# Sharing a joint cost: the Shapley value and the core -- the check behind the card.
# Nothing is imported.  Money is in whole pounds; a share is an exact fraction top/bottom.
# Game 1, the oven: three bakeries bake in turns in one oven sized for the biggest.  Alone they
# need ovens costing 1000, 2000 and 3000 pounds, so a group S pays the dearest: c(S) = max need.
# Game 2, the twins: a 1000-pound oven has two bakeries' shifts a night, so S pays 1000 per two.
# Shapley roads: (1) average extra cost over all n! orders, (2) the weighted sum over
# coalitions, (3) the airport rule: each step up in oven size split among those who need it.
# Core roads: (a) every coalition's limit checked directly, (b) a corner-checking LP solver.
NAMES = ["Ash", "Birch", "Cedar", "Dock"]
NEED = [1000, 2000, 3000]

def oven(needs):
    return lambda S: max([needs[i] for i in range(len(needs)) if S >> i & 1] + [0])
def twins(S):
    return 1000 * ((bin(S).count("1") + 1) // 2)
def fact(k):
    return 1 if k < 2 else k * fact(k - 1)
def orders(items):                    # every order of the items, written out
    if not items:
        return [[]]
    return [[x] + rest for x in items for rest in orders([y for y in items if y != x])]
def fmt(top, bottom):                 # pounds to 2 decimals, rounded half up, integers only
    sign, top = ("-", -top) if top < 0 else ("", top)
    cents = (200 * top + bottom) // (2 * bottom)
    return f"{sign}{cents // 100:,}.{cents % 100:02d}"

def shapley_orders(c, n):             # road 1: n! times each share
    tot = [0] * n
    for order in orders(list(range(n))):
        S = 0
        for i in order:
            tot[i] += c(S | 1 << i) - c(S)
            S |= 1 << i
    return tot
def shapley_subsets(c, n):            # road 2: |S|!(n-|S|-1)! weights, also over n!
    tot = [0] * n
    for i in range(n):
        for S in range(1 << n):
            if not S >> i & 1:
                s = bin(S).count("1")
                tot[i] += fact(s) * fact(n - s - 1) * (c(S | 1 << i) - c(S))
    return tot
def airport(needs):                   # road 3: n! times each share, smallest need first
    n, idx = len(needs), sorted(range(len(needs)), key=lambda i: needs[i])
    tot, acc, prev = [0] * n, 0, 0
    for k, i in enumerate(idx):
        acc += (needs[i] - prev) * fact(n) // (n - k)
        tot[i], prev = acc, needs[i]
    return tot

def core_breaks(x, bottom, c, n):     # road (a): coalitions charged more than going alone
    return [S for S in range(1, (1 << n) - 1) if sum(x[i] for i in range(n) if S >> i & 1) > c(S) * bottom]
def det3(m):
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
def corners(rows, n=3):               # road (b): make 3 rows tight, solve by Cramer, keep if all rows hold
    found = []
    for a in range(len(rows)):
        for b in range(a + 1, len(rows)):
            for d in range(b + 1, len(rows)):
                M, r = [rows[a][0], rows[b][0], rows[d][0]], [rows[a][1], rows[b][1], rows[d][1]]
                D = det3(M)
                if D == 0:
                    continue
                x = [det3([[r[k] if j == col else M[k][j] for j in range(n)] for k in range(n)]) for col in range(n)]
                if D < 0:
                    D, x = -D, [-v for v in x]
                fits = all(sum(row[j] * x[j] for j in range(n)) <= lim * D for row, lim in rows)
                if fits and all(any(x[j] * e != y[j] * D for j in range(n)) for y, e in found):
                    found.append((x, D))
    return found
def limits(c, n=3):
    return [([S >> j & 1 for j in range(n)], c(S)) for S in range(1, (1 << n) - 1)]
def lp_room(c):                       # most the bakeries can be charged with no coalition overcharged
    best = (0, 1)
    for x, D in corners(limits(c)):
        if sum(x) * best[1] > best[0] * D:
            best = (sum(x), D)
    return best
def members(S):
    return "{" + ", ".join(NAMES[i] for i in range(4) if S >> i & 1) + "}"

c, F = oven(NEED), fact(3)
r1, r2, r3 = shapley_orders(c, 3), shapley_subsets(c, 3), airport(NEED)
for S in range(1, 8):
    print(f"oven game, c({members(S)}) = {c(S)}")
marginal = {}
for order in orders([0, 1, 2]):
    S, extra, v = 0, [], [0, 0, 0]
    for i in order:
        v[i] = c(S | 1 << i) - c(S)
        extra.append(f"{NAMES[i]} +{v[i]}")
        S |= 1 << i
    marginal[''.join(NAMES[i][0] for i in order)] = v
    print(f"order {'-'.join(NAMES[i][0] for i in order)}: {', '.join(extra)}; in the core: {'no' if core_breaks(v, 1, c, 3) else 'yes'}")
for name, r in (("road 1, all 6 orders", r1), ("road 2, coalition weights", r2), ("road 3, airport steps", r3)):
    print(f"{name}: 6 x shares = {r}; shares {', '.join(fmt(v, F) for v in r)}")
terms = [(S, fact(bin(S).count("1")) * fact(2 - bin(S).count("1")), c(S | 2) - c(S)) for S in (0, 1, 4, 5)]
print("Birch's road-2 terms: " + "; ".join(f"{members(S)} weight {w}/6 adds {e} -> {fmt(w * e, F)}" for S, w, e in terms) + f"; weights add to {sum(t[1] for t in terms)}/6")
steps = sorted(NEED)
print("airport steps: " + ", ".join(f"{b - a} shared by {3 - k} -> {fmt(b - a, 3 - k)} each" for k, (a, b) in enumerate(zip([0] + steps, steps))))
print(f"efficiency: shares add to {fmt(sum(r1), F)} = c(all) = {c(7)}")
print(f"Shapley shares break the core for coalitions: {core_breaks(r1, F, c, 3) or 'none'}; pair totals "
      + ", ".join(f"{members(S)} {fmt(sum(r1[i] for i in range(3) if S >> i & 1), F)} against {c(S)}" for S in (3, 5, 6)))
print(f"savings against going alone: {', '.join(fmt(NEED[i] * F - r1[i], F) for i in range(3))}; three ovens cost {sum(NEED)}, one shared {c(7)}, saving {sum(NEED) - c(7)}")
core = corners(limits(c) + [([1, 1, 1], c(7)), ([-1, -1, -1], -c(7))])
print(f"core corners (Ash, Birch, Cedar): {'; '.join('(' + ', '.join(fmt(v, D) for v in x) + ')' for x, D in core)}")
room, pairs = lp_room(c), lambda g: g(3) + g(5) + g(6)   # pair limits added: twice the total is at most this
print(f"LP room: at most {fmt(*room)} can be charged (pair limits add to {pairs(c)}), need {c(7)}: core {'non-empty' if room[0] >= c(7) * room[1] else 'empty'}")

t1 = shapley_orders(twins, 3)
print(f"twins game: shares {', '.join(fmt(v, F) for v in t1)}; a pair pays {fmt(t1[0] + t1[1], F)} against c(pair) = {twins(3)}")
print(f"twins game: Shapley breaks the core for coalitions: {', '.join(map(members, core_breaks(t1, F, twins, 3)))}")
troom = lp_room(twins)
print(f"twins LP room: at most {fmt(*troom)} can be charged (pair limits add to {pairs(twins)}), need {twins(7)}: core {'non-empty' if troom[0] >= twins(7) * troom[1] else 'empty'}")
both = shapley_orders(lambda S: c(S) + twins(S), 3)
print(f"additivity: oven + twins shares {', '.join(fmt(v, F) for v in both)}")
d4 = shapley_orders(oven(NEED + [0]), 4)
print(f"null player: with Dock (needs no oven) shares {', '.join(fmt(v, fact(4)) for v in d4)}")

banz = [sum(c(S | 1 << i) - c(S) for S in range(8) if not S >> i & 1) for i in range(3)]
alone_ok = [500, 2000, 500]
print(f"mistake, one order only: A-B-C charges {marginal['ABC']}, C-B-A charges {marginal['CBA']}")
print(f"mistake, average over coalitions not orders: {', '.join(fmt(v, 4) for v in banz)}; total {fmt(sum(banz), 4)}, short by {fmt(c(7) * 4 - sum(banz), 4)}")
print(f"mistake, check only bakeries alone: {alone_ok} passes alone; coalitions broken: {', '.join(map(members, core_breaks(alone_ok, 1, c, 3)))} (Ash+Birch pay {alone_ok[0] + alone_ok[1]})")
X = lambda v: 60 + 0.08 * v
Y = lambda v: 210 - 0.08 * v
print(f"figure, core corners at {', '.join(f'({X(x[0] / D):.1f}, {Y(x[1] / D):.1f})' for x, D in core)}; Shapley at ({X(r1[0] / F):.1f}, {Y(r1[1] / F):.1f}); bad split at ({X(500):.1f}, {Y(2000):.1f})")

assert r1 == r2 == r3 == [2000, 5000, 11000]          # three roads agree, and match 1/3, 5/6, 11/6
assert sum(r1) == c(7) * F and sum(t1) == twins(7) * F  # efficiency
assert core_breaks(r1, F, c, 3) == [] and core_breaks(t1, F, twins, 3) == [3, 5, 6]
assert room[0] >= c(7) * room[1] and troom[0] < twins(7) * troom[1]  # Bondareva-Shapley by corners
assert 2 * room[0] == pairs(c) * room[1] and 2 * troom[0] == pairs(twins) * troom[1]  # LP optimum = pair bound
assert len(core) == 4 and t1[0] == t1[1] == t1[2]       # core shape, symmetry
assert {tuple(x) for x, D in core if D == 1} == {tuple(v) for v in marginal.values()}  # corners = orders
assert [sum(v[i] for v in marginal.values()) for i in range(3)] == r3 and sum(w * e for S, w, e in terms) == r3[1]
assert both == [r1[i] + t1[i] for i in range(3)] and d4 == [4 * v for v in r1] + [0]  # additivity, null player
assert sum(banz) != c(7) * 4 and core_breaks(alone_ok, 1, c, 3) == [3]
print("ALL CHECKS PASS")
