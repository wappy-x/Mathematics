# Predator and prey -- the check behind the card.  Gazelles x (hundreds), cheetahs y (tens), years,
# every rate 1: x' = x - x y, y' = -y + x y, from (2, 1).  Road one reads the orbit off the conserved
# quantity H = x - ln x + y - ln y; road two steps the equations by Runge-Kutta 4, never using H.
from math import log, sqrt, pi
def lv(x, y): return (x - x * y, -y + x * y)               # the rate law
def ad(s, k, c): return (s[0] + c * k[0], s[1] + c * k[1])
def rk4(g, s, h):                                          # one Runge-Kutta 4 step
    k1 = g(*s); k2 = g(*ad(s, k1, h / 2)); k3 = g(*ad(s, k2, h / 2)); k4 = g(*ad(s, k3, h))
    return ad(s, [k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i] for i in (0, 1)], h / 6)
def euler(g, s, h): return ad(s, g(*s), h)                 # one plain step along the slope
def run(g, s, h, n, step=rk4):
    out = [s]
    for _ in range(n): s = step(g, s, h); out.append(s)
    return out
def H(x, y): return x - log(x) + y - log(y)                # the conserved quantity
def bisect(fn, a, b):                                      # root of fn between a and b
    for _ in range(200): m = (a + b) / 2; a, b = (m, b) if (fn(a) > 0) == (fn(m) > 0) else (a, m)
    return (a + b) / 2
def period(s, h=0.001):                                    # time until y next climbs back through its start
    t, p, q = 0.0, s, rk4(lv, s, h)
    while not (t > 1 and p[1] < s[1] <= q[1]): t, p, q = t + h, q, rk4(lv, q, h)
    return t + h * (s[1] - p[1]) / (q[1] - p[1])
def jac(x, y, d=1e-6):                                     # Jacobian by differences
    a, b = lv(x + d, y), lv(x - d, y); c, e = lv(x, y + d), lv(x, y - d)
    return [[(a[0] - b[0]) / (2 * d), (c[0] - e[0]) / (2 * d)], [(a[1] - b[1]) / (2 * d), (c[1] - e[1]) / (2 * d)]]
def eig(J):                                                 # from trace and determinant
    tr, det = J[0][0] + J[1][1], J[0][0] * J[1][1] - J[0][1] * J[1][0]; disc = tr * tr / 4 - det
    if disc >= 0: return f"{tr / 2 + sqrt(disc):+.4f}, {tr / 2 - sqrt(disc):+.4f}"
    return f"{tr / 2:+.4f} +/- {sqrt(-disc):.4f}i"
def row(v, fmt=".2f"): return " ".join(format(u, fmt) for u in v)
H0 = H(2, 1); lvl = lambda u: u - log(u) - (H0 - 1)       # the level curve on the line y = 1
lo, hi = bisect(lvl, 1e-9, 1), bisect(lvl, 1, 10)
T, Ts = period((2, 1)), period((1.01, 1)); orb = run(lv, (2, 1), T / 4800, 4800)[:-1]
xs, ys = [p[0] for p in orb], [p[1] for p in orb]; J1 = jac(1, 1); w = sqrt(J1[0][0] * J1[1][1] - J1[0][1] * J1[1][0])
drift = [max(abs(H(*p) - H0) for p in run(lv, (2, 1), h, round(T / h))) for h in (0.1, 0.05, 0.025)]
tl = run(lv, (2, 1), 0.005, 2600)[::100]; eu = [H(*run(lv, (2, 1), h, round(20 / h), euler)[-1]) for h in (0.1, 0.01)]
cap = run(lambda x, y: (x * (1 - x / 5) - x * y, -y + x * y), (2, 1), 0.01, 4000)[-1]
print("gazelles x (hundreds), cheetahs y (tens), years: x' = x - xy, y' = -y + xy, start (2, 1)")
print(f"rests: rates at (0, 0) = {row(lv(0, 0))}, at (1, 1) = {row(lv(1, 1))}")
print(f"Jacobian at (0, 0): {row(jac(0, 0)[0], '.4f')} / {row(jac(0, 0)[1], '.4f')}; eigenvalues {eig(jac(0, 0))}: a saddle")
print(f"Jacobian at (1, 1): {row(J1[0], '.4f')} / {row(J1[1], '.4f')}; eigenvalues {eig(J1)}: a linear centre, period 2 pi / {w:.4f} = {2 * pi / w:.4f}")
print(f"conserved: H(2, 1) = 3 - ln 2 = {H0:.6f}; H(1, 1) = {H(1, 1):.6f}, the lowest value")
print(f"road 1, level curve u - ln u = {H0 - 1:.6f} by bisection: from {lo:.6f} to {hi:.6f} for each population; minus ln there {-log(lo):.6f}, {-log(hi):.6f}")
print(f"road 2, RK4 over one lap: x from {min(xs):.6f} to {max(xs):.6f}, y from {min(ys):.6f} to {max(ys):.6f}; period {T:.4f} years")
print(f"averages over one lap: gazelles {sum(xs) / len(xs):.6f}, cheetahs {sum(ys) / len(ys):.6f}")
print(f"small swing from (1.01, 1): period {Ts:.4f} years, against 2 pi = {2 * pi:.4f}")
print(f"RK4 largest drift in H over one lap, in billionths, h = 0.1, 0.05, 0.025: {row(d * 1e9 for d in drift)}; ratios {drift[0] / drift[1]:.1f}, {drift[1] / drift[2]:.1f}")
print("chart, gazelles, years 0 to 13 by 0.5:", row(p[0] for p in tl))
print("chart, cheetahs, years 0 to 13 by 0.5:", row(p[1] for p in tl))
print(f"mistake 1, Euler steps for 20 years: H ends at {eu[0]:.4f} (h = 0.1) and {eu[1]:.4f} (h = 0.01), not {H0:.4f}")
print(f"mistake 2, gazelles capped at 5 (hundreds): after 40 years ({cap[0]:.4f}, {cap[1]:.4f}), closing on the rest (1, 0.8)")
print(f"mistake 3, midpoint of peak and trough {(lo + hi) / 2:.4f}, not the average 1; small-swing period {2 * pi:.4f} for this lap, not {T:.4f}")
X, Y = (lambda x: 50 + 80 * x), (lambda y: 205 - 80 * y)   # 80 units per hundred gazelles and per ten cheetahs
print(f"figure, origin ({X(0):.1f}, {Y(0):.1f}); rest (1, 1) at ({X(1):.1f}, {Y(1):.1f}); start (2, 1) at ({X(2):.1f}, {Y(1):.1f})")
print("figure, orbit:", " ".join(f"{X(p[0]):.1f},{Y(p[1]):.1f}" for p in orb[::200]))
assert abs(min(xs) - lo) < 1e-6 and abs(max(ys) - hi) < 1e-6    # road 2 lands on road 1's curve
assert abs(sum(xs) / len(xs) - 1) < 1e-6 and abs(sum(ys) / len(ys) - 1) < 1e-6   # averages proved to be 1
assert abs(Ts - 2 * pi / w) < 1e-3                                # small laps take the Jacobian's period
assert 12 < drift[0] / drift[1] < 20                              # RK4 error falls at order four
print("ALL CHECKS PASS")
