# Ratios and rates -- the check behind the card.  Nothing is imported.  Paint
# mixed 3 parts blue to 2 parts white, scaled up to a 15 litre tin.  A car that
# covers 120 km in 1.5 hours.  Blue paint sold at 3 litres for $2.25.
def row(name, value):
    print(f"{name:<34}{value:>11}")

blue_parts, white_parts, tin = 3, 2, 15
parts = blue_parts + white_parts
per_part = tin // parts                       # what one part is worth, in litres
blue, white = blue_parts * per_part, white_parts * per_part
row("parts in the mix, 3 blue + 2 white", parts)
row("litres in one part, 15 / 5", per_part)
row("blue litres and white litres", f"{blue} and {white}")
row("blue + white, back to the tin", blue + white)

km, hours = 120.0, 1.5
speed = km / hours                            # a rate: kilometres per one hour
row("car speed, 120 km / 1.5 hours", f"{speed:.0f}")
row("distance check, speed x 1.5 hours", f"{speed * hours:.0f}")
row("km by 0.5 hours and by 1 hour", f"{speed * 0.5:.0f} and {speed:.0f}")
price, litres = 2.25, 3
unit = price / litres                         # the same move: dollars per litre
row("unit price, $2.25 / 3 litres", f"{unit:.2f}")
row("twelve litres, 12 x unit price", f"{12 * unit:.2f}")
row("twelve litres, 4 x $2.25", f"{(12 // litres) * price:.2f}")
print(f"the three mistakes: {(tin // blue_parts) * parts} litres, {hours / km:.4f} hours per km, ${12 * price:.2f}")
assert parts == 5 and per_part == 3 and blue == 9 and white == 6 and blue + white == 15
assert speed == 80.0 and speed * hours == 120.0 and speed * 0.5 == 40.0
assert unit == 0.75 and 12 * unit == 9.0 and (12 // litres) * price == 9.0
print("ALL CHECKS PASS")
