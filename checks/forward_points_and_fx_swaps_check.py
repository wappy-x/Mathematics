# Forward points and the FX swap -- the check behind the card.  Standard library only.
# Road 1 is the formula.  Road 2 sums e^x by hand and finds the far-leg rate by bisection
# on the dollar lender's ledger.  Road 3 is the money-market form.  Road 4 rolls 3M forwards.
from math import exp

S, rd, rf, PIP, N = 1.10, 0.05, 0.03, 0.0001, 10_000_000.0   # USD per EUR, USD rate, EUR rate, pip, EUR notional

def ex(x, terms=40):                        # e^x as 1 + x + x^2/2! + ..., summed by hand
    total, term = 1.0, 1.0
    for k in range(1, terms):
        term *= x / k
        total += term
    return total

def pts(S, rd, rf, T):                      # road 1: the formula, in pips
    return S * (exp((rd - rf) * T) - 1.0) / PIP

def lender_gap(Fq, S, rd, rf, T):           # dollar lender, per euro, at T: swap far leg plus
    far_leg = Fq                            # interest on the euro collateral sold at Fq,
    euro_int = (ex(rf * T) - 1.0) * Fq      # minus what an unsecured dollar deposit pays
    return far_leg + euro_int - S * ex(rd * T)

def bisect(f, lo, hi, n=200):
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        if (f(lo) < 0) == (f(mid) < 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def pts_ledger(S, rd, rf, T):               # road 2: the far rate at which the ledger nets zero
    return (bisect(lambda F: lender_gap(F, S, rd, rf, T), 0.5 * S, 2.0 * S) - S) / PIP

def pts_mm(S, rd, rf, T):                   # road 3: simple rates R = (e^{rT} - 1)/T, tau = T
    Rd, Rf = (ex(rd * T) - 1.0) / T, (ex(rf * T) - 1.0) / T
    return S * (Rd - Rf) * T / (1.0 + Rf * T) / PIP

p1y, p3m = pts(S, rd, rf, 1.0), pts(S, rd, rf, 0.25)
F1y, F3m = S + p1y * PIP, S + p3m * PIP
p1y_roll = (S * (F3m / S) ** 4 - S) / PIP  # road 4: the 3M carry, four times over
rule1y, rule3m = S * (rd - rf) * 1.0 / PIP, S * (rd - rf) * 0.25 / PIP
second = S * ((rd - rf) * 1.0) ** 2 / 2 / PIP     # the square term the rule of thumb drops
p6m = pts(S, rd, rf, 0.5)
p6m_lin = p3m + (0.5 - 0.25) / (1.0 - 0.25) * (p1y - p3m)   # straight line between quoted dates
p1y_s111 = pts(1.11, rd, rf, 1.0)
flip3m, flip1y = pts(S, rf, rd, 0.25), pts(S, rf, rd, 1.0)  # euro pays 5%, dollar 3%

# a dealer's two-way quote: spot bid/ask, points bid/ask; low/high adds, high/low subtracts
sb, sa = 1.0999, 1.1001
def outright(pb, pa):
    return (sb + pb * PIP, sa + pa * PIP) if pb <= pa else (sb - pb * PIP, sa - pa * PIP)
up_b, up_a = outright(55.0, 55.3)
dn_b, dn_a = outright(55.3, 55.0)
wr_b, wr_a = sb + 55.3 * PIP, sa + 55.0 * PIP     # wrong: high/low added anyway

# the 3M swap on EUR 10m: sell euros at spot, buy them back at the 3M outright
T = 0.25
near_usd, far_usd = N * S, N * F3m
points_leg = far_usd - near_usd
usd_int = N * S * (ex(rd * T) - 1.0)             # an unsecured 5% dollar loan for the quarter
eur_int = N * (ex(rf * T) - 1.0)                 # 3% earned on the euro collateral
two_loans = usd_int - eur_int * F3m
gap_rule = N * S * (rd - rf) * T

def lender_value(S_new):                         # dollar lender just after the trade, spot jumps
    held = N * S_new - near_usd                  # euros held now, dollars paid out
    far = far_usd * ex(-rd * T) - N * S_new * ex(-rf * T)   # get dollars, hand back euros, at T
    return held + far
swap_move = lender_value(1.20) - lender_value(S)
fwd_move = N * (1.20 - S) * ex(-rf * T)          # an outright: buy EUR 10m forward at F3m
ndf = N * (1.12 - F3m)                           # cash-settled on a 1.1200 fixing

rows = [
    ("1Y points, formula", p1y), ("1Y points, ledger + bisection", pts_ledger(S, rd, rf, 1.0)),
    ("1Y points, money-market form", pts_mm(S, rd, rf, 1.0)), ("1Y points, 3M rolled 4 times", p1y_roll),
    ("1Y outright", F1y),
    ("3M points, formula", p3m), ("3M points, ledger + bisection", pts_ledger(S, rd, rf, 0.25)),
    ("3M points, money-market form", pts_mm(S, rd, rf, 0.25)), ("3M outright", F3m),
    ("3M carry factor minus one", exp((rd - rf) * 0.25) - 1), ("3M forward minus spot", F3m - S),
    ("1Y carry factor", exp(rd - rf)), ("wrong: 3M points added 4 times", 4 * p3m),
    ("rule of thumb 1Y, S(rd-rf)T", rule1y), ("rule of thumb 3M", rule3m),
    ("1Y exact minus rule", p1y - rule1y), ("  square term S((rd-rf)T)^2/2", second),
    ("6M points, formula", p6m), ("6M points, straight line 3M-1Y", p6m_lin),
    ("1Y points at spot 1.1100", p1y_s111),
    ("flipped rates: 3M points", flip3m), ("flipped rates: 3M ledger", pts_ledger(S, rf, rd, 0.25)),
    ("flipped rates: 1Y points", flip1y),
    ("spot bid", sb), ("spot ask", sa),
    ("quote 55.0/55.3: outright bid", up_b), ("  outright ask", up_a),
    ("quote 55.3/55.0: outright bid", dn_b), ("  outright ask", dn_a),
    ("wrong: 55.3/55.0 added, bid", wr_b), ("  ask", wr_a),
    ("wrong: pip read as 0.001, 3M", S + p3m * 0.001),
    ("swap near leg, USD", near_usd), ("swap far leg, USD", far_usd),
    ("one pip on EUR 10m, USD", N * PIP), ("points leg, USD", points_leg), ("  USD interest on 11m, 5%", usd_int),
    ("  EUR interest on 10m, 3%", eur_int), ("  EUR interest, in USD at F", eur_int * F3m),
    ("  USD interest minus EUR interest", two_loans), ("  rule: 2% gap on 11m, a quarter", gap_rule),
    ("lender value at trade", lender_value(S)), ("spot to 1.20: swap moves", swap_move),
    ("spot to 1.20: outright moves", fwd_move), ("NDF paid on a 1.1200 fixing", ndf),
]
for name, v in rows:
    print(f"{name:<36} {v:>16.6f}")
print()
print("chart, years          " + " ".join(f"{t:>8.2f}" for t in (0.25, 0.5, 1, 2, 3, 5)))
print("chart, points exact   " + " ".join(f"{pts(S, rd, rf, t):>8.2f}" for t in (0.25, 0.5, 1, 2, 3, 5)))
print("chart, rule of thumb  " + " ".join(f"{S * (rd - rf) * t / PIP:>8.2f}" for t in (0.25, 0.5, 1, 2, 3, 5)))

assert abs(p1y - pts_ledger(S, rd, rf, 1.0)) < 1e-6, "formula and ledger must agree, 1Y"
assert abs(p3m - pts_ledger(S, rd, rf, 0.25)) < 1e-6, "formula and ledger must agree, 3M"
assert abs(p1y - pts_mm(S, rd, rf, 1.0)) < 1e-6, "money-market form must agree"
assert abs(p1y - p1y_roll) < 1e-6, "the forward curve is multiplicative"
assert abs((p1y - rule1y) - second) < 0.02, "rule of thumb misses the square term, and little else"
assert abs(flip3m - pts_ledger(S, rf, rd, 0.25)) < 1e-6, "flipped rates: the ledger agrees"
assert p6m_lin > p6m, "points curve bends up, so a straight line overstates a broken date"
grid = [(b / 10, a / 10) for b in range(0, 900, 37) for a in range(0, 900, 41) if b != a]
assert all(outright(b, a)[1] - outright(b, a)[0] > sa - sb for b, a in grid), "the add/subtract rule always widens the spread"
assert abs(points_leg - two_loans) < 1e-4, "points leg = dollar interest minus euro interest"
assert abs(lender_value(S)) < 1e-4, "a swap at market is worth nothing at inception"
assert abs(swap_move - N * (1.20 - S) * (1 - exp(-rf * T))) < 1e-4, "swap feels spot only through euro interest"
print("all checks passed")
