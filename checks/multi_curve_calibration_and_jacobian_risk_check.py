# Multi-curve calibration and Jacobian risk -- the check behind the card.  Standard library only.
# Two curves (overnight discount D, 3-month projection H), zero rates at 1, 2, 3 years,
# solved jointly by Newton on six quotes; then node risk -> quote risk by the inverse Jacobian.
from math import exp, log
def tot(xs):                          # plain left-to-right sum, the same in both languages
    s = 0.0
    for v in xs: s += v
    return s
PIL, BP = [1.0, 2.0, 3.0], 1e-4
MKT = [0.0420, 0.0440, 0.0455, 0.0009, 0.00095, 0.0010]   # OIS 1y 2y 3y; basis 1y 2y 3y
NAMES = ["OIS 1y", "OIS 2y", "OIS 3y", "basis 1y", "basis 2y", "basis 3y"]
def zero(t, n):                       # straight line between pillars, flat outside them
    if t <= PIL[0] or t >= PIL[2]: return n[0] if t <= PIL[0] else n[2]
    k = 0 if t <= PIL[1] else 1
    return (1 - (t - PIL[k])) * n[k] + (t - PIL[k]) * n[k + 1]
def df(t, n): return exp(-zero(t, n) * t)
def qgrid(m): return [0.25 * i for i in range(4 * m + 1)]
def index_leg(x, ts):                 # forecast off H, discount off D
    d, h = x[:3], x[3:]
    return tot((df(ts[i - 1], h) / df(ts[i], h) - 1) * df(ts[i], d) for i in range(1, len(ts)))
def ann_y(x, m): return tot(df(k, x[:3]) for k in range(1, m + 1))
def ann_q(x, m): return tot(0.25 * df(t, x[:3]) for t in qgrid(m)[1:])
def quotes(x):                        # the six model quotes the curves imply
    out = [(1 - df(m, x[:3])) / ann_y(x, m) for m in (1, 2, 3)]
    out += [(index_leg(x, qgrid(m)) - (1 - df(m, x[:3]))) / ann_q(x, m) for m in (1, 2, 3)]
    return out
def jac(f, x, rows, cols, h=1e-7):    # central differences, one column per node
    J = [[0.0] * len(cols) for _ in rows]
    for c, j in enumerate(cols):
        u = x[:]; u[j] += h; v = x[:]; v[j] -= h
        fu, fv = f(u), f(v)
        for r, i in enumerate(rows): J[r][c] = (fu[i] - fv[i]) / (2 * h)
    return J
def solve(A, b):                      # Gaussian elimination with partial pivoting
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            for k in range(c, n + 1): M[r][k] -= f * M[c][k]
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        x[r] = (M[r][n] - tot(M[r][k] * x[k] for k in range(r + 1, n))) / M[r][r]
    return x
def newton(mkt, x0, free=range(6), stale=False, log=None):
    x, free, J = x0[:], list(free), None
    for it in range(0, 60):
        r = [quotes(x)[i] - mkt[i] for i in free]
        if log is not None: log.append(max(abs(v) for v in r) / BP)
        if max(abs(v) for v in r) < 1e-14: return x, it
        if J is None or not stale: J = jac(quotes, x, free, free)
        for i, s in zip(free, solve(J, r)): x[i] -= s
    raise RuntimeError("Newton did not converge")
def bisect(g, lo=-0.5, hi=0.5):       # road 2: one node at a time, no derivatives
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (g(lo) > 0) == (g(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def bootstrap(mkt):
    x = [0.0] * 6
    for i in range(6):
        def g(z, i=i):
            x[i] = z; return quotes(x)[i] - mkt[i]
        x[i] = bisect(g)
    return x
N, K = 10_000_000.0, 0.045            # test swap: receive 3-month index, pay 4.5% twice a year, 2.5 years
def swap(x): return N * (index_leg(x, qgrid(3)[:11]) - tot(0.5 * K * df(0.5 * j, x[:3]) for j in range(1, 6)))
def node_risk(f, x):                  # dollars per 1bp up at each node, central difference
    out = []
    for j in range(6):
        u = x[:]; u[j] += BP; v = x[:]; v[j] -= BP
        out.append((f(u) - f(v)) / 2)
    return out
def show(label, vals, fmt):
    print(f"{label:<30}" + "".join(fmt.format(0.0 if abs(v) < 1e-6 else v) for v in vals))
misses = []
x, iters = newton(MKT, [0.0] * 6, log=misses)
for it, e in enumerate(misses): print(f"Newton step {it}: largest quote miss {e:.3e} bp")
xb = bootstrap(MKT)
show("nodes, Newton (zero %)", [100 * v for v in x], "{:>12.6f}")
show("nodes, bootstrap (zero %)", [100 * v for v in xb], "{:>12.6f}")
g1 = exp(x[0] / 4)                    # by hand: inside one year both curves are flat
print(f"D(1) {df(1, x[:3]):.8f}  e^(zD1/4) {g1:.8f}  + s/4 = {g1 + MKT[3] / 4:.8f}  zH1 {400 * log(g1 + MKT[3] / 4):.6f} %")
gap = max(abs(a - b) for a, b in zip(x, xb)) / BP
J = jac(quotes, x, range(6), range(6))
for i in range(6): show(f"Jacobian row {NAMES[i]}", J[i], "{:>10.5f}")
V0, Rz = swap(x), node_risk(swap, x)
JT = [[J[i][j] for i in range(6)] for j in range(6)]
Rq = solve(JT, Rz)                    # quote risk = J^-T times node risk
fwd, cen = [], []
for i in range(6):
    up = MKT[:]; up[i] += BP; dn = MKT[:]; dn[i] -= BP
    vu, vd = swap(newton(up, x)[0]), swap(newton(dn, x)[0])
    fwd.append(vu - V0); cen.append((vu - vd) / 2)
print(f"test swap value {V0:.2f}")
show("node risk ($ per bp)", Rz, "{:>10.2f}")
for k in range(5, -1, -1):            # J is lower triangular, so J^T y = Rz solves from the bottom up
    num = Rz[k] - tot(J[i][k] * Rq[i] for i in range(k + 1, 6))
    print(f"  back-substitute {NAMES[k]:<9} ({Rz[k]:.2f} -> {num:.2f}) / {J[k][k]:.5f} = {num / J[k][k]:.2f}")
print(f"totals: node D {tot(Rz[:3]):.2f}  node H {tot(Rz[3:]):.2f}  quote OIS {tot(Rq[:3]):.2f}  quote basis {tot(Rq[3:]):.2f}")
show("quote risk, J^-T ($ per bp)", Rq, "{:>10.2f}")
show("quote risk, rebuild +1bp", fwd, "{:>10.2f}")
show("quote risk, rebuild central", cen, "{:>10.2f}")
def ois2(x): return N * ((1 - df(2, x[:3])) - MKT[1] * ann_y(x, 2))   # 2y OIS, pay fixed at par
own = solve(JT, node_risk(ois2, x))
show("2y OIS par swap, J^-T", own, "{:>10.2f}")
annuity_bp = [ann_y(x, m) * BP for m in (1, 2, 3)] + [ann_q(x, m) * BP for m in (1, 2, 3)]
hedge = [r / a for r, a in zip(Rq, annuity_bp)]
show("hedge notionals (millions)", [h / 1e6 for h in hedge], "{:>10.4f}")
def hedged(x):                        # test swap minus the six par instruments, sized by quote risk
    v = swap(x)
    for i, m in enumerate((1, 2, 3)):
        v -= hedge[i] * ((1 - df(m, x[:3])) - MKT[i] * ann_y(x, m))
        v -= hedge[3 + i] * (index_leg(x, qgrid(m)) - (1 - df(m, x[:3])) - MKT[3 + i] * ann_q(x, m))
    return v
hz = max(abs(v) for v in node_risk(hedged, x))
print(f"hedged book, largest node risk {hz:.4f}")
# ---- what breaks ----
frozen = []                           # rebuild only the OIS curve, hold projection nodes still
for i in range(3):
    up = MKT[:]; up[i] += BP; dn = MKT[:]; dn[i] -= BP
    frozen.append((swap(newton(up, x, free=range(3))[0]) - swap(newton(dn, x, free=range(3))[0])) / 2)
show("wrong: projection frozen", frozen, "{:>10.2f}")
show("wrong: J^-1 not J^-T", solve(J, Rz), "{:>10.2f}")
miss = tot(Rq[:3]) - tot(Rz[:3])
print(f"wrong: node risk as quote risk, OIS risk missed {miss:.2f}")
# ---- try changing ----
_, chord = newton(MKT, [0.0] * 6, stale=True)
print(f"try: stale Jacobian, steps {chord}")
_, far = newton(MKT, [0.20] * 6)
print(f"try: start at 20% everywhere, steps {far}")
xz, _ = newton(MKT[:3] + [0.0, 0.0, 0.0], x)
print(f"try: zero basis, largest gap H - D {max(abs(xz[3 + k] - xz[k]) for k in range(3)) / BP:.6f} bp")
assert iters <= 5 and gap < 1e-8 and abs(x[3] - 4 * log(g1 + MKT[3] / 4)) < 1e-12 and abs(df(1, x) - 1 / 1.042) < 1e-12
assert max(abs(a - b) for a, b in zip(Rq, cen)) < 1e-3 # Jacobian risk = bump and rebuild
assert max(abs(a - b) for a, b in zip(Rq, fwd)) < 0.1  # forward bump differs only by convexity
assert abs(own[1] - N * ann_y(x, 2) * BP) < 1e-4 and max(abs(own[j]) for j in (0, 2, 3, 4, 5)) < 1e-4
assert hz < 1e-4 and chord > iters and abs(tot(frozen) - tot(Rq[:3])) > 1000
print("ALL CHECKS PASS")
