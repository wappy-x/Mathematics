# Splitting and merging Poisson streams -- the check behind the card.
# Standard library math only.  A switchboard takes calls at 4 an hour; each
# call is routed to sales with chance 0.25, else to support.  Four roads to
# the joint law of the two desks: the formula; every label word enumerated;
# a grid of m slots an hour as m grows; a seeded simulation, with errors.
from math import exp, log, sqrt

LAM, P, H, SEED, NMAX, ROT = 4.0, 0.25, 200000, 20260930, 16, 4
M64 = (1 << 64) - 1

def fact(n):
    out = 1
    for i in range(2, n + 1):
        out *= i
    return out

def pois(k, mu):                         # Poisson probability of k when the mean is mu
    return exp(-mu) * mu ** k / fact(k)

class SplitMix64:                        # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed
    def uniform(self):                   # a number in [0, 1) with 53 random bits
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def wait(self, rate):                # an exponential waiting time, in hours
        return -log(1.0 - self.uniform()) / rate

def freq(hits, n):                       # a simulated share and its standard error
    f = hits / n
    return f, sqrt(f * (1 - f) / n)

l1, l2 = P * LAM, (1 - P) * LAM
print(f"setup: calls at {LAM:.0f} an hour; each call is sales with chance {P}, else support")
print(f"split rates: sales {l1:.1f} an hour, support {l2:.1f} an hour")
pt, words = pois(3, LAM), 3 * P * (1 - P) ** 2
print(f"worked, one hour: P(total 3) = {pt:.6f}; label words for 1 sales in 3 = {words:.6f}; product {pt * words:.6f}")
print(f"worked, one hour: P(sales 1) = {pois(1, l1):.6f}; P(support 2) = {pois(2, l2):.6f}; product {pois(1, l1) * pois(2, l2):.6f}")

# road two: every label word of every length n up to NMAX, weighted and binned
joint = [[0.0] * (NMAX + 1) for _ in range(NMAX + 1)]
for n in range(NMAX + 1):
    for mask in range(1 << n):
        a = bin(mask).count("1")
        joint[a][n - a] += pois(n, LAM) * P ** a * (1 - P) ** (n - a)
gap = max(abs(joint[a][b] - pois(a, l1) * pois(b, l2)) for a in range(NMAX + 1) for b in range(NMAX + 1 - a))
print(f"enumeration: {(1 << (NMAX + 1)) - 1} label words; every cell equals Poisson(1) x Poisson(3) to 1e-15: {'yes' if gap < 1e-15 else 'no'}")
given_support = [joint[0][k] / sum(joint[a][k] for a in range(NMAX + 1 - k)) for k in range(7)]
given_total = [joint[0][k] / pois(k, LAM) for k in range(7)]
print("chart, P(sales silent | support took k), k = 0..6: " + ", ".join(f"{x:.2f}" for x in given_support))
print("chart, P(sales silent | switchboard took k), k = 0..6: " + ", ".join(f"{x:.2f}" for x in given_total))
assert gap < 1e-15                                                    # words against the formula
assert all(abs(x - exp(-l1)) < 1e-4 for x in given_support)          # independence: flat at e^-1

# road three: m slots an hour, each holding one sales call, one support call, or none
target, last = pois(1, l1) * pois(2, l2), 1.0
for m in (10, 100, 1000, 10000):
    grid = m * (m - 1) * (m - 2) / 2 * (l1 / m) * (l2 / m) ** 2 * (1 - LAM / m) ** (m - 3)
    print(f"grid, {m} slots an hour: P(sales 1, support 2) = {grid:.6f}, off by {abs(grid - target):.6f}")
    assert abs(grid - target) < last                                  # the error shrinks with m
    last = abs(grid - target)
assert last < 2e-4

# road four: one long stream of calls, labelled by coin and by a 1-in-ROT rotation
g = SplitMix64(SEED)
sales, support, rota, fig = [0] * H, [0] * H, [0] * H, []
t, calls = g.wait(LAM), 0
while t < H:
    h, calls = int(t), calls + 1
    is_sales = g.uniform() < P
    if is_sales: sales[h] += 1
    else: support[h] += 1
    if calls % ROT == 0: rota[h] += 1
    if t < 2: fig.append(f"{t:.3f}{'S' if is_sales else 'U'} x {40 + 150 * t:.1f}")
    t += g.wait(LAM)
print(f"simulation: {H} hours, seed {SEED}, {calls} calls")
ms, mu = sum(sales) / H, sum(support) / H
ses = sqrt(sum((x - ms) ** 2 for x in sales) / H / H)
seu = sqrt(sum((x - mu) ** 2 for x in support) / H / H)
print(f"simulated calls an hour: sales {ms:.4f} +- {ses:.4f}, support {mu:.4f} +- {seu:.4f}")
f12, se12 = freq(sum(1 for i in range(H) if sales[i] == 1 and support[i] == 2), H)
print(f"simulated P(sales 1, support 2) = {f12:.4f} +- {se12:.4f}, exact {target:.4f}")
prods = [(sales[i] - ms) * (support[i] - mu) for i in range(H)]
cov = sum(prods) / H
secov = sqrt(sum((x - cov) ** 2 for x in prods) / H / H)
print(f"simulated covariance of sales and support counts = {cov:.4f} +- {secov:.4f}, exact 0")
for x, e, s in ((ms, l1, ses), (mu, l2, seu), (f12, target, se12), (cov, 0.0, secov)):
    assert abs(x - e) < 4 * s
for k in range(7):
    nk = sum(1 for x in support if x == k)
    f, se = freq(sum(1 for i in range(H) if support[i] == k and sales[i] == 0), nk)
    print(f"simulated P(sales silent | support took {k}) = {f:.4f} +- {se:.4f} over {nk} hours")
    assert abs(f - exp(-l1)) < 4 * se
print("figure, first 2 hours, time in hours, S sales or U support, x = 40 + 150 t: " + ", ".join(fig))

# merging: a sales line at 1 an hour and a support line at 3, drawn apart, added
merged, t1, t2, prev, ng, sg, sg2, from_sales = [0] * H, g.wait(l1), g.wait(l2), 0.0, 0, 0.0, 0.0, 0
while min(t1, t2) < H:
    if t1 < t2: t, t1, from_sales = t1, t1 + g.wait(l1), from_sales + 1
    else: t, t2 = t2, t2 + g.wait(l2)
    merged[int(t)] += 1
    ng, sg, sg2, prev = ng + 1, sg + (t - prev), sg2 + (t - prev) ** 2, t
for k in range(9):
    conv = sum(pois(i, l1) * pois(k - i, l2) for i in range(k + 1))
    f, se = freq(sum(1 for x in merged if x == k), H)
    print(f"merge, P(merged count = {k}): formula {pois(k, LAM):.6f}, convolution {conv:.6f}, simulated {f:.4f} +- {se:.4f}")
    assert abs(conv - pois(k, LAM)) < 1e-15 and abs(f - conv) < 4 * se
mg = sg / ng
seg = sqrt((sg2 / ng - mg * mg) / ng)
fs, sefs = freq(from_sales, ng)
print(f"merge, gap between merged calls: exact {1 / LAM:.4f} hours, simulated {mg:.4f} +- {seg:.4f} over {ng} gaps")
print(f"merge, share of merged calls from sales: exact {l1 / LAM:.4f}, simulated {fs:.4f} +- {sefs:.4f}")
assert abs(mg - 1 / LAM) < 4 * seg
assert abs(fs - l1 / LAM) < 4 * sefs

# what breaks when a hypothesis is dropped
rr_exact = sum(sum(pois(i, LAM) for i in range(j)) for j in range(1, ROT + 1)) / ROT
frr, serr = freq(sum(1 for x in rota if x == 0), H)
print(f"mistake, every {ROT}th call to sales: P(sales silent an hour) exact {rr_exact:.4f}, simulated {frr:.4f} +- {serr:.4f}, Poisson {exp(-LAM / ROT):.4f}")
assert abs(frr - rr_exact) < 4 * serr
w = [(bin(m).count("1"), P ** bin(m).count("1") * (1 - P) ** (4 - bin(m).count("1"))) for m in range(16)]
p0 = sum(q for a, q in w if a == 0)
cv = sum(q * a * (4 - a) for a, q in w) - sum(q * a for a, q in w) * sum(q * (4 - a) for a, q in w)
print(f"mistake, calls on the quarter hour, then coin labels: P(sales silent) {p0:.4f}, covariance {cv:.4f}")
assert abs(cv + 4 * P * (1 - P)) < 1e-12                               # minus a binomial variance
print(f"mistake, sales line merged with a copy of itself: P(1 call) {sum(pois(j, l1) for j in range(20) if 2 * j == 1):.4f}, "
      f"P(2 calls) {pois(1, l1):.4f}; Poisson(2) says {pois(1, 2 * l1):.4f} and {pois(2, 2 * l1):.4f}")
print(f"mistake, told the switchboard took 3: P(sales silent) {given_total[3]:.4f}, not {exp(-l1):.4f}")
print("ALL CHECKS PASS")
