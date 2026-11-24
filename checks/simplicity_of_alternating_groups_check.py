# A_n is simple for n at least 5 -- the check behind the card.  Nothing is
# imported.  A shuffle of n places is a tuple p: place i+1 goes to place p[i]+1.
# Road one adds up class sizes; road two builds each normal subgroup by brute force.
SIZES, PAIRS, res = (4, 5, 6), [((1, 2, 3, 4, 5), (1, 2, 4)), ((1, 2, 3, 4, 5, 6, 7), (1, 2, 4))], {}
def mul(p, q): return tuple(p[i] for i in q)                 # q first, then p
def inv(p): return tuple(sorted(range(len(p)), key=lambda i: p[i]))
def conj(g, x): return mul(mul(g, x), inv(g))                # undo g, do x, redo g
def comm(t, x): return mul(conj(t, x), inv(x))               # Step 3: t x t^-1 x^-1
def moved(p): return sum(p[i] != i for i in range(len(p)))
def cyc(n, *c): return tuple(c[(c.index(i + 1) + 1) % len(c)] - 1 if i + 1 in c else i for i in range(n))
def orbit(p, i, c=()): return c if i in c else orbit(p, p[i], c + (i,))
def show(p):                                                 # cycle notation from 1
    cs = [orbit(p, i) for i in range(len(p)) if p[i] != i and i == min(orbit(p, i))]
    return "".join("(" + " ".join(str(x + 1) for x in c) + ")" for c in cs) or "e"
def shuffles(n): return [()] if n == 0 else [s[:j] + (n - 1,) + s[j:] for s in shuffles(n - 1) for j in range(n)]
def even(p): return sum(p[j] > p[i] for i in range(len(p)) for j in range(i)) % 2 == 0
def classes(G):                                              # look-alike classes
    out, seen = [], set()
    for x in G:
        if x not in seen: c = {conj(g, x) for g in G}; seen |= c; out.append(c)
    return sorted(out, key=len)
def build(gens, n):                                          # every product of gens
    grp = {tuple(range(n))}; edge = list(grp)
    while edge: edge = [y for y in {mul(g, x) for x in edge for g in gens} if y not in grp]; grp |= set(edge)
    return grp
def unions(sizes, order):                                    # sums of classes; those dividing
    tot = {sizes[0] + sum(x for i, x in enumerate(sizes[1:]) if m >> i & 1) for m in range(1 << len(sizes) - 1)}
    return sorted(t for t in tot if t), [t for t in sorted(tot) if t and order % t == 0]
for n in SIZES:
    G = [p for p in shuffles(n) if even(p)]; cl = classes(G); sz = [len(c) for c in cl]
    res[n] = (G, sz, unions(sz, len(G))[1], [len(build(c, n)) for c in cl])
    print(f"A_{n}: {len(G)} members; class sizes {sz}; unions of classes dividing {len(G)}: {res[n][2]}")
    print(f"A_{n}: normal subgroup built from one class at a time, sizes {res[n][3]}")
A4, A5, S5, s = res[4][0], res[5][0], shuffles(5), lambda *c: cyc(5, *c); threes = [p for p in A5 if moved(p) == 3]
print(f"A_5 unions that hold do-nothing: {unions(res[5][1], 60)[0]}")
print(f"mistake 1, do-nothing left out: unions dividing 60 are {unions([0] + res[5][1][1:], 60)[1]}")
print(f"A_5 has {len(threes)} 3-cycles; the subgroup they build has {len(build(threes, 5))} members")
swaps = mul(s(1, 2), s(1, 3)) == s(1, 3, 2) and mul(s(1, 2), s(3, 4)) == mul(s(1, 3, 2), s(1, 3, 4))
print(f"(1 2)(1 3) = (1 3 2) and (1 2)(3 4) = (1 3 2)(1 3 4): {'yes' if swaps else 'no'}")
k5, k4 = len({conj(g, s(1, 2, 3)) for g in A5}), len({conj(g, cyc(4, 1, 2, 3)) for g in A4})
print(f"class of (1 2 3): {k5} members in A_5; {k4} of the 8 3-cycles in A_4")
look = [(len({conj(g, x) for g in S5}), [g for g in S5 if mul(g, x) == mul(x, g)]) for x in (s(1, 2, 3), mul(s(1, 2), s(3, 4)), s(1, 2, 3, 4, 5))]
shape, cent, odds = [k for k, c in look], [len(c) for k, c in look], [sum(not even(g) for g in c) for k, c in look]
print(f"in all {len(S5)} shuffles: (1 2 3), (1 2)(3 4), (1 2 3 4 5) have {shape} look-alikes; {cent} commute with each, {odds} of them odd")
for sig, tau in PAIRS:
    n = len(sig); sg, t = cyc(n, *sig), cyc(n, *tau); rho = comm(t, sg)
    print(f"sigma {show(sg)}, tau {show(t)}: rho = {show(rho)}, moving {moved(rho)} of {n} places")
    assert show(rho) == "(1 2 5 3 4)"                                # traced by hand
rhos = [comm(cyc(6, a + 1, g[a] + 1, c + 1), g) for g in res[6][0] for a in range(6) if g[a] != a for c in range(6) if c not in (a, g[a], g[g[a]])]
print(f"Step 3 on all of A_6, every allowed a and c: {len(rhos)} commutators, each moving {min(map(moved, rhos))} to {max(map(moved, rhos))} places")
v = mul(cyc(4, 1, 2), cyc(4, 3, 4)); r4, V = comm(cyc(4, 1, 2, 3), v), build([conj(g, v) for g in A4], 4)
print(f"A_4: sigma {show(v)}, tau (1 2 3): rho = {show(r4)}; the class of sigma builds {len(V)} members, {sum(moved(p) == 3 for p in V)} of them 3-cycles")
H = [p for p in A5 if p[4] == 4]; copies = {frozenset(conj(g, h) for h in H) for g in A5}
print(f"even shuffles fixing place 5: {len(H)}, a subgroup with {len(copies)} different conjugates")
assert res[5][1] == [1, 12, 12, 15, 20] and res[5][2] == [1, 60] and res[6][2] == [1, 360] and show(r4) == "(1 3)(2 4)"
assert res[5][3][1:] == [60] * 4 and res[6][3][1:] == [360] * 6 and min(map(moved, rhos)) > 0 and max(map(moved, rhos)) <= 5
assert res[4][2] == [1, 4, 12] and res[4][3] == [1, 4, 12, 12] and len(V) == 4 and r4 in V    # A_4 has its normal 4
assert sorted([1] + [k // 2 if o == 0 else k for k, o in zip(shape, odds) for _ in range(1 + (o == 0))]) == res[5][1]  # halving rule
assert all(k * c == len(S5) for k, c in zip(shape, cent)) and build(threes, 5) == set(A5) and k5 == len(threes) == 20 and k4 == 4 and swaps and len(copies) == 5
print("ALL CHECKS PASS")
