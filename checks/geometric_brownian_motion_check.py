# Geometric Brownian motion -- the check behind the card.  Only math is imported.
# A share at $100, drift mu = 0.05 a year, volatility sigma = 0.20 a year.
# Roads to the mean and median of the price after T years: the formulas; the
# exact law of a coin-flip model, n multiplying steps a year, every path
# counted; and 20000 simulated years of 252 daily steps (SplitMix64, Box-Muller).
import math
S0, MU, SIG, T = 100.0, 0.05, 0.20, 1.0
SEED, PATHS, DAYS = 20260930, 20000, 252
MASK, state = (1 << 64) - 1, SEED
def uniform():                            # SplitMix64, a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def normal_pair():                        # Box-Muller: two independent standard normals
    r = math.sqrt(-2.0 * math.log(1.0 - uniform()))
    th = 2.0 * math.pi * uniform()
    return r * math.cos(th), r * math.sin(th)
def phi(x): return math.exp(-0.5 * x * x) / math.sqrt(2.0 * math.pi)
def Phi(x):                               # area under the bell left of x, Simpson's rule
    n, h = 2000, x / 2000
    s = phi(0.0) + phi(x) + sum((4 if i % 2 else 2) * phi(i * h) for i in range(1, n))
    return 0.5 + s * h / 3.0

def mean_f(t): return S0 * math.exp(MU * t)                       # the card's formulas
def median_f(t): return S0 * math.exp((MU - 0.5 * SIG * SIG) * t)

def coin_flips(n, t):                     # n steps, each x(1 + a + b) or x(1 + a - b), chance 1/2
    a, b = MU * t / n, SIG * math.sqrt(t / n)
    lu, ld, lw = math.log(1 + a + b), math.log(1 + a - b), -n * math.log(2.0)
    mean, cum, med = 0.0, 0.0, None
    for k in range(n + 1):                # k up-steps; prices rise with k
        v, w = S0 * math.exp(k * lu + (n - k) * ld), math.exp(lw)
        mean, cum = mean + w * v, cum + w
        if med is None and cum >= 0.5: med = v
        if k < n: lw += math.log(n - k) - math.log(k + 1)
    return mean, med

def increments(days):                     # Brownian increments on a daily grid
    incs = []
    for _ in range(days // 2): incs.extend(math.sqrt(T / DAYS) * z for z in normal_pair())
    return incs

def product(incs, per):                   # steps of x(1 + mu dt + sigma dW), dW summed per step
    s, k = S0, len(incs) // per
    for j in range(k): s *= 1 + MU * len(incs) / DAYS / k + SIG * sum(incs[j * per:(j + 1) * per])
    return s

def avg_se(xs):
    m = sum(xs) / len(xs)
    return m, math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))
def frac_se(flags):
    q = sum(flags) / len(flags)
    return q, math.sqrt(q * (1 - q) / len(flags))
def out(label, v): print(f"{label:<40} {v:>11.6f}")

print("share 100, mu 0.05, sigma 0.20, T 1 year")
out("1 formula: mean S0 e^(mu T)", mean_f(T))
out("1 formula: median S0 e^((mu - s^2/2)T)", median_f(T))
out("  mean / median = e^(s^2 T / 2)", mean_f(T) / median_f(T))
out("  sd of S_T", mean_f(T) * math.sqrt(math.exp(SIG * SIG * T) - 1))
out("  P(S_T < mean) = Phi(s sqrt(T) / 2)", Phi(SIG * math.sqrt(T) / 2))
out("  P(S_T < 100)", Phi(-(MU - 0.5 * SIG * SIG) * math.sqrt(T) / SIG))
print("2 coin flips: steps a year, mean, error, median, error")
cf = {}
for n in (4, 12, 52, 252, 2520):
    m, md = coin_flips(n, T)
    cf[n] = (m - mean_f(T), md - median_f(T))
    print(f"  {n:>5} {m:>11.6f} {cf[n][0]:>+10.6f} {md:>11.6f} {cf[n][1]:>+10.6f}")

blocks = {1: 252, 12: 21, 63: 4, 252: 1}  # steps a year: days per step
ends, logs, gaps = [], [], {k: 0.0 for k in blocks}
for p in range(PATHS):
    incs = increments(DAYS)
    if p == 0: qv = sum(x * x for x in incs)
    exact = median_f(T) * math.exp(SIG * sum(incs))
    for k, per in blocks.items(): gaps[k] += abs(product(incs, per) - exact) / PATHS
    s = product(incs, 1)
    ends.append(s); logs.append(math.log(s / S0))
sim_mean, sim_se = avg_se(ends)
srt = sorted(ends); sim_med = 0.5 * (srt[PATHS // 2 - 1] + srt[PATHS // 2])
rk = round(math.sqrt(PATHS) / 2); med_se = (srt[PATHS // 2 + rk] - srt[PATHS // 2 - 1 - rk]) / 2   # order statistics sqrt(N)/2 ranks either side
below_med, bmd_se = frac_se([x < median_f(T) for x in ends])
below_mean, bmn_se = frac_se([x < mean_f(T) for x in ends])
lg, lg_se = avg_se(logs)
print(f"3 simulation, {PATHS} paths x {DAYS} daily steps, seed {SEED}")
print(f"  mean S_T               {sim_mean:>11.6f}  se {sim_se:.6f}")
print(f"  median S_T             {sim_med:>11.6f}  se {med_se:.6f}")
print(f"  share below median     {below_med:>11.6f}  se {bmd_se:.6f}")
print(f"  share below mean       {below_mean:>11.6f}  se {bmn_se:.6f}")
print(f"  mean ln(S_T / S0)      {lg:>11.6f}  se {lg_se:.6f}")
print(f"  path 1: sum of dW^2    {qv:>11.6f}")
print("  mean |product - exponential| by steps a year")
for k in blocks: print(f"  {k:>5} {gaps[k]:>11.6f}")

print("horizon: years, mean, median, P(below mean) formula, simulated, se")
hz = {}
for t in (1, 10, 30, 100):
    flags = []
    for _ in range(PATHS // 2):
        flags.extend(median_f(t) * math.exp(SIG * math.sqrt(t) * z) < mean_f(t) for z in normal_pair())
    q, se = frac_se(flags)
    hz[t] = (Phi(SIG * math.sqrt(t) / 2), q, se)
    print(f"  {t:>4} {mean_f(t):>10.2f} {median_f(t):>9.2f} {hz[t][0]:>9.6f} {q:>9.6f} {se:.6f}")

out("wrong: ordinary chain rule, median", S0 * math.exp(MU * T))
out("wrong: ordinary chain rule, mean", S0 * math.exp((MU + 0.5 * SIG * SIG) * T))
out("wrong: 100 + 5t + 20 W_t, P(< 0) at 25y", Phi(-(S0 + 5 * 25) / (20 * 5)))
out("try: sigma 0.40, median", S0 * math.exp((MU - 0.08) * T))
out("try: sigma 0.40, P(S_T < 100)", Phi(-(MU - 0.08) / 0.40))
out("try: mu 0.02, median", S0 * math.exp(0.02 - 0.02))

years, incs, path = list(range(0, 31, 3)), increments(30 * DAYS), [S0]
for y in years[1:]: path.append(path[-1] * product(incs[(y - 3) * DAYS:y * DAYS], 1) / S0)
print("chart, years       " + " ".join(f"{y:>7d}" for y in years))
print("chart, mean        " + " ".join(f"{mean_f(y):>7.2f}" for y in years))
print("chart, median      " + " ".join(f"{median_f(y):>7.2f}" for y in years))
print("chart, one path    " + " ".join(f"{v:>7.2f}" for v in path))
out("  that path: ln(S_30 / S0) / 30", math.log(path[-1] / S0) / 30)
edges = list(range(50, 170, 10))
zf = lambda x: (math.log(x / S0) - (MU - 0.5 * SIG * SIG) * T) / (SIG * math.sqrt(T))
sim_pct = [100 * sum(lo <= x < lo + 10 for x in ends) / PATHS for lo in edges]
f_pct = [100 * (Phi(zf(lo + 10)) - Phi(zf(lo))) for lo in edges]
print("chart, bin from    " + " ".join(f"{e:>5d}" for e in edges))
print("chart, simulated % " + " ".join(f"{v:>5.2f}" for v in sim_pct))
print("chart, sim se %    " + " ".join(f"{100 * math.sqrt(v / 100 * (1 - v / 100) / PATHS):>5.2f}" for v in sim_pct))
print("chart, formula %   " + " ".join(f"{v:>5.2f}" for v in f_pct))

assert abs(cf[2520][0]) < 1e-4, "coin-flip mean reaches S0 e^(mu T)"
assert abs(cf[2520][1]) < 1e-4, "coin-flip median reaches S0 e^((mu - sigma^2/2) T)"
assert abs(cf[2520][1]) < abs(cf[252][1]) < abs(cf[52][1]) < abs(cf[12][1]), "error shrinks with the step"
assert abs(sim_mean - mean_f(T)) < 4 * sim_se, "simulated mean within 4 se of S0 e^(mu T)"
assert abs(below_med - 0.5) < 4 * bmd_se, "half the simulated years end below the formula median"
assert abs(below_mean - Phi(SIG * math.sqrt(T) / 2)) < 4 * bmn_se, "252-step paths: share below the mean = Phi(sigma sqrt(T) / 2)"
assert abs(lg - (MU - 0.5 * SIG * SIG) * T) < 4 * lg_se, "log grows at mu - sigma^2 / 2"
assert all(abs(f - q) < 4 * se for f, q, se in hz.values()), "P(below mean) = Phi(sigma sqrt(T) / 2)"
assert gaps[252] < gaps[63] < gaps[12] < gaps[1], "products close in on the exponential"
print("ALL CHECKS PASS")
