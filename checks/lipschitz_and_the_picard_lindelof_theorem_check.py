# Picard-Lindelof on a leaking bucket -- the check behind the card.  Standard
# library only.  Rate law h' = -0.2 sqrt(h): depth h in cm, time t in minutes.
from math import sqrt

def f(h):                                      # the rate law, in cm per minute
    return -0.2 * sqrt(max(h, 0.0))

def exact(t):                                  # road one: separation, full at t = 0
    return (5.0 - 0.1 * t) ** 2 if t <= 50 else 0.0

A, B, H0 = 10.0, 16.0, 25.0                    # the box: 10 min, depth 25 +- 16 cm
M = 0.2 * sqrt(H0 + B)                         # fastest fall anywhere in the box
L = 0.1 / sqrt(H0 - B)                         # steepest slope of f in the box, by calculus
T = min(A, B / M)
grid = [H0 - B + 0.01 * k for k in range(3201)]
L_seen = max(abs(f(u) - f(v)) / (v - u) for u, v in zip(grid, grid[1:]))
print(f"box: M = {M:.6f} cm/min, b/M = {B / M:.6f} min, window T = {T:.6f} min")
print(f"L = {L:.6f} per min by calculus; largest quotient on a 0.01 cm grid {L_seen:.6f}; slope at 25 cm {0.1 / sqrt(H0):.6f}")
print(f"promised shrink per round, L x T = {L * T:.6f}")

N = 1000; dt = T / N                           # road two: Picard rounds, trapezoid integral
phi, gaps = [H0] * (N + 1), []
for n in range(1, 7):
    new = [H0]
    for i in range(N):
        new.append(new[-1] + 0.5 * dt * (f(phi[i]) + f(phi[i + 1])))
    gaps.append(max(abs(u - v) for u, v in zip(new, phi)))
    phi = new
    ratio = f"{gaps[-1] / gaps[-2]:.6f}" if n > 1 else "-"
    print(f"round {n}: depth at 10 min {phi[-1]:.6f} cm, gap {gaps[-1]:.6f}, shrink {ratio}")
print(f"separation formula at 10 min: {exact(T):.6f} cm; empty at t = 50 min: {exact(50):.6f}; rate at 25 cm {-f(H0):.6f}")

errs = []                                      # road three: Euler steps against the formula
for step in (1.0, 0.5, 0.25):
    h = H0
    for _ in range(round(T / step)):
        h += step * f(h)
    errs.append(h - exact(T))
print("Euler error at 10 min, steps 1, 0.5, 0.25 min: " + ", ".join(f"{e:.6f}" for e in errs))

for q in (1.0, 0.01, 0.0001):                  # the slope of f blows up at empty
    print(f"slope quotient between h = {q:g} and 0: {abs(f(q) - f(0.0)) / q:.6f}")
past = lambda t, e: (0.1 * (e - t)) ** 2 if t <= e else 0.0   # emptied at minute e
K = 5000; ds = 50.0 / K                        # integral equation back from h(50) = 0
back = -sum(0.5 * ds * (f(past(k * ds, 50)) + f(past((k + 1) * ds, 50))) for k in range(K))
print(f"from h(50) = 0, depth at t = 0: stay empty {-50 * f(0.0):.6f}; emptied at 50: {past(0, 50):.6f}; "
      f"emptied at 30: {past(0, 30):.6f}")
eb = 0.0                                       # Euler, 1-minute steps back from empty
for _ in range(50): eb -= f(eb)
print(f"integral equation for the emptied-at-50 past, depth at t = 0: {back:.6f}; Euler back: {eb:.6f}")
print(f"window stretched to 40 min: L x T = {L * 40:.6f}; depth at 20 min {exact(20):.6f}, the box's floor")
def fig(e):                                    # quadratic Bezier: start, control, end
    d = past(0, e)
    return f"(40, {200 - 6.4 * d:.1f}) ctrl ({40 + 5 * d / -f(d):.0f}, 200) to ({40 + 5 * e:.0f}, 200)"
print(f"figure, full {fig(50)}; emptied at 30 {fig(30)}")
assert abs(phi[-1] - exact(T)) < 1e-5 and abs(errs[2]) < abs(errs[0]) / 3   # roads agree
assert all(g2 <= L * T * g1 for g1, g2 in zip(gaps, gaps[1:]))           # contraction bound
assert abs(L_seen - L) < 1e-4                                            # L two ways
assert abs(back - past(0, 50)) < 1e-6                                    # a second past fits
print("ALL CHECKS PASS")
