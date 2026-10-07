# Vasicek large-pool loss curve and Basel capital -- the check behind the card. Standard library
# only: normal CDF from math.erf, inverse by bisection, Simpson integrals, hand-written random numbers.
from math import erf, exp, log, sqrt, cos, pi

def N(x):                                   # bell-curve area left of x
    return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def phi(x):                                 # bell-curve height at x
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def bisect(f, lo, hi, iters=200):           # root of an increasing function on [lo, hi]
    for _ in range(iters):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0.0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def Ninv(u):
    return bisect(lambda z: N(z) - u, -40.0, 40.0)
def simpson(f, a, b, n=4000):               # n even
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

PD, RHO, LGD, LOAN, ALPHA = 0.02, 0.20, 0.60, 100.0, 0.999
c = Ninv(PD)                                # default threshold
z_a = Ninv(ALPHA)                           # the 1-in-1000 bad economy, as a positive number

def p_given(m, rho=RHO, cc=c):             # default chance of one loan when the economy reads m
    return N((cc - sqrt(rho) * m) / sqrt(1.0 - rho))

def quantile(u, rho=RHO, pd=PD):            # road 1: the closed form
    return N((Ninv(pd) + sqrt(rho) * Ninv(u)) / sqrt(1.0 - rho))

def F(x):                                   # chance the pool's default fraction is at most x
    return N((sqrt(1.0 - RHO) * Ninv(x) - c) / sqrt(RHO))

def basel_rho(pd):
    w = (1.0 - exp(-50.0 * pd)) / (1.0 - exp(-50.0))
    return 0.12 * w + 0.24 * (1.0 - w)

# ---- road 1 and road 2 to the 99.9% default fraction ----
x1 = quantile(ALPHA)
x2 = bisect(lambda x: F(x) - ALPHA, 1e-12, 1.0 - 1e-12)
mean_pd = simpson(lambda m: p_given(m) * phi(m), -10.0, 10.0)            # must give back PD
# expected shortfall: average default fraction over the worst 0.1% of economies ...
es1 = simpson(lambda z: p_given(-z) * phi(z), z_a, 12.0) / (1.0 - ALPHA)
# ... and, independently, over loss levels: ES = VaR + E[(L - VaR)+] / (1 - alpha)
es2 = x1 + simpson(lambda y: 1.0 - F(y), x1, 1.0 - 1e-12) / (1.0 - ALPHA)

# ---- road 3: finite pools, exact, by mixing binomials over the economy ----
def finite_pool(n, nodes=1600, lo=-9.0, hi=9.0):
    lc = [0.0] * (n + 1)
    for k in range(1, n + 1):
        lc[k] = lc[k - 1] + log(n - k + 1) - log(k)
    dist, h = [0.0] * (n + 1), (hi - lo) / nodes
    for i in range(nodes + 1):
        m = lo + i * h
        w = (1 if i in (0, nodes) else (4 if i % 2 else 2)) * h / 3.0 * phi(m)
        q = min(max(p_given(m), 1e-300), 1.0 - 1e-16)
        lq, l1 = log(q), log(1.0 - q)
        for k in range(n + 1):
            dist[k] += w * exp(lc[k] + k * lq + (n - k) * l1)
    cum, k = 0.0, 0
    while cum + dist[k] < ALPHA:
        cum += dist[k]; k += 1
    tail = sum(dist[j] * j / n for j in range(k + 1, n + 1)) + (cum + dist[k] - ALPHA) * k / n
    return sum(dist), k / n, tail / (1.0 - ALPHA)

# ---- road 4: simulate 100 loans, each with its own luck, 100,000 years ----
state = 0x2545F4914F6CDD1D
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
def normal_pair():
    r, t = sqrt(-2.0 * log(uniform())), 2.0 * pi * uniform()
    return r * cos(t), r * cos(t - 0.5 * pi)
YEARS, LOANS = 100000, 100
a, b = sqrt(RHO), sqrt(1.0 - RHO)
fracs = []
for _ in range(YEARS):
    m, _ = normal_pair()
    d = 0
    for _ in range(LOANS // 2):
        z1, z2 = normal_pair()
        d += (a * m + b * z1 < c) + (a * m + b * z2 < c)
    fracs.append(d / LOANS)
fracs.sort()
tail_n = int(round(YEARS * (1.0 - ALPHA)))
mc_var = fracs[YEARS - tail_n - 1]
mc_es = sum(fracs[YEARS - tail_n:]) / tail_n
mc_mean = sum(fracs) / YEARS

# ---- capital ----
EL = LOAN * LGD * PD
var_loss = LOAN * LGD * x1
cap = var_loss - EL
rb = basel_rho(PD)
xb = quantile(ALPHA, rb)
cap_b = LOAN * LGD * (xb - PD)
joint = simpson(lambda m: p_given(m) ** 2 * phi(m), -10.0, 10.0)
dcorr = (joint - PD * PD) / (PD * (1.0 - PD))   # default correlation

out = [("threshold c = N^-1(PD)", c), ("bad economy N^-1(0.999)", z_a), ("sqrt(rho)", sqrt(RHO)),
       ("sqrt(1 - rho)", sqrt(1 - RHO)), ("argument (c + sqrt(rho) z)/sqrt(1-rho)", (c + sqrt(RHO) * z_a) / sqrt(1 - RHO)),
       ("1 closed-form 99.9% fraction", x1), ("2 root of F(x) = 0.999", x2),
       ("  average of p(M), must be PD", mean_pd),
       ("ES 99.9%, over economies", es1), ("ES 99.9%, over loss levels", es2)]
pools = {n: finite_pool(n) for n in (25, 100, 1000)}
for n, (tot, q_n, es_n) in pools.items():
    out += [(f"3 exact pool of {n}: total prob", tot), (f"  pool of {n}: 99.9% fraction", q_n), (f"  pool of {n}: ES 99.9%", es_n)]
out += [("4 simulated 100 loans: mean", mc_mean), ("  simulated: 99.9% fraction", mc_var), ("  simulated: ES 99.9%", mc_es),
        ("expected loss per loan $", EL), ("99.9% loss per loan $", var_loss), ("capital = UL per loan $", cap),
        ("ES loss per loan $", LOAN * LGD * es1), ("fraction above expected", x1 - PD), ("Basel weight w", (1 - exp(-50 * PD)) / (1 - exp(-50))), ("Basel correlation", rb), ("Basel 99.9% fraction", xb),
        ("Basel capital per loan $", cap_b), ("risk-weighted assets per loan $", 12.5 * cap_b),
        ("default correlation", dcorr),
        ("wrong: correlation 0, 99.9% fraction", quantile(ALPHA, 0.0)),
        ("wrong: EL left in, capital $", var_loss), ("wrong: forgot LGD, capital $", LOAN * (x1 - PD)),
        ("wrong: N^-1(0.001), capital $", LOAN * LGD * (quantile(1.0 - ALPHA) - PD)),
        ("wrong: default corr as rho, capital $", LOAN * LGD * (quantile(ALPHA, dcorr) - PD)),
        ("try: rho 0.10 fraction", quantile(ALPHA, 0.10)), ("try: rho 0.30 fraction", quantile(ALPHA, 0.30)),
        ("try: alpha 0.99 fraction", quantile(0.99))]
for name, v in out:
    print(f"{name:<38} {v:>12.6f}")
print("chart, 1 year in   " + " ".join(f"{t:>6d}" for t in (2, 5, 10, 20, 50, 100, 200, 500, 1000)))
print("chart, fraction %  " + " ".join(f"{100 * quantile(1 - 1 / t):6.2f}" for t in (2, 5, 10, 20, 50, 100, 200, 500, 1000)))
pds = (0.001, 0.0025, 0.005, 0.01, 0.02, 0.03, 0.05, 0.10, 0.20)
print("chart, PD %        " + " ".join(f"{100 * p:6.2f}" for p in pds))
print("chart, cap rho 20% " + " ".join(f"{LOAN * LGD * (quantile(ALPHA, RHO, p) - p):6.2f}" for p in pds))
print("chart, cap Basel   " + " ".join(f"{LOAN * LGD * (quantile(ALPHA, basel_rho(p), p) - p):6.2f}" for p in pds))

assert abs(x1 - x2) < 1e-9,                "closed form vs root of the CDF"
assert abs(mean_pd - PD) < 1e-9,           "averaging over the economy returns PD"
assert abs(es1 - es2) < 1e-6,              "ES over economies vs ES over loss levels"
assert abs(pools[100][1] - mc_var) <= 0.015, "simulated 100-loan quantile within noise of the exact one"
assert abs(pools[100][2] - mc_es) < 0.01,    "simulated 100-loan ES within noise of the exact one"
assert abs(pools[1000][1] - x1) < 0.005 < abs(pools[25][1] - x1), "big pools approach the large-pool curve"
assert abs(mc_mean - PD) < 0.0015,           "simulated mean default rate"
assert abs(cap - LOAN * LGD * (x2 - PD)) < 1e-6 and abs(rb - 0.1641) < 1e-4 and abs(bisect(lambda x: N((sqrt(1 - rb) * Ninv(x) - c) / sqrt(rb)) - ALPHA, 1e-12, 1 - 1e-12) - xb) < 1e-9, "capital by road 2; Basel correlation and quantile by root-finding"
print("ALL CHECKS PASS")
