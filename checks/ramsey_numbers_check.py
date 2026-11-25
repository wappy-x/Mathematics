# Ramsey numbers -- the check behind the card.  Nothing is imported.  Radio towers, every pair sharing
# one direct link, high-band or low-band.  A network is a list of bitmasks: bit j of adj[i] is set when
# link i-j uses the high band.  R(3,4) = 9 is reached twice: recursion with parity, and full search.
T, PAIRS = "ABCDEFGHI", [(3, 3), (3, 4), (3, 5), (4, 4), (4, 5), (5, 5)]
def cliques(adj, m, k, lo=0):                # k-sets inside the set m with every link among them in adj
    return 1 if k == 0 else sum(cliques(adj, adj[v] & m, k - 1, v + 1) for v in range(lo, len(adj)) if m >> v & 1)
def other(adj): return [((1 << len(adj)) - 1) ^ a ^ (1 << i) for i, a in enumerate(adj)]
def dodges(adj, s, t): return not cliques(adj, (1 << len(adj)) - 1, s) and not cliques(other(adj), (1 << len(adj)) - 1, t)
def sweep(s, t, top):                        # road two: add one tower at a time, keep every network that dodges
    level, counts = [[]], {}                 # S: the towers the new tower reaches on the high band
    for n in range(1, top + 1):
        level = [[a | (S >> i & 1) << len(adj) for i, a in enumerate(adj)] + [S] for adj in level for S in range(1 << len(adj))
                 if not cliques(adj, S, s - 1) and not cliques(other(adj), ((1 << len(adj)) - 1) & ~S, t - 1)]
        counts[n] = len(level)
    return counts
def labelled(col, n=6):                      # six towers, link number b high-band when bit b of col is set
    P = [(i, j) for i in range(n) for j in range(i + 1, n)]
    return [sum(1 << (x ^ y ^ i) for b, (x, y) in enumerate(P) if i in (x, y) and col >> b & 1) for i in range(n)]
def network(n, gaps): return [sum(1 << j for j in range(n) if (j - i) % n in gaps) for i in range(n)]
def fact(n): return 1 if n < 2 else n * fact(n - 1)
def binom(n, k): return fact(n) // (fact(k) * fact(n - k))    # n choose k from factorials
def rec(s, t): return t if s == 2 else s if t == 2 else rec(s - 1, t) + rec(s, t - 1)
def known(s, t): return {(2, t): t, (s, 2): s, (3, 3): 6, (3, 4): 9, (4, 3): 9, (3, 5): 14, (5, 3): 14,
                         (4, 4): 18, (4, 5): 25, (5, 4): 25}.get((s, t))
e33, e24, e34 = sweep(3, 3, 6), sweep(2, 4, 4), sweep(3, 4, 9)
r33, r24, r34 = (min(n for n in e if e[n] == 0) for e in (e33, e24, e34))   # first size with no escape
brute6 = sum(dodges(labelled(col), 3, 4) for col in range(1 << 15))   # road three: all 15 links of six towers
high = 8 - (r33 - 1); ends = 9 * high        # at most R(3,3) - 1 low-band of 8; high-band link-ends, tower by tower
ring, paley, c13 = network(8, {1, 4, 7}), network(17, {x * x % 17 for x in range(1, 17)}), network(13, {1, 5, 8, 12})
links = [T[i] + "-" + T[j] for i in range(8) for j in range(i + 1, 8) if ring[i] >> j & 1]
chain = [known(s - 1, t) + known(s, t - 1) for s, t in PAIRS]
print(f"nine towers {T}: links C(9,2) = {binom(9, 2)}, band assignments 2^36 = {2 ** 36}")
print(f"search, no high-band trio or low-band trio: 5 towers {e33[5]}, 6 towers {e33[6]}, so R(3,3) = {r33}")
print(f"search, no high-band link or low-band foursome: 3 towers {e24[3]}, 4 towers {e24[4]}, so R(2,4) = {r24}")
print(f"recursion: R(3,4) <= R(2,4) + R(3,3) = {r24} + {r33} = {r24 + r33}")
print(f"nine towers, 8 links each: high-band at most {r24 - 1}, low-band at most {r33 - 1}, so high-band exactly {high}")
print(f"high-band link-ends 9 x {high} = {ends}, odd, but every link has 2 ends: no such network, R(3,4) <= 9")
print("search, no high-band trio or low-band foursome: " + ", ".join(f"{n} towers {e34[n]}" for n in range(6, 10)))
print(f"six towers by brute force over all {2 ** 15} assignments: {brute6} dodge")
print(f"the 8-tower escape, high-band: {', '.join(links)}")
print(f"  high-band trios {cliques(ring, 255, 3)} of {binom(8, 3)}, low-band foursomes {cliques(other(ring), 255, 4)} "
      f"of {binom(8, 4)}, high-band links per tower {[bin(a).count('1') for a in ring]}, so R(3,4) = 9")
print("s,t            " + "".join(f"{s},{t}".rjust(8) for s, t in PAIRS))
print("known R(s,t)   " + "".join(str(known(s, t) or "43..46").rjust(8) for s, t in PAIRS))
print("C(s+t-2, s-1)  " + "".join(str(binom(s + t - 2, s - 1)).rjust(8) for s, t in PAIRS))
print("by recursion   " + "".join(str(rec(s, t)).rjust(8) for s, t in PAIRS))
print("chained known  " + "".join(str(c).rjust(8) for c in chain))
print(f"17 towers, high-band when the gap is a square mod 17: one-band foursomes {cliques(paley, (1 << 17) - 1, 4)}"
      f" + {cliques(other(paley), (1 << 17) - 1, 4)} of {binom(17, 4)}, so R(4,4) > 17")
print(f"13 towers, high-band at gaps 1, 5, 8, 12: high-band trios {cliques(c13, (1 << 13) - 1, 3)}, low-band five-sets "
      f"{cliques(other(c13), (1 << 13) - 1, 5)} of {binom(13, 5)}, so R(3,5) > 13")
print(f"mistake 1, parity step skipped: R(3,4) <= {r24 + r33}; mistake 2, ceiling read as the value: R(5,5) = "
      f"{binom(8, 4)}; mistake 3, only high-band trios counted: an all-low-band network of 9 has {cliques([0] * 9, 511, 3)}")
assert e34[9] == 0 and ends % 2 == 1         # the search and the parity step agree: nine towers never dodge
assert brute6 == e34[6]                      # one-tower-at-a-time search against assigning every link
assert all(binom(s + t - 2, s - 1) == rec(s, t) for s, t in PAIRS)
assert dodges(ring, 3, 4) and dodges(paley, 4, 4) and dodges(c13, 3, 5) and \
    (len(ring) + 1, len(c13) + 1, len(paley) + 1) == (r34, rec(2, 5) + r34, r34 + r34)   # floors meet ceilings
print("ALL CHECKS PASS")
