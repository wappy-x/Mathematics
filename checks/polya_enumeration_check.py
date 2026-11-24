# Polya counting -- the check behind the card.  Nothing is imported.  A move is a list: the
# corner in position i goes to position move[i].  Road one: cycles, cycle index, colours in its
# slots.  Road two: paint every pattern, list the orbits by brute force, sort them by colour.
def group(n, flips=True):                      # the turns of an n-sided shape, then flips
    return [[(s * i + k) % n for i in range(n)] for s in ((1, -1) if flips else (1,)) for k in range(n)]
def cycles(m):                                 # cycle lengths of one move: r2 gives [2, 2]
    seen, out = set(), []
    for i in range(len(m)):
        j, n = i, 0
        while j not in seen: seen.add(j); j, n = m[j], n + 1
        if n: out.append(n)
    return out
def term(m):                                   # the move's term, written like x1^2x2
    c = cycles(m)
    return "".join(f"x{n}" + (f"^{c.count(n)}" if c.count(n) > 1 else "") for n in sorted(set(c)))
def mul(p, q):                                 # multiply two polynomials in the colours
    out = {}
    for (a, u), (b, v) in ((s, t) for s in p.items() for t in q.items()):
        e = tuple(x + y for x, y in zip(a, b)); out[e] = out.get(e, 0) + u * v
    return out
def fill(m, k, e, power=True):                 # each slot xn becomes c1^n + ... + ck^n;
    p = {(0,) * k: 1}                          # return the coefficient of the type e
    for n in cycles(m):
        p = mul(p, {tuple((n if power else 1) * (c == d) for d in range(k)): 1 for c in range(k)})
    return p.get(e, 0)
def paints(n, k): return [()] if n == 0 else [p + (c,) for p in paints(n - 1, k) for c in range(k)]
def act(m, p): return tuple(p[m.index(j)] for j in range(len(m)))   # paint rides with corner
def orbits(G, k): return {min(act(m, p) for m in G) for p in paints(len(G[0]), k)}
def by_type(G, k, e): return sum(1 for o in orbits(G, k) if tuple(o.count(c) for c in range(k)) == e)
def row(t, v): print(f"{t:<22}" + "".join(f"{x:>8}" for x in v))
def index(G): return {t: list(map(term, G)).count(t) for t in map(term, G)}   # each term: how many moves
def zline(G): return "Z = (" + " + ".join((f"{c} " if c > 1 else "") + t for t, c in index(G).items()) + f") / {len(G)}"
def avg(v, G, listed):                         # Burnside's average: must divide exactly, and match the listing
    assert sum(v) % len(G) == 0 and sum(v) // len(G) == listed, (v, listed); return sum(v) // len(G)
T = group(4); terms = index(T)
def parts(f): return [c * f(next(m for m in T if term(m) == t)) for t, c in terms.items()]
row("move", [f"r{k}" for k in range(4)] + [f"r{k}f" for k in range(4)])
row("its cycle term", [term(m) for m in T])
for k in (2, 3): row(f"k^cycles, k = {k}", [k ** len(cycles(m)) for m in T])
print(zline(T))
for k in (2, 3, 4):
    pk, n = parts(lambda m: k ** len(cycles(m))), len(orbits(T, k))
    print(f"k = {k}: ({' + '.join(map(str, pk))}) / 8 = {avg(pk, T, n)}; listing the orbits gives {n}")
types = [(b, 4 - b) for b in (4, 3, 2, 1, 0)]
inv, two = [sum(fill(m, 2, e) for m in T) for e in types], parts(lambda m: fill(m, 2, (2, 2)))
print(f"two black corners: ({' + '.join(map(str, two))}) / 8 = {avg(two, T, by_type(T, 2, (2, 2)))}")
row("4,3,2,1,0 black: Z", [avg([v], T, by_type(T, 2, e)) for v, e in zip(inv, types)])
row("4,3,2,1,0 black: list", [by_type(T, 2, e) for e in types])
H, N, rb = group(6), group(6, False), (2, 2, 1, 1)
br, nk, bz = [fill(m, 4, rb) for m in H], [fill(m, 4, rb) for m in N], [fill(m, 2, (4, 2)) for m in H]
print("hexagon: " + zline(H))
print(f"R R B B G Y bracelets: ({' + '.join(str(v) for v in br if v)}) / {len(H)} = {avg(br, H, by_type(H, 4, rb))}, "
      f"listing {by_type(H, 4, rb)}; necklaces {avg(nk, N, by_type(N, 4, rb))}, listing {by_type(N, 4, rb)}")
print(f"benzene, 4 H, 2 Cl: ({' + '.join(str(v) for v in bz if v)}) / {len(H)} = {avg(bz, H, by_type(H, 2, (4, 2)))}, listing "
      f"{by_type(H, 2, (4, 2))}; every H/Cl mix {avg([2 ** len(cycles(m)) for m in H], H, len(orbits(H, 2)))}, listing {len(orbits(H, 2))}")
print(f"mistakes: no division {sum(2 ** len(cycles(m)) for m in T)}, b + w in every slot {sum(fill(m, 2, (2, 2), False) for m in T) / 8},"
      f" half turn as x4 {sum(2 if m == T[2] else 2 ** len(cycles(m)) for m in T) / 8}, halving the necklaces {sum(nk) // len(N) // 2}")
assert all(k ** len(cycles(m)) == sum(1 for p in paints(4, k) if act(m, p) == p) for k in (2, 3) for m in T)
assert sum(inv) == sum(parts(lambda m: 2 ** len(cycles(m))))   # b = w = 1 adds the colour counts back up
print("ALL CHECKS PASS")
