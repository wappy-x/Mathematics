# A PDE problem -- the check behind the card.  Only math is imported.  The problem:
# a 1 m square steel plate, edges held at 0 C, starting at 80 sin(pi x) sin(pi y) C,
# obeying u_t = kappa (u_xx + u_yy).  Road one: the closed form.  Road two: an explicit
# grid that never sees it.  Road three: the equation's residual by centred differences.
from math import sin, cos, exp, pi, log
KAPPA, L, U0, HOUR = 1.2e-5, 1.0, 80.0, 3600.0      # m^2/s (illustrative), m, C, s
RATE = 2 * pi * pi * KAPPA / L ** 2                 # decay rate of the closed form, 1/s

# The order of each plate problem, read off the derivatives it contains: (in x, in y, in t)
PROBLEMS = [("cooling, u_t = kappa (u_xx + u_yy)", [(0, 0, 1), (2, 0, 0), (0, 2, 0)]),
            ("held steady, u_xx + u_yy = 0", [(2, 0, 0), (0, 2, 0)]),
            ("ringing membrane, u_tt = c^2 (u_xx + u_yy)", [(0, 0, 2), (2, 0, 0), (0, 2, 0)]),
            ("ringing plate, w_tt + D/(rho H)(w_xxxx + 2w_xxyy + w_yyyy) = 0",
             [(0, 0, 2), (4, 0, 0), (2, 2, 0), (0, 4, 0)])]

def exact(x, y, t):                    # road one: the closed form
    return U0 * exp(-RATE * t) * sin(pi * x / L) * sin(pi * y / L)

def grid(n, steps, t_end, insulated=False):   # road two: each point moves toward its neighbours' mean
    h, dt = L / n, t_end / steps
    lam = KAPPA * dt / (h * h)         # grid ratio kappa dt / h^2
    assert lam <= 0.25                 # inside the explicit scheme's stability limit
    u = [[U0 * sin(pi * i / n) * sin(pi * j / n) for i in range(n + 1)] for j in range(n + 1)]
    edge = lambda i, j: i in (0, n) or j in (0, n)
    if not insulated:
        u = [[0.0 if edge(i, j) else u[j][i] for i in range(n + 1)] for j in range(n + 1)]
    for _ in range(steps):
        new = [row[:] for row in u]
        for j in range(n + 1):
            for i in range(n + 1):
                if edge(i, j) and not insulated:
                    continue           # an edge point is data, not equation
                w = u[j][i - 1] if i > 0 else u[j][1]        # insulated: mirror across the edge
                e = u[j][i + 1] if i < n else u[j][n - 1]
                s = u[j - 1][i] if j > 0 else u[1][i]
                nn = u[j + 1][i] if j < n else u[n - 1][i]
                new[j][i] = u[j][i] + lam * (w + e + s + nn - 4 * u[j][i])
        u = new
    return u[n // 2][n // 2]

def residual(x, y, t, d, dt=1.0):      # road three: u_t - kappa (u_xx + u_yy) by centred differences
    ut = (exact(x, y, t + dt) - exact(x, y, t - dt)) / (2 * dt)
    lap = (exact(x + d, y, t) + exact(x - d, y, t) + exact(x, y + d, t) + exact(x, y - d, t)
           - 4 * exact(x, y, t)) / (d * d)
    return ut, ut - KAPPA * lap

def insulated_centre(t, terms=40):     # cosine series, insulated edges: value, first omitted term
    tau = KAPPA * t / L ** 2
    a = lambda k: 2 / pi if k == 0 else -4 / (pi * (4 * k * k - 1))
    s = sum(a(k) * (-1) ** k * exp(-4 * k * k * pi * pi * tau) for k in range(terms))
    return U0 * s * s, abs(a(terms)) * exp(-4 * terms * terms * pi * pi * tau)

orders = []
for name, terms in PROBLEMS:
    total = max(a + b + c for a, b, c in terms)
    in_t, in_space = max(c for _, _, c in terms), max(a + b for a, b, _ in terms)
    orders.append((total, in_t, in_space // 2))
    print(f"{name}: order {total}; {in_t} start field(s); {in_space // 2} condition(s) per edge point")
print(f"kappa {KAPPA * 1e5:.1f}e-5 m^2/s; decay rate 2 pi^2 kappa / L^2 = {RATE * 1e4:.5f}e-4 per s")
c1 = exact(0.5, 0.5, HOUR)
print(f"exponent at 1 h: {RATE * HOUR:.6f}; factor {exp(-RATE * HOUR):.5f}; centre at 1 h: {c1:.2f} C")
print(f"centre halves after {log(2) / RATE:.1f} s = {log(2) / RATE / 60:.1f} min")
gs, errs = [], []
for n, steps in [(10, 20), (20, 80), (40, 320)]:
    g = grid(n, steps, HOUR)
    gs.append(g)
    errs.append(abs(g - c1))
    print(f"grid h = {L / n:.3f} m, dt = {HOUR / steps:.2f} s: centre {g:.4f} C, error {abs(g - c1):.4f} C")
print(f"observed order: {log(errs[0] / errs[1], 2):.2f}, {log(errs[1] / errs[2], 2):.2f}")
ut, r1 = residual(0.5, 0.5, HOUR, 0.01)
_, r2 = residual(0.5, 0.5, HOUR, 0.005)
print(f"residual at the centre, 1 h: u_t = {ut * 1e3:.4f}e-3 C/s; u_t - kappa lap u = {r1 * 1e7:.4f}e-7 "
      f"at step 0.01 m, {r2 * 1e7:.4f}e-7 at 0.005 m; ratio {r1 / r2:.2f}")
edge_max = max(abs(exact(p / 10, q, t)) for p in range(11) for q in (0.0, L) for t in (0.0, HOUR))
start_gap = max(abs(exact(p / 10, q / 10, 0.0) - U0 * sin(pi * p / 10) * sin(pi * q / 10))
                for p in range(11) for q in range(11))
print(f"data: every edge value below 1e-12 C: {'yes' if edge_max < 1e-12 else 'no'}; "
      f"start matches g: {'yes' if start_gap < 1e-12 else 'no'}")
forced = -RATE * U0
lap_g = (4 * U0 * sin(pi * 0.501) - 4 * U0 * sin(pi * 0.5)) / 1e-6   # discrete bend of g at the centre (x and y alike)
print(f"start rate the equation forces at the centre: {forced:.6f} C/s = {forced * 60:.4f} C/min; "
      f"from g's bend: {KAPPA * lap_g:.6f} C/s")
ins, omitted = insulated_centre(HOUR, 3)
gi = grid(40, 320, HOUR, insulated=True)
print(f"insulated edges, centre at 1 h: series {ins:.2f} C (3 terms, first omitted {omitted * 1e9:.1f}e-9), grid h = 0.025 m {gi:.2f} C")
print(f"insulated edges, long run: the mean 80 (2/pi)^2 = {U0 * 4 / pi ** 2:.2f} C; series at 12 h {insulated_centre(12 * HOUR)[0]:.2f} C")
print(f"mistake 1, no start given: u = 0 also fits; centre at 1 h 0.00 C, not {c1:.2f} C")
print(f"mistake 2, no edge rule: insulated edges also fit; centre at 1 h {ins:.2f} C, not {c1:.2f} C")
print(f"mistake 3, start rate 0 added: the equation forces {forced:.6f} C/s; no solution")
hours = [k / 2 for k in range(9)]
print("chart held centre:", ", ".join(f"{exact(0.5, 0.5, hh * HOUR):.1f}" for hh in hours))
print("chart insulated centre:", ", ".join(f"{insulated_centre(hh * HOUR)[0]:.1f}" for hh in hours))
assert orders == [(2, 1, 1), (2, 0, 1), (2, 2, 1), (4, 2, 2)]          # counts known from the equations
assert errs[2] < 0.03 and abs((4 * gs[2] - gs[1]) / 3 - c1) < 0.002     # closed form against the grid
assert 1.9 < log(errs[0] / errs[1], 2) < 2.1 and 1.9 < log(errs[1] / errs[2], 2) < 2.1   # second order
assert abs(r1) < 1e-3 * abs(ut) and 3.9 < r1 / r2 < 4.1                  # residual shrinks as step^2
assert abs(KAPPA * lap_g - forced) < 1e-6 and abs(ins - gi) < 0.05 and abs(ins - c1) > 5
print("ALL CHECKS PASS")
