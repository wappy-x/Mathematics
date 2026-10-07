# Gambler's ruin -- the check behind the card.  Nothing is imported.
# A gambler holds 10 chips, bets 1 chip a round, and stops at 0 or at 20.
# Four roads to the chance h of reaching 20 first and the expected number of
# rounds t: the closed forms; the first-step equations solved by elimination;
# the chance mass pushed forward round by round; and a seeded simulation.
K, L, SEED, GAMES = 10, 20, 20260929, 20000
MASK = (1 << 64) - 1

def formula(k, n, p):                    # the closed forms from Why it works
    q = 1 - p
    if p == 0.5:
        return k / n, k * (n - k)
    r = q / p
    h = (1 - r ** k) / (1 - r ** n) + 0.0
    return h, (k - n * h) / (q - p)

def first_step(n, p, rhs, end):          # q x[i-1] - x[i] + p x[i+1] = -rhs
    q = 1 - p                            # for i = 1..n-1, x[0] = 0, x[n] = end
    c, d = [0.0] * n, [0.0] * n          # forward sweep of Thomas elimination
    for i in range(1, n):
        den = -1 - q * c[i - 1]
        c[i] = p / den
        d[i] = (-rhs - q * d[i - 1]) / den
    x = [0.0] * (n + 1)
    x[n] = end
    for i in range(n - 1, 0, -1):        # back substitution
        x[i] = d[i] - c[i] * x[i + 1]
    return x

def mass_flow(k, n, p, rounds):          # move every scrap of chance, round by round
    m = [0.0] * (n + 1)
    m[k] = 1.0
    top = dur = 0.0
    for _ in range(rounds):
        dur += sum(m[1:n])               # P(still playing) adds up to E[rounds]
        new = [0.0] * (n + 1)
        for i in range(1, n):
            new[i + 1] += p * m[i]
            new[i - 1] += (1 - p) * m[i]
        top += new[n]
        new[0] = new[n] = 0.0
        m = new
    return top, dur, sum(m)

class SplitMix64:                        # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def play(g, k, n, p, path):              # one game; returns (reached n, rounds)
    x, t = k, 0
    while 0 < x < n:
        x += 1 if g.uniform() < p else -1
        t += 1
        path.append(x)
    return x == n, t

def simulate(k, n, p):
    g, wins, s1, s2 = SplitMix64(SEED), 0, 0.0, 0.0
    for _ in range(GAMES):
        won, t = play(g, k, n, p, [])
        wins, s1, s2 = wins + won, s1 + t, s2 + t * t
    h, mt = wins / GAMES, s1 / GAMES
    return h, (h * (1 - h) / GAMES) ** 0.5, mt, ((s2 / GAMES - mt * mt) / (GAMES - 1)) ** 0.5

print(f"game: start {K} chips, stop at 0 or {L}, stake 1 chip a round")
for p in (0.5, 0.49):
    hf, tf = formula(K, L, p)
    hs, ts = first_step(L, p, 0.0, 1.0)[K], first_step(L, p, 1.0, 0.0)[K]
    hm, tm, left = mass_flow(K, L, p, 3000)
    hr, seh, tr, set_ = simulate(K, L, p)
    print(f"p = {p:.2f}  formula     h = {hf:.6f}  t = {tf:.4f}")
    print(f"p = {p:.2f}  first-step  h = {hs:.6f}  t = {ts:.4f}")
    print(f"p = {p:.2f}  mass flow   h = {hm:.6f}  t = {tm:.4f}  unresolved after 3000 rounds {left:.1e}")
    print(f"p = {p:.2f}  simulated   h = {hr:.4f} +- {seh:.4f}  t = {tr:.2f} +- {set_:.2f}  ({GAMES} games)")
    print(f"p = {p:.2f}  ruin chance 1 - h = {1 - hf:.6f}")
    assert abs(hf - hs) < 1e-12                  # closed form against elimination
    assert abs(tf - ts) < 1e-9
    assert abs(hf - hm) <= left + 1e-12          # closed form against mass flow
    assert abs(tf - tm) < 1e-6
    assert abs(hr - hf) < 4 * seh                # simulation, within 4 standard errors
    assert abs(tr - tf) < 4 * set_
r = 0.51 / 0.49
r10 = 1.0
for _ in range(10):
    r10 *= r
h49 = 1 / (1 + r10)
print(f"worked, p = 0.49: r = {r:.6f}, r^10 = {r10:.6f}, h = 1/(1 + r^10) = {h49:.6f}")
print(f"worked, p = 0.49: 20 h = {20 * h49:.6f}, t = (10 - 20 h)/0.02 = {(10 - 20 * h49) / 0.02:.4f}")
assert abs(h49 - formula(K, L, 0.49)[0]) < 1e-12              # the 1/(1 + r^10) shortcut
for p in (0.5, 0.49):
    row = ", ".join(f"{formula(k, L, p)[0]:.2f}" for k in range(0, L + 1, 2))
    print(f"figure, h by start k = 0, 2, ..., 20, p = {p:.2f}: {row}")
path = [K]
won, T = play(SplitMix64(SEED), K, L, 0.5, path)
print(f"figure, first simulated fair game, chips every 4 rounds: {', '.join(str(path[i]) for i in range(0, T + 1, 4))}")
print(f"figure, that game ends at round {T} on {path[-1]}; lowest {min(path)}, highest before the end {max(path[:-1])}")
print(f"mistake, fair formula k/L used at p = 0.49: {K / L:.4f} against {formula(K, L, 0.49)[0]:.4f}")
print(f"mistake, ratio upside down, p/q for q/p: {formula(K, L, 0.51)[0]:.4f}")
g, wins = SplitMix64(SEED), 0
for _ in range(GAMES):                   # bold play: stake all 10 chips at once
    wins += g.uniform() < 0.49
se_b = (wins / GAMES * (1 - wins / GAMES) / GAMES) ** 0.5
print(f"mistake, stake all 10 chips in one round at p = 0.49: simulated {wins / GAMES:.4f} +- {se_b:.4f}, exact 0.4900")
assert abs(wins / GAMES - 0.49) < 4 * se_b
for n in (20, 30, 40, 80, 160, 1000):
    hf, tf = formula(K, n, 0.5)
    print(f"top wall moved up, fair, target {n}: h = {hf:.4f}, t = {tf:.0f}")
hf = formula(K, 1000, 0.51)[0]
q10 = 1.0
for _ in range(10):
    q10 *= 0.49 / 0.51
print(f"top wall moved up, p = 0.51: h at target 1000 = {hf:.4f}; limit 1 - (0.49/0.51)^10 = {1 - q10:.4f}")
assert abs(hf - (1 - q10)) < 1e-9
for k, n, p, what in ((100, 200, 0.49, "100 chips to 200 at 0.49"), (K, L, 18 / 38, "10 chips to 20 on red, 18/38")):
    hf, tf = formula(k, n, p)
    print(f"scale, {what}: h = {hf:.4f}, t = {tf:.2f}")
print("ALL CHECKS PASS")
