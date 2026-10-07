# Cosets and Lagrange's theorem -- the check behind the card.  Nothing is
# imported.  The group is the 12-hour clock: the hours 0 to 11, added and
# wrapped at 12.  The subgroup is H = 0, 3, 6, 9.  Its blocks are built twice,
# by roads that share no arithmetic, and the clock's units then give Euler.
N, H, K = 12, [0, 3, 6, 9], [0, 3, 6, 7]

def slide(members, g):                   # road one: shift a whole set by g
    return tuple(sorted((g + m) % N for m in members))

def gcd(a, b):                           # Euclid's algorithm, written out here
    while b:
        a, b = b, a % b
    return a

def power(a, k):                         # a multiplied in k times, wrapped at 12
    out = 1
    for _ in range(k):
        out = out * a % N
    return out

def order(a):                            # the first count of multiplies reading 1
    k = 1
    while power(a, k) != 1:
        k += 1
    return k

def yn(claim):
    return "yes" if claim else "no"

blocks = sorted({slide(H, g) for g in range(N)})
by_remainder = sorted(tuple(x for x in range(N) if x % 3 == r) for r in range(3))
index = len(blocks)
hours = sorted(x for b in blocks for x in b)
coprime = [a for a in range(N) if gcd(a, N) == 1]      # road one to the units
units = [a for a in range(N)                           # road two to the units
         if any(a * b % N == 1 for b in range(N))]
phi = len(coprime)
orders = [order(a) for a in units]
copies_of_k = {slide(K, g) for g in range(N)}

print(f"clock size {N}; subgroup H = {H}, size {len(H)}; distinct blocks {index}")
for b in blocks:
    print(f"{b[0]} + H  ->  {list(b)}")
print(f"the same three blocks, by remainder after dividing by 3: {yn(blocks == by_remainder)}")
print(f"every hour exactly once: {index} blocks x {len(H)} hours = {index * len(H)}")
print(f"shift 4 names the block shift 1 names: {yn(slide(H, 4) == slide(H, 1))}, and 4 - 1 = 3 sits in H")
print(f"hours sharing no factor with 12, by gcd: {coprime}; phi(12) = {phi}")
print(f"the same hours, by hunting a multiplying partner: {units}")
print(f"orders of {units} under multiplication: {orders}")
print(f"every order divides phi(12): {yn(all(phi % d == 0 for d in orders))}")
print(f"each unit multiplied in {phi} times: {[power(a, phi) for a in units]}")
print(f"mistake 1, block size read as the block count: 4 x 4 = {len(H) * len(H)}, not {N}")
print(f"mistake 2, K = {K} is no subgroup: {len(copies_of_k)} shifted copies x "
      f"{len(K)} hours = {len(copies_of_k) * len(K)} slots for {N} hours")
print(f"mistake 3, every hour taken as a multiplier: 2 multiplied in {N} times = {power(2, N)}, not 1")
assert blocks == by_remainder                                  # two roads, one partition
assert hours == list(range(N)) and index * len(H) == N          # covers, and counts
assert coprime == units and phi == 4                            # two roads to the units
assert orders == [1, 2, 2, 2] and all(power(a, phi) == 1 for a in units)
print("ALL CHECKS PASS")
