# Triple integrals -- the check behind the card.  Standard library only.
# A 60-degree wedge cut from a cheese wheel of radius 20 cm and height 10 cm.
# Density at distance r cm from the wheel's axis: 1 + r/40 g/cm^3.
# Road one: the antiderivatives worked by hand in cylindrical coordinates.
# Road two: the definition itself.  Cut the wedge's bounding box into cubes,
# keep each cube whose centre lies in the wedge, add density times volume.
# Road two never uses the r in r dr dtheta dz.
import math
R, H, A = 20.0, 10.0, math.pi / 3              # radius, height, wedge angle
S, T = math.sin(A / 2), math.tan(A / 2)

def rho(r): return 1 + r / 40                  # density, g/cm^3

def cubes(n, dens):                            # n cubes per cm along each edge
    h = 1 / n
    m = qx = qy = qz = 0.0
    for i in range(int(R * n)):
        x = (i + 0.5) * h
        for j in range(-int(R * S * n), int(R * S * n)):
            y = (j + 0.5) * h
            if abs(y) > x * T or x * x + y * y > R * R:
                continue                       # this cube's centre is outside
            for k in range(int(H * n)):
                z = (k + 0.5) * h
                dm = dens(math.sqrt(x * x + y * y)) * h ** 3
                m, qx, qy, qz = m + dm, qx + x * dm, qy + y * dm, qz + z * dm
    return m, qx / m, qy / m, qz / m

V = A / 2 * R ** 2 * H                                  # plain volume
M = A * H * (R ** 2 / 2 + R ** 3 / 120)                 # hand: mass
QX = 2 * S * H * (R ** 3 / 3 + R ** 4 / 160)            # hand: x-moment
XU = 4 * R * S / (3 * A)                                # hand: uniform centroid
print(f"wedge: radius {R:.0f} cm, height {H:.0f} cm, angle 60 degrees = {A:.6f} rad")
print(f"hand: volume {V:.2f} cm^3, mass {M:.2f} g, x-moment {QX:.2f} g cm")
print(f"hand: centre of mass x {QX / M:.4f} cm, y 0, z {H / 2:.4f} cm")
print(f"hand: r-integrals {R**2 / 2:.4f} + {R**3 / 120:.4f} = {M / (A * H):.4f} and "
      f"{R**3 / 3:.4f} + {R**4 / 160:.4f} = {QX / (2 * S * H):.4f}; angle x height {A * H:.4f}")
print(f"hand: density {rho(0):.4f} at the tip, {rho(10):.4f} at r = 10, {rho(R):.4f} at the rind; "
      f"average {M / V:.4f} g/cm^3")
print(f"hand: uniform centroid x {XU:.4f} cm")
errs = []
for n in (1, 2, 4):
    m, xb, yb, zb = cubes(n, rho)
    errs.append(abs(m - M))
    print(f"cubes of side {1 / n:.2f} cm: mass {m:.2f} g (gap {M - m:.2f}), "
          f"centre x {xb:.4f} y {abs(yb):.4f} z {zb:.4f}")
vu, xu, _, _ = cubes(4, lambda r: 1.0)
print(f"cubes of side 0.25 cm, density 1: volume {vu:.2f} cm^3, centroid x {xu:.4f} cm")
print(f"mistake 1, drop the r in r dr dtheta dz: 'mass' {A * H * (R + R * R / 80):.2f}")
print(f"mistake 2, ignore density: centre x {XU:.4f} cm, not {QX / M:.4f}")
print(f"mistake 3, divide the moment by volume: centre x {QX / V:.4f} cm")
F = 10                                                  # figure: 1 cm = 10 units
pt = lambda r, d: f"({40 + F * r * math.cos(math.radians(d)):.2f}, {120 - F * r * math.sin(math.radians(d)):.2f})"
print(f"figure, 1 cm = {F} units; tip {pt(0, 0)}; corners {pt(R, 30)} {pt(R, -30)}; rind {pt(R, 0)}; mid-arc ends {pt(10, 30)} {pt(10, -30)}")
print(f"figure, cell r 14 to 16 cm, 12 to 24 degrees {pt(14, 12)} {pt(16, 12)} {pt(16, 24)} {pt(14, 24)}; dots {pt(QX / M, 0)} {pt(XU, 0)}")
assert abs(m - M) / M < 0.002 and abs(xb - QX / M) < 0.01    # road two meets road one
assert abs(vu - V) / V < 0.002 and abs(xu - XU) < 0.01        # uniform case, own formula
assert errs[2] < errs[0] / 4                                  # the gap closes as cubes shrink
assert abs(zb - H / 2) < 1e-9 and abs(yb) < 1e-9              # symmetry, found not assumed
print("ALL CHECKS PASS")
