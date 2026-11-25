# Monotone operators and Minty-Browder -- the check behind the card.  Standard library only.
# Problem (scaled): -((u')^3)' + u' = 1 on 0 < x < 1, u(0) = u(1) = 0.  Three roads to u:
# a closed form after integrating once, RK4 shooting, and Galerkin on hat functions.
from math import log, pi, sin, cos, atan

def cbrt(y): return y ** (1 / 3) if y >= 0 else -((-y) ** (1 / 3))
def G(t): return 3 * (t * t / 2 + t + log(1 - t))      # along the solution x = G(t) - G(t0), t = u'

def bisect(f, lo, hi, n=80):                            # root of f between lo and hi (f changes sign)
    flo = f(lo)
    for _ in range(n):
        mid = (lo + hi) / 2
        fm = f(mid)
        if (fm > 0) == (flo > 0): lo, flo = mid, fm
        else: hi = mid
    return (lo + hi) / 2

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

# ---- road 1: integrate once, (u')^3 = u - x - c; separate variables; one equation for t0 = u'(0)
t0 = bisect(lambda s: G(cbrt(s ** 3 - 1)) - G(s) - 1, 0.0, 0.999)
t1, c = cbrt(t0 ** 3 - 1), -t0 ** 3
xpk = -G(t0); upk = xpk + c                             # the peak sits where t = u' = 0
def u_exact(x):
    if x <= 0 or x >= 1: return 0.0
    t = bisect(lambda s: G(s) - G(t0) - x, t1, t0)
    return t ** 3 + c + x
dxdt = lambda t: 3 * t * t / (1 - t)                    # |dx/dt|: integrate over x by integrating over t
energy = simpson(lambda t: t ** 4 * dxdt(t), t1, t0)    # int (u')^4 dx
mass = simpson(lambda t: (t ** 3 + c + G(t) - G(t0)) * dxdt(t), t1, t0)   # int u dx
print(f"road 1 closed form: u'(0) = {t0:.9f}, u'(1) = {t1:.9f}, c = {c:.9f}")
print(f"  G(u'(0)) = {G(t0):.6f}, G(u'(1)) = {G(t1):.6f}, difference = {G(t1) - G(t0):.6f} m")
print(f"  by hand: z0^2/2 = {t0 * t0 / 2:.6f}, 1 - z0 = {1 - t0:.6f}, z1^2/2 = {t1 * t1 / 2:.6f}, 1 - z1 = {1 - t1:.6f}")
print(f"  peak u = {upk:.9f} at x = {xpk:.9f} m")
print(f"  test with u: int (u')^4 = {energy:.9f}, int u = {mass:.9f}, ||u'||_4 = {energy ** 0.25:.6f}")

# ---- road 2: shooting.  u' = cbrt(u - x - c) by RK4 from u(0) = 0; bisect on c until u(1) = 0
def shoot(cc, n):
    h, u = 1 / n, 0.0
    f = lambda x, u: cbrt(u - x - cc)
    for i in range(n):
        x = i * h
        k1 = f(x, u); k2 = f(x + h / 2, u + h / 2 * k1); k3 = f(x + h / 2, u + h / 2 * k2); k4 = f(x + h, u + h * k3)
        u += h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    return u
shots = [bisect(lambda cc: shoot(cc, n), -1.0, 0.0, 60) for n in (1000, 4000)]
for n, cs in zip((1000, 4000), shots): print(f"road 2 shooting, {n} RK4 steps: c = {cs:.9f}, |error| = {abs(cs - c):.1e}")
print(f"  error ratio, 1000 to 4000 steps: {abs(shots[0] - c) / abs(shots[1] - c):.1f}")

# ---- road 3: Galerkin on hat functions, drift strength b; Newton's method with a tridiagonal solve
def galerkin(N, b=1.0):
    h = 1 / N
    U = [x * (1 - x) for x in (i * h for i in range(N + 1))]
    for _ in range(60):
        s = [(U[e + 1] - U[e]) / h for e in range(N)]
        R = [s[i - 1] ** 3 - s[i] ** 3 + b * (U[i + 1] - U[i - 1]) / 2 - h for i in range(1, N)]
        lo = [-3 * s[i - 1] ** 2 / h - b / 2 for i in range(1, N)]
        di = [3 * (s[i - 1] ** 2 + s[i] ** 2) / h for i in range(1, N)]
        up = [-3 * s[i] ** 2 / h + b / 2 for i in range(1, N)]
        m = N - 1
        for i in range(1, m):                           # elimination, then back substitution
            w = lo[i] / di[i - 1]; di[i] -= w * up[i - 1]; R[i] -= w * R[i - 1]
        d = [0.0] * m
        d[m - 1] = R[m - 1] / di[m - 1]
        for i in range(m - 2, -1, -1): d[i] = (R[i] - up[i] * d[i + 1]) / di[i]
        for i in range(m): U[i + 1] -= d[i]
        if max(abs(v) for v in d) < 1e-14: break
    return U
u0 = lambda x: 0.75 * (0.5 ** (4 / 3) - abs(0.5 - x) ** (4 / 3))   # no drift: the energy case, by hand
Ns, errs = (40, 80, 160, 320, 640, 1280), []
for N in Ns:
    U = galerkin(N)
    errs.append(max(abs(U[i] - u_exact(i / N)) for i in range(1, N)))
    k = max(range(N + 1), key=lambda i: U[i])
    print(f"road 3 Galerkin h = 1/{N:<4d}: max node error {errs[-1]:.3e}, top node u = {U[k]:.6f} at x = {k / N:.6f} m")
print(f"  overall order from h = 1/80 to 1/1280: {log(errs[1] / errs[-1]) / log(16):.3f}")
print(f"  error ratios: 1/80 to 1/160 {errs[1] / errs[2]:.1f}, 1/320 to 1/640 {errs[3] / errs[4]:.1f}")
sh = [(U[i + 1] - U[i]) * 1280 for i in range(1280)]
print(f"  h = 1/1280 tested with u_h: int (u_h')^4 = {sum(v ** 4 for v in sh) / 1280:.9f}, int u_h = {sum(U) / 1280:.9f}")
U0 = galerkin(80, 0.0)
e0 = max(abs(U0[i] - u0(i / 80)) for i in range(1, 80))
print(f"no drift: peak u = {u0(0.5):.9f} at x = 0.5 m; Galerkin h = 1/80 max node error {e0:.3e}")
print(f"  the flow moves the peak {xpk - 0.5:.4f} m downstream and lowers it by {u0(0.5) - upk:.4f}")
xs = [i / 10 for i in range(11)]
print(f"{'chart x (m)':<17}" + " ".join(f"{x:5.1f}" for x in xs))
print(f"{'chart with drift':<17}" + " ".join(f"{u_exact(x):5.3f}" for x in xs))
print(f"{'chart no drift':<17}" + " ".join(f"{u0(x):5.3f}" for x in xs))

# ---- monotone: u = x(1 - x), v = sin(pi x)/4.  <Au - Av, u - v> = cubic part + drift part
du, dv = (lambda x: 1 - 2 * x), (lambda x: pi * cos(pi * x) / 4)
mono_cube = simpson(lambda x: (du(x) ** 3 - dv(x) ** 3) * (du(x) - dv(x)), 0, 1)
mono_drift = simpson(lambda x: (du(x) - dv(x)) * (x * (1 - x) - sin(pi * x) / 4), 0, 1)
print(f"monotone check: cubic part {mono_cube:.9f}, drift part {abs(mono_drift):.9f}")

# ---- no energy: work of A around the loop g(s) = cos(s) sin(pi x) + sin(s) sin(2 pi x), 0 <= s <= 2 pi
M, cube, drift = 200, 0.0, 0.0
for j in range(M):                                      # trapezoid in s: very accurate for a periodic integrand
    s = 2 * pi * j / M
    dg = lambda x: cos(s) * pi * cos(pi * x) + sin(s) * 2 * pi * cos(2 * pi * x)
    gs = lambda x: -sin(s) * sin(pi * x) + cos(s) * sin(2 * pi * x)
    dgs = lambda x: -sin(s) * pi * cos(pi * x) + cos(s) * 2 * pi * cos(2 * pi * x)
    cube += simpson(lambda x: dg(x) ** 3 * dgs(x), 0, 1, 400) * 2 * pi / M
    drift += simpson(lambda x: dg(x) * gs(x), 0, 1, 400) * 2 * pi / M
print(f"loop work: cubic part {abs(cube):.9f}, drift part = {drift:.9f}, 8 pi/3 = {8 * pi / 3:.9f}")

# ---- why a weak limit needs Minty: slopes w_m = 2 on the first half of each of m periods, else 0
for m in (10, 1000):
    w, n = (lambda x: 2.0 if (x * m) % 1 < 0.5 else 0.0), 20000
    a = sum(w((i + 0.5) / n) * (i + 0.5) / n for i in range(n)) / n
    b = sum(w((i + 0.5) / n) ** 3 * (i + 0.5) / n for i in range(n)) / n
    print(f"m = {m}: int w_m x dx = {a:.6f} (1/2 - 1/(4m) = {0.5 - 0.25 / m:.6f}), int w_m^3 x dx = {b:.6f}")
print(f"weak limit w = 1: int 1^3 x dx = {0.5:.6f}; limit of int w_m^3 x dx = {2.0:.6f} = 4 x 0.5")

# ---- what breaks: one-dimensional operators, each missing one hypothesis
print(f"not coercive: arctan(x) = 2 has no root; arctan(1e6) = {atan(1e6):.6f}, pi/2 = {pi / 2:.6f}")
jump = lambda x: x + (1.0 if x >= 0 else 0.0)
print(f"not hemicontinuous: x + [x >= 0] = 0.5 has no root; value {jump(-1e-3):.6f} at x = -0.001, {jump(0.0):.6f} at 0")
roots = [round(bisect(lambda x: x ** 3 - 3 * x, a, b), 6) + 0.0 for a, b in ((-2.5, -1.0), (-1.0, 1.2), (1.0, 2.5))]
print("not monotone: x^3 - 3x = 0 has roots " + ", ".join(f"{r:.6f}" for r in roots))

assert abs(energy - mass) < 1e-9, "testing with u: int (u')^4 must equal int u"
assert abs(U[k] - upk) < 2e-5 and abs(k / 1280 - xpk) < 2 / 1280, "Galerkin top node lands on the closed-form peak"
assert all(abs(cs - c) < 1e-4 for cs in shots), "shooting lands on the closed form's c"
assert errs[-1] < 2e-5 and errs[0] > errs[1] > errs[-1], "Galerkin settles on the closed form"
assert e0 < 2e-4, "Galerkin without drift lands on the energy case's formula"
assert mono_cube > 0 and abs(mono_drift) < 1e-9, "monotone: cubic part positive, drift part zero"
assert abs(drift - 8 * pi / 3) < 1e-8 and abs(cube) < 1e-8, "loop work: drift 8 pi/3, cubic part 0"
assert abs(b - (2 - 1 / m)) < 1e-9, "weak limit of the cubes is 2, not the cube of the weak limit"
print("ALL CHECKS PASS")
