# Heavy tails -- the check behind the card.  Nothing is imported but math primitives.
# Fortunes of at least $1 million (units: $ millions) follow Pareto with b = 1, a = 1.5.
# Roads: closed forms; Simpson integration in log-space; a bell curve built from its own
# series; and seeded draws (SplitMix64, seed 2026) that never use the closed forms.
from math import exp, log, sqrt, pi, cos, atan
A, B, M64 = 1.5, 1.0, (1 << 64) - 1

def simpson(g, lo, hi, n):
    w = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4.0 if j % 2 else 2.0) * g(lo + j * w) for j in range(1, n))
    return s * w / 3.0

def phi(z):                            # standard normal density
    return exp(-z * z / 2) / sqrt(2 * pi)

def Phi(z):                            # standard normal area left of z, by its Taylor series
    term, s, n = z, z, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -z * z / 2 / n
        s += term / (2 * n + 1)
    return 0.5 + s / sqrt(2 * pi)

def Phi_inv(u):                        # bisection on Phi
    lo, hi = -8.0, 8.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if Phi(mid) < u else (lo, mid)
    return (lo + hi) / 2

class SplitMix64:
    def __init__(self, seed):
        self.s = seed
    def uniform(self):                 # strictly inside (0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0

def frac_se(hits, n):
    p = hits / n
    return p, sqrt(p * (1 - p) / n)

def pareto_q(u):                       # quantile: the fortune below which a share u sits
    return B * (1 - u) ** (-1 / A)

mean, share = A * B / (A - 1), 0.01 ** (1 - 1 / A)
print(f"Pareto b = {B}, a = {A}: mean {mean:.4f}; median {pareto_q(0.5):.4f}; P(X > 10) = {10 ** -A:.5f}")
print(f"top 1 percent start at {pareto_q(0.99):.4f} and hold {share:.4f} of all wealth")
print(f"mean fortune above 10 = {A * 10 / (A - 1):.4f}; variance formula at a = 1.5 gives {A * B * B / ((A - 1) ** 2 * (A - 2)):.4f}")
T = 50.0                               # log-space: x = e^t, t from ln(lower) to 50
area = simpson(lambda t: A * exp(-A * t), 0.0, T, 20000)
top = simpson(lambda t: A * exp((1 - A) * t), log(pareto_q(0.99)), T, 20000) / mean
print(f"Simpson: total area {area:.9f}; top 1 percent share {top:.9f}")
gaps = []                              # Simpson minus closed form, for the asserts
for R in (10, 100, 10 ** 4, 10 ** 6):
    m1 = simpson(lambda t: A * exp((1 - A) * t), 0.0, log(R), 4000)
    m2 = simpson(lambda t: A * exp((2 - A) * t), 0.0, log(R), 4000)
    c1, c2 = A / (A - 1) * (1 - R ** (1 - A)), A / (2 - A) * (R ** (2 - A) - 1)
    gaps += [m1 - c1, m2 - c2]
    print(f"cutoff R = {R:>7}: partial mean {m1:.4f} (closed {c1:.4f}); partial E[X^2] {m2:.4f} (closed {c2:.4f})")
z75, z99 = Phi_inv(0.75), Phi_inv(0.99)
sig = (pareto_q(0.75) - pareto_q(0.25)) / (2 * z75)          # bell: same mean, same middle half
nshare = (0.01 * mean + sig * phi(z99)) / mean
nshare_s = simpson(lambda x: x * phi((x - mean) / sig) / sig, mean + z99 * sig, mean + 40 * sig, 20000) / mean
def bell_tail(x):                      # chance the bell exceeds x, by Simpson on its density
    return simpson(phi, (x - mean) / sig, 40.0, 20000)
ntail = bell_tail(10)
print(f"bell curve: mean {mean:.4f}, sd {sig:.4f}; top 1 percent start at {mean + z99 * sig:.4f}, hold {nshare:.4f} (Simpson {nshare_s:.4f})")
print(f"bell curve: P(X > 10) = {ntail:.3e}; P(X < 0) = {Phi(-mean / sig):.5f}")
cm = 4 * simpson(lambda z: 1 / (pi * (1 + z * z)), 0.0, 1.0, 2000)   # w = 1/z folds the tail onto [0, 1]
print(f"Cauchy: total area by folding {cm:.9f}; P(-1 < Z < 1) = {2 * simpson(lambda z: 1 / (pi * (1 + z * z)), 0.0, 1.0, 2000):.6f}")
for R in (10, 100, 1000):
    half = simpson(lambda t: exp(2 * t) / (pi * (1 + exp(2 * t))), -30.0, log(R), 20000)
    gaps.append(half - log(1 + R * R) / (2 * pi))
    print(f"Cauchy: integral of z g(z) from 0 to {R:>4} = {half:.4f} (closed {log(1 + R * R) / (2 * pi):.4f})")
half_m = 2 * simpson(lambda t: exp(1.5 * t) / (pi * (1 + exp(2 * t))), -60.0, 60.0, 20000)
print(f"Cauchy: E|Z|^0.5 by Simpson {half_m:.6f}; closed form 1/cos(pi/4) = {1 / cos(pi / 4):.6f}")
print(f"Cauchy: cutoffs -R and 2R give {log(4) / (2 * pi):.4f} in the limit, not 0; P(|Z| > 10) = {1 - 2 * atan(10) / pi:.4f}")

rng = SplitMix64(2026)
xs, cks, run = [], [], 0.0
for i in range(1, 10 ** 6 + 1):
    x = B * rng.uniform() ** (-1 / A)                         # inverse transform
    xs.append(x); run += x
    if i in (10, 100, 10 ** 3, 10 ** 4, 10 ** 5, 10 ** 6):
        sd = sqrt(sum((v - run / i) ** 2 for v in xs) / (i - 1))
        cks.append((i, run / i, sd))
for i, m, sd in cks:
    print(f"simulated fortunes n = {i:>7}: average {m:.4f}; sample sd {sd:.4f}")
p10, se10 = frac_se(sum(x > 10 for x in xs), len(xs))
print(f"simulated: P(X > 10) = {p10:.5f} (se {se10:.5f}); largest fortune {max(xs):.1f}")
shares = []
for k in range(10):                                           # 10 batches of 100,000
    s = sorted(xs[k * 100000:(k + 1) * 100000], reverse=True)
    shares.append(sum(s[:1000]) / sum(s))
sm = sum(shares) / 10
sse = sqrt(sum((v - sm) ** 2 for v in shares) / 9 / 10)
print(f"simulated: top 1 percent share {sm:.4f} (se {sse:.4f}, from 10 batches of 100000)")
ret, ratio = [], []
for _ in range(10 ** 5):                                      # two daily returns, 1.2 percent spread
    u1, u2, u3, u4 = (rng.uniform() for _ in range(4))
    r1 = 1.2 * sqrt(-2 * log(u1)) * cos(2 * pi * u2)
    r2 = 1.2 * sqrt(-2 * log(u3)) * cos(2 * pi * u4)
    ret.append(r1); ratio.append(r1 / r2)
pin, sein = frac_se(sum(abs(z) < 1 for z in ratio), len(ratio))
pout, seout = frac_se(sum(abs(z) > 10 for z in ratio), len(ratio))
print(f"ratio of two returns: P(-1 < Z < 1) = {pin:.4f} (se {sein:.4f}); P(|Z| > 10) = {pout:.4f} (se {seout:.4f})")
for n in (10, 100, 10 ** 3, 10 ** 4, 10 ** 5):
    print(f"ratio of two returns, running average n = {n:>6}: {sum(ratio[:n]) / n:.4f}")
cav = [sum(ratio[j:j + 100]) / 100 for j in range(0, 10 ** 5, 100)]
rav = [sum(ret[j:j + 100]) / 100 for j in range(0, 10 ** 5, 100)]
pc, sec = frac_se(sum(abs(v) < 1 for v in cav), 1000)
pr, _ = frac_se(sum(abs(v) < 1.2 for v in rav), 1000)
print("figure, ratio averages: " + ", ".join(f"{sum(ratio[:n]) / n:.2f}" for n in (10, 100, 10 ** 3, 10 ** 4, 10 ** 5)))
print("figure, return averages: " + ", ".join(f"{sum(ret[:n]) / n:.2f}" for n in (10, 100, 10 ** 3, 10 ** 4, 10 ** 5)))
print(f"1000 averages of 100 ratios: P(-1 < avg < 1) = {pc:.4f} (se {sec:.4f}); of 100 returns within 1.2: {pr:.4f}")
grid = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
print("figure, $ millions:  " + ", ".join(str(x) for x in grid))
print("figure, Pareto %:    " + ", ".join(f"{100 * x ** -A:.2f}" for x in grid))
print("figure, bell %:      " + ", ".join(f"{100 * bell_tail(x):.2f}" for x in grid))
print("figure, simulated %: " + ", ".join(f"{100 * sum(v > x for v in xs[:100000]) / 100000:.2f}" for x in grid))
assert abs(area - 1) < 1e-8 and abs(top - share) < 1e-8          # integration vs algebra
assert max(abs(g) for g in gaps) < 1e-6                         # partial moments vs closed forms
assert abs(cm - 1) < 1e-9 and abs(half_m - sqrt(2)) < 1e-6 and abs(nshare_s - nshare) < 1e-6
assert abs(p10 - 10 ** -A) < 4 * se10 and abs(sm - share) < 4 * sse   # simulation vs formula
assert abs(pin - 0.5) < 4 * sein and abs(pout - (1 - 2 * atan(10) / pi)) < 4 * seout
assert abs(pc - 0.5) < 4 * sec and pr > 0.99                    # Cauchy averages never tighten
print("ALL CHECKS PASS")
