# Lyapunov functions -- the check behind the card.  Standard library only; the
# imports are math.sqrt, exp and log.  A ball settling in a bowl: x' = -x^3,
# x in cm from the bottom, t in s, V = x^2/2.  Road one: closed forms from
# separating variables.  Road two: Runge-Kutta 4 steps written out below.
from math import sqrt, exp, log

def rk4(f, s, h, n):                                   # n classical RK4 steps
    for _ in range(n):
        k1 = f(s); k2 = f([a + h / 2 * b for a, b in zip(s, k1)])
        k3 = f([a + h / 2 * b for a, b in zip(s, k2)]); k4 = f([a + h * b for a, b in zip(s, k3)])
        s = [a + h / 6 * (p + 2 * q + 2 * r + w) for a, p, q, r, w in zip(s, k1, k2, k3, k4)]
    return s

def first_time(f, x0, h, done):                        # step until done(x) turns true
    s, n = [x0], 0
    while not done(s[0]): s, n = rk4(f, s, h, 1), n + 1
    return n * h

settle, burst = (lambda s: [-s[0] ** 3]), (lambda s: [s[0] ** 3])
closed = lambda x0, t: x0 / sqrt(1 + 2 * x0 * x0 * t)  # 1/x^2 = 1/x0^2 + 2t
step = lambda f, x0, t, h=0.01: rk4(f, [x0], h, round(t / h))[0]
V = lambda x: x * x / 2
print("ball in a bowl: x' = -x^3, x in cm, t in s; V = x^2/2, V' = x x' = -x^4")
s0 = (settle([1e-4])[0] - settle([-1e-4])[0]) / 2e-4
print(f"slope of the rate at x = 0, by differences: {round(s0, 6) + 0.0:.6f} -> linearisation silent")
print("rate x' = -x^3 at x = 1, 0.5, 0.2:", " ".join(f"{settle([x])[0]:.3f}" for x in (1, 0.5, 0.2)))
print("V' = -x^4 at x = 1, 0.5, 0.2:", " ".join(f"{-x ** 4:.6f}" for x in (1, 0.5, 0.2)))
x4 = step(settle, 1, 4)
dV = (V(rk4(settle, [x4], 1e-3, 1)[0]) - V(rk4(settle, [x4], -1e-3, 1)[0])) / 2e-3
print(f"at t = 4 s: dV/dt by differences along the stepped path {dV:.6f}, chain rule -x^4 {-x4 ** 4:.6f}")
print(f"x at t = 4, 12 s: closed {closed(1, 4):.6f} {closed(1, 12):.6f}; RK4 h = 0.01 {x4:.6f} {step(settle, 1, 12):.6f}")
print(f"V at t = 12 s: from the stepped x {V(step(settle, 1, 12)):.6f}; from 1/V = 1/V0 + 4t {1 / (2 + 4 * 12):.6f}")
err = [step(settle, 1, 1, h) - closed(1, 1) for h in (0.02, 0.01, 0.005)]
print("RK4 error at t = 1 s, h = 0.02, 0.01, 0.005:", " ".join(f"{e:.3e}" for e in err),
      f"ratios {err[0] / err[1]:.1f} {err[1] / err[2]:.1f}")
lin = lambda s: [-s[0]]                                # the linear bowl x' = -x, for contrast
print(f"time to reach 0.1 cm: cubic closed {(100 - 1) / 2:.2f} s, stepped {first_time(settle, 1, 0.01, lambda x: x <= 0.1):.2f} s;"
      f" linear closed {log(10):.2f} s, stepped {first_time(lin, 1, 0.01, lambda x: x <= 0.1):.2f} s")
print("chart, cubic x at t = 0..12 s:", " ".join(f"{step(settle, 1, t):.2f}" for t in range(13)))
print("chart, linear x at t = 0..12 s:", " ".join(f"{step(lin, 1, t):.2f}" for t in range(13)))
xb = step(burst, 1, 0.49, 0.001)
print(f"x' = +x^3 from 1 cm: V' = +x^4; x(0.49) closed {1 / sqrt(1 - 2 * 0.49):.4f}, RK4 {xb:.4f}; blow-up at t = 0.5 s")
free = lambda s: [s[1], -s[0] ** 3]                    # no friction: x' = y, y' = -x^3
E = lambda s: s[1] ** 2 / 2 + s[0] ** 4 / 4            # its energy, E' = y(-x^3) + x^3 y = 0
s, top = rk4(free, [1.0, 0.0], 0.01, 1000), 0.0
for _ in range(1000): s = rk4(free, s, 0.01, 1); top = max(top, abs(s[0]))
print(f"frictionless bowl from (1, 0): E at t = 0, 20 s {E([1, 0]):.6f} {E(s):.6f}; largest |x| on 10..20 s {top:.4f}")
local = lambda s: [-s[0] + s[0] ** 3]                  # V' = -x^2 (1 - x^2): negative only for |x| < 1
u0 = 1 / 1.21
t_esc = first_time(local, 1.1, 1e-4, lambda x: x > 100)
print(f"x' = -x + x^3 from 1.1 cm: escape at t closed {0.5 * log(1 / (1 - u0)):.3f} s, stepped {t_esc:.3f} s")
x9 = 1 / sqrt(1 + (1 / 0.81 - 1) * exp(10))
print(f"x' = -x + x^3 from 0.9 cm: x(5) closed {x9:.5f}, stepped {step(local, 0.9, 5):.5f}")
assert abs(step(settle, 1, 12) - closed(1, 12)) < 1e-8   # the stepped path meets the closed form
assert 14 < err[1] / err[2] < 17                          # error falls near 16-fold per halving: order 4
assert abs(dV + x4 ** 4) < 1e-7                            # V' along the path equals grad V . f
assert abs(top - (4 * E([1, 0])) ** 0.25) < 1e-3 and abs(t_esc - 0.5 * log(1 / (1 - u0))) < 2e-3
print("ALL CHECKS PASS")
