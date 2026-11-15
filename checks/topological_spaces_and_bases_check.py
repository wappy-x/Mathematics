# Topological spaces and bases -- the check behind the card.  Standard library only.
# The circle of compass headings is cut into 48 pieces: 24 marks, one every 15 degrees
# (piece 2k is the heading 15k), and the 24 open gaps between them (piece 2k + 1).
# A set of pieces is a 48-bit integer, so every count below is exact.
from math import sin, cos, radians

FULL = (1 << 48) - 1

def arc(a, b):  # open arc: the headings strictly between a and b, going clockwise
    s, n, m = a // 15, ((b - a) % 360) // 15, 0
    for i in range(n):
        m |= 1 << ((2 * (s + i) + 1) % 48)        # a gap
        if i:
            m |= 1 << ((2 * (s + i)) % 48)        # a mark inside the arc
    return m

def mark(h): return 1 << ((2 * (h // 15)) % 48)
def closed(a, b): return arc(a, b) | mark(a) | mark(b)

def basis(step, length=0):  # every open arc whose ends sit on the dial's marks
    lengths = [length] if length else range(step, 360, step)
    return sorted({arc(a, a + L) for a in range(0, 360, step) for L in lengths})

def generate(B):  # road 1: every union of basis arcs, the empty union included
    opens, todo = {0}, [0]
    while todo:
        u = todo.pop()
        for b in B:
            if u | b not in opens:
                opens.add(u | b)
                todo.append(u | b)
    return opens

def lucas(n):  # road 2: walk round the n gaps; a mark between two kept gaps is kept or not
    a, b, c, d = 1, 0, 0, 1                         # M^n with M = [[1, 1], [1, 2]]
    for _ in range(n):
        a, b, c, d = a + b, a + 2 * b, c + d, c + 2 * d
    return a + d

def by_definition(step):  # road 3: test every set of the dial's own pieces, one by one
    B, n = basis(step), 360 // step
    pieces = [mark(step * j) for j in range(n)] + [arc(step * j, step * (j + 1)) for j in range(n)]
    count = 0
    for pick in range(1 << (2 * n)):
        chosen = [p for i, p in enumerate(pieces) if pick >> i & 1]
        U = 0
        for p in chosen:
            U |= p
        # U is open when every piece in it has a basis arc round it lying inside U
        if all(any(p & b and b & ~U == 0 for b in B) for p in chosen):
            count += 1
    return count

def axioms(T, whole):  # empty set and whole set in; unions and intersections of pairs stay in
    return 0 in T and whole in T and all(u | v in T and u & v in T for u in T for v in T)

def pieces_of(m):  # how many separate arcs a set of pieces falls into
    return sum(1 for i in range(48) if m >> i & 1 and not m >> ((i - 1) % 48) & 1)

def finer(Bf, Bc):  # basis test: round every point of every coarse arc, a fine arc inside it
    return all(any(b >> i & 1 and b & ~c == 0 for b in Bf) for c in Bc for i in range(48) if c >> i & 1)

B90, B60, B45, B30, B15 = basis(90), basis(60), basis(45), basis(30), basis(15)
T90, T60, T45, T30 = generate(B90), generate(B60), generate(B45), generate(B30)
print(f"wrap: 330 and 30 are {min((30 - 330) % 360, (330 - 30) % 360)} apart round the circle, {330 - 30} along a ruler")
print("dial      marks  basis arcs  by generation  by Lucas count  by definition")
for name, B, T, d in (("90 deg", B90, T90, by_definition(90)), ("60 deg", B60, T60, by_definition(60)),
                      ("45 deg", B45, T45, by_definition(45)),
                      ("30 deg", B30, T30, "-")):
    n = 360 // int(name[:2])
    print(f"{name:<9} {n:>5}  {len(B):>10}  {len(T):>13}  {lucas(n):>14}  {d:>13}")
    assert len(T) == lucas(n) and d in ("-", len(T))
print(f"15 deg       24  {len(B15):>10}  {'-':>13}  {lucas(24):>14}  {'-':>13}")
by_hand = {}  # 90 deg dial by hand: keep some of the 4 gaps; each mark between two kept gaps doubles
for g in range(16):
    key = (bin(g).count("1"), 2 ** sum(g >> i & 1 and g >> (i + 1) % 4 & 1 for i in range(4)))
    by_hand[key] = by_hand.get(key, 0) + 1
print("by hand, kept gaps: " + "; ".join(f"{k} kept {n} way(s) x {w}" for (k, w), n in sorted(by_hand.items())))
m, M = [[1, 0], [0, 1]], [[1, 1], [1, 2]]
for _ in range(4):
    m = [[sum(m[i][k] * M[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
print(f"M^4 = {m[0][0]} {m[0][1]} / {m[1][0]} {m[1][1]}, trace {m[0][0] + m[1][1]}")
assert sum(n * w for (k, w), n in by_hand.items()) == m[0][0] + m[1][1] == len(T90)

ax90, ax45 = axioms(T90, FULL), axioms(T45, FULL)
print(f"axioms on every pair: 90 deg dial {ax90} ({len(T90) ** 2} pairs), 45 deg dial {ax45} ({len(T45) ** 2} pairs)")
assert ax90 and ax45

pairs = [(b, c) for b in B30 for c in B30]
def inside(m, B):  # the union of every basis arc lying inside m
    u = 0
    for x in B:
        if x & ~m == 0:
            u |= x
    return u

unions_ok = sum(1 for b, c in pairs if inside(b & c, B30) == b & c)
cover = 0
for b in B30:
    cover |= b
two = sum(1 for b, c in pairs if pieces_of(b & c) == 2)
print(f"30 deg basis: covers circle {cover == FULL}, pairs {len(pairs)}, overlap a union of arcs {unions_ok}, two-piece overlaps {two}")
assert cover == FULL and unions_ok == len(pairs)

A, B = arc(330, 210), arc(150, 30)
print(f"example: A=(330,210) B=(150,30) lengths {(210 - 330) % 360} {(30 - 150) % 360}, overlap pieces {pieces_of(A & B)} of 60 and 60, equals (330,30)+(150,210) {A & B == arc(330, 30) | arc(150, 210)}")
assert A & B == arc(330, 30) | arc(150, 210) and pieces_of(A & B) == 2

c90_30, c45_30, c30_45 = T90 <= T30, T45 <= T30, T30 <= T45
print(f"fineness by sets: 90 in 30 {c90_30}, 45 in 30 {c45_30}, 30 in 45 {c30_45}; shared by 45 and 30 {len(T45 & T30)}, all of the 90-dial {T45 & T30 == T90}")
assert T45 & T30 == T90
print(f"fineness by basis test: 30 finer than 90 {finer(B30, B90)}, 30 finer than 45 {finer(B30, B45)}, "
      f"45 finer than 30 {finer(B45, B30)}, 15 finer than both {finer(B15, B45) and finer(B15, B30)}")
assert (c90_30, c45_30, c30_45) == (finer(B30, B90), finer(B30, B45), finer(B45, B30)) == (True, False, False)
print(f"witnesses: (0,45) in 45-dial not 30-dial {arc(0, 45) not in T30}, (0,30) in 30-dial not 45-dial {arc(0, 30) not in T45}")

H = basis(30, 180)
TH = generate(H)
bad = sum(1 for u in TH for v in TH if u & v not in TH)
print(f"wrong: half-circles only: {len(H)} arcs, {len(TH)} unions, axioms {axioms(TH, FULL)}, failing pairs {bad}; "
      f"(0,180)&(90,270) is (90,180) {arc(0, 180) & arc(90, 270) == arc(90, 180)}, in family {arc(90, 180) in TH}")
assert bad > 0 and arc(90, 180) not in TH
P = closed(0, 90) & closed(90, 180)
print(f"wrong: closed arcs [0,90]&[90,180]: pieces {bin(P).count('1')}, just the mark at 90 {P == mark(90)}")
assert P == mark(90)
print(f"wrong: count as fineness: 30 deg has {len(T30)} sets, 45 deg {len(T45)}, yet 45 in 30 is {c45_30}")
pts = " ".join(f"{h}:{150 + 110 * sin(radians(h)):.2f},{150 - 110 * cos(radians(h)):.2f}" for h in (330, 30, 150, 210))
print(f"figure,centre 150,150 radius 110 {pts}")
end = lambda r, h: f"{150 + r * sin(radians(h)):.2f},{150 - r * cos(radians(h)):.2f}"
print(f"figure,A radius 128 from {end(128, 330)} to {end(128, 210)}; B radius 92 from {end(92, 150)} to {end(92, 30)}")
print("ALL CHECKS PASS")
