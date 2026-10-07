# Bessel's equation and the drum -- the check behind the card.  Standard library only.  A timpani
# head, radius 0.3 m, wave speed 100 m/s.  A pure note's shape y(x), x = k r, obeys x^2 y'' + x y' + x^2 y = 0.
# Road one: the Frobenius series J0, zeros by bisection.  Road two: Runge-Kutta 4 out from the centre.
import math
R, C = 0.3, 100.0                          # drum radius (m), wave speed on the head (m/s)
def terms(x, n, wrong=False):              # a_n = -a_(n-2) / n^2; wrong: n(n - 1), y'/x dropped
    out = [1.0]
    for k in range(1, n): out.append(out[-1] * -x * x / ((2 * k) * (2 * k - 1) if wrong else 4 * k * k))
    return out

series = lambda x, n=40, wrong=False: sum(terms(x, n, wrong))
def bisect(f, lo, hi):
    for _ in range(80): lo, hi = ((lo + hi) / 2, hi) if f(lo) * f((lo + hi) / 2) > 0 else (lo, (lo + hi) / 2)
    return (lo + hi) / 2
def zeros(f, xmax=10.0, step=0.1):         # every sign change of f below xmax, refined
    return [bisect(f, i * step, (i + 1) * step) for i in range(int(xmax / step)) if f(i * step) * f((i + 1) * step) < 0]
def rk4(x, y, v, h):                       # one step of y'' = -y'/x - y; at x = 0, y'' = -y/2
    f = lambda x, y, v: (v, -y / 2 if x == 0 else -v / x - y)
    k1 = f(x, y, v); k2 = f(x + h / 2, y + h / 2 * k1[0], v + h / 2 * k1[1])
    k3 = f(x + h / 2, y + h / 2 * k2[0], v + h / 2 * k2[1]); k4 = f(x + h, y + h * k3[0], v + h * k3[1])
    return y + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]), v + h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
def rk4_zeros(h, xmax=10.0):               # step out from y(0) = 1, y'(0) = 0; refine each crossing
    x, y, v, found = 0.0, 1.0, 0.0, []
    while x < xmax - h / 2:
        y2, v2 = rk4(x, y, v, h)
        if y * y2 < 0: found.append(x + bisect(lambda s: rk4(x, y, v, s)[0], 0.0, h))
        x, y, v = x + h, y2, v2
    return found
row = lambda vals, p: " ".join(f"{round(v, p) + 0.0:.{p}f}" for v in vals)
resid = lambda g, x, h=1e-3: x * x * (g(x + h) - 2 * g(x) + g(x - h)) / h ** 2 + x * (g(x + h) - g(x - h)) / (2 * h) + x * x * g(x)
print("indicial s^2 = 0: double root s = 0; a1 = 0; a2, a4, a6, a8 = -1/4, 1/64, -1/2304, 1/147456")
print(f"J0 put into the equation at x = 1.5, rates by differences: residual below 1e-5: {'yes' if abs(resid(series, 1.5)) < 1e-5 else 'no'}")
print("hand check, terms at x = 2.4:", row(terms(2.4, 7), 6), f"; J0(2.4) = {series(2.4):.6f}, J0(2.41) = {series(2.41):.6f}")
js = zeros(series)
print("zeros, series and bisection:", row(js, 6))
errs = []
for h in (0.2, 0.1, 0.05):
    rz = rk4_zeros(h)
    errs.append(max(abs(a - b) for a, b in zip(rz, js)))
    print(f"zeros, RK4 from the centre, h = {h:.2f}:", row(rz, 6), f"; worst error {errs[-1] * 1e6:.2f} millionths")
print(f"error ratio when h halves: {errs[0] / errs[1]:.1f}, {errs[1] / errs[2]:.1f}")
beta = [(n - 0.25) * math.pi for n in (1, 2, 3)]
print("overtone ratios j2/j1, j3/j1:", row([j / js[0] for j in js[1:]], 3), "; large-x estimate (n - 1/4) pi:", row(beta, 3),
      "; its ratios", row([b / beta[0] for b in beta[1:]], 3), "; with 1/(8 beta) added:", row([b + 1 / (8 * b) for b in beta], 4))
fs = [C * j / (2 * math.pi * R) for j in js]
print(f"timpani R = {R} m, c = {C:.0f} m/s: notes", row(fs, 1), "Hz")
print("figure, r (cm):", " ".join(f"{3 * i:5d}" for i in range(11)))
for n in range(3): print(f"figure, mode {n + 1}: ", " ".join(f"{round(series(js[n] * i / 10), 2) + 0.0:5.2f}" for i in range(11)))
print(f"mistake, harmonic overtones: {2 * fs[0]:.1f} and {3 * fs[0]:.1f} Hz, not {fs[1]:.1f} and {fs[2]:.1f}")
cz = zeros(lambda x: series(x, wrong=True))
print("mistake, y'/x dropped (cos x): zeros", row(cz, 3), "; ratios", row([z / cz[0] for z in cz[1:]], 3),
      f"; fundamental {C * cz[0] / (2 * math.pi * R):.1f} Hz; cos x in J0's equation at 1.5: {resid(math.cos, 1.5):.3f}")
tz = zeros(lambda x: series(x, 4))
print(f"mistake, 4 terms of the series: {len(tz)} zero below 10, at {tz[0]:.3f}")
assert errs[-1] < 5e-7                                                         # two roads, one set of zeros
assert 10 < errs[0] / errs[1] < 22 and 10 < errs[1] / errs[2] < 22          # the gap shrinks at fourth order
assert abs(resid(series, 1.5)) < 1e-5 and abs(resid(math.cos, 1.5)) > 1     # J0 solves it, cos x does not
assert all(abs(j - b - 1 / (8 * b)) < 0.005 for j, b in zip(js, beta))     # large-x estimate agrees
print("ALL CHECKS PASS")
