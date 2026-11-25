# Erdos-Ko-Rado and shadows -- the check behind the card.  itertools lists subsets and orders;
# nothing else is imported.  A k-set is a bit pattern: bit i is on when point i + 1 is in it.
# Road one searches every family, road two is Katona's circle count, and Kruskal-Katona is searched.
from itertools import combinations, permutations
def C(n, k): return 0 if k < 0 or k > n else (1 if k == 0 else C(n - 1, k - 1) * n // k)
def ksets(n, k): return sorted(sum(1 << (p - 1) for p in s) for s in combinations(range(1, n + 1), k))
def best(sets):                    # largest family in which every two meet, and how many reach it
    memo = {}
    def go(left):                  # left: which of the sets are still allowed, as bits
        if left not in memo:
            live = [i for i in range(len(sets)) if left >> i & 1]
            clash = {i: sum(1 << j for j in live if sets[i] & sets[j] == 0) for i in live}
            v = max(live, key=lambda i: clash[i].bit_count(), default=None)
            if v is None or clash[v] == 0: return (len(live), 1)
            s1, c1 = go(left & ~(1 << v))                  # families without set v
            s2, c2 = go(left & ~(1 << v) & ~clash[v]); s2 += 1  # families with set v
            memo[left] = (s1, c1 + c2) if s1 == s2 else max((s1, c1), (s2, c2))
        return memo[left]
    return go((1 << len(sets)) - 1)
def circles(n): return [(1,) + p for p in permutations(range(2, n + 1))]
def arcs(o, k): return [sum(1 << (o[(s + j) % len(o)] - 1) for j in range(k)) for s in range(len(o))]
def stars(n, k, top): return sum(1 for p in range(n) if sum(1 for s in ksets(n, k) if s >> p & 1) == top)
def shadow(fam): return len({s & ~(1 << p) for s in fam for p in range(8) if s >> p & 1})  # (k-1)-sets inside
n, k = 6, 3; fact = lambda m: m * fact(m - 1) if m else 1
S = ksets(n, k); size, count = best(S); star = [s for s in S if s & 1]; pairs = {min(s, 63 - s) for s in S}
two = [s for s in S if (s & 7).bit_count() >= 2]; ok2 = all(a & b for a in two for b in two)
print(f"n = 6, k = 3: {len(S)} three-sets, the star through 1 holds C(5, 2) = {len(star)}")
print(f"largest intersecting family, by search: {size}; families reaching it: {count}; stars among them: {stars(n, k, size)}")
print(f"complementary pairs: {len(pairs)}; one set from each pair, any way: 2^{len(pairs)} = {2 ** len(pairs)}")
print(f"sets holding 2 of 1,2,3: {len(two)}; every two meet: {'yes' if ok2 else 'no'}; "
      f"a point in all: {'yes' if any(all(s >> p & 1 for s in two) for p in range(n)) else 'no'}")
circ = [arcs(o, k) for o in circles(n)]; in_arc = sum(1 for a in circ if 7 in a)
most = max(best(a)[0] for a in circ); star_arcs = sum(1 for a in circ for s in a if s & 1)
print(f"circles of 6: {len(circ)}; circles where 1,2,3 is an arc: {in_arc} = 3! x 3!")
print(f"most arcs of one circle that pairwise meet: {most} of {n}")
print(f"Katona: |F| x {in_arc} <= {most} x {len(circ)} = {most * len(circ)}, so |F| <= {most * len(circ) // in_arc}")
print(f"arcs from the star, over all {len(circ)} circles: {star_arcs}")
s7, c7 = best(ksets(7, 3)); s5 = best(ksets(5, 3))[0]; m5 = best(arcs(circles(5)[0], 3))[0]; s4, c4 = best(ksets(4, 2))
print(f"n = 7, k = 3: bound C(6, 2) = {C(6, 2)}; search: {s7}; families reaching it: {c7}; stars: {stars(7, 3, s7)}")
print(f"n = 5, k = 3: largest intersecting family {s5}; bound C(4, 2) = {C(4, 2)} fails; arcs of one circle meeting: {m5} of 5")
print(f"n = 4, k = 2 (pairs of 4): largest intersecting family of pairs {s4} = C(3, 1); families reaching it: {c4}; stars: {stars(4, 2, s4)}")
print(f"shadow of the star through 1: {shadow(star)} pairs; of the first 10 in colex: {shadow(S[:10])} pairs")
low, u = [99] * 21, [0] * (1 << 20)                  # u[f]: the shadow of family f, as bits
sh = [sum(1 << (s & ~(1 << p)) for p in range(n) if s >> p & 1) for s in S]
for f in range(1, 1 << 20):
    u[f] = u[f & (f - 1)] | sh[(f & -f).bit_length() - 1]
    low[f.bit_count()] = min(low[f.bit_count()], u[f].bit_count())
def kk(m, j):                      # write m greedily as C(a, j) + C(b, j - 1) + ..., lower each j by one
    if m == 0 or j == 0: return 0
    a = max(a for a in range(j, 40) if C(a, j) <= m)
    return C(a, j - 1) + kk(m - C(a, j), j - 1)
print(f"smallest shadow, search,  m = 1..20: {low[1:]}")
print(f"Kruskal-Katona formula,   m = 1..20: {[kk(m, 3) for m in range(1, 21)]}")
print(f"first m sets in colex,    m = 1..20: {[shadow(S[:m]) for m in range(1, 21)]}")
print(f"m = 7 = C(4, 3) + C(3, 2): smallest shadow C(4, 2) + C(3, 1) = {C(4, 2) + C(3, 1)}")
assert size == len(star) == most * len(circ) // in_arc and count == 2 ** len(pairs) and ok2
assert len(circ) == fact(n - 1) and in_arc == fact(k) * fact(n - k) and in_arc * len(S) == len(circ) * n and star_arcs == most * len(circ)  # (n-1)!, k!(n-k)!, double counting
assert (s7, c7) == (C(6, 2), stars(7, 3, s7)) and s5 == len(ksets(5, 3)) and m5 == 5 and (s4, c4) == (C(3, 1), 2 ** 3)
assert low[1:] == [kk(m, 3) for m in range(1, 21)] == [shadow(S[:m]) for m in range(1, 21)]
print("ALL CHECKS PASS")
