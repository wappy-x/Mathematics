# SVI smile fit -- the check behind the card.  Standard library only.  Card 1's crash market quotes
# seven one-year strikes; SVI is fitted by two roads, then tested for butterfly arbitrage and Lee's bound.
from math import log, sqrt, exp, pi, tanh

def N(x):                         # normal CDF from its own series, as on card 1
    if abs(x) > 9.0: return 1.0 if x > 0 else 0.0
    y = abs(x) / sqrt(2.0); term = y; s = y; n = 0
    while term > 1e-17 * s:
        n += 1; term *= 2.0 * y * y / (2 * n + 1); s += term
    e = 2.0 / sqrt(pi) * exp(-y * y) * s
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

S, r, q, T = 100.0, 0.05, 0.02, 1.0
F, D = S * exp((r - q) * T), exp(-r * T)
MIX = [(0.12, 0.70 * F, 0.40), (0.88, (F - 0.12 * 0.70 * F) / 0.88, 0.15)]   # card 1's crash market
def b76(f, K, v):                 # call on forward f, total standard deviation v
    d1 = (log(f / K) + 0.5 * v * v) / v
    return D * (f * N(d1) - K * N(d1 - v))
def mix(K): return sum(p * b76(f, K, s * sqrt(T)) for p, f, s in MIX)
def iv(C, K):                     # bisection: the vol whose Black-Scholes call costs C
    lo, hi = 1e-6, 3.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (lo, mid) if b76(F, K, mid * sqrt(T)) > C else (mid, hi)
    return 0.5 * (lo + hi)

FIT = [80.0, 90.0, 95.0, 100.0, 105.0, 110.0, 120.0]
ks = [log(K / F) for K in FIT]
vols = [iv(mix(K), K) for K in FIT]
ws = [v * v * T for v in vols]    # total variance = vol squared times time
def svi(p, k):
    a, b, rho, m, s = p
    return a + b * (rho * (k - m) + sqrt((k - m) ** 2 + s * s))
def sse(p): return sum((svi(p, k) - w) ** 2 for k, w in zip(ks, ws))
def solve(A, y):                  # Gaussian elimination with partial pivoting
    n = len(y); M = [A[i][:] + [y[i]] for i in range(n)]
    for c in range(n):
        piv = max(range(c, n), key=lambda i: abs(M[i][c])); M[c], M[piv] = M[piv], M[c]
        for i in range(c + 1, n):
            f = M[i][c] / M[c][c]
            for j in range(c, n + 1): M[i][j] -= f * M[c][j]
    x = [0.0] * n
    for i in reversed(range(n)): x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def lstsq(cols, y):               # normal equations: (X'X) beta = X'y
    return solve([[sum(u * v for u, v in zip(ci, cj)) for cj in cols] for ci in cols], [sum(u * v for u, v in zip(ci, y)) for ci in cols])

# road 1: for fixed (m, s) SVI is linear in (a, b*rho, b); search (m, s) on a shrinking grid
def inner(m, s):
    a, c, b = lstsq([[1.0] * 7, [k - m for k in ks], [sqrt((k - m) ** 2 + s * s) for k in ks]], ws)
    return (a, b, c / b, m, s)
p1, cm, cs, hm, hs = None, 0.0, 0.3, 0.5, 0.29
for _ in range(60):
    for i in range(-5, 6):
        for j in range(-5, 6):
            p = inner(cm + hm * i / 5, cs + hs * j / 5)
            if p1 is None or sse(p) < sse(p1): p1 = p
    cm, cs, hm, hs = p1[3], p1[4], hm * 0.6, hs * 0.6
# road 2: Levenberg-Marquardt on all five at once; b = e^u1, rho = tanh(u2), s = e^u4 keep them legal
def P5(u): return (u[0], exp(u[1]), tanh(u[2]), u[3], exp(u[4]))
def res(u): return [svi(P5(u), k) - w for k, w in zip(ks, ws)]
u, lam = [0.03, log(0.1), 0.0, 0.0, log(0.1)], 1e-3
while lam < 1e12:
    R = res(u); J = []
    for j in range(5):
        uu = u[:]; uu[j] += 1e-7
        J.append([(x - y) / 1e-7 for x, y in zip(res(uu), R)])
    A = [[sum(x * y for x, y in zip(J[i], J[j])) * (1 + (lam if i == j else 0)) for j in range(5)] for i in range(5)]
    un = [x + d for x, d in zip(u, solve(A, [-sum(x * y for x, y in zip(J[i], R)) for i in range(5)]))]
    if sum(x * x for x in res(un)) < sum(x * x for x in R): u, lam = un, lam * 0.3
    else: lam *= 10
p2 = P5(u); a, b, rho, m, s = p1
print(f"forward F, discount e^-rT        {F:.6f} {D:.6f}")
print("crash market, crash then calm: weight, forward/F, vol  " + "  ".join(f"{p:.2f} {f / F:.4f} {v:.2f}" for p, f, v in MIX))
print("strike      k    market vol   total var w")
for K, k, v, w in zip(FIT, ks, vols, ws): print(f"{K:6.0f} {k:+8.4f} {100 * v:10.4f} {w:12.6f}")
for lab, p in (("road 1, grid + linear", p1), ("road 2, Levenberg-Marquardt", p2)):
    print(f"{lab:<28} a b rho m s  " + " ".join(f"{x:+.6f}" for x in p) + f"  sse {sse(p):.3e}")
print("strike  market   SVI    miss (vol points)")
miss = []
for K, k, v in zip(FIT, ks, vols):
    miss.append(100 * (sqrt(svi(p1, k) / T) - v)); print(f"{K:6.0f} {100 * v:8.4f} {100 * sqrt(svi(p1, k) / T):8.4f} {miss[-1]:+9.4f}")
hold = [(K, 100 * iv(mix(K), K), 100 * sqrt(svi(p1, log(K / F)) / T)) for K in (85.0, 115.0)]
for K, mv, sv in hold: print(f"held out {K:.0f}: market, SVI, miss  {mv:.4f} {sv:.4f} {sv - mv:+.4f}")
k90 = log(90.0 / F); rt = sqrt((k90 - m) ** 2 + s * s)          # the worked number at the 90 strike
print(f"at 90: k, k-m, root, bracket, w, vol  {k90:.6f} {k90 - m:.6f} {rt:.6f} {rho * (k90 - m) + rt:.6f} {svi(p1, k90):.6f} {100 * sqrt(svi(p1, k90) / T):.4f}")
root1 = sqrt(1 - rho * rho)
print(f"bottom: sqrt(1-rho^2), k*, w_min = a+b s sqrt(1-rho^2), vol  {root1:.6f} {m - rho * s / root1:.6f} {a + b * s * root1:.6f} {100 * sqrt((a + b * s * root1) / T):.4f}")
print(f"at the forward k = 0: w, vol     {svi(p1, 0.0):.6f} {100 * sqrt(svi(p1, 0.0) / T):.4f}")
print(f"1-rho, 1+rho; wing slopes b(1-rho), b(1+rho)   {1 - rho:.6f} {1 + rho:.6f}; {b * (1 - rho):.6f} {b * (1 + rho):.6f}   Lee's ceiling 2")
sl, sr = (svi(p1, -12.0) - svi(p1, -10.0)) / 2.0, (svi(p1, 12.0) - svi(p1, 10.0)) / 2.0
print(f"slopes measured, k -12..-10, 10..12  {sl:.6f} {sr:.6f}")
def g(p, k):                      # Gatheral's g: the implied density is g times a positive factor
    a, b, rho, m, s = p; w = svi(p, k); rt = sqrt((k - m) ** 2 + s * s)
    w1, w2 = b * (rho + (k - m) / rt), b * s * s / rt ** 3
    return (1 - k * w1 / (2 * w)) ** 2 - w1 * w1 / 4 * (1 / w + 0.25) + w2 / 2
def dens_g(p, K):                 # road A: density of S_T at K from g, no option prices
    k = log(K / F); w = svi(p, k)
    return g(p, k) * phi(-k / sqrt(w) - sqrt(w) / 2) / (sqrt(w) * K)
def dens_fd(p, K, h=0.01):        # road B: e^rT times the second difference of call prices
    c = lambda x: b76(F, x, sqrt(svi(p, log(x / F))))
    return (c(K + h) - 2 * c(K) + c(K - h)) / (h * h) / D
gmin = min((g(p1, -1.5 + 0.001 * i), -1.5 + 0.001 * i) for i in range(3001))
print(f"min g on k in [-1.5, 1.5], at k   {gmin[0]:.6f} {gmin[1]:+.3f}")
for K in (80.0, 100.0, 120.0): print(f"density at {K:.0f}, per $1: from g, from prices  {dens_g(p1, K):.6f} {dens_fd(p1, K):.6f}")
h = 14.0 / 6000; fk = lambda k, n: (F * exp(k)) ** (n + 1) * dens_g(p1, F * exp(k))   # Simpson on k in [-10, 4]
simp = lambda n: h / 3 * sum((1 if i in (0, 6000) else 4 if i % 2 else 2) * fk(-10.0 + i * h, n) for i in range(6001))
print(f"density total, mean (Simpson)    {simp(0):.6f} {simp(1):.6f}")
V = (-0.0410, 0.1331, 0.3060, 0.3586, 0.4153)   # Vogt's example, quoted by Gatheral and Jacquier
print("Vogt parameters a b rho m s       " + " ".join(f"{x:+.4f}" for x in V))
vmin = min((g(V, -1.5 + 0.001 * i), -1.5 + 0.001 * i) for i in range(3001)); Kv = F * exp(vmin[1])
print(f"Vogt: floor, min g, at k, K       {V[0] + V[1] * V[4] * sqrt(1 - V[2] ** 2):.6f} {vmin[0]:.6f} {vmin[1]:+.3f} {Kv:.2f}")
print(f"Vogt density at K, per $1 000 000: from g, from prices  {1e6 * dens_g(V, Kv):.4f} {1e6 * dens_fd(V, Kv):.4f}")
qa, qb, qc = lstsq([[1.0] * 7, ks, [k * k for k in ks]], ws); wq = lambda k: qa + qb * k + qc * k * k
print(f"wrong: parabola in k, w/|k| at k = -3, +3   {wq(-3.0) / 3:.4f} {wq(3.0) / 3:.4f}  SVI {svi(p1, -3.0) / 3:.4f} {svi(p1, 3.0) / 3:.4f}")
print(f"wrong: parabola vol at 40, SVI vol, market vol  {100 * sqrt(wq(log(40 / F))):.2f} {100 * sqrt(svi(p1, log(40 / F))):.2f} {100 * iv(mix(40.0), 40.0):.2f}")
print(f"wrong: k from spot, vol at 100, right vol  {100 * sqrt(svi(p1, log(100 / S))):.4f} {100 * sqrt(svi(p1, log(100 / F))):.4f}")
for lab, p in (("rho = 0", (a, b, 0.0, m, s)), ("b doubled", (a, 2 * b, rho, m, s)), ("s = 0.01", (a, b, rho, m, 0.01)), ("a + 0.01", (a + 0.01, b, rho, m, s))):
    print(f"try: {lab:<10} vol at 80/100/120  " + " ".join(f"{100 * sqrt(svi(p, log(K / F))):.2f}" for K in (80.0, 100.0, 120.0)))
grid, kg, sg = [80.0 + 5.0 * i for i in range(9)], [-1.0 + 0.25 * i for i in range(9)], [40.0 + 10.0 * i for i in range(13)]
mixd = lambda x: sum(p * phi((log(x / f) + 0.5 * v * v * T) / (v * sqrt(T))) / (v * sqrt(T) * x) for p, f, v in MIX)
print("chart, strike        " + " ".join(f"{K:6.0f}" for K in grid))
print("chart, market vol    " + " ".join(f"{100 * iv(mix(K), K):6.2f}" for K in grid))
print("chart, SVI vol       " + " ".join(f"{100 * sqrt(svi(p1, log(K / F))):6.2f}" for K in grid))
print("chart, k             " + " ".join(f"{k:6.2f}" for k in kg))
print("chart, 100 w, SVI    " + " ".join(f"{100 * svi(p1, k):6.2f}" for k in kg))
print("chart, 100 w, s = 0  " + " ".join(f"{100 * svi((a, b, rho, m, 0.0), k):6.2f}" for k in kg))
print("chart, S_T           " + " ".join(f"{x:5.0f}" for x in sg))
print("chart, SVI density   " + " ".join(f"{100 * dens_g(p1, x):5.2f}" for x in sg))
print("chart, market dens.  " + " ".join(f"{100 * mixd(x):5.2f}" for x in sg))
assert max(abs(x - y) for x, y in zip(p1, p2)) < 1e-6, "two fitting roads land on one parameter set"
assert max(abs(x) for x in miss) < 0.1 and all(abs(sv - mv) < 0.1 for _, mv, sv in hold), "within a tenth of a vol point"
assert all(abs(dens_g(p1, K) - dens_fd(p1, K)) < 1e-5 for K in (80.0, 100.0, 120.0)), "g road = price road"
assert abs(simp(0) - 1) < 1e-4 and abs(simp(1) - F) < 1e-2, "density sums to one and averages to the forward"
assert abs(sl - b * (1 - rho)) < 1e-3 and abs(sr - b * (1 + rho)) < 1e-3, "measured wing slopes match b(1 -/+ rho)"
hc = 1900.0 / 6000; cint = D * hc / 3 * sum((1 if i in (0, 6000) else 4 if i % 2 else 2) * i * hc * mixd(100.0 + i * hc) for i in range(6001))
assert abs(cint - mix(100.0)) < 1e-6, "call price by integrating the payoff against the market density"
assert gmin[0] > 0 and vmin[0] < 0 and dens_fd(V, Kv) < 0, "fit passes butterfly; Vogt fails it on both roads"
print("ALL CHECKS PASS")
