# Barrier inverses -- the check behind the card.  Standard library only.
# Three roads to a barrier price: the closed form, an integral over where the share
# ends weighted by the Brownian-bridge chance of never touching, and a finite-difference
# grid.  The normal CDF, the integrator, the grid and both root finders are written here.
from math import log, exp, sqrt, pi

S, K, r, q, T = 100.0, 100.0, 0.05, 0.02, 1.0

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                   # 1/2 + phi(x) * (x + x^3/3 + x^5/(3*5) + ...)
    if abs(x) > 9.0: return 1.0 if x > 0 else 0.0
    s = t = x; n = 1
    while abs(t) > 1e-17 * abs(s):
        t *= x * x / (2 * n + 1); s += t; n += 1
    return 0.5 + phi(x) * s

def vanilla(sig):
    v = sig * sqrt(T); d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / v
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - v)

def down_out(H, sig):                       # road 1, closed form, barrier H <= strike K
    v = sig * sqrt(T); lam = (r - q + 0.5 * sig * sig) / (sig * sig)
    y = log(H * H / (S * K)) / v + lam * v
    d_in = S * exp(-q * T) * (H / S) ** (2 * lam) * N(y) - K * exp(-r * T) * (H / S) ** (2 * lam - 2) * N(y - v)
    return vanilla(sig) - d_in

def up_out(H, sig):                         # road 1, closed form, barrier H above strike K
    v = sig * sqrt(T); lam = (r - q + 0.5 * sig * sig) / (sig * sig)
    x1 = log(S / H) / v + lam * v; y = log(H * H / (S * K)) / v + lam * v; y1 = log(H / S) / v + lam * v
    u_in = (S * exp(-q * T) * N(x1) - K * exp(-r * T) * N(x1 - v)
            - S * exp(-q * T) * (H / S) ** (2 * lam) * (N(-y) - N(-y1))
            + K * exp(-r * T) * (H / S) ** (2 * lam - 2) * (N(-y + v) - N(-y1 + v)))
    return vanilla(sig) - u_in

def bridge(H, sig, up, n=4000):             # road 2: Simpson over the end point z
    v = sig * sqrt(T); m = (r - q - 0.5 * sig * sig) * T
    a = (log(K / S) - m) / v
    b = min((log(H / S) - m) / v, 12.0) if up else 12.0
    h = (b - a) / n; tot = 0.0
    for i in range(n + 1):
        z = a + i * h; ST = S * exp(m + v * z)
        alive = 1.0 - exp(-2.0 * log(S / H) * log(ST / H) / (sig * sig * T))
        w = 1 if i in (0, n) else (4 if i % 2 else 2)
        tot += w * (ST - K) * alive * phi(z)
    return exp(-r * T) * tot * h / 3.0

def grid(H, sig, up, m=40):                 # road 3: explicit finite differences in log price
    dx = abs(log(H / S)) / m; J = m + int(6.0 * sig * sqrt(T) / dx) + 2
    lo = log(H) - J * dx if up else log(H)
    xs = [lo + i * dx for i in range(J + 1)]
    V = [max(exp(x) - K, 0.0) for x in xs]
    V[J if up else 0] = 0.0
    steps = int(T * sig * sig / (0.9 * dx * dx)) + 1; dt = T / steps
    nu = r - q - 0.5 * sig * sig; a = 0.5 * sig * sig / (dx * dx); b = nu / (2 * dx)
    for k in range(1, steps + 1):
        W = [0.0] * (J + 1)
        for i in range(1, J):
            W[i] = V[i] + dt * (a * (V[i + 1] - 2 * V[i] + V[i - 1]) + b * (V[i + 1] - V[i - 1]) - r * V[i])
        if not up: W[J] = exp(xs[J] - q * k * dt) - K * exp(-r * k * dt)
        V = W
    return V[J - m if up else m]

def bisect(f, a, b, n=80):                  # keeps a sign change; returns None without one
    fa = f(a)
    if fa * f(b) > 0: return None
    for _ in range(n):
        c = 0.5 * (a + b); fc = f(c)
        if (fc > 0) == (fa > 0): a, fa = c, fc
        else: b = c
    return 0.5 * (a + b)

def secant(f, a, b, n=40):                  # a second root finder, run on road 2
    fa, fb = f(a), f(b)
    for _ in range(n):
        if fb == fa: break
        a, fa, b = b, fb, b - fb * (b - a) / (fb - fa); fb = f(b)
    return b

def out(label, x): print(f"{label:<40} " + ("        none" if x is None else f"{x:>12.6f}"))
sig = 0.20; C = vanilla(sig); do80 = down_out(80.0, sig); do80b = bridge(80.0, sig, False)
out("vanilla call, vol 20%", C); out("down-and-out, barrier 80, formula", do80)
out("down-and-out, barrier 80, bridge", do80b); out("down-and-in, barrier 80", C - do80)
lam = (r - q + 0.5 * sig * sig) / (sig * sig); out("lambda at vol 20%", lam)
out("y at barrier 80", log(80.0 * 80.0 / (S * K)) / (sig * sqrt(T)) + lam * sig * sqrt(T))
levels = [50.0, 60.0, 70.0, 80.0, 85.0, 88.0, 90.0, 92.0, 94.0, 96.0, 98.0, 100.0]
print("chart, barrier  " + " ".join(f"{h:6.0f}" for h in levels))
print("chart, DO price " + " ".join(f"{down_out(h, sig):6.2f}" for h in levels))
a, b, mids = 50.0, 100.0, []
for _ in range(7): c = 0.5 * (a + b); mids.append(c); a, b = (c, b) if down_out(c, sig) > 8.0 else (a, c)
print("bisection, midpoint " + " ".join(f"{h:.6f}" for h in mids)); print("bisection, DO price " + " ".join(f"{down_out(h, sig):9.4f}" for h in mids))
H1 = bisect(lambda h: down_out(h, sig) - 8.0, 50.0, 100.0)
H2 = secant(lambda h: bridge(h, sig, False) - 8.0, 85.0, 92.0)
out("level for 8.00, bisection on formula", H1); out("level for 8.00, secant on bridge", H2)
out("DO at that level, formula", down_out(H1, sig)); out("DO at that level, bridge", bridge(H1, sig, False))
gd = grid(H1, sig, False); out("DO at that level, grid", gd)
out("level for 9.30 (above vanilla)", bisect(lambda h: down_out(h, sig) - 9.30, 50.0, 99.999))
out("daily-monitored contract level", H1 * exp(0.5826 * sig * sqrt(1.0 / 252.0)))
print("DO at that level, vol 10 20 30 40%: " + " ".join(f"{down_out(H1, s):.4f}" for s in (0.1, 0.2, 0.3, 0.4)))
vols = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10, 0.12, 0.15, 0.20, 0.30, 0.40, 0.60]
print("chart, vol %    " + " ".join(f"{100 * s:5.0f}" for s in vols))
print("chart, UO price " + " ".join(f"{up_out(120.0, s):5.2f}" for s in vols))
lim0 = S * exp(-q * T) - K * exp(-r * T)
out("UO limit as vol -> 0", lim0); out("UO at vol 1%", up_out(120.0, 0.01))
out("UO at vol 20%, formula", up_out(120.0, sig)); out("UO at vol 20%, bridge", bridge(120.0, sig, True))
g20 = grid(120.0, sig, True); out("UO at vol 20%, grid", g20)
vega = lambda s: (up_out(120.0, s + 1e-5) - up_out(120.0, s - 1e-5)) / 2e-5
vega_b = lambda s: (bridge(120.0, s + 1e-4, True) - bridge(120.0, s - 1e-4, True)) / 2e-4
pk = bisect(vega, 0.03, 0.12); out("peak vol", pk); out("peak price", up_out(120.0, pk))
lo1 = bisect(lambda s: up_out(120.0, s) - 3.5, 0.01, pk); hi1 = bisect(lambda s: up_out(120.0, s) - 3.5, pk, 1.0)
lo2 = secant(lambda s: bridge(120.0, s, True) - 3.5, 0.04, 0.05); hi2 = secant(lambda s: bridge(120.0, s, True) - 3.5, 0.09, 0.10)
out("quote 3.50: low vol, formula", lo1); out("quote 3.50: low vol, bridge", lo2)
out("quote 3.50: high vol, formula", hi1); out("quote 3.50: high vol, bridge", hi2)
glo, ghi = grid(120.0, lo1, True), grid(120.0, hi1, True)
out("grid price at low vol", glo); out("grid price at high vol", ghi)
out("vega at low vol, formula", vega(lo1)); out("vega at low vol, bridge", vega_b(lo1))
out("vega at high vol, formula", vega(hi1)); out("vega at high vol, bridge", vega_b(hi1))
out("quote 2.00: the one vol", bisect(lambda s: up_out(120.0, s) - 2.0, pk, 1.0))
out("quote 2.00: root below the peak", bisect(lambda s: up_out(120.0, s) - 2.0, 0.01, pk))
out("quote 4.00: root below the peak", bisect(lambda s: up_out(120.0, s) - 4.0, 0.01, pk))
out("quote 4.00: root above the peak", bisect(lambda s: up_out(120.0, s) - 4.0, pk, 1.0))
out("quote 3.50: bisection on 1% to 60%", bisect(lambda s: up_out(120.0, s) - 3.5, 0.01, 0.60))
s1 = sig - (up_out(120.0, sig) - 3.5) / vega(sig); s2 = s1 - (up_out(120.0, s1) - 3.5) / vega(s1)
s3 = s2 - (up_out(120.0, s2) - 3.5) / vega(s2)
out("vega at 20%, formula", vega(sig)); out("newton from 20%, step 1", s1); out("newton from 20%, step 2", s2)
print(f"{'newton from 20%, step 3 below zero':<40} " + ("         yes" if s3 < 0 else "          no"))
van_b = bridge(1e-9, sig, False)             # a barrier so low it is never touched
iv = bisect(lambda s: vanilla(s) - van_b, 0.01, 1.0)
out("vanilla quote, by integral", van_b); out("vanilla implied vol", iv)
out("UO at the vanilla vol", up_out(120.0, iv)); out("market UO 1.20: spread over model", 1.20 - up_out(120.0, iv))
out("try: level for 5.00", bisect(lambda h: down_out(h, sig) - 5.0, 50.0, 99.999))
b130 = bisect(lambda s: (up_out(130.0, s + 1e-5) - up_out(130.0, s - 1e-5)), 0.03, 0.2)
out("try: barrier 130, peak vol", b130); out("try: barrier 130, peak price", up_out(130.0, b130))

assert abs(do80 - 9.133306) < 1e-6 and abs(do80b - do80) < 1e-7, "barrier 80 on two roads and the shelf's number"
assert abs(H1 - H2) < 1e-6 and abs(gd - 8.0) < 0.01 and bisect(lambda h: bridge(h, sig, False) - 9.30, 50.0, 99.999) is None, "the level on three roads; none for 9.30"
assert abs(lo1 - lo2) < 1e-6 and abs(hi1 - hi2) < 1e-6, "two implied vols on two roads"
assert abs(glo - 3.5) < 0.01 and abs(ghi - 3.5) < 0.01 and abs(g20 - up_out(120.0, sig)) < 0.01, "grid agrees"
assert vega_b(lo1) > 0 > vega_b(hi1) and all(bisect(lambda s: bridge(120.0, s, True) - 4.0, a, b) is None for a, b in ((0.01, pk), (pk, 1.0))), "opposite vegas; no vol for 4.00"
assert abs(up_out(120.0, 0.01) - lim0) < 1e-3 and abs(iv - 0.2) < 1e-6, "low-vol limit; vanilla vol recovered"
print("ALL CHECKS PASS")
