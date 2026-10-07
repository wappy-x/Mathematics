# The eight single barriers -- the check behind the card.  Standard library only.  House FX market:
# EURUSD 1.10, strike 1.10, USD 5%, EUR 3%, vol 10%, 1 year, walls 1.05 and 1.20; USD per 1 EUR.
# Roads: (1) blocks A-F; (2) in + out = vanilla; (3) Simpson integral of payoff times bridge survival;
# (4) Monte Carlo with its own random numbers; (5) rebate at hit from the first-hitting-time density.
from math import log, exp, sqrt, cos, pi

def N(x):                                   # normal CDF, own series: 0.5 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total) or k < 5:
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + total * exp(-0.5 * x * x) / sqrt(2 * pi)

S0, K, rd, rf, VOL, T, LO, HI, R = 1.10, 1.10, 0.05, 0.03, 0.10, 1.0, 1.05, 1.20, 0.005
# name, barrier, eta, phi, coefficients on A B C D, blocks in words, [strike if not K]
TYPES = [("DOC", LO, 1, 1, (1, 0, -1, 0), "A-C"), ("DIC", LO, 1, 1, (0, 0, 1, 0), "C"),
         ("DOP", LO, 1, -1, (1, -1, 1, -1), "A-B+C-D"), ("DIP", LO, 1, -1, (0, 1, -1, 1), "B-C+D"),
         ("UOC", HI, -1, 1, (1, -1, 1, -1), "A-B+C-D"), ("UIC", HI, -1, 1, (0, 1, -1, 1), "B-C+D"),
         ("UOP", HI, -1, -1, (1, 0, -1, 0), "A-C"), ("UIP", HI, -1, -1, (0, 0, 1, 0), "C")]
OTHER = [("DOC", LO, 1, 1, (0, 1, 0, -1), "B-D", 1.0), ("DIC", LO, 1, 1, (1, -1, 0, 1), "A-B+D", 1.0),   # strike under
         ("DOP", LO, 1, -1, (0, 0, 0, 0), "0", 1.0), ("DIP", LO, 1, -1, (1, 0, 0, 0), "A", 1.0),          # the low wall,
         ("UOC", HI, -1, 1, (0, 0, 0, 0), "0", 1.25), ("UIC", HI, -1, 1, (1, 0, 0, 0), "A", 1.25),        # strike over
         ("UOP", HI, -1, -1, (0, 1, 0, -1), "B-D", 1.25), ("UIP", HI, -1, -1, (1, -1, 0, 1), "A-B+D", 1.25)]  # the high
def blocks(S, v, H, eta, phi, b=rd - rf, K=K):
    s = v * sqrt(T); mu = (b - 0.5 * v * v) / (v * v); lam = sqrt(mu * mu + 2 * rd / (v * v))
    x1 = log(S / K) / s + (1 + mu) * s; x2 = log(S / H) / s + (1 + mu) * s
    y1 = log(H * H / (S * K)) / s + (1 + mu) * s; y2 = log(H / S) / s + (1 + mu) * s
    z = log(H / S) / s + lam * s
    fS, fK, hp, hm = S * exp(-rf * T), K * exp(-rd * T), (H / S) ** (2 * mu + 2), (H / S) ** (2 * mu)
    A = phi * fS * N(phi * x1) - phi * fK * N(phi * x1 - phi * s)
    B = phi * fS * N(phi * x2) - phi * fK * N(phi * x2 - phi * s)
    C = phi * fS * hp * N(eta * y1) - phi * fK * hm * N(eta * y1 - eta * s)
    D = phi * fS * hp * N(eta * y2) - phi * fK * hm * N(eta * y2 - eta * s)
    E = exp(-rd * T) * (N(eta * x2 - eta * s) - hm * N(eta * y2 - eta * s))     # 1 USD at expiry if never hit
    F = (H / S) ** (mu + lam) * N(eta * z) + (H / S) ** (mu - lam) * N(eta * z - 2 * eta * lam * s)  # 1 USD at hit
    return A, B, C, D, E, F, (mu, lam, x1, x2, y1, y2, z, hp, hm)

def price(t, S=S0, v=VOL, b=rd - rf):
    bl = blocks(S, v, t[1], t[2], t[3], b, *t[6:])
    return sum(c * x for c, x in zip(t[4], bl[:4]))

def simpson(f, a, b, n):
    h = (b - a) / n; tot = f(a) + f(b)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return tot * h / 3

def by_integral(t):                         # road 3: survival chance of a bridge pinned at both ends
    H, eta, phi, out, k = t[1], t[2], t[3], t[0][1] == "O", (t[6:] or [K])[0]
    a, m, s = log(H / S0), (rd - rf - 0.5 * VOL * VOL) * T, VOL * sqrt(T)
    def f(z):
        x = m + s * z
        pay = max(phi * (S0 * exp(x) - k), 0.0)
        live = x > a if eta == 1 else x < a
        surv = 1 - exp(-2 * a * (a - x) / (s * s)) if live else 0.0
        return pay * (surv if out else 1 - surv) * exp(-0.5 * z * z) / sqrt(2 * pi)
    return exp(-rd * T) * simpson(f, -9.0, 9.0, 20000)

def hit_integral(H):                        # road 5: first-hitting-time density, discounted
    a, nu = log(H / S0), rd - rf - 0.5 * VOL * VOL
    f = lambda t: 0.0 if t == 0 else exp(-rd * t) * abs(a) / (VOL * sqrt(2 * pi * t ** 3)) * exp(-(a - nu * t) ** 2 / (2 * VOL * VOL * t))
    return simpson(f, 0.0, T, 20000)

state = [20260927]
def unif():                                 # splitmix64, then 53 bits into (0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

def monte_carlo(paths=200000, steps=20):     # road 4: 12 payoffs per path, bridge test each step
    dt = T / steps; drift, sd = (rd - rf - 0.5 * VOL * VOL) * dt, VOL * sqrt(dt)
    aL, aH, disc = log(LO / S0), log(HI / S0), exp(-rd * T)
    sm, sq = [0.0] * 12, [0.0] * 12
    for _ in range(paths):
        x, tL, tH = 0.0, -1.0, -1.0
        for i in range(steps):
            z = sqrt(-2 * log(unif())) * cos(2 * pi * unif()); u3, u4 = unif(), unif()
            y = x + drift + sd * z
            if tL < 0 and (y <= aL or u3 < exp(-2 * (x - aL) * (y - aL) / (sd * sd))): tL = (i + 0.5) * dt
            if tH < 0 and (y >= aH or u4 < exp(-2 * (aH - x) * (aH - y) / (sd * sd))): tH = (i + 0.5) * dt
            x = y
        c, p = max(S0 * exp(x) - K, 0.0) * disc, max(K - S0 * exp(x), 0.0) * disc
        hL, hH = tL >= 0, tH >= 0
        v = [c * (not hL), c * hL, p * (not hL), p * hL, c * (not hH), c * hH, p * (not hH), p * hH,
             exp(-rd * tL) if hL else 0.0, exp(-rd * tH) if hH else 0.0, disc * (not hL), disc * (not hH)]
        for k in range(12):
            sm[k] += v[k]; sq[k] += v[k] * v[k]
    mean = [s / paths for s in sm]
    return mean, [sqrt(max(sq[k] / paths - mean[k] ** 2, 0.0) / paths) for k in range(12)]

def gk(phi, S=S0, K=K):                     # Garman-Kohlhagen vanilla, written the usual way
    d1 = (log(S / K) + (rd - rf + 0.5 * VOL * VOL) * T) / (VOL * sqrt(T)); d2 = d1 - VOL * sqrt(T)
    return phi * (S * exp(-rf * T) * N(phi * d1) - K * exp(-rd * T) * N(phi * d2))

van, (mc, se) = {1: gk(1), -1: gk(-1)}, monte_carlo()
print(f"vanilla EUR call {van[1]:.6f}   vanilla EUR put {van[-1]:.6f}")
for H, eta in ((LO, 1), (HI, -1)):
    print(f"blocks, call, H={H:.2f}   " + "  ".join(f"{x:.6f}" for x in blocks(S0, VOL, H, eta, 1)[:6]))
    print(f"pieces, H={H:.2f} mu lam x1 x2 y1 y2 z hp hm " + " ".join(f"{x:.6f}" for x in blocks(S0, VOL, H, eta, 1)[6]))
print("type blocks      formula  integral  monte-carlo   se      delta    vega/pt")
P = {}
for k, t in enumerate(TYPES):
    P[t[0]] = price(t); I = by_integral(t)
    dl = (price(t, S0 + 1e-4) - price(t, S0 - 1e-4)) / 2e-4
    vg = (price(t, v=VOL + 1e-4) - price(t, v=VOL - 1e-4)) / 2e-4 * 0.01
    print(f"{t[0]}  {t[5]:<9} {P[t[0]]:9.6f} {I:9.6f} {mc[k]:9.6f} {se[k]:9.6f} {dl:8.4f} {vg:9.6f}")
    assert abs(I - P[t[0]]) < 1e-7, t[0]
    assert abs(mc[k] - P[t[0]]) < 4 * se[k], t[0]
for o, i, ph in (("DOC", "DIC", 1), ("DOP", "DIP", -1), ("UOC", "UIC", 1), ("UOP", "UIP", -1)):
    print(f"parity {o}+{i} {P[o] + P[i]:.9f}  vanilla {van[ph]:.9f}")
    assert abs(P[o] + P[i] - van[ph]) < 1e-12
for k, t in enumerate(OTHER):               # the barrier on the other side of the strike
    P[k], I = price(t), by_integral(t)
    print(f"other side, {t[0]} K={t[6]:.2f} {t[5]:<6} formula {P[k]:.6f}  integral {I:.6f}")
    assert abs(I - P[k]) < 1e-7 and (k % 2 == 0 or abs(P[k] + P[k - 1] - gk(t[3], S0, t[6])) < 1e-12)
for j, (H, eta) in enumerate(((LO, 1), (HI, -1))):
    (E, F), Fi = blocks(S0, VOL, H, eta, 1)[4:6], hit_integral(H)
    print(f"1 USD at hit, H={H:.2f}: F {F:.6f}  density {Fi:.6f}  mc {mc[8 + j]:.6f}")
    print(f"1 USD at expiry if untouched, H={H:.2f}: E {E:.6f}  mc {mc[10 + j]:.6f}")
    assert abs(Fi - F) < 1e-7 and abs(mc[8 + j] - F) < 4 * se[8 + j] and abs(mc[10 + j] - E) < 4 * se[10 + j]
EU, FU, ED = blocks(S0, VOL, HI, -1, 1)[4], blocks(S0, VOL, HI, -1, 1)[5], blocks(S0, VOL, LO, 1, 1)[4]
print(f"one-touch 1.20, 1 USD at expiry = e^-rT - E {exp(-rd * T) - EU:.6f}")
print(f"UOC share of vanilla {P['UOC'] / van[1]:.4f}   UIC share {P['UIC'] / van[1]:.4f}")
print(f"UOC + 0.005 rebate at hit {P['UOC'] + R * FU:.6f}   at expiry {P['UOC'] + R * (exp(-rd * T) - EU):.6f}")
print(f"DIC + 0.005 rebate at expiry if never in {P['DIC'] + R * ED:.6f}")
print(f"wrong: UOC by the regular pair A-C {blocks(S0, VOL, HI, -1, 1)[0] - blocks(S0, VOL, HI, -1, 1)[2]:.6f}")
print(f"wrong: DOC with the EUR rate left out of mu {price(TYPES[0], b=rd):.6f}")
print(f"wrong: UIC+rebate as vanilla - (UOC+rebate at hit) {van[1] - P['UOC'] - R * FU:.6f}  right {P['UIC'] + R * EU:.6f}")
xs = [1.00 + 0.02 * i for i in range(11)]
print("chart, spot today    " + " ".join(f"{x:6.2f}" for x in xs))
print("chart, vanilla cents " + " ".join(f"{100 * gk(1, x):6.2f}" for x in xs))
for t in TYPES[4:6]:
    print(f"chart, {t[0]}     cents " + " ".join(f"{100 * (price(t, x) if abs(price(t, x)) > 1e-12 else 0.0):6.2f}" for x in xs))
xs = [1.00 + 0.025 * i for i in range(13)]
print("payoff, EURUSD at expiry " + " ".join(f"{x:5.3f}" for x in xs))
print("payoff, vanilla   cents  " + " ".join(f"{100 * max(x - K, 0):5.2f}" for x in xs))
print("payoff, UOC       cents  " + " ".join(f"{100 * max(x - K, 0) * (x < HI - 1e-9):5.2f}" for x in xs))
print("ALL CHECKS PASS")
