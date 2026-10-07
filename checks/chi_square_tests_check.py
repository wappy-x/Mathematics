# Chi-square tests -- the check behind the card.  Only math.sqrt, math.exp,
# math.log and math.pi are imported.  Two questions.  Dice: 60 rolls came out
# 5, 7, 8, 10, 12, 18; is the die fair?  Trial: 45 of 100 recovered on the drug,
# 35 of 100 on placebo; is recovery independent of treatment?  Every tail is
# built here: a gamma series, Simpson's rule on the density, an exact sum over
# every tally, and a seeded simulation (SplitMix64, seed 20260928).
from math import sqrt, exp, log, pi
M64 = 2**64 - 1

def Phi(z):                               # bell area left of z, Taylor series
    term, total, j = z, z, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        j += 1
        term *= -z * z * (2 * j - 1) / (2 * j * (2 * j + 1))
        total += term
    return 0.5 + total / sqrt(2.0 * pi)

def gamma_half(a):                        # Gamma(a) for a = 1/2, 1, 3/2, ...
    g, x = (sqrt(pi), 0.5) if (2 * a) % 2 else (1.0, 1.0)
    while x < a: g, x = g * x, x + 1
    return g

def tail_series(q, df):                   # road one: 1 - lower gamma series
    a, x = df / 2, q / 2
    term, total, j = 1.0 / (a * gamma_half(a)), 0.0, 0
    while term > 1e-18 * max(total, 1e-300):
        total += term
        j += 1
        term *= x / (a + j)
    return 1 - exp(-x + a * log(x)) * total

def density(t, df):                       # the chi-square density
    return exp((df / 2 - 1) * log(t) - t / 2) / (2 ** (df / 2) * gamma_half(df / 2))

def tail_simpson(q, df, m=20000):         # road two: area from q to q + 200
    h = 200.0 / m
    s = density(q, df) + density(q + 200, df)
    s += sum((4 if i % 2 else 2) * density(q + i * h, df) for i in range(1, m))
    return s * h / 3

def cut(df, alpha=0.05):                  # bisection: the tail equals alpha
    a, b = 0.0, 100.0
    for _ in range(200):
        m = 0.5 * (a + b)
        a, b = (m, b) if tail_series(m, df) > alpha else (a, m)
    return 0.5 * (a + b)

LF = [0.0]
for i in range(1, 201): LF.append(LF[-1] + log(i))

def tallies(n, k, top=None):              # every tally c1 >= c2 >= ... >= ck
    top = n if top is None else top
    if k == 1:
        if n <= top: yield (n,)
        return
    for c in range(min(n, top), -1, -1):
        for rest in tallies(n - c, k - 1, c): yield (c,) + rest

def exact_law(n, k):                      # road three: (Q, chance) for every tally
    law, e = [], n / k
    for t in tallies(n, k):
        orders = LF[k] - sum(LF[t.count(v)] for v in set(t))
        chance = exp(LF[n] - sum(LF[c] for c in t) - n * log(k) + orders)
        law.append((sum((c - e) ** 2 for c in t) / e, chance))
    return law

def pearson(obs, exp_):                   # the statistic itself
    return sum((o - e) ** 2 / e for o, e in zip(obs, exp_))

state = 20260928                          # SplitMix64, the same stream as the Rust
def next64():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & M64
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & M64
    return x ^ (x >> 31)

DICE = [5, 7, 8, 10, 12, 18]
q_dice = pearson(DICE, [10] * 6)
c5, c1, SMALL = cut(5), cut(1), 12        # SMALL: rolls in the small session
law60 = exact_law(60, 6)
exact_p = sum(w for q, w in law60 if q >= q_dice - 1e-9)
mean_q = sum(q * w for q, w in law60)
var_q = sum(q * q * w for q, w in law60) - mean_q ** 2
size60 = sum(w for q, w in law60 if q > c5)
size12 = sum(w for q, w in exact_law(SMALL, 6) if q > c5)
print("dice: counts " + ", ".join(str(o) for o in DICE) + "; expected 10 each")
print("  gaps squared over 10: " + ", ".join(f"{(o - 10) ** 2 / 10:.1f}" for o in DICE))
print(f"  Q = {q_dice:.4f}, degrees of freedom 5")
print(f"  tail, gamma series        {tail_series(q_dice, 5):.6f}")
print(f"  tail, Simpson on density  {tail_simpson(q_dice, 5):.6f}")
print(f"  tail, exact sum over {len(law60)} tallies {exact_p:.6f}")
print(f"  exact mean of Q {mean_q:.6f} (k - 1 = 5); variance {var_q:.6f} (2 x 5 x 59/60 = {2 * 5 * 59 / 60:.6f})")
print(f"  5% cut, 5 degrees of freedom {c5:.4f}; 1 degree {c1:.4f}")
print(f"  exact chance fair die rejected at the 5% cut: 60 rolls {size60:.4f}, {SMALL} rolls {size12:.4f}")
RUNS, hit_p, hit_c = 20000, 0, 0
for _ in range(RUNS):                     # one run = 60 rolls of a fair die
    cnt = [0] * 6
    for _ in range(60): cnt[int((next64() >> 11) / 2**53 * 6)] += 1
    q = pearson(cnt, [10] * 6)
    hit_p += q >= q_dice - 1e-9
    hit_c += q > c5
for label, h, ex in ((f"Q >= {q_dice:.1f}", hit_p, exact_p), ("Q > 5% cut", hit_c, size60)):
    s = h / RUNS
    se = sqrt(s * (1 - s) / RUNS)
    print(f"  simulated {label:<11}{s:.4f}  se {se:.4f}  (sim - exact)/se {(s - ex) / se:>5.2f}")
    assert abs(s - ex) < 4 * se                                    # simulation agrees
print("chart, Q at least  " + " ".join(f"{x:>6d}" for x in range(0, 21, 2)))
print("chart, exact %     " + " ".join(f"{100 * sum(w for q, w in law60 if q >= x - 1e-9):6.2f}" for x in range(0, 21, 2)))
print("chart, chi-sq 5 %  " + " ".join(f"{100 * tail_series(x, 5) if x else 100.0:6.2f}" for x in range(0, 21, 2)))
T = [[45, 55], [35, 65]]                  # rows: drug, placebo; columns: recovered, not
R, C, n = [sum(r) for r in T], [T[0][j] + T[1][j] for j in range(2)], 200
E = [[R[i] * C[j] / n for j in range(2)] for i in range(2)]
q_cells = pearson(sum(T, []), sum(E, []))
a, b, c, d = 45, 55, 35, 65
q_short = n * (a * d - b * c) ** 2 / (R[0] * R[1] * C[0] * C[1])
pool = C[0] / n
z = (a / 100 - c / 100) / sqrt(pool * (1 - pool) * (1 / 100 + 1 / 100))
def binom(m, p): return [exp(LF[m] - LF[j] - LF[m - j] + j * log(p) + (m - j) * log(1 - p)) for j in range(m + 1)]
bp = binom(100, pool)
def q22(x, y):                            # the 2 x 2 statistic for x and y recovered
    s = x + y
    return 0.0 if s in (0, 200) else 200 * (x - y) ** 2 / (s * (200 - s))
exact_22 = sum(bp[x] * bp[y] for x in range(101) for y in range(101) if q22(x, y) >= q_cells - 1e-9)
print(f"trial: expected drug {E[0][0]:.1f} {E[0][1]:.1f}, placebo {E[1][0]:.1f} {E[1][1]:.1f}; pooled rate {pool:.2f}")
print(f"  Q by cells {q_cells:.6f}; by n(ad - bc)^2 / margins {q_short:.6f}; z^2 {z * z:.6f} (z = {z:.6f})")
print(f"  tail, gamma series 1 d.f. {tail_series(q_cells, 1):.6f}; Simpson {tail_simpson(q_cells, 1):.6f}; 2(1 - Phi(z)) {2 * (1 - Phi(z)):.6f}")
print(f"  exact tail, both arms binomial at 0.40: {exact_22:.6f}")
print("what breaks:")
print(f"  dice, 6 degrees of freedom: p {tail_series(q_dice, 6):.6f}, cut {cut(6):.4f}")
print(f"  trial, 3 degrees of freedom: p {tail_series(q_cells, 3):.6f}")
print(f"  dice, proportions fed in: Q {pearson([o / 60 for o in DICE], [1 / 6] * 6):.6f}, p {tail_series(pearson([o / 60 for o in DICE], [1 / 6] * 6), 5):.6f}")
print(f"  dice, every roll written down twice: Q {pearson([2 * o for o in DICE], [20] * 6):.4f}, p {tail_series(2 * q_dice, 5):.6f}")
assert abs(tail_series(q_dice, 5) - tail_simpson(q_dice, 5)) < 1e-8       # two roads to one tail
assert abs(mean_q - 5) < 1e-9 and abs(var_q - 2 * 5 * 59 / 60) < 1e-8     # exact moments by enumeration
assert abs(q_cells - z * z) < 1e-12 and abs(q_short - q_cells) < 1e-12    # three forms of the 2 x 2
assert abs(tail_series(q_cells, 1) - 2 * (1 - Phi(z))) < 1e-10            # chi-square 1 = z squared
assert abs(exact_p - tail_series(q_dice, 5)) < 0.01 and size12 < 0.04     # close at 60, off at 12
print("ALL CHECKS PASS")
