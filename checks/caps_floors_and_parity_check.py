# Caps and floors: a 2-year cap at 5% on 3-month rates, 30% lognormal volatility.
# Roads: Black-76 per caplet; Simpson integral of each payoff; Monte Carlo; parity from discount factors.
from math import exp, log, sqrt, cos, pi

NOTIONAL, TAU, K, SIG = 10_000_000.0, 0.25, 0.05, 0.30
FWD = [0.044 + 0.0005 * i for i in range(8)]       # 3-month forward rates, today's curve
D = [1.0]                                           # D[i] = discount factor to T_i = 0.25 i
for f in FWD:
    D.append(D[-1] / (1.0 + TAU * f))
CAPLETS = range(1, 8)                               # period 0 fixes today at 4.40%: no option left

def ncdf(x):                                        # N(x) = 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + exp(-0.5 * x * x) / sqrt(2.0 * pi) * total

def black(F, strike, sig, T, call):                 # Black-76 per unit of rate, undiscounted
    v = sig * sqrt(T)
    d1 = (log(F / strike) + 0.5 * v * v) / v
    d2 = d1 - v
    return F * ncdf(d1) - strike * ncdf(d2) if call else strike * ncdf(-d2) - F * ncdf(-d1)

def strip(strike=K, sig=SIG, call=True, bump=0.0, pay_lag=1, vol_lag=0):
    return [NOTIONAL * TAU * D[i + pay_lag] * black(FWD[i] + bump, strike, sig, TAU * (i + vol_lag), call)
            for i in CAPLETS]

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if j % 2 else 2) * f(a + j * h) for j in range(1, n)))

def by_integral(i, call):                           # E[payoff] with the fixing lognormal around F_i
    F, v = FWD[i], SIG * sqrt(TAU * i)
    rate = lambda z: F * exp(-0.5 * v * v + v * z)
    dens = lambda z: exp(-0.5 * z * z) / sqrt(2.0 * pi)
    zk = (log(K / F) + 0.5 * v * v) / v             # the kink: fixing equals the strike
    if call: val = simpson(lambda z: (rate(z) - K) * dens(z), zk, 10.0)
    else: val = simpson(lambda z: (K - rate(z)) * dens(z), -10.0, zk)
    return NOTIONAL * TAU * D[i + 1] * val

state = [20260928]
def uniform():                                      # 64-bit linear congruential generator
    state[0] = (6364136223846793005 * state[0] + 1442695040888963407) % 2**64
    return ((state[0] >> 11) + 0.5) / 2.0**53

def monte_carlo(paths=200_000):
    total = 0.0
    for _ in range(paths // 2):
        z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
        for i in CAPLETS:
            F, v = FWD[i], SIG * sqrt(TAU * i)
            for s in (z, -z):
                total += TAU * D[i + 1] * max(F * exp(-0.5 * v * v + v * s) - K, 0.0)
    return NOTIONAL * total / paths

cl, fl = strip(), strip(call=False)
cap, floor = sum(cl), sum(fl)
cap_int = sum(by_integral(i, True) for i in CAPLETS)
floor_int = sum(by_integral(i, False) for i in CAPLETS)
cap_mc = monte_carlo()
A = sum(TAU * D[i + 1] for i in CAPLETS)            # annuity: value of 1 per year paid quarterly
S = (D[1] - D[8]) / A                               # forward swap rate, periods 1 to 7
swap = NOTIONAL * ((D[1] - D[8]) - K * A)           # pay 5% fixed, receive floating, periods 1 to 7
cap_S, floor_S = sum(strip(strike=S)), sum(strip(strike=S, call=False))

bp = 0.0001
dcap = sum(NOTIONAL * TAU * D[i + 1] * ncdf((log(FWD[i] / K) + 0.5 * SIG**2 * TAU * i) / (SIG * sqrt(TAU * i))) * bp for i in CAPLETS)
dcap_b = (sum(strip(bump=bp / 2)) - sum(strip(bump=-bp / 2)))
dfl_b = (sum(strip(call=False, bump=bp / 2)) - sum(strip(call=False, bump=-bp / 2)))
vcap_b = (sum(strip(sig=SIG + 0.005)) - sum(strip(sig=SIG - 0.005)))
vfl_b = (sum(strip(sig=SIG + 0.005, call=False)) - sum(strip(sig=SIG - 0.005, call=False)))

p = lambda label, v: print(f"{label:<40}{v:>16.2f}")
q = lambda label, v: print(f"{label:<40}{v:>16.6f}")
for i in CAPLETS:
    print(f"caplet {i}  fix {TAU*i:.2f}y  F {100*FWD[i]:.2f}%  D {D[i+1]:.6f}{cl[i-1]:>11.2f}{fl[i-1]:>11.2f}")
v7 = SIG * sqrt(1.75); d1 = (log(FWD[7] / K) + 0.5 * v7 * v7) / v7
q("caplet 7: sigma sqrt(T)", v7); q("caplet 7: d1", d1); q("caplet 7: d2", d1 - v7)
q("caplet 7: N(d1)", ncdf(d1)); q("caplet 7: N(d2)", ncdf(d1 - v7))
q("caplet 7: F N(d1) - K N(d2), percent", 100 * black(FWD[7], K, SIG, 1.75, True))
p("1 cap, Black strip", cap); p("2 cap, Simpson integral", cap_int); p("3 cap, Monte Carlo 200000", cap_mc)
q("cap, percent of notional", 100 * cap / NOTIONAL)
p("floor, Black strip", floor); p("floor, Simpson integral", floor_int)
q("annuity A", A); q("forward swap rate S, percent", 100 * S)
p("cap - floor (integral road)", cap_int - floor_int); p("4 payer swap from D(T)", swap)
p("cap at strike S", cap_S); p("floor at strike S", floor_S)
q("running premium, percent a year", 100 * cap / NOTIONAL / A)
q("worst all-in rate, percent", 100 * (K + cap / NOTIONAL / A))
p("delta cap per 1bp, N(d1)", dcap); p("delta cap per 1bp, bump", dcap_b); p("delta floor per 1bp, bump", dfl_b)
p("  delta difference", dcap_b - dfl_b); p("  annuity x 1bp x notional", A * bp * NOTIONAL)
p("vega cap per vol point, bump", vcap_b); p("vega floor per vol point, bump", vfl_b)
p("wrong: discount to the reset date", sum(strip(pay_lag=0)))
p("wrong: volatility to the payment date", sum(strip(vol_lag=1)))
p("wrong: one option, swaption at 0.25y", NOTIONAL * A * black(S, K, SIG, 0.25, True))
p("wrong: parity read as receiver swap", -swap)
fix = (3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0)
print("chart fixing, %  " + "".join(f"{x:>9.1f}" for x in fix))
print("chart cap pays   " + "".join(f"{NOTIONAL * TAU * max(x / 100 - K, 0):>9.2f}" for x in fix))
print("chart floor pays " + "".join(f"{NOTIONAL * TAU * max(K - x / 100, 0):>9.2f}" for x in fix))
for ks in (3.5, 4.0, 4.5, 5.0, 5.5, 6.0):
    c, f = sum(strip(strike=ks / 100)), sum(strip(strike=ks / 100, call=False))
    print(f"chart strike {ks:.1f}%  cap {100*c/NOTIONAL:.2f}%  floor {100*f/NOTIONAL:.2f}%")
p("try: volatility 20%", sum(strip(sig=0.20))); p("try: strike 6%", sum(strip(strike=0.06)))
p("try: every forward up 1%", sum(strip(bump=0.01)))

assert abs(cap - cap_int) < 1e-4, "Black strip vs integral of the payoff"
assert abs(cap_mc - cap) < 0.01 * cap, "Monte Carlo within 1 percent"
assert abs((cap_int - floor_int) - swap) < 1e-4, "parity: integral cap minus floor vs swap from discount factors"
assert abs(cap_S - floor_S) < 1e-6, "cap equals floor at the swap rate"
assert abs((dcap_b - dfl_b) - A * bp * NOTIONAL) < 1e-3, "delta gap equals the annuity"
assert abs(dcap - dcap_b) < 1e-3, "N(d1) delta vs bump"
print("ALL CHECKS PASS")
