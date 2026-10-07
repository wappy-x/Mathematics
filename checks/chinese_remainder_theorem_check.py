# The Chinese remainder theorem -- the check behind the card.  Nothing is
# imported.  Three rotas from a shared reset: day 2 of a 3-day cycle, day 3 of
# a 5-day cycle, day 2 of the 7-day week.  Road one folds two cycles at a time
# with an inverse; road two scans all 105 days of the combined cycle.
CYCLES, DAYS = [3, 5, 7], [2, 3, 2]
def inverse(a, n):                  # the number that undoes multiplying by a
    return next(t for t in range(n) if (a * t) % n == 1)
def fold(day1, cycle1, day2, cycle2):                 # road one: two into one
    inv = inverse(cycle1 % cycle2, cycle2)
    steps = ((day2 - day1) * inv) % cycle2
    print(f"on the {cycle2}-cycle: {cycle1} leaves {cycle1 % cycle2}, undone by {inv}; steps: {steps}")
    return (day1 + cycle1 * steps) % (cycle1 * cycle2)
def fits(cycles, days, span):       # road two: try every day in the span
    return [d for d in range(span) if all(d % c == r for c, r in zip(cycles, days))]
x, m = DAYS[0], CYCLES[0]
for c, r in zip(CYCLES[1:], DAYS[1:]):
    x, m = fold(x, m, r, c), m * c
    print(f"combined so far: day {x} of the {m}-day cycle")
print("by hand: " + ";  ".join(f"{x} = {x // c} x {c} + {x % c}" for c in CYCLES))
print(f"{'by scanning all 105 days':<32}{str(fits(CYCLES, DAYS, 105)):>10}")
print(f"{'the next one, two cycles out':<32}{str(fits(CYCLES, DAYS, 210)):>10}")
counts = [sum(d % c == r for c, r in zip(CYCLES, DAYS)) for d in range(30)]
print("rotas matched, days 0 to 29: " + " ".join(str(n) for n in counts))
print(f"adding the day numbers: {' + '.join(str(d) for d in DAYS)} = {sum(DAYS)}, which is day {sum(DAYS) % 3} of the 3-day cycle")
agree, clash = fits([3, 5, 6], [2, 3, 2], 30), fits([3, 5, 6], [2, 3, 1], 30)
print(f"a 6-day cycle in place of the 7: readings agreeing fit {agree} in 30; readings clashing, {clash}")
assert x == 23 and m == 105 and fits(CYCLES, DAYS, 105) == [23]
assert 23 % 3 == 2 and 23 % 5 == 3 and 23 % 7 == 2 and 23 + 105 == 128
assert counts[23] == 3 and max(counts[:23]) == 2 and agree == [8] and clash == []
print("ALL CHECKS PASS")
