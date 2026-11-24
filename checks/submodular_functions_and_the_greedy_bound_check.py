# Submodular functions -- the check behind the card.  Standard library only.
# Part 1 maximises: book k = 2 of 3 acts to reach the most fan groups; greedy against every pair and the 1 - (1 - 1/k)^k promise.
# Part 2 minimises: which acts move to the tent (costs in £ thousand), by the Lovasz extension, against all 8 sets and a dual certificate.
from math import e, sqrt

ACTS = {"A": {1, 2, 3, 4}, "B": {1, 2, 5}, "C": {3, 4, 6}}
NAMES = "ABC"
SETS = [frozenset(n for i, n in enumerate(NAMES) if m >> i & 1) for m in range(8)]
def word(S): return "".join(sorted(S)) or "none"
def cover(S, acts=ACTS): return len(set().union(*(acts[a] for a in S)))
def reunion(S): return cover(S) + (4 if {"B", "C"} <= S else 0)   # B and C draw 4 more groups only together

def lattice_and_dr(f):                      # both definitions of submodular, over every pair of sets
    lat = sum(f(S) + f(T) >= f(S | T) + f(S & T) for S in SETS for T in SETS)
    dr = sum(f(S | {x}) - f(S) >= f(T | {x}) - f(T) for S in SETS for T in SETS if S <= T for x in NAMES if x not in T)
    return lat, dr

def greedy(f, k, names=NAMES, log=False):   # add the act with the largest gain, ties to the act listed first
    S, best_bound, path = frozenset(), float("inf"), [frozenset()]
    for i in range(k):
        gains = {x: f(S | {x}) - f(S) for x in names if x not in S}
        top = sorted(gains.values(), reverse=True)[:k]
        best_bound = min(best_bound, f(S) + sum(top))   # OPT <= f(S) + the k largest gains (diminishing returns)
        x = max(gains, key=lambda a: (gains[a], -names.index(a)))
        if log: print(f"greedy step {i + 1}: gains " + ", ".join(f"{a} {g}" for a, g in gains.items()) + f"; take {x}; run bound {f(S) + sum(top)}")
        S = S | {x}; path.append(S)
    return S, best_bound, path

def best_of_size(f, k): return max((S for S in SETS if len(S) == k), key=f)   # every set of size k, first best kept
def promise(k): return 1 - (1 - 1 / k) ** k

lat, dr = lattice_and_dr(cover)
print(f"coverage: lattice inequality holds for {lat} of 64 pairs; diminishing returns for {dr} of 27 cases")
print("coverage of every set: " + ", ".join(f"{word(S)} {cover(S)}" for S in SETS))
G, bound, path = greedy(cover, 2, log=True)
O = best_of_size(cover, 2)
print(f"greedy books {word(G)}, {cover(G)} groups; best of all 3 pairs {word(O)}, {cover(O)} groups; run bound {bound}")
print(f"ratio {cover(G) / cover(O):.3f}; promise 1 - (1 - 1/2)^2 = {promise(2):.3f}; 1 - 1/e = {1 - 1 / e:.3f}")
gaps = [cover(O) - cover(S) for S in path]
print(f"gap to the best after 0, 1, 2 picks: {gaps[0]}, {gaps[1]}, {gaps[2]}; proof allows {cover(O)}, {cover(O) / 2:g}, {cover(O) / 4:g}")
print("step inequality OPT <= f(S) + k x gain: " + "; ".join(f"{cover(O)} <= {cover(a)} + 2 x {cover(b) - cover(a)} = {cover(a) + 2 * (cover(b) - cover(a))}" for a, b in zip(path, path[1:])))
print("promise by k: " + " ".join(f"{promise(k):.3f}" for k in range(1, 11)))
TIGHT = {"G": {1, 3}, "H": {2}, "P": {1, 2}, "Q": {3, 4}}          # ties go against greedy
tf = lambda S: cover(S, TIGHT)
TS = greedy(tf, 2, "GHPQ")[0]
print(f"tight case: greedy {word(TS)} {tf(TS)}, best PQ {tf(frozenset('PQ'))}, ratio {tf(TS) / tf(frozenset('PQ')):.3f}")
rl, rd = lattice_and_dr(reunion)
RG = greedy(reunion, 2)[0]
RO = best_of_size(reunion, 2)
print(f"reunion bonus: lattice holds {rl} of 64, diminishing returns {rd} of 27; C adds {reunion(frozenset('C'))} to none, "
      f"{reunion(frozenset('BC')) - reunion(frozenset('B'))} to B; greedy {word(RG)} {reunion(RG)}, best {word(RO)} {reunion(RO)}, ratio {reunion(RG) / reunion(RO):.3f}")

COST = {"A": -3, "B": -1, "C": 3}           # fixed change in running cost when the act moves, before split groups, £ thousand
W = {(a, b): len(ACTS[a] & ACTS[b]) for a in NAMES for b in NAMES if a < b}   # shared fan groups, £1 thousand each when split
def f(S): return sum(COST[a] for a in S) + sum(w for (a, b), w in W.items() if (a in S) != (b in S))
print(f"shared groups A-B {W[('A', 'B')]}, A-C {W[('A', 'C')]}, B-C {W[('B', 'C')]}; f of every set: " + ", ".join(f"{word(S)} {f(S)}" for S in SETS))
fl, fd = lattice_and_dr(f)
print(f"stage cost: lattice holds {fl} of 64, diminishing returns {fd} of 27")

def lovasz(F, x):                           # sort coordinates high to low, weight each new set's increase
    order, S, total, prev = sorted(range(3), key=lambda i: (-x[i], i)), set(), 0.0, 0
    grad = [0] * 3
    for i in order:
        S.add(NAMES[i]); g = F(frozenset(S)) - prev; prev += g
        total += x[i] * g; grad[i] = g
    return total, grad

def by_threshold(F, x, n=100000):          # average of F over the level sets {x_j >= t}, t from 0 to 1
    return sum(F(frozenset(NAMES[i] for i in range(3) if x[i] >= (j + 0.5) / n)) for j in range(n)) / n

x = [0.2, 0.9, 0.5]
L, gx = lovasz(f, x)
print(f"Lovasz extension at A 0.2, B 0.9, C 0.5: sorted sum {L:.3f}; threshold average {by_threshold(f, x):.3f}; greedy vector {' '.join(map(str, gx))}")
state = 2026
def rand():                                 # SplitMix64, seed 2026, uniform on [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64; z = state
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2 ** 64; z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
def worst_midpoint(F, trials=2000):        # largest amount the midpoint value rises above the chord
    worst = -1.0
    for _ in range(trials):
        p, q = [rand() for _ in range(3)], [rand() for _ in range(3)]
        m = [(a + b) / 2 for a, b in zip(p, q)]
        worst = max(worst, lovasz(F, m)[0] - (lovasz(F, p)[0] + lovasz(F, q)[0]) / 2)
    return worst
print(f"midpoint test, 2000 random pairs: stage cost worst rise {max(0.0, worst_midpoint(f)):.3f}; reunion worst rise {worst_midpoint(reunion):.3f}")
xk, best = [0.5, 0.5, 0.5], (f(frozenset()), frozenset())
for k in range(60):                         # projected subgradient descent on the cube [0, 1]^3, step 0.5 / sqrt(k + 1)
    val, g = lovasz(f, xk)
    for t in xk:                            # every level set of the iterate is a candidate answer
        S = frozenset(NAMES[i] for i in range(3) if xk[i] >= t); best = min(best, (f(S), S), key=lambda b: b[0])
    if k in (0, 1, 2, 59): print(f"descent k = {k}: x = {' '.join(f'{v:.3f}' for v in xk)}, extension {val:.3f}, best level set {word(best[1])} {best[0]}")
    xk = [min(1.0, max(0.0, xi - 0.5 / sqrt(k + 1) * gi)) for xi, gi in zip(xk, g)]
y1, y2 = lovasz(f, [1, 0.9, 0])[1], lovasz(f, [0.9, 1, 0])[1]
y = [(a + b) / 2 for a, b in zip(y1, y2)]
print(f"certificate: greedy vectors {' '.join(map(str, y1))} and {' '.join(map(str, y2))}, average {' '.join(f'{v:g}' for v in y)}; "
      f"floor {sum(min(0, v) for v in y):g}; y(S) <= f(S) for {sum(sum(y[NAMES.index(a)] for a in S) <= f(S) for S in SETS)} of 8 sets")
fmin = min(SETS, key=f)
moves = [(word(S), f(S)) for S in SETS if len(S) == 1]
print(f"all 8 sets: least f is {word(fmin)} at {f(fmin)}; single moves from none: {', '.join(f'{a} {v}' for a, v in moves)}, none improves on 0")

assert (lat, dr) == (64, 27) and (fl, fd) == (64, 27)              # both definitions agree, on both functions
assert cover(G) == 5 and cover(O) == 6 and cover(G) >= promise(2) * cover(O) and bound == 6   # the theorem against enumeration
assert all(g <= cover(O) * (1 - 1 / 2) ** i for i, g in enumerate(gaps))                       # the gap halves at least
assert tf(TS) / tf(frozenset("PQ")) == promise(2)                   # the promise is reached
assert rl < 64 and rd < 27 and reunion(RG) / reunion(RO) < promise(2)  # no diminishing returns, no promise
assert abs(L - by_threshold(f, x)) < 1e-3 and worst_midpoint(f) < 1e-12 < worst_midpoint(reunion)
assert best == (f(fmin), fmin) and sum(min(0, v) for v in y) == f(fmin) and all(sum(y[NAMES.index(a)] for a in S) <= f(S) for S in SETS)
C7 = dict(ACTS, C={3, 4, 6, 7})             # try: act C reaches a seventh group
c7 = lambda S: cover(S, C7)
S7, O7 = greedy(c7, 2)[0], best_of_size(c7, 2)
print(f"try C reaching group 7: greedy {word(S7)} {c7(S7)}, best {word(O7)} {c7(O7)}, ratio {c7(S7) / c7(O7):.3f}")
S3 = greedy(cover, 3)[0]
print(f"try k = 3: greedy {word(S3)} {cover(S3)}, best {cover(frozenset(NAMES))}, ratio {cover(S3) / cover(frozenset(NAMES)):.3f}")
f2 = lambda S: f(S) + sum(w for (a, b), w in W.items() if (a in S) != (b in S))   # try: £2 thousand per split group
m2 = min(SETS, key=f2)
print(f"try £2 thousand per split group: " + ", ".join(f"{word(S)} {f2(S)}" for S in SETS) + f"; least {word(m2)} at {f2(m2)}")
print("ALL CHECKS PASS")
