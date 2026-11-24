# Compressible flow -- the check behind the card.  Standard library only.  A Mach 2 wind-tunnel nozzle,
# 20 C chamber air, 100 mm x 100 mm test section, room at 101.325 kPa.  Roads: closed forms; Simpson on
# dA/A; a search for the biggest mass flux; the shock from raw conservation laws; the entropy rise.
from math import sqrt, log, exp, cos, pi

G = 1.4                              # ratio of heat capacities, air
R = 8314.32 / 28.9644                # J/(kg K): US Standard Atmosphere 1976, R* / M0
CP = G * R / (G - 1)                 # J/(kg K)
T0, P0, PB = 293.15, 300e3, 101325.0 # chamber K, chamber Pa, room Pa
W, HT, HE, HIN = 0.100, 0.100 / 1.6875, 0.100, 0.180  # span, throat, exit, inlet heights, m

def out(label, v, d, unit=""):
    print(f"{label:<44}{v:>11.{d}f} {unit}")

def tt(m, g=G): return 1 + (g - 1) / 2 * m * m                 # T0/T
def pr(m, g=G): return tt(m, g) ** (-g / (g - 1))               # p/p0
def area(m, g=G): return (2 / (g + 1) * tt(m, g)) ** ((g + 1) / (2 * (g - 1))) / m  # A/A*

def bisect(f, lo, hi, n=200):        # f(lo) and f(hi) of opposite sign
    flo = f(lo)
    for _ in range(n):
        mid = (lo + hi) / 2
        if (f(mid) > 0) == (flo > 0): lo, flo = mid, f(mid)
        else: hi = mid
    return (lo + hi) / 2

def mach(ar, sup, g=G): return bisect(lambda m: area(m, g) - ar, *((1.0, 50.0) if sup else (1e-9, 1.0)))

def shock(m, g=G):                   # closed forms: M2, p2/p1, rho2/rho1, T2/T1, p02/p01
    m2 = sqrt(tt(m, g) / (g * m * m - (g - 1) / 2))
    pp = 1 + 2 * g / (g + 1) * (m * m - 1)
    rr = (g + 1) * m * m / ((g - 1) * m * m + 2)
    return m2, pp, rr, pp / rr, pp * (tt(m2, g) / tt(m, g)) ** (g / (g - 1))

def simpson(f, a, b, n=2000):
    h = (b - a) / n; return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def height(x):                       # nozzle wall, x in m: converge 0-80 mm, diverge 80-280 mm
    if x <= 0.08: return HT + (HIN - HT) * (1 + cos(pi * x / 0.08)) / 2
    return HT + (HE - HT) * (1 - cos(pi * (min(x, 0.28) - 0.08) / 0.2)) / 2
def shock_place(p0):                 # area ratio where the shock stands so the exit meets the room
    def exit_gap(a): r = shock(mach(a, True))[4]; return r * p0 * pr(mach(1.6875 * r, False)) - PB
    a = bisect(exit_gap, 1.0 + 1e-9, 1.6875)
    return a, bisect(lambda x: height(x) / HT - a, 0.08, 0.28)

# ---- the nozzle at its design Mach 2 ----
AR = area(2.0)
ar_int = exp(simpson(lambda m: (m * m - 1) / (m * tt(m)), 1.0, 2.0))  # road 2: integrate dA/A
assert abs(AR - 0.5 * 1.5 ** 3) < 1e-12 and abs(ar_int - AR) < 1e-9
T1, p1 = T0 / tt(2.0), P0 * pr(2.0)
a1 = sqrt(G * R * T1); u1 = 2.0 * a1; astar = sqrt(G * R * T0 / tt(1.0))
for lab, v, d, u in [("gas constant of air", R, 2, "J/(kg K)"), ("area ratio A/A* at Mach 2", AR, 4, ""),
                     ("area ratio, Simpson on (M^2-1)/(M(1+0.2M^2))", ar_int, 4, ""),
                     ("throat area, 100 mm span", HT * W * 1e4, 2, "cm^2"),
                     ("T0/T at Mach 2", tt(2.0), 4, ""), ("p0/p at Mach 2", 1 / pr(2.0), 4, ""),
                     ("test section: static temperature", T1, 2, "K"), ("test section: static temperature", T1 - 273.15, 2, "C"),
                     ("test section: static pressure", p1 / 1e3, 2, "kPa"), ("test section: speed of sound", a1, 1, "m/s"),
                     ("test section: air speed", u1, 1, "m/s"), ("throat: air speed = sound speed", astar, 1, "m/s")]:
    out(lab, v, d, u)

# ---- choking: the formula against a golden-section search over throat pressure ----
mdot = HT * W * P0 * sqrt(G / (R * T0)) * (2 / (G + 1)) ** ((G + 1) / (2 * (G - 1)))
def flux(p):                         # energy equation + isentropic law only, no Mach number
    t = T0 * (p / P0) ** ((G - 1) / G); return p / (R * t) * sqrt(2 * CP * (T0 - t))
lo, hi = 0.01 * P0, 0.99 * P0        # golden-section search for the biggest flux
for _ in range(200):
    c, d = hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)
    lo, hi = (lo, d) if flux(c) > flux(d) else (c, hi)
pst = (lo + hi) / 2; tst = T0 * (pst / P0) ** ((G - 1) / G)
assert abs(flux(pst) * HT * W - mdot) < 1e-6 * mdot and abs(pst / P0 - pr(1.0)) < 1e-6 and abs(sqrt(2 * CP * (T0 - tst)) / sqrt(G * R * tst) - 1) < 1e-5
for lab, v, d, u in [("mass flow, choked formula", mdot, 3, "kg/s"), ("mass flow, search for biggest flux", flux(pst) * HT * W, 3, "kg/s"),
                     ("pressure at the peak, p*/p0", pst / P0, 4, ""), ("Mach number at the peak", sqrt(2 * CP * (T0 - tst) / (G * R * tst)), 4, "")]:
    out(lab, v, d, u)

# ---- the normal shock at Mach 2: closed form, raw conservation laws, entropy ----
m2, pp, rr, tr, keep = shock(2.0)
rho1 = p1 / (R * T1); J = rho1 * u1; H = CP * T1 + u1 * u1 / 2
def energy_gap(u):                   # mass and momentum fix p2 and rho2 for a trial u2
    p2 = p1 + J * (u1 - u); return G / (G - 1) * p2 * u / J + u * u / 2 - H
u2 = bisect(energy_gap, 1e-6, 0.999 * u1)
p2 = p1 + J * (u1 - u2); T2 = p2 * u2 / (J * R); M2c = u2 / sqrt(G * R * T2)
keep_c = p2 * tt(M2c) ** (G / (G - 1)) / P0
ds = CP * log(T2 / T1) - R * log(p2 / p1)
assert abs(M2c - m2) < 1e-9 and abs(p2 / p1 - pp) < 1e-9 and abs(keep_c - keep) < 1e-9
assert abs(exp(-ds / R) - keep) < 1e-9 and abs(u1 * u2 - astar ** 2) < 1e-6 * u1 * u2  # Prandtl: u1 u2 = a*^2
for lab, v, d, u in [("shock: Mach after, formula", m2, 4, ""), ("shock: Mach after, conservation", M2c, 4, ""),
                     ("shock: p2/p1", pp, 4, ""), ("shock: rho2/rho1", rr, 4, ""), ("shock: T2/T1", tr, 4, ""),
                     ("shock: stagnation pressure kept, formula", 100 * keep, 2, "%"),
                     ("shock: kept, conservation", 100 * keep_c, 2, "%"), ("shock: kept, exp(-ds/R)", 100 * exp(-ds / R), 2, "%"),
                     ("shock: entropy rise", ds, 2, "J/(kg K)"), ("after shock: pressure", p2 / 1e3, 2, "kPa"),
                     ("after shock: temperature", T2, 2, "K"), ("after shock: speed", u2, 1, "m/s"),
                     ("diffuser second throat, A*/kept", HT * W * 1e4 / keep, 2, "cm^2"),
                     ("lowest p0 to start, diffuser after shock", PB / keep / 1e3, 2, "kPa")]:
    out(lab, v, d, u)

# ---- start-up: the chamber pressure climbs and the shock walks down the nozzle ----
msub = mach(AR, False); p0c1, p0c2, p0d = PB / pr(msub), PB / (pr(2.0) * pp), PB / pr(2.0)
assert 0 < p0c1 < 120e3 and 160e3 < p0c2 < p0d and abs(msub - 0.3722) < 1e-4
def flow(p, m, h): return p * m * sqrt(G * tt(m) / (R * T0)) * h * W   # mass flow, kg/s, from static p, Mach, height
print("start-up: p0 kPa, throat Mach, mass flow kg/s, shock x mm, exit Mach")
for p0 in [105e3, p0c1, 120e3, 140e3, 160e3, p0c2, 300e3, p0d]:
    if p0 < p0c1 + 1e-6:             # not choked: exit at room pressure, subsonic all through
        me = sqrt(((p0 / PB) ** ((G - 1) / G) - 1) / (G / 2 - 0.5)); mt = mach(area(me) / AR, False)
        mf = PB / (R * T0 / tt(me)) * me * sqrt(G * R * T0 / tt(me)) * HE * W; xs, me_s = "none", me
    else:
        mt, mf = 1.0, mdot * p0 / P0
        if p0 < p0c2 - 1e-6:
            a, x = shock_place(p0); r = shock(mach(a, True))[4]; xs, me_s = f"{x * 1e3:.1f}", mach(AR * r, False)
        else: xs, me_s = ("280.0" if p0 < p0c2 + 1 else "none"), 2.0
    assert abs(flow(p0 * pr(mt), mt, HT) / mf - 1) < 1e-9 and abs(flow(PB if me_s < 1 else p0 * pr(me_s), me_s, HE) / mf - 1) < 1e-9
    print(f"  {p0 / 1e3:7.2f} {mt:9.4f} {mf:9.3f} {xs:>8} {me_s:9.4f}")

# ---- chart: static pressure along the nozzle, running and with the shock standing at p0 = 140 kPa ----
a140, x140 = shock_place(140e3); r140 = shock(mach(a140, True))[4]
xs = [i * 0.02 for i in range(15)]
def p_at(x, p0, xsh, r):
    ar = height(x) / HT
    if x <= 0.08: return p0 * pr(mach(ar, False))
    if x < xsh: return p0 * pr(mach(ar, True))
    return r * p0 * pr(mach(ar * r, False))
assert abs(p_at(0.28, 140e3, x140, r140) / PB - 1) < 1e-9 and abs(height(x140) / HT - a140) < 1e-9   # leaves at room pressure
print("chart, x mm      " + " ".join(f"{x * 1e3:5.0f}" for x in xs))
print("chart, 300 kPa   " + " ".join(f"{p_at(x, 300e3, 9, 1) / 1e3:5.1f}" for x in xs))
print("chart, 140 kPa   " + " ".join(f"{p_at(x, 140e3, x140, r140) / 1e3:5.1f}" for x in xs))
print(f"figure, throat x 80 h {HT * 1e3:.2f}; exit x 280 h 100.00; inlet h 180.00; shock at 140 kPa x {x140 * 1e3:.1f} h {height(x140) * 1e3:.2f}")

# ---- what breaks, honesty numbers, try changing ----
rho0 = P0 / (R * T0)
for lab, v, d, u in [("wrong: A V constant, speed at the exit", astar / AR, 1, "m/s"),
                     ("wrong: Bernoulli, fixed density, exit p", (P0 - rho0 * u1 * u1 / 2) / 1e3, 1, "kPa"),
                     ("wrong: loss-free shock, second throat", HT * W * 1e4, 2, "cm^2"),
                     ("wrong: static p in choked formula", mdot * p1 / P0, 3, "kg/s"),
                     ("density drop at Mach 0.3", 100 * (1 - tt(0.3) ** (-1 / (G - 1))), 2, "%"),
                     ("Mach 5 from 20 C: static temperature", T0 / tt(5.0), 2, "K"),
                     ("try: Mach 3, throat area", W * HE * 1e4 / area(3.0), 2, "cm^2"), ("try: Mach 3, design p0", PB / pr(3.0) / 1e6, 3, "MPa"),
                     ("try: helium, area ratio at Mach 2", area(2.0, 5 / 3), 4, ""),
                     ("try: helium, stagnation pressure kept", 100 * shock(2.0, 5 / 3)[4], 2, "%"),
                     ("try: shock at Mach 1.2, kept", 100 * shock(1.2)[4], 2, "%")]:
    out(lab, v, d, u)
print("ALL CHECKS PASS")
