# Percolation on the square grid: the check behind the card. Standard library only.
# Roads: (1) exact enumeration of every open/closed pattern on a small box,
# (2) the duality count a_k + a_(E-k) = C(E, k), (3) simulation with a written-out
# generator (SplitMix64, seed 2026), held against the exact numbers.
from math import comb, sqrt

M = (1 << 64) - 1


class SplitMix64:
    def __init__(self, seed):
        self.s = seed & M

    def unit(self):  # a uniform number in [0, 1), exact in both languages
        self.s = (self.s + 0x9E3779B97F4A7C15) & M
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0


def box(w, h, sides):
    """Channels of a w-by-h box of pores; first- and last-column verticals (no help to a crossing) only if sides."""
    e = [(y * w + x, y * w + x + 1) for y in range(h) for x in range(w - 1)]
    xs = range(w) if sides else range(1, w - 1)
    return e + [(y * w + x, (y + 1) * w + x) for y in range(h - 1) for x in xs]


def find(par, a):
    while par[a] != a:
        par[a] = par[par[a]]
        a = par[a]
    return a


def crosses(w, h, par):
    left = {find(par, y * w) for y in range(h)}
    return any(find(par, y * w + w - 1) in left for y in range(h))


def reaches(w, h, par):  # is the centre pore of a w-by-w square joined to its rim?
    c = find(par, w * w // 2)
    return any(find(par, i) == c for i in range(w * w) if i % w in (0, w - 1) or i // w in (0, w - 1))


def exact_counts(w, h, sides=False, ok=crosses):
    """a[k] = how many patterns with k open channels pass ok (default: water crosses left to right)."""
    e = box(w, h, sides)
    a = [0] * (len(e) + 1)
    for mask in range(1 << len(e)):
        par = list(range(w * h))
        for i, (u, v) in enumerate(e):
            if mask >> i & 1:
                par[find(par, u)] = find(par, v)
        if ok(w, h, par):
            a[bin(mask).count("1")] += 1
    return a


def exact_f(a, num, den):  # crossing chance at p = num/den, as (top, bottom) integers
    n = len(a) - 1
    return sum(a[k] * num**k * (den - num) ** (n - k) for k in range(n + 1)), den**n


def dec(top, bot):  # top/bot rounded to 4 decimals, in integers
    q = (2 * top * 10**4 + bot) // (2 * bot)
    return f"{q // 10**4}.{q % 10**4:04d}"


def sim_cross(w, h, p, trials, rng):
    e, hits = box(w, h, False), 0
    for _ in range(trials):
        par = list(range(w * h))
        for u, v in e:
            if rng.unit() < p:
                par[find(par, u)] = find(par, v)
        hits += crosses(w, h, par)
    return hits


def sim_reach(r, p, trials, rng):  # centre joined to the rim of a (2r+1)-square?
    w, hits = 2 * r + 1, 0
    e = box(w, w, True)
    for _ in range(trials):
        par = list(range(w * w))
        for u, v in e:
            if rng.unit() < p:
                par[find(par, u)] = find(par, v)
        hits += reaches(w, w, par)
    return hits


rng, T = SplitMix64(2026), 400
a = exact_counts(4, 3)
E = len(a) - 1
print(f"Exact: the 4-by-3 box, {E} channels, {1 << E} patterns; a_k = {a}")
assert all(a[k] + a[E - k] == comb(E, k) for k in range(E + 1))  # duality, every k
print(f"duality a_k + a_(13-k) = C(13,k): checked for k = 0..{E}")
nh = sum(1 for u, v in box(4, 3, False) if v == u + 1)
print(f"by hand: {nh} across + {E - nh} up-down; a_3 + a_10 = {a[3] + a[10]} = C(13,3); a_6 + a_7 = {a[6] + a[7]} = C(13,6)")
half, f40, f60 = exact_f(a, 50, 100), exact_f(a, 40, 100), exact_f(a, 60, 100)
assert half[0] * 2 == half[1]  # f(1/2) = 1/2 exactly, as duality predicts
assert f40[0] + f60[0] == f40[1]  # f(p) + f(1-p) = 1
print(f"crossing patterns: {sum(a)} of {1 << E}, so f(0.50) = {dec(*half)} exactly")
print(f"f(0.40) = {dec(*f40)}, f(0.60) = {dec(*f60)}, sum 1 exactly")
sq = exact_counts(3, 3)
sqh = exact_f(sq, 50, 100)
assert 2 * sqh[0] != sqh[1]  # the wrong shape is not fair
print(f"wrong shape, 3-by-3 box ({len(sq) - 1} channels): f(0.50) = {sum(sq)}/{1 << (len(sq) - 1)} = {dec(*sqh)}")
hit = sim_cross(4, 3, 0.6, T, rng)
print(f"simulated 4-by-3 box at p = 0.60: {hit}/{T} = {hit / T:.4f} against exact {dec(*f60)}")
assert abs(hit / T - f60[0] / f60[1]) < 4 * sqrt(0.6 * 0.4 / T)
print("Crossing chance: p, exact 4x3, simulated 9x8, simulated 33x32 (400 runs each)")
curve = {}
for k in range(30, 71, 5):
    curve[k] = sim_cross(9, 8, k / 100, T, rng), sim_cross(33, 32, k / 100, T, rng)
    print(f"p=0.{k}  {dec(*exact_f(a, k, 100))}  {curve[k][0] / T:.4f}  {curve[k][1] / T:.4f}")
assert abs(curve[50][1] / T - 0.5) < 4 * sqrt(0.25 / T)  # fair at p = 1/2 at every size
assert curve[40][1] < curve[40][0] and curve[60][1] > curve[60][0]  # the switch sharpens
print("Reach: chance the centre joins the rim at distance r (400 runs each)")
reach = {}
for p in (0.5, 0.6):
    reach[p] = [sim_reach(r, p, T, rng) / T for r in (2, 4, 8, 16, 32)]
    print(f"p={p:.2f}  r=2,4,8,16,32: " + "  ".join(f"{x:.4f}" for x in reach[p]))
assert reach[0.5][0] - reach[0.5][4] > 6 * sqrt(0.5 / T)  # dying out at p = 1/2
assert reach[0.6][4] > reach[0.5][4] + 6 * sqrt(0.5 / T)  # but not at p = 0.60
r1 = exact_counts(3, 3, True, reaches)  # second road for reach: all 4096 patterns at r = 1
assert sum(r1) == 4096 - 256 and exact_f(r1, 60, 100)[0] == (100**4 - 40**4) * 100**8  # 1 - (1-p)^4
print(f"reach at r = 1, exact over all 4096 patterns: {dec(*exact_f(r1, 50, 100))} at p = 0.50, {dec(*exact_f(r1, 60, 100))} at p = 0.60, both 1 - (1-p)^4")
mean, tree = sim_cross(33, 32, 0.25, T, rng), sim_cross(33, 32, 1 / 3, T, rng)
print(f"mean-degree rule p=0.25: 33x32 crossing {mean}/{T}; tree rule p=0.3333: {tree}/{T}")
assert mean == 0 and tree < 4
fig, par, opened = SplitMix64(2), list(range(72)), 0  # the drawn 9-by-8 sample, p = 0.50
for u, v in box(9, 8, False):
    if fig.unit() < 0.5:
        par[find(par, u)], opened = find(par, v), opened + 1
left = {find(par, 9 * y) for y in range(8)}
wet = sum(find(par, i) in left for i in range(72))
print(f"figure, seed 2: {opened} of 113 channels open, {wet} of 72 pores wet, crosses: {'yes' if crosses(9, 8, par) else 'no'}")
print("ALL CHECKS PASS")
