# Linear against exponential -- the check behind the card.  Nothing is imported.
# Two ponds, each starting at one lily pad.  In the first the gardener adds one
# pad a day.  In the second the pads double.  Covered means a million pads.
COVER = 1000000
plus, times = [1], [1]                       # day 0: one pad in each pond
for _ in range(20):                          # one road: step a day at a time
    plus.append(plus[-1] + 1)
    times.append(times[-1] * 2)

def grid(name, values): print(f"{name:<16}" + "".join(f"{v:>6}" for v in values))
def one(name, value): print(f"{name:<44}{value:>10}")

grid("day", range(11))
grid("one pad a day", plus[:11])
grid("doubling", times[:11])
one("day 19, doubling pond", times[19])
one("day 20, doubling pond", times[20])
one("day 20, one-pad pond", plus[20])
one("day 20, the gap", times[20] - plus[20])
one("days for the one-pad pond to reach 1000000", COVER - 1)
one("that, in whole years", (COVER - 1) // 365)
print(f"the two mistakes come out at {1 + 2 * 20} and {2 * 20}")

assert plus[20] == 21 and times[20] == 1048576 and times[20] - plus[20] == 1048555
assert times[20] == times[10] * times[10]    # a second road: 1024 x 1024
assert times[19] * 2 == times[20] and times[19] < COVER <= times[20]
assert COVER - 1 == 999999 and (COVER - 1) // 365 == 2739  # the headline numbers
assert 1 + 2 * 20 == 41 and 2 * 20 == 40     # the two mistake numbers, as printed
print("ALL CHECKS PASS")
