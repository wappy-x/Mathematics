# Entropy -- the check behind the card.  Standard library only: math.log2 and
# math.log are the only imports, and neither knows what entropy is.
# A weather station sends one forecast a day: sunny, cloudy, rain or snow.
# The entropy of its forecast is reached four ways: the formula, the question
# tree played outcome by outcome, one yes-or-no question at a time, and a
# seeded simulation that counts the questions it actually asks.
from math import log2, log

NAMES = ["sunny", "cloudy", "rain", "snow"]
P = [0.5, 0.25, 0.125, 0.125]            # the station's forecast chances
WINTER = [0.125, 0.125, 0.25, 0.5]       # a snowy month, same four outcomes
SEED = 2026                              # the simulation's starting state

def term(p):                             # one outcome's share: p x log2(1/p), 0 when p = 0
    return 0.0 if p == 0 else p * log2(1 / p)

def H(ps):                               # road 1: the formula
    return sum(term(p) for p in ps)

def h(p):                                # binary entropy: a yes-or-no with chance p
    return term(p) + term(1 - p)

def questions(k):                        # play the tree: sunny? then cloudy? then rain?
    asked = 0
    for guess in range(3):
        asked += 1
        if k == guess or guess == 2:     # a yes ends it; a no to "rain?" means snow
            return asked
    return asked

MASK = (1 << 64) - 1
def splitmix64(state):                   # small seeded generator, written out
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

def draw(u, ps):                         # which outcome a uniform number u picks
    acc = 0.0
    for k, p in enumerate(ps):
        acc += p
        if u < acc:
            return k
    return len(ps) - 1

H1 = H(P)
qs = [questions(k) for k in range(4)]
tree = sum(p * q for p, q in zip(P, qs))                       # road 2
chain = h(0.5) + 0.5 * (h(0.5) + 0.5 * h(0.5))                 # road 3
state, n, total, total_sq, year = SEED, 100000, 0, 0, 0       # road 4
for day in range(n):
    state, z = splitmix64(state)
    q = questions(draw((z >> 11) / 2.0**53, P))
    total += q
    total_sq += q * q
    if day == 364:
        year = total
mean = total / n
se = ((total_sq / n - mean * mean) / n) ** 0.5
gap = sum(p * log2(p / 0.25) for p in P)
grid, best, best_at = 0, -1.0, None
for a in range(21):
    for b in range(21 - a):
        for c in range(21 - a - b):
            ks = (a, b, c, 20 - a - b - c)
            grid += 1
            v = H([k / 20 for k in ks])
            if v > best:
                best, best_at = v, ks
curve = [h(i / 20) for i in range(21)]
climates = [("every day sunny", [1.0, 0.0, 0.0, 0.0]), ("desert", [0.85, 0.1, 0.04, 0.01]),
            ("our station", P), ("four-way spread", [0.4, 0.3, 0.2, 0.1]),
            ("all four equal", [0.25] * 4)]
winter_cost = sum(p * q for p, q in zip(WINTER, qs))
winter_kl = sum(p * log2(p / 2.0**-q) for p, q in zip(WINTER, qs))

print("forecast: " + ", ".join(f"{a} {p}" for a, p in zip(NAMES, P)))
print("surprise log2(1/p), bits: " + ", ".join(f"{a} {log2(1 / p):.4f}" for a, p in zip(NAMES, P)))
print(f"road 1, the formula: H = {H1:.4f} bits")
print(f"road 2, the question tree: questions {qs}, weighted average {tree:.4f}")
print(f"road 3, one question at a time: h(0.5) + 0.5 x (h(0.5) + 0.5 x h(0.5)) = {chain:.4f}")
print(f"road 4, {n} simulated days, seed {SEED}: {total} questions, {mean:.4f} a day, standard error {se:.4f}")
print(f"first simulated year, 365 days: {year} questions, against {2 * 365} for two fixed bits a day")
print(f"expected over 365 days: {365 * H1:.2f} bits by questions, {365 * 2:.2f} by two fixed bits")
print(f"all four equal: H = {H([0.25] * 4):.4f} bits; log2 4 = {log2(4):.4f}")
print(f"gap to all-equal, sum of p log2(p / 0.25): {gap:.4f}; 2 - H = {2 - H1:.4f}")
print(f"grid search, {grid} forecasts in steps of 0.05: largest H {best:.4f} at {[k / 20 for k in best_at]}")
print("binary entropy h(p), p = 0, 0.05, ..., 1:")
print(" ".join(f"{v:.3f}" for v in curve))
print(f"h(0.5) sunny or not {h(0.5):.4f}; h(0.125) snow or not {h(0.125):.4f}; "
      f"h(0.05) {h(0.05):.4f}; h(0.95) {h(0.95):.4f}")
for name, ps in climates:
    v = H(ps)
    print(f"{name:<16} {'#' * int(v * 20 + 0.5):<40} {v:.4f}")
print(f"mistake 1, natural log in place of log2: {sum(p * log(1 / p) for p in P):.4f}")
print(f"mistake 2, questions averaged without weights: {sum(qs) / 4:.4f}")
print(f"mistake 3, usual tree on winter weather: {winter_cost:.4f} a day; "
      f"winter's own H {H(WINTER):.4f}; extra {winter_kl:.4f}")
print(f"mistake 4, counting outcomes, log2 4: {log2(4):.4f}, {log2(4) - H1:.4f} too many")
print(f"sunny then snow: chance {0.5 * 0.125}, surprise {log2(1 / (0.5 * 0.125)):.4f} = 1 + 3")
print(f"asides: 1 nat = {1 / log(2):.4f} bits; log2 26 = {log2(26):.4f}; log2 3 = {log2(3):.4f}; "
      f"h(0.01) = {h(0.01):.4f}; 2^20 = {2**20}")

assert abs(H1 - tree) < 1e-12 and abs(H1 - chain) < 1e-12           # roads 1, 2, 3 agree
assert abs(mean - H1) < 4 * se                                       # road 4, within 4 errors
assert best_at == (5, 5, 5, 5) and abs(best - log2(4)) < 1e-12       # all-equal is the top
assert all(abs(H([a / 20, 1 - a / 20, 0, 0]) - h(a / 20)) < 1e-12 for a in range(21))  # zero chances add nothing
assert abs(gap - (2 - H1)) < 1e-12                                   # the gap is the divergence
assert all(abs(curve[i] - curve[20 - i]) < 1e-12 for i in range(21)) and max(curve) == curve[10]
assert abs(winter_cost - (H(WINTER) + winter_kl)) < 1e-12 and winter_cost > 2
print("ALL CHECKS PASS")
