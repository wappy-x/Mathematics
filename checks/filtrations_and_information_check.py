# Filtrations and predictable stakes -- the check behind the card.  Only math
# is imported, for one square root.  A gambler starts with 10 chips and plays
# three fair rounds; a round pays the stake on a win and takes it on a loss.
# The 8 win/loss histories are the outcomes.  What is known after n rounds is
# a partition of them into cells; a quantity is known when it is constant on
# every cell.  A stake is predictable when it is known one round before its toss.
import math

N, START, NIGHTS, SEED = 3, 10, 100000, 2026
MASK = (1 << 64) - 1
PATHS = [tuple(1 - 2 * ((p >> (N - 1 - k)) & 1) for k in range(N)) for p in range(2 ** N)]

def word(path):                              # +1 is a win W, -1 a loss L
    return "".join("W" if x > 0 else "L" for x in path)

def cells(n):                                # paths grouped by their first n tosses
    out = {}
    for i, p in enumerate(PATHS):
        out.setdefault(p[:n], []).append(i)
    return list(out.values())

def known(values, groups):                   # constant on every cell?
    return all(len({values[i] for i in c}) == 1 for c in groups)

def chase(toss, chips):                      # 2 chips when behind 10, else 1
    return 2 if chips < START else 1

def flat(toss, chips):
    return 1

def peek(toss, chips):                       # sits out every round it will lose
    return 1 if toss > 0 else 0

def play(path, rule):                        # chips after each round, and stakes
    chips, xs, stakes = START, [START], []
    for toss in path:
        s = rule(toss, chips)
        chips += s * toss
        xs.append(chips)
        stakes.append(s)
    return xs, stakes

def splitmix(state):                         # SplitMix64, written out
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

# road one, exact: count the questions settled by round n two ways, by brute
# force over all 256 yes/no labellings of the 8 paths and as 2 to the cells
brute = [sum(known([(f >> i) & 1 for i in range(8)], cells(n)) for f in range(256)) for n in range(N + 1)]
formula = [2 ** len(cells(n)) for n in range(N + 1)]
nested = all(any(set(a) <= set(b) for b in cells(n)) for n in range(N) for a in cells(n + 1))
print(f"{len(PATHS)} histories, probability {1 / len(PATHS):.3f} each; a round is won on "
      f"{sum(p[0] > 0 for p in PATHS)} of them, probability {sum(p[0] > 0 for p in PATHS) / len(PATHS):.3f}")
print("cells after rounds 0..3:", [len(cells(n)) for n in range(N + 1)])
print(f"events known after rounds 0..3, by brute force: {brute}; by 2^cells: {formula}")
print("each cell lies inside one cell of the round before:", "yes" if nested else "no")

plays = {name: [play(p, r) for p in PATHS] for name, r in (("flat", flat), ("chase", chase), ("peek", peek))}
flags = {}
for name in plays:
    st = [[s[k] for _, s in plays[name]] for k in range(N)]
    pred = all(known(st[k], cells(k)) for k in range(N))
    adap = all(known(st[k], cells(k + 1)) for k in range(N))
    flags[name] = (pred, adap)
    fin = [x[-1] for x, _ in plays[name]]
    print(f"{name}: predictable {'yes' if pred else 'no'}, adapted {'yes' if adap else 'no'}, "
          f"final chips {fin}, mean {sum(fin) / 8:.3f}, below 10 on {sum(f < START for f in fin)} of 8")
for p, (xs, st) in zip(PATHS, plays["chase"]):
    print(f"  chase {word(p)}: chips {xs}, stakes {st}")
fortune_known = all(known([x[n] for x, _ in plays["chase"]], cells(n)) for n in range(N + 1))
print("chase fortune known after each round (adapted):", "yes" if fortune_known else "no")
last = [[i for i, p in enumerate(PATHS) if p[1] == s] for s in (1, -1)]
r3 = [s[2] for _, s in plays["chase"]]
print(f"chase round-3 stake from the round-2 toss alone: {'possible' if known(r3, last) else 'not possible'}; "
      f"stakes after WL and LL: {r3[2]} and {r3[6]}")

gain = lambda name, k, idx: sum(plays[name][i][1][k] * PATHS[i][k] for i in idx) / len(idx)
print(f"mean gain in one round: chase round 2 after a first loss {gain('chase', 1, range(4, 8)):.3f}, "
      f"after a first win {gain('chase', 1, range(4)):.3f}; peek round 1 {gain('peek', 0, range(8)):.3f}")

# road two: every stake rule with stakes 0 or 1, 128 predictable, 16384 adapted
pred_means, adap_means = set(), []
for g in range(2 * 4 * 16):
    g1, g2, g3 = g & 1, (g >> 1) & 3, g >> 3
    tot = sum(START + sum(((gk >> (i >> (N - k))) & 1) * PATHS[i][k] for k, gk in enumerate((g1, g2, g3))) for i in range(8))
    pred_means.add(tot / 8)
for f1 in range(4):
    for f2 in range(16):
        for f3 in range(256):
            tot = sum(START + sum(((fk >> (i >> (N - 1 - k))) & 1) * PATHS[i][k] for k, fk in enumerate((f1, f2, f3))) for i in range(8))
            adap_means.append(tot / 8)
print(f"predictable rules: {2 * 4 * 16}, distinct mean finals: {', '.join(f'{m:.3f}' for m in sorted(pred_means))}")
print(f"adapted rules: {len(adap_means)}, mean finals from {min(adap_means):.3f} to {max(adap_means):.3f}; "
      f"formula 10 - 1.5 to 10 + 1.5, the peek rule at the top")

# road three: simulate the chase and peek rules with a seeded generator
state, sims = SEED, {"chase": [0.0, 0.0], "peek": [0.0, 0.0]}
for _ in range(NIGHTS):
    path = []
    for _ in range(N):
        state, z = splitmix(state)
        path.append(1 if z >> 63 else -1)
    for name, rule in (("chase", chase), ("peek", peek)):
        f = play(tuple(path), rule)[0][-1]
        sims[name][0] += f
        sims[name][1] += f * f
se = {}
for name, (s1, s2) in sims.items():
    m = s1 / NIGHTS
    se[name] = (m, math.sqrt((s2 / NIGHTS - m * m) / NIGHTS))
    print(f"simulated {name}, {NIGHTS} nights, seed {SEED}: mean {m:.4f}, standard error {se[name][1]:.4f}")

xs = [50 + 90 * n for n in range(N + 1)]
nodes = sorted({(n, x[n]) for x, _ in plays["chase"] for n in range(N + 1)})
print("figure, x = 50 + 90 * round, y = 200 - 20 * (chips - 5):",
      " ".join(f"({xs[n]},{200 - 20 * (c - 5)})" for n, c in nodes))

assert brute == formula == [2, 4, 16, 256] and nested                 # two roads to the counts
assert [sum(x[-1] for x, _ in plays[n]) for n in ("chase", "peek")] == [8 * START, 8 * START + 12]
assert pred_means == {10.0} and (min(adap_means), max(adap_means)) == (START - N / 2, START + N / 2)
assert abs(se["chase"][0] - START) < 4 * se["chase"][1] and abs(se["peek"][0] - 11.5) < 4 * se["peek"][1]
assert flags == {"flat": (True, True), "chase": (True, True), "peek": (False, True)}
assert fortune_known and not known(r3, last)                          # chase needs the whole past
print("ALL CHECKS PASS")
