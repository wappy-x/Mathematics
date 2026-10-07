# The twelvefold way -- the check behind the card.  Nothing is imported.  Five parcels into
# three vans, then two parcels into three vans.  Each of the twelve counts is reached twice:
# by listing every loading and stripping the labels the question ignores, and by its formula.
WAYS = (("differ", "differ"), ("differ", "alike"), ("alike", "differ"), ("alike", "alike"))
RULES = ("any", "at most one", "at least one")
def choose(m, r):                            # C(m, r), one factor at a time; 0 when r > m
    out = 0 if r < 0 or r > m else 1
    for i in range(r): out = out * (m - i) // (i + 1)
    return out
def falling(k, n):                           # count down from k for n steps: k x (k-1) x ...
    out = 1
    for i in range(n): out *= k - i
    return out
def blocks(n, k):                            # S(n, k) = k x S(n-1, k) + S(n-1, k-1)
    row = [1] + [0] * k
    for _ in range(n): row = [0] + [j * row[j] + row[j - 1] for j in range(1, k + 1)]
    return row[k]
def parts(n, k):                             # n as a sum of exactly k positive parts
    if n == k: return 1
    return 0 if k == 0 or n < k else parts(n - 1, k - 1) + parts(n - k, k)
def listing(n, k):                           # road one: every loading, the labels stripped
    loads = [()]
    for _ in range(n): loads = [f + (v,) for f in loads for v in range(k)]
    def keyset(things, vans, rule):
        keys = set()
        for f in loads:
            c = [f.count(v) for v in range(k)]
            if rule == "at most one" and max(c) > 1: continue
            if rule == "at least one" and min(c) < 1: continue
            if vans == "differ": keys.add(f if things == "differ" else tuple(c))
            elif things == "alike": keys.add(tuple(sorted([x for x in c if x], reverse=True)))
            else: keys.add(tuple(b for b in sorted(tuple(i for i in range(n) if f[i] == v) for v in range(k)) if b))
        return keys
    return [[keyset(t, v, r) for r in RULES] for t, v in WAYS]
def formulas(n, k):                          # road two: the twelve closed forms, same order
    b = [blocks(n, j) for j in range(1, k + 1)]
    p = [parts(n, j) for j in range(1, k + 1)]
    one = 1 if n <= k else 0
    return [[k ** n, falling(k, n), falling(k, k) * b[k - 1]], [sum(b), one, b[k - 1]],
            [choose(n + k - 1, k - 1), choose(k, n), choose(n - 1, k - 1)], [sum(p), one, p[k - 1]]]
L, F = listing(5, 3), formulas(5, 3)
M, G = listing(2, 3), formulas(2, 3)
for n, k, A, B in ((5, 3, L, F), (2, 3, M, G)):
    print(f"{n} parcels into {k} vans, each cell listed then by formula")
    for i, (things, vans) in enumerate(WAYS):
        print(f"  parcels {things:<6} vans {vans:<6}" + "".join(
              f"   {RULES[j]}: {len(A[i][j]):>3} {B[i][j]:>3}" for j in range(3)))
used = [[choose(3, j) * falling(j, j) * blocks(5, j) for j in (1, 2, 3)], [blocks(5, j) for j in (1, 2, 3)],
        [choose(3, j) * choose(4, j - 1) for j in (1, 2, 3)], [parts(5, j) for j in (1, 2, 3)]]
print("5 as a sum of at most 3 parts: " + ", ".join("+".join(str(x) for x in q) for q in sorted(L[3][0], reverse=True)))
print(f"no van left empty, two roads: listed {len(L[0][2])}, 3! x S(5,3) = {falling(3, 3)} x {blocks(5, 3)}")
print("each 'any' cell split by vans used: " + "; ".join(f"{' + '.join(str(x) for x in u)} = {sum(u)}" for u in used))
print(f"unlabelling the vans by dividing: 243 / 3! = 243 / {falling(3, 3)} = {243 / falling(3, 3):.1f}, not {F[1][0]}")
assert [[len(x) for x in r] for r in L] == F and [[len(x) for x in r] for r in M] == G
assert [F[i][0] for i in range(4)] == [243, 41, 21, 5] and [F[i][2] for i in range(4)] == [150, 25, 6, 2]
assert [sum(u) for u in used] == [len(L[i][0]) for i in range(4)] and len(L[0][2]) == falling(3, 3) * len(L[1][2])
assert [len(x) for x in M[0]] == [9, 6, 0] and [G[i][1] for i in range(4)] == [6, 1, 3, 1]
print("ALL CHECKS PASS")
