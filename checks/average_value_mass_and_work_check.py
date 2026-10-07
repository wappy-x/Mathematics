# Averages, mass and work -- the check behind the card.  Standard library only:
# math.pi and math.sqrt are primitives; every integral is our own midpoint sum.
import math

def mid(f, a, b, n):                     # n midpoint rectangles from a to b
    h = (b - a) / n
    return sum(f(a + (k + 0.5) * h) for k in range(n)) * h
def row(xs, p): return "[" + ", ".join(f"{x:.{p}f}" for x in xs) + "]"

# The day: T(t) = 10 + t(24 - t)/10 degrees C, t in hours after midnight.
def T(t): return 10 + t * (24 - t) / 10
def TA(t): return 10 * t + (12 * t * t - t ** 3 / 3) / 10     # antiderivative of T
total = TA(24) - TA(0)
mean = total / 24
print(f"day: integral of T = {total:.1f} degree-hours; mean = {total:.1f} / 24 = {mean:.4f} C")
print("mean by midpoint strips, n = 24, 240, 2400: " + row([mid(T, 0, 24, n) / 24 for n in (24, 240, 2400)], 6))
assert abs(mid(T, 0, 24, 2400) / 24 - mean) < 1e-6                  # sums against antiderivative
print(f"24 hourly readings averaged {sum(T(k) for k in range(24)) / 24:.4f}; (max + min)/2 = {(T(12) + T(0)) / 2:.1f}")
lo, hi = 0.0, 12.0                       # bisection: when, before noon, is T = mean?
for _ in range(60):
    c = (lo + hi) / 2
    lo, hi = (c, hi) if T(c) < mean else (lo, c)
root = 12 - math.sqrt(144 - 10 * (mean - 10))                        # quadratic formula
print(f"T = mean at t = {lo:.4f} h by bisection, {root:.4f} h by formula; again at {24 - root:.4f} h")
assert abs(lo - root) < 1e-9
print("chart, T at t = 0, 2, ..., 24: " + row([T(t) for t in range(0, 25, 2)], 2) + f"; mean line {mean:.2f}")
# The tank: a cone, point down, 4 m deep, rim radius 2 m, full of water, pumped out over the rim.
RHO, G, H, R = 1000, 9.81, 4, 2          # kg per m^3, N per kg, m, m
def lam(y): return RHO * math.pi * (R * y / H) ** 2                 # kg per metre of height
def LA(y): return RHO * math.pi * (R / H) ** 2 * y ** 3 / 3          # antiderivative of lam
def WA(y): return G * RHO * math.pi * (R / H) ** 2 * (H * y ** 3 / 3 - y ** 4 / 4)
mass, work = LA(H) - LA(0), WA(H) - WA(0)
cone = RHO * math.pi * R * R * H / 3     # cone volume, one third of the cylinder: no calculus
print(f"mass by antiderivative {mass:.1f} kg; by cone volume x density {cone:.1f} kg")
assert abs(mid(lam, 0, H, 4000) - cone) < 1e-3 and abs(mass - cone) < 1e-9   # sums, antiderivative, geometry
slabs = [lam(y) for y in (0.5, 1.5, 2.5, 3.5)]
print(f"four 1 m slabs, masses {row(slabs, 1)}, total {sum(slabs):.1f} kg")
print("mass by strips, n = 4, 40, 400: " + row([mid(lam, 0, H, n) for n in (4, 40, 400)], 1))
def wf(y): return G * lam(y) * (H - y)   # newtons per metre of height, times the lift
print("work by strips, n = 4, 40, 400: " + row([mid(wf, 0, H, n) for n in (4, 40, 400)], 1))
print(f"work by antiderivative {work:.1f} J; mass x g x 1 m = {mass * G * 1:.1f} J")
assert abs(mid(wf, 0, H, 4000) - work) < 1e-2                      # sums against antiderivative
print(f"spring, F = 200x N from 0 to 0.3 m: strips {mid(lambda x: 200 * x, 0, 0.3, 4):.4f} J; 100 x 0.3^2 = "
      f"{100 * 0.3 ** 2:.4f} J; the spring's own pull does {mid(lambda x: -200 * x, 0, 0.3, 4):.4f} J")
step = mid(lambda t: 10 if t < 12 else 20, 0, 24, 2400) / 24
print(f"break, heater step 10 C then 20 C at noon: mean {step:.4f} C, yet T is only 10 or 20")
print(f"break, lift measured from the tip, y not 4 - y: {G * RHO * math.pi * (R / H) ** 2 * H ** 4 / 4:.1f} J")
print(f"break, tank taken as a cylinder of radius 2 m: {RHO * math.pi * R * R * H:.1f} kg")
print(f"figure, tip (180, 210); rim (100, 50) to (260, 50); slab at y = 2 m: x {180 - 40 * 1:.0f} to "
      f"{180 + 40 * 1:.0f} at svg y {210 - 40 * 2:.0f}, {180 - 40 * 1.125:.0f} to {180 + 40 * 1.125:.0f} at {210 - 40 * 2.25:.0f}")
print("ALL CHECKS PASS")
