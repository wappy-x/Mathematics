# Stochastic dominance -- the check behind the card.  Standard library only.
# Three funds, one year, returns in percent, even odds.  Every number quoted on
# the card is printed here.  The normal CDF, the integrator and the random
# numbers are written out below; nothing imported knows the answer.
from math import exp, log, sqrt, pi

FUNDS = {"Steady": [(2.0, 1.0)], "Swing": [(-2.0, 0.5), (6.0, 0.5)],
         "Upside": [(-2.0, 0.5), (8.0, 0.5)]}
KNOTS = [-2.0, 2.0, 6.0, 8.0]
PAIRS = [("Upside", "Swing"), ("Swing", "Upside"), ("Steady", "Swing"),
         ("Swing", "Steady"), ("Steady", "Upside"), ("Upside", "Steady")]

def mean(f):        return sum(p * x for x, p in f)
def spread(f):      return sqrt(sum(p * (x - mean(f)) ** 2 for x, p in f))
def cdf(f, t):      return sum(p for x, p in f if x <= t)
def shortfall(f, k): return sum(p * max(k - x, 0.0) for x, p in f)    # road 1: E[(k - X)+]
def area(f, k, lo=-10.0, h=0.01):                                     # road 2: area under the CDF
    n = round((k - lo) / h)
    return sum(cdf(f, lo + (i + 0.5) * h) for i in range(n)) * h
def quantile(f, q):  return min(x for x, p in f if cdf(f, x) >= q)

def rng(seed):                               # 64-bit LCG, top 53 bits -> [0, 1)
    s = seed
    while True:
        s = (s * 6364136223846793005 + 1442695040888963407) % 2 ** 64
        yield (s >> 11) / 2.0 ** 53

def search(a, b, concave, draws=2000, seed=7):
    # Road 3: random utilities on the knots.  Count those ranking a below b.
    r, bad = rng(seed), 0
    for _ in range(draws):
        s = [next(r), next(r), next(r)]      # slopes on -2..2, 2..6, 6..8
        if concave: s.sort(reverse=True)     # slopes that only fall: concave
        u = [0.0, 4 * s[0], 4 * s[0] + 4 * s[1], 4 * s[0] + 4 * s[1] + 2 * s[2]]
        score = lambda f: sum(p * u[KNOTS.index(x)] for x, p in f)
        bad += score(FUNDS[a]) < score(FUNDS[b]) - 1e-12
    return bad

def yn(c): return "yes" if c else "no "

print("fund     outcomes        mean  spread")
for n, f in FUNDS.items():
    print(f"{n:<8} {' or '.join(f'{x:+.0f}' for x, _ in f):<14}{mean(f):6.2f}{spread(f):8.2f}")
print("CDF F(t) at t =          " + "".join(f"{t:7.0f}" for t in KNOTS))
for n, f in FUNDS.items():
    print(f"  {n:<22}" + "".join(f"{cdf(f, t):7.2f}" for t in KNOTS))
CH = [-4.0 + 2 * i for i in range(8)]
print("shortfall P(k) at k =    " + "".join(f"{k:7.0f}" for k in CH))
worst = 0.0
for n, f in FUNDS.items():
    print(f"  {n:<22}" + "".join(f"{shortfall(f, k):7.2f}" for k in CH))
    worst = max(worst, max(abs(shortfall(f, k) - area(f, k)) for k in CH))
print(f"largest gap, E[(k-X)+] vs area under CDF   {worst:.12f}")
assert worst < 1e-9, "shortfall must equal the area under the CDF"

print("pair               | 1st: CDF  quantile  increasing u bad | 2nd: shortfall  concave u bad")
verdicts = []
for a, b in PAIRS:
    fa, fb = FUNDS[a], FUNDS[b]
    c1 = all(cdf(fa, t) <= cdf(fb, t) for t in KNOTS)
    q1 = all(quantile(fa, (i + 0.5) / 100) >= quantile(fb, (i + 0.5) / 100) for i in range(100))
    s1 = search(a, b, False)
    c2 = all(shortfall(fa, k) <= shortfall(fb, k) + 1e-12 for k in KNOTS)
    s2 = search(a, b, True)
    verdicts.append((c1, c2))
    print(f"{a + ' over ' + b:<19}|      {yn(c1)}  {yn(q1)}       {s1:5d} of 2000 |"
          f"           {yn(c2)}  {s2:5d} of 2000")
    assert c1 == q1 == (s1 == 0), "three first-order roads must agree"
    assert c2 == (s2 == 0), "shortfall test and concave search must agree"

WIT = [("linear, u(r) = r", lambda r: r), ("capped, u(r) = min(r, 2)", lambda r: min(r, 2.0)),
       ("log wealth, ln(100 + r)", lambda r: log(100 + r)), ("bet, 1 if r > 2", lambda r: float(r > 2))]
beat = sum(p * q for x, p in FUNDS["Swing"] for y, q in FUNDS["Upside"] if x > y)
print(f"independent draws: chance Swing ends above Upside {beat:.2f}")
print("witness utility            Steady    Swing   Upside")
for n, u in WIT:
    print(f"{n:<25}" + "".join(f"{sum(p * u(x) for x, p in f):9.4f}" for f in FUNDS.values()))

def simpson(g, a, b, n=2000):
    h = (b - a) / n
    return (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))) * h / 3
# Road 4, the identity of Why it works, Step 3, with u = ln(100 + r) on [a, b] = [-2, 8]
for a, b in (("Steady", "Swing"), ("Upside", "Steady")):
    fa, fb = FUNDS[a], FUNDS[b]
    direct = sum(p * log(100 + x) for x, p in fa) - sum(p * log(100 + x) for x, p in fb)
    ident = (mean(fa) - mean(fb)) / 108 + simpson(
        lambda k: (shortfall(fb, k) - shortfall(fa, k)) / (100 + k) ** 2, -2.0, 8.0)
    print(f"Eu({a}) - Eu({b}): direct {direct:.9f}  identity {ident:.9f}")
    assert abs(direct - ident) < 1e-9, "the Step 3 identity must match the direct average"

phi = lambda x: exp(-0.5 * x * x) / sqrt(2 * pi)
def N_simpson(x): return 0.5 + simpson(phi, 0.0, x)
def N_series(x):                                        # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    term, total, j = x, x, 1
    while abs(term) > 1e-17:
        term *= x * x / (2 * j + 1); total += term; j += 1
    return 0.5 + phi(x) * total
MU, SIG, DEP = 8.0, 15.0, 4.0                          # house fund and deposit, percent
def fund_short(k, mu=MU, sig=SIG):                     # closed form: sigma phi(z) + (k - mu) N(z)
    z = (k - mu) / sig
    return sig * phi(z) + (k - mu) * N_series(z)
def fund_short_int(k):                                 # the same by brute force over the bell curve
    return simpson(lambda x: (k - x) * phi((x - MU) / SIG) / SIG, MU - 12 * SIG, k, 20000)
z4 = (DEP - MU) / SIG
print(f"house: z = (4 - 8) / 15 = {z4:.4f}")
print(f"house: chance fund ends below 4%: Simpson {N_simpson(z4):.6f}  series {N_series(z4):.6f}")
for k in (4.0, 30.0):
    print(f"house: shortfall at {k:4.0f}  deposit {max(k - DEP, 0):7.4f}  fund {fund_short(k):7.4f}"
          f"  by integral {fund_short_int(k):7.4f}")
    assert abs(fund_short(k) - fund_short_int(k)) < 1e-8, "closed form vs integral"
assert abs(N_simpson(z4) - N_series(z4)) < 1e-12, "two roads to N(z)"
print(f"house: capped at 4, E min(fund, 4) = {DEP - fund_short(DEP):.4f} vs deposit 4.0000")

MIS = [("means only: Steady vs Swing", mean(FUNDS["Steady"]) - mean(FUNDS["Swing"])),
       ("spreads only: Upside minus Steady", spread(FUNDS["Upside"]) - spread(FUNDS["Steady"])),
       ("one cutoff, k = 8: P_Upside - P_Steady", shortfall(FUNDS["Upside"], 8) - shortfall(FUNDS["Steady"], 8)),
       ("same, k = 2: P_Upside - P_Steady", shortfall(FUNDS["Upside"], 2) - shortfall(FUNDS["Steady"], 2)),
       ("one threshold, t = -2: F_Steady - F_Swing", cdf(FUNDS["Steady"], -2) - cdf(FUNDS["Swing"], -2)),
       ("same, t = 2: F_Steady - F_Swing", cdf(FUNDS["Steady"], 2) - cdf(FUNDS["Swing"], 2))]
for n, v in MIS: print(f"wrong: {n:<42}{v:7.2f}")
sw7 = [(-2.0, 0.5), (7.0, 0.5)]
up3 = [(-3.0, 0.5), (8.0, 0.5)]
print(f"try: Swing -2 or +7, shortfall at 8: Steady {shortfall(FUNDS['Steady'], 8):.2f}, Swing {shortfall(sw7, 8):.2f}")
print(f"try: Upside -3 or +8, CDF at -3: Upside {cdf(up3, -3):.2f}, Swing {cdf(FUNDS['Swing'], -3):.2f};"
      f" shortfall at -2: Upside {shortfall(up3, -2):.2f}, Swing {shortfall(FUNDS['Swing'], -2):.2f}")
print(f"try: fund spread 1%, chance below 4% per million {1e6 * N_series(-4.0):.3f},"
      f" shortfall at 4 per million {1e6 * fund_short(4.0, 8.0, 1.0):.3f}")
assert verdicts == [(True, True), (False, False), (False, True), (False, False), (False, False), (False, False)]
print("ALL CHECKS PASS")
