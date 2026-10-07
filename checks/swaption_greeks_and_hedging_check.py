# Swaption Greeks and the forward-swap hedge -- the check behind the card.  Standard library only.
# Normal CDF, integrator and random numbers are written here; nothing imported knows a swaption.
from math import exp, log, sqrt, pi, cos

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height at x
def N(x):                                                       # bell-curve area left of x, by its series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, k = x, x, 1
    while abs(t) > 1e-17 * abs(s):
        t *= x * x / (2 * k + 1); s += t; k += 1
    return 0.5 + phi(x) * s

Y, K, SIG, TAU, NOT = 0.044, 0.0435, 0.30, 1.0, 1e7   # flat 4.4% curve, strike 4.35%, 30% vol, 1y expiry, $10m
BP = 1e-4

def curve(y, tau):                     # annuity and forward swap rate of the 5-year swap starting at tau
    D = lambda t: (1.0 + y) ** -t
    A = sum(D(tau + i) for i in range(1, 6))
    return A, (D(tau) - D(tau + 5)) / A

def black(F, s, tau):                  # swaption value per unit of annuity, and d1, d2
    v = s * sqrt(tau); d1 = (log(F / K) + 0.5 * v * v) / v
    return F * N(d1) - K * N(d1 - v), d1, d1 - v

def V(y, tau=TAU, s=SIG):              # dollars: full revaluation off the curve
    A, F = curve(y, tau); return NOT * A * black(F, s, tau)[0]

def swap(y, F0, tau=TAU):              # dollars: payer forward swap struck at F0, $10m
    A, F = curve(y, tau); return NOT * A * (F - F0)

def B_int(F, s=SIG, tau=TAU, n=4000): # road 2: Simpson's rule over the bell curve; no d1, no d2
    g = lambda z: F * exp(-0.5 * s * s * tau + s * sqrt(tau) * z) - K
    lo, hi = -10.0, 10.0                                # exercise boundary by bisection
    for _ in range(200):
        mid = 0.5 * (lo + hi); lo, hi = (lo, mid) if g(mid) > 0 else (mid, hi)
    a, h = lo, (10.0 - lo) / n
    tot = sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(a + i * h) * phi(a + i * h) for i in range(n + 1))
    return tot * h / 3.0

def dh(y, tau):                        # full hedge ratio: N(d1) plus the annuity's own sensitivity
    A, F = curve(y, tau); b, d1, _ = black(F, SIG, tau)
    dA = -sum((tau + i) * (1.0 + y) ** (-(tau + i) - 1.0) for i in range(1, 6))
    return N(d1) + dA / A * b

def out(label, *vals, fmt="{:>14.6f}"): print(f"{label:<34}" + "".join(fmt.format(v) for v in vals))

A, F = curve(Y, TAU); B, d1, d2 = black(F, SIG, TAU)
fwd = [((1 + Y) ** -(TAU + i - 1) / (1 + Y) ** -(TAU + i) - 1.0) for i in range(1, 6)]
F_avg = sum((1 + Y) ** -(TAU + i) * fwd[i - 1] for i in range(1, 6)) / A
Bi = B_int(F)
out("annuity A, forward F (ratio)", A, F); out("forward F (weighted forwards)", F_avg)
out("d1, d2", d1, d2); out("N(d1), N(d2)", N(d1), N(d2))
out("1 Black price, dollars", NOT * A * B, fmt="{:>14.2f}"); out("2 Simpson price, dollars", NOT * A * Bi, fmt="{:>14.2f}")
out("price, percent of notional", 100 * A * B); out("value per unit of annuity B", B, fmt="{:>14.7f}")
# ---- delta: in forward swaps, then with the annuity moving too ----
e = 1e-6
nd1_int = (B_int(F + e) - B_int(F - e)) / (2 * e)
dA = -sum((TAU + i) * (1 + Y) ** (-(TAU + i) - 1) for i in range(1, 6))
h_cf = dh(Y, TAU)
h_fd = (V(Y + BP) - V(Y - BP)) / (swap(Y + BP, F) - swap(Y - BP, F))
out("N(d1) formula, by integral", N(d1), nd1_int)
out("annuity slope A', A'/A, (A'/A) B", dA, dA / A, dA / A * B)
out("hedge ratio: formula, bumped curve", h_cf, h_fd)
out("hedge: forward swap notional, $", NOT * h_cf, fmt="{:>14.2f}")
out("swaption DV01, swap DV01 ($/bp)", (V(Y + BP) - V(Y - BP)) / 2, (swap(Y + BP, F) - swap(Y - BP, F)) / 2, fmt="{:>14.2f}")
# ---- gamma, vega, theta ----
g_cf = phi(d1) / (F * SIG * sqrt(TAU)) * 10 * BP
g_int = (B_int(F + 1e-5) - 2 * Bi + B_int(F - 1e-5)) / 1e-10 * 10 * BP
out("gamma: N(d1) change per 10bp, x2", g_cf, g_int)
out("hedge ratio at -10bp, +10bp", dh(Y - 10 * BP, TAU), dh(Y + 10 * BP, TAU))
vg_cf = NOT * A * F * phi(d1) * sqrt(TAU) * 0.01
vg_int = NOT * A * (B_int(F, SIG + 1e-4) - B_int(F, SIG - 1e-4)) / 2e-4 * 0.01
out("vega per vol point: formula, integral", vg_cf, vg_int, fmt="{:>14.2f}")
decay = -NOT * A * F * phi(d1) * SIG / (2 * sqrt(TAU)) / 365
carry = V(Y) * log(1 + Y) / 365
th_fd = (V(Y, TAU - 1e-4) - V(Y, TAU + 1e-4)) / 2e-4 / 365
out("theta/day: decay, carry, sum", decay, carry, decay + carry, fmt="{:>14.2f}")
out("theta/day: rolled date; one day", th_fd, V(Y, TAU - 1 / 365) - V(Y), fmt="{:>14.2f}")
# ---- the hedge at work: short h forward swaps against the long payer ----
print("move bp   swaption P&L      hedge P&L    net P&L   half-gamma guess")
gam_d = 0.5 * NOT * A * phi(d1) / (F * SIG * sqrt(TAU))
chart_u, chart_n = [], []
for bp in range(-50, 51, 10):
    dy = bp * BP; pv = V(Y + dy) - V(Y); hv = h_cf * swap(Y + dy, F) + 0.0
    chart_u.append(pv / 1000); chart_n.append((pv - hv) / 1000)
    print(f"{bp:>7d}{pv:>15.2f}{0.0 - hv:>15.2f}{pv - hv:>11.2f}{gam_d * dy * dy:>12.2f}")
out("chart, $000 unhedged", *chart_u, fmt="{:>8.2f}"); out("chart, $000 hedged", *chart_n, fmt="{:>8.2f}")
# ---- what breaks ----
A5 = sum((1 + Y) ** -i for i in range(1, 6))
spot = lambda dy: NOT * sum((1 + Y + dy) ** -i for i in range(1, 6)) * dy   # spot 5y payer, at market today
for bp in (-30, 30):
    dy = bp * BP; pv = V(Y + dy) - V(Y)
    out(f"wrong at {bp:+d}bp: N(d1) hedge; spot swap", pv - N(d1) * swap(Y + dy, F), pv - h_cf * spot(dy), fmt="{:>14.2f}")
out("wrong: N(d1) hedge, bet in $ per bp", (N(d1) - h_cf) * NOT * A * BP, fmt="{:>14.2f}")
out("wrong: theta without carry", decay, fmt="{:>14.2f}")
out("wrong: price with no annuity", NOT * B, fmt="{:>14.2f}")
# ---- how the hedge moves ----
grid = [0.039 + 0.001 * i for i in range(11)]
out("chart, forward rate %", *[100 * g for g in grid], fmt="{:>7.1f}")
out("chart, hedge ratio 12m left", *[dh(g, 1.0) for g in grid], fmt="{:>7.2f}")
out("chart, hedge ratio 3m left", *[dh(g, 0.25) for g in grid], fmt="{:>7.2f}")
for m in (12, 6, 3, 1):
    t = m / 12; tl = (V(Y, t - 1e-4) - V(Y, t + 1e-4)) / 2e-4 / 365
    out(f"bars, {m:>2} months left: value, theta", V(Y, t), tl, fmt="{:>14.2f}")
# ---- road 4: replicate by hedging, counted in annuity units (F has no drift there) ----
st = [0x2545F4914F6CDD1D]
def U():
    st[0] = (st[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF; z = st[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
sim = []
for steps in (52, 260):
    dt, errs = TAU / steps, []
    for p in range(2000):
        f, cash = F, B
        for i in range(steps):
            v = SIG * sqrt(TAU - i * dt)
            dlt = N((log(f / K) + 0.5 * v * v) / v)
            fn = f * exp(-0.5 * SIG * SIG * dt + SIG * sqrt(dt) * sqrt(-2 * log(U())) * cos(2 * pi * U()))
            cash += dlt * (fn - f); f = fn
        errs.append(NOT * A * (cash - max(f - K, 0.0)))
    m = sum(errs) / len(errs); sd = sqrt(sum((x - m) ** 2 for x in errs) / (len(errs) - 1))
    sim.append((m, sd)); out(f"hedge error, {steps} rebalances: mean, sd", m, sd, fmt="{:>14.2f}")
# ---- try changing ----
b20, d20, _ = black(F, 0.20, TAU)
out("try: vol 20%: price; hedge ratio", NOT * A * b20, N(d20) + dA / A * b20, fmt="{:>14.4f}")
out("try: 3 months left: hedge ratio", dh(Y, 0.25))
out("try: strike 4.40%: hedge ratio", N(0.15) + dA / A * (F * N(0.15) - F * N(-0.15)))
assert abs(F - F_avg) < 1e-12,                            "forward: ratio vs weighted forwards"
assert abs(Bi - B) < 1e-9,                                "Black formula vs Simpson integral"
assert abs(nd1_int - N(d1)) < 1e-6,                       "delta in swaps: N(d1) vs bumped integral"
assert abs(h_cf - h_fd) < 1e-5,                           "hedge ratio: formula vs full curve bump"
assert abs(g_cf - g_int) < 1e-5,                          "gamma: formula vs integral"
assert abs(vg_cf - vg_int) < 1e-3,                        "vega: formula vs integral"
assert abs((decay + carry) - th_fd) < 1e-3,               "theta formula vs rolled date"
assert abs(sim[1][0]) < 3 * sim[1][1] / sqrt(2000),       "hedging costs the premium on average"
assert sim[1][1] < 0.6 * sim[0][1],                       "five times the rebalancing, under 0.6 the spread"
print("ALL CHECKS PASS")
