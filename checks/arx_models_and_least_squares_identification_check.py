# ARX identification of the radiator room: the check behind the card.  Standard library only.
# Roads: normal equations vs Gram-Schmidt QR vs recursive least squares; the standard-error formula
# vs 200 simulated days; the bias closed form vs simulation; instrumental variables as the fix.
from math import sqrt, log, cos, pi
A, B, SE, SW, N = 0.9, 0.5, 0.1, 0.3, 1440  # true room; process and thermometer noise (degC); minutes
M64, state = 0xFFFFFFFFFFFFFFFF, [2026]     # 64-bit mask; SplitMix64 seed
def unif():
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 2.0**53
def gauss(): return sqrt(-2.0 * log(1.0 - unif())) * cos(2.0 * pi * unif())   # Box-Muller, cosine half only
def prbs(n):                                # 11-bit shift register, x^11 + x^9 + 1, period 2047
    reg, out = 0x7FF, []
    for _ in range(n):
        out.append(1.0 if reg & 1 else -1.0)
        reg = ((reg << 1) | (((reg >> 10) ^ (reg >> 8)) & 1)) & 0x7FF
    return out
def day(u):                                 # x: true room (good thermometer), ym: cheap thermometer
    x, ym = [0.0] * N, [0.0] * N
    for k in range(N):
        e, w = SE * gauss(), SW * gauss()
        if k > 0: x[k] = A * x[k - 1] + B * u[k - 1] + e
        ym[k] = x[k] + w
    return x, ym
def rows(y, u, na, nb, s, e):               # regressors phi_k = (y_k-1 .. y_k-na, u_k-1 .. u_k-nb), targets y_k
    return [[y[k - i] for i in range(1, na + 1)] + [u[k - i] for i in range(1, nb + 1)] for k in range(s, e)], y[s:e]
def solve(M, v):                            # Gaussian elimination with partial pivoting
    n = len(v); M = [M[i][:] + [v[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            M[r] = [M[r][j] - M[r][c] / M[c][c] * M[c][j] for j in range(n + 1)]
    th = [0.0] * n
    for i in range(n - 1, -1, -1):
        th[i] = (M[i][n] - sum(M[i][j] * th[j] for j in range(i + 1, n))) / M[i][i]
    return th
def gram(P, Z=None):                        # Z^T Phi; with Z = Phi it is the normal-equation matrix
    Z = Z or P
    return [[sum(z[i] * p[j] for z, p in zip(Z, P)) for j in range(len(P[0]))] for i in range(len(Z[0]))]
def zty(Z, t):   return [sum(z[i] * v for z, v in zip(Z, t)) for i in range(len(Z[0]))]
def ls(P, t):    return solve(gram(P), zty(P, t))              # road 1: normal equations
def iv(P, Z, t): return solve(gram(P, Z), zty(Z, t))           # instrumental variables
def qr_ls(P, t):                            # road 2: modified Gram-Schmidt QR, then back-substitution
    n = len(P[0]); Q = [[p[c] for p in P] for c in range(n)]; R = [[0.0] * n for _ in range(n)]
    for c in range(n):
        for j in range(c):
            R[j][c] = sum(a * b for a, b in zip(Q[j], Q[c])); Q[c] = [a - R[j][c] * b for a, b in zip(Q[c], Q[j])]
        R[c][c] = sqrt(sum(a * a for a in Q[c])); Q[c] = [a / R[c][c] for a in Q[c]]
    return solve(R, [sum(a * b for a, b in zip(Q[c], t)) for c in range(n)])
def rls(P, t):                              # road 3: recursive least squares, P0 = 1e6 I, no forgetting
    th, C = [0.0, 0.0], [[1e6, 0.0], [0.0, 1e6]]
    for f, v in zip(P, t):
        Cf = [C[i][0] * f[0] + C[i][1] * f[1] for i in range(2)]
        g = [c / (1.0 + f[0] * Cf[0] + f[1] * Cf[1]) for c in Cf]
        err = v - th[0] * f[0] - th[1] * f[1]
        th = [th[i] + g[i] * err for i in range(2)]
        C = [[C[i][j] - g[i] * Cf[j] for j in range(2)] for i in range(2)]
    return th
def resid(P, t, th): return [v - sum(a * b for a, b in zip(p, th)) for p, v in zip(P, t)]
def rms(r):          return sqrt(sum(v * v for v in r) / len(r))
def se(P, t, th):                           # standard errors: sigma_hat^2 times the diagonal of (Phi^T Phi)^-1
    r, n = resid(P, t, th), len(P[0]); s2 = sum(v * v for v in r) / (len(r) - n)
    return [sqrt(s2 * solve(gram(P), [1.0 * (j == i) for j in range(n)])[i]) for i in range(n)]
def whiteness(r):                           # residual autocorrelation, lags 1-20; count outside +-1.96/sqrt(N)
    s0 = sum(v * v for v in r); rho = [sum(r[k] * r[k - L] for k in range(L, len(r))) / s0 for L in range(1, 21)]
    return rho, sum(abs(p) > 1.96 / sqrt(len(r)) for p in rho)

u = prbs(N); x, ym = day(u)
print(f"valve PRBS: {sum(v > 0 for v in u)} minutes at 2.5 kW, {sum(v < 0 for v in u)} at 0.5 kW")
print("chart valve kW, min 0-60: " + " ".join(f"{1.5 + v:.1f}" for v in u[:61]))
print("chart room degC, min 0-60: " + " ".join(f"{20 + v:.2f}" for v in x[:61]))
P, t = rows(x, u, 1, 1, 1, N); G, g = gram(P), zty(P, t)
th, thq, thr, s = ls(P, t), qr_ls(P, t), rls(P, t), se(P, t, ls(P, t))
print(f"Phi^T Phi = [[{G[0][0]:.2f}, {G[0][1]:.2f}], [{G[1][0]:.2f}, {G[1][1]:.2f}]]  Phi^T y = [{g[0]:.2f}, {g[1]:.2f}]")
print(f"1 normal equations  a = {th[0]:.4f}  b = {th[1]:.4f}  (se {s[0]:.4f}, {s[1]:.4f})")
print(f"2 Gram-Schmidt QR   a = {thq[0]:.4f}  b = {thq[1]:.4f}")
print(f"3 recursive LS      a = {thr[0]:.4f}  b = {thr[1]:.4f}")
print(f"room: gain b/(1-a) = {th[1] / (1 - th[0]):.3f} degC/kW (true 5.000), lag -1/ln a = "
      f"{-1 / log(th[0]):.2f} min (true {-1 / log(A):.2f})")
assert abs(th[0] - A) < 0.01 and abs(th[1] - B) < 0.01
assert all(abs(p - q) < 1e-4 for p, q in zip(th + th, thq + thr))

# input design: one step against the PRBS, for a second-order model
us = [0.0] * 10 + [1.0] * (N - 10); xs, _ = day(us)
def pe(w):                                  # smallest eigenvalue of the 2x2 table of input lags 1 and 2 (Step 3)
    p, q, r = (sum(w[k - i] * w[k - j] for k in range(2, N)) / (N - 2) for i, j in ((1, 1), (2, 2), (1, 2)))
    return (p + q) / 2 - sqrt((p - q) * (p - q) / 4 + r * r)
P2, t2 = rows(xs, us, 2, 2, 2, N); th2 = ls(P2, t2); s2 = se(P2, t2, th2)
Pp, tp = rows(x, u, 2, 2, 2, N); thp = ls(Pp, tp); sp = se(Pp, tp, thp)
print(f"excitation, smallest eigenvalue: step {pe(us):.5f}, PRBS {pe(u):.4f}")
print(f"order 2 from the step: b1 = {th2[2]:.2f} +- {s2[2]:.2f}, b2 = {th2[3]:.2f} +- {s2[3]:.2f}, b1+b2 = {th2[2] + th2[3]:.3f}")
print(f"order 2 from the PRBS: b1 = {thp[2]:.3f} +- {sp[2]:.3f}, b2 = {thp[3]:.3f} +- {sp[3]:.3f}, a2 = {thp[1]:.3f}")
assert pe(us) < 0.01 and pe(u) > 0.9 and s2[2] > 10 * sp[2]

# order choice: fit on the first 12 hours, score on the last 12
print("order  train rms  valid rms  lags outside the whiteness band, of 20")
val = {}
for na, nb in [(0, 1), (1, 1), (2, 2), (3, 3), (4, 4)]:
    Pe, te = rows(x, u, na, nb, 4, 720); Pv, tv = rows(x, u, na, nb, 724, N); tho = ls(Pe, te)
    rv = resid(Pv, tv, tho); val[na] = rms(rv); out = whiteness(rv)[1]
    print(f"({na},{nb})   {rms(resid(Pe, te, tho)):.5f}    {val[na]:.5f}    {out}")
    if na == 1: th1, out1 = tho, out
    if na == 0: out0 = out
sim, err = [x[720]], []
for k in range(721, N): sim.append(th1[0] * sim[-1] + th1[1] * u[k - 1]); err.append(x[k] - sim[-1])
print(f"order 1, free run over the last 12 h: rms {rms(err):.3f} degC")
print("chart measured degC, min 720-780: " + " ".join(f"{20 + v:.2f}" for v in x[720:781]))
print("chart model degC, min 720-780: " + " ".join(f"{20 + v:.2f}" for v in sim[:61]))
assert val[1] < 1.01 * min(val[2], val[3], val[4]) and val[0] > 2 * val[1] and out1 <= 2 < out0

# coloured noise: the cheap thermometer on the same day
Pm, tm = rows(ym, u, 1, 1, 2, N); thm = ls(Pm, tm)
Zm = [[u[k - 2], u[k - 1]] for k in range(2, N)]; thi = iv(Pm, Zm, tm)
rho, outm = whiteness(resid(Pm, tm, thm))
vx = (B * B + SE * SE) / (1 - A * A); abar = A * vx / (vx + SW * SW)
print(f"cheap thermometer, LS: a = {thm[0]:.4f} b = {thm[1]:.4f}; gain {thm[1] / (1 - thm[0]):.3f} degC/kW, "
      f"lag {-1 / log(thm[0]):.2f} min")
print(f"  residual lag-1 correlation {rho[0]:.3f}, lags outside the band {outm} of 20")
print(f"  closed form: a -> 0.9 * {vx:.4f} / ({vx:.4f} + {SW * SW:.2f}) = {abar:.4f}")
print(f"  instrumental variables: a = {thi[0]:.4f} b = {thi[1]:.4f}")

# 200 more days: the spread of the white-noise fit, and the bias of the coloured one
ag, am, ai = [], [], []
for _ in range(200):
    xx, yy = day(u)
    P, t = rows(xx, u, 1, 1, 1, N); ag.append(ls(P, t)[0])
    P, t = rows(yy, u, 1, 1, 2, N); am.append(ls(P, t)[0]); ai.append(iv(P, Zm, t)[0])
mean, sd = (lambda v: sum(v) / len(v)), (lambda v: sqrt(sum((a - mean(v)) ** 2 for a in v) / (len(v) - 1)))
print(f"200 days, good thermometer: mean a {mean(ag):.4f}, spread {sd(ag):.4f} (formula {s[0]:.4f})")
print(f"200 days, cheap thermometer: LS mean a {mean(am):.4f} spread {sd(am):.4f} (closed form {abar:.4f})")
print(f"200 days, cheap thermometer: IV mean a {mean(ai):.4f} spread {sd(ai):.4f}")
print(f"try: thermometer noise 0.1 / 0.5 degC -> a {A * vx / (vx + 0.01):.4f} / {A * vx / (vx + 0.25):.4f}; "
      f"6 hours of data -> spread about {2 * s[0]:.4f}")
assert abs(sd(ag) / s[0] - 1) < 0.2 and abs(mean(am) - abar) < 0.005 and abs(mean(ai) - A) < 0.01 and outm > 3
state[0] = 2026; sq = [1.0 if k // 20 % 2 == 0 else -1.0 for k in range(N)]; Pq, tq = rows(day(sq)[0], sq, 2, 2, 2, N)
thw, sw = ls(Pq, tq), se(Pq, tq, ls(Pq, tq))  # the first day's noise again, with the valve on a 40-minute square wave
print(f"try: square wave of period 40 min -> smallest eigenvalue {pe(sq):.4f}; order 2: b1 = {thw[2]:.3f} +- {sw[2]:.3f}")
print("ALL CHECKS PASS")
