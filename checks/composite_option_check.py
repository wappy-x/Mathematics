# Composite option -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  The normal CDF, the
# integrals and the bumps are written out; nothing imported knows the answer.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def N(x):                                                  # bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)

def bs_call(S, K, r, q, v, T):                             # Black-Scholes, dividend yield q
    d1 = (log(S / K) + (r - q + 0.5 * v * v) * T) / (v * sqrt(T))
    d2 = d1 - v * sqrt(T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2), d1, d2

# ---- the house market ----
S, K_eur, X0, rd, rf, q = 100.0, 100.0, 1.10, 0.05, 0.03, 0.01
sS, sX, rho, T = 0.20, 0.10, 0.30, 1.0
K = K_eur * X0                                             # dollar strike, 110

def comp_vol(rho): return sqrt(sS * sS + sX * sX + 2.0 * rho * sS * sX)
def composite(rho, S=S, X=X0, sS_=None):                   # road 1: the formula
    s1 = sS if sS_ is None else sS_
    v = sqrt(s1 * s1 + sX * sX + 2.0 * rho * s1 * sX)
    return bs_call(S * X, K, rd, q, v, T)
def quanto(rho):                                           # the sibling card's price
    c, _, _ = bs_call(S, K_eur, rd, rd - (rf - q - rho * sS * sX), sS, T)
    return X0 * c
plain = X0 * bs_call(S, K_eur, rf, q, sS, T)[0]            # euro call, paid in euros

# ---- roads 2 and 3: brute-force average over two linked bell curves ----
def avg2(f, m=0.0, n=600, L=8.0):   # E f(z1, z2), z1 and z2 independent; z1's grid centred on m
    h = 2 * L / n
    w = [(1 if i in (0, n) else (4 if i % 2 else 2)) * h / 3.0 for i in range(n + 1)]
    zs = [-L + i * h for i in range(n + 1)]
    c = sqrt(1.0 - rho * rho)
    tot = [0.0] * 6
    for i, a0 in enumerate(zs):
        a = a0 + m
        for j, b in enumerate(zs):
            vals = f(a, rho * a + c * b)
            ww = w[i] * phi(a) * w[j] * phi(b)
            for k in range(len(vals)): tot[k] += ww * vals[k]
    return tot

def usd_world(zS, zX):          # dollar pricing world: share slowed by rho sS sX, euro grows at rd - rf
    ST = S * exp((rf - q - rho * sS * sX - 0.5 * sS * sS) * T + sS * sqrt(T) * zS)
    XT = X0 * exp((rd - rf - 0.5 * sX * sX) * T + sX * sqrt(T) * zX)
    V = ST * XT
    return (max(V - K, 0.0), max(K - V, 0.0), X0 * max(ST - K_eur, 0.0),
            XT * max(ST - K_eur, 0.0), log(V / (S * X0)), log(V / (S * X0)) ** 2)
def eur_world(zS, zX):          # euro pricing world: share grows at rf - q, the dollar at rf - rd
    ST = S * exp((rf - q - 0.5 * sS * sS) * T + sS * sqrt(T) * zS)
    inv_XT = exp((rf - rd - 0.5 * sX * sX) * T - sX * sqrt(T) * zX) / X0
    return (max(ST - K * inv_XT, 0.0), 0, 0, 0, 0, 0)       # payoff in euros: S_T - K / X_T

m = (log(K_eur / S) - (rf - q - rho * sS * sX - 0.5 * sS * sS) * T) / (sS * sqrt(T))
u = avg2(usd_world, m)                                     # m: the euro strike's line sits on a node
e = avg2(eur_world)
C, d1, d2 = composite(rho)
C_usd, P_usd, Q_int, plain_int = [exp(-rd * T) * x for x in u[:4]]
C_eur = X0 * exp(-rf * T) * e[0]
vol_int = sqrt((u[5] - u[4] ** 2) / T)
h = 1e-4
dS = (composite(rho, S=S + h)[0] - composite(rho, S=S - h)[0]) / (2 * h)
dX = (composite(rho, X=X0 + h)[0] - composite(rho, X=X0 - h)[0]) / (2 * h)
dr = (composite(rho + h)[0] - composite(rho - h)[0]) / (2 * h)
dsS = (composite(rho, sS_=sS + h)[0] - composite(rho, sS_=sS - h)[0]) / (2 * h)
vega = S * X0 * exp(-q * T) * phi(d1) * sqrt(T)
rows = [
    ("cross term 2 rho sS sX", 2 * rho * sS * sX), ("composite variance", comp_vol(rho) ** 2),
    ("composite vol", comp_vol(rho)), ("  vol from the log-moments integral", vol_int),
    ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)),
    ("share side V e^-qT N(d1)", S * X0 * exp(-q * T) * N(d1)),
    ("cash side K e^-rdT N(d2)", K * exp(-rd * T) * N(d2)),
    ("1 composite call, formula", C), ("2 dollar-world integral", C_usd),
    ("3 euro-world integral", C_eur), ("4 put by integral", P_usd),
    ("  C - P", C - P_usd), ("  S X e^-qT - K e^-rdT", S * X0 * exp(-q * T) - K * exp(-rd * T)),
    ("quanto drift rf - q - rho sS sX", rf - q - rho * sS * sX), ("quanto call, formula", quanto(rho)), ("  quanto by integral", Q_int),
    ("plain euro call x 1.10, formula", plain), ("  plain by integral", plain_int),
    ("delta, shares e^-qT N(d1)", exp(-q * T) * N(d1)), ("  bump S, per EUR", dS),
    ("  X e^-qT N(d1)", X0 * exp(-q * T) * N(d1)), ("  bump X, per 1.00 of rate", dX),
    ("  S e^-qT N(d1)", S * exp(-q * T) * N(d1)), ("vega per unit composite vol", vega),
    ("dC/drho, bump", dr), ("  vega x sS sX / vol", vega * sS * sX / comp_vol(rho)),
    ("dC/dsigma_S, bump", dsS), ("  vega x (sS + rho sX) / vol", vega * (sS + rho * sX) / comp_vol(rho)),
    ("breakeven dollar value", K + C),
    ("wrong: vol sqrt(sS^2 + sX^2)", composite(0.0)[0]),
    ("wrong: vol sS alone", bs_call(S * X0, K, rd, q, sS, T)[0]),
    ("wrong: vol sS + sX", composite(1.0)[0]),
    ("wrong: grows at the euro rate rf - q", bs_call(S * X0, K, rd, q + rd - rf, comp_vol(rho), T)[0]),
]
for name, v in rows: print(f"{name:<36} {v:>12.6f}")
print("scenario  share  USD per EUR  dollar value  quanto  composite  plain")
for sh, x in ((120.0, 1.30), (120.0, 0.90), (95.0, 1.30), (110.0, 1.10)):
    print(f"scenario {sh:6.0f} {x:12.2f} {sh * x:13.2f} {X0 * max(sh - K_eur, 0):8.2f}"
          f" {max(sh * x - K, 0):10.2f} {x * max(sh - K_eur, 0):6.2f}")
rhos = [-1.0 + 0.25 * i for i in range(9)]
print("chart, rho      " + " ".join(f"{r_:6.2f}" for r_ in rhos))
print("chart, composite" + " ".join(f"{composite(r_)[0]:6.2f}" for r_ in rhos))
print("chart, quanto   " + " ".join(f"{quanto(r_):6.2f}" for r_ in rhos))
print("chart, plain    " + " ".join(f"{plain:6.2f}" for r_ in rhos))
print("chart, comp vol " + " ".join(f"{comp_vol(r_):6.3f}" for r_ in rhos))
vs = [90.0 + 10.0 * i for i in range(7)]
print("payoff, value   " + " ".join(f"{v:6.0f}" for v in vs))
print("payoff, profit  " + " ".join(f"{max(v - K, 0) - C:6.2f}" for v in vs))

assert abs(C_usd - C) < 1e-5, "dollar-world integral must land on the formula"
assert abs(C_eur - C) < 1e-5, "euro-world integral, no drift adjustment, must agree"
assert abs((C - P_usd) - (S * X0 * exp(-q * T) - K * exp(-rd * T))) < 1e-5, "parity"
assert abs(vol_int - comp_vol(rho)) < 1e-6, "spread of log(S X) is the composite vol"
assert abs(Q_int - 9.151629) < 1e-5, "quanto integral matches the sibling card's price"
assert abs(plain_int - plain) < 1e-5, "plain call converted at expiry: integral vs formula"
assert abs(dr - vega * sS * sX / comp_vol(rho)) < 1e-4, "correlation sensitivity"
print("ALL CHECKS PASS")
