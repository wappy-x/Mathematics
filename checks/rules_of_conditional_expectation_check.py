# The rules of conditional expectation -- the check behind the card.
# Standard library only; fractions for exact sums.  The space: 48 equally
# likely points = 12 months x (dry, wet) x gauge error (-3, +1) mm.
# Rainfall X is the month's mean times 3/5 in a dry year, 7/5 in a wet one.
from fractions import Fraction as Q

MEAN = [25, 30, 35, 50, 60, 70, 100, 90, 80, 50, 40, 30]   # month means, mm
U = [4, 3, 1, 2]                          # umbrellas sold per mm, by season
OMEGA = [(m, w, e) for m in range(12) for w in (0, 1) for e in (0, 1)]
PR = Q(1, 48)
X = lambda p: Q(MEAN[p[0]] * (7 if p[1] else 3), 5)
N = lambda p: (-3, 1)[p[2]]                         # gauge error, independent
MONTH, SEASON = (lambda p: p[0]), (lambda p: p[0] // 3)
BIMONTH, ALL = (lambda p: p[0] // 2), (lambda p: 0)

def cond(f, lab):                         # road 1: average f over each atom
    tot, mass = {}, {}
    for p in OMEGA:
        a = lab(p)
        tot[a], mass[a] = tot.get(a, 0) + f(p) * PR, mass.get(a, 0) + PR
    return {a: tot[a] / mass[a] for a in tot}

def defining_identity(cand, f, lab):      # road 2: the integral over every A in G
    atoms = sorted({lab(p) for p in OMEGA})
    for bits in range(1 << len(atoms)):
        A = [p for p in OMEGA if bits >> atoms.index(lab(p)) & 1]
        if sum(cand(p) * PR for p in A) != sum(f(p) * PR for p in A):
            return False
    return True

def show(d):
    return ", ".join(str(d[a]) for a in sorted(d))

def dec(v):
    return f"{float(v):.2f}"

NAMES = ["winter", "spring", "summer", "autumn"]
print(f"space: {len(OMEGA)} points, each {PR}; E[X] = {sum(X(p) * PR for p in OMEGA)} mm")
print("X dry/wet by month: " + ", ".join(f"{X((m, 0, 0))}/{X((m, 1, 0))}" for m in range(12)))
by_month, by_season = cond(X, MONTH), cond(X, SEASON)
print("E[X | month]: " + show(by_month))
print("E[X | season], direct: " + show(by_season))
tower = cond(lambda p: by_month[MONTH(p)], SEASON)
print("E[E[X | month] | season]: " + show(tower) + f"; its mean {cond(lambda p: tower[SEASON(p)], ALL)[0]}")
assert tower == by_season
assert defining_identity(lambda p: by_month[MONTH(p)], X, MONTH)          # 4096 events
assert defining_identity(lambda p: by_month[MONTH(p)], X, SEASON)         # tower, 16 events
print("defining identity: E[X | month] on all 4096 events of sigma(month); tower on all 16 of sigma(season)")

# ---- taking out what is known: umbrella sales U(season) times rainfall ----
sales = lambda p: U[SEASON(p)] * X(p)
pulled = {s: U[s] * by_season[s] for s in range(4)}
print("E[U X | season]: " + show(cond(sales, SEASON)) + "; U E[X | season]: " + show(pulled))
assert cond(sales, SEASON) == pulled
assert defining_identity(lambda p: pulled[SEASON(p)], sales, SEASON)
print(f"E[U X] = {float(cond(sales, ALL)[0]):.1f}; wrong E[U] E[X] = {float(Q(sum(U), 4) * 55):.1f}")

# ---- linearity and the independent gauge error: reading R = X + N ----
EN = sum(N(p) * PR for p in OMEGA)
print("E[N | month]: " + show(cond(N, MONTH)) + f"; E[N] = {EN}")
dropped = {s: by_season[s] + EN for s in range(4)}
assert cond(lambda p: X(p) + N(p), SEASON) == dropped
assert defining_identity(lambda p: EN, N, MONTH)
print("E[X + N | season]: " + show(dropped))

# ---- conditional Jensen: flood payout (X - 50)+, and the square ----
flood = lambda x: max(x - 50, 0)
pay = cond(lambda p: flood(X(p)), SEASON)
print("E[(X - 50)+ | season]: " + show(pay) + "; (E[X | season] - 50)+: " + show({s: flood(by_season[s]) for s in range(4)}))
assert all(pay[s] >= flood(by_season[s]) for s in range(4)) and pay[1] > flood(by_season[1])
sq = cond(lambda p: X(p) ** 2, SEASON)
cvar = cond(lambda p: (X(p) - by_season[SEASON(p)]) ** 2, SEASON)
print("E[X^2 | season] - E[X | season]^2: " + ", ".join(dec(sq[s] - by_season[s] ** 2) for s in range(4)))
assert all(sq[s] - by_season[s] ** 2 == cvar[s] for s in range(4))       # gap = spread

# ---- what breaks ----
bi = cond(X, BIMONTH)
print("E[X | bimonth]: " + show(bi))
cross = cond(lambda p: bi[BIMONTH(p)], SEASON)
print("not nested, E[E[X | bimonth] | season]: " + show(cross))
assert cross != by_season
V = lambda p: 3 if p[1] else 1                     # umbrellas per mm, by weather
print("V by weather: E[V X | season]: " + show(cond(lambda p: V(p) * X(p), SEASON))
      + "; E[V | season] E[X | season]: " + show({s: 2 * by_season[s] for s in range(4)}))
assert cond(lambda p: V(p) * X(p), SEASON) != {s: 2 * by_season[s] for s in range(4)}
N2 = lambda p: N(p) - 4 * (SEASON(p) == 2)          # summer evaporation loss
print("seasonal error: E[N2 | season]: " + show(cond(N2, SEASON)) + f"; E[N2] = {cond(N2, ALL)[0]}")
assert cond(N2, SEASON) != {s: cond(N2, ALL)[0] for s in range(4)}

# ---- conditional monotone convergence: a gauge that overflows at c mm ----
caps = [20, 40, 60, 80, 100, 120, 140]
print("figure, capacity c (mm): " + ", ".join(map(str, caps)))
rows = [cond(lambda p: min(X(p), c), SEASON) for c in caps]
for s, name in enumerate(NAMES):
    col = [r[s] for r in rows]
    print(f"figure, E[min(X, c) | {name}]: " + ", ".join(dec(v) for v in col))
    assert all(a <= b for a, b in zip(col, col[1:])) and col[-1] == by_season[s]

# ---- conditional dominated convergence: the burst X_n = n on [0, 1/n) ----
# Omega = [0, 1) under length; G = {early half [0, 1/2), late half}.
k = 1 << 14                               # midpoint rule on the early half
mids = [(i + 0.5) / (2 * k) for i in range(k)]
for n in [2, 4, 8, 16, 32, 64]:
    early, late = Q(n) * min(Q(1, n), Q(1, 2)) * 2, Q(n) * max(Q(1, n) - Q(1, 2), Q(0)) * 2
    capped = Q(min(n, 4)) * min(Q(1, n), Q(1, 2)) * 2
    r_early = sum(n for t in mids if t < 1 / n) / k
    r_cap = sum(min(n, 4) for t in mids if t < 1 / n) / k
    print(f"n = {n}: E[X_n | early] = {early} (midpoint {r_early:.4f}); E[X_n | late] = {late}; "
          f"E[min(X_n, 4) | early] = {capped} (midpoint {r_cap:.4f})")
    assert abs(r_early - float(early)) < 1e-12 and abs(r_cap - float(capped)) < 1e-12

# ---- road 3: sampling, SplitMix64, seed 20260929 ----
MASK, state = (1 << 64) - 1, 20260929
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
tot, tot2, cnt = [0.0] * 4, [0.0] * 4, [0] * 4
print("sampling: 48000 draws, SplitMix64 seed 20260929")
for _ in range(48000):
    p = OMEGA[splitmix() % 48]
    r = float(sales(p))
    tot[SEASON(p)] += r; tot2[SEASON(p)] += r * r; cnt[SEASON(p)] += 1
for s in range(4):
    m = tot[s] / cnt[s]
    se = ((tot2[s] / cnt[s] - m * m) / cnt[s]) ** 0.5
    print(f"sampled E[U X | {NAMES[s]}] over {cnt[s]} draws = {m:.2f}, standard error {se:.2f}")
    assert abs(m - float(pulled[s])) < 4 * se
print("ALL CHECKS PASS")
