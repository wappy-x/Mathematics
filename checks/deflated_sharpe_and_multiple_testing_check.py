# Deflated Sharpe ratio and CSCV overfitting check. Standard library only: the normal CDF,
# its inverse, the integrals and the random numbers are all written here.
from math import exp, log, sqrt, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)      # bell-curve height
def ncdf(x):                                              # N(x): bell-curve area left of x
    if x < -9: return 0.0
    if x > 9: return 1.0
    term, total, k = x, x, 1                              # x + x^3/3 + x^5/15 + ...
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total
def simpson(f, a, b, n=4000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3
def ninv(p, lo=-9.0, hi=9.0):                             # N^-1(p) by bisection
    for _ in range(80): lo, hi = ((lo + hi) / 2, hi) if ncdf((lo + hi) / 2) < p else (lo, (lo + hi) / 2)
    return (lo + hi) / 2
def row(name, v, f=".6f"): print(f"{name:<34}{v:>12{f}}")

G = 0.5772156649015329                                    # Euler's constant
def emax_density(M): return simpson(lambda z: z * M * phi(z) * ncdf(z) ** (M - 1), -12, 12)
def emax_tail(M):    return simpson(lambda z: 1 - ncdf(z) ** M, 0, 12) - simpson(lambda z: ncdf(z) ** M, -12, 0)
def emax_approx(M):  return (1 - G) * ninv(1 - 1 / M) + G * ninv(1 - 1 / (M * exp(1)))
def dsr(sr_ann, ppy, T, M, skew=0.0, kurt=3.0, per_period=True):
    sr = sr_ann / sqrt(ppy) if per_period else sr_ann     # per_period=False is the clock-mixing mistake
    s0 = emax_approx(M) / sqrt(T - 1) if M > 1 else 0.0
    den = sqrt(1 - skew * sr + (kurt - 1) / 4 * sr * sr)
    return s0 * sqrt(ppy), ncdf((sr - s0) * sqrt(T - 1) / den)

# ---- the example: best of 100 random strategies, 3 years of daily returns, Sharpe 1.4 ----
M, T, PPY, SR = 100, 756, 252, 1.4
sd_ann = sqrt(PPY / (T - 1))                              # spread of a no-skill annual Sharpe
e_exact, e_tail, e_apx = emax_density(M), emax_tail(M), emax_approx(M)
s0_ann, d = dsr(SR, PPY, T, M)
psr0 = dsr(SR, PPY, T, 1)[1]
p_one, p_max = 1 - psr0, 1 - ncdf(SR / sd_ann) ** M
sr_d, s0_d = SR / sqrt(PPY), e_apx / sqrt(T - 1)          # the hand chain, per day
den = sqrt(1 + 2 / 4 * sr_d * sr_d)
print(f"{'N(1.5): series, Simpson':<34}{ncdf(1.5):>12.8f}{0.5 + simpson(phi, 0, 1.5):>12.8f}")
row("observed best annual Sharpe", SR); row("winner's Sharpe per day", sr_d)
row("no-skill Sharpe spread per day", 1 / sqrt(T - 1)); row("no-skill annual Sharpe spread", sd_ann)
row("E[max of 100 z], density integral", e_exact); row("E[max of 100 z], tail integral", e_tail)
row("N^-1(1 - 1/100)", ninv(1 - 1 / M)); row("N^-1(1 - 1/(100e))", ninv(1 - 1 / (M * exp(1))))
row("E[max of 100 z], two-quantile", e_apx); row("expected best annual Sharpe, exact", e_exact * sd_ann)
row("SR0 per day", s0_d); row("SR0 annual (deflation bar)", s0_ann)
row("gap per day", sr_d - s0_d); row("sqrt(T - 1)", sqrt(T - 1)); row("denominator", den)
row("z", (sr_d - s0_d) * sqrt(T - 1) / den); row("DSR", d)
row("PSR against zero (naive)", psr0); row("one-test p-value", p_one)
row("Bonferroni 100 x p", 100 * p_one); row("P(best of 100 >= 1.4 | no skill)", p_max)
print("chart: M, expected best annual Sharpe")
for m in (1, 2, 5, 10, 20, 50, 100, 200, 500, 1000):
    print(f"  M={m:<5}{max(emax_density(m) * sd_ann, 0.0):>10.2f}")   # clamp round-off: E[max] >= 0
# ---- the same 1.4 on ten years of monthly returns (independent reference run) ----
s0_m, d_m = dsr(SR, 12, 120, M)
row("monthly 10y: SR0 annual", s0_m); row("monthly 10y: DSR", d_m)
# ---- what breaks, and try changing ----
row("wrong: count 10 trials, not 100", dsr(SR, PPY, T, 10)[1])
row("wrong: annual Sharpe, daily clock", dsr(SR, PPY, T, M, per_period=False)[1])
row("try: M = 1000, DSR", dsr(SR, PPY, T, 1000)[1]); row("try: 10 years daily, DSR", dsr(SR, PPY, 2520, M)[1])
row("try: monthly, skew -1 kurt 6, DSR", dsr(SR, 12, 120, M, -1.0, 6.0)[1])

# ---- road 3: simulate the search itself, and run CSCV on every matrix ----
M64, state = (1 << 64) - 1, 20260928
def pair():                                               # two normals by Box-Muller from a 64-bit LCG
    global state
    state = (6364136223846793005 * state + 1442695040888963407) & M64; u1 = ((state >> 11) + 0.5) / 2 ** 53
    state = (6364136223846793005 * state + 1442695040888963407) & M64; u2 = ((state >> 11) + 0.5) / 2 ** 53
    r = sqrt(-2 * log(u1)); return r * cos(2 * pi * u2), r * sin(2 * pi * u2)
def sharpe(s, q, n):                                      # annual Sharpe from sum, sum of squares, count
    return s / n / sqrt((q - s * s / n) / (n - 1)) * sqrt(PPY)
def cscv(st, blocks, L):                                  # st[j][b] = (sum, sumsq); counts splits below the middle
    splits = [c for c in range(1 << blocks) if bin(c).count("1") == blocks // 2]
    below = 0
    for c in splits:
        def score(j, want):
            s = sum(st[j][b][0] for b in range(blocks) if (c >> b & 1) == want)
            q = sum(st[j][b][1] for b in range(blocks) if (c >> b & 1) == want)
            return sharpe(s, q, L * blocks // 2)
        best = max(range(len(st)), key=lambda j: score(j, 1))
        oos = [score(j, 0) for j in range(len(st))]
        rank = 1 + sum(o < oos[best] for o in oos)        # rank 1 = worst out of sample
        below += rank <= len(st) // 2
    return below, len(splits)

REPS, BLOCKS = 500, 6
L = T // BLOCKS
tot_max = hits = below_n = below_s = count = 0
for rep in range(REPS):
    noise, skill = [], []
    for j in range(M):
        mu = 2.0 * j / (M - 1) / sqrt(PPY)                # skill family: true annual Sharpe 0 to 2
        z = [v for _ in range(T // 2) for v in pair()]
        blk = [z[b * L:(b + 1) * L] for b in range(BLOCKS)]
        noise.append([(sum(x), sum(v * v for v in x)) for x in blk])
        skill.append([(s + mu * L, q + 2 * mu * s + mu * mu * L) for s, q in noise[-1]])
    best = max(sharpe(sum(b[0] for b in st), sum(b[1] for b in st), T) for st in noise)
    tot_max += best; hits += best >= SR
    bn, count = cscv(noise, BLOCKS, L); below_n += bn
    below_s += cscv(skill, BLOCKS, L)[0]
mc_max, mc_hit, pbo_n, pbo_s = tot_max / REPS, hits / REPS, below_n / (REPS * count), below_s / (REPS * count)
row("simulated mean best Sharpe", mc_max, ".4f"); row("simulated P(best >= 1.4)", mc_hit, ".4f")
row("CSCV splits per matrix", count, "d")
row("PBO, 100 random strategies", pbo_n, ".4f"); row("PBO, family with real skill", pbo_s, ".4f")

# ---- CSCV by hand: four rules, four blocks, mean P&L per block (reference case) ----
cols = ((8, 8, -2, -2), (2, 2, 2, 2), (-2, -2, 8, 8), (1, 1, 1, 1))
ranks = []
for c in (3, 12, 5, 9, 6, 10):                            # in-sample halves {1,2},{3,4},{1,3},{1,4},{2,3},{2,4}
    isc = [sum(col[b] for b in range(4) if c >> b & 1) // 2 for col in cols]
    osc = [sum(col[b] for b in range(4) if not c >> b & 1) // 2 for col in cols]
    pick = max(range(4), key=lambda j: (isc[j], -j))      # ties go to the earlier rule
    ranks.append(1 + sum(osc[j] < osc[pick] or (osc[j] == osc[pick] and j > pick) for j in range(4)))
    print(f"  IS {''.join(str(b + 1) for b in range(4) if c >> b & 1)}: means", *isc, "->", "ABCD"[pick],
          "| OOS means", *osc, "| rank", ranks[-1])
print(f"hand CSCV: PBO {sum(r <= 2 for r in ranks)}/{len(ranks)}")

assert abs(ncdf(1.5) - (0.5 + simpson(phi, 0, 1.5))) < 1e-12       # series vs integral
assert abs(e_exact - e_tail) < 1e-8                                  # two different integrals
assert abs(e_apx - e_exact) < 0.03                                   # the paper's shortcut is close
assert abs(mc_max - e_exact * sd_ann) < 0.08                         # simulation vs integral
assert abs(mc_hit - p_max) < 0.15                                    # simulation vs max law
assert abs(pbo_n - 0.5) < 0.05                                       # symmetry says 1/2 for noise
assert pbo_s < 0.35                                                  # real skill travels
assert abs(d_m - 0.964526) < 1e-5                                    # independent earlier run
assert ranks == [1, 1, 4, 4, 4, 4]                                   # the hand enumeration
print("all checks passed")
