# Knock-out and knock-in options -- the check behind the card.  Standard library only.
# House market: S = K = 100, r = 5%, q = 2%, sigma = 20%, one year; barrier H = 80 below.
# Four roads to the down-and-out call: the reflection formula, a Simpson integral over the
# surviving-path density, a finite-difference grid that knows nothing of mirrors, and a
# 10,000-path daily simulation.  The normal CDF, integrator, solver and random numbers are here.
from math import log, exp, sqrt, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def N(x):                                                          # bell-curve area, by its power series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, s, k = x, x, 0
    while k < 400 and abs(term) > 1e-17 * abs(s):
        k += 1; term *= x * x / (2 * k + 1); s += term
    return 0.5 + phi(x) * s

def call(S, K, r, q, v, T):                                        # Black-Scholes call
    d1 = (log(S / K) + (r - q + 0.5 * v * v) * T) / (v * sqrt(T)); d2 = d1 - v * sqrt(T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)

def weight(S, H, r, q, v): return (H / S) ** (2.0 * (r - q - 0.5 * v * v) / (v * v))
def d_in(S, K, H, r, q, v, T): return weight(S, H, r, q, v) * call(H * H / S, K, r, q, v, T)
def d_out(S, K, H, r, q, v, T): return call(S, K, r, q, v, T) - d_in(S, K, H, r, q, v, T)

def simpson(f, a, b, n=20000):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def by_density(S, K, H, r, q, v, T):
    # Road 2: average the payoff over where log-price ends, split into untouched and touched paths.
    nu, sd, b = r - q - 0.5 * v * v, v * sqrt(T), log(H / S)
    p = lambda x: phi((x - nu * T) / sd) / sd                       # free density of x = ln(S_T / S)
    pay = lambda x: S * exp(x) - K
    lo, hi = log(K / S), log(K / S) + 12.0 * sd
    touched = simpson(lambda x: pay(x) * exp(2 * nu * b / (v * v)) * p(x - 2 * b), lo, hi)
    alive = simpson(lambda x: pay(x) * p(x), lo, hi) - touched
    return exp(-r * T) * alive, exp(-r * T) * touched

def by_grid(S, K, H, r, q, v, T, below=50, M=400, steps=500):
    # Road 3: the pricing equation on a grid in ln S, value held at 0 on the barrier.  No mirror.
    dx = log(S / H) / below; dt = T / steps; nu = r - q - 0.5 * v * v
    xs = [log(H) + i * dx for i in range(M + 1)]
    V = [max(exp(x) - K, 0.0) for x in xs]
    a = 0.5 * v * v / dx ** 2 - 0.5 * nu / dx; c = 0.5 * v * v / dx ** 2 + 0.5 * nu / dx; bb = -v * v / dx ** 2 - r
    for n in range(steps):
        th = 1.0 if n < 4 else 0.5                                  # four plain steps smooth the kink
        tau = (n + 1) * dt
        rhs = [V[i] + (1 - th) * dt * (a * V[i - 1] + bb * V[i] + c * V[i + 1]) for i in range(1, M)]
        top = exp(xs[M] - q * tau) - K * exp(-r * tau)
        rhs[-1] += th * dt * c * top
        lo_, di_, up_ = -th * dt * a, 1 - th * dt * bb, -th * dt * c
        cp, dp = [0.0] * (M - 1), [0.0] * (M - 1)                   # Thomas algorithm
        for i in range(M - 1):
            den = di_ - (lo_ * cp[i - 1] if i else 0.0)
            cp[i] = up_ / den; dp[i] = (rhs[i] - (lo_ * dp[i - 1] if i else 0.0)) / den
        for i in range(M - 2, -1, -1):
            V[i + 1] = dp[i] - (cp[i] * V[i + 2] if i < M - 2 else 0.0)
        V[0], V[M] = 0.0, top
    return V[below], (V[below + 1] - V[below - 1]) / (exp(xs[below + 1]) - exp(xs[below - 1]))

def by_simulation(S, K, H, r, q, v, T, paths=10000, days=252, seed=20260924):
    # Road 4: simulate daily closes.  Count a knock-out at a close below H (the daily contract),
    # and separately weight each path by the chance it slipped under H between closes (continuous).
    state = [seed]
    def unif():                                                     # splitmix64, written out
        state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = state[0]
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
    dt = T / days; mu = (r - q - 0.5 * v * v) * dt; sd = v * sqrt(dt); h = log(H / S)
    disc = exp(-r * T); sums = [[0.0, 0.0] for _ in range(5)]
    for _ in range(paths):
        x, daily_alive, surv, z2 = 0.0, True, 1.0, None
        for _ in range(days):
            if z2 is None:
                u1, u2 = unif(), unif(); rad = sqrt(-2.0 * log(u1))
                z, z2 = rad * cos(2 * pi * u2), rad * sin(2 * pi * u2)
            else: z, z2 = z2, None
            nx = x + mu + sd * z
            if nx <= h: daily_alive = False; surv = 0.0
            elif surv > 0.0: surv *= 1.0 - exp(-2.0 * (x - h) * (nx - h) / (v * v * dt))
            x = nx
        pay = disc * max(S * exp(x) - K, 0.0)
        for j, y in enumerate((pay, pay * daily_alive, pay * surv, pay * (daily_alive - surv), pay * (1 - surv))):
            sums[j][0] += y; sums[j][1] += y * y
    return [(s / paths, sqrt((s2 / paths - (s / paths) ** 2) / (paths - 1))) for s, s2 in sums]

S, K, H, r, q, v, T = 100.0, 100.0, 80.0, 0.05, 0.02, 0.20, 1.0
nu = r - q - 0.5 * v * v
C, w, img = call(S, K, r, q, v, T), weight(S, H, r, q, v), H * H / S
DO, DI = d_out(S, K, H, r, q, v, T), d_in(S, K, H, r, q, v, T)
bgk = d_out(S, K, H * exp(-0.5826 * v * sqrt(T / 252)), r, q, v, T) - DO; do_int, di_int = by_density(S, K, H, r, q, v, T)
do_grid, delta_grid = by_grid(S, K, H, r, q, v, T)
mc = by_simulation(S, K, H, r, q, v, T)
bump = lambda f, s, e: (f(s + e) - f(s - e)) / (2 * e); fo = lambda s: d_out(s, K, H, r, q, v, T); fc = lambda s: call(s, K, r, q, v, T)
rows = [("drift of ln S, nu = r - q - sigma^2/2", nu), ("exponent 2 nu / sigma^2", 2 * nu / v ** 2),
    ("reflection weight (H/S)^(2nu/sigma^2)", w), ("image spot H^2/S", img),
    ("vanilla call C(100)", C), ("image call C(64)", call(img, K, r, q, v, T)),
    ("1 down-and-in, formula", DI), ("1 down-and-out, formula", DO), ("  in + out", DI + DO),
    ("2 down-and-out, density integral", do_int), ("2 down-and-in, density integral", di_int),
    ("3 down-and-out, grid, no mirror", do_grid), ("  grid out + integral in", do_grid + di_int),
    ("4 vanilla, simulation", mc[0][0]), ("  its error bar (1 s.e.)", mc[0][1]),
    ("4 out, daily closes", mc[1][0]), ("  its error bar (1 s.e.)", mc[1][1]),
    ("4 in, daily closes = vanilla - out", mc[0][0] - mc[1][0]),
    ("4 out, continuous (bridge)", mc[2][0]), ("  its error bar (1 s.e.)", mc[2][1]),
    ("4 in, continuous (bridge)", mc[4][0]), ("  its error bar (1 s.e.)", mc[4][1]),
    ("4 daily minus continuous, same paths", mc[3][0]), ("  its error bar (1 s.e.)", mc[3][1]), ("  shifted-barrier estimate", bgk),
    ("greek: delta out, bump", bump(fo, S, 0.01)), ("greek: delta out, grid", delta_grid),
    ("greek: delta vanilla", bump(fc, S, 0.01)),
    ("greek: gamma out", (fo(S + 0.1) - 2 * fo(S) + fo(S - 0.1)) / 0.01),
    ("greek: gamma vanilla", (fc(S + 0.1) - 2 * fc(S) + fc(S - 0.1)) / 0.01),
    ("greek: vega out, per vol point", (d_out(S, K, H, r, q, .21, T) - d_out(S, K, H, r, q, .19, T)) / 2),
    ("greek: vega vanilla, per vol point", (call(S, K, r, q, .21, T) - call(S, K, r, q, .19, T)) / 2),
    ("wrong: weight left out", C - call(img, K, r, q, v, T)),
    ("wrong: exponent with +sigma^2/2", C - (H / S) ** (2 * (r - q + .5 * v * v) / v ** 2) * call(img, K, r, q, v, T)),
    ("wrong: image at H, not H^2/S", C - w * call(H, K, r, q, v, T)),
    ("wrong: only the end price checked", C),
    ("try: H = 90", d_out(S, K, 90.0, r, q, v, T)), ("try: sigma = 0.30, H = 80", d_out(S, K, H, r, q, .3, T)),
    ("try: S = 85, out", d_out(85.0, K, H, r, q, v, T)), ("try: S = 85, in", d_in(85.0, K, H, r, q, v, T))]
for name, val in rows: print(f"{name:<40} {val:>12.6f}")
print("bars, barrier H :" + "".join(f"{h:>8.0f}" for h in (60, 70, 80, 90, 95, 99)))
print("bars, out price :" + "".join(f"{d_out(S, K, h, r, q, v, T):>8.2f}" for h in (60, 70, 80, 90, 95, 99)))
sp = [80.0 + 5 * i for i in range(11)]
print("chart, spot     :" + "".join(f"{s:>7.0f}" for s in sp))
print("chart, vanilla  :" + "".join(f"{call(s, K, r, q, v, T):>7.2f}" for s in sp))
print("chart, out      :" + "".join(f"{d_out(s, K, H, r, q, v, T):>7.2f}" for s in sp))
print("chart, in       :" + "".join(f"{d_in(s, K, H, r, q, v, T):>7.2f}" for s in sp))
se = [60.0 + 10 * i for i in range(9)]
print("payoff, S_T     :" + "".join(f"{s:>7.0f}" for s in se) + "\npayoff, alive   :" + "".join(f"{max(s - K, 0.0):>7.0f}" for s in se))
assert abs(DO - 9.133306436498) < 1e-9, "formula vs the card's worked number"
assert abs(do_int - DO) < 1e-7, "density integral vs the reflection formula, out"
assert abs(di_int - DI) < 1e-7, "density integral vs the reflection formula, in"
assert abs(do_grid - DO) < 2e-3, "grid with no mirror vs the formula"
assert abs(do_grid + di_int - C) < 2e-3, "in-out parity from two independent roads"
assert abs(mc[2][0] - DO) < 3 * mc[2][1], "continuous simulated out within 3 error bars of the formula"
assert abs(mc[4][0] - DI) < 3 * mc[4][1], "continuous simulated in within 3 error bars of the formula"
assert abs(mc[3][0] - bgk) < 2 * mc[3][1] < mc[3][0], "daily premium: real, and within 2 error bars of the shifted barrier"
print("ALL CHECKS PASS")
