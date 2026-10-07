# Induction -- the check behind the card.  Nothing is imported.  A party where
# every pair shakes hands once.  Two roads to the count: list the pairs and
# tally them, or use the formula.  Then the same count built one guest at a time.
def by_listing(n):                      # every pair, counted one at a time
    return sum(1 for a in range(n) for b in range(a + 1, n))

def by_formula(n):                      # the claim: n x (n - 1) / 2
    return n * (n - 1) // 2

built = {1: 0}                          # the induction, run for real: 1 person, 0 shakes
for n in range(2, 10):
    built[n] = built[n - 1] + (n - 1)   # the new guest shakes every hand already there

print(f"{'people':>7}{'pairs listed':>14}{'by the formula':>16}{'built by the step':>19}{'the guest shook':>17}")
for n in (1, 2, 3, 4, 5, 8):
    print(f"{n:>7}{by_listing(n):>14}{by_formula(n):>16}{built[n]:>19}{n - 1:>17}")
print(f"the step at 7 people: {by_formula(7)} + 7 = {by_formula(8)}")
print(f"the three mistakes come out at {by_formula(8) + 1}, {8 * 7} and {by_formula(9)} at 9 people")
assert by_listing(8) == 28 and by_formula(8) == 28
assert built == {n: by_listing(n) for n in built}
assert by_formula(1) == 0 and by_formula(9) == 36 and 8 * 7 == 56
print("ALL CHECKS PASS")
