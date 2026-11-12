# Cubic splines -- the check behind the card.  Standard library only.  Zero rates
# at eight maturities, read off a smooth model curve (illustrative), so the truth is
# known.  Road one: moments by the Thomas sweep.  Road two: all 28 raw conditions by
# dense elimination.  Road three: the true curve, with the gaps halved five times.
from math import exp, log10, log2

def z(t):                                # model zero rate, percent a year
    x = t / 2.0
    l1 = (1 - exp(-x)) / x
    return 4.5 - 0.2 * l1 - 2.0 * (l1 - exp(-x))

def thomas(a, b, c, d):                  # tridiagonal solve, no row swaps
    p, r = [b[0]], [d[0]]
    for i in range(1, len(b)):
        l = a[i] / p[i - 1]
        p.append(b[i] - l * c[i - 1]); r.append(d[i] - l * r[i - 1])
    m = [0.0] * len(b)
    m[-1] = r[-1] / p[-1]
    for i in range(len(b) - 2, -1, -1): m[i] = (r[i] - c[i] * m[i + 1]) / p[i]
    return p, m

def moments(x, y):                       # natural spline: M_0 = M_n = 0
    n = len(x) - 1
    h = [x[i + 1] - x[i] for i in range(n)]
    g = [(y[i + 1] - y[i]) / h[i] for i in range(n)]
    a, c = h[:n - 1], h[1:]
    b = [2 * (h[i - 1] + h[i]) for i in range(1, n)]
    d = [6 * (g[i] - g[i - 1]) for i in range(1, n)]
    p, m = thomas(a, b, c, d)
    return h, b, d, p, [0.0] + m + [0.0]

def ev(x, y, M, t, i=None):              # s, s', s'', s''' on gap i at t
    i = sum(1 for v in x[1:-1] if v <= t) if i is None else i   # the gap holding t
    h, A, B = x[i + 1] - x[i], x[i + 1] - t, t - x[i]
    s = (M[i] * A * A * A + M[i + 1] * B * B * B) / (6 * h) + (y[i] / h - M[i] * h / 6) * A \
        + (y[i + 1] / h - M[i + 1] * h / 6) * B
    s1 = (M[i + 1] * B * B - M[i] * A * A) / (2 * h) + (y[i + 1] - y[i]) / h - (M[i + 1] - M[i]) * h / 6
    return s, s1, (M[i] * A + M[i + 1] * B) / h, (M[i + 1] - M[i]) / h

def dense(x, y):                         # 4n raw conditions, Gaussian elimination
    n = len(x) - 1; N = 4 * n; R = []
    def row(v, *e):
        r = [0.0] * N + [v]
        for k, w in e: r[k] += w
        R.append(r)
    for i in range(n):                   # piece i: y_i + b u + c u^2 + d u^3, u = t - x_i
        h, k = x[i + 1] - x[i], 4 * i
        row(y[i], (k, 1.0))
        row(y[i + 1], (k, 1.0), (k + 1, h), (k + 2, h * h), (k + 3, h * h * h))
        if i < n - 1:                    # slope and bend match at x_(i+1)
            row(0.0, (k + 1, 1.0), (k + 2, 2 * h), (k + 3, 3 * h * h), (k + 5, -1.0))
            row(0.0, (k + 2, 2.0), (k + 3, 6 * h), (k + 6, -2.0))
    row(0.0, (2, 2.0)); row(0.0, (N - 2, 2.0), (N - 1, 6 * (x[n] - x[n - 1])))
    for k in range(N):
        q = max(range(k, N), key=lambda i: abs(R[i][k]))
        R[k], R[q] = R[q], R[k]
        for i in range(k + 1, N):
            f = R[i][k] / R[k][k]
            for j in range(k, N + 1): R[i][j] -= f * R[k][j]
    c = [0.0] * N
    for i in range(N - 1, -1, -1): c[i] = (R[i][N] - sum(R[i][j] * c[j] for j in range(i + 1, N))) / R[i][i]
    return c

def poly(x, y, t):                       # the degree-7 polynomial, Newton form
    c, n = y[:], len(x)
    for k in range(1, n):
        for i in range(n - 1, k - 1, -1): c[i] = (c[i] - c[i - 1]) / (x[i] - x[i - k])
    v = c[-1]
    for i in range(n - 2, -1, -1): v = v * (t - x[i]) + c[i]
    return v

T = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0]
Y = [z(t) for t in T]
H, B, D, P, M = moments(T, Y)
tq, zq = 15.0, z(15.0)
print("quotes, % a year:", " ".join(f"{v:.4f}" for v in Y))
print("gaps h:", " ".join(f"{v:g}" for v in H), "| slopes:", " ".join(f"{(Y[i + 1] - Y[i]) / H[i]:.6f}" for i in range(7)))
for i in range(6):
    print(f"row M{i + 1}: {H[i]:g}, {B[i]:g}, {H[i + 1]:g} | right side {D[i]:.6f}")
print("Thomas pivots:", " ".join(f"{v:.4f}" for v in P))
print("moments M_i = s''(T_i):", " ".join(f"{v:.6f}" for v in M))
sq, lin = ev(T, Y, M, tq)[0], (Y[5] + Y[6]) / 2
print(f"15y: straight line {lin:.6f}, bend term -6.25 x (M5 + M6) = {-6.25 * (M[5] + M[6]):.6f}, spline {sq:.6f}, true {zq:.6f}")
pv = lambda r: 1e7 * exp(-r / 100 * tq)
print(f"15y true error: spline {(sq - zq) * 100:.3f} bp, line {(lin - zq) * 100:.3f} bp; "
      f"$10m due in 15y: true {pv(zq):.2f}, spline off by {pv(sq) - pv(zq):.2f}")
sd = sum(w * 5**k for k, w in enumerate(dense(T, Y)[20:24]))   # piece 5 at u = 5
print(f"dense road, 28 by 28: 15y {sd:.6f}; gap to the moment road {abs(sd - sq):.1e}")
print(f"flops for 7 gaps: setup 7 + 14 + 12 + 12, Thomas {8 * 6 - 7}, total 15n - 19 = {15 * 7 - 19}; dense {(4 * 28**3 + 9 * 28**2 - 7 * 28) // 6}")
jl = [[abs(u - v) for u, v in zip(ev(T, Y, M, T[i], i - 1), ev(T, Y, M, T[i], i))] for i in range(1, 7)]
print("largest jump at the six inside knots: s {:.1e}, s' {:.1e}, s'' {:.1e}, s''' {:.6f}".format(
    *[max(j[k] for j in jl) for k in range(4)]))
dd = 1e-3
fd = (ev(T, Y, M, 10 + dd)[0] - 2 * ev(T, Y, M, 10.0)[0] + ev(T, Y, M, 10 - dd)[0]) / (dd * dd)
print(f"second difference straddling the 10y knot {fd:.6f}; moment M5 {M[5]:.6f}")
ts = [0.25, 1.0, 2.0, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0, 25.0, 30.0]
print("chart t:", " ".join(f"{t:g}" for t in ts))
for name, f in (("true  ", z), ("spline", lambda t: ev(T, Y, M, t)[0]), ("poly  ", lambda t: poly(T, Y, t))):
    print(" ", name, " ".join(f"{f(t):.3f}" for t in ts))
G = [0.25 + 29.75 * k / 5950 for k in range(5951)]
def bend(f):                             # integral of f''^2: second differences, Simpson
    w = [((f(t + dd) - 2 * f(t) + f(t - dd)) / (dd * dd))**2 for t in G]
    return 29.75 / 5950 / 3 * (w[0] + w[-1] + sum((4 if k % 2 else 2) * w[k] for k in range(1, 5950)))
bs = sum(H[i] / 3 * (M[i] * M[i] + M[i] * M[i + 1] + M[i + 1] * M[i + 1]) for i in range(7))
bz, bp = bend(z), bend(lambda t: poly(T, Y, t))
print(f"bending, integral of s'' squared: spline {bs:.6f}, true curve {bz:.6f}, polynomial {bp:.2f}")
print("refine: gaps halved L times | widest gap | max true error (% points), all; 1y to 20y | orders")
ER = []
for L in range(6):
    x = T[:]
    for _ in range(L): x = [v for i in range(len(x) - 1) for v in (x[i], (x[i] + x[i + 1]) / 2)] + [x[-1]]
    yx = [z(t) for t in x]
    Mx = moments(x, yx)[4]
    e = [abs(ev(x, yx, Mx, t)[0] - z(t)) for t in G]
    ER.append((max(e), max(e[k] for k in range(5951) if 1 <= G[k] <= 20)))
    o = "" if L == 0 else f" | {log2(ER[-2][0] / ER[-1][0]):.2f} {log2(ER[-2][1] / ER[-1][1]):.2f}"
    print(f"  L={L} knots {len(x):3d} | h {10 / 2**L:.4f} | {ER[-1][0]:.2e} {ER[-1][1]:.2e}{o}")
print("chart log10 h:", " ".join(f"{log10(10 / 2**L):.2f}" for L in range(6)))
print("  log10 error, all    ", " ".join(f"{log10(e[0]):.2f}" for e in ER))
print("  log10 error, 1y-20y ", " ".join(f"{log10(e[1]):.2f}" for e in ER))
es, pq, pw = ER[0][0], poly(T, Y, tq), max(abs(poly(T, Y, t) - z(t)) for t in G)
print(f"mistake, one degree-7 polynomial: 15y {pq:.6f}, off {(pq - zq) * 100:.2f} bp; worst {pw * 100:.1f} bp, spline's worst {es * 100:.2f} bp")
hb = 29.75 / 7                           # equal-spacing rows on uneven gaps
Mb = [0.0] + thomas([1.0] * 6, [4.0] * 6, [1.0] * 6,
                    [6 / (hb * hb) * (Y[i + 1] - 2 * Y[i] + Y[i - 1]) for i in range(1, 7)])[1] + [0.0]
sb = ev(T, Y, Mb, tq)[0]
print(f"mistake, equal-spacing rows with h = {hb:.4f}: 15y {sb:.6f}, off {(sb - zq) * 100:.2f} bp")
X2, Y2 = T[:6] + [10.05] + T[6:], Y[:6] + [Y[5] + 0.01] + Y[6:]
M2 = moments(X2, Y2)[4]
s2, w2 = ev(X2, Y2, M2, tq)[0], max(abs(ev(X2, Y2, M2, t)[0] - z(t)) for t in G)
print(f"break, a 10.05y quote 1 bp above the 10y: 15y {s2:.6f}, off {(s2 - zq) * 100:.2f} bp; worst {w2 * 100:.1f} bp")

assert abs(sd - sq) < 1e-12                           # two independent roads agree
assert max(max(j[:3]) for j in jl) < 1e-12 and max(j[3] for j in jl) > 1e-3  # C2 at the knots, not C3
assert abs(fd - M[5]) < 1e-5                          # s'' read off the curve = the moment
assert abs(sq - zq) < 0.01 and abs(lin - zq) > 5 * abs(sq - zq)  # spline beats the line at 15y
assert bs < bz < bp                                   # the spline bends least of the three
assert 3.5 < log2(ER[4][1] / ER[5][1]) < 4.5 and 1.5 < log2(ER[4][0] / ER[5][0]) < 2.5
assert pw > 100 * es and w2 > 10 * es                 # the polynomial and the near-repeat quote
print("ALL CHECKS PASS")
