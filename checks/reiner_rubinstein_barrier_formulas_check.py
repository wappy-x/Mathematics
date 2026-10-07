# The eight barrier formulas -- the check behind the card.  Standard library only.
# Road 1: the Reiner-Rubinstein blocks A..F.  Road 2: Simpson's rule over the
# reflected density of the log price.  Road 3: a Monte Carlo of monthly steps
# with the Brownian-bridge chance of a touch between steps.  Road 4: parity.
from math import log, sqrt, exp, cos, pi
S, r, q, sig, T, R = 100.0, 0.05, 0.02, 0.20, 1.0, 3.0
CALL, PUT = 9.227005508154, 6.330080627550           # house prices, from the Black-Scholes card
def dens(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3.0 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def N(x):                                            # bell-curve area left of x, by slices
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    return 0.5 + simpson(dens, 0.0, x, 2000)
def blocks(K, H, phi, eta):                          # the six Reiner-Rubinstein terms
    v = sig * sqrt(T); mu = (r - q - 0.5 * sig * sig) / (sig * sig); lam = sqrt(mu * mu + 2 * r / (sig * sig))
    x1 = log(S / K) / v + (1 + mu) * v; x2 = log(S / H) / v + (1 + mu) * v
    y1 = log(H * H / (S * K)) / v + (1 + mu) * v; y2 = log(H / S) / v + (1 + mu) * v; z = log(H / S) / v + lam * v
    Sq, Kr, h = S * exp(-q * T), K * exp(-r * T), H / S
    A = phi * Sq * N(phi * x1) - phi * Kr * N(phi * (x1 - v))
    B = phi * Sq * N(phi * x2) - phi * Kr * N(phi * (x2 - v))
    C = phi * Sq * h ** (2 * mu + 2) * N(eta * y1) - phi * Kr * h ** (2 * mu) * N(eta * (y1 - v))
    D = phi * Sq * h ** (2 * mu + 2) * N(eta * y2) - phi * Kr * h ** (2 * mu) * N(eta * (y2 - v))
    E = R * exp(-r * T) * (N(eta * (x2 - v)) - h ** (2 * mu) * N(eta * (y2 - v)))
    F = R * (h ** (mu + lam) * N(eta * z) + h ** (mu - lam) * N(eta * (z - 2 * lam * v)))
    return A, B, C, D, E, F
# which blocks each contract adds, as coefficients on (A, B, C, D); key (in?, eta, phi, strike above barrier?)
MIX = {(1, 1, 1, 1): (0, 0, 1, 0), (1, 1, 1, 0): (1, -1, 0, 1), (1, -1, 1, 1): (1, 0, 0, 0), (1, -1, 1, 0): (0, 1, -1, 1),
       (1, 1, -1, 1): (0, 1, -1, 1), (1, 1, -1, 0): (1, 0, 0, 0), (1, -1, -1, 1): (1, -1, 0, 1), (1, -1, -1, 0): (0, 0, 1, 0),
       (0, 1, 1, 1): (1, 0, -1, 0), (0, 1, 1, 0): (0, 1, 0, -1), (0, -1, 1, 1): (0, 0, 0, 0), (0, -1, 1, 0): (1, -1, 1, -1),
       (0, 1, -1, 1): (1, -1, 1, -1), (0, 1, -1, 0): (0, 0, 0, 0), (0, -1, -1, 1): (0, 1, 0, -1), (0, -1, -1, 0): (1, 0, -1, 0)}
def rr(K, H, phi, eta, inn, rebate=False):
    b = blocks(K, H, phi, eta)
    val = sum(c * x for c, x in zip(MIX[(inn, eta, phi, int(K > H))], b[:4]))
    return val + ((b[4] if inn else b[5]) if rebate else 0.0)
def integral(K, H, phi, eta, inn, pay=None):         # road 2: reflected density, no blocks used
    nu, sd, bl = r - q - 0.5 * sig * sig, sig * sqrt(T), log(H / S)
    w = exp(2 * nu * bl / (sig * sig))
    f = lambda u: dens((u - nu * T) / sd) / sd
    def g(u):
        live = (u > bl) if eta == 1 else (u < bl)
        surv = f(u) - w * f(u - 2 * bl) if live else 0.0
        p = pay(u) if pay else max(phi * (S * exp(u) - K), 0.0)
        return p * ((f(u) - surv) if inn else surv)
    cuts = sorted({-3.0, bl, log(K / S), 3.0})
    return exp(-r * T) * sum(simpson(g, a, b, 4000) for a, b in zip(cuts, cuts[1:]))
def touch_pv(H):                                     # E[e^{-r tau}; tau <= T] from the first-passage density
    nu, bl = r - q - 0.5 * sig * sig, abs(log(H / S))
    sgn = 1.0 if H < S else -1.0
    g = lambda t: 0.0 if t == 0 else exp(-r * t) * bl / (sig * sqrt(2 * pi * t ** 3)) * exp(-(bl + sgn * nu * t) ** 2 / (2 * sig * sig * t))
    return simpson(g, 0.0, T, 4000)
CASES = [("DOC", 80, 1, 1, 0), ("DIC", 80, 1, 1, 1), ("DOP", 80, -1, 1, 0), ("DIP", 80, -1, 1, 1),
         ("UOC", 120, 1, -1, 0), ("UIC", 120, 1, -1, 1), ("UOP", 120, -1, -1, 0), ("UIP", 120, -1, -1, 1)]
STRIKES = (100.0, 60.0, 140.0)                       # 60 sits below the 80 barrier, 140 above the 120 one
# ---- road 3: Monte Carlo, 12 monthly steps, bridge chance of a touch between steps ----
state = 20260924
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2 ** 53
PATHS, STEPS = 200000, 12
dt = T / STEPS; drift = (r - q - 0.5 * sig * sig) * dt; vol = sig * sqrt(dt)
bd, bu = log(0.8), log(1.2)
acc = {}; monthly = 0.0
for _ in range(PATHS):
    x = 0.0; sd_ = su = 1.0; alive_m = True
    for _ in range(STEPS):
        z = sqrt(-2 * log(uniform())) * cos(2 * pi * uniform())
        y = x + drift + vol * z
        sd_ *= 0.0 if y <= bd else 1 - exp(-2 * (x - bd) * (y - bd) / (vol * vol))
        su *= 0.0 if y >= bu else 1 - exp(-2 * (bu - x) * (bu - y) / (vol * vol))
        alive_m = alive_m and y > bd
        x = y
    ST = S * exp(x)
    for name, H, phi, eta, inn in CASES:
        for K in STRIKES:
            keep = sd_ if eta == 1 else su
            p = max(phi * (ST - K), 0.0) * ((1 - keep) if inn else keep)
            s = acc.setdefault((name, K), [0.0, 0.0]); s[0] += p; s[1] += p * p
    monthly += max(ST - 100.0, 0.0) * alive_m
def mc(name, K):
    s1, s2 = acc[(name, K)]; m = s1 / PATHS
    return exp(-r * T) * m, exp(-r * T) * sqrt(max(s2 / PATHS - m * m, 0.0) / PATHS)
print("house: S 100, r 5%, q 2%, sigma 20%, T 1; barriers 80 and 120; rebate 3")
print("blocks at K 100      A          B          C          D")
for lab, H, phi, eta in (("down call", 80, 1, 1), ("down put", 80, -1, 1), ("up call", 120, 1, -1), ("up put", 120, -1, -1)):
    print(f"{lab:<11}" + "".join(f"{v:11.6f}" for v in blocks(100.0, H, phi, eta)[:4]))
print("contract   K   formula    integral   simulated   +/- se")
prices, worst_int, worst_z = {}, 0.0, 0.0
for K in STRIKES:
    for name, H, phi, eta, inn in CASES:
        if K != 100.0 and (K == 60.0) != (eta == 1): continue
        f, i = rr(K, H, phi, eta, inn), integral(K, H, phi, eta, inn); m, se = mc(name, K)
        prices[(name, K)] = f; worst_int = max(worst_int, abs(f - i)); worst_z = max(worst_z, abs(f - m) / max(se, 1e-12))
        print(f"{name} {K:5.0f} {f:10.6f} {i:10.6f} {m:10.4f} {se:8.4f}")
van = {K: (integral(K, 1e-9, 1, 1, 0), integral(K, 1e-9, -1, 1, 0)) for K in (60.0, 140.0)}   # barrier far out of reach
PAIRS = [(100.0, "DOC", "DIC", CALL), (100.0, "DOP", "DIP", PUT), (100.0, "UOC", "UIC", CALL), (100.0, "UOP", "UIP", PUT),
         (60.0, "DOC", "DIC", van[60.0][0]), (60.0, "DOP", "DIP", van[60.0][1]), (140.0, "UOC", "UIC", van[140.0][0]), (140.0, "UOP", "UIP", van[140.0][1])]
for K, o, i, target in PAIRS:
    tot = prices[(o, K)] + prices[(i, K)]
    print(f"parity {o}+{i} K{K:4.0f}: {tot:10.6f}  plain option {target:10.6f}")
    assert abs(tot - target) < 1e-7, "in plus out must rebuild the plain option"
Qd, Qu = integral(100, 80, 0, 1, 0, lambda u: 1.0) * exp(r * T), integral(100, 120, 0, -1, 0, lambda u: 1.0) * exp(r * T)
for lab, H, eta, Q in (("80 ", 80, 1, Qd), ("120", 120, -1, Qu)):
    b = blocks(100.0, H, 1, eta)
    print(f"barrier {lab}: chance of touching {1 - Q:.6f}; F {b[5]:.6f} vs {R * touch_pv(H):.6f}; E {b[4]:.6f} vs {R * exp(-r * T) * Q:.6f}")
    assert abs(b[5] - R * touch_pv(H)) < 1e-7 and abs(b[4] - R * exp(-r * T) * Q) < 1e-7
print(f"DOC 80 with rebate 3 paid at the touch: {rr(100.0, 80, 1, 1, 0, True):.6f}; UOC 120: {rr(100.0, 120, 1, -1, 0, True):.6f}")
print(f"DIC 80 with rebate 3 paid at expiry if never touched: {rr(100.0, 80, 1, 1, 1, True):.6f}")
b80 = blocks(100.0, 80, 1, 1); b120w = blocks(100.0, 120, 1, 1)
print(f"wrong: DOC 80 by the strike-below-barrier branch B - D {b80[1] - b80[3]:.6f}")
print(f"wrong: UOC 120 with eta left at +1 {b120w[0] - b120w[1] + b120w[2] - b120w[3]:.6f}")
v, mu = sig * sqrt(T), (r - q - 0.5 * sig * sig) / (sig * sig); y1 = log(0.64) / v + (1 + mu) * v
wrongC = S * exp(-q * T) * 0.8 ** (2 * mu) * N(y1) - 100 * exp(-r * T) * 0.8 ** (2 * mu) * N(y1 - v)
lam, sh, ch = sqrt(mu * mu + 2 * r / (sig * sig)), S * exp(-q * T) * 0.8 ** (2 * mu + 2) * N(y1), 100 * exp(-r * T) * 0.8 ** (2 * mu) * N(y1 - v)
print(f"worked DOC 80: mu {mu:.6f} lambda {lam:.6f} y1 {y1:.6f} N(y1) {N(y1):.6f} N(y1-v) {N(y1 - v):.6f}")
print(f"worked DOC 80: (H/S)^(2mu+2) {0.8 ** (2 * mu + 2):.6f} (H/S)^2mu {0.8 ** (2 * mu):.6f} share {sh:.6f} cash {ch:.6f} C {sh - ch:.6f}")
bu_ = blocks(100.0, 120, 1, -1)
print(f"worked UOC 120: A-B {bu_[0] - bu_[1]:.6f} C-D {bu_[2] - bu_[3]:.6f} UOC {prices[('UOC', 100.0)]:.6f}")
print(f"wrong: DOC 80 with one image weight (H/S)^2mu on both halves of C {b80[0] - wrongC:.6f}")
print(f"wrong: DOC 80 rebate paid at expiry, not at the touch {prices[('DOC', 100.0)] + R * exp(-r * T) * (1 - Qd):.6f}")
m_mc = exp(-r * T) * monthly / PATHS
print(f"wrong: DOC 80 checked only at 12 month-ends, no bridge (simulated) {m_mc:.4f}")
hs = list(range(50, 100, 5))
print("chart, barrier   " + " ".join(f"{h:6d}" for h in hs))
print("chart, DOC       " + " ".join(f"{rr(100.0, h, 1, 1, 0):6.2f}" for h in hs))
print("chart, DIC       " + " ".join(f"{rr(100.0, h, 1, 1, 1):6.2f}" for h in hs))
print("chart, eight     " + " ".join(f"{prices[(c[0], 100.0)]:6.2f}" for c in CASES))
print(f"try: UOC barrier 150 {rr(100.0, 150, 1, -1, 0):.6f}; DOC barrier 99 {rr(100.0, 99, 1, 1, 0):.6f}; UIP barrier 105 {rr(100.0, 105, -1, -1, 1):.6f}")
assert abs(prices[("DOC", 100.0)] - 9.133306) < 1e-6 and abs(prices[("DIC", 100.0)] - 0.093699) < 1e-6
assert worst_int < 1e-7, "formula and reflected-density integral must agree"
assert worst_z < 4.0, "simulation within four standard errors of every formula price"
assert m_mc > prices[("DOC", 100.0)], "month-end checks miss touches, so the price comes out high"
print(f"worst formula-integral gap {worst_int:.1e}; worst simulation gap {worst_z:.2f} standard errors")
print("ALL CHECKS PASS")
