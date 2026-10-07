# Parametric (delta-normal) VaR -- the check behind the card.  Nothing imported
# but math's exp, log, sqrt, cos, pi.  The book: 10,000,000 of shares, a
# 5,000,000 bond, 1,000 Acme call contracts on 100 shares each.  One day, 99%.
from math import exp, log, sqrt, cos, pi

def N(x):                                   # normal CDF: Simpson on the bell curve
    n, a = 2000, abs(x)
    h = a / n
    f = lambda t: exp(-0.5 * t * t) / sqrt(2 * pi)
    s = f(0) + f(a) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))
    half = s * h / 3
    return 0.5 + half if x >= 0 else 0.5 - half

def inv_N(p):                               # bisection: the z with N(z) = p
    lo, hi = -10.0, 10.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N(mid) < p else (lo, mid)
    return 0.5 * (lo + hi)

# ---- mapping: each position becomes dollars per unit move of a risk factor ----
S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
delta = exp(-q * T) * N(d1)
def bs_call(s0):                            # Black-Scholes call at spot s0
    d = (log(s0 / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return s0 * exp(-q * T) * N(d) - K * exp(-r * T) * N(d - sig * sqrt(T))
call, delta_fd = bs_call(S), (bs_call(S + 0.01) - bs_call(S - 0.01)) / 0.02
pv01 = 5_000_000 * 5.0 * 0.0001             # bond: value x duration x 1 basis point
w = [10_000_000.0, 1000 * 100 * S * delta, -pv01]   # $ per 1.00 return, 1.00 return, 1 bp
vol = [0.0135, sig / sqrt(252), 6.0]        # daily: shares, Acme, 5-year yield in bp
rho = [[1.0, 0.5, 0.2], [0.5, 1.0, 0.1], [0.2, 0.1, 1.0]]
z99, z95 = inv_N(0.99), inv_N(0.95)

def cov(rh):
    return [[rh[i][j] * vol[i] * vol[j] for j in range(3)] for i in range(3)]

def var_quad(w, C):                         # road 1: z * sqrt(w' C w)
    return z99 * sqrt(sum(w[i] * C[i][j] * w[j] for i in range(3) for j in range(3)))

C = cov(rho)
V1 = var_quad(w, C)

# ---- road 2: Cholesky, C = L L', so the P&L is a sum of independent moves ----
L = [[0.0] * 3 for _ in range(3)]
for i in range(3):
    for j in range(i + 1):
        s = C[i][j] - sum(L[i][k] * L[j][k] for k in range(j))
        L[i][j] = sqrt(s) if i == j else s / L[j][j]
b = [sum(w[i] * L[i][k] for i in range(3)) for k in range(3)]   # $ per independent shock
V2 = z99 * sqrt(sum(x * x for x in b))

# ---- road 3: dollar volatilities and correlations, the hand table ----
s_d = [w[i] * vol[i] for i in range(3)]
terms = [(i, j, rho[i][j] * s_d[i] * s_d[j] * (1 if i == j else 2)) for i in range(3) for j in range(i, 3)]
V3 = z99 * sqrt(sum(t for _, _, t in terms))

# ---- road 4: simulate 100,000 days, own random numbers, read the 1% tail ----
state = 20260928
def u01():                                  # splitmix64 -> uniform in (0,1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    x ^= x >> 31
    return ((x >> 11) + 0.5) / 9007199254740992.0
n = 100_000
pnl = []
for _ in range(n):
    g = []
    while len(g) < 3:                       # Box-Muller: two uniforms -> two normals
        rad, ang = sqrt(-2.0 * log(u01())), 2.0 * pi * u01()
        g += [rad * cos(ang), rad * cos(ang - 0.5 * pi)]
    pnl.append(sum(w[i] * sum(L[i][k] * g[k] for k in range(3)) for i in range(3)))
pnl.sort()
V4 = -pnl[n // 100 - 1]                     # the 1,000th-worst day

# ---- decomposition: component = position x marginal; marginal by bumping ----
sp = V1 / z99
comp = [z99 * w[i] * sum(C[i][j] * w[j] for j in range(3)) / sp for i in range(3)]
bump = []
for i in range(3):
    up, dn = w[:], w[:]
    up[i] *= 1.0001; dn[i] *= 0.9999
    bump.append((var_quad(up, C) - var_quad(dn, C)) / 0.0002)
alone = [z99 * abs(x) for x in s_d]

# ---- what breaks ----
w_sum = sum(alone)
w_zero = z99 * sqrt(sum(x * x for x in s_d))
w_prem = var_quad([w[0], 1000 * 100 * call, w[2]], C)
w_annual = var_quad(w, [[x * 252 for x in row] for row in C])
w_95 = z95 * sp

names = ["shares", "calls (Acme)", "bond (yield)"]
rows = [("d1", d1), ("call price", call), ("call delta", delta), ("calls' market value", 1000 * 100 * call),
        ("delta, in Acme shares", 1000 * 100 * delta), ("bond PV01 $/bp", pv01), ("Acme daily vol", vol[1]),
        ("z at 99%", z99), ("z at 95%", z95),
        ("exposure shares $/1.00", w[0]), ("exposure calls $/1.00", w[1]), ("exposure bond $/bp", w[2])]
rows += [("dollar vol " + names[i], s_d[i]) for i in range(3)]
rows += [(f"term {i + 1}{j + 1}", t) for i, j, t in terms]
rows += [("portfolio sigma", sp), ("1 VaR, quadratic form", V1), ("2 VaR, Cholesky", V2),
         ("3 VaR, dollar-vol table", V3), ("4 VaR, 100,000 simulated days", V4)]
rows += [("component " + names[i], comp[i]) for i in range(3)]
rows += [("  by bumping " + names[i], bump[i]) for i in range(3)]
rows += [("  percent of VaR " + names[i], 100 * comp[i] / V1) for i in range(3)]
rows += [("standalone " + names[i], alone[i]) for i in range(3)]
rows += [("wrong: add standalone VaRs", w_sum), ("wrong: correlations set to 0", w_zero),
         ("wrong: calls at premium", w_prem),
         ("wrong: annual vols", w_annual), ("wrong: 95% z, called 99%", w_95),
         ("try: 10-day, root-10 rule", V1 * sqrt(10)), ("try: bond doubled", var_quad([w[0], w[1], 2 * w[2]], C)),
         ("try: calls sold, not bought", var_quad([w[0], -w[1], w[2]], C))]
for name, v in rows:
    print(f"{name:<34}{v:>16.{6 if abs(v) < 100 else 2}f}")
for i in range(3):
    print(f"covariance row {i + 1}  " + " ".join(f"{C[i][j]:>14.9f}" for j in range(3)))
print("chart, rho shares-Acme  " + " ".join(f"{x:>7.2f}" for x in (-0.5, -0.25, 0.0, 0.25, 0.5, 0.75)))
pts = []
for x in (-0.5, -0.25, 0.0, 0.25, 0.5, 0.75):
    rh = [row[:] for row in rho]; rh[0][1] = rh[1][0] = x
    pts.append(var_quad(w, cov(rh)) / 1000)
print("chart, VaR in $000      " + " ".join(f"{v:>7.2f}" for v in pts))

assert abs(N(d1) - 0.598706325683) < 1e-9, "own normal CDF vs the pilot's N(0.25)"
assert abs(call - 9.227005508154) < 1e-9, "call price vs the house market"
assert abs(delta_fd - delta) < 1e-6, "delta vs bumping the call's price"
assert abs(V2 - V1) < 1e-6 * V1, "Cholesky road must equal the quadratic form"
assert abs(V3 - V1) < 1e-6 * V1, "hand table road must equal the quadratic form"
assert abs(V4 - V1) < 0.02 * V1, "simulated 1% tail within 2% of the formula"
assert all(abs(comp[i] - bump[i]) < 1e-3 * V1 for i in range(3)), "components vs bumped marginals"
assert abs(sum(bump) - V1) < 1e-4 * V1, "bumped pieces add back to the total (Euler)"
print("ALL CHECKS PASS")
