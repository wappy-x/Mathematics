# Steiner triple systems: triples covering every pair of v points exactly once.  No imports.
def cover(blocks):                     # (distinct pairs covered, most times one pair is covered)
    seen = {}
    for a, b, c in blocks:
        for p in ((a, b), (a, c), (b, c)): seen[tuple(sorted(p))] = seen.get(tuple(sorted(p)), 0) + 1
    return len(seen), max(seen.values())
def sts(v, blocks): return len({p for t in blocks for p in t}) == v and cover(blocks) == (v * (v - 1) // 2, 1)
def search(v, used):                   # brute force: can every uncovered pair still be tripled?
    for a in range(v):
        for b in range(a + 1, v):
            if not used[a][b]:
                for c in range(b + 1, v):
                    if not used[a][c] and not used[b][c]:
                        for x, y in ((a, b), (a, c), (b, c)): used[x][y] = used[y][x] = True
                        if search(v, used): return True
                        for x, y in ((a, b), (a, c), (b, c)): used[x][y] = used[y][x] = False
                return False
    return True
def bose(n):                           # v = 6n + 3: point x on layer i is numbered x + q*i
    q = 2 * n + 1
    return [(x, x + q, x + 2 * q) for x in range(q)], [(x + q * i, y + q * i, (x + y) * (n + 1) % q
            + q * ((i + 1) % 3)) for i in range(3) for x in range(q) for y in range(x + 1, q)]
def skolem(n):                         # v = 6n + 1: three layers of 2n points, plus point 6n
    m, half = 2 * n, lambda s: s // 2 if s % 2 == 0 else n + s // 2
    return ([(x, x + m, x + 2 * m) for x in range(n)]
            + [(6 * n, x + n + m * i, x + m * ((i + 1) % 3)) for x in range(n) for i in range(3)]
            + [(x + m * i, y + m * i, half((x + y) % m) + m * ((i + 1) % 3))
               for i in range(3) for x in range(m) for y in range(x + 1, m)])
yn = lambda claim: "yes" if claim else "no"
cell = lambda x, y: 3 * (x % 3) + y % 3 + 1          # grid row x, column y, read 1 to 9
rows, cols = [[cell(c, t) for t in range(3)] for c in range(3)], [[cell(t, c) for t in range(3)] for c in range(3)]
diag, anti = [[cell(t, t + c) for t in range(3)] for c in range(3)], [[cell(t, c - t) for t in range(3)] for c in range(3)]
lines, ttt = rows + cols + diag + anti, rows + cols + [[1, 5, 9], [3, 5, 7]]
fano = [(1, 2, 4), (2, 3, 5), (3, 4, 6), (4, 5, 7), (5, 6, 1), (6, 7, 2), (7, 1, 3)]
base = [(14, 0, 7), (1, 2, 4), (3, 8, 12), (5, 11, 13), (6, 9, 10)]   # A0-A6 = 0-6, B0-B6 = 7-13, Z = 14
days = [[[p if p == 14 else (p + d) % 7 + 7 * (p // 7) for p in t] for t in base] for d in range(7)]
name, walks = lambda p: "Z" if p == 14 else "AB"[p // 7] + str(p % 7), [t for day in days for t in day]
by_count = [v for v in range(3, 16) if (v - 1) % 2 == 0 and v * (v - 1) % 6 == 0]
by_rule = [v for v in range(3, 16) if v % 6 in (1, 3)]
found = [v for v in range(3, 14) if search(v, [[False] * v for _ in range(v)])]
up, rule = bose(1)
print(f"v = 3 to 15 with r and b whole: {by_count}; remainder 1 or 3 on division by 6: {by_rule}")
print(f"brute-force search, v = 3 to 13: a system exists for {found}")
print(f"grid rows {rows}, columns {cols}")
print(f"grid diagonals {diag}, anti-diagonals {anti}")
print(f"v = 9: pairs 9 x 8 / 2 = 36, b = 36 / 3 = {36 // 3}, r = 8 / 2 = {8 // 2}; grid lines {len(lines)}, every pair once: {yn(sts(9, lines))}")
print(f"Bose v = 9: {len(up)} upright + {len(rule)} rule triples, every pair once: {yn(sts(9, up + rule))}; v = 15: {len(sum(bose(2), []))} triples, {yn(sts(15, sum(bose(2), [])))}")
print(f"Skolem v = 7 and 13: {len(skolem(1))} and {len(skolem(2))} triples, {yn(sts(7, skolem(1)))}, {yn(sts(13, skolem(2)))}; Fano plane: {len(fano)} lines, {yn(sts(7, fano))}")
for d, day in enumerate(days): print(f"day {d + 1}: " + " | ".join(" ".join(name(p) for p in t) for t in day))
print(f"Kirkman v = 15: pairs 15 x 14 / 2 = 105, b = 105 / 3 = {len(walks)}, r = 14 / 2 = 7, days {len(walks)} / 5 = {len(days)}; "
      f"each day uses all 15 girls: {yn(all(sorted(sum(day, [])) == list(range(15)) for day in days))}; every pair once: {yn(sts(15, walks))}")
print(f"mistake 1, tic-tac-toe lines only: {len(ttt)} lines cover {cover(ttt)[0]} of 36 pairs")
print(f"mistake 2, Bose v = 9 without the uprights: {len(rule)} triples cover {cover(rule)[0]} of 36 pairs")
print(f"mistake 3, v = 11 is odd, r = {10 // 2}, but b = 110 / 6 = {110 / 6:.2f}")
assert by_count == by_rule == [3, 7, 9, 13, 15] and found == [3, 7, 9, 13]    # counting against search
assert sts(9, lines) and len(lines) == 9 * 8 // 6 and sts(9, up + rule) and sts(7, fano)
assert all(sts(6 * n + 3, sum(bose(n), [])) and sts(6 * n + 1, skolem(n)) for n in range(1, 5))
assert sts(15, walks) and all(sorted(sum(day, [])) == list(range(15)) for day in days)
assert cover(rule)[0] == 36 - 9 and cover(ttt) == (24, 1)
print("ALL CHECKS PASS")
