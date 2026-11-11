# Lagrange multipliers, proved -- the check behind the card.  Standard library only.
# Pumps feed one water main.  Choose the flows x_i (L/s) to MINIMISE the power drawn,
# f(x) = sum a_i x_i^2 (kW), subject to equality rules g_j(x) = b_j.
# Road 1 solves the Lagrange equations grad f = sum lam_j grad g_j, g = b, by elimination.
# Road 2 walks the allowed plans with no multiplier and searches them.
# Road 3 loosens each rule, re-solves, and reads the price off the change in cost.
A, K, KWH = [0.02, 0.03, 0.05], [0.1, 0.2, 0.4], 0.20   # kW per (L/s)^2; m per L/s; pounds per kWh

def gauss(M, r):                         # solve M z = r by elimination with row swaps
    n = len(r)
    M = [list(row) + [v] for row, v in zip(M, r)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(M[i][c]))
        if abs(M[p][c]) < 1e-12:
            return None                  # singular: no unique solution
        M[c], M[p] = M[p], M[c]
        for i in range(n):
            if i != c:
                m = M[i][c] / M[c][c]
                M[i] = [u - m * v for u, v in zip(M[i], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def lagrange(a, G, b):                   # unknowns x_1..x_n, then lam_1..lam_m
    n, m = len(a), len(G)
    M = [[2 * a[i] if j == i else 0 for j in range(n)] + [-G[j][i] for j in range(m)] for i in range(n)]
    M += [list(G[j]) + [0] * m for j in range(m)]
    return gauss(M, [0] * n + list(b))

cost = lambda a, x: sum(ai * xi * xi for ai, xi in zip(a, x))
dot = lambda u, v: sum(p * q for p, q in zip(u, v))
f4 = lambda v: ", ".join(f"{round(u, 9) + 0.0:.4f}" for u in v)   # + 0.0 turns -0 into 0
def resid(a, x, G, lam):                 # size of grad f - sum lam_j grad g_j
    r = [2 * a[i] * x[i] - sum(l * g[i] for l, g in zip(lam, G)) for i in range(len(x))]
    return dot(r, r) ** 0.5

# ---- two pumps, 100 L/s in total: the one-rule case ----
x1, x2, lam = lagrange(A[:2], [[1, 1]], [100])
scan = min(range(101), key=lambda q: cost(A[:2], [q, 100 - q]))
print(f"two pumps: flows {f4([x1, x2])} L/s, marginal costs {f4([2 * A[0] * x1, 2 * A[1] * x2])} kW per L/s")
print(f"two pumps: lambda {lam:.4f} kW per L/s, power {cost(A[:2], [x1, x2]):.4f} kW, {KWH * cost(A[:2], [x1, x2]):.4f} pounds per hour")
print(f"two pumps: integer scan finds {scan} L/s from pump A; even split costs {cost(A[:2], [50, 50]):.4f} kW, marginal costs {f4([2 * A[0] * 50, 2 * A[1] * 50])}")
print("chart, power (kW) at pump A = 0, 10, ..., 100 L/s:", " ".join(f"{cost(A[:2], [q, 100 - q]):g}" for q in range(0, 101, 10)))
assert scan == round(x1) and abs(cost(A[:2], [scan, 100 - scan]) - cost(A[:2], [x1, x2])) < 1e-9

# ---- three pumps, two rules: total flow 150 L/s and 35 m of head at the hill tank ----
G, b = [[1, 1, 1], K], [150, 35]
*x, l1, l2 = lagrange(A, G, b)
p0 = cost(A, x)
h = [6 * sum(K[i] ** e / (2 * A[i]) for i in range(3)) for e in (0, 1, 2)]   # x_i = (lam1 + lam2 k_i) / (2 a_i)
print(f"hand elimination, times 6: {h[0]:.1f} lam1 + {h[1]:.1f} lam2 = {6 * b[0]:.1f}; {h[1]:.1f} lam1 + {h[2]:.1f} lam2 = {6 * b[1]:.1f}; det {h[0] * h[2] - h[1] ** 2:.1f}")
print(f"three pumps: flows {f4(x)} L/s, lambda1 {l1:.4f} kW per L/s, lambda2 {l2:.4f} kW per m")
print(f"three pumps: power {p0:.4f} kW, {KWH * p0:.4f} pounds per hour; prices {KWH * l1:.4f} pounds/h per L/s, {KWH * l2:.4f} pounds/h per m")
print(f"grad f = ({f4([2 * A[i] * x[i] for i in range(3)])}); residual {"below" if resid(A, x, G, [l1, l2]) < 1e-12 else "ABOVE"} 1e-12")
t = [10 * (G[0][1] * K[2] - G[0][2] * K[1]), 10 * (G[0][2] * K[0] - G[0][0] * K[2]), 10 * (G[0][0] * K[1] - G[0][1] * K[0])]
print(f"allowed step t = ({f4(t)}); rule rates {f4([dot(G[0], t), dot(K, t)])}; grad f . t = {f4([dot([2 * A[i] * x[i] for i in range(3)], t)])}")
line = lambda s: cost(A, [x[i] + s * t[i] for i in range(3)])
lo, hi, r = -25.0, 50 / 3, (5 ** 0.5 - 1) / 2   # every pump flow stays at or above zero
for _ in range(200):
    p, q = hi - r * (hi - lo), lo + r * (hi - lo)
    if line(p) < line(q): hi = q
    else: lo = p
s = (lo + hi) / 2
print(f"road 2, golden-section search along the line: s = {f4([s])}, power {line(s):.4f} kW")
print("power along the line at s = -2, -1, 0, 1, 2:", f4([line(u) for u in (-2, -1, 0, 1, 2)]))
assert abs(s) < 1e-6 and resid(A, x, G, [l1, l2]) < 1e-12 and abs(line(s) - p0) < 1e-9 and abs(line(1) - p0 - 0.4) < 1e-9
w = gauss([[1, K[1]], [1, K[2]]], [2 * A[1] * x[1], 2 * A[2] * x[2]])   # solve for lam from pumps B, C
print(f"implicit-function road, pumps B and C solved for: lambda = ({f4(w)}); pump A row {2 * A[0] * x[0]:.4f} = {w[0] + w[1] * K[0]:.4f}")
assert abs(w[0] - l1) < 1e-9 and abs(w[1] - l2) < 1e-9 and abs(2 * A[0] * x[0] - w[0] - w[1] * K[0]) < 1e-9
pstar = lambda bb: cost(A, lagrange(A, G, bb)[:3])
d1 = (pstar([151, 35]) - pstar([149, 35])) / 2
d2 = (pstar([150, 36]) - pstar([150, 34])) / 2
print(f"road 3, re-solved: 151 L/s costs {pstar([151, 35]):.4f} kW (+{pstar([151, 35]) - p0:.4f}); 36 m costs {pstar([150, 36]):.4f} kW (+{pstar([150, 36]) - p0:.4f})")
print(f"road 3, central differences: {d1:.4f} kW per L/s, {d2:.4f} kW per m")
assert abs(d1 - l1) < 1e-9 and abs(d2 - l2) < 1e-9

# ---- what breaks ----
*y, mu = lagrange(A, [[1, 1, 1]], [150])
print(f"no head rule: flows {f4(y)} L/s, power {cost(A, y):.4f} kW, head {dot(K, y):.4f} m, {b[1] - dot(K, y):.4f} m short")
D = [[1, 1, 1], [2, 2, 2], K]
print("demand written twice: Lagrange system", "singular" if lagrange(A, D, [150, 300, 35]) is None else "solvable")
for lam3 in ([l1, 0, l2], [0, l1 / 2, l2]):
    print(f"  multipliers ({f4(lam3)}) leave residual {"below" if resid(A, x, D, lam3) < 1e-12 else "ABOVE"} 1e-12")
assert lagrange(A, D, [150, 300, 35]) is None and resid(A, x, D, [0, l1 / 2, l2]) < 1e-9
print(f"head rule written as -k.x = -35: lambda2 = {lagrange(A, [[1, 1, 1], [-k for k in K]], [150, -35])[4]:.4f}")
gc, e = lambda p: p[1] ** 2 - p[0] ** 3, 1e-6     # the rule g = x2^2 - x1^3; grad g by central difference
gf, gg = [1, 0], [(gc([e, 0]) - gc([-e, 0])) / (2 * e), (gc([0, e]) - gc([0, -e])) / (2 * e)]
best = min(((gf[0] - l * gg[0]) ** 2 + (gf[1] - l * gg[1]) ** 2) ** 0.5 for l in [u / 10 for u in range(-1000, 1001)])
def root(x2):                            # the x1 with g(x1, x2) = 0, by bisection: g falls as x1 rises
    lo, hi = -1.0, 2.0
    for _ in range(60):
        if gc([(lo + hi) / 2, x2]) > 0: lo = (lo + hi) / 2
        else: hi = (lo + hi) / 2
    return (lo + hi) / 2
cusp = min((root(u / 10), u / 10) for u in range(-10, 11))   # 21 points on the curve, lowest x1 first
print(f"cusp, minimise x1 on x2^2 = x1^3: grad g at (0, 0) = ({f4(gg)}); best residual over lambda {best:.4f}; lowest of 21 curve points ({f4(cusp)})")
assert best > 0.99 and abs(cusp[0]) < 1e-9 and abs(cusp[1]) < 1e-9
print("ALL CHECKS PASS")
