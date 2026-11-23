# Universal properties -- the check behind the card.  Nothing is imported.
# A shirt shop: 2 colours, 3 sizes, 4 orders today.  The product of colours and
# sizes is fixed by its two projections.  Every claim is a count over every
# function, set against a count found another way.
COLOURS, SIZES, ORDERS = ["red", "blue"], ["S", "M", "L"], ["#1", "#2", "#3", "#4"]
F = ["red", "blue", "red", "blue"]               # f: the colour of each order
G = ["M", "S", "L", "M"]                         # g: the size of each order
PROD = [(c, s) for c in COLOURS for s in SIZES]  # the 6 pairs, A x B

def maps(dom, cod):                  # every function dom -> cod, as a tuple of images
    out = [()]
    for _ in dom:
        out = [m + (y,) for m in out for y in cod]
    return out

def tally(points, pa, pb, dom):      # for each h: dom -> points, record (pa o h, pb o h)
    seen = {}
    for h in maps(dom, points):
        key = (tuple(pa(p) for p in h), tuple(pb(p) for p in h))
        seen[key] = seen.get(key, 0) + 1
    return seen

def counts(points, pa, pb):          # how many h fit each of the 16 x 81 pairs (f, g)
    seen = tally(points, pa, pb, ORDERS)
    return [seen.get((f, g), 0) for f in maps(ORDERS, COLOURS) for g in maps(ORDERS, SIZES)]

first, second = (lambda p: p[0]), (lambda p: p[1])
yn = lambda claim: "yes" if claim else "no"
pairs = len(maps(ORDERS, COLOURS)) * len(maps(ORDERS, SIZES))
prod_counts = counts(PROD, first, second)
h = tuple((F[i], G[i]) for i in range(len(ORDERS)))   # the formula: h(x) = (f(x), g(x))
print(f"colours {len(COLOURS)}, sizes {len(SIZES)}, pairs in A x B {len(PROD)}, orders {len(ORDERS)}")
print(f"maps orders -> colours {len(maps(ORDERS, COLOURS))}, -> sizes {len(maps(ORDERS, SIZES))}, "
      f"pairs (f, g) {pairs}; maps orders -> A x B {len(maps(ORDERS, PROD))}")
print(f"pairs (f, g) met by exactly one h: {prod_counts.count(1)} of {pairs}")
print("today's h:", ", ".join(f"{o} -> {c} {s}" for o, (c, s) in zip(ORDERS, h)))
print(f"maps orders -> one-point set: {len(maps(ORDERS, ['*']))}; maps empty set -> sizes: {len(maps([], SIZES))}")

BIG = [(c, s, b) for c in COLOURS for s in SIZES for b in (0, 1)]   # an extra bit
SMALL = [p for p in PROD if p != ("blue", "L")]                     # blue L missing
big_counts, small_counts = counts(BIG, first, second), counts(SMALL, first, second)
print(f"mistake, 12-point candidate with a spare bit: {big_counts.count(16)} pairs met by 16 maps each")
print(f"mistake, 5-point candidate missing blue L: {small_counts.count(0)} pairs met by no map; "
      f"by subtraction {pairs} - 5^4 = {pairs - 5 ** 4}")

CODES = list(range(6))                           # a second product: stock codes 0 to 5
colour_of, size_of = (lambda n: COLOURS[n // 3]), (lambda n: SIZES[n % 3])
code_counts = counts(CODES, colour_of, size_of)
fits = [u for u in maps(PROD, CODES)
        if all(colour_of(u[i]) == c and size_of(u[i]) == s for i, (c, s) in enumerate(PROD))]
bij = [u for u in maps(PROD, CODES) if len(set(u)) == 6]
ends = [e for e in maps(PROD, PROD) if all(e[i] == p for i, p in enumerate(PROD))]
ends_fit = [e for e in maps(PROD, PROD)
            if all(e[i][0] == p[0] and e[i][1] == p[1] for i, p in enumerate(PROD))]
formula_u = tuple(3 * COLOURS.index(c) + SIZES.index(s) for c, s in PROD)
v = [(colour_of(n), size_of(n)) for n in CODES]  # back again: v(n) = (colour of n, size of n)
u_after_v = [fits[0][PROD.index(p)] for p in v]  # code -> its pair -> the code u gives that pair
print(f"stock codes as a product too: {code_counts.count(1)} of {pairs} pairs met once")
print(f"maps A x B -> codes {len(maps(PROD, CODES))}, of them bijections {len(bij)}, "
      f"respecting both projections {len(fits)}")
print("the one that fits:", ", ".join(f"{c} {s} -> {n}" for (c, s), n in zip(PROD, fits[0])))
print(f"maps A x B -> A x B {len(maps(PROD, PROD))}, respecting both projections {len(ends_fit)}")
print(f"codes -> pairs -> codes returns every code: {yn(u_after_v == CODES)}")

TAGGED = [("colour", c) for c in COLOURS] + [("size", s) for s in SIZES]   # A + B
Y = ["yes", "no"]
co = {}
for k in maps(TAGGED, Y):            # each k: A + B -> Y gives (k on colours, k on sizes)
    key = (k[:len(COLOURS)], k[len(COLOURS):])
    co[key] = co.get(key, 0) + 1
co_pairs = len(maps(COLOURS, Y)) * len(maps(SIZES, Y))
print(f"A + B has {len(TAGGED)} points; maps A + B -> yes/no {len(maps(TAGGED, Y))}, "
      f"pairs (p, q) {co_pairs}, met exactly once {list(co.values()).count(1)}")
print(f"mistake, A x B used as the coproduct: maps A x B -> yes/no {len(maps(PROD, Y))}, not {co_pairs}")

TOPS = ["mushroom", "olive", "chilli"]           # the power set, ordered by inclusion
SUBS = [frozenset(t for i, t in enumerate(TOPS) if bits >> i & 1) for bits in range(8)]
def best(U, V, below):               # the bound of U and V that every other bound passes through
    cands = [W for W in SUBS if (W <= U and W <= V if below else U <= W and V <= W)]
    return [W for W in cands if all((X <= W) if below else (W <= X) for X in cands)]
meets = sum(best(U, V, True) == [U & V] for U in SUBS for V in SUBS)
joins = sum(best(U, V, False) == [U | V] for U in SUBS for V in SUBS)
print(f"subsets of 3 toppings {len(SUBS)}; product = intersection in {meets} of 64 pairs, "
      f"coproduct = union in {joins} of 64")

Z6, Z2, Z3 = range(6), range(2), range(3)        # groups alongside: homomorphisms out of Z6
def homs(cod, add):
    return [m for m in maps(Z6, cod) if all(m[(x + y) % 6] == add(m[x], m[y]) for x in Z6 for y in Z6)]
Z23 = [(a, b) for a in Z2 for b in Z3]
h2, h3 = homs(Z2, lambda a, b: (a + b) % 2), homs(Z3, lambda a, b: (a + b) % 3)
h23 = homs(Z23, lambda p, q: ((p[0] + q[0]) % 2, (p[1] + q[1]) % 3))
print(f"homomorphisms Z6 -> Z2 {len(h2)}, Z6 -> Z3 {len(h3)}, Z6 -> Z2 x Z3 {len(h23)}")

def mul(p, q):                       # 2 x 2 integer matrices, written (a, b, c, d)
    return (p[0] * q[0] + p[1] * q[2], p[0] * q[1] + p[1] * q[3],
            p[2] * q[0] + p[3] * q[2], p[2] * q[1] + p[3] * q[3])
def sign(p):                         # a matrix and its negative count as one element
    return p if next(x for x in p if x != 0) > 0 else tuple(-x for x in p)
A2, B3 = (0, -1, 1, 0), (0, -1, 1, 1)            # orders 2 and 3, once signs are ignored
gens, level, seen, by_matrix, by_words = [A2, B3, mul(B3, B3)], {(1, 0, 0, 1)}, {(1, 0, 0, 1)}, [1], [1]
for k in range(1, 5):
    level = {sign(mul(p, g)) for p in level for g in gens} - seen
    seen |= level
    by_matrix.append(len(seen))
    by_words.append(by_words[-1] + 2 ** (k // 2) + 2 ** ((k + 1) // 2))
print(f"Z2 * Z3, elements of word length up to 0..4: by matrices {by_matrix}, by counting words {by_words}")
print("figure, nodes: orders (210,50) | A x B (210,170) | colours (70,290) | sizes (350,290)")

assert prod_counts.count(1) == pairs == 2 ** 4 * 3 ** 4 == len(maps(ORDERS, PROD))   # existence, uniqueness
assert [m for m in maps(ORDERS, PROD) if [p[0] for p in m] == F and [p[1] for p in m] == G] == [h]
assert big_counts.count(16) == pairs and small_counts.count(0) == pairs - 5 ** 4
assert len(fits) == 1 and fits[0] == formula_u and len(bij) == 720 and ends_fit == ends
assert code_counts.count(1) == pairs and u_after_v == CODES          # the codes are a product too
assert list(co.values()).count(1) == co_pairs == 2 ** 5 and len(maps(PROD, Y)) == 64
assert meets == joins == 64 and (len(h2), len(h3), len(h23)) == (2, 3, 6)
assert by_matrix == by_words == [1, 4, 8, 14, 22]
print("ALL CHECKS PASS")
