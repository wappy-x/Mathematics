# Greeks at the wall: EURUSD reverse knock-out (call 1.10, dies at 1.20) and one-touch at 1.20.
# Standard library only. Three roads: closed-form Greeks, bump-and-revalue of the closed-form
# price, and a Crank-Nicolson grid that never sees the formula. The normal CDF is a series.
from math import exp, log, sqrt, pi
RD, RF, K, H, SIG = 0.05, 0.03, 1.10, 1.20, 0.10      # dollar rate, euro rate, strike, wall, vol
MONTH, WEEK, DAY = 1 / 12, 1 / 52, 1 / 365

def N(x):                                  # area under the bell curve left of x, by its Taylor series
    if abs(x) > 9: return 0.0 if x < 0 else 1.0
    t = s = x; n = 0
    while abs(t) > 1e-17 * abs(s):
        n += 1; t *= x * x / (2 * n + 1); s += t
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * pi)
def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def vanilla(x, k, s, T):                   # call and cash digital at strike k: price, delta, gamma, vega
    v = s * sqrt(T); d1 = (log(x / k) + (RD - RF + 0.5 * s * s) * T) / v; d2 = d1 - v
    a, b = exp(-RF * T), exp(-RD * T)
    return ((x * a * N(d1) - k * b * N(d2), a * N(d1), a * phi(d1) / (x * v), x * a * phi(d1) * sqrt(T)),
            (b * N(d2), b * phi(d2) / (x * v), -b * phi(d2) * d1 / (x * x * v * v), -b * phi(d2) * d1 / s))
def below(prod, x, s, T, hb):              # plain price of the payoff cut off at the wall, and its Greeks
    cK = vanilla(x, K, s, T)[0]; cH, dH = vanilla(x, hb, s, T)
    if prod == "ko": return [cK[j] - cH[j] - (hb - K) * dH[j] for j in range(4)]
    return [(exp(-RD * T) if j == 0 else 0.0) - dH[j] for j in range(4)]      # no-touch piece
def closed(prod, S, s, T, hb=H, drop=False):   # mirror: V = G(S) - w G(m), w = (hb/S)^(2 lam), m = hb^2/S
    lam = (RD - RF - 0.5 * s * s) / (s * s); w = (hb / S) ** (2 * lam); m = hb * hb / S
    g, gm = below(prod, S, s, T, hb), below(prod, m, s, T, hb)
    v = g[0] - w * gm[0]
    d = g[1] + (0.0 if drop else 2 * lam * w * gm[0] / S) + w * m * gm[1] / S
    ga = (g[2] - 2 * lam * (2 * lam + 1) * w * gm[0] / S ** 2 - (4 * lam + 2) * w * m * gm[1] / S ** 2
          - w * m * m * gm[2] / S ** 2)
    ve = g[3] + w * 4 * log(hb / S) * (RD - RF) / s ** 3 * gm[0] - w * gm[3]
    if prod == "ot": return exp(-RD * T) - v, -d, -ga, -ve
    return v, d, ga, ve
def price(prod, S, s, T, hb=H):
    if S >= hb: return 0.0 if prod == "ko" else exp(-RD * T)
    return closed(prod, S, s, T, hb)[0]
def five(prod, S, s, T, e=1e-4):           # road 1: closed form; vanna, volga = vol-slopes of exact delta, vega
    c, up, dn = closed(prod, S, s, T), closed(prod, S, s + e, T), closed(prod, S, s - e, T)
    return [c[0], c[1], c[2], c[3], (up[1] - dn[1]) / (2 * e), (up[3] - dn[3]) / (2 * e)]
def bump(prod, S, s, T, h=1e-4, e=1e-4):   # road 2: bump and revalue the price only
    p = lambda x, y: price(prod, x, y, T); v = p(S, s)
    return [v, (p(S + h, s) - p(S - h, s)) / (2 * h), (p(S + h, s) - 2 * v + p(S - h, s)) / h ** 2,
            (p(S, s + e) - p(S, s - e)) / (2 * e),
            (p(S + h, s + e) - p(S + h, s - e) - p(S - h, s + e) + p(S - h, s - e)) / (4 * h * e),
            (p(S, s + e) - 2 * v + p(S, s - e)) / e ** 2]
LO, DS, STEPS = 0.90, 0.0005, 400
def grid(prod, s, T):                      # road 3: Crank-Nicolson on price x = LO..H, wall on a node
    n = round((H - LO) / DS); X = [LO + i * DS for i in range(n + 1)]
    V = [max(x - K, 0.0) for x in X] if prod == "ko" else [0.0] * n + [1.0]
    V[n] = 0.0 if prod == "ko" else 1.0; dt = T / STEPS
    A = [0.5 * s * s * x * x / DS ** 2 - 0.5 * (RD - RF) * x / DS for x in X]
    C = [0.5 * s * s * x * x / DS ** 2 + 0.5 * (RD - RF) * x / DS for x in X]
    B = [-s * s * x * x / DS ** 2 - RD for x in X]
    for k in range(STEPS):
        th = 1.0 if k < 4 else 0.5         # four fully implicit steps first, to calm the kink and the wall
        top = 0.0 if prod == "ko" else exp(-RD * (k + 1) * dt)
        r = [V[i] + (1 - th) * dt * (A[i] * V[i - 1] + B[i] * V[i] + C[i] * V[i + 1]) for i in range(1, n)]
        r[-1] += th * dt * C[n - 1] * top
        cp, dp = [0.0] * (n - 1), [0.0] * (n - 1)
        for j in range(n - 1):
            i = j + 1; a, c = -th * dt * A[i], -th * dt * C[i]
            den = 1 - th * dt * B[i] - (a * cp[j - 1] if j else 0.0)
            cp[j] = c / den; dp[j] = (r[j] - (a * dp[j - 1] if j else 0.0)) / den
        V[n - 1] = dp[n - 2]
        for j in range(n - 3, -1, -1): V[j + 1] = dp[j] - cp[j] * V[j + 2]
        V[n] = top
    return V
def from_grid(G0, Gu, Gd, S, e):          # Greeks off grid nodes; vol Greeks from grids at vol +- e
    i = round((S - LO) / DS)
    dlt = lambda V: (V[i + 1] - V[i - 1]) / (2 * DS)
    return [G0[i], dlt(G0), (G0[i + 1] - 2 * G0[i] + G0[i - 1]) / DS ** 2, (Gu[i] - Gd[i]) / (2 * e),
            (dlt(Gu) - dlt(Gd)) / (2 * e), (Gu[i] - 2 * G0[i] + Gd[i]) / e ** 2]
def root(f, a, b):                         # bisection: f(a), f(b) of opposite sign
    fa = f(a)
    for _ in range(80):
        m = 0.5 * (a + b)
        if (f(m) > 0) == (fa > 0): a, fa = m, f(m)
        else: b = m
    return 0.5 * (a + b)
def touch(S, s, T):                        # one-touch as discounted touch chance: an independent formula
    b, nu, v = log(H / S), RD - RF - 0.5 * s * s, s * sqrt(T)
    return exp(-RD * T) * (N((nu * T - b) / v) + (H / S) ** (2 * nu / s / s) * N((-b - nu * T) / v))

UNIT = {"ko": [1e4, 1, 0.01, 100, 0.01, 1], "ot": [100, 1, 0.01, 1, 0.01, 0.01]}   # desk units
def desk(prod, g): return [x * u for x, u in zip(g, UNIT[prod])]
print("house cross-checks, one year, spot 1.10")
print(f"  reverse knock-out, pips               {price('ko', 1.10, SIG, 1.0) * 1e4:10.2f}")
print(f"  one-touch, mirror of digital          {price('ot', 1.10, SIG, 1.0):10.6f}")
print(f"  one-touch, discounted touch chance    {touch(1.10, SIG, 1.0):10.6f}")
E = 0.001
grids = {p: [grid(p, SIG, MONTH), grid(p, SIG + E, MONTH), grid(p, SIG - E, MONTH)] for p in ("ko", "ot")}
names = ["price", "delta", "gamma", "vega", "vanna", "volga"]
print("one month left; units: KO pips, OT % of payout; gamma per cent, vega/vanna/volga per vol point")
print("                     closed form    bump    grid")
for prod, S in (("ko", 1.10), ("ko", 1.19), ("ot", 1.19)):
    rows = [desk(prod, five(prod, S, SIG, MONTH)), desk(prod, bump(prod, S, SIG, MONTH)),
            desk(prod, from_grid(*grids[prod], S, E))]
    for j in range(6):
        print(f"  {prod} {S:.2f} {names[j]:<6}  {rows[0][j]:12.4f} {rows[1][j]:9.4f} {rows[2][j]:9.4f}")
        assert abs(rows[1][j] - rows[0][j]) < 1e-4 * (1 + abs(rows[0][j]))       # bump agrees with closed form
        assert abs(rows[2][j] - rows[0][j]) < 1e-3 * (1 + abs(rows[0][j]))       # grid agrees with closed form
assert abs(price("ot", 1.10, SIG, 1.0) - touch(1.10, SIG, 1.0)) < 1e-12        # two one-touch formulas agree
lam, S = (RD - RF - 0.5 * SIG ** 2) / SIG ** 2, 1.19; w, m = (H / S) ** (2 * lam), H * H / S   # the hand table
g, gm = below("ko", S, SIG, MONTH, H), below("ko", m, SIG, MONTH, H)
print(f"worked, KO 1.19, month: lam {lam:.4f}  w {w:.6f}  m {m:.6f}  G(S) {g[0]:.6f}  G(m) {gm[0]:.6f}  price {g[0] - w * gm[0]:.6f}")
print(f"  delta terms: G'(S) {g[1]:.6f}  2 lam w G(m)/S {2 * lam * w * gm[0] / S:.6f}  w m G'(m)/S {w * m * gm[1] / S:.6f}")
print("sweep, one month: closed form   KO pips  delta  gamma   vega |  OT %   delta   vega")
for S in (1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.18, 1.19, 1.195, 1.199):
    k, o = desk("ko", closed("ko", S, SIG, MONTH)), desk("ot", closed("ot", S, SIG, MONTH))
    print(f"  spot {S:<6.3f}  {k[0]:20.2f} {k[1]:6.2f} {k[2]:6.2f} {k[3]:6.2f} | {o[0]:5.2f} {o[1]:7.2f} {o[3]:6.2f}")
f = lambda j, t: (lambda S: closed("ko", S, SIG, MONTH)[j] - t)
print(f"  KO delta 0 at {root(f(1, 0), 1.12, 1.18):.4f}, delta -1 at {root(f(1, -1), 1.16, 1.19):.4f}, "
      f"vega 0 at {root(f(3, 0), 1.10, 1.13):.4f}, gamma 0 at {root(f(2, 0), 1.10, 1.13):.4f}")
print(f"  OT gamma 0 at {root(lambda S: closed('ot', S, SIG, MONTH)[2], 1.19, 1.199):.4f}; "
      "KO vega 0 at, week / day: " + " / ".join(f"{root(lambda S: closed('ko', S, SIG, T)[3], 1.10, 1.1999):.4f}" for T in (WEEK, DAY)))
print("T left    KO delta 1.199  at wall  wall-delta rule  KO gamma 1.199  OT delta 1.199")
for lab, T in (("month", MONTH), ("week", WEEK), ("day", DAY)):
    rule = 1 - (H - K) * sqrt(2 / pi) / (H * SIG * sqrt(T))      # wall-delta rule, near expiry
    print(f"  {lab:<6} {closed('ko', 1.199, SIG, T)[1]:16.4f} {closed('ko', H, SIG, T)[1]:8.4f} {rule:17.4f} "
          f"{closed('ko', 1.199, SIG, T)[2] * 0.01:15.4f} {closed('ot', 1.199, SIG, T)[1]:15.4f}")
    assert abs(closed("ko", H, SIG, T)[1] - rule) < 0.05 * abs(rule)             # blow-up law holds
print("barrier shift, one month   wall 1.2010   wall 1.2020   wall 1.2050  (KO reserve, pips)")
for S in (1.10, 1.19):
    print(f"  spot {S:.2f}          " + "".join(f"{(price('ko', S, SIG, MONTH, H + d) - price('ko', S, SIG, MONTH)) * 1e4:14.2f}" for d in (0.001, 0.002, 0.005)))
res, cost = price("ko", H, SIG, MONTH, H + 0.001), -closed("ko", H, SIG, MONTH)[1] * 0.001
print(f"  at spot 1.20, wall 1.2010: KO worth {res * 1e4:.2f} pips; |delta at wall| x 10 pips = {cost * 1e4:.2f}")
assert abs(res - cost) < 0.1 * cost                                              # shift pays for the unwind
print(f"  OT sold: wall pulled to 1.1990, reserve % at 1.10 / 1.19: " + " / ".join(f"{(price('ot', S, SIG, MONTH, H - 0.001) - price('ot', S, SIG, MONTH)) * 100:.2f}" for S in (1.10, 1.19)))
vd = vanilla(1.19, K, SIG, MONTH)[0][1]
up, mid, dn = (price("ko", x, SIG, MONTH) for x in (1.205, 1.195, 1.185))
print(f"what breaks at 1.19: vanilla delta {vd:.4f}; weight slope dropped {closed('ko', 1.19, SIG, MONTH, H, True)[1]:.4f}")
print(f"  at 1.195, one-cent bump across the wall: delta {(up - dn) / 0.02:.4f}, gamma per cent {(up - 2 * mid + dn) / 1e-4 * 0.01:.4f}")
print("ALL CHECKS PASS")
