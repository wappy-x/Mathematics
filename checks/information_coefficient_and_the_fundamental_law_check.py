# Information coefficient and the fundamental law -- the check behind the card.
# Standard library only. Every number quoted on the card is printed here.
# Own random numbers (splitmix64 + Box-Muller), own normal CDF (Simpson), own sums.
from math import sqrt, log, cos, sin, pi, exp, asin, floor
from fractions import Fraction

M64 = (1 << 64) - 1
state = 20260928
def uniform():                                    # splitmix64, then 53 bits into (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    z ^= z >> 31
    return ((z >> 11) + 0.5) / 9007199254740992.0
def normal_pair():                                # Box-Muller: two bell-curve draws
    r, a = sqrt(-2.0 * log(uniform())), 2.0 * pi * uniform()
    return r * cos(a), r * sin(a)
def normals(n):
    out = []
    while len(out) < n:
        out.extend(normal_pair())
    return out[:n]
def N(x):                                         # bell-curve area left of x, Simpson on [0, |x|]
    n, h = 2000, abs(x) / 2000
    f = lambda t: exp(-0.5 * t * t) / sqrt(2.0 * pi)
    s = f(0.0) + f(abs(x)) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))
    area = s * h / 3.0
    return 0.5 + area if x >= 0 else 0.5 - area
def pearson(x, y):
    n = len(x); mx, my = sum(x) / n, sum(y) / n
    sxy = sum((a - mx) * (b - my) for a, b in zip(x, y))
    sxx = sum((a - mx) ** 2 for a in x); syy = sum((b - my) ** 2 for b in y)
    return sxy / sqrt(sxx * syy)
def ranks(v):
    order = sorted(range(len(v)), key=lambda i: v[i])
    r = [0.0] * len(v)
    for k, i in enumerate(order): r[i] = k + 1.0
    return r

# ---- 1. the toy: five stocks, scores and next-year residual returns (percent) ----
score, ret = [-2, -1, 0, 1, 2], [-2, 0, 1, -1, 2]
ic_toy, ric_toy = pearson(score, ret), pearson(ranks(score), ranks(ret))
by_hand = Fraction(sum(a * b for a, b in zip(score, ret)), 10)   # 7 / sqrt(10 x 10), in integers

# ---- 2. the law, and its exact form inside the model ----
IC, B, omega = 0.05, 500, 0.25
law = IC * sqrt(B)
exact = law / sqrt(1 - IC * IC)

# ---- 3. coin-flip model, every outcome counted: A = IC*B + sqrt(1-IC^2)*(2k - B), k ~ Binomial(B, 1/2) ----
lp, mean_a, sq_a, lose = B * log(0.5), 0.0, 0.0, 0.0   # log of each chance: no underflow at B = 2000
for k in range(B + 1):
    a = IC * B + sqrt(1 - IC * IC) * (2 * k - B)
    p = exp(lp); mean_a += p * a; sq_a += p * a * a
    if a < 0: lose += p
    lp += log(max(B - k, 1) / (k + 1))
ir_coin = mean_a / sqrt(sq_a - mean_a * mean_a)

# ---- 4. simulation: 4000 years, 500 stocks, bell-curve scores and shocks ----
YEARS = 4000
act, act_sort, ics, hits = [], [], [], 0
bins = [0] * 12                                   # realised IC from -0.10 to 0.20 in steps of 0.025
for _ in range(YEARS):
    z = normals(B)
    mz = sum(z) / B; sz = sqrt(sum((v - mz) ** 2 for v in z) / B)
    z = [(v - mz) / sz for v in z]                # standardise: mean 0, spread 1 across stocks
    eps = normals(B)
    th = [omega * (IC * zi + sqrt(1 - IC * IC) * e) for zi, e in zip(z, eps)]
    act.append(sum(zi * t for zi, t in zip(z, th)))                          # weights in proportion to score
    act_sort.append(sum((1.0 if zi > 0 else -1.0) * t for zi, t in zip(z, th)))  # long top half, short bottom half
    ic_y = pearson(z, th); ics.append(ic_y)
    hits += sum(1 for zi, t in zip(z, th) if (zi > 0) == (t > 0))
    j = floor((ic_y + 0.10) / 0.025)
    if 0 <= j < 12: bins[j] += 1
def ir_of(xs):
    m = sum(xs) / len(xs)
    return m / sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))
ir_sim, ir_sort_sim = ir_of(act), ir_of(act_sort)
ic_mean = sum(ics) / YEARS
ic_sd = sqrt(sum((c - ic_mean) ** 2 for c in ics) / (YEARS - 1))
lose_sim = sum(1 for a in act if a < 0) / YEARS
hit_sim = hits / (YEARS * B)
tc_sort = sqrt(2 / pi)                            # correlation of sign(z) with z for a bell curve

rows = [
    ("toy: sum of score x return", sum(a * b for a, b in zip(score, ret))),
    ("toy: sum of squared scores", sum(a * a for a in score)),
    ("toy: sum of squared returns", sum(b * b for b in ret)),
    ("toy: Pearson IC, five stocks", ic_toy), ("toy: rank IC, five stocks", ric_toy),
    ("law: IC x sqrt(500)", law), ("exact model: law / sqrt(1 - IC^2)", exact),
    ("coin-flip model, all 501 outcomes", ir_coin), ("simulation, 4000 years: IR", ir_sim),
    ("simulation: mean realised IC", ic_mean), ("simulation: spread of realised IC", ic_sd),
    ("theory: spread 1/sqrt(500)", 1 / sqrt(B)),
    ("coin-flip: chance of a losing year", lose), ("bell curve: N(-exact IR)", N(-exact)),
    ("simulation: share of losing years", lose_sim),
    ("hit rate: 1/2 + asin(IC)/pi", 0.5 + asin(IC) / pi), ("simulation: hit rate", hit_sim),
    ("R-squared: IC^2", IC * IC), ("residual volatility omega", omega), ("forecast alpha, score +1", IC * omega * 1.0),
    ("expected active return at 4% risk", law * 0.04),
    ("sort portfolio: TC sqrt(2/pi)", tc_sort), ("sort portfolio: TC x law", tc_sort * law),
    ("sort portfolio: simulation", ir_sort_sim),
    ("wrong: 50 lockstep groups, IC sqrt(50)", IC * sqrt(50)), ("wrong: no square root, IC x 500", IC * B),
    ("monthly bets: IC sqrt(12 x 500)", IC * sqrt(12 * B)), ("wrong: monthly IR x 12", law * 12),
    ("right: monthly IR x sqrt(12)", law * sqrt(12)),
    ("timing, breadth 1: IC for the same IR", law / sqrt(1 + law * law)),
]
for name, v in rows:
    print(f"{name:<40} {v:>11.6f}")
print("chart, breadth      " + " ".join(f"{b:>6d}" for b in (25, 50, 100, 200, 500, 1000, 2000)))
for ic in (0.05, 0.10):
    print(f"chart, IC {ic:.2f}     " + " ".join(f"{ic * sqrt(b):6.2f}" for b in (25, 50, 100, 200, 500, 1000, 2000)))
print("histogram, IC from  " + " ".join(f"{-0.10 + 0.025 * j:6.3f}" for j in range(12)))
print("histogram, years    " + " ".join(f"{c:6d}" for c in bins))

assert abs(ic_toy - float(by_hand)) < 1e-12,  "toy IC vs the integer count by hand, 7/10"
assert abs(ir_coin - exact) < 1e-9,          "every-outcome count must land on the exact model"
assert abs(ir_sim - exact) < 4 * sqrt((1 + exact ** 2 / 2) / YEARS), "simulated IR within 4 standard errors"
assert abs(ic_mean - IC) < 4 * (1 / sqrt(B)) / sqrt(YEARS), "mean realised IC within 4 standard errors"
assert abs(lose - N(-exact)) < 0.01,         "binomial losing-year chance vs bell curve"
assert abs(hit_sim - (0.5 + asin(IC) / pi)) < 0.002, "simulated hit rate vs Sheppard's formula"
assert abs(ir_sort_sim - tc_sort * exact) < 0.08, "sort portfolio IR shrinks by the transfer coefficient"
assert ir_sort_sim < ir_sim,                  "score-weighted beats sign-weighted"
print("ALL CHECKS PASS")
