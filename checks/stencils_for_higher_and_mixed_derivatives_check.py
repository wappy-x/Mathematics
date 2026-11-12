# Stencils to order -- the check behind the card.  Standard library only.
# Weights come from solving the Taylor conditions in exact fractions, and again
# from differentiating Lagrange's polynomial.  The bond's slopes come from its
# cash flows in closed form.  Discounting is (1 + r)^-t by repeated division,
# so Python and Rust do the same +, -, x, / and print the same digits.
from fractions import Fraction as Q
from math import factorial, log2, log10

def add(xs):  # plain left-to-right sum: Python's sum() compensates floats, Rust's does not
    t = 0.0
    for x in xs: t += x
    return t

def e(x, d):  # e-notation the way Rust prints it: -1.707e-3, not -1.707e-03
    m, p = f"{x:.{d}e}".split("e"); return f"{m}e{int(p)}"

def solve(M, rhs):  # Gauss-Jordan elimination on exact fractions
    n = len(M); A = [row[:] + [b] for row, b in zip(M, rhs)]
    for c in range(n):
        p = next(r for r in range(c, n) if A[r][c] != 0); A[c], A[p] = A[p], A[c]
        A[c] = [v / A[c][c] for v in A[c]]
        for r in range(n):
            if r != c and A[r][c] != 0: A[r] = [x - A[r][c] * y for x, y in zip(A[r], A[c])]
    return [A[r][n] for r in range(n)]

def weights(s, k):  # undetermined coefficients: sum_j c_j s_j^m = k! if m == k else 0
    return solve([[Q(x) ** m for x in s] for m in range(len(s))], [Q(factorial(k) if m == k else 0) for m in range(len(s))])

def lagrange(s, k):  # road two: k! times the x^k coefficient of each basis polynomial
    out = []
    for j, sj in enumerate(s):
        poly, den = [Q(1)], 1
        for i, si in enumerate(s):
            if i != j:
                poly = [(poly[m - 1] if m else 0) - si * (poly[m] if m < len(poly) else 0) for m in range(len(poly) + 1)]
                den *= sj - si
        out.append(poly[k] * factorial(k) / den)
    return out

def err_term(s, c):  # first moment the stencil gets wrong: error = E h^(m-k) f^(m)
    for m in range(len(s), len(s) + 3):
        E = sum(cj * Q(x) ** m for cj, x in zip(c, s)) / factorial(m)
        if E != 0: return m, E

YEARS, CPN, FACE, R0, BP = 30, 400_000.0, 10_000_000.0, 0.045, 1e-4
def cash(t): return CPN + (FACE if t == YEARS else 0.0)
def disc(r, t):  # (1 + r)^-t by repeated division
    d = 1.0
    for _ in range(t): d /= 1.0 + r
    return d
def price(a, b):  # short end moved a bp, 30-year end b bp, zero rate straight between
    return add(cash(t) * disc(R0 + (a + (b - a) * t / YEARS) * BP, t) for t in range(1, YEARS + 1))
def exact(m, n):  # d^(m+n) P / da^m db^n in $ per bp^(m+n), from the cash flows
    tot = 0.0
    for t in range(1, YEARS + 1):
        wa, wb = 1 - t / YEARS, t / YEARS; g = 1.0
        for i in range(m + n): g *= -(t + i) / (1 + R0) * BP
        tot += cash(t) * disc(R0, t) * g * wa ** m * wb ** n
    return tot
def par(k):  # k-th slope for a parallel move: binomial sum of the partial slopes
    return add(factorial(k) // (factorial(m) * factorial(k - m)) * exact(m, k - m) for m in range(k + 1))
def f(x): return price(x, x)  # the position after every rate moves x bp
def apply(s, c, k, h): return add(float(cj) * f(x * h) for cj, x in zip(c, s)) / h ** k
def fr(c): return " ".join(str(x) for x in c)
S3, S5 = [-1, 0, 1], [-2, -1, 0, 1, 2]
SL3, SL5, CU3, CU5 = weights(S3, 1), weights(S5, 1), weights(S3, 2), weights(S5, 2)
P0, P1, P2 = f(0), par(1), par(2)
print("$10m face, 4% annual coupon, 30 years, every zero rate 4.50%; moves in bp")
print(f"value {P0:.2f}; slope {P1:.6f} $/bp; curvature {P2:.6f} $/bp^2")
print(f"100 bp rise: slope alone {P1 * 100:.2f}, curvature adds {P2 * 100 ** 2 / 2:.2f}, true change {f(100) - P0:.2f}")
for name, s, k, c in (("slope, 3 points", S3, 1, SL3), ("slope, 5 points", S5, 1, SL5),
                      ("curvature, 3 points", S3, 2, CU3), ("curvature, 5 points", S5, 2, CU5)):
    m, E = err_term(s, c)
    assert c == lagrange(s, k)  # two unrelated algorithms give the same fractions
    print(f"{name:<20} weights {fr(c)}; error {E} h^{m - k} f^({m})")
assert CU5 == [Q(-1, 12), Q(4, 3), Q(-5, 2), Q(4, 3), Q(-1, 12)] and err_term(S5, SL5) == (5, Q(-1, 30))
print("at h = 1 bp, true error of each stencil, then the predicted leading term:")
for name, s, k, c, tru in (("slope 3", S3, 1, SL3, P1), ("slope 5", S5, 1, SL5, P1),
                           ("curvature 3", S3, 2, CU3, P2), ("curvature 5", S5, 2, CU5, P2)):
    m, E = err_term(s, c)
    print(f"  {name:<12} {e(apply(s, c, k, 1) - tru, 3):>10}   predicted {e(float(E) * par(m), 3):>10}")
fl = 2 ** -53 * P0 * add(float(abs(c)) for c in CU5)
print(f"  rounding estimate for curvature 5 at 1 bp: u x value x sum|w| / h^2 = {e(fl, 2)}")
r5 = abs(apply(S5, CU5, 2, 1) - P2); assert fl / 10 < r5 < 10 * fl and r5 > 10 * abs(float(Q(-1, 90)) * par(6))
print("curvature errors, h = 50, 25, 12.5, 6.25 bp:")
HS = (50, 25, 12.5, 6.25)
e3 = [apply(S3, CU3, 2, hb) - P2 for hb in HS]; e5 = [apply(S5, CU5, 2, hb) - P2 for hb in HS]
o3 = [log2(e3[i] / e3[i + 1]) for i in range(3)]; o5 = [log2(e5[i] / e5[i + 1]) for i in range(3)]
print("  3 points: " + ", ".join(e(v, 4) for v in e3) + "; orders " + ", ".join(f"{o:.2f}" for o in o3))
print("  5 points: " + ", ".join(e(v, 4) for v in e5) + "; orders " + ", ".join(f"{o:.2f}" for o in o5))
assert all(abs(o - 2) < 0.02 for o in o3) and all(abs(o - 4) < 0.05 for o in o5)
lead = float(Q(-1, 90)) * 25 ** 4 * par(6)
print(f"  at 25 bp: leading term {e(lead, 4)}, true over predicted {e5[1] / lead:.4f}")
n3 = add(float(c) * f(x * 25) for c, x in zip(CU3, S3)); n5 = add(float(12 * c) * f(x * 25) for c, x in zip(CU5, S5))
print("values at -50, -25, 0, +25, +50 bp: " + ", ".join(f"{f(x * 25):.4f}" for x in S5))
print(f"  1 -2 1 sum {n3:.4f}, / 25^2 = {n3 / 625:.6f}; -1 16 -30 16 -1 sum {n5:.4f}, / (12 x 25^2) = {n5 / 7500:.6f}")
print("chart, log10 h in bp: " + ", ".join(f"{log10(hb):.2f}" for hb in HS))
print("chart, log10 |error| 3 points: " + ", ".join(f"{log10(abs(v)):.2f}" for v in e3))
print("chart, log10 |error| 5 points: " + ", ".join(f"{log10(abs(v)):.2f}" for v in e5))
# --- the mixed derivative: four corner points (x, y), solved for d^2/dx dy ---
C4 = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
MON = [(0, 0), (1, 0), (0, 1), (1, 1)]  # monomials 1, x, y, xy
CX = solve([[Q(x) ** p * Q(y) ** q for x, y in C4] for p, q in MON], [Q(1 if (p, q) == (1, 1) else 0) for p, q in MON])
prod = [Q(x, 2) * Q(y, 2) for x, y in C4]  # road two: central slope in x times central slope in y
def mom(p, q): return sum(c * Q(x) ** p * Q(y) ** q for c, (x, y) in zip(CX, C4)) / (factorial(p) * factorial(q))
print(f"cross weights at (+,+) (+,-) (-,+) (-,-): {fr(CX)}; product of two slopes: {fr(prod)}")
print(f"cross moments: x^2 {mom(2, 0)}, y^2 {mom(0, 2)}, x^3 y {mom(3, 1)}, x y^3 {mom(1, 3)}, x^2 y^2 {mom(2, 2)}")
assert CX == prod and mom(2, 0) == 0 and mom(3, 1) == Q(1, 6)
X11, X31 = exact(1, 1), exact(3, 1) + exact(1, 3)
def cross(h): return add(float(c) * price(x * h, y * h) for c, (x, y) in zip(CX, C4)) / (h * h)
pc = [price(x, y) for x, y in C4]
print("cross values at (+,+) (+,-) (-,+) (-,-), 1 bp: " + ", ".join(f"{v:.4f}" for v in pc))
print(f"  ++ - +- - -+ + -- = {pc[0] - pc[1] - pc[2] + pc[3]:.6f}")
for hb in (1, 25):
    v = cross(hb)
    print(f"cross term, h = {hb} bp: stencil {v:.6f}, exact {X11:.6f}, error {e(v - X11, 4)}, predicted {e(hb * hb / 6 * X31, 4)}")
assert abs(cross(1) - X11) < 1e-4 and abs((cross(25) - X11) / (625 / 6 * X31) - 1) < 0.01
print(f"slopes: short end {exact(1, 0):.4f}, 30-year end {exact(0, 1):.4f}; own curvatures {exact(2, 0):.6f}, {exact(0, 2):.6f}")
print(f"30-year end up 1 bp: short-end slope {exact(1, 0):.4f} becomes {exact(1, 0) + X11:.4f}")
# --- unequal spacing: scenarios stored at -10 bp, 0 and +25 bp ---
SU = [-10, 0, 25]; CU = weights(SU, 2); mU, EU = err_term(SU, CU)
vU = apply(SU, CU, 2, 1); predU = float(EU) * par(mU)
print(f"uneven {', '.join(map(str, SU))} bp: weights {fr(CU)}; error {EU} f^({mU})")
print(f"  curvature {vU:.6f}, error {vU - P2:.6f}, predicted {predU:.6f}")
S4 = [-10, 0, 25, 50]; C4U = weights(S4, 2); v4 = apply(S4, C4U, 2, 1); m4, E4 = err_term(S4, C4U)
print(f"  add +50 bp: weights {fr(C4U)}; error {E4} f^(4)")
print(f"  curvature {v4:.6f}, error {v4 - P2:.6f}, predicted {float(E4) * par(4):.6f}")
assert CU == lagrange(SU, 2) and abs((vU - P2) / predU - 1) < 0.05 and abs(v4 - P2) < abs(vU - P2) / 5
# --- what breaks ---
naive = (f(25) - 2 * P0 + f(-10)) / 17.5 ** 2
both = (f(1) - 2 * P0 + f(-1)) / 4
one = price(1, 1) - price(1, 0) - price(0, 1) + P0
pone = (exact(2, 1) + exact(1, 2)) / 2
print(f"mistake, 1 -2 1 on -10/+25 with h = 17.5 bp: {naive:.4f}")
print(f"mistake, both ends moved together, over 4 h^2: {both:.6f}; (P_aa + 2 P_ab + P_bb) / 4 = {P2 / 4:.6f}")
print(f"mistake, one-sided cross from up moves only: {one:.6f}, error {one - X11:.6f}, predicted {pone:.6f}")
assert abs(both - P2 / 4) < 1e-4 and naive < 0 and abs((one - X11) / pone - 1) < 0.02
print("figure, five points at x " + " ".join(str(180 + 60 * x) for x in S5) + "; uneven at x "
      + " ".join(str(160 + 6 * x) for x in SU) + "; cross corners at x 150 210, y 168 228")
print("ALL CHECKS PASS")
