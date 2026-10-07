# Hedging a quanto -- the check behind the card.  Python standard library only.
# Every number quoted on the card is printed here.  The normal CDF is a series
# written out, the tree is a loop, the random numbers are splitmix64.
from math import log, sqrt, exp, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                  # bell-curve area left of x
    if x < 0.0: return 1.0 - N(-x)
    if x > 8.5: return 1.0
    term, total, k = x, x, 0
    while term > 1e-17 * total:
        k += 1; term *= x * x / (2 * k + 1); total += term
    return 0.5 + phi(x) * total

S0, K, XBAR, X0 = 100.0, 100.0, 1.10, 1.15   # share EUR, strike EUR, fixed USD/EUR, spot USD/EUR
RD, RF, Q = 0.05, 0.03, 0.01                 # USD rate, EUR rate, dividend yield
A, B, RHO, T = 0.20, 0.10, 0.30, 1.0         # share vol, FX vol, correlation, years

def price(S=S0, a=A, b=B, rho=RHO, rd=RD, rf=RF, t=T):     # road 1: the closed form, in USD
    mu, w = rf - Q - rho * a * b, a * sqrt(t)
    d1 = (log(S / K) + (mu + 0.5 * a * a) * t) / w
    return XBAR * exp(-rd * t) * (S * exp(mu * t) * N(d1) - K * N(d1 - w))

def delta(S, t):                                           # V_S, USD per EUR of share price
    mu = RF - Q - RHO * A * B
    return XBAR * exp((mu - RD) * t) * N((log(S / K) + (mu + 0.5 * A * A) * t) / (A * sqrt(t)))

MU = RF - Q - RHO * A * B; W = A * sqrt(T)
D1 = (log(S0 / K) + (MU + 0.5 * A * A) * T) / W
V, VS = price(), delta(S0, T)
g = {"delta, USD per EUR": VS,                              # the Greeks by differentiating the formula
     "gamma, USD per EUR^2": XBAR * exp((MU - RD) * T) * phi(D1) / (S0 * W),
     "share vega, per unit": XBAR * exp(-RD * T) * S0 * exp(MU * T) * (sqrt(T) * phi(D1) - RHO * B * T * N(D1)),
     "FX vega, per unit": -RHO * A * T * S0 * VS,
     "USD rho, per unit": -T * V,
     "EUR rho, per unit": T * S0 * VS,
     "correlation, per unit": -A * B * T * S0 * VS}
h = 1e-4                                                   # the same Greeks by bump-and-revalue
bump = [(price(S=S0 + 0.01) - price(S=S0 - 0.01)) / 0.02,
        (price(S=S0 + 0.01) - 2 * V + price(S=S0 - 0.01)) / 1e-4,
        (price(a=A + h) - price(a=A - h)) / (2 * h), (price(b=B + h) - price(b=B - h)) / (2 * h),
        (price(rd=RD + h) - price(rd=RD - h)) / (2 * h), (price(rf=RF + h) - price(rf=RF - h)) / (2 * h),
        (price(rho=RHO + h) - price(rho=RHO - h)) / (2 * h)]

def tree(n, rho=RHO):              # road 2: two-asset tree; drifts come from no-arbitrage, mu never used
    hh = T / n; sh = sqrt(hh); be = sqrt(1.0 - rho * rho)
    mX = (exp(B * sh) + exp(-B * sh)) / 2.0                 # average FX step, four branches
    AX = exp((RD - RF) * hh) / mX                           # a euro deposit grows at rd in USD
    mSX = sum(exp(B * sh * e1 + A * sh * (rho * e1 + be * e2)) for e1 in (1, -1) for e2 in (1, -1)) / 4.0
    AS = exp((RD - Q) * hh) / (AX * mSX)                    # a share held in USD grows at rd - q
    v = [[XBAR * max(S0 * AS ** n * exp(A * sh * (rho * (2 * i - n) + be * (2 * j - n))) - K, 0.0)
          for j in range(n + 1)] for i in range(n + 1)]
    disc = exp(-RD * hh) / 4.0
    for m in range(n, 0, -1):
        v = [[disc * (v[i][j] + v[i + 1][j] + v[i][j + 1] + v[i + 1][j + 1]) for j in range(m)] for i in range(m)]
    step = sum(exp(A * sh * (rho * e1 + be * e2)) for e1 in (1, -1) for e2 in (1, -1)) / 4.0
    return v[0][0], S0 * (AS * step) ** n

t100, _ = tree(100); t200, fwd200 = tree(200)
t_rho = (tree(200, RHO + 0.05)[0] - tree(200, RHO - 0.05)[0]) / 0.1

state = [20260927]                                         # road 3: hedge it, daily, 2000 paths
def u01():
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

def hedge_book(paths=2000, steps=252):     # strategies: full, no euro loan, loan frozen, shares = V_S
    dt, be = T / steps, sqrt(1.0 - RHO * RHO)
    err = [[] for _ in range(4)]; cost = 0.0
    for _ in range(paths):
        S, X = S0, X0
        eta = [VS / X, VS / X, VS / X, VS]
        f = [-eta[0] * S, 0.0, -eta[2] * S, -eta[3] * S]
        d = [V - eta[k] * S * X - f[k] * X for k in range(4)]
        for s in range(1, steps + 1):
            r1, r2 = sqrt(-2.0 * log(u01())), 2.0 * pi * u01()
            z1, z2 = r1 * cos(r2), r1 * sin(r2)
            X *= exp((RD - RF - 0.5 * B * B) * dt + B * sqrt(dt) * z1)
            S *= exp((MU - 0.5 * A * A) * dt + A * sqrt(dt) * (RHO * z1 + be * z2))
            vs = delta(S, T - s * dt) if s < steps else 0.0
            for k in range(4):
                d[k] = d[k] * exp(RD * dt) + eta[k] * S * (exp(Q * dt) - 1.0) * X
                f[k] *= exp(RF * dt)
                if s == steps: continue
                ne = vs if k == 3 else vs / X
                nf = f[k] if k == 2 else (0.0 if k == 1 else -ne * S)
                d[k] -= (ne - eta[k]) * S * X + (nf - f[k]) * X
                eta[k], f[k] = ne, nf
        pay = XBAR * max(S - K, 0.0)
        for k in range(4): err[k].append(eta[k] * S * X + f[k] * X + d[k] - pay)
    ms = [(sum(e) / len(e), sqrt(sum(x * x for x in e) / len(e) - (sum(e) / len(e)) ** 2)) for e in err]
    return ms

hb = hedge_book()
VW = XBAR * exp(-RD * T) * S0 * exp(MU * T) * sqrt(T) * phi(D1)       # vega of the width alone
mc3 = V - exp(-RD * T) * hb[0][0]; mc3_se = exp(-RD * T) * hb[0][1] / sqrt(2000)

rows = [("rho a b", RHO * A * B), ("mu = rf - q - rho a b", MU), ("d1", D1), ("N(d1)", N(D1)), ("phi(d1)", phi(D1)),
        ("e^(mu - rd)T", exp((MU - RD) * T)), ("phi(d1) - rho b T N(d1)", sqrt(T) * phi(D1) - RHO * B * T * N(D1)),
        ("1 formula, call USD", V), ("2 tree, 100 steps", t100), ("2 tree, 200 steps", t200),
        ("2 tree, 2 x 200 - 100", 2 * t200 - t100), ("  tree mean share EUR", fwd200),
        ("  quanto forward S e^muT", S0 * exp(MU * T)), ("3 hedged simulation, call USD", mc3),
        ("  standard error", mc3_se), ("  rule of thumb, daily spread", sqrt(pi / 4) * VW * A / sqrt(252))]
for name, v in rows: print(f"{name:<34}{v:>14.6f}")
print(f"{'Greek':<26}{'formula':>14}{'bump':>14}")
for (name, v), bv in zip(g.items(), bump): print(f"{name:<26}{v:>14.6f}{bv:>14.6f}")
more = [("  correlation, tree bump", t_rho), ("share vega, per point", g["share vega, per unit"] / 100),
        ("FX vega, per point", g["FX vega, per unit"] / 100), ("correlation, per 0.01", g["correlation, per unit"] / 100),
        ("hedge: shares = V_S / X", VS / X0), ("hedge: euro loan EUR", -VS / X0 * S0),
        ("hedge: euro loan in USD", -VS * S0), ("hedge: dollar cash USD", V),
        ("wrong: shares = V_S", VS), ("wrong: vega, drift frozen", VW / 100),
        ("wrong: delta, no adjustment", XBAR * exp((RF - Q - RD) * T) * N((log(S0 / K) + (RF - Q + 0.5 * A * A) * T) / W)),
        ("shares at X = 1.25", VS / 1.25), ("euro loan at X = 1.25", -VS / 1.25 * S0)]
for name, v in more: print(f"{name:<34}{v:>14.6f}")
print("resize, share EUR     " + " ".join(f"{s:7.0f}" for s in (80, 90, 100, 110, 120)))
print("resize, shares        " + " ".join(f"{delta(s, T) / X0:7.4f}" for s in (80, 90, 100, 110, 120)))
print("resize, euro loan EUR " + " ".join(f"{-delta(s, T) / X0 * s:7.2f}" for s in (80, 90, 100, 110, 120)))
rhos = (-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0)
print("chart, correlation    " + " ".join(f"{r:6.2f}" for r in rhos))
print("chart, call USD       " + " ".join(f"{price(rho=r):6.2f}" for r in rhos))
print(f"{'average slope, -1 to +1':<34}{(price(rho=1.0) - price(rho=-1.0)) / 2.0:>14.6f}")
for name, (m, sd) in zip(("full hedge", "no euro loan", "euro loan frozen", "shares = V_S"), hb):
    print(f"hedge error, {name:<18} mean {m:9.4f}  spread {sd:8.4f}")

assert abs(V - 9.151629) < 5e-7, "formula vs the hand-worked 9.151629"
assert abs(2 * t200 - t100 - V) < 0.002, "two-asset tree, extrapolated, lands on the formula"
assert abs(fwd200 - S0 * exp(MU * T)) < 1e-3, "the tree finds the quanto drift without being told it"
assert abs(mc3 - V) < 4 * mc3_se, "hedged simulation within four standard errors"
for (name, v), bv in zip(g.items(), bump):
    assert abs(v - bv) < 1e-5 * max(1.0, abs(v)), "Greek formula vs bump: " + name
assert abs(t_rho - g["correlation, per unit"]) < 0.01, "tree bump vs correlation Greek"
assert abs(hb[0][1] - sqrt(pi / 4) * VW * A / sqrt(252)) < 0.1, "full hedge spread vs the rule of thumb"
assert hb[1][1] > 5 * hb[0][1] and hb[2][1] > 2 * hb[0][1] and hb[3][1] > 2 * hb[0][1], "every broken hedge is worse"
print("ALL CHECKS PASS")
