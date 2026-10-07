# Correlation from a quanto price -- the check behind the card.  Standard library only.
# Normal CDF, integrator, root finders and random numbers are all written here.
from math import log, sqrt, exp, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                   # bell-curve area, by its Taylor series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    t = s = x
    for n in range(1, 400):
        t *= x * x / (2 * n + 1); s += t
        if abs(t) < 1e-17 * abs(s): break
    return 0.5 + s * phi(x)

S, K, XB, X0, RD, RF, Q, SS, SX, T = 100.0, 100.0, 1.10, 1.15, 0.05, 0.03, 0.01, 0.20, 0.10, 1.0

def fwd(rho, sx=SX): return S * exp((RF - Q - rho * SS * sx) * T)   # quanto forward, EUR
def price(rho, k=K, xb=XB, vol=SS, sx=SX, sign=-1.0):              # road 1: the closed form
    F = S * exp((RF - Q + sign * rho * SS * sx) * T)
    d1 = (log(F / k) + 0.5 * vol * vol * T) / (vol * sqrt(T)); d2 = d1 - vol * sqrt(T)
    return xb * exp(-RD * T) * (F * N(d1) - k * N(d2))
def slope(rho, k=K):                                                # dC/drho, by the chain rule
    F = fwd(rho); d1 = (log(F / k) + 0.5 * SS * SS * T) / (SS * sqrt(T))
    return -XB * exp(-RD * T) * F * N(d1) * SS * SX * T

def bisect(f, lo, hi, steps=80, log_rows=0):   # f(lo) > 0 > f(hi): the price falls as rho rises
    for i in range(steps):
        mid = 0.5 * (lo + hi); v = f(mid)
        if i < log_rows: print(f"bisect step {i+1}  rho {mid:+.6f}  price minus quote {v:+.6f}")
        if v > 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def implied(quote, **kw):                        # existence first, then the unique root
    top, bottom = price(-1.0, **kw), price(1.0, **kw)
    if not (bottom <= quote <= top): return None
    return bisect(lambda r: price(r, **kw) - quote, -1.0, 1.0)
def newton(quote, rho=0.0):                      # road 3: Newton, no bracket kept
    for _ in range(50): rho -= (price(rho) - quote) / slope(rho)
    return rho

def simpson_call_from_forward(F, k=K, n=2000):   # road 2: integrate the payoff over the bell curve
    v = SS * sqrt(T); a = (log(k / F) + 0.5 * v * v) / v; b = 10.0; h = (b - a) / n
    f = lambda z: (F * exp(-0.5 * v * v + v * z) - k) * phi(z)
    tot = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return XB * exp(-RD * T) * tot * h / 3.0
def forward_from_quote(quote):                   # secant on the forward, no correlation in sight
    f0, f1 = 100.0, 110.0
    g0, g1 = simpson_call_from_forward(f0) - quote, simpson_call_from_forward(f1) - quote
    for _ in range(60):
        if g1 == g0: break
        f0, f1, g0 = f1, f1 - g1 * (f1 - f0) / (g1 - g0), g1
        g1 = simpson_call_from_forward(f1) - quote
    return f1

M64 = (1 << 64) - 1
state = 20260927
def uniform():                                   # splitmix64, then a number strictly inside (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def normal_pair():                               # Box-Muller
    r, a = sqrt(-2.0 * log(uniform())), 2.0 * pi * uniform()
    return r * cos(a), r * sin(a)

PAIRS = [normal_pair() for _ in range(100000)]
def mc_price(rho):   # road 4: simulate in the EURO world, no quanto adjustment used anywhere
    total = total2 = 0.0; c = sqrt(1.0 - rho * rho)
    for z1, z2 in PAIRS:
        pair = 0.0
        for s in (1.0, -1.0):                    # antithetic: each draw and its mirror
            ST = S * exp((RF - Q - 0.5 * SS * SS) * T + SS * sqrt(T) * s * z1)
            XT = X0 * exp((RD - RF + 0.5 * SX * SX) * T + SX * sqrt(T) * s * (rho * z1 + c * z2))
            pair += 0.5 * XB * max(ST - K, 0.0) / XT
        total += pair; total2 += pair * pair
    n = len(PAIRS); m = total / n; se = sqrt((total2 / n - m * m) / n)
    return X0 * exp(-RF * T) * m, X0 * exp(-RF * T) * se

def sample_corr(n=252, rho=0.30):                # one simulated year of daily returns
    xs, ys = [], []
    for _ in range(n):
        z1, z2 = normal_pair(); xs.append(z1); ys.append(rho * z1 + sqrt(1 - rho * rho) * z2)
    mx, my = sum(xs) / n, sum(ys) / n
    sxy = sum((a - mx) * (b - my) for a, b in zip(xs, ys))
    return sxy / sqrt(sum((a - mx) * (a - mx) for a in xs) * sum((b - my) * (b - my) for b in ys))

def p(label, v): print(f"{label:<44} {v:>12.6f}" if v is not None else f"{label:<44} {'none':>12}")
HOUSE = 9.151629
p("formula at rho 0.30: the house quote", price(0.30))
p("ceiling: price at rho = -1", price(-1.0)); p("floor: price at rho = +1", price(1.0))
r1 = bisect(lambda r: price(r) - HOUSE, -1.0, 1.0, log_rows=6)
F2 = forward_from_quote(HOUSE); r2 = (RF - Q - log(F2 / S) / T) / (SS * SX)
r3 = newton(HOUSE)
p("1 bisection on the formula", r1); p("2 forward from quote, Simpson + secant", F2)
p("  ln(F/S)/T, the forward's growth", log(F2 / S) / T)
p("  rho = (rf - q - ln(F/S)/T) / (sS sX)", r2); p("3 Newton from rho = 0", r3)
p("rho sS sX, the quanto adjustment", r1 * SS * SX); p("rho sX, all the quote pins down", r1 * SX)
mc = {rho: mc_price(rho) for rho in (-1.0, 0.30, 1.0)}
for rho in (-1.0, 0.30, 1.0):
    print(f"4 euro-world simulation, rho {rho:+.2f}  {mc[rho][0]:>12.6f}  one standard error {mc[rho][1]:.6f}")
p("quote 11.00: correlation", implied(11.00)); p("  Newton, unbracketed", newton(11.00))
p("quote 8.20: correlation", implied(8.20)); p("quote 9.40: correlation", implied(9.40))
p("quote 8.50: correlation", implied(8.50))
p("slope dC/drho at 0.30", slope(r1)); p("rho moved by a 1-cent quote error", 0.01 / abs(slope(r1)))
p("  strike 140: ceiling", price(-1.0, k=140.0)); p("  strike 140: floor", price(1.0, k=140.0))
p("  strike 140: rho moved by 1 cent", 0.01 / abs(slope(0.30, k=140.0)))
for sx in (0.02, 0.03, 0.05, 0.15, 0.30):
    p(f"FX vol {sx:.2f} assumed: correlation", implied(HOUSE, sx=sx))
p("wrong: spot 1.15 for the fixed 1.10", implied(HOUSE, xb=X0))
p("wrong: vol sqrt(sS^2 + sX^2)", implied(HOUSE, vol=sqrt(SS * SS + SX * SX)))
p("  the floor with that vol", price(1.0, vol=sqrt(SS * SS + SX * SX)))
p("wrong: plus sign on rho", bisect(lambda r: HOUSE - price(r, sign=1.0), -1.0, 1.0))
est = [sample_corr() for _ in range(1000)]
mean = sum(est) / len(est); sd = sqrt(sum((e - mean) ** 2 for e in est) / (len(est) - 1))
p("history: first simulated year's estimate", est[0]); p("history: average of 1000 years", mean)
p("history: spread of the estimates", sd); p("  formula (1 - rho^2) / sqrt(252)", (1 - 0.09) / sqrt(252))
p("  quote 9.40 sits this many spreads away", (0.30 - implied(9.40)) / sd)
print("sweep: rho, price, quanto forward")
for rho in (-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0):
    print(f"  {rho:+.2f}  {price(rho):.2f}  {fwd(rho):.2f}")
assert abs(r1 - 0.30) < 1e-5
assert abs(r2 - r1) < 1e-6
assert abs(r3 - r1) < 1e-9
assert abs(slope(r1) - (price(r1 + 1e-5) - price(r1 - 1e-5)) / 2e-5) < 1e-6   # slope = finite difference
assert all(price(i / 8) > price((i + 1) / 8) for i in range(-8, 8))            # strictly falling
assert all(abs(mc[r][0] - price(r)) < 4 * mc[r][1] for r in mc)
assert implied(11.00) is None
assert newton(11.00) < -1.0
assert implied(8.20) is None
assert abs(implied(HOUSE, sx=0.05) * 0.05 - implied(HOUSE, sx=0.15) * 0.15) < 1e-6
assert abs(sd / ((1 - 0.09) / sqrt(252)) - 1.0) < 0.15
print("All checks passed.")
