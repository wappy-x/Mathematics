# The Laplacian in round coordinates -- the check behind the card.  Standard library only.
# A steel drum lid, radius 0.30 m, faces lagged, rim held at 30 + 12 cos(phi) + 4 cos(2 phi) degC.
# Roads: the round formulas against the exact Cartesian Laplacian; the mode series against
# the Poisson integral and the rim mean; the equation's residual at two steps; the same in a ball.
import math

R = 0.30                       # lid radius, m
A = {0: 30.0, 1: 12.0, 2: 4.0}  # rim modes: degC times cos(m phi)
RA = 0.15                      # the point read off, m from the centre

def sci(x):
    m, e = f"{x:.2e}".split("e")
    return f"{m}e{int(e)}"

def lid(r, p):                 # the mode series: mode m fades as (r/R)^m
    return sum(a * (r / R) ** m * math.cos(m * p) for m, a in A.items())

def rim(p):
    return lid(R, p)

def polar_lap(u, r, p, h):     # flux through a small polar box, per unit area
    rad = ((r + h / 2) * (u(r + h, p) - u(r, p)) - (r - h / 2) * (u(r, p) - u(r - h, p))) / (h * h * r)
    return rad + (u(r, p + h) - 2 * u(r, p) + u(r, p - h)) / (h * h * r * r)

def ang_lap(Y, t, p, h):       # the angular part of the spherical Laplacian
    th = (math.sin(t + h / 2) * (Y(t + h, p) - Y(t, p)) - math.sin(t - h / 2) * (Y(t, p) - Y(t - h, p))) / (h * h * math.sin(t))
    return th + (Y(t, p + h) - 2 * Y(t, p) + Y(t, p - h)) / (h * h * math.sin(t) ** 2)

def sph_lap(u, r, t, p, h):    # radial flux through r^2 faces, plus the angular part over r^2
    rad = ((r + h / 2) ** 2 * (u(r + h, t, p) - u(r, t, p)) - (r - h / 2) ** 2 * (u(r, t, p) - u(r - h, t, p))) / (h * h * r * r)
    return rad + ang_lap(lambda tt, pp: u(r, tt, pp), t, p, h) / (r * r)

def legendre(n):               # coefficients of P_n, by Bonnet's rule
    P = [[1.0], [0.0, 1.0]]
    for k in range(1, n):
        a = [0.0] + [(2 * k + 1) * c / (k + 1) for c in P[k]]
        for i, c in enumerate(P[k - 1]):
            a[i] -= k * c / (k + 1)
        P.append(a)
    return P[n]

def assoc(n, m, s):            # P_n^m(s) = (1 - s^2)^(m/2) times the m-th derivative of P_n, s = cos(theta)
    c = legendre(n)
    for _ in range(m):
        c = [i * c[i] for i in range(1, len(c))] or [0.0]
    return (1 - s * s) ** (m / 2) * sum(ci * s ** i for i, ci in enumerate(c))

print("1. The round formulas against the exact Cartesian Laplacian")
x, y = 0.2 * math.cos(0.7), 0.2 * math.sin(0.7)
g2 = lambda r, p: (r * math.cos(p)) ** 3 * (r * math.sin(p)) + (r * math.cos(p)) ** 2
e2 = [polar_lap(g2, 0.2, 0.7, h) - (6 * x * y + 2) for h in (0.01, 0.005)]
print(f"polar, x^3 y + x^2 at r 0.2 m, phi 0.7: exact {6 * x * y + 2:.6f}; error h 0.01 {sci(e2[0])}, h 0.005 {sci(e2[1])}, ratio {e2[0] / e2[1]:.2f}")
assert abs(e2[1]) < 1e-3 and 3.5 < e2[0] / e2[1] < 4.5
cart = lambda r, t, p: (r * math.sin(t) * math.cos(p), r * math.sin(t) * math.sin(p), r * math.cos(t))
g3 = lambda r, t, p: (lambda X, Y, Z: X * X * Y * Z + Z ** 3)(*cart(r, t, p))
X, Y, Z = cart(0.25, 1.0, 0.6)
e3 = [sph_lap(g3, 0.25, 1.0, 0.6, h) - (2 * Y * Z + 6 * Z) for h in (0.01, 0.005)]
print(f"spherical, x^2 y z + z^3 at r 0.25 m: exact {2 * Y * Z + 6 * Z:.6f}; error h 0.01 {sci(e3[0])}, h 0.005 {sci(e3[1])}, ratio {e3[0] / e3[1]:.2f}")
assert abs(e3[1]) < 1e-3 and 3.5 < e3[0] / e3[1] < 4.5

print("2. Angular modes: the angular part returns -n(n+1) times Y_n^m")
for n, m in [(1, 0), (2, 0), (2, 1), (2, 2), (3, 1)]:
    Yf = lambda t, p, n=n, m=m: assoc(n, m, math.cos(t)) * math.cos(m * p)
    lam = ang_lap(Yf, 0.9, 0.4, 1e-3) / Yf(0.9, 0.4)
    print(f"n {n}, m {m}: ratio {lam:.4f}, -n(n+1) = {-n * (n + 1)}")
    assert abs(lam + n * (n + 1)) < 1e-4
print(f"P_2^1(0.6) = {assoc(2, 1, 0.6):.4f}, by hand 3 s sqrt(1 - s^2) = {3 * 0.6 * 0.8:.4f}")

print("3. The drum lid: the mode series against the Poisson integral")
N = 256
ps = [2 * math.pi * k / N for k in range(N)]
coef = [sum(rim(p) * math.cos(m * p) for p in ps) / N * (1 if m == 0 else 2) for m in range(4)]
print("rim modes by a 256-point sum: " + ", ".join(f"m {m} {c if abs(c) > 5e-7 else 0.0:.6f} degC" for m, c in enumerate(coef)))
assert all(abs(coef[m] - A.get(m, 0.0)) < 1e-9 for m in range(4))
def poisson(r, p):             # wing 07's Poisson integral, by the trapezoid sum
    return sum((R * R - r * r) / (R * R - 2 * R * r * math.cos(p - q) + r * r) * rim(q) for q in ps) / N
for lab, r, p in [("centre", 0.0, 0.0), ("halfway, hot side", RA, 0.0), ("halfway, 90 deg round", RA, math.pi / 2)]:
    print(f"{lab}: series {lid(r, p):.6f} degC, Poisson integral {poisson(r, p):.6f} degC")
    assert abs(lid(r, p) - poisson(r, p)) < 1e-9
print(f"hand rows at r/R {RA / R:.2f}: mode 0 {A[0]:.2f}, mode 1 {A[1] * (RA / R):.2f}, mode 2 {A[2] * (RA / R) ** 2:.2f} degC")
res = [polar_lap(lid, RA, 0.0, h) for h in (0.01, 0.005)]
print(f"residual of the series in the polar formula: h 0.01 {res[0]:.6f}, h 0.005 {res[1]:.6f} degC/m^2, ratio {res[0] / res[1]:.2f}")
assert abs(res[1]) < 0.01 and 3.5 < res[0] / res[1] < 4.5
print("chart, hot-cold diameter, x from -0.30 to 0.30 m: " + ", ".join(f"{lid(abs(s), 0.0 if s >= 0 else math.pi):.2f}" for s in [0.05 * k - 0.30 for k in range(13)]))
print("chart, cross diameter: " + ", ".join(f"{lid(abs(s), math.pi / 2):.2f}" for s in [0.05 * k - 0.30 for k in range(13)]))

print("4. The same pattern on a ball, radius 0.30 m: surface 30 + 12 P_1 + 4 P_2 of cos(theta)")
ball = lambda r, t, p: sum(a * (r / R) ** n * assoc(n, 0, math.cos(t)) for n, a in A.items())
print(f"halfway on the axis {ball(RA, 0.0, 0.0):.6f} degC, halfway on the equator {ball(RA, math.pi / 2, 0.0):.6f} degC")
M = 200
mean = sum((1 if i in (0, M) else 4 if i % 2 else 2) * ball(R, i * math.pi / M, 0.0) * math.sin(i * math.pi / M) for i in range(M + 1)) * math.pi / (3 * M) / 2
print(f"surface mean, Simpson in theta, 200 steps: {mean:.6f} degC = centre {ball(0.0, 0.0, 0.0):.6f} degC")
assert abs(mean - ball(0.0, 0.0, 0.0)) < 1e-6
rb = [sph_lap(ball, RA, 0.8, 0.3, h) for h in (0.01, 0.005)]
print(f"residual of the ball in the spherical formula: h 0.01 {rb[0]:.6f}, h 0.005 {rb[1]:.6f} degC/m^2, ratio {rb[0] / rb[1]:.2f}")
assert abs(rb[1]) < 0.01 and 3.5 < rb[0] / rb[1] < 4.5
print(f"outside, at r = 2R, a degree-1 pattern keeps: disc {(1 / 2) ** 1:.3f}, ball {(1 / 2) ** 2:.3f}; degree 2: disc {(1 / 2) ** 2:.3f}, ball {(1 / 2) ** 3:.3f}")

print("5. What breaks")
q = RA / R
k2 = [(1 + math.sqrt(1 + 4 * m * m)) / 2 for m in (1, 2)]
w1 = A[0] + A[1] * q ** k2[0] + A[2] * q ** k2[1]
print(f"mistake 1, drop u_r/r: powers {k2[0]:.6f}, {k2[1]:.6f}; halfway {w1:.2f} degC, not {lid(RA, 0.0):.2f}")
print(f"mistake 2, no fade: halfway {sum(A.values()):.2f} degC, not {lid(RA, 0.0):.2f}")
scan = [rim(2 * math.pi * k / 3600) for k in range(3600)]
print(f"mistake 3, centre as the rim's midrange: ({max(scan):.2f} + {min(scan):.2f})/2 = {(max(scan) + min(scan)) / 2:.2f} degC, not {lid(0.0, 0.0):.2f}")
a_in = 0.025                   # bung radius, m
def bung(n_r):                 # radial grid of n_r cells; returns the temperature at RA
    hr = (R - a_in) / n_r
    rr = [a_in + i * hr for i in range(n_r + 1)]
    sub = [rr[i] - hr / 2 for i in range(n_r + 1)]
    sup = [rr[i] + hr / 2 for i in range(n_r + 1)]
    dg, rhs = [-(sub[i] + sup[i]) for i in range(n_r + 1)], [0.0] * (n_r + 1)
    rhs[1] -= sub[1] * 60.0
    rhs[n_r - 1] -= sup[n_r - 1] * 30.0
    for i in range(2, n_r):    # Thomas sweep on the flux equations, rows 1 .. n_r - 1
        w = sub[i] / dg[i - 1]
        dg[i] -= w * sup[i - 1]
        rhs[i] -= w * rhs[i - 1]
    u = [0.0] * (n_r + 1)
    u[0], u[n_r] = 60.0, 30.0
    for i in range(n_r - 1, 0, -1):
        u[i] = (rhs[i] - (sup[i] * u[i + 1] if i < n_r - 1 else 0.0)) / dg[i]
    return u[round((RA - a_in) / hr)]
exact = 30 + 30 * math.log(RA / R) / math.log(a_in / R)
grid = [bung(n) for n in (220, 440, 880)]   # steps 1.25, 0.625, 0.3125 mm
be = [g - exact for g in grid]
print(f"mistake 4, bung of radius 2.5 cm at 60 degC, rim 30 degC: log form {exact:.4f}, grid {grid[1]:.4f} degC; centre rule gives 30.00")
print(f"bung grid error at steps 1.25, 0.625, 0.3125 mm: {sci(be[0])}, {sci(be[1])}, {sci(be[2])} degC; observed order {math.log2(be[0] / be[1]):.2f}, {math.log2(be[1] / be[2]):.2f}")
assert abs(be[2]) < 1e-4 and 1.9 < math.log2(be[1] / be[2]) < 2.1
kb = [(-1 + math.sqrt(1 + 4 * n * n)) / 2 for n in (1, 2)]
w5 = A[0] + A[1] * q ** kb[0] + A[2] * q ** kb[1]
print(f"mistake 5, ball with angular number n^2: powers {kb[0]:.6f}, {kb[1]:.6f}; axis halfway {w5:.2f} degC, not {ball(RA, 0.0, 0.0):.2f}")
print("ALL CHECKS PASS")
