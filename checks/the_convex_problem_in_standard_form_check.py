# The standard convex problem -- the check behind the card.  Nothing is imported.
# One kilo of coffee blended from Brazil, Colombia and Robusta beans: x[i] is the
# kilos of bean i.  Minimise the cost in pounds per kilo, keep caffeine at or
# above 1.6 percent, stay within 0.2 of the house recipe 50/30/20.  Each piece is
# judged twice: by the rules a solver applies to the formula, and by a midpoint
# test on random blends.  The answer is found twice: by a Cauchy-Schwarz bound
# that one blend meets, and by listing every blend on a 0.001 grid.
COST, CAF, REF, R2, N = [9.0, 12.0, 6.0], [1.2, 1.4, 2.4], [0.5, 0.3, 0.2], 0.04, 2000
def add(v):                                              # left to right, as Rust adds
    s = 0.0
    for t in v: s += t
    return s
def dot(a, x): return add(p * q for p, q in zip(a, x))
def aff(a, b): return ("aff", a, b)                      # a . x + b
def taste(): return ("sum", [("sq", aff([1.0 if j == i else 0.0 for j in range(3)], -REF[i]))
                             for i in range(3)])         # squared distance from the recipe
PIECES = [("f0 = c.x, cost to minimise", "min", aff(COST, 0.0)),
          ("h1 = x1 + x2 + x3 - 1", "eq", aff([1.0, 1.0, 1.0], -1.0)),
          ("f1 = 1.6 - s.x, caffeine", "le", aff([-c for c in CAF], 1.6)),
          ("f2 = taste - 0.04", "le", ("sum", [taste(), aff([0.0] * 3, -R2)]))] + \
         [(f"f{3 + i} = -x{i + 1}, no negative kilos", "le", aff([-1.0 if j == i else 0.0 for j in range(3)], 0.0))
          for i in range(3)]
BROKEN = [("taste = 0.04, the circle", "eq", ("sum", [taste(), aff([0.0] * 3, -R2)])),
          ("sqrt(taste) - 0.2 <= 0", "le", ("sum", [("sqrt", taste()), aff([0.0] * 3, -0.2)])),
          ("cost per caffeine, minimise", "min", ("div", aff(COST, 0.0), aff(CAF, 0.0)))]

def ev(e, x):                                            # the value of a formula at x
    k = e[0]
    if k == "aff": return dot(e[1], x) + e[2]
    if k == "sq": return ev(e[1], x) * ev(e[1], x)
    if k == "sqrt": return ev(e[1], x) ** 0.5
    if k == "sum": return add(ev(t, x) for t in e[1])
    return ev(e[1], x) / ev(e[2], x)                     # "div"

def curv(e):                                             # road one: the solver's rules
    k = e[0]
    if k == "aff": return "affine"
    if k == "sq": return "convex" if curv(e[1]) == "affine" else "unknown"
    if k == "sqrt": return "concave" if curv(e[1]) in ("affine", "concave") else "unknown"
    if k == "sum":
        kinds = {curv(t) for t in e[1]} - {"affine"}
        if not kinds: return "affine"
        return kinds.pop() if len(kinds) == 1 and "unknown" not in kinds else "unknown"
    return "unknown"                                     # no rule for a ratio

def accepted(role, e):
    return curv(e) == "affine" if role == "eq" else curv(e) in ("affine", "convex")

state = [2026]
def rnd():                                               # SplitMix64, seed 2026
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def blend():                                             # a random point of the triangle
    u, v = rnd(), rnd()
    if u + v > 1.0: u, v = 1.0 - u, 1.0 - v
    return [u, v, 1.0 - u - v]

PAIRS = [(blend(), blend()) for _ in range(N)]
def misses(role, e):                                     # road two: the midpoint test
    bad = 0
    for a, b in PAIRS:
        mid = ev(e, [(p + q) / 2 for p, q in zip(a, b)])
        avg = (ev(e, a) + ev(e, b)) / 2
        bad += abs(mid - avg) > 1e-9 if role == "eq" else mid > avg + 1e-9
    return bad

def feasible(x):
    caf = dot(CAF, x)
    return (abs(add(x) - 1) < 1e-9 and min(x) >= 0 and ev(taste(), x) <= R2 + 1e-12
            and caf >= 1.6)
def on_grid(i, j, k, flip):                              # the same tests in whole thousandths
    caf = 12 * i + 14 * j + 24 * k - 16000
    near = (i - 500) ** 2 + (j - 300) ** 2 + (k - 200) ** 2 <= R2 * 10 ** 6
    return near and (caf <= 0 if flip else caf >= 0)

def cost(x): return dot(COST, x)
def grid(flip=False):                                    # every blend on a 0.001 grid
    best, where, count = 1e9, None, 0
    for i in range(1001):
        for j in range(1001 - i):
            x = [i / 1000, j / 1000, (1000 - i - j) / 1000]
            if on_grid(i, j, 1000 - i - j, flip):
                count += 1
                if cost(x) < best: best, where = cost(x), x
    return best, where, count

print(f"Brazil, Colombia, Robusta: pounds a kilo {COST}, caffeine percent {CAF}")
print(f"{'piece':<28}{'rule says':<10}{'accepted':<10}midpoint misses in {N}")
results = []
for name, role, e in PIECES + BROKEN:
    ok, bad = accepted(role, e), misses(role, e)
    results.append((ok, bad))
    print(f"{name:<28}{curv(e):<10}{'yes' if ok else 'no':<10}{bad}")
print(f"house recipe {REF}: cost {cost(REF):.4f}, caffeine {dot(CAF, REF):.4f}")
m = add(COST) / 3
pc = [c - m for c in COST]                               # the cost with its even part removed
norm = dot(pc, pc) ** 0.5
bound = cost(REF) - R2 ** 0.5 * norm                     # Cauchy-Schwarz on the taste ball
xs = [r - R2 ** 0.5 * p / norm for r, p in zip(REF, pc)]
print(f"projected cost {pc}, its length {norm:.4f}; lower bound {cost(REF):.4f} - {R2 ** 0.5:.1f} x {norm:.4f} = {bound:.4f}")
print(f"step from the recipe: [{xs[0] - REF[0]:.4f}, {xs[1] - REF[1]:.4f}, {xs[2] - REF[2]:.4f}]")
print(f"blend meeting it: x* = [{xs[0]:.4f}, {xs[1]:.4f}, {xs[2]:.4f}], cost {cost(xs):.4f}, "
      f"caffeine {dot(CAF, xs):.4f}, taste {ev(taste(), xs):.4f}, feasible {'yes' if feasible(xs) else 'no'}")
gc, gx, gn = grid()
print(f"grid: {gn} of 501501 blends feasible; best {gx} at cost {gc:.4f}, {gc - bound:.4f} above the bound")
fc, fx, fn = grid(flip=True)
P, Q = [0.0, 0.8, 0.2], [2 / 3, 0.0, 1 / 3]              # where caffeine 1.6 meets the edges
d = [q - p for p, q in zip(P, Q)]
e0 = [p - r for p, r in zip(P, REF)]
qa, qb = dot(d, d), 2 * dot(d, e0)
qc = dot(e0, e0) - R2
root = (qb * qb - 4 * qa * qc) ** 0.5
cut = [[p + t * s for p, s in zip(P, d)] for t in ((-qb - root) / (2 * qa), (-qb + root) / (2 * qa))]
fl = min(cost(x) for x in cut)                           # a linear cost is least at an end of the chord
print(f"mistake, caffeine flipped to at most 1.6: exact {fl:.4f}; grid best {fx} at {fc:.4f}")
a, b = [2 * r - x for r, x in zip(REF, xs)], xs        # x* and its mirror through the recipe
mid = [(p + q) / 2 for p, q in zip(a, b)]
print(f"mistake, circle: x* and [{a[0]:.4f}, {a[1]:.4f}, {a[2]:.4f}] have taste {ev(taste(), a):.4f}, {ev(taste(), b):.4f}; "
      f"midpoint taste {ev(taste(), mid):.4f}")
ratio = BROKEN[2][2]
br, co = [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]
rm, ra = ev(ratio, [0.5, 0.5, 0.0]), (ev(ratio, br) + ev(ratio, co)) / 2
print(f"mistake, ratio: Brazil {ev(ratio, br):.4f}, Colombia {ev(ratio, co):.4f}, "
      f"half and half {rm:.4f} above their average {ra:.4f}")
def px(x):                                               # the figure: 240 px per unit, to scale
    u, w = (x[1] - x[2]) / 2 ** 0.5, (2 * x[0] - x[1] - x[2]) / 6 ** 0.5
    return f"({200 + 240 * u:.1f} {225 - 240 * w:.1f})"
print("figure, Brazil", px(br), "Colombia", px(co), "Robusta", px([0, 0, 1]), "recipe", px(REF),
      f"radius {240 * 0.2:.1f}", "x*", px(xs), "caffeine line", px(P), px(Q),
      "cuts circle", px(cut[0]), px(cut[1]))
assert all(bad == 0 for ok, bad in results[:7]) and all(ok for ok, bad in results[:7])
assert results[8][1] == 0 and not results[8][0]          # rejected, yet convex: the rules are cautious
assert not results[7][0] and not results[9][0] and results[7][1] > 0 and results[9][1] > 0 and rm > ra   # rejected, and truly not convex
assert feasible(xs) and abs(cost(xs) - bound) < 1e-12 and 0 <= gc - bound < 0.005
assert 0 <= fc - fl < 0.005 and fl > bound + 0.03 and ev(taste(), mid) < R2
print("ALL CHECKS PASS")
