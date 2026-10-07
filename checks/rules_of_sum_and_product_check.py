# The rules of sum and product -- the check behind the card.  Nothing is
# imported.  The lunch deal: 4 breads x 5 fillings x 3 sauces, or one of 3
# soups instead.  Every count is reached twice: once from the stage sizes,
# multiplied or added, and once by building every lunch and counting them one
# at a time, a road that never multiplies or adds a stage size at all.
BREADS = ["rye", "white", "sourdough", "flat"]
FILLINGS = ["cheese", "ham", "tuna", "falafel", "egg"]
SAUCES = ["chilli", "mustard", "none"]
SOUPS = ["tomato", "lentil", "pea"]
SQUAD = list(range(1, 21))                   # the squad's 20 shirt numbers

def build(stages):                           # road two: pile the rows up, one pick at a time
    rows = [()]
    for stage in stages:
        rows = [row + (pick,) for row in rows for pick in stage]
    return rows

def yn(claim):
    return "yes" if claim else "no"

pairs = build([BREADS, FILLINGS])
running = [sum(1 for p in pairs if p[0] in BREADS[:k + 1]) for k in range(len(BREADS))]
sandwiches = build([BREADS, FILLINGS, SAUCES])
by_stages = len(BREADS) * len(FILLINGS) * len(SAUCES)            # road one
lunches = [("sandwich",) + s for s in sandwiches] + [("soup", s) for s in SOUPS]
by_cases = by_stages + len(SOUPS)
leaders = [(c, v) for c in SQUAD for v in SQUAD if v != c]       # captain, then vice-captain
by_shrinking = len(SQUAD) * (len(SQUAD) - 1)
rye = [s for s in sandwiches if s[0] == "rye"]
chilli = [s for s in sandwiches if s[2] == "chilli"]
both = [s for s in rye if s in chilli]
either = [s for s in sandwiches if s in rye or s in chilli]

print(f"stage sizes: {len(BREADS)} breads, {len(FILLINGS)} fillings, {len(SAUCES)} sauces;"
      f" and {len(SOUPS)} soups in the other case")
print(f"bread-and-filling pairs, counted one bread at a time: {running}")
print(f"sandwiches, stage sizes multiplied: {len(BREADS)} x {len(FILLINGS)} x {len(SAUCES)} = {by_stages}")
print(f"sandwiches, every one built and counted: {len(sandwiches)}; no two alike: "
      f"{yn(len(set(sandwiches)) == len(sandwiches))}")
print(f"first built and last: {' + '.join(sandwiches[0])} and {' + '.join(sandwiches[-1])}")
print(f"lunches, the two cases added: {by_stages} + {len(SOUPS)} = {by_cases}")
print(f"lunches, every one built and counted: {len(lunches)}; no lunch counted twice: "
      f"{yn(len(set(lunches)) == len(lunches))}")
print(f"captain then vice-captain, stage sizes multiplied: {len(SQUAD)} x {len(SQUAD) - 1} = {by_shrinking}")
print(f"the same, every ordered pair of two different players listed: {len(leaders)}")
print(f"rye sandwiches {len(rye)}, chilli sandwiches {len(chilli)}, both {len(both)}, either {len(either)}")
print(f"mistake 1, stage sizes added: {len(BREADS)} + {len(FILLINGS)} + {len(SAUCES)} = "
      f"{len(BREADS) + len(FILLINGS) + len(SAUCES)}, not {by_stages}")
print(f"mistake 2, the two cases multiplied: {by_stages} x {len(SOUPS)} = {by_stages * len(SOUPS)}, not {by_cases}")
print(f"mistake 3, the vice-captain drawn from all {len(SQUAD)}: {len(SQUAD)} x {len(SQUAD)} = "
      f"{len(SQUAD) * len(SQUAD)}, not {by_shrinking}")
print(f"mistake 4, overlapping groups added: {len(rye)} + {len(chilli)} = {len(rye) + len(chilli)}, not {len(either)}")
assert len(sandwiches) == by_stages and len(set(sandwiches)) == by_stages
assert len(lunches) == by_cases and len(set(lunches)) == len(sandwiches) + len(SOUPS)
assert len(leaders) == by_shrinking and len({c for c, v in leaders}) == len(SQUAD)
assert len(either) == len(rye) + len(chilli) - len(both) and len(both) == len(FILLINGS)
print("ALL CHECKS PASS")
