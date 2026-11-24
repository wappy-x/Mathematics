# Kato-Rellich and perturbed eigenvalues: a 2 x 2 rehearsal, then hydrogen, -Laplacian - 1/r on R^3.
# Standard library only. No eigen-solver is imported: roots, bisection, contour sums and Simpson are written out.
from math import sqrt, exp, pi, cos, sin

def simpson(f, a, b, n=4000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

# ---- Part 1: M(e) = A + eV with A = diag(1, 2), V = [[0, 1], [1, 0]] ----
def exact_low(e):  return (3 - sqrt(1 + 4 * e * e)) / 2      # road 1: the quadratic formula
def exact_high(e): return (3 + sqrt(1 + 4 * e * e)) / 2
V = [[0.0, 1.0], [1.0, 0.0]]
def rs2(e):        return 1 + e * V[0][0] + e * e * V[1][0] * V[1][0] / (1 - 2)  # road 2: Rayleigh-Schroedinger

def riesz(e, K=64, c=1.0, rho=0.5):                          # road 3: P = (1/2 pi i) closed integral of (z - M)^-1 dz
    P, rmax = [[0j, 0j], [0j, 0j]], 0.0
    for k in range(K):
        w = complex(cos(2 * pi * k / K), sin(2 * pi * k / K))
        z = c + rho * w
        rmax = max(rmax, 1 / abs(z - 1), 1 / abs(z - 2))      # |R(z, A)| for A = diag(1, 2)
        a, b, d = z - 1, -e, z - 2                            # z - M = [[a, b], [b, d]]
        det = a * d - b * b
        inv = [[d / det, -b / det], [-b / det, a / det]]
        for i in range(2):
            for j in range(2):
                P[i][j] += inv[i][j] * rho * w / K
    trP = (P[0][0] + P[1][1]).real
    trMP = (1 * P[0][0] + e * P[1][0] + e * P[0][1] + 2 * P[1][1]).real
    return trP, trMP, rmax

e = 0.1
trP, lam3, rmax = riesz(e)
print("== 2 x 2: M = [[1, e], [e, 2]], e = 0.1 ==")
print(f"exact lower eigenvalue        {exact_low(e):.6f}")
print(f"second order 1 - e^2          {rs2(e):.6f}")
print(f"Riesz contour: trace P        {trP:.6f}")
print(f"Riesz contour: trace MP       {lam3:.6f}")
print(f"max |R(z, A)| on the circle   {rmax:.6f}")
print(f"error of 1 - e^2              {exact_low(e) - rs2(e):.6f}")
print(f"first order only, 1 + e V11   {1 + e * V[0][0]:.6f}")
print(f"wrong sign, divide by 2 - 1   {1 + e * e * V[1][0] * V[1][0] / (2 - 1):.6f}")
print(f"guaranteed range |e| < 1/(max|R| |V|) = {1 / (rmax * 1.0):.6f}")
assert abs(lam3 - exact_low(e)) < 1e-12 and abs(trP - 1) < 1e-12
assert abs(rmax - 1 / 0.5) < 1e-12                            # on the circle, |z - 1| = radius 0.5
assert abs(exact_low(e) - rs2(e)) < 2 * e ** 4
print("chart e, lower, 1 - e^2, upper")
for i in range(11):
    x = i * 0.05
    print(f"chart {x:.2f} {exact_low(x):.6f} {rs2(x):.6f} {exact_high(x):.6f}")

def series(e, K):                                            # (3 - sum_k binom(1/2, k) (4e^2)^k) / 2
    c, s, x, xk = 1.0, 0.0, 4 * e * e, 1.0
    for k in range(K + 1):
        s += c * xk
        c, xk = c * (0.5 - k) / (k + 1), xk * x
    return (3 - s) / 2
print("power series in e, terms k = 0..K, up to e^(2K)")
for ee in (0.4, 0.6):
    print(f"e = {ee:.1f}: K=5 {series(ee, 5):.6f}  K=10 {series(ee, 10):.6f}  K=20 {series(ee, 20):.6f}  exact {exact_low(ee):.6f}")
assert abs(series(0.4, 20) - exact_low(0.4)) < 1e-2 and abs(series(0.6, 20) - exact_low(0.6)) > 1

# ---- Part 2: hydrogen, psi = e^(-r/2); radial integrals carry the 4 pi r^2 shell area ----
nrm = simpson(lambda r: 4 * pi * r * r * exp(-r), 0, 60)
kin = simpson(lambda r: 4 * pi * r * r * 0.25 * exp(-r), 0, 60)   # |grad psi|^2 = psi'^2 = e^(-r)/4
pot = simpson(lambda r: 4 * pi * r * exp(-r), 0, 60)               # <psi, psi/r>
print("== hydrogen ground state psi = e^(-r/2) ==")
print(f"|psi|^2/pi {nrm/pi:.6f}  kinetic/pi {kin/pi:.6f}  <psi,psi/r>/pi {pot/pi:.6f}")
print(f"Rayleigh quotient (kin - pot)/|psi|^2  {(kin - pot) / nrm:.6f}")
assert abs((kin - pot) / nrm + 0.25) < 1e-9
psi = lambda r: exp(-r / 2)
res, hd = 0.0, 1e-3
for r in (0.5, 1.0, 2.0, 5.0):
    d2 = (psi(r + hd) - 2 * psi(r) + psi(r - hd)) / (hd * hd)
    d1 = (psi(r + hd) - psi(r - hd)) / (2 * hd)
    res = max(res, abs(-d2 - 2 * d1 / r - psi(r) / r + psi(r) / 4))
print(f"max |H psi + psi/4| at r = 0.5, 1, 2, 5 (difference quotients)  {res:.6f}")
assert res < 1e-6

print("== relative bound on u = e^(-s r): |u/r| <= 0.5 |Lap u| + 3 |u| ==")
print("s       |u/r|      |Lap u|    |u|        bound      |u/r|/|Lap u|  Sobolev, beta = 2, on max|u| = 1")
for s in (0.5, 2.0, 8.0, 32.0):
    L = 40 / s
    ur = sqrt(simpson(lambda r: 4 * pi * exp(-2 * s * r), 0, L))
    lu = sqrt(simpson(lambda r: 4 * pi * exp(-2 * s * r) * (s * s * r - 2 * s) * (s * s * r - 2 * s), 0, L))
    un = sqrt(simpson(lambda r: 4 * pi * r * r * exp(-2 * s * r), 0, L))
    for got, want in ((ur, sqrt(2 * pi / s)), (lu, sqrt(5 * pi * s)), (un, sqrt(pi / (s * s * s)))):
        assert abs(got / want - 1) < 1e-7
    bound, sob = 0.5 * lu + 3 * un, (lu + 4 * un) / sqrt(16 * pi)
    assert ur <= bound and 1 <= sob
    print(f"{s:<7.1f} {ur:<10.6f} {lu:<10.6f} {un:<10.6f} {bound:<10.6f} {ur / lu:<14.6f} {sob:.6f}")
print("trade-off a = sqrt(r0/(2 beta)), b = beta^1.5 sqrt(r0/2) + 1/r0")
for r0, beta in ((1.0, 2.0), (0.02, 1.0), (0.0002, 1.0)):
    print(f"r0 = {r0:.4f}, beta = {beta:.1f}: a = {sqrt(r0 / (2 * beta)):.6f}, b = {beta * sqrt(beta) * sqrt(r0 / 2) + 1 / r0:.6f}")
print(f"mu = 12: a + b/mu = {0.5 + 3 / 12:.6f}")

def lowest(Z, N, k=1, Rmax=40.0):                            # road 2: radial grid, u = r psi, bisection by Sturm count
    h = Rmax / (N + 1)
    def count(x):
        q, c = 1.0, 0
        for i in range(1, N + 1):
            q = 2 / (h * h) - Z / (i * h) - x - (1 / ((h * h) * (h * h)) / q if i > 1 else 0)
            if q == 0: q = 1e-300
            if q < 0: c += 1
        return c
    lo, hi = -2.0, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if count(mid) >= k: hi = mid
        else: lo = mid
    return (lo + hi) / 2
print("== grid truncation, box of radius 40, N points ==")
prev = None
for N in (100, 200, 400, 800):
    E = lowest(1.0, N)
    print(f"N = {N:<4} lowest {E:.6f}  error {E + 0.25:.6f}" + (f"  error ratio {(prev + 0.25) / (E + 0.25):.2f}" if prev else ""))
    prev = E
E2 = lowest(1.0, 800, 2)
print(f"N = 800 second level {E2:.6f} (exact -1/16 = -0.062500)")
assert abs(prev + 0.25) < 1e-3 and abs(E2 + 0.0625) < 1e-3

print("== charge Z = 1 + eps: first order -1/4 - eps <psi,psi/r>/|psi|^2, exact -(1+eps)^2/4 ==")
for eps in (0.1, 1.0):
    first, grid = -0.25 - eps * pot / nrm, lowest(1 + eps, 800)
    print(f"eps = {eps:.1f}: first order {first:.6f}  exact {-(1 + eps) * (1 + eps) / 4:.6f}  grid N = 800 {grid:.6f}")
    assert abs(grid + (1 + eps) ** 2 / 4) < 2e-3 * (1 + eps) ** 4
assert abs(pot / nrm - 0.5) < 1e-9
print("ALL CHECKS PASS")
