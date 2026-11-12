# Pade approximants -- the check behind the card.  Only math is imported.
# Example: tan x near a right angle (pi/2 = 1.5708 rad), built from its Taylor series at 0.
# Road 1: Pade [m/n] solved from the Taylor coefficients by linear equations.
# Road 2: Lambert's closed forms, [5/4] = (945x - 105x^3 + x^5)/(945 - 420x^2 + 15x^4).
# Road 3: the defining property, Q*tan - P has no terms below x^(m+n+1).
# Reference values: tan = sin/cos and pi/2 from the math library, labelled as such.
import math

def add(xs):                                    # plain left-to-right sum, as in the Rust
    s = 0.0
    for v in xs: s += v
    return s

def tan_series(N):                              # tan' = 1 + tan^2, matched power by power
    c = [0.0] * (N + 1)
    for n in range(N):
        c[n + 1] = ((1.0 if n == 0 else 0.0) + add(c[i] * c[n - i] for i in range(n + 1))) / (n + 1)
    return c

def solve(A, b):                                # Gaussian elimination, partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(M[i][k])); M[k], M[p] = M[p], M[k]
        for i in range(k + 1, n):
            f = M[i][k] / M[k][k]
            for j in range(k, n + 1): M[i][j] -= f * M[k][j]
    x = [0.0] * n
    for k in range(n - 1, -1, -1):
        x[k] = (M[k][n] - add(M[k][j] * x[j] for j in range(k + 1, n))) / M[k][k]
    return x

def pade(c, m, n, sign=1.0):                    # returns P (degree m) and Q (degree n, Q(0) = 1)
    A = [[c[k - j] if k >= j else 0.0 for j in range(1, n + 1)] for k in range(m + 1, m + n + 1)]
    q = [1.0] + solve(A, [-sign * c[k] for k in range(m + 1, m + n + 1)])
    p = [add(q[j] * c[k - j] for j in range(min(k, n) + 1)) for k in range(m + 1)]
    return p, q

def ev(a, x):                                   # Horner
    s = 0.0
    for v in reversed(a): s = s * x + v
    return s

def rat(pq, x): return ev(pq[0], x) / ev(pq[1], x)

def root(f, lo, hi):                            # bisection on a sign change
    assert f(lo) * f(hi) < 0
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if f(lo) * f(mid) <= 0: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)

def sci(v): return f"{v:.3e}"
X, H = 1.5, math.pi / 2
T = math.sin(X) / math.cos(X)                   # library reference
c = tan_series(260)
print("tan coefficients c1..c9: " + ", ".join(f"{c[k]:.12f}" for k in (1, 3, 5, 7, 9)))
exact = {1: 1 / 1, 3: 1 / 3, 5: 2 / 15, 7: 17 / 315, 9: 62 / 2835}
assert max(abs(c[k] - v) for k, v in exact.items()) < 1e-15
print(f"x = {X} rad ({math.degrees(X):.2f} degrees); reference tan x = {T:.10f}; pole pi/2 = {H:.10f}")
print("  N  Taylor deg N   Pade [m/n]   value       |Taylor err|  |Pade err|   pole")
rows = []
for N in (3, 5, 7, 9, 11, 13):
    n = 2 * ((N + 1) // 4); m = N - n
    pq = pade(c, m, n); ts = ev(c[:N + 1], X); pv = rat(pq, X)
    pole = root(lambda x: ev(pq[1], x), 1.0, 2.0)
    rows.append((N, ts, pv, pole, pq))
    print(f"{N:3d}  {ts:11.6f}   [{m}/{n}]       {pv:10.6f}  {sci(abs(ts - T)):>11}  {sci(abs(pv - T)):>10}  {pole:.7f}")
assert all(abs(r[2] - T) < abs(r[1] - T) for r in rows) and abs(rows[3][1] - T) > 5000 * abs(rows[3][2] - T)
assert all(abs(b[3] - H) < abs(a[3] - H) for a, b in zip(rows, rows[1:]))  # poles close in on pi/2
p54, q54 = rows[3][4]
print("[5/4] times 945, x^1 x^3 x^5 on top: " + ", ".join(f"{945 * p54[k]:.9f}" for k in (1, 3, 5))
      + "; x^0 x^2 x^4 below: " + ", ".join(f"{945 * q54[k]:.9f}" for k in (0, 2, 4)))
lam = lambda x: (945 * x - 105 * x ** 3 + x ** 5) / (945 - 420 * x ** 2 + 15 * x ** 4)
assert max(abs(945 * a - b) for a, b in zip(p54 + q54, [0, 945, 0, -105, 0, 1, 945, 0, -420, 0, 15])) < 1e-9
assert abs(lam(X) - rows[3][2]) < 1e-11
r = [add(q54[j] * c[k - j] for j in range(min(k, 4) + 1)) - (p54[k] if k <= 5 else 0.0) for k in range(12)]
print(f"Q*tan - P, terms x^0..x^9: max size {sci(max(abs(v) for v in r[:10]))}; x^11 term {sci(r[11])}")
assert max(abs(v) for v in r[:10]) < 1e-15 and abs(r[11]) > 1e-8
det = c[5] * c[5] - c[3] * c[7]
print(f"determinant c5^2 - c3 c7 = {det:.12f} (exact -1/4725 = {-1 / 4725:.12f})")
assert abs(det + 1 / 4725) < 1e-15
print(f"hand: q2 {q54[2]:.9f}, q4 {q54[4]:.9f}, p3 {p54[3]:.9f}, p5 {p54[5]:.9f}; c3 c9 - c5 c7 = {c[3] * c[9] - c[5] * c[7]:.12f}")
tt, bb = [945 * X, -105 * X ** 3, X ** 5], [945.0, -420 * X ** 2, 15 * X ** 4]
print("hand at 1.5: top " + " + ".join(f"{v:.5f}" for v in tt) + f" = {add(tt):.5f}; bottom "
      + " + ".join(f"{v:.4f}" for v in bb) + f" = {add(bb):.4f}; ratio {add(tt) / add(bb):.6f}")
res = ev(p54, rows[3][3]) / ev([k * v for k, v in enumerate(q54)][1:], rows[3][3])
print(f"[5/4] residue at its pole: {res:.9f} (tan's residue at pi/2 is -1)")
assert abs(res + 1) < 1e-4
e54 = abs(rows[3][2] - T); K = 1
while K < 130 and abs(ev(c[:2 * K], X) - T) >= e54: K += 1
print(f"Taylor terms to beat [5/4] at x = 1.5: {K} (degree {2 * K - 1}); flops about {2 * K} vs 10; term ratio (x/(pi/2))^2 = {(X / H) ** 2:.4f}")
assert 80 < K < 130
est, tru = rows[3][2] - rows[2][2], T - rows[2][2]
print(f"estimate of [3/4]'s error, [5/4] - [3/4]: {est:.6f}; true {tru:.6f}; ratio {est / tru:.4f}")
print("row [m/2], m = 1, 3, 5, 7, 9; error at 1.5 and ratio per step (theory (1.5/(3pi/2))^2 = "
      f"{(X / (3 * H)) ** 2:.4f}; 3pi/2 = {3 * H:.4f}):")
er = [abs(rat(pade(c, m, 2), X) - T) for m in (1, 3, 5, 7, 9)]
print("  " + ", ".join(sci(v) for v in er) + "; ratios " + ", ".join(f"{b / a:.4f}" for a, b in zip(er, er[1:])))
assert abs(er[4] / er[3] - (X / (3 * H)) ** 2) < 0.02
T2 = math.sin(2.0) / math.cos(2.0)
t5, t50 = ev(c[:10], 2.0), ev(c[:100], 2.0)
print(f"past the pole, x = 2: tan {T2:.6f}; [5/4] {lam(2.0):.6f}; Taylor deg 9 {t5:.6f}; deg 99 {sci(t50)}")
assert abs(rat(rows[3][4], 2.0) - T2) < 1e-3 and t50 > 1e6
bad = rat(pade(c, 5, 4, -1.0), X)
print(f"mistake, sign slip in the denominator equations: [5/4] at 1.5 = {bad:.6f}")
assert abs(bad - T) > 5
e = [1.0 / math.factorial(k) for k in range(8)]
s03 = pade(e, 0, 3); sp = root(lambda x: ev(s03[1], x), 1.0, 2.0)
print(f"spurious pole: [0/3] of e^x at 1.5 = {rat(s03, X):.6f} vs e^1.5 = {math.exp(X):.6f}; pole at {sp:.6f}")
assert abs(rat(s03, X) - 16.0) < 1e-12 and abs(ev(s03[1], sp)) < 1e-12
d = [(-1.0) ** k / math.factorial(k) for k in range(5)]
for m in (1, 2):
    p, q = pade(d, m, m)
    print(f"delay e^-x [{m}/{m}]: P = " + ", ".join(f"{v:.6f}" for v in p) + "; Q = " + ", ".join(f"{v:.6f}" for v in q))
assert abs(pade(d, 2, 2)[1][2] - 1 / 12) < 1e-15
for x in (1.57, 3.0):                           # Try changing: nearer the pole, and far past it
    print(f"try: x = {x:.2f}, tan {math.sin(x) / math.cos(x):.6f}; [5/4] {rat(rows[3][4], x):.6f}; [7/6] {rat(rows[5][4], x):.6f}; Taylor deg 13 {ev(c[:14], x):.6f}")
xs = [0.1 * k for k in range(16)]
print("chart, x: " + ", ".join(f"{x:.1f}" for x in xs))
print("chart, tan: " + ", ".join(f"{math.sin(x) / math.cos(x):.2f}" for x in xs))
print("chart, Taylor deg 9: " + ", ".join(f"{ev(c[:10], x):.2f}" for x in xs))
print("chart, Pade [5/4]: " + ", ".join(f"{rat(rows[3][4], x):.2f}" for x in xs))
print("chart, log10 err Taylor: " + ", ".join(f"{math.log10(abs(r[1] - T)):.2f}" for r in rows))
print("chart, log10 err Pade: " + ", ".join(f"{math.log10(abs(r[2] - T)):.2f}" for r in rows))
print("ALL CHECKS PASS")
