# Principal bundle and connection -- the check behind the card.  Nothing is imported but math.
# Part 1, the circle group SO(2) at every point of the globe: a survey drone flies a
# latitude-longitude box; its gyro-held camera frame comes back turned against the compass.
# The turn is found four ways: the line integral of A in two gauges, the area integral
# of F = dA, and a gauge-free carry of the frame in 3D.  Part 2, the group SO(3): a gimbal
# whose connection has dA = 0, so all of its curvature F = dA + A^A is the bracket term.
from math import sin, cos, acos, atan2, sqrt, radians, degrees, pi

R = 6371.0                                           # Earth radius, km (a sphere: a model)
p1, p2, t0, t1 = radians(30), radians(40), radians(-30), 0.0   # 60N, 50N; 30W to 0
c = sin(radians(55))                                 # grid gauge: alpha = c (theta - th_mid)
def A(ph, th, gauge):                                # (A_phi, A_theta) in rad per rad
    return (0.0, -cos(ph) + (c if gauge == "grid" else 0.0))
def f(x): return 0.0 if abs(x) < 5e-9 else x
def legs(n):                                         # the route as (phi, theta) points
    pts = [(p2, t0 + (t1 - t0) * k / n) for k in range(n)] + [(p2 - (p2 - p1) * k / n, t1) for k in range(n)]
    pts += [(p1, t1 - (t1 - t0) * k / n) for k in range(n)] + [(p1 + (p2 - p1) * k / n, t0) for k in range(n)]
    return pts + [(p2, t0)]
def line(gauge, pts):                                # road 1: integral of A along the route, midpoint rule
    out = [0.0]
    for (a, b), (u, v) in zip(pts, pts[1:]):
        Ap, At = A((a + u) / 2, (b + v) / 2, gauge)
        out.append(out[-1] + Ap * (u - a) + At * (v - b))
    return out
def area_F(n, pa, pb, ta, tb):                       # road 2: F = dA = sin(phi) dphi^dtheta, midpoint grid
    hp, ht = (pb - pa) / n, (tb - ta) / n
    return sum(sin(pa + (i + 0.5) * hp) * hp * ht for i in range(n) for j in range(n))
def cap_F(n, pb): return sum(sin((i + 0.5) * pb / n) * pb / n for i in range(n)) * 2 * pi   # F has no theta in it
def xyz(ph, th): return [sin(ph) * cos(th), sin(ph) * sin(th), cos(ph)]
def cross(a, b): return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def unit(a): return [x / sqrt(dot(a, a)) for x in a]
def turn(v, n, t): return [v[i] * cos(t) + cross(n, v)[i] * sin(t) + n[i] * dot(n, v) * (1 - cos(t)) for i in range(3)]
def carry(n):                                        # road 3: gyro frame carried in 3D, no chart, no gauge
    P = [xyz(*q) for q in legs(n)]
    north = [-cos(p2) * cos(t0), -cos(p2) * sin(t0), sin(p2)]
    v = north[:]
    for a, b in zip(P, P[1:]): v = turn(v, unit(cross(a, b)), acos(min(1.0, dot(a, b))))
    return atan2(dot(cross(north, v), P[0]), dot(north, v))

d = t1 - t0
exact = d * (cos(p1) - cos(p2))
print(f"box 50N-60N, 30W-0: legs {R * sin(p2) * d:.1f}, {R * (p2 - p1):.1f}, {R * sin(p1) * d:.1f}, {R * (p2 - p1):.1f} km; area {R * R * exact:.0f} km^2")
pm, tm = (p1 + p2) / 2, (t0 + t1) / 2
print(f"A_theta at the box centre 55N: compass gauge {A(pm, tm, 'compass')[1]:.6f}, grid gauge {f(A(pm, tm, 'grid')[1]):.6f}")
for g in ("compass", "grid"):
    s = line(g, legs(400))
    print(f"{g:7} gauge, integral of A by leg: {s[400]:.6f}, {s[800] - s[400]:.6f}, {s[1200] - s[800]:.6f}, {s[1600] - s[1200]:.6f}; total {s[1600]:.6f} rad")
print(f"closed form d theta (cos 30 - cos 40) = {exact:.6f} rad = {degrees(exact):.6f} deg")
print(f"by hand: d theta {d:.6f} rad, cos 30 deg {cos(p1):.6f}, cos 40 deg {cos(p2):.6f}, c = sin 55 deg {c:.6f}, K = {1e8 / R ** 2:.6f}e-8 per km^2; camera heading {360 - degrees(exact):.3f} deg")
F20, F40 = area_F(20, p1, p2, t0, t1), area_F(40, p1, p2, t0, t1)
print(f"area integral of F: 20x20 grid {F20:.9f}, 40x40 {F40:.9f}; error ratio {(F20 - exact) / (F40 - exact):.2f}")
c50, c100 = carry(50), carry(100)
print(f"3D carry: 50 steps a leg {c50:.9f}, 100 steps {c100:.9f}; error ratio {(c50 - exact) / (c100 - exact):.2f}")
e = 1e-5                                             # F_phi_theta = d_phi A_theta - d_theta A_phi, both gauges
Fd = [(A(pm + e, tm, g)[1] - A(pm - e, tm, g)[1] - A(pm, tm + e, g)[0] + A(pm, tm - e, g)[0]) / (2 * e) for g in ("compass", "grid")]
print(f"F at the centre by differences: compass {Fd[0]:.6f}, grid {Fd[1]:.6f}; sin 35 deg = {sin(pm):.6f}")
pts = legs(400)
sc, sg = line("compass", pts), line("grid", pts)
km = [0.0]
for (a, b), (u, v) in zip(pts, pts[1:]): km.append(km[-1] + R * sqrt((u - a) ** 2 + (sin((a + u) / 2) * (v - b)) ** 2))
idx = list(range(0, 1601, 200))
print("chart, km     " + " ".join(f"{km[i]:6.0f}" for i in idx))
print("chart, compass" + " ".join(f"{degrees(sc[i]):7.2f}" for i in idx))
print("chart, grid   " + " ".join(f"{degrees(sg[i]):7.2f}" for i in idx))
q = radians(1)                                       # a loop round the pole at 89N
cap_line, cap_area = -2 * pi * cos(q), cap_F(1000, q)
print(f"loop at 89N: integral of A (compass) {degrees(cap_line):.6f} deg; area integral of F {degrees(cap_area):.6f} deg; gap {degrees(cap_line - cap_area):.6f}")
whole = cap_F(2000, pi)
print(f"whole sphere: integral of F = {whole:.6f} = {whole / (2 * pi):.6f} turns")

I = [[float(i == j) for j in range(3)] for i in range(3)]
def mul(a, b): return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def lin(a, b, s): return [[a[i][j] + s * b[i][j] for j in range(3)] for i in range(3)]
def sm(a, s): return lin([[0.0] * 3 for _ in range(3)], a, s)
def tr(a): return [[a[j][i] for j in range(3)] for i in range(3)]
def hat(w): return [[0.0, -w[2], w[1]], [w[2], 0.0, -w[0]], [-w[1], w[0], 0.0]]
def vee(m): return (m[2][1], m[0][2], m[1][0])
def br(x, y): return lin(mul(x, y), mul(y, x), -1.0)
def gap(a, b): return max(abs(a[i][j] - b[i][j]) for i in range(3) for j in range(3))
def ang(r): return acos(max(-1.0, min(1.0, (r[0][0] + r[1][1] + r[2][2] - 1) / 2)))
def expm(x):
    s, t = [r[:] for r in I], [r[:] for r in I]
    for k in range(1, 40): t = sm(mul(t, x), 1.0 / k); s = lin(s, t, 1.0)
    return s
def fv(v): return "(" + ", ".join(f"{f(x):.6f}" for x in v) + ")"
Ly, Lz, a = hat((0, 1, 0)), hat((0, 0, 1)), 0.1
Ax, Ay = sm(Ly, a), sm(Lz, a)                        # stick east pitches, stick north yaws, 0.1 rad per unit
F = br(Ax, Ay)                                       # dA = 0 here, so F = [A_x, A_y]
print(f"gimbal: A_x = 0.1 Ly, A_y = 0.1 Lz; dA = 0; F_xy = [A_x, A_y] = {fv(vee(F))} (a roll)")
def square(h): return mul(mul(expm(sm(Ax, h)), expm(sm(Ay, h))), mul(expm(sm(Ax, -h)), expm(sm(Ay, -h))))
gs = []
for h in (1.0, 0.5):
    C = square(h)
    gs.append(gap(sm(lin(C, I, -1.0), 1 / h ** 2), F))
    print(f"square of side {h}: holonomy turn {ang(C):.6f} rad = {degrees(ang(C)):.6f} deg; I + h^2 F predicts {h * h * a * a:.6f}; (H - I)/h^2 - F {gs[-1]:.6f}")
print(f"error ratio {gs[0] / gs[1]:.2f}")
b = 0.5                                              # gauge change g = exp(0.5 x y Lz)
def Ap(x, y):
    g = expm(sm(Lz, b * x * y)); gi = tr(g)                     # g^-1 A g + g^-1 dg
    return lin(mul(mul(gi, Ax), g), Lz, b * y), lin(mul(mul(gi, Ay), g), Lz, b * x)    # g^-1 A g + g^-1 dg
x0, y0, e = 0.5, 0.5, 1e-5
dAp = lin(lin(Ap(x0 + e, y0)[1], Ap(x0 - e, y0)[1], -1.0), lin(Ap(x0, y0 + e)[0], Ap(x0, y0 - e)[0], -1.0), -1.0)
dAp = sm(dAp, 1 / (2 * e))
AAp = br(*Ap(x0, y0))
Fp = lin(dAp, AAp, 1.0)
g0 = expm(sm(Lz, b * x0 * y0))
print(f"new gauge at (0.5, 0.5): A'_y = {fv(vee(Ap(x0, y0)[1]))}; dA' part {fv(vee(dAp))}, A'^A' part {fv(vee(AAp))}")
print(f"F' = {fv(vee(Fp))}; g^-1 F g = {fv(vee(mul(mul(tr(g0), F), g0)))}; size {sqrt(sum(x * x for x in vee(Fp))):.6f}")
def stepped(n):                                      # holonomy in the new gauge, path-ordered, midpoint steps
    H, h = [r[:] for r in I], 1.0 / n
    for (dx, dy, x, y) in [(1, 0, 0, 0), (0, 1, 1, 0), (-1, 0, 1, 1), (0, -1, 0, 1)]:
        for k in range(n):
            ax, ay = Ap(x + dx * (k + 0.5) * h, y + dy * (k + 0.5) * h)
            H = mul(H, expm(lin(sm(ax, dx * h), ay, dy * h)))
    return H
C1 = square(1.0)
H50, H100 = stepped(50), stepped(100)
print(f"new gauge, stepped holonomy: 50 steps a side off by {gap(H50, C1):.9f}, 100 off by {gap(H100, C1):.9f}; ratio {gap(H50, C1) / gap(H100, C1):.2f}; turn {ang(H100):.6f} rad")
big = square(10.0)
print(f"mistake, drop A^A: predicted roll 0.000000 rad; real {ang(C1):.6f} rad")
print(f"mistake, exp(area x F) on a 10 x 10 square: {degrees(ang(expm(sm(F, 100.0)))):.4f} deg; real holonomy {degrees(ang(big)):.4f} deg")
Ax, Ay = sm(Ly, 0.2), sm(Lz, 0.2)
print(f"try, a = 0.2: square of side 1 turns {ang(square(1.0)):.6f} rad")
print(f"try, box 0N-10N: {degrees(d * (cos(radians(80)) - cos(radians(90)))):.6f} deg; box 60 deg wide: {degrees(2 * exact):.6f} deg")

assert abs(line("compass", legs(400))[-1] - exact) < 1e-6 and abs(line("grid", legs(400))[-1] - exact) < 1e-6
assert 3.9 < (F20 - exact) / (F40 - exact) < 4.1 and abs(F40 - exact) < 1e-5     # Stokes, by area
assert 3.9 < (c50 - exact) / (c100 - exact) < 4.1 and abs(c100 - exact) < 1e-6   # gauge-free carry
assert abs(Fd[0] - sin(pm)) < 1e-8 and abs(Fd[1] - sin(pm)) < 1e-8 and abs(A(pm, tm, "grid")[1]) < 1e-12   # grid A = 0 at 55N
assert abs(abs(cap_line - cap_area) - 2 * pi) < 1e-6 and abs(whole - 4 * pi) < 1e-5
assert 1.95 < gs[0] / gs[1] < 2.05 and abs(ang(C1) - 0.01) < 1e-4               # holonomy -> I + h^2 F
assert gap(Fp, mul(mul(tr(g0), F), g0)) < 1e-8 and gap(H100, C1) < 1e-5
print("ALL CHECKS PASS")
