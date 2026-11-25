# Multiplying and dividing -- the check behind the card.  Nothing is imported.
# The plain way first, then the same answers again by adding, as a cross-check.
def added_up(count, size):            # size added to itself, count times over
    total = 0
    for _ in range(count):
        total = total + size
    return total

def row(label, value): print(f"{label:<36}{value:>28}")
price, friends = 75, 4                # cents for one apple; people sharing
cost = 12 * price                     # twelve apples
change = 1000 - cost                  # handed over a $10 bill, which is 1000 cents
each, over = cost // friends, cost % friends     # the money shared out
zeros = [q for q in range(0, 100) if added_up(q, 0) == 12]   # nothing here works
assert cost == added_up(12, price) == added_up(price, 12), "12 lots of 75 is 75 lots of 12"
assert added_up(friends, each) + over == cost, "the shares and the leftover must rebuild the cost"
assert added_up(friends, 14 // friends) + 14 % friends == 14 and zeros == [], "rebuild 14; no 0s make 12"
row(f"12 apples at {price} cents each", f"{cost} cents")
row("that in dollars", f"{cost // 100}.{cost % 100:02d}")
row("change from the 1000-cent bill", f"{change} cents")
row(f"cross-check, {price} added 12 times", f"{added_up(12, price)} cents")
row(f"{cost} cents shared by {friends} friends", f"{each} each, {over} over")
row("each friend pays, in dollars", f"{each // 100}.{each % 100:02d}")
row(f"cross-check, {friends} lots of {each}", f"{added_up(friends, each) + over} cents")
row(f"12 apples shared by {friends} friends", f"{12 // friends} each, {12 % friends} over")
row(f"14 apples shared by {friends} friends", f"{14 // friends} each, {14 % friends} over")
row(f"cross-check, {friends} lots of {14 // friends}, plus {14 % friends}",
    f"{added_up(friends, 14 // friends) + 14 % friends} apples")
row("any number of 0s adding up to 12", f"{len(zeros)} found under 100")
print("ALL CHECKS PASS")
