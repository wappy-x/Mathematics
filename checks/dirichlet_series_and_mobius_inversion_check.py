# Dirichlet series and Mobius inversion -- the check behind the card.  Only
# math is imported, for pi as an outside value and for prod.  The example is the 12-hour
# clock: 12 = 2 x 2 x 3, with divisors 1, 2, 3, 4, 6, 12.
import math

def divisors(n):
    return [d for d in range(1, n + 1) if n % d == 0]

def factor(n):                         # trial division: {prime: exponent}
    out, p = {}, 2
    while n > 1:
        while n % p == 0:
            out[p], n = out.get(p, 0) + 1, n // p
        p += 1
    return out

def mu(n):                             # road 1: read the definition off the primes
    e = list(factor(n).values())
    return 0 if any(k > 1 for k in e) else (-1) ** len(e)

peel = {1: 1}                          # road 2: make each divisor sum of mu vanish past 1
for n in range(2, 13):
    peel[n] = -sum(peel[d] for d in divisors(n)[:-1])
euler = {1: 1}                         # road 3: expand (1 - 2^-s)(1 - 3^-s)(1 - 5^-s)(1 - 7^-s)
for p in (2, 3, 5, 7):
    euler.update({m * p: -c for m, c in list(euler.items())})
tau = lambda n: len(divisors(n))
sigma = lambda n: sum(divisors(n))
peeled = lambda g, n: g(n) - sum(peeled(g, d) for d in divisors(n)[:-1])   # undo by subtracting
moebius = lambda g, n: sum(mu(d) * g(n // d) for d in divisors(n))       # undo with mu weights
part = lambda c, s, N: sum(c(n) * n ** (-s) for n in range(1, N + 1))    # first N terms at s
one, ten = (lambda n: 1), range(1, 11)
pairs = len([(m, 12 // m) for m in divisors(12)])
formula = math.prod(e + 1 for e in factor(12).values())
print(f"divisors of 12: {divisors(12)}; pairs m x k = 12: {pairs}; (2+1)(1+1) = {formula}")
print(f"tau(4) x tau(3) = {tau(4)} x {tau(3)} = {tau(4) * tau(3)}; tau(2) x tau(2) = {tau(2) ** 2}, but tau(4) = {tau(4)}")
print(f"mu(1..10) from the primes:         {[mu(n) for n in ten]}")
print(f"mu(1..10) by peeling divisor sums: {[peel[n] for n in ten]}")
print(f"mu(1..10) from the Euler product:  {[euler.get(n, 0) for n in ten]}")
print(f"mu(6) = {mu(6)}, mu(12) = {mu(12)}; mu over the divisors of 12: {[mu(d) for d in divisors(12)]}, sum {sum(mu(d) for d in divisors(12))}")
for n in (6, 12):
    terms = [mu(d) * sigma(n // d) for d in divisors(n)]
    print(f"sigma({n}) = {sigma(n)}; mu-weighted sigmas {terms} sum to {sum(terms)}; peeling gives {peeled(sigma, n)}")
print("figure, partial sums of mu(n)/n^2, N = 1..10:", " ".join(f"{part(mu, 2, N):.2f}" for N in ten))
for N in (10, 100, 1000):
    z, m = part(one, 2, N), part(mu, 2, N)
    print(f"s = 2, N = {N:4}: zeta part {z:.6f} x mu part {m:.6f} = {z * m:.6f}")
print(f"6/pi^2 = {6 / math.pi ** 2:.6f}, the value 1/zeta(2) from Euler's pi^2/6")
w = part(one, 2 + 1j, 1000) * part(mu, 2 + 1j, 1000)
print(f"s = 2 + i, N = 1000: product {w.real:.6f} + {w.imag:.6f}i")
lam = lambda n: (-1) ** sum(factor(n).values())
print(f"mistake 1, signs counting repeated primes: sum over d | 4 = {sum(lam(d) for d in divisors(4))}, not 0")
print(f"mistake 2, coefficients multiplied, not convolved: 12^-s gets 1 x 1 = 1, not {pairs}")
cut = sum(mu(d) for d in divisors(12) if d <= 10 and 12 // d <= 10)
print(f"mistake 3, ten terms of each series multiplied: 12^-s gets {cut}, not 0")
assert [mu(n) for n in range(1, 13)] == [peel[n] for n in range(1, 13)]           # definition = inverse of 1
assert [mu(n) for n in ten] == [euler.get(n, 0) for n in ten]                     # = Euler product expanded
assert [moebius(sigma, n) for n in range(1, 13)] == list(range(1, 13))            # sigma inverts to n
assert abs(part(mu, 2, 1000) - 6 / math.pi ** 2) < 1 / 1000 and abs(w - 1) < 4 / 1000   # tails under 1/N
print("ALL CHECKS PASS")
