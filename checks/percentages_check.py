# Percentages -- the check behind the card.  Nothing is imported.  Whole cents
# throughout: an $80 jacket, 25% off, then 8% sales tax at the till, and a 15%
# tip on a $46 dinner.  Two roads to the till total, then both undone.
def part(amount, percent):        # 25 percent of 8000 cents -> 2000 cents
    return amount * percent // 100
def row(name, cents):
    print(f"{name:<34}{cents / 100:>8.2f}")
tag, dinner = 8000, 4600
discount = part(tag, 25)
sale = tag - discount
tax = part(sale, 8)
till = sale + tax
till_2 = part(part(tag, 100 - 25), 100 + 8)     # second road: one multiply each way
back_to_sale = till * 100 // (100 + 8)          # undo the tax
back_to_tag = back_to_sale * 100 // (100 - 25)  # undo the cut
tip15, tip18 = part(dinner, 15), part(dinner, 18)
wrong_add = part(tag, 100 - 17)                 # 25 off then 8 on is not 17 off
wrong_back = part(sale, 100 + 25)               # adding 25 back does not undo a cut
wrong_pts = (tip15 * 103 + 50) // 100           # "three percent more", not three points
for name, cents in [("jacket tag price", tag), ("25 percent off, the discount", discount),
                    ("sale price", sale), ("8 percent sales tax", tax),
                    ("total at the till", till), ("the one-multiply road agrees", till_2),
                    ("reversed from the till, the tag", back_to_tag), ("dinner bill", dinner),
                    ("tip at 15 percent", tip15), ("tip at 18 percent, three points", tip18)]:
    row(name, cents)
print(f"mistakes: {wrong_add / 100:.2f}, {wrong_back / 100:.2f} and {wrong_pts / 100:.2f}")
assert discount == 2000 and sale == 6000 and till == 6480
assert till_2 == till and back_to_sale == sale and back_to_tag == tag
assert tip15 == 690 and tip18 == 828 and wrong_add == 6640 and wrong_back == 7500 and wrong_pts == 711
print("ALL CHECKS PASS")
