# Growth factors -- the check behind the card.  Nothing is imported.  Money in
# whole cents, rounded to the nearest cent: an $80 jacket up 25% for the season,
# then 25% off in the sale.  Then half off a second jacket, and half on again.
def after(cents, factor):          # 8000 cents at factor 1.25 -> 10000 cents
    return int(cents * factor + 0.5)
def row(name, cents): print(f"{name:<36}{cents / 100:>9.2f}")
start = 8000
rise = after(start, 1 + 0.25)
cut = after(rise, 1 - 0.25)
pair = after(start, 1.25 * 0.75)             # second road: one factor for both changes
other = after(after(start, 0.75), 1.25)      # third road: the same two changes, swapped
undo = after(rise, 1 / 1.25)
half_off = after(start, 1 - 0.50)
half_on = after(half_off, 1 + 0.50)
pair2 = after(start, 0.50 * 1.50)
wrong_add = after(start, 1.00)               # +25 and -25 read as no change at all
wrong_part = after(start, 0.25)              # 0.25 is the part, not the growth factor
wrong_sum = after(start, 1.25 + 0.75)        # factors chain by multiplying, not adding
for name, cents in [("jacket at the start", start), ("25 percent rise, factor 1.25", rise),
                    ("25 percent cut, factor 0.75", cut), ("the pair as one factor, 0.9375", pair),
                    ("the other order, cut then rise", other), ("undo the rise: 20 percent off, 0.80", undo),
                    ("half off, factor 0.50", half_off), ("half on again, factor 1.50", half_on),
                    ("that pair as one factor, 0.75", pair2)]:
    row(name, cents)
print(f"a 5 percent rise is factor {1 + 0.05:.2f}; 0.9375 is {(1 - 1.25 * 0.75) * 100:.2f} percent down; 0.75 is {(1 - 0.5 * 1.5) * 100:.2f} percent down")
print(f"the three mistakes come out at {wrong_add / 100:.2f}, {wrong_part / 100:.2f} and {wrong_sum / 100:.2f}")
assert rise == 10000 and cut == 7500 and pair == cut
assert other == 7500 and undo == start and pair2 == 6000
assert half_on == 6000 and wrong_add == 8000 and wrong_part == 2000 and wrong_sum == 16000
print("ALL CHECKS PASS")
