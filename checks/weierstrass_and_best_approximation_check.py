# Weierstrass and the minimax fit -- the check behind the card.  Standard library only.
# Target (illustrative spec): exp on [0, 1] with absolute error at most a millionth, 1e-06.
# Roads: Remez (levelled error, then max error), Chebyshev interpolation boxed in by the
# de la Vallee Poussin bound, the Chebyshev a-priori bound, Taylor, and Bernstein polynomials.
import math
TOL, E1 = 1e-06, math.exp(1.0)

def solve(A, b):                       # Gaussian elimination with partial pivoting
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = c
        for r in range(c + 1, n):
            if abs(M[r][c]) > abs(M[p][c]): p = r
        M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            m = M[r][c] / M[c][c]
            for k in range(c, n + 1): M[r][k] -= m * M[c][k]
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        s = M[r][n]
        for k in range(r + 1, n): s -= M[r][k] * x[k]
        x[r] = s / M[r][r]
    return x

def pows(t, n): return [math.prod([t] * k) for k in range(n + 1)]
def horner(c, t):
    s = 0.0
    for a in reversed(c): s = s * t + a
    return s

def golden(g, a, b):                   # maximise g on [a, b]
    r = (math.sqrt(5.0) - 1.0) / 2.0
    for _ in range(90):
        c, d = b - r * (b - a), a + r * (b - a)
        if g(c) > g(d): b = d
        else: a = c
    m = (a + b) / 2.0
    return m, g(m)

def extrema(e, N=2000):                # one peak of |e| per run of one sign on [-1, 1]
    ts = [-1.0 + 2.0 * j / N for j in range(N + 1)]; es = [e(t) for t in ts]; runs = []
    for j in range(N + 1):
        if runs and (es[j] > 0) == (es[runs[-1]] > 0):
            if abs(es[j]) > abs(es[runs[-1]]): runs[-1] = j
        else: runs.append(j)
    out = []
    for j in runs:
        if j == 0 or j == N: out.append((ts[j], es[j])); continue
        s = 1.0 if es[j] > 0 else -1.0
        t, v = golden(lambda u: s * e(u), ts[j - 1], ts[j + 1]); out.append((t, s * v))
    return out

def fmap(a, b): return lambda t: math.exp(a + (b - a) * (t + 1.0) / 2.0)

def remez(n, a=0.0, b=1.0, show=False):
    f = fmap(a, b); ref = [-math.cos(i * math.pi / (n + 1)) for i in range(n + 2)]; gap = math.inf
    for it in range(1, 16):
        A = [pows(t, n) + [(-1.0) ** i] for i, t in enumerate(ref)]
        sol = solve(A, [f(t) for t in ref]); c, lev = sol[:n + 1], abs(sol[n + 1])
        ext = extrema(lambda t: f(t) - horner(c, t)); top = max(abs(v) for _, v in ext)
        assert len(ext) == n + 2, "error must have n + 2 alternating peaks"
        if show: print(f"remez degree {n}, round {it}: level {lev:.6e}, max error {top:.6e}, gap {top - lev:.1e}")
        if top - lev <= 1e-6 * top + 4e-15 and top - lev > gap / 4: return c, lev, top, ext  # gap stopped falling
        gap, ref = top - lev, [t for t, _ in ext]

def cheb_interp(n):
    f = fmap(0.0, 1.0); nodes = [math.cos((2 * i + 1) * math.pi / (2 * n + 2)) for i in range(n + 1)]
    c = solve([pows(t, n) for t in nodes], [f(t) for t in nodes])
    ext = extrema(lambda t: f(t) - horner(c, t))
    return c, min(abs(v) for _, v in ext), max(abs(v) for _, v in ext), len(ext)

def bern(f, n, x):                     # B_n f(x), weights grown outward from the middle
    if x <= 0.0 or x >= 1.0: return f(x)
    r, m = x / (1.0 - x), int(n * x); s, tot = 1.0, f(m / n)
    w, k = 1.0, m
    while k < n and w > 1e-18: w *= (n - k) / (k + 1) * r; k += 1; s += w; tot += w * f(k / n)
    w, k = 1.0, m
    while k > 0 and w > 1e-18: w *= k / (n - k + 1) / r; k -= 1; s += w; tot += w * f(k / n)
    return tot / s

def bern_err(n):                       # largest |B_n exp - exp| on [0, 1]
    g = lambda x: abs(bern(math.exp, n, x) - math.exp(x))
    j = max(range(201), key=lambda i: (g(i / 200), -i))
    return golden(g, max(j - 1, 0) / 200, min(j + 1, 200) / 200)

print(f"target: exp on [0, 1], absolute error at most {TOL:.0e}")
tay = [E1 - sum(1.0 / math.factorial(k) for k in range(d + 1)) for d in (6, 8, 9)]
print("taylor at 0, error at x = 1: degree 6 %.4e, degree 8 %.4e, degree 9 %.4e" % tuple(tay))
c6, E6, top6, ext6 = remez(6, show=True)
c5, E5, top5, _ = remez(5)
print(f"minimax error: degree 5 {E5:.6e}, degree 6 {E6:.6e}")
print("degree 6 peaks at x: " + " ".join(f"{(t + 1) / 2:.4f}" for t, _ in ext6))
print("signs: " + " ".join("+" if v > 0 else "-" for _, v in ext6))
ci, lo, hi, npk = cheb_interp(6)
U6 = E1 * 2.0 / 4.0 ** 7 / math.factorial(7)
print(f"chebyshev interpolant, degree 6: {npk} peaks, smallest {lo:.6e}, largest {hi:.6e}, ratio {hi / lo:.4f}")
print(f"so the best error lies in [{lo:.6e}, {hi:.6e}]; a-priori bound e*2/(4^7*7!) = {U6:.6e}, bound/true {U6 / E6:.3f}")
cx = [0.0] * 7; pw = [1.0]             # rewrite p(t) with t = 2x - 1 as coefficients of x
for ck in c6:
    for j, v in enumerate(pw): cx[j] += ck * v
    nw = [0.0] * (len(pw) + 1)
    for j, v in enumerate(pw): nw[j] -= v; nw[j + 1] += 2.0 * v
    pw = nw
print("chip coefficients, x^0..x^6: " + " ".join(f"{v:.10f}" for v in cx))
xmax = max(abs(math.exp(i / 4000) - horner(cx, i / 4000)) for i in range(4001))
print(f"chip form, max error on 4001 points {xmax:.6e}; cost 6 multiplies + 6 adds")
p2 = math.exp(2.0) - horner(cx, 2.0)
print(f"outside the interval: at x = 2 the error is {p2:.4e}")
C = (math.sqrt(5.0) - 2.0) * math.exp((math.sqrt(5.0) - 1.0) / 2.0) / 2.0
print("bernstein n, at x, max error, n*error, bound e/(8n), bound/true")
bt = {}
for n in (10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000):
    bt[n] = bern_err(n)
    if n in (10, 100, 1000, 10000, 100000):
        x, v = bt[n]; print(f"  {n:>6} {x:.4f} {v:.6e} {n * v:.6f} {E1 / 8 / n:.6e} {E1 / 8 / n / v:.3f}")
print(f"limit of n*error: (sqrt5 - 2) e^0.618034 / 2 = {C:.6f}, at x = {(math.sqrt(5.0) - 1.0) / 2.0:.6f}")
nest, nbd = math.ceil(C / TOL), math.ceil(E1 / 8 / TOL)
x_est, v_est = bern_err(nest)
print(f"degree for a millionth: estimate {nest}, guaranteed {nbd}; largest error at {nest}: {v_est:.6e} at x = {x_est:.4f}")
b2 = bern(lambda x: x * x, 10, 0.3)
print(f"identity: B_10(x^2) at 0.3 = {b2:.12f}, x^2 + x(1-x)/n = {0.09 + 0.3 * 0.7 / 10:.12f}")
step = lambda x: 1.0 if x >= 0.5 else 0.0
print("step function, worst error (just left of 0.5), then error at 0.5: " + " ".join(f"n={n} {bern(step, n, 0.5):.4f} {1.0 - bern(step, n, 0.5):.4f}" for n in (10, 100, 1000, 10000)))
for d in (7, 8):
    print(f"try: degree {d} minimax error {remez(d)[1]:.4e}")
print(f"try: on [0, 2], degree 6 {remez(6, 0.0, 2.0)[1]:.4e}, degree 8 {remez(8, 0.0, 2.0)[1]:.4e}")
xs = [i / 20 for i in range(21)]
print("chart, minimax error x 1e8: " + " ".join(f"{1e8 * (math.exp(x) - horner(c6, 2 * x - 1)):.2f}" for x in xs))
print("chart, chebyshev error x 1e8: " + " ".join(f"{1e8 * (math.exp(x) - horner(ci, 2 * x - 1)):.2f}" for x in xs))
print("chart, log10 n: " + " ".join(f"{math.log10(n):.2f}" for n in bt))
print("chart, log10 bernstein error: " + " ".join(f"{math.log10(bt[n][1]):.2f}" for n in bt))
print("chart, log10 bound e/(8n): " + " ".join(f"{math.log10(E1 / 8 / n):.2f}" for n in bt))

assert lo <= E6 <= hi and E6 <= U6, "Remez must land inside the Chebyshev box and under the a-priori bound"
assert abs(top6 - E6) <= 1e-6 * top6 and abs(xmax - E6) < 1e-12, "levelled error = true max error, both forms"
assert E5 > TOL > E6 and tay[1] > TOL > tay[2], "degree 6 is the least minimax degree, 9 the least Taylor degree"
assert abs(b2 - (0.09 + 0.3 * 0.7 / 10)) < 1e-15, "Bernstein's second-moment identity"
assert all(bt[n][1] <= E1 / 8 / n for n in bt) and abs(100000 * bt[100000][1] - C) < 1e-3, "bound and Voronovskaya"
assert v_est < TOL < E1 / 8 / nest, "the estimated degree reaches a millionth; the bound alone cannot promise it"
print("ALL CHECKS PASS")
