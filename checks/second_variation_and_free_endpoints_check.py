# The second variation and free ends -- the check behind the card.  Standard library only.
# J[y] = integral from 0 to T of (y'^2 - y^2) dt, y(0) = y(T) = 0: the second-order part of a route's
# length along the equator of a unit sphere.  Then a pipe from (0, 0) to anywhere on the coast y = 2 - x.
from math import sin, cos, tan, pi, sqrt
R = 6371.0                                            # Earth's radius in km, Earth taken as a sphere
def simpson(f, a, b, n=2000):                         # Simpson's rule, written out here
    w = (b - a) / n
    return w / 3 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * w) for k in range(1, n)))
J = lambda e, de, T: simpson(lambda t: de(t) ** 2 - e(t) ** 2, 0, T)     # J from a shape and its slope
trial = lambda T: J(lambda t: sin(pi * t / T), lambda t: pi / T * cos(pi * t / T), T)
closed = lambda T: pi ** 2 / (2 * T) - T / 2           # the same integral, done by hand
print("J of the trial sin(pi t/T), T = 1, 1.5, ..., 5:", ", ".join(f"{trial(k / 2):.4f}" for k in range(2, 11)))
j4, j3 = trial(4.0), trial(3.0)
print(f"T = 4: Simpson {j4:.6f}, by hand 2(pi^2/16 - 1) = {2 * (pi ** 2 / 16 - 1):.6f}; T = 3: {j3:.6f}")
def conjugate(h=1e-3):                                # RK4 on the Jacobi equation u'' = -u, u(0) = 0, u'(0) = 1
    t, u, v = 0.0, 0.0, 1.0
    while True:
        f = lambda a, b: (b, -a)
        k1 = f(u, v); k2 = f(u + h / 2 * k1[0], v + h / 2 * k1[1])
        k3 = f(u + h / 2 * k2[0], v + h / 2 * k2[1]); k4 = f(u + h * k3[0], v + h * k3[1])
        un = u + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        v += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        if t > 1 and un <= 0:
            return t + h * u / (u - un)               # straight-line guess between the last two steps
        t, u = t + h, un
tc = conjugate()
print(f"Legendre: F_pp = 2 > 0.  Jacobi field returns to 0 at t = {tc:.6f} = pi = {pi:.6f}, {pi * R:.0f} km on Earth")
def gap(T, eps):                                      # exact sphere length minus T, latitude eps sin(pi t/T)
    s = lambda t: sqrt((eps * pi / T * cos(pi * t / T)) ** 2 + cos(eps * sin(pi * t / T)) ** 2)
    return simpson(s, 0, T, 4000) - T
for T in (4.0, 3.0):
    g, q = gap(T, 0.01) * R * 1000, 0.01 ** 2 / 2 * trial(T) * R * 1000
    print(f"sphere, T = {T:.0f} rad = {T * R:.0f} km, bulge 0.01 rad = {0.01 * R:.1f} km north: change {g:.1f} m, from J {q:.1f} m")
    assert abs(g - q) < 1e-3 * abs(q)                 # J really is the second-order part of the length
d = 0.07                                              # Riccati road at T = 3: w = cot(t + d), sin(t + d) > 0
w = lambda t: 1 / tan(t + d)
lhs = J(lambda t: t * (3 - t), lambda t: 3 - 2 * t, 3.0)
rhs = simpson(lambda t: (3 - 2 * t - w(t) * t * (3 - t)) ** 2, 0, 3.0)
print(f"T = 3, eta = t(3 - t): J = {lhs:.6f}, integral of (eta' - w eta)^2 = {rhs:.6f}")
print(f"T = pi, trial sin t: J = {abs(trial(pi)):.6f}")
lo, hi, dist = 0.0, 2.0, lambda s: sqrt(s * s + (2 - s) ** 2)        # pipe end at (s, 2 - s) on the coast
for _ in range(100):                                  # golden-section search for the nearest coast point
    a, b = hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)
    lo, hi = (lo, b) if dist(a) < dist(b) else (a, hi)
s = (lo + hi) / 2
p = 1.0                                               # slope y' = 1 from the transversality condition 1 + c' y' = 0
print(f"pipe, search: ends at ({s:.4f}, {2 - s:.4f}), length {dist(s):.4f} km")
print(f"pipe, transversality F + (c' - y') F_p at y' = 1, c' = -1: {sqrt(1 + p * p) + (-1 - p) * p / sqrt(1 + p * p):.6f}")
print(f"mistake, flip the sign, integral of (y^2 - y'^2) on T = 1 with sin(pi t): {-trial(1.0):.4f}")
print(f"mistake, end condition y' = 0 (pipe due east to (2, 0)): {dist(2.0):.4f} km, {dist(2.0) - dist(s):.4f} too long")
assert abs(j4 - closed(4.0)) < 1e-9 and j4 < 0 < j3  # Simpson = hand integral; sign flips past pi
assert abs(tc - pi) < 1e-6                            # RK4 conjugate point = pi, the zero of sin t
assert abs(lhs - 0.9) < 1e-9 and abs(rhs - lhs) < 1e-6  # completing the square, T < pi
assert abs(s - 1) < 1e-6 and abs(dist(s) - sqrt(2)) < 1e-9  # search lands where transversality says
print("ALL CHECKS PASS")
