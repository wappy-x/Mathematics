# Decimals -- the check behind the card.  Nothing is imported.  Petrol at
# $1.85 a litre into a 42.5-litre tank, and a receipt that has to land on a
# whole cent.  Three roads to the same total, all of them in whole numbers.
def row(name, value):
    print(f"{name:<36}{value:>9}")
def point(thousandths):            # 78625 -> "78.625", the point put back by hand
    return f"{thousandths // 1000}.{thousandths % 1000:03d}"
def money(cents):                  # 7863 -> "78.63"
    return f"{cents // 100}.{cents % 100:02d}"
price, litres = 185, 425           # $1.85 as hundredths, 42.5 litres as tenths
total = price * litres             # thousandths of a dollar
row("$1.85 is 185 over 100", price)
row("42.5 litres is 425 over 10", litres)
row("185 x 425, both whole numbers", total)
row("78625 over 1000, the point back", point(total))
top, bottom = 37 * 85, 20 * 2      # the fraction road, 3145 over 40
row("37/20 x 85/2 = 3145/40, reduced", f"{top // 5}/{bottom // 5}")
row("629 divided by 8", point(top * 1000 // bottom))
whole, half = price * 420, price * 5      # 42 litres, then the last half litre
row(f"42 litres {point(whole)}, half litre {point(half)}", point(whole + half))
cents = (total + 5) // 10          # to the nearest cent, a half cent goes up
row("the receipt, rounded to the cent", money(cents))
row("columns right of the point", "0.1 0.01 0.001")
print(f"mistakes: {money(total // 10)}, {money(total)}, "
      f"and 43 litres gives {money(price * 430 // 10)}")
assert total == 78625 and top * 1000 // bottom == total    # two roads, one answer
assert whole + half == total and top // 5 == 629 and bottom // 5 == 8
assert cents == 7863 and 629 * 125 == total   # 629/8 is 78.625, and 1/8 is 0.125
assert point(total) == "78.625" and money(cents) == "78.63"  # the printed strings
print("ALL CHECKS PASS")
