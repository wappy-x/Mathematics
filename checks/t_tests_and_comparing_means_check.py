# t-tests -- the check behind the card.  Standard library only.  30 patients' systolic blood pressure (mmHg)
# before and after 8 weeks on a drug.  Road 1: t areas by Simpson over an angle.  Road 2: the closed-form t
# area.  Road 3: exact sign-flip, shuffle and sign tests by counting, no t law.  Then sample size and simulations.
from math import sqrt, pi, cos, sin, atan, log, exp, comb as choose
from functools import reduce

BEFORE = [152, 151, 165, 156, 163, 150, 150, 151, 128, 166, 131, 139, 161, 153, 163,
          174, 176, 170, 149, 179, 141, 151, 165, 149, 150, 147, 170, 120, 169, 166]
AFTER = [145, 149, 151, 159, 181, 137, 155, 145, 119, 156, 123, 123, 144, 160, 157,
         172, 172, 168, 131, 164, 140, 153, 150, 138, 135, 146, 167, 114, 158, 163]
CLAIM, NOISE, SIM, SEED = 10.0, 8.0, 4000, 20260928     # patients 1-15 women, 16-30 men

def total(xs): return reduce(lambda a, b: a + b, xs, 0.0)    # plain left-to-right sum
def mean(xs): return total(xs) / len(xs)
def sd(xs):
    m = mean(xs)
    return sqrt(total((x - m) ** 2 for x in xs) / (len(xs) - 1))

def simpson(f, a, b, m=600):                 # integral of f from a to b, m even
    h = (b - a) / m
    return (f(a) + f(b) + total((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m))) * h / 3

def t_area_angle(x, v):                      # road 1: any v > 0, u = root(v) tan(th)
    g = lambda th: cos(th) ** (v - 1)
    return 0.5 + 0.5 * simpson(g, 0.0, atan(x / sqrt(v))) / simpson(g, 0.0, pi / 2)

def t_area_closed(x, v):                     # road 2: whole-number v, closed form
    th = atan(x / sqrt(v))
    c2, term, total = cos(th) ** 2, 1.0, 1.0
    if v % 2 == 0:
        for j in range(1, v // 2):
            term *= c2 * (2 * j - 1) / (2 * j)
            total += term
        return 0.5 + sin(th) * total / 2
    for j in range(1, (v - 1) // 2):
        term *= c2 * (2 * j) / (2 * j + 1)
        total += term
    return 0.5 + (th + (sin(th) * cos(th) * total if v > 1 else 0.0)) / pi
def p_two(t, v, area): return 2 * (1 - area(abs(t), v))
def cutoff(area, p):                         # bisection: area(x) = p
    lo, hi = 0.0, 10.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if area(mid) < p else (lo, mid)
    return (lo + hi) / 2

def phi(x): return 0.5 + simpson(lambda u: exp(-u * u / 2), 0.0, x) / sqrt(2 * pi)   # the bell's area left of x
def power(m, gap, s):                        # exact paired-t power at 5%: the bell's chance averaged over chi-square
    k, ts, c, dens = m - 1, cutoff(lambda x: t_area_closed(x, m - 1), 0.975), gap * sqrt(m) / s, lambda v: v ** (k / 2 - 1) * exp(-v / 2)
    return simpson(lambda v: dens(v) * (phi(c - ts * sqrt(v / k)) + phi(-c - ts * sqrt(v / k))), 0.0, 6.0 * k) / simpson(dens, 0.0, 6.0 * k)

def welch(a, b):                             # t and Welch's degrees of freedom
    va, vb = sd(a) ** 2 / len(a), sd(b) ** 2 / len(b)
    return (mean(a) - mean(b)) / sqrt(va + vb), (va + vb) ** 2 / (va ** 2 / (len(a) - 1) + vb ** 2 / (len(b) - 1))
def pooled(a, b):
    na, nb = len(a), len(b)
    sp2 = ((na - 1) * sd(a) ** 2 + (nb - 1) * sd(b) ** 2) / (na + nb - 2)
    return (mean(a) - mean(b)) / sqrt(sp2 * (1 / na + 1 / nb)), na + nb - 2

n = len(BEFORE)
d = [b - a for b, a in zip(BEFORE, AFTER)]                 # drop, mmHg
dbar, sdd = mean(d), sd(d)
se = sdd / sqrt(n)
t0, t10 = dbar / se, (dbar - CLAIM) / se
tstar = cutoff(lambda x: t_area_closed(x, n - 1), 0.975)
print(f"drops: {d}")
print(f"n {n}, mean drop {dbar:.4f}, s {sdd:.4f}, standard error {se:.4f} mmHg")
print(f"before: mean {mean(BEFORE):.4f} s {sd(BEFORE):.4f}; after: mean {mean(AFTER):.4f} s {sd(AFTER):.4f}")
print(f"paired t vs 0: t {t0:.4f}, df {n - 1}, p road 1 {p_two(t0, n - 1, t_area_angle):.6f}, road 2 {p_two(t0, n - 1, t_area_closed):.6f}, one-sided {p_two(t0, n - 1, t_area_closed) / 2:.6f}")
print(f"one-sample t vs claim {CLAIM:.0f}: t {t10:.4f}, p road 1 {p_two(t10, n - 1, t_area_angle):.6f}, road 2 {p_two(t10, n - 1, t_area_closed):.6f}")
print(f"t cutoff 0.975, df {n - 1}: {tstar:.6f}; 95% interval for mean drop [{dbar - tstar * se:.4f}, {dbar + tstar * se:.4f}]")
(tw, vw), (tp, vp) = welch(BEFORE, AFTER), pooled(BEFORE, AFTER)
print(f"mistake, before vs after as independent: se {dbar / tw:.4f}, Welch t {tw:.4f} df {vw:.4f} p {p_two(tw, vw, t_area_angle):.6f}; pooled t {tp:.4f} p {p_two(tp, vp, t_area_closed):.6f}")
r = total((b - mean(BEFORE)) * (a - mean(AFTER)) for b, a in zip(BEFORE, AFTER)) / ((n - 1) * sd(BEFORE) * sd(AFTER))
print(f"  correlation before-after {r:.4f}; s^2(before)+s^2(after)-2 r s s = {sd(BEFORE)**2 + sd(AFTER)**2 - 2*r*sd(BEFORE)*sd(AFTER):.4f} = s_d^2 {sdd**2:.4f}")
wom, men = d[:15], d[15:]
(tw2, vw2), (tp2, vp2) = welch(men, wom), pooled(men, wom)
print(f"two-sample, men vs women: means {mean(men):.4f} {mean(wom):.4f}, s {sd(men):.4f} {sd(wom):.4f}, se {(mean(men) - mean(wom)) / tw2:.4f}")
print(f"  Welch t {tw2:.4f} df {vw2:.4f} p road 1 {p_two(tw2, vw2, t_area_angle):.6f}; pooled t {tp2:.4f} df {vp2} p {p_two(tp2, vp2, t_area_closed):.6f}")
bins = [sum(lo <= x < lo + 5 for x in d) for lo in range(-20, 25, 5)]
print(f"histogram of drops, bins of 5 from -20 to 25: {bins}")
k, m0 = sum(x > 0 for x in d), sum(x != 0 for x in d)
comb, tail = 1, 0                                           # exact sign test by counting
for j in range(0, min(k, m0 - k) + 1):
    tail += comb
    comb = comb * (m0 - j) // (j + 1)
print(f"sign test: {k} of {m0} dropped, exact two-sided p {min(1.0, 2 * tail / 2 ** m0):.6f}")
sub, T = {(0, 0): 1}, sum(d)                 # road 3: count every subset of the drops by its size k and sum s
for x in d: sub = {key: sub.get(key, 0) + sub.get((key[0] - 1, key[1] - x), 0) for key in set(sub) | {(k + 1, s + x) for k, s in sub}}
pe = [sum(c for (k, s), c in sub.items() if abs(2 * (s - mu * k) - (T - mu * n)) >= abs(T - mu * n) - 1e-9) / 2 ** n for mu in (0, CLAIM)]
pe.append(sum(c for (k, s), c in sub.items() if k == 15 and abs(2 * s - T) >= abs(2 * sum(men) - T)) / choose(n, 15))
print(f"exact randomisation p, all {2 ** n} sign patterns: vs 0 {pe[0]:.6f}, vs {CLAIM:.0f} {pe[1]:.6f}; all {choose(n, 15)} splits, men vs women {pe[2]:.6f}")
z = [cutoff(phi, q) for q in (0.975, 0.80)]
print(f"sample size, power 0.80 at a 6 mmHg drop, s {sdd:.4f}: z {z[0]:.6f} + {z[1]:.6f} = {sum(z):.4f}, normal rule n {(sum(z) * sdd / 6) ** 2:.1f}; exact t power n 16 {power(16, 6.0, sdd):.4f}, n 17 {power(17, 6.0, sdd):.4f}")

MASK, state = (1 << 64) - 1, SEED
def splitmix():                              # SplitMix64, seed 20260928
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & MASK
    return x ^ (x >> 31)
def unif(): return ((splitmix() >> 11) + 0.5) / 9007199254740992.0
def normal(): return sqrt(-2 * log(unif())) * cos(2 * pi * unif())

rate = lambda gen, test: sum(test(*gen()) < 0.05 for _ in range(SIM)) / SIM   # share with p < 0.05
def trial(drop):
    b = [152 + 13 * normal() for _ in range(n)]
    return b, [x - drop - NOISE * normal() for x in b]
pair = lambda b, a: p_two(mean([x - y for x, y in zip(b, a)]) / (sd([x - y for x, y in zip(b, a)]) / sqrt(n)), n - 1, t_area_closed)
unpair = lambda b, a: p_two(*welch(b, a), t_area_angle)
uneq = lambda: ([150 + 24 * normal() for _ in range(5)], [150 + 8 * normal() for _ in range(25)])
rows = [("paired, no real drop", rate(lambda: trial(0), pair)), ("paired, drop 6", rate(lambda: trial(6), pair)),
        ("unpaired, drop 6", rate(lambda: trial(6), unpair)),
        ("pooled, n 5 vs 25, s 24 vs 8, no difference", rate(uneq, lambda a, b: p_two(*pooled(a, b), t_area_closed))),
        ("Welch, same setting", rate(uneq, lambda a, b: p_two(*welch(a, b), t_area_angle)))]
rows += [(f"paired, n {m}, drop 6, spread as in the trial", rate(lambda: ([6 + sdd * normal() for _ in range(m)],), lambda dd: p_two(mean(dd) / (sd(dd) / sqrt(len(dd))), len(dd) - 1, t_area_closed))) for m in (16, 17)]
print(f"simulation, {SIM} trials each, share with p < 0.05:")
for nm, p in rows:
    print(f"  {nm:45s} {p:.4f} +/- {sqrt(p * (1 - p) / SIM):.4f}")
fig = [f"{40 + 2.5 * (b - 110):.1f} {210 - 2.5 * (a - 110):.1f}" for b, a in zip(BEFORE, AFTER)]
for i in range(0, n, 10): print("figure, points " + ", ".join(fig[i:i + 10]))

assert abs(p_two(t0, n - 1, t_area_angle) - p_two(t0, n - 1, t_area_closed)) < 1e-9   # two roads, odd df
assert abs(p_two(tp2, vp2, t_area_angle) - p_two(tp2, vp2, t_area_closed)) < 1e-9      # two roads, even df
assert abs(sdd ** 2 - (sd(BEFORE) ** 2 + sd(AFTER) ** 2 - 2 * r * sd(BEFORE) * sd(AFTER))) < 1e-9
assert abs(tp2 - tw2) < 1e-12                                      # equal sizes: same ratio
assert 14 <= vw2 <= vp2                                            # nu between 14 and 28
assert sum(sub.values()) == 2 ** n                                 # every sign pattern counted once
assert 2 * sum(c * s for (k, s), c in sub.items() if k == 15) == choose(n, 15) * T   # each drop is in half the splits
assert abs(pe[1] - p_two(t10, n - 1, t_area_closed)) < 0.15 * p_two(t10, n - 1, t_area_closed)   # exact flips and t within 15%
assert abs(pe[2] - p_two(tw2, vw2, t_area_angle)) < 0.05          # shuffle and Welch: different tests, near p
assert abs(rows[0][1] - 0.05) < 4 * sqrt(0.05 * 0.95 / SIM)        # paired t keeps its 5 percent
assert rows[3][1] - 0.05 > 4 * sqrt(0.05 * 0.95 / SIM)             # pooled t breaks with unequal spreads
assert abs(rows[4][1] - 0.05) < 4 * sqrt(0.05 * 0.95 / SIM)        # Welch repairs it
assert abs(power(n, 6.0, NOISE) - rows[1][1]) < 4 * sqrt(rows[1][1] * (1 - rows[1][1]) / SIM)   # exact power vs simulated
assert all(abs(power(16 + i, 6.0, sdd) - rows[5 + i][1]) < 4 * sqrt(rows[5 + i][1] * (1 - rows[5 + i][1]) / SIM) for i in (0, 1))   # small n too
assert power(16, 6.0, sdd) < 0.80 < power(17, 6.0, sdd)            # 17 patients, not 16, reach 80 percent
print("ALL CHECKS PASS")
