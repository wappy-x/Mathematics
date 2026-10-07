# Rearranging a formula -- the check behind the card.  Nothing is imported.
# F = 1.8C + 32 turns 25 degrees C into 77 degrees F.  Rearranged,
# C = (F - 32) / 1.8 turns 77 back into 25.  Two roads reach that 25: the
# rearranged formula, and a hunt that never rearranges anything at all.
SLOPE, OFFSET = 1.8, 32.0                      # the two numbers in F = 1.8C + 32

def to_f(c): return SLOPE * c + OFFSET         # the formula as it is written
def to_c(f): return (f - OFFSET) / SLOPE       # road one: the rearranged formula

def hunt(f):                                   # road two: no rearranging at all
    lo, hi = -100.0, 200.0                     # the Celsius number is in here
    for _ in range(200):                       # halve the range, 200 times over
        mid = (lo + hi) / 2
        if to_f(mid) < f: lo = mid             # too cold, keep the upper half
        else: hi = mid                         # too warm, keep the lower half
    return (lo + hi) / 2

def fare(m): return 3.0 + 2.0 * m              # the taxi: $3 to start, $2 a mile
def miles(f): return (f - 3.0) / 2.0           # the same formula, rearranged

def grid(name, values): print(f"{name:<26}" + "".join(f"{v:>7}" for v in values))
def one(name, value): print(f"{name:<48}{value:>10}")

print(f"forward   1.8 x 25 = {SLOPE * 25:.1f}, then {SLOPE * 25:.1f} + 32 = "
      f"{to_f(25):.1f} degrees F")
print(f"backward  77 - 32 = {77 - OFFSET:.1f}, then {77 - OFFSET:.1f} / 1.8 = "
      f"{to_c(77):.1f} degrees C")
cs = [0, 5, 10, 15, 20, 25]
fs = [to_f(c) for c in cs]
grid("C, degrees Celsius", [f"{c:.0f}" for c in cs])
grid("F, degrees Fahrenheit", [f"{f:.0f}" for f in fs])
grid("back to C, rearranged", [f"{to_c(f):.0f}" for f in fs])
one("77 F in Celsius, the rearranged formula", f"{to_c(77.0):.1f}")
one("77 F in Celsius, hunted in the original formula", f"{hunt(77.0):.1f}")
one("5 miles in the taxi costs", f"${fare(5):.2f}")
print(f"taxi      13.00 - 3 = {13.0 - 3.0:.2f}, then {13.0 - 3.0:.2f} / 2 = "
      f"{miles(13.0):.1f} miles")
wrong_order = 77 / SLOPE - OFFSET              # divided before subtracting
no_brackets = 77 - OFFSET / SLOPE              # only the 32 got divided
wrong_sign = (77 + OFFSET) / SLOPE             # added instead of subtracted
print(f"the three wrong roads give {wrong_order:.2f}, {no_brackets:.2f} and "
      f"{wrong_sign:.2f} degrees C, not {to_c(77.0):.1f}")
one("a $13.00 fare with the $3 flagfall forgotten", f"{13.0 / 2.0:.1f} miles")
PI = 3.14159265358979                          # written out, nothing imported
radius = (12.0 / PI) ** 0.5                    # area = PI x radius x radius
one("a rug of area 12.00 square feet has radius", f"{radius:.4f} feet")
rate = (162.89 / 100.0) ** (1 / 10) - 1        # a tenth power, undone the same way
one("$100.00 to $162.89 in 10 years is a rate of", f"{rate * 100:.2f}% a year")
assert (to_f(25) == 77.0 and to_c(77.0) == 25.0 and fs == [32, 41, 50, 59, 68, 77]
        and abs(hunt(77.0) - 25.0) < 1e-9 and abs(hunt(212.0) - 100.0) < 1e-9)
assert fare(5) == 13.0 and miles(13.0) == 5.0 and 13.0 / 2.0 == 6.5
assert (round(wrong_order, 2), round(no_brackets, 2), round(wrong_sign, 2)) == (10.78, 59.22, 60.56)
assert round(radius, 4) == 1.9544 and round(rate * 100, 2) == 5.00
print("ALL CHECKS PASS")
