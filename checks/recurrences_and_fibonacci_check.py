# Recurrences and Fibonacci -- the check behind the card.  Nothing is imported.  A hallway
# 2 tiles wide and n tiles long is laid with 1 x 2 tiles; its tilings are counted twice, by
# the step rule and by laying tiles every legal way.  Hanoi is counted three ways.
N, DISCS = 10, 10
def by_rule(n, seeds=(1, 2), w=1):            # road one: the step rule, run forward
    a = list(seeds)
    while len(a) < n: a.append(a[-1] + w * a[-2])
    return a[:n]
def by_listing(n):                            # road two: lay tiles, count the finishes
    cells = [[0] * n for _ in range(2)]
    def fill():                               # fill the first empty square, two ways
        spot = next(((r, c) for c in range(n) for r in range(2) if not cells[r][c]), None)
        if spot is None: return 1
        r, c, total = spot[0], spot[1], 0
        upright = ((0, c), (1, c)) if r == 0 and not cells[1][c] else ()
        flat = ((r, c), (r, c + 1)) if c + 1 < n and not cells[r][c + 1] else ()
        for pair in (upright, flat):
            if not pair: continue
            for y, x in pair: cells[y][x] = 1
            total += fill()
            for y, x in pair: cells[y][x] = 0
        return total
    return fill()
def hanoi_by_rule(k):                         # road one: h(n) = 2 h(n-1) + 1, forward
    h = 0
    for _ in range(k): h = 2 * h + 1
    return h
def hanoi_by_moving(k):                       # road two: shift the discs one at a time
    pegs, count, legal = {"A": list(range(k, 0, -1)), "B": [], "C": []}, 0, True
    def shift(m, src, dst, spare):
        nonlocal count, legal
        if m == 0: return
        shift(m - 1, src, spare, dst)
        d = pegs[src].pop(); legal = legal and (not pegs[dst] or pegs[dst][-1] > d)
        pegs[dst].append(d); count += 1
        shift(m - 1, spare, dst, src)
    shift(k, "A", "C", "B")
    return count, legal and pegs["C"] == list(range(k, 0, -1))
rule, listed = by_rule(N), [by_listing(n) for n in range(1, N + 1)]
fib, (moves, legal) = by_rule(N + 1, (1, 1)), hanoi_by_moving(DISCS)
hanoi, closed_h = [hanoi_by_rule(k) for k in range(1, DISCS + 1)], 2 ** DISCS - 1
print("hallway 2 tiles wide, 1 x 2 tiles; n is its length in tiles, or the number of discs")
for label, xs in (("n", list(range(1, N + 1))), ("tilings by the rule", rule), ("tilings by listing", listed), ("Hanoi moves by rule", hanoi)):
    print(f"{label:<21}:" + "".join(f"{x:5d}" for x in xs))
print(f"the two tiling roads agree: {'yes' if rule == listed else 'no'}")
print(f"a 2 x {N} hallway has {listed[-1]} tilings")
print(f"the last column: {rule[-2]} end in one upright tile, {rule[-3]} end in two flat tiles, {rule[-2]} + {rule[-3]} = {rule[-2] + rule[-3]}")
print(f"Fibonacci from seeds 1, 1: F({N + 1}) = {fib[-1]}, so T(n) = F(n+1)")
print(f"Tower of Hanoi, {DISCS} discs")
print(f"{'moves by the rule h(n) = 2 h(n-1) + 1':<39}: {hanoi[-1]}")
print(f"{'moves by shifting the discs one by one':<39}: {moves}, legal solve: {'yes' if legal else 'no'}")
print(f"{f'moves by the closed form 2^{DISCS} - 1':<39}: {closed_h}")
print(f"mistake 1, seeds 1 and 1 instead of 1 and 2: {fib[N - 1]}, not {listed[-1]}")
print(f"mistake 2, the flat pair counted once per row: {by_rule(N, (1, 2), 2)[-1]}, not {listed[-1]}")
print(f"mistake 3, guessing h(n) = 2^n, first step unchecked: {2 ** DISCS}, not {hanoi[-1]}")
assert rule == listed                                    # two roads, one sequence
assert listed[-1] == 89 and rule[-2] + rule[-3] == listed[-1]
assert fib[-1] == listed[-1] and fib[N - 1] == 55        # Fibonacci, one place along
assert hanoi[-1] == 1023 and moves == hanoi[-1] and closed_h == hanoi[-1] and legal
print("ALL CHECKS PASS")
