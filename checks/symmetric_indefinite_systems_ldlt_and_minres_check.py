# Saddle-point systems -- the check behind the card.  Standard library only; nothing imported holds an answer.  Water
# flows q (L/s) and heads h (m) solve [[R, E^T], [E, 0]] (q, h) = (g, d): symmetric, indefinite.  Several roads, compared.
from math import sqrt, log10; from functools import reduce
ALPHA, H = (1 + sqrt(17)) / 8, 60.0
def dot(u, v): return reduce(lambda s, t: s + t[0] * t[1], zip(u, v), 0.0)   # left to right, no compensation
def bk(a0, plain=False):           # Bunch-Kaufman: P A P^T = L D L^T, D made of 1x1 and 2x2 blocks
    n, a, k = len(a0), [r[:] for r in a0], 0; big0 = big = max(abs(v) for r in a0 for v in r)
    L, perm, blocks = [[float(i == j) for j in range(n)] for i in range(n)], list(range(n)), []
    def swap(i, j):                # rows AND columns together, so the matrix stays symmetric
        a[i], a[j], perm[i], perm[j] = a[j], a[i], perm[j], perm[i]
        for r in a: r[i], r[j] = r[j], r[i]
        for c in range(k): L[i][c], L[j][c] = L[j][c], L[i][c]
    while k < n:
        r = max(range(k + 1, n), key=lambda i: abs(a[i][k]), default=k); lam, s = abs(a[r][k]) if r > k else 0.0, 1
        if not plain and abs(a[k][k]) < ALPHA * lam:
            sig = max(abs(a[i][r]) for i in range(k, n) if i != r)
            if abs(a[k][k]) * sig >= ALPHA * lam * lam: pass           # keep the 1x1 pivot
            elif abs(a[r][r]) >= ALPHA * sig: swap(k, r)               # 1x1 pivot from row r
            else: s = 2; swap(k + 1, r)                               # 2x2 pivot on rows k, r
        if s == 1:
            for i in range(k + 1, n): L[i][k] = a[i][k] / a[k][k]
            blocks.append((a[k][k],))
        else:
            p, q, t = a[k][k], a[k + 1][k], a[k + 1][k + 1]; det = p * t - q * q
            for i in range(k + 2, n):
                L[i][k], L[i][k + 1] = (a[i][k] * t - a[i][k + 1] * q) / det, (a[i][k + 1] * p - a[i][k] * q) / det
            blocks.append((p, q, t))
        for i in range(k + s, n):
            for j in range(k + s, n):
                for c in range(k, k + s): a[i][j] -= L[i][c] * a[c][j]
                big = max(big, abs(a[i][j]))
        k += s
    return perm, L, blocks, big / big0
def bk_solve(perm, L, blocks, b):  # forward with L, then the blocks of D, back with L^T, undo P
    n, y, k = len(b), [b[p] for p in perm], 0
    for i in range(n): y[i] -= dot(L[i][:i], y[:i])
    for d in blocks:
        if len(d) == 1: y[k] /= d[0]
        else:
            det, y0 = d[0] * d[2] - d[1] * d[1], y[k]
            y[k], y[k + 1] = (d[2] * y0 - d[1] * y[k + 1]) / det, (d[0] * y[k + 1] - d[1] * y0) / det
        k += min(len(d), 2)
    for i in reversed(range(n)): y[i] -= dot([L[j][i] for j in range(i + 1, n)], y[i + 1:])
    return [y[perm.index(i)] for i in range(n)]
def inertia(D): return [sum(len(d) == 3 or d[0] * sg > 0 for d in D) for sg in (1, -1)]  # a 2x2 block: one of each
def minres(mv, b, tol, kmax, full=False):  # Lanczos plus one plane rotation a step; seven vectors kept (all, if full)
    n, b1, bet, cs, sn, dbar, eps, V = len(b), sqrt(dot(b, b)), 0.0, -1.0, 0.0, 0.0, 0.0, []
    v, vp, w, w2, x, phib, hist, tr = [t / b1 for t in b], [0.0] * n, [0.0] * n, [0.0] * n, [0.0] * n, b1, [1.0], [1.0]
    for k in range(kmax):
        p = mv(v); al = dot(v, p); p = [p[i] - al * v[i] - bet * vp[i] for i in range(n)]; V += [v] * full
        for u in V + V: c = dot(u, p); p = [p[i] - c * u[i] for i in range(n)]   # full: orthogonal to all, as in exact arithmetic
        bn = sqrt(dot(p, p)); oeps, delta, gbar = eps, cs * dbar + sn * al, sn * dbar - cs * al
        eps, dbar, gam = sn * bn, -cs * bn, sqrt(gbar * gbar + bn * bn)
        cs, sn = gbar / gam, bn / gam; phi, phib = cs * phib, sn * phib
        w1, w2 = w2, w; w = [(v[i] - oeps * w1[i] - delta * w2[i]) / gam for i in range(n)]
        x = [x[i] + phi * w[i] for i in range(n)]; hist.append(abs(phib) / b1); r = [s - t for s, t in zip(mv(x), b)]; tr.append(sqrt(dot(r, r)) / b1)
        if hist[-1] < tol or bn == 0.0: return x, hist, tr          # hist: the rotations' estimate; tr: b - A x recomputed
        vp, v, bet = v, [t / bn for t in p], bn
    return x, hist, tr
def cg(mv, b, tol, kmax):          # conjugate gradient, run where it has no guarantee
    n, x, r, p, neg, hist, rr = len(b), [0.0] * len(b), b[:], b[:], 0, [1.0], dot(b, b)
    for k in range(kmax):
        ap = mv(p); pap = dot(p, ap)
        if pap == 0.0: return x, hist, neg, k + 1          # breakdown: the step length divides by zero
        neg += pap < 0; al = rr / pap
        x, r = [x[i] + al * p[i] for i in range(n)], [r[i] - al * ap[i] for i in range(n)]
        rn = dot(r, r); hist.append(sqrt(rn / dot(b, b)))
        if hist[-1] < tol: break
        p = [r[i] + rn / rr * p[i] for i in range(n)]; rr = rn
    return x, hist, neg, 0
def chol_solve(a, b):              # Cholesky, as on the Cholesky card; None at the first pivot <= 0
    n, L, piv, y = len(a), [[0.0] * len(a) for _ in a], [], b[:]
    for j in range(n):
        piv.append(a[j][j] - dot(L[j][:j], L[j][:j]))
        if piv[-1] <= 0.0: return None, piv
        L[j][j] = sqrt(piv[-1])
        for i in range(j + 1, n): L[i][j] = (a[i][j] - dot(L[i][:j], L[j][:j])) / L[j][j]
    for i in range(n): y[i] = (y[i] - dot(L[i][:i], y[:i])) / L[i][i]
    for i in reversed(range(n)): y[i] = (y[i] - dot([L[j][i] for j in range(i + 1, n)], y[i + 1:])) / L[i][i]
    return y, piv
class Net:                         # pipe (a, b, r): a to b, r m per L/s; a = -1 is the reservoir at H
    def __init__(s, pipes, dem): s.pp, s.d, s.m, s.n, s.rhs = pipes, dem, len(pipes), len(pipes) + len(dem), [H if a < 0 else 0.0 for a, b, r in pipes] + dem
    def mv(s, v):                  # (R q + E^T h, E q), one pass over the pipes
        y, m = [0.0] * s.n, s.m
        for p, (a, b, r) in enumerate(s.pp):
            y[p] += r * v[p] + v[m + b]; y[m + b] += v[p]
            if a >= 0: y[p] -= v[m + a]; y[m + a] -= v[p]
        return y
    def dense(s): return [s.mv([float(i == j) for i in range(s.n)]) for j in range(s.n)]
    def nodal(s):                  # S h = E R^-1 g - d, S = E R^-1 E^T; then q = R^-1 (g - E^T h)
        S, t = [[0.0] * len(s.d) for _ in s.d], [-v for v in s.d]
        for a, b, r in s.pp:
            S[b][b] += 1 / r; t[b] += H / r if a < 0 else 0.0
            if a >= 0: S[a][a] += 1 / r; S[a][b] -= 1 / r; S[b][a] -= 1 / r
        h, piv = chol_solve(S, t)
        return [((H if a < 0 else h[a]) - h[b]) / r for a, b, r in s.pp] + h, piv
def grid(rows, cols):              # feeders into column 0, pipes along each row, then down each column
    ends = [(-1, i * cols) for i in range(rows)] + [(i * cols + j, i * cols + j + 1) for i in range(rows) for j in range(cols - 1)] + [
        (i * cols + j, i * cols + cols + j) for i in range(rows - 1) for j in range(cols)]
    u = [(k * 0.6180339887498949) % 1.0 for k in range(1, len(ends) + rows * cols + 1)]   # golden-ratio spread, illustrative
    return Net([(a, b, 0.01 + 0.01 * u[p] if a < 0 else 0.02 + 0.06 * u[p]) for p, (a, b) in enumerate(ends)], [0.5 + v for v in u[len(ends):]])
def sci(x): m, e = f"{x:.3e}".split("e"); return f"{m}e{int(e)}"
def gap(u, v): return max(abs(a - b) for a, b in zip(u, v))
def row(label, vals): print(f"{label:<38}" + "".join(f"{v:>11.6f}" for v in vals))
g1, g2 = 1 + 1 / ALPHA, 1 + 2 / (1 - ALPHA); row("alpha; growth: 1x1 step, 2x2 step, g1^2", [ALPHA, g1, g2, g1 * g1])
one = Net([(-1, 0, 0.0)], [20.0]); S2 = one.dense(); B1 = bk(S2); c1 = chol_solve(S2, one.rhs); x1 = bk_solve(*B1[:3], one.rhs)
print(f"one pipe: Cholesky pivot 1 = {c1[1][0]:.6f}; BK 2x2 det {B1[2][0][0] * B1[2][0][2] - B1[2][0][1] ** 2:.6f}, "
      f"inertia {inertia(B1[2])}, q, h = {x1[0]:.6f}, {x1[1]:.6f}")
brk = cg(one.mv, [H, 0.0], 1e-12, 5)[3]; xm, hm, _ = minres(one.mv, [H, 0.0], 1e-12, 5)
print(f"one pipe, demand 0: CG stops at step {brk}, p^T A p = 0; MINRES {len(hm) - 1} steps to q, h = {xm[0]:.6f}, {xm[1]:.6f}")
loop = Net([(-1, 0, 0.1), (0, 1, 0.3), (-1, 1, 0.4)], [20.0, 30.0])      # the LU card's loop, morning demand
A5 = loop.dense(); perm, L5, D5, gr5 = bk(A5); x5 = bk_solve(perm, L5, D5, loop.rhs); c5 = chol_solve(A5, loop.rhs)
row("loop: Cholesky pivots, then it stops", c5[1])
print("loop: order", " ".join(["q1", "q2", "q3", "h1", "h2"][p] for p in perm), "| D blocks", *("[" + " ".join(f"{v:.6f}" for v in d) + "]" for d in D5))
row("loop: last row of L; growth", L5[4] + [gr5]); row("loop: Bunch-Kaufman q1 q2 q3 h1 h2", x5)
q2 = (30 * 0.4 - 20 * 0.1) / (0.1 + 0.3 + 0.4); print(f"loop: inertia {inertia(D5)}; loop rule q2 = {q2:.6f}")
xm5, hm5, _ = minres(loop.mv, loop.rhs, 1e-12, 10); print("loop: MINRES residual by step", *map(sci, hm5), "| gap to BK", sci(gap(xm5, x5)))
tiny = Net([(-1, 0, 1e-13), (0, 1, 0.3), (-1, 1, 0.4)], [20.0, 30.0]); qt = (12 - 20e-13) / (1e-13 + 0.7) + 20   # r1 = 1e-13
xp, xb = [bk_solve(*bk(tiny.dense(), f)[:3], tiny.rhs) for f in (True, False)]; row("tiny r1: q1 by 1x1 order, BK, loop rule", [xp[0], xb[0], qt])
dis = grid(3, 20); Pd = bk(dis.dense()); xd = bk_solve(*Pd[:3], dis.rhs); xdm = minres(dis.mv, dis.rhs, 1e-10, 2000)[0]
print(f"district: {dis.m} pipes, n = {dis.n}; 2x2 pivots {sum(len(d) == 3 for d in Pd[2])}, inertia {inertia(Pd[2])}; growth "
      f"{sci(Pd[3])}, bound {sci(g1 ** (dis.n - 1))}; gap to MINRES {sci(gap(xd, xdm))}")
net = grid(13, 20); xn, pn = net.nodal(); nnz, ones = net.m + 2 * (2 * net.m - 13), [1.0] * net.n; step = 2 * nnz + 16 * net.n
print(f"network: {net.m} pipes, n = {net.n}, stored entries {nnz}; demand {dot(net.d, ones):.6f} L/s")
row("network: nodal pivots: smallest, largest", [min(pn), max(pn)]); print("network: inertia", [net.m, len(pn)])
xm, hm, tm = minres(net.mv, net.rhs, 1e-10, 3000); xc, hc, negc, _ = cg(net.mv, net.rhs, 1e-10, 3000)
res = [a - b for a, b in zip(net.mv(xm), net.rhs)]; rel = sqrt(dot(res, res) / dot(net.rhs, net.rhs))
print(f"network: MINRES {len(hm) - 1} steps, residual {sci(hm[-1])}, recomputed {sci(rel)}; gap to nodal {sci(gap(xm, xn))}, CG's {sci(gap(xc, xn))}")
row("network: heads min, max; reservoir L/s", [min(xm[net.m:]), max(xm[net.m:]), dot(xm[:13], ones)])
print(f"network: CG {len(hc) - 1} steps, {negc} negative p^T A p, worst residual {max(hc):.3f} times the start")
hf = minres(net.mv, net.rhs, 1e-10, 3000, True)[1]; print(f"network: recomputed residual rises {sum(b > a for a, b in zip(tm, tm[1:]))} times; with full reorthogonalisation MINRES needs {len(hf) - 1} steps, {len(hm) - len(hf)} fewer")
print(f"flops at n = {net.n}: dense BK {net.n ** 3 // 3:,}, LU {2 * net.n ** 3 // 3:,}; MINRES {step:,} a step, {step * (len(hm) - 1):,} in all")
for k in range(0, len(hm), 40): print(f"figure, step {k}, MINRES {log10(hm[k]):.2f}, CG {log10(hc[k]):.2f}")
assert abs(g1 * g1 - g2) < 1e-12 and abs(4 * ALPHA * ALPHA - ALPHA - 1) < 1e-15 and c1[0] is None and c5[0] is None and brk == 1
assert gap(x5, [32.5, 12.5, 17.5, 56.75, 53.0]) < 1e-12 and abs(x5[1] - q2) < 1e-12 and abs(xp[0] - qt) > 0.01 and abs(xb[0] - qt) < 1e-9
assert inertia(D5) == [3, 2] and inertia(Pd[2]) == [dis.m, dis.n - dis.m] and min(pn) > 0 and Pd[3] <= g1 ** (dis.n - 1)
assert all(d[0] * d[2] - d[1] ** 2 < 0 for d in D5 + Pd[2] if len(d) == 3)            # every 2x2 pivot: one + and one -
assert gap(xm5, x5) < 1e-10 and gap(xdm, xd) < 1e-7 and gap(xm, xn) < 1e-6 and abs(rel - hm[-1]) < 1e-12 and max(hc) > 1
assert all(b <= a * (1 + 1e-12) for a, b in zip(tm, tm[1:])) and abs(dot(xm[:13], ones) - dot(net.d, ones)) < 1e-6 and hf[-1] < 1e-10 < hf[-2] and len(hf) < len(hm)
print("ALL CHECKS PASS")
