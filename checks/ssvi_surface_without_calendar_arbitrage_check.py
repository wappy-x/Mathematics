# SSVI surface -- the check behind the card.  Standard library only.  Power-law SSVI on a stylized at-the-money
# term structure, its arbitrage tests by two roads, SSVI fitted to the Acme quotes, and separate SVI slices.
from math import log, sqrt, exp, pi

def N(x):                         # normal CDF from its own series, as on the SVI card
    if abs(x) > 9.0: return 1.0 if x > 0 else 0.0
    y = abs(x) / sqrt(2.0); term = y; s = y; n = 0
    while term > 1e-17 * s:
        n += 1; term *= 2.0 * y * y / (2 * n + 1); s += term
    e = 2.0 / sqrt(pi) * exp(-y * y) * s
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)

ETA, GAM, RHO = 1.0, 0.5, -0.7    # power law phi(theta) = eta * theta^-gamma, one skew number rho
def theta(t): return 0.04 * t     # stylized at-the-money total variance: 20% vol at the forward at every expiry
def phi(th, eta=ETA, gam=GAM): return eta * th ** -gam
def ssvi(k, th, rho=RHO, eta=ETA, gam=GAM):
    x = phi(th, eta, gam) * k
    return th / 2 * (1 + rho * x + sqrt((x + rho) ** 2 + 1 - rho * rho))
def g_ssvi(k, th, rho=RHO, eta=ETA, gam=GAM):     # Gatheral's g from w, w', w'' in closed form
    f = phi(th, eta, gam); R = sqrt((f * k + rho) ** 2 + 1 - rho * rho); w = ssvi(k, th, rho, eta, gam)
    w1, w2 = th * f / 2 * (rho + (f * k + rho) / R), th * f * f / 2 * (1 - rho * rho) / R ** 3   # w' and w''
    return (1 - k * w1 / (2 * w)) ** 2 - w1 * w1 / 4 * (1 / w + 0.25) + w2 / 2
def dw_dtheta(k, th, rho=RHO, gam=GAM):           # calendar road A: 1/2 [gam (h - x h') + (1 - gam) h]
    x = phi(th, gam=gam) * k; R = sqrt((x + rho) ** 2 + 1 - rho * rho)
    h, h1 = 1 + rho * x + R, rho + (x + rho) / R; return 0.5 * (gam * (h - x * h1) + (1 - gam) * h)
def call(k, w):                   # call per unit of forward, undiscounted: N(d1) - e^k N(d2)
    d1 = -k / sqrt(w) + sqrt(w) / 2; return N(d1) - exp(k) * N(d1 - sqrt(w))
def put(k, w): return call(k, w) - 1 + exp(k)     # put-call parity per unit of forward
def dens_g(k, w, g): return g * exp(-0.5 * (-k / sqrt(w) - sqrt(w) / 2) ** 2) / sqrt(2 * pi * w)
def dens_fd(wf, k, h=1e-3):       # butterfly road B: e^-k (c'' - c') from call prices alone
    c = lambda x: call(x, wf(x))
    c2, c1 = (c(k + h) - 2 * c(k) + c(k - h)) / h ** 2, (c(k + h) - c(k - h)) / (2 * h); return exp(-k) * (c2 - c1)

t6, t1 = theta(0.5), theta(1.0)
print(f"theta at 6 months, 1 year     {t6:.4f} {t1:.4f};  SSVI at k = 0 returns {ssvi(0, t6):.4f} {ssvi(0, t1):.4f}")
print(f"phi at 6 months, 1 year       {phi(t6):.4f} {phi(t1):.4f}")
sk = (ssvi(1e-5, t1) - ssvi(-1e-5, t1)) / 2e-5
print(f"1-year ATM skew dw/dk: rho*theta*phi, finite difference  {RHO * t1 * phi(t1):.6f} {sk:.6f}")
print(f"  as vol skew dsigma/dk = skew / (2 sigma t)  {sk / (2 * sqrt(t1)):.4f};  rho read back  {sk / (t1 * phi(t1)):.4f}")
lee, c2, cap = ETA * (1 + abs(RHO)), ETA ** 2 * (1 + abs(RHO)), (4 / (ETA * (1 + abs(RHO)))) ** 2; ub = (1 + sqrt(1 - RHO ** 2)) / RHO ** 2
print(f"butterfly: eta(1+|rho|) {lee:.4f} <= 2;  theta phi^2 (1+|rho|) {c2:.4f} <= 4")
print(f"  theta phi (1+|rho|) at 1 year {t1 * phi(t1) * (1 + abs(RHO)):.4f} < 4, holds while theta < {cap:.4f}, t < {cap / 0.04:.1f} years")
print(f"calendar: d(theta phi)/dtheta / phi = 1 - gamma = {1 - GAM:.4f}, inside [0, {ub:.4f}]")
for lab, th in (("6 months", t6), ("1 year", t1)):
    f = th * phi(th); sl, sr = f * (1 - RHO) / 2, f * (1 + RHO) / 2      # road 2: the slice's own slope far out
    assert abs(sl - ssvi(-1e3 - 1, th) + ssvi(-1e3, th)) < 1e-6 and abs(sr - ssvi(1e3 + 1, th) + ssvi(1e3, th)) < 1e-6, "wing slopes"
    assert abs(lee - 2 * max(sl, sr) / th ** (1 - GAM)) < 1e-9 and abs(c2 - th * phi(th) ** 2 * (1 + abs(RHO))) < 1e-9, "eta(1+|rho|) from the wing slopes"
    print(f"wing slopes {lab:<8} left theta phi (1-rho)/2, right (1+rho)/2  {sl:.4f} {sr:.4f}")
KG = [-1.5 + 0.01 * i for i in range(301)]; KW = [-3 + 0.001 * i for i in range(4501)]
gm, s2 = min((g_ssvi(k, th), k, th) for th in (t6, t1, 0.4, 2.0) for k in KG), 2.0 * phi(2.0) * (1 - RHO) / 2; lim = 0.25 - s2 * s2 / 16
print(f"min g over k in [-1.5, 1.5], theta in 0.02 0.04 0.4 2:  {gm[0]:.6f} at k {gm[1]:+.2f}, theta {gm[2]:.2f}")
print(f"  far left wing at theta 2: slope {s2:.4f}, g tends to 1/4 - slope^2/16 = {lim:.4f};  g at k -10000 {g_ssvi(-1e4, 2.0):.4f}")
for k in (-0.7, 0.0, 0.3):
    print(f"1-year density of k at {k:+.1f}: from g, from call prices  {dens_g(k, ssvi(k, t1), g_ssvi(k, t1)):.6f} {dens_fd(lambda x: ssvi(x, t1), k):.6f}")
TH = [0.005 * 1.25 ** j for j in range(25)]; dmin = min(dw_dtheta(k, th) for k in KG for th in TH)
fd = (ssvi(-0.7, 0.03 + 1e-6) - ssvi(-0.7, 0.03 - 1e-6)) / 2e-6
print(f"calendar: min dw/dtheta on the grid {dmin:.6f};  at k -0.7, theta 0.03: formula, difference  {dw_dtheta(-0.7, 0.03):.6f} {fd:.6f}")
fd3, cmin = (ssvi(-0.7, 0.03 + 1e-6, gam=0.3) - ssvi(-0.7, 0.03 - 1e-6, gam=0.3)) / 2e-6, min(ssvi(k, t1) - ssvi(k, t6) for k in KG)
print(f"  same at gamma 0.3 (u = {1 - 0.3:.1f}): formula, difference  {dw_dtheta(-0.7, 0.03, gam=0.3):.6f} {fd3:.6f};  u at gamma 1.2 {1 - 1.2:+.1f}")
print(f"calendar: min over k of w(1 year) - w(6 months)  {cmin:.6f}")
def solve(A, y):                  # Gaussian elimination with partial pivoting
    n = len(y); M = [A[i][:] + [y[i]] for i in range(n)]
    for c in range(n):
        piv = max(range(c, n), key=lambda i: abs(M[i][c])); M[c], M[piv] = M[piv], M[c]
        for i in range(c + 1, n):
            f = M[i][c] / M[c][c]; M[i][c:] = [u - f * v for u, v in zip(M[i][c:], M[c][c:])]
    x = [0.0] * n
    for i in reversed(range(n)): x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def svi(p, k): a, b, rho, m, s = p; return a + b * (rho * (k - m) + sqrt((k - m) ** 2 + s * s))
def bis(f, lo, hi):               # bisection: f changes sign once on [lo, hi]
    for _ in range(100): mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if f(mid) * f(hi) < 0 else (lo, mid)
    return 0.5 * (lo + hi)
def fit_svi(Q, T):                # nine quotes at $80..$120; spot 100, rate 5%, dividend yield 2%
    ks = [log((80 + 5 * i) / (100 * exp(0.03 * T))) for i in range(9)]; ws = [T * (v / 100) ** 2 for v in Q]
    sse = lambda p: sum((svi(p, k) - w) ** 2 for k, w in zip(ks, ws))
    def inner(m, s):              # SVI card's trick: for fixed (m, s) the fit is linear in (a, b rho, b)
        cols = [[1.0] * 9, [k - m for k in ks], [sqrt((k - m) ** 2 + s * s) for k in ks]]
        a, c, b = solve([[sum(u * v for u, v in zip(ci, cj)) for cj in cols] for ci in cols], [sum(u * v for u, v in zip(ci, ws)) for ci in cols])
        return (a, b, c / b, m, s)
    P, cm, cs, hm, hs = None, 0.0, 0.3, 0.5, 0.29
    for _ in range(60):
        for p in [inner(cm + hm * i / 5, cs + hs * j / 5) for i in range(-5, 6) for j in range(-5, 6) if cs + hs * j / 5 > 0]:
            if P is None or sse(p) < sse(P): P = p
        cm, cs, hm, hs = P[3], P[4], hm * 0.6, hs * 0.6
    return P, ks, max(abs(100 * sqrt(svi(P, k) / T) - v) for k, v in zip(ks, Q))
Q6 = [27.43, 24.38, 21.84, 19.73, 18.00, 16.59, 15.47, 14.60, 13.95]   # the surface card's 6-month row
QH = [27.79, 25.33, 23.24, 21.48, 20.00, 18.76, 17.74, 16.90, 16.22]   # the surface card's 1-year row
(P6, ks, miss), (PH, kh, missh), F6, F1 = fit_svi(Q6, 0.5), fit_svi(QH, 1.0), 100 * exp(0.03 * 0.5), 100 * exp(0.03)
P1 = (0.016719, 0.126769, -0.912282, -0.118207, 0.248954)    # the SVI card's 1-year fit, to its own crash-market quotes
print("6-month SVI a b rho m s  " + " ".join(f"{x:+.5f}" for x in P6) + f"  max miss {miss:.4f} vol points")
print(f"6-month SVI left slope b(1-rho) {P6[1] * (1 - P6[2]):.4f};  1-year SVI left slope {P1[1] * (1 - P1[2]):.4f}")
kx, KS = bis(lambda k: svi(P1, k) - svi(P6, k), -1.0, -0.3), bis(lambda K: svi(P1, log(K / F1)) - svi(P6, log(K / F6)), 40.0, 80.0)
K6, K1 = F6 * exp(kx), F1 * exp(kx)  # the crossing's strikes at the two expiries' own forwards
print(f"SVI slices cross at k {kx:.4f}: strikes {K6:.2f} (6 months), {K1:.2f} (1 year);  compared at the same strike instead {KS:.2f}")
qmin = min(svi(P1, k) - svi(P6, k) for k in [ks[0] + 0.001 * i for i in range(int((ks[-1] - ks[0]) / 0.001) + 1)])
print(f"inside the quoted range k {ks[0]:.4f} to {ks[-1]:.4f}: min w(1y) - w(6m) {qmin:.6f}")
def g_svi(p, k):                  # Gatheral's g for one raw SVI slice, closed form
    a, b, r, m, s = p; q = sqrt((k - m) ** 2 + s * s); w = svi(p, k); w1, w2 = b * (r + (k - m) / q), b * s * s / q ** 3
    return (1 - k * w1 / (2 * w)) ** 2 - w1 * w1 / 4 * (1 / w + 0.25) + w2 / 2
g6, g1, kn = min((g_svi(P6, k), k) for k in KG), min(g_svi(P1, k) for k in KG), [k for k in KW if g_svi(P6, k) < 0]; d6 = dens_fd(lambda x: svi(P6, x), g6[1])
print(f"SVI slices alone: min g 6m {g6[0]:.4f} at k {g6[1]:+.2f} (below 0 for k from {kn[0]:+.2f} to {kn[-1]:+.2f}), density from prices {d6:.4f}; min g 1y {g1:.4f}")
hg = min((svi(PH, k) - svi(P6, k), k) for k in KW); m1 = max(abs(100 * sqrt(svi(P1, k)) - v) for k, v in zip(kh, QH))
print(f"surface card's 1-year row, same fitter: max miss {missh:.4f}, left slope {PH[1] * (1 - PH[2]):.4f};  SVI card's 1-year curve misses it by up to {m1:.2f}")
print(f"  against the 6-month slice on k -3 to 1.5: min w(1y) - w(6m) {hg[0]:.6f} at k {hg[1]:+.2f};  at k -0.7 {svi(PH, -0.7) - svi(P6, -0.7):+.6f}")
th6, th1, ra = svi(P6, 0), svi(PH, 0), -0.5   # Acme's at-the-money total variances: each SVI fit read at k = 0
fq = lambda r: sum((ssvi(k, th, r) - T * (v / 100) ** 2) ** 2 for th, T, kq, Q in ((th6, 0.5, ks, Q6), (th1, 1.0, kh, QH)) for k, v in zip(kq, Q))
for h in (0.05, 0.005, 5e-4, 5e-5, 5e-6): ra = min((ra + h * i for i in range(-9, 10)), key=fq)   # one skew number, eta 1
mq = lambda r, a, b: " ".join(f"{max(abs(100 * sqrt(ssvi(k, th, r) / T) - v) for k, v in zip(kq, Q)):.2f}" for th, T, kq, Q in ((a, 0.5, ks, Q6), (b, 1.0, kh, QH)))
print(f"SSVI fitted to Acme: theta 6m, 1y {th6:.6f} {th1:.6f} (vols {100 * sqrt(th6 / 0.5):.2f}% {100 * sqrt(th1):.2f}%), rho {ra:.4f}, eta(1+|rho|) {ETA * (1 + abs(ra)):.4f}")
print(f"  max miss in vol points, 6m 1y: fitted SSVI {mq(ra, th6, th1)};  stylized SSVI {mq(RHO, t6, t1)}")
print(f"forwards 6m, 1y {F6:.2f} {F1:.2f};  1-year SVI b {P1[1]:.6f};  eta 1.5: eta(1+|rho|) {1.5 * (1 + abs(RHO)):.2f}, eta^2(1+|rho|) {1.5 ** 2 * (1 + abs(RHO)):.3f}")
k7 = -0.7; a6, a1, s6, s1 = svi(P6, k7), svi(P1, k7), ssvi(k7, t6), ssvi(k7, t1); fv = 100 * sqrt((s1 - s6) / 0.5)
print(f"at k -0.7: SVI w 6m, 1y, forward variance  {a6:.6f} {a1:.6f} {a1 - a6:+.6f}")
print(f"at k -0.7: SSVI w 6m, 1y, forward variance {s6:.6f} {s1:.6f} {s1 - s6:+.6f}, forward vol {fv:.2f}%")
print(f"at k -0.7: puts per unit forward, SVI 6m, 1y, spread  {put(k7, a6):.6f} {put(k7, a1):.6f} {put(k7, a1) - put(k7, a6):+.6f}")
print(f"at k -0.7: puts per unit forward, SSVI 6m, 1y, spread {put(k7, s6):.6f} {put(k7, s1):.6f} {put(k7, s1) - put(k7, s6):+.6f}")
hand = lambda th: " ".join(f"{v:.4f}" for v in (phi(th) * k7, RHO * phi(th) * k7, sqrt((phi(th) * k7 + RHO) ** 2 + 1 - RHO ** 2)))
print(f"by hand 6m: x = phi k, rho x, root  {hand(t6)};  1y: {hand(t1)}")
gb = min((g_ssvi(k, t1, eta=3.0), k) for k in KG); db = dens_fd(lambda x: ssvi(x, t1, eta=3.0), gb[1])
cb = min((ssvi(k, t1, gam=1.2) - ssvi(k, t6, gam=1.2), k) for k in KG)
print(f"wrong: eta 3, theta phi^2 (1+|rho|) {3.0 ** 2 * (1 + abs(RHO)):.2f}: min g at 1 year {gb[0]:.4f} at k {gb[1]:+.2f}, density from prices {db:.4f}")
print(f"wrong: gamma 1.2 (theta phi falls): min w(1y) - w(6m) {cb[0]:.6f} at k {cb[1]:+.2f}")
for lab, kw in (("rho -0.95", {"rho": -0.95}), ("eta 1.5", {"eta": 1.5}), ("gamma 0.3", {"gam": 0.3})):
    gt = min(g_ssvi(k, th, **kw) for th in (t6, t1) for k in KG)
    ct = min(ssvi(k, t1, **kw) - ssvi(k, t6, **kw) for k in KG)
    print(f"try: {lab:<10} min g {gt:.4f}  min w(1y) - w(6m) {ct:.6f}  vol at k -0.7, 1y {100 * sqrt(ssvi(k7, t1, **kw)):.2f}%")
KC = [-1.0 + 0.2 * i for i in range(8)]
print("chart, k              " + " ".join(f"{k:6.2f}" for k in KC))
for lab, fn in (("SVI 6m", lambda k: svi(P6, k)), ("SVI 1y", lambda k: svi(P1, k)), ("SVI 1y row", lambda k: svi(PH, k)), ("SSVI 6m", lambda k: ssvi(k, t6)), ("SSVI 1y", lambda k: ssvi(k, t1))):
    print(f"chart, 100 w {lab:<10}" + " ".join(f"{100 * fn(k):6.2f}" for k in KC))
assert abs(sk - RHO * t1 * phi(t1)) < 1e-6 and abs(ssvi(0, t1) - t1) < 1e-12 and miss < 0.05 and missh < 0.05 and fq(ra) < min(fq(ra - 1e-4), fq(ra + 1e-4)), "read-backs; fits tight; SSVI fit at a minimum"
assert all(abs(th - T * (Q[4] ** 2 + (Q[5] ** 2 - Q[4] ** 2) * kq[4] / (kq[4] - kq[5])) / 1e4) < 3e-4 for th, T, kq, Q in ((th6, 0.5, ks, Q6), (th1, 1.0, kh, QH))), "theta = straight line between the quotes either side of the forward"
assert lee <= 2 and c2 <= 4 and t1 * phi(t1) * (1 + abs(RHO)) < 4 and 0 <= 1 - GAM <= ub and abs(ub - 1 / (1 - sqrt(1 - RHO ** 2))) < 1e-12 and abs(cap * phi(cap) * (1 + abs(RHO)) - 4) < 1e-9, "Gatheral-Jacquier inequalities"
assert gm[0] > 0 and all(abs(dens_g(k, ssvi(k, t1), g_ssvi(k, t1)) - dens_fd(lambda x: ssvi(x, t1), k)) < 1e-4 for k in (-0.7, 0.0, 0.3)) and 0 < lim < gm[0] and abs(g_ssvi(-1e4, 2.0) - lim) < 1e-3, "g road = price road; far-wing limit"
assert dmin > 0 and cmin > 0 and abs(fd - dw_dtheta(-0.7, 0.03)) < 1e-6 and abs(fd3 - dw_dtheta(-0.7, 0.03, gam=0.3)) < 1e-6, "SSVI never crosses: formula and difference agree"
assert abs(svi(P1, kx) - svi(P6, kx)) < 1e-9 and a6 > a1 and qmin > 0 and g6[0] < 0 and abs(dens_g(g6[1], svi(P6, g6[1]), g6[0]) - d6) < 1e-4 and g1 > 0 and hg[0] > 0, "SVI slices cross; 6m slice has negative density; Acme's own 1-year row does not cross"
assert abs(svi(P6, log(K6 / F6)) - svi(P1, log(K1 / F1))) < 1e-9 and abs(svi(P1, log(KS / F1)) - svi(P6, log(KS / F6))) < 1e-9 and abs(s6 + 0.5 * (fv / 100) ** 2 - s1) < 1e-12, "crossing strikes; forward vol"
assert all(abs(put(k7, w) - exp(k7) * N(k7 / sqrt(w) + sqrt(w) / 2) + N(k7 / sqrt(w) - sqrt(w) / 2)) < 1e-12 for w in (a6, a1, s6, s1)) and gb[0] < 0 and db < 0 and cb[0] < 0, "puts: parity = direct formula; broken surfaces fail"
print("ALL CHECKS PASS")
