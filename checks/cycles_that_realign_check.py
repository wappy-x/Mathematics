# When cycles meet again -- the check behind the card.  Nothing is imported.  A Chinese year name pairs a 10-year
# stem cycle with a 12-year branch cycle, counted from 1984, the Wood Rat.  Then the Maya 260-day and 365-day counts.
# Road one divides the product by the biggest number going into both; road two counts up one step at a time.
ELEMENTS = ["Wood", "Wood", "Fire", "Fire", "Earth", "Earth", "Metal", "Metal", "Water", "Water"]
ANIMALS = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
def shared(a, b):                        # the biggest number going into both
    while b: a, b = b, a % b
    return a
def meet(a, b): return a * b // shared(a, b)          # road one
def count_up(a, b):                                   # road two
    n = 1
    while n % a or n % b: n += 1
    return n
def name(n): return ELEMENTS[n % 10] + " " + ANIMALS[n % 12]
year = 2026 - 1984
pairs = sorted({(n % 10, n % 12) for n in range(120)})
bad = (3, 4)
bad_count = sum(1 for n in range(120) if (n % 10, n % 12) == bad)
print(f"2026 is year {year} after 1984, the {name(0)}: stem {year % 10}, branch {year % 12} -- the {name(year)}")
print(f"road one: 10 x 12 = {10 * 12}, shared factor {shared(10, 12)}, so they meet again after {meet(10, 12)} years")
print(f"road two, counting up: both cycles come round together at year {count_up(10, 12)}")
print(f"pairs that ever happen: {len(pairs)} of the {10 * 12} on paper -- both remainders even, or both odd")
print(f"stem 3 with branch 4: happens {bad_count} times in 120 years -- 3 is odd, 4 is even")
print(f"Maya: 260 x 365 = {260 * 365}, shared factor {shared(260, 365)}, so the counts realign after {meet(260, 365)} days")
print(f"{meet(260, 365)} days is {meet(260, 365) // 260} rounds of the 260-day count and {meet(260, 365) // 365} of the 365-day count")
print(f"the three mistakes come out at {10 * 12} years, {260 * 365} days and {260 * 365 // 365} years")
assert year == 42 and (year % 10, year % 12) == (2, 6) and name(year) == "Fire Horse"
assert pairs == sorted((s, b) for s in range(10) for b in range(12) if s % 2 == b % 2) and len(pairs) == 60 and bad_count == 0
assert meet(10, 12) == 60 == count_up(10, 12) and meet(260, 365) == 18980 == 52 * 365 == 73 * 260 and 260 * 365 == 94900
print("ALL CHECKS PASS")
