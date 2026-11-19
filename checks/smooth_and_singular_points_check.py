# Smooth and singular points: the Jacobian test on the cone x^2 + y^2 = z^2.
# Standard library only. A polynomial is a dict {(a, b, c): coefficient} for
# coefficient * x^a y^b z^c, with whole-number coefficients, so all is exact.
# Road 1: partial derivatives and the rank of the Jacobian matrix.
# Road 2: put the line P + t v into f and read the lowest power of t; no derivatives.
# Road 3: count every point over F_p and test each one.
from fractions import Fraction as Fr

def P(*terms): return {(a, b, c): k for k, a, b, c in terms}
def mul(f, g):
    h = {}
    for e, a in f.items():
        for k, b in g.items():
            m = (e[0] + k[0], e[1] + k[1], e[2] + k[2]); h[m] = h.get(m, 0) + a * b
    return {m: c for m, c in h.items() if c}
def sub(f, g):
    h = dict(f)
    for e, c in g.items(): h[e] = h.get(e, 0) - c
    return {m: c for m, c in h.items() if c}
def d(f, i):
    h = {}
    for e, c in f.items():
        if e[i]: m = list(e); m[i] -= 1; h[tuple(m)] = c * e[i]
    return h
def ev(f, p, q=0):
    s = sum(c * p[0] ** e[0] * p[1] ** e[1] * p[2] ** e[2] for e, c in f.items())
    return s % q if q else s
def show(f):
    out = ""
    for e in sorted(f, reverse=True):
        c = f[e]; mono = "".join(v + ("^" + str(k) if k > 1 else "") for v, k in zip("xyz", e) if k)
        body = (str(abs(c)) if abs(c) != 1 or not mono else "") + mono
        out += (("-" if c < 0 else "") if not out else (" - " if c < 0 else " + ")) + body
    return out or "0"
def on_line(f, p, v):  # coefficients of f(p + t v), a polynomial in t
    tot = [0] * 5
    for e, c in f.items():
        poly = [c]
        for i in range(3):
            for _ in range(e[i]):
                poly = [(poly[k] if k < len(poly) else 0) * p[i] + (poly[k - 1] * v[i] if k else 0) for k in range(len(poly) + 1)]
        for k, a in enumerate(poly): tot[k] += a
    return tot
def order(f, p, v):
    t = on_line(f, p, v); return next((k for k, a in enumerate(t) if a), None)
def rank(rows, q=0):
    rows = [[a % q if q else a for a in r] for r in rows]
    if all(a == 0 for r in rows for a in r): return 0
    if len(rows) == 1: return 1
    (a, b, c), (u, v, w) = rows
    m = [a * v - b * u, a * w - c * u, b * w - c * v]
    return 2 if any(x % q if q else x for x in m) else 1
def jac(fs, p, q=0): return [[ev(d(f, i), p, q) for i in range(3)] for f in fs]

y, z = P((1, 0, 1, 0)), P((1, 0, 0, 1))
f = P((1, 2, 0, 0), (1, 0, 2, 0), (-1, 0, 0, 2))
print("field: the real numbers, exact whole-number arithmetic; F_p only where named")
print("cone f =", show(f), "| f_x =", show(d(f, 0)), "| f_y =", show(d(f, 1)), "| f_z =", show(d(f, 2)))
Pt, O = (3, 4, 5), (0, 0, 0)
for name, p in [("P", Pt), ("apex", O)]:
    g = jac([f], p)[0]; r = rank([g])
    print(f"{name} {p}: f = {ev(f, p)}; gradient {tuple(g)}; rank {r}; {'smooth' if r == 1 else 'singular'}")
assert ev(f, Pt) == 0 and rank(jac([f], Pt)) == 1 and rank(jac([f], O)) == 0
g = jac([f], Pt)[0]
print(f"tangent plane at P: 3x + 4y - 5z = 0 (gradient / 2); contains the line from the apex through P: {'yes' if sum(a * b for a, b in zip(g, Pt)) == 0 else 'no'}")
zx, zy = Fr(-g[0], g[2]), Fr(-g[1], g[2])
print(f"implicit slopes at P: z_x = {zx}, z_y = {zy}; length of gradient squared {sum(a * a for a in g)}")
assert (zx, zy) == (Fr(3, 5), Fr(4, 5))  # z = sqrt(x^2 + y^2) gives x/z and y/z at (3, 4)
for p, v in [(Pt, (1, 0, 0)), (Pt, (-1, 2, 1)), (O, (1, 0, 0)), (O, (0, 1, 1))]:
    t = on_line(f, p, v)
    tx = " + ".join((str(a) if a != 1 else "") + ("t" if k == 1 else f"t^{k}") for k, a in enumerate(t) if a) or "0"
    print(f"f({p} + t{v}) = {tx} | order", order(f, p, v) or "none: the line lies in the cone")
dirs = [(a, b, c) for a in range(-2, 3) for b in range(-2, 3) for c in range(-2, 3) if (a, b, c) != O]
for name, p in [("P", Pt), ("apex", O)]:
    o = [order(f, p, v) for v in dirs]
    print(f"line test at {name}, {len(dirs)} directions: order 1: {o.count(1)}, order 2: {o.count(2)}, line inside the cone: {o.count(None)}")
B = range(-6, 7)
cone = [(a, b, c) for a in B for b in B for c in B if ev(f, (a, b, c)) == 0]
sj = [p for p in cone if rank(jac([f], p)) == 0]
sl = [p for p in cone if all(order(f, p, v) != 1 for v in dirs)]
same = all(on_line(f, p, v)[1] == sum(a * b for a, b in zip(jac([f], p)[0], v)) for p in cone for v in dirs)
print(f"box [-6, 6]^3: {len(cone)} cone points; singular by Jacobian: {', '.join(map(str, sj))}; by line test: {', '.join(map(str, sl))}")
print(f"t coefficient of f(p + tv) = gradient . v at all {len(cone)} points and {len(dirs)} directions: {'yes' if same else 'no'}")
assert sj == sl == [O] and same
for name, p in [("P", Pt), ("apex", O)]:
    print(f"tangent space T_P V at {name}: dimension 3 - {rank(jac([f], p))} = {3 - rank(jac([f], p))}  (dim V = 2)")
cu = P((1, 0, 0, 2), (-1, 3, 0, 0)); low = {e: c for e, c in cu.items() if sum(e) == 2}   # the surface z^2 = x^3
print(f"cusp z^2 = x^3, f = {show(cu)}: lowest part at the origin {show(low)}, zero set the plane z = 0 in the box; gradient {tuple(jac([cu], O)[0])}, rank {rank(jac([cu], O))}: singular")
assert ev(cu, O) == 0 and rank(jac([cu], O)) == 0 and all((ev(low, p) == 0) == (p[2] == 0) for p in [(a, b, c) for a in B for b in B for c in B])
rul = [(3, 4, 5), (-3, 4, 5), (1, 0, 1)]
print("local ring: x/z at P =", Fr(Pt[0], Pt[2]), "| at the apex along rulings", ", ".join(f"{r}: {Fr(r[0], r[2])}" for r in rul), "-> no single value")
wall, through = sub(z, P((5, 0, 0, 0))), sub(mul(P((4, 0, 0, 0)), z), mul(P((5, 0, 0, 0)), y))
def mins(J): return ", ".join(show(sub(mul(J[0][i], J[1][j]), mul(J[0][j], J[1][i]))) for i, j in [(0, 1), (0, 2), (1, 2)])
J = [[d(h, i) for i in range(3)] for h in (f, through)]
print("slice by the wall z = 5: 2x2 minors:", mins([[d(h, i) for i in range(3)] for h in (f, wall)]), "| integer points", sum(ev(wall, p) == 0 for p in cone), "| ranks:", ", ".join(map(str, sorted({rank(jac([f, wall], p)) for p in cone if ev(wall, p) == 0}))))
pts = [p for p in cone if ev(through, p) == 0]
print("slice by 4z = 5y: Jacobian rows (" + ", ".join(show(e) for e in J[0]) + "), (" + ", ".join(show(e) for e in J[1]) + ")")
print("  2x2 minors:", mins(J), "| integer points:", ", ".join(map(str, pts)))
print("  ranks:", ", ".join(f"{p} {rank(jac([f, through], p))}" for p in pts), "-> singular only at the apex")
assert [p for p in pts if rank(jac([f, through], p)) < 2] == [O] and all(rank(jac([f, wall], p)) == 2 for p in cone if ev(wall, p) == 0)
for q in (7, 13):
    F = [(a, b, c) for a in range(q) for b in range(q) for c in range(q) if ev(f, (a, b, c), q) == 0]
    S = [(a, b, c) for a in range(q) for b in range(q) for c in range(q) if ev(through, (a, b, c), q) == 0 and ev(f, (a, b, c), q) == 0]
    sf = sum(rank(jac([f], p, q), q) == 0 for p in F); ss = sum(rank(jac([f, through], p, q), q) < 2 for p in S)
    print(f"over F_{q}: cone {len(F)} points, {sf} singular; slice 4z = 5y {len(S)} points, {ss} singular")
    assert len(F) == q * q and len(S) == 2 * q - 1 and sf == ss == 1
s3 = P((1, 1, 0, 0), (1, 0, 1, 0), (1, 0, 0, 1))
F2 = [(a, b, c) for a in range(2) for b in range(2) for c in range(2) if ev(f, (a, b, c), 2) == 0]
s2 = sum(rank(jac([f], p, 2), 2) == 0 for p in F2)
print(f"mistake 1, over F_2: f = (x + y + z)^2 there; cone {len(F2)} points, {s2} flagged singular")
assert all(ev(f, p, 2) == ev(mul(s3, s3), p, 2) for p in F2) and s2 == 4
c1 = P((1, 2, 0, 0), (1, 0, 2, 0), (-1, 0, 0, 0)); c2 = mul(c1, c1)
pc = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0)]
print("mistake 2, circle written as (" + show(c1) + ")^2 =", show(c2) + ": flagged", sum(rank(jac([c2], p)) == 0 for p in pc), "of 4; as", show(c1) + ": flagged", sum(rank(jac([c1], p)) == 0 for p in pc), "of 4")
assert sum(rank(jac([c2], p)) == 0 for p in pc) == 4 and sum(rank(jac([c1], p)) == 0 for p in pc) == 0
row = jac([through], O)[0]
print(f"mistake 3, slice apex: row {tuple(row)} is not zero ('smooth'), but rank {rank(jac([f, through], O))} < 2: singular")
h = sub(f, P((1, 0, 0, 0)))
gz = [p for p in [(a, b, c) for a in B for b in B for c in B] if rank(jac([h], p)) == 0]
print(f"mistake 4, hyperboloid {show(h)}: gradient zero only at {', '.join(map(str, gz))}, where h = {ev(h, O)}: no singular point")
assert gz == [O] and ev(h, O) != 0
print("figure, top view: circle radius 5 (wall z = 5); lines x = 3y/4 and x = -3y/4 (plane 4z = 5y); apex (0,0); P (3,4); Q (-3,4)")
print("ALL CHECKS PASS")
