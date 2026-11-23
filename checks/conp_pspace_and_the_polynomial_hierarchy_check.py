# Above NP: alternating there-exists and for-all -- the check behind the card.
# Draughts cut down to a 6 by 6 board, men only: a man steps or jumps diagonally
# forward, a capture is compulsory and a jump continues while it can, and a man
# reaching the far row wins.  A side with no legal move loses.  Squares are a1..f6.
from itertools import combinations, permutations, product
N, INF, COLS = 6, 99, "abcdef"
TOP, BOTTOM = sum(1 << (N * (N - 1) + c) for c in range(N)), (1 << N) - 1

def board(names):                                # "b2 b4" -> one bit per square
    return sum(1 << (int(s[1]) - 1) * N + COLS.index(s[0]) for s in names.split())
def name(bits):                                  # one bit per square -> "b2 b4"
    return " ".join(COLS[s % N] + str(s // N + 1) for s in range(N * N) if bits >> s & 1)
def moves(w, b, white):                          # every legal move, as the new (w, b)
    me, op, dr, out = (w, b, 1, []) if white else (b, w, -1, [])
    def jump(s, me, op, jumped):
        r, c, more = s // N, s % N, False
        for dc in (-1, 1):
            m, t = (r + dr) * N + c + dc, (r + 2 * dr) * N + c + 2 * dc
            if 0 <= r + 2 * dr < N and 0 <= c + 2 * dc < N and op >> m & 1 and not (me | op) >> t & 1:
                more = True
                jump(t, me & ~(1 << s) | 1 << t, op & ~(1 << m), True)
        if jumped and not more:
            out.append((me, op))
    for s in range(N * N):
        if me >> s & 1:
            jump(s, me, op, False)
    for s in range(N * N) if not out else []:
        r, c = s // N, s % N
        for dc in (-1, 1):
            t = (r + dr) * N + c + dc
            if me >> s & 1 and 0 <= r + dr < N and 0 <= c + dc < N and not (me | op) >> t & 1:
                out.append((me & ~(1 << s) | 1 << t, op))
    return [(m, o) if white else (o, m) for m, o in out]
def over(w, b, white):                           # None while play goes on, else "White won"
    if w & TOP or b & BOTTOM:
        return bool(w & TOP)
    return None if moves(w, b, white) else not white
count = {"visited": 0, "deepest": 0}
def search(w, b, white, depth=0, cap=INF, black=all):   # road one: depth first, one line held
    count["visited"] += 1
    count["deepest"] = max(count["deepest"], depth)
    end = over(w, b, white)
    if end is not None or depth == cap:
        return bool(end)
    pick = any if white else black               # White: there exists; Black: for every
    return pick(search(x, y, not white, depth + 1, cap, black) for x, y in moves(w, b, white))
table = {}
def plies(w, b, white):                          # road two: every position stored, with plies to a win
    key = (w, b, white)
    if key not in table:
        end = over(w, b, white)
        if end is not None:
            table[key] = 0 if end else INF
        else:
            vals = [plies(x, y, not white) for x, y in moves(w, b, white)]
            v = min(vals) if white else max(vals)
            table[key] = v + 1 if v < INF else INF
    return table[key]
def plan_wins(w, b, white, left, plan):          # road three: one White plan, every Black reply
    end = over(w, b, white)
    if end is not None or left == 0:
        return bool(end)
    if white:
        plan.add((w, b))
        x, y = min(moves(w, b, True), key=lambda m: plies(m[0], m[1], False))
        return plan_wins(x, y, False, left - 1, plan)
    return all(plan_wins(x, y, True, left - 1, plan) for x, y in moves(w, b, False))
def runs(*args, **kw):                           # one search, with fresh counters
    count.update(visited=0, deepest=0)
    return search(*args, **kw), count["visited"], count["deepest"]
def step(old, new):                              # a move as "from-to"
    return name(old & ~new) + "-" + name(new & ~old)

w0, b0 = board("b2 b4"), board("a5 e3")          # the endgame worked by hand
print(f"endgame: White {name(w0)}, Black {name(b0)}, White to move")
agree = []
for x, y in moves(w0, b0, True):
    p, replies = plies(x, y, False), moves(x, y, False)
    agree.append(runs(x, y, False)[0] == (p < INF))
    print(f"  White {step(w0, x)}: Black replies {len(replies)}; plies to a White win "
          f"{p + 1 if p < INF else 'none'}; depth-first search says {runs(x, y, False)[0]}")
    for u, v in replies if p < INF else []:
        answers = [step(u, s) for s, t in moves(u, v, True) if s & TOP]
        print(f"    Black {step(y, v)}: White reaches row 6 by {' or '.join(answers)}")
pe = plies(w0, b0, True)
print(f"endgame value: White wins in {pe} plies; the sentence reads {'∃∀' * (pe // 2) + '∃' * (pe % 2)}")
bad = moves(w0, b0, True)[0]
print(f"mistake 1, Black's replies read as there-exists after {step(w0, bad[0])}: "
      f"White wins {runs(*bad, False, black=any)[0]}, truly {runs(*bad, False)[0]}")

table.clear()
ws, bs = board("a1 c1 e1"), board("b6 d6 f6")
win, seen, deep = runs(ws, bs, True)
p0, plan = plies(ws, bs, True), set()
ok, plan_short = plan_wins(ws, bs, True, p0, plan), plan_wins(ws, bs, True, p0 - 1, set())
capped = runs(ws, bs, True, cap=(cut := p0 - 1))
print(f"start: White {name(ws)}, Black {name(bs)}, White to move")
print(f"road one, depth first: White wins {win}; positions visited {seen:,}; longest line {deep} plies")
print(f"road one memory: {deep + 1} positions x {N * N} squares = {(deep + 1) * N * N:,} cells")
print(f"road two, table: positions stored {len(table):,} = {len(table) * N * N:,} cells; "
      f"White wins in {p0} plies")
print(f"road three, one White plan against every Black reply: wins within {p0} plies {ok}; "
      f"within {p0 - 1} {plan_short}; the plan answers {len(plan):,} positions")
print(f"the sentence 'White wins within {p0} plies' has {p0} quantifiers, {p0 // 2 + 1} ∃ and {p0 // 2} ∀")
print(f"mistake 2, search capped at {cut} plies: White wins {capped[0]}, after {capped[1]:,} positions")

G, grid = [], [0] * 16                           # every 4 by 4 sudoku grid, by backtracking
def fill(i):
    if i == 16:
        return G.append(tuple(grid))
    for d in range(1, 5):
        if all(grid[j] != d for j in range(i) if j // 4 == i // 4 or j % 4 == i % 4
               or (j // 8 == i // 8 and j % 4 // 2 == i % 4 // 2)):
            grid[i] = d
            fill(i + 1)
fill(0)
T = (1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1)
def fits(cells):                                 # grids that agree with T on these cells
    return sum(all(g[i] == T[i] for i in cells) for g in G)
three = [fits(s) for s in combinations(range(16), 3)]
four = [fits(s) for s in combinations(range(16), 4)]
rows = list(permutations((1, 2, 3, 4)))          # road two: stack three rows under 1 2 3 4
def legal(q):                                    # every column and 2 by 2 box holds 1 to 4
    return all(len({q[r][c] for r in range(4)}) == 4 for c in range(4)) and all(
        len({q[a + i][b + j] for i in (0, 1) for j in (0, 1)}) == 4 for a in (0, 2) for b in (0, 2))
first_row = sum(legal(q) for q in product([(1, 2, 3, 4)], rows, rows, rows))
print(f"sudoku: {len(G)} grids; {first_row} start 1 2 3 4, times 24 relabellings = {first_row * 24}")
print(f"3 givens from 1234/3412/2143/4321: {len(three)} choices, pinning the grid {three.count(1)}, "
      f"fewest grids fitting {min(three)}")
print(f"4 givens: {len(four)} choices, pinning the grid {four.count(1)}; "
      f"grid checks made {len(four) * len(G):,}")
print(f"mistake 3, for-every dropped: 3-given choices the grid fits {sum(f >= 1 for f in three)} of {len(three)}")
assert win and p0 < INF and all(agree)                    # roads one and two agree
assert ok and not plan_short                              # the plan wins in exactly p0 plies
assert not capped[0] and runs(ws, bs, True, cap=p0)[0]    # a cap below p0 misses the win
assert runs(*bad, False, black=any)[0] and not runs(*bad, False)[0]
assert first_row * 24 == len(G)                           # backtracking against stacked rows
assert [len(moves(x, y, False)) for x, y in moves(w0, b0, True)] == [1, 2, 3] and pe == 3  # by hand
assert min(three) >= 2 and four.count(1) > 0              # 3 givens never pin it; 4 can
print("ALL CHECKS PASS")
