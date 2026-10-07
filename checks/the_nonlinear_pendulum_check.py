# The nonlinear pendulum -- the check behind the card.  Imports only math's
# sin, cos, asin, acos, sqrt, log and pi.  Time is counted in units of sqrt(l/g)
# and energy per m g l, so the swing obeys theta'' = -sin(theta).  Road one: the
# period integral by Simpson's rule.  Road two: RK4 steps that know no formula.
from math import sin, cos, asin, acos, sqrt, log, pi
G, L, TH0 = 9.81, 1.0, pi / 3; U = sqrt(L / G)         # 1 m rod, 60 degrees; one time unit in s
def energy(th, w): return 0.5 * w * w + 1 - cos(th)
def quarter(k2, n=400):                                # integral of 1/sqrt(1 - k2 sin^2) on [0, pi/2]
    h = pi / 2 / n
    f = lambda p: 1 / sqrt(1 - k2 * sin(p) ** 2)
    return h / 3 * (f(0) + f(pi / 2) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n)))
def rk4(th, w, h, c=0.0):                              # one Runge-Kutta 4 step; c = friction
    f = lambda a, b: (b, -sin(a) - c * b)
    a1, b1 = f(th, w); a2, b2 = f(th + h / 2 * a1, w + h / 2 * b1)
    a3, b3 = f(th + h / 2 * a2, w + h / 2 * b2); a4, b4 = f(th + h * a3, w + h * b3)
    return th + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4), w + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
def time_to(th, w, target, h):                         # step until theta passes target,
    t, s = 0.0, th - target                            # then bisect the length of the last step
    while (rk4(th, w, h)[0] - target) * s > 0: th, w = rk4(th, w, h); t += h
    lo, hi = 0.0, h
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if (rk4(th, w, mid)[0] - target) * s > 0 else (lo, mid)
    return t + lo
def run(th, w, t, h, step):                            # march a fixed time, return the energy
    for _ in range(round(t / h)): th, w = step(th, w, h)
    return energy(th, w)
euler = lambda th, w, h: (th + h * w, w - h * sin(th))
E0 = energy(TH0, 0.0); T_simp = 4 * quarter(E0 / 2)
T_rk = [4 * time_to(TH0, 0.0, 0.0, h) for h in (0.1, 0.05)]
err = [abs(t - T_simp) for t in T_rk]
jac = [(-sin(x + 1e-5) + sin(x - 1e-5)) / 2e-5 for x in (0.0, pi)]   # d(omega')/d(theta)
sep = (2 * cos((pi + 1e-5) / 2) - 2 * cos((pi - 1e-5) / 2)) / 2e-5    # separatrix slope at pi
Er = energy(0.0, 2.5); k = sqrt(2 / Er)                # the push of 2.5 goes over the top
print(f"energy at release, 60 deg: {E0:.6f}; standing on end at rest: {energy(pi, 0):.6f}")
print(f"bottom speed to reach the top: {sqrt(2 * energy(pi, 0)):.4f} units = {2 * sqrt(G * L):.3f} m/s")
print(f"lambda^2 = d(omega')/d(theta): at 0 {jac[0]:.6f} -> +-i, centre; at pi {jac[1]:.6f} -> +-1, saddle")
print(f"separatrix omega = 2 cos(theta/2), slope at pi: {sep:.6f}")
print(f"period at 60 deg, Simpson: {T_simp:.6f}; small-angle 2 pi: {2 * pi:.6f}; ratio {T_simp / (2 * pi):.4f}")
print(f"period at 60 deg, RK4 h = 0.1, 0.05: {T_rk[0]:.6f} {T_rk[1]:.6f}; errors {err[0]:.8f} {err[1]:.8f}, ratio {err[0] / err[1]:.1f}")
print(f"energy after one period, RK4 h = 0.1: {run(TH0, 0.0, T_simp, 0.1, rk4):.6f}")
print(f"1 m rod: one unit {U:.4f} s; period {T_simp * U:.3f} s against small-angle {2 * pi * U:.3f} s")
print("chart, period at E = 0.1, 0.5, 1.0, 1.5, 1.9, 1.99:", " ".join(f"{4 * quarter(e / 2):.2f}" for e in (0.1, 0.5, 1.0, 1.5, 1.9, 1.99)))
print(f"near the top, 2 ln(32/(2 - E)) at E = 1.9, 1.99: {2 * log(32 / 0.1):.2f} {2 * log(32 / 0.01):.2f}")
print(f"push 2.5 ({2.5 * sqrt(G * L):.3f} m/s): energy {Er:.4f}, speed at the top {sqrt(2 * (Er - 2)):.4f}, one turn Simpson {2 * k * quarter(k * k):.4f}, RK4 {time_to(0.0, 2.5, 2 * pi, 0.05):.4f}")
print(f"mistake 1, bottom speed sqrt(2 g l) = {sqrt(2 * G * L):.3f} m/s: energy {energy(0, sqrt(2)):.4f}, turns back at {acos(1 - energy(0, sqrt(2))) * 180 / pi:.1f} deg")
print(f"mistake 2, friction 0.5 (the house swing): energy after 6.74 units {run(TH0, 0.0, 6.74, 0.01, lambda a, b, h: rk4(a, b, h, 0.5)):.4f}")
print(f"mistake 3, Euler's rule h = 0.1: energy after 6.74 units {run(TH0, 0.0, 6.74, 0.1, euler):.4f}")
X, Y = lambda th: 180 + 45 * th, lambda w: 110 - 30 * w            # 45 units per rad, 30 per unit of speed
pts = lambda cs: " ".join(f"{X(a):.1f},{Y(b):.1f}" for a, b in cs)
ks = sqrt(E0 / 2)
print("figure, swing loop:", pts((2 * asin(ks * sin(i * pi / 12)), 2 * ks * cos(i * pi / 12)) for i in range(24)))
for sg in (1, -1):
    print(f"figure, separatrix {sg:+d}:", pts((i * pi / 8, sg * 2 * cos(i * pi / 16)) for i in range(-8, 9)))
    print(f"figure, turning {sg:+d}:", pts((i * pi / 8, sg * sqrt(2 * (Er - 1 + cos(i * pi / 8)))) for i in range(-8, 9)))
assert abs(T_rk[1] - T_simp) < 1e-6 and 12 < err[0] / err[1] < 20   # two roads; RK4 is order four
assert abs(sqrt(jac[1]) - abs(sep)) < 1e-6              # saddle rate = separatrix slope
assert abs(2 * k * quarter(k * k) - time_to(0.0, 2.5, 2 * pi, 0.05)) < 1e-5
assert abs(run(TH0, 0.0, T_simp, 0.1, rk4) - E0) < 1e-4 < abs(run(TH0, 0.0, 6.74, 0.1, euler) - E0)
print("ALL CHECKS PASS")
