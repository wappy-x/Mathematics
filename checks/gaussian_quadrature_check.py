# Gaussian quadrature -- the check behind the card.  Standard library only.
# A 6 m simply supported beam carries a load rising from 0 to 12 kN/m; EI = 20,000 kN m^2.
# Bending energy U = integral over the span of M(x)^2 / (2 EI), with M(x) = w0 x (L^2 - x^2) / (6 L).
# Roads: exact integration term by term; Gauss nodes found by bisection on the Legendre
# polynomial with the weight formula; the closed-form 4-point rule; weights from moment equations.
from math import sqrt, log10
from functools import reduce

L, W0, EI = 6.0, 12.0, 20000.0                    # m, kN/m, kN m^2
def e(x, d=3):                                    # e-notation, printed the same way in Rust
    m, p = f"{x:.{d}e}".split("e")
    return m + "e" + str(int(p))
def pw(x, k): return 1.0 if k == 0 else x * pw(x, k - 1)  # x^k by plain multiplies
def total(v): return reduce(lambda a, b: a + b, v, 0.0)  # left-to-right sum, as in Rust
def legendre(n, x):                               # Bonnet's rule; returns P_n(x), P_(n-1)(x)
    p0, p1 = 1.0, x
    for k in range(1, n):
        p0, p1 = p1, ((2 * k + 1) * x * p1 - k * p0) / (k + 1)
    return p1, p0
def gauss(n):                                     # zeros of P_n by bisection; w = 2 / ((1 - x^2) P_n'(x)^2)
    xs, ws, grid = [], [], 2001
    for i in range(grid):
        a, b = -1.0 + 2.0 * i / grid, -1.0 + 2.0 * (i + 1) / grid
        fa = legendre(n, a)[0]
        if fa * legendre(n, b)[0] > 0.0:
            continue
        while True:
            m = 0.5 * (a + b)
            if m == a or m == b:
                break
            fm = legendre(n, m)[0]
            if fa * fm <= 0.0:
                b = m
            else:
                a, fa = m, fm
        p, q = legendre(n, a)
        dp = n * (a * p - q) / (a * a - 1.0)
        xs.append(a)
        ws.append(2.0 / ((1.0 - a * a) * dp * dp))
    return xs, ws
def rule(f, a, b, xs, ws):                        # stretch [-1, 1] onto [a, b]: x = mid + half t, dx = half dt
    mid, half = 0.5 * (a + b), 0.5 * (b - a)
    return half * total(w * f(mid + half * t) for t, w in zip(xs, ws))
def moment_weights(xs):                           # solve sum_j w_j x_j^k = integral of t^k, k = 0..n-1
    n = len(xs)
    A = [[pw(x, k) for x in xs] + [2.0 / (k + 1) if k % 2 == 0 else 0.0] for k in range(n)]
    for c in range(n):
        piv = max(range(c, n), key=lambda r: abs(A[r][c]))
        A[c], A[piv] = A[piv], A[c]
        for r in range(c + 1, n):
            f = A[r][c] / A[c][c]
            A[r] = [A[r][j] - f * A[c][j] for j in range(n + 1)]
    w = [0.0] * n
    for r in range(n - 1, -1, -1):
        w[r] = (A[r][n] - total(A[r][j] * w[j] for j in range(r + 1, n))) / A[r][r]
    return w
def M(x): return W0 * x * (L * L - x * x) / (6.0 * L)       # bending moment, kN m
def energy(x): return 1000.0 * M(x) * M(x) / (2.0 * EI)        # J per m of span
c = W0 / (6.0 * L)                                            # M^2 = c^2 (L^4 x^2 - 2 L^2 x^4 + x^6)
U = 1000.0 * c * c * (pw(L, 7) / 3 - 2 * pw(L, 7) / 5 + pw(L, 7) / 7) / (2.0 * EI)
print(f"L {L:.0f} m, w0 {W0:.0f} kN/m, EI {EI:.0f} kN m^2; exact U (J): term by term {U:.12f}", "| 1000 w0^2 L^5/(945 EI)", f"{1000.0 * W0 * W0 * pw(L, 5) / (945.0 * EI):.12f}")
x2, w2 = gauss(2)
print("2-point nodes", f"{x2[0]:.12f} {x2[1]:.12f}", "weights", f"{w2[0]:.12f} {w2[1]:.12f}")
assert abs(x2[1] - 1.0 / sqrt(3.0)) < 1e-15 and abs(w2[0] - 1.0) < 1e-14
for k in range(5):
    print(f"2-point on t^{k}: rule {rule(lambda t: pw(t, k), -1.0, 1.0, x2, w2):.12f}"
          f" exact {2.0 / (k + 1) if k % 2 == 0 else 0.0:.12f}")

x4, w4 = gauss(4)
s = 2.0 * sqrt(6.0 / 5.0)                         # closed form: x^2 = (3 -+ 2 sqrt(6/5)) / 7, w = (18 +- sqrt 30) / 36
cx = [-sqrt((3 + s) / 7), -sqrt((3 - s) / 7), sqrt((3 - s) / 7), sqrt((3 + s) / 7)]
cw = [(18 - sqrt(30.0)) / 36, (18 + sqrt(30.0)) / 36, (18 + sqrt(30.0)) / 36, (18 - sqrt(30.0)) / 36]
mw = moment_weights(x4)
for j in range(4):
    print(f"4-point t {x4[j]:+.15f} w {w4[j]:.15f} | x {3 + 3 * x4[j]:.6f} m, energy {energy(3 + 3 * x4[j]):.6f} J/m")
dx = max(abs(a - b) for a, b in zip(x4, cx))
dw = max(abs(a - b) for a, b in zip(w4, cw))
dm = max(abs(a - b) for a, b in zip(w4, mw))
print("vs closed form: nodes", e(dx), "weights", e(dw), "| weights by moments", e(dm))
assert dx < 1e-15 and dw < 1e-14 and dm < 1e-13

degs = []
for n in range(1, 7):                             # highest degree k with every t^0..t^k exact
    xs, ws = gauss(n)
    k = 0
    while abs(rule(lambda t: pw(t, k), -1.0, 1.0, xs, ws) - (2.0 / (k + 1) if k % 2 == 0 else 0.0)) < 1e-13:
        k += 1
    degs.append(k - 1)
print("degree of exactness, n = 1..6:", degs)
assert degs == [2 * n - 1 for n in range(1, 7)]

print("beam, n points: U_n (J), true error")
errs = []
for n in range(1, 7):
    xs, ws = gauss(n)
    Un = rule(energy, 0.0, L, xs, ws)
    errs.append(U - Un)
    print(f"  n={n} {Un:.12f} {e(U - Un)}")
assert abs(errs[3]) < 4e-15 * U and abs(errs[2]) > 1e-4
# n = 3 error from the theorem: K_3 f^(6), K_3 = 2^7 (3!)^4 / (7 (6!)^3); f^(6) = 720 x leading coefficient in t
K3 = 128.0 * 1296.0 / (7.0 * 720.0 * 720.0 * 720.0)
lead = 1000.0 * c * c * pw(L / 2, 7) / (2.0 * EI)  # t^6 coefficient of (L/2) energy(L/2 (1 + t))
pred = K3 * 720.0 * lead
print("n=3 error: theorem", e(pred), "true", e(errs[2]), "ratio", f"{errs[2] / pred:.6f}")
assert abs(errs[2] / pred - 1.0) < 1e-9

def trap(f, a, b, m):
    h = (b - a) / m
    return h * (0.5 * f(a) + 0.5 * f(b) + total(f(a + i * h) for i in range(1, m)))
def simpson(f, a, b, m):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + total((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m)))
print("4-point trapezoid", e(U - trap(energy, 0.0, L, 3)), "| 5-point Simpson", e(U - simpson(energy, 0.0, L, 4)))
m = next(m for m in range(2, 4000, 2) if abs(U - simpson(energy, 0.0, L, m)) <= 1e-12 * U)   # fewest even slice count
print("Simpson to relative error 1e-12:", m + 1, "points, error", e(U - simpson(energy, 0.0, L, m)))
assert abs(U - simpson(energy, 0.0, L, 2 * m)) < abs(U - simpson(energy, 0.0, L, m)) / 8   # h^4: twice the slices, near 16 times less error

print("chart, log10 relative error by points used, n = 2..8: Gauss | trapezoid")
print("  ", " ".join(f"{log10(abs(U - rule(energy, 0.0, L, *gauss(n))) / U):.2f}" for n in range(2, 9)))
print("  ", " ".join(f"{log10(abs(U - trap(energy, 0.0, L, n - 1)) / U):.2f}" for n in range(2, 9)))

print("break: no half-width factor", f"{total(w * energy(3.0 + 3.0 * t) for t, w in zip(x4, w4)):.6f}")
eq = [-1.0, -1.0 / 3, 1.0 / 3, 1.0]               # four equally spaced points, Simpson's 3/8 weights
print("break: 4 equal points, 3/8 rule", e(U - rule(energy, 0.0, L, eq, [0.25, 0.75, 0.75, 0.25])))
prev = None
for n in (2, 4, 8, 16, 32):                       # sqrt(x) on [0, 1]: infinite slope at 0
    err = abs(2.0 / 3.0 - rule(sqrt, 0.0, 1.0, *gauss(n)))
    print(f"break: sqrt(x), n={n} error {e(err)}" + (f" order {log10(prev / err) / log10(2.0):.2f}, theory 3" if prev else ""))
    prev = err
assert prev > 1e-6                                # the crawl: still wrong in the sixth digit at 32 points
x3, w3 = gauss(3)
Uu = 1000.0 * W0 * W0 * pw(L, 5) / (240.0 * EI)     # try: uniform 12 kN/m, M = w0 x (L - x) / 2, M^2 of degree 4
uni = lambda x: 1000.0 * pw(W0 * x * (L - x) / 2, 2) / (2.0 * EI)
print(f"try: uniform load U {Uu:.6f}, error n=2", e(Uu - rule(uni, 0.0, L, x2, w2)), "n=3", e(Uu - rule(uni, 0.0, L, x3, w3)))
print("try: sqrt(x) as 2 s^2 on s in [0, 1], n=2 error", e(2.0 / 3.0 - rule(lambda s: 2.0 * s * s, 0.0, 1.0, x2, w2)))
L = 12.0                                          # try: double the span; energy() reads L afresh
print(f"try: span 12 m, U {32.0 * U:.6f}, n=4 error", e(32.0 * U - rule(energy, 0.0, L, x4, w4)))
print("ALL CHECKS PASS")
