# Randomised experiments and A/B tests -- the check behind the card.  Standard library only.
# Checkout pages A (old) and B (new), 10,000 visitors each, assigned by lottery.  Road 1: exact
# formulas on a model table of both outcomes for 20,000 visitors.  Road 2: all 70 lotteries on an
# 8-visitor table.  Road 3: 1,000 seeded lotteries (SplitMix64).  Sizing: formula against exact count.
from math import sqrt, pi, exp, ceil, log
SEED, R, NA, NB = 20260929, 1000, 10000, 10000

def Phi(z):                                   # bell area left of z, by its Taylor series
    term, total = z, z
    for k in range(1, 300):
        term *= -z * z / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2 * pi)
def Phi_inv(p, z=0.0):                        # normal quantile by Newton's method from 0
    for _ in range(50): z -= (Phi(z) - p) / (exp(-z * z / 2) / sqrt(2 * pi))
    return z
def neyman(yA, yB, nA, nB):                   # road 1: the exact variance over all lotteries
    N = len(yA)
    def S2(col): m = sum(col) / N; return sum((v - m) ** 2 for v in col) / (N - 1)
    SA, SB, St = S2(yA), S2(yB), S2([b - a for a, b in zip(yA, yB)])
    return SA, SB, St, SB / nB + SA / nA - St / N
# the model population: (returning?, count) for each kind of visitor, (y(A), y(B))
KINDS = [(1, 700, 1, 1), (1, 60, 0, 1), (1, 20, 1, 0), (1, 3220, 0, 0),
         (0, 200, 1, 1), (0, 200, 0, 1), (0, 80, 1, 0), (0, 15520, 0, 0)]
ret, yA, yB = [], [], []
for r, c, a, b in KINDS:
    ret += [r] * c; yA += [a] * c; yB += [b] * c
N = len(yA)
tau = (sum(yB) - sum(yA)) / N
kind = lambda a, b: sum(c for r, c, x, y in KINDS if (x, y) == (a, b))
xA, xB = 500, 580                             # the observed test
gap = xB / NB - xA / NA
pool = (xA + xB) / (NA + NB)
se0 = sqrt(pool * (1 - pool) * (1 / NA + 1 / NB))
se1 = sqrt(xA / NA * (1 - xA / NA) / NA + xB / NB * (1 - xB / NB) / NB)
za, zb = Phi_inv(0.975), Phi_inv(0.80)
print(f"observed: A {xA} of {NA} = {xA / NA:.4f}, B {xB} of {NB} = {xB / NB:.4f}, gap {gap:.4f}")
print(f"observed: pooled rate {pool:.4f}, pooled SE {se0:.6f}, z {gap / se0:.4f}, two-sided p-value {2 * (1 - Phi(gap / se0)):.4f}")
print(f"observed: arm variances {xA / NA * (1 - xA / NA) / NA:.8f} + {xB / NB * (1 - xB / NB) / NB:.8f}, unpooled SE {se1:.6f}, 95% interval {gap - za * se1:.4f} to {gap + za * se1:.4f}")
print(f"model: N {N}; always {kind(1, 1)}, helped {kind(0, 1)}, hurt {kind(1, 0)}, never {kind(0, 0)}")
print(f"model: y(A) rate {sum(yA) / N:.4f}, y(B) rate {sum(yB) / N:.4f}, true effect tau {tau:.4f}")
nret = sum(ret)
rA = sum(a for a, r in zip(yA, ret) if r); rB = sum(b for b, r in zip(yB, ret) if r)
print(f"model: returning {nret} (A {rA / nret:.4f}, B {rB / nret:.4f}), new {N - nret} "
      f"(A {(sum(yA) - rA) / (N - nret):.4f}, B {(sum(yB) - rB) / (N - nret):.4f})")
SA, SB, St, V = neyman(yA, yB, NA, NB)
print(f"exact: S_A^2 {SA:.6f}, S_B^2 {SB:.6f}, S_tau^2 {St:.6f}")
print(f"exact: SD of tau hat over all lotteries {sqrt(V):.6f}; usual SE formula {sqrt(SA / NA + SB / NB):.6f}")
# road 2: the 8-visitor table, every lottery of 4 into B
sA, sB = [1, 0, 0, 1, 0, 0, 0, 0], [1, 1, 1, 0, 0, 0, 0, 0]
gaps8, in_B, total8 = [], 0, 0
for mask in range(256):
    if bin(mask).count("1") != 4: continue
    b = sum(sB[i] for i in range(8) if mask >> i & 1)
    a = sum(sA[i] for i in range(8) if not mask >> i & 1)
    gaps8.append((b - a) / 4); total8 += b - a; in_B += mask & 1
tau8, m8 = (sum(sB) - sum(sA)) / 8, sum(gaps8) / len(gaps8)
v8 = sum((g - m8) ** 2 for g in gaps8) / len(gaps8)
print(f"enumeration, 8 visitors: {len(gaps8)} lotteries; visitor 1 lands in B in {in_B} of {len(gaps8)}")
print(f"enumeration: tau {tau8:.4f}, mean of all gaps {m8:.4f}; variance {v8:.6f}, formula {neyman(sA, sB, 4, 4)[3]:.6f}")
print(f"enumeration: smallest gap {min(gaps8):.4f}, largest {max(gaps8):.4f}")
# road 3: seeded lotteries on the 20,000 visitors
class Rng:                                    # SplitMix64
    def __init__(self, s): self.s = s
    def next(self):
        z = self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return z ^ (z >> 31)
rng, perm, sims, cover, bins = Rng(SEED), list(range(N)), [], 0, [0] * 10
for t in range(R):
    for i in range(NB):                       # the first NB places of a Fisher-Yates shuffle go to B
        j = i + rng.next() % (N - i)
        perm[i], perm[j] = perm[j], perm[i]
    b = sum(yB[k] for k in perm[:NB]); a = sum(yA[k] for k in perm[NB:])
    g = b / NB - a / NA
    se = sqrt(a / NA * (1 - a / NA) / NA + b / NB * (1 - b / NB) / NB)
    cover += abs(g - tau) <= za * se; sims.append(g)
    bins[min(max((b - a + 20) // 20, 0), 9)] += 1      # 0.2-point bins; the end bins take the tails
    if t == 0:
        print(f"simulation: first lottery, returning share in B {sum(ret[k] for k in perm[:NB]) / NB:.4f}, "
              f"in A {sum(ret[k] for k in perm[NB:]) / NA:.4f}")
ms = sum(sims) / R
sd = sqrt(sum((g - ms) ** 2 for g in sims) / (R - 1))
print(f"simulation: {R} lotteries, seed {SEED}: mean gap {ms:.5f} +- {sd / sqrt(R):.5f}, SD {sd:.6f}")
print(f"simulation: the 95% interval caught tau in {cover} of {R} ({cover / R:.4f})")
print(f"simulation: smallest gap {min(sims):.4f}, largest {max(sims):.4f}")
# what breaks: assignment chosen by who the visitor is
print(f"breaks, B shown to returning visitors only: gap {rB / nret - (sum(yA) - rA) / (N - nret):.4f}")
print(f"breaks, B shown to new visitors only: gap {(sum(yB) - rB) / (N - nret) - rA / nret:.4f}")
# sizing
def spreads(p0, p1):
    pb = (p0 + p1) / 2
    return sqrt(2 * pb * (1 - pb)), sqrt(p0 * (1 - p0) + p1 * (1 - p1))
def power(n, p0, p1):                         # normal formula, both tails
    s0, s1 = spreads(p0, p1)
    return Phi(((p1 - p0) * sqrt(n) - za * s0) / s1) + Phi((-(p1 - p0) * sqrt(n) - za * s0) / s1)
def n_need(p0, p1):
    s0, s1 = spreads(p0, p1)
    return ceil(((za * s0 + zb * s1) / (p1 - p0)) ** 2)
def pmf_window(n, p):                         # binomial chances within 12 SDs of the mean, by logs
    m, s = n * p, sqrt(n * p * (1 - p))
    lo, hi = max(0, int(m - 12 * s)), min(n, int(m + 12 * s))
    lg = sum(log(k) for k in range(1, lo + 1)) - sum(log(k) for k in range(n - lo + 1, n + 1))
    out, lp = {}, None
    for k in range(lo, hi + 1):
        lp = (-lg + lo * log(p) + (n - lo) * log(1 - p)) if k == lo else lp + log((n - k + 1) / k * p / (1 - p))
        out[k] = exp(lp)
    return out
def power_exact(n, p0, p1):                   # road 2 for sizing: add every rejecting pair of counts
    f0, f1, tot = pmf_window(n, p0), pmf_window(n, p1), 0.0
    for x1, q1 in f1.items():
        for x0, q0 in f0.items():
            pl = (x0 + x1) / (2 * n)
            if abs(x1 - x0) / n > za * sqrt(pl * (1 - pl) * 2 / n): tot += q1 * q0
    return tot
s0, s1 = spreads(0.05, 0.058); lo, hi = 0.05, 0.07
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if power(NA, 0.05, mid) < 0.80 else (lo, mid)
pf, pe = power(NA, 0.05, 0.058), power_exact(NA, 0.05, 0.058)
print(f"sizing: z(0.975) {za:.6f}, z(0.80) {zb:.6f}, sigma0 {s0:.6f}, sigma1 {s1:.6f}")
print(f"sizing: 0.0500 -> 0.0580: (({za * s0:.6f} + {zb * s1:.6f}) / 0.008)^2 = {((za * s0 + zb * s1) / 0.008) ** 2:.1f}, needs {n_need(0.05, 0.058)} per arm")
print(f"sizing: power at {NA} per arm, formula {pf:.4f}, exact count {pe:.4f}")
print(f"sizing: smallest lift found with 80% power at {NA} per arm: 0.0500 -> {hi:.5f}")
print(f"sizing: 0.0500 -> 0.0550 needs {n_need(0.05, 0.055)} per arm; power at {NA} per arm {power(NA, 0.05, 0.055):.4f}")
ns = list(range(2000, 22000, 2000))
print("figure, gap bin starts (points)", " ".join(f"{-0.2 + 0.2 * i:.1f}" for i in range(10)))
print("figure, lotteries per bin", " ".join(str(c) for c in bins))
print("figure, visitors per arm", " ".join(str(n) for n in ns))
print("figure, power at 0.8-point lift", " ".join(f"{power(n, 0.05, 0.058):.2f}" for n in ns))
assert total8 * 8 == len(gaps8) * 4 * (sum(sB) - sum(sA))            # enumeration vs definition of tau
assert abs(v8 - neyman(sA, sB, 4, 4)[3]) < 1e-12 and 2 * in_B == len(gaps8)    # enumeration vs variance formula; Step 1
S8 = neyman(sA, sB, 4, 4); assert v8 < S8[0] / 4 + S8[1] / 4             # usual variance errs on the safe side
assert abs(ms - tau) < 4 * sd / sqrt(R) and abs(sd / sqrt(V) - 1) < 0.15  # simulation vs exact
assert abs(pf - pe) < 0.01                                              # formula vs exact count
assert power(n_need(0.05, 0.058), 0.05, 0.058) >= 0.80 > power(n_need(0.05, 0.058) - 1, 0.05, 0.058)
assert abs(za - 1.959963984540054) < 1e-9                               # published 97.5% point
assert cover / R > 0.93                                                 # coverage by lottery
print("all checks passed")
