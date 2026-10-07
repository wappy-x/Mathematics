# Hypothesis tests and p-values -- the check behind the card.  Standard library only.
# A drug trial: 45 of 100 recovered on the drug, 35 of 100 on placebo.  Is the gap
# more than chance?  Road 1: the z statistic and its tail from the bell's Taylor
# series.  Road 2: the same tail by Simpson's rule.  Road 3: all 101 x 101 outcomes
# under the null, enumerated exactly.  Road 4: 20,000 seeded null trials.
from math import sqrt, pi, exp

N, A, B, R, SEED = 100, 45, 35, 20000, 20260928

def Phi(x):                                  # bell area left of x, by its Taylor series
    term, total = x, x
    for k in range(1, 200):
        term *= -x * x / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2 * pi)

def simpson(f, a, b, m=4000):                # integral of f from a to b, m even
    h = (b - a) / m
    s = f(a) + f(b)
    for i in range(1, m):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def zstat(a, b, n=N):                        # gap in rates over its pooled standard error
    r = (a + b) / (2 * n)
    if r <= 0 or r >= 1:
        return 0.0
    return (a / n - b / n) / sqrt(r * (1 - r) * 2 / n)

def binom(r, n=N):                           # P(K = k) for k = 0..n, K ~ Binomial(n, r)
    pm = [(1 - r) ** n]
    for k in range(n):
        pm.append(pm[-1] * (n - k) / (k + 1) * r / (1 - r))
    return pm

def enum(ra, rb, cut):                       # exact chance that |z| >= cut, every outcome
    pa, pb = binom(ra), binom(rb)
    return sum(pa[a] * pb[b] for a in range(N + 1) for b in range(N + 1) if abs(zstat(a, b)) >= cut - 1e-12)

rbar = (A + B) / (2 * N)
se = sqrt(rbar * (1 - rbar) * 2 / N)
z0 = zstat(A, B)
p1 = 2 * (1 - Phi(z0))
bell = lambda u: exp(-u * u / 2) / sqrt(2 * pi)
p2 = 2 * simpson(bell, z0, 12.0)
p3 = enum(rbar, rbar, z0)
lo, hi = 0.0, 10.0
for _ in range(100):                         # bisection: the cutoff with two-sided area 0.05
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if 2 * (1 - Phi(mid)) > 0.05 else (lo, mid)
zc = (lo + hi) / 2
size, power = enum(rbar, rbar, zc), enum(0.45, 0.35, zc)
print(f"data: drug {A}/{N} = {A / N:.2f}, placebo {B}/{N} = {B / N:.2f}, gap {(A - B) / N:.2f}; {A + B} of {2 * N} recovered")
print(f"pooled rate {rbar:.2f}, variance of the gap {se * se:.6f}, standard error {se:.6f}, z = {z0:.6f}")
print(f"road 1, Taylor series: two-sided p = {p1:.6f}, one-sided p = {p1 / 2:.6f}")
print(f"road 2, Simpson's rule: two-sided p = {p2:.6f}")
print(f"road 3, all {(N + 1) ** 2} outcomes at rate {rbar:.2f}: exact p = {p3:.6f}")
print(f"cutoff for level 0.05: {zc:.6f}; exact size of 'reject if |z| >= cutoff' {size:.4f}")
print(f"exact power against 0.45 vs 0.35: {power:.4f}")

MASK, state = (1 << 64) - 1, SEED
def splitmix():                              # SplitMix64, seed 20260928
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & MASK
    return x ^ (x >> 31)

def trial(ra, rb):                           # recoveries after 20, 40, .., 100 patients per arm
    arms = []
    for r in (ra, rb):
        c, marks = 0, []
        for i in range(1, N + 1):
            c += (splitmix() >> 11) / 9007199254740992.0 < r
            if i % 20 == 0:
                marks.append(c)
        arms.append(marks)
    return [zstat(a, b, 20 * (j + 1)) for j, (a, b) in enumerate(zip(*arms))]

def rate(k): return k / R, sqrt(k / R * (1 - k / R) / R)
hist = {"null": [0] * 10, "drug works": [0] * 10}
far = rej0 = peek = rej1 = 0
for _ in range(R):
    zs = trial(rbar, rbar)
    far += abs(zs[-1]) >= z0 - 1e-12
    rej0 += abs(zs[-1]) >= zc
    peek += any(abs(z) >= zc for z in zs)
    hist["null"][min(9, int(10 * 2 * (1 - Phi(abs(zs[-1])))))] += 1
for _ in range(R):
    z = trial(0.45, 0.35)[-1]
    rej1 += abs(z) >= zc
    hist["drug works"][min(9, int(10 * 2 * (1 - Phi(abs(z)))))] += 1
(q4, e4), (q0, e0), (qp, ep), (q1, e1) = rate(far), rate(rej0), rate(peek), rate(rej1)
print(f"road 4, {R} null trials, seed {SEED}: share with |z| >= {z0:.4f} is {q4:.4f} +/- {e4:.4f}")
print(f"  rejected at 0.05 when the drug does nothing: {q0:.4f} +/- {e0:.4f}")
print(f"  rejected at 0.05 when it lifts 0.35 to 0.45: {q1:.4f} +/- {e1:.4f}")
print(f"  peeking after 20, 40, 60, 80, 100 per arm, stop at first |z| >= cutoff: {qp:.4f} +/- {ep:.4f}")
for k, v in hist.items():
    print(f"p-value histogram, {k}, percent per bin of width 0.1: " + ", ".join(f"{100 * c / R:.2f}" for c in v))

w = [1.0]                                    # permutation (Fisher) law of drug-arm recoveries, 80 in all
for x in range(80):
    w.append(w[-1] * (80 - x) * (100 - x) / ((x + 1) * (21 + x)))
fisher = sum(w[x] for x in range(81) if abs(x - 40) >= 5) / sum(w)
seu = sqrt(A / N * (1 - A / N) / N + B / N * (1 - B / N) / N)
print(f"permutation test (Fisher), same data: p = {fisher:.4f}")
print(f"95% interval for the gap, standard error from each arm's own rate {seu:.6f}: {(A - B) / N:.2f} +/- {zc * seu:.4f} = [{(A - B) / N - zc * seu:.4f}, {(A - B) / N + zc * seu:.4f}]")
print(f"ten times the patients, 450/1000 vs 350/1000: z = {zstat(450, 350, 1000):.4f}, p = {2 * (1 - Phi(zstat(450, 350, 1000))):.7f}")
print(f"tiny gap, 7200/20000 vs 7000/20000: z = {zstat(7200, 7000, 20000):.4f}, p = {2 * (1 - Phi(zstat(7200, 7000, 20000))):.4f}")
for share in (0.5, 0.1):                     # of drugs tested, the share that truly work
    ex = (1 - share) * size / ((1 - share) * size + share * power)
    sm = (1 - share) * q0 / ((1 - share) * q0 + share * q1)
    print(f"if {share:.1f} of drugs work: rejections that are false alarms, exact {ex:.4f}, simulated {sm:.4f}")

S, BASE = 40.0, 190.0                        # figure: x in bell units -> 180 + 40 x, y -> 190 - 360 f
pt = lambda u: f"{180 + S * u:.1f},{BASE - 360 * bell(u):.1f}"
print("figure, bell: " + " ".join(pt(-3.5 + 0.25 * i) for i in range(29)))
tail = [z0] + [1.5 + 0.25 * i for i in range(9)]
print("figure, right tail: " + " ".join(pt(u) for u in tail) + f" {180 + S * 3.5:.1f},{BASE:.1f} {180 + S * z0:.1f},{BASE:.1f}")
print("figure, left tail: " + " ".join(pt(-u) for u in tail) + f" {180 - S * 3.5:.1f},{BASE:.1f} {180 - S * z0:.1f},{BASE:.1f}")

assert abs(p1 - p2) < 1e-9                   # series and integral: two roads to the bell's tail
assert abs(p3 - p1) < 0.005                  # exact enumeration agrees with the bell to half a point
assert abs(q4 - p3) < 4 * e4                 # simulation agrees with enumeration
assert abs(q0 - size) < 4 * e0 and abs(q1 - power) < 4 * e1
assert qp - size > 4 * ep                    # peeking breaks the 5 percent promise
print("ALL CHECKS PASS")
