# Theta pays for gamma -- the check behind the card.  Python standard library only.
# Every number quoted on the card is printed here.  The bell-curve area N is a power
# series written out below (no erf); the random numbers are splitmix64 and Box-Muller,
# written out; the root finder is bisection.  Nothing imported already knows the answer.
from math import log, sqrt, exp, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def N(x):                                                  # bell-curve area left of x
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term = total = x; k = 1
    while abs(term) > 1e-18 * abs(total):                  # x + x^3/3 + x^5/15 + ...
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

K, r, q, sig, T, S0 = 100.0, 0.05, 0.02, 0.20, 1.0, 100.0  # the house market
def d1(S, s, t): return (log(S / K) + (r - q + 0.5 * s * s) * t) / (s * sqrt(t))
def call(S, s, t):
    a = d1(S, s, t); return S * exp(-q * t) * N(a) - K * exp(-r * t) * N(a - s * sqrt(t))
def dg(S, t):                                              # delta and gamma from one d1
    a = d1(S, sig, t); return exp(-q * t) * N(a), exp(-q * t) * phi(a) / (S * sig * sqrt(t))
def theta(S, s, t):                                        # the formula's own calendar slope
    a = d1(S, s, t); b = a - s * sqrt(t)
    return -S * exp(-q * t) * phi(a) * s / (2 * sqrt(t)) - r * K * exp(-r * t) * N(b) + q * S * exp(-q * t) * N(a)

# ---- road 1: the identity, with delta and gamma found by bumping the price ----
V, TH = call(S0, sig, T), theta(S0, sig, T)
D, G = dg(S0, T)
h = 0.01
Db = (call(S0 + h, sig, T) - call(S0 - h, sig, T)) / (2 * h)
Gb = (call(S0 + h, sig, T) - 2 * V + call(S0 - h, sig, T)) / (h * h)
THb = (call(S0, sig, T - 1e-4) - call(S0, sig, T + 1e-4)) / 2e-4
rent, carry, fund = 0.5 * sig * sig * S0 * S0 * Gb, (r - q) * S0 * Db, r * V
TH_id = fund - carry - rent
# ---- road 2: one trading day, revalued in full, for the seller of the call ----
dt = 1.0 / 252
def day_pnl(dS):
    return -(call(S0 + dS, sig, T - dt) - V) + D * dS + (V - D * S0) * (exp(r * dt) - 1) + q * D * S0 * dt
def bisect(a, b):
    for _ in range(200):
        m = 0.5 * (a + b)
        if (day_pnl(a) > 0) == (day_pnl(m) > 0): a = m
        else: b = m
    return 0.5 * (a + b)
up, dn, be = bisect(0.0, 5.0), bisect(-5.0, 0.0), sig * S0 * sqrt(dt)
rows = [("call price V", V), ("delta, formula", D), ("delta, bumped", Db), ("gamma, formula", G),
        ("gamma, bumped", Gb), ("theta per year, formula", TH), ("theta per year, bumped clock", THb),
        ("rent  1/2 sig^2 S^2 gamma", rent), ("carry (r-q) S delta", carry), ("funding r V", fund),
        ("theta from the identity", TH_id), ("rent per trading day", rent * dt),
        ("theta per trading day", TH * dt), ("theta per calendar day", TH / 365),
        ("carry less funding per trading day", (carry - fund) * dt),
        ("break-even move sig S root(dt)", be), ("break-even, weekly hedge", sig * S0 * sqrt(5 * dt)),
        ("break-even up, bisection", up),
        ("break-even down, bisection", dn), ("  average size", 0.5 * (up - dn)),
        ("wrong: drop the 1/2, theta", fund - carry - 2 * rent),
        ("wrong: sigma not sigma^2, theta", fund - carry - rent / sig),
        ("wrong: theta = -rent alone", -rent), ("wrong: sig S dt, break-even", sig * S0 * dt),
        ("wrong: unfinanced break-even", sqrt(-2 * TH * dt / G))]
for name, v in rows: print(f"{name:<34} {v:>12.6f}")
moves = [-3.0 + 0.5 * i for i in range(13)]
print("chart, move ($)   " + " ".join(f"{m:6.1f}" for m in moves))
print("chart, cents      " + " ".join(f"{100 * day_pnl(m):6.2f}" for m in moves))

# ---- road 3: hedge 2,000 simulated years, rebalancing n times ----
M64 = (1 << 64) - 1
def normals(seed):
    x = seed
    def u():
        nonlocal x
        x = (x + 0x9E3779B97F4A7C15) & M64
        z = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    while True:
        a, b = u(), u(); R = sqrt(-2.0 * log(a))
        yield R * cos(2 * pi * b); yield R * sin(2 * pi * b)

def hedge(n, sw, mu, paths=2000, seed=2026):
    """Seller of the call at 20%, delta-hedged n times; the world moves at sw with drift mu."""
    d_t = T / n; g = normals(seed); out, pred, story = [], [], []
    for p in range(paths):
        S, dl, gm, cash, gs = S0, D, G, V - D * S0, 0.0
        for i in range(n):
            Sn = S * exp((mu - 0.5 * sw * sw) * d_t + sw * sqrt(d_t) * next(g))
            cash = cash * exp(r * d_t) + q * dl * S * d_t       # interest, and dividends on the shares
            gs += 0.5 * gm * (sig * sig * S * S * d_t - (Sn - S) ** 2) * exp(r * (T - (i + 1) * d_t))
            S, left = Sn, T - (i + 1) * d_t
            if i < n - 1:
                dn_, gm = dg(S, left); cash -= (dn_ - dl) * S; dl = dn_
            if p == 0 and (i + 1) % (n // 4) == 0:
                mark = cash + dl * S - (call(S, sig, left) if left > 1e-12 else max(S - K, 0.0))
                story.append((i + 1, S, mark, gs))
        out.append(cash + dl * S - max(S - K, 0.0)); pred.append(gs)
    return out, pred, story

def stats(xs):
    m = sum(xs) / len(xs); sd = sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))
    return m, sd, sd / sqrt(len(xs))
A, Ap, story = hedge(252, 0.20, r - q)
print("story: day, Acme, seller's P&L marked, gamma-weighted sum")
for day, S, mark, gs in story: print(f"  day {day:>3}   Acme {S:7.2f}   P&L {mark:+8.4f}   sum {gs:+8.4f}")
print("rebalances   mean      sd   sd*root(n)")
sds = {}
for n in (21, 63, 252):
    xs = A if n == 252 else hedge(n, 0.20, r - q)[0]
    m, sd, se = stats(xs); sds[n] = sd
    print(f"  n = {n:>3}  {m:+.4f}  {sd:.4f}  {sd * sqrt(n):.4f}")
mA, sdA, seA = stats(A); diff = stats([a - b for a, b in zip(A, Ap)])
srt = sorted(A)
print(f"daily, 20% world: std error {seA:.4f}; 5th pct {srt[99]:+.4f}; 95th pct {srt[1899]:+.4f}")
print(f"daily, 20% world: gamma-sum mean {stats(Ap)[0]:+.4f}; sd of (P&L - sum) {diff[1]:.4f}")
Cw, Cp, _ = hedge(252, 0.30, r - q)
mC, sdC, seC = stats(Cw); gap = call(S0, 0.30, T) - V
print(f"daily, 30% world: mean {mC:+.4f}  sd {sdC:.4f}  std error {seC:.4f}  gamma-sum mean {stats(Cp)[0]:+.4f}")
print(f"daily, 30% world: paths that made money {sum(1 for x in Cw if x > 0)}; best path {max(Cw):+.4f}")
print(f"price gap C(30%) - C(20%) {gap:.4f}; carried to expiry {gap * exp(r * T):.4f}; vega x 0.10 {0.10 * sqrt(T) * S0 * exp(-q * T) * phi(d1(S0, sig, T)):.4f}")
mD = stats(hedge(252, 0.20, 0.15)[0])
print(f"daily, 20% world, drift 15%: mean {mD[0]:+.4f}  sd {mD[1]:.4f}")
edges = [-9.0 + 0.5 * i for i in range(23)]
def hist(xs): return [sum(1 for x in xs if lo <= min(max(x, -8.999), 1.999) < lo + 0.5) for lo in edges[:-1]]
print("hist, bin start " + " ".join(f"{e:5.1f}" for e in edges[:-1]))
print("hist, 20% world " + " ".join(f"{c:5d}" for c in hist(A)))
print("hist, 30% world " + " ".join(f"{c:5d}" for c in hist(Cw)))

assert abs(TH - (-5.089319)) < 5e-7,               "theta vs the house number from the theta card"
assert abs(TH_id - TH) < 1e-5,                     "identity with bumped Greeks vs the closed-form theta"
assert abs(THb - TH) < 1e-6,                       "bumped clock vs the closed-form theta"
assert abs(0.5 * (up - dn) - be) < 0.002,          "full-revaluation break-even vs sig S root(dt)"
assert abs(mA) < 3 * seA,                          "matched world: hedge centred on zero"
assert abs(sds[21] / sds[252] / sqrt(12) - 1) < 0.1, "spread falls like one over root n"
assert abs(mC + gap * exp(r * T)) < 4 * seC,       "30% world: loss is the price gap carried forward"
assert diff[1] < 0.25 * sdA,                       "the gamma-weighted sum tracks each path"
print("ALL CHECKS PASS")
