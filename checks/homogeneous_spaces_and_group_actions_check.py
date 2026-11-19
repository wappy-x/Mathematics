# Group action and homogeneous space -- the check behind the card.  Standard
# library only.  The rotation group SO(3) turns a globe of radius 6371 km.  Any
# point can be carried to any other, and the turns that fix the North Pole are
# the spins about the polar axis, so the globe is SO(3) / SO(2).  Roads: a
# formula against a scan, a rank against a chart, random turns against area,
# and orbit times stabiliser against fixed points.
import math
D, RAD, N = math.pi / 180, 6371.0, [0.0, 0.0, 1.0]

def mul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def tp(A):
    return [list(r) for r in zip(*A)]
def act(A, v):
    return [sum(A[i][k] * v[k] for k in range(3)) for i in range(3)]
def turn(a, i, j):                     # turn by a in the plane of axes i and j
    M = [[float(r == c) for c in range(3)] for r in range(3)]
    M[i][i] = M[j][j] = math.cos(a)
    M[i][j], M[j][i] = -math.sin(a), math.sin(a)
    return M
def Z(a): return turn(a, 0, 1)         # spin about the polar axis (or, for the drone, the down axis)
def Y(a): return turn(a, 2, 0)         # tip about the axis through 90 deg east (or the right wing)
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def cross(u, v): return [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
def gap(u, v): return max(abs(a - b) for a, b in zip(u, v))
def arc(u, v): return math.acos(max(-1.0, min(1.0, dot(u, v))))
def angle(A): return math.acos(max(-1.0, min(1.0, (A[0][0] + A[1][1] + A[2][2] - 1) / 2)))
def point(lat, lon):                   # unit vector from latitude and longitude in degrees
    p, t = (90 - lat) * D, lon * D
    return [math.sin(p) * math.cos(t), math.sin(p) * math.sin(t), math.cos(p)]
def to_pole(v):                        # the chosen turn Z(theta) Y(phi), carrying n to v
    return mul(Z(math.atan2(v[1], v[0])), Y(math.acos(v[2])))
def rank(rows, tol=1e-9):              # Gaussian elimination with row swaps
    m, r = [list(x) for x in rows], 0
    for c in range(3):
        if r == len(m): break
        piv = max(range(r, len(m)), key=lambda i: abs(m[i][c]))
        if abs(m[piv][c]) < tol: continue
        m[r], m[piv] = m[piv], m[r]
        for i in range(r + 1, len(m)):
            f = m[i][c] / m[r][c]
            m[i] = [a - f * b for a, b in zip(m[i], m[r])]
        r += 1
    return r
state = 2026
def rnd():                             # SplitMix64, seed 2026, uniform in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
def random_turn():                     # a fair random turn, from a uniform unit quaternion
    u1, u2, u3 = rnd(), rnd(), rnd()
    a, b = math.sqrt(1 - u1), math.sqrt(u1)
    x, y, z, w = a * math.sin(2 * math.pi * u2), a * math.cos(2 * math.pi * u2), b * math.sin(2 * math.pi * u3), b * math.cos(2 * math.pi * u3)
    return [[1 - 2 * (y * y + z * z), 2 * (x * y - w * z), 2 * (x * z + w * y)],
            [2 * (x * y + w * z), 1 - 2 * (x * x + z * z), 2 * (y * z - w * x)],
            [2 * (x * z - w * y), 2 * (y * z + w * x), 1 - 2 * (x * x + y * y)]]
def yn(c): return "yes" if c else "no"

L, NY, PA = point(51.5074, -0.1278), point(40.7128, -74.0060), point(48.8566, 2.3522)
gL, gY = to_pole(L), to_pole(NY)
print(f"globe radius {RAD:.0f} km; London colatitude {math.acos(L[2]) / D:.4f} deg, longitude {math.atan2(L[1], L[0]) / D:.4f} deg")
fib = max(gap(act(mul(gL, Z(a * D)), N), L) for a in range(360))
print(f"g_L = Z(theta) Y(phi) and all 360 turns g_L Z(alpha), alpha = 0..359 deg, land on London: {yn(fib < 1e-12)}")
worst = 0.0
for _ in range(1000):                  # every turn = (chosen turn to its point) x (a spin)
    g = random_turn()
    s = mul(tp(to_pole(act(g, N))), g)
    worst = max(worst, gap(act(s, N), N), abs(s[0][2]), abs(s[1][2]))
print(f"1000 random turns g: g_v^T g is a spin about the pole, worst miss below 1e-12: {yn(worst < 1e-12)}")
best = min((angle(mul(mul(gY, Z(k * D / 100)), tp(gL))), k) for k in range(36000))
T = mul(mul(gY, Z(best[1] * D / 100)), tp(gL))
c = arc(L, NY)
print(f"smallest turn carrying London to New York, by scanning the circle of them: {best[0] / D:.4f} deg")
print(f"central angle London-New York, acos of {dot(L, NY):.4f}: {c / D:.4f} deg = {c:.4f} rad = {c * RAD:.1f} km")
print(f"London-Paris {arc(L, PA) * RAD:.1f} km; New York to the turned Paris {arc(NY, act(T, PA)) * RAD:.1f} km")
orbit_rows = [cross(e, L) for e in ([1.0, 0, 0], [0, 1.0, 0], [0, 0, 1.0])]
h = 1e-6
chart_rows = [[(a - b) / (2 * h) for a, b in zip(point(51.5074 + h, -0.1278), point(51.5074 - h, -0.1278))],
              [(a - b) / (2 * h) for a, b in zip(point(51.5074, -0.1278 + h), point(51.5074, -0.1278 - h))]]
ro, rc = rank(orbit_rows), rank(chart_rows, 1e-6)
print(f"rank of omega -> omega x London: {ro}; |London x London| = {math.sqrt(dot(cross(L, L), cross(L, L))):.4f}")
print(f"rank of the latitude-longitude chart at London: {rc}; stabiliser dimension 3 - {ro} = {3 - ro}")
rho, M = 2000 / RAD, 200000
share = (1 - math.cos(rho)) / 2
hits = [0, 0]
for _ in range(M):
    v = act(random_turn(), N)
    hits[0] += arc(v, L) <= rho
    hits[1] += arc(v, NY) <= rho
se = math.sqrt(M * share * (1 - share))
print(f"cap of 2000 km = {rho:.4f} rad: area {2 * math.pi * RAD * RAD * (1 - math.cos(rho)):.0f} km^2, share of globe {share:.6f}")
print(f"{M} fair random turns of the pole: within 2000 km of London {hits[0]}, of New York {hits[1]}")
print(f"expected from area {M * share:.1f}, standard error {se:.1f}")
R0 = mul(mul(Z(30 * D), Y(10 * D)), turn(5 * D, 1, 2))
cam = mul(R0, Y(-30 * D))
dep, head = math.asin(cam[2][0]) / D, math.atan2(cam[1][0], cam[0][0]) / D
pan = mul(Z(head * D), Y(-dep * D))
roll = mul(tp(pan), cam)
print(f"camera axis {dep:.4f} deg below the horizon, heading {head:.4f} deg")
print(f"pan {head:.4f} deg, tilt {-dep:.4f} deg aims the same way: {yn(gap([r[0] for r in pan], [r[0] for r in cam]) < 1e-12)}")
print(f"what is left is a roll about the camera axis: {yn(gap([r[0] for r in roll], [1.0, 0, 0]) < 1e-12)}, of {math.atan2(roll[2][1], roll[1][1]) / D:.4f} deg")
s1, s2 = point(-89.99, 0.0), point(-89.99, 90.0)
print(f"chosen turns near the South Pole: points {arc(s1, s2) * RAD:.2f} km apart, turns {angle(mul(tp(to_pole(s1)), to_pole(s2))) / D:.4f} deg apart")
I3 = [[int(r == c) for c in range(3)] for r in range(3)]
cube, todo = [I3], [I3]
while todo:
    a = todo.pop()
    for g in ([[0, -1, 0], [1, 0, 0], [0, 0, 1]], [[1, 0, 0], [0, 0, -1], [0, 1, 0]]):
        b = mul(g, a)
        if b not in cube:
            cube.append(b)
            todo.append(b)
print(f"turns of a cube, built from two quarter turns: {len(cube)}")
special, prods, sizes = [], [], []
for name, v in (("face centre", [0, 0, 1]), ("corner", [1, 1, 1]), ("edge midpoint", [1, 1, 0]), ("general point", [1, 2, 3])):
    orb = sorted({tuple(act(g, v)) for g in cube})
    stab = sum(act(g, v) == v for g in cube)
    prods.append(len(orb) * stab)
    sizes.append(len(orb))
    special += [(list(p), stab) for p in orb if stab > 1]
    print(f"{name} {v}: orbit {len(orb)} x stabiliser {stab} = {len(orb) * stab}")
by_points = sum(s - 1 for _, s in special)
per_turn = [sum(act(g, p) == p for p, _ in special) for g in cube if g != I3]
print(f"turn-and-fixed-point pairs: by points {by_points}, by turns {len(per_turn)} x 2 = {sum(per_turn)}")
print(f"mistake 1, spin on the wrong side: Z(90 deg) g_L sends the pole {arc(L, act(Z(90 * D), L)) * RAD:.1f} km from London")
print(f"mistake 2, orbit dimension taken as 3: the orbit map has rank {ro}, the globe dimension 2")
print(f"mistake 3, spins only: London's orbit is a circle of {2 * math.pi * RAD * math.sqrt(1 - L[2] * L[2]):.1f} km; New York is {abs(math.acos(L[2]) - math.acos(NY[2])) * RAD:.1f} km off it")
print(f"mistake 4, images counted without the stabiliser: {len(cube)} images of a face centre, {sizes[0]} distinct")
assert abs(best[0] - c) < 1e-6 and gap(act(T, L), NY) < 1e-12        # scan against acos
assert abs(arc(L, PA) - arc(NY, act(T, PA))) < 1e-12                  # distances kept
assert ro == 2 and rc == 2 and fib < 1e-12 and worst < 1e-12          # 3 = 2 + 1, two roads
assert all(abs(k - M * share) < 4 * se for k in hits)                 # random turns against area
assert len(cube) == 24 and prods == [24] * 4                          # orbit x stabiliser
assert by_points == sum(per_turn) == 46 and set(per_turn) == {2}      # two counts of pairs
assert gap([r[0] for r in roll], [1.0, 0.0, 0.0]) < 1e-12
print("ALL CHECKS PASS")
