# De Giorgi-Nash-Moser on a checkerboard conductor.  Standard library only.
# Two opposite square tiles conduct 100 S/m, the other two 1 S/m (illustrative).
# Near the shared corner the potential is u = V0 r^a phi(theta).  Roads to a:
# Kellogg's closed form, an RK4 transfer across the tiles found by bisection,
# and the equation's residual by centred differences on the assembled u.
import math
PI = math.pi
HI, LO, V0 = 100.0, 1.0, 0.5        # S/m, S/m, volts on the 1 cm circle

def alpha_closed(c):                 # c = contrast Lambda/lambda >= 1
    return 4 / PI * math.atan(1 / math.sqrt(c))

def half_turn(a, c, n=400):          # RK4 for (phi, k phi') across a hi tile then a lo tile
    cols = []
    for p, q in ((1.0, 0.0), (0.0, 1.0)):
        for k in (c, 1.0):
            h = PI / 2 / n
            for _ in range(n):
                f = lambda p, q: (q / k, -k * a * a * p)
                k1 = f(p, q); k2 = f(p + h / 2 * k1[0], q + h / 2 * k1[1])
                k3 = f(p + h / 2 * k2[0], q + h / 2 * k2[1]); k4 = f(p + h * k3[0], q + h * k3[1])
                p += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
                q += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        cols.append((p, q))
    return cols                      # columns of the half-turn matrix

def alpha_transfer(c):               # smallest a > 0 with trace(half turn) = -2
    g = lambda a: half_turn(a, c)[0][0] + half_turn(a, c)[1][1] + 2
    lo, hi = 1e-4, 1e-4
    while g(hi) > 0: lo, hi = hi, hi * 1.5
    for _ in range(50):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if g(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

A = alpha_closed(HI / LO)
AT = alpha_transfer(HI / LO)
COT = 1 / math.tan(A * PI / 4)

def phi(t):                          # angular profile, max 1 at 45 degrees; tiles 0-90 and 180-270 conduct 100
    s = 1.0
    t = t % (2 * PI)
    if t >= PI: t, s = t - PI, -1.0
    if t <= PI / 2: return s * math.cos(A * (t - PI / 4))
    return -s * COT * math.sin(A * (t - 3 * PI / 4))

def dphi(t):                         # its slope, by hand from the same pieces
    s = 1.0
    t = t % (2 * PI)
    if t >= PI: t, s = t - PI, -1.0
    if t <= PI / 2: return -s * A * math.sin(A * (t - PI / 4))
    return -s * COT * A * math.cos(A * (t - 3 * PI / 4))
def kk(t): return HI if (t % PI) < PI / 2 else LO
def u(x, y): return V0 * math.hypot(x, y) ** A * phi(math.atan2(y, x))

print(f"tiles 100 S/m and 1 S/m, contrast Lambda/lambda = {HI / LO:.0f}")
print(f"alpha: Kellogg (4/pi) atan(sqrt(lambda/Lambda)) = {A:.6f}, RK4 transfer + bisection = {AT:.6f}")
assert abs(A - AT) < 1e-7
m = half_turn(A, HI / LO)
p0, q0 = math.cos(A * PI / 4), HI * A * math.sin(A * PI / 4)
p1, q1 = m[0][0] * p0 + m[1][0] * q0, m[0][1] * p0 + m[1][1] * q0
print(f"half turn sends (phi, k phi') = ({p0:.6f}, {q0:.6f}) to ({p1:.6f}, {q1:.6f})")
assert abs(p1 + p0) < 1e-8 and abs(q1 + q0) < 1e-6          # antiperiodic: phi(t + pi) = -phi(t)
print(f"lo-tile amplitude cot(a pi/4) = {COT:.6f}; phi at 90 deg: hi side {p0:.6f}, lo side {COT * math.sin(A * PI / 4):.6f}")
h = 1e-3                                                  # residual of div(k grad u) inside each tile, cm
for deg in (30.0, 120.0):
    x, y = 0.5 * math.cos(math.radians(deg)), 0.5 * math.sin(math.radians(deg))
    lap = (u(x + h, y) + u(x - h, y) + u(x, y + h) + u(x, y - h) - 4 * u(x, y)) / h / h
    print(f"residual at r = 0.5 cm, {deg:.0f} deg: centred Laplacian {lap:+.1e} V/cm2, u = {u(x, y):+.6f} V")
    assert abs(lap) < 1e-4
y0 = 0.5                                                  # flux across the interface x = 0 at y = 0.5 cm
fr = HI * (-3 * u(0, y0) + 4 * u(h, y0) - u(2 * h, y0)) / (2 * h)
fl = LO * (3 * u(0, y0) - 4 * u(-h, y0) + u(-2 * h, y0)) / (2 * h)
print(f"flux k du/dx across x = 0 at y = 0.5 cm: 100 S/m side {fr:.6f}, 1 S/m side {fl:.6f} (S/m)(V/cm)")
assert abs(fr - fl) < 1e-4 * abs(fr)
N = 400                                                    # Simpson over each tile
def simpson(g, a, b):
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + (b - a) * i / N) for i in range(1, N))
    return s * (b - a) / N / 3
Ip = sum(simpson(lambda t: kk(t + 1e-12) * phi(t) ** 2, j * PI / 2, (j + 1) * PI / 2) for j in range(4))
Id = sum(simpson(lambda t: kk(t + 1e-12) * dphi(t + 1e-12) ** 2, j * PI / 2, (j + 1) * PI / 2) for j in range(4))
print(f"energy identity: int k phi'^2 = {Id:.4f}, a^2 int k phi^2 = {A * A * Ip:.4f}")
assert abs(Id - A * A * Ip) < 1e-9 * Id
lhs = V0 ** 2 * ((0.5 ** (2 * A)) / (2 * A) + simpson(lambda r: 4 * (1 - r) ** 2 * r ** (2 * A - 1), 0.5, 1.0)) * 2 * A * A * Ip
rhs = 4 * V0 ** 2 * 4 * (1 - 0.5 ** (2 * A + 2)) / (2 * A + 2) * Ip
print(f"Caccioppoli, cutoff 1 cm -> 0.5 cm: int k eta^2 |grad u|^2 = {lhs:.4f} <= 4 int k |grad eta|^2 u^2 = {rhs:.4f} W/m")
assert lhs <= rhs
Iq = sum(simpson(lambda t: phi(t) ** 2, j * PI / 2, (j + 1) * PI / 2) for j in range(4))
rms = math.sqrt(V0 ** 2 * Iq / (2 * A + 2) / PI)
print(f"L-infinity bound: sup over 0.5 cm disc {V0 * 0.5 ** A:.6f} V, rms over 1 cm disc {rms:.6f} V, ratio {V0 * 0.5 ** A / rms:.4f}")
print(f"by hand: atan(0.1) = {math.atan(0.1):.6f} rad, 1 - a = {1 - A:.6f}, V0 a cot = {V0 * A * COT:.6f} V/cm, "
      f"1e4^(1-a) = {1e4 ** (1 - A):.2f}, 1 + 2^-a = {1 + 0.5 ** A:.6f}, 1 - 2^-a = {1 - 0.5 ** A:.6f}")
print(f"one halving of the radius keeps 2^-a = {0.5 ** A:.6f} of the oscillation; one tenfold cut keeps {0.1 ** A:.6f}")
for r in (1.0, 0.1, 0.01, 0.001, 0.0001):
    osc = max(u(r * math.cos(math.radians(i / 2)), r * math.sin(math.radians(i / 2))) for i in range(720))
    osc -= min(u(r * math.cos(math.radians(i / 2)), r * math.sin(math.radians(i / 2))) for i in range(720))
    print(f"osc on circle r = {r:.4f} cm: sampled {osc:.6f} V, 2 V0 r^a {2 * V0 * r ** A:.6f} V, uniform sheet {r:.6f} V")
    assert abs(osc - 2 * V0 * r ** A) < 1e-9
for r in (1.0, 0.0001):                                   # field on the 1 S/m tile's bisector
    t, e = 3 * PI / 4, 1e-6
    fd = (u(r * math.cos(t + e), r * math.sin(t + e)) - u(r * math.cos(t - e), r * math.sin(t - e))) / (2 * r * e)
    print(f"field at r = {r:.4f} cm on the 1 S/m bisector: centred diff {abs(fd):.4f}, formula V0 a cot r^(a-1) {V0 * A * COT * r ** (A - 1):.4f} V/cm")
    assert abs(abs(fd) - V0 * A * COT * r ** (A - 1)) < 1e-4 * abs(fd)
smax = max(V0 + u(rr / 100 * math.cos(math.radians(d)), rr / 100 * math.sin(math.radians(d))) for rr in range(51) for d in range(360))
smin = min(V0 + u(rr / 100 * math.cos(math.radians(d)), rr / 100 * math.sin(math.radians(d))) for rr in range(51) for d in range(360))
hc = (1 + 0.5 ** A) / (1 - 0.5 ** A)
print(f"Harnack, v = 0.5 V + u >= 0 on 1 cm disc: on 0.5 cm disc max {smax:.6f}, min {smin:.6f} V, ratio {smax / smin:.4f}, formula {hc:.4f}")
assert abs(smax / smin - hc) < 1e-6 * hc
for c in (1.0, 10.0, 100.0, 1e4, 1e8):
    a1 = alpha_closed(c)
    a2 = alpha_transfer(c) if c > 1 else a1      # contrast 1 is Laplace, u = x: the trace only touches -2
    tr = f"{a2:.6f} transfer" if c > 1 else "Laplace u = x"
    print(f"contrast {c:9.0f}: alpha {a1:.6f} closed, {tr}; Harnack ratio {(1 + 0.5 ** a1) / (1 - 0.5 ** a1):12.4f}; osc at 1 um {0.0001 ** a1:.6f} V")
    assert abs(a1 - a2) < 1e-6
C, B, EPS = 4.0, 4.0, 0.5                                  # iteration lemma, illustrative constants
star = C ** (-1 / EPS) * B ** (-1 / EPS ** 2)
print(f"iteration Y(j+1) = C b^j Y(j)^(1+eps), C = b = 4, eps = 1/2: threshold C^(-1/eps) b^(-1/eps^2) = {star:.4e}, decay there b^(1/eps) = {B ** (1 / EPS):.0f} per step")
for f in (0.5, 1.0, 2.0):
    y, ys = f * star, []
    for j in range(13):
        ys.append(y); y = C * B ** j * y ** (1 + EPS)
    print(f"  start {f:.1f} x threshold: Y0 {ys[0]:.4e}, Y4 {ys[4]:.4e}, Y8 {ys[8]:.4e}, Y12 {ys[12]:.4e}")
    if f == 1.0: assert abs(ys[12] - star * B ** (-12 / EPS)) < 1e-9 * ys[12]
    if f == 2.0: assert ys[12] > ys[0]
    if f == 0.5: assert ys[12] < star * B ** (-12 / EPS)
print("chart r mm:", ", ".join(f"{i / 2:g}" for i in range(21)))
print("chart checkerboard u V:", ", ".join(f"{V0 * (i / 20) ** A:.3f}" for i in range(21)))
print("chart uniform u V:", ", ".join(f"{V0 * i / 20:.3f}" for i in range(21)))
print("chart phi, 0..360 deg by 15:", ", ".join(f"{round(phi(math.radians(15 * i)), 3) + 0.0:.3f}" for i in range(25)))
print("ALL CHECKS PASS")
