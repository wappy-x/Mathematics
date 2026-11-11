# Second-order cone programs -- the check behind the card.  Standard library only.
# A fund holds five assets against a benchmark.  It chooses weights w to make the
# expected return largest, fully invested and long-only, with tracking error
# ||A (w - wb)|| at most DELTA = 2% a year: one second-order cone constraint.
# Road 1 is a log-barrier Newton method, road 2 the KKT closed form, road 3 a dual
# certificate whose bound meets the return.  Then the mistakes, and the chart.
import math

NAMES = ["UK", "US", "EM", "gilts", "corp"]
MU = [0.060, 0.070, 0.085, 0.040, 0.048]           # expected return a year
WB = [0.25, 0.30, 0.10, 0.20, 0.15]                # benchmark weights
A = [[0.14, 0.15, 0.18, -0.01, 0.04],              # equity-factor exposure a year
     [0.00, 0.00, 0.02, 0.06, 0.05]]               # interest-rate exposure a year
A += [[s if j == i else 0.0 for j in range(5)] for i, s in enumerate([0.06, 0.05, 0.10, 0.02, 0.03])]
N, DELTA = 5, 0.02

def add(xs):                                       # plain left-to-right sum, as in Rust
    s = 0.0
    for v in xs:
        s += v
    return s

def dot(x, y):
    return add(a * b for a, b in zip(x, y))

def mat_vec(M, x):
    return [dot(row, x) for row in M]

SIG = [[add(row[i] * row[j] for row in A) for j in range(N)] for i in range(N)]

def solve(M, b):                                   # Gaussian elimination, partial pivoting
    n = len(b)
    R = [M[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = c
        for r in range(c + 1, n):
            if abs(R[r][c]) > abs(R[p][c]):
                p = r
        R[c], R[p] = R[p], R[c]
        for r in range(c + 1, n):
            f = R[r][c] / R[c][c]
            R[r] = [a - f * b for a, b in zip(R[r], R[c])]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (R[i][n] - add(R[i][j] * x[j] for j in range(i + 1, n))) / R[i][i]
    return x

def te2(w):                                        # squared length of A (w - wb)
    v = mat_vec(A, [a - b for a, b in zip(w, WB)])
    return dot(v, v)

def te(w):                                         # tracking error
    return math.sqrt(te2(w))

def phi(x, t, delta):                              # barrier cost; x = first four weights
    w = x + [1.0 - add(x)]
    slack = delta * delta - te2(w)
    if min(w) <= 0.0 or slack <= 0.0:
        return math.inf
    return -t * dot(MU, w) - add(math.log(v) for v in w) - math.log(slack)

def barrier(delta):                                # road 1: long-only, start at the benchmark
    x, t, steps = WB[:4], 1.0, 0
    while True:
        for _ in range(100):                       # Newton steps at this t, capped
            w = x + [1.0 - add(x)]
            sd = mat_vec(SIG, [a - b for a, b in zip(w, WB)])
            sl = delta * delta - te2(w)
            gw = [-t * MU[i] - 1.0 / w[i] + 2.0 * sd[i] / sl for i in range(N)]
            hw = [[(1.0 / (w[i] * w[i]) if i == j else 0.0) + 2.0 * SIG[i][j] / sl
                   + 4.0 * sd[i] * sd[j] / (sl * sl) for j in range(N)] for i in range(N)]
            g = [gw[i] - gw[4] for i in range(4)]
            H = [[hw[i][j] - hw[i][4] - hw[4][j] + hw[4][4] for j in range(4)] for i in range(4)]
            dx = solve(H, [-v for v in g])
            if -dot(g, dx) / 2.0 < 1e-9:
                break
            s, f0 = 1.0, phi(x, t, delta)
            while phi([a + s * b for a, b in zip(x, dx)], t, delta) > f0 + 0.25 * s * dot(g, dx) and s > 1e-12:
                s *= 0.5
            x, steps = [a + s * b for a, b in zip(x, dx)], steps + 1
        if 6.0 / t < 1e-10:
            return x + [1.0 - add(x)], steps, 6.0 / t
        t *= 10.0

def closed_form(delta):                            # road 2: KKT, cone active, floor ignored
    a, o = solve(SIG, MU), solve(SIG, [1.0] * N)
    nu = add(a) / add(o)
    g = [p - nu * q for p, q in zip(a, o)]         # Sigma g = mu - nu * ones
    ir = math.sqrt(dot(g, mat_vec(SIG, g)))
    return [b + delta * gi / ir for b, gi in zip(WB, g)], nu, ir

def pct(w):
    return "  ".join(f"{n} {100 * v:.2f}" for n, v in zip(NAMES, w))

wb_ret = dot(MU, WB)
w1, steps, gap = barrier(DELTA)
w2, nu, ir = closed_form(DELTA)
d2 = [a - b for a, b in zip(w2, WB)]
u = [ir / DELTA * v for v in mat_vec(A, d2)]       # road 3: dual point (z, u), lambda = 0
z = math.sqrt(dot(u, u))
resid = max(abs(add(A[k][i] * u[k] for k in range(len(A))) + nu - MU[i]) for i in range(N))
bound = nu + DELTA * z + dot(u, mat_vec(A, WB))
print(f"risk model rows {len(A)}, so the cone has dimension {len(A) + 1}")
print(f"benchmark return             {100 * wb_ret:.4f}%")
print(f"road 1 barrier weights %     {pct(w1)}")
print(f"road 1 return {100 * dot(MU, w1):.4f}%  tracking error {100 * te(w1):.4f}%  Newton steps {steps}  gap bound {gap:.0e}")
print(f"road 2 closed-form weights % {pct(w2)}")
print(f"road 2 nu {nu:.6f}  best ratio sqrt(g'Sg) {ir:.6f}  return {100 * dot(MU, w2):.4f}%")
print(f"road 2 excess = delta x ratio {100 * DELTA * ir:.4f}%  direction g = {' '.join(f'{v * ir / DELTA:.6f}' for v in d2)}")
print(f"road 3 dual z = |u| {z:.6f}  u = {' '.join(f'{v:.6f}' for v in u)}")
print(f"road 3 stationarity residual below 1e-12: {'yes' if resid < 1e-12 else 'no'}")
print(f"road 3 dual bound {100 * bound:.4f}%  gap to the return below 1e-12: {'yes' if abs(bound - dot(MU, w2)) < 1e-12 else 'no'}")
print(f"tracking error by 7-row length {100 * te(w2):.4f}%, by sqrt of variance "
      f"{100 * math.sqrt(dot(d2, mat_vec(SIG, d2))):.4f}%")
print(f"turnover from benchmark, sum |w - wb| {100 * add(abs(v) for v in d2):.2f}%")
wv, _, _ = barrier(math.sqrt(DELTA))               # mistake: variance capped at 0.02, not 0.0004
print(f"wrong: variance cap 0.02    weights % {pct(wv)}")
print(f"wrong: variance cap 0.02    excess {100 * (dot(MU, wv) - wb_ret):.4f}%  real tracking error {100 * te(wv):.4f}%")
m = [v - add(MU) / N for v in MU]                  # mistake: plain length of weight changes
wl = [b + DELTA * v / math.sqrt(dot(m, m)) for b, v in zip(WB, m)]
print(f"wrong: |w - wb| <= 2%       excess {100 * (dot(MU, wl) - wb_ret):.4f}%  real tracking error {100 * te(wl):.4f}%")
print(f"wrong: |w - wb| scaled up to 2% tracking error: excess {100 * (dot(MU, wl) - wb_ret) * DELTA / te(wl):.4f}%")
w5, _, _ = closed_form(0.05)
print(f"wrong: closed form at 5%    weights % {pct(w5)}")
for x2 in (10.0, 100.0, 1000.0):                   # min x1 with x1 * x2 >= 1: never reached
    x1 = 1.0 / x2
    print(f"hyperbola x2 {x2:6.0f}  x1 {x1:.4f}  |(x1 - x2, 2)| {math.sqrt((x1 - x2) * (x1 - x2) + 4.0):.4f}  x1 + x2 {x1 + x2:.4f}")
print("hyperbola dual point (0.5, 0.5, 0): on the rim, |(0.5, 0)| = 0.5, dual value 0")
deltas = [0.01 * k for k in range(1, 9)]
long_only = [100 * (dot(MU, barrier(d)[0]) - wb_ret) for d in deltas]
print("chart, limit %   " + " ".join(f"{100 * d:5.1f}" for d in deltas))
print("chart, long-only " + " ".join(f"{v:5.3f}" for v in long_only))
print("chart, shorting  " + " ".join(f"{100 * d * ir:5.3f}" for d in deltas))
assert abs(dot(MU, w1) - dot(MU, w2)) < 1e-8, "barrier method meets the closed form"
assert max(abs(a - b) for a, b in zip(w1, w2)) < 1e-6 and min(w2) > 0, "same weights, floor slack"
assert resid < 1e-12 and abs(bound - dot(MU, w2)) < 1e-12, "dual certificate meets the return"
assert abs(te(w2) - DELTA) < 1e-12 and abs(z - ir) < 1e-12, "cone tight, |u| is the best ratio"
assert te(wv) > 3 * DELTA and te(wl) < DELTA / 2 and min(w5) < 0, "each mistake breaks a limit"
assert long_only[-1] < 100 * 0.08 * ir - 1e-4 and abs(long_only[0] - ir) < 1e-6, "chart bends"
print("ALL CHECKS PASS")
