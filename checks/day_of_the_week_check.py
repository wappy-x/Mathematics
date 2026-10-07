# Day of the week -- the check behind the card.  Nothing is imported.  The rule is
# run for 20 July 1969, the Moon landing, then checked the long way, by counting
# every day since 1 January 1900, which was a Monday.
DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
OFFSET = [0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5]              # January to December
LENGTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
def leap(year):                    # every fourth year, but a century year needs 400
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
def weekday(day, month, year):     # 0 is Sunday; good from 1900 to 2099
    t = day + OFFSET[month - 1] + (year - 1900) + (year - 1900) // 4
    return (t - (1 if leap(year) and month <= 2 else 0)) % 7
def by_counting(day, month, year):  # the long road: every day since 1 January 1900
    n = day - 1 + sum(365 + (1 if leap(y) else 0) for y in range(1900, year))
    return n + sum(LENGTH[m - 1] + (1 if m == 2 and leap(year) else 0) for m in range(1, month))
for name, value in (("the day of the month", 20), ("July's offset", OFFSET[6]),
                    ("years since 1900", 1969 - 1900), ("leap days since 1900", 69 // 4)):
    print(f"{name:<30}{value:>5}")
sums = [20, 20 + OFFSET[6], 20 + OFFSET[6] + 69, 20 + OFFSET[6] + 69 + 17]
print("running sum, piece by piece:  " + ", ".join(str(s) for s in sums))
print(f"{sums[3]} = {sums[3] // 7} x 7 + {sums[3] % 7}, so 20 July 1969 was a {DAYS[weekday(20, 7, 1969)]}")
n = by_counting(20, 7, 1969)
print(f"the long road: {n} days on from Monday, {n} = {n // 7} x 7 + {n % 7}, a {DAYS[(1 + n) % 7]}")
print("1 January 1900 " + DAYS[weekday(1, 1, 1900)] + ", 1 January 1904 " + DAYS[weekday(1, 1, 1904)]
      + ", 6 September 2026 " + DAYS[weekday(6, 9, 2026)])
print(f"the three mistakes come out at {DAYS[(sums[3] - 17) % 7]}, {DAYS[(sums[3] - OFFSET[6]) % 7]} and {DAYS[(1 + 0 + 4 + 1) % 7]}")
assert weekday(20, 7, 1969) == (1 + n) % 7 == 0 and sums[3] == 112
assert all(weekday(d, m, y) == (1 + by_counting(d, m, y)) % 7 for y in (1900, 1904, 1943, 2000, 2026, 2099) for m in range(1, 13) for d in (1, 28))
assert n == 25402 and not leap(1900) and leap(2000)
print("ALL CHECKS PASS")
