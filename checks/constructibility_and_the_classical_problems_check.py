# Straightedge and compass -- the check behind the card.  Standard library only;
# math gives cos, sqrt, pi and gcd as tools.  Every number on the card is printed here.
# Roads: (1) phi(n) a power of 2 against (2) n = a power of 2 times distinct Fermat
# primes, for every n to 1000; (3) exact minimal polynomials, proved irreducible by
# reduction mod a prime; (4) the 17-gon's cosine by square roots against cosine sums.
import math

def is_prime(m):
    return m > 1 and all(m % d for d in range(2, math.isqrt(m) + 1))

def phi(n):                                  # road 1 counts what shares no factor with n
    return sum(1 for k in range(1, n + 1) if math.gcd(k, n) == 1)

def pow2(m):
    return m > 0 and m & (m - 1) == 0

FERMAT = [2 ** (2 ** j) + 1 for j in range(5)]

def gauss_wantzel(n):                        # road 2: strip the 2s, then each Fermat prime once
    while n % 2 == 0:
        n //= 2
    for p in FERMAT:
        if n % p == 0:
            n //= p
    return n == 1

def padd(a, b):                              # polynomials: integer lists, constant term first
    a, b = a + [0] * (len(b) - len(a)), b + [0] * (len(a) - len(b))
    return [x + y for x, y in zip(a, b)]

def pmul(a, b):
    out = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] += x * y
    return out

def divide(f, g, p=0):                       # f by monic g; p = 0 means exact, over the integers
    f, q = f[:], [0] * (len(f) - len(g) + 1)
    for i in range(len(f) - len(g), -1, -1):
        c = f[i + len(g) - 1] % p if p else f[i + len(g) - 1]
        q[i] = c
        for j, y in enumerate(g):
            f[i + j] -= c * y
    return q, [x % p for x in f[:len(g) - 1]] if p else f[:len(g) - 1]

def cyclotomic(n):                           # x^n - 1 with every smaller divisor's factor removed
    f = [-1] + [0] * (n - 1) + [1]
    for d in range(1, n):
        if n % d == 0:
            f = divide(f, cyclotomic(d))[0]
    return f

def twice_cos_poly(n):                       # z^-m times the cyclotomic polynomial, in x = z + 1/z
    c = cyclotomic(n)
    m = (len(c) - 1) // 2
    D = [[2], [0, 1]]                        # z^k + z^-k as a polynomial in x
    while len(D) <= m:
        D.append(padd(pmul([0, 1], D[-1]), [-v for v in D[-2]]))
    out = [c[m]]
    for k in range(1, m + 1):
        out = padd(out, [c[m + k] * v for v in D[k]])
    return out

def irreducible_mod(f, p):                   # no monic factor of degree 1 to d/2 over GF(p)
    d = len(f) - 1
    for k in range(1, d // 2 + 1):
        for code in range(p ** k):
            g = [code // p ** i % p for i in range(k)] + [1]
            if not any(divide(f, g, p)[1]):
                return False
    return True

def certificate(f):                          # the smallest prime that proves f irreducible
    return next(p for p in range(2, 60) if is_prime(p) and irreducible_mod(f, p))

def value(f, x):
    return sum(c * x ** i for i, c in enumerate(f))

def bisect(f, lo, hi):
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if value(f, lo) * value(f, mid) > 0 else (lo, mid)
    return lo

yn = lambda b: "yes" if b else "no"
print(f"Fermat numbers 2^(2^j) + 1, j = 0..4: {FERMAT}, all prime: {yn(all(map(is_prime, FERMAT)))}")
f5 = 2 ** 32 + 1
d5 = next(d for d in range(3, 10 ** 6, 2) if f5 % d == 0)
print(f"F5 = {f5} = {d5} x {f5 // d5}; product of the five Fermat primes = {math.prod(FERMAT)} = 2^32 - 1: {yn(math.prod(FERMAT) == 2 ** 32 - 1)}")
yes = [n for n in range(3, 21) if pow2(phi(n))]
no = [f"{n} (degree {phi(n) // 2})" for n in range(3, 21) if not pow2(phi(n))]
print(f"n = 3..20, buildable: {yes}")
print(f"n = 3..20, not: {', '.join(no)}")
agree = all(pow2(phi(n)) == gauss_wantzel(n) for n in range(3, 1001))
print(f"phi test and Fermat-prime test agree for every n = 3..1000: {yn(agree)}")
print(f"buildable n-gons up to 100: {sum(gauss_wantzel(n) for n in range(3, 101))}; up to 1000: {sum(gauss_wantzel(n) for n in range(3, 1001))}")

quartic = [2, -4, 0, 0, 1]
r1, r2 = bisect(quartic, 0, 1), bisect(quartic, 1, 2)
cases = [("x^3 - 2, side of the doubled cube", [-2, 0, 0, 1], 2 ** (1 / 3)),
         ("x^3 - 3x - 1, twice cos 20 deg", [-1, -3, 0, 1], 2 * math.cos(math.pi / 9)),
         ("x^4 - 2, the house example", [-2, 0, 0, 0, 1], math.sqrt(math.sqrt(2))),
         ("x^4 - 4x + 2", quartic, r1)]
cases += [(f"twice cos(360/{n})", twice_cos_poly(n), 2 * math.cos(2 * math.pi / n)) for n in (7, 9, 11, 13, 17)]
print("polynomial (top power first) | irreducible mod p | degree | power of 2 | root")
for name, f, x in cases:
    p, d = certificate(f), len(f) - 1
    assert abs(value(f, x)) < 1e-9                         # the number really is a root
    print(f"{name}: {f[::-1]} | p = {p} | {d} | {yn(pow2(d))} | {x:.6f}")
    if name.startswith("twice cos"):
        n = int(name[14:-1])
        assert d == phi(n) // 2 and pow2(d) == gauss_wantzel(n)   # exact degree = phi(n)/2
w12 = [p for p in range(2, 60) if is_prime(p) and irreducible_mod([1, 0, -1, 0, 1], p)]  # the converse fails
print(f"x^4 - x^2 + 1 (twelfth roots of 1): primes below 60 where it has no factor mod p: {w12}")
assert w12 == [] and not any(irreducible_mod(pmul([-2, 0, 1], [-3, 0, 1]), p) for p in (2, 3, 5, 7, 11))  # a known product
print(f"cos 20 deg = {math.cos(math.pi / 9):.6f}; side of a square of area pi = {math.sqrt(math.pi):.6f}")

s17 = math.sqrt(17)                          # road 4a: the 17-gon by four square roots
A, B = (-1 + s17) / 2, (-1 - s17) / 2
A1, B1 = (A + math.sqrt(A * A + 4)) / 2, (B + math.sqrt(B * B + 4)) / 2
c17 = (A1 + math.sqrt(A1 * A1 - 4 * B1)) / 4
print(f"square-root road: sqrt 17 = {s17:.6f}, A = {A:.6f}, B = {B:.6f}, A1 = {A1:.6f}, B1 = {B1:.6f}, c = {c17:.6f}")
powers = [pow(3, k, 17) for k in range(16)]  # road 4b: 3 runs through all 16 remainders
print(f"powers of 3 mod 17 reach all 16 nonzero remainders: {yn(sorted(powers) == list(range(1, 17)))}")
for size in (8, 4, 2):
    H = sorted(powers[::16 // size])
    eta = sum(math.cos(2 * math.pi * h / 17) for h in H)
    print(f"subgroup of size {size}: {H}, cosine sum {eta:.6f}")
    assert abs(eta - {8: A, 4: A1, 2: 2 * c17}[size]) < 1e-12   # two roads, one number
assert abs(c17 - 0.932472) < 5e-7

u = (r1 + r2) ** 2
roots = [t for d in (1, 2, 4, 8, 16) for t in (d, -d) if t ** 3 - 8 * t - 16 == 0]
print(f"x^4 - 4x + 2: real roots {r1:.6f}, {r2:.6f}; u = (sum)^2 = {u:.6f}")
print(f"u^3 - 8u - 16 at u is zero: {yn(abs(u ** 3 - 8 * u - 16) < 1e-9)}; whole-number roots of it: {roots}")
assert roots == [] and abs(u ** 3 - 8 * u - 16) < 1e-9
assert agree and len(yes) == 11 and d5 == 641 and all(map(is_prime, FERMAT)) and math.prod(FERMAT) == 2 ** 32 - 1
print("ALL CHECKS PASS")
