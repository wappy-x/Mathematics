# Closure, interior and boundary -- the check behind the card.  Standard library
# only.  Part 1 has no distances: the circle squeezed to four points, top,
# bottom, east and west, with seven open sets.  All 16 subsets are tested, so
# every identity printed there is proved for that space.  Part 2 finds fractions
# in shrinking bands around root 2, exactly, two ways; it illustrates the proof.
from fractions import Fraction as F
from itertools import combinations

X = ("top", "bottom", "east", "west")
OPEN = [frozenset(s) for s in ([], ["top"], ["bottom"], ["top", "bottom"],
        ["top", "bottom", "east"], ["top", "bottom", "west"], list(X))]
ALL = [frozenset(c) for r in range(5) for c in combinations(X, r)]
EVERY = frozenset(X)
GLUED = [a for a in ALL if not a & {"east", "west"} or {"top", "bottom"} <= a]  # quotient rule

def show(s):
    return "{" + ", ".join(p for p in X if p in s) + "}"

def yn(claim):
    return "yes" if claim else "no"

def dec(n, k):                             # the whole number n / 10^k, exactly
    return f"{n // 10 ** k}.{n % 10 ** k:0{k}d}"

def interior(a, opens):                    # union of the open sets inside a
    return frozenset().union(*[u for u in opens if u <= a])

def closure_closed(a, opens):              # road 1: meet of closed sets holding a
    return EVERY.intersection(*[EVERY - u for u in opens if a <= EVERY - u])

def closure_touch(a, opens):               # road 2: every open set round x meets a
    return frozenset(x for x in X if all(u & a for u in opens if x in u))

def closure_swap(a, opens):                # road 3: the rest of the rest's interior
    return EVERY - interior(EVERY - a, opens)

def limit_points(a, opens):                # meets a somewhere other than x itself
    return frozenset(x for x in X if all((u & a) - {x} for u in opens if x in u))

def boundary(a, opens):
    return closure_touch(a, opens) - interior(a, opens)

unions = all(frozenset().union(*f) in OPEN
             for r in range(8) for f in combinations(OPEN, r))
overlaps = all(u & v in OPEN for u in OPEN for v in OPEN)
top = frozenset(["top"])
print("Part 1: the circle squeezed to four points: top, bottom, east, west")
print("open sets:", ", ".join(show(u) for u in OPEN))
print(f"open sets by the gluing rule, east or west only with top and bottom: {len(GLUED)}; "
      f"same family: {yn(set(GLUED) == set(OPEN))}")
print(f"every union and every overlap of open sets is open: {yn(unions and overlaps)}")
print("A = {top}, the open upper arc")
print(f"  interior {show(interior(top, OPEN))}; closure {show(closure_touch(top, OPEN))}; "
      f"boundary {show(boundary(top, OPEN))}; limit points {show(limit_points(top, OPEN))}")
seq_limits = frozenset(x for x in X if all("top" in u for u in OPEN if x in u))
print(f"  the sequence top, top, top, ... converges to {show(seq_limits)}")
three = all(closure_closed(a, OPEN) == closure_touch(a, OPEN) == closure_swap(a, OPEN) for a in ALL)
plus = all(closure_touch(a, OPEN) == a | limit_points(a, OPEN) for a in ALL)
edge = all(boundary(a, OPEN) == closure_touch(a, OPEN) & closure_touch(EVERY - a, OPEN) for a in ALL)
dense = [a for a in ALL if closure_touch(a, OPEN) == EVERY]
print(f"all {len(ALL)} subsets: the three roads to the closure agree: {yn(three)}")
print(f"all {len(ALL)} subsets: closure = the set plus its limit points: {yn(plus)}")
print(f"all {len(ALL)} subsets: boundary = closure of the set, met with closure of the rest: {yn(edge)}")
print(f"dense subsets: {len(dense)} of {len(ALL)}: " + ", ".join(show(a) for a in dense))
te = frozenset(["top", "east"])
indiscrete, discrete = [frozenset(), EVERY], ALL
print(f"mistake 1, boundary of {{top}} as the set minus its interior: {show(top - interior(top, OPEN))}")
print(f"mistake 2, A = {{top, east}}: closure of the interior {show(closure_touch(interior(te, OPEN), OPEN))}, "
      f"interior of the closure {show(interior(closure_touch(te, OPEN), OPEN))}")
print(f"mistake 3, closure of {{top}}: indiscrete {show(closure_touch(top, indiscrete))}, "
      f"discrete {show(closure_touch(top, discrete))}")
px, py, push = F(3, 5), F(4, 5), F(2001, 2000)
r2 = (px * push) ** 2 + (py * push) ** 2
print(f"mistake 4, the circle inside the plane: (3/5, 4/5) pushed out by 1/2000 "
      f"has x^2 + y^2 = {r2} = {dec(int(r2 * 10 ** 8), 8)}, off the circle")

def isqrt(n):                              # largest whole r with r * r <= n
    lo, hi = 0, n + 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if mid * mid <= n else (lo, mid)
    return lo

def archimedes(s, t):                      # n past 1/(t - s), then step past s
    n = int(1 / (t - s)) + 1
    return F(int(n * s) + 1, n), n

def simplest(s, t):                        # Stern-Brocot: mediants, smallest bottom
    (p1, q1), (p2, q2) = (0, 1), (1, 0)
    while True:
        p, q = p1 + p2, q1 + q2
        if F(p, q) <= s:
            p1, q1 = p, q
        elif F(p, q) >= t:
            p2, q2 = p, q
        else:
            return F(p, q)

print("Part 2: bands around root 2, the diagonal of a 1-metre tile, in metres")
for k in (3, 6, 9, 12):
    lo = isqrt(2 * 10 ** (2 * k))
    s = F(lo, 10 ** k)
    t = s + F(1, 10 ** k)
    a, n = archimedes(s, t)
    b = simplest(s, t)
    print(f"width 10^-{k}: ({dec(lo, k)}, {dec(lo + 1, k)}); root 2 inside: {yn(s * s < 2 < t * t)}; "
          f"Archimedes {a}; simplest {b}")
    assert s < a < t and s < b < t and s * s < 2 < t * t                 # in the band
    assert b.denominator <= n                                             # simplest is smallest
    if k == 3:
        none = all(not (s < F(p, q) < t) for q in range(1, b.denominator) for p in range(2 * q + 1))
        print(f"  checked: no fraction with bottom below {b.denominator} lies in this band: {yn(none)}")
        assert none                                                       # brute force agrees
        print(f"  a non-fraction in it: 1.414 + 0.001/root 2 = 1.414{isqrt(10 ** 8 // 2)}...")
assert set(GLUED) == set(OPEN) and unions and overlaps and three and plus and edge
assert closure_touch(top, OPEN) == {"top", "east", "west"} and interior(top, OPEN) == top
assert limit_points(top, OPEN) == {"east", "west"}                       # top is not its own limit
assert len(dense) == 4 and closure_touch(top, indiscrete) == EVERY and r2 != 1
print("figure, circle centre (0, 0) radius 1; east (1, 0); west (-1, 0); top arc y > 0; bottom arc y < 0")
print("ALL CHECKS PASS")
