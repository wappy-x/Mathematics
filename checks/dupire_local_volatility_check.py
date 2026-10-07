# Dupire local volatility -- the check behind the card.  Standard library only.
# The normal CDF is Marsaglia's series written out; the forward equation is marched
# with a tridiagonal solver written out.  Nothing imported knows the answer.
from math import log, sqrt, exp, pi

S0, R, Q, SIG = 100.0, 0.05, 0.02, 0.20          # the house market, every call at 20%
H, DT = 1.0, 0.01                                # grid steps: $1 in strike, 0.01 year in expiry

def N(x):                                        # bell-curve area left of x, summed as a series
    if x < -10.0: return 0.0
    if x > 10.0: return 1.0
    s, t, b, q, i = x, 0.0, x, x * x, 1.0
    while s != t:
        i += 2.0; b *= q / i; t = s; s = t + b
    return 0.5 + s * exp(-0.5 * q - 0.91893853320467274178)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def bs(S, K, T, sig):                            # the house call price at one volatility
    v = sig * sqrt(T)
    d1 = (log(S / K) + (R - Q + 0.5 * sig * sig) * T) / v
    return S * exp(-Q * T) * N(d1) - K * exp(-R * T) * N(d1 - v)

def slopes(C, K, T, h, dt):                      # road 1: differences on a grid of prices
    return (C(K, T), (C(K, T + dt) - C(K, T - dt)) / (2 * dt), (C(K + h, T) - C(K - h, T)) / (2 * h),
            (C(K + h, T) - 2 * C(K, T) + C(K - h, T)) / (h * h))

def closed(K, T):                                # road 2: the house formula's own slopes
    v = SIG * sqrt(T)
    d1 = (log(S0 / K) + (R - Q + 0.5 * SIG * SIG) * T) / v; d2 = d1 - v
    c = S0 * exp(-Q * T) * N(d1) - K * exp(-R * T) * N(d2)
    ct = S0 * exp(-Q * T) * phi(d1) * SIG / (2 * sqrt(T)) - Q * S0 * exp(-Q * T) * N(d1) + R * K * exp(-R * T) * N(d2)
    gamma = exp(-Q * T) * phi(d1) / (S0 * v)     # spot gamma, for the mistake table
    return (c, ct, -exp(-R * T) * N(d2), exp(-R * T) * phi(d2) / (K * v)), gamma

def parts(p, K):                                 # carry terms, numerator, denominator
    c, ct, ck, ckk = p
    return (R - Q) * K * ck, Q * c, ct + (R - Q) * K * ck + Q * c, 0.5 * K * K * ckk

def dupire(p, K):                                # the formula: local variance at (K, T)
    _, _, num, den = parts(p, K)
    return num / den

def march(sig, per, half, steps):                # road 3: march the forward equation in expiry
    dx = log(1.1) / per                          # log-strike step; $100 and $110 are both nodes
    x = [log(S0) + (j - half) * dx for j in range(2 * half + 1)]
    u = [max(S0 - exp(xj), 0.0) for xj in x]     # expiry 0: the payoff (S - K)+
    a, dt = 0.5 * sig * sig, 1.0 / steps
    b = a + (R - Q)                              # C_T = a (u_xx - u_x) - (r - q) u_x - q u
    lo, di, up = a / dx / dx + b / (2 * dx), -2 * a / dx / dx - Q, a / dx / dx - b / (2 * dx)
    snaps = [u]
    for n in range(1, steps + 2):
        th, T = (1.0 if n <= 4 else 0.5), n * dt # four implicit steps smooth the kink, then Crank-Nicolson
        rhs = [u[j] + (1 - th) * dt * (lo * u[j - 1] + di * u[j] + up * u[j + 1]) for j in range(1, len(u) - 1)]
        left = S0 * exp(-Q * T) - exp(x[0]) * exp(-R * T)
        A, B, Cc = -th * dt * lo, 1 - th * dt * di, -th * dt * up
        rhs[0] -= A * left
        cp, dp = [Cc / B], [rhs[0] / B]          # Thomas algorithm: sweep down, then back up
        for i in range(1, len(rhs)):
            m = B - A * cp[-1]
            cp.append(Cc / m); dp.append((rhs[i] - A * dp[-1]) / m)
        for i in range(len(rhs) - 2, -1, -1):
            dp[i] -= cp[i] * dp[i + 1]
        u = [left] + dp + [0.0]
        snaps.append(u)
    return x, snaps, dx, dt

def read_marched(snaps, n, j, K, dx, dt):        # Dupire on the marched grid, in log strike
    u = snaps[n]
    ux, uxx = (u[j + 1] - u[j - 1]) / (2 * dx), (u[j + 1] - 2 * u[j] + u[j - 1]) / (dx * dx)
    ct = (snaps[n + 1][j] - snaps[n - 1][j]) / (2 * dt)
    return dupire((u[j], ct, ux / K, (uxx - ux) / (K * K)), K)

def row(name, vals, d=6, w=12):
    print(f"{name:<42}" + "".join(f"{v:>{w}.{d}f}" for v in vals))

flat = lambda K, T: bs(S0, K, T, SIG)
pts = [(100.0, 1.0), (110.0, 0.5)]
g1 = [slopes(flat, K, T, H, DT) for K, T in pts]
g2 = [closed(K, T)[0] for K, T in pts]
print(f"house market: S 100, r 0.05, q 0.02, every call at 20%; grid steps h {H:g}, dt {DT:g}")
print(f"{'':<42}{'(100, 1)':>12}{'(110, 0.5)':>12}")
for name, f in (("call C(K - h, T)", lambda K, T: flat(K - H, T)), ("call C(K, T)", flat),
                ("call C(K + h, T)", lambda K, T: flat(K + H, T)), ("call C(K, T - dt)", lambda K, T: flat(K, T - DT)),
                ("call C(K, T + dt)", lambda K, T: flat(K, T + DT))):
    row(name, [f(K, T) for K, T in pts])
print("road 1: differences on the grid above; road 2: the house formula's own slopes")
for road, g in (("road 1", g1), ("road 2", g2)):
    for i, nm in ((1, "C_T"), (2, "C_K"), (3, "C_KK")):
        row(f"{road}: {nm}", [p[i] for p in g])
    for i, nm in ((0, "(r - q) K C_K"), (1, "q C"), (2, "numerator"), (3, "denominator 0.5 K^2 C_KK")):
        row(f"{road}: {nm}", [parts(p, K)[i] for p, (K, T) in zip(g, pts)])
    row(f"{road}: local variance", [dupire(p, K) for p, (K, T) in zip(g, pts)])
    row(f"{road}: local vol", [sqrt(dupire(p, K)) for p, (K, T) in zip(g, pts)])
row("road 1: local vol to four places", [sqrt(dupire(p, K)) for p, (K, T) in zip(g1, pts)], 4)
row("density p = e^{rT} C_KK, closed form", [exp(R * T) * p[3] for p, (K, T) in zip(g2, pts)])

x, snaps, dx, dt = march(SIG, 40, 600, 400)      # 1,201 log strikes, 600 either side of $100
jm = [600, 640]                                  # the nodes at $100 and $110
ns = [round(T / dt) for K, T in pts]
print(f"road 3: forward equation marched from the payoff at 20%, {len(x)} strikes, {round(1 / dt)} steps a year")
row("road 3: call, marched", [snaps[n][j] for n, j in zip(ns, jm)])
row("road 3: call, house formula", [flat(K, T) for K, T in pts])
lv3 = [sqrt(read_marched(snaps, n, j, exp(x[j]), dx, dt)) for n, j in zip(ns, jm)]
row("road 3: local vol read off marched prices", lv3)

DSH, SD = 100.0, 0.10                            # second case: stock + $100 cushion moves like the house at 10%
cushion = lambda K, T: bs(S0 + DSH, K + DSH * exp((R - Q) * T), T, SD)
truth = lambda K, T: SD * (K + DSH * exp((R - Q) * T)) / K
ks = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0]
read2 = [sqrt(dupire(slopes(cushion, K, 1.0, H, DT), K)) for K in ks]
read_flat = [sqrt(dupire(slopes(flat, K, 1.0, H, DT), K)) for K in ks]
print("second case: local vol in percent at T = 1, strikes 70 to 130 in steps of 10")
row("cushioned stock, read off its call prices", [100 * v for v in read2], 2, 7)
row("cushioned stock, known in advance", [100 * truth(K, 1.0) for K in ks], 2, 7)
row("flat 20% surface, read off its call prices", [100 * v for v in read_flat], 2, 7)

(c, ct, ck, ckk), _ = closed(100.0, 1.0)
_, _, num, den = parts((c, ct, ck, ckk), 100.0)
p110, gam110 = closed(110.0, 0.5)
row("wrong: drop the 1/2 in the denominator", [sqrt(num / (2 * den))])
row("wrong: zero-rate formula on today's prices", [sqrt(ct / den)])
row("wrong: leave out q C", [sqrt((num - Q * c) / den)])
row("wrong: flip the sign of (r - q) K C_K", [sqrt((num - 2 * (R - Q) * 100.0 * ck) / den)])
row("wrong: spot gamma for C_KK at (110, 0.5)", [sqrt(parts(p110, 110.0)[2] / (0.5 * 110.0 ** 2 * gam110))])
row("try: desk grid h 5, dt 0.25, at (100, 1)", [sqrt(dupire(slopes(flat, 100.0, 1.0, 5.0, 0.25), 100.0))])
row("try: half the steps, h 0.5, dt 0.005", [sqrt(dupire(slopes(flat, 100.0, 1.0, 0.5, 0.005), 100.0))])
row("try: every call at 30%, read at (110, 0.5)", [sqrt(dupire(slopes(lambda K, T: bs(S0, K, T, 0.3), 110.0, 0.5, H, DT), 110.0))])
edge = slopes(flat, 60.0, 0.1, H, DT)
print(f"{'edge: C_KK by differences at (60, 0.1)':<42}{edge[3]:>12.3e}")
row("edge: local variance there", [dupire(edge, 60.0)], 2)

assert abs(sqrt(dupire(g1[0], 100.0)) - SIG) < 1e-4, "road 1 at (100, 1) hands back 20%"
assert abs(sqrt(dupire(g1[1], 110.0)) - SIG) < 1e-4, "road 1 at (110, 0.5) hands back 20%"
assert max(abs(dupire(p, K) - SIG * SIG) for p, (K, T) in zip(g2, pts)) < 1e-12, "road 2: exact"
assert max(abs(snaps[n][j] - flat(K, T)) for n, j, (K, T) in zip(ns, jm, pts)) < 5e-4, "road 3 prices"
assert max(abs(v - SIG) for v in lv3) < 1e-4, "road 3: read back off marched prices"
assert max(abs(v - truth(K, 1.0)) for v, K in zip(read2, ks)) < 1e-4, "second case: sloped vol read back"
print("ALL CHECKS PASS")
