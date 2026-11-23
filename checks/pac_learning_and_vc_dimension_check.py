# PAC learning and VC dimension: how many labelled sales pin down a hidden price cap.
# Standard library only. Roads: closed-form bounds, brute-force labelling counts,
# exact failure chances, and a seeded simulation (SplitMix64, written out here).
import math
from itertools import combinations

M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unit(self): return (self.next() >> 11) / 9007199254740992.0

def pw(b, n):  # b to the power n by repeated multiplication, the same in both languages
    r = 1.0
    for _ in range(n): r *= b
    return r

LO, HI, CAP = 2000.0, 4000.0, 3150.0  # quotes in pence, uniform; the council's hidden cap
EPS, DELTA = 0.05, 0.01               # allowed error, allowed failure chance
W = HI - LO

# ---- the worked log: ten quotes, approved (1) when price <= cap
log = [2240, 3895, 2710, 3320, 3085, 2475, 3605, 2960, 3210, 2150]
lab = [1 if p <= CAP else 0 for p in log]
a10 = max(p for p, l in zip(log, lab) if l == 1)
r10 = min(p for p, l in zip(log, lab) if l == 0)
print(f"log: {sum(lab)} of {len(log)} approved; highest approved {a10}p, lowest refused {r10}p")
print(f"learned cap error {(CAP - a10) / W:.4f}; error at top of fitting range {(r10 - CAP) / W:.4f}")

# ---- brute force: every labelling the cap rules and the interval rules can give
def caps(pts):  # approve iff price <= c, one c per gap
    cs = [min(pts) - 1] + sorted(pts)
    return {tuple(1 if p <= c else 0 for p in pts) for c in cs}
def intervals(pts):  # approve iff a < price <= b
    cs = [min(pts) - 1] + sorted(pts)
    return {tuple(1 if a < p <= b else 0 for p in pts) for a in cs for b in cs}
def vc(family, pts):  # the largest k up to 4 with some k quotes labelled all 2^k ways
    return max([k for k in range(1, 5) if any(len(family(list(c))) == 2 ** k for c in combinations(pts, k))], default=0)
def sauer(n, d): return sum(math.comb(n, i) for i in range(d + 1))
vc_c, vc_i = vc(caps, log), vc(intervals, log)
print(f"VC dimension by brute force: caps {vc_c}, price bands {vc_i}")
for n in (3, 10):
    print(f"labellings of {n} quotes: caps {len(caps(log[:n]))} (Sauer {sauer(n, 1)}),"
          f" bands {len(intervals(log[:n]))} (Sauer {sauer(n, 2)}), all {2 ** n}")
assert vc_c == 1 and vc_i == 2
for n in range(1, 11):
    assert len(caps(log[:n])) == n + 1 == sauer(n, 1)
    assert len(intervals(log[:n])) == sauer(n, 2)

# ---- sample sizes for error 5%, failure chance 1%
def finite(size): return math.ceil((math.log(size) + math.log(1 / DELTA)) / EPS)
def fail_any(m): return 2 * pw(1 - EPS, m) - pw(1 - 2 * EPS, m)
def vc_m(growth):
    m = math.ceil(8 / EPS)
    while 2 * growth(2 * m) * math.exp(-EPS * m / 2 * math.log(2)) > DELTA: m += 1
    return m
m_fin, m_tenth, m_hund = finite(2001), finite(20001), finite(200001)
m_dir = math.ceil(math.log(2 / DELTA) / EPS)
m_one = math.ceil(math.log(1 / DELTA) / EPS)
m_ex = next(m for m in range(1, 1000) if fail_any(m) <= DELTA)
m_vc, m_vcs, m_vci = vc_m(lambda n: n + 1), vc_m(lambda n: math.e * n), vc_m(lambda n: sauer(n, 2))
m_ag, m_ag2 = (math.ceil(math.log(2 * 2001 / DELTA) / (2 * e * e)) for e in (EPS, EPS / 2))
print(f"union bound, 2,001 penny caps: {m_fin}; tenth-penny caps: {m_tenth}; hundredth: {m_hund}")
print(f"VC bound, d = 1, exact growth 2m + 1: {m_vc}; Sauer growth 2em: {m_vcs}; bands d = 2: {m_vci}")
print(f"direct two-sided bound: {m_dir}; exact smallest m: {m_ex}; one side only: {m_one}")
print(f"failure chance at {m_ex}: {fail_any(m_ex):.5f}; at {m_ex - 1}: {fail_any(m_ex - 1):.5f}")
print(f"failure chance at {m_one}, guarding one side: {fail_any(m_one):.5f}")
print(f"noisy labels, finite caps, 1/eps^2 bound: {m_ag} (every log error within eps, so chosen cap within 2 eps of best), {m_ag2} (chosen cap within eps of best)")
def vcv(m): return 2 * (2 * m + 1) * math.exp(-EPS * m / 2 * math.log(2))
print(f"hand: ln 2001 = {math.log(2001):.4f}, ln 100 = {math.log(100):.4f}, ln 200 = {math.log(200):.4f}, 5% = {EPS * W:.0f}p,"
      f" 8/eps = {math.ceil(8 / EPS)}")
print(f"hand: 0.95^{m_ex} = {pw(1 - EPS, m_ex):.5f}, 0.90^{m_ex} = {pw(1 - 2 * EPS, m_ex):.7f}")
print(f"hand: VC bound at {m_vc}: growth {2 * m_vc + 1}, power of 2 {-EPS * m_vc / 2:.3f},"
      f" value {vcv(m_vc):.5f}; at {m_vc - 1}: {vcv(m_vc - 1):.5f}")
for e, dl in ((0.05, 0.001), (0.01, 0.01)):
    ex = next(k for k in range(1, 10000) if 2 * pw(1 - e, k) - pw(1 - 2 * e, k) <= dl)
    print(f"try eps {e}, delta {dl}: direct {math.ceil(math.log(2 / dl) / e)}, exact {ex}")
assert m_ex <= m_dir <= m_fin < m_vc and fail_any(m_dir) <= 2 * math.exp(-EPS * m_dir)
assert fail_any(m_one) > DELTA and m_tenth > m_fin

# ---- simulation: 20,000 logs of m_dir quotes; the learner keeps two numbers in one pass
rng, N, m = SplitMix64(20261119), 20000, m_dir
bad1 = bad2 = 0; tot = sq = 0.0
for _ in range(N):
    a, r = LO, HI
    for _ in range(m):
        p = LO + W * rng.unit()
        if p <= CAP:
            if p > a: a = p
        elif p < r: r = p
    e1, e2 = (CAP - a) / W, (r - CAP) / W
    tot += e1; sq += e1 * e1
    if e1 > EPS: bad1 += 1
    if e1 > EPS or e2 > EPS: bad2 += 1
f1, f2, mean = bad1 / N, bad2 / N, tot / N; x1, x2 = pw(1 - EPS, m), fail_any(m)
xmean = (1 - pw(1 - (CAP - LO) / W, m + 1)) / (m + 1)
print(f"simulated {N} logs of {m}: learned cap bad {f1:.5f} (exact {x1:.5f}),"
      f" some consistent cap bad {f2:.5f} (exact {x2:.5f})")
print(f"mean error of learned cap {mean:.5f} (exact {xmean:.5f})")
assert abs(f1 - x1) < 4 * math.sqrt(x1 * (1 - x1) / N)
assert abs(f2 - x2) < 4 * math.sqrt(x2 * (1 - x2) / N)
assert abs(mean - xmean) < 4 * math.sqrt((sq / N - mean * mean) / N)

# ---- what breaks: a memoriser (infinite VC) and a log that is not a fair sample
train = [LO + W * rng.unit() for _ in range(m)]
seen = {p for p in train if p <= CAP}
trn = sum((p in seen) != (p <= CAP) for p in train) / m
T, wrong = 10000, 0
for _ in range(T):
    p = LO + W * rng.unit()
    if (p in seen) != (p <= CAP): wrong += 1
mem = wrong / T
print(f"memoriser: training error {trn:.4f}, test error {mem:.4f} (exact {(CAP - LO) / W:.4f})")
assert abs(mem - 0.575) < 4 * math.sqrt(0.575 * 0.425 / T)
a = LO
for _ in range(m):
    p = LO + 500.0 * rng.unit()
    if p > a: a = p
print(f"promotion log, all quotes under 2500p: learned cap {a:.0f}p, error {(CAP - a) / W:.4f}")
assert 0.325 < (CAP - a) / W < 0.33

# ---- a short log, where the overlap term is large: 20,000 logs of 20 sales, strips tested directly
bad = 0
for _ in range(N):
    xs = [LO + W * rng.unit() for _ in range(20)]
    if all(not CAP - EPS * W < p <= CAP for p in xs) or all(not CAP < p <= CAP + EPS * W for p in xs): bad += 1
print(f"simulated {N} logs of 20, strips checked directly: some consistent cap bad {bad / N:.5f} (exact {fail_any(20):.5f}, overlap term dropped {2 * pw(1 - EPS, 20):.5f})")
assert abs(bad / N - fail_any(20)) < 4 * math.sqrt(fail_any(20) * (1 - fail_any(20)) / N)

# ---- chart: failure chance of the worst consistent cap against log length
ms = list(range(0, 201, 20))
print("chart, sales", " ".join(str(k) for k in ms))
print("chart, exact", " ".join(f"{fail_any(k):.3f}" for k in ms))
print("chart, bound", " ".join(f"{min(1.0, 2 * math.exp(-EPS * k)):.3f}" for k in ms))
print("ALL CHECKS PASS")
