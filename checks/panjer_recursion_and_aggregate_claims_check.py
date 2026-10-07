# Panjer's recursion -- the check behind the card.  Standard library only;
# nothing imported contains the answer.  A motor insurer's 50,000 policies
# give 20 large claims a year on average (Poisson).  Sizes on a $10,000 grid:
# 1 unit 50%, 2 units 30%, 5 units 20%.  Question: the chance that the year's
# total beats 120% of its expected value.  Four roads, then the mistakes.
from math import exp, sqrt

LAM, Q, KMAX = 20.0, [0.0, 0.5, 0.3, 0.0, 0.0, 0.2], 200

def panjer(a, b, p0, q, kmax):           # road 1: the (a, b, 0) recursion
    p = [p0] + [0.0] * kmax
    for k in range(1, kmax + 1):
        s = 0.0
        for j in range(1, min(k, len(q) - 1) + 1):
            s += (a + b * j / k) * q[j] * p[k - j]
        p[k] = s / (1.0 - a * q[0])
    return p

def poisson(mu, n):                      # e^-mu mu^n / n!, written out
    v = exp(-mu)
    for i in range(1, n + 1):
        v *= mu / i
    return v
def by_count(weight, q, kmax):           # road 3: sum over the claim count
    out, conv = [0.0] * (kmax + 1), [1.0] + [0.0] * kmax     # conv = q^{*n}
    for n in range(kmax + 1):            # every claim is >= 1 unit, so n <= kmax
        w = weight(n)
        for k in range(kmax + 1):
            out[k] += w * conv[k]
        new = [0.0] * (kmax + 1)
        for k in range(kmax + 1):
            for j in range(1, min(k, len(q) - 1) + 1):
                new[k] += q[j] * conv[k - j]
        conv = new
    return out
def row(label, v, d=6):                 # one labelled number per line
    print(f"{label:<38}{v:.{d}f}")
def normal_cdf(z):                       # 0.5 + Simpson's rule on the bell curve
    n, h = 2000, z / 2000
    s = 1.0 + exp(-z * z / 2)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * exp(-(i * h) * (i * h) / 2)
    return 0.5 + s * h / 3 / sqrt(2 * 3.141592653589793)
state = 20260928                         # road 4: splitmix64, then Knuth's Poisson
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

p = panjer(0.0, LAM, exp(-LAM * (1 - Q[0])), Q, KMAX)
split = [0.0] * (KMAX + 1)               # road 2: 10 + 6 + 4 independent Poissons
c1, c2, c5 = ([poisson(mu, n) for n in range(KMAX + 1)] for mu in (10.0, 6.0, 4.0))
for n5 in range(KMAX // 5 + 1):
    for n2 in range((KMAX - 5 * n5) // 2 + 1):
        for n1 in range(KMAX - 5 * n5 - 2 * n2 + 1):
            split[n1 + 2 * n2 + 5 * n5] += c1[n1] * c2[n2] * c5[n5]
conv = by_count(lambda n: poisson(LAM, n), Q, KMAX)
ex = sum(j * x for j, x in enumerate(Q))
ex2 = sum(j * j * x for j, x in enumerate(Q))
mean, var = LAM * ex, LAM * ex2
t = int(1.2 * mean)                      # 50.4 units: beating it means K >= 51
tail = 1.0 - sum(p[:t + 1])
tail_split, tail_conv = 1.0 - sum(split[:t + 1]), 1.0 - sum(conv[:t + 1])
years, hits, limit = 200000, 0, exp(-LAM)
for _ in range(years):
    n, prod = 0, uniform()
    while prod > limit:
        n, prod = n + 1, prod * uniform()
    total = 0
    for _ in range(n):
        u = uniform()
        total += 1 if u < 0.5 else (2 if u < 0.8 else 5)
    hits += total > t
m_d = sum(k * x for k, x in enumerate(p))
v_d = sum(k * k * x for k, x in enumerate(p)) - m_d * m_d
t150 = int(1.5 * mean)                   # 63 units
tail150 = 1.0 - sum(p[:t150 + 1])
nb = panjer(2.0 / 3.0, 6.0, 3.0 ** -10, Q, KMAX)           # r = 10, beta = 2
def nb_weight(n):                        # C(n+9, 9) (1/3)^10 (2/3)^n, closed form
    c = 1
    for i in range(1, 10):
        c = c * (n + i) // i
    return c * (1.0 / 3.0) ** 10 * (2.0 / 3.0) ** n
nb_conv = by_count(nb_weight, Q, KMAX)
nb_tail = 1.0 - sum(nb[:t + 1])
Q0 = [0.2, 0.4, 0.24, 0.0, 0.0, 0.16]    # 25 claims a year, one in five settles at zero
thin = panjer(0.0, 25.0, exp(-25.0 * (1 - Q0[0])), Q0, KMAX)  # the same year as p
nb_thin = panjer(5.0 / 7.0, 45.0 / 7.0, 3.0 ** -10, Q0, KMAX)  # r = 10, beta = 2.5: same as nb
no_j = [exp(-LAM)] + [0.0] * KMAX        # mistake: weight j dropped from the sum
for k in range(1, KMAX + 1):
    no_j[k] = LAM / k * sum(Q[j] * no_j[k - j] for j in range(1, min(k, 5) + 1))
big = panjer(0.0, 2500.0, exp(-2500.0), Q, 50)
def tail120(lam, q):                     # try-changing runs: 120% of the new mean
    pp = panjer(0.0, lam, exp(-lam * (1 - q[0])), q, KMAX)
    return 1.0 - sum(pp[:int(1.2 * lam * sum(j * x for j, x in enumerate(q))) + 1])

row("mean claim, units of $10,000", ex)
row("mean total, units", mean)
row("sd of total, units", sqrt(var))
row("threshold 120% of mean, units", 1.2 * mean)
row("p0 = e^-20, times 10^9", p[0] * 1e9)
for k in (1, 2, 3):
    row(f"p{k} / p0, road 1 Panjer", p[k] / p[0])
row("P(K <= 50), road 1 Panjer", 1 - tail, 10)
row("P(K <= 50), road 2 Poisson split", 1 - tail_split, 10)
row("P(K <= 50), road 3 sum over count", 1 - tail_conv, 10)
row("tail, road 1 Panjer", tail)
row("tail, road 4 simulated 200,000 years", hits / years)
row("mean from the distribution, units", m_d)
row("variance from the distribution", v_d)
row("variance lambda E[X^2]", var)
row("p2 / p0, road 2 Poisson split", split[2] / split[0])
row("tail beyond 150% of mean (K > 63)", tail150)
row("negative binomial count, tail", nb_tail)
row("  same by closed-form count weights", 1.0 - sum(nb_conv[:t + 1]))
row("wrong: normal curve at 120%", 1 - normal_cdf((1.2 * mean - mean) / sqrt(var)))
row("wrong: normal curve at 150%", 1 - normal_cdf((1.5 * mean - mean) / sqrt(var)))
row("wrong: counted $500,000 as a breach", 1.0 - sum(p[:t]))
row("wrong: j dropped, total probability", sum(no_j))
row("wrong: lambda 2500, total of p0..p50", sum(big))
row("try: 25 claims a year, tail at 120%", tail120(25.0, Q))
row("try: $50,000 claims 30%, $10k 40%", tail120(LAM, [0.0, 0.4, 0.3, 0.0, 0.0, 0.3]))
row("try: sizes 1 unit only, tail at 120%", tail120(LAM, [0.0, 1.0]))
ks, xs = range(20, 81, 5), range(30, 71, 5)
print("chart, total $k   " + " ".join(f"{10 * k:6d}" for k in ks))
print("chart, p_k in %   " + " ".join(f"{100 * p[k]:6.2f}" for k in ks))
print("chart, over $k    " + " ".join(f"{10 * x:6d}" for x in xs))
print("chart, exact %    " + " ".join(f"{100 * (1 - sum(p[:x + 1])):6.2f}" for x in xs))
print("chart, normal %   " + " ".join(f"{100 * (1 - normal_cdf((x - mean) / sqrt(var))):6.2f}" for x in xs))

assert max(abs(a - b) for a, b in zip(p, split)) < 1e-15          # recursion vs split
assert abs(tail - tail_conv) < 1e-12 and abs(tail - tail_split) < 1e-12
assert abs(hits / years - tail) < 0.006                            # about 6 standard errors
assert abs(m_d - mean) < 1e-9 and abs(v_d - var) < 1e-6           # moments vs lambda E[X]
assert max(abs(a - b) for a, b in zip(nb, nb_conv)) < 1e-15       # (a, b, 0) vs closed form
assert max(abs(a - b) for a, b in zip(p + nb, thin + nb_thin)) < 1e-15  # q0 > 0 terms
print("ALL CHECKS PASS")
