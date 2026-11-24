# Transmission lines and reflections -- the check behind the card.  Standard library only.
# 1.5 m of 50-ohm coax (250 nH/m, 100 pF/m) from a radio to a 75-ohm antenna, 100 MHz.
# Road 1: closed forms.  Road 2: step the telegrapher's equations in time (leapfrog).
# Road 3: Kirchhoff's laws on a ladder of 3000 tiny coils and capacitors, in phasors.
from math import sqrt, pi, cos, sin, exp, log, log10, tan

L, C = 250e-9, 100e-12          # H/m and F/m, per metre of line (typical RG-58 values)
ELL, F, ZL, RS, VS = 1.5, 100e6, 75.0, 50.0, 1.0   # m, Hz, ohm, ohm (radio), V peak
MU0, EPS0, C0 = 1.25663706127e-6, 8.8541878188e-12, 299792458.0   # CODATA 2022

def zin(zl, ell, f, vel=None):  # input impedance of a lossless line ending in zl
    t = tan(2 * pi * f * ell / (vel or v))
    return z0 * (zl + 1j * z0 * t) / (z0 + 1j * zl * t)
def fz(z):                      # print an impedance; no minus sign on a zero
    if abs(z) > 1e6: return "open circuit"
    s = f"{z.real:.2f} {'-' if z.imag < -0.005 else '+'} j{abs(z.imag):.2f} ohm"
    return s.replace("-0.00", "0.00")

# ---- Road 1: closed forms
z0, v = sqrt(L / C), 1 / sqrt(L * C)
lam, gam = v / F, (ZL - z0) / (ZL + z0)
swr = (1 + abs(gam)) / (1 - abs(gam))
print(f"Z0 = sqrt(L/C) = {z0:.2f} ohm, v = 1/sqrt(LC) = {v / 1e8:.4f} x 10^8 m/s = {v / C0:.4f} of c")
print(f"wavelength in the cable at 100 MHz {lam:.4f} m, beta {2 * pi / lam:.4f} rad/m, lead = {ELL / lam:.2f} wavelengths, delay {ELL / v * 1e9:.2f} ns")
lnba = 2 * pi * z0 * sqrt(2.25 * EPS0 / MU0)    # polyethylene coax, Z0 = 50 ohm
print(f"coax radii ratio b/a = {exp(lnba):.3f}: L = {MU0 / (2 * pi) * lnba * 1e9:.1f} nH/m, "
      f"C = {2 * pi * 2.25 * EPS0 / lnba * 1e12:.2f} pF/m")
pinc = (VS / 2) ** 2 / (2 * z0)
print(f"Gamma = ({ZL:.0f} - 50)/({ZL:.0f} + 50) = {gam:.4f}, SWR = {1 + gam:.1f}/{1 - gam:.1f} = {swr:.4f}")
print(f"power: incident {pinc * 1e3:.2f} mW, reflected {gam ** 2 * 100:.2f}% = {gam ** 2 * pinc * 1e3:.2f} mW, "
      f"delivered {(1 - gam ** 2) * pinc * 1e3:.2f} mW")
print(f"return loss {-20 * log10(abs(gam)) if gam else float('inf'):.2f} dB, mismatch loss {-10 * log10(1 - gam ** 2):.3f} dB")
print(f"antenna volts: incident {VS / 2:.2f} + reflected {gam * VS / 2:.2f} = {(1 + gam) * VS / 2:.2f} V; "
      f"check 0.6^2/(2*75) = {((1 + gam) * VS / 2) ** 2 / (2 * ZL) * 1e3:.2f} mW")
zi = zin(ZL, ELL, F)
vin = abs(VS * zi / (zi + RS))
print(f"Zin at 1.5 m = {fz(zi)} (Z0^2/ZL = {z0 ** 2 / ZL:.2f}), radio end {vin:.2f} V")
for name, zl in [("matched 50", 50.0), ("short", 0.0), ("open", 1e12)]:
    g = (zl - z0) / (zl + z0)
    s = "infinite" if abs(abs(g) - 1) < 1e-9 else f"{(1 + abs(g)) / (1 - abs(g)):.2f}"
    print(f"load {name:10s}: Gamma = {g:+.2f}, SWR {s}, Zin at 1.5 m = {fz(zin(zl, ELL, F))}")
R = 0.3                         # ohm/m, an illustrative copper loss at 100 MHz
z0c = ((R + 2j * pi * F * L) / (2j * pi * F * C)) ** 0.5
gl = ((R + 2j * pi * F * L) * (2j * pi * F * C)) ** 0.5
print(f"omega L = {2 * pi * F * L:.2f} ohm/m; at 50 Hz {2 * pi * 50 * L * 1e6:.2f} micro-ohm/m")
print(f"with R = 0.3 ohm/m: Z0 = {fz(z0c)}, loss {gl.real * 20 / log(10):.4f} dB/m")
for name, f in [("50 Hz", 50.0), ("1 MHz", 1e6)]:
    print(f"at {name}: wavelength {v / f:.0f} m, lead = 1/{v / f / ELL:.0f} of it, Zin {fz(zin(ZL, ELL, f))}")

# ---- Road 2: leapfrog on the telegrapher's equations, 1 cm cells, dt = dz/v
DZ = 0.01
N, DT = round(ELL / DZ), DZ / v
def run(zl, drive, steps, keep):
    V, I, a, out = [0.0] * (N + 1), [0.0] * N, C * DZ / (2 * DT), []
    for n in range(steps):
        for k in range(N): I[k] -= DT / (L * DZ) * (V[k + 1] - V[k])
        vs, g = drive((n + 0.5) * DT), 1 / (2 * RS)        # source node: radio, 50 ohm
        V[0] = ((a - g) * V[0] + vs / RS - I[0]) / (a + g)
        for k in range(1, N): V[k] -= DT / (C * DZ) * (I[k] - I[k - 1])
        g = 1 / (2 * zl) if zl > 0 else 1e30                 # load node: antenna
        V[N] = ((a - g) * V[N] + I[N - 1]) / (a + g)
        out.append((n * DT + DT, vs, [V[k] for k in keep]))
    return out
pulse = lambda t: exp(-((t - 3e-9) / 0.5e-9) ** 2)        # 1 V bump leaving the radio at 3 ns
sim_g, lab = {}, f"{ZL:.0f} ohm"
for name, zl in [(lab, ZL), ("matched", 50.0), ("short", 0.0), ("open", 1e12)]:
    tr = run(zl, pulse, 420, (0, N // 2, N))
    pk = lambda j, t0, t1: max(((r[2][j], r[0] * 1e9 - 3) for r in tr if t0 < r[0] * 1e9 - 3 < t1),
                               key=lambda p: abs(p[0]))
    sim_g[name] = pk(1, 6, 14)[0] / pk(1, 0, 6)[0]
    print(f"simulated pulse, {name:7s}: back/out at 0.75 m = {sim_g[name]:+.4f}")
    if name == lab:
        for j, t0, t1 in [(0, -1, 2), (1, 2, 6), (2, 6, 9), (1, 9, 13), (0, 13, 17)]:
            h, t = pk(j, t0, t1)
            print(f"  pulse peak {h:.3f} V at {(0, 0.75, 1.5)[j]:.2f} m from the radio, t = {t:.2f} ns")
assert abs(sim_g[lab] - gam) < 1e-4
assert abs(sim_g["short"] + 1) < 1e-4 and abs(sim_g["open"] - 1) < 1e-4
per = round(1 / (F * DT))
sine = lambda t: VS * cos(2 * pi * F * t) * min(1.0, t / 20e-9)   # ramped on over 20 ns
tr = run(ZL, sine, 1200, range(N + 1))[-per:]
env = [max(abs(r[2][k]) for r in tr) for k in range(N + 1)]
print(f"simulated sine: max {max(env):.4f} V, min {min(env):.4f} V, SWR {max(env) / min(env):.4f}")
ph = lambda xs: sum(x * complex(cos(2 * pi * F * r[0]), -sin(2 * pi * F * r[0])) for x, r in zip(xs, tr))
zsim = ph([r[2][0] for r in tr]) / ph([(VS * cos(2 * pi * F * r[0]) - r[2][0]) / RS for r in tr])
print(f"simulated Zin = {fz(zsim)}")
assert abs(max(env) / min(env) - swr) < 1e-3
assert abs(zsim - zi) < 0.05
ds = [i / 10 for i in range(16)]   # distance back from the antenna
print("chart, distance (m)  " + " ".join(f"{d:4.1f}" for d in ds))
for name, g in [(lab, gam), ("open  ", 1.0)]:
    print(f"chart, {name} |V| (V) " + " ".join(f"{VS / 2 * abs(1 + g * complex(cos(4 * pi * d / lam), -sin(4 * pi * d / lam))):4.2f}" for d in ds))
assert max(abs(env[N - round(d / DZ)] - VS / 2 * abs(1 + gam * complex(cos(4 * pi * d / lam), -sin(4 * pi * d / lam)))) for d in ds) < 1e-3

# ---- Road 3: Kirchhoff on a ladder of tiny series coils and shunt capacitors
def ladder(n, zl):
    z, w, dz = complex(zl), 2 * pi * F, ELL / n
    for _ in range(n):
        z = 1j * w * L * dz / 2 + 1 / (1j * w * C * dz + 1 / (z + 1j * w * L * dz / 2))
    return z
for n in (1, 10, 100):
    print(f"ladder of {n:3d} sections ({ELL / n * 100:5.1f} cm each): Zin = {fz(ladder(n, ZL))}")
zlad = ladder(3000, ZL)
print(f"ladder of 3000 sections: Zin = {fz(zlad)}")
assert abs(zlad - zi) < 0.01

# ---- What breaks, and try changing
print(f"wrong: lead as a plain wire: Zin = {fz(complex(ZL))}, radio end {VS * ZL / (ZL + RS):.2f} V")
print(f"wrong: Gamma upside down (50 - 75)/(50 + 75) = {-gam:.2f}: antenna {(1 - gam) * VS / 2:.2f} V, simulated {env[N]:.2f} V")
print(f"wrong: |Gamma| read as power: {abs(gam) * 100:.0f}% instead of {gam ** 2 * 100:.0f}%")
print(f"wrong: vacuum wavelength {C0 / F:.4f} m, so 1.5 m looks like a half wave: Zin {fz(zin(ZL, ELL, F, C0))}")
for zl in (100.0,):
    g = (zl - z0) / (zl + z0)
    print(f"try: ZL = 100 ohm: Gamma {g:.4f}, SWR {(1 + g) / (1 - g):.2f}, reflected {g * g * 100:.2f}%")
print(f"try: lead 1.0 m: Zin = {fz(zin(ZL, 1.0, F))}; lead 1.25 m: Zin = {fz(zin(ZL, 1.25, F))}")
print(f"try: F = 88 MHz: Zin = {fz(zin(ZL, ELL, 88e6))}")
print("ALL CHECKS PASS")
