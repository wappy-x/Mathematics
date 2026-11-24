# Multilevel Monte Carlo -- the check behind the card.  Standard library only.  Nothing imported
# knows an answer: uniforms from the recurrence of the Monte Carlo pricing card, normals by Box-Muller,
# every integral by Simpson's rule, exact Euler prices from a density convolved with itself on a grid.
from math import ceil, cos, exp, log, pi, sin, sqrt
S0, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0   # the house Acme call
MU, DISC, MOD = R - Q, exp(-R * T), 1 << 32
SEED, PILOT, L, EPS = 20260914, 20000, 6, 0.01               # levels 0..6: h = 1 .. 1/64
EXACT = 9.227005508154                                       # the call card's price
def simpson(f, a, b, n):                 # every integral on this card
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def row(name, v): print(f"{name:<44}{v:>12.6f}" if isinstance(v, float) else f"{name:<44}{v:>12}")
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height
def ncdf(x): return 0.5 + simpson(phi, 0.0, x, 4000)      # bell-curve area to the left
def bs_call():                           # road 1: Black-Scholes
    vt = SIG * sqrt(T)
    d1 = (log(S0 / K) + (MU + 0.5 * SIG * SIG) * T) / vt
    return S0 * exp(-Q * T) * ncdf(d1) - K * exp(-R * T) * ncdf(d1 - vt)
def normals(st, count):                  # the recurrence, then Box-Muller, in pairs
    out = []
    while len(out) < count:
        st = (1664525 * st + 1013904223) % MOD
        rad = sqrt(-2.0 * log((st + 0.5) / MOD))
        st = (1664525 * st + 1013904223) % MOD
        ang = 2.0 * pi * (st + 0.5) / MOD
        out += [rad * cos(ang), rad * sin(ang)]
    return st, out
def cost(l): return 1 if l == 0 else 3 << (l - 1)         # fine steps plus coarse steps
def euler_end(dws, h):                   # Euler's terminal reading along given increments
    y = S0
    for dw in dws:
        y *= 1.0 + MU * h + SIG * dw
    return y
def level(l, n, st):                     # n samples of P_l - P_(l-1) on shared increments
    nf, s = 1 << l, [0.0] * 6            # sums of y, y^2, fine payoff and its square, coarse ditto
    hf, done = T / nf, 0
    while done < n:
        st, zs = normals(st, nf)
        for j in range(0, len(zs), nf):  # level 0 uses both draws of a pair
            fine = [z * sqrt(hf) for z in zs[j:j + nf]]
            pf = DISC * max(euler_end(fine, hf) - K, 0.0)
            pc = 0.0
            if l > 0:                    # the coarse path sums the fine increments in pairs
                coarse = [fine[i] + fine[i + 1] for i in range(0, nf, 2)]
                pc = DISC * max(euler_end(coarse, 2.0 * hf) - K, 0.0)
            y = pf - pc
            s = [u + w for u, w in zip(s, (y, y * y, pf, pf * pf, pc, pc * pc))]
            done += 1
    return st, s, done
def exact_euler(l, n=640, lo=-1.6, hi=1.6):   # road 3: E[P_l] with no random numbers
    h, dx = T / (1 << l), (hi - lo) / n       # density of log of one Euler factor ...
    def one(x):
        z = (exp(x) - 1.0 - MU * h) / (SIG * sqrt(h))
        return phi(z) * exp(x) / (SIG * sqrt(h))
    f, mid = [one(lo + i * dx) for i in range(n + 1)], n // 2
    for _ in range(l):                        # ... convolved with itself: 2, 4, ... steps
        f = [dx * sum(f[i] * f[k - i + mid] for i in range(max(0, k - mid), min(n, k + mid) + 1))
             for k in range(n + 1)]
    g = lambda i: f[i] * max(S0 * exp(lo + i * dx) - K, 0.0)
    pay = dx / 3.0 * sum((1 if i in (mid, n) else 4 if (i - mid) % 2 else 2) * g(i) for i in range(mid, n + 1))
    return DISC * pay
def plan(vs, eps):                       # path counts that meet the variance budget eps^2/2 at least cost
    lam = 2.0 / (eps * eps) * sum(sqrt(v * cost(l)) for l, v in enumerate(vs))
    ns = [ceil(lam * sqrt(v / cost(l))) for l, v in enumerate(vs)]
    return ns, sum(m * cost(l) for l, m in enumerate(ns))

bs = bs_call()
a, b = S0 * (1.0 + MU * T) - K, S0 * SIG * sqrt(T)        # one Euler step: a + b Z, a normal ending
p0 = DISC * (a * ncdf(a / b) + b * phi(a / b))
v0 = DISC * DISC * ((a * a + b * b) * ncdf(a / b) + a * b * phi(a / b)) - p0 * p0
ex = [exact_euler(l) for l in range(L + 1)]
print(f"Acme call: S={S0:.0f} K={K:.0f} r={R:.2f} q={Q:.2f} sigma={SIG:.2f} T={T:.0f}; Euler steps h = 1 .. 1/{1 << L}")
for name, v in [("Black-Scholes price", bs), ("one Euler step, closed form: price", p0),
                ("one Euler step, closed form: payoff variance", v0)]: row(name, v)
st, k, h6 = SEED, 0, T / (1 << L)                         # one path, read on all seven grids:
while True:                                                # the seed's first one in the money on both
    st, zs = normals(st, 1 << L)                           # the coarsest and the finest grid
    fine, prev, k = [z * sqrt(h6) for z in zs], 0.0, k + 1
    if min(euler_end([sum(fine)], T), euler_end(fine, h6)) > K: break
print(f"path {k} of the seed, read on every grid\ngrid      steps    ending      payoff   correction")
for l in range(L + 1):
    blk = (1 << L) >> l
    y = euler_end([sum(fine[i:i + blk]) for i in range(0, 1 << L, blk)], T / (1 << l))
    p = DISC * max(y - K, 0.0)
    print(f"{'level ' + str(l):<10}{1 << l:>6}{y:>10.4f}{p:>12.6f}{p - prev:>13.6f}")
    prev = p
pil, vs = [], []
print("pilot, 20000 paths a level")
print("level  h         exact E[P_l]  exact dE   pilot mean   std err    V_l       V ratio  cost  sqrt(V C)")
for l in range(L + 1):
    st, s, n = level(l, PILOT, st)
    m, v = s[0] / n, s[1] / n - (s[0] / n) ** 2
    pil.append((m, v, s[3] / n - (s[2] / n) ** 2, s[5] / n - (s[4] / n) ** 2)); vs.append(v)
    d = ex[l] - (ex[l - 1] if l else 0.0)
    rt = f"{vs[l - 1] / v:>8.3f}" if l > 1 else f"{'':>8}"
    print(f"{l:<6} {T / (1 << l):<9.6f}{ex[l]:>12.6f}{d:>11.6f}{m:>12.6f}{sqrt(v / n):>10.6f}{v:>10.4f}{rt}{cost(l):>6}{sqrt(v * cost(l)):>11.4f}")
ns, tot = plan(vs, EPS)[0], sum(sqrt(v * cost(l)) for l, v in enumerate(vs))
print(f"eps = {EPS}: budget eps^2/2 = {EPS * EPS / 2:.6f}, sum sqrt(V C) = {tot:.4f}, 2/eps^2 x sum = {2 / EPS / EPS * tot:.1f}")
print("level  paths N_l   mean        variance    N_l x cost")
means, var, work = [], 0.0, 0
for l in range(L + 1):
    st, s, n = level(l, ns[l], st)
    m, v = s[0] / n, s[1] / n - (s[0] / n) ** 2
    means.append(m); var, work = var + v / n, work + n * cost(l)
    print(f"{l:<6} {n:>9}  {m:>10.6f}  {v:>10.4f}  {n * cost(l):>11}")
est, bias, se = sum(means), ex[L] - bs, sqrt(var)
plain = ceil(2.0 * pil[L][2] / (EPS * EPS)) * (1 << L)
for name, v in [("multilevel estimate", est), ("  its standard error", se), ("  exact Euler bias at h = 1/64", bias),
                ("  root-mean-square error", sqrt(var + bias * bias)), ("  gap to Black-Scholes", est - bs),
                ("step-evaluations, multilevel", work), ("payoff variance at h = 1/64, pilot", pil[L][2]),
                ("step-evaluations, plain MC at h = 1/64", plain), ("  ratio, plain over multilevel", plain / work)]: row(name, v)
print("cost for a target error: L = 6 - log2(0.01/eps) as if the bias forced it, then L kept at 6, then L = 2")
print("eps      L   bias        multilevel   x eps^2    plain        x eps^2")
rows = []
for e, lv in ((0.08, 3), (0.04, 4), (0.02, 5), (0.01, 6), (0.005, 6), (0.01, 2)):
    c = plan(vs[:lv + 1], e)[1]
    p = ceil(2.0 * pil[lv][2] / (e * e)) * (1 << lv)
    rows.append((e, lv, c, p))
    print(f"{e:<8} {lv:<3}{ex[lv] - bs:>9.6f}{c:>13}{c * e * e:>10.1f}{p:>13}{p * e * e:>10.1f}")
indep = plan([vs[0]] + [pil[l][2] + pil[l][3] for l in range(1, L + 1)], EPS)[1]
same = ceil(2.0 * sum(vs) / (EPS * EPS)) * sum(cost(l) for l in range(L + 1))
print("what breaks")
for name, v in [("  drop level 0, keep only the corrections", sum(means[1:])),
                ("  stop at level 0: one step, exact price", ex[0]), ("    its bias", ex[0] - bs),
                ("  fresh draws for the coarse path: cost", indep), ("  the same N on every level: cost", same)]: row(name, v)
assert abs(bs - EXACT) < 1e-9                                   # road 1 against the house number
assert abs(ex[0] - p0) < 1e-6                                    # road 3 against the one-step closed form
assert all(abs(exact_euler(l, 1280) - ex[l]) < 1e-7 for l in range(L + 1))   # road 3 on a grid twice as fine
assert abs(pil[0][0] - p0) < 4.0 * sqrt(v0 / PILOT) and abs(pil[0][1] / v0 - 1.0) < 0.05
assert all(abs(pil[l][0] - (ex[l] - ex[l - 1])) < 4.0 * sqrt(vs[l] / PILOT) for l in range(1, L + 1))
assert all(1.5 < vs[l - 1] / vs[l] < 2.5 for l in range(2, L + 1))   # the correction variance roughly halves
assert abs(est - ex[L]) < 4.0 * se                               # road 2 against road 3
assert se < 1.05 * EPS / sqrt(2.0) and sqrt(var + bias * bias) < EPS
assert all(abs(ex[lv] - bs) < e / sqrt(2.0) for e, lv, c, p in rows)
for (e1, l1, c1, p1), (e2, l2, c2, p2) in zip(rows, rows[1:4]):   # halving eps: x8 plain, under x6 multilevel
    assert p2 / p1 > 7.0 and c2 / c1 < 6.0
assert plain / work > 5.0 and same > plain and indep > plain
print("ALL CHECKS PASS")
