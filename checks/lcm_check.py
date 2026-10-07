# Least common multiple -- the check behind the card.  Nothing is imported.  A 6-beat drum
# pattern against an 8-beat bass line: the first beat they both come round on, three roads.
def walk_to_shared(a, b):           # road one: step along the multiples of a until b goes in too
    m = a
    while m % b != 0: m += a
    return m
def primes_of(n):                   # the prime pieces of n, smallest first: 8 -> 2, 2, 2
    out, d = [], 2
    while n > 1:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out
def most_of_each(a, b):             # road three: each prime, as often as the greedier of the two wants it
    pa, pb = primes_of(a), primes_of(b)
    return [p for p in sorted(set(pa + pb)) for _ in range(max(pa.count(p), pb.count(p)))]
def product(fs): return fs[0] * product(fs[1:]) if fs else 1
def show(fs, sep=" x "): return sep.join(str(f) for f in fs)
drum, bass = 6, 8
shared, g = walk_to_shared(drum, bass), max(d for d in range(1, drum + 1) if drum % d == 0 and bass % d == 0)
mult = most_of_each(drum, bass)
print(f"road one, step along the multiples -- drum comes round on {show(range(drum, shared + 1, drum), ', ')};  bass on {show(range(bass, shared + 1, bass), ', ')}")
print(f"the first beat in both lists is {shared}, and nothing under it is in both (checked 1 to {shared - 1})")
print(f"road two, the link -- gcd({drum}, {bass}) = {g}, product {drum} x {bass} = {drum * bass}, and {drum * bass} / {g} = {drum * bass // g}")
print(f"road three, from the primes -- {drum} = {show(primes_of(drum))}, {bass} = {show(primes_of(bass))}, most of each = {show(mult)} = {product(mult)}")
print(f"over {shared} beats the drum plays {shared // drum} loops and the bass {shared // bass};  at 120 beats a minute, {shared * 60 // 120} seconds")
print(f"the three mistakes come out at {drum * bass}, {drum + bass} and {bass}")
assert shared == 24 and shared % drum == 0 and shared % bass == 0
assert all(m % drum or m % bass for m in range(1, shared))
assert g * shared == drum * bass == 48 and product(mult) == shared
print("ALL CHECKS PASS")
