# Landau's four problems -- the check behind the card.  Standard library only.
# One sieve of Eratosthenes to 1,000,003 gives every count below; each count is
# reached a second, independent way: trial division, a gap argument, a twin
# sieve on two classes, or a sieve on the values n^2 + 1.
import math
X = 1_000_003                                      # 1,000,003: the first prime past 10^6
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0
for p in range(2, 1001):
    if flag[p]:
        flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(2, X + 1) if flag[p]]
small = [p for p in primes if p <= 1000]
def by_division(n):                                # road two: trial division
    d = 2
    while d * d <= n and n % d: d += 1
    return n > 1 and d * d > n
# Legendre: a prime strictly between n^2 and (n+1)^2, for n = 1 to 999
cnt = [sum(flag[n * n + 1:(n + 1) ** 2]) for n in range(1000)]
inside = [m for m in range(962, 1024) if flag[m]]
print("primes between 961 and 1024:", ", ".join(map(str, inside)), f"({len(inside)} of them)")
print("trial division of 967 by 2 to 31: remainders", [967 % p for p in small if p <= 31])
print("962 to 966:", ", ".join(f"{m} = {min(p for p in small if m % p == 0)} x {m // min(p for p in small if m % p == 0)}" for m in range(962, 967)))
expect = sum(1 / math.log(m) for m in range(962, 1024))
print(f"n = 31: expected {expect:.2f}; Brun-Titchmarsh ceiling 2y/log y with y = 62: {124 / math.log(62):.2f}")
low = min(range(1, 1000), key=lambda n: (cnt[n], n))
print(f"n = 1 to 999: every interval has a prime: {all(cnt[n] for n in range(1, 1000))};"
      f" fewest {cnt[low]}, at n = {low}; most {max(cnt[1:])}")
gap = max((b - a, a) for a, b in zip(primes, primes[1:]) if a < 10**6)
start = gap[0] // 2 - 1                            # n >= start: 2n + 3 > largest gap
print(f"largest gap below 10^6: {gap[0]}, after {gap[1]:,}; so n >= {start} cannot fail below 10^6")
hold = all(any(by_division(m) for m in range(n * n + 1, (n + 1) ** 2)) for n in range(1, start))
print(f"n = 1 to {start - 1} by trial division: all hold: {hold}")
print(f"gap record 1476 below 4 x 10^18 covers n >= {1476 // 2 - 1} up to (n+1)^2 = 4 x 10^18, n + 1 = {math.isqrt(4 * 10**18):,}")
pts = (31, 100, 200, 300, 400, 500, 600, 700, 800, 900, 999)
print("chart n:", ", ".join(map(str, pts)))
print("chart, primes counted:", ", ".join(str(cnt[n]) for n in pts))
print("chart, expected:", ", ".join(f"{sum(1 / math.log(m) for m in range(n * n + 1, (n + 1) ** 2)):.1f}" for n in pts))
print("chart, Brun-Titchmarsh ceiling:", ", ".join(f"{4 * n / math.log(2 * n):.1f}" for n in pts))
print(f"proved window x^0.525 against square gap 2 sqrt x: equal at x = 2^40 = {2**40:,};"
      f" at 10^18: {10**(18 * 0.525) / 1e9:.3f} x 10^9 against 2.000 x 10^9")
# Twin primes: road one from the sieve, road two sieving n and n + 2 together
twins = [p for p in primes if p + 2 < 10**6 and flag[p + 2]]
two = bytearray([1]) * (10**6 + 1)
for p in small:
    two[0::p] = bytearray(len(range(0, 10**6 + 1, p)))
    two[p - 2::p] = bytearray(len(range(p - 2, 10**6 + 1, p)))
above = sum(two[1001:10**6 - 1]); below = sum(1 for p in twins if p < 1000)
c2 = math.prod(1 - 1 / (p - 1) ** 2 for p in primes[1:] if p <= 10**6)
a, b, N = math.log(2), math.log(10**6), 20000
h = (b - a) / N
f = lambda u: math.exp(u) / (u * u)
simp = h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, N)))
brun = sum(1 / p + 1 / (p + 2) for p in twins)
print(f"twin pairs below 10^6: {len(twins):,}; twin sieve: {below} below 1000 + {above:,} above = {below + above:,}")
print(f"C2 = {c2:.6f}; Hardy-Littlewood 2 C2 integral of 1/log^2 t: {2 * c2 * simp:,.0f}; Brun's sum to 10^6: {brun:.4f}")
# Goldbach: the smallest prime p with n - p prime, for every even n to 10^6
worst = max((next(p for p in primes if p <= n // 2 and flag[n - p]), n) for n in range(4, 10**6 + 1, 2))
print(f"Goldbach, every even n from 4 to 1,000,000 has a pair; the hardest needs p = {worst[0]}, at n = {worst[1]:,}")
# n^2 + 1: road one reads the sieve, road two sieves the values n^2 + 1 directly
hits = [n for n in range(1, 1001) if flag[n * n + 1]]
val = bytearray([1]) * 1001
for p in small:
    for r in [r for r in range(p) if (r * r + 1) % p == 0]:
        for n in range(r, 1001, p):
            if n * n + 1 != p: val[n] = 0
hits2 = [n for n in range(1, 1001) if val[n]]
roots = sum(1 for p in small if any((r * r + 1) % p == 0 for r in range(p)))
cpoly = math.prod(1 - (1 if p % 4 == 1 else -1) / (p - 1) for p in primes[1:] if p <= 10**6)
pred = cpoly * sum(1 / math.log(n * n + 1) for n in range(1, 1001))
print(f"n^2 + 1 prime for n = 1 to 1000: {len(hits)}; first: {', '.join(str(n) for n in hits[:8])}; by the value sieve: {len(hits2)}")
print(f"primes up to 1000 that ever divide n^2 + 1: {roots} of {len(small)}; constant C = {cpoly:.4f}; predicted {pred:.1f}")
bad = [n * n + n + 2 for n in range(1, 1000)]
print(f"n^2 + n + 2 prime for n = 1 to 999: {sum(flag[v] for v in bad)}; all even: {all(v % 2 == 0 for v in bad)}")
assert inside[0] == 967 and len(inside) == 10 and all(by_division(m) for m in inside)
assert all(cnt[n] for n in range(1, 1000)) and hold and gap == (114, 492113) and sum(p < 10**6 for p in primes) == 78498
assert len(twins) == 8169 == below + above and round(2 * c2 * simp) == 8248
assert worst == (523, 503222) and roots == 1 + sum(p % 4 == 1 for p in small)
assert hits == hits2 and all(by_division(n * n + 1) for n in hits)
assert 124 / math.log(62) > len(inside) > expect
print("ALL CHECKS PASS")
