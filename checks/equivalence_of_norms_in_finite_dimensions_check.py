# Equivalent norms -- the check behind the card.  Standard library only.
# A shortbread batch: flour, butter, sugar.  Its weighing error is a list of
# three numbers in grams, sized three ways.  Then a week of electricity prices
# cut into N slots, where the sup and average norms stop agreeing as N grows.
from math import log10

AMT = (300.0, 200.0, 100.0)          # recipe amounts, grams
PRICE = (0.09, 0.8, 0.1)             # pence per gram, illustrative
NAMES = ("flour", "butter", "sugar")

def grams(x): return sum(abs(v) for v in x)                            # total grams off
def pct(x): return max(100 * abs(v) / a for v, a in zip(x, AMT))      # worst miss, %
def pence(x, price=PRICE): return sum(w * abs(v) for w, v in zip(price, x))  # cost of the miss

# ---- the batch ----
e = (6, -4, 3)
print(f"batch error {e} g: grams {grams(e):.0f} g, percent {pct(e):.4f} %, pence {pence(e):.4f} p")
assert grams(e) == 13 and abs(pct(e) - 3) < 1e-12
assert abs(pence(e) - (0.54 + 3.2 + 0.3)) < 1e-12
for name, a, v in zip(NAMES, AMT, e):
    print(f"  {name}: {v:+d} g of {a:.0f} g = {100 * abs(v) / a:.4f} %")

# ---- road 1: best constants from the corners of each unit ball ----
closed = {
    "percent per gram": (100 / sum(AMT), max(100 / a for a in AMT)),
    "pence per gram": (min(PRICE), max(PRICE)),
    "pence per percent": (min(w * a / 100 for w, a in zip(PRICE, AMT)),
                          sum(w * a / 100 for w, a in zip(PRICE, AMT))),
}

# ---- road 2: walk the whole grams-sphere |x1| + |x2| + |x3| = K ----
K = 60
sphere = []                          # every whole-gram error of total K, in a fixed order
for i in range(-K, K + 1):
    for j in range(-(K - abs(i)), K - abs(i) + 1):
        r = K - abs(i) - abs(j)
        sphere += [(i, j, r), (i, j, -r)] if r > 0 else [(i, j, 0)]
print(f"grams-sphere points with K = {K}: {len(sphere)} (formula 4K^2 + 2 = {4 * K * K + 2})")
assert len(sphere) == 4 * K * K + 2
ratio = {
    "percent per gram": lambda x: pct(x) / grams(x),
    "pence per gram": lambda x: pence(x) / grams(x),
    "pence per percent": lambda x: pence(x) / pct(x),
}
for key, f in ratio.items():
    vals = [f(x) for x in sphere]
    lo, hi = min(vals), max(vals)
    c, C = closed[key]
    print(f"{key}: corners c = {c:.4f}, C = {C:.4f}; sphere walk min {lo:.4f}, max {hi:.4f}; batch {f(e):.4f}")
    assert abs(lo - c) < 1e-12 and abs(hi - C) < 1e-12 and c <= f(e) <= C
    at = lambda x: tuple(abs(v) for v in x)
    print(f"  sizes of the extreme errors: min at {at(min(sphere, key=f))}, max at {at(max(sphere, key=f))}")

# ---- the proof's constants, with grams as the reference norm ----
B = max(pct((1 if k == i else 0 for k in range(3))) for i in range(3))
m = min(pct(x) for x in sphere) / K
print(f"proof, percent against grams: B = max over one gram of each = {B:.4f}, m = min on sphere = {m:.4f}")
xs = tuple(a / sum(AMT) for a in AMT)                   # the error in proportion to the recipe
print(f"  one gram each: {', '.join(f'{100 / a:.4f}' for a in AMT)} %; x* = ({', '.join(f'{v:.4f}' for v in xs)}) g, "
      f"each {', '.join(f'{100 * v / a:.4f}' for v, a in zip(xs, AMT))} % off")
print(f"  batch sandwich: {m * grams(e):.4f} <= {pct(e):.4f} <= {B * grams(e):.4f}")
mp = min(pence(x) for x in sphere) / K
print(f"  chain percent <= (B / m_pence) pence: constant {B / mp:.4f}, best {1 / closed['pence per percent'][0]:.4f}")
assert m * grams(e) <= pct(e) <= B * grams(e) and B / mp >= 1 / closed["pence per percent"][0]

# ---- continuity of the percent norm: |pct(x) - pct(y)| <= B |x - y|_1 ----
worst = max(abs(pct(x) - pct(y)) / grams(tuple(a - b for a, b in zip(x, y)))
            for x in [(6, -4, 3)] for y in sphere)
print(f"continuity: worst |pct(e) - pct(y)| / grams(e - y) over the sphere = {worst:.4f} <= B")
assert worst <= B + 1e-12

# ---- what breaks: a free ingredient ----
free = pence((0, 0, 3), (0.09, 0.8, 0.0))
print(f"sugar priced 0: error (0, 0, 3) costs {free:.4f} p, yet is {pct((0, 0, 3)):.4f} % off")
assert free == 0 and pct((0, 0, 3)) > 0

# ---- what breaks: one net reading of the batch.  Overs and shorts cancel, so it is not a norm ----
for x in ((6, -4, 3), (10, -10, 0), (30, -30, 0)):
    print(f"net reading {x}: {sum(x)} g net, {sum(w * v for w, v in zip(PRICE, x)):.4f} p net, yet {pct(x):.4f} % off")

# ---- what breaks: fractions only.  |p + q sqrt2| is zero only at (0, 0) when p, q are fractions ----
for p, q in ((-7, 5), (-41, 29), (-239, 169)):
    r2 = abs(p + q * 2 ** 0.5)
    print(f"fractions ({p}, {q}): |p + q sqrt2| = {r2:.6f}, grams {abs(p) + abs(q)}, ratio {r2 / (abs(p) + abs(q)):.7f}")
    assert abs(r2 - 1 / abs(p - q * 2 ** 0.5)) < 1e-9          # (p + q sqrt2)(p - q sqrt2) = p^2 - 2q^2 = -1

# ---- functions: a week cut into N slots, a single-slot price spike ----
SPIKE = 920.0                         # £/MWh above a flat 80, illustrative
print("week of prices, one-slot spike of 920 £/MWh: sup norm vs time-average norm")
for N in (7, 168, 1008, 10080, 604800):
    f = [0.0] * N; f[N // 2] = SPIKE
    sup, avg = max(abs(v) for v in f), sum(abs(v) for v in f) / N
    print(f"  N {N:6d}: slot {168 / N:.6f} h, sup {sup:.1f}, average {avg:.7f}, sup/average {sup / avg:.1f}, "
          f"log10 average {log10(avg):.3f}")
    assert abs(avg - SPIKE / N) < 1e-9 and abs(sup / avg - N) < 1e-6
pts = []
for N in (10, 100, 1000, 10000, 100000, 1000000):    # chart points, evenly spaced in log10 N
    f = [0.0] * N; f[N // 2] = SPIKE
    pts.append(log10(sum(abs(v) for v in f) / N))
print(f"chart, N = 10^1 to 10^6 slots: log10 sup {log10(SPIKE):.3f}; log10 average " + ", ".join(f"{v:.3f}" for v in pts))
assert all(abs(a - b - 1) < 1e-12 for a, b in zip(pts, pts[1:]))   # one unit of log10 per tenfold

# ---- brute force for N = 7: min average on the sup-sphere is 1/N ----
levels = (-1.0, -0.5, 0.0, 0.5, 1.0)
best, count = 2.0, 0
for code in range(5 ** 7):
    v, c = [], code
    for _ in range(7):
        v.append(levels[c % 5]); c //= 5
    if max(abs(t) for t in v) == 1.0:
        count += 1; best = min(best, sum(abs(t) for t in v) / 7)
print(f"N = 7 brute force: {5 ** 7} lists tried, {count} with sup 1, smallest average {best:.6f} (1/7 = {1 / 7:.6f})")
assert abs(best - 1 / 7) < 1e-12
print("ALL CHECKS PASS")
