# Contango, backwardation and roll yield -- the check behind the card.
# Standard library only.  Every number quoted on the card is printed here.
# Nothing imported knows the answer: the random numbers come from a generator
# written below, the straight-line fit is written out, the ledgers are loops.
from math import exp, log, sqrt, cos, pi

r, u = 0.05, 0.02                     # bank rate and crude storage, per year
S_OIL, F12_OIL = 80.0, 84.0           # crude: spot and the 12-month future, $/barrel
S_CU, F12_CU = 9000.0, 8700.0         # copper: spot and the 12-month future, $/tonne
DAYS = 30                             # daily marks in each month of a ledger

def carry(S, F12):                    # c = r + u - y, read off the two ends of a strip
    return log(F12 / S)

def strip(S, c):                      # the curve: future for delivery k months out
    return [S * exp(c * k / 12) for k in range(13)]

def roll_formula(c, months):          # road 1: spot fixed, shape fixed
    return exp(-c * months / 12) - 1

def ledger(c, spot, months, per_roll=1):
    # Road 2: hold the front contract, mark it every day from the curve, and at
    # its delivery buy the new front.  spot[i] is the spot price on day i.
    value, day = 1.0, 0
    for _ in range(months // per_roll):
        for d in range(per_roll * DAYS):
            left0 = (per_roll * DAYS - d) / (12 * DAYS)    # years to delivery today
            left1 = left0 - 1 / (12 * DAYS)                # and tomorrow
            value *= spot[day + 1] * exp(c * left1) / (spot[day] * exp(c * left0))
            day += 1
    return value - 1

state = 20260927                      # a 64-bit linear congruential generator
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53

def gauss():                          # Box-Muller: two uniforms make one bell-curve draw
    u1 = uniform()
    u2 = uniform()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

def fit_slope(prices):                # road 4: least-squares slope of ln F against years
    xs = [k / 12 for k in range(len(prices))]
    ys = [log(p) for p in prices]
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    return sxy / sum((x - mx) ** 2 for x in xs)

def pct(x): return f"{0.0 if abs(x) < 1e-12 else 100 * x:+.4f}%"
def show(label, text): print(f"{label:<44} {text}")

c_oil, c_cu = carry(S_OIL, F12_OIL), carry(S_CU, F12_CU)
flat_oil = [S_OIL] * (12 * DAYS + 1)
flat_cu = [S_CU] * (12 * DAYS + 1)
oil_strip, cu_strip = strip(S_OIL, c_oil), strip(S_CU, c_cu)

sigma, dt, path = 0.30, 1 / (12 * DAYS), [S_OIL]      # road 3: a random spot path
for _ in range(12 * DAYS):
    path.append(path[-1] * exp(-0.5 * sigma * sigma * dt + sigma * sqrt(dt) * gauss()))
fut_log = log(1 + ledger(c_oil, path, 12))
spot_log = log(path[-1] / path[0])
quoted = [round(p, 2) for p in oil_strip]               # the strip as a screen shows it

show("crude carry c = r + u - y, per year", f"{c_oil:.6f}")
y_oil = r + u - c_oil                                   # what the market forward implies
show("crude implied convenience yield y", f"{y_oil:.6f}")
print("crude strip, months 0..12:", " ".join(f"{p:.2f}" for p in oil_strip))
show("front minus spot, $; growth factor e^c", f"{oil_strip[1] - S_OIL:.2f}  {exp(c_oil):.6f}")
show("full-carry ceiling r + u; 12-month cap", f"{r + u:.6f}  {S_OIL * exp(r + u):.2f}")
show("copper carry c, per year", f"{c_cu:.6f}")
print("copper strip, months 0,3,6,9,12:", " ".join(f"{cu_strip[k]:.2f}" for k in (0, 3, 6, 9, 12)))
show("1 formula, crude, one month", pct(roll_formula(c_oil, 1)))
show("2 daily ledger, crude, one month", pct(ledger(c_oil, flat_oil, 1)))
show("  roll-date spread (F0 - F1) / F1", pct((oil_strip[0] - oil_strip[1]) / oil_strip[1]))
show("  one month, in logs, -c/12", f"{-c_oil / 12:.6f}")
show("1 formula, crude, twelve months", pct(roll_formula(c_oil, 12)))
show("2 daily ledger, crude, twelve months", pct(ledger(c_oil, flat_oil, 12)))
show("  spot / 12-month future - 1", pct(S_OIL / F12_OIL - 1))
show("3 random path: spot ends at", f"{path[-1]:.2f}")
show("  futures log return", f"{fut_log:.6f}")
show("  spot log return", f"{spot_log:.6f}")
show("  futures minus spot, the roll", f"{fut_log - spot_log:.6f}")
show("4 straight-line fit to the quoted strip, c", f"{fit_slope(quoted):.6f}")
show("copper: formula, one month", pct(roll_formula(c_cu, 1)))
show("copper: daily ledger, one month", pct(ledger(c_cu, flat_cu, 1)))
show("copper: formula, twelve months", pct(roll_formula(c_cu, 12)))
show("copper: daily ledger, twelve months", pct(ledger(c_cu, flat_cu, 12)))
show("crude roller + cash interest, a year", pct(exp(r - c_oil) - 1))
show("crude barrel in a tank, y - u, a year", pct(exp(y_oil - u) - 1))
for end in (76.0, 80.0, 84.0, 88.0):
    walk = [S_OIL * (end / S_OIL) ** (i / (12 * DAYS)) for i in range(12 * DAYS + 1)]
    show(f"crude roller, spot drifts to {end:.0f}", f"spot {pct(end / S_OIL - 1)}  roller {pct(ledger(c_oil, walk, 12))}")
show("wrong: strip read as a forecast, a year", pct(F12_OIL / S_OIL - 1))
show("wrong: 5% spread / 12, one month", pct(-(F12_OIL / S_OIL - 1) / 12))
show("try: strip 80 -> 88, one month", pct(roll_formula(carry(80.0, 88.0), 1)))
show("try: y = 7%, carry and one month", f"{r + u - 0.07:.6f}  {pct(roll_formula(r + u - 0.07, 1))}")
show("try: roll quarterly, crude, a year", pct(ledger(c_oil, flat_oil, 12, per_roll=3)))
print("chart, crude roller index:", " ".join(f"{100 * (1 + roll_formula(c_oil, m)):.2f}" for m in range(13)))
print("chart, copper roller index:", " ".join(f"{100 * (1 + roll_formula(c_cu, m)):.2f}" for m in range(13)))
print("chart, spot index:", " ".join(f"{100 * flat_oil[m * DAYS] / S_OIL:.2f}" for m in range(13)))

assert abs(ledger(c_oil, flat_oil, 12) - (S_OIL / F12_OIL - 1)) < 1e-12, "ledger vs the two ends of the strip"
assert abs(roll_formula(c_oil, 1) - ledger(c_oil, flat_oil, 1)) < 1e-12, "formula vs daily ledger, crude month"
assert abs(roll_formula(c_cu, 12) - ledger(c_cu, flat_cu, 12)) < 1e-12, "formula vs daily ledger, copper year"
assert abs(ledger(c_oil, flat_oil, 1) - (oil_strip[0] - oil_strip[1]) / oil_strip[1]) < 1e-12, "ledger vs roll-date spread"
assert abs((fut_log - spot_log) + c_oil) < 1e-9, "random path: futures minus spot is -c"
assert abs(fit_slope(quoted) - c_oil) < 2e-4, "slope of the quoted strip recovers c"
assert ledger(c_cu, flat_cu, 12) > 0 > ledger(c_oil, flat_oil, 12), "backwardation pays, contango bleeds"
print("ALL CHECKS PASS")
