# How primes thin out -- the check behind the card.  Only log is imported.  A corridor of a
# million lockers is sieved, the doors left open are counted a second way by trial division,
# and those counts are set against x divided by the natural log of x.
from math import log
def sieve(n):                       # doors 2..n; slam every multiple of every door kept
    open_ = [True] * (n + 1)
    open_[0] = open_[1] = False
    for p in range(2, int(n ** 0.5) + 1):
        if open_[p]: open_[p * p::p] = [False] * len(range(p * p, n + 1, p))
    return open_
def is_prime(k):                    # second road: divide k by everything up to its root
    d = 2
    while d * d <= k and k % d: d += 1
    return d * d > k
def com(v): return f"{v:,}"         # 78498 -> 78,498

flags = sieve(1000000)
pi = lambda x: sum(flags[:x + 1])
print(f"{'x':>9}{'primes up to x':>16}{'ln x':>10}{'x / ln x':>12}{'miss':>8}{'ratio':>8}")
for x in (100, 1000, 1000000):
    g, p = x / log(x), pi(x)
    print(f"{com(x):>9}{com(p):>16}{log(x):>10.4f}{com(round(g)):>12}{com(p - round(g)):>8}{p / g:>8.3f}")
print(f"the 1000th prime is {com([k for k in range(2, 8000) if flags[k]][999])}, not {pi(1000)}")
print("log base 10 instead of ln predicts " + ", ".join(com(round(x * log(10) / log(x))) for x in (100, 1000, 1000000)))
print(f"primes per hundred lockers: {pi(100)} in the first, {pi(1000) - pi(900)} at 901 to 1000, {pi(1000000) - pi(999900)} in the last before a million")
print(f"a flat {pi(100)} per hundred all the way would give {com(pi(100) * 10000)}, not {com(pi(1000000))}")
assert pi(100) == 25 and pi(1000) == 168 and pi(1000000) == 78498
assert sum(1 for k in range(2, 101) if is_prime(k)) == 25 and sum(1 for k in range(2, 1001) if is_prime(k)) == 168 and sum(1 for k in range(999901, 1000001) if is_prime(k)) == 8
assert round(100 / log(100)) == 22 and round(1000 / log(1000)) == 145 and round(1000000 / log(1000000)) == 72382
print("ALL CHECKS PASS")
