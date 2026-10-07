# The arithmetic Asian on jet fuel: 52 weekly fixings read the futures curve 100 e^(0.05 t).
# Standard library only.  Nothing imported knows the answer: the bell-curve area, the random
# numbers (splitmix64 + Box-Muller) and every path are written out below.
from math import log, sqrt, exp, cos, pi

K, r, sig, T, n = 100.0, 0.05, 0.20, 1.0, 52

def N(x):                                   # area left of x: Marsaglia's series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        i += 2.0
        b, t = b * x * x / i, s
        s += b
    return 0.5 + s * exp(-0.5 * x * x - 0.91893853320467274178)

def black(F, v, k, tp):                     # Black-76: call on a lognormal with forward F, log-spread v
    d1 = (log(F / k) + 0.5 * v * v) / v
    return exp(-r * tp) * (F * N(d1) - k * N(d1 - v))

def curve(c, lvl=100.0): return lambda t: lvl * exp(c * t)     # futures price for delivery at t
def dates(m, tx=T, t0=0.0): return [t0 + (tx - t0) * (i + 1) / m for i in range(m)]

def tw(fw, ts, s=sig, k=K):                 # Turnbull-Wakeman: exact two moments, fitted lognormal
    m, Fs = len(ts), [fw(t) for t in ts]
    M1 = sum(Fs) / m
    M2 = sum(Fs[i] * Fs[j] * exp(s * s * min(ts[i], ts[j])) for i in range(m) for j in range(m)) / (m * m)
    vA = sqrt(log(M2 / (M1 * M1)))
    return black(M1, vA, k, ts[-1]), M1, M2, vA

def kv(fw, ts, s=sig, k=K):                 # geometric twin, exact: the law of ln G summed date by date
    m = len(ts)
    mu = sum(log(fw(t)) - 0.5 * s * s * t for t in ts) / m
    var = s * s * sum(min(a, b) for a in ts for b in ts) / (m * m)
    return black(exp(mu + 0.5 * var), sqrt(var), k, ts[-1]), exp(mu + 0.5 * var)

state = 20260927                            # splitmix64: 64-bit integer mixing
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

def normal():                               # Box-Muller, one draw per pair of uniforms
    return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())

def mc(fw, ts, s=sig, k=K, paths=20000):    # fixing i = F(0,t_i) e^(s W(t_i) - s^2 t_i / 2)
    m, d = len(ts), exp(-r * ts[-1])
    base = [log(fw(t)) - 0.5 * s * s * t for t in ts]
    steps = [s * sqrt(t - u) for t, u in zip(ts, [0.0] + ts[:-1])]
    a = [0.0] * 8
    for _ in range(paths):
        W = tot = totlog = 0.0
        for b0, st in zip(base, steps):
            W += st * normal()
            tot, totlog = tot + exp(b0 + W), totlog + b0 + W
        A = tot / m
        X, Y = d * max(A - k, 0.0), d * max(exp(totlog / m) - k, 0.0)   # arithmetic, geometric
        for j, v in enumerate((X, X * X, Y, Y * Y, X * Y, A, A * A, A * A * A * A)):
            a[j] += v
    p = float(paths)
    mx, my, mA, mA2 = a[0] / p, a[2] / p, a[5] / p, a[6] / p
    vx, vy, cxy = a[1] / p - mx * mx, a[3] / p - my * my, a[4] / p - mx * my
    beta = cxy / vy                             # slope of X on Y; the twin's miss is subtracted
    return (mx, sqrt(vx / p), mx - beta * (my - kv(fw, ts, s, k)[0]), sqrt((vx - beta * cxy) / p),
            cxy / sqrt(vx * vy), my, sqrt(vy / p), mA, sqrt((mA2 - mA * mA) / p), mA2, sqrt((a[7] / p - mA2 * mA2) / p))

def row(label, *vals, w=12, dp=6):
    print(f"{label:<42}" + "".join(f"{v:>{w}.{dp}f}" for v in vals))

fw, ts = curve(0.05), dates(n)
plain = black(fw(T), sig * sqrt(T), K, T)
d1 = (log(100.0 / K) + (r + 0.5 * sig * sig) * T) / (sig * sqrt(T))    # spot form, no yield
spot_form = 100.0 * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))
TW, M1, M2, vA = tw(fw, ts)
KV, FG = kv(fw, ts)
e1 = (log(M1 / K) + 0.5 * vA * vA) / vA
mx, se, ctrl, se_c, rho, gsim, se_g, mA, se_A, mA2, se_A2 = mc(fw, ts, paths=50000)
ceiling = KV + exp(-r * T) * (M1 - FG)      # A - G >= (A-K)+ - (G-K)+ >= 0 on every path

for label, *vals in [("curve F(0,t) at first and last fixing", fw(ts[0]), fw(T)),
        ("plain call, Black-76 on F(0,T)", plain), ("plain call, spot form, no yield", spot_form),
        ("M1, mean of the average, exact", M1), ("  simulated, and its error bar", mA, se_A),
        ("M2, mean square of the average, exact", M2), ("  simulated, and its error bar", mA2, se_A2),
        ("M2 / M1^2", M2 / (M1 * M1)), ("log-spread of the average vA", vA),
        ("log-spread of one fixing, sigma*sqrt(T)", sig * sqrt(T)), ("cut-offs e1, e2", e1, e1 - vA),
        ("N(e1), N(e2)", N(e1), N(e1 - vA)), ("discount e^-rT", exp(-r * T)),
        ("geometric twin, Kemna-Vorst", KV), ("  simulated, and its error bar", gsim, se_g),
        ("geometric forward F_G", FG), ("1 plain simulation, and its error bar", mx, se),
        ("2 controlled simulation, and its bar", ctrl, se_c), ("  correlation rho", rho),
        ("  error bar shrinks by", se / se_c), ("  plain paths needed for that bar, times", (se / se_c) ** 2),
        ("3 Turnbull-Wakeman", TW), ("  minus road 2", TW - ctrl), ("4 floor (the twin) and ceiling", KV, ceiling),
        ("Asian / plain call", ctrl / plain), ("dial: lower spread only", black(fw(T), vA, K, T)),
        ("dial: lower forward only", black(M1, sig * sqrt(T), K, T)),
        ("wrong: fixings as independent draws", black(M1, sig * sqrt(T / n), K, T)),
        ("equity slope r-q = 3%, Turnbull-Wakeman", tw(curve(0.03), ts)[0])]:
    row(label, *vals)

def greeks(tsx):                            # bump the whole curve by 1%, the volatility by 0.01 point
    up, mid, dn = (tw(curve(0.05, 100.0 * (1 + h)), tsx)[0] for h in (0.01, 0.0, -0.01))
    vu, vd = tw(fw, tsx, sig + 1e-4)[0], tw(fw, tsx, sig - 1e-4)[0]
    return (up - dn) / 2.0, (up - 2 * mid + dn) / 1.0, (vu - vd) / 2e-4 / 100
row("greeks, Asian (delta gamma vega/pt)", *greeks(ts), w=10, dp=4)
row("greeks, plain call", *greeks([T]), w=10, dp=4)

print(f"{'scenario: TW, controlled MC, bar, TW - MC':<42}")
errs = [TW - ctrl]
for label, f, tx, s in (("  curve flat at 100", curve(0.0), ts, sig), ("  curve falling 5% (backwardation)", curve(-0.05), ts, sig),
                        ("  vol 30%", fw, ts, 0.3), ("  vol 40%", fw, ts, 0.4), ("  vol 50%", fw, ts, 0.5),
                        ("  vol 60%", fw, ts, 0.6), ("  five years, 52 fixings", fw, dates(n, 5.0), sig)):
    res = mc(f, tx, s)
    errs.append(tw(f, tx, s)[0] - res[2])
    row(label, tw(f, tx, s)[0], res[2], res[3], errs[-1], w=10, dp=4)
    if label == "  vol 60%": bar60 = res[3]
half, kstar = dates(26, 0.5), 2 * K - 80.0  # 26 fixings banked at $80; 26 left over half a year
res = mc(fw, half, k=kstar)
row("  half done, $80 banked (half of K*=120)", 0.5 * tw(fw, half, k=kstar)[0], 0.5 * res[2], 0.5 * res[3],
    0.5 * (tw(fw, half, k=kstar)[0] - res[2]), w=10, dp=4)
row("  half done: TW / MC", tw(fw, half, k=kstar)[0] / res[2])
strip = [[mth / 12 + (i + 1) / 252 for i in range(21)] for mth in range(12)]   # 21 daily fixings a month
kvs = [kv(fw, tm) for tm in strip]
row("monthly strip: TW, floor, ceiling", sum(tw(fw, tm)[0] for tm in strip) / 12, sum(g[0] for g in kvs) / 12,
    sum(g[0] + exp(-r * tm[-1]) * (tw(fw, tm)[1] - g[1]) for g, tm in zip(kvs, strip)) / 12)
print(f"{'chart, TW - MC in cents, vol 20% to 60%':<42}" + "".join(f"{100 * e:>7.2f}" for e in errs[:1] + errs[3:7]))
avgs = [80 + 5 * i for i in range(9)]
print(f"{'chart, average at expiry':<42}" + "".join(f"{x:>7d}" for x in avgs))
print(f"{'chart, profit after premium':<42}" + "".join(f"{max(x - K, 0.0) - ctrl:>7.2f}" for x in avgs))

assert abs(tw(fw, [T])[0] - spot_form) < 1e-9 and abs(spot_form - 10.450583572185565) < 1e-9, "one fixing: the plain call"
assert abs(gsim - KV) < 3 * se_g, "the paths reproduce the exact geometric price"
assert abs(mA - M1) < 3 * se_A and abs(mA2 - M2) < 3 * se_A2, "the paths reproduce both exact moments"
assert KV < ctrl < ceiling, "controlled price inside the AM-GM floor and ceiling"
assert abs(ctrl - mx) < 3 * se, "the control moves the price by less than three plain bars"
assert se / se_c > 10, "the control shrinks the error bar at least tenfold"
assert abs(TW - ctrl) < 0.03, "moment matching within three cents at 20% vol"
assert errs[6] > 10 * bar60 and errs[6] > 5 * (TW - ctrl), "at 60% vol the approximation has drifted"
assert tw(fw, half, k=kstar)[0] < res[2] - 3 * res[3], "half banked, far out of the money: the quick price is too cheap"
print("ALL CHECKS PASS")
