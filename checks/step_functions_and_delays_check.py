# Step functions and delays -- the check behind the card.  Only math.exp and
# math.log are imported.  A 20 C room, T' = -0.5(T - 20 - 10u(t - 2)), with the
# heater switched on at t = 2 h.  Road one is the transform answer, built from
# the two shifting rules.  Road two steps the equation with Runge-Kutta 4 and
# never uses a transform.  A midpoint sum checks each rule's integral directly.
from math import exp, log
K, GAIN, ON = 0.5, 10.0, 2.0

def step(t):                                   # the unit step, 1 from t = 0 on
    return 1.0 if t >= 0 else 0.0

def closed(t, off=None):                       # road one: 10(1 - e^(-0.5(t - 2))) u(t - 2)
    x = GAIN * (1 - exp(-K * (t - ON))) * step(t - ON)
    if off is not None: x -= GAIN * (1 - exp(-K * (t - off))) * step(t - off)
    return 20 + x

def rk4(t_end, h, off=None):                   # road two: heater fixed within each step
    T, n = 20.0, round(t_end / h)
    for i in range(n):
        t0 = i * h
        heat = step(t0 - ON + 1e-9) - (step(t0 - off + 1e-9) if off else 0)
        f = lambda T: -K * (T - 20 - GAIN * heat)
        k1 = f(T); k2 = f(T + h / 2 * k1); k3 = f(T + h / 2 * k2); k4 = f(T + h * k3)
        T += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    return T

def transform(g, s, end=40.0, n=40000):        # midpoint sum of e^(-st) g(t)
    dt = end / n
    return sum(exp(-s * (k + 0.5) * dt) * g((k + 0.5) * dt) for k in range(n)) * dt

print("target 20 + 10u(t - 2) at hours 0..10: " + " ".join(f"{20 + GAIN * step(t - ON):.0f}" for t in range(11)))
print("T at hours 0..10: " + " ".join(f"{closed(t):.2f}" for t in range(11)))
print(f"T(3) = {closed(3):.4f}, T(4) = {closed(4):.4f}, T(6) = {closed(6):.4f} C")
print(f"reaches 25 C at t = 2 + 2 ln 2 = {ON + log(2) / K:.3f} h")
errs = [abs(rk4(4, h) - closed(4)) for h in (0.1, 0.05)]
print(f"RK4 T(4) at h = 0.05: {rk4(4, 0.05):.6f}; errors {errs[0]:.1e}, {errs[1]:.1e}; ratio {errs[0] / errs[1]:.1f}")
print(f"on 2 h, off 6 h: T(8) = {closed(8, 6):.4f} closed, {rk4(8, 0.05, 6):.4f} RK4")
X = 5 * exp(-2.0) / (1.0 * 1.5)                # delay rule at s = 1: 5e^(-2s)/(s(s+0.5))
Xn = transform(lambda t: closed(t) - 20, 1.0)
print(f"s = 1: delay rule X = {X:.6f}, midpoint sum of e^(-t)(T - 20) = {Xn:.6f}")
Sn = transform(lambda t: 5 * step(t - ON), 1.0)
print(f"s = 1: forcing 5u(t-2) -> 5e^(-2)/1 = {5 * exp(-2.0):.6f}, midpoint sum {Sn:.6f}")
Fn = transform(lambda t: exp(-K * t) * t, 1.0)
print(f"s = 1: e^(-0.5t) t -> 1/(s+0.5)^2 = {1 / 1.5 ** 2:.6f}, midpoint sum {Fn:.6f}")
print(f"mistake 1, gate without restarting: T(2) = {20 + GAIN * (1 - exp(-K * 2)):.4f}, T(4) = {20 + GAIN * (1 - exp(-K * 4)):.4f}")
print(f"mistake 2, e^(+2s) for the delay: T(4) = {20 + GAIN * (1 - exp(-K * 6)):.4f}")
print(f"mistake 3, 1/(s+0.5) read as e^(+0.5t): T(4) = {20 + GAIN * (1 - exp(K * 2)):.4f}")
assert abs(rk4(4, 0.05) - closed(4)) < 1e-6                     # stepped room = transform answer
assert abs(rk4(8, 0.05, 6) - closed(8, 6)) < 1e-6               # second case: on, then off
assert abs(Xn - X) < 1e-6                                       # delay rule vs direct integral
assert abs(Fn - 1 / 1.5 ** 2) < 1e-6                            # s-shift rule vs direct integral
print("ALL CHECKS PASS")
