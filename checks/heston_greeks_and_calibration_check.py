# Heston Greeks and calibration -- the check behind the card.  Standard library only;
# cmath supplies complex arithmetic and nothing else.  Road 1: Lewis's integral on the
# line Im u = -1/2 (trapezoid, step 0.1).  Road 2: Gil-Pelaez on the real line (midpoint,
# step 0.2).  As xi -> 0 Heston must become Black-Scholes.  Greeks by integral and bumps.
from math import exp, log, sqrt, pi, cos, sin
from cmath import exp as cexp, log as clog, sqrt as csqrt

S, r, q = 100.0, 0.05, 0.02
KS, TS = [80.0, 90.0, 95.0, 100.0, 105.0, 110.0, 120.0], [0.25, 0.5, 1.0]
QV = [[28.61, 21.61, 19.05, 17.00, 15.39, 14.17, 12.69],      # the house surface,
      [27.43, 21.84, 19.73, 18.00, 16.59, 15.47, 13.95],      # implied vols in percent
      [27.79, 23.24, 21.48, 20.00, 18.76, 17.74, 16.22]]
ANCHOR, START_B = [0.04, 2.0, 0.04, 0.3, -0.7], [0.04, 6.0, 0.04, 0.9, -0.7]  # v0 kappa theta xi rho

def fingerprint(z, T, p):          # H, B and phi = exp(theta H + v0 B) for ln(S_T / F)
    v0, ka, th, xi, rho = p
    beta = ka - rho * xi * 1j * z
    d = csqrt(beta * beta + xi * xi * (1j * z + z * z))
    g, e = (beta - d) / (beta + d), cexp(-d * T)
    B = (beta - d) / (xi * xi) * (1 - e) / (1 - g * e)
    H = ka / (xi * xi) * ((beta - d) * T - 2 * clog((1 - g * e) / (1 - g)))
    return H, B, cexp(th * H + v0 * B)
def lewis(T, Ks, p, kind="price", s=S):    # road 1, and its derivatives under the integral
    F = s * exp((r - q) * T); ks = [log(K / F) for K in Ks]; tot = [0.0] * len(Ks)
    for i in range(3001):
        u = 0.1 * i; H, B, f = fingerprint(complex(u, -0.5), T, p)
        m = {"price": 1, "delta": 0.5 + 1j * u, "gamma": u * u + 0.25, "v0": B, "theta": H}[kind]
        g = (0.05 if i == 0 else 0.1) * m * f / (u * u + 0.25)
        for j, k in enumerate(ks): tot[j] += (g * complex(cos(u * k), -sin(u * k))).real
    c = [sqrt(F * K) * exp(-r * T) / pi * t for K, t in zip(Ks, tot)]
    if kind == "price": return [s * exp(-q * T) - x for x in c]
    if kind == "delta": return [exp(-q * T) - x / s for x in c]
    return [x / (s * s) for x in c] if kind == "gamma" else [-x for x in c]
def gil_pelaez(T, K, p):           # road 2: P1, P2, the density of S_T at K, and the price
    k = log(K / (S * exp((r - q) * T))); P1 = P2 = dens = 0.0
    for i in range(1500):
        u = 0.2 * (i + 0.5); w = complex(cos(u * k), -sin(u * k))
        f2, f1 = fingerprint(complex(u, 0.0), T, p)[2], fingerprint(complex(u, -1.0), T, p)[2]
        P1 += 0.2 * (w * f1 / (1j * u)).real; P2 += 0.2 * (w * f2 / (1j * u)).real; dens += 0.2 * (w * f2).real
    P1, P2 = 0.5 + P1 / pi, 0.5 + P2 / pi
    return P1, P2, dens / (pi * K), S * exp(-q * T) * P1 - K * exp(-r * T) * P2
def N(x):                          # normal CDF by Marsaglia's series
    if abs(x) > 8: return 1.0 if x > 0 else 0.0
    s = t = x; n = 1
    while abs(t) > 1e-17: t *= x * x / (2 * n + 1); s += t; n += 1
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * pi)
def bs(K, T, vol, what="price"):   # Black-Scholes call, its vega and its delta
    F, v = S * exp((r - q) * T), vol * sqrt(T); d1 = (log(F / K) + 0.5 * v * v) / v
    if what == "vega": return exp(-r * T) * F * exp(-0.5 * d1 * d1) / sqrt(2 * pi) * sqrt(T)
    return exp(-q * T) * N(d1) if what == "delta" else exp(-r * T) * (F * N(d1) - K * N(d1 - v))
def implied(price, K, T):          # bisection: a call's price rises with its vol
    lo, hi = 1e-4, 3.0
    for _ in range(100):
        mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if bs(K, T, mid) < price else (lo, mid)
    return 0.5 * (lo + hi)
MKT = [[bs(K, T, v / 100) for K, v in zip(KS, row)] for T, row in zip(TS, QV)]
VEGA = [[bs(K, T, v / 100, "vega") for K, v in zip(KS, row)] for T, row in zip(TS, QV)]
LO, HI = [1e-4, 0.05, 1e-4, 0.05, -0.999], [1.0, 20.0, 1.0, 5.0, 0.999]
def misses(p, prior):              # vol-point misses (price miss over vega), then the prior
    e = [100 * (c - m) / v for T, ms, vs in zip(TS, MKT, VEGA) for c, m, v in zip(lewis(T, KS, p), ms, vs)]
    return e + ([prior * (p[1] - 2.0)] if prior else [])
def solve(A, b):                   # Gaussian elimination on the damped normal equations
    n = len(b); M = [row[:] + [x] for row, x in zip(A, b)]
    for c in range(n):
        for i in range(c + 1, n):
            f = M[i][c] / M[c][c]; M[i] = [a - f * m for a, m in zip(M[i], M[c])]
    x = [0.0] * n
    for i in range(n - 1, -1, -1): x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def fit(p, tol, free=(0, 1, 2, 3, 4), prior=0.0):   # stop when a step gains < tol vol points
    p = list(p); e = misses(p, prior); L = sum(x * x for x in e); lam, steps = 1e-3, 0
    while steps < 200:
        J = []
        for i in free:
            pp = list(p); pp[i] += 1e-4
            J.append([(a - b) / 1e-4 for a, b in zip(misses(pp, prior), e)])
        A = [[sum(a * b for a, b in zip(Ji, Jj)) for Jj in J] for Ji in J]
        g = [-sum(a * b for a, b in zip(Ji, e)) for Ji in J]
        while lam < 1e8:
            d = solve([[a * (1 + lam) if i == j else a for j, a in enumerate(row)] for i, row in enumerate(A)], g)
            pn = list(p)
            for i, di in zip(free, d): pn[i] = min(max(p[i] + di, LO[i]), HI[i])
            en = misses(pn, prior); Ln = sum(x * x for x in en)
            if Ln < L: break
            lam *= 3
        else: break
        gain = sqrt(L / 21) - sqrt(Ln / 21); p, e, L, lam, steps = pn, en, Ln, lam / 3, steps + 1
        if gain < tol: break
    return p, sqrt(sum(x * x for x in e[:21]) / 21), steps
def show(label, xs, fmt="{:.6f}", tail=""): print(f"{label:<44}" + "  ".join(fmt.format(x) for x in xs) + tail)
def central(f, x, h): return (f(x + h) - f(x - h)) / (2 * h)
def dial(i, road, h=1e-4): return central(lambda y: road(ANCHOR[:i] + [y] + ANCHOR[i + 1:]), ANCHOR[i], h)
L1, G1 = (lambda p: lewis(1.0, [100.0], p)[0]), (lambda p: gil_pelaez(1.0, 100.0, p)[3])
spot = lambda s: lewis(1.0, [100.0], ANCHOR, s=s)[0]
C, dlt, gam, dv0, dth = (lewis(1.0, [100.0], ANCHOR, k)[0] for k in ("price", "delta", "gamma", "v0", "theta"))
P1, P2, dens, C2 = gil_pelaez(1.0, 100.0, ANCHOR)
iv = implied(C, 100.0, 1.0); bsd, bsv = bs(100.0, 1.0, iv, "delta"), bs(100.0, 1.0, iv, "vega")
skew = -bsv * central(lambda K: implied(lewis(1.0, [K], ANCHOR)[0], K, 1.0), 100.0, 0.1)   # K/S = 1
lim = [lewis(1.0, [100.0], [0.02, 2.0, 0.06, 1e-4, -0.7])[0], bs(100.0, 1.0, sqrt(0.06 - 0.02 * (1 - exp(-2.0))))]
print("house surface, percent; strikes " + " ".join(f"{K:.0f}" for K in KS))
for T, row in zip(TS, QV): show(f"  quotes, T = {T:.2f}", row, "{:.2f}")
print("one-year 100 call at the house anchor: v0 0.04, kappa 2, theta 0.04, xi 0.3, rho -0.7")
show("price: Lewis, Gil-Pelaez", [C, C2])
show("xi -> 0, v0 0.02, theta 0.06: Heston, BS", lim)
show("implied vol, percent", [100 * iv], "{:.4f}")
show("delta: integral, bump, e^-qT P1", [dlt, central(spot, 100.0, 0.01), exp(-q) * P1])
show("gamma: integral, bump, density road", [gam, (spot(100.01) - 2 * C + spot(99.99)) / 1e-4, exp(-r) * dens])
show("dC/dv0: integral, bump Lewis, bump G-P", [dv0, dial(0, L1), dial(0, G1)], "{:.5f}")
show("dC/dtheta: integral, bump Lewis, bump G-P", [dth, dial(2, L1), dial(2, G1)], "{:.5f}")
for i, name in ((1, "kappa"), (3, "xi"), (4, "rho")): show(f"dC/d{name}: bump Lewis, bump G-P", [dial(i, L1), dial(i, G1)])
show("Black-Scholes at that vol: delta, vega", [bsd, bsv])
show("skew -vega dsigma/dK, BS delta + it, slope", [skew, bsd + skew, -skew / bsv])
show("vega per vol point: v0, v0 and theta, BS", [0.4 * dv0 / 100, 0.4 * (dv0 + dth) / 100, bsv / 100], "{:.4f}")
print("fits to the 21 quotes: v0, kappa, theta, xi, rho | rms vol points | steps"); R = []
for name, st, tol, pr in (("A: anchor start", ANCHOR, 1e-3, 0), ("B: kappa, xi tripled", START_B, 1e-3, 0),
                          ("A, tolerance 1e-7", ANCHOR, 1e-7, 0), ("A with the prior", ANCHOR, 1e-3, 1),
                          ("B with the prior", START_B, 1e-3, 1)):
    R.append(fit(st, tol, prior=pr)); show(f"  {name}", R[-1][0] + [R[-1][1]], "{:.4f}", f"  {R[-1][2]}")
(pA, rA, _), (pB, rB, _), _, (pAp, _, _), (pBp, _, _) = R
vols = lambda p, T: [100 * implied(gil_pelaez(T, K, p)[3], K, T) for K in KS]
exact = lambda p: sqrt(sum((a - b) ** 2 for T, row in zip(TS, QV) for a, b in zip(vols(p, T), row)) / 21)
show("rms by road 2 and bisection: A, B", [exact(pA), exact(pB)], "{:.4f}")
for nm, p, T in [("A", pA, 0.25)] + [("B", pB, T) for T in TS]: show(f"fit {nm}, T = {T:.2f} vols", vols(p, T), "{:.2f}")
three = [gil_pelaez(3.0, 100.0, p)[3] for p in (pA, pB, pAp, pBp)]
show("3-year 100 call: A, B, A prior, B prior", three, "{:.4f}")
show("  its implied vol, percent", [100 * implied(c, 100.0, 3.0) for c in three], "{:.2f}")
show("A - B: kappa, rms, 3y call; prior kappa, 3y", [pA[1] - pB[1], rA - rB, three[0] - three[1], pAp[1] - pBp[1], three[2] - three[3]], "{:.4f}")
for name, p in (("A", pA), ("B", pB)): show(f"1-year dC/dv0, dC/dtheta: fit {name}", [lewis(1.0, [100.0], p, k)[0] for k in ("v0", "theta")], "{:.4f}")
show("Feller 2 kappa theta, xi^2: fit B", [2 * pB[1] * pB[2], pB[3] ** 2], "{:.4f}")
print("kappa held fixed, the other four fitted: kappa | rms | xi | theta")
prof = [fit(pB[:1] + [ka] + pB[2:], 1e-5, free=(0, 2, 3, 4)) for ka in (0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0)]
for p, rms, _ in prof: show("  kappa fixed", [p[1], rms, p[3], p[2]], "{:.4f}")
show("chart: best miss by kappa, 2 decimals", [x[1] for x in prof], "{:.2f}")
assert abs(C - C2) < 1e-8 and abs(dlt - exp(-q) * P1) < 1e-8 and abs(lim[0] - lim[1]) < 1e-4   # roads agree
assert abs(gam - exp(-r) * dens) < 1e-9 and abs(central(spot, 100.0, 0.01) - dlt) < 1e-7        # gamma, delta
assert abs(dv0 - dial(0, G1)) < 1e-4 and abs(dth - dial(2, G1)) < 1e-4    # integral vs bumps, and bump roads:
assert all(abs(dial(i, L1) - dial(i, G1)) < 1e-7 for i in (1, 3, 4)) and abs(bsd + skew - dlt) < 1e-5 and skew > 0
assert abs(exact(pB) - rB) < 0.01 and abs(pA[1] - pB[1]) > 0.5 and abs(rA - rB) < 0.02 and three[0] - three[1] > 0.5
assert abs(pAp[1] - pBp[1]) < 0.05 and abs(three[2] - three[3]) < 0.05 and prof[6][1] - prof[2][1] > 0.05 > prof[4][1] - prof[2][1]
print("ALL CHECKS PASS")
