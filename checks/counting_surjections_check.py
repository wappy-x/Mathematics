# Onto functions -- the check behind the card.  Nothing is imported.  Five different repair
# jobs go to three named mechanics, every mechanic getting at least one.  The sieve count is
# met by listing every handout, by the grouping recurrence, and by splitting all handouts.
JOBS, MECHANICS = 5, 3

def choose(n, k):                            # C(n, k), one factor at a time
    out = 1
    for i in range(k): out = out * (n - i) // (i + 1)
    return out
def factorial(n):                            # n! = 1 x 2 x ... x n
    out = 1
    for i in range(2, n + 1): out *= i
    return out
def sieve(n, k):                             # road one: inclusion-exclusion
    return sum((-1) ** j * choose(k, j) * (k - j) ** n for j in range(k + 1))
def handouts(n, k):                          # every way to send n jobs to k mechanics
    out = [()]
    for _ in range(n): out = [h + (w,) for h in out for w in range(k)]
    return out
def listed(n, k):                            # road two: list them, keep the onto ones
    return sum(1 for h in handouts(n, k) if len(set(h)) == k)
def groupings(n, k):                         # road three: list the block structures
    return len({tuple(sorted(tuple(i for i in range(n) if h[i] == w) for w in range(k)))
                for h in handouts(n, k) if len(set(h)) == k})
def stirling(n, k):                          # road three's formula, by recurrence
    row = [1] + [0] * k
    for _ in range(n):
        row = [0] + [j * row[j] + row[j - 1] for j in range(1, k + 1)]
    return row[k]

layer = [choose(MECHANICS, j) * (MECHANICS - j) ** JOBS for j in range(MECHANICS + 1)]
onto, s53 = sieve(JOBS, MECHANICS), stirling(JOBS, MECHANICS)
by_used = [choose(MECHANICS, j) * sieve(JOBS, j) for j in range(1, MECHANICS + 1)]
patterns = sum(1 for a in range(1, JOBS) for b in range(1, JOBS) if JOBS - a - b >= 1)
sieve_row = [sieve(n, MECHANICS) for n in range(1, JOBS + 2)]
listed_row = [listed(n, MECHANICS) for n in range(1, JOBS + 2)]
all_row = [MECHANICS ** n for n in range(1, JOBS + 2)]
k_row = [sieve(JOBS, k) for k in range(1, MECHANICS + 4)]

print(f"{JOBS} jobs to {MECHANICS} named mechanics: all handouts {MECHANICS}^{JOBS} = {layer[0]}")
print(f"one named mechanic left empty: 2^{JOBS} = {(MECHANICS - 1) ** JOBS} each, {choose(MECHANICS, 1)} mechanics to pick, layer 1 = {layer[1]}")
print(f"two named mechanics left empty: 1^{JOBS} = {(MECHANICS - 2) ** JOBS} each, {choose(MECHANICS, 2)} pairs to pick, layer 2 = {layer[2]}")
print(f"all {MECHANICS} left empty: 0^{JOBS} = {0 ** JOBS}, layer 3 = {layer[3]}")
print(f"sieve: {layer[0]} - {layer[1]} + {layer[2]} - {layer[3]} = {onto}")
print(f"listing all {MECHANICS ** JOBS} handouts, those reaching every mechanic: {listed(JOBS, MECHANICS)}")
print(f"groupings of {JOBS} jobs into {MECHANICS} unnamed piles: {s53} by recurrence, {groupings(JOBS, MECHANICS)} by listing")
print(f"naming the piles: {MECHANICS}! x {s53} = {factorial(MECHANICS)} x {s53} = {factorial(MECHANICS) * s53}")
print(f"all handouts split by mechanics used: 3 x {sieve(JOBS, 1)} + 3 x {sieve(JOBS, 2)} + 1 x {sieve(JOBS, 3)} = {sum(by_used)}")
print(f"second case, {JOBS + 1} jobs to {MECHANICS} mechanics: sieve {sieve(JOBS + 1, MECHANICS)}, listed {listed(JOBS + 1, MECHANICS)}, {MECHANICS}! x S(6,3) = 6 x {stirling(JOBS + 1, MECHANICS)} = {factorial(MECHANICS) * stirling(JOBS + 1, MECHANICS)}")
print(f"jobs n = 1 to 6, onto handouts to {MECHANICS} mechanics: {sieve_row}")
print(f"jobs n = 1 to 6, all handouts to {MECHANICS} mechanics:  {all_row}")
print(f"mechanics k = 1 to 6, onto handouts of {JOBS} jobs: {k_row}")
print(f"mistake 1, stopping after the subtraction: {layer[0]} - {layer[1]} = {layer[0] - layer[1]}, not {onto}")
print(f"mistake 2, mechanics treated as alike: {s53} groupings, not {onto} handouts")
print(f"mistake 3, jobs treated as alike: {patterns} share-out patterns, not {onto} handouts")
assert sieve_row == listed_row and k_row == [listed(JOBS, k) for k in range(1, MECHANICS + 4)] and onto == 150
assert factorial(MECHANICS) * s53 == onto and s53 == groupings(JOBS, MECHANICS)
assert sum(by_used) == len(handouts(JOBS, MECHANICS))       # the split accounts for every handout
assert sieve(JOBS + 1, MECHANICS) == listed(JOBS + 1, MECHANICS) == factorial(MECHANICS) * stirling(JOBS + 1, MECHANICS)
print("ALL CHECKS PASS")
