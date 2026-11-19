# Smooth manifold -- the check behind the card.  Standard library only.
# The Earth is a sphere of radius 6371 km.  Six map sheets each look straight
# down on one half of it (orthographic projection): a sheet keeps two of the
# point's coordinates (X, Y, Z) and drops the third.  The card's claim is that
# every change of sheet is smooth.  Road 1: derivative matrices by formula.
# Road 2: difference quotients at two step sizes.  A rate measured on the
# ground is then computed in two sheets, which must agree.
import math
R = 6371.0
SHEETS = [("North", 2, 1), ("South", 2, -1), ("Greenwich", 0, 1),
          ("Date line", 0, -1), ("East", 1, 1), ("West", 1, -1)]

def point(lat, lon):                     # degrees to (X, Y, Z) in km
    a, b = math.radians(lat), math.radians(lon)
    return (R * math.cos(a) * math.cos(b), R * math.cos(a) * math.sin(b), R * math.sin(a))

def on_sheet(p, s): return s[2] * p[s[1]] > 0        # open half: the rim is left out
def chart(p, s): return tuple(p[i] for i in range(3) if i != s[1])
def lift(u, s):                          # inverse chart: put back the dropped coordinate
    p = list(u)
    p.insert(s[1], s[2] * math.sqrt(R * R - u[0] ** 2 - u[1] ** 2))
    return p
def change(u, s, t): return chart(lift(u, s), t)    # the transition, sheet s to sheet t

def jac_formula(u, s, t):                # road 1: row = output, column = input
    p, k = lift(u, s), s[1]
    ins = [i for i in range(3) if i != k]
    return [[-p[i] / p[k] if o == k else float(o == i) for i in ins]
            for o in range(3) if o != t[1]]

def jac_steps(u, s, t, h):               # road 2: central difference quotients
    cols = []
    for j in range(2):
        up, dn = list(u), list(u)
        up[j] += h; dn[j] -= h
        a, b = change(up, s, t), change(dn, s, t)
        cols.append([(a[i] - b[i]) / (2 * h) for i in range(2)])
    return [[cols[0][0], cols[1][0]], [cols[0][1], cols[1][1]]]

def gap(A, B): return max(abs(A[i][j] - B[i][j]) for i in range(2) for j in range(2))
def det(J): return J[0][0] * J[1][1] - J[0][1] * J[1][0]
def mul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
def yn(c): return "yes" if c else "no"

# The atlas: every grid point lies on at least one sheet; which pairs overlap.
grid = [point(la, lo) for la in range(-90, 91, 5) for lo in range(-180, 180, 5)]
counts = [sum(on_sheet(p, s) for s in SHEETS) for p in grid]
pairs = [(s, t) for i, s in enumerate(SHEETS) for t in SHEETS[i + 1:]
         if any(on_sheet(p, s) and on_sheet(p, t) for p in grid)]
worst, smallest = 0.0, 1e9
for s, t in pairs:                       # both directions, at a point inside the overlap
    for a, b in ((s, t), (t, s)):
        p = [R * 3 / 7, R * 2 / 7, R * 6 / 7]
        p[a[1]] *= a[2]; p[b[1]] *= b[2]
        u = chart(p, a)
        worst = max(worst, gap(jac_formula(u, a, b), jac_steps(u, a, b, 0.01)))
        smallest = min(smallest, abs(det(jac_formula(u, a, b))))
print(f"grid points {len(grid)}; sheets per point: fewest {min(counts)}, most {max(counts)}")
print(f"pairs of sheets that overlap: {len(pairs)} of 15; transitions checked both ways: {2 * len(pairs)}")
print(f"formula and difference quotients agree to 1e-6 on all {2 * len(pairs)}: {yn(worst < 1e-6)}")
print(f"smallest |det J| among them: {smallest:.4f}")

N, G = SHEETS[0], SHEETS[2]
lat, lon = 51.5074, -0.1278
P = point(lat, lon)
u, v = chart(P, N), chart(P, G)
J, K = jac_formula(u, N, G), jac_formula(v, G, N)
print(f"London {lat:.4f} N, {-lon:.4f} W: (X, Y, Z) = ({P[0]:.1f}, {P[1]:.1f}, {P[2]:.1f}) km")
print(f"North sheet ({u[0]:.1f}, {u[1]:.1f}); Greenwich sheet ({v[0]:.1f}, {v[1]:.1f})")
w = change(u, N, G)
print(f"North to Greenwich by the transition: ({w[0]:.1f}, {w[1]:.1f})")
print(f"J at London: [[{J[0][0]:.4f}, {J[0][1]:.4f}], [{J[1][0]:.4f}, {J[1][1]:.4f}]]; det J = X/Z = {det(J):.4f}")
for h in (1.0, 0.1):
    print(f"step {h:.1f} km: difference quotients miss J by {gap(J, jac_steps(u, N, G, h)):.10f}")
IJ = mul(K, J)
one = abs(IJ[0][0] - 1) < 1e-12 and abs(IJ[0][1]) < 1e-12 and abs(IJ[1][0]) < 1e-12 and abs(IJ[1][1] - 1) < 1e-12
print(f"J back times J forward is the identity to 1e-12: {yn(one)}")
A = point(5.6037, -0.1870)
print(f"Accra {5.6037:.4f} N, near the North sheet's rim: slope -X/Z = {-A[0] / A[2]:.2f}")
E = point(0.01, 0.0)
print(f"0.01 deg north of the equator: slope -X/Z = {-E[0] / E[2]:.2f}; on the equator Z = 0")

exact = math.cos(math.radians(lat))
def rate(s, h):                          # walk north from London: Z gained per km walked
    a, b = chart(point(lat + math.degrees(h / R), lon), s), chart(point(lat - math.degrees(h / R), lon), s)
    vel = [(a[i] - b[i]) / (2 * h) for i in range(2)]
    q = lift(chart(P, s), s)             # gradient of Z in this sheet, chain rule
    grad = [-c / q[2] for c in chart(P, s)] if s[1] == 2 else [0.0, 1.0]
    return vel, grad[0] * vel[0] + grad[1] * vel[1]
for s in (N, G):
    for h in (1.0, 0.1):
        vel, r = rate(s, h)
        print(f"{s[0]} sheet, step {h:.1f} km: velocity ({vel[0]:.4f}, {vel[1]:.4f}), "
              f"sheet speed {math.hypot(*vel):.4f}, dZ/ds {r:.6f}, off by {abs(r - exact):.10f}")
print(f"exact dZ/ds = cos(latitude) = {exact:.6f}; ground speed 1")

rho = math.hypot(*u)                     # the stereographic north map, same structure
st = R * rho / (R + math.sqrt(R * R - rho * rho))
back = 2 * R * R * st / (R * R + st * st)
print(f"North sheet {rho:.1f} km out -> stereographic {st:.1f} km -> back {back:.1f} km")
for h in (0.001, 0.000001):              # charts t and t^3 on the line
    print(f"line, step {h:.6f}: slope of t^3 at 0 = {h ** 3 / h:.12f}, of cube root = {h ** (1 / 3) / h:.1f}")
cx, cy, sc = 190.0, 210.0, 160.0 / R
print(f"figure, London ({cx + sc * P[0]:.2f}, {cy - sc * P[2]:.2f}), Accra ({cx + sc * A[0]:.2f}, {cy - sc * A[2]:.2f})")

v1, r1 = rate(N, 0.1)
v2, r2 = rate(G, 0.1)
assert min(counts) == 1 and max(counts) == 3 and len(pairs) == 12        # an atlas, 12 overlaps
assert worst < 1e-6 and smallest > 0.1                                   # road 1 against road 2
assert abs(w[0] - v[0]) < 1e-9 and abs(w[1] - v[1]) < 1e-9               # transition lands right
assert one                                                                 # J back undoes J
assert abs(r1 - exact) < 1e-6 and abs(r2 - exact) < 1e-6                 # one rate, two sheets
assert abs(math.hypot(*v1) - math.hypot(*v2)) > 0.1                      # components differ
assert abs(back - rho) < 1e-6 and abs(st - 2224.4) < 0.05                # matches the topology card
print("ALL CHECKS PASS")
