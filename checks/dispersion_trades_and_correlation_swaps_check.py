from math import sqrt, log, exp, cos, pi
W, VOL, RHO = [0.5, 0.5], [0.20, 0.20], 0.5         # house: weights, implied vols, implied correlation
M64 = (1 << 64) - 1

def show(label, x):                                  # tiny float noise prints as 0, not -0
    print(f"{label:<50}{x if abs(x) > 1e-12 else 0.0:.6f}")

def index_var(w, v, rho):                            # variance of a weighted sum, one correlation
    n = len(w)
    return sum(w[i] * w[j] * v[i] * v[j] * (1.0 if i == j else rho) for i in range(n) for j in range(n))

def cross(w, v):                                     # sum over pairs i != j of w_i w_j v_i v_j
    return sum(w[i] * w[j] * v[i] * v[j] for i in range(len(w)) for j in range(len(w)) if i != j)

def implied_corr(KI, w, K):                          # the correlation the variance strikes imply
    own = sum(wi * wi * k for wi, k in zip(w, K))
    return (KI - own) / cross(w, [sqrt(k) for k in K])

def notionals(w, v, rho):                            # vega-neutral member notionals, closed form
    n = len(w)
    return [w[i] * w[i] + rho * w[i] * sum(w[j] * v[j] for j in range(n) if j != i) / v[i] for i in range(n)]

def pnl(N, KI, K, rvI, rv):                          # short 1 unit of index variance, long members
    return (KI - rvI) + sum(n * (r - k) for n, r, k in zip(N, rv, K))

def scenario(N, vols, rho_r):                        # realised vols and correlation -> trade profit
    return pnl(N, KI, K, index_var(W, vols, rho_r), [s * s for s in vols])

# ---- strikes and sizing ----
K = [s * s for s in VOL]
KI = index_var(W, VOL, RHO)
show("index variance strike K_I", KI)
show("index volatility, percent", 100 * sqrt(KI))
show("implied correlation from the strikes", implied_corr(KI, W, K))
N = notionals(W, VOL, RHO)
h = 1e-4                                             # road 2: bump share 1's vol in the index variance
bumped = (index_var(W, [VOL[0] + h, VOL[1]], RHO) - index_var(W, [VOL[0] - h, VOL[1]], RHO)) / (2 * h)
show("index variance slope in share 1 vol", bumped)
show("member notional, closed form", N[0])
show("member notional, bump / (2 sigma_1)", bumped / (2 * VOL[0]))
assert abs(N[0] - bumped / (2 * VOL[0])) < 1e-9
show("members' total notional x strike", sum(n * k for n, k in zip(N, K)))
assert abs(sum(n * k for n, k in zip(N, K)) - KI) < 1e-12   # Euler: matches the index leg
# ---- the trade, settled ----
rvI = index_var(W, VOL, 0.3)
show("index realised variance at correlation 0.3", rvI)
show("profit: index leg", KI - rvI)
show("profit: member legs", sum(n * (r - k) for n, r, k in zip(N, K, K)))
p = scenario(N, VOL, 0.3)
show("profit: whole trade", p)
show("profit at correlation 0.8, both 20%", scenario(N, VOL, 0.8))
cx = cross(W, VOL)
show("cross term sum w_i w_j sigma_i sigma_j", cx)
show("profit: (rho_impl - rho_real) x cross term", (RHO - 0.3) * cx)
assert abs(p - (RHO - 0.3) * cx) < 1e-12
show("correlation swap notional per unit", cx)
NI = 100000 / (2 * 100 * sqrt(KI))                  # dollars per variance point, from $100,000 vega
show("index variance notional, $ per var point", NI)
show("member variance notional, $ each", N[0] * NI)
show("member vega notional, $ each", N[0] * NI * 2 * 100 * VOL[0])
show("profit in dollars at correlation 0.3", NI * 10000 * p)
# ---- flat in single-name vol, and what breaks ----
wt, sq = [w for w in W], [w * w for w in W]
for name, M in (("vega-neutral", N), ("by weight", wt), ("by weight squared", sq)):
    slope = (scenario(M, [0.21, 0.20], RHO) - scenario(M, [0.19, 0.20], RHO)) / 2
    show(f"{name}: slope per vol point of share 1", slope)
    show(f"{name}: both 25%, correlation 0.5", scenario(M, [0.25, 0.25], RHO))
    show(f"{name}: both 30%, correlation 0.3", scenario(M, [0.30, 0.30], 0.3))
assert abs(scenario(N, [0.25, 0.25], RHO)) < 1e-12 and abs(scenario(wt, [0.25, 0.25], RHO) - 0.005625) < 1e-12
show("vega-neutral: 25% and 15%, correlation 0.5", scenario(N, [0.25, 0.15], RHO))
show("vol gap term rho w1 w2 (sigma1 - sigma2)^2", RHO * W[0] * W[1] * (0.25 - 0.15) ** 2)
assert abs(scenario(N, [0.25, 0.15], RHO) - RHO * W[0] * W[1] * 0.01) < 1e-12
for v in (0.15, 0.20, 0.30):                         # chart: profit against realised correlation
    pts = [10000 * scenario(N, [v, v], c / 10) for c in range(11)]
    print(f"chart vol {v:.2f}," + ",".join(f"{x if abs(x) > 1e-9 else 0.0:.2f}" for x in pts))
# ---- correlation swap strike from variance strikes ----
show("proxy K_I / (sum w_i sqrt K_i)^2, two names", KI / sum(w * sqrt(k) for w, k in zip(W, K)) ** 2)
w50 = [1 / 50] * 50
K50 = index_var(w50, [0.2] * 50, RHO)
show("50 names: index variance strike", K50)
show("50 names: exact implied correlation", implied_corr(K50, w50, [0.04] * 50))
show("50 names: proxy", K50 / sum(w * 0.2 for w in w50) ** 2)
states = [(0.5, 0.15, 0.3), (0.5, 0.30, 0.8)]        # calm and stressed: (probability, vol, correlation)
Ks = sum(pr * v * v for pr, v, c in states)
KIs = sum(pr * index_var(W, [v, v], c) for pr, v, c in states)
ri = implied_corr(KIs, W, [Ks, Ks])
show("two states: member variance strike", Ks)
show("two states: index variance strike", KIs)
show("two states: implied correlation", ri)
show("two states: variance-weighted correlation", sum(pr * c * v * v for pr, v, c in states) / Ks)
show("two states: correlation swap fair strike", sum(pr * c for pr, v, c in states))
assert abs(ri - sum(pr * c * v * v for pr, v, c in states) / Ks) < 1e-12
# ---- road 3: simulate daily prices, settle the legs from the path ----
state = 20261123
def normal():
    global state
    u = []
    for _ in range(2):
        state = (state + 0x9E3779B97F4A7C15) & M64
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        u.append(((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54)
    return sqrt(-2 * log(u[0])) * cos(2 * pi * u[1])

def year(rho):                                       # 252 days; index rebalanced daily to 50/50
    a, b, xy, ii = 0.0, 0.0, 0.0, 0.0
    for _ in range(252):
        z1 = normal(); z2 = rho * z1 + sqrt(1 - rho * rho) * normal()
        x1 = -0.5 * 0.04 / 252 + 0.2 * z1 / sqrt(252); x2 = -0.5 * 0.04 / 252 + 0.2 * z2 / sqrt(252)
        xi = log(1 + W[0] * (exp(x1) - 1) + W[1] * (exp(x2) - 1))
        a += x1 * x1; b += x2 * x2; xy += x1 * x2; ii += xi * xi
    return a, b, xy / sqrt(a * b), ii

a, b, rr, ii = year(0.3)
legs = pnl(N, KI, K, ii, [a, b])
formula = RHO * W[0] * W[1] * (a + b) - rr * 2 * W[0] * W[1] * sqrt(a * b)
show("sim year 1: share 1 realised vol, percent", 100 * sqrt(a))
show("sim year 1: share 2 realised vol, percent", 100 * sqrt(b))
show("sim year 1: realised correlation", rr)
show("sim year 1: index realised variance", ii)
show("sim year 1: profit from the three legs", legs)
show("sim year 1: profit from the formula", formula)
assert abs(legs - formula) < 2e-5
ps = [pnl(N, KI, K, i, [x, y]) for x, y, _, i in (year(0.3) for _ in range(1000))]
m = sum(ps) / len(ps); se = sqrt(sum((x - m) ** 2 for x in ps) / (len(ps) - 1) / len(ps))
show("1000 sim years: average profit", m)
show("1000 sim years: standard error", se)
assert abs(m - 0.004) < 4 * se
print("ALL CHECKS PASS")
