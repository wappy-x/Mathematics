# Differential-algebraic equations: index 1 (an RC circuit), index 2 and 3 (a prescribed path), index 3 (a pendulum).
from math import exp, sin, cos, sqrt, log2

def E(x, d=3):  # e-notation with the same digits as Rust's {:.de}
    m, ex = f"{x:.{d}e}".split("e")
    return m + "e" + str(int(ex))

def solve(M, b):  # Gaussian elimination with partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(M)]
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(M[i][k])); M[k], M[p] = M[p], M[k]
        for i in range(k + 1, n):
            f = M[i][k] / M[k][k]
            M[i] = [M[i][j] - f * M[k][j] for j in range(n + 1)]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x

A = [[5 / 12, -1 / 12], [3 / 4, 1 / 4]]; C = [1 / 3, 1.0]  # Radau IIA, two stages
ytrue = lambda t: (1 - exp(-2 * t)) / 2
print("circuit: y' = -y + z, 0 = y + z - 1, y(0) = 0 (y volts, z milliamps, t seconds)")
print(f"index 1: dg/dz = {1.0:.3f}, nonzero; consistent start z(0) = 1 - y(0) = {1 - 0.0:.3f}")
print(f"true y(1) = (1 - e^-2)/2 = {ytrue(1.0):.9f}")

def be(N):  # unknowns (y1, z1): y1 - h(-y1 + z1) = y0 and y1 + z1 = 1
    h, y = 1 / N, 0.0
    for _ in range(N):
        y, z = solve([[1 + h, -h], [1, 1]], [y, 1])
    return y, z

def bdf2(N):  # exact start y(h); then 3/2 y2 - 2 y1 + 1/2 y0 = h(-y2 + z2), y2 + z2 = 1
    h, y0, y1 = 1 / N, 0.0, ytrue(1 / N)
    for _ in range(N - 1):
        y2, _z = solve([[1.5 + h, -h], [1, 1]], [2 * y1 - 0.5 * y0, 1])
        y0, y1 = y1, y2
    return y1

def radau(N):  # unknowns Y1, Y2, Z1, Z2: Yi - h sum aij(-Yj + Zj) = y, Yi + Zi = 1
    h, y = 1 / N, 0.0
    for _ in range(N):
        M = [[(i == j) + h * A[i][j] for j in range(2)] + [-h * A[i][j] for j in range(2)] for i in range(2)]
        M += [[1.0 * (i == j) for j in range(2)] + [1.0 * (i == j) for j in range(2)] for i in range(2)]
        y = solve(M, [y, y, 1.0, 1.0])[1]  # stiffly accurate: the new y is the last stage
    return y

yb, zb = be(10); yr = radau(10)
cf_be = 0.5 * (1 - 1.2 ** -10)
R = lambda z: (1 + z / 3) / (1 - 2 * z / 3 + z * z / 6)
cf_r = 0.5 * (1 - R(-0.2) ** 10)
f1 = solve([[1.1, -0.1], [1, 1]], [0.0, 1.0])
print(f"h = 0.1: BE first step y = {f1[0]:.5f}, z = {f1[1]:.5f}; factor on y - 0.5 per step 1/1.2 = {1 / 1.2:.5f}")
print(f"h = 0.1: BE y(1) = {yb:.5f}, z(1) = {zb:.5f}, closed form 0.5(1 - 1.2^-10) = {cf_be:.5f}")
print(f"h = 0.1: Radau IIA y(1) = {yr:.8f}, closed form 0.5(1 - R(-0.2)^10) = {cf_r:.8f}, R(-0.2) = {R(-0.2):.8f}")
assert abs(yb - cf_be) < 1e-14 and abs(zb - (1 - cf_be)) < 1e-14
assert abs(yr - cf_r) < 1e-14
print("true error in y(1)   N=10        N=20        N=40        N=80     order")
for name, f, p in (("BE", lambda N: be(N)[0], 1), ("BDF2", bdf2, 2), ("Radau IIA", radau, 3)):
    errs = [f(N) - ytrue(1.0) for N in (10, 20, 40, 80)]
    q = log2(abs(errs[2] / errs[3]))
    print(f"{name:>9}  " + "  ".join(f"{E(e):>10}" for e in errs) + f"  {q:.3f}")
    assert abs(q - p) < 0.05
yd = [0.0, 0.9]  # the differentiated system y' = -y + z, z' = y - z by BE, from a start 0.1 off
for _ in range(10):
    yd = solve([[1.1, -0.1], [-0.1, 1.1]], yd)
print(f"z(0) = 0.9 instead of 1: DAE form by BE y(1) = {be(10)[0]:.5f}; differentiated form y(1) = {yd[0]:.5f}, y + z = {yd[0] + yd[1]:.5f}")
assert abs(yd[0] - 0.9 * cf_be) < 1e-14 and abs(yd[0] + yd[1] - 0.9) < 1e-14

def path2(N, method):  # index 2: y' = z, 0 = y - sin t; true z = cos t
    h, y = 1 / N, 0.0
    for n in range(N):
        t = n * h
        if method == "BE":
            z = (sin(t + h) - y) / h
        else:  # Radau: y + h sum aij Zj = sin(t + ci h)
            z = solve([[h * A[i][j] for j in range(2)] for i in range(2)], [sin(t + C[i] * h) - y for i in range(2)])[1]
        y = sin(t + h)
    return z - cos(1.0)
print("index 2 path, error in z(1)   N=10        N=20        N=40        N=80     order")
for name, p in (("BE", 1), ("Radau IIA", 2)):
    errs = [path2(N, name) for N in (10, 20, 40, 80)]
    q = log2(abs(errs[2] / errs[3]))
    print(f"{name:>9}" + " " * 18 + "  ".join(f"{E(e):>10}" for e in errs) + f"  {q:.3f}")
    assert abs(q - p) < 0.05
for w0 in (1.0, 0.0):  # index 3: y' = w, w' = z, 0 = y - sin t; BE first step, h = 0.01; true z(0.01) = -sin(0.01)
    h = 0.01; w1 = (sin(h) - 0.0) / h; z1 = (w1 - w0) / h
    print(f"index 3 path, BE, w(0) = {w0:.1f}: z(0.01) = {z1:.4f}, true {-sin(h):.4f}")
assert abs(z1 - 1 / h) < 0.01

g = 9.81
def rhs(s, gam):  # pendulum in index-1 form: mu from G'' = 0 (or G'' + 2 gam G' + gam^2 G = 0)
    x1, x2, v1, v2 = s
    r2 = x1 * x1 + x2 * x2
    num = v1 * v1 + v2 * v2 - g * x2 + 2 * gam * (x1 * v1 + x2 * v2) + gam * gam * (r2 - 1) / 2
    mu = num / r2
    return [v1, v2, -mu * x1, -mu * x2 - g]

def run(h, T, gam=0.0, proj=False, every=0):  # RK4 from rest at the horizontal, length 1 m
    s, out, worst = [1.0, 0.0, 0.0, 0.0], [], 0.0
    for n in range(1, round(T / h) + 1):
        k1 = rhs(s, gam); k2 = rhs([s[i] + h / 2 * k1[i] for i in range(4)], gam)
        k3 = rhs([s[i] + h / 2 * k2[i] for i in range(4)], gam); k4 = rhs([s[i] + h * k3[i] for i in range(4)], gam)
        s = [s[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in range(4)]
        if proj:  # back onto the circle, then remove the radial speed
            r = sqrt(s[0] * s[0] + s[1] * s[1]); s[0] /= r; s[1] /= r
            d = s[0] * s[2] + s[1] * s[3]; s[2] -= d * s[0]; s[3] -= d * s[1]
        err = sqrt(s[0] * s[0] + s[1] * s[1]) - 1; worst = max(worst, abs(err))
        if every and n % every == 0: out.append(err)
    return err, worst, out
s0 = [0.6, -0.8, 1.5, 1.125]  # a point on the circle, moving along it
lev2 = lambda mu: s0[2] * s0[2] + s0[3] * s0[3] + s0[0] * (-mu * s0[0]) + s0[1] * (-mu * s0[1] - g)
print(f"pendulum: d/dmu of G = 0, of G' = 0, of G'' = {lev2(1.0) - lev2(0.0):.3f}: mu appears after 2 differentiations, index 3")
assert abs((lev2(1.0) - lev2(0.0)) + 1.0) < 1e-12
print("length error at 20 s    h = 0.05     h = 0.02     h = 0.01")
rows = {}
for name, kw in (("index-1 form", {}), ("Baumgarte 5/s", {"gam": 5.0}), ("projection, max", {"proj": True})):
    rows[name] = [run(h, 20.0, **kw)[1 if "proj" in kw else 0] for h in (0.05, 0.02, 0.01)]
    print(f"{name:>15}  " + "  ".join(f"{E(v):>11}" for v in rows[name]))
q = log2(abs(rows["index-1 form"][1] / rows["index-1 form"][2]))
print(f"index-1 form drift falls by 2^{q:.2f} when h halves (RK4 order 4)")
assert abs(q - 4) < 0.2 and rows["projection, max"][1] < 1e-15 and abs(rows["Baumgarte 5/s"][1]) < 1e-6
naive = run(0.02, 20.0, every=100)[2]; bg = run(0.02, 20.0, gam=5.0)[1]  # bg: largest over every step
print("h = 0.02, t = 2..20 s, length error in mm:")
print("  index-1 form: " + ", ".join(f"{-1000 * v:.3f}" for v in naive))
print("  Baumgarte, largest size over all steps: " + E(bg) + " m")
print("  t^2 guide:    " + ", ".join(f"{-1000 * naive[-1] * (k / 10) * (k / 10):.3f}" for k in range(1, 11)))
print(f"drift ratio 20 s / 10 s: {naive[9] / naive[4]:.3f} (t^2 predicts 4)")
assert abs(naive[9] / naive[4] - 4) < 0.1
for gam in (150.0, 125.0):  # past RK4's linear edge, then inside it
    x = 0.02 * gam; e1 = run(0.02, 1.0, gam=gam)[0]
    print(f"Baumgarte {gam:.0f}/s at h = 0.02: h*gam = {x:.2f}, RK4's linear factor {1 - x + x * x / 2 - x ** 3 / 6 + x ** 4 / 24:.3f} (edge at 2.785); length error at 1 s = {E(e1)}")
    assert abs(e1) > 1.0
print("ALL CHECKS PASS")
