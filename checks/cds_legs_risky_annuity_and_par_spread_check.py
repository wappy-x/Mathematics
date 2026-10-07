# Pricing a CDS -- the check behind the card.  Standard library only.
# Northwind five-year CDS: notional $10m, quarterly premiums, hazard 2% flat,
# recovery 40%, riskless rate 5% continuously compounded.  Nothing imported
# knows the answer: the integrator, root finder and random numbers are below.
from math import exp, log, sqrt

NOTIONAL, T, DELTA, LAM, R, RATE = 10_000_000.0, 5.0, 0.25, 0.02, 0.40, 0.05

def simpson(f, a, b, n=2000):                    # area under f from a to b, n even
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

def dates(delta):                                # premium dates delta, 2 delta, ..., T
    return [delta * (j + 1) for j in range(round(T / delta))]

def legs(D, Q, h, delta=DELTA):                  # road 2: dated sum and quadrature, any curves
    A = sum(delta * D(t) * Q(t) for t in dates(delta))
    P = (1 - R) * simpson(lambda t: h(t) * Q(t) * D(t), 0.0, T)
    acc = sum(simpson(lambda t: (t - a) * h(t) * Q(t) * D(t), a, a + delta, 200)
              for a in [t - delta for t in dates(delta)])
    return A, P, acc

def closed(delta=DELTA, lam=LAM):                # road 1: flat curves, geometric series
    c = RATE + lam
    x = exp(-c * delta)
    n = round(T / delta)
    A = delta * x * (1 - x ** n) / (1 - x)
    P = (1 - R) * lam * (1 - exp(-c * T)) / c
    return A, P, (1 - exp(-c * T)) / c           # last: the continuous-premium annuity

def bisect(f, lo, hi):                           # root finder: halve the bracket 100 times
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return 0.5 * (lo + hi)

state = 20260928
def uniform():                                   # splitmix64, then 53 bits into (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

def monte_carlo(D, tau_of, paths=400_000):       # road 3: draw default dates, pay cash
    A = P = AA = PP = AP = 0.0
    for _ in range(paths):
        tau = tau_of(-log(uniform()))            # cumulative hazard reached at default
        prem = sum(DELTA * D(t) for t in dates(DELTA) if t < tau)
        pay = (1 - R) * D(tau) if tau <= T else 0.0
        A, P, AA, PP, AP = A + prem, P + pay, AA + prem * prem, PP + pay * pay, AP + prem * pay
    s = P / A                                    # std error of the spread P/A, from pay - s * prem
    se = sqrt(PP - 2 * s * AP + s * s * AA) / A  # = sqrt(variance / paths) / mean annuity
    return A / paths, P / paths, se

flat_D, flat_Q, flat_h = (lambda t: exp(-RATE * t)), (lambda t: exp(-LAM * t)), (lambda t: LAM)
A1, P1, Ac = closed()
A2, P2, acc = legs(flat_D, flat_Q, flat_h)
s1, s2 = P1 / A1, P2 / A2
s_root = bisect(lambda s: P2 - s * A2, 0.0, 1.0)
A_int = simpson(lambda t: flat_D(t) * flat_Q(t), 0.0, T)       # premiums paid every instant
A3, P3, se3 = monte_carlo(flat_D, lambda e: e / LAM)
bp = 1e4
rows = [("annuity, closed form", A1), ("annuity, dated sum", A2), ("annuity, simulation", A3),
        ("protection, closed form", P1), ("protection, Simpson", P2), ("protection, simulation", P3),
        ("par spread bp, closed form", s1 * bp), ("par spread bp, dated/Simpson", s2 * bp),
        ("par spread bp, root finder", s_root * bp), ("par spread bp, simulation", P3 / A3 * bp),
        ("  simulation std error, bp", se3 * bp), ("  simulation paths", 400_000),
        ("continuous annuity, closed form", Ac), ("continuous annuity, Simpson", A_int),
        ("par spread bp, continuous", P1 / A_int * bp),
        ("(1-R) x hazard, bp", (1 - R) * LAM * bp),
        ("accrual per unit spread", acc), ("par spread bp, with accrual", P2 / (A2 + acc) * bp),
        ("D(5) e^-rT", flat_D(T)), ("Q(5) e^-lambda T", flat_Q(T)), ("default chance by 5y", 1 - flat_Q(T)),
        ("D(5)Q(5) e^-(r+lambda)T", exp(-(RATE + LAM) * T)), ("1 - e^-(r+lambda)T", 1 - exp(-(RATE + LAM) * T)),
        ("x = e^-(r+lambda)/4", exp(-(RATE + LAM) * DELTA)), ("1 - x", 1 - exp(-(RATE + LAM) * DELTA)),
        ("$ protection leg on $10m", P1 * NOTIONAL), ("$ one bp of premium, PV", A1 * NOTIONAL / bp),
        ("$ quarterly premium at par", s1 * DELTA * NOTIONAL)]
A_rl = sum(DELTA * flat_D(t) for t in dates(DELTA))
rows += [("wrong: no survival in annuity", P1 / A_rl * bp), ("  riskless annuity", A_rl),
         ("wrong: protection undiscounted", (1 - R) * (1 - flat_Q(T)) / A1 * bp),
         ("wrong: R in place of 1-R", R / (1 - R) * s1 * bp),
         ("wrong: full spread each quarter", P1 / (A1 / DELTA) * bp)]
for name, delta in (("annual", 1.0), ("semiannual", 0.5), ("quarterly", 0.25), ("monthly", 1 / 12)):
    Af, Pf, _ = closed(delta)
    rows.append((f"spread bp, {name} premiums", Pf / Af * bp))
rows += [("try: hazard 4%", closed(lam=0.04)[1] / closed(lam=0.04)[0] * bp),
         ("try: hazard 0", closed(lam=0.0)[1] / closed(lam=0.0)[0] * bp)]
# a general curve: zero rate 3% rising 0.6% a year, hazard 1% rising 0.4% a year
g_D = lambda t: exp(-(0.03 + 0.006 * t) * t)
g_Q = lambda t: exp(-(0.01 * t + 0.002 * t * t))
g_h = lambda t: 0.01 + 0.004 * t
gA2, gP2, _ = legs(g_D, g_Q, g_h)
gA3, gP3, gse3 = monte_carlo(g_D, lambda e: (-0.01 + sqrt(0.0001 + 0.008 * e)) / 0.004)
rows += [("curve: annuity, dated sum", gA2), ("curve: annuity, simulation", gA3),
         ("curve: protection, Simpson", gP2), ("curve: protection, simulation", gP3),
         ("curve: par spread bp", gP2 / gA2 * bp), ("curve: spread bp, simulation", gP3 / gA3 * bp),
         ("  simulation std error, bp", gse3 * bp)]
for name, v in rows:
    print(f"{name:<34} {v:>16.6f}")
print()
print("chart, spread bp       " + " ".join(f"{s:7d}" for s in range(0, 241, 40)))
print("chart, premium leg $k  " + " ".join(f"{s / bp * A1 * NOTIONAL / 1e3:7.2f}" for s in range(0, 241, 40)))
print("chart, protection $k   " + " ".join(f"{P1 * NOTIONAL / 1e3:7.2f}" for s in range(0, 241, 40)))
print("chart, year            " + " ".join(f"{y:7d}" for y in range(1, 6)))
print("chart, D(t)Q(t)        " + " ".join(f"{flat_D(y) * flat_Q(y):7.2f}" for y in range(1, 6)))
print("chart, D(t)            " + " ".join(f"{flat_D(y):7.2f}" for y in range(1, 6)))
assert abs(A2 - A1) < 1e-12 and abs(P2 - P1) < 1e-10, "dated sum and Simpson vs closed form"
assert abs(s_root - s1) < 1e-12, "root finder lands on protection / annuity"
assert abs(P3 / A3 - s1) < 4 * se3, "simulation within four standard errors"
assert abs(gP3 / gA3 - gP2 / gA2) < 4 * gse3, "general curve: simulation vs quadrature"
assert abs(P1 / A_int - (1 - R) * LAM) < 1e-12, "closed protection / Simpson annuity = (1-R) x hazard"
print("ALL CHECKS PASS")
