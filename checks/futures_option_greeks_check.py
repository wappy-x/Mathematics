# Greeks of a futures option (Black-76), Brent house example. Standard library only.
from math import exp, log, sqrt, pi, cos, sin

def N(x):                       # normal CDF from its own series: erf(z) = 2/sqrt(pi) e^-z^2 sum 2^n z^(2n+1)/(1*3*..*(2n+1))
    z = abs(x) / sqrt(2.0)
    if z > 6.0:
        e = 1.0
    else:
        term, total, n = z, z, 0
        while term > 1e-17 * total:
            n += 1
            term *= 2.0 * z * z / (2 * n + 1)
            total += term
        e = 2.0 / sqrt(pi) * exp(-z * z) * total
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def d12(F, K, s, T):
    d1 = (log(F / K) + 0.5 * s * s * T) / (s * sqrt(T))
    return d1, d1 - s * sqrt(T)

def b76(F, K, r, s, T):          # premium-paid call, dollars per barrel
    d1, d2 = d12(F, K, s, T)
    return exp(-r * T) * (F * N(d1) - K * N(d2))

def greeks(F, K, r, s, T):       # closed forms: delta, gamma, vega, theta (per year), rho
    d1, d2 = d12(F, K, s, T); D = exp(-r * T); V = b76(F, K, r, s, T)
    return (D * N(d1), D * phi(d1) / (F * s * sqrt(T)), D * F * phi(d1) * sqrt(T),
            r * V - D * F * phi(d1) * s / (2.0 * sqrt(T)), -T * V)

F, K, r, s, T, lot = 85.0, 85.0, 0.05, 0.30, 0.5, 1000.0
d1, d2 = d12(F, K, s, T); D = exp(-r * T); V = b76(F, K, r, s, T)
dl, ga, ve, th, rh = greeks(F, K, r, s, T)
h = 1e-3                         # road 2: bump and reprice
dl_b = (b76(F + h, K, r, s, T) - b76(F - h, K, r, s, T)) / (2 * h)
ga_b = (b76(F + 0.1, K, r, s, T) - 2 * V + b76(F - 0.1, K, r, s, T)) / 0.01
ve_b = (b76(F, K, r, s + h, T) - b76(F, K, r, s - h, T)) / (2 * h)
th_b = -(b76(F, K, r, s, T + h) - b76(F, K, r, s, T - h)) / (2 * h)
rh_b = (b76(F, K, r + h, s, T) - b76(F, K, r - h, s, T)) / (2 * h)
q = lambda F_, r_: b76(F_, K, r_, s, T) / exp(-r_ * T)      # margined quote: nothing paid up front
qdl_b = (q(F + h, r) - q(F - h, r)) / (2 * h)
qrh_b = (q(F, r + h) - q(F, r - h)) / (2 * h)
qth = -F * phi(d1) * s / (2.0 * sqrt(T))
# road 3: Simpson integral over the lognormal, above the strike only (no kink inside)
zs = (log(K / F) + 0.5 * s * s * T) / (s * sqrt(T)); m = 4000; w = (8.0 - zs) / m
V_int, dl_int = 0.0, 0.0
for i in range(m + 1):
    z = zs + i * w; c = 1 if i in (0, m) else (4 if i % 2 else 2)
    FT = F * exp(-0.5 * s * s * T + s * sqrt(T) * z)
    V_int += c * (FT - K) * phi(z); dl_int += c * (FT / F) * phi(z)
V_int *= D * w / 3; dl_int *= D * w / 3
# road 4: Acme, the house stock, priced on spot (Black-Scholes) and on its one-year future (Black-76)
S, Ka, ra, qa, sa, Ta = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
b1 = (log(S / Ka) + (ra - qa + 0.5 * sa * sa) * Ta) / (sa * sqrt(Ta)); b2 = b1 - sa * sqrt(Ta)
C_bs = S * exp(-qa * Ta) * N(b1) - Ka * exp(-ra * Ta) * N(b2)
Fa = S * exp((ra - qa) * Ta); C_76 = b76(Fa, Ka, ra, sa, Ta); ga76 = greeks(Fa, Ka, ra, sa, Ta)
spot_delta = exp(-qa * Ta) * N(b1); stock_rho = Ka * Ta * exp(-ra * Ta) * N(b2)
chain_rho = ga76[4] + ga76[0] * Ta * Fa          # rho at fixed future + delta * dF/dr
# road 5: sell the Brent call, hedge daily with futures, 2000 paths, own random numbers
state = 0x2545F4914F6CDD1D
def unif():
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7
    state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
paths, steps = 2000, 126; dt = T / steps
acc = [[0.0, 0.0] for _ in range(3)]              # plain, untailed N(d1), tailed e^-rT N(d1)
for p in range(paths):
    Fp, G = F, [0.0, 0.0, 0.0]
    for k in range(steps):
        tau = T - k * dt; nd = N(d12(Fp, K, s, tau)[0])
        if k % 2 == 0:
            u1, u2 = unif(), unif(); rad = sqrt(-2.0 * log(u1)); z = rad * cos(2 * pi * u2)
        else:
            z = rad * sin(2 * pi * u2)
        Fn = Fp * exp(-0.5 * s * s * dt + s * sqrt(dt) * z)
        for j, hr in enumerate((0.0, nd, exp(-r * tau) * nd)):
            G[j] = G[j] * exp(r * dt) + hr * (Fn - Fp)
        Fp = Fn
    for j in range(3):
        x = max(Fp - K, 0.0) - G[j]; acc[j][0] += x; acc[j][1] += x * x
est = []
for a0, a1 in acc:
    mu = a0 / paths; sd = sqrt(a1 / paths - mu * mu)
    est.append((D * mu, D * sd / sqrt(paths)))
rows = [
    ("d1", d1), ("N(d1)", N(d1)), ("e^-rT", D),
    ("1 formula V", V), ("2 Simpson integral V", V_int),
    ("delta formula", dl), ("delta bump", dl_b), ("delta integral", dl_int),
    ("delta in barrels, per option", dl * lot), ("gamma formula", ga), ("gamma bump", ga_b),
    ("vega per unit formula", ve), ("vega per unit bump", ve_b),
    ("vega per vol point, per barrel", ve / 100), ("vega per vol point, per lot", ve / 100 * lot),
    ("theta per year formula", th), ("theta per year bump", th_b),
    ("theta per day, per barrel", th / 365), ("theta per day, per lot", th / 365 * lot),
    ("rho per unit formula", rh), ("rho per unit bump", rh_b), ("rho per unit, per lot", rh * lot),
    ("rho per basis point, per lot", rh * lot / 1e4),
    ("margined quote V_m = V e^rT", V / D), ("margined delta bump", qdl_b),
    ("margined theta per day, per barrel", qth / 365), ("margined rho bump", qrh_b),
    ("Acme Black-Scholes call", C_bs), ("Acme Black-76 on 1y future", C_76),
    ("Acme spot delta, shares", spot_delta), ("Acme futures delta, lots", ga76[0]),
    ("Acme stock rho", stock_rho), ("Acme -T C + delta T F", chain_rho),
    ("wrong: N(d1) lots, $ per $1 per lot", (N(d1) - dl) * lot),
    ("wrong: stock rho formula, Brent", K * T * D * N(d2)), ("wrong: theta per year, per lot", th * lot),
]
for name, v in rows:
    print(f"{name:<36} {v:>13.6f}")
A = D * F * phi(d1)
print(f"hand: sigma sqrt T {s * sqrt(T):.6f}  d2 {d2:.6f}  N(d2) {N(d2):.6f}  phi(d1) {phi(d1):.6f}")
print(f"hand: A = e^-rT F phi(d1) {A:.6f}  rV {r * V:.6f}  A sigma/(2 sqrt T) {A * s / (2 * sqrt(T)):.6f}  V per lot {V * lot:.6f}")
for lab, (e, se) in zip(("3 sim V, no hedge", "3 sim V, N(d1) lots", "3 sim V, e^-rT N(d1) lots"), est):
    print(f"{lab:<27} {e:>9.6f}  standard error {se:.6f}")
fs = [65.0 + 5.0 * i for i in range(9)]
print("chart, Brent future  " + " ".join(f"{x:6.0f}" for x in fs))
print("chart, V per barrel  " + " ".join(f"{b76(x, K, r, s, T):6.2f}" for x in fs))
print("chart, V + delta dF  " + " ".join(f"{V + dl * (x - F):6.2f}" for x in fs))
for lab, tt in (("lots, 6m, paid", 0.5), ("lots, 3m, paid", 0.25), ("lots, 2w, paid", 1 / 26)):
    print(f"{lab:<20} " + " ".join(f"{greeks(x, K, r, s, tt)[0]:6.2f}" for x in fs))
print("time left, F = 90   " + " ".join(f"{b:6.3f}" for b in (greeks(90.0, K, r, s, t)[0] for t in (0.5, 1 / 3, 1 / 6, 1 / 12, 1 / 24, 1 / 52))))
for mo, Fm in ((0, 85.0), (1, 88.0), (2, 93.0), (3, 87.0), (4, 80.0), (5, 84.0)):
    g = greeks(Fm, K, r, s, (6 - mo) / 12)
    print(f"story month {mo}  F {Fm:5.1f}  V {b76(Fm, K, r, s, (6 - mo) / 12):6.3f}  lots {g[0]:6.4f}  gamma {g[1]:6.4f}")
assert abs(V - 7.002679) < 5e-7, "formula vs the shelf's house call 7.002679"
assert abs(V_int - V) < 1e-8 and abs(dl_int - dl) < 1e-8, "integral road lands on formula price and delta"
assert abs(dl_b - dl) < 1e-8 and abs(ga_b - ga) < 1e-6 and abs(ve_b - ve) < 1e-5, "bumps match closed forms"
assert abs(th_b - th) < 1e-5 and abs(rh_b - rh) < 1e-6, "theta and rho = -T V by bumping"
assert abs(qdl_b - N(d1)) < 1e-8 and abs(qrh_b) < 1e-8, "margined delta N(d1), margined rho zero"
assert abs(C_76 - 9.227005508154) < 1e-9 and abs(chain_rho - stock_rho) < 1e-9, "Acme both ways"
assert abs(est[2][0] - V) < 3 * est[2][1] and est[2][1] < est[1][1] < est[0][1] / 5, "hedged simulation"
print("ALL CHECKS PASS")
