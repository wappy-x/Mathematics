# Convection and radiation from one radiator panel -- the check behind the card.
# Standard library only. Every number quoted on the card is printed here.
from math import exp, log, pi

SIGMA = 5.670374419e-8                     # Stefan-Boltzmann constant, W/(m^2 K^4), NIST CODATA
HP, C, KB = 6.62607015e-34, 299792458.0, 1.380649e-23   # Planck, light, Boltzmann: exact SI
G, K0 = 9.80665, 273.15                    # standard gravity m/s^2; 0 degC in kelvin
AIR = ((300.0, 15.89e-6, 26.3e-3, 22.5e-6), # dry air at 1 atm, Incropera Table A.4:
       (350.0, 20.92e-6, 30.0e-3, 29.9e-6)) # T K, nu m^2/s, k W/(m K), alpha m^2/s

def air(t):                                # straight line between the two table rows
    (t0, *a), (t1, *b) = AIR
    f = (t - t0) / (t1 - t0)
    return [x + f * (y - x) for x, y in zip(a, b)]

def conv(ts, ta, L):                       # natural convection, vertical plate (Churchill-Chu)
    tf = (ts + ta) / 2 + K0                # film temperature, K
    nu, k, al = air(tf)
    ra = G * (ts - ta) * L ** 3 / (tf * nu * al)          # Rayleigh number, beta = 1/tf
    pr = nu / al
    nusselt = (0.825 + 0.387 * ra ** (1 / 6) / (1 + (0.492 / pr) ** (9 / 16)) ** (8 / 27)) ** 2
    return nusselt * k / L, ra, pr, nusselt, k

def rad(ts, tw, eps):                      # net radiation per m^2, small body in a big room
    return eps * SIGMA * ((ts + K0) ** 4 - (tw + K0) ** 4)

def planck(lam, t):                        # black-body power per m^2 per metre of wavelength
    return 2 * pi * HP * C * C / lam ** 5 / (exp(HP * C / (lam * KB * t)) - 1)

def rad_spectrum(ts, tw, eps, n=4000):     # road 2: add up the spectrum, no sigma, no 4th power
    a, b = log(1e-7), log(1e-2)            # 0.1 um to 10 mm, stepped evenly in ln(lambda)
    h = (b - a) / n
    tot = 0.0
    for i in range(n + 1):
        lam = exp(a + i * h)
        w = 1 if i in (0, n) else (4 if i % 2 else 2)
        tot += w * (planck(lam, ts + K0) - planck(lam, tw + K0)) * lam
    return eps * tot * h / 3

TA = TW = 20.0                             # room air and walls, degC
TS, EPS, L, W = 60.0, 0.90, 0.60, 1.00     # surface degC, emissivity (white paint, Incropera), height m, length m
WALL_DT, WALL_H = 0.691, 2.5               # room wall face below the air on Fourier's law, K; wall height, m
A = 2 * L * W                              # both faces, m^2

def total(ts, eps=EPS, height=L, area=A):  # watts: convection plus radiation
    return area * (conv(ts, TA, height)[0] * (ts - TA) + rad(ts, TW, eps))

def solve(q):                              # road 3: surface temperature that sheds q watts
    lo, hi = TA + 1e-9, 150.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if total(mid) < q else (lo, mid)
    return (lo + hi) / 2

h, ra, pr, nusselt, kair = conv(TS, TA, L)
nu_f, _, al_f = air((TS + TA) / 2 + K0)
g_pr = 0.75 * pr ** 0.5 / (0.609 + 1.221 * pr ** 0.5 + 1.238 * pr) ** 0.25
nu_th = 4 / 3 * (ra / pr / 4) ** 0.25 * g_pr   # smooth-flow similarity solution, no fitted data
nu_lam = 0.68 + 0.670 * ra ** 0.25 / (1 + (0.492 / pr) ** (9 / 16)) ** (4 / 9)   # Churchill-Chu, Ra < 1e9 only
h_lam = nu_lam * kair / L
qc, qr = h * (TS - TA), rad(TS, TW, EPS)
qr2 = rad_spectrum(TS, TW, EPS)
ts_k, tw_k = TS + K0, TW + K0
hr = EPS * SIGMA * (ts_k + tw_k) * (ts_k ** 2 + tw_k ** 2)
q60 = total(TS)
peak = max((planck(l * 1e-8, ts_k), l / 100) for l in range(100, 3001))[1]
steel = (qc + qr) * 0.00125 / 60.5         # drop across 1.25 mm of steel, k = 60.5 W/(m K)
q45 = total(45.0)
n_exp = log(q60 / q45) / log(40 / 25)
cel = A * (qc + EPS * SIGMA * (TS ** 4 - TW ** 4))
lin = A * (qc + 4 * EPS * SIGMA * tw_k ** 3 * (TS - TW))
stove, stove_lin = rad(300.0, TW, EPS), 4 * EPS * SIGMA * tw_k ** 3 * (300.0 - TW)
h_wall = conv(TA + WALL_DT, TA, WALL_H)[0]  # a face colder than the air drives the same flow, downward
tf_k = TA - WALL_DT + K0
hr_wall = EPS * SIGMA * (tf_k + tw_k) * (tf_k ** 2 + tw_k ** 2)

rows = [("film temperature, K", (ts_k + tw_k) / 2), ("air viscosity nu, mm^2/s", 1e6 * nu_f),
        ("air diffusivity alpha, mm^2/s", 1e6 * al_f), ("Rayleigh number Ra, millions", ra / 1e6), ("Prandtl number Pr", pr),
        ("air conductivity k, W/(m K)", kair), ("Nusselt number Nu", nusselt),
        ("convection coefficient h, W/(m^2 K)", h), ("  still-air film k/h, mm", 1000 * kair / h),
        ("smooth-flow theory: Nu", nu_th), ("  its h, W/(m^2 K)", nu_th * kair / L),
        ("Churchill-Chu laminar form: Nu", nu_lam), ("  its h, W/(m^2 K)", h_lam),
        ("  its total, W", A * (h_lam * (TS - TA) + qr)), ("  its radiation share, %", 100 * qr / (h_lam * (TS - TA) + qr)),
        ("radiation coefficient h_r, W/(m^2 K)", hr), ("  straightened at mean temp, W/(m^2 K)", 4 * EPS * SIGMA * (ts_k / 2 + tw_k / 2) ** 3),
        ("convection, W/m^2", qc), ("1 radiation by formula, W/m^2", qr),
        ("2 radiation by spectrum, W/m^2", qr2), ("  h_r x 40 K, W/m^2", hr * 40), ("film resistance 1/(h + h_r), m^2 K/W", 1 / (h + hr)),
        ("spectrum peak at 60 C, um", peak), ("panel area, m^2", A),
        ("convection, W", A * qc), ("radiation, W", A * qr), ("TOTAL, W", q60),
        ("radiation share, %", 100 * qr / (qc + qr)), ("drop across the steel, K", steel),
        ("3 surface temp that sheds TOTAL, C", solve(q60)), ("surface temp for 400 W, C", solve(400.0)),
        ("at 45 C surface, W", q45), ("  scaled by 25/40 instead, W", q60 * 25 / 40),
        ("  output exponent n, Q ~ dT^n", n_exp), ("  panel length for TOTAL at 45 C, m", W * q60 / q45),
        ("wrong: Celsius in the 4th power, W", cel), ("  its radiation part, W", cel - A * qc),
        ("wrong: radiation left out, W", A * qc),
        ("wrong: radiation linear at room temp, W", lin),
        ("  its radiation part, W/m^2", lin / A - qc),
        ("stove at 300 C: radiation, W/m^2", stove), ("  linear at room temp, W/m^2", stove_lin),
        ("try: eps = 0.30, W", total(TS, 0.30)), ("try: 0.30 m tall, same length, W", total(TS, EPS, 0.30, 0.60)),
        ("try: 0.30 m tall: h, W/(m^2 K)", conv(TS, TA, 0.30)[0]), ("  1/4-power law at 0.30 m: h, W/(m^2 K)", h * 2 ** 0.25),
        ("wall face, 0.691 K below air: h, W/(m^2 K)", h_wall), ("  its h_r, W/(m^2 K)", hr_wall),
        ("  its film 1/(h + h_r), m^2 K/W", 1 / (h_wall + hr_wall))]
for name, v in rows:
    print(f"{name:<42} {v:>12.4f}")
chart = [(A * conv(ts, TA, L)[0] * (ts - TA), A * rad(ts, TW, EPS)) for ts in range(30, 85, 5)]
print("chart, surface C  " + "".join(f"{ts:5d}" for ts in range(30, 85, 5)))
for name, j in (("convection W", 0), ("radiation W", 1), ("total W", 2)):
    print(f"chart, {name:<12}" + "".join(f"{(c[0] + c[1] if j == 2 else c[j]):5.0f}" for c in chart))

assert abs(qr2 / qr - 1) < 1e-4            # spectrum sum agrees with sigma T^4
assert abs(solve(q60) - TS) < 1e-6         # balance turned round returns the 60 C surface
assert abs(peak - 2897.771955e-6 / ts_k * 1e6) < 0.01   # Wien's displacement constant, NIST
assert abs(h / (nu_th * kair / L) - 1) < 0.35   # fitted h within 35% of smooth-flow theory
assert abs(pr - 0.705) < 0.005             # Table A.4's own Prandtl column: 0.707 at 300 K, 0.700 at 350 K
assert abs(nu_lam / nu_th - 1) < 0.02     # laminar fit to measurements against smooth-flow theory
assert q45 < q60 * 25 / 40                 # output falls faster than the temperature difference
print("ALL CHECKS PASS")
