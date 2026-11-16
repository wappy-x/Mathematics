# How big must n be: Berry-Esseen and the skewness correction -- the check.
# Standard library only.  S = number of sixes in n fair-die rolls.  Roads to
# the law of S: convolution in whole numbers, the binomial formula, inversion
# of the fingerprint, and a seeded simulation.  Phi is its own series.
from math import comb, sqrt, exp, pi, cos, sin, ceil

C_BE, C_LOW, EPS = 0.4748, 0.409732, 1 / 20       # upper constant, Esseen's floor
def Phi(x):                                        # bell-curve area left of x
    if abs(x) > 8: return 1.0 if x > 0 else 0.0
    s = t = x; k = 0
    while abs(t) > 1e-17 * abs(s):
        k += 1; t *= x * x / (2 * k + 1); s += t
    return 0.5 + exp(-x * x / 2) / sqrt(2 * pi) * s
def dens(x): return exp(-x * x / 2) / sqrt(2 * pi)   # bell-curve height, Phi'(x)
def law(n, p):                                     # float law of S, by recursion
    q = 1 - p; pm = [q ** n]
    for k in range(1, n + 1): pm.append(pm[-1] * (n - k + 1) / k * p / q)
    return pm
def gaps(n, p, sign=1.0, half=0.5, skew_scale=1.0):
    # largest gaps: plain bell (both sides of each jump), half-step, half-step + Edgeworth
    q = 1 - p; mu, sd = n * p, sqrt(n * p * q)
    g = skew_scale * (1 - 2 * p) / sqrt(p * q)
    F = 0.0; D = Dh = De = 0.0; rows = []
    for k, pk in enumerate(law(n, p)):
        Fl, F = F, F + pk
        z = (k - mu) / sd; zh = (k + half - mu) / sd
        edg = Phi(zh) - sign * dens(zh) * g * (zh * zh - 1) / (6 * sqrt(n))
        D = max(D, abs(F - Phi(z)), abs(Fl - Phi(z)))
        Dh, De = max(Dh, abs(F - Phi(zh))), max(De, abs(F - edg))
        rows.append((k, F, Phi(z), Phi(zh), edg))
    return D, Dh, De, rows
def ratio(p): return (p * (1 - p)) * ((1 - p) ** 2 + p ** 2) / (p * (1 - p)) ** 1.5

n, p = 20, 1 / 6
gam, r = (1 - 2 * p) / sqrt(p * (1 - p)), ratio(p)
print(f"one roll: variance 5/36 = {5/36:.6f}, sigma = {sqrt(5/36):.6f}, rho = 65/648 = {65/648:.6f}")
print(f"rho/sigma^3 = {r:.6f}, skewness gamma = {gam:.6f}")
assert abs(r - sum(w * abs(x - p) ** 3 for x, w in ((1, p), (0, 1 - p))) / (5 / 36) ** 1.5) < 1e-12, "rho/sigma^3 by definition"

# ---- road 1 and 2: exact counts of the 6^20 roll sequences ----
cnt = [1]                                          # weights: 5 ways not six, 1 way six
for _ in range(n):
    cnt = [5 * (cnt[k] if k < len(cnt) else 0) + (cnt[k - 1] if k else 0) for k in range(len(cnt) + 1)]
assert cnt == [comb(n, k) * 5 ** (n - k) for k in range(n + 1)], "convolution = binomial"
exact = [c / 6 ** n for c in cnt]
# ---- road 3: inversion of the fingerprint (q + p e^{it})^n at 21 frequencies ----
def cpow(z, m):
    w = complex(1, 0)
    for _ in range(m): w *= z
    return w
inv = []
for k in range(n + 1):
    tot = 0j
    for j in range(n + 1):
        t = 2 * pi * j / (n + 1)
        tot += cpow(complex(1 - p + p * cos(t), p * sin(t)), n) * complex(cos(t * k), -sin(t * k))
    inv.append(tot.real / (n + 1))
err_inv = max(abs(a - b) for a, b in zip(inv, exact))
print(f"P(S <= 3) exact = {sum(cnt[:4])}/6^20 = {sum(exact[:4]):.6f}")
print(f"inversion vs count, largest difference below 1e-12: {err_inv < 1e-12}")
assert err_inv < 1e-12, "inversion of the fingerprint recovers the law"
# ---- road 4: simulation, SplitMix64, seed 2026 ----
M64 = (1 << 64) - 1; state = 2026
def nxt():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
SIMS, hits = 100000, 0
for _ in range(SIMS):
    sixes = sum(1 for _ in range(n) if (nxt() >> 32) % 6 == 5)
    hits += sixes <= 3
f3 = sum(exact[:4]); se = sqrt(f3 * (1 - f3) / SIMS)
print(f"simulated P(S <= 3), {SIMS} sessions = {hits / SIMS:.5f}, {abs(hits / SIMS - f3) / se:.2f} SE off")
assert abs(hits / SIMS - f3) < 4 * se, "simulation within 4 standard errors"

# ---- the gaps at n = 20 ----
D, Dh, De, rows = gaps(n, p)
print("k  F(k) exact  bell  half-step  +Edgeworth   errors x1000: bell half edge")
for k, F, b, h, e in rows[:9]:
    print(f"{k} {F:.4f} {b:.4f} {h:.4f} {e:.4f}   {1000*(F-b):7.2f} {1000*(F-h):6.2f} {1000*(F-e):6.2f}")
assert abs(sum(exact[:4]) - rows[3][1]) < 1e-12, "float law agrees with the count"
be = C_BE * r / sqrt(n)
print(f"Berry-Esseen bound {C_BE} x {r:.4f} / sqrt(20) = {be:.4f}")
print(f"largest gap, plain bell = {D:.4f}, gap / bound = {D / be:.3f}")
print(f"largest gap, half-step = {Dh:.4f}; half-step + Edgeworth = {De:.4f}")
print(f"Edgeworth gain: {Dh / De:.2f} times smaller")
print("bars at n = 20, one # per 5 thousandths:")
for name, v in (("Berry-Esseen bound", be), ("plain bell", D), ("half step", Dh), ("half step + Edgeworth", De)):
    print(f"  {name:<22}{'#' * round(200 * v):<42}{1000 * v:6.1f}")
mu, sd = n * p, sqrt(n * p * (1 - p)); z3, zh3 = (3 - mu) / sd, (3.5 - mu) / sd
print(f"total: mean {mu:.6f}, sd {sd:.6f}; k = 3: z = {z3:.4f}, half-step z = {zh3:.4f}")
print(f"  Phi'(z) = {dens(zh3):.6f}, Edgeworth term = {-dens(zh3) * gam * (zh3 * zh3 - 1) / (6 * sqrt(n)):+.6f}")
print(f"sharper Shevtsova form 0.33554 x ({r:.4f} + 0.415) / sqrt(20) = {0.33554 * (r + 0.415) / sqrt(n):.4f}")
assert D <= be and D > EPS > Dh > De, "bound holds; only the corrections beat 1/20"

# ---- how big must n be for a gap under 1/20? ----
print(f"Berry-Esseen promises 1/20 from n = {ceil((C_BE * r / EPS) ** 2)}")
NMAX = 400; tab = {m: gaps(m, p)[:3] for m in range(1, NMAX + 1)}
for w, name in enumerate(["plain bell", "half-step", "half-step + Edgeworth"]):
    first = 1 + max([m for m in tab if tab[m][w] >= EPS], default=0)
    print(f"actual gap under 1/20 for every n from {first} to {NMAX}: {name}")
print("n  plain  half-step  +Edgeworth  bound   (x1000)")
for m in [5, 10, 20, 50, 100, 200, 400]:
    a, b, c = tab[m]
    print(f"{m} {1000*a:.1f} {1000*b:.1f} {1000*c:.1f} {1000*C_BE*r/sqrt(m):.1f}")
    assert a <= C_BE * r / sqrt(m), "Berry-Esseen holds at every n"
assert tab[400][2] * 400 < tab[20][2] * 20 and tab[400][1] * 20 > tab[20][1], "1/n against 1/sqrt(n)"

# ---- the fingerprint: why the Edgeworth term is the next order ----
for m in (20, 80):
    t, mu, sd = 1.0, m * p, sqrt(m * p * (1 - p))
    u = t / sd
    phiZ = cpow(complex(1 - p + p * cos(u), p * sin(u)), m) * complex(cos(t * mu / sd), -sin(t * mu / sd))
    g0 = exp(-t * t / 2)
    edg = complex(g0, 0) * complex(1, -gam * t ** 3 / (6 * sqrt(m)))   # (it)^3 = -i t^3
    e1, e2 = abs(phiZ - g0), abs(phiZ - edg)
    print(f"fingerprint at t = 1, n = {m}: gap to bell {e1:.6f}, after Edgeworth {e2:.6f}")
    if m == 20: e1_20, e2_20 = e1, e2
assert 1.8 < e1_20 / e1 < 2.2 and e2_20 / e2 > 3.5, "orders 1/sqrt(n) and 1/n"

# ---- what breaks ----
Dc, Dhc, Dec, _ = gaps(20, 0.5)
print(f"fair coin: gap {Dc:.4f}, bound {C_BE / sqrt(20):.4f}, half-step {Dhc:.4f}, +Edgeworth {Dec:.4f}")
assert abs(Dhc - Dec) < 1e-15 and Dc < C_BE / sqrt(20), "zero skewness, zero gain"
print(f"Edgeworth without the half-step: {gaps(n, p, half=0.0)[2]:.4f}")
print(f"Edgeworth with the wrong sign: {gaps(n, p, sign=-1.0)[2]:.4f}")
print(f"skewness of the total, divided by sqrt(n) again: {gaps(n, p, skew_scale=1/sqrt(n))[2]:.4f}")
print(f"bound without sigma^3: {C_BE} x {65/648:.4f} / sqrt(20) = {C_BE * 65 / 648 / sqrt(n):.4f}")

# ---- try changing ----
D80, Dh80, De80, _ = gaps(80, p)
print(f"try n = 80: bound {C_BE * r / sqrt(80):.4f}, gaps {D80:.4f} {Dh80:.4f} {De80:.4f}")
Dd, Dhd, Ded, _ = gaps(20, 1 / 36)
print(f"try double sixes, p = 1/36: bound {C_BE * ratio(1/36) / sqrt(20):.4f}, gaps {Dd:.4f} {Dhd:.4f} {Ded:.4f}")
print(f"try floor constant {C_LOW}: {C_LOW * r / sqrt(20):.4f}")
print(f"try target 1/100: Berry-Esseen needs n = {ceil((C_BE * r / 0.01) ** 2)}")
print("ALL CHECKS PASS")
