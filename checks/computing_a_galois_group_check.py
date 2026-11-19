# Computing a Galois group: x^4 + x + 1 -- the check behind the card.  Standard library only.
# Road 1: discriminant and resolvent cubic, exact integers.  Road 2: factor patterns mod 2 and 3,
# then the group those cycles generate inside S4.  Road 3: numeric roots, from which the
# discriminant and the resolvent's roots are rebuilt.  Road 4: patterns over many primes (evidence).
from math import isqrt

def trim(a):
    while a and a[-1] == 0: a.pop()
    return a
def pmod(a, b, p):                       # remainder of a by b mod p; coefficients low to high
    a = [c % p for c in a]; inv = pow(b[-1], p - 2, p)
    while len(trim(a)) >= len(b):
        c = a[-1] * inv % p; s = len(a) - len(b)
        for i, bi in enumerate(b): a[s + i] = (a[s + i] - c * bi) % p
    return a
def pdiv(a, b, p):                       # exact quotient a / b mod p
    a = [c % p for c in a]; q = [0] * (len(a) - len(b) + 1); inv = pow(b[-1], p - 2, p)
    for s in range(len(q) - 1, -1, -1):
        c = a[s + len(b) - 1] * inv % p; q[s] = c
        for i, bi in enumerate(b): a[s + i] = (a[s + i] - c * bi) % p
    return q
def pmul(a, b, g, p):
    r = [0] * (len(a) + len(b))
    for i, x in enumerate(a):
        for j, y in enumerate(b): r[i + j] += x * y
    return pmod(r, g, p)
def ppow(a, e, g, p):
    r = [1]
    while e:
        if e & 1: r = pmul(r, a, g, p)
        a = pmul(a, a, g, p); e >>= 1
    return r
def pgcd(a, b, p):
    a, b = trim([c % p for c in a]), trim([c % p for c in b])
    while b: a, b = b, trim(pmod(a, b, p))
    return a
def pattern(f, p):                       # degrees of the irreducible factors of f mod p (f squarefree mod p)
    g, h, d, out = [c % p for c in f], [0, 1], 0, []
    while len(g) > 1:
        d += 1
        if 2 * d > len(g) - 1: out.append(len(g) - 1); break
        h = ppow(h, p, g, p)             # h = x^(p^d) mod g
        hx = h + [0] * (2 - len(h)); hx[1] -= 1
        c = pgcd(g, hx, p)               # product of the factors of degree d
        out += [d] * ((len(c) - 1) // d)
        if len(c) > 1: g = pdiv(g, c, p); h = pmod(h, g, p)
    return tuple(sorted(out, reverse=True))
def resolvent(b, c, d): return [4 * b * d - c * c, -4 * d, -b, 1]   # of x^4 + b x^2 + c x + d
def disc3(r):                            # discriminant of y^3 + a y^2 + b y + c
    c, b, a = r[0], r[1], r[2]
    return a * a * b * b - 4 * b**3 - 4 * a**3 * c - 27 * c * c + 18 * a * b * c
def int_roots(r):
    B = 1 + max(abs(x) for x in r)
    return [y for y in range(-B, B + 1) if sum(c * y**i for i, c in enumerate(r)) == 0]

F = [1, 1, 0, 0, 1]                      # x^4 + x + 1, low to high
disc = -27 * 1**4 + 256 * 1**3           # x^4 + c x + d has discriminant -27 c^4 + 256 d^3
R = resolvent(0, 1, 1)
print("discriminant of x^4+x+1:", disc, "| from the resolvent cubic:", disc3(R), "| isqrt:", isqrt(disc))
print("resolvent cubic y^3 - 4y - 1: integer roots", int_roots(R), "| value at 1 and -1:", 1 - 4 - 1, -1 + 4 - 1)
assert disc == disc3(R) and isqrt(disc)**2 != disc
assert int_roots(R) == []
# Road 2: irreducible mod 2 (also by trial division by every monic linear and quadratic) and 1 + 3 mod 3
small = [[a, 1] for a in range(2)] + [[a, b, 1] for a in range(2) for b in range(2)]
print("x^4+x+1 mod 2:", "+".join(map(str, pattern(F, 2))), "| mod 3:", "+".join(map(str, pattern(F, 3))), "| roots mod 3:", [x for x in range(3) if (x**4 + x + 1) % 3 == 0])
assert pattern(F, 2) == (4,) and all(trim(pmod(F, g, 2)) for g in small)
assert pattern(F, 3) == (3, 1)
def closure(gens):                       # every shuffle the generators produce, composed in any order
    grp, todo = set(), [(0, 1, 2, 3)]
    while todo:
        s = todo.pop()
        if s not in grp: grp.add(s); todo += [tuple(s[g[i]] for i in range(4)) for g in gens]
    return grp
g24, g8 = closure([(1, 2, 3, 0), (0, 2, 3, 1)]), closure([(1, 2, 3, 0), (2, 1, 0, 3)])
print("group from (1 2 3 4) and (2 3 4):", len(g24), "shuffles | from (1 2 3 4) and (1 3):", len(g8), "shuffles")
assert len(g24) == 24 and len(g8) == 8
# Road 3: complex roots by Durand-Kerner, then the discriminant and resolvent rebuilt from them
z = [(0.4 + 0.9j) ** k for k in range(4)]
for _ in range(200):
    for i in range(4):
        den = 1
        for j in range(4):
            if j != i: den *= z[i] - z[j]
        z[i] -= (z[i]**4 + z[i] + 1) / den
nd = 1
for i in range(4):
    for j in range(i + 1, 4): nd *= (z[i] - z[j]) ** 2
th = sorted([(z[0]*z[1] + z[2]*z[3]).real, (z[0]*z[2] + z[1]*z[3]).real, (z[0]*z[3] + z[1]*z[2]).real])
print("roots: " + ", ".join("%.6f%+.6fi" % (w.real, w.imag) for w in sorted(z, key=lambda w: (w.real, w.imag))))
print("numeric discriminant: %.6f | numeric resolvent roots: %.6f %.6f %.6f" % (nd.real, *th))
assert abs(nd.real - disc) < 1e-6 and all(abs(sum(c * t**i for i, c in enumerate(R))) < 1e-9 for t in th)
# Road 4: factor patterns over primes; a prime dividing the discriminant is set aside
def primes(n):
    s = bytearray([1]) * n; s[0] = s[1] = 0
    for i in range(2, isqrt(n) + 1):
        if s[i]: s[i*i::i] = bytearray(len(s[i*i::i]))
    return [i for i in range(n) if s[i]]
PR = primes(100000)
for p in PR[:46]:                         # brute-force root count agrees with the pattern's 1s
    if p != 229: assert sum((x**4 + x + 1) % p == 0 for x in range(p)) == pattern(F, p).count(1)
T4, T3 = [(1, 1, 1, 1), (2, 1, 1), (2, 2), (3, 1), (4,)], [(1, 1, 1), (2, 1), (3,)]
S4, D4 = [1, 6, 3, 8, 6], [1, 2, 3, 0, 2]   # elements of each cycle type, out of 24 and out of 8
def count(f, bad, n, types=T4):
    c = {t: 0 for t in types}
    for p in PR:
        if p < n and bad % p: c[pattern(f, p)] += 1
    return [c[t] for t in types]
print("pattern counts       1+1+1+1   2+1+1    2+2    3+1      4   primes")
for n in (1000, 10000, 100000):
    c = count(F, disc, n); print("x^4+x+1, p < %-6d %8d %7d %6d %6d %6d %8d" % (n, *c, sum(c)))
c4 = count([-2, 0, 0, 0, 1], 2048, 100000); print("x^4-2,   p < 100000 %8d %7d %6d %6d %6d %8d" % (*c4, sum(c4)))
for t, k, s in zip(T4, c, S4):
    sh = k / sum(c); print("%-8s %-30s %5.2f%%  S4 predicts %5.2f%%" % ("+".join(map(str, t)), "#" * round(sh * 80), 100 * sh, 100 * s / 24))
    assert abs(sh - s / 24) < 0.01
assert all(abs(k / sum(c4) - s / 8) < 0.01 for k, s in zip(c4, D4))
cR = count(R, disc, 100000, T3)
print("resolvent y^3-4y-1, p < 100000, patterns 1+1+1, 2+1, 3:", *cR, "| S3 predicts shares 1/6, 1/2, 1/3")
assert all(abs(k / sum(cR) - s / 6) < 0.01 for k, s in zip(cR, [1, 3, 2]))
# What breaks
r229 = [x for x in range(229) if (x**4 + x + 1) % 229 == 0]
q229 = pdiv(F, [75 * 75 % 229, -150 % 229, 1], 229)
print("mod 229: roots", r229, "| derivative there:", [(4 * x**3 + 1) % 229 for x in r229], "| f = (x-75)^2 times", q229, "| routine says",
      "+".join(map(str, pattern(F, 229))))
assert r229 == [75] and (4 * 75**3 + 1) % 229 == 0 and all(sum(c * x**i for i, c in enumerate(q229)) % 229 for x in range(229))
assert pmul(q229, [75 * 75, -150, 1], [0] * 5 + [1], 229) == [1, 1, 0, 0, 1]
R2, R4 = resolvent(0, 0, -2), resolvent(0, 0, 4)
print("x^4-2: discriminant", disc3(R2), "| resolvent", R2, "integer roots", int_roots(R2), "| 3+1 never seen:", c4[3],
      "| mod 7: roots", [x for x in range(7) if (x**4 - 2) % 7 == 0], "pattern", "+".join(map(str, pattern([-2, 0, 0, 0, 1], 7))))
assert int_roots(R2) == [0] and c4[3] == 0 and disc3(R2) < 0 and pattern([-2, 0, 0, 0, 1], 7) == (2, 1, 1)   # a single swap: not C4
fac = [sum(a * b for i, a in enumerate([2, 2, 1]) for j, b in enumerate([2, -2, 1]) if i + j == k) for k in range(5)]
print("x^4+4: discriminant", disc3(R4), "=", isqrt(disc3(R4)), "squared | resolvent integer roots", int_roots(R4), "| but (x^2+2x+2)(x^2-2x+2) =", fac)
assert isqrt(disc3(R4))**2 == disc3(R4) and len(int_roots(R4)) == 3 and fac == [4, 0, 0, 0, 1]
c3 = count([1, -3, 0, 1], 81, 10000, T3)
print("x^3-3x+1: discriminant", disc3([1, -3, 0, 1]), "| p < 10000 patterns 1+1+1, 2+1, 3:", *c3)
assert isqrt(disc3([1, -3, 0, 1]))**2 == disc3([1, -3, 0, 1]) and c3[1] == 0
print("ALL CHECKS PASS")
