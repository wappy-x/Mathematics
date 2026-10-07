# Conservative fields -- the check behind the card.  Standard library only;
# math gives sqrt, sin and cos as primitives.  Road one adds F(r(t)).r'(t) by a
# Simpson sum written here; road two is the potential difference found by hand.
from math import sqrt, sin, cos

def simpson(f, n=200):               # integral of f over the clock t, from 0 to 1
    return (f(0) + f(1) + sum((4 if i % 2 else 2) * f(i / n) for i in range(1, n))) / (3 * n)
def work(F, legs):                   # road one: each leg is (position, velocity) on clock t
    return sum(simpson(lambda t: sum(a * b for a, b in zip(F(*r(t)), v(t)))) for r, v in legs)
def line(p, q):
    return (lambda t: (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t), lambda t: (q[0] - p[0], q[1] - p[1]))
def arc(rho, a, b): return (lambda t: (rho * cos(a + (b - a) * t), rho * sin(a + (b - a) * t)),
                            lambda t: (-rho * (b - a) * sin(a + (b - a) * t), rho * (b - a) * cos(a + (b - a) * t)))
def sq(cx, s): c = ((cx - s, -s), (cx + s, -s), (cx + s, s), (cx - s, s)); return [line(c[i], c[(i + 1) % 4]) for i in range(4)]
lo, hi = 1.0, 2.0                    # pi built, not imported: cos crosses 0 at pi/2
for _ in range(60): lo, hi = ((lo + hi) / 2, hi) if cos((lo + hi) / 2) > 0 else (lo, (lo + hi) / 2)
PI, z = lo + hi, lambda v: round(v, 6) + 0.0     # z prints a rounding-sized -0 as 0

bottle = lambda x, y: (0.0, -2 * 9.8)            # 2 kg, g = 9.8 m/s^2
A, B = (0, 0), (400, 300)
trails = {"straight": [line(A, B)], "curve (400t, 300t^2)": [(lambda t: (400 * t, 300 * t * t), lambda t: (400, 600 * t))],
          "three switchbacks": [line(A, (400, 100)), line((400, 100), (0, 200)), line((0, 200), B)]}
drop = -2 * 9.8 * B[1] - (-2 * 9.8 * A[1])      # road two: phi = -19.6 y, end minus start
print("bottle, 2 kg: gravity (0, -19.6) N; trailhead A (0, 0) m to hut B (400, 300) m")
for name, legs in trails.items():
    print(f"{name}: Simpson {work(bottle, legs):.6f} J; potential difference {drop:.6f} J")
g, R = 9.8, 6371000.0
k = g * R * R                                    # planet, per kg: F = -k (x, y) / r^3, phi = k / r
planet = lambda x, y: (-k * x / sqrt(x * x + y * y) ** 3, -k * y / sqrt(x * x + y * y) ** 3)
out, far = work(planet, [line((R, 0), (2 * R, 0))]), k / (2 * R) - k / R
detour = work(planet, [arc(R, 0, PI / 2), line((0, R), (0, 2 * R)), arc(2 * R, PI / 2, 0)])
print(f"planet, per kg, R = {R:.0f} m, R to 2R: straight out {out / 1e6:.4f} MJ; arc, out, arc back {detour / 1e6:.4f} MJ; k/2R - k/R {far / 1e6:.4f} MJ")
print(f"planet, 2 kg lifted 300 m: 2 (k/(R + 300) - k/R) = {2 * (k / (R + 300) - k / R):.2f} J; m g h = {-2 * g * 300:.2f} J")
whirl = lambda x, y: (-y / (x * x + y * y), x / (x * x + y * y))
unit = lambda x, y: (-x / sqrt(x * x + y * y) ** 3, -y / sqrt(x * x + y * y) ** 3)
def curl_parts(F, x, y, h=1e-5):                 # difference quotients: dQ/dx and dP/dy
    return (F(x + h, y)[1] - F(x - h, y)[1]) / (2 * h), (F(x, y + h)[0] - F(x, y - h)[0]) / (2 * h)
cp, cw = curl_parts(unit, 1, 2), curl_parts(whirl, 1, 2)
hand_p, hand_w = 3 * 1 * 2 / sqrt(5) ** 5, (2 * 2 - 1 * 1) / 5 ** 2
print(f"curl test at (1, 2), planet with k = 1: dQ/dx {cp[0]:.6f}, dP/dy {cp[1]:.6f}; by hand 3xy/r^5 = {hand_p:.6f}")
print(f"curl test at (1, 2), whirlpool: dQ/dx {cw[0]:.6f}, dP/dy {cw[1]:.6f}; by hand (y^2 - x^2)/r^4 = {hand_w:.6f}")
round1, round2, beside = work(whirl, sq(0, 1)), work(whirl, sq(0, 2)), work(whirl, sq(4, 1))
print(f"whirlpool, square round the drain, half-side 1: {round1:.6f}; half-side 2: {round2:.6f}; 2 pi = {2 * PI:.6f}")
print(f"whirlpool, square beside the drain, centre (4, 0), half-side 1: {z(beside):.6f}")
print(f"mistake 1, zero curl so every loop gives 0: predicts 0, the square gives {round1:.6f}")
print(f"mistake 2, integrate P in x and stop: potential {z(simpson(lambda t: 400 * bottle(400 * t, 0)[0])):.0f}, work 0 J, not {drop:.0f} J")
print(f"mistake 3, potential energy U = 19.6 y used as phi: {2 * 9.8 * 300:.0f} J, not {drop:.0f} J")
print(f"mistake 4, g h per kg for a climb of h = R: {-g * R / 1e6:.4f} MJ, not {far / 1e6:.4f} MJ")
X, Y = (lambda x: 50 + 0.6 * x), (lambda y: 210 - 0.6 * y)
print("figure 1, 0.6 units per m, curve:", " ".join(f"({X(400 * t / 8):.1f},{Y(300 * (t / 8) ** 2):.1f})" for t in range(9)))
print(f"figure 1, switchback corners: ({X(400):.0f},{Y(100):.0f}) ({X(0):.0f},{Y(200):.0f}); arrows 1 unit per N: "
      f"({X(100):.0f},{Y(250):.0f})->({X(100):.0f},{Y(250) + 19.6:.1f}) ({X(350):.0f},{Y(60):.0f})->({X(350):.0f},{Y(60) + 19.6:.1f})")
print("figure 2, drain at (120,120), 20 units per m, arrows 30 units per m/s:", " ".join(
    f"({120 + 20 * x:.0f},{120 - 20 * y:.0f})->({120 + 20 * x + 30 * whirl(x, y)[0]:.0f},{120 - 20 * y - 30 * whirl(x, y)[1]:.0f})"
    for x, y in ((1.5, 0), (0, 1.5), (-1.5, 0), (0, -1.5))))
assert all(abs(work(bottle, legs) - drop) < 1e-6 for legs in trails.values())  # road one against road two
assert abs(out / far - 1) < 1e-9 and abs(detour / far - 1) < 1e-9             # the planet, both routes
assert all(abs(c - hand) < 1e-7 for pair, hand in ((cp, hand_p), (cw, hand_w)) for c in pair)
assert abs(round1 - 2 * PI) < 1e-8 and abs(round2 - 2 * PI) < 1e-8 and abs(beside) < 1e-8
print("ALL CHECKS PASS")
