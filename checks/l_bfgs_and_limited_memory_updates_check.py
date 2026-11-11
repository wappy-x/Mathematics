# L-BFGS -- the check behind the card.  Only math is imported.  A weather station logs
# air temperature every ten minutes: 50,000 readings d.  The smoothed curve c has one
# coefficient per reading and minimises f(c) = sum (c_i - d_i)^2 + LAM sum (c_{i+1} - c_i)^2.
# L-BFGS keeps the last M step pairs (s, y) and rebuilds each direction by the two-loop
# recursion.  Roads: the run; the gradient certificate; elimination; the dense update.
import math
N, LAM, M, TOL = 50000, 100.0, 10, 0.002       # TOL on |g|: every value within 0.001 C
MASK, state = (1 << 64) - 1, 2026              # SplitMix64, seed 2026: the sensor noise
def rnd():
    global state
    state = z = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
d = [11 - 7 * math.cos(2 * math.pi * i / 52560) + 4 * math.sin(2 * math.pi * i / 144)
     + 3 * (rnd() - 0.5) for i in range(N)]
dot = math.sumprod
def norm(v): return math.sqrt(dot(v, v))
def fg(c):                                      # cost and gradient, written out
    r = [a - b for a, b in zip(c, d)]
    df = [c[i + 1] - c[i] for i in range(N - 1)]
    g = [2 * x for x in r]
    for i, x in enumerate(df):
        g[i] -= 2 * LAM * x
        g[i + 1] += 2 * LAM * x
    return dot(r, r) + LAM * dot(df, df), g
def solve(b):                                   # A x = b by elimination; A = 2(I + LAM D^T D)
    off, cp, bp = -2 * LAM, [0.0] * N, [0.0] * N
    for i in range(N):
        dg = 2 * (1 + LAM) if i in (0, N - 1) else 2 * (1 + 2 * LAM)
        den = dg - (off * cp[i - 1] if i else 0.0)
        cp[i], bp[i] = off / den, (b[i] - (off * bp[i - 1] if i else 0.0)) / den
    x = bp[:]
    for i in range(N - 2, -1, -1):
        x[i] -= cp[i] * x[i + 1]
    return x
def two_loop(g, S, Y, order=1, gam=None):       # d = -B^-1 g from the stored pairs
    q, al = g[:], []
    for s, y in list(zip(S, Y))[::-order]:      # newest pair first
        a = dot(s, q) / dot(y, s)
        al.append(a)
        q = [u - a * v for u, v in zip(q, y)]
    if gam is None:
        gam = dot(S[-1], Y[-1]) / dot(Y[-1], Y[-1]) if S else 1 / norm(g)
    r = [gam * u for u in q]
    for (s, y), a in zip(list(zip(S, Y))[::order], al[::-1]):   # oldest pair first
        b = dot(y, r) / dot(y, s)
        r = [u + (a - b) * v for u, v in zip(r, s)]
    return [-u for u in r]
def lbfgs(f_g, x, m, tol, keep=0, probe=None, skip=True, order=1):
    f, g = f_g(x)
    S, Y, k, ev, hist, out = [], [], 0, 1, [], None
    while norm(g) > tol and k < 400:
        hist.append(norm(g))
        if k == probe:
            out = (x, g, S[:], Y[:])
        dd = two_loop(g, S[-m:], Y[-m:], order) if m else two_loop(g, [], [])
        slope, t = dot(g, dd), 1.0
        if slope >= 0:
            return x, k, ev, hist, ("uphill", slope)
        while True:                             # backtrack until the cost falls enough
            xn = [a + t * b for a, b in zip(x, dd)]
            fn, gn = f_g(xn)
            ev += 1
            if fn <= f + 1e-4 * t * slope or t < 1e-12:   # floor: never loop forever
                break
            t *= 0.5
        s, y = [a - b for a, b in zip(xn, x)], [a - b for a, b in zip(gn, g)]
        if dot(s, y) > 0 or not skip:           # curvature test: keep only s.y > 0
            S.append(s), Y.append(y)
        S, Y, x, f, g, k = S[-max(m, keep):], Y[-max(m, keep):], xn, fn, gn, k + 1
    return x, k, ev, hist, out
cs = solve([2 * v for v in d])                  # road 3: the exact fit
fs, gs = fg(cs)
print(f"readings {N}, {N * 10 / 1440:.1f} days; LAM {LAM:.0f}; exact fit cost {fs:.4f}, |g| {norm(gs):.1e}")
h = 0.01                                        # nudge the raw readings and the exact fit, where c - d is not zero
fd = max(abs((fg(p[:i] + [p[i] + h] + p[i + 1:])[0] - fg(p[:i] + [p[i] - h] + p[i + 1:])[0]) / (2 * h) - fg(p)[1][i])
         for p in (d, cs) for i in (0, 25000, N - 1))
print(f"gradient vs central difference at values 0, 25000, 49999 of the readings and the exact fit: largest gap {fd:.1e}")
x, k, ev, hist, pr = lbfgs(fg, d[:], M, TOL, keep=20, probe=40)
assert pr[0] != "uphill", "every direction on the fit points downhill"
xp, gp, Sp, Yp = pr
(f, g), gap = fg(x), max(abs(a - b) for a, b in zip(x, cs))
print(f"L-BFGS, m={M}, from k=0 at the raw readings (|g| {hist[0]:.1f}): {k} iterations, {ev} cost evaluations")
print(f"cost {f:.4f}; certificate: |g| {norm(g):.6f}, so every value within |g|/2 = {norm(g) / 2:.6f} C")
print(f"largest gap to the exact fit: {gap:.2e} C")
print(f"reading 25000 (day {25000 * 10 / 1440:.1f}): raw {d[25000]:.3f} C, smoothed {x[25000]:.3f} C")
print(f"dense matrix: {N * N} numbers = {N * N * 8 / 1e9:.1f} GB; {M} pairs: {2 * M * N} numbers = {2 * M * N * 8 / 1e6:.1f} MB")
print(f"multiply-adds per direction: dense {N * N}, two-loop 4mn + n = {4 * M * N + N}")
print(f"gradient descent, step 1/L: L = {2 + 8 * LAM:.0f}, mu = 2, needs about "
      f"{math.ceil(math.log(hist[0] / TOL) / -math.log(1 - 2 / (2 + 8 * LAM)))} iterations (estimate)")
print("chart, log10 bound every 10 iterations: " + " ".join(f"{math.log10(v / 2):.2f}" for v in hist[::10]))
sweep = {m: lbfgs(fg, d[:], m, TOL)[1:3] for m in (1, 3, 5, 20)} | {M: (k, ev)}
for m in sorted(sweep):
    print(f"sweep m={m:<2}: {sweep[m][0]:3d} iterations, {sweep[m][1]:3d} evaluations, {2 * m * N * 8 / 1e6:4.1f} MB")
newton, g40 = solve([-v for v in gp]), dot(Sp[-1], Yp[-1]) / dot(Yp[-1], Yp[-1])   # Newton's step at k = 40
dirs = [two_loop(gp, Sp[-m:], Yp[-m:]) if m else two_loop(gp, [], [], gam=g40) for m in (0, 10, 20)]
print("at k=40 vs Newton's step, m = 0 10 20: cosine " + " ".join(f"{dot(v, newton) / norm(v) / norm(newton):.3f}" for v in dirs)
      + "; length ratio " + " ".join(f"{norm(v) / norm(newton):.3f}" for v in dirs))
right, ones = two_loop(gp, Sp[-M:], Yp[-M:]), two_loop(gp, Sp[-M:], Yp[-M:], gam=1.0)
t, fp = 1.0, fg(xp)[0]
while fg([a + t * b for a, b in zip(xp, ones)])[0] > fp + 1e-4 * t * dot(gp, ones):
    t *= 0.5
print(f"break, no scaling: step {norm(ones):.1f} long (right {norm(right):.3f}); cost at t=1 "
      f"{fg([a + b for a, b in zip(xp, ones)])[0]:.0f} (right {fg([a + b for a, b in zip(xp, right)])[0]:.1f}); "
      f"halvings {round(-math.log2(t))}")
def banana(v):                                  # the house example, minimised at (1, 1)
    a, b = v
    return 100 * (b - a * a) ** 2 + (1 - a) ** 2, [-400 * a * (b - a * a) - 2 * (1 - a), 200 * (b - a * a)]
b1 = lbfgs(banana, [-1.2, 1.0], 1, 1e-6, probe=1)
x1, g1, (s0,), (y0,) = b1[4]
sy, yy, sg = dot(s0, y0), dot(y0, y0), dot(s0, g1)
print(f"banana, x1 = ({x1[0]:.4f}, {x1[1]:.4f}), g1 = ({g1[0]:.4f}, {g1[1]:.4f})")
print(f"  s0 = ({s0[0]:.5f}, {s0[1]:.5f}), y0 = ({y0[0]:.4f}, {y0[1]:.4f}), s.y {sy:.4f}, y.y {yy:.2f}, s.g1 {sg:.4f}")
al = sg / sy                                    # the two-loop with one pair, by hand
q = [u - al * v for u, v in zip(g1, y0)]
dh, be = two_loop(g1, [s0], [y0]), dot(y0, [sy / yy * u for u in q]) / sy
print(f"  alpha {al:.6f}, q = ({q[0]:.4f}, {q[1]:.4f}), gamma {sy / yy:.7f}, beta {be:.6f}, d1 = ({dh[0]:.6f}, {dh[1]:.6f})")
_, _, _, _, (x6, g6, S6, Y6) = lbfgs(banana, [-1.2, 1.0], 10, 1e-6, probe=6)
Bi = [[dot(S6[-1], Y6[-1]) / dot(Y6[-1], Y6[-1]) * (i == j) for j in range(2)] for i in range(2)]
for s, y in zip(S6, Y6):                        # road 4: the dense inverse update, pair by pair
    p = 1 / dot(s, y)
    V = [[(i == j) - p * y[i] * s[j] for j in range(2)] for i in range(2)]
    Bi = [[sum(V[a][i] * Bi[a][b] * V[b][j] for a in range(2) for b in range(2)) + p * s[i] * s[j]
           for j in range(2)] for i in range(2)]
dd6, tl6 = [-dot(row, g6) for row in Bi], two_loop(g6, S6, Y6)
print(f"banana k=6, {len(S6)} pairs: two-loop ({tl6[0]:.6f}, {tl6[1]:.6f}), dense ({dd6[0]:.6f}, {dd6[1]:.6f})")
bad = lbfgs(banana, [-1.2, 1.0], 10, 1e-6, skip=False)
good = lbfgs(banana, [-1.2, 1.0], 10, 1e-6)
rev = lbfgs(banana, [-1.2, 1.0], 10, 1e-6, order=-1)   # break: each loop in reverse order
print(f"banana, no curvature test: stuck at k={bad[1]}, slope {bad[4][1]:+.4f} (uphill), cost {banana(bad[0])[0]:.4f}")
print(f"banana, with the test: ({good[0][0]:.6f}, {good[0][1]:.6f}) after {good[1]} iterations, {good[2]} evaluations")
print(f"banana, each loop reversed: {rev[1]} iterations, {rev[2]} evaluations")
assert norm(gs) < 1e-8 and fd < 1e-4,              "elimination solves A c = 2d; gradient matches differences"
assert gap <= norm(g) / 2 and gap < 1e-3,          "the certificate bounds the true gap to the exact fit"
assert abs(f - fs) < 1e-6 * fs,                    "L-BFGS reaches the exact fit's cost"
assert max(abs(a - b) for a, b in zip(tl6, dd6)) < 1e-9, "two-loop equals the dense inverse update"
assert bad[4][0] == "uphill" and max(abs(v - 1) for v in good[0]) < 1e-6, "s.y > 0 is needed and enough"
assert sweep[M][0] < sweep[1][0] and rev[2] > good[2], "ten pairs beat one; loop order matters"
print("ALL CHECKS PASS")
