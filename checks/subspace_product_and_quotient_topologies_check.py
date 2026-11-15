# Subspace, product and quotient topologies -- the check behind the card.
# Standard library only.  Part 1 bends a 100 cm tape into a hoop and a torus
# (lengths in cm).  Part 2 checks finite models exhaustively: the tape squeezed
# to 5 pieces, its ends glued into the four-point circle, and the four-point
# torus.  A set of pieces is a bitmask, so every count in part 2 is exact.
from math import pi, sin, cos, asin, hypot, radians

L, LT = 100, 30                      # the hoop's length and the tube's, cm
R, RT = L / (2 * pi), LT / (2 * pi)  # their radii, cm
f = lambda x: f"{x:.4f}"
yn = lambda c: "yes" if c else "no"

def hoop(t):                         # the wrap map w: tape mark t -> a point of the plane
    a = 2 * pi * t / L
    return (R * cos(a), R * sin(a))

def chord(s, t):                     # straight-line distance in the plane
    (x1, y1), (x2, y2) = hoop(s), hoop(t)
    return hypot(x1 - x2, y1 - y2)

def round_gap(s, t):                 # distance along the glued tape: the shorter way round
    d = abs(s - t) % L
    return min(d, L - d)

def tube(s, t):                      # the torus in space: s round the hole, t round the tube
    a, b = 2 * pi * s / L, 2 * pi * t / LT
    return ((R + RT * cos(b)) * cos(a), (R + RT * cos(b)) * sin(a), RT * sin(b))

print(f"hoop {L} cm round, radius {f(R)} cm; tube {LT} cm round, radius {f(RT)} cm")
print(f"marks 1 and 99: {f(98)} cm apart on the flat tape, {f(round_gap(1, 99))} cm "
      f"round the hoop, chord {f(chord(1, 99))} cm")
pairs = [(k, (37 * k + 11) % L) for k in range(L)]
err = max(abs(chord(s, t) - 2 * R * sin(pi * round_gap(s, t) / L)) for s, t in pairs)
print(f"chord against 2R sin(pi gap / L), checked on {len(pairs)} pairs: worst gap below 1e-9: {yn(err < 1e-9)}")
d_asin = (L / pi) * asin(1 / R)      # road 1: solve 2R sin(pi d / L) = 2
lo, hi = 0.0, L / 2                  # road 2: halve the interval 60 times
for _ in range(60):
    lo, hi = (lo, (lo + hi) / 2) if chord(0, (lo + hi) / 2) > 2 else ((lo + hi) / 2, hi)
print(f"disc of radius 2 cm round the join meets the hoop within {f(d_asin)} cm of mark 0 "
      f"(by asin); by halving {f(lo)}")
print(f"its pre-image on the tape: [0, {f(d_asin)}) and ({f(L - d_asin)}, 100]")
for h in (1, 0.1, 0.01):
    print(f"unglued: mark {f(L - h)} lands {f(chord(0, L - h))} cm from mark 0's point, "
          f"{f(L - h)} cm from it along the tape")
x0, y0 = hoop(d_asin)
print(f"figure, tape 0 to 100 at 6 px per cm; hoop radius {f(R)}; disc radius 2 at "
      f"({f(R)}, 0); arc ends ({f(x0)}, {f(y0)}) and ({f(x0)}, {f(-y0)})")
ends = [tube(0, 0), tube(L, 0), tube(0, LT), tube(L, LT)]
same = all(max(abs(a - b) for a, b in zip(p, ends[0])) < 1e-9 for p in ends)
grid = [tube(5 * i, 5 * j) for i in range(20) for j in range(6)]
res = max(abs((hypot(x, y) - R) ** 2 + z * z - RT * RT) for x, y, z in grid)
gap = min(hypot(*(a - b for a, b in zip(p, q))) for k, p in enumerate(grid) for q in grid[:k])
print(f"torus: the square's 4 corners land on one point: {yn(same)}")
print(f"torus: {len(grid)} grid points, all on the tube to within 1e-9: {yn(res < 1e-9)}; "
      f"closest two {f(gap)} cm apart")

# Part 2: finite models.  A space is a list of smallest open sets, one per piece;
# a set of pieces is open when it holds the smallest open set of each piece in it.
def opens_by_rule(U):
    n = len(U)
    return [S for S in range(1 << n) if all(U[x] & ~S == 0 for x in range(n) if S >> x & 1)]

def names(S, label):
    return "{" + ", ".join(label[i] for i in range(len(label)) if S >> i & 1) + "}"

TAPE = ["0", "(0,1/2)", "1/2", "(1/2,1)", "1"]
CIRC = ["east", "top", "west", "bottom"]
tape = set(opens_by_rule([0b00011, 0b00010, 0b01110, 0b01000, 0b11000]))
q = [0, 1, 2, 3, 0]                  # the glue: mark 0 and mark 1 both go to east
pre = lambda V: sum(1 << i for i in range(5) if V >> q[i] & 1)
quot = [V for V in range(16) if pre(V) in tape]           # road 1: the quotient rule

def piece(a):                        # road 2: a circle point at angle a, placed by its coordinates
    x, y = cos(radians(a)), sin(radians(a))
    return 1 if y > 1e-9 else 3 if y < -1e-9 else 0 if x > 0 else 2
near = [sum({1 << piece(a + da) for da in (-1, 0, 1)}) for a in (0, 90, 180, 270)]
plane = opens_by_rule(near)          # traces on the circle of small discs in the plane

def is_topology(fam):
    return all(a | b in fam and a & b in fam for a in fam for b in fam)
cands = []                           # road 3: every topology on 4 points that makes q continuous
for m in range(1 << 14):
    fam = {0, 15} | {v for v in range(1, 15) if m >> (v - 1) & 1}
    if all(pre(V) in tape for V in fam) and is_topology(fam):
        cands.append(fam)
big = max(cands, key=len)
print(f"tape in 5 pieces: {len(tape)} open sets; {sum(1 for S in tape if S & 0b10001)} of them hold an end mark")
print(f"glued, by the quotient rule: {len(quot)} open sets: " + " ".join(names(V, CIRC) for V in quot))
print(f"circle in the plane, by small discs: {len(plane)} open sets; same family: {yn(plane == quot)}")
print(f"topologies making the glue continuous: {len(cands)}; largest has {len(big)} sets, "
      f"holds every other: {yn(all(c <= big for c in cands))}; same family: {yn(sorted(big) == quot)}")
bad = 0b00011                        # the open set {0, (0,1/2)} of the tape
print(f"image of the open set {names(bad, TAPE)} is {names(1 | 2, CIRC)}: open? {yn((1 | 2) in quot)}")

box = lambda U, V: sum(1 << (4 * x + y) for x in range(4) for y in range(4) if U >> x & 1 and V >> y & 1)
boxes = {box(U, V) for U in quot for V in quot}
unions, todo = set(boxes), list(boxes)                    # road 1: every union of boxes
while todo:
    u = todo.pop()
    for b in boxes:
        if u | b not in unions:
            unions.add(u | b)
            todo.append(u | b)
rule = opens_by_rule([box(near[x], near[y]) for x in range(4) for y in range(4)])  # road 2
print(f"torus of 16 pieces: {len(boxes)} distinct boxes; {len(unions)} open sets as unions of boxes")
print(f"the same {len(rule)} open sets by the smallest-open-set rule: {yn(sorted(unions) == rule)}")
slices = []
for y in range(4):                   # the subspace circle x {y} inside the torus
    trace = sorted({sum(1 << x for x in range(4) if W >> (4 * x + y) & 1) for W in rule})
    slices.append(trace == quot)
print(f"each of the 4 slices circle x {{point}} carries the circle's 7 open sets: {yn(all(slices))}")

assert abs(d_asin - lo) < 1e-9 and err < 1e-9             # two roads to the arc; chord vs gap
assert plane == quot == sorted(big) and all(c <= big for c in cands)
assert len(quot) == 7 and len(tape) == 13 and (1 | 2) not in quot
assert sorted(unions) == rule and all(slices) and same and res < 1e-9 and gap > 0.1
print("ALL CHECKS PASS")
