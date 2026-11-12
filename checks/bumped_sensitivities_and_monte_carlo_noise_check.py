# Bumping a simulated price -- the check behind the card.  Standard library only.
# The bell-curve area is a series, the random numbers come from SplitMix64, both written
# out here; the exact variances come from Simpson's rule, never from the simulation.
from math import cos, exp, log, log10, pi, sin, sqrt
S, K, R, Q, SIG, T, CASH = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 100.0
W, DISC, DRIFT, MASK = SIG * sqrt(T), exp(-R * T), (R - Q - 0.5 * SIG * SIG) * T, (1 << 64) - 1
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def area(x):                                      # bell-curve area left of x
    if abs(x) > 8.0: return 0.0 if x < 0.0 else 1.0
    term = total = x                              # x + x^3/3 + x^5/(3*5) + ...
    for k in range(1, 120):
        term *= x * x / (2 * k + 1); total += term
    return 0.5 + phi(x) * total
def d2(s): return (log(s / K) + DRIFT) / W
def call(s): return s * exp(-Q * T) * area(d2(s) + W) - K * DISC * area(d2(s))
def digi(s): return CASH * DISC * area(d2(s))     # pays CASH if the share ends above K
def zcut(s): return (log(K / s) - DRIFT) / W      # draws above this finish in the money
B = d2(S)
DC = exp(-Q * T) * area(B + W)                    # exact call delta
DD = CASH * DISC * phi(B) / (S * W)               # exact digital delta
SPC = -exp(-Q * T) * phi(B + W) / (S * W) / S * ((B + W) / W + 1.0)       # call V'''
SPD = CASH * DISC * phi(B) / (W * S ** 3) * (B * (B / W + 1.0) / W - 1.0 / W ** 2 + 2.0 * (B / W + 1.0))
def simpson(f, a, b, m=400):                      # integral of f(z) phi(z) from a to b
    hh = (b - a) / m
    t = f(a) * phi(a) + f(b) * phi(b)
    for i in range(1, m):
        z = a + i * hh; t += (4.0 if i % 2 else 2.0) * f(z) * phi(z)
    return t * hh / 3.0
def grow(z): return exp(DRIFT + W * z)
def ey2(s): return simpson(lambda z: (DISC * (s * grow(z) - K)) ** 2, zcut(s), 9.0)
def bias(kind, h):
    v = digi if kind == "dig" else call
    return (v(S + h) - v(S - h)) / (2.0 * h) - (DD if kind == "dig" else DC)
def var1(kind, h):                                # exact variance of ONE path's estimate
    if kind == "fresh":
        return (ey2(S + h) - call(S + h) ** 2 + ey2(S - h) - call(S - h) ** 2) / (4.0 * h * h)
    up, dn = zcut(S + h), zcut(S - h)
    if kind == "dig":
        m2 = (CASH * DISC / (2.0 * h)) ** 2 * (area(dn) - area(up))
        return m2 - (digi(S + h) - digi(S - h)) ** 2 / (4.0 * h * h)
    m2 = (simpson(lambda z: (DISC * ((S + h) * grow(z) - K) / (2.0 * h)) ** 2, up, dn)
          + simpson(lambda z: (DISC * grow(z)) ** 2, dn, 9.0))
    return m2 - ((call(S + h) - call(S - h)) / (2.0 * h)) ** 2
def rmse(kind, h, n): return sqrt(bias(kind, h) ** 2 + var1(kind, h) / n)
def best(kind, n):                                # golden-section search on log h
    a, b, g = log(0.01), log(60.0), (sqrt(5.0) - 1.0) / 2.0
    for _ in range(60):
        c, d = b - g * (b - a), a + g * (b - a)
        if rmse(kind, exp(c), n) < rmse(kind, exp(d), n): b = d
        else: a = c
    return exp(0.5 * (a + b))
def theory(kind, n):                              # best bump from the leading terms alone
    if kind == "fresh":
        return ((ey2(S) - call(S) ** 2) / 2.0 / (2.0 * (SPC / 6.0) ** 2 * n)) ** (1.0 / 6.0)
    return (CASH * CASH * DISC * DISC * phi(B) / (2.0 * S * W) / (4.0 * (SPD / 6.0) ** 2 * n)) ** 0.2
def normals(seed, n):                             # SplitMix64, then Box-Muller
    st, out = seed, []
    def unif():
        nonlocal st
        st = (st + 0x9E3779B97F4A7C15) & MASK
        z = ((st ^ (st >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    for _ in range(n // 2):
        rad, ang = sqrt(-2.0 * log(unif())), 2.0 * pi * unif()
        out.append(rad * cos(ang)); out.append(rad * sin(ang))
    return out
def cpay(s, z): return DISC * max(s * grow(z) - K, 0.0)
def dpay(s, z): return CASH * DISC if s * grow(z) > K else 0.0
def stats(xs):                                    # mean and standard error, in order
    m = 0.0
    for x in xs: m += x
    m /= len(xs); v = 0.0
    for x in xs: v += (x - m) * (x - m)
    return m, sqrt(v / (len(xs) - 1) / len(xs))
def estimate(kind, h, za, zb):                    # fresh: up leg on za, down leg on zb
    if kind == "fresh":
        (u, su), (d, sd) = stats([cpay(S + h, z) for z in za]), stats([cpay(S - h, z) for z in zb])
        return (u - d) / (2.0 * h), sqrt(su * su + sd * sd) / (2.0 * h)
    pay = dpay if kind == "dig" else cpay
    return stats([(pay(S + h, z) - pay(S - h, z)) / (2.0 * h) for z in za])
KINDS, NP = ("fresh", "dig", "shared"), 10000
print("--- 1. exact answers from the closed forms ---")
print(f"call:    price {call(S):.6f}  delta {DC:.6f}  V''' {SPC:.6f}")
print(f"digital: price {digi(S):.6f}  delta {DD:.6f}  V''' {SPD:.6f}  from a bump {6 * bias('dig', 0.1) / 0.01:.6f}")
ZA, ZB = normals(20261111, NP), normals(777, NP)
print(f"--- 2. one run, {NP} paths per leg: delta (standard error) ---")
print(f"{'h':>6}  {'fresh call':>19}  {'shared call':>19}  {'shared digital':>19}")
one = {}
for h in (10.0, 1.0, 0.1, 0.01):
    one[h] = [estimate(k, h, ZA, ZB) for k in ("fresh", "shared", "dig")]
    print(f"{h:>6.2f}" + "".join(f"  {m:>9.4f} ({s:>7.4f})" for m, s in one[h]))
for h in (1.0, 0.01): print(f"exact se at h = {h:.2f}:" + "".join(f"  {sqrt(var1(k, h) / NP):.4f}" for k in ("fresh", "shared", "dig")))
print(f"digital paths whose two legs differ at h = 0.01: {sum(dpay(S + 0.01, z) != dpay(S - 0.01, z) for z in ZA)}")
print("--- 3. exact root-mean-square error at the best bump, n paths per leg ---")
print(f"{'n':>8}  {'fresh h*':>8} {'theory':>7} {'rmse':>8}  {'digital h*':>10} {'theory':>7} {'rmse':>8}  {'shared, h=0.01':>14}")
rates = {k: [] for k in KINDS}
for n in (1000, 10000, 100000, 1000000):
    for k in KINDS:
        hk = 0.01 if k == "shared" else best(k, n)
        rates[k].append((hk, rmse(k, hk, n)))
    (hf, ef), (hd, ed), (_, es) = (rates[k][-1] for k in KINDS)
    print(f"{n:>8}  {hf:>8.3f} {theory('fresh', n):>7.3f} {ef:>8.5f}  {hd:>10.3f} {theory('dig', n):>7.3f} {ed:>8.5f}  {es:>14.5f}")
order = {k: log10(rates[k][2][1]) - log10(rates[k][3][1]) for k in KINDS}
print(f"observed order, last decade: fresh {order['fresh']:.3f} (theory 0.333)  digital {order['dig']:.3f} "
      f"(theory 0.400)  shared {order['shared']:.3f} (theory 0.500)")
RUNS, sq, hs = 100, {k: 0.0 for k in KINDS}, {k: rates[k][1][0] for k in KINDS}
for j in range(RUNS):
    za, zb = normals(5000 + 2 * j, NP), normals(5001 + 2 * j, NP)
    for k in KINDS:
        sq[k] += (estimate(k, hs[k], za, zb)[0] - (DD if k == "dig" else DC)) ** 2
print(f"--- 4. {RUNS} independent runs of {NP} paths at those bumps: measured against exact ---")
for k in KINDS:
    print(f"{k:<7} h = {hs[k]:>7.3f}  bias {bias(k, hs[k]):+.5f}  noise {sqrt(var1(k, hs[k]) / NP):.5f}  "
          f"exact rmse {rmse(k, hs[k], NP):.5f}  measured {sqrt(sq[k] / RUNS):.5f}  measured/exact {sqrt(sq[k] / RUNS) / rmse(k, hs[k], NP):.3f}")
nb = lambda k: sqrt(var1(k, hs[k]) / NP) / abs(bias(k, hs[k])); print(f"noise / |bias| at those bumps: fresh {nb('fresh'):.2f} (leading order {sqrt(2.0):.2f}), digital {nb('dig'):.2f} (leading order 2.00)")
print(f"--- 5. what breaks, {NP} paths per leg unless stated ---")
hc = (2.0 ** -52) ** (1.0 / 3.0) * S              # the cube-root rule for a pricer with no noise
print(f"fresh call, cube-root bump {hc:.6f}: exact se {sqrt(var1('fresh', hc) / NP):.1f}")
print(f"fresh call, one-cent bump: one run gives {one[0.01][0][0]:.4f}, se {one[0.01][0][1]:.4f}")
print(f"shared digital, one-cent bump: exact rmse {rmse('dig', 0.01, NP):.4f}, at its best bump {rates['dig'][1][1]:.5f}")
print(f"fresh call, h = {hs['fresh']:.3f} kept at 1000000 paths: exact rmse {rmse('fresh', hs['fresh'], 10 ** 6):.5f}, "
      f"at its best bump {rates['fresh'][3][1]:.5f}")
print("--- 6. chart points, every value is log10 ---")
for k in KINDS:
    print(f"chart, se at n = 10000, h = 10 to 0.001, {k:<6}"
          + "".join(f" {log10(sqrt(var1(k, h) / NP)):.2f}" for h in (10.0, 1.0, 0.1, 0.01, 0.001)))
for k in KINDS: print(f"chart, best rmse, n = 1e3 to 1e6, {k:<6}" + "".join(f" {log10(r):.2f}" for _, r in rates[k]))
for lab, f in (("bias", lambda h: abs(bias("fresh", h))), ("noise", lambda h: sqrt(var1("fresh", h) / NP)),
               ("rmse", lambda h: rmse("fresh", h, NP))):
    print(f"chart, fresh call, h = 32 to 1, {lab:<5}" + "".join(f" {log10(f(h)):.2f}" for h in (32.0, 16.0, 8.0, 4.0, 2.0, 1.0)))
assert abs(6.0 * bias("dig", 0.1) / 0.01 - SPD) < 0.01 * abs(SPD), "digital V''' formula against a bump"
assert abs(one[0.01][0][1] / sqrt(var1("fresh", 0.01) / NP) - 1.0) < 0.05, "fresh se: run against Simpson"
assert abs(one[1.0][2][1] / sqrt(var1("dig", 1.0) / NP) - 1.0) < 0.10, "digital se: run against exact"
assert abs(one[0.01][1][0] - DC) < 3.0 * one[0.01][1][1], "shared call delta within three standard errors"
assert one[0.01][0][1] > 1000.0 * one[0.01][1][1], "fresh draws are 1000 times noisier at one cent"
for k in ("fresh", "dig"): assert abs(rates[k][3][0] / theory(k, 10 ** 6) - 1.0) < 0.02, "best bump vs theory"
for k, p in (("fresh", 1 / 3), ("dig", 0.4), ("shared", 0.5)): assert abs(order[k] - p) < 0.02, "order vs theorem"
for k in KINDS: assert abs(sqrt(sq[k] / RUNS) / rmse(k, hs[k], NP) - 1.0) < 0.2, "100 runs against the exact rmse"
print("ALL CHECKS PASS")
