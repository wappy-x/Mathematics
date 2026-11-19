# Genus and the degree-genus formula.  Nothing imported.  Field: the complex numbers.  Curves are
# dicts {(i, j): c} for c x^i y^j, z = 1.  Three roads to the genus: (1) (d-1)(d-2)/2 minus the deltas;
# (2) Riemann-Hurwitz, branch points read off the y-discriminant; (3) adjoint curves of degree d-3.
# Genus-0 curves get a parametrisation put back in.  Integers exact; gcds and resultants mod the prime P.
P = 1_000_000_007
def trim(a): return trim(a[:-1]) if len(a) > 1 and a[-1] == 0 else a
def padd(a, b):
    return trim([(a[i] if i < len(a) else 0) + (b[i] if i < len(b) else 0) for i in range(max(len(a), len(b)))])
def pmul(a, b):
    out = [0] * (len(a) + len(b) - 1)
    for i, u in enumerate(a):
        for j, v in enumerate(b): out[i + j] += u * v
    return trim(out)
def deriv(a): return trim([i * a[i] for i in range(1, len(a))] or [0])
def show(a):
    if a == [0]: return "0"
    s = ""
    for k in range(len(a) - 1, -1, -1):
        if a[k] == 0: continue
        c, m = abs(a[k]), ("" if k == 0 else "x" if k == 1 else f"x^{k}")
        s += (" - " if a[k] < 0 else " + ") + ("" if c == 1 and k else str(c)) + m
    return s[3:] if s[1] == "+" else "-" + s[3:]
def det(M):                                    # cofactor expansion, polynomial entries
    if len(M) == 1: return M[0][0]
    tot = [0]
    for c in range(len(M)):
        if M[0][c] != [0]:
            minor = [row[:c] + row[c + 1:] for row in M[1:]]
            tot = padd(tot, pmul([(-1) ** c], pmul(M[0][c], det(minor))))
    return tot
def disc_y(F, d):                              # Res_y(F, dF/dy): Sylvester matrix, 2d-1 rows
    co = [trim([F.get((i, j), 0) for i in range(d + 1)]) for j in range(d + 1)]
    cy = [pmul([j], co[j]) for j in range(1, d + 1)]
    n, rows = 2 * d - 1, []
    for r in range(d - 1): rows.append([co[r + d - c] if 0 <= r + d - c <= d else [0] for c in range(n)])
    for r in range(d): rows.append([cy[r + d - 1 - c] if 0 <= r + d - 1 - c < d else [0] for c in range(n)])
    return det(rows)
def rem_mod(a, b):                             # remainder of a on division by b, mod P
    inv = pow(b[-1], P - 2, P)
    while len(a) >= len(b) and a != [0]:
        q, s = a[-1] * inv % P, len(a) - len(b)
        a = trim([(a[i] - q * b[i - s]) % P if i >= s else a[i] for i in range(len(a))])
    return a
def gcd_mod(a, b):                             # Euclid's algorithm for polynomials mod P
    a, b = trim([c % P for c in a]), trim([c % P for c in b])
    while b != [0]: a, b = b, rem_mod(a, b)
    inv = pow(a[-1], P - 2, P)                 # made monic, so "no common factor" reads [1]
    return [c * inv % P for c in a]
def res_mod(a, b):                             # Res(a, b) mod P by Euclid, with no determinant
    a, b, r = trim([c % P for c in a]), trim([c % P for c in b]), 1
    while len(b) > 1:
        c = rem_mod(a, b)
        if c == [0]: return 0
        r = r * (-1) ** ((len(a) - 1) * (len(b) - 1)) * pow(b[-1], len(a) - len(c), P) % P
        a, b = b, c
    return r * pow(b[0], len(a) - 1, P) % P
def falling(n, k): return 1 if k == 0 else n * falling(n - 1, k - 1)
def partial(F, i, j, p, q):                    # d^i/dx^i d^j/dy^j of F at (p, q)
    return sum(c * falling(a, i) * falling(b, j) * p ** (a - i) * q ** (b - j)
               for (a, b), c in F.items() if a >= i and b >= j)
def multiplicity(F, p, q): return min(i + j for i in range(5) for j in range(5) if partial(F, i, j, p, q) != 0)
def road1(F, d, sing):                         # road 1: (d-1)(d-2)/2, the sum of m(m-1)/2 over the (ordinary) singular
    dl = sum(m * (m - 1) // 2 for m in (multiplicity(F, p, q) for p, q, _ in sing))   # points, m measured from F,
    return (d - 1) * (d - 2) // 2, dl, (d - 1) * (d - 2) // 2 - dl                    # and the genus
def rank_mod(rows):
    rows, r = [[v % P for v in row] for row in rows], 0
    for c in range(len(rows[0]) if rows else 0):
        piv = next((k for k in range(r, len(rows)) if rows[k][c]), None)
        if piv is None: continue
        rows[r], rows[piv] = rows[piv], rows[r]
        inv = pow(rows[r][c], P - 2, P)
        for k in range(len(rows)):
            if k != r and rows[k][c]:
                f = rows[k][c] * inv % P
                rows[k] = [(x - f * y) % P for x, y in zip(rows[k], rows[r])]
        r += 1
    return r
def adjoints(d, sing):                         # degree d-3 curves vanishing to order m-1
    mons = [(a, b) for a in range(d - 2) for b in range(d - 2 - a)]
    conds = [[falling(a, i) * falling(b, k - i) * p ** max(a - i, 0) * q ** max(b - k + i, 0)
              if a >= i and b >= k - i else 0 for (a, b) in mons]
             for (p, q, m) in sing for k in range(m - 1) for i in range(k + 1)]
    return len(mons), rank_mod(conds) if conds else 0
def homog_at(F, d, X, Y, Z):                   # F(X(t), Y(t), Z(t)), homogenised to degree d
    tot = [0]
    for (a, b), c in F.items():
        term = [c]
        for poly, e in ((X, a), (Y, b), (Z, d - a - b)):
            for _ in range(e): term = pmul(term, poly)
        tot = padd(tot, term)
    return tot

QS, QN = {(4, 0): 1, (2, 0): -1, (0, 4): 1, (0, 3): 1, (0, 2): 1, (0, 0): -1}, {(4, 0): 1, (2, 0): -1, (0, 4): 1, (0, 3): 1, (0, 2): 1}
print(f"field: the complex numbers; exact integers; polynomial gcds modulo {P}")
top, genus = [1, 0, 0, 0, 1], {}               # both quartics end in x^4 + y^4: put y = s x, get s^4 + 1
print(f"points at infinity of both quartics: s^4 + 1 has {len(gcd_mod(top, deriv(top))) - 1} repeated roots, so 4 separate points")
for name, F, sing in (("smooth quartic x^4 - x^2 + y^4 + y^3 + y^2 - 1", QS, []),
                      ("nodal quartic x^4 - x^2 + y^4 + y^3 + y^2", QN, [(0, 0, 2)])):
    D = disc_y(F, 4); G = gcd_mod(D, deriv(D)); G2 = gcd_mod(G, deriv(G))
    b = len(D) - 1 - 2 * (len(G) - 1)          # simple roots; the repeated ones are double (G2 = 1)
    (pa, dl, g1), (nm, rk) = road1(F, 4, sing), adjoints(4, sing)
    print(name + " = 0")
    for (p, q, m) in sing:
        hess = partial(F, 1, 1, p, q) ** 2 - partial(F, 2, 0, p, q) * partial(F, 0, 2, p, q)
        print(f"  singular point ({p}, {q}): multiplicity {multiplicity(F, p, q)}, two tangents: {'yes' if hess != 0 else 'no'}, so a node, delta {dl}")
    print(f"  road 1, formula: (4 - 1)(4 - 2)/2 - {dl} = {g1}")
    print(f"  discriminant in y: {show(D)}")
    print(f"  degree {len(D) - 1}; repeated roots {len(G) - 1}" + (" (x = 0, the node's x, twice)" if sing else "") + f"; branch points {b}")
    print(f"  road 2, Riemann-Hurwitz: 2 - 2g = 2*4 - {b} = {8 - b}, so g = {(b - 6) // 2}")
    print(f"  road 3, lines through the singular points: {nm} coefficients - {rk} conditions = {nm - rk}")
    assert G2 == [1] and G == ([0, 1] if sing else [1]) and gcd_mod(top, deriv(top)) == [1]       # repeated roots: only x = 0, twice
    assert 2 - 2 * g1 == 8 - b and g1 == nm - rk           # three roads agree
    Fx = lambda x: [sum(c * x ** i for (i, k), c in F.items() if k == j) for j in range(5)]   # F(x, y), a poly in y
    assert all(res_mod(Fx(x), deriv(Fx(x))) == sum(c * x ** i for i, c in enumerate(D)) % P for x in range(1, 6))
    genus[name.split()[0]] = g1
C3, TRI = {(0, 2): 1, (3, 0): -1, (2, 0): -1}, {(4, 0): 1, (2, 2): 2, (0, 4): 1, (3, 0): -1, (1, 2): 3}
TWO = {(4, 0): 2, (2, 2): 5, (0, 4): 2, (2, 0): -9, (0, 2): -9, (0, 0): 9}
f3, (_, d0, g0), (nm, rk) = [-1, 0, -1, -1], road1({}, 3, []), adjoints(3, [])   # y^2 = x^3 + x^2 + 1: smooth when f3 has no repeated root
print(f"smooth cubic y^2 = x^3 + x^2 + 1: repeated roots of the right side {len(gcd_mod(f3, deriv(f3))) - 1}; "
      f"road 1: (3 - 1)(3 - 2)/2 - {d0} = {g0}; road 3: {nm} - {rk} = {nm - rk}")
(p3, d3, g3), (n3, r3) = road1(C3, 3, [(0, 0, 2)]), adjoints(3, [(0, 0, 2)]); par = homog_at(C3, 3, [-1, 0, 1], [0, -1, 0, 1], [1])
print(f"nodal cubic y^2 = x^3 + x^2: multiplicity at (0, 0) {multiplicity(C3, 0, 0)}; road 1: {p3} - {d3} = {g3}; road 3: {n3} - {r3} = {n3 - r3}")
print(f"  rational: (t^2 - 1, t^3 - t) put back in gives {show(par)}; t = 2 gives (3, 6): 6^2 = {6 ** 2}, 3^2 * 4 = {9 * 4}")
assert gcd_mod(f3, deriv(f3)) == [1] and g0 == nm - rk and g3 == n3 - r3 and par == [0] and multiplicity(C3, 0, 0) == 2
(pt, dt, gt), (nt, rt), mt = road1(TRI, 4, [(0, 0, 3)]), adjoints(4, [(0, 0, 3)]), multiplicity(TRI, 0, 0); par = homog_at(TRI, 4, [1, 0, -3], [0, 1, 0, -3], [1, 0, 2, 0, 1])
print(f"trifolium (x^2 + y^2)^2 = x^3 - 3xy^2: multiplicity at (0, 0) {mt}, delta {mt}*{mt - 1}/2 = {dt}; "
      f"road 1: {pt} - {dt} = {gt}; road 3: {nt} - {rt} = {nt - rt}")
print(f"  rational: (1 - 3t^2, t - 3t^3, (1 + t^2)^2) put back in gives {show(par)}")
assert mt == 3 and gt == nt - rt and par == [0]
pts, mq = [(p, q) for p in (-1, 1) for q in (-1, 1)], multiplicity(QN, 0, 0)
(pc, dc, gc), (nc, rc) = road1(TWO, 4, [(p, q, 2) for p, q in pts]), adjoints(4, [(p, q, 2) for p, q in pts])
print(f"two conics (x^2 + 2y^2 - 3)(2x^2 + y^2 - 3): nodes at {pts}, multiplicities "
      f"{[multiplicity(TWO, p, q) for p, q in pts]}; road 1: {pc} - {dc} = {gc}; road 3: {nc} - {rc} = {nc - rc}")
print(f"mistake 1, node not subtracted: quartic {pa} - 0 = {pa}, not {genus['nodal']}; cubic {p3} - 0 = {p3}, not {g3}")
print(f"mistake 2, triple point counted as 1: {pt} - 1 = {pt - 1}, not {pt} - {dt} = {gt}")
print(f"mistake 3, formula on two conics: {gc}, a genus no surface has; road 3 says {nc - rc}")
print(f"mistake 4, delta read as multiplicity: the node has m = {mq}, so {pa} - {mq} = {pa - mq}, not {genus['nodal']}")
assert gc == -1 and nc - rc == 0 and all(multiplicity(TWO, p, q) == 2 for p, q in pts) and pa - mq != genus['nodal']
for d in range(1, 8): print(f"bars, degree {d}: {'#' * ((d - 1) * (d - 2)):<30} {(d - 1) * (d - 2) // 2}")
print("ALL CHECKS PASS")
