# Quanto option -- the check behind the card.  Python standard library only.
# Every number quoted on the card is printed here.  The normal CDF is a series
# written out, the integral is Simpson's rule, the random numbers are splitmix64.
from math import log, sqrt, exp, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                  # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):                  # x + x^3/3 + x^5/(3*5) + ...
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

S, K, XBAR, X0 = 100.0, 100.0, 1.10, 1.15   # share EUR, strike EUR, fixed USD/EUR, spot USD/EUR
RD, RF, Q = 0.05, 0.03, 0.01                # USD rate, EUR rate, dividend yield
SS, SX, RHO, T = 0.20, 0.10, 0.30, 1.0      # share vol, FX vol, correlation, years

def drift(rf, q, ss, sx, rho): return rf - q - rho * ss * sx    # mu, the slowed drift

def quanto(S, K, xbar, rd, mu, ss, T, put=False):     # road 1: the closed form
    v = ss * sqrt(T)
    d1 = (log(S / K) + (mu + 0.5 * ss * ss) * T) / v; d2 = d1 - v
    share, cash = S * exp((mu - rd) * T), K * exp(-rd * T)
    if put: return xbar * (cash * N(-d2) - share * N(-d1))
    return xbar * (share * N(d1) - cash * N(d2))

def call(ss=SS, sx=SX, rho=RHO, q=Q, S=S):
    return quanto(S, K, XBAR, RD, drift(RF, q, ss, sx, rho), ss, T)

MU = drift(RF, Q, SS, SX, RHO)
D1 = (log(S / K) + (MU + 0.5 * SS * SS) * T) / (SS * sqrt(T)); D2 = D1 - SS * sqrt(T)
C, P = call(), quanto(S, K, XBAR, RD, MU, SS, T, put=True)

def simpson(f, a, b, n):                    # Simpson's rule, n even
    h, total = (b - a) / n, 0.0
    for i in range(n + 1): total += (1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h)
    return h / 3 * total

def euro_world(x0, put=False, n=400):      # road 2: price in EUR under the EUR world, mu never used
    mS = (RF - Q - 0.5 * SS * SS) * T      # share drifts at its own rate rf - q
    mX = (RD - RF + SX * SX - 0.5 * SX * SX) * T   # USD per EUR drifts at rd - rf + sX^2 here
    zk = (log(K / S) - mS) / (SS * sqrt(T))        # share draw where S_T = K
    def inner(z1):
        sT = S * exp(mS + SS * sqrt(T) * z1)
        def g(z2):
            xT = x0 * exp(mX + SX * sqrt(T) * (RHO * z1 + sqrt(1 - RHO * RHO) * z2))
            return XBAR * max(K - sT if put else sT - K, 0.0) / xT * phi(z2)   # USD paid, in EUR
        return simpson(g, -9.0, 9.0, n) * phi(z1)
    lo, hi = (-9.0, zk) if put else (zk, 9.0)
    return x0 * exp(-RF * T) * simpson(inner, lo, hi, n)    # EUR price, converted at today's spot

C_115, C_200, P_int = euro_world(1.15), euro_world(2.00), euro_world(1.15, put=True)

state = [20260927]                          # road 3: Monte Carlo in the USD world, both assets
def u01():
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & (2**64 - 1); z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return ((z ^ (z >> 31)) >> 11) * 2.0**-53
n_mc, sp, sp2, sv, sv2 = 200000, 0.0, 0.0, 0.0, 0.0
for _ in range(n_mc // 2):
    r, a = sqrt(-2.0 * log(1.0 - u01())), 2.0 * pi * u01()
    z1, z2 = r * cos(a), r * sin(a)
    for s1, s2 in ((z1, z2), (-z1, -z2)):              # each draw and its mirror
        sT = S * exp((MU - 0.5 * SS * SS) * T + SS * sqrt(T) * s1)
        xT = X0 * exp((RD - RF - 0.5 * SX * SX) * T + SX * sqrt(T) * (RHO * s1 + sqrt(1 - RHO * RHO) * s2))
        pay = XBAR * max(sT - K, 0.0); sp += pay; sp2 += pay * pay
        v = sT * xT; sv += v; sv2 += v * v                # one share, valued in USD
mc = exp(-RD * T) * sp / n_mc; mc_se = exp(-RD * T) * sqrt((sp2 / n_mc - (sp / n_mc) ** 2) / n_mc)
mv, mv_se = sv / n_mc, sqrt((sv2 / n_mc - (sv / n_mc) ** 2) / n_mc)
need_v, unadj_v = S * X0 * exp((RD - Q) * T), S * X0 * exp((RD - Q + RHO * SS * SX) * T)

def bisect(f, lo, hi):                       # root finder for the vol-point translation
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
no_adj = quanto(S, K, XBAR, RD, RF - Q, SS, T)
flipped = quanto(S, K, XBAR, RD, RF - Q + RHO * SS * SX, SS, T)
vol_eq = bisect(lambda s: call(ss=s) - no_adj, 0.05, 0.60)
h = 1e-4
delta_fd = (call(S=S + h) - call(S=S - h)) / (2 * h); delta_an = XBAR * exp((MU - RD) * T) * N(D1)

rows = [("1.01 x 1.01, moving together", 1.01 * 1.01), ("1.01 x 0.99, moving apart", 1.01 * 0.99),
    ("euro growth rf - q", RF - Q), ("currency growth rd - rf", RD - RF),
    ("adjustment -rho sS sX", -RHO * SS * SX), ("mu = rf - q - rho sS sX", MU), ("d1", D1), ("d2", D2),
    ("N(d1)", N(D1)), ("N(d2)", N(D2)), ("share side S e^(mu-rd)T N(d1)", S * exp((MU - RD) * T) * N(D1)),
    ("cash side K e^-rdT N(d2)", K * exp(-RD * T) * N(D2)), ("1 formula, call", C),
    ("2 EUR world, spot 1.15", C_115), ("2 EUR world, spot 2.00", C_200),
    ("3 Monte Carlo, 200000 paths", mc), ("  standard error", mc_se),
    ("formula, put", P), ("EUR world, put", P_int), ("  C - P, both by EUR world", C_115 - P_int),
    ("  Xbar e^-rdT (S e^muT - K)", XBAR * exp(-RD * T) * (S * exp(MU * T) - K)),
    ("MC mean of S_T X_T, USD", mv), ("  standard error", mv_se),
    ("  required S X0 e^(rd-q)T", need_v), ("  if drift were rf - q", unadj_v),
    ("substitute dividend q*", RD - RF + Q + RHO * SS * SX),
    ("quanto forward S e^muT", S * exp(MU * T)), ("euro forward S e^(rf-q)T", S * exp((RF - Q) * T)),
    ("premium on 10,000 shares", 10000 * C), ("breakeven share K + C/Xbar", K + C / XBAR),
    ("wrong: no adjustment", no_adj), ("  error, USD", no_adj - C),
    ("  too dear, percent", 100 * (no_adj / C - 1)),
    ("  as share vol, points", 100 * (vol_eq - SS)), ("wrong: sign flipped", flipped),
    ("wrong: spot 1.15 for Xbar", C / XBAR * X0), ("wrong: rd in the drift", quanto(S, K, XBAR, RD, RD - Q - RHO * SS * SX, SS, T)),
    ("wrong: vol sqrt(sS^2+sX^2)", quanto(S, K, XBAR, RD, MU, sqrt(SS * SS + SX * SX), T)),
    ("wrong: dividend dropped", call(q=0.0)),
    ("delta, USD per EUR, bump", delta_fd), ("delta, Xbar e^(mu-rd)T N(d1)", delta_an),
    ("gamma, bump", (call(S=S + 0.01) - 2 * C + call(S=S - 0.01)) / 1e-4),
    ("vega, per share-vol point", (call(ss=SS + h) - call(ss=SS - h)) / (2 * h) / 100),
    ("per 0.01 of correlation", (call(rho=RHO + h) - call(rho=RHO - h)) / (2 * h) / 100),
    ("per FX-vol point", (call(sx=SX + h) - call(sx=SX - h)) / (2 * h) / 100)]
for name, v in rows: print(f"{name:<32}{v:>14.6f}")
print("chart, correlation " + " ".join(f"{r:6.2f}" for r in (-1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1)))
print("chart, call USD    " + " ".join(f"{call(rho=r):6.2f}" for r in (-1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1)))
print("chart, share EUR   " + " ".join(f"{s:6.0f}" for s in range(80, 135, 5)))
print("chart, profit USD  " + " ".join(f"{XBAR * max(s - K, 0) - C:6.2f}" for s in range(80, 135, 5)))

assert abs(C - 9.151629) < 5e-7, "formula vs the hand-worked 9.151629"
assert abs(C_115 - C) < 1e-6, "EUR-world road, spot 1.15, lands on the formula"
assert abs(C_200 - C) < 1e-6, "EUR-world road, spot 2.00: today's rate cancels"
assert abs(mc - C) < 4 * mc_se, "Monte Carlo within four standard errors"
assert abs(P - P_int) < 1e-6, "formula put vs EUR-world put"
assert abs((C_115 - P_int) - XBAR * exp(-RD * T) * (S * exp(MU * T) - K)) < 1e-6, "quanto put-call parity"
assert abs(mv - need_v) < 4 * mv_se, "USD value of one share grows at rd - q"
assert abs(mv - unadj_v) > 8 * mv_se, "without the adjustment it would grow too fast"
assert abs(delta_fd - delta_an) < 1e-6, "bumped delta vs Xbar e^(mu-rd)T N(d1)"
print("ALL CHECKS PASS")
