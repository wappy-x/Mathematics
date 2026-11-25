# Artin reciprocity and the Hilbert class field, checked on K = Q(sqrt-5) (h = 2) and K = Q(sqrt-14) (h = 4).
# Class side: reduced forms and numbers x + y sqrt(-n). Field side: the Frobenius, read off a polynomial mod p.
from math import isqrt, sqrt

N = 10000; isp = [1] * N; isp[0] = isp[1] = 0
for i in range(2, 101):
    if isp[i]: isp[i * i::i] = [0] * len(isp[i * i::i])
P = [p for p in range(N) if isp[p]]
def red(a, b, c):                  # one reduced form per class: -a < b <= a <= c, b >= 0 when a = c
    while not (-a < b <= a <= c):
        k = (a - b) // (2 * a); b, c = b + 2 * a * k, a * k * k + b * k + c
        if c < a: a, b, c = c, -b, a
    return (a, -b, c) if a == c and b < 0 else (a, b, c)
def forms(D): return sorted({red(a, b, (b * b - D) // (4 * a)) for a in range(1, isqrt(-D // 3) + 1)
                             for b in range(-a + 1, a + 1) if (b * b - D) % (4 * a) == 0})
def cls(p, n):                     # the class of a prime ideal above p: the form (p, b, c) with b^2 - 4pc = -4n
    b = next(b for b in range(2 * p) if (b * b + 4 * n) % (4 * p) == 0); return red(p, b, (b * b + 4 * n) // (4 * p))
def reps(m, n): return [(isqrt(m - n * y * y), y) for y in range(isqrt(m // n) + 1) if isqrt(m - n * y * y) ** 2 == m - n * y * y]
def prim(m, n, p): return [(x, y) for x, y in reps(m, n) if x % p or y % p]   # x + y sqrt(-n) not a multiple of p
def leg(a, p): return {0: 0, 1: 1}.get(pow(a % p, (p - 1) // 2, p), -1)      # Euler's test
def sgn(s): return "+i" if s == 1 else "-i"

print("K = Q(sqrt-5): reduced forms of -20:", forms(-20), "; h =", len(forms(-20)), "; H = K(i), unramified, [H : K] = 2")
for p in (3, 7, 29, 41):           # Frobenius on i is i^p = (-1)^((p-1)/2) i; the class is read off the forms
    r = reps(p, 5); s = leg(-1, p)
    print(f"p = {p}: (-5/p) = {leg(-5, p)}, class {cls(p, 5)}, x^2 + 5y^2: {r[0] if r else 'none'}, i^p = {sgn(s)}, Artin symbol {s:+d}")
    assert leg(-5, p) == 1 and (s == 1) == bool(r) == (cls(p, 5) == (1, 0, 5))
gold = [t for t in range(2) if (t * t - t - 1) % 2 == 0]; i5 = [t for t in range(5) if (t * t + 1) % 5 == 0]
print("p-ideal over 2: class", cls(2, 5), "; roots of x^2 - x - 1 mod 2:", gold, "-> Frobenius moves (1 + sqrt5)/2, symbol -1")
print("p-ideal over 5: class", cls(5, 5), "; roots of x^2 + 1 mod 5:", i5, "-> Frobenius fixes i, symbol +1")
assert gold == [] and cls(2, 5) == (2, 2, 3) and len(i5) == 2 and cls(5, 5) == (1, 0, 5)
for a, b in ((3, 7), (3, 29)):
    print(f"ideal p{a} p{b}, norm {a * b}: symbol {leg(-1, a) * leg(-1, b):+d}; x^2 + 5y^2 = {a * b}: {reps(a * b, 5)}")
    assert (leg(-1, a) * leg(-1, b) == 1) == bool(reps(a * b, 5))
odd = {(a * a + 5 * b * b) % 4 for a in range(-50, 51) for b in range(-50, 51) if (a * a + 5 * b * b) % 2}
print("odd norms a^2 + 5b^2, |a|, |b| <= 50, leave remainder", sorted(odd), "mod 4: principal ideals get symbol +1")
assert odd == {1}
S5 = [p for p in P if p not in (2, 5) and leg(-5, p) == 1]
roadA = [p for p in S5 if reps(p, 5)]; roadB = [p for p in S5 if cls(p, 5) == (1, 0, 5)]; roadC = [p for p in S5 if leg(-1, p) == 1]
nonp = len([p for p in S5 if cls(p, 5) == (2, 2, 3) and leg(-1, p) == -1])
m20 = sorted({p % 20 for p in roadA})
print(f"split primes below 10,000: {len(S5)}; principal (x^2 + 5y^2) {len(roadA)}, symbol +1 {len(roadC)}, class (1, 0, 5) {len(roadB)}; remainders mod 20 {m20}; class (2, 2, 3) and symbol -1 {nonp}")
assert roadA == roadB == roadC and len(roadA) == 302 and m20 == [1, 9] and nonp == len(S5) - len(roadA)
def bar(label, k): print(f"{label:<30} {k:>3}  " + "#" * ((k + 10) // 20))   # one # per 20 primes, rounded
print("Q(sqrt-5), split primes below 10,000:", len(S5)); bar("class (1, 0, 5), symbol +1", len(roadA)); bar("class (2, 2, 3), symbol -1", nonp)

def pmul(u, v, p):                 # multiply polynomials mod p and mod f = x^4 + 2x^2 - 7, using x^4 = 7 - 2x^2
    r = [0] * 7
    for i in range(4):
        for j in range(4): r[i + j] += u[i] * v[j]
    for d in (6, 5, 4): c = r[d]; r[d] = 0; r[d - 4] += 7 * c; r[d - 2] -= 2 * c
    return [c % p for c in r[:4]]
def ppow(u, e, p):
    out = [1, 0, 0, 0]
    while e:
        if e & 1: out = pmul(out, u, p)
        u = pmul(u, u, p); e >>= 1
    return out
def frob(p):                       # the order of Frobenius: the least k with x^(p^k) = x mod (f, p)
    y = [0, 1, 0, 0]
    for k in range(1, 9):
        y = ppow(y, p, p)
        if y == [0, 1, 0, 0]: return k
def roots(p): return [t for t in range(p) if (t ** 4 + 2 * t * t - 7) % p == 0]
def corder(p): return next((k, prim(p ** k, 14, p)[0]) for k in range(1, 5) if prim(p ** k, 14, p))

al = sqrt(2 * sqrt(2) - 1)
print(f"K = Q(sqrt-14): reduced forms of -56: {forms(-56)} ; h = {len(forms(-56))} ; H = K(alpha), alpha = {al:.10f}, f(alpha) = 0 to 12 places: {'yes' if abs(al ** 4 + 2 * al * al - 7) < 1e-12 else 'no'}")
assert len(forms(-56)) == 4 and abs(al ** 4 + 2 * al * al - 7) < 1e-12
for p in (3, 5, 13, 23, 71):
    k, w = corder(p)
    print(f"p = {p}: (-14/p) = {leg(-14, p)}, class {cls(p, 14)}, class order {k} ({p}^{k} = {w[0]}^2 + 14 x {w[1]}^2), roots of f mod p {roots(p)}, Frobenius order {frob(p)}")
    assert k == frob(p)
f3 = [t ** 4 + 2 * t * t - 7 for t in range(3)]
print(f"p = 3: f(0), f(1), f(2) = {f3}, remainders mod 3 {[v % 3 for v in f3]}")
order = {(1, 0, 14): 1, (2, 0, 7): 2, (3, -2, 5): 4, (3, 2, 5): 4}
S14 = [p for p in P if p not in (2, 7) and leg(-14, p) == 1]
tally = {}
for p in S14:
    c = cls(p, 14); key = (c[0], abs(c[1]), c[2]); tally[key] = tally.get(key, 0) + 1
    assert order[c] == frob(p) and (c == (1, 0, 14)) == bool(reps(p, 14)) == bool(roots(p))
for c in sorted(tally): print(f"split primes below 10,000 in class ({c[0]}, {'±' if c[1] else ''}{c[1]}, {c[2]}): {tally[c]}, Frobenius order {order[c]} for every one")
print("Q(sqrt-14), split primes below 10,000:", len(S14))
for c, lab in (((1, 0, 14), "class (1, 0, 14), Frob order 1"), ((2, 0, 7), "class (2, 0, 7),  Frob order 2"), ((3, 2, 5), "class (3, ±2, 5), Frob order 4")): bar(lab, tally[c])
small = [p for p in S14 if p < 300]
assert all(corder(p)[0] == frob(p) for p in small)
print(f"split primes below 300: {len(small)}; class order (smallest power that is x^2 + 14y^2) = Frobenius order for all: yes")
X = [p for p in S14 if reps(p, 14)]; T = [p for p in S14 if roots(p)]
print(f"x^2 + 14y^2 below 10,000: {len(X)}; Hilbert class field test picks {len(T)}; first {X[:6]}")
assert X == T and len(X) == 145 and X[:2] == [23, 127]

bad = [p for p in P if p not in (2, 7) and leg(-14, p) == -1 and roots(p)]
print(f"what breaks: drop (-14/p) = 1: {len(bad)} more primes have a root, first {bad[:4]}; is {bad[0]} = x^2 + 14y^2? {'yes' if reps(bad[0], 14) else 'no'}")
w71 = [(x, y) for x in range(7) for y in range(4) if 2 * x * x + 7 * y * y == 71]
print(f"what breaks: test only the genus field K(sqrt2): 71 has (2/71) = {leg(2, 71)}, (-14/71) = {leg(-14, 71)}, yet x^2 + 14y^2 = 71: {reps(71, 14)}; 2x^2 + 7y^2 = 71 at {w71}")
disc = 16 * -7 * (2 * 2 - 4 * -7) ** 2      # discriminant of t^4 + a t^2 + b is 16 b (a^2 - 4b)^2
print(f"what breaks: keep the ramified 7: disc f = {disc} = -2^14 x 7: {'yes' if disc == -2 ** 14 * 7 else 'no'}; roots of f mod 7 {roots(7)}, x^2 + 14y^2 = 7: {reps(7, 14)}")
cube = [t for t in range(7) if (t ** 3 - 2) % 7 == 0]
print(f"what breaks: n = 27 with h(Q(sqrt-3)) = 1: 7 is 1 mod 3, yet x^2 + 27y^2 = 7: {reps(7, 27)}; cube roots of 2 mod 7: {cube}")
assert bad and not reps(bad[0], 14) and not reps(71, 14) and w71 == [(2, 3)] and roots(7) == [0] and not reps(7, 27) and not cube
print("ALL CHECKS PASS")
