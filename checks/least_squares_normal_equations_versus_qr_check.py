# Least squares two ways: normal equations against Householder QR, on a quadratic fit
# to 20 kart lap times (illustrative data, in seconds). Standard library only.
# Roads: exact integer arithmetic (Cramer's rule), Householder QR, normal equations
# with Cholesky; kappa of A and of A^T A by one-sided Jacobi on each separately.
from math import sqrt, log10
TIMES = [61.318, 61.418, 61.327, 61.293, 61.278, 61.133, 61.071, 61.026, 61.065, 60.965,
         60.982, 61.006, 61.020, 61.123, 61.212, 61.180, 61.218, 61.388, 61.188, 61.217]
LAP0, M, U = 301, 20, 2.0 ** -53         # first lap of the stint, laps, unit roundoff

def dot(p, q):                           # plain loop: same rounding in Python and Rust
    t = 0.0
    for a, b in zip(p, q): t += a * b
    return t
def columns(a):                          # A as three columns: 1, lap, lap^2
    laps = [float(a + i) for i in range(M)]
    return [[1.0] * M, laps, [v * v for v in laps]]
def det3(g):
    return (g[0][0] * (g[1][1] * g[2][2] - g[1][2] * g[2][1]) - g[0][1] * (g[1][0] * g[2][2]
            - g[1][2] * g[2][0]) + g[0][2] * (g[1][0] * g[2][1] - g[1][1] * g[2][0]))
def exact(a, times):                     # road 1: exact rationals in integers
    t = [a + i for i in range(M)]        # the laps as numbered: each offset gives new integers
    yi = [int(v * 2.0 ** 47) for v in times]   # each stored double, times 2^47, exactly
    g = [[sum(v ** (j + k) for v in t) for k in range(3)] for j in range(3)]
    h = [sum(v ** j * y for v, y in zip(t, yi)) for j in range(3)]
    d, n = det3(g), []
    for j in range(3):
        gj = [[h[i] if k == j else g[i][k] for k in range(3)] for i in range(3)]
        n.append(det3(gj))
    assert max(abs(v).bit_length() for v in n + [d << 47]) < 127        # fits Rust's i128
    return [float(v) / float(d << 47) for v in n]
def back(r, z):                          # solve the triangle R x = z from the bottom up
    x = [0.0] * 3
    for i in (2, 1, 0):
        e = z[i]
        for k in range(i + 1, 3): e -= r[i][k] * x[k]
        x[i] = e / r[i][i]
    return x
def normal(c, y):                        # road 2: A^T A x = A^T b by Cholesky
    g = [[dot(c[j], c[k]) for k in range(3)] for j in range(3)]
    r = [[0.0] * 3 for _ in range(3)]
    for j in range(3):
        d = g[j][j]
        for k in range(j): d -= r[k][j] * r[k][j]
        r[j][j] = sqrt(d)
        for i in range(j + 1, 3):
            e = g[j][i]
            for k in range(j): e -= r[k][j] * r[k][i]
            r[j][i] = e / r[j][j]
    z = [0.0] * 3                        # forward solve R^T z = A^T b
    for i in range(3):
        e = dot(c[i], y)
        for k in range(i): e -= r[k][i] * z[k]
        z[i] = e / r[i][i]
    return back(r, z)
def householder(c, y):                   # road 3: reflect A into a triangle R
    v_cols, b, r = [col[:] for col in c], list(y), [[0.0] * 3 for _ in range(3)]
    for j in range(3):
        col = v_cols[j][j:]
        nrm = sqrt(dot(col, col))
        alpha = -nrm if col[0] > 0 else nrm
        v = col[:]; v[0] -= alpha
        vv = dot(v, v)
        for w in v_cols[j:] + [b]:
            f = 2.0 * dot(v, w[j:]) / vv
            for i in range(j, M): w[i] -= f * v[i - j]
        for k in range(j, 3): r[j][k] = v_cols[k][j]
    return back(r, b[:3])
def gram_schmidt(c, y):                  # classical Gram-Schmidt, for "what breaks"
    q, r = [], [[0.0] * 3 for _ in range(3)]
    for j in range(3):
        v = c[j][:]
        for k in range(j):
            r[k][j] = dot(q[k], c[j])
            for i in range(M): v[i] -= r[k][j] * q[k][i]
        r[j][j] = sqrt(dot(v, v)); q.append([w / r[j][j] for w in v])
    return back(r, [dot(qk, y) for qk in q])
def sing(cols):                          # one-sided Jacobi: rotate columns until perpendicular
    v = [col[:] for col in cols]
    for sweep in range(40):
        worst = 0.0
        for p in range(3):
            for q in range(p + 1, 3):
                al, be, ga = dot(v[p], v[p]), dot(v[q], v[q]), dot(v[p], v[q])
                if ga == 0.0: continue
                worst = max(worst, abs(ga) / sqrt(al * be))
                ze = (be - al) / (2.0 * ga)
                t = (1.0 if ze >= 0 else -1.0) / (abs(ze) + sqrt(1.0 + ze * ze))
                cs = 1.0 / sqrt(1.0 + t * t); sn = cs * t
                for i in range(len(v[p])):
                    x1, x2 = v[p][i], v[q][i]
                    v[p][i], v[q][i] = cs * x1 - sn * x2, sn * x1 + cs * x2
        if worst < 1e-15: break
    s = sorted(sqrt(dot(w, w)) for w in v)
    return s[2] / s[0]                   # largest stretch over smallest: kappa
def kappa(c):                            # kappa of A with each column scaled to length 1
    return sing([[v / sqrt(dot(col, col)) for v in col] for col in c])
def rel2(xh, x): return abs(xh[2] - x[2]) / abs(x[2])   # relative error in x2, the wear number
def rss(c, x):                           # residual sum of squares, exact: misses in whole units of 2^-62
    sx = [int(v * 2.0 ** 62) for v in x]; assert all((v * 2.0 ** 62).is_integer() for v in x)
    q = sum((int(TIMES[i] * 2.0 ** 62) - sx[0] - sx[1] * int(c[1][i]) - sx[2] * int(c[2][i])) ** 2 for i in range(M))
    assert q.bit_length() < 127; return float(q) / 2.0 ** 62 / 2.0 ** 62   # q fits Rust's i128

C = columns(LAP0)
xe, xq, xn, xg = exact(LAP0, TIMES), householder(C, TIMES), normal(C, TIMES), gram_schmidt(C, TIMES)
for name, x in (("exact", xe), ("QR", xq), ("normal eqns", xn)):
    print(f"{name:<12} x0 {x[0]:.12e}  x1 {x[1]:.12e}  x2 {x[2]:.12e}")
k = kappa(C)
cs = [[v / sqrt(dot(col, col)) for v in col] for col in C]
kg = sing([[dot(cs[j], cs[i]) for i in range(3)] for j in range(3)])   # kappa of A^T A
fit = [xe[0] + xe[1] * C[1][i] + xe[2] * C[2][i] for i in range(M)]
tan = sqrt(rss(C, xe)) / sqrt(dot(fit, fit))
eq, en, eg = rel2(xq, xe), rel2(xn, xe), rel2(xg, xe)
print(f"kappa(A) {k:.1f}  kappa(A^T A) {kg:.1f}  kappa(A)^2 {k * k:.1f}")
print(f"tan theta {tan:.3e}   u {U:.3e}")
eqs, ens = (k + k * k * tan) * U, k * k * U
print(f"x2 error, QR          {eq:.2e}   estimate (k + k^2 tan)u {eqs:.2e}   ratio {eq / eqs:.3f}")
print(f"x2 error, normal eqns {en:.2e}   estimate k^2 u {ens:.2e}   ratio {en / ens:.3f}")
print(f"normal eqns / QR error {en / eq:.0f}, about {log10(en / eq):.2f} digits")
print(f"x2 error, classical Gram-Schmidt {eg:.2e}")
print(f"rss, summed exactly: exact fit {rss(C, xe):.15f}  QR {rss(C, xq):.15f}  normal {rss(C, xn):.15f}")
print(f"fastest lap {-xe[1] / (2 * xe[2]):.4f}, wear 2*x2 {2000 * xe[2]:.4f} ms per lap per lap")
bumped = TIMES[:]; bumped[0] = 61.319
print(f"lap {LAP0} timed 1 ms slower: x2 moves {rel2(exact(LAP0, bumped), xe):.2e}")
for m in (20, 1000000): print(f"flops m={m}: normal {m * 9 + 9}, Householder {18 * m - 18}")
print("sweep first lap, centre/half-width, kappa, k^2 u, normal, QR, log10 normal, log10 QR")
sweep = {}
for a in (-9, 1, 21, 101, 301):
    c = columns(a); x = exact(a, TIMES)
    sweep[a] = (kappa(c), rel2(normal(c, TIMES), x), rel2(householder(c, TIMES), x))
    kk, e1, e2 = sweep[a]
    print(f"sweep {a:>5} {(a + 9.5) / 9.5:>8.2f} {kk:>9.1f} {kk * kk * U:.2e} {e1:.2e} {e2:.2e} {log10(e1):6.2f} {log10(e2):6.2f}")

assert abs(xe[2] - 0.0036196172248804) < 1e-15        # exact x2, pinned to 14 digits
assert all(abs(exact(a, TIMES)[2] - xe[2]) < 1e-15 for a in (-9, 1, 21, 101))  # same x2, new integers
assert eq < 1e-11 and 0.1 < en / ens < 1 and en / eq > 1e3   # NE near k^2 u; QR 4 digits ahead
assert abs(kg / (k * k) - 1.0) < 1e-6                    # kappa(A^T A) = kappa(A)^2
assert sweep[-9][1] < 1e-12 and sweep[301][1] > 1e3 * sweep[-9][1]   # centring rescues it
assert abs(rss(C, xn) - rss(C, xe)) < 1e-15               # residual hides the loss
assert abs(-xq[1] / (2 * xq[2]) + xe[1] / (2 * xe[2])) < 1e-9
print("ALL CHECKS PASS")
