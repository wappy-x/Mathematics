# Nonlinear least squares -- the check behind the card.  Standard library only:
# math gives exp, log and sqrt; every step, solve and search is written out.
# A pan cools from about 200 C; 40 probe readings, one every 30 s.  Fit the
# decay T(t) = c + a exp(-b t) by Gauss-Newton and Levenberg-Marquardt.
import math
MASK = (1 << 64) - 1
def readings(sd, seed=2026):                   # SplitMix64; 12 uniforms - 6 ~ bell curve
    s, ys = seed, []
    for i in range(1, 41):
        u = 0.0
        for _ in range(12):
            s = (s + 0x9E3779B97F4A7C15) & MASK
            z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
            z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
            u += ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
        ys.append(21.0 + 180.0 * math.exp(-0.15 * 0.5 * i) + sd * (u - 6.0))
    return ys
TS = [0.5 * i for i in range(1, 41)]
def misses(th, ys, wrong=False):               # misses r_i and slope table J, a row per reading
    c, a, b = th
    r = [c + a * math.exp(-b * t) - y for t, y in zip(TS, ys)]
    J = [[1.0, math.exp(-b * t), -(1.0 if wrong else a) * t * math.exp(-b * t)] for t in TS]
    return r, J
def loss(th, ys): return 0.5 * sum(x * x for x in misses(th, ys)[0])
def solve(A, b):                               # Gaussian elimination with row swaps
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for col in range(n):
        p = max(range(col, n), key=lambda q: abs(M[q][col])); M[col], M[p] = M[p], M[col]
        for q in range(col + 1, n):
            f = M[q][col] / M[col][col]
            for j in range(col, n + 1): M[q][j] -= f * M[col][j]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def dot(p, q): return sum(x * y for x, y in zip(p, q))
def normal(J, r):                              # J^T J, and the gradient g = J^T r
    n = len(J[0])
    cols = [[w[i] for w in J] for i in range(n)]
    return [[dot(cols[i], cols[j]) for j in range(n)] for i in range(n)], [dot(cols[i], r) for i in range(n)]
def model(r, J, d): return 0.5 * sum(e * e for e in (x + dot(w, d) for x, w in zip(r, J)))
def step(th, ys, lam, wrong=False):            # damped step; lam = 0 is plain Gauss-Newton
    r, J = misses(th, ys, wrong); A, g = normal(J, r)
    d = solve([[A[i][j] + (lam * A[i][i] if i == j else 0.0) for j in range(3)] for i in range(3)], [-x for x in g])
    pred = -dot(g, d) - 0.5 * sum(dot(w, d) * dot(w, d) for w in J)
    size = math.sqrt(sum(A[i][i] * d[i] * d[i] for i in range(3)))
    return [p + q for p, q in zip(th, d)], pred, size, r, J, A, d
def lm(th, ys, show=False, lam=1e-3):          # accept if F falls: lam / 3; refuse: lam x 3
    steps = 0
    while steps < 200:
        refused = 0
        while True:
            new, pred, size = step(th, ys, lam)[:3]
            if size < 1e-7: return th, steps
            drop = loss(th, ys) - loss(new, ys); rho = drop / pred if pred > 0 else 0.0
            if drop > 0: break
            lam *= 3.0; refused += 1
        if show: print(f"LM step {steps + 1} lambda {lam:8.6f} refused {refused}  c {new[0]:8.4f}  a {new[1]:8.4f}  b {new[2]:7.5f}  F {loss(new, ys):13.6f}  rho {rho:4.2f}")
        th, lam, steps = new, lam / 3.0, steps + 1
    return th, steps
def profile(b, ys):                            # road 2: fix b; then c, a are a straight-line fit
    A, g = normal([[1.0, math.exp(-b * t)] for t in TS], ys)
    c, a = solve(A, g)
    return c, a, loss([c, a, b], ys)
def dropped(th, ys):                           # S = sum r_i (Hessian of r_i): what Gauss-Newton leaves out
    r, J = misses(th, ys); A = normal(J, r)[0]; c, a, b = th
    S = [[0.0] * 3 for _ in range(3)]
    for t, x in zip(TS, r):
        e = math.exp(-b * t); S[1][2] -= x * t * e; S[2][1] -= x * t * e; S[2][2] += x * a * t * t * e
    v = [1.0, 1.0, 1.0]
    for _ in range(300):                       # power iteration: biggest stretch of (J^T J)^-1 S
        w = solve(A, [sum(S[i][j] * v[j] for j in range(3)) for i in range(3)])
        big = max(abs(x) for x in w); v = [x / big for x in w]
    return big, [[A[i][j] + S[i][j] for j in range(3)] for i in range(3)]
ys = readings(1.5)
for row in range(4):
    print(f"readings {10 * row + 1:2d}-{10 * row + 10:2d} (C)" + "".join(f"{y:7.2f}" for y in ys[10 * row:10 * row + 10]))
start = [30.0, 160.0, 0.6]; F0 = loss(start, ys)
print(f"start c {start[0]}  a {start[1]}  b {start[2]}  F {F0:.4f}")
gn1 = step(start, ys, 0.0)[0]; gn2 = step(gn1, ys, 0.0)[0]
for n, th in ((1, gn1), (2, gn2)):
    print(f"pure Gauss-Newton step {n}: c {th[0]:.4f}  a {th[1]:.4f}  b {th[2]:.5f}  F {loss(th, ys):.4e}")
for lam in (0.0, 0.01, 0.1, 1.0, 10.0):
    new, pred, size = step(start, ys, lam)[:3]
    print(f"first step, lambda {lam:5.2f}: scaled length {size:7.3f}  b {new[2]:8.5f}  F {loss(new, ys):.4e}  predicted drop {pred:.4e}  rho {(F0 - loss(new, ys)) / pred:.3f}")
new, pred, size, r, J, A, d = step(start, ys, 1.0)
best = min(model(r, J, [z * f * size / math.sqrt(A[j][j]) for j, z in enumerate((
    math.sin(p * math.pi / 60) * math.cos(q * math.pi / 60), math.sin(p * math.pi / 60) * math.sin(q * math.pi / 60), math.cos(p * math.pi / 60)))])
    for p in range(61) for q in range(120) for f in (0.25, 0.5, 0.75, 1.0))
print(f"trust region, lambda 1: model at the step {model(r, J, d):.4f}; best of 29280 points in the same ball {best:.4f}")
fit, nsteps = lm(start, ys, show=True)
F = loss(fit, ys)
print(f"fit: c {fit[0]:.6f} C  a {fit[1]:.6f} C  b {fit[2]:.6f} per min  F {F:.6f}  rms miss {math.sqrt(2 * F / 40):.4f} C")
print(f"half-life of the heat above room: ln 2 / b = {math.log(2.0) / fit[2]:.4f} min; T(0) = c + a = {fit[0] + fit[1]:.4f} C")
lo, hi, phi = 0.05, 0.5, (math.sqrt(5.0) - 1.0) / 2.0
for _ in range(80):                            # golden-section search on the profile
    m1, m2 = hi - phi * (hi - lo), lo + phi * (hi - lo)
    if profile(m1, ys)[2] < profile(m2, ys)[2]: hi = m2
    else: lo = m1
bp = 0.5 * (lo + hi); cp, ap, Fp = profile(bp, ys)
grid = 0.01 * min(range(1, 101), key=lambda j: profile(0.01 * j, ys)[2])
print(f"road 2, profile in b: c {cp:.6f}  a {ap:.6f}  b {bp:.6f}  F {Fp:.6f}; best b on the grid 0.01..1.00: {grid:.2f}")
rf, Jf = misses(fit, ys); g = normal(Jf, rf)[1]; H = dropped(fit, ys)[1]
minors = [H[0][0], H[0][0] * H[1][1] - H[0][1] * H[0][1], sum(H[0][j] * (H[1][(j + 1) % 3] * H[2][(j + 2) % 3] - H[1][(j + 2) % 3] * H[2][(j + 1) % 3]) for j in range(3))]
print("road 3, gradient at the fit: " + "  ".join(f"{x:.1e}" for x in g) + "; Hessian minors " + "  ".join(f"{x:.4e}" for x in minors))
rates = []
for sd in (1.5, 15.0, 30.0):
    y2 = readings(sd); f2 = lm([30.0, 160.0, 0.1], y2)[0]
    th1 = step([f2[0], f2[1], f2[2] + 0.001], y2, 0.0)[0]; th2 = step(th1, y2, 0.0)[0]
    rates.append((dropped(f2, y2)[0], abs(th2[2] - f2[2]) / abs(th1[2] - f2[2])))
    print(f"probe sd {sd:4.1f} C: rms miss {math.sqrt(2 * loss(f2, y2) / 40):6.3f} C  Gauss-Newton rate, predicted {rates[-1][0]:.4f}  measured {rates[-1][1]:.4f}")
w = step([fit[0], fit[1], fit[2] + 0.001], ys, 0.0, wrong=True)[0]
print(f"wrong slope column (a left out), one step from b = fit + 0.001: b {w[2]:.5f}  F {loss(w, ys):.1f}")
lx = [math.log(y - 30.0) for y in ys]; mt, ml = sum(TS) / 40, sum(lx) / 40
bl = -sum((t - mt) * (x - ml) for t, x in zip(TS, lx)) / sum((t - mt) * (t - mt) for t in TS)
print(f"log-line shortcut, room guessed 30 C: b {bl:.5f}  a {math.exp(ml + bl * mt):.4f}")
rb, path = [-1.2, 1.0], []                     # Rosenbrock: misses 10(y - x^2) and 1 - x
d0 = solve([[-20.0 * rb[0], 10.0], [-1.0, 0.0]], [-10.0 * (rb[1] - rb[0] * rb[0]), -(1.0 - rb[0])])   # J d = -r by elimination
for n in (1, 2):                               # closed form: dx = 1 - x, then dy from the first row
    x, y = rb; dx = 1.0 - x; rb = [x + dx, y + (-10.0 * (y - x * x) + 20.0 * x * dx) / 10.0]; path.append(rb)
    print(f"Rosenbrock as two misses, Gauss-Newton step {n}: ({rb[0]:.4f}, {rb[1]:.4f})")
print("figure, fit at t = 0, 5, 10, 15, 20 min: " + "  ".join(f"{fit[0] + fit[1] * math.exp(-fit[2] * t):.2f}" for t in (0, 5, 10, 15, 20)))
print("figure, start at t = 0, 1, 2, 4, 20 min: " + "  ".join(f"{30 + 160 * math.exp(-0.6 * t):.2f}" for t in (0, 1, 2, 4, 20)))
assert loss(gn1, ys) > 1e6 * F0 and gn1[2] < 0          # undamped step from the poor start overshoots
assert abs(bp - fit[2]) < 1e-6 and abs(cp - fit[0]) < 1e-4 and abs(grid - fit[2]) < 0.01   # two roads meet
assert max(abs(x) for x in g) < 1e-4 and min(minors) > 0  # flat and curving up: a local minimum
assert model(r, J, d) <= best + 1e-9 and best - model(r, J, d) < 1e-2 * model(r, J, d) and abs(F0 - model(r, J, d) - pred) < 1e-9 * F0   # ball's best; predicted drop
assert all(abs(p - m) < 0.02 * p for p, m in rates) and rates[0][0] < rates[1][0] < rates[2][0]
assert abs(path[0][0] - (-1.2 + d0[0])) < 1e-12 and abs(path[0][1] - (1.0 + d0[1])) < 1e-12   # step 1 by two roads
assert abs(rb[0] - 1.0) < 1e-9 and abs(rb[1] - 1.0) < 1e-9 and w[2] < 0 and bl > fit[2] + 0.05
print("ALL CHECKS PASS")
