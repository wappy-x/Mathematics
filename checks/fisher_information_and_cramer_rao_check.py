# Fisher information and the Cramer-Rao bound -- the check behind the card.
# A bent coin, chance of heads p = 0.25, flipped n = 4 times.  Roads: the formula;
# all 16 strings, the score as a numerical slope of the log-likelihood; the
# curvature; a seeded simulation (SplitMix64); a search of unbiased estimators.
from math import log, exp, sqrt
M64 = 2**64 - 1
state = 20260928

def next64():                            # SplitMix64 with a stated seed
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

def unif(): return (next64() >> 11) / 2.0**53     # uniform in [0, 1)
def row(label, v, d=6): print(f"{label:<44}{v:>12.{d}f}")
N, P, H = 4, 0.25, 1e-5
strings = [[(m >> i) & 1 for i in range(N)] for m in range(2**N)]
heads = [sum(s) for s in strings]

def prob(i, p):                          # chance of string i when heads has chance p
    return p ** heads[i] * (1.0 - p) ** (N - heads[i])
def loglik(i, p):                        # log-likelihood of string i, flip by flip
    return sum(log(p) if x else log(1.0 - p) for x in strings[i])
def score(i):                            # slope of the log-likelihood at P, numerically
    return (loglik(i, P + H) - loglik(i, P - H)) / (2 * H)
def curve(i):                            # its second slope, numerically
    h = 1e-4
    return (loglik(i, P + h) - 2 * loglik(i, P) + loglik(i, P - h)) / (h * h)
def moments(t, p=P):                     # mean, variance, mean squared error of estimator t
    m = sum(prob(i, p) * t[i] for i in range(2**N))
    v = sum(prob(i, p) * (t[i] - m) ** 2 for i in range(2**N))
    return m, v, v + (m - p) ** 2
def e(f): return sum(prob(i, P) * f(i) for i in range(2**N))   # average at P
I_form = N / (P * (1 - P))
row("1 formula: information n/(p(1-p))", I_form)
row("  floor p(1-p)/n", 1 / I_form)
row("  floor as a standard deviation", sqrt(1 / I_form))
print("head count k, chance of that count, score, score squared")
for k in range(N + 1):
    i = heads.index(k)
    ck = sum(prob(j, P) for j in range(2**N) if heads[j] == k)
    print(f"  {k}  {ck:.8f}  {score(i):10.6f}  {score(i) ** 2:11.6f}")
ES = e(score)
I_enum = e(lambda i: score(i) ** 2)
I_curv = -e(curve)
row("2 enumerated: average score", ES)
row("  average squared score (information)", I_enum)
row("3 curvature: minus average second slope", I_curv)
phat = [h / N for h in heads]
m, v, _ = moments(phat)
cov = e(lambda i: (phat[i] - P) * score(i))
row("sample proportion: mean", m)
row("  variance", v)
row("  covariance with the score", cov)
row("  variance x information", v * I_form)
others = [("first flip only", [s[0] for s in strings]),
          ("weights 0.4 0.3 0.2 0.1", [0.4*s[0] + 0.3*s[1] + 0.2*s[2] + 0.1*s[3] for s in strings]),
          ("Laplace (K+1)/(n+2), biased", [(h + 1) / (N + 2) for h in heads]),
          ("stopped clock 0.25, biased", [0.25] * 2**N)]
res = {}
for name, t in others:
    res[name] = moments(t)
    print(f"{name:<30} mean {res[name][0]:.6f}  var {res[name][1]:.6f}  mse {res[name][2]:.6f}")
lap = res["Laplace (K+1)/(n+2), biased"]
row("Laplace floor (1 + bias slope)^2 / I", (N / (N + 2)) ** 2 / I_form)
for p in (0.05, 0.6):
    print(f"at p = {p}: floor {p * (1 - p) / N:.6f}  Laplace mse {moments(others[2][1], p)[2]:.6f}"
          f"  clock mse {moments(others[3][1], p)[2]:.6f}")
best, worst_mean = 1.0, 0.0              # 4: random unbiased estimators, phat plus noise
for trial in range(2000):
    amp = 0.3 * unif()
    z = [amp * (2 * unif() - 1) for _ in range(2**N)]
    for k in range(N + 1):               # zero sum inside each head-count class
        cls = [i for i in range(2**N) if heads[i] == k]
        c = sum(z[i] for i in cls) / len(cls)
        for i in cls:
            z[i] -= c
    t = [phat[i] + z[i] for i in range(2**N)]
    for p in (0.1, 0.25, 0.7):
        worst_mean = max(worst_mean, abs(moments(t, p)[0] - p))
    best = min(best, moments(t)[1])
row("4 search: 2000 unbiased estimators, least var", best)
row("  largest bias found at p = 0.1, 0.25, 0.7", worst_mean)
runs, acc, acc2 = 200000, 0.0, 0.0       # 5: simulation of the sample proportion
for _ in range(runs):
    k = sum(1 for _ in range(N) if unif() < P)
    sq = (k / N - P) ** 2
    acc, acc2 = acc + sq, acc2 + sq * sq
sim = acc / runs
se = sqrt((acc2 / runs - sim * sim) / runs)
row("5 simulated variance, 200000 runs", sim)
row("  standard error", se)
theta, ua, ua2 = 2.0, 0.0, 0.0           # moving edge: uniform on (0, theta)
for _ in range(runs):
    t = (N + 1) / N * max(theta * unif() for _ in range(N))
    sq = (t - theta) ** 2
    ua, ua2 = ua + sq, ua2 + sq * sq
usim, use = ua / runs, sqrt((ua2 / runs - (ua / runs) ** 2) / runs)
row("uniform: slope of log(1/theta) per draw", (log(1 / (theta + H)) - log(1 / (theta - H))) / (2 * H))
row("  naive floor theta^2/n^2", theta ** 2 / N ** 2)
row("  corrected maximum, exact theta^2/(n(n+2))", theta ** 2 / (N * (N + 2)))
row("  corrected maximum, simulated", usim)
row("  standard error", use)
n, p = 1000, 0.52                        # house poll: exact binomial sum in logs
lp, pv = n * log(1 - p), 0.0
for k in range(n + 1):
    pv += exp(lp) * (k / n - p) ** 2
    lp += log((n - k) / (k + 1) * p / (1 - p)) if k < n else 0.0
row("poll n=1000 p=0.52: floor p(1-p)/n", p * (1 - p) / n, 7)
row("  exact variance of the proportion", pv, 7)
row("  floor as a standard deviation", sqrt(p * (1 - p) / n))
row("  information n/(p(1-p))", n / (p * (1 - p)), 1)
for nn in (4, 16, 64, 100): print(f"n = {nn:3d}: floor {P * (1 - P) / nn:.6f}  standard deviation {sqrt(P * (1 - P) / nn):.6f}")
grid = [j / 20 for j in range(1, 13)]
def drop(nn, kk, q): return kk * log(q / 0.25) + (nn - kk) * log((1 - q) / 0.75)
print("chart1, p       " + " ".join(f"{q:.2f}" for q in grid))
print("chart1, n=4     " + " ".join(f"{drop(4, 1, q):.2f}" for q in grid))
print("chart1, n=40    " + " ".join(f"{drop(40, 10, q):.2f}" for q in grid))
g2 = [j / 20 for j in range(1, 20)]
print("chart2, floor   " + " ".join(f"{q * (1 - q) / N:.4f}" for q in g2))
print("chart2, Laplace " + " ".join(f"{moments(others[2][1], q)[2]:.4f}" for q in g2))
print("crossings of floor and Laplace", f"{(1 - sqrt(5) / 3) / 2:.6f}", f"{(1 + sqrt(5) / 3) / 2:.6f}")

assert abs(I_enum - I_form) < 1e-6, "enumerated squared score equals n/(p(1-p))"
assert abs(I_curv - I_form) < 1e-3, "curvature road equals the squared-score road"
assert abs(ES) < 1e-6, "the score averages zero"
assert abs(cov - 1.0) < 1e-6, "unbiased estimator has covariance 1 with the score"
assert abs(v - 1 / I_form) < 1e-12, "enumerated variance of phat sits on the floor"
assert best >= v - 1e-12, "no unbiased estimator found below the floor"
assert worst_mean < 1e-12, "every searched estimator is unbiased at three values of p"
assert abs(sim - 1 / I_form) < 4 * se, "simulated variance within four standard errors"
assert lap[2] < v, "a biased estimator beats the floor at p = 0.25"
assert abs(lap[1] - (N / (N + 2)) ** 2 / I_form) < 1e-12, "Laplace sits on its biased floor"
assert abs(usim - theta ** 2 / 24) < 4 * use, "corrected maximum: simulation matches theta^2/(n(n+2))"
assert theta ** 2 / 16 - usim > 20 * use, "moving edge: variance far below the naive floor"
assert abs(pv - p * (1 - p) / n) < 1e-10, "poll: exact sum equals p(1-p)/n"
print("ALL CHECKS PASS")
