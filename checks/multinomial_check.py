# Multinomial -- the check behind the card.  Nothing is imported.  Twenty
# customers each pick a cup size on their own: small 0.3, medium 0.5, large
# 0.2.  Three roads: the counting formula, an exact table built one customer
# at a time (every one of the 3^20 orders, grouped by tally), and a seeded
# simulation of 100,000 days drawn from SplitMix64, written out below.
N, P = 20, (0.3, 0.5, 0.2)

def fact(n):
    out = 1
    for i in range(2, n + 1):
        out *= i
    return out
def ipow(x, k):                              # x multiplied in k times
    out = 1.0
    for _ in range(k):
        out *= x
    return out
def formula(k, p, n):                        # road one: C(n; k1, k2, k3) p1^k1 p2^k2 p3^k3
    coef = fact(n) // (fact(k[0]) * fact(k[1]) * fact(k[2]))
    return coef * ipow(p[0], k[0]) * ipow(p[1], k[1]) * ipow(p[2], k[2])

def table(p, steps, size):                   # road two: law[s][m], large = total - s - m
    law = [[0.0] * (N + 1) for _ in range(N + 1)]
    law[0][0] = 1.0
    for t in range(steps):
        new = [[0.0] * (N + 1) for _ in range(N + 1)]
        for s in range(t * size + 1):
            for m in range(t * size - s + 1):
                w = law[s][m]
                new[s + size][m] += w * p[0]      # this customer (or pair) takes small
                new[s][m + size] += w * p[1]      # medium
                new[s][m] += w * p[2]             # large
        law = new
    return law

def moments(law):                            # E[S], E[M], E[L], then the 3 x 3 covariances
    cells = [(s, m, N - s - m, law[s][m]) for s in range(N + 1) for m in range(N + 1 - s)]
    mean = [0.0, 0.0, 0.0]
    for c in cells:
        for i in range(3):
            mean[i] += c[i] * c[3]
    cov = [[0.0] * 3 for _ in range(3)]
    for c in cells:
        for i in range(3):
            for j in range(3):
                cov[i][j] += (c[i] - mean[i]) * (c[j] - mean[j]) * c[3]
    return mean, cov

def add(xs):                                 # plain left-to-right sum, as in Rust
    out = 0.0
    for x in xs:
        out += x
    return out

def binom_pmf(n, p):                         # Pascal's triangle, no factorials
    row = [1]
    for _ in range(n):
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return [row[k] * ipow(p, k) * ipow(1 - p, n - k) for k in range(n + 1)]

law = table(P, N, 1)
exact = formula((6, 10, 4), P, N)
total = 0.0
best = (0, 0, 0.0)
for s in range(N + 1):
    for m in range(N + 1 - s):
        total += law[s][m]
        if law[s][m] > best[2]:
            best = (s, m, law[s][m])
mean, cov = moments(law)
corr = cov[0][1] / (cov[0][0] * cov[1][1]) ** 0.5
print(f"coefficient C(20; 6, 10, 4) = {fact(20) // (fact(6) * fact(10) * fact(4))}")
print(f"one order, 6 small then 10 medium then 4 large = {ipow(0.3, 6) * ipow(0.5, 10) * ipow(0.2, 4):.12f}")
print(f"its pieces: 0.3^6 = {ipow(0.3, 6):.10f}, 0.5^10 = {ipow(0.5, 10):.10f}, 0.2^4 = {ipow(0.2, 4):.10f}")
print(f"P(6, 10, 4) by the formula          = {exact:.6f}")
print(f"P(6, 10, 4) by the customer table   = {law[6][10]:.6f}")
print(f"table total over {(N + 1) * (N + 2) // 2} tallies = {total:.6f}; most likely tally {best[0]}, {best[1]}, {N - best[0] - best[1]}")
print(f"means from the table: small {mean[0]:.4f}, medium {mean[1]:.4f}, large {mean[2]:.4f}")
for i, name in enumerate(("small", "medium", "large")):
    print(f"covariance row {name:6s}: {cov[i][0]:8.4f} {cov[i][1]:8.4f} {cov[i][2]:8.4f}; formula diagonal {N * P[i] * (1 - P[i]):.4f}")
print(f"formula off-diagonal: -n p1 p2 = {-N * P[0] * P[1]:.4f}, -n p1 p3 = {-N * P[0] * P[2]:.4f}, -n p2 p3 = {-N * P[1] * P[2]:.4f}")
print(f"correlation small with medium = {corr:.4f}; variance of the total = {add(add(r) for r in cov):.4f}")
marg_err = 0.0                               # each count alone, summed out of the table
for i in range(3):
    marg, pmf = [0.0] * (N + 1), binom_pmf(N, P[i])
    for s in range(N + 1):
        for m in range(N + 1 - s):
            marg[(s, m, N - s - m)[i]] += law[s][m]
    marg_err = max(marg_err, max(abs(marg[a] - pmf[a]) for a in range(N + 1)))
print(f"each count alone matches Binomial(20, its chance) to 1e-12: {'yes' if marg_err < 1e-12 else 'no'}")
print("figure, P(medium = m), m = 4..16: " + ", ".join(f"{add(law[s][m] for s in range(N + 1 - m)):.4f}" for m in range(4, 17)))
cond = []
for m in range(0, N + 1, 2):
    w = [law[s][m] for s in range(N + 1 - m)]
    cond.append(add(s * w[s] for s in range(len(w))) / add(w))
print("figure, mean small given m medium, m = 0,2..20: " + ", ".join(f"{c:.2f}" for c in cond))
print("figure, mean large given m medium, m = 0,2..20: " + ", ".join(f"{(N - m) - c:.2f}" for m, c in zip(range(0, N + 1, 2), cond)))
print(f"given m medium, each other customer is small with chance 0.3 / (0.3 + 0.2) = {P[0] / (P[0] + P[2]):.4f}")
state, MASK = 20260928, (1 << 64) - 1
def draw():                                  # SplitMix64, top 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (z ^ (z >> 31)) >> 11
CUT1, CUT2, DAYS = int(0.3 * 2.0 ** 53), int(0.8 * 2.0 ** 53), 100000
hits, days, ss, sm, ssm = 0, [], 0, 0, 0
for _ in range(DAYS):                        # road three: simulate the days
    s = m = 0
    for _ in range(N):
        u = draw()
        if u < CUT1: s += 1
        elif u < CUT2: m += 1
    hits += (s, m) == (6, 10)
    days.append((s, m))
    ss, sm, ssm = ss + s, sm + m, ssm + s * m
ph = hits / DAYS
cov_sim = (ssm - ss * sm / DAYS) / (DAYS - 1)
dev = 0.0
for s, m in days:
    d = (s - ss / DAYS) * (m - sm / DAYS) - cov_sim
    dev += d * d
se_cov = (dev / (DAYS - 1) / DAYS) ** 0.5
se_p = (ph * (1 - ph) / DAYS) ** 0.5
print(f"simulated {DAYS} days, seed 20260928: P(6, 10, 4) = {ph:.5f} +/- {se_p:.5f}; Cov(small, medium) = {cov_sim:.4f} +/- {se_cov:.4f}")
indep = binom_pmf(N, P[0])[6] * binom_pmf(N, P[1])[10] * binom_pmf(N, P[2])[4]
pairs = table(P, N // 2, 2)
pm, pc = moments(pairs)
print(f"mistake 1, one order only, no coefficient: {ipow(0.3, 6) * ipow(0.5, 10) * ipow(0.2, 4):.12f}, not {exact:.6f}")
print(f"mistake 2, three binomial chances multiplied as if independent: {indep:.6f}, not {exact:.6f}")
print(f"mistake 3, the three variances added: {cov[0][0] + cov[1][1] + cov[2][2]:.4f}, but the total never moves")
print(f"mistake 4, customers in 10 pairs ordering alike: P(6, 10, 4) = {pairs[6][10]:.6f}, formula on pairs {formula((3, 5, 2), P, 10):.6f}; Var(medium) = {pc[1][1]:.4f}; Cov(small, medium) = {pc[0][1]:.4f}")
assert abs(exact - law[6][10]) < 1e-12 * exact             # formula against the table
assert marg_err < 1e-12 and abs(total - 1) < 1e-12          # marginals are the binomials
assert all(abs(cov[i][j] - (N * P[i] * ((i == j) - P[j]))) < 1e-9 for i in range(3) for j in range(3))
assert best[:2] == (6, 10) and all(abs(c - P[0] / (P[0] + P[2]) * (N - m)) < 1e-9 for m, c in zip(range(0, N + 1, 2), cond))
assert abs(ph - exact) < 4 * se_p and abs(cov_sim - cov[0][1]) < 4 * se_cov   # simulation agrees
assert abs(pairs[6][10] - formula((3, 5, 2), P, 10)) < 1e-12 and abs(pc[1][1] - 2 * cov[1][1]) < 1e-9
print("ALL CHECKS PASS")
