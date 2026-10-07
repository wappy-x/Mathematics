# Convex functions -- the check behind the card.  Nothing imported.  A seedling measured at
# weeks 0-3; fit height = a + b*week.  The squared error S(a, b) is convex: two roads, one fit.
X, Y = [0, 1, 2, 3], [1, 3, 4, 6]

def S(a, b, xs=X):                                   # squared error of the line a + b*x
    return sum((y - a - b * x) ** 2 for x, y in zip(xs, Y))

def descend(f, p, rate, steps, h=1e-4):              # gradient descent, slopes by central differences
    p = list(p)
    for _ in range(steps):
        g = [(f(*[p[j] + h * (i == j) for j in range(len(p))]) -
              f(*[p[j] - h * (i == j) for j in range(len(p))])) / (2 * h) for i in range(len(p))]
        p = [pj - rate * gj for pj, gj in zip(p, g)]
    return p

n, sx, sy = len(X), sum(X), sum(Y)
sxx, sxy = sum(x * x for x in X), sum(x * y for x, y in zip(X, Y))
b = (n * sxy - sx * sy) / (n * sxx - sx * sx)        # road 1: the normal equations, solved
a = (sy - b * sx) / n
H = [[2 * n, 2 * sx], [2 * sx, 2 * sxx]]             # Hessian of S, from its formula
e = 0.01                                             # Hessian again, by second differences
Hd = [[(S(a + e, b) - 2 * S(a, b) + S(a - e, b)) / e ** 2,
       (S(a + e, b + e) - S(a + e, b - e) - S(a - e, b + e) + S(a - e, b - e)) / (4 * e * e)],
      [0, (S(a, b + e) - 2 * S(a, b) + S(a, b - e)) / e ** 2]]
Hd[1][0] = Hd[0][1]
det, tr = H[0][0] * H[1][1] - H[0][1] ** 2, H[0][0] + H[1][1]
lam = [(tr + (tr * tr - 4 * det) ** 0.5) / 2, (tr - (tr * tr - 4 * det) ** 0.5) / 2]
quad = lambda d: sum(d[i] * H[i][j] * d[j] for i in range(2) for j in range(2))   # d'Hd
ends = [descend(S, s, 0.05, 400) for s in ((10, -10), (-10, 10))]
errs = [max(abs(u - v) for u, v in zip(descend(S, (10, -10), 0.05, k), (a, b))) for k in (25, 50, 100, 200)]
bs = [0.5 * k for k in range(7)]
P, W = [(0, 2), (2, 1), (3, 0)], [0.5, 0.3, 0.2]     # Jensen: three fits, three weights
m = [sum(w * p[i] for w, p in zip(W, P)) for i in range(2)]
jgap = sum(w * S(*p) for w, p in zip(W, P)) - S(*m)
jgap2 = sum(w * quad([p[0] - m[0], p[1] - m[1]]) / 2 for w, p in zip(W, P))
cgap, cgap2 = (S(0, 2) + S(2, 1)) / 2 - S(1, 1.5), quad([2, -1]) / 8
wf = lambda x: x ** 4 - 4 * x * x + x                # a wavy error curve: not convex
wl, wr = descend(wf, (-2,), 0.01, 2000)[0], descend(wf, (2,), 0.01, 2000)[0]
X2 = [2, 2, 2, 2]                                    # all four measurements in week 2
det2 = (2 * 4) * (2 * sum(x * x for x in X2)) - (2 * sum(X2)) ** 2
print(f"weeks {X}, heights {Y} cm")
print(f"sums: x {sx}, x^2 {sxx}, y {sy}, xy {sxy}; residuals " + ", ".join(f"{y - a - b * x:.1f}" for x, y in zip(X, Y)))
print(f"road 1, normal equations: a = {a:.3f} cm, b = {b:.3f} cm/week, S = {S(a, b):.3f}")
for s, p in zip(("(10, -10)", "(-10, 10)"), ends):
    print(f"road 2, descent from {s}: a = {p[0]:.6f}, b = {p[1]:.6f}")
print("descent error after 25, 50, 100, 200 steps: " + ", ".join(f"{x:.1e}" for x in errs))
print(f"Hessian by formula: {H}; by second differences: [[{Hd[0][0]:.4f}, {Hd[0][1]:.4f}], [{Hd[1][0]:.4f}, {Hd[1][1]:.4f}]]")
print(f"determinant {det}, trace {tr}, stretch factors {lam[0]:.2f} and {lam[1]:.2f}")
print("chart b: " + ", ".join(f"{x:.1f}" for x in bs))
print("chart S(1.1, b): " + ", ".join(f"{S(1.1, x):.2f}" for x in bs))
print("chart chord: " + ", ".join(f"{S(1.1, 0) + (S(1.1, 3) - S(1.1, 0)) * x / 3:.2f}" for x in bs))
print(f"chord: S(0, 2) = {S(0, 2):.2f}, S(2, 1) = {S(2, 1):.2f}, S(1, 1.5) = {S(1, 1.5):.2f}; gap {cgap:.2f}, by d'Hd/8 {cgap2:.2f}")
print(f"Jensen: S at (0, 2), (2, 1), (3, 0): " + ", ".join(f"{S(*p):.2f}" for p in P) + f"; mix ({m[0]:.2f}, {m[1]:.2f}), S at mix {S(*m):.2f}, mix of S {S(*m) + jgap:.2f}; gap {jgap:.2f}, by Hessian {jgap2:.2f}")
print(f"mistake 1, wavy curve: w''(0) = {(wf(e) - 2 * wf(0) + wf(-e)) / e ** 2:.2f}; descent from 2 stops at x = {wr:.4f}, w = {wf(wr):.4f}; from -2 at x = {wl:.4f}, w = {wf(wl):.4f}")
print(f"mistake 2, all weeks 2: determinant {det2}; S(3.5, 0) = {S(3.5, 0, X2):.2f}, S(1.5, 1) = {S(1.5, 1, X2):.2f}")
assert all(abs(p[0] - a) < 1e-6 and abs(p[1] - b) < 1e-6 for p in ends)          # two roads, one fit
assert all(abs(Hd[i][j] - H[i][j]) < 1e-6 for i in range(2) for j in range(2))   # Hessian two ways
assert abs(jgap - jgap2) < 1e-9 and abs(cgap - cgap2) < 1e-9 and jgap > 0        # Jensen gap two ways
assert wf(wl) < wf(wr) - 1 and abs(S(3.5, 0, X2) - S(1.5, 1, X2)) < 1e-12        # what breaks
print("ALL CHECKS PASS")
