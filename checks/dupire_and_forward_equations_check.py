# Dupire's equation -- the check behind the card.  Standard library only.
# An index at 100, rates and dividends zero (illustrative).  60 call quotes:
# strikes 70..125 step 5, expiries 0.2..1.0 step 0.2 years.  The forward
# equation C_T = 1/2 sig(K)^2 K^2 C_KK is marched in strike and expiry
# (Crank-Nicolson, four implicit half-steps first, Thomas solve written out).
# Roads: the Black formula (normal CDF by series); one backward solve per
# strike; Dupire's inversion against the known volatility; a two-number fit.
import math

S0, KS, TS = 100.0, [70 + 5 * i for i in range(12)], [0.2, 0.4, 0.6, 0.8, 1.0]

def ncdf(x):                       # Marsaglia's series for the normal CDF
    s, t, k = x, x, 1
    while abs(t) > 1e-17:
        t *= x * x / (2 * k + 1); s += t; k += 1
    return 0.5 + s * math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)

def black(K, T, sg):
    d1 = (math.log(S0 / K) + 0.5 * sg * sg * T) / (sg * math.sqrt(T))
    return S0 * ncdf(d1) - K * ncdf(d1 - sg * math.sqrt(T))

def skew(a, b):
    return lambda x: max(0.05, min(1.0, a + b * math.log(x / 100))) if x > 0 else 0.0

def march(sig, init, dx, n):       # u_t = 1/2 sig(x)^2 x^2 u_xx on [0, 300]
    M, dt = round(300 / dx), 0.2 / n
    a = [0.5 * (sig(i * dx) * (i * dx)) ** 2 / dx ** 2 for i in range(M + 1)]
    u, out = [init(i * dx) for i in range(M + 1)], []
    steps = [(dt / 2, 1.0)] * 4 + [(dt, 0.5)] * (5 * n - 2)
    for s, (h, th) in enumerate(steps):
        l, d, r = [0.0] * (M + 1), [1.0] * (M + 1), u[:]
        for i in range(1, M):
            lam = a[i] * h
            r[i] = u[i] + (1 - th) * lam * (u[i - 1] - 2 * u[i] + u[i + 1])
            l[i], d[i] = -th * lam, 1 + 2 * th * lam
        r[1] -= l[1] * u[0]; r[M - 1] -= l[M - 1] * u[M]
        c, y = [0.0] * M, [0.0] * M          # Thomas: sweep down, then back up
        for i in range(1, M):
            m = d[i] - l[i] * c[i - 1]
            c[i], y[i] = l[i] / m, (r[i] - l[i] * y[i - 1]) / m
        u[M - 1] = y[M - 1]
        for i in range(M - 2, 0, -1):
            u[i] = y[i] - c[i] * u[i + 1]
        if s >= 4 and (s - 1) % n == 0:
            out.append(u[:])
    return out

def at(grid, dx, K):
    return grid[round(K / dx)]
def fwd(sig, dx, n):
    return march(sig, lambda x: max(S0 - x, 0.0), dx, n)
def table(g, dx):
    return [[at(g[j], dx, K) for K in KS] for j in range(5)]

RNG = [2026]
def noisy(c):                      # a quote: true price, uniform noise +-2 cents, to the cent
    RNG[0] = (RNG[0] + 0x9E3779B97F4A7C15) % 2**64      # SplitMix64, seed 2026
    z = RNG[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return math.floor(100 * (c + 0.04 * ((z ^ (z >> 31)) >> 11) / 2**53 - 0.02) + 0.5) / 100

def lv(C, dT, h, K):               # Dupire's inversion, centred differences
    cT, cKK = (C[2] - C[0]) / (2 * dT), (C[3] - 2 * C[1] + C[4]) / h ** 2
    return 2 * cT / (K * K * cKK)
def vol(v):
    return math.sqrt(v) if v > 0 else float("nan")
def pct(v):
    return f"{100 * math.sqrt(v):6.2f}" if v > 0 else "  none"

flat = lambda x: 0.2
err = []
for dx, n in [(0.5, 20), (0.25, 40)]:
    Q = table(fwd(flat, dx, n), dx)
    err.append(max(abs(Q[j][i] - black(K, TS[j], 0.2)) for j in range(5) for i, K in enumerate(KS)))
    print(f"flat 20%: dK = {dx} $, dT = {0.2 / n:.3f} y, max |forward - Black| = {err[-1]:.2e} $")
order = math.log2(err[0] / err[1])
print(f"observed order {order:.2f}; K = 100, T = 1: forward {Q[4][6]:.4f} $, Black {black(100, 1, 0.2):.4f} $")
assert err[1] < 1e-3 and 1.5 < order < 2.5

true = skew(0.20, -0.15)
DX, N = 0.25, 40
G = fwd(true, DX, N)
Q = table(G, DX)
for K in [80, 100, 120]:                  # one backward solve per strike
    B = march(true, lambda x: max(x - K, 0.0), DX, N)
    b6, b10 = at(B[2], DX, S0), at(B[4], DX, S0)
    f6, f10 = Q[2][KS.index(K)], Q[4][KS.index(K)]
    print(f"backward K={K}: T=0.6 {b6:.4f} vs forward {f6:.4f}; T=1.0 {b10:.4f} vs {f10:.4f}")
    assert abs(b6 - f6) < 2e-3 and abs(b10 - f10) < 2e-3

R = [[noisy(c) for c in row] for row in Q]
print("the 60 quotes ($), strikes 70..125 across, expiries 0.2..1.0 down:")
for j in range(5):
    print(f"  T={TS[j]:.1f} " + " ".join(f"{c:.2f}" for c in R[j]))
def surface(C):
    return [[lv([C[j-1][i], C[j][i], C[j+1][i], C[j][i-1], C[j][i+1]], 0.2, 5, KS[i])
             for i in range(1, 11)] for j in range(1, 4)]
LE, LR = surface(Q), surface(R)
print("local vol at T = 0.6 (%), strikes 75..120:")
print("  truth " + " ".join(f"{100 * true(K):.2f}" for K in KS[1:11]))
print("  exact " + " ".join(f"{100 * vol(v):.2f}" for v in LE[1]))
print("  noisy " + " ".join(f"{100 * vol(v):.2f}" for v in LR[1]))
we = max(abs(vol(v) - true(KS[i + 1])) for row in LE for i, v in enumerate(row))
wn = max(abs(vol(v) - true(KS[i + 1])) for row in LR for i, v in enumerate(row))
print(f"30 readings, worst error: exact quotes {100 * we:.2f} points, noisy quotes {100 * wn:.2f}")
assert we < 0.012 and wn < 0.03

c = [Q[1][6], Q[2][6], Q[3][6], Q[2][5], Q[2][7]]
for name, C in [("exact", c), ("quoted", [R[1][6], R[2][6], R[3][6], R[2][5], R[2][7]])]:
    cT, cKK = (C[2] - C[0]) / 0.4, (C[3] - 2 * C[1] + C[4]) / 25
    print(f"by hand {name}: " + " ".join(f"{x:.4f}" for x in C) + f"; C_T {cT:.4f} C_KK {cKK:.6f} var {2 * cT / (1e4 * cKK):.6f}")
cT, cKK = (c[2] - c[0]) / 0.4, (c[3] - 2 * c[1] + c[4]) / 25
print(f"mistakes, exact quotes: no 1/2 {math.sqrt(cT / (1e4 * cKK)):.4f}; one-sided C_T {math.sqrt(2 * (c[1] - c[0]) / 0.2 / (1e4 * cKK)):.4f}")
print("strike spacing h at K=100, T=0.6 (dT = 0.2): local vol (%) from exact and noisy quotes")
for h in [10, 5, 2.5, 1, 0.5]:
    pts = [(at(G[j], DX, 100), at(G[2], DX, 100 - h), at(G[2], DX, 100 + h)) for j in [1, 2, 3]]
    C = [pts[0][0], pts[1][0], pts[2][0], pts[1][1], pts[1][2]]
    e, t = lv(C, 0.2, h, 100), lv([noisy(x) for x in C], 0.2, h, 100)
    print(f"  h={h:<4} exact {100 * vol(e):.2f} bend {(C[3] - 2 * C[1] + C[4]) / h ** 2:.4f} noisy {pct(t)} variance {t:7.4f} bend noise up to {0.1 / h ** 2:.4f}")
assert abs(vol(e) - 0.2) < 0.003 and t < 0

p = [0.25, 0.0]                           # the fit: Gauss-Newton on (a, b)
def resid(p):
    M = table(fwd(skew(*p), 0.5, 20), 0.5)
    return [M[j][i] - R[j][i] for j in range(5) for i in range(12)]
for it in range(4):
    r0 = resid(p)
    J = [[(x - y) / 1e-4 for x, y in zip(resid([p[0] + 1e-4 * (k == 0), p[1] + 1e-4 * (k == 1)]), r0)] for k in (0, 1)]
    A = [[sum(x * y for x, y in zip(J[k], J[m])) for m in (0, 1)] for k in (0, 1)]
    g = [sum(x * y for x, y in zip(J[k], r0)) for k in (0, 1)]
    det = A[0][0] * A[1][1] - A[0][1] ** 2
    p = [p[0] - (A[1][1] * g[0] - A[0][1] * g[1]) / det, p[1] - (A[0][0] * g[1] - A[0][1] * g[0]) / det]
    rms = math.sqrt(sum(x * x for x in resid(p)) / 60)
    print(f"fit step {it + 1}: a = {p[0]:.4f}, b = {p[1]:.4f}, rms price error {rms:.4f} $")
print("fitted local vol (%), strikes 75..120: " + " ".join(f"{100 * skew(*p)(K):.2f}" for K in KS[1:11]))
assert abs(p[0] - 0.20) < 0.003 and abs(p[1] + 0.15) < 0.01 and rms < 0.03
print("ALL CHECKS PASS")
