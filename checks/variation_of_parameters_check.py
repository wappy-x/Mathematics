# Variation of parameters -- the check behind the card.  Standard library only.
# A 1 kg cart on a 1 N/m spring, no friction, pushed by sec t = 1/cos t newtons:
# y'' + y = sec t, starting at rest at balance; t in s, y in m.  Road one: the
# closed answer y_p = cos t ln cos t + t sin t.  Road two: the rates u1' and u2'
# added up by Simpson's rule, then assembled.  Road three: Euler steps on the law.
import math

def g(t): return 1 / math.cos(t)                         # the push, in newtons
def yp(t): return math.cos(t) * math.log(math.cos(t)) + t * math.sin(t)
def dyp(t): return -math.sin(t) * math.log(math.cos(t)) + t * math.cos(t)

def simpson(f, a, b, n=2000):                             # area under f from a to b, n even
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * (b - a) / n) for i in range(1, n))
    return s * (b - a) / (3 * n)

def varied(t, y1, y2, d1, d2, use_w=True):               # u1 y1 + u2 y2 from the two rates
    W = (lambda s: y1(s) * d2(s) - y2(s) * d1(s)) if use_w else (lambda s: 1.0)
    u1 = simpson(lambda s: -y2(s) * g(s) / W(s), 0, t)
    u2 = simpson(lambda s: y1(s) * g(s) / W(s), 0, t)
    return u1, u2, u1 * y1(t) + u2 * y2(t)

def euler(t_end, n, y=0.0, v=0.0):                        # n plain steps along the slope
    h, t = t_end / n, 0.0
    for _ in range(n):
        y, v, t = y + h * v, v + h * (g(t) - y), t + h
    return y

T = math.pi / 3
u1, u2, road2 = varied(T, math.cos, math.sin, lambda s: -math.sin(s), math.cos)
B2 = (lambda s: 2 * math.cos(s), lambda s: 3 * math.sin(s), lambda s: -2 * math.sin(s), lambda s: 3 * math.cos(s))
scaled, no_w = varied(T, *B2)[2], varied(T, *B2, use_w=False)[2]      # a rescaled pair, W = 6
errs = [abs(euler(T, n) - yp(T)) for n in (100, 200, 400)]
fd = lambda f, t, e=1e-4: (f(t + e) - 2 * f(t) + f(t - e)) / e ** 2 + f(t)   # y'' + y
flip = lambda t: -math.cos(t) * math.log(math.cos(t)) + t * math.sin(t)
full = 2 * math.cos(T) - math.sin(T) + yp(T)
ts = [0.25 * k for k in range(7)]
print("t (s)            ", ", ".join(f"{t:.2f}" for t in ts))
print("y_p (m)          ", ", ".join(f"{yp(t):.2f}" for t in ts))
print("t sin t (m)      ", ", ".join(f"{t * math.sin(t):.2f}" for t in ts))
print("cos t ln cos t   ", ", ".join(f"{math.cos(t) * math.log(math.cos(t)):.2f}" for t in ts))
print(f"by hand at pi/3 = {T:.4f}: cos {math.cos(T):.4f}, sin {math.sin(T):.4f}, ln cos {math.log(math.cos(T)):.4f}")
print(f"u1: Simpson {u1:.6f}, ln cos t {math.log(math.cos(T)):.6f}; u2: Simpson {u2:.6f}, t {T:.6f}")
print(f"u1 y1 = {u1 * math.cos(T):.4f}; u2 y2 = {u2 * math.sin(T):.4f}")
print(f"y_p(pi/3): closed {yp(T):.6f}; Simpson on u1', u2' {road2:.6f}; basis 2 cos t, 3 sin t (W = 6) {scaled:.6f}")
print("Euler error at pi/3, n = 100, 200, 400:", " ".join(f"{e:.6f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"push rebuilt at pi/3 from y'' + y: {fd(yp, T):.4f} N; sec(pi/3) = {g(T):.4f} N")
print(f"y_p(pi/6) = {yp(math.pi / 6):.6f}; start (2, -1): y(pi/3) = {full:.6f}")
print(f"edge: y_p(1.5) = {yp(1.5):.4f}, y_p(1.57) = {yp(1.57):.4f}, pi/2 = {math.pi / 2:.4f}; speed {dyp(1.5):.2f} and {dyp(1.57):.2f} m/s")
print(f"dependent pair cos t, 2 cos t: W = {math.cos(1) * -2 * math.sin(1) - 2 * math.cos(1) * -math.sin(1):.4f}")
print(f"mistake, trial A sec t: needs A = {1 / (2 * g(0) ** 2):.4f} at t = 0, A = {1 / (2 * g(T) ** 2):.4f} at pi/3")
print(f"mistake, sign of u1 flipped: y(pi/3) = {flip(T):.4f}, its push {abs(fd(flip, T)):.4f} N, not 2")
print(f"mistake, W dropped with basis 2 cos t, 3 sin t: y(pi/3) = {no_w:.4f}, not {yp(T):.4f}")
print(f"mistake, start (2, -1) ignored: y(pi/3) = {yp(T):.4f}, not {full:.4f}")
assert abs(road2 - yp(T)) < 1e-9 and abs(scaled - yp(T)) < 1e-9          # road two, two bases
assert all(1.8 < errs[i] / errs[i + 1] < 2.2 for i in range(2))           # road three, order one
assert errs[2] < 0.01                                                      # Euler lands near y_p
assert abs(fd(yp, T) - g(T)) < 1e-5                                        # the law itself
print("ALL CHECKS PASS")
