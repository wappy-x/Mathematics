# The inverse matrix -- the check behind the card.  Nothing is imported.  The cafe's
# counts matrix is inverted two ways: by the 2 by 2 swap-negate-divide formula, and by
# Gauss-Jordan on [A | I], the road that also handles the three-item matrix.
A2 = [[2.0, 1.0], [1.0, 1.0]]        # Mon: 2 coffees + 1 pastry.  Tue: 1 and 1.
B2 = [11.0, 7.0]                     # what the till held on those two days
A3 = [[2.0, 1.0, 1.0], [1.0, 1.0, 1.0], [1.0, 2.0, 1.0]]   # three days, three items
B3 = [17.0, 13.0, 16.0]              # the three days' takings, in dollars
S = [[2.0, 4.0], [1.0, 2.0]]         # the singular one: row two is half of row one
def num(v):  return f"{v if abs(v) > 1e-9 else 0.0:.0f}"   # tiny float dust prints as 0
def mat(m):  return "[" + ", ".join("[" + ", ".join(num(v) for v in r) + "]" for r in m) + "]"
def vec(v):  return "(" + ", ".join(num(x) for x in v) + ")"
def near(u, w): return all(abs(a - b) < 1e-9 for a, b in zip(u, w))
def mul(a, b): return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))] for i in range(len(a))]
def mv(a, v):  return [sum(a[i][k] * v[k] for k in range(len(v))) for i in range(len(a))]
def det2(m):   return m[0][0] * m[1][1] - m[0][1] * m[1][0]
def flip(m):   return [[m[1][1], -m[0][1]], [-m[1][0], m[0][0]]]     # swap and negate
def det3(m):   return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] *
    (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))

def inverse(a):                                        # Gauss-Jordan on [A | I]
    n = len(a)
    m = [list(a[i]) + [1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(m[r][c]))
        if abs(m[p][c]) < 1e-12: return None           # a flattened column: no inverse
        m[c], m[p] = m[p], m[c]
        d = m[c][c]
        m[c] = [v / d for v in m[c]]
        for r in range(n):
            if r != c:
                f = m[r][c]
                m[r] = [v - f * w for v, w in zip(m[r], m[c])]
    return [row[n:] for row in m]

d2, gj2 = det2(A2), inverse(A2)                        # road two: Gauss-Jordan
formula = [[v / d2 for v in row] for row in flip(A2)]  # road one: swap, negate, divide
x2 = mv(formula, B2)
cram = [det2([[B2[0], A2[0][1]], [B2[1], A2[1][1]]]) / d2, det2([[A2[0][0], B2[0]], [A2[1][0], B2[1]]]) / d2]
print(f"cafe matrix A = {mat(A2)}   determinant = {num(d2)}")
print(f"A^-1 by swap, negate, divide  = {mat(formula)}")
print(f"A^-1 by Gauss-Jordan on [A|I] = {mat(gj2)}")
print(f"A times A^-1 = {mat(mul(A2, formula))}   A^-1 times A = {mat(mul(formula, A2))}")
print(f"takings {vec(B2)} -> prices x = A^-1 b = {vec(x2)}")
print(f"the same prices by Cramer's rule: {vec(cram)}")
print(f"and back the other way, A x = {vec(mv(A2, x2))}")
d3, gj3 = det3(A3), inverse(A3)
x3 = mv(gj3, B3)
print(f"three items, A = {mat(A3)}   determinant = {num(d3)}")
print(f"A^-1 by Gauss-Jordan on [A|I] = {mat(gj3)}")
print(f"A times A^-1 = {mat(mul(A3, gj3))}")
print(f"takings {vec(B3)} -> prices x = {vec(x3)}")
print(f"mistake, no swap: prices come out {vec(mv([[2.0, -1.0], [-1.0, 1.0]], B2))}")
print(f"mistake, no minus signs: prices come out {vec(mv([[1.0, 1.0], [1.0, 2.0]], B2))}")
print(f"mistake, no divide by the determinant: prices come out {vec(mv([[v * d3 for v in r] for r in gj3], B3))}")
print(f"singular {mat(S)}: determinant = {num(det2(S))}, swap-and-flip times it = {mat(mul(flip(S), S))}, no inverse")
assert near(x2, [4.0, 3.0]) and near(cram, [4.0, 3.0]) and near(mv(A2, x2), B2)
assert near(formula[0] + formula[1], gj2[0] + gj2[1]) and near(mul(A2, gj2)[0] + mul(A2, gj2)[1], [1.0, 0.0, 0.0, 1.0])
assert near(x3, [4.0, 3.0, 6.0]) and near(mv(A3, x3), B3) and d3 == -1.0
assert inverse(S) is None and det2(S) == 0.0
print("ALL CHECKS PASS")
