# ISDA SIMM initial margin -- the check behind the card.  Standard library only.
# Two USD rate sensitivities (+10,000 per bp at 5 years, -8,000 per bp at 10 years),
# illustrative risk weights 50 and 55, correlation 0.9; then a EUR bucket, a random test of
# subadditivity, a simulated 99% ten-day loss, and the margin fed into the MVA formula.
# Nothing imported knows the answer: the normal CDF is a series, the percentile is bisection,
# the random numbers are splitmix64 plus Box-Muller, all written out below.
from math import exp, log, sqrt, pi, cos

S1, S2 = 10000.0, -8000.0          # dollars per basis point, 5y and 10y
RW1, RW2, RHO = 50.0, 55.0, 0.90   # illustrative risk weights (bp) and tenor correlation
S_EUR, RW_EUR, GAMMA = -3000.0, 55.0, 0.30   # EUR 10y sensitivity; cross-currency correlation
S_IM, LAM, T = 0.005, 0.02, 1.0    # MVA inputs from the MVA card: spread, hazard, years

def margin(ws, corr):              # sqrt(sum_k sum_l corr_kl ws_k ws_l)
    q = sum(corr[k][l] * ws[k] * ws[l] for k in range(len(ws)) for l in range(len(ws)))
    return sqrt(q)
C2 = [[1.0, RHO], [RHO, 1.0]]
w1, w2 = S1 * RW1, S2 * RW2
k_usd = margin([w1, w2], C2)
# road 2: split the 10y move into the part that follows the 5y move and an independent part
k_fac = sqrt((w1 + RHO * w2) ** 2 + (w2 * sqrt(1.0 - RHO * RHO)) ** 2)
same = margin([w1, -w2], C2)
print(f"inputs, s1 s2 per bp, RW1 RW2, rho: {S1:.0f} {S2:.0f} {RW1:.0f} {RW2:.0f} {RHO:.2f}")
print(f"weighted, WS1 WS2: {w1:.0f} {w2:.0f}")
print(f"margin, 5y alone 10y alone sum: {abs(w1):.0f} {abs(w2):.0f} {abs(w1) + abs(w2):.0f}")
print(f"hand, squares, cross term, under the root: {w1 * w1 + w2 * w2:.0f} {2.0 * RHO * w1 * w2:.0f} {k_usd * k_usd:.0f}")
print(f"margin, pair by formula, by factor split: {k_usd:.2f} {k_fac:.2f}")
print(f"margin, 10y pointing the same way: {same:.2f}")
print(f"margin, pair if rho were 0.99: {margin([w1, w2], [[1.0, 0.99], [0.99, 1.0]]):.2f}")
print(f"saved against the sum, hedged pair, same-way pair: {abs(w1) + abs(w2) - k_usd:.2f} {abs(w1) + abs(w2) - same:.2f}")
assert abs(k_usd - k_fac) < 1e-6

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                          # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total
lo, hi = 0.0, 8.0
for _ in range(200):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if N(mid) < 0.99 else (lo, mid)
Z99 = 0.5 * (lo + hi)

state = 20261123
def uniform():                     # splitmix64, a number in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())

# road 3: a risk weight is a 99% ten-day move, so simulate ten-day rate moves and read the 99% loss
sd1, sd2, n = RW1 / Z99, RW2 / Z99, 200000
losses = []
for _ in range(n):
    e1, e2 = gauss(), gauss()
    x1, x2 = sd1 * e1, sd2 * (RHO * e1 + sqrt(1.0 - RHO * RHO) * e2)
    losses.append(-(S1 * x1 + S2 * x2))
losses.sort()
mc = losses[int(0.99 * n)]
print(f"z99, ten-day sd 5y 10y bp: {Z99:.6f} {sd1:.2f} {sd2:.2f}")
print(f"simulated 99% ten-day loss, draws, ratio to formula: {mc:.0f} {n} {mc / k_usd:.4f}")
assert abs(mc / k_usd - 1.0) < 0.02

# across buckets: USD and EUR, each bucket margin K_b and net S_b capped at +-K_b
w_eur = S_EUR * RW_EUR
k_eur = abs(w_eur)
def cap(s, k): return max(min(s, k), -k)
s_usd, s_eur = cap(w1 + w2, k_usd), cap(w_eur, k_eur)
def total(g): return sqrt(k_usd ** 2 + k_eur ** 2 + 2.0 * g * s_usd * s_eur)
big = margin([w1, w2, w_eur], [[1.0, RHO, GAMMA], [RHO, 1.0, GAMMA], [GAMMA, GAMMA, 1.0]])
print(f"across, EUR WS K: {w_eur:.0f} {k_eur:.0f}")
print(f"across, S_USD S_EUR: {s_usd:.0f} {s_eur:.0f}")
print(f"across, total gamma 0.30, gamma 0, sum of buckets: {total(GAMMA):.2f} {total(0.0):.2f} {k_usd + k_eur:.2f}")
print(f"across, one 3x3 quadratic form: {big:.2f}")
assert abs(total(GAMMA) - big) < 1e-6

# the caps can break subadditivity: each book is a USD 10y swap with a small EUR hedge
def simm(u5, u10, e5, e10):        # the capped two-bucket formula for 5y/10y in USD and EUR
    k = [margin([a * RW1, b * RW2], C2) for a, b in ((u5, u10), (e5, e10))]
    sb = [cap(a * RW1 + b * RW2, kb) for (a, b), kb in zip(((u5, u10), (e5, e10)), k)]
    return sqrt(k[0] ** 2 + k[1] ** 2 + 2.0 * GAMMA * sb[0] * sb[1])
im_a, im_b, im_ab = simm(0, 1e4, -2e3, 0), simm(0, 1e4, 0, -2e3), simm(0, 2e4, -2e3, -2e3)
print(f"caps break it, IM of A, B, A+B, excess: {im_a:.2f} {im_b:.2f} {im_ab:.2f} {im_ab - im_a - im_b:.2f}")
print(f"  A+B EUR bucket, net WS, K: {-2e3 * (RW1 + RW2):.0f} {margin([-2e3 * RW1, -2e3 * RW2], C2):.2f}")
assert abs(simm(S1, S2, 0.0, S_EUR) - big) < 1e-6
assert im_ab > im_a + im_b + 100.0

# subadditivity, tested: random pairs of three-tenor books (5y, 10y, 30y)
RW3 = [50.0, 55.0, 60.0]
C3 = [[1.0, 0.9, 0.8], [0.9, 1.0, 0.9], [0.8, 0.9, 1.0]]
def im3(s): return margin([s[i] * RW3[i] for i in range(3)], C3)
bad, worst, pairs = 0, 0.0, 20000
for _ in range(pairs):
    a = [20000.0 * uniform() - 10000.0 for _ in range(3)]
    b = [20000.0 * uniform() - 10000.0 for _ in range(3)]
    ratio = im3([a[i] + b[i] for i in range(3)]) / (im3(a) + im3(b))
    worst = max(worst, ratio)
    bad += ratio > 1.0 + 1e-12
q_bad = sum([[1, .9, .9], [.9, 1, -.9], [.9, -.9, 1]][k][l] * v[k] * v[l]
            for v in [[100000.0, -100000.0, -100000.0]] for k in range(3) for l in range(3))
print(f"subadditive, pairs tested, violations, worst ratio: {pairs} {bad} {worst:.6f}")
print(f"not a valid correlation table, quantity under the root: {q_bad:.0f}")
assert bad == 0 and worst <= 1.0

# the hedge sweep: margin as the 10y sensitivity grows
sweep = [0.0, -2000.0, -4000.0, -6000.0, -8000.0, -10000.0, -12000.0]
print("sweep, 10y per bp: " + " ".join(f"{s:.0f}" for s in sweep))
print("sweep, margin thousands: " + " ".join(f"{margin([w1, s * RW2], C2) / 1000:.1f}" for s in sweep))
b_star, floor = -RHO * w1 / RW2, abs(w1) * sqrt(1.0 - RHO * RHO)
grid = min((margin([w1, (-12000.0 + 0.01 * i) * RW2], C2), -12000.0 + 0.01 * i) for i in range(1200001))
print(f"lowest-margin hedge per bp, margin; grid search: {b_star:.2f} {floor:.2f}; {grid[1]:.2f} {grid[0]:.2f}")
print(f"DV01-neutral hedge -10000 per bp, margin: {margin([w1, -10000.0 * RW2], C2):.2f}")
assert abs(grid[0] - floor) < 0.01 and abs(grid[1] - b_star) < 0.01

# what breaks
print(f"breaks, no netting, signs dropped, rho 0, tenors netted: {abs(w1) + abs(w2):.0f} {same:.0f} "
      f"{margin([w1, w2], [[1.0, 0.0], [0.0, 1.0]]):.0f} {abs(w1 + w2):.0f}")

# feed into MVA: spread x margin x survival-weighted life, margin held at today's level
ann = (1.0 - exp(-LAM * T)) / LAM
m = 1000
simp = sum((1 if i in (0, m) else 4 if i % 2 else 2) * exp(-LAM * T * i / m) for i in range(m + 1)) * T / m / 3
mva_pair, mva_apart = S_IM * k_usd * ann, S_IM * (abs(w1) + abs(w2)) * ann
print(f"mva, survival-weighted life closed form, by Simpson: {ann:.6f} {simp:.6f}")
print(f"mva, pair in one netting set, trades apart, saving: {mva_pair:.2f} {mva_apart:.2f} {mva_apart - mva_pair:.2f}")
assert abs(ann - simp) < 1e-9
print("ALL CHECKS PASS")
