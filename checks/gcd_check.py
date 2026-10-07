# Greatest common divisor -- the check behind the card.  Nothing is imported.  A 180 cm by 300 cm
# bathroom floor, one square tile, no cutting.  Road one lists the divisors of each side and keeps
# the largest they share.  Road two multiplies the primes they share, each at the poorer count.
A, B, SIZES = 180, 300, [10, 12, 15, 20, 30, 60]
def divisors(n): return [d for d in range(1, n + 1) if n % d == 0]
def join(xs, sep): return sep.join(str(v) for v in xs)
def primes(n):                                     # 180 -> [2, 2, 3, 3, 5]
    out, d = [], 2
    while d * d <= n:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out + ([n] if n > 1 else [])
common = [d for d in divisors(A) if B % d == 0]
big = max(common)                                  # road one, the largest shared
pool, sh, prod = primes(B), [], 1
for p in primes(A):                                # road two, the shared primes
    if p in pool: pool.remove(p); sh.append(p); prod *= p
mix, tiles = A, [(A // s) * (B // s) for s in SIZES]
for p in pool: mix *= p                            # every prime either side has
spare, second = pool[0] if pool else 1, common[-2]  # the 5 only 300 owns; the next size down
print(f"floor {A} cm by {B} cm, one square tile, no cutting")
print(f"{A} = {join(primes(A), ' x ')}, {len(divisors(A))} divisors;  {B} = {join(primes(B), ' x ')}, {len(divisors(B))} divisors")
print(f"common divisors: {join(common, ', ')}  ({len(common)} of them, and they are the {len(divisors(big))} divisors of {big})")
print(f"road one, the largest of those: {big}.  road two, the shared primes {join(sh, ' x ')}: {prod}")
print(f"at {big} cm the floor is {A // big} tiles across and {B // big} down, {tiles[5]} in all")
print(f"tiles needed at {join(SIZES, ', ')} cm: {join(tiles, ', ')}")
print(f"the three mistakes come out at {mix}, {prod * spare} and {second}")
assert big == 60 and prod == 60 and common == divisors(big) and not [d for d in range(big + 1, A + 1) if A % d == 0 and B % d == 0]
assert tiles == [540, 375, 240, 135, 60, 15] and (A // big) * (B // big) == 15
print("ALL CHECKS PASS")
