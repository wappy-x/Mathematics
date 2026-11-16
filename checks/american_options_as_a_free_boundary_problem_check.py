# An American put as an obstacle problem: strike $100, six months left. Standard library only.
# Road 1 solves the variational inequality on a log-price grid: step the equation, lift onto the payoff.
# Road 2 solves the early-exercise integral equation for the boundary alone. Road 3 is a binomial tree.
from math import log, exp, sqrt
K, r, q, sig, T, S0 = 100.0, 0.05, 0.02, 0.20, 0.5, 100.0
mu = r - q - 0.5 * sig * sig                  # drift of log price in the pricing world

def N(x):                                     # normal CDF from its Taylor series, no erf
    if abs(x) > 9: return 1.0 if x > 0 else 0.0
    s, t, k = x, x, 1
    while abs(t) > 1e-17 * abs(s):
        k += 2; t *= x * x / k; s += t
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * 3.141592653589793)
def d12(S, b, u):
    d1 = (log(S / b) + (r - q + 0.5 * sig * sig) * u) / (sig * sqrt(u)); return d1, d1 - sig * sqrt(u)
def euro(S, u):                               # European put with u years left
    d1, d2 = d12(S, K, u); return K * exp(-r * u) * N(-d2) - S * exp(-q * u) * N(-d1)
def root(f, lo, hi):                          # bisection on a sign change
    flo = f(lo)
    for _ in range(50):
        m = 0.5 * (lo + hi); fm = f(m)
        if (fm > 0) == (flo > 0): lo, flo = m, fm
        else: hi = m
    return 0.5 * (lo + hi)
psi = lambda S: max(K - S, 0.0)               # the obstacle: what exercising pays
LEFT = (0.5, 0.4, 0.3, 0.2, 0.1, 0.05, 0.01)  # years left, for the boundary chart

# ---- road 1: projected explicit scheme in x = ln(S/K) on [-0.8, 0.8], ratio sig^2 dt / h^2 = 0.8
def grid(h):
    n, nt = round(1.6 / h), round(T * sig * sig / (0.8 * h * h)); dt = T / nt
    S = [K * exp(-0.8 + i * h) for i in range(n + 1)]; g = [psi(s) for s in S]; V = g[:]; seen = {}
    a, b = 0.5 * sig * sig / (h * h), mu / (2 * h)
    for step in range(1, nt + 1):
        old = V
        LV = [0.0] + [a * (old[i + 1] - 2 * old[i] + old[i - 1]) + b * (old[i + 1] - old[i - 1]) - r * old[i]
                      for i in range(1, n)] + [0.0]
        V = [g[0]] + [max(g[i], old[i] + dt * LV[i]) for i in range(1, n)] + [0.0]
        left = round(step * dt, 6)
        if left in LEFT: seen[left] = edge(S, V, g)
    push = [(V[i] - old[i]) / dt - LV[i] for i in range(n)]   # -(V_t + LV) on the last step: V_t = (old - V)/dt
    return S, V, g, push, seen
def edge(S, V, g):                            # last contact node, then V - psi ~ c (x - xb)^2 above it
    i = max(k for k in range(len(S)) if S[k] < K and V[k] - g[k] < 1e-12)
    d1, d2 = sqrt(V[i + 1] - g[i + 1]), sqrt(V[i + 2] - g[i + 2])
    return S[i + 1] * (S[i + 2] / S[i + 1]) ** (-d1 / (d2 - d1))
HS = (0.01, 0.005, 0.0025, 0.00125); runs = {h: grid(h) for h in HS}
S, V, g, push, seen = runs[0.00125]; i0 = round(0.8 / 0.00125)

# ---- road 2: early-exercise integral equation, marched back from expiry on 100 bunched dates
def prem(S, us, Bs, i):                       # discounted carry r K - q S wherever S sits below the line
    tot, pu, pf = 0.0, None, None
    for j in range(i, -1, -1):
        u = us[i] - us[j]
        if u == 0: f = 0.5 * (r * K - q * S)
        else:
            d1, d2 = d12(S, Bs[j], u); f = r * K * exp(-r * u) * N(-d2) - q * S * exp(-q * u) * N(-d1)
        if pu is not None: tot += 0.5 * (f + pf) * (u - pu)
        pu, pf = u, f
    return tot
m = 100; us = [T * (i / m) ** 2 for i in range(m + 1)]; Bs = [K]
for i in range(1, m + 1):
    Bs.append(root(lambda b: K - b - euro(b, us[i]) - prem(b, us, Bs + [b], i), 40.0, Bs[-1]))
def B_int(t):                                 # boundary t years left, linear between dates
    t = max(t, 0.0); i = max(k for k in range(m) if us[k] <= t); w = (t - us[i]) / (us[i + 1] - us[i])
    return Bs[i] + w * (Bs[i + 1] - Bs[i])
def V_int(S, n=400):                          # price: European put plus premium, Simpson in v = sqrt(u)
    if S <= Bs[m]: return K - S
    hv, tot = sqrt(T) / n, 0.0
    for k in range(1, n + 1):
        u = (k * hv) ** 2; d1, d2 = d12(S, B_int(T - u), u)
        f = r * K * exp(-r * u) * N(-d2) - q * S * exp(-q * u) * N(-d1)
        tot += (4 if k % 2 else 2 if k < n else 1) * f * 2 * k * hv
    return euro(S, T) + tot * hv / 3

# ---- road 3: CRR binomial tree: at each node take the larger of exercising and waiting
def tree(n, rule=None):
    dt = T / n; u = exp(sig * sqrt(dt)); p = (exp((r - q) * dt) - 1 / u) / (u - 1 / u); D = exp(-r * dt)
    W = [psi(S0 * u ** (2 * j - n)) for j in range(n + 1)]
    for k in range(n - 1, -1, -1):
        for j in range(k + 1):
            s = S0 * u ** (2 * j - k); c = D * (p * W[j + 1] + (1 - p) * W[j])
            W[j] = max(psi(s), c) if rule is None else (psi(s) if s <= rule else c)
    return W[0]

# ---- the perpetual put: exact boundary, and trial triggers glued at matching height only
lam = (-mu - sqrt(mu * mu + 2 * sig * sig * r)) / (sig * sig); Sstar = K * lam / (lam - 1)
def trial(L):                                 # (K - L)(S/L)^lam above L: value matches, slope may not
    jump = lam * (K - L) / L + 1; low = min((K - L) * (s / L) ** lam - psi(s) for s in (L + 1, L + 5, L + 10))
    return jump, (K - L) * (S0 / L) ** lam, low

B1, A_tree = Bs[m], tree(2000)
print(f"six-month put, S = {S0:.0f}: grid {V[i0]:.4f}, integral {V_int(S0):.4f}, tree {A_tree:.4f} dollars")
print(f"European put {euro(S0, T):.4f} dollars, early-exercise premium {V_int(S0) - euro(S0, T):.4f}")
pg = [runs[h][1][round(0.8 / h)] for h in HS]; bg = [edge(*runs[h][:3]) for h in HS]
for h, p, b in zip(HS, pg, bg):
    print(f"grid h = {h:.5f}: price {p:.5f} dollars, boundary {b:.3f} dollars, gap to integral road {b - B1:+.3f}")
print("price order from successive halvings: " + ", ".join(f"{log((pg[k] - pg[k + 1]) / (pg[k + 1] - pg[k + 2])) / log(2):.2f}" for k in (0, 1)))
print(f"boundary today: integral {B1:.3f} dollars, finest grid {bg[3]:.3f} dollars")
print("years left:", ", ".join(f"{t:.2f}" for t in LEFT) + ", 0.00")
print("boundary integral:", ", ".join(f"{B_int(t):.2f}" for t in LEFT) + f", {K:.2f}")
print("boundary grid:", ", ".join(f"{seen[t]:.2f}" for t in LEFT) + f", {K:.2f}")
print("chart S:", ", ".join(f"{s}" for s in range(70, 115, 5)))
print("chart V:", ", ".join(f"{V_int(s):.2f}" for s in range(70, 115, 5)))
print("chart payoff:", ", ".join(f"{psi(s):.2f}" for s in range(70, 115, 5)))
cont = [k for k in range(1, len(S) - 1) if V[k] - g[k] > 1e-9]; ex = [k for k in range(1, len(S) - 1) if k not in cont and S[k] < K]
for s in (60.0, 70.0, 80.0):
    k = min(ex, key=lambda k: abs(S[k] - s))
    print(f"push at S = {S[k]:.2f}: grid {push[k]:.4f}, rK - qS {r * K - q * S[k]:.4f} dollars a year")
sl = [(V_int(B1 + e) - (K - B1)) / e for e in (2.0, 1.0, 0.5)]
print("slope from the line out by 2, 1, 0.5 dollars: " + ", ".join(f"{x:.4f}" for x in sl))
gam = 2 * (r * K - q * B1) / (sig * sig * B1 * B1)
j, h = cont[0] + 1, HS[3]                     # the finest grid's second node above the line; Gamma = (V_xx - V_x) / S^2
gm = ((V[j + 1] - 2 * V[j] + V[j - 1]) / (h * h) - (V[j + 1] - V[j - 1]) / (2 * h)) / (S[j] * S[j])
print(f"curvature just above the line: predicted {gam:.5f}, finest grid at {S[j]:.2f} dollars {gm:.5f} per dollar")
print(f"carry on the line rK - qB {r * K - q * B1:.4f} dollars a year; predicted slope out by 2, 1, 0.5: " + ", ".join(f"{-1 + gam * e / 2:.4f}" for e in (2.0, 1.0, 0.5)))
print(f"perpetual: log-price drift mu {mu:.4f}, lambda {lam:.6f}, boundary {Sstar:.2f}, value at 100 {(K - Sstar) * (S0 / Sstar) ** lam:.4f}")
for L in (50.0, Sstar, 80.0):
    jump, v100, low = trial(L); jump = round(jump, 9) + 0.0
    print(f"trigger {L:5.2f}: slope jump {jump:+.4f}, point push {-0.5 * sig * sig * L * L * jump + 0.0:+.2f}, value at 100 {v100:.4f}, lowest gap to payoff {low:+.4f}")
wf, wp, we = tree(2000, B1), tree(2000, Sstar), tree(2000, 0.0)
print(f"breaks on the tree: never exercise {we:.4f}; boundary frozen at {B1:.2f}: {wf:.4f}; perpetual {Sstar:.2f}: {wp:.4f}")

assert abs(euro(S0, 1.0) - 6.330080627550) < 1e-9                        # CDF series: the one-year European put
assert abs(V[i0] - A_tree) < 0.005 and abs(V_int(S0) - A_tree) < 0.002   # three roads, one price
assert abs(bg[3] - B1) < 0.02 and abs(bg[3] - B1) < abs(bg[0] - B1)       # two roads, one boundary
assert all(abs(seen[t] - B_int(t)) < 0.15 for t in LEFT)                  # the whole line agrees
assert Sstar < B1 < K and all(B_int(a) < B_int(b) for a, b in zip(LEFT, LEFT[1:]))
assert min(push[k] for k in ex) > 0                                      # the floor pushes wherever V rests on it
assert all(abs(push[k] - (r * K - q * S[k])) < 0.01 for k in ex if S[k] < B1 - 2)
assert all(abs(1 + sl[k]) / abs(1 + sl[k + 1]) > 1.8 for k in (0, 1))    # slope tends to -1: no corner
assert abs(gm - gam) < 0.02 * gam                                          # curvature jumps from 0 to 2(rK-qB)/(sig B)^2
assert abs(trial(Sstar)[0]) < 1e-12 and trial(80.0)[0] > 0 and trial(50.0)[2] < 0
assert max(trial(50.0)[1], trial(80.0)[1]) < trial(Sstar)[1] and max(wf, wp, we) < A_tree - 0.05
assert abs(we - euro(S0, T)) < 0.002 and abs(wp - we) < 0.001                # the far line almost never acts
print("ALL CHECKS PASS")
