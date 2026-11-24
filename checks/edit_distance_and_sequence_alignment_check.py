# Edit distance and sequence alignment -- the check behind the card.  Nothing is imported.
# D(i, j) = the cheapest way to turn the first i letters of x into the first j letters of y.
unit = lambda a, b: 0 if a == b else 1    # Levenshtein: a change costs 1, a match costs 0
dna = lambda a, b: -1 if a == b else 1    # DNA score +1 match, -1 mismatch, kept as a cost = -score
CELLS, KEPT = [0], [0, 0]                 # cells computed; table cells held now, and the most held at once
def keep(k): KEPT[0] += k; KEPT[1] = max(KEPT[1], KEPT[0])

def last_row(x, y, sub, g):               # two rows only: returns the bottom row of the table
    prev = [j * g for j in range(len(y) + 1)]; keep(len(y) + 1)
    for i in range(1, len(x) + 1):
        cur = [i * g] + [0] * len(y); keep(len(y) + 1)
        for j in range(1, len(y) + 1):
            cur[j] = min(prev[j - 1] + sub(x[i - 1], y[j - 1]), prev[j] + g, cur[j - 1] + g)
            CELLS[0] += 1
        prev = cur; keep(-len(y) - 1)       # the old row is dropped
    return prev

def table(x, y, sub=unit, g=1, border=True):    # road one: the whole table, kept for the traceback
    D = [[(j * g if border else 0) for j in range(len(y) + 1)]]; keep(len(y) + 1)
    for i in range(1, len(x) + 1):
        D.append([i * g if border else 0] + [0] * len(y)); keep(len(y) + 1)
        for j in range(1, len(y) + 1):
            D[i][j] = min(D[i - 1][j - 1] + sub(x[i - 1], y[j - 1]), D[i - 1][j] + g, D[i][j - 1] + g)
            CELLS[0] += 1
    return D

def trace(D, x, y, sub=unit, g=1):        # walk back from the corner: diagonal, then up, then left
    i, j, top, bot = len(x), len(y), "", ""
    while i or j:
        if i and j and D[i][j] == D[i - 1][j - 1] + sub(x[i - 1], y[j - 1]):
            top, bot, i, j = x[i - 1] + top, y[j - 1] + bot, i - 1, j - 1
        elif i and D[i][j] == D[i - 1][j] + g:
            top, bot, i = x[i - 1] + top, "-" + bot, i - 1
        else:
            top, bot, j = "-" + top, y[j - 1] + bot, j - 1
    return top, bot

def score(top, bot, sub=unit, g=1):       # the cost of a written alignment, column by column
    return sum(g if "-" in (a, b) else sub(a, b) for a, b in zip(top, bot))

def brute(x, y, sub=unit, g=1):           # road two: every alignment, one by one
    best, ways, count = [None], [0], [0]
    def go(i, j, c):
        if i == len(x) and j == len(y):
            count[0] += 1
            if best[0] is None or c < best[0]: best[0], ways[0] = c, 1
            elif c == best[0]: ways[0] += 1
            return
        if i < len(x) and j < len(y): go(i + 1, j + 1, c + sub(x[i], y[j]))
        if i < len(x): go(i + 1, j, c + g)
        if j < len(y): go(i, j + 1, c + g)
    go(0, 0, 0)
    return best[0], ways[0], count[0]

def plain(x, y, calls):                   # the recursion without a table, counting its calls
    calls[0] += 1
    if not x or not y: return len(x) + len(y)
    return min(plain(x[:-1], y[:-1], calls) + unit(x[-1], y[-1]), plain(x[:-1], y, calls) + 1, plain(x, y[:-1], calls) + 1)

def hirsch(x, y, sub=unit, g=1, split_best=True):   # road three: Hirschberg, two rows at a time
    if len(x) <= 1 or len(y) == 0:
        al = trace(table(x, y, sub, g), x, y, sub, g); keep(-(len(x) + 1) * (len(y) + 1)); return al
    mid = len(x) // 2
    left = last_row(x[:mid], y, sub, g)
    right = last_row(x[mid:][::-1], y[::-1], sub, g)[::-1]
    js = range(len(y) + 1)
    j = min(js, key=lambda k: (left[k] + right[k], k)) if split_best else len(y) // 2; del left, right; keep(-2 * len(y) - 2)
    a1, b1 = hirsch(x[:mid], y[:j], sub, g, split_best)
    a2, b2 = hirsch(x[mid:], y[j:], sub, g, split_best)
    return a1 + a2, b1 + b2

x, y = "kitten", "sitting"
CELLS[0] = 0; D = table(x, y)
print(f"table for {x} -> {y}: rows i = 0..6, columns j = 0..7, {CELLS[0]} cells filled")
for i, row in enumerate(D):
    print(f"  {' ' + x[i - 1] if i else '  '}" + "".join(f"{v:3d}" for v in row))
top, bot = trace(D, x, y)
print(f"traceback: {top} / {bot}, cost {score(top, bot)}")
print("edits: " + ", ".join(f"{a}->{b}" if "-" not in (a, b) else (f"insert {b}" if a == "-" else f"delete {a}")
                            for a, b in zip(top, bot) if a != b))
bk = brute(x, y); calls = [0]; plain(x, y, calls)
print(f"brute force: {bk[2]} alignments, best {bk[0]}, {bk[1]} of them optimal")
print(f"plain recursion: {calls[0]} calls for {(len(x) + 1) * (len(y) + 1)} different questions")
g1, g2 = "GATTACA", "GCATGCA"
Dg, bg = table(g1, g2), brute(g1, g2)
print(f"{g1} -> {g2}: distance {Dg[7][7]}, traceback {' / '.join(trace(Dg, g1, g2))}; "
      f"brute force {bg[2]} alignments, best {bg[0]}, {bg[1]} optimal")
for gap in (1, 2):
    Ds = table(g1, g2, dna, gap)
    t, b = trace(Ds, g1, g2, dna, gap)
    bs = brute(g1, g2, dna, gap)
    print(f"DNA score, match +1, mismatch -1, gap -{gap}: best {-Ds[7][7]}, {t} / {b}; brute force best {-bs[0]}, {bs[1]} optimal")
    assert -Ds[7][7] == -bs[0] == -score(t, b, dna, gap), "scored table against every alignment"
for a, b in ((x, y), (g1, g2)):
    CELLS[0] = 0; KEPT[:] = [0, 0]
    ht, hb = hirsch(a, b)
    print(f"Hirschberg {a} -> {b}: {ht} / {hb}, cost {score(ht, hb)}, {CELLS[0]} cells computed, peak {KEPT[1]} cells held, 3 rows of {len(b) + 1}")
    assert KEPT[1] <= 3 * (len(b) + 1) and score(ht, hb) == table(a, b)[-1][-1], "Hirschberg against the full table, in 3 rows"
    assert ht.replace("-", "") == a and hb.replace("-", "") == b, "the alignment spells both strings"
L, R = last_row(x[:3], y, unit, 1), last_row(x[3:][::-1], y[::-1], unit, 1)[::-1]
print(f"first split, kit | ten: forward {L}, backward {R}, sums {[a + b for a, b in zip(L, R)]}")
q, t2 = "Beatles", "The Beatles"
ham = sum(1 for k in range(len(t2)) if k >= len(q) or q[k] != t2[k])
print(f"wrong: letter by letter, {q} against {t2}: {ham} differences, true distance {table(q, t2)[-1][-1]}")
print(f"wrong: no changes, only insert and delete, {x} -> {y}: {table(x, y, lambda a, b: 0 if a == b else 2)[-1][-1]}")
print(f"wrong: border filled with zeros, {q} -> {t2}: {table(q, t2, border=False)[-1][-1]}")
print(f"limit: a swap, teh -> the: {table('teh', 'the')[-1][-1]} edits, not 1")
wt, wb = hirsch(q, t2, split_best=False)
print(f"wrong: Hirschberg splitting y at its middle, {q} -> {t2}: {wt} / {wb}, cost {score(wt, wb)}")

def splitmix(s):                          # SplitMix64, written out, for the synthetic DNA
    s = (s + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return s, z ^ (z >> 31)
print("synthetic DNA, seed 2026, both strings of length n, unit costs")
chart, s = [], 2026
for n in (50, 100, 200, 400):
    u, v = "", ""
    for _ in range(n):
        s, r1 = splitmix(s); s, r2 = splitmix(s)
        u += "ACGT"[r1 % 4]; v += "ACGT"[r2 % 4]
    CELLS[0] = 0; KEPT[:] = [0, 0]; full = table(u, v)[n][n]; c_full, k_full = CELLS[0], KEPT[1]
    CELLS[0] = 0; KEPT[:] = [0, 0]; ht, hb = hirsch(u, v); c_h, k_h = CELLS[0], KEPT[1]
    assert score(ht, hb) == full and c_h <= 2 * c_full and k_h <= 3 * (n + 1), "same cost, twice the work, 3 rows"
    chart.append((k_full, k_h))
    print(f"  n={n:3d}: distance {full:3d}, Hirschberg {score(ht, hb):3d}; cells computed {c_full:6d} vs {c_h:6d}; "
          f"cells kept {k_full:6d} vs {k_h}")
print("chart, n 50 100 200 400")
print("chart, cells kept by the full table " + " ".join(str(c[0]) for c in chart))
print("chart, cells kept by Hirschberg, 3 rows " + " ".join(str(c[1]) for c in chart))
print(f"two play logs of 100,000 plays, 4 bytes a cell: full table {100001 ** 2} cells, {4 * 100001 ** 2} bytes; "
      f"3 rows {3 * 100001} cells, {12 * 100001} bytes; two genomes of 4,600,000: {4600000 ** 2} cells")
assert D[6][7] == bk[0] == 3 and Dg[7][7] == bg[0] == 3, "table against every alignment"
assert score(top, bot) == 3 and hirsch(x, y) == (top, bot), "traceback cost, and Hirschberg finds the same alignment"
assert calls[0] > bk[2] > 56, "plain recursion repeats questions"
fact = lambda k: 1 if k < 2 else k * fact(k - 1)   # a path with k diagonal steps has n - k down, m - k right
assert [bk[2], bg[2]] == [sum(fact(a + b - k) // (fact(k) * fact(a - k) * fact(b - k)) for k in range(a + 1))
                          for a, b in ((6, 7), (7, 7))], "alignment count against the path-counting formula"
print("ALL CHECKS PASS")
