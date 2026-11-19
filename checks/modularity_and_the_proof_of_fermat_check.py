# Modularity and the proof of Fermat -- the check behind the card.  Standard
# library only.  Part 1 builds the Frey curve y^2 = x(x - A)(x + B), A + B = C,
# for the stand-in 3^2 + 4^2 = 5^2: its discriminant three ways, its bad primes
# two ways.  Part 2 counts points on y^2 = x^3 - x mod every odd prime below 100
# and compares them with the coefficients of a modular form of level 32.
# Part 3 counts weight-2 forms of level N by the genus formula, two ways.
from fractions import Fraction
from math import gcd, prod

def primes_upto(n): return [p for p in range(2, n + 1) if all(p % d for d in range(2, p))]
def prime_factors(n): return [p for p in primes_upto(n) if n % p == 0]
def rad(n):
    out = 1
    for p in prime_factors(n): out *= p
    return out
def val(n, p):                                   # how many times p divides n
    k = 0
    while n % p == 0: n //= p; k += 1
    return k

# Part 1: the Frey curve.  Roots 0, A, -B; in expanded form x^3 + a2 x^2 + a4 x.
def disc_roots(A, B): return 16 * (A * B * (A + B)) ** 2      # differences A, B, A + B
def disc_coeffs(A, B):
    a2, a4 = B - A, -A * B
    return 16 * a4 ** 2 * (a2 ** 2 - 4 * a4)
def disc_long(a1, a2, a4):                       # y^2 + a1 xy = x^3 + a2 x^2 + a4 x: Delta, c4
    b2, b4, b8 = a1 * a1 + 4 * a2, 2 * a4, -a4 * a4
    return -b2 * b2 * b8 - 8 * b4 ** 3, b2 * b2 - 24 * b4
def meeting_roots(A, B, l):                      # road 1: compare the roots mod l
    r = [0, A % l, (-B) % l]
    return max(r.count(x) for x in r)
def singular_kind(A, B, l):                      # road 2: brute-force derivative test
    a2, a4 = B - A, -A * B
    for x in range(l):
        if (x ** 3 + a2 * x * x + a4 * x) % l == 0 and (3 * x * x + 2 * a2 * x + a4) % l == 0:
            return 3 if (3 * x + a2) % l == 0 else 2
    return 1
def bad_odd(A, B, bound):
    return [(l, singular_kind(A, B, l)) for l in primes_upto(bound)[1:] if singular_kind(A, B, l) > 1]

a, b, c, p = 3, 4, 5, 2
A, B = a ** p, b ** p
D = disc_roots(A, B)
print(f"stand-in: {a}^{p} + {b}^{p} = {c}^{p}; Frey curve y^2 = x(x - {A})(x + {B})")
print(f"root differences {A}, {B}, {A + B}; product {A * B * (A + B):,}; squared {(A * B * (A + B)) ** 2:,}")
print(f"discriminant from the roots: {D:,}")
print(f"discriminant from the coefficients: {disc_coeffs(A, B):,}")
print(f"16(abc)^(2p) = 16 x {a * b * c}^{2 * p} = {16 * (a * b * c) ** (2 * p):,}")
bad = bad_odd(A, B, 50)
print(f"odd primes below 50 where the curve is singular: {[l for l, k in bad]}")
print(f"roots meeting there: {[meeting_roots(A, B, l) for l, k in bad]} (2 = node, 3 = cusp)")
print(f"odd primes dividing abc = {a * b * c}: {prime_factors(a * b * c)[1:]}")
print(f"exponents of 3 and 5 in the discriminant: {val(D, 3)}, {val(D, 5)}; 2p x exponent in abc: "
      f"{2 * p * val(a * b * c, 3)}, {2 * p * val(a * b * c, 5)}")
pairs = [(x, y) for x in range(1, 61) for y in range(1, 61) if gcd(x, y) == 1]
same = all(disc_roots(x, y) == disc_coeffs(x, y) for x, y in pairs)
print(f"Delta = 16(ABC)^2 by both formulas for all {len(pairs):,} coprime pairs A, B up to 60: {'yes' if same else 'no'}")

# Part 2: points of y^2 = x^3 - x mod l against q * prod (1 - q^4n)^2 (1 - q^8n)^2.
def count_points(l, a2=0, a4=-1):                # y^2 = x^3 + a2 x^2 + a4 x mod l
    sq = [0] * l
    for y in range(l): sq[y * y % l] += 1
    return 1 + sum(sq[(x ** 3 + a2 * x * x + a4 * x) % l] for x in range(l))   # 1 for O
def q_product(parts, M):                         # q * prod of (1 - q^(m n))^k, to q^M
    f = [0] * (M + 1); f[0] = 1
    for m, k in parts:
        for step in [m * n for n in range(1, M // m + 1)] * k:
            for i in range(M, step - 1, -1): f[i] -= f[i - step]     # times 1 - q^step
    return [0] + f[:M]
M = 100
coef = q_product([(4, 2), (8, 2)], M)
odd = primes_upto(M)[1:]
ap = {l: l + 1 - count_points(l) for l in odd}
print("prime l | points mod l | a_l = l + 1 - points | q^l coefficient of the form")
for l in odd[:8]:
    print(f"{l:7} | {count_points(l):12} | {ap[l]:20} | {coef[l]:27}")
agree = sum(ap[l] == coef[l] for l in odd)
print(f"agreement for odd primes below {M}: {agree} of {len(odd)}")
print(f"primes 3 mod 4 with a_l = 0: {sum(ap[l] == 0 for l in odd if l % 4 == 3)} of {sum(l % 4 == 3 for l in odd)}")
f15 = q_product([(1, 1), (3, 1), (5, 1), (15, 1)], M)          # the level-15 newform
good = [l for l in odd if (a * b * c) % l]
twist = sum(l + 1 - count_points(l, B - A, -A * B) == (-1) ** (l // 2) * f15[l] for l in good)
print(f"stand-in: a_l = (-1)^((l-1)/2) x (q^l coefficient of the level-15 form), "
      f"odd primes below {M} not dividing abc: {twist} of {len(good)}")
print(f"so the stand-in, A = {A} = {A % 4} mod 4, fails the sign: level 16 x 15 = {16 * 15}, "
      f"not rad(abc) = {rad(a * b * c)}")
flip = sum(l + 1 - count_points(l, A - B, -A * B) == f15[l] for l in good)   # y^2 = x(x + A)(x - B)
D15, c4f = disc_long(1, (A - B - 1) // 4, -(A * B) // 16)       # flipped, after x = 4X, y = 8Y + 4X
print(f"flipped y^2 = x(x + {A})(x - {B}): a_l = q^l coefficient of the level-15 form, no sign: {flip} of {len(good)}")
print(f"its model at 2: discriminant {D15:,} = 3^{val(D15, 3)} x 5^{val(D15, 5)}, odd; "
      f"gcd(c4, discriminant) = {gcd(c4f, D15)}: level 15, 2 drops out")

# Part 3: the genus of X0(N) = number of independent weight-2 cusp forms of level N.
def phi(n): return sum(gcd(k, n) == 1 for k in range(1, n + 1))
def genus_formula(N):
    ps = prime_factors(N)
    mu = Fraction(N)
    for q in ps: mu *= Fraction(q + 1, q)
    n2 = 0 if N % 4 == 0 else prod([1 + (0 if q == 2 else 1 if q % 4 == 1 else -1) for q in ps])
    n3 = 0 if N % 9 == 0 else prod([1 + (0 if q == 3 else 1 if q % 3 == 1 else -1) for q in ps])
    cusps = sum(phi(gcd(d, N // d)) for d in range(1, N + 1) if N % d == 0)
    return int(mu), n2, n3, cusps
def genus_brute(N):                              # count P^1(Z mod N) and the two fixed-point equations
    mu = sum(gcd(gcd(x, y), N) == 1 for x in range(N) for y in range(N)) // phi(N)
    n2 = sum((x * x + 1) % N == 0 for x in range(N))
    n3 = sum((x * x + x + 1) % N == 0 for x in range(N))
    return mu, n2, n3
def genus(mu, n2, n3, cusps): return 1 + Fraction(mu, 12) - Fraction(n2, 4) - Fraction(n3, 3) - Fraction(cusps, 2)

G = {N: genus(*genus_formula(N)) for N in range(1, 51)}
roads = all(genus_formula(N)[:3] == genus_brute(N) for N in range(1, 51))
for N in [2, 11, 30, 32]:
    mu, n2, n3, cu = genus_formula(N)
    print(f"level {N:2}: index {mu}, nu2 {n2}, nu3 {n3}, cusps {cu} -> genus {G[N]}")
print(f"index, nu2, nu3 by formula and by brute count agree for N = 1 to 50: {'yes' if roads else 'no'}")
zero = [N for N in range(1, 51) if G[N] == 0]
print(f"levels up to 50 with no weight-2 cusp form: {zero}")
print(f"first level with a form: {min(N for N in G if G[N] > 0)}")

# What breaks
A2, B2 = 9 ** 2, 12 ** 2                         # 9, 12, 15 share the factor 3
D2, c42 = disc_long(0, B2 - A2, -A2 * B2)
print(f"mistake 1, common factor 9^2 + 12^2 = 15^2: roots meeting mod 3 = {meeting_roots(A2, B2, 3)}, "
      f"but v3(Delta) = {val(D2, 3)}, v3(c4) = {val(c42, 3)}: the equation is not minimal")
same3 = all(count_points(l, B2 - A2, -A2 * B2) == count_points(l, B - A, -A * B) for l in odd[1:])
print(f"   x = 9X, y = 27Y gives y^2 = x(x - {A2 // 9})(x + {B2 // 9}), the 3, 4, 5 curve: roots meeting mod 3 = "
      f"{meeting_roots(A2 // 9, B2 // 9, 3)}, a node; same point counts mod 5 to {odd[-1]}: {'yes' if same3 else 'no'}")
print(f"mistake 2, stopping at level rad(abc) = {rad(a * b * c)}: genus {G[30]}, so forms exist and nothing clashes")
print(f"mistake 3, discriminant taken as the level: {D:,} instead of {16 * 15}")

assert D == disc_coeffs(A, B) == 16 * (a * b * c) ** (2 * p) == 207360000 and same      # three roads
assert [l for l, k in bad] == prime_factors(a * b * c)[1:] and all(k == 2 for l, k in bad)
assert [meeting_roots(A, B, l) for l, k in bad] == [k for l, k in bad]                  # two roads
assert agree == len(odd) == 24 and ap[5] == -2 and twist == len(good) == 22             # modularity, evidence
assert roads and zero == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 16, 18, 25]            # quoted genus-0 list
assert G[11] == 1 and G[32] == 1 and G[30] == 3 and meeting_roots(A2, B2, 3) == singular_kind(A2, B2, 3) == 3
assert val(D2, 3) == 16 and val(c42, 3) == 4 and D2 == 3 ** 12 * D and same3 and meeting_roots(A2 // 9, B2 // 9, 3) == 2
assert flip == len(good) == 22 and D15 * 2 ** 12 == D and D15 == 3 ** 4 * 5 ** 4 and gcd(c4f, D15) == 1
print("ALL CHECKS PASS")
