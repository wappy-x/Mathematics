# Cohomology of projective space -- the check behind the card.  Standard library
# only.  Road 1 builds the cell chains of complex P^n and reads off the Betti
# numbers.  Road 2 counts the points of P^2 over F_p by brute force.  Road 3
# multiplies classes by solving real curves exactly.  Road 4 integrates the
# Fubini-Study densities numerically.  Roads 1 to 3 are exact.
import math

def rank(rows, p=0):                       # elimination over Q (p = 0) or over F_p
    m, r = [[x % p if p else x for x in row] for row in rows], 0
    for c in range(len(m[0]) if m else 0):
        piv = next((i for i in range(r, len(m)) if m[i][c]), None)
        if piv is None:
            continue
        m[r], m[piv] = m[piv], m[r]
        for i in range(len(m)):
            if i != r and m[i][c]:
                f, g = m[i][c], m[r][c]
                m[i] = [(g * a - f * b) % p if p else g * a - f * b for a, b in zip(m[i], m[r])]
        r += 1
    return r

def betti(cells, bound, p=0):              # b_k = cells - rank d_k - rank d_(k+1)
    return [cells[k] - rank(bound.get(k, []), p) - rank(bound.get(k + 1, []), p) for k in range(len(cells))]

def complex_pn(n):                         # one cell in each real dimension 0, 2, ..., 2n
    cells = [1 - k % 2 for k in range(2 * n + 1)]
    return cells, {k: [[0] * cells[k] for _ in range(cells[k - 1])] for k in range(1, 2 * n + 1)}

def points(p, n, eq):                      # scale each vector so its last nonzero entry is 1
    seen = {}
    for code in range(1, p ** (n + 1)):
        v = [code // p ** i % p for i in range(n + 1)]
        last = max(i for i in range(n + 1) if v[i])
        w = tuple(x * pow(v[last], p - 2, p) % p for x in v)
        if eq(w) % p == 0:
            seen[w] = last
    return [list(seen.values()).count(k) for k in range(n + 1)]

def det3(m):
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2]
            - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))

def fit(ps, ns):                           # a0 + a1 p + a2 p^2 through three counts, by Cramer
    v = [[1, q, q * q] for q in ps]
    return [det3([[ns[i] if c == j else v[i][c] for c in range(3)] for i in range(3)]) // det3(v)
            for j in range(3)]

def add(*ps):                              # polynomials in one variable, lowest power first
    out = [sum(q[i] for q in ps if i < len(q)) for i in range(max(map(len, ps)))]
    while len(out) > 1 and out[-1] == 0:
        out.pop()
    return out

def mul(a, b):
    return add([sum(a[i] * b[k - i] for i in range(len(a)) if 0 <= k - i < len(b)) for k in range(len(a) + len(b) - 1)])

def ev(q, x): return sum(c * x ** i for i, c in enumerate(q))

def roots(q):                              # whole-number roots with multiplicity: search, then divide
    out = []
    for r in range(-30, 31):
        while len(q) > 1 and ev(q, r) == 0:
            out.append(r)
            q = [sum(q[j] * r ** (j - i - 1) for j in range(i + 1, len(q))) for i in range(len(q) - 1)]
    return out

def show(q, v="x"):                        # leading term first
    s = "".join((" - " if c < 0 else " + ") + ("" if abs(c) == 1 and i else str(abs(c)))
                + (v if i else "") + (f"^{i}" if i > 1 else "") for i, c in reversed(list(enumerate(q))) if c)
    return ("-" if s.startswith(" - ") else "") + s[3:]

def circle(x, y, z): return add(mul(x, x), mul(y, y), mul([-25], mul(z, z)))
def hyperbola(x, y, z): return add(mul(x, y), mul([-12], mul(z, z)))
def beacon(x, y, z): return circle(add(x, mul([-6], z)), y, z)

def fs_curve(phi, n=4000):                 # Fubini-Study density on a curve chart: (1/2) r (u'' + u'/r) dr
    tot, w = 0.0, math.pi / (2 * n)
    for i in range(n):
        r = math.tan((i + 0.5) * w)
        h, u = 1e-4 * (1 + r), lambda s: math.log(phi(s * s))
        d1, d2 = (u(r + h) - u(r - h)) / (2 * h), (u(r + h) - 2 * u(r) + u(r - h)) / (h * h)
        tot += 0.5 * r * (d2 + d1 / r) * (1 + r * r) * w
    return tot

def fs_plane(n=800):                       # h^2 density over the chart C^2: 8 r s / (1 + r^2 + s^2)^3
    w, tot = math.pi / (2 * n), 0.0
    for i in range(n):
        for j in range(n):
            r, s = math.tan((i + 0.5) * w), math.tan((j + 0.5) * w)
            tot += 8 * r * s / (1 + r * r + s * s) ** 3 * (1 + r * r) * (1 + s * s) * w * w
    return tot

X, LINE, TAN = [0, 1], [7, -1], [5]        # the lines x + y = 7z and y = 5z, in the chart z = 1
for n in range(1, 5):
    print(f"P^{n}: Betti numbers in degrees 0 to {2 * n}: {' '.join(map(str, betti(*complex_pn(n))))}")
real = ([1, 1, 1], {1: [[0]], 2: [[2]]})
bq, b2 = betti(*real), betti(*real, p=2)
print(f"real P^2, cells in dimensions 0, 1, 2, boundary 2: over Q {bq}, over F_2 {b2}")
plane, quad = [], []
for p in (2, 3, 5, 7):
    c, q = points(p, 2, lambda w: 0), sum(points(p, 3, lambda w: w[0] * w[3] - w[1] * w[2]))
    plane.append(sum(c)); quad.append(q)
    print(f"p = {p}: P^2 has {sum(c)} points = {c[2]} + {c[1]} + {c[0]} by cell; quadric surface {q}")
    assert c == [1, p, p * p]
a, qa = fit((2, 3, 5), plane[:3]), fit((2, 3, 5), quad[:3])
print(f"fitted from p = 2, 3, 5: P^2 {a[0]} + {a[1]}p + {a[2]}p^2, predicts {ev(a, 7)} at p = 7; quadric {qa[0]} + {qa[1]}p + {qa[2]}p^2")
chi = [d ** 3 - 4 * d * d + 6 * d for d in (1, 2, 4)]
print(f"Euler characteristic d^3 - 4d^2 + 6d: plane {chi[0]}, quadric {chi[1]}, quartic {chi[2]}, quartic b2 = {chi[2] - 2}")
cls = []
for name, f in (("circle x^2 + y^2 = 25z^2", circle), ("hyperbola xy = 12z^2", hyperbola)):
    q = f(X, LINE, [1])
    cls.append(len(roots(q)))
    print(f"{name} on the line x + y = 7z: {show(q)} = 0, x = {roots(q)}, class {cls[-1]}h")
elim = add([144], mul(add(mul(X, X), [-25]), mul(X, X)))     # Res_y = a e^2 - b d e + c d^2
grid = [(x, y) for x in range(-30, 31) for y in range(-30, 31) if x * x + y * y == 25 and x * y == 12]
jac = [2 * (x * x - y * y) for x, y in grid]
g = lambda x, y: x * x + y * y           # xy = 0 at (0 : 1) and (1 : 0); test x^2 + y^2 there
print(f"cup product 2h x 2h = {cls[0] * cls[1]}h^2; eliminant {show(elim)}, roots {roots(elim)}")
print(f"integer search finds {grid}; Jacobian 2(x^2 - y^2) there {jac}")
print(f"points at infinity: x^2 + y^2 and xy share none, resultant {g(0, 1) * g(1, 0)}; total {len(grid)}")
u, v = (0, 1, 0), (0, 1, -1)               # the lines y = 0 and y - z = 0; they meet at the cross product
m = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
print(f"parallel lines y = 0, y = z meet at ({m[0]} : {m[1]} : {m[2]}) = (1 : 0 : 0)")
print(f"lines x = 0, y = 0, x + y = z: determinant {det3([[1, 0, 0], [0, 1, 0], [1, 1, -1]])}, no common point: h^3 = 0")
fl, fc, fp = fs_curve(lambda s: 1 + s), fs_curve(lambda s: 1 + s + s * s), fs_plane()
print(f"Fubini-Study integrals: line {fl:.5f}, conic (1 : t : t^2) {fc:.5f}, h^2 over P^2 {fp:.5f}")
inf_b, tan = beacon([1], X, [0]), circle(X, TAN, [1])
real_b = [(x, y) for x in range(-30, 31) for y in range(-30, 31) if x * x + y * y == 25 and (x - 6) ** 2 + y * y == 25]
print(f"mistake 1, real P^2 over Q: {bq}, the top class lost")
print(f"mistake 2, beacon circles 6 apart: real affine points {real_b}; at infinity both give "
      f"{show(inf_b, 'y')} = 0, discriminant {-4 * inf_b[0] * inf_b[2]}: 2 more, total 4")
print(f"mistake 3, tangent line y = 5z: {show(tan)} = 0, roots {roots(tan)}: 1 point, multiplicity 2")
print(f"mistake 4, the quadric surface: {qa[1]} classes in degree 2, not 1; Bezout in P^5 for conics: 6^5 = {6 ** 5}, true count 3264")
assert betti(*complex_pn(2)) == [a[0], 0, a[1], 0, a[2]] and ev(a, 7) == plane[3]   # cells against counts
assert qa == [1, 2, 1] and ev(qa, 7) == quad[3] and chi[:2] == [sum(a), sum(qa)]
assert bq == [1, 0, 0] and b2 == [1, 1, 1] and cls == [2, 2]
assert sorted(x for x, y in grid) == roots(elim) and len(roots(elim)) == cls[0] * cls[1] and 0 not in jac
assert len(real_b) == 2 and inf_b == circle([1], X, [0]) and roots(inf_b) == [] and g(0, 1) * g(1, 0) != 0
assert roots(tan) == [0, 0] and m[1] == m[2] == 0 != m[0] and abs(fl - 1) + abs(fc - 2) + abs(fp - 1) < 1e-5
print("ALL CHECKS PASS")
