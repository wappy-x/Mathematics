# Discounting -- the check behind the card.  Nothing is imported.  A $100 payment
# due later, priced today at 5%: divide by 1.05 once a year, then continuously.
FACE, RATE, YEARS = 100.0, 0.05, 10
def series(x):                      # 1 + x + x times x / 2 + ... , 20 terms
    total, term = 0.0, 1.0
    for k in range(1, 21): total, term = total + term, term * x / k
    return total
def back(n):                        # the payment divided by 1.05, n times over
    value = FACE
    for _ in range(n): value = value / (1.0 + RATE)
    return value
def row(name, value, places): print(f"{name:<38}{value:>12.{places}f}")
def grid(name, values): print(f"{name:<30}" + "".join(f"{v:>7}" for v in values))
grid("years until the payment", [str(y) for y in range(YEARS + 1)])
grid("the payment itself, always", [f"{FACE:.2f}" for _ in range(YEARS + 1)])
grid("what it is worth today", [f"{back(y):.2f}" for y in range(YEARS + 1)])
one, ten, grow = back(1), back(YEARS), series(RATE)
row("discount factor, one year", one / FACE, 6)
row("$100 due in one year, worth today", one, 2)
row("discount factor, ten years", ten / FACE, 6)
row("$100 due in ten years, worth today", ten, 2)
row("continuous growth factor, one year", grow, 6)
row("continuous discount factor, one year", 1.0 / grow, 6)
row("$100 due in one year, continuously", FACE / grow, 2)
print(f"the three mistakes come out at {FACE * 0.95:.2f}, {one:.2f} and {FACE * 0.95 ** YEARS:.2f}")
exact = (2 * 10000 * 20 ** YEARS + 21 ** YEARS) // (2 * 21 ** YEARS)   # whole numbers only
assert exact == 6139 and round(ten * 100) == exact and round(one * 100) == 9524
assert abs(ten * (1.0 + RATE) ** YEARS - FACE) < 1e-9        # discounted, then grown back
assert abs(1.0 / grow - series(-RATE)) < 1e-12 and round(FACE / grow * 100) == 9512
print("ALL CHECKS PASS")
