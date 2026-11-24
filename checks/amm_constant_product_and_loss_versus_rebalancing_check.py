# Constant-product pool and loss-versus-rebalancing: the check behind the card.
# Standard library only. Roads: closed forms; the arbitrageur's best trade found
# by ternary search; gamma by finite differences; the daily loss by Simpson's
# rule over the bell curve; a simulated year of daily arbitrage.
import math

x0, y0, P0, sig = 10.0, 600000.0, 60000.0, 0.80
k = x0 * y0
V = lambda P: 2 * math.sqrt(k * P)            # pool value once arbitrage sets its price to P
H = lambda P: x0 * P + y0                     # value of simply holding the deposit
def lvr_step(v, R): return v / 2 * (math.sqrt(R) - 1) ** 2   # one jump of ratio R
print(f"pool: k = {k:.0f}, price {P0:.0f}, value {V(P0):.0f}")

# ---- road 1 against road 2: holdings after the move to 66,000 ----
P1 = 66000.0
x1, y1 = math.sqrt(k / P1), math.sqrt(k * P1)
profit = lambda d: d * P1 - (k / (x0 - d) - y0)   # arbitrageur buys d BTC, pays the pool
lo, hi = 0.0, x0 - 1e-9
for _ in range(200):
    a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    if profit(a) < profit(b): lo = a
    else: hi = b
d = (lo + hi) / 2
print(f"after 66000: formula x = {x1:.4f} BTC, y = {y1:.0f} USDC")
print(f"after 66000: arbitrage search x = {x0 - d:.4f} BTC, pays {k / (x0 - d) - y0:.0f} USDC for {d:.4f} BTC")
print(f"arbitrageur's average price {(k / (x0 - d) - y0) / d:.0f}, profit {profit(d):.0f}")
assert abs((x0 - d) - x1) < 1e-6 and abs(profit(d) - lvr_step(V(P0), P1 / P0)) < 1e-6
v1, h1 = V(P1), H(P1)
print(f"pool value {v1:.0f}, held {h1:.0f}, loss {h1 - v1:.0f} = {100 * (1 - v1 / h1):.3f}%")
R = P1 / P0
assert abs((1 - v1 / h1) - (1 - 2 * math.sqrt(R) / (1 + R))) < 1e-12   # ratio form
assert abs(v1 - (x1 * P1 + y1)) < 1e-6 and v1 < h1                        # AM-GM

# ---- delta and gamma: derivative formulas against finite differences ----
h = 1.0
dfd = (V(P0 + h) - V(P0 - h)) / (2 * h)
gfd = (V(P0 + h) - 2 * V(P0) + V(P0 - h)) / h ** 2
g = -x0 / (2 * P0)
print(f"delta {dfd:.6f} BTC (holdings {x0:.6f}); gamma {gfd:.4e} per USD (formula {g:.4e})")
assert abs(dfd - x0) < 1e-6 and abs(gfd - g) < 1e-8
rent = 0.5 * abs(g) * sig ** 2 * P0 ** 2
print(f"rent 1/2|gamma|sigma^2 P^2 = {rent:.0f} USD a year = {100 * rent / V(P0):.2f}% of value, {rent / 365:.2f} a day")
assert abs(rent / V(P0) - sig ** 2 / 8) < 1e-12
for s in (0.4, 0.8, 1.2):
    print(f"sigma {s:.0%}: LVR rate {100 * s * s / 8:.2f}% a year = {s * s / 8 * V(P0):.0f} USD")
print(f"fee break-even at 0.30%: volume {rent / 0.003:.0f} a year, {rent / 0.003 / 365:.0f} a day")

# ---- one day's expected loss: Simpson's rule over the bell curve ----
dt = 1 / 365
f = lambda z: (math.sqrt(math.exp(-sig**2 * dt / 2 + sig * math.sqrt(dt) * z)) - 1) ** 2 \
    * math.exp(-z * z / 2) / math.sqrt(2 * math.pi)
n, A = 4000, 10.0
w = 2 * A / n
q = sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(-A + i * w) for i in range(n + 1)) * w / 3
print(f"day: Simpson E[(sqrtR-1)^2] = {q:.8e}, exact {2 * (1 - math.exp(-sig**2 * dt / 8)):.8e}, sigma^2 dt/4 = {sig**2 * dt / 4:.8e}")
assert abs(q - 2 * (1 - math.exp(-sig**2 * dt / 8))) < 1e-12
print(f"day one expected LVR {V(P0) / 2 * q:.2f} USD")
exact = V(P0) * (1 - math.exp(-sig ** 2 / 8))
print(f"one year expected LVR {exact:.0f} (rate times starting value {sig**2 / 8 * V(P0):.0f})")

# ---- round trip 60,000 -> 66,000 -> 60,000 ----
up, dn = lvr_step(V(P0), R), lvr_step(V(P1), P0 / P1)
print(f"round trip: up {up:.0f}, down {dn:.0f}, LVR {up + dn:.0f}; held-vs-pool loss at the end {H(P0) - V(P0):.0f}")
reb = (x0 - x1) * P1 - (x0 - x1) * P0            # rebalancer sells at 66,000, buys back at 60,000
assert abs(reb - (up + dn)) < 1e-6

# ---- simulated year: arbitrage every step, zero drift ----
st = [88172645463325252]
def unif():
    s = st[0]; s ^= (s << 13) & 0xFFFFFFFFFFFFFFFF; s ^= s >> 7; s ^= (s << 17) & 0xFFFFFFFFFFFFFFFF
    st[0] = s; return ((s >> 11) + 0.5) / 9007199254740992.0
def year(steps, paths, marks=1):   # mean LVR and s.e.; mean LVR and IL at `marks` even times; IL s.e.
    tot, tot2, il2 = 0.0, 0.0, 0.0
    lv, il = [0.0] * marks, [0.0] * marks
    e, every = sig * math.sqrt(1 / steps), steps // marks
    for _ in range(paths):
        p, loss = P0, 0.0
        for i in range(1, steps + 1):
            z = math.sqrt(-2 * math.log(unif())) * math.cos(2 * math.pi * unif())
            pn = p * math.exp(-e * e / 2 + e * z)
            loss += math.sqrt(k / p) * (pn - p) - (V(pn) - V(p))   # rebalancer minus pool
            p = pn
            if i % every == 0:                                     # IL: held minus pool, unhedged
                lv[i // every - 1] += loss / paths; il[i // every - 1] += (H(p) - V(p)) / paths
        tot += loss; tot2 += loss * loss; il2 += (H(p) - V(p)) ** 2
    m = tot / paths
    return m, math.sqrt((tot2 / paths - m * m) / paths), lv, il, math.sqrt((il2 / paths - il[-1] ** 2) / paths)
m, se, lv, il, seil = year(365, 2000, 5)
print(f"simulated year, daily: mean LVR {m:.0f} (s.e. {se:.0f}), exact {exact:.0f}")
print(f"simulated year, daily: mean impermanent loss at the end {il[-1]:.0f} (s.e. {seil:.0f})")
assert abs(m - exact) < 4 * se
assert abs(il[-1] - exact) < 4 * seil                      # unhedged LP: on average IL equals LVR
mw, sew = year(52, 2000)[:2]
print(f"simulated year, weekly: mean LVR {mw:.0f} (s.e. {sew:.0f})")
assert abs(mw - exact) < 4 * sew

# ---- what breaks, try changing, chart ----
print(f"breaks: sigma^2/2 -> {sig**2 / 2 * V(P0):.0f}; sigma^2/4 -> {sig**2 / 4 * V(P0):.0f}; sigma/8 -> {sig / 8 * V(P0):.0f}")
print(f"try: jump to 120000: IL {100 * (1 - V(120000) / H(120000)):.2f}%, one-jump LVR {lvr_step(V(P0), 2):.0f}")
print(f"try: jump to 30000: IL {100 * (1 - V(30000) / H(30000)):.2f}%, one-jump LVR {lvr_step(V(P0), 0.5):.0f}")
ps = range(30000, 120001, 10000)
print("chart pool (thousand USD):", ", ".join(f"{V(p) / 1000:.0f}" for p in ps))
print("chart held (thousand USD):", ", ".join(f"{H(p) / 1000:.0f}" for p in ps))
form = [V(P0) * (1 - math.exp(-sig ** 2 * (j + 1) / 5 / 8)) for j in range(5)]
for name, ys in (("formula", form), ("mean LVR", lv), ("mean IL", il)):  # year in fifths
    print(f"chart {name} (thousand USD): 0.0, " + ", ".join(f"{y / 1000:.1f}" for y in ys))
print("ALL CHECKS PASS")
