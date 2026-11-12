# One polynomial through five swap quotes -- the check behind the card.  Standard library
# only.  Illustrative swap rates (percent) at 1, 2, 3, 5 and 10 years.  The degree-4 curve
# is built in exact fractions (the known answer), then by Lagrange, Newton, Vandermonde and
# barycentric in floats, with errors and operation counts.  Then a 7-year quote arrives.
from fractions import Fraction as Fr
X, Y, T = [1.0, 2.0, 3.0, 5.0, 10.0], [4.20, 3.95, 3.85, 3.90, 4.15], 7.0
XQ, YQ = [Fr(int(x)) for x in X], [Fr(int(round(y * 100)), 100) for y in Y]
ops = 0                                       # + - * / done, counted as they happen
def e(v): return f"{v:.1e}".replace("e-0", "e-").replace("e+0", "e+").replace("e+", "e")   # as Rust prints it

def lagrange(xs, ys, t):                      # road 1: sum of y_j times basis l_j(t)
    global ops
    s = ys[0] * 0
    for j in range(len(xs)):
        l = ys[0] * 0 + 1
        for k in range(len(xs)):
            if k != j:
                l = l * (t - xs[k]) / (xs[j] - xs[k]); ops += 4
        s = s + ys[j] * l; ops += 2
    return s
def divided(xs, ys):                          # road 2: Newton's divided-difference table
    global ops
    tab = [list(ys)]                          # level k, entry i: f[x_i, ..., x_(i+k)]
    for k in range(1, len(xs)):
        p = tab[-1]; ops += 3 * (len(p) - 1)
        tab.append([(p[i + 1] - p[i]) / (xs[i + k] - xs[i]) for i in range(len(p) - 1)])
    return tab
def nested(xs, c, t):                         # Newton form, evaluated inside out
    global ops
    p = c[-1]
    for i in range(len(c) - 2, -1, -1):
        p = p * (t - xs[i]) + c[i]; ops += 3
    return p
def solve(A, b):                              # Gaussian elimination, partial pivoting
    global ops
    n = len(b); M = [row[:] + [bi] for row, bi in zip(A, b)]; det = 1
    for i in range(n):
        piv = max(range(i, n), key=lambda r: abs(M[r][i]))
        if piv != i:
            M[i], M[piv] = M[piv], M[i]; det = -det
        det = det * M[i][i]
        for r in range(i + 1, n):
            f = M[r][i] / M[i][i]; ops += 1
            for c in range(i, n + 1):
                M[r][c] = M[r][c] - f * M[i][c]; ops += 2
    a = [0] * n
    for i in range(n - 1, -1, -1):
        s = M[i][n]
        for k in range(i + 1, n):
            s = s - M[i][k] * a[k]; ops += 2
        a[i] = s / M[i][i]; ops += 1
    return a, det
def horner(a, t):                             # monomial form a0 + a1 t + ... + a4 t^4
    global ops
    p = a[-1]
    for c in reversed(a[:-1]):
        p = p * t + c; ops += 2
    return p
def bary_weights(xs):                         # road 4: w_j = 1 / prod (x_j - x_k)
    global ops
    w = []
    for j in range(len(xs)):
        d = 1.0
        for k in range(len(xs)):
            if k != j:
                d = d * (xs[j] - xs[k]); ops += 2
        w.append(1.0 / d); ops += 1
    return w
def bary(xs, ys, w, t):                       # barycentric second form
    global ops
    num = den = 0.0
    for j in range(len(xs)):
        q = w[j] / (t - xs[j]); num = num + q * ys[j]; den = den + q; ops += 5
    ops += 1
    return num / den
def vander(xs): return [[x ** k for k in range(len(xs))] for x in xs]   # rows 1, x, x^2, x^3, x^4
def kappa(xs):                                # infinity-norm condition number, exact
    n = len(xs); inv = [solve(vander(xs), [Fr(int(i == j)) for i in range(n)])[0] for j in range(n)]
    norm = lambda M: max(sum(abs(v) for v in row) for row in M)
    return float(norm(vander(xs)) * norm([[inv[j][i] for j in range(n)] for i in range(n)]))
def l_coeffs(xs, j):                          # x^k coefficients of l_j: column j of V^-1, a second road
    c = [Fr(1)]
    for m in (m for m in range(len(xs)) if m != j):
        c = [((c[k - 1] if k else 0) - xs[m] * (c[k] if k < len(c) else 0)) / (xs[j] - xs[m]) for k in range(len(c) + 1)]
    return c
def counted(f, *args):
    global ops
    ops = 0; v = f(*args); return v, ops

exact = lagrange(XQ, YQ, Fr(7)); ex = float(exact)
print(f"quotes (years: percent) {', '.join(f'{x:.0f}: {y:.2f}' for x, y in zip(X, Y))}")
print(f"exact 7-year reading {exact} = {ex:.6f} percent")
tab, nc = counted(divided, X, Y); c = [col[0] for col in tab]; w, nw = counted(bary_weights, X)
a, na = counted(lambda: solve(vander(X), Y)[0])
roads = [("Lagrange", *counted(lagrange, X, Y, T), 0), ("Newton", *counted(nested, X, c, T), nc),
         ("Vandermonde", *counted(horner, a, T), na), ("barycentric", *counted(bary, X, Y, w, T), nw)]
for name, v, n_eval, n_setup in roads:
    print(f"{name:12s} 7y {v:.15f}  error {e(v - ex)}  ops setup {n_setup:3d}, per reading {n_eval:3d}")
    assert abs(v - ex) < 1e-13                # four float roads meet the exact answer
for k in range(1, 5): print(f"divided differences, level {k}: {', '.join(f'{v:.7f}' for v in tab[k])}")
print(f"Newton coefficients {', '.join(f'{v:.10f}' for v in c)}")
print(f"Newton terms at 7y {', '.join(f'{c[k] * g:.6f}' for k, g in enumerate([1, 6, 30, 120, 240]))}")
print(f"Lagrange basis at 7y {', '.join(f'{lagrange(X, [float(i == j) for i in range(5)], T):.6f}' for j in range(5))}")
print(f"monomial coefficients {', '.join(f'{v:.10f}' for v in a)}")
det = solve(vander(XQ), [Fr(0)] * 5)[1]; prod = 1
for i, j in [(i, j) for i in range(5) for j in range(i + 1, 5)]: prod = prod * (XQ[j] - XQ[i])
print(f"det V by elimination {det}, by product of node gaps {prod}")
assert det == prod and det != 0              # unique: V can be inverted
k1, k2 = kappa(XQ), kappa([(2 * x - 11) / 9 for x in XQ])
print(f"kappa(V) years 1..10 {k1:.1f}; rescaled to [-1, 1] {k2:.1f}")
Vi = [[l_coeffs(XQ, j)[k] for j in range(5)] for k in range(5)]     # V^-1 rebuilt: row k, every l_j's x^k
assert abs(k1 - float(max(sum(r) for r in vander(XQ)) * max(sum(abs(v) for v in r) for r in Vi))) < 1e-9 * k1
q7 = 4.00; X6, Y6 = X + [T], Y + [q7]
print(f"7y quote arrives {q7:.2f}: curve read {ex:.6f}, true error {(ex - q7) * 100:.2f} bp; line 5y-10y read {Y[3] + (Y[4] - Y[3]) * (T - X[3]) / (X[4] - X[3]):.6f}")
tab6, nu = counted(divided, X6, Y6); c6 = [col[0] for col in tab6]
_, nfull = counted(lambda: solve(vander(X6), Y6))
print(f"new Newton term {c6[-1]:.10f}; update ops Newton {nu - nc}, Vandermonde redo {nfull}")
assert c6[:5] == c                            # old Newton coefficients survive unchanged
n = 4; elim = lambda N: (N - 1) * N * (2 * N - 1) // 3 + 5 * N * (N - 1) // 2 + N * N   # this solve, N unknowns
assert [r[2] for r in roads] == [(4 * n + 2) * (n + 1), 3 * n, 2 * n, 5 * (n + 1) + 1]  # counts against closed forms
assert [nc, nw, na, nu - nc, nfull] == [3 * n * (n + 1) // 2, (2 * n + 1) * (n + 1), elim(n + 1), 3 * (n + 1), elim(n + 2)]
r4, r4n = nested(X, c, 4.0), nested(X6, c6, 4.0)
r4x = float(lagrange(XQ + [Fr(7)], YQ + [Fr(4)], Fr(4)))
print(f"4y reading before {r4:.6f}, after {r4n:.6f}, exact after {r4x:.6f}")
assert abs(r4n - r4x) < 1e-13 and abs(nested(X6, c6, T) - q7) < 1e-13
try: divided([1.0, 2.0, 3.0, 5.0, 5.0], [4.20, 3.95, 3.85, 3.90, 3.92]); bad = "no error"
except ZeroDivisionError: bad = "division by zero"
wx = 1.0                                      # omega(x) = (x - 1)(x - 2)(x - 3)(x - 5)(x - 10)
for x in X: wx = wx * (T - x)
print(f"mistake 1, two 5y quotes 3.90 and 3.92: {bad}")
print(f"mistake 2, degree 5 adds 0.0001 x omega(x), omega(7) = {wx:.0f}: 7y reads {ex + 1e-4 * wx:.6f}")
ar = [round(v * 1e4) / 1e4 for v in a]
print(f"mistake 3, coefficients to 4 decimals: 10y reads {horner(ar, 10.0):.6f}, 7y {horner(ar, T):.6f}")
print(f"mistake 4, read at 30 years: {nested(X, c, 30.0):.6f} percent")
assert abs(horner(ar, 10.0) - 4.15) > 0.03 and nested(X, c, 30.0) > 90
print("figure, " + ", ".join(f"{nested(X, c, float(t)):.4f}" for t in range(13)))
print("ALL CHECKS PASS")
