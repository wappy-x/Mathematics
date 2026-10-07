# The exchange option (Margrabe) -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is a series written out, the integral is
# Simpson's rule, the random numbers are splitmix64 + Box-Muller, correlated by Cholesky.
from math import log, sqrt, exp, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)           # bell-curve height
def N(x):                                                       # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term = total = x; k = 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total

def eff_vol(s1, s2, rho): return sqrt(max(s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2, 0.0))

def margrabe(S1, S2, q1, q2, s1, s2, rho, T):                   # road 1: the formula, no r in it
    v = eff_vol(s1, s2, rho) * sqrt(T)
    A, B = S1 * exp(-q1 * T), S2 * exp(-q2 * T)
    if v == 0.0: return max(A - B, 0.0)
    d1 = (log(A / B) + 0.5 * v * v) / v
    return A * N(d1) - B * N(d1 - v)

def bs_call(S, K, r, q, sig, T):                                # the plain Black-Scholes call
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))

def conditional(r, rho, panels=4000):
    # road 2: fix share 2's shock z.  Share 1 is then lognormal with a known centre and spread,
    # so the inner average is exact; Simpson's rule does the outer one.  The bank rate r is used.
    w = s1 * sqrt((1.0 - rho * rho) * T)
    def f(z):
        X2 = S2 * exp((r - q2 - 0.5 * s2 * s2) * T + s2 * sqrt(T) * z)
        m = log(S1) + (r - q1 - 0.5 * s1 * s1) * T + s1 * rho * sqrt(T) * z
        d = (m - log(X2)) / w
        return (exp(m + 0.5 * w * w) * N(d + w) - X2 * N(d)) * phi(z)
    a, b = -10.0, 10.0; h = (b - a) / panels
    tot = f(a) + f(b)
    for i in range(1, panels):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * tot * h / 3.0

MASK = (1 << 64) - 1
def simulate(r, rho, paths=1000000):
    # road 3: correlated shares at expiry.  z1 = rho z2 + sqrt(1 - rho^2) z_other (Cholesky).
    state = 20260924; c = sqrt(1.0 - rho * rho); acc = acc2 = 0.0
    def uniform():
        nonlocal state
        state = (state + 0x9E3779B97F4A7C15) & MASK
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53
    m1, m2 = (r - q1 - 0.5 * s1 * s1) * T, (r - q2 - 0.5 * s2 * s2) * T
    for _ in range(paths):
        rad = sqrt(-2.0 * log(uniform())); ang = 2.0 * pi * uniform()
        z2, zo = rad * cos(ang), rad * sin(ang)
        z1 = rho * z2 + c * zo
        pay = max(S1 * exp(m1 + s1 * sqrt(T) * z1) - S2 * exp(m2 + s2 * sqrt(T) * z2), 0.0)
        acc += pay; acc2 += pay * pay
    mean = acc / paths
    return exp(-r * T) * mean, exp(-r * T) * sqrt((acc2 / paths - mean * mean) / paths)

# ---- two house shares: $100 each, 20% vol, 2% dividend, correlation 0.5; 5% rate, 1 year ----
S1, S2, q1, q2, s1, s2, rho, r, T = 100.0, 100.0, 0.02, 0.02, 0.20, 0.20, 0.5, 0.05, 1.0
sig = eff_vol(s1, s2, rho)
A, B = S1 * exp(-q1 * T), S2 * exp(-q2 * T)
d1 = (log(A / B) + 0.5 * sig * sig * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
V = margrabe(S1, S2, q1, q2, s1, s2, rho, T)
V_cond, V_cond0, V_cond10 = conditional(r, rho), conditional(0.0, rho), conditional(0.10, rho)
V_mc, se = simulate(r, rho)
V_mc1, _ = simulate(r, 1.0, 20000)
cash = 100.0 * exp(-r * T)                              # a zero-coupon bond paying $100 at T
V_cash = margrabe(S1, cash, q1, 0.0, s1, 0.0, 0.0, T)
C_bs = bs_call(S1, 100.0, r, q1, s1, T)
h = 0.01
g = lambda a, b: margrabe(a, b, q1, q2, s1, s2, rho, T)
dl1 = (g(S1 + h, S2) - g(S1 - h, S2)) / (2 * h); dl2 = (g(S1, S2 + h) - g(S1, S2 - h)) / (2 * h)
vega = (margrabe(S1, S2, q1, q2, s1 + h, s2, rho, T) - margrabe(S1, S2, q1, q2, s1 - h, s2, rho, T)) / 2.0
corr = (margrabe(S1, S2, q1, q2, s1, s2, rho + h, T) - margrabe(S1, S2, q1, q2, s1, s2, rho - h, T)) / 2.0
gam = (g(S1 + 1.0, S2) - 2.0 * V + g(S1 - 1.0, S2))

rows = [
    ("effective variance sigma^2", sig * sig), ("effective vol sigma", sig), ("effective vol, rho = -1", eff_vol(s1, s2, -1.0)),
    ("share 1 today, S1 e^-q1T", A), ("share 2 today, S2 e^-q2T", B),
    ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("Acme half", A * N(d1)), ("Birch half", B * N(d2)),
    ("1 Margrabe formula", V), ("2 conditional integral, r = 5%", V_cond),
    ("3 simulation, 1000000 pairs", V_mc), ("  standard error", se),
    ("  conditional integral, r = 0%", V_cond0), ("  conditional integral, r = 10%", V_cond10),
    ("rho = 1, formula", margrabe(S1, S2, q1, q2, s1, s2, 1.0, T)), ("rho = 1, simulation", V_mc1),
    ("cash case: Margrabe, bond S2 = 95.12", V_cash), ("cash case: Black-Scholes call", C_bs),
    ("delta 1, bump", dl1), ("  e^-q1T N(d1)", A / S1 * N(d1)),
    ("delta 2, bump", dl2), ("  -e^-q2T N(d2)", -B / S2 * N(d2)),
    ("S1 delta1 + S2 delta2", S1 * dl1 + S2 * dl2), ("gamma 1, per $1", gam),
    ("vega of share 1, per vol point", vega), ("correlation, per 0.01", corr),
    ("wrong: correlation left out", margrabe(S1, S2, q1, q2, s1, s2, 0.0, T)),
    ("wrong: +2 rho instead of -2 rho", margrabe(S1, S2, q1, q2, sqrt(0.12), 0.0, 0.0, T)),
    ("wrong: rho s1 s2 without the 2", margrabe(S1, S2, q1, q2, sqrt(0.06), 0.0, 0.0, T)),
    ("wrong: share 2 as a fixed $100 strike", C_bs),
    ("wrong: dividends dropped", margrabe(S1, S2, 0.0, 0.0, s1, s2, rho, T)),
    ("try: rho = -1", margrabe(S1, S2, q1, q2, s1, s2, -1.0, T)),
    ("try: S1 = 110", margrabe(110.0, S2, q1, q2, s1, s2, rho, T)),
    ("try: share 2 vol 30%", margrabe(S1, S2, q1, q2, s1, 0.30, rho, T)),
]
for name, v in rows:
    print(f"{name:<40} {v:>12.6f}")
rhos = [-1.0 + 0.25 * i for i in range(9)]
print("chart, correlation " + " ".join(f"{x:6.2f}" for x in rhos))
print("chart, price       " + " ".join(f"{margrabe(S1, S2, q1, q2, s1, s2, x, T):6.2f}" for x in rhos))
ends = [80.0 + 5.0 * i for i in range(11)]
print("chart, share 1 end " + " ".join(f"{x:6.0f}" for x in ends))
for e2 in (100.0, 110.0):
    print(f"chart, profit {e2:.0f}  " + " ".join(f"{max(x - e2, 0.0) - V:6.2f}" for x in ends))

assert abs(V - 7.807839) < 1e-6,                  "formula vs the shelf's house number"
assert abs(V_cond - V) < 1e-8,                    "conditional integral lands on the formula"
assert abs(V_mc - V) < 4.0 * se,                  "simulation within four standard errors"
assert abs(V_cond10 - V) < 1e-8,                 "bank rate 10%: same price"
assert abs(V_cond0 - V) < 1e-8,                  "bank rate 0%: same price"
assert abs(V_cash - 9.227005508154) < 1e-9,       "cash case is the house vanilla"
assert V_mc1 == 0.0,                              "perfect correlation: every simulated payoff is zero"
assert abs(S1 * dl1 + S2 * dl2 - V) < 1e-6,       "the price is shares only: Euler's identity"
print("ALL CHECKS PASS")
