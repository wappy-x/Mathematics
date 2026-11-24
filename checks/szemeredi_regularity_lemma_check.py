# The regularity lemma -- the check behind the card.  Nothing is imported.  A pair of
# parts is one bitmask per vertex of A: bit j is set when it links to b(j+1).  Road one
# tries every sub-pair X, Y; road two fixes Y and sorts A by links into Y, since the
# densest X of each size takes the top of that list and the sparsest the bottom.
seed = [2026]
def key():                               # a 64-bit linear congruential generator
    seed[0] = (seed[0] * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return seed[0]
def rand(n):                             # exactly half the n x n pairs: those with the smallest keys
    keys, nb = [key() for _ in range(n * n)], [0] * n
    for i in sorted(range(n * n), key=keys.__getitem__)[:n * n // 2]: nb[i // n] |= 1 << i % n
    return nb
def blocks(n): return [(2 ** (n // 2) - 1) << (n // 2 if a >= n // 2 else 0) for a in range(n)]
def dens(nb): return sum(v.bit_count() for v in nb) / len(nb) ** 2
def sets(n, m): return [Y for Y in range(1, 2 ** n) if Y.bit_count() >= m]
def brute(nb, n, m):                     # road one: every X and every Y with at least m vertices
    return max(abs(sum((nb[a] & Y).bit_count() for a in range(n) if X >> a & 1)
                   / X.bit_count() / Y.bit_count() - dens(nb)) for X in sets(n, m) for Y in sets(n, m))
def greedy(nb, n, m):                    # road two: for each Y, only the top and bottom s of A
    d, worst = dens(nb), 0.0
    for Y in sets(n, m):
        deg, t = sorted((v & Y).bit_count() for v in nb), Y.bit_count()
        for s in range(m, n + 1):
            worst = max(worst, sum(deg[-s:]) / s / t - d, d - sum(deg[:s]) / s / t)
    return worst
def eps_star(nb, n):                     # smallest eps the pair passes, with sides >= eps x n
    return min(max(g, (m - 1) / n) for m in range(1, n + 1) for g in [greedy(nb, n, m)] if g <= m / n)
def energy(parts, nb, n):                # sum over pairs of parts of |P||Q| d(P,Q)^2 / n^2
    return sum(len(P) * len(Q) * (sum(nb[p] >> q & 1 for p in P for q in Q) / len(P) / len(Q)) ** 2
               for P in parts[0] for Q in parts[1]) / n / n
def triangles(xy, yz, xz, n):            # x-y linked, then count z linked to both
    return sum((yz[y] & xz[x]).bit_count() for x in range(n) for y in range(n) if xy[x] >> y & 1)
b4, r16 = blocks(4), rand(16)
br2, gr2, gr1, gr3, es = brute(b4, 4, 2), greedy(b4, 4, 2), greedy(b4, 4, 1), greedy(b4, 4, 3), eps_star(b4, 4)
b16g, r16g, r16g1 = greedy(blocks(16), 16, 8), greedy(r16, 16, 8), greedy(r16, 16, 1)
whole, halves = [[[0, 1, 2, 3]], [[0, 1, 2, 3]]], [[[0, 1], [2, 3]], [[0, 1], [2, 3]]]
e1, e2 = energy(whole, b4, 8), energy(halves, b4, 8)
sq = sum(4 * (sum(b4[p] >> q & 1 for p in P for q in Q) / 4 - 0.5) ** 2 for P in halves[0] for Q in halves[1]) / 64
promised = 0.5 ** 4 * 16 / 64
same, opp = blocks(16), [2 ** 16 - 1 - v for v in blocks(16)]
t_rand, t_block = triangles(rand(16), rand(16), rand(16), 16), triangles(same, same, opp, 16)
print(f"pair A-B, 4 + 4 vertices: {dens(b4) * 16:.0f} of 16 links, density {dens(b4):.3f}")
print(f"halves a1,a2 and b1,b2: {(b4[0] & 3).bit_count() * 2} of 4 links, density {dens([b4[0] & 3, b4[1] & 3]):.3f}, gap {dens([b4[0] & 3, b4[1] & 3]) - 0.5:.3f}")
print(f"worst gap, sides >= 2: {br2:.3f} over all 121 such sub-pairs, {gr2:.3f} by sorting")
print(f"worst gap, sides >= 1: {gr1:.3f}; sides >= 3: {gr3:.3f}")
print(f"smallest eps that makes the pair eps-regular: {es:.3f}")
print(f"16 + 16, worst gap on sides >= 8: blocks {b16g:.3f}, random {r16g:.3f}")
print(f"energy: parts A, B {e1:.4f}; halves {e2:.4f}; gain {e2 - e1:.4f}")
print(f"gain from squared gaps {sq:.4f}; promised at least (1/2)^4 x 16/64 = {promised:.4f}")
print(f"three parts of 16, density 0.5 each: product rule 0.5^3 x 16^3 = {0.5 ** 3 * 16 ** 3:.0f} triangles")
print(f"random links: {t_rand} triangles; blocks, X-Z opposite halves: {t_block}")
print(f"mistake 1, whole-pair density only: blocks {dens(blocks(16)):.3f}, random {dens(r16):.3f}")
print(f"mistake 2, single vertices allowed: random pair's worst gap {r16g1:.3f}")
assert br2 == gr2 == 0.5 and gr1 == 0.5 and abs(gr3 - 1 / 18) < 1e-12  # two roads agree, by hand 1/18
assert abs(brute(b4, 4, 3) - 1 / 18) < 1e-12 and all(abs(brute(c, 5, m) - greedy(c, 5, m)) < 1e-12 for c in [[v & 31 for v in r16[:5]]] for m in range(1, 6))
assert es == 0.5 and b16g == 0.5 and r16g < 0.4                        # blocks fail, random does better
assert abs((e2 - e1) - sq) < 1e-12 and e2 - e1 >= promised              # energy rises by the squared gaps
assert t_block == 0 and abs(t_rand - 512) < 128                         # density alone does not count triangles
print("ALL CHECKS PASS")
