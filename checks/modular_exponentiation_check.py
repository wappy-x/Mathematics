# Powers on the clock -- the check behind the card.  Nothing is imported.  A three-digit
# trip counter multiplies its reading by 7 each day and keeps only the last three digits.
def by_squaring(days, spare=True):     # halve the days down, then square back up
    rungs = []
    while days: rungs.append(days); days //= 2
    rungs.reverse()
    reading, mults, trace = 7, 0, [7]
    for rung in rungs[1:]:
        reading = reading * reading % 1000; mults += 1        # square: doubles the days
        if spare and rung % 2: reading = reading * 7 % 1000; mults += 1   # the spare day
        trace.append(reading)
    return reading, mults, rungs, trace
def slow(days):                        # the counter's own way, one multiplication a day
    reading = 1
    for _ in range(days): reading = reading * 7 % 1000
    return reading
def line(name, values): print(f"{name:<33}" + "".join(f"{v:>7}" for v in values))
fast, mults, rungs, readings = by_squaring(123)
line("the days, from 1 up to 123", rungs)
line("what the counter reads on them", readings)
line("day 123 by squaring, mod 1000", [fast])
line("day 123 the slow way, mod 1000", [slow(123)])
line("multiplications, fast then slow", [mults, 123])
line("day 7 with nothing thrown away", [7 * 7 * 7 * 7 * 7 * 7 * 7])
line("biggest number written down", [943 * 943])
line("skipping the spare 7s", [by_squaring(123, False)[0]])
assert fast == 343 and slow(123) == 343 and fast == slow(123)
assert rungs == [1, 3, 7, 15, 30, 61, 123] and readings == [7, 343, 543, 943, 249, 7, 343]
assert mults == 11 and 7 ** 7 % 1000 == readings[2] and by_squaring(123, False)[0] == 401
print("ALL CHECKS PASS")
