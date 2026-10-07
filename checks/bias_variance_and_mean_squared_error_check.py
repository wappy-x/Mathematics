# Bias and variance -- the check behind the card; only math is imported.
# A kitchen scale is tested with a 500 g weight, 4 readings, each off by
# noise of SD 4 g around a true offset MU.  The rules: the plain average of
# the offsets, and that average shrunk toward zero by C = 0.8.  Roads: the
# formula, every pattern of a coin-flip noise, and a seeded simulation.
import math

N, SD, MU, C, RUNS, SEED = 4, 4.0, 2.0, 0.8, 200000, 20260928
M64 = 0xFFFFFFFFFFFFFFFF
V = SD * SD / N                             # variance of the average, 16/4

def splitmix64(s):                          # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def uniform(s):                             # a draw in (0, 1] from 53 random bits
    s, z = splitmix64(s)
    return s, ((z >> 11) + 1) * 2.0 ** -53

def mse_formula(c, mu):                     # variance plus squared bias
    return c * c * V + (1 - c) * (1 - c) * mu * mu

def enumerate_rule(c, mu, divisor=None):    # all 16 patterns of +-4 g noise, equally likely
    total, first = 0.0, 0.0
    for pattern in range(2 ** N):
        xs = [mu + (SD if pattern >> i & 1 else -SD) for i in range(N)]
        xb = sum(xs) / N
        if divisor is None:
            t, target = c * xb, mu
        else:
            t, target = sum((x - xb) * (x - xb) for x in xs) / divisor, SD * SD
        total += (t - target) * (t - target) / 2 ** N
        first += t / 2 ** N
    return total, first                     # mean squared error and mean of the rule

def spread(c, mu, mean):                    # enumerated variance about the rule's own mean
    total = 0.0
    for pattern in range(2 ** N):
        xb = sum(mu + (SD if pattern >> i & 1 else -SD) for i in range(N)) / N
        total += (c * xb - mean) * (c * xb - mean) / 2 ** N
    return total

def bisect(f, lo, hi):                      # root finder written out
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

def ternary(f, lo, hi):                     # minimum finder for a bowl-shaped curve
    for _ in range(200):
        a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (a, hi) if f(a) > f(b) else (lo, b)
    return (lo + hi) / 2

def row(label, v):
    print(f"{label:<52} {v:>10.6f}")

offs = [3.0, -1.0, 5.0, 1.0]                # readings 503, 499, 505, 501 minus 500
ob = sum(offs) / len(offs)
s_obs = sum((o - ob) * (o - ob) for o in offs)

names = ["average", "0.8 x average", "plug-in shrink", "S/3", "S/4", "S/5"]
sums, sq = [0.0] * 6, [0.0] * 6
state = SEED
for run in range(RUNS):                     # 4 bell-curve readings per run, Box-Muller
    xs = []
    for _ in range(N // 2):
        state, u1 = uniform(state)
        state, u2 = uniform(state)
        r = math.sqrt(-2.0 * math.log(u1))
        xs += [MU + SD * r * math.cos(2 * math.pi * u2), MU + SD * r * math.sin(2 * math.pi * u2)]
    xb = sum(xs) / N
    s = sum((x - xb) * (x - xb) for x in xs)
    errs = [xb - MU, C * xb - MU, xb * xb / (xb * xb + V) * xb - MU,
            s / 3 - SD * SD, s / 4 - SD * SD, s / 5 - SD * SD]
    for k in range(6):
        sums[k] += errs[k] * errs[k]
        sq[k] += errs[k] ** 4
sim = [t / RUNS for t in sums]
se = [math.sqrt((sq[k] / RUNS - sim[k] * sim[k]) / RUNS) for k in range(6)]

cross = bisect(lambda mu: enumerate_rule(C, mu)[0] - enumerate_rule(1.0, mu)[0], 0.0, 100.0)
c_best = ternary(lambda c: enumerate_rule(c, MU)[0], 0.0, 1.0)
e_avg = enumerate_rule(1.0, MU)[0]
e_shr, e_mean = enumerate_rule(C, MU)
e_var = spread(C, MU, e_mean)
div_formula = {a: SD ** 4 * (2 * (N - 1) + (N - 1 - a) ** 2) / (a * a) for a in (3, 4, 5)}
coin_formula = {a: SD ** 4 * (2 * (N - 1) / N + (N - 1 - a) ** 2) / (a * a) for a in (3, 4, 5)}
# plug-in shrink, a second road: midpoint rule over the bell curve of the average, z from -10 to 10
plug_exact = sum(math.exp(-z * z / 2) * ((x := MU + math.sqrt(V) * z) * x * x / (x * x + V) - MU) ** 2 for z in (-10 + (j + 0.5) / 2000 for j in range(40000))) / 2000 / math.sqrt(2 * math.pi)

print(f"setup: 500 g weight, n = {N} readings, noise SD {SD:.0f} g, true offset {MU:.0f} g, shrink factor {C}")
print(f"worked: readings 503 499 505 501 g, average offset {ob:.2f} g, shrunk {C * ob:.2f} g")
print(f"worked: S = {s_obs:.2f}, S/3 = {s_obs / 3:.4f}, S/4 = {s_obs / 4:.4f}, S/5 = {s_obs / 5:.4f}")
row("formula: variance of the average, 16/4 (SD 2 g)", V)
row("formula: bias of 0.8 x average, (0.8 - 1) x 2", (C - 1) * MU)
row("formula: variance of 0.8 x average, 0.64 x 4", C * C * V)
row("formula: MSE of 0.8 x average, 2.56 + 0.16", mse_formula(C, MU))
row("formula: break-even offset, 2 x sqrt(1.8/0.2)", math.sqrt(V) * math.sqrt((1 + C) / (1 - C)))
row("bisection on enumerated MSEs: where they meet", cross)
row("formula: best factor at offset 2, 4/(4 + 4)", MU * MU / (MU * MU + V))
row("ternary search on enumerated MSE: best factor", c_best)
row("formula: MSE at the best factor", mse_formula(0.5, MU))
row("coin-flip noise, 16 patterns: MSE of average", e_avg)
row("coin-flip: mean of 0.8 x average", e_mean)
row("coin-flip: variance of 0.8 x average", e_var)
row("coin-flip: variance + bias^2", e_var + (e_mean - MU) ** 2)
row("coin-flip: MSE of 0.8 x average, direct", e_shr)
for a in (3, 4, 5):
    row(f"formula, bell noise: MSE of S/{a}", div_formula[a])
print("formula: bias of S/3, S/4, S/5: " + " ".join(f"{SD * SD * (N - 1 - a) / a:.1f}" for a in (3, 4, 5)))
for a in (3, 4, 5):
    row(f"coin-flip noise, 16 patterns: MSE of S/{a}", enumerate_rule(0, MU, a)[0])
print(f"simulated {RUNS:,} runs, bell noise:                  MSE  standard error")
for k in range(6):
    print(f"  {names[k]:<44} {sim[k]:>10.4f} {se[k]:>10.4f}" + (f"  midpoint-rule integral {plug_exact:.6f}" if k == 2 else ""))
row("adding bias, not bias^2: 2.56 + 0.4", C * C * V + abs((C - 1) * MU))
print("chart A, offset, MSE of average, MSE of 0.8 x average")
for mu in range(9):
    print(f"chart A, {mu} {mse_formula(1.0, mu):.2f} {mse_formula(C, mu):.2f}")
print("chart B, factor c at offset 2: variance, bias^2, MSE")
for j in range(11):
    c = j / 10
    print(f"chart B, {c:.1f} {c * c * V:.2f} {(1 - c) ** 2 * MU * MU:.2f} {mse_formula(c, MU):.2f}")

assert abs(e_avg - V) < 1e-12, "enumerated MSE of the average vs sigma^2/n"
assert abs(e_shr - mse_formula(C, MU)) < 1e-12, "enumerated MSE vs variance + bias^2 formula"
assert abs(e_var + (e_mean - MU) ** 2 - e_shr) < 1e-12, "enumerated spread + bias^2 vs direct MSE"
assert abs(cross - math.sqrt(V * (1 + C) / (1 - C))) < 1e-9, "bisection root vs break-even formula"
assert abs(c_best - MU * MU / (MU * MU + V)) < 1e-6, "searched best factor vs formula"
for a in (3, 4, 5):
    assert abs(enumerate_rule(0, MU, a)[0] - coin_formula[a]) < 1e-9, "coin-flip MSE of S/a vs formula"
for k, target in ((0, V), (1, mse_formula(C, MU)), (2, plug_exact), (3, div_formula[3]), (4, div_formula[4]),
                  (5, div_formula[5])):
    assert abs(sim[k] - target) < 4 * se[k], "simulated MSE vs formula: " + names[k]
assert sim[1] + 10 * se[1] < sim[0], "the biased rule beats the unbiased one"
print("ALL CHECKS PASS")
