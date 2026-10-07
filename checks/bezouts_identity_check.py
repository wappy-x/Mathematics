# Bezout's identity -- the check behind the card.  Nothing is imported.  Two
# jugs, 21 and 15 litres.  Road one: Euclid's chain, walked backwards, to write
# 3 as a mix of 21 and 15.  Road two: try every small mix and see what turns up.
A, B = 21, 15

def listing_gcd(a, b):            # independent of Euclid: list the divisors
    return max(d for d in range(1, min(a, b) + 1) if a % d == 0 and b % d == 0)

chain, a, b = [], A, B
while b:
    chain.append((a, a // b, b, a % b))
    a, b = b, a % b
g = a
print(f"{'gcd(21, 15) by Euclid':<38}{g:>4}")
for (u, q, v, r) in chain:
    print(f"{u} = {q} x {v} + {r}")
p, s = 1, -chain[-2][1]           # the last useful line: 3 = 15 - 2 x 6
for (u, q, v, r) in reversed(chain[:-2]):
    p, s = s, p - s * q           # swap in the line above it
print(f"Bezout: 21 x {p} + 15 x {s} = {A * p} + {B * s} = {A * p + B * s}")
p2, s2 = p + B // g, s - A // g   # slide along by one whole step
print(f"one step along (21 x {B // g} = 15 x {A // g} = {A * (B // g)}): 21 x {p2} + 15 x {s2} = {A * p2} + {B * s2} = {A * p2 + B * s2}")
mixes = [A * i + B * j for i in range(-9, 10) for j in range(-9, 10)]
print(f"{'smallest mix above zero, by search':<38}{min(m for m in mixes if m > 0):>4}")
print(f"{'mixes that land on 1 or 2 litres':<38}{sum(m in (1, 2) for m in mixes):>4}")
print(f"the three mistakes come out at {A * 2 + B * 3}, {B - 2 * A} and {A * 3 - B * 2}")
assert g == 3 and g == listing_gcd(A, B)
assert (p, s) == (-2, 3) and A * p + B * s == g and A * p2 + B * s2 == g
assert min(m for m in mixes if m > 0) == g and 1 not in mixes and 2 not in mixes
print("ALL CHECKS PASS")
