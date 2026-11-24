# Dividend futures and swaps: trading the dividends alone, and the implied dividend strip read from options

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Equity financing - borrow, total return swaps and dividends](../README.md#s52) → Dividend futures and swaps

---

## General Overview

Acme shares trade at $100.00. Acme pays one cash dividend a year, each time about nine months into the year. Nobody quotes what those dividends will be. But options on Acme trade at three expiries, one, two and three years away, and the bank rate is 5% a year.

The options say what the dividends are worth. A share bought today collects every dividend paid before an expiry. A forward, a promise to buy the share on that expiry day, collects none of them. A call bought and a put sold at one strike (the fixed price written into both options) make exactly that forward ([Put-call parity](../08-The%20Black-Scholes%20call%20and%20put/03-put-call-parity.md)). So the share price, less the value today of getting the share on expiry day (call minus put, plus the strike's value today), is the value today of the dividends paid before that expiry.

Run that at all three expiries and the options give **$1.93**, **$3.85** and **$5.77**: the dividends before year 1, before year 2 and before year 3, each valued today. Take differences and each year's dividend stands alone. Year 2's dividend is worth $1.92 today. Carried forward at the bank rate to the day it is paid, that is **$2.10**.

That $2.10 is the fair price of a **dividend future** on year 2. A dividend future is an exchange contract whose final value is the cash dividends the share pays in one year, nothing else. A **dividend swap** does the same over several years, privately between two parties: on the last day, one side pays the dividends actually paid, the other pays a fixed amount called the strike. The fair three-year strike is the sum of the three futures prices, **$6.30**.

Both trade the dividends alone, with no exposure to the share price. The people who need them are the ones holding long-dated options, because a three-year call on Acme loses about $1.84 for every $1 added to each of the three dividends.

**Put-call parity at each expiry prices the dividends paid before it, so the difference between two expiries prices the dividends paid between them; carry that difference forward to its payment date and it is the fair dividend future, and the futures summed are the fair dividend swap strike.**

**What kind of fact this is:** a method that rests on a theorem. Put-call parity is proved without any model of the share, so the strip of dividend values is model-free. Turning values into futures prices adds two assumptions: known payment dates and a known bank rate. The dividend delta of an option, on the other hand, comes from a model: the escrowed-dividend Black–Scholes model of [Known cash dividends](../08-The%20Black-Scholes%20call%20and%20put/08-known-cash-dividends.md).

### The picture: three values today become three futures prices

```
Value today of each year's dividend (from the options)
year 1  ███████████████████      1.926389
year 2  ███████████████████      1.924060
year 3  ███████████████████      1.917376

Dividend future: the same, carried to the payment date
year 1  ████████████████████     2.000000
year 2  █████████████████████    2.100000
year 3  ██████████████████████   2.200000
```

The top three bars are nearly equal. The dividend grows by about 5% a year, and discounting at 5% a year takes almost all of that growth back out. The bottom bars put the growth back: carrying each value forward to its own payment date undoes the discount. The longer the wait, the larger the carry factor.

---

## The formula

Notation first, in words. $`D(T)`$ is the value today of all dividends paid before expiry $`T`$: the **cumulative implied dividend**. The list of $`D(T)`$ across expiries is the **implied dividend strip**. Year $`i`$ runs from expiry $`T_{i-1}`$ to expiry $`T_i`$, with $`T_0 = 0`$ and $`D(T_0) = 0`$. Its dividend $`\mathrm{div}_i`$ is paid at time $`t_i`$.

The strip, from a call $`C`$ and put $`P`$ at strike $`K`$ and expiry $`T`$:

```math
D(T) = S - K e^{-rT} - \big(C(T) - P(T)\big)
```

One year's dividend, valued today, and its futures price:

```math
\mathrm{PV}_i = D(T_i) - D(T_{i-1}), \qquad F_i = \mathrm{PV}_i \, e^{r t_i}
```

The dividend swap strike over years 1 to $`n`$, and the dividend delta of a call expiring at $`T`$, for any dividend paid before $`T`$:

```math
K_{\mathrm{swap}} = F_1 + F_2 + \dots + F_n, \qquad \Delta_i = \frac{\partial C}{\partial \mathrm{div}_i} = -N(d_1)\, e^{-r t_i}
```

**Read it aloud:** the share price, less the strike's value today, less the call-minus-put gap, is what the dividends before expiry are worth today; difference two expiries, carry the result forward to the payment date, and that is the year's dividend future; add the futures to get the swap strike.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`S`$, $`S_T`$, $`S^{*}`$ | Acme's share price today; $`S_T`$ is its price at expiry; $`S^{*}`$, in the fold, is the escrowed share: $`S`$ less the dividends' value today | $100.00 | every $`D(T)`$ rises one for one, if the option quotes stay put |
| $`K`$ | the strike both options share | $100.00 | no change: the gap $`C - P`$ shrinks to match |
| $`r`$ | the bank rate, continuously compounded | 5% | the strike's value today falls, and the carry factor $`e^{r t_i}`$ rises |
| $`T`$, $`T_i`$ | an option expiry, in years; $`T_i`$ is the end of year $`i`$ | 1, 2, 3 | more dividends fall before it, so $`D(T)`$ rises |
| $`C(T)`$, $`P(T)`$ | the call and put prices today at expiry $`T`$ | $13.566895 and $7.901085 at 2 years | a dearer call means a smaller $`D(T)`$; a dearer put, a larger one |
| $`D(T)`$ | cumulative implied dividend: value today of dividends before $`T`$ | $1.926389, $3.850448, $5.767824 | the answer of the first line |
| $`\mathrm{PV}_i`$ | value today of year $`i`$'s dividend alone | $1.924060 for year 2 | the year's future rises with it |
| $`t_i`$, $`t_s`$ | when year $`i`$'s dividend is paid, in years from today; $`t_s`$, in the fold, is a future's settlement day | 0.75, 1.75, 2.75 | the carry factor grows, so the future rises |
| $`\mathrm{div}_i`$ | the cash dividend paid at $`t_i`$, written div so it is not confused with Black–Scholes $`d_1`$: unknown today | — | calls fall, puts rise |
| $`F_i`$, $`\mathbb{E}^{\mathbb{Q}}`$ | the fair price of the year-$`i`$ dividend future: $`\mathbb{E}^{\mathbb{Q}}[\mathrm{div}_i]`$, the dividend's average in the risk-neutral (pricing) world | $2.000000, $2.100000, $2.200000 | the answer of the second line |
| $`K_{\mathrm{swap}}`$, $`n`$ | the fair strike of a dividend swap over years 1 to $`n`$ | $6.300000 for 3 years | the answer of the third line |
| $`\Delta_i`$, $`N(d_1)`$, $`d_2`$ | dividend delta: dollars of call price per $1 more on $`\mathrm{div}_i`$. $`N(d_1)`$ is the call's share delta in the escrowed model, from [Black–Scholes call](../08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md); $`d_2`$ is $`d_1`$ less the volatility times $`\sqrt{T}`$, as there | −0.5823 for the 3-year call on year 3; $`N(d_1)`$ = 0.668117 | more negative for deeper in-the-money calls |

### When it holds

- **European options, both quotes live together.** American options carry an early-exercise value, and parity does not know it is there; it then lands in the strip as if it were dividend. A stale leg moves $`D(T)`$ by part of the share's move since that quote.
- **The share costs nothing to borrow.** A borrow fee, the charge for borrowing a share to sell it, lowers the forward exactly the way a dividend does ([Stock borrow and repo](01-stock-borrow-repo-and-the-equity-forward.md)). On the shelf's house numbers a 1% fee drops the one-year forward from 103.0455 to 102.0201. For Acme here, a 1% fee on the share's value, read as dividend, turns the three futures into $3.028044, $3.149085 and $3.269952.
- **Known payment dates.** The strip gives a value for each interval between expiries, not the day inside it. The carry needs the day. Carry year 2 to the year's end instead of its payment date and the future comes out at $2.126415, not $2.10.
- **A known bank rate.** Futures are settled in cash every day, called daily margining. With a known rate the futures price equals the forward price. If rates move together with dividends, the futures price and the forward price differ by a small amount, called the convexity gap.
- **The delta needs a model.** The strip and the futures need no model at all. $`\Delta_i`$ assumes the escrowed model: cash dividends, with the volatility on the share net of their value. Other models give other deltas.

---

## Why it works

### Step 0: a share is its dividends plus a forward

A holder of Acme until expiry $`T`$ gets two things: every dividend paid before $`T`$, and the share itself on expiry day. A forward gives only the second. So the share's price today, less the value today of getting the share on expiry day, is the price today of the dividends. Options give that value, call minus put plus the strike's value today, so options give the dividends.

### Step 1: parity solved for the dividends

A call bought and a put sold at strike $`K`$ pay $`S_T - K`$ on expiry day, where $`S_T`$ is Acme's price then, whatever it is. So does this: hold the share, hand over the dividends as they come, and owe $`K`$ at expiry. Two things that pay the same cost the same today:

```math
C(T) - P(T) = S - D(T) - K e^{-rT}
```

This is the parity line of [Known cash dividends](../08-The%20Black-Scholes%20call%20and%20put/08-known-cash-dividends.md), with $`D(T)`$ in place of the escrow. Solve it for $`D(T)`$ and the first formula comes out. No model of the share enters, and the dividends need not be known. $`D(T)`$ is the market's value today of whatever they turn out to be.

At two years: $`100.00 - 90.483742 - 5.665810 = 3.850448`$.

### Step 2: values add, so differences isolate one year

The dividends before year 2 are the dividends before year 1 plus the dividend in year 2. Values today add the same way. So year 2's dividend alone is worth $`D(2) - D(1)`$ = $1.924060.

[Implied forward and dividend from parity](../11-Implied%20volatility%20and%20the%20vanilla%20inverses/05-implied-forward-and-dividend-from-parity.md) read one carry from one expiry. This card reads one at each expiry, and the differences between them are the new information.

### Step 3: from value today to a futures price

A dividend future on year $`i`$ ends paying $`\mathrm{div}_i`$, the cash dividend, in full. Its price $`F_i`$ is set so that entering the contract costs nothing.

The pricing rule comes from [The fundamental theorems](../05-Black-Scholes%20from%20the%20Ground%20Up/02-risk-neutral-measure-and-the-fundamental-theorems.md): anything paid at $`t_i`$ is worth $`e^{-r t_i}`$ times its average in the risk-neutral world (the pricing world, where every asset grows at the bank rate). So $`\mathrm{PV}_i = e^{-r t_i}\,\mathbb{E}^{\mathbb{Q}}[\mathrm{div}_i]`$, where $`\mathbb{E}^{\mathbb{Q}}`$ is that average. With a known rate, a futures price is that same average of what it settles on: $`F_i = \mathbb{E}^{\mathbb{Q}}[\mathrm{div}_i]`$. Put the two together:

```math
F_i = \mathrm{PV}_i \, e^{r t_i}
```

The carry runs to the payment date $`t_i`$, not to the contract's last day. The future settles on the dividend's amount, with no interest added for the months between payment and settlement.

### Step 4: a swap is a bundle of futures

A three-year dividend swap pays $`\mathrm{div}_1 + \mathrm{div}_2 + \mathrm{div}_3 - K_{\mathrm{swap}}`$ at year 3. Its value today is $`e^{-3r}`$ times the average of that, which is zero when $`K_{\mathrm{swap}} = F_1 + F_2 + F_3`$. Here: 2.00 + 2.10 + 2.20 = $6.30.

The strike is the sum of the futures, not of the values today. Each dividend is paid in full on the last day, whenever it was earned.

### Step 5: why long-dated options carry dividend risk

In the escrowed model, a call is priced on the share less the value today of the dividends before expiry. Raise $`\mathrm{div}_i`$ by $1 and that escrowed share falls by $`e^{-r t_i}`$. The call moves by its share delta times that fall, so $`\Delta_i = -N(d_1)\,e^{-r t_i}`$. A put has the opposite sign: $`+N(-d_1)\,e^{-r t_i}`$.

A one-year call feels one dividend. A three-year call feels three, so its total dividend delta is more than three times larger, about −1.84. That is why dividend risk is a long-dated options problem, and why the dividend future is its hedge: buy 0.58 year-3 futures per three-year call to cover its year-3 exposure.

<details>
<summary>Detailed proof: the replication trades behind Steps 1, 3 and 4</summary>

**Step 1 as a trade.** Buy the share, sell the call, buy the put, borrow $`K e^{-rT}`$. Pass each dividend to the lender of a second loan, borrowed today against those dividends for $`D(T)`$. At expiry the options turn the share into exactly $`K`$, which repays the first loan. Nothing is left, so the cost today is zero:

$`\displaystyle S - C(T) + P(T) - K e^{-rT} - D(T) = 0`$

If $`D(T)`$ were quoted elsewhere at a different price, the trade or its reverse would make money for nothing.

**Step 2.** The value today of a sum of payments is the sum of their values today. This is linearity of price, which no-arbitrage gives.

**Step 3, futures equal forwards.** With a known rate, hold $`e^{-r(t_s - t)}`$ futures on each day $`t`$, where $`t_s`$ is settlement. Each day's margin, invested at the bank rate to $`t_s`$, grows by the factor that cancels this weight. The total at $`t_s`$ is the change in the futures price, $`\mathrm{div}_i - F_i`$, scaled by one: a forward's payoff. Two positions that cost nothing and pay the same have the same price. A forward that settles at $`t_s`$ on $`\mathrm{div}_i`$ has price $`\mathbb{E}^{\mathbb{Q}}[\mathrm{div}_i]`$, because its value is $`e^{-r t_s}(\mathbb{E}^{\mathbb{Q}}[\mathrm{div}_i] - F) = 0`$. The settlement date cancels.

**Step 4.** The swap payoff is the sum of three forward payoffs settling on the same day, minus a constant. Each forward has zero value at its own fair price, so the swap is fair when the constant is the sum of those prices.

**Step 5.** $`C = S^{*} N(d_1) - K e^{-rT} N(d_2)`$ with $`S^{*} = S - \sum_{t_j < T} \mathrm{div}_j e^{-r t_j}`$. The derivative of the Black–Scholes price in the spot is $`N(d_1)`$, the terms from moving $`d_1`$ and $`d_2`$ cancelling as on [Delta](../09-The%20Greeks%2C%20one%20each/01-delta.md). The chain rule gives $`\partial C / \partial \mathrm{div}_i = N(d_1) \cdot (-e^{-r t_i})`$.

</details>

---

## Worked numbers, by hand

Acme at $`S`$ = $100.00, rate $`r`$ = 5%, strike $`K`$ = $100.00. The quotes below came from options priced with dividends of $2.00, $2.10 and $2.20 paid at 0.75, 1.75 and 2.75 years and volatility 20%. The method sees only the quotes.

| Step | Arithmetic | Value |
| --- | --- | --- |
| 1-year gap, $`C - P`$ | $`9.259211 - 6.308542`$ | $2.950669 |
| 1-year strike value today, $`K e^{-r}`$ | $`100 \times e^{-0.05}`$ | $95.122942 |
| $`D(1)`$ | $`100 - 95.122942 - 2.950669`$ | $1.926389 |
| 2-year gap | $`13.566895 - 7.901085`$ | $5.665810 |
| $`D(2)`$ | $`100 - 90.483742 - 5.665810`$ | $3.850448 |
| 3-year gap | $`16.894352 - 8.732974`$ | $8.161378 |
| $`D(3)`$ | $`100 - 86.070798 - 8.161378`$ | $5.767824 |
| year 2 alone, $`\mathrm{PV}_2`$ | $`3.850448 - 1.926389`$ | $1.924060 |
| carry to payment, $`e^{0.05 \times 1.75}`$ | | 1.091442 |
| year-2 dividend future, $`F_2`$ | $`1.924060 \times 1.091442`$ | **$2.100000** |
| year-1 and year-3 futures, the same way | $`1.926389 \times 1.038212`$, $`1.917376 \times 1.147402`$ | $2.000000, $2.200000 |
| 3-year swap strike | $`2.000000 + 2.100000 + 2.200000`$ | **$6.300000** |

The options alone, with no dividend forecast, price Acme's year-2 dividend at exactly the $2.10 that built them, and a three-year dividend swap at $6.30. (The year-2 difference shows 1.924060 rather than 1.924059 because the inputs are rounded to six places.)

### What breaks if you drop a piece

Right answers: year-2 future $2.100000, swap strike $6.300000.

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Future quoted at the value today | $1.924060 | the future settles on the dividend's full amount, later; the value today is discounted |
| Carried to the year's end, not the payment date | $2.126415 | the dividend earns no interest between payment and settlement |
| Swap strike as the sum of values today | $5.767824 | the swap pays the dividends in full at the end |
| Swap strike as the values today carried to year 3 | $6.701255 | adds interest the swap never pays on dividends earned early |

### The dividend delta of long-dated options

Dividend delta of each Acme call at strike $100, in dollars of call price per $1 added to each year's dividend:

| Call | Year-1 dividend | Year-2 dividend | Year-3 dividend | Total |
| --- | ---: | ---: | ---: | ---: |
| 1-year | −0.5777 | 0 | 0 | −0.5777 |
| 2-year | −0.6156 | −0.5856 | 0 | −1.2012 |
| 3-year | −0.6435 | −0.6121 | −0.5823 | −1.8380 |

```
Total dividend delta of each call, dollars per $1 on every dividend
1-year  ██████                 -0.5777
2-year  ████████████           -1.2012
3-year  ██████████████████     -1.8380
```

Two things grow with the expiry. More dividends fall before it, and each one weighs more because $`N(d_1)`$ grows with time (0.668117 at three years). Cut all three dividends by 10% and the three-year call gains $0.387199; the deltas predict $0.385358. The three-year put has dividend deltas of +0.3197, +0.3041 and +0.2892: it gains when dividends rise.

---

## Code, from first principles, and it actually runs

The code prices Acme's options from a hidden dividend list, then reads the dividends back from the quotes alone. The strip and the futures come by two independent roads. Road 1 is parity solved at strike $100 from closed-form prices. Road 2 prices both options at strike $90 by brute force, averaging each payoff over the bell curve with Simpson's rule (adding thin slices), and solves parity there. Road 3 reads the forwards from parity and takes their differences; it rearranges Road 1's quotes, so it checks the forward reading rather than adding an independent answer. All three must agree, and the futures must equal the hidden list. The dividend deltas come two ways: the formula, and a bump of each dividend by a cent each way with the Simpson prices. The bell-curve area is `math.erf` in Python and a series written out in Rust.

### Python

```python
# Dividend futures and swaps -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the answer:
# the bell-curve area comes from math.erf, the brute-force prices are Simpson's rule
# written out, and the dividend list that built the quotes is checked, never reused.
from math import erf, exp, log, sqrt, pi

S, r, sig, K = 100.0, 0.05, 0.20, 100.0
DIVS = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.20)]       # (paid at, dollars): hidden truth
EXP = [1.0, 2.0, 3.0]                                   # option expiries, years

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def pv_divs(T, divs): return sum(d * exp(-r * t) for t, d in divs if t < T)
def d1(T, K, divs): return (log((S - pv_divs(T, divs)) / K) + (r + 0.5 * sig * sig) * T) / (sig * sqrt(T))
def bs(T, K, divs, b=0.0):                              # escrowed spot; fee b a year on the share's value
    Ss = S * exp(-b * T) - sum(d * exp(-r * t - b * (T - t)) for t, d in divs if t < T)
    a = (log(Ss / K) + (r + 0.5 * sig * sig) * T) / (sig * sqrt(T)); c = a - sig * sqrt(T)
    return Ss * N(a) - K * exp(-r * T) * N(c), K * exp(-r * T) * N(-c) - Ss * N(-a)
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def simpson_pair(T, K, divs):                           # road 2: both legs by brute force
    Ss, v = S - pv_divs(T, divs), sig * sqrt(T)         # no d1, no N: average the payoff
    ST = lambda z: Ss * exp((r - 0.5 * sig * sig) * T + v * z)
    phi = lambda z: exp(-0.5 * z * z) / sqrt(2 * pi)
    zk = (log(K / Ss) - (r - 0.5 * sig * sig) * T) / v  # where the payoff kinks
    c = simpson(lambda z: (ST(z) - K) * phi(z), zk, 9.0)
    p = simpson(lambda z: (K - ST(z)) * phi(z), -9.0, zk)
    return exp(-r * T) * c, exp(-r * T) * p

def strip(quotes, K):                                   # road 1: parity solved for the dividends
    return [S - K * exp(-r * T) - (C - P) for T, (C, P) in zip(EXP, quotes)]
def futures(Dcum, tpay):                                # difference, then carry to the pay date
    prev = [0.0] + Dcum[:-1]
    return [(a - b) * exp(r * t) for a, b, t in zip(Dcum, prev, tpay)]

quotes = [bs(T, K, DIVS) for T in EXP]
D1 = strip(quotes, K)
tpay = [t for t, _ in DIVS]
FUT = futures(D1, tpay)
for T, (C, P), D in zip(EXP, quotes, D1):
    print(f"expiry {T:.0f}y: call {C:.6f}  put {P:.6f}  C-P {C - P:.6f}  K e^-rT {K * exp(-r * T):.6f}  PV of dividends {D:.6f}")
for i, (a, f) in enumerate(zip([D1[0], D1[1] - D1[0], D1[2] - D1[1]], FUT)):
    print(f"year {i+1}: PV {a:.6f}  carry e^(r*{tpay[i]}) {exp(r*tpay[i]):.6f}  dividend future {f:.6f}")
    assert abs(f - DIVS[i][1]) < 1e-5                   # recovers the hidden dividend list
SWAP = sum(FUT)
print(f"3-year dividend swap fair strike {SWAP:.6f}")

# road 2: brute-force prices at a different strike, same parity inversion
D2 = strip([simpson_pair(T, 90.0, DIVS) for T in EXP], 90.0)
print("road 2, Simpson prices at strike 90: " + "  ".join(f"{x:.6f}" for x in D2))
assert all(abs(a - b) < 1e-5 for a, b in zip(D1, D2))
# road 3: forwards from parity, dividends from forward differences
F = [K + (C - P) * exp(r * T) for T, (C, P) in zip(EXP, quotes)]
prevF = [S] + F[:-1]
FUT3 = [(pf * exp(r) - f) * exp(-r * (T - t)) for pf, f, T, t in zip(prevF, F, EXP, tpay)]
print("road 3, forwards " + "  ".join(f"{x:.6f}" for x in F) + "  futures " + "  ".join(f"{x:.6f}" for x in FUT3))
assert all(abs(a - b) < 1e-9 for a, b in zip(FUT, FUT3))
assert abs(sum(FUT3) - sum(d for _, d in DIVS)) < 1e-5     # swap strike = the listed total

# dividend delta: dollars of option per $1 more on dividend i
print("dividend delta of the calls (rows: expiry; columns: year-1, year-2, year-3 dividend)")
for T in EXP:
    row = [-N(d1(T, K, DIVS)) * exp(-r * t) if t < T else 0.0 for t in tpay]
    bump = []
    for i in range(3):
        up = [(t, d + (0.01 if j == i else 0)) for j, (t, d) in enumerate(DIVS)]
        dn = [(t, d - (0.01 if j == i else 0)) for j, (t, d) in enumerate(DIVS)]
        bump.append((simpson_pair(T, K, up)[0] - simpson_pair(T, K, dn)[0]) / 0.02)
    assert all(abs(a - b) < 1e-4 for a, b in zip(row, bump))
    print(f"  {T:.0f}y call  formula " + " ".join(f"{x:+.4f}" for x in row) + "  bump " + " ".join(f"{x:+.4f}" for x in bump) + f"  total {sum(row):+.4f}")
row3 = [-N(d1(3.0, K, DIVS)) * exp(-r * t) for t in tpay]
cut = [(t, 0.9 * d) for t, d in DIVS]
gain = bs(3.0, K, cut)[0] - quotes[2][0]
print(f"3y call N(d1) {N(d1(3.0, K, DIVS)):.6f}; all dividends cut 10%: call gains {gain:.6f}, delta predicts {sum(-x * 0.1 * d for x, (t, d) in zip(row3, DIVS)):.6f}")
print("3y put dividend delta " + " ".join(f"{N(-d1(3.0, K, DIVS)) * exp(-r * t):+.4f}" for t in tpay))

# what breaks
print(f"break: future left at PV, year 2 {D1[1] - D1[0]:.6f}")
print(f"break: carried to year end, year 2 {(D1[1] - D1[0]) * exp(r * 2.0):.6f}")
print(f"break: swap strike as sum of PVs {D1[2]:.6f}; carried to year 3 {D1[2] * exp(3 * r):.6f}")
qb = [bs(T, K, DIVS, b=0.01) for T in EXP]
Fb = futures(strip(qb, K), tpay)
print("break: 1% borrow fee read as dividends, futures " + "  ".join(f"{x:.6f}" for x in Fb))
assert Fb[1] - FUT[1] > 0.9                             # the fee shows up as about $1 a year
print(f"house: forward with borrow {S * exp(0.02):.4f}, without {S * exp(0.03):.4f}")

# try changing
q120 = [bs(T, 120.0, DIVS) for T in EXP]
print("try: strike 120 strip " + "  ".join(f"{x:.6f}" for x in strip(q120, 120.0)))
hi = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.50)]
print(f"try: year-3 dividend 2.50: 3y call {bs(3.0, K, hi)[0]:.6f} from {quotes[2][0]:.6f}")
print("try: strike 80: 3y call delta " + " ".join(f"{-N(d1(3.0, 80.0, DIVS)) * exp(-r * t):+.4f}" for t in tpay) + "  full short " + " ".join(f"{-exp(-r * t):+.4f}" for t in tpay))
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
expiry 1y: call 9.259211  put 6.308542  C-P 2.950669  K e^-rT 95.122942  PV of dividends 1.926389
expiry 2y: call 13.566895  put 7.901085  C-P 5.665810  K e^-rT 90.483742  PV of dividends 3.850448
expiry 3y: call 16.894352  put 8.732974  C-P 8.161378  K e^-rT 86.070798  PV of dividends 5.767824
year 1: PV 1.926389  carry e^(r*0.75) 1.038212  dividend future 2.000000
year 2: PV 1.924060  carry e^(r*1.75) 1.091442  dividend future 2.100000
year 3: PV 1.917376  carry e^(r*2.75) 1.147402  dividend future 2.200000
3-year dividend swap fair strike 6.300000
road 2, Simpson prices at strike 90: 1.926389  3.850448  5.767824
road 3, forwards 103.101953  106.261688  109.482169  futures 2.000000  2.100000  2.200000
dividend delta of the calls (rows: expiry; columns: year-1, year-2, year-3 dividend)
  1y call  formula -0.5777 +0.0000 +0.0000  bump -0.5777 +0.0000 +0.0000  total -0.5777
  2y call  formula -0.6156 -0.5856 +0.0000  bump -0.6156 -0.5856 +0.0000  total -1.2012
  3y call  formula -0.6435 -0.6121 -0.5823  bump -0.6435 -0.6121 -0.5823  total -1.8380
3y call N(d1) 0.668117; all dividends cut 10%: call gains 0.387199, delta predicts 0.385358
3y put dividend delta +0.3197 +0.3041 +0.2892
break: future left at PV, year 2 1.924060
break: carried to year end, year 2 2.126415
break: swap strike as sum of PVs 5.767824; carried to year 3 6.701255
break: 1% borrow fee read as dividends, futures 3.028044  3.149085  3.269952
house: forward with borrow 102.0201, without 103.0455
try: strike 120 strip 1.926389  3.850448  5.767824
try: year-3 dividend 2.50: 3y call 16.720047 from 16.894352
try: strike 80: 3y call delta -0.8280 -0.7877 -0.7492  full short -0.9632 -0.9162 -0.8715
ALL CHECKS PASS
```

### Rust

```rust
// Dividend futures and swaps -- the check behind the card.  std only, no crates.
// Every number quoted on the card is printed here.  Nothing imported knows the answer:
// the bell-curve area is a series written out, the brute-force prices are Simpson's
// rule written out, and the dividend list that built the quotes is checked, never reused.
const S: f64 = 100.0;
const R: f64 = 0.05;
const SIG: f64 = 0.20;
const K: f64 = 100.0;
const EXP: [f64; 3] = [1.0, 2.0, 3.0]; // option expiries, years
type Divs = [(f64, f64); 3]; // (paid at, dollars)
const DIVS: Divs = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.20)]; // hidden truth

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn n(x: f64) -> f64 { // x + x^3/3 + x^5/(3*5) + ..., times the bell-curve height
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while s + t * x * x / (2.0 * k + 1.0) != s { t *= x * x / (2.0 * k + 1.0); s += t; k += 1.0; }
    0.5 + s * phi(x)
}
fn pv_divs(t_exp: f64, d: &Divs) -> f64 { d.iter().filter(|p| p.0 < t_exp).map(|p| p.1 * (-R * p.0).exp()).sum() }
fn d1(t: f64, k: f64, d: &Divs) -> f64 { (((S - pv_divs(t, d)) / k).ln() + (R + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt()) }
fn bs(t: f64, k: f64, d: &Divs, b: f64) -> (f64, f64) { // escrowed spot; fee b a year on the share's value
    let ss = S * (-b * t).exp() - d.iter().filter(|p| p.0 < t).map(|p| p.1 * (-R * p.0 - b * (t - p.0)).exp()).sum::<f64>();
    let a = ((ss / k).ln() + (R + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt());
    let c = a - SIG * t.sqrt();
    (ss * n(a) - k * (-R * t).exp() * n(c), k * (-R * t).exp() * n(-c) - ss * n(-a))
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let m = 2000; let h = (b - a) / m as f64;
    let w = |i: usize| if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=m).map(|i| w(i) * f(a + i as f64 * h)).sum::<f64>()
}
fn simpson_pair(t: f64, k: f64, d: &Divs) -> (f64, f64) { // road 2: both legs by brute force
    let (ss, v) = (S - pv_divs(t, d), SIG * t.sqrt());
    let st = |z: f64| ss * ((R - 0.5 * SIG * SIG) * t + v * z).exp();
    let zk = ((k / ss).ln() - (R - 0.5 * SIG * SIG) * t) / v; // where the payoff kinks
    let c = simpson(|z| (st(z) - k) * phi(z), zk, 9.0);
    let p = simpson(|z| (k - st(z)) * phi(z), -9.0, zk);
    ((-R * t).exp() * c, (-R * t).exp() * p)
}
fn strip(q: &[(f64, f64)], k: f64) -> Vec<f64> { // road 1: parity solved for the dividends
    EXP.iter().zip(q).map(|(t, (c, p))| S - k * (-R * t).exp() - (c - p)).collect()
}
fn futures(dc: &[f64], tpay: &[f64]) -> Vec<f64> { // difference, then carry to the pay date
    (0..3).map(|i| (dc[i] - if i == 0 { 0.0 } else { dc[i - 1] }) * (R * tpay[i]).exp()).collect()
}
fn join(v: &[f64], f: fn(&f64) -> String, sep: &str) -> String { v.iter().map(f).collect::<Vec<_>>().join(sep) }
fn f6(x: &f64) -> String { format!("{:.6}", x) }
fn s4(x: &f64) -> String { format!("{:+.4}", x) }

fn main() {
    let quotes: Vec<(f64, f64)> = EXP.iter().map(|&t| bs(t, K, &DIVS, 0.0)).collect();
    let dd = strip(&quotes, K);
    let tpay: Vec<f64> = DIVS.iter().map(|p| p.0).collect();
    let fut = futures(&dd, &tpay);
    for i in 0..3 {
        let (c, p) = quotes[i];
        println!("expiry {:.0}y: call {:.6}  put {:.6}  C-P {:.6}  K e^-rT {:.6}  PV of dividends {:.6}", EXP[i], c, p, c - p, K * (-R * EXP[i]).exp(), dd[i]);
    }
    let pvs = [dd[0], dd[1] - dd[0], dd[2] - dd[1]];
    for i in 0..3 {
        println!("year {}: PV {:.6}  carry e^(r*{}) {:.6}  dividend future {:.6}", i + 1, pvs[i], tpay[i], (R * tpay[i]).exp(), fut[i]);
        assert!((fut[i] - DIVS[i].1).abs() < 1e-5); // recovers the hidden dividend list
    }
    println!("3-year dividend swap fair strike {:.6}", fut.iter().sum::<f64>());

    // road 2: brute-force prices at a different strike, same parity inversion
    let q90: Vec<(f64, f64)> = EXP.iter().map(|&t| simpson_pair(t, 90.0, &DIVS)).collect();
    let d2 = strip(&q90, 90.0);
    println!("road 2, Simpson prices at strike 90: {}", join(&d2, f6, "  "));
    assert!((0..3).all(|i| (dd[i] - d2[i]).abs() < 1e-5));
    // road 3: forwards from parity, dividends from forward differences
    let f: Vec<f64> = (0..3).map(|i| K + (quotes[i].0 - quotes[i].1) * (R * EXP[i]).exp()).collect();
    let fut3: Vec<f64> = (0..3).map(|i| {
        let pf = if i == 0 { S } else { f[i - 1] };
        (pf * R.exp() - f[i]) * (-R * (EXP[i] - tpay[i])).exp()
    }).collect();
    println!("road 3, forwards {}  futures {}", join(&f, f6, "  "), join(&fut3, f6, "  "));
    assert!((0..3).all(|i| (fut[i] - fut3[i]).abs() < 1e-9));
    assert!((fut3.iter().sum::<f64>() - DIVS.iter().map(|p| p.1).sum::<f64>()).abs() < 1e-5); // swap strike = listed total

    // dividend delta: dollars of option per $1 more on dividend i
    println!("dividend delta of the calls (rows: expiry; columns: year-1, year-2, year-3 dividend)");
    for &t in EXP.iter() {
        let row: Vec<f64> = tpay.iter().map(|&tp| if tp < t { -n(d1(t, K, &DIVS)) * (-R * tp).exp() } else { 0.0 }).collect();
        let bump: Vec<f64> = (0..3).map(|i| {
            let (mut up, mut dn) = (DIVS, DIVS);
            up[i].1 += 0.01; dn[i].1 -= 0.01;
            (simpson_pair(t, K, &up).0 - simpson_pair(t, K, &dn).0) / 0.02
        }).collect();
        assert!((0..3).all(|i| (row[i] - bump[i]).abs() < 1e-4));
        println!("  {:.0}y call  formula {}  bump {}  total {:+.4}", t, join(&row, s4, " "), join(&bump, s4, " "), row.iter().sum::<f64>());
    }
    let nd = n(d1(3.0, K, &DIVS));
    let row3: Vec<f64> = tpay.iter().map(|&tp| -nd * (-R * tp).exp()).collect();
    let mut cut = DIVS;
    for p in cut.iter_mut() { p.1 *= 0.9; }
    let gain = bs(3.0, K, &cut, 0.0).0 - quotes[2].0;
    let pred: f64 = (0..3).map(|i| -row3[i] * 0.1 * DIVS[i].1).sum();
    println!("3y call N(d1) {:.6}; all dividends cut 10%: call gains {:.6}, delta predicts {:.6}", nd, gain, pred);
    let putd: Vec<f64> = tpay.iter().map(|&tp| n(-d1(3.0, K, &DIVS)) * (-R * tp).exp()).collect();
    println!("3y put dividend delta {}", join(&putd, s4, " "));

    // what breaks
    println!("break: future left at PV, year 2 {:.6}", dd[1] - dd[0]);
    println!("break: carried to year end, year 2 {:.6}", (dd[1] - dd[0]) * (R * 2.0).exp());
    println!("break: swap strike as sum of PVs {:.6}; carried to year 3 {:.6}", dd[2], dd[2] * (3.0 * R).exp());
    let qb: Vec<(f64, f64)> = EXP.iter().map(|&t| bs(t, K, &DIVS, 0.01)).collect();
    let fb = futures(&strip(&qb, K), &tpay);
    println!("break: 1% borrow fee read as dividends, futures {}", join(&fb, f6, "  "));
    assert!(fb[1] - fut[1] > 0.9); // the fee shows up as about $1 a year
    println!("house: forward with borrow {:.4}, without {:.4}", S * 0.02f64.exp(), S * 0.03f64.exp());

    // try changing
    let q120: Vec<(f64, f64)> = EXP.iter().map(|&t| bs(t, 120.0, &DIVS, 0.0)).collect();
    println!("try: strike 120 strip {}", join(&strip(&q120, 120.0), f6, "  "));
    let hi: Divs = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.50)];
    println!("try: year-3 dividend 2.50: 3y call {:.6} from {:.6}", bs(3.0, K, &hi, 0.0).0, quotes[2].0);
    let d80: Vec<f64> = tpay.iter().map(|&tp| -n(d1(3.0, 80.0, &DIVS)) * (-R * tp).exp()).collect();
    let full: Vec<f64> = tpay.iter().map(|&tp| -(-R * tp).exp()).collect();
    println!("try: strike 80: 3y call delta {}  full short {}", join(&d80, s4, " "), join(&full, s4, " "));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
expiry 1y: call 9.259211  put 6.308542  C-P 2.950669  K e^-rT 95.122942  PV of dividends 1.926389
expiry 2y: call 13.566895  put 7.901085  C-P 5.665810  K e^-rT 90.483742  PV of dividends 3.850448
expiry 3y: call 16.894352  put 8.732974  C-P 8.161378  K e^-rT 86.070798  PV of dividends 5.767824
year 1: PV 1.926389  carry e^(r*0.75) 1.038212  dividend future 2.000000
year 2: PV 1.924060  carry e^(r*1.75) 1.091442  dividend future 2.100000
year 3: PV 1.917376  carry e^(r*2.75) 1.147402  dividend future 2.200000
3-year dividend swap fair strike 6.300000
road 2, Simpson prices at strike 90: 1.926389  3.850448  5.767824
road 3, forwards 103.101953  106.261688  109.482169  futures 2.000000  2.100000  2.200000
dividend delta of the calls (rows: expiry; columns: year-1, year-2, year-3 dividend)
  1y call  formula -0.5777 +0.0000 +0.0000  bump -0.5777 +0.0000 +0.0000  total -0.5777
  2y call  formula -0.6156 -0.5856 +0.0000  bump -0.6156 -0.5856 +0.0000  total -1.2012
  3y call  formula -0.6435 -0.6121 -0.5823  bump -0.6435 -0.6121 -0.5823  total -1.8380
3y call N(d1) 0.668117; all dividends cut 10%: call gains 0.387199, delta predicts 0.385358
3y put dividend delta +0.3197 +0.3041 +0.2892
break: future left at PV, year 2 1.924060
break: carried to year end, year 2 2.126415
break: swap strike as sum of PVs 5.767824; carried to year 3 6.701255
break: 1% borrow fee read as dividends, futures 3.028044  3.149085  3.269952
house: forward with borrow 102.0201, without 103.0455
try: strike 120 strip 1.926389  3.850448  5.767824
try: year-3 dividend 2.50: 3y call 16.720047 from 16.894352
try: strike 80: 3y call delta -0.8280 -0.7877 -0.7492  full short -0.9632 -0.9162 -0.8715
ALL CHECKS PASS
```

### Lean

Lean proves the card's three main results for any quotes and dividends, and checks the hand arithmetic exactly.

- Suppose parity holds at every expiry, and each $`\mathrm{PV}_i = e^{-r t_i} F_i`$. Then $`D(T)`$ read from the quotes is the dividends' value today before $`T`$.
- Take the same conditions. Then each difference of the strip, carried to its payment date, equals that year's dividend future $`F_i`$.
- Take the same conditions. Then a dividend swap over years 1 to $`n`$ is worth zero exactly when $`K_{\mathrm{swap}} = F_1 + \dots + F_n`$.
- Take the escrowed model with $`S^{*}`$, $`K`$, the volatility and $`T`$ all positive. Then $`\Delta_i = -N(d_1)\, e^{-r t_i}`$ for each dividend paid before $`T`$.
- The worked numbers come out exactly: the three $`C - P`$ gaps, the strip, the $6.30 swap strike and the 2-year call's total delta.

The option prices, carry factors, Simpson road, put deltas and borrow fee are left to the Python and Rust checks.

```lean
-- Dividend futures and swaps: put-call parity at each expiry gives the value today of the dividends before it, the difference of two expiries carried to the payment date is the fair dividend future, the futures summed are the fair dividend swap strike, and in the escrowed model a call's dividend delta is -N(d₁)e^(-r tᵢ).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real MeasureTheory ProbabilityTheory Finset

/-! Notation, as on the card, counting years from 0 in Lean. `S` is Acme's price today, `K` the
strike both options share, `r` the bank rate (continuously compounded). Expiry number `n + 1` is
at `T (n + 1)` years, with call `C (n + 1)` and put `P (n + 1)` quoted there; expiry 0 is today.
Year `i` (`i = 0, 1, 2, …`, the card's year `i + 1`) runs from expiry `i` to expiry `i + 1`; its
dividend is paid at `t i` years, `pv i` is its value today and `F i` the fair price of its dividend
future, the dividend's risk-neutral average. So the dividends paid before expiry `n` are years
`0, …, n - 1`, and their value today is `∑ i ∈ range n, pv i`. -/

/-- The implied dividend strip read from the quotes: `D(T₀) = 0` and
`D(T_n) = S - K e^(-r T_n) - (C(T_n) - P(T_n))` at each quoted expiry. -/
noncomputable def impliedStrip (S K r : ℝ) (T C P : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | n + 1 => S - K * exp (-r * T (n + 1)) - (C (n + 1) - P (n + 1))

/-- The year-`i` dividend future read from the strip: `F_i = (D(T_{i+1}) - D(T_i)) e^(r tᵢ)`. -/
noncomputable def futureFromStrip (S K r : ℝ) (T C P t : ℕ → ℝ) (i : ℕ) : ℝ :=
  (impliedStrip S K r T C P (i + 1) - impliedStrip S K r T C P i) * exp (r * t i)

/-- **The card's main claim** (The formula; Steps 1 to 3). Suppose put-call parity holds at every
expiry, `C(T_n) - P(T_n) = S - (value today of the dividends before T_n) - K e^(-r T_n)` (European
options quoted together, a share that costs nothing to borrow), and that with known payment dates
and a known bank rate each year's dividend is worth today its futures price discounted from its
payment date, `PVᵢ = e^(-r tᵢ) Fᵢ`. Then the strip read from the quotes is the value today of the
dividends before each expiry, `D(T_n) = PV₁ + … + PV_n`, and each difference of the strip carried
forward to its payment date is that year's fair dividend future: `(D(T_i) - D(T_{i-1})) e^(r tᵢ) = Fᵢ`. -/
theorem dividend_future_from_parity_strip (S K r : ℝ) (T C P t pv F : ℕ → ℝ)
    (h_parity : ∀ n, C (n + 1) - P (n + 1) = S - ∑ i ∈ range (n + 1), pv i - K * exp (-r * T (n + 1)))
    (h_price : ∀ i, pv i = exp (-r * t i) * F i) :
    (∀ n, impliedStrip S K r T C P n = ∑ i ∈ range n, pv i) ∧
      ∀ i, futureFromStrip S K r T C P t i = F i := by
  have h1 : ∀ n, impliedStrip S K r T C P n = ∑ i ∈ range n, pv i := by
    intro n
    cases n with
    | zero => simp [impliedStrip]
    | succ n => simp only [impliedStrip]; rw [h_parity n]; ring
  refine ⟨h1, fun i => ?_⟩
  rw [futureFromStrip, h1, h1, sum_range_succ, h_price i]
  rw [show (∑ x ∈ range i, pv x + exp (-r * t i) * F i - ∑ x ∈ range i, pv x) * exp (r * t i)
      = F i * (exp (-r * t i) * exp (r * t i)) by ring, ← exp_add]
  simp

/-- **A swap is a bundle of futures** (Step 4). Under the same hypotheses, a dividend swap over
years 1 to `n` pays `div₁ + … + div_n - K_swap` at its end `T_n`; its value today is
`e^(-r T_n) (F₁ + … + F_n - K_swap)`. It is fair (worth zero) exactly when the strike is the sum
of the futures read from the strip: `K_swap = F₁ + … + F_n`. -/
theorem dividend_swap_strike_eq_sum_of_futures (S K r : ℝ) (T C P t pv F : ℕ → ℝ)
    (h_parity : ∀ n, C (n + 1) - P (n + 1) = S - ∑ i ∈ range (n + 1), pv i - K * exp (-r * T (n + 1)))
    (h_price : ∀ i, pv i = exp (-r * t i) * F i) (n : ℕ) (Kswap : ℝ) :
    exp (-r * T n) * (∑ i ∈ range n, F i - Kswap) = 0 ↔
      Kswap = ∑ i ∈ range n, futureFromStrip S K r T C P t i := by
  have h := (dividend_future_from_parity_strip S K r T C P t pv F h_parity h_price).2
  simp_rw [h]
  rw [mul_eq_zero, or_iff_right (exp_pos _).ne', sub_eq_zero, eq_comm]

/-! The dividend delta (Step 5 and its detailed proof). This part needs a model: the escrowed
Black–Scholes model of the card "Known cash dividends", with the volatility on the share net of
the dividends' value today. -/

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The escrowed share with `n` cash dividends before expiry, `div j` paid at `t j`:
`S* = S - ∑_{j<n} div_j e^(-r t_j)`. -/
noncomputable def escrowedSpot (S r : ℝ) (t div : ℕ → ℝ) (n : ℕ) : ℝ :=
  S - ∑ j ∈ range n, div j * exp (-r * t j)

/-- The first distance with no yield, `d₁ = (ln(S*/K) + (r + σ²/2) T) / (σ√T)`. -/
noncomputable def bsD1 (Sstar K r σ T : ℝ) : ℝ :=
  (log (Sstar / K) + (r + σ ^ 2 / 2) * T) / (σ * √T)

/-- The escrowed call: `C = S* N(d₁) - K e^(-rT) N(d₂)`, with `d₂ = d₁ - σ√T`. -/
noncomputable def escrowedCall (S K r σ T : ℝ) (t div : ℕ → ℝ) (n : ℕ) : ℝ :=
  escrowedSpot S r t div n * stdNormalCDF (bsD1 (escrowedSpot S r t div n) K r σ T)
    - K * exp (-r * T) * stdNormalCDF (bsD1 (escrowedSpot S r t div n) K r σ T - σ * √T)


/-- The standard normal density, written out. -/
lemma dfs_phi_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma dfs_phi_continuous : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma dfs_N_eq_integral (x : ℝ) : stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma dfs_N_sub (a b : ℝ) :
    stdNormalCDF b - stdNormalCDF a = ∫ t in a..b, gaussianPDFReal 0 1 t := by
  rw [dfs_N_eq_integral, dfs_N_eq_integral]
  exact intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn

lemma dfs_N_hasDerivAt (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have h : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y; rw [← dfs_N_sub]; ring
  rw [h]
  exact (intervalIntegral.integral_hasDerivAt_right (dfs_phi_continuous.intervalIntegrable _ _)
    (dfs_phi_continuous.stronglyMeasurableAtFilter _ _)
    dfs_phi_continuous.continuousAt).const_add _

/-- The cancellation behind delta: `K e^(-rT) φ(d₂) = S* φ(d₁)`. -/
lemma dfs_key (S K r σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K * exp (-r * T) * gaussianPDFReal 0 1 (bsD1 S K r σ T - σ * √T)
      = S * gaussianPDFReal 0 1 (bsD1 S K r σ T) := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  set d := bsD1 S K r σ T with hd_def
  have hd : d * (σ * √T) = log (S / K) + (r + σ ^ 2 / 2) * T := by
    rw [hd_def, bsD1]; field_simp
  have hexp : -(d - σ * √T) ^ 2 / 2 + -r * T = -d ^ 2 / 2 + log (S / K) := by
    linear_combination hd - (σ ^ 2 / 2) * hsq
  rw [dfs_phi_eq, dfs_phi_eq]
  rw [show K * exp (-r * T) * ((√(2 * π))⁻¹ * exp (-(d - σ * √T) ^ 2 / 2))
      = (√(2 * π))⁻¹ * K * exp (-(d - σ * √T) ^ 2 / 2 + -r * T) by rw [exp_add]; ring,
    hexp, exp_add, exp_log (div_pos hS hK)]
  field_simp

/-- The no-yield call's slope in the (escrowed) share price is `N(d₁)`. -/
lemma dfs_call_hasDerivAt_spot (S K r σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun s => s * stdNormalCDF (bsD1 s K r σ T)
        - K * exp (-r * T) * stdNormalCDF (bsD1 s K r σ T - σ * √T))
      (stdNormalCDF (bsD1 S K r σ T)) S := by
  have hd1 : HasDerivAt (fun x => bsD1 x K r σ T) ((1 / K) / (S / K) / (σ * √T)) S := by
    have h := ((((hasDerivAt_id' S).div_const K).log (div_pos hS hK).ne').add_const
      ((r + σ ^ 2 / 2) * T)).div_const (σ * √T)
    simpa [bsD1] using h
  have hC := ((hasDerivAt_id S).mul ((dfs_N_hasDerivAt _).comp S hd1)).sub
    (((dfs_N_hasDerivAt _).comp S (hd1.sub_const (σ * √T))).const_mul (K * exp (-r * T)))
  have key := dfs_key S K r σ T hS hK hσ hT
  convert hC using 1
  · funext x; simp [Function.comp]
  · simp only [id, Function.comp]
    linear_combination ((1 / K) / (S / K) / (σ * √T)) * key

/-- **Dividend delta of a call** (The formula; Step 5). In the escrowed model, with a positive
escrowed share, strike, volatility and time to expiry, raising any one dividend `divᵢ` paid before
expiry changes the call at the rate `Δᵢ = ∂C/∂divᵢ = -N(d₁) e^(-r tᵢ)`. -/
theorem call_dividend_delta (S K r σ T : ℝ) (t div : ℕ → ℝ) (n i : ℕ) (hi : i < n)
    (hS : 0 < escrowedSpot S r t div n) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => escrowedCall S K r σ T t (Function.update div i x) n)
      (-(stdNormalCDF (bsD1 (escrowedSpot S r t div n) K r σ T)) * exp (-r * t i)) (div i) := by
  set s0 := escrowedSpot S r t div n with hs0
  have hspot : ∀ x, escrowedSpot S r t (Function.update div i x) n
      = s0 - (x - div i) * exp (-r * t i) := by
    intro x
    have hmem : i ∈ range n := mem_range.2 hi
    simp only [hs0, escrowedSpot]
    rw [← add_sum_erase _ _ hmem, ← add_sum_erase _ _ hmem]
    have : ∑ j ∈ (range n).erase i, Function.update div i x j * exp (-r * t j)
        = ∑ j ∈ (range n).erase i, div j * exp (-r * t j) := by
      refine sum_congr rfl fun j hj => ?_
      rw [Function.update_of_ne (ne_of_mem_erase hj)]
    rw [this, Function.update_self]
    ring
  have hin : HasDerivAt (fun x => s0 - (x - div i) * exp (-r * t i)) (-exp (-r * t i)) (div i) := by
    have := ((hasDerivAt_id (div i)).sub_const (div i)).mul_const (exp (-r * t i)) |>.const_sub s0
    simpa using this
  have hval : s0 - (div i - div i) * exp (-r * t i) = s0 := by ring
  have hg := dfs_call_hasDerivAt_spot s0 K r σ T hS hK hσ hT
  rw [← hval] at hg
  have hc := hg.comp (div i) hin
  convert hc using 1
  · funext x; simp only [Function.comp, escrowedCall, hspot]
  · rw [hval]; ring

/-! The card's worked numbers, exactly, in millionths of a dollar. -/

-- 1-year gap C - P: 9.259211 - 6.308542 = 2.950669.
example : (9259211 : ℤ) - 6308542 = 2950669 := by norm_num
-- D(1) = 100 - 95.122942 - 2.950669 = 1.926389.
example : (100000000 : ℤ) - 95122942 - 2950669 = 1926389 := by norm_num
-- 2-year gap 13.566895 - 7.901085 = 5.665810, and D(2) = 100 - 90.483742 - 5.665810 = 3.850448.
example : (13566895 : ℤ) - 7901085 = 5665810 := by norm_num
example : (100000000 : ℤ) - 90483742 - 5665810 = 3850448 := by norm_num
-- 3-year gap 16.894352 - 8.732974 = 8.161378, and D(3) = 100 - 86.070798 - 8.161378 = 5.767824.
example : (16894352 : ℤ) - 8732974 = 8161378 := by norm_num
example : (100000000 : ℤ) - 86070798 - 8161378 = 5767824 := by norm_num
-- 3-year swap strike: 2.000000 + 2.100000 + 2.200000 = 6.300000.
example : (2000000 : ℤ) + 2100000 + 2200000 = 6300000 := by norm_num
-- Dividend delta table, total for the 2-year call: -0.6156 - 0.5856 = -1.2012 (ten-thousandths).
example : (-6156 : ℤ) - 5856 = -12012 := by norm_num

#print axioms dividend_future_from_parity_strip
#print axioms dividend_swap_strike_eq_sum_of_futures
#print axioms dfs_phi_eq
#print axioms dfs_phi_continuous
#print axioms dfs_N_eq_integral
#print axioms dfs_N_sub
#print axioms dfs_N_hasDerivAt
#print axioms dfs_key
#print axioms dfs_call_hasDerivAt_spot
#print axioms call_dividend_delta
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'dividend_future_from_parity_strip' depends on axioms: [propext, Classical.choice, Quot.sound]
'dividend_swap_strike_eq_sum_of_futures' depends on axioms: [propext, Classical.choice, Quot.sound]
'dfs_phi_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'dfs_phi_continuous' depends on axioms: [propext, Classical.choice, Quot.sound]
'dfs_N_eq_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'dfs_N_sub' depends on axioms: [propext, Classical.choice, Quot.sound]
'dfs_N_hasDerivAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'dfs_key' depends on axioms: [propext, Classical.choice, Quot.sound]
'dfs_call_hasDerivAt_spot' depends on axioms: [propext, Classical.choice, Quot.sound]
'call_dividend_delta' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Read the strip from strike $120 instead of $100.** Guess whether a deep out-of-the-money call changes it. It does not: 1.926389, 3.850448, 5.767824 again, because parity holds at every strike.
> - **Raise the year-3 dividend from $2.20 to $2.50.** Guess the three-year call. It falls from $16.894352 to $16.720047, close to $0.30 times the delta of −0.5823.
> - **Use strike $80 for the dividend delta.** Guess whether a deep in-the-money call is more exposed. It is: −0.8280, −0.7877 and −0.7492, most of the way to a full short position in the dividends, which would be −0.9632, −0.9162 and −0.8715.
> - **Put a 1% borrow fee into the option prices.** Guess the year-2 future read from them. It comes out at $3.149085: the fee, about $1 a year, poses as dividend.

---

## The usual mistake

> [!warning]
> **Reading the options' strip as pure dividends.** Parity returns everything that makes holding the share differ from holding a forward. That is the dividends, plus any borrow fee, plus early-exercise value if the options are American. A 1% borrow fee on Acme turns the year-2 future from $2.10 into $3.149085. Before a strip is traded as dividends, the fee must be measured and taken out.
>
> - **Quoting the future at the value today.** Year 2 comes out at $1.924060, not $2.10. The future settles on the dividend's full amount.
> - **Carrying to the contract's last day.** Year 2 comes out at $2.126415. The carry runs to the payment date.
> - **Adding values today for a swap strike.** $5.767824 instead of $6.30. Carrying that sum to the swap's end overshoots instead: $6.701255.
> - **Getting the sign of the risk wrong.** A long call is short dividends: the three-year call loses $1.84 per $1 on every dividend. A long put is long dividends.

---

## Where you meet it in real life

- **Index dividend futures.** Exchanges list dividend futures on major stock indices, each settling on the index dividends of one year. They let anyone hold dividends without the shares.
- **Structured product desks.** Banks that sell long-dated notes linked to an index end up exposed to that index's dividends through the options inside the notes. They sell dividend swaps and futures to lay that risk off.
- **Long-dated options books.** Desks track dividend delta beside share delta and rho. The [Rho and dividend rho](../09-The%20Greeks%2C%20one%20each/05-rho-and-dividend-rho.md) card measures the same risk as a yield; this card measures it per cash dividend.
- **Research on how the market prices time.** Studies recover the price of near-term index dividends from option parity, exactly as Step 1 does, and compare short-dated with long-dated dividend claims.
- **Checking the dividend input.** Before pricing a long-dated option, a desk compares the strip read from options with its dividend forecast. A gap points to a borrow fee or a stale quote.

> **Say it back**
> A share is its dividends plus a forward, and a call minus a put at one strike is that forward. So parity at each expiry gives the value today of the dividends before it, with no model: $1.93, $3.85 and $5.77 for Acme. Differences give each year alone, and carrying each to its payment date gives the dividend future: $2.00, $2.10 and $2.20. A dividend swap's fair strike is the futures summed, $6.30. Long-dated calls are short dividends, about $1.84 per $1 for a three-year Acme call, and the dividend future is the hedge.

---

## What this builds on

- [Implied forward and dividend from parity](../11-Implied%20volatility%20and%20the%20vanilla%20inverses/05-implied-forward-and-dividend-from-parity.md): reading the forward and the carry from one call-put pair. This card repeats it across expiries.
- [Known cash dividends](../08-The%20Black-Scholes%20call%20and%20put/08-known-cash-dividends.md): parity with a cash dividend, and the escrowed model behind the dividend delta.
- [Stock borrow and repo](01-stock-borrow-repo-and-the-equity-forward.md): the borrow fee that sits in the forward beside the dividends and must be separated from them.
- [Rho and dividend rho](../09-The%20Greeks%2C%20one%20each/05-rho-and-dividend-rho.md): dividend risk measured as a yield sensitivity, the continuous version of this card's dividend delta.
- [Total return swaps](02-equity-swaps-and-total-return-swaps.md): a swap that hands over the share's price change and its dividends together. A dividend swap hands over only the dividend leg.

## Where this goes next

This card closes the shelf.

The question it leaves open: when dividends are partly fixed in cash and partly proportional to the share price, how does that mix bend the volatility smile of long-dated options?

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- van Binsbergen, Jules, Michael Brandt, and Ralph Koijen. "On the Timing and Pricing of Dividends." *American Economic Review* 102, no. 4 (2012): 1596–1618. [doi:10.1257/aer.102.4.1596](https://doi.org/10.1257/aer.102.4.1596). Recovers the prices of near-term index dividend claims from option parity, as in Step 1.
- Manley, Richard, and Christian Mueller-Glissmann. "The Market for Dividends and Related Investment Strategies." *Financial Analysts Journal* 64, no. 3 (2008): 17–29. [doi:10.2469/faj.v64.n3.4](https://doi.org/10.2469/faj.v64.n3.4). Describes dividend swaps and futures, and why structured product desks supply dividend risk to the market.
- Kragt, Jac, Frank de Jong, and Joost Driessen. "The Dividend Term Structure." *Journal of Financial and Quantitative Analysis* 55, no. 3 (2020): 829–867. [doi:10.1017/S002210901900036X](https://doi.org/10.1017/S002210901900036X). Studies the prices of dividends at each maturity from dividend futures, the strip of this card.
- Buehler, Hans. "Volatility and Dividends: Volatility Modelling with Cash Dividends and Simple Credit Risk." SSRN working paper (2008). [doi:10.2139/ssrn.1141877](https://doi.org/10.2139/ssrn.1141877). Shows how cash and proportional dividends change long-dated option prices: the open question above.
- Hull, John C. *Options, Futures, and Other Derivatives*, 11th ed. Pearson. [Publisher page](https://www.pearson.com/en-us/subject-catalog/p/options-futures-and-other-derivatives/P200000005938). Put-call parity with known dividends, and why futures and forward prices agree when rates are known.
