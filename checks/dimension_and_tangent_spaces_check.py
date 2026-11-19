# Dimension and tangent space -- the check behind the card.  Nothing is imported.
# The variety is the cone x^2 + y^2 = z^2 over the reals; F_p only where named.
# A polynomial is a dict {(i, j, k): coeff} for x^i y^j z^k, whole numbers.
# Dimension, three roads: independent coordinates (transcendence degree), a
# chain of prime ideals with exact witnesses, and point counts over F_p.
# Tangent space, three roads: Jacobian rank, dual numbers counted over F_p,
# and the exact secant identity of a quadratic.
P = 1000003                                     # a prime, for ranks of value tables

def add(a, b, s=1):
    out = dict(a)
    for m, c in b.items():
        out[m] = out.get(m, 0) + s * c
    return {m: c for m, c in out.items() if c}

def mul(a, b):
    out = {}
    for (i, j, k), c in a.items():
        for (u, v, w), d in b.items():
            out = add(out, {(i + u, j + v, k + w): c * d})
    return out

def ev(g, pt, mod=0):
    s = sum(c * pt[0] ** i * pt[1] ** j * pt[2] ** k for (i, j, k), c in g.items())
    return s % mod if mod else s

def grad(g, pt):                                # the Jacobian row of g at pt
    row = []
    for v in range(3):
        d = {}
        for m, c in g.items():
            if m[v]:
                e = list(m)
                e[v] -= 1
                d = add(d, {tuple(e): c * m[v]})
        row.append(ev(d, pt))
    return row

def rank_mod(rows):                             # Gaussian elimination mod P
    rows, r = [[v % P for v in row] for row in rows], 0
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

def dual_ev(g, pt, v, p):                       # g(pt + eps v) with eps^2 = 0, mod p
    a, b = 0, 0
    for m, c in g.items():
        ta, tb = c % p, 0
        for q, d, e in zip(pt, v, m):
            for _ in range(e):
                ta, tb = ta * q % p, (ta * d + tb * q) % p
        a, b = (a + ta) % p, (b + tb) % p
    return a, b

def tangent_count(gens, pt, p):                 # directions v in F_p^3 that keep every g zero
    box = [(i, j, k) for i in range(p) for j in range(p) for k in range(p)]
    return sum(1 for v in box if all(dual_ev(g, pt, v, p) == (0, 0) for g in gens))

x, y, z, one = {(1, 0, 0): 1}, {(0, 1, 0): 1}, {(0, 0, 1): 1}, {(0, 0, 0): 1}
F = {(2, 0, 0): 1, (0, 2, 0): 1, (0, 0, 2): -1}
pts = sorted({(sx * t * a, sy * t * b, sz * t * (m * m + n * n))
              for m in range(1, 6) for n in range(m) for a, b in [(m * m - n * n, 2 * m * n), (2 * m * n, m * m - n * n)]
              for t in (1, 2) for sx in (1, -1) for sy in (1, -1) for sz in (1, -1)})
assert all(ev(F, q) == 0 for q in pts)
print("field: the real numbers; F_p only where named.  cone f = x^2 + y^2 - z^2")
print(f"integer test points on the cone: {len(pts)}")
print("-- dimension, road 1: independent coordinates --")
yz = [(0, a, b) for a in range(5) for b in range(5 - a)]
r_yz = rank_mod([[ev({m: 1}, q, P) for m in yz] for q in pts])
print(f"monomials in y, z of degree <= 4: {len(yz)}; rank of their values on the cone: {r_yz}")
xyz = [(i, j, k) for i in range(3) for j in range(3) for k in range(3) if i + j + k <= 2]
r_xyz = rank_mod([[ev({m: 1}, q, P) for m in xyz] for q in pts])
print(f"monomials in x, y, z of degree <= 2: {len(xyz)}; rank: {r_xyz}, so one relation: f")
print(f"x over k(y, z): t^2 - (z^2 - y^2) = 0; (3, 4, 5) and (-3, 4, 5) share y, z: degree 2")
assert r_yz == len(yz) == 15 and r_xyz == len(xyz) - 1 == 9 and ev(F, (-3, 4, 5)) == 0
print("transcendence degree 2")
print("-- dimension, road 2: a chain of prime ideals --")
g1, g2 = add(mul({(0, 0, 0): 4}, x), mul({(0, 0, 0): 3}, y), -1), add(mul({(0, 0, 0): 5}, x), mul({(0, 0, 0): 3}, z), -1)
lhs = add(mul(add(g1, mul({(0, 0, 0): 8}, x), -1), g1), mul(add(mul({(0, 0, 0): 10}, x), g2, -1), g2))
print(f"9f = (g1 - 8x) g1 + (10x - g2) g2 with g1 = 4x - 3y, g2 = 5x - 3z: {'yes' if lhs == mul({(0, 0, 0): 9}, F) else 'no'}")
print(f"g1 at the cone point (4, 3, 5): {ev(g1, (4, 3, 5))}, not 0, so the line ideal is bigger than <f>")
X3, H = add(x, {(0, 0, 0): 3}, -1), [grad(F, e) for e in ((1, 0, 0), (0, 1, 0), (0, 0, 1))]   # H: f's second derivatives
print(f"x - 3 at the line point (6, 8, 10): {ev(X3, (6, 8, 10))}, not 0, so the point ideal is bigger again")
print(f"quadratic form of f: second-derivative matrix {H}, rank {rank_mod(H)}: no linear factors, <f> prime")
assert lhs == mul({(0, 0, 0): 9}, F) and ev(g1, (4, 3, 5)) == 7 and ev(X3, (6, 8, 10)) != 0 and rank_mod(H) == 3
assert ev(g1, (6, 8, 10)) == ev(g2, (6, 8, 10)) == 0
print("chain in k[V]: (0) < line ideal < point ideal, length 2; in k[x, y, z]: length 3")
print("-- dimension, road 3: points over F_p --")
for p in (3, 5, 7, 11, 13):
    n = sum(1 for a in range(p) for b in range(p) for c in range(p) if ev(F, (a, b, c), p) == 0)
    print(f"cone over F_{p}: {n} points = {p}^2")
    assert n == p * p
circ = sum(1 for a in range(7) for b in range(7) if (a * a + b * b - 25) % 7 == 0)
print(f"circle x^2 + y^2 = 25 at z = 5, over F_7: {circ} points = 7 + 1")
assert circ == 8
print("-- tangent spaces: Jacobian rank against dual numbers over F_7 --")
Z5, ZY = add(z, {(0, 0, 0): 5}, -1), add(z, y, -1)
cases = [("cone at (3, 4, 5)", [F], (3, 4, 5)), ("cone at the apex", [F], (0, 0, 0)),
         ("circle z = 5 at (3, 4, 5)", [F, Z5], (3, 4, 5)), ("mistake <f^2> at (3, 4, 5)", [mul(F, F)], (3, 4, 5)),
         ("count <f, z f>: 3 - 2 = 1? at (3, 4, 5)", [F, mul(z, F)], (3, 4, 5)), ("try <f, z - y> at (0, 3, 3)", [F, ZY], (0, 3, 3)),
         ("try cone at (5, 12, 13)", [F], (5, 12, 13))]
for name, gens, pt in cases:
    J = [grad(g, pt) for g in gens]
    r, cnt = rank_mod(J), tangent_count(gens, pt, 7)
    print(f"{name}: J = {J}, rank {r}, tangent dim {3 - r}; F_7 count {cnt} = 7^{3 - r}")
    assert cnt == 7 ** (3 - r) and all(ev(g, pt) == 0 for g in gens)
print(f"try F_11: apex {tangent_count([F], (0, 0, 0), 11)}, (3, 4, 5) {tangent_count([F], (3, 4, 5), 11)}")
print("-- secants: grad f(P).(Q - P) = -f(Q - P) for every cone point Q --")
G = grad(F, (3, 4, 5))
assert all(sum(a * (b - c) for a, b, c in zip(G, q, (3, 4, 5))) == -ev(F, [b - c for b, c in zip(q, (3, 4, 5))]) for q in pts)
print(f"holds at all {len(pts)} test points; tangent plane 6x + 8y - 10z = 0, or 3x + 4y - 5z = 0")
for N in (10, 100, 1000):
    w = (-2 * N - 1, 4 * N, 2 * N + 1)          # N^2 (Q - P), Q from m = 2N, n = N + 1
    gap, dist = ev(F, w) / N ** 4, sum(c * c for c in w) ** 0.5 / N ** 2
    assert ev(F, (3 * N * N - 2 * N - 1, 4 * N * N + 4 * N, 5 * N * N + 2 * N + 1)) == 0 and sum(a * b for a, b in zip(G, w)) * N * N == -ev(F, w)
    print(f"N = {N}: Q - P = ({w[0]}, {w[1]}, {w[2]})/{N * N}; linear part {-gap:.6f}, distance {dist:.6f}, ratio {gap / dist:.6f}")
det = 3 * (3 * 5 - 5 * 4) - 4 * (4 * 5 - 5 * (-3)) + 5 * (4 * 4 - 3 * (-3))
print(f"apex: rulings through (3, 4, 5), (4, 3, 5), (-3, 4, 5); determinant {det}, so they span all 3 directions")
assert det == -30 and rank_mod([[3, 4, 5], [4, 3, 5], [-3, 4, 5]]) == 3
box = [(a, b, c) for a in range(-5, 6) for b in range(-5, 6) for c in range(-5, 6) if a * a + b * b + c * c == 0]
print(f"mistake x^2 + y^2 + z^2 = 0 over the reals: {len(box)} point in the box, dimension 0, not 3 - 1 = 2")
assert len(box) == 1
print("ALL CHECKS PASS")
