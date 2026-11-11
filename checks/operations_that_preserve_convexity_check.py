# Building convex functions -- the check behind the card.  Nothing is imported.
# A roaster blends Brazil, Colombia and Ethiopia beans (shares x1, x2, x3 of a
# kilo).  Cost: the worst of three supplier quotes, a 50% surcharge on any part
# above a £10 budget, and a £2 taste penalty per squared strength point off 7.
# Roads: nested ternary search, every blend on a 1/128 grid, a subgradient
# certificate, and chord tests on random pairs.  Breaking a rule shows a dent.
QUOTES = {"A": (8, 12, 11), "B": (10, 9, 12), "C": (9, 11, 9)}
STRENGTH, TARGET, W, BUDGET = (5, 9, 7), 7, 2, 10

def dot(p, x): return p[0] * x[0] + p[1] * x[1] + p[2] * x[2]
def worst(x): return max(dot(q, x) for q in QUOTES.values())
def best_quote(x): return min(dot(q, x) for q in QUOTES.values())
def surcharge(c): return c + 0.5 * max(0.0, c - BUDGET)        # slopes 1, then 1.5
def discount(c): return c - 0.5 * max(0.0, c - BUDGET)         # slopes 1, then 0.5
def taste(x): d = dot(STRENGTH, x) - TARGET; return W * d * d
def cost(x): return surcharge(worst(x)) + taste(x)

def ternary(fn, lo, hi):                     # valid only because fn is convex
    for _ in range(100):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        if fn(m1) <= fn(m2): hi = m2
        else: lo = m1
    return (lo + hi) / 2

def inner(x1):                               # V(x1): best Colombia share for a fixed Brazil share
    r = 1 - x1
    x2 = ternary(lambda t: cost((x1, t, r - t)), 0.0, r)
    return cost((x1, x2, r - x2)), x2

def all_or_nothing(x1):                      # Colombia either 0 or all the rest: not a convex choice
    return min(cost((x1, 0.0, 1 - x1)), cost((x1, 1 - x1, 0.0)))

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, (z ^ (z >> 31)) >> 11

def chord_test(fn, pairs, seed):             # count mixes that rise above the chord
    state, bad, worst_gap = seed, 0, 0.0
    for _ in range(pairs):
        u = []
        for _ in range(5):
            state, r = splitmix(state)
            u.append(r / 2.0 ** 53)
        def blend(a, b):
            lo, hi = min(a, b), max(a, b)
            return (lo, hi - lo, 1 - hi)
        x, y, th = blend(u[0], u[1]), blend(u[2], u[3]), u[4]
        m = tuple(th * x[i] + (1 - th) * y[i] for i in range(3))
        gap = fn(m) - (th * fn(x) + (1 - th) * fn(y))
        if gap > 1e-9: bad += 1
        worst_gap = max(worst_gap, gap)
    return bad, worst_gap

def fmt(v): return "(" + ", ".join(f"{t:.2f}" for t in v) + ")"
def ints(v): return "(" + ", ".join(str(int(t)) for t in v) + ")"

print("inputs: quotes " + ", ".join(f"{k} {ints(q)}" for k, q in QUOTES.items())
      + f"; strength {ints(STRENGTH)}, target {TARGET}, weight {W}, budget {BUDGET}")

# Road 1: nested ternary search, outer over Brazil, inner over Colombia.
x1 = ternary(lambda t: inner(t)[0], 0.0, 1.0)
v1, x2 = inner(x1)
print(f"road 1, nested ternary search: shares {x1:.7f}, {x2:.7f}, {1 - x1 - x2:.7f}; cost {v1:.7f}")
# Road 2: every blend whose shares are multiples of 1/128.
n, grid = 128, (None, None)
for i in range(n + 1):
    for j in range(n + 1 - i):
        c = cost((i / n, j / n, (n - i - j) / n))
        if grid[0] is None or c < grid[0]: grid = (c, (i, j, n - i - j))
print(f"road 2, all {(n + 1) * (n + 2) // 2} blends in steps of 1/128: best {grid[1][0]}/128, "
      f"{grid[1][1]}/128, {grid[1][2]}/128; cost {grid[0]:.7f}")
xs = tuple(k / n for k in grid[1])
qa, qb, qc = (dot(QUOTES[k], xs) for k in "ABC")
s = dot(STRENGTH, xs)
print("in 128ths of a pound: quotes " + ", ".join(f"{k} {dot(QUOTES[k], grid[1])}" for k in "ABC")
      + f"; strength {dot(STRENGTH, grid[1])} in 128ths of a point")
print(f"at that blend: quotes A {qa:.7f}, B {qb:.7f}, C {qc:.7f}; worst {worst(xs):.7f}, "
      f"after surcharge {surcharge(worst(xs)):.7f}")
print(f"strength {s:.4f}, miss {s - TARGET:.4f}, taste penalty {taste(xs):.7f}; total {cost(xs):.7f}")
# Road 3: the certificate.  Half of A's prices plus half of C's, plus the taste slope.
half = tuple((QUOTES["A"][i] + QUOTES["C"][i]) / 2 for i in range(3))
slope = tuple(2 * W * (s - TARGET) * STRENGTH[i] for i in range(3))
cert = tuple(half[i] + slope[i] for i in range(3))
print(f"certificate: half A + half C {fmt(half)}, taste slope {fmt(slope)}, sum {fmt(cert)}")
# Road 4: chord tests on 20000 random pairs of blends and random mixes.
bad, gap = chord_test(cost, 20000, 2026)
print(f"chord test, built cost: {bad} of 20000 mixes above the chord")
bad_b, gap_b = chord_test(best_quote, 20000, 2026)
print(f"chord test, best quote instead of worst: {bad_b} of 20000 above, worst by {gap_b:.4f}")
# The chart: V(x1), best cost for each Brazil share, against the all-or-nothing version.
ts = [k / 10 for k in range(11)]
vs = [inner(t)[0] for t in ts]
an = [all_or_nothing(t) for t in ts]
print("chart, V by Brazil share 0.0 to 1.0:", ", ".join(f"{v:.2f}" for v in vs))
print("chart, all-or-nothing Colombia:     ", ", ".join(f"{v:.2f}" for v in an))
d2 = [vs[k - 1] + vs[k + 1] - 2 * vs[k] for k in range(1, 10)]
d2n = [an[k - 1] + an[k + 1] - 2 * an[k] for k in range(1, 10)]
print(f"smallest second difference: V {min(d2):.4f}; all-or-nothing {min(d2n):.4f} at Brazil "
      f"{ts[1 + d2n.index(min(d2n))]:.1f}")
# What breaks: one chord each, mid = the halfway blend.
def show(label, fn, x, y):
    m = tuple((x[i] + y[i]) / 2 for i in range(3))
    mid, chord = fn(m), (fn(x) + fn(y)) / 2
    print(f"{label}: ends {fn(x):.4f} and {fn(y):.4f}, midpoint {mid:.4f}, chord {chord:.4f}, "
          f"bulge {mid - chord:.4f}")
    return mid - chord
b1 = show("break 1, best quote", best_quote, (1, 0, 0), (0, 1, 0))
b2 = show("break 2, squared miss of budget", lambda x: (worst(x) - BUDGET) ** 2, (1, 0, 0), (0.5, 0.5, 0))
b3 = show("break 3, bulk discount above budget", lambda x: discount(worst(x)), (0.7, 0.3, 0), (0.8, 0, 0.2))
print(f"break 4, all-or-nothing Colombia: at Brazil 0.2, 0.3, 0.4 cost {an[2]:.4f}, {an[3]:.4f}, "
      f"{an[4]:.4f}; bulge {an[3] - (an[2] + an[4]) / 2:.4f}")
assert abs(v1 - grid[0]) < 1e-9 and abs(x1 - xs[0]) < 1e-6      # two searches, one answer
assert abs(cert[0] - cert[1]) < 1e-12 and abs(cert[1] - cert[2]) < 1e-12 and worst(xs) < BUDGET
assert bad == 0 and bad_b > 0                                  # rules hold, broken rule shows
assert min(d2) > -1e-9 and min(d2n) < 0                        # V is a bowl, the dented one is not
assert b1 > 0 and b2 > 0 and b3 > 0                            # each broken rule bulges
print("ALL CHECKS PASS")
