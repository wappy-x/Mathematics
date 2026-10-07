# Scaling and nondimensionalisation -- the check behind the card.  Standard library only.
# Water in a 0.1 m pipe, pushed from rest by a steady pressure drop per metre G.
# Rescaled: du/dtau = 1 + eps * (1/r) d/dr (r du/dr), u = 0 at the wall r = 1, u = 0 at tau = 0.
# Road 1: the exact Bessel series.  Road 2: Crank-Nicolson finite differences.
# Road 3: eps -> 0 (the plug), plus its wall-layer correction.  Nothing imported knows the answer.
from math import pi, sqrt, cos, sin, exp, log, log10

RHO, NU, D = 1000.0, 1.0e-6, 0.1            # kg/m^3, m^2/s, m: water near 20 C, rounded
MU, R = RHO * NU, D / 2.0

def bessel(n, x, m=600):                     # J_n(x) = (1/pi) int_0^pi cos(n t - x sin t) dt, trapezoid
    h = pi / m
    s = 0.5 * (1.0 + cos(n * pi))
    for k in range(1, m):
        s += cos(n * k * h - x * sin(k * h))
    return s * h / pi

ZEROS = []                                   # zeros of J_0 by Newton, J_0' = -J_1
for k in range(1, 151):
    x = (k - 0.25) * pi
    for _ in range(6):
        x += bessel(0, x) / bessel(1, x)
    ZEROS.append((x, bessel(1, x)))

def series_mean(eps, tau):                   # road 1: mean speed / U
    return 1 / (8 * eps) - sum(4 / (eps * l ** 4) * exp(-eps * l * l * tau) for l, _ in ZEROS)

def series_u(eps, tau, r):                   # road 1: speed / U at radius r / R
    return (1 - r * r) / (4 * eps) - sum(2 * bessel(0, l * r) / (eps * l ** 3 * j1)
                                         * exp(-eps * l * l * tau) for l, j1 in ZEROS)

def simulate(eps, tau_end, n=400, steps=2000):   # road 2: Crank-Nicolson on n cells
    h, dt = 1.0 / n, tau_end / steps
    lo, up = [0.0] * n, [4 / (h * h)] + [0.0] * (n - 1)
    for i in range(1, n):
        lo[i] = (i - 0.5) / (i * h * h)
        up[i] = (i + 0.5) / (i * h * h)
    c = 0.5 * eps * dt
    u = [0.0] * (n + 1)                          # u[n] is the wall, held at 0
    for _ in range(steps):
        rhs = [u[i] + dt + c * (lo[i] * (u[i - 1] if i else 0) - (lo[i] + up[i]) * u[i] + up[i] * u[i + 1])
               for i in range(n)]
        cp, dp = [0.0] * n, [0.0] * n            # Thomas algorithm
        for i in range(n):
            a, b, cc = -c * lo[i], 1 + c * (lo[i] + up[i]), -c * up[i]
            den = b - (a * cp[i - 1] if i else 0)
            cp[i] = cc / den
            dp[i] = (rhs[i] - (a * dp[i - 1] if i else 0)) / den
        for i in range(n - 1, -1, -1):
            u[i] = dp[i] - cp[i] * u[i + 1]
    mean = sum(2 * (i * h) * u[i] * h for i in range(1, n))   # trapezoid of 2 r u dr; ends are 0
    return mean, u[0]

def prandtl_f(re):                           # smooth-pipe law 1/sqrt f = 2 log10(Re sqrt f) - 0.8
    g = 0.02
    for _ in range(50):
        g = 1 / (2 * log10(re * sqrt(g)) - 0.8) ** 2
    return g

K_LAYER = 8 / (3 * sqrt(pi))                 # mean deficit = K sqrt(eps tau): the wall-layer road
print(f"inputs: rho 1000 kg/m^3, nu 1.0e-6 m^2/s, D = 0.1 m; NIST, 20 C: rho 998.21, mu 1.0016e-3 Pa s, "
      f"nu {1.0016e-3 / 998.21 * 1e6:.4f}e-6 m^2/s")
cases = []
for re, laminar in ((2000, True), (200000, False)):
    U = re * NU / D
    f = 64 / re if laminar else prandtl_f(re)
    G = f * RHO * U * U / (2 * D)                   # Pa/m the steady flow needs
    T = RHO * U / G                                 # s: time for G alone to bring water to U
    eps = MU * U / (G * R * R)
    cases.append((re, U, f, G, T, eps))
    sm, sc = simulate(eps, 1.0)
    em, ec = series_mean(eps, 1.0), series_u(eps, 1.0, 0.0)
    print(f"Re {re:>6}: U = {U:.2f} m/s, 1/Re = {1 / re:.6f}, f = {f:.5f}, G = {G:.3f} Pa/m")
    print(f"   T = rho U / G = {T:.2f} s, D/U = {D / U:.2f} s, eps = mu U/(G R^2) = {eps:.5f}, 8/(f Re) = {8 / (f * re):.5f}")
    print(f"   wall layer sqrt(nu T) = {sqrt(NU * T) * 1000:.2f} mm, sqrt(eps) = {sqrt(eps):.4f} of R")
    print(f"   at tau = 1, mean/U: series {em:.5f}  simulation {sm:.5f}  plug 1.00000  "
          f"plug - layer {1 - K_LAYER * sqrt(eps):.5f}")
    print(f"   at tau = 1, centre/U: series {ec:.5f}  simulation {sc:.5f}  plug 1.00000")
    print(f"   mean speed at T: {em * U:.4f} m/s, deficit / sqrt(eps) = {(1 - em) / sqrt(eps):.4f}")
    assert abs(sm - em) < 1e-4, "simulation and series disagree on the mean"
    assert abs(sc - ec) < 1e-4, "simulation and series disagree at the centre"
    assert abs(eps * f * re / 8 - 1) < 1e-12, "mu U/(G R^2) and 8/(f Re) disagree"

reA, UA, fA, GA, TA, epsA = cases[0]
reB, UB, fB, GB, TB, epsB = cases[1]
lo_t, hi_t = 0.0, 20.0                       # case A: time to 99% of the steady mean, by bisection
for _ in range(60):
    mid = 0.5 * (lo_t + hi_t)
    lo_t, hi_t = (mid, hi_t) if series_mean(epsA, mid) < 0.99 / (8 * epsA) else (lo_t, mid)
l1 = ZEROS[0][0]
t99_mode = log(32 / l1 ** 4 / 0.01) / (epsA * l1 * l1)
print(f"Re 2000 to 99% of steady: tau {lo_t:.4f} (series), {t99_mode:.4f} (first mode) = {lo_t * TA:.0f} s")
print(f"K = 8/(3 sqrt pi) = {K_LAYER:.4f}; first zero of J0 = {l1:.5f}; viscous time R^2/nu = {R * R / NU:.0f} s")
print(f"wrong: laminar G at Re 200000 = {8 * MU * UB / R ** 2:.2f} Pa/m, needed {GB:.2f} Pa/m (x{GB * R ** 2 / (8 * MU * UB):.1f})")
print(f"wrong: drop the acceleration at Re 200000: mean = {GB * R * R / (8 * MU):.2f} m/s")
print(f"wrong: plug-minus-layer at Re 2000 = {1 - K_LAYER * sqrt(epsA):.4f}, true {series_mean(epsA, 1.0):.4f}")
for re in (4000, 2000000):
    f = prandtl_f(re); e = 8 / (f * re); m = series_mean(e, 1.0)
    print(f"try: Re {re:>7}: f = {f:.5f}, eps = {e:.5f}, mean/U at tau 1 = {m:.4f}, "
          f"deficit/sqrt(eps) = {(1 - m) / sqrt(e):.4f}")
coarse = simulate(epsB, 1.0, n=25, steps=200)[0]
print(f"try: Re 200000 on 25 cells: simulation mean {coarse:.4f}")
fH = (-1.8 * log10(6.9 / reB)) ** -2         # Haaland's explicit smooth-pipe fit: a second road to f
print(f"friction at Re 200000: Prandtl {fB:.5f}, Haaland {fH:.5f}, gap {(fB / fH - 1) * 100:.1f}%")
taus = [k / 10 for k in range(11)]
rads = [0.5 + k / 20 for k in range(11)]
print(f"{'chart, tau':<22}" + " ".join(f"{t:5.2f}" for t in taus))
print(f"{'chart, plug mean':<22}" + " ".join(f"{t:5.2f}" for t in taus))
for lab, e in (("Re 200000", epsB), ("Re 2000", epsA)):
    print(f"chart, mean {lab:<10}" + " ".join(f"{series_mean(e, t):5.2f}" for t in taus))
print(f"{'chart, r/R':<22}" + " ".join(f"{r:5.2f}" for r in rads))
for lab, e in (("Re 200000", epsB), ("Re 2000", epsA)):
    print(f"chart, prof {lab:<10}" + " ".join(f"{max(series_u(e, 1.0, r), 0.0):5.2f}" for r in rads))
mB = series_mean(epsB, 1.0)
assert abs(mB - (1 - K_LAYER * sqrt(epsB))) < 0.005, "wall-layer road misses the exact mean at Re 200000"
assert abs(series_u(epsB, 1.0, 0.0) - 1.0) < 1e-3, "the plug must be exact at the centre at Re 200000"
assert abs(lo_t - t99_mode) < 1e-3, "bisection and first-mode settling times disagree"
assert abs(fB / fH - 1) < 0.02, "Prandtl and Haaland friction factors disagree"
assert series_mean(epsA, 1.0) < 0.6, "at Re 2000 the plug must fail badly"
print("ALL CHECKS PASS")
