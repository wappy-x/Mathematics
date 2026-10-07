# Money markets -- the check behind the card.  Standard library only, and
# nothing imported that already holds an answer: each yield is found twice,
# once in closed form and once by a bisection root finder written out here,
# and the compounded overnight factor is built three separate ways.
# The bill: face 1,000,000 dollars, 91 days left, quoted at a 4.9 percent
# discount, actual/360.  The overnight path: 13 weeks of business-day blocks,
# invented but market-shaped -- 5.05 percent for six weeks, a quarter-point
# cut from day 42, and a 20 basis point quarter-end squeeze on day 87.
from math import log, exp

F, DAYS, DQ, N = 1_000_000.0, 91, 0.049, 1_000_000.0

def bisect(f, lo, hi):                       # our own root finder: 200 halvings
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(lo) * f(mid) <= 0.0: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)

def blocks_of(cut_day):                      # the business-day blocks, in order
    out = []
    for w in range(13):
        for k in range(5):
            start, days = 7 * w + k, (3 if k == 4 else 1)   # Friday carries 3 days
            r = 0.0505 if start < cut_day else 0.0480
            if start == 87: r += 0.0020                     # quarter-end squeeze
            out.append((start, days, r))
    return out

def grow(bl):                                # road 1: multiply the block factors
    g = 1.0
    for _, days, r in bl: g *= 1.0 + r * days / 360.0
    return g

def grow_by_logs(bl):                        # road 2: add logs, then undo them
    s = 0.0
    for _, days, r in bl: s += log(1.0 + r * days / 360.0)
    return exp(s)

def grow_each_day(bl):                       # the weekend mistake: compound Sat and Sun
    g = 1.0
    for _, days, r in bl: g *= (1.0 + r / 360.0) ** days
    return g

def rate_from(g, days): return (g - 1.0) * 360.0 / days      # simple, actual/360

def money(name, v): print(f"{name:<46}{v:>16.2f}")
def pct(name, v):   print(f"{name:<46}{100.0 * v:>15.4f}%")
def fac(name, v):   print(f"{name:<46}{v:>16.10f}")

P = F * (1.0 - DQ * DAYS / 360.0)                            # the quoting rule
i_mm = (F - P) / P * 360.0 / DAYS                            # road 1
i_bs = bisect(lambda i: P * (1.0 + i * DAYS / 360.0) - F, -0.5, 0.5)   # road 2
y_bey = i_mm * 365.0 / 360.0
ear = (F / P) ** (365.0 / DAYS) - 1.0
ear_bs = bisect(lambda e: (1.0 + e) ** (DAYS / 365.0) - F / P, -0.5, 0.5)

bl = blocks_of(42)
G, G_log = grow(bl), grow_by_logs(bl)
s1 = sum(r * d / 360.0 for _, d, r in bl)                    # the plain sum
s2 = sum((r * d / 360.0) ** 2 for _, d, r in bl)
G_2nd = 1.0 + s1 + 0.5 * (s1 * s1 - s2)                      # road 3
R_c = rate_from(G, DAYS)
r_bar = sum(r * d for _, d, r in bl) / DAYS
j0 = 1.00000000
j42, j91 = j0 * grow(bl[:30]), j0 * G

print("THE BILL: face 1,000,000 dollars, 91 days, quoted at a 4.9 percent discount")
money("price paid, actual/360 discount rule", P)
money("price times 36, a whole number by hand", P * 36.0)
money("discount, face minus price", F - P)
pct("1 money-market yield, closed form", i_mm)
pct("2 money-market yield, by bisection", i_bs)
pct("bond-equivalent yield, actual/365", y_bey)
pct("3 effective annual rate, closed form", ear)
pct("4 effective annual rate, by bisection", ear_bs)

print()
print("THE OVERNIGHT PATH: 13 weeks, 65 blocks, 91 calendar days")
print(f"{'blocks: one-day, three-day, calendar days':<46}"
      f"{sum(1 for _, d, _ in bl if d == 1):>6}{sum(1 for _, d, _ in bl if d == 3):>5}"
      f"{sum(d for _, d, _ in bl):>5}")
fac("one-day block at 5.05 percent", 1.0 + 0.0505 / 360.0)
fac("Friday block, three days at 5.05 percent", 1.0 + 0.0505 * 3.0 / 360.0)
fac("1 compounded factor, block by block", G)
fac("2 compounded factor, from logs", G_log)
fac("3 compounded factor, two-term expansion", G_2nd)
pct("compounded in arrears, actual/360", R_c)
pct("weighted average of the daily rates", r_bar)
money("interest on 1,000,000, compounded", N * (G - 1.0))
money("interest on 1,000,000, at the average", N * s1)
print(f"{'index levels, day 0, day 42, day 91':<46}{j0:>16.8f}{j42:>14.8f}{j91:>14.8f}")
fac("factor from the two index levels", j91 / j0)

print()
print("WHAT THE MISTAKES COST, per 1,000,000 of the same 91 days")
money("quote read as the return: interest short by", (F - P) - P * DQ * DAYS / 360.0)
money("actual/365 in the price rule: overpaid by", F * (1.0 - DQ * DAYS / 365.0) - P)
money("average instead of compounding: short by", N * (G - 1.0 - s1))
money("weekends compounded, not one block: over by", N * (grow_each_day(bl) - G))

print()
print("THE SAME 91 DAYS, FOUR WAYS OF QUOTING IT")
pct("discount quote on the face", DQ)
pct("compounded overnight, in arrears", R_c)
pct("money-market yield on the cash", i_mm)
pct("bond-equivalent yield", y_bey)

print()
weeks = list(range(1, 14))
g_w = [grow(bl[:5 * w]) for w in weeks]
print(f"{'week':<24}" + "".join(f"{w:>9d}" for w in weeks))
print(f"{'overnight rate, Thursday':<24}" + "".join(f"{100.0 * bl[5 * (w - 1) + 3][2]:>9.2f}" for w in weeks))
print(f"{'interest by week end':<24}" + "".join(f"{N * (g - 1.0):>9.2f}" for g in g_w))
print(f"{'running rate in arrears':<24}" + "".join(f"{100.0 * rate_from(g, 7 * w):>9.2f}" for g, w in zip(g_w, weeks)))

print()
ds = [0.01 * k for k in range(11)]
print(f"{'chart, discount quote, percent':<34}" + "".join(f"{100.0 * d:>7.2f}" for d in ds))
print(f"{'chart, money-market yield, percent':<34}"
      + "".join(f"{100.0 * d / (1.0 - d * DAYS / 360.0):>7.2f}" for d in ds))

print()
print("COMPOUNDING GAIN per 1,000,000, flat 5 percent compounded every day")
for n in (30, 91, 182, 365):
    money(f"  over {n} days", N * ((1.0 + 0.05 / 360.0) ** n - (1.0 + 0.05 * n / 360.0)))

assert abs(P * 36.0 - 35554100.0) < 1e-6      # against the hand arithmetic
assert abs(i_bs - i_mm) < 1e-12               # root finder against closed form
assert abs(ear_bs - ear) < 1e-10              # root finder against the power
assert abs(G_log - G) < 1e-12                 # logs against multiplication
assert abs(G_2nd - G) < 5e-7                  # expansion against the product
assert i_mm > DQ + 1e-4                       # the return beats the quote
assert R_c > r_bar + 1e-5                     # compounding beats the average
print("ALL CHECKS PASS")
