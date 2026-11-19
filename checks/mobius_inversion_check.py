# The Mobius function and inversion -- the check behind the card.  Only math
# is imported, for pi as an outside value and for isqrt.  The examples are a
# dial of 60 marks and the house number 720720 = 2^4 x 3^2 x 5 x 7 x 11 x 13.
import math

N = 10_000                                       # every claim is also checked for n up to N

def gcd(a, b):                                   # Euclid, written out here
    while b:
        a, b = b, a % b
    return a

def primes_of(n):                                # trial division: {prime: exponent}
    out, p = {}, 2
    while p * p <= n:
        while n % p == 0:
            out[p], n = out.get(p, 0) + 1, n // p
        p += 1
    if n > 1:
        out[n] = out.get(n, 0) + 1
    return out

def mu(n):                                       # 0 on a repeated prime, else (-1)^(prime count)
    e = list(primes_of(n).values())
    return 0 if any(k > 1 for k in e) else (-1) ** len(e)

def divisors(n):                                 # pairs d and n/d, with d up to the square root
    small = [d for d in range(1, math.isqrt(n) + 1) if n % d == 0]
    return sorted(set(small + [n // d for d in small]))

def phi_count(n):                                # road 1, the definition: count k <= n with gcd 1
    return sum(1 for k in range(1, n + 1) if gcd(k, n) == 1)

def phi_mobius(n):                               # road 2, Mobius inversion of n = sum of phi(d)
    return sum(mu(d) * (n // d) for d in divisors(n))

def phi_product(n):                              # road 3, n times (1 - 1/p) for each prime p
    v = n
    for p in primes_of(n):
        v = v // p * (p - 1)
    return v

def loop_length(k, n):                           # step a pointer k marks at a time; count ticks home
    pos, t = k % n, 1
    while pos != 0:
        pos, t = (pos + k) % n, t + 1
    return t

divs = [[] for _ in range(N + 1)]                # divisor lists up to N, by a sieve
for d in range(1, N + 1):
    for m in range(d, N + 1, d):
        divs[m].append(d)
MU = [0] + [mu(n) for n in range(1, N + 1)]
peel = [0] * (N + 1)                             # road 4: phi(n) = n minus phi of smaller divisors
for n in range(1, N + 1):
    peel[n] = n - sum(peel[d] for d in divs[n][:-1])
via_mu = [0] + [sum(MU[d] * (n // d) for d in divs[n]) for n in range(1, N + 1)]
assert all(sum(MU[d] for d in divs[n]) == (n == 1) for n in range(1, N + 1))     # mu * 1 = epsilon
assert all(peel[n] == via_mu[n] == phi_product(n) for n in range(1, N + 1))     # inversion, n <= N
assert all(phi_count(n) == peel[n] for n in range(1, 1001))                     # Gauss, n <= 1000
print(f"checked n = 1..{N}: mu sums to 1 at n = 1 and 0 after; peeling = inversion = product")
print(f"checked n = 1..1000: the gcd count equals all three")

D = divisors(60)
tally = {}
for k in range(1, 61):
    tally[loop_length(k, 60)] = tally.get(loop_length(k, 60), 0) + 1
tours = [k for k in range(1, 61) if loop_length(k, 60) == 60]
print(f"divisors of 60: {D}")
print(f"jumps 1..60 sorted by loop length d: {[tally[d] for d in D]}")
print(f"phi(d) for the same d, by gcd count: {[phi_count(d) for d in D]}; total {sum(phi_count(d) for d in D)}")
print(f"jumps that visit all 60 marks: {tours}")
print(f"jump 7 comes home after {loop_length(7, 60)} ticks; jump 6 after {loop_length(6, 60)}")
print(f"mu(d) on the divisors of 60: {[mu(d) for d in D]}")
terms = [mu(d) * (60 // d) for d in D if mu(d) != 0]
print(f"inversion terms mu(d) x 60/d: {terms}; sum {sum(terms)}")
print(f"product form: 60 x 1/2 x 2/3 x 4/5 = {phi_product(60)}; gcd count {phi_count(60)}")
assert [tally[d] for d in D] == [phi_count(d) for d in D] and len(tours) == phi_mobius(60) == 16

H = 720720
DH = divisors(H)
sq = [d for d in DH if mu(d) != 0]
print(f"720720 = {primes_of(H)}: {len(DH)} divisors, {len(sq)} squarefree")
print(f"sum of phi(d) over its divisors: {sum(phi_product(d) for d in DH)}")
print(f"phi(720720): inversion {phi_mobius(H)}, product {phi_product(H)}, gcd count {phi_count(H)}")
assert sum(phi_product(d) for d in DH) == H and phi_mobius(H) == phi_count(H) == 138240

T = [0] * (N + 1)                                # T(x): the running total of phi up to x
for n in range(1, N + 1):
    T[n] = T[n - 1] + peel[n]
for x in (60, 1000, N):
    gauss = sum(T[x // n] for n in range(1, x + 1))
    inv = sum(MU[n] * (x // n) * (x // n + 1) // 2 for n in range(1, x + 1))
    main_term = 3 * x * x / math.pi ** 2
    print(f"x = {x}: T(x) = {T[x]}; inverted {inv}; sum of T(x/n) = {gauss} = x(x+1)/2; "
          f"T(x)/(3x^2/pi^2) = {T[x] / main_term:.6f}; T(x) - 3x^2/pi^2 = {T[x] - main_term:.2f}")
    assert inv == T[x] and gauss == x * (x + 1) // 2

def prime_behind(n):                             # product form: n = product of r(d) over d | n
    num = den = 1
    for d in divisors(n):
        if mu(d) == 1:
            num *= n // d
        elif mu(d) == -1:
            den *= n // d
    assert num % den == 0
    return num // den
print(f"r(n) for n = 1..12 from the product form: {[prime_behind(n) for n in range(1, 13)]}")
assert all(prime_behind(n) == (list(primes_of(n))[0] if len(primes_of(n)) == 1 else 1)
           for n in range(1, 2001))

def is_primitive(s, n):                          # an n-bit string that is no shorter block repeated
    return all(s != int(format(s, f"0{n}b")[:d] * (n // d), 2) for d in divisors(n)[:-1])

def has_factor(f):                               # a degree-8 polynomial over GF(2), as bits
    for g in range(2, 32):                       # every polynomial of degree 1 to 4
        a = f
        while a.bit_length() >= g.bit_length():
            a ^= g << (a.bit_length() - g.bit_length())
        if a == 0:
            return True
    return False
prim = sum(1 for s in range(256) if is_primitive(s, 8))
irred = sum(1 for f in range(256, 512) if not has_factor(f))
formula = sum(mu(d) * 2 ** (8 // d) for d in divisors(8))
print(f"8-bit strings with no shorter repeat: brute force {prim}, inversion {formula}; "
      f"/8 = {formula // 8}; irreducible degree-8 over GF(2), brute force {irred}")
assert prim == formula == 240 and irred == formula // 8

omega = lambda n: sum(primes_of(n).values())
print(f"mistake 1, signs counting repeated primes: {sum((-1) ** omega(d) * (60 // d) for d in D)}, not 16")
print(f"mistake 2, signs dropped: {sum(60 // d for d in D if mu(d) != 0)}, not 16")
print(f"mistake 3, the term d = 1 left out: {sum(terms[1:])}, not 16")
print(f"mistake 4, phi(360) x phi(2002) = {phi_product(360)} x {phi_product(2002)} = "
      f"{phi_product(360) * phi_product(2002)}, not {phi_product(H)}")
print("ALL CHECKS PASS")
