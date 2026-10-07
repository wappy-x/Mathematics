# Calibrating a market model. Roads: Levenberg-Marquardt, Nelder-Mead, Simpson, a Monte Carlo of the model.
from math import exp, expm1, log, sqrt, cos, sin, pi
D, T = 0.12, [float(i) for i in range(12)]        # fixed d; reset dates, forward i runs T[i] to T[i+1]
L = [0.030 + 0.002 * i for i in range(11)]        # today's one-year forward rates, 3.0% to 5.0%
P = [1.0]
for i in range(11): P.append(P[-1] / (1.0 + L[i]))     # discount factors P(0, T_i)
CAP = [0.2210, 0.2296, 0.2149, 0.2129, 0.1963, 0.1925, 0.1893, 0.1779, 0.1694, 0.1720]
SWP = [(1, 2, 0.2219), (1, 5, 0.1836), (1, 10, 0.1434), (2, 3, 0.2035), (2, 8, 0.1523),
       (3, 3, 0.1915), (3, 7, 0.1524), (5, 5, 0.1555), (6, 4, 0.1615), (8, 3, 0.1579)]
MADE = [0.08, 0.12, 0.60, 0.10]                   # the knobs the screen was manufactured from
def g(i, t, th): return (th[0] + th[1] * (T[i] - t)) * exp(-th[2] * (T[i] - t)) + D
def cross(i, j, e, th, d):                        # closed form: integral of g_i g_j from 0 to e
    a, b, c, m, n = th[0], th[1], th[2], [0.0] * 3, [0.0] * 3
    for mom, k in ((m, 2.0 * c), (n, c)):         # integrals of 1, s, s^2 times e^(-ks) on [0, e]
        mom[0] = -expm1(-k * e) / k; mom[1] = (mom[0] - e * exp(-k * e)) / k; mom[2] = (2.0 * mom[1] - e * e * exp(-k * e)) / k
    ai, aj, ei, ej = a + b * (T[i] - e), a + b * (T[j] - e), exp(-c * (T[i] - e)), exp(-c * (T[j] - e))
    return (ei * ej * (ai * aj * m[0] + b * (ai + aj) * m[1] + b * b * m[2])
            + d * (ei * (ai * n[0] + b * n[1]) + ej * (aj * n[0] + b * n[1])) + d * d * e)
def simpson(f, lo, hi, n=2000):                   # second integrator, no closed form used
    h = (hi - lo) / n
    return h / 3.0 * sum((1 if m in (0, n) else 4 if m % 2 else 2) * f(lo + m * h) for m in range(n + 1))
def mults(th, d, cap): return [0.0] + [cap[i - 1] * sqrt(T[i] / cross(i, i, T[i], th, d)) for i in range(1, 11)]
def cov(i, j, e, th, k, d): return exp(-th[3] * abs(T[i] - T[j])) * k[i] * k[j] * cross(i, j, e, th, d)
def swap(p, n): A = sum(P[i + 1] for i in range(p, p + n)); return A, sum(P[i + 1] * L[i] for i in range(p, p + n)) / A
def reb(p, n, th, k, d=D):                        # Rebonato's frozen-weight Black vol of the swaption
    A, S = swap(p, n); x = [P[i + 1] / A * L[i] for i in range(p, p + n)]
    return sqrt(sum(x[a] * x[b] * cov(p + a, p + b, T[p], th, k, d) for a in range(n) for b in range(n)) / (T[p] * S * S))
def resid(th): k = mults(th, D, CAP); return [100.0 * (reb(p, n, th, k) - u) for p, n, u in SWP]
def loss(th): return 0.5 * sum(e * e for e in resid(th)) if 0.05 < th[2] < 5.0 and 0.0 <= th[3] < 3.0 and th[0] > -D else float("inf")
def chol(c):                                      # lower-triangular r with r r' = c
    n = len(c); r = [[0.0] * n for _ in range(n)]
    for a in range(n):
        for b in range(a + 1):
            x = c[a][b] - sum(r[a][m] * r[b][m] for m in range(b)); r[a][b] = sqrt(x) if a == b else x / r[b][b]
    return r
def lm(th, lam=1e-3):                             # road one: Levenberg-Marquardt, slopes by bumping
    f, steps = loss(th), 0
    while steps < 100:
        e = resid(th); J = [[(x - y) / 1e-7 for x, y in zip(resid([th[q] + (1e-7 if q == r else 0.0) for q in range(4)]), e)] for r in range(4)]
        A = [[sum(J[r][m] * J[s][m] for m in range(10)) for s in range(4)] for r in range(4)]
        grad = [-sum(J[r][m] * e[m] for m in range(10)) for r in range(4)]
        while lam < 1e12:                         # damped step by Cholesky; a refused step triples the damping
            R, y, d = chol([[A[r][s] * (1.0 + lam if r == s else 1.0) for s in range(4)] for r in range(4)]), [0.0] * 4, [0.0] * 4
            for a in range(4): y[a] = (grad[a] - sum(R[a][m] * y[m] for m in range(a))) / R[a][a]
            for a in (3, 2, 1, 0): d[a] = (y[a] - sum(R[m][a] * d[m] for m in range(a + 1, 4))) / R[a][a]
            tn = [th[q] + d[q] for q in range(4)]; fn = loss(tn)
            if fn < f: break
            lam *= 3.0
        if fn >= f: break
        steps, lam, gain, th, f = steps + 1, lam / 3.0, f - fn, tn, fn
        if gain < 1e-13 * (1.0 + f): break
    return th, f, steps
def nelder(th, size=0.05):                        # road two: Nelder-Mead, no slopes at all
    pts = [th[:]] + [[th[q] + (size if q == r else 0.0) for q in range(4)] for r in range(4)]
    fs, evals = [loss(p) for p in pts], 5
    while max(fs) - min(fs) > 1e-13 * (1.0 + min(fs)) and evals < 20000:
        o = sorted(range(5), key=lambda m: fs[m]); pts, fs = [pts[m] for m in o], [fs[m] for m in o]
        tr = lambda s: [(pts[0][q] + pts[1][q] + pts[2][q] + pts[3][q]) / 4.0 * (1.0 - s) + s * pts[4][q] for q in range(4)]
        xr = tr(-1.0); fr = loss(xr); evals += 1
        if fr < fs[0]:
            xe = tr(-2.0); fe = loss(xe); evals += 1; pts[4], fs[4] = (xe, fe) if fe < fr else (xr, fr)
        elif fr < fs[3]: pts[4], fs[4] = xr, fr
        else:
            xc = tr(0.5 if fr >= fs[4] else -0.5); fc = loss(xc); evals += 1
            if fc < min(fr, fs[4]): pts[4], fs[4] = xc, fc
            else:                                 # shrink every corner halfway to the best one
                pts = [pts[0]] + [[0.5 * (pts[0][q] + p[q]) for q in range(4)] for p in pts[1:]]; fs = [fs[0]] + [loss(p) for p in pts[1:]]; evals += 4
    m = min(range(5), key=lambda m: fs[m]); return pts[m], fs[m], evals
M64, SEED = (1 << 64) - 1, [20260928]
def unif():                                       # splitmix64, top 53 bits, never exactly 0
    SEED[0] = (SEED[0] + 0x9E3779B97F4A7C15) & M64; z = SEED[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
def N(x):                                         # bell-curve area left of x, by its power series
    y, s, term, n = x / sqrt(2.0), 0.0, x / sqrt(2.0), 0
    while abs(term) > 1e-17 * (2 * n + 1): s += term / (2 * n + 1); n += 1; term *= -y * y / n
    return 0.5 + s / sqrt(pi)
def mc(th, k, pairs, steps=20):                   # road four: forwards 5..10 to year 5, year-11 bond as unit
    h, S0, out = 5.0 / steps, swap(5, 5)[1], []
    C = [[[cov(i, j, (s + 1) * h, th, k, D) - cov(i, j, s * h, th, k, D) for j in range(5, 11)] for i in range(5, 11)] for s in range(steps)]; R = [chol(c) for c in C]
    for _ in range(pairs):
        z, pay = [], [0.0, 0.0, 0.0]
        for _ in range(steps * 3):
            r, a = sqrt(-2.0 * log(unif())), 2.0 * pi * unif(); z += [r * cos(a), r * sin(a)]
        for sign in (1.0, -1.0):                  # antithetic pair: the same draws, sign flipped
            x = [log(L[i]) for i in range(5, 11)]
            for s in range(steps):                # log step: terminal-measure drift, exact covariance
                Lv, c = [exp(v) for v in x], C[s]
                x = [x[a] - sum(Lv[b] / (1.0 + Lv[b]) * c[a][b] for b in range(a + 1, 6)) - 0.5 * c[a][a]
                     + sign * sum(R[s][a][b] * z[6 * s + b] for b in range(a + 1)) for a in range(6)]
            grow = [1.0] * 7                      # grow[m] = P(5, T_5+m) / P(5, T_11)
            for m in (5, 4, 3, 2, 1, 0): grow[m] = grow[m + 1] * (1.0 + exp(x[m]))
            ann = sum(grow[1:6]); sw = (grow[0] - grow[5]) / ann
            pay = [pay[0] + 0.5 * max(exp(x[0]) - L[5], 0.0) * grow[1], pay[1] + 0.5 * ann * max(sw - S0, 0.0), pay[2] + 0.5 * ann * (sw - S0)]
        out.append(pay)
    mean = [sum(o[q] for o in out) / pairs for q in range(3)]
    cv = lambda q, r: sum((o[q] - mean[q]) * (o[r] - mean[r]) for o in out) / (pairs - 1)
    beta = cv(1, 2) / cv(2, 2)                    # control: the forward swap itself, worth exactly 0 today
    return P[11] * mean[0], P[11] * sqrt(cv(0, 0) / pairs), P[11] * (mean[1] - beta * mean[2]), P[11] * sqrt((cv(1, 1) - beta * cv(1, 2)) / pairs)
def implied(ratio, e, lo=1e-6, hi=2.0):           # ATM Black vol by bisection: 2N(u sqrt(e) / 2) - 1 = ratio
    for _ in range(100): mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if 2.0 * N(0.5 * mid * sqrt(e)) - 1.0 < ratio else (lo, mid)
    return 0.5 * (lo + hi)
th1, f1, n1 = lm([0.20, 0.05, 1.50, 0.40]); th2, f2, n2 = nelder([0.02, 0.30, 0.30, 0.02]); k = mults(th1, D, CAP)
print("caplet quotes 1y..10y        " + " ".join(f"{100 * x:.2f}" for x in CAP) + "\ncaplet multipliers k_1..k_10  " + " ".join(f"{x:.4f}" for x in k[1:]))
print("road 1 Levenberg-Marquardt a b c beta " + " ".join(f"{x:.6f}" for x in th1) + f"  loss {f1:.6f}  steps {n1}")
print("road 2 Nelder-Mead         a b c beta " + " ".join(f"{x:.6f}" for x in th2) + f"  loss {f2:.6f}  evals {n2}")
print(f"manufacturing knobs 0.08 0.12 0.60 0.10: loss {loss(MADE):.6f}  1y x 10y {100 * reb(1, 10, MADE, mults(MADE, D, CAP)):.2f}")
for p, n, u in SWP:
    v = reb(p, n, th1, k); print(f"swaption {p:>2}y x {n:>2}y  quote {100 * u:6.2f}  fit {100 * v:6.2f}  miss {100 * (v - u):+.2f}")
capmiss = max(abs(k[i] * sqrt(simpson(lambda t: g(i, t, th1) ** 2, 0.0, T[i]) / T[i]) - CAP[i - 1]) for i in range(1, 11))
one, ci, cs = reb(5, 1, th1, k), cross(3, 7, 3.0, th1, D), simpson(lambda t: g(3, t, th1) * g(7, t, th1), 0.0, 3.0)
big = [1.5 * th1[0], 1.5 * th1[1], th1[2], th1[3]]; kb = mults(big, 1.5 * D, CAP)
shift = max(abs(reb(p, n, big, kb, 1.5 * D) - reb(p, n, th1, k)) for p, n, _ in SWP)
print(f"caplets repriced through Simpson: largest miss {100 * capmiss:.10f} points   5y x 1y by Rebonato {100 * one:.6f}, caplet quote {100 * CAP[4]:.6f}")
print(f"cross integral, forwards 3 and 7, to year 3: closed form {ci:.8f}  Simpson {cs:.8f}   abcd all times 1.5: largest change {100 * shift:.10f}")
(A5, S5), r55 = swap(5, 5), reb(5, 5, th1, k); cmc, cse, smc, sse = mc(th1, k, 20000)
cbl, sbl = P[6] * L[5] * (2.0 * N(0.5 * CAP[4] * sqrt(5.0)) - 1.0), A5 * S5 * (2.0 * N(0.5 * r55 * sqrt(5.0)) - 1.0)
umc = implied(smc / (A5 * S5), 5.0); use = implied((smc + sse) / (A5 * S5), 5.0) - umc
print(f"MC 5y caplet, per 1 notional  {cmc:.6f} +/- {cse:.6f}   Black at the quote {cbl:.6f}")
print(f"MC 5y x 5y swaption           {smc:.6f} +/- {sse:.6f}   Rebonato price {sbl:.6f}")
print(f"MC implied vol {100 * umc:.2f} +/- {100 * use:.2f}   Rebonato {100 * r55:.2f}   gap {100 * (r55 - umc):+.2f} points")
(A, S), I = swap(1, 2), [cross(1, 1, 1.0, th1, D), cross(1, 2, 1.0, th1, D), cross(2, 2, 1.0, th1, D)]
x1, x2 = P[2] / A * L[1] * k[1], P[3] / A * L[2] * k[2]; tm = [x1 * x1 * I[0], 2.0 * x1 * x2 * exp(-th1[3]) * I[1], x2 * x2 * I[2]]
print(f"hand 1y x 2y: P(0,2) {P[2]:.6f}  P(0,3) {P[3]:.6f}  annuity {A:.6f}  w1 {P[2] / A:.6f}  w2 {P[3] / A:.6f}  S {100 * S:.6f}%")
print(f"hand: k1 {k[1]:.6f}  k2 {k[2]:.6f}  I11 {I[0]:.6f}  I12 {I[1]:.6f}  I22 {I[2]:.6f}  rho12 {exp(-th1[3]):.6f}")
print(f"hand: terms x 1e6 {1e6 * tm[0]:.6f} {1e6 * tm[1]:.6f} {1e6 * tm[2]:.6f}  sum {1e6 * (tm[0] + tm[1] + tm[2]):.6f}  S^2 x 1e6 {1e6 * S * S:.6f}")
kbar, (A1, S1) = sum(k[1:]) / 10.0, swap(1, 10)
print(f"break: one common multiplier {kbar:.4f}, largest caplet miss {100 * max(abs(kbar * sqrt(cross(i, i, T[i], th1, D) / T[i]) - CAP[i - 1]) for i in range(1, 11)):.2f} points")
print(f"break: 1y x 10y with beta = 0 (one factor) {100 * reb(1, 10, th1[:3] + [0.0], k):.2f}   with flat caplet vols {100 * reb(1, 10, [0.0, 0.0, 1.0, th1[3]], [0.0] + CAP, 1.0):.2f}")
print(f"break: 1y x 10y as weighted average of caplet vols {100 * sum(P[m + 2] * L[m + 1] * CAP[m] for m in range(10)) / (A1 * S1):.2f}")
print(f"try: beta = 0.30, 1y x 10y {100 * reb(1, 10, th1[:3] + [0.30], k):.2f}   5y caplet +1 point, 5y x 5y {100 * reb(5, 5, th1, mults(th1, D, CAP[:4] + [CAP[4] + 0.01] + CAP[5:])):.2f}")
for name, th in (("fitted", th1), ("made  ", MADE)): print(f"chart, 10y forward {name}   " + " ".join(f"{100 * mults(th, D, CAP)[10] * g(10, t, th):.2f}" for t in range(11)))
assert max(abs(x - y) for x, y in zip(th1, th2)) < 1e-5, "two optimisers, one minimum"
assert capmiss < 1e-10, "every caplet repriced exactly, checked with an integral the fit never used"
assert abs(ci - cs) < 1e-10, "closed-form cross integral against Simpson"
assert abs(one - CAP[4]) < 1e-12, "a one-period swaption must collapse to its caplet"
assert abs(cmc - cbl) < 3.0 * cse, "simulated caplet within three standard errors of Black"
assert abs(r55 - umc) < 0.0025, "Rebonato within a quarter of a vol point of the simulated model"
assert shift < 1e-12, "overall scale of abcd is invisible once the caplets set the multipliers"
print("ALL CHECKS PASS")
