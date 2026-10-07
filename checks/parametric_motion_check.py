# Parametric motion -- the check behind the card.  Standard library only.
# A ball leaves the hand at 12 m/s across and 16 m/s up; gravity 9.8 m/s^2.
# Road one: the derivative formulas.  Road two: shrinking difference quotients
# of the position itself, and of the path with the clock removed.
import math
U, W, G = 12.0, 16.0, 9.8                    # across speed, up speed, gravity

def pos(t): return (U * t, W * t - G * t * t / 2)       # metres after t s
def vel(t): return (U, W - G * t)                       # road one: the formulas
def speed(v): return math.sqrt(v[0] ** 2 + v[1] ** 2)
def graph(x): return (W / U) * x - G * x * x / (2 * U * U)  # y from x, t removed

lo, hi = 0.0, 3.0                          # the top, found without the formula:
for _ in range(60):                        # halve the interval where y still climbs
    m = (lo + hi) / 2
    lo, hi = (m, hi) if pos(m + 1e-9)[1] > pos(m)[1] else (lo, m)
top = W / G
xt, yt = pos(top)
print(f"thrown at {U:.0f} m/s across, {W:.0f} m/s up, gravity {G} m/s^2, half of it {G / 2}")
print(f"top: t = {top:.4f} s by W/G, {lo:.4f} s by halving; x = {xt:.4f} m, y = {W * W:.0f}/{2 * G:.1f} = {yt:.4f} m")
print(f"velocity at the top ({vel(top)[0]:.4f}, {abs(vel(top)[1]):.4f}) m/s, speed {speed(vel(top)):.4f} m/s")
fwd = [math.dist(pos(top + h), pos(top)) / h for h in (0.1, 0.01, 0.001)]
print("distance per second just after the top, h = 0.1, 0.01, 0.001 s: " + ", ".join(f"{s:.6f}" for s in fwd))
print(f"at release: speed {speed(vel(0)):.4f} m/s, dy/dx {vel(0)[1] / vel(0)[0]:.4f}")
p1, v1 = pos(1), vel(1)
print(f"t = 1 s: position ({p1[0]:.4f}, {p1[1]:.4f}) m, velocity ({v1[0]:.4f}, {v1[1]:.4f}) m/s, speed sqrt({v1[0] ** 2:.2f} + {v1[1] ** 2:.2f}) = {speed(v1):.4f} m/s")
slope = v1[1] / v1[0]
qs = [(graph(p1[0] + k) - graph(p1[0])) / k for k in (1.0, 0.1, 0.01, 0.0001)]
print(f"dy/dx at t = 1 s: {slope:.6f} by (dy/dt)/(dx/dt); from y(x), step 1, 0.1, 0.01, 0.0001 m: " + ", ".join(f"{q:.6f}" for q in qs))
hs = [(pos(1 + h)[1] - pos(1)[1]) / h - v1[1] for h in (0.01, 0.001, 0.0002)]
print("forward quotient error in dy/dt at t = 1 s, h = 0.01, 0.001, 0.0002: " + ", ".join(f"{e:.6f}" for e in hs) + f"; within 0.001 once h < {0.001 / (G / 2):.6f}")
k = 0.001
acc = [(pos(1 + k)[i] - 2 * pos(1)[i] + pos(1 - k)[i]) / (k * k) for i in (0, 1)]
land = 2 * W / G
print(f"acceleration by second differences ({abs(acc[0]):.4f}, {acc[1]:.4f}) m/s^2; lands at t = {land:.4f} s, x = {pos(land)[0]:.4f} m")
print("chart, speed at t = 0, 0.5, ..., 3 s: " + ", ".join(f"{speed(vel(i / 2)):.2f}" for i in range(7)))
sx = lambda x: 24 + 8 * x
sy = lambda y: 200 - 8 * y
print(f"figure, 8 units per m: release (24, 200), top ({sx(xt):.2f}, {sy(yt):.2f}), landing ({sx(pos(land)[0]):.2f}, 200), "
      f"curve control ({sx(xt):.2f}, {sy(2 * yt):.2f})")
print(f"figure, arrow ends (velocity x 0.5 s): ({sx(U / 2):.2f}, {sy(W / 2):.2f}), ({sx(p1[0] + v1[0] / 2):.2f}, {sy(p1[1] + v1[1] / 2):.2f}), "
      f"({sx(xt + U / 2):.2f}, {sy(yt):.2f}); t = 1 s point ({sx(p1[0]):.2f}, {sy(p1[1]):.2f})")
print(f"mistake 1, speed at the top read off dy/dt alone: {abs(vel(top)[1]):.4f}, not {speed(vel(top)):.4f}")
print(f"mistake 2, slope at t = 1 s taken as dy/dt: {v1[1]:.4f}, not {slope:.4f}")
print(f"mistake 3, speed at release as dx/dt + dy/dt: {U + W:.4f}, not {speed(vel(0)):.4f}; ratio upside down: {U / W:.4f}")
print(f"straight up at 16 m/s: at t = 1 s, dx/dt = 0 and dy/dt = {W - G:.4f}, so (dy/dt)/(dx/dt) has no value")
assert abs(lo - top) < 1e-6                              # the top, two roads
assert abs(fwd[-1] - speed(vel(top))) < 0.001            # distance per second -> speed
assert abs(qs[-1] - slope) < 1e-4                        # clock removed -> same slope
assert abs(acc[1] + G) < 1e-3 and abs(acc[0]) < 1e-6     # second differences -> gravity
print("ALL CHECKS PASS")
