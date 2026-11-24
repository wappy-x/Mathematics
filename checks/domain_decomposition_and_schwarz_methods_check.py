# Domain decomposition and Schwarz methods -- the check behind the card.  Standard
# library only.  Part 1: -u'' = 0 on [0, 1] split into [0, 0.6] and [0.4, 1], grid
# step 0.01.  Part 2: the hot plate on a 63-by-63 grid, conjugate gradient with
# one-level and two-level additive Schwarz, checked against a banded Cholesky.
from math import gcd, sqrt, tan, pi
def e3(x): m, p = f"{x:.3e}".split("e"); return f"{m}e{int(p)}"  # as Rust's {:.3e}
def piece(u, lo, hi):  # solve -u'' = 0 strictly inside (lo, hi) by Thomas, ends fixed
    n = hi - lo - 1; c = [0.0] * n; d = [0.0] * n
    for k in range(n):
        rhs = (u[lo] if k == 0 else 0.0) + (u[hi] if k == n - 1 else 0.0)
        den = 2.0 + (c[k - 1] if k else 0.0)
        c[k] = -1.0 / den; d[k] = (rhs + (d[k - 1] if k else 0.0)) / den
    v = u[:]; v[hi - 1] = d[n - 1]
    for k in range(n - 2, -1, -1): v[lo + 1 + k] = d[k] - c[k] * v[lo + 2 + k]
    return v
def err(u): return max(abs(u[j] - j / 100) for j in range(101))
u0 = [0.0] * 100 + [1.0]
for ia, ib in [(40, 60), (45, 55), (49, 51), (50, 50)]:
    u, es = u0[:], [err(u0)]
    for k in range(20): u = piece(piece(u, 0, ib), ia, 100); es.append(err(u))
    g = gcd(ia * (100 - ib), ib * (100 - ia)); rho = ia * (100 - ib) / (ib * (100 - ia))
    assert abs(es[10] / es[9] - rho) < 1e-9  # the proved factor against the run
    print(f"1d,overlap={(ib - ia) / 100:.2f},factor={ia * (100 - ib) // g}/{ib * (100 - ia) // g}"
          f"={rho:.6f},observed={es[10] / es[9]:.6f},err_after_20={e3(es[20])}")
    if ia == 40: first = es[:5]
print("1d,max_error_after_sweeps_0_to_4," + ",".join(f"{e:.6f}" for e in first))
assert abs(first[1] - 0.4) < 1e-12 and abs(first[4] - 0.4 * (4 / 9) ** 3) < 1e-12
u, fig = u0[:], []
for k in range(2):
    u = piece(u, 0, 60); fig.append(u[40]); u = piece(u, 40, 100); fig.append(u[60])
print("figure,u(0.4)_then_u(0.6)_after_each_half_sweep," + ",".join(f"{v:.6f}" for v in fig))
def additive(u, k):  # additive form as a plain iteration: both pieces at once, k steps
    for _ in range(k): v1, v2 = piece(u, 0, 60), piece(u, 40, 100); u = [u[j] + (v1[j] - u[j]) + (v2[j] - u[j]) for j in range(101)]
    return u
ea = [err(additive(u0, k)) for k in range(1, 21)]  # from u = 0 the error stays a straight line across the overlap
s1, s20 = (additive([j / 100 + (j == 50) for j in range(101)], k)[50] - 0.5 for k in (1, 20))  # exact line + spike at x = 0.5
print(f"1d,additive_iteration,err_after_20={e3(ea[19])},observed_factor={ea[10] / ea[9]:.6f},spike_at_0.5_after_1_and_20={s1:.6f},{s20:.6f}")
assert abs(ea[10] / ea[9] - 2 / 3) < 1e-9 and abs(s1 + 1) < 1e-12 and abs(s20 - 1) < 1e-12  # 2/3 on a straight line; -1 inside the overlap
e = [0.0] * 101; e[50] = 1.0  # Schur complement: unit push at the interface x = 0.5
S = 2.0 - piece(e, 0, 50)[49] - piece(e, 50, 100)[51]; gr = piece(u0, 50, 100)[51]
print(f"1d,schur,S={S:.6f},g={gr:.6f},u(0.5)={gr / S:.6f}")
assert abs(S - 2 / 50) < 1e-12 and abs(gr / S - 0.5) < 1e-12
n, F = 63, 3200.0  # plate: 63x63 inside nodes, h = 1/64 m; heater 0.375 to 0.625 m
N, h = n * n, 1.0 / 64
b = [h * h * F if 24 <= k // n + 1 <= 40 and 24 <= k % n + 1 <= 40 else 0.0 for k in range(N)]
def matvec(x):
    y = [4.0 * v for v in x]
    for k in range(N):
        i, j = divmod(k, n)
        if i: y[k] -= x[k - n]
        if i < n - 1: y[k] -= x[k + n]
        if j: y[k] -= x[k - 1]
        if j < n - 1: y[k] -= x[k + 1]
    return y
def dot(x, y):
    s = 0.0
    for a, c in zip(x, y): s += a * c
    return s
def chol(m, w, ent):  # banded Cholesky: L[r][t] holds L(r, r - w + t)
    L = [[0.0] * (w + 1) for _ in range(m)]
    for r in range(m):
        for d in range(min(w, r), -1, -1):
            Lr, Lc, s = L[r], L[r - d], ent(r, r - d)
            for t in range(w - d): s -= Lr[t] * Lc[t + d]
            Lr[w - d] = sqrt(s) if d == 0 else s / Lc[w]
    return L
def csolve(L, m, w, rhs):
    y = rhs[:]
    for r in range(m):
        for t in range(max(0, w - r), w): y[r] -= L[r][t] * y[r - w + t]
        y[r] /= L[r][w]
    for r in range(m - 1, -1, -1):
        y[r] /= L[r][w]
        for t in range(max(0, w - r), w): y[r - w + t] -= L[r][t] * y[r]
    return y
def grid_ent(ny):
    return lambda r, c: 4.0 if r == c else -1.0 if (c == r - 1 and r % ny) or c == r - ny else 0.0
def make_prec(P, ext, two_level):  # P x P squares, each grown by ext cells a side
    H, sub, ph = 64 // P, [], []
    for p in range(P * P):
        I = range(max(1, p // P * H - ext + 1), min(n, (p // P + 1) * H + ext - 1) + 1)
        J = range(max(1, p % P * H - ext + 1), min(n, (p % P + 1) * H + ext - 1) + 1)
        idx = [(i - 1) * n + j - 1 for i in I for j in J]
        sub.append((idx, len(J), chol(len(idx), len(J), grid_ent(len(J)))))
    for p in range(1, P if two_level else 1):  # bilinear hats on the inside corners
        for q in range(1, P):
            ph.append([((i - 1) * n + j - 1, (1 - abs(i - p * H) / H) * (1 - abs(j - q * H) / H))
                       for i in range(p * H - H + 1, p * H + H) for j in range(q * H - H + 1, q * H + H)])
    M, wts = len(ph), [[wt for _, wt in f] for f in ph]
    cols = [matvec([dict(f).get(k, 0.0) for k in range(N)]) for f in ph]
    A0 = [[dot(wts[r], [cols[c][k] for k, _ in ph[r]]) for c in range(M)] for r in range(M)]
    L0 = chol(M, M - 1, lambda r, c: A0[r][c])
    def prec(r):
        z = [0.0] * N
        for idx, w, L in sub:
            for k, v in zip(idx, csolve(L, len(idx), w, [r[k] for k in idx])): z[k] += v
        y = csolve(L0, M, M - 1, [dot(wts[m], [r[k] for k, _ in ph[m]]) for m in range(M)])
        for f, v in zip(ph, y):
            for k, wt in f: z[k] += wt * v
        return z
    return prec, max(len(s[0]) for s in sub), M
def pcg(prec, tol=1e-8):  # also returns kappa estimated from CG's own numbers (Lanczos)
    x, r = [0.0] * N, b[:]; z = prec(r); p = z[:]; rz = dot(r, z); bn = sqrt(dot(b, b)); al, be = [], []
    while sqrt(dot(r, r)) > tol * bn:
        Ap = matvec(p); al.append(rz / dot(p, Ap))
        x = [a + al[-1] * c for a, c in zip(x, p)]; r = [a - al[-1] * c for a, c in zip(r, Ap)]
        z = prec(r); rz2 = dot(r, z); be.append(rz2 / rz); p = [a + be[-1] * c for a, c in zip(z, p)]; rz = rz2
    m = len(al); dg = [1 / al[0]] + [1 / al[k] + be[k - 1] / al[k - 1] for k in range(1, m)]
    o2 = [be[k] / (al[k] * al[k]) for k in range(m - 1)]
    def below(t):  # Sturm count: eigenvalues of the Lanczos table below t
        q = dg[0] - t; c = 1 if q < 0 else 0
        for k in range(1, m): q = dg[k] - t - o2[k - 1] / q; c += 1 if q < 0 else 0
        return c
    def eig(i):
        lo, hi = 0.0, 8.0
        for _ in range(80):
            if below((lo + hi) / 2) > i: hi = (lo + hi) / 2
            else: lo = (lo + hi) / 2
        return lo
    return x, m, eig(0), eig(m - 1)
Lf = chol(N, n, grid_ent(n)); xd = csolve(Lf, N, n, b); mid = 31 * n + 31
rd = [a - c for a, c in zip(b, matvec(xd))]
print(f"plate,unknowns={N},direct_centre_K={xd[mid]:.4f},direct_rel_residual={e3(sqrt(dot(rd, rd) / dot(b, b)))}")
x, k, lo, hi = pcg(lambda r: r[:]); ex = 1 / tan(pi / 128) ** 2  # exact kappa: cot^2(pi h / 2)
print(f"plate,plain_cg,steps={k},kappa_est={hi / lo:.1f},closed_form={ex:.1f}"); assert abs(hi / lo - ex) < 1.0
st, kap = {}, {}
for lev, P, ext in [(1, 2, 4), (1, 4, 2), (1, 8, 1), (2, 2, 4), (2, 4, 2), (2, 8, 1), (2, 2, 1), (2, 4, 1)]:
    pr, big, M = make_prec(P, ext, lev == 2); x, k, lo, hi = pcg(pr); st[lev, P, ext] = k; kap[lev, P, ext] = hi / lo
    gap = max(abs(a - c) for a, c in zip(x, xd))
    print(f"plate,levels={lev},squares={P * P},H/delta={64 // P / (2 * ext):.0f},largest_piece={big},coarse={M},"
          f"steps={k},lmin={lo:.3f},lmax={hi:.3f},kappa_est={hi / lo:.1f},centre_K={x[mid]:.4f},gap={e3(gap)}")
    assert gap < 1e-7 * xd[mid]  # Schwarz-CG against the direct solve
assert kap[1, 8, 1] > 10 * kap[1, 2, 4] and kap[2, 8, 1] < 1.5 * kap[2, 2, 4] and st[1, 8, 1] > 3 * st[1, 2, 4]
assert kap[2, 2, 1] > kap[2, 4, 1] > kap[2, 8, 1]  # thinner overlap, larger H/delta, worse
xr, pr = [0.0] * N, make_prec(4, 2, False)[0]  # additive Schwarz as a plain iteration
for k in range(21):
    rr = [a - c for a, c in zip(b, matvec(xr))]; xr = [a + c for a, c in zip(xr, pr(rr))]
    if k % 10 == 0: print(f"plate,additive_iteration,squares=16,step={k},rel_residual={e3(sqrt(dot(rr, rr) / dot(b, b)))}")
assert sqrt(dot(rr, rr) / dot(b, b)) > 1e6
print("ALL CHECKS PASS")
