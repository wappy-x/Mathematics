# Lagrangian mechanics -- the check behind the card.  Imports only sin, cos and pi.
# Road one knows only L = T - V and gets each acceleration from the Euler-Lagrange
# equation by numerical slopes of L.  Road two steps the equations derived by hand.
from math import sin, cos, pi
G, M, LEN, TH0 = 9.81, 30.0, 2.0, pi / 6          # swing: 30 kg, 2 m rods, released at 30 deg
MB, R, I, W0 = 0.5, 0.5, 0.25, 6.0                # bead kg, hoop radius m, hoop inertia kg m^2, spin rad/s
def l_swing(q, v): return 0.5 * M * LEN**2 * v[0]**2 + M * G * LEN * cos(q[0])
def l_wrong(q, v): return 0.5 * M * LEN**2 * v[0]**2 - M * G * LEN * cos(q[0])   # T + V, mistake 1
def l_hoop(q, v): return 0.5 * I * v[1]**2 + 0.5 * MB * R**2 * (v[0]**2 + sin(q[0])**2 * v[1]**2) + MB * G * R * cos(q[0])
def slope(f, x, i, e=1e-4):                       # central difference of f in its i-th input
    xp, xm = list(x), list(x); xp[i] += e; xm[i] -= e; return (f(xp) - f(xm)) / (2 * e)
def acc_from_l(lag, q, v):                        # solve  sum_j L_vi,vj a_j = L_qi - sum_j L_vi,qj v_j
    n, s = len(q), list(q) + list(v); f = lambda x: lag(x[:n], x[n:])
    p = [lambda x, i=i: slope(f, x, n + i) for i in range(n)]          # momenta dL/dv_i
    a = [[slope(p[i], s, n + j) for j in range(n)] for i in range(n)]
    b = [slope(f, s, i) - sum(slope(p[i], s, j) * v[j] for j in range(n)) for i in range(n)]
    if n == 1: return [b[0] / a[0][0]]
    det = a[0][0] * a[1][1] - a[0][1] * a[1][0]; return [(b[0] * a[1][1] - a[0][1] * b[1]) / det, (a[0][0] * b[1] - b[0] * a[1][0]) / det]
def acc_swing(q, v): return [-(G / LEN) * sin(q[0])]
def acc_hoop(q, v):                               # q = (theta, phi), v = (theta', phi')
    c, s = cos(q[0]), sin(q[0]); return [s * c * v[1]**2 - (G / R) * s, -2 * MB * R**2 * s * c * v[0] * v[1] / (I + MB * R**2 * s * s)]
def run(acc, s, h, steps):                        # Runge-Kutta 4 on q' = v, v' = acc(q, v)
    n, out, ad = len(s) // 2, [s], lambda s, k, c: [x + c * y for x, y in zip(s, k)]; f = lambda s: s[n:] + acc(s[:n], s[n:])
    for _ in range(steps):
        s = out[-1]; k1 = f(s); k2 = f(ad(s, k1, h / 2)); k3 = f(ad(s, k2, h / 2)); k4 = f(ad(s, k3, h))
        out.append([x + h / 6 * (a + 2 * b + 2 * c + d) for x, a, b, c, d in zip(s, k1, k2, k3, k4)])
    return out
a1, a2 = acc_from_l(l_swing, [TH0], [0.0])[0], acc_swing([TH0], [0.0])[0]
sw1, sw2 = run(lambda q, v: acc_from_l(l_swing, q, v), [TH0, 0.0], 0.01, 100), run(acc_swing, [TH0, 0.0], 0.01, 100)
print(f"swing: m l^2 = {M * LEN**2:.1f} kg m^2, m g l = {M * G * LEN:.1f} J; at 30 deg, angular acceleration "
      f"from L alone {a1:.6f}, from -(g/l) sin {a2:.6f} rad/s^2\n"
      f"swing angle at 1 s: road one {sw1[-1][0]:.6f}, road two {sw2[-1][0]:.6f} rad; speed {sw2[-1][1]:.6f} rad/s")
fine = run(acc_swing, [TH0, 0.0], 0.001, 1000)                   # the true path, 0 to 1 s, and a straight line
line = [[TH0 + (fine[-1][0] - TH0) * k / 1000, fine[-1][0] - TH0] for k in range(1001)]
def action(path, eps, h=0.001):                  # trapezoid sum of L along path + eps * sin(pi t); eps = +-0.01 rad
    vals = [l_swing([s[0] + eps * sin(pi * k * h)], [s[1] + eps * pi * cos(pi * k * h)]) for k, s in enumerate(path)]
    return h * (sum(vals) - 0.5 * (vals[0] + vals[-1]))
first = lambda p: (action(p, 0.01) - action(p, -0.01)) / 0.02; second = lambda p: (action(p, 0.01) + action(p, -0.01) - 2 * action(p, 0.0)) / 2e-4
q2 = 0.0005 * sum((1 if 0 < k < 1000 else 0.5) * (M * LEN**2 * (pi * cos(pi * k / 1000))**2
     - M * G * LEN * cos(s[0]) * sin(pi * k / 1000)**2) for k, s in enumerate(fine))
for name, pth in (("true path", fine), ("straight line", line)):
    print(f"{name}: action {action(pth, 0.0):.6f} J s; first-order change {first(pth):.6f}, second-order {second(pth):.4f}")
print(f"second variation, 0.5 x integral of (m l^2 eta'^2 - m g l cos(theta) eta^2): {q2:.4f}")
h1, h2 = run(lambda q, v: acc_from_l(l_hoop, q, v), [0.3, 0.0, 0.0, W0], 0.01, 300), run(acc_hoop, [0.3, 0.0, 0.0, W0], 0.01, 300)
p1 = [slope(lambda v: l_hoop(s[:2], v), s[2:], 1) for s in h1]; mom = [(I + MB * R**2 * sin(s[0])**2) * s[3] for s in h2]  # dL/dphi': by slope; by hand
print(f"hoop at 3 s: bead angle road one {h1[-1][0]:.6f}, road two {h2[-1][0]:.6f} rad; over 0 to 3 s the bead "
      f"swings {min(s[0] for s in h2):.4f} to {max(s[0] for s in h2):.4f} rad, the hoop spins {min(s[3] for s in h2):.4f} to {max(s[3] for s in h2):.4f} rad/s")
print(f"momentum (I + m R^2 sin^2 theta) phi', m R^2 = {MB * R**2:.3f}, at the start {mom[0] / W0:.6f} x {W0:g}; road two: min {min(mom):.6f}, max {max(mom):.6f}; "
      f"slope of L in phi', road one: min {min(p1):.6f}, max {max(p1):.6f} kg m^2/s")
dr = run(lambda q, v: acc_hoop(q, [v[0], W0])[:1], [0.3, 0.0], 0.01, 300); pd = [(I + MB * R**2 * sin(s[0])**2) * W0 for s in dr]  # motor holds phi'
print("chart, t = 0, 0.25 ... 3 s, hoop spin:", " ".join(f"{h2[k][3]:.2f}" for k in range(0, 301, 25)))
print(f"mistake 1, L = T + V: acceleration at 30 deg {acc_from_l(l_wrong, [TH0], [0.0])[0]:.6f} rad/s^2; mistake 2, hoop spin alone "
      f"I phi': {min(I * s[3] for s in h2):.4f} to {max(I * s[3] for s in h2):.4f} kg m^2/s\nmistake 3, motor-held spin: bead to {max(s[0] for s in dr):.4f} rad, momentum {min(pd):.6f} to {max(pd):.6f} kg m^2/s")
print("figure, 60 units per metre: pivot 180.0,30.0; seat at 30 deg %.1f,%.1f; seat at rest %.1f,%.1f; drop %.3f m; angle arc 40 units, ends 180.0,70.0 and %.1f,%.1f"
      % (180 + 60 * LEN * sin(TH0), 30 + 60 * LEN * cos(TH0), 180.0, 30 + 60 * LEN, LEN * (1 - cos(TH0)), 180 + 40 * sin(TH0), 30 + 40 * cos(TH0)))
assert abs(a1 - a2) < 1e-6 and abs(sw1[-1][0] - sw2[-1][0]) < 1e-6          # road one = road two, swing
assert abs(h1[-1][0] - h2[-1][0]) < 1e-5 and max(p1) - min(p1) < 1e-6        # road one = road two, hoop
assert abs(first(fine)) < 0.01 < abs(first(line))                            # stationary only on the true path
assert abs(second(fine) - q2) < 1e-3 * q2                                    # nudge cost = second variation
print("ALL CHECKS PASS")
