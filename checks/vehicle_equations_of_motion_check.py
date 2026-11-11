# Vehicle equations of motion: a jumbo jet at Mach 0.8, 40,000 ft.  Standard library only.
# Road 1: modes as eigenvalues of the published linear sets (characteristic polynomial, roots).
# Road 2: the nonlinear body-axis equations, linearised by finite differences: same matrices, zero coupling.
# Road 3: fly the nonlinear equations (RK4), then fit the modes to the recorded motion (Prony).
import cmath
from math import sin, cos, tan, asin, atan2, sqrt, pi, log, radians, degrees
FT = 0.3048
V, G, A0 = 773.98 * FT, 32.2 * FT, 0.0803          # airspeed m/s, gravity m/s^2, trim alpha = trim pitch, rad
XU, XW, ZU, ZW = -0.006868, 0.01395, -0.09055, -0.3151        # per s
MU, MW, MQ = 0.0001187 / FT, -0.001026 / FT, -0.4285          # per (m s), per (m s), per s
ALON = [[XU, XW, 0, -G], [ZU, ZW, V, 0], [MU, MW, MQ, 0], [0, 0, 1, 0]]          # states u, w, q, theta
ALAT = [[-0.0558, -0.9968, 0.0802, 0.0415], [0.598, -0.115, -0.0318, 0],
        [-3.05, 0.388, -0.4650, 0], [0, 0.0805, 1, 0]]                          # states beta, r, p, phi
c, s = cos(A0), sin(A0)

def f(x, pv=1.0):   # body-axis equations: x = u, w, q, theta, v, r, p, phi (m/s, rad/s, rad); pv 0 drops p v from heave
    u, w, q, th, v, r, p, ph = x
    us, ws = c * u + s * w, -s * u + c * w                  # velocity in axes along the trim airflow
    xs, zs = XU * (us - V) + XW * ws, ZU * (us - V) + ZW * ws - G
    b = asin(v / sqrt(u * u + v * v + w * w))              # sideslip
    return [r * v - q * w - G * sin(th) + c * xs - s * zs,
            q * u - pv * p * v + G * cos(th) * cos(ph) + s * xs + c * zs,
            MU * (us - V) + MW * ws + MQ * q,
            q * cos(ph) - r * sin(ph),
            p * w - r * u + G * cos(th) * sin(ph) - 0.0558 * V * b,
            0.598 * b - 0.115 * r - 0.0318 * p,
            -3.05 * b + 0.388 * r - 0.465 * p,
            p + (q * sin(ph) + r * cos(ph)) * tan(th)]
def mm(a, b): return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))] for i in range(len(a))]
def roots(cf):          # Durand-Kerner: all roots of a monic polynomial at once
    n = len(cf) - 1
    z = [(0.4 + 0.9j) ** k for k in range(n)]
    for _ in range(500):
        for i in range(n):
            pv, d = 0j, 1 + 0j
            for k in range(n + 1): pv = pv * z[i] + cf[k]
            for j in range(n):
                if j != i: d *= z[i] - z[j]
            z[i] -= pv / d
    return sorted(z, key=lambda t: (round(t.real, 9), round(t.imag, 9)))
def eig(a):             # Faddeev-LeVerrier characteristic polynomial, then its roots
    n, m, cf = len(a), [[0.0] * len(a) for _ in a], [1.0]
    for k in range(1, n + 1):
        am = mm(a, m)
        m = [[am[i][j] + (cf[-1] if i == j else 0) for j in range(n)] for i in range(n)]
        am = mm(a, m)
        cf.append(-sum(am[i][i] for i in range(n)) / k)
    return roots(cf)
def show(tag, lam, lo=0.0, hi=9.0):    # print each mode once: rate, frequency, damping, time scale
    for z in lam:
        if z.imag < -1e-6 or not lo < abs(z) < hi: continue
        tail = f"half-life {log(2) / -z.real:7.2f} s" if z.real < 0 else f"doubles in {log(2) / z.real:5.2f} s"
        if abs(z.imag) < 1e-6:
            print(f"{tag:<9} real {z.real:9.5f} /s  time constant {1 / abs(z.real):8.2f} s  {tail}")
        else:
            print(f"{tag:<9} {z.real:8.5f} +/- {z.imag:7.5f}j  wn {abs(z):7.4f} rad/s  zeta {-z.real / abs(z):7.4f}"
                  f"  period {2 * pi / z.imag:6.2f} s  {tail}")
def two(tag, a, b, cc, d):   # 2x2 approximation by trace and determinant
    tr, de = a + d, a * d - b * cc
    print(f"{tag:<20} trace {tr:8.4f}  det {de:7.4f}  wn {sqrt(de):6.4f} rad/s  zeta {-tr / (2 * sqrt(de)):6.4f}"
          f"  period {2 * pi / sqrt(de - tr * tr / 4):5.2f} s")
    return sqrt(de), -tr / (2 * sqrt(de))
def rk4(x, dt, pv=1.0):
    k1 = f(x, pv); k2 = f([a + dt / 2 * b for a, b in zip(x, k1)], pv)
    k3 = f([a + dt / 2 * b for a, b in zip(x, k2)], pv); k4 = f([a + dt * b for a, b in zip(x, k3)], pv)
    return [a + dt / 6 * (b1 + 2 * b2 + 2 * b3 + b4) for a, b1, b2, b3, b4 in zip(x, k1, k2, k3, k4)]
def fly(da, db, tend, dt=0.02, pv=1.0):   # start disturbed by da (angle of attack) and db (sideslip), radians
    x = [V * cos(db) * cos(A0 + da), V * cos(db) * sin(A0 + da), 0, A0, V * sin(db), 0, 0, 0]
    rec = [x]
    for _ in range(round(tend / dt)):
        x = rk4(x, dt, pv); rec.append(x)
    return rec
def prony(y, dt):       # fit y[k+4] + a1 y[k+3] + ... + a4 y[k] = 0 by least squares; roots are e^(lambda dt)
    rows = [[y[k + 3], y[k + 2], y[k + 1], y[k], -y[k + 4]] for k in range(len(y) - 4)]
    m = [[sum(r[i] * r[j] for r in rows) for j in range(5)] for i in range(4)]
    for i in range(4):
        for k in range(i + 1, 4):
            fk = m[k][i] / m[i][i]; m[k] = [a - fk * b for a, b in zip(m[k], m[i])]
    a = [0.0] * 4
    for i in (3, 2, 1, 0): a[i] = (m[i][4] - sum(m[i][j] * a[j] for j in range(i + 1, 4))) / m[i][i]
    return sorted([cmath.log(z) / dt for z in roots([1.0] + a)], key=lambda t: (round(t.real, 6), round(t.imag, 6)))
# ---- road 2: linearise the body-axis equations by finite differences ----
x0 = [V * c, V * s, 0, A0, 0, 0, 0, 0]
jac = [[0.0] * 8 for _ in range(8)]
for j in range(8):
    h = 1e-6 * max(1.0, abs(x0[j]))
    fp = f([x0[k] + (h if k == j else 0) for k in range(8)]); fm = f([x0[k] - (h if k == j else 0) for k in range(8)])
    for i in range(8): jac[i][j] = (fp[i] - fm[i]) / (2 * h)
rot, back = [[c, s, 0, 0], [-s, c, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]], [[c, -s, 0, 0], [s, c, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
jlon = mm(mm(rot, [r[:4] for r in jac[:4]]), back)
jlat = [[jac[4 + i][4 + j] * (V if j == 0 else 1) / (V if i == 0 else 1) for j in range(4)] for i in range(4)]
dlon = max(abs(jlon[i][j] - ALON[i][j]) for i in range(4) for j in range(4))
dlat = max(abs(jlat[i][j] - ALAT[i][j]) for i in range(4) for j in range(4))
cross = max(abs(jac[i][j]) for i in range(8) for j in range(8) if (i < 4) != (j < 4))
print(f"trim: altitude {40000 * FT:.0f} m, V {V:.3f} m/s, g {G:.4f} m/s^2, alpha = theta = {A0} rad = {degrees(A0):.2f} deg, Mw {MW:.6f} /(m s)")
print(f"jacobian vs published: longitudinal max diff {dlon:.6f}, lateral max diff {dlat:.6f}")
print(f"jacobian coupling blocks, largest entry {cross:.6f}")
print(f"lateral kinematics: -cos a0 {jlat[0][1]:.5f}, sin a0 {jlat[0][2]:.5f}, g cos a0 / V {jlat[0][3]:.5f}, tan a0 {jlat[3][1]:.5f}")
# ---- road 1: eigenvalues of the published sets ----
lon, lat = eig(ALON), eig(ALAT)
show("lon", lon); show("lat", lat)
# ---- road 3: fly a 0.1 deg nudge for 300 s, sample once a second, fit the modes ----
plon = prony([x[2] for x in fly(radians(0.1), 0, 300)[::50]], 1.0)
plat = prony([x[6] for x in fly(0, radians(0.1), 300)[::50]], 1.0)
show("fit lon", plon); show("fit lat", plat)
# ---- by hand: the two-state approximations ----
wsp, _ = two("short period 2x2", ZW, V, MW, MQ)
_, zdr = two("dutch roll 2x2", -0.0558, -0.9968, 0.598, -0.115)
# ---- what breaks ----
show("no V*q", eig([[XU, XW, 0, -G], [ZU, ZW, 0, 0], [MU, MW, MQ, 0], [0, 0, 1, 0]]))
print(f"dutch roll {abs(lat[2]):.4f} rad/s read as Hz: period {1 / abs(lat[2]):.2f} s (right {2 * pi / lat[2].imag:.2f} s)")
amp = []
for b0 in (1, 5, 15):
    rec = fly(0, radians(b0), 40)
    da = max(abs(atan2(x[1], x[0]) - A0) for x in rec); amp.append(da)
    print(f"sideslip {b0:2d} deg: linear says alpha moves 0; nonlinear peak alpha change {degrees(da):6.3f} deg,"
          f" peak bank {max(abs(degrees(x[7])) for x in rec):5.2f} deg, x{da / amp[0]:6.1f} the 1 deg case")
npv = max(abs(atan2(x[1], x[0]) - A0) for x in fly(0, radians(5), 40, pv=0.0))   # roll-times-sideslip p v dropped
print(f"sideslip  5 deg, p v dropped from heave: peak alpha change {degrees(npv):6.3f} deg")
# ---- try changing ----
def lon_with(mw): return eig([[XU, XW, 0, -G], [ZU, ZW, V, 0], [MU, mw, MQ, 0], [0, 0, 1, 0]])
def lat_with(nr, lb): return eig([[-0.0558, -0.9968, 0.0802, 0.0415], [0.598, nr, -0.0318, 0], [lb, 0.388, -0.465, 0], [0, 0.0805, 1, 0]])
show("Mw/2", lon_with(MW / 2), 0.3); show("Mw flip", lon_with(-MW), 0.3)
show("Nr -0.6", [z for z in lat_with(-0.6, -3.05) if abs(z.imag) > 0.1]); show("Lb 0", [z for z in lat_with(-0.115, 0) if abs(z.imag) > 0.1])
# ---- chart: 1 deg gusts, nonlinear, once a second ----
ra, rb = fly(radians(1), 0, 20)[::50], fly(0, radians(1), 20)[::50]
print("chart alpha change, deg:", " ".join(f"{degrees(atan2(x[1], x[0]) - A0):.2f}" for x in ra))
print("chart sideslip, deg:    ", " ".join(f"{degrees(asin(x[4] / sqrt(x[0]**2 + x[1]**2 + x[4]**2))):.2f}" for x in rb))
# ---- checks ----
assert dlon < 1e-6, "linearised body-axis equations must reproduce the published longitudinal set"
assert dlat < 1e-4, "... and the published lateral set, to its 3-4 figure rounding"
assert cross < 1e-9, "turning-axes and gravity terms must not couple the two sets to first order"
for a, b in zip(lon + lat, plon + plat):
    assert abs(a - b) < 0.01 * abs(a) + 1e-4, "modes fitted to the flight record must match the eigenvalues"
assert abs(wsp - abs(eig([[ZW, V], [MW, MQ]])[0])) < 1e-9, "trace-determinant formula must match the 2x2 eigenvalues"
assert abs(wsp / abs(lon[0]) - 1) < 0.01, "2x2 short period within 1% of the full set"
assert zdr / (-lat[2].real / abs(lat[2])) > 2, "2x2 dutch roll over-states the damping"
assert abs(amp[1] / amp[0] - 25) < 2.5, "coupling grows as the square of the disturbance"
assert npv < amp[1] / 2, "the roll-times-sideslip product p v carries most of the coupling"
print("ALL CHECKS PASS")
