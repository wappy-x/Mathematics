# Normal and separable extensions -- the check behind the card.  Nothing is imported.
# A field is Q[x, y]/(f(x), g(y)), basis x^i y^j.  Road 1 searches for every root of f and g
# in it (degree n allows at most n roots) and counts automorphisms.  Road 2 measures what each
# automorphism group fixes, by rank.  Road 3 is evidence: how two cubics factor mod primes.
def field(f, g): return (f, g, len(f) - 1, len(g) - 1)
def const(F, c): return [c] + [0] * (F[2] * F[3] - 1)
def add(a, b): return [u + v for u, v in zip(a, b)]

def mul(F, a, b):
    f, g, n, m = F
    w = [[0] * (2 * m - 1) for _ in range(2 * n - 1)]
    for i in range(n * m):
        for k in range(n * m):
            w[i // m + k // m][i % m + k % m] += a[i] * b[k]
    for i in range(2 * n - 2, n - 1, -1):              # x^n = -(f_0 + ... + f_(n-1) x^(n-1))
        for j in range(2 * m - 1):
            c, w[i][j] = w[i][j], 0
            for t in range(n): w[i - n + t][j] -= c * f[t]
    for row in w[:n]:                                   # the same for y^m, using g
        for j in range(2 * m - 2, m - 1, -1):
            c, row[j] = row[j], 0
            for t in range(m): row[j - m + t] -= c * g[t]
    return [w[i][j] for i in range(n) for j in range(m)]
def ev(F, p, a):                                        # p(a) by Horner's rule
    r = const(F, p[-1])
    for c in reversed(p[:-1]): r = add(mul(F, r, a), const(F, c))
    return r
def box(d, lo, hi):                                     # every coordinate vector in a box
    out = [[]]
    for _ in range(d): out = [v + [c] for v in out for c in range(lo, hi + 1)]
    return out
def roots(F, p, lo, hi): return [v for v in box(F[2] * F[3], lo, hi) if not any(ev(F, p, v))]
def image(F, A, B, e):                                  # sum of e_ij A^i B^j
    n, m = F[2], F[3]
    out, pa = const(F, 0), const(F, 1)
    for i in range(n):
        pb = pa
        for j in range(m):
            out = add(out, [e[i * m + j] * c for c in pb])
            pb = mul(F, pb, B)
        pa = mul(F, pa, A)
    return out

def is_hom(F, A, B):                                    # respects every product of basis vectors
    d = F[2] * F[3]
    basis = [[int(i == k) for i in range(d)] for k in range(d)]
    return all(image(F, A, B, mul(F, u, v)) == mul(F, image(F, A, B, u), image(F, A, B, v))
               for u in basis for v in basis)
def autos(F, rf, rg): return [(A, B) for A in rf for B in rg if is_hom(F, A, B)]
def gcd(a, b): return gcd(b, a % b) if b else abs(a)
def binom(n, k): return 1 if k in (0, n) else binom(n - 1, k - 1) + binom(n - 1, k)
def rank(rows):                                         # integer elimination, no fractions
    rows, r = [row[:] for row in rows if any(row)], 0
    for col in range(len(rows[0]) if rows else 0):
        piv = next((i for i in range(r, len(rows)) if rows[i][col]), None)
        if piv is None: continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in [i for i in range(len(rows)) if i != r and rows[i][col]]:
            c, p = rows[i][col], rows[r][col]
            rows[i] = [p * x - c * y for x, y in zip(rows[i], rows[r])]
            g = 0
            for x in rows[i]: g = gcd(g, x)
            rows[i] = [x // g for x in rows[i]] if g else rows[i]
        r += 1
    return r
def fixed_dim(F, G):                                    # dimension of what every map in G fixes
    d, rows = F[2] * F[3], []
    for A, B in G:
        cols = [image(F, A, B, [int(i == k) for i in range(d)]) for k in range(d)]
        rows += [[cols[k][i] - int(i == k) for k in range(d)] for i in range(d)]
    return d - rank(rows)

def name(v, s):                                         # coordinates as a readable sum
    t = [f"{c}" if k == 0 else {1: "", -1: "-"}.get(c, f"{c}") + s[k] for k, c in enumerate(v) if c]
    return " + ".join(t).replace("+ -", "- ") or "0"
def prem(a, b):                                         # pseudo-remainder over the integers
    while len(a) >= len(b):
        c, s = a[-1], len(a) - len(b)
        a = [x * b[-1] for x in a]
        for i, x in enumerate(b): a[i + s] -= c * x
        while a and a[-1] == 0: a.pop()
    return a
def gcd_deg(a, b):                                      # degree of gcd(a, b), Euclid's algorithm
    while b: a, b = b, prem(a, b)
    return len(a) - 1
def deriv(f, p=0):
    d = [k * c % p if p else k * c for k, c in enumerate(f)][1:]
    while d and d[-1] == 0: d.pop()
    return d

lo, hi = 1.0, 2.0                                       # the real cube root of 2, by bisection
for _ in range(60): lo, hi = ((lo + hi) / 2, hi) if ((lo + hi) / 2) ** 3 < 2 else (lo, (lo + hi) / 2)
print(f"cube root of 2 = {lo:.6f}; other roots {-lo / 2:.6f} +/- {lo * 3 ** 0.5 / 2:.6f} i")
L6, Q3 = field([-2, 0, 0, 1], [1, 1, 1]), field([-2, 0, 0, 1], [0, 1])
L8, Q4 = field([-2, 0, 0, 0, 1], [1, 0, 1]), field([-2, 0, 0, 0, 1], [0, 1])
C3 = field([1, -3, 0, 1], [0, 1])
s6, s8 = ["", "w", "a", "aw", "a^2", "a^2w"], ["", "i", "b", "bi", "b^2", "b^2i", "b^3", "b^3i"]
r6, w6 = roots(L6, L6[0], -1, 1), roots(L6, L6[1], -1, 1)
r8, i8 = roots(L8, L8[0], -1, 1), roots(L8, L8[1], -1, 1)
G6, G8 = autos(L6, r6, w6), autos(L8, r8, i8)
inQ3, inQ4 = ([[v[2 * i] for i in range(n)] for v in r if not any(v[1::2])] for r, n in ((r6, 3), (r8, 4)))
GQ3, GQ4 = autos(Q3, inQ3, [const(Q3, 0)]), autos(Q4, inQ4, [const(Q4, 0)])
GC = autos(C3, (rc := roots(C3, C3[0], -2, 2)), [const(C3, 0)])
orbit = {tuple(image(L6, A, B, [0, 1, 1, 0, 0, 0])) for A, B in G6}   # images of a + w
print("L = Q(a, w), a^3 = 2, w^2 + w + 1 = 0; roots of x^3 - 2 in L:", ", ".join(name(v, s6) for v in r6))
print("  roots of x^2 + x + 1 in L:", ", ".join(name(v, s6) for v in w6) + f"; a + w has {len(orbit)} images")
for lab, F, rs, G, s in [("L = Q(a, w)", L6, [], G6, s6), ("Q(a), x^3 - 2", Q3, inQ3, GQ3, s6[::2]),
                         ("M = Q(b, i)", L8, [], G8, s8), ("Q(b), x^4 - 2", Q4, inQ4, GQ4, s8[::2]),
                         ("Q(r), x^3 - 3x + 1", C3, rc, GC, ["", "r", "r^2"])]:
    inside = f"; roots inside: {', '.join(name(v, s) for v in rs)}" if rs else ""
    print(f"{lab}: degree {F[2] * F[3]}{inside}; automorphisms {len(G)}; fixed dimension {fixed_dim(F, G)}")
sig = ([0, 0, 0, 1, 0, 0, 0, 0], [0, -1, 0, 0, 0, 0, 0, 0])                # b -> bi, i -> -i, order 2
nb = sum(image(L8, *sig, e) == e for e in ([int(i == k) for i in range(8)] for k in range(8)))
print(f"M, the pair id and b -> bi, i -> -i (one of the 8: {sig in G8}): basis vectors fixed {nb}; fixed dimension {fixed_dim(L8, [sig])} = 8 / 2")
sep, tally = [], {}
for lab, (a, b) in [("x^3 - 2", (0, -2)), ("x^3 - 3x + 1", (-3, 1)), ("x^3 - 3x + 2", (-3, 2))]:
    sep.append((gcd_deg([b, a, 0, 1], deriv([b, a, 0, 1])), -4 * a ** 3 - 27 * b ** 2))
    print(f"{lab}: gcd(f, f') degree {sep[-1][0]}; discriminant -4a^3 - 27b^2 = {sep[-1][1]}")
for p in (2, 3):
    print(f"char {p}: x^{p} - t has derivative {deriv([0] * p + [1], p) or 0}; "
          f"(x - s)^{p} middle binomials mod {p}: {(m := [binom(p, k) % p for k in range(1, p)])}; "
          f"degree {p}, distinct roots {1 if not any(m) else p}, automorphisms {1 if not any(m) else p}")
P = [p for p in range(2, 1000) if all(p % q for q in range(2, int(p ** 0.5) + 1))]
for lab, f, bad in [("x^3 - 2", [-2, 0, 0, 1], (2, 3)), ("x^3 - 3x + 1", [1, -3, 0, 1], (3,))]:
    cnt = [sum(1 for x in range(p) if (f[0] + f[1] * x + x ** 3) % p == 0) for p in P if p not in bad]
    tally[lab] = [cnt.count(k) for k in (0, 1, 3)]
    print(f"{lab}, {len(cnt)} primes below 1,000 (p not dividing the discriminant): "
          f"0 roots {tally[lab][0]}, 1 root {tally[lab][1]}, 3 roots {tally[lab][2]}")
one2 = all(sum(1 for x in range(p) if (x ** 3 - 2) % p == 0) == 1 for p in P if p % 3 == 2 and p > 2)
print("x^3 - 2 has exactly one root mod every prime p = 2 mod 3 above 2:", "yes" if one2 else "no")
print(f"mistake, complex roots counted as automorphisms: Q(a) {len(r6)} against {len(GQ3)}; "
      f"Q(b) {len(r8)} against {len(GQ4)}; Q(a) fixes dimension {fixed_dim(Q3, GQ3)}, not 1")
assert len(r6) == 3 and len(w6) == 2 and len(G6) == 6 and fixed_dim(L6, G6) == 1  # normal, separable
assert len(GQ3) == 1 and fixed_dim(Q3, GQ3) == 3 and len(orbit) == 6             # not normal; primitive
assert len(G8) == 8 and fixed_dim(L8, G8) == 1 and len(GQ4) == 2 == fixed_dim(Q4, GQ4)
assert sig in G8 and nb == 2 and fixed_dim(L8, [sig]) == 4                        # a fixed field off the basis
assert len(GC) == 3 and fixed_dim(C3, GC) == 1 and tally["x^3 - 3x + 1"][1] == 0 and one2
assert [g == 0 for g, d in sep] == [d != 0 for g, d in sep] == [True, True, False]  # two roads agree
assert deriv([0, 0, 1], 2) == [] and deriv([0, 0, 0, 1], 3) == []
print("ALL CHECKS PASS")
