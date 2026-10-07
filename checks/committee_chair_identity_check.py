# Committee and chair -- the check behind the card.  Nothing is imported.  An office
# of 10 picks a committee of any size and one chair from inside it.  The (committee,
# chair) pairs are counted by roads that share no arithmetic: every committee walked
# one at a time, the closed form 10 x 2^9 read off Pascal's triangle, and every
# committee paired with the one holding everybody it leaves out.  The front room of
# four is listed by hand.
N = 10
FRONT = ["Farah", "Gus", "Hana", "Ivo"]
def committees(n):                         # every committee: one bit per person, in or out
    out = [[i for i in range(n) if m >> i & 1] for m in range(2 ** n)]
    out.sort(key=lambda s: (len(s), s))
    return out
def triangle(top):                         # Pascal's rule: each entry from the two above
    rows = [[1]]
    for n in range(1, top + 1):
        above = rows[-1]
        rows.append([1] + [above[k - 1] + above[k] for k in range(1, n)] + [1])
    return rows
def letters(s): return "".join(FRONT[i][0] for i in s)   # a committee, by first letters
def yn(claim): return "yes" if claim else "no"

rows = triangle(N)
front = committees(len(FRONT))
front_pairs = [(s, c) for s in front for c in s]   # committee first, then a chair inside it
front_sizes = [sum(1 for s, c in front_pairs if len(s) == k) for k in range(len(FRONT) + 1)]
office = committees(N)                             # road one: walk all 1,024 committees
pairs = sum(len(s) for s in office)
listed = [sum(len(s) for s in office if len(s) == k) for k in range(N + 1)]
absorbed = [N * rows[N - 1][k - 1] if k >= 1 else 0 for k in range(N + 1)]   # road two
closed = N * 2 ** (N - 1)
complement = len(office) // 2 * N                  # road three: a committee and the rest
row_total = sum(rows[N])

print(f"office of {N}; a committee of any size, one chair from inside it")
print(f"front room of {len(FRONT)} -- {', '.join(FRONT)} -- every committee|chair pair listed:")
for k in range(1, len(FRONT) + 1):
    got = [f"{letters(s)}|{FRONT[c][0]}" for s, c in front_pairs if len(s) == k]
    print(f"  size {k}: {' '.join(got)}  ->  {len(got)}")
print(f"  total {len(front_pairs)}; chair first: {len(FRONT)} x 2^{len(FRONT) - 1} = "
      f"{len(FRONT)} x {2 ** (len(FRONT) - 1)} = {len(FRONT) * 2 ** (len(FRONT) - 1)}")
print(f"row {N} of the triangle: {' '.join(str(x) for x in rows[N])}  adds to {row_total}")
print(f"pairs by committee size, k C({N},k): {' '.join(str(x) for x in listed)}")
print(f"the same terms, chair first, {N} C({N - 1},k-1): "
      f"{' '.join(str(x) for x in absorbed)}  (agree: {yn(listed == absorbed)})")
print(f"the eleven terms added: {sum(listed)}; chair first in one step: "
      f"{N} x 2^{N - 1} = {N} x {2 ** (N - 1)} = {closed}")
print(f"every committee walked one at a time: {pairs} pairs over {len(office)} committees")
print(f"complement pairing: {len(office) // 2} pairs of committees x {N} people = {complement}")
print(f"average committee size: {pairs} / {len(office)} = {pairs // len(office)}")
print(f"the k = 3 term: 3 x {rows[N][3]} = {3 * rows[N][3]} = "
      f"{N} x C({N - 1},2) = {N} x {rows[N - 1][2]}")
print(f"mistakes: a chair from the whole office gives {N * len(office)}, not {pairs}; "
      f"dropping the k gives {row_total}, not {pairs}; shifting the index gives "
      f"{N} x C({N - 1},3) = {N * rows[N - 1][3]} at k = 3, not {3 * rows[N][3]}")
assert pairs == closed                             # every committee walked, against the formula
assert listed == absorbed                          # size by size: committee first vs chair first
assert row_total == 1024 and complement == pairs   # the house row sum, and the third road
assert front_sizes == [0, 4, 12, 12, 4] and len(front_pairs) == len(FRONT) * 2 ** (len(FRONT) - 1)
print("ALL CHECKS PASS")
