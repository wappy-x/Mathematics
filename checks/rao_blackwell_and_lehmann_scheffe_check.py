# Rao-Blackwell and Lehmann-Scheffe -- the check behind the card.
# Five hours of help-desk calls: 2, 3, 0, 1, 4, total T = 10.  Each hour's count
# is Poisson with unknown rate lam; the target e^(-lam) is the chance of an empty
# hour.  Roads: closed forms; every split of a total; a simulation; a search.
from math import exp, factorial, lgamma, log, prod
M64, state = 2**64 - 1, 20261123

def next64():                                  # SplitMix64 with a stated seed
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

def unif(): return (next64() >> 11) / 2**53

def draw(lam):                                 # Poisson count by inversion
    u, k, p = unif(), 0, exp(-lam)
    c = p
    while u > c:
        k += 1
        p *= lam / k
        c += p
    return k

def pois(lam, k): return exp(-lam) * lam**k / factorial(k)

def splits(t, parts):                          # every ordered way to share t calls
    if parts == 1:
        yield (t,)
        return
    for first in range(t + 1):
        for rest in splits(t - first, parts - 1):
            yield (first,) + rest

def row(label, x): print(f"{label:<46}{x:.6f}")

N, counts, LAM = 5, [2, 3, 0, 1, 4], 2.0; T = sum(counts)
crude = 1.0 if counts[0] == 0 else 0.0
frac = sum(1 for c in counts if c == 0) / N
rb = (1 - 1 / N) ** T
print("data: counts 2 3 0 1 4, total T =", T)
row("crude rule: was hour 1 empty?", crude)
row("fraction of empty hours", frac)
row("plug-in e^(-T/5)", exp(-T / N))
row("1 Rao-Blackwell (4/5)^T, formula", rb)

def cond_mean(rule, t, lam):                   # E[rule | T = t] from the definition
    num = den = 0.0
    for x in splits(t, N):
        w = prod(pois(lam, xi) for xi in x)
        num += rule(x) * w
        den += w
    return num / den
first = lambda x: 1.0 if x[0] == 0 else 0.0
share = lambda x: sum(1 for xi in x if xi == 0) / N
for lam in (0.7, 2.0, 3.5):
    row(f"2 E[crude | T=10] by enumeration, lam={lam}", cond_mean(first, T, lam))
    assert abs(cond_mean(first, T, lam) - rb) < 1e-12
row("2 E[fraction | T=10] by enumeration", cond_mean(share, T, LAM))
assert abs(cond_mean(share, T, LAM) - rb) < 1e-12

theta = exp(-LAM)                              # moments at the true rate lam = 2
pT = [pois(N * LAM, t) for t in range(120)]
m = [(1 - 1 / N) ** t for t in range(120)]
mean_rb = sum(p * v for p, v in zip(pT, m))
var_rb = sum(p * v * v for p, v in zip(pT, m)) - mean_rb**2
inner = sum(p * (v - v * v) for p, v in zip(pT, m))   # E[Var(crude | T)]
var_crude, var_frac = theta * (1 - theta), theta * (1 - theta) / N
var_form = exp(-2 * LAM) * (exp(LAM / N) - 1)
cr = LAM * exp(-2 * LAM) / N
plug = sum(p * exp(-t / N) for t, p in enumerate(pT))
print("at true rate lam = 2, target e^(-2) =", f"{theta:.6f}")
row("mean of (4/5)^T, sum over T", mean_rb)
print(f"  e^(-2 lam) = {exp(-2 * LAM):.6f}  e^(lam/n) - 1 = {exp(LAM / N) - 1:.6f}  1 - theta = {1 - theta:.6f}")
row("variance of crude rule theta(1-theta)", var_crude)
row("  average leftover variance E[Var(W|T)]", inner)
row("  variance of (4/5)^T, sum over T", var_rb)
row("  variance of (4/5)^T, formula", var_form)
row("variance of fraction of empty hours", var_frac)
row("Cramer-Rao floor lam e^(-2 lam)/n", cr)
row("efficiency floor / variance of (4/5)^T", cr / var_rb)
row("mean of plug-in e^(-T/5), sum over T", plug)
row("  closed form exp(n lam (e^(-1/n) - 1))", exp(N * LAM * (exp(-1 / N) - 1)))
assert abs(mean_rb - theta) < 1e-12 and abs(var_rb - var_form) < 1e-12
assert abs(inner + var_rb - var_crude) < 1e-12
assert var_rb > cr and var_rb < var_frac < var_crude and plug - theta > 0.02
row("E[crude | X2] at lam = 1 (not a statistic)", pois(1.0, 0))   # hour 2 says nothing
row("E[crude | X2] at lam = 2", pois(2.0, 0))                        # about hour 1

R, s = 200000, [[0.0, 0.0] for _ in range(3)]  # crude, fraction, (4/5)^T
for _ in range(R):
    x = [draw(LAM) for _ in range(N)]
    for i, v in enumerate((first(x), share(x), (1 - 1 / N) ** sum(x))):
        s[i][0] += v
        s[i][1] += v * v
for name, (a, b), exact in zip(("crude", "fraction", "(4/5)^T"), s, (var_crude, var_frac, var_rb)):
    mu, var = a / R, b / R - (a / R) ** 2
    print(f"3 simulated {name:<9} mean {mu:.6f}  variance {var:.6f}")
    assert abs(mu - theta) < 4 * (var / R) ** 0.5 and abs(var - exact) < 0.05 * exact

groups, best, worst_bias = [], 1.0, 0.0       # search: (4/5)^T plus noise, t <= 8
for t in range(9):
    groups.append((t, [factorial(t) / (N**t * prod(factorial(v) for v in x)) for x in splits(t, N)]))
for _ in range(300):
    noise, size = [], 0.2 * unif()
    for t, wt in groups:
        u = [size * (2 * unif() - 1) for _ in wt]
        c = sum(a * b for a, b in zip(u, wt))
        noise.append([a - c for a in u])       # averages zero given T = t
    ex2 = sum(pT[t] * m[t] ** 2 for t in range(9, 120))
    for (t, wt), u in zip(groups, noise):
        ex2 += pT[t] * sum(w * (m[t] + a) ** 2 for w, a in zip(wt, u))
    best = min(best, ex2 - theta**2)
    for lam in (0.5, 2.0, 3.5):
        mean = sum(pois(N * lam, t) * m[t] for t in range(120))
        mean += sum(pois(N * lam, t) * w * a for (t, wt), u in zip(groups, noise) for w, a in zip(wt, u))
        worst_bias = max(worst_bias, abs(mean - exp(-lam)))
row("4 search: 300 unbiased rules, least variance", best)
row("  largest bias at lam = 0.5, 2, 3.5", worst_bias)
assert best >= var_rb - 1e-12 and worst_bias < 1e-12

n, k = 1000, 520                               # house poll: estimate p(1-p)
umvue = k * (n - k) / (n * (n - 1))
count = exp(lgamma(n - 1) - lgamma(k) - lgamma(n - k) - lgamma(n + 1) + lgamma(k + 1) + lgamma(n - k + 1))
row("poll: P(1 yes, 2 no | K=520) by counting", count)
row("  formula K(n-K)/(n(n-1))", umvue)
row("  plug-in p-hat(1-p-hat)", 0.52 * 0.48)
lp = [lgamma(n + 1) - lgamma(j + 1) - lgamma(n - j + 1) + j * log(0.52) + (n - j) * log(0.48) for j in range(n + 1)]
row("  mean of K(n-K)/(n(n-1)) at p = 0.52", sum(exp(a) * j * (n - j) / (n * (n - 1)) for j, a in enumerate(lp)))
row("  mean of plug-in at p = 0.52", sum(exp(a) * j * (n - j) / n**2 for j, a in enumerate(lp)))
assert abs(count - umvue) < 1e-12
for nn in (5, 10, 20, 50):
    print(f"n = {nn:2d} hours: efficiency at lam = 2  {(LAM / nn) / (exp(LAM / nn) - 1):.6f}")
lams = [0.5 * i for i in range(1, 9)]
print("chart, lam      ", " ".join(f"{v:.2f}" for v in lams))
print("chart, (4/5)^T  ", " ".join(f"{(v / N) / (exp(v / N) - 1):.3f}" for v in lams))
print("chart, fraction ", " ".join(f"{v / (exp(v) - 1):.3f}" for v in lams))
print("ALL CHECKS PASS")
