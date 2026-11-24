# Sufficient statistics -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  Roads: brute force over all 1,024
# answer lists, the factorisation formula, a likelihood-ratio grouping that never
# mentions the count, and a seeded simulation (SplitMix64, same draws as Rust).
from math import comb, log, exp
from itertools import product

N, T = 10, 7                                   # the poll in miniature: 10 answers, 7 yes
LISTS = list(product((0, 1), repeat=N))        # all 1,024 possible answer lists

def chance(x, p):                              # one exact list: p per yes, 1 - p per no
    out = 1.0
    for a in x: out *= p if a else 1 - p
    return out

def fisher(groups, p, h=1e-6):                 # information kept by a summary
    info = 0.0                                 # groups: summary value -> its lists
    for xs in groups.values():
        q = sum(chance(x, p) for x in xs)
        dq = (sum(chance(x, p + h) for x in xs) - sum(chance(x, p - h) for x in xs)) / (2 * h)
        info += dq * dq / q
    return info

def group_by(key):
    g = {}
    for x in LISTS: g.setdefault(key(x), []).append(x)
    return g

M64 = (1 << 64) - 1
state = [20261123]
def unif():                                    # SplitMix64: a uniform number in [0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

# ---- road 1: the conditional law of the list, given the count 7 ----
seven = [x for x in LISTS if sum(x) == T]
print(f"lists with 7 yes out of 10: {len(seven)}; C(10, 7) = {comb(N, T)}")
worst = 0.0
for p in (0.3, 0.52, 0.9):
    one, total = chance(seven[0], p), sum(chance(x, p) for x in seven)
    cond = [chance(x, p) / total for x in seven]
    worst = max(worst, max(abs(c - 1 / 120) for c in cond))
    print(f"p = {p:.2f}: one list {one:.8f}; count 7 {total:.6f}; one list given 7 {one / total:.6f}")
assert len(seven) == comb(N, T) and worst < 1e-12

# ---- road 2: the factorisation g(t, p) h(x), h = 1, against brute force ----
gap = max(abs(chance(x, 0.52) - 0.52 ** sum(x) * 0.48 ** (N - sum(x))) for x in LISTS)
by_count = group_by(sum)                       # rebuild: draw the count, then shuffle it
law_t = {t: sum(chance(x, 0.52) for x in xs) for t, xs in by_count.items()}
rebuilt = max(abs(law_t[sum(x)] / len(by_count[sum(x)]) - chance(x, 0.52)) for x in LISTS)
print(f"all 1,024 lists: brute chance = g(t,p)h(x): {'yes' if gap < 1e-15 else 'no'}; "
      f"law rebuilt from the count = real law: {'yes' if rebuilt < 1e-15 else 'no'}")
assert gap < 1e-15 and rebuilt < 1e-15

# ---- road 3: simulate. Given 7 yes, is the first answer yes 70% of the time? ----
for p in (0.52, 0.9):
    hits = first = 0
    for _ in range(200000):
        x = [1 if unif() < p else 0 for _ in range(N)]
        if sum(x) == T:
            hits += 1
            first += x[0]
    print(f"simulated, p = {p:.2f}: {hits} polls with 7 yes; first answer yes in {first / hits:.4f}")
    assert abs(first / hits - 0.7) < 0.02

# ---- what a summary keeps: Fisher information at p = 0.7 ----
infos = [("whole list", group_by(lambda x: x)), ("count of yes", group_by(sum)),
         ("counts in each half", group_by(lambda x: (sum(x[:5]), sum(x[5:])))),
         ("count in first half", group_by(lambda x: sum(x[:5]))),
         ("majority yes or not", group_by(lambda x: sum(x) >= 6)),
         ("first answer only", group_by(lambda x: x[0]))]
for name, g in infos:
    print(f"information kept, {name:<20} {fisher(g, 0.7):10.6f}   ({len(g)} values)")
print(f"formula n / (p(1 - p)) = {N / (0.7 * 0.3):.6f}")
assert abs(fisher(infos[0][1], 0.7) - N / 0.21) < 1e-4 and abs(fisher(infos[1][1], 0.7) - N / 0.21) < 1e-4
assert fisher(infos[4][1], 0.7) < 0.5 * N / 0.21

# ---- minimal: group lists whose likelihood ratio does not move with p ----
grid = [i / 10 for i in range(1, 10)]
def ratio_key(x):                              # ln P(x; p) - ln P(x; 0.5) on a grid, never the count
    return tuple(round(log(chance(x, p)) - log(chance(x, 0.5)), 9) for p in grid)
classes = group_by(ratio_key)
same = all(len({sum(x) for x in xs}) == 1 for xs in classes.values())
print(f"classes of equal likelihood ratio: {len(classes)}; each class is one count: {'yes' if same else 'no'}")
assert len(classes) == 11 and same

# ---- the shuttle: waits Uniform(0, theta), observed 2.1, 4.7, 3.3 minutes ----
waits, twin, same_sum = [2.1, 4.7, 3.3], [0.4, 4.7, 1.0], [3.3, 3.4, 3.4]
def lik(w, th):                                # independent waits multiply: 1/theta each in [0, theta]
    out = 1.0
    for v in w: out *= 1 / th if 0 <= v <= th else 0.0
    return out
for th in (4.5, 4.7, 5.0, 6.0, 8.0):
    print(f"theta = {th:.1f}: likelihood {lik(waits, th):.6f}; same-maximum twin {lik(twin, th):.6f}")
pts = [4.0 + 0.1 * i for i in range(21)]
print("chart, likelihood x 1000, theta 4.0 to 6.0:", " ".join(f"{1000 * lik(waits, t):.2f}" for t in pts))
best = max(pts + [4.7], key=lambda t: lik(waits, t))
print(f"peak at theta = {best:.1f}; sums {sum(waits):.1f} and {sum(same_sum):.1f}; "
      f"at theta = 4.0: {lik(waits, 4.0):.6f} vs {lik(same_sum, 4.0):.6f}")
wrong = min((0.1 * i for i in range(1, 101)), key=lambda t: -t ** -3)
print(f"indicator dropped, theta^-3 alone: peak at the search floor {wrong:.1f}")
assert all(lik(waits, t) == lik(twin, t) for t in pts) and abs(best - 4.7) < 1e-12
assert lik(waits, 4.0) == 0.0 and lik(same_sum, 4.0) > 0.0
for th in (5.0, 9.0):                          # given a maximum near 4.7, the rest ignore theta
    hits, rest = 0, 0.0
    for _ in range(400000):
        w = [th * unif() for _ in range(3)]
        w.sort()
        if 4.6 <= w[2] <= 4.8:
            hits += 1
            rest += (w[0] + w[1]) / 2
    print(f"simulated, theta = {th:.0f}: {hits} samples with maximum in 4.6-4.8; mean of the other two {rest / hits:.4f}")
    assert abs(rest / hits - 2.35) < 0.05

# ---- the normal with known spread 0.02: the median is not sufficient ----
A, B = [0.49, 0.51, 0.52, 0.54, 0.54], [0.51, 0.51, 0.52, 0.52, 0.59]
C, s2 = [0.50, 0.50, 0.50, 0.55, 0.55], 0.02 ** 2
def lnratio(x, y, mu):                         # ln of L(mu; x) / L(mu; y)
    return (sum((v - mu) ** 2 for v in y) - sum((v - mu) ** 2 for v in x)) / (2 * s2)
med = lambda v: sorted(v)[2]
print(f"medians A, B, C: {med(A):.2f} {med(B):.2f} {med(C):.2f}; means {sum(A) / 5:.3f} {sum(B) / 5:.3f} {sum(C) / 5:.3f}")
for mu in (0.50, 0.52, 0.54):
    print(f"mu = {mu:.2f}: L(A)/L(B) = {exp(lnratio(A, B, mu)):.4f}; L(A)/L(C) = {exp(lnratio(A, C, mu)):.4f}")
assert abs(lnratio(A, B, 0.50) - lnratio(A, B, 0.54)) > 1.0
assert abs(lnratio(A, C, 0.50) - lnratio(A, C, 0.54)) < 1e-9
print("ALL CHECKS PASS")
