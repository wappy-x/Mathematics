# Green's function and the representation formula -- the check behind the card.
# A 1 m concrete cube: top face on a hot plate at 80 C, the other five faces at 20 C,
# a 20 W heater inside at a, a sensor at b.  Standard library only.
# Road 1: G and the wall weights as sine-sinh series (the closed form).
# Road 2: G = Phi - h, the corrector h solved on a grid by SOR, never using the series.
# Road 3: exact facts: the centre weighs each face 1/6; all weights add to 1.
from math import pi, sin, sinh, exp, sqrt, log

def G_series(x, y, N):      # unit poke at y, walls at 0, read at x; sum over l, m up to N
    zl, zh, tot = min(x[2], y[2]), max(x[2], y[2]), 0.0
    for l in range(1, N + 1):
        for m in range(1, N + 1):
            be = pi * sqrt(l * l + m * m)
            tot += (4 * sin(l * pi * x[0]) * sin(l * pi * y[0]) * sin(m * pi * x[1]) * sin(m * pi * y[1])
                    * sinh(be * zl) * sinh(be * (1 - zh)) / (be * sinh(be)))
    return tot

def w_top(x, N):            # weight of the face z = 1 at x: the integral of P = -dG/dn over that face
    tot = 0.0
    for l in range(1, N + 1, 2):
        for m in range(1, N + 1, 2):
            be = pi * sqrt(l * l + m * m)
            ratio = (exp(be * (x[2] - 1)) - exp(-be * (x[2] + 1))) / (1 - exp(-2 * be))   # sinh(be z)/sinh(be)
            tot += 16 / (pi * pi * l * m) * sin(l * pi * x[0]) * sin(m * pi * x[1]) * ratio
    return tot

def weights(x, N):          # all six faces, by turning the cube so each face is on top
    a, b, c = x
    pts = [(a, b, c), (a, b, 1 - c), (b, c, a), (b, c, 1 - a), (a, c, b), (a, c, 1 - b)]
    return [w_top(p, N) for p in pts]   # top, bottom, x = 1, x = 0, y = 1, y = 0

def sor(n, bc):             # Laplace's equation on the grid, wall values bc, SOR sweeps
    M, om = n + 1, 2 / (1 + sin(pi / n))
    u = [0.0] * (M * M * M)
    for i in range(M):
        for j in range(M):
            for k in range(M):
                if 0 in (i, j, k) or n in (i, j, k): u[(i * M + j) * M + k] = bc(i / n, j / n, k / n)
    for _ in range(15 * n):
        for i in range(1, n):
            for j in range(1, n):
                for k in range(1, n):
                    p = (i * M + j) * M + k
                    s = u[p - M * M] + u[p + M * M] + u[p - M] + u[p + M] + u[p - 1] + u[p + 1]
                    u[p] += om * (s / 6 - u[p])
    return lambda x: u[(round(x[0] * n) * M + round(x[1] * n)) * M + round(x[2] * n)]

def Phi(x, y): return 1 / (4 * pi * sqrt(sum((p - q) ** 2 for p, q in zip(x, y))))

Q, kc, hot, cold = 20.0, 1.4, 80.0, 20.0      # heater W, concrete W/(m K) (illustrative), plate C, jacket C
a, b, c = (0.2, 0.3, 0.4), (0.5, 0.5, 0.8), (0.5, 0.5, 0.5)
f6 = lambda v: f"{v:.6f}"
print(f"box 1 m cube; plate {hot:.0f} C on top, {cold:.0f} C on five faces; heater {Q:.0f} W at a = (0.2, 0.3, 0.4) m, sensor b = (0.5, 0.5, 0.8) m, k = {kc} W/(m K)")
# ---- wall data alone: the weights ----
wc, wb = weights(c, 81), weights(b, 81)
one_term = 16 / pi ** 2 * sinh(pi * sqrt(2) / 2) / sinh(pi * sqrt(2))
print("face weights at centre c  (top, bottom, x=1, x=0, y=1, y=0): " + " ".join(f6(w) for w in wc))
print(f"  sum {sum(wc):.6f}; one-term top weight 16/pi^2 sinh(pi sqrt2/2)/sinh(pi sqrt2) = {one_term:.6f}")
print("face weights at sensor b  (top, bottom, x=1, x=0, y=1, y=0): " + " ".join(f6(w) for w in wb))
print(f"  sum {sum(wb):.6f}; first omitted term (l = 1, m = 83) {16 / (pi * pi * 83) * exp(-0.2 * pi * sqrt(1 + 83 * 83)):.1e}")
for name, x, w in (("centre c", c, wc), ("sensor b", b, wb)):
    print(f"walls alone at {name}: 20 + 60 x {w[0]:.6f} = {cold + (hot - cold) * w[0]:.4f} C;"
          f" sum of weight x wall temp = {hot * w[0] + cold * sum(w[1:]):.4f} C")
print("bars, weight at b in % : " + " ".join(f"{100 * w:.1f}" for w in wb))
S80 = [(i / 80, (1 if i in (0, 80) else 4 if i % 2 else 2) / 240) for i in range(81)]   # Simpson's rule, 80 strips
hn = 1e-4                   # the wall weight -dG/dn from G itself: G = 0 on the face, so -dG/dn ~ G(b, y)/hn just inside
w_from_G = sum(ws * wt * G_series(b, (s, t, 1 - hn), 40) for s, ws in S80 for t, wt in S80) / hn
print(f"top weight at b from G itself (Simpson 80 x 80 over the face, slope from 1e-4 m inside): {w_from_G:.6f}; series {wb[0]:.6f}")
# ---- the poke: G(b, a) and G(a, b) ----
g40, g20 = G_series(b, a, 40), G_series(b, a, 20)
gs_ab = G_series(a, b, 40)
print(f"Phi(b - a) = 1/(4 pi |b - a|) = {Phi(a, b):.6f} 1/m, |b - a| = {sqrt(0.29):.6f} m")
print(f"series G(b, a) N = 40: {g40:.6f} 1/m; N = 20 differs by {abs(g40 - g20):.1e}; corrector h_a(b) = {Phi(a, b) - g40:.6f}")
grid, walls_b = {}, cold + (hot - cold) * wb[0]
for n in (10, 20):
    ha, hb = sor(n, lambda *p: Phi(p, a)), sor(n, lambda *p: Phi(p, b))
    uw = sor(n, lambda x, y, z: hot if z == 1 else cold)
    grid[n] = (Phi(a, b) - ha(b), Phi(a, b) - hb(a), uw(b), uw(c))
    print(f"grid step {1 / n:.2f} m: G(b, a) = {grid[n][0]:.6f}, G(a, b) = {grid[n][1]:.6f}, walls at b {grid[n][2]:.4f} C, at c {grid[n][3]:.4f} C")
e10, e20 = abs(grid[10][0] - g40), abs(grid[20][0] - g40)
rich_ba, rich_ab = (4 * grid[20][0] - grid[10][0]) / 3, (4 * grid[20][1] - grid[10][1]) / 3
print(f"grid error in G(b, a): {e10:.2e} at step 0.1 m, {e20:.2e} at step 0.05 m, observed order {log(e10 / e20) / log(2):.2f}")
print(f"grid error in walls at b: {abs(grid[10][2] - walls_b):.4f} C at step 0.1 m, {abs(grid[20][2] - walls_b):.4f} C at step 0.05 m")
print(f"extrapolated (4 G_fine - G_coarse)/3: G(b, a) = {rich_ba:.6f}, G(a, b) = {rich_ab:.6f}; series G(a, b) = {gs_ab:.6f}")
rise = Q / kc * g40
print(f"heater rise at b = (Q/k) G(b, a) = {Q / kc:.4f} x {g40:.6f} = {rise:.4f} C")
print(f"sensor reading at b = {walls_b:.4f} + {rise:.4f} = {walls_b + rise:.4f} C")
print(f"swap heater and sensor: rise at a from the heater at b = {Q / kc * gs_ab:.4f} C")
# ---- Green's identities on u = x^2 y + z, v = x y z + y^2, by Simpson (exact for cubics) ----
S = [(i / 4, (1 if i in (0, 4) else 4 if i % 2 else 2) / 12) for i in range(5)]
vol = lambda F: sum(wx * wy * wz * F(x, y, z) for x, wx in S for y, wy in S for z, wz in S)
def wall(F):                 # sum over the six faces of F(point, outward normal)
    tot = 0.0
    for ax in range(3):
        for side, nrm in ((0.0, -1.0), (1.0, 1.0)):
            for s, ws in S:
                for t, wt in S:
                    p = [s, t]; p.insert(ax, side); nv = [0.0, 0.0, 0.0]; nv[ax] = nrm
                    tot += ws * wt * F(p, nv)
    return tot
u = lambda x, y, z: x * x * y + z;  gu = lambda x, y, z: (2 * x * y, x * x, 1.0);  Lu = lambda x, y, z: 2 * y
v = lambda x, y, z: x * y * z + y * y;  gv = lambda x, y, z: (y * z, x * z + 2 * y, x * y);  Lv = lambda x, y, z: 2.0
dot = lambda p, q: sum(i * j for i, j in zip(p, q))
I1 = vol(lambda *p: v(*p) * Lu(*p) + dot(gu(*p), gv(*p)));  B1 = wall(lambda p, nv: v(*p) * dot(gu(*p), nv))
I2 = vol(lambda *p: u(*p) * Lv(*p) - v(*p) * Lu(*p));  B2 = wall(lambda p, nv: u(*p) * dot(gv(*p), nv) - v(*p) * dot(gu(*p), nv))
print(f"first identity:  inside {I1:.6f}, walls {B1:.6f};  second identity: inside {I2:.6f}, walls {B2:.6f}")
# ---- what breaks ----
print(f"mistake 1, Phi for G (no walls): rise {Q / kc * Phi(a, b):.4f} C, not {rise:.4f}")
print(f"mistake 2, wall term dropped: reading {rise:.4f} C, not {walls_b + rise:.4f}")
print(f"mistake 3, inward normal: walls give {-walls_b:.4f} C, reading {rise - walls_b:.4f} C")
print(f"mistake 4, insulated walls: unit poke's wall flux = -(sum of weights at a) = {-sum(weights(a, 81)):.4f}, needs 0")
print(f"try: sensor at centre: {cold + (hot - cold) * wc[0] + Q / kc * G_series(c, a, 40):.4f} C; heater 40 W: rise {2 * rise:.4f} C; plate at 20 C: {cold + rise:.4f} C")
print(f"figure, side view x-z, 300 px/m, origin (60,360): heater ({60 + 300 * a[0]:.0f},{360 - 300 * a[2]:.0f}) "
      f"sensor ({60 + 300 * b[0]:.0f},{360 - 300 * b[2]:.0f}) centre ({60 + 300 * c[0]:.0f},{360 - 300 * c[2]:.0f})")
assert abs(wc[0] - 1 / 6) < 1e-9 and abs(sum(wb) - 1) < 1e-9           # series vs exact facts
assert abs(w_from_G - wb[0]) < 1e-5                                    # wall weight from G vs the face series
assert abs(rich_ba - g40) < 2e-5 and abs(rich_ab - g40) < 2e-5          # grid road vs series road
assert abs(grid[20][2] - walls_b) < abs(grid[10][2] - walls_b) < 0.5   # grid settles on the series
assert abs(I1 - B1) < 1e-12 and abs(I2 - B2) < 1e-12 and abs(I1) > 0.1  # identities, both sides
print("ALL CHECKS PASS")
