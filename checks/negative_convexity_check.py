# Negative convexity -- the check behind the card.  Standard library only.
# The house pool: $100 of 30-year mortgages, 6% coupon, paid monthly, prepaying at
# 8% a year when the market yield is 6%.  Borrowers refinance faster when rates fall:
# every point the yield drops adds 2.55 points to the yearly prepayment rate.
L, N, I = 100.0, 360, 0.06 / 12            # face, months, coupon per month
BASE_CPR, SLOPE, FLOOR = 0.08, 2.55, 0.02  # speed at 6%, refinancing slope, movers' floor

def cpr(y, slope=SLOPE):                   # yearly prepayment rate at market yield y
    return max(FLOOR, BASE_CPR + slope * (0.06 - y))

def smm(c):                                # the same speed as a fraction per month
    return 1.0 - (1.0 - c) ** (1.0 / 12.0)

def ledger(y, slope=SLOPE):
    # Road 1: run the pool month by month.  Re-amortise, pay, prepay, discount.
    s, j, bal, pv, wal = smm(cpr(y, slope)), y / 12, L, 0.0, 0.0
    for m in range(1, N + 1):
        pay = bal * I / (1.0 - (1.0 + I) ** -(N - m + 1))   # level payment on what is left
        sched = pay - bal * I                               # its principal part
        extra = s * (bal - sched)                           # prepaid on top
        pv += (pay + extra) / (1.0 + j) ** m
        wal += m / 12 * (sched + extra)
        bal -= sched + extra
    return pv, wal / L

def closed(y, slope=SLOPE):
    # Road 2: no ledger.  Balance in closed form, price from the par identity
    # V = L + (i - j) * F, F = sum of discounted opening balances.
    c, j, g = cpr(y, slope), y / 12, (1.0 + I) ** N
    F = sum((1.0 + j) ** -m * L * (g - (1.0 + I) ** (m - 1)) / (g - 1.0)
            * (1.0 - c) ** ((m - 1) / 12) for m in range(1, N + 1))
    return L + (I - j) * F

def exact_at_par(slope=SLOPE):
    # Road 3: no bumps.  D = F/(12L) and C = -F'/(6L), F' split into its two causes.
    c, j, g = cpr(0.06, slope), 0.005, (1.0 + I) ** N
    F = Fdisc = Fspeed = 0.0
    for m in range(1, N + 1):
        B = L * (g - (1.0 + I) ** (m - 1)) / (g - 1.0) * (1.0 - c) ** ((m - 1) / 12)
        F += B / (1.0 + j) ** m
        Fdisc += -(m / 12) * B / (1.0 + j) ** (m + 1)            # heavier discounting
        Fspeed += B / (1.0 + j) ** m * ((m - 1) / 12) * slope / (1.0 - c)  # slower paydown
    return F / (12 * L), -Fdisc / (6 * L), -Fspeed / (6 * L)

def bumped(price, y0, d):                  # three full repricings -> slope and bend
    dn, v0, up = price(y0 - d), price(y0), price(y0 + d)
    return dn, v0, up, (dn - up) / (2 * v0 * d), (dn + up - 2 * v0) / (v0 * d * d)

p1 = lambda y: ledger(y)[0]
dn, v0, up, D1, C1 = bumped(p1, 0.06, 0.01)                  # the job: 100 bp bumps
_, _, _, D2, C2 = bumped(closed, 0.06, 0.01)
_, _, _, Dbp, Cbp = bumped(p1, 0.06, 0.0001)                 # 1 bp bumps
D3, Cdisc, Cspeed = exact_at_par()
C3 = Cdisc + Cspeed
fdn, f0, fup, Df, Cf = bumped(lambda y: ledger(y, 0.0)[0], 0.06, 0.01)  # speed frozen at 8%
d_down, d_up = (dn - v0) / (v0 * 0.01), (v0 - up) / (v0 * 0.01)
pred_dn = L * (1 + D3 * 0.01 + 0.5 * C3 * 0.0001)            # Taylor from road 3
pred_up = L * (1 - D3 * 0.01 + 0.5 * C3 * 0.0001)
wrong_units = L * (1 - D1 * 0.01 + 0.5 * (C1 / 100) * 0.0001)  # -1.2 put in as years^2
right_units = L * (1 - D1 * 0.01 + 0.5 * C1 * 0.0001)
_, _, _, _, C_25 = bumped(p1, 0.06, 0.0025)
_, _, _, _, C_300 = bumped(p1, 0.06, 0.03)
_, _, _, D_dbl, C_dbl = bumped(lambda y: ledger(y, 2 * SLOPE)[0], 0.06, 0.01)

rows = [
    ("month-1 payment per $100", L * I / (1.0 - (1.0 + I) ** -N)),
    ("monthly prepay fraction at 6%", smm(cpr(0.06))),
    ("CPR at 5%", cpr(0.05)), ("CPR at 6%", cpr(0.06)), ("CPR at 7%", cpr(0.07)),
    ("1 ledger  V at 5%", dn), ("1 ledger  V at 6%", v0), ("1 ledger  V at 7%", up),
    ("2 closed  V at 5%", closed(0.05)), ("2 closed  V at 6%", closed(0.06)),
    ("2 closed  V at 7%", closed(0.07)),
    ("gain on a 1-point fall", dn - v0), ("loss on a 1-point rise", v0 - up),
    ("price swing, V- minus V+", dn - up), ("the miss, V- + V+ - 2 V0", dn + up - 2 * v0),
    ("1 ledger  D_eff, 100 bp", D1), ("1 ledger  C_eff, 100 bp", C1),
    ("2 closed  D_eff, 100 bp", D2), ("2 closed  C_eff, 100 bp", C2),
    ("  C_eff / 100, as quoted", C1 / 100), ("  half of that", C1 / 200),
    ("1 ledger  D_eff, 1 bp", Dbp), ("1 ledger  C_eff, 1 bp", Cbp),
    ("3 exact   D at par", D3), ("3 exact   C at par", C3),
    ("  discounting part of C", Cdisc), ("  prepayment part of C", Cspeed),
    ("down-side duration", d_down), ("up-side duration", d_up),
    ("average life at 5%, years", ledger(0.05)[1]), ("average life at 6%, years", ledger(0.06)[1]),
    ("average life at 7%, years", ledger(0.07)[1]),
    ("Taylor V at 5%, exact D and C", pred_dn), ("Taylor V at 7%, exact D and C", pred_up),
    ("wrong: speed frozen, V at 5%", fdn), ("wrong: speed frozen, V at 7%", fup),
    ("wrong: speed frozen, D_eff", Df), ("wrong: speed frozen, C_eff", Cf),
    ("wrong: -1.2 used as years^2, V at 7%", wrong_units),
    ("  right units, V at 7%", right_units),
    ("try: C_eff, 25 bp bumps", C_25), ("try: C_eff, 300 bp bumps", C_300),
    ("try: slope doubled, D_eff", D_dbl), ("try: slope doubled, C_eff", C_dbl),
]
for name, v in rows:
    print(f"{name:<38} {v:>12.6f}")

ys = [0.03 + 0.005 * k for k in range(11)]                    # chart: yields 3% to 8%
print("chart, yield %     " + " ".join(f"{100 * y:6.1f}" for y in ys))
print("chart, prepaying   " + " ".join(f"{ledger(y)[0]:6.2f}" for y in ys))
print("chart, frozen 8%   " + " ".join(f"{ledger(y, 0.0)[0]:6.2f}" for y in ys))
print("chart, tangent     " + " ".join(f"{L * (1 - D3 * (y - 0.06)):6.2f}" for y in ys))

assert abs(v0 - L) < 1e-9,                "ledger at par must equal the par identity's 100"
assert abs(dn - closed(0.05)) < 1e-9 and abs(up - closed(0.07)) < 1e-9, "roads 1 and 2 disagree"
assert abs(Cbp - C3) < 0.01,              "1 bp bumped convexity vs exact derivative"
assert abs(Dbp - D3) < 1e-5,              "1 bp bumped duration vs exact derivative"
assert abs(Cf - Cdisc) < 1.0,             "frozen pool's convexity vs discounting part"
assert C1 < 0 < Cf and abs(C1 / 100 + 1.2) < 0.05, "house pool must show -1.2 per hundred"
print("ALL CHECKS PASS")
