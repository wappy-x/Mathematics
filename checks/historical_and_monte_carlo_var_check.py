# Historical and Monte Carlo VaR -- the check behind the card.  Standard library only.
# Own random numbers (splitmix64), own normal CDF (a series), own inverse (bisection).
from math import log, sqrt, exp, cos, pi

M64 = (1 << 64) - 1
class Rng:                                      # splitmix64: the same stream in Python and Rust
    def __init__(self, seed): self.s = seed
    def u64(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unif(self): return ((self.u64() >> 11) + 0.5) / 9007199254740992.0
    def below(self, n): return self.u64() % n
    def normal(self): return sqrt(-2.0 * log(self.unif())) * cos(2.0 * pi * self.unif())
    def pair(self, rho, nu):                    # two correlated moves; nu > 0 fattens the tails
        z1 = self.normal(); z2 = rho * z1 + sqrt(1.0 - rho * rho) * self.normal()
        f = sqrt((nu - 2) / sum(self.normal() ** 2 for _ in range(nu))) if nu else 1.0
        return z1 * f, z2 * f

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def Phi(x):                                     # bell-curve area left of x, by its power series
    if abs(x) > 8.0: return 0.0 if x < 0 else 1.0
    term, total, n = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        n += 2; term *= x * x / n; total += term
    return 0.5 + phi(x) * total
def Phi_inv(p):
    lo, hi = -10.0, 10.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if Phi(mid) < p else (lo, mid)
    return 0.5 * (lo + hi)

S0, K, r, q, vol, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
def call(S):
    d1 = (log(S / K) + (r - q + 0.5 * vol * vol) * T) / (vol * sqrt(T))
    return S * exp(-q * T) * Phi(d1) - K * exp(-r * T) * Phi(d1 - vol * sqrt(T))
C0 = call(S0)
SHARES, OPT_SHARES, BOND, DUR = 100000, 100000, 5e6, 7.0   # 1,000 calls x 100 shares each
def parts(x, y):                                # full revaluation of today's book under one day's moves
    S = S0 * exp(x)
    return SHARES * (S - S0), OPT_SHARES * (call(S) - C0), -BOND * DUR * y
def loss(x, y): return -sum(parts(x, y))
def var(losses):                                # 99%: the ceil(0.99 N)-th smallest loss
    return sorted(losses)[(99 * len(losses) + 99) // 100 - 1]
def sd_of(v): m = sum(v) / len(v); return sqrt(sum((x - m) ** 2 for x in v) / (len(v) - 1))

# ---- the record: 500 constructed days of (Acme log-move, change in bond yield) ----
rec = Rng(558)
days = [(0.0118 * a, 0.0006 * b) for a, b in (rec.pair(0.3, 6) for _ in range(500))]
L = [loss(x, y) for x, y in days]
Ls = sorted(L)
h_var = var(L)
count_road = min(v for v in L if sum(w <= v for w in L) >= 495)    # road 2: count, never sort
day = L.index(h_var)
# distribution-free 95% band: the count of losses at or below the true VaR is Binomial(500, 0.99)
pm = [0.0] * 501; pm[500] = 0.99 ** 500
for k in range(500, 0, -1): pm[k - 1] = pm[k] * k / (501 - k) * 0.01 / 0.99
cover = sum(pm[489:499])
cover_direct = sum(exp(sum(log((501 - j) / j) for j in range(1, k + 1)) + k * log(0.99) + (500 - k) * log(0.01)) for k in range(489, 499))

# ---- parametric: delta-normal from the record's second moments, means taken as zero ----
sxx = sum(x * x for x, _ in days) / 500; syy = sum(y * y for _, y in days) / 500
sxy = sum(x * y for x, y in days) / 500
d1 = (r - q + 0.5 * vol * vol) / vol
ex = S0 * (SHARES + OPT_SHARES * exp(-q * T) * Phi(d1)); ey = -BOND * DUR
bump = (sum(parts(1e-6, 0.0)) - sum(parts(-1e-6, 0.0))) / 2e-6
bump_y = (sum(parts(0.0, 1e-6)) - sum(parts(0.0, -1e-6))) / 2e-6
z = Phi_inv(0.99)
sd = sqrt(ex * ex * sxx + 2 * ex * ey * sxy + ey * ey * syy)
sd_series = sqrt(sum((ex * x + ey * y) ** 2 for x, y in days) / 500)
p_var = z * sd
simpson = 0.5 + sum((1 if i in (0, 400) else 4 if i % 2 else 2) * phi(i / 400) for i in range(401)) / 1200

# ---- Monte Carlo: 10,000 scenarios from a stated law ----
kurt = sum(l ** 4 for l in L) / 500 / (sum(l * l for l in L) / 500) ** 2 - 3
nu = round(4 + 6 / kurt)                        # tail weight matched to the record's kurtosis
sa, sb = sqrt(sxx), sqrt(syy); rho = sxy / (sa * sb)
def draws(seed, n, nu): g = Rng(seed); return [g.pair(rho, nu) for _ in range(n)]
def mc(seed, n, nu): return [loss(sa * a, sb * b) for a, b in draws(seed, n, nu)]
M = mc(1, 10000, nu); m_var = var(M)
f_hat = sum(abs(v - m_var) < 20000 for v in M) / (40000 * 10000)   # loss density near the answer
se_formula = sqrt(0.99 * 0.01 / 10000) / f_hat
reruns = [var(mc(100 + k, 10000, nu)) for k in range(20)]
normal_full = var(mc(8, 10000, 0))
normal_delta = var([-(ex * sa * a + ey * sb * b) for a, b in draws(8, 10000, 0)])
se_normal = sqrt(0.99 * 0.01 / 10000) * sd / phi(z)
g = Rng(9); boot = var([L[g.below(500)] for _ in range(10000)])  # resample whole days
g = Rng(11); truth = var([loss(0.0118 * a, 0.0006 * b) for a, b in (g.pair(0.3, 6) for _ in range(200000))])

# ---- what breaks ----
delta_hist = var([-(ex * x + ey * y) for x, y in days])
eq = [sum(parts(x, 0.0)[:2]) for x, _ in days]; bp = [-BOND * DUR * y for _, y in days]
split = var([-(a + b) for a in eq for b in bp])   # every Acme day paired with every yield day
small = [var(mc(200 + k, 1000, nu)) for k in range(20)]

rows = [("house call price", C0), ("N(1) by series", Phi(1.0)), ("N(1) by Simpson", simpson),
    ("z = N^-1(0.99)", z), ("record: Acme vol, annual", sqrt(sxx * 252)),
    ("record: yield vol, bp per day", sqrt(syy) * 1e4), ("record: correlation", rho),
    ("1 historical VaR, rank 495 of 500", h_var), ("  same, by counting", count_road),
    ("  that day's number", day + 1), ("  its Acme move, percent", 100 * (exp(days[day][0]) - 1)),
    ("  its yield change, bp", 1e4 * days[day][1]), ("  shares P&L", parts(*days[day])[0]),
    ("  calls P&L", parts(*days[day])[1]), ("  bond P&L", parts(*days[day])[2]),
    ("  95% band low, rank 489", Ls[488]), ("  95% band high, rank 499", Ls[498]),
    ("  band coverage", cover),
    ("2 delta, analytic", ex), ("  delta, by bump", bump), ("  call delta e^-qT N(d1)", exp(-q * T) * Phi(d1)),
    ("  delta to the yield", ey), ("  P&L sd, covariance", sd),
    ("  P&L sd, series", sd_series), ("  parametric VaR", p_var),
    ("record: excess kurtosis", kurt), ("MC tail weight nu", nu),
    ("3 Monte Carlo VaR, 10,000", m_var), ("  SE by formula", se_formula),
    ("  20 reruns: mean", sum(reruns) / 20), ("  20 reruns: SE", sd_of(reruns)),
    ("  20 reruns: lowest", min(reruns)), ("  20 reruns: highest", max(reruns)),
    ("  normal law, full revaluation", normal_full), ("  normal law, delta P&L", normal_delta),
    ("  normal law SE", se_normal), ("  resample whole days", boot),
    ("  truth: the record's own law", truth),
    ("wrong: 5th-worst day", Ls[495]), ("wrong: delta, not full revaluation", delta_hist),
    ("wrong: moves paired apart", split), ("wrong: 1,000 scenarios, SE", sd_of(small))]
for name, v in rows: print(f"{name:<36} {v:>18.{2 if abs(v) >= 1000 else 6}f}")
print("tail, losses from $k   200    300    400    500    600")
edges = [200000.0 + 100000.0 * i for i in range(6)]
print("tail, days in record " + "".join(f"{sum(a <= v < b for v in L):>7d}" for a, b in zip(edges, edges[1:])))
print("tail, normal expects " + "".join(f"{500 * (Phi(b / sd) - Phi(a / sd)):>7.2f}" for a, b in zip(edges, edges[1:])))

assert count_road == h_var, "sorting and counting must pick the same day"
assert abs(cover - cover_direct) < 1e-9, "binomial band: recursion vs direct formula"
assert abs(Phi(1.0) - simpson) < 1e-12, "series vs Simpson for the bell-curve area"
assert abs(C0 - 9.227005508154) < 1e-9, "the house call price"
assert abs(bump - ex) < 1e-7 * ex, "delta by bump vs analytic"
assert abs(bump_y - ey) < 1e-7 * abs(ey), "yield delta by bump vs duration"
assert abs(sd - sd_series) < 1e-6 * sd, "covariance formula vs the P&L series"
assert abs(m_var - sum(reruns) / 20) < 3 * sd_of(reruns), "MC answer sits inside its reruns"
assert 0.5 < se_formula / sd_of(reruns) < 2.0, "error bar: formula vs reruns"
assert abs(normal_delta - p_var) < 3 * se_normal, "normal MC lands on the parametric answer"
assert boot in Ls[489:499], "resampling days returns one of the record's own days"
assert Ls[488] <= truth <= Ls[498], "the order-statistic band holds the truth"
assert split > h_var, "pairing days apart removes the bond's cushion"
print("ALL CHECKS PASS")
