# Rotation group: three-dimensional turns and the four-number shortcut -- the check behind the card.
# Standard library only.  A drone camera's orientation, axes north, east, down, is held three ways:
# a 3 x 3 rotation matrix R, an axis and angle, and a unit quaternion q = (w, x, y, z), scalar first,
# with ij = k, turning a vector v to q v q-bar.  The pan between two shots is blended by slerp.
# Roads: matrix and quaternion built separately from the same angles; the quaternion read back from
# the matrix and from axis-angle; slerp against the matrix route R_A exp(t log(R_A^T R_B)); slerp
# against many small gyro-style steps q <- q (1 + w h / 2), renormalised.
import math
D = math.pi / 180

def mul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def tp(A):
    return [list(r) for r in zip(*A)]
def rx(a):
    return [[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]]
def ry(a):
    return [[math.cos(a), 0, math.sin(a)], [0, 1, 0], [-math.sin(a), 0, math.cos(a)]]
def rz(a):
    return [[math.cos(a), -math.sin(a), 0], [math.sin(a), math.cos(a), 0], [0, 0, 1]]
def euler(h, p, r):                        # heading about down, tilt about east, roll about north (degrees)
    return mul(rz(h * D), mul(ry(p * D), rx(r * D)))
def det3(A):
    return (A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1]) - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
            + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]))
def qmul(a, b):                            # Hamilton's product, from i^2 = j^2 = k^2 = ijk = -1
    return (a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3], a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
            a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1], a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0])
def qbar(q):
    return (q[0], -q[1], -q[2], -q[3])
def qaxis(u, t):                           # axis u, angle t in radians: (cos t/2, sin t/2 u)
    return (math.cos(t / 2), u[0] * math.sin(t / 2), u[1] * math.sin(t / 2), u[2] * math.sin(t / 2))
def qeuler(h, p, r):
    return qmul(qaxis((0, 0, 1), h * D), qmul(qaxis((0, 1, 0), p * D), qaxis((1, 0, 0), r * D)))
def turn(q, v):                            # v -> q v q-bar
    return list(qmul(qmul(q, (0.0, v[0], v[1], v[2])), qbar(q))[1:])
def qmat(q):                               # column j of R is where axis j goes under q v q-bar
    return tp([turn(q, e) for e in ((1, 0, 0), (0, 1, 0), (0, 0, 1))])
def rodrigues(u, t):                       # R = I + sin t [u]x + (1 - cos t) [u]x^2
    K = [[0, -u[2], u[1]], [u[2], 0, -u[0]], [-u[1], u[0], 0]]
    K2 = mul(K, K)
    return [[(i == j) + math.sin(t) * K[i][j] + (1 - math.cos(t)) * K2[i][j] for j in range(3)] for i in range(3)]
def axis_angle(R):                         # trace gives the angle, the skew part the axis (0 < t < 180 deg)
    t = math.acos((R[0][0] + R[1][1] + R[2][2] - 1) / 2)
    s = 2 * math.sin(t)
    return [(R[2][1] - R[1][2]) / s, (R[0][2] - R[2][0]) / s, (R[1][0] - R[0][1]) / s], t
def q_from_mat(R):                         # valid while the trace is above -1
    w = math.sqrt(1 + R[0][0] + R[1][1] + R[2][2]) / 2
    return (w, (R[2][1] - R[1][2]) / (4 * w), (R[0][2] - R[2][0]) / (4 * w), (R[1][0] - R[0][1]) / (4 * w))
def dot4(a, b):
    return sum(x * y for x, y in zip(a, b))
def slerp(a, b, t):                        # flip b if needed, so the blend takes the short way
    if dot4(a, b) < 0:
        b = tuple(-c for c in b)
    om = math.acos(min(1.0, dot4(a, b)))
    return tuple((math.sin((1 - t) * om) * x + math.sin(t * om) * y) / math.sin(om) for x, y in zip(a, b))
def gap(a, b):                             # angle of the turn from a to b, in degrees
    return 2 * math.acos(min(1.0, abs(dot4(a, b)))) / D
def hpr(R):                                # heading, tilt, roll read back from a matrix (degrees)
    return [math.atan2(R[1][0], R[0][0]) / D, math.asin(-R[2][0]) / D, math.atan2(R[2][1], R[2][2]) / D]
def mgap(A, B):
    return max(abs(A[i][j] - B[i][j]) for i in range(3) for j in range(3))
def f4(x):
    return f"{0.0 if abs(x) < 5e-5 else x:.4f}"
def f2(x):
    return f"{0.0 if abs(x) < 5e-3 else x:.2f}"
def fl(v):
    return " ".join(f4(x) for x in v)

shots = {"A": (30, -10, 0), "B": (120, -40, 0)}  # heading, tilt (negative = down), roll, in degrees
R, Q, worst = {}, {}, 0.0
for s, a in shots.items():
    R[s], Q[s] = euler(*a), qeuler(*a)
    u, t = axis_angle(R[s])
    print(f"shot {s} {a}: R rows {' | '.join(fl(r) for r in R[s])}")
    print(f"shot {s}: q from angles {fl(Q[s])}; q from R {fl(q_from_mat(R[s]))}")
    print(f"shot {s}: axis {fl(u)}, angle {f4(t / D)} deg; q from axis-angle {fl(qaxis(u, t))}")
    print(f"shot {s}: camera looks along {fl(turn(Q[s], (1, 0, 0)))}")
    worst = max(worst, mgap(qmat(Q[s]), R[s]), max(abs(x - y) for x, y in zip(q_from_mat(R[s]), Q[s])),
                max(abs(x - y) for x, y in zip(qaxis(u, t), Q[s])), max(abs(turn(Q[s], (1, 0, 0))[i] - R[s][i][0]) for i in range(3)))
print(f"matrix, axis-angle and quaternion agree, worst gap below 1e-12: {'yes' if worst < 1e-12 else 'no'}")
d = dot4(Q["A"], Q["B"])
total = gap(Q["A"], Q["B"])
print(f"qA . qB = {' + '.join(f4(x * y) for x, y in zip(Q['A'], Q['B']))} = {f4(d)}; half-angle {f4(math.acos(d) / D)} deg; the pan turns the camera {f4(total)} deg")
mid = slerp(Q["A"], Q["B"], 0.5)
sm = [x + y for x, y in zip(Q["A"], Q["B"])]
n = math.sqrt(dot4(sm, sm))
print(f"shot A pieces: heading 30 gives {fl(qaxis((0, 0, 1), 30 * D))}; tilt -10 gives {fl(qaxis((0, 1, 0), -10 * D))}")
print(f"qA + qB = {fl(sm)}, length {f4(n)}; 2 cos(half-angle / 2) = {f4(2 * math.cos(math.acos(d) / 2))}")
uR, tR = axis_angle(mul(tp(R["A"]), R["B"]))
road = 0.0
for t in (0, 0.25, 0.5, 0.75, 1):
    q = slerp(Q["A"], Q["B"], t)
    Rm = mul(R["A"], rodrigues(uR, t * tR))  # the matrix route, R_A exp(t log(R_A^T R_B))
    road = max(road, mgap(qmat(q), Rm))
    print(f"slerp t = {t:.2f}: q {fl(q)}; heading, tilt, roll {fl(hpr(qmat(q)))}")
print(f"slerp against the matrix route, worst gap below 1e-12: {'yes' if road < 1e-12 else 'no'}")
print(f"midpoint is (qA + qB) / |qA + qB|, gap below 1e-12: {'yes' if max(abs((x + y) / n - z) for x, y, z in zip(Q['A'], Q['B'], mid)) < 1e-12 else 'no'}")
times = [k / 8 for k in range(9)]
blend = lambda t: qeuler(*[x + t * (y - x) for x, y in zip(shots["A"], shots["B"])])
s_ang = [gap(Q["A"], slerp(Q["A"], Q["B"], t)) for t in times]
print(f"seconds into a 4 s pan:     {' '.join(f'{4 * t:.1f}' for t in times)}")
print(f"slerp horizon roll, deg:    {' '.join(f2(hpr(qmat(slerp(Q['A'], Q['B'], t)))[2]) for t in times)}")
print(f"slerp to blended, deg:      {' '.join(f2(gap(slerp(Q['A'], Q['B'], t), blend(t))) for t in times)}")
paths = [sum(gap(blend((k - 1) / M), blend(k / M)) for k in range(1, M + 1)) for M in (1000, 2000)]
print(f"turning done by blended angles, 1000 and 2000 samples: {f4(paths[0])} {f4(paths[1])} deg; slerp {f4(total)} deg")
w = [2 * math.acos(d) * c / math.sqrt(1 - d * d) for c in qmul(qbar(Q["A"]), Q["B"])[1:]]  # body rate, rad per pan
errs = []
for N in (100, 1000):
    q = Q["A"]
    for _ in range(N // 2):
        q = qmul(q, (1.0, w[0] / (2 * N), w[1] / (2 * N), w[2] / (2 * N)))
        q = tuple(c / math.sqrt(dot4(q, q)) for c in q)
    errs.append(gap(q, mid))
    print(f"gyro steps, {N} per pan, at mid-pan: off slerp by {errs[-1]:.7f} deg")
avg = [[(a + b) / 2 for a, b in zip(r1, r2)] for r1, r2 in zip(R["A"], R["B"])]
print(f"mistake 1, matrices averaged entry by entry: det {f4(det3(avg))}")
print(f"mistake 2, blend toward -qB unflipped: swings {f4(2 * math.acos(-d) / D)} deg; (qA + (-qA)) / 2 = {fl([(x - x) / 2 for x in Q['A']])}")
em = qeuler(*[(x + y) / 2 for x, y in zip(shots["A"], shots["B"])])
print(f"mistake 3, heading, tilt, roll blended: mid-pan is {f4(gap(em, mid))} deg off slerp")
l1, l2 = qeuler(*[(x + y) / 2 for x, y in zip(shots["A"], (120, -90, 0))]), qeuler(*[(x + y) / 2 for x, y in zip(shots["A"], (30, -90, 90))])
print(f"  shot B straight down, named (120, -90, 0) or (30, -90, 90): same shot, gap {f4(gap(qeuler(120, -90, 0), qeuler(30, -90, 90)))} deg; blended midpoints {f4(gap(l1, l2))} deg apart")
nl = [x + 0.25 * (y - x) for x, y in zip(Q["A"], Q["B"])]
ln = math.sqrt(dot4(nl, nl))
print(f"mistake 4, straight blend at 1 s: length {f4(ln)}; rescaled, {f4(gap(Q['A'], [c / ln for c in nl]))} deg from A; slerp {f4(s_ang[2])} deg")
print(f"mistake 5, q-bar v q for shot A: camera heading {f4(math.atan2(turn(qbar(Q['A']), (1, 0, 0))[1], turn(qbar(Q['A']), (1, 0, 0))[0]) / D)} deg, tilt {f4(math.asin(-turn(qbar(Q['A']), (1, 0, 0))[2]) / D)} deg")
uA, tA = axis_angle(R["A"])
print(f"mistake 6, shot A built from cos t and sin t, not the half angles: turns {f4(axis_angle(qmat(qaxis(uA, 2 * tA)))[1] / D)} deg")
print(f"q and -q give the same matrix: {'yes' if mgap(qmat(Q['A']), qmat(tuple(-c for c in Q['A']))) < 1e-12 else 'no'}; 360 deg turn q = {fl(qaxis((0, 0, 1), 2 * math.pi))}; 720 deg q = {fl(qaxis((0, 0, 1), 4 * math.pi))}")
assert worst < 1e-12 and road < 1e-12                            # three representations, two blend routes
assert max(abs(a - total * t) for a, t in zip(s_ang, times)) < 1e-9   # slerp turns at a constant rate
assert errs[1] < errs[0] / 50 and errs[1] < 1e-3                 # gyro steps close in on slerp
assert abs(n - 2 * math.cos(math.acos(d) / 2)) < 1e-12           # the midpoint by hand
assert abs(axis_angle(qmat(qaxis(uA, 2 * tA)))[1] - 2 * tA) < 1e-9  # q carries half the angle
assert abs(det3(avg)) < 0.9 and gap(em, mid) > 1 and gap(l1, l2) > 1 and paths[1] > total + 1
print("ALL CHECKS PASS")
