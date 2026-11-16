# Elliptic regularity on a heated brick wall: -(k u')' = f, u(0) = 20 C, u(L) = 0 C.
import math

L, K, T_IN, Q, A, W = 0.2, 0.77, 20.0, 100.0, 0.03, 0.01  # m, W/(m K), C, W/m2, m, m
F_BOX = Q / (2 * W)                                        # 5000 W/m3 in the cable layer
KW = 0.035                                                 # wool, for the two-material wall

def simpson(g, a, b, n):
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

def bump(t):
    return math.exp(-1.0 / (1.0 - t * t)) if abs(t) < 1.0 else 0.0

I0 = simpson(bump, -1.0, 1.0, 4000)
def f_bump(x): return Q / (W * I0) * bump((x - A) / W)
def df_bump(x):
    t = (x - A) / W
    return f_bump(x) * (-2.0 * t / (1.0 - t * t) ** 2) / W if abs(t) < 1.0 else 0.0

def qint(kind, x):  # integral of (x - y) f(y) dy from 0 to x: heat made before x, weighted
    if kind == "foil": return Q * max(x - A, 0.0)
    if kind == "box":
        if x <= A - W: return 0.0
        return F_BOX * (x - A + W) ** 2 / 2 if x <= A + W else Q * (x - A)
    hi = min(x, A + W)
    return simpson(lambda y: (x - y) * f_bump(y), A - W, hi, 2000) if hi > A - W else 0.0

C0 = Q * (L - A) / L - K * T_IN / L     # flux into the room at x = 0, W/m2 (Step 1)
def u_exact(kind, x): return T_IN + (C0 * x - qint(kind, x)) / K

def galerkin(n, kind):  # hat functions on n equal elements: the weak form only
    h = L / n
    kel = [K] * n if kind != "wall2" else [KW if (e + 0.5) * h < 0.1 else 0.77 for e in range(n)]
    b = [0.0] * (n + 1)
    if kind == "foil": b[round(A / h)] = Q
    for e in range(n):
        x0 = e * h
        if kind == "box" and A - W - 1e-12 <= x0 < A + W - 1e-12:
            b[e] += F_BOX * h / 2; b[e + 1] += F_BOX * h / 2
        if kind == "bump" and A - W - 1e-12 <= x0 < A + W - 1e-12:
            b[e] += simpson(lambda y: f_bump(y) * (x0 + h - y) / h, x0, x0 + h, 16)
            b[e + 1] += simpson(lambda y: f_bump(y) * (y - x0) / h, x0, x0 + h, 16)
    lo = [-kel[i - 1] / h for i in range(1, n)]
    di = [(kel[i - 1] + kel[i]) / h for i in range(1, n)]
    up = [-kel[i] / h for i in range(1, n)]
    rhs = b[1:n]; rhs[0] += kel[0] / h * T_IN
    for i in range(1, n - 1):          # Thomas algorithm
        m = lo[i] / di[i - 1]; di[i] -= m * up[i - 1]; rhs[i] -= m * rhs[i - 1]
    u = [0.0] * (n - 1); u[-1] = rhs[-1] / di[-1]
    for i in range(n - 3, -1, -1): u[i] = (rhs[i] - up[i] * u[i + 1]) / di[i]
    return [T_IN] + u + [0.0], h

def rms_diffs(u, h):  # root-mean-square of first, second and third differences over the wall
    n = len(u) - 1
    s1 = sum(h * ((u[i + 1] - u[i]) / h) ** 2 for i in range(n))
    s2 = sum(h * ((u[i + 1] - 2 * u[i] + u[i - 1]) / h ** 2) ** 2 for i in range(1, n))
    s3 = sum(h * ((u[i + 2] - 3 * u[i + 1] + 3 * u[i] - u[i - 1]) / h ** 3) ** 2 for i in range(1, n - 1))
    return math.sqrt(s1 / L), math.sqrt(s2 / L), math.sqrt(s3 / L)

print(f"wall: L = {L} m, k = {K} W/(m K), faces {T_IN:.0f} C and 0 C, heater {Q:.0f} W/m2 centred at {A} m")
print(f"unheated loss {K * T_IN / L:.4f} W/m2; heater sends {Q * (L - A) / L:.4f} to the room side, {Q * A / L:.4f} outward")
print(f"flux at the room face {C0:.4f} W/m2 into the room; at the outside face {Q - C0:.4f} W/m2 out")
assert abs(I0 - 0.443993816) < 1e-8
nodes = {}
for kind in ("foil", "box", "bump"):
    g, h = galerkin(10000, kind); nodes[kind] = (g, h)
    i3, i10 = round(0.03 / h), round(0.10 / h)
    e3, e10 = u_exact(kind, 0.03), u_exact(kind, 0.10)
    imax = max(range(len(g)), key=lambda i: g[i])
    print(f"{kind:4s}: u(3 cm) flux formula {e3:.6f}, Galerkin {g[i3]:.6f}; u(10 cm) {e10:.6f}, {g[i10]:.6f};"
          f" peak {g[imax]:.4f} C at {imax * h * 100:.3f} cm")
    assert abs(e3 - g[i3]) < 1e-6 and abs(e10 - g[i10]) < 1e-6
    assert abs(e10 - (T_IN / 2 + Q * A * (L - 0.10) / (K * L))) < 1e-9  # same outside the layer
xp = A - W + C0 / F_BOX
peak_hand = T_IN + C0 * (A - W) / K + (C0 * (xp - A + W) - F_BOX * (xp - A + W) ** 2 / 2) / K
print(f"box by hand: f = {F_BOX:.0f} W/m3, bend {-F_BOX / K:.2f} K/m2, u(2 cm) {T_IN + C0 * (A - W) / K:.4f} C,"
      f" peak {peak_hand:.4f} C at {xp * 100:.2f} cm")
assert abs(peak_hand - max(nodes["box"][0])) < 1e-5
hd = 1e-4
res = -K * (u_exact("bump", 0.03 + hd) - 2 * u_exact("bump", 0.03) + u_exact("bump", 0.03 - hd)) / hd ** 2
print(f"bump residual at 3 cm: -k u'' = {res:.2f}, f = {f_bump(0.03):.2f} W/m3")
assert abs(res - f_bump(0.03)) < 1e-3 * f_bump(0.03)
rb2 = math.sqrt(simpson(lambda x: f_bump(x) ** 2, A - W, A + W, 4000) / L) / K
rb3 = math.sqrt(simpson(lambda x: df_bump(x) ** 2, A - W, A + W, 4000) / L) / K
print(f"limits: box rms bend {F_BOX / K * math.sqrt(2 * W / L):.2f} K/m2; bump rms bend {rb2:.2f} K/m2,"
      f" rms third derivative {rb3:.0f} K/m3")
table = {}
for kind in ("foil", "box", "bump", "wall2"):
    for n in (100, 1000, 10000):
        u, h = galerkin(n, kind)
        s1, s2, s3 = rms_diffs(u, h); table[kind, n] = (s1, s2, s3)
        print(f"{kind:5s} h = {h * 1000:5.2f} mm: rms slope {s1:9.4f} K/m, rms 2nd diff {s2:10.2f} K/m2,"
              f" rms 3rd diff {s3:.4e} K/m3")
for n in (100, 1000):
    assert abs(table["foil", 10 * n][1] / table["foil", n][1] - math.sqrt(10)) < 1e-6
    assert abs(table["box", 10 * n][2] / table["box", n][2] - math.sqrt(10)) < 0.05
assert abs(table["box", 10000][1] - F_BOX / K * math.sqrt(2 * W / L)) < 1e-2 * table["box", 10000][1]
assert abs(table["bump", 10000][1] - rb2) < 1e-3 * rb2 and abs(table["bump", 10000][2] - rb3) < 1e-2 * rb3
for n in (100, 1000, 10000):
    h = L / n
    print(f"foil formula (Q/k)/sqrt(hL) at h = {h * 1000:5.2f} mm: {Q / K / math.sqrt(h * L):.2f} K/m2")
    assert abs(table["foil", n][1] - Q / K / math.sqrt(h * L)) < 1e-6 * table["foil", n][1]
u2, h2 = galerkin(10000, "wall2")
j = round(0.1 / h2); jump = (u2[j + 1] - u2[j] - u2[j] + u2[j - 1]) / h2
tj = T_IN * (0.1 / 0.77) / (0.1 / KW + 0.1 / 0.77)
print(f"two-material wall: joint {u2[j]:.6f} C (resistances {tj:.6f}), slope jump {jump:.2f} K/m")
assert abs(u2[j] - tj) < 1e-9 and abs(table["wall2", 100][1] - jump / math.sqrt(0.002 * L)) < 1e-6 * jump

def corner(alpha, opening, eps, ns=200, nphi=60):  # integral of |D2 u|^2, u = r^alpha sin(alpha phi)
    def hess2(r, p):
        x, y, d = r * math.cos(p), r * math.sin(p), 1e-3 * r
        def u(x, y):
            ph = math.atan2(y, x); ph = ph + 2 * math.pi if ph < -math.pi / 4 else ph
            return math.hypot(x, y) ** alpha * math.sin(alpha * ph)
        uxx = (u(x + d, y) - 2 * u(x, y) + u(x - d, y)) / d ** 2
        uyy = (u(x, y + d) - 2 * u(x, y) + u(x, y - d)) / d ** 2
        uxy = (u(x + d, y + d) - u(x + d, y - d) - u(x - d, y + d) + u(x - d, y - d)) / (4 * d * d)
        return uxx ** 2 + uyy ** 2 + 2 * uxy ** 2
    return simpson(lambda s: simpson(lambda p: hess2(math.exp(s), p), 0.0, opening, nphi)
                   * math.exp(2 * s), math.log(eps), 0.0, ns)

for eps in (1e-2, 1e-4, 1e-6):
    num, exact = corner(2 / 3, 1.5 * math.pi, eps), 2 * math.pi / 9 * (eps ** (-2 / 3) - 1)
    print(f"corner 270 deg, eps = {eps:.0e}: H2 energy {num:.4f}, closed form {exact:.4f} (scaled)")
    assert abs(num - exact) < 1e-4 * exact
c90 = corner(2.0, 0.5 * math.pi, 1e-6)
print(f"corner  90 deg, eps = 1e-06: H2 energy {c90:.4f}, closed form {2 * math.pi * (1 - 1e-12):.4f} (scaled)")
assert abs(c90 - 2 * math.pi) < 1e-4
print("chart, depth cm: " + ", ".join(f"{i}" for i in range(21)))
print("chart, heated u: " + ", ".join(f"{round(u_exact('bump', i / 100), 2) + 0.0:.2f}" for i in range(21)))
print("chart, unheated: " + ", ".join(f"{T_IN * (1 - i / 20):.2f}" for i in range(21)))
xs = [1.5 + 0.2 * i for i in range(16)]
print("chart, bend x cm: " + ", ".join(f"{x:.1f}" for x in xs))
print("chart, box bend: " + ", ".join(f"{(-F_BOX / K if 2 < x < 4 else 0.0):.0f}" for x in xs))
print("chart, bump bend: " + ", ".join(f"{-f_bump(x / 100) / K + 0.0:.0f}" for x in xs))
print("ALL CHECKS PASS")
