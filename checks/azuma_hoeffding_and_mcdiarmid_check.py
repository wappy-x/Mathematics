# Azuma-Hoeffding and McDiarmid -- the check behind the card.  Standard library only.
# Part 1: a gambler bets $1 on a fair coin for 100 rounds; chance of winning $30 or more.
# Part 2: 100 balls thrown into 100 boxes; how far the count of empty boxes strays from its mean.
from math import comb, exp, log, sqrt
N, T = 100, 30                    # gambler: rounds, target gain in dollars
B, Q, TB = 100, 0.99, 15          # balls (= boxes), chance a ball misses a given box, distance

# ---- Part 1: the gambler, steps of width 2 (from -1 to +1)
azuma = exp(-2 * T ** 2 / (N * 2 ** 2))
def heads_at_least(h): return sum(comb(N, k) for k in range(h, N + 1)) / 2 ** N
end_exact = heads_at_least((N + T) // 2)                      # gain 30 means 65 heads or more
peak_reflect = end_exact + heads_at_least((N + T) // 2 + 1)   # reflection: P(S >= 30) + P(S > 30)
def walk(n, level, absorb):  # exact law of the fair walk; absorb=True stops it at the level
    dist, hit = {0: 1.0}, 0.0
    for _ in range(n):
        new = {}
        for x, p in dist.items():
            for y in (x - 1, x + 1):
                if absorb and y >= level: hit += 0.5 * p
                else: new[y] = new.get(y, 0.0) + 0.5 * p
        dist = new
    return hit if absorb else sum(p for x, p in dist.items() if x >= level)
end_dp, peak_dp = walk(N, T, False), walk(N, T, True)
theta = 0.5 * log((1 + T / N) / (1 - T / N))                 # atanh(0.3): best tilt for cosh
cosh_bound = exp(N * log((exp(theta) + exp(-theta)) / 2) - T * theta)
kolmogorov = N / T ** 2                                       # Doob on the square, two-sided
grid = [i / 100 for i in range(1, 301)]
lemma_coin = max(log((exp(t) + exp(-t)) / 2) - t * t / 2 for t in grid)     # must be <= 0

def doubling(n, cap):  # double the stake after a loss, up to cap; back to $1 after a win or a loss at cap
    dist = {(0, 1): 1.0}
    for _ in range(n):
        new = {}
        for (x, s), p in dist.items():
            for key in ((x + s, 1), (x - s, 2 * s if s < cap else 1)):
                new[key] = new.get(key, 0.0) + 0.5 * p
        dist = new
    return sum(p for (x, s), p in dist.items() if x >= T), sum(p * x for (x, s), p in dist.items()), min(x for x, s in dist)
(dbl_p, dbl_mean, dbl_low), dbl_azuma = doubling(N, 64), exp(-2 * T ** 2 / (N * 128 ** 2))
# ---- Part 2: balls in boxes; z = empty boxes so far
mean_formula = B * Q ** B
law = [0.0] * (B + 1); law[B] = 1.0            # before any ball, all 100 boxes are empty
for _ in range(B):
    new = [0.0] * (B + 1)
    for z, p in enumerate(law):
        if p == 0.0: continue
        new[z] += p * (B - z) / B               # the ball lands in an occupied box
        if z > 0: new[z - 1] += p * z / B       # the ball lands in an empty box
    law = new
mean_dp = sum(z * p for z, p in enumerate(law)); var_dp = sum((z - mean_dp) ** 2 * p for z, p in enumerate(law))
def tail(t): return sum(p for z, p in enumerate(law) if abs(z - mean_dp) >= t)
mcd = lambda t, w2: 2 * exp(-2 * t * t / w2); exact_tail = tail(TB)
mean_dep = (B - 1 + mean_dp) / 2   # ball 1 leads: in an even box it draws every other ball in (99 empty); odd: free throws
tail_dep = 0.5 * (B - 1 - mean_dep >= TB) + 0.5 * sum(p for z, p in enumerate(law) if abs(z - mean_dep) >= TB)
# The Doob martingale M_k = E[N | first k balls] = z * Q^(B-k). Check fairness, widths, the lemma.
worst_fair, worst_width, worst_lemma, w2_true = 0.0, 0.0, -1.0, 0.0
for k in range(B):
    w = Q ** (B - k - 1); w2_true += w * w
    for z in range(B - k, B + 1):
        m_now = z * Q ** (B - k)
        up, down = z * w - m_now, (z - 1) * w - m_now   # occupied box hit / empty box hit
        pu, pd = (B - z) / B, z / B; worst_width = max(worst_width, up - down)
        worst_fair = max(worst_fair, abs(pu * up + pd * down))
        for t in grid[::10]:
            mgf = pu * exp(t * up) + pd * exp(t * down)
            worst_lemma = max(worst_lemma, log(mgf) - t * t * w * w / 8)
chebyshev, band95 = var_dp / TB ** 2, sqrt(B / 2 * log(2 / 0.05))
M64 = (1 << 64) - 1
def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)
st, trials, s1, s2, far = 20261123, 20000, 0.0, 0.0, 0
for _ in range(trials):
    hit = [False] * B
    for _ in range(B):
        st, r = splitmix(st); hit[r % B] = True
    e = B - sum(hit); s1 += e; s2 += e * e; far += abs(e - mean_formula) >= 6
sim_mean = s1 / trials; sim_se = sqrt((s2 / trials - sim_mean ** 2) / trials)

rows = [
    ("gambler: rounds N, target gain t", f"{N} {T}"),
    ("Azuma bound  exp(-2t^2/(N*2^2))", f"{azuma:.6f}"),
    ("  sum of squared widths, best tilt, exponent", f"{N * 2 ** 2:.6f} {4 * T / (N * 4):.6f} {2 * T ** 2 / (N * 4):.6f}"),
    ("exact P(gain >= 30): counting, walk DP", f"{end_exact:.6f} {end_dp:.6f}"),
    ("exact P(peak >= 30): reflection, absorbed DP", f"{peak_reflect:.6f} {peak_dp:.6f}"),
    ("tilt atanh(0.3)", f"{theta:.6f}"),
    ("Doob, exact cosh  cosh^100 e^-30theta", f"{cosh_bound:.6f}"),
    ("Doob on the square  100/30^2", f"{kolmogorov:.6f}"),
    ("lemma for the coin, every tilt tested", "holds" if lemma_coin <= 0 else "FAILS"),
    ("doubling to $64: P(gain >= 30), mean gain", f"{dbl_p:.6f} {round(dbl_mean, 6) + 0.0:.6f}"),
    ("  Azuma at width 128", f"{dbl_azuma:.6f}"),
    ("balls B, boxes, distance", f"{B} {B} {TB}"),
    ("E[empty]  100 * 0.99^100", f"{mean_formula:.6f}"),
    ("E[empty]  exact DP", f"{mean_dp:.6f}"),
    ("  simulated (20000 throws)", f"{sim_mean:.4f} +- {sim_se:.4f}"),
    ("Var[empty]  exact DP, and sd", f"{var_dp:.6f} {sqrt(var_dp):.6f}"),
    ("McDiarmid  2 exp(-2*15^2/100)", f"{mcd(TB, B):.6f}"),
    ("exact P(|N - mean| >= 15), per million", f"{1e6 * exact_tail:.3f}"),
    ("Chebyshev  Var/15^2", f"{chebyshev:.6f}"),
    ("Doob martingale fair to 1e-12", "yes" if worst_fair < 1e-12 else "no"),
    ("  widest step", f"{worst_width:.6f}"),
    ("  lemma on every step, every tilt", "holds" if worst_lemma <= 1e-12 else "FAILS"),
    ("  true widths: sum of squares, McDiarmid", f"{w2_true:.6f} {mcd(TB, w2_true):.6f}"),
    ("95% band  sqrt(50 ln 40)", f"{band95:.6f}"),
    ("  exact P(|N - mean| >= band), per million", f"{1e6 * tail(band95):.3f}"),
    ("P(|N - mean| >= 6): simulated, exact", f"{far / trials:.6f} {tail(6):.6f}"),
    ("wrong: width 2 per ball", f"{mcd(TB, 4 * B):.6f}"),
    ("wrong: half-width 1 as width, per million", f"{1e6 * exp(-2 * T ** 2 / N):.3f}"),
    ("wrong: widths not squared  exp(-2t^2/200)", f"{exp(-2 * T ** 2 / (2 * N)):.6f}"),
    ("try: 400 rounds, gain 30", f"{exp(-2 * T ** 2 / (4 * N * 4)):.6f}"),
    ("try: 100 rounds, gain 40", f"{exp(-2 * 40 ** 2 / (N * 4)):.6f}"),
    ("try: 200 balls, mean and McDiarmid at 15", f"{B * Q ** 200:.6f} {mcd(TB, 2 * B):.6f}"),
    ("chromatic, 1000 vertices, t = 50", f"{mcd(50, 1000):.6f}"),
    ("ball 1 leads: mean, P(miss >= 15), step c_1", f"{mean_dep:.6f} {tail_dep:.9f} {B - 1 - mean_formula:.6f}"),
    ("50 pairs: mean and McDiarmid at 15", f"{B * Q ** 50:.6f} {mcd(TB, B / 2):.6f}"),
]
for name, v in rows: print(f"{name:<44} {v}")
print()
print("chart, t   exact %   McDiarmid %   Chebyshev %")
for t in (3, 5, 7, 9, 11, 13, 15, 17, 19):
    print(f"chart, {t:>2}  {100 * tail(t):8.3f}   {100 * min(1, mcd(t, B)):11.3f}   {100 * min(1, var_dp / t / t):11.3f}")

assert abs(end_exact - end_dp) < 1e-12, "counting vs dynamic program"
assert abs(peak_reflect - peak_dp) < 1e-12, "reflection vs absorbed dynamic program"
assert peak_dp < cosh_bound < azuma < kolmogorov, "the ladder of bounds sits above the truth"
assert lemma_coin <= 0 and worst_lemma <= 1e-12, "Hoeffding's lemma on every step tested"
assert abs(mean_formula - mean_dp) < 1e-9, "mean of empty boxes: formula vs dynamic program"
assert abs(sim_mean - mean_dp) < 4 * sim_se, "simulation within 4 standard errors"
assert worst_fair < 1e-12 and worst_width <= 1 + 1e-12, "Doob martingale is fair with steps of width <= 1"
assert exact_tail < mcd(TB, w2_true) < mcd(TB, B) < tail_dep, "McDiarmid holds, true widths sharpen it, dependent inputs break it"
assert dbl_p > azuma and abs(dbl_mean) < 1e-9, "doubling: fair, but big steps break the width-2 bound"
assert dbl_low == -(127 * (N // 7) + 2 ** (N % 7) - 1), "doubling: all losses = 14 busts of $127, then $1 and $2"
assert abs(w2_true - (1 - Q ** (2 * B)) / (1 - Q * Q)) < 1e-9, "true widths: a geometric sum of squares"
assert abs(var_dp - (mean_formula + B * (B - 1) * (1 - 2 / B) ** B - mean_formula ** 2)) < 1e-9, "variance: pairs of boxes"
print("ALL CHECKS PASS")
