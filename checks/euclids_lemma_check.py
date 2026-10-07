# Euclid's lemma -- the check behind the card.  Nothing is imported.  $84 raised
# as 4 gifts of $21: 7 divides the total, and so has to divide a gift.  Then 6,
# not a prime, dividing 4 x 9 = 36 while dividing neither the 4 nor the 9.
P, A, B = 7, 4, 21               # the prime, the number of gifts, one gift
C, U, V = 6, 4, 9                # the composite, and the pair it splits between

def listing_gcd(a, b):           # second road to a shared factor: list divisors
    return max(d for d in range(1, min(a, b) + 1) if a % d == 0 and b % d == 0)

def row(name, value):
    print(f"{name:<40}{value:>4}")

total = A * B
x = next(i for i in range(1, P) if (A * i) % P == 1)   # copies of 4 landing on 1
y = (1 - A * x) // P
row(f"{A} gifts of ${B}, the money raised", total)
print(f"{total} shared by {P}: {total} = {P} x {total // P} + {total % P}")
row(f"the {A} gifts shared by {P}, remainder", A % P)
row(f"shared factor of {P} and {A}, by listing", listing_gcd(P, A))
print(f"a mix landing on 1: {A} x {x} + {P} x {y} = {A * x + P * y}")
print(f"times {B}: {total} x {x} + {P * B} x {y} = {total * x + P * B * y}")
print(f"{total} x {x} = {P} x {(total // P) * x}, {P * B} = {P} x {B}, so {B} = {P} x {(total // P) * x + B * y}")
row(f"the ${B} gift shared by {P}, remainder", B % P)
row(f"{U} x {V} = {U * V} shared by {C}, remainder", (U * V) % C)
print(f"but {C} into {U} leaves {U % C}, {C} into {V} leaves {V % C}, gcd({C}, {U}) = {listing_gcd(C, U)}")
assert total == 84 and total % P == 0 and A % P == 4 and B % P == 0
assert A * x + P * y == 1 and total * x + P * B * y == B and (total // P) * x + B * y == B // P == 3
assert (U * V) % C == 0 and U % C == 4 and V % C == 3 and listing_gcd(C, U) == 2
assert C % 2 == 0 and U % 2 == 0   # both even, so every mix of them is even, never 1
print("ALL CHECKS PASS")
