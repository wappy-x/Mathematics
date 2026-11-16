# Lax-Milgram for steady heat in a two-material wall: constants, bounds, three roads.
import math
K1, K2, S, D2, F = 1.8, 0.04, 0.30, 0.05, 1000.0   # W/(m K), W/(m K), m, m, W/m^3
L, R2 = S + D2, D2 / K2                             # wall thickness m; formwork resistance m^2 K/W

def closed(x, beta):  # exact rise above the air, K: -(k u')' - beta*u = F in the concrete
    if beta == 0.0:
        A = F * S * (1 + S / (2 * K1 * R2)) / (K1 + S / R2)
        inner = lambda y: -F * y * y / (2 * K1) + A * y
    else:
        mu = math.sqrt(beta / K1); c, s = math.cos(mu * S), math.sin(mu * S)
        P, Q = F / beta * (c - 1), -F / beta * mu * s
        b = -(P / R2 + K1 * Q) / (K1 * mu * c + s / R2)
        inner = lambda y: F / beta * (math.cos(mu * y) - 1) + b * math.sin(mu * y)
    return inner(x) if x <= S else inner(S) * max(L - x, 0.0) / D2

def thomas(lo, di, up, rhs):  # solve a three-diagonal system; also return the smallest pivot
    n = len(di); d, r = di[:], rhs[:]; piv = abs(d[0])
    for i in range(1, n):
        if d[i - 1] == 0.0: return None, 0.0   # a zero pivot: the matrix is singular
        m = lo[i] / d[i - 1]; d[i] -= m * up[i - 1]; r[i] -= m * r[i - 1]; piv = min(piv, abs(d[i]))
    x = [0.0] * n; x[-1] = r[-1] / d[-1]
    for i in range(n - 2, -1, -1):
        x[i] = (r[i] - up[i] * x[i + 1]) / d[i]
    return x, piv

def fem(N, beta, k2=K2, heat_all=False, k1=K1):  # hat functions; node on the joint when 7 divides N
    h = L / N; di = [0.0] * (N - 1); off = [0.0] * (N - 1); md = [0.0] * (N - 1); mo = [0.0] * (N - 1); rhs = [0.0] * (N - 1)
    for e in range(N):
        conc = (e + 0.5) * h < S; k = k1 if conc else k2; w = 1.0 if (conc or heat_all) else 0.0
        for i in (e - 1, e):  # interior node numbers 0..N-2 sit at x = (i+1) h
            if 0 <= i < N - 1:
                di[i] += k / h; md[i] += w * h / 3; rhs[i] += w * F * h / 2
        if 1 <= e < N - 1:
            off[e] = -k / h; mo[e] = w * h / 6
    lo = [off[i] - beta * mo[i] for i in range(N - 1)]; up = lo[1:] + [0.0]
    u, piv = thomas(lo, [di[i] - beta * md[i] for i in range(N - 1)], up, rhs)
    return u, piv, (di, off, md, mo), rhs

def lowest_eig(N, heat_all):  # inverse iteration: smallest lambda with K v = lambda M v
    k = 1.0 if heat_all else K1  # heat_all: plain -u'' on the whole wall, for Poincare
    _, _, (di, off, md, mo), _ = fem(N, 0.0, k2=k if heat_all else K2, heat_all=heat_all, k1=k)
    lo = off; up = off[1:] + [0.0]; mul = lambda a, b, v: [a[i] * v[i] + (b[i] * v[i - 1] if i else 0) + (b[i + 1] * v[i + 1] if i + 1 < len(v) else 0) for i in range(len(v))]
    v = [1.0] * (N - 1)
    for _ in range(60):
        v, _ = thomas(lo, di, up, mul(md, mo, v)); s = max(abs(t) for t in v); v = [t / s for t in v]
    dot = lambda a, b: sum(p * q for p, q in zip(a, b))
    return dot(v, mul(di, off, v)) / dot(v, mul(md, mo, v))

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def peak(beta):
    xs = [i * L / 7000 for i in range(7001)]; v = [closed(x, beta) for x in xs]
    j = max(range(7001), key=lambda i: abs(v[i])); return xs[j], v[j]

M, ALPHA, CP = K1, K2, L / math.pi
print(f"wall: concrete {S:.2f} m k {K1:.3f}, formwork {D2:.2f} m k {K2:.3f} W/(m K), heating {F:.0f} W/m3")
print(f"constants: M = k_max {M:.3f}, alpha = k_min {ALPHA:.3f} W/(m K), M/alpha {M / ALPHA:.1f}")
cp_fe = 1 / math.sqrt(lowest_eig(280, True))
print(f"Poincare: C_P = L/pi {CP:.6f} m, finite elements N = 280: {cp_fe:.6f} m")
print(f"full Sobolev norm: alpha = k_min/(1 + C_P^2) = {ALPHA / (1 + CP**2):.6f} (x in m); factor 1/(1 + C_P^2) = {1 / (1 + CP**2):.5f} (x in m), {1 / (1 + (1000 * CP)**2):.7f} (x in mm)")
fnorm = F * math.sqrt(S); lnorm = CP * fnorm; ceil = lnorm / ALPHA; pceil = math.sqrt(L) / 2 * ceil
print(f"load: |f| {fnorm:.4f} W/m^2.5, |l| at most C_P |f| = {lnorm:.4f} W/m^1.5")
print(f"ceilings: |u'| at most {ceil:.2f} K/m^0.5, peak rise at most {pceil:.2f} K")
uj = closed(S, 0.0); A0 = F * S * (1 + S / (2 * K1 * R2)) / (K1 + S / R2); xp = A0 * K1 / F; up_ = closed(xp, 0.0)
print(f"closed form: joint {uj:.4f} K, peak {up_:.4f} K at {xp:.4f} m")
q0, qL = K1 * A0, uj / R2   # heat leaving each face, W/m2
print(f"by hand: formwork resistance {R2:.4f} m2 K/W, slope at the bare face {A0:.4f} K/m, sqrt(L)/2 = {math.sqrt(L) / 2:.6f} m^0.5")
print(f"heat out: bare face {q0:.4f} W/m2, formwork face {qL:.4f} W/m2, sum {q0 + qL:.4f} = F S {F * S:.4f}")
g1 = simpson(lambda x: (A0 - F * x / K1)**2, 0.0, S); g2 = (uj / D2)**2 * D2   # slope squared, each layer
grad, energy = math.sqrt(g1 + g2), K1 * g1 + K2 * g2
work = simpson(lambda x: F * closed(x, 0.0), 0.0, S)
print(f"|u'| = {grad:.4f} K/m^0.5; energy a(u,u) = {energy:.4f}, l(u) = {work:.4f} W K/m2")
print(f"a(u,u)/|u'|^2 = {energy / grad**2:.4f}, between alpha and M: {ALPHA - 1e-9 <= energy / grad**2 <= M + 1e-9}")
assert ALPHA - 1e-9 <= energy / grad**2 <= M + 1e-9   # the true profile obeys both constants (1e-9 for rounding)
assert abs(cp_fe - CP) < 1e-5 and abs(q0 + qL - F * S) < 1e-9          # Poincare by two roads; heat balance
assert abs(energy - work) < 1e-9 * work and abs(up_ - peak(0.0)[1]) < 1e-6 and grad <= ceil and up_ <= pceil  # energy identity; Lax-Milgram ceilings hold
print("Galerkin, beta = 0:   N  nodes exact to 1e-12  energy error W K/m2  ratio")
prev = None
for N in (7, 14, 28, 56):
    u, _, _, rhs = fem(N, 0.0); h = L / N
    err = max(abs(u[i] - closed((i + 1) * h, 0.0)) for i in range(N - 1))
    e = work - sum(p * q for p, q in zip(u, rhs))
    print(f"                   {N:4d}  {str(err < 1e-12):>20}  {e:19.6f}  " + (f"{prev / e:.3f}" if prev else "  -"))
    assert err < 1e-12 and (prev is None or 3.9 < prev / e < 4.1)   # exact at nodes; energy error falls 4x per halving
    prev = e
lam1_fe = [lowest_eig(N, False) for N in (70, 140, 280)]
a, b = math.pi / (2 * S), math.pi / S
g = lambda m: K1 * m * math.cos(S * m) + (K2 / D2) * math.sin(S * m)
for _ in range(100):
    m = (a + b) / 2; a, b = (a, m) if g(a) * g(m) <= 0 else (m, b)
lam1 = K1 * m * m
print(f"critical rate beta*: matching root {lam1:.4f}, finite elements N = 70/140/280: " + " ".join(f"{t:.4f}" for t in lam1_fe) + " W/(m3 K)")
print(f"crude Poincare test certifies beta < k_min/C_P^2 = {K2 / CP**2:.4f} W/(m3 K) only")
assert abs(lam1_fe[-1] - lam1) < 1e-3 and lam1_fe[0] > lam1_fe[1] > lam1_fe[2] > lam1  # eigenvalue by two roads
print("  beta W/(m3 K)  beta/beta*  alpha_beta  peak closed K  peak N = 280 K")
for r in (0.0, 0.5, 0.8, 0.9, 0.99, 1.01):
    beta = r * lam1; xb, pb = peak(beta); u = fem(280, beta)[0]; pf = max(u, key=abs)
    print(f"  {beta:12.4f}  {r:10.2f}  {(1 - r) * ALPHA:10.5f}  {pb:13.4f}  {pf:14.4f}")
    assert abs(pf - pb) < 2e-3 * abs(pb)   # Galerkin agrees with the closed form
piv0 = fem(70, 0.0, k2=0.0)[1]
print(f"what breaks: formwork k = 0: smallest pivot {piv0:.4f}")
print(f"what breaks: beta = 1.01 beta*: rise {peak(1.01 * lam1)[1]:.1f} K, below the air")
print(f"what breaks: beta = 10: crude alpha {K2 - 10 * CP**2:.5f}, true alpha {(1 - 10 / lam1) * ALPHA:.5f}, peak {peak(10.0)[1]:.4f} K")
assert piv0 == 0.0 and peak(1.01 * lam1)[1] < 0.0 < peak(10.0)[1]   # each failure shows
print(f"chart, x (m)       " + " ".join(f"{0.05 * i:7.2f}" for i in range(8)))
for r in (0.0, 0.5, 0.8):
    print(f"chart, beta/beta* {r:.1f}" + " ".join(f"{closed(0.05 * i, r * lam1):7.2f}" for i in range(8)))
print("ALL CHECKS PASS")
