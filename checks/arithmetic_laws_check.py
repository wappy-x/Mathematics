# The three rearranging laws -- the check behind the card.  No imports.
# Twelve apples at 75 cents, a ten-dollar bill (1000 cents), four friends.
# The bill is done the obvious way, then by a second route; then the three laws.
APPLES, PRICE, BILL, FRIENDS = 12, 75, 1000, 4

def show(label, value):
    print(f"{label:<33}{value:>6}")

bill = APPLES * PRICE                    # obvious way: 12 lots of 75 cents
bill_again = FRIENDS * (3 * PRICE)       # second route: 4 friends, 3 apples each
first, second = APPLES * 70, APPLES * 5  # spreading: the 75 cut into 70 and 5
change = BILL - bill
share = bill // FRIENDS
half = APPLES * 70 + 5                   # a spread that missed the second piece
bad_minus = BILL - (bill - 100)          # a minus that was wrongly regrouped
show("bill, 12 x 75", bill)
show("bill again, 4 x (3 x 75)", bill_again)
show("swap, 75 x 12", PRICE * APPLES)
show("regroup, (4 x 3) x 75", (FRIENDS * 3) * PRICE)
show("spread, 12 x 70", first)
show("spread, 12 x 5", second)
show("spread, 840 + 60", first + second)
show("change, 1000 - 900", change)
show("each friend, 900 / 4", share)
show("wrong, 12 x 70 + 5", half)
show("wrong, 1000 - (900 - 100)", bad_minus)
assert bill == 900 and bill_again == bill and PRICE * APPLES == bill, "swap and regroup hold"
assert first + second == bill and change == 100 and share == 225, "spread, change, share"
assert half == 845 and bad_minus == 200, "the two traps"
print("ALL CHECKS PASS")
