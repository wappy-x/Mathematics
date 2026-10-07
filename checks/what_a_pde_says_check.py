# A partial differential equation -- the check behind the card.  Only math is
# imported.  Road one sorts seven equations by B^2 - 4AC and solves the rod, string
# and plate in closed form.  Road two sorts them by scanning directions, and steps
# the rod, string and plate on finite-difference grids that never see the answers.
from math import sin, cos, exp, sinh, pi, log
CASES = [("heat u_t = u_xx", 1, 0, 0), ("wave u_tt = u_xx", 1, 0, -1), ("Laplace u_xx + u_yy = 0", 1, 0, 1),
         ("Tricomi y u_xx + u_yy at y = 1", 1, 0, 1), ("Tricomi y u_xx + u_yy at y = -1", -1, 0, 1),
         ("trap u_xx + 3u_xy + u_yy", 1, 3, 1), ("tilted u_xx + 2u_xy + u_yy", 1, 2, 1)]
def by_discriminant(a, b, c):            # road one: the sign of B^2 - 4AC
    d = b * b - 4 * a * c
    return d, "hyperbolic" if d > 0 else ("parabolic" if d == 0 else "elliptic")
def by_scan(a, b, c, k=3600):            # road two: signs of A p^2 + B p q + C q^2 round a half circle
    q = [a * cos(t) ** 2 + b * cos(t) * sin(t) + c * sin(t) ** 2 for t in (pi * j / k for j in range(k))]
    lo, hi = min(q), max(q)
    return "hyperbolic" if lo < -1e-9 and hi > 1e-9 else ("elliptic" if lo > 1e-9 or hi < -1e-9 else "parabolic")
def lap(u, j, h): return (u[j - 1] - 2 * u[j] + u[j + 1]) / (h * h)
def heat(n, t_end=0.1):                  # rod: each point moves toward its neighbours' mean
    h = 1 / n; dt = 0.25 * h * h; u = [sin(pi * j * h) for j in range(n + 1)]
    for _ in range(round(t_end / dt)):
        u = [0.0] + [u[j] + dt * lap(u, j, h) for j in range(1, n)] + [0.0]
    return u[n // 2]
def wave(v0, n=40, t_end=0.5):           # string: the bend sets the acceleration, leapfrog steps
    h = 1 / n; dt = h / 2; old = [sin(pi * j * h) for j in range(n + 1)]
    now = [0.0] + [old[j] + dt * v0 * old[j] + dt * dt / 2 * lap(old, j, h) for j in range(1, n)] + [0.0]
    for _ in range(round(t_end / dt) - 1):
        old, now = now, [0.0] + [2 * now[j] - old[j] + dt * dt * lap(now, j, h) for j in range(1, n)] + [0.0]
    return now[n // 2]
def plate(n=20, sweeps=2000):            # plate: each inside point becomes its neighbours' mean
    u = [[sin(pi * i / n) if j == n else 0.0 for i in range(n + 1)] for j in range(n + 1)]
    for _ in range(sweeps):
        for j in range(1, n):
            for i in range(1, n):
                u[j][i] = (u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4
    return u[n // 2][n // 2]
kinds = []
for name, a, b, c in CASES:
    d, k1 = by_discriminant(a, b, c); k2 = by_scan(a, b, c); kinds.append((k1, k2))
    print(f"{name}: A {a}, B {b}, C {c}, B^2 - 4AC {d} -> {k1}; direction scan -> {k2}")
rod = exp(-pi * pi * 0.1); e1, e2 = abs(heat(10) - rod), abs(heat(20) - rod)
print(f"rod middle at t = 0.1: closed {rod:.4f}; grid error {e1:.6f} at h = 0.1, {e2:.6f} at h = 0.05; halves at t = {log(2) / pi ** 2:.4f}")
pl, st = wave(0.0), wave(1.0)
print(f"string middle at t = 0.5: plucked closed {cos(pi / 2):.4f}, grid {pl:.4f}; struck closed {1 / pi:.4f}, grid {st:.4f}")
pc, pg = sinh(pi / 2) / sinh(pi), plate()
print(f"plate centre: closed {pc:.4f}, grid {pg:.4f} at h = 0.05")
ts = [k / 10 for k in range(21)]
print("chart rod middle:", ", ".join(f"{exp(-pi * pi * t):.2f}" for t in ts))
print("chart string middle:", ", ".join(f"{cos(pi * t):.2f}" for t in ts))
print("figure, panels left x " + ", ".join(f"{20 + 115 * p}" for p in range(3)) + ", width 90 (1 m), bottom y 190, top y 100 (t = 1 or y = 1 m)")
print(f"mistake 1, string given its shape only: middle at t = 0.5 is {cos(pi / 2):.4f} or {1 / pi:.4f}, both fit")
print(f"mistake 2, plate given value and slope on one edge: slope data sin(10x)/10, at y = 1 m u reaches {sinh(10) / 100:.2f}; "
      f"data sin(20x)/20 gives {sinh(20) / 400:.0f}")
print(f"mistake 3, rod run backwards 0.01: noise 0.001 sin(10 pi x) grows to {0.001 * exp(100 * pi * pi * 0.01):.2f}, "
      f"the true profile only x{exp(pi * pi * 0.01):.4f}")
assert all(k1 == k2 for k1, k2 in kinds)                    # two roads, one sorting
assert 3.5 < e1 / e2 < 4.5 and e2 < 1e-3                    # the rod's grid closes on e^(-pi^2 t) at second order
assert abs(pl) < 1e-3 and abs(st - 1 / pi) < 1e-3           # the string's grid matches both closed forms
assert abs(pg - pc) < 2e-3                                  # the plate's averaging matches the closed form
print("ALL CHECKS PASS")
