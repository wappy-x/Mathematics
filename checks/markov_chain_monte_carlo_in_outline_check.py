# MCMC in outline -- the check behind the card.  Standard library only.  A new coin shows
# 7 heads in 10 flips; with a flat prior its posterior is Beta(8, 4).  Road 1: exact, by
# counting.  Road 2: Simpson's rule on p^7 (1 - p)^3.  Road 3: a Metropolis random walk.
# Road 4: independent draws (the 8th smallest of 11 uniforms).  Road 5: the same walk on a
# grid of 99 points, its whole distribution pushed forward exactly, step by step.
from math import comb, sqrt, exp

MASK, state = (1 << 64) - 1, 20260929

def splitmix():                      # SplitMix64, written out: the same stream in Rust
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

def unif(): return ((splitmix() >> 11) + 0.5) / 2.0 ** 53

def pw(x, k):                        # x multiplied in k times, the same way in both languages
    r = 1.0
    for _ in range(k): r *= x
    return r

def total(xs):                       # plain running sum, as Rust does it
    t = 0.0
    for x in xs: t += x
    return t

def f(p): return pw(p, 7) * pw(1 - p, 3) if 0 < p < 1 else 0.0   # flat prior x likelihood
def f_tri(p): return f(p) * min(p, 1 - p)                        # prior peaked at a fair coin

def cdf(x):                          # Beta(8,4) by counting: at least 8 of 11 uniforms below x
    return total([comb(11, k) * pw(x, k) * pw(1 - x, 11 - k) for k in range(8, 12)])

def quantile(c):                     # bisection on the counted CDF
    lo, hi = 0.0, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if cdf(mid) < c else (lo, mid)
    return (lo + hi) / 2

def simpson(g, n=2000):              # the area under g on [0, 1]
    h = 1.0 / n
    return h / 3 * total([(1 if i in (0, n) else 4 if i % 2 else 2) * g(i * h) for i in range(n + 1)])

def walk(target, h, n, burn, show=0):
    p, fp, acc, out = 0.5, target(0.5), 0, []
    for t in range(burn + n):
        u = unif(); prop = p + h * (2 * u - 1)   # propose: a step of up to h either way
        fq, v = target(prop), unif()
        ok = v < fq / fp                          # accept with chance min(1, f(p') / f(p))
        if t < show:
            print(f"  step {t + 1}: at {p:.4f}, u {u:.4f}, propose {prop:.4f}, ratio {fq / fp:.4f}, "
                  f"draw {v:.4f}, {'move' if ok else 'stay'}")
        if ok: p, fp, acc = prop, fq, acc + 1
        if t >= burn: out.append(p)
    return out, acc / (burn + n)

def summary(xs, batches=100):        # mean, spread, batch-means standard error, effective size
    n, m = len(xs), total(xs) / len(xs)
    var = total([(x - m) * (x - m) for x in xs]) / (n - 1)
    k = n // batches
    bm = [total(xs[b * k:(b + 1) * k]) / k for b in range(batches)]
    se = sqrt(total([(b - m) * (b - m) for b in bm]) / (batches - 1) / batches)
    return m, sqrt(var), se, var / (se * se)

Z_exact = 1 / (4 * comb(11, 4))              # 7! 3! / 11! = 1 / 1320
Z_simp = simpson(f)
mean_x, sd_x = 8 / 12, sqrt(8 * 4 / (12 * 12 * 13))
up_x = 1 - total([comb(11, k) for k in range(8, 12)]) / 2 ** 11
lo_x, hi_x = quantile(0.025), quantile(0.975)
print(f"road 1, exact, Beta(8, 4): mean {mean_x:.6f}, sd {sd_x:.6f}, P(p > 0.5) = 1 - 232/2048 = {up_x:.6f}")
print(f"  95% credible interval {lo_x:.4f} to {hi_x:.4f}; Z = 1/1320 = {Z_exact:.9f}")
print(f"road 2, Simpson: Z {Z_simp:.9f}, mean {simpson(lambda p: p * f(p)) / Z_simp:.6f}")
print("road 3, Metropolis, step h = 0.25, start 0.5; the first five steps:")
N, BURN = 100000, 1000
ch, acc = walk(f, 0.25, N, BURN, show=5)
m3, s3, se3, ess3 = summary(ch)
up = [1.0 if x > 0.5 else 0.0 for x in ch]
u3, _, seu, _ = summary(up)
print(f"  {N} kept after {BURN} burn-in, acceptance {acc:.4f}")
print(f"  mean {m3:.4f} (SE {se3:.4f}), sd {s3:.4f}, P(p > 0.5) {u3:.4f} (SE {seu:.4f})")
print(f"  95% interval {sorted(ch)[int(0.025 * N)]:.4f} to {sorted(ch)[int(0.975 * N)]:.4f}")
print(f"  batch means over 100 batches: effective sample size {ess3:.0f}; naive SE sd/root N {s3 / sqrt(N):.4f}")
iid = [sorted(unif() for _ in range(11))[7] for _ in range(20000)]
m4, s4, _, _ = summary(iid)
print(f"road 4, 20000 independent draws, 8th smallest of 11 uniforms: mean {m4:.4f} (SE {s4 / sqrt(20000):.4f}), sd {s4:.4f}")
print("chart, bin from:  " + " ".join(f"{b / 10:.1f}" for b in range(10)))
print("chart, exact %:   " + " ".join(f"{100 * (cdf((b + 1) / 10) - cdf(b / 10)):.2f}" for b in range(10)))
print("chart, chain %:   " + " ".join(f"{100 * total([1.0 for x in ch if b / 10 <= x < (b + 1) / 10]) / N:.2f}"
                                       for b in range(10)))

G = [i / 100 for i in range(1, 100)]         # road 5: the walk on a grid, steps of 1 to 10 cells
wg = [f(p) for p in G]
tgt = [w / total(wg) for w in wg]
def grid_step(d):
    new = [0.0] * 99
    for i in range(99):
        for k in [i + j for j in range(-10, 11) if j != 0]:
            a = min(1.0, wg[k] / wg[i]) if 0 <= k < 99 else 0.0
            if a > 0: new[k] += d[i] * a / 20
            new[i] += d[i] * (1 - a) / 20
    return new
d, tv = [1.0 if i == 0 else 0.0 for i in range(99)], []   # start at p = 0.01, deep in the tail
for s in range(201):
    if s in (0, 5, 10, 20, 50, 100, 200):
        tv.append((s, total([abs(a - b) for a, b in zip(d, tgt)]) / 2))
    d = grid_step(d)
P = [grid_step([1.0 if j == i else 0.0 for j in range(99)]) for i in range(99)]   # row i: one step from state i
flow = max(abs(tgt[i] * P[i][k] - tgt[k] * P[k][i]) for i in range(99) for k in range(99))
still = max(abs(a - b) for a, b in zip(grid_step(tgt), tgt))
print(f"road 5, grid of 99 points, steps of 1 to 10 cells, start 0.01: largest flow imbalance {flow:.1e}; one step moves the posterior by {still:.1e}")
print("chart, grid steps:    " + " ".join(f"{s}" for s, _ in tv))
print("chart, distance left: " + " ".join(f"{v:.3f}" for _, v in tv))

mt_x = simpson(lambda p: p * f_tri(p)) / simpson(f_tri)
mt, st, set_, _ = summary(walk(f_tri, 0.25, N, BURN)[0])
print(f"second case, prior min(p, 1 - p): Simpson mean {mt_x:.4f}; chain mean {mt:.4f} (SE {set_:.4f})")

print("what breaks")
kept = [x for i, x in enumerate(ch) if i == 0 or x != ch[i - 1]]
mk, sk, sek, _ = summary(kept)
print(f"  repeats dropped: {len(kept)} moves, mean {mk:.4f} (SE {sek:.4f}), sd {sk:.4f}")
def f_logit(t): return f(1 / (1 + exp(-t)))  # walk on log-odds, no Jacobian correction
chl, _ = walk(f_logit, 1.0, N, BURN)
ml, _, sel, _ = summary([1 / (1 + exp(-t)) for t in chl])
print(f"  log-odds walk, no Jacobian: mean {ml:.4f} (SE {sel:.4f}); Beta(7, 3) mean {7 / 10:.4f}")
chs, accs = walk(f, 0.002, 2000, 0)
ms, _, ses, esss = summary(chs, 20)
print(f"  step 0.002, 2000 steps: acceptance {accs:.4f}, mean {ms:.4f} (SE {ses:.4f}), ESS {esss:.0f}")

assert abs(Z_simp - Z_exact) < 1e-12 and abs(simpson(lambda p: p * f(p)) / Z_simp - mean_x) < 1e-9, "Simpson vs factorials"
assert abs(m3 - mean_x) < 4 * se3 and abs(u3 - up_x) < 4 * seu, "chain vs exact, within 4 SE"
assert abs(m4 - mean_x) < 4 * s4 / sqrt(20000), "independent draws vs exact"
assert s3 / sqrt(N) < se3, "correlated draws: naive SE must understate the batch-means SE"
assert flow < 1e-15 and still < 1e-15 and tv[-1][1] < 0.01 < tv[2][1], "grid: balance, stillness, forgetting"
assert abs(mt - mt_x) < 4 * set_, "second prior: chain vs Simpson"
assert abs(ml - 0.7) < 4 * sel and abs(ml - mean_x) > 4 * sel, "missing Jacobian lands on Beta(7, 3)"
print("ALL CHECKS PASS")
