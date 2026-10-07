# Swap DV01 and hedging -- the check behind the card.  Standard library only.
# The curve is rebuilt from its quotes by the bootstrap written out below;
# DV01 is reached by bumping and rebuilding, and separately by carrying the
# exact slope through the same bootstrap.  Nothing imported knows a swap.
from math import exp

QUOTES = [0.042, 0.044, 0.0455, 0.0462, 0.0465,      # the house curve, years 1 to 5
          0.0467, 0.0468, 0.0469, 0.0470, 0.0471]    # years 6 to 10, extended at its last forward
N, K, BP = 10_000_000.0, 0.045, 0.0001               # notional, fixed rate, one basis point

def boot(q):                                         # D(n) = (1 - S_n * sum of earlier D) / (1 + S_n)
    D, B = [], 0.0
    for s in q:
        d = (1.0 - s * B) / (1.0 + s)
        D.append(d); B += d
    return D

def boot_slope(q):                                   # the same recursion, carrying dD/dshift alongside
    D, dD, B, dB = [], [], 0.0, 0.0
    for s in q:
        d = (1.0 - s * B) / (1.0 + s)
        dd = (-(B + s * dB) * (1.0 + s) - (1.0 - s * B)) / (1.0 + s) ** 2
        D.append(d); dD.append(dd); B += d; dB += dd
    return D, dD

def payer(D, k, n, notional):                        # receive floating, pay k; floating as a strip of forwards
    prev, flt, fix = 1.0, 0.0, 0.0
    for i in range(n):
        flt += (prev / D[i] - 1.0) * D[i]           # forward rate for year i+1, paid then, discounted
        fix += k * D[i]
        prev = D[i]
    return notional * (flt - fix)

def value(q, k, n, notional, shift=0.0):
    return payer(boot([x + shift for x in q]), k, n, notional)

def dv01(q, k, n, notional, h=BP):                   # bump every quote up and down, rebuild, reprice
    return (value(q, k, n, notional, h) - value(q, k, n, notional, -h)) / (2.0 * h) * BP

D = boot(QUOTES)
A5, A10 = sum(D[:5]), sum(D)
par5, par10 = (1.0 - D[4]) / A5, (1.0 - D[9]) / A10
print("the house curve: par quotes with annual coupons, bootstrapped")
for i, (q, d) in enumerate(zip(QUOTES, D)):
    print(f"  year {i + 1:>2}   quote {100 * q:6.4f} %   D = {d:.8f}")
print(f"5-year annuity A5 {A5:>22.6f}    par rate {100 * par5:.4f} %")
print(f"10-year annuity A10 {A10:>20.6f}    par rate {100 * par10:.4f} %")

V5 = payer(D, K, 5, N)
flt_strip = V5 + N * K * A5
print("\nthe 5-year swap: pay 4.5% fixed on 10,000,000, receive floating")
print(f"  floating leg, strip of forwards {flt_strip:>16,.2f}")
print(f"  floating leg, N (1 - D(5))      {N * (1.0 - D[4]):>16,.2f}")
print(f"  fixed leg, N K A5               {N * K * A5:>16,.2f}")
print(f"  value to the payer              {V5:>16,.2f}")

dv_bump = dv01(QUOTES, K, 5, N)
Ds, dD = boot_slope(QUOTES)
dv_exact = N * (-dD[4] - K * sum(dD[:5])) * BP
pv01 = N * A5 * BP
dv_par = dv01(QUOTES, par5, 5, N)
print("\nDV01 of the 5-year payer, dollars per basis point")
print(f"  1 bump every quote, rebuild     {dv_bump:>16,.2f}")
print(f"  2 exact slope through bootstrap {dv_exact:>16,.2f}")
print(f"  PV01 shortcut N A5 x 0.0001     {pv01:>16,.2f}")
print(f"  gap, PV01 minus DV01            {pv01 - dv_bump:>16,.2f}")
print(f"  same swap struck at par 4.65%   {dv_par:>16,.2f}")

dv10_unit = dv01(QUOTES, par10, 10, 1.0)
hedge = dv_bump / dv10_unit
print("\nhedge: receive fixed on a 10-year swap at its par rate, 4.71%")
print(f"  10-year DV01 per million        {1e6 * dv10_unit:>16,.2f}")
print(f"  hedge notional                  {hedge:>16,.2f}")
print(f"  net DV01 of the pair            {dv_bump - hedge * dv10_unit:>16,.2f}")

def book(shifts, n5=N, n10=None):                    # P&L of 5y payer and 10y receiver after the quotes move
    n10 = hedge if n10 is None else n10
    q = [x + s for x, s in zip(QUOTES, shifts)]
    p5 = value(q, K, 5, n5) - V5
    p10 = -(value(q, par10, 10, n10) - value(QUOTES, par10, 10, n10))
    return p5, p10

moves = [-100, -75, -50, -25, 0, 25, 50, 75, 100]
pl = [book([m * BP] * 10) for m in moves]
print("\nparallel moves, P&L in thousands of dollars")
print("chart, move bp  " + " ".join(f"{m:>8d}" for m in moves))
print("chart, unhedged " + " ".join(f"{p5 / 1e3:>8.2f}" for p5, _ in pl))
print("chart, hedged   " + " ".join(f"{(p5 + p10) / 1e3:>8.2f}" for p5, p10 in pl))

tw5, tw10 = book([0.0] * 5 + [j * 2 * BP for j in range(1, 6)])
print(f"\nsteepener, years 6-10 up 2,4,6,8,10 bp: 5y {tw5:,.2f}  hedge {tw10:,.2f}  net {tw5 + tw10:,.2f}")

print("\nwhat breaks, net DV01 or DV01 in dollars per basis point")
print(f"  hedge with 10,000,000 of the 10-year  {dv_bump - N * dv10_unit:>12,.2f}")
print(f"  pay fixed on the 10-year instead      {dv_bump + hedge * dv10_unit:>12,.2f}")
zb = lambda h: payer([d * exp(-h * (i + 1)) for i, d in enumerate(D)], K, 5, N)
print(f"  bump zero rates, not the quotes       {(zb(BP) - zb(-BP)) / 2.0:>12,.2f}")

print("\na year at a time, quotes unchanged: DV01 of each leg and of the pair")
for j in range(5):
    a = dv01(QUOTES, K, 5 - j, N)
    b = hedge * dv01(QUOTES, par10, 10 - j, 1.0)
    print(f"  at time {j}   5y leg {a:>9,.2f}   hedge {b:>9,.2f}   net {a - b:>9,.2f}")

print("\ntry: hedge with the 7-year at par instead  "
      f"{dv_bump / dv01(QUOTES, (1.0 - D[6]) / sum(D[:7]), 7, 1.0):,.2f}")
print(f"try: bump by 10 bp and divide by 10        {dv01(QUOTES, K, 5, N, 10 * BP):,.2f}")

assert abs(D[4] - 0.79621728) < 5e-9,               "D(5) must match the bootstrapping card"
assert abs(par5 - QUOTES[4]) < 1e-12,               "the curve must reprice its own 5-year quote"
assert abs(flt_strip - N * (1.0 - D[4])) < 1e-6,    "strip of forwards vs N(1 - D(5))"
assert abs(dv_bump - dv_exact) < 0.01,              "bump road vs exact-slope road"
assert abs(dv_par - pv01) < 0.01,                   "at par, DV01 must equal N A5 x 1bp"
assert abs(sum(pl[5])) < 0.01 * abs(pl[5][0]),      "hedge must cut a 25bp parallel move by 99%"
print("ALL CHECKS PASS")
