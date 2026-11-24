# Coordinate descent -- the check behind the card.  Standard library only.
# A fund tilts two holdings by x and y percentage points and minimises
# f(x, y) = x^2 + xy + y^2 - 3x  (tracking risk minus forecast gain).
# Roads: exact coordinate steps (cyclic, greedy, random); the optimality equations
# solved by elimination; the random method's expected gap by enumerating every
# choice path, by a closed formula and by simulation; a stall on a kinked coupling;
# alternating least squares for a rank-1 fit against an angle enumeration.
import math

def f(x, y): return x * x + x * y + y * y - 3 * x
def grad(x, y): return (2 * x + y - 3, x + 2 * y)
def step(x, y, i):                       # exact minimisation along coordinate i
    return ((3 - y) / 2, y) if i == 0 else (x, -x / 2)

# road 1: grad f = 0 is 2x + y = 3, x + 2y = 0; eliminate x from the second row
m = 1 / 2
ys = (0 - m * 3) / (2 - m * 1); xs = (3 - ys) / 2; fs = f(xs, ys)
print(f"optimality equations: x* = {xs:.4f}, y* = {ys:.4f}, f* = {fs:.4f}")
h = 1e-3                                 # curvatures by second differences
Lx = (f(1 + h, 0) - 2 * f(1, 0) + f(1 - h, 0)) / h**2
Ly = (f(0, 1 + h) - 2 * f(0, 1) + f(0, 1 - h)) / h**2
disc = math.sqrt((2 - 2)**2 + 4 * 1**2)  # eigenvalues of the Hessian [[2,1],[1,2]]
L, mu = (2 + 2 + disc) / 2, (2 + 2 - disc) / 2
print(f"coordinate curvatures L_x = {Lx:.4f}, L_y = {Ly:.4f}; full L = {L:.4f}, mu = {mu:.4f}")

# road 2: cyclic exact coordinate descent from (0, 0)
x, y = 0.0, 0.0; path = [(x, y)]; errs = []
for s in range(1, 7):
    x, y = step(x, y, 0); path.append((x, y)); x, y = step(x, y, 1); path.append((x, y))
    errs.append(x - xs)
    print(f"sweep {s}: x = {x:.6f}, y = {y:.6f}, x - x* = {x - xs:+.6f}, gap {f(x, y) - fs:.8f}")
gaps = [f(p[0], p[1]) - fs for p in path]
print("gap after each step:", " ".join(f"{g:.6f}" for g in gaps[:7]))
drop, bound = gaps[0] - gaps[1], grad(0, 0)[0]**2 / (2 * Lx)
print(f"first step: drop {drop:.4f}; Step 1's bound slope^2 / (2 L_x) = {bound:.4f}")
assert abs(drop - bound) < 1e-6
for k in range(5):
    assert abs(errs[k + 1] / errs[k] - 0.25) < 1e-9          # 1/4 per sweep
    assert abs(gaps[k + 1] / gaps[k] - 0.25) < 1e-9          # 1/4 per step
assert abs(path[-1][0] - xs) < 1e-3 and abs(grad(*path[-1])[1]) < 1e-12
print("figure,", " ".join(f"({p[0]:.4f},{p[1]:.4f})" for p in path[:7]),
      f"centre ({xs:.1f},{ys:.1f}) axes for gap c: sqrt(2c) along (1,-1), sqrt(2c/3) along (1,1)")

# greedy (Gauss-Southwell): always the coordinate with the larger partial derivative
x, y = 0.0, 0.0; order = ""
for k in range(12):
    g = grad(x, y); i = 0 if abs(g[0]) >= abs(g[1]) else 1
    order += "xy"[i]; x, y = step(x, y, i)
print(f"greedy order: {order}, gap after 12 steps {f(x, y) - fs:.10f} (cyclic {gaps[12]:.10f})")
assert abs((f(x, y) - fs) - gaps[12]) < 1e-15

# road 3: random order, each step picks x or y with probability 1/2
def expected_gap(k):                     # average over all 2^k equally likely paths
    tot = 0.0
    for mask in range(2**k):
        x, y = 0.0, 0.0
        for t in range(k): x, y = step(x, y, (mask >> t) & 1)
        tot += f(x, y) - fs
    return tot / 2**k
R2 = max(3 / (1 + math.cos(t) * math.sin(t)) for t in [j * math.pi / 20000 for j in range(40000)])
n, Lmax = 2, max(Lx, Ly)
print(f"level set f <= f(0,0): R^2 = {R2:.4f}; bound 2 n Lmax R^2 / k = {2 * n * Lmax * R2:.2f}/k")
assert abs(R2 - 2 * gaps[0] / mu) < 1e-9             # the farthest point lies along the gentlest curvature
print("k  enumerated  3(5/8)^k   1/k bound  3(3/4)^k bound")
for k in [1, 2, 4, 6, 8, 10]:
    e = expected_gap(k)
    b1 = 2 * n * Lmax * R2 / k; b2 = 3 * (1 - mu / (n * Lmax))**k
    print(f"{k:<2} {e:.6f}    {3 * 0.625**k:.6f}  {b1:8.4f}   {b2:.6f}")
    assert abs(e - 3 * 0.625**k) < 1e-12 and e <= b1 and e <= b2
ks = [0, 2, 4, 6, 8, 10]
print("chart, log10 gap at k = 0, 2, 4, 6, 8, 10: cyclic", " ".join(f"{math.log10(gaps[k]):.2f}" for k in ks))
print("chart, random", " ".join(f"{math.log10(expected_gap(k)):.2f}" for k in ks),
      "; bound 3(3/4)^k", " ".join(f"{math.log10(3 * 0.75**k):.2f}" for k in ks))
M64 = (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M64; z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
SEED = 2024; seed, N, tot, tot2 = SEED, 20000, 0.0, 0.0
for r in range(N):
    x, y = 0.0, 0.0
    for t in range(10):
        seed, z = splitmix(seed); x, y = step(x, y, z >> 63)
    g = f(x, y) - fs; tot += g; tot2 += g * g
mean = tot / N; se = math.sqrt((tot2 / N - mean * mean) / N)
print(f"simulated, {N} runs, seed {SEED}: mean gap at k = 10 {mean:.6f} (standard error {se:.6f})")
assert abs(mean - expected_gap(10)) < 4 * se

# gradient descent at step 1/L for comparison: one gradient costs two partials
x, y = 0.0, 0.0
for k in range(6):
    g = grad(x, y); x, y = x - g[0] / L, y - g[1] / L
print(f"gradient descent, 6 steps at 1/L: gap {f(x, y) - fs:.6f}; cyclic, 6 sweeps: {gaps[12]:.8f}")
print(f"2,000 assets: full gradient {2000 * 2000} multiply-adds, one coordinate step {2000}")

# what breaks: a kinked coupling |x - y| stalls; a smooth or separable one does not
def argmin1(h, lo=-5.0, hi=5.0):         # golden-section search, convex in one variable
    r = (math.sqrt(5) - 1) / 2
    for _ in range(120):
        a, b = hi - r * (hi - lo), lo + r * (hi - lo)
        if h(a) <= h(b): hi = b
        else: lo = a
    return (lo + hi) / 2
def cd(F, x, y, sweeps):
    for _ in range(sweeps):
        x = argmin1(lambda t: F(t, y)); y = argmin1(lambda t: F(x, t))
    return x, y, F(x, y)
kink = lambda x, y: abs(x - y) + 0.1 * (x + y)**2
smooth = lambda x, y: (x - y)**2 + 0.1 * (x + y)**2
separable = lambda x, y: abs(x) + abs(y) + 0.1 * (x + y)**2
e = 1e-6
print(f"kinked coupling at (1, 1): f = {kink(1, 1):.4f}; slopes along x: right "
      f"{(kink(1 + e, 1) - kink(1, 1)) / e:+.4f}, left {(kink(1, 1) - kink(1 - e, 1)) / e:+.4f}")
xk, yk, vk = cd(kink, 1.0, 1.0, 20)
print(f"  20 sweeps from (1, 1): ({xk:.6f}, {yk:.6f}), f = {vk:.6f}; but f(0, 0) = {kink(0, 0):.4f}"
      f", f(0.5, 0.5) = {kink(0.5, 0.5):.4f}")
assert abs(vk - 0.4) < 1e-8 and kink(0, 0) < vk - 0.39
xs2, ys2, v2 = cd(smooth, 1.0, 1.0, 20)
xs3, ys3, v3 = cd(separable, 1.0, 1.0, 1)
print(f"smooth coupling (x-y)^2, 20 sweeps: f = {v2:.6f}; separable |x|+|y|, 1 sweep: "
      f"largest |coordinate| {max(abs(xs3), abs(ys3)):.6f}, f = {v3:.6f}")
assert v2 < 1e-6 and v3 < 1e-8

# alternating least squares: rank-1 fit to returns M (3 days by 2 assets, percent)
M = [[3.0, 2.0], [1.0, 0.0], [0.0, 1.0]]; v = [1.0, 0.0]
def resid(u, v): return sum((M[i][j] - u[i] * v[j])**2 for i in range(3) for j in range(2))
for r in range(1, 6):
    vv = v[0]**2 + v[1]**2; u = [(M[i][0] * v[0] + M[i][1] * v[1]) / vv for i in range(3)]
    uu = sum(t * t for t in u); v = [sum(M[i][j] * u[i] for i in range(3)) / uu for j in range(2)]
    print(f"ALS round {r}: v = ({v[0]:.6f}, {v[1]:.6f}), squared misses {resid(u, v):.8f}")
G = [[sum(M[i][a] * M[i][b] for i in range(3)) for b in range(2)] for a in range(2)]   # M^T M
tr, det = G[0][0] + G[1][1], G[0][0] * G[1][1] - G[0][1] ** 2
tot = sum(t * t for row in M for t in row); lam1 = (tr + math.sqrt(tr * tr - 4 * det)) / 2
grid = min(tot - sum((row[0] * math.cos(t) + row[1] * math.sin(t))**2 for row in M)
           for t in [j * math.pi / 100000 for j in range(100000)])
print(f"certificate: {tot:.0f} - top eigenvalue {lam1:.4f} = {tot - lam1:.6f}; angle enumeration {grid:.6f}")
assert abs(resid(u, v) - (tot - lam1)) < 1e-6 and abs(grid - (tot - lam1)) < 1e-6
print("ALL CHECKS PASS")
