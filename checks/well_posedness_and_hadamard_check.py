# Well posed -- the check behind the card.  Standard library only: math for exp,
# log, sin, sinh.  Road one is the closed form for each pattern (mode).  Road two
# steps the plate on a grid of points that never sees exp, forwards and then
# backwards, and marches Hadamard's slope data up the plate by RK4, which never
# sees sinh.  A centred-difference residual checks Hadamard's solution itself.
from math import exp, log, sin, sinh, pi, log10, floor

KAPPA, ELL = 1.2e-5, 1.0            # steel diffusivity (m^2/s, illustrative), plate side (m)
HOUR, DAY = 3600.0, 86400.0

def sci(x, k=2):                    # 1.80e9: the same digits in Python and Rust
    e = floor(log10(abs(x)))
    m = x / 10.0 ** e
    if round(abs(m), k) >= 10.0:
        m, e = m / 10.0, e + 1
    return f"{m:.{k}f}e{e}"

def rate(m, n):                     # decay rate of the (m, n) pattern, per second
    return KAPPA * pi * pi * (m * m + n * n) / ELL ** 2

def amp(m, n, tau):                 # road one: how much going back tau seconds multiplies it
    return exp(rate(m, n) * tau)

# ---- forward a day: yesterday's 50 C hump, read today ----
a11 = amp(1, 1, DAY)
print(f"(1,1) rate {sci(rate(1, 1), 4)} per s; one day: exponent {rate(1, 1) * DAY:.2f}, factor {sci(a11)}")
print(f"50 C hump yesterday -> {sci(50 / a11)} C today; a 0.01 C reading error -> {sci(0.01 * a11)} C yesterday")

# ---- back one hour, pattern by pattern, with a 0.01 C error in each ----
print(f"worked (5,5): pi^2 {pi * pi:.4f}, kappa pi^2 {sci(KAPPA * pi * pi, 4)} per s, x 50 = {sci(rate(5, 5), 4)} per s, x 3600 s = {rate(5, 5) * HOUR:.3f}")
for m in (1, 2, 3, 5, 10):
    lt = rate(m, m) * HOUR
    print(f"back 1 h, mode ({m},{m}), patches {100 * ELL / m:.0f} cm: rate x 1 h {lt:.3f}, "
          f"factor {sci(exp(lt))}, 0.01 C error -> {sci(0.01 * exp(lt))} C, forward x{sci(exp(-lt))}")
print("1e-6 C error in mode (10,10), back 1 h ->", sci(1e-6 * amp(10, 10, HOUR)), "C")
for m in (100, 300, 1000):
    print(f"back 1 s, mode ({m},{m}), patches {1000 * ELL / m:.0f} mm: factor {sci(amp(m, m, 1.0))}")

# ---- road two: the plate on an N x N grid, explicit time steps, no exp ----
def grid_run(N, m, tau, K, back=False, seed=0.0):
    h, dt, sg = ELL / N, tau / K, (-1.0 if back else 1.0)
    u = [[sin(m * pi * i * h) * sin(m * pi * j * h) + seed * sin((N - 1) * pi * i * h)
          * sin((N - 1) * pi * j * h) for j in range(N + 1)] for i in range(N + 1)]
    c = sg * KAPPA * dt / (h * h)
    for _ in range(K):              # u(t + dt) = u + dt * kappa * Laplacian(u); back: dt < 0
        u = [[0.0] * (N + 1)] + [[0.0] + [u[i][j] + c * (u[i + 1][j] + u[i - 1][j] + u[i][j + 1]
              + u[i][j - 1] - 4 * u[i][j]) for j in range(1, N)] + [0.0] for i in range(1, N)] + [[0.0] * (N + 1)]
    i0 = N // (2 * m)               # a grid point near a peak of the pattern
    return u[i0][i0] / (sin((N - 1 if seed else m) * pi * i0 * h) ** 2)

g10, g20 = 1 / grid_run(10, 2, HOUR, 4000), 1 / grid_run(20, 2, HOUR, 4000)
exact = rate(2, 2) * HOUR
e10, e20 = exact - log(g10), exact - log(g20)
rich = (4 * (exact - e20) - (exact - e10)) / 3
print(f"grid forward 1 h, mode (2,2): 1/decay at h = 10 cm {g10:.3f}, at h = 5 cm {g20:.3f}; closed form {exp(exact):.3f}")
print(f"grid exponent short by {e10:.4f} then {e20:.4f}: ratio {e10 / e20:.2f} (order 2); extrapolated {rich:.4f} vs {exact:.4f}")
gb = grid_run(20, 2, HOUR, 4000, back=True, seed=1e-6)
step = 1 + KAPPA * (HOUR / 4000) / 0.05 ** 2 * 8 * sin(19 * pi * 0.05 / 2) ** 2
print(f"grid backward 1 h, h = 5 cm, (2,2) plus 1e-6 C in its finest ripple (19,19): ripple {sci(gb)} C; "
      f"per-step factor {step:.5f}, predicted {sci(1e-6 * step ** 4000)} C")

# ---- Hadamard: u_xx + u_yy = 0, u(x,0) = 0, u_y(x,0) = sin(kx)/k ----
def rk4_height(k, steps=4000):      # a'' = k^2 a, a(0) = 0, a'(0) = 1/k; u = a(y) sin(kx)
    a, b, dy = 0.0, 1.0 / k, 1.0 / steps
    f = lambda a, b: (b, k * k * a)
    for _ in range(steps):
        k1 = f(a, b); k2 = f(a + dy / 2 * k1[0], b + dy / 2 * k1[1])
        k3 = f(a + dy / 2 * k2[0], b + dy / 2 * k2[1]); k4 = f(a + dy * k3[0], b + dy * k3[1])
        a += dy / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        b += dy / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return a

had = []
for k in (10, 20, 40):
    cf, rk = sinh(k) / k ** 2, rk4_height(k)
    had.append((cf, rk))
    print(f"Hadamard k = {k}: data size {1 / k:.3f}, at y = 1 m closed form {sci(cf)}, RK4 {sci(rk)}; "
          f"ratio over data: plain {sci(cf * k)}, counting 4 derivatives {sci(cf / k ** 3)}")
print(f"as on the wing 08 card: k = 10 gives {had[0][0]:.2f}, k = 20 gives {had[1][0]:.0f}")
r = lambda x, y, k: sin(k * x) * sinh(k * y) / k ** 2
def lap(d):                         # u_xx and u_yy by centred differences at (0.3, 0.5), k = 10
    uxx = (r(0.3 + d, 0.5, 10) - 2 * r(0.3, 0.5, 10) + r(0.3 - d, 0.5, 10)) / d ** 2
    return uxx, (r(0.3, 0.5 + d, 10) - 2 * r(0.3, 0.5, 10) + r(0.3, 0.5 - d, 10)) / d ** 2
uxx, uyy = lap(1e-3)
res, res2 = uxx + uyy, sum(lap(5e-4))
print(f"Hadamard solution, k = 10, at (0.3, 0.5): u_xx {uxx:.4f}, u_yy {uyy:.4f}, sum {sci(res)}; half step {sci(res2)}")

# ---- chart: log10 of the backward factor, modes (m,m), m = 1..10 ----
print("chart, back 1 h:", ", ".join(f"{log10(amp(m, m, HOUR)):.2f}" for m in range(1, 11)))
print("chart, back 10 min:", ", ".join(f"{log10(amp(m, m, 600.0)):.2f}" for m in range(1, 11)))

assert abs(g20 / exp(exact) - 1) < 0.04 and abs(g10 / exp(exact) - 1) < 0.15   # grid agrees with closed form
assert 3.5 < e10 / e20 < 4.5 and abs(rich - exact) < 0.005                      # at second order in h
assert all(abs(rk / cf - 1) < 1e-8 for cf, rk in had)                           # RK4 march = sinh(k)/k^2
assert abs(gb / (1e-6 * step ** 4000) - 1) < 1e-6                              # back-run = its own law
assert abs(res) < 2e-5 * abs(uxx) and 3.8 < res / res2 < 4.2                   # it solves Laplace
assert had[2][0] * 40 > had[1][0] * 20 > had[0][0] * 10 > 1000                  # solution over data rises with k
print("ALL CHECKS PASS")
