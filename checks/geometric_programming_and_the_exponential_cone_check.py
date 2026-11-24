# Geometric programs and the exponential cone -- the check behind the card.  Standard library only.
# Box: largest volume h*w*d (dm, so litres) with wall 2h(w + d) <= 200 dm^2 and floor w*d <= 100 dm^2.
# In logs u = (log h, log w, log d) it is convex.  Road 1: log-barrier Newton in logs.  Road 2: the
# multipliers and the AM-GM ceiling.  Road 3: a grid of boxes.  Then log-concave tests, the
# exponential cone, and a growth-optimal (Kelly) mix of five assets, solved and certified the same way.
import math
def add(xs):                                       # plain left-to-right sum, as in Rust
    s = 0.0
    for v in xs:
        s += v
    return s
dot = lambda x, y: add(a * b for a, b in zip(x, y))
def solve(M, b):                                   # Gaussian elimination, partial pivoting
    n = len(b)
    R = [M[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(R[r][c]))
        R[c], R[p] = R[p], R[c]
        for r in range(c + 1, n):
            f = R[r][c] / R[c][c]
            R[r] = [a - f * q for a, q in zip(R[r], R[c])]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (R[i][n] - add(R[i][j] * x[j] for j in range(i + 1, n))) / R[i][i]
    return x
def barrier(F, x, m):                              # minimise t*cost + barrier, t = 1, 10, 100, ...
    t, steps = 1.0, 0
    while True:
        for _ in range(100):
            v, g, H = F(x, t)
            dx = solve(H, [-a for a in g])
            dec = -dot(g, dx)                      # Newton decrement squared
            if dec / 2.0 < 1e-12:
                break
            s = 1.0
            while F([a + s * b for a, b in zip(x, dx)], t)[0] > v - 0.25 * s * dec and s > 1e-12:
                s *= 0.5
            x, steps = [a + s * b for a, b in zip(x, dx)], steps + 1
        if m / t < 1e-10:                          # m barrier terms: gap at most m / t
            return x, steps, m / t
        t *= 10.0
def box_F(wall, floor):                            # cost -(x + y + z); two log-convex limits
    def F(u, t):
        x, y, z = u
        e1, e2 = math.exp(x + y), math.exp(x + z)
        c1, c2 = math.log(e1 + e2) - math.log(wall / 2.0), y + z - math.log(floor)
        if c1 >= 0.0 or c2 >= 0.0:
            return math.inf, None, None
        ab = e1 * e2 / ((e1 + e2) * (e1 + e2))     # Hessian of log-sum-exp: ab times (0, 1, -1)(0, 1, -1)'
        g1, g2, d1 = [1.0, e1 / (e1 + e2), e2 / (e1 + e2)], [0.0, 1.0, 1.0], [0.0, 1.0, -1.0]
        g = [-t + g1[i] / -c1 + g2[i] / -c2 for i in range(3)]
        H = [[ab * d1[i] * d1[j] / -c1 + g1[i] * g1[j] / (c1 * c1) + g2[i] * g2[j] / (c2 * c2)
              for j in range(3)] for i in range(3)]
        return -t * (x + y + z) - math.log(-c1) - math.log(-c2), g, H
    return F
vol = lambda u: math.exp(u[0] + u[1] + u[2])     # volume in litres from the logs
u, steps, gap = barrier(box_F(200.0, 100.0), [0.0, 0.0, 0.0], 2.0)
h, w, d = (math.exp(v) for v in u)
print(f"road 1 barrier in logs: h {h:.6f}  w {w:.6f}  d {d:.6f} dm  volume {vol(u):.4f} L  Newton steps {steps}  gap bound {gap:.0e}")
a = h * w / (h * w + h * d)
lam1, lam2 = 1.0, 1.0 - a                          # stationarity rows x and y; row z is the residual
print(f"road 2 wall-term weights {a:.4f} {1 - a:.4f}  multipliers wall {lam1:.4f} floor {lam2:.4f}  z-row residual below 1e-6: {'yes' if abs(lam1 * (1 - a) + lam2 - 1) < 1e-6 else 'no'}")
ceiling = 200.0 / 4.0 * math.sqrt(100.0)
print(f"road 2 AM-GM ceiling (wall / 4) x sqrt(floor) = {ceiling:.4f} L  wall used {2 * h * (w + d):.4f}  floor used {w * d:.4f}")
best = max((100.0 / (i / 10 + j / 10) * (i / 10) * (j / 10), i, j)   # w = i/10, d = j/10; h fills the wall
           for i in range(1, 201) for j in range(1, 201) if i * j <= 10000)
print(f"road 3 grid of 40000 floors in 0.1 dm steps, {sum(i * j <= 10000 for i in range(1, 201) for j in range(1, 201))} within the floor limit: best w {best[1] / 10:.1f} d {best[2] / 10:.1f} h {100 / (best[1] / 10 + best[2] / 10):.4f}  volume {best[0]:.4f} L")
vw, vf = vol(barrier(box_F(202.0, 100.0), [0.0] * 3, 2.0)[0]), vol(barrier(box_F(200.0, 101.0), [0.0] * 3, 2.0)[0])
print(f"sensitivity: wall 202 -> {vw:.4f} L (+{100 * (vw / 500 - 1):.4f}%)  floor 101 -> {vf:.4f} L (+{100 * (vf / 500 - 1):.4f}%)")
A, B = (2.0, 2.0, 25.0), (10.0, 10.0, 5.0)         # (w, d, h): both use the full 200 dm^2 of wall
walls = []
for name, bx in (("plain mix", [(p + q) / 2 for p, q in zip(A, B)]), ("log mix", [math.sqrt(p * q) for p, q in zip(A, B)])):
    walls.append(2 * bx[2] * (bx[0] + bx[1]))
    print(f"{name}: {bx[0]:.4f} x {bx[1]:.4f} x {bx[2]:.4f}  wall {walls[-1]:.4f} dm^2  floor {bx[0] * bx[1]:.4f}  volume {bx[0] * bx[1] * bx[2]:.4f} L")
print(f"figure, A (2, 25) B (10, 5) plain mix (6, 15) log mix ({math.sqrt(20):.4f}, {math.sqrt(125):.4f}); "
      f"logs A ({math.log(2):.4f}, {math.log(25):.4f}) B ({math.log(10):.4f}, {math.log(5):.4f}) mix ({math.log(20) / 2:.4f}, {math.log(125) / 2:.4f})")
for s in (20.0, 40.0):                             # mistake: no floor limit, h = 50/s on a square floor
    print(f"wrong: floor limit dropped, side {s:.0f} dm: volume {50 * s:.4f} L")
print(f"wrong: assume a cube: side {math.sqrt(50.0):.4f} dm  volume {math.sqrt(50.0) ** 3:.4f} L")
phi = lambda x: math.exp(-x * x / 2) / math.sqrt(2 * math.pi)   # normal density
def Phi(x):                                        # Simpson's rule from -12 to x, 2000 panels
    n, lo = 2000, -12.0
    hs = (x - lo) / n
    return hs / 3 * add((1 if k in (0, n) else 4 if k % 2 else 2) * phi(lo + k * hs) for k in range(n + 1))
tests = [("normal density", phi), ("normal CDF", Phi), ("skew normal 2 phi Phi", lambda x: 2 * phi(x) * Phi(x)),
         ("two-bump mixture", lambda x: (phi(x - 3) + phi(x + 3)) / 2)]
mid = [math.log(f(0)) - (math.log(f(-3)) + math.log(f(3))) / 2 for _, f in tests]
for (name, _), m in zip(tests, mid):               # midpoint test of log f between -3 and 3
    print(f"log-concave test {name}: log f(0) - mean(log f(-3), log f(3)) = {m:.4f}")
te = -0.3 * math.log(0.3)
print(f"exp cone, entropy: x 0.3  r = -x log x = {te:.6f}  x e^(r/x) = {0.3 * math.exp(te / 0.3):.6f} (<= 1 means in the cone)")
print(f"exp cone, wall: v = {h * w / 100:.4f} {h * d / 100:.4f}  sum {(h * w + h * d) / 100:.6f} (<= 1)")

NAMES = ["UK", "US", "EM", "gilts", "corp"]
P = [0.30, 0.40, 0.20, 0.10]                       # boom, steady, slump, crash
R = [[1.20, 1.24, 1.36, 1.02, 1.05], [1.08, 1.09, 1.14, 1.05, 1.07],
     [0.94, 0.99, 0.85, 1.07, 1.06], [0.72, 0.75, 0.61, 1.15, 0.97]]   # wealth multiplier a year
growth = lambda wt: add(p * math.log(dot(r, wt)) for p, r in zip(P, R))   # mean log of wealth
def kelly_F(x, t):                                 # cost -t * growth - sum log w_i, w5 = 1 - sum
    wt = x + [1.0 - add(x)]
    if min(wt) <= 0.0:
        return math.inf, None, None
    W = [dot(r, wt) for r in R]
    gw = [-t * add(p * r[i] / Ws for p, r, Ws in zip(P, R, W)) - 1.0 / wt[i] for i in range(5)]
    hw = [[t * add(p * r[i] * r[j] / (Ws * Ws) for p, r, Ws in zip(P, R, W)) + (1.0 / (wt[i] * wt[i]) if i == j else 0.0)
           for j in range(5)] for i in range(5)]
    g = [gw[i] - gw[4] for i in range(4)]
    H = [[hw[i][j] - hw[i][4] - hw[4][j] + hw[4][4] for j in range(4)] for i in range(4)]
    return -t * growth(wt) - add(math.log(v) for v in wt), g, H
pct = lambda wt: "  ".join(f"{n} {100 * v:.2f}" for n, v in zip(NAMES, wt))
print("kelly mean return %  " + "  ".join(f"{n} {100 * (add(p * r[i] for p, r in zip(P, R)) - 1):.2f}" for i, n in enumerate(NAMES)))
x, ksteps, kgap = barrier(kelly_F, [0.2] * 4, 5.0)
wk = x + [1.0 - add(x)]
Gk, W = growth(wk), [dot(r, wk) for r in R]
print(f"road 1 barrier weights %  {pct(wk)}  Newton steps {ksteps}  gap bound {kgap:.0e}")
print(f"road 1 growth {Gk:.6f} a year in logs, median wealth x{math.exp(Gk):.6f}")
y = [p / Ws for p, Ws in zip(P, W)]                # road 2: state prices, the dual point
gk = [dot(y, [r[i] for r in R]) for i in range(5)]
dual = add(p * math.log(p / v) for p, v in zip(P, y))
print("road 2 state prices y_s = p_s / W_s:  " + "  ".join(f"{v:.6f}" for v in y))
print("road 2 price of each asset, sum y_s R_si (<= 1):  " + "  ".join(f"{n} {v:.6f}" for n, v in zip(NAMES, gk)))
print(f"road 2 dual ceiling sum p_s log(p_s / y_s) = {dual:.6f}  gap to road 1 below 1e-9: {'yes' if abs(dual - Gk) < 1e-9 else 'no'}")
mixes = ([i / 50, j / 50, k / 50, l / 50, (50 - i - j - k - l) / 50] for i in range(51) for j in range(51 - i)
         for k in range(51 - i - j) for l in range(51 - i - j - k))   # road 3: every mix in 2% steps
grid = max((growth(m), m) for m in mixes)
print(f"road 3 grid in 2% steps (316251 mixes): best {pct(grid[1])}  growth {grid[0]:.6f}")
print("cone points (log W, 1, W) by scenario: " + "  ".join(f"({math.log(v):.4f}, 1, {v:.4f})" for v in W))
em = [0.0, 0.0, 1.0, 0.0, 0.0]
print(f"wrong: all in EM, the largest mean: growth {growth(em):.6f}  crash wealth x{R[3][2]:.2f}")
print(f"wrong: equal weights: growth {growth([0.2] * 5):.6f}")
assert abs(vol(u) - ceiling) < 1e-6 and abs(lam1 * (1 - a) + lam2 - 1) < 1e-6, "barrier meets the AM-GM ceiling and the KKT rows"
assert best[0] <= ceiling + 1e-9 and abs(best[0] - vol(u)) < 1e-6, "no grid box beats the ceiling"
assert abs(vw / vol(u) - 1.01) < 1e-6 and abs(vf / vol(u) - math.sqrt(1.01)) < 1e-6, "multipliers are the elasticities"
assert max(gk) < 1 + 1e-9 and abs(dual - Gk) < 1e-9, "state prices: feasible dual meets the growth"
assert grid[0] <= dual + 1e-12 and Gk - grid[0] < 1e-3 and growth(em) < Gk, "nothing on the grid grows faster"
assert min(mid[:3]) > 0 > mid[3] and abs(mid[0] - 4.5) < 1e-12 and abs(mid[1] - (math.log(0.5) - (math.log(1.3498980316301e-3) + math.log(1 - 1.3498980316301e-3)) / 2)) < 1e-9, "log-concave tests; Phi(-3) = 0.0013498980316301"
print("ALL CHECKS PASS")
