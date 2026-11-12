# Stiffness and the Dahlquist barriers: the check behind the card.  Standard library only.  A reaction A -> B -> C
# (rates 1e6 and 1 per s, illustrative) stepped five ways; stability on y' = lam*y; the BDF family; both barriers.
from math import exp, sqrt, cos, sin, pi, atan2, log
K1, K2 = 1e6, 1.0                                # fast and slow rates, per s
def sci(v, d=3): m, e = f"{v:.{d}e}".split("e"); return f"{m}e{int(e)}"   # 1.234e-5, the form Rust prints
def b_true(t): return K1 / (K1 - K2) * (exp(-K2 * t) - exp(-K1 * t))
def rate(a, b): return -K1 * a, K1 * a - K2 * b
def solve(c, h, ra, rb):                         # (I - c h J) y = r; J is lower triangular
    a = ra / (1 + c * h * K1); return a, (rb + c * h * K1 * a) / (1 + c * h * K2)
def run(m, h, n):                                # n steps of size h from a = 1, b = 0
    a, b, prev = 1.0, 0.0, None
    for _ in range(n):
        if m == "FE": da, db = rate(a, b); na, nb = a + h * da, b + h * db
        elif m == "RK4":
            p = rate(a, b); q = rate(a + h / 2 * p[0], b + h / 2 * p[1])
            r = rate(a + h / 2 * q[0], b + h / 2 * q[1]); s = rate(a + h * r[0], b + h * r[1])
            na, nb = a + h / 6 * (p[0] + 2 * q[0] + 2 * r[0] + s[0]), b + h / 6 * (p[1] + 2 * q[1] + 2 * r[1] + s[1])
        elif m == "BE": na, nb = solve(1, h, a, b)
        elif m == "TR": da, db = rate(a, b); na, nb = solve(0.5, h, a + h / 2 * da, b + h / 2 * db)
        elif prev is None: na, nb = solve(1, h, a, b)          # BDF2, started by one BE step
        else: na, nb = solve(2 / 3, h, (4 * a - prev[0]) / 3, (4 * b - prev[1]) / 3)
        prev, a, b = (a, b), na, nb
    return a, b
def div(p, q): return p * q.conjugate() / (q.real * q.real + q.imag * q.imag)
def pv(c, x):                                    # Horner: sum c[j] x^j
    p = 0j
    for v in reversed(c): p = p * x + v
    return p
def roots(c):                                    # Durand-Kerner: every root of sum c[j] x^j
    c = [div(x, c[-1]) for x in c]; n = len(c) - 1
    if n == 1: return [-c[0]]
    z = [1 + 0j]
    while len(z) < n: z.append(z[-1] * (0.4 + 0.9j))
    for _ in range(800):
        new = []
        for i in range(n):
            p, q = pv(c, z[i]), 1 + 0j
            for j in range(n):
                if j != i: q = q * (z[i] - z[j])
            new.append(z[i] - div(p, q))
        moved = max(abs(u - v) for u, v in zip(new, z)); z = new
        if moved < 1e-15: break
    return z
def R4(z): return pv([1, 1, 1 / 2, 1 / 6, 1 / 24], z)       # RK4's factor per step on y' = lam*y
M = {"FE": ([-1, 1], [1, 0]), "AB2": ([0, -1, 1], [-0.5, 1.5, 0]), "BE": ([-1, 1], [0, 1]),
     "TR": ([-1, 1], [0.5, 0.5]), "AM2": ([0, -1, 1], [-1 / 12, 8 / 12, 5 / 12]),
     "BDF2": ([0.5, -2, 1.5], [0, 0, 1]), "BDF3": ([-1 / 3, 1.5, -3, 11 / 6], [0, 0, 0, 1])}
def amp(m, z):                                   # largest root size of the step's characteristic polynomial
    if m == "RK4": return abs(R4(z))
    return max(abs(x) for x in roots([complex(u) - z * v for u, v in zip(*M[m])]))
def edge(m):                                     # left end of the stable stretch of the real axis
    if amp(m, -1e4) <= 1: return None
    lo, hi = -50.0, -1e-6
    while hi - lo > 1e-13: mid = (lo + hi) / 2; lo, hi = (mid, hi) if amp(m, mid) > 1 else (lo, mid)
    return hi
tr, dt = -K1 - K2, K1 * K2; l1, l2 = (tr - sqrt(tr * tr - 4 * dt)) / 2, (tr + sqrt(tr * tr - 4 * dt)) / 2
print(f"J = [[-{K1:.0f}, 0], [{K1:.0f}, -{K2:.0f}]]; eigenvalues from trace and determinant: {l1:.1f} and {l2:.6f} per s; stiffness ratio {l1 / l2:.0f}")
assert abs(l1 + K1) < 1e-6 and abs(l2 + K2) < 1e-9
bt = b_true(1.0); print(f"true B at 1 s: {bt:.10f}; target: an error under 1e-4")
xr = -2.8                                        # second road to RK4's edge: Newton on (R(x) - 1)/x = 0
for _ in range(50): xr -= (1 + xr * (1 / 2 + xr * (1 / 6 + xr / 24))) / (1 / 2 + xr * (1 / 3 + xr / 8))
e = {m: edge(m) for m in ["FE", "RK4", "AB2"]}
assert abs(e["FE"] + 2) < 1e-9 and abs(e["AB2"] + 1) < 1e-9 and abs(e["RK4"] - xr) < 1e-9
print(f"explicit step limits h < -edge/1e6: FE {sci(-e['FE'] / K1)} s, RK4 {sci(-e['RK4'] / K1)} s "
      f"(Newton edge {xr:.6f}), AB2 {sci(-e['AB2'] / K1)} s")
print("run to 1 s           steps    evals  A at 1 s    B error")
for m, n, ev in [("FE", 525000, 1), ("RK4", 360000, 4), ("BE", 100, 1), ("TR", 100, 1), ("BDF2", 100, 1)]:
    a, b = run(m, 1.0 / n, n)
    print(f"{m:>4}, h = {sci(1.0 / n, 2):>8}  {n:>6}  {n * ev:>7}  {sci(a):>10}  {sci(b - bt):>10}")
    if m == "BDF2": assert abs(b - bt) < 1e-4 < abs(run("BE", 0.01, 100)[1] - bt)
    if m == "FE": assert abs(b - bt - K1 / (K1 - K2) * ((1 - K2 / n) ** n - (1 - K1 / n) ** n - exp(-K2))) < 1e-10   # FE's exact discrete B
    if m == "TR": assert abs(a - ((1 - K1 / (2 * n)) / (1 + K1 / (2 * n))) ** n) < 1e-12   # TR's factor on A, n times
fa = run("FE", 2.1e-6, 476)[0]; print(f"FE at h = 2.1e-6 (factor -1.1), 476 steps = 1 ms: A = {sci(fa)}"); assert 1e19 < abs(fa) < 1e21
eb = [abs(run(m, 1.0 / n, n)[1] - bt) for m in ("BE", "BDF2") for n in (100, 200, 400)]
pb, pd = log(eb[1] / eb[2]) / log(2), log(eb[4] / eb[5]) / log(2); assert abs(pb - 1) < 0.02 and abs(pd - 2) < 0.02
print(f"B errors at h = 0.01, 0.005, 0.0025: BE {', '.join(sci(x) for x in eb[:3])} (order {pb:.3f}); "
      f"BDF2 {', '.join(sci(x) for x in eb[3:])} (order {pd:.3f})")
z = -1e4                                         # h = 0.01 on the fast rate
print(f"one step at z = h*lam = {z:.0f}: FE {1 + z:.0f}, RK4 {sci(R4(z).real)}, BE {sci(amp('BE', z))}, "
      f"TR {div(1 + z / 2, 1 - z / 2).real:.5f}, BDF2 root size {amp('BDF2', z):.7f}")
assert abs(amp("BDF2", z) - sqrt(0.5 / (1.5 - z))) < 1e-12
def consts(m):                                   # order p and error constant C_(p+1)/sigma(1)
    al, be = M[m]; f1 = 1.0
    for q in range(1, 9):
        f1 *= q; cq = sum(a * j ** q for j, a in enumerate(al)) / f1 - q * sum(b * j ** (q - 1) for j, b in enumerate(be)) / f1
        if abs(cq) > 1e-10: return q - 1, cq / sum(be)
TH = [pi * (i + 0.5) / 4000 for i in range(4000)]
def locus_min(m):                                # road 1: smallest Re z on the boundary locus z = rho/sigma
    return min(div(pv(M[m][0], complex(cos(t), sin(t))), pv(M[m][1], complex(cos(t), sin(t)))).real for t in TH)
grid = [10 ** (s / 4 - 2) * complex(cos(pi * (0.5 + (i + 0.5) / 60)), sin(pi * (0.5 + (i + 0.5) / 60))) for s in range(21) for i in range(60)]
print("method  p  C/sigma(1)  real edge  locus min Re z  worst grid amp  A-stable  amp at -1e8")
for m in ["FE", "AB2", "RK4", "AM2", "BE", "TR", "BDF2", "BDF3"]:
    (p, c), wg = consts(m) if m != "RK4" else (4, None), max(amp(m, g) for g in grid)
    lm = locus_min(m) if m != "RK4" else min(min(x.real for x in roots([1 - complex(cos(t), sin(t)), 1, 1 / 2, 1 / 6, 1 / 24])) for t in TH[::20])
    ok, eg = wg <= 1 + 1e-9, edge(m)                # the locus's leftmost point: the real edge, BDF3's -1/12, or 0
    assert ok == (lm >= -1e-9) and abs(lm - (eg if eg is not None else -1 / 12 if m == "BDF3" else 0.0)) < 1e-5
    assert not ok or (p <= 2 and (p < 2 or c <= -1 / 12 + 1e-12))   # second barrier, on each A-stable one
    ed = "-inf" if eg is None else f"{eg:.4f}"
    cs, ls, ws = "-" if c is None else f"{c:.5f}", f"{lm if abs(lm) > 1e-9 else 0.0:.5f}", f"{wg:.4f}" if wg < 100 else sci(wg, 2)
    print(f"{m:>6}  {p}  {cs:>10}  {ed:>9}  {ls:>13}  {ws:>14}  {'yes' if ok else 'no':>8}  {sci(amp(m, -1e8), 2)}")
ph = {m: div(pv(M[m][1], 1.01), pv(M[m][0], 1.01)).real - 2.01 / (2 * (1.01 - 1)) for m in ("TR", "BDF2", "AM2")}   # the proof's phi at zeta = 1.01
print(f"proof: Re phi(1.01) = Re[sigma/rho - (zeta+1)/(2(zeta-1))]: TR {sci(ph['TR'])}, BDF2 {sci(ph['BDF2'])}, AM2 {sci(ph['AM2'])}")
assert ph["AM2"] < 0 < ph["BDF2"] and abs(ph["AM2"] + 0.01 / 12) < 2e-4 and abs(ph["BDF2"] - 0.0025) < 3e-4
print("BDF k  max |root of rho| besides 1  alpha (deg)")
for k in range(1, 8):
    rho = [0.0] * (k + 1)
    for j in range(1, k + 1):                    # rho = sum (1/j) x^(k-j) (x-1)^j
        t = [1.0]
        for _ in range(j): t = [0.0] + t; t = [t[i] - (t[i + 1] if i + 1 < len(t) else 0) for i in range(len(t))]
        for i, v in enumerate(t): rho[i + k - j] += v / j
    big = max([abs(x) for x in sorted(roots(rho), key=lambda x: abs(x - 1))[1:]], default=0.0)
    al = pi / 2                                  # A(alpha): smallest angle of the locus from the negative real axis
    for i in range(1, 20000):
        t = pi * i / 20000; w = div(pv(rho, complex(cos(t), sin(t))), complex(cos(k * t), sin(k * t)))
        if w.real < 0: al = min(al, atan2(abs(w.imag), -w.real))
    al *= 180 / pi
    print(f"    {k}  {big:28.4f}  {f'{al:.2f}' if big < 1 else 'unstable':>11}")
    assert (big > 1) == (k == 7)
    assert k > 6 or abs(al - [90, 90, 86.03, 73.35, 51.84, 17.84][k - 1]) < 0.006
for k in (1, 2, 3):                              # first barrier: the highest-order implicit k-step formula
    n = 2 * k + 1                                # unknowns a_0..a_(k-1), b_0..b_k; a_k = 1
    A = [[float(j ** q) for j in range(k)] + [-float(q * j ** (q - 1)) if q else 0.0 for j in range(k + 1)]
         + [-float(k ** q)] for q in range(n)]
    for c in range(n):                           # Gaussian elimination with partial pivoting
        piv = max(range(c, n), key=lambda r: abs(A[r][c])); A[c], A[piv] = A[piv], A[c]
        for r in range(n):
            if r != c: A[r] = [x - A[r][c] / A[c][c] * y for x, y in zip(A[r], A[c])]
    x = [A[i][n] / A[i][i] for i in range(n)]
    al, be = x[:k] + [1.0], x[k:]; M["k"] = (al, be); p = consts("k")[0]; big = max(abs(r) for r in roots(al))
    print(f"first barrier, k = {k}: order {p}, rho = {', '.join(f'{v:.4f}' for v in al)}; largest |root| {big:.4f}")
    assert p == 2 * k and (big > 1 + 1e-9) == (p > (k + 2 if k % 2 == 0 else k + 1))
h, ys = 0.1, [exp(-0.1 * i) for i in range(3)]   # run the order-6 three-step formula on y' = -y
for i in range(3, 31): ys.append((-sum(a * y for a, y in zip(al[:3], ys[-3:])) + h * -sum(b * y for b, y in zip(be[:3], ys[-3:]))) / (1 + h * be[3]))
print(f"order-6 three-step formula on y' = -y, h = 0.1: error at steps 10, 20, 30: {', '.join(sci(ys[i] - exp(-h * i)) for i in (10, 20, 30))}")
assert abs(ys[30] - exp(-3)) > 1
w = max((div(pv(M["BDF2"][0], complex(cos(t), sin(t))), complex(cos(2 * t), sin(2 * t))) for t in TH), key=lambda w: w.imag)
assert abs(abs(R4(1j * sqrt(8))) - 1) < 1e-12 and abs(w.imag - sqrt(sqrt(3) / 2) * (3 + sqrt(3)) / 2) < 1e-6  # closed forms
print(f"figure, 34 px per unit, origin (140, 120): FE centre (106.0, 120.0) radius 34.0; RK4 edge ({140 + 34 * e['RK4']:.1f}, 120.0), "
      f"imaginary tips +-{sqrt(8):.4f} at y {120 - 34 * sqrt(8):.1f}; BDF2 locus right end {pv(M["BDF2"][0], -1).real:.0f} at (276.0, 120.0), top {w.real:.4f} + {w.imag:.4f}i at ({140 + 34 * w.real:.1f}, {120 - 34 * w.imag:.1f})")
print("ALL CHECKS PASS")
