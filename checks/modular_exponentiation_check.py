# Powers on the clock -- the check behind the card.  Nothing is imported.  A toy random-number
# generator multiplies its output by 7 at each step and keeps only the last three digits.
def by_squaring(steps, spare=True):    # halve the steps down, then square back up
    rungs = []
    while steps: rungs.append(steps); steps //= 2
    rungs.reverse()
    reading, mults, trace = 7, 0, [7]
    for rung in rungs[1:]:
        reading = reading * reading % 1000; mults += 1        # square: doubles the steps
        if spare and rung % 2: reading = reading * 7 % 1000; mults += 1   # the spare step
        trace.append(reading)
    return reading, mults, rungs, trace
def slow(steps):                       # the generator's own way, one multiplication a step
    reading = 1
    for _ in range(steps): reading = reading * 7 % 1000
    return reading
def line(name, values): print(f"{name:<33}" + "".join(f"{v:>7}" for v in values))
STEPS = 123; fast, mults, rungs, readings = by_squaring(STEPS)
line(f"the steps, from 1 up to {STEPS}", rungs)
line("what the generator gives on them", readings)
line(f"step {STEPS} by squaring, mod 1000", [fast])
line(f"step {STEPS} the slow way, mod 1000", [slow(STEPS)])
line("multiplications, fast then slow", [mults, STEPS])
line("step 7 with nothing thrown away", [7 * 7 * 7 * 7 * 7 * 7 * 7])
line("biggest number written down", [943 * 943])
line("skipping the spare 7s", [by_squaring(STEPS, False)[0]])
assert fast == 343 and slow(STEPS) == 343 and fast == slow(STEPS)
assert rungs == [1, 3, 7, 15, 30, 61, 123] and readings == [7, 343, 543, 943, 249, 7, 343]
assert mults == 11 and 7 ** 7 % 1000 == readings[2] and by_squaring(123, False)[0] == 401
print("ALL CHECKS PASS")
