# Uniform law for a bus due any time in a 10-minute window: formulas, integration, simulation.
import math
A, B, N = 0.0, 10.0, 100000              # window starts at minute 0, ends at minute 10; draws
W = B - A
def f(x): return 1.0 / W if A <= x <= B else 0.0     # density: chance per minute
def F(x): return min(1.0, max(0.0, (x - A) / W))     # cumulative chance of waiting at most x
def Q(u): return A + W * u                           # quantile: wait reached with chance u
def simpson(g, lo, hi, n=10):                        # Simpson's rule, n even
    h = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4 if k % 2 else 2) * g(lo + k * h) for k in range(1, n))
    return s * h / 3
def bisect(u, lo=A, hi=B):                           # solve F(x) = u by halving
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if F(mid) < u else (lo, mid)
    return (lo + hi) / 2
M64 = 2 ** 64 - 1
state = 20260928                                     # SplitMix64 seed
def rnd():                                           # one uniform draw in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
def se_p(p): return math.sqrt(p * (1 - p) / N)
waits = [A + W * rnd() for _ in range(N)]            # the bus waits, scaled from [0, 1)
print(f"law,a {A:.0f},b {B:.0f},density {1 / W:.4f} per minute,draws {N},splitmix64 seed 20260928")
# chances are lengths
p3 = sum(1 for x in waits if x <= 3) / N
p47 = sum(1 for x in waits if 4 <= x <= 7) / N
print(f"chance wait<=3,formula {F(3):.4f},sim {p3:.4f},se {se_p(p3):.4f}")
print(f"chance 4<=wait<=7,formula {F(7) - F(4):.4f},sim {p47:.4f},se {se_p(p47):.4f}")
# mean, second moment, variance: formula, Simpson, simulation
mean_f, m2_f = (A + B) / 2, (A * A + A * B + B * B) / 3
var_f = W * W / 12
mean_i = simpson(lambda x: x * f(x), A, B)
m2_i = simpson(lambda x: x * x * f(x), A, B)
var_i = m2_i - mean_i ** 2
mean_s = sum(waits) / N
var_s = sum((x - mean_s) ** 2 for x in waits) / (N - 1)
m4_s = sum((x - mean_s) ** 4 for x in waits) / N
se_mean, se_var = math.sqrt(var_s / N), math.sqrt((m4_s - var_s ** 2) / N)
print(f"mean,formula {mean_f:.4f},simpson {mean_i:.4f},sim {mean_s:.4f},se {se_mean:.4f}")
print(f"second moment,formula {m2_f:.4f},simpson {m2_i:.4f}")
print(f"variance,formula {var_f:.4f},simpson {var_i:.4f},sim {var_s:.4f},se {se_var:.4f}")
sd_f = math.sqrt(var_f)
p1sd = sum(1 for x in waits if abs(x - mean_f) <= sd_f) / N
print(f"sd,formula {sd_f:.4f},sim {math.sqrt(var_s):.4f}")
print(f"chance within one sd,formula {2 * sd_f / W:.4f},sim {p1sd:.4f},se {se_p(p1sd):.4f}")
assert abs(mean_i - mean_f) < 1e-9
assert abs(var_i - var_f) < 1e-9
assert abs(mean_s - mean_f) < 4 * se_mean
assert abs(var_s - var_f) < 4 * se_var
# quantiles: formula, bisection on F, sorted sample
srt = sorted(waits)
for u in (0.25, 0.5, 0.9):
    qs, se_q = srt[int(u * N)], math.sqrt(u * (1 - u) / N) * W
    print(f"quantile u={u:.2f},formula {Q(u):.4f},bisection {bisect(u):.4f},sim {qs:.4f},se {se_q:.4f}")
    assert abs(bisect(u) - Q(u)) < 1e-9
    assert abs(qs - Q(u)) < 4 * se_q
# grids: n equally spaced midpoints, each with chance 1/n
for n in (10, 100):
    pts = [A + W * (k + 0.5) / n for k in range(n)]
    gm = sum(pts) / n
    gv = sum((x - gm) ** 2 for x in pts) / n
    print(f"grid n={n},mean {gm:.4f},variance {gv:.4f},gap to 8.3333 {var_f - gv:.4f}")
    assert abs(gv - var_f * (1 - 1 / n ** 2)) < 1e-9
# histogram of the simulated waits, fraction per one-minute bin
hist = [0] * 10
for x in waits: hist[min(9, int(x))] += 1
print("histogram per minute," + ",".join(f"{h / N:.4f}" for h in hist))
# already waited 4 minutes
late = [x for x in waits if x > 4]
pc = sum(1 for x in late if x <= 7) / len(late)
rem = sum(x - 4 for x in late) / len(late)
print(f"given wait>4,chance wait<=7 formula {(F(7) - F(4)) / (1 - F(4)):.4f},sim {pc:.4f}")
print(f"given wait>4,mean still to wait formula {(B - 4) / 2:.4f},sim {rem:.4f},count {len(late)}")
assert abs(rem - (B - 4) / 2) < 4 * math.sqrt((B - 4) ** 2 / 12 / len(late))
# inverse transform: exponential waits with mean 5 from the same generator
us = [rnd() for _ in range(N)]
ex = [-5 * math.log(1 - u) for u in us]
ex_m = sum(ex) / N
ex_se = math.sqrt(sum((x - ex_m) ** 2 for x in ex) / (N - 1) / N)
ex_p = sum(1 for x in ex if x <= 5) / N
print(f"inverse transform,exponential mean formula 5.0000,sim {ex_m:.4f},se {ex_se:.4f}")
print(f"inverse transform,chance <=5 formula {1 - math.exp(-1):.4f},sim {ex_p:.4f},se {se_p(ex_p):.4f}")
assert abs(ex_m - 5) < 4 * ex_se
assert abs(ex_p - (1 - math.exp(-1))) < 4 * se_p(ex_p)
print(f"aside,30-second window density {1 / 0.5:.4f} per minute,rounding error width 1 variance {1 / 12:.4f}")
# what breaks
wrong_cdf = sum(1 - math.exp(-u / 5) for u in us) / N
sq = sum(-5 * math.log(1 - u * u) for u in us) / N
print(f"break,sd as (b-a)/12 {W / 12:.4f},right {sd_f:.4f}")
print(f"break,variance of whole minutes 0..10 {sum((k - 5) ** 2 for k in range(11)) / 11:.4f},right {var_f:.4f}")
print(f"break,U fed to F not Q mean exact {1 - 5 * (1 - math.exp(-0.2)):.4f},sim {wrong_cdf:.4f},right 5.0000")
print(f"break,U^2 fed to Q mean exact {10 - 10 * math.log(2):.4f},sim {sq:.4f},right 5.0000")
# figure: exponential CDF 1 - exp(-x/5), x 0..20 min -> px 40..340; u 0..1 -> px 200..30
px = lambda x: 40 + 15 * x
py = lambda u: 200 - 170 * u
pts = " ".join(f"{px(x):.1f},{py(1 - math.exp(-x / 5)):.1f}" for x in range(0, 21, 2))
xq = -5 * math.log(1 - 0.7)
print("figure,scale 15 per minute across,170 per unit of chance up,curve " + pts)
print(f"figure,u=0.70 at y {py(0.7):.1f},x {xq:.4f} min at px {px(xq):.1f}")
