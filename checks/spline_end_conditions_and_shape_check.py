# Spline end conditions and a monotone scheme -- the check behind the card.  Standard library only.
# Every scheme is a Hermite cubic on each gap; the schemes differ only in the slopes s_i at the knots.
import math

T = [1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 10.0, 15.0]        # maturities, years
Y = [3.50, 3.50, 3.55, 4.25, 4.50, 4.55, 4.60, 4.60]  # forward rates, % a year (illustrative)

def solve(A, b):  # Gaussian elimination with partial pivoting
    n = len(b); A = [r[:] for r in A]; b = b[:]
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(A[i][k]))  # first row with the largest pivot
        A[k], A[p] = A[p], A[k]; b[k], b[p] = b[p], b[k]
        for i in range(k + 1, n):
            m = A[i][k] / A[k][k]
            for j in range(k, n): A[i][j] -= m * A[k][j]
            b[i] -= m * b[k]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        acc = b[i]
        for j in range(i + 1, n): acc -= A[i][j] * x[j]
        x[i] = acc / A[i][i]
    return x

def gaps(t, y):
    h = [t[i + 1] - t[i] for i in range(len(t) - 1)]
    return h, [(y[i + 1] - y[i]) / h[i] for i in range(len(h))], len(h)

def road1(t, y, end, a=0.0, b=0.0):  # unknowns: the slopes; interior rows: S'' continuous
    h, d, n = gaps(t, y); A = [[0.0] * (n + 1) for _ in range(n + 1)]; r = [0.0] * (n + 1)
    for i in range(1, n):
        A[i][i - 1], A[i][i], A[i][i + 1] = h[i], 2 * (h[i - 1] + h[i]), h[i - 1]
        r[i] = 3 * (h[i] * d[i - 1] + h[i - 1] * d[i])
    for (e, f, g, k, j) in ((0, 1, 2, 0, 1), (n, n - 1, n - 2, n - 1, n - 2)):
        if end == "natural": A[e][e], A[e][f], r[e] = 2.0, 1.0, 3 * d[k]
        elif end == "clamped": A[e][e], r[e] = 1.0, (a if e == 0 else b)
        else:  # not-a-knot: S''' equal on the two end gaps
            q, u = 1 / (h[k] * h[k]), 1 / (h[j] * h[j])
            A[e][e], A[e][f], A[e][g], r[e] = q, q - u, -u, 2 * d[k] * q - 2 * d[j] * u
    return solve(A, r)

def road2(t, y, end, a=0.0, b=0.0):  # unknowns: second derivatives M; interior rows: S' continuous
    h, d, n = gaps(t, y); A = [[0.0] * (n + 1) for _ in range(n + 1)]; r = [0.0] * (n + 1)
    for i in range(1, n):
        A[i][i - 1], A[i][i], A[i][i + 1], r[i] = h[i - 1], 2 * (h[i - 1] + h[i]), h[i], 6 * (d[i] - d[i - 1])
    if end == "natural": A[0][0] = A[n][n] = 1.0
    elif end == "clamped":
        A[0][0], A[0][1], r[0] = 2 * h[0], h[0], 6 * (d[0] - a)
        A[n][n - 1], A[n][n], r[n] = h[n - 1], 2 * h[n - 1], 6 * (b - d[n - 1])
    else:
        A[0][0], A[0][1], A[0][2] = h[1], -(h[0] + h[1]), h[0]
        A[n][n - 2], A[n][n - 1], A[n][n] = h[n - 1], -(h[n - 2] + h[n - 1]), h[n - 2]
    M = solve(A, r)
    return [d[i] - h[i] * (2 * M[i] + M[i + 1]) / 6 for i in range(n)] + [d[n - 1] + h[n - 1] * (M[n - 1] + 2 * M[n]) / 6]

def monotone(t, y, limit=True):  # weighted harmonic mean; limit=False gives plain averages
    h, d, n = gaps(t, y); s = [0.0] * (n + 1)
    for i in range(1, n):
        if not limit: s[i] = (d[i - 1] + d[i]) / 2
        elif d[i - 1] * d[i] > 0:
            w1, w2 = 2 * h[i] + h[i - 1], h[i] + 2 * h[i - 1]
            s[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i])
    for (e, k, j) in ((0, 0, 1), (n, n - 1, n - 2)):
        v = ((2 * h[k] + h[j]) * d[k] - h[k] * d[j]) / (h[k] + h[j])
        if v * d[k] <= 0: v = 0.0
        elif d[k] * d[j] <= 0 and abs(v) > abs(3 * d[k]): v = 3 * d[k]
        s[e] = v if limit else d[k]
    return s

def S(t, y, s, x, der=0):  # the Hermite cubic, or its second derivative
    i = 0
    while i < len(t) - 2 and x > t[i + 1]: i += 1
    h = t[i + 1] - t[i]; p = (x - t[i]) / h; p2 = p * p; p3 = p2 * p
    if der == 0: return y[i] * (2*p3 - 3*p2 + 1) + h * s[i] * (p3 - 2*p2 + p) + y[i+1] * (3*p2 - 2*p3) + h * s[i+1] * (p3 - p2)
    return (y[i] * (12*p - 6) + h * s[i] * (6*p - 4) + y[i+1] * (6 - 12*p) + h * s[i+1] * (6*p - 2)) / (h * h)

def low_by_roots(t, y, s, i):  # S' is a quadratic in p: test its roots inside the gap and the two ends
    h = t[i + 1] - t[i]; dl = (y[i + 1] - y[i]) / h
    qa, qb, qc = 3 * s[i] + 3 * s[i + 1] - 6 * dl, 6 * dl - 4 * s[i] - 2 * s[i + 1], s[i]
    ps = [-qc / qb] if qa == 0 and qb != 0 else []
    if qa != 0 and qb * qb - 4 * qa * qc >= 0:
        r = math.sqrt(qb * qb - 4 * qa * qc); ps = [(-qb - r) / (2 * qa), (-qb + r) / (2 * qa)]
    return min([y[i], y[i + 1]] + [S(t, y, s, t[i] + h * p) for p in ps if 0 < p < 1])

ends, d1 = ("natural", "clamped", "not-a-knot"), Y[2] - Y[1]
SL = {e: road1(T, Y, e) for e in ends}; SL["monotone"] = monotone(T, Y)
print("quotes:", " ".join("%gy %.2f" % (a, b) for a, b in zip(T, Y)), "| gap slopes:", " ".join("%.4f" % v for v in gaps(T, Y)[1]))
for k, s in SL.items(): print("%-10s slopes" % k, " ".join("%+.4f" % v for v in s))
gap = max(max(abs(u - v) for u, v in zip(SL[e], road2(T, Y, e))) for e in ends)
print("road 2 (second derivatives) against road 1 (slopes), largest slope difference: %.1e" % gap); assert gap < 1e-12
for k, s in SL.items():
    g, r = min(S(T, Y, s, 2 + k2 / 4000) for k2 in range(4001)), low_by_roots(T, Y, s, 1)
    print("%-10s lowest on 2y-3y: %.4f%% by roots, %.4f%% on a grid, %+.2f bp against 3.50" % (k, r, g, (r - Y[1]) * 100))
    assert abs(g - r) < 1e-6 and (r < Y[1] - 0.03 if k != "monotone" else r >= Y[1] - 1e-12)
for k in ("natural", "monotone"):
    s = SL[k]; print("%-10s 2y-3y: delta %.4f, s(2y) %+.4f, s(3y) %+.4f, alpha %+.4f, beta %+.4f, S(2.35) %.4f"
                     % (k, d1, s[1], s[2], s[1] / d1, s[2] / d1, S(T, Y, s, 2.35)))
V = {k: [S(T, Y, s, 1 + j / 1000) for j in range(14001)] for k, s in SL.items()}; over = {k: max(v) - Y[-1] for k, v in V.items()}
print("highest point above the 4.60 top quote, bp:", " ".join("%s %+.2f" % (k, v * 100) for k, v in over.items()))
assert over["monotone"] <= 1e-12 and over["not-a-knot"] > 0.01 and min(b - a for a, b in zip(V["monotone"], V["monotone"][1:])) > -1e-12
for k in ("natural", "not-a-knot", "monotone"):
    print("chart, %s:" % k, ", ".join("%.4f" % S(T, Y, SL[k], 1 + 0.125 * j) for j in range(17)))
bump = Y[:3] + [Y[3] + 0.01] + Y[4:]
for k, fn in (("natural", lambda y: road1(T, y, "natural")), ("monotone", lambda y: monotone(T, y))):
    ch = [(S(T, bump, fn(bump), x) - S(T, Y, fn(Y), x)) * 100 for x in (1.5, 12.5)]
    print("%-10s 4y quote +1 bp moves 1.5y by %+.4f bp, 12.5y by %+.4f bp" % (k, ch[0], ch[1]))
    assert (ch[0] == 0.0 and ch[1] == 0.0) if k == "monotone" else min(abs(ch[0]), abs(ch[1])) > 1e-3
jm, jn = [S(T[3:], Y[3:], SL[k][3:], 4.0, 2) - S(T[:4], Y[:4], SL[k][:4], 4.0, 2) for k in ("monotone", "natural")]
print("jump in S'' at 4y, %% a year per year squared: monotone %+.4f, natural spline %.1e" % (jm, abs(jn))); assert abs(jm) > 0.1 and abs(jn) < 1e-12
print("flops at n = 7: natural spline rows 9n - 4 = %d, Thomas sweep 8n + 1 = %d, total %d; monotone at most 13n + 10 = %d" % (9 * 7 - 4, 8 * 7 + 1, 17 * 7 - 3, 13 * 7 + 10))
# Errors against a known smooth forward curve f(t) = 4.60 - 1.10 exp(-(t - 1)/4), 1y to 15y
f = lambda x: 4.60 - 1.10 * math.exp(-(x - 1) / 4); fp = lambda x: 0.275 * math.exp(-(x - 1) / 4)
cub = lambda x: 3.0 + 0.3 * x - 0.03 * x * x + 0.001 * x * x * x; cubp = lambda x: 0.3 - 0.06 * x + 0.003 * x * x
def err(t, g, s):
    pts = [t[i] + (t[i + 1] - t[i]) * k / 10 for i in range(len(t) - 1) for k in range(1, 10)]
    return max(abs(S(t, [g(v) for v in t], s, x) - g(x)) for x in pts)
def schemes(t, g, gp):
    y = [g(v) for v in t]
    return {"natural": road1(t, y, "natural"), "clamped": road1(t, y, "clamped", gp(t[0]), gp(t[-1])),
            "not-a-knot": road1(t, y, "not-a-knot"), "monotone": monotone(t, y), "flat ends": road1(t, y, "clamped")}
E = {}; print("n    h       natural    clamped    not-a-knot monotone   flat ends  clamped bound")
for n in (7, 14, 28, 56, 112):
    t = [1 + 14 * i / n for i in range(n + 1)]; E[n] = {k: err(t, f, s) for k, s in schemes(t, f, fp).items()}
    bound = 5 / 384 * (14 / n) ** 4 * 1.10 / 256
    print("%-4d %-7.4f" % (n, 14 / n), " ".join("%.3e " % v for v in E[n].values()), "%.3e" % bound)
    assert E[n]["clamped"] <= bound
print("bound / true error, clamped, n = 112: %.2f" % (bound / E[112]["clamped"]))
order = {k: math.log2(E[56][k] / E[112][k]) for k in E[112]}
print("observed order, n 56 to 112:", " ".join("%s %.2f" % kv for kv in order.items()))
for k in ("natural", "not-a-knot", "monotone"):
    print("chart, log10 error, %s:" % k, ", ".join("%.2f" % math.log10(E[n][k]) for n in E))
assert abs(order["natural"] - 2) < 0.2 and abs(order["clamped"] - 4) < 0.2 and abs(order["not-a-knot"] - 4) < 0.2
assert abs(order["monotone"] - 3) < 0.3 and abs(order["flat ends"] - 1) < 0.2
cs = schemes(T, cub, cubp); ce = {k: err(T, cub, cs[k]) for k in ends}
print("a cubic through the 8 maturities, largest error:", " ".join("%s %.1e" % kv for kv in ce.items()))
assert ce["clamped"] < 1e-12 and ce["not-a-knot"] < 1e-12 and ce["natural"] > 1e-3
avg = monotone(T, Y, limit=False); la = low_by_roots(T, Y, avg, 1)
print("plain average slopes: s(3y) %+.4f, beta %.2f, lowest on 2y-3y %.4f%%, %+.2f bp" % (avg[2], avg[2] / d1, la, (la - Y[1]) * 100))
assert la < Y[1] - 0.001
assert abs(SL["monotone"][4] - 0.05) < 1e-12  # by hand at 5y, gaps 1 and 2: 9/(5/0.25 + 4/0.025)
print("ALL CHECKS PASS")
