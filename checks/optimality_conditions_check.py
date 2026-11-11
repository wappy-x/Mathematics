# Optimality conditions on the banana valley.  Standard library only.
# Minimise f(x) = sum over i of b(x[i+1] - x[i]^2)^2 + (1 - x[i])^2.  Two variables: the banana.
import functools, itertools, math

def total(terms): return functools.reduce(lambda t, v: t + v, terms, 0.0)   # plain left-to-right sum, as in Rust
def f(x, b=100.0):
    return total(b * (x[i + 1] - x[i] * x[i]) * (x[i + 1] - x[i] * x[i]) + (1 - x[i]) * (1 - x[i]) for i in range(len(x) - 1))
def grad(x, b=100.0):                                  # the slopes, by hand
    g = [0.0] * len(x)
    for i in range(len(x) - 1):
        w = x[i + 1] - x[i] * x[i]
        g[i] += -4 * b * x[i] * w - 2 * (1 - x[i])
        g[i + 1] += 2 * b * w
    return g
def hess(x, b=100.0):                                  # the second derivatives, by hand
    H = [[0.0] * len(x) for _ in x]
    for i in range(len(x) - 1):
        H[i][i] += 12 * b * x[i] * x[i] - 4 * b * x[i + 1] + 2
        H[i][i + 1] -= 4 * b * x[i]; H[i + 1][i] -= 4 * b * x[i]
        H[i + 1][i + 1] += 2 * b
    return H
def solve(A, r):                                       # elimination with row swaps; None if singular
    n = len(r); M = [A[i][:] + [r[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(M[i][c]))
        if M[p][c] == 0: return None
        M[c], M[p] = M[p], M[c]
        for i in range(c + 1, n):
            m = M[i][c] / M[c][c]
            for k in range(c, n + 1): M[i][k] -= m * M[c][k]
    z = [0.0] * n
    for i in reversed(range(n)):
        z[i] = (M[i][n] - total(M[i][k] * z[k] for k in range(i + 1, n))) / M[i][i]
    return z

def pivots(H):                                         # elimination without swaps: H = L P L^T
    n = len(H); A = [row[:] for row in H]; L = [[float(i == j) for j in range(n)] for i in range(n)]
    for c in range(n):
        if A[c][c] == 0: return [A[i][i] if i <= c else 0.0 for i in range(n)], L
        for i in range(c + 1, n):
            L[i][c] = A[i][c] / A[c][c]
            for k in range(c, n): A[i][k] -= L[i][c] * A[c][k]
    return [A[i][i] for i in range(n)], L
def verdict(piv):                                      # signs of pivots = signs of eigenvalues
    if 0.0 in piv: return "no verdict"
    neg = sum(p < 0 for p in piv)
    return "strict local minimum" if neg == 0 else "strict local maximum" if neg == len(piv) else f"saddle ({neg} negative)"
def newton(x):                                         # Newton on grad f = 0: finds flat spots of any kind
    for _ in range(50):
        if max(abs(v) for v in x) > 1e3: return None
        d = solve(hess(x), grad(x))
        if d is None: return None
        x = [a - e for a, e in zip(x, d)]
    return x if max(abs(v) for v in grad(x)) < 1e-9 else None
def flat_spots(n):                                     # Newton from every start in a grid of 5^n points
    found, fails = {}, 0
    for s in itertools.product((-1.2, -0.5, 0.0, 0.5, 1.2), repeat=n):
        z = newton(list(s))
        if z is None: fails += 1; continue
        found.setdefault(fmt(z), [z, 0])[1] += 1
    return sorted(found.values(), key=lambda p: f(p[0])), fails

def step(x, d, t): return [a + t * u for a, u in zip(x, d)]
def unit(v): s = math.sqrt(total(a * a for a in v)); return [a / s for a in v]
def fmt(v, p=6): return "(" + ", ".join(f"{a:.{p}f}" for a in v) + ")"
def by_differences(x, h=1e-5):                         # road 2: slopes and bends from f alone
    E = [[float(i == j) for j in range(len(x))] for i in range(len(x))]
    g = [(f(step(x, e, h)) - f(step(x, e, -h))) / (2 * h) for e in E]
    H = [[(f(step(step(x, a, h), c, h)) - f(step(step(x, a, h), c, -h)) - f(step(step(x, a, -h), c, h))
           + f(step(step(x, a, -h), c, -h))) / (4 * h * h) for c in E] for a in E]
    return g, H

# ---- the banana, n = 2 ----
x = [-1.2, 1.0]; heights = []
for k in range(7):
    x = step(x, solve(hess(x), grad(x)), -1.0); heights.append(f(x))
print(f"start (-1.2, 1): f = {f([-1.2, 1.0]):.6f}; newton on grad = 0, f after steps 1-7: " + " ".join(f"{v:.2f}" for v in heights))
xs = x; H = hess(xs); gd, Hd = by_differences(xs)
print(f"flat spot {fmt(xs)}: f = {f(xs):.6f}, gradient {fmt(grad(xs))}, by differences {fmt([abs(v) for v in gd])}")
print(f"hessian by hand {H[0][0]:.3f} {H[0][1]:.3f} {H[1][1]:.3f}; by differences {Hd[0][0]:.3f} {Hd[0][1]:.3f} {Hd[1][1]:.3f}")
assert max(abs(Hd[i][j] - H[i][j]) for i in range(2) for j in range(2)) < 0.01 and max(map(abs, gd)) < 1e-4
def eig2(H):                                           # eigenvalues of a 2 by 2 table from trace and det
    T, D = H[0][0] + H[1][1], H[0][0] * H[1][1] - H[0][1] * H[1][0]
    return T, D, (T + math.sqrt(T * T - 4 * D)) / 2, (T - math.sqrt(T * T - 4 * D)) / 2
T, D, lmax, lmin = eig2(H)
print(f"trace {T:.6f}, det {D:.6f}, eigenvalues {lmax:.6f} and {lmin:.6f}, stretch {lmax / lmin:.2f}")
q = [H[0][0] * c * c + 2 * H[0][1] * c * s + H[1][1] * s * s
     for c, s in ((math.cos(k * math.pi / 3600), math.sin(k * math.pi / 3600)) for k in range(3600))]
print(f"d'Hd over 3600 unit directions: largest {max(q):.4f}, smallest {min(q):.4f}")
assert abs(min(q) - lmin) < 1e-3 and abs(max(q) - lmax) < 1e-3
piv, _ = pivots(H)
print(f"pivots {piv[0]:.6f} and {piv[1]:.6f}: {verdict(piv)}")
vflat, vsteep = unit([-H[0][1], H[0][0] - lmin]), unit([-H[0][1], H[0][0] - lmax])
print(f"flat direction {fmt(vflat)}, steep direction {fmt(vsteep)}")
print(f"contour f = 0.01, quadratic model: {math.sqrt(0.02 / lmin):.4f} along the flat way, {math.sqrt(0.02 / lmax):.4f} along the steep way")
r = 0.01
rise = min(f(step(xs, [math.cos(k * math.pi / 1800), math.sin(k * math.pi / 1800)], r)) for k in range(3600)) - f(xs)
print(f"circle of radius 0.01: smallest rise {rise:.4e}; model lmin r^2/2 = {lmin * r * r / 2:.4e}")
assert 0 < rise and abs(rise - lmin * r * r / 2) < 0.1 * lmin * r * r / 2
best = min((f([i / 100, j / 100]), i / 100, j / 100) for i in range(-200, 201) for j in range(-200, 201))
print(f"grid over [-2, 2] x [-2, 2], spacing 0.01: lowest f = {best[0]:.6f} at ({best[1]:.2f}, {best[2]:.2f})")
assert best[1:] == (1.0, 1.0) and best[0] == f(xs)

# ---- the chained banana, n = 4 ----
pts, fails = flat_spots(4)
dirs = [unit(list(s)) for s in itertools.product((-1, 0, 1), repeat=4) if any(s)]
print(f"n = 4: Newton from 625 starts finds {len(pts)} flat spots; {fails} starts did not settle")
for z, count in pts:
    piv, _ = pivots(hess(z)); gd, Hd = by_differences(z)
    assert max(abs(Hd[i][j] - hess(z)[i][j]) for i in range(4) for j in range(4)) < 0.05 and max(map(abs, gd)) < 1e-4
    low = min(f(step(z, d, 1e-3)) for d in dirs) - f(z)
    print(f"{fmt(z)} f = {f(z):.6f} from {count:3d} starts; pivots {fmt(piv, 3)}: {verdict(piv)}; 80-direction rise {low:.3e}")
sad = pts[-1][0]; Hs = hess(sad); piv, L = pivots(Hs)
k = piv.index(min(piv)); d = [float(i == k) for i in range(4)]
for i in range(k - 1, -1, -1): d[i] = -total(L[j][i] * d[j] for j in range(i + 1, 4))   # solve L^T d = e_k
d = unit(d); curv = total(d[i] * Hs[i][j] * d[j] for i in range(4) for j in range(4))
drop = f(step(sad, d, 0.01)) - f(sad)
print(f"saddle: diagonal {fmt([Hs[i][i] for i in range(4)], 3)}; downhill direction {fmt(d)}")
print(f"saddle: d'Hd = {curv:.4f}; a step of 0.01 along d changes f by {drop:.4e} (model {curv * 0.0001 / 2:.4e})")
assert curv < 0 and drop < 0 and min(Hs[i][i] for i in range(4)) > 0
assert [verdict(pivots(hess(z))[0]) for z, _ in pts[:2]] == ["strict local minimum"] * 2

# ---- what breaks ----
for name, sgn in (("x^2 + y^4", 1.0), ("x^2 - y^4", -1.0)):
    Hb = [[2.0, 0.0], [0.0, 0.0]]                          # second derivatives 2 and 12y^2 at (0, 0)
    print(f"breaks, {name}: hessian at 0 is diag(2, 0): {verdict(pivots(Hb)[0])}; f(0, 0.1) = {sgn * 0.1 * 0.1 * 0.1 * 0.1:.6f}")
p3 = pivots([[2.0, 0.0, 0.0], [0.0, -2.0, 0.0], [0.0, 0.0, -2.0]])[0]
print(f"breaks, x^2 - y^2 - z^2: det {p3[0] * p3[1] * p3[2]:.0f} and top-left {p3[0]:.0f}, yet pivots {fmt(p3, 0)}: {verdict(p3)}; f(0, 0.1, 0) = {-0.1 * 0.1:.6f}")
assert verdict(p3) != "strict local minimum" and p3[0] * p3[1] * p3[2] > 0
print(f"breaks, local read as global: f = {f(pts[1][0]):.6f} at the second pit, {f(pts[0][0]):.6f} at (1, 1, 1, 1)")

# ---- try changing, and the figure ----
H1 = hess([1.0, 1.0], b=1.0); _, _, l1, l2 = eig2(H1)
print(f"try b = 1: hessian {H1[0][0]:.0f} {H1[0][1]:.0f} {H1[1][1]:.0f}, eigenvalues {l1:.4f} and {l2:.4f}, stretch {l1 / l2:.2f}")
pm = pivots([[-v for v in row] for row in H])[0]
print(f"try minus f: pivots {fmt(pm)}: {verdict(pm)}")
p3s, _ = flat_spots(3)
print(f"try n = 3: Newton from 125 starts finds {len(p3s)} flat spot(s): " + ", ".join(fmt(z) for z, _ in p3s))
print("figure, contour f = c runs from x = 1 - sqrt(c) to 1 + sqrt(c): " + "; ".join(f"c = {c}: {1 - math.sqrt(c):.2f} to {1 + math.sqrt(c):.2f}" for c in (0.01, 0.25, 1, 4, 24.2)))
print("ALL CHECKS PASS")
