# Pontryagin's principle -- the check behind the card.  Standard library only.
# A car parks 100 m away, rest to rest, with |u| <= 2 m/s^2.  Road one: the
# maximum principle, H = p1 v + p2 u - 1, switching where p2 = 0.  Road two: a
# grid search offering five throttle settings.  Road three: the costate as a price.
import math
D, A, e, DTS = 100.0, 2.0, 1e-4, (0.1, 0.04, 0.01)
ts = math.sqrt(D / A); T = 2 * ts                  # switch time, arrival time
p2_0 = 1 / A                                        # H = 0 at t = 0, where v = 0
p1 = p2_0 / ts                                      # p2 = p2_0 - p1 t is 0 at ts
def sigma(t): return p2_0 - p1 * t                  # the switching function, p2
def speed(t): return A * t if t <= ts else max(0.0, A * (T - t))
def ham(t, u): return p1 * speed(t) + sigma(t) * u - 1
def best_time(d, v0, a=A):                          # to rest at distance d, from v0
    vp = math.sqrt(a * d + v0 * v0 / 2)             # peak speed
    return (2 * vp - v0) / a, (vp - v0) / a         # arrival time, switch time
def grid(dt):                                       # farthest point at each speed k dt
    best, n = {0: 0.0}, 0
    while best.get(0, -1.0) < D - 1e-9:
        new = {}
        for k, x in best.items():
            for u in (-2, -1, 0, 1, 2):
                y = x + k * dt * dt + u * dt * dt / 2
                if y > new.get(k + u, -1e18): new[k + u] = y
        best, n = new, n + 1
    return n * dt
def euler(n):                                       # n steps, u = 2 sign(sigma)
    x = v = 0.0; h = T / n
    for i in range(n):
        if i == n // 2: xs = x                      # position at the switch
        u = A if sigma((i + 0.5) * h) > 0 else -A
        x, v = x + h * v, v + h * u
    return D / 2 - xs, x
fd1 = (best_time(D + e, 0)[0] - best_time(D - e, 0)[0]) / (2 * e)
fd2 = -(best_time(D, e)[0] - best_time(D, -e)[0]) / (2 * e)
gs, eul = [grid(dt) for dt in DTS], [euler(n) for n in (1000, 2000, 4000)]
print(f"switch ts = sqrt(D/a) = {ts:.4f} s; arrival T = {T:.4f} s; peak speed {A * ts:.4f} m/s")
print(f"costate p1 = {p1:.6f} s/m; p2(0) = {p2_0:.4f} s^2/m; p2(T) = {sigma(T):.4f}")
for t in (0.0, 3.0, ts, 10.0):
    hs = [ham(t, u) for u in (-2, -1, 0, 1, 2)]
    print(f"t = {t:7.4f}: sigma {sigma(t):+.4f}; H at u = -2..2: " + " ".join(f"{round(h, 3) + 0.0:+.3f}" for h in hs))
print("speed chart, t = 0, 2, ..., 20 s")
print("  full throttle then brake:", ", ".join(f"{speed(t):.2f}" for t in range(0, 21, 2)))
print("  half throttle then brake:", ", ".join(f"{min(t, 20 - t) * 1.0:.2f}" for t in range(0, 21, 2)))
print("grid search, dt = 0.1, 0.04, 0.01 s: " + ", ".join(f"{g:.3f} s" for g in gs))
print(f"price of a metre: dT/dD = {fd1:.6f}; of a m/s head start: -dT/dv0 = {fd2:.4f}")
print("Euler, 1000, 2000, 4000 steps: short of 50 m at the switch by "
      + ", ".join(f"{r[0]:.5f}" for r in eul) + "; ends at " + ", ".join(f"{r[1]:.5f}" for r in eul))
print("rolling start 10 m/s: T = {:.4f} s, switch at {:.4f} s".format(*best_time(D, 10.0)))
print(f"mistake, half throttle: {best_time(D, 0, 1.0)[0]:.2f} s; top speed capped at 10: "
      f"{10 / A * 2 + (D - 10 * 10 / A) / 10:.2f} s")
print(f"mistake, switch late at 8 s: stops at {A * 8 ** 2 / 2 + (A * 8) ** 2 / (2 * A):.2f} m; "
      f"bound 200 m/s^2: {best_time(D, 0, 200.0)[0]:.2f} s")
Y = lambda v: 200 - 8 * v                           # figure: 2.8 px per m, 8 px per m/s
print(f"figure, switch ({40 + 2.8 * D / 2:.2f}, {Y(A * ts):.2f}); arc controls y {Y(A * ts / 2):.2f}; "
      f"switching curve top {Y(math.sqrt(2 * A * D)):.2f}, control y {Y(math.sqrt(2 * A * D) / 2):.2f}")
assert all(T <= g < T + dt for g, dt in zip(gs, DTS))    # no plan on the grid beats T
assert abs(fd1 - p1) < 1e-6 and abs(fd2 - p2_0) < 1e-6         # costate = price of state
assert all(abs(ham(t, A if sigma(t) > 0 else -A)) < 1e-12 for t in (1.0, 9.0, 13.0))
assert all(1.9 < a[0] / b[0] < 2.1 for a, b in zip(eul, eul[1:]))  # Euler, order one
print("ALL CHECKS PASS")
