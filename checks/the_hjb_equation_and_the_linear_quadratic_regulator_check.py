# The HJB equation and the linear-quadratic regulator -- the check behind the card.
# Cruise control: speed error x (m/s), push u (m/s^2), x' = u, cost the integral of
# x^2 + u^2.  Claim: value V(x) = x^2, best push u = -x.  Roads: the formula; a search
# over u; RK4 stepping of the car; a backward Bellman recursion; RK4 on the Riccati.
import math
X0 = 2.0

def run(k, h=0.01, t_end=60.0):          # RK4 on x' = -k x, cost rate (1 + k^2) x^2
    f = lambda x: (-k * x, (1 + k * k) * x * x)
    x, c, t, half, path = X0, 0.0, 0.0, None, [X0]
    for _ in range(round(t_end / h)):
        a = f(x); b = f(x + h / 2 * a[0]); d = f(x + h / 2 * b[0]); e = f(x + h * d[0])
        xn = x + h / 6 * (a[0] + 2 * b[0] + 2 * d[0] + e[0])
        c += h / 6 * (a[1] + 2 * b[1] + 2 * d[1] + e[1])
        if half is None and xn <= X0 / 2:        # straight line between the two steps
            half = t + h * (x - X0 / 2) / (x - xn)
        x, t = xn, t + h; path.append(x)
    return c, half, path
def ternary(g, lo, hi):                  # the lowest point of a bowl-shaped g
    for _ in range(200):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, m2) if g(m1) < g(m2) else (m1, hi)
    return (lo + hi) / 2
def bellman(h, p=0.0):                   # V = P x^2 on steps of h, back from P = 0
    for _ in range(round(40 / h)):
        p = h + p / (1 + h * p)
    return p
def riccati(s_end, h, p=0.0, g=lambda p: 1 - p * p):   # RK4 on P' = 1 - P^2 in time to go
    for _ in range(round(s_end / h)):
        a = g(p); b = g(p + h / 2 * a); d = g(p + h / 2 * b); p += h / 6 * (a + 2 * b + 2 * d + g(p + h * d))
    return p

tanh = lambda s: (math.exp(2 * s) - 1) / (math.exp(2 * s) + 1)
u_best = ternary(lambda u: X0 * X0 + u * u + 2 * X0 * u, -10, 10)
c1, half, path = run(1.0)
gains = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0]; costs = [run(k)[0] for k in gains]
scan = min((run(k / 100, h=0.02)[0], k / 100) for k in range(25, 301))
print(f"HJB at x = 2, V' = 4: search finds u = {u_best:.4f}, min of x^2 + u^2 + V'u = {X0 * X0 + u_best ** 2 + 2 * X0 * u_best:.6f}")
print(f"cost of u = -x from x0 = 2, RK4 stepped: {c1:.6f}; value V(2) = x0^2 = {X0 * X0:.6f}")
print(f"error halves after {half:.3f} s, stepped; ln 2 = {math.log(2):.3f} s")
print("chart, error x(t) at t = 0 0.5 1 1.5 2 2.5 3:", " ".join(f"{path[i]:.2f}" for i in range(0, 301, 50)))
print("chart, cost of gain k =", " ".join(f"{k}" for k in gains) + ":", " ".join(f"{c:.2f}" for c in costs))
print(f"best gain on a scan 0.25 to 3 in steps of 0.01: k = {scan[1]:.2f}, cost {scan[0]:.4f}")
for h in (0.1, 0.01, 0.001):
    p = bellman(h)
    print(f"Bellman on steps of {h}: P = {p:.6f}, gain {p / (1 + h * p):.6f}, P - 1 = {p - 1:.6f}")
for h in (0.1, 0.05):
    ps = [riccati(s, h) for s in (1, 2, 3)]
    print(f"Riccati RK4 h = {h}: P at 1, 2, 3 s to go = " + " ".join(f"{p:.6f}" for p in ps)
          + f"; worst error vs tanh {max(abs(p - tanh(s)) for p, s in zip(ps, (1, 2, 3))):.1e}")
print(f"tanh(1) = {tanh(1):.6f}; 1 s trip from x0 = 2 costs {X0 * X0 * tanh(1):.4f}, not {X0 * X0:.4f}")
c20, (c05, h05, _) = run(20.0, h=0.001), run(0.5)
print(f"mistake, no push cost: gain 20 gives speed cost {c20[0] / 401:.4f}, true cost {c20[0]:.4f}")
print(f"mistake, V' = x not 2x: gain 0.5, cost {c05:.4f}, halving time {h05:.3f} s")
print(f"mistake, root P = -1: u = +x, error after 3 s = {run(-1.0, t_end=3.0)[2][-1]:.4f} m/s")
assert abs(c1 - X0 * X0) < 1e-6 and abs(half - math.log(2)) < 1e-3   # stepping vs formula
assert abs(scan[1] - 1.0) < 1e-9 and all(abs(c - X0 * X0 * (1 + k * k) / (2 * k)) < 1e-6 for c, k in zip(costs, gains))
assert abs(bellman(0.001) - 1) < 1e-3 and 9 < (bellman(0.01) - 1) / (bellman(0.001) - 1) < 11
assert abs(u_best + X0) < 1e-6 and max(abs(riccati(s, 0.05) - tanh(s)) for s in (1, 2, 3)) < 1e-6
print("ALL CHECKS PASS")
