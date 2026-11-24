# Feigenbaum renormalisation -- the check behind the card.  Standard library only.
# Road one: three one-hump maps, superstable dials found by Newton in the dial.
# Road two: the doubling operator T g(x) = -alpha g(g(-x/alpha)), its fixed point by Newton.
from math import sin, pi, sqrt
from functools import reduce
def g(c, x):                             # g(x) = 1 + c1 x^2 + c2 x^4 + ...
    return 1 + sum(cj * x ** (2 * j + 2) for j, cj in enumerate(c))
def T(c, x):                             # the doubling operator, with alpha = -1/g(1)
    a = -1 / g(c, 1)
    return -a * g(c, g(c, -x / a))
def solve(A, b):                         # Gaussian elimination with row swaps
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(M[i][k])); M[k], M[p] = M[p], M[k]
        for i in range(k + 1, n):
            m = M[i][k] / M[k][k]; M[i] = [u - m * v for u, v in zip(M[i], M[k])]
    x = [0.0] * n
    for i in reversed(range(n)): x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def jac(F, c, h):                        # F at c, and its slopes by small nudges
    f0 = F(c); cols = [F(c[:j] + [c[j] + h] + c[j + 1:]) for j in range(len(c))]
    return f0, [[(cols[j][i] - f0[i]) / h for j in range(len(c))] for i in range(len(c))]
def fixed_point(N):                      # Newton: g = T g at x = 1/N, 2/N, ..., 1
    xs, c = [(i + 1) / N for i in range(N)], ([-1.5, 0.1] + [0.0] * (N - 2))[:N]
    for _ in range(30):
        f0, J = jac(lambda c: [g(c, x) - T(c, x) for x in xs], c, 1e-7)
        c = [u + v for u, v in zip(c, solve(J, [-v for v in f0]))]
    V = [[x ** (2 * j + 2) for j in range(N)] for x in xs]   # values -> coefficients
    _, J = jac(lambda c: solve(V, [T(c, x) - 1 for x in xs]), c, 1e-6)
    v, lam = [1.0] * N, 0.0
    for _ in range(200):                 # power iteration: T's largest stretch near g
        w = [sum(J[i][j] * v[j] for j in range(N)) for i in range(N)]
        lam = max(w, key=abs) / max(v, key=abs); v = [u / max(w, key=abs) for u in w]
    return c, -1 / g(c, 1), lam
orbit = lambda f, r, p: reduce(lambda x, _: f(r, x), range(p), 0.5)   # p steps from the top
def superstable(f, p, r):                # Newton in r: the p-cycle passes through x = 1/2
    G = lambda r: orbit(f, r, p) - 0.5
    for _ in range(40): h = 1e-9 * max(1, abs(r)); r -= G(r) * 2 * h / (G(r + h) - G(r - h))
    return r
fm, out = (lambda v, d: " ".join(f"{x:.{d}f}" for x in v)), []
maps = [("logistic r x (1 - x)", lambda r, x: r * x * (1 - x), 2.0, 3.2),
        ("sine r sin(pi x)", lambda r, x: r * sin(pi * x), 0.5, 0.78),
        ("flat top r (1 - (2x - 1)^4)", lambda r, x: r * (1 - (2 * x - 1) ** 4), 0.5, 0.915)]
for name, f, a0, a1 in maps:
    R = [superstable(f, 1, a0), superstable(f, 2, a1)]
    for k in range(2, 9):                # guess: the last gap shrunk by the last ratio
        R.append(superstable(f, 2 ** k, R[-1] + (R[-1] - R[-2]) / (6 if k == 2 else (R[-2] - R[-3]) / (R[-1] - R[-2]))))
    d = [orbit(f, R[k], 2 ** (k - 1)) - 0.5 for k in range(1, 9)]
    out.append((R, [(R[i] - R[i - 1]) / (R[i + 1] - R[i]) for i in range(1, 8)], [d[i] / d[i + 1] for i in range(7)], d))
    print(f"{name}, superstable dials: {fm(R, 6)}\n  gap ratios: {fm(out[-1][1], 4)}\n  window ratios: {fm(out[-1][2], 4)}")
(R, dl, al, d), (_, ds, als, _), (_, dq, aq, _) = out
print(f"logistic by hand: 1 + sqrt(5) = {1 + sqrt(5):.6f}; gaps {fm([R[i + 1] - R[i] for i in range(3)], 6)}; windows {fm(d[:2], 6)}")
for N in (1, 2, 4, 8):
    c, alpha, delta = fixed_point(N)
    print(f"fixed point of T, N = {N}: alpha {alpha:.6f}, delta {delta:.6f}, c = {fm(c[:3], 6)}")
assert abs(R[1] - (1 + sqrt(5))) < 1e-12                       # Newton against the closed form
assert abs(alpha + al[-1]) < 1e-4 and abs(alpha + als[-1]) < 1e-4  # operator against two maps
assert abs(delta - dl[-1]) < 1e-4 and abs(delta - ds[-1]) < 1e-4   # eigenvalue against two maps
assert dq[-1] > 7 and abs(aq[-1]) < 2                          # flat top: another family
print("ALL CHECKS PASS")
