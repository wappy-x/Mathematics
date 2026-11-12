# ADI and multidimensional grids -- the check behind the card.  Standard library only.
# A 1 m square steel plate (diffusivity 1.2e-5 m^2/s, illustrative) starts at 0 C; its top edge
# is held at 100 C, the other three edges at 0 C.  Road one: the exact series, settled and in time.
# Road two: the five-point system assembled and solved by banded elimination, flops counted.
# Road three: Peaceman-Rachford ADI, a row sweep then a column sweep, each a tridiagonal solve.
import math
PI, ALPHA, HOUR = math.pi, 1.2e-5, 3600.0

def ratio(n, y):                    # sinh(n pi y)/sinh(n pi), written so it never overflows
    return math.exp(n * PI * (y - 1)) * (1 - math.exp(-2 * n * PI * y)) / (1 - math.exp(-2 * n * PI))
def settled(x, y):                  # the separated series for the settled plate
    return sum(400 / (n * PI) * math.sin(n * PI * x) * ratio(n, y) for n in range(1, 400, 2))
def exact(x, y, t, K=41):           # settled minus every double-sine mode, each fading at its own rate
    gap = sum(800 * n * (-1) ** (n + 1) / (PI * PI * m * (m * m + n * n)) * math.sin(m * PI * x)
              * math.sin(n * PI * y) * math.exp(-ALPHA * PI * PI * (m * m + n * n) * t)
              for m in range(1, K, 2) for n in range(1, K))
    return settled(x, y) - gap
def cold_grid(N, top=100.0):        # U[j][i] at x = i/N, y = j/N; edges hold their values
    U = [[0.0] * (N + 1) for _ in range(N + 1)]
    for i in range(1, N): U[N][i] = top
    return U
def thomas(lo, di, up, d):          # constant-diagonal tridiagonal solve, one sweep down, one back
    n, p, q = len(d), [up / di], [d[0] / di]
    for k in range(1, n):
        den = di - lo * p[k - 1]
        p.append(up / den); q.append((d[k] - lo * q[k - 1]) / den)
    x = q[:]
    for k in range(n - 2, -1, -1): x[k] = q[k] - p[k] * x[k + 1]
    return x
def adi_step(U, N, r, half=True):   # rows implicit in x, then columns implicit in y
    s = r / 2 if half else r
    V = [row[:] for row in U]
    for j in range(1, N):
        d = [U[j][i] + s * (U[j + 1][i] - 2 * U[j][i] + U[j - 1][i]) for i in range(1, N)]
        d[0] += s * U[j][0]; d[-1] += s * U[j][N]        # the row's two edge values go right
        V[j][1:N] = thomas(-s, 1 + 2 * s, -s, d)
    W = [row[:] for row in V]
    for i in range(1, N):
        d = [V[j][i] + s * (V[j][i + 1] - 2 * V[j][i] + V[j][i - 1]) for j in range(1, N)]
        d[0] += s * V[0][i]; d[-1] += s * V[N][i]        # the column's two edge values go right
        for j, v in enumerate(thomas(-s, 1 + 2 * s, -s, d)): W[j + 1][i] = v
    return W
def explicit_step(U, N, r):
    W = [row[:] for row in U]
    for j in range(1, N):
        for i in range(1, N):
            W[j][i] = U[j][i] + r * (U[j][i + 1] + U[j][i - 1] + U[j + 1][i] + U[j - 1][i] - 4 * U[j][i])
    return W
def run(step, N, dt, t, **kw):
    U, h = cold_grid(N), 1.0 / N
    r = ALPHA * dt / (h * h)
    for _ in range(round(t / dt)): U = step(U, N, r, **kw)
    return U
def five_point(N, edges=True):      # A U = b on the (N-1)^2 inside points, numbered row by row
    m, b = (N - 1) ** 2, N - 1
    A, rhs, E = [[0.0] * (2 * b + 1) for _ in range(m)], [0.0] * m, cold_grid(N, 100.0 if edges else 0.0)
    for j in range(1, N):
        for i in range(1, N):
            k = (j - 1) * b + (i - 1); A[k][b] = 4.0
            for ii, jj in ((i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1)):
                if 0 < ii < N and 0 < jj < N: A[k][b + (jj - 1) * b + (ii - 1) - k] = -1.0
                else: rhs[k] += E[jj][ii]                # an edge value is known: it moves right
    return A, rhs, b
def band_solve(A, rhs, b):          # Gaussian elimination inside the band; count every flop
    m, fac, sol = len(rhs), 0, 0
    for k in range(m):
        for i in range(k + 1, min(k + b + 1, m)):
            l = A[i][b + k - i] / A[k][b]; fac += 1
            for j in range(k + 1, min(k + b + 1, m)): A[i][b + j - i] -= l * A[k][b + j - k]
            fac += 2 * (min(k + b + 1, m) - k - 1)
            rhs[i] -= l * rhs[k]; sol += 2
    x = [0.0] * m
    for i in range(m - 1, -1, -1):
        s = rhs[i]
        for j in range(i + 1, min(i + b + 1, m)): s -= A[i][b + j - i] * x[j]; sol += 2
        x[i] = s / A[i][b]; sol += 1
    return x, fac, sol
def solve_grid(N, edges=True):
    A, rhs, b = five_point(N, edges)
    x, fac, sol = band_solve(A, rhs, b)
    return (lambda i, j: x[(j - 1) * b + (i - 1)]), fac, sol

f4 = lambda v: " ".join(f"{x:.4f}" for x in v)
# by hand: the 3-cell grid, 4 inside points; settled values, then one ADI step of an hour
g3 = solve_grid(3)[0]
r3 = ALPHA * HOUR * 9; s3 = r3 / 2
top_star = 100 * s3 / (1 + s3); col_rhs = top_star * (1 - s3) + 100 * s3
U3 = adi_step(cold_grid(3), 3, r3)
print(f"3-cell grid settled: top points {g3(1, 2):.4f}, bottom points {g3(1, 1):.4f} C")
print(f"3-cell ADI step of 1 h: r = {r3:.4f}, r/2 = {s3:.4f}; row sweep: right side {100 * s3:.4f}, diagonal {1 + r3:.4f}, U* = {top_star:.4f} at both top points")
print(f"  column sweep: right side top {col_rhs:.4f}, pivot {1 + r3 - s3 * s3 / (1 + r3):.4f}; top {U3[2][1]:.4f}, bottom {U3[1][1]:.4f}; exact (1/3, 2/3) at 1 h {exact(1/3, 2/3, HOUR):.4f} C, off by {U3[2][1] - exact(1/3, 2/3, HOUR):.4f}")
# settled plate: assembled five-point system against the series, at P = (0.5, 0.8)
P, errs = settled(0.5, 0.8), []
for N in (10, 20, 40):
    g, fac, sol = solve_grid(N)
    errs.append(abs(g(N // 2, 4 * N // 5) - P))
    print(f"five-point N = {N}: {(N - 1) ** 2} unknowns, band {N - 1}; P = {g(N // 2, 4 * N // 5):.4f} C, "
          f"centre {g(N // 2, N // 2):.4f} C; flops factor {fac} solve {sol}")
print(f"series P = {P:.4f} C; errors {' '.join(f'{e:.5f}' for e in errs)}; ratios {errs[0] / errs[1]:.2f} {errs[1] / errs[2]:.2f}")
for n in (39, 999):                 # n = N - 1 points a line; m = n^2 unknowns; band w = n
    print(f"flops per step, N = {n + 1}: ADI 2n(13n - 2) = {2 * n * (13 * n - 2)}; banded estimates: solve 4mw = {4 * n ** 3}, factor once 2mw^2 = {2 * n ** 4}; solve/ADI {4 * n ** 3 / (2 * n * (13 * n - 2)):.1f}")
zero = solve_grid(20, edges=False)[0](10, 16)
# the plate warming: ADI at N = 40 against the exact series at the centre after one hour
ex1, ref = exact(0.5, 0.5, HOUR), run(adi_step, 40, 30.0, HOUR)[20][20]
adi1 = {dt: run(adi_step, 40, dt, HOUR)[20][20] for dt in (3600, 1200, 600, 300, 150)}
print(f"centre at 1 h: exact {ex1:.4f} C; ADI N = 40, dt = 30 s {ref:.4f} C, so the space error is {ref - ex1:.4f}")
for dt, v in adi1.items():
    print(f"  ADI dt = {dt:4d} s, r = {ALPHA * dt * 1600:6.2f}: {v:.4f} C; time error {v - ref:8.4f}, error against exact {v - ex1:8.4f}")
te = [adi1[dt] - ref for dt in (1200, 600, 300, 150)]
print(f"time-error ratios as dt halves: {te[0] / te[1]:.2f} {te[1] / te[2]:.2f} {te[2] / te[3]:.2f}")
exp12 = run(explicit_step, 40, 12.0, HOUR)[20][20]
exp15 = run(explicit_step, 40, 15.0, HOUR)
blow = max(abs(v) for row in exp15 for v in row)
full = run(adi_step, 40, 60.0, HOUR, half=False)[20][20]
print(f"explicit limit r <= 1/4: dt <= {0.25 * 0.025 * 0.025 / ALPHA:.4f} s; dt = 12 s (r = 0.2304): {exp12:.4f} C after 300 steps; dt = 15 s (r = 0.288): largest |U| {blow:.3e}")
print(f"mistake, full r in each sweep: {full:.4f} C at 1 h; exact at 2 h {exact(0.5, 0.5, 2 * HOUR):.4f} C")
print(f"mistake, edge values left out of b: P reads {zero:.4f} C")
# the chart: centre, hour by hour, ADI dt = 600 s against the exact series; then 24 h against direct
U, hours, adiv = cold_grid(40), [], []
for step in range(1, 145):
    U = adi_step(U, 40, ALPHA * 600 * 1600)
    if step % 6 == 0 and step <= 48: hours.append(exact(0.5, 0.5, step * 600)); adiv.append(U[20][20])
g40 = solve_grid(40)[0]
gap24 = max(abs(U[j][i] - g40(i, j)) for j in range(1, 40) for i in range(1, 40))
print("chart, hours        ", " ".join(f"{h:7d}" for h in range(1, 9)))
print("chart, exact centre ", " ".join(f"{v:7.4f}" for v in hours))
print("chart, ADI dt = 600 ", " ".join(f"{v:7.4f}" for v in adiv))
print(f"ADI at 24 h against the direct settled solve, N = 40: largest gap {gap24:.2e} C")
pt = lambda i, j: f"{80 + 40 * i},{230 - 40 * j}"   # the figure: N = 5, 200 units per metre
print(f"figure, plate {pt(0, 5)} to {pt(5, 0)}; stencil {pt(1, 4)} arms {pt(0, 4)} {pt(2, 4)} {pt(1, 5)} {pt(1, 3)}; row {pt(1, 1)} to {pt(4, 1)}; column {pt(4, 1)} to {pt(4, 4)}")
assert abs(g3(1, 2) - 37.5) < 1e-12 and abs(g3(1, 1) - 12.5) < 1e-12        # hand solve: 3a - b = 100, 3b - a = 0
assert all(3.5 < errs[k] / errs[k + 1] < 4.5 for k in range(2)) and errs[-1] < 0.03  # five-point error falls as h^2
assert abs(g40(20, 20) - 25) < 1e-9                                               # turning the plate: centre is 25
assert abs(ref - ex1) < 0.03 and all(3.5 < te[k] / te[k + 1] < 4.5 for k in (1, 2))  # ADI meets the series; order 2 in time
assert abs(exp12 - ex1) < 0.03 and blow > 1e6 and abs(zero) < 1e-12        # explicit: fine at r < 1/4, not above
assert gap24 < 1e-6 and max(abs(a - e) for a, e in zip(adiv, hours)) < 0.03      # ADI settles on the direct solve
print("ALL CHECKS PASS")
