# Piecewise-flat hazard curve -- the check behind the card.  Standard library
# only.  A used van's breakdown hazard is 2% a year in year 1, 4% in years 2-3
# and 6% in years 4-5.  Survival is reached four ways: e to the minus the area
# under the steps, a slice product with no exp in it, Simpson's rule on the
# default density, and 100,000 simulated vans flipping a monthly coin drawn
# from a hand-written random number generator.
from math import exp, log, sqrt

NODES = [0.0, 1.0, 3.0, 5.0]           # node dates, in years
RATES = [0.02, 0.04, 0.06]             # the flat hazard on each piece, per year

def rate(t, rates=RATES):              # the hazard at date t; the last rate runs on past year 5
    for i in range(len(rates) - 1):
        if t < NODES[i + 1]:
            return rates[i]
    return rates[-1]

def area(t, rates=RATES):              # road 1: cumulative hazard, rate times overlap, piece by piece
    total = 0.0
    for i, lam in enumerate(rates):
        lo = NODES[i]
        hi = NODES[i + 1] if i < len(rates) - 1 else 1e9
        if t > lo:
            total += lam * (min(t, hi) - lo)
    return total

def S(t, rates=RATES):                 # survival to date t
    return exp(-area(t, rates))

def slice_curve(per_year, rates=RATES):   # road 2: survive each thin slice in turn; no exp
    dt, p, out = 1.0 / per_year, 1.0, [1.0]
    for year in range(5):
        for k in range(per_year):
            p *= 1.0 - rate(year + (k + 0.5) * dt, rates) * dt
        out.append(p)
    return out

def simpson(f, a, b, n=200):           # road 3: area under a smooth curve, parabola by parabola
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def vans(n, seed):                     # road 4: monthly coin flips; no exp, no log
    p = [rate((m + 0.5) / 12.0) / 12.0 for m in range(60)]
    died, x = [0] * 5, seed
    for _ in range(n):
        for m in range(60):
            x = (6364136223846793005 * x + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
            if (x >> 11) / 9007199254740992.0 < p[m]:
                died[m // 12] += 1
                break
    return died

def loglin(t, a, b):                   # survival read between nodes a and b along a straight line in ln S
    w = (t - a) / (b - a)
    return exp((1 - w) * log(S(a)) + w * log(S(b)))

def linear(t, a, b):                   # the mistake: a straight line in S itself
    w = (t - a) / (b - a)
    return (1 - w) * S(a) + w * S(b)

YEARS = range(6)
surv = [S(t) for t in YEARS]
slc = slice_curve(100000)
died = [surv[y - 1] - surv[y] for y in range(1, 6)]
simp = [simpson(lambda t, lam=rate(y - 1): lam * S(t), y - 1.0, float(y)) for y in range(1, 6)]
N_VANS = 100000
counts = vans(N_VANS, 1)
mc = [1.0 - sum(counts[:y]) / N_VANS for y in YEARS]
se5 = sqrt(mc[5] * (1 - mc[5]) / N_VANS)
node_S = [S(t) for t in NODES]
avg = [-log(node_S[i]) / NODES[i] for i in range(1, 4)]
spot_from_S = [-log(node_S[i + 1] / node_S[i]) / (NODES[i + 1] - NODES[i]) for i in range(3)]
spot_from_avg = [(avg[i] * NODES[i + 1] - (avg[i - 1] * NODES[i] if i else 0.0))
                 / (NODES[i + 1] - NODES[i]) for i in range(3)]

print("year  Lambda(t)  S(t)      S slices  avg rate  spot rate  died in yr  Simpson   vans")
for y in YEARS:
    if y == 0:
        print(f"{y:>4}  {area(y):.6f}  {surv[y]:.6f}  {slc[y]:.6f}  {'':>8}  {'':>9}  {'':>10}  {'':>8}  {mc[y]:.6f}")
    else:
        print(f"{y:>4}  {area(y):.6f}  {surv[y]:.6f}  {slc[y]:.6f}  {area(y) / y:.6f}  {rate(y - 0.5):.6f}"
              f"   {died[y - 1]:.6f}  {simp[y - 1]:.6f}  {mc[y]:.6f}")
rows = [
    ("vans: one standard error at 5 years", se5),
    ("default by 5, 1 - S(5)", 1 - surv[5]),
    ("year 4 given alive at 3, 1 - e^-0.06", 1 - S(4) / S(3)),
    ("vans: died in year 4", counts[3] / N_VANS),
    ("log-linear S(2) from S(1), S(3)", loglin(2, 1, 3)),
    ("log-linear S(4) from S(3), S(5)", loglin(4, 3, 5)),
    ("piece areas: 1", RATES[0] * (NODES[1] - NODES[0])), ("  2", RATES[1] * (NODES[2] - NODES[1])),
    ("  3", RATES[2] * (NODES[3] - NODES[2])),
    ("Lambda(2.5)", area(2.5)), ("w at 2 years, from node 1 to node 3", (2 - 1) / (3 - 1)),
    ("S(2.5) on the curve", S(2.5)),
    ("average rate to 1, 3, 5: 1", avg[0]), ("  3", avg[1]), ("  5", avg[2]),
    ("spots from node survivals: 1", spot_from_S[0]), ("  2", spot_from_S[1]), ("  3", spot_from_S[2]),
    ("spots from the averages: 1", spot_from_avg[0]), ("  2", spot_from_avg[1]), ("  3", spot_from_avg[2]),
    ("ageing: alive at 3, survives to 5", S(5) / S(3)),
    ("ageing: new van survives 2 years", S(2)),
    ("wrong: linear S(2)", linear(2, 1, 3)),
    ("wrong: linear S(4)", linear(4, 3, 5)),
    ("wrong: year 5 hazard = 4.4% average, given alive", 1 - exp(-avg[2])),
    ("  right: 1 - e^-0.06", 1 - exp(-0.06)),
    ("wrong: died in year 4 = hazard", rate(3.5)),
    ("try: flat 4.4%, S(5)", S(5, [avg[2]] * 3)),
    ("try: flat 4.4%, died in year 1", 1 - S(1, [avg[2]] * 3)),
    ("try: rates reversed, S(5)", S(5, RATES[::-1])),
    ("try: one slice a year, S(5)", slice_curve(1)[5]),
    ("try: 6% held on, S(7)", S(7)),
]
for name, v in rows:
    print(f"{name:<50} {v:.6f}")
half = [0.5 * i for i in range(11)]
print("chart, years           " + " ".join(f"{t:5.1f}" for t in half))
print("chart, piecewise S(t)  " + " ".join(f"{S(t):5.2f}" for t in half))
print("chart, flat 4.4% S(t)  " + " ".join(f"{exp(-avg[2] * t):5.2f}" for t in half))
print("chart, spot % by year  " + " ".join(f"{100 * rate(y - 0.5):5.2f}" for y in range(1, 6)))
print("chart, average % to yr " + " ".join(f"{100 * area(y) / y:5.2f}" for y in range(1, 6)))
print("bars, died in yr %     " + " ".join(f"{100 * d:5.2f}" for d in died))

assert all(abs(slc[y] - surv[y]) < 1e-6 for y in YEARS), "slice product must reach exp(-area)"
assert all(abs(simp[i] - died[i]) < 1e-10 for i in range(5)), "density area must equal S(a) - S(b)"
assert abs(mc[5] - surv[5]) < 4 * se5, "simulated vans within four standard errors"
assert all(abs(loglin(t, a, b) - S(t)) < 1e-12 for t, a, b in [(1.5, 1, 3), (2, 1, 3), (2.5, 1, 3), (4.5, 3, 5)]), "log-linear = flat"
assert all(abs(spot_from_avg[i] - RATES[i]) < 1e-12 for i in range(3)), "spots recovered from averages"
assert abs(surv[5] - 0.8025) < 5e-5 and abs(surv[3] - 0.9048) < 5e-5, "the card's hand-worked survivals"
assert abs(died[3] - 0.0527) < 5e-5 and abs(S(7) - 0.7118) < 5e-5, "year-four deaths and the flat tail"
print("ALL CHECKS PASS")
