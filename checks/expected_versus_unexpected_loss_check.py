# Expected and unexpected loss -- the check behind the card.  Standard library only.
# A $1 billion loan book, 2% chance of default per loan, 40% lost in a default.
# Road 1: the formula EL = PD x LGD x EAD, loan by loan.
# Road 2: the whole loss distribution, built by adding one loan at a time.
# Road 3: simulated years, with a random-number generator written out below.
# Money is printed in $ millions.
from math import comb, log, sqrt

BOOK, PD, LGD = 1000.0, 0.02, 0.40                   # $ millions, chance, fraction

def book_pmf(n, p):
    # dist[k] = chance of exactly k defaults among the loans added so far
    dist = [1.0]
    for _ in range(n):
        new = [0.0] * (len(dist) + 1)
        for k, w in enumerate(dist):
            new[k] += w * (1.0 - p)
            new[k + 1] += w * p
        dist = new
    return dist

def mixed_pmf(n, good, bad, p_bad=0.10):             # a bad year one time in ten
    g, b = book_pmf(n, good), book_pmf(n, bad)
    return [(1.0 - p_bad) * x + p_bad * y for x, y in zip(g, b)]

def mean_sd(dist, a):                                # a = dollars lost per default
    m = sum(k * a * w for k, w in enumerate(dist))
    v = sum((k * a - m) ** 2 * w for k, w in enumerate(dist))
    return m, sqrt(v)

def quantile(dist, a, alpha):                        # smallest loss x with P(L <= x) >= alpha
    cum = 0.0
    for k, w in enumerate(dist):
        cum += w
        if cum >= alpha:
            return k * a
    return (len(dist) - 1) * a

def formula_el(n, pd, lgd):                          # road 1: add PD x LGD x EAD over the loans
    return sum(pd * lgd * (BOOK / n) for _ in range(n))

# the four books: same $1 billion, same 2% PD, same 40% LGD
books = {
    "A 10 loans, independent": (book_pmf(10, PD), BOOK / 10 * LGD, 10),
    "B 1000 loans, independent": (book_pmf(1000, PD), BOOK / 1000 * LGD, 1000),
    "C 1000 loans, bad years": (mixed_pmf(1000, 0.01, 0.11), BOOK / 1000 * LGD, 1000),
    "D 1000 loans, all-or-none": ([0.98] + [0.0] * 999 + [0.02], BOOK / 1000 * LGD, 1000),
}
res = {}
print(f"{'book':<27}{'EL':>8}{'formula':>8}{'sd':>8}{'q95':>8}{'UL95':>8}"
      f"{'q99':>8}{'UL99':>8}{'q99.9':>8}{'UL99.9':>8}")
for name, (dist, a, n) in books.items():
    el, sd = mean_sd(dist, a)
    qs = [quantile(dist, a, al) for al in (0.95, 0.99, 0.999)]
    res[name[0]] = (el, sd, qs, dist, a)
    assert abs(sum(dist) - 1.0) < 1e-12
    assert abs(el - formula_el(n, PD, LGD)) < 1e-9   # distribution mean = formula
    cells = [el, formula_el(n, PD, LGD), sd] + [x for q in qs for x in (q, q - el)]
    print(f"{name:<27}" + "".join(f"{c:8.2f}" for c in cells))

# hand check of book A: P(N <= 1) and P(N <= 2) in closed form
pA = res["A"][3]
p0, p1, p2 = 0.98 ** 10, 10 * 0.02 * 0.98 ** 9, 45 * 0.02 ** 2 * 0.98 ** 8
assert abs(pA[0] + pA[1] - (p0 + p1)) < 1e-14 and abs(pA[2] - p2) < 1e-14
cumA = [p0, p0 + p1, p0 + p1 + p2]                   # closed-form CDF of book A
for al, q in ((0.99, res["A"][2][1]), (0.999, res["A"][2][2])):
    assert q == 40.0 * next(k for k in range(3) if cumA[k] >= al)   # quantile by hand
kB = next(k for k in range(1001) if sum(comb(1000, j) * 0.02 ** j * 0.98 ** (1000 - j) for j in range(k + 1)) >= 0.999)
assert abs(res["B"][2][2] - 0.4 * kB) < 1e-9       # B's 99.9% point from binomial coefficients
print(f"A by hand: P(0)={p0:.6f} P(1)={p1:.6f} P(2)={p2:.6f} P(<=1)={p0+p1:.6f} P(<=2)={p0+p1+p2:.6f}")

g, b = book_pmf(1000, 0.01), book_pmf(1000, 0.11)
print(f"C: normal-year EL {mean_sd(g, 0.4)[0]:.2f}, recession-year EL {mean_sd(b, 0.4)[0]:.2f}")
print(f"per loan: A loss/default {BOOK / 10 * LGD:.2f}, EL {PD * LGD * BOOK / 10:.2f}; "
      f"B loss/default {BOOK / 1000 * LGD:.2f}, EL {PD * LGD * BOOK / 1000:.4f}")
print(f"defaults at q99.9: B {round(res['B'][2][2] / 0.4)}, C {round(res['C'][2][2] / 0.4)}; "
      f"average {round(res['B'][0] / 0.4)}; A P(>=3)={1 - (p0 + p1 + p2):.6f}")

# what breaks
elC, sdC, qC = res["C"][0], res["C"][1], res["C"][2]
standalone = 1000 * (quantile([0.98, 0.02], 0.4, 0.999) - PD * LGD * 1.0)
assert abs(standalone - (res["D"][2][2] - res["D"][0])) < 1e-9   # sum of one-loan ULs = all-or-none book
print(f"wrong: forgot LGD, PD x EAD       {PD * BOOK:8.2f}")
print(f"wrong: capital = q99.9 of C       {qC[2]:8.2f}  right UL {qC[2] - elC:8.2f}")
print(f"wrong: sum of 1000 one-loan UL99.9 {standalone:7.2f}")
print(f"wrong: C read with B's UL99.9     {res['B'][2][2] - res['B'][0]:8.2f}")
print(f"wrong: UL = one sd, book C        {sdC:8.2f}")

# how it moves: concentration (independent loans) and bad years (1000 loans)
for n in (1, 10, 100, 1000):
    d = book_pmf(n, PD)
    print(f"move: {n:>4} loans, UL99.9 {quantile(d, BOOK / n * LGD, 0.999) - PD * LGD * BOOK:8.2f}")
for bad in (0.02, 0.05, 0.08, 0.11, 0.14, 0.20):
    good = max(0.0, (PD - 0.10 * bad) / 0.90)
    d = mixed_pmf(1000, good, bad)
    print(f"move: bad-year PD {bad:.2f}, good {good:.4f}, UL99.9 {quantile(d, 0.4, 0.999) - 8.0:8.2f}")

# chart: chance of each $4 million band of loss, books B and C, in percent
for key in ("B", "C"):
    d = res[key][3]
    bands = [100 * sum(d[10 * j:10 * j + 10]) for j in range(17)]
    print(f"chart {key}: " + ", ".join(f"{x:.2f}" for x in bands))

# road 3: simulated years (splitmix64; defaults found by jumping geometric gaps)
state = 20260928
def rand():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    z ^= z >> 31
    return ((z >> 11) + 1) * 2.0 ** -53              # in (0, 1]

def defaults(n, p):
    count, pos = 0, -1
    while True:
        pos += 1 + int(log(rand()) / log(1.0 - p))
        if pos >= n:
            return count
        count += 1

def simulate(n, a, years, mixed):
    hist = [0] * (n + 1)
    for _ in range(years):
        p = (0.11 if rand() < 0.10 else 0.01) if mixed else PD
        hist[defaults(n, p)] += 1
    dist = [h / years for h in hist]
    return mean_sd(dist, a)[0], quantile(dist, a, 0.99), quantile(dist, a, 0.999)

YEARS = 200_000
for key, n, a, mixed in (("A", 10, 40.0, False), ("C", 1000, 0.4, True)):
    el, q99, q999 = simulate(n, a, YEARS, mixed)
    print(f"sim {key}, {YEARS} years: EL {el:8.2f}  q99 {q99:8.2f}  q99.9 {q999:8.2f}")
    assert abs(el - res[key][0]) < 0.02 * res[key][0]              # mean within 2%
    assert abs(q99 - res[key][2][1]) <= 2 * a                      # 99% point within 2 defaults
    assert abs(q999 - res[key][2][2]) <= 3 * a                     # 99.9% point within 3 defaults
