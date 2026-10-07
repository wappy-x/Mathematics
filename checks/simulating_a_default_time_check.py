# Simulating a default time -- the check behind the card.  Standard library only.
# Nothing is imported that already knows the answer: the uniform numbers come
# from the recurrence on the Monte Carlo card, the root finder is bisection
# written out, and every survival number is exp of minus an area.
from math import exp, log, sqrt

SEED, PIECES, MOD = 20260914, 100000, 1 << 32
MARKS = (1000, 2000, 5000, 10000, 20000, 50000, 100000)
LAM = 0.02                                  # the game: 2% a round, flat
NODES = (0.0, 1.0, 3.0, 5.0)                # the van: hazard flat between nodes
RATES = (0.02, 0.04, 0.06)                  # the last rate carries on past year 5
R, REC = 0.05, 40.0                         # Northwind: riskless rate, $ recovered per $100

def uniform(state):                         # one step of the recurrence, whole numbers
    state = (1664525 * state + 1013904223) % MOD
    return state, (state + 0.5) / MOD       # strictly inside 0 and 1

def area(t, rates=RATES):                   # cumulative hazard: area under the steps up to t
    total = 0.0
    for i, lam in enumerate(rates):
        end = NODES[i + 1] if i + 1 < len(rates) else float("inf")
        total += lam * max(0.0, min(t, end) - NODES[i])
    return total

def surv(t, rates=RATES):
    return exp(-area(t, rates))

def invert_steps(u):                        # road A: walk the steps until the area reaches -ln u
    need = -log(u)
    for i, lam in enumerate(RATES):
        end = NODES[i + 1] if i + 1 < len(RATES) else float("inf")
        if need <= lam * (end - NODES[i]):
            return NODES[i] + need / lam, i, need   # date, step, budget left on entering it
        need -= lam * (end - NODES[i])

def invert_bisect(u):                       # road B: solve S(t) = u by halving an interval
    lo, hi = 0.0, 1000.0
    for _ in range(64):
        mid = 0.5 * (lo + hi)
        if surv(mid) > u: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

# ---- one uniform per piece, read off both curves ----
state, flat, van, misfits = SEED, [], [], 0
for _ in range(PIECES):
    state, u = uniform(state)
    flat.append(-log(u) / LAM)
    van.append(invert_steps(u)[0])
    misfits += abs(van[-1] - invert_bisect(u)) > 1e-9

def gone(times, t, n=PIECES):
    return sum(1 for x in times[:n] if x <= t) / n

def se(p, n): return sqrt(p * (1 - p) / n)

# ---- road C for the game: tick by tick, knocked out with chance rate x tick ----
tick_out = 0
for _ in range(PIECES):
    for _ in range(50):                     # 50 ticks of 0.1 round
        state, u = uniform(state)
        if u < LAM * 0.1:
            tick_out += 1
            break
tick = tick_out / PIECES

f_exact, f_sim = 1 - exp(-LAM * 5), gone(flat, 5.0)
v_exact, v_sim = 1 - surv(5.0), gone(van, 5.0)
life = sum(flat) / PIECES
pays = [REC * exp(-R * x) if x <= 5 else 100 * exp(-R * 5) for x in flat]
bond_draws = sum(pays) / PIECES
bond_se = sqrt(sum((p - bond_draws) ** 2 for p in pays) / (PIECES - 1) / PIECES)
bond_formula = 100 * exp(-(R + LAM) * 5) + REC * LAM / (R + LAM) * (1 - exp(-(R + LAM) * 5))
print("hand draws: U, -ln U, game round, van year")
for u in (0.97, 0.90, 0.85, 0.50):
    tau, i, left = invert_steps(u)
    print(f"  U = {u:.2f}   -ln U {-log(u):.6f}   game {-log(u) / LAM:8.4f}   van {tau:8.4f}"
          f" = {NODES[i]:.0f} + {left:.6f} / {RATES[i]:.2f} = {NODES[i]:.0f} + {left / RATES[i]:.4f}")
print("van: area at years 1, 3, 5     " + " ".join(f"{area(t):.6f}" for t in (1.0, 3.0, 5.0)))
print("van: survival at years 1, 3, 5 " + " ".join(f"{surv(t):.6f}" for t in (1.0, 3.0, 5.0)))
rows = [
    ("game: % gone by round 5, formula", 100 * f_exact),
    ("game: % gone by round 5, inverted draws", 100 * f_sim),
    ("game: % gone by round 5, tick by tick", 100 * tick),
    ("game: gap, draws minus formula, % points", 100 * (f_sim - f_exact)),
    ("game: survival at round 5", exp(-LAM * 5)),
    ("game: standard error, % points", 100 * se(f_sim, PIECES)),
    ("game: average lifetime, draws", life), ("game: average lifetime, 1/rate", 1 / LAM),
    ("van: % gone by year 5, formula", 100 * v_exact),
    ("van: % gone by year 5, inverted draws", 100 * v_sim),
    ("van: standard error, % points", 100 * se(v_sim, PIECES)),
    ("van: % of tickets dated past year 5", 100 * (1 - v_sim)),
    ("Northwind $100 in 5y, alive only, formula", 100 * exp(-R * 5) * exp(-LAM * 5)),
    ("Northwind $100 in 5y, alive only, draws", 100 * exp(-R * 5) * (1 - f_sim)),
    ("Northwind, $40 at default date, draws", bond_draws),
    ("Northwind, $40 at default date, formula", bond_formula),
    ("Northwind, standard error of the draws", bond_se),
    ("wrong: rate times -ln U, % gone by 5", 100 * sum(1 for x in flat if x * LAM * LAM <= 5) / PIECES),
    ("wrong: 2% per round as a coin, % gone", 100 * (1 - 0.98 ** 5)),
    ("wrong: van at its average 4.4%, year-1 %", 100 * (1 - exp(-0.044))),
    ("  right: van year-1 %", 100 * (1 - surv(1.0))),
    ("wrong: van at 6% throughout, % gone by 5", 100 * (1 - exp(-0.30))),
    ("try: van years 4-5 at 3%, % gone by 5", 100 * (1 - surv(5.0, (0.02, 0.04, 0.03)))),
    ("try: 1,000 pieces, % gone by round 5", 100 * gone(flat, 5.0, 1000)),
]
for name, v in rows:
    print(f"{name:<44} {v:>10.4f}")
print(f"van: draws where steps and bisection split {misfits:>6d} of {PIECES}")
print("van, year by year: % defaulting, draws vs formula")
for y in range(1, 6):
    sim = gone(van, y) - gone(van, y - 1)
    print(f"  year {y}   draws {100 * sim:6.2f}   formula {100 * (surv(y - 1.0) - surv(float(y))):6.2f}")
print("chart, % alive at 0, 0.5, ..., 5 years")
half = [0.5 * i for i in range(11)]
print("  van formula " + " ".join(f"{100 * surv(t):6.2f}" for t in half))
print("  van draws   " + " ".join(f"{100 * (1 - gone(van, t)):6.2f}" for t in half))
print("  flat 2%     " + " ".join(f"{100 * exp(-LAM * t):6.2f}" for t in half))
print("chart, game % gone by round 5 after n pieces")
print("  " + " ".join(f"{m:>6d}" for m in MARKS))
print("  " + " ".join(f"{100 * gone(flat, 5.0, m):6.2f}" for m in MARKS))

assert abs(f_sim - f_exact) < 4 * se(f_sim, PIECES), "inverted draws vs the flat formula"
assert abs(tick - f_exact) < 4 * se(tick, PIECES), "tick-by-tick game vs the flat formula"
assert abs(v_sim - v_exact) < 4 * se(v_sim, PIECES), "van draws vs e^-area"
assert abs(v_exact - (1 - exp(-(0.02 * 1 + 0.04 * 2 + 0.06 * 2)))) < 1e-12, "area by the steps vs by hand"
assert misfits == 0, "stepwise inversion vs bisection on S"
assert abs(life - 1 / LAM) < 4 * (1 / LAM) / sqrt(PIECES), "average lifetime vs 1/rate"
assert abs(bond_draws - bond_formula) < 4 * bond_se, "priced by draws vs priced by formula"
print("ALL CHECKS PASS")
