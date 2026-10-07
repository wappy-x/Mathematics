# Determinants -- the check behind the card.  Nothing is imported.  The sprite is the
# unit square, area 1, and each matrix moves its four corners.  Every determinant is found
# twice: cofactor expansion along the top row, and elimination to a staircase whose diagonal
# is multiplied.  The moved square's area is then measured a third way, off its corners.
NAMED = [("shear", [[1, 1], [0, 1]]), ("cafe", [[2, 1], [1, 1]]),
         ("stretch", [[3, 0], [0, 2]]), ("mirror", [[0, 1], [1, 0]]),
         ("flattener", [[2, 4], [1, 2]])]
M3 = [[2, 1, 1], [0, 1, 1], [1, 0, 4]]
def cofactor(M):                        # road 1: entry x its knocked-out minor
    if len(M) == 1: return float(M[0][0])
    total = 0.0
    for j in range(len(M)):
        minor = [row[:j] + row[j + 1:] for row in M[1:]]
        total += (1 if j % 2 == 0 else -1) * M[0][j] * cofactor(minor)
    return total
def staircase(M):                       # road 2: eliminate, multiply the diagonal
    A = [[float(x) for x in row] for row in M]
    n, sign = len(A), 1.0
    for c in range(n):
        p = next((r for r in range(c, n) if abs(A[r][c]) > 1e-12), None)
        if p is None: return 0.0, A     # a column of zeros: the box is already flat
        if p != c: A[c], A[p], sign = A[p], A[c], -sign
        for r in range(c + 1, n):
            f = A[r][c] / A[c][c]
            A[r] = [A[r][k] - f * A[c][k] for k in range(n)]
    for i in range(n): sign *= A[i][i]
    return sign, A
def area(a, b, c, d):                   # the moved square, measured from its corners
    P = [(0.0, 0.0), (a, c), (a + b, c + d), (b, d)]
    return abs(sum(P[i][0] * P[(i + 1) % 4][1] - P[(i + 1) % 4][0] * P[i][1] for i in range(4))) / 2
def mul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
def show2(M): return f"[[{M[0][0]}, {M[0][1]}], [{M[1][0]}, {M[1][1]}]]"
def row3(r): return "[" + ", ".join(f"{x:.1f}" for x in r) + "]"
print("the sprite is the unit square, area 1; each matrix moves its four corners")
for name, M in NAMED:
    (a, b), (c, d) = M
    print(f"  {name:<10}{show2(M):<20}ad - bc = {a * d - b * c:>2}   cofactor {cofactor(M):>5.1f}"
          f"   staircase {staircase(M)[0]:>5.1f}   area {area(a, b, c, d):>4.1f}")
S, D = NAMED[0][1], NAMED[2][1]
DS, SUM = mul(D, S), [[D[i][j] + S[i][j] for j in range(2)] for i in range(2)]
print(f"stretch after shear {show2(DS):<20}det = {cofactor(DS):.1f} = 6 x 1")
print(f"stretch plus shear  {show2(SUM):<20}det = {cofactor(SUM):.1f}, not 6 + 1 = 7")
t1 = M3[0][0] * (M3[1][1] * M3[2][2] - M3[1][2] * M3[2][1])
t2 = -M3[0][1] * (M3[1][0] * M3[2][2] - M3[1][2] * M3[2][0])
t3 = M3[0][2] * (M3[1][0] * M3[2][1] - M3[1][1] * M3[2][0])
d3, tri = staircase(M3)
print("3 by 3 [[2, 1, 1], [0, 1, 1], [1, 0, 4]]")
print(f"  cofactor along the top row: {t1:.1f} {t2:+.1f} {t3:+.1f} = {cofactor(M3):.1f}")
print(f"  staircase rows: {row3(tri[0])} {row3(tri[1])} {row3(tri[2])}")
print(f"  diagonal: {tri[0][0]:.1f} x {tri[1][1]:.1f} x {tri[2][2]:.1f} = {d3:.1f}")
print(f"mistakes on the cafe matrix: ad + bc gives {2 * 1 + 1 * 1}, the diagonal gives {2 * 1}")
print(f"mistake on the 3 by 3: all three cofactor terms added gives {t1 - t2 + t3:.1f}")
print(f"try changing: rows swapped {cofactor([[1, 1], [2, 1]]):.1f}, corner 2.1 {cofactor([[2, 4], [1, 2.1]]):.1f}, "
      f"3 by 3 top row doubled {cofactor([[4, 2, 2]] + M3[1:]):.1f}")
assert [cofactor(M) for _, M in NAMED] == [1.0, 1.0, 6.0, -1.0, 0.0]
assert all(abs(staircase(M)[0] - cofactor(M)) < 1e-12 and
           abs(area(M[0][0], M[0][1], M[1][0], M[1][1]) - abs(cofactor(M))) < 1e-12 for _, M in NAMED)
assert cofactor(M3) == 8.0 and abs(d3 - 8.0) < 1e-12 and tri[2][2] == 4.0
assert cofactor(DS) == 6.0 == cofactor(D) * cofactor(S) and cofactor(SUM) == 12.0
print("ALL CHECKS PASS")
