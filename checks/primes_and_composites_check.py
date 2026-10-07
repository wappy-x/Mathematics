# Primes and composites -- the check behind the card.  Nothing is imported.  97 chairs will not make equal
# rows; 91 chairs make 7 rows of 13.  Trial division is one road, listing every divisor is the other.
def trials(n):                  # the divisors tried, stopping at the first that goes in
    tried = []
    for d in range(2, n):
        if d * d > n: break
        tried.append(d)
        if n % d == 0: break
    return tried
def is_prime(n, floor=1): return n > floor and all(n % d for d in trials(n))   # the first road
def divisors(n): return [d for d in range(1, n + 1) if n % d == 0]     # the second road
for n, verdict in ((97, "prime"), (91, "composite, 91 = 7 x 13")):
    t = trials(n)
    print(f"{n} -- trial divisors {' '.join(map(str, t))}, remainders "
          f"{' '.join(str(n % d) for d in t)} -> {verdict}")
print("stop rule: 9 x 9 = 81 is under 97, 10 x 10 = 100 is past it, so 9 is the last trial")
d97, d91 = divisors(97), divisors(91)
print(f"divisors: 97 has {', '.join(map(str, d97))} ({len(d97)} of them); 91 has {', '.join(map(str, d91))} ({len(d91)} of them)")
print("how many divisors, 91 to 100: " + " ".join(str(len(divisors(n))) for n in range(91, 101)))
p100, p1000 = [n for n in range(2, 100) if is_prime(n)], [n for n in range(2, 1000) if is_prime(n)]
slip = [n for n in range(2, 100) if not is_prime(n) and all(n % d for d in (2, 3, 4, 5))]
print(f"primes below 100: {len(p100)}")
print(f"counting 1 as prime instead: {len([n for n in range(1, 100) if is_prime(n, 0)])}")
print(f"stopping the trials at 5 instead: {len(p100) + len(slip)}  ({', '.join(map(str, slip))} slip through)")
print(f"odd numbers above 1 below 100: {len(range(3, 100, 2))}")
assert p1000 == [n for n in range(2, 1000) if len(divisors(n)) == 2]   # the two roads agree
print(f"both roads agree on every number below 1,000: {len(p1000)} primes")
assert len(p100) == 25 and d91 == [1, 7, 13, 91] and 7 * 13 == 91 and not is_prime(1) and len(divisors(1)) == 1
assert 9 * 9 < 97 < 10 * 10 and len(slip) == 3 and len(range(3, 100, 2)) == 49
print("ALL CHECKS PASS")
