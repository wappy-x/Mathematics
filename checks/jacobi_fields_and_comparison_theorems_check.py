# Jacobi fields and comparison theorems -- the check behind the card.  Standard
# library only: sin, cos, sinh, asin and sqrt, nothing that knows the answer.
# Two aircraft leave London Heathrow on great circles, headings 290 and 291
# degrees.  Their gap is found three ways: the Jacobi field alpha R sin(s/R),
# Runge-Kutta 4 on f'' + K f = 0, and 3D positions on the sphere.  Then the
# flattened Earth (WGS 84) is trapped between two comparison spheres.
import math

R = 6371.0                                   # km, the spherical Earth model
AL = math.radians(1.0)                       # the 1 degree spread, in radians
A_E, F_E = 6378.137, 1 / 298.257223563       # WGS 84 equator radius, flattening
B_E = A_E * (1 - F_E)                        # polar semi-axis, km

def sn(k, s):                                # model-space gap per radian, curvature k
    if k > 0:
        return math.sin(math.sqrt(k) * s) / math.sqrt(k)
    if k < 0:
        return math.sinh(math.sqrt(-k) * s) / math.sqrt(-k)
    return s

def rk4(speed, curv, u_end, n, sign=1.0):    # f'' + sign K f = 0 in arc length s,
    h, u, f, g, s = u_end / n, 0.0, 0.0, AL, 0.0      # stepped in a parameter u
    def rhs(u, f, g):
        v = speed(u)
        return g * v, -sign * curv(u) * f * v, v
    for _ in range(n):
        k1 = rhs(u, f, g)
        k2 = rhs(u + h / 2, f + h / 2 * k1[0], g + h / 2 * k1[1])
        k3 = rhs(u + h / 2, f + h / 2 * k2[0], g + h / 2 * k2[1])
        k4 = rhs(u + h, f + h * k3[0], g + h * k3[1])
        f += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        g += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        s += h / 6 * (k1[2] + 2 * k2[2] + 2 * k3[2] + k4[2])
        u += h
    return f, s

def unit(lat, lon):                          # point on the unit sphere, degrees
    la, lo = math.radians(lat), math.radians(lon)
    return [math.cos(la) * math.cos(lo), math.cos(la) * math.sin(lo), math.sin(la)]

E0 = unit(51.47, -0.4543)                    # Heathrow
NO = [-math.sin(math.radians(51.47)) * math.cos(math.radians(-0.4543)),
      -math.sin(math.radians(51.47)) * math.sin(math.radians(-0.4543)),
      math.cos(math.radians(51.47))]         # unit vector due north at Heathrow
EA = [-math.sin(math.radians(-0.4543)), math.cos(math.radians(-0.4543)), 0.0]

def gap3d(s, head_deg, spread):              # great-circle distance between the two aircraft
    pts = []
    for hd in (head_deg, head_deg + math.degrees(spread)):
        t = [math.cos(math.radians(hd)) * n + math.sin(math.radians(hd)) * e for n, e in zip(NO, EA)]
        pts.append([math.cos(s / R) * p + math.sin(s / R) * q for p, q in zip(E0, t)])
    chord = math.sqrt(sum((p - q) ** 2 for p, q in zip(*pts)))
    return 2 * R * math.asin(min(1.0, chord / 2))

K = 1 / R ** 2
QS, HALF = math.pi * R / 2, math.pi * R
print(f"Heathrow 51.47 N 0.4543 W; headings 290 and 291 deg; WGS 84 inverse flattening {1 / F_E:.9f}")
print(f"spread {AL:.9f} rad; sphere R = {R:.1f} km, K = 1/R^2; antipode at pi R = {HALF:.2f} km")
print("    s km | flat a s | a R sin(s/R) |  3D gap | saddle a R sinh(s/R)")
rows = [500.0, 1000.0, 2000.0, 5000.0, QS, 15000.0, HALF]
for s in rows:
    jac, ex = AL * sn(K, s), gap3d(s, 290.0, AL)
    print(f"{s:8.1f} | {AL * s:8.3f} | {jac:12.3f} | {ex:7.3f} | {AL * sn(-K, s):9.3f}")
    trig = 2 * R * math.asin(math.sin(s / R) * math.sin(AL / 2))  # spherical trig
    assert abs(trig - ex) < 1e-9                           # 3D gap = exact formula
    assert abs(jac - ex) <= AL ** 3 * R / 40               # Jacobi = gap to third order
one = lambda u: 1.0
kon = lambda u: K
f5, _ = rk4(one, kon, 5000.0, 5)
f10, _ = rk4(one, kon, 5000.0, 10)
j_5, j_q = AL * sn(K, 5000.0), AL * sn(K, QS)
print(f"RK4 at 5000 km, 5 steps {f5:.9f}, 10 steps {f10:.9f}, closed form {j_5:.9f} km")
print(f"RK4 error ratio 5 -> 10 steps: {(f5 - j_5) / (f10 - j_5):.2f} (fourth order: about 16)")
assert abs(f10 - j_5) < 1e-4 and 12 < (f5 - j_5) / (f10 - j_5) < 20
fpi, _ = rk4(one, kon, HALF, 400)
print(f"conjugate point: RK4 gap at pi R = {fpi:.6f} km, exact 3D gap {gap3d(HALF, 290.0, AL):.6f} km")
assert abs(fpi) < 1e-6
print("chart, s in 1000 km:", " ".join(f"{s // 1000}" for s in range(0, 20001, 2000)))
print("chart, plane:", " ".join(f"{AL * s:.1f}" for s in range(0, 20001, 2000)))
print("chart, sphere:", " ".join(f"{AL * sn(K, s):.1f}" for s in range(0, 20001, 2000)))
print("chart, saddle:", " ".join(f"{AL * sn(-K, s):.1f}" for s in range(0, 20001, 2000)))
# ---- the flattened Earth: meridians from the North Pole, 1 degree of longitude apart ----
W = lambda u: A_E ** 2 * math.cos(u) ** 2 + B_E ** 2 * math.sin(u) ** 2
spd = lambda u: math.sqrt(W(u))                         # ds/du along the meridian
kel = lambda u: B_E ** 2 / W(u) ** 2                    # Gaussian curvature there
r_hi, r_lo = B_E, A_E ** 2 / B_E                        # radii of the comparison spheres
print(f"WGS 84: a = {A_E:.3f} km, b = {B_E:.3f} km; K from 1/{r_lo:.3f}^2 (pole) to 1/{r_hi:.3f}^2 (equator)")
e8, q8 = rk4(spd, kel, math.pi / 2, 8)
e16, q16 = rk4(spd, kel, math.pi / 2, 16)
exact = AL * A_E                                        # symmetry: 1 degree of longitude at the equator
lo, hi = AL * sn(1 / r_hi ** 2, q16), AL * sn(1 / r_lo ** 2, q16)
print(f"pole to equator along a meridian: {q8:.3f} km (8 steps), {q16:.3f} km (16 steps)")
print(f"gap at the equator: RK4 {e8:.6f} (8 steps), {e16:.6f} (16 steps); symmetry alpha a = {exact:.6f} km")
print(f"comparison: {lo:.3f} (sphere radius b) <= {exact:.3f} <= {hi:.3f} (sphere radius a^2/b) km")
print(f"house sphere R = 6371 km at the same distance: {AL * sn(K, q16):.3f} km")
assert abs(e16 - exact) < 1e-4 and abs(e8 - exact) > abs(e16 - exact)
assert lo < exact < hi
# ---- what breaks ----
big = math.radians(60.0)
print(f"mistake 1, flat gap at the quarter: {AL * QS:.3f} km, not {j_q:.3f}")
print(f"mistake 2, sign flipped f'' - K f = 0 at the quarter: {rk4(one, kon, QS, 20, -1.0)[0]:.3f} km")
print(f"mistake 3, spread 60 deg at 2000 km: Jacobi {big * sn(K, 2000.0):.1f} km, exact {gap3d(2000.0, 290.0, big):.1f} km")
print(f"mistake 4, upper bound from the wrong sphere: {lo:.3f} km, but the gap is {exact:.3f}")
print("ALL CHECKS PASS")
