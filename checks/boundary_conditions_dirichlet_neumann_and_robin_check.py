# Boundary conditions -- the check behind the card.  Standard library only.
# A 1 m square steel plate, 10 mm thick, faces insulated, so heat moves in its
# plane.  Bottom edge held at 20 + 60 sin(pi x) C, sides held at 20 C; the top
# edge is held at 20 C (D), insulated (N) or cooled by 20 C air (R).  v = u - 20.
# Road one: closed forms in sinh and cosh.  Road two: a grid solved by
# over-relaxed Gauss-Seidel, written out.  Road three: the heat budget, each
# edge's flux summed by Simpson's rule.  Then the tube (periodic) and the
# all-insulated plate fed and drained through its edges (compatibility).
import math
pi, k, d, rho, c = math.pi, 50.0, 0.01, 7850.0, 490.0   # W/(m K), m, kg/m^3, J/(kg K)
ch, sh = math.cosh, math.sinh
def Y(kind, y, b=0.5):               # profile up the plate, Y(0) = 1; b = h/k per m
    if kind == "D": return sh(pi * (1 - y)) / sh(pi)
    if kind == "N": return ch(pi * (1 - y)) / ch(pi)
    return (pi * ch(pi * (1 - y)) + b * sh(pi * (1 - y))) / (pi * ch(pi) + b * sh(pi))
def dY(kind, y, b=0.5):              # its slope, from the same formulas
    if kind == "D": return -pi * ch(pi * (1 - y)) / sh(pi)
    if kind == "N": return -pi * sh(pi * (1 - y)) / ch(pi)
    return -pi * (pi * sh(pi * (1 - y)) + b * ch(pi * (1 - y))) / (pi * ch(pi) + b * sh(pi))
def simpson(f, n=200):               # integral of f over [0, 1]
    s = f(0) + f(1) + sum((4 if i % 2 else 2) * f(i / n) for i in range(1, n))
    return s / (3 * n)
def plate(N, kind, b=0.5, tube=False):   # grid road; tube joins x = 0 to x = 1
    hh, w = 1 / N, 2 / (1 + math.sin(pi / N))
    cols = range(N) if tube else range(1, N)
    v = [[0.0] * (N + 1) for _ in range(N + 1)]
    for i in range(N + 1):
        v[i][0] = 30 - 30 * math.cos(2 * pi * i * hh) if tube else 60 * math.sin(pi * i * hh)
    last = N if kind in "NR" else N - 1
    while True:
        big = 0.0
        for i in cols:
            l, r = (i - 1) % N, (i + 1) % N if tube else i + 1
            for j in range(1, last + 1):
                if j < N: new = (v[l][j] + v[r][j] + v[i][j - 1] + v[i][j + 1]) / 4
                else: new = (v[l][j] + v[r][j] + 2 * v[i][j - 1]) / (4 + 2 * hh * (b if kind == "R" else 0))
                dv = w * (new - v[i][j]); v[i][j] += dv; big = max(big, abs(dv))
        if big < 1e-13: return v
def insulated(N, g_in, g_out, tilt, sweeps=0):    # all four edges given du/dn
    hh, w = 1 / N, 2 / (1 + math.sin(pi / N))
    u = [[20 + tilt * i / N] * (N + 1) for i in range(N + 1)]   # start 20 C, tilted
    for s in range(sweeps or 10 ** 6):
        big = 0.0
        for i in range(N + 1):
            for j in range(N + 1):
                l = u[i - 1][j] if i > 0 else u[1][j]
                r = u[i + 1][j] if i < N else u[N - 1][j]
                dn = u[i][j - 1] if j > 0 else u[i][1] + 2 * hh * g_in
                up = u[i][j + 1] if j < N else u[i][N - 1] - 2 * hh * g_out
                du = w * ((l + r + dn + up) / 4 - u[i][j]); u[i][j] += du; big = max(big, abs(du))
        if not sweeps and big < 1e-12: return u
    return u
mean = lambda u: sum(map(sum, u)) / len(u) ** 2
names = {"D": "held 20 C", "N": "insulated", "R": "air-cooled"}
print("plate 1 m x 1 m x 10 mm steel, k = 50 W/(m K); bottom 20 + 60 sin(pi x) C, sides 20 C")
for kd in "DNR":
    print(f"top {names[kd]:10s}: centre {20 + 60 * Y(kd, 0.5):.3f} C, top middle {20 + 60 * Y(kd, 1):.3f} C")
print(f"hand: sinh pi {sh(pi):.4f}, cosh pi {ch(pi):.4f}, sinh pi/2 {sh(pi / 2):.4f}, cosh pi/2 {ch(pi / 2):.4f}; h/k = {25 / k:.1f} per m")
print(f"hand: Y(1/2) held {Y('D', 0.5):.5f}, insulated {Y('N', 0.5):.5f}, air-cooled"
      f" {pi * ch(pi / 2) + 0.5 * sh(pi / 2):.4f}/{pi * ch(pi) + 0.5 * sh(pi):.4f} = {Y('R', 0.5):.5f}")
print(f"hand: heat in, held 60 coth pi = {60 * ch(pi) / sh(pi):.4f} W, insulated 60 tanh pi = {60 * sh(pi) / ch(pi):.4f} W")
print("road two, grid centre at h = 0.1 0.05 0.025 m, and error ratios:")
for kd in "DNR":
    ex = 60 * Y(kd, 0.5)
    e = [abs(plate(N, kd)[N // 2][N // 2] - ex) for N in (10, 20, 40)]
    print(f"  {names[kd]:10s}: errors {e[0]:.5f} {e[1]:.5f} {e[2]:.5f} K, ratios {e[0] / e[1]:.2f} {e[1] / e[2]:.2f}")
    assert e[2] < 0.02 and 3.6 < e[0] / e[1] < 4.4 and 3.6 < e[1] / e[2] < 4.4
S = simpson(lambda x: math.sin(pi * x))           # 2/pi, by Simpson
print("road three, heat budget in W: in at bottom = out through sides + out at top")
for kd in "DNR":
    pin = k * d * 60 * -dY(kd, 0) * S
    side = 2 * k * d * 60 * pi * simpson(lambda y: Y(kd, y))
    top = k * d * 60 * -dY(kd, 1) * S
    print(f"  {names[kd]:10s}: {pin:.4f} = {side:.4f} + {top:.4f}")
    assert abs(pin - side - top) < 1e-8
e = 1e-4
for kd in "DNR":                     # the top condition, by centred differences
    slope = (Y(kd, 1 + e) - Y(kd, 1 - e)) / (2 * e)
    res = {"D": Y(kd, 1), "N": slope, "R": slope + 0.5 * Y(kd, 1)}[kd]
    assert abs(res) < 1e-7
print("Robin top middle, h = 0 25 250 2500 W/(m^2 K) and held:", " ".join(
    f"{20 + 60 * Y('R', 1, hv / k):.3f}" for hv in (0, 25, 250, 2500)), "20.000 C")
assert abs(Y("R", 1, 0) - Y("N", 1)) < 1e-12 and abs(Y("R", 0.5, 1e9) - Y("D", 0.5)) < 1e-8
ys = [j / 10 for j in range(11)]
for kd in "DNR":
    print(f"chart, {names[kd]:10s}", " ".join(f"{20 + 60 * Y(kd, y):.2f}" for y in ys))
tube_ex = lambda x, y: 30 * (1 - y) - 30 * math.cos(2 * pi * x) * sh(2 * pi * (1 - y)) / sh(2 * pi)
vt = plate(40, "D", tube=True)
print(f"tube (periodic seam): opposite seam {20 + tube_ex(0.5, 0.5):.3f} C, on seam {20 + tube_ex(0, 0.5):.3f} C;"
      f" grid h = 0.025 m: {20 + vt[20][20]:.3f} {20 + vt[0][20]:.3f} C")
assert abs(vt[20][20] - tube_ex(0.5, 0.5)) < 0.02 and abs(vt[0][20] - tube_ex(0, 0.5)) < 0.02
flow = lambda y: k * d * simpson(lambda x: -(tube_ex(x, y + e) - tube_ex(x, y - e)) / (2 * e))
print(f"  tube budget: in {flow(0):.3f} W at bottom, out {flow(1):.3f} W at top, nothing at the seam")
assert abs(flow(0) - 15) < 1e-5 and abs(flow(1) - 15) < 1e-5
q = 60 / (1 * d)                     # 60 W over a 1 m x 10 mm edge face, W/m^2
G = q / k                            # the edge gradient it needs, K/m
print(f"insulated plate fed 60 W at bottom, drained at top: {q:.0f} W/m^2 of edge face, gradient {G:.0f} K/m")
ua, ub = insulated(10, G, G, 0.0), insulated(10, G, G, 500.0)
diff = [ub[i][j] - ua[i][j] for i in range(11) for j in range(11)]
print(f"  drained 60 W: compatible; starts flat and tilted settle at centre {ua[5][5]:.3f} and {ub[5][5]:.3f} C,"
      f" apart by {diff[0]:.3f} K at every point")
assert max(diff) - min(diff) < 1e-8 and abs(ua[5][5] - ua[5][10] - 0.5 * G) < 1e-8
m = [mean(insulated(10, G, 100.0, 0.0, s)) for s in (1000, 2000, 4000)]
print(f"  drained 50 W: incompatible; grid mean after 1000 2000 4000 sweeps {m[0]:.1f} {m[1]:.1f} {m[2]:.1f} C")
assert m[2] - m[1] > 1.5 * (m[1] - m[0]) > 0
heat = rho * c * d                  # J per K per m^2 of plate
print(f"  real plate: 10 W surplus warms it {10 / heat * 3600:.3f} K/h; all edges insulated, 60 W in: {60 / heat * 3600:.3f} K/h;"
      f" diffusivity k/(rho c) {k / (rho * c) * 1e5:.2f}e-5 m^2/s")
print(f"mistake, Robin sign flipped: top middle {20 + 60 * Y('R', 1, -0.5):.3f} C, above insulated {20 + 60 * Y('N', 1):.3f} C")
print(f"mistake, du/dn = u_y on the bottom too: edges sum to {-G - G:.0f} K, books {2 * q * d:.0f} W leaving,"
      f" cooling {120 / heat * 3600:.3f} K/h")
print(f"try, plate 20 mm thick, top held: same {20 + 60 * Y('D', 0.5):.3f} C centre, heat in {2 * k * d * 60 * -dY('D', 0) * S:.2f} W")
px = lambda x, y: f"{60 + 300 * x:.0f},{340 - 300 * y:.0f}"   # 300 px per m
print("figure, corners", px(0, 0), px(1, 1), "centre", px(0.5, 0.5), "normal tips", px(0.5, -0.12),
      px(0.5, 1.12), px(-0.12, 0.5), px(1.12, 0.5))
print("ALL CHECKS PASS")
