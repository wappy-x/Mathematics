# Perfect numbers and Mersenne primes -- the check behind the card.  28 is done
# the plain way, its proper divisors listed and added, then again by Euclid's
# recipe, then the recipe on the first four.  log10 only counts digits.
from math import floor, log10
def divisors(n):                       # every d that goes into n, n itself last
    return [d for d in range(1, n + 1) if n % d == 0]
def digit_count(twos):                 # digits in that many 2s multiplied, minus 1
    return floor(twos * log10(2)) + 1
def row(name, value):
    print(f"{name:<44}{value:>8}")

d28 = divisors(28)
print("28 = " + " + ".join(str(d) for d in d28[:-1]))
row("proper divisors of 28 add to", sum(d28[:-1]))
row("all divisors of 28 add to, that is 2 x 28", sum(d28))
row("Euclid's way, (1 + 2 + 4) x (1 + 7) = 7 x 8", (1 + 2 + 4) * (1 + 7))
pairs = [(2, 3), (3, 7), (5, 31), (7, 127)]
print("the recipe: " + ", ".join(f"{2 ** (p - 1)} x {m} = {2 ** (p - 1) * m}" for p, m in pairs))
hand = [sum(divisors(2 ** (p - 1) * m)[:-1]) for p, m in pairs]
print("added up by hand: " + ", ".join(str(s) for s in hand))
print("2047 = 23 x 89, not prime, and 1024 x 2047 =", 1024 * 2047)
row("proper divisors of 2096128 add to", sum(divisors(2096128)[:-1]))
row("digits in the record prime, 136279841 twos", digit_count(136279841))
row("digits in its perfect number, 52nd known", digit_count(2 * 136279841 - 1))
assert d28 == [1, 2, 4, 7, 14, 28] and sum(d28[:-1]) == 28
assert sum(d28) == (1 + 2 + 4) * (1 + 7) == 56
assert [2 ** (p - 1) * m for p, m in pairs] == hand == [6, 28, 496, 8128]
assert sum(divisors(2096128)[:-1]) == 2325392 and 23 * 89 == 2047
assert digit_count(136279841) == 41024320 and digit_count(2 * 136279841 - 1) == 82048640
print("ALL CHECKS PASS")
