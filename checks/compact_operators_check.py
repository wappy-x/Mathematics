# Compact operators -- the check behind the card.  Standard library only.
# A copper rod 1 m long, ends held at 0 C, smooths for about 450 s.  K maps the start
# profile f to the profile 450 s later: (Kf)(x) = integral of k(x, y) f(y) dy.
# Roads: the kernel two ways (sine modes, mirror images); finite-rank cuts two
# ways (keep N modes, average k on an N-by-N grid); norms by formula, power
# iteration and quadrature.  Every computation is a truncation of the rod.
import math

KAPPA, KT = 1.11e-4, 0.05                # m^2/s (copper, illustrative); kappa*t, m^2
T = KT / KAPPA                            # seconds of smoothing, about 450

def lam(n):                               # factor by which mode n survives
    return math.exp(-n * n * math.pi ** 2 * KT)

def k_modes(x, y, terms=30):              # road one: sum of sine modes
    return sum(2 * lam(n) * math.sin(n * math.pi * x) * math.sin(n * math.pi * y)
               for n in range(1, terms + 1))

def k_images(x, y):                       # road two: bell curves and mirror images
    g = lambda z: math.exp(-z * z / (4 * KT)) / math.sqrt(4 * math.pi * KT)
    return sum(g(x - y + 2 * m) - g(x + y + 2 * m) for m in range(-2, 3))

def sci(v, d):                            # one fixed scientific format
    return f"{v:.{d}e}"

print(f"kappa*t = {KAPPA:.3e} m^2/s x {T:.1f} s = {KT:.2f} m^2")
for n in range(1, 10):
    print(f"mode {n}: lambda = {sci(lam(n), 4)}")
grid = [i / 20 for i in range(21)]
gap = max(abs(k_modes(x, y) - k_images(x, y)) for x in grid for y in grid)
print(f"kernel, sine modes against mirror images, 21 x 21 grid, worst gap below 1e-12 per m: {'yes' if gap < 1e-12 else 'no'}")

# The flat 100 C start: middle of the rod after 450 s, two roads.
c = {n: (math.sqrt(2) * 100 * 2 / (n * math.pi) if n % 2 else 0.0) for n in range(1, 2001)}
mid_modes = sum(lam(n) * c[n] * math.sqrt(2) * math.sin(n * math.pi / 2) for n in range(1, 40))
Q = 2000
mid_quad = sum(k_images(0.5, (j + 0.5) / Q) * 100 / Q for j in range(Q))
print(f"flat 100 C start, middle after 450 s: modes {mid_modes:.4f} C, quadrature {mid_quad:.4f} C")
for n in (1, 3, 5):
    print(f"mode {n}: amount c = {c[n]:.4f} C, after smoothing lambda*c = {sci(lam(n) * c[n], 4)} C")
for N in (1, 2, 3):
    tail = math.sqrt(sum((lam(n) * c[n]) ** 2 for n in range(N + 1, 60)))
    print(f"modes kept {N}: rms error {sci(tail, 4)} C, bound lambda_{N + 1} x 100 C = {sci(lam(N + 1) * 100, 4)} C")
    assert tail <= lam(N + 1) * 100                              # the norm bound holds

# Norms: ||K|| by power iteration, ||K||_HS by quadrature, against the formulas.
P = 120
xs = [(i + 0.5) / P for i in range(P)]
A = [[k_images(x, y) / P for y in xs] for x in xs]
v = [1.0] * P
for _ in range(60):
    w = [sum(a * b for a, b in zip(row, v)) for row in A]
    s = math.sqrt(sum(t * t for t in w))
    v = [t / s for t in w]
rq = sum(vi * sum(a * b for a, b in zip(row, v)) for vi, row in zip(v, A))
print(f"||K||: formula lambda_1 = {lam(1):.6f}, power iteration on {P} points = {rq:.6f}")
B = [[a - sum(2 * lam(n) * math.sin(n * math.pi * x) * math.sin(n * math.pi * y) for n in (1, 2, 3)) / P
      for a, y in zip(row, xs)] for row, x in zip(A, xs)]                # K - K_3 on the grid
v = list(xs)                              # a start holding every mode, odd and even
for _ in range(30):
    w = [sum(a * b for a, b in zip(row, v)) for row in B]
    s = math.sqrt(sum(t * t for t in w))
    v = [t / s for t in w]
cut3 = sum(vi * sum(a * b for a, b in zip(row, v)) for vi, row in zip(v, B))
print(f"||K - K_3||: formula lambda_4 = {sci(lam(4), 4)}, power iteration on {P} points = {sci(cut3, 4)}")
M = 840                                   # fine grid; 840 is divisible by 1..8
h = 1.0 / M
fx = [(i + 0.5) * h for i in range(M)]
F = [[0.0] * M for _ in range(M)]
for i in range(M):
    for j in range(i, M):
        F[i][j] = F[j][i] = k_images(fx[i], fx[j])
hs_quad = math.sqrt(sum(t * t for row in F for t in row) * h * h)
hs_form = math.sqrt(sum(lam(n) ** 2 for n in range(1, 40)))
print(f"||K||_HS: formula sqrt(sum lambda^2) = {hs_form:.6f}, quadrature on {M} x {M} = {hs_quad:.6f}")

# Finite-rank cuts: average k over an N-by-N grid (rank <= N), against keeping N modes.
S = [[0.0] * (M + 1) for _ in range(M + 1)]         # running sums for block sums
for i in range(M):
    for j in range(M):
        S[i + 1][j + 1] = F[i][j] + S[i][j + 1] + S[i + 1][j] - S[i][j]
sq = sum(t * t for row in F for t in row)
errs, errs_cf = {}, {}
for N in range(1, 9):
    b = M // N
    cell = {n: [(math.cos(n * math.pi * I / N) - math.cos(n * math.pi * (I + 1) / N)) / (n * math.pi)
                for I in range(N)] for n in range(1, 40)}          # integrals of mode n over strips
    kept = sum(sum(2 * lam(n) * cell[n][I] * cell[n][J] for n in cell) ** 2
               for I in range(N) for J in range(N)) * N * N
    errs_cf[N] = math.sqrt(hs_form ** 2 - kept)                    # second road, no quadrature
    lost = sum((S[(I + 1) * b][(J + 1) * b] - S[I * b][(J + 1) * b] - S[(I + 1) * b][J * b]
                + S[I * b][J * b]) ** 2 / (b * b) for I in range(N) for J in range(N))
    errs[N] = math.sqrt(max(sq - lost, 0.0) * h * h)
    print(f"N = {N}: grid cut rank <= {N}, HS error {errs[N]:.4f} (log10 {math.log10(errs[N]):.2f});"
          f" mode cut error lambda_{N + 1} = {sci(lam(N + 1), 3)} (log10 {math.log10(lam(N + 1)):.2f})")
print(f"grid cut, N x error: N=2 {2 * errs[2]:.4f}, N=4 {4 * errs[4]:.4f}, N=8 {8 * errs[8]:.4f}")
gap_cf = max(abs(errs[N] - errs_cf[N]) for N in errs)
print(f"grid cut from closed-form cell integrals: N=1 {errs_cf[1]:.4f}, N=8 {errs_cf[8]:.4f};"
      f" every N within 1e-4 of the quadrature: {'yes' if gap_cf < 1e-4 else 'no'}")

# The closed-ideal rule: an inverse would make the identity compact.
for n in (1, 3, 5):
    print(f"undo mode {n}: multiply by 1/lambda = {sci(1 / lam(n), 4)}")
print(f"0.001 C of noise in mode 5, smoothing undone: {1e-3 / lam(5):.1f} C")

# What breaks: no smoothing.  Modes needed for 1% worst-case error as t shrinks.
for kt in (KT, KT / 10, KT / 100, 0.0):
    n = 1
    while math.exp(-n * n * math.pi ** 2 * kt) >= 0.01 and n < 10 ** 6:
        n += 1
    need = f"{n - 1}" if n < 10 ** 6 else "none up to a million"
    print(f"kappa*t = {kt:.7f} m^2: lambda_4 = {math.exp(-16 * math.pi ** 2 * kt):.4f}, modes for 1%: {need}")
mode_gap = math.sqrt(sum((math.sqrt(2) * (math.sin(math.pi * x) - math.sin(2 * math.pi * x))) ** 2
                         for x in fx) * h)
print(f"no smoothing: modes 1 and 2 stay {mode_gap:.6f} apart, as sqrt(2) = {math.sqrt(2):.6f}")
gq = [(j + 0.5) / Q for j in range(Q)]    # 2000 points keep modes up to 1999 apart
for N in (1, 9, 99, 999):
    rest = math.sqrt(max(100 ** 2 - sum(c[n] ** 2 for n in range(1, N + 1)), 0.0))
    u = [math.sqrt(2) * math.sin((N + 1) * math.pi * x) for x in gq]
    for n in range(1, N + 1):                                    # apply I - P_N to mode N+1
        vn = [math.sqrt(2) * math.sin(n * math.pi * x) for x in gq]
        d = sum(a * b for a, b in zip(u, vn)) / Q
        u = [a - d * b for a, b in zip(u, vn)]
    left = math.sqrt(sum(a * a for a in u) / Q)
    print(f"no smoothing, modes kept {N}: flat start misses {rest:.4f} C rms; mode {N + 1} misses {left:.6f}")
    assert abs(left - 1) < 1e-9                                  # mode N+1 missed in full

assert gap < 1e-12                                               # two kernels agree
assert abs(mid_modes - mid_quad) < 1e-4 and round(mid_quad, 2) == 77.23   # midpoint error ~ h^2
assert abs(rq - lam(1)) < 1e-4                                   # power iteration finds ||K||
assert abs(cut3 - lam(4)) < 1e-9                                 # measured ||K - K_3|| = lambda_4
assert abs(hs_quad - hs_form) < 1e-5                             # HS norm two roads
assert gap_cf < 1e-4                                             # grid cut two roads
assert all(errs[N + 1] < errs[N] for N in range(1, 8)) and 1.8 < errs[4] / errs[8] < 2.2
assert all(math.sqrt(sum(lam(n) ** 2 for n in range(N + 1, 40))) <= errs[N] <= hs_quad
           for N in range(1, 9))                                 # best rank-N cut, and a projection
assert abs(mode_gap - math.sqrt(2)) < 1e-9 and 1e-3 / lam(5) > 100
print("ALL CHECKS PASS")
