# Hall's theorem -- the check behind the card.  Nothing is imported.  Six
# applicants and six jobs at a small hotel; a line joins an applicant to a job
# she is qualified for.  Three roads: Hall's condition over all 64 groups, an
# augmenting-path search that never mentions Hall, and a census of placements.
JOBS = ["front desk", "kitchen", "laundry", "bar", "maintenance", "accounts"]
NAMES = ["Ana", "Ben", "Cleo", "Dev", "Eve", "Fay"]
BLOCKED = [[0, 5], [0, 5], [5], [1, 2, 3], [2, 4], [3, 4, 1]]
REPAIRED = [[0, 5], [0, 5], [5, 2], [1, 2, 3], [2, 4], [3, 4, 1]]
NO_ACCOUNTS = [[j for j in a if j != 5] for a in REPAIRED]

def worst_gap(adj):                        # road one: Hall's count on every group
    gap, who = 0, ()
    for mask in range(1 << len(adj)):
        group = tuple(i for i in range(len(adj)) if mask >> i & 1)
        short = len(group) - len({j for i in group for j in adj[i]})
        if short > gap: gap, who = short, group
    return gap, who

def augment(adj, i, taken, seen):          # road two: the alternating-path search
    for j in adj[i]:
        if not seen[j]:
            seen[j] = True
            if taken[j] < 0 or augment(adj, taken[j], taken, seen):
                taken[j] = i
                return True
    return False

def hold(adj):                             # which applicant holds each job, -1 none
    taken = [-1] * len(JOBS)
    for i in range(len(adj)): augment(adj, i, taken, [False] * len(JOBS))
    return taken

def census(adj, i=0, used=()):             # road three: count complete placements
    if i == len(adj): return 1
    return sum(census(adj, i + 1, used + (j,)) for j in adj[i] if j not in used)
def size(taken): return sum(1 for i in taken if i >= 0)    # jobs that ended up filled

n, (gap_b, trio) = len(NAMES), worst_gap(BLOCKED)
gap_r, gap_c = worst_gap(REPAIRED)[0], worst_gap(NO_ACCOUNTS)[0]
held_b, held_r, held_c = hold(BLOCKED), hold(REPAIRED), hold(NO_ACCOUNTS)
full_b, full_r = census(BLOCKED), census(REPAIRED)
left_out = ", ".join(NAMES[i] for i in range(n) if i not in held_b)
trio_names, trio_lines = ", ".join(NAMES[i] for i in trio), sum(len(BLOCKED[i]) for i in trio)
trio_reach, singles = len({j for i in trio for j in BLOCKED[i]}), sum(1 for a in BLOCKED if a)
pairs = " ".join(f"{NAMES[i]}-{JOBS[j]}" for j, i in sorted(enumerate(held_r), key=lambda p: p[1]))
print(f"applicants {n}, jobs {len(JOBS)}; qualification lines: blocked {sum(len(a) for a in BLOCKED)}, repaired {sum(len(a) for a in REPAIRED)}")
print(f"blocked : worst group of all {1 << n} is {trio_names} -- {len(trio)} applicants, {trio_reach} jobs, gap {gap_b}")
print(f"blocked : augmenting paths place {size(held_b)}; Hall's count {n} - {gap_b} = {n - gap_b}; left out {left_out}")
print(f"repaired: worst gap over all {1 << n} groups is {gap_r}")
print(f"repaired: augmenting paths place {size(held_r)}; Hall's count {n} - {gap_r} = {n - gap_r}")
print(f"repaired: {pairs}")
print(f"complete placements by census: blocked {full_b}, repaired {full_r}")
print(f"mistake 1, one applicant at a time: {singles} of {n} applicants pass, yet only {size(held_b)} are placed")
print(f"mistake 2, the trio's lines counted, not the jobs they reach: {trio_lines} lines, {trio_reach} jobs")
print(f"mistake 3, accounts post deleted from the repaired graph: gap {gap_c}, {size(held_c)} placed")
assert size(held_b) == n - gap_b and size(held_r) == n - gap_r
assert (full_b > 0) == (size(held_b) == n) and (full_r > 0) == (size(held_r) == n)
assert full_r == 4 and size(held_c) == n - gap_c
assert trio == (0, 1, 2) and trio_reach == 2 and singles == n
print("ALL CHECKS PASS")
