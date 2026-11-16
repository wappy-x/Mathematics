# Leray's weak solutions -- the check behind the card. Standard library only.
# Water at 1 m/s mean speed in a 5 cm pipe, written against test functions.
import math

R, U, nu, rho = 0.025, 1.0, 1.0e-6, 1000.0  # radius m, mean speed m/s, m^2/s, kg/m^3
mu, Umax = rho * nu, 2 * U                   # viscosity Pa s; laminar centre speed m/s
G = 4 * mu * Umax / R**2                     # pressure drop per metre, Pa/m
g = G / rho                                  # the same drop per unit mass, m/s^2
print(f"pipe: R = {R*1000:.1f} mm, mean {U:.1f} m/s, centre {Umax:.1f} m/s, Re = {U*2*R/nu:.0f}")
print(f"pressure drop G = {G:.4f} Pa/m, wall stress {2*mu*Umax/R:.4f} Pa")

def simpson(f, a, b, n=4000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def bump(c, h):  # test profile (1 - ((r-c)/h)^2)^3, with its first and second slopes
    def q(r): return (r - c) / h if abs(r - c) < h else 1.0
    f = lambda r: (1 - q(r)**2)**3
    df = lambda r: -6 * q(r) * (1 - q(r)**2)**2 / h
    d2 = lambda r: (-6 * (1 - q(r)**2)**2 + 24 * q(r)**2 * (1 - q(r)**2)) / h**2
    return f, df, d2

w = lambda r, Um=Umax: Um * (1 - (r / R)**2)
dw = lambda r, Um=Umax: -2 * Um * r / R**2
def sides(c, h, GG=G):  # road 1: viscous side; road 2: pressure side; road 3: very weak form
    f, df, d2 = bump(c, h)
    lo, hi = max(0.0, c - h), min(R, c + h)
    a = simpson(lambda r: mu * dw(r) * df(r) * 2 * math.pi * r, lo, hi)
    l = simpson(lambda r: GG * f(r) * 2 * math.pi * r, lo, hi)
    lap = lambda r: d2(r) + (df(r) / r if r > 0 else d2(r))
    vw = simpson(lambda r: -mu * w(r) * lap(r) * 2 * math.pi * r, lo, hi)
    return a, l, vw

for name, c, h in [("A, on the axis", 0.0, R), ("B, a ring", 0.015, 0.008)]:
    a, l, vw = sides(c, h)
    print(f"bump {name}: viscous {a:.7f} N/m, pressure {l:.7f} N/m, very weak {vw:.7f} N/m")
    assert abs(a - l) < 1e-9 and abs(vw - l) < 1e-9
assert abs(sides(0.0, R)[1] - G * math.pi * R**2 / 4) < 1e-12  # closed form for bump A
drag = -mu * (w(R + 1e-6) - w(R - 1e-6)) / 2e-6 * 2 * math.pi * R   # wall stress from the profile's slope
print(f"mistake v = 1: viscous 0.0000000 N/m, pressure {G*math.pi*R**2:.7f} N/m = wall drag {drag:.7f} N/m")
assert abs(G * math.pi * R**2 - drag) < 1e-12
a, l, _ = sides(0.0, R, 4 * mu * U / R**2)
print(f"mistake mean speed in 4 mu U/R^2: G = {4*mu*U/R**2:.4f} Pa/m, bump A {a:.7f} vs {l:.7f} N/m")

# The nonlinear term on a swirling cell, scaled: periodic box of side 2 pi.
def ev(f, x, y): return sum(A * math.sin(kx * x + ky * y + p) for A, kx, ky, p in f)
def d(f, ax): return [(A * (kx, ky)[ax], kx, ky, p + math.pi / 2) for A, kx, ky, p in f]
u1 = [(0.5, 1, 1, 0.0), (0.5, 1, -1, 0.0), (-0.5, 2, 1, 0.0)]   # from psi = sin x sin y + cos(2x+y)/2
u2 = [(-0.5, 1, 1, 0.0), (0.5, 1, -1, 0.0), (1.0, 2, 1, 0.0)]
chi = [(1.0, 1, 0, math.pi / 2)]                                 # cos x: a leaking gradient part
b1, b2 = u1 + [(0.5 * A, k, l_, p) for A, k, l_, p in d(chi, 0)], u2 + [(0.5 * A, k, l_, p) for A, k, l_, p in d(chi, 1)]
n, hb = 32, 2 * math.pi / 32
def box(fun): return sum(fun(i * hb, j * hb) for i in range(n) for j in range(n)) * hb * hb
def bform(a1, a2):
    ds = [d(a1, 0), d(a1, 1), d(a2, 0), d(a2, 1)]
    def f(x, y):
        v1, v2 = ev(a1, x, y), ev(a2, x, y)
        g_ = [ev(t, x, y) for t in ds]
        return v1 * (v1 * g_[0] + v2 * g_[1]) + v2 * (v1 * g_[2] + v2 * g_[3])
    return box(f)
def divsq(a1, a2): return lambda x, y: ev(d(a1, 0), x, y) + ev(d(a2, 1), x, y)
def half_div(a1, a2): return box(lambda x, y: -0.5 * divsq(a1, a2)(x, y) * (ev(a1, x, y)**2 + ev(a2, x, y)**2))
def press(a1, a2): return box(lambda x, y: ev(d(chi, 0), x, y) * ev(a1, x, y) + ev(d(chi, 1), x, y) * ev(a2, x, y))
bu, bb, hdb = bform(u1, u2), bform(b1, b2), half_div(b1, b2)
print(f"box: b(u,u,u) divergence-free {abs(bu):.6f}; leaking {bb:.6f}, by -1/2 int (div u)|u|^2 {hdb:.6f}")
assert abs(bu) < 1e-12 and abs(bb - hdb) < 1e-10 and abs(bb + 3 * math.pi**2 / 8) < 1e-10
pu, pb = press(u1, u2), press(b1, b2)
print(f"box: pressure term divergence-free {abs(pu):.6f}; leaking {pb:.6f} (pi^2 = {math.pi**2:.6f})")
assert abs(pu) < 1e-12 and abs(pb - math.pi**2) < 1e-10

# Weak is not strong: a wiggle across the diameter, s from 0 to 1, size 1 m/s.
phi = lambda s: 16 * s * s * (1 - s)**2
for k in (1, 5, 25, 125):
    lin = simpson(lambda s: math.sin(k * math.pi * s) * phi(s), 0, 1)
    sq = simpson(lambda s: math.sin(k * math.pi * s)**2 * phi(s), 0, 1)
    slope = math.sqrt(simpson(lambda s: (k * math.pi * math.cos(k * math.pi * s))**2, 0, 1))
    print(f"wiggle n = {k:3d}: |int u phi| {abs(lin):.6f}, int u^2 phi {sq:.6f}, slope size {slope:.4f} m/s per diameter")
assert abs(lin) < 1e-4 and abs(sq - 4 / 15) < 1e-4 and abs(slope - 125 * math.pi / math.sqrt(2)) < 1e-6

# Start-up flow: Bessel series against Galerkin with N profiles (1 - s^2) s^(2k).
def J(m, x, M=400): return sum(math.cos(m * (i + .5) * math.pi / M - x * math.sin((i + .5) * math.pi / M)) for i in range(M)) / M
def zero(k):
    a, b = (k - 0.25) * math.pi - 0.5, (k - 0.25) * math.pi + 0.5
    for _ in range(60):
        m = (a + b) / 2
        a, b = (a, m) if J(0, a) * J(0, m) <= 0 else (m, b)
    return (a + b) / 2
lam = [zero(k) for k in range(1, 12)]
def term(k, s, t): return 8 * Umax * J(0, lam[k] * s) / (lam[k]**3 * J(1, lam[k])) * math.exp(-lam[k]**2 * nu * t / R**2)
def series(s, t): return w(s * R) - sum(term(k, s, t) for k in range(10))
print(f"Bessel zeros {lam[0]:.6f}, {lam[1]:.6f}; slowest time R^2/(nu z1^2) = {R*R/nu/lam[0]**2:.2f} s")
def galerkin(N, t, steps=3000):
    M = [[1/(2*(j+k)+2) - 2/(2*(j+k)+4) + 1/(2*(j+k)+6) for k in range(N)] for j in range(N)]
    K = [[(4*j*k/(2*(j+k)) if j*k else 0) - (2*j*(2*k+2) + (2*j+2)*2*k)/(2*(j+k)+2)
          + (2*j+2)*(2*k+2)/(2*(j+k)+4) for k in range(N)] for j in range(N)]
    F = [1/(2*j+2) - 1/(2*j+4) for j in range(N)]
    dt, a, c = t / steps, nu / R**2, [0.0] * N
    for _ in range(steps):  # Crank-Nicolson in time, Gaussian elimination
        A = [[M[i][k] + dt*a/2*K[i][k] for k in range(N)] + [sum((M[i][k] - dt*a/2*K[i][k]) * c[k]
             for k in range(N)) + dt*g*F[i]] for i in range(N)]
        for p in range(N):
            for q in range(p + 1, N):
                f = A[q][p] / A[p][p]
                A[q] = [A[q][r] - f * A[p][r] for r in range(N + 1)]
        for p in reversed(range(N)):
            c[p] = (A[p][N] - sum(A[p][r] * c[r] for r in range(p + 1, N))) / A[p][p]
    return c[0]
ex = series(0, 180)
print(f"centre at 180 s: series {ex:.6f} m/s, first omitted term {abs(term(10, 0, 180)):.2e}")
gal = [galerkin(N, 180) for N in range(1, 6)]
for N, v in enumerate(gal, 1): print(f"  Galerkin N = {N}: {v:.6f} m/s, gap {abs(v-ex):.6f}")
assert abs(gal[-1] - ex) < 1e-6 and abs(gal[0] - ex) > 0.05
assert abs(g * 60 - series(0, 60)) < 0.03   # early on, the centre speeds up at G / rho
for t in (60, 180, 600):
    print(f"chart t = {t:3d} s:", " ".join(f"{series(r/R, t):.3f}" for r in (0, .005, .01, .015, .02, .025)))
print("chart steady:  ", " ".join(f"{w(r):.3f}" for r in (0, .005, .01, .015, .02, .025)))
print("ALL CHECKS PASS")
