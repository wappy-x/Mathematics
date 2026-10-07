# Distance to default and expected default frequency -- the check behind the card.
# Standard library only; the normal CDF, its inverse, the integrator and the random
# numbers are written here.  The firm: assets V = 100 ($m), one zero-coupon debt of
# D = 80 due in T = 1 year, asset volatility 20%, riskless rate 5%, real drift 8%.
from math import exp, log, sqrt, cos, pi

V, D, T, sigma, r, mu = 100.0, 80.0, 1.0, 0.20, 0.05, 0.08

def N(x):                                    # normal CDF from the Taylor series of erf
    z = x / sqrt(2.0)
    term, s = z, 0.0
    for n in range(120):                     # term = (-1)^n z^(2n+1) / n!
        s += term / (2 * n + 1)
        term *= -z * z / (n + 1)
    return 0.5 + s / sqrt(pi)

def N_inv(p):                                # bisection: N rises, so one root
    lo, hi = -10.0, 10.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N(mid) < p else (lo, mid)
    return 0.5 * (lo + hi)

def dd(v, drift, t):                         # distance to default, in standard deviations
    return (log(v / D) + (drift - 0.5 * sigma * sigma) * t) / (sigma * sqrt(t))

def pd_simpson(drift, t, n=4000):            # road 2: lognormal density of V_T, dollars 0 to D
    m, s = log(V) + (drift - 0.5 * sigma * sigma) * t, sigma * sqrt(t)
    f = lambda v: exp(-(log(v) - m) ** 2 / (2 * s * s)) / (v * s * sqrt(2 * pi))
    a, h = 1e-9, (D - 1e-9) / n
    return h / 3 * sum((1 if k in (0, n) else 4 if k % 2 else 2) * f(a + k * h) for k in range(n + 1))

state = 20260928                             # xorshift64* random numbers, same in the Rust
def uniform():
    global state
    state ^= state >> 12; state ^= (state << 25) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) / 9007199254740992.0 + 1e-18

def normals():                               # Box-Muller: two uniforms in, two normals out
    u1, u2 = uniform(), uniform()
    rad = sqrt(-2.0 * log(u1))
    return rad * cos(2 * pi * u2), rad * cos(2 * pi * u2 - pi / 2)

def pd_euler(paths=40000, steps=100):        # road 3: dV = mu V dt + sigma V dW, step by step
    dt, hits = T / steps, 0
    for _ in range(paths // 2):
        a, b = V, V
        for _ in range(steps):
            z1, z2 = normals()
            a *= 1 + mu * dt + sigma * sqrt(dt) * z1
            b *= 1 + mu * dt + sigma * sqrt(dt) * z2
        hits += (a < D) + (b < D)
    return hits / paths

DD = dd(V, mu, T)
EDF, EDF_int, EDF_mc = N(-DD), pd_simpson(mu, T), pd_euler()
se = sqrt(EDF * (1 - EDF) / 40000)
d1 = (log(V / D) + (r + 0.5 * sigma * sigma) * T) / (sigma * sqrt(T))   # Merton's d1
d2 = d1 - sigma * sqrt(T)
Q, Q_int = N(-d2), pd_simpson(r, T)
lam = (mu - r) / sigma
Q_shift = N(N_inv(EDF) + lam * sqrt(T))      # road 4: from the real-world EDF to the pricing PD
E = V * N(d1) - D * exp(-r * T) * N(d2)
put = D * exp(-r * T) * N(-d2) - V * N(-d1)
spread = -log((V - E) / D) / T - r

rows = [("ln(V/D)", log(V / D)), ("real log drift mu - sigma^2/2", mu - 0.5 * sigma ** 2),
        ("one standard deviation, sigma sqrt T", sigma * sqrt(T)),
        ("top line, real drift", log(V / D) + (mu - 0.5 * sigma ** 2) * T),
        ("top line, r in place of mu", log(V / D) + (r - 0.5 * sigma ** 2) * T),
        ("DD, distance to default", DD), ("1 EDF = N(-DD)", EDF),
        ("2 EDF, Simpson over dollars", EDF_int), ("3 EDF, Euler paths, 40000", EDF_mc),
        ("  standard error of road 3", se), ("d2 = d1 - sigma sqrt T, Merton", d2),
        ("pricing PD = N(-d2)", Q), ("  pricing PD, Simpson", Q_int),
        ("lambda = (mu - r)/sigma", lam), ("DD - d2", DD - d2), ("N_inv(EDF)", N_inv(EDF)),
        ("4 pricing PD = N(N_inv(EDF) + lambda)", Q_shift), ("EDF at mu = 5%", N(-dd(V, 0.05, T))),
        ("house: equity", E), ("house: risky debt", V - E), ("house: default put", put),
        ("house: spread, bp", 10000 * spread), ("shortcut DD (V - D)/(sigma V)", (V - D) / (sigma * V)),
        ("  N(-shortcut)", N(-(V - D) / (sigma * V))),
        ("wrong: no -sigma^2/2, DD", (log(V / D) + mu * T) / (sigma * sqrt(T))),
        ("wrong: no -sigma^2/2, EDF", N(-(log(V / D) + mu * T) / (sigma * sqrt(T)))),
        ("wrong: N(+DD)", N(DD)), ("wrong: T = 3 with sigma T, EDF", N(-(log(V / D) + 0.06 * 3) / (sigma * 3))),
        ("  right: T = 3, EDF", N(-dd(V, mu, 3.0))), ("try: sigma = 30%, EDF", N(-(log(V / D) + (mu - 0.045)) / 0.3))]
for name, v in rows:
    print(f"{name:<40}{v:>12.6f}")

drifts = [0.0, 0.02, 0.04, 0.05, 0.06, 0.08, 0.10, 0.12]
print("chart, drift %     " + " ".join(f"{100 * m:6.0f}" for m in drifts))
print("chart, EDF %       " + " ".join(f"{100 * N(-dd(V, m, T)):6.2f}" for m in drifts))
print("chart, pricing PD %" + " ".join(f"{100 * Q:6.2f}" for m in drifts))
assets = [80.0 + 5 * k for k in range(9)]
print("moves, assets $m   " + " ".join(f"{v:6.0f}" for v in assets))
for t in (1.0, 3.0):
    print(f"moves, DD, T = {t:.0f}    " + " ".join(f"{dd(v, mu, t):6.3f}" for v in assets))
    print(f"moves, EDF %, T = {t:.0f} " + " ".join(f"{100 * N(-dd(v, mu, t)):6.2f}" for v in assets))

ks = [1.0, 2.0, 3.0, 4.0]                    # a fat tail with the same variance: Laplace
counts, M = [0, 0, 0, 0], 400000
for _ in range(M):
    u, w = uniform(), uniform()
    x = (-log(u) / sqrt(2)) * (1 if w < 0.5 else -1)
    counts = [c + (x < -k) for c, k in zip(counts, ks)]
for k, c in zip(ks, counts):
    print(f"tail at DD {k:.0f}: normal {100 * N(-k):8.4f}%  fat formula {100 * 0.5 * exp(-sqrt(2) * k):8.4f}%"
          f"  fat counted {100 * c / M:8.4f}%  ratio {0.5 * exp(-sqrt(2) * k) / N(-k):5.1f}")

assert abs(EDF - EDF_int) < 1e-8, "Simpson over dollars must land on N(-DD)"
assert abs(EDF_mc - EDF) < 4 * se, "Euler simulation within four standard errors"
assert abs(Q_shift - Q) < 1e-9, "shifting the EDF by lambda must give the pricing PD"
assert abs(Q_int - Q) < 1e-8, "pricing PD by integral over dollars at drift r"
assert abs(N(-dd(V, 0.05, T)) - Q_int) < 1e-8, "EDF at mu = r meets the integrated pricing PD"
assert abs(E - 24.59) < 0.005, "house equity, from the Merton card's numbers"
assert abs(DD - 1.415718) < 1e-6 and abs(EDF - 0.078429) < 1e-6, "the card's example: 1.416 and 7.84%"
assert abs(counts[3] / M - 0.5 * exp(-sqrt(2) * 4)) < 4 * sqrt(0.00175 / M), "counted fat tail"
print("ALL CHECKS PASS")
