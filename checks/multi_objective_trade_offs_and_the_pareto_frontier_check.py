# Two goals at once: Pareto optimality and the frontier of trade-offs -- the check behind the card.
# Standard library only. Five funds, treated as uncorrelated, no short sales.
# Risk is the variance in percent squared; return is in percent a year.
from itertools import product
NAME = ["gilt", "corp bond", "property", "UK equity", "emerging"]
MU = [3.0, 4.0, 5.0, 6.5, 9.0]
VAR = [s * s for s in [5.0, 8.0, 14.0, 16.0, 25.0]]
N = 5

def stats(x):
    return sum(v * a * a for v, a in zip(VAR, x)), sum(m * a for m, a in zip(MU, x))

def weighted(tau, longonly=True):
    # Road 1: minimise variance - tau * return over every set of funds held (31 sets);
    # keep the one whose KKT conditions hold: weights >= 0 and no fund left out wants in.
    for mask in range(1, 2 ** N):
        on = [i for i in range(N) if mask >> i & 1]
        if not longonly and len(on) < N:
            continue
        nu = (sum(tau * MU[i] / (2 * VAR[i]) for i in on) - 1) / sum(1 / (2 * VAR[i]) for i in on)
        x = [(tau * MU[i] - nu) / (2 * VAR[i]) if i in on else 0.0 for i in range(N)]
        lam = [0.0 if i in on else nu - tau * MU[i] for i in range(N)]  # multipliers on x_i >= 0
        if not longonly or (min(x) >= -1e-12 and min(lam) >= -1e-12):
            return x, nu, lam

def pct(x):
    return " ".join(f"{100 * a:6.2f}" for a in x)

# ---- eleven frontier portfolios, tau = 0, 10, ..., 100 ----
TAUS = [10 * k for k in range(11)]
front = []
print("tau  weights % (gilt corp prop UKeq emer)   return  var     sd")
for t in TAUS:
    x, nu, lam = weighted(t)
    v, r = stats(x)
    front.append((t, x, v, r, nu, lam))
    print(f"{t:3d} {pct(x)}  {r:6.3f} {v:7.2f} {v ** 0.5:6.3f}")
    sc = lambda i, s: (lambda z: stats(z)[0] - t * stats(z)[1])([a + s if j == i else a for j, a in enumerate(x)])
    resid = max(abs((sc(i, 1e-4) - sc(i, -1e-4)) / 2e-4 + nu - lam[i]) for i in range(N))  # score's slope, measured
    assert resid < 1e-6 and min(lam) >= -1e-12  # KKT certificate: slopes balance, no fund left out wants in
t, x, v, r, nu, lam = front[5]
top, bot = sum(50 * MU[i] / (2 * VAR[i]) for i in range(1, N)), sum(1 / (2 * VAR[i]) for i in range(1, N))
print(f"tau 50 by hand: sums {top:.4f} and {bot:.6f}, nu {nu:.2f}, gilt multiplier {lam[0]:.2f}, objective {v - 50 * r:.3f}")

# ---- road 2: every portfolio on a 2% grid (316,251 of them) ----
grid = []
for c in product(range(51), repeat=4):
    if sum(c) <= 50:
        grid.append(stats([a / 50 for a in c] + [(50 - sum(c)) / 50]))
worst_gap, dominators = 0.0, 0
for t, x, v, r, nu, lam in front:
    best = min(gv - t * gr for gv, gr in grid)
    assert best >= v - t * r - 1e-9          # no grid portfolio beats the exact answer
    worst_gap = max(worst_gap, best - (v - t * r))
    dominators += sum(1 for gv, gr in grid if gv <= v and gr >= r and (gv < v or gr > r))
print(f"grid portfolios {len(grid)}, worst grid shortfall {worst_gap:.4f}, grid portfolios dominating a frontier one {dominators}")
assert len(grid) == 316251 and dominators == 0 and worst_gap < 0.5
top_tau = 2 * VAR[4] / (MU[4] - MU[3])   # from here on, all in emerging markets
print(f"sets of funds tried per solve {2 ** N - 1}; all emerging from tau {top_tau:.1f}; tau values in the one-fund sweep 10001")
assert abs(weighted(top_tau)[0][4] - 1) < 1e-12 and weighted(top_tau - 1)[0][4] < 0.999

# ---- the weight is the slope: target 6% return by bisection on tau ----
def for_return(m):  # bisection on tau until the weighted answer returns m
    lo, hi = 0.0, 500.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if stats(weighted(mid)[0])[1] < m else (lo, mid)
    return lo
t6 = for_return(6.0)
v6, r6 = stats(weighted(t6)[0])
h = 1e-3
slope = (stats(weighted(for_return(6 + h))[0])[0] - stats(weighted(for_return(6 - h))[0])[0]) / (2 * h)
g6 = min(gv for gv, gr in grid if gr >= 6.0)
print(f"6% target: tau {t6:.3f}, variance {v6:.3f}, sd {v6 ** 0.5:.3f}; frontier slope {slope:.3f}; best 2% grid variance {g6:.3f}")
assert abs(slope - t6) < 1e-3 and v6 <= g6 + 1e-9

# ---- the one-fund rule: a dented frontier ----
score = lambda i, t: VAR[i] - t * MU[i]
winners, gap, at = [], 1e9, 0.0
for k in range(10001):                    # tau from 0 to 1000 in steps of 0.1
    t = k / 10
    w = min(range(N), key=lambda i: score(i, t))
    if not winners or winners[-1][0] != w:
        winners.append((w, t))
    d = score(2, t) - min(score(i, t) for i in range(N) if i != 2)
    if d < gap:
        gap, at = d, t
print("one fund, weighted-sum winners as tau rises:", ", ".join(NAME[w] for w, _ in winners))
cuts = [(VAR[b] - VAR[a]) / (MU[b] - MU[a]) for a, b in [(0, 1), (1, 3), (3, 4)]]
th = (MU[3] - MU[2]) / (MU[3] - MU[1])   # average of two funds' points, returning 5%
mixv = th * VAR[1] + (1 - th) * VAR[3]
print(f"switch points {cuts[0]:.1f} {cuts[1]:.1f} {cuts[2]:.1f}; property never wins; closest at tau {at:.1f}, loses by {gap:.2f}")
print(f"{100 * th:.0f}/{100 * (1 - th):.0f} average of corp bond and UK equity points: return {MU[2]:.2f}, variance {mixv:.2f} vs property {VAR[2]:.2f}")
assert [w for w, _ in winners] == [0, 1, 3, 4] and abs(gap - (VAR[2] - mixv)) < 1e-9
assert all(abs(t - c) <= 0.1 + 1e-9 for (_, t), c in zip(winners[1:], cuts))
pareto = [i for i in range(N) if not any(VAR[j] <= VAR[i] and MU[j] >= MU[i] and j != i for j in range(N))]
eps = [min((VAR[i], i) for i in range(N) if MU[i] >= e)[1] for e in MU]
print("Pareto-optimal funds:", ", ".join(NAME[i] for i in pareto), "| epsilon-constraint picks:", ", ".join(NAME[i] for i in eps))
assert pareto == eps == [0, 1, 2, 3, 4]

# ---- what breaks ----
x = weighted(-10)[0]
vb, rb = stats(x)
print(f"tau -10: return {rb:.3f}, var {vb:.2f}; tau 0 has return {front[0][3]:.3f}, var {front[0][2]:.2f}")
assert rb < front[0][3] and vb > front[0][2]
x = weighted(100, longonly=False)[0]
print(f"shorts allowed, tau 100: {pct(x)}, return {stats(x)[1]:.3f}, var {stats(x)[0]:.2f}")
assert x[0] < 0
print("figure, funds " + " ".join(f"({VAR[i]:.0f},{MU[i]:.1f})" for i in range(N)) + f", average ({mixv:.1f},{MU[2]:.1f})")
print("ALL CHECKS PASS")
