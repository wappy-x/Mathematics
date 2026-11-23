# The inverse Galois problem: the check behind the card.  Standard library only.
# Builds polynomials with a chosen abelian group from roots of unity, then reads
# their factor patterns mod p by distinct-degree factorisation written out here.
from math import cos, pi

def trim(a):
    while a and a[-1] == 0: a.pop()
    return a
def pdivmod(a, b, p):                         # polynomials: coefficient lists, lowest power first
    a = trim([x % p for x in a]); q = [0] * max(len(a) - len(b) + 1, 1)
    inv = pow(b[-1], p - 2, p)                # Fermat: b^(p-2) undoes b mod p
    while len(a) >= len(b):
        c, s = a[-1] * inv % p, len(a) - len(b); q[s] = c
        for i, bi in enumerate(b): a[s + i] = (a[s + i] - c * bi) % p
        trim(a)
    return q, a
def pmul(a, b, p):
    r = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b): r[i + j] = (r[i + j] + x * y) % p
    return trim(r)
def pgcd(a, b, p):
    a, b = trim([x % p for x in a]), trim([x % p for x in b])
    while b: a, b = b, pdivmod(a, b, p)[1]
    return a
def pattern(f, p):                            # factor degrees of f mod p, or None if a root repeats
    deriv = [i * c for i, c in enumerate(f)][1:]
    if len(pgcd(f, deriv, p)) > 1: return None
    g, h, d, degs = trim([x % p for x in f]), [0, 1], 0, []
    while len(g) - 1 >= 2 * (d + 1):
        d += 1; r, e, b = [1], p, pdivmod(h, g, p)[1]
        while e:                              # h <- h^p mod g, so h = x^(p^d) mod g
            if e & 1: r = pdivmod(pmul(r, b, p), g, p)[1]
            b, e = pdivmod(pmul(b, b, p), g, p)[1], e >> 1
        h = r; diff = h + [0] * (2 - len(h)); diff[1] -= 1
        c = pgcd(g, diff, p); k = len(c) - 1   # c holds every factor of degree d
        if k > 0: degs += [d] * (k // d); g = pdivmod(g, c, p)[0]; h = pdivmod(h, g, p)[1]
    if len(g) > 1: degs.append(len(g) - 1)
    return tuple(sorted(degs, reverse=True))
def primes(n): return [q for q in range(2, n) if all(q % r for r in range(2, int(q ** 0.5) + 1))]
def from_roots(roots):                        # multiply out (x - r), then round
    c = [1.0]
    for r in roots: c = [0.0] + c; c = [c[i] - r * c[i + 1] for i in range(len(c) - 1)] + [c[-1]]
    ints = [round(x) for x in c]
    return ints, max(abs(x - y) for x, y in zip(c, ints)) < 1e-6
def show(f): return " ".join(f"{c:+d}x^{i}" for i, c in reversed(list(enumerate(f))) if c)
def period_poly(m, H):                        # conjugates of the sum of zeta_m^h over H
    units = [k for k in range(1, m) if all(k % q for q in primes(m + 1) if m % q == 0)]
    reps, seen = [], set()
    for g in units:
        if g not in seen: reps.append(g); seen |= {g * h % m for h in H}
    roots = [sum(cos(2 * pi * g * h / m) for h in H) for g in reps]
    return units, reps, roots, *from_roots(roots)

print("1. a group of order 3 from the 7th roots of unity")
H7 = sorted({x ** 3 % 7 for x in range(1, 7)})
u7, r7, roots7, f7, ok7 = period_poly(7, H7)
print("cubes of 1..6:", [x ** 3 for x in range(1, 7)], "; mod 7:", [x ** 3 % 7 for x in range(1, 7)])
print("cubes mod 7:", H7, "; units", len(u7), "/ subgroup", len(H7), "=", len(r7), "conjugates")
print("conjugates:", " ".join(f"{r:.6f}" for r in roots7), "; sum", f"{sum(roots7):.6f}")
print("polynomial:", show(f7), "; integer coefficients", ok7)
assert f7 == [-1, -2, 1, 1] and ok7
print("2. primes leaving remainder 1 on division by 3, two roads")
scan = [q for q in primes(50) if q % 3 == 1]
found = sorted({q for a in range(1, 13) for q in primes(200) if (a * a + a + 1) % q == 0 and q != 3})
print("by scanning:", scan, "; prime factors of a^2+a+1, a = 1..12:", found)
assert all(q % 3 == 1 for q in found) and set(scan) <= set(found)
print("3. the group Z/3 x Z/3 from the 91st roots of unity, 91 = 7 x 13")
cube13 = {x ** 3 % 13 for x in range(1, 13)}
H = [k for k in range(1, 91) if k % 7 in H7 and k % 13 in cube13 and k % 7 and k % 13]
u, reps, roots, f, ok = period_poly(91, H)
print("cubes mod 13:", sorted(cube13), "; subgroup H has", len(H), "members:", H)
print("units mod 91:", len(u), "; index", len(u) // len(H), "; coset representatives", reps)
print("conjugates:", " ".join(f"{r:.6f}" for r in roots))
print("polynomial:", show(f), "; integer coefficients", ok)
coset = {g * h % 91: i for i, g in enumerate(reps) for h in H}
perms = {tuple(coset[k * g % 91] for g in reps) for k in u}   # where sigma_k sends each root
def comp(a, b): return tuple(a[i] for i in b)
idp = tuple(range(9))
commute = all(comp(a, b) == comp(b, a) for a in perms for b in perms)
cubed = all(comp(a, comp(a, a)) == idp for a in perms)
print("distinct permutations of the 9 roots:", len(perms), "; all commute", commute, "; every one cubed is the identity", cubed)
assert len(perms) == 9 and commute and cubed
assert all(abs(sum(c * r ** i for i, c in enumerate(f))) < 1e-6 for r in roots)
counts, bad, agree = {}, [], True
for q in primes(1000):
    pat = pattern(f, q)
    if pat is None: bad.append(q); continue
    counts[pat] = counts.get(pat, 0) + 1
    agree &= pat == ((1,) * 9 if q % 91 in H else (3, 3, 3))
n = sum(counts.values())
print("primes below 1000 with a repeated root mod p:", bad, "; primes used", n)
for pat, c in sorted(counts.items()):
    print(f"pattern {pat}: {c} primes, share {c / n:.3f}; predicted {'1/9 = 0.111' if pat[0] == 1 else '8/9 = 0.889'}")
print("every pattern matches 'splits exactly when p mod 91 is in H':", agree)
assert agree and bad == [2, 3, 7, 13, 281]
cubes1 = lambda m: sum(1 for x in range(1, m) if x ** 3 % m == 1)
print("solutions of x^3 = 1: mod 91", cubes1(91), "; mod 49", cubes1(49))
assert cubes1(91) == 9 and cubes1(49) == 3
print("4. S5 among the trinomials x^5 + ax + b, a and b from -3 to 3, not 0")
small, s5, rootd = primes(200), [], []
def s5_proof(f5):                             # a 5-cycle, and a swap: (2, 1, 1, 1), or (3, 2) cubed
    pats = [pattern(f5, q) for q in small]
    return (5,) in pats and ((2, 1, 1, 1) in pats or (3, 2) in pats)
for a in [-3, -2, -1, 1, 2, 3]:
    for b in [-3, -2, -1, 1, 2, 3]:
        f5 = [b, a, 0, 0, 0, 1]
        if any(sum(c * x ** i for i, c in enumerate(f5)) == 0 for x in range(-3, 4)): rootd.append((a, b)); continue
        if s5_proof(f5): s5.append((a, b))
print("trinomials 36; with a whole-number root", len(rootd), rootd)
print("proved S5 by primes below 200:", len(s5), "; not settled by those primes:",
      [ab for ab in [(a, b) for a in [-3, -2, -1, 1, 2, 3] for b in [-3, -2, -1, 1, 2, 3]] if ab not in s5 and ab not in rootd])
q5 = [q for q in small if pattern([-1, -1, 0, 0, 0, 1], q) == (5,)][0]
q2 = [q for q in small if pattern([-1, -1, 0, 0, 0, 1], q) in ((2, 1, 1, 1), (3, 2))][0]
P = 10 ** 9 + 7                               # a large prime, so mod P is exact for these small numbers
fac1 = pmul([1, 1, 1], [1, 0, -1, 1], P) == [1, 1, 0, 0, 0, 1]
fac2 = pmul([1, -1, 1], [-1, 0, 1, 1], P) == [P - 1, 1, 0, 0, 0, 1]
print("x^5 + x + 1 = (x^2 + x + 1)(x^3 - x^2 + 1):", fac1, "; x^5 + x - 1 = (x^2 - x + 1)(x^3 + x^2 - 1):", fac2)
assert fac1 and fac2
print("x^5 - x - 1: first pattern (5) at p =", q5, "; first transposition source at p =", q2,
      pattern([-1, -1, 0, 0, 0, 1], q2))
assert (-1, -1) in s5 and q5 == 3 and q2 == 2 and len(s5) == 26
d5 = [12, -5, 0, 0, 0, 1]
seen5 = sorted({pattern(d5, q) for q in primes(2000)} - {None})
print("x^5 - 5x + 12: discriminant", 5 ** 5 * 12 ** 4 + 4 ** 4 * (-5) ** 5, "= 8000^2; patterns below 2000:", seen5)
assert seen5 == [(1, 1, 1, 1, 1), (2, 2, 1), (5,)]
assert not s5_proof(d5)                       # it has a 5-cycle but no swap, so the S5 test must fail
print("5. what breaks")
cube7 = pmul(pmul([-2, 1], [-2, 1], 7), [-2, 1], 7) == [x % 7 for x in [-1, -2, 1, 1]]
print("x^3 - 2 mod 5:", pattern([-2, 0, 0, 1], 5), "; x^3 + x^2 - 2x - 1 mod 7 is (x - 2)^3:", cube7)
assert pattern([-2, 0, 0, 1], 5) == (2, 1) and cube7
print("ALL CHECKS PASS")
