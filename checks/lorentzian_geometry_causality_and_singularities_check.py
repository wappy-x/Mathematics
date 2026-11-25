# Lorentzian geometry: sort vectors by the sign of g(v, v), solve Friedmann for a matter universe,
# find the horizons of a spinning black hole, and check the focusing behind the singularity theorems.
from math import sqrt, sin, cos, pi, asinh

def show(label, v, d=6):
    print(f"{label:<46}{(0.0 if abs(v) < 5e-13 else v):>14.{d}f}")

z = lambda v: 0.0 if abs(v) < 5e-13 else v  # print a tiny rounding leftover as 0

# ---- 1. causal character in flat spacetime, in years and light-years, so c = 1 ----
def eta(u, v):
    return -u[0] * v[0] + u[1] * v[1]
def boost(v, beta):  # the same two events seen from a ship moving at speed beta
    gam = 1 / sqrt(1 - beta * beta)
    return (gam * (v[0] - beta * v[1]), gam * (v[1] - beta * v[0]))
def kind(q):
    return "timelike" if q < -1e-12 else ("spacelike" if q > 1e-12 else "null")
vecs = (("ship at 0.6 c", (1.0, 0.6)), ("light pulse", (1.0, 1.0)), ("1 yr, 2 ly apart", (1.0, 2.0)))
for name, v in vecs:
    w = boost(v, 0.6)
    print(f"{name:<17} g = {z(eta(v, v)):6.3f} {kind(eta(v, v)):<9} | at 0.6 c: dt = {z(w[0]):6.3f}"
          f" dx = {z(w[1]):6.3f} g = {z(eta(w, w)):6.3f}")
show("proper time of the ship per year, years", sqrt(-eta(vecs[0][1], vecs[0][1])), 3)
w8 = boost(vecs[2][1], 0.8)
print(f"try: the 2 ly pair seen at 0.8 c: dt = {w8[0]:6.3f}, g = {eta(w8, w8):6.3f}")

# ---- 2. FLRW: Einstein tensor of -dt^2 + a(t)^2 (dx^2 + dy^2 + dz^2) from the metric alone ----
def frw(expo):
    return lambda p: [-1.0] + [p[0] ** (2 * expo)] * 3   # a = t^expo, so a^2 = t^(2 expo)
def shift(p, i, s):
    q = list(p); q[i] += s; return q
def christoffel(metric, p, h):  # G[l][j][k] = 1/2 g^ll (d_j g_lk + d_k g_lj - d_l g_jk), g diagonal
    g = metric(p)
    dg = [[(u - w) / (2 * h) for u, w in zip(metric(shift(p, m, h)), metric(shift(p, m, -h)))] for m in range(4)]
    d = lambda m, i, j: dg[m][i] if i == j else 0.0
    return [[[0.5 / g[l] * (d(j, l, k) + d(k, l, j) - d(l, j, k)) for k in range(4)] for j in range(4)] for l in range(4)]
def einstein(metric, p, h=1e-4):  # Ric_bd = d_a G^a_bd - d_d G^a_ba + G^a_ae G^e_bd - G^a_de G^e_ba
    G = christoffel(metric, p, h)
    dG = [[[[(u - w) / (2 * h) for u, w in zip(ru, rw)] for ru, rw in zip(A, B)]
           for A, B in zip(christoffel(metric, shift(p, i, h), h), christoffel(metric, shift(p, i, -h), h))]
          for i in range(4)]
    ric = [sum(dG[a][a][b][b] - dG[b][a][b][a] + sum(G[a][a][e] * G[e][b][b] - G[a][b][e] * G[e][b][a]
               for e in range(4)) for a in range(4)) for b in range(4)]
    g = metric(p)
    S = sum(r / gi for r, gi in zip(ric, g))
    return [r - 0.5 * S * gi for r, gi in zip(ric, g)]
for expo, name in ((2 / 3, "a = t^(2/3), dust"), (1 / 2, "a = t^(1/2), radiation")):
    Gt = einstein(frw(expo), [1.0, 0.3, 0.2, 0.1])
    show(f"{name}: G_tt at t = 1", Gt[0])
    show(f"  closed form 3 H^2 = 3 (expo / t)^2", 3 * expo * expo)
    show(f"{name}: G_xx at t = 1", Gt[1])
    show(f"  closed form -(2 a''/a + H^2) a^2", -(2 * expo * (expo - 1) + expo * expo))
dust, rad = einstein(frw(2 / 3), [1.0, 0.3, 0.2, 0.1]), einstein(frw(1 / 2), [1.0, 0.3, 0.2, 0.1])

# ---- 3. ages: H0 = 70 km/s per Mpc ----
MPC_KM, GYR_S, G_N, M_P = 3.0856775814913673e19, 3.15576e16, 6.67430e-11, 1.67262192595e-27
def hubble_time(H0):  # 1/H0 in billions of years
    return MPC_KM / H0 / GYR_S
H0s = 70 / MPC_KM  # per second
show("1 Mpc in millions of light-years", MPC_KM / 9.4607304725808e12 / 1e6, 4)
show("Hubble time 1/H0, Gyr", hubble_time(70), 3)
show("matter only: age 2/(3 H0), Gyr", 2 / 3 * hubble_time(70), 3)
rho_c = 3 * H0s ** 2 / (8 * pi * G_N)
show("critical density 3H^2/(8 pi G), 1e-27 kg/m^3", rho_c * 1e27, 4)
show("  protons per cubic metre", rho_c / M_P, 2)
def age_integral(Om, OL, n=2000):  # t0 H0 = integral of 2u^2/sqrt(Om + OL u^6), u = sqrt(a), Simpson
    f = lambda u: 2 * u * u / sqrt(Om + OL * u ** 6)
    return sum((1 if k in (0, n) else 4 if k % 2 else 2) * f(k / n) for k in range(n + 1)) / (3 * n)
show("matter only, H0 = 67.4: age, Gyr", 2 / 3 * hubble_time(67.4), 3)
lcdm = 2 / (3 * sqrt(0.685)) * asinh(sqrt(0.685 / 0.315)) * hubble_time(67.4)
show("with dark energy, H0 = 67.4: closed form, Gyr", lcdm, 3)
show("with dark energy, H0 = 67.4: by integral, Gyr", age_integral(0.315, 0.685) * hubble_time(67.4), 3)
show("measured age (Planck 2018), Gyr", 13.787, 3)
show("Ric(u,u) today / H0^2, matter only", 1.5 * 1.0, 4)
show("Ric(u,u) today / H0^2, with dark energy", 1.5 * (0.315 - 2 * 0.685), 4)

# ---- 4. Raychaudhuri, run backwards: dTheta/dt = -Theta^2/3 - Ric(u,u), da/dt = a Theta/3 ----
def back_to(a_stop, h=1e-5):  # units 1/H0; today a = 1, Theta = 3 H0; RK4 with time running back
    f = lambda a, th: (-a * th / 3, th * th / 3 + 1.5 / a ** 3)
    a, th, t = 1.0, 3.0, 0.0
    while True:
        k1 = f(a, th); k2 = f(a + h / 2 * k1[0], th + h / 2 * k1[1])
        k3 = f(a + h / 2 * k2[0], th + h / 2 * k2[1]); k4 = f(a + h * k3[0], th + h * k3[1])
        na = a + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        nt = th + h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        if na < a_stop:
            return t + h * (a - a_stop) / (a - na)
        a, th, t = na, nt, t + h
ray = back_to(0.01)
exact = 2 / 3 * (1 - 0.01 ** 1.5)
show("back to a = 0.01: Raychaudhuri RK4, Gyr", ray * hubble_time(70), 5)
show("back to a = 0.01: exact (2/3)(1 - a^1.5), Gyr", exact * hubble_time(70), 5)
show("focusing bound 3/Theta = 1/H0, Gyr", hubble_time(70), 3)

# ---- 5. Kerr black hole, G = c = 1, M = 1; phi down from the spin axis, theta round it ----
def kerr(r, ph, b):  # g_tt, g_t-theta, g_theta-theta, g_rr
    S, D, s2 = r * r + (b * cos(ph)) ** 2, r * r - 2 * r + b * b, sin(ph) ** 2
    return (-(1 - 2 * r / S), -2 * b * r * s2 / S, (r * r + b * b + 2 * b * b * r * s2 / S) * s2, S / D)
def bisect(f, lo, hi):
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2
b = 0.6
det = lambda ph: (lambda r: kerr(r, ph, b)[0] * kerr(r, ph, b)[2] - kerr(r, ph, b)[1] ** 2)
show("outer horizon M + sqrt(M^2 - b^2), M", 1 + sqrt(1 - b * b))
show("inner horizon M - sqrt(M^2 - b^2), M", 1 - sqrt(1 - b * b))
for ph in (pi / 2, pi / 3):
    print(f"  from the metric at phi = {ph * 180 / pi:2.0f} deg: outer {bisect(det(ph), 1.0, 3.0):.6f} M,"
          f" inner {bisect(det(ph), 0.01, 1.0):.6f} M")
for ph in (pi / 2, pi / 4):
    show(f"ergosurface, phi = {ph * 180 / pi:2.0f} deg, closed form, M", 1 + sqrt(1 - (b * cos(ph)) ** 2))
    show(f"  from g_tt = 0, M", bisect(lambda r: kerr(r, ph, b)[0], 1.0, 3.0))
show("g_rr at r = 1.0 M (inside): d/dr is timelike", kerr(1.0, pi / 2, b)[3], 4)
show("g_tt at r = 1.9 M (ergosphere): d/dt spacelike", kerr(1.9, pi / 2, b)[0], 6)
show("g_tt at r = 2.5 M (outside): d/dt timelike", kerr(2.5, pi / 2, b)[0], 6)
Mm = 10 * 1.3271244e20 / 299792458.0 ** 2 / 1000   # 10 Suns, in km
show("10 Suns: M = GM/c^2, km", Mm, 3)
show("  outer horizon, km", (1 + sqrt(1 - b * b)) * Mm, 2)
show("  inner horizon, km", (1 - sqrt(1 - b * b)) * Mm, 2)
show("  ergosurface at the equator, km", 2 * Mm, 2)
show("b = 1.2 M: smallest Delta = b^2 - M^2", min(r * r - 2 * r + 1.44 for r in [k / 1000 for k in range(3001)]), 4)
show("try: b = 0.9 M, outer horizon, M", 1 + sqrt(1 - 0.81))
show("try: b = 0.9 M, inner horizon, M", 1 - sqrt(1 - 0.81))

# ---- chart: size of the universe against time before now, H0 = 70 ----
taus, t0, th = list(range(0, 15)), 2 / 3 * hubble_time(70), hubble_time(70)
print("chart Gyr ago " + " ".join(f"{t:5d}" for t in taus))
print("matter        " + " ".join(f"{max(0.0, 1 - t / t0) ** (2 / 3):5.2f}" for t in taus))
print("coasting      " + " ".join(f"{max(0.0, 1 - t / th):5.2f}" for t in taus))

assert abs(dust[0] - 4 / 3) < 1e-6 and abs(dust[1]) < 1e-6, "dust: G_tt = 3H^2 and no pressure"
assert abs(rad[1] - 0.25) < 1e-6, "radiation exponent leaves pressure G_xx = 1/4"
assert abs(age_integral(1.0, 0.0) - 2 / 3) < 1e-12, "matter age by integral"
assert abs(age_integral(0.315, 0.685) * hubble_time(67.4) - lcdm) < 1e-6, "dark-energy age, two roads"
assert abs(ray - exact) < 1e-6 and ray < 1.0, "Raychaudhuri run back agrees, inside the focusing bound"
assert abs(bisect(det(pi / 3), 1.0, 3.0) - 1.8) < 1e-12 and abs(bisect(det(pi / 2), 0.01, 1.0) - 0.2) < 1e-12, "horizons"
assert abs(bisect(lambda r: kerr(r, pi / 4, b)[0], 1.0, 3.0) - (1 + sqrt(0.82))) < 1e-12, "ergosurface"
assert abs(eta(w8, w8) - 3.0) < 1e-12 and w8[0] < 0, "boost keeps g(v, v), reverses the spacelike order"
print("ALL CHECKS PASS")
