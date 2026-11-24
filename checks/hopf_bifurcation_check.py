# Hopf bifurcation -- the check behind the card.  Normal forms r' = mu r + a r^3 (+ ...), and the
# Brusselator x' = 1 - (B + 1) x + x^2 y, y' = B x - x^2 y, whose Hopf point is B = 2.
from math import sqrt, exp
def rk4(F, s, dt, n):                         # n Runge-Kutta 4 steps of s' = F(s)
    for _ in range(n):
        k1 = F(s); k2 = F([a + dt / 2 * b for a, b in zip(s, k1)])
        k3 = F([a + dt / 2 * b for a, b in zip(s, k2)]); k4 = F([a + dt * b for a, b in zip(s, k3)])
        s = [a + dt / 6 * (p + 2 * q + 2 * u + v) for a, p, q, u, v in zip(s, k1, k2, k3, k4)]
    return s
sup = lambda mu: lambda s: [mu * s[0] - s[0] ** 3]                     # r' = mu r - r^3
sub = lambda mu: lambda s: [mu * s[0] + s[0] ** 3 - s[0] ** 5]         # r' = mu r + r^3 - r^5
plane = lambda mu: lambda s: [mu * s[0] - s[1] - s[0] * (s[0] ** 2 + s[1] ** 2), s[0] + mu * s[1] - s[1] * (s[0] ** 2 + s[1] ** 2)]
r1, r2, xy = rk4(sup(0.04), [0.01], 0.05, 8000)[0], rk4(sup(0.04), [0.5], 0.05, 8000)[0], rk4(plane(0.04), [0.01, 0.0], 0.05, 8000)
print(f"super mu 0.04: radius sqrt(mu) {sqrt(0.04):.4f}; RK4 from 0.01 {r1:.4f}, from 0.5 {r2:.4f}; x-y plane {sqrt(xy[0]**2 + xy[1]**2):.4f}")
assert abs(r1 - 0.2) < 1e-6 and abs(r2 - 0.2) < 1e-6 and abs(sqrt(xy[0] ** 2 + xy[1] ** 2) - 0.2) < 1e-6
lin, r150 = 0.01 * exp(0.04 * 150), rk4(sup(0.04), [0.01], 0.05, 3000)[0]
print(f"super mu 0.04 from 0.01 at t 150: linear guess {lin:.4f}, true {r150:.4f}; mu 0 at t 1000 from 0.2: {rk4(sup(0), [0.2], 0.05, 20000)[0]:.4f} (1/sqrt(25 + 2000) = {1 / sqrt(2025):.4f})")
big, small = (lambda mu: sqrt((1 + sqrt(1 + 4 * mu)) / 2)), (lambda mu: sqrt((1 - sqrt(1 + 4 * mu)) / 2))
print(f"sub: big cycle at mu 0 {big(0):.4f}, at 0.04 {big(0.04):.4f}, at -0.10 {big(-0.1):.4f}, at -0.25 {big(-0.25):.4f}; small unstable at -0.04 {small(-0.04):.4f}")
for mu in (-0.1, -0.04):                      # both cycles are rests of r' found by RK4: start just off each
    assert abs(rk4(sub(mu), [big(mu) + 0.05], 0.05, 4000)[0] - big(mu)) < 1e-6 and rk4(sub(mu), [small(mu) - 0.01], 0.05, 4000)[0] < 1e-3
mus, r, up, down = [round(-0.30 + 0.02 * i, 2) for i in range(21)], 0.0, [], []
for path, order in ((up, mus), (down, mus[::-1])):
    for mu in order:                          # settle 1000 time units at each dial value; noise floor 0.01
        r = rk4(sub(mu), [max(r, 0.01)], 0.05, 20000)[0]; path.append(r)
down = down[::-1]
for name, row in (("mu", mus), ("sweep up", up), ("sweep down", down), ("super sqrt(mu)", [sqrt(max(m, 0)) for m in mus])):
    print(f"chart {name}:", " ".join(f"{v:.2f}" for v in row))
jump, drop = min(m for m, v in zip(mus, up) if v > 0.5), max(m for m, v in zip(mus, down) if v < 0.5)
print(f"hysteresis: up-sweep jumps at mu {jump:.2f}, down-sweep drops at mu {drop:.2f}")
assert jump == 0.02 and drop == -0.26 and all(abs(v - big(m)) < 1e-3 for m, v in zip(mus, down) if m > -0.25)
def F(B): return lambda s: [1 - (B + 1) * s[0] + s[0] ** 2 * s[1], B * s[0] - s[0] ** 2 * s[1]]
def fg(u, w):                                 # nonlinear parts in u = x - 1, w = -(u + y - 2), at B = 2
    x, y = F(2)([1 + u, 2 - w - u]); return x + w, -(x + y) - u       # u' = -w + f, w' = u + g
def D(k, ax, p=(0.0, 0.0), h=0.01):           # nested central differences: exact for cubics
    if not ax: return fg(*p)[k]
    e = (h, 0) if ax[0] == 0 else (0, h)
    return (D(k, ax[1:], (p[0] + e[0], p[1] + e[1])) - D(k, ax[1:], (p[0] - e[0], p[1] - e[1]))) / (2 * h)
f, g = (lambda *ax: D(0, ax)), (lambda *ax: D(1, ax))                  # f_uw is f(0, 1), and so on
cubic = f(0, 0, 0) + f(0, 1, 1) + g(0, 0, 1) + g(1, 1, 1)
quad = f(0, 1) * (f(0, 0) + f(1, 1)) - g(0, 1) * (g(0, 0) + g(1, 1)) - f(0, 0) * g(0, 0) + f(1, 1) * g(1, 1)
a = (cubic + quad) / 16
print(f"Brusselator B 2: f_uuu {f(0, 0, 0):.3f}, f_uw {f(0, 1):.3f}, others 0; 16a = {cubic:.3f} + {quad:.3f}; a = {a:.4f}")
s, t, laps, dt = [1.05, 1.95], 0.0, [], 0.01  # start u = 0.05, w = 0; time each pass up through w = 0
while t < 1000:
    n = rk4(F(2), s, dt, 1); w0, w1 = -(s[0] + s[1] - 3), -(n[0] + n[1] - 3)
    if w0 < 0 <= w1 and n[0] > 1: laps.append((t, s[0] - 1 + (n[0] - s[0]) * (-w0) / (w1 - w0)))
    s, t = n, t + dt
(tl, ul), = laps[-1:]; a_sim = -(1 / ul ** 2 - 400) / (2 * tl)      # 1/r^2 grows at rate -2a
print(f"simulated at B 2: {len(laps)} laps, u from 0.05 to {ul:.4f}; a from 1/r^2 growth {a_sim:.4f}")
assert abs(a_sim - a) < 0.01 and abs(a + 0.375) < 1e-6
for beta in (0.04, 0.01):                     # dial d = 1/2 per unit of B: radius sqrt(-(beta/2)/a)
    s = rk4(F(2 + beta), [1.01, 2 + beta], 0.01, 300000); xs = [s[0]]
    for _ in range(700): s = rk4(F(2 + beta), s, 0.01, 1); xs.append(s[0])
    pred, half = sqrt(-(beta / 2) / a), (max(xs) - min(xs)) / 2
    print(f"B {2 + beta:.2f}: predicted radius {pred:.4f}, simulated half-swing of x {half:.4f}, ratio {half / pred:.3f}")
    assert abs(half / pred - 1) < 0.08 * beta / 0.04
print(f"mistakes: no 1/2 dial speed {sqrt(-0.04 / a):.4f}; no 1/16 {sqrt(-0.02 / (16 * a)):.4f}; sub back at mu -0.10 swing {down[mus.index(-0.1)]:.4f}")
print("ALL CHECKS PASS")
