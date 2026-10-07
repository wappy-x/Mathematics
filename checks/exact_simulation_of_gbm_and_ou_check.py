# Exact simulation of GBM and OU -- the check behind the card.  Only math is imported.
# A share starts at S0 = $100 with drift MU = 8 percent and volatility SIG = 20 percent a year:
# dS = MU S dt + SIG S dW.  A short rate starts at R0 = 6 percent, pulled to THETA = 4 percent at
# KAPPA = 0.5 a year: dr = KAPPA (THETA - r) dt + SIG_R dW.  Dates: 12 month-ends, time in years.
# Roads: the closed-form law at one year; the exact step's own moment recursion on even and
# calendar months; Euler's moment recursion at 1, 12, 100, 1000 steps; 20000 exact monthly paths
# (SplitMix64, seed 20260930, Box-Muller); 2000 Brownian paths of 1000 steps for Euler's path error.
import math

S0, MU, SIG, R0, THETA, KAPPA, SIG_R, T = 100.0, 0.08, 0.20, 0.06, 0.04, 0.5, 0.02, 1.0
PATHS, FINE_PATHS, FINE, SEED, MASK = 20000, 2000, 1000, 20260930, (1 << 64) - 1
EVEN = [1 / 12] * 12
CAL = [d / 365 for d in (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)]

def ncdf(x, n=2000):                     # bell-curve area left of x: one half plus Simpson from 0 to x
    h, s = x / n, 0.0
    for i in range(n + 1):
        s += (1 if i in (0, n) else (4 if i % 2 else 2)) * math.exp(-0.5 * (i * h) * (i * h))
    return 0.5 + s * h / 3 / math.sqrt(2 * math.pi)

class SplitMix64:                        # the wing's generator, written out
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                    # Box-Muller, cosine half only
        u1, u2 = 1.0 - self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def stats(xs):                           # mean, its SE, variance, its SE
    n = len(xs); m = sum(xs) / n
    c2 = sum((x - m) * (x - m) for x in xs) / n
    c4 = sum(((x - m) * (x - m)) * ((x - m) * (x - m)) for x in xs) / n
    return m, math.sqrt(c2 / (n - 1)), c2 * n / (n - 1), math.sqrt((c4 - c2 * c2) / n)

# road 1: the closed-form law at one year
g_mean = S0 * math.exp(MU * T)
g_var = S0 * S0 * math.exp(2 * MU * T) * (math.exp(SIG * SIG * T) - 1)
p120 = ncdf((math.log(S0 / 120) + (MU - SIG * SIG / 2) * T) / (SIG * math.sqrt(T)))
o_mean = THETA + (R0 - THETA) * math.exp(-KAPPA * T)
o_var = SIG_R * SIG_R / (2 * KAPPA) * (1 - math.exp(-2 * KAPPA * T))
print(f"GBM: S0 {S0:.0f}, mu {MU}, sigma {SIG}; OU: r0 {R0}, theta {THETA}, kappa {KAPPA}, sigma {SIG_R}")
print(f"law at 1 year: GBM mean {g_mean:.4f} var {g_var:.4f} sd {math.sqrt(g_var):.4f} median {S0 * math.exp((MU - SIG * SIG / 2) * T):.4f} P(S > 120) {p120:.4f}")
print(f"law at 1 year: OU mean {100 * o_mean:.4f} percent, var {o_var:.8f}, sd {100 * math.sqrt(o_var):.4f} points")
a, d = math.exp(-KAPPA / 12), 1 / 12
print(f"monthly step: GBM log drift {(MU - SIG * SIG / 2) * d:.6f}, log sd {SIG * math.sqrt(d):.6f}; OU a {a:.6f},"
      f" exact sd {100 * SIG_R * math.sqrt((1 - a * a) / (2 * KAPPA)):.6f} points, Euler factor {1 - KAPPA * d:.6f}, Euler sd {100 * SIG_R * math.sqrt(d):.6f}")
print(f"hand, one month with Z = 1: GBM exact {S0 * math.exp((MU - SIG * SIG / 2) * d + SIG * math.sqrt(d)):.4f}, Euler {S0 * (1 + MU * d + SIG * math.sqrt(d)):.4f};"
      f" OU exact {100 * (THETA + a * (R0 - THETA) + SIG_R * math.sqrt((1 - a * a) / (2 * KAPPA))):.4f}, Euler {100 * (R0 + KAPPA * (THETA - R0) * d + SIG_R * math.sqrt(d)):.4f} percent")

# road 2: chain the exact step's moments date by date; no closed form is used
def exact_chain(steps):
    m1, m2, om, ov = S0, S0 * S0, R0, 0.0
    for h in steps:
        m1, m2 = m1 * math.exp(MU * h), m2 * math.exp((2 * MU + SIG * SIG) * h)
        e = math.exp(-KAPPA * h)
        om, ov = THETA + e * (om - THETA), e * e * ov + SIG_R * SIG_R * (1 - e * e) / (2 * KAPPA)
    return m1, m2 - m1 * m1, om, ov
for lab, grid in (("even months", EVEN), ("calendar months", CAL)):
    m1, v1, om, ov = exact_chain(grid)
    print(f"exact chain, {lab:15s}: GBM mean {m1:.10f} var {v1:.10f}; OU mean {100 * om:.10f} var {ov:.12f}")
    assert abs(m1 - g_mean) < 1e-9 and abs(v1 - g_var) < 1e-8 and abs(om - o_mean) < 1e-14 and abs(ov - o_var) < 1e-16

# road 3: Euler's own moments, exact, at shrinking steps
def euler_chain(n):
    h, m1, m2, om, ov = T / n, S0, S0 * S0, R0, 0.0
    for _ in range(n):
        m1, m2 = m1 * (1 + MU * h), m2 * ((1 + MU * h) * (1 + MU * h) + SIG * SIG * h)
        om, ov = THETA + (1 - KAPPA * h) * (om - THETA), (1 - KAPPA * h) * (1 - KAPPA * h) * ov + SIG_R * SIG_R * h
    return m1, m2 - m1 * m1, om, ov
errs = []
for n in (1, 12, 100, 1000):
    m1, v1, om, ov = euler_chain(n)
    errs.append((abs(v1 - g_var), abs(ov - o_var)))
    print(f"Euler {n:4d} steps: GBM mean {m1:.4f} var {v1:.4f} (off {100 * (v1 / g_var - 1):+.4f} percent);"
          f" OU mean {100 * om:.4f} var {ov:.8f} (off {100 * (ov / o_var - 1):+.4f} percent)")
for k in (0, 1):
    assert errs[0][k] > errs[1][k] > errs[2][k] > errs[3][k] > 1e-7 * errs[0][k]

# road 4: 20000 exact monthly paths; Euler driven by the very same draws
g = SplitMix64(SEED)
gS, oR, eS, gap, wrong, fig = [], [], [], [], [], None
for p in range(PATHS):
    s, r, e, w, row = S0, R0, S0, S0, [(S0, S0)]
    for k in range(12):
        z = g.normal()
        s *= math.exp((MU - SIG * SIG / 2) * d + SIG * math.sqrt(d) * z)
        r = THETA + a * (r - THETA) + SIG_R * math.sqrt((1 - a * a) / (2 * KAPPA)) * z
        e *= 1 + MU * d + SIG * math.sqrt(d) * z
        w *= math.exp(MU * d + SIG * math.sqrt(d) * z)          # the mistake: no -sigma^2/2
        row.append((s, e))
    gS.append(s); oR.append(r); eS.append(e); gap.append(abs(e - s)); wrong.append(w)
    if p == 0: fig = row
m, sm, v, sv = stats(gS)
ph = sum(1 for x in gS if x > 120) / PATHS; sph = math.sqrt(ph * (1 - ph) / PATHS)
print(f"exact GBM, 12 steps: mean {m:.4f} +- {sm:.4f} (law {g_mean:.4f}), var {v:.2f} +- {sv:.2f} (law {g_var:.2f}), P(S > 120) {ph:.4f} +- {sph:.4f} (law {p120:.4f})")
assert abs(m - g_mean) < 4 * sm and abs(v - g_var) < 4 * sv and abs(ph - p120) < 4 * sph
m, sm, v, sv = stats(oR)
print(f"exact OU, 12 steps: mean {100 * m:.4f} +- {100 * sm:.4f} percent (law {100 * o_mean:.4f}), var {v:.8f} +- {sv:.8f} (law {o_var:.8f})")
assert abs(m - o_mean) < 4 * sm and abs(v - o_var) < 4 * sv
m, sm, v, sv = stats(eS); em = euler_chain(12)[0]
mg, smg, _, _ = stats(gap)
print(f"Euler GBM, same 12 draws: mean {m:.4f} +- {sm:.4f} (its own theory {em:.4f}); path gap |Euler - exact| {mg:.4f} +- {smg:.4f} dollars")
assert abs(m - em) < 4 * sm
mw, smw, _, _ = stats(wrong)
print(f"mistake, no -sigma^2/2: mean {mw:.4f} +- {smw:.4f}, theory {S0 * math.exp((MU + SIG * SIG / 2) * T):.4f}")
assert abs(mw - S0 * math.exp((MU + SIG * SIG / 2) * T)) < 4 * smw and mw - g_mean > 8 * smw

# road 5: one fine Brownian path per sample, 1000 steps; exact GBM from W_T, Euler on coarser grids
g = SplitMix64(SEED + 1)
gaps, oE = {n: [] for n in (1, 10, 100, 1000)}, []
hf = T / FINE
for p in range(FINE_PATHS):
    dw = [g.normal() * math.sqrt(hf) for _ in range(FINE)]
    exact = S0 * math.exp((MU - SIG * SIG / 2) * T + SIG * sum(dw))
    for n in gaps:
        e, b, h = S0, FINE // n, T / n
        for j in range(n): e *= 1 + MU * h + SIG * sum(dw[j * b:(j + 1) * b])
        gaps[n].append(abs(e - exact))
    r = R0
    for x in dw: r += KAPPA * (THETA - r) * hf + SIG_R * x
    oE.append(r)
gm = [stats(gaps[n])[:2] for n in (1, 10, 100, 1000)]
for n, (mg, smg) in zip((1, 10, 100, 1000), gm):
    print(f"Euler GBM path error, {n:4d} steps: {mg:.4f} +- {smg:.4f} dollars")
assert gm[0][0] > gm[1][0] > gm[2][0] > gm[3][0] and 5 < gm[1][0] / gm[3][0] < 20
m, sm, v, sv = stats(oE)
print(f"Euler OU, 1000 steps, {FINE_PATHS} paths: mean {100 * m:.4f} +- {100 * sm:.4f} percent, var {v:.8f} +- {sv:.8f} (law {o_var:.8f})")
assert abs(m - o_mean) < 4 * sm and abs(v - o_var) < 4 * sv
wv = 0.0
for _ in range(12): wv = a * a * wv + SIG_R * SIG_R * d             # the mistake: Euler's noise in the exact step
print(f"mistake, OU exact step with Euler's noise sd: var {wv:.8f} (law {o_var:.8f})"); assert 1.03 < wv / o_var < 1.05
print("figure, Euler path error at 1, 10, 100, 1000 steps, dollars: " + ", ".join(f"{x[0]:.2f}" for x in gm))
print("figure, month: " + ", ".join(str(k) for k in range(13)))
print("figure, exact path, dollars: " + ", ".join(f"{x[0]:.2f}" for x in fig))
print("figure, Euler path, same draws: " + ", ".join(f"{x[1]:.2f}" for x in fig))
print("ALL CHECKS PASS")
