# Knock-out and knock-in by reflection -- the check behind the card.  Standard library only.
# House FX market: EURUSD 1.10 (dollars per euro), USD rate 5%, EUR rate 3%, volatility 10%,
# one year, EUR call struck at 1.10, knocked out if EURUSD ever trades at 1.05 or lower.
# Nothing imported knows the answer: the bell-curve area is a series, the integrals are
# Simpson's rule, the lattice is a loop, and the random numbers come from our own generator.
from math import exp, log, sqrt, pi, cos, sin
from operator import mul

S, K, H, RD, RF, SIG, T = 1.10, 1.10, 1.05, 0.05, 0.03, 0.10, 1.0
PIP, BETA = 1e-4, 0.5826                       # 1 pip = 0.0001 USD; BETA = -zeta(1/2)/sqrt(2 pi), rounded

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)        # bell-curve height at x
def N(x):                                                      # bell-curve area left of x, by its series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term = total = x; k = 0
    while abs(term) > 1e-17 * abs(total):
        k += 1; term *= x * x / (2 * k + 1); total += term
    return 0.5 + phi(x) * total

def call(s, k, sig=SIG, t=T, rd=RD, rf=RF):                    # Garman-Kohlhagen EUR call, USD per EUR
    v = sig * sqrt(t); d1 = (log(s / k) + (rd - rf + 0.5 * sig * sig) * t) / v
    return s * exp(-rf * t) * N(d1) - k * exp(-rd * t) * N(d1 - v)
def lam(sig=SIG, rd=RD, rf=RF): return (rd - rf - 0.5 * sig * sig) / (sig * sig)
def dao(s, k, h, sig=SIG, t=T, rd=RD, rf=RF):                  # Road 1: plain call minus its weighted mirror
    if s <= h: return 0.0
    return call(s, k, sig, t, rd, rf) - (h / s) ** (2 * lam(sig, rd, rf)) * call(h * h / s, k, sig, t, rd, rf)
def dai_rr(s, k, h, sig=SIG, t=T, rd=RD, rf=RF):               # Road 3: knock-in in the Reiner-Rubinstein form,
    L = (rd - rf + 0.5 * sig * sig) / (sig * sig); v = sig * sqrt(t)   # a different lambda, written apart
    y = log(h * h / (s * k)) / v + L * v
    return s * exp(-rf * t) * (h / s) ** (2 * L) * N(y) - k * exp(-rd * t) * (h / s) ** (2 * L - 2) * N(y - v)

def two_humps(n=2000):                                         # Road 2: integrate the payoff against the
    nu, v2, b = RD - RF - 0.5 * SIG * SIG, SIG * SIG * T, log(H / S)   # reflected density; no N, no d1
    dens = lambda y: (exp(-(y - nu * T) ** 2 / (2 * v2)) - exp(2 * nu * b / (SIG * SIG))
                      * exp(-(y - 2 * b - nu * T) ** 2 / (2 * v2))) / sqrt(2 * pi * v2)
    lo, hi = log(K / S), nu * T + 12 * SIG * sqrt(T); h = (hi - lo) / n
    f = lambda y: (S * exp(y) - K) * dens(y)
    tot = f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return exp(-RD * T) * tot * h / 3

def lattice(n, per=40, top=20):                                # Road 4: the n-date contract exactly, by
    dx, dt = log(S / H) / per, T / n                           # backward steps on a grid of ln(spot / wall)
    s, mu, M = SIG * sqrt(dt), (RD - RF - 0.5 * SIG * SIG) * dt, per * top
    w = [(1 if i in (0, M) else 4 if i % 2 else 2) * dx / 3 for i in range(M + 1)]
    W = int(9 * s / dx) + 2
    ker = [phi((d * dx - mu) / s) / s for d in range(-W, W + 1)]
    V = [max(H * exp(i * dx) - K, 0.0) for i in range(M + 1)]
    disc, pad = exp(-RD * dt), [0.0] * W
    for _ in range(n):                                         # each date: only grid points above the wall count
        U = pad + [a * b for a, b in zip(w, V)] + pad
        V = [disc * sum(map(mul, ker, U[i:i + 2 * W + 1])) for i in range(M + 1)]
    return V[per]

def mc(npairs, n=252, seed=20260927):                          # Road 5: simulated daily paths, our own random numbers
    st, dt = seed, T / n
    mu, s, c = (RD - RF - 0.5 * SIG * SIG) * dt, SIG * sqrt(dt), 2 / (SIG * SIG * dt)
    disc, acc, knocked = exp(-RD * T), [0.0] * 6, 0
    def u():
        nonlocal st
        st = (6364136223846793005 * st + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        return ((st >> 11) + 0.5) / 9007199254740992.0
    for _ in range(npairs):
        zs = []
        while len(zs) < n:                                     # Box-Muller: two uniforms -> two bell-curve draws
            r, a = sqrt(-2 * log(u())), 2 * pi * u(); zs += [r * cos(a), r * sin(a)]
        est = []
        for sg in (s, -s):                                     # each path and its mirror-image twin
            y, surv, alive = log(S / H), 1.0, True
            for z in zs:
                yn = y + mu + sg * z
                if yn <= 0: alive, surv = False, 0.0; break
                surv *= 1 - exp(-c * y * yn); y = yn           # chance the path did not dip between closes
            pay = disc * max(H * exp(y) - K, 0.0) if alive else 0.0
            est.append((pay * surv, pay, pay - pay * surv)); knocked += not alive
        for j in range(3):
            a = 0.5 * (est[0][j] + est[1][j]); acc[j] += a; acc[j + 3] += a * a
    res = [(acc[j] / npairs, sqrt((acc[j + 3] / npairs - (acc[j] / npairs) ** 2) / npairs)) for j in range(3)]
    return res, knocked / (2 * npairs)

van, out, mirror, wgt = call(S, K), dao(S, K, H), call(H * H / S, K), (H / S) ** (2 * lam())
humps, inn = two_humps(), dai_rr(S, K, H)
a, nu = log(S / H), RD - RF - 0.5 * SIG * SIG
touch = N((-a - nu * T) / (SIG * sqrt(T))) + wgt * N((-a + nu * T) / (SIG * sqrt(T)))
lat = {n: lattice(n) for n in (12, 52, 252)}
bgk = {n: dao(S, K, H * exp(-BETA * SIG * sqrt(T / n))) for n in (12, 52, 252)}
bgk_up = dao(S, K, H * exp(BETA * SIG * sqrt(T / 252)))
sims, knocked = mc(100000)                                     # 100,000 paths and their twins
(mc_c, se_c), (mc_d, se_d), (gap, se_g) = sims
mc_daily = out + gap
greek = lambda f: ((f(S + 1e-4, SIG) - f(S - 1e-4, SIG)) / 2e-4,     # delta: bump spot by a pip each way
                   (f(S, SIG + 0.005) - f(S, SIG - 0.005)) / PIP)      # vega: pips per volatility point
g_v = greek(lambda s, sg: call(s, K, sg)); g_o = greek(lambda s, sg: dao(s, K, H, sg))
g_i = greek(lambda s, sg: dai_rr(s, K, H, sg))

rows = [("nu, drift of log EURUSD", [RD - RF - 0.5 * SIG * SIG]), ("lambda", [lam()]), ("weight (H/S)^(2 lambda)", [wgt]), ("mirror spot H^2/S", [H * H / S]),
    ("1 vanilla C(S)", [van]), ("  mirror call C(H^2/S)", [mirror]), ("  weighted mirror", [wgt * mirror]),
    ("1 down-and-out, formula", [out]), ("2 down-and-out, two humps", [humps]),
    ("3 down-and-in, other lambda", [inn]), ("  in + out", [inn + out]),
    ("  touch chance, continuous", [touch]), ("  BGK beta, rounded", [BETA]),
    ("4 lattice, 12 / 52 / 252 dates", [lat[12], lat[52], lat[252]]),
    ("  BGK wall, 12 / 52 / 252", [H * exp(-BETA * SIG * sqrt(T / n)) for n in (12, 52, 252)]),
    ("  BGK price, 12 / 52 / 252", [bgk[12], bgk[52], bgk[252]]),
    ("5 MC continuous, std error", [mc_c, se_c]), ("  MC daily raw, std error", [mc_d, se_d]),
    ("  paired gap, std error", [gap, se_g]), ("  MC daily = formula + gap", [mc_daily]),
    ("  knocked out at a close", [knocked]),
    ("pips: daily - continuous", [(lat[252] - out) / PIP]), ("pips: BGK - lattice, 252", [(bgk[252] - lat[252]) / PIP]),
    ("pips: BGK - MC daily", [(bgk[252] - mc_daily) / PIP]), ("pips: BGK - lattice, 12", [(bgk[12] - lat[12]) / PIP]),
    ("wrong: barrier ignored", [van]), ("wrong: weight dropped", [van - mirror]),
    ("wrong: lambda with +sigma^2/2", [van - (H / S) ** (2 * lam() + 2) * mirror]),
    ("wrong: mirror at H, not H^2/S", [van - wgt * call(H, K)]), ("wrong: EUR rate left out", [dao(S, K, H, rf=0.0)]),
    ("wrong: wall shifted up, 252", [bgk_up]),
    ("delta: vanilla / out / in", list(g_v[:1] + g_o[:1] + g_i[:1])),
    ("vega pips/pt: vanilla / out / in", [g_v[1], g_o[1], g_i[1]]),
    ("try: H = 1.08, out / in", [dao(S, K, 1.08), dai_rr(S, K, 1.08)]), ("try: H = 1.00, out", [dao(S, K, 1.00)]),
    ("try: sigma 0.15, vanilla / out", [call(S, K, 0.15), dao(S, K, H, 0.15)]),
    ("try: T = 3, vanilla / out", [call(S, K, t=3.0), dao(S, K, H, t=3.0)])]
for name, vals in rows:
    print(f"{name:<33}" + "".join(f"{v:>12.6f}" for v in vals))
print()
xs = [1.05 + 0.01 * i for i in range(16)]
print(f"{'chart, EURUSD':<24}" + "".join(f"{x:>8.2f}" for x in xs))
for name, f in (("chart, vanilla pips", lambda x: call(x, K) / PIP),
                ("chart, knock-out pips", lambda x: dao(x, K, H) / PIP), ("chart, knock-in pips", lambda x: dai_rr(x, K, H) / PIP),
                ("chart, payoff untouched", lambda x: max(x - K, 0.0) / PIP)):
    print(f"{name:<24}" + "".join(f"{f(x):>8.2f}" for x in xs))

assert abs(out - 0.041661) < 5e-7,                  "formula vs the shelf's house number"
assert abs(humps - out) < 1e-10,                    "reflected-density integral lands on the formula"
assert abs(inn + out - van) < 1e-12,                "in-out parity with a knock-in written in the other lambda"
assert abs(mc_c - out) < 3 * se_c,                  "bridge-weighted simulation finds the continuous price"
assert abs(mc_daily - lat[252]) < 3 * se_g,         "simulated daily price agrees with the lattice"
assert abs(bgk[252] - lat[252]) < PIP,              "BGK shift within a pip of the exact daily price"
assert lat[12] > lat[52] > lat[252] > out,          "fewer looks, fewer knock-outs, dearer option"
assert abs(bgk_up - lat[252]) > abs(out - lat[252]), "shifting the wall the wrong way is worse than no shift"
print("ALL CHECKS PASS")
