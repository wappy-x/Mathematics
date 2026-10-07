# Risk limits and the appetite behind them -- the check behind the card.
# Standard library only.  Every number quoted on the card is printed here.
# Book: long Acme shares, each hedged by one sold one-year call (house market).  Roads: Greeks
# by formula and by bumping; VaR by the exact quantile and by 40,000 simulated days; largest size
# by the min rule and by a scan; days to the stop by exact count, simulation and square law.
from math import sqrt, exp, log, cos, pi
S0, K, r, q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
DT = 1.0 / 252.0                                      # one trading day, in years
def N(x):                                             # normal CDF, Marsaglia's positive series
    if x < 0: return 1.0 - N(-x)
    t, s, i = x, x, 1
    while t > 1e-17 * s:
        t *= x * x / (2 * i + 1); s += t; i += 1
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def call(S, sig):
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T)), d1
def call_int(S, sig, n=4000):                         # road 2: Simpson on the discounted payoff
    g = lambda z: max(S * exp((r - q - 0.5 * sig * sig) * T + sig * sqrt(T) * z) - K, 0.0) * phi(z)
    return exp(-r * T) * 20.0 / n / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(-10.0 + 20.0 * i / n) for i in range(n + 1))
def unit(S, sig): return S - call(S, sig)[0]          # one share minus one sold call
def delta_pct(S, sig):                                # $ per 1% spot move, per unit, formula
    return (1.0 - exp(-q * T) * N(call(S, sig)[1])) * S * 0.01
def vega_pt(S, sig):                                  # $ per vol point, per unit (short call)
    return -S * exp(-q * T) * phi(call(S, sig)[1]) * sqrt(T) * 0.01
def z_low(p):                                         # N(z) = p by bisection
    lo, hi = -10.0, 10.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if N(mid) < p: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

Z01 = z_low(0.01)
def var_exact(S, sig):                                # unit value rises with S, so the 1% spot
    s1 = S * exp(-0.5 * sig * sig * DT + Z01 * sig * sqrt(DT))   # quantile gives the 1% loss
    return unit(S, sig) - unit(s1, sig)

class Rng:                                            # xorshift64 and Box-Muller
    def __init__(self, seed): self.x = seed
    def u(self):
        x = self.x
        x ^= (x << 13) & 0xFFFFFFFFFFFFFFFF; x ^= x >> 7; x ^= (x << 17) & 0xFFFFFFFFFFFFFFFF
        self.x = x
        return ((x >> 11) + 0.5) / 2.0 ** 53
    def z(self): return sqrt(-2.0 * log(self.u())) * cos(2.0 * pi * self.u())

def var_mc(S, sig, n, rng):
    v0 = unit(S, sig)
    losses = sorted(v0 - unit(S * exp(-0.5 * sig * sig * DT + sig * sqrt(DT) * rng.z()), sig) for _ in range(n))
    return losses[int(0.99 * n) - 1]

# ---- the appetite, and the caps derived from it ----
CAP, STOP_FRAC, PATIENCE = 50e6, 0.03, 100            # capital, stop as share of capital, days
L = STOP_FRAC * CAP
caps = {"notional": 0.40 * CAP, "delta": L / 2 / 20, "vega": L / 2 / 15, "stress": L,
        "VaR": round(-Z01 * L / sqrt(PATIENCE), -4)}

# ---- per-unit measures at today's market ----
c0, h = call(S0, SIG)[0], 1e-4
d_bump = (unit(S0 + h, SIG) - unit(S0 - h, SIG)) / (2 * h) * S0 * 0.01
v_bump = (unit(S0, SIG + h) - unit(S0, SIG - h)) / (2 * h) * 0.01
stress = unit(S0, SIG) - unit(80.0, 0.35)             # loss per unit, -20% spot, +15 vol points
per = {"notional": S0 + K, "delta": delta_pct(S0, SIG), "vega": abs(vega_pt(S0, SIG)),
       "stress": stress, "VaR": var_exact(S0, SIG)}
v_mc = var_mc(S0, SIG, 40000, Rng(88172645463325252))
stress_int = (S0 - call_int(S0, SIG)) - (80.0 - call_int(80.0, 0.35))
bind = {k: caps[k] / per[k] for k in caps}
qstar = min(bind.values())
scan = 0                                              # road 2: grow the book one unit at a time
while all((scan + 1) * per[k] <= caps[k] for k in caps): scan += 1

def show(name, v, fmt="{:>16.4f}"): print(f"{name:<40}" + fmt.format(v))
show("house call C(100, 20%)", c0); show("stop L = 3% of capital", L, "{:>16.2f}")
show("z, 1% point of the bell curve", Z01); show("VaR cap before rounding, z L / 10", -Z01 * L / sqrt(PATIENCE), "{:>16.2f}")
show("half the stop, L/2", L / 2, "{:>16.2f}")
for k in caps: show(f"cap {k}", caps[k], "{:>16.2f}")
show("unit delta $/1%: formula, bump", per["delta"], "{:>16.6f}" + f"{d_bump:>12.6f}")
show("unit vega $/pt: formula, bump", vega_pt(S0, SIG), "{:>16.6f}" + f"{v_bump:>12.6f}")
show("unit stress loss: formula, integral", stress, "{:>16.4f}" + f"{stress_int:>12.4f}"); show("call after shock C(80, 35%)", call(80.0, 0.35)[0])
show("unit VaR99: exact, 40,000 days", per["VaR"], "{:>16.4f}" + f"{v_mc:>12.4f}")
for k in caps: show(f"binding size, {k}", bind[k], "{:>16.1f}")
show("largest size: min rule, scan", qstar, "{:>16.1f}" + f"{scan:>12d}")

# ---- scenario A: a proposed trade from 75,000 to 95,000 units; scenario B: the shock day ----
Q0, QNEW, DD0 = 75000, 95000, 300000.0
post = {"notional": 80.0 + K, "delta": delta_pct(80.0, 0.35), "vega": abs(vega_pt(80.0, 0.35)),
        "stress": unit(80.0, 0.35) - unit(64.0, 0.50), "VaR": var_exact(80.0, 0.35)}
print("utilisation %          today   proposed   after shock")
for k in caps:
    print(f"  {k:<18}{100 * Q0 * per[k] / caps[k]:>9.2f}{100 * QNEW * per[k] / caps[k]:>11.2f}{100 * Q0 * post[k] / caps[k]:>14.2f}")
loss_b = Q0 * stress
show("shock loss, drawdown after", loss_b, "{:>16.2f}" + f"{DD0 + loss_b:>12.2f}")
show("stop utilisation %: before, after", 100 * DD0 / L, "{:>16.2f}" + f"{100 * (DD0 + loss_b) / L:>12.2f}")
show("stop left L - D; stress use of it %", L - DD0, "{:>16.2f}" + f"{100 * loss_b / (L - DD0):>12.2f}")
show("post-shock unit delta $/1%", post["delta"]); show("post-shock unit VaR99", post["VaR"])

# ---- what breaks ----
taylor = -(per["delta"] * -20 + vega_pt(S0, SIG) * 15)   # delta and vega only
show("wrong: stress by delta+vega, per unit", taylor); show("  its binding size", L / taylor, "{:>16.1f}")
show("wrong: net notional per unit", S0 - K, "{:>16.2f}")
show("wrong: patience linear, VaR cap", -Z01 * L / PATIENCE, "{:>16.2f}")
path = [600000.0, -1700000.0]; eq = [0.0]; [eq.append(eq[-1] + p) for p in path]
show("path: loss from start, from peak", -eq[-1], "{:>16.2f}" + f"{max(eq) - eq[-1]:>12.2f}")

# ---- days to the stop: coin walk, simulation, Brownian square law ----
def coin_exact(n): return n * (n + 1)
def coin_mc(n, paths, rng):
    tot = 0
    for _ in range(paths):
        d, t = 0, 0
        while d < n:
            t += 1; d = max(0, d - 1) if rng.u() < 0.5 else d + 1
        tot += t
    return tot / paths
mc10 = coin_mc(10, 20000, Rng(2463534242))
sd_now = Q0 * per["VaR"] / -Z01                      # daily sd implied by today's VaR
show("L/sigma = 10: coin walk, exact days", coin_exact(10), "{:>16.0f}")
show("L/sigma = 10: coin walk, 20,000 walks", mc10, "{:>16.2f}")
show("L/sigma = 10: Brownian (L/sigma)^2", 10 ** 2, "{:>16.0f}")
show("book today: VaR99", Q0 * per["VaR"], "{:>16.2f}"); show("book today: daily sd = VaR/2.3263", sd_now, "{:>16.2f}")
show("book today: L/sigma, Brownian days", L / sd_now, "{:>16.2f}" + f"{(L / sd_now) ** 2:>12.0f}")
print("chart, size (thousand units)  " + " ".join(f"{s:>7d}" for s in range(0, 121, 20)))
for k in caps:
    print(f"chart, {k:<23}" + " ".join(f"{100 * s * 1000 * per[k] / caps[k]:>7.2f}" for s in range(0, 121, 20)))
print("chart, L/sigma               " + " ".join(f"{n:>5d}" for n in range(2, 13, 2)))
print("chart, coin n(n+1)           " + " ".join(f"{coin_exact(n):>5d}" for n in range(2, 13, 2)))
print("chart, Brownian n^2          " + " ".join(f"{n * n:>5d}" for n in range(2, 13, 2)))

assert abs(c0 - 9.227005508154) < 1e-9, "house call from another card"
assert abs(d_bump - per["delta"]) < 1e-6, "delta: bump vs formula"
assert abs(v_bump - vega_pt(S0, SIG)) < 1e-6, "vega: bump vs formula"
assert abs(stress_int - stress) < 1e-4, "stress: integral vs formula"
assert min(bind, key=bind.get) == "delta", "delta binds first"
assert DD0 + loss_b > L, "the shock day breaches the stop"
assert abs(v_mc - per["VaR"]) < 0.03 * per["VaR"], "VaR: simulation vs exact quantile"
assert scan == int(qstar), "largest size: scan vs min rule"
assert abs(mc10 - coin_exact(10)) < 3.0, "days to stop: simulation vs exact count"
print("ALL CHECKS PASS")
