# Simple interest -- the check behind the card.  Nothing is imported.  $500
# lent to a cousin at 4% a year, simple interest, for five years.  Two roads:
# the one-line formula, and adding the same $20.00 on five times.
principal, rate, years = 500.00, 0.04, 5

def row(name, value):
    print(f"{name:<38}{'$' + format(value, '.2f'):>10}")

per_year = principal * rate                      # the same $20.00 every year
balance, steps = principal, [principal]
for _ in range(years):                           # road 1: add it on, year by year
    balance = balance + per_year
    steps.append(balance)
by_formula = principal * rate * years            # road 2: straight to the total
compound, wrong_rate = principal, principal + principal * 4 * years
for _ in range(years):
    compound = compound * (1 + rate)             # the mistake: interest on interest
row("principal lent to the cousin", principal)
row("interest each year, 500.00 x 0.04", per_year)
print(f"{'balance, years 0 to 5':<38}" + " ".join(f"${b:.2f}" for b in steps))
row("interest after five years, added up", balance - principal)
row("the same by principal x rate x years", by_formula)
row("step from each year to the next", steps[1] - steps[0])
row("to repay after five years", balance)
row("if the interest earned interest", compound)
row("if 4% were read as 4", wrong_rate)
assert abs(per_year - 20.00) < 1e-9 and abs(balance - 600.00) < 1e-9
assert abs(by_formula - 100.00) < 1e-9 and abs(balance - principal - by_formula) < 1e-9
assert all(abs(b - (500.00 + 20.00 * i)) < 1e-9 for i, b in enumerate(steps))
print("ALL CHECKS PASS")
