# Stochastic-local volatility -- the check behind the card.  Standard library only.
# Random numbers: a 64-bit linear congruential generator and Marsaglia's polar method.
# Normal CDF: Marsaglia's series.  Implied volatility: bisection.  All written out below.
from math import sqrt, log, exp, pi
S0, R, Q, T, SIG = 100.0, 0.05, 0.02, 1.0, 0.20           # house market: flat 20% surface
V0, TH, KA, XI, RHO = 0.04, 0.04, 2.0, 0.3, -0.7          # Heston anchor
NP, NS, T1 = 50000, 40, 0.5                               # paths, dates, forward-start reset
DT, CR, D, TAU, state = T / NS, sqrt(1.0 - RHO * RHO), exp(-R * T), T - T1, [0]
def unif():                                               # uniform on (-1, 1], 64-bit LCG
    state[0] = (state[0] * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
    return ((state[0] >> 11) + 1) * 2.0 ** -52 - 1.0
def normals():                                            # polar method: two independent normals
    while True:
        a, b = unif(), unif(); s = a * a + b * b
        if 0.0 < s < 1.0: f = sqrt(-2.0 * log(s) / s); return a * f, b * f
def ncdf(x):                                              # bell-curve area left of x
    if abs(x) > 9.0: return 0.0 if x < 0.0 else 1.0
    s, t, i = x, x, 1.0
    while True:
        i += 2.0; t *= x * x / i; s2 = s + t
        if s2 == s: return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
        s = s2
def bs(s, k, tau, vol, call=True):                        # Black-Scholes call; put by parity
    sd = vol * sqrt(tau); d1 = (log(s / k) + (R - Q) * tau) / sd + 0.5 * sd
    c = s * exp(-Q * tau) * ncdf(d1) - k * exp(-R * tau) * ncdf(d1 - sd)
    return c if call else c - s * exp(-Q * tau) + k * exp(-R * tau)
def ivol(price, s, k, tau, call=True):                    # bisection: price in, volatility out
    lo, hi = 0.01, 1.0
    for _ in range(50):
        mid = 0.5 * (lo + hi); lo, hi = (lo, mid) if bs(s, k, tau, mid, call) > price else (mid, hi)
    return 0.5 * (lo + hi)
def hat(s):                                               # coarse grid: nodes $40, $50, ..., $200
    x = (min(max(s, 40.0), 199.999999) - 40.0) / 10.0; return int(x), x - int(x)
def interp(lev, s):
    j, a = hat(s); return (1.0 - a) * lev[j] + a * lev[j + 1]
def node_avg(ss, ys):                                     # hat-weighted average of ys near each node
    num, den = [0.0] * 17, [0.0] * 17
    for s, y in zip(ss, ys):
        j, a = hat(s); num[j] += (1.0 - a) * y; den[j] += 1.0 - a; num[j + 1] += a * y; den[j + 1] += a
    return [num[j] / den[j] if den[j] >= 100.0 else None for j in range(17)], den
def leverage(ss, vp, passes):                             # L = SIG / sqrt(E[v | S]) on the nodes
    ev, den = node_avg(ss, vp)
    ok = [j for j in range(17) if ev[j] is not None]
    lev = [SIG / sqrt(ev[min(max(j, ok[0]), ok[-1])]) for j in range(17)]; first = lev[5]
    for _ in range(passes):                               # rescale: local average of L^2 v -> SIG^2
        m = node_avg(ss, [(l := interp(lev, s)) * l * v for s, v in zip(ss, vp)])[0]
        lev = [lev[j] * SIG / sqrt(m[j]) if m[j] is not None else 0.0 for j in range(17)]
        lev = [lev[min(max(j, ok[0]), ok[-1])] for j in range(17)]
    return lev, (den[5], ev[5], first, lev[5])
def calibrate(seed, passes):                              # particle method: refit L at every date
    state[0] = seed; ss, vs, table = [S0] * NP, [V0] * NP, []
    for k in range(NS):
        vp = [max(v, 0.0) for v in vs]; lev, info = leverage(ss, vp, passes); table.append(lev)
        if k == 20: node90 = info
        for i in range(NP):
            zv, zp = normals(); l = interp(lev, ss[i]); sv = sqrt(vp[i] * DT)
            ss[i] *= exp((R - Q - 0.5 * l * l * vp[i]) * DT + l * sv * (RHO * zv + CR * zp))
            vs[i] += KA * (TH - vp[i]) * DT + XI * sv * zv
    return table, node90
(LF, node90), LN = calibrate(1, 2), calibrate(1, 0)[0]
state[0] = 2; S = [[S0] * NP for _ in range(5)]; vs, I, V = [V0] * NP, [0.0] * NP, [0.0] * NP
for k in range(NS):          # fresh paths: 0 SLV, 1 no rescaling, 2 L from Heston's cloud, 3 Heston, 4 LV
    vp = [max(v, 0.0) for v in vs]
    if k == NS // 2: S1, I1, V1 = [s[:] for s in S], I[:], V[:]
    if k == 30:
        cond_slv = node_avg(S[0], [(l := interp(LF[k], s)) * l * v for s, v in zip(S[0], vp)])[0]
        cond_h = node_avg(S[3], vp)[0]
    lf, ln, lw = LF[k], LN[k], leverage(S[3], vp, 2)[0]
    for i in range(NP):
        zv, zp = normals(); w = vp[i]; sv = sqrt(w * DT); zs = RHO * zv + CR * zp
        l = interp(lf, S[0][i]); S[0][i] *= exp((R - Q - 0.5 * l * l * w) * DT + l * sv * zs)
        l = interp(ln, S[1][i]); S[1][i] *= exp((R - Q - 0.5 * l * l * w) * DT + l * sv * zs)
        l = interp(lw, S[2][i]); S[2][i] *= exp((R - Q - 0.5 * l * l * w) * DT + l * sv * zs)
        S[3][i] *= exp((R - Q - 0.5 * w) * DT + sv * zs)
        S[4][i] *= exp((R - Q - 0.5 * SIG * SIG) * DT + SIG * sqrt(DT) * zs)
        I[i] += sv * zv; V[i] += w * DT; vs[i] += KA * (TH - w) * DT + XI * sv * zv
def stats(xs):                                            # mean and standard error, summed in order
    m, s2, n = 0.0, 0.0, len(xs)
    for x in xs: m += x / n
    for x in xs: s2 += (x - m) * (x - m)
    return m, sqrt(s2 / (n - 1) / n)
C_T, P_T, FS = bs(S0, 100.0, T, SIG), bs(S0, 100.0, T, SIG, False), S0 * exp(-Q * T1) * bs(1.0, 1.0, TAU, SIG)
sd = SIG * sqrt(TAU); d1 = (R - Q) * TAU / sd + 0.5 * sd
print(f"house targets: call {C_T:.6f}  put {P_T:.6f}  forward-start {FS:.6f}\nforward-start by hand: d1 {d1:.6f}"
      f"  d2 {d1 - sd:.6f}  N(d1) {ncdf(d1):.6f}  N(d2) {ncdf(d1 - sd):.6f}\n  half-year call"
      f" {bs(S0, 100.0, TAU, SIG):.6f}  e^-q t1 {exp(-Q * T1):.6f}\nnode $90, t 0.50: weight {node90[0]:.1f}"
      f"  E[v|S] {node90[1]:.6f}  sqrt {sqrt(node90[1]):.6f}  L first {node90[2]:.4f}  L final {node90[3]:.4f}"
      f"\n  L final x 30% vol {node90[3] * 0.3:.4f}   L final x 10% vol {node90[3] * 0.1:.4f}")
def row(label, xs, p=2): print(f"{label:<30}" + " ".join(f"{x:6.{p}f}" for x in xs))
row("leverage L(S, t), S =", [10.0 * j for j in range(7, 14)], 0)
for k in (10, 20, 30): row(f"  t = {k * DT:.2f}  rescaled", LF[k][3:10])
row("  t = 0.75  node values only", LN[30][3:10])
row("fresh paths, t = 0.75, vol %", [10.0 * j for j in range(7, 14)], 0)
row("  Heston  sqrt E[v | S]", [100 * sqrt(c) for c in cond_h[3:10]])
row("  SLV  sqrt E[L^2 v | S]", [100 * sqrt(c) for c in cond_slv[3:10]])
print("one year     target  SLV by paths      SLV - LV same paths   vol %: SLV  Heston")
rows, fwd = {}, {}
for K, call in ((80.0, False), (90.0, False), (100.0, False), (100.0, True), (110.0, True), (120.0, True)):
    f = (lambda s: max(s - K, 0.0)) if call else (lambda s: max(K - s, 0.0))
    tgt, plain = bs(S0, K, T, SIG, call), stats([D * f(s) for s in S[0]])
    rw = rows[(K, call)] = [stats([D * (f(a) - f(b)) for a, b in zip(S[m], S[4])]) for m in range(4)]
    iv = [100 * ivol(tgt + rw[m][0], S0, K, T, call) for m in range(4)]; rw.append((tgt, iv))
    print(f"{'call' if call else 'put '} {K:5.0f}  {tgt:7.4f}  {plain[0]:7.4f} ± {plain[1]:.4f}   "
          f"{rw[0][0]:+.4f} ± {rw[0][1]:.4f}   {iv[0]:10.2f} {iv[3]:7.2f}")
mix_c, mix_f = [], []                                     # Heston, second road: condition on the variance path
for i in range(NP):
    I2, V2 = I[i] - I1[i], V[i] - V1[i]
    mix_c.append(bs(S0 * exp(RHO * I[i] - 0.5 * RHO * RHO * V[i]), 120.0, T, CR * sqrt(V[i] / T)))
    mix_f.append(S0 * exp(-Q * T1 + RHO * I1[i] - 0.5 * RHO * RHO * V1[i])
                 * bs(exp(RHO * I2 - 0.5 * RHO * RHO * V2), 1.0, TAU, CR * sqrt(V2 / TAU)))
hc, mc, mf = stats([D * max(s - 120.0, 0.0) for s in S[3]]), stats(mix_c), stats(mix_f)
fsp = [stats([D * max(S[m][i] - S1[m][i], 0.0) for i in range(NP)]) for m in (3, 4)]
print(f"Heston call 120       paths {hc[0]:.4f} ± {hc[1]:.4f}   mixing formula {mc[0]:.4f} ± {mc[1]:.4f}\n"
      f"Heston forward-start  paths {fsp[0][0]:.4f} ± {fsp[0][1]:.4f}   mixing formula {mf[0]:.4f} ± {mf[1]:.4f}\n"
      f"local-vol forward-start  paths {fsp[1][0]:.4f} ± {fsp[1][1]:.4f}")
print("forward start  LV exact    SLV, same paths     Heston, same paths   fwd vol %: LV   SLV  Heston")
for kk in (0.8, 0.9, 1.0, 1.1, 1.2):
    ex = S0 * exp(-Q * T1) * bs(1.0, kk, TAU, SIG)
    fw = fwd[kk] = [stats([D * (max(S[m][i] - kk * S1[m][i], 0.0) - max(S[4][i] - kk * S1[4][i], 0.0))
                           for i in range(NP)]) for m in (0, 3)]
    iv = [100 * ivol((ex + x) / (S0 * exp(-Q * T1)), 1.0, kk, TAU) for x in (0.0, fw[0][0], fw[1][0])]
    print(f"  k = {kk:.1f}    {ex:8.4f}   {ex + fw[0][0]:8.4f} ± {fw[0][1]:.4f}   "
          f"{ex + fw[1][0]:8.4f} ± {fw[1][1]:.4f}   {iv[0]:8.2f} {iv[1]:6.2f} {iv[2]:6.2f}")
a, b = rows[(100.0, True)], rows[(120.0, True)]
print("what breaks, priced against LV on the same paths   call 100 (vol %)          call 120 (vol %)")
for m, name in ((3, "pure Heston, L = 1"), (2, "L fitted to pure-Heston paths"), (1, "node values, no rescaling")):
    print(f"  {name:<34} {a[4][0] + a[m][0]:.4f} ± {a[m][1]:.4f} ({a[4][1][m]:.2f})   "
          f"{b[4][0] + b[m][0]:.4f} ± {b[m][1]:.4f} ({b[4][1][m]:.2f})")
assert abs(C_T - 9.227005508154) < 1e-9, "own normal CDF vs the house call"
assert abs(FS - 6.244873136513) < 1e-9, "forward-start closed form vs the house anchor"
for key, rw in rows.items(): assert abs(rw[0][0]) < 3 * rw[0][1], f"SLV must reprice {key} within 3 s.e."
assert abs(rows[(120.0, True)][3][0]) > 10 * rows[(120.0, True)][3][1], "without leverage Heston misses"
assert abs(rows[(100.0, True)][2][0]) > 3 * rows[(100.0, True)][2][1], "leverage from the wrong cloud misses"
assert abs(hc[0] - mc[0]) < 3 * hc[1], "Heston call: paths vs mixing formula"
assert abs(fsp[0][0] - mf[0]) < 3 * fsp[0][1], "Heston forward-start: paths vs mixing formula"
assert abs(fsp[1][0] - FS) < 3 * fsp[1][1], "local-vol forward-start: paths vs closed form"
assert fwd[1.1][1][0] + 3 * fwd[1.1][1][1] < fwd[1.1][0][0] < -3 * fwd[1.1][0][1], "SLV between LV and Heston"
assert max(abs(sqrt(cond_slv[j]) - SIG) for j in range(4, 9)) < 0.005, "fresh paths: E[L^2 v | S] = SIG^2"
print("ALL CHECKS PASS")
