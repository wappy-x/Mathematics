# Blumenthal's zero-one law and the Brownian LIL, for a grain spreading 1 um^2 per second.
# Roads: normal tails three ways; exact sign-change and Borel-Cantelli sums; seeded simulation.
import math

M64 = (1 << 64) - 1
class Rng:  # SplitMix64, then Box-Muller for normal draws
    def __init__(self, seed): self.s, self.spare = seed, None
    def u64(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def normal(self):
        if self.spare is not None:
            z, self.spare = self.spare, None
            return z
        u1 = ((self.u64() >> 11) + 1) / 2.0**53
        u2 = (self.u64() >> 11) / 2.0**53
        r = math.sqrt(-2.0 * math.log(u1))
        self.spare = r * math.sin(2.0 * math.pi * u2)
        return r * math.cos(2.0 * math.pi * u2)

def phi(z): return math.exp(-z * z / 2.0) / math.sqrt(2.0 * math.pi)
def q_series(z):  # P(Z > z) from the Taylor series of erf
    x, s, term, k = z / math.sqrt(2.0), 0.0, z / math.sqrt(2.0), 0
    while k < 5 or abs(term) > 1e-17:
        s += term / (2 * k + 1); k += 1; term *= -x * x / k
    return 0.5 - s / math.sqrt(math.pi)
def q_cf(z, kmax=400):  # P(Z > z) from the continued fraction of the Mills ratio
    f = z
    for k in range(kmax, 0, -1): f = z + k / f
    return phi(z) / f
def q_simpson(z, n=4000):  # P(Z > z) as the area under phi from z to z + 12
    hh = 12.0 / n
    s = phi(z) + phi(z + 12.0) + sum((4 if i % 2 else 2) * phi(z + i * hh) for i in range(1, n))
    return s * hh / 3.0
def tail(z): return q_cf(z, 100) if z >= 2.0 else q_series(z)
def env(t): return math.sqrt(2.0 * t * math.log(math.log(t)))  # the LIL envelope h(t)

T = 1e6; z = env(T) / math.sqrt(T)
print(f"{'sqrt(t), t = 1e6 s; t in days':42}{math.sqrt(T):12.4f}{T / 86400:10.4f}")
print(f"{'ln t, then ln ln t':42}{math.log(T):12.4f}{math.log(math.log(T)):10.4f}")
print(f"{'envelope h(t) = sqrt(2 t ln ln t), um':42}{env(T):12.4f}")
print(f"{'h(t) / sqrt(t)':42}{z:12.4f}")
print(f"{'P(W_t > h(t)): series, fraction, Simpson':42}{q_series(z):12.6f}{q_cf(z):10.6f}{q_simpson(z):10.6f}")
assert abs(env(T) - 2291.6) < 0.1, "envelope against the hand value sqrt(2e6 x 2.626)"
for zz in (1.0, 1.5, z, 3.0):
    assert abs(q_series(zz) - q_cf(zz)) < 1e-13 and abs(q_simpson(zz) - q_cf(zz)) < 1e-12
facs = [env(t) / math.sqrt(t) for t in (1e3, 1e6, 1e12, 1e100)]
print(f"{'factor at t = 1e3, 1e6, 1e12, 1e100 s':42}" + "".join(f"{f:8.4f}" for f in facs))
print(f"{'wrong: P(W_t > 3 sqrt t); sqrt(2 t ln t)':42}{tail(3.0):12.6f}{math.sqrt(2 * T * math.log(T)):10.1f}")
print(f"{'time inversion: envelope at 1 us, um':42}{math.sqrt(2e-6 * math.log(math.log(1e6))):12.7f}")
ri = Rng(7)  # time inversion simulated: Cov(X_0.5, X_4) = E[0.5 W_2 * 4 W_0.25] must be min(0.5, 4) = 0.5
pr = [(lambda a: 0.5 * (a + math.sqrt(1.75) * ri.normal()) * 4.0 * a)(0.5 * ri.normal()) for _ in range(20000)]
pm = sum(pr) / len(pr); pse = math.sqrt(sum((x - pm) ** 2 for x in pr) / (len(pr) - 1) / len(pr))
print(f"{'time inversion: Cov(X_0.5, X_4), sim; se':42}{pm:12.4f}{pse:10.4f}"); assert abs(pm - 0.5) < 4 * pse

# Blumenthal: the first millisecond, sampled every 1 us, coarsened to 10 and 100 us.
rng = Rng(20261123)
PATHS, M = 2000, 1000
grids = (100, 10, 1)
chg = {g: [] for g in grids}; pos = {g: 0 for g in grids}
for _ in range(PATHS):
    w, path = 0.0, []
    for _ in range(M):
        w += math.sqrt(1e-6) * rng.normal(); path.append(w)
    for g in grids:
        pts = path[g - 1::g]
        chg[g].append(sum(1 for a, b in zip(pts, pts[1:]) if a * b < 0))
        pos[g] += any(p > 0 for p in pts)
def exact_changes(m):  # sum over neighbours of P(opposite signs) = arccos(rho) / pi
    return sum(math.acos(math.sqrt(i / (i + 1))) for i in range(1, m)) / math.pi
print("first ms   samples   exact mean changes   simulated   std err   positive somewhere")
for g in grids:
    m = M // g; ex = exact_changes(m); c = chg[g]
    mean = sum(c) / PATHS; se = math.sqrt(sum((x - mean) ** 2 for x in c) / (PATHS - 1) / PATHS)
    print(f"{'':10}{m:8d}{ex:21.4f}{mean:12.4f}{se:10.4f}{pos[g] / PATHS:16.4f}")
    assert abs(mean - ex) < 4 * se, "simulated sign changes against the exact sum"
assert pos[1] / PATHS > 0.5 + 4 * math.sqrt(0.25 / PATHS), "beats the 1/2 of a single time"
big = exact_changes(10**6)
print(f"{'exact mean changes, 1e6 samples (1 ns)':42}{big:12.4f}{2 / math.pi * 1000:10.4f}")
assert abs(big / (2 / math.pi * 1000) - 1) < 0.01, "changes grow like (2/pi) root m"

# Borel-Cantelli, upper half: blocks [2^n, 2^(n+1)], max passing 2 h(2^n), by reflection.
def a_term(n): return 2 * tail(2 * math.sqrt(math.log(n * math.log(2.0))))  # 2 h(2^n) / sqrt(2^(n+1))
assert abs(2 * env(2.0**30) / math.sqrt(2.0**31) - 2 * math.sqrt(math.log(30 * math.log(2.0)))) < 1e-12
LN2 = math.log(2.0)
def mills_bound(n): L = math.log(n * LN2); return 2 * phi(2 * math.sqrt(L)) / (2 * math.sqrt(L))
sums, acc = [], 0.0
for n in range(20, 10**4 + 1):
    acc += a_term(n)
    if n in (20, 100, 1000, 10**4): sums.append(acc)
rest = 1 / (math.sqrt(2 * math.pi) * LN2**2 * math.sqrt(math.log(1e4 * LN2)) * 1e4)
print(f"{'upper: term 20; sums to 1e2, 1e3, 1e4':42}" + "".join(f"{x:10.6f}" for x in sums))
print(f"{'upper: block 20 starts (s); bound after 1e4':42}{2**20:12d}{rest:10.6f}")
print(f"{'blocks of 2 for factor 1.1: exponent; 1.1':42}{1.1**2 / 2:12.4f}{1.1**2 / 1.1:10.4f}")
assert a_term(500) < mills_bound(500) and sums[3] - sums[2] < 1 / (math.sqrt(2 * math.pi) * LN2**2 * math.sqrt(math.log(1e3 * LN2)) * 1e3)
# Borel-Cantelli, lower half: q = 100, independent jumps D_n beyond sqrt(1 - 1/q) h(t_n).
def b_term(n): return tail(math.sqrt(2 * math.log(n * math.log(100.0))))
bs, acc = [], 0.0
for n in range(3, 10**5 + 1):
    acc += b_term(n)
    if n in (10, 100, 1000, 10**4, 10**5): bs.append(acc)
print(f"{'lower: sums to 1e1 .. 1e5 blocks':42}" + "".join(f"{x:8.4f}" for x in bs))
grow = (math.sqrt(math.log(1e5 * math.log(100.0))) - math.sqrt(math.log(1e4 * math.log(100.0)))) / (math.sqrt(math.pi) * math.log(100.0))
print(f"{'lower: block 3 (1e6 s); last decade, integral':42}{b_term(3):12.6f}{bs[4] - bs[3]:10.4f}{grow:10.4f}")
assert abs((bs[4] - bs[3]) / grow - 1) < 0.1, "lower series grows like root ln N"
NB, NPATH = 150, 20000
expect = sum(b_term(n) for n in range(3, NB + 1))
cnt = [sum(1 for n in range(3, NB + 1) if rng.normal() >= math.sqrt(2 * math.log(n * math.log(100.0)))) for _ in range(NPATH)]
cm = sum(cnt) / NPATH; cse = math.sqrt(sum((x - cm) ** 2 for x in cnt) / (NPATH - 1) / NPATH)
print(f"{'blocks 3..150 hit: expected, simulated, se':42}{expect:12.4f}{cm:10.4f}{cse:10.4f}")
assert abs(cm - expect) < 4 * cse, "simulated count of lower events against the sum"
print(f"{'lower bound, q = 100, 1e4, 1e6':42}" + "".join(f"{math.sqrt(1 - 1 / q) - 2 / math.sqrt(q):8.4f}" for q in (100, 1e4, 1e6)))

# LIL simulation on times 1.2^k from 10 s to 1e300 s.
LP, R, starts = 500, 1.2, (1e6, 1e30, 1e100)
over11 = {s: 0 for s in starts}; over09 = 0; chart_hi, chart_lo = [], []
for p in range(LP):
    t, w = 10.0, math.sqrt(10.0) * rng.normal()
    best = {s: -9.0 for s in starts}; win = {}
    while t < 1e300:
        t2 = t * R; w += math.sqrt(t2 - t) * rng.normal(); t = t2
        r = w / env(t)
        for s in starts:
            if t >= s: best[s] = max(best[s], r)
        if p == 0:
            k = min(int(math.log10(t) // 20), 14); lo, hi = win.get(k, (9.0, -9.0)); win[k] = (min(lo, r), max(hi, r))
    for s in starts: over11[s] += best[s] > 1.1
    over09 += best[1e100] > 0.9
    if p == 0: chart_hi = [win[k][1] for k in range(15)]; chart_lo = [win[k][0] for k in range(15)]
sh = [over11[s] / LP for s in starts]
print(f"{'share over 1.1 h after 1e6, 1e30, 1e100':42}" + "".join(f"{x:8.3f}" for x in sh))
print(f"{'share over 0.9 h after 1e100':42}{over09 / LP:8.3f}")
assert sh[0] > sh[2] + 4 * math.sqrt(sh[0] * (1 - sh[0]) / LP), "overshoots thin out with time"
print("chart, window start 1e(20k), k =  " + " ".join(f"{k:5d}" for k in range(15)))
print("chart, path 1, max W/h          " + " ".join(f"{x:5.2f}" for x in chart_hi))
print("chart, path 1, min W/h          " + " ".join(f"{x:5.2f}" for x in chart_lo))
print("ALL CHECKS PASS")
