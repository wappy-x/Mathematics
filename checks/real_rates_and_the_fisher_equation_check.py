# Real rates and the Fisher equation -- the check behind the card.
# Standard library only.  Every number quoted on the card is printed here.
# The real rate is reached four ways: dividing growth factors, counting
# baskets, a bisection root finder that never divides, and log rates.
from math import log, exp

I, PI = 0.045, 0.025            # nominal rate and inflation, one year
DEPOSIT, BASKET = 1000.0, 100.0  # dollars deposited; a basket's price today

def real(i, p):                  # road 1: the exact Fisher relation
    return (1.0 + i) / (1.0 + p) - 1.0

def by_baskets(i, p):            # road 2: count what the money buys, before and after
    before = DEPOSIT / BASKET
    after = DEPOSIT * (1.0 + i) / (BASKET * (1.0 + p))
    return before, after, after / before - 1.0

def by_bisection(i, p):          # road 3: find r with (1 + r)(1 + p) = 1 + i, no division
    lo, hi = -0.99, 1.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (1.0 + mid) * (1.0 + p) - (1.0 + i) > 0.0: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)

def by_logs(i, p):               # road 4: continuous rates subtract exactly
    ic, pc = log(1.0 + i), log(1.0 + p)
    return ic, pc, ic - pc, exp(ic - pc) - 1.0

r = real(I, PI)
b0, b1, r_b = by_baskets(I, PI)
r_bis = by_bisection(I, PI)
ic, pc, rc, r_log = by_logs(I, PI)
approx = I - PI
gap_formula = (I - PI) * PI / (1.0 + PI)   # the approximation's error, written independently

rows = [
    ("baskets bought today", b0), ("basket price in a year", BASKET * (1.0 + PI)),
    ("dollars in a year", DEPOSIT * (1.0 + I)), ("baskets bought in a year", b1),
    ("1 exact (1+i)/(1+pi) - 1", r), ("2 baskets after/before - 1", r_b),
    ("3 bisection, no division", r_bis),
    ("4a continuous nominal ln(1+i)", ic), ("4b continuous inflation ln(1+pi)", pc),
    ("4c continuous real, the difference", rc), ("4  back to yearly, e^diff - 1", r_log),
    ("approximation i - pi", approx), ("approximation minus exact", approx - r),
    ("  (i - pi) pi / (1 + pi)", gap_formula),
]
for name, v in rows:
    print(f"{name:<38} {v:>13.9f}")

# ---- ten years: the deposit in dollars and in today's dollars ----
print()
print("year   dollars  today's-dollars  approx-2%")
grow = 1.0; prices = 1.0; money = DEPOSIT; approx_path = DEPOSIT
for year in range(11):
    if year > 0:
        money *= 1.0 + I; prices *= 1.0 + PI; approx_path *= 1.0 + approx; grow *= 1.0 + r
    if year % 2 == 0:
        print(f"{year:>4} {money:>9.2f} {money / prices:>16.2f} {approx_path:>10.2f}")
baskets10 = money / (BASKET * prices)
print(f"{'baskets after ten years':<38} {baskets10:>13.6f}")
print(f"{'price index after ten years':<38} {prices:>13.6f}")

# ---- the same 2-point gap as inflation rises: exact against approximate ----
print()
print("inflation%  nominal%  exact-real%  approx-real%")
for p in (0.0, 0.025, 0.05, 0.10, 0.20, 0.50, 1.00):
    print(f"{100 * p:>10.1f} {100 * (p + 0.02):>9.1f} {100 * real(p + 0.02, p):>12.2f} {100 * 0.02:>13.2f}")

# ---- nominal locked at 4.5 percent; the inflation that actually arrived ----
print()
print("realised inflation%  realised real%")
for p in (0.0, 0.01, 0.02, 0.025, 0.03, 0.04, 0.05):
    print(f"{100 * p:>19.1f} {100 * real(I, p):>15.2f}")

# ---- what breaks, taxes, the shelf's bond, try changing ----
print()
T = 0.30
extra = [
    ("wrong: multiply, (1+i)(1+pi) - 1", (1.0 + I) * (1.0 + PI) - 1.0),
    ("wrong: approx, 110% nominal 100% infl", 1.10 - 1.00),
    ("  exact, 110% nominal 100% inflation", real(1.10, 1.00)),
    ("wrong: approx compounded, baskets", DEPOSIT * (1.0 + approx) ** 10 / BASKET),
    ("tax 30%: nominal after tax", I * (1.0 - T)),
    ("tax 30%: real after tax", real(I * (1.0 - T), PI)),
    ("wrong: tax charged on the real rate", r * (1.0 - T)),
    ("shelf bond: real 1%, breakeven 2.5%", 1.01 * 1.025 - 1.0),
    ("try: inflation 4.5%", real(I, 0.045)),
    ("try: inflation 10%", real(I, 0.10)),
    ("try: nominal 10%", real(0.10, PI)),
]
for name, v in extra:
    print(f"{name:<38} {v:>13.9f}")

assert abs(r_bis - r) < 1e-12,                  "bisection (no division) must land on the ratio"
assert abs(r_log - r) < 1e-12,                  "log road must land on the ratio"
assert abs(r_b - r) < 1e-12,                    "basket count must land on the ratio"
assert abs((approx - r) - gap_formula) < 1e-15, "approximation error is (i - pi) pi / (1 + pi)"
assert abs(baskets10 - 10.0 * grow) < 1e-9,     "ten years of baskets vs real growth compounded"
assert abs(r - 2.0 / 102.5) < 1e-15,            "hand value: 2 dollars gained on a 102.50 basket"
assert abs((approx - r) - r * PI) < 1e-15,      "the dropped term is exactly r times pi"
assert abs(real(1.01 * 1.025 - 1.0, 0.025) - 0.01) < 1e-15, "shelf bond: back to 1 percent real"
assert abs(real(1.10, 1.00) - (1.10 - 1.00) / 2.0) < 1e-15, "100% inflation: exact is half the shortcut"
print("ALL CHECKS PASS")
