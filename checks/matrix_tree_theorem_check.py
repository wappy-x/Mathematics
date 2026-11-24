# The matrix-tree theorem -- the check behind the card.  Nothing is imported.  Switches P, Q, R, W, cables every
# pair but R-W: trees by listing, cut determinant, Cauchy-Binet, eigenvalues; then the R-W resistance.
def det(M):                              # cofactor expansion along the top row
    return sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M))) if M else 1
def choose(items, k):                    # every k-element subset, in order
    return [[]] if k == 0 else [] if len(items) < k else [[items[0]] + c for c in choose(items[1:], k - 1)] + choose(items[1:], k)
def is_tree(n, cables):                  # n - 1 cables, and a flood from switch 0 reaches all
    seen, todo = {0}, [0]
    while todo:
        u = todo.pop()
        for y in [b for a, b in cables if a == u] + [a for a, b in cables if b == u]:
            if y not in seen: seen.add(y); todo.append(y)
    return len(cables) == n - 1 and len(seen) == n
def laplacian(n, cables):                # L = D - A
    L = [[0] * n for _ in range(n)]
    for a, b in cables: L[a][a] += 1; L[b][b] += 1; L[a][b] -= 1; L[b][a] -= 1
    return L
def charpoly(L):                         # Faddeev-LeVerrier: coefficients of det(xI - L)
    n, c, M = len(L), [1], [[0] * len(L) for _ in L]
    for k in range(1, n + 1):
        M = [[sum(L[i][t] * M[t][j] for t in range(n)) + (c[-1] if i == j else 0) for j in range(n)] for i in range(n)]
        c.append(-sum(L[i][t] * M[t][i] for i in range(n) for t in range(n)) // k)
    return c

cut = lambda L, i: [r[:i] + r[i + 1:] for k, r in enumerate(L) if k != i]
name = lambda s: " ".join("PQRW"[a] + "PQRW"[b] for a, b in s)
Kn = lambda k: laplacian(k, choose(list(range(k)), 2))               # every pair cabled
n, cables = 4, [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3)]
L, sets = laplacian(n, cables), choose(cables, n - 1)
L0, trees = cut(L, 0), [s for s in sets if is_tree(n, s)]
M0 = [[(1 if j == a else -1 if j == b else 0) for j in range(1, n)] for a, b in cables]   # column P cut
squares = [det([M0[cables.index(e)] for e in s]) ** 2 for s in sets]
MtM = [[sum(r[i] * r[j] for r in M0) for j in range(n - 1)] for i in range(n - 1)]
eig = [(0, [1, 1, 1, 1]), (2, [0, 0, 1, -1]), (4, [1, -1, 0, 0]), (4, [1, 1, -1, -1])]
eig_ok = all([sum(p * x for p, x in zip(r, v)) for r in L] == [lam * x for x in v] for lam, v in eig)
prod, cp, K4, cp4 = eig[1][0] * eig[2][0] * eig[3][0], charpoly(L), Kn(4), charpoly(Kn(4))
terms = [(-1) ** j * L0[0][j] * det([r[:j] + r[j + 1:] for r in L0[1:]]) for j in range(3)]   # 12, -2, -2
merged, amps = det(cut(cut(L, 3), 2)), [sum(p * x for p, x in zip(r, [0, 0, 1, -1])) for r in L]   # R, W cut; 1 V, -1 V
print(f"switches P Q R W; cables {name(cables)}; degrees {[L[i][i] for i in range(n)]}")
print(f"Laplacian L = D - A, rows {L}; row sums {[sum(r) for r in L]}")
print(f"cut row and column P: {L0}; determinant {terms[0]} - {-terms[1]} - {-terms[2]} = {det(L0)}")
print(f"cut P, Q, R, W in turn: {[det(cut(L, i)) for i in range(n)]}; nothing cut: {det(L)}")
print(f"listing: {len(sets)} choices of 3 cables, {len(trees)} trees; loops: {', '.join(name(s) for s in sets if s not in trees)}")
print(f"signed incidence M, column P cut: M^T M equals the cut Laplacian: {'yes' if MtM == L0 else 'no'}")
print(f"Cauchy-Binet, det(M_S)^2 over the {len(sets)} sets: {squares}, total {sum(squares)}")
print(f"eigenvalues {[e[0] for e in eig]} checked by L v = lambda v: {'yes' if eig_ok else 'no'}; {prod}/{n} = {prod // n}")
print(f"det(xI - L) coefficients {cp}; x coefficient {cp[-2]}, so {-cp[-2]}/{n} = {-cp[-2] // n}")
print(f"add R-W, the full K4: cut determinant {det(cut(K4, 0))}; det(xI - L) coefficients {cp4}, so {-cp4[-2]}/4 = {-cp4[-2] // 4}")
rows = [(k, det(cut(Kn(k), 0)), sum(is_tree(k, s) for s in choose(choose(list(range(k)), 2), k - 1)), charpoly(Kn(k)), [len(choose(list(range(k - 1)), j)) * (-k) ** j for j in range(k)] + [0]) for k in range(2, 8)]   # x(x - k)^(k-1)
for k, d, t, c, e in rows: print(f"K{k}: cut determinant {d}, listed {t}, n^(n-2) {k ** (k - 2)}; det(xI - L) = x(x - {k})^{k - 1}: {'yes' if c == e else 'no'}")
print(f"1-ohm cables, R to W: trees with R and W merged {merged}, over {len(trees)} trees = {merged / len(trees):g} ohm; 1 V at R, -1 V at W: currents {amps}, 2 V / {amps[2]} A = {2 / amps[2]:g} ohm")
print(f"mistake 1, diagonal only {L0[0][0]}*{L0[1][1]}*{L0[2][2]} = {L0[0][0] * L0[1][1] * L0[2][2]}; mistake 2, eigenvalues not divided by n: {prod}")
print(f"mistake 3, Cayley's 4^2 here: {4 ** 2}, not {len(trees)}; mistake 4, signs dropped on K4: {det(cut([[abs(x) for x in r] for r in K4], 0))}, not {det(cut(K4, 0))}")
assert det(L0) == len(trees) == sum(squares) and MtM == L0       # three roads agree
assert all(det(cut(L, i)) == len(trees) for i in range(n))       # any row and column
assert eig_ok and prod == -cp[-2] == n * len(trees)              # the eigenvalue roads, exactly
assert all(d == t == k ** (k - 2) and c == e and (-1) ** (k - 1) * c[-2] == k * t for k, d, t, c, e in rows)   # Cayley, three roads
assert det(cut(K4, 0)) == rows[2][2] and -cp4[-2] == 4 * rows[2][2] and det(cut([[abs(x) for x in r] for r in K4], 0)) == 20
assert amps == [0, 0, amps[2], -amps[2]] and merged * amps[2] == 2 * len(trees)              # resistance, two roads
print("ALL CHECKS PASS")
