# Commodity implied vol and the call skew -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is a series, the inverse CDF, the root
# finders, the integrator and the random numbers are all written out here.
from math import log, sqrt, exp, pi, cos, sin
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def N(x):                                # bell-curve area left of x: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total
def N_inv(p, lo=-12.0, hi=12.0):         # inverse CDF by halving
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if N(mid) < p: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def d1(F, K, s, T): return (log(F / K) + 0.5 * s * s * T) / (s * sqrt(T))
def black_call(F, K, r, s, T):           # Black-76 call on a futures price
    a = d1(F, K, s, T); return exp(-r * T) * (F * N(a) - K * N(a - s * sqrt(T)))
def black_put(F, K, r, s, T):            # Black-76 put, written separately
    a = d1(F, K, s, T); return exp(-r * T) * (K * N(s * sqrt(T) - a) - F * N(-a))
def vega(F, K, r, s, T): return exp(-r * T) * F * phi(d1(F, K, s, T)) * sqrt(T)
def call_by_simpson(F, K, r, s, T, n=20000):   # average the payoff over the bell curve: no d1, no d2
    a, b = -10.0, 10.0; h = (b - a) / n
    f = lambda z: max(F * exp(-0.5 * s * s * T + s * sqrt(T) * z) - K, 0.0) * phi(z)
    tot = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return exp(-r * T) * tot * h / 3.0
def bisect(price, quote, lo=1e-6, hi=10.0, steps=60):
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if price(mid) < quote: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def implied(quote, F, K, r, T, put=False):       # refuse quotes outside the no-arbitrage range
    D = exp(-r * T)
    floor, ceil = (D * max(K - F, 0), D * K) if put else (D * max(F - K, 0), D * F)
    if not floor < quote < ceil: return None
    f = black_put if put else black_call
    return bisect(lambda s: f(F, K, r, s, T), quote)
def newton(quote, F, K, r, T, s=0.5):
    for i in range(1, 50):
        step = (black_call(F, K, r, s, T) - quote) / vega(F, K, r, s, T); s -= step
        if abs(step) < 1e-13: return s, i
    return s, 50
F, K, r, T = 85.0, 85.0, 0.05, 0.5          # house Brent: futures 85, strike 85, 5%, six months
D = exp(-r * T); Q = 7.002679                 # the screen quote, USD/bbl
iv1 = implied(Q, F, K, r, T)
iv2, its = newton(Q, F, K, r, T)
iv3 = bisect(lambda s: call_by_simpson(F, K, r, s, T), Q, 0.1, 0.6, 40)
a0 = d1(F, K, 0.30, T)
print("house Brent: F 85, K 85, r 5%, T 0.5")
rows = [("discount D = e^-rT", D), ("floor D(F-K)+", D * max(F - K, 0)), ("ceiling D F", D * F),
        ("d1 at 0.30", a0), ("N(d1)", N(a0)), ("N(d2)", N(a0 - 0.30 * sqrt(T))),
        ("call at 0.30", black_call(F, K, r, 0.30, T)), ("vega at 0.30", vega(F, K, r, 0.30, T)),
        ("1 implied vol, bisection", iv1), ("2 implied vol, Newton", iv2), ("  Newton steps from 0.5", its),
        ("3 implied vol, Simpson price", iv3)]
for name, v in rows: print(f"  {name:<30} {v:>11.6f}")
# The smile: vol as a quadratic in call delta x = N(d1), pinned at 30% where K = F.
xa = N(0.5 * 0.30 * sqrt(T))                  # delta of the at-the-money-forward call
u, v_ = 0.15 - xa, 0.85 - xa                  # 15-delta call, 15-delta put (call delta 0.85)
det = u * v_ * v_ - v_ * u * u
b = (0.04 * v_ * v_ - (-0.02) * u * u) / det  # vol(x) - 0.30 = b (x - xa) + c (x - xa)^2
c = (u * (-0.02) - v_ * 0.04) / det
vol_at = lambda x: 0.30 + b * (x - xa) + c * (x - xa) ** 2
print(f"\nsmile in delta: xa {xa:.6f}  b {b:.6f}  c {c:.6f}")
print("  label  strike    vol%   quote (OTM side)  implied%  put-via-parity%")
labels = [("10p", 0.90), ("15p", 0.85), ("25p", 0.75), ("35p", 0.65), ("ATMF", xa),
          ("35c", 0.35), ("25c", 0.25), ("15c", 0.15), ("10c", 0.10)]
smile = {}
for lab, x in labels:
    s = vol_at(x); Kx = F * exp(-N_inv(x) * s * sqrt(T) + 0.5 * s * s * T)
    put = x > xa + 1e-12
    q = black_put(F, Kx, r, s, T) if put else black_call(F, Kx, r, s, T)
    iv = implied(q, F, Kx, r, T, put)
    ivp = implied(q + D * (F - Kx), F, Kx, r, T) if put else implied(q - D * (F - Kx), F, Kx, r, T, True)
    smile[lab] = (Kx, s, q, iv, ivp)
    print(f"  {lab:<5} {Kx:7.2f}  {100*s:6.2f}  {q:10.6f} {'P' if put else 'C'}      {100*iv:7.4f}   {100*ivp:7.4f}")
rr = smile["15c"][3] - smile["15p"][3]; fly = 0.5 * (smile["15c"][3] + smile["15p"][3]) - smile["ATMF"][3]
K15 = smile["15c"][0]
c34, c30 = black_call(F, K15, r, 0.34, T), black_call(F, K15, r, 0.30, T)
print(f"  risk reversal 15c - 15p {100*rr:.4f}   butterfly {100*fly:.4f} vol points")
print(f"  15c at 34% {c34:.6f}, at flat 30% {c30:.6f}, richer by {c34 - c30:.6f}")
# Samuelson: option expiring with its contract at T; model spot log-vol sig, pull-back kappa.
kap = 1.2
f = lambda T_, k=kap: (1 - exp(-2 * k * T_)) / (2 * k * T_)
sig = 0.30 / sqrt(f(0.5))                     # fitted so the 6-month contract sits at 30%
def samuel_simpson(T_, n=2000):               # road 2: average sig^2 e^{-2 kap (T-t)} over [0, T]
    h = T_ / n; g = lambda t: sig * sig * exp(-2 * kap * (T_ - t))
    tot = g(0) + g(T_) + sum((4 if i % 2 else 2) * g(i * h) for i in range(1, n))
    return sqrt(tot * h / 3.0 / T_)
print(f"\nSamuelson: kappa {kap}, spot vol {sig:.6f}, half-life {log(2)/kap:.4f} y")
print(f"  by hand: e^-1.2 {exp(-1.2):.6f}  f(0.5) {f(0.5):.6f}  e^-4.8 {exp(-4.8):.6f}  f(2) {f(2.0):.6f}  sqrt f(2) {sqrt(f(2.0)):.6f}")
months = [1, 3, 6, 9, 12, 15, 18, 21, 24]
print("  month   " + " ".join(f"{m:6d}" for m in months))
print("  vol %   " + " ".join(f"{100*sig*sqrt(f(m/12)):6.2f}" for m in months))
print("  simpson " + " ".join(f"{100*samuel_simpson(m/12):6.2f}" for m in months))
print("  k=0.3 % " + " ".join(f"{100*0.30/sqrt(f(0.5,0.3))*sqrt(f(m/12,0.3)):6.2f}" for m in months))
# Road 3: simulate the mean-reverting log spot weekly for two years, price the ATM call, invert.
state = 20260927
def unif():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
paths, steps, T2 = 40000, 104, 2.0
dt = T2 / steps; ends = []
for _ in range(paths):
    y = 0.0
    for j in range(steps // 2):               # Box-Muller: two normals per pair of uniforms
        u1, u2 = unif(), unif(); rad = sqrt(-2 * log(u1))
        for z in (rad * cos(2 * pi * u2), rad * sin(2 * pi * u2)):
            y += -kap * y * dt + sig * sqrt(dt) * z
    ends.append(exp(y))
m2 = sum(ends) / paths                          # the 24-month futures is the average spot; scale it to 85
C2 = exp(-r * T2) * sum(max(85 * e / m2 - 85, 0) for e in ends) / paths
iv_mc = implied(C2, 85.0, 85.0, r, T2)
print(f"  24m by simulation: raw mean {m2:.6f}, ATM call {C2:.6f}, implied {100*iv_mc:.4f}%, gap {100*(iv_mc - sig*sqrt(f(2.0))):.4f} pts")
print("\nwhat breaks (house quote 7.002679 unless stated)")
bs_spot = lambda s: 85 * N((r + 0.5 * s * s) * T / (s * sqrt(T))) - 85 * D * N((r - 0.5 * s * s) * T / (s * sqrt(T)))
wrong = [("85 as spot, Black-Scholes, no yield", bisect(bs_spot, Q)),
         ("forgot the discount D", bisect(lambda s: F * N(d1(F, K, s, T)) - K * N(d1(F, K, s, T) - s * sqrt(T)), Q)),
         ("T = 1 year, not 6 months", implied(Q, F, K, r, 1.0)),
         ("quote 83.00, bare solver", bisect(lambda s: black_call(F, K, r, s, T), 83.0))]
for name, v in wrong: print(f"  {name:<40} {v:>10.6f}")
v24 = sig * sqrt(f(2.0))
over = black_call(F, K, r, 0.30, 2.0) - black_call(F, K, r, v24, 2.0)
print(f"  24m ATM call at 30% {black_call(F, K, r, 0.30, 2.0):.6f}, at {100*v24:.2f}% {black_call(F, K, r, v24, 2.0):.6f}: overpays {over:.6f}")
assert abs(iv1 - 0.30) < 1e-6 and abs(iv2 - iv1) < 1e-9, "7.002679 was made at 30%: both solvers recover it"
assert abs(iv3 - iv1) < 1e-6, "a price built by Simpson averaging gives the same vol"
assert all(abs(k_[3] - k_[1]) < 1e-9 and abs(k_[4] - k_[1]) < 1e-9 for k_ in smile.values()), "every quote inverts to its smile vol, both sides of parity"
assert abs(smile["15c"][1] - 0.34) < 1e-12 and abs(smile["15p"][1] - 0.28) < 1e-12 and abs(smile["ATMF"][0] - F) < 1e-9, "smile pinned"
assert all(abs(sig * sqrt(f(m / 12)) - samuel_simpson(m / 12)) < 1e-7 for m in months), "closed form vs integral"
assert abs(iv_mc - v24) < 0.006, "simulated spot gives the 24-month vol within noise"
assert implied(83.0, F, K, r, T) is None and wrong[3][1] > 9.99, "83 is above the ceiling: no vol, bare solver hits its edge"
print("ALL CHECKS PASS")
