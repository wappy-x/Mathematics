# Stopping without a bound -- the check behind the card.  Nothing is imported
# except math.  A gambler starts with a = 10 dollars, stakes 1 dollar a round,
# and stops at 0 (ruin) or at the goal b = 30.  Ruin odds are reached four
# ways: the martingale in one line, first-step equations solved as a linear
# system, the exact law of the stopped fortune pushed forward round by round,
# and a seeded simulation.  Then two games where optional stopping fails.
import math
A, B, M64 = 10, 30, (1 << 64) - 1

class SplitMix64:                              # the wing's generator, written out
    def __init__(self, seed): self.s = seed
    def unit(self):                            # a uniform draw in [0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53

def first_step(p, rhs):          # solve -q h(x-1) + h(x) - p h(x+1) = rhs(x), 0 < x < B
    q, n = 1 - p, B - 1          # h(0) = 0, h(B) = 0; Thomas algorithm, no martingale
    c, d = [0.0] * n, [0.0] * n
    for i in range(n):
        piv = 1.0 - (-q) * (c[i - 1] if i else 0.0)
        c[i] = -p / piv
        d[i] = (rhs(i + 1) + q * (d[i - 1] if i else 0.0)) / piv
    h = [0.0] * (B + 1)
    for i in range(n - 1, -1, -1):
        h[i + 1] = d[i] - c[i] * h[i + 2]
    return h[A]

def push_law(p, rounds, marks):  # exact law of the stopped fortune, round by round
    law, alive_sum, rows = [0.0] * (B + 1), 0.0, {}
    law[A] = 1.0
    for n in range(rounds + 1):
        if n in marks:
            rows[n] = (law[0], law[B], sum(law[1:B]), sum(x * law[x] for x in range(B + 1)), alive_sum)
        alive_sum += sum(law[1:B])            # adds P(tau > n): builds E[min(tau, n)]
        new = [0.0] * (B + 1)
        new[0], new[B] = law[0], law[B]
        for x in range(1, B):
            new[x + 1] += p * law[x]
            new[x - 1] += (1 - p) * law[x]
        law = new
    return rows

def simulate(p, games, seed):
    g, wins, steps, steps2 = SplitMix64(seed), 0, 0, 0
    for _ in range(games):
        x, t = A, 0
        while 0 < x < B:
            x, t = (x + 1, t + 1) if g.unit() < p else (x - 1, t + 1)
        wins += x == B
        steps, steps2 = steps + t, steps2 + t * t
    w, m = wins / games, steps / games
    return w, math.sqrt(w * (1 - w) / games), m, math.sqrt((steps2 / games - m * m) / games)

print(f"fair game: start a = {A}, goal b = {B}, stake $1 a round, win chance 0.5")
w_mart = A / B
w_fs = first_step(0.5, lambda x: 0.5 if x == B - 1 else 0.0)
d_fs = first_step(0.5, lambda x: 1.0)
marks = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 20000]
law = push_law(0.5, 20000, set(marks))
print(f"road 1, martingale in one line: P(reach 30) = a/b = {w_mart:.6f}, P(ruin) = {1 - w_mart:.6f}")
print(f"road 2, first-step equations:   P(reach 30) = {w_fs:.6f}, P(ruin) = {1 - w_fs:.6f}")
print(f"road 3, law pushed 20000 rounds: P(reach 30) = {law[20000][1]:.6f}, P(ruin) = {law[20000][0]:.6f}")
ws, wse, ds, dse = simulate(0.5, 10000, 2026)
print(f"road 4, 10000 games, seed 2026:  P(reach 30) = {ws:.4f} (se {wse:.4f})")
print("chart, by round n: n, P(ruined by n), P(reached 30 by n), P(still playing), E[X at min(tau, n)]")
for n in marks[:-1]:
    r0, r1, al, mean, _ = law[n]
    print(f"  {n:5d}  {r0:.2f}  {r1:.2f}  {al:.4f}  {mean:.6f}")
print(f"bounded test: |X at min(tau, n)| never exceeds {B}, so its tail above K = {B} is 0 for every n")
print(f"duration, E[tau] in rounds: a(b - a) = {A * (B - A)}, first-step = {d_fs:.3f}, "
      f"law = {law[20000][4]:.3f}, simulated = {ds:.1f} (se {dse:.1f})")
print(f"duration by X^2 - n: X^2 <= b^2 = {B * B}, E[X_tau^2] = b^2 P(reach 30) = {B * B * w_mart:.3f}, "
      f"E[tau] = that - a^2 = {B * B * w_mart - A * A:.3f}")
p = 18 / 38                                   # roulette: $1 on red wins 18 times in 38
r = (1 - p) / p
w_rm = (r ** A - 1) / (r ** B - 1)
w_rf = first_step(p, lambda x: p if x == B - 1 else 0.0)
d_rf = first_step(p, lambda x: 1.0)
d_rm = (A - B * w_rm) / ((1 - p) - p)
rs, rse, rds, rdse = simulate(p, 10000, 38)
print(f"roulette, p = 18/38 = {p:.6f}, martingale (q/p)^X with q/p = {r:.6f}")
print(f"  by hand: (q/p)^10 = {r ** A:.6f}, (q/p)^30 = {r ** B:.6f}, q - p = {1 - 2 * p:.6f}, a - b P(reach 30) = {A - B * w_rm:.6f}")
print(f"  P(reach 30): martingale = {w_rm:.6f}, first-step = {w_rf:.6f}, simulated = {rs:.4f} (se {rse:.4f})")
print(f"  E[tau]: martingale X + n(q - p) = {d_rm:.3f}, first-step = {d_rf:.3f}, "
      f"simulated = {rds:.1f} (se {rdse:.1f})")
print("doubling, every coin word enumerated: n, E[G_n], E|G_n - 1|, tail of |G_n| above K = 100")
dbl = {}
for n in (1, 4, 7, 10):
    mean = err = tail = 0.0
    for word in range(1 << n):                 # bit j set = toss j+1 is a head
        stake, gain = 1, 0
        for j in range(n):
            if gain == 1: break                # already won, stopped
            if word >> j & 1: gain += stake
            else: gain, stake = gain - stake, 2 * stake
        mean += gain / (1 << n); err += abs(gain - 1) / (1 << n)
        tail += abs(gain) / (1 << n) if abs(gain) > 100 else 0.0
    dbl[n] = (mean, err, tail)
    print(f"  {n:2d}  {mean:.6f}  {err:.6f}  {tail:.6f}")
e_tau = sum(2.0 ** -n for n in range(60))
print(f"doubling: stopped gain G_tau = 1 on every run, E[tau] = {e_tau:.6f} tosses, yet E[G_n] = 0 at every cap")
print("no goal, stop only at 0: n, P(ruined by n) pushed (chart), by reflection, E[X at min(tau, n)], tail above 30")
N, law1 = 2000, [0.0] * (A + 2002)
law1[A] = 1.0
one = {}
for n in range(N + 1):
    if n % 250 == 0:
        k_lo, k_hi = (n - A) / 2, (n + A) / 2      # reflection: P(tau > n) = P(-a < S_n <= a)
        refl = sum(math.exp(sum(math.log((n - k + i) / i) for i in range(1, k + 1)) - n * math.log(2))
                   for k in range(n + 1) if k_lo < k <= k_hi)
        one[n] = (law1[0], 1 - refl, sum(x * law1[x] for x in range(len(law1))),
                  sum(x * law1[x] for x in range(B + 1, len(law1))))
        print(f"  {n:5d}  {one[n][0]:.2f}  {one[n][1]:.6f}  {one[n][2]:.6f}  {one[n][3]:.2f}")
    new = [0.0] * len(law1)
    new[0] = law1[0]
    for x in range(1, A + n + 1):
        new[x + 1] += 0.5 * law1[x]; new[x - 1] += 0.5 * law1[x]
    law1 = new
print(f"mistake 1, doubling: optional stopping claims E[G_tau] = 0; it is 1")
print(f"no goal as the limit of goal b: P(ruin) = 1 - a/b = {1 - A / 100:.2f} at b = 100, {1 - A / 1000:.3f} at b = 1000")
print(f"mistake 2, no goal: optional stopping claims E[X_tau] = {A}; X_tau = 0 on every run, since ruin is certain")
print(f"mistake 3, fair formula a/b on roulette: {w_mart:.6f} against the true {w_rm:.6f}")
assert abs(w_fs - w_mart) < 1e-12 and abs(law[20000][1] - w_mart) < 1e-12   # three roads agree
assert abs(ws - w_mart) < 4 * wse and abs(rs - w_rm) < 4 * rse                 # simulation within 4 se
assert abs(d_fs - A * (B - A)) < 1e-9 and abs(law[20000][4] - d_fs) < 1e-6 and abs(ds - d_fs) < 4 * dse
assert abs(w_rf - w_rm) < 1e-12 and abs(d_rf - d_rm) < 1e-9 and abs(rds - d_rm) < 4 * rdse
assert abs(one[N][0] - one[N][1]) < 1e-9 and one[N][0] > 0.8 and abs(one[N][2] - A) < 1e-9
assert all(abs(dbl[n][0]) < 1e-12 and abs(dbl[n][1] - 1) < 1e-12 for n in dbl)
print("ALL CHECKS PASS")
