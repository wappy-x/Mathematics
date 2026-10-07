# Natural log and doubling time -- the check behind the card.  Nothing is
# imported: ln is the series 2 * (y + y*y*y/3 + ...), y = (x - 1)/(x + 1).
# Road one is ln 2 / ln 1.08; road two multiplies 1.08 by itself 9 and 10
# times, and the doubling has to land between the two.
def ln(x):                            # natural log, built here from the series
    y = (x - 1.0) / (x + 1.0)
    term, total, k = y, 0.0, 1
    while abs(term) > 1e-18:
        total, term, k = total + term / k, term * y * y, k + 2
    return 2.0 * total
def grown(factor, years, out=1.0):    # the factor multiplied by itself
    for _ in range(years): out *= factor
    return out
def row(name, value): print(f"{name:<40}{value:>12}")
ln2 = ln(2.0)
eight, five = ln2 / ln(1.08), ln2 / ln(1.05)
row("ln 2", f"{ln2:.6f}")
row("ln 1.08 and ln 1.05", f"{ln(1.08):.6f} and {ln(1.05):.6f}")
row("100 x ln 2, the honest rule number", f"{100 * ln2:.4f}")
for rate, factor in ((8, 1.08), (5, 1.05)):
    row(f"years to double at {rate}%, ln 2 / ln {factor}", f"{ln2 / ln(factor):.3f}")
    row(f"the rule of 72 at {rate}%, 72 / {rate}", f"{72 / rate:.3f}")
row("1.08 multiplied by itself 9 times", f"{grown(1.08, 9):.6f}")
row("1.08 multiplied by itself 10 times", f"{grown(1.08, 10):.6f}")
row("$100 at 5% after 14 years, then 15", f"${100 * grown(1.05, 14):.2f} ${100 * grown(1.05, 15):.2f}")
print(f"the three mistakes come out at {100 / 8}, {ln2 / 0.08:.3f} and {grown(1.08, 9):.6f}")
assert abs(ln(1.25) + ln(1.6) - ln2) < 1e-14 and abs(ln(0.5) / ln(0.9) - 6.579) < 5e-4
assert grown(1.08, 9) < 2.0 < grown(1.08, 10) and f"{100 * grown(1.05, 14):.2f} {100 * grown(1.05, 15):.2f}" == "197.99 207.89"
assert 9 < eight < 10 and 14 < five < 15 and 72 / 8 < eight and five < 72 / 5
print("ALL CHECKS PASS")
