# Schur's lemma and character orthogonality -- the check behind the card.  Nothing
# is imported.  The tile's 8 moves are built from the quarter turn R and the flip
# F as 2 by 2 matrices; each move also shuffles the 4 corners, a 4 by 4 matrix.
def mul(a, b):
    return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(len(b)))
                       for j in range(len(b[0]))) for i in range(len(a)))

def tr(m):
    return sum(m[i][i] for i in range(len(m)))
I2, R, F = ((1, 0), (0, 1)), ((0, -1), (1, 0)), ((1, 0), (0, -1))
G = [I2]
for g in G:                                   # close up under R and F
    G += [h for h in (mul(R, g), mul(F, g)) if h not in G]
inv = {g: next(h for h in G if mul(g, h) == I2) for g in G}
CORNERS = [(-1, 1), (1, 1), (1, -1), (-1, -1)]  # clockwise from top left
act = lambda g, p: (g[0][0] * p[0] + g[0][1] * p[1], g[1][0] * p[0] + g[1][1] * p[1])
corner = lambda g: tuple(tuple(int(act(g, CORNERS[j]) == CORNERS[i]) for j in range(4)) for i in range(4))
det = lambda g: g[0][0] * g[1][1] - g[0][1] * g[1][0]
def diag_sign(g):                             # how g acts on (1, -1, 1, -1)
    s = [1, -1, 1, -1]
    v = [sum(c * x for c, x in zip(row, s)) for row in corner(g)]
    assert v in (s, [-x for x in s])
    return v[0]
name = lambda g: 0 if g == I2 else 1 if tr(g) == -2 else 2 if det(g) == 1 else 3 if g[0][0] == 0 else 4
classes = sorted({frozenset(mul(mul(h, g), inv[h]) for h in G) for g in G}, key=lambda c: name(min(c)))
assert all({name(g) for g in c} == {k} for k, c in enumerate(classes))   # conjugation agrees with names
size, rep = [len(c) for c in classes], [min(c) for c in classes]
chars = {"trivial": lambda g: 1, "flip sign": det, "diagonal sign": diag_sign,
         "edge sign": lambda g: det(g) * diag_sign(g), "floor": tr}
by_classes = lambda a, b: sum(n * a(g) * b(g) for n, g in zip(size, rep))   # 8 x inner product
by_moves = lambda a, b: sum(a(g) * b(inv[g]) for g in G)                     # every move, b at the undo
chi = lambda g: tr(corner(g))
print(f"{len(G)} moves; classes by conjugation, sizes {size}")
print(f"corner character, trace of each shuffle: {[chi(g) for g in rep]}")
for k, (n, a) in enumerate(chars.items()):
    row = [by_classes(a, b) for b in chars.values()]
    assert row == [by_moves(a, b) for b in chars.values()] == [8 * (j == k) for j in range(5)]   # two roads; 8 x identity
    print(f"{n:13} {[a(g) for g in rep]}  8 x inner products: {row}")
m = [by_classes(chi, b) // 8 for b in chars.values()]
assert [by_moves(chi, b) for b in chars.values()] == [8 * x for x in m]
print(f"corner against each, by classes and by moves: {[by_classes(chi, b) for b in chars.values()]} / 8 = {m}")
dims = sum(x * a(I2) for x, a in zip(m, chars.values()))
print(f"<corner, corner> = {by_classes(chi, chi)}/8 = {by_classes(chi, chi) // 8}; dimensions {dims}")
T, S = ((3, 1), (4, 1)), ((5, 7),)
avg = [[sum(mul(mul(g, T), inv[g])[i][j] for g in G) // 8 for j in range(2)] for i in range(2)]
print(f"Schur average, floor to floor, of {[list(r) for r in T]}: {avg}, trace {tr(T)}/2 = {tr(T) // 2}")
avg_s = [sum(mul(S, inv[g])[0][j] for g in G) for j in range(2)]          # 8 x the average, floor to trivial
print(f"Schur average, floor to trivial, of {list(S[0])}: {[v // 8 for v in avg_s]}")
grid = [((a, b), (c, d)) for a in range(-2, 3) for b in range(-2, 3) for c in range(-2, 3) for d in range(-2, 3)]
comm = [t for t in grid if all(mul(t, g) == mul(g, t) for g in G)]
print(f"of {len(grid)} small matrices, {len(comm)} commute with all 8 floor moves: {[t[0][0] for t in comm]} times I")
print(f"mistake 1, class sizes dropped: {sum(chi(g) for g in rep)} / 8 = {sum(chi(g) for g in rep) / 8}")
print(f"mistake 2, divided by 5 classes: 8 / 5 = {by_classes(chi, chars['trivial']) / 5}")
pair = lambda g: 1 + tr(g)                     # trivial and floor together, not irreducible
print(f"mistake 3, against trivial + floor {[pair(g) for g in rep]}: {by_classes(chi, pair) // 8}")
assert size == [1, 1, 2, 2, 2] and m == [1, 0, 1, 0, 1] and dims == 4            # corner = trivial + diagonal sign + floor
assert by_classes(chi, chi) == 8 * sum(x * x for x in m)                         # <chi, chi> = sum of squares
assert avg == [[2, 0], [0, 2]] and avg_s == [0, 0] and [t[0][0] for t in comm] == [-2, -1, 0, 1, 2]  # Schur: trace / 2, or 0
assert all(t[0][1] == t[1][0] == 0 and t[0][0] == t[1][1] for t in comm)        # only multiples of I commute
print("ALL CHECKS PASS")
