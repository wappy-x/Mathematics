# Fitting instead of passing through: a cubic trend through 30 years of monthly rainfall
# (illustrative data from a seeded generator), fitted in several bases. Standard library only.
# Roads: exact whole numbers in the discrete orthogonal basis; Legendre columns with Cholesky;
# the three-term recurrence; kappa by one-sided Jacobi and from a formula; a fit by those rotations.
from math import sqrt, log10
M, U, MASK = 360, 2.0 ** -53, (1 << 64) - 1   # months, Jan 1995 to Dec 2024; unit roundoff
SEASON = [22, 4, 4, -10, -10, -15, -20, -10, -5, 14, 22, 4]   # mm above the year's average

def splitmix(s):                     # SplitMix64: uniform numbers in [0, 1) from seed s
    while True:
        s = (s + 0x9E3779B97F4A7C15) & MASK
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
def dot(p, q):                       # plain loop: same rounding in Python and Rust
    t = 0.0
    for a, b in zip(p, q): t += a * b
    return t
gen, TENTHS = splitmix(2024), []     # rainfall in tenths of a mm, whole numbers
X = [(2 * j - M - 1) / M for j in range(1, M + 1)]   # month centres mapped onto -1 .. 1
for j in range(M):
    e = 0.0
    for _ in range(12): e += next(gen)                # noise: 12 uniforms minus 6, sd 1
    v = 70.0 - 9.0 * X[j] + 12.0 * X[j] * X[j] * X[j] + SEASON[j % 12] + 25.0 * (e - 6.0)
    TENTHS.append(int(v * 10.0 + 0.5) if v > 0 else 0)
Y = [v / 10 for v in TENTHS]

def exact():                         # road 1: whole numbers; t = 2j - 361 = 360 x
    t = [2 * j - M - 1 for j in range(1, M + 1)]
    q = [[1] * M, t, [3 * v * v - (M * M - 1) for v in t], [5 * v ** 3 - (3 * M * M - 7) * v for v in t]]
    g = [[sum(a * b for a, b in zip(q[i], q[k])) for k in range(4)] for i in range(4)]
    c = [float(sum(a * b for a, b in zip(q[k], TENTHS))) / float(10 * g[k][k]) for k in range(4)]
    fit = [c[0] + c[1] * q[1][j] + c[2] * q[2][j] + c[3] * q[3][j] for j in range(M)]
    d = [c[0] + c[2], M * c[1] + 7 * M * c[3], 2 * M * M * c[2], 2 * M ** 3 * c[3]]  # in P_k
    return g, d, fit
def powers(xs, n):                   # columns 1, x, x^2, .. x^n
    cols = [[1.0] * M]
    for k in range(n): cols.append([a * x for a, x in zip(cols[-1], xs)])
    return cols
def legendre(n):                     # columns P_0 .. P_n by Bonnet's recurrence
    cols = [[1.0] * M, X[:]]
    for k in range(1, n):
        cols.append([((2 * k + 1) * x * a - k * b) / (k + 1) for x, a, b in zip(X, cols[k], cols[k - 1])])
    return cols[:n + 1]
def cholesky_fit(cols):              # road 2: normal equations G c = A^T y by Cholesky
    n = len(cols); r = [[0.0] * n for _ in range(n)]
    for j in range(n):
        d = dot(cols[j], cols[j])
        for k in range(j): d -= r[k][j] * r[k][j]
        if d <= 0: return None, None                  # rounding made G look singular
        r[j][j] = sqrt(d)
        for i in range(j + 1, n):
            e = dot(cols[j], cols[i])
            for k in range(j): e -= r[k][j] * r[k][i]
            r[j][i] = e / r[j][j]
    z, c = [0.0] * n, [0.0] * n
    for i in range(n):
        e = dot(cols[i], Y)
        for k in range(i): e -= r[k][i] * z[k]
        z[i] = e / r[i][i]
    for i in reversed(range(n)):
        e = z[i]
        for k in range(i + 1, n): e -= r[i][k] * c[k]
        c[i] = e / r[i][i]
    return c, [dot([col[j] for col in cols], c) for j in range(M)]
def recurrence(n):                   # road 3: p_(k+1) = (x - alpha) p_k - beta p_(k-1)
    old, p, nold, f, out = [0.0] * M, [1.0] * M, 1.0, [0.0] * M, []
    for k in range(n + 1):
        nk = dot(p, p); c = dot(Y, p) / nk
        f = [a + c * b for a, b in zip(f, p)]
        out.append((c, nk, p[M - 1] - p[0], dot([a - b for a, b in zip(Y, f)], [a - b for a, b in zip(Y, f)]), p))
        al, be = dot([x * v for x, v in zip(X, p)], p) / nk, nk / nold
        old, p, nold = p, [(x - al) * v - be * w for x, v, w in zip(X, p, old)], nk
    return f, out
def sing(cols):                      # one-sided Jacobi: rotate columns until perpendicular
    v = [col[:] for col in cols]
    for sweep in range(60):
        worst = 0.0
        for p in range(len(v)):
            for q in range(p + 1, len(v)):
                al, be, ga = dot(v[p], v[p]), dot(v[q], v[q]), dot(v[p], v[q])
                if ga == 0.0: continue
                worst = max(worst, abs(ga) / sqrt(al * be))
                ze = (be - al) / (2.0 * ga)
                t = (1.0 if ze >= 0 else -1.0) / (abs(ze) + sqrt(1.0 + ze * ze))
                cs = 1.0 / sqrt(1.0 + t * t); sn = cs * t
                for i in range(M):
                    x1, x2 = v[p][i], v[q][i]
                    v[p][i], v[q][i] = cs * x1 - sn * x2, sn * x1 + cs * x2
        if worst < 1e-15: break
    s = sorted(sqrt(dot(w, w)) for w in v)
    return s[-1] / s[0], v
def kappa(cols): return sing([[v / sqrt(dot(col, col)) for v in col] for col in cols])[0]
def rotated_fit(cols):               # no A^T A: rotate the columns perpendicular, then project Y
    v = sing(cols)[1]; c = [dot(Y, w) / dot(w, w) for w in v]; return [dot([w[j] for w in v], c) for j in range(M)]
def worst(f, ref): return max(abs(a - b) for a, b in zip(f, ref))

g, dx, fx = exact(); L = legendre(3); dl, fl = cholesky_fit(L)
f3, rec = recurrence(3)[0], recurrence(6)[1]   # degrees 0..3 of rec are the cubic's terms
print(f"data: {M} months, mean {dot(Y, [1.0] * M) / M:.4f} mm, smallest {min(Y):.1f}, largest {max(Y):.1f}")
print("trend = d0 + d1 P1 + d2 P2 + d3 P3, in mm")
for name, d in (("exact", dx), ("Legendre", dl)): print(f"{name:<9}" + "".join(f" d{k} {d[k]:.12e}" for k in range(4)))
sig = sqrt(rec[3][3] / (M - 4))
se = sig * sqrt(rec[1][2] ** 2 / rec[1][1] + rec[3][2] ** 2 / rec[3][1])
print(f"trend Jan 1995 {fx[0]:.2f} mm, Dec 2024 {fx[-1]:.2f} mm, change {fx[-1] - fx[0]:.2f} mm")
print(f"noise sd estimate {sig:.2f} mm; change standard error {se:.2f} mm; cubic term {rec[3][0] * sqrt(rec[3][1]) / sig:.2f} standard errors")
yr = [1995 + (j - 0.5) / 12 for j in range(1, M + 1)]
bases = (("calendar years", powers(yr, 3)), ("months 1..360", powers([j + 1.0 for j in range(M)], 3)),
         ("powers of x", powers(X, 3)), ("Legendre", legendre(3)), ("recurrence", [r[4] for r in rec[:4]]))
for name, cols in bases:
    c, f = cholesky_fit(cols)
    err = "Cholesky stops: G not positive" if f is None else f"{worst(f, fx):.2e} mm"
    print(f"degree 3, {name:<14} kappa {kappa(cols):.7e}  k^2 u {kappa(cols) * kappa(cols) * U:.2e}  trend error {err}")
print(f"calendar years by Jacobi rotations, no A^T A: trend error {worst(rotated_fit(bases[0][1]), fx):.2e} mm")
print(f"recurrence trend error {worst(f3, fx):.2e} mm; kappa formula 1 + 7 sqrt(21)/(6 m^2) = {1 + 7 * sqrt(21) / (6 * M * M):.7e}")
print(f"sum of P0 P2 {dot(L[0], L[2]):.9f}, -1/(2m) {-1 / (2 * M):.9f}; sum of P1 P3 {dot(L[1], L[3]):.9f}, -7(m^2 - 1)/(6 m^3) {-7 * (M * M - 1) / (6 * M ** 3):.9f}")
sh = [dot(Y, col) / dot(col, col) for col in L]; fs = [dot([col[j] for col in L], sh) for j in range(M)]   # P_k as if orthogonal
print(f"shortcut ignoring the small overlaps: trend error {worst(fs, fx):.2e} mm")
print("degree, kappa powers, kappa Legendre, log10 of each, k^2 u powers, error powers, error Legendre (mm, vs recurrence)")
sweep = {}
for n in (3, 6, 9, 12, 15, 18, 21):
    ref = recurrence(n)[0]; kp, kl = kappa(powers(X, n)), kappa(legendre(n))
    ep, el = worst(cholesky_fit(powers(X, n))[1], ref), worst(cholesky_fit(legendre(n))[1], ref)
    sweep[n] = (kp, kl, ep, el)
    print(f"sweep {n:>2} {kp:.3e} {kl:.6f} {log10(kp):5.2f} {log10(kl):5.2f} {kp * kp * U:.2e} {ep:.2e} {el:.2e}")
for k in range(1, 7):
    drop = rec[k - 1][3] - rec[k][3]
    print(f"degree {k}: rss {rec[k][3]:.3f}, drop {drop:.3f}, c^2 |p|^2 {rec[k][0] ** 2 * rec[k][1]:.3f}, z {rec[k][0] * sqrt(rec[k][1]) / sig:.2f}")
print("flops m=360: normal eqns 4 coefs %d, 16 coefs %d; recurrence 4 coefs %d, 16 coefs %d" % (360 * 16 + 21, 360 * 256 + 1365, 13 * 360 * 4, 13 * 360 * 16))
print("annual mean " + " ".join(f"{dot(Y[12 * i:12 * i + 12], [1.0] * 12) / 12:.1f}" for i in range(30)))
print("annual trend " + " ".join(f"{dot(fx[12 * i:12 * i + 12], [1.0] * 12) / 12:.1f}" for i in range(30)))

assert all(g[i][k] == 0 for i in range(4) for k in range(i))        # exactly orthogonal
assert max(abs(a - b) for a, b in zip(dl, dx)) < 1e-11               # Legendre basis = exact
assert worst(f3, fx) < 1e-11 and worst(fl, fx) < 1e-11               # recurrence = exact
assert worst(cholesky_fit(bases[0][1])[1], fx) > 1.0 and worst(rotated_fit(bases[0][1]), fx) < 1e-5  # A^T A breaks it
assert abs(kappa(L) - (1 + 7 * sqrt(21) / (6 * M * M))) < 1e-8       # kappa from the formula
assert all(abs(rec[k - 1][3] - rec[k][3] - rec[k][0] ** 2 * rec[k][1]) < 1e-6 for k in range(1, 7))
assert sweep[15][2] > 1e4 * sweep[15][3] and sweep[15][1] < 1.02    # powers lose, Legendre holds
print("ALL CHECKS PASS")
