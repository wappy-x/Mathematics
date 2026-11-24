# Knock-in and knock-out forwards -- the check behind the card.  Standard library only.
# House FX market: EURUSD 1.10, USD 5%, EUR 3%, vol 10%, 1 year; knock-in 1.05, knock-out 1.20; USD per 1 EUR.
# Roads: (1) barrier blocks A-D + bisection; (2) Simpson integral of payoff times bridge survival + bisection;
# (3) Monte Carlo with its own random numbers. Identity checks, not a road: forward = call - put, KIKO = forward - UIC + DOP.
from math import log, exp, sqrt, cos, pi

def N(x):                                   # normal CDF, own series: 0.5 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total) or k < 5:
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + total * exp(-0.5 * x * x) / sqrt(2 * pi)

S0, rd, rf, T, VOL, LO, HI = 1.10, 0.05, 0.03, 1.0, 0.10, 1.05, 1.20
FWD = S0 * exp((rd - rf) * T)               # covered interest parity

def blocks(K, H, eta, phi, v):              # Rubinstein-Reiner blocks, as on the eight-barrier card
    s = v * sqrt(T); mu = (rd - rf - 0.5 * v * v) / (v * v)
    x1 = log(S0 / K) / s + (1 + mu) * s; x2 = log(S0 / H) / s + (1 + mu) * s
    y1 = log(H * H / (S0 * K)) / s + (1 + mu) * s; y2 = log(H / S0) / s + (1 + mu) * s
    fS, fK, hp, hm = S0 * exp(-rf * T), K * exp(-rd * T), (H / S0) ** (2 * mu + 2), (H / S0) ** (2 * mu)
    A = phi * (fS * N(phi * x1) - fK * N(phi * (x1 - s))); B = phi * (fS * N(phi * x2) - fK * N(phi * (x2 - s)))
    C = phi * (fS * hp * N(eta * y1) - fK * hm * N(eta * (y1 - s)))
    D = phi * (fS * hp * N(eta * y2) - fK * hm * N(eta * (y2 - s)))
    return A, B, C, D

def legs(K, v=VOL, lo=LO, hi=HI):           # call, put, down-and-in put, up-and-out call, up-and-in call, down-and-out put
    A, B, C, D = blocks(K, hi, -1, 1, v); a, b, c, d = blocks(K, lo, 1, -1, v)
    uoc, uic = (A - B + C - D, B - C + D) if K < hi else (0.0, A)
    dip, dop = (b - c + d, a - b + c - d) if K > lo else (a, 0.0)
    return A, a, dip, uoc, uic, dop

STRUCT = {"plain forward": lambda L, p: L[0] - L[1], "participating 50%": lambda L, p: L[0] - p * L[1],
          "knock-in forward": lambda L, p: L[0] - L[2], "KIKO": lambda L, p: L[3] - L[2]}
def value(name, K, v=VOL, lo=LO, hi=HI, p=0.5): return STRUCT[name](legs(K, v, lo, hi), p)

def bisect(f, a, b, trace=None):            # f falls in K: keep the half where the sign changes
    for i in range(80):
        m = 0.5 * (a + b); fm = f(m)
        if trace is not None and i < 7: trace.append((i + 1, a, b, m, fm))
        a, b = (m, b) if fm > 0 else (a, m)
    return 0.5 * (a + b)

def simpson(f, a, b, n=400):
    h = (b - a) / n; tot = f(a) + f(b)
    for i in range(1, n): tot += (4 if i % 2 else 2) * f(a + i * h)
    return tot * h / 3

def by_integral(name, K, p=0.5):            # road 2: no blocks, no N; survival of a bridge pinned at both ends
    m, s, k, aL, aH = (rd - rf - 0.5 * VOL * VOL) * T, VOL * sqrt(T), log(K / S0), log(LO / S0), log(HI / S0)
    dens = lambda x: exp(-(x - m) ** 2 / (2 * s * s)) / (s * sqrt(2 * pi))
    survL = lambda x: 1 - exp(-2 * aL * (aL - x) / (s * s)) if x > aL else 0.0
    survH = lambda x: 1 - exp(-2 * aH * (aH - x) / (s * s)) if x < aH else 0.0
    call = lambda x: (S0 * exp(x) - K) * dens(x); put = lambda x: (K - S0 * exp(x)) * dens(x)
    def over(f, a, b):                      # integrate between kinks so Simpson sees smooth pieces only
        cuts = sorted({a, b} | {c for c in (k, aL, aH) if a < c < b})
        return sum(simpson(f, cuts[i], cuts[i + 1]) for i in range(len(cuts) - 1))
    lo_x, hi_x = m - 10 * s, m + 10 * s
    C = over(call, k, hi_x); P = over(put, lo_x, k)
    UOC = over(lambda x: call(x) * survH(x), k, aH) if k < aH else 0.0
    DIP = over(lambda x: put(x) * (1 - survL(x)), lo_x, k)
    L = [x * exp(-rd * T) for x in (C, P, DIP, UOC)]
    return STRUCT[name](L, p)

state = [20261123]
def unif():                                 # splitmix64, then 53 bits into (0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

def monte_carlo(K1, K2, paths=100000, steps=12):   # road 3: both structures, bridge test for each wall each month
    dt = T / steps; drift, sd = (rd - rf - 0.5 * VOL * VOL) * dt, VOL * sqrt(dt)
    aL, aH, disc = log(LO / S0), log(HI / S0), exp(-rd * T)
    sm, sq = [0.0] * 4, [0.0] * 4
    for _ in range(paths):
        x, hL, hH = 0.0, False, False
        for i in range(steps):
            z = sqrt(-2 * log(unif())) * cos(2 * pi * unif()); u3, u4 = unif(), unif()
            y = x + drift + sd * z
            hL = hL or y <= aL or u3 < exp(-2 * (x - aL) * (y - aL) / (sd * sd))
            hH = hH or y >= aH or u4 < exp(-2 * (aH - x) * (aH - y) / (sd * sd))
            x = y
        ST = S0 * exp(x)
        v = [disc * (max(ST - K1, 0) - hL * max(K1 - ST, 0)), disc * ((not hH) * max(ST - K2, 0) - hL * max(K2 - ST, 0)),
             float(hL), float(hH)]
        for j in range(4): sm[j] += v[j]; sq[j] += v[j] * v[j]
    mean = [t / paths for t in sm]
    return mean, [sqrt(max(sq[j] / paths - mean[j] ** 2, 0.0) / paths) for j in range(4)]

print("house: EURUSD 1.10, USD 5%, EUR 3%, vol 10%, 1 year, knock-in 1.05, knock-out 1.20")
K, trace = {}, []
for name in STRUCT:
    K[name] = bisect(lambda k: value(name, k), 1.00, 1.20, trace if name == "KIKO" else None)
    Ki = bisect(lambda k: by_integral(name, k), 1.00, 1.20)
    print(f"zero-cost strike  {name:<18} blocks {K[name]:.6f}  integral {Ki:.6f}")
    assert abs(Ki - K[name]) < 1e-8, name
print(f"forward by parity {FWD:.6f}, so the plain-forward strike is the parity forward")
assert abs(K["plain forward"] - FWD) < 1e-10
for name in ("knock-in forward", "KIKO"):
    L = legs(K[name])
    print(f"legs at {name} strike {K[name]:.6f}: call {L[0]:.6f} put {L[1]:.6f} DIP {L[2]:.6f} UOC {L[3]:.6f}")
Lf = legs(FWD); dfd = exp(-rd * T)
print(f"at K = forward: call {Lf[0]:.6f} = put {Lf[1]:.6f}; DIP {Lf[2]:.6f}; DOP = put - DIP {Lf[5]:.6f}")
print(f"first-order strike shift DOP/e^(-rd T) = {Lf[5]:.6f}/{dfd:.6f} = {Lf[5] / dfd:.6f}; guess {FWD + Lf[5] / dfd:.6f}"
      f"\nactual shift {K['knock-in forward'] - FWD:.6f}")
print("KIKO bisection: step, low, high, mid, value at mid")
for st in trace: print("  %d  %.6f  %.6f  %.6f  %+.6f" % st)
print("value to the importer (US cents per euro) against strike\n  strike  forward  knock-in fwd  KIKO")
for k in (1.04, 1.06, 1.08, 1.10, 1.12, 1.14, 1.16):
    print(f"  {k:.2f}  {100 * value('plain forward', k):7.3f}  {100 * value('knock-in forward', k):7.3f}  "
          f"{100 * value('KIKO', k):7.3f}")
Kk, Kf = K["KIKO"], K["knock-in forward"]; L = legs(Kk); fv = S0 * exp(-rf * T) - Kk * dfd
print(f"KIKO strike {FWD - Kk:.6f} below forward: forward value {fv:.6f} = UIC {L[4]:.6f} - DOP {L[5]:.6f} = {L[4] - L[5]:.6f}")
assert abs(fv - (L[4] - L[5])) < 1e-12 and abs(L[0] - L[1] - fv) < 1e-12
print("rate paid per euro: path / forward / knock-in fwd / KIKO")
for desc, ST, hL, hH in (("ends 1.15, no touch", 1.15, 0, 0), ("ends 1.08, no touch", 1.08, 0, 0),
                         ("touches 1.05, ends 1.08", 1.08, 1, 0), ("touches 1.20, ends 1.25", 1.25, 0, 1),
                         ("touches 1.05, ends 1.02", 1.02, 1, 0)):
    kif = Kf if ST > Kf or hL else ST
    kiko = Kk if (ST > Kk and not hH) or (ST < Kk and hL) else ST
    print(f"  {desc:<24} {FWD:.6f}  {kif:.6f}  {kiko:.6f}")
(mc, se) = monte_carlo(Kf, Kk)
for j, (lab, Kx) in enumerate((("knock-in forward", Kf), ("KIKO", Kk))):
    print(f"Monte Carlo value of {lab} at {Kx:.6f}: {mc[j]:+.6f}  (se {se[j]:.6f})")
    assert abs(mc[j]) < 4 * se[j], lab
for j, (H, eta) in enumerate(((LO, 1), (HI, -1))):   # chance of a touch from the no-touch dollar
    s = VOL * sqrt(T); mu = (rd - rf - 0.5 * VOL ** 2) / VOL ** 2
    x2 = log(S0 / H) / s + (1 + mu) * s; y2 = log(H / S0) / s + (1 + mu) * s
    p = 1 - (N(eta * (x2 - s)) - (H / S0) ** (2 * mu) * N(eta * (y2 - s)))
    print(f"chance of touching {H:.2f} in the year: formula {p:.6f}  Monte Carlo {mc[2 + j]:.6f}")
    assert abs(mc[2 + j] - p) < 4 * se[2 + j]
tries = (("KIKO, knock-out 1.25", lambda k: value("KIKO", k, hi=1.25)),
         ("knock-in forward, knock-in 1.00", lambda k: value("knock-in forward", k, lo=1.00)),
         ("knock-in forward, vol 12%", lambda k: value("knock-in forward", k, v=0.12)),
         ("participating 75%", lambda k: value("participating 50%", k, p=0.75)),
         ("KIKO without the knock-in", lambda k: legs(k)[3] - legs(k)[1]))
for lab, f in tries: print(f"try: {lab:<33} strike {bisect(f, 1.00, 1.20):.6f}")
print("ALL CHECKS PASS")
