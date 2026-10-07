# The rules of probability -- the check behind the card.  Nothing is imported.
# One fair die rolled four times: the chance of at least one six, reached five
# ways -- the complement, a full listing of all 1296 sequences, adding separate
# pieces, inclusion-exclusion, and a seeded simulation.  Chances are kept as
# whole-number counts of equally likely sequences until the last step.
ROLLS, FACES, GAMES, SEED = 4, 6, 200000, 2026

def sequences(n):                          # every run of n rolls, as tuples
    out = [()]
    for _ in range(n):
        out = [s + (f,) for s in out for f in range(1, FACES + 1)]
    return out

def choose(n, k):                          # ways to pick k of n, by Pascal's rule
    row = [1]
    for _ in range(n):
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return row[k]

def splitmix64(state):                     # SplitMix64: returns (new state, draw)
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return state, z ^ (z >> 31)

total = FACES ** ROLLS
none = (FACES - 1) ** ROLLS
road1 = total - none                                        # the complement rule
road2 = sum(1 for s in sequences(ROLLS) if 6 in s)          # list every sequence
pieces = [(FACES - 1) ** (k - 1) * FACES ** (ROLLS - k) for k in range(1, ROLLS + 1)]
road3 = sum(pieces)                                         # first six on roll k
terms = [choose(ROLLS, j) * FACES ** (ROLLS - j) for j in range(1, ROLLS + 1)]
road4 = sum(t if j % 2 == 0 else -t for j, t in enumerate(terms))
state, wins = SEED, 0                                       # road 5: simulate
for _ in range(GAMES):
    six = False
    for _ in range(ROLLS):
        state, z = splitmix64(state)
        six = six or z % FACES == 5                         # remainder 5 = face six
    wins += six
p_hat = wins / GAMES
se = (p_hat * (1 - p_hat) / GAMES) ** 0.5
exact = road1 / total

print(f"one die, {ROLLS} rolls: {FACES}^{ROLLS} = {total} equally likely sequences, {none} with no six")
print(f"road 1, complement: 1 - {none}/{total} = {road1}/{total} = {exact:.6f}")
print(f"road 2, every sequence listed: {road2} of {total} contain a six")
print("road 3, separate pieces, first six on roll " + ", ".join(str(k) for k in range(1, ROLLS + 1))
      + ": " + " + ".join(str(p) for p in pieces) + f" = {road3}")
signed = str(terms[0]) + "".join(f" {'+-'[j % 2]} {t}" for j, t in enumerate(terms[1:], 1))
print(f"road 4, inclusion-exclusion: {signed} = {road4}")
print(f"road 5, simulation, {GAMES} games, seed {SEED}: {wins} wins, "
      f"{p_hat:.4f} with standard error {se:.4f}")
print(f"read back: about {round(100 * exact)} games in 100 show a six; "
      f"the bet pays even money, so the thrower's edge is {2 * exact - 1:.4f} a dollar")

two = sequences(2)                                          # the house example
a = sum(1 for s in two if s[0] == 6)
b = sum(1 for s in two if s[1] == 6)
ab = sum(1 for s in two if s[0] == 6 and s[1] == 6)
no_six2 = sum(1 for s in two if 6 not in s)
print(f"house example, two dice, 36 outcomes: six on first {a}, on second {b}, on both {ab}")
print(f"  at least one six: {a} + {b} - {ab} = {a + b - ab} of 36; "
      f"complement 36 - {no_six2} = {36 - no_six2}; as a chance {(a + b - ab) / 36:.4f}")

three = sequences(3)                                        # three events, a Venn
regions = {}
for s in three:
    key = tuple(int(f == 6) for f in s)
    regions[key] = regions.get(key, 0) + 1
single = [sum(1 for s in three if s[i] == 6) for i in range(3)]
pair = [sum(1 for s in three if s[i] == 6 and s[j] == 6) for i, j in ((0, 1), (0, 2), (1, 2))]
triple = regions[(1, 1, 1)]
ie3 = sum(single) - sum(pair) + triple
union3 = 216 - regions[(0, 0, 0)]
print(f"three rolls, 216 outcomes: {'+'.join(map(str, single))} - "
      f"{'-'.join(map(str, pair))} + {triple} = {ie3}; complement 216 - "
      f"{regions[(0, 0, 0)]} = {union3}; chance {union3 / 216:.4f}")
print(f"figure, Venn regions out of 216: only roll 1 {regions[(1, 0, 0)]}, only roll 2 "
      f"{regions[(0, 1, 0)]}, only roll 3 {regions[(0, 0, 1)]}, rolls 1+2 only "
      f"{regions[(1, 1, 0)]}, 1+3 only {regions[(1, 0, 1)]}, 2+3 only "
      f"{regions[(0, 1, 1)]}, all three {triple}, none {regions[(0, 0, 0)]}")
print("figure, circles radius 62 centred at (135,95), (225,95), (180,160)")

print("chart, rolls n:          " + " ".join(f"{n:>4}" for n in range(1, 13)))
print("chart, at least one six: " + " ".join(f"{1 - (5 / 6) ** n:.2f}" for n in range(1, 13)))
print("chart, n/6 added up:     " + " ".join(f"{n / 6:.2f}" for n in range(1, 13)))
print(f"mistake 1, add four 1/6s: {4 / 6:.4f}; at seven rolls it gives {7 / 6:.4f}, above 1")
print(f"mistake 2, complement of 'all four sixes': 1 - 1/1296 = {1 - 1 / 1296:.4f}")
print(f"mistake 3, stop after the pair terms: ({terms[0]} - {terms[1]})/1296 = "
      f"{(terms[0] - terms[1]) / total:.4f}")
lose24 = 35 ** 24                                           # de Mere's second bet
p24 = (36 ** 24 - lose24) / 36 ** 24
print(f"second bet, a double six in 24 rolls of two dice: 1 - (35/36)^24 = {p24:.6f}; "
      f"the old rule 24/36 = {24 / 36:.4f}")

listed_none = sum(1 for s in sequences(ROLLS) if 6 not in s)
trunc = sum(k - k * (k - 1) // 2 for k in (s.count(6) for s in sequences(ROLLS)))
assert road2 == road1 and none == listed_none         # listing against complement
assert road3 == road2 and road4 == road2              # two more exact roads
assert abs(p_hat - exact) < 4 * se                    # simulation within 4 errors
assert ie3 == union3 and sum(regions.values()) == FACES ** 3
assert a + b - ab == 36 - no_six2                     # house example, two roads
assert trunc == terms[0] - terms[1]                   # mistake 3: k - C(k, 2) per game
assert p24 < 0.5 < exact                              # second bet loses, first wins
print("ALL CHECKS PASS")
