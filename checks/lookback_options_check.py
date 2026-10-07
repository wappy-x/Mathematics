# Floating-strike lookback call -- the check behind the card.  Standard library only.
# Four roads: the closed form, the minimum's law integrated level by level, a simulation that
# draws the exact continuous minimum, and a daily-watched simulation on paired paths.
from math import exp, log, sqrt, pi, cos

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def N(x):                                                        # bell-curve area left of x (Marsaglia's series)
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    s, t = x, x
    for k in range(1, 200):
        t *= x * x / (2 * k + 1); s += t
    return 0.5 + phi(x) * s

def vanilla(S, K, r, q, sig, T):
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))

def lookback_call(S, m, r, q, sig, T, keep_ebT=True):           # Road 1: Goldman-Sosin-Gatto, dividend yield q
    m = min(m, S); b = r - q; t = sig * sqrt(T)
    a1 = (log(S / m) + (b + 0.5 * sig * sig) * T) / t; a2 = a1 - t; a3 = a1 - 2.0 * b * T / t
    van = S * exp(-q * T) * N(a1) - m * exp(-r * T) * N(a2)
    if b == 0.0: return van + S * exp(-r * T) * t * (phi(a1) - a1 * N(-a1))
    ebT = exp(b * T) if keep_ebT else 1.0
    return van + S * exp(-r * T) * sig * sig / (2 * b) * ((S / m) ** (-2 * b / (sig * sig)) * N(-a3) - ebT * N(-a1))

def lookback_put(S, M, r, q, sig, T):                            # floating put: pays the maximum minus the last price
    b = r - q; t = sig * sqrt(T)
    a1 = (log(S / M) + (b + 0.5 * sig * sig) * T) / t; a2 = a1 - t; a3 = a1 - 2.0 * b * T / t
    van = M * exp(-r * T) * N(-a2) - S * exp(-q * T) * N(-a1)
    return van + S * exp(-r * T) * sig * sig / (2 * b) * (-(S / M) ** (-2 * b / (sig * sig)) * N(a3) + exp(b * T) * N(a1))

def expected_min(S, m, r, q, sig, T, n=4000):                  # Road 2: E[m_T] = integral over h of P(minimum > h)
    nu = r - q - 0.5 * sig * sig; t = sig * sqrt(T)
    def Q(h):                                                    # reflection principle: chance the path never touches h
        if h <= 0.0: return 1.0
        u = log(S / h)
        return N((u + nu * T) / t) - (h / S) ** (2 * nu / (sig * sig)) * N((nu * T - u) / t)
    w, tot = m / n, 0.0
    for i in range(n + 1): tot += (1 if i in (0, n) else 4 if i % 2 else 2) * Q(i * w)
    return w / 3 * tot

def by_integral(S, m, r, q, sig, T):
    return S * exp(-q * T) - exp(-r * T) * expected_min(S, m, r, q, sig, T)

MASK = (1 << 64) - 1
state = 20260924
def u01():                                                       # splitmix64, written out; a number in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
def gauss(): return sqrt(-2.0 * log(u01())) * cos(2.0 * pi * u01())   # Box-Muller
def bridge_low(x0, x1, v): return 0.5 * (x0 + x1 - sqrt((x1 - x0) ** 2 - 2.0 * v * log(u01())))
def bridge_high(x0, x1, v): return 0.5 * (x0 + x1 + sqrt((x1 - x0) ** 2 - 2.0 * v * log(u01())))
def mean_se(xs):                                                 # plain running sums, the same in both languages
    mu = ss = 0.0
    for x in xs: mu += x
    mu /= len(xs)
    for x in xs: ss += (x - mu) ** 2
    return mu, sqrt(ss / (len(xs) - 1) / len(xs))

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
D, nu = exp(-r * T), r - q - 0.5 * sig * sig
C = lookback_call(S, S, r, q, sig, T); V = vanilla(S, K, r, q, sig, T)
Emin = expected_min(S, S, r, q, sig, T); C2 = S * exp(-q * T) - D * Emin
P = lookback_put(S, S, r, q, sig, T); gap_fwd = S * exp(-q * T) - S * D
Cfix = P + gap_fwd                                               # (M_T - 100) = (M_T - S_T) + (S_T - 100) when K = S = M
lam = (r - q + 0.5 * sig * sig) / (sig * sig); B = 80.0          # the shelf's down-and-in call, barrier 80
y = log(B * B / (S * K)) / (sig * sqrt(T)) + lam * sig * sqrt(T)
DI = S * exp(-q * T) * (B / S) ** (2 * lam) * N(y) - K * D * (B / S) ** (2 * lam - 2) * N(y - sig * sqrt(T))

fl, pu, fx = [], [], []                                          # Road 3: exact continuous extremes, one step per path
for _ in range(200000):
    x = nu * T + sig * sqrt(T) * gauss(); ST = S * exp(x)
    fl.append(D * (ST - S * exp(min(0.0, bridge_low(0.0, x, sig * sig * T)))))
    hi = S * exp(max(0.0, bridge_high(0.0, x, sig * sig * T)))
    pu.append(D * (hi - ST)); fx.append(D * max(hi - K, 0.0))
(C3, se3), (P3, seP), (F3, seF) = mean_se(fl), mean_se(pu), mean_se(fx)

daily, cont, gap = [], [], []                                    # Road 4: 252 daily looks, same paths watched continuously too
dt = T / 252
for _ in range(20000):
    x = lo_d = lo_c = 0.0
    for _ in range(252):
        x1 = x + nu * dt + sig * sqrt(dt) * gauss()
        lo_c = min(lo_c, bridge_low(x, x1, sig * sig * dt)); x = x1; lo_d = min(lo_d, x)
    daily.append(D * (S * exp(x) - S * exp(lo_d))); cont.append(D * (S * exp(x) - S * exp(lo_c)))
    gap.append(cont[-1] - daily[-1])
(C4, se4), (C4c, se4c), (G4, seG) = mean_se(daily), mean_se(cont), mean_se(gap)
bgk = S * exp(-q * T) - D * Emin * exp(0.5826 * sig * sqrt(dt))  # Broadie-Glasserman-Kou shift of the minimum

h = 1e-4; price = lambda s, **k: lookback_call(s, S, **{**dict(r=r, q=q, sig=sig, T=T), **k})
rows = [("vanilla call, strike 100", V), ("1 lookback call, closed form", C), ("  extra over the vanilla", C - V),
    ("2 lookback call, integral of P(min > h)", C2), ("  expected minimum E[m_T]", Emin),
    ("3 lookback call, exact-minimum simulation", C3), ("  standard error", se3),
    ("4 lookback call, watched daily", C4), ("  standard error", se4), ("  same paths, watched continuously", C4c),
    ("  continuous minus daily, paired", G4), ("  standard error", seG), ("  daily, formula minus paired gap", C - G4),
    ("  daily, Broadie-Glasserman-Kou shift", bgk), ("prepaid share S e^-qT", S * exp(-q * T)), ("  S e^-qT - K e^-rT", gap_fwd),
    ("floating lookback put, formula", P), ("  simulation", P3), ("  standard error", seP),
    ("fixed-strike lookback call, parity", Cfix), ("  simulation", F3), ("  standard error", seF), ("fixed-strike lookback put, parity", C - gap_fwd),
    ("down-and-in call, barrier 80", DI), ("down-and-out call, barrier 80", V - DI),
    ("seasoned, minimum 90: formula", lookback_call(S, 90.0, r, q, sig, T)), ("  integral", by_integral(S, 90.0, r, q, sig, T)),
    ("  vanilla struck at 90", vanilla(S, 90.0, r, q, sig, T)),
    ("greek delta, bump", (price(S + h) - lookback_call(S - h, S - h, r, q, sig, T)) / (2 * h)), ("  C / S", C / S),
    ("greek vega per vol point", (price(S, sig=sig + 0.01) - price(S, sig=sig - 0.01)) / 2),
    ("greek rho per rate point", (price(S, r=r + 0.01) - price(S, r=r - 0.01)) / 2),
    ("greek theta, one day", price(S, T=T - 1 / 365) - C),
    ("wrong: dividend ignored, q = 0", price(S, q=0.0)), ("wrong: e^bT dropped", lookback_call(S, S, r, q, sig, T, False)),
    ("try: T = 0.25", price(S, T=0.25)), ("try: r = q = 5%, formula", price(S, q=0.05)),
    ("  integral", by_integral(S, S, r, 0.05, sig, T))]
for name, v in rows: print(f"{name:<42} {v:>12.6f}")
a1 = (r - q + 0.5 * sig * sig) * T / (sig * sqrt(T)); a2, a3 = a1 - sig * sqrt(T), a1 - 2 * (r - q) * sqrt(T) / sig
print(f"pieces: a1, a2, a3               {a1:9.6f} {a2:9.6f} {a3:9.6f}")
print(f"pieces: N(a1), N(a2), N(-a1), N(-a3)  {N(a1):.6f} {N(a2):.6f} {N(-a1):.6f} {N(-a3):.6f}")
print(f"pieces: e^bT, bracket, S e^-rT sig^2/2b  {exp((r - q) * T):.6f} {N(-a3) - exp((r - q) * T) * N(-a1):.6f} {S * D * sig * sig / (2 * (r - q)):.6f}")
sigs = [0.05 * i for i in range(1, 9)]
print("chart, sigma            " + " ".join(f"{s:6.2f}" for s in sigs))
for lab, f in (("fixed-strike", lambda s: lookback_put(S, S, r, q, s, T) + gap_fwd), ("floating", lambda s: price(S, sig=s)),
               ("vanilla", lambda s: vanilla(S, K, r, q, s, T))):
    print(f"chart, {lab:<17}" + " ".join(f"{f(s):6.2f}" for s in sigs))
path = [100, 96, 91, 88, 93, 97, 94, 99, 104, 101, 107, 110, 108]
lows = [min(path[:i + 1]) for i in range(len(path))]
print("path, month-end price  " + " ".join(f"{p:4d}" for p in path))
print("path, lowest so far    " + " ".join(f"{p:4d}" for p in lows))
print(f"path pays: lookback {path[-1] - lows[-1]}, vanilla {max(path[-1] - 100, 0)}, fixed-strike {max(max(path) - 100, 0)}")

assert abs(C - 15.975910) < 5e-7, "closed form vs the shelf's house number"
C90, I90 = lookback_call(S, 90.0, r, q, sig, T), by_integral(S, 90.0, r, q, sig, T)
assert abs(C - C2) < 1e-6 and abs(C90 - I90) < 1e-6, "closed form vs the level-by-level integral, fresh and seasoned"
assert abs(C3 - C) < 3 * se3, "exact-minimum simulation within three standard errors"
assert G4 > 5 * seG, "daily watching must price clearly below continuous watching"
assert abs(V - DI - 9.133306) < 5e-7, "down-and-out vs the shelf's house number"
assert abs(F3 - Cfix) < 3 * seF and abs(P3 - P) < 3 * seP, "fixed-strike and put vs simulation"
assert abs((price(S + h) - price(S)) / h - C / S) < 1e-5, "delta at issue is C/S: the minimum's own slope is zero"
assert abs(price(S, q=0.05) - by_integral(S, S, r, 0.05, sig, T)) < 1e-6, "zero-carry branch vs the integral"
print("ALL CHECKS PASS")
