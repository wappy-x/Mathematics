# Stochastic gradient and sample average approximation -- the check behind the card.
# Standard library only.  An online grocer with 200,000 customers (synthetic, from
# SplitMix64 seed 2026) picks one delivery fee p.  Customer i books b_i (m_i - p)
# deliveries a month; each costs the grocer c = £1.  The card MINIMISES the average
# loss f(p) = minus the average monthly profit per customer, in pounds.
import math
M64 = (1 << 64) - 1
class Rng:                                   # SplitMix64, written out so Rust can match it
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unif(self): return (self.next() >> 11) * 2.0 ** -53
    def pick(self, n): return self.next() % n

N, C, P0, MU, L = 200_000, 1.0, 2.0, 0.8, 3.2      # every b_i lies in [0.4, 1.6]: curvature 2 b_i in [MU, L]
rng = Rng(2026)
B, M = [], []
for _ in range(N):
    B.append(0.4 + 1.2 * rng.unif()); M.append(4.0 + 6.0 * rng.unif())
def F(p, i): return -(p - C) * B[i] * (M[i] - p)   # one customer's loss, £ a month
def g(p, i): return B[i] * (2.0 * p - M[i] - C)    # its slope in p
def f(p):
    s = 0.0
    for i in range(N): s += F(p, i)
    return s / N
def mean(xs):
    s = 0.0
    for x in xs: s += x
    return s / len(xs)

# ---- the whole-population answer, two roads and a certificate ----
B1 = mean(B)
BMC = mean([b * (m + C) for b, m in zip(B, M)])
pstar = BMC / (2.0 * B1)                                          # road 1: f'(p) = 0, solved
f3, f4, f5 = f(3.0), f(4.0), f(5.0)
curv = f5 - 2.0 * f4 + f3                                         # f'' from three loss values, h = 1
pvert = 4.0 - (f5 - f3) / (2.0 * curv)                            # road 2: vertex of the parabola
fstar = f(pstar)
slope = (f(pstar + 1e-3) - f(pstar - 1e-3)) / 2e-3
print(f"customers {N}; mean b {B1:.5f}; mean b(m+c) {BMC:.5f}; best fee p* = £{pstar:.4f}; parabola vertex £{pvert:.4f}")
print(f"profit a customer a month: at £{P0:.2f} £{-f(P0):.4f}; at p* £{-fstar:.4f}; whole base £{-fstar * N:.0f}")
print(f"certificate: f'(p*) = {slope:.6f}, f'' = {curv:.4f} > 0, so p* is the global minimum")
assert abs(pstar - pvert) < 1e-6 and abs(slope) < 1e-6 and abs(curv - 2.0 * B1) < 1e-6
assert abs(mean([g(P0, i) for i in range(N)]) - (f(P0 + 1e-3) - f(P0 - 1e-3)) / 2e-3) < 1e-6   # g really is F's slope

Z = [g(pstar, i) for i in range(N)]                # each customer's slope at p*: pure noise
Z1, Z2 = mean(Z), mean([z * z for z in Z])
B2, BZ = mean([b * b for b in B]), mean([b * z for b, z in zip(B, Z)])
print(f"noise at p*: sigma^2 = {Z2:.4f}; mu = {MU:.1f}, L = {L:.1f}, f'' = {curv:.4f}")
assert abs(Z1) < 1e-9

# ---- stochastic gradient: one customer per step ----
RULES = [("Robbins-Monro 0.5/(k+1)", lambda k: 0.5 / (k + 1)), ("constant 0.02", lambda k: 0.02),
         ("timid 0.05/(k+1)", lambda k: 0.05 / (k + 1)), ("summable 0.25/(k+1)^2", lambda k: 0.25 / (k + 1) ** 2),
         ("root 0.5/sqrt(k+1)", lambda k: 0.5 / math.sqrt(k + 1))]
MARKS = [0, 1, 10, 100, 1000, 10000]
def exact(step):                                   # road 2: exact mean and mean square of e_k = p_k - p*
    m1, m2, out = P0 - pstar, (P0 - pstar) ** 2, {}
    for k in range(MARKS[-1] + 1):
        if k in MARKS: out[k] = (m1, m2)
        a = step(k)
        m1, m2 = ((1 - 2 * a * B1) * m1 - a * Z1,
                  (1 - 4 * a * B1 + 4 * a * a * B2) * m2 - 2 * a * (Z1 - 2 * a * BZ) * m1 + a * a * Z2)
    return out
def sgd(step, K, r):
    p, out = P0, {}
    for k in range(K + 1):
        if k in MARKS: out[k] = p
        if k < K: p -= step(k) * g(p, r.pick(N))
    return out
EX = [exact(s) for _, s in RULES]
run = sgd(RULES[0][1], 10000, Rng(7))
i0 = Rng(7).pick(N)
assert abs(run[1] - (P0 - RULES[0][1](0) * g(P0, i0))) < 1e-12        # the loop's first step, by hand
print(f"first customer drawn: b {B[i0]:.5f}, m £{M[i0]:.5f}, slope at £2 {g(P0, i0):.4f}, p_1 = 2 - 0.5 x slope = £{P0 - 0.5 * g(P0, i0):.4f}")
print("one run, Robbins-Monro steps, fee p_k at k =", " ".join(f"{k}:£{run[k]:.4f}" for k in MARKS))
print("exact root-mean-square error |p_k - p*| in £, and its split at k = 10000:")
for (name, _), ex in zip(RULES, EX):
    m1, m2 = ex[10000]
    print(f"  {name:24}" + " ".join(f"{math.sqrt(ex[k][1]):.4f}" for k in MARKS),
          f"| mean {m1:+.4f}, start part {m1 * m1:.6f} noise part {m2 - m1 * m1:.6f}")
print("chart, log10 RMS error:", "; ".join(" ".join(f"{math.log10(math.sqrt(ex[k][1])):.2f}" for k in MARKS) for ex in EX[:3]))
R, rs = 200, Rng(11)
sq = {k: [] for k in MARKS[2:]}
for _ in range(R):
    o = sgd(RULES[0][1], 10000, rs)
    for k in sq: sq[k].append((o[k] - pstar) ** 2)
for k in sq:
    mc, se = mean(sq[k]), math.sqrt((mean([x * x for x in sq[k]]) - mean(sq[k]) ** 2) / R)
    print(f"  k = {k:5}: simulated RMS £{math.sqrt(mc):.4f}, exact £{math.sqrt(EX[0][k][1]):.4f}, gap {(mc - EX[0][k][1]) / se:+.2f} se")
    assert abs(mc - EX[0][k][1]) < 4 * se
print(f"  sigma/(f'' sqrt k) at k = 10000: £{math.sqrt(Z2 / (curv * curv * 1e4)):.4f}")
assert abs(EX[0][10000][1] / (Z2 / (curv * curv * 1e4)) - 1) < 0.02     # the 1/k law at step 1/f''
assert EX[1][10000][1] > 50 * EX[0][10000][1] and abs(EX[3][10000][0]) > 0.5 and abs(EX[2][10000][0]) > 0.5
fl = RULES[4][1](10000) * Z2 / (2.0 * curv)                     # floor where pull and kick balance
print(f"root steps, squares not summable: RMS £{math.sqrt(EX[4][10000][1]):.4f} at k = 10000; floor alpha_k sigma^2/(2f'') gives £{math.sqrt(fl):.4f}")
assert abs(EX[4][10000][1] / fl - 1) < 0.02 and EX[4][10000][1] < EX[4][1000][1] / 3
lg = 4 + math.log10(abs(EX[2][10000][0]) / 0.01) / (0.1 * B1)      # mean error shrinks like k^(-0.1 f''/2)
print(f"timid steps: 2af'' = {0.1 * curv:.2f}; mean error still £{abs(EX[2][10000][0]):.4f}; reaching £0.01 takes about 10^{lg:.1f} steps")
print(f"summable steps 0.25/(k+1)^2 add up to {0.25 * math.pi ** 2 / 6:.3f} in all")
p, k, i = P0, 0, 0
while k < 10000:                                   # customers read in file order, keen ones (m > 7) only
    if M[i] > 7.0: p -= RULES[0][1](k) * g(p, i); k += 1
    i += 1
print(f"biased stream, 10000 keen customers in file order: fee ends at £{p:.4f}")
assert p - pstar > 0.5

# ---- sample average approximation: solve exactly on a sample of n customers ----
print("SAA: RMS error of the sample's best fee, against the bound sigma/(mu sqrt n)")
for n in (100, 1000, 10000):
    e2, opt, rs = [], [], Rng(100 + n)
    for _ in range(R):
        sb = sbmc = 0.0
        for _ in range(n):
            i = rs.pick(N); sb += B[i]; sbmc += B[i] * (M[i] + C)
        ph = sbmc / (2.0 * sb)
        e2.append((ph - pstar) ** 2); opt.append(sb / n * (ph - pstar) ** 2)
    mc, se = mean(e2), math.sqrt((mean([x * x for x in e2]) - mean(e2) ** 2) / R)
    bound, asym = Z2 / (MU * MU * n), Z2 / (curv * curv * n)
    print(f"  n = {n:5}: simulated RMS £{math.sqrt(mc):.4f}, asymptotic £{math.sqrt(asym):.4f}, bound £{math.sqrt(bound):.4f} ({bound:.6f});"
          f" claimed profit too high by {100 * mean(opt):.3f}p, real profit short by {100 * B1 * mc:.3f}p")
    assert mc + 4 * se < bound and abs(mc - asym) < 4 * se + 0.1 * asym
need_mu = math.ceil(Z2 / (MU * MU * 0.1 ** 2 * 0.05)); need_f = math.ceil(Z2 / (curv * curv * 0.1 ** 2 * 0.05))
print(f"customers to sample for |p_hat - p*| < £0.10 with 95%: {need_mu} from mu, {need_f} from f''")
print(f"the 200,000 themselves, as a sample of future customers: RMS £{math.sqrt(Z2 / (curv * curv * N)):.4f}")
print("ALL CHECKS PASS")
