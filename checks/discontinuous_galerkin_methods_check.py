# Discontinuous Galerkin for u_t + u_x = 0 on a 1 m loop -- the check behind the card.
# Standard library only; math supplies sin, cos, pi, sqrt, log2, log10.
# Road 1: after one lap the exact answer is the starting bump.  Road 2: DG with p = 0, 1, 2
# on 10, 20, 40 cells, and the observed orders.  Road 3: p = 0 against the upwind step of
# the Flow problems card, and the energy identity against the summed squared jumps.
from math import sin, cos, pi, sqrt, log2, log10

def sci(x): m, e = f"{x:.3e}".split("e"); return f"{m}e{int(e)}"   # Rust-style exponent
def P(k, x):                                  # Legendre polynomial P_k(x), by recurrence
    p0, p1 = 1.0, x
    if k == 0: return 1.0
    for n in range(1, k): p0, p1 = p1, ((2 * n + 1) * x * p1 - n * p0) / (n + 1)
    return p1
def gauss(n):                                 # Gauss-Legendre nodes and weights, by Newton
    xs, ws = [], []
    for i in range(n):
        x = cos(pi * (i + 0.75) / (n + 0.5))
        for _ in range(50): x -= P(n, x) * (x * x - 1) / (n * (x * P(n, x) - P(n - 1, x)))
        dp = n * (x * P(n, x) - P(n - 1, x)) / (x * x - 1)
        xs.append(x); ws.append(2 / ((1 - x * x) * dp * dp))
    return xs, ws
GX, GW = gauss(5)
def sq(v): return v * v
def tot(vals):                                # plain left-to-right sum, as Rust's sum() does
    s = 0.0
    for v in vals: s += v
    return s
def bump(x): return sq(sin(pi * x))            # the dye at t = 0; also the exact answer at t = 1
def square(x): return 1.0 if 0.25 <= x % 1.0 < 0.75 else 0.0

def project(f, N, p):                         # a[j][k]: Legendre coefficients in cell j
    return [[(2 * k + 1) / 2 * tot(w * f((j + (1 + x) / 2) / N) * P(k, x) for x, w in zip(GX, GW))
             for k in range(p + 1)] for j in range(N)]
def edges(a):                                 # values at each cell's right and left edge
    return [tot(c) for c in a], [tot(c * (-1) ** k for k, c in enumerate(cj)) for cj in a]
def jumps(a):                                 # sum over edges of (jump in u)^2
    R, L = edges(a); return tot(sq(R[j] - L[(j + 1) % len(a)]) for j in range(len(a)))
def rhs(a, beta):                             # da/dt; beta = 1 upwind, 0 central, -1 downwind
    N = len(a); R, L = edges(a)
    F = [0.5 * (R[j] + L[(j + 1) % N]) + 0.5 * beta * (R[j] - L[(j + 1) % N]) for j in range(N)]
    return [[(2 * k + 1) * N * (tot(2 * a[j][m] for m in range(k) if (k - m) % 2)
             - (F[j] - F[j - 1] * (-1) ** k)) for k in range(len(a[0]))] for j in range(N)]
def lin(s, A, t, B): return [[s * x + t * y for x, y in zip(r, q)] for r, q in zip(A, B)]
def minmod(a, b, c):
    if a > 0 and b > 0 and c > 0: return min(a, b, c)
    if a < 0 and b < 0 and c < 0: return max(a, b, c)
    return 0.0
def limit(a):                                 # p = 1 slope limiter: keep the mean, clip the slope
    N = len(a)
    return [[a[j][0], minmod(a[j][1], a[(j + 1) % N][0] - a[j][0], a[j][0] - a[j - 1][0])] for j in range(N)]
def run(p, N, beta=1.0, nu=0.1, laps=1, f=bump, euler=False, lim=False):
    a = project(f, N, p)
    n = round(laps * N / nu); dt = laps / n; lost = 0.0
    g = limit if lim else (lambda b: b)
    for _ in range(n):
        j0 = jumps(a)
        if euler: a = lin(1, a, dt, rhs(a, beta))
        else:                                 # three-stage, third-order Runge-Kutta (Shu-Osher)
            u1 = g(lin(1, a, dt, rhs(a, beta)))
            u2 = g(lin(0.75, a, 0.25, lin(1, u1, dt, rhs(u1, beta))))
            a = g(lin(1 / 3, a, 2 / 3, lin(1, u2, dt, rhs(u2, beta))))
        lost += dt * (j0 + jumps(a)) / 2      # trapezoid rule for the integral of the jumps
    return a, lost
def l2err(a, f=bump):
    N = len(a)
    return sqrt(tot(w / (2 * N) * sq(tot(c * P(k, x) for k, c in enumerate(a[j])) - f((j + (1 + x) / 2) / N))
                    for j in range(N) for x, w in zip(GX, GW)))
def energy(a): return tot(c * c / (len(a) * (2 * k + 1)) for cj in a for k, c in enumerate(cj))

print("loop 1 m, speed c = 1 m/s, one lap T = 1 s, dye u0 = sin(pi x)^2; exact answer after one lap = u0")
print("Gauss 5-point nodes: " + " ".join(f"{x:.6f}" for x in GX) + "; weights add to " + f"{tot(GW):.12f}")
g8 = tot(w * x ** 8 for x, w in zip(GX, GW))
b0 = project(bump, 10, 0); u = [c[0] for c in b0]; dg = b0
for _ in range(13):                           # road 3: p = 0 with Euler steps at nu = 0.8
    u = [u[j] - 0.8 * (u[j] - u[j - 1]) for j in range(10)]
    dg = lin(1, dg, 0.08, rhs(dg, 1.0))
d_up = max(abs(x - c[0]) for x, c in zip(u, dg))
print(f"p = 0, Euler steps, nu = 0.8, 13 steps: largest gap from the upwind step u - nu(u - u_left) = {sci(d_up)}")
print("L2 error after one lap, upwind flux, third-order Runge-Kutta, nu = 0.1:")
E = {}
for p in range(3):
    for N in (10, 20, 40):
        E[p, N] = l2err(run(p, N)[0])
        tail = f"  ratio {E[p, N // 2] / E[p, N]:.2f}  observed order {log2(E[p, N // 2] / E[p, N]):.2f}" if N > 10 else ""
        print(f"  p = {p}  N = {N:<3} h = {1 / N:<6} error {sci(E[p, N])}{tail}")
a1, lost = run(1, 10); R, L = edges(a1)
print(f"10 cells after one lap: p = 0 peak cell {max(c[0] for c in run(0, 10)[0]):.4f};"
      f" p = 1 at x = 0.5 left {R[4]:.4f}, right {L[5]:.4f}, jump {L[5] - R[4]:.4f}")
a = project(bump, 10, 1); R, L = edges(a); da = rhs(a, 1.0)
xl, xr = 0.4, 0.5
avg = 0.5 - (sin(2 * pi * xr) - sin(2 * pi * xl)) / (4 * pi * (xr - xl))
print(f"hand step, p = 1, 10 cells, t = 0: cell [0.3, 0.4] a0 {a[3][0]:.6f} a1 {a[3][1]:.6f};"
      f" cell [0.4, 0.5] a0 {a[4][0]:.6f} a1 {a[4][1]:.6f}")
print(f"  closed-form average of cell [0.4, 0.5] {avg:.6f}; edge values: 0.4 from the left {R[3]:.6f},"
      f" 0.5 from the left {R[4]:.6f}")
print(f"  da0/dt = -({R[4]:.6f} - {R[3]:.6f}) / 0.1 = {da[4][0]:.6f};"
      f" da1/dt = 30 x (2 x {a[4][0]:.6f} - {R[4]:.6f} - {R[3]:.6f}) = {da[4][1]:.6f}")
e0 = energy(a); a05, lost05 = run(1, 10, nu=0.05); gap, gap05 = e0 - energy(a1) - lost, e0 - energy(a05) - lost05
print(f"energy, p = 1, 10 cells: exact 3/8 = {0.375:.6f}; projected {e0:.6f}; after one lap {energy(a1):.6f}")
print(f"  lost over the lap {e0 - energy(a1):.6f}; time integral of the summed squared jumps {lost:.6f};"
      f" gap {sci(gap)}; at nu = 0.05 the gap is {sci(gap05)}, {gap / gap05:.2f} times smaller")
worst = 0.0
for beta, name in ((1.0, "upwind"), (0.0, "central"), (-1.0, "downwind")):
    r = rhs(a, beta)
    rate = tot(2 * a[j][k] * r[j][k] / (10 * (2 * k + 1)) for j in range(10) for k in range(2))
    worst = max(worst, abs(rate + beta * jumps(a)))
    print(f"  t = 0, {name:<8} flux: d/dt of the energy {rate:+.8f}; -beta x sum of squared jumps {-beta * jumps(a) + 0.0:+.8f}")
dn = energy(run(1, 10, beta=-1.0)[0]); eu1 = energy(run(1, 10, euler=True)[0])
eu10 = energy(run(1, 10, euler=True, laps=10)[0])
print(f"what breaks: downwind flux, p = 1, 10 cells: energy after one lap 10^{log10(dn):.1f}")
print(f"what breaks: Euler steps, p = 1, 10 cells, nu = 0.1: energy {e0:.4f} -> {eu1:.4f} after one lap, {eu10:.4f} after ten")
sqp, _ = run(1, 20, f=square); Rs, Ls = edges(sqp)
sl, _ = run(1, 20, f=square, lim=True); R2, L2 = edges(sl)
print(f"what breaks: square pulse, p = 1, 20 cells: highest {max(Rs + Ls):.4f}, lowest {min(Rs + Ls):.4f};"
      f" with the minmod limiter {max(R2 + L2):.4f} and {min(R2 + L2):.4f}")
lim40 = l2err(run(1, 40, lim=True)[0])
print(f"what breaks: limiter left on for the smooth bump, p = 1, 40 cells: error {sci(lim40)} against {sci(E[1, 40])}")
cen = [l2err(run(1, N, beta=0.0)[0]) for N in (10, 20, 40)]
print("central flux, p = 1, N = 10, 20, 40: errors " + ", ".join(sci(e) for e in cen))
need = E[0, 40] * 40 / E[1, 40]
print(f"cost: p = 1 on 40 cells is 80 unknowns for {sci(E[1, 40])}; p = 0 at order 1 would need about {need:.0f} cells (estimate)")
print("chart, log10 h: " + ", ".join(f"{log10(1 / N):.2f}" for N in (10, 20, 40)))
for p in range(3): print(f"chart, p = {p} log10 error: " + ", ".join(f"{log10(E[p, N]):.2f}" for N in (10, 20, 40)))
X = lambda x: 40 + 280 * x; Y = lambda v: 200 - 160 * v
print("figure, p = 1 segments: " + " ".join(f"({X(j / 10):.1f},{Y(L[j]):.1f})-({X((j + 1) / 10):.1f},{Y(R[j]):.1f})"
      for R, L in [edges(a1)] for j in range(10)))
print("figure, exact curve y at x = 0, 0.05, ..., 1: " + " ".join(f"{Y(bump(i / 20)):.1f}" for i in range(21)))
print("figure, p = 0 steps y: " + " ".join(f"{Y(c[0]):.1f}" for c in run(0, 10)[0]))

assert abs(tot(GW) - 2) < 1e-14 and abs(g8 - 2 / 9) < 1e-14   # Gauss: exact to degree 9
assert d_up < 1e-15                                          # p = 0 is the upwind step
assert abs(a[4][0] - avg) < 1e-12                            # projection meets the closed form
assert 1.2 < E[0, 20] / E[0, 40] < 2.2                       # p = 0: order toward 1
assert 3.6 < E[1, 20] / E[1, 40] < 4.6 and 7.2 < E[2, 20] / E[2, 40] < 8.8   # orders 2 and 3
assert worst < 1e-12                                         # energy rate = -beta x jumps
assert abs(gap) < 5e-3 * lost and 6 < gap / gap05 < 10 and energy(a1) < e0   # gap: the time step's own error
assert dn > 1e10 and eu1 > e0 and eu10 > 10 * e0             # the failures really fail
assert max(Rs + Ls) > 1.05 and -1e-12 < min(R2 + L2) and max(R2 + L2) < 1 + 1e-12
print("ALL CHECKS PASS")
