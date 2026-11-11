# Newton's laws on a thrown cricket ball: the check behind the card. Standard library only.
# The equation of motion m dv/dt = m g + drag is stepped with RK4 written out. The drag work
# rides along as an extra state; the drag impulse is added up apart, by Simpson's rule.
from math import sqrt, sin, cos, atan, log, radians, pi

G, RHO = 9.80665, 1.225            # standard gravity, m/s^2; sea-level air density, kg/m^3
M, DIAM, CD = 0.160, 0.072, 0.40   # ball mass, kg; diameter, m; drag coefficient
AREA = pi * DIAM * DIAM / 4.0      # frontal area, m^2
K = RHO * CD * AREA / (2.0 * M)    # drag deceleration per (m/s)^2, 1/m
V0, DEG = 30.0, 45.0               # the throw: 30 m/s at 45 degrees, from ground level

def drag(s, k, lin):                # drag deceleration across and up, m/s^2: straight against v
    f = k * V0 if lin else k * sqrt(s[2] * s[2] + s[3] * s[3])   # per m/s, 1/s
    return -f * s[2], -f * s[3]

def deriv(s, k, lin):               # s = [x, y, vx, vy, W]: position, velocity, drag work
    ax, ay = drag(s, k, lin)
    return [s[2], s[3], ax, ay - G, M * (ax * s[2] + ay * s[3])]

def rk4(s, h, k, lin):
    a = deriv(s, k, lin)
    b = deriv([p + h / 2 * q for p, q in zip(s, a)], k, lin)
    c = deriv([p + h / 2 * q for p, q in zip(s, b)], k, lin)
    d = deriv([p + h * q for p, q in zip(s, c)], k, lin)
    return [p + h / 6 * (qa + 2 * qb + 2 * qc + qd) for p, qa, qb, qc, qd in zip(s, a, b, c, d)]

def to_zero(s, t, i, k, lin):
    for _ in range(4):             # Newton steps in time until s[i] is zero
        hh = -s[i] / deriv(s, k, lin)[i]
        s, t = rk4(s, hh, k, lin), t + hh
    return s, t

def fly(v0, deg, k, lin=False, h=1e-3, y0=0.0):
    th = radians(deg)
    s, t, top, path = [0.0, y0, v0 * cos(th), v0 * sin(th), 0.0], 0.0, None, []
    while True:
        path.append(s)
        n = rk4(s, h, k, lin)
        if top is None and n[3] <= 0.0:
            top = to_zero(s, t, 3, k, lin)
        if n[1] < 0.0:
            return to_zero(s, t, 1, k, lin), top, path
        s, t = n, t + h

def impulse(path, land, T, k, h=1e-3):
    # Drag impulse by Simpson's rule: drag at the start, middle and end of each step, weighted
    # 1, 4, 1. It never uses the RK4 velocity update, so it is a second road to the momentum change.
    J, n = [0.0, 0.0], len(path) - 1
    for i, (p, q) in enumerate(zip(path, path[1:] + [land])):
        dt = h if i < n else T - n * h             # the last step is cut short at the landing
        f0, fm, f1 = drag(p, k, False), drag(rk4(p, dt / 2, k, False), k, False), drag(q, k, False)
        J = [J[j] + M * dt / 6 * (f0[j] + 4 * fm[j] + f1[j]) for j in (0, 1)]
    return J

def ke(s): return 0.5 * M * (s[2] * s[2] + s[3] * s[3])
def speed(s): return sqrt(s[2] * s[2] + s[3] * s[3])

def height_at(path, land, x):      # straight-line read-off between steps; 0 m once landed
    if x >= land[0]: return 0.0
    for p, q in zip(path, path[1:] + [land]):
        if p[0] <= x <= q[0]:
            return p[1] + (q[1] - p[1]) * (x - p[0]) / (q[0] - p[0])

def line(name, *vals, unit="", d=4): print(f"{name:<38}" + "".join(f"{v:>11.{d}f}" for v in vals) + " " + unit)

th = radians(DEG)
R0, T0, H0 = V0 * V0 * sin(2 * th) / G, 2 * V0 * sin(th) / G, (V0 * sin(th)) ** 2 / (2 * G)
(vac, tv), (vtop, _), vpath = fly(V0, DEG, 0.0)
(land, T), (top, ttop), path = fly(V0, DEG, K)
Jx, Jy = impulse(path, land, T, K)
(land2, _), _, _ = fly(V0, DEG, K, h=5e-4)
_, (up, tup), _ = fly(V0, 90.0, K)
H_up, t_up = log(1 + K * V0 * V0 / G) / (2 * K), atan(V0 * sqrt(K / G)) / sqrt(G * K)
s0 = path[0]
lob, lob0 = fly(10.0, DEG, K)[0][0][0], 100.0 / G
best = max(range(30, 51), key=lambda a: fly(V0, a, K)[0][0][0])

line("frontal area A", AREA, unit="m^2", d=6)
line("drag constant k = rho Cd A / 2m", K, unit="1/m", d=6)
line("weight m g / drag at release m k v0^2", M * G, M * K * V0 * V0, unit="N")
line("terminal speed sqrt(g/k)", sqrt(G / K), unit="m/s")
line("launch velocity across / up", s0[2], s0[3], unit="m/s")
line("Reynolds number v0 D / nu, nu=1.46e-5", V0 * DIAM / 1.46e-5, unit="(pure number)", d=0)
print(f"{'':<38}{'formula':>11}{'RK4':>11}")
line("1 no air: range", R0, vac[0], unit="m")
line("  no air: flight time", T0, tv, unit="s")
line("  no air: peak height", H0, vtop[1], unit="m")
line("2 straight up, drag: peak height", H_up, up[1], unit="m")
line("  straight up, drag: time to peak", t_up, tup, unit="s")
print(f"{'3 with drag':<38}{'step 1 ms':>11}{'step 0.5ms':>11}")
line("  range", land[0], land2[0], unit="m")
line("  range lost to the air, vs no air", R0 - land[0], unit="m")
line("  landing velocity across / up", land[2], land[3], unit="m/s")
line("  flight time / landing speed", T, speed(land), unit="s, m/s")
line("  peak height / time of peak", top[1], ttop, unit="m, s")
line("4 kinetic energy at release / landing", ke(s0), ke(land), unit="J")
line("  change in KE / drag work on path", ke(land) - ke(s0), land[4], unit="J")
line("  at peak: change in KE / -mgH + W", ke(top) - ke(s0), -M * G * top[1] + top[4], unit="J")
line("5 across: momentum change / impulse", M * (land[2] - s0[2]), Jx, unit="kg m/s")
line("  up: momentum change / impulse", M * (land[3] - s0[3]), Jy - M * G * T, unit="kg m/s")
line("  up: drag impulse / gravity impulse", Jy, -M * G * T, unit="kg m/s")
line("wrong: no air, range", R0, unit="m")
line("wrong: drag without the 1/2, range", fly(V0, DEG, 2 * K)[0][0][0], unit="m")
line("wrong: drag linear in v, range", fly(V0, DEG, K, lin=True)[0][0][0], unit="m")
line("wrong: energy kept, landing speed", V0, unit="m/s")
line("lob 10 m/s: range with drag / no air", lob, lob0, unit="m")
line("try: best angle / range there", best, fly(V0, best, K)[0][0][0], unit="deg, m")
line("try: Cd = 0.5, range", fly(V0, DEG, K * 0.5 / CD)[0][0][0], unit="m")
line("try: 40 m/s, range drag / no air", fly(40.0, DEG, K)[0][0][0], 1600.0 / G, unit="m")
line("try: release 2 m up, range", fly(V0, DEG, K, y0=2.0)[0][0][0], unit="m")

print(f"{'time s':>8}{'height m':>10}{'speed m/s':>11}{'KE J':>8}{'PE J':>8}{'lost J':>8}{'total J':>9}")
for i in (0, 500, 1000, 1500, 2000, 2500, 3000, 3500, None):
    s, t = (land, T) if i is None else (path[i], i * 1e-3)
    pe, lost = M * G * abs(s[1]), 0.0 - s[4]
    print(f"{t:>8.2f}{abs(s[1]):>10.2f}{speed(s):>11.2f}{ke(s):>8.2f}{pe:>8.2f}{lost:>8.2f}{ke(s) + pe + lost:>9.2f}")
xs = [10.0 * i for i in range(10)]
print("chart, distance m      " + " ".join(f"{x:5.0f}" for x in xs))
print("chart, height no air m " + " ".join(f"{height_at(vpath, vac, x):5.1f}" for x in xs))
print("chart, height drag m   " + " ".join(f"{height_at(path, land, x):5.1f}" for x in xs))

assert abs(vac[0] - R0) < 1e-6
assert abs(tv - T0) < 1e-9
assert abs(vtop[1] - H0) < 1e-6
assert abs(up[1] - H_up) < 1e-6
assert abs(tup - t_up) < 1e-9
assert abs(land[0] - land2[0]) < 1e-6
assert abs((ke(land) - ke(s0)) - land[4]) < 1e-6
assert abs((ke(top) - ke(s0)) - (-M * G * top[1] + top[4])) < 1e-6
assert abs(M * (land[2] - s0[2]) - Jx) < 1e-9
assert abs(M * (land[3] - s0[3]) - (Jy - M * G * T)) < 1e-9
assert land[0] < 0.8 * R0
assert abs(lob - lob0) / lob0 < 0.05
print("ALL CHECKS PASS")
