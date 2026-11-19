# Sum-product and additive energy -- the check behind the card.  Nothing is
# imported.  A geometric run 1, 2, 4, ..., 512 and the arithmetic
# run 1 to 10: sumsets, product sets and additive energy, each counted two ways,
# the energy bound |A+A| >= |A|^4 / E checked, and every 6-number set drawn
# from 1 to 24 searched for the one smallest at adding and multiplying at once.
def sums(A, B): return {a + b for a in A for b in B}
def prods(A, B): return {a * b for a in A for b in B}

def energy_brute(A):                     # road one: every quadruple a + b = c + d
    return sum(1 for a in A for b in A for c in A for d in A if a + b == c + d)

def energy_by_r(A, op):                  # road two: add up r(s)^2, r(s) = ways to make s
    r = {}
    for a in A:
        for b in A:
            s = op(a, b)
            r[s] = r.get(s, 0) + 1
    return sum(v * v for v in r.values())

def products_by_divisors(n):             # 1..n times 1..n, without building the set
    return sum(1 for m in range(1, n * n + 1)
               if any(m % d == 0 and m // d <= n for d in range(1, n + 1)))

def ceil_log2(n):                        # the smallest whole k with 2^k >= n
    k = 0
    while 2 ** k < n: k += 1
    return k

def subsets(pool, k):                    # every k-number subset, smallest first
    if k == 0: yield (); return
    for i in range(len(pool) - k + 1):
        for rest in subsets(pool[i + 1:], k - 1): yield (pool[i],) + rest

def bar(v): return "#" * v
def yn(c): return "yes" if c else "no"

G = [2 ** i for i in range(10)]          # the geometric run
P = list(range(1, 11))                   # the arithmetic run
M = [1, 2, 3, 4, 6, 8]                   # the search's winner, found below
n = len(G)
rows = []
for name, A in (("geometric 1..512", G), ("arithmetic 1..10", P), ("mixed 1,2,3,4,6,8", M)):
    s, p = len(sums(A, A)), len(prods(A, A))
    e1, e2 = energy_brute(A), energy_by_r(A, lambda a, b: a + b)
    ex = energy_by_r(A, lambda a, b: a * b)
    m = len(A)
    rows.append((name, m, s, p, e1, e2, ex))
    print(f"{name}: |A| {m}, |A+A| {s}, |A.A| {p}, E+ {e1} (by r(s)^2: {e2}), Ex {ex}")
    print(f"  energy bound |A|^4/E+ = {m ** 4}/{e1} = {m ** 4 / e1:.1f} <= |A+A| {s}: {yn(m ** 4 / e1 <= s)}")
    lhs, rhs = p * s * s, m ** 4 / (4 * ceil_log2(m))
    print(f"  Solymosi: |A.A| |A+A|^2 = {lhs} >= |A|^4/(4 ceil(log2|A|)) = {rhs:.1f}: {yn(lhs >= rhs)}")
g, ar = rows[0], rows[1]
print(f"closed forms, n = {n}: n(n+1)/2 = {n * (n + 1) // 2}, 2n - 1 = {2 * n - 1}, "
      f"2n^2 - n = {2 * n * n - n}, (2n^3 + n)/3 = {(2 * n ** 3 + n) // 3}")
print(f"ordered pairs (a, b): {n * n}; unordered with a <= b: {n * (n + 1) // 2}")
r = {}
for x in G:
    for y in G: r[x + y] = r.get(x + y, 0) + 1
c2, c1 = sum(1 for v in r.values() if v == 2), sum(1 for v in r.values() if v == 1)
print(f"geometric run: products 1 to 2^{max(prods(G, G)).bit_length() - 1}; sums made by 2 ordered "
      f"pairs {c2}, by 1 pair {c1}; r(3) = {r.get(3, 0)}")
print(f"arithmetic run: sums run {min(sums(P, P))} to {max(sums(P, P))}; ceil(log2 10) = {ceil_log2(10)}")
print("picture: sizes of A+A and A.A")
for name, _, s, p, *_ in rows[:2]:
    print(f"  {name:18} A+A {bar(s):55} {s}")
    print(f"  {'':18} A.A {bar(p):55} {p}")
sizes = [(k, len(prods(range(1, k + 1), range(1, k + 1)))) for k in (10, 100)]
print(f"multiplication table 1..n x 1..n, distinct products: {sizes}")
print(f"the same for n = 100, by testing each m up to 10000 for a divisor pair: "
      f"{products_by_divisors(100)}")
best, count = None, 0
for A in subsets(list(range(1, 25)), 6):
    count += 1
    m = max(len(sums(A, A)), len(prods(A, A)))
    if best is None or m < best[0]: best = (m, A)
print(f"search: {count} sets of 6 from 1..24; smallest max(|A+A|, |A.A|) = {best[0]}, "
      f"first at {list(best[1])}")
print(f"for |A| = 6: 2|A| - 1 = 11, |A|^(4/3) = {6 ** (4 / 3):.2f}, "
      f"Solymosi floor |A|^(4/3)/(2 ceil(log2|A|)^(1/3)) = {6 ** (4 / 3) / (2 * ceil_log2(6) ** (1 / 3)):.2f}")
Z = list(range(13))                      # a hypothesis broken: wrap-round arithmetic
zs, zp = {(a + b) % 13 for a in Z for b in Z}, {(a * b) % 13 for a in Z for b in Z}
print(f"mistake 1, ordered pairs read as the sumset of the run: {n * n}, not {g[2]}")
print(f"mistake 2, bound turned round, |A+A| <= |A|^4/E+: ceiling {n ** 4 / g[4]:.1f}, "
      f"but |A+A| is {g[2]}")
print(f"mistake 3, all 13 residues mod 13: |A+A| {len(zs)}, |A.A| {len(zp)}, |A| {len(Z)}")
print(f"mistake 4, energy without the trivial quadruples, geometric run: {g[4] - (2 * n * n - n)}")
assert [g[2], g[3], ar[2], ar[3]] == [n * (n + 1) // 2, 2 * n - 1, 2 * n - 1, 42]  # sizes vs formulas
assert all(r[4] == r[5] for r in rows)                           # energy, two roads
assert g[4] == 2 * n * n - n and ar[4] == (2 * n ** 3 + n) // 3   # energy vs closed forms
assert g[6] == ar[4] and all(r[1] ** 4 <= r[2] * r[4] for r in rows)   # log map; the bound
assert sizes[1][1] == products_by_divisors(100) == 2906          # products, two roads
assert best == (15, (1, 2, 3, 4, 6, 8)) and count == 134596 and len(zs) == len(zp) == 13
print("ALL CHECKS PASS")
