# Phase portraits and nullclines.  Gazelles x (hundreds), cheetahs y (tens), years: x' = x(1 - y),
# y' = y(x - 1).  Road one: signs of the rates.  Road two: Runge-Kutta 4.  Referee: the conserved V.
from math import log
def f(x, y): return x * (1 - y)                 # gazelle rate, hundreds per year
def g(x, y): return y * (x - 1)                 # cheetah rate, tens per year
def V(x, y): return x - log(x) + y - log(y)     # constant along every orbit
def sg(v): return "+" if v > 0 else "-" if v < 0 else "0"
def reg(x, y): return ("N" if y > 1 else "S") + ("E" if x > 1 else "W")
def p(x, y): return f"{50 + 70 * x:.1f},{205 - 70 * y:.1f}"   # figure scale, 70 px a unit
def rk4(x, y, h, F=f):
    k = lambda a, b: (F(a, b), g(a, b))          # the two rates at one point
    a1, b1 = k(x, y); a2, b2 = k(x + h * a1 / 2, y + h * b1 / 2)
    a3, b3 = k(x + h * a2 / 2, y + h * b2 / 2); a4, b4 = k(x + h * a3, y + h * b3)
    return x + h * (a1 + 2 * a2 + 2 * a3 + a4) / 6, y + h * (b1 + 2 * b2 + 2 * b3 + b4) / 6
def run(h, T, F=f, x=2.0, y=1.0):
    for _ in range(round(T / h)): x, y = rk4(x, y, h, F)
    return x, y
x, y, t, seen, when, box, pts, ok = 2.0, 1.0, 0.0, ["NE"], [], [2, 2, 1, 1], [p(2, 1)], True
while len(seen) < 5:                            # road two: one full turn from (2, 1)
    nx, ny = rk4(x, y, 0.01)
    if reg(nx, ny) == reg(x, y): ok = ok and sg(nx - x) + sg(ny - y) == sg(f(x, y)) + sg(g(x, y))
    elif t > 0:
        s = (1 - x) / (nx - x) if (x > 1) != (nx > 1) else (1 - y) / (ny - y)
        seen.append(reg(nx, ny)); when.append(t + s * 0.01)
    x, y, t = nx, ny, t + 0.01
    box = [min(box[0], x), max(box[1], x), min(box[2], y), max(box[3], y)]
    if round(t * 100) % 25 == 0: pts.append(p(x, y))
def root(lo, hi, c):                            # bisection on u - ln u = c
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if (mid - log(mid) > c) == (lo - log(lo) > c) else (lo, mid)
    return lo
tests = [(2, 0.5), (2, 2), (0.5, 2), (0.5, 0.5)]
mixed = [(a, b) for a, b in [(0, 0), (1, 0), (0, 1), (1, 1)] if (a == 0 or b == 1) and (b == 0 or a == 1)]
grid = [(i / 100, j / 100) for i in range(301) for j in range(301) if f(i / 100, j / 100) == 0 == g(i / 100, j / 100)]
print("x' = x(1 - y), y' = y(x - 1); x-nullclines x = 0 and y = 1; y-nullclines y = 0 and x = 1")
print(f"rests at mixed crossings: {mixed}; by grid scan of 301 x 301 points: {grid}")
print(f"same-kind crossing (0, 1): x' = {f(0, 1):.3f}, y' = {g(0, 1):.3f}; (1, 0): x' = {f(1, 0):.3f}, y' = {g(1, 0):.3f}")
for a, b in tests:
    print(f"region {reg(a, b)}, test point ({a}, {b}): x' = {f(a, b):+.3f}, y' = {g(a, b):+.3f}, signs {sg(f(a, b))}{sg(g(a, b))}")
print(f"start (2, 1) on the x-nullcline: x' = {f(2, 1):.3f}, y' = {g(2, 1):.3f}, straight up")
print(f"RK4 h = 0.01, regions in order: {' '.join(seen)}; every step's signs match its region: {'yes' if ok else 'no'}")
print(f"crossing times (years): {' '.join(f'{w:.3f}' for w in when)}; one turn T = {when[-1]:.3f}")
print(f"extremes by RK4: x {box[0]:.4f} to {box[1]:.4f}, y {box[2]:.4f} to {box[3]:.4f}; V = {V(2, 1):.4f}")
print(f"ln 2 = {log(2):.4f}; bisection on u - ln u = {V(2, 1) - 1:.4f}: low {(lo := root(0.01, 1, V(2, 1) - 1)):.4f}, high {(hi := root(1, 10, V(2, 1) - 1)):.4f}")
ref = run(0.001, 2)                             # a fine run is the yardstick for step-size error
e = [((a - ref[0]) ** 2 + (b - ref[1]) ** 2) ** 0.5 for a, b in (run(0.2, 2), run(0.1, 2))]
print(f"error at t = 2 against h = 0.001, in millionths: h = 0.2 {e[0] * 1e6:.3f}, h = 0.1 {e[1] * 1e6:.3f}, ratio {e[0] / e[1]:.1f}")
far = sum((a - b) ** 2 for a, b in zip(run(0.01, 20, lambda x, y: x * (1 - y - 0.2 * x), 2.0, 0.8), (1, 0.8))) ** 0.5
print(f"crowded gazelles x' = x(1 - y - 0.2x): distance to rest (1, 0.8) from 1.000 to {far:.3f} after 20 years")
print("figure, loop at 70 px a unit:", " ".join(pts))
print("figure, arrows:", " ".join(p(a, b) + ">" + p(a + 0.3 * f(a, b) / r, b + 0.3 * g(a, b) / r)
      for a, b in tests for r in [(f(a, b) ** 2 + g(a, b) ** 2) ** 0.5]))   # 0.3-unit arrows
cs = [run(0.01, k / 2) for k in range(15)]
for i, name in ((0, "gazelles"), (1, "cheetahs")): print(f"chart, {name}:", ", ".join(f"{c[i]:.2f}" for c in cs))
assert grid == [(float(a), float(b)) for a, b in mixed]           # two roads to the rests
assert seen == ["NE", "NW", "SW", "SE", "NE"] and ok             # the flow follows the sign table
assert max(abs(box[0] - lo), abs(box[2] - lo), abs(box[1] - hi), abs(box[3] - hi)) < 1e-4   # RK4 loop sits on V's level
assert 12 < e[0] / e[1] < 20 and far < 0.3                       # order 4; crowding spirals in
print("ALL CHECKS PASS")
