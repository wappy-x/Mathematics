# Stirling numbers of the second kind -- the check behind the card.  Nothing is
# imported.  Five named tools, H P C F T, go into unnamed toolboxes, none left
# empty.  Every count is reached twice: by the recurrence S(n,k) = k S(n-1,k)
# + S(n-1,k-1), and by listing the splits, which never mentions the recurrence.
TOOLS, N = "HPCFT", 5

def triangle(nmax):                       # road one: one multiply, one add per cell
    T = [[0] * (nmax + 1) for _ in range(nmax + 1)]
    T[0][0] = 1
    for n in range(1, nmax + 1):
        for k in range(1, n + 1): T[n][k] = k * T[n - 1][k] + T[n - 1][k - 1]
    return T

def labellings(items, tags):              # every way to hand each tool one tag
    out = [()]
    for _ in range(items): out = [f + (j,) for f in out for j in range(tags)]
    return out

def split_of(f):                          # the groups a labelling makes, tags dropped
    groups = {}
    for i, tag in enumerate(f): groups[tag] = groups.get(tag, "") + TOOLS[i]
    return tuple(sorted(groups.values()))

def fact(k):
    out = 1
    for j in range(2, k + 1): out *= j
    return out

def choose(n, k):
    return fact(n) // (fact(k) * fact(n - k))

T = triangle(N)
splits = sorted({split_of(f) for f in labellings(N, N)})        # road two: list them
row = [sum(1 for s in splits if len(s) == k) for k in range(N + 1)]
sieve = sum((-1) ** (3 - j) * choose(3, j) * j ** N for j in range(4)) // fact(3)
onto = [f for f in labellings(N, 3) if len(set(f)) == 3]
shape = [sum(1 for s in splits if sorted(len(g) for g in s) == list(sz)) for sz in ((1, 4), (2, 3))]
print(f"five tools {' '.join(TOOLS)}; triangle S(n,k) by the recurrence, rows n = 0 to {N}")
print("  n\\k" + "".join(f"{k:6d}" for k in range(N + 1)))
for n in range(N + 1):
    print(f"{n:5d}" + "".join(f"{T[n][k]:6d}" for k in range(n + 1)))
for k in (2, 3):
    print(f"S(5,{k}): tape alone {T[N - 1][k - 1]}, tape joins one of the {k} groups "
          f"{k} x {T[N - 1][k]} = {k * T[N - 1][k]}, total {T[N][k]}; by listing: {row[k]}")
print(f"S(5,2) by shape: {shape[0]} splits of sizes 4+1, {shape[1]} of sizes 3+2, total {sum(shape)}")
print(f"S(5,3) by inclusion-exclusion: ({3 ** N} - 3 x {2 ** N} + 3) / 3! = ({3 ** N} - {3 * 2 ** N} + 3) / {fact(3)} = {sieve}")
print(f"Bell B(5) = {' + '.join(str(T[N][k]) for k in range(1, N + 1))} = {sum(T[N])}; "
      f"at most three groups: {sum(T[N][:4])}; every split listed: {len(splits)}")
print(f"onto maps, five tools to 3 named boxes, listed one by one: {len(onto)}; "
      f"3! x S(5,3) = {fact(3)} x {T[N][3]} = {fact(3) * T[N][3]}")
print(f"mistake 1, adding the two rows Pascal-style: {T[N - 1][3]} + {T[N - 1][2]} = "
      f"{T[N - 1][3] + T[N - 1][2]}, not {T[N][3]}")
print(f"mistake 2, naming the three boxes: {fact(3) * T[N][3]}, not {T[N][3]}")
print(f"mistake 3, letting a box stay empty: 3^5 = {3 ** N} labellings, not {len(onto)} onto maps")
print(f"mistake 4, reading C(5,3) as S(5,3): {choose(5, 3)}, which is S(5,4) = {T[N][4]}")
assert row == [T[N][k] for k in range(N + 1)]        # listed splits against the recurrence
assert len(splits) == sum(T[N]) == 52                # every split against the row sum
assert len(onto) == fact(3) * T[N][3]                # listed onto maps against 3! S(5,3)
assert sieve == T[N][3] and sum(shape) == T[N][2]    # the sieve, and the shapes, against the table
print("ALL CHECKS PASS")
