# Quadratic residues and Euler's test -- the check behind the card.  Nothing is
# imported.  Three roads decide whether a is a square on the p-clock: list every
# square (brute force), raise a to the power (p - 1)/2 (Euler's test), and read
# the parity of a's exponent against a primitive root.  Then the house count.
def power(a, k, n):                      # square-and-multiply, written out here
    out, a = 1, a % n
    while k:
        if k & 1:
            out = out * a % n
        a, k = a * a % n, k >> 1
    return out

def squares(p):                          # road one: every square on the p-clock
    return sorted({x * x % p for x in range(1, p)})

def euler(a, p):                         # road two: a^((p-1)/2), read as +1, -1 or 0
    r = power(a, (p - 1) // 2, p)
    return -1 if r == p - 1 else r

def primitive_root(p):                   # the smallest g whose powers reach all of 1..p-1
    return next(g for g in range(2, p) if len({power(g, k, p) for k in range(1, p)}) == p - 1)

def by_parity(p):                        # road three: a = g^k is a square exactly when k is even
    g, sym = primitive_root(p), {}
    for k in range(1, p):
        sym[power(g, k, p)] = 1 if k % 2 == 0 else -1
    return g, sym

def sieve(n):                            # Eratosthenes: the primes below n
    is_p = [True] * n
    is_p[0] = is_p[1] = False
    for i in range(2, int(n ** 0.5) + 1):
        if is_p[i]:
            for j in range(i * i, n, i):
                is_p[j] = False
    return [i for i in range(n) if is_p[i]]

def sign(s):
    return "+1" if s == 1 else "-1" if s == -1 else "0"

p = 13
res = squares(p)
non = [a for a in range(1, p) if a not in res]
g, sym = by_parity(p)
leg = {a: (1 if a in res else -1) for a in range(1, p)}
print(f"squares of 1..12 on the 13-clock: {[x * x % p for x in range(1, p)]}")
print(f"residues {res}; non-residues {non}")
print(f"square roots of 3: {[x for x in range(1, p) if x * x % p == 3]}; 4 x 4 = 16 = 13 + 3")
print(f"Euler's test: 3^3 = {3 ** 3} = {3 ** 3 % p} on the clock, so 3^6 = {power(3, 6, p)}; 2^6 = {2 ** 6} = {power(2, 6, p)} = -1")
print(f"primitive root {g}: powers {[power(g, k, p) for k in range(1, p)]}")
print(f"3 = {g}^4 = ({g}^2)^2 = {g * g}^2; 2 = {g}^1, odd")
print("a      " + " ".join(f"{a:>3}" for a in range(1, p)))
print("a^6    " + " ".join(f"{power(a, 6, p):>3}" for a in range(1, p)))
print("(a/13) " + " ".join(f"{sign(euler(a, p)):>3}" for a in range(1, p)))
pairs = sum(1 for a in range(1, p) for b in range(1, p) if euler(a * b, p) == euler(a, p) * euler(b, p))
print(f"(2/13)(5/13) = ({sign(euler(2, p))})({sign(euler(5, p))}) = {sign(euler(2, p) * euler(5, p))}; (10/13) = {sign(euler(10, p))}; 6 x 6 = 36 = 2 x 13 + 10")
print(f"product rule holds for {pairs} of {(p - 1) ** 2} pairs; symbols sum to {sum(euler(a, p) for a in range(1, p))} over 1..12")
small = [q for q in sieve(2000) if q > 2]
agree = 0
for q in small:
    sq, par = set(squares(q)), by_parity(q)[1]
    agree += sum(1 for a in range(1, q) if euler(a, q) == (1 if a in sq else -1) == par[a])
total = sum(q - 1 for q in small)
print(f"three roads agree on {agree:,} of {total:,} pairs (a, p), odd primes p below 2,000")
print(f"mistake 1, exponent p - 1 instead of (p - 1)/2: 2^12 = {power(2, 12, p)}, every a passes")
u15 = [a for a in range(1, 15) if all(a % d for d in (3, 5))]
sq15 = sorted({a * a % 15 for a in u15})
print(f"mistake 2, the 15-clock: 4 = 2 x 2, yet 4^7 = {power(4, 7, 15)}; squares of the {len(u15)} units: {sq15}")
print(f"mistake 3, adding: 1 is a square, (1/13) = {sign(euler(1, p))}, but 1 + 1 = 2 and (2/13) = {sign(euler(2, p))}")
print(f"mistake 4, -1 is never a square: (12/13) = {sign(euler(12, p))}, 5 x 5 = 25 = 13 + 12")
primes = sieve(10 ** 6)
print(f"primes below 1,000,000: {len(primes):,}")
for d in (1, 3, 7, 9):
    ps = [q for q in primes if q % 10 == d]
    yes = sum(1 for q in ps if euler(5, q) == 1)
    print(f"last digit {d}: {len(ps):,} primes; 5 is a square mod {yes:,} of them")
odd = [q for q in primes if q > 2]
m1 = sum(1 for q in odd if euler(q - 1, q) == 1)
print(f"-1 is a square mod {m1:,} odd primes; p = 1 mod 4 for {sum(1 for q in odd if q % 4 == 1):,}")
assert res == [1, 3, 4, 9, 10, 12] and euler(3, p) == 1 and euler(2, p) == -1 and euler(26, p) == 0
assert all(sym[a] == leg[a] == euler(a, p) for a in range(1, p))       # three roads at 13
assert agree == total and pairs == (p - 1) ** 2
assert power(4, 7, 15) == 4 and len(sq15) * 2 != len(u15)               # composite: the test fails
for d in (1, 3, 7, 9):                                                   # the last digit decides (5/p)
    ps = [q for q in primes if q % 10 == d]
    assert sum(1 for q in ps if euler(5, q) == 1) == (len(ps) if d in (1, 9) else 0)
assert m1 == sum(1 for q in odd if q % 4 == 1) and len(primes) == 78498
print("ALL CHECKS PASS")
