# Linear programs and polyhedra -- the check behind the card.  Only Fraction is
# imported, so every number is exact.  A workshop makes x1 tables and x2 chairs a
# week and maximises profit 19 x1 + 20 x2 pounds, limited by timber, labour and
# finish.  The corners are found by two roads that share no code: crossing the
# picture's boundary lines two at a time, and choosing 3 basic columns of the
# standard form A x = b, x >= 0.  Faces are listed by which limits are tight.
from fractions import Fraction as F
NAME = ["x1", "x2", "s1", "s2", "s3"]                     # tables, chairs, 3 slacks
A = [[4, 2, 1, 0, 0], [3, 1, 0, 1, 0], [1, 2, 0, 0, 1]]   # metres, hours, litres
B, PROFIT = [160, 120, 64], [19, 20]
# picture limit k is g.x <= h, and it is tight exactly when variable k is zero
G = [([-1, 0], 0), ([0, -1], 0)] + [(row[:2], h) for row, h in zip(A, B)]

def fmt(v):                                       # exact: a short decimal, else a fraction
    v, k = F(v), 0
    while (v * 10 ** k).denominator != 1 and k < 4: k += 1
    if (v * 10 ** k).denominator != 1: return f"{v.numerator}/{v.denominator}"
    s = str(abs(v.numerator) * 10 ** k // v.denominator).rjust(k + 1, "0")
    return ("-" if v < 0 else "") + (s[:-k] + "." + s[-k:] if k else s)
def pt(p): return "(" + ", ".join(fmt(v) for v in p) + ")"
def value(p, w=PROFIT): return w[0] * p[0] + w[1] * p[1]
def lhs(g, p): return g[0] * p[0] + g[1] * p[1]
def inside(p, gs=G): return all(lhs(g, p) <= h for g, h in gs)
def crossings(gs):                                # road 1: two boundary lines at a time
    pts = []
    for i in range(5):
        for j in range(i + 1, 5):
            (a, h), (c, k) = gs[i], gs[j]
            det = a[0] * c[1] - a[1] * c[0]
            if det != 0: pts.append((F(h * c[1] - a[1] * k, det), F(a[0] * k - h * c[0], det)))
    return pts
def solve(M, r):                                  # Gaussian elimination, exact
    M, n = [[F(v) for v in row] + [F(x)] for row, x in zip(M, r)], len(M)
    for col in range(n):
        piv = next((i for i in range(col, n) if M[i][col] != 0), None)
        if piv is None: return None
        M[col], M[piv] = M[piv], M[col]
        for i in range(n):
            if i != col:
                f = M[i][col] / M[col][col]
                M[i] = [a - f * b for a, b in zip(M[i], M[col])]
    return [M[i][n] / M[i][i] for i in range(n)]
def basics(b):                                    # road 2: 3 basic columns at a time
    out = []
    for i in range(5):
        for j in range(i + 1, 5):
            for k in range(j + 1, 5):
                x = [F(0)] * 5
                for c, v in zip((i, j, k), solve([[row[c] for c in (i, j, k)] for row in A], b)): x[c] = v
                out.append(((i, j, k), x))
    return out

print(f"maximise {PROFIT[0]} x1 + {PROFIT[1]} x2 pounds; timber {B[0]} m, labour {B[1]} h, finish {B[2]} litres")
print(f"standard form: minimise c.x, c = ({-PROFIT[0]}, {-PROFIT[1]}, 0, 0, 0), x = (x1, x2, s1, s2, s3)")
pts = crossings(G)
corners = sorted({p for p in pts if inside(p)})
print(f"road 1: {len(pts)} line crossings, {len(set(pts))} distinct points, {len(corners)} feasible")
bases = []
for cols, x in basics(B):
    ok = min(x) >= 0
    if ok: bases.append((x[0], x[1]))
    print(f"basis {' '.join(NAME[c] for c in cols)}: x = {pt(x)}  {'corner' if ok else 'infeasible'}")
print(f"road 2: 10 bases, {len(bases)} feasible, {len(set(bases))} distinct corners")
print("corners, both roads:", " ".join(pt(p) for p in corners))
def tight(p): return {k for k, (g, h) in enumerate(G) if lhs(g, p) == h}
faces, hit = {}, 0
for mask in range(32):                            # every set of limits made tight
    vs = tuple(v for v in corners if all(k in tight(v) for k in range(5) if mask >> k & 1))
    hit += bool(vs)
    if vs: faces[vs] = sorted(set.intersection(*[tight(v) for v in vs]))
print(f"faces: 32 sets of walls made tight, {len(faces)} distinct non-empty faces")
for vs in sorted(faces, key=lambda f: (len(f), f)):
    zero = " ".join(NAME[k] for k in faces[vs]) or "none"
    print(f"face, dim {min(len(vs) - 1, 2)}: {' '.join(pt(v) for v in vs):<22} zero: {zero}")
lab = tuple(v for v in corners if 3 in tight(v))
red = [F(3, 4) * a + F(1, 2) * b for a, b in zip(G[2][0], G[1][0])]   # 3/4 timber + 1/2 chairs
print(f"labour tight only at {' '.join(pt(v) for v in lab)}; 3/4 timber + 1/2 (x2 >= 0): "
      f"{fmt(red[0])} x1 + {fmt(red[1])} x2 <= {fmt(F(3, 4) * B[0])}")
best = max(corners, key=value)
y = [3, 0, 7]                                     # prices on timber, labour, finish
yA = [sum(y[r] * A[r][c] for r in range(3)) for c in range(5)]
bound = sum(yr * br for yr, br in zip(y, B))
grid = max(value((a, b)) for a in range(65) for b in range(81) if inside((a, b)))
print("profit at corners:", ", ".join(f"{pt(v)} {fmt(value(v))}" for v in corners))
print(f"best: {pt(best)}, {fmt(value(best))} pounds; standard-form p* = {fmt(-value(best))}")
print(f"certificate y = (3, 0, 7): y.A = {pt(yA)}, y.b = {bound}; whole-number grid best {grid}")
tie = [v for v in corners if value(v, [19, 38]) == max(value(u, [19, 38]) for u in corners)]
print(f"chairs at 38: best set {' to '.join(pt(v) for v in tie)}, {fmt(value(tie[0], [19, 38]))} each: the finish edge")
flip = G[:2] + [([-4, -2], -160)] + G[3:]         # mistake 1: surplus on timber
fc = [p for p in crossings(flip) if inside(p, flip)]
fb = max(fc, key=value)
edges = [k for k in range(5) if sum(k in tight(v) for v in corners) > 1]   # mistake 2: walls as edges
eq = solve([r[:2] for r in A[:2]], B[:2])         # mistake 4: limits as equations
print(f"mistake, timber slack signed as surplus: {pt(fb)}, {fmt(value(fb))}, uses {fmt(lhs([4, 2], fb))} m")
print(f"mistake, one edge per wall: {len(G)} claimed, {len(edges)} walls tight along an edge, labour at {len(lab)} corner")
print(f"mistake, every set of walls counted as a face: 32, but {32 - hit} are empty and {hit} give {len(faces)} faces")
print(f"mistake, no slacks: timber and labour force {pt(eq)}, finish {fmt(lhs([1, 2], eq))} not 64")
ends = [f"{nm} {pt((F(h - g[1] * top, g[0]), top))}-{pt((F(h, g[0]), 0))}"   # where each line
        for nm, (g, h), top in zip(["timber", "labour", "finish"], G[2:], [45, 45, 32])]  # leaves the box
print(f"figure, corners {' '.join(pt(v) for v in corners)}; {'; '.join(ends)}; "
      f"928 line {pt((16, F(928 - 19 * 16, 20)))}-{pt((48, F(928 - 19 * 48, 20)))}")
for h in (130, 110):                              # Try changing: move the labour wall
    Gt = G[:3] + [(G[3][0], h)] + G[4:]
    ct = sorted({p for p in crossings(Gt) if inside(p, Gt)})
    on = lambda k: " ".join(pt(v) for v in ct if lhs(Gt[k][0], v) == Gt[k][1]) or "none"
    bt = max(ct, key=value)
    print(f"try labour {h} h: {sum(min(x) >= 0 for _, x in basics([160, h, 64]))} feasible bases, {len(ct)} corners; "
          f"labour tight at {on(3)}; timber at {on(2)}; best {pt(bt)}, {fmt(value(bt))}")
dear = max(corners, key=lambda v: value(v, [19, 40]))
print(f"try chairs at 40: best {pt(dear)}, {fmt(value(dear, [19, 40]))}; prices (3, 0, 7) value a chair at {yA[1]}")
assert corners == sorted(set(bases)) and len(corners) == 4      # two roads, one shape
assert yA[:2] == PROFIT and min(yA[2:]) >= 0 and bound == value(best) == grid == 928
assert red == G[3][0] and F(3, 4) * B[0] == B[1] and lab == ((40, 0),)   # labour is redundant
assert faces[tuple(tie)] == [4] and len(faces) == 9 and hit == 13 and len(edges) == 4 and fb == (F(176, 5), F(72, 5))
print("ALL CHECKS PASS")
