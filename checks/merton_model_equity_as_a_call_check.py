# Merton's model -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is the erf series written
# out, the integral is Simpson's rule, the tree is a loop, the random numbers
# come from a hand-written generator, the yield from a hand-written bisection.
from math import log, sqrt, exp, pi, cos

def N(x):                                    # bell-curve area left of x, erf series
    z = x / sqrt(2.0)
    if abs(z) > 5.0: return 1.0 if z > 0 else 0.0
    term, total, n = z, z, 0
    while abs(term) > 1e-18:
        n += 1
        term *= -z * z * (2 * n - 1) / (n * (2 * n + 1))
        total += term
    return 0.5 + total / sqrt(pi)

def merton(V, F, r, sig, T):                 # road 1: the call and put formulas
    w = sig * sqrt(T)
    d2 = (log(V / F) + (r - 0.5 * sig * sig) * T) / w
    d1 = d2 + w
    safe = F * exp(-r * T)
    E = V * N(d1) - safe * N(d2)             # equity: a call on the assets
    P = safe * N(-d2) - V * N(-d1)           # the lenders' short put
    return d1, d2, safe, E, P

def spread_bp(V, F, r, sig, T):
    d1, d2, safe, E, P = merton(V, F, r, sig, T)
    return (-log((V - E) / F) / T - r) * 1e4

def bisect(f, lo, hi):                       # a root of f between lo and hi
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) < 0) == (f(mid) < 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def simpson(f, a, b, n=4000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

V, F, T, sig, r, mu = 100.0, 80.0, 1.0, 0.20, 0.05, 0.08
d1, d2, safe, E, P = merton(V, F, r, sig, T)
B, B_put, PD = V - E, safe - P, N(-d2)
y = -log(B / F) / T
y_bis = bisect(lambda x: F * exp(-x * T) - B, -1.0, 1.0)

# road 2: average the maturity payoffs over the bell curve; no d1, d2 or N
VT = lambda z: V * exp((r - 0.5 * sig * sig) * T + sig * sqrt(T) * z)
phi = lambda z: exp(-0.5 * z * z) / sqrt(2.0 * pi)
zs = bisect(lambda z: VT(z) - F, -10.0, 10.0)            # where assets just cover the debt
D = exp(-r * T)
E_int = D * simpson(lambda z: (VT(z) - F) * phi(z), zs, 10.0)
B_int = D * (simpson(lambda z: VT(z) * phi(z), -10.0, zs) + simpson(lambda z: F * phi(z), zs, 10.0))
P_int = D * simpson(lambda z: (F - VT(z)) * phi(z), -10.0, zs)
PD_int = simpson(phi, -10.0, zs)
rec_int = simpson(lambda z: VT(z) * phi(z), -10.0, zs) / PD_int     # mean assets, given default

# road 3: a 2000-step coin-flip tree on the assets
def tree(payoff, disc, n=2000):
    dt = T / n; u = exp(sig * sqrt(dt)); d = 1.0 / u
    p = (exp(r * dt) - d) / (u - d); k = exp(-r * dt) if disc else 1.0
    v = [payoff(V * u ** j * d ** (n - j)) for j in range(n + 1)]
    for m in range(n, 0, -1):
        v = [k * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(m)]
    return v[0]
E_tree = tree(lambda a: max(a - F, 0.0), True)
PD_tree = tree(lambda a: 1.0 if a < F else 0.0, False)

# road 4: Monte Carlo, 200,000 draws from a hand-written generator (splitmix64)
state, M = 20260928, 200000
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((x ^ (x >> 31)) >> 11) * 2.0 ** -53
se, sq, nd = 0.0, 0.0, 0
for _ in range(M):
    z = sqrt(-2.0 * log(1.0 - uniform())) * cos(2.0 * pi * uniform())
    pay = max(VT(z) - F, 0.0)
    se += pay; sq += pay * pay; nd += VT(z) < F
E_mc, PD_mc = D * se / M, nd / M
E_se = D * sqrt((sq / M - (se / M) ** 2) / M)
PD_se = sqrt(PD_mc * (1.0 - PD_mc) / M)

rec = V * exp(r * T) * N(-d1) / N(-d2)      # mean assets given default, formula
wrong_E = V * N(d1) - F * N(d2)
w_mu = (log(V / F) + (mu - 0.5 * sig * sig) * T) / (sig * sqrt(T))
rows = [
    ("ln(V/F)", log(V / F)), ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("discount e^-rT", D), ("safe bond F e^-rT", safe),
    ("share leg V N(d1)", V * N(d1)), ("cash leg F e^-rT N(d2)", safe * N(d2)), ("recovery leg V N(-d1)", V * N(-d1)),
    ("1 equity, formula", E), ("2 equity, Simpson integral", E_int),
    ("3 equity, tree 2000 steps", E_tree), ("4 equity, Monte Carlo", E_mc), ("  its standard error", E_se),
    ("debt, V - E", B), ("debt, safe bond - put", B_put),
    ("debt, integral of min(V_T, F)", B_int), ("bond / riskless bond", B / safe),
    ("put, formula", P), ("put, integral", P_int),
    ("default prob, N(-d2)", PD), ("default prob, integral", PD_int),
    ("default prob, tree", PD_tree), ("default prob, Monte Carlo", PD_mc), ("  its standard error", PD_se),
    ("yield, -ln(B/F)/T", y), ("yield, bisection", y_bis), ("spread, bp", (y - r) * 1e4),
    ("mean assets given default, formula", rec), ("mean assets given default, integral", rec_int),
    ("recovery rate, share of F", rec / F), ("loss given default, share of F", 1 - rec / F),
    ("shortfall given default, F - mean", F - rec),
    ("put = e^-rT x PD x (F - mean assets)", D * PD * (F - rec)),
    ("rough spread PD x LGD, bp", PD * (1 - rec / F) * 1e4),
    ("wrong: no discount, equity", wrong_E), ("wrong: no discount, debt", V - wrong_E),
    ("wrong: safe x (1 - PD), debt", safe * (1 - PD)),
    ("wrong: simple yield, spread bp", ((F / B - 1) / T - r) * 1e4),
    ("real-world default prob, 8% drift", N(-w_mu)),
    ("try: sigma 0.40, equity", merton(V, F, r, 0.40, T)[3]), ("try: sigma 0.40, spread bp", spread_bp(V, F, r, 0.40, T)),
    ("try: F 90, spread bp", spread_bp(V, 90.0, r, sig, T)), ("try: V 80, spread bp", spread_bp(80.0, F, r, sig, T)),
    ("try: T 5, spread bp", spread_bp(V, F, r, sig, 5.0)), ("try: T 5, default prob", N(-merton(V, F, r, sig, 5.0)[1])),
]
for name, v in rows:
    print(f"{name:<38} {v:>14.6f}")
grid = [0.0, 20.0, 40.0, 60.0, 80.0, 100.0, 120.0, 140.0, 160.0]
print("chart, assets at maturity " + " ".join(f"{a:6.0f}" for a in grid))
print("chart, equity at maturity " + " ".join(f"{max(a - F, 0.0):6.0f}" for a in grid))
print("chart, debt at maturity   " + " ".join(f"{min(a, F):6.0f}" for a in grid))
print("bars, $m: equity, debt, put, safe " + " ".join(f"{x:.2f}" for x in (E, B, P, safe)))
today = [60.0 + 10.0 * i for i in range(9)]
print("chart, assets today       " + " ".join(f"{a:6.0f}" for a in today))
print("chart, equity today       " + " ".join(f"{merton(a, F, r, sig, T)[3]:6.2f}" for a in today))
print("chart, debt today         " + " ".join(f"{a - merton(a, F, r, sig, T)[3]:6.2f}" for a in today))

assert abs(E_int - E) < 1e-7 and abs(B_int - B) < 1e-7, "integral road vs the call formula"
assert abs(P_int - P) < 1e-7 and abs(B_put - B) < 1e-9, "put formula vs integral; two debt routes"
assert abs(E_tree - E) < 0.01 and abs(PD_tree - PD) < 0.005, "tree road"
assert abs(E_mc - E) < 4 * E_se and abs(PD_mc - PD) < 4 * PD_se, "Monte Carlo within 4 standard errors"
assert abs(PD_int - PD) < 1e-8 and abs(rec_int - rec) < 1e-6, "default prob and recovery, two roads"
assert abs(y_bis - y) < 1e-12 and abs((y - r) * 1e4 - 90.713) < 0.001, "yield two ways; the reference 90.713 bp"
print("ALL CHECKS PASS")
