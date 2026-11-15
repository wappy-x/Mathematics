# Urysohn, Tietze and metrisation -- the check behind the card.  Standard library only.
# Room floor in metres: corners (0,0), (6,0), (3,4), (0,4).  Wall A runs (0,0)-(0,4); the far
# wall B runs (6,0)-(3,4), a 3-4-5 slant.  Temperatures on the walls are in degrees C.
from math import sqrt, log10, atan2, pi, cos, sin
from fractions import Fraction as Fr

def seg(p, a, b):  # distance from p to the segment a-b: project, clamp to the ends, measure
    (px, py), (ax, ay), (bx, by) = p, a, b
    t = ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / ((bx - ax) ** 2 + (by - ay) ** 2)
    t = min(1.0, max(0.0, t))
    return sqrt((px - ax - t * (bx - ax)) ** 2 + (py - ay - t * (by - ay)) ** 2)
dA = lambda p: seg(p, (0, 0), (0, 4))
dB = lambda p: seg(p, (6, 0), (3, 4))
dial = lambda p: dA(p) / (dA(p) + dB(p))     # Urysohn's dial in a metric space
def exact(x, y):  # second road: wall A is x itself, wall B is the 3-4-5 line, exact fractions
    a, b = Fr(x), (24 - 4 * Fr(x) - 3 * Fr(y)) / 5
    return a, b, a / (a + b)
room = [(i / 4, j / 4) for i in range(25) for j in range(17) if 4 * i + 3 * j <= 96]
print(f"room grid every 0.25 m: {len(room)} points; gap between walls {min(dA(p) + dB(p) for p in room):.4f} m")
a, b, f = exact(3, 1)
print(f"P=(3,1): dA={a} dB={b} dial={f} = {float(f):.4f}; by projection {dial((3, 1)):.4f}")
assert f == Fr(5, 8) and abs(dial((3, 1)) - 5 / 8) < 1e-12
row = []
for x in (0, 1, 2, 3, 4, 4.5):
    a, b, f = exact(x, 2)
    assert abs(dial((x, 2)) - float(f)) < 1e-12
    row.append(f"{x}:{float(f):.4f}")
print("along y=2, x:dial  " + "  ".join(row))
ends = [dial((0, y)) for y in range(5)] + [dial((6 - 3 * s / 5, 4 * s / 5)) for s in range(6)]
print("on wall A: " + " ".join(f"{v:.4f}" for v in ends[:5]) + "; on wall B: " + " ".join(f"{v:.4f}" for v in ends[5:]))
assert max(ends[:5]) == 0 and min(ends[5:]) > 1 - 1e-12
slope = max(abs(dial(p) - dial(q)) / sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2)
            for i, p in enumerate(room) for q in room[:i])
print(f"steepest dial change between grid points: {slope:.4f} per m; proved bound 1/gap = {1 / 3:.4f}")
assert 0 < slope <= 1 / 3 + 1e-12
# Tietze: wall A reads 16 + 2y, wall B reads 24 - 1.6 s (s = metres from (6,0)); scaled g = (T - 20)/4
walls = [((0.0, k / 6), (2 * k / 6 - 4) / 4) for k in range(25)] + \
        [((6 - 3 * (5 * k / 24) / 5, 4 * (5 * k / 24) / 5), (4 - 1.6 * 5 * k / 24) / 4) for k in range(25)]
near = lambda p, S: min(sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2) for q in S)
def step(r, M):  # one Urysohn dial: -M/3 where r <= -M/3, +M/3 where r >= M/3, between elsewhere
    lo = [q for q, v in r if v <= -M / 3 + 1e-12]
    hi = [q for q, v in r if v >= M / 3 - 1e-12]
    return lambda p: M / 3 * (near(p, lo) - near(p, hi)) / (near(p, lo) + near(p, hi)), lo, hi
P, r, M, us, errs = (3, 1), list(walls), 1.0, [], []
for n in range(13):
    errs.append(max(abs(v) for q, v in r))
    assert abs(errs[-1] - (2 / 3) ** n) < 1e-9   # the remainder meets its proved bound (2/3)^n
    if n == 12:
        break
    u, lo, hi = step(r, M)
    if n == 0:
        print(f"step 1 at P: nearest hot {near(P, hi):.4f} m (sqrt37/3 = {sqrt(37) / 3:.4f}), "
              f"nearest cold {near(P, lo):.4f} m (sqrt34/3 = {sqrt(34) / 3:.4f}), u = {u(P):.6f}")
    us.append(u)
    r, M = [(q, v - u(q)) for q, v in r], 2 * M / 3
F = lambda p, N=12: sum(u(p) for u in us[:N])
print("chart,n " + " ".join(str(n) for n in range(13)))
print("chart,log10 worst wall error " + " ".join(f"{log10(e):.3f}" for e in errs))
print("Tietze at P, degrees C: " + "  ".join(f"N={N}:{20 + 4 * F(P, N):.3f}" for N in (1, 2, 3, 6, 12)))
top = max(abs(F(p)) for p in room)
print(f"after 12 steps: worst wall error {4 * errs[12]:.4f} C; room spans {20 - 4 * top:.3f} to {20 + 4 * top:.3f} C "
      f"(proved inside 20 +- {4 * (1 - (2 / 3) ** 12):.3f})")
assert top <= 1 - (2 / 3) ** 12 + 1e-12 and abs(20 + 4 * F(P, 1) - (20 + 4 / 3 * (sqrt(34) - sqrt(37)) / (sqrt(34) + sqrt(37)))) < 1e-12
def blend(p):  # a second extension: weigh the nearest reading on each wall by the dial
    x, y = p
    gA = (2 * min(4.0, max(0.0, y)) - 4) / 4
    t = min(5.0, max(0.0, (-3 * (x - 6) + 4 * y) / 5))
    return (dB(p) * gA + dA(p) * (4 - 1.6 * t) / 4) / (dA(p) + dB(p))
bw = max(abs(blend(q) - v) for q, v in walls)
print(f"blend extension at P {20 + 4 * blend(P):.3f} C; largest miss on the walls below 1e-12 {bw < 1e-12}; "
      f"inside 16 to 24 C {max(abs(blend(p)) for p in room) <= 1}")
assert bw < 1e-12 and abs(20 + 4 * blend(P) - 19.15) < 1e-9
# metrisation on the circle, [0,1] with its ends glued: t = j/24; three tent dials centred at 0, 1/3, 2/3
dials = lambda j: [12 - min((j - c) % 24, (c - j) % 24) for c in (0, 8, 16)]  # in twelfths
D = lambda i, j: sum(w * abs(x - y) for w, x, y in zip((4, 2, 1), dials(i), dials(j)))  # in 96ths
arc = lambda i, j: min((i - j) % 24, (j - i) % 24)                                     # in 24ths
pairs = [(i, j) for i in range(24) for j in range(24) if i != j]
tri = all(D(i, k) <= D(i, j) + D(j, k) for i in range(24) for j in range(24) for k in range(24))
print(f"dial metric on 24 points: zero only on the diagonal {all(D(i, j) > 0 for i, j in pairs)}, "
      f"symmetric {all(D(i, j) == D(j, i) for i, j in pairs)}, triangle on 13824 triples {tri}")
assert tri and all(D(i, j) > 0 for i, j in pairs)
rat = sorted(Fr(D(i, j), 4 * arc(i, j)) for i, j in pairs)
print(f"D / arc length: from {rat[0]} to {rat[-1]}")
assert rat[0] == Fr(1, 2)
print(f"dials at 1/24: {dials(1)}, at 23/24: {dials(23)} (twelfths); D(1/24, 23/24) = {Fr(D(1, 23), 96)} "
      f"though |1/24 - 23/24| = 11/12; D(1/4, 3/4) = {Fr(D(6, 18), 96)}")
assert D(1, 23) < D(6, 18)
# what breaks
print("B touching A along (x,2), 0<x<=1: the dial must jump 1 across x m, slope " +
      ", ".join(f"{1 / x:.0f}" for x in (0.1, 0.01, 0.001)) + " per m at x = 0.1, 0.01, 0.001")
print("Tietze from (0,1], zigzag at 1, 1/2, ..., 1/6: " + " ".join(str((-1) ** (k + 1)) for k in range(1, 7)))
ring = [(cos(2 * pi * k / 24), sin(2 * pi * k / 24)) for k in range(25)]
wind = sum(atan2(x1 * y2 - y1 * x2, x1 * x2 + y1 * y2) for (x1, y1), (x2, y2) in zip(ring, ring[1:])) / (2 * pi)
print(f"circle-valued: the identity loop winds {wind:.6f} times; a loop that shrinks in the disc winds 0")
assert abs(wind - 1) < 1e-9
print("Tietze split: " + "; ".join(f"at {c} shrinks by {max(1 - c, 2 * c)}" for c in (Fr(1, 4), Fr(1, 3), Fr(1, 2))))
print("doubled origin: 1/k near both origins forces D(0, 0') <= 2/k: " + ", ".join(f"{2 / k}" for k in (10, 100, 1000)))
print("ALL CHECKS PASS")
