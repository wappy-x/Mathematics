# Approximation and its limits -- the check behind the card.  Standard library
# only: math for ln and sqrt.  A care home's week has 8 shifts, lengths in hours;
# a staff member works at most CAP = 40.  Fewest staff covering every shift is
# bin packing.  Three roads to the exact answer, then the gap reduction.
import math
WEEK, NOSPLIT, CAP = [12, 12, 12, 10, 10, 10, 8, 6], [12, 12, 12, 12, 12, 10, 10], 40
M64 = (1 << 64) - 1

def first_fit(shifts, cap):  # each shift goes to the first person with room
    rows = []
    for s in shifts:
        for r in rows:
            if sum(r) + s <= cap:
                r.append(s)
                break
        else:
            rows.append([s])
    return rows

def ffd(shifts, cap):  # first fit, longest shift first
    return first_fit(sorted(shifts, reverse=True), cap)

def fewest_exact(xs, cap):  # road 1: best plan over every group of shifts
    n = len(xs)
    full = (1 << n) - 1
    tot = [0] * (full + 1)
    for m in range(1, full + 1):
        low = m & -m
        tot[m] = tot[m ^ low] + xs[low.bit_length() - 1]
    best = [0] + [n + 1] * full
    for m in range(1, full + 1):
        low = m & -m
        rest = m ^ low
        sub = rest
        while True:  # every group holding the lowest shift left
            g = sub | low
            if tot[g] <= cap and best[m ^ g] + 1 < best[m]:
                best[m] = best[m ^ g] + 1
            if sub == 0:
                break
            sub = (sub - 1) & rest
    return best[full]

def split_by_subsets(xs):  # road 2: try all 2^n groups for exactly half
    for m in range(1 << len(xs)):
        if 2 * sum(x for i, x in enumerate(xs) if m >> i & 1) == sum(xs):
            return [x for i, x in enumerate(xs) if m >> i & 1]
    return None

def split_by_table(xs):  # road 3: which totals can a group reach? counts cells
    t = sum(xs)
    if t % 2:
        return False, 0
    reach, cells = [True] + [False] * (t // 2), 0
    for x in xs:
        for s in range(t // 2, x - 1, -1):
            cells += 1
            reach[s] = reach[s] or reach[s - x]
    return reach[t // 2], cells

def ffd_ceiling(k):  # proved ceiling on FFD's staff when the fewest is k
    return (11 * k + 6) // 9

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)

def draw(state, n, lo, hi):
    out = []
    for _ in range(n):
        state, z = splitmix(state)
        out.append(lo + z % (hi - lo + 1))
    return state, out

rows, opt = ffd(WEEK, CAP), fewest_exact(WEEK, CAP)
half = split_by_subsets(WEEK)
yes, cells = split_by_table(WEEK)
print("week, hours", " ".join(map(str, WEEK)), "total", sum(WEEK))
print("floor: total / cap, rounded up", -(-sum(WEEK) // CAP))
print("FFD staff loads", " ".join(str(sum(r)) for r in rows), "-> staff", len(rows))
for i, r in enumerate(rows):
    print(f"  FFD person {i + 1}", " ".join(map(str, r)))
other = list(WEEK)
for x in half:
    other.remove(x)
print("exact fewest, all groups", opt)
print("split by all 256 subsets", " ".join(map(str, half)), "|", " ".join(map(str, other)))
print("split by table", yes, "cells", cells)
assert opt == 2 and yes and 2 * sum(half) == sum(WEEK) and len(rows) == 3
assert [sum(r) for r in rows] == [36, 38, 6]  # by hand: 12+12+12, 10+10+10+8, 6
assert len(ffd([12, 12, 12, 10, 10, 10, 8, 4], CAP)) == 2  # a 4h shift fills 36 to exactly 40
assert len(rows) <= 2 * opt and len(rows) <= ffd_ceiling(opt)
print("FFD/fewest", f"{len(rows) / opt:.3f}", "First Fit ceiling 2*OPT", 2 * opt, "FFD ceiling", ffd_ceiling(opt))
assert all(2 * ffd_ceiling(k) <= 3 * k for k in range(1, 1001))
print("FFD ceiling <= 1.5*OPT for OPT 1 to 1000: True")
print("FFD ceiling before rounding down, OPT 1 2 3:",
      " ".join(f"{(11 * k + 6) / 9:.3f}" for k in (1, 2, 3)), "| 1.5*OPT 1.5 3.0 4.5")
n_opt, n_yes, n_cells = fewest_exact(NOSPLIT, CAP), split_by_subsets(NOSPLIT), split_by_table(NOSPLIT)
print("no-split week", " ".join(map(str, NOSPLIT)), "total", sum(NOSPLIT))
print("  floor", -(-sum(NOSPLIT) // CAP), "exact fewest", n_opt, "FFD", len(ffd(NOSPLIT, CAP)),
      "split", n_yes is not None, n_cells[0])
assert n_opt == 3 and n_yes is None and not n_cells[0]
state, seen = 2026, [0, 0]
for _ in range(300):  # gap reduction: numbers -> rota with cap = half the total
    state, xs = draw(state, 7, 1, 30)
    xs[-1] += sum(xs) % 2
    k = fewest_exact(xs, sum(xs) // 2)
    by_table, by_subsets = split_by_table(xs)[0], split_by_subsets(xs) is not None
    assert by_table == by_subsets and (k == 2) == by_table and k >= 2
    seen[by_table] += 1
print("reduction, 300 number lists: yes -> fewest 2:", seen[1], "no -> fewest >= 3:", seen[0])
worst_ff = worst_ffd = 0.0
ffd_miss = 0
for _ in range(400):  # random weeks: the ratios proved, against the exact fewest
    state, xs = draw(state, 8, 4, 12)
    k, a, b = fewest_exact(xs, CAP), len(first_fit(xs, CAP)), len(ffd(xs, CAP))
    assert a <= 2 * k and b <= ffd_ceiling(k) and b >= k
    worst_ff, worst_ffd, ffd_miss = max(worst_ff, a / k), max(worst_ffd, b / k), ffd_miss + (b > k)
print("400 random weeks: worst First Fit", f"{worst_ff:.3f}", "worst FFD", f"{worst_ffd:.3f}",
      "FFD above fewest", ffd_miss)
big = ffd(WEEK * 10, CAP)
plan = [half, other] * 10  # ten copies of the two-person split
assert sorted(x for r in plan for x in r) == sorted(WEEK * 10) and all(sum(r) <= CAP for r in plan)
print("ten weeks: floor", sum(WEEK) * 10 // CAP, "split plan", len(plan), "FFD", len(big),
      "ratio", f"{len(big) / len(plan):.3f}", "FFD ceiling", ffd_ceiling(len(plan)))
h30 = sum(1 / j for j in range(1, 31))
print("set cover, 30 shifts: H(30)", f"{h30:.3f}", "ln 30", f"{math.log(30):.3f}",
      "vertex cover floor sqrt 2", f"{math.sqrt(2):.3f}")
for name, xs, cap in [("try 6h -> 4h", [12, 12, 12, 10, 10, 10, 8, 4], CAP),
                      ("try cap 41", WEEK, 41), ("try 12h -> 11h", [11, 12, 12, 10, 10, 10, 8, 6], CAP)]:
    print(name, "total", sum(xs), "exact fewest", fewest_exact(xs, cap), "FFD", len(ffd(xs, cap)))
print("ALL CHECKS PASS")
