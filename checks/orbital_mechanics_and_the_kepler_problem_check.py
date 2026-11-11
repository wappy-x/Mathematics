# Orbits and the Kepler problem -- the check behind the card.  Standard library only.
# A satellite in a 300 km circular orbit is raised to geostationary by two burns.
# Road 1: the conic-orbit formulas (Kepler's three laws, vis-viva).
# Road 2: Newton's inverse-square law stepped forward in time by RK4, burn by burn.
# Road 3 (the slow spiral): the same integrator with a small steady push.
from math import sqrt, pi, atan2, cos, radians, degrees

MU = 3.986004418e14      # GM of Earth, m^3/s^2      (IERS Conventions 2010, Table 1.1)
RE = 6378136.6           # equatorial radius, m      (Table 1.1)
J2 = 1.0826359e-3        # Earth's flattening term   (Table 1.1)
OMEGA = 7.292115e-5      # Earth's spin, rad/s       (Table 1.2)

def vis_viva(r, a): return sqrt(MU * (2 / r - 1 / a))
def kepler_r(T): return (MU * T * T / (4 * pi * pi)) ** (1 / 3)    # Kepler III, solved for a
def period(a): return 2 * pi * sqrt(a ** 3 / MU)
def hohmann(r1, r2):
    at = (r1 + r2) / 2
    return vis_viva(r1, at) - sqrt(MU / r1), sqrt(MU / r2) - vis_viva(r2, at)

# ---- road 1: the formulas ----
Tday = 2 * pi / OMEGA
r1, r2 = RE + 300e3, kepler_r(Tday)
v1, v2 = sqrt(MU / r1), sqrt(MU / r2)
at, et = (r1 + r2) / 2, (r2 - r1) / (r2 + r1)
vp, va = vis_viva(r1, at), vis_viva(r2, at)
dv1, dv2 = hohmann(r1, r2)
h = r1 * vp                      # angular momentum per kg, m^2/s
p = h * h / MU                   # the conic's width parameter, m
def three_burn_best(r1, r2):     # three burns via an endless ellipse: (sqrt 2 - 1)(v1 + v2)
    return (sqrt(2) - 1) * (sqrt(MU / r1) + sqrt(MU / r2))
lo, hi = 2.0, 50.0               # the size ratio r2/r1 where three burns start to beat two
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if sum(hohmann(r1, mid * r1)) < three_burn_best(r1, mid * r1) else (lo, mid)

# ---- road 2: integrate Newton's law, x'' = -MU x / r^3 (+ a push along the velocity) ----
def deriv(s, push):
    x, y, vx, vy = s
    r3, v = (x * x + y * y) ** 1.5, sqrt(vx * vx + vy * vy)
    return (vx, vy, -MU * x / r3 + push * vx / v, -MU * y / r3 + push * vy / v)
def rk4(s, dt, push=0.0):
    k1 = deriv(s, push)
    k2 = deriv([a + dt / 2 * b for a, b in zip(s, k1)], push)
    k3 = deriv([a + dt / 2 * b for a, b in zip(s, k2)], push)
    k4 = deriv([a + dt * b for a, b in zip(s, k3)], push)
    return [a + dt / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(s, k1, k2, k3, k4)]
def rad(s): return sqrt(s[0] ** 2 + s[1] ** 2)
def spd(s): return sqrt(s[2] ** 2 + s[3] ** 2)

s, t, dt, conic_err, area, dist, hours = [r1, 0.0, 0.0, vp], 0.0, 1.0, 0.0, 0.0, 0.0, []
while True:                                          # coast from burn 1 until r stops growing
    n = rk4(s, dt)
    if n[0] * n[2] + n[1] * n[3] < 0:                # radial speed turned negative: apogee passed
        a0, b0 = s[0] * s[2] + s[1] * s[3], n[0] * n[2] + n[1] * n[3]
        frac = a0 / (a0 - b0)
        s, t = rk4(s, frac * dt), t + frac * dt
        break
    area += 0.5 * (s[0] * s[3] - s[1] * s[2]) * dt; dist += (spd(s) + spd(n)) / 2 * dt
    s, t = n, t + dt
    conic_err = max(conic_err, abs(rad(s) - p / (1 + et * cos(atan2(s[1], s[0])))))
    if round(t) % 3600 == 0:
        hours.append((t, rad(s), spd(s), area, dist)); area, dist = 0.0, 0.0
ap_r, ap_v, t_coast = rad(s), spd(s), t

s = [s[0], s[1], s[2] * (ap_v + dv2) / ap_v, s[3] * (ap_v + dv2) / ap_v]   # burn 2
ang, last, rmin, rmax, t, dt = 0.0, atan2(s[1], s[0]), 1e99, 0.0, 0.0, 10.0
while ang < 2 * pi:                                  # one lap of the new orbit
    s, t = rk4(s, dt), t + dt
    a = atan2(s[1], s[0]); d = a - last
    ang += d + 2 * pi if d < -pi else d; last = a
    rmin, rmax = min(rmin, rad(s)), max(rmax, rad(s))
geo_T = t - (ang - 2 * pi) / (sqrt(MU / rad(s)) / rad(s))

def spiral(push, dt=10.0):                           # road 3: gentle push, start in the low circle
    s, t = [r1, 0.0, 0.0, v1], 0.0
    while spd(s) ** 2 / 2 - MU / rad(s) < -MU / (2 * r2):
        s, t = rk4(s, dt, push), t + dt
    return push * t, t
sp_dv, sp_t = spiral(0.02)
sp2_dv, _ = spiral(0.2, 1.0)

def out(label, val, unit, d=2): print(f"{label:<44}{val:>12.{d}f} {unit}")
out("sidereal day, 2 pi / omega", Tday, "s")
out("r1, 300 km orbit", r1 / 1e3, "km"); out("r2, geostationary (Kepler III)", r2 / 1e3, "km")
out("r2 altitude", (r2 - RE) / 1e3, "km")
out("v1, circular speed low", v1, "m/s"); out("v2, circular speed high", v2, "m/s")
out("low orbit period", period(r1) / 60, "min")
out("transfer a", at / 1e3, "km"); out("transfer e", et, "-", 4)
out("h = r1 vp", h / 1e9, "1e9 m^2/s", 4); out("p = h^2/MU", p / 1e3, "km")
out("1 formula  vp, perigee speed (vis-viva)", vp, "m/s")
out("1 formula  va, apogee speed (vis-viva)", va, "m/s")
out("1 formula  burn 1", dv1, "m/s"); out("1 formula  burn 2", dv2, "m/s")
out("1 formula  total", dv1 + dv2, "m/s"); out("1 formula  coast, half a period", period(at) / 2 / 3600, "h", 3)
out("r2 / r1, size ratio of the two circles", r2 / r1, "-")
out("  three burns can win only above ratio", lo, "-")
out("2 simulate apogee radius", ap_r / 1e3, "km"); out("2 simulate apogee speed", ap_v, "m/s")
out("2 simulate coast time", t_coast / 3600, "h", 3)
out("2 simulate worst gap from the conic", conic_err, "m", 4)
out("2 simulate after burn 2, r wanders by", rmax - rmin, "m")
out("2 simulate lap time after burn 2", geo_T, "s")
for t, r, v, A, D in hours:
    print(f"coast,{t / 3600:.0f} h,alt {(r - RE) / 1e3:.0f} km,speed {v / 1e3:.2f} km/s,"
          f"area {A / 1e12:.2f} 1e12 m^2,distance {D / 1e3:.0f} km")
print(f"coast,{t_coast / 3600:.2f} h,alt {(ap_r - RE) / 1e3:.0f} km,speed {ap_v / 1e3:.2f} km/s")
out("area per hour, h x 3600 / 2", h * 1800 / 1e12, "1e12 m^2")
out("3 spiral, push 0.02 m/s^2: speed gained", sp_dv, "m/s"); out("3 spiral time", sp_t / 86400, "days")
out("  spiral rule v1 - v2", v1 - v2, "m/s"); out("  spiral, push 0.2 m/s^2", sp2_dv, "m/s")
out("J2 drift of the orbit plane, 28.5 deg", degrees(1.5 * 2 * pi / period(r1) * J2 * (RE / r1) ** 2 * cos(radians(28.5))) * 86400, "deg/day")
out("wrong: altitude as r in sqrt(MU/r)", sqrt(MU / 300e3), "m/s")
rw = kepler_r(86400.0)
out("wrong: 86400 s day, radius", rw / 1e3, "km"); out("  drift west", 360 * (86400 / Tday - 1), "deg/day", 3)
ab = -MU / (2 * ((v1 - (v1 - v2)) ** 2 / 2 - MU / r1))
out("wrong: brake by v1 - v2, lowest r", (2 * ab - r1) / 1e3, "km")
out("wrong: skip burn 2, period", period(at) / 3600, "h")
d5, g = hohmann(RE + 500e3, r2), hohmann(r1, kepler_r(Tday / 2))
out("try: 500 km start, total", d5[0] + d5[1], "m/s"); out("try: to GPS height, radius", kepler_r(Tday / 2) / 1e3, "km")
out("try: to GPS height, total", g[0] + g[1], "m/s")
print(f"figure,scale 200 km/unit,earth {RE / 2e5:.2f},low {r1 / 2e5:.2f},geo {r2 / 2e5:.2f},"
      f"ellipse centre {(r1 - r2) / 4e5:.2f},a {at / 2e5:.2f},b {sqrt(r1 * r2) / 2e5:.2f}")

assert abs(ap_r - r2) < 50                     # simulated apogee lands on the GEO radius
assert abs(ap_v - va) < 0.01                   # simulated apogee speed = vis-viva
assert abs(t_coast - period(at) / 2) < 0.5     # coast time = Kepler III half period
assert conic_err < 1.0                         # the path is r = p / (1 + e cos theta)
assert abs(geo_T - Tday) < 30                  # after burn 2, one lap per sidereal day
assert rmax - rmin < 200                       # ... and the orbit is a circle
assert all(abs(A - h * 1800) / (h * 1800) < 1e-6 for _, _, _, A, _ in hours)  # equal areas
assert abs(sp_dv - (v1 - v2)) / (v1 - v2) < 0.01                             # spiral rule
assert r2 / r1 < lo and sum(hohmann(r1, r2)) < three_burn_best(r1, r2)       # two burns win here
print("ALL CHECKS PASS")
