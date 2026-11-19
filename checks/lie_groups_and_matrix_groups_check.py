# Lie group: a group that is also a smooth manifold -- the check behind the card.
# Standard library only.  A drone's orientation is a 3 x 3 rotation matrix R,
# axes north, east, down.  The set of all of them, SO(3), is shown to be a group
# and a smooth 3-dimensional manifold.  The dimension comes by three roads:
# road 1 counts free entries, 9 minus the rank of the constraint's derivative;
# roads 2 and 3 count the independent directions of two different charts.
import math
D = math.pi / 180

def mul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]
def tp(A):
    return [list(r) for r in zip(*A)]
def eye(n):
    return [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
def rx(a):
    return [[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]]
def ry(a):
    return [[math.cos(a), 0, math.sin(a)], [0, 1, 0], [-math.sin(a), 0, math.cos(a)]]
def rz(a):
    return [[math.cos(a), -math.sin(a), 0], [math.sin(a), math.cos(a), 0], [0, 0, 1]]
def euler(x):                              # chart A: yaw, pitch, roll, in radians
    return mul(rz(x[0]), mul(ry(x[1]), rx(x[2])))
def rodrigues(v):                          # chart B: axis times angle, in radians
    t = math.sqrt(sum(c * c for c in v))
    if t == 0:
        return eye(3)
    x, y, z = (c / t for c in v)
    K = [[0, -z, y], [z, 0, -x], [-y, x, 0]]
    K2 = mul(K, K)
    return [[(i == j) + math.sin(t) * K[i][j] + (1 - math.cos(t)) * K2[i][j] for j in range(3)] for i in range(3)]
def axis_angle(R):                         # the inverse of chart B, valid for angles below 180 degrees
    t = math.acos((R[0][0] + R[1][1] + R[2][2] - 1) / 2)
    s = 2 * math.sin(t)
    return [t * (R[2][1] - R[1][2]) / s, t * (R[0][2] - R[2][0]) / s, t * (R[1][0] - R[0][1]) / s]
def det3(A):
    return (A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1]) - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
            + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]))
def residual(R):                           # size of R^T R - I, zero exactly on O(n)
    P, n = mul(tp(R), R), len(R)
    return math.sqrt(sum((P[i][j] - (i == j)) ** 2 for i in range(n) for j in range(n)))
def rank(rows, tol=1e-7):                  # Gaussian elimination with partial pivoting
    M, r = [list(x) for x in rows], 0
    for c in range(len(M[0])):
        p = max(range(r, len(M)), key=lambda i: abs(M[i][c]), default=None)
        if p is None or abs(M[p][c]) < tol:
            continue
        M[r], M[p] = M[p], M[r]
        for i in range(r + 1, len(M)):
            f = M[i][c] / M[r][c]
            M[i] = [a - f * b for a, b in zip(M[i], M[r])]
        r += 1
    return r
def constraint_rows(R):                    # derivative of H -> H^T R + R^T H, one row per entry i <= j
    n = len(R)
    return [[(b == i) * R[a][j] + (b == j) * R[a][i] for a in range(n) for b in range(n)]
            for i in range(n) for j in range(i, n)]
def chart_columns(chart, x, h=1e-6):       # central differences: one 9-number column per coordinate
    cols = []
    for k in range(3):
        up, dn = list(x), list(x)
        up[k] += h; dn[k] -= h
        A, B = chart(up), chart(dn)
        cols.append([(A[i][j] - B[i][j]) / (2 * h) for i in range(3) for j in range(3)])
    return cols
def volume(cols):                          # square root of the Gram determinant
    return math.sqrt(max(0.0, det3([[sum(a * b for a, b in zip(c1, c2)) for c2 in cols] for c1 in cols])))
def f4(x):
    return f"{0.0 if abs(x) < 5e-5 else x:.4f}"
def yn(claim):
    return "yes" if claim else "no"
def rotation_n(n):                          # an n-dimensional turn: plane turns in planes (0,1), (1,2), ...
    R = eye(n)
    for k in range(n - 1):
        G = eye(n); a = 0.3 + 0.2 * k
        G[k][k], G[k][k + 1], G[k + 1][k], G[k + 1][k + 1] = math.cos(a), -math.sin(a), math.sin(a), math.cos(a)
        R = mul(R, G)
    return R
state = 2026                               # SplitMix64, seed 2026, for random orientations
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53

drone = [30 * D, 10 * D, 5 * D]            # yaw 30, pitch 10 nose up, roll 5 right wing down
R0 = euler(drone)
for i, name in enumerate(["north", "east ", "down "]):
    print(f"R0 row {name}: {' '.join(f4(R0[i][j]) for j in range(3))}")
sq = [R0[i][0] ** 2 for i in range(3)]
print(f"R0 column 1 squared: {' + '.join(f4(x) for x in sq)} = {f4(sum(sq))}; column 1 . column 2 = {f4(sum(R0[i][0] * R0[i][1] for i in range(3)))}")
print(f"R0: R^T R - I below 1e-12: {yn(residual(R0) < 1e-12)}; det {f4(det3(R0))}")
cam = mul(R0, ry(-30 * D))                 # gimbal tilts the camera 30 degrees down from the nose
print(f"camera = R0 G: R^T R - I below 1e-12: {yn(residual(cam) < 1e-12)}; det {f4(det3(cam))}")
print(f"camera axis below horizon {f4(math.asin(cam[2][0]) / D)} deg, heading {f4(math.atan2(cam[1][0], cam[0][0]) / D)} deg")
print(f"inverse is the transpose: R0 R0^T - I below 1e-12: {yn(residual(tp(R0)) < 1e-12)}")
road1 = 9 - rank(constraint_rows(R0))
v0 = axis_angle(R0)
cA, cB = chart_columns(euler, drone), chart_columns(rodrigues, v0)
print(f"road 1: 9 entries - rank {rank(constraint_rows(R0))} of the constraint = {road1}")
print(f"road 2: rank of chart A (yaw, pitch, roll) at the drone = {rank(cA)}")
print(f"road 3: rank of chart B (axis-angle) at the drone = {rank(cB)}")
print(f"chart B point: angle {f4(math.sqrt(sum(c * c for c in v0)) / D)} deg, rebuilt R0 error below 1e-12: {yn(residual(mul(tp(R0), rodrigues(v0))) < 1e-12)}")
tang = max(abs(sum(r * c for r, c in zip(row, col))) for row in constraint_rows(R0) for col in cA + cB)
print(f"chart directions obey the constraint's derivative, worst miss below 1e-8: {yn(tang < 1e-8)}")
ranks = []
for _ in range(1000):
    x = [(2 * uniform() - 1) * math.pi, (uniform() - 0.5) * math.pi, (2 * uniform() - 1) * math.pi]
    ranks.append(rank(constraint_rows(euler(x))))
print(f"1000 random orientations with constraint rank 6: {ranks.count(6)}")
so = [len(eye(n)) ** 2 - rank(constraint_rows(rotation_n(n))) for n in (2, 3, 4)]
print(f"SO(n) by road 1, n = 2, 3, 4: {so}; by n(n-1)/2: {[n * (n - 1) // 2 for n in (2, 3, 4)]}")
print(f"n = 3: GL {3 * 3}, O {3 * 2 // 2}, SO {3 * 2 // 2}, U {3 * 3}, SU {3 * 3 - 1}")
vols = [volume(chart_columns(euler, [30 * D, p * D, 5 * D])) for p in range(0, 91, 15)]
print(f"chart A volume at level flight {f4(vols[0])}; 2 sqrt 2 = {f4(2 * math.sqrt(2))}")
print(f"chart A volume / level, pitch 0..90 by 15: {' '.join(f4(v / vols[0]) for v in vols)}")
print(f"cos(pitch), pitch 0..90 by 15:            {' '.join(f4(math.cos(p * D)) for p in range(0, 91, 15))}")
lock = [30 * D, 90 * D, 5 * D]
print(f"mistake 1, all 9 equations of R^T R = I counted: 9 - 9 = {9 - 9}")
print(f"mistake 2, pitch 90: chart A rank {rank(chart_columns(euler, lock))}, chart B rank {rank(chart_columns(rodrigues, axis_angle(euler(lock))))}")
mirror = [[1, 0, 0], [0, 1, 0], [0, 0, -1]]
print(f"mistake 3, mirror diag(1, 1, -1): R^T R - I = {f4(residual(mirror))}, det {f4(det3(mirror))}")
avg = [[(a + b) / 2 for a, b in zip(r1, r2)] for r1, r2 in zip(rz(0), rz(180 * D))]
print(f"mistake 4, north and south headings averaged: det {f4(det3(avg))}, R^T R - I = {f4(residual(avg))}")
assert road1 == 3 and rank(cA) == 3 and rank(cB) == 3            # three roads, one dimension
assert tang < 1e-8 and ranks.count(6) == 1000                    # charts move along the constraint surface
assert so == [n * (n - 1) // 2 for n in (2, 3, 4)]               # the rank count against the formula
assert max(abs(v / vols[0] - math.cos(p * D)) for v, p in zip(vols, range(0, 91, 15))) < 1e-6
assert abs(vols[0] - 2 * math.sqrt(2)) < 1e-6                    # finite differences against the closed form
assert rank(chart_columns(euler, lock)) == 2 and abs(det3(avg)) < 1e-12
assert max(residual(M) for M in [R0, cam] + [rotation_n(n) for n in (2, 3, 4)]) < 1e-12   # all are turns
assert abs(det3(R0) - 1) < 1e-12 and abs(det3(cam) - 1) < 1e-12                 # det +1, not mirrors
yaw, pitch, roll = drone                   # R0's nose column and down row against their closed forms
assert max(abs(a - b) for a, b in zip([R0[0][0], R0[1][0], R0[2][0], R0[2][1], R0[2][2]], [math.cos(yaw) * math.cos(pitch), math.sin(yaw) * math.cos(pitch), -math.sin(pitch), math.cos(pitch) * math.sin(roll), math.cos(pitch) * math.cos(roll)])) < 1e-12
print("ALL CHECKS PASS")
