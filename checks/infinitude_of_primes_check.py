# There are infinitely many primes -- the check behind the card.  Nothing is
# imported.  Six primes multiplied, plus one, is 30031.  Two roads to a new
# prime: factor it, and divide it by every prime on the list.
LISTED = [2, 3, 5, 7, 11, 13]
def factor(n):                   # trial division: the smallest prime factor of n
    d = 2
    while d * d <= n:
        if n % d == 0:
            return d
        d += 1
    return n
product = 1
for p in LISTED:
    product *= p
euclid = product + 1                              # the Euclid number
small = factor(euclid)                            # road one: factor it
big = euclid // small
rem = " ".join(str(euclid % p) for p in LISTED)   # road two: the remainders
for name, value in [
        ("2 x 3 x 5 x 7 x 11 x 13", product), ("that product plus one", euclid),
        ("remainder of 30031 by each listed prime", rem), ("smallest prime factor of 30031", small),
        ("30031 divided by 59", big), ("59 x 509, multiplied back", small * big),
        ("smallest prime factor of 509", factor(big)), ("drop the plus one, factor 30030", factor(product)),
        ("either factor already listed, 0 is no", sum(q in LISTED for q in (small, big))),
        ("add one to 13 alone", 13 + 1), ("factor that 14 instead", factor(14))]:
    print(f"{name:<41}{value:>6}")
assert product == 30030 and euclid == 30031 and small * big == euclid
assert small == 59 and big == 509 and factor(big) == 509
assert rem == "1 1 1 1 1 1" and factor(product) == 2 and factor(14) == 2
print("ALL CHECKS PASS")
