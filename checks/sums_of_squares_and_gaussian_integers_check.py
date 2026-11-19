# Two squares -- the check behind the card.  Standard library only.  The pair
# (a, b) stands for the Gaussian integer a + bi, where i times i is -1.
# Road 1 searches every pair of squares.  Road 2 counts divisors by remainder
# mod 4.  Road 3 reads the Gaussian factorisation from the prime exponents.
# For a prime p = 1 mod 4, a square root of -1 mod p and a Gaussian gcd build
# a + bi directly; a search confirms it.  Evidence runs to the stated limits.
from math import isqrt, pi
N, PMAX, R = 2000, 10000, 100
CASES = [101, 103, 2, 21, 25, 45, 65, 1105]

def mul(z, w): return (z[0] * w[0] - z[1] * w[1], z[0] * w[1] + z[1] * w[0])
def norm(z): return z[0] * z[0] + z[1] * z[1]
def rnd(u, d): return (2 * u + d) // (2 * d)          # nearest whole number to u/d
def ggcd(z, w, steps):                                # Euclid's algorithm in Z[i]
    while w != (0, 0):
        t = mul(z, (w[0], -w[1])); d = norm(w)
        q = (rnd(t[0], d), rnd(t[1], d))
        qw = mul(q, w); r = (z[0] - qw[0], z[1] - qw[1])
        assert 2 * norm(r) <= d                       # nearest rounding halves the norm
        steps.append((z, w, q, r)); z, w = w, r
    return z
def first_quadrant(z):                                # the associate with a > 0, b >= 0
    while not (z[0] > 0 and z[1] >= 0): z = (-z[1], z[0])
    return z
def factor(n):
    out, p = [], 2
    while p * p <= n:
        e = 0
        while n % p == 0: n //= p; e += 1
        if e: out.append((p, e))
        p += 1
    if n > 1: out.append((n, 1))
    return out
def r2_search(n):                                     # road 1: every (a, b), signs and order
    count = 0
    for a in range(-isqrt(n), isqrt(n) + 1):
        b2 = n - a * a; b = isqrt(b2)
        if b * b == b2: count += 1 if b == 0 else 2
    return count
def d13(n):                                           # divisors leaving 1, and 3, mod 4
    d1 = d3 = 0
    for d in range(1, n + 1):
        if n % d == 0:
            if d % 4 == 1: d1 += 1
            if d % 4 == 3: d3 += 1
    return d1, d3
def r2_divisors(n): d1, d3 = d13(n); return 4 * (d1 - d3)   # road 2
def r2_gauss(n):                                      # road 3: split each p^e between a+bi, a-bi
    ways = 4
    for p, e in factor(n):
        if p % 4 == 1: ways *= e + 1
        if p % 4 == 3 and e % 2 == 1: return 0
    return ways
def two_squares(p):                                   # p = 1 mod 4: build a + bi from scratch
    c = 2
    while pow(c, (p - 1) // 2, p) != p - 1: c += 1    # c is not a square mod p
    x = pow(c, (p - 1) // 4, p)                       # x * x = -1 mod p
    steps = []
    return x, first_quadrant(ggcd((p, 0), (x, 1), steps)), steps, c

x, g, steps, c = two_squares(101)
wil = 1
for k in range(1, 51): wil = wil * k % 101            # Wilson road: 50! mod 101
print(f"101 = 4 x {101 // 4} + {101 % 4}; 103 = 4 x {103 // 4} + {103 % 4}")
print(f"101: c = {c} is no square mod 101, x = {c}^25 mod 101 = {x}, x*x + 1 = {x * x + 1} = 101 x {(x * x + 1) // 101}")
print(f"101: Wilson road, 50! mod 101 = {wil}, and {wil}^2 + 1 = {wil * wil + 1} = 101 x {(wil * wil + 1) // 101}")
steps2 = []
g2 = first_quadrant(ggcd((101, 0), (wil, 1), steps2))
for label, xx, st, gg in (("x = 10", x, steps, g), ("x = 91", wil, steps2, g2)):
    for z, w, q, r in st: print(f"gcd step, {label}: {z} = {q} x {w} + {r}")
    print(f"101: gcd(101, {xx} + i) is {gg[0]} + {gg[1]}i up to a unit, norm {gg[0]}^2 + {gg[1]}^2 = {norm(gg)}")
sq = mul((10, 1), (10, 1))
print(f"(10 + i)^2 = {sq[0]} + {sq[1]}i, so {sq[0]}^2 + {sq[1]}^2 = {norm(sq)} = 101^2 = {101 * 101}")
print(f"103: 103 mod 4 = {103 % 4}; 103 - a^2 for a = 0..10: {[103 - a * a for a in range(11)]}")
print("n, factors, d1, d3, r2 by search, by divisors, by Gaussian exponents")
for n in CASES:
    d1, d3 = d13(n)
    print(f"{n}, {' '.join(f'{p}^{e}' for p, e in factor(n))}, {d1}, {d3}, {r2_search(n)}, {r2_divisors(n)}, {r2_gauss(n)}")
pts = sorted((a, b) for a in range(-11, 12) for b in range(-11, 12) if a * a + b * b == 101)
print(f"points with a^2 + b^2 = 101: {pts}")
print(f"points with a^2 + b^2 = 103: {[(a, b) for a in range(-11, 12) for b in range(-11, 12) if a * a + b * b == 103]}")
print(f"points with a^2 + b^2 = 45: {[(a, b) for a in range(-11, 12) for b in range(-11, 12) if a * a + b * b == 45]}")
agree = sum(1 for n in range(1, N + 1) if r2_search(n) == r2_divisors(n) == r2_gauss(n))
print(f"three roads agree for n = 1 to {N}: {agree} of {N}")
sieve = [True] * (PMAX + 1); sieve[0] = sieve[1] = False
for i in range(2, isqrt(PMAX) + 1):
    if sieve[i]: sieve[i * i::i] = [False] * len(sieve[i * i::i])
ones = [p for p in range(3, PMAX + 1) if sieve[p] and p % 4 == 1]
threes = [p for p in range(3, PMAX + 1) if sieve[p] and p % 4 == 3]
built = sum(1 for p in ones if norm(two_squares(p)[1]) == p and r2_search(p) == 8)
missed = sum(1 for p in threes if r2_search(p) == 0)
print(f"odd primes to {PMAX}: {len(ones)} are 1 mod 4, gcd road builds a + bi for {built}, search finds 8 points each")
print(f"odd primes to {PMAX}: {len(threes)} are 3 mod 4, search finds no point for {missed}")
last = two_squares(ones[-1])[1]
print(f"largest such prime below {PMAX}: {ones[-1]} = {last[0]}^2 + {last[1]}^2")
z5 = [(a, b) for a in range(0, 3) for b in range(0, 2) if a * a + 5 * b * b == 3]
print(f"Z[root -5]: 1^2 + 5 = 6 = 3 x 2, so 3 divides x^2 + 5 at x = 1, yet a^2 + 5b^2 = 3 has solutions {z5}")
print(f"what breaks: only a >= b >= 0 counts {len([1 for a, b in pts if a >= b >= 0])} for 101; "
      f"d1 - d3 without the 4 gives {d13(101)[0] - d13(101)[1]}; 4 x d1 for 45 gives {4 * d13(45)[0]}; 21 mod 4 = {21 % 4} yet r2(21) = {r2_search(21)}")
lattice = sum(2 * isqrt(R * R - a * a) + 1 for a in range(-R, R + 1))
summed = 1 + sum(r2_divisors(n) for n in range(1, R * R + 1))
print(f"circle radius {R}: lattice points {lattice}, 1 + sum of r2(n) to {R * R} = {summed}, pi x {R * R} = {pi * R * R:.4f}, gap {lattice - pi * R * R:.4f}")
print(f"figure, radius^2 101 and 103, radius {101 ** 0.5:.4f} and {103 ** 0.5:.4f}, points {pts}")
assert x * x % 101 == 100 and wil * wil % 101 == 100 and norm(g) == norm(g2) == 101 and {g, g2} <= {(10, 1), (1, 10)}
assert norm(sq) == 101 * 101 and sq == (99, 20)
assert agree == N and r2_search(101) == 8 and r2_search(103) == 0 and r2_search(45) == 8 and r2_search(65) == 16 and r2_gauss(1105) == 32
assert built == len(ones) == 609 and missed == len(threes) == 619
assert z5 == [] and lattice == summed and abs(lattice - pi * R * R) < 2 * pi * R
print("ALL CHECKS PASS")
