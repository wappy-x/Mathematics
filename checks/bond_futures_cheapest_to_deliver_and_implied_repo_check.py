# Treasury bond futures: conversion factors, the cheapest to deliver, the implied
# repo rate and the switch option -- the check behind the card.  Standard library only.
# Three bonds deliverable on 15 June 2027 (a coupon date for all three); today is
# 15 March 2027, a quarter of a year earlier.  Flat curve at 5%, repo 4.50%.
# Roads: conversion factor by summing cash flows and by the closed form; cash price
# today two ways; implied repo by formula and by bisection on the net basis; cheapest
# by implied repo and by net basis; the 6% crossing by bisection on closed-form prices;
# switch option by quadrature and by simulation; futures DV01 by formula and by bumping.
from math import exp, log, sqrt, cos, pi

BONDS = [("4% 10-year", 4.0, 20), ("5% 15-year", 5.0, 30), ("6.5% 25-year", 6.5, 50)]
Y, REPO, T, F = 0.05, 0.045, 0.25, 108 + 4 / 32   # yield, repo, years to delivery, quote 108-04

def price_sum(c, n, y):            # clean price per 100 face on a coupon date: add every payment
    v, p = 1 / (1 + y / 2), 0.0
    for k in range(1, n + 1): p += c / 2 * v ** k
    return p + 100 * v ** n

def price_closed(c, n, y):         # the same price by the annuity closed form
    v = 1 / (1 + y / 2)
    return c / 2 * (1 - v ** n) / (y / 2) + 100 * v ** n

def dv01(c, n, y):                 # price fall for one basis point, from the derivative
    v, d = 1 / (1 + y / 2), 0.0
    for k in range(1, n + 1): d += k * (c / 2) * v ** (k + 1)
    return (d + n * 100 * v ** (n + 1)) / 2 / 10000

def bisect(g, lo, hi):             # the root of g between lo and hi, by halving
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (g(lo) > 0) == (g(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

cf = [price_sum(c, n, 0.06) / 100 for _, c, n in BONDS]
cf_closed = [price_closed(c, n, 0.06) / 100 for _, c, n in BONDS]
print("bond                    " + "".join(f"{b[0]:>14}" for b in BONDS))
def row(name, xs, fmt="{:14.6f}"): print(f"{name:<24}" + "".join(fmt.format(x) for x in xs))
row("CF, payments added", cf)
row("CF, closed form", cf_closed)
row("CF, exchange, 4 decimals", cf, "{:14.4f}")
dirty, ai0, coup, nb, irr, irr_b, gross, carry = [], [], [], [], [], [], [], []
for i, (_, c, n) in enumerate(BONDS):
    at_delivery = price_sum(c, n, Y) + c / 2          # value on 15 June, coupon included
    dirty.append(at_delivery / (1 + Y / 2) ** 0.5)    # discounted back half a coupon period
    ai0.append(c / 4); coup.append(c / 2)             # accrued today; coupon paid on 15 June
    clean = dirty[i] - ai0[i]
    gross.append(clean - F * cf[i])
    carry.append(coup[i] - ai0[i] - dirty[i] * REPO * T)    # accrued at delivery is zero
    nb.append(gross[i] - carry[i])
    irr.append(((F * cf[i] + coup[i]) / dirty[i] - 1) / T)
    irr_b.append(bisect(lambda r: dirty[i] * (1 + r * T) - coup[i] - F * cf[i], -1.0, 1.0))
dirty_flows = [sum((c / 2 + 100 * (k == n)) / (1 + Y / 2) ** (k + 0.5) for k in range(n + 1))
               for _, c, n in BONDS]              # road 2: each payment discounted for its own time
row("clean price today", [d - a for d, a in zip(dirty, ai0)], "{:14.4f}")
row("accrued today", ai0, "{:14.4f}")
row("cash paid today", dirty, "{:14.4f}")
row("invoice at 108-04", [F * x for x in cf], "{:14.4f}")
row("coupon on 15 June", coup, "{:14.4f}")
row("gross basis", gross, "{:14.4f}")
row("carry to delivery", carry, "{:14.4f}")
row("net basis", nb, "{:14.4f}")
row("net basis, identity", [d * T * (REPO - r) for d, r in zip(dirty, irr)], "{:14.4f}")
row("implied repo, formula %", [100 * r for r in irr], "{:14.4f}")
row("implied repo, bisect %", [100 * r for r in irr_b], "{:14.4f}")
row("forward price / CF", [(d * (1 + REPO * T) - k) / x for d, k, x in zip(dirty, coup, cf)], "{:14.4f}")
ctd_r = max(range(3), key=lambda i: irr[i]); ctd_b = min(range(3), key=lambda i: nb[i])
print(f"cheapest by implied repo: {BONDS[ctd_r][0]};  by net basis: {BONDS[ctd_b][0]}")

def ratios(y): return [price_sum(c, n, y) / cf[i] for i, (_, c, n) in enumerate(BONDS)]
print("\ndelivery yield %   price/CF:  10-year  15-year  25-year   cheapest")
for k in range(9):
    yd = 0.03 + 0.005 * k
    q = ratios(yd)
    name = "all equal" if max(q) - min(q) < 1e-9 else BONDS[q.index(min(q))][0]
    print(f"{100 * yd:13.1f} {'':10}" + "".join(f"{x:9.2f}" for x in q) + f"   {name}")
ystar = bisect(lambda y: price_closed(4.0, 20, y) / cf[0] - price_closed(6.5, 50, y) / cf[2], 0.03, 0.09)
print(f"10-year and 25-year lines cross at {100 * ystar:.6f}% (closed-form prices, bisection)")

# ---- switch option: delivery yield 5% + a normal move with standard deviation SD ----
def option_quad(sd, m=4000):       # midpoint rule over the normal density
    lo, w = -8 * sd, 16 * sd / m
    ev, emin, pswitch = [0.0] * 3, 0.0, 0.0
    for j in range(m):
        d = lo + (j + 0.5) * w
        p = exp(-d * d / (2 * sd * sd)) / (sd * sqrt(2 * pi)) * w
        q = ratios(Y + d)
        ev = [e + p * x for e, x in zip(ev, q)]; emin += p * min(q)
        pswitch += p * (min(q) < q[0])
    return min(ev) - emin, min(ev), emin, pswitch, ev.index(min(ev))

def option_sim(sd, paths=100000):  # same value by simulation: own generator, Box-Muller
    s, tot, tot2, sw = 88172645463325252, 0.0, 0.0, 0
    def u():
        nonlocal s
        s = (6364136223846793005 * s + 1442695040888963407) % 2 ** 64
        return ((s >> 11) + 0.5) / 2 ** 53
    for _ in range(paths):
        d = sd * sqrt(-2 * log(u())) * cos(2 * pi * u())
        q = ratios(Y + d)
        g = q[0] - min(q)          # what switching away from the 10-year saves on this path
        tot += g; tot2 += g * g; sw += g > 0
    mean = tot / paths
    return mean, sqrt((tot2 / paths - mean * mean) / paths), sw / paths

val, best_mean, mean_min, psw, best = option_quad(0.005)
sim, se, psw_sim = option_sim(0.005)
print(f"\nswitch option, move SD 50 bp: quadrature {val:.4f}, simulation {sim:.4f} (+/- {se:.4f})")
print(f"  lowest average price/CF {best_mean:.4f} ({BONDS[best][0]}), average of cheapest {mean_min:.4f}")
print(f"  net basis of the 10-year in futures points: {nb[0] / cf[0]:.4f}")
print(f"  chance the cheapest switches: quadrature {100 * psw:.2f}%, simulation {100 * psw_sim:.2f}%")
print(f"  move SD 75 bp: {option_quad(0.0075)[0]:.4f};  SD 100 bp: {option_quad(0.01)[0]:.4f}")

d_ctd = dv01(4.0, 20, Y)
bump = (min(ratios(Y - 0.0001)) - min(ratios(Y + 0.0001))) / 2
print(f"\nCTD DV01 per 100 at 5%: {d_ctd:.6f};  / CF = {d_ctd / cf[0]:.6f};  bumped futures {bump:.6f}")
print(f"futures DV01 per 100,000 contract: {1000 * d_ctd / cf[0]:.2f} dollars")
print(f"try: quote 107-04, implied repo of the 10-year {100 * ((107.125 * cf[0] + 2) / dirty[0] - 1) / T:.4f}%")
print(f"try: repo 5.50%, net basis of the 10-year {dirty[0] * T * (0.055 - irr[0]):.4f}")

print("\nwrong: cheapest by lowest price at 6.5%: " + BONDS[min(range(3), key=lambda i:
      price_sum(BONDS[i][1], BONDS[i][2], 0.065))][0])
print(f"wrong: implied repo without the coupon {100 * ((F * cf[0]) / dirty[0] - 1) / T:.4f}%")
print(f"wrong: implied repo on the clean price {100 * ((F * cf[0] + 2) / (dirty[0] - 1) - 1) / T:.4f}%")
print(f"wrong: futures DV01 = CTD DV01 {d_ctd:.6f}")

assert all(abs(a - b) < 1e-12 for a, b in zip(cf, cf_closed)), "two roads to each CF"
assert all(abs(a - b) < 1e-10 for a, b in zip(irr, irr_b)), "implied repo: formula = bisection"
assert all(abs(g - k - d * T * (REPO - r)) < 1e-10 for g, k, d, r in zip(gross, carry, dirty, irr))
assert ctd_r == ctd_b == 0, "highest implied repo and lowest net basis pick the same bond"
assert all(abs(a - b) < 1e-9 for a, b in zip(dirty, dirty_flows)), "cash price today: two roads"
assert [round(x, 6) for x in cf] == [0.851225, 0.901998, 1.064324], "the factors quoted on the card"
assert abs(ystar - 0.06) < 1e-9 and all(abs(price_closed(c, n, ystar) / cf[i] - 100) < 1e-7
                                        for i, (_, c, n) in enumerate(BONDS)), "all three tie at 6%"
assert ratios(0.065).index(min(ratios(0.065))) == 2, "+150 bp switches to the 25-year"
assert best == 0 and abs(sim - val) < 4 * se, "simulation agrees with quadrature"
assert abs(psw - 0.02275) < 1e-3, "switch beyond +100 bp: two SDs, 2.28%"
assert abs(bump - d_ctd / cf[0]) < 1e-6, "futures DV01 = CTD DV01 / CF"
print("ALL CHECKS PASS")
