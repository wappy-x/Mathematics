# Goldbach and twin primes -- the check behind the card.  Nothing is imported.
# Two roads to the same counts: a sieve of Eratosthenes to 200, and trial
# division.  House numbers 4, 98, 100, 102, and the twin pair 101 and 103.
flag = [True] * 201                  # road one: the sieve.  flag[m] means "m is prime"
flag[0] = flag[1] = False
for p in range(2, 15):
    if flag[p]:
        for k in range(p * p, 201, p): flag[k] = False
def by_division(n):                  # road two: hunt for a divisor, up to the square root
    d = 2
    while d * d <= n and n % d: d += 1
    return d * d > n
def pairs(n, is_prime):              # every way n = p + q, both prime, smaller one first
    return [(p, n - p) for p in range(2, n // 2 + 1) if is_prime(p) and is_prime(n - p)]

by_sieve = lambda m: flag[m]
six = pairs(100, by_sieve)
for p, q in six: print(f"100 = {p} + {q}")
counts = [len(pairs(n, by_sieve)) for n in (4, 98, 100, 102)]
checked = [len(pairs(n, by_division)) for n in (4, 98, 100, 102)]
twins = [(a, a + 2) for a in range(101, 199) if flag[a] and flag[a + 2]]
print("ways to write it as two primes: 4 has {}, 98 has {}, 100 has {}, 102 has {}".format(*counts))
print("the sieve and trial division agree on all four counts" if counts == checked else "the two roads disagree")
print(f"twin primes just above 100: {twins[0][0]} and {twins[0][1]}")
print("Goldbach checked to 4,000,000,000,000,000,000 by computer (published, not checked here)")
print(f"the three mistakes come out at {2 * len(six)} ordered pairs, {len(pairs(11, by_sieve))} ways for 11, {len(pairs(2, by_sieve))} for 2")
assert six == [(3, 97), (11, 89), (17, 83), (29, 71), (41, 59), (47, 53)]
assert counts == [1, 3, 6, 8] and checked == [1, 3, 6, 8] and all(flag[m] == by_division(m) for m in range(2, 201))
assert twins[0] == (101, 103) and by_division(101) and by_division(103)
print("ALL CHECKS PASS")
