# Dispersion on a canal: ripples behind a barge, group velocity from plane waves, KdV balance.
import math
G, H, U = 9.81, 1.5, 1.8           # gravity m/s^2, canal depth m, barge speed m/s
SIG, RHO = 0.072, 1000.0           # surface tension N/m, water density kg/m^3
def omega(k, sig=0.0):             # water waves: omega^2 = (g k + sig k^3 / rho) tanh(k h)
    return math.sqrt((G * k + sig * k ** 3 / RHO) * math.tanh(k * H))
def cg_formula(k):                 # d omega/dk for gravity waves, by hand
    return 0.5 * omega(k) / k * (1 + 2 * k * H / math.sinh(2 * k * H))
def bisect(f, lo, hi):
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
# 1. the wake wave: crests keep pace with the barge, omega/k = U
k = bisect(lambda q: omega(q) / q - U, 0.5, 20.0)
w = omega(k)
print(f"wake wave: k = {k:.4f} rad/m, wavelength = {2*math.pi/k:.4f} m, omega = {w:.4f} rad/s, period = {2*math.pi/w:.4f} s")
print(f"deep-water guess g/U^2 = {G/U**2:.4f} rad/m, kh = {k*H:.3f}, tanh(kh) = {math.tanh(k*H):.5f}, "
      f"1 + 2kh/sinh(2kh) = {1 + 2*k*H/math.sinh(2*k*H):.5f}")
# 2. read the relation off the plane wave: phi = cosh(k(z+h)) cos(kx - wt), residuals by centred differences
def res_water(k, w, d):
    phi = lambda x, z, t: math.cosh(k * (z + H)) * math.cos(k * x - w * t)
    x, t = 0.3, 0.2
    lap = (phi(x+d, -0.5, t) + phi(x-d, -0.5, t) + phi(x, -0.5+d, t) + phi(x, -0.5-d, t) - 4*phi(x, -0.5, t)) / d**2
    surf = (phi(x, 0, t+d) - 2*phi(x, 0, t) + phi(x, 0, t-d)) / d**2 + G * (phi(x, d, t) - phi(x, -d, t)) / (2*d)
    return abs(lap) / (k * k * abs(phi(x, -0.5, t))), abs(surf) / (w * w * abs(phi(x, 0, t)))
for d in (1e-2, 5e-3):
    r = res_water(k, w, d)
    print(f"plane wave in the canal, step {d:.0e}: Laplace {r[0]:.2e}, surface {r[1]:.2e} (relative)")
    assert max(r) < 1e-3
k20 = 2 * math.pi / 20.0
r_wrong = res_water(k20, math.sqrt(G * k20), 5e-3)[1]
print(f"20 m wave with the deep-water omega: surface residual {r_wrong:.4f}")
assert abs(r_wrong - (1 - math.tanh(k20 * H))) < 1e-3   # the miss is 1 - tanh(kh) of the term's size
# 3. group velocity, four roads
dk = 1e-4
cg_fd = (omega(k + dk) - omega(k - dk)) / (2 * dk)
cg = cg_formula(k)
print(f"phase velocity omega/k = {w/k:.4f} m/s; group velocity formula = {cg:.4f} m/s, centred difference = {cg_fd:.4f} m/s")
assert abs(cg - cg_fd) < 1e-6
assert abs(w / k - U) < 1e-9
for frac in (0.5, 0.10, 0.05, 0.01):
    k1, k2 = k * (1 - frac / 2), k * (1 + frac / 2)
    print(f"two waves {frac*100:4.0f}% apart in k: beat speed d omega/d k = {(omega(k2)-omega(k1))/(k2-k1):.4f} m/s")
# three plane waves, amplitudes 1/2, 1, 1/2: track the envelope's peak by scanning x
DK = 0.05 * k
def env(x, t):
    re = im = 0.0
    for amp, q in ((0.5, k - DK), (1.0, k), (0.5, k + DK)):
        ph = (q - k) * x - (omega(q) - w) * t
        re += amp * math.cos(ph); im += amp * math.sin(ph)
    return math.hypot(re, im)
def peak(t):
    xs = [i * 0.001 for i in range(-5000, 30000)]
    return max(xs, key=lambda x: env(x, t))
T = 20.0
xp = peak(T)
print(f"three-wave group: peak at {xp:.3f} m after {T:.0f} s, speed {xp/T:.4f} m/s, height {env(xp, T):.4f} (2 at the start)")
assert abs(xp / T - cg) < 2e-3
print(f"in {T:.0f} s the crests move {U*T:.1f} m, the group {cg*T:.2f} m; {(U-cg)*T/(2*math.pi/k):.2f} crests pass through it")
print("envelope t=0 s: " + ", ".join(f"{env(x, 0):.2f}" for x in range(-10, 31, 2)))
print("envelope t=20 s: " + ", ".join(f"{env(x, T):.2f}" for x in range(-10, 31, 2)))
print(f"energy made 10 s ago sits {(U-cg)*10:.2f} m behind the barge; Kelvin wedge half-angle {math.degrees(math.asin(1/3)):.2f} deg")
# 4. the dispersion relation across wavelengths (chart)
lams = [0.5, 1, 2, 3, 4, 6, 8, 10, 15, 20, 30, 50]
print("wavelength m: " + ", ".join(f"{L:g}" for L in lams))
print("phase m/s: " + ", ".join(f"{omega(2*math.pi/L)/(2*math.pi/L):.3f}" for L in lams))
print("group m/s: " + ", ".join(f"{cg_formula(2*math.pi/L):.3f}" for L in lams))
c0 = math.sqrt(G * H)
print(f"long-wave limit sqrt(g h) = {c0:.4f} m/s")
# 5. long waves: omega = c0 k (1 - (kh)^2/6) is the linear KdV relation; read it off eta = cos(kx - wt)
beta = c0 * H ** 2 / 6
wk = c0 * k20 - beta * k20 ** 3
print(f"20 m wave: exact {omega(k20)/k20:.4f} m/s, KdV {wk/k20:.4f} m/s, deep-water formula {math.sqrt(G/k20):.4f} m/s")
assert abs(wk / k20 - omega(k20) / k20) < 0.02
lin = lambda x, t: math.cos(k20 * x - wk * t)
d = 1e-2
rl = ((lin(1, d) - lin(1, -d)) / (2*d) + c0 * (lin(1+d, 0) - lin(1-d, 0)) / (2*d)
      + beta * (lin(1+2*d, 0) - 2*lin(1+d, 0) + 2*lin(1-d, 0) - lin(1-2*d, 0)) / (2*d**3))
print(f"plane wave in linear KdV: residual {abs(rl):.2e}")
assert abs(rl) < 1e-4
# 6. KdV: eta_t + c0 eta_x + (3 c0 / 2h) eta eta_x + (c0 h^2/6) eta_xxx = 0, solitary wave a sech^2((x - Vt)/l)
A = 0.3
V, ell = c0 * (1 + A / (2 * H)), math.sqrt(4 * H ** 3 / (3 * A))
print(f"solitary wave a = {A} m: speed {V:.4f} m/s (linear {c0:.4f}), width scale {ell:.4f} m")
def kdv_terms(x, d, v):
    eta = lambda x, t: A / math.cosh((x - v * t) / ell) ** 2
    et = (eta(x, d) - eta(x, -d)) / (2 * d)
    ex = (eta(x + d, 0) - eta(x - d, 0)) / (2 * d)
    exxx = (eta(x+2*d, 0) - 2*eta(x+d, 0) + 2*eta(x-d, 0) - eta(x-2*d, 0)) / (2 * d**3)
    nl, disp = 1.5 * c0 / H * eta(x, 0) * ex, beta * exxx
    return et + c0 * ex + nl + disp, nl, disp
res, nl = {}, 0.0
for d in (0.1, 0.05):
    rs = [kdv_terms(-10 + 0.25 * i, d, V) for i in range(81)]
    res[d], nl = max(abs(r[0]) for r in rs), max(abs(r[1]) for r in rs)
    print(f"KdV residual, step {d} m: max {res[d]:.2e} m/s "
          f"(steepening term up to {nl:.4f}, spreading term up to {max(abs(r[2]) for r in rs):.4f})")
assert res[0.05] < 0.1 * nl
assert res[0.05] < 0.3 * res[0.1]
r_lin = max(abs(kdv_terms(-10 + 0.25 * i, 0.05, c0)[0]) for i in range(81))
print(f"same hump at the linear speed {c0:.4f} m/s: residual {r_lin:.4f} m/s")
assert r_lin > 3 * res[0.05]
eta = lambda x, t: A / math.cosh((x - V * t) / ell) ** 2
# 7. drop the spreading term: eta_t + c0 (1 + 3 eta/2h) eta_x = 0 breaks
tb = 2 * H * ell / (3 * c0 * A * 4 / (3 * math.sqrt(3)))
xs = [-15 + 0.001 * i for i in range(30001)]
sp = [c0 * (1 + 1.5 * eta(x, 0) / H) for x in xs]
tb_brute = min((xs[i+1] - xs[i]) / (sp[i] - sp[i+1]) for i in range(30000) if sp[i] > sp[i+1])
print(f"no spreading term: breaks at {tb:.4f} s (formula), {tb_brute:.4f} s (crossing characteristics), after {c0*tb:.2f} m")
assert abs(tb - tb_brute) < 1e-3
# 8. surface tension: ripples shorter than a few cm run with group faster than crests
lmin_closed, cmin_closed = 2 * math.pi * math.sqrt(SIG / (RHO * G)), (4 * G * SIG / RHO) ** 0.25
gr = (math.sqrt(5) - 1) / 2; lo, hi = 0.005, 0.05
for _ in range(100):
    m1, m2 = hi - gr * (hi - lo), lo + gr * (hi - lo)
    cp = lambda L: omega(2 * math.pi / L, SIG) / (2 * math.pi / L)
    if cp(m1) < cp(m2): hi = m2
    else: lo = m1
print(f"slowest ripple: {100*lo:.3f} cm at {cp(lo):.4f} m/s (search), {100*lmin_closed:.3f} cm at {cmin_closed:.4f} m/s (closed form)")
assert abs(lo - lmin_closed) < 1e-5
assert abs(cp(lo) - cmin_closed) < 1e-6
kc = 2 * math.pi / 0.005
cgc = (omega(kc + 1e-2, SIG) - omega(kc - 1e-2, SIG)) / 2e-2
print(f"0.5 cm ripple: phase {omega(kc, SIG)/kc:.4f} m/s, group {cgc:.4f} m/s")
print("ALL CHECKS PASS")
