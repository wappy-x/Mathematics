# The number families -- the check behind the card.  Nothing is imported.
# A carpenter's job: 3 planks counted, a plank cut 15 cm short, a 100 cm
# off-cut sawn in three, and a 30 cm square tile whose diagonal lands
# between two marks on the tape and stays there.
def row(name, value): print(f"{name:<40}{value:>14}")
planks, want, got, offcut, side = 3, 240, 225, 100, 30
short = got - want                        # 225 - 240, off the bottom of counting
whole, rest = divmod(offcut, 3)           # 100 cm is three 33s and 1 cm over
dsq = side * side + side * side           # the diagonal, multiplied by itself
lo, hi = float(side), float(2 * side)     # longer than a side, shorter than two
for _ in range(60):                       # road 1: squeeze it between two marks
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if mid * mid < dsq else (lo, mid)
guess = float(side)
for _ in range(20): guess = (guess + dsq / guess) / 2   # road 2: guess, average, repeat
row("planks on the job", planks)
row("plank cut short, 225 - 240", short)
row("check, 240 + (-15) back to the cut", want + short)
row("off-cut of 100 cm sawn in three", f"{whole} + {rest}/3 cm")
row("check, three of those back together", whole * 3 + rest)
row("tile diagonal, times itself, 900 + 900", dsq)
row("tile diagonal, squeezed, in cm", f"{lo:.9f}")
row("tile diagonal, second road, in cm", f"{guess:.9f}")
row("rounding that third down to 33 loses", whole * 3)
row("tape mark below, 42.42 x 42.42", f"{4242 * 4242 / 10000:.4f}")
row("tape mark above, 42.43 x 42.43", f"{4243 * 4243 / 10000:.4f}")
assert short == -15 and want + short == got
assert whole == 33 and rest == 1 and whole * 3 + rest == offcut and whole * 3 == 99
assert dsq == 1800 and lo * lo < dsq < hi * hi and abs(lo - guess) < 1e-9
print("ALL CHECKS PASS")
