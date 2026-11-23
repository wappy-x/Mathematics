# P and NP -- the check behind the card.  A 4 by 4 sudoku (side k = 4, 16 cells
# of 3 bits, so n = 48 bits; 0 = blank).  Checking a filled grid is V(x, c);
# filling it is a search over certificates.  Three roads to the answer:
# blind search over every filling, a backtracking solver, and the list of all
# valid grids built from row orderings.  Standard library only.
import math

K = 4
BITS = len(format(K, "b"))                  # bits per cell, as on Time and space classes
PUZZLE = [1, 0, 3, 0, 0, 4, 1, 0, 2, 0, 0, 3, 0, 3, 0, 1]
BROKEN = [1, 0, 3, 0, 0, 4, 1, 0, 2, 0, 0, 3, 0, 3, 0, 2]  # last given 1 -> 2
ROWS = [[r * 4 + c for c in range(4)] for r in range(4)]
COLS = [[r * 4 + c for r in range(4)] for c in range(4)]
BOXES = [[(br + i) * 4 + bc + j for i in range(2) for j in range(2)]
         for br in (0, 2) for bc in (0, 2)]
GROUPS = ROWS + COLS + BOXES

def verify(x, c, groups=GROUPS, use_givens=True):
    """V(x, c): 1 when grid c fills puzzle x legally.  Returns (ok, cell reads)."""
    ok, reads = True, 0
    for i in range(16):                     # c must agree with every given
        reads += 1
        if use_givens and x[i] != 0 and c[i] != x[i]:
            ok = False
    for g in groups:                        # each group holds 1..k once
        seen = [False] * (K + 1)
        for i in g:
            reads += 1
            v = c[i]
            if v < 1 or v > K or seen[v]:
                ok = False
            else:
                seen[v] = True
    return ok, reads

def blind_search(x, groups=GROUPS):
    """Deterministic run of the guessing machine: try every filling of the blanks."""
    blanks = [i for i in range(16) if x[i] == 0]
    found, tried, reads = [], 0, 0
    for code in range(K ** len(blanks)):
        c = list(x)
        for b in blanks:
            c[b] = code % K + 1
            code //= K
        ok, r = verify(x, c, groups)
        tried, reads = tried + 1, reads + r
        if ok:
            found.append(c)
    return found, tried, reads, len(blanks)

def backtrack(x):
    """A second road: fill blanks in order, never placing a clashing digit."""
    g, nodes = list(x), 0
    def fits(i, v):
        return all(g[j] != v for grp in GROUPS if i in grp for j in grp)
    def go(i):
        nonlocal nodes
        if i == 16:
            return True
        if g[i] != 0:
            return go(i + 1)
        for v in range(1, K + 1):
            nodes += 1
            if fits(i, v):
                g[i] = v
                if go(i + 1):
                    return True
                g[i] = 0
        return False
    return (list(g) if go(0) else None), nodes

def orderings(items):
    if len(items) <= 1:
        return [list(items)]
    out = []
    for i in range(len(items)):
        for rest in orderings(items[:i] + items[i + 1:]):
            out.append([items[i]] + rest)
    return out

def all_valid_grids():
    """A third road: every grid whose rows are orderings of 1..4, kept if valid."""
    rows, grids = orderings([1, 2, 3, 4]), []
    for a in rows:
        for b in rows:
            for c in rows:
                for d in rows:
                    g = a + b + c + d
                    if verify([0] * 16, g)[0]:
                        grids.append(g)
    return grids

show = lambda g: " / ".join("".join(str(v or ".") for v in g[r*4:r*4+4]) for r in range(4))
print("puzzle", show(PUZZLE), "| givens", sum(1 for v in PUZZLE if v), "| n =", 16 * BITS, "bits: 16 cells x", BITS, "bits")
found, tried, reads, b = blind_search(PUZZLE)
sol, nodes = backtrack(PUZZLE)
valid = all_valid_grids()
matches = [g for g in valid if all(p == 0 or p == v for p, v in zip(PUZZLE, g))]
print("blanks", b, "| fillings tried", tried, "| completions found", len(found))
print("solution", show(found[0]))
print("verifier reads per grid", verify(PUZZLE, found[0])[1])
print("blind search total reads", reads)
print("guessing machine: branches", K ** b, "| guesses + reads per branch", b + 64)
print("backtracking placements tried", nodes)
print("valid 4 by 4 grids", len(valid), "| agreeing with the givens", len(matches))
gives = [sum(1 for g in valid if verify(x, g)[0]) for x in (PUZZLE, BROKEN)]  # the givens pass at work
print("verifier over all", len(valid), "grids: accepts", gives[0], "for the puzzle,", gives[1], "for the no-instance")
swapped = list(sol); swapped[1], swapped[2] = swapped[2], swapped[1]
print("verifier on solution", int(verify(PUZZLE, sol)[0]), "| with two cells swapped", int(verify(PUZZLE, swapped)[0]))
assert len(found) == 1 and sol == found[0]           # road 1 = road 2
assert matches == [sol]                              # road 3 agrees
assert len(valid) == 288                             # known count of 4 by 4 grids
assert verify(PUZZLE, sol)[0] and not verify(PUZZLE, swapped)[0]
assert reads == tried * 4 * K * K                    # 4k^2 reads per grid
# What breaks
rows_only, _, _, _ = blind_search(PUZZLE, ROWS)
loose = [g for g in valid if verify(PUZZLE, g, GROUPS, False)[0]]
bfound, btried, _, _ = blind_search(BROKEN)
bsol, bnodes = backtrack(BROKEN)
bmatch = [g for g in valid if all(p == 0 or p == v for p, v in zip(BROKEN, g))]
row_choices = math.prod(math.factorial(sum(1 for i in r if PUZZLE[i] == 0)) for r in ROWS)
print("broken: rows-only verifier accepts", len(rows_only), "| row choices multiplied", row_choices)
print("broken: verifier ignoring givens accepts", len(loose))
print("no-instance", show(BROKEN), "| completions", len(bfound), "| backtracking placements", bnodes)
print("no-instance: listing every failed filling takes", btried * 16, "digits, the puzzle has 16")
assert len(rows_only) == row_choices and len(loose) == 288
assert bfound == [] and bsol is None and bmatch == []
assert gives == [len(matches), len(bmatch)]               # the givens pass, against the agree filter
# Scale: verifier reads 4k^2 against blind fillings of an empty grid, k^(k^2)
for k in (4, 9, 16, 25):
    lg = k * k * math.log10(k)
    print(f"scale k={k} cells={k*k} n={k*k*len(format(k, 'b'))} groups={3*k} verifier reads={4*k*k} log10 reads={math.log10(4*k*k):.2f} log10 blind fillings={lg:.2f}")
lg17 = 64 * math.log10(9)
print(f"9 by 9 with 17 givens: 64 blanks, 9^64 = {10 ** (lg17 - math.floor(lg17)):.2f} x 10^{math.floor(lg17)}")
exact = str(9 ** 64)                                 # exact integer against the log road
assert len(exact) == math.floor(lg17) + 1 and f"{int(exact[:4]) / 1000:.2f}" == f"{10 ** (lg17 - math.floor(lg17)):.2f}"
print("ALL CHECKS PASS")
