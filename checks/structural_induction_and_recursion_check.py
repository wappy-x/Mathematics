# Structural induction -- the check behind the card.  Nothing is imported.  A bracket is one
# team, or two brackets joined by a final.  Roads: the recursion, a walk, every shape to 8 teams.
def games(t, final=1): return 0 if isinstance(t, str) else games(t[0], final) + games(t[1], final) + final
def teams(t): return 1 if isinstance(t, str) else teams(t[0]) + teams(t[1])
def height(t): return 0 if isinstance(t, str) else 1 + max(height(t[0]), height(t[1]))
def even(n, k=0): return f"T{k}" if n == 1 else (even(n // 2, k), even(n // 2, k + n // 2))
def walk(t):                            # second road: a to-do list, no recursion
    finals, todo = 0, [t]
    while todo:
        x = todo.pop(); finals += not isinstance(x, str); todo += [] if isinstance(x, str) else list(x)
    return finals
def shapes(n): return ["T"] if n == 1 else [(a, b) for k in range(1, n) for a in shapes(k) for b in shapes(n - k)]
def formulas(d):                        # every formula built in at most d rounds of the rules
    f = ["p", "q"] if d == 0 else formulas(d - 1)
    return f if d == 0 else sorted(set(f + ["not " + a for a in f] + [f"({a} and {b})" for a in f for b in f]))
def euclid(a, b, seen): seen.append(b); return a if b == 0 else euclid(b, a % b, seen)
ladder = (((("B5", "B4"), "B3"), "B2"), "B1")   # a stepladder: 5th seed v 4th, winner v 3rd, ...
print(f"{'bracket':<22}{'teams':>6}{'height':>7}{'games':>6}{'walked':>7}{'teams - 1':>10}")
for name, t in [("even, 16 teams", even(16)), ("even, 64 teams", even(64)), ("stepladder, 5 bowlers", ladder)]:
    print(f"{name:<22}{teams(t):>6}{height(t):>7}{games(t):>6}{walk(t):>7}{teams(t) - 1:>10}")
print("doubling 1, 2, 4, 8, 16 teams gives", ", ".join(str(games(even(n))) for n in (1, 2, 4, 8, 16)), "games")
every, F, seen, ex = [t for n in range(1, 9) for t in shapes(n)], formulas(3), [], "(not (p and q) and p)"
print(f"every shape of 1 to 8 teams: {len(every)} brackets; every formula in 3 rounds: {len(F)}")
print(f"{ex}: {ex.count('(')} '(' and {ex.count(')')} ')'; Euclid on 63 and 15 -> {euclid(63, 15, seen)}, second numbers {seen}")
rr, nofinal = sum(1 for a in range(16) for b in range(a + 1, 16)), games(even(16), final=0)
print(f"the three mistakes come out at {nofinal}, {games(even(16)) + 1} and {rr}")
assert all(games(t) == walk(t) == teams(t) - 1 for t in every) and len(every) == 1 + 1 + 2 + 5 + 14 + 42 + 132 + 429
assert all(f.count("(") == f.count(")") == f.count(" and ") for f in F) and ex in F
assert games(even(64)) == 63 and height(even(64)) == 6 and height(ladder) == 4 and seen == [15, 3, 0] and euclid(63, 15, []) == 3 and rr == 120
print("ALL CHECKS PASS")
