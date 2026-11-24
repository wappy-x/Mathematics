# Nets and filters: the check behind the card.  Standard library only, exact fractions.
from fractions import Fraction as F
from itertools import combinations

def show(q): return str(q)                       # 1/2, 2/7, 0
def dec(q):                                      # a terminating fraction as a decimal
    for k in range(7):
        if (q * 10**k).denominator == 1:
            s = str(abs(q.numerator * 10**k // q.denominator)).rjust(k + 1, "0")
            return s if k == 0 else s[:-k] + "." + s[-k:]
    raise ValueError(q)

# Part 1: the net f_F in R^[0,1].  f_F is 0 on the finite set F and 1 elsewhere.
pts = [F(1, 8), F(1, 4), F(2, 7), F(1, 3), F(1, 2), F(3, 5), F(3, 4), F(1)]
box, eps = [F(1, 2), F(1, 3), F(2, 7)], F(1, 10)   # basic box round 0: |f(x)| < 1/10 at 3 coordinates
def f(Fset, x): return 0 if x in Fset else 1
def in_box(Fset, coords=box, e=eps): return all(abs(f(Fset, x)) < e for x in coords)
print("Part 1: R^[0,1], pointwise; f_F is 0 on the finite set F, 1 elsewhere")
print("box B round the zero function: |f(x)| < 1/10 at x = 1/2, 1/3, 2/7")
for Fs in [set(), {F(1, 2), F(1, 3)}, set(box)]:
    name = "{" + ", ".join(show(x) for x in sorted(Fs, reverse=True)) + "}"
    vals = " ".join(str(f(Fs, x)) for x in box)
    print(f"  F = {name}: values at 1/2, 1/3, 2/7: {vals}; in B: {'yes' if in_box(Fs) else 'no'}")
subsets = [frozenset(c) for r in range(9) for c in combinations(pts, r)]
later = {a: {c for c in subsets if a <= c} for a in subsets}       # the labels later than a, by search
least = all(min(later[a] & later[b], key=len) == a | b for a in subsets for b in subsets)   # road 2: the union
tail = [s for s in subsets if in_box(s)]
holds0 = all(in_box(s) == set(box).issubset(s) for s in subsets)
assert least and holds0
assert len(tail) == 2 ** (len(pts) - len(box))                      # road 2: count by formula
print(f"8 sample points, {len(subsets)} finite sets F: least later F, by search, is the union for all {len(subsets)**2} pairs: {'yes' if least else 'no'}")
print(f"  f_F in B for {len(tail)} of 256 F; exactly those holding the probes: yes; 2^({len(pts)}-{len(box)}) = {2 ** (len(pts) - len(box))}")
single = sum(in_box({x}) for x in pts)
assert single == 0
print(f"mistake, singletons only (not directed): f_x in B for {single} of 8")

# Part 2: the best sequence, g_n = 0 on every fraction p/q in [0, 1] with q <= n.
def farey(n): return {F(p, q) for q in range(1, n + 1) for p in range(q + 1)}
def phi(k):                                      # totient by the product over primes
    out, m, p = k, k, 2
    while p * p <= m:
        if m % p == 0:
            out -= out // p
            while m % p == 0: m //= p
        p += 1
    return out - out // m if m > 1 else out
print("Part 2: the best sequence: g_n is 0 on every fraction p/q in [0, 1] with q <= n")
sizes = []
for n in (10, 100):
    a, b = len(farey(n)), 1 + sum(phi(k) for k in range(1, n + 1))
    assert a == b
    sizes.append(f"n = {n}: {a} (1 + totient sum {b})")
print("  zero-set sizes: " + "; ".join(sizes))
first = min(n for n in range(1, 101) if F(2, 7) in farey(n))
assert first == 7 and all(F(2, 7) in farey(n) for n in range(7, 101))
print(f"  at x = 2/7: g_n(x) = 1 for n = 1..{first - 1}, 0 from n = {first} on")
miss = all(2 * q.numerator ** 2 != q.denominator ** 2 for q in farey(100))
assert miss
print("  at x = sqrt(2)/2: 2p^2 = q^2 for no p/q with q <= 100, so g_n(x) = 1 for n = 1..100")
print("  g_n never enters the box |f(sqrt(2)/2)| < 1/10: checked on n = 1..100")

# Part 3: the circle in turns.  A = open arc (0, 1/4), p = 1/4 turn.  Arcs of radius 1/n round p.
print("Part 3: the circle in turns; A = arc (0, 1/4), p = 1/4 turn = 90 degrees")
def x_n(n): return F(1, 4) - F(1, 2 * n)
for n in (10, 100, 1000):
    x = x_n(n)
    assert 0 < x < F(1, 4) and abs(x - F(1, 4)) < F(1, n)
    print(f"  n = {n}: x_n = {show(x)} turn = {dec(360 * x)} degrees")
entry = [n for n in range(1, 2001) if abs(x_n(n) - F(1, 4)) < F(1, 1000)]
assert entry == list(range(1000 // 2 + 1, 2001))                     # road 2: 1/(2n) < 1/1000 iff n > 500
print(f"  inside the arc of radius 1/1000 round p from n = {entry[0]} on (checked n = 1..2000)")

# Part 4: continuity.  h = 1 at the zero function, 0 on A.
witness = [next(F(1, m) for m in range(9, 99) if F(1, m) not in s) for s in subsets]   # f_F = 1 there
hvals = {0 if f(s, w) == 1 else 1 for s, w in zip(subsets, witness)}
assert hvals == {0}
print("Part 4: h = 1 at the zero function, 0 on A")
print(f"  h(f_F) over all 256 F: {sorted(hvals)} (f_F = 1 at {show(witness[-1])}); h(0) = 1; f_F -> 0 but h(f_F) stays 0")

# Part 5: filters on {a, b, c}, all 256 families of subsets.
X = 7                                             # subsets of {a, b, c} as bit masks 0..7
fams = range(1 << 8)
def has(fm, s): return fm >> s & 1
def is_filter(fm):
    return (has(fm, X) and not has(fm, 0)
            and all(has(fm, s & t) for s in range(8) for t in range(8) if has(fm, s) and has(fm, t))
            and all(has(fm, t) for s in range(8) for t in range(8) if has(fm, s) and s & t == s))
def fip(fm):
    mem = [s for s in range(8) if has(fm, s)]
    return all(X & eval_and(c) for r in range(1, len(mem) + 1) for c in combinations(mem, r))
def eval_and(c):
    out = X
    for s in c: out &= s
    return out
filters = [fm for fm in fams if is_filter(fm)]
principal = all(fm == sum(1 << t for t in range(8) if t & core == core)
                for fm in filters for core in [eval_and([s for s in range(8) if has(fm, s)])])
maxf = [g for g in filters if not any(h != g and h & g == g for h in filters)]
ultra = [g for g in filters if all(has(g, s) or has(g, X ^ s) for s in range(8))]
fips = [fm for fm in fams if fip(fm)]
maxfip = [g for g in fips if not any(h != g and h & g == g for h in fips)]
assert len(filters) == 2 ** 3 - 1 and principal and maxf == ultra == maxfip and len(ultra) == 3
print("Part 5: filters on {a, b, c}, every one of the 256 families checked")
print(f"  filters: {len(filters)} (one per non-empty core, 2^3 - 1 = 7); each is all sets holding its core: yes")
print(f"  ultrafilters: {len(ultra)}, by maximality, by 'S or its outside', and as the maximal FIP families: same 3")

# Part 6: every topology on {a, b, c}; an ultrafilter at a point converges where every open set holds it.
tops = [t for t in fams if has(t, 0) and has(t, X) and all(has(t, s & u) and has(t, s | u)
        for s in range(8) for u in range(8) if has(t, s) and has(t, u))]
def limits(t, pt): return [q for q in range(3) if all(not has(t, u) or u >> pt & 1 for u in range(8) if u >> q & 1)]
conv = all(limits(t, pt) for t in tops for pt in range(3))
unique = [t for t in tops if all(len(limits(t, pt)) == 1 for pt in range(3))]
haus = [t for t in tops if all(any(has(t, u) and has(t, v) and u >> i & 1 and v >> j & 1 and not u & v
        for u in range(8) for v in range(8)) for i in range(3) for j in range(3) if i != j)]
assert len(tops) == 29 and conv and unique == haus and len(unique) == 1
print(f"Part 6: all {len(tops)} topologies on {{a, b, c}}: every ultrafilter converges: yes")
print(f"  limits unique in {len(unique)} topology, the discrete one; Hausdorff ones: {len(haus)}; same: yes")
print(f"  mistake, no Hausdorff: some ultrafilter has two or more limits in {len(tops) - len(unique)} of {len(tops)}")

# Part 7: the circle without the glue point; the filter made from the arcs (0, 1/n) turn.  An illustration:
# r = min(q, 1 - q)/2 makes the arc (q - r, q + r) miss (0, r) by construction.
print("Part 7: the circle minus the glue point; the filter of the arcs (0, 1/n) turn")
for k in (1, 6, 11):
    q = F(k, 12); r = min(q, 1 - q) / 2          # arc (q - r, q + r) misses (0, r)
    n = r.denominator if r.numerator == 1 else None
    assert n                                      # r = 1/n, so (0, r) is one of the filter's sets
    print(f"  candidate limit {show(q)} turn: arc ({show(q - r)}, {show(q + r)}) misses (0, 1/{n})")
print("  on the whole circle every arc round 0 holds some (0, 1/n): limit 0, the removed point")

# Part 8: [0,1]^[0,1] is compact, yet s_n(x) = n-th binary digit of x has no convergent subsequence.
ks = range(1, 9)
x = sum(F(1, 2 ** (2 * k)) for k in ks if k % 2)             # digit 1 at positions 2k with k odd
digits = [int(x * 2 ** (2 * k)) % 2 for k in ks]             # road 2: read the digits back
assert digits == [k % 2 for k in ks]
print(f"Part 8: s_n = n-th binary digit; subsequence n_k = 2k; x = {show(x)}")
print("  s_(2k)(x) for k = 1..8: " + " ".join(map(str, digits)) + "; never settles")
print("ALL CHECKS PASS")
