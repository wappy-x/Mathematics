# Retirement pot: $1,000,000, $40,000 a year in today's dollars, 30 withdrawals, real returns.
# Road 1: simulate 50,000 pots year by year.  Road 2: the realised-discount sum S on the same paths.
# Road 3: no randomness at all, the survival probability carried backwards on a wealth grid.
from math import exp, log, sqrt, cos, sin, pi
from itertools import accumulate

W0, C, N_YEARS, N_PATHS = 1_000_000.0, 40_000.0, 30, 50_000
A_S, SIG_S, A_B, SIG_B = 0.08, 0.20, 0.03, 0.08      # stocks, bonds: expected real return, volatility

def ms(p):                                           # yearly log-growth: mean m, spread s, share p in stocks
    a, v = p * A_S + (1 - p) * A_B, (p * SIG_S) ** 2 + ((1 - p) * SIG_B) ** 2; return a - 0.5 * v, sqrt(v)

def Phi(x):                                          # normal CDF, Marsaglia's series
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total) + 1e-300:
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + total * exp(-0.5 * x * x) / sqrt(2 * pi)

MASK, state = (1 << 64) - 1, 20260928
def uniform():                                       # splitmix64
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def normals(k):                                      # Box-Muller, two draws per pair of uniforms
    out = []
    while len(out) < k:
        r, t = sqrt(-2.0 * log(1.0 - uniform())), 2.0 * pi * uniform()
        out += [r * cos(t), r * sin(t)]
    return out[:k]

glide = lambda a, b: [a + (b - a) * t / (N_YEARS - 1) for t in range(N_YEARS)]
PATHS = [("flat 60% stocks", glide(0.6, 0.6)), ("flat 30% stocks", glide(0.3, 0.3)),
         ("flat 90% stocks", glide(0.9, 0.9)), ("falling 80% to 40%", glide(0.8, 0.4)),
         ("rising 40% to 80%", glide(0.4, 0.8))]

def survival_grid(ws, h=0.1, xmax=100.0, dz=0.25):   # V_k(x): chance of k more withdrawals from x
    xs = [i * h for i in range(int(xmax / h) + 1)]
    zs = [-8.0 + dz * i for i in range(int(16.0 / dz) + 1)]
    pz = [exp(-0.5 * z * z) * dz / sqrt(2 * pi) for z in zs]
    m, s = ms(ws[len(ws) - 2])
    V = [Phi((log(x - 1.0) + m) / s) if x > 1.0 else 0.0 for x in xs]
    for k in range(3, len(ws) + 1):
        m, s = ms(ws[len(ws) - k])
        gs, new = [exp(m + s * z) / h for z in zs], []
        for x in xs:
            acc = 0.0
            if x >= 1.0:
                for g, p in zip(gs, pz):
                    y = (x - 1.0) * g; j = int(y)
                    acc += p * (V[-1] if j >= len(xs) - 1 else V[j] + (y - j) * (V[j + 1] - V[j]))
            new.append(acc)
        V = new
    return lambda x: V[-1] if x >= xmax else V[int(x / h)] + (x / h - int(x / h)) * (V[int(x / h) + 1] - V[int(x / h)])

x0, fails, S_list, finals, end_fail, Z1 = W0 / C, [0] * len(PATHS), [], [], 0, []
for _ in range(N_PATHS):
    z = normals(N_YEARS)
    for i, (_, ws) in enumerate(PATHS):
        x = x0
        for t in range(N_YEARS):
            if x < 1.0: fails[i] += 1; x = 0.0; break
            m, s = ms(ws[t]); x = (x - 1.0) * exp(m + s * z[t])
        if i == 0: finals.append(x * C)
    m, s = ms(0.6); P, S, xe, dead = 1.0, 0.0, x0, False
    for t in range(N_YEARS):
        S += 1.0 / P; g = exp(m + s * z[t]); P *= g
        xe = xe * g - 1.0; dead = dead or xe < 0.0
    S_list.append(S); end_fail += dead; Z1.append(z[0])
S_list.sort(); finals.sort(); grids = [survival_grid(ws) for _, ws in PATHS]; V60 = grids[0]
p_mc, p_dp = fails[0] / N_PATHS, 1.0 - V60(x0); se = sqrt(p_mc * (1 - p_mc) / N_PATHS)
p_S, (m, s) = sum(1 for S in S_list if S > x0) / N_PATHS, ms(0.6)
print("4% of $1,000,000 = $40,000 a year, 30 years, 60/40")
print(f"{'  1 simulate 50,000 pots':<36}{100 * p_mc:>10.2f} %  (one standard error {100 * se:.2f})")
print(f"{'  2 sum S > 25, same paths':<36}{100 * p_S:>10.2f} %")
print(f"{'  3 survival grid, no randomness':<36}{100 * p_dp:>10.2f} %")
print(f"{'  yearly log-growth m, spread s':<36}{m:>10.6f}{s:>10.6f}")
print(f"{'  pot at 30 years ($000), mean':<36}{sum(finals) / N_PATHS / 1000:>10.0f}  median {finals[N_PATHS // 2] / 1000:.0f}")

def swr(V, target):                                  # bisection: the x where V(x) = 1 - target
    lo, hi = 1.0, 99.0
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if 1.0 - V(mid) > target: lo = mid
        else: hi = mid
    return 1.0 / hi
swr_dp, swr_mc = swr(V60, 0.05), 1.0 / S_list[int(0.95 * N_PATHS)]
print(f"{'safe rate at 5% failure: grid':<36}{100 * swr_dp:>10.2f} %  95th percentile of S {100 * swr_mc:.2f} %")
print("failure by withdrawal rate: rate, grid %, simulated %")
for w in (0.03, 0.035, 0.04, 0.045, 0.05, 0.055, 0.06):
    print(f"  {100 * w:4.1f}  {100 * (1 - V60(1 / w)):8.2f}  {100 * sum(1 for S in S_list if S > 1 / w) / N_PATHS:8.2f}")

print("glide paths at 4%: grid %, simulated %")
for (name, _), V, f in zip(PATHS, grids, fails):
    print(f"  {name:<22}{100 * (1 - V(x0)):8.2f}{100 * f / N_PATHS:8.2f}")

def story(rets, draw=C):                             # pot at the start of each year; year it runs dry
    W, path, dry = W0, [W0], 0
    for t, r in enumerate(rets):
        if W < draw and not dry: dry = t + 1
        W = 0.0 if dry else (W - draw) * (1 + r); path.append(W)
    return path, dry
early, late = [-0.15] * 3 + [0.06] * 27, [0.06] * 27 + [-0.15] * 3
pe, de = story(early); pl, dl = story(late)
print("same 30 returns, crash first vs crash last: pot ($000) every 3 years")
print("  year  " + " ".join(f"{t:5d}" for t in range(0, 31, 3)))
print("  first " + " ".join(f"{pe[t] / 1000:5.0f}" for t in range(0, 31, 3)) + f"   runs dry in year {de}")
print("  last  " + " ".join(f"{pl[t] / 1000:5.0f}" for t in range(0, 31, 3)) + f"   ends at ${pl[-1]:,.2f}")
ne, nl = story(early, 0.0)[0][-1], story(late, 0.0)[0][-1]
dsum = lambda rets: list(accumulate([1.0] + [1 + r for r in rets], lambda a, b: a * b))   # P_0 .. P_30
Pe, Pl = dsum(early), dsum(late); Se, Sl = sum(1 / q for q in Pe[:30]), sum(1 / q for q in Pl[:30])
print(f"  by hand, crash first: {pe[1]:,.2f}  {pe[2]:,.2f}  {pe[3]:,.2f}")
print(f"  discount sum S: first {Se:.4f}  last {Sl:.4f}  P_30 {Pe[30]:.6f}")
print(f"  no withdrawals: first ${ne:,.2f}  last ${nl:,.2f}  average return {100 * sum(early) / 30:.2f} %")

annuity = lambda g: 1.0 / sum(g ** -j for j in range(N_YEARS))
r_avg, r_med = annuity(1.0 + 0.6 * A_S + 0.4 * A_B), annuity(exp(m))
print("what breaks")
print(f"  plan at the 6% average: rate {100 * r_avg:.2f} %, true failure {100 * (1 - V60(1 / r_avg)):.2f} %")
print(f"  plan at the median growth {100 * (exp(m) - 1):.2f} %: rate {100 * r_med:.2f} %, true failure {100 * (1 - V60(1 / r_med)):.2f} %")
print(f"  withdraw at year end, not start: failure {100 * end_fail / N_PATHS:.2f} %")

g1 = [exp(m + s * z) for z in Z1]; mg = sum(g1) / N_PATHS; q = sum(g >= 1.0 for g in g1) / N_PATHS
assert abs(mg - exp(0.6 * A_S + 0.4 * A_B)) < 4 * sqrt(sum((g - mg) ** 2 for g in g1)) / N_PATHS, "yearly growth factor has mean e^a"
assert abs(survival_grid([0.6, 0.6])(2.0) - q) < 4 * sqrt(q * (1 - q) / N_PATHS), "grid's last two years vs the draws"
assert fails[0] == sum(1 for S in S_list if S > x0), "pot-by-pot count must equal the discount-sum count"
assert abs(p_mc - p_dp) < 4 * se, "simulation and grid must agree within four standard errors"
for f, V in zip(fails, grids):
    pm = f / N_PATHS
    assert abs(pm - (1 - V(x0))) < 4 * sqrt(pm * (1 - pm) / N_PATHS), "each glide path, two roads"
assert abs(swr_dp - swr_mc) < 0.001, "safe rate: grid root vs sample quantile"
assert abs(ne - W0 * 0.85 ** 3 * 1.06 ** 27) < 1e-6 and abs(nl - W0 * 0.85 ** 3 * 1.06 ** 27) < 1e-6, "order is irrelevant without withdrawals"
assert de > 0 and dl == 0, "order decides whether the pot lasts once withdrawals start"
assert abs(pl[-1] - Pl[30] * (W0 - C * Sl)) < 1e-6 and (Se > x0) == (de > 0), "the formula on two paths"
print("ALL CHECKS PASS")
