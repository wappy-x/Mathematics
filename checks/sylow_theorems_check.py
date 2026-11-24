# The Sylow theorems -- the check behind the card.  Nothing is imported.
# The rules (n_p is 1 more than a multiple of p and divides the rest) are set
# against brute force: every subgroup of S4 (shuffle s sends corner i to s[i]),
# every member of a 15-dial, and the 21 maps x -> a x + b on the 7-dial.
def perms(xs):
    return [()] if not xs else [(x,) + q for x in xs for q in perms([y for y in xs if y != x])]
def mul(a, b): return tuple(a[i] for i in b)                 # b first, then a
def inv(a): return tuple(sorted(range(4), key=lambda i: a[i]))
def conj(g, H): return frozenset(mul(mul(g, h), inv(g)) for h in H)
def span(gens):                                              # close under combining
    S = set(gens) | {E}
    while (T := S | {mul(x, y) for x in S for y in S}) != S: S = T
    return frozenset(S)
def split(n, p):                                             # n = p^a x m, p not dividing m
    return (0, n) if n % p else (lambda a, m: (a + 1, m))(*split(n // p, p))
def allowed(n, p):                                           # what the counting rules leave
    m = split(n, p)[1]
    return [d for d in range(1, m + 1) if m % d == 0 and d % p == 1]
def choose(n, k): return 1 if k == 0 else choose(n, k - 1) * (n - k + 1) // k
G, E = perms([0, 1, 2, 3]), (0, 1, 2, 3)
subs = {span([a, b]) for a in G for b in G}                  # each subgroup of S4 has two makers
def of_size(k): return [H for H in subs if len(H) == k]
tile = span([(1, 2, 3, 0), (0, 3, 2, 1)])                    # quarter turn and flip of the tile
C3 = span([(0, 2, 3, 1)])                                    # corner 0 still, 1 -> 2 -> 3 -> 1
order15 = [k for k in range(15) if all(j * k % 15 for j in range(1, 15))]
known = 1 + (3 - 1) * (n3 := allowed(15, 3)[0]) + (5 - 1) * (n5 := allowed(15, 5)[0])
print(f"order 15 = 3 x 5: n_3 may be {allowed(15, 3)}, n_5 may be {allowed(15, 5)}")
print(f"order 15: 1 identity + {(3 - 1) * n3} of order 3 + {(5 - 1) * n5} of order 5 = {known}; left over {15 - known}")
print(f"members of order 15 on a 15-dial, by brute force: {len(order15)}")
forced = [p * q for p in range(2, 60) for q in range(p + 1, 60) if all(p % d for d in range(2, p)) and all(q % d for d in range(2, q)) and p * q < 60 and allowed(p * q, p) == allowed(p * q, q) == [1]]
print(f"orders p x q under 60 where both counts are forced to 1: {sorted(forced)}")
print(f"order 24 = 2^3 x 3: n_2 may be {allowed(24, 2)}, n_3 may be {allowed(24, 3)}")
print(f"S4 by brute force: {len(subs)} subgroups; size 8: {len(of_size(8))}; size 3: {len(of_size(3))}")
cT, c3 = {conj(g, tile) for g in G}, {conj(g, C3) for g in G}
NT, N3 = [g for g in G if conj(g, tile) == tile], [g for g in G if conj(g, C3) == C3]
orbs = sorted(len(O) for O in {frozenset(conj(t, Q) for t in tile) for Q in cT})
print(f"conjugates of the tile's 8 ways: {len(cT)}, which the tile's ways sort into orbits of sizes {orbs}; of one size-3 subgroup: {len(c3)}")
print(f"normalisers: sizes {len(NT)} and {len(N3)}, so 24 / {len(NT)} = {24 // len(NT)} and 24 / {len(N3)} = {24 // len(N3)}")
print(f"the tile's 8 ways are one of the size-8 subgroups: {'yes' if tile in subs else 'no'}")
for n, p in [(24, 2), (15, 3), (15, 5)]:
    (a, m), c = split(n, p), choose(n, p ** split(n, p)[0])
    print(f"subsets of size {p ** a} from {n}: C({n}, {p ** a}) = {c}, leaves {c % p} on dividing by {p}; m = {m} leaves {m % p}")
print(f"mistake 1, divides only: n_3 for order 15 may be {[d for d in range(1, 6) if 5 % d == 0]}")
classes = {frozenset(conj(g, H) for g in G) for H in of_size(4)}
print(f"mistake 2, size 4 is not the largest power of 2: {len(of_size(4))} subgroups in {len(classes)} conjugacy classes")
even = {s for s in G if sum(s[i] > s[j] for i in range(4) for j in range(i + 1, 4)) % 2 == 0}
print(f"mistake 3, A4 has order 12 but size-6 subgroups: {len([H for H in of_size(6) if H <= even])}")
def order(f):                                                # f = (a, b) is x -> a x + b mod 7
    k, g = 1, f
    while g != (1, 0): k, g = k + 1, (f[0] * g[0] % 7, (f[0] * g[1] + f[1]) % 7)
    return k
ords = [order((a, b)) for a in (1, 2, 4) for b in range(7)]
print(f"mistake 4, order 21: n_3 may be {allowed(21, 3)}; the 21 maps x -> a x + b mod 7 have {ords.count(3) // 2} size-3 subgroups, largest order {max(ords)}")
assert allowed(15, 3) == allowed(15, 5) == [1] and len(order15) == 15 - known
assert len(of_size(8)) == len(cT) == 24 // len(NT) and len(of_size(8)) in allowed(24, 2)
assert len(of_size(3)) == len(c3) == 24 // len(N3) and len(of_size(3)) in allowed(24, 3)
assert orbs == [1, 2] and len(subs) == 30 and set(of_size(8)) == cT and set(of_size(3)) == c3
assert all(choose(n, p ** split(n, p)[0]) % p == split(n, p)[1] % p for n, p in [(24, 2), (15, 3), (15, 5)])
assert ords.count(3) // 2 in allowed(21, 3) and max(ords) < 21 and sorted(forced) == [15, 33, 35, 51]
print("ALL CHECKS PASS")
