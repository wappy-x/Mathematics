# Hamilton's equations -- the check behind the card.  Imports only math's sin, cos, asin, sqrt, pi.
# A 20 kg child, 2 m rods, released at -60 degrees; state: angle th (rad), momentum p = m l^2 th'.
# Roads: the level curve of H, RK4 steps of Hamilton's equations, Simpson's rule, Legendre's max.
from math import sin, cos, asin, sqrt, pi
M, L, G, TH0 = 20.0, 2.0, 9.81, -pi / 3; I, K = M * L * L, M * G * L   # I = m l^2, K = m g l
ham = lambda th, p: p * p / (2 * I) - K * cos(th)     # the Hamiltonian, J
lag = lambda th, v: 0.5 * I * v * v + K * cos(th)      # the Lagrangian, J
def legendre(th, p, lo=-50.0, hi=50.0):                # max over v of p v - L, by ternary search
    for _ in range(200):
        a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (a, hi) if p * a - lag(th, a) < p * b - lag(th, b) else (lo, b)
    return p * lo - lag(th, lo), lo
def rk4(th, p, h, s=-1.0):                             # s = -1: p' = -dH/dth; s = +1 is mistake 2
    f = lambda a, b: (b / I, s * K * sin(a))
    a1, b1 = f(th, p); a2, b2 = f(th + h / 2 * a1, p + h / 2 * b1)
    a3, b3 = f(th + h / 2 * a2, p + h / 2 * b2); a4, b4 = f(th + h * a3, p + h * b3)
    return th + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4), p + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
def to_bottom(h, th=TH0, p=0.0, t=0.0):                # step until th passes 0,
    while rk4(th, p, h)[0] < 0: th, p = rk4(th, p, h); t += h
    lo, hi = 0.0, h                                    # bisect the last step onto th = 0
    for _ in range(60): mid = (lo + hi) / 2; lo, hi = (mid, hi) if rk4(th, p, mid)[0] < 0 else (lo, mid)
    return t + lo, rk4(th, p, lo)[1]
euler = lambda th, p, h: (th + h * p / I, p - h * K * sin(th))
def leap(th, p, h):                                    # kick half, drift, kick half
    p -= h / 2 * K * sin(th); th += h * p / I; return th, p - h / 2 * K * sin(th)
def drift(step, h=0.05, th=TH0, p=0.0, worst=0.0):     # 100 s of steps: largest |H - H0|, final H
    for _ in range(2000): th, p = step(th, p, h); worst = max(worst, abs(ham(th, p) - H0))
    return worst, ham(th, p)
def det(step, th, p, h=0.05, e=1e-4):                  # area factor of one step, by differences
    a = [(x - y) / (2 * e) for x, y in zip(step(th + e, p, h), step(th - e, p, h))]
    b = [(x - y) / (2 * e) for x, y in zip(step(th, p + e, h), step(th, p - e, h))]
    return a[0] * b[1] - a[1] * b[0]
H0, k, n = ham(TH0, 0.0), sin(-TH0 / 2), 400
p_curve = sqrt(2 * I * (H0 + K))                       # the level curve H = H0, read at th = 0
f = lambda q: 1 / sqrt(1 - k * k * sin(q) ** 2)        # the quarter-swing integrand, as on the pendulum card
t_simp = sqrt(I / K) * pi / 6 / n * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(i * pi / 2 / n) for i in range(n + 1))
runs = [to_bottom(h) for h in (0.02, 0.01)]; err = [abs(r[0] - t_simp) for r in runs]
(H_leg, v_star), lf, eu, th1, p1 = legendre(0.0, runs[1][1]), drift(leap), drift(euler), TH0, 0.0
for _ in range(100): th1, p1 = rk4(th1, p1, 0.01, +1.0)
print(f"swing: m l^2 = {I:.1f} kg m^2, m g l = {K:.1f} J, released at -60 deg: H0 = {H0:.1f} J")
print(f"rates at release: th' = p/(m l^2) = 0, p' = -m g l sin(-60 deg) = {-K * sin(TH0):.2f} N m")
print(f"bottom, level curve: p = {p_curve:.2f} kg m^2/s, th' = {p_curve / I:.4f} rad/s, seat {L * p_curve / I:.2f} m/s")
print(f"bottom, RK4 h = 0.02, 0.01: p = {runs[0][1]:.6f} {runs[1][1]:.6f}; off the level curve by {1e9 * (runs[0][1] - p_curve):.1f} {1e9 * (runs[1][1] - p_curve):.1f} x 1e-9")
print(f"quarter swing: Simpson {t_simp:.9f} s; RK4 h = 0.02, 0.01 off by {1e9 * err[0]:.2f} {1e9 * err[1]:.2f} ns, ratio {err[0] / err[1]:.1f}; full swing {4 * t_simp:.3f} s")
print(f"Legendre at the bottom: best v = {v_star:.4f} rad/s, max of p v - L = {H_leg:.1f} J")
print(f"100 s at h = 0.05: leapfrog largest |H - H0| {lf[0]:.2f} J; Euler ends at H = {eu[1]:.2f} J")
print(f"area factor of one step at the bottom: leapfrog {det(leap, 0.0, p_curve):.8f}, Euler {det(euler, 0.0, p_curve):.8f}")
print(f"standing on end: H = {K:.1f} J, needs p = {2 * sqrt(I * K):.2f} at the bottom, seat {2 * L * sqrt(K / I):.3f} m/s; curve drawn above it H = {1.5 * K:.1f} J")
print(f"mistake 1, p = m l th' at the bottom: {M * L * p_curve / I:.2f}, so H = {ham(0.0, M * L * p_curve / I):.2f} J")
print(f"mistake 2, p' = +dH/dth for 1 s: th = {th1 * 180 / pi:.1f} deg, H = {ham(th1, p1):.2f} J")
pts = lambda cs: " ".join(f"{180 + 45 * a:.1f},{110 - 0.2 * b:.1f}" for a, b in cs)   # 45 per rad, 0.2 per kg m^2/s
print("figure, swing loop:", pts((2 * asin(k * sin(i * pi / 12)), 2 * sqrt(I * K) * k * cos(i * pi / 12)) for i in range(24)))
for sg in (1, -1):
    print(f"figure, separatrix {sg:+d}:", pts((i * pi / 8, sg * 2 * sqrt(I * K) * cos(i * pi / 16)) for i in range(-8, 9)))
print("figure, over the top:", pts((i * pi / 8, sqrt(2 * I * (1.5 * K + K * cos(i * pi / 8)))) for i in range(-8, 9)))
assert abs(runs[1][1] - p_curve) < 1e-6                        # RK4 steps land on the level curve
assert err[1] < 1e-8 and 12 < err[0] / err[1] < 20             # two roads to the quarter swing; order four
assert abs(H_leg - H0) < 1e-6                                  # Legendre's max at the bottom = energy at release
assert lf[0] < K / 100 < abs(eu[1] - H0) and abs(det(leap, 0.0, p_curve) - 1) < 1e-8 < abs(det(euler, 0.0, p_curve) - 1)
print("ALL CHECKS PASS")
