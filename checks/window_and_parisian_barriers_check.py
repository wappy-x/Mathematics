# Window and Parisian barriers -- the check behind the card.  Standard library only.
# Road 1: condition on the price when the window opens and integrate the 16-02
# down-and-out formula over it (Simpson).  Road 2: a double integral of the payoff
# against the reflected transition density, no formula blocks.  Road 3: a 252-step
# simulation with the Brownian-bridge chance of a touch, which also prices the
# Parisian clause; it is checked against the 16-02 and 16-03 formulas.
from math import log, sqrt, exp, cos, sin, pi
S, K, H, r, q, sig, T, T0 = 100.0, 100.0, 80.0, 0.05, 0.02, 0.20, 1.0, 0.5
nu = r - q - 0.5 * sig * sig; mu = nu / (sig * sig); b = log(H / S)
def dens(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                            # bell-curve area left of x, by its series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term = tot = x; n = 1
    while abs(term) > 1e-17 * abs(tot) + 1e-300:
        n += 2; term *= x * x / n; tot += term
    return 0.5 + dens(x) * tot
def call(s, tau):                                    # plain call, block A of 16-02
    v = sig * sqrt(tau); d1 = log(s / K) / v + (1 + mu) * v
    return s * exp(-q * tau) * N(d1) - K * exp(-r * tau) * N(d1 - v)
def doc(s, tau, h=H):                                # down-and-out call, strike above barrier: A - C
    if s <= h: return 0.0
    v = sig * sqrt(tau); y1 = log(h * h / (s * K)) / v + (1 + mu) * v
    C = s * exp(-q * tau) * (h / s) ** (2 * mu + 2) * N(y1) - K * exp(-r * tau) * (h / s) ** (2 * mu) * N(y1 - v)
    return call(s, tau) - C
def touch(s, tau):                                   # chance a down line at H is touched within tau
    v, c = sig * sqrt(tau), log(H / s)
    return N((c - nu * tau) / v) + (H / s) ** (2 * mu) * N((c + nu * tau) / v)
def simpson(f, a, c, n):
    h = (c - a) / n; tot = f(a) + f(c)
    for i in range(1, n): tot += (4 if i % 2 else 2) * f(a + i * h)
    return h / 3.0 * tot
def f_at(t): return lambda x: dens((x - nu * t) / (sig * sqrt(t))) / (sig * sqrt(t))
def avg_at(t0, g, lo, hi):                           # average of g(price at t0) over a log-price range
    f = f_at(t0); return simpson(lambda x: f(x) * g(S * exp(x)), lo, hi, 2000)
def window(t0, h=H):                                 # road 1: discounted average of the knock-out at t0
    if t0 <= 0: return doc(S, T, h)
    if t0 >= T: return call(S, T)
    return exp(-r * t0) * avg_at(t0, lambda s: doc(s, T - t0, h), log(h / S), nu * t0 + 10 * sig * sqrt(t0))
def window_2d(t0, n=400):                            # road 2: payoff against reflected density
    f, tau = f_at(t0), T - t0; sd = sig * sqrt(tau); g = lambda z: dens((z - nu * tau) / sd) / sd
    xh, yh = nu * t0 + 9 * sig * sqrt(t0), nu * T + 9 * sig * sqrt(T)
    def over_y(x):
        tilt = exp(2 * nu * (b - x) / (sig * sig))
        return f(x) * simpson(lambda y: (S * exp(y) - K) * (g(y - x) - tilt * g(y - 2 * b + x)), log(K / S), yh, n)
    return exp(-r * T) * simpson(over_y, b, xh, n)
VAN, DOC = call(S, T), doc(S, T)
W1, W2 = window(T0), window_2d(T0)
LO, HI = b - 10 * sig * sqrt(T0), nu * T0 + 10 * sig * sqrt(T0)
BELOW = exp(-r * T0) * avg_at(T0, lambda s: call(s, T - T0), LO, b)   # value of paths under 80 at 0.5
fr = f_at(T0); tl = exp(2 * nu * b / (sig * sig))                      # front window: barrier 0 to 0.5 only
FRONT = exp(-r * T0) * simpson(lambda x: (fr(x) - tl * fr(x - 2 * b)) * call(S * exp(x), T - T0), b, HI, 2000)
BGK = doc(S, T, H * exp(-0.5826 * sig * sqrt(T / 252)))   # 16-03: daily checks = barrier pushed out
P_BELOW = N((b - nu * T0) / (sig * sqrt(T0)))
P_WIN = P_BELOW + avg_at(T0, lambda s: touch(s, T - T0), b, HI)
# ---- road 3: simulation, 252 daily closes ----
state = 20261123
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2 ** 53
PATHS, STEPS, OPEN = 150000, 252, 126
dt = T / STEPS; drift = nu * dt; vol = sig * sqrt(dt); v2 = vol * vol
DAYS = (1, 2, 3, 5, 10, 20)
acc = {k: [0.0, 0.0] for k in ("full", "win") + DAYS + ("cum5", "dir5")}; hits = {d: 0 for d in DAYS}
def add(k, x): a = acc[k]; a[0] += x; a[1] += x * x
for _ in range(PATHS):
    x, wf, ww, run, best, cum, zs = 0.0, 1.0, 1.0, 0, 0, 0, []
    for i in range(1, STEPS + 1):
        if not zs:
            u1, u2 = uniform(), uniform(); m = sqrt(-2 * log(u1))
            zs = [m * sin(2 * pi * u2), m * cos(2 * pi * u2)]
        y = x + drift + vol * zs.pop()
        keep = 0.0 if x <= b or y <= b else 1 - exp(-2 * (x - b) * (y - b) / v2)
        wf *= keep                                   # whole year, watched every instant
        if i == OPEN and y <= b: ww = 0.0            # window opens with the price under the line
        if i > OPEN: ww *= keep
        if y < b: run += 1; cum += 1; best = max(best, run)
        else: run = 0
        x = y
    p = exp(-r * T) * max(S * exp(x) - K, 0.0)      # lost value: what the knock-out takes away
    add("full", p * (1 - wf)); add("win", p * (1 - ww)); add("cum5", p * (cum >= 5)); add("dir5", p * (best < 5))
    for d in DAYS: add(d, p * (best >= d)); hits[d] += best >= d
def mc(k):
    s1, s2 = acc[k]; m = s1 / PATHS
    return VAN - m, sqrt(max(s2 / PATHS - m * m, 0.0) / PATHS)
print("house: S 100, K 100, barrier 80, r 5%, q 2%, sigma 20%, T 1; window opens at 0.5")
print(f"plain call                         {VAN:.6f}")
print(f"down-and-out, whole year (16-02)   {DOC:.6f}")
print(f"window 0.5 to 1, road 1 (1-D)      {W1:.6f}")
print(f"window 0.5 to 1, road 2 (2-D)      {W2:.6f}")
mw, sw = mc("win"); mf, sf = mc("full")
print(f"window 0.5 to 1, road 3 simulated  {mw:.4f} +/- {sw:.4f}")
print(f"whole year simulated, bridge       {mf:.4f} +/- {sf:.4f}")
print(f"daily-checked whole year (16-03)   {BGK:.6f}  lost {VAN - BGK:.6f}")
print("Parisian: knocked out after D consecutive daily closes below 80")
par = {}
for d in DAYS:
    par[d], se = mc(d)
    print(f"  D {d:2d} days  {par[d]:.4f} +/- {se:.4f}  lost {VAN - par[d]:.4f}  paths knocked out {hits[d] / PATHS:.4f}")
s1, s2 = acc["dir5"]; m5 = s1 / PATHS
print(f"direct average of the D 5 payoff {m5:.4f} +/- {sqrt((s2 / PATHS - m5 * m5) / PATHS):.4f}")
print(f"simulation gaps in standard errors: window {abs(mw - W1) / sw:.2f}, whole year {abs(mf - DOC) / sf:.2f}, D 1 {abs(par[1] - BGK) / mc(1)[1]:.2f}")
print(f"worked: log price at 0.5 centre {nu * T0:.6f} spread {sig * sqrt(T0):.6f}; discount {exp(-r * T0):.6f}")
print(f"worked: chance under 80 at 0.5 {P_BELOW:.6f}; chance of touching 80 in the window {P_WIN:.6f}; whole year {touch(S, T):.6f}")
for s6 in (80.0, 85.0, 90.0, 100.0, 110.0):
    print(f"worked: price at 0.5 {s6:5.1f}  6-month call {call(s6, 0.5):9.6f}  6-month knock-out {doc(s6, 0.5):9.6f}  lost {call(s6, 0.5) - doc(s6, 0.5):8.6f}")
print(f"worked: lost value {VAN - W1:.6f} = under 80 at the opening {BELOW:.6f} + touched later {VAN - W1 - BELOW:.6f}; whole year {VAN - DOC:.6f}")
print(f"wrong: whole-year formula for the window          {DOC:.6f}")
print(f"wrong: half the whole-year discount              {VAN - 0.5 * (VAN - DOC):.6f}")
print(f"wrong: paths under 80 at 0.5 kept alive           {W1 + BELOW:.6f}")
print(f"wrong: barrier in the first half instead (front)  {FRONT:.6f}")
c5, _ = mc("cum5")
print(f"wrong: Parisian counting 5 days in total, not in a row {c5:.4f}")
ts = [i / 10 for i in range(11)]
print("chart, window opens " + " ".join(f"{t:5.1f}" for t in ts))
print("chart, price        " + " ".join(f"{window(t):5.3f}" for t in ts))
print(f"try: window opens 0.25 {window(0.25):.6f}; window with barrier 85 {window(T0, 85.0):.6f}")
assert abs(DOC - 9.133306) < 1e-6 and abs(VAN - 9.227006) < 1e-6, "16-02 house numbers"
assert abs(W1 - W2) < 1e-6, "conditioning and the reflected double integral must agree"
assert abs(mw - W1) < 3 * sw and abs(mf - DOC) < 3 * sf, "simulation within three standard errors"
assert abs(par[1] - BGK) < 3 * mc(1)[1], "Parisian with D = 1 is the daily knock-out of 16-03"
assert DOC < W1 < VAN and BGK < par[5] < VAN, "bounds: full-life barrier <= window, Parisian <= plain call"
assert all(par[a] <= par[c] for a, c in zip(DAYS, DAYS[1:])), "a longer wait kills fewer paths"
assert c5 < par[5], "five days in total happens more often than five in a row"
print("ALL CHECKS PASS")
