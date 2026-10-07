# A spot price that reverts -- the check behind the card.  Standard library only.
# Crude at 80, its log pulled toward ln 75 at speed kappa = 1, volatility 30%.
# Futures prices reached three ways: the Schwartz closed form, the two moment
# equations stepped forward by Runge-Kutta, and a Monte Carlo of the log price.
# Then the Samuelson vol, a spot jump, and a least-squares fit of a strip.
from math import log, exp, sqrt, cos, pi

S0, LEVEL, KAPPA, SIGMA = 80.0, 75.0, 1.0, 0.30
A = log(LEVEL)                                    # long-run level of the LOG price

def fut(T, S=S0, k=KAPPA, a=A, s=SIGMA):          # road 1: the closed form
    w = exp(-k * T)
    return exp(w * log(S) + (1 - w) * a + s * s * (1 - exp(-2 * k * T)) / (4 * k))

def fut_ode(T, S=S0, k=KAPPA, a=A, s=SIGMA, n=2000):
    # road 2: mean m and variance v of the log obey dm/dt = k(a - m), dv/dt = s^2 - 2kv.
    # Step both with Runge-Kutta; no exponential solution is used.  F = exp(m + v/2).
    m, v, h = log(S), 0.0, T / n
    fm = lambda m: k * (a - m)
    fv = lambda v: s * s - 2 * k * v
    for _ in range(n):
        m1 = fm(m); m2 = fm(m + h / 2 * m1); m3 = fm(m + h / 2 * m2); m4 = fm(m + h * m3)
        m += h / 6 * (m1 + 2 * m2 + 2 * m3 + m4)
        v1 = fv(v); v2 = fv(v + h / 2 * v1); v3 = fv(v + h / 2 * v2); v4 = fv(v + h * v3)
        v += h / 6 * (v1 + 2 * v2 + 2 * v3 + v4)
    return exp(m + v / 2)

state = 20260927                                  # road 3: our own random numbers (64-bit LCG)
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53

def simulate(times, pairs=10000, dt=0.01):
    # Euler steps of dX = kappa (a - X) dt + sigma dW, antithetic pairs; returns mean and s.e. of S_T
    marks = {round(T / dt): T for T in times}
    sums = {T: [0.0, 0.0] for T in times}
    for _ in range(pairs):
        x1 = x2 = log(S0)
        for step in range(1, max(marks) + 1):
            z = sqrt(-2 * log(uniform())) * cos(2 * pi * uniform())
            x1 += KAPPA * (A - x1) * dt + SIGMA * sqrt(dt) * z
            x2 += KAPPA * (A - x2) * dt - SIGMA * sqrt(dt) * z
            if step in marks:
                y = (exp(x1) + exp(x2)) / 2
                sums[marks[step]][0] += y; sums[marks[step]][1] += y * y
    out = {}
    for T, (s1, s2) in sums.items():
        mean = s1 / pairs
        out[T] = (mean, sqrt((s2 / pairs - mean * mean) / pairs))
    return out

TIMES = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0]
sim = simulate(TIMES)
print("inputs: spot 80, level e^a = 75, kappa = 1 per year, sigma = 0.30")
print(f"half-life of a gap, ln 2 / kappa (years)      {log(2) / KAPPA:10.4f}")
print(f"long-run futures level 75 e^(sigma^2/4kappa)  {LEVEL * exp(SIGMA**2 / (4 * KAPPA)):10.4f}")
print(f"futures price at T = 30 (ODE road)            {fut_ode(30.0):10.4f}")
for T in (1.0, 5.0):                              # the worked-numbers table, step by step
    w, v = exp(-KAPPA * T), SIGMA**2 * (1 - exp(-2 * KAPPA * T)) / (4 * KAPPA)
    m = w * log(S0) + (1 - w) * A
    print(f"by hand T = {T:.0f}: e^-kT {w:.4f}  ln S {log(S0):.4f}  a {A:.4f}  blend {m:.4f}"
          f"  variance term {v:.4f}  ln F {m + v:.4f}  F {exp(m + v):.4f}")
print("   T   closed form   ODE road   simulation  (s.e.)")
for T in TIMES:
    print(f"{T:4.2f}  {fut(T):11.4f}  {fut_ode(T):9.4f}  {sim[T][0]:11.4f}  ({sim[T][1]:.4f})")

# Samuelson: futures vol = sigma e^{-kappa T}; second road bumps the spot inside the ODE road
print("   T   futures vol, formula   by bumping spot")
vols = []
for T in TIMES:
    h = 1e-4
    bump = SIGMA * (log(fut_ode(T, S=S0 * exp(h))) - log(fut_ode(T, S=S0 * exp(-h)))) / (2 * h)
    vols.append((SIGMA * exp(-KAPPA * T), bump))
    print(f"{T:4.2f}  {100 * vols[-1][0]:18.2f}%  {100 * bump:15.2f}%")

print(f"spot falls 80 -> 70, moves: spot {100 * (70 / 80 - 1):+.2f}%,",
      f"1-year {100 * (fut(1.0, S=70.0) / fut(1.0) - 1):+.2f}%, 5-year {100 * (fut(5.0, S=70.0) / fut(5.0) - 1):+.2f}%")

grid = [0.5 * i for i in range(11)]
print("chart T      " + " ".join(f"{T:6.1f}" for T in grid))
print("chart from 80" + " ".join(f"{fut(T):6.2f}" for T in grid))
print("chart from 70" + " ".join(f"{fut(T, S=70.0):6.2f}" for T in grid))

# ---- the fit: a strip of quotes, sigma taken as known, find kappa and the level ----
STRIP_T = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
STRIP_F = [79.60, 79.08, 78.33, 77.70, 77.37, 76.93, 76.81, 76.72]
def sse(k, a):
    return sum((log(f) - log(fut(T, k=k, a=a))) ** 2 for T, f in zip(STRIP_T, STRIP_F))
def best_a(k):                                    # for fixed kappa, the level solves a straight-line fit
    w = [1 - exp(-k * T) for T in STRIP_T]
    y = [log(f) - exp(-k * T) * log(S0) - SIGMA**2 * (1 - exp(-2 * k * T)) / (4 * k)
         for T, f in zip(STRIP_T, STRIP_F)]
    return sum(wi * yi for wi, yi in zip(w, y)) / sum(wi * wi for wi in w)
lo, hi, g = 0.05, 5.0, (sqrt(5) - 1) / 2          # road 1: golden-section search on kappa alone
for _ in range(200):
    c, d = hi - g * (hi - lo), lo + g * (hi - lo)
    if sse(c, best_a(c)) < sse(d, best_a(d)): hi = d
    else: lo = c
k1 = (lo + hi) / 2; a1 = best_a(k1)
k2, a2 = 0.5, log(STRIP_F[-1])                   # road 2: Gauss-Newton on both at once,
for _ in range(50):                               # starting from the longest quote
    r = [log(f) - log(fut(T, k=k2, a=a2)) for T, f in zip(STRIP_T, STRIP_F)]
    e = 1e-6
    jk = [(log(fut(T, k=k2 + e, a=a2)) - log(fut(T, k=k2 - e, a=a2))) / (2 * e) for T in STRIP_T]
    ja = [(log(fut(T, k=k2, a=a2 + e)) - log(fut(T, k=k2, a=a2 - e))) / (2 * e) for T in STRIP_T]
    p, q, u = sum(x * x for x in jk), sum(x * y for x, y in zip(jk, ja)), sum(y * y for y in ja)
    bk, ba = sum(x * y for x, y in zip(jk, r)), sum(x * y for x, y in zip(ja, r))
    dk, da = (u * bk - q * ba) / (p * u - q * q), (p * ba - q * bk) / (p * u - q * q)
    step = 1.0                                    # halve the step until the error falls
    while step > 1e-6 and (k2 + step * dk <= 0 or sse(k2 + step * dk, a2 + step * da) > sse(k2, a2)):
        step /= 2
    k2, a2 = k2 + step * dk, a2 + step * da
print(f"fit, golden section: kappa {k1:.4f}  level e^a {exp(a1):.4f}  rms log error {sqrt(sse(k1, a1) / 8):.6f}")
print(f"fit, Gauss-Newton:   kappa {k2:.4f}  level e^a {exp(a2):.4f}  rms log error {sqrt(sse(k2, a2) / 8):.6f}")
print("strip quotes  " + " ".join(f"{f:6.2f}" for f in STRIP_F))
print("fitted curve  " + " ".join(f"{fut(T, k=k1, a=a1):6.2f}" for T in STRIP_T))

# ---- what breaks, and try changing ----
print(f"wrong: drop the variance term, 1-year        {exp(exp(-1) * log(S0) + (1 - exp(-1)) * A):10.4f}")
print(f"wrong: drop the variance term, 5-year        {exp(exp(-5) * log(S0) + (1 - exp(-5)) * A):10.4f}")
print(f"wrong: price (not log) reverts, 1-year       {LEVEL + (S0 - LEVEL) * exp(-1):10.4f}")
print(f"wrong: carry-model vol, 5-year future        {100 * SIGMA:9.2f}%")
print(f"try: kappa = 0.25, 5-year future             {fut(5.0, k=0.25):10.4f}")
print(f"try: kappa = 0.25, long-run futures level    {LEVEL * exp(SIGMA**2 / (4 * 0.25)):10.4f}")
print(f"try: spot 70, 1-year future                  {fut(1.0, S=70.0):10.4f}")
print(f"try: kappa = 0.25, 5-year futures vol        {100 * SIGMA * exp(-1.25):9.2f}%")

for T in TIMES:
    assert abs(fut(T) - fut_ode(T)) < 1e-6, "closed form vs Runge-Kutta moments"
    assert abs(sim[T][0] - fut(T)) < 4 * sim[T][1], "simulation within four standard errors"
    assert abs(vols[TIMES.index(T)][0] - vols[TIMES.index(T)][1]) < 1e-6, "Samuelson vol vs bump"
assert abs(fut_ode(30.0) - LEVEL * exp(SIGMA**2 / (4 * KAPPA))) < 1e-6, "ODE long end vs the limit"
assert abs(k1 - k2) < 1e-6, "two fits agree on kappa"
assert abs(exp(a1) - LEVEL) < 1.0, "fit recovers the level the strip was built from"
assert abs(k1 - KAPPA) < 0.2, "fit recovers the speed the strip was built from"
print("ALL CHECKS PASS")
