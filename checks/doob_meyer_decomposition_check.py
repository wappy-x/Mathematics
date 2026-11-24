# Doob-Meyer -- the check behind the card.  Standard library only.
# House example: M_t = integral of W against W = (W_t^2 - t)/2, W a Brownian motion.
# Its bracket <M>_t = integral of W_s^2 ds, so E[M_1^2] = E<M>_1 = 1/2.
# Calls at 4 an hour: N_t - 4t is a martingale whose bracket is 4t.
# Road 1: the formulas, with the normal's moments by Simpson's rule.
# Road 2: Doob's recipe run exactly on a coin-toss tree, in whole numbers.
# Road 3: seeded simulation (SplitMix64 and Box-Muller, written out).
import math

MASK = (1 << 64) - 1

class Rng:
    def __init__(self, seed): self.s = seed
    def u(self):  # uniform on [0, 1), 53 bits
        z = self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):  # Box-Muller, cosine branch
        a, b = 1.0 - self.u(), self.u()
        return math.sqrt(-2.0 * math.log(a)) * math.cos(2.0 * math.pi * b)

def simpson(f, a, b, n=2000):
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

def mean_se(xs):
    s = q = 0.0
    for x in xs: s, q = s + x, q + x * x
    m = s / len(xs)
    return m, math.sqrt((q - len(xs) * m * m) / (len(xs) - 1) / len(xs))

# ---- road 1: formulas ----
phi = lambda z: math.exp(-z * z / 2) / math.sqrt(2 * math.pi)
m2, m4 = simpson(lambda z: z**2 * phi(z), -12, 12), simpson(lambda z: z**4 * phi(z), -12, 12)
print(f"road 1: E[W_1^2] = {m2:.6f}, E[W_1^4] = {m4:.6f} (Simpson)")
for t in (1.0, 2.0):
    em2 = (m4 * t * t - 2 * t * m2 * t + t * t) / 4    # E[(W_t^2 - t)^2]/4
    ea = simpson(lambda s: m2 * s, 0, t)                # E int_0^t W_s^2 ds
    print(f"t = {t:.0f}: E[M_t^2] = {em2:.6f}, E<M>_t = {ea:.6f}")
    assert abs(em2 - t * t / 2) < 1e-9 and abs(ea - em2) < 1e-9

# ---- road 2: Doob's recipe on a coin-toss tree, n steps of size 1/sqrt(n) ----
# Walk S (sum of +-1), W = S/sqrt(n), M = (S^2 - k)/(2n); work with 4n^2 M^2 = (S^2-k)^2.
def tree(n):
    z = lambda k, s: (s * s - k) ** 2
    bad = 0
    for k in range(n):
        for s in range(-k, k + 1, 2):
            recipe = z(k + 1, s + 1) + z(k + 1, s - 1) - 2 * z(k, s)  # 2 x 4n^2 x trend step
            dm = (s + 1) ** 2 - (k + 1) - (s * s - k)                  # 2n x step of M
            bad += recipe != 8 * s * s or dm * dm != 4 * s * s         # trend = (dM)^2 = W^2 dt
    c, ez = 1, 0
    for j in range(n + 1):
        ez += c * z(n, 2 * j - n)
        c = c * (n - j) // (j + 1)
    ea = 0
    for k in range(n):
        c, sk = 1, 0
        for j in range(k + 1):
            sk += c * (2 * j - k) ** 2
            c = c * (k - j) // (j + 1)
        ea += sk * 2 ** (n - k) * 4                                    # E[S_k^2]/n^2, scaled
    den = 2**n * 4 * n * n
    g, h = math.gcd(ez, den), math.gcd(ea, den)
    return n * (n + 1) // 2, bad, (ez // g, den // g), (ea // h, den // h)

for n in (10, 100):
    nodes, bad, ez, ea = tree(n)
    print(f"tree, {n} steps: recipe = W^2 dt = (dM)^2 at {nodes - bad} of {nodes} nodes")
    print(f"  E[M^2] = {ez[0]}/{ez[1]} = {ez[0] / ez[1]:.6f}, E[A] = {ea[0]}/{ea[1]}")
    assert bad == 0 and ez == ea and ez[0] * 2 * n == ez[1] * (n - 1)

# ---- road 3: Brownian paths ----
rng, P, n, cols = Rng(20261123), 4000, 200, [[] for _ in range(5)]
dt, sq = 1.0 / n, math.sqrt(1.0 / n)
for _ in range(P):
    w = a = q = qw = iw = mprev = 0.0
    for k in range(n):
        dw = sq * rng.normal()
        a += (w * w + (w + dw) ** 2) / 2 * dt   # trapezoid for int W^2 ds
        iw += (w + w + dw) / 2 * dt             # int W ds, the unsquared mistake
        w, qw = w + dw, qw + dw * dw
        m = (w * w - (k + 1) * dt) / 2
        q, mprev = q + (m - mprev) ** 2, m
    for c, v in zip(cols, (mprev * mprev, a, q, iw, qw)): c.append(v)
names = ["E[M_1^2]", "E<M>_1 = E int W^2 ds", "E[sum (dM)^2]", "mistake E int W ds", "mistake E[W]_1"]
for name, c, want in zip(names, cols, (0.5, 0.5, 0.5, 0.0, 1.0)):
    m, se = mean_se(c)
    print(f"sim {P} paths x {n} steps: {name} = {m:.4f} +- {se:.4f}")
    assert abs(m - want) < 4 * se

# one path, fine grid: the squared steps of M settle on int W^2 ds
fine, rng, ws = 20480, Rng(7), [0.0]
for _ in range(fine):
    ws.append(ws[-1] + math.sqrt(1.0 / fine) * rng.normal())
ms = [(w * w - i / fine) / 2 for i, w in enumerate(ws)]
br = [0.0]
for i in range(fine):
    br.append(br[-1] + (ws[i] ** 2 + ws[i + 1] ** 2) / 2 / fine)
print(f"one path: W_1 = {ws[-1]:.4f}, M_1 = {ms[-1]:.4f}, <M>_1 = int W^2 ds = {br[-1]:.4f}")
for steps in (20, 320, 5120, 20480):
    j, qv = fine // steps, 0.0
    for i in range(steps): qv += (ms[(i + 1) * j] - ms[i * j]) ** 2
    print(f"  sum of squared steps of M, {steps:5d} steps: {qv:.4f}")
assert abs(qv - br[-1]) < 0.05
print("chart M^2:", ", ".join(f"{ms[i * 1024] ** 2:.3f}" for i in range(21)))
print("chart <M>:", ", ".join(f"{br[i * 1024]:.3f}" for i in range(21)))

# ---- calls at 4 an hour ----
lam = 4.0
p, e2c, e2, p4 = math.exp(-lam), 0.0, 0.0, 0.0
for k in range(100):
    e2c, e2, p4 = e2c + p * (k - lam) ** 2, e2 + p * k * k, p if k == 4 else p4
    p = p * lam / (k + 1)
print(f"Poisson sums: E[(N_1-4)^2] = {e2c:.6f}, E[N_1^2] = {e2:.6f}, P(N_1 = 4) = {p4:.6f}")
assert abs(e2c - lam) < 1e-12 and abs(e2 - lam - lam * lam) < 1e-12
for slots in (60, 3600):
    pp = lam / slots
    for m in (-3.5, 0.0, 2.25):  # recipe one slot ahead, from the two outcomes
        step = pp * (m + 1 - pp) ** 2 + (1 - pp) * (m - pp) ** 2 - m * m
        assert abs(step - pp * (1 - pp)) < 1e-12
    print(f"{slots} slots an hour: trend of (N - 4t)^2 over the hour = {slots * step:.6f}")
rng, H = Rng(20261124), 20000
counts = []
for _ in range(H):
    t, c = -math.log(1.0 - rng.u()) / lam, 0
    while t <= 1.0: c, t = c + 1, t - math.log(1.0 - rng.u()) / lam
    counts.append(c)
print(f"hour 1 of the simulation: N_1 = {counts[0]}, so [M]_1 = {counts[0]}; <M>_1 = 4")
for name, xs, want in (("E[N_1]", counts, lam), ("E[(N_1-4)^2] = E<M>_1", [(c - lam) ** 2 for c in counts], lam),
                       ("P(N_1 = 4)", [1.0 if c == 4 else 0.0 for c in counts], p4),
                       ("mistake E[N_1^2]", [c * c * 1.0 for c in counts], e2)):
    m, se = mean_se(xs)
    print(f"sim {H} hours: {name} = {m:.4f} +- {se:.4f}")
    assert abs(m - want) < 4 * se
print(f"8-hour shift: <M>_8 = {8 * lam:.0f}, spread sqrt(32) = {math.sqrt(8 * lam):.6f} calls")
print("ALL CHECKS PASS")
