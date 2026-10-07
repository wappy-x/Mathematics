# Multiplying and dividing -- the check behind the card.  Nothing is imported.
# The plain way first, then the same answers again by adding, as a cross-check.

def added_up(count, size):            # size added to itself, count times over
    total = 0
    for _ in range(count):
        total = total + size
    return total

def row(label, value): print(f"{label:<36}{value:>28}")

cost = 12 * 75                        # twelve apples at 75 cents each
change = 1000 - cost                  # handed over a $10 bill, which is 1000 cents
each, over = cost // 4, cost % 4      # the money split four ways
zeros = [q for q in range(0, 100) if added_up(q, 0) == 12]   # nothing here works
assert cost == added_up(12, 75), "adding 75 twelve times must give the same total"
assert added_up(each, 4) + over == cost, "four lots of 225 must rebuild the 900"
assert added_up(14 // 4, 4) + 14 % 4 == 14, "three each and two over must rebuild 14"
row("12 apples at 75 cents each", f"{cost} cents")
row("that in dollars", f"{cost // 100}.{cost % 100:02d}")
row("change from the 1000-cent bill", f"{change} cents")
row("cross-check, 75 added 12 times", f"{added_up(12, 75)} cents")
row("900 cents shared by 4 friends", f"{each} each, {over} over")
row("each friend pays, in dollars", f"{each // 100}.{each % 100:02d}")
row("cross-check, 4 lots of 225", f"{added_up(each, 4) + over} cents")
row("12 apples shared by 4 friends", f"{12 // 4} each, {12 % 4} over")
row("14 apples shared by 4 friends", f"{14 // 4} each, {14 % 4} over")
row("cross-check, 4 lots of 3, plus 2", f"{added_up(14 // 4, 4) + 14 % 4} apples")
row("any number of 0s adding up to 12", f"{len(zeros)} found under 100")
print("ALL CHECKS PASS")
