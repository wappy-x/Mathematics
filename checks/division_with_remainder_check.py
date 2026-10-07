# Division with a remainder -- the check behind the card.  Nothing is imported.
# A 365-day year measured in 7-day weeks, then a 366-day leap year, then the
# weekday a 6 September birthday lands on, 2026 to 2029.
DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

def strip(total, size):            # the long way: take 7 away until under 7 is left
    q = 0
    while total >= size:
        total, q = total - size, q + 1
    return q, total

def row(name, total, q, r):
    print(f"{name:<30}{total:>7}{q:>7}{r:>11}")

print(f"{'what':<30}{'total':>7}{'weeks':>7}{'days over':>11}")
row("ordinary year", 365, 365 // 7, 365 % 7)   # // whole weeks, % days over
row("leap year", 366, 366 // 7, 366 % 7)
row("by taking 7 away over and over", 365, *strip(365, 7))
pairs = [(q, 365 - 7 * q) for q in range(100) if 0 <= 365 - 7 * q < 7]
print(f"quotient-and-leftover pairs with the leftover under 7: {len(pairs)}")
moved = [0]
for length in (365, 366, 365):
    moved.append((moved[-1] + length % 7) % 7)
print("6 September: " + ", ".join(f"{y} {DAYS[m]}" for y, m in zip(range(2026, 2030), moved)))
print("weekdays moved since 2026: " + ", then ".join(str(m) for m in moved))
print(f"the three mistakes come out at {52 * 7} days, 51 weeks with {365 - 51 * 7} days over, and {DAYS[3]}")
assert (365 // 7, 365 % 7) == (52, 1) and 52 * 7 + 1 == 365
assert (366 // 7, 366 % 7) == (52, 2) and strip(365, 7) == (52, 1)
assert pairs == [(52, 1)] and moved == [0, 1, 3, 4]
print("ALL CHECKS PASS")
