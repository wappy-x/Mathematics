# Time and space classes -- the check behind the card.  Standard library only.
# Costs are counted steps and comparisons, never a stopwatch.  The puzzle is a
# 4 by 4 sudoku (digits 1 to 4, boxes 2 by 2) with 8 blank cells, written 0.
import math
PUZZLE = [0, 0, 3, 4,  0, 4, 0, 2,  2, 0, 4, 0,  4, 3, 0, 0]
D = 4
UNITS = ([[r * D + c for c in range(D)] for r in range(D)] + [[r * D + c for r in range(D)] for c in range(D)]
         + [[(br + i) * D + bc + j for i in range(2) for j in range(2)] for br in (0, 2) for bc in (0, 2)])
BLANKS = [i for i in range(D * D) if PUZZLE[i] == 0]

def bits(v):                                   # how many bits write the number v
    return len(format(v, "b"))

def rows(g):
    return " / ".join(" ".join(str(x) for x in g[r * D:r * D + D]) for r in range(D))

def full_check(g):                             # every pair in every unit, no early exit
    comps, good = 0, True
    for u in UNITS:
        for a in range(D):
            for b in range(a + 1, D):
                comps += 1
                good = good and g[u[a]] != g[u[b]]
    return good, comps

# ---- road 1: brute force, a base-4 odometer over the blanks ----
digits, fillings, comps, found = [1] * len(BLANKS), 0, 0, []
while True:
    g = PUZZLE[:]
    for i, v in zip(BLANKS, digits):
        g[i] = v
    good, c = full_check(g)
    fillings, comps = fillings + 1, comps + c
    if good:
        found.append(g)
    k = len(digits) - 1
    while k >= 0 and digits[k] == D:
        digits[k], k = 1, k - 1
    if k < 0:
        break
    digits[k] += 1
b = len(BLANKS)
per = 3 * D * D * (D - 1) // 2
print(f"grid {D} x {D}, {b} blanks; puzzle by rows (0 = blank): {rows(PUZZLE)}")
print(f"input length: {D * D} cells x {bits(D)} bits = {D * D * bits(D)} bits")
print(f"road 1, brute force: fillings tried {fillings:,} = 4^{b}; comparisons {comps:,} = {fillings:,} x {per}")
print(f"road 1, solutions found {len(found)}: {rows(found[0])}")
assert fillings == D ** b and comps == D ** b * per and len(found) == 1

# ---- road 2: backtracking, place a digit only if it clashes with nothing so far ----
tests = 0
def back(g, k, out):
    global tests
    if k == len(BLANKS):
        out.append(g[:]); return
    i = BLANKS[k]
    for v in range(1, D + 1):
        tests += 1
        if all(g[j] != v for u in UNITS if i in u for j in u):
            g[i] = v; back(g, k + 1, out); g[i] = 0
sols = []
back(PUZZLE[:], 0, sols)
print(f"road 2, backtracking: same single solution {'yes' if sols == found else 'no'}; digits tested {tests}")
assert sols == found

# ---- road 3: the enumeration on a tape: a base-4 counter over b cells ----
COUNTER = {("right", c): (c, "R", "right") for c in "1234"}
COUNTER.update({("right", "_"): ("_", "L", "carry"), ("carry", "4"): ("1", "L", "carry"),
                ("carry", "1"): ("2", "R", "right"), ("carry", "2"): ("3", "R", "right"),
                ("carry", "3"): ("4", "R", "right"), ("carry", "_"): ("_", "R", "done")})

def run(rules, word, state, cap=10 ** 7, watch=False):
    # Halts when no row applies.  Returns steps, cells visited, values seen, and
    # the step at which a whole configuration first repeats (watch=True only).
    tape, head, steps, cells, seen, configs = dict(enumerate(word)), 0, 0, {0}, 1, set()
    while (state, tape.get(head, "_")) in rules and steps < cap:
        if watch:
            key = (state, head, tuple(sorted(x for x in tape.items() if x[1] != "_")))
            if key in configs:
                return steps, len(cells), seen, steps
            configs.add(key)
        w, m, nxt = rules[(state, tape.get(head, "_"))]
        seen += state == "carry" and nxt == "right"      # one more value of the counter
        state = nxt
        tape[head] = w
        head += 1 if m == "R" else -1
        steps, cells = steps + 1, cells | {head}
    return steps, len(cells), seen, None

print("tape counter on b blanks: steps, cells used, values seen, steps by 2(4^(b+1) - 1)/3, configuration bound")
for k in range(1, 9):
    steps, cells, seen, _ = run(COUNTER, "1" * k, "right")
    bound = 3 * cells * 5 ** cells
    print(f"  b {k}  steps {steps:>7,}  cells {cells:>2}  values {seen:>6,}  formula {2 * (4 ** (k + 1) - 1) // 3:>7,}  bound {bound:>13,}")
    assert steps == 2 * (4 ** (k + 1) - 1) // 3 and cells == k + 2 and seen == 4 ** k and steps <= bound

print("sizes: d, input bits n, log10 of d^(d^2) fillings, log10 of 2^n, n^4, comparisons per check")
chart = []
for d in (4, 9, 16, 25, 36):
    n = d * d * bits(d)
    f, e = d * d * math.log10(d), n * math.log10(2)
    chart.append((d, f, e))
    print(f"  d {d:>2}  n {n:>5,}  {f:8.2f}  {e:8.2f}  {n ** 4:>22,}  {3 * d * d * (d - 1) // 2:>7,}")
    assert f <= e                              # a filling is one string of n bits

def sci(x):
    e = math.floor(x)
    return f"{10 ** (x - e):.2f} x 10^{e}"
print(f"9 x 9 with 17 givens: 64 blanks, 9^64 = {sci(64 * math.log10(9))} fillings; 324^4 = {324 ** 4:,}")

# ---- what breaks ----
print(f"wrong: one fixed 9 x 9 grid, all blank: 9^81 = {sci(81 * math.log10(9))} fillings, a constant")
print(f"wrong: backtracking's {tests} tests on this puzzle read as the worst case, against {fillings:,} fillings")
s8, c8, _, _ = run(COUNTER, "1" * 8, "right")
print(f"wrong: counting space as time: 8 blanks use {c8} cells but {s8:,} steps")
LOOP = dict(COUNTER); LOOP[("carry", "_")] = ("_", "R", "right")   # overflow restarts the count
for k in (2, 8):
    steps, cells, _, rep = run(LOOP, "1" * k, "right", watch=True)
    print(f"wrong: no halting row, b {k}: {cells} cells, configuration repeats at step {rep:,}, so it never halts")
    assert rep == 2 * (4 ** (k + 1) - 1) // 3 and rep <= 3 * cells * 5 ** cells
steps, cells, _, _ = run(COUNTER, "1" * 9, "right")
print(f"try: counter on 9 blanks: {steps:,} steps, {cells} cells")
assert steps == 2 * (4 ** 10 - 1) // 3 and cells == 11
print("chart, log10 fillings " + " ".join(f"{f:.1f}" for _, f, _ in chart))
print("chart, log10 2^n      " + " ".join(f"{e:.1f}" for _, _, e in chart))
print("ALL CHECKS PASS")
