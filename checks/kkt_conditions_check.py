# KKT conditions -- the check behind the card.  Nothing is imported.
# Two pumps feed a water network; x1, x2 are their powers in kW.  Minimise the
# running cost f0 = 0.3 x1^2 + 0.2 x2^2 pounds an hour, subject to
#   demand       h  = x1 + x2 - 10 = 0          (10 kW delivered in all)
#   node 1 cap   f1 = 10 + x1 + 4 x2 - 35 <= 0   (pressure head in metres)
#   node 2 cap   f2 = 10 + 3 x1 + x2 - 35 <= 0
# Road 1: every active set, its linear KKT system solved by elimination.
# Road 2: the dual bound, the Lagrangian minimised over every x, feasible or not.
# Road 3: a scan of the demand line in steps of 0.0001 kW.
C, D, BASE, CAPS = (0.3, 0.2), 10.0, 10.0, (35.0, 35.0)
A = ((1.0, 4.0), (3.0, 1.0))        # metres of head per kW of each pump, at nodes 1 and 2

def cost(x): return C[0] * x[0] ** 2 + C[1] * x[1] ** 2
def fi(i, x, caps=CAPS): return BASE + A[i][0] * x[0] + A[i][1] * x[1] - caps[i]
def v(x): return f"({x[0]:.4f}, {x[1]:.4f})"

def solve(M, b):                    # Gauss-Jordan elimination with partial pivoting
    n = len(b); M = [row[:] + [b[r]] for r, row in enumerate(M)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        if abs(M[p][c]) < 1e-12: return None
        M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                f = M[r][c] / M[c][c]
                M[r] = [a - f * e for a, e in zip(M[r], M[c])]
    return [M[r][n] / M[r][r] for r in range(n)]

def kkt(active, caps=CAPS, d=D):    # unknowns x1, x2, a lam per active cap, nu
    n = 3 + len(active); M = [[0.0] * n for _ in range(n)]; b = [0.0] * n
    for j in range(2):              # stationarity: 2 C_j x_j + sum lam_i A_ij + nu = 0
        M[j][j] = 2 * C[j]; M[j][n - 1] = 1.0
        for t, i in enumerate(active): M[j][2 + t] = A[i][j]
    M[2][0] = M[2][1] = 1.0; b[2] = d                      # demand met exactly
    for t, i in enumerate(active):                         # active caps hold with equality
        M[3 + t][0], M[3 + t][1] = A[i]; b[3 + t] = caps[i] - BASE
    s = solve(M, b)
    if s is None: return None
    lam = [0.0, 0.0]
    for t, i in enumerate(active): lam[i] = s[2 + t]
    return (s[0], s[1]), lam, s[n - 1]

def best(caps=CAPS, d=D):           # road 1: the active set that passes all four conditions
    out = []
    for act in ((), (0,), (1,), (0, 1)):
        r = kkt(act, caps, d)
        if r and max(fi(0, r[0], caps), fi(1, r[0], caps)) <= 1e-9 and min(r[1]) >= -1e-9:
            out.append((act, r))
    return out

print("active caps   x1 kW   x2 kW     lam1     lam2       nu  cost £/h  verdict")
for act, name in (((), "none"), ((0,), "node 1"), ((1,), "node 2"), ((0, 1), "both")):
    r = kkt(act)
    if r is None:
        print(f"{name:<11} no point meets the demand and both caps"); continue
    x, lam, nu = r
    why = [f"node {i + 1} at {fi(i, x) + CAPS[i]:.1f} m, over {CAPS[i]:.0f}" for i in range(2) if fi(i, x) > 1e-9]
    why += [f"lam{i + 1} < 0" for i in range(2) if lam[i] < -1e-9]
    print(f"{name:<11}{x[0]:8.4f}{x[1]:8.4f}{lam[0]:9.4f}{lam[1]:9.4f}{nu:9.4f}{cost(x):10.4f}  "
          + ("; ".join(why) if why else "passes all four"))
sols = best(); assert len(sols) == 1, "exactly one active set passes"
(xs, lam, nu), fs = sols[0][1], cost(sols[0][1][0])
gf = (2 * C[0] * xs[0], 2 * C[1] * xs[1])
st = [gf[j] + lam[0] * A[0][j] + lam[1] * A[1][j] + nu for j in range(2)]
print(f"x* = {v(xs)} kW, cost {fs:.4f} £/h, lam = ({lam[0]:.4f}, {lam[1]:.4f}), nu = {nu:.4f}")
print(f"1 primal:      f1 = {fi(0, xs):.4f}, f2 = {fi(1, xs):.4f}, h = {xs[0] + xs[1] - D:.4f}")
print(f"2 dual:        lam1 = {lam[0]:.4f} >= 0, lam2 = {lam[1]:.4f} >= 0")
print(f"3 slackness:   lam1*f1 = {abs(lam[0] * fi(0, xs)):.4f}, lam2*f2 = {abs(lam[1] * fi(1, xs)):.4f}")
print(f"4 stationary:  grad f0 {v(gf)} + lam1 (1, 4) + nu (1, 1) = {v([abs(s) for s in st])}")
det = A[0][0] * 1.0 - A[0][1] * 1.0
print(f"LICQ: active gradients (1, 4) and (1, 1), determinant {det:.4f}, so independent")
e = 1e-5; fd = [(cost((xs[0] + e * (j == 0), xs[1] + e * (j == 1))) - cost((xs[0] - e * (j == 0), xs[1] - e * (j == 1)))) / (2 * e) for j in range(2)]
print(f"grad f0 by central difference {v(fd)}")
# road 2: q(lam, nu) = min over all x of f0 + lam1 f1 + lam2 f2 + nu h, separable in x1, x2
bj = [lam[0] * A[0][j] + lam[1] * A[1][j] + nu for j in range(2)]
q = sum(-bj[j] ** 2 / (4 * C[j]) for j in range(2)) + sum(lam[i] * (BASE - CAPS[i]) for i in range(2)) - nu * D
print(f"dual bound q(lam, nu) = {q:.4f} £/h, gap to the cost {abs(fs - q):.4f}")
# road 3: scan the demand line
feas = [(cost((k / 10000, D - k / 10000)), k / 10000) for k in range(100001)
        if max(fi(0, (k / 10000, D - k / 10000)), fi(1, (k / 10000, D - k / 10000))) <= 0]
sc = min(feas)
print(f"scan: {len(feas)} of 100001 points feasible, x1 from {feas[0][1]:.4f} to {feas[-1][1]:.4f}; best x1 = {sc[1]:.4f} at {sc[0]:.4f} £/h")
# what each multiplier is worth: re-solve with the limit nudged
up, dn = cost(best((CAPS[0] + 0.1, CAPS[1]))[0][1][0]), cost(best((CAPS[0] - 0.1, CAPS[1]))[0][1][0])
d_up, d_dn = cost(best(d=D + 0.1)[0][1][0]), cost(best(d=D - 0.1)[0][1][0])
print(f"cap 1 at {CAPS[0] - 0.1:.1f} / {CAPS[0] + 0.1:.1f} m: {dn:.4f} / {up:.4f} £/h, saving {(dn - up) / 0.2:.4f} per metre")
print(f"demand {D - 0.1:.1f} / {D + 0.1:.1f} kW: {d_dn:.4f} / {d_up:.4f} £/h, {(d_up - d_dn) / 0.2:.4f} per kW")
# how it moves: the node 1 cap swept from 28 to 40 m, each answer checked by a 0.001 kW scan
caps = list(range(28, 41)); row = []
for c in caps:
    x, lm, _ = best((float(c), 35.0))[0][1]
    grid = min(cost((k / 1000, D - k / 1000)) for k in range(10001)
               if max(fi(0, (k / 1000, D - k / 1000), (c, 35.0)), fi(1, (k / 1000, D - k / 1000), (c, 35.0))) <= 0)
    assert 0 <= grid - cost(x) < 0.004, "sweep: KKT answer vs scan"
    row.append((x[0], lm[0], cost(x)))
print(f"sweep, {'cap m':<9}" + " ".join(f"{c:6d}" for c in caps))
for k, name in ((0, "x1 kW"), (1, "lam1"), (2, "cost £/h")):
    print(f"sweep, {name:<9}" + " ".join(f"{r[k]:6.3f}" for r in row))
# what breaks
x0 = kkt(())[0]
print(f"mistake, no caps: x = {v(x0)}, cost {cost(x0):.4f}, node 1 at {fi(0, x0) + CAPS[0]:.4f} m")
x2, l2, _ = kkt((1,))
print(f"mistake, no sign rule: x = {v(x2)}, cost {cost(x2):.4f}, lam2 = {l2[1]:.4f}")
xc = (6.0, 4.0); sl = solve([[A[0][0], 1.0], [A[0][1], 1.0]], [-2 * C[0] * xc[0], -2 * C[1] * xc[1]])
print(f"mistake, no slackness: x = {v(xc)}, cost {cost(xc):.4f}, lam1 = {sl[0]:.4f}, f1 = {fi(0, xc):.4f}, lam1*f1 = {sl[0] * fi(0, xc):.4f}")
ns = [solve([[A[0][0], 1.0], [A[0][1], 1.0]], [-2 * C[0] * x1, -2 * C[1] * (D - x1)])[0] for _, x1 in feas]   # lam1 at every allowed split
print(f"mistake, no slackness: {sum(l >= 0 for l in ns)} of {len(feas)} allowed splits pass checks 1, 2 and 4, lam1 from {min(ns):.4f} to {max(ns):.4f}")
xx = solve([list(A[0]), list(A[1])], [CAPS[0] - BASE, CAPS[1] - BASE])
print(f"mistake, both caps as equalities: caps cross at {v(xx)}, total {xx[0] + xx[1]:.4f} kW, not 10")
# a constraint qualification fails: the node 1 cap written as (f1)^2 <= 0
nsq = sum(1 for k in range(100001) if fi(0, (k / 10000, D - k / 10000)) ** 2 <= 0)
xq = kkt((0,))[0]; gq = (2 * C[0] * xq[0], 2 * C[1] * xq[1])    # the one point with f1 = 0 and h = 0
nu_ls = -(gq[0] + gq[1]) / 2; res = ((gq[0] + nu_ls) ** 2 + (gq[1] + nu_ls) ** 2) ** 0.5
print(f"squared cap: {nsq} feasible point, x = {v(xq)}; grad (f1)^2 = {v([abs(2 * fi(0, xq) * a) for a in A[0]])}")
print(f"squared cap: best nu = {nu_ls:.4f} leaves stationarity residual {res:.4f}, so no multipliers")
cu = (lambda x: x[1] - (1 - x[0]) ** 3, lambda x: -x[1], lambda x: x[0])   # Kuhn-Tucker cusp: the two caps, and x1 = -f0
cg = [((u((1 + e, 0.0)) - u((1 - e, 0.0))) / (2 * e), (u((1.0, e)) - u((1.0, -e))) / (2 * e)) for u in cu]   # gradients at (1, 0)
kt = min(((cg[2][0] - a * cg[0][0] - b * cg[1][0]) ** 2 + (cg[2][1] - a * cg[0][1] - b * cg[1][1]) ** 2) ** 0.5
         for a in [k / 10 for k in range(101)] for b in [k / 10 for k in range(101)])
print(f"cusp, max x1 with x2 <= (1-x1)^3, x2 >= 0: at (1, 0) gradients {v(cg[0])}, {v(cg[1])}; -grad f = {v(cg[2])}; best residual over lam in [0, 10] {kt:.4f}")
s = 28.0
print(f"figure, x* ({40 + s * xs[0]:.1f} {300 - s * xs[1]:.1f}) no-cap ({40 + s * x0[0]:.1f} {300 - s * x0[1]:.1f}) "
      f"demand ({40:.1f} {300 - s * D:.1f}) ({40 + s * D:.1f} {300:.1f}) "
      f"cap1 ({40:.1f} {300 - s * 6.25:.1f}) ({40 + s * 10:.1f} {300 - s * 3.75:.1f}) cap2 ({40 + s * 5:.1f} {20:.1f}) "
      f"({40 + s * 25 / 3:.1f} {300:.1f}) end ({40 + s * 7.5:.1f} {300 - s * 2.5:.1f}) radii {s * (fs / C[0]) ** 0.5:.1f} {s * (fs / C[1]) ** 0.5:.1f}")
assert abs(sc[1] - xs[0]) < 1e-4 and abs(sc[0] - fs) < 1e-9, "road 1 vs road 3: KKT point vs scan"
assert abs(q - fs) < 1e-9 and all(c >= q - 1e-12 for c, _ in feas), "road 2: dual bound meets the cost"
assert abs((dn - up) / 0.2 - lam[0]) < 1e-6, "lam1 is the saving per metre of cap"
assert abs((d_up - d_dn) / 0.2 + nu) < 1e-6, "-nu is the cost per kW of demand"
assert all(abs(fd[j] - gf[j]) < 1e-6 for j in range(2)), "gradient vs central difference"
assert max(abs(s) for s in st) < 1e-9 and res > 1e-6, "stationarity holds; the squared cap breaks it"
assert min(ns) >= 0 and kt > 0.99, "without slackness every allowed split passes; the cusp has no multipliers"
print("ALL CHECKS PASS")
