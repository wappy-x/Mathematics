# Continuity and subadditivity -- the check behind the card.  Standard library
# only; fractions keeps every area exact.  Lengths in km, areas in km^2.
# Road 1: add disjoint layers, as the proof does.  Road 2: count grid cells
# 1/32 km on a side whose centres lie in the set; it never sees a layer.
# Road 3, for the flood and the reservoir: the closed-form geometric sums.
# The code checks finite stages exactly; only the proof covers every stage.
from fractions import Fraction as Q

def show(x):                                   # 5 not 5.0; exact dyadics as decimals
    return str(x.numerator) if x.denominator == 1 else repr(float(x))

def cells(inside):                             # road 2: grid 2 km across, 5 km along
    hits = sum(1 for i in range(64) for j in range(160) if inside(2 * i + 1, 2 * j + 1))
    return Q(hits, 1024)                       # each cell is (1/32 km)^2

def strip(x0, x1, y0, y1):                     # closed rectangle; centres in 1/64-km units
    return lambda cx, cy: 64 * x0 <= cx <= 64 * x1 and 64 * y0 <= cy <= 64 * y1

edge = lambda n: 2 - Q(2, 2 ** n)              # flood edge after stage n, km from the bank
wet = lambda n: 1 + Q(2, 2 ** n)               # reservoir wet width on day n, km

print("flood, stage n: edge km | area by layers | 10 - 10/2^n | by cells | short of 10")
flood = []
for n in range(1, 11):
    by_layers = sum(5 * (edge(j) - edge(j - 1)) for j in range(1, n + 1))
    closed = 10 - Q(10, 2 ** n)
    grid = cells(strip(0, edge(n), 0, 5)) if n <= 6 else None
    assert by_layers == closed                 # layers against the geometric sum
    assert grid is None or grid == by_layers   # layers against counted cells
    flood.append(by_layers)
    g = "-" if grid is None else show(grid)
    print(f"flood, stage {n}: {show(edge(n))} | {show(by_layers)} | {show(closed)} | {g} | {show(10 - by_layers)}")
union = cells(lambda cx, cy: any(strip(0, edge(n), 0, 5)(cx, cy) for n in range(1, 21)))
assert union == 10                             # cells under some stage 1 to 20: the union
assert 10 - flood[-1] < Q(1, 100)              # stage 10 is within 0.01 of the union
print(f"flood, union of stages 1 to 20 (the strip short of 2 km), by cells: {show(union)}")

band = cells(lambda cx, cy: strip(0, edge(3), 0, 5)(cx, cy) and not strip(0, edge(2), 0, 5)(cx, cy))
assert band == flood[2] - flood[1]             # monotonicity: mu(B) = mu(A) + mu(B minus A)
print(f"monotone: stage 2 inside stage 3, {show(flood[1])} <= {show(flood[2])}; band between, by cells: {show(band)}")

print("survey, flight k: km along | patch area | new piece | union by pieces | union by cells | sum of areas")
s, L, covered, by_pieces, total, rects = Q(0), Q(2), Q(0), Q(0), Q(0), []
for k in range(1, 21):
    rects.append(strip(0, 2, s, s + L))
    new = 2 * max(Q(0), s + L - max(s, covered))   # B_k: patch k minus all earlier patches
    covered, by_pieces, total = max(covered, s + L), by_pieces + new, total + 2 * L
    assert by_pieces == 6 - Q(4, 2 ** k) and total == 8 - Q(8, 2 ** k)
    if k <= 6:
        grid = cells(lambda cx, cy: any(r(cx, cy) for r in rects))
        assert grid == by_pieces               # new pieces against counted cells
        print(f"survey, flight {k}: {show(s)} to {show(s + L)} | {show(2 * L)} | {show(new)} | "
              f"{show(by_pieces)} | {show(grid)} | {show(total)}")
    s, L = s + 3 * L / 4, L / 2
print(f"survey, after 20 flights: union {show(by_pieces)}; sum {show(total)}; overlap {show(total - by_pieces)}")
print("survey, closed forms held for k = 1 to 20: union 6 - 4/2^k, limit 6; sum 8 - 8/2^k, limit 8; overlap 2")

print("reservoir, day n: wet width km | 6 - dried layers | 3 + 6/2^n | by cells | above 3")
res = []
for n in range(1, 11):
    dried = sum(3 * (wet(j - 1) - wet(j)) for j in range(2, n + 1))   # F_1 minus F_n, layer by layer
    closed = 3 + Q(6, 2 ** n)
    grid = cells(strip(0, wet(n), 0, 3)) if n <= 6 else None
    assert 6 - dried == closed
    assert grid is None or grid == closed
    res.append(closed)
    g = "-" if grid is None else show(grid)
    print(f"reservoir, day {n}: {show(wet(n))} | {show(6 - dried)} | {show(closed)} | {g} | {show(closed - 3)}")
pool = cells(lambda cx, cy: all(strip(0, wet(n), 0, 3)(cx, cy) for n in range(1, 21)))
assert pool == 3
print(f"reservoir, wet on every day 1 to 20 (the pool that never dries), by cells: {show(pool)}")

for N in (1000, 100000):
    counts = [sum(1 for m in range(1, N + 1) if m >= n) for n in (1, 10, 100)]
    assert counts == [N - n + 1 for n in (1, 10, 100)]
    print(f"tails, counting measure of {{n, n+1, ...}} seen up to {N}: n=1: {counts[0]}, n=10: {counts[1]}, n=100: {counts[2]}")
    lengths = [sum(1 for m in range(n, N)) for n in (1, 10, 100)]   # [n, N] as unit pieces [m, m+1)
    assert lengths == [N - n for n in (1, 10, 100)]
    print(f"tails, length of [n, {N}] from unit pieces: n=1: {lengths[0]}, n=10: {lengths[1]}, n=100: {lengths[2]}")
survivors = [m for m in range(1, 1001) if all(m >= n for n in range(1, 1002))]
assert survivors == []
print(f"tails, numbers 1 to 1000 lying in every tail: {len(survivors)}")

near, far = strip(0, 1, 0, 5), strip(1, 2, 0, 5)   # bands 0 to 1 km and 1 to 2 km from the bank
halves = [cells(near), cells(far), cells(lambda cx, cy: near(cx, cy) or far(cx, cy)),
          cells(lambda cx, cy: near(cx, cy) and far(cx, cy))]
assert halves == [5, 5, 10, 0]
print(f"not nested, band 0 to 1 km then band 1 to 2 km from the bank: each {show(halves[0])} and {show(halves[1])}; "
      f"union {show(halves[2])}; common part {show(halves[3])}")

print("figure, flood edge y-pixels, stages 1-4:", " ".join(show(200 - 60 * edge(n)) for n in range(1, 5)),
      "| limit 80 | bank 200 | plain x 30 to 330")
print("chart, flooded area km^2:", " ".join(f"{float(a):.2f}" for a in flood[:8]))
print("chart, reservoir wet area km^2:", " ".join(f"{float(a):.2f}" for a in res[:8]))
print("ALL CHECKS PASS")
