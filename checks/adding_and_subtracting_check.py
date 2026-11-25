# The check behind the card: twelve apples at 75 cents, a $10 bill, four
# friends, everything in whole cents.  Nothing is imported.
APPLES, PRICE, PAID = 12, 75, 1000
# First way: put one apple's price on the pile at a time, keeping the bill.
bill, running = 0, []
for _ in range(APPLES):
    bill = bill + PRICE
    running.append(bill)
# Second way, the cross-check: the tens digits and the ones digits, added as piles.
tens, ones = 0, 0
for _ in range(APPLES):
    tens, ones = tens + PRICE // 10, ones + PRICE % 10
piles = tens * 10 + ones
change, share = PAID - bill, PRICE + PRICE + PRICE
each = change // 4                         # the change, shared four ways
print(f"one apple, cents           {PRICE:>5}")
print(f"twelve apples, added up    {bill:>5}")
print(f"twelve apples, by piles    {piles:>5}")
print(f"   {APPLES} x {PRICE // 10} = {tens} tens, {APPLES} x {PRICE % 10} = {ones} ones")
print(f"paid with, cents           {PAID:>5}")
print(f"change, cents              {change:>5}")
print(f"check: change + bill       {change + bill:>5}")
print(f"one friend's three apples  {share:>5}")
print(f"each friend's change       {each:>5}")
print("running bill, cents:  " + " ".join(str(v) for v in running))
print(f"the three mistakes: {(5 + 5) % 10 + (7 + 7) % 10 * 10}, {1 * 1000 + (9 - 0) * 100}, {900 - 1000}")
assert bill == piles, "the two roads to the bill must agree"
assert change + bill == PAID and each * 4 == change, "change + bill is the note; change splits 4 ways"
assert share + share + share + share == bill, "four shares must be the whole basket"
print("ALL CHECKS PASS")
