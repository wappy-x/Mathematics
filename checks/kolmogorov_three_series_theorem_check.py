# Kolmogorov's three-series theorem -- the check behind the card.  Standard library only.
# Fair signs e_n = +1 or -1.  Series A: sum e_n/n, variances 1/n^2.  Series B: sum e_n/sqrt(n),
# variances 1/n.  Roads: all 2^16 sign patterns counted exactly, against Kolmogorov's maximal
# inequality; partial sums bracketed by the integral test, against pi^2/6; 1000 simulated
# runs (SplitMix64, seed 20261123) against the spreads and both inequalities; the three
# series for four examples, with a telescoping product against a direct product.
from fractions import Fraction as Q
from math import sqrt, pi, log

print("sum of 1/n^2 to N, integral-test bracket for pi^2/6; sum of 1/n to N, bracket [ln(N+1), 1 + ln N]")
v2, h1, brk, n = 0.0, 0.0, [], 0
for N in (16, 100, 1000, 10000, 1000000):
    while n < N:
        n += 1
        v2 += 1.0 / (n * n)
        h1 += 1.0 / n
    brk.append((v2 + 1 / (N + 1), v2 + 1 / N, log(N + 1), h1, 1 + log(N)))
    print(f"N={N:7d}: sum 1/n^2 {v2:.6f}, pi^2/6 in [{v2 + 1 / (N + 1):.6f}, {v2 + 1 / N:.6f}];"
          f" sum 1/n {h1:.4f}")
Z2 = pi * pi / 6
print(f"pi^2/6 = {Z2:.6f}; sd of the limit of series A = sqrt(pi^2/6) = {sqrt(Z2):.4f}")

K, L = 16, 720720                                       # L = lcm(1..16): sums become integers
step = [L // k for k in range(1, K + 1)]
LAM = (Q(3, 2), Q(2), Q(5, 2), Q(3))
hit_max, hit_end, s2sum, s2hit = [0] * 4, [0] * 4, 0, 0
for mask in range(1 << K):
    s = mx = 0
    for k in range(K):
        s += step[k] if mask >> k & 1 else -step[k]
        mx = max(mx, abs(s))
    s2sum += s * s
    for i, lam in enumerate(LAM):
        hit_max[i] += mx >= lam * L
        hit_end[i] += abs(s) >= lam * L
    if mx >= 2 * L:
        s2hit += s * s
V16 = sum(Q(1, k * k) for k in range(1, K + 1))
print(f"series A, n = 16, all 65536 sign patterns: Var(S_16) = {float(V16):.6f}, counted "
      f"{float(Q(s2sum, L * L << K)):.6f}")
print("lambda, P(|S_16| >= lambda), P(max_k<=16 |S_k| >= lambda), bound Var(S_16)/lambda^2")
for i, lam in enumerate(LAM):
    print(f"{float(lam):.1f}: {hit_end[i] / 65536:.6f} {hit_max[i] / 65536:.6f} {float(V16 / lam ** 2):.6f}")
print(f"lambda = 2: E[S_16^2 on the crossing set] = {s2hit / L / L / 65536:.6f} >= "
      f"4 P(crossing) = {4 * hit_max[1] / 65536:.6f}")

M64 = (1 << 64) - 1
state = 20261123
def draw():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

RUNS, N = 1000, 10000
CHART = (10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000)
SPREAD = (100, 1000, 10000)
a = [0.0] + [1.0 / k for k in range(1, N + 1)]
b = [0.0] + [1.0 / sqrt(k) for k in range(1, N + 1)]
sq = {m: [0.0, 0.0] for m in SPREAD}
osc_hits, stay_hits, d_sum, d_sq = 0, 0, 0.0, 0.0
for r in range(RUNS):
    sa = sb = sd = 0.0
    sa1000, osc, bmax, pa, pb = 0.0, 0.0, 0.0, [], []
    for k in range(1, N + 1):
        z = draw()
        e = 1.0 if z >> 63 else -1.0                 # fair sign from the top bit
        sa += e * a[k]
        sb += e * b[k]
        sd += (-1.0 if z >> 62 == 0 else 1.0) * a[k]  # + with chance 3/4: series D
        bmax = max(bmax, abs(sb))
        if k == 1000:
            sa1000 = sa
        elif k > 1000:
            osc = max(osc, abs(sa - sa1000))
        if k in sq:
            sq[k][0] += sa * sa
            sq[k][1] += sb * sb
        if r == 0 and k in CHART:
            pa.append(sa)
            pb.append(sb)
    osc_hits += osc >= 0.05
    stay_hits += bmax <= 1.5
    d_sum += sd
    d_sq += sd * sd
    if r == 0:
        print("run 1, same signs: n, series A, series B")
        for m, x, y in zip(CHART, pa, pb):
            print(f"{m:5d}: {x:8.4f} {y:8.4f}")
        print("figure A:", ", ".join(f"{x:.2f}" for x in pa))
        print("figure B:", ", ".join(f"{y:.2f}" for y in pb))
print(f"{RUNS} runs: n, spread of S_n for A (simulated, sqrt sum 1/k^2), for B (simulated, sqrt sum 1/k)")
va = vb = 0.0
spread = []
for k in range(1, N + 1):
    va += 1.0 / (k * k)
    vb += 1.0 / k
    if k == 1000:
        va1000 = va
    if k in sq:
        ra, rb = sqrt(sq[k][0] / RUNS), sqrt(sq[k][1] / RUNS)
        spread.append((ra, sqrt(va), rb, sqrt(vb)))
        print(f"{k:5d}: A {ra:.4f} {sqrt(va):.4f}   B {rb:.4f} {sqrt(vb):.4f}")
tail = va - va1000
print(f"A: share of runs with max over 1000<k<=10000 of |S_k - S_1000| >= 0.05: {osc_hits / RUNS:.3f};"
      f" bound {tail:.7f}/0.05^2 = {tail / 0.0025:.4f}")
print(f"B: share of runs with max over k<=10000 of |S_k| <= 1.5: {stay_hits / RUNS:.3f};"
      f" converse bound (1.5+1)^2/{vb:.4f} = {6.25 / vb:.4f}")
print(f"B: the same converse bound at n = 1000000: 6.25/{h1:.4f} = {6.25 / h1:.4f}")
print("three series, truncation level 1: sum P(|X_n|>1), sum E[Y_n], sum Var(Y_n) -> verdict")
print(f"A  +-1/n          : 0, 0, {Z2:.4f} -> converges")
print(f"B  +-1/sqrt(n)    : 0, 0, infinite ({h1:.4f} by n = 1000000) -> diverges")
print(f"C  n^2 w.p. 1/n^2 : {Z2 - 1:.4f}, 1, 0 -> converges (sum Var(X_n) = sum (n^2 - 1) is infinite)")
print(f"D  +1/n w.p. 3/4  : 0, infinite ({h1 / 2:.4f} by n = 1000000), {0.75 * Z2:.4f} -> diverges")
prod = 1.0
for k in range(2, N + 1):
    prod *= 1.0 - 1.0 / (k * k)
print(f"C: P(no jump for 2<=n<={N}) = product {prod:.6f}, telescoped (N+1)/(2N) = {(N + 1) / (2 * N):.6f}")
dm, dsd = d_sum / RUNS, sqrt(d_sq / RUNS - (d_sum / RUNS) ** 2)
print(f"D: {RUNS} runs, mean of S_10000 {dm:.4f} (sum of means {vb / 2:.4f}), sd {dsd:.4f}"
      f" (sqrt of sum 3/(4k^2) {sqrt(0.75 * va):.4f})")
print(f"Kolmogorov's strong law, fair die: sum Var((X_n - 3.5)/n) = (35/12)(pi^2/6) = {35 / 12 * Z2:.6f}")

assert all(lo <= Z2 <= hi and l1 <= h <= u1 for lo, hi, l1, h, u1 in brk)  # series vs closed forms
assert s2sum == sum(t * t for t in step) << K                    # Var(S_16): count vs formula
assert all(hit_end[i] <= hit_max[i] <= V16 / lam ** 2 * 65536 for i, lam in enumerate(LAM))
assert s2hit >= 4 * L * L * hit_max[1]                           # the proof's key step, counted
assert all(abs(ra / ta - 1) < 0.1 and abs(rb / tb - 1) < 0.1 for ra, ta, rb, tb in spread)
assert osc_hits / RUNS <= tail / 0.0025 and stay_hits / RUNS <= 6.25 / vb  # both inequalities
assert abs(prod - (N + 1) / (2 * N)) < 1e-9                      # product vs telescoping
assert abs(dm - vb / 2) < 4 * sqrt(0.75 * va / RUNS)              # simulation vs sum of means
print("ALL CHECKS PASS")
