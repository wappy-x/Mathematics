# Kirchhoff and Huygens: a handclap heard 17.15 m away, in space (3D) and in a flat world (2D).
# 3D roads: the closed form from r*u obeying the 1-D wave equation; Kirchhoff's sphere mean by
# Simpson's rule; the equation's residual by centred differences. 2D roads: Poisson's formula
# around the clap, by elliptic integrals; descent, the 3D sphere mean of a cylinder, around the
# listener; a tail series for late times.
from math import pi, sqrt, asin, acos, sin, cos
C, R, A, V = 343.0, 17.15, 0.1715, 2.4e5  # m/s, m, m, Pa/s (illustrative peak rate of the clap)
ms = 1e-3

def g(s):  # the clap: the rate at which the pressure starts rising, Pa/s, at distance s from its centre
    return V * (1 - s * s / (A * A)) ** 2 if s < A else 0.0

def simpson(f, lo, hi, n):  # n even
    h = (hi - lo) / n
    tot = f(lo) + f(hi) + sum((4 if j % 2 else 2) * f(lo + j * h) for j in range(1, n))
    return tot * h / 3

def u3_closed(r, t):  # 3D: r*u is a 1-D wave, so u = V a^2 (1 - d^2/a^2)^3 / (12 c r), d = r - c t
    d = r - C * t
    return V * A * A * (1 - d * d / (A * A)) ** 3 / (12 * C * r) if abs(d) < A else 0.0

def u3_mean(r, t):  # 3D: Kirchhoff, t times the mean of g over the sphere of radius c t around the listener
    rho = C * t
    mu0 = max(-1.0, (r * r + rho * rho - A * A) / (2 * r * rho))
    if mu0 >= 1: return 0.0
    return t * 0.5 * simpson(lambda mu: g(sqrt(max(0.0, r * r + rho * rho - 2 * r * rho * mu))), mu0, 1.0, 400)

def K(k):  # complete elliptic integral of the first kind, by the arithmetic-geometric mean
    a, b = 1.0, sqrt(1 - k * k)
    while abs(a - b) > 1e-15 * a: a, b = (a + b) / 2, sqrt(a * b)
    return pi / (2 * a)

def ring(s, t):  # integral over the clap's ring of radius s of 1/sqrt(c^2 t^2 - |y - x|^2), by angle
    P, Q = (C * t) ** 2 - R * R - s * s, 2 * s * R
    if P <= -Q: return 0.0
    if P >= Q: return 4 * K(sqrt(2 * Q / (P + Q))) / sqrt(P + Q)
    return 4 * K(sqrt((P + Q) / (2 * Q))) / sqrt(2 * Q)

def u2_poisson(t, n=1000):  # 2D: Poisson's formula, (1/(2 pi c)) times the ring integrals, summed over s
    cuts = sorted({0.0, A} | {x for x in (C * t - R, R - C * t) if 0 < x < A})
    tot = 0.0
    for p, q in zip(cuts, cuts[1:]):  # cosine-spaced midpoints soften the log spikes at the cuts
        for j in range(n):
            tau = (j + 0.5) / n
            s = p + (q - p) * (1 - cos(pi * tau)) / 2
            tot += s * g(s) * ring(s, t) * (q - p) * pi / 2 * sin(pi * tau) / n
    return tot / (2 * pi * C)

def u2_descent(t, n=200):  # 2D by descent: the 3D sphere mean of a cylinder, flattened onto the plane
    rho = C * t
    if rho <= R - A: return 0.0
    al = asin(A / R)
    lo, hi = asin((R - A) / rho), asin(min(1.0, (R + A) / rho))
    def inner(ph):
        return simpson(lambda ps: g(sqrt(max(0.0, R * R + (rho * sin(ps)) ** 2 + 2 * R * rho * sin(ps) * cos(ph)))) * sin(ps), lo, hi, n)
    return t / (2 * pi) * 2 * simpson(inner, pi - al, pi, n)

def u2_tail(t):  # 2D after the pulse: series in a^2/D, with D = c^2 t^2 - R^2
    D = (C * t) ** 2 - R * R
    return V * A * A / (6 * C * sqrt(D)) * (1 + A * A / 4 * (1 / (2 * D) + 3 * R * R / (4 * D * D)))

def u2_circle(t):  # the mistake: Kirchhoff's surface-only shape used in 2D, t times the mean over a circle
    rho = C * t
    m = (R * R + rho * rho - A * A) / (2 * R * rho)  # the circle meets the clap where cos(ph) > m
    if m >= 1: return 0.0
    return t / pi * simpson(lambda ph: g(sqrt(max(0.0, R * R + rho * rho - 2 * R * rho * cos(ph)))), 0.0, acos(max(-1.0, m)), 4000)

def resid(t, h):  # u_tt - c^2 (u_rr + 2 u_r / r) by centred differences, relative to c^2 u_rr
    k = h / (2 * C)  # a time step that is not the r-step over c, so the test is not exact by luck
    utt = (u3_closed(R, t + k) - 2 * u3_closed(R, t) + u3_closed(R, t - k)) / (k * k)
    urr = (u3_closed(R + h, t) - 2 * u3_closed(R, t) + u3_closed(R - h, t)) / (h * h)
    ur = (u3_closed(R + h, t) - u3_closed(R - h, t)) / (2 * h)
    return (utt - C * C * (urr + 2 * ur / R)) / (C * C * urr)

print(f"setup: c = {C:.0f} m/s, listener at R = {R:.2f} m, clap radius a = {A:.4f} m, peak rate V = {V:.0f} Pa/s")
print(f"sound can arrive only from (R - a)/c = {(R - A) / C / ms:.3f} ms to (R + a)/c = {(R + A) / C / ms:.3f} ms in 3D")
print(f"by hand: Q = {pi * V * A * A / 3:.0f} Pa m^2/s, D at 100 ms = {(C * 0.1) ** 2 - R * R:.1f} m^2, shell 2a = {200 * A:.1f} cm")
print(f"by hand: R - ct at 49.75 ms = {R - C * 49.75 * ms:.5f} m, at 50.60 ms = {R - C * 50.6 * ms:.4f} m")
print("3D pressure at the listener, Pa: time, closed form, Kirchhoff sphere mean")
for tm in (49.40, 49.75, 50.00, 50.25, 51.00, 100.0):
    a3, b3 = u3_closed(R, tm * ms), u3_mean(R, tm * ms)
    print(f"  {tm:7.2f} ms  {a3:.6f}  {b3:.6f}")
    assert abs(a3 - b3) < 1e-9
assert u3_mean(R, 50.6 * ms) == 0 and u3_mean(R, 100 * ms) == 0  # Huygens: silence once the shell has passed
r1, r2 = resid(49.9 * ms, 2e-3), resid(49.9 * ms, 1e-3)
print(f"3D residual of the wave equation at 49.90 ms: step 2 mm {r1:.3e}, step 1 mm {r2:.3e}, ratio {r1 / r2:.2f}")
assert abs(r1) < 1e-3 and 3.5 < r1 / r2 < 4.5
print("2D pressure at the listener, Pa: time, Poisson by elliptic integrals, descent")
for tm in (49.40, 49.75, 50.00, 50.25, 50.50, 51.00):
    a2, b2 = u2_poisson(tm * ms), u2_descent(tm * ms)
    print(f"  {tm:7.2f} ms  {a2:.6f}  {b2:.6f}")
    assert abs(a2 - b2) <= 1e-4 * a2 + 1e-9
assert u2_poisson(49.4 * ms) == 0 and u2_descent(49.4 * ms) == 0  # nothing outruns c, in 2D too
pk, tpk = max((u2_poisson(x * ms, 400), x) for x in [49.5 + 0.02 * j for j in range(76)])
lo, hi = tpk - 0.02, tpk + 0.02  # refine the grid's best by golden-section search, ms
for _ in range(40):
    m1, m2 = hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)
    if u2_poisson(m1 * ms) < u2_poisson(m2 * ms): lo = m1
    else: hi = m2
tpk = (lo + hi) / 2
pk = u2_poisson(tpk * ms)
print(f"2D peak: {pk:.4f} Pa at {tpk:.3f} ms")
print("2D tail, Pa: time, Poisson, descent, tail series, crude Q/(2 pi c^2 t)")
tails = {}
for tm in (55.0, 60.0, 70.0, 100.0, 200.0, 500.0, 1000.0):
    t = tm * ms
    a2, b2, c2, d2 = u2_poisson(t), u2_descent(t), u2_tail(t), V * A * A / (6 * C * C * t)
    tails[tm] = a2
    print(f"  {tm:7.1f} ms  {a2:.6f}  {b2:.6f}  {c2:.6f}  {d2:.6f}")
    assert abs(a2 - c2) < 1e-4 * c2 and abs(b2 - c2) < 1e-4 * c2
D5 = (C * 55 * ms) ** 2 - R * R  # the tail series' first omitted terms, all of size a^4, at 55 ms
om = A ** 4 * (3 / (80 * D5 ** 2) + 3 * R * R / (16 * D5 ** 3) + 21 * R ** 4 / (128 * D5 ** 4))
gap = tails[55.0] / u2_tail(55 * ms) - 1
print(f"tail series at 55 ms: first omitted terms {om:.3e} of the tail; Poisson above the series by {gap:.3e}")
assert abs(gap - om) < 0.1 * om  # the series misses by its first omitted terms
print(f"tail as a share of the peak: 3D 0 after {(R + A) / C / ms:.3f} ms; 2D {tails[100.0] / pk:.4f} at 100 ms, {tails[1000.0] / pk:.4f} at 1 s")
p3 = u3_closed(R, 50 * ms)  # the charts from 49 ms to 53 ms, each as a percent of its own peak
print(f"chart 3D, % of peak: {', '.join(f'{100 * u3_closed(R, (49 + 0.25 * j) * ms) / p3:.1f}' for j in range(17))}")
print(f"chart 2D, % of peak: {', '.join(f'{100 * u2_poisson((49 + 0.25 * j) * ms, 400) / pk:.1f}' for j in range(17))}")
print(f"chart tail 2D: {', '.join(f'{u2_tail(x * ms):.4f}' for x in (60, 80, 100, 150, 200, 300, 500, 700, 1000))}")
w1, w2, w3 = u3_mean(R, 50 * ms) / (50 * ms), u2_circle(50 * ms), u2_circle(51 * ms)
print(f"no factor t, 3D at 50.00 ms: {w1:.4f} Pa/s, not {u3_closed(R, 50 * ms):.4f} Pa")
print(f"circle only, 2D: {w2:.6f} Pa at 50.00 ms, {w3:.6f} Pa at 51.00 ms; true {u2_poisson(50 * ms):.6f} and {u2_poisson(51 * ms):.6f} Pa")
assert w3 == 0 and u2_poisson(51 * ms) > 0.25 * pk and abs(w1 * 50 * ms - u3_closed(R, 50 * ms)) < 1e-9
print("ALL CHECKS PASS")
