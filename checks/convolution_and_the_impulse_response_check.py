# Convolution and the impulse response -- the check behind the card.  Only
# math.exp, sin and cos are imported.  The shock absorber: y'' + 2y' + 5y = f(t),
# starting at rest.  Road one blends the impulse response with the input by a
# midpoint sum; road two steps the equation itself with Runge-Kutta 4.
from math import exp, sin, cos

def conv(a, b, t, n=4000):                # (a * b)(t): add a(tau) b(t - tau) over 0..t
    w = t / n
    return w * sum(a((k + 0.5) * w) * b(t - (k + 0.5) * w) for k in range(n))

def rk4(push, y, v, h, t_end):            # y'' = push - 2y' - 5y, states at every 0.5 s
    acc, out, every = lambda y, v: push - 2 * v - 5 * y, [], round(0.5 / h)
    for n in range(round(t_end / h) + 1):
        if n % every == 0: out.append(y)
        k1 = (v, acc(y, v)); k2 = (v + h / 2 * k1[1], acc(y + h / 2 * k1[0], v + h / 2 * k1[1]))
        k3 = (v + h / 2 * k2[1], acc(y + h / 2 * k2[0], v + h / 2 * k2[1]))
        k4 = (v + h * k3[1], acc(y + h * k3[0], v + h * k3[1]))
        y, v = y + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]), v + h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return out

g = lambda t: 0.5 * exp(-t) * sin(2 * t)                  # impulse response, from 1/(s^2+2s+5)
push = lambda t: 10.0
trip = lambda t: 2 - exp(-t) * (2 * cos(2 * t) + sin(2 * t))   # the round-trip answer
c1, exact = conv(lambda t: exp(-t), lambda t: exp(-2 * t), 1.0), exp(-1) - exp(-2)
print(f"e^(-t) * e^(-2t) at t = 1: midpoint sum {c1:.6f}, e^(-1) - e^(-2) = {exact:.6f}")
lap = sum(0.001 * exp(-u) * (exp(-u) - exp(-2 * u)) for u in [(k + 0.5) * 0.001 for k in range(40000)])
print(f"transforms at s = 1: (1/2)(1/3) = {1 / 6:.6f}, weighted integral of e^(-t) - e^(-2t) = {lap:.6f}")
kick = [rk4(0.0, 0.0, 1.0, h, 1.0)[2] for h in (0.05, 0.025)]
e1, e2 = abs(kick[0] - g(1)), abs(kick[1] - g(1))
print(f"impulse response at t = 1: RK4 from a unit kick {kick[1]:.6f}, 0.5 e^(-1) sin 2 = {g(1):.6f}")
print(f"RK4 error at t = 1: h = 0.05 {e1:.1e}, h = 0.025 {e2:.1e}, ratio {e1 / e2:.1f}, near 16 for order 4")
ts = [0.5 * k for k in range(13)]
ys = [conv(g, push, t) for t in ts]
steps = rk4(10.0, 0.0, 0.0, 0.01, 6.0)
gap = max(abs(a - b) for a, b in zip(ys, steps))
print(f"push of 10 at t = 1: convolution {ys[2]:.6f}, RK4 {steps[2]:.6f}, round trip {trip(1):.6f}")
print(f"largest gap over 0 to 6 s: convolution vs RK4 {gap:.1e}, convolution vs round trip "
      f"{max(abs(a - trip(t)) for a, t in zip(ys, ts)):.1e}")
print(f"at t = 20: convolution {conv(g, push, 20.0, 40000):.6f}, steady value 10/5 = {10 / 5:.6f}")
print("figure, t     " + " ".join(f"{t:5.2f}" for t in ts))
print("figure, y     " + " ".join(f"{y:5.2f}" for y in ys))
print("figure, 10g   " + " ".join(f"{10 * g(t):5.2f}" for t in ts))
print(f"mistake 1, pointwise product at t = 1: e^(-3) = {exp(-3):.6f}, not {exact:.6f}")
noflip = conv(lambda t: exp(-t), lambda t: exp(-2 * (1.0 - t)), 1.0)
print(f"mistake 2, no flip, e^(-2 tau) for e^(-2(t - tau)): {noflip:.6f}, not {exact:.6f}")
print(f"mistake 3, released from 1 cm and pushed: convolution alone {ys[2]:.6f}, "
      f"RK4 {rk4(10.0, 1.0, 0.0, 0.01, 1.0)[2]:.6f}")
assert abs(c1 - exact) < 1e-6                     # blended sum = closed form
assert abs(lap - 1 / 6) < 1e-6                    # transform of the blend = product of transforms
assert abs(kick[1] - g(1)) < 1e-6 and 12 < e1 / e2 < 20   # a unit kick gives g, at order 4
assert gap < 1e-5                                 # convolution = stepped equation
print("ALL CHECKS PASS")
