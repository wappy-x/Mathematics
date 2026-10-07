# Logarithms -- the check behind the card.  Nothing is imported.  A logarithm
# answers "what power got me here?".  Road one counts the divisions down to 1;
# road two multiplies back up and has to land on the same number.
QUAKES = [(4, 10000), (5, 100000), (6, 1000000), (7, 10000000)]
def log_by_dividing(base, x):        # divide by the base until 1, counting steps
    steps = 0
    while x > 1:
        assert x % base == 0, "not a whole power of that base"
        x //= base
        steps += 1
    return steps
def power(base, steps):              # the road back, the base multiplied by itself
    out = 1
    for _ in range(steps): out *= base
    return out
def row(name, value): print(f"{name:<37}{value:>9}")

for mag, swing in QUAKES:
    print(f"magnitude {mag}  needle swing {swing:>9}  log base 10 of it {log_by_dividing(10, swing)}")
print("dividing ten million by ten:", *(10000000 // power(10, s) for s in range(1, 8)))
row("a 7 against a 6", 10000000 // 1000000)
row("a 7 against a 5", 10000000 // 100000)
row("log base 10 of 1", log_by_dividing(10, 1))
row("log base 2 of 32", log_by_dividing(2, 32))
row("the road back, seven tens multiplied", power(10, 7))
print(f"the three mistakes come out at {7 - 5}, {log_by_dividing(10, 10000000) + 1} and {32 // 2}")
assert log_by_dividing(10, 10000000) == 7 and power(10, 7) == 10000000
assert power(10, log_by_dividing(10, 1000000)) == 1000000
assert log_by_dividing(2, 32) == 5 and log_by_dividing(10, 1) == 0
print("ALL CHECKS PASS")
