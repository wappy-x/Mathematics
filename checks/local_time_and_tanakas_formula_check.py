# Local time and Tanaka's formula -- the check behind the card.  Only math is imported.
# Roads: the coin-walk identity |S_n| = sum sgn(S_{k-1}) X_k + (visits to 0) on one path
# and on all 1024 ten-step paths; its average two ways (enumeration, binomials) and its
# scaling limit against E|B_1| by Simpson's rule; 5000 seeded Brownian paths where the
# Tanaka leftover, the time-near-0 limit and the reflection law agree; a stop-loss hedge.
import math

MASK = (1 << 64) - 1
SEED, PATHS, FINE, GRIDS, EPS = 20261123, 5000, 4096, (16, 64, 256, 1024), 0.05
S0, K, SIG = 100.0, 100.0, 20.0           # share price, strike, dollars per root-year

class SplitMix64:                         # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal_pair(self):                # Box-Muller, both halves
        u1, u2 = self.uniform(), self.uniform()
        r = math.sqrt(-2.0 * math.log(1.0 - u1))
        return r * math.cos(2.0 * math.pi * u2), r * math.sin(2.0 * math.pi * u2)

def sgn(x):
    return (x > 0) - (x < 0)

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

phi = lambda z: math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi)

def walk(steps):                          # positions, hedge sum, visits to 0 before k
    s, beta, vis = [0], [0], [0]
    for x in steps:
        beta.append(beta[-1] + sgn(s[-1]) * x)
        vis.append(vis[-1] + (s[-1] == 0))
        s.append(s[-1] + x)
    return s, beta, vis

# 1. the hand path
STEPS = [1, -1, -1, 1, 1, 1, -1, -1, -1, -1]
s, beta, vis = walk(STEPS)
print("walk, k        " + "".join(f"{k:4d}" for k in range(11)))
print("walk, S_k      " + "".join(f"{v:4d}" for v in s))
print("walk, |S_k|    " + "".join(f"{abs(v):4d}" for v in s))
print("walk, hedge    " + "".join(f"{v:4d}" for v in beta))
print("walk, visits   " + "".join(f"{v:4d}" for v in vis))
print(f"hand path: |S_10| = {abs(s[10])} = hedge sum {beta[10]} + visits {vis[10]}")
assert abs(s[10]) == beta[10] + vis[10]
assert vis[10] == s[:10].count(0) == 4    # counted a second way: zeros among S_0..S_9

# 2. all 1024 ten-step paths
tot_abs = tot_vis = bad = 0
for m in range(1 << 10):
    p, b, v = walk([1 if (m >> i) & 1 else -1 for i in range(10)])
    tot_abs += abs(p[10]); tot_vis += v[10]; bad += abs(p[10]) != b[10] + v[10]
binom_abs = sum(abs(2 * j - 10) * math.comb(10, j) for j in range(11)) / 1024
binom_vis = sum(math.comb(k, k // 2) / 2 ** k for k in range(0, 10, 2))
print(f"all 1024 paths: identity fails on {bad}; mean |S_10| {tot_abs / 1024:.4f}, "
      f"mean visits {tot_vis / 1024:.4f}")
print(f"binomials: E|S_10| {binom_abs:.4f}; sum of P(S_k = 0), k < 10, {binom_vis:.4f}")
assert bad == 0 and abs(tot_vis / 1024 - binom_abs) < 1e-12 and abs(binom_vis - binom_abs) < 1e-12

# 3. scaling: visits / sqrt(n) -> E|B_1|
target = 2.0 * simpson(lambda x: x * phi(x), 0.0, 12.0, 4000)
print(f"E|B_1| by Simpson {target:.6f}; sqrt(2/pi) {math.sqrt(2 / math.pi):.6f}")
p0, acc, last = 1.0, 0.0, {}
for k in range(0, 10001, 2):              # P(S_k = 0) by p_k = p_{k-2} (k-1)/k
    if k > 0:
        p0 *= (k - 1) / k
    if k in (10, 100, 1000, 10000):
        last[k] = (acc / math.sqrt(k), k * p0 / math.sqrt(k))
    acc += p0
for n, (a, b) in last.items():
    print(f"n {n:5d}: mean visits / sqrt(n) {a:.6f}; E|S_n| / sqrt(n) {b:.6f}")
assert abs(target - math.sqrt(2 / math.pi)) < 1e-9 and abs(last[10000][0] - target) < 1e-4
assert all(abs(a - b) < 1e-12 for a, b in last.values())

# 4. Brownian paths and the stop-loss hedge, price P = 100 + 20 B, strike 100
rng, dt = SplitMix64(SEED), 1.0 / FINE
L_tan, L_occ, over = [], [], 0
slip = {g: [] for g in GRIDS}; gap = {g: 0.0 for g in GRIDS}
for _ in range(PATHS):
    B = [0.0]
    for _ in range(FINE // 2):
        z1, z2 = rng.normal_pair()
        B.append(B[-1] + z1 * math.sqrt(dt)); B.append(B[-1] + z2 * math.sqrt(dt))
    hedge, near = 0.0, 0
    for k in range(FINE):
        hedge += sgn(B[k]) * (B[k + 1] - B[k]); near += abs(B[k]) < EPS
    lt = abs(B[FINE]) - hedge
    L_tan.append(lt); L_occ.append(near * dt / (2 * EPS)); over += lt > 0.5
    pay = max(S0 + SIG * B[FINE] - K, 0.0)
    for g in GRIDS:
        st, gain = FINE // g, 0.0
        for j in range(0, FINE, st):
            if S0 + SIG * B[j] > K:
                gain += SIG * (B[j + st] - B[j])
        slip[g].append(pay - gain); gap[g] += abs(pay - gain - SIG * lt / 2) / PATHS

def mse(xs):
    m = 0.0
    for x in xs:
        m += x / len(xs)
    v = 0.0
    for x in xs:
        v += (x - m) * (x - m) / (len(xs) - 1)
    return m, math.sqrt(v / len(xs))

mt, st_ = mse(L_tan); mo, so = mse(L_occ); pd = 0.0
for a, b in zip(L_tan, L_occ):
    pd += abs(a - b) / PATHS
law = 2.0 * (0.5 - simpson(phi, 0.0, 0.5, 2000))
fr = over / PATHS; fse = math.sqrt(fr * (1 - fr) / PATHS)
occ = simpson(lambda a: 2 * phi(a) + 2 * a * simpson(phi, 0.0, a, 200) - abs(a), -EPS, EPS, 200) / (2 * EPS)  # mean of E|B_1 - a| - |a|
print(f"Brownian, {PATHS} paths of {FINE} steps, seed {SEED}:")
print(f"  Tanaka leftover |B_1| - sum sgn(B) dB: mean {mt:.4f} (se {st_:.4f})")
print(f"  time within {EPS} of 0, over 2 eps: mean {mo:.4f} (se {so:.4f}), exact {occ:.4f} at this eps; path gap {pd:.4f}")
print(f"  share with L_1 > 0.5: {fr:.4f} (se {fse:.4f}); reflection law 2 P(B_1 > 0.5) {law:.4f}")
call = SIG * simpson(lambda x: x * phi(x), 0.0, 12.0, 4000)
print(f"call, P = {S0:g} + {SIG:g} B, strike {K:g}, one year: value {call:.4f} = half of {SIG:g} x {target:.4f}")
for g in GRIDS:
    m, e = mse(slip[g])
    print(f"  stop-loss hedge checked {g:4d} times: mean slippage {m:.4f} (se {e:.4f}); "
          f"path gap to {SIG / 2:g} L {gap[g]:.4f}")
    assert abs(m - call) < 4 * e
assert abs(mt - target) < 4 * st_ and abs(mo - occ) < 4 * so and abs(fr - law) < 4 * fse
assert gap[16] > gap[64] > gap[256] > gap[1024]
print("what breaks:")
print(f"  ordinary Ito on |x| (no curvature off 0): E|B_1| would be 0; it is {target:.4f}")
print(f"  time near 0 divided by eps, not 2 eps: {2 * mo:.4f}; it is {mo:.4f}")
print(f"  slippage as all of {SIG:g} L, not half: {2 * call:.4f}; it is {call:.4f}")
print(f"  check {GRIDS[-1]} times to kill slippage: still {mse(slip[GRIDS[-1]])[0]:.4f}, not 0")
print("ALL CHECKS PASS")
