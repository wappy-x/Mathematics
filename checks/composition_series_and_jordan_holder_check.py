# Composition series and Jordan-Holder -- the check behind the card.  Nothing
# is imported.  Every group is a set of shuffles: Z mod 12 as the 12 turns of a
# 12-hour dial, the square tile's 8 moves on its corners, S4 and S5.  Road one
# lists every composition series by brute force; road two takes commutators.
def mul(p, q): return tuple(p[i] for i in q)                  # do q, then p
def inv(p): return tuple(sorted(range(len(p)), key=lambda i: p[i]))
def perms(n): return [()] if n == 0 else [p[:i] + (n - 1,) + p[i:] for p in perms(n - 1) for i in range(n)]
def primes(n, p=2): return [] if n == 1 else [p] + primes(n // p) if n % p == 0 else primes(n, p + 1)
def factors(c): return [a // b for a, b in zip(c, c[1:])]     # sizes of the steps
def classes(H): return {frozenset(mul(mul(h, x), inv(h)) for h in H) for x in H}
def comm(G): return sum(mul(a, b) == mul(b, a) for a in G for b in G)

def gen(gens, n):                       # the smallest subgroup holding gens
    out = {tuple(range(n))}; todo = list(out)
    while todo:
        x = todo.pop()
        for g in gens:
            y = mul(g, x)
            if y not in out: out.add(y); todo.append(y)
    return frozenset(out)
def normals(H):                         # a normal subgroup is a union of classes
    n, cl = len(next(iter(H))), list(classes(H))
    return {gen(set().union(*(c for i, c in enumerate(cl) if m >> i & 1)), n) for m in range(1 << len(cl))}
memo = {}
def chains(H):                          # road one: every composition series, as sizes
    if len(H) == 1: return [[1]]
    if H not in memo:
        below = [M for M in normals(H) if M != H]
        top = [M for M in below if not any(M < K for K in below)]   # maximal: a simple step
        memo[H] = sorted([len(H)] + c for M in top for c in chains(M))
    return memo[H]

def derived(H):                         # road two: commutators until nothing changes
    n, sizes = len(next(iter(H))), [len(H)]
    while len(H) > 1 and (D := gen({mul(mul(a, b), mul(inv(a), inv(b))) for a in H for b in H}, n)) != H:
        H = D; sizes.append(len(H))
    return sizes

turn = lambda k: tuple((i + 1) % k for i in range(k))
Z12, Z8, tile = gen({turn(12)}, 12), gen({turn(8)}, 8), gen({(1, 2, 3, 0), (0, 3, 2, 1)}, 4)
S4, S5, A4 = frozenset(perms(4)), frozenset(perms(5)), gen({(1, 2, 0, 3), (1, 0, 3, 2)}, 4)
solvable = []
for name, G in [("Z mod 12", Z12), ("square tile", tile), ("S4", S4), ("S5", S5)]:
    cs, ds = chains(G), derived(G); fs = sorted({tuple(sorted(factors(c))) for c in cs})
    prime = all(primes(f) == [f] for c in cs for f in factors(c)); solvable.append(prime)
    print(f"{name}: {len(cs)} series, sizes {sorted(map(list, set(map(tuple, cs))))}, factors {[factors(c) for c in cs][:3]}")
    print(f"  sorted factors {[list(f) for f in fs]}; all prime {'yes' if prime else 'no'}; commutator sizes {ds}")
    assert len(fs) == 1 and prime == (ds[-1] == 1)                          # one multiset; two roads agree
t = turn(12); H, K = gen({mul(t, t)}, 12), gen({mul(t, mul(t, t))}, 12); D = H & K
HK = frozenset(mul(h, k) for h in H for k in K)
print(f"12 by trial division: {primes(12)}; diamond |H| {len(H)}, |K| {len(K)}, |H & K| {len(D)}, |HK| {len(HK)}")
print(f"G/H {12 // len(H)} matches K/D {len(K) // len(D)}; G/K {12 // len(K)} matches H/D {len(H) // len(D)}")
print(f"A5 normal subgroups by size: {sorted(len(N) for N in normals(gen({(1, 2, 3, 4, 0), (1, 2, 0, 3, 4)}, 5)))}")
print(f"mistake 1, stop at S4 > A4 > 1: factors {factors([24, 12, 1])}; A4 alone splits as {factors(chains(A4)[0])}")
print(f"mistake 2, copies of one double swap seen from all of S4: {len({mul(mul(h, (1, 0, 3, 2)), inv(h)) for h in S4})}")
print(f"mistake 3, Z mod 8 factors {factors(chains(Z8)[0])}, commuting pairs {comm(Z8)}; tile {comm(tile)} = 8 x {len(classes(tile))} classes")
assert all(sorted(factors(c)) == primes(12) for c in chains(Z12))           # Jordan-Holder vs 12 = 2 x 2 x 3
assert len(HK) == len(H) * len(K) // len(D) == 12 and 12 // len(H) == len(K) // len(D) and 12 // len(K) == len(H) // len(D)
assert solvable == [True, True, True, False] and len(chains(tile)) == 7 and len(chains(Z12)) == 3 and comm(tile) == 8 * len(classes(tile))
print("ALL CHECKS PASS")
