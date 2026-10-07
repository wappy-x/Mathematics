# Calibrating Hull-White to six swaptions. Standard library only: own normal CDF, root finder, integrator, solver.
from math import exp, expm1, log, sqrt, pi

CASES = [(e, n) for e in (0.5, 1.0, 2.0) for n in (2, 5)]    # (expiry, tenor) in years
KAPPA, SIGMA = 0.05, 0.009                                    # the pair behind the six quotes

def phi(z): return exp(-0.5 * z * z) / sqrt(2 * pi)
def N(z):                                        # series near 0, continued fraction in the tails
    if abs(z) < 3:
        term = total = z
        for k in range(1, 80):
            term *= -z * z * (2 * k - 1) / (2 * k * (2 * k + 1)); total += term
        return 0.5 + total / sqrt(2 * pi)
    t = abs(z)
    for k in range(60, 0, -1): t = abs(z) + k / t
    return 1 - phi(z) / t if z > 0 else phi(z) / t

def D(t): return exp(-0.03 * t - 0.002 * t * t)              # today's discount curve
def f(t): return 0.03 + 0.004 * t                             # its instantaneous forward rate
def b(k, u): return -expm1(-k * u) / k                        # load of a u-year bond on the rate
def clock(k, e): return -expm1(-2 * k * e) / (2 * k)          # variance of r at e is s^2 * clock
def bond(e, t, r, k, s):                                      # Hull-White zero at e, rate r there
    bb = b(k, t - e)
    return D(t) / D(e) * exp(-bb * (r - f(e)) - 0.5 * s * s * clock(k, e) * bb * bb)
def strike(e, n): return (D(e) - D(e + n)) / sum(D(e + j) for j in range(1, n + 1))
def legs(e, n):
    K = strike(e, n)
    return [K] * (n - 1) + [1 + K], [e + j for j in range(1, n + 1)]
def bisect(g, lo, hi, it=60):                                 # needs g(lo) > 0 > g(hi)
    for _ in range(it):
        mid = 0.5 * (lo + hi)
        if g(mid) > 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def jamshidian(e, n, k, s, flat=False):           # road 1: bond calls at one threshold
    c, ts = legs(e, n)
    rs = bisect(lambda r: sum(ci * bond(e, t, r, k, s) for ci, t in zip(c, ts)) - 1, -1.0, 1.0)
    rec = pay = 0.0
    for ci, t in zip(c, ts):
        kj = bond(e, t, rs, k, s)                            # payment j's strike: its bond at the threshold
        w = s * b(k, t - e) * sqrt(e if flat else clock(k, e))  # flat = spread s*sqrt(e), no damping
        d1 = log(D(t) / (D(e) * kj)) / w + w / 2
        rec += ci * (D(t) * N(d1) - kj * D(e) * N(d1 - w))
        pay += ci * (kj * D(e) * N(w - d1) - D(t) * N(-d1))
    return rec, pay, sum(ci * D(t) for ci, t in zip(c, ts)) - D(e)

def simpson(g, a, c, m=2000):                  # Simpson's rule on [a, c], m even
    h = (c - a) / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * g(a + i * h) for i in range(m + 1))
def by_integral(e, n, k, s):                 # road 2: average exercise value over r at e, Simpson
    c, ts = legs(e, n); sd = s * sqrt(clock(k, e))
    v = lambda z: sum(ci * bond(e, t, f(e) + sd * z, k, s) for ci, t in zip(c, ts)) - 1
    return D(e) * simpson(lambda z: v(z) * phi(z), -12.0, bisect(v, -12.0, 12.0))
def prices(k, s, **kw): return [jamshidian(e, n, k, s, **kw)[0] for e, n in CASES]
def rms(p, q, use=range(6)): return sqrt(sum((1e4 * (p[i] - q[i])) ** 2 for i in use) / len(use))

def fit(q, k=0.20, s=0.005, use=range(6), free=(0, 1), trail=None, **kw):  # road B: Levenberg-Marquardt
    x, lam = [log(k), log(s)], 1e-3                                         # in logs: both stay positive
    res = lambda x: [1e4 * (prices(exp(x[0]), exp(x[1]), **kw)[i] - q[i]) for i in use]
    r = res(x)
    for it in range(40):
        if trail is not None: trail.append((it, exp(x[0]), exp(x[1]), 0.5 * sum(a * a for a in r)))
        J = [[0.0] * len(r) for _ in range(2)]
        for a in free:
            xp, xm = x[:], x[:]; xp[a] += 1e-6; xm[a] -= 1e-6
            J[a] = [(u - v) / 2e-6 for u, v in zip(res(xp), res(xm))]
        A = [[sum(J[a][i] * J[c][i] for i in range(len(r))) for c in range(2)] for a in range(2)]
        g = [sum(J[a][i] * r[i] for i in range(len(r))) for a in range(2)]
        while True:
            M = [[A[a][c] * (1 + lam * (a == c)) + 1e-12 * (a == c) for c in range(2)] for a in range(2)]
            det = M[0][0] * M[1][1] - M[0][1] * M[1][0]
            dx = [-(M[1][1] * g[0] - M[0][1] * g[1]) / det, -(M[0][0] * g[1] - M[1][0] * g[0]) / det]
            xn = [x[0] + dx[0], x[1] + dx[1]]; rn = res(xn)
            if sum(a * a for a in rn) <= sum(a * a for a in r): x, r, lam = xn, rn, lam / 10; break
            lam *= 10
            if lam > 1e12: break
        if abs(dx[0]) + abs(dx[1]) < 1e-12 or lam > 1e12: break
    return exp(x[0]), exp(x[1]), rms(prices(exp(x[0]), exp(x[1]), **kw), q, use)
def implied_sigma(i, k, q):                  # the one sigma that reprices quote i at this kappa
    e, n = CASES[i]
    return bisect(lambda s: q[i] - jamshidian(e, n, k, s)[0], 1e-5, 0.1, 50)
name = lambda e, n: f"{e:.1f}y x {n}y"
q = [round(p, 9) for p in prices(KAPPA, SIGMA)]               # the quotes, to 9 decimals
print("six receiver swaptions, at-the-money, curve D(T) = exp(-0.03T - 0.002T^2)\nquote       strike %  premium bp  $ per 1m  road 2 bp  gap bp")
gap = 0.0
for (e, n), qi in zip(CASES, q):
    rec, pay, swap = jamshidian(e, n, KAPPA, SIGMA); integ = by_integral(e, n, KAPPA, SIGMA)
    assert abs(integ - rec) < 1e-9, "Simpson over the rate must land on Jamshidian"
    assert abs(rec - pay - swap) < 1e-12, "receiver - payer = the forward swap's value"
    assert abs(swap) < 1e-15, "the strike is the par rate: the forward swap is worth nothing"
    assert max(abs(clock(KAPPA, e) - simpson(lambda u: exp(-2 * KAPPA * u), 0, e)), abs(b(KAPPA, n) - simpson(lambda u: exp(-KAPPA * u), 0, n))) < 1e-12, "clock and load equal their integrals"
    gap = max(gap, abs(rec - pay - swap))
    print(f"{name(e, n):<11} {100 * strike(e, n):7.4f}  {1e4 * qi:9.3f}  {1e6 * qi:8.2f}  {1e4 * integ:9.3f}  {1e4 * abs(integ - rec):.5f}")
print(f"receiver - payer - swap value, largest gap bp {1e4 * gap:.6f}")
for e, n in ((0.5, 2), (2.0, 5)):                            # the last payment's width, with and without the pull
    print(f"by hand {name(e, n)} last payment: load {b(KAPPA, n):.4f}  clock {clock(KAPPA, e):.4f}  width {SIGMA * b(KAPPA, n) * sqrt(clock(KAPPA, e)):.6f}  no-pull {SIGMA * n * sqrt(e):.6f}")
grid = min((0.5 * sum((1e4 * (p - qi)) ** 2 for p, qi in zip(prices(0.01 + 0.005 * m, 0.004 + 0.0005 * l), q)),
            0.01 + 0.005 * m, 0.004 + 0.0005 * l) for m in range(21) for l in range(21))
print(f"road A grid of 441 pairs: kappa {grid[1]:.6f}  sigma % {100 * grid[2]:.4f}  half-life ln2/kappa yrs {log(2) / grid[1]:.2f}")
assert abs(grid[1] - KAPPA) < 1e-12 and abs(grid[2] - SIGMA) < 1e-12, "grid must find the generating pair"
trail = []; kB, sB, _ = fit(q, trail=trail); print("road B Levenberg-Marquardt from kappa 0.20, sigma 0.5%")
for it, k, s, L in trail[:7]: print(f"  step {it}  kappa {k:.6f}  sigma % {100 * s:.6f}  loss bp^2 {L:.4f}")
print(f"  lands   kappa {kB:.6f}  sigma % {100 * sB:.6f}  after {len(trail)} steps")
assert abs(kB - KAPPA) < 1e-6 and abs(sB - SIGMA) < 1e-8, "LM from far away must find the pair"
kC = bisect(lambda k: implied_sigma(0, k, q) - implied_sigma(5, k, q), 0.01, 0.10, 50)
print(f"road C kappa where 0.5y x 2y and 2.0y x 5y imply one sigma: {kC:.6f}")
assert abs(kC - KAPPA) < 1e-5, "flat implied sigma must find kappa"
J = []; print("sensitivity, bp per +1%   kappa    sigma   kappa/sigma  rule -kappa(n+E)/2")
for (e, n), i in zip(CASES, range(6)):
    dk = 1e4 * 0.01 * (jamshidian(e, n, KAPPA * 1.0001, SIGMA)[0] - jamshidian(e, n, KAPPA * 0.9999, SIGMA)[0]) / 2e-4
    ds = 1e4 * 0.01 * (jamshidian(e, n, KAPPA, SIGMA * 1.0001)[0] - jamshidian(e, n, KAPPA, SIGMA * 0.9999)[0]) / 2e-4
    J.append((dk, ds))
    print(f"  {name(e, n):<11}           {dk:8.4f} {ds:8.4f}  {dk / ds:9.4f}  {-KAPPA * (n + e) / 2:9.4f}")
def ratio(use):                               # stiff / soft eigenvalue of J'J over the chosen quotes
    aa, bb, ab = (sum(J[r][i] * J[r][j] for r in use) for i, j in ((0, 0), (1, 1), (0, 1)))
    big = (aa + bb + sqrt((aa - bb) ** 2 + 4 * ab * ab)) / 2
    return big / ((aa * bb - ab * ab) / big)
for label, use in (("all six", range(6)), ("the three 2y tenors", (0, 2, 4)), ("the two 0.5y expiries", (0, 1))):
    print(f"eigenvalue ratio, stiff / soft, {label:<22} {ratio(use):10.1f}")
print("implied sigma bp     kappa 0.01  kappa 0.05  kappa 0.10")
for i, (e, n) in enumerate(CASES):
    iv = [implied_sigma(i, k, q) for k in (0.01, 0.05, 0.10)]
    assert abs(iv[1] - SIGMA) < 1e-8, "at the true kappa every quote implies the true sigma"
    print(f"  {name(e, n):<11}         " + "  ".join(f"{1e4 * v:10.2f}" for v in iv))
prof = [fit(q, k, 0.005, free=(1,)) for k in (0.01, 0.03, 0.05, 0.07, 0.09, 0.11)]
print("profile kappa        " + " ".join(f"{k:6.2f}" for k, _, _ in prof))
print("profile best sigma % " + " ".join(f"{100 * s:6.3f}" for _, s, _ in prof))
print("profile rms miss bp  " + " ".join(f"{m:6.2f}" for _, _, m in prof))
for label, qn in (("all six scaled up 1%", [1.01 * a for a in q]), ("tilt +0.5bp 2y, -0.5bp 5y", [a + d for a, d in zip(q, [5e-5, -5e-5] * 3)])):
    k, s, _ = fit(qn, KAPPA, SIGMA)
    print(f"noise: {label:<26} kappa {k:.4f}  sigma % {100 * s:.4f}")
k, s, m = fit(q, KAPPA, SIGMA, flat=True)
print(f"wrong: spread s*sqrt(E)  kappa {k:.4f}  sigma % {100 * s:.4f}  rms bp {m:.2f}")
print(f"try: sigma 1.2%, 2.0y x 5y premium bp {1e4 * jamshidian(2.0, 5, KAPPA, 0.012)[0]:.2f}  (was {1e4 * q[5]:.2f})")
print(f"try: kappa 0.15, 2.0y x 5y premium bp {1e4 * jamshidian(2.0, 5, 0.15, SIGMA)[0]:.2f}")
k2, s2, _ = fit(q, use=(0, 5))
print(f"try: fit to 0.5y x 2y and 2.0y x 5y only: kappa {k2:.6f}  sigma % {100 * s2:.6f}")
print("ALL CHECKS PASS")
