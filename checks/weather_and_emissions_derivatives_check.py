# Weather and emissions derivatives -- the check behind the card.  Standard library only: the
# normal CDF, the integrator and the random numbers are all written here.  A capped winter HDD call
# (base 65F, strike 3,000, 5,000 USD per degree-day, cap 2 million USD) priced from 30 simulated
# winters, and an EU allowance forward by cost of carry (spot 70 EUR, 3 percent, one year).
from math import exp, log, sqrt, cos, pi, prod

R, BASE, K, TICK, CAP, TW = 0.03, 65.0, 3000.0, 5000.0, 2.0e6, 0.5
LIM = CAP / TICK                            # the cap in degree-days: 400
DAYS, M, B, PHI, SD_A, SD_W, WARM = 151, 57.0, 15.0, 0.7, 7.0, 1.5, 0.10

def N(x):                                   # normal CDF, Marsaglia's series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, i = x, x, 1
    while abs(t) > 1e-17:
        i += 2; t *= x * x / i; s += t
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def tot(xs):                                # plain left-to-right sum, as in the Rust check
    t = 0.0
    for x in xs: t += x
    return t
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
state = 88172645463325252
def uniform():                              # xorshift64: own random numbers
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7
    state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())   # Box-Muller
def row(label, v, d=2): print(f"{label:<44}{v:>16.{d}f}")
def hdd(ts): return tot(max(BASE - t, 0.0) for t in ts)
def cdd(ts): return tot(max(t - BASE, 0.0) for t in ts)
def pay(x): return TICK * min(max(x - K, 0.0), LIM)   # the capped call, in USD
def seasonal(d): return M - B * cos(2.0 * pi * (d - 76) / 365.0)   # day 0 = 1 November
def winter(shift, start=0, days=DAYS):      # one simulated season of daily mean temperatures
    lvl, a, ts = SD_W * gauss(), SD_A * gauss(), []
    for d in range(days):
        a = PHI * a + SD_A * sqrt(1.0 - PHI * PHI) * gauss()
        ts.append(seasonal(start + d) + shift + lvl + a)
    return ts
def g(m, s, k): z = (m - k) / s; return (m - k) * N(z) + s * phi(z)   # E[max(X - k, 0)], X normal
def capped_normal(m, s): return TICK * (g(m, s, K) - g(m, s, K + LIM))
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3.0 * (f(a) + f(b) + tot((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def capped_simpson(m, s):                   # road 3: the payoff against the bell curve, split at the kinks
    f = lambda x: pay(x) * phi((x - m) / s) / s
    return simpson(f, K, K + LIM) + simpson(f, K + LIM, max(m + 12.0 * s, K + LIM + 1.0))

# 1. one shoulder-season week by hand
week = [58.0, 62.0, 67.0, 71.0, 64.0, 55.0, 60.0]
print("week, daily mean F  " + " ".join(f"{t:4.0f}" for t in week))
print("week, HDD           " + " ".join(f"{max(BASE - t, 0):4.0f}" for t in week))
print("week, CDD           " + " ".join(f"{max(t - BASE, 0):4.0f}" for t in week))
row("week: HDD total", hdd(week)); row("week: CDD total", cdd(week)); row("week: sum of (65 - T)", tot(BASE - t for t in week))
print(f"one day: high 72, low 52, mean {(72 + 52) / 2:.1f}, HDD {max(BASE - (72 + 52) / 2, 0):.1f}")
# 2. thirty simulated past winters, 1996-97 to 2025-26, warming WARM F a year
idx, gap = [], 0.0
for y in range(30):
    ts = winter(WARM * (y - 30)); idx.append(hdd(ts))
    gap = max(gap, abs(hdd(ts) - cdd(ts) - tot(BASE - t for t in ts)))
row("identity: max |HDD - CDD - sum(65 - T)|", gap, 9)
ybar, xbar = 14.5, tot(idx) / 30
slope = tot((y - ybar) * (x - xbar) for y, x in enumerate(idx)) / tot((y - ybar) ** 2 for y in range(30))
det = [x + slope * (30 - y) for y, x in enumerate(idx)]   # each winter moved to the coming winter's climate
sy, syy, sx, sxy = tot(range(30)), tot(y * y for y in range(30)), tot(idx), tot(y * x for y, x in enumerate(idx))
dn = 30 * syy - sy * sy; b0, b1 = (sx * syy - sy * sxy) / dn, (30 * sxy - sy * sx) / dn   # road 2: line by Cramer's rule
print("chart, raw index  " + " ".join(f"{x:.0f}" for x in idx))
print("chart, trend line " + " ".join(f"{xbar + slope * (y - ybar):.0f}" for y in range(30)))
row("raw index: mean", xbar); row("trend: HDD per year, fitted", slope); row("trend: HDD per year, true -0.10 x 151", -WARM * DAYS)
mu = tot(det) / 30; sd = sqrt(tot((x - mu) ** 2 for x in det) / 29)
row("detrended: mean", mu); row("detrended: standard deviation", sd)
pays = sorted((x for x in det if x > K), reverse=True)
print("burn: paying winters " + " ".join(f"{x:.0f}" for x in pays))
print("burn: payoffs USD k  " + " ".join(f"{pay(x) / 1000:.1f}" for x in pays))
row("burn: sum of payoffs, USD k", tot(pay(x) for x in pays) / 1000, 1)
z1, z2 = (mu - K) / sd, (mu - K - LIM) / sd
print(f"fit: z {z1:.4f} {z2:.4f}, excess over 3,000 {g(mu, sd, K):.4f}, over 3,400 {g(mu, sd, K + LIM):.4f}")
print("detrended: winters above 3,000, 3,200, 3,400: " + ", ".join(str(sum(x > k for x in det)) for k in (K, 3200.0, K + LIM)))
# 3. the price, five roads
D = exp(-R * TW)
burn_p = [pay(x) for x in det]; burn = D * tot(burn_p) / 30
bsd = sqrt(tot((p - tot(burn_p) / 30) ** 2 for p in burn_p) / 29)
fit, fit_s = D * capped_normal(mu, sd), D * capped_simpson(mu, sd)
row("cap in degree-days, 2,000,000 / 5,000", LIM); row("discount e^(-0.03 x 0.5)", D, 6)
row("price 1 burn, 30 detrended winters", burn); row("price 2 normal fit, formula", fit)
row("price 3 normal fit, Simpson integral", fit_s)
mean_ex = tot(g(BASE, sqrt(SD_A ** 2 + SD_W ** 2), seasonal(d)) for d in range(DAYS))   # exact E[HDD]
var_ex = (DAYS * SD_W) ** 2 + SD_A ** 2 * tot(PHI ** abs(i - j) for i in range(DAYS) for j in range(DAYS))
true_mc = [hdd(winter(0.0)) for _ in range(20000)]
tm = tot(true_mc) / 20000; tp = [pay(x) for x in true_mc]; tpm = D * tot(tp) / 20000
tse = D * sqrt(tot((p - tpm / D) ** 2 for p in tp) / 19999 / 20000)
row("model: exact mean index", mean_ex); row("model: index sd, if no day is above 65F", sqrt(var_ex))
row("model: mean index, 20,000 winters", tm)
row("price 4 model, 20,000 fresh winters", tpm); row("price 4 standard error", tse)
p5 = D * capped_normal(mean_ex, sqrt(var_ex)); row("price 5 model moments, normal formula", p5)
row("burn: sd of payoff", bsd); row("seller's quote, burn + 0.2 sd", burn + 0.2 * D * bsd)
# 4. what breaks
raw_burn = D * tot(pay(x) for x in idx) / 30
row("wrong: burn on raw winters, no detrending", raw_burn)
row("wrong: no cap, normal fit", D * TICK * g(mu, sd, K)); row("wrong: no discount, burn", burn / D)
row("wrong: payoff at the mean winter", D * pay(mu))
# 5. carbon: an allowance costs nothing to keep and can be banked, so it carries
S, T, VOL = 70.0, 1.0, 0.5
F = S * exp(R * T)
row("EUA forward, 70 e^0.03", F, 4)
for n in (2, 3): row(f"EUA forward, {n} years", S * exp(R * n), 4)
row("carry trade profit if quoted 74.00", 74.0 - F, 4); row("reverse trade profit if quoted 70.00", F - 70.0, 4)
sims = []
for _ in range(50000):
    z = gauss(); m = (R - 0.5 * VOL * VOL) * T
    sims.append(0.5 * S * (exp(m + VOL * sqrt(T) * z) + exp(m - VOL * sqrt(T) * z)))
ms = tot(sims) / 50000; mse = sqrt(tot((v - ms) ** 2 for v in sims) / 49999 / 50000)
row("EUA forward, simulated average", ms, 4); row("EUA simulation standard error", mse, 4)
lo, hi, debt = 0.0, 10.0 * S, prod([exp(R / 12.0)] * 12, start=S)   # road 2: borrow S for a year, rolled monthly
for _ in range(100): lo, hi = (lo, (lo + hi) / 2) if (lo + hi) / 2 - debt > 0 else ((lo + hi) / 2, hi)
fb = (lo + hi) / 2; row("EUA forward, carry ledger break-even", fb, 4)   # buy, bank, deliver at the quote, repay
row("wrong: 70 x 1.03, simple interest", S * 1.03, 4)
row("clean spark: 0.37 t/MWh x forward", 0.37 * F, 2)
summer, cmean = winter(0.0, 181, 153), tot(g(seasonal(d), sqrt(SD_A ** 2 + SD_W ** 2), BASE) for d in range(181, 334))
print(f"summer CDD index, May-Sep: simulated {cdd(summer):.2f}, model mean {cmean:.2f}")   # CDD: 1 May to 30 September
# 6. try changing
row("try: strike 3,200, burn", D * tot(TICK * min(max(x - 3200.0, 0.0), LIM) for x in det) / 30)
row("try: cap 1 million, normal fit", D * TICK * (g(mu, sd, K) - g(mu, sd, K + 200.0)))
row("try: EUA rate 4 percent", S * exp(0.04), 4)
print("chart, index at expiry " + " ".join(f"{x:5.0f}" for x in range(2600, 3700, 100)))
print("chart, payoff USD k    " + " ".join(f"{pay(float(x)) / 1000:5.0f}" for x in range(2600, 3700, 100)))

assert abs(tot(BASE - t for t in week) - 18.0) < 1e-12 and abs(hdd(week) - cdd(week) - 18.0) < 1e-12
assert gap < 1e-9, "HDD - CDD must equal sum(65 - T) every winter"
assert abs(fit - fit_s) < 1e-3, "normal-fit formula against Simpson integral"
assert abs(tm - mean_ex) < 3.0 * sqrt(var_ex / 20000), "simulated mean index against the exact model mean"
assert abs(F - 72.1318) < 1e-4 and abs(fb - F) < 1e-9, "spec's forward 70 e^0.03 = 72.13, where the carry ledger breaks even"
assert abs(ms - F) < 3.0 * mse, "simulated EUA average within three standard errors of the carry forward"
assert abs(p5 - tpm) < 3.0 * tse, "model-moment normal price within three standard errors of the simulation"
assert raw_burn > burn, "undetrended history must overprice the call in a warming climate"
assert abs(slope - b1) < 1e-9 and abs(mu - (b0 + 30 * b1)) < 1e-6, "trend by Cramer's rule; moved mean = the line at 2026-27"
assert abs(sd - sqrt(tot((x - b0 - b1 * y) ** 2 for y, x in enumerate(idx)) / 29)) < 1e-6, "moved sd = sd of misses from the line"
assert abs(D - 0.985112) < 1e-6 and abs(burn - 9310.7e3 / 30 * 0.985112) < 2.0, "burn price against the hand table"
print("ALL CHECKS PASS")
