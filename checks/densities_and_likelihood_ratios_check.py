# Densities and likelihood ratios -- the check behind the card.
# Standard library only: math for exp, log and sqrt.  Bus waits in minutes:
# model P says buses come at rate 1 a minute (density e^-x), model Q says
# rate 2 (density 2 e^-2x).  Then the fair die is tilted by e^(theta x face)
# until its mean is 4.4, and set beside the loaded die with the same mean.
import math

def p(x): return math.exp(-x)                  # density of P against length
def q(x): return 2.0 * math.exp(-2.0 * x)      # density of Q against length
def lr(x): return 2.0 * math.exp(-x)           # the claimed dQ/dP, 2 e^-x
def cdf(x): return 1.0 - math.exp(-x)          # P(wait <= x)

def simpson(g, a, b, n=20000):                 # composite Simpson's rule, n even
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

class SplitMix64:                              # the same generator in both checks
    def __init__(self, seed): self.s = seed
    def uniform(self):                         # in (0, 1], never 0, so log is safe
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        z ^= z >> 31
        return ((z >> 11) + 1) / 9007199254740992.0

def mean_se(xs):                               # sample mean and its standard error
    n = len(xs); m = sum(xs) / n
    return m, math.sqrt(sum((x - m) * (x - m) for x in xs) / (n - 1) / n)

# ---- road 1: the density is the slope of the distribution function ----
for x in (0.5, 1.0, 2.0):
    h = 1e-4
    print(f"density at {x}: slope of F {(cdf(x + h) - cdf(x - h)) / (2 * h):.6f}, formula e^-x {p(x):.6f}")
slope_err = max(abs((cdf(x + 1e-4) - cdf(x - 1e-4)) / 2e-4 - p(x)) for x in (0.5, 1.0, 2.0))
print(f"P(wait <= 1): area under the density {simpson(p, 0, 1):.6f}, F(1) {cdf(1):.6f}")

# ---- the two densities and their ratio, the points of the chart ----
xs = [0.5 * i for i in range(7)]
print("chart x:", ", ".join(f"{x:.1f}" for x in xs))
print("chart p:", ", ".join(f"{p(x):.2f}" for x in xs))
print("chart q:", ", ".join(f"{q(x):.2f}" for x in xs))
print("chart L:", ", ".join(f"{lr(x):.2f}" for x in xs))
print(f"L at 0.3 = {lr(0.3):.4f}; L at 2 = {lr(2):.4f}; L = 1 at x = ln 2 = {math.log(2):.4f}")

# ---- road 2: Q(wait > 1) three ways ----
exact = math.exp(-2)
by_integral = simpson(lambda x: lr(x) * p(x), 1, 41)
rng = SplitMix64(20260929)
draws = [-math.log(rng.uniform()) for _ in range(200000)]      # waits drawn from P
tail_mc, tail_se = mean_se([lr(x) if x > 1 else 0.0 for x in draws])
mass_mc, mass_se = mean_se([lr(x) for x in draws])
print(f"Q(wait > 1): closed form e^-2 {exact:.6f}; integral of L dP {by_integral:.6f}")
print(f"  reweighted P-draws, n = 200000: {tail_mc:.6f} (standard error {tail_se:.6f})")
print(f"  plain P-probability of the same event {1 - cdf(1):.6f}")
print(f"P-average of L: integral {simpson(lambda x: lr(x) * p(x), 0, 40):.6f}; P-draws {mass_mc:.6f} (se {mass_se:.6f})")

# ---- road 3: Kullback-Leibler divergence three ways ----
kl_exact = math.log(2) - 0.5
kl_int = simpson(lambda x: q(x) * math.log(q(x) / p(x)), 0, 40)
qdraws = [-math.log(rng.uniform()) / 2 for _ in range(200000)]  # waits drawn from Q
kl_mc, kl_se = mean_se([math.log(lr(x)) for x in qdraws])
theta = -1.0                                                    # Q is P tilted by theta = -1
big_m = simpson(lambda x: math.exp(theta * x) * p(x), 0, 40)    # M(theta), integrated against P
m_tilt = simpson(lambda x: x * math.exp(theta * x) / big_m * p(x), 0, 40)   # the tilt's mean
kl_tilt = theta * m_tilt - math.log(big_m)
print(f"D(Q||P): ln 2 - 1/2 = {kl_exact:.6f}; integral {kl_int:.6f}; Q-draws {kl_mc:.6f} (se {kl_se:.6f})")
print(f"  as a tilt, theta = -1, M {big_m:.6f} and m {m_tilt:.6f} integrated against P: theta m - ln M {kl_tilt:.6f}")
kl_rev = simpson(lambda x: p(x) * math.log(p(x) / q(x)), 0, 40)
print(f"D(P||Q): 1 - ln 2 = {1 - math.log(2):.6f}; integral {kl_rev:.6f}")

# ---- road 4: tilt the fair die to mean 4.4, three root-finders ----
faces, target = [1, 2, 3, 4, 5, 6], 4.4
def moments(t):                                # M(theta), mean and variance of the tilt
    w = [math.exp(t * k) / 6 for k in faces]
    big = sum(w); mean = sum(k * x for k, x in zip(faces, w)) / big
    return big, mean, sum((k - mean) * (k - mean) * x for k, x in zip(faces, w)) / big
lo, hi = 0.0, 3.0
for _ in range(100):                           # bisection on mean(theta) = 4.4
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if moments(mid)[1] < target else (lo, mid)
th_bis = (lo + hi) / 2
th_new = 0.0
for i in range(5):                             # Newton: slope of the mean is the variance
    _, mean, var = moments(th_new)
    th_new -= (mean - target) / var
    print(f"Newton step {i + 1}: theta {th_new:.12f}")
a, b, g = 0.0, 3.0, (math.sqrt(5) - 1) / 2
obj = lambda t: math.log(moments(t)[0]) - target * t              # convex; its minimum is the tilt
for _ in range(80):                            # golden-section search, no derivatives
    c, d = b - g * (b - a), a + g * (b - a)
    a, b = (a, d) if obj(c) < obj(d) else (c, b)
th_gold = (a + b) / 2
big, mean, var = moments(th_bis)
tilt = [math.exp(th_bis * k) / 6 / big for k in faces]
print(f"theta: bisection {th_bis:.9f}; Newton {th_new:.9f}; golden section {th_gold:.7f}")
print(f"tilted die: M(theta) {big:.6f}, mean {mean:.6f}, variance {var:.6f}")
loaded = [0.1, 0.1, 0.1, 0.1, 0.2, 0.4]
print("tilted die weights:", ", ".join(f"{w:.4f}" for w in tilt))
print("chart fair:  ", ", ".join(f"{1 / 6:.2f}" for _ in faces))
print("chart tilted:", ", ".join(f"{w:.2f}" for w in tilt))
print("chart loaded:", ", ".join(f"{w:.2f}" for w in loaded))
print(f"dQ/dP for the tilt, e^(theta k)/M: {', '.join(f'{6 * w:.4f}' for w in tilt)}")
kl_t_sum = sum(w * math.log(6 * w) for w in tilt)
kl_t_formula = th_bis * target - math.log(big)
kl_l = sum(w * math.log(6 * w) for w in loaded)
kl_lt = sum(w * math.log(w / t) for w, t in zip(loaded, tilt))
print(f"D(tilt||fair): by the sum {kl_t_sum:.6f}; theta m - ln M {kl_t_formula:.6f}")
print(f"D(loaded||fair) {kl_l:.6f} = D(loaded||tilt) {kl_lt:.6f} + D(tilt||fair) {kl_t_sum:.6f}")

# ---- what breaks ----
for h in (0.1, 0.01, 0.001):                  # the die against length: no density
    print(f"die, P(face in [6 - h, 6 + h]) / length 2h, h = {h}: {(1 / 6) / (2 * h):.4f}")
pu = lambda x: 1.0 if x <= 1 else 0.0          # P uniform on [0, 1]
qu = lambda x: 0.5 if x <= 2 else 0.0          # Q uniform on [0, 2]: not << P
seen = simpson(lambda x: (qu(x) / pu(x) if pu(x) > 0 else 0.0) * pu(x), 0, 1)
unseen = simpson(qu, 1, 2)                     # Q's mass where p = 0
print(f"Q uniform on [0, 2], P on [0, 1]: integral of q/p dP {seen:.6f}; Q-mass where p = 0 {unseen:.6f}")
wrong = simpson(lambda x: p(x) * math.log(lr(x)), 0, 40)
print(f"log-ratio averaged under P instead of Q: {wrong:.6f}; Q's density at 0: {q(0):.4f}")

assert slope_err < 1e-7                                 # density = slope of F
assert abs(by_integral - exact) < 1e-9                  # integral of L dP = Q(A)
assert abs(tail_mc - exact) < 4 * tail_se               # reweighted draws land on it
assert abs(kl_int - kl_exact) < 1e-9                    # KL by integral vs closed form
assert abs(kl_mc - kl_int) < 4 * kl_se                  # KL by sampling from Q
assert abs(kl_tilt - kl_int) < 1e-9                     # KL by the tilt formula
assert abs(kl_rev - (1 - math.log(2))) < 1e-9           # the reverse divergence
assert abs(th_bis - th_new) < 1e-12                     # two root-finders agree
assert abs(th_gold - th_bis) < 1e-6                     # KL minimiser is the tilt
assert abs(kl_l - (kl_lt + kl_t_sum)) < 1e-12           # Pythagoras for the tilt
assert abs(kl_t_sum - kl_t_formula) < 1e-12             # tilt KL two ways
print("ALL CHECKS PASS")
