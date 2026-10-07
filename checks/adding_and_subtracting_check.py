# The check behind the card: twelve apples at 75 cents, a $10 bill, four
# friends, everything in whole cents.  Nothing is imported.
APPLES, PRICE, PAID, QUARTER = 12, 75, 1000, 25
# First way: put one apple's price on the pile at a time, keeping the bill.
bill, running = 0, []
for _ in range(APPLES):
    bill = bill + PRICE
    running.append(bill)
# Second way, the cross-check: the same total by piles -- twelve sevens in
# the tens column and twelve fives in the ones, exactly as on the card.
tens, ones = 0, 0
for _ in range(APPLES):
    tens, ones = tens + 7, ones + 5
piles = tens * 10 + ones
change = PAID - bill
share = PRICE + PRICE + PRICE
print(f"one apple, cents           {PRICE:>5}")
print(f"twelve apples, added up    {bill:>5}")
print(f"twelve apples, by piles    {piles:>5}")
print(f"   twelve sevens {tens} tens, twelve fives {ones} ones")
print(f"paid with, cents           {PAID:>5}")
print(f"change, cents              {change:>5}")
print(f"check: change + bill       {change + bill:>5}")
print(f"one friend's three apples  {share:>5}")
print(f"one friend's quarter       {QUARTER:>5}")
print("running bill, cents:  " + " ".join(str(v) for v in running))
assert bill == piles, "the two roads to the bill must agree"
assert change + bill == PAID, "the change plus the bill must give back the note"
assert share + share + share + share == bill, "four shares must be the whole basket"
print("ALL CHECKS PASS")
