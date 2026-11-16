# Method of images -- the check behind the card.  Standard library only.
# A 1 nC charge 5 cm above a grounded metal sheet; the same charge 5 cm from the centre
# of a grounded metal sphere of radius 10 cm.  Roads: the image formulas; quadrature of
# the induced charge, the force and the Poisson integral; centred differences; a random walk.
import math

EPS0 = 8.8541878188e-12                    # F/m, vacuum permittivity (CODATA 2022)
K = 1 / (4 * math.pi * EPS0)               # Coulomb constant, N m^2/C^2
q, h, R, a = 1e-9, 0.05, 0.10, 0.05        # C, m, m, m
AREA = {2: 2 * math.pi, 3: 4 * math.pi}    # area of the unit sphere in d dimensions

def dist(p, s): return math.sqrt(sum((u - v) ** 2 for u, v in zip(p, s)))
def V_plane(y): return K * q * (1 / dist(y, (0, 0, h)) - 1 / dist(y, (0, 0, -h)))
XB, XT, QT = (a, 0.0, 0.0), (R * R / a, 0.0, 0.0), -q * R / a   # ball: charge, image point, image charge
def V_ball(y): return K * q / dist(y, XB) + K * QT / dist(y, XT)
def K_half(x, y, d): return 2 * x[-1] / (AREA[d] * dist(x, y) ** d)
def K_ball(x, y, d, r): return (r * r - sum(c * c for c in x)) / (AREA[d] * r * dist(x, y) ** d)

def simpson(f, lo, hi, n):
    w = (hi - lo) / n
    return w / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(lo + i * w) for i in range(n + 1))

def over_plane(x, f, n=200, top=math.pi / 2 - 1e-9):   # f(y) dA over the sheet, polar about x's foot, rho = x3 tan(th)
    def ring(th):
        rho = x[2] * math.tan(th)
        jac = rho * x[2] / math.cos(th) ** 2
        return jac * simpson(lambda ph: f((x[0] + rho * math.cos(ph), x[1] + rho * math.sin(ph), 0.0)), 0, 2 * math.pi, n)
    return simpson(ring, 0, top, n)

def over_sphere(f, n=200):
    def ring(th):
        return R * R * math.sin(th) * simpson(lambda ph: f((R * math.cos(th), R * math.sin(th) * math.cos(ph),
                                                           R * math.sin(th) * math.sin(ph))), 0, 2 * math.pi, n)
    return simpson(ring, 0, math.pi, n)

def laplacian(V, y, s):
    tot = 0.0
    for i in range(3):
        up = list(y); dn = list(y); up[i] += s; dn[i] -= s
        tot += (V(up) - 2 * V(y) + V(dn)) / (s * s)
    return tot

X = (0.0, 0.0, h)
print(f"Coulomb constant k = 1/(4 pi eps0) = {K / 1e9:.6f}e9 N m^2/C^2; kq = {K * q:.4f} V m")
mid = K * q * (1 / 0.025 - 1 / 0.075)
print(f"V halfway down, 2.5 cm: {K * q / 0.025:.2f} V - {K * q / 0.075:.2f} V = {mid:.2f} V")
print(f"V on the sheet, 6 points out to 20 cm: {max(abs(V_plane((u, w, 0.0))) for u in (0, 0.03, 0.2) for w in (0, 0.07)):.2f} V")
assert max(abs(V_plane((u, w, 0.0))) for u in (0, 0.03, 0.2) for w in (0, 0.07)) < 1e-12
s0, s5 = -q * K_half(X, (0, 0, 0), 3), -q * K_half(X, (0.05, 0, 0), 3)
print(f"induced charge density at the foot {s0 * 1e9:.2f} nC/m^2, at 5 cm out {s5 * 1e9:.2f} nC/m^2")
assert abs(s0 + q / (2 * math.pi * h * h)) < 1e-15
tot = over_plane(X, lambda y: -q * K_half(X, y, 3))
print(f"total induced charge on the sheet, by quadrature: {tot * 1e9:.6f} nC")
assert abs(tot + q) < 1e-15
half = over_plane(X, lambda y: -q * K_half(X, y, 3), top=math.pi / 3)   # tan(60 deg) = sqrt(3)
print(f"induced charge within h*sqrt(3) = {100 * h * math.sqrt(3):.2f} cm: {half * 1e9:.3f} nC")
assert abs(half + q / 2) < 1e-15
F_img = K * q * q / (2 * h) ** 2
F_int = over_plane(X, lambda y: -K * q * (-q * K_half(X, y, 3)) * h / dist(X, y) ** 3)
print(f"pull on the charge: image {F_img * 1e6:.4f} uN, summed over the sheet {F_int * 1e6:.4f} uN")
assert abs(F_int - F_img) < 1e-6 * F_img
print(f"work to pull the charge from 5 cm out to far away: {F_img * h * 1e9:.2f} nJ; charge-image pair at 10 cm: {K * q * q / (2 * h) * 1e9:.2f} nJ")
xP, pP = (0.03, 0.0, 0.04), (0.0, 0.0, -0.05)
u_p = over_plane(xP, lambda y: K_half(xP, y, 3) / dist(y, pP))
print(f"Poisson integral, sheet data 1/|y-p|: {u_p:.6f} per m, exact 1/|x-p| = {1 / dist(xP, pP):.6f} per m")
assert abs(u_p - 1 / dist(xP, pP)) < 1e-6
r1, r2 = laplacian(V_plane, Y := (0.02, 0.01, 0.03), 1e-3), laplacian(V_plane, Y, 5e-4)
print(f"Laplacian of V at (2,1,3) cm, centred differences: step 1 mm {r1:.1f}, 0.5 mm {r2:.1f} V/m^2; V/r^2 = {V_plane(Y) / 0.03 ** 2:.0f} V/m^2")
assert abs(r1 / r2 - 4) < 0.2 and abs(r2) < 1e-3 * V_plane(Y) / 0.03 ** 2

print(f"ball: R = 10 cm, charge at 5 cm, image point {100 * XT[0]:.1f} cm, image charge {QT * 1e9:.1f} nC")
pts = [(R * math.sin(t) * math.cos(f), R * math.sin(t) * math.sin(f), R * math.cos(t)) for t in (0.1, 0.9, 1.7, 2.5, 3.0) for f in (0, 1, 2, 4)] + [(R, 0, 0), (-R, 0, 0)]
print(f"max |V| at 22 points of the sphere below 1e-9 V: {'yes' if max(abs(V_ball(y)) for y in pts) < 1e-9 else 'no'}")
assert max(abs(V_ball(y)) for y in pts) < 1e-9
for lab, y in (("nearest", (R, 0, 0)), ("farthest", (-R, 0, 0))):
    print(f"  {lab} point: induced density {-q * K_ball(XB, y, 3, R) * 1e9:.3f} nC/m^2")
tb = over_sphere(lambda y: -q * K_ball(XB, y, 3, R))
print(f"total induced charge on the sphere, by quadrature: {tb * 1e9:.6f} nC")
assert abs(tb + q) < 1e-14
pB = (0.0, 0.25, 0.0)
u_b = over_sphere(lambda y: K_ball(XB, y, 3, R) / dist(y, pB))
print(f"Poisson integral, sphere data 1/|y-p|: {u_b:.6f} per m, exact {1 / dist(XB, pB):.6f} per m")
assert abs(u_b - 1 / dist(XB, pB)) < 1e-6
b1, b2 = laplacian(V_ball, (0.0, 0.03, 0.02), 1e-3), laplacian(V_ball, (0.0, 0.03, 0.02), 5e-4)
print(f"Laplacian of V inside the ball: step 1 mm {b1:.2f}, 0.5 mm {b2:.2f} V/m^2")
assert abs(b1 / b2 - 4) < 0.2

print("plane (d = 2): kernels times 2 pi against the complex-analysis card")
P = lambda r, t: (1 - r * r) / (1 - 2 * r * math.cos(t) + r * r)
dd = max(abs(2 * math.pi * K_ball((0.5, 0), (math.cos(t), math.sin(t)), 2, 1) - P(0.5, t)) for t in [i * 0.4 for i in range(16)])
print(f"  disc r = 1/2: nearest {2 * math.pi * K_ball((0.5, 0), (1, 0), 2, 1):.6f}, farthest {2 * math.pi * K_ball((0.5, 0), (-1, 0), 2, 1):.6f}; gap to P_r below 1e-12: {'yes' if dd < 1e-12 else 'no'}")
dh = max(abs(K_half((0, 3), (t, 0), 2) - 3 / (math.pi * (t * t + 9))) for t in range(-10, 11))
print(f"  half-plane at 3i: gap to y/(pi((x-t)^2+y^2)) below 1e-12: {'yes' if dh < 1e-12 else 'no'}")
assert dd < 1e-12 and dh < 1e-12

s = 0x2026111505
def rnd():
    global s
    s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
N, near, mid_n = 20000, 0, 0
for _ in range(N):
    x, y, z = 0.0, 0.0, h
    while z > 1e-5:
        c, ph = 2 * rnd() - 1, 2 * math.pi * rnd()
        sn = math.sqrt(max(0.0, 1 - c * c))
        x, y, z = x + z * sn * math.cos(ph), y + z * sn * math.sin(ph), z + z * c
    rr = math.hypot(x, y)
    near += rr < h
    mid_n += rr < h * math.sqrt(3)
for lab, cnt, ex in (("5 cm", near, 1 - 1 / math.sqrt(2)), ("8.66 cm", mid_n, 0.5)):
    se = math.sqrt(ex * (1 - ex) / N)
    print(f"random walk, {N} walkers from the charge: within {lab} {cnt} = {cnt / N:.4f}, kernel says {ex:.4f} (s.e. {se:.4f})")
    assert abs(cnt / N - ex) < 4 * se

def slab(M, L=0.10): return K * q * sum((-1) ** m / abs(0.025 - (L / 2 + m * L)) for m in range(-M, M + 1))
exact = 4 * K * q / 0.10 * math.log(1 + math.sqrt(2)) / math.sqrt(2)
print(f"two sheets 10 cm apart, V at 2.5 cm: one image {mid:.2f} V (top sheet then at {K * q * (1 / 0.05 - 1 / 0.15):.2f} V)")
for M in (1, 10, 100, 1000):
    print(f"  images out to round {M:4d}: {slab(M):7.2f} V, first omitted round {abs(slab(M + 1) - slab(M)):.2f} V")
print(f"  full sum {exact:.2f} V")
assert abs(slab(1000) - exact) < abs(slab(1001) - slab(1000))

kap, t, y0 = 1.11e-4, 10.0, 0.05
G = lambda x: math.exp(-x * x / (4 * kap * t)) / math.sqrt(4 * math.pi * kap * t)
print(f"heat: 1 K m spot 5 cm from the rod's end, after 10 s: free {G(0):.4f} K, end held at room temperature {G(0) - G(2 * y0):.4f} K, end insulated {G(0) + G(2 * y0):.4f} K")
kept = simpson(lambda x: G(x - y0) - G(x + y0), 0, 1.0, 2000)
ser = sum((-1) ** n * (y0 / math.sqrt(4 * kap * t)) ** (2 * n + 1) / (math.factorial(n) * (2 * n + 1)) for n in range(40)) * 2 / math.sqrt(math.pi)
print(f"  fraction of the heat still in the rod, end held: {kept:.6f} by quadrature, {ser:.6f} by the erf series")
assert abs(kept - ser) < 1e-9

print("bad images: no image V at the foot", f"{K * q / h:.2f} V; same-sign image {2 * K * q / h:.2f} V;",
      f"source half only {-q / (4 * math.pi * h * h) * 1e9:.2f} nC/m^2")
print(f"bad images: sphere image -1 nC: nearest {K * q * (1 / 0.05 - 1 / 0.10):.2f} V, farthest {K * q * (1 / 0.15 - 1 / 0.30):.2f} V")
print("figure, 20 px per cm: charge (240, 50), image (240, 250), sheet at y = 150, sheet point (340, 150),",
      f"half-charge marks x = {240 - 20 * 100 * h * math.sqrt(3):.1f} and {240 + 20 * 100 * h * math.sqrt(3):.1f}, slant {100 * dist((h, 0, 0), X):.2f} cm")
print("ALL CHECKS PASS")
