# Conjugacy and the class equation -- the check behind the card.  Nothing is imported.  A group is
# its members and a rule combining two, b first.  Tile move r_k sends position i to i + k, r_kf to
# k - i, wrapped at 4.  Road one conjugates; road two counts what commutes (orbit-stabiliser).
perm = lambda a, b: tuple(a[i] for i in b)
TILE = [tuple((s * i + k) % 4 for i in range(4)) for s in (1, -1) for k in range(4)]
NAME = dict(zip(TILE, ["r0", "r1", "r2", "r3", "r0f", "r1f", "r2f", "r3f"]))
S3 = [(a, b, 3 - a - b) for a in range(3) for b in range(3) if a != b]
HEIS = [(a, b, c) for a in range(3) for b in range(3) for c in range(3)]
heis = lambda u, v: ((u[0] + v[0]) % 3, (u[1] + v[1]) % 3, (u[2] + v[2] + u[0] * v[1]) % 3)

def undo(G, mul):                             # the do-nothing member, and every undo
    e = next(x for x in G if all(mul(x, y) == y for y in G))
    return e, {x: next(y for y in G if mul(x, y) == e) for x in G}
def conj(G, mul, g, xs): return sorted({mul(mul(g, x), undo(G, mul)[1][g]) for x in xs}, key=G.index)
def classes(G, mul):                          # road one: every g x g^-1, deduplicated
    cs = {tuple(sorted({conj(G, mul, g, [x])[0] for g in G}, key=G.index)) for x in G}
    return sorted(cs, key=lambda c: (len(c), G.index(c[0])))
def cent(G, mul, x): return [g for g in G if mul(g, x) == mul(x, g)]   # road two
def centre(G, mul): return [z for z in G if len(cent(G, mul, z)) == len(G)]
def upper(G, mul):                            # sizes of Z0 = {e}, Z1 = centre, Z2, ...
    e, inv = undo(G, mul); Z = [e]; sizes = [1]
    while True:
        Z2 = [g for g in G if all(mul(mul(g, x), mul(inv[g], inv[x])) in Z for x in G)]
        if len(Z2) == len(Z): return sizes
        Z = Z2; sizes.append(len(Z))
def derived(H, mul, inv):                     # all commutators, closed under combining
    S = {mul(mul(a, b), mul(inv[a], inv[b])) for a in H for b in H}
    while (T := S | {mul(a, b) for a in S for b in S}) != S: S = T
    return list(S)
def show(c): return "{" + " ".join(NAME[x] for x in c) + "}"
cl, Z = classes(TILE, perm), centre(TILE, perm)
by_cent = [8 // len(cent(TILE, perm, c[0])) for c in cl]
print("classes by conjugating:", " ".join(show(c) for c in cl))
print("class sizes:", [len(c) for c in cl], "| 8 / centraliser size:", by_cent)
print("centralisers:", "; ".join(f"{NAME[c[0]]} {show(cent(TILE, perm, c[0]))}" for c in cl[2:]))
big = [len(c) for c in cl if len(c) > 1]
print(f"centre, commuting with all 8: {show(Z)}; class equation 8 = {len(Z)} + "
      + " + ".join(map(str, big)))
H = [TILE[0], TILE[4]]
norm = [g for g in TILE if conj(TILE, perm, g, H) == H]
subs = sorted({tuple(conj(TILE, perm, g, H)) for g in TILE})
print(f"normaliser of {show(H)}: {show(norm)}; 8 / {len(norm)} = {8 // len(norm)} "
      f"conjugate subgroups:", " ".join(show(c) for c in subs))
for nm, G, mul in [("S3", S3, perm), ("order 27", HEIS, heis)]:
    sz = [len(c) for c in classes(G, mul)]; k = sz.count(1)
    print(f"{nm}: {len(G)} = {' + '.join(map(str, [k] + sz[k:]))}; centre {len(centre(G, mul))}")
_, i3 = undo(S3, perm); A3 = derived(S3, perm, i3)
print("upper central series sizes: tile", upper(TILE, perm), "| S3", upper(S3, perm),
      "| order 27", upper(HEIS, heis))
print(f"S3 solvable: its commutators make a subgroup of {len(A3)}, theirs of {len(derived(A3, perm, i3))}")
turns = len({tuple(sorted({conj(TILE, perm, g, [x])[0] for g in TILE[:4]})) for x in TILE})
print(f"mistakes: 8 / 5 classes = {8 / 5}; conjugating by turns only gives {turns} classes; "
      f"centre as one term 1 + {sum(big)} = {1 + sum(big)}; centralisers added = "
      f"{sum(len(cent(TILE, perm, c[0])) for c in cl)}")
assert [len(c) for c in cl] == by_cent and sum(by_cent) == 8   # two roads, one count
assert sorted(Z) == sorted(c[0] for c in cl if len(c) == 1) and len(Z) == 2
assert len(centre(HEIS, heis)) == 3 and len(centre(S3, perm)) == 1
assert upper(TILE, perm)[-1] == 8 and upper(HEIS, heis) == [1, 3, 27] and upper(S3, perm) == [1]
assert len(norm) * len(subs) == 8 and len(A3) == 3
print("ALL CHECKS PASS")
