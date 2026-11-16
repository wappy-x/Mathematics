# Fredholm alternative -- the check behind the card.  Standard library only.
# A 1 m layer of damp wood chips, both faces held at air temperature, heated
# by 25 W/m^3 plus 1.25 W/m^3 per kelvin of warming; k = 0.25 W/(m K).  All
# illustrative.  Scaled by k: u = f + lam K u, f = K q, q = 100 K/m^2,
# lam = 5 1/m^2, kernel K(x, y) = min(x, y) (1 - max(x, y)) on 0 <= x, y <= 1 m.
import math
PI = math.pi
KC, Q0, BETA = 0.25, 25.0, 1.25
q, lam = Q0 / KC, BETA / KC
L1 = PI * PI                              # lowest eigenvalue n^2 pi^2 of -u''

def kern(x, y): return min(x, y) * (1 - max(x, y))
def total(xs):                            # plain left-to-right sum, as in the Rust
    s = 0.0
    for v in xs: s += v
    return s
def closed(lv, x):                        # road 1: -u'' = q + lv u, u(0) = u(1) = 0
    if lv == 0: return q * x * (1 - x) / 2
    s = math.sqrt(lv)
    return q * (math.cos(s * (x - 0.5)) / math.cos(s / 2) - 1) / lv
def apply_k(p):                           # K on a polynomial: -w'' = p, w(0) = w(1) = 0
    w = [0.0, 0.0] + [-p[k] / ((k + 1) * (k + 2)) for k in range(len(p))]
    w[1] = -total(w)
    return w
def peval(p, x):
    v = 0.0
    for c in reversed(p): v = v * x + c
    return v
def neumann(lv, qpoly, nmax, x=0.5):      # road 2: u = f + lv K f + lv^2 K^2 f + ...
    t, terms = apply_k(qpoly), []
    for _ in range(nmax + 1):
        terms.append(peval(t, x))
        t = [lv * c for c in apply_k(t)]
    return terms
def partial(terms, n): return total(terms[:n + 1])
def modes(lv, x, nmax):                   # road 3: sum of <q, phi_n> phi_n(x) / (lam_n - lv)
    return total(4 * q * math.sin(n * PI * x) / (n * PI * (n * n * L1 - lv)) for n in range(1, nmax + 1, 2))
def nystrom(lv, n):                       # road 4: trapezoid grid, Gaussian elimination
    h = 1.0 / n
    xs = [i * h for i in range(1, n)]
    a = [[(1.0 if i == j else 0.0) - lv * h * kern(xi, xj) for j, xj in enumerate(xs)] + [closed(0, xi)]
         for i, xi in enumerate(xs)]
    m = n - 1
    for c in range(m):
        p = max(range(c, m), key=lambda r: abs(a[r][c]))
        a[c], a[p] = a[p], a[c]
        for r in range(c + 1, m):
            f = a[r][c] / a[c][c]
            for k in range(c, m + 1): a[r][k] -= f * a[c][k]
    u = [0.0] * m
    for r in range(m - 1, -1, -1):
        u[r] = (a[r][m] - total(a[r][k] * u[k] for k in range(r + 1, m))) / a[r][r]
    return u[n // 2 - 1]                  # the node x = 0.5 m
def power(n, iters):                      # top eigenvalue of the grid's K, then 1/mu
    h = 1.0 / n
    xs = [i * h for i in range(1, n)]
    v, mu = [1.0] * len(xs), 0.0
    for _ in range(iters):
        w = [h * total(kern(xi, xj) * vj for xj, vj in zip(xs, v)) for xi in xs]
        mu = math.sqrt(total(c * c for c in w)) / math.sqrt(total(c * c for c in v))
        v = w
    return 1 / mu
def simpson(f, lo, hi, panels):
    h = (hi - lo) / panels
    return h / 3 * total((1 if i in (0, panels) else 4 if i % 2 else 2) * f(lo + i * h) for i in range(panels + 1))
def kint(g, x):                           # (K g)(x) by Simpson, split at the kink y = x
    return simpson(lambda y: kern(x, y) * g(y), 0, x, 200) + simpson(lambda y: kern(x, y) * g(y), x, 1, 200)

u5 = closed(lam, 0.5)
print(f"layer 1 m, k = {KC} W/(m K): q = {q:.0f} K/m^2, lam = {lam:.0f} 1/m^2, critical lam_1 = pi^2 = {L1:.4f} 1/m^2")
print(f"critical beta = k pi^2 = {KC * L1:.4f} W/(m^3 K); critical thickness at beta = {BETA}: {PI * math.sqrt(KC / BETA):.3f} m")
print(f"middle rise: no reaction {closed(0, 0.5):.3f} K; with reaction, closed form {u5:.3f} K")
terms = neumann(lam, [q], 40)
print("Neumann generations r = 0 to 6 at the middle, K: " + ", ".join(f"{t:.3f}" for t in terms[:7]))
print("  partial sums r = 0, 1, 2, 3, 5, 10, 20: " + ", ".join(f"{partial(terms, n):.3f}" for n in (0, 1, 2, 3, 5, 10, 20)))
print(f"  first omitted term after r = 20: {terms[21]:.2e} K; ratio of terms 20 to 19: {terms[20] / terms[19]:.4f} = lam/{lam * terms[19] / terms[20]:.4f}")
m5 = [modes(lam, 0.5, n) for n in (1, 3, 11, 101)]
print("mode sum at the middle, odd n up to 1, 3, 11, 101: " + ", ".join(f"{v:.4f}" for v in m5) + f"; next term {4 * q / (103 * PI * (103 * 103 * L1 - lam)):.1e} K")
ny = [nystrom(lam, n) for n in (20, 40)]
order, rich = math.log2((ny[0] - u5) / (ny[1] - u5)), (4 * ny[1] - ny[0]) / 3
print(f"grid at h = 0.05, 0.025 m: {ny[0]:.4f}, {ny[1]:.4f} K; observed order {order:.2f}; Richardson {rich:.4f} K")
pw = [power(n, 60) for n in (20, 40)]
print(f"lam_1 from the grid's top eigenvalue at h = 0.05, 0.025 m: {pw[0]:.4f}, {pw[1]:.4f} 1/m^2")
print("kernel in its own modes, K(x, y) = sum 2 sin(n pi x) sin(n pi y) / (n^2 pi^2):")
mer = []
for x, y in ((0.5, 0.5), (0.3, 0.7)):
    ps = [total(2 * math.sin(n * PI * x) * math.sin(n * PI * y) / (n * n * L1) for n in range(1, N + 1)) for N in (1, 9, 99)]
    mer.append(abs(ps[-1] - kern(x, y)))
    print(f"  K({x}, {y}) = {kern(x, y):.4f}; N = 1, 9, 99: " + ", ".join(f"{v:.5f}" for v in ps) + f"; tail < {2 / (L1 * 99):.5f}")
tr = simpson(lambda x: kern(x, x), 0, 1, 100)
h2 = total(kern((i + 0.5) / 400, (j + 0.5) / 400) ** 2 for i in range(400) for j in range(400)) / 160000
inv1, inv2 = total(1 / (n * n * L1) for n in range(1, 1001)), total(1 / (n * n * L1) ** 2 for n in range(1, 1001))
print(f"  trace: int K(x,x) dx = {tr:.6f}; sum 1/lam_n, n <= 1000: {inv1:.6f}, tail < {1 / (1000 * L1):.6f}")
print(f"  Hilbert-Schmidt: int int K^2 = {h2:.6f}; sum 1/lam_n^2, n <= 1000: {inv2:.6f}; 1/90 = {1 / 90:.6f}")
print("at the critical lam = pi^2, uniform q = 100 K/m^2:")
s1 = simpson(lambda x: q * math.sin(PI * x), 0, 1, 200)
s2 = simpson(lambda x: q * math.sin(2 * PI * x), 0, 1, 200)
print(f"  int q sin(pi x) dx = {s1:.3f} K/m (2q/pi = {2 * q / PI:.3f}); against sin(2 pi x): {abs(s2):.3f}")
tc = neumann(L1, [q], 40)
print("  partial sums r = 10, 20, 40: " + ", ".join(f"{partial(tc, n):.2f}" for n in (10, 20, 40)) + f" K; each term tends to 4q/pi^3 = {4 * q / PI ** 3:.3f} K")
qc = lambda y: q * math.cos(PI * y)
print(f"cosine source q = 100 cos(pi x): int q sin(pi x) dx = {abs(simpson(lambda x: qc(x) * math.sin(PI * x), 0, 1, 200)):.3f}")
res = []
for c in (0.0, 5.0):
    uc = lambda y, c=c: -(q / (2 * PI)) * y * math.sin(PI * y) + c * math.sin(PI * y)
    res.append(uc(0.3) - L1 * kint(uc, 0.3) - kint(qc, 0.3))
    print(f"  c = {c:.0f}: u(0.5) = {uc(0.5):.3f} K, residual of u - pi^2 K u - K q at x = 0.3: {abs(res[-1]):.1e}")
e12 = closed(12, 0.5)
t12 = neumann(12, [q], 20)
print(f"above critical, lam = 12: closed form {e12:.3f} K, mode sum {modes(12, 0.5, 101):.3f} K, Neumann r = 10, 20: {partial(t12, 10):.0f}, {partial(t12, 20):.0f}, ratio 12/pi^2 = {12 / L1:.3f}")
print("chart x = 0, 0.1, ..., 1 m, rise in K:")
for lv in (0, 5, 9):
    print(f"  lam = {lv}: " + ", ".join(f"{closed(lv, i / 10):.2f}" for i in range(11)))
need = [next((n for n in range(200) if abs(partial(neumann(lv, [q], 200), n) - closed(lv, 0.5)) < 0.01), 200) for lv in (5, 9)]
print(f"try: lam = 8 middle {closed(8, 0.5):.2f} K; within 0.01 K from round r = {need[0]} (lam = 5), {need[1]} (lam = 9); thickness at beta = 2.0: {PI * math.sqrt(KC / 2.0):.3f} m")
assert abs(partial(terms, 40) - u5) < 1e-9 and abs(m5[-1] - u5) < 1e-5     # three roads meet
assert abs(rich - u5) < 1e-3 and 1.9 < order < 2.1                          # grid, second order
assert all(abs(p - L1) < 0.03 for p in pw) and abs(lam * terms[19] / terms[20] - L1) < 1e-3
assert abs(tr - 1 / 6) < 1e-9 and abs(h2 - 1 / 90) < 1e-6                     # trace and K^2 by quadrature
assert max(mer) < 2 / (99 * L1) and 0 < tr - inv1 < 1 / (1000 * L1) and abs(inv2 - h2) < 1e-6  # Mercer's mode sums
assert abs(s1 - 2 * q / PI) < 1e-6 and partial(tc, 40) > 3 * partial(tc, 10)  # no steady state
assert abs(min(tc) - closed(0, 0.5)) < 1e-9 and max(tc) < 4 * q / PI ** 3 + 1e-9  # rounds lie in 12.500 to 12.901 K
assert max(abs(r) for r in res) < 1e-6 and abs(e12 - modes(12, 0.5, 2001)) < 1e-4 and abs(partial(t12, 20)) > 1e3
print("ALL CHECKS PASS")
