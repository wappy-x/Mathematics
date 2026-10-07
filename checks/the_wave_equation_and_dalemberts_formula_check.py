# The wave equation u_tt = c^2 u_xx, two roads: d'Alembert's formula and a grid stepped by its own loop.
import math

C, H, W = 1.0, 1.0, 0.05                   # string: speed m/s, pinch height cm, pinch width m
f = lambda x: H * math.exp(-((x - 0.5) / W) ** 2)          # starting shape, cm

def dalembert(x, t):                       # released from rest: two half-copies of f
    return 0.5 * (f(x - C * t) + f(x + C * t))

def grid(n, t_end, r=0.5):                 # leapfrog on 0..1 m, ends held at 0, r = c dt / dx
    dx = 1.0 / n; steps = round(t_end / (r * dx / C))
    lap = lambda u, j: u[j + 1] - 2 * u[j] + u[j - 1]
    old = [0.0] + [f(j * dx) for j in range(1, n)] + [0.0]
    new = [0.0] + [old[j] + 0.5 * r * r * lap(old, j) for j in range(1, n)] + [0.0]
    for _ in range(steps - 1):
        old, new = new, [0.0] + [2 * new[j] - old[j] + r * r * lap(new, j) for j in range(1, n)] + [0.0]
    return new, dx

for x, t in ((0.5, 0.0), (0.5, 0.05), (0.7, 0.2), (0.3, 0.2), (0.5, 0.2)):
    print(f"pinch: u({x:.2f} m, {t:.2f} s) = {dalembert(x, t):.6f} cm")
errs = []
for n in (100, 200, 400):
    u, dx = grid(n, 0.2)
    errs.append(max(abs(u[j] - dalembert(j * dx, 0.2)) for j in range(n + 1)))
    print(f"grid n={n}: dx = {dx:.4f} m, largest gap to d'Alembert at 0.2 s = {errs[-1]:.5f} cm")
print(f"error ratios: {errs[0] / errs[1]:.2f} {errs[1] / errs[2]:.2f} (order 2 means 4)")
jp = max(range(200, 401), key=lambda j: u[j])
print(f"grid right bump at 0.2 s: x = {jp * dx:.3f} m, height = {u[jp]:.4f} cm")
print(f"bump peaks reach the held ends at: {0.5 / C:.2f} s")
print(f"what breaks: no 1/2 gives {2 * dalembert(0.7, 0.2):.6f} cm; one copy only gives u(0.30, 0.20) = {f(0.3 - C * 0.2):.6f} cm")
print(f"figure, px: start peak (190, {190 - 150 * f(0.5):.0f}); bumps ({40 + 300 * 0.3:.0f}, {190 - 150 * dalembert(0.3, 0.2):.1f}) ({40 + 300 * 0.7:.0f}, {190 - 150 * dalembert(0.7, 0.2):.1f})")

# Second case: a rope, c = sqrt(T / rho), flicked so one pulse runs right from x = 0.
T, RHO, A = 0.05, 0.2, 4.0                 # tension N, mass per length kg/m, pulse height cm
c = math.sqrt(T / RHO)
p = lambda s: A * (1 - ((s + 0.1) / 0.1) ** 2) ** 3 if -0.2 < s < 0 else 0.0
dp = lambda s: A * 3 * (1 - ((s + 0.1) / 0.1) ** 2) ** 2 * (-2 * (s + 0.1) / 0.01) if -0.2 < s < 0 else 0.0
def rope(x, t, m=4000):                    # d'Alembert with f = p, g = -c p', g integrated by Simpson's rule
    a, b = x - c * t, x + c * t; h = (b - a) / m
    s = sum((1 if k in (0, m) else 4 if k % 2 else 2) * -c * dp(a + k * h) for k in range(m + 1)) * h / 3
    return 0.5 * (p(a) + p(b)) + s / (2 * c)
print(f"rope: c = sqrt({T} N / {RHO} kg/m) = {c:.2f} m/s, so 1 m takes {1 / c:.2f} s; T / rho = {T / RHO:.2f} would say {RHO / T:.2f} s")
print(f"rope u(1 m, 2.2 s): travelling pulse p(x - ct) = {p(1 - c * 2.2):.6f} cm, d'Alembert = {rope(1, 2.2):.6f} cm, no velocity term = {0.5 * (p(1 - c * 2.2) + p(1 + c * 2.2)):.6f} cm")
first = next(k / 100 for k in range(400) if abs(rope(1, k / 100)) > 1e-9)
print(f"rope: first motion at x = 1 m on a 0.01 s scan: t = {first:.2f} s")
print("rope u(1 m, t) cm, t = 1.90 to 2.50 step 0.05:", " ".join(f"{round(rope(1, 1.9 + 0.05 * k), 2) + 0.0:.2f}" for k in range(13)))

assert errs[2] < 1e-3                      # the grid, stepped blind, lands on d'Alembert's formula
assert 3.5 < errs[0] / errs[1] < 4.5       # halving dx cuts the gap about fourfold: second order
assert abs(rope(1, 2.2) - p(1 - c * 2.2)) < 1e-6   # the velocity integral turns two halves into one pulse
assert 1 / c <= first <= 1 / c + 0.01      # nothing arrives before distance / speed
