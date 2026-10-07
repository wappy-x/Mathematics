# The Lorenz system -- the check behind the card.  Only math primitives imported; RK4 written out.  Two roads each time:
# formula vs Newton, eigenvalue cubic vs Jacobian trace and det, divergence vs a flowed box, separation vs tangent rate.
from math import sqrt, log, exp, log10
S, R, B = 10.0, 28.0, 8.0 / 3.0
def F(p, r=R): x, y, z = p; return (S * (y - x), x * (r - z) - y, x * y - B * z)
def J(p, r=R): x, y, z = p; return ((-S, S, 0.0), (r - z, -1.0, -x), (y, x, -B))
def ax(p, k, c): return tuple(p[i] + c * k[i] for i in range(len(p)))
def rk4(f, p, h, n):                                   # Runge-Kutta 4, four slopes weighted 1-2-2-1
    for _ in range(n):
        k1 = f(p); k2 = f(ax(p, k1, h / 2)); k3 = f(ax(p, k2, h / 2)); k4 = f(ax(p, k3, h))
        p = tuple(p[i] + h * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) / 6 for i in range(len(p)))
    return p
def det(m): return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
def solve(m, v): d = det(m); return tuple(det([[v[i] if j == k else m[i][j] for j in range(3)] for i in range(3)]) / d for k in range(3))
dist = lambda a, b: sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]) + (a[2] - b[2]) * (a[2] - b[2])); f6 = lambda xs: " ".join(f"{x:.6f}" for x in xs)
print(f"Lorenz system, sigma = 10, rho = 28, beta = 8/3 = {B:.6f}; RK4 throughout")
c = sqrt(B * (R - 1)); cp = (8.0, 8.0, 25.0)
for _ in range(8): cp = ax(cp, solve(J(cp), F(cp)), -1.0)       # Newton: p -> p - J^-1 F
print(f"lobe centres, formula x^2 = beta (rho - 1) = {B * (R - 1):.6f}, so (+/-{c:.6f}, +/-{c:.6f}, {R - 1:.6f}); Newton from (8, 8, 25): {f6(cp)}")
a2, a1, a0, lo, hi = S + B + 1, B * (S + R), 2 * S * B * (R - 1), -100.0, 0.0   # cubic l^3 + a2 l^2 + a1 l + a0
for _ in range(200): mid = (lo + hi) / 2; lo, hi = (mid, hi) if ((mid + a2) * mid + a1) * mid + a0 < 0 else (lo, mid)
l1 = lo; re = -(a2 + l1) / 2; im = sqrt(a0 / -l1 - re * re); g = sqrt((S + 1) ** 2 + 4 * S * (R - 1))   # pair's product is a0 / -l1
print(f"eigenvalues at the origin, roots of l^2 + {S + 1:.0f} l - {S * (R - 1):.0f} and -beta: {f6([(-(S + 1) + g) / 2, (-(S + 1) - g) / 2, -B])}")
print(f"eigenvalues at a lobe centre: {l1:.6f} and {re:.6f} +/- {im:.6f}i; spiral turns outward above rho = {S * (S + B + 3) / (S - B - 1):.6f}")
Jc = J(cp); tr = Jc[0][0] + Jc[1][1] + Jc[2][2]; mi = Jc[0][0] * Jc[1][1] - Jc[0][1] * Jc[1][0] + Jc[0][0] * Jc[2][2] - Jc[0][2] * Jc[2][0] + Jc[1][1] * Jc[2][2] - Jc[1][2] * Jc[2][1]; pairs = 2 * l1 * re + re * re + im * im
print(f"Jacobian at Newton's point: trace {tr:.6f}, 2x2 minors {mi:.6f}, det {det(Jc):.6f}; from the roots: sum {l1 + 2 * re:.6f}, pairs {pairs:.6f}, product {l1 * (re * re + im * im):.6f}")
q0 = rk4(F, (1.0, 1.0, 1.0), 0.001, 10000); e = 1e-6; box = [ax(rk4(F, ax(q0, u, e), 0.001, 500), rk4(F, q0, 0.001, 500), -1.0) for u in ((1, 0, 0), (0, 1, 0), (0, 0, 1))]
print(f"box of side 1e-6 at t = 10, after 0.5: volume x {det(box) / (e * e * e):.6f}, exp(0.5 x trace) = {exp(0.5 * tr):.6f}")
a, b, s = (1.0, 1.0, 1.0), (1.0 + 1e-8, 1.0, 1.0), (1.0, 1.0, 1.0); sep, gap = [], []
for k in range(41):
    sep.append(dist(a, b)); gap.append(dist(a, s))
    a, b, s = rk4(F, a, 0.001, 1000), rk4(F, b, 0.001, 1000), rk4(F, s, 0.0005, 2000)
print("separation at t = 0, 5, ..., 40:", " ".join(f"{sep[t]:.1e}" for t in range(0, 41, 5)))
print("chart, log10 separation at t = 0, 2, ..., 40:", " ".join(f"{log10(sep[t]):.2f}" for t in range(0, 41, 2)))
print("step check, h = 0.001 vs 0.0005, gap at t = 10, 20, 25, 30:", " ".join(f"{gap[t]:.1e}" for t in (10, 20, 25, 30)))
slope = (log(sep[30]) - log(sep[15])) / 15; w, v, tot = rk4(F, (1.0, 1.0, 1.0), 0.01, 1000), (1.0, 0.0, 0.0), 0.0
T = lambda s6: F(s6[:3]) + tuple(m[0] * s6[3] + m[1] * s6[4] + m[2] * s6[5] for m in J(s6[:3]))
for _ in range(500):                                   # tangent road: stretch a unit arrow, renormalise each unit
    s6 = rk4(T, w + v, 0.01, 100); w = s6[:3]; n = sqrt(s6[3] * s6[3] + s6[4] * s6[4] + s6[5] * s6[5]); tot += log(n); v = tuple(x / n for x in s6[3:])
lam = tot / 500; print(f"growth rate: separation slope t = 15..30 {slope:.6f}; tangent over 500 units {lam:.6f}; dimension 2 + {lam:.4f}/{lam - tr:.4f} = {2 + lam / (lam - tr):.4f}; 1e-8 to 10 takes {log(10 / 1e-8) / lam:.2f}, one digit {log(10) / lam:.2f}")
p = rk4(F, (1.0, 1.0, 1.0), 0.002, 5000); tops, pr = [], F(p)[2]
for _ in range(50000):                                  # Poincare section: the moments z stops rising
    q = rk4(F, p, 0.002, 1); d = F(q)[2]; tops += [q[2]] if pr > 0 >= d else []; p, pr = q, d
low = [n > m for m, n in zip(tops, tops[1:]) if m < 38.5]; zbar = []
print(f"section z' = 0, t = 10..110: {len(tops)} tops, {min(tops):.2f} to {max(tops):.2f}; below 38.5 then higher: {sum(low)} of {len(low)}")
print("first pairs (top > next top):", " ".join(f"{m:.2f}>{n:.2f}" for m, n in zip(tops[:5], tops[1:6])))
for s0 in ((1.0, 1.0, 1.0), (30.0, -40.0, 90.0), (-0.01, 0.0, 0.0)):   # basin: far and near starts
    q, tot = rk4(F, s0, 0.01, 2000), 0.0
    for _ in range(2000): q = rk4(F, q, 0.01, 10); tot += q[2]
    zbar.append(tot / 2000)
print(f"basin: mean z over t = 20..220 from (1,1,1), (30,-40,90), (-0.01,0,0): {f6(zbar)}")
print(f"mistake, rho = 20: from (1,1,1) at t = 150 {f6(rk4(lambda s: F(s, 20.0), (1.0, 1.0, 1.0), 0.01, 15000))}; formula {sqrt(B * 19):.6f}")
fig, pts = rk4(F, (1.0, 1.0, 1.0), 0.001, 15000), []
for _ in range(400): pts.append(f"{180 + 4 * fig[0]:.0f},{220 - 4 * fig[2]:.0f}"); fig = rk4(F, fig, 0.001, 25)
print(f"figure, x-z plane, 4 units per unit, t = 15 to 25 every 0.025: lobes at {180 - 4 * c:.1f},{220 - 4 * (R - 1):.1f} and {180 + 4 * c:.1f},{220 - 4 * (R - 1):.1f};", " ".join(pts))
assert dist(cp, (c, c, R - 1)) < 1e-9                                  # Newton meets the formula
assert abs(mi - pairs) < 1e-6 and abs(det(Jc) - l1 * (re * re + im * im)) < 1e-6        # matrix meets the cubic's roots
assert abs(det(box) / (e * e * e) - exp(0.5 * tr)) < 1e-5                  # flowed box shrinks at the divergence
assert abs(slope - lam) < 0.1                                          # two roads to the growth rate
print("ALL CHECKS PASS")
