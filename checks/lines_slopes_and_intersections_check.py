# Lines, slopes and intersections -- the check behind the card.  Nothing is
# imported.  A city grid in km, x east and y north, the depot D at (0, 0).
# Route A runs D to E; route B runs Q to R; ring road C runs beside route A.
# The junction is found by two roads that share no arithmetic.
D, E, Q, R, C0, C1 = (0, 0), (10, 5), (3, 9), (7, 1), (0, 5), (10, 10)
A, B, C = (1, -2, 0), (2, 1, 15), (1, -2, -10)   # a, b, p in ax + by = p

def slope(P1, P2):                  # rise over run, same point order in both
    return (P2[1] - P1[1]) / (P2[0] - P1[0])

def cross(L1, L2):                  # the crossing number ad - bc
    return L1[0] * L2[1] - L1[1] * L2[0]

def meet(L1, L2):                   # road one: the crossing-number formula
    (a, b, p), (c, d, q) = L1, L2
    return (p * d - b * q) / cross(L1, L2), (a * q - c * p) / cross(L1, L2)

def side(L, x, y):                  # sign says which side of line L a point is on
    return L[0] * x + L[1] * y - L[2]

def sq(P1, P2):                     # squared distance, from the distance formula
    return (P2[0] - P1[0]) ** 2 + (P2[1] - P1[1]) ** 2

lo, hi = 0.0, 1.0                   # road two: halve route A until B is crossed
for _ in range(60):
    mid = (lo + hi) / 2
    if side(B, 0, 0) * side(B, 10 * mid, 5 * mid) > 0: lo = mid
    else: hi = mid
t = (lo + hi) / 2
J = meet(A, B)
s = (J[0] - Q[0]) / (R[0] - Q[0])
mA, mB, mC = slope(D, E), slope(Q, R), slope(C0, C1)
kA, kB, kC = D[1] - mA * D[0], Q[1] - mB * Q[0], C0[1] - mC * C0[0]
gaps = [(mC * x + kC) - (mA * x + kA) for x in (0, 4, 8)]
dj, jq, dq = sq(D, J), sq(J, Q), sq(D, Q)
f = lambda v: f"{v:g}"
px = lambda P: f"({f(round(40 + 20 * P[0], 1))}, {f(round(210 - 20 * P[1], 1))})"
u = 0.4 / 5 ** 0.5                  # 8 drawing units along each road, in km
mark = [(J[0] + 2 * u, J[1] + u), (J[0] + u, J[1] + 3 * u), (J[0] - u, J[1] + 2 * u)]
print(f"slopes from two points: A {f(mA)}, B {f(mB)}, C {f(mC)}; north-axis crossings {f(kA)}, {f(kB)}, {f(kC)}")
print(f"slopes from general form, -a/b: A {f(-A[0] / A[1])}, B {f(-B[0] / B[1])}, C {f(-C[0] / C[1])}")
print(f"crossing number A with B: {cross(A, B)}; A with ring road C: {cross(A, C)}")
print(f"junction by the formula: x = {A[2] * B[1] - A[1] * B[2]}/{cross(A, B)} = {f(J[0])}, y = {A[0] * B[2] - B[0] * A[2]}/{cross(A, B)} = {f(J[1])}")
print(f"junction by halving route A: t = {t:.6f}, point ({10 * t:.6f}, {5 * t:.6f})")
print(f"route A put into B: {B[0] * E[0] + B[1] * E[1]}t = {B[2]}, t = {f(B[2] / (B[0] * E[0] + B[1] * E[1]))}; on route B s = {f(s)}")
print(f"slope product A x B: {f(mA * mB)}; step dot product (10, 5).(4, -8) = {(E[0] - D[0]) * (R[0] - Q[0]) + (E[1] - D[1]) * (R[1] - Q[1])}")
print(f"Pythagoras: DJ^2 = {f(dj)}, JQ^2 = {f(jq)}, DQ^2 = {f(dq)}")
print(f"ring road C above route A at x = 0, 4, 8: {', '.join(f(g) for g in gaps)} km")
print(f"ring road C meets route B at ({f(meet(C, B)[0])}, {f(meet(C, B)[1])}), s = {f((meet(C, B)[0] - Q[0]) / (R[0] - Q[0]))}")
print(f"street x = 2 meets route A at ({f(meet(A, (1, 0, 2))[0])}, {f(meet(A, (1, 0, 2))[1])}); crossing number {cross(A, (1, 0, 2))}")
print(f"mistake 1, run over rise: slope {f(10 / 5)}, junction ({f(meet((2, -1, 0), B)[0])}, {f(meet((2, -1, 0), B)[1])})")
print(f"mistake 2, perpendicular to B as 1/m: slope {f(1 / mB)}, step dot product (1, -2).(1, -0.5) = {f(1 + mB * (1 / mB))}")
print(f"mistake 3, point order mixed on B: {R[1] - Q[1]}/{Q[0] - R[0]} = {f((R[1] - Q[1]) / (Q[0] - R[0]))}")
print(f"figure, 20 units per km: D {px(D)} E {px(E)} Q {px(Q)} R {px(R)} J {px(J)} C {px(C0)} to {px((8, 9))}")
print(f"figure, right-angle marker {' '.join(px(P) for P in mark)}")
assert abs(J[0] - 10 * t) < 1e-9 and abs(J[1] - 5 * t) < 1e-9        # two roads, one junction
assert mA * mB == -1 and dj + jq == dq                              # right angle two ways
assert cross(A, C) == 0 and gaps == [5, 5, 5]                       # parallel two ways
assert [mA, mB, mC] == [-L[0] / L[1] for L in (A, B, C)]            # two points vs general form
print("ALL CHECKS PASS")
