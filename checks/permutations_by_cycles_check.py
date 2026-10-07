# Counting shuffles by their loops -- the check behind the card.  Nothing is
# imported.  Five keys come off a keyring onto five labelled hooks, and a rehang
# is a destination list: entry i names the hook the key from hook i goes to.
# Three roads sharing no arithmetic count the rehangs with exactly k loops:
# listing all 120 and tracing each, the recurrence c(n,k) = (n-1) c(n-1,k) +
# c(n-1,k-1), and the cycle-type count n! / (product of j^a_j times a_j!).
N = 5

def rehangs(n):                          # every destination list, no hook used twice
    out = [()]
    for _ in range(n): out = [p + (d,) for p in out for d in range(1, n + 1) if d not in p]
    return out
def loops(p):                            # follow a hook until the key comes back
    seen, out = set(), []
    for start in range(1, len(p) + 1):
        cyc = []
        while start not in seen: cyc.append(start); seen.add(start); start = p[start - 1]
        if cyc: out.append(cyc)
    return out
def factorial(n): return 1 if n < 2 else n * factorial(n - 1)
def splits(n, most):                     # the ways n breaks into parts, largest first
    if n == 0: return [()]
    return [(j,) + r for j in range(min(n, most), 0, -1) for r in splits(n - j, j)]
def size(q):                             # n! / (product of j^a_j times a_j!)
    out = factorial(sum(q))
    for i, j in enumerate(q): out //= j * q[:i + 1].count(j)
    return out
def at(row, k): return row[k - 1] if 1 <= k <= len(row) else 0
def flat(row): return " ".join(str(v) for v in row)
def name(p): return "".join("(" + flat(c) + ")" for c in loops(p))
def lengths(p): return ", ".join(str(len(c)) for c in loops(p))

deck, parts, three, whole = rehangs(N), splits(N, N), (3, 5, 1, 4, 2), (2, 3, 4, 5, 1)
listed = [sum(1 for p in deck if len(loops(p)) == k) for k in range(1, N + 1)]
typed = [sum(size(q) for q in parts if len(q) == k) for k in range(1, N + 1)]
tri, sec = [[1]], [[1]]                  # first kind, and second kind for contrast
for n in range(2, N + 1):
    tri.append([(n - 1) * at(tri[-1], k) + at(tri[-1], k - 1) for k in range(1, n + 1)])
    sec.append([k * at(sec[-1], k) + at(sec[-1], k - 1) for k in range(1, n + 1)])
deranged = sum(1 for p in deck if all(p[i] != i + 1 for i in range(N)))
no_ones = sum(size(q) for q in parts if min(q) >= 2)
print(f"five keys on five hooks: {len(deck)} rehangs in all")
print(f"rehang {flat(three)} traced: {name(three)}, {len(loops(three))} loops of lengths {lengths(three)}")
print(f"rehang {flat(whole)} traced: {name(whole)}, {len(loops(whole))} loop of length {lengths(whole)}")
print("the triangle by the recurrence:   " + "   ".join(f"n={n + 1}: {flat(tri[n])}" for n in range(N)))
print(f"row 5 by listing all {len(deck)} rehangs: {flat(listed)}; from the cycle types: {flat(typed)}")
print(f"row sum {' + '.join(str(v) for v in listed)} = {sum(listed)}, and 5! = {factorial(N)}; "
      f"corners c(5,1) = 4! = {tri[4][0]}, c(5,5) = {tri[4][4]}, c(5,4) = C(5,2) = {tri[4][3]}")
print(f"the recurrence at c(5,3): 4 x c(4,3) + c(4,2) = 4 x {tri[3][2]} + {tri[3][1]} = {tri[4][2]}")
print("cycle types: " + ", ".join("+".join(str(j) for j in q) + f" -> {size(q)}" for q in parts))
print(f"no loop of length 1, by listing {deranged}; from the cycle types "
      + " + ".join(str(size(q)) for q in parts if min(q) >= 2) + f" = {no_ones}")
print(f"blocks are not loops: S(5,3) = {sec[4][2]} against c(5,3) = {tri[4][2]}")
print(f"mistakes: the multiplier read as k, 3 x {tri[3][2]} + {tri[3][1]} = {3 * tri[3][2] + tri[3][1]}; "
      f"the single hook left out, {sum(1 for c in loops(three) if len(c) > 1)} loops not {len(loops(three))}")
assert listed == tri[N - 1]                        # listing against the recurrence
assert listed == typed                             # listing against the cycle types
assert deranged == no_ones                         # two roads to the no-single-hook count
assert sum(listed) == factorial(N) == len(deck)    # the row sum, three ways
print("ALL CHECKS PASS")
