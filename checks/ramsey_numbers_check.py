# Ramsey numbers -- the check behind the card.  Nothing is imported.  Towns, every pair joined by one
# road, paved or gravel.  A county is a list of bitmasks: bit j of paved[i] is set when road i-j is paved.
# R(3,4) = 9 is reached twice: by the recursion with its parity step, and by searching every county.
T, PAIRS = "ABCDEFGHI", [(3, 3), (3, 4), (3, 5), (4, 4), (4, 5), (5, 5)]
def cliques(adj, m, k, lo=0):                # k-sets inside the set m with every road among them in adj
    return 1 if k == 0 else sum(cliques(adj, adj[v] & m, k - 1, v + 1) for v in range(lo, len(adj)) if m >> v & 1)
def other(adj): return [((1 << len(adj)) - 1) ^ a ^ (1 << i) for i, a in enumerate(adj)]
def dodges(adj, s, t): return not cliques(adj, (1 << len(adj)) - 1, s) and not cliques(other(adj), (1 << len(adj)) - 1, t)
def sweep(s, t, top):                        # road two: add one town at a time, keep every county that dodges
    level, counts = [[]], {}                 # S: the towns the new town reaches by paved road
    for n in range(1, top + 1):
        level = [[a | (S >> i & 1) << len(adj) for i, a in enumerate(adj)] + [S] for adj in level for S in range(1 << len(adj))
                 if not cliques(adj, S, s - 1) and not cliques(other(adj), ((1 << len(adj)) - 1) & ~S, t - 1)]
        counts[n] = len(level)
    return counts
def labelled(col, n=6):                      # six towns, road number b paved when bit b of col is set
    P = [(i, j) for i in range(n) for j in range(i + 1, n)]
    return [sum(1 << (x ^ y ^ i) for b, (x, y) in enumerate(P) if i in (x, y) and col >> b & 1) for i in range(n)]
def county(n, gaps): return [sum(1 << j for j in range(n) if (j - i) % n in gaps) for i in range(n)]
def fact(n): return 1 if n < 2 else n * fact(n - 1)
def binom(n, k): return fact(n) // (fact(k) * fact(n - k))    # n choose k from factorials
def rec(s, t): return t if s == 2 else s if t == 2 else rec(s - 1, t) + rec(s, t - 1)
def known(s, t): return {(2, t): t, (s, 2): s, (3, 3): 6, (3, 4): 9, (4, 3): 9, (3, 5): 14, (5, 3): 14,
                         (4, 4): 18, (4, 5): 25, (5, 4): 25}.get((s, t))
e33, e24, e34 = sweep(3, 3, 6), sweep(2, 4, 4), sweep(3, 4, 9)
r33, r24, r34 = (min(n for n in e if e[n] == 0) for e in (e33, e24, e34))   # first size with no escape
brute6 = sum(dodges(labelled(col), 3, 4) for col in range(1 << 15))   # road three: all 15 roads of six towns
paved = 8 - (r33 - 1); ends = 9 * paved     # at most R(3,3) - 1 gravel of 8; paved road-ends, town by town
ring, paley, c13 = county(8, {1, 4, 7}), county(17, {x * x % 17 for x in range(1, 17)}), county(13, {1, 5, 8, 12})
roads = [T[i] + "-" + T[j] for i in range(8) for j in range(i + 1, 8) if ring[i] >> j & 1]
chain = [known(s - 1, t) + known(s, t - 1) for s, t in PAIRS]
print(f"nine towns {T}: roads C(9,2) = {binom(9, 2)}, ways to surface them 2^36 = {2 ** 36}")
print(f"search, no paved trio or gravel trio: 5 towns {e33[5]}, 6 towns {e33[6]}, so R(3,3) = {r33}")
print(f"search, no paved road or gravel foursome: 3 towns {e24[3]}, 4 towns {e24[4]}, so R(2,4) = {r24}")
print(f"recursion: R(3,4) <= R(2,4) + R(3,3) = {r24} + {r33} = {r24 + r33}")
print(f"nine towns, 8 roads each: paved at most {r24 - 1}, gravel at most {r33 - 1}, so paved exactly {paved}")
print(f"paved road-ends 9 x {paved} = {ends}, odd, but every road has 2 ends: no such county, R(3,4) <= 9")
print("search, no paved trio or gravel foursome: " + ", ".join(f"{n} towns {e34[n]}" for n in range(6, 10)))
print(f"six towns by brute force over all {2 ** 15} labellings: {brute6} dodge")
print(f"the 8-town escape, paved: {', '.join(roads)}")
print(f"  paved trios {cliques(ring, 255, 3)} of {binom(8, 3)}, gravel foursomes {cliques(other(ring), 255, 4)} "
      f"of {binom(8, 4)}, paved roads per town {[bin(a).count('1') for a in ring]}, so R(3,4) = 9")
print("s,t            " + "".join(f"{s},{t}".rjust(8) for s, t in PAIRS))
print("known R(s,t)   " + "".join(str(known(s, t) or "43..46").rjust(8) for s, t in PAIRS))
print("C(s+t-2, s-1)  " + "".join(str(binom(s + t - 2, s - 1)).rjust(8) for s, t in PAIRS))
print("by recursion   " + "".join(str(rec(s, t)).rjust(8) for s, t in PAIRS))
print("chained known  " + "".join(str(c).rjust(8) for c in chain))
print(f"17 towns, paved when the gap is a square mod 17: one-colour foursomes {cliques(paley, (1 << 17) - 1, 4)}"
      f" + {cliques(other(paley), (1 << 17) - 1, 4)} of {binom(17, 4)}, so R(4,4) > 17")
print(f"13 towns, paved at gaps 1, 5, 8, 12: paved trios {cliques(c13, (1 << 13) - 1, 3)}, gravel five-sets "
      f"{cliques(other(c13), (1 << 13) - 1, 5)} of {binom(13, 5)}, so R(3,5) > 13")
print(f"mistake 1, parity step skipped: R(3,4) <= {r24 + r33}; mistake 2, ceiling read as the value: R(5,5) = "
      f"{binom(8, 4)}; mistake 3, only paved trios counted: an all-gravel county of 9 has {cliques([0] * 9, 511, 3)}")
assert e34[9] == 0 and ends % 2 == 1         # the search and the parity step agree: nine towns never dodge
assert brute6 == e34[6]                      # one-town-at-a-time search against labelling every road
assert all(binom(s + t - 2, s - 1) == rec(s, t) for s, t in PAIRS)
assert dodges(ring, 3, 4) and dodges(paley, 4, 4) and dodges(c13, 3, 5) and \
    (len(ring) + 1, len(c13) + 1, len(paley) + 1) == (r34, rec(2, 5) + r34, r34 + r34)   # floors meet ceilings
print("ALL CHECKS PASS")
