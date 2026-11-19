# Affine varieties and coordinate rings -- the check behind the card.  Nothing
# is imported.  The variety is the cone x^2 + y^2 = z^2, the edge of a torch
# beam with its bulb at the origin.  A polynomial is a dict {(i, j, k): coeff}
# for x^i y^j z^k, with whole-number coefficients.  Roads: divide by the cone
# (replace x^2 by z^2 - y^2); put exact points back in; count independent
# functions by the rank of a table of values, which never sees the equation.
P = 1000003                                     # a prime, for the rank road

def add(a, b):
    out = dict(a)
    for m, c in b.items():
        out[m] = out.get(m, 0) + c
    return {m: c for m, c in out.items() if c}

def normal_form(g):                             # road one: x^2 -> z^2 - y^2
    g = dict(g)
    while any(m[0] >= 2 for m in g):
        (i, j, k), c = next((m, c) for m, c in g.items() if m[0] >= 2)
        del g[(i, j, k)]
        g = add(g, {(i - 2, j, k + 2): c, (i - 2, j + 2, k): -c})
    return g

def ev(g, pt, mod=None):                        # road two: put a point back in
    s = sum(c * pt[0] ** i * pt[1] ** j * pt[2] ** k for (i, j, k), c in g.items())
    return s % mod if mod else s

def show(g):                                    # leading term first, x > y > z
    if not g:
        return "0"
    out = ""
    for (i, j, k), c in sorted(g.items(), reverse=True):
        mono = "".join(v + (f"^{e}" if e > 1 else "") for v, e in zip("xyz", (i, j, k)) if e)
        coef = (str(abs(c)) if abs(c) != 1 or not mono else "") + mono
        out += ("-" if c < 0 else "") + coef if not out else (" - " if c < 0 else " + ") + coef
    return out

pts = set()                                     # integer points from Pythagorean triples
for m in range(1, 6):
    for n in range(0, m):
        a, b, c = m * m - n * n, 2 * m * n, m * m + n * n
        for t in (1, 2):
            for sx, sy, sz in [(u, v, w) for u in (1, -1) for v in (1, -1) for w in (1, -1)]:
                pts |= {(sx * t * a, sy * t * b, sz * t * c), (sx * t * b, sy * t * a, sz * t * c)}
pts = sorted(pts)
F = {(2, 0, 0): 1, (0, 2, 0): 1, (0, 0, 2): -1}
assert all(ev(F, q) == 0 for q in pts)
print("field: the real numbers; F_p only where named")
print(f"cone f = {show(F)}; normal form: replace x^2 by z^2 - y^2")
print(f"integer test points on the cone: {len(pts)}")
named = [("x^2 + y^2 + z^2", {(2, 0, 0): 1, (0, 2, 0): 1, (0, 0, 2): 1}),
         ("2x^2 + 2y^2", {(2, 0, 0): 2, (0, 2, 0): 2}),
         ("x^4 - x^2z^2 - y^4 + y^2z^2", {(4, 0, 0): 1, (2, 0, 2): -1, (0, 4, 0): -1, (0, 2, 2): 1}),
         ("x^2 + z^2", {(2, 0, 0): 1, (0, 0, 2): 1})]
for name, g in named:
    r = normal_form(g)
    same = all(ev(g, q) == ev(r, q) for q in pts)
    print(f"g = {name}  ->  {show(r)}; equal at all {len(pts)} points: {'yes' if same else 'no'}")
    assert same
assert normal_form(named[0][1]) == normal_form(named[1][1]) == {(0, 0, 2): 2} and normal_form(named[2][1]) == {}
print(f"x^2 + z^2 against 2z^2: at (3, 0, 3) {ev(named[3][1], (3, 0, 3))} and 18; at (0, 3, 3) {ev(named[3][1], (0, 3, 3))} and 18")
print(f"squared distance from the bulb at (9, 12, 15): {ev(named[0][1], (9, 12, 15))} = 2 x 15^2 = {2 * 225}")
print(f"on the wall z = 3: 2 x 3^2 = 18, distance {18 ** 0.5:.3f} m")

def rank_mod(rows):                             # Gaussian elimination mod P
    r = 0
    for col in range(len(rows[0])):
        piv = next((i for i in range(r, len(rows)) if rows[i][col]), None)
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        inv = pow(rows[r][col], P - 2, P)
        rows[r] = [v * inv % P for v in rows[r]]
        for i in range(len(rows)):
            if i != r and rows[i][col]:
                c = rows[i][col]
                rows[i] = [(v - c * w) % P for v, w in zip(rows[i], rows[r])]
        r += 1
    return r

def monos(d):
    return [(i, j, k) for i in range(d + 1) for j in range(d + 1 - i) for k in range(d + 1 - i - j)]

def mults(e, d):                                # multiples h g of a degree-e polynomial g, deg h <= d - e
    return len(monos(d - e)) if d >= e else 0

print("degree d | monomials | multiples of f | normal-form basis | rank of values")
dims = []
for d in range(6):
    ms = monos(d)
    basis = sum(1 for (i, j, k) in ms if i <= 1)
    rank = rank_mod([[ev({m: 1}, q, P) for m in ms] for q in pts])
    print(f"   {d}     |    {len(ms):2}     |      {mults(2, d):2}        |        {basis:2}         |   {rank:2}")
    assert basis == rank == (d + 1) ** 2 == len(ms) - mults(2, d)
    dims.append(rank)

def frac(n, d):                                 # n/d in lowest terms
    a, b = abs(n), abs(d)
    while b:
        a, b = b, a % b
    sign = "-" if n * d < 0 else ""
    return f"{sign}{abs(n) // a}" + (f"/{abs(d) // a}" if abs(d) != a else "")

print("walls z = 3 + c y with c = p/q; the slice, put into f and times q^2:")
ends = {}                                       # each wall's x = 0 ends, kept for the lines below
for p, q in [(0, 1), (1, 2), (1, 1), (2, 1), (3, 2)]:
    A, B, C = q * q - p * p, -6 * p * q, -9 * q * q
    kind = ("circle" if B == 0 else "ellipse") if A > 0 else "parabola" if A == 0 else "hyperbola"
    disc = B * B - 4 * A * C
    s = int(disc ** 0.5)
    assert s * s == disc
    ys = sorted([(-B - s, 2 * A), (-B + s, 2 * A)], key=lambda t: t[0] / t[1]) if A else [(-C, B)]
    zs = [(3 * q * yd + p * yn, q * yd) for yn, yd in ys]
    ends[p, q] = list(zip(ys, zs))
    for (yn, yd), (zn, zd) in zip(ys, zs):          # scale up and put back in f
        assert ev(F, (0, yn * zd, zn * yd)) == 0
    geo = "ellipse" if len(zs) == 2 and all(zn * zd > 0 for zn, zd in zs) else "parabola" if len(zs) == 1 else "hyperbola"
    assert geo == kind.replace("circle", "ellipse")
    print(f"c = {frac(p, q)}: {show(add({}, {(2, 0, 0): q * q, (0, 2, 0): A, (0, 1, 0): B, (0, 0, 0): C}))}; {kind}; x = 0 at "
          + "(y, z) = " + " and ".join(f"({frac(*y)}, {frac(*z)})" for y, z in zip(ys, zs)))
(ya, za), (yb, zb) = ends[1, 2]                 # the ellipse's ends; on the cone, distance^2 = 2z^2
print(f"ellipse ends (0, {frac(*ya)}, {frac(*za)}) and (0, {frac(*yb)}, {frac(*zb)}): "
      f"{(2 * (za[0] / za[1]) ** 2) ** 0.5:.3f} m and {(2 * (zb[0] / zb[1]) ** 2) ** 0.5:.3f} m from the bulb")
pt = {w: [f"({frac(*y)},{frac(*z)})" for y, z in sorted(e, key=lambda t: t[1][0] / t[1][1])] for w, e in ends.items()}
print(f"figure, edges z = y and z = -y; circle {'-'.join(pt[0, 1])}; ellipse {'-'.join(pt[1, 2])}; "
      f"parabola from {pt[1, 1][0]} along z = 3 + y; hyperbola up from {pt[2, 1][1]}, down from {pt[2, 1][0]}")
for p in (3, 5, 7, 11):
    n = sum(1 for x in range(p) for y in range(p) for z in range(p) if (x * x + y * y - z * z) % p == 0)
    print(f"points on the cone over F_{p}: {n} = {p}^2")
    assert n == p * p
cub = {(3, 0, 0): 1, (1, 0, 0): -1}
on3 = [(x, y, z) for x in range(3) for y in range(3) for z in range(3) if (x * x + y * y - z * z) % 3 == 0]
print(f"mistake 1, over F_3: x^3 - x is 0 at all {len(on3)} points: {'yes' if all(ev(cub, q, 3) == 0 for q in on3) else 'no'}; "
      f"normal form {show(normal_form(cub))}, not 0")
q2, q3 = (len(monos(2)) - mults(e, 2) for e in (2 * max(map(sum, F)), max(map(sum, named[0][1]))))  # f^2; x^2+y^2+z^2
print(f"mistake 2, (x^2 + y^2 - z^2)^2 = 0 as the equation: degree <= 2 quotient keeps {q2}; functions {dims[2]}")
box = [(x, y, z) for x in range(-5, 6) for y in range(-5, 6) for z in range(-5, 6) if x * x + y * y + z * z == 0]
one = rank_mod([[ev({m: 1}, q, P) for m in monos(2)] for q in box])
print(f"mistake 3, x^2 + y^2 + z^2 = 0 over the reals: {len(box)} point in the box; quotient keeps {q3} in degree <= 2, functions {one}")
assert normal_form(cub) != {} and all(ev(cub, q, 3) == 0 for q in on3) and len(box) == one == 1 and q2 == dims[2] + 1 == q3 + 1
print("ALL CHECKS PASS")
