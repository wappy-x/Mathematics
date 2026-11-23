# Rough Bergomi: skew power law, skew-stickiness ratio; Ross recovery.  Standard library only.
# Years; rates zero; forward 100.  Roads: closed forms; quadrature and sums over the kernel;
# simulation (SplitMix64, seed 20261123, exact Gaussian grid by Cholesky); power iteration.
from math import sqrt, exp, log, cos, pi
H, RHO, XI0, S0, KAP = 0.1, -0.9, 0.04, 0.2, 2.0   # Hurst, correlation, variance, its vol, Heston pull
ETA = 0.6 * 252.0 ** H                       # log-vol spread 0.3 a trading day, as on the rough-paths card
M64, state = (1 << 64) - 1, 20261123
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0 ** 53
def gauss(): u1 = unif(); u2 = unif(); return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)   # Box-Muller
def ncdf(x):                                 # bell-curve area by its Taylor series, no erf
    if abs(x) > 8.0: return 0.0 if x < 0 else 1.0
    term, s, k = x, x, 1
    while abs(term) > 1e-17 * abs(s):
        term = term * x * x / (2 * k + 1); s += term; k += 1
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def bs(f, k, w):                             # Black-Scholes call: forward f, strike k, total variance w
    sd = sqrt(w); d1 = (log(f / k) + 0.5 * w) / sd
    return f * ncdf(d1) - k * ncdf(d1 - sd)
def implied(c, k, T):                        # volatility by bisection, forward 100
    lo, hi = 0.001, 2.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (lo, mid) if bs(100.0, k, mid * mid * T) > c else (mid, hi)
    return 0.5 * (lo + hi)
def simpson(f, a, b, n):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
# ---- road 1: closed forms, first order in the vol of vol ----
def skew_rough(T, eta): return RHO * eta * sqrt(2 * H) / (2 * (H + 0.5) * (H + 1.5)) * T ** (H - 0.5)
def hI(T): return T / KAP - (1 - exp(-KAP * T)) / KAP ** 2
XIH = skew_rough(1.0, ETA) / (RHO / (2 * S0) * hI(1.0))   # Heston vol of vol giving the same 1-year skew
def skew_heston(T): return RHO * XIH / (2 * S0 * T * T) * hI(T)
def ssr_heston(T): return T * (1 - exp(-KAP * T)) / KAP / hI(T)
print(f"H {H}  rho {RHO}  eta {ETA:.6f}  xi0 {XI0}  sqrt(2H) {sqrt(2 * H):.4f}  (H+1/2)(H+3/2) {(H + 0.5) * (H + 1.5):.4f}")
print(f"Heston kappa {KAP}  vol of vol matched at 1y {XIH:.6f}")
print("maturity   years     rough   Heston  rough/1y Heston/1y")
for name, T in (("1w", 1 / 52), ("2w", 1 / 26), ("1m", 1 / 12), ("2m", 1 / 6), ("3m", 0.25), ("6m", 0.5), ("1y", 1.0)):
    r, h = skew_rough(T, ETA), skew_heston(T)
    print(f"{name:>8} {T:7.4f} {r:9.4f} {h:8.4f} {r / skew_rough(1.0, ETA):9.4f} {h / skew_heston(1.0):9.4f}")
print(f"52^(1/2-H) {52 ** (0.5 - H):.4f}   H = 0.3: {52 ** 0.2:.4f}   H = 0.5: {52 ** 0.0:.4f}")
heston_lim = RHO * XIH / (4 * S0); print(f"Heston skew at T = 1e-4: formula {skew_heston(1e-4):.6f}  limit rho*xi/(4 sigma0) {heston_lim:.6f}")
# ---- road 2: quadrature and sums over the model's own kernel ----
p, I1 = 1.0 / (H + 0.5), lambda s: s ** (H + 0.5) / (H + 0.5)    # integral of the kernel u^(H-1/2) from 0 to s
ssr_quad = I1(1.0) / simpson(I1, 0.0, 1.0, 4000)
print(f"SSR rough by quadrature {ssr_quad:.6f}  H + 3/2 = {H + 1.5:.6f}   Heston 1w {ssr_heston(1 / 52):.4f}  1y {ssr_heston(1.0):.4f}  T = 1e-4 {ssr_heston(1e-4):.4f}")
rules = (lambda K, S: 0.2 - 0.04 * (K / S - 1), lambda K, S: 0.2 - 0.0004 * (K - 100), lambda K, S: 0.2 - 0.0004 * (K + S - 200))
print("SSR of the smile card's rules (moneyness, strike, local vol):", " ".join(f"{(r(100, 100) - r(100 * exp(1e-4), 100 * exp(1e-4))) / (r(100, 100) - r(100 * exp(1e-4), 100)):.4f}" for r in rules))
def cov_yy(a, b):                            # Cov(Y_a, Y_b), a <= b; u = w^p removes the singularity
    if b - a <= 0: return a ** (2 * H)
    return 2 * H * simpson(lambda w: p * (w ** p + b - a) ** (H - 0.5), 0.0, a ** (H + 0.5), 400)
def cov_yw(a, lo, hi):                       # Cov(Y_a, W_hi - W_lo), hi <= a
    return sqrt(2 * H) / (H + 0.5) * ((a - lo) ** (H + 0.5) - (a - hi) ** (H + 0.5))
def skew_grid(T, n, eta):                    # first-order skew of the n-step model, from its covariances
    tot = 0.0
    for j in range(1, n):
        for i in range(j): tot += cov_yw(j / n, i / n, (i + 1) / n)
    return RHO * eta * tot / n * T ** (H - 0.5) / 2.0
g32, g1024 = skew_grid(1.0, 32, ETA), skew_grid(1.0, 1024, ETA)
print(f"first-order 1y skew: 32-step grid {g32:.6f}  1024-step grid {g1024:.6f}  formula {skew_rough(1.0, ETA):.6f}")
# ---- road 3: simulation, 32 steps, exact Gaussian grid, Black-Scholes over the price's own noise ----
N, n2, M, NB, TS, ETAS = 32, 64, 20000, 10, (1 / 52, 1.0), (0.0, 0.05, ETA)
C = [[0.0] * n2 for _ in range(n2)]          # rows 0..31: dW on each step; rows 32..63: Y at each step's end
for i in range(N):
    C[i][i] = 1.0 / N
    for j in range(i, N): C[N + j][i] = C[i][N + j] = cov_yw((j + 1) / N, i / N, (i + 1) / N)
    for j in range(i, N): C[N + i][N + j] = C[N + j][N + i] = cov_yy((i + 1) / N, (j + 1) / N)
L = [[0.0] * n2 for _ in range(n2)]
for i in range(n2):
    for j in range(i + 1):
        s = C[i][j]
        for k in range(j): s -= L[i][k] * L[j][k]
        L[i][j] = sqrt(s) if i == j else s / L[j][j]
acc, vmean, vnocomp = {(T, e, b): [0.0] * 3 for T in TS for e in ETAS for b in range(NB)}, 0.0, 0.0
for m in range(M):
    z = [gauss() for _ in range(n2)]
    for sgn in (1.0, -1.0):                  # antithetic pair
        g = [0.0] * n2
        for i in range(n2):
            for k in range(i + 1): g[i] += sgn * L[i][k] * z[k]
        for T in TS:
            sw, sy, dk = sqrt(T), T ** H, 0.1 * S0 * sqrt(T)
            for e in ETAS:
                i1 = i2 = 0.0; v = XI0
                for i in range(N):
                    i1 += sqrt(v) * g[i] * sw; i2 += v * T / N
                    v = XI0 * exp(e * g[N + i] * sy - 0.5 * e * e * ((i + 1) * T / N) ** (2 * H))
                f, w, a = 100.0 * exp(RHO * i1 - 0.5 * RHO * RHO * i2), (1 - RHO * RHO) * i2, acc[(T, e, m % NB)]
                a[0] += bs(f, 100.0 * exp(-dk), w); a[1] += f; a[2] += bs(f, 100.0 * exp(dk), w)
                if T == 1.0 and e == ETA: vmean += v; vnocomp += XI0 * exp(e * g[n2 - 1])
def batch_skew(T, e, b):
    a, n, dk = acc[(T, e, b)], 2.0 * M / NB, 0.1 * S0 * sqrt(T)
    F = a[1] / n
    lo, hi = (implied(a[q] / n * 100.0 / F, 100.0 * exp(x) * 100.0 / F, T) for q, x in ((0, -dk), (2, dk)))
    return (hi - lo) / (2 * dk)
sim = {}
for T in TS:
    for e in ETAS[1:]:                       # minus the eta = 0 skew, which is exactly 0: a control
        xs = [batch_skew(T, e, b) - batch_skew(T, 0.0, b) for b in range(NB)]
        mu = var = 0.0
        for x in xs: mu += x / NB
        for x in xs: var += (x - mu) * (x - mu)
        sim[(T, e)] = (mu, sqrt(var / (NB - 1) / NB))
        print(f"simulated skew T {T:.4f} eta {e:.4f}: {mu:.4f} +- {sim[(T, e)][1]:.4f}   grid {skew_grid(T, N, e):.4f}  formula {skew_rough(T, e):.4f}")
r_sim = sim[(TS[0], ETA)][0] / sim[(1.0, ETA)][0]
print(f"simulated 1w/1y skew ratio {r_sim:.4f}   power law {52 ** (0.5 - H):.4f}")
vm, vn, vn_exact = vmean / (2 * M), vnocomp / (2 * M), XI0 * exp(0.5 * ETA * ETA)
print(f"mean variance at 1y: simulated {vm:.5f}  no compensator: simulated {vn:.5f}  exact {vn_exact:.5f}  vol {sqrt(vn_exact):.4f}")
# ---- road 4: Ross recovery on a 3-state chain (states: down, flat, up) ----
P, Z, W, DELTA = [[0.6, 0.3, 0.1], [0.2, 0.6, 0.2], [0.1, 0.3, 0.6]], [1.25, 1.0, 0.8], [1.3, 1.0, 0.85], 0.97
# true chances; marginal utility in each state; world B's permanent tilt; one-year discount
A, e = [[DELTA * P[i][j] * Z[j] / Z[i] for j in range(3)] for i in range(3)], [1.0, 1.0, 1.0]   # state prices
for _ in range(500):                         # power iteration: positive eigenvector of A
    e2 = [A[i][0] * e[0] + A[i][1] * e[1] + A[i][2] * e[2] for i in range(3)]
    lam = e2[1] / e[1]; e = [x / e2[1] for x in e2]
R = [[A[i][j] * e[j] / (lam * e[i]) for j in range(3)] for i in range(3)]
c = [P[i][0] / W[0] + P[i][1] / W[1] + P[i][2] / W[2] for i in range(3)]
PB = [[P[i][j] / (c[i] * W[j]) for j in range(3)] for i in range(3)]       # world B's true chances
AB = [[PB[i][j] * DELTA * Z[j] / Z[i] * c[i] * W[j] for j in range(3)] for i in range(3)]
print(f"recovery: discount {lam:.6f}   from flat, recovered {R[1][0]:.4f} {R[1][1]:.4f} {R[1][2]:.4f}")
print(f"true chances from flat: world A {P[1][0]:.4f} {P[1][1]:.4f} {P[1][2]:.4f}   world B {PB[1][0]:.4f} {PB[1][1]:.4f} {PB[1][2]:.4f}")
assert abs(heston_lim - skew_heston(1e-4)) < 1e-4, "Heston skew formula vs its short-maturity limit"
assert abs(ssr_quad - (H + 1.5)) < 1e-5, "skew-stickiness ratio by quadrature vs H + 3/2"
assert abs(ssr_heston(1e-4) - 2.0) < 1e-3, "Heston SSR tends to 2 at short maturity"
assert abs(g1024 / skew_rough(1.0, ETA) - 1) < 2e-3, "grid sum of covariances converges to the closed form"
for T in TS:                                 # small vol of vol: simulation matches first order
    mu, se = sim[(T, 0.05)]
    assert abs(mu - skew_grid(T, N, 0.05)) < 4 * se + 0.03 * abs(mu), "simulated skew vs first order"
assert 4.0 < r_sim < 6.5, "rough skew steepens like a power law at full vol of vol"
assert abs(vm - XI0) < 0.002, "compensator keeps the mean variance at 0.04"
assert abs(vn / vn_exact - 1) < 0.05, "without it the mean is 0.04 e^(eta^2/2)"
assert max(abs(R[i][j] - P[i][j]) for i in range(3) for j in range(3)) < 1e-12, "recovery returns world A"
assert max(abs(A[i][j] - AB[i][j]) for i in range(3) for j in range(3)) < 1e-14, "worlds A and B: same prices"
assert abs(PB[1][0] - P[1][0]) > 0.04, "world B's true chance of down differs from the recovered one"
print("ALL CHECKS PASS")
