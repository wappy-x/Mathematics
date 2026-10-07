# Jump diffusions -- the check behind the card.  Only math is imported.
# An electricity price, $50 a megawatt-hour, follows Merton's rule with time in days:
# dS = mu S dt + sigma S dW + S(Y - 1) dN, spikes at 0.1 a day, log Y ~ normal(0.30, 0.10^2).
# Roads: Ito's lemma with a jump term; the Poisson mixture (condition on the number
# of spikes, no jump term from Ito); 4000 seeded paths on nested grids, checked path by path.
import math

S0, SIG, LAM, MJ, DJ, T = 50.0, 0.03, 0.1, 0.30, 0.10, 30.0
K = math.exp(MJ + 0.5 * DJ * DJ) - 1.0           # the average spike adds K of the price
MU = -LAM * K                                     # the compensator: average price stays flat
SEED, PATHS, FINE, GRIDS = 20260930, 4000, 480, (30, 120, 480)
MASK = (1 << 64) - 1

class SplitMix64:                                 # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                             # Box-Muller, cosine half
        u1, u2 = self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)

def phi(z):                                       # bell-curve height
    return math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi)

def ncdf(x, n=2000):                              # bell-curve area left of x, Simpson's rule
    h = x / n
    s = phi(0.0) + phi(x)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * phi(i * h)
    return 0.5 + s * h / 3.0

c = MU - 0.5 * SIG * SIG                          # log drift between spikes, per day
EY2 = math.exp(2.0 * MJ + 2.0 * DJ * DJ)          # average squared spike factor
print(f"price: S0 {S0:.0f} dollars/MWh, sigma {SIG:.2f} per root day, T {T:.0f} days")
print(f"spikes: rate {LAM:.1f} a day, log size mean {MJ:.2f} sd {DJ:.2f}; k = E[Y] - 1 = {K:.6f}")
print(f"compensated drift mu = -lambda k {MU:.6f} a day; log drift between spikes {c:.6f}")
m1 = c * T + LAM * T * MJ
v1 = SIG * SIG * T + LAM * T * (MJ * MJ + DJ * DJ)
mean1 = S0 * math.exp((MU + LAM * K) * T)
sq1 = S0 * S0 * math.exp((2.0 * MU + SIG * SIG + LAM * (EY2 - 1.0)) * T)
print(f"road 1, Ito with jumps: E log(S_T/S0) {m1:.6f}  Var {v1:.6f}  typical price {S0 * math.exp(m1):.2f}")
print(f"road 1, Ito with jumps: E S_T {mean1:.4f}  E S_T^2 {sq1:.4f}  sd S_T {math.sqrt(sq1 - mean1 * mean1):.4f}")

print(f"by hand: delta^2/2 {0.5 * DJ * DJ:.6f}  sigma^2/2 {0.5 * SIG * SIG:.6f}  c T {c * T:.6f}"
      f"  lambda T {LAM * T:.1f}  lambda T mu_J {LAM * T * MJ:.6f}  lambda k {LAM * K:.6f}")
print(f"by hand: sigma^2 T {SIG * SIG * T:.6f}  mu_J^2 {MJ * MJ:.6f}  delta^2 {DJ * DJ:.6f}"
      f"  lambda T (mu_J^2 + delta^2) {LAM * T * (MJ * MJ + DJ * DJ):.6f}")
print(f"by hand: E[Y^2] {EY2:.6f}  2 mu {2.0 * MU:.6f}  sigma^2 {SIG * SIG:.6f}  lambda (E[Y^2] - 1)"
      f" {LAM * (EY2 - 1.0):.6f}  E S_T^2 exponent {(2.0 * MU + SIG * SIG + LAM * (EY2 - 1.0)) * T:.6f}  S0^2 {S0 * S0:.0f}")
print(f"by hand: per spike E[Y - 1 - J] {K - MJ:.6f}  E[(Y - 1)^2] {EY2 - 2.0 * (1.0 + K) + 1.0:.6f}")

w, m2, e2, mean2, sq2, up2 = math.exp(-LAM * T), 0.0, 0.0, 0.0, 0.0, 0.0
weights, cond = [], []
for n in range(40):                               # condition on n spikes: log S_T is normal
    mn, vn = c * T + n * MJ, SIG * SIG * T + n * DJ * DJ
    weights.append(w); cond.append(S0 * math.exp(mn + 0.5 * vn))
    m2 += w * mn; e2 += w * (vn + mn * mn)
    mean2 += w * S0 * math.exp(mn + 0.5 * vn); sq2 += w * S0 * S0 * math.exp(2.0 * mn + 2.0 * vn)
    up2 += w * ncdf(mn / math.sqrt(vn))
    w *= LAM * T / (n + 1)
v2 = e2 - m2 * m2
print("road 2, Poisson mixture: chance of 0, 1, 2, 3, 4 spikes " + " ".join(f"{x:.4f}" for x in weights[:5]))
print(f"road 2, Poisson mixture: E log(S_T/S0) {m2:.6f}  Var {v2:.6f}")
print(f"road 2, Poisson mixture: E S_T {mean2:.4f}  E S_T^2 {sq2:.4f}  chance S_T > 50 {up2:.4f}")
print(f"road 2, Poisson mixture: 5 or more spikes: chance {sum(weights[5:]):.4f}, share of E S_T {sum(a * b for a, b in zip(weights[5:], cond[5:])) / mean2:.4f}")

ey1 = math.exp(MJ + 0.5 * DJ * DJ)
print("what breaks, E log(S_T/S0):")
print(f"  drop the jump term                {c * T:+.6f}")
print(f"  slope times the jump, Y - 1       {c * T + LAM * T * K:+.6f}")
print(f"  Taylor to second order on a jump  {c * T + LAM * T * (K - 0.5 * (EY2 - 2.0 * ey1 + 1.0)):+.6f}")
print(f"  no compensator, mu = 0: E S_T {S0 * math.exp(LAM * K * T):.2f} instead of {mean2:.2f}")
print("  infinitely many jumps, nu = x^-2.5 dx on (0,1), no compensator, mean jump sum a day, cut 1e-2 to 1e-8: " + " ".join(f"{2 * (e ** -0.5 - 1):.1f}" for e in (1e-2, 1e-4, 1e-6, 1e-8)))

g = SplitMix64(SEED)
gap = {n: [0.0, 0.0, 0.0, 0.0] for n in GRIDS}   # |Euler log - Ito with jumps|, |Euler log - slope rule|, squares
tot = [0.0, 0.0, 0.0, 0.0, 0.0]                   # S, S^2, log, log^2, count above 50
daily, qv, qv_target, spikes1 = [], 0.0, 0.0, []
for p in range(PATHS):
    jumps, t = [], 0.0
    while True:                                   # spike times: exponential gaps at rate lambda
        t += -math.log(1.0 - g.uniform()) / LAM
        if t >= T:
            break
        jumps.append((t, MJ + DJ * g.normal()))
    dw = [g.normal() * math.sqrt(T / FINE) for _ in range(FINE)]
    wT = sum(dw)
    ito = c * T + SIG * wT + sum(j for _, j in jumps)
    slope = c * T + SIG * wT + sum(math.exp(j) - 1.0 for _, j in jumps)
    for n in GRIDS:
        m, dt, s = FINE // n, T / n, S0
        jstep = [0.0] * n
        for tj, j in jumps:
            jstep[int(tj * n / T)] += j
        for k in range(n):
            before = s
            s *= (1.0 + MU * dt + SIG * sum(dw[k * m:(k + 1) * m])) * math.exp(jstep[k])
            if p == 0 and n == FINE:
                qv += math.log(s / before) ** 2
                if k % 16 == 0:
                    daily.append(before)
        lg = math.log(s / S0)
        d1, d2 = abs(lg - ito), abs(lg - slope); gap[n][0] += d1; gap[n][1] += d2; gap[n][2] += d1 * d1; gap[n][3] += d2 * d2
    if p == 0:
        daily.append(s)
        qv_target = SIG * SIG * T + sum(j * j for _, j in jumps)
        spikes1 = jumps
    tot[0] += s; tot[1] += s * s; tot[2] += lg; tot[3] += lg * lg; tot[4] += 1 if s > S0 else 0

se = lambda s, s2: math.sqrt((s2 / PATHS - (s / PATHS) * (s / PATHS)) / PATHS)   # standard error of an average
print(f"road 3, {PATHS} seeded paths (seed {SEED}), Euler steps with spikes applied exactly:")
for n in GRIDS:
    print(f"  {n // 30:2d} steps a day   |gap to Ito with jumps| {gap[n][0] / PATHS:.5f} (se {se(gap[n][0], gap[n][2]):.5f})"
          f"   |gap to slope rule| {gap[n][1] / PATHS:.5f} (se {se(gap[n][1], gap[n][3]):.5f})")
ms, ml, se_s, se_l = tot[0] / PATHS, tot[2] / PATHS, se(tot[0], tot[1]), se(tot[2], tot[3])
fr = tot[4] / PATHS
se_f = math.sqrt(fr * (1.0 - fr) / PATHS)
print(f"  16 steps a day: mean S_T {ms:.2f} (se {se_s:.2f})")
print(f"  16 steps a day: mean log {ml:.4f} (se {se_l:.4f}), above 50 {fr:.4f} (se {se_f:.4f})")
print("path 1 spikes, day and log size: " + "  ".join(f"{tj:.2f} {j:+.4f}" for tj, j in spikes1))
print(f"path 1 quadratic variation of log S: grid sum {qv:.5f}, sigma^2 T + sum J^2 {qv_target:.5f}")
print("chart, day   " + " ".join(f"{d:6d}" for d in range(31)))
print("chart, price " + " ".join(f"{x:6.2f}" for x in daily))
print("chart, gap to Ito x1000   " + " ".join(f"{1000 * gap[n][0] / PATHS:.2f}" for n in GRIDS))
print("chart, gap to slope x1000 " + " ".join(f"{1000 * gap[n][1] / PATHS:.2f}" for n in GRIDS))

assert abs(m1 - m2) < 1e-9 and abs(v1 - v2) < 1e-9, "the averaged log matches the Poisson mixture"
assert abs(mean1 - mean2) < 1e-9 * mean2 and abs(sq1 - sq2) < 1e-6 * sq2, "Ito on S and S^2 matches the mixture"
assert abs(ms - mean2) < 4 * se_s, "simulated mean price within 4 se of the mixture's 50"
assert abs(ml - m1) < 4 * se_l, "simulated mean log within 4 se of Ito with jumps"
assert abs(fr - up2) < 4 * se_f, "simulated chance above 50 matches the mixture"
assert gap[FINE][0] < gap[30][0] / 3, "the path-by-path gap to Ito shrinks with the step"
assert gap[FINE][1] / PATHS > 0.1, "the slope rule stays far off on every grid"
assert abs(qv - qv_target) < 0.1 * qv_target, "the jumps' squares sit in the quadratic variation"
print("ALL CHECKS PASS")
