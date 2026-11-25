# Proj of a graded ring -- the check behind the card.  Nothing is imported and
# every number is an exact integer mod a prime p.  Roads: points found by listing
# all of P^n(F_p), by the parametrisation (s : t) -> (s^2 : st : t^2), by gluing
# the affine charts Spec S_(f), and by counting lines through the origin of the
# affine cone; closed points by brute force against the counting identity; and
# dim S_d by a rank computation against the image of monomials in k[s, t].
P = 7
def proj_points(n, p):                        # P^n(F_p): first nonzero coordinate scaled to 1
    out = []
    for i in range(n + 1):
        for rest in range(p ** (n - i)):
            out.append(tuple([0] * i + [1] + [rest // p ** j % p for j in range(n - i)]))
    return out
def inv(a, p):                                # a^(p-2) is the inverse of a mod p
    r = 1
    for _ in range(p - 2):
        r = r * a % p
    return r
def norm(v, p):                               # scale a nonzero vector: first nonzero entry 1
    a = next(c for c in v if c % p)
    return tuple(c * inv(a, p) % p for c in v)
def show(q):
    return "(" + " : ".join(map(str, q)) + ")"
def rank(rows, p):                            # Gaussian elimination mod p
    rows, r = [row[:] for row in rows], 0
    for c in range(len(rows[0]) if rows else 0):
        piv = next((i for i in range(r, len(rows)) if rows[i][c] % p), None)
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        k = inv(rows[r][c], p)
        for i in range(len(rows)):
            if i != r and rows[i][c] % p:
                f = rows[i][c] * k % p
                rows[i] = [(x - f * y) % p for x, y in zip(rows[i], rows[r])]
        r += 1
    return r
print("== projective space: Proj F_7[x, y] and Proj F_7[x, y, z] ==")
line, plane = proj_points(1, P), proj_points(2, P)
assert len(line) == (P ** 2 - 1) // (P - 1) and len(plane) == (P ** 3 - 1) // (P - 1)
print(f"P^1(F_7): {len(line)} points", " ".join(show(q) for q in line))
print(f"P^2(F_7): {len(plane)} points = (343 - 1)/6")
ux = sorted({y * inv(x, P) % P for x, y in line if x})      # chart D+(x): the value y/x
uy = sorted({x * inv(y, P) % P for x, y in line if y})      # chart D+(y): the value x/y
both = [q for q in line if q[0] and q[1]]
assert len(ux) + len(uy) - len(both) == len(line)
print(f"charts of P^1: D+(x) {len(ux)} values of y/x, D+(y) {len(uy)} values of x/y, overlap {len(both)}: {len(ux)} + {len(uy)} - {len(both)} = {len(line)}")
def roots(c, p):                              # points (s : t) of P^1(F_p) where the form vanishes
    d = len(c) - 1
    return [q for q in proj_points(1, p) if sum(ci * q[0] ** (d - i) * q[1] ** i for i, ci in enumerate(c)) % p == 0]
N = {1: len(line)}
for d in (2, 3):                              # degree 2 and 3: irreducible means no root
    N[d] = sum(1 for c in proj_points(d, P) if not roots(c, P))
    assert sum(e * N[e] for e in N if d % e == 0) == P ** d + 1
print("closed points of Proj F_7[x, y] by degree 1, 2, 3:", N[1], N[2], N[3], f" check: 8 + 2 x 21 = {8 + 2 * 21}, 8 + 3 x 112 = {8 + 3 * 112}")
assert not roots((1, 0, 1), P)
print("x^2 + y^2 has", len(roots((1, 0, 1), P)), "roots: a closed point of degree 2; squares mod 7:", sorted({a * a % P for a in range(1, P)}))
print("== Proj Z[x, y]: the line over Z, one fibre per prime ==")
for p in (2, 3, 5, 7, 11, 13):
    assert len(proj_points(1, p)) == p + 1
    print(f"fibre over {p}: {p + 1} points; the rational point (3 : 5) lands on {show(norm((3, 5), p))}")
print(f"over 7: 1/3 = {inv(3, P)}, 5 x {inv(3, P)} = {5 * inv(3, P)} = {5 * inv(3, P) % P} mod 7")
print("== the conic Proj F_7[x, y, z]/(xz - y^2) ==")
conic = [q for q in plane if (q[0] * q[2] - q[1] ** 2) % P == 0]
image = sorted({norm((s * s, s * t, t * t), P) for s, t in line})
assert image == sorted(conic) and len(conic) == P + 1        # road two: the parametrisation
back = lambda q: norm(q[:2], P) if q[0] or q[1] else norm(q[1:], P)
assert all(back(norm((s * s, s * t, t * t), P)) == (s, t) for s, t in line)
print("points:", " ".join(show(q) for q in conic), f"-> {len(conic)}")
print("from (s : t):", " ".join(f"{show(q)}->{show(norm((q[0] ** 2, q[0] * q[1], q[1] ** 2), P))}" for q in line[:3]), "...")
cone = sum(1 for x in range(P) for y in range(P) for z in range(P) if (x * z - y * y) % P == 0)
assert cone == 1 + (P - 1) * len(conic)                      # road three: lines through the cone's vertex
print(f"affine cone xz = y^2 in F_7^3: {cone} points = 1 + {(P - 1) * len(conic)}; ({cone} - 1)/6 = {(cone - 1) // (P - 1)} lines")
cx = [(u, v) for u in range(P) for v in range(P) if (v - u * u) % P == 0]     # S_(x): v = u^2
cz = [(a, b) for a in range(P) for b in range(P) if (a - b * b) % P == 0]     # S_(z): a = b^2
cy = [(c, e) for c in range(P) for e in range(P) if (c * e - 1) % P == 0]     # S_(y): ce = 1
xz = [q for q in conic if q[0] and q[2]]
assert all(q[0] or q[2] for q in conic) and len(cx) + len(cz) - len(xz) == len(conic) == len(cx) + 1
assert len(xz) == len(cy) and all(q[1] * inv(q[0], P) * q[1] * inv(q[2], P) % P == 1 for q in xz)
print(f"charts: Spec S_(x) {len(cx)} points, Spec S_(z) {len(cz)}, overlap {len(xz)} (= Spec S_(y), {len(cy)}): {len(cx)} + {len(cz)} - {len(xz)} = {len(conic)}")
print("on the overlap (y/x)(y/z) = 1 at all", len(xz), "points; chart x = 1 holds", " ".join(f"({u}, {v})" for u, v in cx))
def mono(d, n):                               # exponent vectors of degree d in n variables
    return [(d,)] if n == 1 else [(a,) + m for a in range(d, -1, -1) for m in mono(d - a, n - 1)]
hf = []
for d in range(7):
    ms = mono(d, 3)
    rows = []
    for a, b, c in (mono(d - 2, 3) if d >= 2 else []):       # the multiples of xz - y^2 in degree d
        row = [0] * len(ms)
        row[ms.index((a + 1, b, c + 1))] += 1
        row[ms.index((a, b + 2, c))] -= 1
        rows.append(row)
    pic = len({(2 * a + b, b + 2 * c) for a, b, c in ms})    # monomials hit by x -> s^2, y -> st, z -> t^2
    assert len(ms) - rank(rows, P) == pic == 2 * d + 1
    hf.append(pic)
print("dim S_d, d = 0..6:", " ".join(map(str, hf)), " = 2d + 1 = dim k[s, t] in degree 2d; top coefficient 2, the degree")
print(f"dim S_3 = {len(mono(3, 3))} - {len(mono(1, 3))} = {hf[3]}")
print("== the weighted line Proj F_7[x, y], deg x = 1, deg y = 2 ==")
w = [sum(1 for i in range(d + 1) for j in range(d + 1) if i + 2 * j == d) for d in range(9)]
assert w == [d // 2 + 1 for d in range(9)]
print("dim S_d, d = 0..8:", " ".join(map(str, w)), " even degrees 2d:", " ".join(str(w[2 * d]) for d in range(5)), "= d + 1, as for P^1")
def orbits(a, b, p):                          # naive classes of (x, y) != 0 under (lx, ly) -> (l^a x, l^b y)
    return sorted({min((x * l ** a % p, y * l ** b % p) for l in range(1, p)) for x in range(p) for y in range(p) if x or y})
orb = orbits(1, 2, P)
pts = sorted({norm((x * x, y), P) for x, y in orb})          # (x : y) -> (x^2 : y), onto P^1
wx = {y * inv(x * x, P) % P for x, y in orb if x}            # chart D+(x): the value y/x^2
wy = {x * x * inv(y, P) % P for x, y in orb if y}            # chart D+(y): the value x^2/y
wxy = sum(1 for q in pts if q[0] and q[1])
assert len(wx) + len(wy) - wxy == len(pts) == len(line) and len(orb) == len(pts) + 1
merged = [show(q) for q in orb if q[0] == 0]
print(f"naive orbits: {len(orb)}; scheme points: {len(pts)} = {len(wx)} values of y/x^2 + {len(wy)} of x^2/y - {wxy} on the overlap")
print("orbits", " and ".join(merged), "both have x^2/y = 0: one point of Proj")
print("== what breaks ==")
print(f"Spec instead of Proj, keeping the vertex: {cone} points, not {len(conic)}")
whole = sum(1 for x in range(P) for y in range(P) if x)
print(f"whole localisation S_x = F_7[x, y, 1/x], not its degree-0 part: {whole} points, not {len(ux)}")
print(f"weighted points as naive orbits: {len(orb)}, not {len(pts)}")
print(f"three different rings, one P^1: dim S_1 = {len(mono(1, 2))}, {hf[1]}, {w[1]}; every one has {len(line)} points over F_7")
print("== try changing ==")
print(f"orbits for weights 1, 3 over F_7: {len(orbits(1, 3, P))}, cubes mod 7: {sorted({a ** 3 % P for a in range(1, P)})}; conic over F_11: {sum(1 for q in proj_points(2, 11) if (q[0] * q[2] - q[1] ** 2) % 11 == 0)} points; dim S_10 of the conic: {len(mono(10, 3)) - len(mono(8, 3))}")
print("figure, chart x = 1 points (u, v) at px = 60 + 40u, py = 300 - 40v:", " ".join(f"({60 + 40 * u}, {300 - 40 * v})" for u, v in cx), "; (0 : 0 : 1) at infinity")
print("ALL CHECKS PASS")
