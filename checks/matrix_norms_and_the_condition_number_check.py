# Matrix norms and the condition number -- the check behind the card.  Standard library only.
# A stream carries groundwater g and rain runoff r (m^3/s).  Gauge: g + r = 10.  Chloride,
# 50 g + 48 r = 490 g/s, divided by 50: g + 0.96 r = 9.8.  Road 1: norms by their formulas.
# Road 2: norms by sweeping directions round the circle.  Road 3: power iteration for the
# 2-norm, and exact fractions for every true error.
import math
from fractions import Fraction as F

U = 2.0 ** -53  # unit roundoff

def e(v, p=2):  # e-notation as Rust prints it: 1.11e-16, never 1.11e-016 or e+02
    m, x = f"{v:.{p}e}".split("e")
    return m + "e" + str(int(x))

def mul(A, x): return [A[0][0] * x[0] + A[0][1] * x[1], A[1][0] * x[0] + A[1][1] * x[1]]
def inv(A):  # the 2 by 2 inverse: swap the diagonal, flip the other signs, divide by det
    d = A[0][0] * A[1][1] - A[0][1] * A[1][0]
    return [[A[1][1] / d, -A[0][1] / d], [-A[1][0] / d, A[0][0] / d]]
def det(A): return A[0][0] * A[1][1] - A[0][1] * A[1][0]
def v1(x): return abs(x[0]) + abs(x[1])
def v2(x): return math.sqrt(x[0] ** 2 + x[1] ** 2)
def vi(x): return max(abs(x[0]), abs(x[1]))
def m1(A): return max(abs(A[0][j]) + abs(A[1][j]) for j in range(2))  # largest column sum
def mi(A): return max(abs(A[i][0]) + abs(A[i][1]) for i in range(2))  # largest row sum
def m2(A):  # largest singular value: square root of the larger eigenvalue of A^T A
    t = sum(float(a) ** 2 for row in A for a in row)
    return math.sqrt((t + math.sqrt(t * t - 4 * float(det(A)) ** 2)) / 2)
def sweep(A, vn, n=200000):  # road 2: biggest and smallest stretch over n directions
    hi, lo = 0.0, math.inf
    for k in range(n):
        t = math.pi * k / n
        v = [math.cos(t), math.sin(t)]
        s = vn(mul(A, v)) / vn(v)
        hi, lo = max(hi, s), min(lo, s)
    return hi, lo
def power(A, steps=60):  # road 3: power iteration on A^T A for the 2-norm
    M = [[sum(float(A[k][i]) * float(A[k][j]) for k in range(2)) for j in range(2)] for i in range(2)]
    v = [1.0, 0.0]
    for _ in range(steps):
        w = mul(M, v)
        v = [w[0] / v2(w), w[1] / v2(w)]
    return math.sqrt(v2(mul(M, v)))
def solve(A, b):  # partial pivoting in doubles: swap rows only if the lower pivot is larger
    (a, c), (p, q) = A
    if abs(p) > abs(a):
        a, c, p, q, b = p, q, a, c, [b[1], b[0]]
    l = p / a
    y = (b[1] - l * b[0]) / (q - l * c)
    return [(b[0] - c * y) / a, y]

A = [[F(1), F(1)], [F(1), F(24, 25)]]
b, x = [F(10), F(49, 5)], [F(5), F(5)]
Ai = inv(A)
print("stream: g + r = 10 and 50 g + 48 r = 490, so g + 0.96 r = 9.8; true flows g = r = 5 m^3/s")
print(f"det A {float(det(A)):.4f}; A^-1 = [[{float(Ai[0][0]):.0f}, {float(Ai[0][1]):.0f}], [{float(Ai[1][0]):.0f}, {float(Ai[1][1]):.0f}]]")
print(f"x norms: 1 {v1(x):.4f}, 2 {v2([float(t) for t in x]):.4f}, inf {vi(x):.4f}")
print(f"b norms: 1 {float(v1(b)):.4f}, 2 {v2([float(t) for t in b]):.4f}, inf {float(vi(b)):.4f}")
K = {}
for name, mn, vn in (("1", m1, v1), ("2", m2, v2), ("inf", mi, vi)):
    nA, nAi = float(mn(A)), float(mn(Ai))
    sA, sAi = sweep(A, vn)[0], sweep(Ai, vn)[0]
    K[name] = nA * nAi
    print(f"norm {name:3}: ||A|| {nA:.4f} sweep {sA:.4f}; ||A^-1|| {nAi:.4f} sweep {sAi:.4f}; kappa {K[name]:.4f}")
    assert abs(sA - nA) < 1e-6 * nA and abs(sAi - nAi) < 1e-6 * nAi, "sweep agrees with the formula"
raw = [[F(1), F(1)], [F(50), F(48)]]  # unscaled rows: not symmetric, so row and column sums differ
for nm, M in (("A", raw), ("A^-1", inv(raw))):
    s1, si = sweep(M, v1)[0], sweep(M, vi)[0]
    print(f"unscaled rows, {nm}: 1-norm {float(m1(M)):.4f} sweep {s1:.4f}; inf-norm {float(mi(M)):.4f} sweep {si:.4f}")
    assert abs(s1 - float(m1(M))) < 1e-6 * s1 and abs(si - float(mi(M))) < 1e-6 * si, "1-norm by columns, inf by rows"
hi, lo = sweep(A, v2)
pw = power(A)
print(f"2-norm: power iteration {pw:.6f}, sigma_min {float(abs(det(A))) / m2(A):.6f}, sweep kappa {hi / lo:.4f}")
print(f"digits at risk log10 kappa_inf {math.log10(K['inf']):.2f}; eigenvalues of A {0.98 + math.sqrt(1.0004):.4f}, {0.98 - math.sqrt(1.0004):.4f}")
rs = [float(abs(M[i][0]) + abs(M[i][1])) for M in (A, Ai) for i in range(2)]
dx0, dg = mul(Ai, [F(-1, 10), F(0)]), 53 * math.log10(2)
print(f"hand: row sums A {rs[0]:.4f}, {rs[1]:.4f}; A^-1 {rs[2]:.4f}, {rs[3]:.4f}; dx ({float(dx0[0]):.4f}, {float(dx0[1]):.4f}); digits in a double {dg:.2f}, left {dg - math.log10(K['inf']):.2f}")
assert abs(pw - m2(A)) < 1e-12 and abs(hi / lo - K["2"]) < 1e-3 * K["2"], "three roads to kappa_2"
assert [mul(A, [Ai[0][j], Ai[1][j]]) for j in range(2)] == [[1, 0], [0, 1]], "A times A^-1 is I, exactly"

def case(label, db):  # change b by db, solve exactly, compare relative changes in three norms
    xs = mul(Ai, [b[0] + db[0], b[1] + db[1]])
    dx = [xs[0] - x[0], xs[1] - x[1]]
    f = lambda v: [float(t) for t in v]
    out = []
    for name, vn in (("1", v1), ("2", v2), ("inf", vi)):
        rb, rx = vn(f(db)) / vn(f(b)), vn(f(dx)) / vn(f(x))
        out.append((name, rb, rx))
    print(f"{label}: g {float(xs[0]):.4f}, r {float(xs[1]):.4f}")
    for name, rb, rx in out:
        print(f"  norm {name:3}: data {100 * rb:.3f} %, flows {100 * rx:.2f} %, amplified {rx / rb:.2f}, bound kappa {K[name]:.2f}")
        assert rx <= K[name] * rb * (1 + 1e-12), "the bound holds"
    return out, xs
low, xl = case("gauge 1% low", [F(-1, 10), F(0)])
worst, xw = case("worst case", [F(-1, 10), F(1, 10)])
assert abs(worst[2][2] / worst[2][1] - K["inf"]) < 1e-9, "the infinity-norm bound is attained"
best = 0.0  # road 2 for 'attained': sweep directions of x and of the data error
for i in range(360):
    for j in range(360):
        xv = [math.cos(math.pi * i / 180), math.sin(math.pi * i / 180)]
        dv = [math.cos(math.pi * j / 180), math.sin(math.pi * j / 180)]
        best = max(best, (vi(mul(Ai, dv)) / vi(xv)) / (vi(dv) / vi(mul(A, xv))))
print(f"largest amplification over 129600 pairs of directions {best:.4f}")
assert abs(best - K["inf"]) < 1e-9 * K["inf"], "the sweep finds kappa_inf"
r_wrong = [b[0] - mul(A, xl)[0], b[1] - mul(A, xl)[1]]
print(f"residual of the gauge-low answer ({float(r_wrong[0]):.4f}, {float(r_wrong[1]):.4f}), relative {100 * float(vi(r_wrong) / vi(b)):.2f} %")

A2 = [[F(1), F(1)], [F(1), F(24, 25) * F(99, 100)]]  # runoff chloride read 1% low: 47.52 mg/L
xa = mul(inv(A2), b)
ra, rx = float(abs(A2[1][1] - A[1][1]) / mi(A)), float(vi([xa[0] - 5, xa[1] - 5]) / vi(xa))
print(f"A changed: 0.96 -> {float(A2[1][1]):.4f}: g {float(xa[0]):.4f}, r {float(xa[1]):.4f}; data {100 * ra:.2f} %, flows {100 * rx:.2f} %, bound {100 * K['inf'] * ra:.2f} %, ratio {K['inf'] * ra / rx:.2f}")
assert rx <= K["inf"] * ra, "the bound for a change in A"

xh = solve([[1.0, 1.0], [1.0, 0.96]], [10.0, 9.8])
err = float(vi([F(xh[0]) - 5, F(xh[1]) - 5]) / 5)
print(f"doubles: g {xh[0]:.15f}, r {xh[1]:.15f}; true rel error {e(err)}, kappa*u {e(K['inf'] * U)}, ratio {err / (K['inf'] * U):.2f}")
assert err <= 4 * K["inf"] * U, "a stable solve loses about log10 kappa digits, no more"

ten = [[10 * a for a in row] for row in A]
tiny = [[F(1, 1000), F(0)], [F(0), F(1, 1000)]]
print(f"break: det 10A {float(det(ten)):.4f}, kappa_inf {float(mi(ten) * mi(inv(ten))):.4f}; det 0.001 I {e(float(det(tiny)))}, kappa_inf {float(mi(tiny) * mi(inv(tiny))):.4f}")
print(f"break: rows unscaled (mg/L row) kappa_inf {float(mi(raw) * mi(inv(raw))):.4f}; 1/|det A| {float(1 / abs(det(A))):.4f}")
for k in range(-2, 3):  # chart: the gauge reads k/2 percent off
    xs = mul(Ai, [b[0] * (1 + F(k, 200)), b[1]])
    print(f"chart, gauge {k / 2:+.1f} %, g {float(xs[0]):.2f}, r {float(xs[1]):.2f}")
for c in (40, 49, 50):  # try: runoff chloride c mg/L
    Ac = [[F(1), F(1)], [F(1), F(c, 50)]]
    if det(Ac) == 0:
        print(f"try: runoff {c} mg/L: det 0, no inverse, kappa infinite")
        continue
    bc = mul(Ac, x)
    xs = mul(inv(Ac), [bc[0] - F(1, 10), bc[1]])
    print(f"try: runoff {c} mg/L: kappa_inf {float(mi(Ac) * mi(inv(Ac))):.4f}, gauge 1% low moves flows {100 * float(vi([xs[0] - 5, xs[1] - 5]) / 5):.2f} %")
print("ALL CHECKS PASS")
