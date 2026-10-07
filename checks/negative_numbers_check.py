# Negative numbers -- the check behind the card.  Nothing is imported.
# One bank account, in whole dollars: $40 paid in, a $65 bill out, then three
# $25 fees, then the bank cancels all three.  Plus a thermometer, in degrees.
def row(name, value):
    print(f"{name:<37}{value:>5}")

paid_in, bill, fee, months = 40, 65, 25, 3
balance = paid_in - bill                     # take the bill away: 40 - 65
opposite = paid_in + (-bill)                 # second route: add the opposite of 65
cold = -3 - 5                                # 3 below zero, 5 degrees colder
charged = months * (-fee)                    # three fees of 25 in the red
cancelled = (-months) * (-fee)               # those same three fees taken back off
run = [0, paid_in, balance, balance + charged, balance + charged + cancelled]
row("paid in 40, then a bill of 65", balance)
row("the same, as 40 + (-65)", opposite)
row("3 below zero, 5 degrees colder", cold)
row("three fees, 3 x (-25)", charged)
row("the bank cancels them, (-3) x (-25)", cancelled)
row("that debt over 3 months, -75 / 3", charged // months)
row("how many -25 fees make -75", charged // (-fee))
print("running balance " + " ".join(str(v) for v in run))
print(f"the three mistakes come out at {balance + charged + (-months * fee)}, "
      f"{bill - paid_in} and {-3 + 5}")
assert months * fee + months * (-fee) == 0 and charged == -75    # spreading fixes the sign
assert (-months) * fee + cancelled == 0 and cancelled == 75      # spreading again
assert balance == -25 and opposite == balance and cold == -8
print("ALL CHECKS PASS")
