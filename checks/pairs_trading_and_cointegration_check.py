# Pairs trading and cointegration -- the check behind the card.  Standard library only.
# Own random numbers (splitmix64 + Box-Muller), own least squares, own Dickey-Fuller
# regression, own critical values by simulation.  Nothing imported knows the answer.
from math import log, sqrt, cos, pi

M64 = (1 << 64) - 1
class Rng:
    def __init__(self, seed): self.s = seed
    def u(self):                                   # uniform on (0, 1), splitmix64
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    def z(self):                                   # one bell-curve draw, Box-Muller
        a = self.u()
        return sqrt(-2.0 * log(a)) * cos(2.0 * pi * self.u())

def ols(x, y):                                     # fit y = c + b x; return b, c, R^2
    n = len(x); mx = sum(x) / n; my = sum(y) / n
    sxx = sum((a - mx) ** 2 for a in x)
    sxy = sum((a - mx) * (b - my) for a, b in zip(x, y))
    syy = sum((b - my) ** 2 for b in y)
    return sxy / sxx, my - sxy / sxx * mx, sxy * sxy / (sxx * syy)

def df_t(u, const=False):                          # Dickey-Fuller: change on lagged level
    lag = u[:-1]; d = [u[i + 1] - u[i] for i in range(len(u) - 1)]
    if const:
        b, c, _ = ols(lag, d); m = sum(lag) / len(lag)
        sxx = sum((a - m) ** 2 for a in lag); k = 2
    else:
        sxx = sum(a * a for a in lag); b = sum(a * e for a, e in zip(lag, d)) / sxx; c = 0.0; k = 1
    rss = sum((e - c - b * a) ** 2 for a, e in zip(lag, d))
    return b, b / sqrt(rss / (len(d) - k) / sxx)

def walk(r, n, start, sd):
    w = [start]
    for _ in range(n - 1): w.append(w[-1] + sd * r.z())
    return w

def year(seed, phi, n=251):                       # B wanders; A = 1.3 B + a spread pulled back by phi
    r = Rng(seed); B = walk(r, n, 100.0, 1.0)
    u = [0.5 / sqrt(1.0 - phi * phi) * r.z()]
    for _ in range(n - 1): u.append(phi * u[-1] + 0.5 * r.z())
    return r, B, [1.3 * b + e for b, e in zip(B, u)], walk(r, n, 100.0, 1.0)

def show(lab, v, f=".6f"): print(f"{lab:<34}{v:>12{f}}")
def tidy(v): return 0.0 if abs(v) < 1e-9 else v

# ---- road 1: the six-date table, retailer B and retailer A, dollars per share ----
B = [100.0, 101.0, 99.0, 100.0, 102.0, 101.0]
A = [130.0, 132.3, 129.7, 128.0, 132.6, 131.3]
beta, c, _ = ols(B, A)
pairs = [(i, j) for i in range(6) for j in range(i + 1, 6)]   # road 2: slopes between every two dates
beta_pw = sum((B[i] - B[j]) * (A[i] - A[j]) for i, j in pairs) / sum((B[i] - B[j]) ** 2 for i, j in pairs)
mB, mA = sum(B) / 6, sum(A) / 6
rss = lambda b: sum(((y - mA) - b * (x - mB)) ** 2 for x, y in zip(B, A))
lo, hi, g = 0.0, 5.0, (sqrt(5.0) - 1.0) / 2.0                 # road 3: golden-section search on the misfit
for _ in range(80):
    m1, m2 = hi - g * (hi - lo), lo + g * (hi - lo)
    if rss(m1) < rss(m2): hi = m2
    else: lo = m1
beta_gs = (lo + hi) / 2.0
res = [y - c - beta * x for x, y in zip(B, A)]
rho, t6 = df_t(res)
show("table: beta, least squares", beta); show("table: beta, pairwise slopes", beta_pw)
show("table: beta, golden-section search", beta_gs); show("table: intercept c", tidy(c))
print(f"{'table: spread A - 1.3 B':<34}" + " ".join(f"{tidy(v):.2f}" for v in res))
show("table: misfit, sum of squares", sum(v * v for v in res))
show("table: rho", rho); show("table: t = rho / its std error", t6)
show("wrong: regress B on A, invert", 1.0 / ols(A, B)[0])

# ---- the trade: buy 100 A at date 3, short 130 B, close at date 4 ----
nA, nB = 100, 130
pnl_legs = nA * (A[4] - A[3]) - nB * (B[4] - B[3])
pnl_spread = nA * (res[4] - res[3])
show("trade: long leg at entry", nA * A[3], ".2f"); show("trade: short leg at entry", nB * B[3], ".2f")
show("trade: P&L, leg by leg", pnl_legs, ".2f"); show("trade: P&L, 100 x spread change", pnl_spread, ".2f")
show("wrong: 128 B, both prices drift", nA * 1.3 * 10.0 - 128 * 10.0, ".2f")

# ---- road 4: a simulated year of 251 days, pull-back 0.9 a day, and an unrelated third share C ----
phi = 0.9
r, Bs, As, Cs = year(2030, phi)
bs, cs, r2s = ols(Bs, As)
sp = [y - cs - bs * x for x, y in zip(Bs, As)]
rho_s, t_s = df_t(sp)
bc, cc, r2c = ols(Cs, As)
spc = [y - cc - bc * x for x, y in zip(Cs, As)]
t_c = df_t(spc)[1]
for lab, v in (("sim: beta", bs), ("sim: intercept c", cs), ("sim: R^2", r2s), ("sim: rho", rho_s),
               ("sim: 1 + rho, true 0.9", 1 + rho_s), ("sim: half-life, days", log(0.5) / log(1.0 + rho_s)),
               ("  half-life if 0.9 exactly", log(0.5) / log(phi)), ("sim: t", t_s),
               ("unrelated: beta", bc), ("unrelated: R^2", r2c), ("unrelated: t", t_c)):
    show(lab, v)

# ---- road 5, the referee: 4000 pairs of unrelated walks; what t does fitting alone produce? ----
R, n = 4000, 251
teg, tdc, td0, r2n = [], [], [], []
for _ in range(R):
    x = walk(r, n, 100.0, 1.0); y = walk(r, n, 100.0, 1.0)
    b, c0, q = ols(x, y)
    teg.append(df_t([v - c0 - b * w for w, v in zip(x, y)])[1])
    tdc.append(df_t(y, True)[1]); td0.append(df_t([v - y[0] for v in y])[1]); r2n.append(q)
k = int(0.05 * R)
q_eg, q_dc, q_d0 = sorted(teg)[k], sorted(tdc)[k], sorted(td0)[k]
for lab, v in (("5% cut, Engle-Granger (MK -3.36)", q_eg), ("5% cut, 1 series+const (MK -2.87)", q_dc),
               ("5% cut, 1 series bare (MK -1.94)", q_d0),
               ("false alarms %, E-G cutoff", 100 * sum(t < q_eg for t in teg) / R),
               ("false alarms %, 1 series+const", 100 * sum(t < q_dc for t in teg) / R),
               ("false alarms %, 1 series bare", 100 * sum(t < q_d0 for t in teg) / R),
               ("unrelated pairs: median R^2", sorted(r2n)[R // 2])):
    show(lab, v)

# ---- try changing: a slower pull-back, and another year from another seed ----
for lab, (s, p) in (("try: phi = 0.995", (2030, 0.995)), ("try: seed 2026", (2026, 0.9))):
    _, x, y, _ = year(s, p); b, c0, _ = ols(x, y)
    print(f"{lab + ': beta, t':<34}{b:>12.6f}{df_t([v - c0 - b * w for w, v in zip(x, y)])[1]:>12.6f}")

# ---- chart points, every 10th day ----
idx = range(0, n, 10)
print("chart, day   " + " ".join(f"{i}" for i in idx))
print("chart, A     " + " ".join(f"{As[i]:.2f}" for i in idx))
print("chart, 1.3B  " + " ".join(f"{1.3 * Bs[i]:.2f}" for i in idx))
print("chart, sprd  " + " ".join(f"{sp[i]:.2f}" for i in idx))
print("chart, unrel " + " ".join(f"{spc[i]:.2f}" for i in idx))

assert abs(beta - 1.3) < 1e-12 and abs(beta_pw - 1.3) < 1e-12, "table built as A = 1.3 B + (0,1,1,-2,0,0)"
assert abs(beta_gs - beta_pw) < 1e-6,           "search and pairwise slopes agree"
assert abs(rho - (-7.0 / 6.0)) < 1e-12,         "hand-worked rho = -7/6"
assert abs(t6 - (-14.0 / sqrt(35.0))) < 1e-9,   "hand-worked t = -14/sqrt(35)"
assert abs(pnl_legs - pnl_spread) < 1e-9,       "leg-by-leg P&L equals shares x spread change"
assert abs(bs - 1.3) < 0.03,                    "fitted ratio near the 1.3 the year was built with"
assert abs((1 + rho_s) - phi) < 0.08,           "fitted pull-back near the 0.9 it was built with"
assert abs(q_eg - (-3.36)) < 0.15,              "Engle-Granger 5% cutoff vs MacKinnon 2010, two series, T=250"
assert abs(q_dc - (-2.87)) < 0.12,              "Dickey-Fuller 5% cutoff with constant vs MacKinnon 2010"
assert abs(q_d0 - (-1.94)) < 0.12,              "Dickey-Fuller 5% cutoff, no constant, vs MacKinnon 2010"
assert t_s < q_eg < t_c,                        "the tied pair passes, the unrelated pair does not"
print("ALL CHECKS PASS")
