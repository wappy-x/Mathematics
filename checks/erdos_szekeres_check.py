# Erdos-Szekeres -- the check behind the card.  Nothing is imported.  Ten daily
# closing prices of Harlow Cement, all different.  Each day carries two labels:
# the longest strictly rising run of days ending there, and the longest strictly
# falling one.  Road two ignores the labels and tries every set of days instead.
PRICES = [43.20, 42.10, 44.60, 41.65, 43.95, 46.30, 42.88, 45.15, 47.05, 45.70]
NINE = [45.90, 44.30, 43.10, 48.70, 47.20, 46.40, 51.50, 50.10, 49.30]
TIED, R, N = [44.00, 43.00] * 5, 4, 10
UP, DOWN, NEVER_DOWN = (lambda u, v: u < v), (lambda u, v: u > v), (lambda u, v: u <= v)
def labels(p, ok):                  # road one: look back from each day in turn
    out = []
    for j, x in enumerate(p): out.append(max([out[i] + 1 for i in range(j) if ok(p[i], x)] + [1]))
    return out
def longest(p, ok):                 # road two: try all 2^n sets of days, labels unused
    sets = ([i for i in range(len(p)) if m >> i & 1] for m in range(1 << len(p)))
    return max(len(d) for d in sets if all(ok(p[i], p[j]) for i, j in zip(d, d[1:])))
def trace(p, lab, ok):              # walk back from the first day holding the top label
    k = max(lab); j = lab.index(k); run = [j]
    while k > 1:
        j = next(i for i in range(j) if lab[i] == k - 1 and ok(p[i], p[j])); run.append(j); k -= 1
    return run[::-1]
def streak(p, ok):                  # the wrong reading: days in a row only
    runs = [1]
    for i in range(1, len(p)): runs.append(runs[-1] + 1 if ok(p[i - 1], p[i]) else 1)
    return max(runs)
def show(p, run, sign):
    return "days " + ", ".join(str(i + 1) for i in run) + " at " + f" {sign} ".join(f"{p[i]:.2f}" for i in run)
def row(name, values):
    return f"{name:<16}" + "".join(f"{v:>6}" for v in values)
a, b = labels(PRICES, UP), labels(PRICES, DOWN)
na, nb = labels(NINE, UP), labels(NINE, DOWN)
grid = sorted(zip(na, nb)) == [(i, j) for i in (1, 2, 3) for j in (1, 2, 3)]
run_up, run_down = trace(PRICES, a, UP), trace(PRICES, b, DOWN)
brute = (longest(PRICES, UP), longest(PRICES, DOWN), longest(NINE, UP), longest(NINE, DOWN))
print("ten closing prices, day 1 to day 10: " + " ".join(f"{x:.2f}" for x in PRICES))
print(row("day", range(1, N + 1)))
print(row("rising label a", a))
print(row("falling label b", b))
print(f"all {N} label pairs different: {'yes' if len(set(zip(a, b))) == N else 'no'}")
print(f"longest rising run: labels {max(a)}, every set of days tried {brute[0]}")
print(f"longest falling run: labels {max(b)}, every set of days tried {brute[1]}")
print(f"{max(a)} x {max(b)} = {max(a) * max(b)}, and that is at least the {N} days")
print(f"the rising run of {max(a)}: " + show(PRICES, run_up, "<"))
print(f"the falling run of {max(b)}: " + show(PRICES, run_down, ">"))
print(f"boxes if no label passed 3: 3 x 3 = 9, one fewer than the {N} days")
print("nine days, " + " ".join(f"{x:.2f}" for x in NINE) +
      f": longest rising {brute[2]}, longest falling {brute[3]}")
print(f"its nine label pairs fill the 3 x 3 grid once each: {'yes' if grid else 'no'}")
print(f"mistake 1, runs read as days in a row: longest rising {streak(PRICES, UP)}, longest falling {streak(PRICES, DOWN)}")
print(f"mistake 2, nine days instead of ten: longest rising {max(na)}, one short of {R}")
print(f"mistake 3, only 44.00 and 43.00, alternating: longest rising {longest(TIED, UP)}, "
      f"longest falling {longest(TIED, DOWN)}, longest never-falling {longest(TIED, NEVER_DOWN)}")
assert (max(a), max(b)) == (brute[0], brute[1]) == (4, 3)
assert len(set(zip(a, b))) == N and max(a) * max(b) >= N
assert len(run_up) == R and all(PRICES[i] < PRICES[j] for i, j in zip(run_up, run_up[1:])) and streak(PRICES, UP) < R
assert (max(na), max(nb)) == (brute[2], brute[3]) == (3, 3) and grid
print("ALL CHECKS PASS")
