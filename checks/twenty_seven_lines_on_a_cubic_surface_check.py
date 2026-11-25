# The 27 lines on a cubic surface -- the check behind the card.  Nothing is imported.
# Road 1: the Fermat cubic x^3 + y^3 + z^3 + w^3 = 0 and its 27 lines, exact in Z[r] (r^2 = -1 - r).
# Road 2: every line of P^3 over F_p, tested by brute force.
# Road 3: the plane blown up at six points, where lines are the classes D with D.D = -1 and K.D = -1.
# Road 4: name six skew Fermat lines E1..E6, read off every other line's class, compare all meetings.
def mul(a, b):                           # (a0 + a1 r)(b0 + b1 r), using r^2 = -1 - r
    return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0] - a[1] * b[1])
def det(m):                              # determinant in Z[r], expanding along row 0
    if len(m) == 1:
        return m[0][0]
    total = (0, 0)
    for j in range(len(m)):
        t = mul(m[0][j], det([row[:j] + row[j + 1:] for row in m[1:]]))
        sign = 1 - 2 * (j % 2)
        total = (total[0] + sign * t[0], total[1] + sign * t[1])
    return total
ROOTS = [(1, 0), (0, 1), (-1, -1)]                      # 1, r, r^2
fermat = []                                             # each line as two points P, Q on it
for (i, j), (k, l) in [((0, 1), (2, 3)), ((0, 2), (1, 3)), ((0, 3), (1, 2))]:
    for a in ROOTS:
        for b in ROOTS:
            P, Q = [(0, 0)] * 4, [(0, 0)] * 4
            P[i], P[j], Q[k], Q[l] = (-a[0], -a[1]), (1, 0), (-b[0], -b[1]), (1, 0)
            fermat.append((P, Q, a == b == (1, 0)))
def on_surface(P, Q):                    # F(sP + tQ) = 0 at four points: a cubic in s, t that is 0
    for s, t in [(1, 0), (0, 1), (1, 1), (1, -1)]:
        cubes = [mul(mul(c, c), c) for c in [(s * p[0] + t * q[0], s * p[1] + t * q[1]) for p, q in zip(P, Q)]]
        if (sum(c[0] for c in cubes), sum(c[1] for c in cubes)) != (0, 0):
            return False
    return True
def graph_stats(adj):                    # degrees, triangles, common neighbours (meeting, not)
    n = len(adj)
    degs = sorted({sum(adj[u]) for u in range(n)})
    tri = sum(adj[u][v] and adj[v][w] and adj[u][w] for u in range(n) for v in range(u + 1, n) for w in range(v + 1, n))
    lam, mu = set(), set()
    for u in range(n):
        for v in range(u + 1, n):
            (lam if adj[u][v] else mu).add(sum(adj[u][w] and adj[v][w] for w in range(n)))
    return degs, tri, sorted(lam), sorted(mu)
def rref(rows, p):                       # reduced row echelon form of two rows mod p
    rows, out = [[x % p for x in r] for r in rows], []
    for c in range(4):
        k = next((t for t, r in enumerate(rows) if r[c]), None)
        if k is None:
            continue
        piv = rows.pop(k)
        piv = [x * pow(piv[c], p - 2, p) % p for x in piv]
        rows = [[(x - r[c] * y) % p for x, y in zip(r, piv)] for r in rows]
        out = [[(x - o[c] * y) % p for x, y in zip(o, piv)] for o in out] + [piv]
    return tuple(tuple(r) for r in out)
def lines_on(p, coeffs):                 # brute force: every line of P^3 over F_p, in echelon form
    found, total = [], 0
    for i in range(4):
        for j in range(i + 1, 4):
            fr1, fr2 = [c for c in range(i + 1, 4) if c != j], list(range(j + 1, 4))
            for n1 in range(p ** len(fr1)):
                for n2 in range(p ** len(fr2)):
                    r1 = [int(c == i) + (n1 // p ** fr1.index(c) % p if c in fr1 else 0) for c in range(4)]
                    r2 = [int(c == j) + (n2 // p ** fr2.index(c) % p if c in fr2 else 0) for c in range(4)]
                    total += 1
                    if all(sum(k * (s * x + t * y) ** 3 for k, x, y in zip(coeffs, r1, r2)) % p == 0
                           for s, t in [(1, 0), (0, 1), (1, 1), (1, 2)]):
                        found.append((tuple(r1), tuple(r2)))
    return total, found
def classes(n):                          # every aH - b1E1 - ... - bnEn with D.D = -1 and K.D = -1
    out = []
    def go(a, pre, s, q):                # s, q: sum and sum of squares the remaining b's must make
        k = n - len(pre)
        if k == 0 or s * s > k * q:      # Cauchy-Schwarz: s^2 <= k q, or the rest cannot fit
            if k == 0 and s == 0 and q == 0:
                out.append((a,) + tuple(pre))
            return
        m = int(q ** 0.5)
        for b in range(-m, m + 1):
            go(a, pre + [b], s - b, q - b * b)
    for a in range(-12, 13):             # Cauchy-Schwarz bounds a to 0, 1, 2; the range is far wider
        go(a, [], 3 * a - 1, a * a + 1)
    return out
dot = lambda D, F: D[0] * F[0] - sum(x * y for x, y in zip(D[1:], F[1:]))
E = [(0,) + tuple(-(t == i) for t in range(6)) for i in range(6)]
L = [(1,) + tuple(int(t in (i, j)) for t in range(6)) for i in range(6) for j in range(i + 1, 6)]
C = [(2,) + tuple(int(t != i) for t in range(6)) for i in range(6)]
names = [f"E{i+1}" for i in range(6)] + [f"L{i+1}{j+1}" for i in range(6) for j in range(i + 1, 6)] + [f"C{i+1}" for i in range(6)]
typed, K, h, found6 = E + L + C, (-3,) + (-1,) * 6, (3,) + (1,) * 6, classes(6)
yn = lambda claim: "yes" if claim else "no"
print("Road 1: Fermat cubic x^3 + y^3 + z^3 + w^3 = 0, exact, r^2 + r + 1 = 0")
print(f"lines x = -a y, z = -b w and the 2 other pairings, a, b in 1, r, r^2: {len(fermat)}")
print(f"lines put back in the equation that vanish identically: {sum(on_surface(P, Q) for P, Q, _ in fermat)}")
print(f"lines with real coefficients (a = b = 1): {sum(re for _, _, re in fermat)}")
meet = [[u != v and det([*fermat[u][:2], *fermat[v][:2]]) == (0, 0) for v in range(27)] for u in range(27)]
g1 = graph_stats(meet)                   # two lines meet exactly when their four spanning points are dependent
print(f"x = -y, z = -w meets {sum(meet[0][:9])} lines of its own pairing and {sum(meet[0][9:])} of the other two")
print(f"meeting graph, Fermat lines: degree {g1[0]}, triangles {g1[1]}, common neighbours {g1[2]} if meeting, {g1[3]} if not")
total7, on7 = lines_on(7, [1, 1, 1, 1])
red = {rref([[c[0] + 2 * c[1] for c in P], [c[0] + 2 * c[1] for c in Q]], 7) for P, Q, _ in fermat}
print(f"Road 2: all {total7} lines of P^3 over F_7 tested, on the Fermat cubic: {len(on7)}")
print(f"the 27 exact lines reduced mod 7 (r -> 2) are exactly these: {yn(red == set(on7))}")
print("Road 3: plane blown up at six points, classes D = aH - b1E1 - ... - b6E6")
print(f"search for D.D = -1 and K.D = -1, K = -3H + E1 + ... + E6: {len(found6)} classes, a in {sorted({d[0] for d in found6})}")
print(f"typed list: E_i {len(E)}, L_ij = H - Ei - Ej {len(L)}, C_i = 2H - (E1 + ... + E6) + Ei {len(C)}: {len(typed)}")
print(f"search and typed list agree: {yn(sorted(found6) == sorted(typed))}")
print(f"K.K = {dot(K, K)}, h = -K = 3H - E1 - ... - E6, h.h = {dot(h, h)}, h.D for the 27: {sorted({dot(h, d) for d in typed})}; "
      f"plane cubics: {4 * 5 // 2} coefficients, minus 6 points = {10 - 6} = coordinates of P^3")
for name in ["E1", "L12", "C1"]:
    u = typed[names.index(name)]
    print(f"{name} meets: {' '.join(names[t] for t, v in enumerate(typed) if dot(u, v) == 1)}")
def skew(ch):                            # six pairwise skew Fermat lines, by backtracking
    return ch if len(ch) == 6 else next((r for u in range(ch[-1] + 1 if ch else 0, 27)
                                         if not any(meet[u][v] for v in ch) for r in [skew(ch + [u])] if r), None)
sixer = skew([])                         # E_i is sixer[i]; a line meeting E_i, E_j is H - Ei - Ej (a = 1),
lab = [E[sixer.index(u)] if u in sixer else  # a line meeting five of them is a conic (a = 2)
       (sum(meet[u][v] for v in sixer) // 2,) + tuple(int(meet[u][v]) for v in sixer) for u in range(27)]
agree = all(dot(lab[u], lab[v]) == meet[u][v] for u in range(27) for v in range(u + 1, 27))
print(f"Road 4: skew Fermat lines {sixer} named E1..E6; the other 21 meet "
      f"{sorted({sum(meet[u][v] for v in sixer) for u in range(27) if u not in sixer})} of them")
print(f"classes read off = the 27 of road 3: {yn(sorted(lab) == sorted(typed))}; all 351 pairs meet as the classes say: {yn(agree)}")
six = all(dot(E[i], C[j]) == (i != j) and (i == j or dot(E[i], E[j]) == 0 == dot(C[i], C[j]))
          for i in range(6) for j in range(6))
print(f"double six: Ei meets Cj exactly when i != j, E's and C's disjoint among themselves: {yn(six)}")
print(f"other blow-ups, classes with D.D = -1, K.D = -1 for n = 3..8 points: {[len(classes(n)) for n in range(3, 9)]}")
pts = [(5, 0), (3, 4), (-4, 3), (-4, -3), (0, -5), (1, 1)]
col = sum((b[0] - a[0]) * (c[1] - a[1]) == (b[1] - a[1]) * (c[0] - a[0]) for x, a in enumerate(pts)
          for y, b in enumerate(pts[x + 1:], x + 1) for c in pts[y + 1:])
print(f"figure, points {pts}, collinear triples {col}, p6 on the circle x^2 + y^2 = 25: {yn(pts[5][0] ** 2 + pts[5][1] ** 2 == 25)}")
line3 = (1, 1, 1, 1, 0, 0, 0)
split = [names[t] for t, d in enumerate(typed) if dot(d, line3) < 0]
print(f"p1, p2, p3 on a line: H - E1 - E2 - E3 has D.D = {dot(line3, line3)}, K.D = {dot(K, line3)}; "
      f"split off {' '.join(split)}, left {27 - len(split)}")
print(f"mistake 1, only exceptional curves and lines through two points: {len(E) + len(L)}")
print(f"mistake 2, lines over F_5, where 1 is the only cube root of 1: {len(lines_on(5, [1, 1, 1, 1])[1])}")
print(f"mistake 3, singular cone x^3 + y^3 + z^3 = 0: lines over F_7 {len(lines_on(7, [1, 1, 1, 0])[1])}, "
      f"over F_31 {len(lines_on(31, [1, 1, 1, 0])[1])}")
print(f"try: Fermat lines over F_11 {len(lines_on(11, [1, 1, 1, 1])[1])}, over F_13 {len(lines_on(13, [1, 1, 1, 1])[1])}")
assert len(fermat) == 27 and all(on_surface(P, Q) for P, Q, _ in fermat)   # road 1 substitutes
assert len(on7) == 27 and red == set(on7)                                   # road 2 = road 1 mod 7
assert sorted(found6) == sorted(typed)                                      # road 3: search = list
assert sorted(lab) == sorted(typed) and agree                               # road 4: Fermat = blow-up
assert g1 == ([10], 45, [1], [5])                                           # each line meets 10
assert [len(classes(n)) for n in range(3, 9)] == [6, 10, 16, 27, 56, 240]  # known del Pezzo counts
print("ALL CHECKS PASS")
