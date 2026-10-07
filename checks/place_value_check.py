# Place value -- the check behind the card.  Nothing is imported.  The apple
# stall in cents: twelve apples at 75 cents, a $10 bill, four friends.  Then
# three numerals, each one read a column at a time.
PLACES = [100, 10, 1]

def worth(digits):              # [5, 2, 3] -> 5 x 100 + 2 x 10 + 3 x 1 -> 523
    return sum(d * p for d, p in zip(digits, PLACES))

def row(name, value):
    print(f"{name:<32}{value:>6}")

apples, price, bill, friends = 12, 75, 1000, 4
total = apples * price
change = bill - total
share = total // friends
row("twelve apples at 75 cents each", total)
row("paid with a $10 bill", bill)
row("change, a $1.00 note", change)
row("each of four friends pays $2.25", share)
row("four shares back together", share * friends)     # the check, going backwards
for digits in ([5, 2, 3], [9, 0, 0], [2, 2, 5]):
    row(" + ".join(f"{d} x {p}" for d, p in zip(digits, PLACES)), worth(digits))
print(f"{'what one column is worth':<26}" + "".join(f"{v:>7}" for v in [1, 10, 100, 1000, 10000]))
print(f"{'all 9s to its right':<26}" + "".join(f"{v:>7}" for v in [0, 9, 99, 999, 9999]))
print(f"the three mistakes come out at {worth([0, 9, 0])}, {worth([3, 2, 5])} and {5 + 2 + 3}")

assert total == 900 and change == 100 and total + change == bill
assert share == 225 and share * friends == total
assert worth([5, 2, 3]) == 523 and worth([9, 0, 0]) == total
print("ALL CHECKS PASS")
