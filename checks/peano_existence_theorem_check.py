# Peano's theorem -- the check behind the card.  Standard library only.
# Euler polygons for y' = sqrt|y| and y' = 1 + y^2, both from y(0) = 0, are
# compared with exact solutions (0, t^2/4, tan t), with the integral equation
# they converge to, and with the blow-up time found as an area by Simpson's rule.
import math
def euler(f, y0, t_end, h):                 # corner values of the polygon at t = 0, h, 2h, ...
    ys = [y0]
    for _ in range(round(t_end / h)):
        ys.append(ys[-1] + h * f(ys[-1]))   # new value = old value + step x rate
    return ys
def simpson(g, a, b, n=1000):               # area under g from a to b, n even
    w = (b - a) / n
    return w / 3 * sum(g(a + i * w) * (1 if i in (0, n) else 4 if i % 2 else 2) for i in range(n + 1))
def residual(f, ys, h):                     # largest |y(t) - integral of f(y) from 0 to t|, Simpson per piece
    area, worst = 0.0, 0.0
    for k in range(1, len(ys)):
        area += h * (f(ys[k - 1]) + 4 * f((ys[k - 1] + ys[k]) / 2) + f(ys[k])) / 6   # exact: f is quadratic here
        worst = max(worst, abs(ys[k] - area))
    return worst
sq, tn = (lambda y: math.sqrt(abs(y))), (lambda y: 1 + y * y)
hs = (0.1, 0.01, 0.001)
fmt = lambda xs, d: ", ".join(f"{x:.{d}f}" for x in xs)
stuck = [euler(sq, 0.0, 2, h)[-1] for h in hs]
late = lambda t: 0.0 if t < 1 else (t - 1) ** 2 / 4    # rests until t = 1, then rises
grid = [i / 100 for i in range(201)]        # do t^2/4 and late solve it? slopes by central difference
miss = max(abs((g(t + 1e-6) - g(t - 1e-6)) / 2e-6 - sq(g(t))) for g in (lambda s: s * s / 4, late) for t in grid)
ts = [i / 4 for i in range(9)]
nudged = euler(sq, 1e-6, 2, 0.001)[-1]
B = 1.0; M = tn(B); T = min(1.0, B / M)    # box: times 0 to 1, values -1 to 1
runs = [euler(tn, 0.0, T, h) for h in hs]
gaps = [max(abs(y - math.tan(k * h)) for k, y in enumerate(r)) for r, h in zip(runs, hs)]
slope = max(abs(r[k + 1] - r[k]) / h for r, h in zip(runs, hs) for k in range(len(r) - 1))
res = [residual(tn, r, h) for r, h in zip(runs, hs)]
t, y, h, marks, hit = 0.0, 0.0, 1e-6, (10, 100, 1000), []
while len(hit) < 3:                         # Euler until |y| leaves the boxes of size 10, 100, 1000
    y, t = y + h * tn(y), t + h
    if y > marks[len(hit)]: hit.append(t)
life = 2 * simpson(lambda u: 1 / tn(u), 0, 1)   # time to infinity = area under 1/(1 + u^2)
past = euler(tn, 0.0, 2, 0.1)[-1]
print(f"y' = sqrt|y|, y(0) = 0: Euler y(2) with h = 0.1, 0.01, 0.001: {fmt(stuck, 4)}")
print(f"t^2/4 and waits 1: largest |slope - sqrt(y)| on [0, 2] = {miss:.6f}; 2^2/4 = {2 * 2 / 4:.4f}")
print(f"chart t:        {fmt(ts, 2)}")
print(f"chart Euler:    {fmt([0.0 for _ in ts], 4)}")
print(f"chart t^2/4:    {fmt([s * s / 4 for s in ts], 4)}")
print(f"chart waits 1:  {fmt([late(s) for s in ts], 4)}")
print(f"start nudged to 0.000001, h = 0.001: Euler y(2) = {nudged:.6f}; exact (1 + 0.001)^2 = {1.001 ** 2:.6f}")
print(f"y' = 1 + y^2 in the box b = {B:.0f}: M = {M:.0f}, window T = min(1, b/M) = {T:.2f}")
print(f"Euler y(0.5) with h = 0.1, 0.01, 0.001: {fmt([r[-1] for r in runs], 6)}; tan 0.5 = {math.tan(0.5):.6f}")
print(f"largest gap to tan t on [0, 0.5]: {fmt(gaps, 6)}")
print(f"steepest polygon segment: {slope:.4f}, under the bound M = {M:.0f}")
print(f"integral-equation residual: {fmt(res, 6)}")
print(f"Euler (h = 0.000001) leaves |y| <= 10, 100, 1000 at t = {fmt(hit, 4)}")
print(f"arctan of 10, 100, 1000:                         {fmt([math.atan(m) for m in marks], 4)}")
print(f"blow-up time: 2 x area under 1/(1 + u^2) on [0, 1] = {life:.6f}; pi/2 = {math.pi / 2:.6f} = {math.pi / 2:.4f} to 4 places")
print(f"mistakes: tan 2 = {math.tan(2):.4f}; Euler h = 0.1 run to t = 2: {past:.1f}")
assert max(stuck) == 0.0 and miss < 1e-6 and abs(nudged - 1.001 ** 2) < 0.01   # two solutions, one start
assert gaps[2] < gaps[1] / 5 < gaps[0] / 25 and slope <= M                      # polygons converge to tan
assert res[2] < res[1] / 5 < res[0] / 25                                         # limit obeys the equation
assert all(abs(a - math.atan(m)) < 5e-5 for a, m in zip(hit, marks)) and abs(life - math.pi / 2) < 1e-9
print("ALL CHECKS PASS")
