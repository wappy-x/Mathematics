# What compactness and connectedness buy -- the check behind the card.  Standard
# library only.  Part 1 is exhaustive: every topology on three points and every
# map between two of them, so its counts are proofs for three-point spaces.
# Part 2 is the drone: a closed loop of radius 500 m round the launch point, with
# altitude 120 + 15E + 20N metres at the loop point E radii east, N radii north.
# Loop points are exact fractions; the code illustrates the theorems there.
from fractions import Fraction as F
from itertools import permutations, product
import math

P = (0, 1, 2)
EVERY = frozenset(P)
SUBS = [frozenset(p for p in P if m >> p & 1) for m in range(8)]

def yn(claim):
    return "yes" if claim else "no"

def is_topology(t):
    return frozenset() in t and EVERY in t and all(u | v in t and u & v in t for u in t for v in t)

def continuous(f, t1, t2):                 # every pre-image of an open set is open
    return all(frozenset(x for x in P if f[x] in v) in t1 for v in t2)

def connected(s, t):                       # no split of s into two open pieces
    pieces = {u & s for u in t}
    return not any(a and s - a and s - a in pieces for a in pieces)

def hausdorff(t):                          # distinct points sit in disjoint open sets
    return all(any(x in u and y in v and not u & v for u in t for v in t)
               for x in P for y in P if x != y)

TOPS = [t for m in range(256) if is_topology(t := frozenset(SUBS[i] for i in range(8) if m >> i & 1))]
cont = conn = jumpy = 0
images_ok = True
for t1, t2 in product(TOPS, TOPS):
    for f in product(P, repeat=3):
        img = frozenset(f)
        if continuous(f, t1, t2):
            cont += 1
            if connected(EVERY, t1):
                conn += 1
                images_ok = images_ok and connected(img, t2)
        elif connected(EVERY, t1) and not connected(img, t2):
            jumpy += 1
counts = {True: [0, 0], False: [0, 0]}     # target Hausdorff? -> [continuous bijections, homeomorphisms]
for t1, t2 in product(TOPS, TOPS):
    for f in permutations(P):
        if continuous(f, t1, t2):
            inv = tuple(f.index(y) for y in P)
            counts[hausdorff(t2)][0] += 1
            counts[hausdorff(t2)][1] += continuous(inv, t2, t1)
discrete, indiscrete = frozenset(SUBS), frozenset([frozenset(), EVERY])
print("Part 1: every topology on three points, every map between two of them")
print(f"topologies on 3 points: {len(TOPS)}; Hausdorff ones: {sum(map(hausdorff, TOPS))}; "
      f"connected ones: {sum(connected(EVERY, t) for t in TOPS)}")
print(f"continuous maps: {cont}; from a connected space: {conn}; image connected every time: {yn(images_ok)}")
print(f"discontinuous maps from a connected space with a disconnected image: {jumpy}")
hb, nb = counts[True], counts[False]
print(f"continuous bijections onto a Hausdorff space: {hb[0]}; homeomorphisms among them: {hb[1]}")
print(f"continuous bijections onto a non-Hausdorff space: {nb[0]}; homeomorphisms among them: {nb[1]}")
print(f"identity, discrete onto indiscrete: continuous {yn(continuous(P, discrete, indiscrete))}, "
      f"inverse continuous {yn(continuous(P, indiscrete, discrete))}")

def alt(e, n):
    return 120 + 15 * e + 20 * n

def point(t):                              # exact loop point for slope t; t = infinity gives (-1, 0)
    return (1 - t * t) / (1 + t * t), 2 * t / (1 + t * t)

def dec(x, k):                             # a fraction to k decimal places, cut not rounded
    s, x = ("-" if x < 0 else ""), abs(x)
    w = x.numerator * 10 ** k // x.denominator
    return f"{s}{w // 10 ** k}.{w % 10 ** k:0{k}d}"

loop = [point(F(k, 8)) for k in range(-64, 65)] + [(F(-1), F(0))]
alts = [alt(e, n) for e, n in loop]
hi, lo = max(alts), min(alts)
top, bottom = loop[alts.index(hi)], loop[alts.index(lo)]
ident = all((15 * e + 20 * n) ** 2 + (20 * e - 15 * n) ** 2 == 625 for e, n in loop)
print("Part 2: the drone's loop, radius 500 m, altitude 120 + 15E + 20N metres")
print(f"checked on {len(loop)} exact loop points: highest {hi} m at ({top[0] * 500}, {top[1] * 500}) m; "
      f"lowest {lo} m at ({bottom[0] * 500}, {bottom[1] * 500}) m")
print(f"identity (15E + 20N)^2 + (20E - 15N)^2 = 625 at all {len(loop)} points: {yn(ident)}")
compass = [("north", 0, 1), ("east", 1, 0), ("south", 0, -1), ("west", -1, 0)]
print("compass points only: " + ", ".join(f"{c} {alt(e, n)} m" for c, e, n in compass)
      + f"; best {max(alt(e, n) for _, e, n in compass)} m")
print("chart, altitude in m at bearings 0, 30, ..., 360 degrees:", " ".join(
    f"{120 + 15 * math.sin(math.radians(b)) + 20 * math.cos(math.radians(b)):.1f}" for b in range(0, 361, 30)))
a, b = F(-2), F(1, 2)                      # lowest point to highest point
g = lambda t: 15 * (1 - t * t) + 40 * t    # (altitude - 120) times (1 + t^2)
for _ in range(40):
    m = (a + b) / 2
    a, b = (m, b) if g(m) < 0 else (a, m)
print(f"bisection for 120 m, 40 halvings: slope t in [{dec(a, 12)}, {dec(b, 12)}]; algebra: t = -1/3 or t = 3")
for t in (F(-1, 3), F(3)):
    e, n = point(t)
    print(f"  t = {t}: point ({e * 500}, {n * 500}) m, altitude {alt(e, n)} m")
crossings = {}
for y in (110, 130, 150):
    s = [v > y for v in alts]
    crossings[y] = sum(s[i] != s[i - 1] for i in range(len(s)))
print("crossings of one lap, sampled: " + ", ".join(f"{y} m: {c}" for y, c in crossings.items()))
near = [alt(*point(F(1, 2) + F(1, 10 ** k))) for k in (2, 3, 4)]
print("open loop, top point removed: altitudes " + ", ".join(dec(v, 9) for v in near) + "; 145 never reached")
print(f"two separate loops, the second 60 m higher: altitudes {lo} to {hi} and {lo + 60} to {hi + 60}; "
      f"150 m flown: {yn(any(v == 150 or v + 60 == 150 for v in alts))}")
chord = 1000 * math.sin(math.pi / 1000)
p0, p1 = (500.0, 0.0), (500 * math.cos(2 * math.pi * 0.999), 500 * math.sin(2 * math.pi * 0.999))
print(f"unglued lap clock [0, 1): lap fractions 0.999 and 0 sit {chord:.4f} m apart on the loop, "
      f"but 0.999 apart on the clock; glued, {min(F(999, 1000), 1 - F(999, 1000))} apart")
print(f"closed set, image not closed: 1/(1 + x^2) at x = 10, 100, 1000: "
      + ", ".join(str(F(1, 1 + x * x)) for x in (10, 100, 1000)) + "; 0 never reached")
assert len(TOPS) == 29 and sum(map(hausdorff, TOPS)) == 1         # Evans-Harary-Lynn count
assert sum(connected(EVERY, t) for t in TOPS) == 29 - 10            # 10 split ones, by hand
assert images_ok and jumpy > 0 and conn > 0                       # theorem holds, test can fail
assert hb[0] == hb[1] > 0 and nb[1] < nb[0]                         # compact to Hausdorff only
assert hb[1] + nb[1] == 6 * len(TOPS)        # one homeomorphism per topology and permutation
assert (hi, top, lo, bottom) == (145, (F(3, 5), F(4, 5)), 95, (F(-3, 5), F(-4, 5))) and ident
assert a < F(-1, 3) < b and b - a == F(5, 2) / 2 ** 40            # bisection meets the algebra
assert all(c == (2 if abs(y - 120) < 25 else 0) for y, c in crossings.items())
assert abs(math.dist(p0, p1) - chord) < 1e-9                      # cross-check of the chord
print("ALL CHECKS PASS")
