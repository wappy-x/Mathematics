# Zorn's lemma -- the check behind the card.  Nothing is imported.  Four arrows in 3D space; the collection is every independent set of them, ordered by "inside".
V = {"a": (1, 0, 0), "b": (1, 1, 0), "c": (2, 1, 0), "d": (0, 0, 1)}
def rank(s):                       # elimination in whole numbers: count the rows that survive
    rows, r = [list(V[x]) for x in s], 0
    for col in range(3):
        p = next((i for i in range(r, len(rows)) if rows[i][col]), None)
        if p is None: continue
        rows[r], rows[p] = rows[p], rows[r]; rows[r + 1:], r = [[rows[r][col] * x - row[col] * y for x, y in zip(row, rows[r])] for row in rows[r + 1:]], r + 1
    return r
def det(s):                        # second road for three arrows: the determinant
    (p, q, r), (u, v, w), (x, y, z) = (V[t] for t in s)
    return p * (v * z - w * y) - q * (u * z - w * x) + r * (u * y - v * x)
def climb(order, stop=False):      # Zorn's move: add the next arrow that keeps the set independent
    s = ""
    for x in order:
        if rank(s + x) == len(s) + 1: s += x
        elif stop: break
    return "".join(sorted(s))
def perms(s): return [s] if len(s) < 2 else [x + p for x in s for p in perms(s.replace(x, ""))]
ALL = ["".join(x for i, x in enumerate("abcd") if m >> i & 1) for m in range(16)]
IND = [s for s in ALL if rank(s) == len(s)]
MAX, CEIL = sorted(s for s in IND if not any(set(s) < set(t) for t in IND)), "".join(sorted(set("a") | set("ab") | set("abd")))
LAND, TOP = {m: sum(climb(o) == m for o in perms("abcd")) for m in MAX}, sum(all(set(t) <= set(s) for t in IND) for s in IND)
print(f"independent sets among the 16: {len(IND)}; by size 0 to 4: {[sum(len(s) == k for s in IND) for k in range(5)]}\nmaximal, by checking every bigger set: {', '.join(MAX)}\ntriples with nonzero determinant: {', '.join(s for s in ALL if len(s) == 3 and det(s))}; abc gives {det('abc')}")
print(f"c - a - b = {tuple(V['c'][i] - V['a'][i] - V['b'][i] for i in range(3))}; rank of abcd: {rank('abcd')} of 4\nchain a, ab, abd: ceiling {CEIL}, independent {'yes' if rank(CEIL) == 3 else 'no'}, maximal {'yes' if CEIL in MAX else 'no'}")
print(f"climb in the order a, b, c, d: {climb('abcd')}; stopping at the first refusal: {climb('abcd', True)}\n24 line-ups land on: {', '.join(f'{m} {n}' for m, n in LAND.items())}; sets above all others: {TOP}")
assert len(IND) == 14 and MAX == ["abd", "acd", "bcd"] and rank("abcd") == 3 and TOP == 0 and rank("bb") == 1   # bb repeats an arrow
assert MAX == [s for s in ALL if len(s) == 3 and det(s) != 0] and det("abc") == 0 and climb("abcd") == CEIL == "abd"
assert set(LAND.values()) == {8} and sum(LAND.values()) == 24 and climb("abcd", True) == "ab"
print("ALL CHECKS PASS")
