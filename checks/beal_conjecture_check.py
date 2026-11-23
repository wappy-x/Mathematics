# Beal's conjecture: A^x + B^y = C^z with x, y, z >= 3 forces a common prime.  Standard library only.
# Beal is open, so the search is evidence.  Roads: the search by set lookup against integer-root tests;
# the common factor by gcd of all three against gcd of two; the families by identity against direct powers.
from math import gcd
from fractions import Fraction as F

def iroot(n, k):                            # largest r with r^k <= n, float guess corrected in integers
    r = int(round(n ** (1 / k)))
    while r > 0 and r ** k > n: r -= 1
    while (r + 1) ** k <= n: r += 1
    return r

def high_power(n):                          # n = r^k for some k >= 3?  (1 = 1^3 counts)
    return n == 1 or any(iroot(n, k) ** k == n for k in range(3, n.bit_length() + 1))

def common_exp(vals):                       # an n >= 3 with every value an n-th power, else 0
    for n in range(3, max(vals).bit_length() + 1):
        if all(iroot(v, n) ** n == v for v in vals): return n
    return 0

def cop_all(T): return sum(1 for t in T if gcd(gcd(t[0], t[1]), t[2]) == 1)   # coprime: gcd of all three
def cop_two(T): return sum(1 for t in T if gcd(t[0], t[1]) == 1)              # coprime: gcd of the first two
def below1(x, y, z): return F(1, x) + F(1, y) + F(1, z) < 1                    # Darmon-Granville's bottom row

print("example: 3^3 + 6^3 = 3^5")
a, b, c = 3 ** 3, 6 ** 3, 3 ** 5
print(f"{a} + {b} = {c}   gcd = {gcd(gcd(a, b), c)}   gcd(A, B, C) = {gcd(gcd(3, 6), 3)}")
print(f"divide by 3^3: {a // 27} + {b // 27} = {c // 27} = 3^2, so z falls to 2")
print("float cube root of 216, truncated:", int(216 ** (1 / 3)), "  integer root:", iroot(216, 3))

print("\nfamily 1: 1 + 2^3 = 3^2 times 3^(3k) gives (3^k)^3 + (2*3^k)^3 = 3^(3k+2)")
for k in range(1, 5):
    A, B, C = 3 ** k, 2 * 3 ** k, 3
    assert 3 ** (3 * k) * (1 + 8) == A ** 3 + B ** 3 == C ** (3 * k + 2)
    print(f"  k={k}: {A}^3 + {B}^3 = 3^{3 * k + 2} = {C ** (3 * k + 2):,}")
print("family 2: (a s)^m + (b s)^m = s^(m+1), s = a^m + b^m")
n_id = 0
for x in range(1, 5):
    for y in range(1, 5):
        for m in range(3, 7):
            s = x ** m + y ** m
            lhs = (x * s) ** m + (y * s) ** m
            assert lhs == s ** (m + 1) and high_power(lhs)
            n_id += 1
print(f"  a=1 b=2 m=3: 9^3 + 18^3 = 9^4 = {9 ** 4:,}   identities checked: {n_id}")

N = 10 ** 10
P = {1}
for e in range(3, N.bit_length() + 1):      # every A^x <= N with x >= 3
    r = 2
    while r ** e <= N: P.add(r ** e); r += 1
L = sorted(P)
road1 = [(p, r - p, r) for r in L for p in L if 2 * p <= r and r - p in P]
road2 = []
for r in L:                                 # second road: no lookup table, an integer-root test
    for p in L:
        if 2 * p > r: break
        if high_power(r - p): road2.append((p, r - p, r))
assert road1 == road2
print(f"\nsearch: A^x + B^y = C^z, x, y, z >= 3, A^x <= B^y, C^z <= 10^10")
print("bound    powers  solutions  coprime  one exponent for all three")
for j in range(6, 11):
    S = [t for t in road1 if t[2] <= 10 ** j]
    cop1, cop2 = cop_all(S), cop_two(S)
    assert cop1 == cop2                     # a prime in two of p, q, r divides the third
    feq = sum(1 for t in S if common_exp(t))
    print(f"10^{j:<5} {sum(1 for v in L if v <= 10 ** j):>6}  {len(S):>9}  {cop1:>7}  {feq:>5}")
assert sum(1 for t in road1 if t[2] <= 10 ** 6) == 25   # the abc card's count below 1,000,000
print("set lookup and integer-root test agree; checked for C^z <= 10^10")
print("one-exponent test on 8, 27, 64 (all cubes):", common_exp((8, 27, 64)))
assert common_exp((8, 27, 64)) == 3                     # the last column's test can find a shared exponent
print("first eight:", ", ".join(f"{p}+{q}={r}" for p, q, r in road1[:8]))
dbl = sum(1 for t in road1 if t[0] == t[1])
print(f"A^x = B^y (a doubling, like 8 + 8 = 16): {dbl} of {len(road1)}")
assert dbl == sum(1 for p in P if 2 * p in P)           # second road: powers whose double is a power
assert (27, 216, 243) in road1

print("\nexponent 2 allowed: the ten coprime solutions listed in 1997")
FC = [((1, 7), (2, 3), (3, 2)), ((2, 5), (7, 2), (3, 4)), ((7, 3), (13, 2), (2, 9)),
      ((2, 7), (17, 3), (71, 2)), ((3, 5), (11, 4), (122, 2)), ((17, 7), (76271, 3), (21063928, 2)),
      ((1414, 3), (2213459, 2), (65, 7)), ((9262, 3), (15312283, 2), (113, 7)),
      ((43, 8), (96222, 3), (30042907, 2)), ((33, 8), (1549034, 2), (15613, 3))]
inside = 0
for (A, x), (B, y), (C, z) in FC:
    assert A ** x + B ** y == C ** z and gcd(A, B) == gcd(B, C) == gcd(A, C) == 1
    assert 2 in (x, y, z) and below1(x, y, z)
    inside += C ** z <= N
    print(f"  {A}^{x} + {B}^{y} = {C}^{z} = {C ** z:,}")
fcv = [(A ** x, B ** y, C ** z) for (A, x), (B, y), (C, z) in FC]
least_x = next(x for x in range(2, 99) if below1(x, 3, 2))   # 1 = 1^x for every x
print(f"1/x + 1/y + 1/z below 1 for all ten; for 1^x + 2^3 = 3^2, from x = {least_x}")
print(f"coprime counters on these ten: gcd of all three {cop_all(fcv)}, gcd of two {cop_two(fcv)}")
assert cop_all(fcv) == cop_two(fcv) == len(FC)
print(f"inside the search bound 10^10: {inside} of 10")
assert inside == 5
print("Pythagoras, all exponents 2: 3^2 + 4^2 = 5^2 =", 3 ** 2 + 4 ** 2, " gcd", gcd(3, 4))
sums = sorted({F(1, x) + F(1, y) + F(1, z) for x in range(3, 30) for y in range(x, 30) for z in range(y, 30)})
print("1/x + 1/y + 1/z, all >= 3: largest", sums[-1], "at (3, 3, 3), next", sums[-2], "at (3, 3, 4)")
assert sums[-1] == 1 and sums[-2] == F(11, 12)

print("\nwhat breaks")
print("  allow an exponent 2: 2^5 + 7^2 = 3^4 =", 2 ** 5 + 7 ** 2, " gcd", gcd(32, 49))
print("  divide out the common 3^3: 1 + 8 = 9, exponent 2")
print(f"  read 'no solutions': {len(road1)} solutions with a common prime, C^z <= 10^10")
print(f"  trust the search: {10 - inside} of 10 exponent-2 solutions lie above 10^10")
print("ALL CHECKS PASS")
