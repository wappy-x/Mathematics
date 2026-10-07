# Bond price and yield -- the check behind the card.  Nothing is imported.
# The house bond: face 1000, a 6% coupon paid once a year, five years to run,
# priced when the market yield is 5%.  The price is built four ways that share
# no arithmetic, then tested a fifth way by spending it; the clean and dirty
# prices are built from the calendar, with the day count written out here.
FACE, CRATE, YEARS, Y = 1000.0, 0.06, 5, 0.05

def flows(face, crate, years, k=1):
    """(period number, cash) for every payment; the last one carries the face."""
    n, c = years * k, face * crate / k
    return [(t, c + (face if t == n else 0.0)) for t in range(1, n + 1)]

def price(face, crate, y, years, k=1):
    """Road 1: discount every payment on its own, then add them up."""
    return sum(cf / (1.0 + y / k) ** t for t, cf in flows(face, crate, years, k))

def annuity(n, i):
    """Value today of 1 at the end of each of n periods, i a period."""
    return (1.0 - (1.0 + i) ** (-n)) / i

def price_closed(face, crate, y, years):
    """Road 2: the coupons as one annuity, plus the face discounted once."""
    return face * crate * annuity(years, y) + face * (1.0 + y) ** (-years)

def price_rollback(face, crate, y, years):
    """Road 3: start at maturity holding nothing, walk back a year at a time."""
    v = 0.0
    for t in range(years, 0, -1):
        v = (v + face * crate + (face if t == years else 0.0)) / (1.0 + y)
    return v

def price_par_split(face, crate, y, years):
    """Road 4: the face, plus the slice of each coupon above the market's rate."""
    return face + (face * crate - y * face) * annuity(years, y)

def account(start, face, crate, y, years):
    """Road 5: a savings account paying the coupons out; the balances it leaves."""
    bal, path = start, [start]
    for _ in range(years):
        bal = bal * (1.0 + y) - face * crate
        path.append(bal)
    return path

def day_number(y, m, d):
    """Days from 1970-01-01 to a civil date, leap years and all."""
    y -= 1 if m <= 2 else 0
    era = (y if y >= 0 else y - 399) // 400
    yoe = y - era * 400
    doy = (153 * (m - 3 if m > 2 else m + 9) + 2) // 5 + d - 1
    return era * 146097 + yoe * 365 + yoe // 4 - yoe // 100 + doy - 719468

def row(label, value):
    print(f"{label:<46}{value:>15.6f}")

def strip(label, values):
    print(f"{label:<42}" + "".join(f"{v:>10.2f}" for v in values))

p1 = price(FACE, CRATE, Y, YEARS)
p2 = price_closed(FACE, CRATE, Y, YEARS)
p3 = price_rollback(FACE, CRATE, Y, YEARS)
p4 = price_par_split(FACE, CRATE, Y, YEARS)
path = account(p1, FACE, CRATE, Y, YEARS)
par_path = [price(FACE, CRATE, Y, n) for n in range(YEARS, 0, -1)] + [FACE]
pvs = [cf * (1.0 + Y) ** (-t) for t, cf in flows(FACE, CRATE, YEARS)]

print(f"the house bond: face {FACE:.2f}, coupon {CRATE * 100:.2f}% once a year, "
      f"{YEARS} payments, market yield {Y * 100:.2f}%")
for t, cf in flows(FACE, CRATE, YEARS):
    d = (1.0 + Y) ** (-t)
    print(f"  year {t}  cash {cf:>9.2f}  discount factor D({t}) {d:.6f}"
          f"  present value {cf * d:>11.6f}")
strip("present values, to the cent", pvs)
row("road 1  the five present values added", p1)
row("road 2  coupon annuity plus the face", p2)
row("road 3  rolled back from maturity", p3)
row("road 4  face plus the coupon above the yield", p4)
row("road 5  savings account, balance at year 5", path[YEARS])
row("annuity factor for 5 years at 5%", annuity(YEARS, Y))
row("the five coupons, 60 x the annuity factor", FACE * CRATE * annuity(YEARS, Y))
row("the face, 1000 x D(5)", FACE * (1.0 + Y) ** (-YEARS))
row("coupon above the market's rate, 60 - 50", FACE * CRATE - Y * FACE)
row("price above face, the premium paid", p1 - FACE)

ys = [0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09]
strip("price at yields 3% to 9%", [price(FACE, CRATE, yy, YEARS) for yy in ys])
strip("value just after each coupon, years 0-5", par_path)
strip("savings account balances, years 0-5", path)

first, settle, second = day_number(2026, 3, 15), day_number(2026, 9, 15), day_number(2027, 3, 15)
elapsed, full = settle - first, second - first
w = elapsed / full
accrued = FACE * CRATE * w
daily = sum(FACE * CRATE / full for _ in range(elapsed))
dirty_a = p1 * (1.0 + Y) ** w
dirty_b = sum(cf / (1.0 + Y) ** (t - w) for t, cf in flows(FACE, CRATE, YEARS))
clean = dirty_a - accrued
print(f"settling 2026-09-15: {elapsed} days of the {full}-day coupon period have run")
row("fraction of the period elapsed", w)
row("accrued interest, 60 x 184/365", accrued)
row("the same, earned one day at a time", daily)
row("dirty price, the 15 March price grown at 5%", dirty_a)
row("dirty price, each payment from settlement", dirty_b)
row("clean price, the quote: dirty minus accrued", clean)

row("price when the yield equals the 6% coupon", price(FACE, CRATE, CRATE, YEARS))
row("mistake: cash added with no discounting", sum(cf for _, cf in flows(FACE, CRATE, YEARS)))
row("mistake: yield typed as 5, not 0.05", price(FACE, CRATE, 5.0, YEARS))
row("try: coupon 0%, a zero-coupon bond", price(FACE, 0.0, Y, YEARS))
row("try: 30 years to run instead of 5", price(FACE, CRATE, Y, 30))
row("try: the same 6% paid twice a year", price(FACE, CRATE, Y, YEARS, 2))
row("the half-yearly 5% quote as an annual rate", (1.0 + Y / 2) ** 2 - 1.0)

assert abs(p1 - p2) < 1e-9, "term-by-term sum against the annuity closed form"
assert abs(p1 - p3) < 1e-9, "term-by-term sum against the roll-back recursion"
assert abs(p1 - p4) < 1e-9, "term-by-term sum against the face-plus-premium split"
assert abs(path[YEARS] - FACE) < 1e-9, "spending the price leaves exactly the face"
assert max(abs(a - b) for a, b in zip(path, par_path)) < 1e-9, "balances are the prices"
assert abs(price(FACE, CRATE, CRATE, YEARS) - FACE) < 1e-9, "yield = coupon prices at face"
assert all(price(FACE, CRATE, ys[i], YEARS) > price(FACE, CRATE, ys[i + 1], YEARS)
           for i in range(len(ys) - 1)), "the price falls at every step up in yield"
assert abs(dirty_a - dirty_b) < 1e-9, "two roads to the dirty price"
assert abs(accrued - daily) < 1e-9, "accrued interest: one day's worth, 184 times"
assert par_path[1] < clean < par_path[0], "the clean price sits inside the year's fall"
assert elapsed == 184, "15 March to 15 September 2026 is 184 days"
assert full == 365, "15 March 2026 to 15 March 2027 is 365 days"
print("ALL CHECKS PASS")
