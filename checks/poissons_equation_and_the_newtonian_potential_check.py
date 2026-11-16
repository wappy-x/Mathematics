# Poisson's equation -Laplacian(V) = rho/eps0 for a uranium-238 nucleus, modelled as a
# uniformly charged ball.  Standard library only.  Distances in fm, potentials in MV,
# energies in MeV.  Roads: (1) the closed form from Newton's shell theorem; (2) the
# convolution integral done along lines of sight from the field point (Simpson's rule);
# (3) the convolution as a sum over small cubes, each a point charge; (4) the equation's
# residual by centred differences.
import math

eps0 = 8.8541878188e-12                     # F/m, CODATA 2022
e = 1.602176634e-19                         # C, exact
ke = e / (4 * math.pi * eps0) / 1e-15 / 1e6  # MV fm: potential of one proton charge at 1 fm
Z, A, r0 = 92, 238, 1.2                     # uranium-238; r0 in fm (typical value)
R = r0 * A ** (1 / 3)                       # fm: radius of the ball
VR = Z * ke / R                             # MV: potential at the surface, kQ/R
S = 3 * VR / R ** 2                         # MV/fm^2: rho/eps0, the source

def V(r):                                   # road 1: closed form
    return VR * (3 - r * r / R ** 2) / 2 if r < R else VR * R / r

def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def V_sight(r, rad):                        # road 2: field point at r inside a ball of radius rad
    L = lambda th: -r * math.cos(th) + math.sqrt(rad * rad - (r * math.sin(th)) ** 2)
    return S / 4 * simpson(lambda th: L(th) ** 2 * math.sin(th), 0.0, math.pi, 400)

def V_cubes(m, pts):                        # road 3: cubes of side R/m, each a point charge
    a = R / m
    tot = [0.0] * len(pts)
    cells = 0
    for i in range(-m, m):
        for j in range(-m, m):
            for k in range(-m, m):
                c = ((i + 0.5) * a, (j + 0.5) * a, (k + 0.5) * a)
                if c[0] ** 2 + c[1] ** 2 + c[2] ** 2 > R * R:
                    continue
                cells += 1
                for n, p in enumerate(pts):
                    tot[n] += 1 / math.dist(p, c)
    return [S / (4 * math.pi) * a ** 3 * t for t in tot], cells

def lap(f, x, y, z, h):                     # 7-point -Laplacian
    return -(f(x + h, y, z) + f(x - h, y, z) + f(x, y + h, z) + f(x, y - h, z)
             + f(x, y, z + h) + f(x, y, z - h) - 6 * f(x, y, z)) / h ** 2

V3 = lambda x, y, z: V(math.sqrt(x * x + y * y + z * z))

print(f"ball: Z = {Z}, R = {R:.4f} fm, ke = {ke:.6f} MV fm")
print(f"source rho/eps0 = {S:.6f} MV/fm^2")
print(f"surface V = kQ/R = {VR:.4f} MV")
for r in (0.0, R / 2):
    print(f"r = {r:.4f} fm: closed form {V(r):.4f} MV, line-of-sight integral {V_sight(r, R):.4f} MV")
    assert abs(V(r) - V_sight(r, R)) < 1e-8
pts = [(0.0, 0.0, 0.0), (R / 2, 0.0, 0.0), (2 * R, 0.0, 0.0)]
exact = [V(math.dist(p, pts[0])) for p in pts]
print("cube sum, centre / half radius / twice radius (MV):")
errs = []
for m in (10, 20, 40):
    vals, cells = V_cubes(m, pts)
    errs.append(max(abs(v - x) for v, x in zip(vals, exact)))
    print(f"  side R/{m}, {cells} cubes: {vals[0]:.4f}, {vals[1]:.4f}, {vals[2]:.4f}; worst error {errs[-1]:.4f}")
print(f"  exact:                  {exact[0]:.4f}, {exact[1]:.4f}, {exact[2]:.4f}")
assert errs[2] < errs[0] / 4 and errs[2] < 0.05

# road 4: the equation's residual, and the seam at the surface
ri = lap(V3, 2.0, 1.0, 1.0, 0.25)
print(f"-Lap V inside at (2,1,1) fm, h = 0.25: {ri:.6f} MV/fm^2 (source {S:.6f})")
assert abs(ri - S) < 1e-6
for h in (0.5, 0.25):
    print(f"-Lap V outside at (12,5,3) fm, h = {h}: {lap(V3, 12.0, 5.0, 3.0, h):.6f} MV/fm^2")
assert abs(lap(V3, 12.0, 5.0, 3.0, 0.25)) < 1e-3
for h in (0.1, 0.01):
    print(f"-Lap V on the surface at (R,0,0), h = {h}: {lap(V3, R, 0.0, 0.0, h):.4f} MV/fm^2")
h = 1e-3
d_in, d_out = (V(R) - V(R - h)) / h, (V(R + h) - V(R)) / h
s_in = (V(R) - 2 * V(R - h) + V(R - 2 * h)) / h ** 2
s_out = (V(R + 2 * h) - 2 * V(R + h) + V(R)) / h ** 2
print(f"slope V' at R: inside {d_in:.4f}, outside {d_out:.4f} MV/fm (Gauss: -kQ/R^2 = {-VR / R:.4f})")
print(f"V'' at R: inside {s_in:.4f}, outside {s_out:.4f} MV/fm^2, jump {s_out - s_in:.4f}")
assert abs(d_in - d_out) < 1e-2 and abs(s_out - s_in - S) < 1e-2

# the energy: U = (1/2) * integral of charge density times potential
n = Z / (4 / 3 * math.pi * R ** 3)          # protons per fm^3
U = 0.5 * simpson(lambda r: n * V(r) * 4 * math.pi * r * r, 0.0, R, 200)
print(f"Coulomb energy: integral {U:.2f} MeV, (3/5) Z^2 ke/R = {0.6 * Z * VR:.2f} MeV")
assert abs(U - 0.6 * Z * VR) < 1e-6
print(f"liquid-drop coefficient (3/5) ke/r0 = {0.6 * ke / r0:.5f} MeV")

print("what breaks:")
print(f"  charge on the surface only: U = {0.5 * Z * VR:.2f} MeV")
Upt = 0.5 * simpson(lambda r: n * Z * ke * 4 * math.pi * r, 0.0, R, 200)
print(f"  kQ/r used inside too: U = {Upt:.2f} MeV, centre infinite")
print(f"  inner charge only, at R/2: {VR * 0.5 ** 3 / 0.5:.4f} MV")
print(f"  forget the 1/2: U = {2 * U:.2f} MeV")
print(f"  kernel 1/r without 4 pi: centre {4 * math.pi * V(0):.2f} MV")
print("  source that does not fade, centre potential (MV): ", end="")
grow = [V_sight(0.0, L * R) for L in (1, 2, 4, 8)]
print(" ".join(f"{g:.2f}" for g in grow))
assert abs(grow[3] / grow[2] - 4) < 1e-9
print("  f continuous, not Hoelder: u = (x^2-y^2) log(-log r), scaled")
for s in (1e-2, 1e-6, 1e-12):
    Lg = -math.log(s)
    u = lambda x, y, z: (x * x - y * y) * math.log(-0.5 * math.log(x * x + y * y + z * z))
    hh = s / 1000
    uxx = (u(s + hh, 0.0, 0.0) - 2 * u(s, 0.0, 0.0) + u(s - hh, 0.0, 0.0)) / hh ** 2
    form = 2 * math.log(Lg) - 3 / Lg - 1 / Lg ** 2
    f_num, f_form = lap(u, s, 0.0, 0.0, hh), 5 / Lg + 1 / Lg ** 2
    print(f"    r = {s:.0e}: f = {f_form:.4f} (grid {f_num:.4f}), u_xx = {form:.4f} (grid {uxx:.4f})")
    assert abs(uxx - form) < 1e-3 and abs(f_num - f_form) < 1e-3

print("try changing:")
Rpb = 1.2 * 208 ** (1 / 3)
print(f"  lead-208: R = {Rpb:.4f} fm, centre {1.5 * 82 * ke / Rpb:.4f} MV, U = {0.6 * 82 * 82 * ke / Rpb:.2f} MeV")
Rh = 1.2 * 119 ** (1 / 3)
Uh = 0.6 * 46 * 46 * ke / Rh
print(f"  two halves Z = 46, A = 119: R = {Rh:.4f} fm, U = {Uh:.2f} MeV each, Coulomb release {U - 2 * Uh:.2f} MeV")
print("chart, r (fm), solid ball (MV), surface charge (MV):")
for r in range(0, 24, 2):
    print(f"  {r}, {V(r):.2f}, {VR if r < R else VR * R / r:.2f}")
print("ALL CHECKS PASS")
