# Regular value theorem -- the check behind the card.  Standard library only.
# $10,000 split as x, y, z dollars in funds with yearly swings of 10%, 20% and 30%,
# taken as independent.  F = (total, risk squared) = (x + y + z, (0.1x)^2 + (0.2y)^2 + (0.3z)^2).
# Road one: the rank test, dF and its 2 x 2 minors.  Road two: a chart from the
# implicit function theorem, solved by Newton and by the quadratic formula.
# Road three: the loop drawn with no derivatives, as a sphere cut by a plane.
from math import sqrt, cos, sin, atan2, pi

SIG, TOTAL, RISK = (0.1, 0.2, 0.3), 10000.0, 900.0
def F(p): return (sum(p), sum((s * c) ** 2 for s, c in zip(SIG, p)))
def dF(p): return ((1.0, 1.0, 1.0), tuple(2 * s * s * c for s, c in zip(SIG, p)))
def minors(J):                            # columns (x, y), (x, z), (y, z)
    return tuple(J[0][i] * J[1][j] - J[0][j] * J[1][i] for i, j in ((0, 1), (0, 2), (1, 2)))
def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def dot(a, b): return sum(p * q for p, q in zip(a, b))
def unit(a): return tuple(c / sqrt(dot(a, a)) for c in a)
def v(a, d=2): return "(" + ", ".join(f"{c:.{d}f}" for c in a) + ")"

p = (6000.0, 3000.0, 1000.0)
J = dF(p)
print(f"swings {v(tuple(100 * s for s in SIG), 0)} %, squared {v(tuple(s * s for s in SIG))}; "
      f"total {TOTAL:.0f}, risk {RISK:.0f}; n - k = 3 - 2 = 1")
print(f"split p = {v(p, 0)}: total {F(p)[0]:.0f}, risk squared {F(p)[1]:.0f}, risk {sqrt(F(p)[1]):.2f}")
print(f"dF_p rows {v(J[0], 0)} and {v(J[1], 0)}")
m = minors(J)
print(f"minors (x,y) (x,z) (y,z): {m[0]:.0f} {m[1]:.0f} {m[2]:.0f}, rank 2")
t = cross(J[0], J[1])
print(f"tangent = row 1 x row 2 = {v(t, 0)}; per $1 into z: {v(tuple(c / t[2] for c in t))}")
assert abs(dot(t, J[0])) < 1e-9 and abs(dot(t, J[1])) < 1e-9

def chart_newton(z, x, y):                # road two: solve F = c for (x, y) with z held
    for _ in range(50):
        f1, f2 = x + y + z - TOTAL, (0.1 * x) ** 2 + (0.2 * y) ** 2 + (0.3 * z) ** 2 - RISK ** 2
        a, b = 0.02 * x, 0.08 * y         # block dF/d(x, y) = [[1, 1], [a, b]]
        det = b - a
        x, y = x - (b * f1 - f2) / det, y - (-a * f1 + f2) / det
    return x, y

def chart_exact(z):                       # same chart, quadratic formula, root nearer p
    s, q = TOTAL - z, RISK ** 2 - (0.3 * z) ** 2      # x + y = s, 0.01x^2 + 0.04y^2 = q
    A, B, C = 0.05, -0.08 * s, 0.04 * s * s - q
    x = (-B - sqrt(B * B - 4 * A * C)) / (2 * A)
    return x, s - x

ift = (J[1][2] - J[1][1]) / (J[1][1] - J[1][0]), (J[1][0] - J[1][2]) / (J[1][1] - J[1][0])
print(f"implicit function slopes dx/dz, dy/dz = {ift[0]:.4f}, {ift[1]:.4f}")
for h in (100.0, 10.0):
    a, b = chart_newton(1000 + h, 6000, 3000), chart_newton(1000 - h, 6000, 3000)
    sl = ((a[0] - b[0]) / (2 * h), (a[1] - b[1]) / (2 * h))
    print(f"  Newton chart, step {h:.0f}: slopes {sl[0]:.6f}, {sl[1]:.6f}")
assert abs(sl[0] - ift[0]) < 1e-4 and abs(sl[1] - ift[1]) < 1e-4
xn, yn = chart_newton(1100.0, 6000, 3000)
xe, ye = chart_exact(1100.0)
assert abs(xn - xe) < 1e-6 and abs(yn - ye) < 1e-6
lin = (6000 + 100 * ift[0], 3000 + 100 * ift[1], 1100.0)
print(f"z = 1100: chart gives x, y = {xn:.2f}, {yn:.2f} (quadratic formula {xe:.2f}, {ye:.2f})")
print(f"  straight-line trade {v(lin)} has risk {sqrt(F(lin)[1]):.2f}")

w = tuple(1 / s for s in SIG)             # road three: u = 0.1x, v = 0.2y, w = 0.3z
nh = unit(w)
d = TOTAL / sqrt(dot(w, w))               # distance from origin to the budget plane
r = sqrt(RISK ** 2 - d * d)
print(f"risk coordinates of p {v(tuple(s * c for s, c in zip(SIG, p)), 0)}; plane normal {v(nh, 6)}")
print(f"plane distance = least risk {d:.6f} (6000/7 = {6000 / 7:.6f}); circle radius {r:.2f}")
lag = tuple(TOTAL * (1 / s ** 2) / sum(1 / q ** 2 for q in SIG) for s in SIG)
print(f"least-risk split (Lagrange) {v(lag)}, risk {sqrt(F(lag)[1]):.6f}")
assert abs(sqrt(F(lag)[1]) - d) < 1e-6
e1 = unit((-nh[1], nh[0], 0.0)); e2 = cross(nh, e1)
def loop(th): return tuple((d * nh[i] + r * (cos(th) * e1[i] + sin(th) * e2[i])) / SIG[i] for i in range(3))

N = 7200
pts = [loop(2 * pi * k / N) for k in range(N)]
err = max(max(abs(F(q)[0] - TOTAL), abs(F(q)[1] - RISK ** 2)) for q in pts)
low = min(max(abs(c) for c in minors(dF(q))) for q in pts)
print(f"loop, {N} points: every one solves F = c to within 1e-6; smallest largest-minor {low:.2f}")
assert err < 1e-6 and low > 1
def where_zero(k, a, b):                  # bisection on a sign change of minor k
    for _ in range(60):
        c = (a + b) / 2
        if (minors(dF(loop(a)))[k] > 0) == (minors(dF(loop(c)))[k] > 0): a = c
        else: b = c
    return loop(a)
fails = []
for k, name, i in ((2, "x", 0), (1, "y", 1), (0, "z", 2)):
    ch = [j for j in range(N) if (minors(dF(pts[j]))[k] > 0) != (minors(dF(pts[(j + 1) % N]))[k] > 0)]
    fp = sorted((where_zero(k, 2 * pi * j / N, 2 * pi * (j + 1) / N) for j in ch), key=lambda q: q[i])
    fails += fp
    ext = [q[i] for q in fp]
    hw = r * sqrt(1 - nh[i] ** 2)
    cf = ((d * nh[i] - hw) / SIG[i], (d * nh[i] + hw) / SIG[i])
    print(f"chart over {name} fails at {len(ch)} points, {name} = {ext[0]:.2f} and {ext[1]:.2f}"
          f" (closed form {cf[0]:.2f}, {cf[1]:.2f})")
    assert len(ch) == 2 and abs(ext[0] - cf[0]) < 1e-6 and abs(ext[1] - cf[1]) < 1e-6
yp = tuple(s * c - d * n for s, c, n in zip(SIG, p, nh))   # p seen from the circle's centre
thp = atan2(dot(yp, e2), dot(yp, e1))
q1, q0 = loop(thp + 1e-6), loop(thp - 1e-6)
vel = tuple(a - b for a, b in zip(q1, q0))
gap = max(abs(a - b) for a, b in zip(loop(thp), p))
print(f"loop at angle {thp:.6f} rad meets p (gap {gap:.6f}); its velocity, scaled: {v(tuple(c / vel[2] for c in vel), 3)}")
assert gap < 1e-6 and sqrt(dot(cross(unit(vel), unit(t)), cross(unit(vel), unit(t)))) < 1e-6
print("figure, (y, z): p " + v(p[1:], 0) + ", centre " + v(lag[1:], 0) + ", chart edges "
      + " ".join(v(q[1:], 0) for q in fails))

print("what breaks:")
Jl = dF(lag)
print(f"  risk {d:.2f}: one split, largest minor {max(abs(c) for c in minors(Jl)):.6f}, rank 1, dimension 0 not 1")
assert max(abs(c) for c in minors(Jl)) < 1e-6
print(f"  risk 850.00: radius squared {850.0 ** 2 - d * d:.2f} < 0, no split at all")
print(f"  total twice (dollars, cents): minors {v(minors(((1, 1, 1), (100, 100, 100))), 0)}, rank 1, the set is a plane")
print(f"  (x + y + z - 10000)^2 = 0: differential {v(tuple(2 * (sum(p) - TOTAL) for _ in p), 0)}, a plane, test silent")
Rg = 6371.0
print(f"globe x^2 + y^2 + z^2 = {Rg:.0f}^2: |dF| = 2R = {2 * Rg:.0f} km, never 0, dimension 3 - 1 = 2")
rows = []                                 # O(3): dF_I(H) = H + H^T, 9 inputs, 6 outputs
for a in range(9):
    H = [[1.0 if 3 * i + j == a else 0.0 for j in range(3)] for i in range(3)]
    rows.append([H[i][j] + H[j][i] for i in range(3) for j in range(i, 3)])
rank, M = 0, [row[:] for row in rows]
for col in range(6):
    piv = next((i for i in range(rank, 9) if abs(M[i][col]) > 1e-12), None)
    if piv is None: continue
    M[rank], M[piv] = M[piv], M[rank]
    for i in range(9):
        if i != rank: M[i] = [a - M[i][col] / M[rank][col] * b for a, b in zip(M[i], M[rank])]
    rank += 1
print(f"O(3): A^T A = I, 9 entries, rank of dF_I {rank}, dimension {9 - rank}")
assert rank == 6
print("ALL CHECKS PASS")
