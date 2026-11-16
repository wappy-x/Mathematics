# Drumheads: the modes of a round membrane are Bessel patterns.  Standard library only.
# A drum 30 cm across (R = 0.15 m), clamped at the rim, waves at c = 100 m/s
# (tension 2000 N/m over 0.2 kg/m^2, illustrative).  Bessel functions and their zeros are
# built here three ways: power series, Bessel's integral, Runge-Kutta 4 from the centre.
from math import cos, sin, pi, sqrt, atan2, factorial, floor, log10

R, C = 0.15, 100.0

def sci(x):                                    # same e-notation digits in Python and Rust
    if x == 0: return "0.0e+00"
    e = floor(log10(abs(x))); m = round(x / 10 ** e, 1)
    if abs(m) >= 10: m, e = m / 10, e + 1
    return f"{m:.1f}e{'-' if e < 0 else '+'}{abs(e):02d}"

def j_series(m, x, terms=40):                  # sum (-1)^p (x/2)^(2p+m) / (p! (p+m)!)
    t = (x / 2) ** m / factorial(m); s = 0.0
    for p in range(terms):
        s += t; t *= -(x / 2) ** 2 / ((p + 1) * (p + 1 + m))
    return s

def j_integral(m, x, n=64):                    # (1/pi) int_0^pi cos(m tau - x sin tau), trapezoid
    s = 0.5 * (1.0 + cos(m * pi))
    for i in range(1, n): s += cos(m * i * pi / n - x * sin(i * pi / n))
    return s / n

def zeros(f, m, count, step=0.05):             # scan for sign changes, then bisect
    out, a = [], step
    while len(out) < count:
        if f(m, a) * f(m, a + step) < 0:
            lo, hi = a, a + step
            for _ in range(60):
                mid = (lo + hi) / 2
                lo, hi = (mid, hi) if f(m, lo) * f(m, mid) > 0 else (lo, mid)
            out.append((lo + hi) / 2)
        a += step
    return out

def zeros_rk4(m, count, h):                    # y = x^m v: v'' + (2m+1) v'/x + v = 0, v(0) = 1, v'(0) = 0
    def acc(x, v, w): return -v / (2 * m + 2) if x == 0 else -v - (2 * m + 1) * w / x
    def step(x, v, w, d):
        k1 = (w, acc(x, v, w)); k2 = (w + d / 2 * k1[1], acc(x + d / 2, v + d / 2 * k1[0], w + d / 2 * k1[1]))
        k3 = (w + d / 2 * k2[1], acc(x + d / 2, v + d / 2 * k2[0], w + d / 2 * k2[1]))
        k4 = (w + d * k3[1], acc(x + d, v + d * k3[0], w + d * k3[1]))
        return v + d / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]), w + d / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    x, v, w, out = 0.0, 1.0, 0.0, []
    while len(out) < count:
        v2, w2 = step(x, v, w, h)
        if v * v2 < 0:                         # bisect the length of one RK4 step from x
            lo, hi = 0.0, h
            for _ in range(60):
                mid = (lo + hi) / 2
                lo, hi = (mid, hi) if step(x, v, w, mid)[0] * v > 0 else (lo, mid)
            out.append(x + (lo + hi) / 2)
        x, v, w = x + h, v2, w2
    return out

Z = {m: zeros(j_series, m, 3) for m in range(6)}
print(f"drum: R = {R} m (30 cm across), c = {C:.0f} m/s; f = c j/(2 pi R) = {C / (2 * pi * R):.3f} Hz per unit of j")
print(f"series, 40 terms: first omitted term of J0 at x = 16, the largest x used, is {sci(8.0 ** 80 / factorial(40) ** 2)}")
worst_int = max(abs(a - b) for m in range(6) for a, b in zip(Z[m], zeros(j_integral, m, 3)))
print(f"zeros by Bessel's integral (64 points) against the series: worst gap below 1e-10: {'yes' if worst_int < 1e-10 else 'no'}")
errs = []
for h in (0.1, 0.05):
    e = max(abs(a - b) for m in range(4) for a, b in zip(Z[m], zeros_rk4(m, 3, h)))
    errs.append(e); print(f"zeros by RK4 from the centre, h = {h}: worst gap {sci(e)}")
print(f"RK4 gap ratio when h halves: {errs[0] / errs[1]:.1f}")
assert worst_int < 1e-10 and errs[1] < 1e-6 and 10 < errs[0] / errs[1] < 22
modes = sorted((Z[m][n - 1], m, n) for m in range(6) for n in (1, 2, 3))[:10]
print("mode (m,n)   j_mn      k (1/m)   f (Hz)   f/f1   diameters circles  shapes")
for j, m, n in modes:
    print(f"  ({m},{n})   {j:8.4f}  {j / R:8.2f}  {C * j / (2 * pi * R):7.1f}  {j / modes[0][0]:5.3f}"
          f"       {m}         {n - 1}       {1 if m == 0 else 2}")
assert [(m, n) for _, m, n in modes[:4]] == [(0, 1), (1, 1), (2, 1), (0, 2)]
assert abs(Z[0][0] - 2.404826) < 1e-6 and abs(Z[1][0] - 3.831706) < 1e-6 and abs(Z[2][0] - 5.135622) < 1e-6
f1 = C * Z[0][0] / (2 * pi * R)
print(f"fundamental: omega = c k = {C * Z[0][0] / R:.1f} rad/s, f = {f1:.1f} Hz, period {1000 / f1:.3f} ms")
print("cycles done by the next modes in one period of the fundamental: "
      + ", ".join(f"{j / modes[0][0]:.3f}" for j, _, _ in modes[1:4]))
print(f"nodal circle of (0,2) at r = R j01/j02 = {R * Z[0][0] / Z[0][1] * 100:.2f} cm; "
      f"of (1,2) at {R * Z[1][0] / Z[1][1] * 100:.2f} cm")
print("timpani family (m,1), m = 1..4, over (1,1): " + ", ".join(f"{Z[m][0] / Z[1][0]:.3f}" for m in (1, 2, 3, 4))
      + "; a 2:3:4:5 ladder is 1.000, 1.500, 2.000, 2.500")
# road 4: the full shape J_m(k r) cos(m theta) in the plain Cartesian Laplacian, by centred differences
for m in (1, 2):
    k = Z[m][0] / R
    phi = lambda x, y: j_series(m, k * sqrt(x * x + y * y)) * cos(m * atan2(y, x))
    gaps = []
    for h in (2e-3, 1e-3):
        x0, y0 = 0.05, 0.03
        lap = (phi(x0 + h, y0) + phi(x0 - h, y0) + phi(x0, y0 + h) + phi(x0, y0 - h) - 4 * phi(x0, y0)) / h ** 2
        gaps.append(abs(-lap / phi(x0, y0) - k * k))
    print(f"({m},1) in Cartesian -Laplacian / shape at (0.05, 0.03) m: k^2 = {k * k:.2f} 1/m^2; "
          f"gap {sci(gaps[0])} at h = 2 mm, {sci(gaps[1])} at 1 mm, ratio {gaps[0] / gaps[1]:.1f}")
    assert gaps[1] < 1e-2 * k * k and 3 < gaps[0] / gaps[1] < 5
def simpson(g, n=2000):
    return sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(i / n) for i in range(n + 1)) / (3 * n)
cross = simpson(lambda s: j_series(0, Z[0][0] * s) * j_series(0, Z[0][1] * s) * s)
norm = simpson(lambda s: j_series(0, Z[0][0] * s) ** 2 * s)
print(f"orthogonality: int_0^1 J0(j01 s) J0(j02 s) s ds below 1e-12: {'yes' if abs(cross) < 1e-12 else 'no'}; int J0(j01 s)^2 s ds = {norm:.6f}, "
      f"J1(j01)^2 / 2 = {j_series(1, Z[0][0]) ** 2 / 2:.6f}")
assert abs(cross) < 1e-12 and abs(norm - j_series(1, Z[0][0]) ** 2 / 2) < 1e-9
def rel(m, j, r):                              # height at r over the shape's highest point
    peak = max(abs(j_series(m, j * i / 1000)) for i in range(1001))
    return round(j_series(m, j * r / R) / peak, 6) + 0.0
for r in (0.0, 0.10):
    print(f"strike at r = {r * 100:.0f} cm: heights of (0,1), (1,1), (2,1) over their peaks: "
          + ", ".join(f"{rel(m, Z[m][0], r):.3f}" for m in (0, 1, 2)))
print("figure, r (cm):  " + " ".join(f"{i * 1.5:5.1f}" for i in range(11)))
for m in (0, 1, 2):
    print(f"figure, ({m},1) / peak: " + " ".join(f"{rel(m, Z[m][0], i * 0.015):5.2f}" for i in range(11)))
print("highest points of (1,1) and (2,1), where J_m' = J_(m-1) - m J_m / x = 0: r = " + ", ".join(
      f"{100 * R * zeros(lambda m, x: j_series(m - 1, x) - m / x * j_series(m, x), m, 1)[0] / Z[m][0]:.2f}" for m in (1, 2)) + " cm")
print(f"figure, 400 px per m: discs of radius 60 px at x 80, 220, 360, 500, y 90; (0,2) nodal circle radius "
      f"{60 * Z[0][0] / Z[0][1]:.1f} px; (2,1) nodal diameters end {60 / sqrt(2):.2f} px across and up from centre")
print("mistakes:")
print(f"  whole-number ladder: second note {2 * f1:.1f} Hz, not {C * Z[1][0] / (2 * pi * R):.1f} Hz")
print(f"  round modes only: second note {C * Z[0][1] / (2 * pi * R):.1f} Hz; misses "
      f"{C * Z[1][0] / (2 * pi * R):.1f} and {C * Z[2][0] / (2 * pi * R):.1f} Hz")
print(f"  30 cm taken as the radius: fundamental {C * Z[0][0] / (2 * pi * 0.30):.1f} Hz, not {f1:.1f} Hz")
print(f"  m = 1.5 round the circle: cos(1.5 theta) is {cos(0):.0f} at theta = 0 and {cos(1.5 * 2 * pi):.0f} "
      f"after a full turn, a jump of {cos(0) - cos(3 * pi):.0f}")
print("ALL CHECKS PASS")
