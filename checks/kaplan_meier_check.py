# Kaplan-Meier -- the check behind the card.  Standard library only.  Nothing
# imported knows the answer: the curve is built two ways (a product over risk
# sets, and Efron's redistribute-to-the-right), the error bar two ways (the
# Greenwood sum, and the spread across simulated trials), and every random
# draw comes from SplitMix64, written out, with a stated seed.
from math import log, exp, sqrt

# the trial: months to relapse (1) or to dropout (0), 12 patients
TRIAL = [(3, 1), (4, 0), (5, 1), (5, 1), (8, 1), (8, 0), (11, 1), (12, 0),
         (14, 1), (16, 0), (20, 1), (24, 0)]
Z = 1.96                                     # the normal quantile for a 95% interval

def km(data, dropout_first=False):
    # road 1: at each time, d relapses among r still followed; multiply (1 - d/r)
    pts = sorted(data, key=lambda p: (p[0], p[1] if dropout_first else -p[1]))
    rows, s, g, r, i = [], 1.0, 0.0, len(pts), 0
    while i < len(pts):
        t, j = pts[i][0], i
        while j < len(pts) and pts[j][0] == t:
            j += 1
        d = sum(e for _, e in pts[i:j]); c = j - i - d
        rr = r - c if dropout_first else r   # the wrong tie rule drops the leavers first
        if d:
            s *= 1.0 - d / rr
            g += d / (rr * (rr - d)) if rr > d else 0.0
        rows.append((t, r, d, c, s, g))
        r -= j - i; i = j
    return rows

def at(rows, t):                             # the curve's height at month t
    out = (1.0, 0.0)
    for u, _, _, _, s, g in rows:
        if u <= t: out = (s, g)
    return out

def redistribute(data):
    # road 2 (Efron 1967): each patient holds 1/n of the curve; a dropout hands
    # its share, equally, to everyone after it in time order (relapses first at a tie)
    pts = sorted(data, key=lambda p: (p[0], -p[1]))
    w = [1.0 / len(pts)] * len(pts)
    for i, (t, e) in enumerate(pts):
        if e == 0 and i + 1 < len(pts):
            share = w[i] / (len(pts) - i - 1)
            for j in range(i + 1, len(pts)): w[j] += share
            w[i] = 0.0
    return {t: 1.0 - sum(w[k] for k, (u, e) in enumerate(pts) if e == 1 and u <= t)
            for t, e in pts if e == 1}

def loglog_band(s, g):                       # 95% interval on the log(-log S) scale
    if s >= 1.0 or s <= 0.0: return (s, s)
    w = Z * sqrt(g) / abs(log(s))
    return (s ** exp(w), s ** exp(-w))

class SplitMix64:
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return z ^ (z >> 31)
    def uniform(self): return (self.next() >> 11) * 2.0 ** -53

rows = km(TRIAL)
print("month at_risk relapses dropouts  factor   S_hat  greenwood_sum      SE")
for t, r, d, c, s, g in rows:
    print(f"{t:5d} {r:7d} {d:8d} {c:8d} {1 - d / r:7.4f} {s:7.4f} {g:14.6f} {s * sqrt(g):7.4f}")
eff = redistribute(TRIAL)
gap = max(abs(eff[t] - at(rows, t)[0]) for t in eff)
print("road 2, redistribute-to-the-right:", " ".join(f"{eff[t]:.6f}" for t in sorted(eff)))
print(f"road 2, largest gap to road 1: {gap:.12f}")
best = []                                    # road 3: grid search of each factor h^d (1-h)^(r-d)
for t, r, d, c, s, g in rows:
    if d:
        ll = lambda h: d * log(h) + (r - d) * log(1 - h)
        best.append((max(range(1, 1000), key=lambda k: ll(k / 1000)) / 1000, d / r))
print("road 3, grid argmax vs d/r:", " ".join(f"{a:.3f}/{b:.3f}" for a, b in best))
s14, g14 = at(rows, 14); s20, g20 = at(rows, 20)
for t, s, g in ((14, s14, g14), (20, s20, g20)):
    lo, hi = loglog_band(s, g)
    print(f"S({t}) = {s:.6f}  SE {s * sqrt(g):.6f}  plain 95%: {s - Z * s * sqrt(g):.4f} to "
          f"{s + Z * s * sqrt(g):.4f}  log-log 95%: {lo:.4f} to {hi:.4f}")
print(f"median relapse-free time: {min(t for t, *_, s, g in rows if s <= 0.5)} months")

# ---- what breaks ----
print(f"wrong: dropouts counted as relapses, S(14) = {at(km([(t, 1) for t, e in TRIAL]), 14)[0]:.6f}")
print(f"wrong: dropouts deleted, S(14) = {at(km([p for p in TRIAL if p[1]]), 14)[0]:.6f}")
print(f"wrong: no clock, share never seen to relapse = {sum(1 - e for _, e in TRIAL) / 12:.6f}")
wt = km(TRIAL, dropout_first=True)
print(f"wrong: dropout removed before the month-8 relapse, S(8) = {at(wt, 8)[0]:.6f}, S(14) = {at(wt, 14)[0]:.6f}")

# ---- road 4: 4000 simulated trials, 60 patients each, true S(12) = 0.5 ----
rng, TRIALS, N, LAM = SplitMix64(2026), 4000, 60, log(2.0) / 12.0
sums = {"km": [0.0, 0.0], "se": [0.0, 0.0], "all": [0.0, 0.0], "del": [0.0, 0.0], "inf": [0.0, 0.0]}
for _ in range(TRIALS):
    fair, sick = [], []
    for _ in range(N):
        tt = -log(1.0 - rng.uniform()) / LAM          # true relapse month, median 12
        cc = min(48.0 * rng.uniform(), 24.0)          # dropout month, study stops at 24
        c2 = min(cc, tt / 2) if (rng.uniform() < 0.5 and tt < 12.0) else cc
        fair.append((min(tt, cc), 1 if tt <= cc else 0))
        sick.append((min(tt, c2), 1 if tt <= c2 else 0))
    s, g = at(km(fair), 12)
    vals = {"km": s, "se": s * sqrt(g), "all": at(km([(t, 1) for t, e in fair]), 12)[0],
            "del": at(km([p for p in fair if p[1]]), 12)[0], "inf": at(km(sick), 12)[0]}
    for k, v in vals.items():
        sums[k][0] += v; sums[k][1] += v * v
mean = {k: a / TRIALS for k, (a, b) in sums.items()}
sd = {k: sqrt(b / TRIALS - mean[k] ** 2) for k, (a, b) in sums.items()}
mc = sd["km"] / sqrt(TRIALS)
print(f"sim: mean S_hat(12) = {mean['km']:.4f} (MC SE {mc:.4f}), truth 0.5000")
print(f"sim: spread of S_hat(12) across trials = {sd['km']:.4f}, mean Greenwood SE = {mean['se']:.4f}")
print(f"sim wrong: dropouts as relapses {mean['all']:.4f}, dropouts deleted {mean['del']:.4f}, "
      f"sick patients leave early {mean['inf']:.4f}")

# ---- try changing ----
alt = [(4, 1) if p == (4, 0) else p for p in TRIAL]
dbl = at(km(TRIAL + TRIAL), 14)
print(f"try: month-4 dropout relapses instead, S(14) = {at(km(alt), 14)[0]:.6f}")
print(f"try: every record doubled, S(14) = {dbl[0]:.6f}, SE {dbl[0] * sqrt(dbl[1]):.6f}")
print(f"try: last patient relapses at 24, S(24) = {at(km(TRIAL[:-1] + [(24, 1)]), 24)[0]:.6f}")

# ---- chart and figure points ----
band = [loglog_band(*at(rows, m)) for m in range(25)]
print("chart, S_hat  ", " ".join(f"{at(rows, m)[0]:.2f}" for m in range(25)))
print("chart, lower  ", " ".join(f"{lo:.2f}" for lo, hi in band))
print("chart, upper  ", " ".join(f"{hi:.2f}" for lo, hi in band))
print("figure, x = 40 + 12.5 * month; line ends:", " ".join(f"{40 + 12.5 * t:g}" for t, e in TRIAL))

assert gap < 1e-12, "redistribute-to-the-right must give the product-limit curve"
assert abs(s14 - 77 / 192) < 1e-12 and abs(s20 - 77 / 384) < 1e-12, "hand fractions 77/192 and 77/384"
assert abs(g14 - (1/132 + 2/80 + 1/56 + 1/30 + 1/12)) < 1e-12, "Greenwood sum from the hand table"
assert all(abs(a - b) < 0.0006 for a, b in best), "each factor peaks at d/r"
assert abs(mean["km"] - 0.5) < 4 * mc, "Kaplan-Meier centred on the true S(12)"
assert abs(mean["se"] / sd["km"] - 1) < 0.05, "Greenwood SE matches the real spread"
assert mean["inf"] - 0.5 > 4 * sd["inf"] / sqrt(TRIALS), "informative dropout must bias the curve up"
print("ALL CHECKS PASS")
