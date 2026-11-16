# The fundamental solution of -Laplacian: one 1 nC charge in a large hall, and a 1 nC/m wire.
# Standard library only. Simpson's rule and every check are written out here.
from math import sqrt, exp, log, pi

EPS0, Q, LAM = 8.8541878188e-12, 1e-9, 1e-9     # F/m (CODATA 2022); C; C/m
AREA = {1: 2.0, 2: 2 * pi, 3: 4 * pi, 4: 2 * pi ** 2}   # surface of the unit sphere in d dimensions

def Phi(r, d):                   # the fundamental solution, -Lap Phi = delta, as a function of r = |x|
    if d == 1: return -r / 2
    if d == 2: return -log(r) / (2 * pi)
    return r ** (2 - d) / ((d - 2) * AREA[d])

def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def lap(f, p, h):                # centred-difference Laplacian at point p
    s = 0.0
    for i in range(len(p)):
        up = list(p); dn = list(p); up[i] += h; dn[i] -= h
        s += (f(up) - 2 * f(p) + f(dn)) / h ** 2
    return s

def sci(x, p): return f"{x:.{p}e}"

qe, le = Q / EPS0, LAM / EPS0
print(f"hand: Q/eps0 = {qe:.4f} V m; Phi_3(1 m) = 1/(4 pi) = {Phi(1, 3):.7f} per m; potential at 1 m {qe*Phi(1, 3):.5f} V")
print(f"hand: potential at 10 cm {qe*Phi(0.1, 3):.4f} V, at 2 m {qe*Phi(2, 3):.5f} V; field at 1 m {qe/(4*pi):.5f} V/m")
print(f"hand: wire lambda/eps0 = {le:.4f} V; /(2 pi) = {le/(2*pi):.4f} V; ln 100 = {log(100):.5f};"
      f" 1 cm to 1 m: {le*(Phi(0.01, 2)-Phi(1, 2)):.4f} V; field at 10 cm {le/(2*pi*0.1):.3f} V/m")

for d in (1, 2, 3, 4):           # road 1: the radial formula, flux -Phi'(r) A_d r^(d-1) through spheres
    fl = [-(Phi(r + 1e-5, d) - Phi(r - 1e-5, d)) / 2e-5 * AREA[d] * r ** (d - 1) for r in (0.5, 1.0, 2.0)]
    print(f"d = {d}: Phi(1 m) = {Phi(1, d) + 0.0:.7f}; flux through spheres r = 0.5, 1, 2 m: " + ", ".join(f"{x:.6f}" for x in fl))
    for x in fl: assert abs(x - 1) < 1e-8

f3 = lambda p: Phi(sqrt(sum(c * c for c in p)), 3)   # road 2: the formula back in Laplace's equation, centred differences
f2 = lambda p: Phi(sqrt(sum(c * c for c in p)), 2)
for name, f, p in (("d = 3 at (0.6, 0.3, 0.2) m", f3, [0.6, 0.3, 0.2]), ("d = 2 at (0.6, 0.3) m", f2, [0.6, 0.3])):
    a, b = lap(f, p, 0.02), lap(f, p, 0.01)
    print(f"{name}: centred Laplacian {sci(a, 3)} (h 2 cm), {sci(b, 3)} (h 1 cm), ratio {a/b:.2f}")
    assert abs(a / b - 4) < 0.05 and abs(b) < 1e-4
w1 = lap(lambda p: sum(c * c for c in p) ** -1, [1.0, 0, 0], 0.01)
w2 = lap(lambda p: sum(c * c for c in p) ** -0.5, [1.0, 0], 0.01)
exact = lambda p, d: p * (p + d - 2)      # Step 1 on r^p: Lap r^p = p (p + d - 2) r^(p - 2), here at r = 1 m
print(f"mistake, field shape 1/r^2 as a 3-d potential: Laplacian at 1 m {w1:.4f} per m^4 (h 1 cm), exactly {exact(-2, 3)}, not 0")
print(f"mistake, 1/r as the wire's potential: Laplacian in the plane at 1 m {w2:.4f} per m^3 (h 1 cm), exactly {exact(-1, 2)}, not 0")
assert abs(w1 - exact(-2, 3)) < 5e-3 and abs(w2 - exact(-1, 2)) < 5e-3

def heat(r, d, T, n=6000):       # road 3, scaled kappa = 1: integral of the heat kernel over time 0..T, t = e^u
    g = lambda u: exp(u) * exp(-r * r / (4 * exp(u))) / (4 * pi * exp(u)) ** (d / 2)
    return simpson(g, -30.0, log(T), n)
for r in (0.5, 1.0, 2.0):
    v = heat(r, 3, exp(40))
    print(f"d = 3, r = {r} m: time integral of heat kernel {v:.7f}, 1/(4 pi r) {Phi(r, 3):.7f}")
    assert abs(v - Phi(r, 3)) < 1e-7
print(f"d = 3, tail beyond t = e^40 at most {sci(2 * (4 * pi) ** -1.5 * exp(-20), 1)}")
v4 = heat(1.0, 4, exp(40))
print(f"d = 4, r = 1 m: time integral {v4:.7f}, 1/(4 pi^2 r^2) {Phi(1, 4):.7f}")
assert abs(v4 - Phi(1, 4)) < 1e-7
for T in (1e4, 1e8):
    dv = heat(0.01, 2, T) - heat(1.0, 2, T)
    print(f"d = 2, T = {T:.0e}: at 1 m alone {heat(1.0, 2, T):.4f} (grows like ln T/(4 pi));"
          f" 1 cm minus 1 m {dv:.6f}; ln(100)/(2 pi) {Phi(0.01, 2):.6f}; tail at most {sci(1 / (16 * pi * T), 1)}")
    assert abs(dv - Phi(0.01, 2)) < 2 / (16 * pi * T)

B = 0.5                          # road 4: the point-source identity with a bump of width b = 50 cm
phi = lambda r: exp(-r * r / (2 * B * B))
def ident(d, eps, c=1.0, R=5.0):  # integral over r > eps of c Phi (-Lap bump), radially
    return simpson(lambda r: AREA[d] * r ** (d - 1) * c * Phi(r, d) * (d / B ** 2 - r * r / B ** 4) * phi(r), eps, R, 8000)
for d in (2, 3):
    for eps in (0.1, 0.01, 0.001):
        v = ident(d, eps)
        part = AREA[d] * eps ** (d - 1) * Phi(eps, d) * (-eps / B ** 2) * phi(eps)
        print(f"d = {d}, eps = {eps} m: integral outside eps {v:.6f}; flux part {phi(eps):.6f};"
              f" Phi part {part:.6f}; sum {phi(eps)+part:.6f}")
        assert abs(v - phi(eps) - part) < 1e-8
w = [ident(d, 1e-9) for d in (2, 3, 4)]
print(f"whole integral, bump width 0.5 m, d = 2, 3, 4: {w[0]:.6f}, {w[1]:.6f}, {w[2]:.6f}; bump at the source 1, at the 5 m cut-off {sci(phi(5.0), 1)}")
for x in w: assert abs(x - 1) < 1e-6
print(f"mistake, 2-d constant 1/(2 pi r) in 3-d: identity gives {ident(3, 1e-9, 2.0):.6f}; potential at 1 m {qe/(2*pi):.4f} V")

def cube_flux(c, n=120):         # road 5: flux of the field x/(4 pi |x|^3) out of the cube [-1, 1]^3, charge at c
    tot = 0.0
    for ax in range(3):
        for s in (-1.0, 1.0):
            def face(u, v):
                p = [u, v]; p.insert(ax, s); x = [p[i] - c[i] for i in range(3)]
                return s * x[ax] / (4 * pi * sqrt(sum(t * t for t in x)) ** 3)
            tot += simpson(lambda u: simpson(lambda v: face(u, v), -1, 1, n), -1, 1, n)
    return tot
fin, fout = cube_flux([0.5, 0.3, -0.2]), cube_flux([2.5, 0.0, 0.0])
print(f"cube 2 m wide, charge at (0.5, 0.3, -0.2) m: flux {fin:.6f} -> {qe*fin:.4f} V m; charge at (2.5, 0, 0) m: flux {fout:.6f}")
assert abs(fin - 1) < 1e-5 and abs(fout) < 1e-6

k = 1 / (4 * pi * EPS0)          # the hall: an earthed floor 5 m below the charge acts as a mirror charge
di = sqrt(1 + 10 ** 2)
print(f"hall: earthed floor 5 m below, mirror charge 10 m below; at 1 m sideways it shifts the potential by {-k*Q/di:.4f} V"
      f" ({100/di:.2f}% of its 1 m value) and the field by {k*Q/di**2:.5f} V/m ({100/di**2:.2f}%)")
print("chart, point charge V at r = 0.25..2 m: " + ", ".join(f"{qe*Phi(i/4, 3):.2f}" for i in range(1, 9)))
print("chart, wire V above 1 m at r = 0.25..2 m: " + ", ".join(f"{le*Phi(i/4, 2) + 0.0:.2f}" for i in range(1, 9)))
print("mistake, wire potential taken as zero far away: 1 cm to R = 1 km, 1000 km: "
      + ", ".join(f"{le*(Phi(0.01, 2)-Phi(R, 2)):.2f} V" for R in (1e3, 1e6)))
print("ALL CHECKS PASS")
