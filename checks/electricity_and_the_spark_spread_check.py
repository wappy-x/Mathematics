# Electricity and the spark spread -- the check behind the card.  Standard
# library only: the normal CDF, the integrator and the random numbers are all
# written here.  One gas plant's July: power forward 50 USD/MWh, gas 3.00
# USD/MMBtu, heat rate 7.5 MMBtu/MWh, variable cost 5 USD/MWh, six months out.
from math import exp, log, sqrt, cos, pi

R, HR, VOM, SP, SG, RHO, MW = 0.05, 7.5, 5.0, 0.50, 0.40, 0.70, 400.0

def N(x):                                   # normal CDF, Marsaglia's series
    if abs(x) > 9.0:
        return 0.0 if x < 0 else 1.0
    s, t, b, q, i = x, 0.0, x, x * x, 1.0
    while s != t:
        t = s; i += 2.0; b *= q / i; s = t + b
    return 0.5 + s * exp(-0.5 * q - 0.91893853320467274)
def black(F, K, vol, T):                    # undiscounted call on a forward
    sd = vol * sqrt(T)
    d1 = (log(F / K) + 0.5 * sd * sd) / sd
    return F * N(d1) - K * N(d1 - sd)
def kirk(P, f2, K, sp, sg, rho, T):         # road 1: Kirk's approximation
    b = f2 / (f2 + K)
    v = sqrt(sp * sp - 2.0 * rho * sp * sg * b + sg * sg * b * b)
    return exp(-R * T) * black(P, f2 + K, v, T)
def exact(P, f2, K, sp, sg, rho, T, n=600): # road 2: fix gas, Black on power,
    rt, h, tot = sqrt(T), 18.0 / n, 0.0     # Simpson's rule across gas outcomes
    for i in range(n + 1):
        z = -9.0 + i * h
        fuel = f2 * exp(-0.5 * sg * sg * T + sg * rt * z)
        pw = P * exp(-0.5 * rho * rho * sp * sp * T + rho * sp * rt * z)
        w = 1.0 if i in (0, n) else (4.0 if i % 2 else 2.0)
        tot += w * exp(-0.5 * z * z) * black(pw, fuel + K, sp * sqrt(1.0 - rho * rho), T)
    return exp(-R * T) * tot * h / 3.0 / sqrt(2.0 * pi)
state = 88172645463325252
def uniform():                              # xorshift64: own random numbers
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF
    state ^= state >> 7
    state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
def gauss():                                # Box-Muller, one normal per call
    u1, u2 = uniform(), uniform()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
def mc(P, f2, K, T, pairs):                 # road 3: simulate both prices
    tot = tot2 = 0.0
    for _ in range(pairs):
        a, c = gauss(), gauss()
        zg = RHO * a + sqrt(1.0 - RHO * RHO) * c
        pay = 0.0
        for s in (1.0, -1.0):               # antithetic pair: z and -z
            pw = P * exp(-0.5 * SP * SP * T + SP * sqrt(T) * s * a)
            fuel = f2 * exp(-0.5 * SG * SG * T + SG * sqrt(T) * s * zg)
            pay += 0.5 * max(pw - fuel - K, 0.0)
        tot += pay; tot2 += pay * pay
    m = tot / pairs
    return exp(-R * T) * m, exp(-R * T) * sqrt((tot2 / pairs - m * m) / pairs)
def row(label, v, d=4): print(f"{label:<40}{v:>14.{d}f}")
def july(K=VOM, f2=22.5, sp=SP, rho=RHO, P=50.0): return kirk(P, f2, K, sp, SG, rho, 0.5)

# 1. no carry: July power priced off today's spot by storage arithmetic
print(f"carry: spot today 30.00, spot x e^(rT) at T = 0.5 {30.0 * exp(R * 0.5):.4f}")
# 2. the July shape: 31 days from Thursday 1 July 2027, peak = weekdays HE7-HE22
wd = (2027 + 2027 // 4 - 2027 // 100 + 2027 // 400 + 5 + 1 + 6) % 7   # Sakamoto's rule, Mon = 0
peak_h = sum(1 for d in range(31) for hr in range(24) if (wd + d) % 7 < 5 and 6 <= hr <= 21)
off_px = (50.0 * 744 - 60.0 * peak_h) / (744 - peak_h)
print(f"shape: 1 July 2027 weekday {wd} (Mon = 0), peak hours {peak_h}, off-peak hours {744 - peak_h}"); row("shape: off-peak price", off_px)
# 3. spikes as jumps: daily log price reverts half-way each day, 4% chance of x5
KAP, SDD, PJ, JUMP = 0.5, 0.08, 0.04, log(5.0)
def mean_mult(t, pj):                       # E[e^x_t], exactly, day by day
    m = 1.0
    for s in range(t):
        c = (1.0 - KAP) ** (t - 1 - s)
        m *= exp(0.5 * c * c * SDD * SDD) * (1.0 - pj + pj * exp(c * JUMP))
    return m
level = 50.0 / (sum(mean_mult(t, PJ) for t in range(1, 32)) / 31)
calm = level * sum(mean_mult(t, 0.0) for t in range(1, 32)) / 31
def month():
    x, path = 0.0, []
    for _ in range(31):
        x = (1.0 - KAP) * x + SDD * gauss() + (JUMP if uniform() < PJ else 0.0)
        path.append(level * exp(x))
    return path
sims = [sum(month()) / 31 for _ in range(20000)]
sm = sum(sims) / len(sims); sse = sqrt(sum((v - sm) ** 2 for v in sims)) / len(sims)
row("spikes: calm-day level", level); row("spikes: forward with no spikes", calm); row("spikes: premium in the forward", 50.0 - calm)
row("spikes: forward, simulated", sm); row("spikes: simulation standard error", sse)
print("chart, one July of daily prices " + " ".join(f"{v:.2f}" for v in month()))
# 4. July, six months out, three roads
kj, ej = july(), exact(50.0, 22.5, VOM, SP, SG, RHO, 0.5)
mj, mse = mc(50.0, 22.5, VOM, 0.5, 100000)
row("July spark spread, P - HR x G", 50.0 - HR * 3.0, 2)
row("July 1 Kirk", kj); row("July 2 exact integral", ej); row("July 3 simulation", mj)
row("July   simulation standard error", mse)
row("July intrinsic e^(-rT)(27.50 - 5)", exp(-0.5 * R) * 22.5); row("July time value, Kirk - intrinsic", kj - exp(-0.5 * R) * 22.5)
b = 22.5 / 27.5; v = sqrt(SP * SP - 2 * RHO * SP * SG * b + SG * SG * b * b); d1 = (log(50 / 27.5) + 0.25 * v * v) / (v * sqrt(0.5))
hand = exp(-0.5 * R) * (50 * N(d1) - 27.5 * N(d1 - v * sqrt(0.5)))
print(f"Kirk by hand: b {b:.4f} vol {v:.4f} vol*sqrtT {v * sqrt(0.5):.4f} ln {log(50 / 27.5):.4f} d1 {d1:.4f} d2 {d1 - v * sqrt(0.5):.4f} N {N(d1):.5f} {N(d1 - v * sqrt(0.5)):.5f} disc {exp(-0.5 * R):.5f}")
print(f"July zero cost: Kirk {july(K=0.0):.4f}, exact {exact(50.0, 22.5, 0.0, SP, SG, RHO, 0.5):.4f}")
pk, pe = july(f2=45.0), exact(50.0, 45.0, VOM, SP, SG, RHO, 0.5)
print(f"peaker, heat rate 15, spread 5.00 = cost: Kirk {pk:.4f}, exact {pe:.4f}")
def house(K):                               # the spread-option card's crack spread
    b = 90.0 / (90.0 + K); v = sqrt(0.09 - 2 * 0.5 * 0.3 * 0.25 * b + 0.0625 * b * b)
    return exp(-R * 0.5) * black(100.0, 90.0 + K, v, 0.5)
row("house: Margrabe crack, strike 0", house(0.0)); row("house: Kirk crack, strike 10", house(10.0))
# 5. blocks: peak and off-peak priced apart, then hour-weighted
kp, ko = july(P=60.0), july(P=off_px)
row("blocks: peak option", kp); row("blocks: off-peak option", ko)
row("blocks: hour-weighted", (peak_h * kp + (744 - peak_h) * ko) / 744)
# 6. Greeks of the July option by bumping, both roads
for lab, f in (("Kirk", kirk), ("exact", exact)):
    dp = (f(50.01, 22.5, VOM, SP, SG, RHO, 0.5) - f(49.99, 22.5, VOM, SP, SG, RHO, 0.5)) / 0.02
    dg = (f(50.0, 22.5075, VOM, SP, SG, RHO, 0.5) - f(50.0, 22.4925, VOM, SP, SG, RHO, 0.5)) / 0.002
    dr = f(50.0, 22.5, VOM, SP, SG, 0.8, 0.5) - f(50.0, 22.5, VOM, SP, SG, 0.6, 0.5)
    print(f"greeks {lab:<6} power {dp:.4f}  gas {dg:.4f}  corr 0.6->0.8 {dr:.4f}")
# 7. the plant: a strip of monthly options, Feb 2027 to Jan 2028
strip = (("Feb", 52, 4.10, 672), ("Mar", 45, 3.60, 744), ("Apr", 40, 3.10, 720),
         ("May", 41, 2.90, 744), ("Jun", 46, 2.90, 720), ("Jul", 50, 3.00, 744),
         ("Aug", 52, 3.05, 744), ("Sep", 43, 2.95, 720), ("Oct", 40, 3.00, 744),
         ("Nov", 44, 3.40, 720), ("Dec", 55, 4.00, 744), ("Jan", 60, 4.40, 744))
tk = te = 0.0
for k, (mon, p, g, hrs) in enumerate(strip, 1):
    a, b = kirk(p, HR * g, VOM, SP, SG, RHO, k / 12), exact(p, HR * g, VOM, SP, SG, RHO, k / 12)
    tk += a * hrs * MW / 1e6; te += b * hrs * MW / 1e6
    print(f"strip {mon} T={k:>2}/12 P {p:5.2f} G {g:4.2f} spread {p - HR * g:6.2f}"
          f"  Kirk {a:7.4f} exact {b:7.4f}  USD m {a * hrs * MW / 1e6:6.3f}")
row("plant, 400 MW, one year, USD m, Kirk", tk); row("plant, 400 MW, one year, USD m, exact", te)
# 8. what breaks, and try-changing
row("wrong: July off carry forward", july(P=30.0 * exp(R * 0.5)))
row("wrong: correlation set to 0", july(rho=0.0))
row("try: gas 4.00, fuel 30", july(f2=30.0)); row("try: power vol 0.80", july(sp=0.80))
row("try: peaker, correlation 0.9", july(f2=45.0, rho=0.9))
print("chart, power at expiry  " + " ".join(f"{p:6.0f}" for p in range(20, 85, 5)))
print("chart, payoff at expiry " + " ".join(f"{max(p - 27.5, 0):6.2f}" for p in range(20, 85, 5)))
print("chart, value 6 m out    " + " ".join(f"{july(P=float(p)):6.2f}" for p in range(20, 85, 5)))
assert abs(kj - ej) < 0.001 and abs(pk - pe) < 0.01 and abs(hand - kj) < 1e-9, "Kirk by hand = code = integral"
assert abs(mj - ej) < 4 * mse, "simulation within four standard errors of the integral"
assert abs(house(0.0) - 13.15) < 0.005 and abs(house(10.0) - 7.43) < 0.005, "sibling card's numbers"
assert abs(sm - 50.0) < 4 * sse, "simulated spiky month averages to the exact forward"
assert wd == 3 and peak_h == 22 * 16, "1 July 2027 is a Thursday; 22 weekdays of 16 peak hours"
print("ALL CHECKS PASS")
