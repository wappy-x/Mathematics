"""Beyond one factor: Hull-White against G2++, a Black-Derman-Toy tree, and negative rates. Standard library only."""
from math import exp, log, sqrt, cos, pi

KV, TH, SV, R0 = 0.3, 0.05, 0.01, 0.04                  # house curve: Vasicek, also Hull-White's a and sigma
A, B, SIG, ETA, RHO = 1.0, 0.08, 0.012, 0.007, -0.2     # G2++: fast factor, slow factor, their correlation
MATS = [float(u) for u in range(1, 11)]
def load(c, u):                                          # B_c(u) = (1 - e^(-c u)) / c
    return (1.0 - exp(-c * u)) / c
def simpson(f, lo, hi, n=2000):
    h = (hi - lo) / n
    return (f(lo) + f(hi) + sum((4 if k % 2 else 2) * f(lo + k * h) for k in range(1, n))) * h / 3.0
def P0(T):                                               # today's zero price on the house curve
    b = load(KV, T)
    return exp((TH - SV * SV / (2 * KV * KV)) * (b - T) - SV * SV * b * b / (4 * KV) - b * R0)
def cov(p, q, rho=RHO):
    return p[0] * q[0] + p[1] * q[1] + rho * (p[0] * q[1] + p[1] * q[0])
def corr(p, q, rho=RHO):
    return cov(p, q, rho) / sqrt(cov(p, p, rho) * cov(q, q, rho))
def yload(u, a=A, b=B, s=SIG, e=ETA):                    # how much a u-year yield moves per unit of each shock
    return (s * load(a, u) / u, e * load(b, u) / u)
def swap(n, x=0.0, y=0.0):                              # par rate of a swap from year 1 to year 1+n, factors shocked by x, y
    p = [P0(t) * exp(-load(A, t) * x - load(B, t) * y) for t in range(1, n + 2)]
    return (p[0] - p[n]) / sum(p[1:])
def swap_grad(n, c):                                     # d(swap rate)/d(factor with speed c), by the quotient rule
    p = [P0(t) for t in range(1, n + 2)]
    ann = sum(p[1:])
    num = (-load(c, 1) * p[0] + load(c, 1 + n) * p[n]) * ann
    num += (p[0] - p[n]) * sum(load(c, 1 + j) * p[j] for j in range(1, n + 1))
    return num / ann ** 2
def rng(seed):                                           # xorshift64, uniforms in (0, 1)
    s, M = seed, (1 << 64) - 1
    while True:
        s ^= (s << 13) & M; s ^= s >> 7; s ^= (s << 17) & M
        yield ((s >> 11) + 0.5) / 2.0 ** 53
def normals(g):
    while True:
        yield sqrt(-2.0 * log(next(g))) * cos(2.0 * pi * next(g))
def show(label, v, d=6):
    print(f"{label:<40} {v:>12.{d}f}")

# 1. one factor: a 2-year move fixes every other move
dr = 0.0010 / (load(KV, 2) / 2)
hw_move = [dr * load(KV, u) / u * 1e4 for u in MATS]
# 2. two factors: solve for the shocks that put 2y up 10bp and 10y down 5bp
(p2, q2), (p10, q10) = (load(A, 2) / 2, load(B, 2) / 2), (load(A, 10) / 10, load(B, 10) / 10)
det = p2 * q10 - q2 * p10
x = (0.0010 * q10 - q2 * -0.0005) / det
y = (p2 * -0.0005 - p10 * 0.0010) / det
g2_move = [(load(A, u) * x + load(B, u) * y) / u * 1e4 for u in MATS]
# 3. correlations of yields and of swap rates
c_2_10 = corr(yload(2), yload(10))
cross = load(A, 2) * load(B, 10) - load(A, 10) * load(B, 2)
det_cov = cov(yload(2), yload(2)) * cov(yload(10), yload(10)) - cov(yload(2), yload(10)) ** 2
det_id = (SIG * ETA / 20) ** 2 * (1 - RHO ** 2) * cross ** 2
g = {n: (SIG * swap_grad(n, A), ETA * swap_grad(n, B)) for n in (2, 9)}
swap_corr = corr(g[2], g[9])
h = 1e-6
fd2 = (swap(2, h, 0) - swap(2, -h, 0)) / (2 * h)
hw_swap = corr((swap_grad(2, KV), 0.0), (swap_grad(9, KV), 0.0))
zs, dt, d2, d9 = normals(rng(20260928)), 1.0 / 252, [], []
s2, s9 = swap(2), swap(9)
for _ in range(100000):                                 # one trading day of shocks, fully repriced
    z1, z2 = next(zs), next(zs)
    xx, yy = SIG * sqrt(dt) * z1, ETA * sqrt(dt) * (RHO * z1 + sqrt(1 - RHO * RHO) * z2)
    d2.append(swap(2, xx, yy) - s2); d9.append(swap(9, xx, yy) - s9)
m2, m9 = sum(d2) / len(d2), sum(d9) / len(d9)
sxy = sum((u - m2) * (v - m9) for u, v in zip(d2, d9))
mc_corr = sxy / sqrt(sum((u - m2) ** 2 for u in d2) * sum((v - m9) ** 2 for v in d9))
# 4. a Black-Derman-Toy tree, 4 annual steps, 20% log-volatility, fitted to the house curve
SB, N = 0.20, 4
U, Q, rates = [], [1.0], []
for i in range(N):
    node = lambda u, j: u * exp(SB * (2 * j - i))
    price = lambda u: sum(Q[j] / (1 + node(u, j)) for j in range(i + 1))
    lo, hi = 1e-6, 1.0
    for _ in range(200):                                # bisection: price falls as the median rate rises
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if price(mid) > P0(i + 1) else (lo, mid)
    U.append(0.5 * (lo + hi)); r = [node(U[i], j) for j in range(i + 1)]; rates.append(r)
    Q = [0.5 * ((Q[j - 1] / (1 + r[j - 1]) if j > 0 else 0) + (Q[j] / (1 + r[j]) if j <= i else 0)) for j in range(i + 2)]
def backward(T):                                        # roll a bond paying 1 at year T back through the tree
    v, layers = [1.0] * (T + 1), {}
    for i in range(T - 1, -1, -1):
        v = [0.5 * (v[j] + v[j + 1]) / (1 + rates[i][j]) for j in range(i + 1)]
        layers[i] = v
    return layers
bdt_back = [backward(T)[0][0] for T in range(1, N + 1)]
at1 = {T: backward(T)[1] for T in (2, 3, 4)}            # bond prices seen from year 1, down node then up node
sw = [[(1 - at1[1 + n][j]) / sum(at1[t][j] for t in range(2, 2 + n)) for j in (0, 1)] for n in (2, 3)]
# 5. negative rates: Hull-White in a 1% world after 10 years
a1, s1, r1, T1 = 0.3, 0.01, 0.01, 10.0
sd = sqrt(s1 * s1 * (1 - exp(-2 * a1 * T1)) / (2 * a1))
p_neg = 0.5 - simpson(lambda z: exp(-z * z / 2) / sqrt(2 * pi), 0.0, r1 / sd)
zs2, neg, fade = normals(rng(7)), 0, exp(-a1)
for _ in range(100000):                                 # ten exact one-year steps of the short rate
    r = r1
    for _ in range(10):
        r = r1 + (r - r1) * fade + s1 * sqrt((1 - fade * fade) / (2 * a1)) * next(zs2)
    neg += r < 0
print("house curve: zero prices P0(T)")
print("  " + " ".join(f"{P0(T):.6f}" for T in (1, 2, 3, 4, 10)))
print(f"HW yield loadings B(u)/u, 2y and 10y     {load(KV, 2) / 2:.6f} {load(KV, 10) / 10:.6f}")
print(f"G2 loadings 2y fast/slow, 10y fast/slow {p2:.6f} {q2:.6f} {p10:.6f} {q10:.6f}  det {det:.6f}")
show("HW: short-rate shock for 2y +10bp, bp", dr * 1e4, 4); show("G2++: fast factor shock x, bp", x * 1e4, 4); show("G2++: slow factor shock y, bp", y * 1e4, 4)
print(f"G2++ yield vols 2y, 10y, bp a year       {1e4 * sqrt(cov(yload(2), yload(2))):.2f} {1e4 * sqrt(cov(yload(10), yload(10))):.2f}")
print("maturity " + " ".join(f"{int(u):>6d}" for u in MATS))
print("HW move  " + " ".join(f"{v:6.2f}" for v in hw_move))
print("G2 move  " + " ".join(f"{v:6.2f}" for v in g2_move))
print("G2 corr% " + " ".join(f"{100 * corr(yload(2), yload(u)):6.2f}" for u in MATS))
show("B_1(2)", load(A, 2)); show("B_1(2) by Simpson", simpson(lambda s: exp(-A * s), 0.0, 2.0))
show("B_0.08(10)", load(B, 10)); show("B_0.08(10) by Simpson", simpson(lambda s: exp(-B * s), 0.0, 10.0))
show("yield corr 2y,10y: G2++", c_2_10); show("yield corr 2y,10y: HW", corr(yload(2, KV, KV, SV, 0.0), yload(10, KV, KV, SV, 0.0)))
print(f"{'covariance determinant, direct':<40} {det_cov:>12.4e}"); print(f"{'covariance determinant, identity':<40} {det_id:>12.4e}")
show("swap 1y-into-2y par rate", s2); show("swap 1y-into-9y par rate", s9)
show("dS2/dx analytic", swap_grad(2, A)); show("dS2/dx bumped", fd2)
show("swap corr 1y2y,1y9y: G2++ formula", swap_corr); show("swap corr: G2++ Monte Carlo, 100000 days", mc_corr, 3)
show("swap corr: HW", hw_swap)
show("wrong: rho = -1, yield corr", corr(yload(2), yload(10), -1.0))
show("wrong: a = b = 0.08, yield corr", corr(yload(2, B, B), yload(10, B, B)))
show("wrong: rho set to 0, yield corr", corr(yload(2), yload(10), 0.0))
show("try: rho = +0.5, yield corr", corr(yload(2), yload(10), 0.5)); show("try: rho = -0.8, yield corr", corr(yload(2), yload(10), -0.8))
show("try: rho = +0.5, swap corr", corr(g[2], g[9], 0.5)); show("try: b = 0.3, yield corr", corr(yload(2, A, 0.3), yload(10, A, 0.3)))
for i, r in enumerate(rates):
    print(f"BDT year {i} node rates, %  " + " ".join(f"{100 * v:7.4f}" for v in r))
print("BDT zero prices, tree  " + " ".join(f"{v:.6f}" for v in bdt_back))
print(f"BDT year-1 swap to 3, down/up, %  {100 * sw[0][0]:.4f} {100 * sw[0][1]:.4f}")
print(f"BDT year-1 swap to 4, down/up, %  {100 * sw[1][0]:.4f} {100 * sw[1][1]:.4f}")
show("HW 1% world: P(r < 0 at 10y), formula", p_neg, 4); show("HW 1% world: P(r < 0), Monte Carlo", neg / 100000, 4)

assert abs(g2_move[1] - 10.0) < 1e-9, "the solved shocks put the 2-year up 10bp"
assert abs(g2_move[9] + 5.0) < 1e-9, "and the 10-year down 5bp"
assert min(hw_move) > 0, "one factor cannot move any yield against the 2-year"
assert abs(load(A, 2) - simpson(lambda s: exp(-A * s), 0.0, 2.0)) < 1e-10, "loading: closed form against quadrature"
assert abs(det_cov - det_id) < 1e-22, "covariance determinant against its identity"
assert abs(fd2 - swap_grad(2, A)) < 1e-6, "swap gradient: quotient rule against bump"
assert abs(mc_corr - swap_corr) < 0.003, "swap correlation: formula against simulation"
assert abs(U[0] - (1 / P0(1) - 1)) < 1e-12, "first BDT rate is the one-year rate"
assert max(abs(bdt_back[T] - P0(T + 1)) for T in range(N)) < 1e-12, "tree prices every zero back"
assert abs(neg / 100000 - p_neg) < 0.003, "negative-rate chance: formula against simulation"
print("ALL CHECKS PASS")
