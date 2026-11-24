# Quantum tunnelling -- the check behind the card.  Standard library only.
# An electron of 1 eV meets a wall 2 eV high and 0.5 nm wide.  Three roads to the
# chance T that it gets through: the closed form, the four matching equations
# solved by Gaussian elimination, and an RK4 march of Schrodinger's equation
# itself.  Then the thick-barrier (WKB) estimate, and a rounded barrier.
import cmath, math

H = 6.62607015e-34          # Planck constant, J s (exact in SI)
HBAR = H / (2 * math.pi)    # reduced Planck constant, J s
ME = 9.1093837139e-31       # electron mass, kg (CODATA 2022)
EV = 1.602176634e-19        # one electronvolt, J (exact in SI)
K = 2 * ME * EV * 1e-18 / HBAR ** 2   # k^2 = K (E - V): k in 1/nm, E and V in eV
E, V0, A = 1.0, 2.0, 0.5    # electron energy (eV), wall height (eV), wall width (nm)

def closed(E, V0, a, K=K):  # road 1: T = 1 / (1 + V0^2 sinh^2(kappa a) / (4 E (V0 - E)))
    kap = math.sqrt(K * (V0 - E))
    return 1 / (1 + V0 ** 2 * math.sinh(kap * a) ** 2 / (4 * E * (V0 - E)))

def solve(M, b):            # Gaussian elimination with row swaps, complex entries
    n = len(b)
    M = [list(M[i]) + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            M[r] = [x - f * y for x, y in zip(M[r], M[c])]
    x = [0j] * n
    for r in range(n - 1, -1, -1):
        x[r] = (M[r][n] - sum(M[r][j] * x[j] for j in range(r + 1, n))) / M[r][r]
    return x

def matched(E, V0, a):      # road 2: unknowns r, C, D, t; psi and psi' agree at x = 0 and x = a
    k, q = math.sqrt(K * E), math.sqrt(K * (V0 - E))
    ep, em, ek = math.exp(q * a), math.exp(-q * a), cmath.exp(1j * k * a)
    M = [[-1, 1, 1, 0], [1j * k, q, -q, 0], [0, ep, em, -ek], [0, q * ep, -q * em, -1j * k * ek]]
    return solve(M, [1, 1j * k, 0, 0])

def march(V, E, x0, x1, n, keep=0):  # road 3: put t = 1 at x1, step psi'' = K (V - E) psi back to x0
    k, h = math.sqrt(K * E), (x0 - x1) / n
    y, v, pts = cmath.exp(1j * k * x1), 1j * k * cmath.exp(1j * k * x1), []
    for i in range(n):
        x = x1 + i * h
        if keep and i % keep == 0: pts.append((x, y))
        g = K * (V(x + h / 2) - E)   # the wall's height at the middle of the step
        k1y, k1v = v, g * y
        k2y, k2v = v + h / 2 * k1v, g * (y + h / 2 * k1y)
        k3y, k3v = v + h / 2 * k2v, g * (y + h / 2 * k2y)
        k4y, k4v = v + h * k3v, g * (y + h * k3y)
        y += h / 6 * (k1y + 2 * k2y + 2 * k3y + k4y)
        v += h / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)
    pts.append((x0, y))
    inc = (y + v / (1j * k)) * cmath.exp(-1j * k * x0) / 2   # incoming wave's size
    ref = (y - v / (1j * k)) * cmath.exp(1j * k * x0) / 2    # reflected wave's size
    return 1 / abs(inc) ** 2, abs(ref / inc) ** 2, inc, pts

wall = lambda x: V0 if 0 <= x <= A else 0.0
k, kap = math.sqrt(K * E), math.sqrt(K * (V0 - E))
T1 = closed(E, V0, A)
r, C, D, t = matched(E, V0, A)
T3, R3, inc, pts = march(wall, E, -0.5, 1.0, 6000, keep=200)
est = 16 * E * (V0 - E) / V0 ** 2 * math.exp(-2 * kap * A)
print("constants: hbar %.9f x 10^-34 J s, m_e %.10f x 10^-31 kg" % (HBAR * 1e34, ME * 1e31))
print("K = 2 m_e (1 eV)(1 nm)^2 / hbar^2 = %.4f per eV per nm^2" % K)
print("electron E = %.1f eV, wall V0 = %.1f eV, width a = %.2f nm" % (E, V0, A))
print("k = %.4f per nm, kappa = %.4f per nm, kappa a = %.4f" % (k, kap, kap * A))
print("hand route: sinh(kappa a) = %.4f, sinh^2 = %.4f, cosh(kappa a) = %.4f" % (
    math.sinh(kap * A), math.sinh(kap * A) ** 2, math.cosh(kap * A)))
print("road 1, closed form:      T = %.6f" % T1)
print("road 2, matching solved:  T = %.6f, R = %.6f, R + T = %.12f" % (abs(t) ** 2, abs(r) ** 2, abs(r) ** 2 + abs(t) ** 2))
print("road 3, RK4 march:        T = %.6f, R = %.6f" % (T3, R3))
print("inside the wall: C = %.6f, D = %.6f (size of the rising and falling parts)" % (abs(C), abs(D)))
print("thick-wall estimate 16 E (V0 - E)/V0^2 e^(-2 kappa a) = 4 e^(-%.4f) = %.6f" % (2 * kap * A, est))
print("bare WKB exponent e^(-2 kappa a) = %.6f" % math.exp(-2 * kap * A))
print("of 1,000,000 electrons: %.0f through, %.0f bounce back" % (1e6 * T1, 1e6 * (1 - T1)))
psi = sorted((round(x, 2), abs(y / inc)) for x, y in pts)
print("chart x nm: " + " ".join("%.2f" % x for x, _ in psi))
print("chart |psi|: " + " ".join("%.2f" % m for _, m in psi))
print("|psi| left peak %.4f = 1 + |r|, right side %.4f = sqrt(T)" % (1 + abs(r), math.sqrt(T1)))
widths = [0.1 * i for i in range(1, 11)]
ex = [closed(E, V0, a) for a in widths]
es = [4 * math.exp(-2 * kap * a) for a in widths]
print("width nm:   " + " ".join("%6.1f" % a for a in widths))
print("log10 T:    " + " ".join("%6.2f" % math.log10(x) for x in ex))
print("log10 est:  " + " ".join("%6.2f" % math.log10(x) for x in es))
print("estimate / exact: 0.5 nm %.4f, 1.0 nm %.4f" % (es[4] / ex[4], es[9] / ex[9]))
dbl = closed(E, V0, 2 * A) / T1
print("double the width: T(1.0 nm) = %.4f x 10^-4, ratio %.6f, e^(-2 kappa a) = %.6f" % (
    closed(E, V0, 2 * A) * 1e4, dbl, math.exp(-2 * kap * A)))
print("per 0.1 nm of extra width: T x %.4f; straight-line guess for double width T/2 = %.6f" % (math.exp(-0.2 * kap), T1 / 2))
w = 0.5                     # rounded wall V0 / cosh^2(x / w), with an exact answer
s, u = math.sinh(math.pi * k * w) ** 2, math.cosh(math.pi / 2 * math.sqrt(4 * K * V0 * w * w - 1)) ** 2
Te = s / (s + u)
Tr, Rr, _, _ = march(lambda x: V0 / math.cosh(x / w) ** 2, E, -4.0, 4.0, 16000)
xt, N = w * math.acosh(math.sqrt(V0 / E)), 20000
th = sum(math.sqrt(K * (V0 / math.cosh((-xt + (i + 0.5) * 2 * xt / N) / w) ** 2 - E)) for i in range(N)) * 2 * xt / N
th_c = math.pi * w * math.sqrt(K) * (math.sqrt(V0) - math.sqrt(E))
print("rounded wall, w = 0.5 nm: exact T = %.6f, RK4 T = %.6f, turning points +-%.4f nm" % (Te, Tr, xt))
print("rounded wall WKB: theta = %.4f (formula %.4f), e^(-2 theta) = %.6f, ratio exact/WKB %.3f" % (th, th_c, math.exp(-2 * th), Te / math.exp(-2 * th)))
kt = math.sqrt(K * 4.5)
print("STM gap, 4.5 eV barrier: kappa = %.4f per nm, 0.1 nm more gap: current x %.4f (1/%.2f)" % (
    kt, math.exp(-0.2 * kt), math.exp(0.2 * kt)))
print("mistake, bare WKB exponent: T = %.6f (right %.6f)" % (math.exp(-2 * kap * A), T1))
print("mistake, wave size 2 e^(-kappa a) = %.6f taken as the chance: %.1f times too big (true size |t| = %.4f)" % (
    2 * math.exp(-kap * A), 2 * math.exp(-kap * A) / T1, abs(t)))
print("mistake, thick estimate at 0.1 nm (kappa a = %.2f): T = %.4f (right %.4f)" % (kap * 0.1, es[0], ex[0]))
kh = kap / (2 * math.pi)      # h = 2 pi hbar used where hbar belongs makes kappa 2 pi times too small
print("mistake, h for hbar: kappa = %.4f per nm, T = %.4f (right %.6f)" % (kh, closed(E, V0, A, K / (2 * math.pi) ** 2), T1))
print("try: E = 3 eV, over the top: T = %.4f; effective mass 0.067 m_e: T = %.4f; wall 3 eV high: T = %.6f" % (
    march(wall, 3.0, -0.5, 1.0, 6000)[0], closed(E, V0, A, K * 0.067), closed(E, 3.0, A)))

assert abs(abs(t) ** 2 - T1) / T1 < 1e-12                          # matching meets closed form
assert abs(T3 - T1) / T1 < 1e-8 and abs(R3 + T3 - 1) < 1e-8         # RK4 march meets closed form
assert abs(abs(r) ** 2 + abs(t) ** 2 - 1) < 1e-12                   # nothing lost: R + T = 1
assert abs(Tr - Te) / Te < 1e-5                                     # RK4 meets the rounded wall's exact T
assert abs(th - th_c) / th_c < 1e-4                                 # WKB integral, two ways
assert 0.01 < es[4] / ex[4] - 1 < 0.02 and es[9] / ex[9] - 1 < 1e-3 # estimate improves as the wall thickens
assert abs(dbl / math.exp(-2 * kap * A) - 1) < 0.02                 # doubling the width costs e^(-2 kappa a)
print("ALL CHECKS PASS")
