# Relations -- the check behind the card.  Nothing is imported.  Five teammates, the pairs of "has emailed" and of "is at least as tall as", each put through four tests, twice.
PEOPLE = ["Maya", "Jon", "Priya", "Luis", "Kai"]
CM = {"Maya": 168, "Jon": 175, "Priya": 162, "Luis": 181, "Kai": 170}
TALKED = [("Maya", "Jon"), ("Jon", "Priya"), ("Priya", "Luis"), ("Luis", "Kai")]
NAMES = ["reflexive", "symmetric", "antisymmetric", "transitive"]
EMAIL = {q for a, b in TALKED for q in ((a, b), (b, a))}
TALL = {(a, b) for a in PEOPLE for b in PEOPLE if CM[a] >= CM[b]}
def two_step(R):                 # a to b in R, then b to c in R, so a to c: the composition
    return {(a, c) for a, b in R for c in PEOPLE if (b, c) in R}
def tests(R):                    # straight off the four definitions, one pair at a time
    return (all((a, a) in R for a in PEOPLE), all((b, a) in R for a, b in R),
            all(a == b for a, b in R if (b, a) in R),
            all((a, c) in R for a, b in R for c in PEOPLE if (b, c) in R))
def again(R):                    # second route: whole sets, reversed and stepped twice
    rev, loops = {(b, a) for a, b in R}, {(a, a) for a in PEOPLE}
    return (loops <= R, rev == R, (R & rev) <= loops, two_step(R) <= R)
shut = set(EMAIL)                # add the two-step pairs over and over until none is new
while not two_step(shut) <= shut: shut |= two_step(shut)
ONEWAY, NOLOOP = set(TALKED), TALL - {("Maya", "Maya")}   # the two broken lists from the card
print(f"five teammates, {len(PEOPLE) * len(PEOPLE)} possible ordered pairs")
print("heights in cm: " + ", ".join(f"{p} {CM[p]}" for p in PEOPLE))
print(f"has emailed: {len(TALKED)} conversations, 2 directions each, {len(EMAIL)} ordered pairs")
print("is at least as tall as: " + " + ".join(str(sum(1 for y in CM.values() if x >= y)) for x in sorted(CM.values(), reverse=True)) + f" = {len(TALL)} ordered pairs")
print(f"{'test':<15}{'has emailed':<13}is at least as tall as")
for n, x, y in zip(NAMES, tests(EMAIL), tests(TALL)): print(f"{n:<15}{('yes' if x else 'no'):<13}{'yes' if y else 'no'}")
print(f"both routes agree on all {2 * len(NAMES)} answers; every link the chains imply: {len(shut)} pairs")
print(f"log one direction only: {len(ONEWAY)} pairs, symmetric {'yes' if tests(ONEWAY)[1] else 'no'}; drop one loop: {len(NOLOOP)} pairs, reflexive {'yes' if tests(NOLOOP)[0] else 'no'}")
assert len(EMAIL) == 8 and len(TALL) == 5 + 4 + 3 + 2 + 1 and len(shut) == 25 and len(ONEWAY) == 4 and len(NOLOOP) == 14 and not tests(ONEWAY)[1] and not tests(NOLOOP)[0]
assert tests(EMAIL) == (False, True, False, False) and tests(TALL) == (True, False, True, True) and again(EMAIL) == tests(EMAIL) and again(TALL) == tests(TALL)
print("ALL CHECKS PASS")
