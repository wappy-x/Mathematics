# Hausdorff measure and dimension -- the check behind the card.  Standard library
# only.  The Cantor set C on the road [0, 1] km.  Stage k keeps 2^k pieces of
# length 3^-k; their ends are whole numbers over D = 3^10, so they are exact.
import math

K = 10
D = 3 ** K
S0 = math.log(2) / math.log(3)

def stage(k):                                   # road one: cut the middle third of every piece, k times
    pieces = [(0, D)]
    for _ in range(k):
        pieces = [p for lo, hi in pieces for p in ((lo, lo + (hi - lo) // 3), (hi - (hi - lo) // 3, hi))]
    return pieces

def solve_dim(copies, ratio):                   # road two: bisection for copies * ratio^s = 1
    lo, hi = 0.0, 10.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if copies * ratio ** mid > 1 else (lo, mid)
    return lo

def cheapest(pieces, s, cap, scale=1.0):        # cheapest cover: each set spans a run of whole pieces,
    best = [0.0] + [math.inf] * len(pieces)     # no wider than cap (in units of 1/D)
    for j in range(1, len(pieces) + 1):
        for i in range(j, 0, -1):
            span = pieces[j - 1][1] - pieces[i - 1][0]
            if span > cap:
                break
            best[j] = min(best[j], best[i - 1] + (span / D * scale) ** s)
    return best[-1]

def F(p, q, digits=50):                         # Cantor function at p/q: base-3 digits read in base 2
    if p >= q:
        return 1.0
    total, half = 0.0, 0.5
    for _ in range(digits):
        d, p = divmod(3 * p, q)
        if d == 1:                              # inside a removed gap: flat from here
            return total + half
        total, half = total + half * (d // 2), half / 2
    return total

kd = math.log(4) / math.log(3)
print(f"Cantor: log 2 / log 3 = {S0:.6f}; bisection of 2 x (1/3)^s = 1 gives {solve_dim(2, 1 / 3):.6f}; 3^s = {3 ** S0:.6f}")
print(f"Koch: log 4 / log 3 = {kd:.6f}; bisection of 4 x (1/3)^s = 1 gives {solve_dim(4, 1 / 3):.6f}")
print("stage k         pieces  sum s=0.5  sum s=0.6309  sum s=0.75")
for k in (0, 1, 2, 5, 10, 20, 40):
    sums = [2 ** k * 3.0 ** (-k * s) for s in (0.5, S0, 0.75)]
    print(f"{k:>7}  {2 ** k:>13}  {sums[0]:>9.4f}  {sums[1]:>12.4f}  {sums[2]:>10.4f}")
p10 = stage(K)
built = sum(((hi - lo) / D) ** S0 for lo, hi in p10)
print(f"stage 10 built by cutting: {len(p10)} pieces; sum of (length)^0.6309 over the list = {built:.6f}")
for s, name in ((0.5, "0.5"), (S0, "0.6309"), (0.75, "0.75")):
    print(f"chart s={name}: " + ", ".join(f"{2 ** k * 3.0 ** (-k * s):.2f}" for k in range(13)))
print("cheapest cover of the stage-10 pieces, sets no wider than 3^-j km")
print("    j  width (m)  s=0.5   s=0.6309  s=0.75")
dp = {}
for j in range(9):
    dp[j] = [cheapest(p10, s, 3 ** (K - j)) for s in (0.5, S0, 0.75)]
    print(f"{j:>5}  {1000 / 3 ** j:>9.2f}  {dp[j][0]:.4f}  {dp[j][1]:.4f}    {dp[j][2]:.4f}")
h1 = cheapest(p10, 1.0, D)
print(f"s=1, any width: cheapest cover {h1:.4f}; length of stage 10 = (2/3)^10 = {(2 / 3) ** 10:.4f}")
lp, rp = [p for p in p10 if p[1] <= D // 3], [p for p in p10 if p[0] >= 2 * D // 3]
left, hl, hr = cheapest(lp, S0, D), cheapest(lp, 0.5, D), cheapest(rp, 0.5, D)
print(f"left third of C (scale r = 1/3): cheapest {left:.4f}; r^s = {3 ** -S0:.4f}; r alone would say {1 / 3:.4f}")
print(f"s=0.5, no cap: whole {dp[0][0]:.4f}; halves {hl:.4f} + {hr:.4f} = {hl + hr:.4f}, more than the whole")
metres = cheapest(p10, S0, D, 1000.0)
print(f"same set measured in metres: cheapest {metres:.2f}; 1000^0.6309 = {1000 ** S0:.2f}")
m = 6
q = 3 ** m
vals = [F(i, q) for i in range(q + 1)]
ratios = [(vals[b] - vals[a]) / ((b - a) / q) ** S0 for a in range(q) for b in range(a + 1, q + 1)]
top = max(ratios)
beat = sum(r > 1 + 1e-9 for r in ratios)
print(f"mass test: {len(ratios)} intervals with ends on multiples of 1/729; largest mu(U)/|U|^0.6309 = {top:.4f}; "
      f"above 1: {beat}")
print(f"proved bound mu(U) <= 2 |U|^0.6309 gives H^0.6309(C) >= 1/2 = {1 / 2:.4f}; stage covers give <= {built:.4f}")
fa, fb = F(1, 5), F(3, 10)
w = 0.1 ** S0
print(f"U = [200 m, 300 m]: F = {fa:.4f} and {fb:.4f}, mu(U) = {fb - fa:.4f}; |U|^0.6309 = {w:.4f}; 2|U|^0.6309 = {2 * w:.4f}")
hit = [(lo, hi) for lo, hi in stage(2) if lo < 0.3 * D and hi > 0.2 * D]
print(f"U meets {len(hit)} stage-2 piece: {1000 * hit[0][0] / D:.2f} to {1000 * hit[0][1] / D:.2f} m")
print(f"stage-5 piece: length {1000 / 3 ** 5:.2f} m, weight (length in km)^0.6309 = {(1 / 3 ** 5) ** S0:.5f}")
print(f"mistake, weigh by length (s=1): stage 10 sum {(2 / 3) ** 10:.4f}, stage 20 sum {(2 / 3) ** 20:.6f}")
print(f"mistake, weigh by count (s=0): stage 10 sum {2 ** 10}, stage 20 sum {2 ** 20}")
boxes = [len({math.floor(N * a / b) for b in range(1, N + 1) for a in range(b)}) for N in (3, 9, 27, 81)]
print(f"mistake, box counting on the fractions in [0, 1): boxes touched at widths 1/3, 1/9, 1/27, 1/81: "
      f"{', '.join(map(str, boxes))}; slope {math.log(boxes[-1] / boxes[0]) / math.log(27):.4f}")
eps = 0.01
weight = sum((eps / 2 ** n) for n in range(1, 61))
print(f"fractions listed, n-th given width (0.01/2^n)^(1/s): total weight at any s > 0 is {weight:.4f}")
print(f"constant in H^2 = c x area on the plane (cited): 4/pi = {4 / math.pi:.4f}")
print("figure, x = 18 + 324 t for t in km; stage k drawn at y = 22 + 42 k, bars 12 high")
for k in range(4):
    print(f"figure, stage {k}: width {324 / 3 ** k:.2f} at x " + ", ".join(f"{18 + 324 * lo / D:.2f}" for lo, hi in stage(k)))
print(f"figure, U from x = {18 + 324 * 0.2:.2f} to {18 + 324 * 0.3:.2f}")
assert abs(solve_dim(2, 1 / 3) - S0) < 1e-9 and abs(solve_dim(4, 1 / 3) - kd) < 1e-9   # bisection vs logs
assert abs(built - 1) < 1e-9 and len(p10) == 2 ** K                                   # built list vs 2^k 3^-ks
for j in range(9):                                                                     # search vs stage-j covers
    assert abs(dp[j][1] - 1) < 1e-9 and abs(dp[j][0] - (2 / math.sqrt(3)) ** j) < 1e-9
    assert abs(dp[j][2] - (2 * 3 ** -0.75) ** K) < 1e-9
assert abs(h1 - (2 / 3) ** 10) < 1e-12 and abs(left - 0.5) < 1e-9 and abs(metres - 1000 ** S0) < 1e-6
assert abs(hl - 3 ** -0.5) < 1e-9 and abs(hr - hl) < 1e-9 and hl + hr > dp[0][0] + 0.1   # halves need not add
assert 1 - 1e-12 < top <= 2 and beat == 0                                              # mass test
assert abs(fa - 0.25) < 1e-12 and abs(fb - 0.4) < 1e-12 and boxes == [3, 9, 27, 81] and len(hit) == 1
print("ALL CHECKS PASS")
