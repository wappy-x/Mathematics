# Open and closed sets -- the check behind the card.  Standard library only.
# A city grid measured in blocks, Central Station at (0, 0).  Zone 1 is every
# spot whose walking distance from Central is under 5 blocks.  Arithmetic is
# exact (fractions); the straight line is compared through its square.
from fractions import Fraction as F
from itertools import combinations
import math

C, R = (0, 0), 5
PLACES = [("Central", (0, 0)), ("Cafe", (2, 1)), ("Library", (3, 2)), ("Stadium", (4, 3))]
LIB = (3, 2)

def walk(p, q):                       # d_1: blocks east-west plus blocks north-south
    return abs(p[0] - q[0]) + abs(p[1] - q[1])

def line_sq(p, q):                    # d_2 squared, kept exact
    return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2

def grid_ball(x, r, step=F(1, 4)):    # every quarter-block grid point within walking distance < r of x
    n = int(r / step) + 1
    pts = [(x[0] + i * step, x[1] + j * step) for i in range(-n, n + 1) for j in range(-n, n + 1)]
    return [p for p in pts if walk(x, p) < r]

def fmt(v):
    return str(v) if F(v).denominator == 1 else f"{float(v):g}"

print("place: walking blocks from Central, straight-line blocks")
for name, p in PLACES:
    print(f"  {name} {p}: walk {walk(C, p)}, straight {math.sqrt(line_sq(C, p)):.3f}")

# Road one to the room: the formula.  Road two: search the quarter-block grid.
cafe, stad = (2, 1), (4, 3)
for name, x, inside in (("Cafe", cafe, True), ("Stadium", stad, False)):
    room = R - walk(C, x) if inside else walk(C, x) - R
    ball = grid_ball(x, room)
    far = [walk(C, p) for p in ball]
    ok = all((d < R) if inside else (d > R) for d in far)
    wider = grid_ball(x, room + F(1, 4))
    bad = [p for p in wider if ((walk(C, p) >= R) if inside else (walk(C, p) <= R))]
    print(f"{name}: room {room} by formula; {len(ball)} grid points within {room} all on the same side: "
          f"{'yes' if ok else 'no'} (walking from Central {fmt(min(far))} to {fmt(max(far))}); "
          f"radius {fmt(room + F(1, 4))} crosses at {len(bad)} points")
    assert ok and bad and room == 2

print("Library on the rim: every ball holds a point inside and a point outside")
for r in (F(1), F(1, 10), F(1, 100), F(1, 1000)):
    a, b = (LIB[0] - r / 2, LIB[1]), (LIB[0] + r / 2, LIB[1])
    print(f"  r = {fmt(r)}: ({fmt(a[0])}, 2) walks {fmt(walk(C, a))}, ({fmt(b[0])}, 2) walks {fmt(walk(C, b))}")
    assert walk(LIB, a) < r and walk(LIB, b) < r and walk(C, a) < R < walk(C, b)

RULES = [("under 5 blocks", lambda p: walk(C, p) < R),
         ("at most 5 blocks", lambda p: walk(C, p) <= R),
         ("under 5, plus the Library", lambda p: walk(C, p) < R or p == LIB),
         ("the whole city", lambda p: True),
         ("no zone at all", lambda p: False)]
PROBES = [p for _, p in PLACES] + [(5, 0), (0, -5), (F(-5, 2), F(5, 2)), (1, -1), (-6, 0)]

def has_room(S, p, side):             # road one: does a sampled ball around p stay on p's side?
    for r in (F(1), F(1, 10), F(1, 100), F(1, 1000)):
        pts = [p] + [(p[0] + u * r / 2, p[1] + v * r / 2) for u, v in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        if all(S(q) == side for q in pts):
            return True
    return False

def verdict(op, cl):
    return {(1, 0): "open", (0, 1): "closed", (1, 1): "both", (0, 0): "neither"}[(op, cl)]

print(f"five fare rules, {len(PROBES)} probe points, two roads")
for i, (name, S) in enumerate(RULES):
    op1 = all(has_room(S, p, True) for p in PROBES if S(p))
    cl1 = all(has_room(S, p, False) for p in PROBES if not S(p))
    rim = [p for p in PROBES if walk(C, p) == R] if i < 3 else []    # road two: the rim rule
    op2, cl2 = not any(S(p) for p in rim), all(S(p) for p in rim)
    print(f"  {name}: sampled balls {verdict(op1, cl1)}, rim rule {verdict(op2, cl2)}")
    assert (op1, cl1) == (op2, cl2) == [(1, 0), (0, 1), (0, 0), (1, 1), (1, 1)][i]

ins = all(walk(C, LIB) < R + F(1, n) for n in range(1, 1001))
first = next(n for n in range(1, 2001) if walk(C, (F(2999, 1000), 2)) <= R - F(1, n))
print(f"Library in every zone 'under 5 + 1/n', n = 1 to 1000: {'yes' if ins else 'no'}; in 'under 5': "
      f"{'yes' if walk(C, LIB) < R else 'no'}")
print(f"(2.999, 2) first inside 'at most 5 - 1/n' at n = {first}; the Library never")
assert ins and first == 1000

# Downtown: 0 < east < 6, 0 < north < 4.  Build it from balls centred on finer grids.
def room_dt(q):
    return min(q[0], 6 - q[0], q[1], 4 - q[1])

def centres(k):                       # stage k: grid points 1/2^k apart, strictly inside
    n = 2 ** k
    return [(F(i, n), F(j, n)) for i in range(1, 6 * n) for j in range(1, 4 * n)]

def first_stage(p):
    for k in range(9):
        s = F(1, 2 ** k)
        cs = [(p[0] // s * s + i * s, p[1] // s * s + j * s) for i in range(-3, 4) for j in range(-3, 4)]
        if any(room_dt(q) > 0 and walk(p, q) < room_dt(q) for q in cs):
            return k

counts = [len(centres(k)) for k in range(4)]
spill = [q for k in range(4) for q in centres(k)    # a ball's four tips must stay in the closed rectangle
         if not (0 <= q[0] - room_dt(q) and q[0] + room_dt(q) <= 6
                 and 0 <= q[1] - room_dt(q) and q[1] + room_dt(q) <= 4)]
print(f"Downtown: balls at stages 0 to 3: {counts}; balls poking out: {len(spill)}")
for p in ((3, 2), (F(1, 100), 2), (F(1, 2), F(1, 2)), (F(1, 100), F(1, 100))):
    print(f"  ({fmt(p[0])}, {fmt(p[1])}): room {fmt(room_dt(p))}, first covered at stage {first_stage(p)}")
assert not spill and first_stage((F(1, 100), F(1, 100))) == 6

stops = [p for _, p in PLACES]
gap = min(walk(p, q) for p, q in combinations(stops, 2))
subs = [set(c) for k in range(5) for c in combinations(stops, k)]
both = all(all({q for q in stops if walk(p, q) < gap / 2} <= A for p in A) and
           all({q for q in stops if walk(p, q) < gap / 2} <= set(stops) - A for p in set(stops) - A)
           for A in subs)
unions = all(A == set().union(*({q for q in stops if walk(p, q) < gap / 2} for p in A)) for A in subs)
print(f"four stops only: closest pair {gap} blocks apart; all {len(subs)} subsets open and closed: "
      f"{'yes' if both else 'no'}; each a union of one-stop balls: {'yes' if unions else 'no'}")
o5, o6, c5 = ([n for n, p in PLACES if test(walk(C, p))] for test in
              (lambda d: d < 5, lambda d: d < 6, lambda d: d <= 5))
print(f"  among stops: under 5 blocks {', '.join(o5)}; under 6 blocks {', '.join(o6)}; "
      f"at most 5 blocks {', '.join(c5)}")
assert both and unions and gap == 2 and len(subs) == 16 and o6 == c5 != o5
fine = [walk(C, p) for p in grid_ball(cafe, 2, F(1, 8))]
cross = sum(walk(C, p) >= R for p in grid_ball(cafe, F(9, 4), F(1, 8)))
print(f"try: step 1/8: {len(fine)} grid points within 2 of the Cafe, walking {fmt(min(fine))} to "
      f"{fmt(max(fine))}; radius 2.25 crosses at {cross} points")
print(f"try: Cafe at (2, 2): room {R - walk(C, (2, 2))}, {len(grid_ball((2, 2), R - walk(C, (2, 2))))} grid points; "
      f"(0.1, 0.1) first covered at stage {first_stage((F(1, 10), F(1, 10)))}")

far_pt = (F(2999, 1000) + F(1999, 1000), 2)
print(f"mistake, one room for the whole zone: the ball of radius 2 round (2.999, 2) holds "
      f"({fmt(far_pt[0])}, 2), which walks {fmt(walk(C, far_pt))} blocks")
s1 = 1 + math.sqrt(4 - 1)
print(f"mistake, squared distance on a line: zone (-2, 2), point 1, room 4 - 1 = 3, ball reaches {s1:.3f}")
px = [f"{n} ({180 + 30 * p[0]}, {200 - 30 * p[1]})" for n, p in PLACES + [("east tip", (5, 0)), ("north tip", (0, 5))]]
print("figure, 30 px per block: " + ", ".join(px))
print("ALL CHECKS PASS")
