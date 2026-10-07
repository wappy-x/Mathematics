# Ruin and Lundberg's inequality -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the integrator, the root finder, the series
# and the random numbers are all written out below.
from math import exp, log, sqrt

LAM, B, THETA, U = 10.0, 10_000.0, 0.10, 1_000_000.0   # claims a year, mean claim $, loading, surplus $
C = (1.0 + THETA) * LAM * B                            # premium income, $ a year

def mgf(r, b, n=20000):
    # Road 2 for M_X(r) = E[e^{rX}]: Simpson's rule on e^{rx} times the exponential density.
    k = 1.0 / b - r                                     # net decay rate of the integrand
    top = 60.0 / k                                      # e^{-60} of the mass lies beyond
    h = top / n
    f = lambda x: exp(r * x) * exp(-x / b) / b
    s = f(0.0) + f(top)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(i * h)
    return s * h / 3.0

def kappa(r, lam, b, c):                                # claims side minus premium side
    return lam * (mgf(r, b) - 1.0) - c * r

def bisect(g, lo, hi, iters=80):                        # g(lo) < 0 < g(hi)
    for _ in range(iters):
        mid = 0.5 * (lo + hi)
        if g(mid) < 0.0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def psi_exact(u, b, theta):                             # closed form, exponential claims
    return exp(-theta * u / ((1.0 + theta) * b)) / (1.0 + theta)

def psi_series(u, b, theta, nmax=3000):
    # Road 2 for psi: Pollaczek-Khinchine.  Ruin = the record drops add past u.
    # A record drop happens with chance p = 1/(1+theta); for exponential claims each
    # drop is exponential with mean b, so n drops exceed u with an Erlang tail.
    p, x = 1.0 / (1.0 + theta), u / b
    pois, tail, pn, total = exp(-x), 0.0, 1.0, 0.0
    for n in range(1, nmax + 1):
        tail += pois                                    # P(n drops > u) = sum_{k<n} e^-x x^k/k!
        pois *= x / n
        pn *= p
        total += (1.0 - p) * pn * tail
    return total

MASK = (1 << 64) - 1
def uniforms(seed):                                     # xorshift64*, written out
    s = seed
    while True:
        s ^= s >> 12; s ^= (s << 25) & MASK; s ^= s >> 27
        yield (((s * 0x2545F4914F6CDD1D) & MASK) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0

def psi_monte_carlo(u, lam, b, c, paths, cap, seed=20260928):
    # Road 3: run surplus paths claim by claim; stop at ruin or once surplus passes cap.
    g, ruined = uniforms(seed), 0
    for _ in range(paths):
        s = u
        while 0.0 <= s < cap:
            s += c * (-log(next(g)) / lam) + b * log(next(g))
        ruined += s < 0.0
    return ruined / paths

# ---- the adjustment coefficient, two roads ----
R1 = THETA / ((1.0 + THETA) * B)                        # closed form for exponential claims
R2 = bisect(lambda r: kappa(r, LAM, B, C), 1e-3 / B, 0.5 / B)
bound, exact, series = exp(-R1 * U), psi_exact(U, B, THETA), psi_series(U, B, THETA)
cap_bound = log(100.0) / R1
cap_exact = log(100.0 / (1.0 + THETA)) / R1
cap_series = bisect(lambda u: 0.01 - psi_series(u, B, THETA), 0.0, 2e6)

# ---- same 10% loading, claims ten times bigger ----
B2 = 100_000.0; C2 = (1.0 + THETA) * LAM * B2
bound2, exact2, series2 = exp(-THETA / ((1 + THETA) * B2) * U), psi_exact(U, B2, THETA), psi_series(U, B2, THETA)
N = 20000
mc2 = psi_monte_carlo(U, LAM, B2, C2, N, U + 10e6)
se2 = sqrt(mc2 * (1.0 - mc2) / N)

# ---- what breaks ----
R_diff = 2.0 * (C - LAM * B) / (LAM * 2.0 * B * B)     # mean-and-variance only: 2(c - lam mu)/(lam E[X^2])

assert abs(R2 / R1 - 1.0) < 1e-9, "root finder disagrees with closed form"
assert abs(series / exact - 1.0) < 1e-9 and abs(series2 / exact2 - 1.0) < 1e-9, "series disagrees"
assert abs(mc2 - exact2) < 4.0 * se2, "simulation disagrees with exact ruin chance"
assert exact < bound < 0.01 and exact2 < bound2, "Lundberg bound fails"
assert abs(cap_series / cap_exact - 1.0) < 1e-9, "capital by series disagrees"

rows = [
    ("R closed form, per $1M", R1 * 1e6), ("R bisection on Simpson MGF, per $1M", R2 * 1e6),
    ("1/R, dollars", 1.0 / R1), ("M_X(R)", mgf(R1, B)), ("R u", R1 * U),
    ("Lundberg bound e^-Ru", bound), ("exact psi, closed form", exact),
    ("exact psi, Pollaczek-Khinchine series", series), ("bound / exact", bound / exact),
    ("capital for 1%, by the bound $", cap_bound), ("capital for 1%, exact $", cap_exact),
    ("capital for 1%, series + bisection $", cap_series), ("extra capital, bound over exact $", cap_bound - cap_exact),
    ("mean $100k: R per $1M", THETA / ((1 + THETA) * B2) * 1e6), ("mean $100k: bound", bound2),
    ("mean $100k: exact, closed form", exact2), ("mean $100k: exact, series", series2),
    ("mean $100k: simulation, 20000 paths", mc2), ("mean $100k: simulation std error", se2),
    ("wrong: root R = 0, bound", exp(-0.0 * U)), ("wrong: no loading, exact psi", psi_exact(U, B, 0.0)),
    ("wrong: mean-variance R, per $1M", R_diff * 1e6), ("wrong: mean-variance bound", exp(-R_diff * U)),
    ("try: loading 20%, bound", exp(-0.2 / (1.2 * B) * U)), ("try: surplus $500k, bound", exp(-R1 * 500_000.0)),
    ("try: mean $50k, bound", exp(-THETA / ((1 + THETA) * 50_000.0) * U)),
    ("try: 20 claims/yr, premium x2, R per $1M", 1e6 * bisect(lambda r: kappa(r, 20.0, B, 2 * C), 1e-3 / B, 0.5 / B)),
]
for name, v in rows:
    print(f"{name:<42} {v:>16.9f}")

print()
print("chart: ruin chance in percent, surplus in $ thousands")
print(f"{'u':>6} {'bound %':>9} {'exact %':>9}")
for k in range(11):
    u = 100_000.0 * k
    print(f"{100 * k:>6} {100 * exp(-R1 * u):>9.2f} {100 * psi_exact(u, B, THETA):>9.2f}")
print()
print("chart: two sides of the adjustment equation, per year; r per $1M")
print(f"{'r':>6} {'claims':>9} {'premium':>9}")
for r in range(0, 15, 2):
    print(f"{r:>6} {LAM * (mgf(r / 1e6, B) - 1.0):>9.2f} {C * r / 1e6:>9.2f}")
