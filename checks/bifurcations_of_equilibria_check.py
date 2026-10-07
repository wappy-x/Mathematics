# Bifurcations -- the check behind the card.  Fishery x' = x(1 - x) - h: stock x as a
# fraction of capacity, catch h in capacities per year, time in years.
from math import sqrt, sin, cos, log, pi

def f(x, h): return x * (1 - x) - h
def bisect(g, lo, hi):                       # a root of g where its sign changes
    for _ in range(200):
        mid = (lo + hi) / 2
        if (g(lo) < 0) == (g(mid) < 0): lo = mid
        else: hi = mid
    return (lo + hi) / 2
def atan(y): return bisect(lambda a: sin(a) - y * cos(a), -pi / 2 + 1e-12, pi / 2 - 1e-12)
def run(x, h, dt, t_end, marks):             # RK4 steps; times x first falls through each mark
    t, hits = 0.0, {}
    while t < t_end - 1e-9 and x > 0:
        k1 = f(x, h); k2 = f(x + dt * k1 / 2, h); k3 = f(x + dt * k2 / 2, h); k4 = f(x + dt * k3, h)
        y = x + dt * (k1 + 2 * k2 + 2 * k3 + k4) / 6
        for m in marks:
            if y <= m < x: hits[m] = t + dt * (x - m) / (x - y)
        x, t = y, t + dt
    return x, hits

slope = lambda x, h: (f(x + 1e-6, h) - f(x - 1e-6, h)) / 2e-6    # difference quotient, not 1 - 2x
for h in (0.21, 0.24):
    lo, hi = (1 - sqrt(1 - 4 * h)) / 2, (1 + sqrt(1 - 4 * h)) / 2
    blo, bhi = bisect(lambda x: f(x, h), 0, 0.5), bisect(lambda x: f(x, h), 0.5, 1)
    assert abs(blo - lo) < 1e-12 and abs(bhi - hi) < 1e-12 and slope(blo, h) > 0 > slope(bhi, h)
    print(f"h {h}: rests {lo:.4f} (slope {1 - 2 * lo:+.2f}, unstable) and {hi:.4f} (slope {1 - 2 * hi:+.2f}, stable);"
          f" bisection {blo:.4f}, {bhi:.4f}")
for h in (0.25, 0.26):
    print(f"h {h}: largest growth minus catch on a grid of stocks {max(f(i / 1e4, h) for i in range(10001)):+.4f} at x = 0.5")
a, u0 = sqrt(0.26 - 0.25), 0.7 - 0.5
closed = {m: (atan(u0 / a) - atan((m - 0.5) / a)) / a for m in (0.5, 0.3, 0.0)}
print(f"h 0.26 from 0.7, a = {a:.1f}, closed form: at 0.5 after %.3f y, at 0.3 after %.3f y, at 0 after %.3f y" % tuple(closed.values()))
for dt in (0.1, 0.01):
    _, hits = run(0.7, 0.26, dt, 40, (0.5, 0.3, 0.0))
    gap = max(abs(hits[m] - closed[m]) for m in closed)
    print(f"RK4 step {dt}: at 0 after {hits[0.0]:.3f} y; largest gap to the closed form {gap:.6f} y")
    assert gap < 0.2 * dt ** 2
path = [0.5 + a * sin(atan(u0 / a) - a * t) / cos(atan(u0 / a) - a * t) for t in range(0, 25, 2)]
print("chart, stock at years 0, 2, ..., 24:", ", ".join(f"{x:.2f}" for x in path))
a2 = sqrt(0.2501 - 0.25)
print(f"h 0.2501 from 0.7: at 0 after {(atan(0.2 / a2) + atan(0.5 / a2)) / a2:.1f} y; pi / a = {pi / a2:.1f} y")
end_up, _ = run(0.31, 0.21, 0.01, 60, ())
_, down = run(0.29, 0.21, 0.01, 60, (0.0,))
t_down = (log(0.3 / 0.7) - log(0.01 / 0.41)) / (2 * 0.2)       # u' = b^2 - u^2, b = 0.2, u = x - 0.5
print(f"cut to h 0.21 at stock 0.31: year 60 stock {end_up:.4f}; at 0.29: at 0 after {down[0.0]:.3f} y (closed form {t_down:.3f})")
assert abs(end_up - 0.7) < 1e-4 and abs(down[0.0] - t_down) < 1e-3
_, fold = run(0.49, 0.25, 0.01, 200, (0.0,))
v0 = -0.01                                                     # u' = -u^2 at the fold: u = v0 / (1 + v0 t)
print(f"h 0.25 from 0.49: at 0 after {fold[0.0]:.2f} y (closed form {(-2 * v0 - 1) / v0:.2f}); from 0.51 at year 98: {0.5 + 0.01 / 1.98:.4f}")
assert abs(fold[0.0] - (-2 * v0 - 1) / v0) < 1e-3
for E in (0.5, 1.2):
    print(f"catch E x with E {E}: rests 0 (slope {1 - E:+.2f}) and {1 - E:.2f} (slope {E - 1:+.2f}); yield {E * max(1 - E, 0):.2f}")
for mu in (0.25, -0.25):
    print(f"pitchfork x' = mu x - x^3, mu {mu}: rest 0 (slope {mu:+.2f})" + (f"; +-{sqrt(mu):.2f} (slope {-2 * mu:+.2f})" if mu > 0 else ""))
px, py = lambda h: 60 + 900 * h, lambda x: 200 - 160 * x
pts = [(0, 0), (0.25, 0.25), (0.25, 0.5), (0.25, 0.75), (0, 1), (0.21, 0.3), (0.21, 0.7), (0.26, 0.5)]
print("figure,", " ".join(f"({h},{x})->({px(h):g},{py(x):g})" for h, x in pts))
print("ALL CHECKS PASS")
