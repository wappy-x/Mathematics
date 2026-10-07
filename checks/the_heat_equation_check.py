# The heat equation -- the check behind the card.  Only math's sin, exp, log
# and pi are imported.  The rod: 1 m, ends held at 0 C, kappa = 1 in scaled
# time, starting at u = sin(pi x).  Road one is the formula e^(-kappa n^2 pi^2 t).
# Road two is a grid where each point drifts toward its neighbours' average.
from math import sin, exp, log, pi

def step(u, r, heat=0.0):                  # one grid step, ends held at 0
    return [0.0] + [u[i] + r * (u[i - 1] - 2 * u[i] + u[i + 1]) + heat
                    for i in range(1, len(u) - 1)] + [0.0]

def grid_half_life(n, N, r=0.25):          # step sin(n pi x) until its peak halves
    dx = 1 / N; dt = r * dx * dx
    u = [sin(n * pi * i * dx) for i in range(N + 1)]
    j = N // (2 * n); top = u[j]; t = 0.0
    while True:
        v = step(u, r); t += dt
        if v[j] <= top / 2:                # the last step, read as a pure exponential
            return t - dt + dt * log(2 * u[j] / top) / log(u[j] / v[j])
        u = v

U = lambda x, t: exp(-pi * pi * t) * sin(pi * x)       # the formula, kappa = 1
lam1, lam2 = pi * pi, 4 * pi * pi
h1, h2 = log(2) / lam1, log(2) / lam2
print(f"decay rate kappa n^2 pi^2: n=1 {lam1:.6f}, n=2 {lam2:.6f} per time unit")
print(f"half-life ln2/rate: n=1 {h1:.6f}, n=2 {h2:.6f}, ratio {h1 / h2:.3f}")
g = {N: grid_half_life(1, N) for N in (10, 20, 40)}
for N in (10, 20, 40):
    print(f"grid N={N}: half-life {g[N]:.6f}, error {g[N] - h1:.7f}")
print(f"error shrinks per halving of the spacing h, dt = h^2/4: {(g[10] - h1) / (g[20] - h1):.3f}, {(g[20] - h1) / (g[40] - h1):.3f}")
g2 = grid_half_life(2, 40)
print(f"grid N=40, n=2: half-life {g2:.6f}; grid ratio {g[40] / g2:.3f}")
e = 1e-4; x, t = 0.3, 0.05
ut = (U(x, t + e) - U(x, t - e)) / (2 * e)
uxx = (U(x + e, t) - 2 * U(x, t) + U(x - e, t)) / (e * e)
print(f"formula at x=0.3, t=0.05, by differences: u_t {ut:.6f}, u_xx {uxx:.6f}")
N = 40; u = [min(i / 12, (N - i) / 28) for i in range(N + 1)]   # tent, peak 1 at x=0.3
peaks = []
for k in range(400):
    u = step(u, 0.25); peaks.append(max(u))
print(f"tent start, peak 1 at x=0.3: largest later value {max(peaks):.6f}, at t=0.0625 {peaks[-1]:.6f}")
N = 20; u = [sin(pi * i / N) for i in range(N + 1)]            # a heater: 20 C per time unit
for k in range(1600):
    u = step(u, 0.25, 20 * 0.25 / (N * N))
print(f"heater inside: middle at t=1 {u[N // 2]:.6f}; steady formula 20/8 = {20 / 8:.6f}")
print(f"mistake, rate linear in n: n=2 half-life {log(2) / (2 * pi * pi):.6f}, true {h2:.6f}")
print(f"mistake, sign flipped: ripple 0.001 at n=10 after t=0.1 grows by e^{100 * pi * pi * 0.1:.3f} = 10^{100 * pi * pi * 0.1 / log(10):.2f}")
tu = 1 / 1.11e-4                                               # copper, 1 m: seconds per time unit
print(f"copper rod 1 m, kappa 1.11e-4 m^2/s: time unit {tu:.0f} s, half-life {h1 * tu:.0f} s = {h1 * tu / 60:.1f} min")
ts = [0.035 * k for k in range(9)]
print("chart n=1:", ", ".join(f"{exp(-lam1 * s):.2f}" for s in ts))
print("chart n=2:", ", ".join(f"{exp(-lam2 * s):.2f}" for s in ts))
print("chart times:", ", ".join(f"{s:.3f}" for s in ts))
a1, a2 = U(0.5, h1), exp(-lam2 * h1)                        # heights after one half-life of n=1
print(f"figure, x 40+300x, y 120-90u; at t=0.070 heights n=1 {a1:.4f}, n=2 {a2:.4f}, y {120 - 90 * a1:.1f}, {120 - 90 * a2:.1f}")
assert abs(g[40] - h1) < 2e-5 and abs(g2 - h2) < 2e-5        # the grid meets the formula
assert abs(ut - uxx) < 1e-5 * abs(uxx)                        # the formula obeys u_t = u_xx
assert max(peaks) <= 1.0 and all(a >= b for a, b in zip(peaks, peaks[1:]))   # no new hot spot
assert abs(u[N // 2] - 2.5) < 1e-3                            # the heater breaks the bound
print("ALL CHECKS PASS")
