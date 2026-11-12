# Stock: EOQ, reorder point and the newsvendor -- the check behind the card.
# Standard library only.  The normal curve is built from its series, the quantile
# by bisection, random numbers by SplitMix64 (seed 2026).  Every number on the card is printed.
from math import sqrt, exp, log, cos, pi, ceil

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def Phi(x):                                                      # area left of x, by series
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        n += 1
        term = term * x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total
def quantile(p):                                                 # z with Phi(z) = p, by halving
    lo, hi = -8.0, 8.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if Phi(mid) < p: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def G(z): return phi(z) - z * (1.0 - Phi(z))                     # expected shortfall past z, in spreads

state = 2026
def rand():                                                      # SplitMix64, a uniform in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 1.0 / 18014398509481984.0
def normal(): return sqrt(-2.0 * log(rand())) * cos(2.0 * pi * rand())   # Box-Muller

# ---- 1. EOQ: butter for the croissants, at the warehouse ----
D, K, h = 5200.0, 125.0, 2.60            # cases a year; pounds per delivery; pounds per case per year
def C(Q): return K * D / Q + h * Q / 2.0
Qs = sqrt(2.0 * K * D / h)
best = min(range(1, 3001), key=C)        # road 2: try every whole order size
print(f"EOQ inputs: D {D:.0f} cases/yr (100/week, 52 weeks), K {K:.2f}, h {h:.2f}")
print(f"Q* {Qs:.4f}  C(Q*) {C(Qs):.4f}  holding {h*Qs/2:.4f}  ordering {K*D/Qs:.4f}")
print(f"orders/yr {D/Qs:.4f}  weeks between {52*Qs/D:.4f}  scan best {best}  C({best}) {C(best):.4f}")
print(f"hand: 2KD {2*K*D:.0f}  2KD/h {2*K*D/h:.0f}")
assert best == 707 and abs(C(best) - C(Qs)) < 0.01
assert abs(h * Qs / 2 - K * D / Qs) < 1e-9
for r in (1.2, 0.8):
    print(f"  Q = Q* x {r:.1f} = {r*Qs:.1f}: C {C(r*Qs):.2f}, extra {100*(C(r*Qs)/C(Qs)-1):.2f}%")
print(f"wrong: drop the 2 -> Q {sqrt(K*D/h):.1f}, C {C(sqrt(K*D/h)):.2f}, extra {100*(C(sqrt(K*D/h))/C(Qs)-1):.2f}%")
Qw = sqrt(2.0 * K * D / (h / 52.0))
print(f"wrong: h per week with D per year -> Q {Qw:.1f}, true cost {C(Qw):.2f}")
print("chart Q:", " ".join(f"{q}" for q in range(200, 1401, 100)))
print("chart holding:", " ".join(f"{h*q/2:.0f}" for q in range(200, 1401, 100)))
print("chart ordering:", " ".join(f"{K*D/q:.0f}" for q in range(200, 1401, 100)))
print("chart total:", " ".join(f"{C(q):.0f}" for q in range(200, 1401, 100)))

# ---- 2. Reorder point and safety stock ----
dw, sw, tL, alpha = 100.0, 20.0, 2, 0.95  # weekly mean, weekly spread, lead time in weeks, service level
muL, sL = dw * tL, sw * sqrt(tL)
z = quantile(alpha)
print(f"reorder inputs: {dw:.0f}/week, spread {sw:.0f}/week, lead time {tL} weeks, service level {alpha:.2f}")
s = z * sL
R = muL + s
short = sL * G(z)
print(f"hand: lead-time variance {sw*sw*tL:.0f}  G(z) {G(z):.4f}")
print(f"lead-time demand mean {muL:.0f} spread {sL:.4f}  z {z:.4f}  safety {s:.4f}  R {R:.4f} (order at {ceil(R)})")
print(f"stock-out chance {1-Phi(z):.4f}  short/cycle {short:.4f}  fill rate {1-short/Qs:.5f}  "
      f"stock-outs/yr {(1-Phi(z))*D/Qs:.4f} (one per {Qs/D/(1-Phi(z)):.2f} yr)")
assert abs(z - 1.6448536270) < 1e-9 and abs(Phi(z) - alpha) < 1e-12
n, outs, tot, sq, s1 = 200000, 0, 0.0, 0.0, 0.0
for _ in range(n):
    d = (dw + sw * normal()) + (dw + sw * normal())   # two separate weeks, added
    s1 += d; sq += d * d
    if d > R: outs += 1; tot += d - R
sd_sim = sqrt(sq / n - (s1 / n) ** 2)
print(f"sim {n} cycles: spread {sd_sim:.4f}  stock-out {outs/n:.4f}  short/cycle {tot/n:.4f}")
assert abs(outs / n - 0.05) < 3 * sqrt(0.05 * 0.95 / n)
assert abs(sd_sim - sL) < 0.2 and abs(tot / n - short) < 0.03
s1w = z * sw
print(f"wrong: one week's spread -> safety {s1w:.4f}, true stock-out {1-Phi(s1w/sL):.4f}")

# ---- 3. Newsvendor: croissants for tomorrow ----
p, c, v, mu, sg = 2.80, 0.70, 0.0, 120.0, 30.0
cu, co = p - c, c - v
f = cu / (cu + co)
print(f"newsvendor inputs: price {p:.2f} cost {c:.2f} leftover value {v:.2f} demand mean {mu:.0f} spread {sg:.0f}")
Qn = mu + sg * quantile(f)
def prof(Q, m=mu, sd=sg):                         # expected profit, from G
    zq = (Q - m) / sd
    sold = m - sd * G(zq)
    return p * sold + v * (Q - sold) - c * Q, sold
def prof_int(Q, n=2000):                          # road 2: Simpson over the demand curve, no G
    a, b = mu - 8 * sg, mu + 8 * sg
    hh = (b - a) / n
    def g(x): return (p * min(x, Q) + v * max(Q - x, 0.0) - c * Q) * phi((x - mu) / sg) / sg
    t = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * hh) for i in range(1, n))
    return t * hh / 3
bestn = max(range(0, 251), key=prof_int)
pr, sold = prof(140.0)
print(f"cu {cu:.2f} co {co:.2f} ratio {cu/co:.2f} fractile {f:.4f} z {quantile(f):.4f} Q* {Qn:.4f}  scan best {bestn}")
print(f"Q=140: profit {pr:.4f} (Simpson {prof_int(140.0):.4f})  sold {sold:.4f}  "
      f"left {140-sold:.4f}  lost sales {mu-sold:.4f}")
print(f"marginal at Q*: P(D>Q)*cu {(1-Phi((Qn-mu)/sg))*cu:.4f}  P(D<=Q)*co {Phi((Qn-mu)/sg)*co:.4f}")
print(f"hand: z*spread {sg*quantile(f):.4f}  G {G((140-mu)/sg):.4f}  revenue {p*sold:.4f}  baking {c*140:.2f}")
assert bestn == 140 and abs(prof_int(140.0) - pr) < 1e-6
sims = []
for _ in range(n):
    d = mu + sg * normal()
    sims.append(p * min(d, 140.0) + v * max(140.0 - d, 0.0) - c * 140.0)
m = sum(sims) / n
se = sqrt(sum((x - m) ** 2 for x in sims) / (n - 1) / n)
print(f"sim {n} days at Q=140: profit {m:.4f}  standard error {se:.4f}")
assert abs(m - pr) < 4 * se
print(f"wrong: bake the average 120 -> profit {prof(120.0)[0]:.4f}, gap {pr-prof(120.0)[0]:.4f}/day")
Qf = mu + sg * quantile(co / (cu + co))
print(f"wrong: fractile flipped to {co/(cu+co):.4f} -> Q {Qf:.4f}, profit {prof(Qf)[0]:.4f}")
def two(Q): return 0.5 * (p * min(80, Q) - c * Q) + 0.5 * (p * min(160, Q) - c * Q)
Qb = round(mu + 40.0 * quantile(f))
best2 = max(range(0, 251), key=two)
print(f"two-humped demand (80 or 160): bell-curve fit (mean 120, spread 40) Q {Qb} profit {two(Qb):.2f}; "
      f"true best Q {best2} profit {two(best2):.2f}")
assert best2 == 160 and Qb == 147
print("chart Q:", " ".join(f"{q}" for q in range(80, 201, 10)))
print("chart profit:", " ".join(f"{prof(float(q))[0]:.2f}" for q in range(80, 201, 10)))

# ---- try changing ----
v2 = 0.35
print(f"try: leftovers sold at {v2:.2f} -> fractile {cu/(cu+c-v2):.4f}, Q {mu+sg*quantile(cu/(cu+c-v2)):.4f}")
print(f"try: spread 15 -> Q {mu+15*quantile(f):.4f};  K 250 -> Q* {sqrt(2*250*D/h):.4f}")
print(f"try: service 0.99 -> z {quantile(0.99):.4f}, R {muL+quantile(0.99)*sL:.4f}")
print("ALL CHECKS PASS")
