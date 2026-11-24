# Model reduction -- the check behind the card. Standard library only.
# Room heated by a radiator: states are temperatures above the outside air (degC),
# x = (pipe water, radiator, room air, walls); input u = heat into the pipe (kW);
# output y = room air (degC). Time in minutes. Capacities in kW*min/degC, links in kW/degC.
import math
def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def tr(X): return [list(r) for r in zip(*X)]
def solve(M, b):                                  # Gaussian elimination, partial pivoting
    n = len(M); a = [M[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(a[r][c])); a[c], a[p] = a[p], a[c]
        for r in range(c + 1, n):
            f = a[r][c] / a[c][c]
            for k in range(c, n + 1): a[r][k] -= f * a[c][k]
    x = [0.0] * n
    for i in reversed(range(n)): x[i] = (a[i][n] - sum(a[i][k] * x[k] for k in range(i + 1, n))) / a[i][i]
    return x
def rank(M, tol=1e-9):                            # rows reduced one by one, relative tolerance
    a = [r[:] for r in M]; big = max(abs(v) for r in a for v in r); rk = 0
    for c in range(len(a[0])):
        p = max(range(rk, len(a)), key=lambda r: abs(a[r][c]), default=None)
        if p is None or abs(a[p][c]) < tol * big: continue
        a[rk], a[p] = a[p], a[rk]
        for r in range(rk + 1, len(a)):
            f = a[r][c] / a[rk][c]; a[r] = [a[r][k] - f * a[rk][k] for k in range(len(a[0]))]
        rk += 1
    return rk
def lyap(A, W):                                   # road 1: solve A X + X A^T + W = 0 as n*n equations
    n = len(A); M = [[0.0] * (n * n) for _ in range(n * n)]
    for i in range(n):
        for j in range(n):
            for k in range(n): M[i*n+j][k*n+j] += A[i][k]; M[i*n+j][i*n+k] += A[j][k]
    v = solve(M, [-W[i][j] for i in range(n) for j in range(n)]); return [v[i*n:(i+1)*n] for i in range(n)]
def gram_by_time(A, b, T, h=0.1):                 # road 2: X = integral of e^{At} b b^T e^{A^T t}, Simpson
    n = len(A); E = [[float(i == j) for j in range(n)] for i in range(n)]; term = [r[:] for r in E]
    for k in range(1, 30): term = [[v * h / k for v in r] for r in mm(term, A)]; E = [[E[i][j] + term[i][j] for j in range(n)] for i in range(n)]
    v = b[:]; X = [[0.0] * n for _ in range(n)]; N = int(round(T / h))
    for s in range(N + 1):
        w = (1 if s in (0, N) else 4 if s % 2 else 2) * h / 3
        X = [[X[i][j] + w * v[i] * v[j] for j in range(n)] for i in range(n)]; v = [sum(E[i][k] * v[k] for k in range(n)) for i in range(n)]
    return X
def chol(P):
    n = len(P); L = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            s = P[i][j] - sum(L[i][k] * L[j][k] for k in range(j)); L[i][j] = math.sqrt(s) if i == j else s / L[j][j]
    return L
def jacobi(S):                                    # eigenvalues and eigenvectors of a symmetric matrix
    n = len(S); S = [r[:] for r in S]; V = [[float(i == j) for j in range(n)] for i in range(n)]
    for _ in range(60):
        for p in range(n):
            for q in range(p + 1, n):
                th = 0.5 * math.atan2(2 * S[p][q], S[q][q] - S[p][p]); c, s = math.cos(th), math.sin(th)
                for M in (S, V):
                    for k in range(n): M[k][p], M[k][q] = c * M[k][p] - s * M[k][q], s * M[k][p] + c * M[k][q]
                for k in range(n): S[p][k], S[q][k] = c * S[p][k] - s * S[q][k], s * S[p][k] + c * S[q][k]
    o = sorted(range(n), key=lambda i: -S[i][i]); return [S[i][i] for i in o], [[V[k][i] for i in o] for k in range(n)]
def gain(A, b, c, w):                             # |G(jw)| from the real 2n system for (jwI - A) x = b
    n = len(A); M = [[-A[i][j] for j in range(n)] + [-w * (i == j) for j in range(n)] for i in range(n)]
    M += [[w * (i == j) for j in range(n)] + [-A[i][j] for j in range(n)] for i in range(n)]
    x = solve(M, b + [0.0] * n); return sum(c[i] * x[i] for i in range(n)), sum(c[i] * x[n + i] for i in range(n))
def room(Cp=0.1, Cr=1.0, Ca=1.0, Cw=50.0, Gpr=0.5, Gra=0.05, Gaw=0.4, Gwo=0.1, Gao=0.02):
    A = [[-Gpr/Cp, Gpr/Cp, 0, 0], [Gpr/Cr, -(Gpr+Gra)/Cr, Gra/Cr, 0], [0, Gra/Ca, -(Gra+Gaw+Gao)/Ca, Gaw/Ca], [0, 0, Gaw/Cw, -(Gaw+Gwo)/Cw]]
    return A, [1/Cp, 0, 0, 0], [0, 0, 1, 0]
def hsv(P, Q): L = chol(P); return [math.sqrt(max(e, 0)) for e in jacobi(mm(mm(tr(L), Q), L))[0]]
def gramians(A, b, c): return lyap(A, [[x * y for y in b] for x in b]), lyap(tr(A), [[x * y for y in c] for x in c])
def balance(A, b, c, P, Q):                       # z = T x with T P T^T = T^-T Q T^-1 = diag(sigma)
    L = chol(P); ev, V = jacobi(mm(mm(tr(L), Q), L)); s = [e ** 0.25 for e in ev]; n = len(A)
    Linv = [solve(L, [float(i == j) for i in range(n)]) for j in range(n)]; Linv = tr(Linv)
    T = [[s[i] * v for v in r] for i, r in enumerate(mm(tr(V), Linv))]; Ti = [[r[j] / s[j] for j in range(n)] for r in mm(L, V)]
    return mm(mm(T, A), Ti), [sum(T[i][k] * b[k] for k in range(n)) for i in range(n)], [sum(c[k] * Ti[k][j] for k in range(n)) for j in range(n)], T, Ti
def cut(A, b, c, r): return [row[:r] for row in A[:r]], b[:r], c[:r]
def worst(A1, b1, c1, A2, b2, c2):                # H-infinity norm of the difference: log sweep, then refine
    d = lambda w: math.hypot(*[g1 - g2 for g1, g2 in zip(gain(A1, b1, c1, w), gain(A2, b2, c2, w))])
    ws = [10 ** (-4 + 6 * k / 600) for k in range(601)]; k = max(range(601), key=lambda i: d(ws[i])); lo, hi = ws[max(k-1, 0)], ws[min(k+1, 600)]
    for _ in range(60):
        m1, m2 = lo + (hi - lo) * 0.382, lo + (hi - lo) * 0.618
        if d(m1) > d(m2): hi = m2
        else: lo = m1
    return max(d(0.0), d(lo)), (0.0 if d(0.0) >= d(lo) else lo)
def step(A, b, c, ts, dt=0.05):                   # RK4 on x' = A x + b u, u = 1 kW from t = 0
    n = len(A); x = [0.0] * n; f = lambda x: [sum(A[i][k] * x[k] for k in range(n)) + b[i] for i in range(n)]; out = []; t = 0.0
    for tt in ts:
        while t < tt - 1e-9:
            k1 = f(x); k2 = f([x[i] + dt/2 * k1[i] for i in range(n)]); k3 = f([x[i] + dt/2 * k2[i] for i in range(n)]); k4 = f([x[i] + dt * k3[i] for i in range(n)])
            x = [x[i] + dt/6 * (k1[i] + 2*k2[i] + 2*k3[i] + k4[i]) for i in range(n)]; t += dt
        out.append(sum(c[i] * x[i] for i in range(n)))
    return out
def dc(A, b, c): x = solve(A, b); return -sum(c[i] * x[i] for i in range(len(c)))
f4 = lambda v: " ".join(f"{x:.4f}" for x in v)
f6 = lambda v: " ".join(f"{x:.6f}" for x in v)
A, b, c = room(); n = 4
# ---- 1. Kalman decomposition: the 5-state draft adds the thermostat bulb (1 min lag), driven by the air, logged by nobody ----
A5 = [r + [0.0] for r in A] + [[0, 0, 1.0, 0, -1.0]]; b5 = b + [0.0]; c5 = c + [0.0]
cols, rows = [b5], [c5]                           # columns b, Ab, ..., A^4 b and rows c, cA, ..., cA^4
for _ in range(4): cols.append([sum(A5[i][k] * cols[-1][k] for k in range(5)) for i in range(5)]); rows.append([sum(rows[-1][k] * A5[k][j] for k in range(5)) for j in range(5)])
print(f"5-state draft: reachable rank {rank(tr(cols))}, seeable rank {rank(rows)}; bulb column of the seeable matrix: {f4([r[4] for r in rows])}")
P5, Q5 = gramians(A5, b5, c5); h5 = hsv(P5, Q5)
print(f"5-state Hankel singular values (degC/kW): {f6(h5)}")
assert rank(tr(cols)) == 5 and rank(rows) == 4 and h5[4] < 1e-6 * h5[0]
for w in (0.01, 0.1, 1.0):
    g4, g5 = gain(A, b, c, w), gain(A5, b5, c5, w); print(f"  w = {w} rad/min: |G| 4-state {math.hypot(*g4):.6f}, 5-state {math.hypot(*g5):.6f} degC/kW"); assert abs(g4[0]-g5[0]) + abs(g4[1]-g5[1]) < 1e-12
# ---- 2. the minimal 4-state room: time constants, Gramians two ways ----
D = [0.1, 1.0, 1.0, 50.0]; ev = jacobi([[A[i][j] * math.sqrt(D[i] / D[j]) for j in range(n)] for i in range(n)])[0]
print(f"time constants (min): {f4([-1 / e for e in ev])}")
P, Q = gramians(A, b, c); Pt, Qt = gram_by_time(A, b, 4000.0, 0.05), gram_by_time(tr(A), c, 4000.0, 0.05)
sig = hsv(P, Q); sig_t = hsv(Pt, Qt)
print(f"Hankel singular values (degC/kW), Lyapunov:      {f6(sig)}"); print(f"Hankel singular values (degC/kW), time integral: {f6(sig_t)}")
assert max(abs(x - y) for x, y in zip(sig, sig_t)) < 1e-6
print(f"reachability P diagonal: {f4([P[i][i] for i in range(n)])}"); print(f"seeability Q diagonal: {f4([Q[i][i] for i in range(n)])}")
# ---- 3. balance: both Gramians become diag(sigma) ----
Ab, bb, cb, T, Ti = balance(A, b, c, P, Q); Pb, Qb = gramians(Ab, bb, cb)
print(f"balanced P diagonal: {f6([Pb[i][i] for i in range(n)])}; largest off-diagonal {max(abs(Pb[i][j]) + abs(Qb[i][j]) for i in range(n) for j in range(n) if i != j):.6f}")
print(f"balanced b: {f4(bb)}; balanced c: {f4(cb)}")
assert max(abs(Pb[i][j] - Qb[i][j]) + abs(Pb[i][i] - sig[i]) for i in range(n) for j in range(n)) < 1e-8 and max(abs(bb[i] ** 2 - cb[i] ** 2) for i in range(n)) < 1e-8
# ---- 4. truncate to 2 states and check the bound ----
Ar, br, cr = cut(Ab, bb, cb, 2); err, werr = worst(A, b, c, Ar, br, cr); bound = 2 * (sig[2] + sig[3])
print(f"2-state model: A = [[{Ar[0][0]:.4f}, {Ar[0][1]:.4f}], [{Ar[1][0]:.4f}, {Ar[1][1]:.4f}]], b = ({f4(br)}), c = ({f4(cr)})")
leak = 0.4 * 0.1 / (0.4 + 0.1) + 0.02           # walls in series with the outside, plus the windows (kW/degC)
print(f"steady gain: full {dc(A, b, c):.4f}, 2-state {dc(Ar, br, cr):.4f} degC/kW; leak {leak:.4f} kW/degC, so 1/leak = {1 / leak:.4f}; 1.5 kW holds the air {1.5 * dc(A, b, c):.4f} degC above outside")
print(f"worst gain error {err:.4f} degC/kW at {werr:.4f} rad/min (a {2 * math.pi / werr:.1f} min cycle); lower limit sigma3 {sig[2]:.4f}; bound 2(sigma3 + sigma4) {bound:.4f}")
print(f"sigma3/sigma1 = {sig[2] / sig[0]:.4f}; for a 1.5 kW valve swing: error {1.5 * err:.4f} degC, bound {1.5 * bound:.4f} degC")
assert sig[2] - 1e-9 <= err <= bound and abs(1 / leak - dc(A, b, c)) < 1e-9
ts = list(range(0, 481, 40)); yf, yr = step(A, b, c, ts), step(Ar, br, cr, ts)
print("chart, minutes      " + " ".join(f"{t:7d}" for t in ts)); print("chart, full 4-state " + " ".join(f"{v:7.3f}" for v in yf)); print("chart, 2-state      " + " ".join(f"{v:7.3f}" for v in yr))
fine = list(range(0, 481)); d = max(abs(u - v) for u, v in zip(step(A, b, c, fine), step(Ar, br, cr, fine))); yF, yR = step(A, b, c, [8000])[0], step(Ar, br, cr, [8000])[0]
print(f"largest step gap in the first 8 h: {d:.4f} degC; after 8000 min: full {yF:.4f}, 2-state {yR:.4f}, gap {yR - yF:.4f} degC")
assert abs(yF - dc(A, b, c)) < 1e-3 and abs((yR - yF) - (dc(Ar, br, cr) - dc(A, b, c))) < 1e-3 and d < err
# ---- 5. what breaks ----
An, bn, cn = [[A[i][j] for j in (2, 3)] for i in (2, 3)], [0.0, 0.0], [1.0, 0.0]; en, _ = worst(A, b, c, An, bn, cn); print(f"keep air and walls as they stand: worst gain error {en:.4f} degC/kW (the heat input lands on the dropped pipe)"); assert abs(en - dc(A, b, c)) < 1e-6
evP, VP = jacobi(P); W = [[VP[i][k] for k in range(2)] for i in range(n)]
Ap = mm(mm(tr(W), A), W); bp = [sum(W[i][k] * b[i] for i in range(n)) for k in range(2)]; cp = [sum(c[i] * W[i][k] for i in range(n)) for k in range(2)]
ep, _ = worst(A, b, c, Ap, bp, cp); print(f"keep the 2 most reachable directions only: worst gain error {ep:.4f} degC/kW, steady gain {dc(Ap, bp, cp):.4f}"); assert ep > bound
A1, b1, c1 = cut(Ab, bb, cb, 1); e1, _ = worst(A, b, c, A1, b1, c1); print(f"truncate to 1 state: worst error {e1:.4f}, bound {2 * sum(sig[1:]):.4f} degC/kW")
A3, b3, c3 = cut(Ab, bb, cb, 3); e3, _ = worst(A, b, c, A3, b3, c3); print(f"truncate to 3 states: worst error {e3:.6f}, bound {2 * sig[3]:.6f} degC/kW"); assert e3 <= 2 * sig[3] + 1e-9 and e1 <= 2 * sum(sig[1:])
Ai, bi, ci = room(Gwo=0.0, Gao=0.0); g = [gram_by_time(Ai, bi, H)[2][2] for H in (1000.0, 2000.0, 4000.0)]
print(f"perfectly insulated room: P air entry over 1000, 2000, 4000 min = {f4(g)} (no limit: no Gramian)"); assert g[2] - g[1] > 1.9 * (g[1] - g[0]) > 0.6
for name, kw in (("walls 10 times lighter, Cw = 5", dict(Cw=5.0)), ("pipe link 10 times weaker, Gpr = 0.05", dict(Gpr=0.05)), ("radiator link doubled, Gra = 0.1", dict(Gra=0.1))):
    Av, bv, cv = room(**kw); sv = hsv(*gramians(Av, bv, cv)); print(f"try {name}: sigma {f4(sv)}, 2-state bound {2 * (sv[2] + sv[3]):.4f} degC/kW")
print("ALL CHECKS PASS")
