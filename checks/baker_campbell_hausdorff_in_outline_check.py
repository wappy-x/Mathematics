# Baker-Campbell-Hausdorff in outline -- the check behind the card.  Standard
# library only.  A camera gimbal pans 10 deg (about its down axis) and tilts
# 5 deg down (about its right axis), each about the camera's own current axes,
# in both orders.  Axes north, east, down; a turn is a rotation vector w, its
# generator the skew matrix [w]x.  Roads: exp by power series against the closed
# form; log by power series against the closed form; the BCH series against the
# exact log, with errors that shrink by 4, 8, 32 when the nudges are halved.
import math
D, AS = math.pi / 180, 3600 * 180 / math.pi          # radians per degree, arcseconds per radian
I3 = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
def mul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def lin(A, B, s=1.0): return [[A[i][j] + s * B[i][j] for j in range(3)] for i in range(3)]
def tp(A): return [[A[j][i] for j in range(3)] for i in range(3)]
def hat(w): return [[0.0, -w[2], w[1]], [w[2], 0.0, -w[0]], [-w[1], w[0], 0.0]]
def vee(K): return [(K[2][1] - K[1][2]) / 2, (K[0][2] - K[2][0]) / 2, (K[1][0] - K[0][1]) / 2]
def cross(u, v): return [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
def add(*vs): return [sum(c) for c in zip(*vs)]
def sc(s, v): return [s * x for x in v]
def norm(v): return math.sqrt(sum(x * x for x in v))
def gap(A, B): return max(abs(A[i][j] - B[i][j]) for i in range(3) for j in range(3))
def br(A, B): return lin(mul(A, B), mul(B, A), -1.0)  # the bracket [A, B] = AB - BA

def exp_series(K, n=40):                               # road one: I + K + K^2/2! + ...
    S, P = I3, I3
    for k in range(1, n):
        P = [[x / k for x in row] for row in mul(P, K)]
        S = lin(S, P)
    return S
def exp_closed(w):                                     # road two: Rodrigues' formula
    t, K = norm(w), hat(w)
    if t == 0: return I3
    return lin(lin(I3, K, math.sin(t) / t), mul(K, K), (1 - math.cos(t)) / t ** 2)
def log_closed(R):                                     # road one: angle from the trace, axis from the skew part
    t = math.acos(max(-1.0, min(1.0, (R[0][0] + R[1][1] + R[2][2] - 1) / 2)))
    return sc(t / math.sin(t), vee(R)) if t > 1e-12 else vee(R)
def log_series(R, n):                                  # road two: M - M^2/2 + M^3/3 - ..., M = R - I
    M = lin(R, I3, -1.0)
    S, P = [[0.0] * 3 for _ in range(3)], I3
    for k in range(1, n + 1):
        P = mul(P, M)
        S = lin(S, P, (-1) ** (k + 1) / k)
    return S
def bch(u, v, order):                                  # the series, with [[u]x, [v]x] = [u x v]x
    terms = [add(u, v), sc(0.5, cross(u, v)),
             sc(1 / 12, add(cross(u, cross(u, v)), cross(v, cross(v, u))))]
    return add(*terms[:order])
def miss(z, R): return norm(log_closed(mul(exp_closed(sc(-1.0, z)), R))) * AS  # turn angle, arcsec
def v3(w): return "(" + ", ".join(f"{x / D:.6f}" for x in w) + ")"
def yn(c): return "yes" if c else "no"
def scaled(s, k):                                      # order-k miss with both nudges times s, arcsec
    us, vs = sc(s, u), sc(s, v)
    return miss(bch(us, vs, k), mul(exp_closed(us), exp_closed(vs)))

a, b = 10 * D, 5 * D
u, v = [0.0, 0.0, a], [0.0, -b, 0.0]                   # pan right 10 deg, tilt down 5 deg
X, Y = hat(u), hat(v)
P, T = exp_series(X), exp_series(Y)
PT, TP = mul(P, T), mul(T, P)                          # pan then tilt; tilt then pan
print(f"pan {a:.6f} rad, tilt {-b:.6f} rad; exp series = closed form below 1e-12: "
      f"{yn(gap(P, exp_closed(u)) < 1e-12 and gap(T, exp_closed(v)) < 1e-12)}")
for name, R in (("pan then tilt", PT), ("tilt then pan", TP)):
    print(f"{name}: camera points ({R[0][0]:.6f}, {R[1][0]:.6f}, {R[2][0]:.6f}), "
          f"horizon lean {math.atan2(R[2][1], R[2][2]) / D:.6f} deg")
aim = math.acos(sum(PT[i][0] * TP[i][0] for i in range(3)))
print(f"the two aims differ by {aim / D:.6f} deg; the orders differ by a turn of "
      f"{norm(log_closed(mul(tp(TP), PT))) / D:.6f} deg")
Z, Zs = log_closed(PT), vee(log_series(PT, 40))
print(f"Z = log(pan then tilt), deg: {v3(Z)}; log series agrees below 1e-12: {yn(norm(add(Z, sc(-1.0, Zs))) < 1e-12)}")
print(f"exp(Z) rebuilds pan then tilt below 1e-12: {yn(gap(exp_series(hat(Z)), PT) < 1e-12)}")
print(f"[X, Y] as matrices equals [u x v]x below 1e-15: {yn(gap(br(X, Y), hat(cross(u, v))) < 1e-15)}")
print(f"u x v, deg: {v3(cross(u, v))}; a times b = {a * b / D:.6f} deg of roll")
err = [miss(bch(u, v, k), PT) for k in (1, 2, 3)]
for k in (1, 2, 3):
    print(f"BCH to order {k}, deg {v3(bch(u, v, k))}: misses by {err[k - 1]:.4f} arcsec")
print(f"Z for tilt then pan, deg: {v3(log_closed(TP))}")
C = mul(PT, mul(exp_series(hat(sc(-1.0, u))), exp_series(hat(sc(-1.0, v)))))  # pan, tilt, unpan, untilt
print(f"pan, tilt, unpan, untilt leaves, deg: {v3(log_closed(C))}; [X, Y] predicts {v3(cross(u, v))}")
rat = []
for s in (1.0, 0.5, 0.25):
    rat.append([scaled(s, k) for k in (1, 2, 3)])
    print(f"nudges x {s:.2f}: orders 1, 2, 3 miss by {rat[-1][0]:.4f}, {rat[-1][1]:.4f}, {rat[-1][2]:.4f} arcsec")
r = [rat[0][k] / rat[1][k] for k in range(3)]
print(f"halving the nudges divides the misses by {r[0]:.3f}, {r[1]:.3f}, {r[2]:.3f}; "
      f"order-4 term -[Y, [X, [X, Y]]]/24 here: {norm(cross(v, cross(u, cross(u, v)))) / 24:.6f}")
for k, label in ((1, "X + Y misses"), (2, "with the bracket")):
    print(f"chart, pan 0..20 by 4, {label}, deg: " + ", ".join(f"{scaled(p / 10, k) / 3600:.4f}" for p in range(0, 21, 4)))
u2 = [0.0, 0.0, 5 * D]
print(f"mistake 1, two pans 10 and 5 deg: bracket {norm(cross(u, u2)):.6f}, X + Y misses by "
      f"{miss(add(u, u2), mul(P, exp_closed(u2))):.4f} arcsec")
print(f"mistake 2, bracket dropped: misses by {err[0]:.4f} arcsec")
print(f"mistake 3, bracket sign flipped: misses by {miss(add(u, v, sc(-0.5, cross(u, v))), PT):.4f} arcsec")
U, V = [0.0, 0.0, 90 * D], [0.0, -90 * D, 0.0]
B = mul(exp_closed(U), exp_closed(V))
grow = [norm(vee(log_series(B, n))) / D for n in (5, 10, 20)]
print(f"mistake 4, pan 90 then tilt 90: one turn of {norm(log_closed(B)) / D:.4f} deg; BCH order 3 misses by "
      f"{miss(bch(U, V, 3), B) / 3600:.4f} deg; log series after 5, 10, 20 terms: {grow[0]:.1f}, {grow[1]:.1f}, {grow[2]:.1f} deg")
rad = [2 * math.sin(norm(log_closed(R)) / 2) for R in (PT, B)]  # size of each eigenvalue of R - I
print(f"log series needs 2 sin(angle/2) below 1: house {rad[0]:.4f}, 90 then 90 {rad[1]:.4f}; "
      f"pan + tilt {a + b:.6f} rad against ln 2 = {math.log(2):.6f}")
assert norm(add(Z, sc(-1.0, Zs))) < 1e-12                     # two roads to the log agree
assert gap(br(X, Y), hat(cross(u, v))) < 1e-15                # matrix bracket = cross product
assert err[0] > 10 * err[1] and err[1] > 100 * err[2]          # each order shrinks the miss
assert abs(err[0] / 3600 - a * b / 2 / D) < 0.001             # first miss is half the bracket
assert 3.8 < r[0] < 4.2 and 7.6 < r[1] < 8.4 and 30 < r[2] < 34  # misses scale as s^2, s^3, s^5
assert abs(log_closed(C)[0] - a * b) < 0.01 * a * b           # the loop leaves the bracket's roll
assert grow[2] > 10 * grow[1] and grow[1] > 2 * grow[0] and rad[1] > 1                           # past the radius the series runs away
print("ALL CHECKS PASS")
