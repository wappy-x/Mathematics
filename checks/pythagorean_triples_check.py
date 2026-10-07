# Pythagorean triples -- the check behind the card.  Nothing is imported.  The
# builder's 3-4-5 rope, then the recipe: two whole numbers, bigger first, giving
# bigger x bigger - smaller x smaller, 2 x bigger x smaller, and the two sums.
def triple(big, small):                  # the recipe, straight off the card
    legs = sorted((big * big - small * small, 2 * big * small))
    return (legs[0], legs[1], big * big + small * small)
def missing_leg(leg, long_side):         # second road: count up until it fits
    other = 1
    while leg * leg + other * other < long_side * long_side:
        other += 1
    return other if leg * leg + other * other == long_side * long_side else 0
def row(name, value): print(f"{name:<44}{value:>24}")
row("the rope: 3 x 3 + 4 x 4", f"{3 * 3} + {4 * 4} = {3 * 3 + 4 * 4} = 5 x 5")
for big, small in ((3, 2), (4, 1), (2, 1)):
    row(f"seeds {big} and {small}: leg, leg, long side", " ".join(str(v) for v in triple(big, small)))
for a, b, c in (triple(3, 2), triple(4, 1)):
    row(f"{a} x {a} + {b} x {b}", f"{a * a} + {b * b} = {a * a + b * b} = {c} x {c}")
a, b, c = triple(3, 2)
row(f"({c} + {a}) x ({c} - {a}) = {c + a} x {c - a}", f"{(c + a) * (c - a)} = {b} x {b}")
row("missing legs by counting up: 5,13 and 8,17", f"{missing_leg(5, 13)} and {missing_leg(8, 17)}")
odd_seeds = triple(3, 1)
share = max(k for k in range(1, 11) if all(v % k == 0 for v in odd_seeds))
row("seeds 3 and 1, both odd", f"{odd_seeds[0]} {odd_seeds[1]} {odd_seeds[2]}, shared factor {share}")
row("adding the sides, not the squares", 3 + 4)
row("smaller seed first, 2 and 3", triple(2, 3)[0])
assert triple(3, 2) == (5, 12, 13) and triple(4, 1) == (8, 15, 17) and triple(2, 1) == (3, 4, 5)
assert missing_leg(5, 13) == 12 and missing_leg(8, 17) == 15 and 25 + 144 == 169
assert triple(3, 1) == (6, 8, 10) and share == 2 and (13 + 5) * (13 - 5) == 144
print("ALL CHECKS PASS")
