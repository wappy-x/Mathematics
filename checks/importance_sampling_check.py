# Importance sampling -- the check behind the card.  Nothing is imported but math primitives.
# A bolt jams when its diameter is more than c = 4.75 standard deviations above target: a chance of
# about one in a million.  Estimate it with 10,000 simulated bolts.  Roads: the exact tail by
# a continued fraction; the same tail by Simpson's rule; plain simulation; importance sampling
# from two proposals, drawn with SplitMix64 (seed 2026), Box-Muller and the inverse transform.
from math import exp, log, sqrt, pi, cos
C, N, M64 = 4.75, 10000, (1 << 64) - 1

class SplitMix64:
    def __init__(self, seed):
        self.s = seed
    def uniform(self):                                   # strictly inside (0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    def normal(self):                                    # Box-Muller, one draw from two uniforms
        u1, u2 = self.uniform(), self.uniform()
        return sqrt(-2 * log(u1)) * cos(2 * pi * u2)

def f(y):                                                # target: the standard bell curve
    return exp(-y * y / 2) / sqrt(2 * pi)

def tail_cf(x, terms=300):                               # P(X > x) by Laplace's continued fraction
    t = x
    for k in range(terms, 0, -1):
        t = x + k / t
    return f(x) / t

def simpson(g, lo, hi, n):
    w = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4.0 if j % 2 else 2.0) * g(lo + j * w) for j in range(1, n))
    return s * w / 3.0

def summary(vals):                                       # mean and its standard error
    m = sum(vals) / len(vals)
    return m, sqrt(sum((v - m) ** 2 for v in vals) / (len(vals) - 1) / len(vals))

def m2_shift(th):                                        # second moment, proposal N(th, 1), closed form
    return exp(th * th) * tail_cf(C + th)

def rel_se(m2, p, n):                                    # standard error as a share of the answer
    return sqrt(m2 - p * p) / (p * sqrt(n))

p = tail_cf(C)
p_simp = simpson(f, C, C + 30, 20000)
print(f"exact P(X > 4.75), continued fraction : {p * 1e6:.9f} per million")
print(f"exact P(X > 4.75), Simpson's rule     : {p_simp * 1e6:.9f} per million")
print(f"plain: expected hits in {N} draws {N * p:.4f}; P(no hits) = {(1 - p) ** N:.4f}; rel se {rel_se(p, p, N) * 100:.2f}%")
rng = SplitMix64(2026)
plain = [1.0 if rng.normal() > C else 0.0 for _ in range(N)]
print(f"plain run: {int(sum(plain))} hits, estimate {sum(plain) / N * 1e6:.6f} per million")

g_n = lambda y: f(y - C)                                 # proposal A: bell curve moved to the line
w_n = lambda y: exp(-C * y + C * C / 2)                  # weight f/g, simplified
ys = [C + rng.normal() for _ in range(N)]
wh = [w_n(y) if y > C else 0.0 for y in ys]
est_n, se_n = summary(wh)
hits_n = sum(y > C for y in ys)
m2_simp = simpson(lambda y: f(y) ** 2 / g_n(y), C, C + 30, 20000)
print(f"proposal N(4.75, 1): {hits_n} hits; estimate {est_n * 1e6:.6f} per million, se {se_n * 1e6:.6f}")
print(f"  weight at the line e^(-c^2/2) = {w_n(C) * 1e6:.4f} per million; at y = 5.75 {w_n(5.75) * 1e6:.4f} per million")
print(f"  second moment per 10^12: closed {m2_shift(C) * 1e12:.6f}, Simpson {m2_simp * 1e12:.6f}, sample {sum(v * v for v in wh) / N * 1e12:.6f}")
print(f"  by hand: c^2/2 = {C * C / 2:.5f}; c^2 = {C * C:.4f}; P(X > 9.5) = {tail_cf(9.5) * 1e21:.4f} per 10^21; I^2 = {p * p * 1e12:.6f} per 10^12")
print(f"  rel se: formula {rel_se(m2_shift(C), p, N) * 100:.2f}%, run {se_n / est_n * 100:.2f}%; run is {(est_n - p) / se_n:.2f} se from exact")
print(f"  plain draws for the same se: {p * (1 - p) / (m2_shift(C) - p * p) * N / 1e6:.0f} million")

lam = C                                                  # proposal B: exponential tail from the line
g_e = lambda y: lam * exp(-lam * (y - C))
ye = [C - log(rng.uniform()) / lam for _ in range(N)]    # inverse transform
we = [f(y) / g_e(y) for y in ye]
est_e, se_e = summary(we)
m2_e = simpson(lambda y: f(y) ** 2 / g_e(y), C, C + 30, 20000)
print(f"proposal exponential, rate 4.75: estimate {est_e * 1e6:.6f} per million, se {se_e * 1e6:.6f}")
print(f"  rel se: formula {rel_se(m2_e, p, N) * 100:.4f}%, run {se_e / est_e * 100:.4f}%; run is {(est_e - p) / se_e:.2f} se from exact")
print(f"  plain draws for the same se: {p * (1 - p) / (m2_e - p * p) * N / 1e9:.1f} billion")

a, b, gr = 3.0, 7.0, (sqrt(5) - 1) / 2                   # best shift by golden-section search
for _ in range(100):
    x1, x2 = b - gr * (b - a), a + gr * (b - a)
    a, b = (a, x2) if m2_shift(x1) < m2_shift(x2) else (x1, b)
th_best = (a + b) / 2
print(f"best shift {th_best:.4f}: rel se {rel_se(m2_shift(th_best), p, N) * 100:.2f}%; shift 0 (plain): {rel_se(m2_shift(0.0), p, N) * 100:.2f}%")
thetas = [3.0 + 0.5 * k for k in range(9)]
print("figure, shift:        " + ", ".join(f"{t:.1f}" for t in thetas))
print("figure, rel se %:     " + ", ".join(f"{rel_se(m2_shift(t), p, N) * 100:.2f}" for t in thetas))
grid = list(range(9))
print("figure, y:            " + ", ".join(str(y) for y in grid))
print("figure, target f:     " + ", ".join(f"{f(y):.2f}" for y in grid))
print("figure, proposal A:   " + ", ".join(f"{g_n(y):.2f}" for y in grid))
tail_grid = [C + 0.25 * k for k in range(7)]
print("figure, y in tail:    " + ", ".join(f"{y:.2f}" for y in tail_grid))
print("figure, ideal f/I:    " + ", ".join(f"{f(y) / p:.2f}" for y in tail_grid))
print("figure, proposal B:   " + ", ".join(f"{g_e(y):.2f}" for y in tail_grid))
print("figure, A in tail:    " + ", ".join(f"{g_n(y):.2f}" for y in tail_grid))

# what breaks
print(f"wrong: no weights, share of proposal draws past the line {hits_n / N:.4f}")
print(f"wrong: weight e^(-c y), dropping e^(c^2/2): estimate {est_n * exp(-C * C / 2) * 1e6:.8f} per million, {exp(C * C / 2):.0f} times too small")
print(f"wrong: proposal only up to 5.75 misses {tail_cf(5.75) / p * 100:.2f}% of the answer")
s = 0.5                                                  # proposal N(4.75, 0.25): tails too thin
w_t = lambda y: s * exp(-y * y / 2 + (y - C) ** 2 / (2 * s * s))       # f / g, simplified
m2_t = lambda y: s / sqrt(2 * pi) * exp(-y * y + (y - C) ** 2 / (2 * s * s))   # f * f / g
parts = [simpson(m2_t, C, R, 20000) for R in (10, 20, 25, 30)]
print("wrong: thin proposal sd 0.5, second moment to R = 10, 20, 25, 30: 10^" + ", 10^".join(f"{log(v) / log(10):.1f}" for v in parts))
yt = [C + s * rng.normal() for _ in range(N)]
est_t, se_t = summary([w_t(y) if y > C else 0.0 for y in yt])
print(f"wrong: thin proposal run: estimate {est_t * 1e6:.6f} per million, printed se {se_t * 1e6:.6f}")
print(f"try: line at c = 6, shift 6: rel se {rel_se(exp(36) * tail_cf(12.0), tail_cf(6.0), N) * 100:.2f}%; P(X > 6) = {tail_cf(6.0) * 1e9:.4f} per billion")
for lam2 in (3.0, 7.0):
    m2l = simpson(lambda y: f(y) ** 2 / (lam2 * exp(-lam2 * (y - C))), C, C + 30, 20000)
    print(f"try: exponential rate {lam2:.0f}: rel se {rel_se(m2l, p, N) * 100:.4f}%")

assert abs(p_simp / p - 1) < 1e-9                        # continued fraction vs integration
assert abs(m2_simp / m2_shift(C) - 1) < 1e-8             # completed square vs integration
assert abs(est_n - p) < 4 * se_n                        # simulation, proposal A, vs exact
assert abs(est_e - p) < 4 * se_e                        # simulation, proposal B, vs exact
assert abs(se_e / est_e / rel_se(m2_e, p, N) - 1) < 0.1  # run's error bar vs the variance formula
assert parts[3] > 1e6 * parts[1]                         # thin tails: the second moment explodes
print("ALL CHECKS PASS")
