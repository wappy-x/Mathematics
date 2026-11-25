# Place value -- the check behind the card.  Nothing is imported.  The apple stall
# in cents (12 apples at 75 cents, a $10 bill, 4 friends), then numerals by column.
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
week = [5, 2, 3]                # the stall's board, biggest column first
for digits in (week, [9, 0, 0], [2, 2, 5]):
    row(" + ".join(f"{d} x {p}" for d, p in zip(digits, PLACES)), worth(digits))
worths, nines = [10 ** k for k in range(5)], [10 ** k - 1 for k in range(5)]
print(f"{'what one column is worth':<26}" + "".join(f"{v:>7}" for v in worths))
print(f"{'all 9s to its right':<26}" + "".join(f"{v:>7}" for v in nines))
print(f"the three mistakes come out at {worth([0, 9, 0])}, {worth([3, 2, 5])} and {5 + 2 + 3}")
backwards = [523 // 10 ** k % 10 for k in (2, 1, 0)]   # divide by ten, keep the remainder
assert total == 900 and change == 100 and total + change == bill and share * friends == total == 4 * 225
assert all(w == n + 1 for w, n in zip(worths, nines)) and backwards == [5, 2, 3]
assert worth(week) == 523 and worth([9, 0, 0]) == total
print("ALL CHECKS PASS")
