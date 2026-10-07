# Expectation -- the check behind the card.  Nothing is imported.  A raffle
# sells 100 tickets at $2; one ticket, drawn at random, wins $100.  One
# ticket's payout X is 0 with chance 0.99 and 100 with chance 0.01.  E[X] is
# reached three ways: the weighted sum, a count over all 100 tickets, and a
# seeded simulation.  Linearity is checked on five tickets in one draw
# (dependent) and five tickets in five draws (independent).
M = (1 << 64) - 1

class SplitMix64:                        # the random numbers, written out here
    def __init__(self, seed):
        self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return z ^ (z >> 31)
    def uniform(self):                   # a number in [0, 1), 53 bits
        return (self.next() >> 11) / 9007199254740992.0

PRICE, PRIZE, SOLD = 2.0, 100.0, 100
law = [(0.0, 0.99), (PRIZE, 0.01)]                    # value, chance

def expect(pairs, g=lambda x: x):        # road one: the weighted sum
    return sum(g(x) * p for x, p in pairs)

def sqrt(v):                             # Newton's method, so nothing is imported
    r = v if v > 1 else 1.0
    for _ in range(60):
        r = 0.5 * (r + v / r)
    return r

e_x = expect(law)
mode = max(law, key=lambda xp: xp[1])[0]
# road two: count every draw.  Our ticket is number 0; the winning number w is
# any of 100, each equally likely.  Our payout in draw w:
payouts = [PRIZE if w == 0 else 0.0 for w in range(SOLD)]
e_count = sum(payouts) / SOLD
e_net = sum(x - PRICE for x in payouts) / SOLD
print(f"payout law: 0 with chance {law[0][1]:.2f}, 100 with chance {law[1][1]:.2f}")
print(f"E[X], weighted sum             {e_x:.2f}")
print(f"E[X], count over 100 draws     {e_count:.2f}")
print(f"E[X - 2], net per ticket       {expect(law, lambda x: x - PRICE):.2f} (count: {e_net:.2f})")
print(f"organiser: takes {SOLD * PRICE:.0f}, pays {PRIZE:.0f}, keeps {SOLD * PRICE - PRIZE:.0f}")
p_exact = sum(p for x, p in law if x == e_x)
print(f"most likely payout {mode:.0f} (chance 0.99); chance a ticket pays exactly 1: {p_exact:.2f}")
tail = sum(sum(p for x, p in law if x > t) for t in range(int(PRIZE)))   # levels t = 0..99
print(f"E[X], tail sum of P(X > t)     {tail:.2f}")

# road three: one ticket in each of N separate raffles, seed 2026
rng, total, total_sq, n = SplitMix64(2026), 0.0, 0.0, 0
marks = [1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000]
running = []
for m in marks:
    while n < m:
        x = PRIZE if rng.uniform() < 0.01 else 0.0
        total, total_sq, n = total + x, total_sq + x * x, n + 1
    running.append(total / n)
mean_sim = total / n
se = sqrt((total_sq / n - mean_sim ** 2) / n)
print("running average after N tickets:")
for m, r in zip(marks, running):
    print(f"  N = {m:>6}   {r:.2f}")
print(f"simulated E[X] = {mean_sim:.4f}, standard error {se:.4f}")

# linearity: five tickets, bought two ways
five_same = sum(PRIZE for w in range(SOLD) if w < 5) / SOLD   # our tickets are 0 to 4
p_zero_same = sum(1 for w in range(SOLD) if w >= 5) / SOLD
dist_indep = {}                                             # all 32 win/lose patterns
for mask in range(32):
    wins = bin(mask).count("1")
    chance = 0.01 ** wins * 0.99 ** (5 - wins)
    dist_indep[wins] = dist_indep.get(wins, 0.0) + chance
five_indep = sum(PRIZE * k * p for k, p in dist_indep.items())
print(f"5 tickets, one draw:   E[T] = {five_same:.2f}, P(T = 0) = {p_zero_same:.2f}, at most one wins")
print(f"5 tickets, five draws, 32 patterns: E[T] = {five_indep:.2f}, P(T = 0) = {dist_indep[0]:.4f}, "
      f"P(T = 100) = {dist_indep[1]:.4f}, P(T = 200) = {dist_indep[2]:.5f}")
print(f"5 x E[X]              = {5 * e_x:.2f}")
rng5, hits = SplitMix64(7), 0
for _ in range(100000):
    hits += 1 if int(rng5.uniform() * SOLD) < 5 else 0
q = hits / 100000
se5 = PRIZE * sqrt(q * (1 - q) / 100000)
print(f"5 tickets, one draw, simulated 100000 draws: E[T] = {PRIZE * q:.3f}, standard error {se5:.3f}")

# what breaks
both_same_draw = sum((PRIZE if w == 0 else 0.0) * (PRIZE if w == 1 else 0.0) for w in range(SOLD)) / SOLD
both_indep = sum(a * b * pa * pb for a, pa in law for b, pb in law)   # four patterns
print(f"two tickets, one draw: E[X1 X2] = {both_same_draw:.2f}, E[X1] E[X2] = {e_x * e_x:.2f}")
print(f"two tickets, two draws: E[X1 X2] = {both_indep:.2f}")
e_sq = sum(x * x for x in payouts) / SOLD                  # E[X^2] by counting draws
print(f"E[X^2] = {expect(law, lambda x: x * x):.2f}, E[X]^2 = {e_x ** 2:.2f}")
print(f"E[sqrt X] = {expect(law, sqrt):.2f}, sqrt E[X] = {sqrt(e_x):.2f}")
trunc = {k: sum(2.0 ** j * 0.5 ** j for j in range(1, k + 1)) for k in (10, 20, 40)}
for k, t in trunc.items():                # St Petersburg: pays 2^j with chance 2^-j
    print(f"St Petersburg, levels 1..{k}: truncated mean {t:.2f}")
rng_sp, sp_total, sp_n = SplitMix64(99), 0.0, 0
for m in (1000, 10000, 100000, 1000000):
    while sp_n < m:
        z = rng_sp.next()
        sp_total, sp_n = sp_total + 2.0 ** (z & -z).bit_length(), sp_n + 1
    print(f"  St Petersburg running average, N = {m:>7}: {sp_total / sp_n:.2f}")
print(f"figure, x = 30 + 3v; bar at 0: x 30, height {150 * 0.99:.1f}; bar at 100: x 330, "
      f"height {150 * 0.01:.1f}; balance point x {30 + 3 * e_x:.0f}")
assert abs(e_x - e_count) < 1e-12                           # weighted sum = count
assert abs(mean_sim - e_x) < 4 * se                         # simulation within 4 SE
assert abs(five_same - 5 * e_x) < 1e-9                      # linearity, dependent tickets
assert abs(five_indep - 5 * e_x) < 1e-9                     # linearity, independent tickets
assert both_same_draw < both_indep                           # products need independence
assert abs(tail - e_x) < 1e-12                              # tail sum = weighted sum
assert mode != e_x and p_exact == 0.0                       # the mean is never paid
assert abs(PRIZE * q - five_same) < 4 * se5                 # simulated five tickets
assert abs(e_sq - expect(law, lambda x: x * x)) < 1e-9 and e_sq > e_x ** 2   # E[X^2] vs E[X]^2
assert all(abs(t - k) < 1e-9 for k, t in trunc.items())     # each level adds $1: no mean
print("ALL CHECKS PASS")
