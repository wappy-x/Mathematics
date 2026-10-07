# Exponents -- the check behind the card.  Nothing imported.  A chain message:
# 3 friends each, five rounds; then 243 by a second road, and the ladder of ratios.
def power(base, rounds):            # 3, 5 -> 3 x 3 x 3 x 3 x 3 -> 243
    result = 1
    for _ in range(rounds):
        result = result * base
    return result

def line(name, value):
    print(f"{name:<44}{value:>6}")

new = [power(3, r) for r in range(6)]
running = [sum(new[:r + 1]) for r in range(6)]
flip = new[5] // new[2]             # 9 x 27 = 243, so 9 / 243 is 1/27
print(f"{'round':<22}" + "".join(f"{v:>5}" for v in range(6)))
print(f"{'new people this round':<22}" + "".join(f"{v:>5}" for v in new))
print(f"{'everyone who has it':<22}" + "".join(f"{v:>5}" for v in running))
line("3 x 3 x 3 x 3 x 3 = 3^5", new[5])
line("3^2 x 3^3, the two halves multiplied", power(3, 2) * power(3, 3))
line("(3^2)^3 = 3^6, a power of a power", power(power(3, 2), 3))
line("3^5 / 3^2 = 3^3, five rounds against two", new[5] // new[2])
line("3^5 / 3^5 = 3^0, five rounds against five", new[5] // new[5])
line("3^2 / 3^5 = 3^-3, two rounds against five", f"1/{flip}")
print(f"the three mistakes come out at {power(3, 6)}, {3 * 5} and {-power(3, 3)}")

assert new[5] == 243 and power(3, 2) * power(3, 3) == new[5]
assert running[5] == 1 + 3 + 9 + 27 + 81 + 243 and new[0] == 1
assert new[2] == 9 and flip == 27 and new[2] * flip == new[5] and new[5] // new[5] == 1
assert power(power(3, 2), 3) == power(3, 6) == 729
print("ALL CHECKS PASS")
