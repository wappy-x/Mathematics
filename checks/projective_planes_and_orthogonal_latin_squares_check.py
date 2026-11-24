# Finite planes and orthogonal Latin squares -- the check behind the card.  Only itertools is imported, to loop over
# tuples.  Order 3 squares, the plane of order 3 built two ways, the Fano plane, and a full search for mates up to order 6.
from itertools import combinations, permutations, product
def square(m, n): return [[(i + m * j) % n for j in range(n)] for i in range(n)]
def latin(L): return all(len(set(r)) == len(L) for r in L) and all(len(set(c)) == len(L) for c in zip(*L))
def pairs(A, B): return len({(a, b) for ra, rb in zip(A, B) for a, b in zip(ra, rb)})
def yn(claim): return "yes" if claim else "no"
def plane_ok(pts, lines):                    # two points share one line, two lines share one point
    return all(sum(a in l and b in l for l in lines) == 1 for a, b in combinations(pts, 2)) and all(len(l & m) == 1 for l, m in combinations(lines, 2))
def from_squares(sqs, n):                    # road one: cells, plus a point at infinity per class
    keys = [lambda i, j: i, lambda i, j: j] + [lambda i, j, S=S: S[i][j] for S in sqs]
    lines = [frozenset([(i, j) for i in range(n) for j in range(n) if f(i, j) == s] + [(n, c)])
             for c, f in enumerate(keys) for s in range(n)] + [frozenset((n, c) for c in range(n + 1))]
    return [(i, j) for i in range(n) for j in range(n)] + [(n, c) for c in range(n + 1)], lines
def gf_plane(q):                             # road two: triples over GF(q), first nonzero entry 1
    pts = [t for t in product(range(q), repeat=3) if any(t) and t[[x > 0 for x in t].index(True)] == 1]
    return pts, [frozenset(p for p in pts if sum(a * b for a, b in zip(p, l)) % q == 0) for l in pts]
def reduced(n):                              # every Latin square with first row and column 0..n-1
    L, out = [[i if j == 0 else j if i == 0 else -1 for j in range(n)] for i in range(n)], []
    def fill(c):
        if c == n * n: return out.append([r[:] for r in L])
        i, j = divmod(c, n)
        if L[i][j] >= 0: return fill(c + 1)
        for s in set(range(n)) - set(L[i]) - {L[k][j] for k in range(n)}:
            L[i][j] = s; fill(c + 1); L[i][j] = -1
    fill(0); return out
def has_mate(L):                             # a mate exists exactly when n transversals tile the grid
    n, T = len(L), []
    def tr(i, cols, syms):
        if i == n: return T.append(cols)
        for j in set(range(n)) - set(cols):
            if L[i][j] not in syms: tr(i + 1, cols + (j,), syms | {L[i][j]})
    tr(0, (), set()); masks = [sum(1 << (i * n + t[i]) for i in range(n)) for t in T]
    def tile(k, used): return k == n or any(t[0] == k and not m & used and tile(k + 1, used | m) for t, m in zip(T, masks))
    return tile(0, 0)
L1, L2 = square(1, 3), square(2, 3); print("L1 = i + j mod 3:", L1, "  L2 = i + 2j mod 3:", L2)
print(f"both Latin: {yn(latin(L1) and latin(L2))}; ordered pairs seen when laid on top: {pairs(L1, L2)} of 9")
print("laid on top, row by row:", " | ".join(" ".join(f"{a}{b}" for a, b in zip(ra, rb)) for ra, rb in zip(L1, L2)))
sq3 = [L for L in ([list(g[0:3]), list(g[3:6]), list(g[6:9])] for g in product(range(3), repeat=9)) if latin(L)]
best = max(k for k in range(1, 5) if any(all(pairs(A, B) == 9 for A, B in combinations(c, 2)) for c in combinations(sq3, k)))
print(f"Latin squares of order 3: {len(sq3)}; largest mutually orthogonal set: {best} = 3 - 1")
PA, LA = from_squares([L1, L2], 3); PB, LB = gf_plane(3); ns = (2, 3, 4, 5, 7)
print(f"n = {ns}: points n^2 + n + 1 = {[n * n + n + 1 for n in ns]}, points per line n + 1 = {[n + 1 for n in ns]}")
for name, P, Ls in [("from the two squares", PA, LA), ("from triples over GF(3)", PB, LB)]:
    print(f"plane {name}: {len(P)} points, {len(Ls)} lines, points per line {min(map(len, Ls))} to {max(map(len, Ls))}, a plane: {yn(plane_ok(P, Ls))}")
inf = {(3, c) for c in range(4)}; aff3 = [l - inf for l in LA if not l <= inf]
print(f"minus its line at infinity: {len(set().union(*aff3))} points, {len(aff3)} lines of {len(aff3[0])}, in {len({l & inf for l in LA if not l <= inf})} parallel classes")
fano, (P2, G2) = {frozenset(l) for l in [(1, 2, 4), (2, 3, 5), (3, 4, 6), (4, 5, 7), (5, 6, 1), (6, 7, 2), (7, 1, 3)]}, gf_plane(2)
aff = [l - {1, 2, 4} for l in fano if l != {1, 2, 4}]; same = any({frozenset(p[P2.index(x)] for x in l) for l in G2} == fano for p in permutations(range(1, 8)))
print(f"Fano plane: {len(set().union(*fano))} points, {len(fano)} lines of 3, a plane: {yn(plane_ok(range(1, 8), fano))}; the GF(2) plane, relabelled: {yn(same)}")
print(f"Fano minus the line 1 2 4: {len(set().union(*aff))} points, {len(aff)} lines of {len(aff[0])}")
mates = {n: (len(R), sum(map(has_mate, R))) for n in range(2, 7) for R in [reduced(n)]}
for n in mates: print(f"order {n}: reduced Latin squares {mates[n][0]}, with an orthogonal mate {mates[n][1]}")
print(f"mistake 1, the 4-hour clock for GF(4): i + 2j mod 4 row 0 = {square(2, 4)[0]}, Latin: {yn(latin(square(2, 4)))}")
print(f"mistake 2, second square 2(i + j) mod 3: ordered pairs {pairs(L1, [[2 * x % 3 for x in r] for r in L1])} of 9")
print(f"mistake 3, i + j and i + 5j mod 6: ordered pairs {pairs(square(1, 6), square(5, 6))} of 36")
assert pairs(L1, L2) == 9 and best == 2 and len(sq3) == 12
assert plane_ok(PA, LA) and plane_ok(PB, LB) and len(PA) == len(PB) == 3 * 3 + 3 + 1
assert same and mates[6][1] == 0 and mates[5][1] > 0 and mates[2][1] == 0
print("ALL CHECKS PASS")
