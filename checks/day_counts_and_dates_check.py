# Day counts -- the check behind the card.  Nothing is imported.  A note for
# $3,600.00 pays 10 percent a year, simple, so a whole year of accrual pays
# $360.00 and the Actual/360 coupon in dollars equals the day count.  Every
# answer is reached twice: day counts by an ordinal formula and by visiting
# every calendar date, the Actual/Actual fraction in closed form and one day
# at a time, weekdays from the ordinal and by Zeller's congruence.  Money is
# held in whole cents by integer arithmetic, so no rounding can drift.
PAY = 360            # the notional $3,600.00 times the rate 0.10
DEN = 365 * 366      # 133590, one denominator holding both 1/365 and 1/366
MONTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

def leap(y): return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)   # 2000 leap, 1900 not
def year_len(y): return 366 if leap(y) else 365
def month_len(y, m): return 29 if m == 2 and leap(y) else MONTHS[m - 1]
def days(s, e): return ordinal(e) - ordinal(s)                      # road one, by ordinals
def thirty_e(s, e):                                                 # 30E/360, ISDA 4.16(g)
    return 360 * (e[0] - s[0]) + 30 * (e[1] - s[1]) + min(e[2], 30) - min(s[2], 30)
def act_act(s, e): return sum(k * (DEN // L) for _, k, L in pieces(s, e))   # over DEN
def cents(num, den): return (200 * PAY * num + den) // (2 * den)    # to the nearest cent
def dollars(c): return f"${c // 100}.{c % 100:02d}"
def show(dt): return f"{dt[0]:04d}-{dt[1]:02d}-{dt[2]:02d}"
def yn(claim): return "yes" if claim else "no"
def weekday(dt): return ordinal(dt) % 7          # 1 January of year 1 was a Monday
def business(dt, hols): return weekday(dt) < 5 and dt not in hols

def ordinal(dt):                         # days since 1 January of year 1, zero based
    y, m, d = dt
    z = y - 1
    return (365 * z + z // 4 - z // 100 + z // 400
            + sum(month_len(y, k) for k in range(1, m)) + d - 1)

def visited(s, e):                       # road two: visit every date on the calendar
    return sum(1 for y in range(s[0], e[0] + 1) for m in range(1, 13)
               for d in range(1, month_len(y, m) + 1) if s <= (y, m, d) < e)

def next_day(dt):
    y, m, d = dt
    if d < month_len(y, m): return (y, m, d + 1)
    return (y, m + 1, 1) if m < 12 else (y + 1, 1, 1)

def prev_day(dt):
    y, m, d = dt
    if d > 1: return (y, m, d - 1)
    return (y, m - 1, month_len(y, m - 1)) if m > 1 else (y - 1, 12, 31)

def pieces(s, e):                        # Actual/Actual ISDA: days in each calendar year
    out = []
    for y in range(s[0], e[0] + 1):
        lo, hi = max(s, (y, 1, 1)), min(e, (y + 1, 1, 1))
        if lo < hi: out.append((y, days(lo, hi), year_len(y)))
    return out

def one_at_a_time(s, e):                 # road two: add one day's share at a time
    total, cur = 0, s
    while cur < e: total, cur = total + DEN // year_len(cur[0]), next_day(cur)
    return total

def gcd(a, b):
    while b: a, b = b, a % b
    return a

def zeller(dt):                          # road two to the weekday, Monday as 0
    y, m, d = dt
    if m < 3: y, m = y - 1, m + 12
    return ((d + (13 * (m + 1)) // 5 + y + y // 4 - y // 100 + y // 400) % 7 + 5) % 7

def modified_following(dt, hols):        # forward, but back if the month changes
    if business(dt, hols): return dt
    f = next_day(dt)
    while not business(f, hols): f = next_day(f)
    if f[1] == dt[1]: return f
    b = prev_day(dt)
    while not business(b, hols): b = prev_day(b)
    return b

def report(label, s, e):
    n, h, aa = days(s, e), thirty_e(s, e), act_act(s, e)
    split = " + ".join(f"{k} in {y} over {L}" for y, k, L in pieces(s, e))
    print(f"{label}: {show(s)} to {show(e)}")
    print(f"  actual days {n} by ordinals, {visited(s, e)} by visiting every date; "
          f"30E/360 numerator {h}; Act/Act days {split}")
    for name, num, den in (("30E/360     ", h, 360), ("Actual/360  ", n, 360),
                           ("Act/Act ISDA", aa, DEN)):
        print(f"  {name}  year fraction {num / den:.6f}  coupon {dollars(cents(num, den))}")
    return n, h, aa

S1, E1, MID = (2007, 1, 15), (2007, 3, 1), (2007, 2, 1)
S2, E2 = (2007, 9, 1), (2008, 3, 1)
S3, E3 = (2008, 3, 1), (2008, 5, 31)
PAYS = [(2007, 3, 1), (2007, 9, 1), (2008, 3, 1), (2008, 5, 31)]
OFFSETS = [0, 15, 30, 45, 60, 75, 90]
print("A note for $3,600.00 at 10 percent a year, simple: a whole year accrues $360.00")
n1, h1, a1 = report("first period, the 45-day stub", S1, E1)
g = gcd(PAY * a1, DEN)
print(f"  Act/Act coupon exactly {PAY * a1 // g}/{DEN // g} dollars = {PAY * a1 / DEN:.6f}; "
      f"one day at a time agrees: {yn(one_at_a_time(S1, E1) == a1)}")
print(f"  widest gap, 30E/360 less Act/Act: {dollars(cents(h1, 360) - cents(a1, DEN))}")
n2, _, a2 = report("second period, across the leap year", S2, E2)
print(f"  one flat 365 instead of the year split: {n2 / 365:.6f}, coupon {dollars(cents(n2, 365))}")
n3, _, _ = report("final stub, due at the month end", S3, E3)
print(f"additivity at {show(MID)}: Actual/360 {days(S1, MID)} + {days(MID, E1)} = {days(S1, E1)}; "
      f"30E/360 {thirty_e(S1, MID)} + {thirty_e(MID, E1)} = {thirty_e(S1, E1)}")
ends, cur, k = [], S1, 0
for off in OFFSETS:
    while k < off: cur, k = next_day(cur), k + 1
    ends.append(cur)
print("accrued from 2007-01-15, in dollars, against days of elapsed calendar time")
print("  elapsed days  " + "".join(f"{o:>7}" for o in OFFSETS))
print("  30E/360       " + "".join(f"{dollars(cents(thirty_e(S1, x), 360)):>7}" for x in ends))
print("  Actual/360    " + "".join(f"{dollars(cents(days(S1, x), 360)):>7}" for x in ends))
print("  Act/Act ISDA  " + "".join(f"{dollars(cents(act_act(S1, x), DEN)):>7}" for x in ends))
print("payment dates: weekday by two roads, then modified following, weekends closed")
for p in PAYS:
    r = modified_following(p, set())
    moved = "stays put" if r == p else f"moves to {show(r)}, a {NAMES[weekday(r)]}"
    print(f"  {show(p)}  {NAMES[weekday(p)]:<9} by ordinal, {NAMES[zeller(p)]:<9} by Zeller; {moved}")
print(f"  with 2008-03-03 a stated holiday, 2008-03-01 moves forward to "
      f"{show(modified_following((2008, 3, 1), {(2008, 3, 3)}))}")
print(f"  with 2008-05-30 a stated holiday, 2008-05-31 moves back to "
      f"{show(modified_following((2008, 5, 31), {(2008, 5, 30)}))}")
u, v, jan = (2007, 2, 28), (2007, 3, 31), ((2007, 1, 30), (2007, 1, 31))   # 30E/360 reads jan as 0
unclipped = 360 * (v[0] - u[0]) + 30 * (v[1] - u[1]) + v[2] - u[2]
rolled = days(S3, (2008, 5, 30))
print("what breaks")
print(f"  counting both endpoints: {n1 + 1} days, Actual/360 coupon "
      f"{dollars(cents(n1 + 1, 360))}, not {dollars(cents(n1, 360))}")
print(f"  leaving the 31st unclipped, {show(u)} to {show(v)}: {unclipped} days, not {thirty_e(u, v)}")
print(f"  one flat 365 across the leap year: coupon {dollars(cents(n2, 365))}, "
      f"not {dollars(cents(a2, DEN))}")
print(f"  accruing to the rolled date, {show(S3)} to 2008-05-30: {rolled} days, "
      f"Actual/360 coupon {dollars(cents(rolled, 360))}, not {dollars(cents(n3, 360))}")
assert days(S1, E1) == visited(S1, E1) == 45 and days(S2, E2) == visited(S2, E2) == 182
assert act_act(S1, E1) == one_at_a_time(S1, E1) and act_act(S2, E2) == one_at_a_time(S2, E2)
assert act_act(S2, E2) == 122 * 366 + 60 * 365 and thirty_e(S2, E2) == 180
assert days(S1, MID) + days(MID, E1) == 45 and thirty_e(S1, MID) + thirty_e(MID, E1) == 46
assert [weekday(p) for p in PAYS] == [zeller(p) for p in PAYS]
assert [modified_following(p, set()) for p in PAYS] == [E1, (2007, 9, 3), (2008, 3, 3), (2008, 5, 30)]
assert (cents(h1, 360), cents(n1, 360), cents(a1, DEN), thirty_e(u, v), rolled, thirty_e(*jan), days(*jan)) == (4600, 4500, 4438, 32, 90, 0, 1)
print("ALL CHECKS PASS")
