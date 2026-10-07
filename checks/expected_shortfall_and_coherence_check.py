# Expected shortfall and coherence -- the check behind the card.  Standard library only.
# Two bonds, each a $100 loss if its issuer defaults (1% each, independent, nothing recovered).
# Probabilities are whole millionths, so every tail below is exact integer arithmetic.
from math import exp, sqrt, pi

DEN = 1_000_000

def pair_law(p, together=False):     # p = default chance in thousandths -> [(loss A, loss B, weight)]
    if together:
        return [(0, 0, DEN - 1000 * p), (100, 100, 1000 * p)]
    n = 1000 - p
    return [(0, 0, n * n), (100, 0, p * n), (0, 100, n * p), (100, 100, p * p)]

def merge(pairs):                    # [(loss, weight)] -> {loss: total weight}
    law = {}
    for x, w in pairs: law[x] = law.get(x, 0) + w
    return law

def var(law, a, den=DEN):            # lowest loss whose cumulative weight reaches a/den
    cum = 0
    for x in sorted(law):
        cum += law[x]
        if cum * DEN >= a * den: return x

def es_fill(law, a, den=DEN):        # road 1: fill the worst tail, largest losses first -> numerator over t
    room, total = (DEN - a) * den, 0     # tail size, in units of 1/(DEN*den)
    for x in sorted(law, reverse=True):
        take = min(law[x] * DEN, room)
        total += x * take; room -= take
    return total                     # ES = total / ((DEN - a) * den)

def es_min(law, a, den=DEN):         # road 2: min over s of s*t + E[(L-s)+]; the minimum sits on a loss value
    t = (DEN - a) * den
    return min(s * t + sum(DEN * w * max(x - s, 0) for x, w in law.items()) for s in law)

def es(law, a, den=DEN): return es_fill(law, a, den) / ((DEN - a) * den)

def books(p=10, together=False):
    j = pair_law(p, together)
    return merge((x, w) for x, _, w in j), merge((y, w) for _, y, w in j), merge((x + y, w) for x, y, w in j)

A99 = 990_000
A, B, P = books()
rows = [("state neither defaults", P[0] / DEN), ("state exactly one defaults", P[100] / DEN),
        ("state both default", P[200] / DEN)]
for name, law in (("bond A", A), ("bond B", B), ("pair", P)):
    rows += [(f"VaR99 {name}", var(law, A99)), (f"ES99 {name}, fill the tail", es(law, A99)),
             (f"ES99 {name}, minimise over s", es_min(law, A99) / ((DEN - A99) * DEN))]
v_sum = var(A, A99) + var(B, A99)
rows += [("VaR99 pair minus sum of solo", var(P, A99) - v_sum),
         ("ES99 sum of solo", es(A, A99) + es(B, A99)),
         ("pair tail, weight taken at $100", (DEN - A99 - sum(w for x, w in P.items() if x > 100)) / DEN)]

# ---- road 3: simulate a million days with a home-made generator (64-bit LCG, top bits) ----
seed, M64 = 20260928, (1 << 64) - 1
def draw():
    global seed
    seed = (seed * 6364136223846793005 + 1442695040888963407) & M64
    return (seed >> 33) % 1000
N = 1_000_000
counts = {0: 0, 100: 0, 200: 0}
for _ in range(N):
    counts[100 * (draw() < 10) + 100 * (draw() < 10)] += 1
rows += [("simulated days, both default", counts[200]), ("simulated VaR99 pair", var(counts, A99, N)),
         ("simulated ES99 pair", es(counts, A99, N))]

# ---- what breaks ----
v = var(P, A99)
strict = sum(x * w for x, w in P.items() if x > v) / sum(w for x, w in P.items() if x > v)
ties = sum(x * w for x, w in P.items() if x >= v) / sum(w for x, w in P.items() if x >= v)
rows += [("wrong: mean of losses strictly above VaR", strict), ("wrong: mean of losses at or above VaR", ties),
         ("axiom: ES99 pair + $5 certain loss", es({x + 5: w for x, w in P.items()}, A99)),
         ("axiom: ES99 pair, doubled book", es({2 * x: w for x, w in P.items()}, A99))]

# ---- try changing ----
for label, kw in (("try: p = 0.5%", dict(p=5)), ("try: p = 2%", dict(p=20)), ("try: defaults together", dict(together=True))):
    a, b, pr = books(**kw)
    rows += [(f"{label}, VaR99 pair | sum", f"{var(pr, A99):.2f} | {var(a, A99) + var(b, A99):.2f}"),
             (f"{label}, ES99 pair | sum", f"{es(pr, A99):.2f} | {es(a, A99) + es(b, A99):.2f}")]

# ---- random books: does subadditivity ever fail?  8 equally likely days, 80% level ----
def lcg_int(k): return draw() % k
var_breaks = es_breaks = road_gaps = 0
for _ in range(2000):
    days = [(50 * lcg_int(5) - 50, 50 * lcg_int(5) - 50) for _ in range(8)]
    la, lb, lp = (merge((f(d), 125_000) for d in days) for f in (lambda d: d[0], lambda d: d[1], lambda d: d[0] + d[1]))
    var_breaks += var(lp, 800_000) > var(la, 800_000) + var(lb, 800_000)
    es_breaks += es_fill(lp, 800_000) > es_fill(la, 800_000) + es_fill(lb, 800_000)
    road_gaps += es_fill(lp, 800_000) != es_min(lp, 800_000)
rows += [("random books, VaR80 not subadditive", var_breaks), ("random books, ES80 not subadditive", es_breaks),
         ("random books, ES80 roads 1 and 2 disagree", road_gaps)]

# ---- a second case: a bell-curve loss with spread 1 ($1 million a day) ----
def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def N_cdf(x):                        # Marsaglia's series: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    term = total = x; k = 1
    while abs(term) > 1e-17 * abs(total) + 1e-300:
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total
def z_of(a):                         # bisection on the home-made CDF
    lo, hi = -10.0, 10.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N_cdf(mid) < a else (lo, mid)
    return 0.5 * (lo + hi)
def tail_simpson(z, t, n=20000):     # (1/t) * integral from z to z+12 of x phi(x) dx
    h = 12.0 / n
    s = z * phi(z) + (z + 12) * phi(z + 12)
    for i in range(1, n): s += (4 if i % 2 else 2) * (z + i * h) * phi(z + i * h)
    return s * h / 3 / t
for a in (0.99, 0.975):
    z = z_of(a)
    rows += [(f"normal VaR{a * 100:g}", z), (f"normal ES{a * 100:g}, phi(z)/t", phi(z) / (1 - a)),
             (f"normal ES{a * 100:g}, integral", tail_simpson(z, 1 - a))]

# ---- chart points: confidence level across ----
levels = (950_000, 970_000, 980_000, 985_000, 990_000, 995_000, 999_000)
chart = [("chart, confidence %", [l / 10_000 for l in levels]),
         ("chart, VaR pair", [var(P, l) for l in levels]), ("chart, VaR sum", [var(A, l) + var(B, l) for l in levels]),
         ("chart, ES pair", [es(P, l) for l in levels]), ("chart, ES sum", [es(A, l) + es(B, l) for l in levels])]

for name, x in rows:
    print(f"{name:<44} {x:>14}" if isinstance(x, (str, int)) else f"{name:<44} {x:>14.6f}")
for name, xs in chart:
    print(f"{name:<22}" + "".join(f"{x:>8.2f}" for x in xs))

assert es_fill(P, A99) == es_min(P, A99), "pair: fill road vs minimise road, exact"
assert es_fill(A, A99) == es_min(A, A99), "bond A: fill road vs minimise road, exact"
assert es_fill(P, A99) == 101 * (DEN - A99) * DEN, "pair ES must be exactly $101"
assert var(P, A99) > v_sum, "VaR of the pair must exceed the sum"
assert abs(es(counts, A99, N) - es(P, A99)) < 0.5, "simulation within 50 cents of the exact ES"
assert es_breaks == 0, "ES never breaks subadditivity"
assert var_breaks > 0, "VaR breaks it on some random book"
assert road_gaps == 0, "fill and minimise agree on every random book"
assert abs(phi(z_of(0.99)) / 0.01 - tail_simpson(z_of(0.99), 0.01)) < 1e-8, "normal ES: closed form vs integral"
assert abs(z_of(0.99) - 2.3263478740) < 1e-8, "99% point vs the printed normal table"
print("ALL CHECKS PASS")
