# Change of basis -- the check behind the card.  Nothing is imported.  A game map
# is drawn on a diagonal grid whose axes are b1 = (1, 1) and b2 = (-1, 1), and P
# carries those two axes as its columns.  The treasure at (5, 3) is given its
# diagonal address, and the shear [[1, 1], [0, 1]] is rewritten on that grid.  Two
# methods all the way: the 2 by 2 inverse formula, and elimination, which builds no
# inverse at all.
def det(A): return A[0][0] * A[1][1] - A[0][1] * A[1][0]
def tr(A): return A[0][0] + A[1][1]
def mul(A, B):                                   # 2 by 2 times 2 by 2
    return [[A[i][0] * B[0][j] + A[i][1] * B[1][j] for j in (0, 1)] for i in (0, 1)]
def act(A, v):                                   # 2 by 2 times a column
    return [A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1]]
def inv(A):                                      # method one: the 2 by 2 inverse
    d = det(A)
    return [[A[1][1] / d, -A[0][1] / d], [-A[1][0] / d, A[0][0] / d]]
def solve(A, v):                                 # method two: elimination, no inverse
    f = A[1][0] / A[0][0]                        # clear the lower-left entry
    y = (v[1] - f * v[0]) / (A[1][1] - f * A[0][1])
    return [(v[0] - A[0][1] * y) / A[0][0], y]
def mat(A): return f"[[{A[0][0]:g}, {A[0][1]:g}], [{A[1][0]:g}, {A[1][1]:g}]]"
def col(v): return f"({v[0]:g}, {v[1]:g})"
def row(label, value): print(f"{label:<44}{value}")

b1, b2 = [1.0, 1.0], [-1.0, 1.0]                 # the diagonal grid's two axes
P = [[b1[0], b2[0]], [b1[1], b2[1]]]             # the new axes down the columns
Pi = inv(P)
A = [[1.0, 1.0], [0.0, 1.0]]                     # the shear, on the standard grid
Ad = mul(Pi, mul(A, P))                          # the shear, on the diagonal grid
shr = [solve(P, act(A, [P[0][j], P[1][j]])) for j in (0, 1)]   # sheared axes, new coords
Ad2 = [[shr[0][0], shr[1][0]], [shr[0][1], shr[1][1]]]
v, w = [5.0, 3.0], [2.0, 6.0]                    # the treasure, and a second one
c, cw = act(Pi, v), act(Pi, w)                   # their diagonal addresses
rebuilt = [c[0] * b1[i] + c[1] * b2[i] for i in (0, 1)]
Prow = [[b1[0], b1[1]], [b2[0], b2[1]]]          # the new axes written as rows
PAPi = mul(P, mul(A, Pi))                        # the sandwich, built backwards
wrongs = [act(P, v), act(inv(Prow), v), act(PAPi, c)]

row("P, the new axes down its columns", f"{mat(P)}   det {det(P):g}")
row("P inverse, by the 2 by 2 formula", mat(Pi))
row("P times (1, 0), must be the first new axis", col(act(P, [1.0, 0.0])))
row("treasure: standard, then diagonal address", f"{col(v)}  ->  {col(c)}")
row("the same diagonal address, by elimination", col(solve(P, v)))
row("rebuilt as 4 b1 - 1 b2", col(rebuilt))
row("A, the shear on the standard grid", f"{mat(A)}   trace {tr(A):g}   area {det(A):g}")
row("A P, the shear sent through the new axes", mat(mul(A, P)))
row("P^-1 A P, the shear on the diagonal grid", f"{mat(Ad)}   trace {tr(Ad):g}   area {det(Ad):g}")
row("the same matrix, by elimination", mat(Ad2))
row("road 1: shear, then convert", f"A v = {col(act(A, v))}  ->  {col(act(Pi, act(A, v)))}")
row("road 2: convert, then shear", col(act(Ad, c)))
row("second treasure: standard, then diagonal", f"{col(w)}  ->  {col(cw)}")
row("second treasure, road 1", f"A w = {col(act(A, w))}  ->  {col(act(Pi, act(A, w)))}")
row("second treasure, road 2", col(act(Ad, cw)))
row("wrong: P v instead of P^-1 v", col(wrongs[0]))
row("wrong: the new axes written as rows", col(wrongs[1]))
row("wrong: P A P^-1 sends (4, -1) to", col(wrongs[2]))
assert c == [4.0, -1.0] and solve(P, v) == c and rebuilt == v
assert Ad == [[1.5, 0.5], [-0.5, 0.5]] and Ad2 == Ad and det(Ad) == det(A) and tr(Ad) == tr(A)
assert act(Pi, act(A, v)) == [5.5, -2.5] == act(Ad, c) and act(Pi, act(A, w)) == [7.0, -1.0] == act(Ad, cw)
assert wrongs == [[2.0, 8.0], [1.0, 4.0], [1.5, -3.5]]
print("ALL CHECKS PASS")
