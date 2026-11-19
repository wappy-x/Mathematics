# Geodesic and exponential map -- the check behind the card.  Python standard library only.
# The globe is a sphere of radius R = 6371 km.  Chart: phi = angle down from the North Pole,
# theta = longitude east.  Heading = clockwise from north.  Routes run at unit speed, s in km.
from math import sin, cos, tan, acos, asin, atan2, sqrt, radians, degrees, pi, log
R = 6371.0
def chart(lat, lon): return radians(90 - lat), radians(lon)
def latlon(ph, th): return 90 - degrees(ph), (degrees(th) + 540) % 360 - 180
def xyz(ph, th): return (R * sin(ph) * cos(th), R * sin(ph) * sin(th), R * cos(ph))
def north_east(ph, th): return (-cos(ph) * cos(th), -cos(ph) * sin(th), sin(ph)), (-sin(th), cos(th), 0.0)
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def gap(p1, p2):                # km along the globe, from the straight chord between the two points
    u, v = xyz(*p1), xyz(*p2); w = [x - y for x, y in zip(u, v)]; return 2 * R * asin(min(1.0, sqrt(dot(w, w)) / (2 * R)))

def exp_map(p, head, s):        # road 2: closed form, a great circle in 3D, no chart used
    P = xyz(*p); N, E = north_east(*p)
    q = [cos(s / R) * a + R * sin(s / R) * (cos(head) * n + sin(head) * e) for a, n, e in zip(P, N, E)]
    return acos(max(-1.0, min(1.0, q[2] / R))), atan2(q[1], q[0])

def log_map(p, q):              # inverse: distance and starting heading from p to q
    P, Q = xyz(*p), xyz(*q); N, E = north_east(*p)
    c = dot(P, Q) / R / R; w = [b - c * a for a, b in zip(P, Q)]
    return R * acos(max(-1.0, min(1.0, c))), atan2(dot(w, E), dot(w, N)) % (2 * pi)

def rk4(f, y, h, n, euler=False):
    for _ in range(n):
        k1 = f(y)
        if euler: y = [a + h * b for a, b in zip(y, k1)]; continue
        k2 = f([a + h / 2 * b for a, b in zip(y, k1)]); k3 = f([a + h / 2 * b for a, b in zip(y, k2)])
        k4 = f([a + h * b for a, b in zip(y, k3)])
        y = [a + h / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(y, k1, k2, k3, k4)]
    return y

# road 1: the geodesic equation in the chart, state (phi, theta, phi', theta')
def geodesic(y): return [y[2], y[3], sin(y[0]) * cos(y[0]) * y[3] * y[3], -2 * y[2] * y[3] / tan(y[0])]
def no_gamma(y): return [y[2], y[3], 0.0, 0.0]                        # mistake: Christoffel symbols dropped
def launch(p, head): return [p[0], p[1], -cos(head) / R, sin(head) / (R * sin(p[0]))]
def shoot(p, head, s, n, f=geodesic, euler=False): return rk4(f, launch(p, head), s / n, n, euler)
def heading(y): return atan2(R * sin(y[0]) * y[3], -R * y[2]) % (2 * pi)
def fmt(p): la, lo = latlon(*p); return f"{abs(la):.4f} {'N' if la >= 0 else 'S'}, {abs(lo):.4f} {'E' if lo >= 0 else 'W'}"

LHR, JFK = chart(51.4700, -0.4543), chart(40.6413, -73.7781)
d, a = log_map(LHR, JFK)
print(f"log_p(JFK) from Heathrow: distance {d:.3f} km, heading {degrees(a):.4f} deg ({a:.6f} rad)")
print(f"as a vector in the tangent plane: {d * cos(a):.1f} km north, {d * sin(a):.1f} km east")
c = dot(xyz(*LHR), xyz(*JFK)) / R / R
print(f"by hand: p.q/R^2 = {c:.6f}, d/R = {d / R:.6f} rad, cos(51.47 deg) = {cos(radians(51.47)):.6f}, sin(heading) = {sin(a):.6f}")
q = exp_map(LHR, a, d)
print(f"exp_p back along that vector lands at {fmt(q)}, {gap(q, JFK) * 1e6:.3f} mm from JFK")
assert gap(q, JFK) < 1e-6                                                  # exp undoes log
LON, NYC = chart(51.5074, -0.1278), chart(40.7128, -74.0060)             # city centres of the metric card
dc, ac = log_map(LON, NYC)
print(f"city centres: {dc:.2f} km at heading {degrees(ac):.2f}; Heathrow is {gap(LHR, LON):.1f} km from central London, "
      f"JFK {gap(JFK, NYC):.1f} km from central New York")
assert abs(dc - 5570.22) < 0.01                                           # the metric card's distance
print(f"Christoffel symbols at Heathrow: Gamma^phi_theta,theta = {-sin(LHR[0]) * cos(LHR[0]):.4f}, "
      f"Gamma^theta_phi,theta = {1 / tan(LHR[0]):.4f}; 0.1 deg from the pole {1 / tan(radians(0.1)):.2f}")
miss = {}
for n in (8, 16, 32):
    y = shoot(LHR, a, d, n); miss[n] = gap(y[:2], q)
    print(f"RK4 in the chart, {n:2d} steps of {d / n:6.1f} km: lands {fmt(y[:2])}, {miss[n] * 1000:7.2f} m from closed form")
print(f"miss ratio per halving: {miss[8] / miss[16]:.2f} {miss[16] / miss[32]:.2f}")
assert 12 < miss[8] / miss[16] < 20 and 12 < miss[16] / miss[32] < 20 and miss[32] < 0.001
print("waypoints:   s km | latitude, longitude | heading deg | cos(lat) sin(heading)")
clair = cos(radians(51.47)) * sin(a)
for k in range(7):
    s = min(1000.0 * k, d); y = shoot(LHR, a, s, max(1, round(s / 10)))
    print(f"waypoint {s:8.1f} | {fmt(y[:2])} | {degrees(heading(y)):8.3f} | {sin(y[0]) * sin(heading(y)):.9f}")
    assert gap(y[:2], exp_map(LHR, a, s)) < 1e-4 and abs(sin(y[0]) * sin(heading(y)) - clair) < 1e-9
    assert abs(R * R * (y[2] * y[2] + sin(y[0]) * y[3] * sin(y[0]) * y[3]) - 1) < 1e-9  # speed stays 1 km per km
top = max(range(0, round(d) + 1), key=lambda s: latlon(*exp_map(LHR, a, s))[0])
print(f"northernmost point: Clairaut predicts {degrees(acos(abs(clair))):.4f} N; "
      f"scan of the route finds {latlon(*exp_map(LHR, a, top))[0]:.4f} N at s = {top} km")
assert abs(degrees(acos(abs(clair))) - latlon(*exp_map(LHR, a, top))[0]) < 1e-3
# what breaks
def rhumb(y): return [-cos(a) / R, sin(a) / (R * sin(y[0]))]               # mistake: heading held fixed
rh = rk4(rhumb, list(LHR), d / 1000, 1000)
ng = shoot(LHR, a, d, 1000, no_gamma); eu = shoot(LHR, a, d, 16, euler=True)
print(f"mistake, hold heading {degrees(a):.2f} all the way: lands {fmt(rh)}, {gap(rh, JFK):.0f} km from JFK")
print(f"mistake, drop the Christoffel terms: lands {fmt(ng[:2])}, {gap(ng[:2], JFK):.0f} km from JFK")
print(f"mistake, Euler steps instead of RK4, 16 steps: lands {gap(eu[:2], JFK):.1f} km from JFK")
wd = exp_map(LHR, degrees(a), d)                                         # mistake: heading in degrees
print(f"mistake, heading fed to sin and cos in degrees: lands {fmt(wd)}, {gap(wd, JFK):.1f} km from JFK")
far = exp_map(LHR, a, 25000.0); d2, a2 = log_map(LHR, far)
print(f"mistake, fly 25000 km on: log_p says {d2:.1f} km at heading {degrees(a2):.2f} (2 pi R - 25000 = {2 * pi * R - 25000:.1f})")
assert abs(d2 - (2 * pi * R - 25000)) < 1e-6 and min(gap(rh, JFK), gap(ng[:2], JFK)) > 2000 and gap(eu[:2], JFK) > 10
assert abs(gap(rh, JFK) - log_map(JFK, rh)[0]) < 1e-6                     # misses measured along the globe
anti = (pi - LHR[0], LHR[1] + pi)
spread = max(gap(shoot(LHR, radians(h), pi * R, 400)[:2], anti) for h in range(30, 360, 60))   # RK4, off the poles
print(f"pi R = {pi * R:.1f} km: RK4 in the chart, 6 headings, all land on {fmt(anti)}, widest gap {spread * 1000:.2f} m")
assert spread < 1e-3
lat1, lat2, dlon = radians(51.47), radians(40.6413), radians(-73.7781 + 0.4543)
dpsi = log(tan(pi / 4 + lat2 / 2) / tan(pi / 4 + lat1 / 2)); hr = atan2(dlon, dpsi)
rd = R * (lat2 - lat1) / cos(hr)
print(f"constant-heading route that does reach JFK: heading {degrees(hr) % 360:.2f}, {rd:.1f} km, {rd - d:.1f} km longer")
# try changing
w = exp_map(LHR, radians(270), d); eq = shoot(chart(0, 0), pi / 2, d, 32)
print(f"try: due west 270 deg for {d:.0f} km lands {fmt(w)}; on the equator heading 90 lands {fmt(eq[:2])}")
print(f"try: 4 RK4 steps miss by {gap(shoot(LHR, a, d, 4)[:2], q) * 1000:.1f} m")
X = lambda p: 30 + 4 * (latlon(*p)[1] + 95); Y = lambda p: 20 + 4 * (70 - latlon(*p)[0])
pts = lambda f: " ".join(f"{X(p):.1f},{Y(p):.1f}" for p in f)
ss = [min(500.0 * k, d) for k in range(13)]
print("figure, great circle:", pts([exp_map(LHR, a, s) for s in ss]))
print("figure, fixed heading:", pts([rk4(rhumb, list(LHR), s / 100, 100) for s in ss]))
print("figure, chart-straight:", pts([shoot(LHR, a, s, 100, no_gamma)[:2] for s in ss]))
print("ALL CHECKS PASS")
