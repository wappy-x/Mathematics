# Hille-Yosida and generators -- the check behind the card.  Standard library only.
# Bar: 1 m, ends held at 0 K rise, H = L2(0, 1).  A = kappa d^2/dx^2 on H^2 with zero ends.
# Roads: closed forms on sine modes, a Green's-function integral by Simpson's rule,
# tridiagonal solves on an N-cell grid, power iteration for norms, Yosida's series.
import math

KAPPA = 1.11e-4            # m^2/s, copper's thermal diffusivity (illustrative)
T, LAM = 600.0, 0.01       # s, 1/s
MU1 = KAPPA * math.pi ** 2  # decay rate of the arch sin(pi x), 1/s

def solve(lam, f, N, sign=1.0):
    # (lam I - sign*A_N) u = f on the N - 1 inside points; Thomas algorithm.
    h2 = (1.0 / N) ** 2
    a, b = -sign * KAPPA / h2, lam + 2 * sign * KAPPA / h2
    n = len(f); c, d = [0.0] * n, [0.0] * n
    for i in range(n):
        m = b - (a * c[i - 1] if i else 0.0)
        c[i] = a / m
        d[i] = (f[i] - (a * d[i - 1] if i else 0.0)) / m
    for i in range(n - 2, -1, -1):
        d[i] -= c[i] * d[i + 1]
    return d

def rnorm(v, N):
    return math.sqrt(sum(x * x for x in v) / N)

def power_norm(lam, N, its=400):
    # Largest eigenvalue of the symmetric resolvent matrix = its operator norm.
    v = [1.0] * (N - 1); r = 0.0
    for _ in range(its):
        w = solve(lam, v, N)
        r = sum(x * y for x, y in zip(v, w)) / sum(x * x for x in v)
        s = math.sqrt(sum(x * x for x in w)); v = [x / s for x in w]
    return r

def top_eig(N):
    # Largest eigenvalue of -A_N by Sturm bisection: the LDL^T pivots of -A_N - x I
    # that are negative count the eigenvalues below x.  No eigenvalue formula used.
    d, e2 = 2 * KAPPA * N * N, (KAPPA * N * N) ** 2
    def below(x):
        c, q = 0, 1.0
        for i in range(N - 1):
            q = d - x - (e2 / q if i else 0.0); q = q or 1e-300; c += q < 0
        return c
    lo, hi = 0.0, 2 * d
    for _ in range(100):
        mid = (lo + hi) / 2; lo, hi = (lo, mid) if below(mid) == N - 1 else (mid, hi)
    return (lo + hi) / 2

def simpson(f, a, b, m=2000):
    h = (b - a) / m
    return (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, m))) * h / 3

ok = []
def check(name, got, want, tol):
    ok.append(abs(got - want) <= tol)
    assert ok[-1], (name, got, want)

print(f"setup, kappa = 1.11e-4 m^2/s, arch decay rate kappa pi^2 = {MU1:.8f} 1/s, lambda = 0.01 1/s")
# 1. The resolvent test on the grid, at several N.
print("test, N, ||R(lambda, A_N)|| by power iteration (s), closed form (s), bar limit 1/(lambda + kappa pi^2) (s), bound 1/lambda (s)")
for N in (10, 100, 1000):
    pw = power_norm(LAM, N)
    cf = 1 / (LAM + 4 * KAPPA * N * N * math.sin(math.pi / (2 * N)) ** 2)
    print(f"test, {N}, {pw:.4f}, {cf:.4f}, {1 / (LAM + MU1):.4f}, {1 / LAM:.4f}")
    check("power", pw, cf, 1e-6); assert pw <= 1 / LAM
check("bar limit", cf, 1 / (LAM + MU1), 1e-3)
# 2. The true resolvent through its Green's function, against modes and grid.
m = math.sqrt(LAM / KAPPA)
print(f"green, m = sqrt(lambda / kappa) = {m:.6f} 1/m")
def G(x, s):
    lo, hi = min(x, s), max(x, s)
    return math.sinh(m * lo) * math.sinh(m * (1 - hi)) / (KAPPA * m * math.sinh(m))
arch = lambda s: 10 * math.sin(math.pi * s)
green = LAM * (simpson(lambda s: G(0.5, s) * arch(s), 0, 0.5) + simpson(lambda s: G(0.5, s) * arch(s), 0.5, 1))
mode = 10 * LAM / (LAM + MU1)
N = 1000; xs = [j / N for j in range(1, N)]
grid = LAM * solve(LAM, [arch(x) for x in xs], N)[N // 2 - 1]
print(f"discounted arch, midpoint of lambda R u0: Green {green:.6f} K, mode {mode:.6f} K, grid N=1000 {grid:.6f} K")
check("green", green, mode, 1e-8); check("grid", grid, mode, 1e-5)
u = [LAM * y for y in solve(LAM, [1.0] * (N - 1), N)]
flat = lambda x: 1 - math.cosh(m * (x - 0.5)) / math.cosh(m / 2)
flat_norm = math.sqrt(simpson(lambda x: flat(x) ** 2, 0, 1))
print(f"discounted flat 1 K source: ||lambda R f|| closed form {flat_norm:.6f} K, grid {rnorm(u, N):.6f} K, ||f|| = 1 K")
check("flat", rnorm(u, N), flat_norm, 1e-3); assert flat_norm <= 1
energy = lambda x: math.sinh(m * (x - 0.5)) * m / math.cosh(m / 2)
lhs = flat_norm ** 2 + KAPPA * simpson(lambda x: energy(x) ** 2, 0, 1) / LAM
print(f"energy identity, w = lambda R f: ||w||^2 + (kappa/lambda) ||w'||^2 = {lhs:.6f}, <f, w> = {simpson(flat, 0, 1):.6f}")
check("energy", lhs, simpson(flat, 0, 1), 1e-9)
# 3. Recover the semigroup: implicit Euler (n steps) and Yosida's approximation.
exact = 10 * math.exp(-MU1 * T)
print(f"hand, pi^2 = {math.pi ** 2:.6f}, lambda + kappa pi^2 = {LAM + MU1:.8f} 1/s, a = kappa pi^2 t = {MU1 * T:.6f}, one step factor at n = 10: {1 / (1 + MU1 * T / 10):.6f}, e^(-a) = {math.exp(-MU1 * T):.7f}")
print(f"exact, midpoint after {T:.0f} s: 10 exp(-kappa pi^2 t) = {exact:.6f} K")
print("euler, n, mode formula (K), grid N=1000 (K), error (K), n * error")
errs = []
for n in (1, 10, 100, 1000):
    mf = 10 * (1 + MU1 * T / n) ** (-n)
    v = [arch(x) for x in xs]
    for _ in range(n):
        v = [(n / T) * y for y in solve(n / T, v, N)]
    errs.append(mf - exact)
    print(f"euler, {n}, {mf:.6f}, {v[N // 2 - 1]:.6f}, {mf - exact:.6f}, {n * (mf - exact):.6f}")
    check("euler grid", v[N // 2 - 1], mf, 1e-3)
lim = 10 * math.exp(-MU1 * T) * (MU1 * T) ** 2 / 2
print(f"euler, limit of n * error = 10 e^(-a) a^2 / 2 with a = kappa pi^2 t: {lim:.6f}")
check("rate", 1000 * errs[-1], lim, 2e-3)
print("chart, log10 n, 0, 1, 2, 3")
print("chart, log10 error, " + ", ".join(f"{math.log10(e):.3f}" for e in errs))
print("yosida, lambda (1/s), mode formula (K), grid N=200 series (K), error (K)")
N2 = 200; xs2 = [j / N2 for j in range(1, N2)]
for lam in (0.01, 0.1, 1.0):
    mf = 10 * math.exp(-T * lam * MU1 / (lam + MU1))
    v = [arch(x) for x in xs2]; acc = [0.0] * len(v); w = math.exp(-lam * T)
    for k in range(int(lam * T + 12 * math.sqrt(lam * T) + 20)):
        acc = [p + w * q for p, q in zip(acc, v)]
        v = [lam * y for y in solve(lam, v, N2)]; w *= lam * T / (k + 1)
    print(f"yosida, {lam:.2f}, {mf:.6f}, {acc[N2 // 2 - 1]:.6f}, {mf - exact:.6f}")
    check("yosida", acc[N2 // 2 - 1], mf, 5e-4)
# 4. What breaks.
print("backward, N, top growth rate of -A_N by Sturm bisection (1/s), closed form 4 kappa N^2 sin^2((N-1) pi/(2N)) (1/s), row-sum bound 4 kappa N^2 (1/s)")
for N in (10, 100, 1000):
    st, w = top_eig(N), 4 * KAPPA * N * N * math.sin((N - 1) * math.pi / (2 * N)) ** 2
    print(f"backward, {N}, {st:.4f}, {w:.4f}, {4 * KAPPA * N * N:.4f}"); check("sturm", st, w, 1e-6)
bk = max(1 / abs(LAM - MU1 * k * k) for k in range(1, 50))
print(f"breaks, backward heat at lambda = 0.01: ||R(lambda, -A)|| = {bk:.1f} s against the bound 1/lambda = 100 s (mode n = 3, kappa pi^2 9 = {9 * MU1:.8f} 1/s)")
assert bk > 1 / LAM
dt = T / 10; wN = 4 * KAPPA * 100 ** 2 * math.sin(99 * math.pi / 200) ** 2
print(f"breaks, explicit Euler, N=100, 10 steps of {dt:.0f} s: worst mode factor per step {1 - dt * wN:.4f}, after 10 steps 10^{10 * math.log10(abs(1 - dt * wN)):.2f}, stable only for steps up to h^2/(2 kappa) = {0.0001 / (2 * KAPPA):.4f} s")
print(f"breaks, one implicit step: {10 / (1 + MU1 * T):.6f} K against {exact:.6f} K")
print(f"breaks, Yosida with lambda = 0.01: {10 * math.exp(-T * 0.01 * MU1 / (0.01 + MU1)):.6f} K against {exact:.6f} K")
print("ALL CHECKS PASS")
