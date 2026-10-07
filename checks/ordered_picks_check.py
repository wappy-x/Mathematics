# Ordered picks -- the check behind the card.  Nothing is imported.  Eight
# runners, three medals in order: gold, silver, bronze.  The count is reached by
# three roads that share no arithmetic -- counting down, dividing factorials,
# and writing every podium out -- and a squad of 20 repeats the test bigger.
RUNNERS, MEDALS, SQUAD, TAKERS, NAMES = 8, 3, 20, 5, "ABCDEFGH"

def factorial(m):                          # written out, since nothing is imported
    out = 1
    for i in range(2, m + 1):
        out *= i
    return out
def falling(n, k):                         # road one: k factors, counting down
    out = 1
    for i in range(k):
        out *= n - i
    return out
def by_factorials(n, k):                   # road two: the leftovers divided back out
    return factorial(n) // factorial(n - k)
def lists(pool, k, repeats):               # road three: write every pick down
    if k == 0:
        return [""]
    out = []
    for i, r in enumerate(pool):
        rest = pool if repeats else pool[:i] + pool[i + 1:]
        out += [r + tail for tail in lists(rest, k - 1, repeats)]
    return out
def commas(v):                             # 1860480 -> 1,860,480
    s = str(v)
    return s if len(s) <= 3 else commas(int(s[:-3])) + "," + s[-3:]

tiny = lists(NAMES[:3], 2, False)
podiums = lists(NAMES, MEDALS, False)
repeated = lists(NAMES, MEDALS, True)
unordered = {"".join(sorted(p)) for p in podiums}
running = [falling(SQUAD, i) for i in range(1, TAKERS + 1)]
recurrence = SQUAD * falling(SQUAD - 1, TAKERS - 1)
print(f"3 runners A, B, C, two medals in order: 3 x 2 = {len(tiny)}")
print(f"the six lists: {', '.join(tiny)}")
print(f"{RUNNERS} runners, {MEDALS} medals in order -- counting down: 8 x 7 x 6 = {falling(RUNNERS, MEDALS)}")
print(f"road 2, factorials: 8! / 5! = {commas(factorial(RUNNERS))} / {factorial(RUNNERS - MEDALS)}"
      f" = {by_factorials(RUNNERS, MEDALS)}")
print(f"road 3, every podium written out: {len(podiums)}")
print(f"the first three podiums listed: {', '.join(podiums[:3])}")
print(f"repeats allowed, written out: 8 x 8 x 8 = {len(repeated)}")
print(f"the same podiums with the order forgotten: {len(unordered)}, and "
      f"{len(unordered)} x 3! = {len(unordered) * factorial(MEDALS)}")
print(f"squad of {SQUAD}, {TAKERS} takers -- running product: {', '.join(commas(v) for v in running)}")
print(f"road 2, factorials: 20! / 15! = {commas(by_factorials(SQUAD, TAKERS))}")
print(f"road 3, one kick then a smaller pick: 20 x P(19, 4) = {commas(recurrence)}")
print(f"repeats allowed: 20^5 = {commas(SQUAD ** TAKERS)}")
print(f"mistake 1, dividing by 3! as well: {len(unordered)}, not {falling(RUNNERS, MEDALS)}")
print(f"mistake 2, letting one runner take two medals: {len(repeated)}, not {falling(RUNNERS, MEDALS)}")
print(f"mistake 3, dividing by 3! instead of 5!: 8! / 3! = "
      f"{commas(factorial(RUNNERS) // factorial(MEDALS))}, not {falling(RUNNERS, MEDALS)}")
assert len(podiums) == falling(RUNNERS, MEDALS) == by_factorials(RUNNERS, MEDALS)
assert all(len(set(p)) == MEDALS for p in podiums) and len(set(podiums)) == len(podiums)
assert len(unordered) * factorial(MEDALS) == len(podiums) and len(repeated) == RUNNERS ** MEDALS
assert running[-1] == by_factorials(SQUAD, TAKERS) == recurrence == 1860480
print("ALL CHECKS PASS")
