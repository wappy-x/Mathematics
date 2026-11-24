# Representations and Maschke's theorem -- the check behind the card.  Nothing is imported.
# The tile's eight moves (sign, shift) send corner i to sign*i + shift, wrapped at 4, each a
# 4 by 4 shuffle matrix.  Two roads split corner heights: dot products, and Maschke's average.
MOVES = [(s, k) for s in (1, -1) for k in range(4)]
ONES, TWIST, U, W = [1, 1, 1, 1], [1, -1, 1, -1], [1, 0, -1, 0], [0, 1, 0, -1]
def name(a): return f"r{a[1]}" + ("f" if a[0] == -1 else "")
def rho(a): return [[int((a[0] * j + a[1]) % 4 == i) for j in range(4)] for i in range(4)]
def mul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]
def act(A, x): return [r[0] for r in mul(A, [[v] for v in x])]
def tr(A): return sum(A[i][i] for i in range(len(A)))
def par(v, w): return all(v[i] * w[j] == v[j] * w[i] for i in range(4) for j in range(4))
def row(t, vals): print(f"{t:<25}" + "".join(f"{v:>5}" for v in vals))
def yn(claim): return "yes" if claim else "no"
def average(col):           # 8 x Maschke's average of the skewed projection whose column 0
    Cs = [mul(mul(g, [[c, 0, 0, 0] for c in col]), [list(r) for r in zip(*g)]) for g in R]
    return [[sum(C[i][j] for C in Cs) for j in range(4)] for i in range(4)]   # is col
def plane(g): return [list(r) for r in zip(act(g, U), act(g, W))][:2]   # the move in the basis u = e0 - e2, w = e1 - e3
def keeps(A, c): return (A[0][0] + A[0][1] * c) * c == A[1][0] + A[1][1] * c   # A sends (1, c) along (1, c)
def split(x):               # road one: dot products with the fixed patterns
    return sum(x) // 4, (x[0] - x[1] + x[2] - x[3]) // 4, (x[0] - x[2]) // 2, (x[1] - x[3]) // 2
R = [rho(a) for a in MOVES]
M, T = average(ONES), average(TWIST)
signs, ptr = [act(g, TWIST)[0] for g in R], [tr(plane(g)) for g in R]
row("move", [name(a) for a in MOVES])
row("corners 0 1 2 3 go to", ["".join(str((a[0] * i + a[1]) % 4) for i in range(4)) for a in MOVES])
row("trace: corners left put", [tr(g) for g in R])
row("twist piece acts as", signs)
row("trace on the plane", ptr)
hom = all(mul(rho(a), rho(b)) == rho((a[0] * b[0], (a[0] * b[1] + a[1]) % 4)) for a in MOVES for b in MOVES)
print(f"rho(a * b) = rho(a) rho(b) for all 64 pairs: {yn(hom)}")
print(f"on the plane, basis u = e0 - e2, w = e1 - e3: r1 -> {plane(R[1])}, r0f -> {plane(R[4])}")
grid = [[a, b, c, d] for a in (-1, 0, 1) for b in (-1, 0, 1) for c in (-1, 0, 1) for d in (-1, 0, 1)]
lines = [v for v in grid if any(v) and [e for e in v if e][0] == 1 and all(par(act(g, v), v) for g in R)]
print(f"lines kept by all 8 moves, entries -1, 0, 1 searched: {lines}")
roots = [complex(p, q) for p in range(-2, 3) for q in range(-2, 3) if keeps(plane(R[1]), complex(p, q))]
flip = [c for c in roots if keeps(plane(R[4]), c)]  # of those, the lines the flip r0f keeps too
print(f"plane lines (1, c) the quarter turn keeps: c = {', '.join('-i' if c.imag < 0 else 'i' for c in roots)}; the flip keeps {len(flip)}")
ok = all(mul(A, g) == mul(g, A) for A in (M, T) for g in R) and all(mul(A, A) == [[8 * v for v in r] for r in A] for A in (M, T))
print(f"8 x averaged projection, height: {M}")
print(f"8 x averaged projection, twist: {T}; both commute with all 8 moves and are projections: {yn(ok)}")
agree, X = [], [6, 2, 4, 0]
for label, x in (("heights", X), ("after r1, heights", act(R[1], X))):
    h, t, a, b = split(x)
    m, s = act(M, x), act(T, x)                                     # road two, times 8
    pieces = [[h] * 4, [t * e for e in TWIST], [a, b, -a, -b]]
    agree.append([8 * v for v in sum(pieces, [])] == m + s + [8 * v - p - q for v, p, q in zip(x, m, s)])
    print(f"{label} {x} mm: height {h}, twist {t}, tilt ({a}, {b}); road two agrees: {yn(agree[-1])}")
    sq, dots = [sum(v * v for v in p) for p in pieces], [sum(v * w for v, w in zip(pieces[i], pieces[j])) for i, j in ((0, 1), (0, 2), (1, 2))]
    print(f"  pieces {' + '.join(str(p) for p in pieces)}; dot products {', '.join(map(str, dots))}; squared sizes {' + '.join(map(str, sq))} = {sum(sq)}")
    assert dots == [0, 0, 0] and sum(sq) == sum(v * v for v in x)     # at right angles, so the squares add
print(f"mistake 1, complement x0 = 0 without averaging: kept by {sum(par(g[0], [1, 0, 0, 0]) for g in R)} of 8 moves")
print(f"mistake 2, sum without the 1/8: trace {tr(M)}, square = 8 x itself: {yn(mul(M, M) == [[8 * v for v in r] for r in M])}")
print(f"mistake 3, splitting the plane along u = e0 - e2: kept by {sum(par(act(g, U), U) for g in R)} of 8 moves")
two = [(p, q) for p in (0, 1) for q in (0, 1) if p or q]           # the 3 lines mod 2; the swap
kept = [v for v in two if (v[1], v[0]) == v]                        # keeps one, not its complements
print(f"mistake 4, swap on two coordinates mod 2: kept line {kept[0]}, its complements kept: {len(kept) - 1} of {len(two) - 1}")
assert all(agree) and hom and ok and lines == [TWIST, ONES]     # two roads; brute force finds two lines
assert [tr(g) for g in R] == [1 + s + p for s, p in zip(signs, ptr)]                       # 4 = 1 + 1 + 2
assert plane(R[1]) == [[0, -1], [1, 0]] and plane(R[4]) == [[1, 0], [0, -1]] and roots == [-1j, 1j] and not flip
print("ALL CHECKS PASS")
