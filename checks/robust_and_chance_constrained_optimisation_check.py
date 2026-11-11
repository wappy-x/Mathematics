# Robust and chance constraints -- the check behind the card.  Standard library only.
# Five assets, returns in % a year.  Maximise the worst-case expected return over a ball
# of radius DELTA = 1 point around the estimates, with a 95% chance of losing at most ELL = 10%.
# Roads: log-barrier Newton with a gap certificate, a 2% grid, water-filling, the ball sampled, simulated years.
import math, functools
NAMES = ["UK", "World", "Prop", "Gilts", "Gold"]
MU = [7.0, 7.4, 6.8, 4.0, 5.0]                     # estimated expected return, %
SD = [16.0, 15.0, 18.0, 8.0, 14.0]                 # yearly standard deviation, %
RHO = {(0, 1): 0.9, (0, 2): 0.7, (1, 2): 0.5, (1, 4): 0.2, (2, 3): 0.3, (2, 4): 0.2, (3, 4): 0.3}
N, DELTA, ELL, EPS = 5, 1.0, 10.0, 0.05
SIG = [[SD[i] * SD[j] * (1.0 if i == j else RHO.get((min(i, j), max(i, j)), 0.0)) for j in range(N)] for i in range(N)]
def add(xs): return functools.reduce(lambda a, b: a + b, xs, 0.0)   # left-to-right sum, as Rust
def dot(a, b): return add(x * y for x, y in zip(a, b))
def pc(w): return " ".join(f"{100 * v:6.2f}" for v in w)
def ncdf(x, n=2000):                               # bell-curve area left of x, Simpson's rule
    h = x / n; s = 1.0 + math.exp(-0.5 * x * x)
    for k in range(1, n): s += (4 if k % 2 else 2) * math.exp(-0.5 * (k * h) * (k * h))
    return 0.5 + s * h / 3 / math.sqrt(2 * math.pi)
lo, hi = 0.0, 4.0
for _ in range(60):
    mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if ncdf(mid) < 1 - EPS else (lo, mid)
Z = lo                                             # z: N(z) = 0.95
def stats(w, delta):                               # |w|, Sigma w, sd, worst mean, VaR slack
    nw = math.sqrt(dot(w, w)); Sw = [dot(r, w) for r in SIG]; sd = math.sqrt(dot(w, Sw)); m = dot(MU, w)
    return nw, Sw, sd, m - delta * nw, m + ELL - Z * sd
def solve(M, b):                                   # Gaussian elimination, partial pivoting
    n = len(b); R = [M[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(R[r][c])); R[c], R[p] = R[p], R[c]
        for r in range(n):
            if r != c:
                f = R[r][c] / R[c][c]; R[r] = [a - f * q for a, q in zip(R[r], R[c])]
    return [R[i][n] / R[i][i] for i in range(n)]
def phi(x, t, delta):                              # barrier cost on the first four weights
    w = x + [1.0 - add(x)]; nw, Sw, sd, f, s = stats(w, delta)
    if min(w) <= 0 or s <= 0: return math.inf
    return -t * f - add(math.log(v) for v in w) - math.log(s)
def barrier(delta):                                # road 1: start at a feasible split, t = 1
    x, t, newton = [0.1, 0.1, 0.1, 0.5], 1.0, 0
    while 6.0 / t >= 1e-6:
        t *= 10.0
        while True:
            w = x + [1.0 - add(x)]; nw, Sw, sd, f, s = stats(w, delta)
            gf = [MU[i] - delta * w[i] / nw for i in range(N)]
            gs = [MU[i] - Z * Sw[i] / sd for i in range(N)]
            g = [-t * gf[i] - 1 / w[i] - gs[i] / s for i in range(N)]
            H = [[t * delta * ((i == j) - w[i] * w[j] / (nw * nw)) / nw + (i == j) / (w[i] * w[i])
                  + gs[i] * gs[j] / (s * s) + Z * (SIG[i][j] - Sw[i] * Sw[j] / (sd * sd)) / (sd * s)
                  for j in range(N)] for i in range(N)]
            gx = [g[i] - g[4] for i in range(4)]
            Hx = [[H[i][j] - H[i][4] - H[4][j] + H[4][4] for j in range(4)] for i in range(4)]
            d = solve(Hx, [-v for v in gx]); dec = -dot(gx, d)
            a, p0 = 1.0, phi(x, t, delta)
            while a > 1e-9 and phi([x[i] + a * d[i] for i in range(4)], t, delta) > p0 - 0.25 * a * dec: a *= 0.5
            if dec < 1e-10 or a <= 1e-9: break     # centred, or rounding stops progress
            x = [x[i] + a * d[i] for i in range(4)]; newton += 1
    w = x + [1.0 - add(x)]; nw, Sw, sd, f, s = stats(w, delta)
    lam, lb = 1.0 / (t * s), [1.0 / (t * v) for v in w]   # prices on the VaR limit and on w_i >= 0
    gr = [MU[i] - delta * w[i] / nw + lam * (MU[i] - Z * Sw[i] / sd) + lb[i] for i in range(N)]
    nu = add(gr) / N                               # KKT: every entry of gr equals nu
    assert max(abs(v - nu) for v in gr) < 1e-6 and min(lb) > 0 and lam > 0
    return w, lam, nu, 6.0 / t, newton
print(f"z for chance {EPS:.2f}: {Z:.6f}, N(z) = {ncdf(Z):.6f}")
print("assets      " + " ".join(f"{n:>6}" for n in NAMES))
print("estimates % " + " ".join(f"{m:6.2f}" for m in MU))
# ---- no VaR limit: water-filling, certified by its worst-case estimates ----
order = sorted(range(N), key=lambda i: -MU[i])
for k in range(1, N + 1):
    top = [MU[i] for i in order[:k]]; m = add(top) / k; ss = add((v - m) * (v - m) for v in top)
    if ss > DELTA * DELTA: continue
    nu = m - math.sqrt((DELTA * DELTA - ss) / k)
    if k == N or MU[order[k]] <= nu: break
wf = [max(MU[i] - nu, 0.0) for i in range(N)]; wf = [v / add(wf) for v in wf]
nf = stats(wf, DELTA)
mf = [MU[i] - DELTA * wf[i] / nf[0] for i in range(N)]
print(f"no VaR limit: {pc(wf)}  worst {nf[3]:.4f}, VaR95 {ELL - nf[4]:.4f}")
print("  its worst estimates " + " ".join(f"{v:.4f}" for v in mf))
assert abs(nf[3] - nu) < 1e-12 and max(mf) <= nu + 1e-12
# ---- the card's problem: nominal (radius 0) and robust (radius 1) ----
print("plan        " + " ".join(f"{n:>6}" for n in NAMES) + "  est.   |w|    worst  sd     VaR95")
plans = {}
for name, dl in (("nominal", 0.0), ("robust", DELTA)):
    w, lam, nuk, gap, newton = barrier(dl); plans[name] = w
    nw, Sw, sd, worst, s = stats(w, DELTA)
    print(f"{name:11} {pc(w)}  {dot(MU, w):.4f} {nw:.4f} {worst:.4f} {sd:.4f} {ELL - s:.4f}")
    print(f"  certificate: {newton} Newton steps, gap at most {gap:.7f}, VaR price {lam:.4f}")
    assert abs(s) < 1e-5                           # the VaR limit binds
wn, wr = plans["nominal"], plans["robust"]
(nr, _, sdr, best, _), nn = stats(wr, DELTA), stats(wn, DELTA)
# ---- road 2: every split on a 2% grid that meets the VaR limit ----
gbest, gw = -math.inf, None
for a in range(51):
    for b in range(51 - a):
        for c in range(51 - a - b):
            for d in range(51 - a - b - c):
                w = [a / 50, b / 50, c / 50, d / 50, (50 - a - b - c - d) / 50]
                st = stats(w, DELTA)
                if st[4] >= 0 and st[3] > gbest: gbest, gw = st[3], w
print(f"2% grid best: {pc(gw)}  worst {gbest:.4f}, below the barrier by {best - gbest:.4f}")
assert gbest <= best + 1e-9 and best - gbest < 0.02
# ---- road 3: the worst case by Cauchy-Schwarz, against 20,000 points on the ball ----
mstar = [MU[i] - DELTA * wr[i] / nr for i in range(N)]
print("robust plan's worst estimates " + " ".join(f"{v:.4f}" for v in mstar) + f", earns {dot(mstar, wr):.4f}")
S64 = [0x2026111100000001]                         # seed
def rnd():                                         # SplitMix64, a uniform in [0, 1)
    S64[0] = (S64[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF; z = S64[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def gauss(): return math.sqrt(-2.0 * math.log(1.0 - rnd())) * math.cos(2.0 * math.pi * rnd())
smin = math.inf
for _ in range(20000):
    u = [gauss() for _ in range(N)]; r = math.sqrt(dot(u, u))
    smin = min(smin, dot([MU[i] + DELTA * u[i] / r for i in range(N)], wr))
print(f"20,000 points on the ball: lowest {smin:.4f}, never below {best:.4f}")
assert best - 1e-12 <= smin < best + 0.05
mn = [MU[i] - DELTA * wn[i] / nn[0] for i in range(N)]
print(f"in the nominal plan's worst world: nominal earns {dot(mn, wn):.4f}, robust {dot(mn, wr):.4f}")
# ---- road 4: the chance constraint, 200,000 simulated years (C with C C^T = Sigma) ----
C = [[0.0] * N for _ in range(N)]
for i in range(N):
    for j in range(i + 1):
        v = SIG[i][j] - add(C[i][k] * C[j][k] for k in range(j))
        C[i][j] = math.sqrt(v) if i == j else v / C[j][j]
cw = [add(C[i][j] * wr[i] for i in range(N)) for j in range(N)]   # C^T w
YEARS, bad, se = 200000, 0, math.sqrt(EPS * (1 - EPS) / 200000)
for _ in range(YEARS):
    if dot(MU, wr) + dot(cw, [gauss() for _ in range(N)]) < -ELL: bad += 1
print(f"simulated years losing over {ELL:.0f}%: {bad} of {YEARS} = {bad / YEARS:.4f} (target {EPS:.4f}, se {se:.4f})")
assert abs(bad / YEARS - EPS) < 4 * se and abs(math.sqrt(dot(cw, cw)) - sdr) < 1e-9
# ---- what breaks ----
m = dot(MU, wr); kk = (m + 10.5) / sdr; p2 = 1 / (1 + kk * kk)
print(f"two-point year, same mean and sd: lose 10.50% with chance {p2:.4f}, else gain {m + sdr / kk:.4f}")
assert abs(p2 * -10.5 + (1 - p2) * (m + sdr / kk) - m) < 1e-9 and p2 > 5 * EPS
print(f"any-law z (Cantelli): {math.sqrt((1 - EPS) / EPS):.4f}")
print(f"nominal promises {dot(MU, wn):.4f}, can earn {nn[3]:.4f}; box promise {dot(MU, wn) - DELTA:.4f}; robust worst case on £1,000,000: £{1e4 * best:.0f} a year")
print(f"by hand, robust: w {' '.join(f'{v:.5f}' for v in wr)}, |w|^2 {nr * nr:.5f}, |w| {nr:.5f}, est {dot(MU, wr):.5f}, worst {best:.5f}, sd {sdr:.5f}, z*sd {Z * sdr:.5f}, VaR95 at worst estimates {ELL + DELTA * nr:.5f}")
r2 = DELTA / math.sqrt(2)                          # figure: half in each of two assets, 1 point = 60
print(f"figure, centre 180 120, radius 60, box corner 120 180, worst point {180 - 60 * r2:.1f} {120 + 60 * r2:.1f}, ball worst {7.2 - r2:.4f}, box worst {7.2 - DELTA:.4f}")
print("ALL CHECKS PASS")
