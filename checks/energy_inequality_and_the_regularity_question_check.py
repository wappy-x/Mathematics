# The energy inequality, and the gap it leaves in three dimensions -- the check
# behind the card.  Standard library only.  Water (nu = 1.0e-6 m^2/s) in a 5 cm
# periodic cell, the size of the pipe's largest eddies; three crossing velocity
# waves, two of 1 m/s and one of sqrt(2) m/s.
# Every integral is a grid sum of trigonometric products, exact once the grid
# beats the highest frequency; derivatives are taken by hand, mode by mode.
import math
L, U, NU, RHO, K = 0.05, 1.0, 1.0e-6, 1000.0, 1.0   # K: illustrative constant
k0 = 2 * math.pi / L
# (amplitude direction, wave numbers in units of k0, phase); amplitude ⟂ wave numbers
FLOW3 = [((0, 0, 1), (1, 0, 0), 0.0), ((1, 0, 0), (0, 1, 1), 0.0), ((1, -1, 0), (1, 1, 1), -math.pi / 2)]
FLOW2 = [((0, 1, 0), (1, 0, 0), 0.0), ((1, 0, 0), (0, 1, 0), 0.0), ((1, -1, 0), (1, 1, 0), -math.pi / 2)]
SQUEEZE = [((-1, 0, 0), (1, 0, 0), 0.0)] + FLOW3[1:]   # first amplitude along its k: not ⟂

def yn(claim):
    return "yes" if claim else "no"

def e(x, p=4):                     # e-notation with the exponent written as Rust writes it
    m, ex = f"{x:.{p}e}".split("e")
    return f"{m}e{int(ex)}"

def point(flow, x, lam):           # velocity, gradient g[i][m] = du_i/dx_m, Laplacian
    u, g, lap = [0.0] * 3, [[0.0] * 3 for _ in range(3)], [0.0] * 3
    for a, kv, ph in flow:
        q = [lam * k0 * c for c in kv]
        th = sum(q[m] * x[m] for m in range(3)) + ph
        c, s, qq = math.cos(th), math.sin(th), sum(v * v for v in q)
        for i in range(3):
            u[i] += lam * U * a[i] * c
            lap[i] -= lam * U * a[i] * qq * c
            for m in range(3):
                g[i][m] -= lam * U * a[i] * q[m] * s
    return u, g, lap

def integrals(flow, d, lam=1.0, n=8):   # box of side L/lam, flow sped up lam times
    h = L / lam / n
    tot = dict(E=0.0, y=0.0, P=0.0, S=0.0, W=0.0, T=0.0, V=0.0, p=0.0)
    for i in range(n):
        for j in range(n):
            for l in range(n if d == 3 else 1):
                x = (i * h, j * h, l * h)
                u, g, lap = point(flow, x, lam)
                adv = [sum(u[m] * g[c][m] for m in range(3)) for c in range(3)]
                w = [g[2][1] - g[1][2], g[0][2] - g[2][0], g[1][0] - g[0][1]]   # vorticity
                gp = [-k0 * math.sin(k0 * x[0]) * math.cos(k0 * x[1]),           # grad of a test
                      -k0 * math.cos(k0 * x[0]) * math.sin(k0 * x[1]), 0.0]      # pressure
                tot["E"] += 0.5 * sum(v * v for v in u)
                tot["y"] += sum(g[a][b] ** 2 for a in range(3) for b in range(3))
                tot["P"] += sum(v * v for v in lap)
                tot["S"] += sum(adv[c] * lap[c] for c in range(3))
                tot["W"] += sum(w[a] * 0.5 * (g[a][b] + g[b][a]) * w[b] for a in range(3) for b in range(3))
                tot["T"] += sum(adv[c] * u[c] for c in range(3))
                tot["V"] += sum(u[c] * lap[c] for c in range(3))
                tot["p"] += sum(gp[c] * u[c] for c in range(3))
    return {key: v * h ** d for key, v in tot.items()}

r3, r2, bad = integrals(FLOW3, 3), integrals(FLOW2, 2), integrals(SQUEEZE, 3)
Re = U * L / NU
print(f"house: L = {L} m, U = {U} m/s, nu = {e(NU, 1)} m^2/s, Re = UL/nu = {Re:.0f}")
for name, r, unit in (("3D", r3, "m^5/s^2"), ("2D", r2, "m^4/s^2 per m of depth")):
    print(f"{name}: energy E0 = {e(r['E'])} {unit}; enstrophy y0 = {r['y']:.4f}; |lap u|^2 = {r['P']:.1f}")
print(f"3D energy in joules (x rho = 1000 kg/m^3): {RHO * r3['E']:.4f} J; budget E0/nu = {r3['E'] / NU:.1f} m^3/s")
for name, r in (("3D", r3), ("2D", r2)):
    sc = r["y"] * k0 * U                                   # natural size of a cubic term
    print(f"{name}: transport term ~0: {yn(abs(r['T']) < 1e-12 * sc)}; pressure term ~0: "
          f"{yn(abs(r['p']) < 1e-12 * sc)}; int u.lap u = -y0: {yn(abs(r['V'] + r['y']) < 1e-12 * r['y'])}")
print(f"3D stretching S = {r3['S']:.4f} m^3/s^3; as vorticity times strain: {r3['W']:.4f} m^3/s^3")
print(f"2D stretching ~0: {yn(abs(r2['S']) < 1e-12 * r2['y'] * k0 * U)}")
print(f"3D start: dy/dt = 2S - 2 nu |lap u|^2 = {2 * r3['S']:.4f} - {2 * NU * r3['P']:.4f} = "
      f"{2 * r3['S'] - 2 * NU * r3['P']:.4f} m^3/s^3; stretching / damping = {r3['S'] / (NU * r3['P']):.1f}")
print(f"2D start: dy/dt = -2 nu |lap u|^2 = {-2 * NU * r2['P']:.4f} m^2/s^3: never rises")
for lam in (10.0, 100.0):
    for d, flow, r in ((3, FLOW3, r3), (2, FLOW2, r2)):
        z = integrals(flow, d, lam)
        print(f"zoom {lam:.0f}x, {d}D: energy ratio {z['E'] / r['E']:.6f} (rule lam^(2-d) = {lam ** (2 - d):.6f}); "
              f"enstrophy ratio {z['y'] / r['y']:.1f}")
        assert abs(z["E"] / r["E"] - lam ** (2 - d)) < 1e-9
Tstar = NU ** 3 / (2 * K * r3["y"] ** 2)
print(f"3D guarantee T* = nu^3/(2K y0^2) = {e(Tstar)} s; turnover L/U = {L / U} s; Re^3 = {e(Re ** 3)}")
f = lambda z: z ** 3 / 2                                    # dz/ds, z = y/y0, s = t/T*
z, s, hs, Iz, Iz2, marks, out = 1.0, 0.0, 1e-4, 0.0, 0.0, [0.25, 0.5, 0.75, 0.9, 0.96, 0.99], [1.0]
for step in range(9900):
    k1 = f(z); k2 = f(z + hs * k1 / 2); k3 = f(z + hs * k2 / 2); k4 = f(z + hs * k3)
    zn = z + hs * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    Iz += hs * (z + zn) / 2; Iz2 += hs * (z * z + zn * zn) / 2
    z, s = zn, (step + 1) * hs
    if marks and abs(s - marks[0]) < 1e-9:
        out.append(z); marks.pop(0)
exact = [1 / math.sqrt(1 - q) for q in (0, 0.25, 0.5, 0.75, 0.9, 0.96, 0.99)]
print("chart, 3D bound y/y0 at t/T* = 0,0.25,0.5,0.75,0.9,0.96,0.99:", ", ".join(f"{v:.3f}" for v in out))
print("chart, 2D bound y/y0 at the same times:", ", ".join(f"{1.0:.3f}" for v in out))
print(f"to 0.99 T*: int y dt / (y0 T*) = {Iz:.4f} (exact 1.8); int y^2 dt / (y0^2 T*) = {Iz2:.4f} (exact {math.log(100):.4f})")
for dl in (1e-2, 1e-4, 1e-6):
    print(f"cut {e(dl, 0)} T* short: int y = {2 * (1 - math.sqrt(dl)):.4f} y0 T*, int y^2 = {math.log(1 / dl):.4f} y0^2 T*")
print(f"energy allows int y dt up to {r3['E'] / NU:.1f} m^3/s; this blow-up uses {e(2 * r3['y'] * Tstar)} m^3/s")
expo = 2 * K * r2["E"] ** 2 / NU ** 4
print(f"2D with walls: y <= y0 exp({e(expo)}), a number with about {e(expo / math.log(10))} digits")
prod = math.sqrt(2 * r3["E"] * r3["y"])
print(f"small-data test: |u0| |grad u0| = {prod:.4f} m^4/s^2 = {e(prod / NU ** 2)} nu^2")
print(f"mistake, squeezing wave: dE/dt gains -T = {e(-bad['T'])} m^5/s^3 = {-RHO * bad['T']:.4f} W from nothing")
assert all(abs(a - b) < 1e-6 for a, b in zip(out, exact))            # RK4 against 1/sqrt(1-s)
assert abs(Iz - 1.8) < 1e-4 and abs(Iz2 - math.log(100)) < 1e-4       # quadrature against closed form
assert abs(r3["S"] - r3["W"]) < 1e-9 * abs(r3["S"]) and r3["S"] > 1   # two roads to stretching
assert abs(r2["S"]) < 1e-12 * r2["y"] * k0 * U and abs(r3["T"]) < 1e-12 * r3["y"] * k0 * U
assert all(abs(r["p"]) < 1e-12 * r["y"] * k0 * U and abs(r["V"] + r["y"]) < 1e-12 * r["y"]
           for r in (r3, r2))                                    # pressure; int u.lap u = -y0
assert abs(r3["E"] - L ** 3 * U * U) < 1e-15 and abs(r3["y"] - L ** 3 * 4.5 * k0 * k0 * U * U) < 1e-9
assert abs(-bad["T"] - math.pi / 800) < 1e-12                           # the squeeze: pi/800 by hand
print("ALL CHECKS PASS")
