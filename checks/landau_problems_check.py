# Landau's four problems, the status card -- the check behind it.  Standard library only.
# One sieve of Eratosthenes to 1,000,003 gives the counts; trial division, the gap
# argument and an algebraic identity reach each count a second, independent way.
import math
X = 1_000_003                                      # the first prime past 10^6
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0
for p in range(2, 1001):
    if flag[p]:
        flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(2, X + 1) if flag[p]]
def by_division(n):                                # road two: trial division
    d = 2
    while d * d <= n and n % d: d += 1
    return n > 1 and d * d > n
def factor(n):
    out, d = [], 2
    while d * d <= n:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out + ([n] if n > 1 else [])
def between(a, b): return [m for m in range(a + 1, b) if flag[m]]   # strictly between
# The example: Legendre at n = 100, between 10,000 and 10,201
inside = between(100**2, 101**2)
print(f"primes between 10000 and 10201: {len(inside)}; first {inside[0]}, last {inside[-1]}")
for m in range(10001, 10007, 2): print(f"{m} = {' x '.join(map(str, factor(m)))}")
small = [p for p in primes if p < 101]
rems = [10007 % p for p in small]
print(f"10007 by the {len(small)} primes up to 97: smallest remainder {min(rems)}; 101 x 101 = {101 * 101}")
expect = sum(1 / math.log(m) for m in range(10001, 10201))
print(f"expected count, sum of 1/log m from 10001 to 10200: {expect:.1f}")
for n in range(96, 105):
    c = len(between(n * n, (n + 1) ** 2))
    print(f"bar n = {n:>3} {n * n:>6} to {(n + 1) ** 2:>6} {'#' * c} {c}")
# Legendre for n = 1 to 999: road one counts directly, road two is the gap argument
direct = all(between(n * n, (n + 1) ** 2) for n in range(1, 1000))
gap = max((b - a, a) for a, b in zip(primes, primes[1:]) if a < 10**6)
start = (gap[0] - 3) // 2 + 1                       # a failure at n needs a gap >= 2n + 3
hold = all(any(by_division(m) for m in range(n * n + 1, (n + 1) ** 2)) for n in range(1, start))
print(f"Legendre n = 1 to 999 counted directly: {direct}; largest gap below 10^6: {gap[0]} after {gap[1]:,}")
print(f"gap argument: n >= {start} needs a gap >= {2 * start + 3}, none below 10^6; n = 1 to {start - 1} by trial division: {hold}")
print(f"at n = 100 a failure needs a gap of at least {2 * 100 + 3}")
print(f"quoted gap record 1476 below 4e18: n >= {(1476 - 3) // 2 + 1} safe up to n + 1 = {math.isqrt(4 * 10**18):,}")
print(f"0.525 window equals 2 sqrt x at x = 2^40 = {2**40:,}")
print(f"Ingham 1937: exponent 5/8 = {5 / 8:.3f} < 2/3 = {2 / 3:.3f}, enough for cubes; squares need 1/2 = {1 / 2:.3f}")
print("quoted record, by year published: Goldbach checked to 4e18 (2014); bounded gaps 70000000 (2014), 600 (2015), 246 (2014)")
# What Legendre does not say: Bertrand (proved) and Oppermann (stronger, open)
print(f"Bertrand, between 100 and 200: {len(between(100, 200))} primes")
lo, hi = between(10000, 10100), between(10100, 10201)
opp = all(between(n * n, n * n + n) and between(n * n + n, (n + 1) ** 2) for n in range(2, 1000))
print(f"Oppermann at n = 100: {len(lo)} below 10100, {len(hi)} above; both halves hold for n = 2 to 999: {opp}")
print(f"boundary cases: primes between 1 and 2: {len(between(1, 2))}; whole numbers between 0 and 1: {len(range(1, 1))}")
# Goldbach: 10,000 as p + q, two roads; every even m from 4 to 10^6
pairs = [p for p in primes if p <= 5000 and flag[10000 - p]]
pairs2 = [p for p in range(2, 5001) if by_division(p) and by_division(10000 - p)]
worst = max((next(p for p in primes if flag[m - p]), m) for m in range(4, 10**6 + 1, 2))
print(f"10000 = p + q with p <= q: {len(pairs)} ways by sieve, {len(pairs2)} by division; smallest {pairs[0]} + {10000 - pairs[0]}")
print(f"Goldbach for every even m from 4 to 1,000,000: yes; hardest m = {worst[1]:,} needs p = {worst[0]}")
# Twin primes in the example interval, and below 10^6
tw = [p for p in inside if flag[p + 2] and p + 2 < 10201]
tw2 = [p for p in range(10001, 10199, 2) if by_division(p) and by_division(p + 2)]
twins = sum(1 for p in primes if p + 2 < 10**6 and flag[p + 2])
print(f"twin pairs inside 10000 to 10201: {', '.join(f'({p}, {p + 2})' for p in tw)}; by division {len(tw2)}")
print(f"twin pairs below 10^6: {twins:,}")
# n^2 + 1: the example's first number is 100^2 + 1
f1 = factor(10001)
hits = [n for n in range(1, 1001) if flag[n * n + 1]]
hits2 = [n for n in range(1, 1001) if by_division(n * n + 1)]
print(f"100^2 + 1 = 10001 = {f1[0]} x {f1[1]}; remainders on division by 4: {f1[0] % 4}, {f1[1] % 4}")
print(f"n^2 + 1 prime for n = 1 to 1000: {len(hits)} by sieve, {len(hits2)} by division; last {hits[-1]}")
sq = [n for n in range(1, 1001) if flag[n * n - 1]]
print(f"n^2 - 1 = (n - 1)(n + 1) prime for n = 1 to 1000: {len(sq)}, at n = {sq[0]}")
print(f"largest prime factor of 10001: {max(f1)}; 100^1.279 = {100**1.279:.0f}")
assert inside[0] == 10007 and all(by_division(m) for m in inside) and not any(by_division(m) for m in range(10001, 10007))
assert len(inside) == sum(by_division(m) for m in range(10001, 10201)) and 0 not in rems
assert direct and hold and gap == (114, 492113) and opp and not between(1, 2)
assert 2 * start + 1 <= gap[0] < 2 * start + 3          # start is the first n the gap table clears
assert pairs == pairs2 and worst == (523, 503222) and twins == 8169
assert tw == tw2 and tw[0] == 10007 and len(tw) == 5
assert hits == hits2 and len(hits) == 112 and sq == [2] and f1 == [73, 137]
print("ALL CHECKS PASS")
