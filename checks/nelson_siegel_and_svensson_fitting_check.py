# Nelson-Siegel and Svensson fitted to twelve bond prices -- the check behind the card.
# Standard library only.  Gaussian elimination, Gauss-Newton, Nelder-Mead, Simpson's rule
# and the bisection yield solver are all written out below.
from math import exp

BONDS = [(1, 2.00), (2, 2.50), (3, 3.00), (4, 3.25), (5, 3.50), (7, 3.75),
         (10, 4.00), (12, 4.00), (15, 4.25), (20, 4.25), (25, 4.50), (30, 4.50)]  # (years, coupon per 100)
TRUE = (0.035, -0.025, 0.040, 0.025, 2.0, 7.0)          # the six-parameter curve the prices were built from

def L(x): return (1 - exp(-x)) / x                      # slope loading of the zero rate
def H(x): return L(x) - exp(-x)                         # hump loading of the zero rate
def zero(t, p):                                         # p = (b0, b1, b2, tau1) or (b0, b1, b2, b3, tau1, tau2)
    z = p[0] + p[1] * L(t / p[-2 if len(p) == 6 else -1]) + p[2] * H(t / p[-2 if len(p) == 6 else -1])
    return z + (p[3] * H(t / p[5]) if len(p) == 6 else 0.0)
def fwd(t, p):
    a = t / (p[4] if len(p) == 6 else p[3])
    f = p[0] + p[1] * exp(-a) + p[2] * a * exp(-a)
    return f + (p[3] * (t / p[5]) * exp(-t / p[5]) if len(p) == 6 else 0.0)
def flows(n, c): return [(k, c + (100.0 if k == n else 0.0)) for k in range(1, n + 1)]
def price(n, c, p, rate=zero): return sum(cf * exp(-t * rate(t, p)) for t, cf in flows(n, c))
MKT = [round(price(n, c, TRUE), 2) for n, c in BONDS]  # quoted to the cent
def sse(p, mkt=MKT): return sum((price(n, c, p) - m) ** 2 for (n, c), m in zip(BONDS, mkt))

def solve(A, b):                                        # Gaussian elimination with pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for k in range(n):
        piv = max(range(k, n), key=lambda i: abs(M[i][k])); M[k], M[piv] = M[piv], M[k]
        for i in range(k + 1, n):
            f = M[i][k] / M[k][k]
            for j in range(k, n + 1): M[i][j] -= f * M[k][j]
    x = [0.0] * n
    for i in reversed(range(n)): x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x

def gn(p, free, mkt=MKT):                               # road 1: Gauss-Newton on the free parameters
    p = list(p)
    for _ in range(40):
        J = []
        for j in free:                                  # slopes of the twelve prices, by central differences
            up, dn = p[:], p[:]; up[j] += 1e-6; dn[j] -= 1e-6
            J.append([(price(n, c, up) - price(n, c, dn)) / 2e-6 for n, c in BONDS])
        r = [price(n, c, p) - m for (n, c), m in zip(BONDS, mkt)]
        step = solve([[sum(x * y for x, y in zip(u, v)) for v in J] for u in J], [-sum(x * y for x, y in zip(u, r)) for u in J])
        old, h = sse(p, mkt), 1.0
        def moved(h): q = p[:]; [q.__setitem__(j, q[j] + h * s) for j, s in zip(free, step)]; return q
        while sse(moved(h), mkt) > old and h > 1e-6: h /= 2
        p = moved(h)
        if max(abs(s) for s in step) < 1e-12: break
    return tuple(p)

def road1_ns(mkt=MKT):                                  # grid on tau with the betas solved, then all four
    start = min(([0.04, 0, 0, 0.25 * i] for i in range(1, 41)), key=lambda q: sse(gn(q, [0, 1, 2], mkt), mkt))
    return gn(gn(start, [0, 1, 2], mkt), [0, 1, 2, 3], mkt)

def road1_sv():                                         # grid on both taus, then all six
    start = min(([0.04, 0, 0, 0, 0.5 * i, 0.5 * j] for i in range(1, 11) for j in range(4, 31) if j > i + 1),
                key=lambda q: sse(gn(q, [0, 1, 2, 3])))
    return gn(gn(start, [0, 1, 2, 3]), range(6))

def nelder_mead(f, x0, steps, rounds=12, iters=800):  # road 2: all parameters at once, no derivatives
    best, n = list(x0), len(x0)
    for _ in range(rounds):
        S = [best[:]] + [[best[j] + (steps[j] if j == i else 0.0) for j in range(n)] for i in range(n)]
        S = sorted((f(v), v) for v in S)
        for _ in range(iters):
            c = [sum(v[j] for _, v in S[:-1]) / n for j in range(n)]
            pt = lambda s: [c[j] + s * (S[-1][1][j] - c[j]) for j in range(n)]
            r = pt(-1.0); fr = f(r)
            if fr < S[0][0]:
                e = pt(-2.0); fe = f(e); S[-1] = (fe, e) if fe < fr else (fr, r)
            elif fr < S[-2][0]: S[-1] = (fr, r)
            else:
                k = pt(0.5); fk = f(k)
                if fk < S[-1][0]: S[-1] = (fk, k)
                else: S = [S[0]] + [(f(w), w) for w in ([S[0][1][j] + 0.5 * (v[j] - S[0][1][j]) for j in range(n)] for _, v in S[1:])]
            S.sort(key=lambda z: z[0])
        best = S[0][1]; steps = [s * 0.3 for s in steps]
    return tuple(best)

def safe(p): return sse(p) if min(p[-2:] if len(p) == 6 else p[-1:]) > 0.05 else 1e9
def simpson(g, a, b, n=2000):
    h = (b - a) / n
    return (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))) * h / 3
def ytm(n, c, m):                                        # bisection: one flat rate that reprices the bond
    lo, hi = -0.05, 0.20
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if sum(cf * exp(-t * mid) for t, cf in flows(n, c)) > m else (lo, mid)
    return (lo + hi) / 2

ns1, sv1 = road1_ns(), road1_sv()
ns2 = nelder_mead(safe, (0.04, -0.02, 0.0, 1.0), (0.01, 0.01, 0.01, 0.5))
sv2 = nelder_mead(safe, (0.04, -0.02, 0.0, 0.0, 1.0, 5.0), (0.01, 0.01, 0.01, 0.01, 0.5, 2.0))
fmt = lambda p: " ".join(f"{100 * x:.4f}" for x in p[:-2 if len(p) == 6 else -1]) + " | " + " ".join(f"{x:.4f}" for x in p[-2 if len(p) == 6 else -1:])
print("fit             betas (% a year)                    | taus (years)")
for lab, p in (("NS road 1", ns1), ("NS road 2", ns2), ("SV road 1", sv1), ("SV road 2", sv2), ("SV truth", TRUE)):
    print(f"{lab:<15} {fmt(p)}")
rms = lambda p: (sse(p) / 12) ** 0.5
print(f"score: NS {sse(ns1):.6f}  SV {sse(sv1):.6f}  (dollars squared); rms miss NS {100 * rms(ns1):.3f}c SV {100 * rms(sv1):.3f}c")
print("bond  coupon  market  NS miss, cents  SV miss, cents  yield %  NS zero %  SV zero %")
for (n, c), m in zip(BONDS, MKT):
    print(f"{n:>4} {c:7.2f} {m:8.2f} {100 * (price(n, c, ns1) - m):+15.2f} {100 * (price(n, c, sv1) - m):+15.2f}"
          f" {100 * ytm(n, c, m):8.2f} {100 * zero(n, ns1):10.2f} {100 * zero(n, sv1):10.2f}")
b0, b1, b2, t1 = ns1
print(f"read NS: long level b0 {100 * b0:.4f}%, zero at 10000y {100 * zero(10000, ns1):.4f}%; short end b0+b1 {100 * (b0 + b1):.4f}%, "
      f"zero at 0.001y {100 * zero(0.001, ns1):.4f}%")
xp = max((i * 1e-5 for i in range(1, 500001)), key=H)
print(f"read NS: slope long minus short = -b1 = {-100 * b1:.4f}%; zero-rate hump peaks at x = {xp:.4f}, t = {xp * t1:.4f}y")
print(f"read SV: long level b0 {100 * sv1[0]:.4f}%, short end b0+b1 {100 * (sv1[0] + sv1[1]):.4f}%; truth {100 * TRUE[0]:.4f}% and {100 * (TRUE[0] + TRUE[1]):.4f}%")
print("loadings at NS tau, years: " + " ".join(f"{n}" for n, _ in BONDS))
print("  slope L " + " ".join(f"{L(n / t1):.2f}" for n, _ in BONDS))
print("  hump  H " + " ".join(f"{H(n / t1):.2f}" for n, _ in BONDS))
ci = simpson(lambda s: fwd(s, sv1), 0.0, 10.0) / 10.0
print(f"SV 10y zero: closed form {100 * zero(10, sv1):.8f}%  integral of forward / 10 {100 * ci:.8f}%")
n3, c3 = BONDS[2]
print("3y bond by hand: " + "  ".join(f"t={t} L={L(t / t1):.4f} H={H(t / t1):.4f} R={100 * zero(t, ns1):.4f}% D={exp(-t * zero(t, ns1)):.6f}" for t, _ in flows(n3, c3))
      + f"  price {price(n3, c3, ns1):.4f}")
yl = [ytm(n, c, m) for (n, c), m in zip(BONDS, MKT)]
cols = [[1.0] * 12, [L(n / t1) for n, _ in BONDS], [H(n / t1) for n, _ in BONDS]]
lin = solve([[sum(a * b for a, b in zip(u, v)) for v in cols] for u in cols], [sum(a * y for a, y in zip(u, yl)) for u in cols])
print("wrong: yields fitted as zero rates (same tau): betas " + " ".join(f"{100 * x:.4f}" for x in lin)
      + f"; worst price miss {max(abs(price(n, c, tuple(lin) + (t1,)) - m) for (n, c), m in zip(BONDS, MKT)):.4f}")
print(f"wrong: forward used as zero rate, 30y bond: {price(30, 4.5, ns1, fwd):.4f} vs NS {price(30, 4.5, ns1):.4f}")
dl = gn([0.04, 0, 0, 1 / (12 * 0.0609)], [0, 1, 2])
print(f"wrong: tau fixed at 1.3684y: betas {100 * dl[0]:.4f} {100 * dl[1]:.4f} {100 * dl[2]:.4f} score {sse(dl):.6f}")
m2 = [round(price(n, c, TRUE[:3] + (2.0,)), 2) for n, c in BONDS]; t2 = road1_ns(m2)
print(f"try: prices from a four-parameter curve: NS fit {fmt(t2)}; score {sse(t2, m2):.6f}")
m3 = [price(n, c, TRUE) for n, c in BONDS]
print(f"try: prices not rounded: SV fit {fmt(gn(sv1, range(6), m3))}")
m4 = [m + (0.10 if n == 10 else 0.0) for (n, c), m in zip(BONDS, MKT)]
print(f"try: 10y bond 10 cents dearer: NS fit {fmt(gn(ns1, range(4), m4))}")
assert all(abs(a - b) < 1e-6 for a, b in zip(ns1, ns2)), "NS: road 1 and road 2 must land on the same fit"
assert all(abs(a - b) < 1e-5 for a, b in zip(sv1, sv2)), "SV: road 1 and road 2 must land on the same fit"
assert sse(sv1) <= sse(ns1), "Svensson contains Nelson-Siegel, so it cannot fit worse"
assert abs(zero(10, sv1) - ci) < 1e-10, "zero rate must equal the average of the forward"
assert all(abs(a - b) < 2e-4 for a, b in zip(sv1[:4], TRUE[:4])), "SV betas must recover the curve the prices came from"
print("ALL CHECKS PASS")
