# Continuity and homeomorphism -- the check behind the card.  Standard library only.
# Three maps: the wrap w(t) = (cos t, sin t) from [0, 2pi) onto the circle; the
# radial maps s (circle to square, pasted from two pieces) and r (square to
# circle); and the stretch h(x) = x / (1 - |x|) from (-1, 1) onto the line.
from fractions import Fraction as F
from math import atan2, cos, isqrt, pi, sin

def rad(t): return f"{t:.6f}"
# 1. The wrap.  Pre-image of the open arc of angles (-30, 30) degrees, two roads.
N = 7200
ts = [2 * pi * (k + 0.5) / N for k in range(N)]       # sample points of [0, 2pi)
scan = [t for t in ts if abs(atan2(sin(t), cos(t))) < pi / 6]        # road 1
formula = [t for t in ts if t < pi / 6 or t > 11 * pi / 6]           # road 2
print(f"pre-image of the arc (-30, 30) degrees under w: [0, {rad(pi / 6)}) "
      f"and ({rad(11 * pi / 6)}, {rad(2 * pi)})")
print(f"  scan of {N} points of [0, 2pi): {len(scan)} inside, formula agrees: "
      f"{'yes' if scan == formula else 'NO'}")
winv = lambda p: atan2(p[1], p[0]) % (2 * pi)       # the inverse of w, as an angle
tears = []
for k in (10, 100, 1000):
    p = (cos(-1 / k), sin(-1 / k))                  # just below (1, 0) on the circle
    gap = ((p[0] - 1) ** 2 + p[1] ** 2) ** 0.5
    tears.append(winv(p))
    print(f"angle -1/{k}: {gap:.6f} from (1, 0), w-inverse {winv(p):.6f} "
          f"against 0 at (1, 0)")

# 2. Circle and square.  s is pasted: p/|x| where |x| >= |y|, p/|y| where |y| >= |x|.
def s(p):
    x, y = p
    m = abs(x) if abs(x) >= abs(y) else abs(y)
    return (x / m, y / m)
def fsqrt(q):                                       # exact root of a square Fraction
    a, b = isqrt(q.numerator), isqrt(q.denominator)
    assert a * a == q.numerator and b * b == q.denominator
    return F(a, b)
def r(q): n = fsqrt(q[0] ** 2 + q[1] ** 2); return (q[0] / n, q[1] / n)
pts = set()                                          # rational points on the circle
for b in range(1, 13):
    for a in range(0, b + 1):
        t = F(a, b); x, y = (1 - t * t) / (1 + t * t), 2 * t / (1 + t * t)
        for u, v in ((x, y), (y, x)):
            pts |= {(u, v), (-u, v), (u, -v), (-u, -v)}
on_circle = all(x * x + y * y == 1 for x, y in pts)
on_square = all(max(abs(c) for c in s(p)) == 1 for p in pts)
back = all(r(s(p)) == p for p in pts)                # road 1: exact round trips
fmt = lambda q: f"({q[0]}, {q[1]})"
for p in ((F(4, 5), F(3, 5)), (F(3, 5), F(4, 5))):
    print(f"s{fmt(p)} = {fmt(s(p))}, r{fmt(s(p))} = {fmt(r(s(p)))}")
print(f"{len(pts)} rational points of the circle: all land on the square "
      f"{'yes' if on_square else 'NO'}, r(s(p)) = p exactly {'yes' if back else 'NO'}")
rf = lambda q: (q[0] / (q[0] ** 2 + q[1] ** 2) ** 0.5, q[1] / (q[0] ** 2 + q[1] ** 2) ** 0.5)
circ = [(cos(2 * pi * k / 3600), sin(2 * pi * k / 3600)) for k in range(3600)]
err1 = max(max(abs(a - b) for a, b in zip(rf(s(p)), p)) for p in circ)  # road 2
sq = [s(p) for p in circ]
err2 = max(max(abs(a - b) for a, b in zip(s(rf(q)), q)) for q in sq)
step = max(max(abs(a - b) for a, b in zip(sq[k], sq[k - 1])) for k in range(3600))
print(f"3600 points 0.1 degree apart: r(s(p)) = p and s(r(q)) = q to 1e-12: "
      f"{'yes' if max(err1, err2) < 1e-12 else 'NO'}")
print(f"  neighbours {2 * sin(pi / 3600):.6f} apart land at most {step:.6f} apart")
seam = max(abs(abs(x) - abs(y)) for x, y in
           [(cos(a * pi / 4), sin(a * pi / 4)) for a in (1, 3, 5, 7)])
print(f"overlap |x| = |y|: the two pieces of s agree to 1e-12 at all 4 points: "
      f"{'yes' if seam < 1e-12 else 'NO'}")
bad = (F(20, 29), F(21, 29))
print(f"wrong: p/|x| on the whole circle sends {fmt(bad)} to "
      f"{fmt((bad[0] / bad[0], bad[1] / bad[0]))}, off the square")

# 3. The stretch h: (-1, 1) onto the line, pasted from x/(1 - x) and x/(1 + x).
h = lambda x: x / (1 - x) if x >= 0 else x / (1 + x)
hinv = lambda y: y / (1 + abs(y))
xs = {F(a, b) for b in range(1, 41) for a in range(-b + 1, b)}
print(f"h(1/2) = {h(F(1, 2))}, h(9/10) = {h(F(9, 10))}, h(99/100) = {h(F(99, 100))}, "
      f"h-inverse(99) = {hinv(F(99))}")
round_h = all(hinv(h(x)) == x for x in xs) and all(h(hinv(F(y))) == y for y in range(-500, 501))
print(f"{len(xs)} fractions in (-1, 1) and 1001 whole numbers: round trips exact "
      f"{'yes' if round_h else 'NO'}")

# 4. Pieces left after removing one point, on graph models (an illustration).
def pieces(nodes, edges, gone):
    left, seen, count = [v for v in nodes if v != gone], set(), 0
    for v in left:
        if v in seen: continue
        count += 1; stack = [v]; seen.add(v)
        while stack:
            u = stack.pop()
            for w2 in edges[u]:
                if w2 != gone and w2 not in seen: seen.add(w2); stack.append(w2)
    return count
n = 12
cyc = {i: [(i - 1) % n, (i + 1) % n] for i in range(n)}
path = {i: [j for j in (i - 1, i + 1) if 0 <= j < n] for i in range(n)}
tor = {(i, j): [((i + 1) % 6, j), ((i - 1) % 6, j), (i, (j + 1) % 6), (i, (j - 1) % 6)]
       for i in range(6) for j in range(6)}
cut = {name: sorted(pieces(list(g), g, v) for v in g)
       for name, g in (("circle", cyc), ("interval", path), ("torus", tor))}
for name, c in cut.items():
    print(f"{name} model, {len(c)} points: remove one, pieces "
          + ", ".join(f"{c.count(k)} times {k}" for k in sorted(set(c))))

# 5. Gluing that fails: 0 on [0, 1) and 1 on [1, 2]; the right piece is closed, the left is not.
step_f = lambda x: 0 if x < 1 else 1
jumps = [step_f(1 - F(1, k)) for k in range(1, 1001)]
grid = [F(i, 1000) for i in range(2001)]             # [0, 2] in steps of 1/1000
pre_step = [x for x in grid if F(1, 2) < step_f(x) < F(3, 2)]
print(f"wrong: 0 on [0, 1), 1 on [1, 2]: f(1) = {step_f(F(1))}, f(1 - 1/k) = "
      f"{max(jumps)} for k = 1..1000")
print(f"  pre-image of (1/2, 3/2): {len(pre_step)} of {len(grid)} grid points, "
      f"from {min(pre_step)} to {max(pre_step)}: [1, 2], not open")
lpiece, rpiece = (lambda x: x), (lambda x: x + 1)
print(f"wrong: x on [0, 1], x + 1 on [1, 2]: at 1 the pieces give {lpiece(1)} and {rpiece(1)}")
px = lambda q: f"({float(210 + 150 * q[0]):g}, {float(210 - 150 * q[1]):g})"
print("figure, 150 units a step, centre (210, 210): " + ", ".join(
    f"{fmt(q)} at {px(q)}" for p in ((F(4, 5), F(3, 5)), (F(3, 5), F(4, 5))) for q in (p, s(p))))

# 6. The mug's cup, 8 cm across and 9 cm deep, flattened onto a disc: a cup point is (radius, depth) in cm.
wall = lambda d: 4 - F(2, 9) * d                     # inside wall at depth d -> radius on the disc
floor = lambda rho: rho / 2                          # floor at radius rho -> radius on the disc
flat = lambda p: wall(p[1]) if p[0] == 4 else floor(p[0])
unflat = lambda x: (F(4), (4 - x) * F(9, 2)) if x >= 2 else (2 * x, F(9))   # pasted at radius 2
cup = {(F(4), F(k, 10)) for k in range(91)} | {(F(k, 10), F(9)) for k in range(41)}
disc = [F(k, 100) for k in range(401)]
cup_back = all(unflat(flat(p)) == p for p in cup) and all(flat(unflat(x)) == x for x in disc)
print("mug: cup 8 cm across, 9 cm deep; on the disc, wall depth d goes to radius 4 - (2/9) d, floor radius to half")
print(f"  wall depth 9/2 goes to radius {wall(F(9, 2))}, wall foot to {wall(F(9))}, floor edge to {floor(F(4))}")
print(f"  {len(cup)} points of wall and floor, {len(disc)} radii of the disc: round trips exact "
      f"{'yes' if cup_back else 'NO'}")

assert scan == formula and len(scan) == N // 6       # two roads to the pre-image
assert all(abs(t - (2 * pi - 1 / k)) < 1e-12 and t > 6 for t, k in zip(tears, (10, 100, 1000)))
assert on_circle and on_square and back and len(pts) == 252
assert err1 < 1e-12 and err2 < 1e-12 and seam < 1e-12 and step < 2.01 * 2 * sin(pi / 3600)
assert round_h and h(F(99, 100)) == 99 and hinv(F(99)) == F(99, 100)
assert cut["circle"] == [1] * 12 and cut["interval"] == [1, 1] + [2] * 10
assert cut["torus"] == [1] * 36 and max(jumps) == 0
assert min(pre_step) == 1 and max(pre_step) == 2 and len(pre_step) == 1001
assert cup_back and wall(F(9)) == floor(F(4)) and len(cup) == 131   # pieces agree at the seam
print("ALL CHECKS PASS")
