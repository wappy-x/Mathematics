# Compound interest -- the check behind the card.  Nothing is imported.  $100
# in a savings account paying 5% a year, the interest left in.  Dollars are
# rounded to the cent for printing only; the running balance is kept in full.
YEARS, START, RATE = 10, 100.0, 0.05

comp, simp = [START], [START]                 # year 0: $100 in each account
for _ in range(YEARS):                        # one road: a year at a time
    comp.append(comp[-1] * (1 + RATE))        # 5% of the balance, left in
    simp.append(simp[-1] + START * RATE)      # 5% of the first $100, taken out

def grid(name, values): print(f"{name:<32}" + "".join(f"{v:>7}" for v in values))
def one(name, value): print(f"{name:<44}{value:>10}")

grid("year", list(range(YEARS + 1)))
grid("compound, interest left in", [f"{v:.2f}" for v in comp])
grid("simple, interest taken out", [f"{v:.2f}" for v in simp])
print(f"interest earned in years 1, 2, 3 and 10: {comp[1] - comp[0]:.2f}, "
      f"{comp[2] - comp[1]:.2f}, {comp[3] - comp[2]:.2f} and {comp[10] - comp[9]:.2f}")
one("after ten years, interest left in", f"{comp[10]:.2f}")
one("after ten years, interest taken out", f"{simp[10]:.2f}")
one("the gap", f"{comp[10] - simp[10]:.2f}")
exact = 105 ** YEARS                          # second road: whole numbers only
cents = (exact + 5 * 10 ** 15) // 10 ** 16    # $100 x 105^10 / 100^10, to the cent
one("the same balance, from whole numbers", f"{cents // 100}.{cents % 100:02d}")
print(f"the three mistakes come out at {simp[10]:.2f}, "
      f"{START * (1 + RATE):.2f} and {START * (1 + RATE) * 0.95:.2f}")
assert cents == 16289 and round(comp[10] * 100) == cents and len(comp) == len(simp) == YEARS + 1
assert abs(comp[5] * comp[5] / START - comp[10]) < 1e-9   # five years, then squared
assert simp[10] == 150.0 and round((comp[10] - simp[10]) * 100) == 1289
print("ALL CHECKS PASS")
