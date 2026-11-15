# The distance menu -- the check behind the card.  Standard library only.
# Van grid in km: depot (0, 0), drops A (3, 4) and B (8, 1).  Every number on
# the card is printed here.  Squared distances stay whole numbers, tent
# integrals are checked against exact fractions, graph distances come from a
# breadth-first search written out below.
from fractions import Fraction
from math import sqrt, hypot

def d1(p, q): return sum(abs(a - b) for a, b in zip(p, q))          # grid
def d2sq(p, q): return sum((a - b) ** 2 for a, b in zip(p, q))     # crow, squared
def dinf(p, q): return max(abs(a - b) for a, b in zip(p, q))       # worst case

# ---- the van: three distances for one trip ----
A, B = (3, 4), (8, 1)
g, c2, w = d1(A, B), d2sq(A, B), dinf(A, B)
print(f"van A {A} to B {B}: moves 5 east, 3 south")
print(f"  grid d1 = {g} km, crow d2 = sqrt({c2}) = {sqrt(c2):.10f} km, worst-case dinf = {w} km")
assert g == 5 + 3 and c2 == 5 * 5 + 3 * 3 and w == max(5, 3)
assert abs(sqrt(c2) - hypot(5, 3)) < 1e-12           # second road for the root
print(f"  chain: {w} <= {sqrt(c2):.4f} <= {g} <= 2 x {w} = {2 * w}")

# ---- the chain dinf <= d2 <= d1 <= n*dinf, every move in a 41 x 41 box ----
cases = eq_d1 = eq_d2 = 0
for u in range(-20, 21):
    for v in range(-20, 21):
        p = (u, v)
        a, b2, c = dinf(p, (0, 0)), d2sq(p, (0, 0)), d1(p, (0, 0))
        assert a * a <= b2 <= c * c and c <= 2 * a
        cases += 1
        eq_d1 += (c == 2 * a)
        eq_d2 += (b2 == a * a)
print(f"chain checked on {cases} moves; d1 = 2 dinf on {eq_d1} (diagonals), d2 = dinf on {eq_d2} (along a street)")

# ---- nested open balls round A, radius 5 km, on a quarter-km lattice ----
pts = [(12 + i, 16 + j) for i in range(-48, 49) for j in range(-48, 49)]   # A = (12, 16) in quarter-km
A4 = (12, 16)
in1 = {p for p in pts if d1(p, A4) < 20}
in2 = {p for p in pts if d2sq(p, A4) < 400}
inf_ = {p for p in pts if dinf(p, A4) < 20}
assert in1 <= in2 <= inf_ <= {p for p in pts if d1(p, A4) < 40}
assert {p for p in pts if dinf(p, A4) < 10} <= in1                   # radius r/n inside
print(f"balls round A, radius 5 km, {len(pts)} lattice points: diamond {len(in1)}, disc {len(in2)}, square {len(inf_)}")
ex = (2 * 25, 3.14159265358979 * 25, 4 * 25)                        # 2r^2, pi r^2, 4r^2
print(f"  areas from the counts: {len(in1) / 16:.2f}, {len(in2) / 16:.2f}, {len(inf_) / 16:.2f} km^2 (exact {ex[0]}, {ex[1]:.2f}, {ex[2]})")
assert all(abs(len(b) / 16 - e) < 6 for b, e in zip((in1, in2, inf_), ex))

# ---- an open set: the crow's disc round A; a square fits round P ----
P = (6, 2)
dp = sqrt(d2sq(P, A)); room = 5 - dp; s = room / 2
far = max(sqrt((P[0] + x * s - A[0]) ** 2 + (P[1] + y * s - A[1]) ** 2) for x in (-1, 1) for y in (-1, 1))
print(f"P {P}: crow distance from A {dp:.10f}, room {room:.10f}, square half-width {s:.10f}, farthest corner {far:.10f}")
assert far < 5

# ---- worst detour: tent of height 1 km and width w against the planned road ----
N = 200000
print("tent detours, height 1 km (x = fraction of the leg):")
for m in (1, 10, 100, 1000):
    wd = 1 / m
    tent = lambda x: max(0.0, 1 - abs(x - 0.5) / (wd / 2))
    sup = max(tent(k / N) for k in range(N + 1))
    integ = sum(tent((k + 0.5) / N) for k in range(N)) / N
    exact = Fraction(1, 2 * m)
    assert sup == 1.0 and abs(integ - float(exact)) < 1e-6 and integ <= sup
    assert round(sup / integ) == 2 * m                               # ratio 2/w: no ceiling
    print(f"  width 1/{m}: worst detour {sup:.6f} km, average offset {integ:.6f} km (exact 1/{2 * m}), ratio {round(sup / float(exact))}")
m = 10000; wd = 1 / m; t = Fraction(1, 2 * m)
print(f"  try: width 1/{m}: average offset exact 1/{t.denominator} = {float(t):.6f} km, worst detour still {max(0.0, 1 - abs(0.5 - 0.5) / (wd / 2)):.0f} km")

# ---- Hausdorff distance between the drops and the lockers ----
D, L = [A, B], [(2, 2), (8, 2), (5, 7)]
def one_sided(S, T, d): return max(min(d(s, t) for t in T) for s in S)
def hausdorff(S, T, d): return max(one_sided(S, T, d), one_sided(T, S, d))
dl, ld = one_sided(D, L, d1), one_sided(L, D, d1)
r = 0                                                  # second road: grow r until each set is within r of the other
while not (all(any(d1(s, t) <= r for t in L) for s in D) and all(any(d1(t, s) <= r for s in D) for t in L)):
    r += 1
print(f"Hausdorff, grid: drops to lockers {dl}, lockers to drops {ld}, d_H = {hausdorff(D, L, d1)} km; smallest r covering both ways {r}")
assert (dl, ld) == (3, 5) and r == hausdorff(D, L, d1) == 5
hc = hausdorff(D, L, d2sq)
print(f"Hausdorff, crow: d_H = sqrt({hc}) = {sqrt(hc):.10f} km")
assert hc == 2 * 2 + 3 * 3
print(f"  try: without locker (5, 7): d_H = {hausdorff(D, L[:2], d1)} km")
close = min(d1(s, t) for s in D for t in L)
print(f"closest pair drops-lockers {close} km; closest pair D vs D+(5,7) {min(d1(s, t) for s in D for t in D + [(5, 7)])}, d_H {hausdorff(D, D + [(5, 7)], d1)}")

# ---- shortest-path metric on the street grid, 9 x 5 corners ----
nodes = [(x, y) for x in range(9) for y in range(5)]
def bfs(src, closed):
    dist, frontier = {src: 0}, [src]
    while frontier:
        nxt = []
        for (x, y) in frontier:
            for (a, b) in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if not (0 <= a <= 8 and 0 <= b <= 4) or (a, b) in dist: continue
                if closed and {x, a} == {5, 6} and y >= 1: continue      # rail line, one crossing at y = 0
                dist[(a, b)] = dist[(x, y)] + 1; nxt.append((a, b))
        frontier = nxt
    return dist
for closed in (False, True):
    D_ = {u: bfs(u, closed) for u in nodes}
    assert all(D_[u][v] == D_[v][u] and (D_[u][v] == 0) == (u == v) and D_[u][v] >= d1(u, v) for u in nodes for v in nodes)
    tri = sum(1 for u in nodes for v in nodes for z in nodes if D_[u][z] <= D_[u][v] + D_[v][z])
    assert tri == 45 ** 3
    more = sum(1 for u in nodes for v in nodes if D_[u][v] > d1(u, v))
    print(f"streets {'with rail line' if closed else 'open'}: A to B {D_[A][B]} blocks; triangle checked on all {tri} triples; pairs longer than d1: {more} of {len(nodes) ** 2} ordered; worst excess {max(D_[u][v] - d1(u, v) for u in nodes for v in nodes)}")
assert D_[A][B] == 10 and D_[(5, 4)][(6, 4)] == 4 + 1 + 4
print(f"  across the rail line: (5, 4) to (6, 4) is {D_[(5, 4)][(6, 4)]} blocks by street, {d1((5, 4), (6, 4))} on the grid formula")

# ---- what breaks ----
M2 = (11, 5)                                                         # midpoint (5.5, 2.5), doubled
sq_am = d2sq((6, 8), M2) / 4; sq_mb = d2sq(M2, (16, 2)) / 4
print(f"squared crow: A to B {c2} > A to M {sq_am:.1f} + M to B {sq_mb:.1f} = {sq_am + sq_mb:.1f}")
assert c2 > sq_am + sq_mb
print("try: B at (8, 4): d1 = %d, d2 = %.1f, dinf = %d" % (d1(A, (8, 4)), sqrt(d2sq(A, (8, 4))), dinf(A, (8, 4))))
R = 5
print(f"figure, A {A}, B {B}, radius {R}: diamond {(A[0] + R, A[1])} {(A[0], A[1] + R)} {(A[0] - R, A[1])} {(A[0], A[1] - R)}; disc r {R}; square {(A[0] - R, A[1] - R)} to {(A[0] + R, A[1] + R)}")
print("ALL CHECKS PASS")
