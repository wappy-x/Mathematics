# Inflation-linked bond -- the check behind the card.  Standard library only.
# The 10-year linker: 1% real coupon, dated 15 Jul 2026, settles 31 Jul 2026 at a 1.02% real yield.
# Index levels are invented for teaching; the rules are the US Treasury's (31 CFR 356, Appendix B).
from datetime import date
from math import sqrt
def ref_cpi(m0, m1, day, days):
    # CPI levels in thousandths.  Road 1: the interpolation formula.  Road 2: walk one day at a time.
    formula = m0 * days + (day - 1) * (m1 - m0)
    walk = m0 * days
    for _ in range(day - 1):
        walk += m1 - m0
    assert walk == formula
    six = formula * 1000 // days          # truncate to six decimals
    return (six + 5) // 10                # round to five: result in units of 0.00001
def index_ratio(ref, base):               # both in units of 0.00001; ratio in units of 0.00001
    six = ref * 1_000_000 // base
    return (six + 5) // 10
def price_closed(C, i, n, r, s):          # Treasury's formula: real clean price and accrued, per 100
    v = 1 / (1 + i / 2)
    an = (1 - v ** n) / (i / 2) if i != 0 else float(n)
    whole = (C / 2 + (C / 2) * an + 100 * v ** n) / (1 + (r / s) * (i / 2))
    accrued = (s - r) / s * (C / 2)
    return whole - accrued, accrued
def dirty_by_sum(C, i, n, r, s):          # the same price, one cashflow at a time
    stub = 1 + (r / s) * (i / 2)
    total = 0.0
    for k in range(n + 1):
        cash = C / 2 + (100 if k == n else 0)
        total += cash / (stub * (1 + i / 2) ** k)
    return total
def ddirty_dy(C, i, n, r, s):             # slope of the dirty price in the real yield, by calculus
    stub = 1 + (r / s) * (i / 2)
    total = 0.0
    for k in range(n + 1):
        cash = C / 2 + (100 if k == n else 0)
        total -= cash * ((r / s) / 2 / stub + k / 2 / (1 + i / 2)) / (stub * (1 + i / 2) ** k)
    return total
def yield_bisect(target, C, n, r, s):
    lo, hi = -0.5, 0.5                    # price falls as yield rises, so one crossing
    for _ in range(200):
        mid = (lo + hi) / 2
        if price_closed(C, mid, n, r, s)[0] > target: lo = mid
        else: hi = mid
    return (lo + hi) / 2
def yield_newton(target, C, n, r, s):
    y = 0.05
    for _ in range(50):
        acc = price_closed(C, y, n, r, s)[1]
        y -= (dirty_by_sum(C, y, n, r, s) - acc - target) / ddirty_dy(C, y, n, r, s)
    return y

# ---- road 0: Treasury's own published examples, reproduced to six decimals ----
t_ref = ref_cpi(154400, 154900, 15, 30)
t_ratio = index_ratio(ref_cpi(154400, 154900, 16, 30), t_ref)
t_p1 = price_closed(3.875, 0.03898, 19, 181, 181)[0]
t_p2, t_a2 = price_closed(3.625, 0.0365, 18, 92, 184)
t_sa2 = round(round(t_p2, 6) * 1.01074, 6) + round(t_a2 * 1.01074, 6)
assert (t_ref, t_ratio) == (15463333, 100011)
assert abs(t_p1 - 99.811030) < 5e-7 and abs(t_p2 - 99.797017) < 5e-7 and abs(t_sa2 - 101.784820) < 2e-6

# ---- the 10-year linker ----
base = ref_cpi(320000, 320930, 15, 31)    # 15 Jul 2026: April and May 2026 CPI, 14/31 of the way
settle = ref_cpi(320000, 320930, 31, 31)  # 31 Jul 2026: 30/31 of the way
jan = ref_cpi(324000, 324310, 15, 31)     # 15 Jan 2027: October and November 2026 CPI
I_s, I_jan = index_ratio(settle, base) / 1e5, index_ratio(jan, base) / 1e5
assert (base, settle, jan, round(I_s * 1e5), round(I_jan * 1e5)) == (32042000, 32090000, 32414000, 100150, 101161)
s = (date(2027, 1, 15) - date(2026, 7, 15)).days
r = (date(2027, 1, 15) - date(2026, 7, 31)).days
n = 19                                    # full half-years after the next coupon, to 15 Jul 2036
C, y, face = 1.0, 0.0102, 10.0            # per 100 original face; face scales to $1,000
clean, accrued = price_closed(C, y, n, r, s)
dirty = dirty_by_sum(C, y, n, r, s)
invoice = face * I_s * dirty
assert abs(clean + accrued - dirty) < 1e-11

# ---- the inverse: quoted real price in, real yield out, two root finders ----
y_b = yield_bisect(clean, C, n, r, s)
y_n = yield_newton(clean, C, n, r, s)
assert abs(y_b - y) < 1e-12 and abs(y_n - y) < 1e-12

# ---- road 3: nominal cashflows, inflation at the 2.5% breakeven, nominal yield by Fisher ----
def nominal_road(pi):
    g = sqrt(1 + pi)                      # one half-year of inflation
    zn = (1 + y / 2) * g                  # nominal growth per half-year
    stub = (1 + (r / s) * (y / 2)) * g ** (r / s)
    pv = 0.0
    for k in range(n + 1):
        cash = C / 2 + (100 if k == n else 0)
        pv += cash * I_s * g ** (r / s + k) / (stub * zn ** k)
    return face * pv, 2 * (zn - 1), I_s * g ** (r / s + n)
nom_pv, nom_yield, final_ratio = nominal_road(0.025)
nom_pv_hi = nominal_road(0.035)[0]
assert abs(nom_pv - invoice) < 1e-9 and abs(nom_pv_hi - invoice) < 1e-9

# ---- sensitivities, by calculus and by bumping ----
dv01 = -face * I_s * ddirty_dy(C, y, n, r, s) * 1e-4
dv01_bump = face * I_s * (dirty_by_sum(C, y - 1e-4, n, r, s) - dirty_by_sum(C, y + 1e-4, n, r, s)) / 2
assert abs(dv01 - dv01_bump) < 1e-6

# ---- what breaks ----
no_ratio = face * dirty
jan_ratio = face * I_jan * dirty
real_at_nominal = face * I_s * dirty_by_sum(C, nom_yield, n, r, s)
nominal_at_real = face * I_s * sum((C / 2 + (100 if k == n else 0)) * sqrt(1.025) ** (r / s + k)
                  / ((1 + (r / s) * (y / 2)) * (1 + y / 2) ** k) for k in range(n + 1))
street = face * I_s * sum((C / 2 + (100 if k == n else 0)) / (1 + y / 2) ** (r / s + k) for k in range(n + 1))

def row(label, v, d=6): print(f"{label:<44} {v:.{d}f}")
row("treasury 1996 ref CPI, 15 Apr", t_ref / 1e5, 5); row("treasury 1996 index ratio, 16 Apr", t_ratio / 1e5, 5)
row("treasury 1999 real price", t_p1); row("treasury 1998 real price", t_p2); row("treasury 1998 settlement amount", t_sa2)
row("ref CPI 15 Jul 2026 (base)", base / 1e5, 5); row("ref CPI 31 Jul 2026 (settlement)", settle / 1e5, 5)
row("ref CPI 15 Jan 2027 (first coupon)", jan / 1e5, 5)
row("index ratio 31 Jul 2026", I_s, 5); row("index ratio 15 Jan 2027", I_jan, 5)
print(f"{'days in period s, days to coupon r, n':<44} {s} {r} {n}")
row("real coupon per half-year, per $1,000", face * C / 2, 2)
row("first coupon paid, per $1,000", face * C / 2 * I_jan, 5)
row("1 real clean price per 100, closed form", clean); row("  real accrued per 100", accrued)
row("2 real dirty per 100, cashflow by cashflow", dirty)
row("invoice per $1,000 = 10 x ratio x dirty", invoice, 4)
row("  nominal clean per $1,000", face * I_s * clean, 4); row("  nominal accrued per $1,000", face * I_s * accrued, 4)
row("yield from price, bisection (%)", 100 * y_b, 10); row("yield from price, Newton (%)", 100 * y_n, 10)
row("3 nominal road: PV at 2.5% breakeven", nom_pv, 4); row("  nominal yield by Fisher (%)", 100 * nom_yield, 4)
row("  same, breakeven 3.5%", nom_pv_hi, 4)
row("  projected final index ratio", final_ratio, 5); row("  projected final principal", 1000 * final_ratio, 2)
row("real DV01 per $1,000, calculus", dv01, 4); row("real DV01 per $1,000, bump", dv01_bump, 4)
row("real modified duration (years)", dv01 / invoice * 1e4, 4)
row("invoice change per 0.01 of index ratio", face * dirty * 0.01, 4)
row("wrong: no index ratio", no_ratio, 4); row("wrong: coupon-date ratio 1.01161", jan_ratio, 4)
row("wrong: real cashflows at nominal yield", real_at_nominal, 4)
row("wrong: nominal cashflows at real yield", nominal_at_real, 4)
row("convention: compound stub instead of simple", street, 4)
row("floor: principal if final ratio 0.95", 1000 * max(0.95, 1.0), 2); row("  without the floor", 1000 * 0.95, 2)
print("payoff: principal at final ratio 0.90 to 1.40, step 0.05")
print(" ".join(f"{1000 * max(0.90 + 0.05 * k, 1.0):.2f}" for k in range(11)))
print("price curve: real clean per 100 at yield -1.0% to 3.0%, step 0.5%")
print(" ".join(f"{price_closed(C, -0.01 + 0.005 * k, n, r, s)[0]:.2f}" for k in range(9)))
