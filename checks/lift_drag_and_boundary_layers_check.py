# Lift, drag and boundary layers -- the check behind the card.  Standard library only.
# A model wing (a Joukowski aerofoil, chord 0.30 m) in a wind tunnel at 40 m/s.
# Lift two ways: circulation (Kutta-Joukowski) and summed surface pressure.  Drag and
# separation from the boundary layer: Thwaites (laminar) to the suction peak, then Head's
# turbulent method.  Stall from Kirchhoff's rule: lift shrinks as the layer lets go.
from math import pi, sin, cos, asin, sqrt, degrees, radians
import cmath

R, M_AIR, P0, T0, MU = 8.314462618, 0.0289644, 101325.0, 293.15, 1.82e-5
RHO = P0 * M_AIR / (R * T0); NU = MU / RHO          # air at 20 C, 1 atm
U, C, SPAN, N = 40.0, 0.30, 0.80, 3000              # tunnel speed, chord, span, steps

def wing(ex, ey):                                   # circle centre (-ex, ey) through z = 1
    m = complex(-ex, ey); a = abs(1 - m); beta = asin(ey / a)
    pts = [m + a * cmath.exp(2j * pi * k / 4000) for k in range(4000)]
    zs = [p + 1 / p for p in pts]; xle = min(z.real for z in zs); ch = 2.0 - xle
    up, lo = [-9.0] * 200, [9.0] * 200              # thickness and camber by x-bins
    for z in zs:
        i = min(199, int((z.real - xle) / ch * 200)); up[i] = max(up[i], z.imag); lo[i] = min(lo[i], z.imag)
    t = max(u - l for u, l in zip(up, lo)) / ch; f = max((u + l) / 2 for u, l in zip(up, lo)) / ch
    return dict(m=m, a=a, beta=beta, ch=ch, t=t, f=f, k=8 * pi * a / ch)

def pos(w, th): p = w['m'] + w['a'] * cmath.exp(1j * th); return p + 1 / p
def speed(w, th, al):                               # speed / U on the aerofoil at circle angle th
    p = w['m'] + w['a'] * cmath.exp(1j * th)
    return abs(-2 * sin(th - al) - 2 * sin(al + w['beta'])) / abs(1 - 1 / p ** 2)

def cl_by_pressure(w, al, n=20000):                 # road 2: add up -Cp n ds round the surface
    fl = 0.0; z0 = complex(2, 0)
    for k in range(1, n + 1):
        th = -w['beta'] + 2 * pi * k / n; z1 = pos(w, th) if k < n else complex(2, 0)
        q = speed(w, th - pi / n, al); dz = z1 - z0; cp = 1 - q * q
        fl += -cp * (dz.imag * -sin(al) + -dz.real * cos(al)); z0 = z1
    return fl / w['ch']

def h_of(h1): return 1.1 + 0.86 * (h1 - 3.3) ** -0.777 if h1 >= 5.3 else 0.6778 + 1.1536 * (h1 - 3.3) ** -0.326
def h1_of(h): return 3.3 + 0.8234 * (h - 1.1) ** -1.287 if h <= 1.6 else 3.3 + 1.5501 * (h - 0.6778) ** -3.064

def thwaites(s, ue, k0):                            # laminar momentum thickness at s[k0]
    I = sum(0.5 * (ue[k] ** 5 + ue[k - 1] ** 5) * (s[k] - s[k - 1]) for k in range(1, k0 + 1))
    return sqrt(0.45 * NU * I / ue[k0] ** 6)

def march(s, ue, hsep):                             # Thwaites to the suction peak, then Head
    k0 = max(range(len(ue)), key=lambda k: ue[k])
    th = thwaites(s, ue, k0); h = 1.4; y = ue[k0] * th * h1_of(h); ksep = None
    for k in range(k0, len(s) - 1):
        ds = s[k + 1] - s[k]; due = 0.0 if ksep else (ue[k + 1] - ue[k]) / ds
        cf = 0.246 * 10 ** (-0.678 * h) * (ue[k] * th / NU) ** -0.268
        h1 = y / (ue[k] * th)
        th += ds * (cf / 2 - (h + 2) * th / ue[k] * due); y += ds * ue[k] * 0.0306 * (h1 - 3) ** -0.6169
        if ksep: ue[k + 1] = ue[k]                  # past separation: pressure stays constant
        h1 = y / (ue[k + 1] * th); h = h_of(h1) if h1 > 3.3 + 1e-9 else 3.5
        if ksep is None and h > hsep: ksep = k + 1
        h = min(h, hsep)
    return ksep, 2 * th / C * (ue[-1] / U) ** ((h + 5) / 2), y / ue[-1] + h * th   # last: thickness at the back edge

def section(w, adeg, hsep=2.0, n=N):                # one angle: lift, separation point, drag
    al = radians(adeg); ths = pi + 2 * al + w['beta']; sc = C / w['ch']; out = []
    for tte in (-w['beta'], 2 * pi - w['beta']):    # upper surface, then lower
        thv = [ths + (tte - ths) * k / n for k in range(n + 1)]
        ue = [0.0] + [U * speed(w, t, al) for t in thv[1:n]]; ue.append(ue[-1])
        zz = [pos(w, t) for t in thv[:n]] + [complex(2, 0)]
        s = [0.0]
        for k in range(1, n + 1): s.append(s[-1] + abs(zz[k] - zz[k - 1]) * sc)
        ks, cd, dl = march(s, ue, hsep)
        out.append(((zz[ks].real - (2 - w['ch'])) / w['ch'] if ks else 1.0, cd, zz[ks].imag / w['ch'] if ks else 0.0, dl))
    fs, ae = out[0][0], al + w['beta']; F = w['k'] * sin(ae); g = ((1 + sqrt(fs)) / 2) ** 2
    cl = F * (g * cos(ae) ** 2 + sqrt(fs) * sin(ae) ** 2)        # Kirchhoff: normal x g, suction x sqrt f
    cdp = F * sin(ae) * cos(ae) * (g - sqrt(fs))
    return F, fs, cl, out[0][1] + out[1][1] + cdp, cdp, out[0]   # last: upper x/c, C_D, y/c, thickness

def stall(w, hsep=2.0, n=N):                        # scan, then golden-section on the peak
    best = max(range(0, 26), key=lambda d: section(w, d, hsep, n)[2]); lo, hi = best - 1.0, best + 1.0
    g = (sqrt(5) - 1) / 2
    for _ in range(25):
        x1, x2 = hi - g * (hi - lo), lo + g * (hi - lo)
        if section(w, x1, hsep, n)[2] > section(w, x2, hsep, n)[2]: hi = x2
        else: lo = x1
    a = (lo + hi) / 2; return a, section(w, a, hsep, n)[2]

def p(label, v, fmt): print(f"{label:<46}{v:{fmt}}")
w = wing(0.10, 0.06); qd = 0.5 * RHO * U ** 2; re = U * C / NU; al = radians(8.0)
p("air density, kg/m^3", RHO, ".4f"); p("kinematic viscosity, mm^2/s", NU * 1e6, ".4f")
p("Reynolds number U c / nu", re, ",.0f"); p("Mach number U / sqrt(1.4 R T / M)", U / sqrt(1.4 * R * T0 / M_AIR), ".4f")
p("dynamic pressure 1/2 rho U^2, Pa", qd, ".2f"); p("wing area c x span, m^2", C * SPAN, ".3f")
p("thickness, fraction of chord", w['t'], ".4f"); p("camber, fraction of chord", w['f'], ".4f")
p("zero-lift angle, deg", -degrees(w['beta']), ".4f"); p("zero-lift angle, thin aerofoil -2 f/c, deg", -degrees(2 * w['f']), ".4f")
p("lift slope k, per rad (thin aerofoil 2 pi)", w['k'], ".4f")
F8, f8, cl8, cd8, cdp8, up8 = section(w, 8.0); clp = cl_by_pressure(w, al)
gam = 4 * pi * U * w['a'] * C / w['ch'] * sin(al + w['beta'])
p("8 deg: circulation Gamma, m^2/s", gam, ".4f"); p("8 deg: lift per metre rho U Gamma, N/m", RHO * U * gam, ".3f")
p("8 deg: C_L by circulation, no layer", F8, ".4f"); p("8 deg: C_L by summed pressure, no layer", clp, ".4f")
p("8 deg: C_L slope 2 pi, exact a0", 2 * pi * (al + w['beta']), ".4f")
ae = al + w['beta']; print(f"{'8 deg: a - a0 deg, sin, g, sqrt f':<46}{degrees(ae):.4f}  {sin(ae):.4f}  {((1 + sqrt(f8)) / 2) ** 2:.4f}  {sqrt(f8):.4f}")
p("8 deg: separation point x/c, upper", f8, ".4f"); p("8 deg: C_L with the layer", cl8, ".4f")
p("8 deg: C_D, wake plus separation", cd8, ".5f"); p("8 deg: of which separation pressure", cdp8, ".5f")
p("8 deg: upper layer thickness, back edge, mm", 1000 * up8[3], ".1f")
L8, D8 = cl8 * qd * C * SPAN, cd8 * qd * C * SPAN
print(f"{'8 deg: lift N, drag N, lift / drag':<46}{L8:.2f}  {D8:.3f}  {L8 / D8:.2f}")
sa, clm = stall(w); s18, c18 = stall(w, 1.8); s24, c24 = stall(w, 2.4)
print(f"{'stall deg, margin deg, maximum C_L (H = 2.0)':<46}{sa:.2f}  {sa - 8.0:.2f}  {clm:.4f}")
print(f"{'H = 1.8: stall angle deg, maximum C_L':<46}{s18:.2f}  {c18:.4f}")
print(f"{'H = 2.4: stall angle deg, maximum C_L':<46}{s24:.2f}  {c24:.4f}")
print("angle  C_L no layer  sep x/c   C_L      C_D"); rows = []
for d in range(0, 21, 2):
    rows.append(section(w, d)); F, fs, cl, cd = rows[-1][:4]; print(f"{d:>5} {F:>10.4f} {fs:>10.3f} {cl:>8.4f} {cd:>8.5f}")
plate = [C * k / N for k in range(N + 1)]           # road 4: a flat plate, turbulent from the front edge
fp = march(plate, [0.0] + [U] * N, 2.0)[1]
print(f"{'plate C_f one side: march, 0.074 Re^-0.2':<46}{fp:.5f}  {0.074 * re ** -0.2:.5f}")
th_lam = thwaites(plate, [U] * (N + 1), N)          # road 5: Thwaites on a laminar plate, against Blasius
print(f"{'laminar plate theta mm: Thwaites, Blasius':<46}{1000 * th_lam:.4f}  {664 * C / sqrt(re):.4f}")
F8f, f8f, cl8f, cd8f = section(w, 8.0, 2.0, 4 * N)[:4]; saf = stall(w, 2.0, 4 * N)[0]   # road 6: 4 x the steps
print(f"{'4 x steps: 8 deg x/c, C_D, lift N; stall deg':<46}{f8f:.4f}  {cd8f:.5f}  {cl8f * qd * C * SPAN:.2f}  {saf:.2f}")
p("wrong: degrees in 2 pi (a - a0)", 2 * pi * (8.0 + degrees(w['beta'])), ".2f")
p("wrong: camber left out, k sin a", w['k'] * sin(al), ".4f")
p("wrong: straight line at 20 deg", rows[-1][0], ".4f")
p("wrong: laminar friction, both sides", 2 * 1.328 / sqrt(re), ".5f")
p("wrong: no 1/2 in dynamic pressure, lift N", 2 * L8, ".2f")
sx = lambda f: 40 + 480 * f                          # figure: 480 px of chord
sy = lambda y: 130 - 480 * y                         # chord line at y = 130 px, up is smaller y
print(f"figure, leading edge x {sx(0):.1f}, trailing edge x {sx(1):.1f}, separation at 8 deg ({sx(f8):.1f}, {sy(up8[2]):.1f}),"
      f" at 14 deg ({sx(rows[7][1]):.1f}, {sy(rows[7][5][2]):.1f})")
U = 20.0; p("try: tunnel at 20 m/s, stall angle deg", stall(w)[0], ".2f"); U = 40.0
wt = wing(0.06, 0.06); print(f"{'try: thinner wing, thickness, stall angle deg':<46}{wt['t']:.4f}  {stall(wt)[0]:.2f}")
p("try: no camber, stall angle deg", stall(wing(0.10, 0.0))[0], ".2f")
assert abs(F8 - clp) < 1e-3                         # circulation and pressure agree
assert abs(fp - 0.074 * re ** -0.2) < 0.15 * 0.074 * re ** -0.2   # the march lands within the flat-plate fits' spread
assert abs(w['beta'] - 2 * w['f']) < 0.01 * w['beta']   # camber read off the shape predicts the zero-lift angle
assert 13.0 < sa < 17.0 and s18 < sa < s24         # stall near fifteen degrees, later if separation is judged later
assert all(abs(h_of(h1_of(h)) - h) < 0.005 for h in (1.3, 1.5, 2.0, 2.4))   # Head's two fits invert each other
assert all(a[1] >= b[1] for a, b in zip(rows, rows[1:]))   # separation creeps forward as angle grows
assert 2 * fp < rows[0][3] < 1.3 * 2 * fp           # profile drag sits a little above flat-plate friction
assert abs(th_lam / (0.664 * C / sqrt(re)) - 1) < 0.02   # Thwaites within 2% of the exact Blasius plate
assert abs(f8f - f8) < 0.002 and abs(cd8f / cd8 - 1) < 0.01 and abs(saf - sa) < 0.2   # step size settled
print("ALL CHECKS PASS")
