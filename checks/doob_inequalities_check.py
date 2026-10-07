# Doob's inequalities -- the check behind the card.  Standard library only.
# A gambler starts with $10, bets $1 a round on a fair coin, and must stop when broke.
# Question: the chance her fortune ever exceeds $30 (touches $31) within 100 rounds.
# Roads: Doob's bound; exact dynamic programming; path counting by images; simulation.
from math import sqrt, exp, log, comb
from fractions import Fraction

X0, LAM, N = 10, 31, 100
TOP = X0 + N  # the highest fortune reachable in N rounds

def joint_law(n):  # exact law of (fortune x after n rounds, peak m so far), stopped at 0
    law = [[0.0] * (TOP + 1) for _ in range(TOP + 1)]; law[X0][X0] = 1.0
    for _ in range(n):
        new = [[0.0] * (TOP + 1) for _ in range(TOP + 1)]
        for x in range(TOP + 1):
            for m in range(x, TOP + 1):
                pr = law[x][m]
                if pr == 0.0: continue
                if x == 0: new[0][m] += pr; continue
                new[x - 1][m] += 0.5 * pr; new[x + 1][max(m, x + 1)] += 0.5 * pr
        law = new
    return law

def hit_by(n):  # chance of touching LAM by round n; the walk dies at 0 and at LAM
    v = [0.0] * (LAM + 1); v[X0] = 1.0; hit = 0.0
    for _ in range(n):
        w = [0.0] * (LAM + 1)
        for x in range(1, LAM):
            w[x - 1] += 0.5 * v[x]; w[x + 1] += 0.5 * v[x]
        hit += w[LAM]; w[LAM] = 0.0; w[0] = 0.0; v = w
    return hit

def rounds_played(n):  # mean number of rounds actually bet: sum over rounds of P(still solvent)
    v = [0.0] * (TOP + 2); v[X0] = 1.0; total = 0.0
    for _ in range(n):
        total += sum(v[1:]); w = [0.0] * (TOP + 2); w[0] = v[0]
        for x in range(1, TOP + 1):
            w[x - 1] += 0.5 * v[x]; w[x + 1] += 0.5 * v[x]
        v = w
    return total

def hit_by_images(n):  # count paths 10 -> 30 inside (0, 31), then one step up
    total = Fraction(0)
    for s in range(1, n + 1):
        k = s - 1; c = 0
        for j in range(-3, 4):
            for d, sign in ((LAM - 1 - X0 + 2 * j * LAM, 1), (LAM - 1 + X0 + 2 * j * LAM, -1)):
                if abs(d) <= k and (k + d) % 2 == 0: c += sign * comb(k, (k + d) // 2)
        total += Fraction(c, 2 ** s)
    return float(total)

M64 = (1 << 64) - 1
def splitmix(state):  # SplitMix64: one 64-bit word per call, 64 coin tosses
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)

def simulate(paths, seed):
    st = seed; hits = 0; s = [0.0, 0.0, 0.0, 0.0]
    for _ in range(paths):
        st, w1 = splitmix(st); st, w2 = splitmix(st)
        x = X0; m = X0
        for i in range(N):
            if x == 0: break
            bit = (w1 >> i) & 1 if i < 64 else (w2 >> (i - 64)) & 1
            x += 1 if bit else -1
            if x > m: m = x
        hits += m >= LAM; s[0] += m * m; s[1] += m ** 4; s[2] += x * x; s[3] += x ** 4
    p = hits / paths; pk = s[0] / paths; en = s[2] / paths
    return (p, sqrt(p * (1 - p) / paths), pk, sqrt((s[1] / paths - pk * pk) / paths),
            en, sqrt((s[3] / paths - en * en) / paths))

law = joint_law(N)
def avg(f):  # exact average of f(x, m) over the joint law, summed in a fixed order
    return sum(f(x, m) * law[x][m] for x in range(TOP + 1) for m in range(x, TOP + 1))
p_joint = avg(lambda x, m: m >= LAM)
end_hit, end_miss = avg(lambda x, m: x * (m >= LAM)), avg(lambda x, m: x * (m < LAM))
end_mean, end_sq, peak_sq = avg(lambda x, m: x), avg(lambda x, m: x * x), avg(lambda x, m: m * m)
layer = sum((2 * k - 1) * avg(lambda x, m: m >= k) for k in range(1, TOP + 1))
end_above = avg(lambda x, m: x >= LAM)
wins_sq, wins_pos = avg(lambda x, m: (x - X0) ** 2), avg(lambda x, m: max(x - X0, 0))
p_dp, p_img, played = hit_by(N), hit_by_images(N), rounds_played(N)
doob, kolm = end_mean / LAM, wins_sq / (LAM - X0) ** 2
a, lo, hi = (LAM - X0) / N, 0.0, 2.0
theta = 0.5 * log((1 + a) / (1 - a))  # tanh(theta) = 21/100 minimises the exponential bound
def chern(t): return exp(N * log((exp(t) + exp(-t)) / 2) - (LAM - X0) * t)
for _ in range(200):  # golden-section search for the best exponent, a second road to theta
    g1, g2 = hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)
    if chern(g1) < chern(g2): hi = g2
    else: lo = g1
p_sim, se_p, pk_sim, se_pk, en_sim, se_en = simulate(100000, 20260929)
rows = [
    ("start X0, level lambda, rounds N", f"{X0} {LAM} {N}"),
    ("E[X_N] (fair game keeps the mean)", f"{end_mean:.6f}"),
    ("Doob bound  E[X_N]/lambda", f"{doob:.6f}"),
    ("  Doob bound as 1 in", f"{1 / doob:.1f}"),
    ("exact p, peak DP", f"{p_joint:.6f}"),
    ("exact p, two-barrier DP", f"{p_dp:.6f}"),
    ("exact p, counting by images", f"{p_img:.6f}"),
    ("  exact p as 1 in", f"{1 / p_img:.1f}"),
    ("simulated p (100000 paths)", f"{p_sim:.6f} +- {se_p:.6f}"),
    ("E[X_N ; peak >= 31]", f"{end_hit:.6f}"),
    ("  31 * p", f"{LAM * p_joint:.6f}"),
    ("E[X_N ; peak < 31]  (the slack)", f"{end_miss:.6f}"),
    ("E[X_N^2]", f"{end_sq:.6f}"),
    ("  simulated E[X_N^2]", f"{en_sim:.4f} +- {se_en:.4f}"),
    ("E[peak^2]", f"{peak_sq:.6f}"),
    ("  sum (2k-1) P(peak >= k)", f"{layer:.6f}"),
    ("  simulated E[peak^2]", f"{pk_sim:.4f} +- {se_pk:.4f}"),
    ("L2 bound  4 E[X_N^2]", f"{4 * end_sq:.6f}"),
    ("ratio E[peak^2] / E[X_N^2]", f"{peak_sq / end_sq:.6f}"),
    ("bound on squares  E[(X_N-10)^2]/21^2", f"{kolm:.6f}"),
    ("  E[(X_N-10)^2]", f"{wins_sq:.6f}"),
    ("  mean rounds played", f"{played:.6f}"),
    ("  unstopped walk  100/21^2", f"{N / (LAM - X0) ** 2:.6f}"),
    ("theta = atanh(21/100)", f"{theta:.6f}"),
    ("  theta by golden-section search", f"{(lo + hi) / 2:.6f}"),
    ("exponential bound  cosh^100 e^-21theta", f"{chern(theta):.6f}"),
    ("wrong: net winnings, E[M_N]/21", f"{abs(end_mean - X0) / (LAM - X0):.6f}"),
    ("  right: E[M_N^+]/21", f"{wins_pos / (LAM - X0):.6f}"),
    ("wrong: endpoint P(X_N >= 31)", f"{end_above:.6f}"),
]
for name, v in rows: print(f"{name:<40} {v}")
print()
print("chart, rounds   exact p %   Doob bound %")
for n in (25, 50, 100, 200, 400, 800, 1600, 3200):
    print(f"chart, {n:>6}   {100 * hit_by(n):9.2f}   {100 * doob:12.2f}")

assert abs(end_mean - X0) < 1e-9, "the stopped fair game keeps its mean"
assert abs(p_joint - p_img) < 1e-12, "peak DP vs path counting by images"
assert abs(p_dp - p_img) < 1e-12, "two-barrier DP vs path counting by images"
assert abs(p_sim - p_img) < 4 * se_p, "simulation within 4 standard errors"
assert p_img < chern(theta) < kolm < doob, "the ladder of bounds sits above the truth"
assert abs(end_hit - LAM * p_img) < 1e-12, "on the peak event the fortune ends at 31 on average"
assert abs(layer - peak_sq) < 1e-9, "layer-cake identity: two ways to average the squared peak"
assert peak_sq <= 4 * end_sq, "Doob's L2 inequality on the exact law"
assert abs(wins_sq - played) < 1e-9, "squared winnings minus rounds played is a martingale"
assert abs(theta - (lo + hi) / 2) < 1e-6, "calculus optimum vs searched optimum"
print("ALL CHECKS PASS")
