# Compounding more often, and the number e -- the check behind the card.  Nothing
# is imported.  $1 at 100% for a year, the rate split n ways and multiplied in n
# times, then the same ceiling a second way: the series 1 + 1 + 1/2 + 1/6 + ...
def ladder(rate, n):                   # (1 + rate/n) multiplied in, n times over
    total = 1.0
    for _ in range(n):
        total = total * (1.0 + rate / n)
    return total
def series(rate):                      # 1 + rate + rate x rate / 2 + ... , 20 terms
    total, term = 0.0, 1.0
    for k in range(1, 21):
        total, term = total + term, term * rate / k
    return total
def row(name, value, places):
    print(f"{name:<33}{value:>13.{places}f}")
for name, n in (("paid once a year", 1), ("paid twice a year", 2),
                ("paid monthly, 12 times", 12), ("paid daily, 365 times", 365),
                ("paid a million times", 1000000)):
    row(name, ladder(1.0, n), 6)
row("the ceiling, e by the series", series(1.0), 6)
row("e, to nine decimals", series(1.0), 9)
yearly, cont = 100.0 * ladder(0.05, 1), 100.0 * series(0.05)
row("$100 at 5%, paid once a year", yearly, 2)
row("$100 at 5%, paid continuously", cont, 6)
row("$100 continuous, to the cent", round(cont, 2), 2)
assert abs(ladder(1.0, 2) - 2.25) < 1e-12
assert abs(series(1.0) - ladder(1.0, 1000000)) < 1e-5
assert round(yearly, 2) == 105.00 and round(cont, 2) == 105.13
print("ALL CHECKS PASS")
