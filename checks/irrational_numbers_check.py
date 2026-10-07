# Irrational numbers -- the check behind the card.  Nothing is imported.  A floor tile
# 1000 mm on a side: the square on its diagonal is 2000000 square mm, and no whole number
# of millimetres squares to that.  Then two decimals, dug out a place at a time.
def row(name, value):
    print(f"{name:<44}{value:>16}")
area = 2 * 1000 * 1000
row("tile side, then the square on the diagonal", f"{1000}  {area}")
row("1414 x 1414, then 1415 x 1415", f"{1414 * 1414}  {1415 * 1415}")
row("short by, then over by, in sq mm", f"{area - 1414 * 1414}  {1415 * 1415 - area}")
row("99 x 99, then 2 x 70 x 70", f"{99 * 99}  {2 * 70 * 70}")
whole, power, dug = 1, 1, []
for _ in range(8):        # biggest whole number whose square, in these units, stays under 2
    whole, power = whole * 10, power * 10
    while (whole + 1) * (whole + 1) <= 2 * power * power: whole += 1
    dug.append(whole % 10)
row("root 2, dug out one digit at a time", "1." + "".join(str(d) for d in dug))
left, digits, rests = 5, [], []
for _ in range(8):        # long division: 5 divided by 11, one place at a time
    d, left = divmod(left * 10, 11)
    digits.append(d); rests.append(left)
row("five elevenths, by long division", "0." + "".join(str(d) for d in digits))
row("that decimal shifted two places", "45." + "".join(str(d) for d in digits))
row("its remainders, step by step", " ".join(str(r) for r in rests))
a, b = 45, 99
while b: a, b = b, a % b  # a ends up the biggest whole number dividing both, which is 9
row("45/99 from the shift-and-subtract, cut down", f"{45 // a}/{99 // a}")
assert 1414 * 1414 < area < 1415 * 1415 and 99 * 99 - 2 * 70 * 70 == 1
assert dug == [4, 1, 4, 2, 1, 3, 5, 6] and digits == [4, 5, 4, 5, 4, 5, 4, 5]
assert (45 // a, 99 // a) == (5, 11) and rests[0] == rests[2] == 6
print("ALL CHECKS PASS")
