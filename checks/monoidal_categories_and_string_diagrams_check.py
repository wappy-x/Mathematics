# Monoidal categories and string diagrams -- the check behind the card.  Nothing
# is imported.  Two parcels ride two lanes: A (1,200 g) through a box machine,
# B (800 g) through a wrap machine, then both through pricing, and a merge adds
# the two bills.  Road one reads the diagram stage by stage, road two lane by
# lane, road three slides one box past the other; a search then checks the same
# law for every function on a two-member set, and the swap and the brackets too.
def box(w): return w + 150                   # f: adds 150 g of cardboard
def wrap(w): return w + 50                   # g: adds 50 g of bubble wrap
def price(w): return 300 + w // 10           # f' = g': 300 p plus 1 p per 10 g
def merge(pair): return pair[0] + pair[1]    # two wires in, one wire out
def tensor(f, g): return lambda p: (f(p[0]), g(p[1]))    # side by side
def then(f, g): return lambda x: g(f(x))                 # in turn: f, then g
def ident(x): return x
def swap(p): return (p[1], p[0])                         # two wires crossing
def assoc(t): return (t[0][0], (t[0][1], t[1]))          # ((a, b), c) -> (a, (b, c))
def yn(c): return "yes" if c else "no"

parcels = (1200, 800)
by_stage = then(tensor(box, wrap), tensor(price, price))     # (f' x g') o (f x g)
by_lane = tensor(then(box, price), then(wrap, price))        # (f' o f) x (g' o g)
slid = then(then(tensor(ident, wrap), tensor(box, ident)), tensor(price, price))
print(f"parcels in: A {parcels[0]} g, B {parcels[1]} g")
print(f"after box and wrap, side by side: {tensor(box, wrap)(parcels)}")
print(f"road 1, stage by stage: bills {by_stage(parcels)} pence")
print(f"road 2, lane by lane:   bills {by_lane(parcels)} pence")
print(f"road 3, wrap slid before box: bills {slid(parcels)} pence")
print(f"merge the two wires into one: {merge(by_stage(parcels))} pence")

tables = [(a, b) for a in (0, 1) for b in (0, 1)]    # every function {0,1} -> {0,1}
fns = [lambda x, t=t: t[x] for t in tables]
pairs = [(a, b) for a in (0, 1) for b in (0, 1)]
quads = [(f, g, h, k) for f in fns for g in fns for h in fns for k in fns]
law = slide = 0
for f, g, h, k in quads:
    for p in pairs:
        law += then(tensor(f, g), tensor(h, k))(p) != tensor(then(f, h), then(g, k))(p)
        slide += then(tensor(f, ident), tensor(ident, g))(p) != then(tensor(ident, g), tensor(f, ident))(p)
cross = sum(swap(tensor(f, g)(p)) != tensor(g, f)(swap(p)) for f in fns for g in fns for p in pairs)
twice = sum(swap(swap(p)) != p for p in pairs)
print(f"all functions on {{0, 1}}: {len(fns)}; quadruples {len(quads)}, inputs checked {len(quads) * len(pairs)}")
print(f"interchange failures {law}; sliding failures {slide}; crossing failures {cross}; swap twice failures {twice}")

quad = [(((a, b), c), d) for a in (0, 1) for b in (0, 1) for c in (0, 1) for d in (0, 1)]
path1 = [assoc(assoc(x)) for x in quad]
path2 = [then(then(tensor(assoc, ident), assoc), tensor(ident, assoc))(x) for x in quad]
print(f"pentagon: {len(quad)} members of ((A x B) x C) x D, the two re-bracketings agree on {sum(a == b for a, b in zip(path1, path2))}")
x = ((0, 1), 0)
left3 = [((a, b), c) for a in (0, 1) for b in (0, 1) for c in (0, 1)]    # (A x B) x C, listed
print(f"brackets: {x} becomes {assoc(x)}; the same element: {yn(x == assoc(x))}; both sets have "
      f"{len(left3)} members, matched one for one: {yn(len({assoc(t) for t in left3}) == len(left3))}")
print(f"unit: A = {{0, 1, 2}} beside the one-point set has {len([(a, u) for a in (0, 1, 2) for u in [()]])} members")

def labels(order):                     # a labeller that shares one counter
    count, out = 0, {}
    for lane in order:
        count += 1
        out[lane] = count
    return out
l1, l2 = labels("AB"), labels("BA")
print(f"mistake 1, shared counter: lane A first gives A #{l1['A']}, B #{l1['B']}; lane B first gives A #{l2['A']}, B #{l2['B']}")
print(f"mistake 2, price before box: {price(parcels[0])} p, not {by_lane(parcels)[0]} p")

def kron(m, n): return [[m[i // 2][j // 2] * n[i % 2][j % 2] for j in range(4)] for i in range(4)]
def mul(m, n): return [[sum(m[i][t] * n[t][j] for t in range(len(n))) for j in range(len(n[0]))] for i in range(len(m))]
a, b, a2, b2 = [[1, 1], [0, 1]], [[2, 0], [0, 1]], [[0, 1], [1, 0]], [[1, 0], [1, 1]]
lhs, rhs = mul(kron(a2, b2), kron(a, b)), kron(mul(a2, a), mul(b2, b))
print(f"vectors: (A' x B')(A x B) = (A'A) x (B'B): {yn(lhs == rhs)}; rows {rhs}")
u3, w3 = [1, 2], [3, 4, 5]                   # one vector in R^2, one in R^3
print(f"mistake 3, dimensions: R^2 tensor R^3 has {len([s * t for s in u3 for t in w3])}, "
      f"R^2 and R^3 listed one after the other (the direct sum) has {len(u3 + w3)}")
v = (1, 0, 0, 1)
grid = [(s, t) for s in range(-3, 4) for t in range(-3, 4)]
hits = [(u, w) for u in grid for w in grid if (u[0] * w[0], u[0] * w[1], u[1] * w[0], u[1] * w[1]) == v]
print(f"mistake 4, {v} as a pair: ad - bc = {v[0] * v[3] - v[1] * v[2]}; pairs found with entries -3 to 3: {len(hits)}")
pa, pb = (90, 10), (80, 20)
joint = [pa[i] * pb[j] // 100 for i in (0, 1) for j in (0, 1)]
print(f"independent lanes: {pa} x {pb} percent = {joint}; ad - bc = {joint[0] * joint[3] - joint[1] * joint[2]}")
step, g = 1, (1, 1)
while g != (0, 0):
    g, step = ((g[0] + 1) % 2, (g[1] + 1) % 3), step + 1
z6 = [(s, t) for s in range(2) for t in range(3)]
print(f"groups: Z2 x Z3 has {len(z6)} members; (1, 1) has order {step}")
cols = [200 + 200 * k for k in range(3)]     # figure layout: one column per stage, one row per lane
rows = [90 + 100 * i for i in range(len(parcels))]
print(f"figure, schematic: stage columns x {cols}; lane wires y {rows}; merged wire y {sum(rows) // 2}")
assert by_stage(parcels) == (435, 385) and merge(by_stage(parcels)) == 820   # by hand
assert by_lane(parcels) == by_stage(parcels) == slid(parcels)
assert law == slide == cross == twice == 0 and path1 == path2
assert l1 != l2 and lhs == rhs and len(hits) == 0 and step == 6
assert len(z6) == step and len({assoc(t) for t in left3}) == len(left3) == 8   # order against size
print("ALL CHECKS PASS")
