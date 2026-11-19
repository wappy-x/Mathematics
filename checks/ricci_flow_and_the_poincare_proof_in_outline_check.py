# Ricci flow on a dumbbell surface -- the check behind the card.  Standard library only.
# The metric is g = e^(2u) (round unit sphere), u a function of the polar angle phi.
# On a surface Ric = K g, so the flow dg/dt = -2 Ric is du/dt = -K, stepped on a grid.
from math import pi, sin, cos, tan, log, exp, cosh, tanh, sqrt
R, D = 2.0, 2.0                        # two balls of radius 2 cm, joined; D sets the neck
def rho_x(x):                          # circle radius at cylinder coordinate x (exact profile)
    return R / cosh(x - D) + R / cosh(x + D)
def K_x(x):                            # Gaussian curvature of that profile, -rho''/rho in arc length
    a, b = 1 / cosh(x - D), 1 / cosh(x + D)
    r, r1 = R * (a + b), -R * (a * tanh(x - D) + b * tanh(x + D))
    r2 = R * (a * (1 - 2 * a * a) + b * (1 - 2 * b * b))
    return -(r2 / r - (r1 / r) ** 2) / (r * r)
def neck_rates(d):                    # neck radius, neck K, and d(rho^2)/dt at the neck in 2D and 3D
    r2 = (2 * R / cosh(d)) ** 2
    K = -(1 - r2 / (2 * R * R)) / r2      # closed form of K_x(0)
    return sqrt(r2), K, -2 * r2 * K, -2 * r2 * (K + 1 / r2)  # 3D adds the neck's own 2-sphere, 1/rho^2
def simpson(f, lo, hi, n=6000):        # road 1: integrals over the exact profile
    h = (hi - lo) / n
    s = f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return s * h / 3
def grid(n, u0=None):                  # road 2: n cells in phi, each of exact weight w
    h = pi / n
    phi = [(i + 0.5) * h for i in range(n)]
    w = [cos(i * h) - cos((i + 1) * h) for i in range(n)]
    f = [sin(i * h) / h for i in range(n + 1)]        # zero at both poles: nothing leaks out
    u = [log(rho_x(log(tan(p / 2))) / sin(p)) if u0 is None else u0 for p in phi]
    return [h, phi, w, f, u]
def curv(st):                          # K = e^(-2u) (1 - Laplacian_round u), cell by cell
    h, phi, w, f, u = st
    n, K = len(u), []
    for i in range(n):
        up = f[i + 1] * (u[i + 1] - u[i]) if i < n - 1 else 0.0
        dn = f[i] * (u[i] - u[i - 1]) if i > 0 else 0.0
        K.append(exp(-2 * u[i]) * (1 - (up - dn) / w[i]))
    return K
def area(st):
    return 2 * pi * sum(exp(2 * a) * b for a, b in zip(st[4], st[2]))
def flow(st, T, norm=False, c=2.0):    # dg/dt = -c Ric (c = 2 is Ricci flow); norm keeps the area
    h, t = st[0], 0.0
    while T - t > 1e-12:
        K, u = curv(st), st[4]
        dt = min(0.2 * h * h * exp(2 * min(u)), T - t)
        kbar = 4 * pi / area(st) if norm else 0.0
        st[4] = [a + dt * (c / 2) * (kbar - k) for a, k in zip(u, K)]
        t += dt
    return st
def neck(st):                          # the equator sits between the two middle cells
    m = len(st[4]) // 2
    return exp((st[4][m - 1] + st[4][m]) / 2)
def shape(st):                         # pole-to-pole length L, widest radius, roundness L/(pi*widest)
    h, phi, w, f, u = st
    L, rho = h * sum(exp(a) for a in u), [exp(a) * sin(p) for a, p in zip(u, phi)]
    return L, max(rho), L / (pi * max(rho))
def profile(st, k=10):                 # circle radius at each tenth of the way from pole to pole
    h, phi, w, f, u = st
    s, acc = [0.0], 0.0
    for a in u:
        s.append(acc + h * exp(a) / 2); acc += h * exp(a)
    s.append(acc)
    r = [0.0] + [exp(a) * sin(p) for a, p in zip(u, phi)] + [0.0]
    out, j = [], 0
    for q in range(k + 1):
        x = acc * q / k
        while j < len(s) - 2 and s[j + 1] < x: j += 1
        out.append(r[j] + (r[j + 1] - r[j]) * (x - s[j]) / (s[j + 1] - s[j]))
    return out
def show(label, v): print(f"{label:<44} {v:12.6f}")
# ---- the surface before the flow ----
A_ex = simpson(lambda x: 2 * pi * rho_x(x) ** 2, -40, 40)
L_ex = simpson(rho_x, -40, 40)
GB = simpson(lambda x: 2 * pi * K_x(x) * rho_x(x) ** 2, -40, 40)
chi = 6 - 12 + 8                       # octahedron: vertices - edges + faces
rho0, K0, rate2, rate3 = neck_rates(D)
show("area, exact profile (cm^2)", A_ex); show("pole-to-pole length (cm)", L_ex)
show("neck radius (cm)", rho0); show("bulb radius, widest (cm)", max(rho_x(i / 100) for i in range(400)))
show("total curvature, integral of K dA", GB); show("2 pi chi, chi = 6 - 12 + 8", 2 * pi * chi)
show("neck K, closed form (1/cm^2)", K0)
show("cosh D", cosh(D)); show("neck radius squared (cm^2)", rho0 ** 2)
show("rho^2 / (2 R^2)", rho0 ** 2 / (2 * R * R)); show("area lost per unit time, 8 pi (cm^2)", 8 * pi)
g60, g120 = grid(60), grid(120)
for n, g in ((60, g60), (120, g120)):
    Kg = curv(g)
    show(f"N={n}: area (cm^2)", area(g)); show(f"N={n}: neck K (1/cm^2)", (Kg[n // 2 - 1] + Kg[n // 2]) / 2)
A0 = area(g120)
# ---- the neck in 2D and in 3D: same profile, d(rho^2)/dt at the neck ----
early = flow(grid(120), 0.001)
rate_sim = (neck(early) ** 2 - neck(g120) ** 2) / 0.001
show("2D neck, d(rho^2)/dt, formula", rate2); show("2D neck, d(rho^2)/dt, flow to t=0.001", rate_sim)
show("3D neck, same profile, d(rho^2)/dt", rate3)
show("3D thin neck rho=0.5: pinch time (cm^2)", 0.5 ** 2 / 2); show("3D ball R=2: vanishing time (cm^2)", R * R / 4)
show("3D dumbbell neck at its start rate: t (cm^2)", rho0 ** 2 / -rate3)
# ---- the true flow: area falls by 8 pi per unit time, whatever the shape ----
ball = flow(grid(120, log(R)), 1.0)
show("round ball R=2 at t=1: radius^2, flow", exp(2 * ball[4][0])); show("  closed form R^2 - 2t", R * R - 2)
st = grid(120)
print("t     area        A0 - 8 pi t   neck radius")
for t in (1, 2, 3):
    st = flow(st, 1.0)
    print(f"{t}  {area(st):11.6f} {A0 - 8 * pi * t:11.6f} {neck(st):11.6f}")
show("vanishing time A0 / (8 pi) (cm^2)", A0 / (8 * pi)); show("  exact area: A / (8 pi) (cm^2)", A_ex / (8 * pi))
# ---- the normalised flow: same area, watch the shape go round ----
print("t   neck rho  widest    K min     K max   roundness")
st, prof, done = grid(120), {}, 0
for t in (0, 1, 2, 5, 10, 20, 40):
    st = flow(st, t - done, norm=True); done = t
    K, (L, wide, rnd) = curv(st), shape(st)
    print(f"{t:<3} {neck(st):8.4f} {wide:8.4f} {min(K):8.5f} {max(K):8.5f} {rnd:8.5f}")
    if t in (0, 2, 40): prof[t] = profile(st)
for t in (0, 2, 40):
    print(f"chart t={t:<2}", ", ".join(f"{v:.2f}" for v in prof[t]))
show("round limit: radius sqrt(A/4pi) (cm)", sqrt(area(st) / (4 * pi)))
show("round limit: K = 4 pi / A (1/cm^2)", 4 * pi / area(st))
show("  exact area: radius sqrt(A/4pi) (cm)", sqrt(A_ex / (4 * pi)))
lo = flow(grid(60), 40, norm=True)
show("N=60 at t=40: roundness", shape(lo)[2])
# ---- what breaks ----
show("drop the 2: area at t=1 (cm^2)", area(flow(grid(120), 1.0, c=1.0)))
flip = exp(flow(grid(60, log(R)), 1.0, c=-2.0)[4][0])
show("flip the sign: ball R=2 radius at t=1", flip); show("  closed form sqrt(R^2 + 2t)", sqrt(R * R + 2))
show("3D rule on the surface: pinch t (cm^2)", rho0 ** 2 / 2)
for d in (1.5, 2.5):                   # try changing: a fatter and a thinner neck
    r, k, a, b = neck_rates(d)
    print(f"try D={d}: neck {r:.6f} cm, K {k:.6f}, 2D rate {a:.6f}, 3D rate {b:.6f}")
assert abs(GB - 2 * pi * chi) < 1e-6                     # Gauss-Bonnet: integral against a count
assert abs(area(g120) - A_ex) < abs(area(g60) - A_ex) < 1.0 # grid area converges to the exact area
assert abs((curv(g120)[59] + curv(g120)[60]) / 2 - K0) < 2e-3
assert abs(rate_sim - rate2) < 0.02                     # neck rate: closed form against the flow
assert rate3 < 0 < rate2                                # widens in 2D, shrinks in 3D
assert abs(exp(2 * ball[4][0]) - (R * R - 2)) < 1e-3
assert abs(area(flow(grid(120), 1.0)) - (A0 - 8 * pi)) < 0.01
assert shape(st)[2] < 1.001 and max(curv(st)) / min(curv(st)) < 1.0001
assert abs(area(st) - A0) < 0.05                       # the normalised flow keeps the area
assert abs(shape(st)[1] - sqrt(A0 / (4 * pi))) < 2e-3  # widest radius against the round radius
assert abs(flip - sqrt(R * R + 2)) < 1e-3               # backward flow against R^2 + 2t
print("ALL CHECKS PASS")
