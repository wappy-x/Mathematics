# Multi-armed bandits -- the check behind the card.  Standard library only.
# Three release rules for a hydro plant; each hour one is used, and it succeeds
# (meets the grid's order inside the level band) with unknown chance 0.3, 0.5 or
# 0.6.  Maximise successes; regret = successes lost against always using the best.
# Roads: (1) closed forms: UCB index, KL, the Lai-Robbins constant, the UCB1 bound;
# (2) 100 seeded simulated runs of 10000 hours for each method, regret counted two
# ways; (3) Thompson's choice chances by numerical integration against its sampler.
import math
MU, SWAP, T, RUNS = [0.3, 0.5, 0.6], [0.6, 0.5, 0.3], 10000, 100
GAP = [max(MU) - m for m in MU]
M64 = (1 << 64) - 1
def add(xs):                                   # plain left-to-right sum, as in Rust
    t = 0.0
    for x in xs: t += x
    return t
class Rng:                                     # SplitMix64, seeded
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64
        z = ((self.x ^ (self.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unif(self): return (self.next() >> 11) * 2.0 ** -53
def normal(g): return math.sqrt(-2 * math.log(1 - g.unif())) * math.cos(2 * math.pi * g.unif())
def gamma(g, a):                               # Marsaglia-Tsang, shape a >= 1
    d = a - 1 / 3
    c = 1 / math.sqrt(9 * d)
    while True:
        x = normal(g)
        w = 1 + c * x
        if w <= 0: continue
        v = w * w * w
        if math.log(1 - g.unif()) < 0.5 * x * x + d - d * v + d * math.log(v): return d * v
def beta(g, a, b):
    x = gamma(g, a)
    return x / (x + gamma(g, b))
def kl(p, q): return p * math.log(p / q) + (1 - p) * math.log((1 - p) / (1 - q))
def argmax(v):
    b = 0
    for i in range(len(v)):
        if v[i] > v[b]: b = i
    return b
def run(method, seed, marks=(), eps=0.1, swap=False):
    g, n, s, got, out, late = Rng(seed), [0, 0, 0], [0, 0, 0], 0, [], 0.0
    for t in range(1, T + 1):
        mu = SWAP if swap and t > T // 2 else MU
        if method == "ts": i = argmax([beta(g, 1 + s[j], 1 + n[j] - s[j]) for j in range(3)])
        elif t <= 3: i = t - 1                 # the others try each rule once first
        elif method == "ucb":
            i = argmax([s[j] / n[j] + math.sqrt(2 * math.log(t - 1) / n[j]) for j in range(3)])
        elif g.unif() < eps: i = g.next() % 3  # explore
        else: i = argmax([s[j] / n[j] for j in range(3)])
        win = 1 if g.unif() < mu[i] else 0
        n[i] += 1; s[i] += win; got += win
        if t > T // 2: late += max(mu) - mu[i]
        if t in marks: out.append(add(GAP[j] * n[j] for j in range(3)))
    return n, got, out, late
L30 = math.log(30)
print(f"ln 30 = {L30:.4f}")
for name, k, m in (("A", 6, 1), ("B", 10, 5), ("C", 14, 8)):
    b = math.sqrt(2 * L30 / k)
    print(f"index,rule {name},tries {k},mean {m / k:.4f},bonus {b:.4f},index {m / k + b:.4f}")
kls = [kl(MU[i], 0.6) for i in range(2)]
lr = add(GAP[i] / kls[i] for i in range(2))
print(f"KL(0.3,0.6) {kls[0]:.5f}, KL(0.5,0.6) {kls[1]:.5f}; terms {GAP[0] / kls[0]:.3f} + {GAP[1] / kls[1]:.3f} = {lr:.4f}")
C3 = 1 + math.pi * math.pi / 3
ub = lambda h: add(8 * math.log(h) / GAP[i] + C3 * GAP[i] for i in range(2))
print(f"at T={T}: Lai-Robbins {lr * math.log(T):.2f}, UCB1 bound {ub(T):.2f}, "
      f"pull bounds A {8 * math.log(T) / 0.09 + C3:.0f} B {8 * math.log(T) / 0.01 + C3:.0f}")
cross = 2
while 0.1 * (0.3 + 0.1) / 3 * cross <= ub(cross): cross += 1
print(f"epsilon-greedy floor 0.1 x 0.4/3 x T passes the UCB1 bound from T = {cross}")
MARKS = (100, 200, 500, 1000, 2000, 5000, 10000)
res = {}
for meth in ("eps", "greedy", "ucb", "ts"):
    reg, real, pulls, lost = [0.0] * len(MARKS), [], [0, 0, 0], 0
    for r in range(RUNS):
        n, got, out, _ = run(meth, 1000 + r, MARKS, 0.0 if meth == "greedy" else 0.1)
        reg = [reg[k] + out[k] / RUNS for k in range(len(MARKS))]
        real.append(0.6 * T - got)
        pulls = [pulls[j] + n[j] for j in range(3)]
        lost += 1 if n[2] < T / 2 else 0
    mr = add(real) / RUNS
    se = math.sqrt(add((x - mr) * (x - mr) for x in real) / (RUNS - 1) / RUNS)
    res[meth] = (reg, mr, se, lost, pulls)
    print(f"{meth}: regret " + ",".join(f"{x:.1f}" for x in reg) + f"; realised {mr:.1f} (se {se:.1f})"
          f"; mean pulls " + ",".join(f"{p / RUNS:.1f}" for p in pulls) + f"; runs with C under half {lost}")
print("Lai-Robbins 6.53 ln T: " + ",".join(f"{lr * math.log(h):.1f}" for h in MARKS))
u, th, ep = res["ucb"][0], res["ts"][0], res["eps"][0]
print(f"growth 5000->10000: eps {ep[6] - ep[5]:.1f}, ucb {u[6] - u[5]:.1f}, ts {th[6] - th[5]:.1f}")
bon = [math.sqrt(2 * math.log(T) * RUNS / res["ucb"][4][j]) for j in range(2)]   # UCB1 bonus at the mean pulls
print(f"ucb bonus at T={T}, mean pulls: rule A {bon[0]:.3f} (gap {GAP[0]:.1f}), rule B {bon[1]:.3f} (gap {GAP[1]:.1f})")
lates = []
for meth in ("ucb", "ts"):                     # the world changes: A and C swap after T/2
    late = add(run(meth, 1000 + r, swap=True)[3] for r in range(20)) / 20
    print(f"swap at hour {T // 2}: {meth} regret over the second half {late:.1f}")
    lates.append(late)
post = [(2, 6), (6, 6), (9, 7)]                # Thompson's posteriors at the hand state
def pdf(x, a, b): return (a + b - 1) * math.comb(a + b - 2, a - 1) * x ** (a - 1) * (1 - x) ** (b - 1)
def cdf(x, a, b):                              # integer a, b: a binomial tail
    m = a + b - 1
    return add(math.comb(m, k) * x ** k * (1 - x) ** (m - k) for k in range(a, m + 1))
N, win = 2000, []
for i in range(3):                             # Simpson's rule on f_i(x) F_j(x) F_k(x)
    tot = 0.0
    for k in range(N + 1):
        x, wt = k / N, 1 if k in (0, N) else 4 if k % 2 else 2
        f = pdf(x, *post[i])
        for j in range(3):
            if j != i: f *= cdf(x, *post[j])
        tot += wt * f
    win.append(tot / (3 * N))
g, cnt, D = Rng(7), [0, 0, 0], 60000
first = [beta(g, a, b) for a, b in post]
cnt[argmax(first)] += 1
for _ in range(D - 1): cnt[argmax([beta(g, a, b) for a, b in post])] += 1
print("thompson draw " + ",".join(f"{x:.4f}" for x in first) + "; win chance by integral "
      + ",".join(f"{w:.4f}" for w in win) + "; by sampling " + ",".join(f"{c / D:.4f}" for c in cnt))
zs = [(cnt[i] / D - win[i]) / math.sqrt(win[i] * (1 - win[i]) / D) for i in range(3)]
print("sampling minus integral, in standard errors: " + ",".join(f"{z:+.2f}" for z in zs))
assert abs(5 / 10 + math.sqrt(2 * L30 / 10) - 1.3248) < 5e-5 and abs(lr - 6.53) < 5e-3   # road 1
for meth in ("eps", "ucb", "ts"):                                                     # road 2
    assert abs(res[meth][1] - res[meth][0][6]) < 4 * res[meth][2]
assert u[6] < ub(T) and th[6] < u[6] and ep[6] - ep[5] > 50 and u[6] - u[5] < (ep[6] - ep[5]) / 2
assert bon[0] > GAP[0] and bon[1] > GAP[1] and lates[1] > 3 * lates[0] > 0 and res["greedy"][3] > 0 and res["ucb"][3] == 0 and res["ts"][3] == 0
assert all(abs(win[i] - cnt[i] / D) < 4 * math.sqrt(win[i] * (1 - win[i]) / D) for i in range(3))  # road 3
assert abs(add(win) - 1) < 1e-6
print("ALL CHECKS PASS")
