# Set partitions and Bell numbers -- the check behind the card.  Nothing is imported.  Four
# friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names, so a split
# records only who rides with whom.  Three roads share no arithmetic: every split listed,
# the recurrence on the newest friend's taxi-mates, and the addition-only Bell triangle.
NAMES, TOP = "ABCD", 8
def splits(n):                             # road one: list every split, friend by friend
    if n == 0: return [()]
    out = []
    for rest in splits(n - 1):
        out.append(rest + ((n - 1,),))     # the newest friend takes a taxi alone
        for i in range(len(rest)): out.append(rest[:i] + (rest[i] + (n - 1,),) + rest[i + 1:])
    return out
def choose(n, k):                          # Pascal's rule written out, nothing imported
    row = [1]
    for _ in range(n): row = [1] + [row[j - 1] + row[j] for j in range(1, len(row))] + [1]
    return row[k] if 0 <= k <= n else 0
def by_recurrence(top, floor):             # road two: B(n+1) = C(n,0)B(0) + ... + C(n,n)B(n)
    B = [floor]
    for n in range(top): B.append(sum(choose(n, k) * B[k] for k in range(n + 1)))
    return B
def triangle(top):                         # road three: addition alone
    rows = [[1]]
    for _ in range(top):
        row = [rows[-1][-1]]
        for x in rows[-1]: row.append(row[-1] + x)
        rows.append(row)
    return rows
def show(s):                               # one split written out, smallest taxi first
    return "|".join("".join(NAMES[i] for i in b) for b in sorted(s, key=lambda b: (len(b), b)))
def yn(claim): return "yes" if claim else "no"
listed = [len(splits(n)) for n in range(TOP + 1)]
B = by_recurrence(TOP, 1)
dead = by_recurrence(4, 0)                 # the same recurrence with the floor set to 0
rows = triangle(TOP)
four = splits(4)
by_taxis = [sum(1 for s in four if len(s) == k) for k in range(5)]
mates = [sum(1 for s in four if 4 - len(next(b for b in s if 3 in b)) == k) for k in range(4)]
formula = [choose(3, k) * B[k] for k in range(4)]
patterns = {tuple(sorted(len(b) for b in s)) for s in four}
two_named = 2 ** 4 - 2                     # every yes-or-no labelling but the two that empty a taxi
print("four friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names")
for k, word in ((1, "one taxi   "), (2, "two taxis  "), (3, "three taxis"), (4, "four taxis ")):
    print(f"  {word} ({by_taxis[k]}): " + "  ".join(sorted(show(s) for s in four if len(s) == k)))
print(f"listed one at a time: {listed[4]} splits of four friends and {listed[5]} of five")
print(f"Dara's taxi-mates: all three -> 1 x B(0) = {formula[0]}; two of the three -> 3 x B(1) = "
      f"{formula[1]}; one of the three -> 3 x B(2) = {formula[2]}; nobody -> 1 x B(3) = {formula[3]}")
print(f"recurrence: B(4) = 1x1 + 3x1 + 3x2 + 1x5 = {B[4]};  B(5) = 1x1 + 4x1 + 6x2 + 4x5 + 1x15 = {B[5]}")
print(f"B(0) to B({TOP}) by recurrence: {B}")
print(f"the same numbers by listing every split: {yn(listed == B)}; "
      f"from the Bell triangle: {yn([r[0] for r in rows] == B)}")
print("Bell triangle, rows 0 to 4: " + " / ".join(" ".join(str(x) for x in r) for r in rows[:5]))
print(f"mistake, taxis numbered: four friends into two named taxis, neither empty = {two_named} ways, not {by_taxis[2]}")
print(f"mistake, only the group sizes kept: {len(patterns)} size patterns, not {B[4]}")
print(f"mistake, B(0) taken as 0: the recurrence gives B(1) to B(4) = {dead[1:]}, not {B[4]}")
print(f"mistake, index slipped: C(4,0)B(0) + ... + C(4,4)B(4) = {B[5]}, which is B(5), not B(4)")
assert listed == B                                    # every split listed, against the recurrence
assert [r[0] for r in rows] == B                      # addition alone, against the recurrence
assert mates == formula and by_taxis == [0, 1, 7, 6, 1]
assert two_named == 2 * by_taxis[2]                   # labellings, against the listed two-taxi splits
print("ALL CHECKS PASS")
