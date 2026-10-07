# Fermat's little theorem -- the check behind the card.  Nothing is imported.  A
# 13-position lock dial, base 2: twelve doublings land on 1, the twelve doubled
# positions are the twelve positions shuffled, and 2 to the 1000 collapses to 3.
DIAL, BASE = 13, 2

def turn(base, times, dial):      # the reading after that many multiplications
    out = 1
    for _ in range(times): out = (out * base) % dial
    return out

def row(name, value): print(f"{name:<44}{value:>14}")
whole, left = BASE ** (DIAL - 1), 1000 % (DIAL - 1)   # 4096 in full; 1000 split by 12
doubles = [(BASE * k) % DIAL for k in range(1, DIAL)]
plain, shuffled = 1, 1                                # 1 x 2 x ... x 12, and each doubled
for k in range(1, DIAL): plain, shuffled = plain * k, shuffled * (BASE * k)
row("2 doubled twelve times", whole)
row(f"{whole} = {whole // DIAL} x {DIAL} + 1, so the dial shows", whole % DIAL)
row(f"2 to the {DIAL} = {BASE ** DIAL}, so the dial shows", turn(BASE, DIAL, DIAL))
print("1 to 12, each doubled: " + " ".join(str(d) for d in doubles))
row("1 to 12 multiplied", plain)
row("the twelve doubles multiplied", shuffled)
row("both of those, on the 13-dial", plain % DIAL)
row(f"1000 = {1000 // (DIAL - 1)} x {DIAL - 1} + {left}, leftover exponent", left)
row(f"2 to the {left} = {BASE ** left}, so the dial shows", turn(BASE, left, DIAL))
row("2 to the 1000 the long way, on the 13-dial", turn(BASE, 1000, DIAL))
print(f"gone wrong: cut by 13 -> {turn(BASE, 1000 % DIAL, DIAL)}, base 26 -> {turn(2 * DIAL, DIAL - 1, DIAL)}, 14 on a 15-dial ({BASE ** 14}) -> {turn(BASE, 14, 15)}")
assert whole == 4096 and whole == 315 * DIAL + 1 and turn(BASE, DIAL - 1, DIAL) == 1
assert sorted(doubles) == list(range(1, DIAL)) and shuffled % DIAL == plain % DIAL == 12
assert turn(BASE, 1000, DIAL) == turn(BASE, left, DIAL) == 16 % DIAL == 3
print("ALL CHECKS PASS")
