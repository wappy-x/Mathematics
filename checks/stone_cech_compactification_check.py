# Stone-Cech compactification -- the check behind the card.  Standard library only.
# Exact arithmetic throughout: Fraction for the halving, integers for the counts.
# Part 1 reads bounded sequences at new points of beta N by halving.  Part 2 checks
# every family of subsets of a 4-point set, so that finite case is proved.  Part 3
# counts the new points that more and more functions force.  Part 4 is the circle.
from fractions import Fraction as F
from math import lcm

# ---- Part 1: a value at a new point of beta N, by halving ----
# A free ultrafilter p holds exactly one residue class r mod 12.  On a set that is
# eventually periodic mod 12 (every set used below is), p says "large" exactly when
# the set holds the far-out members of that class.  The test reads three of them.
M, TAIL, STEPS = 12, 12 * 10**11, 30
def large(member, r):
    return all(member(TAIL + M * k + r) for k in range(3))

def halve(a, r):                      # the ultrafilter limit of the sequence a at p_r
    lo, hi = F(-2), F(2)              # every value lies in [-2, 2): a large set
    for _ in range(STEPS):
        mid = (lo + hi) / 2
        left = large(lambda n: lo <= a(n) < mid, r)
        right = large(lambda n: mid <= a(n) < hi, r)
        assert left != right          # a large set split in two: exactly one half is large
        lo, hi = (lo, mid) if left else (mid, hi)
    return lo, hi

seqs = [("(-1)^n", lambda n: F((-1) ** n), lambda r: F((-1) ** r)),
        ("1/n", lambda n: F(1, n), lambda r: F(0)),
        ("(-1)^n + 1/n", lambda n: F((-1) ** n) + F(1, n), lambda r: F((-1) ** r))]
print(f"Part 1: values at the new point p_r of beta N, by {STEPS} halvings of [-2, 2)")
odd_large = large(lambda n: -2 <= (-1) ** n < 0, 1)
assert odd_large and not large(lambda n: 0 <= (-1) ** n < 2, 1)
print(f"  step 1 for (-1)^n at r = 1: [-2, 0) holds the odd n; large: {'yes' if odd_large else 'no'}")
tally = {}
for r in range(M):
    for name, a, direct in seqs:
        lo, hi = halve(a, r)
        v = direct(r)                 # road 2: the limit along the class r, by formula
        assert lo <= v < hi
        assert hi - lo == F(4, 2 ** STEPS)    # the printed width, against its formula
        if name == "(-1)^n":
            tally[lo] = tally.get(lo, 0) + 1
        if r in (1, 2):
            print(f"  r = {r:>2} mod 12: {name:<13} -> {str(lo):>2}, interval width {hi - lo}")
assert tally == {F(-1): 6, F(1): 6}
print(f"  (-1)^n over all 12 classes: -1 at {tally[F(-1)]}, +1 at {tally[F(1)]}, anything else at 0")

# ---- Part 2: every family of subsets of a 4-point set (sets as 4-bit masks) ----
def is_filter(fam):
    mem = [A for A in range(16) if fam >> A & 1]
    if not mem or fam & 1:            # empty family, or the empty set inside
        return False
    up = all(fam >> B & 1 for A in mem for B in range(16) if A & B == A)
    return up and all(fam >> (A & B) & 1 for A in mem for B in mem)

filters = [fam for fam in range(1 << 16) if is_filter(fam)]
ultras = [f for f in filters if all(f >> A & 1 or f >> (15 ^ A) & 1 for A in range(16))]
principal = [sum(1 << A for A in range(16) if A >> i & 1) for i in range(4)]
assert len(filters) == 2 ** 4 - 1 and sorted(ultras) == sorted(principal)
print("Part 2: 4 points (4 voters), all 65536 families of subsets checked")
print(f"  filters {len(filters)} (formula 2^4 - 1 = {2 ** 4 - 1}); ultrafilters {len(ultras)}")
same = sorted(ultras) == sorted(principal)
free = [f for f in ultras if not any(f >> (1 << i) & 1 for i in range(4))]   # holds no single point
print(f"  each ultrafilter is 'the 8 sets holding point i': {'yes' if same else 'no'}; free ones: {len(free)}")

# ---- Part 3: more functions to extend, more new points ----
# Image of n in a cube, one coordinate per function.  1/n tends to 0, so a limit
# point is fixed by the periodic coordinates; count them on a far window of n.
funcs = [("1/n", 1), ("(-1)^n", 2), ("n mod 3", 3), ("n mod 4", 4), ("n mod 5", 5)]
print("Part 3: new points of the closure of N in the cube, function by function")
for k in range(1, len(funcs) + 1):
    periods = [p for _, p in funcs[:k]]
    window = range(10**9, 10**9 + 1000)
    seen = {tuple(n % p for p in periods[1:]) for n in window}
    assert len(seen) == lcm(*periods)
    names = ", ".join(nm for nm, _ in funcs[:k])
    print(f"  {names:<38} new points {len(seen):>2}; lcm of periods {lcm(*periods)}")

# ---- Part 4: the circle, R plus one point ----
def stereo(t):                        # the line onto the circle minus the north pole
    return F(2 * t, 1 + t * t), F(t * t - 1, 1 + t * t)
print("Part 4: R plus one point is the circle (north pole (0, 1) added)")
for t in (0, 1, -1, 1000, -1000):
    x, y = stereo(F(t))
    assert x * x + y * y == 1
    print(f"  t = {t:>5}: ({x}, {y})")
g = lambda t: F(t * t, 1 + t * t)
h = lambda t: F(t, 1 + abs(t))
assert g(1000) == g(-1000) and h(1000) != h(-1000)
print(f"  t^2/(1+t^2) at +-1000: {g(1000)}, {g(-1000)}: one value 1 at the pole, extends")
print(f"  t/(1+|t|)   at +-1000: {h(1000)}, {h(-1000)}: two limits, no value at the pole")

# ---- What breaks ----
print("What breaks")
far = [F((-1) ** n) for n in (1000, 1001, 10**6, 10**6 + 1)]
assert far == [1, -1, 1, -1]
print(f"  one point at infinity for (-1)^n: n = 1000, 1001, 10^6, 10^6+1 give {', '.join(map(str, far))}")
small = [large(lambda n: n <= B, 1) for B in (10, 1000, 10**6)]
assert small == [False, False, False]
print("  unbounded a_n = n: {n <= B} for B = 10, 1000, 10^6 has B members, large: no, no, no")
vals = [F(0), F(1, 2), F(1)]          # maps from the 2-point indiscrete space to [0, 1]
maps = [(u, w) for u in vals for w in vals]     # open set: within 1/4 of c; its pre-image
cont = [m for m in maps if all((abs(m[0] - c) < F(1, 4)) == (abs(m[1] - c) < F(1, 4)) for c in vals)]
assert len(cont) == 3 and all(u == w for u, w in cont)
print(f"  indiscrete 2 points: {len(cont)} of {len(maps)} maps continuous, all constant: 2 points, 1 image")
print("ALL CHECKS PASS")
