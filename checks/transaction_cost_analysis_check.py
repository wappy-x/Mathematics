# Transaction cost analysis -- the check behind the card.  Standard library only.
# One sell order: 100,000 Acme shares, decided at Monday's close, worked all Tuesday.
# Roads: (1) the benchmark formula on the average price; (2) a fill-by-fill cash
# ledger in whole cents; (3) timing + impact built from price legs alone; (4) VWAP by
# a direct sum and by a running update; (5) the noise in one order's cost, exact
# variance against a 20,000-order simulation with a hand-written random generator.
from math import sqrt, log, cos, pi

SIDE = -1                                    # -1 = sell, +1 = buy
Q, P_D, P_A = 100_000, 100.00, 99.96         # shares; decision price; arrival price
FILLS = [(10_000, 99.93), (15_000, 99.92), (20_000, 99.89),     # our six child fills,
         (20_000, 99.86), (20_000, 99.85), (15_000, 99.86)]     # one per trading hour
TAPE = [(200_000, 99.97), (120_000, 99.96), (100_000, 99.93),   # everyone else's trades,
        (90_000, 99.90), (110_000, 99.90), (280_000, 99.91)]    # same six buckets
HOURS = [0.5, 1.5, 2.5, 3.5, 4.5, 5.75]      # middle of each bucket, hours after the open
DAY = 6.5                                    # hours in the trading day

def average(trades):                         # size-weighted average price
    return sum(q * p for q, p in trades) / sum(q for q, _ in trades)

def cost_bp(bench, pbar):                    # signed cost against a benchmark, in bp of decision notional
    return 1e4 * SIDE * (pbar - bench) / P_D

# ---- road 1: formula on the average fill price ----
pbar, p_v = average(FILLS), average(TAPE)
IS, arrival, vwap = cost_bp(P_D, pbar), cost_bp(P_A, pbar), cost_bp(p_v, pbar)

# ---- road 2: cash ledger in whole cents, fill by fill ----
paper = Q * round(P_D * 100)                              # cents the decision price promised
actual = sum(q * round(p * 100) for q, p in FILLS)        # cents the fills raised
IS_ledger = 1e4 * SIDE * (actual - paper) / paper

# ---- road 3: timing leg + impact leg, each from its own prices ----
timing = 1e4 * SIDE * (P_A - P_D) / P_D
impact = sum(1e4 * SIDE * q * (p - P_A) for q, p in FILLS) / (Q * P_D)
drift = 1e4 * SIDE * (p_v - P_A) / P_D                    # arrival -> market VWAP

# ---- road 4: VWAP by a running update, one bucket at a time ----
run_v, run_vol = 0.0, 0
for v, m in TAPE:
    run_vol += v
    run_v += v / run_vol * (m - run_v)

# ---- inside the 5 bp against VWAP: each hour's fill vs that hour, and the schedule ----
own_sched = sum(q * m for (q, _), (_, m) in zip(FILLS, TAPE)) / Q
slices, schedule = cost_bp(own_sched, pbar), 1e4 * SIDE * (own_sched - p_v) / P_D
V = sum(v for v, _ in TAPE)                               # hour by hour, no averages used:
slices_hr = sum(1e4 * SIDE * q * (p - m) for (q, p), (_, m) in zip(FILLS, TAPE)) / (Q * P_D)
sched_w = sum(1e4 * SIDE * (q / Q - v / V) * m for (q, _), (v, m) in zip(FILLS, TAPE)) / P_D

# ---- what breaks ----
as_buy = -IS
unweighted = cost_bp(P_D, sum(p for _, p in FILLS) / len(FILLS))
with_own = cost_bp(average(TAPE + FILLS), pbar)
only_us = cost_bp(average(FILLS), pbar) + 0.0          # + 0.0 turns -0.0 into 0.0
done = FILLS[:-1]; unfilled = Q - sum(q for q, _ in done); P_CLOSE = 99.80
filled_only = cost_bp(P_D, average(done))
with_opp = (sum(1e4 * SIDE * q * (p - P_D) for q, p in done)
            + 1e4 * SIDE * unfilled * (P_CLOSE - P_D)) / (Q * P_D)
fee_2000 = IS + 1e4 * 2000 / (Q * P_D)

rows = [("decision price", P_D), ("arrival price", P_A), ("closing price, partial case", P_CLOSE),
        ("paper proceeds ($)", paper / 100), ("cash raised ($)", actual / 100),
        ("average fill price", pbar), ("market VWAP, others only", p_v), ("  VWAP, running update", run_v),
        ("1 shortfall, formula (bp)", IS), ("2 shortfall, cents ledger (bp)", IS_ledger),
        ("3 timing leg (bp)", timing), ("3 impact leg (bp)", impact), ("  timing + impact (bp)", timing + impact),
        ("arrival cost, formula (bp)", arrival), ("VWAP cost (bp)", vwap), ("  arrival -> VWAP drift (bp)", drift),
        ("  own-schedule market price", own_sched), ("  slices vs their hour (bp)", slices),
        ("  schedule vs volume curve (bp)", schedule), ("shortfall ($)", IS * Q * P_D / 1e4),
        ("timing ($)", timing * Q * P_D / 1e4), ("impact ($)", impact * Q * P_D / 1e4),
        ("VWAP cost ($)", vwap * Q * P_D / 1e4), ("share of day's volume", Q / (Q + sum(v for v, _ in TAPE))),
        ("wrong: scored as a buy (bp)", as_buy), ("wrong: unweighted fill average (bp)", unweighted),
        ("wrong: VWAP with our own fills (bp)", with_own), ("wrong: we are the whole tape (bp)", only_us),
        ("partial: filled shares only (bp)", filled_only), ("partial: with missed shares (bp)", with_opp),
        ("partial: missed shares' loss ($)", unfilled * (P_D - P_CLOSE)), ("try: $2,000 commission (bp)", fee_2000)]
for name, v in rows:
    print(f"{name:<38}{v:>12.4f}")

# ---- road 5: how noisy is one order's arrival cost? ----
SIGMA_DAY = P_D * 0.20 / sqrt(252.0)          # dollars of wander in one day at 20% a year
IMPACT = 0.08                                 # each fill lands 8 cents below the mid of its hour
t = [h / DAY for h in HOURS]
w = [q / Q for q, _ in FILLS]
var = SIGMA_DAY ** 2 * sum(w[j] * w[k] * min(t[j], t[k]) for j in range(6) for k in range(6))
sd_exact = 1e4 * sqrt(var) / P_D

state = 20260928
def uniform():                                # splitmix64, written out; returns a number in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 1.0 / 9007199254740992.0

def normal():                                 # Box-Muller, one draw per pair
    u1, u2 = uniform(), uniform()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

N_SIM, EDGES = 20_000, [-150, -100, -50, 0, 50, 100, 150]
costs, bins = [], [0] * (len(EDGES) + 1)
for _ in range(N_SIM):
    mid, prev, pb = P_A, 0.0, 0.0
    for tk, wk in zip(t, w):
        mid += SIGMA_DAY * sqrt(tk - prev) * normal()
        prev = tk
        pb += wk * (mid - IMPACT)
    c = cost_bp(P_A, pb)
    costs.append(c)
    bins[sum(1 for e in EDGES if c >= e)] += 1
mean = sum(costs) / N_SIM
sd = sqrt(sum((c - mean) ** 2 for c in costs) / (N_SIM - 1))
print()
for name, v in (("sim: one day's wander ($)", SIGMA_DAY), ("sim: true impact (bp)", 1e4 * IMPACT / P_D), ("sim: mean arrival cost (bp)", mean),
                ("sim: standard error of mean (bp)", sd / sqrt(N_SIM)), ("sd, exact (bp)", sd_exact),
                ("sd, simulated (bp)", sd), ("sim: share looking like a gain", sum(1 for c in costs if c < 0) / N_SIM),
                ("orders to see 8 bp at 2 sd", (2 * sd_exact / 8) ** 2)):
    print(f"{name:<38}{v:>12.4f}")
labels = ["below -150"] + [f"{a} to {b}" for a, b in zip(EDGES, EDGES[1:])] + ["150 and up"]
for lab, n in zip(labels, bins):
    print(f"histogram {lab:<14}{n:>8d}")
print("chart, others' hourly price  " + " ".join(f"{m:.2f}" for _, m in TAPE))
print("chart, our hourly fill       " + " ".join(f"{p:.2f}" for _, p in FILLS))

assert abs(IS - IS_ledger) < 1e-9,            "formula road vs cents ledger"
assert abs(timing + impact - IS) < 1e-9,      "legs built from their own prices must rebuild the shortfall"
assert abs(run_v - p_v) < 1e-9,               "running VWAP vs direct VWAP"
assert abs(slices - slices_hr) < 1e-9,       "fills vs their hour: average road vs hour-by-hour road"
assert abs(schedule - sched_w) < 1e-9,       "schedule: average road vs volume-weight road"
assert abs(slices_hr + sched_w - vwap) < 1e-9, "hour-by-hour split vs the VWAP cost"
assert [round(x, 9) for x in (IS, timing, impact, vwap)] == [12, 4, 8, 5], "the card's 12 = 4 + 8 and 5"
assert abs(mean - 8.0) < 4 * sd / sqrt(N_SIM), "simulated mean vs the 8 bp built in"
assert abs(sd / sd_exact - 1.0) < 0.03,       "simulated noise vs exact variance"
print("ALL CHECKS PASS")
