# Primitive roots mod p -- the check behind the card.  Nothing is imported.  The 13-clock, sorted by order.
P, BIG = 13, 2**31 - 1                            # the card's clock, and the prime of a real random generator
gcd = lambda a, b: a if b == 0 else gcd(b, a % b)
phi = lambda n: sum(1 for k in range(1, n + 1) if gcd(k, n) == 1)      # the definition: count them
order = lambda a, n: next(k for k in range(1, n + 1) if pow(a, k, n) == 1)   # road one: first power at 1
def primes_of(n):                                 # the different primes that divide n, by trial division
    out = []
    for q in range(2, int(n ** 0.5) + 2):
        while n % q == 0: n //= q; out += [] if q in out else [q]
    return out + ([n] if n > 1 else [])
test = lambda g, p: all(pow(g, (p - 1) // q, p) != 1 for q in primes_of(p - 1))  # road two: power test
row = lambda name, xs: print(f"{name:<24}" + "".join(f"{x:>3}" for x in xs))
D, orders = [d for d in range(1, P) if (P - 1) % d == 0], [order(a, P) for a in range(1, P)]
count, fracs = [orders.count(d) for d in D], [sum(1 for k in range(1, P) if (P - 1) // gcd(k, P - 1) == d) for d in D]
roots, prims = [sum(1 for x in range(1, P) if pow(x, d, P) == 1) for d in D], [a for a in range(1, P) if orders[a - 1] == P - 1]
primes = [p for p in range(2, 200) if primes_of(p) == [p]]
agree = sum(1 for p in primes if sum(1 for a in range(1, p) if order(a, p) == p - 1) == phi(p - 1))
half, on15 = sum(1 for g in range(1, P) if pow(g, 6, P) != 1), sum(1 for a in range(1, 15) if gcd(a, 15) == 1 and order(a, 15) == 8)
print(f"powers of 2: {' '.join(str(pow(2, k, P)) for k in range(1, P))};  powers of 3: {' '.join(str(pow(3, k, P)) for k in range(1, 4))}")
row(f"order of 1 to {P - 1}:", orders); row("possible order d", D); row("numbers with order d", count)
row("phi(d)", [phi(d) for d in D]); row(f"k/{P - 1} with bottom d", fracs); row("roots of x^d - 1", roots)
print(f"total {' + '.join(map(str, count))} = {sum(count)};  primitive roots: {prims}, by the power test: {[g for g in range(1, P) if test(g, P)]}")
print(f"primes below 200 whose primitive roots number phi(p - 1): {agree} of {len(primes)}")
print(f"16807 on the {BIG}-clock passes the power test: {'yes, order ' + str(BIG - 1) if test(16807, BIG) else 'no'}, primes {primes_of(BIG - 1)}")
print(f"the three mistakes come out at {P - 1}, {half} and {phi(phi(15))} ({on15} found);  15-clock: phi(15) = {phi(15)}, phi(8) = {phi(8)}, x^2 - 1 has {sum(1 for x in range(15) if x * x % 15 == 1)} roots")
assert count == [phi(d) for d in D] == fracs and sum(count) == P - 1 and roots == D and orders[2] == 3
assert prims == [g for g in range(1, P) if test(g, P)] == [2, 6, 7, 11] and agree == len(primes) == 46
assert test(16807, BIG) and not test(16807 ** 2, BIG) and (half, on15, phi(phi(15))) == (6, 0, 4)
print("ALL CHECKS PASS")
