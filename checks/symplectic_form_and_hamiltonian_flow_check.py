# Symplectic form and Hamiltonian flow -- the check behind the card.  Standard library only.
# A 20 kg swing on 2 m rods, released from rest at -60 degrees.  State: angle q (rad), momentum
# p (kg m^2/s).  H = p^2/160 - 392.4 cos q.  The symplectic form is omega = dq ^ dp.
# Roads: the period by the AGM formula and by RK4; a patch of states carried by RK4, by
# leapfrog and by Euler, its area by the shoelace rule at two boundary resolutions; the
# form equation iota_X omega = dH against finite differences of H; two coupled swings,
# where the two shadow areas trade places but their sum, the integral of omega, stays.
import math
I, K, C = 80.0, 392.4, 40.0                  # m l^2, m g l, spring between the seats (J/rad^2)
Q0 = -math.pi / 3
def f6(x): return f"{x:.6f}"
def rates(z, c):                             # Hamilton's equations for 1 or 2 swings
    n = len(z) // 2
    f = [-K * math.sin(z[i]) for i in range(n)]
    if n == 2:
        f[0] -= c * (z[0] - z[1]); f[1] -= c * (z[1] - z[0])
    return [z[n + i] / I for i in range(n)] + f
def rk4(z, h, c):
    k1 = rates(z, c); k2 = rates([a + h / 2 * b for a, b in zip(z, k1)], c)
    k3 = rates([a + h / 2 * b for a, b in zip(z, k2)], c); k4 = rates([a + h * b for a, b in zip(z, k3)], c)
    return [a + h / 6 * (b + 2 * u + 2 * v + w) for a, b, u, v, w in zip(z, k1, k2, k3, k4)]
def euler(z, h): return [z[0] + h * z[1] / I, z[1] - h * K * math.sin(z[0])]
def leap(z, h):                              # half kick, drift, half kick
    p = z[1] - h / 2 * K * math.sin(z[0]); q = z[0] + h * p / I
    return [q, p - h / 2 * K * math.sin(q)]
def H(q, p): return p * p / (2 * I) - K * math.cos(q)
def det(M):                                  # determinant by Laplace expansion along the first row
    return M[0][0] if len(M) == 1 else sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M)))
def solve_X(om, g):                          # the X with iota_X om = g on (dq, dp), by Cramer's rule
    a, b = (om((1, 0), (1, 0)), om((1, 0), (0, 1))), (om((0, 1), (1, 0)), om((0, 1), (0, 1)))
    D = a[0] * b[1] - b[0] * a[1]
    return ((g[0] * b[1] - b[0] * g[1]) / D + 0.0, (a[0] * g[1] - g[0] * a[1]) / D + 0.0)
def agm_period(q0):                          # T = 2 pi sqrt(l/g) / AGM(1, cos(q0/2))
    a, b = 1.0, math.cos(q0 / 2)
    for _ in range(30): a, b = (a + b) / 2, math.sqrt(a * b)
    return 2 * math.pi * math.sqrt(2 / 9.81) / a
def square(n, q0):                           # boundary of q0-2..q0+2 deg by 0..8, anticlockwise
    lo, hi, d = q0 - math.radians(2), q0 + math.radians(2), math.radians(4) / n
    return ([(lo + d * k, 0.0) for k in range(n)] + [(hi, 8 * k / n) for k in range(n)]
            + [(hi - d * k, 8.0) for k in range(n)] + [(lo, 8 - 8 * k / n) for k in range(n)])
def shoelace(pts):
    return sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
               for i in range(len(pts))) / 2
def carry(pts, step, h, steps, c=0.0):
    out = []
    for q, p in pts:
        z = [q, p]
        for _ in range(steps): z = step(z, h, c) if step is rk4 else step(z, h)
        out.append((z[0], z[1]))
    return out
print("swing: m l^2 = 80 kg m^2, m g l = 392.4 J, release -60 deg, H =", f6(H(Q0, 0.0)), "J")
T = agm_period(Q0)
z, t, h = [Q0, 0.0], 0.0, 0.001              # road two: RK4 until the seat passes the bottom
while True:
    assert t < 10, "the seat never reached the bottom in 10 s"
    z2 = rk4(z, h, 0.0)
    if z2[0] >= 0: break
    z, t = z2, t + h
tq = t + h * (-z[0]) / (z2[0] - z[0])
print("period: AGM", f"{T:.9f}", "s, RK4 quarter swing x 4", f"{4 * tq:.9f}", "s")
assert abs(4 * tq - T) < 1e-6
A0 = math.radians(4) * 8
print("patch at release, 4 deg =", f6(math.radians(4)), "rad, x 8 kg m^2/s:", f6(A0), "J s; shoelace", f6(shoelace(square(100, Q0))))
ex = {}
for n in (25, 100):
    ex[n] = shoelace(carry(square(n, Q0), rk4, T / 600, 600))
    print(f"one swing, exact flow (RK4, 600 steps), {n} points a side:", f6(ex[n]), f"error {abs(ex[n] - A0):.1e}")
assert abs(ex[100] - A0) < 1e-6 and abs(ex[100] - A0) < abs(ex[25] - A0)
h = T / 60
print("Euler's step stretches area by 1 + h^2 (K/I) cos q, h^2 =", f6(h * h), "s^2, K/I =", f"{K / I:.3f}", "1/s^2")
lf = shoelace(carry(square(100, Q0), leap, h, 60))
eu = shoelace(carry(square(100, Q0), euler, h, 60))
print("one swing, 60 steps of", f6(h), "s: leapfrog", f6(lf), "Euler", f6(eu), "ratio", f6(eu / A0))
assert abs(lf - A0) < 1e-6 and eu > 1.5 * A0
def jac(step, z, e=1e-6):                    # one-step Jacobian by central differences
    a = [(x - y) / (2 * e) for x, y in zip(step([z[0] + e, z[1]], h), step([z[0] - e, z[1]], h))]
    b = [(x - y) / (2 * e) for x, y in zip(step([z[0], z[1] + e], h), step([z[0], z[1] - e], h))]
    return a[0] * b[1] - a[1] * b[0]
pb = math.sqrt(2 * I * (H(Q0, 0.0) + K))
for name, z in (("release", [Q0, 0.0]), ("the bottom", [0.0, pb])):
    de, dl, rule = jac(euler, z), jac(leap, z), 1 + h * h * (K / I) * math.cos(z[0])
    print(f"area factor per step at {name}: Euler {de:.6f} (rule {rule:.6f}), leapfrog {dl:.6f}")
    assert abs(de - rule) < 1e-6 and abs(dl - 1) < 1e-8
for name, (q, p) in (("release", (Q0, 0.0)), ("the bottom", (0.0, pb))):
    X = [x + 0.0 for x in rates([q, p], 0.0)]                   # iota_X omega = X_q dp - X_p dq
    iw = (-X[1] + 0.0, X[0])
    dH = ((H(q + 1e-6, p) - H(q - 1e-6, p)) / 2e-6, (H(q, p + 1e-6) - H(q, p - 1e-6)) / 2e-6)
    print(f"at {name}: X = ({X[0]:.4f}, {X[1]:.4f}), iota_X omega = ({iw[0]:.4f} dq, {iw[1]:.4f} dp),"
          f" dH = ({dH[0]:.4f} dq, {dH[1]:.4f} dp)")
    assert abs(iw[0] - dH[0]) < 1e-5 and abs(iw[1] - dH[1]) < 1e-5
g0 = ((H(Q0 + 1e-6, 0.0) - H(Q0 - 1e-6, 0.0)) / 2e-6, (H(Q0, 1e-6) - H(Q0, -1e-6)) / 2e-6)   # dH at release
Xw, Xr = solve_X(lambda u, v: u[0] * v[1] - u[1] * v[0], g0), solve_X(lambda u, v: u[1] * v[0] - u[0] * v[1], g0)
print(f"solve iota_X omega = dH at release: omega = dq^dp, X = ({Xw[0]:.4f}, {Xw[1]:.4f}); omega = dp^dq, X = ({Xr[0]:.4f}, {Xr[1]:.4f})")
assert abs(Xw[1] - rates([Q0, 0.0], 0.0)[1]) < 1e-5 and abs(Xr[1] + rates([Q0, 0.0], 0.0)[1]) < 1e-5
print("two swings, spring 40 J/rad^2: t (s), shadow q1p1, shadow q2p2, sum (J s)")
chart, s = [[], [], []], {}
for n in (25, 50):
    pts, hs = [[q, 0.0, p, 0.0] for q, p in square(n, Q0)], 0.01
    for k in range(2001):
        if k % 100 == 0:
            a1 = shoelace([(w[0], w[2]) for w in pts]); a2 = shoelace([(w[1], w[3]) for w in pts])
            s[(n, k // 100)] = (a1, a2)
            if n == 50:
                for row, v in zip(chart, (a1, a2, a1 + a2)): row.append(f"{v:.4f}")
                if k % 500 == 0: print(f"t = {k // 100:2d}:", f6(a1), f6(a2), f6(a1 + a2))
        if k < 2000: pts = [rk4(w, hs, C) for w in pts]
for n in (25, 50):
    print(f"t = 20, {n} points a side: sum {f6(sum(s[(n, 20)]))}, error {abs(sum(s[(n, 20)]) - A0):.1e}")
assert abs(sum(s[(50, 20)]) - A0) < 1e-5 and abs(s[(50, 15)][0]) < 0.01 and s[(50, 15)][1] > 0.5
for name, row in zip(("chart, shadow q1p1", "chart, shadow q2p2", "chart, sum"), chart):
    print(name, "[" + ", ".join(row) + "]")
stretch = lambda w: [2 * w[0], w[1], w[2] / 2, w[3]]   # state (q1, p1, q2, p2): q1 doubled, q2 halved
Js = [[stretch([float(k == j) for k in range(4)])[i] for j in range(4)] for i in range(4)]  # Jacobian: column j, image of axis j
sq = [tuple(stretch([q, p, 0.0, 0.0])[:2]) for q, p in square(50, Q0)]  # the patch, in swing 1's plane, stretched
print("stretch q1 x2, q2 x1/2: volume factor", f6(det(Js)), "omega on the patch", f6(shoelace(sq)))
assert abs(shoelace(sq) - 2 * A0) < 1e-9 and abs(det(Js) - 1) < 1e-12
print("try: Euler 600 steps", f6(shoelace(carry(square(100, Q0), euler, T / 600, 600))),
      "| leapfrog 15 steps", f6(shoelace(carry(square(100, Q0), leap, T / 15, 15))))
T90 = agm_period(-math.pi / 2)
print("try: release -90 deg, period", f"{T90:.6f}", "s, area after one swing",
      f6(shoelace(carry(square(100, -math.pi / 2), rk4, T90 / 600, 600))))
print("ALL CHECKS PASS")
