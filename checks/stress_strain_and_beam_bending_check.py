# Stress, strain and bending -- the check behind the card.  Standard library only.
# A 4 m steel joist, pinned at both ends, 2 kN at mid-span.  Sizes it against a
# sag limit and a stress limit, then reaches the sag three independent ways.
L, P, E, G = 4.0, 2000.0, 200e9, 9.80665       # m, N, Pa (steel), m/s^2
SIGMA_Y, RHO = 275e6, 7850.0                   # S275 yield stress Pa, steel kg/m^3
SAG_LIM, STRESS_LIM = L / 360, 0.6 * SIGMA_Y   # m, Pa
SECTIONS = {"80 mm I": (80, 46, 5.2, 3.8), "100 mm I": (100, 55, 5.7, 4.1),
            "120 mm I": (120, 64, 6.3, 4.4)}   # depth h, flange b x tf, web tw, in mm

def i_formula(h, b, tf, tw):                   # road 1 for I: three rectangles
    hw, d = h - 2 * tf, (h - tf) / 2           # web height; flange centre to axis
    return 2 * (b * tf**3 / 12 + b * tf * d * d) + tw * hw**3 / 12   # mm^4

def i_strips(h, b, tf, tw, dy=0.05):           # road 2 for I: add up y^2 dA, strip by strip
    total = 0.0
    for k in range(round(h / dy)):
        y = -h / 2 + (k + 0.5) * dy            # strip centre, mm from the neutral axis
        width = b if abs(y) > h / 2 - tf else tw
        total += width * dy * y * y
    return total

def strip_sums(h, b, tf, tw, s_face, dy=0.05): # stress -s_face y / c on each strip: net push (N),
    force = turn = z = 0.0                     # turning effect (N m), and the sum of |y| dA (mm^3)
    for k in range(round(h / dy)):
        y = -h / 2 + (k + 0.5) * dy            # strip centre, mm from the neutral axis
        dA = (b if abs(y) > h / 2 - tf else tw) * dy
        sig = -s_face * y / (h / 2)            # Pa
        force, turn, z = force + sig * dA * 1e-6, turn - sig * y * dA * 1e-9, z + abs(y) * dA
    return force, turn, z

def area(h, b, tf, tw): return 2 * b * tf + (h - 2 * tf) * tw          # mm^2
def moment(x): return P * min(x, L - x) / 2                            # N m, at x m
def sag_formula(EI): return P * L**3 / (48 * EI)                      # m

def sag_fd(EI, n=400, mom=moment):             # road 2: EI v'' = -M(x), v(0) = v(L) = 0
    h = L / n                                  # finite differences, Thomas algorithm
    rhs = [-h * h * mom(i * h) / EI for i in range(1, n)]
    c, d = [0.0] * (n - 1), [0.0] * (n - 1)    # sweep the tridiagonal (1, -2, 1) system
    for i in range(n - 1):
        m = -2.0 - (c[i - 1] if i else 0.0)
        c[i] = 1.0 / m
        d[i] = (rhs[i] - (d[i - 1] if i else 0.0)) / m
    v = [0.0] * (n - 1)
    for i in range(n - 2, -1, -1):
        v[i] = d[i] - c[i] * (v[i + 1] if i < n - 2 else 0.0)
    return [0.0] + v + [0.0]

def sag_energy(EI, n=400):                     # road 3: work P sag / 2 = stored energy,
    h, s = L / n, 0.0                          # the integral of M^2 / (2 EI), by Simpson
    for i in range(n + 1):
        s += (1 if i in (0, n) else (4 if i % 2 else 2)) * moment(i * h) ** 2
    return 2 * (s * h / 3) / (2 * EI) / P

def shape(EI, x):                              # closed-form sag curve, m
    x = min(x, L - x)
    return P * x * (3 * L * L - 4 * x * x) / (48 * EI)

M = P * L / 4
print(f"joist: span {L:.1f} m, pinned ends, {P:.0f} N at mid-span = {P / G:.1f} kg, E = {E / 1e9:.0f} GPa")
print(f"limits: sag L/360 = {SAG_LIM * 1e3:.2f} mm, stress 0.6 x {SIGMA_Y / 1e6:.0f} = {STRESS_LIM / 1e6:.0f} MPa")
print(f"largest bending moment PL/4 = {M:.0f} N m")
print(f"needed: I >= {P * L**3 / (48 * E * SAG_LIM) * 1e8:.2f} cm^4 (sag), W >= {M / STRESS_LIM * 1e6:.2f} cm^3 (stress)")
print(f"{'section':<10}{'I cm^4':>9}{'strips':>9}{'W cm^3':>8}{'sag mm':>8}{'MPa':>8}{'kg/m':>7}  verdict")
rows = {}
for name, dims in SECTIONS.items():
    I1, I2 = i_formula(*dims), i_strips(*dims)
    assert abs(I1 - I2) / I1 < 1e-6            # two roads to I agree
    I, W = I1 * 1e-12, I1 / (dims[0] / 2) * 1e-9                  # m^4, m^3
    sag, stress, kg = sag_formula(E * I), M / W, area(*dims) * 1e-6 * RHO
    ok_sag, ok_str = sag <= SAG_LIM, stress <= STRESS_LIM
    verdict = "passes both" if ok_sag and ok_str else ("fails sag" if ok_str else "fails stress")
    rows[name] = (I, W, sag, stress, kg, verdict)
    print(f"{name:<10}{I1 / 1e4:9.2f}{I2 / 1e4:9.2f}{W * 1e6:8.2f}{sag * 1e3:8.2f}{stress / 1e6:8.2f}{kg:7.2f}  {verdict}")
chosen = min((r[4], n) for n, r in rows.items() if r[5] == "passes both")[1]
I, W, sag, stress, kg, _ = rows[chosen]
EI, v, h, b, tf, tw = E * I, sag_fd(E * I), *SECTIONS[chosen]
print(f"lightest section passing both: {chosen}, EI = {EI:.0f} N m^2")
I_web = tw * (h - 2 * tf)**3 / 12
print(f"its I, cm^4: flanges {(I * 1e12 - I_web) / 1e4:.2f} + web {I_web / 1e4:.2f}")
print(f"sag, road 1 formula PL^3/48EI:  {sag * 1e3:.4f} mm")
print(f"sag, road 2 finite differences: {v[200] * 1e3:.4f} mm")
print(f"sag, road 3 energy integral:    {sag_energy(EI) * 1e3:.4f} mm")
assert abs(v[200] - sag) / sag < 1e-4 and abs(sag_energy(EI) - sag) / sag < 1e-9
assert rows["80 mm I"][5] == "fails sag" and chosen == "100 mm I"
assert max(abs(v[50 * k] - shape(EI, 0.5 * k)) for k in range(9)) < 1e-6
strain, slope = stress / E, P * L * L / (16 * EI)
print(f"outer-face stress {stress / 1e6:.2f} MPa, strain {strain:.6f} = {strain * 1e3:.3f} mm per m")
force, turn, z_strips = strip_sums(h, b, tf, tw, stress)
print(f"strips at that stress: net push {abs(force):.3f} N, turning effect {turn:.2f} N m")
assert abs(force) < 1e-6 * P and abs(turn - M) / M < 1e-6       # the stresses add up to the moment
print(f"end slope PL^2/16EI = {slope:.5f} rad = {slope * 180 / 3.141592653589793:.3f} deg")
w_self = kg * G                                # N per m along the span
extra = 5 * w_self * L**4 / (384 * EI)
extra_fd = sag_fd(EI, mom=lambda x: w_self * x * (L - x) / 2)[200]   # same solver, spread load
print(f"self-weight {w_self:.2f} N/m adds {extra * 1e3:.2f} mm (finite differences"
      f" {extra_fd * 1e3:.2f}): total {(sag + extra) * 1e3:.2f} mm")
assert abs(extra_fd - extra) / extra < 1e-4
print("chart, x m       " + "".join(f"{0.5 * k:7.1f}" for k in range(9)))
for name in ("80 mm I", "100 mm I"):
    print(f"chart, {name:<10}" + "".join(f"{shape(E * rows[name][0], 0.5 * k) * 1e3:7.2f}" for k in range(9)))
I_weak = (2 * tf * b**3 / 12 + (h - 2 * tf) * tw**3 / 12) * 1e-12    # turned on its side
sag_weak, sag_clamp = sag_formula(E * I_weak), P * L**3 / (192 * EI)
print(f"wrong: sized by stress only, 80 mm I sags {rows['80 mm I'][2] * 1e3:.2f} mm, limit {SAG_LIM * 1e3:.2f} mm")
print(f"wrong: section on its side, I = {I_weak * 1e8:.2f} cm^4, sag {sag_weak * 1e3:.2f} mm")
print(f"wrong: ends taken as clamped, PL^3/192EI = {sag_clamp * 1e3:.2f} mm")
print(f"wrong: 2 kN spread evenly, sag 5PL^3/384EI = {5 * P * L**3 / (384 * EI) * 1e3:.2f} mm,"
      f" stress {P * L / 8 / W / 1e6:.2f} MPa")
assert sag_weak > 5 * SAG_LIM > sag
P_yield = 4 * W * SIGMA_Y / L
print(f"outside the model: yield at P = {P_yield:.0f} N; at 12000 N the formula says {12000 * L / 4 / W / 1e6:.0f} MPa")
z_formula = b * tf * (h - tf) + tw * (h - 2 * tf)**2 / 4                # mm^3, whole section yielded
P_fold = 4 * z_formula * 1e-9 * SIGMA_Y / L
print(f"outside the model: section yielded through, Z = {z_formula / 1e3:.2f} cm^3"
      f" (strips {z_strips / 1e3:.2f}), folds at P = {P_fold:.0f} N")
assert abs(z_strips - z_formula) / z_formula < 1e-6 and P_yield < P_fold < 12000
print(f"try: P = 3000 N sags {sag * 1.5 * 1e3:.2f} mm; L = 5 m sags {P * 5**3 / (48 * EI) * 1e3:.2f} mm"
      f" against {5 / 360 * 1e3:.2f} mm; aluminium, E = 70 GPa, sags {sag_formula(70e9 * I) * 1e3:.2f} mm")
print("figure, elevation 80 px/m, sag 5 px/mm, y px below beam at x = 0.5 m steps:",
      " ".join(f"{shape(EI, 0.5 * k) * 5e3:.1f}" for k in range(9)))
print(f"figure, section 1 px/mm, {h} x {b} mm, flange {tf} mm, web {tw} mm;"
      f" stress 0.5 px/MPa: {stress / 1e6 * 0.5:.1f} px")
print("ALL CHECKS PASS")
