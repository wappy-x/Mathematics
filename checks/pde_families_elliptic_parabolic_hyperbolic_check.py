# Three families -- the check behind the card.  Standard library only (math).
# One steel bar, h = 0.01 m.  Heat (parabolic): explicit, backward Euler and Crank-Nicolson
# steps against the exact Fourier series, all along the bar.  Sound (hyperbolic): leapfrog against the
# exact standing wave, and backward Euler steps against their mode formula.  A steel plate
# (elliptic): Jacobi sweeps against the exact centre value 25 C and the rate cos(pi h).
from math import sin, cos, exp, sqrt, pi, log, ceil
ALPHA = 1.2e-5                      # diffusivity of steel, m^2/s (illustrative)
C = sqrt(200e9 / 7850)              # sound speed in steel, m/s: sqrt(stiffness / density) (illustrative)
H, N = 0.01, 100                    # grid spacing in m; intervals along the 1 m bar
def sci(x):                         # e-notation with the same digits in Python and Rust
    m, e = f"{x:.2e}".split("e"); return f"{m}e{int(e)}"
def family(a, b, cc):               # the sign of B^2 - 4AC
    d = b * b - 4 * a * cc
    return d, "hyperbolic" if d > 0 else ("parabolic" if d == 0 else "elliptic")
def lam(k, h): return 4 / (h * h) * sin(k * pi * h / 2) ** 2   # grid mode k: rate of the 3-point bend
def thomas(a, b, c, d):             # tridiagonal solve, constant diagonals a (left), b (middle), c (right)
    m = len(d); cp = [0.0] * m; dp = [0.0] * m; cp[0] = c / b; dp[0] = d[0] / b
    for i in range(1, m):
        den = b - a * cp[i - 1]; cp[i] = c / den; dp[i] = (d[i] - a * dp[i - 1]) / den
    x = [0.0] * m; x[m - 1] = dp[m - 1]
    for i in range(m - 2, -1, -1): x[i] = dp[i] - cp[i] * x[i + 1]
    return x
def series(x, t):                       # the exact temperature: Fourier series of the 100 C start
    return sum(400 / pi / k * sin(k * pi * x) * exp(-ALPHA * (k * pi) ** 2 * t) for k in range(1, 400, 2))
def heat_explicit(dt, t_end=3600.0):    # each point moves toward its neighbours, one level back
    u = [0.0] + [100.0] * (N - 1) + [0.0]; r = ALPHA * dt / (H * H)
    for _ in range(round(t_end / dt)):
        u = [0.0] + [u[j] + r * (u[j - 1] - 2 * u[j] + u[j + 1]) for j in range(1, N)] + [0.0]
    return u
def heat_implicit(dt, th=1.0, t_end=3600.0):    # th 1: backward Euler, 0.5: Crank-Nicolson; one solve per step
    u = [0.0] + [100.0] * (N - 1) + [0.0]; r = ALPHA * dt / (H * H); s = (1 - th) * r
    for _ in range(round(t_end / dt)):
        rhs = [u[j] + s * (u[j - 1] - 2 * u[j] + u[j + 1]) for j in range(1, N)]
        u = [0.0] + thomas(-th * r, 1 + 2 * th * r, -th * r, rhs) + [0.0]
    return u
def bend(u, j): return (u[j - 1] - 2 * u[j] + u[j + 1]) / (H * H)
def leapfrog(nu, steps):                # sound: new level from the two before; nu = C dt / H
    dt = nu * H / C; old = [sin(pi * j * H) for j in range(N)] + [0.0]
    now = [0.0] + [old[j] + dt * dt / 2 * C * C * bend(old, j) for j in range(1, N)] + [0.0]
    for _ in range(steps - 1):
        old, now = now, [0.0] + [2 * now[j] - old[j] + dt * dt * C * C * bend(now, j) for j in range(1, N)] + [0.0]
    return now[N // 2], max(abs(x) for x in now)
def sound_implicit(per):                # backward Euler on (u, v) for one period, per steps
    dt = 2 / C / per; k = (C * dt / H) ** 2
    u = [sin(pi * j * H) for j in range(1, N)]; v = [0.0] * (N - 1)
    for _ in range(per):
        u1 = thomas(-k, 1 + 2 * k, -k, [u[i] + dt * v[i] for i in range(N - 1)])
        v = [(u1[i] - u[i]) / dt for i in range(N - 1)]; u = u1
    w = C * sqrt(lam(1, H))
    return sqrt(u[N // 2 - 1] ** 2 + (v[N // 2 - 1] / w) ** 2), (1 + (w * dt) ** 2) ** (-per / 2)
def jacobi(m, marks):                   # plate: each inside point becomes its four neighbours' mean
    u = [[100.0 if j == m and 0 < i < m else 0.0 for i in range(m + 1)] for j in range(m + 1)]; out = {}
    for s in range(1, max(marks) + 1):
        new = [row[:] for row in u]
        for j in range(1, m):
            for i in range(1, m):
                new[j][i] = (u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4
        u = new
        if s in marks: out[s] = u[m // 2][m // 2]
    return out
# 1. Classify from the coefficients of u_xx, u_xy, u_yy (time plays y)
cases = [("heat in the bar, alpha u_xx - u_t", ALPHA, 0, 0), ("sound in the bar, c^2 u_xx - u_tt", C * C, 0, -1),
         ("steady plate, u_xx + u_yy", 1, 0, 1), ("Black-Scholes, S = 100, sigma = 0.2", 0.5 * 0.04 * 100 ** 2, 0, 0)]
kinds = []
for name, a, b, cc in cases:
    d, k = family(a, b, cc); kinds.append(k)
    print(f"{name}: A {sci(a)}, B {b}, C {cc}, B^2 - 4AC {sci(d)} -> {k}")
# 2. Grid modes and the two explicit step limits
l1, lmax = lam(1, H), lam(N - 1, H)
print(f"grid modes, h = {H}: slowest rate {l1:.6f} (pi^2 = {pi * pi:.6f}), fastest {lmax:.2f} (4/h^2 = {4 / H ** 2:.0f})")
w1, wmax = C * sqrt(l1), C * sqrt(lmax)
print(f"sound rings at: slowest {w1:.0f} rad/s, fastest {wmax:.0f} rad/s, spread {wmax / w1:.0f}")
dt_heat, dt_heat_mode = H * H / (2 * ALPHA), 2 / (ALPHA * lmax)
print(f"heat: explicit limit h^2/(2 alpha) = {dt_heat:.4f} s (fastest mode allows {dt_heat_mode:.4f} s); "
      f"slowest decay time {1 / (ALPHA * l1):.0f} s, fastest {1 / (ALPHA * lmax):.2f} s; spread of rates {lmax / l1:.0f}")
dt_wave, period = H / C, 2 / C
print(f"sound: c = {C:.1f} m/s, explicit limit h/c = {dt_wave * 1e6:.4f} us; ring period {period * 1e6:.2f} us = {period / dt_wave:.0f} steps")
# 3. Heat: one hour of cooling, three roads; true errors at the middle and at the worst point of the bar
bar = [series(j / N, 3600.0) for j in range(N + 1)]; exact = bar[N // 2]
print(f"heat middle at 1 h: exact series {exact:.4f} C")
def report(name, u):                    # the middle, its true error, and the largest true error along the bar
    e = [u[j] - bar[j] for j in range(N + 1)]; j = max(range(N + 1), key=lambda i: abs(e[i]))
    print(f"heat {name}: middle {u[N // 2]:.4f}, error {e[N // 2]:+.4f}; largest error {abs(e[j]):.4f} C at x = {j / N:.2f} m")
    return e[N // 2], abs(e[j])
ex4 = report("explicit dt 4 s (900 steps)", heat_explicit(4.0)); be60 = report("backward Euler dt 60 s (60 steps)", heat_implicit(60.0))
be4 = report("backward Euler dt 4 s (900 steps)", heat_implicit(4.0)); cn60 = report("Crank-Nicolson dt 60 s (60 steps)", heat_implicit(60.0, 0.5))
report("backward Euler dt 600 s (6 steps)", heat_implicit(600.0)); blow = max(map(abs, heat_explicit(4.5)))
mids = [heat_implicit(60.0, 1.0, t)[N // 2] - series(0.5, t) for t in (1800.0, 5400.0)]
print(f"heat backward Euler dt 60 s, middle error at 30 min {mids[0]:+.4f}, at 90 min {mids[1]:+.4f}")
fl = [900 * 99 * 5, 60 * (8 * 99 - 7), 900 * (8 * 99 - 7), 60 * (5 * 99 + 8 * 99 - 7)]
print(f"heat flops: explicit 900 x 99 x 5 = {fl[0]}; backward Euler 60 x (8 x 99 - 7) = {fl[1]}, 900 x 785 = {fl[2]}; "
      f"Crank-Nicolson 60 x (5 x 99 + 785) = {fl[3]}; explicit / Crank-Nicolson {fl[0] / fl[3]:.2f}; r at 4 s {ALPHA * 4 / H ** 2:.2f}")
print(f"heat explicit dt 4.5 s = {4.5 / dt_heat:.2f} x limit (r = {ALPHA * 4.5 / H ** 2:.2f}): largest value after 1 h {sci(blow)} C; "
      f"fastest mode x{abs(1 - ALPHA * 4.5 * lmax):.4f} per step")
# 4. Sound: half a period of leapfrog, then backward Euler steps over one period
mid, _ = leapfrog(0.5, 200); _, wild = leapfrog(1.05, 190)
print(f"sound leapfrog cdt/h = 0.5 (dt {0.5 * dt_wave * 1e6:.4f} us), 200 steps to half a period: middle {mid:.10f} um (exact -1), error {sci(mid + 1)}")
print(f"sound leapfrog cdt/h = 1.05, 190 steps: largest value {sci(wild)} um")
for per in (10, 100, 1000):
    grid, formula = sound_implicit(per)
    print(f"sound backward Euler, {per} steps per period: amplitude after one period {grid:.6f} (mode formula {formula:.6f})")
# 5. Plate: no time; Jacobi sweeps toward the exact centre 25 C (four rotated copies add to 100)
plate = jacobi(20, {100, 400, 500, 1200})
print("plate h = 0.05, centre after sweeps: " + ", ".join(f"{s}: {v:.6f}" for s, v in sorted(plate.items())))
rate = ((25 - plate[500]) / (25 - plate[400])) ** 0.01
print(f"plate error shrinks x{rate:.8f} per sweep; cos(pi h) = {cos(pi * 0.05):.8f}")
sweeps = [ceil(log(1e6) / -log(cos(pi * hh))) for hh in (0.05, 0.025, 0.01)]
print(f"sweeps to cut the error a millionfold: h = 0.05 {sweeps[0]}, 0.025 {sweeps[1]}, 0.01 {sweeps[2]}; "
      f"estimate {2 * log(1e6) / pi ** 2:.2f}/h^2 = {2 * log(1e6) / (pi * 0.05) ** 2:.0f} at h = 0.05 (361 unknowns)")
print(f"halve h: heat explicit steps per hour {ceil(3600 / dt_heat)} -> {ceil(3600 / (H * H / 8 / ALPHA))}; "
      f"sound steps per period {period / dt_wave:.0f} -> {2 * period / dt_wave:.0f}; plate sweeps {sweeps[0]} -> {sweeps[1]}")
print("figure, panels centre x " + ", ".join(str(60 + 120 * p) for p in range(3)) + "; rows y 90, 120, 150; spacing 30 (one h or one dt)")
assert kinds == ["parabolic", "hyperbolic", "elliptic", "parabolic"]
assert abs(ex4[0]) <= ex4[1] < 0.02 and cn60[1] < 0.01 and be60[1] > 0.1   # explicit and Crank-Nicolson land on the series
assert 12 < be60[1] / be4[1] < 18 and abs(be60[0]) < 0.01 < -mids[0]   # backward Euler: first order; lucky middle
assert blow > 1e10 and abs(1 - ALPHA * 4.5 * lmax) > 1          # over the limit: the fastest mode grows
assert 1 < dt_heat_mode / dt_heat < 1.001                        # the mode limit sits just above h^2/(2 alpha)
assert abs(mid + 1) < 1e-6 and wild > 1e10                       # leapfrog: exact inside h/c, wild outside
assert all(abs(g - f) < 1e-9 for g, f in map(sound_implicit, (10, 100)))   # grid run = mode formula
assert abs(plate[1200] - 25) < 1e-4 and abs(rate - cos(pi * 0.05)) < 1e-8  # superposition and Jacobi's rate
print("ALL CHECKS PASS")
