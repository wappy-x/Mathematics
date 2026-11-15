# Hausdorff and its ladder -- the check behind the card.  Standard library only.
# Part 1: the line with a doubled origin, where 1/n has two limits.  Part 2: the
# circle in the plane, split by two discs of radius half the gap.  Part 3: two
# closed sets of the line with no fixed gap, split by "nearer to which".  Part 4:
# the K-topology, Hausdorff but not regular.  Part 5: every topology on 3 and 4
# points, sorted onto the ladder; that part is exhaustive, so it is a proof.
from fractions import Fraction as F
from itertools import combinations

def yn(claim):
    return "yes" if claim else "no"

print("Part 1: the line with a doubled origin: every real number, plus a twin 0' of 0")
print("near 0: the band (-r, r); near 0': the same band with 0 swapped for 0'")
TWIN = "0'"                                            # the twin: a point that is not a real number
def band(c, r, z):                                     # is z in the band of radius r round c, 0 or 0'?
    return z == c or (z not in (0, TWIN) and abs(z) < r)
for k in (10, 100, 1000):
    r = F(1, k)
    formula = int(1 / r)                               # n > 1/r gives 1/n < r
    search = next(N for N in range(1, 10 ** 4) if all(F(1, n) < r for n in range(N + 1, N + 3 * k)))
    both = all(band(0, r, F(1, n)) and band(TWIN, r, F(1, n)) for n in range(formula + 1, formula + 3 * k))
    print(f"  tolerance {r}: cutoff {formula} by formula, {search} by search; "
          f"later shares 1/n lie in both bands: {yn(both)}")
    assert formula == search == k and both
radii = [F(1, a) for a in range(1, 51)]
meet = all(band(0, r, min(r, s) / 2) and band(TWIN, s, min(r, s) / 2) for r in radii for s in radii)
apart = all(not band(0, r, TWIN) and not band(TWIN, r, 0) for r in radii)
print(f"bands round 0 and 0' of radius r and s share the point min(r, s)/2: checked on 2500 pairs: {yn(meet)}")
print(f"  radius 1/10 round 0 and 1/1000 round 0': shared point {min(F(1, 10), F(1, 1000)) / 2}")
print(f"so 1/n converges to 0 and to 0': two limits; yet each band round one twin misses the other (T1): {yn(apart)}")
assert meet and apart

def isqrt(n):                                          # largest whole r with r * r <= n
    lo, hi = 0, n + 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if mid * mid <= n else (lo, mid)
    return lo

print("Part 2: the circle in the plane; P = (1, 0), Q = (3/5, 4/5)")
P, Q = (F(1), F(0)), (F(3, 5), F(4, 5))
gap2 = (P[0] - Q[0]) ** 2 + (P[1] - Q[1]) ** 2
print(f"  gap squared {gap2}; gap 0.{isqrt(8 * 10 ** 7)}...; half the gap 0.{isqrt(2 * 10 ** 7)}...")
def shared(rad2):                                      # grid points in both discs, steps of 1/50
    pts = [(F(i, 50), F(j, 50)) for i in range(-50, 101) for j in range(-50, 101)]
    def inside(z, c):
        return (z[0] - c[0]) ** 2 + (z[1] - c[1]) ** 2 < rad2
    return sum(1 for z in pts if inside(z, P) and inside(z, Q)), sum(1 for z in pts if inside(z, P))
none, inP = shared(gap2 / 4)
many, _ = shared(gap2)
print(f"  discs of radius half the gap: {inP} grid points in the disc round P, {none} in both")
print(f"  mistake, discs of radius the whole gap: {many} grid points in both")
assert gap2 == F(4, 5) and none == 0 and inP > 0 and many > 0
grid = [F(k, 1000) for k in range(1001)]                # the circle glued from [0, 1]
U, V = (lambda x: x < F(1, 4) or x > F(3, 4)), (lambda x: F(1, 4) < x < F(3, 4))
glued = U(F(0)) and U(F(1)) and V(F(1, 2)) and not any(U(x) and V(x) for x in grid)
print(f"  [0, 1] with its ends glued: [0, 1/4) and (3/4, 1] hold both ends, (1/4, 3/4) holds 1/2; "
      f"no shared point among {len(grid)}: {yn(glued)}")
assert glued

print("Part 3: C = the whole numbers 2, 3, 4, ...; D = n + 1/n beside each; both closed")
def dist(x, pts):
    return min(abs(x - p) for p in pts)
C = [F(n) for n in range(2, 202)]
D = [n + F(1, n) for n in range(2, 202)]
for n in (2, 3, 10, 100):
    lo, hi = F(n), n + F(1, n)                         # bisect for where nearer-to-C stops
    for _ in range(40):                                # width 1/n halved 40 times
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if dist(mid, C) < dist(mid, D) else (lo, mid)
    switch = n + F(1, 2 * n)
    print(f"  n = {n}: gap 1/{n}; nearer-to-C ends at {switch} by formula; bisection within 10^-12: "
          f"{yn(abs(lo - switch) < F(1, 10 ** 12))}")
    assert abs(lo - switch) < F(1, 10 ** 12)
w = F(1, 100)
first = next(n for n in range(2, 10 ** 4) if n + w > n + F(1, n) - w)
print(f"mistake, a fixed buffer of width {w} round both sets: buffers first overlap at n = {first} "
      f"(formula {int(1 / (2 * w)) + 1})")
assert first == int(1 / (2 * w)) + 1 == 51

print("Part 4: the K-topology; K = {1/n}; basic open sets: bands, and bands with K removed")
for e in (F(1, 1000), F(1, 10 ** 6)):
    x = F(1, 11) - e / 2
    ok = abs(x) < F(1, 10) and abs(x - F(1, 11)) < e and (1 / x).denominator != 1
    print(f"  band (-1/10, 1/10) minus K round 0, band of radius {e} round 1/11 in K: share {x}, "
          f"not in K: {yn(ok)}")
    assert ok

print("Part 5: every topology on a 3-point and a 4-point set, sorted onto the ladder")
def census(n):
    full, masks = (1 << n) - 1, range(1, (1 << n) - 1)
    stats = dict.fromkeys(["tops", "T0", "T1", "T2", "reg", "nor", "regc", "norc", "uniq"], 0)
    for r in range(len(masks) + 1):
        for pick in combinations(masks, r):
            fam = {0, full, *pick}
            if any(u | v not in fam or u & v not in fam for u in fam for v in fam):
                continue
            def small(s):                              # smallest open set holding s
                return min((u for u in fam if u & s == s), key=lambda u: bin(u).count("1"))
            pts = [1 << i for i in range(n)]
            closed = [full ^ u for u in fam]
            t0 = all(small(x) != small(y) for x, y in combinations(pts, 2))
            t1 = all(small(x) & y == 0 for x in pts for y in pts if x != y)
            t2 = all(small(x) & small(y) == 0 for x, y in combinations(pts, 2))
            regc = all(small(x) & small(c) == 0 for c in closed if c for x in pts if x & c == 0)
            norc = all(small(c) & small(d) == 0 for c in closed for d in closed if c and d and c & d == 0)
            limits = [sum(1 for y in pts if small(y) & s == s) for s in range(1, full + 1)]
            uniq = all(k <= 1 for k in limits)          # values s visited forever: limits
            for key, val in (("tops", 1), ("T0", t0), ("T1", t1), ("T2", t2), ("reg", t1 and regc),
                             ("nor", t1 and norc), ("regc", regc), ("norc", norc), ("uniq", uniq)):
                stats[key] += bool(val)
    return stats
def preorders(n):                                      # second road: relations x <= y
    pairs = [(i, j) for i in range(n) for j in range(n) if i != j]
    tot = anti = sym = 0
    for bits in range(1 << len(pairs)):
        R = {(i, i) for i in range(n)} | {p for k, p in enumerate(pairs) if bits >> k & 1}
        if all((a, d) in R for (a, b) in R for (c, d) in R if b == c):
            tot += 1
            anti += all((b, a) not in R for (a, b) in R if a != b)
            sym += all((b, a) in R for (a, b) in R)
    return tot, anti, sym
def bell(n):                                           # third road: the Bell triangle
    row = [1]
    for _ in range(n - 1):
        nxt = [row[-1]]
        for v in row:
            nxt.append(nxt[-1] + v)
        row = nxt
    return row[-1]
for n in (3, 4):
    s, (tot, anti, sym) = census(n), preorders(n)
    print(f"{n} points: topologies {s['tops']} (preorders {tot}); T0 {s['T0']} (partial orders {anti}); "
          f"T1 {s['T1']}; Hausdorff {s['T2']}; regular {s['reg']}; normal {s['nor']}")
    print(f"  every sequence has at most one limit: {s['uniq']}; regular condition alone {s['regc']} "
          f"(equivalence relations {sym}, Bell number {bell(n)}); normal condition alone {s['norc']}")
    assert s["tops"] == tot and s["T0"] == anti and s["regc"] == sym == bell(n)
    assert s["T1"] == s["T2"] == s["reg"] == s["nor"] == s["uniq"] == 1
print("ALL CHECKS PASS")
