# The exchange option: the right to swap one share for another, priced with no interest rate at all

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Many underlyings - exchange, spread, basket and rainbow](../README.md#s18) → The exchange option

---

## General Overview

Two companies, Acme and Birch, each have shares trading at $100 today. Each share moves about 20 percent a year, each pays a 2 percent dividend, and the two tend to move together: their correlation, a score from −1 (always opposite) to +1 (always together), is 0.5.

A contract says: one year from today, the holder may hand over one Birch share and receive one Acme share. The holder does it only if Acme is then worth more than Birch. If Acme ends at $120 and Birch at $110, the swap earns $10. If Acme ends below Birch, the holder walks away. That right is an **exchange option**, the name used from here on.

It looks like a call option on Acme (the right, but not the duty, to buy Acme at expiry) whose strike, the price paid on exercise, is not a fixed sum of cash but a Birch share. A moving strike sounds harder to price.

William Margrabe showed in 1978 that it is easier. Measure everything in Birch shares, and the contract becomes an ordinary call on one number, the price of Acme in Birch shares, with a strike of exactly one. In that unit the bank rate vanishes: a Birch share earns nothing measured against itself. The answer for Acme and Birch is **$7.81**, and the bank rate appears nowhere in it.

**Counted in units of the second share, the exchange option is a Black-Scholes call on the ratio of the two prices with a strike of one and no interest rate, and the ratio's volatility is the combined wiggle of the two shares net of what they share.**

**What kind of fact this is:** a theorem inside the Black-Scholes model, proved on this card in Why it works; the model itself, two lognormal prices with a fixed correlation, is an assumption, not a law. A price is lognormal when its log is bell-curved.

### The picture: what the holder walks away with

The payoff depends on both prices at once. Fix Birch's closing price, and the contract is a call on Acme struck at that price. The chart shows profit after the $7.81 premium, for two ways Birch could end the year.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Exchange option: profit at expiry after the $7.81 premium"
    x-axis "Acme's price at expiry ($)" [80, 85, 90, 95, 100, 105, 110, 115, 120, 125, 130]
    y-axis "Profit or loss ($)" -10 --> 25
    line [-7.81, -7.81, -7.81, -7.81, -7.81, -2.81, 2.19, 7.19, 12.19, 17.19, 22.19]
    line [-7.81, -7.81, -7.81, -7.81, -7.81, -7.81, -7.81, -2.81, 2.19, 7.19, 12.19]
```

First line: Birch ends at $100, so the kink sits at $100 and the picture is a vanilla call's, a plain call with a fixed cash strike. Second line: Birch ends at $110, and the whole kink slides $10 to the right. The strike moves with Birch, and that movement is what the price must account for.

---

## The formula

Notation first, in words. A subscript 1 marks Acme, the share received; a subscript 2 marks Birch, the share handed over. $S_1(T)$ is Acme's price at the expiry date T. The Greek letter $\rho$ (rho) is the correlation between the two shares' random moves. $q_1$ and $q_2$ are dividend yields, $\sigma_1$ and $\sigma_2$ (sigma) volatilities, and $N(x)$ is the bell-curve area to the left of x, as on [Black–Scholes call](../08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md). The table lists every symbol.

$$V = S_1 e^{-q_1 T} N(d_1) \;-\; S_2 e^{-q_2 T} N(d_2)$$

**Read it aloud:** the Acme share that might be received minus the Birch share that might be handed over, each trimmed for the dividends it pays before expiry, each weighted by its own chance.

The inputs that drive the chances:

$$\sigma = \sqrt{\sigma_1^2 + \sigma_2^2 - 2\rho\,\sigma_1\sigma_2}, \qquad d_1 = \frac{\ln\!\left(\dfrac{S_1 e^{-q_1 T}}{S_2 e^{-q_2 T}}\right) + \tfrac12\sigma^2 T}{\sigma\sqrt{T}}, \qquad d_2 = d_1 - \sigma\sqrt{T}$$

In words: $\sigma$ is the volatility of the ratio Acme over Birch. Each share adds its own variance, the square of its volatility, and the part they share cancels, twice the correlation times the two volatilities. $d_2$ counts, in units of the ratio's log-spread $\sigma\sqrt{T}$, how far the middle of the ratio's log lands above zero, the log of the strike 1; $d_1$ is one spread further.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $V$ | price today of the right to swap one Birch share for one Acme share at T | $7.81 | is the answer |
| $S_1$, $S_2$ | Acme's and Birch's prices today | $100 each | Acme up: rises; Birch up: falls |
| $q_1$, $q_2$ | dividend yields, continuously compounded; $e^{-qT}$ is the share left after a year of dividends leak out | 2% each | Acme's up: falls; Birch's up: rises |
| $\sigma_1$, $\sigma_2$ | each share's volatility: the spread of its yearly log return | 20% each | usually rises, through $\sigma$ |
| $\rho$ | correlation of the two shares' random moves | 0.5 | falls: the shares move together, so the gap between them shrinks |
| $\sigma$ | the effective volatility: that of the ratio Acme over Birch | 20% | rises |
| $T$ | years to expiry | 1 | rises |
| $R$, $R_T$ | the ratio Acme over Birch, today and at T | 1 today | — |
| $d_1$, $d_2$, $N$ | distances of the ratio from 1 in units of its spread; $N$ is the bell-curve area to the left of a point | 0.1 and −0.1; N(d1) 0.5398 | — |
| $r$, $K$ | the bank rate, continuously compounded; a fixed cash strike, used only in the cash case | 5%; $100 | r: no effect at all |
| $Z_1$, $Z_2$, $Z_\perp$ | the two standard bell-curve shocks that move Acme and Birch, correlated as rho; $Z_\perp$ is a third shock independent of Birch's | — | — |

### When it holds

- **Both log prices bell-curved, with constant volatilities and a constant correlation.** Correlation is the input nobody quotes directly. If the true correlation is 0.01 higher than the one used, the price is off by $0.08, the correlation sensitivity below.
- **Exercise only at expiry.** When neither share pays dividends, swapping early never pays, and the American contract, which may be exercised on any day up to expiry, is worth the same. With dividends, early exercise can pay, and this formula is a floor.
- **Dividends paid as a steady yield.** A lump-sum dividend before expiry must be subtracted from that share's price today instead.
- **Both shares can be bought, and sold short (borrowed and sold), without cost.** The hedge in Step 4 holds both shares. If Birch cannot be borrowed, the replication argument fails, and so does the price.
- **One share for one share.** A contract swapping n Birch shares for one Acme share uses n times $S_2$ in every place; the formula is unchanged otherwise.

---

## Why it works

### Step 0: count in Birch shares, and the bank rate disappears

A price in dollars is a count of dollars. Nothing forces that unit. The payoff at expiry factors:

$$\max\big(S_1(T) - S_2(T),\,0\big) = S_2(T)\,\max(R_T - 1,\,0).$$

Read in Birch shares, the payoff is $\max(R_T - 1, 0)$ Birch shares: a call on the ratio, struck at 1. The unit of account, here a Birch share, is called the **numeraire**, the word used from here on ([Change of numeraire](../../11-Stochastic%20processes%20and%20calculus/07-Changing%20Measure/05-change-of-numeraire.md)).

In dollars, a call is priced against a bank account that grows at r. In Birch shares, the "bank account" is a Birch share itself, dividends reinvested, and measured in Birch shares it earns nothing but those dividends. The bank rate has no job left to do. What remains is a zero-interest call on the ratio. Steps 1 and 2 find the ratio's spread and its centre; Step 3 prices it.

### Step 1: the ratio's volatility, net of what the shares share

The log of a ratio is a difference of logs: $\ln R_T = \ln S_1(T) - \ln S_2(T)$. Over the year, Acme's log price takes the random shock $\sigma_1\sqrt{T}Z_1$ and Birch's takes $\sigma_2\sqrt{T}Z_2$, where $Z_1$ and $Z_2$ are standard bell-curve draws with correlation $\rho$. The ratio takes their difference. The variance of a difference of two correlated shocks is each variance, minus twice the shared part:

$$\sigma^2 = \sigma_1^2 + \sigma_2^2 - 2\rho\,\sigma_1\sigma_2 = 0.04 + 0.04 - 2(0.5)(0.2)(0.2) = 0.04.$$

So the ratio moves 20 percent a year, as much as either share on its own. Correlation decides the price. At +1, two shares this alike take the same shock, the ratio never moves, and the option is worthless. With unequal volatilities the ratio still moves at $|\sigma_1 - \sigma_2|$, and the option keeps a value. At −1 they move in opposite directions, the ratio moves 40 percent a year, and the option costs about twice as much.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Exchange option on Acme and Birch against their correlation"
    x-axis "Correlation between the two shares" ["-1", "-0.75", "-0.5", "-0.25", "0", "0.25", "0.5", "0.75", "1"]
    y-axis "Price today ($)" 0 --> 16
    line [15.54, 14.55, 13.48, 12.31, 11.02, 9.55, 7.81, 5.53, 0.00]
```

The one line is the Margrabe price at each correlation, everything else held at Acme and Birch's values. It falls from $15.54 at −1 to $11.02 at zero, $7.81 at 0.5, and exactly zero at +1. The fall steepens near +1, because the effective volatility is a square root of a quantity running down to zero. How that slope is traded and read back from prices is [Correlation Greeks and implied correlation](05-correlation-greeks-and-implied-correlation.md).

### Step 2: the ratio's centre, counted in Birch

Pricing in a numeraire rests on one rule: any traded holding, divided by the numeraire holding, is a fair game. Its expected future value, in the probabilities that go with that numeraire, is its value today. Acme with dividends reinvested is a traded holding, and so is Birch with dividends reinvested. Their ratio, $R\,e^{(q_1 - q_2)t}$ at time t, is therefore a fair game.

So the expected ratio at T is $R\,e^{(q_2 - q_1)T}$: today's ratio, pushed by the difference in dividends. Acme leaks dividends, which lowers the ratio; Birch leaks them too, which raises it. For Acme and Birch the two yields are equal, and the ratio is expected to stay at 1. The bank rate would push both shares up equally, and in a ratio it cancels.

### Step 3: price the ratio call, then convert back to dollars

The ratio is lognormal with centre $R\,e^{(q_2 - q_1)T}$ and volatility $\sigma$, and the call on it has strike 1 and zero interest. That is the Black-Scholes call from [Black–Scholes call](../08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md), with the rate set to zero. In Birch shares at expiry, its value is

$$R\,e^{(q_2 - q_1)T} N(d_1) - N(d_2).$$

To bring that back to dollars today, multiply by what one Birch share delivered at T costs today: $S_2 e^{-q_2 T}$, a share bought now minus the dividends it pays out along the way. Multiplied out, $S_2 e^{-q_2T}\cdot R\,e^{(q_2-q_1)T} = S_1 e^{-q_1 T}$, and the formula appears:

$$V = S_1 e^{-q_1 T} N(d_1) - S_2 e^{-q_2 T} N(d_2).$$

<details>
<summary>Detailed proof: the same price by direct integration in dollars</summary>

In the dollar pretend world (risk-neutral), $\ln S_i(T) = \ln S_i + (r - q_i - \tfrac12\sigma_i^2)T + \sigma_i\sqrt{T}Z_i$ for i = 1, 2, where $Z_1$ and $Z_2$ are standard normal with correlation $\rho$. The price is $e^{-rT}$ times the average of $S_2(T)\max(R_T - 1, 0)$.

Write $S_2(T) = S_2 e^{(r - q_2)T} \cdot e^{\sigma_2\sqrt{T}Z_2 - \frac12\sigma_2^2 T}$. The first factor is a constant; times $e^{-rT}$ it is $S_2 e^{-q_2 T}$, and r is gone. The second factor has average 1 and reweights the bell curve. As on [Black–Scholes call](../08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md), completing the square shows the reweighted $Z_2$ is a normal centred at $\sigma_2\sqrt{T}$ instead of 0. Since $Z_1 = \rho Z_2 + \sqrt{1-\rho^2}\,Z_\perp$ with $Z_\perp$ independent, $Z_1$ is centred at $\rho\sigma_2\sqrt{T}$.

Under the reweighting, $\ln R_T = \ln R + (q_2 - q_1)T - \tfrac12(\sigma_1^2 - \sigma_2^2)T + \sigma_1\sqrt{T}Z_1 - \sigma_2\sqrt{T}Z_2$ has centre shifted by $\rho\sigma_1\sigma_2 T - \sigma_2^2 T$, giving $\ln R + (q_2 - q_1)T - \tfrac12(\sigma_1^2 + \sigma_2^2 - 2\rho\sigma_1\sigma_2)T = \ln R + (q_2 - q_1)T - \tfrac12\sigma^2 T$. The reweighting shifts centres, not spreads, so its variance is still $\sigma_1^2 T + \sigma_2^2 T - 2\rho\sigma_1\sigma_2 T = \sigma^2 T$.

So $R_T$ is lognormal with average $R\,e^{(q_2 - q_1)T}$ and log-spread $\sigma\sqrt{T}$, and the price is $S_2 e^{-q_2 T}$ times the average of $\max(R_T - 1, 0)$. The lognormal call average, $F N(d_1) - N(d_2)$ with $F = R\,e^{(q_2 - q_1)T}$, is the Black-Scholes integral with no discount. Multiplying by $S_2 e^{-q_2 T}$ gives the formula. The reweighting is the change to Birch as numeraire, done by hand.

</details>

### Step 4: the hedge holds shares and no cash

Double both share prices and every payoff doubles, so the price doubles. A price with that property equals each input times its sensitivity, summed (Euler's identity for functions of degree one):

$$V = S_1 \cdot \Delta_1 + S_2 \cdot \Delta_2, \qquad \Delta_1 = e^{-q_1T}N(d_1),\quad \Delta_2 = -e^{-q_2T}N(d_2).$$

Here the Greek letter Δ (delta) is the dollars the price gains per dollar on a share. For Acme and Birch: 0.52914 × $100 − 0.45106 × $100 = $7.81. The replicating portfolio is 0.5291 Acme shares held and 0.4511 Birch shares sold short, with nothing in the bank. A hedge with no cash in it cannot care what cash earns. That is the second reason r is absent, seen from the trading desk.

### Step 5: the vanilla call is the case where Birch is cash

Replace Birch with a bond that pays $100 at expiry. Its price today is 100 × e^−0.05 = $95.12. It has no volatility, pays no dividend, and grows at the bank rate.

Put $S_2 = K e^{-rT}$, $q_2 = 0$ and $\sigma_2 = 0$ into the formula. The effective volatility becomes $\sigma_1$, $S_2 e^{-q_2T}$ becomes $K e^{-rT}$, and the result is the Black-Scholes call, $9.227006, the house vanilla: the worked example of [Black–Scholes call](../08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md), a call on Acme at a fixed $100 strike. The bank rate returns only because the second asset is now a bond whose price contains it.

Two other roads reach the exchange price, and the code takes both. Fix Birch's shock; Acme is then lognormal with a known centre and spread, the inner average is a closed Black-Scholes-type expression, and one integral over Birch's shock finishes the job, with r written in. Or simulate the two shares together, correlating their shocks as on [Correlated paths](../06-Numerical%20Methods%20for%20Pricing/04-correlated-paths-and-cholesky.md), and average the discounted payoff.

---

## Worked numbers, by hand

Acme and Birch: $S_1 = S_2 = 100$, $\sigma_1 = \sigma_2 = 20\%$, $q_1 = q_2 = 2\%$, $\rho = 0.5$, $r = 5\%$, $T = 1$ year.

| Step | Arithmetic | Value |
| --- | --- | --- |
| effective variance, $\sigma^2$ | 0.04 + 0.04 − 2 × 0.5 × 0.2 × 0.2 | 0.04 |
| effective volatility, $\sigma$ | √0.04 | 0.20 |
| Acme today net of dividends | 100 × e^−0.02 | $98.02 |
| Birch today net of dividends | 100 × e^−0.02 | $98.02 |
| $d_1$ | (ln 1 + 0.5 × 0.04) / 0.20 | 0.1 |
| $d_2$ | 0.1 − 0.20 | −0.1 |
| N(d1), N(d2) | bell-curve table | 0.5398, 0.4602 |
| Acme half | 98.020 × 0.53983 | $52.914 |
| Birch half | 98.020 × 0.46017 | $45.106 |
| **price** | 52.914 − 45.106 | **$7.81** |

The right to swap a Birch share for an Acme share in a year costs $7.81 today, less than a tenth of a share's price. The vanilla call on Acme at a fixed $100 costs $9.23.

The gap is not volatility: at correlation 0.5 the ratio moves exactly as much as Acme alone. It is growth. A fixed $100 stays at $100 while Acme is expected to grow at the bank rate less its dividend, so the vanilla starts ahead. Birch is expected to grow at the same rate as Acme, so the swap starts level.

### What breaks if you drop a piece

Same contract, right answer $7.81. Every wrong number is printed by both checks.

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Treat Birch as a fixed $100 strike | $9.23 | Birch grows and moves with Acme; a cash strike does neither |
| Leave the correlation out, $\sigma^2 = \sigma_1^2 + \sigma_2^2$ | $11.02 | Priced as if the two shares moved independently |
| Flip the sign, $+2\rho\sigma_1\sigma_2$ | $13.48 | Positive correlation narrows the gap; the plus sign widens it, pricing the shares as if $\rho = -0.5$ |
| Drop the 2, $-\rho\sigma_1\sigma_2$ | $9.55 | The cross term of a squared difference comes twice |
| Drop both dividend yields | $7.97 | Each share delivered at T is worth $98.02 today, not $100 |

### The Greeks

Sensitivities by bumping the formula (nudging one input up and down and comparing the prices), printed by both checks.

| Greek | Plain meaning | Value |
| --- | --- | --- |
| delta, Acme | dollars gained per dollar on Acme; equals $e^{-q_1T}N(d_1)$ | 0.5291 |
| delta, Birch | dollars gained per dollar on Birch; equals $-e^{-q_2T}N(d_2)$ | −0.4511 |
| gamma, Acme | change in Acme's delta per dollar on Acme | 0.0195 |
| vega, Acme | dollars per one point of Acme's volatility | 0.1944 |
| correlation | dollars per 0.01 of correlation | −0.0778 |
| bank rate (the Greek named rho, not the correlation $\rho$) | dollars per point of r | 0 |

The last row is the title of the card.

---

## Code, from first principles, and it actually runs

Both programs reach the price three ways. Road 1 is Margrabe's formula, which contains no bank rate. Road 2 fixes Birch's shock, prices Acme's conditional payoff exactly, and integrates over Birch's shock by Simpson's rule; it discounts at r and uses no effective volatility, and it is run at r = 0%, 5% and 10%. Road 3 simulates a million correlated pairs of year-end prices, correlated by the Cholesky step $Z_1 = \rho Z_2 + \sqrt{1-\rho^2}\,Z_\perp$.

Then the cash case is checked against the house vanilla, the deltas against Euler's identity, and every what-breaks, Greek, chart and try-changing number is printed. The normal CDF is a written-out series; the random numbers come from a written-out generator (splitmix64 with the Box-Muller transform).

### Python

```python
# The exchange option (Margrabe) -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is a series written out, the integral is
# Simpson's rule, the random numbers are splitmix64 + Box-Muller, correlated by Cholesky.
from math import log, sqrt, exp, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)           # bell-curve height
def N(x):                                                       # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term = total = x; k = 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total

def eff_vol(s1, s2, rho): return sqrt(max(s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2, 0.0))

def margrabe(S1, S2, q1, q2, s1, s2, rho, T):                   # road 1: the formula, no r in it
    v = eff_vol(s1, s2, rho) * sqrt(T)
    A, B = S1 * exp(-q1 * T), S2 * exp(-q2 * T)
    if v == 0.0: return max(A - B, 0.0)
    d1 = (log(A / B) + 0.5 * v * v) / v
    return A * N(d1) - B * N(d1 - v)

def bs_call(S, K, r, q, sig, T):                                # the plain Black-Scholes call
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))

def conditional(r, rho, panels=4000):
    # road 2: fix share 2's shock z.  Share 1 is then lognormal with a known centre and spread,
    # so the inner average is exact; Simpson's rule does the outer one.  The bank rate r is used.
    w = s1 * sqrt((1.0 - rho * rho) * T)
    def f(z):
        X2 = S2 * exp((r - q2 - 0.5 * s2 * s2) * T + s2 * sqrt(T) * z)
        m = log(S1) + (r - q1 - 0.5 * s1 * s1) * T + s1 * rho * sqrt(T) * z
        d = (m - log(X2)) / w
        return (exp(m + 0.5 * w * w) * N(d + w) - X2 * N(d)) * phi(z)
    a, b = -10.0, 10.0; h = (b - a) / panels
    tot = f(a) + f(b)
    for i in range(1, panels):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * tot * h / 3.0

MASK = (1 << 64) - 1
def simulate(r, rho, paths=1000000):
    # road 3: correlated shares at expiry.  z1 = rho z2 + sqrt(1 - rho^2) z_other (Cholesky).
    state = 20260924; c = sqrt(1.0 - rho * rho); acc = acc2 = 0.0
    def uniform():
        nonlocal state
        state = (state + 0x9E3779B97F4A7C15) & MASK
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53
    m1, m2 = (r - q1 - 0.5 * s1 * s1) * T, (r - q2 - 0.5 * s2 * s2) * T
    for _ in range(paths):
        rad = sqrt(-2.0 * log(uniform())); ang = 2.0 * pi * uniform()
        z2, zo = rad * cos(ang), rad * sin(ang)
        z1 = rho * z2 + c * zo
        pay = max(S1 * exp(m1 + s1 * sqrt(T) * z1) - S2 * exp(m2 + s2 * sqrt(T) * z2), 0.0)
        acc += pay; acc2 += pay * pay
    mean = acc / paths
    return exp(-r * T) * mean, exp(-r * T) * sqrt((acc2 / paths - mean * mean) / paths)

# ---- two house shares: $100 each, 20% vol, 2% dividend, correlation 0.5; 5% rate, 1 year ----
S1, S2, q1, q2, s1, s2, rho, r, T = 100.0, 100.0, 0.02, 0.02, 0.20, 0.20, 0.5, 0.05, 1.0
sig = eff_vol(s1, s2, rho)
A, B = S1 * exp(-q1 * T), S2 * exp(-q2 * T)
d1 = (log(A / B) + 0.5 * sig * sig * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
V = margrabe(S1, S2, q1, q2, s1, s2, rho, T)
V_cond, V_cond0, V_cond10 = conditional(r, rho), conditional(0.0, rho), conditional(0.10, rho)
V_mc, se = simulate(r, rho)
V_mc1, _ = simulate(r, 1.0, 20000)
cash = 100.0 * exp(-r * T)                              # a zero-coupon bond paying $100 at T
V_cash = margrabe(S1, cash, q1, 0.0, s1, 0.0, 0.0, T)
C_bs = bs_call(S1, 100.0, r, q1, s1, T)
h = 0.01
g = lambda a, b: margrabe(a, b, q1, q2, s1, s2, rho, T)
dl1 = (g(S1 + h, S2) - g(S1 - h, S2)) / (2 * h); dl2 = (g(S1, S2 + h) - g(S1, S2 - h)) / (2 * h)
vega = (margrabe(S1, S2, q1, q2, s1 + h, s2, rho, T) - margrabe(S1, S2, q1, q2, s1 - h, s2, rho, T)) / 2.0
corr = (margrabe(S1, S2, q1, q2, s1, s2, rho + h, T) - margrabe(S1, S2, q1, q2, s1, s2, rho - h, T)) / 2.0
gam = (g(S1 + 1.0, S2) - 2.0 * V + g(S1 - 1.0, S2))

rows = [
    ("effective variance sigma^2", sig * sig), ("effective vol sigma", sig), ("effective vol, rho = -1", eff_vol(s1, s2, -1.0)),
    ("share 1 today, S1 e^-q1T", A), ("share 2 today, S2 e^-q2T", B),
    ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("Acme half", A * N(d1)), ("Birch half", B * N(d2)),
    ("1 Margrabe formula", V), ("2 conditional integral, r = 5%", V_cond),
    ("3 simulation, 1000000 pairs", V_mc), ("  standard error", se),
    ("  conditional integral, r = 0%", V_cond0), ("  conditional integral, r = 10%", V_cond10),
    ("rho = 1, formula", margrabe(S1, S2, q1, q2, s1, s2, 1.0, T)), ("rho = 1, simulation", V_mc1),
    ("cash case: Margrabe, bond S2 = 95.12", V_cash), ("cash case: Black-Scholes call", C_bs),
    ("delta 1, bump", dl1), ("  e^-q1T N(d1)", A / S1 * N(d1)),
    ("delta 2, bump", dl2), ("  -e^-q2T N(d2)", -B / S2 * N(d2)),
    ("S1 delta1 + S2 delta2", S1 * dl1 + S2 * dl2), ("gamma 1, per $1", gam),
    ("vega of share 1, per vol point", vega), ("correlation, per 0.01", corr),
    ("wrong: correlation left out", margrabe(S1, S2, q1, q2, s1, s2, 0.0, T)),
    ("wrong: +2 rho instead of -2 rho", margrabe(S1, S2, q1, q2, sqrt(0.12), 0.0, 0.0, T)),
    ("wrong: rho s1 s2 without the 2", margrabe(S1, S2, q1, q2, sqrt(0.06), 0.0, 0.0, T)),
    ("wrong: share 2 as a fixed $100 strike", C_bs),
    ("wrong: dividends dropped", margrabe(S1, S2, 0.0, 0.0, s1, s2, rho, T)),
    ("try: rho = -1", margrabe(S1, S2, q1, q2, s1, s2, -1.0, T)),
    ("try: S1 = 110", margrabe(110.0, S2, q1, q2, s1, s2, rho, T)),
    ("try: share 2 vol 30%", margrabe(S1, S2, q1, q2, s1, 0.30, rho, T)),
]
for name, v in rows:
    print(f"{name:<40} {v:>12.6f}")
rhos = [-1.0 + 0.25 * i for i in range(9)]
print("chart, correlation " + " ".join(f"{x:6.2f}" for x in rhos))
print("chart, price       " + " ".join(f"{margrabe(S1, S2, q1, q2, s1, s2, x, T):6.2f}" for x in rhos))
ends = [80.0 + 5.0 * i for i in range(11)]
print("chart, share 1 end " + " ".join(f"{x:6.0f}" for x in ends))
for e2 in (100.0, 110.0):
    print(f"chart, profit {e2:.0f}  " + " ".join(f"{max(x - e2, 0.0) - V:6.2f}" for x in ends))

assert abs(V - 7.807839) < 1e-6,                  "formula vs the shelf's house number"
assert abs(V_cond - V) < 1e-8,                    "conditional integral lands on the formula"
assert abs(V_mc - V) < 4.0 * se,                  "simulation within four standard errors"
assert abs(V_cond10 - V) < 1e-8,                 "bank rate 10%: same price"
assert abs(V_cond0 - V) < 1e-8,                  "bank rate 0%: same price"
assert abs(V_cash - 9.227005508154) < 1e-9,       "cash case is the house vanilla"
assert V_mc1 == 0.0,                              "perfect correlation: every simulated payoff is zero"
assert abs(S1 * dl1 + S2 * dl2 - V) < 1e-6,       "the price is shares only: Euler's identity"
print("ALL CHECKS PASS")
```

**Ran 2026-09-24 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
effective variance sigma^2                   0.040000
effective vol sigma                          0.200000
effective vol, rho = -1                      0.400000
share 1 today, S1 e^-q1T                    98.019867
share 2 today, S2 e^-q2T                    98.019867
d1                                           0.100000
d2                                          -0.100000
N(d1)                                        0.539828
N(d2)                                        0.460172
Acme half                                   52.913853
Birch half                                  45.106014
1 Margrabe formula                           7.807839
2 conditional integral, r = 5%               7.807839
3 simulation, 1000000 pairs                  7.830254
  standard error                             0.011724
  conditional integral, r = 0%               7.807839
  conditional integral, r = 10%              7.807839
rho = 1, formula                             0.000000
rho = 1, simulation                          0.000000
cash case: Margrabe, bond S2 = 95.12         9.227006
cash case: Black-Scholes call                9.227006
delta 1, bump                                0.529139
  e^-q1T N(d1)                               0.529139
delta 2, bump                               -0.451060
  -e^-q2T N(d2)                             -0.451060
S1 delta1 + S2 delta2                        7.807838
gamma 1, per $1                              0.019451
vega of share 1, per vol point               0.194362
correlation, per 0.01                       -0.077822
wrong: correlation left out                 11.023600
wrong: +2 rho instead of -2 rho             13.478689
wrong: rho s1 s2 without the 2               9.554658
wrong: share 2 as a fixed $100 strike        9.227006
wrong: dividends dropped                     7.965567
try: rho = -1                               15.538052
try: S1 = 110                               14.009010
try: share 2 vol 30%                        10.315920
chart, correlation  -1.00  -0.75  -0.50  -0.25   0.00   0.25   0.50   0.75   1.00
chart, price        15.54  14.55  13.48  12.31  11.02   9.55   7.81   5.53   0.00
chart, share 1 end     80     85     90     95    100    105    110    115    120    125    130
chart, profit 100   -7.81  -7.81  -7.81  -7.81  -7.81  -2.81   2.19   7.19  12.19  17.19  22.19
chart, profit 110   -7.81  -7.81  -7.81  -7.81  -7.81  -7.81  -7.81  -2.81   2.19   7.19  12.19
ALL CHECKS PASS
```

Three roads, one price. The conditional integral lands on the formula to the printed digit, at a bank rate of 0%, 5% and 10% alike: r goes in and comes out with no effect. The simulation gives $7.83 with a standard error (the typical size of its random error) of 0.0117, less than two standard errors from $7.81. At correlation 1, every one of the simulated payoffs is exactly zero. The cash case reproduces the house vanilla, and the bumped deltas rebuild the price with no cash term.

### Rust

The same checks, the same inputs, the same random-number generator, written again in Rust with no crates.

```rust
// The exchange option (Margrabe) -- the same check as exchange_option_margrabe_check.py, in Rust.
// Std only, no crates.  Normal CDF as a written-out series, Simpson's rule, splitmix64 +
// Box-Muller random numbers, correlated by Cholesky.
// Compile: rustc --edition 2021 -O exchange_option_margrabe_check.rs -o /tmp/margrabe_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 2.0; term *= x * x / k; total += term;
    }
    0.5 + phi(x) * total
}
fn eff_vol(s1: f64, s2: f64, rho: f64) -> f64 { (s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2).max(0.0).sqrt() }

// road 1: the formula, no r in it
fn margrabe(x1: f64, x2: f64, q1: f64, q2: f64, s1: f64, s2: f64, rho: f64, t: f64) -> f64 {
    let v = eff_vol(s1, s2, rho) * t.sqrt();
    let (a, b) = (x1 * (-q1 * t).exp(), x2 * (-q2 * t).exp());
    if v == 0.0 { return (a - b).max(0.0); }
    let d1 = ((a / b).ln() + 0.5 * v * v) / v;
    a * n_cdf(d1) - b * n_cdf(d1 - v)
}
fn bs_call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - sig * t.sqrt())
}

struct Mkt { s1: f64, s2: f64, q1: f64, q2: f64, v1: f64, v2: f64, t: f64 }

// road 2: fix share 2's shock z; share 1 is then lognormal, so the inner average is exact.
fn conditional(m: &Mkt, r: f64, rho: f64, panels: usize) -> f64 {
    let w = m.v1 * ((1.0 - rho * rho) * m.t).sqrt();
    let f = |z: f64| {
        let x2 = m.s2 * ((r - m.q2 - 0.5 * m.v2 * m.v2) * m.t + m.v2 * m.t.sqrt() * z).exp();
        let mu = m.s1.ln() + (r - m.q1 - 0.5 * m.v1 * m.v1) * m.t + m.v1 * rho * m.t.sqrt() * z;
        let d = (mu - x2.ln()) / w;
        ((mu + 0.5 * w * w).exp() * n_cdf(d + w) - x2 * n_cdf(d)) * phi(z)
    };
    let (a, b) = (-10.0, 10.0);
    let h = (b - a) / panels as f64;
    let mut tot = f(a) + f(b);
    for i in 1..panels { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    (-r * m.t).exp() * tot * h / 3.0
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
}

// road 3: correlated shares at expiry, z1 = rho z2 + sqrt(1 - rho^2) z_other (Cholesky).
fn simulate(m: &Mkt, r: f64, rho: f64, paths: usize) -> (f64, f64) {
    let mut rng = Rng(20260924);
    let c = (1.0 - rho * rho).sqrt();
    let (mut acc, mut acc2) = (0.0, 0.0);
    let m1 = (r - m.q1 - 0.5 * m.v1 * m.v1) * m.t;
    let m2 = (r - m.q2 - 0.5 * m.v2 * m.v2) * m.t;
    for _ in 0..paths {
        let rad = (-2.0 * rng.uniform().ln()).sqrt();
        let ang = 2.0 * PI * rng.uniform();
        let (z2, zo) = (rad * ang.cos(), rad * ang.sin());
        let z1 = rho * z2 + c * zo;
        let pay = (m.s1 * (m1 + m.v1 * m.t.sqrt() * z1).exp() - m.s2 * (m2 + m.v2 * m.t.sqrt() * z2).exp()).max(0.0);
        acc += pay; acc2 += pay * pay;
    }
    let mean = acc / paths as f64;
    ((-r * m.t).exp() * mean, (-r * m.t).exp() * ((acc2 / paths as f64 - mean * mean) / paths as f64).sqrt())
}

fn main() {
    let (s1, s2, q1, q2, v1, v2, rho, r, t) = (100.0, 100.0, 0.02, 0.02, 0.20, 0.20, 0.5, 0.05, 1.0);
    let m = Mkt { s1, s2, q1, q2, v1, v2, t };
    let sig = eff_vol(v1, v2, rho);
    let (a, b) = (s1 * (-q1 * t).exp(), s2 * (-q2 * t).exp());
    let d1 = ((a / b).ln() + 0.5 * sig * sig * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    let v = margrabe(s1, s2, q1, q2, v1, v2, rho, t);
    let (v_cond, v_cond0, v_cond10) = (conditional(&m, r, rho, 4000), conditional(&m, 0.0, rho, 4000), conditional(&m, 0.10, rho, 4000));
    let (v_mc, se) = simulate(&m, r, rho, 1000000);
    let (v_mc1, _) = simulate(&m, r, 1.0, 20000);
    let cash = 100.0 * (-r * t).exp();                          // a zero-coupon bond paying $100 at T
    let v_cash = margrabe(s1, cash, q1, 0.0, v1, 0.0, 0.0, t);
    let c_bs = bs_call(s1, 100.0, r, q1, v1, t);
    let h = 0.01;
    let g = |x: f64, y: f64| margrabe(x, y, q1, q2, v1, v2, rho, t);
    let dl1 = (g(s1 + h, s2) - g(s1 - h, s2)) / (2.0 * h);
    let dl2 = (g(s1, s2 + h) - g(s1, s2 - h)) / (2.0 * h);
    let vega = (margrabe(s1, s2, q1, q2, v1 + h, v2, rho, t) - margrabe(s1, s2, q1, q2, v1 - h, v2, rho, t)) / 2.0;
    let corr = (margrabe(s1, s2, q1, q2, v1, v2, rho + h, t) - margrabe(s1, s2, q1, q2, v1, v2, rho - h, t)) / 2.0;
    let gam = g(s1 + 1.0, s2) - 2.0 * v + g(s1 - 1.0, s2);

    let rows: Vec<(&str, f64)> = vec![
        ("effective variance sigma^2", sig * sig), ("effective vol sigma", sig), ("effective vol, rho = -1", eff_vol(v1, v2, -1.0)),
        ("share 1 today, S1 e^-q1T", a), ("share 2 today, S2 e^-q2T", b),
        ("d1", d1), ("d2", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("Acme half", a * n_cdf(d1)), ("Birch half", b * n_cdf(d2)),
        ("1 Margrabe formula", v), ("2 conditional integral, r = 5%", v_cond),
        ("3 simulation, 1000000 pairs", v_mc), ("  standard error", se),
        ("  conditional integral, r = 0%", v_cond0), ("  conditional integral, r = 10%", v_cond10),
        ("rho = 1, formula", margrabe(s1, s2, q1, q2, v1, v2, 1.0, t)), ("rho = 1, simulation", v_mc1),
        ("cash case: Margrabe, bond S2 = 95.12", v_cash), ("cash case: Black-Scholes call", c_bs),
        ("delta 1, bump", dl1), ("  e^-q1T N(d1)", a / s1 * n_cdf(d1)),
        ("delta 2, bump", dl2), ("  -e^-q2T N(d2)", -b / s2 * n_cdf(d2)),
        ("S1 delta1 + S2 delta2", s1 * dl1 + s2 * dl2), ("gamma 1, per $1", gam),
        ("vega of share 1, per vol point", vega), ("correlation, per 0.01", corr),
        ("wrong: correlation left out", margrabe(s1, s2, q1, q2, v1, v2, 0.0, t)),
        ("wrong: +2 rho instead of -2 rho", margrabe(s1, s2, q1, q2, 0.12f64.sqrt(), 0.0, 0.0, t)),
        ("wrong: rho s1 s2 without the 2", margrabe(s1, s2, q1, q2, 0.06f64.sqrt(), 0.0, 0.0, t)),
        ("wrong: share 2 as a fixed $100 strike", c_bs),
        ("wrong: dividends dropped", margrabe(s1, s2, 0.0, 0.0, v1, v2, rho, t)),
        ("try: rho = -1", margrabe(s1, s2, q1, q2, v1, v2, -1.0, t)),
        ("try: S1 = 110", margrabe(110.0, s2, q1, q2, v1, v2, rho, t)),
        ("try: share 2 vol 30%", margrabe(s1, s2, q1, q2, v1, 0.30, rho, t)),
    ];
    for (name, x) in &rows { println!("{:<40} {:>12.6}", name, x); }
    let rhos: Vec<f64> = (0..9).map(|i| -1.0 + 0.25 * i as f64).collect();
    let row = |xs: Vec<String>| xs.join(" ");
    println!("chart, correlation {}", row(rhos.iter().map(|x| format!("{:6.2}", x)).collect()));
    println!("chart, price       {}", row(rhos.iter().map(|x| format!("{:6.2}", margrabe(s1, s2, q1, q2, v1, v2, *x, t))).collect()));
    let ends: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("chart, share 1 end {}", row(ends.iter().map(|x| format!("{:6.0}", x)).collect()));
    for e2 in [100.0f64, 110.0] {
        println!("chart, profit {:.0}  {}", e2, row(ends.iter().map(|x| format!("{:6.2}", (x - e2).max(0.0) - v)).collect()));
    }

    assert!((v - 7.807839).abs() < 1e-6, "formula vs the shelf's house number");
    assert!((v_cond - v).abs() < 1e-8, "conditional integral lands on the formula");
    assert!((v_mc - v).abs() < 4.0 * se, "simulation within four standard errors");
    assert!((v_cond10 - v).abs() < 1e-8, "bank rate 10%: same price");
    assert!((v_cond0 - v).abs() < 1e-8, "bank rate 0%: same price");
    assert!((v_cash - 9.227005508154).abs() < 1e-9, "cash case is the house vanilla");
    assert!(v_mc1 == 0.0, "perfect correlation: every simulated payoff is zero");
    assert!((s1 * dl1 + s2 * dl2 - v).abs() < 1e-6, "the price is shares only: Euler's identity");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
effective variance sigma^2                   0.040000
effective vol sigma                          0.200000
effective vol, rho = -1                      0.400000
share 1 today, S1 e^-q1T                    98.019867
share 2 today, S2 e^-q2T                    98.019867
d1                                           0.100000
d2                                          -0.100000
N(d1)                                        0.539828
N(d2)                                        0.460172
Acme half                                   52.913853
Birch half                                  45.106014
1 Margrabe formula                           7.807839
2 conditional integral, r = 5%               7.807839
3 simulation, 1000000 pairs                  7.830254
  standard error                             0.011724
  conditional integral, r = 0%               7.807839
  conditional integral, r = 10%              7.807839
rho = 1, formula                             0.000000
rho = 1, simulation                          0.000000
cash case: Margrabe, bond S2 = 95.12         9.227006
cash case: Black-Scholes call                9.227006
delta 1, bump                                0.529139
  e^-q1T N(d1)                               0.529139
delta 2, bump                               -0.451060
  -e^-q2T N(d2)                             -0.451060
S1 delta1 + S2 delta2                        7.807838
gamma 1, per $1                              0.019451
vega of share 1, per vol point               0.194362
correlation, per 0.01                       -0.077822
wrong: correlation left out                 11.023600
wrong: +2 rho instead of -2 rho             13.478689
wrong: rho s1 s2 without the 2               9.554658
wrong: share 2 as a fixed $100 strike        9.227006
wrong: dividends dropped                     7.965567
try: rho = -1                               15.538052
try: S1 = 110                               14.009010
try: share 2 vol 30%                        10.315920
chart, correlation  -1.00  -0.75  -0.50  -0.25   0.00   0.25   0.50   0.75   1.00
chart, price        15.54  14.55  13.48  12.31  11.02   9.55   7.81   5.53   0.00
chart, share 1 end     80     85     90     95    100    105    110    115    120    125    130
chart, profit 100   -7.81  -7.81  -7.81  -7.81  -7.81  -2.81   2.19   7.19  12.19  17.19  22.19
chart, profit 110   -7.81  -7.81  -7.81  -7.81  -7.81  -7.81  -7.81  -2.81   2.19   7.19  12.19
ALL CHECKS PASS
```

The two outputs agree line for line, the simulated price included, because both programs draw the same random numbers in the same order.

### Lean

Lean proves Margrabe's formula from the bell-curve model, plus the cash case and the hedge, for any positive prices and expiry.

- Take two shares whose log prices are bell-curved with correlation $\rho$, positive prices today, and any bank rate $r$. Then the average payoff in the dollar pretend world, discounted at $r$, is Margrabe's formula $V$.
- Take the same inputs. Then $V$ equals $S_2 e^{-q_2 T}$ times a Black-Scholes call on the ratio, struck at 1 with no bank rate. That call takes the dividend yield $q_1 - q_2$.
- Suppose Birch is replaced by a bond paying $K$ at expiry, and $\sigma_1 \ge 0$. Then Margrabe's formula gives the Black-Scholes call on Acme with strike $K$, at any correlation.
- Suppose the ratio moves, so $\sigma > 0$. Then Acme's delta is $e^{-q_1T}N(d_1)$ and Birch's delta is $-e^{-q_2T}N(d_2)$.
- Take the same case. Then $V = S_1 \Delta_1 + S_2 \Delta_2$, with no cash term.
- Take Acme and Birch at correlation 1. Then the price is exactly zero.

The bell-curve values, and so the $7.81 price, the Greeks and the simulation, are left to the Python and Rust checks.

```lean
-- The exchange option: if two shares are lognormal with a fixed correlation, the right to hand over one share for the other at expiry is worth Margrabe's formula S₁ e^(-q₁T) N(d₁) - S₂ e^(-q₂T) N(d₂) at every bank rate, which is S₂ e^(-q₂T) times a zero-rate Black-Scholes call on the ratio struck at 1, it becomes the ordinary Black-Scholes call when the second share is a bond, and its hedge holds only the two shares.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- A share's price on expiry day in the dollar pretend world (detailed proof): today's price `S`,
bank rate `r`, dividend yield `q`, volatility `σ`, years to expiry `T`, and a standard bell-curve
draw `z`: `S_T = S e^((r - q - σ²/2) T + σ√T z)`. -/
noncomputable def priceAtExpiry (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- The effective volatility, the volatility of the ratio Acme over Birch:
`σ = √(σ₁² + σ₂² - 2ρσ₁σ₂)`. -/
noncomputable def effVol (σ₁ σ₂ ρ : ℝ) : ℝ :=
  √(σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)

/-- The card's `d₁ = (ln(S₁e^(-q₁T) / (S₂e^(-q₂T))) + σ²T/2) / (σ√T)`; then `d₂ = d₁ - σ√T`. -/
noncomputable def margrabeD1 (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) : ℝ :=
  (log (S₁ * exp (-q₁ * T) / (S₂ * exp (-q₂ * T))) + (effVol σ₁ σ₂ ρ * √T) ^ 2 / 2) /
    (effVol σ₁ σ₂ ρ * √T)

/-- Margrabe's formula `V = S₁e^(-q₁T) N(d₁) - S₂e^(-q₂T) N(d₂)`. There is no bank rate among its
inputs. When the ratio cannot move (`σ√T = 0`), the code's rule applies: the swap is worth
`max(S₁e^(-q₁T) - S₂e^(-q₂T), 0)`. -/
noncomputable def margrabePrice (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) : ℝ :=
  if effVol σ₁ σ₂ ρ * √T = 0 then max (S₁ * exp (-q₁ * T) - S₂ * exp (-q₂ * T)) 0
  else S₁ * exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)
    - S₂ * exp (-q₂ * T) *
      stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)

/-- The Black-Scholes call formula, as on the Black-Scholes call card:
`S e^(-qT) N(d₁) - K e^(-rT) N(d₁ - σ√T)` with `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`; when
`σ√T = 0` the price does not move and the call is worth `max(S e^(-qT) - K e^(-rT), 0)`. -/
noncomputable def bsCall (S K r q σ T : ℝ) : ℝ :=
  if σ * √T = 0 then max (S * exp (-q * T) - K * exp (-r * T)) 0
  else S * exp (-q * T) *
      stdNormalCDF ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T))
    - K * exp (-r * T) *
      stdNormalCDF ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)


open Set in
lemma mg_gauss_Ioi_neg (d : ℝ) :
    (gaussianReal 0 1).real (Ioi (-d)) = stdNormalCDF d := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have h : gaussianReal 0 1 = (gaussianReal 0 1).map (fun x => -x) := by
    rw [gaussianReal_map_neg]; simp
  unfold stdNormalCDF
  rw [cdf_eq_real]
  conv_lhs => rw [h]
  rw [map_measureReal_apply measurable_neg measurableSet_Ioi]
  have hs : (fun x : ℝ => -x) ⁻¹' Ioi (-d) = Iio d := by
    ext x; simp
  rw [hs]
  exact measureReal_congr Iio_ae_eq_Iic

#print axioms mg_gauss_Ioi_neg

lemma mg_tilt1 (a : ℝ) (f : ℝ → ℝ) :
    ∫ x, exp (a * x) * f x ∂(gaussianReal 0 1) =
      exp (a ^ 2 / 2) * ∫ x, f (x + a) ∂(gaussianReal 0 1) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero,
    integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hpt : ∀ x, gaussianPDFReal 0 1 x • (exp (a * x) * f x) =
      exp (a ^ 2 / 2) * (gaussianPDFReal a 1 x * f x) := by
    intro x
    rw [smul_eq_mul]
    have e : gaussianPDFReal 0 1 x * exp (a * x) = exp (a ^ 2 / 2) * gaussianPDFReal a 1 x := by
      unfold gaussianPDFReal
      simp only [NNReal.coe_one, mul_one]
      rw [mul_assoc, ← exp_add]
      rw [mul_left_comm, ← exp_add]
      congr 2
      ring
    calc _ = (gaussianPDFReal 0 1 x * exp (a * x)) * f x := by ring
      _ = _ := by rw [e]; ring
  simp_rw [hpt]
  rw [integral_const_mul]
  congr 1
  rw [← integral_add_right_eq_self (fun x => gaussianPDFReal a 1 x * f x) a]
  congr 1
  funext x
  rw [smul_eq_mul, gaussianPDFReal_add, sub_self]

#print axioms mg_tilt1

lemma mg_integrable_tilt (a b : ℝ) (f : ℝ × ℝ → ℝ) (hf : Measurable f) (hb : ∀ p, |f p| ≤ 1) :
    Integrable (fun p : ℝ × ℝ => exp (a * p.1 + b * p.2) * f p)
      ((gaussianReal 0 1).prod (gaussianReal 0 1)) := by
  have hi := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) a).mul_prod
    (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) b)
  refine hi.mono ?_ ?_
  · exact (by fun_prop : Measurable fun p : ℝ × ℝ => exp (a * p.1 + b * p.2)).mul hf
      |>.aestronglyMeasurable
  · refine Filter.Eventually.of_forall (fun p => ?_)
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_mul, ← exp_add, abs_of_pos (exp_pos _)]
    exact mul_le_of_le_one_right (exp_pos _).le (hb p)

#print axioms mg_integrable_tilt

lemma mg_tilt2 (a b : ℝ) (f : ℝ × ℝ → ℝ) (hf : Measurable f) (hb : ∀ p, |f p| ≤ 1) :
    ∫ p, exp (a * p.1 + b * p.2) * f p ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) =
      exp ((a ^ 2 + b ^ 2) / 2) *
        ∫ p, f (p.1 + a, p.2 + b) ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) := by
  have i1 := mg_integrable_tilt a b f hf hb
  have hf2 : Measurable fun p : ℝ × ℝ => f (p.1 + a, p.2 + b) :=
    hf.comp (by fun_prop)
  have i2 : Integrable (fun p : ℝ × ℝ => f (p.1 + a, p.2 + b))
      ((gaussianReal 0 1).prod (gaussianReal 0 1)) :=
    Integrable.of_bound hf2.aestronglyMeasurable 1
      (Filter.Eventually.of_forall (fun p => by rw [Real.norm_eq_abs]; exact hb _))
  rw [integral_prod _ i1, integral_prod _ i2]
  have hin : ∀ x : ℝ, ∫ y, exp (a * (x, y).1 + b * (x, y).2) * f (x, y) ∂(gaussianReal 0 1) =
      exp (a * x) * (exp (b ^ 2 / 2) * ∫ y, f (x, y + b) ∂(gaussianReal 0 1)) := by
    intro x
    show ∫ y, exp (a * x + b * y) * f (x, y) ∂(gaussianReal 0 1) = _
    have : ∀ y, exp (a * x + b * y) * f (x, y) = exp (a * x) * (exp (b * y) * f (x, y)) := by
      intro y; rw [exp_add]; ring
    simp_rw [this]
    rw [integral_const_mul, mg_tilt1 b (fun y => f (x, y))]
  simp_rw [hin]
  rw [mg_tilt1 a (fun x => exp (b ^ 2 / 2) * ∫ y, f (x, y + b) ∂(gaussianReal 0 1)),
    integral_const_mul]
  rw [← mul_assoc, ← exp_add]
  congr 2
  ring

#print axioms mg_tilt2

lemma mg_prob {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₂ Zperp : Ω → ℝ}
    (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q) (hZperp : HasLaw Zperp (gaussianReal 0 1) Q)
    (hind : IndepFun Z₂ Zperp Q) (K A B s : ℝ) (hs : 0 < s) (hsq : s ^ 2 = A ^ 2 + B ^ 2) :
    Q.real {ω | 0 < K + A * Z₂ ω + B * Zperp ω} = stdNormalCDF (K / s) := by
  have hX := gaussianReal_const_mul hZ₂ A
  have hY := gaussianReal_const_mul hZperp B
  have hind' : IndepFun (fun ω => A * Z₂ ω) (fun ω => B * Zperp ω) Q :=
    hind.comp (measurable_const_mul A) (measurable_const_mul B)
  have hmap := gaussianReal_add_gaussianReal_of_indepFun hind' hX hY
  have hlaw : HasLaw ((fun ω => A * Z₂ ω) + (fun ω => B * Zperp ω)) ((gaussianReal 0 1).map (s * ·)) Q := by
    refine ⟨hX.aemeasurable.add hY.aemeasurable, ?_⟩
    rw [hmap, gaussianReal_map_const_mul]
    congr 1
    · simp
    · apply NNReal.eq; simp [hsq]
  have hset : {ω | 0 < K + A * Z₂ ω + B * Zperp ω} =
      {ω | (fun w => 0 < K + w) (((fun ω => A * Z₂ ω) + (fun ω => B * Zperp ω)) ω)} := by
    ext ω; simp [add_assoc]
  have hms : MeasurableSet {w : ℝ | 0 < K + w} := measurableSet_lt measurable_const (by fun_prop)
  rw [hset, hlaw.measureReal_eq (p := fun w => 0 < K + w) hms,
    map_measureReal_apply (measurable_const_mul s) hms]
  have hpre : (s * ·) ⁻¹' {w : ℝ | 0 < K + w} = Set.Ioi (-(K / s)) := by
    ext z
    simp only [Set.mem_preimage, Set.mem_ofPred_eq, Set.mem_Ioi]
    rw [neg_lt, lt_div_iff₀ hs]
    constructor <;> intro h <;> linarith
  rw [hpre, mg_gauss_Ioi_neg]

#print axioms mg_prob

lemma mg_log (S₁ S₂ a b : ℝ) (h₁ : 0 < S₁) (h₂ : 0 < S₂) :
    log (S₁ * exp a / (S₂ * exp b)) = log S₁ - log S₂ + a - b := by
  rw [log_div (mul_pos h₁ (exp_pos a)).ne' (mul_pos h₂ (exp_pos b)).ne',
    log_mul h₁.ne' (exp_pos a).ne', log_mul h₂.ne' (exp_pos b).ne', log_exp, log_exp]
  ring

#print axioms mg_log

lemma mg_event (S₁ S₂ r q₁ q₂ σ₁ σ₂ ρ c T x y : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) :
    priceAtExpiry S₂ r q₂ σ₂ T x < priceAtExpiry S₁ r q₁ σ₁ T (ρ * x + c * y) ↔
      0 < (log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
        (σ₁ * √T * ρ - σ₂ * √T) * x + σ₁ * √T * c * y := by
  unfold priceAtExpiry
  rw [← log_lt_log_iff (mul_pos hS₂ (exp_pos _)) (mul_pos hS₁ (exp_pos _)),
    log_mul hS₂.ne' (exp_pos _).ne', log_mul hS₁.ne' (exp_pos _).ne', log_exp, log_exp]
  constructor <;> intro h <;> linarith

#print axioms mg_event

lemma mg_hasDerivAt_N (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hc : Continuous (gaussianPDFReal 0 1) := by unfold gaussianPDFReal; fun_prop
  have hN : ∀ x, stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
    intro x
    unfold stdNormalCDF
    rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
      ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
        (fun t _ ↦ gaussianPDFReal_nonneg 0 1 t))]
  have hint : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a ↦ (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun y ↦ stdNormalCDF 0 + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [hN, hN, ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint y)]
    ring
  rw [heq]
  exact ((hc.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

#print axioms mg_hasDerivAt_N

lemma mg_pdf_ratio (F K v : ℝ) (hF : 0 < F) (hK : 0 < K) (hv : 0 < v) :
    F * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v) =
      K * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v - v) := by
  set d1 := (log (F / K) + v ^ 2 / 2) / v with hd1
  have hsd : v * d1 = log (F / K) + v ^ 2 / 2 := by rw [hd1]; field_simp
  unfold gaussianPDFReal
  have hexp : -(d1 - v - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) =
      -(d1 - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + log (F / K) := by
    simp only [NNReal.coe_one]
    linear_combination hsd
  rw [hexp, exp_add, exp_log (div_pos hF hK)]
  field_simp

#print axioms mg_pdf_ratio

lemma mg_ratio (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂)
    (hv : 0 < effVol σ₁ σ₂ ρ * √T) :
    S₁ * exp (-q₁ * T) * gaussianPDFReal 0 1 (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T) =
      S₂ * exp (-q₂ * T) *
        gaussianPDFReal 0 1 (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T) := by
  unfold margrabeD1
  exact mg_pdf_ratio _ _ _ (mul_pos hS₁ (exp_pos _)) (mul_pos hS₂ (exp_pos _)) hv

#print axioms mg_ratio

lemma mg_second (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) (hT : 0 < T) :
    margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T =
      S₂ * exp (-q₂ * T) * bsCall (S₁ / S₂) 1 0 (q₁ - q₂) (effVol σ₁ σ₂ ρ) T := by
  unfold margrabePrice bsCall
  have hpos : 0 < S₂ * exp (-q₂ * T) := mul_pos hS₂ (exp_pos _)
  have e : exp (-q₂ * T) * exp (-(q₁ - q₂) * T) = exp (-q₁ * T) := by
    rw [← exp_add]; ring_nf
  have hratio : S₂ * exp (-q₂ * T) * (S₁ / S₂ * exp (-(q₁ - q₂) * T)) = S₁ * exp (-q₁ * T) := by
    rw [← e]; field_simp
  have h1 : (1 : ℝ) * exp (-0 * T) = 1 := by simp
  rw [h1]
  split_ifs with h
  · rw [mul_max_of_nonneg _ _ hpos.le, mul_sub, hratio, mul_one, mul_zero]
  · have hd : (log (S₁ / S₂ / 1) + (0 - (q₁ - q₂) + effVol σ₁ σ₂ ρ ^ 2 / 2) * T) /
        (effVol σ₁ σ₂ ρ * √T) = margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T := by
      unfold margrabeD1
      rw [mg_log _ _ _ _ hS₁ hS₂, div_one, log_div hS₁.ne' hS₂.ne', mul_pow, sq_sqrt hT.le]
      ring
    rw [hd]
    linear_combination (-(stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T))) * hratio

#print axioms mg_second
/-- **The exchange option is priced with no interest rate at all** (The formula; Why it works,
Steps 0 to 3 and the detailed proof). In the dollar pretend world `Q`, Birch's shock `Z₂` and a
second shock `Z⊥` are independent standard bell-curve draws, and Acme's shock is
`Z₁ = ρZ₂ + √(1 - ρ²) Z⊥`, so the two shocks have correlation `ρ` with `-1 ≤ ρ ≤ 1`. Both log
prices are bell-curved with constant volatilities `σ₁`, `σ₂`, steady dividend yields `q₁`, `q₂`
and bank rate `r`; today's prices are `S₁ > 0` and `S₂ > 0`, and the swap is used only at expiry,
`T > 0` years away. Then, whatever the bank rate `r`, the price of the right to hand over one
Birch share for one Acme share, the average payoff `max(S₁(T) - S₂(T), 0)` brought back to today
by `e^(-rT)`, is Margrabe's formula; and it equals `S₂e^(-q₂T)` Birch shares' worth of a
Black-Scholes call on the ratio `S₁/S₂`, strike 1, bank rate 0, dividend gap `q₁ - q₂`, at the
effective volatility `√(σ₁² + σ₂² - 2ρσ₁σ₂)`. -/
theorem exchange_option_price_is_margrabe_zero_rate_ratio_call
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₂ Zperp : Ω → ℝ}
    (S₁ S₂ r q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) (hT : 0 < T)
    (hρlo : -1 ≤ ρ) (hρhi : ρ ≤ 1)
    (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q) (hZperp : HasLaw Zperp (gaussianReal 0 1) Q)
    (hind : IndepFun Z₂ Zperp Q) :
    exp (-r * T) * ∫ ω, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * Z₂ ω + √(1 - ρ ^ 2) * Zperp ω)
        - priceAtExpiry S₂ r q₂ σ₂ T (Z₂ ω)) 0 ∂Q =
        margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T ∧
      margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T =
        S₂ * exp (-q₂ * T) * bsCall (S₁ / S₂) 1 0 (q₁ - q₂) (effVol σ₁ σ₂ ρ) T := by
  refine ⟨?_, mg_second S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T hS₁ hS₂ hT⟩
  have := hZ₂.isProbabilityMeasure
  have hP := hind.hasLaw_prod hZ₂ hZperp
  have hc2 : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := sq_sqrt (by nlinarith)
  have hs2 : √T ^ 2 = T := sq_sqrt hT.le
  have hE2 : effVol σ₁ σ₂ ρ ^ 2 = σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ := by
    unfold effVol
    have h1 : 0 ≤ 1 - ρ ^ 2 := by nlinarith
    have h2 := mul_nonneg (sq_nonneg σ₁) h1
    have h3 : 0 ≤ σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ := by nlinarith [sq_nonneg (σ₁ * ρ - σ₂)]
    exact sq_sqrt h3
  have hFm : Measurable (fun p : ℝ × ℝ => max (priceAtExpiry S₁ r q₁ σ₁ T
      (ρ * p.1 + √(1 - ρ ^ 2) * p.2) - priceAtExpiry S₂ r q₂ σ₂ T p.1) 0) := by
    simp only [priceAtExpiry]; fun_prop
  have htr : ∫ ω, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * Z₂ ω + √(1 - ρ ^ 2) * Zperp ω)
        - priceAtExpiry S₂ r q₂ σ₂ T (Z₂ ω)) 0 ∂Q =
      ∫ p, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) -
        priceAtExpiry S₂ r q₂ σ₂ T p.1) 0 ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) := by
    rw [← hP.integral_comp hFm.aestronglyMeasurable]; rfl
  rw [htr]
  have hX1 : ∀ p : ℝ × ℝ, priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) =
      S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) *
        exp (σ₁ * √T * ρ * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2) := by
    intro p; unfold priceAtExpiry; rw [mul_assoc S₁, ← exp_add]; congr 2; ring
  have hX2 : ∀ p : ℝ × ℝ, priceAtExpiry S₂ r q₂ σ₂ T p.1 =
      S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T) * exp (σ₂ * √T * p.1 + 0 * p.2) := by
    intro p; unfold priceAtExpiry; rw [mul_assoc S₂, ← exp_add]; congr 2; ring
  rcases (Real.sqrt_nonneg (σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)).eq_or_lt with hE | hE
  · -- the ratio cannot move
    have hE' : effVol σ₁ σ₂ ρ = 0 := hE.symm
    have h0 : (σ₁ * ρ - σ₂) ^ 2 + (σ₁ * √(1 - ρ ^ 2)) ^ 2 = 0 := by
      have := hE2; rw [hE'] at this
      rw [mul_pow σ₁, hc2]; linear_combination -this
    have hα : σ₁ * ρ - σ₂ = 0 := by
      have : (σ₁ * ρ - σ₂) ^ 2 = 0 := by
        nlinarith [sq_nonneg (σ₁ * ρ - σ₂), sq_nonneg (σ₁ * √(1 - ρ ^ 2))]
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
    have hβ : σ₁ * √(1 - ρ ^ 2) = 0 := by
      have : (σ₁ * √(1 - ρ ^ 2)) ^ 2 = 0 := by
        nlinarith [sq_nonneg (σ₁ * ρ - σ₂), sq_nonneg (σ₁ * √(1 - ρ ^ 2))]
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
    have hσsq : σ₁ ^ 2 = σ₂ ^ 2 := by
      have h1 : (σ₁ * √(1 - ρ ^ 2)) ^ 2 = 0 := by rw [hβ]; ring
      rw [mul_pow, hc2] at h1
      have : σ₂ = σ₁ * ρ := by linarith
      rw [this]; linear_combination h1
    have hpt : ∀ p : ℝ × ℝ, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) -
        priceAtExpiry S₂ r q₂ σ₂ T p.1) 0 =
        max (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) - S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T)) 0 *
          (exp (σ₂ * √T * p.1 + 0 * p.2) * 1) := by
      intro p
      rw [hX1, hX2, show σ₁ * √T * ρ * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2 =
        σ₂ * √T * p.1 + 0 * p.2 by linear_combination (√T * p.1) * hα + (√T * p.2) * hβ,
        ← sub_mul, mul_one, max_mul_of_nonneg _ _ (exp_pos _).le,
        zero_mul (exp (σ₂ * √T * p.1 + 0 * p.2))]
    simp_rw [hpt]
    rw [integral_const_mul, mg_tilt2 _ _ (fun _ => 1) measurable_const (by simp)]
    simp only [integral_const, probReal_univ, smul_eq_mul, mul_one]
    simp only [margrabePrice, hE', zero_mul, ↓reduceIte]
    rw [show exp (-r * T) * (max (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) -
          S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T)) 0 * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2)) =
        max (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) - S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T)) 0 *
          (exp (-r * T) * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2)) by ring,
      max_mul_of_nonneg _ _ (by positivity), zero_mul]
    have e1 : exp ((r - q₁ - σ₁ ^ 2 / 2) * T) * (exp (-r * T) * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2))
        = exp (-q₁ * T) := by
      rw [← exp_add, ← exp_add]; congr 1; rw [mul_pow, hs2]; linear_combination (-(T / 2)) * hσsq
    have e2 : exp ((r - q₂ - σ₂ ^ 2 / 2) * T) * (exp (-r * T) * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2))
        = exp (-q₂ * T) := by
      rw [← exp_add, ← exp_add]; congr 1; rw [mul_pow, hs2]; ring
    rw [sub_mul, mul_assoc S₁, e1, mul_assoc S₂, e2]
  · -- the ratio moves
    have hE' : 0 < effVol σ₁ σ₂ ρ := hE
    have hv : 0 < effVol σ₁ σ₂ ρ * √T := mul_pos hE' (sqrt_pos.2 hT)
    obtain ⟨f, hf⟩ : ∃ f : ℝ × ℝ → ℝ, f = fun p =>
        if priceAtExpiry S₂ r q₂ σ₂ T p.1 < priceAtExpiry S₁ r q₁ σ₁ T
          (ρ * p.1 + √(1 - ρ ^ 2) * p.2) then 1 else 0 := ⟨_, rfl⟩
    have hfm : Measurable f := by
      rw [hf]
      refine Measurable.ite ?_ measurable_const measurable_const
      exact measurableSet_lt (by unfold priceAtExpiry; fun_prop) (by unfold priceAtExpiry; fun_prop)
    have hfb : ∀ p, |f p| ≤ 1 := by
      intro p; rw [hf]; dsimp only; split_ifs <;> simp
    have hpay : ∀ p : ℝ × ℝ, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) -
        priceAtExpiry S₂ r q₂ σ₂ T p.1) 0 =
        S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) *
          (exp (σ₁ * √T * ρ * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2) * f p) -
        S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T) * (exp (σ₂ * √T * p.1 + 0 * p.2) * f p) := by
      intro p
      rw [hf]
      dsimp only
      by_cases h : priceAtExpiry S₂ r q₂ σ₂ T p.1 <
          priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2)
      · rw [ite_eq_left h, max_eq_left (by linarith), hX1, hX2]; ring
      · rw [ite_eq_right h, max_eq_right (by linarith)]; ring
    have hprob : ∀ K, ((gaussianReal 0 1).prod (gaussianReal 0 1)).real
        {p : ℝ × ℝ | 0 < K + (σ₁ * √T * ρ - σ₂ * √T) * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2} =
        stdNormalCDF (K / (effVol σ₁ σ₂ ρ * √T)) := by
      intro K
      have hms : MeasurableSet {p : ℝ × ℝ | 0 < K + (σ₁ * √T * ρ - σ₂ * √T) * p.1 +
          σ₁ * √T * √(1 - ρ ^ 2) * p.2} := measurableSet_lt measurable_const (by fun_prop)
      rw [← hP.measureReal_eq (p := fun p : ℝ × ℝ => 0 < K + (σ₁ * √T * ρ - σ₂ * √T) * p.1 +
          σ₁ * √T * √(1 - ρ ^ 2) * p.2) hms]
      apply mg_prob hZ₂ hZperp hind _ _ _ _ hv
      rw [mul_pow, hE2]
      linear_combination (-(√T ^ 2 * σ₁ ^ 2)) * hc2
    have hshift : ∀ a b, ∫ p, f (p.1 + a, p.2 + b) ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) =
        stdNormalCDF (((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * a + σ₁ * √T * √(1 - ρ ^ 2) * b) / (effVol σ₁ σ₂ ρ * √T)) := by
      intro a b
      rw [← hprob, ← integral_indicator_one (measurableSet_lt measurable_const (by fun_prop))]
      congr 1
      funext p
      rw [hf]
      simp only [Set.indicator, Set.mem_ofPred_eq, Pi.one_apply]
      simp only [mg_event S₁ S₂ r q₁ q₂ σ₁ σ₂ ρ (√(1 - ρ ^ 2)) T _ _ hS₁ hS₂]
      split_ifs with h1 h2 h2 <;> first | rfl | (exfalso; linarith)
    have hi1 := (mg_integrable_tilt (σ₁ * √T * ρ) (σ₁ * √T * √(1 - ρ ^ 2)) f hfm hfb).const_mul
      (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T))
    have hi2 := (mg_integrable_tilt (σ₂ * √T) 0 f hfm hfb).const_mul
      (S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T))
    simp_rw [hpay]
    rw [integral_sub hi1 hi2, integral_const_mul, integral_const_mul, mg_tilt2 _ _ f hfm hfb,
      mg_tilt2 _ _ f hfm hfb, hshift, hshift]
    have hK1 : ((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₁ * √T * ρ) +
          σ₁ * √T * √(1 - ρ ^ 2) * (σ₁ * √T * √(1 - ρ ^ 2))) / (effVol σ₁ σ₂ ρ * √T) =
        margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T := by
      unfold margrabeD1
      rw [mg_log _ _ _ _ hS₁ hS₂]
      congr 1
      rw [mul_pow, hE2]
      linear_combination (σ₁ ^ 2 * ρ ^ 2 - σ₁ * σ₂ * ρ + σ₁ ^ 2 * √(1 - ρ ^ 2) ^ 2 -
        (σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) / 2) * hs2 + T * σ₁ ^ 2 * hc2
    have hnum2 : (log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₂ * √T) + σ₁ * √T * √(1 - ρ ^ 2) * 0 =
        ((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₁ * √T * ρ) +
          σ₁ * √T * √(1 - ρ ^ 2) * (σ₁ * √T * √(1 - ρ ^ 2))) - (effVol σ₁ σ₂ ρ * √T) ^ 2 := by
      linear_combination √T ^ 2 * hE2 - √T ^ 2 * σ₁ ^ 2 * hc2
    have hK2 : ((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₂ * √T) + σ₁ * √T * √(1 - ρ ^ 2) * 0) /
          (effVol σ₁ σ₂ ρ * √T) =
        margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T := by
      rw [hnum2, sub_div, hK1]
      congr 1
      field_simp
    rw [hK1, hK2]
    simp only [margrabePrice, hv.ne', ↓reduceIte]
    have e1 : exp (-r * T) * (exp ((r - q₁ - σ₁ ^ 2 / 2) * T) *
        exp (((σ₁ * √T * ρ) ^ 2 + (σ₁ * √T * √(1 - ρ ^ 2)) ^ 2) / 2)) = exp (-q₁ * T) := by
      rw [← exp_add, ← exp_add]; congr 1
      simp only [mul_pow, hs2, hc2]; ring
    have e2 : exp (-r * T) * (exp ((r - q₂ - σ₂ ^ 2 / 2) * T) *
        exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2)) = exp (-q₂ * T) := by
      rw [← exp_add, ← exp_add]; congr 1
      simp only [mul_pow, hs2]; ring
    linear_combination (S₁ * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)) * e1 -
      (S₂ * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)) * e2

/-- **The vanilla call is the case where Birch is cash** (Step 5). Replace Birch by a bond paying
`K > 0` at expiry: today's price `K e^(-rT)`, no dividend, no volatility. Then Margrabe's formula,
at any correlation, gives the Black-Scholes call on Acme (`S₁ > 0`, volatility `σ₁ ≥ 0`) with the
fixed cash strike `K`, bank rate `r` and `T > 0` years to expiry. -/
theorem margrabe_with_bond_is_black_scholes_call
    (S₁ K r q₁ σ₁ ρ T : ℝ) (hS₁ : 0 < S₁) (hK : 0 < K) (hσ₁ : 0 ≤ σ₁) (hT : 0 < T) :
    margrabePrice S₁ (K * exp (-r * T)) q₁ 0 σ₁ 0 ρ T = bsCall S₁ K r q₁ σ₁ T := by
  have heff : effVol σ₁ 0 ρ = σ₁ := by
    unfold effVol
    rw [show σ₁ ^ 2 + 0 ^ 2 - 2 * ρ * σ₁ * 0 = σ₁ ^ 2 by ring]
    exact sqrt_sq hσ₁
  have e0 : K * exp (-r * T) * exp (-0 * T) = K * exp (-r * T) := by simp
  unfold margrabePrice margrabeD1 bsCall
  rw [heff, e0]
  split_ifs with h
  · rfl
  · have hd : (log (S₁ * exp (-q₁ * T) / (K * exp (-r * T))) + (σ₁ * √T) ^ 2 / 2) / (σ₁ * √T) =
        (log (S₁ / K) + (r - q₁ + σ₁ ^ 2 / 2) * T) / (σ₁ * √T) := by
      rw [mg_log _ _ _ _ hS₁ hK, log_div hS₁.ne' hK.ne', mul_pow, sq_sqrt hT.le]
      ring
    rw [hd]

/-- **The hedge holds shares and no cash** (Step 4). With `S₁ > 0`, `S₂ > 0`, `T > 0` and a ratio
that moves (`effVol σ₁ σ₂ ρ > 0`), the price's sensitivity to Acme is
`Δ₁ = e^(-q₁T) N(d₁)`, its sensitivity to Birch is `Δ₂ = -e^(-q₂T) N(d₂)`, and the price is
exactly `S₁Δ₁ + S₂Δ₂`, with no cash term (Euler's identity for a price of degree one). -/
theorem margrabe_deltas_and_shares_only_hedge
    (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) (hT : 0 < T)
    (hσ : 0 < effVol σ₁ σ₂ ρ) :
    HasDerivAt (fun x => margrabePrice x S₂ q₁ q₂ σ₁ σ₂ ρ T)
        (exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)) S₁ ∧
      HasDerivAt (fun y => margrabePrice S₁ y q₁ q₂ σ₁ σ₂ ρ T)
        (-(exp (-q₂ * T) *
          stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T))) S₂ ∧
      margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T =
        S₁ * (exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)) +
          S₂ * (-(exp (-q₂ * T) *
            stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T))) := by
  have hv : 0 < effVol σ₁ σ₂ ρ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have key := mg_ratio S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T hS₁ hS₂ hv
  refine ⟨?_, ?_, ?_⟩
  · have hfun : (fun x => margrabePrice x S₂ q₁ q₂ σ₁ σ₂ ρ T) = fun x =>
        x * exp (-q₁ * T) * stdNormalCDF (margrabeD1 x S₂ q₁ q₂ σ₁ σ₂ ρ T) -
          S₂ * exp (-q₂ * T) *
            stdNormalCDF (margrabeD1 x S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T) := by
      funext x
      simp only [margrabePrice, hv.ne', ↓reduceIte]
    have hin : HasDerivAt (fun x => x * exp (-q₁ * T) / (S₂ * exp (-q₂ * T)))
        (1 * exp (-q₁ * T) / (S₂ * exp (-q₂ * T))) S₁ :=
      ((hasDerivAt_id' S₁).mul_const _).div_const _
    have hne : S₁ * exp (-q₁ * T) / (S₂ * exp (-q₂ * T)) ≠ 0 :=
      (div_pos (mul_pos hS₁ (exp_pos _)) (mul_pos hS₂ (exp_pos _))).ne'
    obtain ⟨d', hd1⟩ : ∃ d', HasDerivAt (fun x => margrabeD1 x S₂ q₁ q₂ σ₁ σ₂ ρ T) d' S₁ :=
      ⟨_, ((hin.log hne).add_const _).div_const _⟩
    have hd2 := hd1.sub_const (effVol σ₁ σ₂ ρ * √T)
    have hN1 := (mg_hasDerivAt_N (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)).comp S₁ hd1
    have hN2 := (mg_hasDerivAt_N
      (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)).comp S₁ hd2
    have h := (((hasDerivAt_id' S₁).mul_const (exp (-q₁ * T))).mul hN1).sub
      (hN2.const_mul (S₂ * exp (-q₂ * T)))
    rw [hfun]
    refine h.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination d' * key
  · have hfun : (fun y => margrabePrice S₁ y q₁ q₂ σ₁ σ₂ ρ T) = fun y =>
        S₁ * exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ y q₁ q₂ σ₁ σ₂ ρ T) -
          y * exp (-q₂ * T) *
            stdNormalCDF (margrabeD1 S₁ y q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T) := by
      funext y
      simp only [margrabePrice, hv.ne', ↓reduceIte]
    have hden : HasDerivAt (fun y => y * exp (-q₂ * T)) (1 * exp (-q₂ * T)) S₂ :=
      (hasDerivAt_id' S₂).mul_const _
    have hin := (hasDerivAt_const S₂ (S₁ * exp (-q₁ * T))).div hden
      (mul_pos hS₂ (exp_pos _)).ne'
    have hne : S₁ * exp (-q₁ * T) / (S₂ * exp (-q₂ * T)) ≠ 0 :=
      (div_pos (mul_pos hS₁ (exp_pos _)) (mul_pos hS₂ (exp_pos _))).ne'
    obtain ⟨d', hd1⟩ : ∃ d', HasDerivAt (fun y => margrabeD1 S₁ y q₁ q₂ σ₁ σ₂ ρ T) d' S₂ :=
      ⟨_, ((hin.log hne).add_const _).div_const _⟩
    have hd2 := hd1.sub_const (effVol σ₁ σ₂ ρ * √T)
    have hN1 := (mg_hasDerivAt_N (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)).comp S₂ hd1
    have hN2 := (mg_hasDerivAt_N
      (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)).comp S₂ hd2
    have h := (hN1.const_mul (S₁ * exp (-q₁ * T))).sub
      (((hasDerivAt_id' S₂).mul_const (exp (-q₂ * T))).mul hN2)
    rw [hfun]
    refine h.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination d' * key
  · simp only [margrabePrice, hv.ne', ↓reduceIte]
    ring

/-! The card's exact worked numbers (fractions, no decimals). Acme and Birch: S₁ = S₂ = 100,
σ₁ = σ₂ = 1/5, q₁ = q₂ = 2/100, ρ = 1/2, T = 1. -/

-- Acme ends at $120 and Birch at $110: the swap earns $10.
example : max ((120 : ℤ) - 110) 0 = 10 := by decide
-- Acme ends below Birch: the holder walks away with nothing.
example : max ((100 : ℤ) - 110) 0 = 0 := by decide
-- Step 0, the payoff factors: max(120 - 110, 0) = 110 · max(120/110 - 1, 0).
example : max ((120 : ℚ) - 110) 0 = 110 * max (120 / 110 - 1) 0 := by norm_num
-- Step 1: effective variance 0.04 + 0.04 - 2 × 0.5 × 0.2 × 0.2 = 0.04.
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 - 2 * (1 / 2) * (1 / 5) * (1 / 5) = 1 / 25 := by norm_num
-- Effective volatility √0.04 = 0.20.
example : effVol (1 / 5) (1 / 5) (1 / 2) = 1 / 5 := by
  rw [effVol, show (1 / 5 : ℝ) ^ 2 + (1 / 5) ^ 2 - 2 * (1 / 2) * (1 / 5) * (1 / 5) = (1 / 5) ^ 2 by
    norm_num]
  exact Real.sqrt_sq (by norm_num)
-- At correlation -1 the ratio moves 40 percent a year: √0.16 = 0.4.
example : effVol (1 / 5) (1 / 5) (-1) = 2 / 5 := by
  rw [effVol, show (1 / 5 : ℝ) ^ 2 + (1 / 5) ^ 2 - 2 * (-1) * (1 / 5) * (1 / 5) = (2 / 5) ^ 2 by
    norm_num]
  exact Real.sqrt_sq (by norm_num)
-- At correlation +1 the two shares take the same shock, the ratio never moves, and the option
-- on Acme and Birch is worthless.
example : margrabePrice 100 100 (2 / 100) (2 / 100) (1 / 5) (1 / 5) 1 1 = 0 := by
  norm_num [margrabePrice, effVol]
-- d₁ = (ln 1 + 0.5 × 0.04) / 0.20 = 0.1, and d₂ = 0.1 - 0.20 = -0.1.
example : (log 1 + (1 / 2 : ℝ) * (1 / 25)) / (1 / 5) = 1 / 10 := by norm_num
example : (1 / 10 : ℚ) - 1 / 5 = -1 / 10 := by norm_num
-- The price: 52.914 - 45.106 = 7.808, which rounds to $7.81.
example : (52914 / 1000 : ℚ) - 45106 / 1000 = 7808 / 1000 := by norm_num
-- Step 4: 0.52914 × $100 - 0.45106 × $100 = $7.808.
example : (52914 / 100000 : ℚ) * 100 - 45106 / 100000 * 100 = 7808 / 1000 := by norm_num
-- What breaks: no correlation term gives variance 0.08, the plus sign 0.12, the missing 2 0.06.
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 = 2 / 25 := by norm_num
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 + 2 * (1 / 2) * (1 / 5) * (1 / 5) = 3 / 25 := by norm_num
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 - (1 / 2) * (1 / 5) * (1 / 5) = 3 / 50 := by norm_num
-- The profit chart: Birch at $100 and Acme at $110 gives $10 - $7.81 = $2.19; Birch at $110
-- slides the kink, and Acme at $120 gives the same $2.19.
example : max ((110 : ℚ) - 100) 0 - 781 / 100 = 219 / 100 := by norm_num
example : max ((120 : ℚ) - 110) 0 - 781 / 100 = 219 / 100 := by norm_num

#print axioms exchange_option_price_is_margrabe_zero_rate_ratio_call
#print axioms margrabe_with_bond_is_black_scholes_call
#print axioms margrabe_deltas_and_shares_only_hedge
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'mg_gauss_Ioi_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_tilt1' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_integrable_tilt' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_tilt2' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_prob' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_log' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_event' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_hasDerivAt_N' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_pdf_ratio' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_ratio' depends on axioms: [propext, Classical.choice, Quot.sound]
'mg_second' depends on axioms: [propext, Classical.choice, Quot.sound]
'exchange_option_price_is_margrabe_zero_rate_ratio_call' depends on axioms: [propext, Classical.choice, Quot.sound]
'margrabe_with_bond_is_black_scholes_call' depends on axioms: [propext, Classical.choice, Quot.sound]
'margrabe_deltas_and_shares_only_hedge' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess the direction first. Then run it.
> - **Make the shares opposites.** Set `rho = -1.0`. The ratio's volatility doubles to 40 percent and the price rises to **$15.54**. A falling Birch now tends to come with a rising Acme, which is exactly when the swap pays.
> - **Give Acme a head start.** Set `S1 = 110.0`. The price rises to **$14.01**: the swap is already worth $9.80 on today's prices net of dividends, plus the chance of more.
> - **Change the bank rate.** Run road 2 at `r = 0.10`. The price stays at **$7.81**. Both shares drift faster, the discount is heavier, and the two effects cancel exactly.
> - **Make Birch jumpier.** Set Birch's volatility to `0.30`. The effective volatility rises and the price rises to **$10.32**, even though the correlation is still 0.5.

---

## The usual mistake

> [!warning]
> **Pricing the swap as a call with a fixed strike.** Birch at $100 today is not a $100 strike. Treat it as one and the price comes out at $9.23, the house vanilla, against the right $7.81. A cash strike stays put while Acme is expected to grow; Birch is expected to grow at the same rate. And when Acme rises, Birch tends to rise too, so the strike chases the share. Only the movement of the ratio is worth paying for, and the effective volatility measures that.
>
> Smaller traps:
> - **Leaving the correlation out.** Adding the two variances with no cross term prices the pair as independent: $11.02 instead of $7.81.
> - **The wrong sign or the missing 2 in the cross term.** A plus sign gives $13.48; a single cross term gives $9.55. The variance of a difference is each variance minus twice the covariance, the shared part $\rho\sigma_1\sigma_2$.
> - **Discounting at the bank rate.** No $e^{-rT}$ belongs in the formula. Each share's value delivered at expiry is already its price today net of dividends; discounting again counts the bank rate twice.
> - **Forgetting the dividends.** Dropping both yields gives $7.97. Equal yields cancel in the ratio, but not in the size of each share delivered.

---

## Where you meet it in real life

- **Share-for-share takeovers.** A bid that offers the acquirer's shares for the target's contains exchange options: a holder who may accept or decline the swap holds the right to exchange one share for another.
- **Outperformance options.** A fund manager's bonus that pays if one index beats another is an exchange option on the two indices, and its price depends on their correlation more than on either index alone.
- **Spread options on commodities.** Refiners and power producers hold options on the gap between two prices. With no fixed strike, that is this card; with one, it needs an approximation: [Spread options](02-spread-options-and-kirk.md).
- **Best-of and worst-of contracts.** The larger of two prices is Birch plus the right to swap Birch for Acme, so a best-of pays one share and one exchange option: [Rainbow options](04-rainbow-best-of-and-worst-of.md).
- **Options on a basket.** Sums of lognormal prices have no exact formula; the exchange option has one because a ratio of lognormals is lognormal: [Basket options](03-basket-options.md).

> **Say it back**
> An exchange option is the right to hand over one share and receive another at expiry. Counted in units of the share handed over, it is a call on the ratio of the two prices with a strike of one, and in that unit no interest is earned, so the bank rate drops out. The ratio's volatility is each share's variance added, less twice the shared part. For Acme and Birch at correlation 0.5 the price is $7.81; at correlation 1 it is zero. Replace the second share with a bond and the formula becomes the Black-Scholes call.

---

## What this builds on

- [Black–Scholes call](../08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md): the call formula this card reuses at a zero rate, and the slide of the bell curve behind the reweighting.
- [Change of numeraire](../../11-Stochastic%20processes%20and%20calculus/07-Changing%20Measure/05-change-of-numeraire.md): why prices counted in any traded asset are fair games under that asset's own probabilities.
- [Correlated paths](../06-Numerical%20Methods%20for%20Pricing/04-correlated-paths-and-cholesky.md): how to draw two correlated shocks from two independent ones, the third road in the code.

## Where this goes next

- [Spread options](02-spread-options-and-kirk.md): the swap with a cash strike added, paying Acme minus Birch minus a fixed amount.

The ratio trick works because the payoff has no cash in it; add a fixed strike to the swap and the payoff is no longer a function of the ratio alone, and how to price it anyway is the next card's question.

---

## Sources

Verified 2026-09-24: every link below resolves to the publisher's page.

- Margrabe, William. "The Value of an Option to Exchange One Asset for Another." *Journal of Finance* 33, no. 1 (1978): 177–186. [doi:10.1111/j.1540-6261.1978.tb03397.x](https://doi.org/10.1111/j.1540-6261.1978.tb03397.x). The formula, the vanishing bank rate, and the early-exercise remark.
- Fischer, Stanley. "Call Option Pricing When the Exercise Price Is Uncertain, and the Valuation of Index Bonds." *Journal of Finance* 33, no. 1 (1978): 169–176. [doi:10.1111/j.1540-6261.1978.tb03396.x](https://doi.org/10.1111/j.1540-6261.1978.tb03396.x). The same result reached independently, in the same issue.
- Geman, Hélyette, Nicole El Karoui, and Jean-Charles Rochet. "Changes of Numéraire, Changes of Probability Measure and Option Pricing." *Journal of Applied Probability* 32, no. 2 (1995): 443–458. [doi:10.2307/3215299](https://doi.org/10.2307/3215299). The numeraire argument of Step 0 made rigorous, with the exchange option as a worked case.
- Shreve, Steven E. *Stochastic Calculus for Finance II: Continuous-Time Models*. Springer, 2004. [Publisher page](https://link.springer.com/book/9780387401010). Change of numeraire and multi-asset risk-neutral pricing, the tools of the detailed proof.
