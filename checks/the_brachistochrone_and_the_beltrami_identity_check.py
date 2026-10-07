# The brachistochrone -- the check behind the card.  Standard library only.  A slide
# from (0, 0) to 2 m across, 1 m down; y points DOWN.  Road 1: the Beltrami cycloid.
# Road 2: the fastest n-chute slide by golden-section search.  Ramp and arc: two roads.
from math import sin, cos, sqrt, pi
G, X, Y = 9.81, 2.0, 1.0

def bisect(f, a, b):                           # root finder written out here
    for _ in range(200):
        m = (a + b) / 2
        a, b = (m, b) if f(a) * f(m) > 0 else (a, m)
    return (a + b) / 2
def chute(xa, ya, xb, yb):                     # straight chute: length over mean speed
    return 2 * sqrt((xb - xa)**2 + (yb - ya)**2) / (sqrt(2*G*ya) + sqrt(2*G*yb))
def best_slide(n):                             # road 2: sweep the corners 25n times
    xs, ys = [X*i/n for i in range(n + 1)], [Y*i/n for i in range(n + 1)]
    for _ in range(25 * n):
        for i in range(1, n):
            f = lambda y: chute(xs[i-1], ys[i-1], xs[i], y) + chute(xs[i], y, xs[i+1], ys[i+1])
            a, b = 1e-12, 2.0
            for _ in range(60):
                m1, m2 = a + 0.382*(b - a), b - 0.382*(b - a)
                a, b = (a, m2) if f(m1) < f(m2) else (m1, b)
            ys[i] = (a + b) / 2
    return sum(chute(xs[i], ys[i], xs[i+1], ys[i+1]) for i in range(n)), xs, ys

def functional(y, dy, n=20000):                # T[y] = integral of sqrt((1+y'^2)/(2gy)) dx,
    total = 0.0                                # midpoint rule in s, where x = X s^4
    for k in range(n):
        s = (k + 0.5) / n; x = X * s**4
        total += 4*X*s**3 * sqrt((1 + dy(x)**2) / (2*G*y(x))) / n
    return total
th = bisect(lambda t: t - sin(t) - (X/Y)*(1 - cos(t)), 0.1, 6.2)
R = Y / (1 - cos(th)); T_cyc = th * sqrt(R/G)
cyc = lambda t: (R*(t - sin(t)), R*(1 - cos(t)))
print(f"cycloid: end angle {th:.4f} rad, rolling radius R = {R:.4f} m, lowest point {2*R:.4f} m down")
print(f"cycloid time, closed form theta*sqrt(R/g) = {th:.4f} x {sqrt(R/G):.4f} = {T_cyc:.4f} s")
bel = [cyc(t)[1] * (1 + ((cyc(t+1e-6)[1] - cyc(t-1e-6)[1]) / (cyc(t+1e-6)[0] - cyc(t-1e-6)[0]))**2)
       for t in (0.5, 1.5, 2.5, 3.4)]         # Beltrami's y(1+y'^2), slope by finite differences
print("Beltrami y(1+y'^2) at angles 0.5, 1.5, 2.5, 3.4: " + ", ".join(f"{b:.6f}" for b in bel) + f"; 2R = {2*R:.6f}")
polys = {n: best_slide(n) for n in (8, 16, 32)}
for n in polys: print(f"fastest {n:2d}-chute slide: {polys[n][0]:.4f} s, above the cycloid by {polys[n][0] - T_cyc:.4f} s")
_, xs, ys = polys[32]; gap = max(abs(ys[i] - cyc(bisect(lambda t: cyc(t)[0] - xs[i], 0, th))[1]) for i in range(33))
print(f"32-chute corners vs cycloid depth at the same x: largest gap {100*gap:.2f} cm")
T_ramp, T_ramp2 = sqrt(2*(X*X + Y*Y) / (G*Y)), functional(lambda x: Y*x/X, lambda x: Y/X)
print(f"straight ramp: closed form {T_ramp:.4f} s, by the functional {T_ramp2:.4f} s")
c = (X*X + Y*Y) / (2*X); ang = pi - bisect(lambda a: cos(a) - (X - c)/c, 0.0, 3.14); m = 20000
T_arc = sqrt(c/(2*G)) * sum(2*u/sqrt(sin(u*u)) for u in ((k + 0.5)*sqrt(ang)/m for k in range(m))) * sqrt(ang)/m
T_arc2 = functional(lambda x: sqrt(x*(2*c - x)), lambda x: (c - x)/sqrt(x*(2*c - x)))
print(f"circular arc, centre {c:.2f} m across, radius {c:.2f} m: by angle {T_arc:.4f} s, by the functional {T_arc2:.4f} s")
print(f"mistake, shortest = fastest: the ramp takes {T_ramp:.4f} s, {T_ramp - T_cyc:.4f} s slower")
print(f"mistake, speed sqrt(g y) not sqrt(2 g y): cycloid time comes out {T_cyc*sqrt(2):.4f} s")
print(f"mistake, slide must end level (C = 1 m, R = 0.5 m): it bottoms out at x = {0.5*pi:.4f} m, not 2")
print("figure, 150 px per m, origin (40, 30): cycloid " + " ".join(
      f"{40 + 150*cyc(th*k/12)[0]:.1f},{30 + 150*cyc(th*k/12)[1]:.1f}" for k in range(13)))
print(f"figure, arc radius {150*c:.1f} px, lowest ({40 + 150*c:.1f}, {30 + 150*c:.1f}); cycloid lowest ({40 + 150*pi*R:.1f}, {30 + 300*R:.1f})")
assert 0 < polys[32][0] - T_cyc < polys[16][0] - T_cyc < polys[8][0] - T_cyc < 0.02  # search never beats the cycloid
assert all(abs(b - 2*R) < 1e-5 for b in bel)                                        # Beltrami constant is 2R
assert abs(T_ramp - T_ramp2) < 1e-4 and abs(T_arc - T_arc2) < 1e-3                 # two roads each
assert T_cyc < T_arc < T_ramp                                                       # the order on the card
print("ALL CHECKS PASS")
