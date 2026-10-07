# The number line and inequalities -- the check behind the card.  Nothing is imported.
# A thermostat holds a room between 18 and 22 degrees: six readings through one
# night, and -2 outside.
LOW, HIGH, OUTSIDE = 18, 22, -2
READINGS = [22, 20, 18, 17, 19, 21]

def row(name, value): print(f"{name:<34}{value}")
def halfway(a, b, c, d):             # halfway between a/b and c/d, as a fraction
    top, bot = a * d + c * b, 2 * b * d
    x, y = top, bot
    while y: x, y = y, x % y         # x ends as the biggest common divisor
    return top // x, bot // x

night = sorted(READINGS + [OUTSIDE])
inside = [t for t in READINGS if LOW <= t <= HIGH]
ends_out = [t for t in READINGS if LOW < t < HIGH]
flipped = [-t for t in sorted(READINGS)]
row("the night, left to right", ", ".join(str(t) for t in night))
row("17 and 18, each doubled", f"{2 * 17}, {2 * 18}")
row("readings inside 18 to 22", len(inside))
row("if the ends were left out", len(ends_out))
row("17 and 19 as shortfalls from 20", f"{20 - 17}, {20 - 19}")
row("the same list, each times -1", ", ".join(str(t) for t in flipped))
for a, b, c, d in [(18, 1, 22, 1), (18, 1, 20, 1), (18, 1, 19, 1), (18, 1, 37, 2)]:
    t, u = halfway(a, b, c, d)
    row(f"halfway between {a}/{b} and {c}/{d}", f"{t}/{u} = {t / u:.2f}")
assert len(inside) == 5 and len(ends_out) == 3 and night[0] < 17 < LOW
assert flipped == sorted(flipped, reverse=True)
assert halfway(18, 1, 19, 1) == (37, 2) and 18 < 37 / 2 < 19
print("ALL CHECKS PASS")
