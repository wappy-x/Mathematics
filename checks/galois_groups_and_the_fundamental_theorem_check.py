# The Galois correspondence -- the check behind the card.  Fraction and permutations are tools.
# L is the splitting field of x^4 - 2: every number in it is a rational mix of the 8 basis
# numbers α^j i^k (j = 0..3, k = 0..1), where α = 2^(1/4).  A vector of 8 integers is one number.
from fractions import Fraction
from itertools import permutations
A4 = 2                                 # the polynomial is x^4 - A4
def mul(u, v):                         # multiply two numbers of L, using α^4 = 2 and i^2 = -1
    w = [0] * 8
    for p in range(8):
        for q in range(8):
            j, k, c = p % 4 + q % 4, p // 4 + q // 4, u[p] * v[q]
            if j >= 4: j, c = j - 4, A4 * c
            if k == 2: k, c = 0, -c
            w[j + 4 * k] += c
    return tuple(w)
def apply(g, u):                       # g = (r, s): α -> i^r α, i -> i^s, extended to all of L
    w = [0] * 8
    for p in range(8):
        m = (g[0] * (p % 4) + g[1] * (p // 4)) % 4
        w[p % 4 + 4 * (m % 2)] += -u[p] if m >= 2 else u[p]
    return tuple(w)
def compose(g, h):                     # do h first, then g
    return ((g[0] + g[1] * h[0]) % 4, (g[1] * h[1]) % 4)
def name(g): return (["", "σ", "σ²", "σ³"][g[0]] + ("τ" if g[1] == 3 else "")) or "1"
def show(c):                           # integer coefficients, constant first -> "x^4 - 2"
    t = [(f"{abs(a) if abs(a) != 1 or n == 0 else ''}" + ("x" if n else "") + (f"^{n}" if n > 1
          else ""), a) for n, a in enumerate(c) if a]
    return "".join((" - " if a < 0 else " + ") * (i > 0) + ("-" if a < 0 and i == 0 else "") + m
                   for i, (m, a) in enumerate(reversed(t)))
def e(*ps): return tuple(sum(c for p, c in ps if p == q) for q in range(8))
def rank(rows):                        # rank over Q by elimination with fractions
    m, r = [[Fraction(x) for x in row] for row in rows], 0
    for c in range(8):
        piv = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if piv is None: continue
        m[r], m[piv] = m[piv], m[r]
        for i in range(len(m)):
            if i != r and m[i][c] != 0:
                f = m[i][c] / m[r][c]
                m[i] = [x - f * y for x, y in zip(m[i], m[r])]
        r += 1
    return r
BASIS = [e((p, 1)) for p in range(8)]
# ---- road 1: try all 16 ways to send α to a root i^r α and i to a power i^s; keep the ring maps
tried = [(r, s) for r in range(4) for s in range(4)]
G = [g for g in tried if all(apply(g, mul(u, v)) == mul(apply(g, u), apply(g, v))
                             for u in BASIS for v in BASIS)]
print(f"maps tried {len(tried)}, respect all {len(BASIS) ** 2} basis products {len(G)}: {[name(g) for g in G]}")
def order(g, x=(0, 1), n=0):
    while n == 0 or x != (0, 1): x, n = compose(g, x), n + 1
    return n
print(f"element orders: {[order(g) for g in G]}; τσ = {name(compose((0, 3), (1, 1)))}, not στ: "
      f"order matters; D4, the square's 8 symmetries")
# ---- road 2: the 4 roots as complex numbers; a symmetry must send -r to minus the image of r
a = A4 ** 0.25
ROOTS = [(a, 0.0), (0.0, a), (-a, 0.0), (0.0, -a)]                   # α, iα, -α, -iα
neg = lambda z: (-z[0], -z[1])
keep = [p for p in permutations(range(4))
        if all(ROOTS[p[(k + 2) % 4]] == neg(ROOTS[p[k]]) for k in range(4))]
on_roots = sorted(tuple((g[1] * k + g[0]) % 4 for k in range(4)) for g in G)  # road 1's maps on the 4 roots
print(f"α = {ROOTS[0][0]:.6f}; root shuffles 24, keeping r -> -r pairs {len(keep)}; failing {24 - len(keep)}; "
      f"same as road 1's maps on the roots {on_roots == keep}")
theta = e((1, 1), (4, 1))                                            # α + i
conj = sorted({apply(g, theta) for g in G})
poly = [e((0, 1))]                                                   # product of (x - c)
for c in conj:
    poly = [tuple(a - b for a, b in zip(lo, mul(c, hi)))
            for lo, hi in zip([e()] + poly, poly + [e()])]
print(f"α + i has {len(conj)} distinct conjugates; min poly coefficients rational "
      f"{all(c[1:] == (0,) * 7 for c in poly)}: {show([c[0] for c in poly])}, so [L:Q] = {len(conj)}")
assert abs(sum(c[0] * complex(a, 1) ** n for n, c in enumerate(poly))) < 1e-9   # α + i, as a float, is a root
# ---- every subgroup, by brute force over the 256 subsets of the 8 symmetries
subs = [H for H in ([g for b, g in enumerate(G) if m >> b & 1] for m in range(256))
        if (0, 1) in H and all(compose(x, y) in H for x in H for y in H)]
subs.sort(key=lambda H: (len(H), [name(g) for g in H]))
CANDIDATES = [("1", e((0, 1))), ("i", e((4, 1))), ("√2", e((2, 1))), ("i√2", e((6, 1))),
              ("α", e((1, 1))), ("iα", e((5, 1))), ("(1+i)α", e((1, 1), (5, 1))),
              ("(1-i)α", e((1, 1), (5, -1))), ("√2 + i", e((2, 1), (4, 1))), ("α + i", theta)]
print("H | order | index | dim of fixed field: kernel, average | field | min poly | normal: H, field")
fields = {}
for H in subs:
    by_kernel = 8 - rank([tuple(a - b for a, b in zip(apply(h, u), u)) for h in H for u in BASIS])
    avg = [tuple(sum(c) for c in zip(*(apply(h, u) for h in H))) for u in BASIS]
    by_average = rank(avg)
    lab, gen = next((l, v) for l, v in CANDIDATES
                    if [g for g in G if apply(g, v) == v] == sorted(H))
    orbit = sorted({apply(g, gen) for g in G})
    mp = [e((0, 1))]
    for c in orbit:
        mp = [tuple(a - b for a, b in zip(lo, mul(c, hi))) for lo, hi in zip([e()] + mp, mp + [e()])]
    grp_normal = all(compose(compose(g, h), (-g[1] * g[0] % 4, g[1])) in H for g in G for h in H)
    fld_normal = all(rank(avg + [apply(g, w) for w in avg]) == by_average for g in G)
    fields[tuple(sorted(H))] = lab
    print(f"{'{' + ','.join(name(g) for g in H) + '}' if len(H) < 8 else 'all 8':14} {len(H)} "
          f"{8 // len(H)} {by_kernel} {by_average}  {'Q(' + lab + ')' if len(H) < 8 else 'Q':10} "
          f"{show([c[0] for c in mp]):26} {grp_normal} {fld_normal}")
    assert by_kernel == by_average == 8 // len(H) == len(orbit)      # [L^H:Q] = [G:H]
    assert grp_normal == fld_normal and all(c[1:] == (0,) * 7 for c in mp)
normals = sum(all(compose(compose(g, h), (-g[1] * g[0] % 4, g[1])) in H for g in G for h in H)
              for H in subs)
print(f"subgroups {len(subs)} of 256 subsets, fields {len(set(fields.values()))}, normal {normals}")
# ---- recover a field: start from Q(√2), find the symmetries fixing it, take their fixed field
fix_r2 = sorted(g for g in G if apply(g, e((2, 1))) == e((2, 1)))
print(f"Gal(L/Q(√2)) = {[name(g) for g in fix_r2]}, order {len(fix_r2)}; its fixed field is "
      f"Q({fields[tuple(fix_r2)]}), degree {8 // len(fix_r2)}")
# ---- what breaks
real_roots = [k for k in range(4) if apply((0, 3), e((1 + 4 * (k % 2), (-1) ** (k // 2)))) ==
              e((1 + 4 * (k % 2), (-1) ** (k // 2)))]
above_a = [H for H in subs if (0, 3) in H]
print(f"Q(α) alone: degree 4, roots of x^4 - 2 inside it {len(real_roots)}, so automorphisms "
      f"{len(real_roots)}; its subgroups 2, but fields between Q and Q(α) {len(above_a)}")
print(f"sizes swapped: H = {{1,τ}} would give degree {len(above_a[0])}, true degree "
      f"{8 // len(above_a[0])}")
s2, s = [H for H in subs if len(H) == 2 and (2, 1) in H][0], [H for H in subs if (1, 1) in H][0]
print(f"bigger group, smaller field: {{1,σ²}} of order 2 fixes Q({fields[tuple(sorted(s2))]}), degree "
      f"4; <σ> of order 4 fixes Q({fields[tuple(sorted(s))]}) of degree 2")
moved = sorted({fields[tuple(sorted(compose(compose(g, h), (-g[1] * g[0] % 4, g[1])) for h in
                                     above_a[0]))] for g in G})
print(f"non-normal {{1,τ}}: the symmetries carry Q(α) to {len(moved)} fields {moved}")
# ---- a count against the group: roots of x^4 - 2 mod p, odd primes below 10,000
N = 10000
sieve = [True] * N
for p in range(2, 100):
    if sieve[p]: sieve[p * p::p] = [False] * len(range(p * p, N, p))
tally = [0] * 5
for p in range(3, N):
    if sieve[p]:
        sq = [x * x % p for x in range(p)]
        tally[sum(1 for x in range(p) if sq[sq[x]] == 2 % p)] += 1
fixed = [sum(1 for k in range(4) if (g[1] * k + g[0]) % 4 == k) for g in G]
pred = [fixed.count(n) for n in range(5)]
print(f"roots fixed by each symmetry {fixed}: shares 0,1,2,3,4 roots = {pred} out of 8")
print(f"odd primes below {N:,}: {sum(tally):,}; with 0,1,2,3,4 roots of x^4 - 2: {tally}")
print("shares found " + ", ".join(f"{t / sum(tally):.4f}" for t in tally) +
      "; predicted " + ", ".join(f"{q / 8:.4f}" for q in pred))
assert len(G) == len(keep) == len(conj) == 8 and on_roots == keep and len(subs) == 10 and normals == 6
assert len(fix_r2) == 4 and fields[tuple(fix_r2)] == "√2" and len(real_roots) == 2
assert all(abs(t / sum(tally) - q / 8) < 0.03 for t, q in zip(tally, pred))
print("ALL CHECKS PASS")
