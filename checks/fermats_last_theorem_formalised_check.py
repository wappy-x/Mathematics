# Fermat's last theorem, formalised -- the check behind the card.  Standard
# library only.  Part 1 searches a^n + b^n = c^n for c <= 1,000 by two roads
# (a table of powers, and two pointers walking towards each other), with
# Euclid's formula as a third road at n = 2.  Part 2 splits every exponent
# n <= 1,000 into "has a factor 4" or "has an odd prime factor", two ways.
# Part 3 finds the irregular primes below 100 two ways (Bernoulli numbers
# mod p, and power sums mod p^2), which tells which formal proof covers which
# prime.  Part 4 is the near miss 1782^12 + 1841^12 against 1922^12, and
# Part 5 is the arithmetic of the eleven days.
N = 1000

def by_table(n):
    powers = {c ** n: c for c in range(1, N + 1)}
    hits = 0
    for a in range(1, N):
        for b in range(a, N):
            s = a ** n + b ** n
            if s > N ** n:
                break
            hits += s in powers
    return hits

def by_pointers(n):
    hits = 0
    for c in range(2, N + 1):
        a, b, t = 1, c - 1, c ** n
        while a <= b:
            s = a ** n + b ** n
            if s == t:
                hits += 1; a += 1
            elif s < t:
                a += 1
            else:
                b -= 1
    return hits

def gcd(x, y):
    while y:
        x, y = y, x % y
    return x

def by_euclid():  # every triple is k(m^2 - j^2, 2mj, m^2 + j^2), m > j, coprime, opposite parity
    total = 0
    for m in range(2, int(N ** 0.5) + 1):
        for j in range(1, m):
            if (m - j) % 2 == 1 and gcd(m, j) == 1 and m * m + j * j <= N:
                total += N // (m * m + j * j)
    return total

print(f"Part 1: solutions of a^n + b^n = c^n, 1 <= a <= b, c <= {N}")
counts = {}
for n in range(2, 7):
    t, p = by_table(n), by_pointers(n)
    counts[n] = t
    assert t == p, n
    print(f"n = {n}: table {t}, two pointers {p}")
assert counts[2] == by_euclid()
print(f"n = 2 by Euclid's formula: {by_euclid()}")
assert all(counts[n] == 0 for n in range(3, 7))
print(f"n = 3 to 6: none, checked for c <= {N} only")
print("drop a != 0: 0^3 + 1^3 = 1^3 is a solution")

print(f"Part 2: every n from 3 to {N} has a factor 4 or an odd prime factor")
only4 = []
for n in range(3, N + 1):
    odd = n
    while odd % 2 == 0:
        odd //= 2
    by_factor = odd > 1  # road 1: strip the 2s, something odd is left
    pow2 = (n & (n - 1)) == 0  # road 2: n is a power of two
    assert by_factor != pow2 and (by_factor or n % 4 == 0), n
    if not by_factor:
        only4.append(n)
print(f"covered by 4 alone: {len(only4)} exponents: {only4}")
print(f"covered by an odd prime: {N - 2 - len(only4)}")

print("Part 3: irregular primes below 100, two roads")
def is_prime(n):
    return n > 1 and all(n % d for d in range(2, int(n ** 0.5) + 1))
def irregular_bernoulli(p):  # B_0..B_{p-3} mod p from sum_j C(m+1, j) B_j = 0
    B = [1]
    for m in range(1, p - 2):
        s, c = 0, 1
        for j in range(m):
            s += c * B[j]
            c = c * (m + 1 - j) // (j + 1)
        B.append(-s * pow(m + 1, p - 2, p) % p)
    return [k for k in range(2, p - 2, 2) if B[k] == 0]
def irregular_powersum(p):  # sum a^k == p B_k mod p^2 for even k < p - 1
    return any(sum(pow(a, k, p * p) for a in range(1, p)) % (p * p) == 0 for k in range(2, p - 2, 2))
odd_primes = [p for p in range(3, 100) if is_prime(p)]
irr = [p for p in odd_primes if irregular_bernoulli(p)]
assert irr == [p for p in odd_primes if irregular_powersum(p)]
assert irr == [37, 59, 67]
small = [p for p in odd_primes if p < 17]
assert not any(p in irr for p in small)
print(f"odd primes below 100: {len(odd_primes)}; irregular: {irr}")
print(f"below 17, all regular: {small}")
print("p divides the top of B_k at (p, k): " + ", ".join(f"({p}, {irregular_bernoulli(p)[0]})" for p in irr))
both = [p for p in odd_primes if p >= 17 and p not in irr]
print(f"17 and up, regular too (covered twice): {len(both)}; covered by the 2026 proof only: {irr}")

print("Part 4: the near miss 1782^12 + 1841^12 against 1922^12")
L, R = 1782 ** 12 + 1841 ** 12, 1922 ** 12
def fpow(x, k):
    r = 1.0
    for _ in range(k):
        r *= x
    return r
gap = fpow(1782 / 1922, 12) + fpow(1841 / 1922, 12) - 1.0
assert L != R and L % 2 == 1 and R % 2 == 0
assert abs(gap - (L - R) / R) < 1e-15
print(f"left side odd, right side even, so not equal; relative gap {gap:.3e}")

print("Part 5: the eleven days, from the sources' own figures")
days, lines, thms, decls = 11, 13_400_000, 29_511, 1_052_234
print(f"source figures: {days} days, {lines} lines, {thms} theorems, {decls} declarations")
print("rebuild: a machine with 96 cores, nearly 20 times as long as building Mathlib")
print(f"a day: {thms // days} theorems, {lines // days} lines; lines per theorem: {lines // thms}")
print(f"years: note 1637 to proof 1995 = {1995 - 1637}; proof to formal proof 2026 = {2026 - 1995}")
print("ALL CHECKS PASS")
