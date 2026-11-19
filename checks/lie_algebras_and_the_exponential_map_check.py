# Lie algebra and the exponential map -- the check behind the card.  Nothing is
# imported but math.  A drone's gyro reads a steady body turn rate w (rad/s);
# held for t = 1 s it becomes a finished turn R = exp(t [w]x).  R is reached by
# three roads: the power series, Rodrigues' closed form, and many small steps.
# Then brackets: by matrix products, by the cross product, and by a gimbal loop.
from math import sin, cos, acos, sqrt, degrees, exp, pi

I = [[1.0 if i == j else 0.0 for j in range(3)] for i in range(3)]
def mul(a, b): return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def lin(a, b, s): return [[a[i][j] + s * b[i][j] for j in range(3)] for i in range(3)]   # a + s b
def sc(a, s): return [[s * x for x in row] for row in a]
def tr(a): return [[a[j][i] for j in range(3)] for i in range(3)]
def hat(w): return [[0.0, -w[2], w[1]], [w[2], 0.0, -w[0]], [-w[1], w[0], 0.0]]   # [w]x
def vee(a): return (a[2][1], a[0][2], a[1][0])                                     # undoes hat
def gap(a, b): return max(abs(a[i][j] - b[i][j]) for i in range(3) for j in range(3))
def br(x, y): return lin(mul(x, y), mul(y, x), -1.0)                                 # [X, Y] = XY - YX
def det(a): return (a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
                    + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]))
def angle(r): return acos(max(-1.0, min(1.0, (r[0][0] + r[1][1] + r[2][2] - 1.0) / 2.0)))   # from the trace
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])

def expm(x, terms=40):                          # road 1: I + X + X^2/2! + ... term by term
    s, term = [r[:] for r in I], [r[:] for r in I]
    for k in range(1, terms):
        term = sc(mul(term, x), 1.0 / k)
        s = lin(s, term, 1.0)
    return s

def rodrigues(w, t):                            # road 2: I + sin(th) K + (1 - cos(th)) K^2
    th = sqrt(sum(c * c for c in w)) * t
    k = hat([c * t / th for c in w])
    return lin(lin(I, k, sin(th)), mul(k, k), 1.0 - cos(th))

def steps(x, n):                                # road 3: n small gyro updates R <- R (I + X/n)
    r, s = [row[:] for row in I], lin(I, x, 1.0 / n)
    for _ in range(n):
        r = mul(r, s)
    return r

def f(x): return 0.0 if abs(x) < 5e-13 else x
def fv(v): return "(" + ", ".join(f"{f(c):.6f}" for c in v) + ")"
def fm(a): return "[" + ", ".join("[" + ", ".join(f"{f(c):.6f}" for c in row) + "]" for row in a) + "]"
def yn(c): return "yes" if c else "no"

w, t = (0.3, 0.4, 1.2), 1.0
W = hat(w)
th = sqrt(sum(c * c for c in w)) * t
axis = tuple(c / th for c in w)
R, Rr = expm(W), rodrigues(w, t)
e1000, e2000 = steps(W, 1000), steps(W, 2000)
print(f"rate w = {w} rad/s held {t:.0f} s: angle {th:.6f} rad = {degrees(th):.6f} deg, axis {fv(axis)}")
print(f"[w]x = {fm(W)}")
print(f"road 1, series:    R = {fm(R)}")
print(f"road 2, Rodrigues: R = {fm(Rr)}; agree to 1e-12: {yn(gap(R, Rr) < 1e-12)}")
print(f"by hand: sin(1.3) = {sin(th):.6f}, 1 - cos(1.3) = {1 - cos(th):.6f}; K^2 entry (2, 1) = {axis[1] * axis[0]:.6f}; entry (2, 1) = "
      f"{sin(th) * axis[2]:.6f} + {(1 - cos(th)) * axis[0] * axis[1]:.6f} = {sin(th) * axis[2] + (1 - cos(th)) * axis[0] * axis[1]:.6f}")
print(f"road 3, 1000 steps: off by {gap(e1000, R):.6f}, det {det(e1000):.6f}")
print(f"road 3, 2000 steps: off by {gap(e2000, R):.6f}, det {det(e2000):.6f}; error ratio {gap(e1000, R) / gap(e2000, R):.2f}")
print(f"R^T R - I largest entry {gap(mul(tr(R), R), I):.6f}; det R = {det(R):.6f}")
print(f"R times the axis = {fv([sum(R[i][j] * axis[j] for j in range(3)) for i in range(3)])}; [w]x times the axis = {fv([sum(W[i][j] * axis[j] for j in range(3)) for i in range(3)])}")
print(f"trace R = {R[0][0] + R[1][1] + R[2][2]:.6f} = 1 + 2 cos(1.3); angle back from the trace {angle(R):.6f} rad")
half = mul(expm(sc(W, 0.4)), expm(sc(W, 0.6)))
print(f"e^(0.4 [w]x) e^(0.6 [w]x) equals e^([w]x): {yn(gap(half, R) < 1e-12)}")
dq = [gap(sc(lin(expm(sc(W, h)), I, -1.0), 1.0 / h), W) for h in (0.01, 0.005)]
print(f"tangent at I: (R(h) - I)/h minus [w]x, h = 0.01: {dq[0]:.6f}, h = 0.005: {dq[1]:.6f}; ratio {dq[0] / dq[1]:.2f}")
times = [0.1 * k for k in range(11)]
noses = [[row[0] for row in expm(sc(W, s))] for s in times]
print("nose, t (s)  " + " ".join(f"{s:6.1f}" for s in times))
for i, name in enumerate("xyz"):
    print(f"nose, {name}      " + " ".join(f"{f(n[i]):6.3f}" for n in noses))

Lx, Ly, Lz = hat((1, 0, 0)), hat((0, 1, 0)), hat((0, 0, 1))
print(f"[Lx, Ly] = Lz: {yn(gap(br(Lx, Ly), Lz) == 0)}; [Ly, Lz] = Lx: {yn(gap(br(Ly, Lz), Lx) == 0)}; [Lz, Lx] = Ly: {yn(gap(br(Lz, Lx), Ly) == 0)}")
print(f"[Ly, Lz] = {fm(br(Ly, Lz))}")
g = (0.0, 0.5, 0.0)                             # the gimbal's pitch rate, rad/s
B = br(W, hat(g))
print(f"[[w]x, [g]x] for g = {g}: vector {fv(vee(B))}; w x g = {fv(cross(w, g))}; skew: {yn(gap(tr(B), sc(B, -1.0)) == 0)}")
loop = []
for eps in (0.1, 0.05):                         # pitch eps, yaw eps, pitch back, yaw back
    C = mul(mul(expm(sc(Ly, eps)), expm(sc(Lz, eps))), mul(expm(sc(Ly, -eps)), expm(sc(Lz, -eps))))
    v = vee(lin(C, tr(C), -1.0))
    n = sqrt(sum(c * c for c in v))
    loop.append((eps, angle(C), gap(sc(lin(C, I, -1.0), 1.0 / eps ** 2), Lx)))
    print(f"gimbal loop eps = {eps} rad = {degrees(eps):.6f} deg: net turn {angle(C):.6f} rad = {degrees(angle(C)):.6f} deg about {fv([c / n for c in v])}; "
          f"(C - I)/eps^2 minus Lx: {loop[-1][2]:.6f}")
print(f"gimbal loop error ratio {loop[0][2] / loop[1][2]:.2f}")

E = [[exp(x) for x in row] for row in W]
seq = mul(mul(expm(sc(Lx, 0.3)), expm(sc(Ly, 0.4))), expm(sc(Lz, 1.2)))
e100 = steps(W, 100)
R3 = expm(sc(W, 3.0))
bch = gap(mul(expm(sc(Ly, 0.1)), expm(sc(Lz, 0.1))), expm(sc(lin(Ly, Lz, 1.0), 0.1)))
print(f"mistake, e of each entry: det {det(E):.6f}, R^T R - I largest entry {gap(mul(tr(E), E), I):.6f}")
print(f"mistake, roll 0.3 then pitch 0.4 then yaw 1.2: off by {angle(mul(tr(R), seq)):.6f} rad = {degrees(angle(mul(tr(R), seq))):.6f} deg")
u = (0.8, -0.6, 0.0)                            # a unit vector at right angles to the axis
print(f"mistake, 100 plain steps: det {det(e100):.6f}; a unit vector at right angles to the axis ends {sqrt(sum(sum(e100[i][j] * u[j] for j in range(3)) ** 2 for i in range(3))):.6f} long")
print(f"mistake, angle from the trace after 3 s: {angle(R3):.6f} rad, not {3 * th:.6f}; 2 pi - 3.9 = {2 * pi - 3 * th:.6f}")
print(f"mistake, e^(0.1 Ly) e^(0.1 Lz) against e^(0.1 (Ly + Lz)): gap {bch:.6f}")
back = expm(sc(W, 2 * pi / th))
C2 = mul(mul(expm(sc(Ly, 0.2)), expm(sc(Lz, 0.2))), mul(expm(sc(Ly, -0.2)), expm(sc(Lz, -0.2))))
print(f"try, hold for 2 pi / 1.3 = {2 * pi / th:.6f} s: gap from I {gap(back, I):.6f}")
print(f"try, gimbal loop eps = 0.2: net turn {angle(C2):.6f} rad; w x (0, 0, 0.5) = {fv(cross(w, (0.0, 0.0, 0.5)))}")

assert gap(R, Rr) < 1e-12                                       # series = Rodrigues
assert gap(mul(tr(R), R), I) < 1e-12 and abs(det(R) - 1.0) < 1e-12  # it is a rotation
assert abs(angle(R) - 1.3) < 1e-12 and abs(angle(R3) - (2 * pi - 3.9)) < 1e-12
assert 1.95 < gap(e1000, R) / gap(e2000, R) < 2.05               # steps converge, first order
assert gap(half, R) < 1e-12                                     # one-parameter subgroup
assert 1.95 < dq[0] / dq[1] < 2.05                              # tangent at I is [w]x
assert gap(br(Ly, Lz), Lx) < 1e-15 and gap(B, hat(cross(w, g))) < 1e-15
assert 1.95 < loop[0][2] / loop[1][2] < 2.05 and abs(loop[0][1] - 0.01) < 1e-4   # loop -> eps^2 [X, Y]
print("ALL CHECKS PASS")
