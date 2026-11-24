# Treasury bond futures: conversion factors, the cheapest bond to deliver, the implied repo rate, and the switch option

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Curves in Depth](../README.md#s33) → Treasury bond futures

---

## General Overview

A pension fund sells one Treasury bond futures contract at 108-04, which means 108 and 4/32, or 108.125 per 100 of face. On 15 June 2027 it must hand over \$100,000 face of a government bond. The contract does not name one bond. It lists a **basket**: here, a 4% bond with 10 years left, a 5% bond with 15 years left and a 6.5% bond with 25 years left. The seller (the **short**) picks which one to deliver.

Those bonds are worth very different amounts. On a flat 5% yield curve the 4% bond costs about 92, the 6.5% bond about 121. So the exchange scales the futures price by a **conversion factor** for each bond: the price that bond would have, per 1 of face, if every yield were 6%. The buyer pays the futures price times that factor. At a 6% yield, the scaling makes all three bonds equally good to deliver.

Yields are not 6%, so one bond is always cheapest to hand over: the **cheapest to deliver**, or CTD. Here it is the 4% 10-year. A trader finds it by asking one question of each bond: if I pay cash for it today and deliver it into the contract, what interest rate has that cash earned? That rate is the **implied repo rate**. A **repo** (repurchase agreement) is a short loan backed by a bond, and its rate is what borrowing against the bond costs. The implied repo rate is the highest repo rate at which buying the bond with borrowed money still breaks even. For the 10-year it is 4.2526% a year. The other two bonds lose money, at −4.7955% and −15.1673% a year.

The answer can change. If yields rise 150 basis points (a basis point, bp, is a hundredth of a percent) to 6.5% by delivery, the 25-year becomes cheapest. That choice belongs to the short, and the buyer pays for it: the futures price sits a little below where it would be with only one bond in the basket. The choice is the **switch option**.

**A Treasury bond futures price, times a bond's conversion factor, is what the buyer pays for that bond; the short delivers whichever bond is cheapest after that scaling, the bond with the highest implied repo rate, and which bond that is depends on how far yields sit from 6%.**

**What kind of fact this is:** a convention (the exchange's 6% conversion factor) plus theorems proved on this card: the implied repo and net-basis identity, the 6% crossing point, and the rule that a choice of bonds can only lower the futures price. The switch option's size comes from a model of yield moves, not a law.

### The picture: each bond's price divided by its factor, as the delivery-day yield moves

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Price per unit of conversion factor on delivery day, by flat yield"
    x-axis "Flat yield on delivery day (%)" [3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0]
    y-axis "Price / conversion factor" 85 --> 155
    line [127.56, 122.40, 117.48, 112.79, 108.32, 104.06, 100.00, 96.13, 92.43]
    line [137.49, 130.14, 123.28, 116.86, 110.87, 105.25, 100.00, 95.08, 90.47]
    line [151.50, 140.66, 130.86, 121.99, 113.94, 106.64, 100.00, 93.96, 88.45]
```

Orange: the 4% 10-year. Green: the 5% 15-year. Dark: the 6.5% 25-year. All three lines pass through 100 at 6%. Below 6% the 10-year is lowest, so it is cheapest to deliver. Above 6% the 25-year is lowest. On delivery day the futures price is the lowest of the three lines.

---

## The formula

Notation first, in words. Bond $`i`$ pays a coupon of $`c`$ percent of face a year, in two halves, and has $`n`$ half-years left on delivery day. Prices are per 100 of face. The **clean price** $`P_0`$ is the quoted price; the buyer also pays **accrued interest** $`AI_0`$, the part of the next coupon already earned by the seller ([Bond price and yield](../01-Money%2C%20Dates%20and%20Discounting/05-bonds-price-and-yield.md)). Clean price plus accrued is the cash paid.

The conversion factor is the bond's price at a 6% yield, compounded twice a year, per 1 of face:

```math
CF_i = \frac{1}{100}\left(\frac{c}{2}\sum_{k=1}^{n} 1.03^{-k} + 100 \times 1.03^{-n}\right)
```

**Read it aloud:** discount every half-year coupon and the face at 3% a half-year, add them, and divide by 100.

The **invoice price** is what the buyer pays for the bond delivered, with $`AI_D`$ the accrued interest on delivery day:

```math
\text{invoice}_i = F \times CF_i + AI_D
```

The **implied repo rate** is the simple interest rate earned by buying the bond today and delivering it. A **repo** is a loan against a bond as collateral ([Money markets](../02-Curves/03-money-market-instruments-and-sofr.md)). Here $`C`$ is the coupon cash received before delivery and $`t`$ the years to delivery:

```math
r_{\mathrm{imp},i} = \left(\frac{F\,CF_i + AI_D + C}{P_0 + AI_0} - 1\right)\frac{1}{t}
```

**Read it aloud:** the cash that comes back at delivery, divided by the cash paid today, less one, put on a yearly basis.

The **net basis** is how much more the bond costs to buy and carry to delivery than the invoice pays for it, at the market repo rate $`r`$:

```math
NB_i = \underbrace{P_0 - F\,CF_i}_{\text{gross basis}} - \underbrace{\left(C + AI_D - AI_0 - (P_0 + AI_0)\,r\,t\right)}_{\text{carry}} = (P_0 + AI_0)\,t\,\bigl(r - r_{\mathrm{imp},i}\bigr)
```

**Read it aloud:** the price gap to the invoice, less what the bond earns over its financing cost, equals the cash paid times the time times the gap between the repo rate and the implied repo rate.

The cheapest to deliver has the highest implied repo rate and, here, the lowest net basis. The futures contract's sensitivity follows the CTD's:

```math
\text{futures DV01} \approx \frac{\text{DV01}_{\text{CTD}}}{CF_{\text{CTD}}}
```

A **DV01** (dollar value of one basis point) is the price fall for a 1 bp rise in yield ([Duration and convexity](../01-Money%2C%20Dates%20and%20Discounting/06-duration-and-convexity.md)).

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`F`$ | futures price, per 100 of face | 108-04 = 108.125 | every invoice rises; every implied repo rises |
| $`CF_i`$ | conversion factor: the bond's price at 6%, per 1 of face | 0.851225, 0.901998, 1.064324 | that bond earns more for the short |
| $`c`$, $`n`$ | coupon, percent a year; half-years left on delivery day | 4%, 20 for the CTD | a higher coupon raises the factor |
| $`y`$, $`P_i(y)`$ | the flat market yield, compounded twice a year; bond $`i`$'s clean price at that yield on delivery day | 5%; the factor's yield is 6% | above 6%, long bonds become cheapest |
| $`P_0`$, $`AI_0`$, $`AI_D`$ | clean price today; accrued today; accrued on delivery day | 92.0495, 1.0000, 0 | more cash paid lowers the implied repo |
| $`C`$ | coupon cash received before delivery | 2.0000 (paid 15 June) | raises the implied repo |
| $`t`$ | years from today to delivery | 0.25 | spreads the same gain over more time |
| $`r`$ | repo rate: the market's rate for a loan against the bond | 4.50% | raises the net basis, not the implied repo |
| $`r_{\mathrm{imp}}`$ | implied repo rate | 4.2526% for the CTD | — |
| gross basis, carry, $`NB`$ | price minus futures times factor; coupon income less financing; their difference | 0.0108, −0.0468, 0.0576 | — |
| $`\Delta`$, $`\sigma`$, $`X_i`$, $`E[\cdot]`$, $`\min_i`$ | move in the yield by delivery day; its standard deviation (typical size); bond $`i`$'s price per factor on delivery day; the average over all outcomes; the smallest over the bonds | $`\sigma`$ = 50 bp | a bigger $`\sigma`$ makes the switch option worth more |
| DV01, $`D_i`$ | price fall for a 1 bp rise in yield; modified duration, the fractional price fall per unit rise in yield | 0.074264 for the CTD | the futures position needs fewer contracts to hedge |

### When it holds

- **Delivery on a coupon date, months counted as quarters.** Today is 15 March 2027, three months after the last coupon, and delivery is on 15 June. The card takes $`t = 0.25`$ and accrued interest as half a half-year coupon. A desk counts actual days: actual/360 for repo, actual/actual for accrued interest. The numbers move by a few hundredths.
- **A flat yield curve.** All three bonds are priced at one yield, so every line crosses at exactly 6%. On a sloped curve each bond has its own yield and the crossing moves. A steep curve makes long bonds yield more and pushes the switch earlier.
- **One delivery day.** A real contract lets the short deliver on any business day of the delivery month and adds smaller choices (the **timing option**, choosing the day, and the **end-of-month option**, delivering after futures trading stops at a price already fixed). Those are left out; they also lower the futures price a little.
- **Implied repo and net basis agree here.** Implied repo is a return per dollar; net basis is dollars per 100 of face. When two bonds have very different cash prices the two rankings can disagree, and the net basis is the money one contract actually makes.
- **The conventions, as of 2026-11-23.** The exchange measures each bond's remaining life from the first day of the delivery month, rounds it down to whole quarters, and publishes the factor to four decimals (0.8512 here). The bonds here mature on 15 June 2037, 2042 and 2052, so on 1 June 2027 they have just over 10, 15 and 25 years left, rounding to whole years. Real contracts take narrower ranges than this teaching basket, also counted from the first day of the delivery month: the classic Treasury Bond contract takes bonds with at least 15 and under 25 years left, the Ultra Bond contract 25 years or more, and the 10-year note contract 6.5 to 10 years. They deliver in March, June, September and December, on any business day of the month the short chooses.

---

## Why it works

### Step 0: the short chooses, so the buyer must expect the worst bond

The buyer gets whichever bond the short picks, and the short picks the one that costs least to hand over. A futures price is therefore a price for the cheapest bond, not for an average one. The conversion factor tries to make the bonds equal; it only succeeds at one yield.

### Step 1: at 6% every bond is worth exactly its invoice

On delivery day, delivering bond $`i`$ costs its clean price $`P_i(y)`$ and earns $`F \times CF_i`$, plus the same accrued interest on both sides. So the short compares the ratios $`P_i(y)/CF_i`$ and delivers the smallest. By definition $`CF_i = P_i(6\%)/100`$, so

```math
\frac{P_i(6\%)}{CF_i} = 100 \quad \text{for every bond.}
```

At 6% the three bonds tie. The picture's lines all pass through 100 there.

### Step 2: away from 6%, duration decides the winner

The ratio is $`100 \times P_i(y)/P_i(6\%)`$: how much the bond's price has grown since a 6% yield. Duration says a price moves by about its modified duration $`D_i`$ for each unit of yield, so

```math
\ln\frac{P_i(y)}{CF_i} \approx \ln 100 + D_i\,(6\% - y).
```

When $`y`$ is below 6%, the right side grows fastest for the longest-duration bond. The 25-year's ratio climbs most, so it is the most expensive to deliver, and the 10-year is cheapest. When $`y`$ is above 6% the sign flips: the 25-year's ratio falls most, and it becomes cheapest. This is a first-order argument; convexity bends the lines but does not move the crossing, which is exact at 6%. The grid below checks it from 3% to 7%, and the code finds the crossing at 6.000000% by bisection on the closed-form prices.

A shortcut traders use: high yields favour long, low-coupon bonds; low yields favour short, high-coupon bonds. In this basket the low-coupon bond is also the short one, so duration is the cleaner rule.

### Step 3: buy, borrow, deliver: the implied repo rate

Before delivery, a trader can lock in a return with three trades: buy the bond today for $`P_0 + AI_0`$, sell one futures contract, and deliver the bond on 15 June. The cash out today is fixed. The cash in on 15 June is fixed too: the invoice $`F\,CF_i + AI_D`$ plus the coupon $`C`$. The rate that links them is the implied repo rate: the formula above is just "cash in over cash out, less one, per year".

Compare it with the repo rate, the cost of borrowing against the same bond. If the implied repo rate were above the repo rate, borrowing at 4.50% to earn more would be free money. So in a working market the CTD's implied repo rate sits at or a little below the repo rate.

### Step 4: net basis is the same comparison in dollars

Write the forward price of the bond by cash and carry ([Forward price](../03-Contracts%20and%20No-Arbitrage/03-forward-price-by-cash-and-carry.md)): pay $`P_0 + AI_0`$, grow it at the repo rate, take off the coupon and the accrued interest received. The net basis is that forward price minus the invoice. Rearranging the definitions:

```math
NB = (P_0 + AI_0)(1 + r\,t) - C - AI_D - F\,CF = (P_0 + AI_0)\,t\,(r - r_{\mathrm{imp}}).
```

The last step substitutes $`F\,CF + AI_D + C = (P_0 + AI_0)(1 + r_{\mathrm{imp}}\,t)`$, the implied repo definition. So a positive net basis means an implied repo rate below the repo rate, and the bond with the highest implied repo has the smallest net basis per dollar invested.

### Step 5: a choice can only lower the price

Let $`X_i`$ be bond $`i`$'s price per unit of factor on delivery day, uncertain today. Without a choice, the short would be stuck with one bond, worth on average $`E[X_i]`$ ($`E`$ means the average over all outcomes). With the choice, the short delivers $`\min_i X_i`$. On every outcome $`\min_i X_i \le X_j`$ for each $`j`$, so averaging gives

```math
E\bigl[\min_i X_i\bigr] \le \min_i E[X_i].
```

The gap is the value of the switch option to the short, and the buyer pays for it through a lower futures price. It is zero only if one bond is cheapest in every outcome.

### Step 6: the futures moves like the CTD, divided by its factor

Near delivery, the futures price is about $`P_{\mathrm{CTD}}/CF_{\mathrm{CTD}}`$. Divide both sides of a 1 bp price move by the factor, and the futures DV01 is the CTD's DV01 over its conversion factor. When the CTD switches, the futures DV01 jumps to the new bond's.

---

## Worked numbers, by hand

The CTD, the 4% 10-year, against the quote 108-04. The cash price today is the bond's price at 5% on 15 June, coupon included, discounted back half a half-year at 2.5%.

| Step | Arithmetic | Value |
| --- | --- | --- |
| conversion factor | (2 × the sum of $`1.03^{-k}`$ over 20 half-years + 100 × $`1.03^{-20}`$) / 100 | 0.851225 |
| invoice per 100 | 108.125 × 0.851225 | 92.0387 |
| cash paid today | 92.0495 clean + 1.0000 accrued | 93.0495 |
| cash back on 15 June | 92.0387 invoice + 2.0000 coupon | 94.0387 |
| **implied repo rate** | (94.0387 / 93.0495 − 1) / 0.25 | **4.2526%** |
| gross basis | 92.0495 − 92.0387 | 0.0108 |
| carry to delivery | 2.0000 − 1.0000 − 93.0495 × 0.045 × 0.25 | −0.0468 |
| net basis | 0.0108 − (−0.0468) | 0.0576 |
| net basis, identity | 93.0495 × 0.25 × (4.50% − 4.2526%) | 0.0576 |
| net basis in futures points | 0.0576 / 0.851225 | 0.0676 |

Cash paid for the 10-year today and delivered into the contract earns 4.2526% a year, just under the 4.50% repo rate. So buying it with money borrowed at repo loses a little: the net basis, 0.0576 per 100 of face, under 2/32. That is what the short pays for its choices, and the contract is fairly priced.

The same steps for the other two bonds give implied repo rates of −4.7955% and −15.1673%, and net bases of 2.3527 and 6.0474. Delivering them would lose money, so nobody would.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Cheapest = lowest price, at 6.5% | picks the 4% 10-year | Price must be divided by the factor; the 25-year is cheapest there |
| Implied repo without the coupon | −4.3450% | The 2.0000 coupon paid on 15 June is cash the trade receives |
| Implied repo on the clean price | 8.6443% | The buyer also pays 1.0000 of accrued interest today |
| Futures DV01 = CTD DV01 | 0.074264 | Divide by the factor: 0.087244 |

---

## When yields move: the switch

Today the 10-year is the CTD by a wide margin. Whether it stays so depends on where yields are on delivery day. The grid below prices each bond on 15 June at a flat yield from 3% to 7% and divides by its factor.

| Delivery-day yield | 10-year | 15-year | 25-year | Cheapest |
| --- | ---: | ---: | ---: | --- |
| 3.0% | 127.56 | 137.49 | 151.50 | 4% 10-year |
| 4.0% | 117.48 | 123.28 | 130.86 | 4% 10-year |
| 5.0% | 108.32 | 110.87 | 113.94 | 4% 10-year |
| 5.5% | 104.06 | 105.25 | 106.64 | 4% 10-year |
| 6.0% | 100.00 | 100.00 | 100.00 | all equal |
| 6.5% | 96.13 | 95.08 | 93.96 | 6.5% 25-year |
| 7.0% | 92.43 | 90.47 | 88.45 | 6.5% 25-year |

A parallel rise of 150 bp, from 5% to 6.5%, switches the CTD from the shortest bond to the longest. The middle bond is never cheapest in this grid: it always sits between the other two.

### The switch option, valued

Model the delivery-day yield as today's 5% plus a normal move $`\Delta`$ with standard deviation $`\sigma`$ = 50 bp, a typical size for a three-month move. The switch happens only if yields rise past 6%, which is two standard deviations away: a 2.28% chance. The option's value is the gap in Step 5:

| Quantity | Value |
| --- | --- |
| lowest average price per factor (the 10-year's) | 108.4253 |
| average of the cheapest, choosing on each outcome | 108.4063 |
| **switch option, futures points** | **0.0190** |
| chance the cheapest switches | 2.28% |

Bigger moves make the option much more valuable, because the switch comes into reach:

```
switch option value, futures points (█ = 0.02)
σ =  50 bp  █                  0.0190
σ =  75 bp  ██████▊            0.1357
σ = 100 bp  ████████████████▉  0.3390
```

At 50 bp the switch option is 0.0190 of the CTD's 0.0676 net basis in futures points: under a third. The rest pays for the timing and end-of-month choices and for the market's own demand for the bond, which this card does not model. The closer yields sit to 6%, the more outcomes land past the crossing, and the larger the option.

---

## Code, from first principles, and it actually runs

Both scripts compute the three conversion factors, the invoice prices, the basis, the carry and the implied repo rate for each bond, then find the CTD. They take two roads to each key number: each factor by adding every payment and by the annuity closed form; the cash paid today by discounting the bond's 15 June value and by discounting each payment for its own time; each implied repo rate by its formula and by bisection (halving an interval until the net basis is zero); the net basis directly and by the identity; the CTD by the highest implied repo rate and by the lowest net basis; the 6% crossing by bisection on the closed-form prices. The switch option is valued twice, by a midpoint sum over the normal density (quadrature) and by 100,000 simulated yield moves from a hand-written random number generator. The futures DV01 is found from the CTD's derivative and by bumping the curve 1 bp each way. Nothing imported knows the answer.

### Python

```python
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
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
bond                        4% 10-year    5% 15-year  6.5% 25-year
CF, payments added            0.851225      0.901998      1.064324
CF, closed form               0.851225      0.901998      1.064324
CF, exchange, 4 decimals        0.8512        0.9020        1.0643
clean price today              92.0495       99.9923      121.3688
accrued today                   1.0000        1.2500        1.6250
cash paid today                93.0495      101.2423      122.9938
invoice at 108-04              92.0387       97.5285      115.0801
coupon on 15 June               2.0000        2.5000        3.2500
gross basis                     0.0108        2.4638        6.2887
carry to delivery              -0.0468        0.1110        0.2413
net basis                       0.0576        2.3527        6.0474
net basis, identity             0.0576        2.3527        6.0474
implied repo, formula %         4.2526       -4.7955      -15.1673
implied repo, bisect %          4.2526       -4.7955      -15.1673
forward price / CF            108.1926      110.7334      113.8069
cheapest by implied repo: 4% 10-year;  by net basis: 4% 10-year

delivery yield %   price/CF:  10-year  15-year  25-year   cheapest
          3.0              127.56   137.49   151.50   4% 10-year
          3.5              122.40   130.14   140.66   4% 10-year
          4.0              117.48   123.28   130.86   4% 10-year
          4.5              112.79   116.86   121.99   4% 10-year
          5.0              108.32   110.87   113.94   4% 10-year
          5.5              104.06   105.25   106.64   4% 10-year
          6.0              100.00   100.00   100.00   all equal
          6.5               96.13    95.08    93.96   6.5% 25-year
          7.0               92.43    90.47    88.45   6.5% 25-year
10-year and 25-year lines cross at 6.000000% (closed-form prices, bisection)

switch option, move SD 50 bp: quadrature 0.0190, simulation 0.0188 (+/- 0.0005)
  lowest average price/CF 108.4253 (4% 10-year), average of cheapest 108.4063
  net basis of the 10-year in futures points: 0.0676
  chance the cheapest switches: quadrature 2.28%, simulation 2.29%
  move SD 75 bp: 0.1357;  SD 100 bp: 0.3390

CTD DV01 per 100 at 5%: 0.074264;  / CF = 0.087244;  bumped futures 0.087244
futures DV01 per 100,000 contract: 87.24 dollars
try: quote 107-04, implied repo of the 10-year 0.5933%
try: repo 5.50%, net basis of the 10-year 0.2902

wrong: cheapest by lowest price at 6.5%: 4% 10-year
wrong: implied repo without the coupon -4.3450%
wrong: implied repo on the clean price 8.6443%
wrong: futures DV01 = CTD DV01 0.074264
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Treasury bond futures: conversion factors, the cheapest to deliver, the implied
// repo rate and the switch option -- the same check as the Python, in Rust.  No crates.
// Three bonds deliverable on 15 June 2027 (a coupon date for all three); today is
// 15 March 2027, a quarter of a year earlier.  Flat curve at 5%, repo 4.50%.
// Roads: conversion factor by summing cash flows and by the closed form; cash price
// today two ways; implied repo by formula and by bisection on the net basis; cheapest
// by implied repo and by net basis; the 6% crossing by bisection on closed-form prices;
// switch option by quadrature and by simulation; futures DV01 by formula and by bumping.
use std::f64::consts::PI;

const BONDS: [(&str, f64, i32); 3] = [("4% 10-year", 4.0, 20), ("5% 15-year", 5.0, 30), ("6.5% 25-year", 6.5, 50)];
const Y: f64 = 0.05; const REPO: f64 = 0.045; const T: f64 = 0.25; // yield, repo, years to delivery
const F: f64 = 108.0 + 4.0 / 32.0; // quote 108-04

fn price_sum(c: f64, n: i32, y: f64) -> f64 { // clean price per 100 face on a coupon date: add every payment
    let v = 1.0 / (1.0 + y / 2.0);
    let mut p = 0.0;
    for k in 1..=n { p += c / 2.0 * v.powf(k as f64); }
    p + 100.0 * v.powf(n as f64)
}
fn price_closed(c: f64, n: i32, y: f64) -> f64 { // the same price by the annuity closed form
    let v = 1.0 / (1.0 + y / 2.0);
    c / 2.0 * (1.0 - v.powf(n as f64)) / (y / 2.0) + 100.0 * v.powf(n as f64)
}
fn dv01(c: f64, n: i32, y: f64) -> f64 { // price fall for one basis point, from the derivative
    let v = 1.0 / (1.0 + y / 2.0);
    let mut d = 0.0;
    for k in 1..=n { d += k as f64 * (c / 2.0) * v.powf((k + 1) as f64); }
    (d + n as f64 * 100.0 * v.powf((n + 1) as f64)) / 2.0 / 10000.0
}
fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // the root, by halving
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) > 0.0) == (g(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn row(name: &str, xs: &[f64], dp: usize) {
    let cells: String = xs.iter().map(|x| format!("{:14.*}", dp, x)).collect();
    println!("{:<24}{}", name, cells);
}
fn ratios(y: f64, cf: &[f64]) -> Vec<f64> {
    BONDS.iter().enumerate().map(|(i, b)| price_sum(b.1, b.2, y) / cf[i]).collect()
}
fn vmin(q: &[f64]) -> f64 { q.iter().cloned().fold(f64::INFINITY, f64::min) }
fn argmin(q: &[f64]) -> usize { let m = vmin(q); q.iter().position(|&x| x == m).unwrap() }

fn option_quad(sd: f64, cf: &[f64]) -> (f64, f64, f64, f64, usize) { // midpoint rule over the normal density
    let m = 4000;
    let (lo, w) = (-8.0 * sd, 16.0 * sd / m as f64);
    let (mut ev, mut emin, mut pswitch) = (vec![0.0; 3], 0.0, 0.0);
    for j in 0..m {
        let d = lo + (j as f64 + 0.5) * w;
        let p = (-d * d / (2.0 * sd * sd)).exp() / (sd * (2.0 * PI).sqrt()) * w;
        let q = ratios(Y + d, cf);
        for i in 0..3 { ev[i] += p * q[i]; }
        emin += p * vmin(&q);
        if vmin(&q) < q[0] { pswitch += p; }
    }
    (vmin(&ev) - emin, vmin(&ev), emin, pswitch, argmin(&ev))
}

fn option_sim(sd: f64, cf: &[f64]) -> (f64, f64, f64) { // same value by simulation: own generator, Box-Muller
    let paths = 100000;
    let mut s: u64 = 88172645463325252;
    let (mut tot, mut tot2, mut sw) = (0.0, 0.0, 0u32);
    let mut u = || {
        s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((s >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    for _ in 0..paths {
        let (u1, u2) = (u(), u());
        let d = sd * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let q = ratios(Y + d, cf);
        let g = q[0] - vmin(&q); // what switching away from the 10-year saves on this path
        tot += g; tot2 += g * g;
        if g > 0.0 { sw += 1; }
    }
    let mean = tot / paths as f64;
    (mean, ((tot2 / paths as f64 - mean * mean) / paths as f64).sqrt(), sw as f64 / paths as f64)
}

fn main() {
    let cf: Vec<f64> = BONDS.iter().map(|b| price_sum(b.1, b.2, 0.06) / 100.0).collect();
    let cf_closed: Vec<f64> = BONDS.iter().map(|b| price_closed(b.1, b.2, 0.06) / 100.0).collect();
    println!("bond                    {}", BONDS.iter().map(|b| format!("{:>14}", b.0)).collect::<String>());
    row("CF, payments added", &cf, 6);
    row("CF, closed form", &cf_closed, 6);
    row("CF, exchange, 4 decimals", &cf, 4);
    let (mut dirty, mut ai0, mut coup, mut nb, mut irr, mut irr_b, mut gross, mut carry) =
        (vec![], vec![], vec![], vec![], vec![], vec![], vec![], vec![]);
    for (i, b) in BONDS.iter().enumerate() {
        let (c, n) = (b.1, b.2);
        let at_delivery = price_sum(c, n, Y) + c / 2.0;           // value on 15 June, coupon included
        dirty.push(at_delivery / (1.0 + Y / 2.0).powf(0.5));     // discounted back half a coupon period
        ai0.push(c / 4.0); coup.push(c / 2.0);                   // accrued today; coupon paid on 15 June
        let clean = dirty[i] - ai0[i];
        gross.push(clean - F * cf[i]);
        carry.push(coup[i] - ai0[i] - dirty[i] * REPO * T);      // accrued at delivery is zero
        nb.push(gross[i] - carry[i]);
        irr.push(((F * cf[i] + coup[i]) / dirty[i] - 1.0) / T);
        let (di, ki, fi) = (dirty[i], coup[i], F * cf[i]);
        irr_b.push(bisect(&|r| di * (1.0 + r * T) - ki - fi, -1.0, 1.0));
    }
    let dirty_flows: Vec<f64> = BONDS.iter().map(|b| (0..=b.2).map(|k| // road 2: each payment discounted for its own time
        (b.1 / 2.0 + if k == b.2 { 100.0 } else { 0.0 }) / (1.0 + Y / 2.0).powf(k as f64 + 0.5)).sum()).collect();
    let pc = |v: &Vec<f64>| v.iter().map(|r| 100.0 * r).collect::<Vec<f64>>();
    row("clean price today", &(0..3).map(|i| dirty[i] - ai0[i]).collect::<Vec<_>>(), 4);
    row("accrued today", &ai0, 4);
    row("cash paid today", &dirty, 4);
    row("invoice at 108-04", &cf.iter().map(|x| F * x).collect::<Vec<_>>(), 4);
    row("coupon on 15 June", &coup, 4);
    row("gross basis", &gross, 4);
    row("carry to delivery", &carry, 4);
    row("net basis", &nb, 4);
    row("net basis, identity", &(0..3).map(|i| dirty[i] * T * (REPO - irr[i])).collect::<Vec<_>>(), 4);
    row("implied repo, formula %", &pc(&irr), 4);
    row("implied repo, bisect %", &pc(&irr_b), 4);
    row("forward price / CF", &(0..3).map(|i| (dirty[i] * (1.0 + REPO * T) - coup[i]) / cf[i]).collect::<Vec<_>>(), 4);
    let ctd_r = argmin(&irr.iter().map(|r| -r).collect::<Vec<_>>());
    let ctd_b = argmin(&nb);
    println!("cheapest by implied repo: {};  by net basis: {}", BONDS[ctd_r].0, BONDS[ctd_b].0);

    println!("\ndelivery yield %   price/CF:  10-year  15-year  25-year   cheapest");
    for k in 0..9 {
        let yd = 0.03 + 0.005 * k as f64;
        let q = ratios(yd, &cf);
        let spread = q.iter().cloned().fold(f64::NEG_INFINITY, f64::max) - vmin(&q);
        let name = if spread < 1e-9 { "all equal" } else { BONDS[argmin(&q)].0 };
        println!("{:13.1} {:10}{}   {}", 100.0 * yd, "", q.iter().map(|x| format!("{:9.2}", x)).collect::<String>(), name);
    }
    let ystar = bisect(&|y| price_closed(4.0, 20, y) / cf[0] - price_closed(6.5, 50, y) / cf[2], 0.03, 0.09);
    println!("10-year and 25-year lines cross at {:.6}% (closed-form prices, bisection)", 100.0 * ystar);

    let (val, best_mean, mean_min, psw, best) = option_quad(0.005, &cf);
    let (sim, se, psw_sim) = option_sim(0.005, &cf);
    println!("\nswitch option, move SD 50 bp: quadrature {:.4}, simulation {:.4} (+/- {:.4})", val, sim, se);
    println!("  lowest average price/CF {:.4} ({}), average of cheapest {:.4}", best_mean, BONDS[best].0, mean_min);
    println!("  net basis of the 10-year in futures points: {:.4}", nb[0] / cf[0]);
    println!("  chance the cheapest switches: quadrature {:.2}%, simulation {:.2}%", 100.0 * psw, 100.0 * psw_sim);
    println!("  move SD 75 bp: {:.4};  SD 100 bp: {:.4}", option_quad(0.0075, &cf).0, option_quad(0.01, &cf).0);

    let d_ctd = dv01(4.0, 20, Y);
    let bump = (vmin(&ratios(Y - 0.0001, &cf)) - vmin(&ratios(Y + 0.0001, &cf))) / 2.0;
    println!("\nCTD DV01 per 100 at 5%: {:.6};  / CF = {:.6};  bumped futures {:.6}", d_ctd, d_ctd / cf[0], bump);
    println!("futures DV01 per 100,000 contract: {:.2} dollars", 1000.0 * d_ctd / cf[0]);
    println!("try: quote 107-04, implied repo of the 10-year {:.4}%", 100.0 * ((107.125 * cf[0] + 2.0) / dirty[0] - 1.0) / T);
    println!("try: repo 5.50%, net basis of the 10-year {:.4}", dirty[0] * T * (0.055 - irr[0]));

    let lowest = argmin(&BONDS.iter().map(|b| price_sum(b.1, b.2, 0.065)).collect::<Vec<_>>());
    println!("\nwrong: cheapest by lowest price at 6.5%: {}", BONDS[lowest].0);
    println!("wrong: implied repo without the coupon {:.4}%", 100.0 * ((F * cf[0]) / dirty[0] - 1.0) / T);
    println!("wrong: implied repo on the clean price {:.4}%", 100.0 * ((F * cf[0] + 2.0) / (dirty[0] - 1.0) - 1.0) / T);
    println!("wrong: futures DV01 = CTD DV01 {:.6}", d_ctd);

    assert!((0..3).all(|i| (cf[i] - cf_closed[i]).abs() < 1e-12), "two roads to each CF");
    assert!((0..3).all(|i| (irr[i] - irr_b[i]).abs() < 1e-10), "implied repo: formula = bisection");
    assert!((0..3).all(|i| (gross[i] - carry[i] - dirty[i] * T * (REPO - irr[i])).abs() < 1e-10));
    assert!(ctd_r == 0 && ctd_b == 0, "highest implied repo and lowest net basis pick the same bond");
    assert!((0..3).all(|i| (dirty[i] - dirty_flows[i]).abs() < 1e-9), "cash price today: two roads");
    let card_cf = [0.851225, 0.901998, 1.064324];
    assert!((0..3).all(|i| ((cf[i] * 1e6).round() / 1e6 - card_cf[i]).abs() < 1e-12), "the factors quoted on the card");
    assert!((ystar - 0.06).abs() < 1e-9 && BONDS.iter().enumerate()
        .all(|(i, b)| (price_closed(b.1, b.2, ystar) / cf[i] - 100.0).abs() < 1e-7), "all three tie at 6%");
    assert!(argmin(&ratios(0.065, &cf)) == 2, "+150 bp switches to the 25-year");
    assert!(best == 0 && (sim - val).abs() < 4.0 * se, "simulation agrees with quadrature");
    assert!((psw - 0.02275).abs() < 1e-3, "switch beyond +100 bp: two SDs, 2.28%");
    assert!((bump - d_ctd / cf[0]).abs() < 1e-6, "futures DV01 = CTD DV01 / CF");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
bond                        4% 10-year    5% 15-year  6.5% 25-year
CF, payments added            0.851225      0.901998      1.064324
CF, closed form               0.851225      0.901998      1.064324
CF, exchange, 4 decimals        0.8512        0.9020        1.0643
clean price today              92.0495       99.9923      121.3688
accrued today                   1.0000        1.2500        1.6250
cash paid today                93.0495      101.2423      122.9938
invoice at 108-04              92.0387       97.5285      115.0801
coupon on 15 June               2.0000        2.5000        3.2500
gross basis                     0.0108        2.4638        6.2887
carry to delivery              -0.0468        0.1110        0.2413
net basis                       0.0576        2.3527        6.0474
net basis, identity             0.0576        2.3527        6.0474
implied repo, formula %         4.2526       -4.7955      -15.1673
implied repo, bisect %          4.2526       -4.7955      -15.1673
forward price / CF            108.1926      110.7334      113.8069
cheapest by implied repo: 4% 10-year;  by net basis: 4% 10-year

delivery yield %   price/CF:  10-year  15-year  25-year   cheapest
          3.0              127.56   137.49   151.50   4% 10-year
          3.5              122.40   130.14   140.66   4% 10-year
          4.0              117.48   123.28   130.86   4% 10-year
          4.5              112.79   116.86   121.99   4% 10-year
          5.0              108.32   110.87   113.94   4% 10-year
          5.5              104.06   105.25   106.64   4% 10-year
          6.0              100.00   100.00   100.00   all equal
          6.5               96.13    95.08    93.96   6.5% 25-year
          7.0               92.43    90.47    88.45   6.5% 25-year
10-year and 25-year lines cross at 6.000000% (closed-form prices, bisection)

switch option, move SD 50 bp: quadrature 0.0190, simulation 0.0188 (+/- 0.0005)
  lowest average price/CF 108.4253 (4% 10-year), average of cheapest 108.4063
  net basis of the 10-year in futures points: 0.0676
  chance the cheapest switches: quadrature 2.28%, simulation 2.29%
  move SD 75 bp: 0.1357;  SD 100 bp: 0.3390

CTD DV01 per 100 at 5%: 0.074264;  / CF = 0.087244;  bumped futures 0.087244
futures DV01 per 100,000 contract: 87.24 dollars
try: quote 107-04, implied repo of the 10-year 0.5933%
try: repo 5.50%, net basis of the 10-year 0.2902

wrong: cheapest by lowest price at 6.5%: 4% 10-year
wrong: implied repo without the coupon -4.3450%
wrong: implied repo on the clean price 8.6443%
wrong: futures DV01 = CTD DV01 0.074264
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves four of the card's rules for any basket of bonds, and checks the quote 108-04 and the three factors.

- Suppose the cash paid today and the time to delivery are positive. Then each bond's net basis equals $`(P_0 + AI_0)\,t\,(r - r_{\mathrm{imp}})`$.
- One bond's net basis per dollar of cash paid is no larger than another's exactly when its implied repo rate is no smaller.
- Take any bond with a coupon of zero or more. Then its price at a 6% yield, divided by its conversion factor, is exactly 100.
- Take finitely many delivery-day outcomes, averaged with weights of zero or more. Then $`E[\min_i X_i] \le \min_i E[X_i]`$: a choice can only lower the price.
- The quote 108-04 is exactly 108.125, and the three factors round to 0.851225, 0.901998 and 1.064324.

Cash prices, implied repo decimals, the grid, the switch option's value and the futures DV01 are left to the Python and Rust checks.

```lean
-- Treasury bond futures: the implied repo rate turns the net basis into cash times time times the gap to repo so the cheapest bond is the one with the highest implied repo, every bond's price per conversion factor is exactly 100 at a 6% yield, and a choice of bonds can only lower the futures price.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring

open Finset

/-- Clean price per 100 of face, on a coupon date, of a bond paying coupon `c` percent a year in
two halves with `n` half-years left, at a flat yield `y` compounded twice a year: every coupon
`c / 2` and the face `100` discounted at `y / 2` a half-year. -/
noncomputable def bondPrice (c : ℝ) (n : ℕ) (y : ℝ) : ℝ :=
  ∑ k ∈ range n, c / 2 * (1 + y / 2)⁻¹ ^ (k + 1) + 100 * (1 + y / 2)⁻¹ ^ n

/-- The conversion factor: the bond's price at a 6% yield, per 1 of face. -/
noncomputable def convFactor (c : ℝ) (n : ℕ) : ℝ :=
  bondPrice c n (6 / 100) / 100

/-- The implied repo rate: cash back at delivery (invoice `F · CF + AI_D` plus coupon `C`) over
cash paid today (`P₀ + AI₀`), less one, per year over `t` years. -/
noncomputable def impliedRepo (F CF AID C P₀ AI₀ t : ℝ) : ℝ :=
  ((F * CF + AID + C) / (P₀ + AI₀) - 1) / t

/-- The net basis at repo rate `r`: gross basis `P₀ - F · CF` minus carry
`C + AI_D - AI₀ - (P₀ + AI₀) r t`. -/
def netBasis (F CF AID C P₀ AI₀ r t : ℝ) : ℝ :=
  (P₀ - F * CF) - (C + AID - AI₀ - (P₀ + AI₀) * r * t)

/-- The implied repo and net-basis identity, and the cheapest-to-deliver rule it gives.
Take a basket of bonds `i`, each with clean price `P₀ i`, accrued today `AI₀ i`, accrued at
delivery `AID i`, coupon cash before delivery `C i` and conversion factor `CF i`, one futures
price `F`, one repo rate `r`, and `t` years to delivery. Suppose the cash paid today
`P₀ i + AI₀ i` and the time `t` are positive. Then each bond's net basis equals
`(P₀ + AI₀) · t · (r - r_imp)`, and so one bond has a net basis per dollar of cash paid no larger
than another's exactly when its implied repo rate is no smaller: the bond with the highest
implied repo rate is the cheapest to deliver. -/
theorem net_basis_eq_cash_times_repo_gap {B : Type*} (P₀ AI₀ AID C CF : B → ℝ) (F r t : ℝ)
    (hD : ∀ i, 0 < P₀ i + AI₀ i) (ht : 0 < t) :
    (∀ i, netBasis F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) r t
        = (P₀ i + AI₀ i) * t * (r - impliedRepo F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) t)) ∧
    (∀ i j, netBasis F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) r t / (P₀ i + AI₀ i)
          ≤ netBasis F (CF j) (AID j) (C j) (P₀ j) (AI₀ j) r t / (P₀ j + AI₀ j) ↔
        impliedRepo F (CF j) (AID j) (C j) (P₀ j) (AI₀ j) t
          ≤ impliedRepo F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) t) := by
  have key : ∀ i, netBasis F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) r t
      = (P₀ i + AI₀ i) * t * (r - impliedRepo F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) t) := by
    intro i
    have hDi := (hD i).ne'
    unfold netBasis impliedRepo
    field_simp
    ring
  refine ⟨key, fun i j => ?_⟩
  rw [key i, key j]
  rw [mul_assoc, mul_div_cancel_left₀ _ (hD i).ne', mul_assoc,
    mul_div_cancel_left₀ _ (hD j).ne']
  rw [mul_le_mul_iff_of_pos_left ht]
  constructor <;> intro h <;> linarith

/-- The 6% tie. For any bond with a coupon of zero or more, its price at a 6% yield divided by
its conversion factor is exactly 100: at 6% every bond in the basket is equally good to
deliver. -/
theorem price_per_factor_at_six_percent (c : ℝ) (n : ℕ) (hc : 0 ≤ c) :
    bondPrice c n (6 / 100) / convFactor c n = 100 := by
  have hpos : 0 < bondPrice c n (6 / 100) := by
    unfold bondPrice
    have h1 : 0 ≤ ∑ k ∈ range n, c / 2 * (1 + (6 / 100 : ℝ) / 2)⁻¹ ^ (k + 1) :=
      Finset.sum_nonneg (fun k _ => by positivity)
    have h2 : 0 < 100 * (1 + (6 / 100 : ℝ) / 2)⁻¹ ^ n := by positivity
    linarith
  unfold convFactor
  field_simp

/-- A choice of bonds can only lower the futures price. Take finitely many delivery-day outcomes
`s` with weights `p s` of zero or more, and `X s i`, bond `i`'s price per factor in outcome `s`.
Then the weighted average of the cheapest bond's price per factor is at most the smallest of
the bonds' weighted averages: `E[min_i X_i] ≤ min_i E[X_i]`. -/
theorem average_of_cheapest_le_cheapest_average {S B : Type*} [Fintype S] [Fintype B]
    [Nonempty B] (p : S → ℝ) (hp : ∀ s, 0 ≤ p s) (X : S → B → ℝ) :
    ∑ s, p s * univ.inf' univ_nonempty (X s)
      ≤ univ.inf' univ_nonempty (fun i => ∑ s, p s * X s i) := by
  refine Finset.le_inf' _ _ (fun i _ => ?_)
  refine Finset.sum_le_sum (fun s _ => ?_)
  exact mul_le_mul_of_nonneg_left (Finset.inf'_le _ (Finset.mem_univ i)) (hp s)

-- The quote 108-04 is 108 and 4/32, that is 108.125 = 865/8 per 100 of face.
example : (108 : ℚ) + 4 / 32 = 865 / 8 := by norm_num

-- The three factors on the card round to 0.851225, 0.901998 and 1.064324.
example : (8512245 : ℝ) / 10 ^ 7 ≤ convFactor 4 20 ∧ convFactor 4 20 < 8512255 / 10 ^ 7 := by
  norm_num [convFactor, bondPrice, Finset.sum_range_succ]

example : (9019975 : ℝ) / 10 ^ 7 ≤ convFactor 5 30 ∧ convFactor 5 30 < 9019985 / 10 ^ 7 := by
  norm_num [convFactor, bondPrice, Finset.sum_range_succ]

example : (10643235 : ℝ) / 10 ^ 7 ≤ convFactor (13 / 2) 50 ∧
    convFactor (13 / 2) 50 < 10643245 / 10 ^ 7 := by
  norm_num [convFactor, bondPrice, Finset.sum_range_succ]

#print axioms net_basis_eq_cash_times_repo_gap
#print axioms price_per_factor_at_six_percent
#print axioms average_of_cheapest_le_cheapest_average
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'net_basis_eq_cash_times_repo_gap' depends on axioms: [propext, Classical.choice, Quot.sound]
'price_per_factor_at_six_percent' depends on axioms: [propext, Classical.choice, Quot.sound]
'average_of_cheapest_le_cheapest_average' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run. The `try:` lines and the grid already print each answer.
> - **Drop the quote a full point, to 107-04.** Guess first: does the CTD's implied repo fall a little or a lot? It falls from 4.2526% to 0.5933%: one point is a large return on a three-month trade.
> - **Raise the repo rate to 5.50%.** Guess first: does the implied repo change? It does not: it depends only on prices. The net basis rises to 0.2902, a cheaper futures relative to the bond.
> - **Raise the standard deviation of the yield move to 100 bp.** Guess first: double the option value, or more? Far more: the switch option goes from 0.0190 to 0.3390.
> - **Set the delivery-day yield to 6%.** Guess first: which bond is cheapest? In the grid, every bond's price per factor is 100.00: the factor works perfectly, and there is nothing to choose.

---

## The usual mistake

> [!warning]
> **Picking the cheapest bond by its price.** The buyer pays the futures price times the factor, so the cost to compare is price divided by factor. At a 6.5% yield the 4% 10-year has the lowest price of the three, yet its price per factor, 96.13, is the highest; the 25-year at 93.96 is cheapest to deliver.
>
> - **Leaving the coupon out of the implied repo.** The 10-year's 2.0000 coupon on 15 June is cash the trade earns. Without it the implied repo is −4.3450%, not 4.2526%.
> - **Using the clean price as the cost.** The buyer pays accrued interest too. On the clean price alone the implied repo is 8.6443%, above repo, which looks like free money that is not there.
> - **Hedging with the CTD's DV01.** One contract moves like 1/0.851225 of the CTD's 100 face: 0.087244 per 100, or \$87.24 per contract, not 0.074264.
> - **Assuming the CTD stays put.** A 150 bp rise switches it to the 25-year, and the futures DV01 jumps with it. A hedge set at 5% is wrong at 6.5%.

---

## Where you meet it in real life

- **Basis trading.** A trader who buys the CTD and sells futures is "long the basis": they pay the net basis and own the short's choices, so they profit only if those choices turn out worth more than the net basis. The opposite trade, "short the basis", collects the net basis and gives up the choices. Funds run this trade at large size, financed in repo, which ties Treasury futures to the repo market.
- **Hedging a bond portfolio.** A fund hedges a bond portfolio by selling futures. It sizes the hedge with the futures DV01, the CTD's DV01 over its factor: \$87.24 per contract here. [Key-rate durations](02-key-rate-durations-and-curve-hedging.md) shows how to hedge against moves at single maturities.
- **The delivery month.** In the delivery month, shorts deliver the CTD and longs receive it. Desks watch the implied repo rate of each deliverable bond against repo to see which will arrive.
- **Changing the duration of a portfolio quickly.** A pension fund lengthens its duration by buying futures rather than bonds: less cash up front, the same rate exposure, through the CTD's DV01.
- **The term structure of futures prices.** Futures for later delivery dates sit at the CTD's forward price over its factor, less the option value. [Carry and roll-down](05-carry-and-roll-down.md) reads the same carry in bond returns.

> **Say it back**
> A Treasury bond futures contract lets the short deliver any bond in a basket, and pays the futures price times that bond's conversion factor, its price at a 6% yield. At 6% every bond delivers equally; below 6% the shortest-duration bond is cheapest, above 6% the longest. The cheapest to deliver is the bond that earns the highest implied repo rate when bought today and delivered, and its net basis is the shortfall from the repo rate in dollars. The short's freedom to switch bonds is an option that lowers the futures price. The futures moves like the cheapest bond divided by its factor.

---

## What this builds on

- [Bond price and yield](../01-Money%2C%20Dates%20and%20Discounting/05-bonds-price-and-yield.md): pricing a bond by discounting its coupons and face, and accrued interest; the conversion factor is that price at 6%.
- [Duration and convexity](../01-Money%2C%20Dates%20and%20Discounting/06-duration-and-convexity.md): why the long bond's price per factor moves most, and the DV01 behind the futures hedge.
- [Futures](../03-Contracts%20and%20No-Arbitrage/05-futures-margining-and-the-forward-futures-difference.md): daily settlement and why a futures price can be treated like a forward when rates are known.
- [Forward price](../03-Contracts%20and%20No-Arbitrage/03-forward-price-by-cash-and-carry.md): buy, finance and hold to delivery; the net basis is the bond's cash-and-carry forward price minus the invoice.
- [Money markets](../02-Curves/03-money-market-instruments-and-sofr.md): repo as a loan against a bond, the rate the implied repo is measured against.

## Where this goes next

- No later card yet.

This card moved the whole curve in parallel and valued only the switch option. How a change in the curve's slope moves the cheapest bond, and how to value the timing and end-of-month choices, is the question it leaves open.

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Tuckman, Bruce, and Angel Serrat. *Fixed Income Securities: Tools for Today's Markets*, 4th ed. Wiley, 2022. [Publisher page](https://www.wiley.com/en-us/Fixed+Income+Securities%3A+Tools+for+Today%27s+Markets%2C+4th+Edition-p-9781119835554). Note and bond futures: conversion factors, the cheapest to deliver, the implied repo rate, net basis and the delivery options.
- Gay, Gerald D., and Steven Manaster. "The Quality Option Implicit in Futures Contracts." *Journal of Financial Economics* 13, no. 3 (1984): 353–370. [doi:10.1016/0304-405X(84)90004-7](https://doi.org/10.1016/0304-405X(84)90004-7). The choice of which grade to deliver valued as an option, the idea behind Step 5.
- Hemler, Michael L. "The Quality Delivery Option in Treasury Bond Futures Contracts." *The Journal of Finance* 45, no. 5 (1990): 1565–1586. [doi:10.1111/j.1540-6261.1990.tb03728.x](https://doi.org/10.1111/j.1540-6261.1990.tb03728.x). The Treasury bond quality option: how it is priced and how large it is.
