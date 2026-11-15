# Smoothing and infinite speed -- the check behind the card.  Standard library only.
# A 1 m copper rod, kappa = 1.11e-4 m^2/s, ends held at room temperature.  Start: a
# tent-shaped hot spot, 50 C above room at x = 0.5 m, falling to 0 at 0.4 and 0.6 m.
# Roads: kernel closed form; sine series on the rod; direct Simpson convolution;
# the equation's residual by centred differences; log-space integral for the far end.
from math import exp, sqrt, pi, log, log10, sin, floor
K, H, W, L = 1.11e-4, 50.0, 0.1, 1.0
KINKS = ((0.4, 1.0), (0.5, -2.0), (0.6, 1.0))   # f'' = (H/W) * sum c delta(x - x_k)
def sci(x, p=3):                                 # e-notation with the same digits in Rust
    e = floor(log10(abs(x))); m = round(abs(x) / 10 ** e, p)
    if m >= 10: m, e = m / 10, e + 1
    return ("-" if x < 0 else "") + f"{m:.{p}f}e{e}"
def phi(z): return exp(-z * z / 2) / sqrt(2 * pi)
def cf(z):                                       # T = 1/(z + 2/(z + 3/(z + ...))), z >= 3
    t = 0.0
    for k in range(300, 1, -1): t = k / (z + t)
    return 1 / (z + t)
def erf(z):                                      # Maclaurin series, |z| <= 2.2
    s, term, n = 0.0, z, 0
    while abs(term) > 1e-17: s += term / (2 * n + 1); n += 1; term *= -z * z / n
    return 2 / sqrt(pi) * s
def R(x, t):                                     # a ramp max(x, 0) after time t: x N(z) + s phi(z)
    s = sqrt(2 * K * t); z = x / s
    if z < -3: T = cf(-z); return s * phi(z) * T / (-z + T)
    if z > 3: return x + R(-x, t)
    return x * 0.5 * (1 + erf(z / sqrt(2))) + s * phi(z)
def G(x, t): return exp(-x * x / (4 * K * t)) / sqrt(4 * pi * K * t)
def Gxx(x, t): return (x * x / (4 * K * K * t * t) - 1 / (2 * K * t)) * G(x, t)
def u(x, t):                                     # rod = line plus odd images at the ends
    return sum((H / W) * c * (R(x - xk - 2 * m, t) - R(-x - xk - 2 * m, t)) for xk, c in KINKS for m in range(-3, 4))
def uxx(x, t): return (H / W) * sum(c * G(x - xk, t) for xk, c in KINKS)
def uxxxx(x, t): return (H / W) * sum(c * Gxx(x - xk, t) for xk, c in KINKS)
def series(x, t, N, p):                          # sine series: p-th x-derivative (p = 0, 2, 4)
    tot = 0.0
    for n in range(1, N + 1):
        k = n * pi / L
        bk2 = -(2 / L) * (H / W) * sum(c * sin(k * xk) for xk, c in KINKS)  # b_n k^2
        tot += bk2 * k ** (p - 2) * (-1) ** (p // 2) * exp(-K * k * k * t) * sin(k * x)
    return tot
def simpson(f, a, b, n=4000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
tent = lambda y: max(0.0, H * (1 - abs(y - 0.5) / W))
t1 = 1e-3
s1 = sqrt(2 * K * t1)
print(f"kappa t = {sci(K * t1)} m^2, rounding width sqrt(kappa t) = {sqrt(K * t1) * 1e3:.4f} mm at 1 ms")
pk = [u(0.5, t1), series(0.5, t1, 8000, 0), simpson(lambda y: G(0.5 - y, t1) * tent(y), 0.5 - 30 * s1, 0.5 + 30 * s1)]
print("peak at 1 ms, C: kernel {:.6f}, sine series {:.6f}, Simpson {:.6f}".format(*pk))
print(f"drop of the peak at 1 ms, C: formula 2 (H/W) c_1 sqrt(kappa t) = {2 * H / W / sqrt(pi) * sqrt(K * t1):.6f}, kernel 50 - peak = {H - pk[0]:.6f}")
c2 = [uxx(0.5, t1), series(0.5, t1, 8000, 2)]
print(f"curvature at the peak, 1 ms, C/m^2: kernel {sci(c2[0], 4)}, series {sci(c2[1], 4)}")
print(f"series tail: first omitted term of u_xx at N = 8000 below {sci(4 * 2 * H / W * exp(-K * (8001 * pi) ** 2 * t1))}")
h, hx = 1e-6, 1e-5                               # residual: u_t against kappa u_xx at the peak
ut = (u(0.5, t1 + h) - u(0.5, t1 - h)) / (2 * h)
kuxx = K * (u(0.5 + hx, t1) - 2 * u(0.5, t1) + u(0.5 - hx, t1)) / hx ** 2
print(f"at the peak, 1 ms, C/s: u_t = {ut:.2f}, kappa u_xx (differences) = {kuxx:.2f}, kappa u_xx (kernel) = {K * c2[0]:.2f}")
rows = []
for t in (1e-3, 4e-3, 16e-3, 64e-3):
    rows.append((t, H - u(0.5, t), uxx(0.5, t), uxxxx(0.5, t)))
    print(f"t = {t * 1e3:4.0f} ms: drop {H - u(0.5, t):.4f} C, u_xx {sci(uxx(0.5, t))} C/m^2, u_xxxx {sci(uxxxx(0.5, t))} C/m^4")
print(f"ratios per 4x time: u_xx {rows[0][2] / rows[1][2]:.4f}, u_xxxx {rows[0][3] / rows[1][3]:.4f}, drop {rows[1][1] / rows[0][1]:.4f}")
c1n = simpson(lambda x: abs(x) / (2 * K * t1) * G(x, t1), -30 * s1, 30 * s1) * sqrt(K * t1)
c2n = simpson(lambda x: abs(Gxx(x, t1)), -30 * s1, 30 * s1) * K * t1
print(f"c_1: Simpson {c1n:.6f}, 1/sqrt(pi) {1 / sqrt(pi):.6f};  c_2: Simpson {c2n:.6f}, 2 phi(1) {2 * phi(1):.6f}")
print(f"bound sup|f'| c_1 / sqrt(kappa t) at 1 ms: {sci(H / W * c1n / sqrt(K * t1), 4)} C/m^2")
for t in (0, 1e-3, 16e-3):
    print(f"figure, t = {t * 1e3:.0f} ms, x - 0.5 m = -3..3 mm:", ", ".join(f"{(tent(0.5 + i * 5e-4) if t == 0 else u(0.5 + i * 5e-4, t)):.3f}" for i in range(-6, 7)))
cd = {1: 1 / sqrt(pi), 2: sqrt(pi) / 2, 3: 2 / sqrt(pi)}  # several dimensions: a cone of radius W
SA = {1: 2.0, 2: 2 * pi, 3: 4 * pi}
def cone(d, t):
    s = sqrt(2 * K * t)
    return simpson(lambda r: SA[d] * r ** (d - 1) * exp(-r * r / (4 * K * t)) / (4 * pi * K * t) ** (d / 2) * H * (1 - r / W), 0, 30 * s)
lap = {}
for d in (1, 2, 3):
    lap[d] = (cone(d, t1 + h) - cone(d, t1 - h)) / (2 * h) / K
    print(f"d = {d}: tip drop {H - cone(d, t1):.4f} C (formula {2 * H / W * cd[d] * sqrt(K * t1):.4f}), Laplacian {sci(lap[d])} (formula {sci(-H / W * cd[d] / sqrt(K * t1))}) C/m^2")
def log10_far(x, t):                             # dominant kink at 0.6 m; R(-a) in logs
    a = x - 0.6; s = sqrt(2 * K * t); z = a / s; T = cf(z)
    return log10(H / W) + log10(s) + (-z * z / 2 - 0.5 * log(2 * pi)) / log(10) + log10(T / (z + T))
def log10_simpson(x, t, n=4000):                 # log-sum-exp of Simpson's sum over y near 0.6 m
    wdt = 60 * 2 * K * t / (x - 0.6); hh = wdt / n
    lg = [-(x - y) ** 2 / (4 * K * t) - 0.5 * log(4 * pi * K * t) + log(max(tent(y), 1e-300)) + log((4 if i % 2 else 2) if 0 < i < n else 1)
          for i, y in enumerate(0.6 - wdt + j * hh for j in range(n + 1))]
    mx = max(lg); return (mx + log(sum(exp(v - mx) for v in lg)) + log(hh / 3)) / log(10)
for t in (1e-3, 1.0, 10.0):
    print(f"far point x = 0.9 m, t = {t:g} s: log10 of u in C, formula {log10_far(0.9, t):.4f}, Simpson {log10_simpson(0.9, t):.4f}")
print(f"first omitted kink (0.5 m) at t = 10 s, relative size: e^{-(0.4 ** 2 - 0.3 ** 2) / (4 * K * 10):.2f}")
for t in (100.0, 1000.0):
    print(f"far point x = 0.9 m, t = {t:g} s: kernel with images {u(0.9, t):.6f} C, sine series {series(0.9, t, 200, 0):.6f} C")
print(f"series tail at x = 0.9 m, N = 200, t = 100 s: first omitted term below 10^{log10(4 * 2 * H / W / (201 * pi) ** 2) - K * (201 * pi) ** 2 * 100 / log(10):.1f} C")
print(f"image tail at x = 0.9 m, t = 1000 s: nearest omitted image (m = -4) below {sci(2 * W * H * G(2 * 4 * L - 0.9 - 0.6, 1000.0))} C")
print(f"rounding width sqrt(kappa t) at t = 100 s: {sqrt(K * 100.0) * 100:.2f} cm, against 30 cm to the far point")
for t in (1e-3, 1.0, 100.0):
    print(f"terms for e^-40 damping at t = {t:g} s: {sqrt(40 / (K * pi * pi * t)):.0f}")
amp = exp(K * (5000 * pi) ** 2 * t1)
print(f"mistake 1, backward 1 ms: a 1e-6 C error in mode 5000 becomes {sci(1e-6 * amp)} C")
print(f"mistake 2, curvature at 1 microsecond: {sci(uxx(0.5, 1e-6))} C/m^2, and no finite value at t = 0")
print(f"mistake 3, 1/t per derivative predicts u_xx {sci(rows[0][2] / 4)} at 4 ms; true {sci(rows[1][2])} C/m^2")
assert abs(pk[0] - pk[1]) < 1e-9 and abs(pk[0] - pk[2]) < 1e-9 and abs(c2[0] - c2[1]) < 1e-6 * abs(c2[0])
assert abs(ut - kuxx) < 1e-3 * abs(ut) and abs(ut - K * c2[0]) < 1e-6 * abs(ut)
assert abs(c1n - 1 / sqrt(pi)) < 1e-9 and abs(c2n - 2 * phi(1)) < 1e-6 and abs(rows[0][2] / rows[1][2] - 2) < 1e-9
assert all(abs(H - cone(d, t1) - 2 * H / W * cd[d] * sqrt(K * t1)) < 1e-8 and abs(lap[d] / (-H / W * cd[d] / sqrt(K * t1)) - 1) < 1e-5 for d in cd)
assert all(abs(log10_far(0.9, t) - log10_simpson(0.9, t)) < 1e-6 for t in (1e-3, 1.0, 10.0))
assert all(abs(u(0.9, t) - series(0.9, t, 200, 0)) < 1e-9 for t in (100.0, 1000.0))
print("ALL CHECKS PASS")
