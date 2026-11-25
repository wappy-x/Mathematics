# Cayley-Hamilton and the minimal polynomial -- the check behind the card.  Nothing is imported; whole numbers only.
A, D = [[2, 1, 0], [0, 2, 0], [0, 0, 3]], [[2, 0, 0], [0, 2, 0], [0, 0, 3]]
M, F = [[2, -1, 0, 3], [1, 0, 4, 1], [0, 5, -2, 2], [3, 1, 1, 1]], [[8, 3], [2, 7]]   # no pattern; the fleet times 10
def eye(n, c=1): return [[c * (i == j) for j in range(n)] for i in range(n)]
def mul(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def add(X, Y, c=1): return [[x + c * y for x, y in zip(r, s)] for r, s in zip(X, Y)]
def big(X): return max(abs(x) for r in X for x in r)
def yn(claim): return "yes" if claim else "no"
def at(p, X):                  # Horner: put the matrix in for x; a constant c becomes c I
    return eye(len(X), p[0]) if len(p) == 1 else add(mul(at(p[:-1], X), X), eye(len(X), p[-1]))
def charpoly(X):               # road one, Faddeev-LeVerrier: traces only, no roots
    n, p, N = len(X), [1], eye(len(X), 0)
    for k in range(1, n + 1):
        N = add(mul(X, N), eye(n, p[-1]))
        p.append(-sum(mul(X, N)[i][i] for i in range(n)) // k)
    return p
def det(X):                    # road two, expansion along the top row
    return X[0][0] if len(X) == 1 else sum((-1) ** j * X[0][j] * det([r[:j] + r[j + 1:] for r in X[1:]]) for j in range(len(X)))
def pmul(p, q): return [sum(p[i] * q[k - i] for i in range(len(p)) if 0 <= k - i < len(q)) for k in range(len(p) + len(q) - 1)]
def pdiv(p, m):                # long division by a monic m: quotient, remainder
    p, q = list(p), []
    while len(p) >= len(m): q.append(p[0]); p = [a - p[0] * b for a, b in zip(p, m + [0] * len(p))][1:]
    return q, p
def repeated(p): return any(big(at(p, [[t]])) == 0 == big(at([c * (len(p) - 1 - i) for i, c in enumerate(p[:-1])], [[t]])) for t in (2, 3))   # roots 2, 3 only
def rank(rows):                # elimination in whole numbers: cross-multiply, never divide
    rows = [r for r in rows if any(r)]
    if not rows: return 0
    p = rows[0]; c = next(j for j, x in enumerate(p) if x)
    return 1 + rank([[p[c] * x - r[c] * y for x, y in zip(r, p)] for r in rows[1:]])
def minpoly(X):                # road one: divisors of (x - 2)^2 (x - 3), lowest degree first
    return next(p for p in (pmul([1, -2], [1, -3]), pmul([1, -2], pmul([1, -2], [1, -3]))) if big(at(p, X)) == 0)
def krylov(X):                 # road two: the first power that is a mix of the lower ones
    P = [eye(3)]
    while rank([sum(Q, []) for Q in P]) == len(P): P.append(mul(X, P[-1]))
    return len(P) - 1
def vecs(X): return [3 - rank(add(X, eye(3), -t)) for t in (2, 3)]   # eigenvectors for 2 and for 3
pA, pD, pM, mA, mD, tri = charpoly(A), charpoly(D), charpoly(M), minpoly(A), minpoly(D), pmul([1, -2], pmul([1, -2], [1, -3]))
S, T, (q, r), x4 = add(A, eye(3), -2), add(A, eye(3), -3), pdiv(pD, mD), pdiv([1, 0, 0, 0, 0], mD)[1]
cols = [sum(all(row[j] == 0 for row in X) for j in range(3)) for X in (S, mul(S, S), mul(mul(S, S), T))]
inv12, fleet, D4 = at([1, -7, 16], A), add(mul(F, F), F, -15), mul(mul(D, D), mul(D, D))
print(f"A: characteristic polynomial by traces {pA}; from the diagonal 2, 2, 3: {tri}")
print(f"zero columns: after (A - 2I) {cols[0]}, after (A - 2I)^2 {cols[1]}, after (A - 2I)^2 (A - 3I) {cols[2]}; p(A) largest entry: {big(at(pA, A))}")
print(f"4 by 4 M: characteristic polynomial {pM}, det by expansion {det(M)}; p(M) largest entry: {big(at(pM, M))}")
print(f"D: characteristic polynomial {pD}; p_D divided by m_D: quotient {q}, remainder {r}")
print(f"minimal polynomial by divisor search: A {mA}, D {mD}; degree by first repeating power: A {krylov(A)}, D {krylov(D)}")
print(f"repeated root in the minimal polynomial: A {yn(repeated(mA))}, D {yn(repeated(mD))}")
print(f"eigenvectors for 2 and 3, by 3 minus rank: A {vecs(A)}, D {vecs(D)}; diagonalisable: A {yn(sum(vecs(A)) == 3)}, D {yn(sum(vecs(D)) == 3)}")
print(f"x^4 divided by m_D leaves {x4}; D^4 = 65D - 114I: {yn(D4 == add(eye(3, -114), D, 65))}")
print(f"12 A^-1 = A^2 - 7A + 16I = {inv12}; times A gives 12 I: {yn(mul(inv12, A) == eye(3, 12))}")
print(f"tenth powers, top row: A^10 {at([1] + [0] * 10, A)[0]}, D^10 {at([1] + [0] * 10, D)[0]}")
print(f"fleet F: characteristic polynomial {[c / 10 ** k for k, c in enumerate(charpoly(F))]}; F^2 - 1.5F + 0.5I largest entry: {big(add(fleet, eye(2, 50))) / 100}")
print(f"mistake 1, (A - 2I)(A - 3I) = {mul(S, T)}, not zero")
print(f"mistake 2, the trace through the same substitution: 3A - 7I = {add(eye(3, -7), A, 3)}")
print(f"mistake 3, fleet with 0.5 added to every entry: {[[(x + 50) / 100 for x in row] for row in fleet]}")
assert pA == tri and pM[-1] == det(M) and pM[1] == -sum(M[i][i] for i in range(4))  # traces against diagonal, det, trace
assert big(at(pA, A)) == 0 and big(at(pM, M)) == 0 and cols == [1, 2, 3] and big(add(fleet, eye(2, 50))) == 0  # Cayley-Hamilton
assert [len(mA) - 1, len(mD) - 1] == [krylov(A), krylov(D)] == [3, 2] and r == [0, 0]  # two roads to the degree
assert [sum(vecs(X)) == 3 for X in (A, D)] == [not repeated(m) for m in (mA, mD)]   # the diagonalisability test
assert D4 == add(eye(3, x4[1]), D, x4[0]) and mul(inv12, A) == eye(3, 12)          # remainders against brute force
print("ALL CHECKS PASS")
