# Implicit Runge-Kutta: the check behind the card.  Standard library only.  A valve servo pulls y towards the
# target cos t at 1000 per s (illustrative): y' = -1000(y - cos t) - sin t, y(0) = 1, exact y = cos t.
# Two-stage Gauss and Radau IIA built by collocation; R(z); stages by simplified Newton; SDIRK for cost.
from math import sqrt, cos, sin, log10
def sci(v, d=3): m, e = f"{v:.{d}e}".split("e"); return f"{m}e{int(e)}"   # 1.234e-5, the form Rust prints
def f6(v): return f"{v if abs(v) >= 5e-7 else 0.0:.6f}"                  # no "-0.000000" from rounding
def quad_roots(a, b, c): d = sqrt(b * b - 4 * a * c); return [(-b - d) / (2 * a), (-b + d) / (2 * a)]
def colloc(c):                                   # a_ij = integral of l_j from 0 to c_i; b_j = from 0 to 1
    L = []
    for j in range(2):                           # Lagrange basis l_j, coefficients lowest power first
        p = [1.0]
        for k in range(2):
            if k != j:
                q = [0.0] * (len(p) + 1)
                for i, v in enumerate(p): q[i] -= c[k] * v / (c[j] - c[k]); q[i + 1] += v / (c[j] - c[k])
                p = q
        L.append(p)
    def integ(p, x): return sum(v * x ** (i + 1) / (i + 1) for i, v in enumerate(p))
    return [[integ(L[j], c[i]) for j in range(2)] for i in range(2)], [integ(L[j], 1.0) for j in range(2)]
cG = quad_roots(6, -6, 1)                        # zeros of the shifted Legendre polynomial 6x^2 - 6x + 1
cR = quad_roots(6, -8, 2)                        # Radau: (6x^2 - 6x + 1) - (2x - 1) = 2(3x - 1)(x - 1)
AG, bG = colloc(cG); AR, bR = colloc(cR)
g = 1 - sqrt(2) / 2                              # SDIRK: L-stable, order 2, both diagonal entries g
M = {"Gauss": [AG, bG, cG], "Radau IIA": [AR, bR, cR], "SDIRK": [[[g, 0.0], [1 - g, g]], [1 - g, g], [g, 1.0]]}
print("tableaux by collocation:")
for k in ("Gauss", "Radau IIA"):
    A, b, c = M[k]
    print(f"  {k}: c = {c[0]:.6f}, {c[1]:.6f}; A = [[{f6(A[0][0])}, {f6(A[0][1])}], [{f6(A[1][0])}, {f6(A[1][1])}]]; b = {b[0]:.6f}, {b[1]:.6f}")
assert abs(AG[0][1] - (0.25 - sqrt(3) / 6)) < 1e-15 and abs(AR[0][0] - 5 / 12) < 1e-15, "against the closed forms"
assert abs(AR[0][1] + 1 / 12) < 1e-15 and abs(AR[1][0] - 0.75) < 1e-15 and abs(bR[0] - 0.75) < 1e-15
def orders(A, b, c):                             # p: sum b c^(k-1) = 1/k for k <= p; q: the same for each row
    p = next(k for k in range(1, 9) if abs(sum(b[i] * c[i] ** (k - 1) for i in range(2)) - 1 / k) > 1e-13) - 1
    q = next(k for k in range(1, 9) if max(abs(sum(A[i][j] * c[j] ** (k - 1) for j in range(2)) - c[i] ** k / k) for i in range(2)) > 1e-13) - 1
    return p, q
def R(A, b, z):                                  # 1 + z b^T (I - zA)^-1 (1, 1), by Cramer's rule
    m11, m12, m21, m22 = 1 - z * A[0][0], -z * A[0][1], -z * A[1][0], 1 - z * A[1][1]
    d = m11 * m22 - m12 * m21
    return 1 + z * (b[0] * (m22 - m12) + b[1] * (m11 - m21)) / d
def padeG(z): return (1 + z / 2 + z * z / 12) / (1 - z / 2 + z * z / 12)
def padeR(z): return (1 + z / 3) / (1 - 2 * z / 3 + z * z / 6)
print("method: order p, stage order q, R(-100), R(-1e8), |R(10i)|, largest |R| on a left half-plane grid")
for k in M:
    A, b, c = M[k]; p, q = orders(A, b, c)
    lh = max(abs(R(A, b, complex(-x * x / 50, y / 5))) for x in range(1, 200) for y in range(-400, 401))
    print(f"  {k}: p = {p}, q = {q}, {R(A, b, -100.0):.6f}, {sci(R(A, b, -1e8))}, {abs(R(A, b, 10j)):.6f}, {lh:.6f}")
    M[k] += [p, q, lh]
assert [M[k][3:5] for k in M] == [[4, 2], [3, 2], [2, 1]], "orders 2s and 2s - 1 from collocation"
assert max(M[k][5] for k in M) < 1, "A-stable: no grid point with |R| above 1"
for z in (-100.0, -0.7, complex(-3, 40), 2.5j):
    assert abs(R(AG, bG, z) - padeG(z)) < 1e-13 and abs(R(AR, bR, z) - padeR(z)) < 1e-13, "R two ways"
r4 = 1 - 100 + 100 ** 2 / 2 - 100 ** 3 / 6 + 100 ** 4 / 24     # explicit RK4: Taylor polynomial of e^z at z = -100
print(f"  RK4 (explicit), for comparison: R(-100) = {sci(r4)}, after 10 steps {sci(r4 ** 10)}")
k1 = -100.0; k2 = -100 * (1 + k1 / 2); k3 = -100 * (1 + k2 / 2); k4 = -100 * (1 + k3)   # RK4's stages on y' = lambda y from y = 1
assert abs((1 + (k1 + 2 * k2 + 2 * k3 + k4) / 6) / r4 - 1) < 1e-12, "RK4 two ways: its stages against the Taylor polynomial"
assert abs(R(AG, bG, -100.0) - 2353 / 2653) < 1e-14 and abs(R(AR, bR, -100.0) + 97 / 5203) < 1e-15
assert abs(abs(R(AG, bG, 7j)) - 1) < 1e-14 and abs(R(AR, bR, -1e8)) < 1e-7 < 1 - R(AG, bG, -1e8) < 1e-6
print("algebraic stability matrix BA + A^T B - b b^T and its smallest eigenvalue:")
for k in M:
    A, b = M[k][0], M[k][1]
    m = [[b[i] * A[i][j] + b[j] * A[j][i] - b[i] * b[j] for j in range(2)] for i in range(2)]
    lo = (m[0][0] + m[1][1]) / 2 - sqrt(((m[0][0] - m[1][1]) / 2) ** 2 + m[0][1] ** 2)
    print(f"  {k}: [[{f6(m[0][0])}, {f6(m[0][1])}], [{f6(m[1][0])}, {f6(m[1][1])}]], {f6(lo)}")
    M[k].append(lo)
assert abs(M["Gauss"][6]) < 1e-15 and M["Radau IIA"][6] > -1e-15 and M["SDIRK"][6] < -0.08
def step(A, b, c, f, J, t, y, h, full):         # Z_i = h sum_j a_ij f(t + c_j h, y + Z_j), Newton on Z
    Z, its = [0.0, 0.0], 0
    while True:
        its += 1
        F = [f(t + c[i] * h, y + Z[i]) for i in range(2)]
        r = [Z[i] - h * (A[i][0] * F[0] + A[i][1] * F[1]) for i in range(2)]
        j = [J(t + c[i] * h, y + Z[i]) for i in range(2)] if full else [J(t, y)] * 2   # simplified: frozen
        m11, m12, m21, m22 = 1 - h * A[0][0] * j[0], -h * A[0][1] * j[1], -h * A[1][0] * j[0], 1 - h * A[1][1] * j[1]
        d = m11 * m22 - m12 * m21; d0, d1 = (m12 * r[1] - m22 * r[0]) / d, (m21 * r[0] - m11 * r[1]) / d
        Z = [Z[0] + d0, Z[1] + d1]
        if max(abs(d0), abs(d1)) < 1e-13: break
    if b == A[1]: return y + Z[1], its             # stiffly accurate (Radau IIA, SDIRK): y_(n+1) is the last stage
    F = [f(t + c[i] * h, y + Z[i]) for i in range(2)]
    return y + h * (b[0] * F[0] + b[1] * F[1]), its
def run(k, lam, h, y0=1.0, nonlin=False, full=False, T=1.0, jolt=False):
    A, b, c = M[k][:3]
    if nonlin: f, J = (lambda t, y: -500 * (y * y - cos(t) ** 2) - sin(t)), (lambda t, y: -1000 * y)
    elif jolt: f, J = (lambda t, y: lam * y), (lambda t, y: lam)        # the fast part alone: y' = lam y
    else: f, J = (lambda t, y: lam * (y - cos(t)) - sin(t)), (lambda t, y: lam)
    n, y, its = round(T / h), y0, 0
    for i in range(n): y, k_ = step(A, b, c, f, J, i * h, y, h, full); its += k_
    return y - (0.0 if jolt else cos(n * h)), its
print("the example, h = 0.1 to t = 1 (z = -100): error at t = 1; what is left of a jolt of 1.0 at t = 0")
for k in M:
    e, gap1, gap = run(k, -1000.0, 0.1)[0], run(k, -1000.0, 0.1, T=0.1, jolt=True)[0], run(k, -1000.0, 0.1, jolt=True)[0]
    print(f"  {k}: error {sci(e)}; jolt after 1 step {gap1:.6f}, after 10 steps {sci(gap)}")
    assert abs(gap1 - R(*M[k][:2], -100.0)) < 1e-13 and abs(gap / R(*M[k][:2], -100.0) ** 10 - 1) < 1e-10, "R(z)^n"
hs, O = [0.2, 0.1, 0.05, 0.025, 0.0125], {}
for lam in (-1.0, -1000.0, -1e6):
    print(f"errors at t = 1 for h = 0.2 down to 0.0125, lambda = {sci(lam, 0)}; observed orders")
    for k in M:
        E = [abs(run(k, lam, h)[0]) for h in hs]; o = [log10(E[i] / E[i + 1]) / log10(2) for i in range(4)]
        print(f"  {k}: " + ", ".join(sci(e) for e in E) + "; " + ", ".join(f"{x:.2f}" for x in o))
        O[(k, lam)] = (E, o)
print("chart, log10 h: " + ", ".join(f"{log10(h):.2f}" for h in hs))
for k in ("Gauss", "Radau IIA"): print(f"chart, log10 error, {k}, lambda = -1000: " + ", ".join(f"{log10(e):.2f}" for e in O[(k, -1000.0)][0]))
for k, p, q in (("Gauss", 4, 2), ("Radau IIA", 3, 2), ("SDIRK", 2, 1)):
    assert abs(O[(k, -1.0)][1][3] - p) < 0.1 and abs(O[(k, -1e6)][1][2] - q) < 0.1, "order p when gentle, q when stiff"
assert O[("Gauss", -1000.0)][1][0] < 2.6 and O[("Gauss", -1000.0)][1][3] > 3.8, "Gauss recovers once |z| is small"
(eS, iS), (eF, iF) = run("Radau IIA", 0, 0.1, nonlin=True), run("Radau IIA", 0, 0.1, nonlin=True, full=True)
print(f"nonlinear pull y' = -500(y^2 - cos^2 t) - sin t, Radau IIA, h = 0.1, 10 steps:")
print(f"  simplified Newton {iS} iterations, error {sci(eS)}; full Newton {iF} iterations, error {sci(eF)}")
assert abs(eS - eF) < 1e-10 and 1e-7 < abs(eS) < 1e-5 and iF < iS, "same answer, more but cheaper iterations"
for n in (100, 1000):
    lu, bs = 2 * (2 * n) ** 3 / 3, 2 * (2 * n) ** 2
    print(f"n = {n}: one LU, Radau IIA (size {2 * n}) {sci(lu)}, SDIRK (size {n}) {sci(2 * n ** 3 / 3)} flops; 10 Radau steps: simplified {sci(10 * lu + iS * bs)}, full {sci(iF * (lu + bs))}")
for k, A in (("Gauss", AG), ("Radau IIA", AR)):    # eigenvalues of A^-1 = the poles of R(z)
    d = A[0][0] * A[1][1] - A[0][1] * A[1][0]; tr = (A[0][0] + A[1][1]) / d; dt = 1 / d
    re, im = tr / 2, sqrt(dt - tr * tr / 4)
    print(f"eigenvalues of A^-1, {k}: {re:.6f} +/- {im:.6f}i")
    assert abs(1 / R(A, M[k][1], complex(re, im))) < 1e-12, "a pole of R in the right half-plane"
print("ALL CHECKS PASS")
