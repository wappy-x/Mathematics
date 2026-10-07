# Betting on a martingale -- the check behind the card.  Nothing is imported.
# A coin pays the stake on heads and takes it on tails.  Doubling bets $1,
# doubles after each loss and stops at the first win; a pocket of 2^N - 1
# dollars pays for at most N rounds.  Three roads: the formula, exact
# enumeration of every coin sequence, and a seeded simulation (SplitMix64).
MASK = (1 << 64) - 1

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def uniform(self): return (self.next() >> 11) * 2.0 ** -53

def doubling(past):                        # stake for the next round, from the past only
    stake = 1
    for x in past:
        if x == 1: return 0                # already won: stop betting
        stake *= 2
    return stake

def play(tosses, rule, peek=False):        # tosses: +1 heads, -1 tails
    gain, low, staked = 0, 0, 0
    for k in range(len(tosses)):
        h = rule(tosses[:k + 1] if peek else tosses[:k])
        gain += h * tosses[k]; staked += abs(h); low = min(low, gain)
    return gain, -low, staked

def sequences(n):
    return [[1 if (i >> (n - 1 - k)) & 1 else -1 for k in range(n)] for i in range(2 ** n)]

def exact(n, up, down, rule, peek=False):  # numerators over (up + down)^n
    tot = [0, 0, 0, 0]                     # mean gain, P(ahead), deepest debt, total staked
    for w in sequences(n):
        wt = up ** w.count(1) * down ** w.count(-1)
        g, debt, staked = play(w, rule, peek)
        for i, v in enumerate((g, int(g > 0), debt, staked)): tot[i] += wt * v
    return tot

def session(rng, n, heads):                # one capped doubling session, simulated
    gain, stake, low = 0, 1, 0
    for _ in range(n):
        if heads(rng): return gain + stake, -low
        gain -= stake; low = gain; stake *= 2
    return gain, -low

def mean_se(total, total_sq, n):
    m = total / n
    return m, ((total_sq / n - m * m) * n / (n - 1)) ** 0.5 / n ** 0.5

N, RED = 4, 18 / 37
fair = lambda r: r.next() >> 63 == 1
red = lambda r: r.uniform() < RED
rng = SplitMix64(20260929)
e = exact(N, 1, 1, doubling)
den = 2 ** N
print(f"fair coin, pocket ${2 ** N - 1}, at most {N} rounds, {den} sequences")
print(f"formula:    P(ahead) = 1 - 2^-{N} = {1 - 2 ** -N:.6f}, P(all lose) = {2 ** -N:.6f}, loss ${2 ** N - 1}, mean gain = 0")
for k in list(range(1, N + 1)) + [0]:                                   # group sequences by first win
    ws = [w for w in sequences(N) if (w.index(1) + 1 if 1 in w else 0) == k]
    (g, debt), = {play(w, doubling)[:2] for w in ws}                    # one outcome per group
    label = f"first win at round {k}" if k else f"no win in {N} rounds"
    print(f"{label}: probability {len(ws) / den:.6f}, "
          f"stakes {[2 ** j for j in range(k or N)]}, gain {g}, deepest debt {debt}")
print(f"enumerated: P(ahead) = {e[1] / den:.6f}, mean gain = {e[0] / den:.6f}, "
      f"mean deepest debt = {e[2] / den:.6f}, mean staked = {e[3] / den:.6f}")
print("cap N, worst loss, all lose 1 in, P(ahead), mean deepest debt (enumerated), N/2")
for n in range(1, 11):
    t = exact(n, 1, 1, doubling)
    assert 2 * t[2] == n * 2 ** n and t[1] == 2 ** n - 1 and t[0] == 0   # enumeration vs formula
    print(f"table, {n}, {2 ** n - 1}, {2 ** n}, {t[1] / 2 ** n:.6f}, {t[2] / 2 ** n:.6f}, {n / 2:.6f}")
r = exact(N, 18, 19, doubling)
doob = -sum(38 ** (k - 1) * 37 ** (N - k) for k in range(1, N + 1))  # edge -1/37 per dollar staked
print(f"roulette red, 18/37: enumerated mean gain = {r[0] / 37 ** N:.6f}, P(ahead) = {r[1] / 37 ** N:.6f}")
print(f"roulette red, Doob road: edge {-1 / 37:.6f} per dollar x mean staked {r[3] / 37 ** N:.6f} = {doob / 37 ** N:.6f}")
assert r[0] == doob and 37 * r[0] == -r[3]                            # two roads to the house edge
assert r[1] == 37 ** N - 19 ** N                                        # P(ahead) = 1 - (19/37)^N
path, fortune, stake = [0], 0, 1                                        # one sample path, 80 rounds
for _ in range(80):
    if fair(rng): fortune += stake; stake = 1
    else:
        fortune -= stake; stake *= 2
        if stake > 2 ** (N - 1): stake = 1                              # pocket empty: start again
    path.append(fortune)
for i in range(0, 81, 27): print(f"path, rounds {i}-{min(i + 26, 80)}: {path[i:i + 27]}")
table = []                                                              # 32 stakes per strategy, -5..5
def coded(past):                                                        # stake looked up by history
    c = 1
    for x in past: c = 2 * c + (x == 1)
    return table[c]
fair_ok, peek_wins = 0, 0
for trial in range(1000):
    table = [rng.next() % 11 - 5 for _ in range(2 ** (N + 1))]
    fair_ok += exact(N, 1, 1, coded)[0] == 0
    peek_wins += exact(N, 1, 1, coded, peek=True)[0] != 0
print(f"1000 random predictable strategies: mean gain exactly 0 in {fair_ok}")
print(f"same stakes allowed to see the toss: mean gain not 0 in {peek_wins}")
hind = [play(w, lambda past: past[-1], peek=True)[0] for w in sequences(N)]
print(f"hindsight stake = the toss itself: gain on the {den} sequences = {sorted(set(hind))}")
assert fair_ok == 1000 and peek_wins > 900 and set(hind) == {N}
for name, heads, exact_mean in (("fair", fair, 0.0), ("roulette", red, r[0] / 37 ** N)):
    s = s2 = 0
    for _ in range(200000):
        g, _d = session(rng, N, heads); s += g; s2 += g * g
    m, se = mean_se(s, s2, 200000)
    print(f"simulated, {name}, 200000 sessions: mean gain {m:.4f} +/- {se:.4f} (exact {exact_mean:.4f})")
    assert abs(m - exact_mean) < 4 * se                                # simulation vs exact
s = s2 = plays = 0
print("no cap: every play ends $1 ahead; sample mean of the deepest debt")
for target in (10 ** 3, 10 ** 4, 10 ** 5, 10 ** 6):
    while plays < target:
        k = 1
        while not fair(rng): k += 1
        d = 2 ** (k - 1) - 1; s += d; s2 += d * d; plays += 1
    m, se = mean_se(s, s2, plays)
    print(f"uncapped, {plays} plays: mean deepest debt {m:.3f} +/- {se:.3f}")
print("ALL CHECKS PASS")
