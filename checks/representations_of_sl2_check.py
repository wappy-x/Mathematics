# Representations of sl(2) -- the check behind the card.  Standard library only.
# V_n is built from the ladder rules, its brackets and Casimir are checked by
# matrix products, and each tensor product is split by two roads that share no
# step: peeling highest weights off the list of weights, and counting the
# Casimir's eigenvectors by exact integer ranks.  Spin 1 is V_2, spin 1/2 is V_1.

def rep(n):                              # basis v_0..v_n; v_k has weight n - 2k
    d = range(n + 1)
    H = [[n - 2 * i if i == j else 0 for j in d] for i in d]
    E = [[j * (n - j + 1) if i == j - 1 else 0 for j in d] for i in d]
    F = [[1 if i == j + 1 else 0 for j in d] for i in d]
    return H, E, F                       # E v_k = k(n-k+1) v_(k-1),  F v_k = v_(k+1)

def mul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))]
            for i in range(len(A))]

def lin(a, A, b, B):                     # a A + b B
    return [[a * x + b * y for x, y in zip(r, s)] for r, s in zip(A, B)]

def eye(d):
    return [[1 if i == j else 0 for j in range(d)] for i in range(d)]

def br(A, B):                            # the bracket [A, B] = AB - BA
    return lin(1, mul(A, B), -1, mul(B, A))

def casimir(H, E, F):                    # C = H^2 + 2EF + 2FE
    return lin(1, mul(H, H), 2, lin(1, mul(E, F), 1, mul(F, E)))

def kron(A, B):
    return [[a * b for a in ra for b in rb] for ra in A for rb in B]

def tensor(R, S):                        # X acts on V (x) W as X (x) 1 + 1 (x) X
    return tuple(lin(1, kron(X, eye(len(Y))), 1, kron(eye(len(X)), Y)) for X, Y in zip(R, S))

def gcd(a, b):
    while b:
        a, b = b, a % b
    return abs(a)

def rank(M):                             # fraction-free elimination on integers
    M, r = [row[:] for row in M], 0
    for c in range(len(M[0])):
        p = next((i for i in range(r, len(M)) if M[i][c]), None)
        if p is None:
            continue
        M[r], M[p] = M[p], M[r]
        for i in range(r + 1, len(M)):
            row = [M[r][c] * x - M[i][c] * y for x, y in zip(M[i], M[r])]
            g = 0
            for x in row:
                g = gcd(g, x)
            M[i] = [x // g for x in row] if g else row
        r += 1
    return r

def peel(ws):                            # road 1: strip whole ladders off the top
    ws, tops = sorted(ws), []
    while ws:
        top = ws[-1]
        tops.append(top)
        for w in range(top, -top - 1, -2):
            ws.remove(w)
    return tops

def by_casimir(R):                       # road 2: pieces V_n = dim ker(C - n(n+2)) / (n+1)
    C, d, tops = casimir(*R), len(R[0]), []
    for n in range(d - 1, -1, -1):
        k = d - rank(lin(1, C, -n * (n + 2), eye(d)))
        tops += [n] * (k // (n + 1))
        assert k % (n + 1) == 0
    return tops

def diag(M):
    return [M[i][i] for i in range(len(M))]

H, E, F = rep(2)
print("spin 1 = V_2, basis v_0, v_1, v_2")
print("H rows:", H, "  E rows:", E, "  F rows:", F)
print("E v_k = k(n-k+1) v_(k-1), coefficients for k = 1, 2:", [k * (2 - k + 1) for k in (1, 2)])
print("EF diagonal:", diag(mul(E, F)), "  FE diagonal:", diag(mul(F, E)), "  [E,F] diagonal:", diag(br(E, F)))
ok = all(br(R[0], R[1]) == lin(2, R[1], 0, R[1]) and br(R[0], R[2]) == lin(-2, R[2], 0, R[2])
         and br(R[1], R[2]) == R[0] for R in map(rep, range(7)))
print("[H,E] = 2E, [H,F] = -2F, [E,F] = H for n = 0..6:", "yes" if ok else "no")
for n in range(5):
    c = casimir(*rep(n))
    spin = str(n // 2) if n % 2 == 0 else f"{n}/2"
    same = "yes" if c == lin(c[0][0], eye(n + 1), 0, eye(n + 1)) else "no"
    print(f"V_{n}: dim {n + 1}, spin {spin}, weights {diag(rep(n)[0])}, C = {c[0][0]} on every vector: "
          f"{same}, j(j+1) = C/4 = {c[0][0] / 4:.2f}")
signs = []
for n in range(5):                       # e^(i pi H) multiplies a weight-w vector by (-1)^w
    s = {1 - 2 * (w % 2) for w in diag(rep(n)[0])}
    signs.append(s.pop() if len(s) == 1 else 0)
print("a full turn, e^(i pi H), multiplies all of V_n by one sign, n = 0..4:", signs)
cases = [("V_1 x V_1, two spin-1/2 quarks", [1, 1]), ("V_2 x V_1, spin 1 with spin 1/2", [2, 1]),
         ("V_1 x V_1 x V_1, three quarks", [1, 1, 1])]
found = []
for name, parts in cases:
    R = rep(parts[0])
    for m in parts[1:]:
        R = tensor(R, rep(m))
    ws, cas = sorted(diag(R[0]), reverse=True), casimir(*R)
    a, b = peel(ws), by_casimir(R)
    found.append((a, b))
    eig = ", ".join(f"{n * (n + 2)} on {len(ws) - rank(lin(1, cas, -n * (n + 2), eye(len(ws))))} vectors"
                    for n in sorted(set(a), reverse=True))
    print(f"{name}: dim {len(ws)}, weights {ws}")
    print(f"  peeled tops {a}; Casimir {eig}; pieces by Casimir {b}")
    print("  =", " + ".join(f"V_{n}" for n in a), " dims", " + ".join(str(n + 1) for n in a), "=", sum(n + 1 for n in a))
lam = 1.5
print("mistake 1, top weight 1.5: E F^k v_0 coefficients k(1.5-k+1), k = 1..5:",
      ", ".join(f"{k * (lam - k + 1):.1f}" for k in range(1, 6)), "-- never 0, no top rung")
print("  top weight 2 for contrast:", ", ".join(f"{k * (2 - k + 1):.1f}" for k in range(1, 4)))
E1 = [[1 if i == j - 1 else 0 for j in range(3)] for i in range(3)]
print("mistake 2, every E coefficient 1: diagonal of [E,F] =", diag(br(E1, F)), "but H =", diag(H))
print("mistake 3, dimensions added: 3 + 2 =", len(H) + len(rep(1)[0]), "but V_2 x V_1 has", len(tensor(rep(2), rep(1))[0]))
print("mistake 4, list stepping by 1: V_3 + V_2 + V_1 has", sum(len(rep(n)[0]) for n in (3, 2, 1)), "dims, not 6")
assert ok and diag(mul(E, F)) == [2, 2, 0] and diag(mul(F, E)) == [0, 2, 2]
assert all(casimir(*rep(n)) == lin(n * (n + 2), eye(n + 1), 0, eye(n + 1)) for n in range(7))
assert all(a == b for a, b in found)               # peeling agrees with the Casimir count
assert [a for a, b in found] == [[2, 0], [3, 1], [3, 1, 1]]
assert signs == [1, -1, 1, -1, 1]                 # a full turn is +1 or -1 on a whole ladder
assert br(E1, F) != H                             # unit E coefficients break [E, F] = H
assert all(k * (lam - k + 1) != 0 for k in range(1, 40))   # a top of 1.5 never stops
print("ALL CHECKS PASS")
