# Goldbach's conjecture, the verification and its limits -- the check behind
# the card.  Standard library only: math supplies log10 and log.  Roads: a
# sieve against a Miller-Rabin test written out; each composite confirmed by an
# explicit factor (trial division, then Pollard's rho); published records
# rechecked; a ladder of primes turning a two-prime check into a three-prime one.
import math
B = 2_000_000                                      # the even check here runs to B
flag = bytearray([1]) * (B + 1)
flag[0] = flag[1] = 0
for i in range(2, 1415):
    if flag[i]: flag[i * i::i] = bytearray(len(range(i * i, B + 1, i)))
P = [m for m in range(3, B + 1) if flag[m]]        # the odd primes up to B
BASES = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
def mr(m, bases=BASES):                            # Miller-Rabin; 12 bases are exact below 3.18e23
    if m < 2: return False
    for a in bases:
        if m % a == 0: return m == a
    d, s = m - 1, 0
    while d % 2 == 0: d, s = d // 2, s + 1
    for a in bases:
        x = pow(a, d, m)
        if x == 1 or x == m - 1: continue
        for _ in range(s - 1):
            x = x * x % m
            if x == m - 1: break
        else: return False
    return True
def gcd(a, b):
    while b: a, b = b, a % b
    return a
def factor_of(m):                                  # an explicit factor 1 < f < m, or 0
    for d in range(3, 100_000, 2):
        if m % d == 0: return d
    for c in range(1, 20):                         # Pollard's rho with x -> x*x + c
        x, y, g = 2, 2, 1
        while g == 1:
            x = (x * x + c) % m
            y = (y * y + c) % m
            y = (y * y + c) % m
            g = gcd(abs(x - y), m)
        if g != m: return g
    return 0
def p_min(n, prime):                               # smallest odd prime p with n - p prime, and tries
    for k, p in enumerate(P):
        if prime(n - p): return p, k + 1
def by_sieve(m): return flag[m] == 1
n = 10 ** 6                                        # the worked example: one million
pairs = [p for p in P if p <= n // 2 and flag[n - p]]
pairs_mr = [p for p in range(3, n // 2 + 1, 2) if mr(p) and mr(n - p)]
print(f"r(1000000) = {len(pairs)} by the sieve, {len(pairs_mr)} by Miller-Rabin; ordered pairs {2 * len(pairs)}")
print(f"smallest pair {pairs[0]} + {n - pairs[0]}; largest p {pairs[-1]} + {n - pairs[-1]}")
first, k0 = p_min(n, by_sieve)
print(f"p_min(1000000) = {first}, found on try {k0}; the failures: " +
      ", ".join(f"{n - q} = {factor_of(n - q)} x {(n - q) // factor_of(n - q)}" for q in P[:k0 - 1]))
records, tries, threes = [(4, 2)], 0, 0
for m in range(6, B + 1, 2):
    p, k = p_min(m, by_sieve)
    tries, threes = tries + k, threes + (p == 3)
    if p > records[-1][1]: records.append((m, p))
evens = (B - 4) // 2
print(f"every even n from 4 to {B} has a pair: yes; {evens + 1} numbers checked")
print(f"mean primes tried per n: {tries / evens:.3f}; share settled by p = 3: {threes / evens:.4f}")
print("records of the smallest prime p_min(n), as n:p")
for i in range(0, len(records), 7):
    print("  " + "  ".join(f"{m}:{p}" for m, p in records[i:i + 7]))
print(f"{len(records)} records; rough tries log(n)/2: {math.log(B) / 2:.2f} at n = {B}, "
      f"{math.log(4e18) / 2:.2f} at n = 4e18, where log n = {math.log(4e18):.2f}")
recheck = [(m, p_min(m, mr)[0]) for m, p in records[1:]]
print(f"records rechecked by Miller-Rabin: {'agree' if recheck == records[1:] else 'differ'}")
below = [r for r in records if r[0] <= n]
print(f"to a million the largest p_min is {below[-1][1]} at {below[-1][0]}; the rule p_min <= {below[-1][1]} "
      f"first fails at {records[len(below)][0]} ({records[len(below)][1]})")
odd = 999_999
print(f"odd {odd}: pairs {sum(1 for p in [2] + P if p < odd and mr(odd - p))}; {odd} - 2 = {odd - 2} = "
      f"{factor_of(odd - 2)} x {(odd - 2) // factor_of(odd - 2)}")
print("published frontier cases, rechecked: n | p_min | primes tried | composites with a factor shown")
front = {}
for m in (389_965_026_819_938, 3_325_581_707_333_960_528, 10 ** 18, 4 * 10 ** 18):
    p, k = p_min(m, mr)
    shown = [q for q in P[:k - 1] if 1 < (f := factor_of(m - q)) < m - q and (m - q) % f == 0]
    front[m] = (p, k, len(shown))
    print(f"  {m} | {p} | {k} | {len(shown)} of {k - 1}")
C2 = 1.0
for p in P: C2 *= 1 - 1 / (p - 1) ** 2
L = math.log(4e18)
print(f"twin-prime constant C2, primes to {B}: {C2:.6f}; crude pair count near 4e18: "
      f"C2 x n/(log n)^2 = {C2 * 4e18 / L ** 2 / 1e15:.2f}e15")
years = 4e18 / 1e12 * 48 / 60 / 24 / 365.25
print(f"cost at 48 minutes per 1e12 block on one core: {years:.0f} core-years to 4e18, {10 * years:.0f} to 4e19")
rungs, q = [3], 3                                  # the ladder: prime steps no longer than B - 4
while q < 10 ** 10:
    q = q + B - 4                                  # odd, since q and B - 4 are
    while not mr(q): q -= 2
    rungs.append(q)
gap = max(b - a for a, b in zip(rungs, rungs[1:]))
top = rungs[-1] + B
print(f"ladder: {len(rungs)} prime rungs from 3 to {rungs[-1]}, widest step {gap}")
print(f"so every odd N from 7 to {top} is a sum of three primes, given the even check to {B}")
N = 9_999_999_999
r = max(x for x in rungs if x <= N - 4)
p, _ = p_min(N - r, by_sieve)
print(f"  N = {N} = {r} + {p} + {N - r - p}")
print("verification bounds, log10 of the largest number checked")
bars = [("this check, even", B), ("Sinisalo 1993", 4e11), ("Richstein 2001", 4e14),
        ("double-checked to", 4e17), ("Oliveira e Silva 2014", 4e18),
        ("this ladder, odd", top), ("Helfgott-Platt, odd", 8.875e30)]
for name, v in bars:
    print(f"  {name:<22}{'#' * round(math.log10(v)):<32}{math.log10(v):.2f}")
two = mr(2047, (2,))
print(f"base 2 alone calls 2047 {'prime' if two else 'composite'}; 2047 = 23 x 89; twelve bases say "
      f"{'prime' if mr(2047) else 'composite'}")
assert len(pairs) == len(pairs_mr) == 5402 and pairs[0] == first == 17 and pairs_mr == pairs
assert recheck == records[1:] and below[-1] == (503222, 523) and records[len(below)] == (1077422, 601)
assert front[389_965_026_819_938][0] == 5569 and front[3_325_581_707_333_960_528][0] == 9781
assert all(v[2] == v[1] - 1 for v in front.values()) and odd - 2 == 757 * 1321
assert gap <= B - 4 and all(r % d for d in range(2, 100_001)) and flag[N - r - p] and flag[p]
assert two and not mr(2047) and 23 * 89 == 2047
assert len(records) == 22 and tries == 6_589_204 and [v[1] for v in front.values()][:2] == [734, 1205]
assert all(flag[m] == mr(m) for m in range(2, B + 1))     # the whole sieve, rechecked by Miller-Rabin
print("ALL CHECKS PASS")
