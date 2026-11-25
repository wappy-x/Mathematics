# Toric varieties -- the check behind the card.  Nothing is imported.
# The lattice N = Z^2 holds the cones; the lattice M = Z^2 holds exponents: m = (a, b) is x^a y^b.
def dot(m, u): return m[0] * u[0] + m[1] * u[1]
def det(u, v): return u[0] * v[1] - u[1] * v[0]
def gcd(a, b): return gcd(b, a % b) if b else abs(a)
def box(r): return [(a, b) for a in range(-r, r + 1) for b in range(-r, r + 1)]
def in_dual(m, cone): return all(dot(m, u) >= 0 for u in cone)
def hilbert(cone, r=6):                         # minimal generators of (dual cone) cap M, brute force
    pts = [m for m in box(r) if m != (0, 0) and in_dual(m, cone)]; s = set(pts)
    return sorted((m for m in pts if not any((m[0] - p[0], m[1] - p[1]) in s for p in pts)), key=lambda m: (m[1], m[0]))
def normals(c):                                 # inward normals of a 2-dimensional cone: its dual's rays
    out = []
    for u, v in [(c[0], c[1]), (c[1], c[0])]:
        n = (-u[1], u[0]); out.append(n if dot(n, v) > 0 else (-n[0], -n[1]))
    return out
def mono(m):                                    # an exponent pair written as a monomial
    def part(e, v): return "" if e <= 0 else v if e == 1 else f"{v}^{e}"
    top, bot = part(m[0], "x") + part(m[1], "y"), part(-m[0], "x") + part(-m[1], "y")
    return (top or "1") + (f"/{bot}" if bot else "")
def ring(gens): return "k[" + ", ".join(mono(m) for m in gens) + "]"
print("== the fan of P^2: three rays, three 2-dimensional cones ==")
U = [(-1, -1), (1, 0), (0, 1)]                  # ray U[i] <-> the line x_i = 0 in P^2
CONES = [(U[1], U[2]), (U[2], U[0]), (U[0], U[1])]   # cone i leaves out U[i] <-> chart x_i != 0
E = [(0, 0), (1, 0), (0, 1)]                    # x = x1/x0, y = x2/x0: x_j/x_i has exponent E[j] - E[i]
for i, c in enumerate(CONES):
    gens = hilbert(c)
    chart = sorted(((E[j][0] - E[i][0], E[j][1] - E[i][1]) for j in range(3) if j != i), key=lambda m: (m[1], m[0]))
    assert gens == chart and abs(det(*c)) == 1 and len(gens) == 2
    print(f"cone {i} on {c[0]}, {c[1]}: det {det(*c)}, dual rays {normals(c)} -> {ring(gens)} = chart x{i} != 0")
print("== gluing: two charts agree on the ray they share ==")
def local(c, m, r):                             # exponents of k[dual of c][1/x^m] inside box(r)
    s = set(box(r)); return {(p[0] - k * m[0], p[1] - k * m[1]) for p in box(2 * r) if in_dual(p, c)
                             for k in range(3 * r) if (p[0] - k * m[0], p[1] - k * m[1]) in s}
for i, j in [(0, 1), (1, 2), (2, 0)]:
    t = next(u for u in CONES[i] if u in CONES[j])
    mi, mj = [next(n for n in normals(CONES[k]) if dot(n, t) == 0) for k in (i, j)]
    A, B, T = local(CONES[i], mi, 3), local(CONES[j], mj, 3), {m for m in box(3) if dot(m, t) >= 0}
    assert A == B == T and len(T) == 28
    print(f"charts {i} and {j} share ray {t}: {ring(hilbert(CONES[i]))} with {mono(mi)} inverted = {ring(hilbert(CONES[j]))} with {mono(mj)} inverted, {len(T)} = {len(T)} exponents in the box")
q = 7
cells = [1, 3, 3]                               # cones of dimension 0, 1, 2 <-> orbits of dimension 2, 1, 0
orbit = sum(n * (q - 1) ** (2 - k) for k, n in enumerate(cells))
brute = sum(1 for a in range(q) for b in range(q) for c in range(q)
            if (a, b, c) != (0, 0, 0) and [v for v in (a, b, c) if v][0] == 1)
assert orbit == brute == q * q + q + 1
print(f"points of P^2 over F_{q}: orbits (q-1)^2 + 3(q-1) + 3 = {(q - 1) ** 2} + {3 * (q - 1)} + 3 = {orbit}; brute force {brute}; q^2 + q + 1 = {q * q + q + 1}")
print("== sections of O(d) = lattice points of the triangle (0, 0), (d, 0), (0, d) ==")
for d in range(1, 7):
    A = {U[0]: d, U[1]: 0, U[2]: 0}             # D = d * (line at infinity x0 = 0)
    poly = sum(1 for m in box(d) if all(dot(m, u) >= -A[u] for u in U))
    verts = []
    for c in CONES:                             # m_sigma: <m, u> = -a_u on both rays (Cramer)
        D, r0, r1 = det(*c), -A[c[0]], -A[c[1]]
        verts.append(((r0 * c[1][1] - r1 * c[0][1]) // D, (c[0][0] * r1 - c[1][0] * r0) // D))
    charts = sum(1 for m in box(d) if all(in_dual((m[0] - v[0], m[1] - v[1]), c) for v, c in zip(verts, CONES)))
    forms = sum(1 for e0 in range(d + 1) for e1 in range(d + 1) if e0 + e1 <= d)
    area2 = abs(det((verts[1][0] - verts[0][0], verts[1][1] - verts[0][1]), (verts[2][0] - verts[0][0], verts[2][1] - verts[0][1])))
    bnd = sum(gcd(verts[k][0] - verts[k - 1][0], verts[k][1] - verts[k - 1][1]) for k in range(3))
    inner = (area2 - bnd + 2) // 2              # Pick: area = I + B/2 - 1
    if d == 3: area3, inner3 = area2, inner
    assert poly == charts == forms == inner + bnd == (d + 1) * (d + 2) // 2
    print(f"d = {d}: vertices {sorted(verts)}; inequalities {poly}, charts {charts}, forms {forms}, Pick {inner} + {bnd} = {inner + bnd}; (d+1)(d+2)/2 = {(d + 1) * (d + 2) // 2}")
d = 3
pts = [(a, b) for b in range(d + 1) for a in range(d + 1 - b)]
def form(e): return "".join(f"x{k}" + (f"^{n}" if n > 1 else "") for k, n in enumerate(e) if n)
print("d = 3 sections:", ", ".join(form((d - a - b, a, b)) for a, b in pts))
print(f"{len(pts)} coefficients in a cubic, so {len(pts) - 1} general points fix one up to scale")
print("== the cone on (0, 1) and (2, -1): index 2 ==")
C = ((0, 1), (2, -1)); D = det(*C); sg = 1 if D > 0 else -1
par = sorted(m for m in box(3) if 0 <= sg * det(m, C[1]) < abs(D) and 0 <= sg * det(C[0], m) < abs(D))
inv = [gcd(gcd(C[0][0], C[0][1]), gcd(C[1][0], C[1][1])), abs(D) // gcd(gcd(C[0][0], C[0][1]), gcd(C[1][0], C[1][1]))]
assert abs(D) == len(par) == 2 and par == [(0, 0), (1, 0)] and inv == [1, 2]
print(f"det {D}: index {abs(D)}; lattice points in the half-open parallelogram {par}; Smith form diag{tuple(inv)}: N / sublattice = Z/{inv[1]}")
hb = hilbert(C); u, v, w = hb
assert normals(C) == [(1, 0), (1, 2)] and hb == [(1, 0), (1, 1), (1, 2)] and (u[0] + w[0], u[1] + w[1]) == (2 * v[0], 2 * v[1])
print(f"dual rays {normals(C)}; generators {hb} -> u = {mono(u)}, v = {mono(v)}, w = {mono(w)}; u*w = {mono((u[0] + w[0], u[1] + w[1]))} = v^2")
print(f"pairing <{w}, {C[1]}> = {dot(w, C[1])}; x^{w} = {mono(w)}")
lat = [sum(1 for b in range(-20, 21) if in_dual((n, b), C)) for n in range(7)]
std = [sum(1 for i in range(n + 1) for j in range(2) for l in range(n + 1) if i + j + l == n) for n in range(7)]
assert lat == std == [2 * n + 1 for n in range(7)]
print("degree n = 0..6: lattice points", lat, "= monomials u^i v^j w^l with j <= 1", std, "-> ring = k[u, v, w]/(uw - v^2)")
F = [(a, b, c) for a in range(q) for b in range(q) for c in range(q) if (a * c - b * b) % q == 0]
sing = [p for p in F if (p[2] % q, -2 * p[1] % q, p[0] % q) == (0, 0, 0)]
assert len(F) == q * q and (1, 1, 1) in F and sing == [(0, 0, 0)]
print(f"uw = v^2 over F_{q}: {len(F)} points; gradient (w, -2v, u) vanishes only at {sing}; tangent space at the tip: dimension {len(hb)} > 2")
x, y, z = 3, 4, 5
torch = sorted(((c - a) % q, b, (c + a) % q) for a in range(q) for b in range(q) for c in range(q) if (a * a + b * b - c * c) % q == 0)
assert torch == F                               # (x, y, z) -> (z - x, y, z + x) carries the torch cone onto uw = v^2
print(f"torch cone x^2 + y^2 = z^2 at ({x}, {y}, {z}): u = z - x = {z - x}, v = y = {y}, w = z + x = {z + x}; uw = {(z - x) * (z + x)} = v^2 = {y * y}")
print(f"over F_{q} the torch's {len(torch)} points map onto the {len(F)} points of uw = v^2")
W = [(1, 0), (0, 1), (-1, -2)]                  # fan of the weighted projective plane P(1, 1, 2)
wc = [(W[k], W[(k + 1) % 3]) for k in range(3)]; g3 = hilbert(wc[2])
assert [det(*c) for c in wc] == [1, 1, 2] and len(g3) == 3 and (g3[0][0] + g3[2][0], g3[0][1] + g3[2][1]) == (2 * g3[1][0], 2 * g3[1][1])
print(f"P(1, 1, 2): rays {W}, 1*{W[0]} + 2*{W[1]} + 1*{W[2]} = {(W[0][0] + 2 * W[1][0] + W[2][0], W[0][1] + 2 * W[1][1] + W[2][1])}; "
      f"dets {[det(*c) for c in wc]}; third cone -> {ring(g3)}: uw = v^2 again")
print("== what breaks ==")
wrong = hilbert(normals(CONES[1]))             # lattice points of the cone itself, not its dual
assert wrong == [(-1, -1), (0, 1)] and wrong != hilbert(CONES[1])
print(f"cone, not dual, for cone 1: {ring(wrong)}, not {ring(hilbert(CONES[1]))}")
print(f"primitive rays only: gcd {gcd(*C[0])} and {gcd(*C[1])} say smooth, but det {D} and {len(hb)} generators say singular")
print(f"d = 3 by area or interior only: area {area3}/2, interior points {inner3}; true count {len(pts)}")
half = hilbert(((1, 0), (-1, 0), (0, 1)))
assert half == [(0, 1)]
fat = ((2, 0), (0, 1))                          # rays not given by their first lattice points
assert det(*fat) == 2 and hilbert(fat) == hilbert(CONES[0]) == [(1, 0), (0, 1)]
print(f"edge (2, 0) instead of (1, 0): det {det(*fat)}, yet the ring is {ring(hilbert(fat))}, smooth; first lattice points give det {det(*CONES[0])}")
print(f"half-plane, not strongly convex: dual generators {half} -> {ring(half)}, a line: dimension 1, not 2")
print("figure, fan rays (-1, -1) (1, 0) (0, 1); triangle (0, 0) (3, 0) (0, 3), 10 points; cone (0, 1) (2, -1), extra point (1, 0); interior point (1, 1); dual (1, 0) (1, 1) (1, 2)")
print("ALL CHECKS PASS")
