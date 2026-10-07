# Efficient frontier and minimum variance -- the check behind the card.  Standard library only.
# Three roads to every frontier portfolio: the closed form (inverse matrix and A, B, C),
# the five Lagrange equations solved directly, and a search that never uses calculus.
from math import sqrt

NAMES = ("shares", "bonds", "gold")
MU = [0.08, 0.04, 0.05]                                   # expected yearly returns
SD = [0.20, 0.06, 0.15]                                   # yearly standard deviations
RHO = {(0, 1): 0.2, (0, 2): 0.1, (1, 2): 0.0}             # shares-bonds, shares-gold, bonds-gold

def cov(sd, rho):
    return [[sd[i] * sd[j] * (1.0 if i == j else rho[(min(i, j), max(i, j))]) for j in range(3)] for i in range(3)]

def solve(M, rhs):                                        # Gauss-Jordan elimination with row swaps
    n = len(rhs)
    a = [list(M[i]) + [rhs[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(a[r][c]))
        a[c], a[p] = a[p], a[c]
        a[c] = [x / a[c][c] for x in a[c]]
        for r in range(n):
            if r != c:
                a[r] = [x - a[r][c] * y for x, y in zip(a[r], a[c])]
    return [a[i][n] for i in range(n)]

def inverse(M):
    cols = [solve(M, [1.0 if i == j else 0.0 for i in range(3)]) for j in range(3)]
    return [[cols[j][i] for j in range(3)] for i in range(3)]

dot = lambda u, v: sum(x * y for x, y in zip(u, v))
mv = lambda M, v: [dot(row, v) for row in M]
var = lambda S, w: dot(w, mv(S, w))

def closed_form(mu, S):                                   # road 1: A, B, C and the frontier formula
    Si = inverse(S)
    u, v = mv(Si, [1.0] * 3), mv(Si, mu)
    A, B, C = sum(u), sum(v), dot(mu, v)
    D = A * C - B * B
    def w(m):
        lam, eta = (C - B * m) / D, (A * m - B) / D
        return [lam * x + eta * y for x, y in zip(u, v)], lam, eta
    return A, B, C, D, [x / A for x in u], w

def kkt(mu, S, m):                                        # road 2: the five Lagrange equations, no inverse
    M = [S[i] + [-1.0, -mu[i]] for i in range(3)] + [[1.0, 1.0, 1.0, 0.0, 0.0], mu + [0.0, 0.0]]
    return solve(M, [0.0, 0.0, 0.0, 1.0, m])[:3]

def golden(f, lo, hi, iters=200):                         # minimise a one-dimensional bowl
    g = (sqrt(5.0) - 1.0) / 2.0
    for _ in range(iters):
        x1, x2 = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(x1) < f(x2): hi = x2
        else: lo = x1
    return (lo + hi) / 2.0

def search(mu, S, m):                                     # road 3: walk the line of weights that hit m
    h = [mu[2] - mu[1], mu[0] - mu[2], mu[1] - mu[0]]     # moves weight without changing total or mean
    ws = (m - mu[1]) / (mu[0] - mu[1])                    # a starting mix: shares and bonds only
    base = [ws, 1.0 - ws, 0.0]
    line = lambda t: [b + t * x for b, x in zip(base, h)]
    return line(golden(lambda t: var(S, line(t)), -1000.0, 1000.0))

S = cov(SD, RHO)
A, B, C, D, wg, wf = closed_form(MU, S)
mg, vg = B / A, 1.0 / A
wg_kkt = kkt(MU, S, mg)
mg_search = golden(lambda m: var(S, search(MU, S, m)), 0.0, 0.2)
wg_search = search(MU, S, mg_search)
w6, lam6, eta6 = wf(0.06)
w6_kkt, w6_search = kkt(MU, S, 0.06), search(MU, S, 0.06)
shift = [a - b for a, b in zip(wf(0.07)[0], wf(0.06)[0])]
V6 = (A * 0.06 ** 2 - 2 * B * 0.06 + C) / D
two_asset = lambda m: sqrt(var(S, [(m - 0.04) / 0.04, 1 - (m - 0.04) / 0.04, 0.0]))

pct = lambda ws: "  ".join(f"{100 * x:8.4f}" for x in ws)
print("inputs: mean% " + " ".join(f"{100 * x:.2f}" for x in MU) + "  sd% " + " ".join(f"{100 * x:.2f}" for x in SD)
      + "  rho " + " ".join(f"{RHO[k]:.2f}" for k in ((0, 1), (0, 2), (1, 2))))
print("covariance matrix, units of percent squared")
for i in range(3): print(f"  {NAMES[i]:<7}" + "".join(f"{1e4 * S[i][j]:10.4f}" for j in range(3)))
(a, b, c), (d, e, f), (g, h, k) = S
det = a * (e * k - f * h) - b * (d * k - f * g) + c * (d * h - e * g)   # expand along the top row
Si = inverse(S)
for i in range(3): print(f"  adjugate {NAMES[i]:<7}" + "".join(f"{det * 1e8 * Si[i][j]:12.4f}" for j in range(3)))
print(f"det {det * 1e12:.4f}  det*inv(S)1 " + "  ".join(f"{det * 1e8 * x:.4f}" for x in mv(Si, [1.0] * 3))
      + "  det*inv(S)mu " + "  ".join(f"{det * 1e10 * x:.4f}" for x in mv(Si, MU)) + "   (percent units)")
print(f"det*A {det * 1e8 * A:.4f}  det*B {det * 1e10 * B:.4f}  det*C {det * 1e12 * C:.4f}")
print(f"A {A * 1e-4:.8f}  B {B * 1e-2:.8f}  C {C:.8f}  Delta {D * 1e-4:.8f}   (percent units)")
print(f"{'GMV road 1 closed form':<30}" + pct(wg))
print(f"{'GMV road 2 Lagrange solve':<30}" + pct(wg_kkt))
print(f"{'GMV road 3 search':<30}" + pct(wg_search))
print(f"GMV mean {100 * mg:.4f}%  variance {1e4 * vg:.4f} pp^2  sd {100 * sqrt(vg):.4f}%  search mean {100 * mg_search:.4f}%")
print("GMV on $10,000 " + "  ".join(f"{NAMES[i]} {1e4 * wg[i]:.2f}" for i in range(3)))
print(f"{'6% road 1 closed form':<30}" + pct(w6))
print(f"{'6% road 2 Lagrange solve':<30}" + pct(w6_kkt))
print(f"{'6% road 3 search':<30}" + pct(w6_search))
print(f"6% lambda {1e4 * lam6:.4f}  eta {100 * eta6:.4f}  variance {1e4 * V6:.4f} pp^2  sd direct {100 * sqrt(var(S, w6)):.4f}%  sd formula {100 * sqrt(V6):.4f}%")
print(f"{'shift per +1 point of target':<30}" + pct(shift))
print("frontier: target%  shares%   bonds%    gold%     sd%   shares+bonds sd%")
for k in range(13):
    m = 0.03 + 0.005 * k
    w = wf(m)[0]
    print(f"  {100 * m:6.2f}  " + "".join(f"{100 * x:9.2f}" for x in w) + f"  {100 * sqrt(var(S, w)):7.2f}  {100 * two_asset(m):7.2f}")

def report(label, w, S=S): print(f"{label:<30}" + pct(w) + f"  mean {100 * dot(MU, w):.4f}%  sd {100 * sqrt(var(S, w)):.4f}%")
Sd = [[S[i][j] if i == j else 0.0 for j in range(3)] for i in range(3)]
report("wrong: ignore correlations", closed_form(MU, Sd)[4])
ts = mv(inverse(S), MU)
report("wrong: normalise inv(S) mu", [x / sum(ts) for x in ts])
w8 = wf(0.08)[0]
clamp = [max(x, 0.0) for x in w8]
wc = [x / sum(clamp) for x in clamp]
report("8% target, true frontier", w8)
report("wrong: clamp shorts at 8%", wc)
report("  frontier at clamped mean", wf(dot(MU, wc))[0])
report("wrong: lower branch 3.5%", wf(0.035)[0])
report("wrong: leave gold out, 6%", [0.5, 0.5, 0.0])
S_neg, S_g30 = cov(SD, {(0, 1): -0.2, (0, 2): 0.1, (1, 2): 0.0}), cov([0.20, 0.06, 0.30], RHO)
report("try: shares-bonds rho -0.2", closed_form(MU, S_neg)[4], S_neg)
report("try: gold sd 30%", closed_form(MU, S_g30)[4], S_g30)
report("try: target 10%", wf(0.10)[0])

assert max(abs(a - b) for a, b in zip(w6, w6_kkt)) < 1e-12,    "closed form vs direct Lagrange solve"
assert max(abs(a - b) for a, b in zip(w6, w6_search)) < 1e-8,  "closed form vs search with no calculus"
assert max(abs(a - b) for a, b in zip(wg, wg_search)) < 1e-6,  "GMV closed form vs two-level search"
assert abs(mg_search - mg) < 1e-7,                             "searched GMV mean vs B/A"
assert abs(var(S, w6_kkt) - V6) < 1e-14,                       "direct variance vs (Am^2-2Bm+C)/Delta"
assert sqrt(vg) < min(SD),                                     "the mix beats the least risky asset"
assert abs(1e4 * vg - 3078000 / 99504) < 1e-9,                "GMV variance vs the hand table, det / (det*A)"
print("ALL CHECKS PASS")
