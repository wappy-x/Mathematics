# Diffeomorphism, immersion, submersion -- the check behind the card.  Standard
# library only.  Four maps from the house example are classified by the rank of
# their differential.  Each rank is found by two roads: the Jacobian written out
# in the latitude-longitude chart, and a chart-free road that pushes two tangent
# directions through the map in 3D space by central differences.
from math import sin, cos, atan, atan2, exp, log, sqrt, pi, radians, degrees

R = 6371.0                                     # the globe's radius in km (a sphere: a model)

def rank(A, tol=1e-7):                         # Gaussian elimination, tolerance relative to the largest entry
    A, r = [row[:] for row in A], 0
    big = max(abs(x) for row in A for x in row) or 1.0
    for c in range(len(A[0])):
        rows = [i for i in range(r, len(A)) if abs(A[i][c]) > tol * big]
        if not rows:
            continue
        p = max(rows, key=lambda i: abs(A[i][c]))
        A[r], A[p] = A[p], A[r]
        for i in range(r + 1, len(A)):
            f = A[i][c] / A[r][c]
            A[i] = [a - f * b for a, b in zip(A[i], A[r])]
        r += 1
    return r

def add(a, b, s=1.0): return [x + s * y for x, y in zip(a, b)]
def norm(a): return sqrt(sum(x * x for x in a))
def cross(a, b): return [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]]
def ball(lat, lon):                            # degrees north and east to a point on the globe, km
    f, t = radians(90 - lat), radians(lon)     # phi measured down from the North Pole
    return [R * sin(f) * cos(t), R * sin(f) * sin(t), R * cos(f)]

def tangent_pair(q):                           # two unit directions along the globe at q, no chart used
    u = [x / norm(q) for x in q]
    a = [0.0, 0.0, 0.0]
    a[min(range(3), key=lambda i: abs(u[i]))] = 1.0
    e1 = cross(a, u)
    e1 = [x / norm(e1) for x in e1]
    return [e1, cross(u, e1)]

def push(F, q, dirs, h=1e-3):                  # columns dF(v) by central differences, as a matrix
    cols = [[(a - b) / (2 * h) for a, b in zip(F(add(q, v, h)), F(add(q, v, -h)))] for v in dirs]
    return [list(row) for row in zip(*cols)]

def mercator(q):                               # X = R theta, Y = R ln cot(phi/2), from a 3D point
    s = q[2] / norm(q)
    return [R * atan2(q[1], q[0]), R * 0.5 * log((1 + s) / (1 - s))]
def photo(q): return [q[0], q[1]]              # the globe seen from far above the North Pole
def J_mercator(f): return [[0.0, R], [-R / sin(f), 0.0]]          # columns: d/dphi, d/dtheta
def J_photo(f, t): return [[R * cos(f) * cos(t), -R * sin(f) * sin(t)],
                           [R * cos(f) * sin(t), R * sin(f) * cos(t)]]

# 1. Mercator at Heathrow: a diffeomorphism from the globe minus its poles onto a strip.
lat, lon = 51.47, -0.4543
f, t = radians(90 - lat), radians(lon)
L = ball(lat, lon)
x, y = mercator(L)
JM = push(mercator, L, tangent_pair(L))
st = [norm([JM[0][k], JM[1][k]]) for k in range(2)]
print(f"Heathrow {lat:.4f} N {-lon:.4f} W on Mercator: X = {x:.3f} km, Y = {y:.3f} km")
print(f"Mercator rank at Heathrow: chart {rank(J_mercator(f))}, chart-free {rank(JM)}; "
      f"chart det = {R * R / sin(f):.1f} km^2 per rad^2")
print(f"Mercator stretch at Heathrow, two chart-free directions: {st[0]:.6f}, {st[1]:.6f}; "
      f"1/cos(latitude) = {1 / cos(radians(lat)):.6f}")
back = (90 - degrees(2 * atan(exp(-y / R))), degrees(x / R))       # road one: the closed-form undo
g, k = radians(40.0), radians(2.0)                               # road two: Newton from 50 N, 2 E
for n in range(1, 30):
    J = J_mercator(g)
    d = [R * k - x, R * 0.5 * log((1 + cos(g)) / (1 - cos(g))) - y]
    g, k = g - d[1] / J[1][0], k - d[0] / J[0][1]                # inverse of an anti-diagonal matrix
    if abs(d[0]) + abs(d[1]) < 1e-9:
        break
print(f"undo by formula: {back[0]:.6f} N {-back[1]:.6f} W; by Newton ({n} steps): "
      f"{90 - degrees(g):.6f} N {-degrees(k):.6f} W")
print(f"Mercator strip width 2 pi R = {2 * pi * R:.2f} km; Y at 85 N = {mercator(ball(85, 0))[1]:.1f} km")
# 2. The photo from above the North Pole: rank 2 at Heathrow, rank 1 on the equator.
rP = [(rank(J_photo(radians(90 - a), radians(b))), rank(push(photo, ball(a, b), tangent_pair(ball(a, b)))))
      for a, b in [(lat, lon), (0, 0), (90, 0)]]
print(f"photo rank (chart, chart-free): Heathrow {rP[0]}, equator {rP[1]}, North Pole {rP[2]}")
print(f"photo chart det R^2 sin(phi) cos(phi): Heathrow {R*R*sin(f)*cos(f):.1f}, equator "
      f"{abs(R*R*sin(pi/2)*cos(pi/2)):.1f}, North Pole {R*R*sin(0.0)*cos(0.0):.1f} km^2 per rad^2")
p10n, p10s = photo(ball(10, 0)), photo(ball(-10, 0))
print(f"photo of 10 N 0 E: ({p10n[0]:.2f}, {p10n[1]:.2f}) km; of 10 S 0 E: ({p10s[0]:.2f}, {abs(p10s[1]):.2f}) km")
# 3. The overlay: a 1.00 m clear sheet curled into a roll 0.80 m round.
def roll(c):
    rho = c / (2 * pi)
    return lambda q: [rho * sin(q[0] / rho), rho * (1 - cos(q[0] / rho)), q[1]]
C = roll(0.80)
JC = push(C, [0.10, 0.35], [[1.0, 0.0], [0.0, 1.0]], 1e-5)
JCa = [[cos(0.10 / (0.8 / (2 * pi))), 0.0], [sin(0.10 / (0.8 / (2 * pi))), 0.0], [0.0, 1.0]]
a, b = C([0.10, 0.35]), C([0.90, 0.35])
print(f"roll rank at u = 0.10 m: formula {rank(JCa)}, differences {rank(JC)}; column lengths "
      f"{norm([r[0] for r in JC]):.6f}, {norm([r[1] for r in JC]):.6f}")
print(f"u = 0.10 m lands at ({a[0]:.6f}, {a[1]:.6f}, {a[2]:.2f}); u = 0.90 m at ({b[0]:.6f}, {b[1]:.6f}, {b[2]:.2f})")
def closest(width, c=0.80, step=0.005, apart=0.40):   # brute force: nearest meeting of far-apart points
    F, us = roll(c), [i * step for i in range(round(width / step) + 1)]
    return min(norm(add(F([u, 0.0]), F([w, 0.0]), -1.0)) for u in us for w in us if w - u >= apart - 1e-12)
rho = 0.80 / (2 * pi)
gap = 2 * rho * sin(0.05 / (2 * rho))                            # chord across the 0.05 m left uncovered
print(f"closest approach of points 0.40 m apart on the sheet: 1.00 m sheet {closest(1.00):.6f} m, "
      f"0.75 m sheet {closest(0.75):.6f} m; chord formula {gap:.6f} m")
print(f"roll radius 0.80 m / 2 pi = {rho:.6f} m; a 1.00 m sheet overlaps itself by {1.00 - 0.80:.2f} m")
# 4. The drop from an aircraft 11 km above Heathrow to the ground point below it.
u = [c / R for c in L]
q = [(R + 11.0) * c for c in u]
G = lambda p: [R * c / norm(p) for c in p]
JG = push(G, q, [[1.0, 0, 0], [0, 1.0, 0], [0, 0, 1.0]])
JGa = [[R / norm(q) * ((i == j) - u[i] * u[j]) for j in range(3)] for i in range(3)]
up = [sum(JG[i][j] * u[j] for j in range(3)) for i in range(3)]
side = tangent_pair(q)[0]
print(f"drop rank: formula {rank(JGa)}, differences {rank(JG)}; nullity {3 - rank(JG)}")
print(f"an 11 km climb moves the ground point {11 * norm(up):.6f} km; a 1 km sideways step moves it "
      f"{norm([sum(JG[i][j] * side[j] for j in range(3)) for i in range(3)]):.6f} km = R/(R + 11)")
assert rank(J_mercator(f)) == rank(JM) == 2 and abs(st[0] - 1 / cos(radians(lat))) < 1e-6
assert abs(back[0] - lat) < 1e-9 and abs(90 - degrees(g) - lat) < 1e-9 and abs(degrees(k) - lon) < 1e-9
assert rP == [(2, 2), (1, 1), (1, 2)] and abs(p10n[0] - p10s[0]) < 1e-9
assert rank(JC) == rank(JCa) == 2 and norm(add(a, b, -1.0)) < 1e-12
assert closest(1.00) < 1e-9 and abs(closest(0.75) - gap) < 1e-9
assert rank(JG) == rank(JGa) == 2 and 11 * norm(up) < 1e-6 and abs(norm(JG[0]) - norm(JGa[0])) < 1e-6
assert abs(J_mercator(f)[0][1] / (R * sin(f)) - st[0]) < 1e-6 and abs(-J_mercator(f)[1][0] / R - st[1]) < 1e-6
print("ALL CHECKS PASS")
