# Implied vol from an Asian quote: invert the moment-matched price, and why it is not the vanilla's vol

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Averages - commodity swaps and Asian options](../README.md#s27) → Implied vol from an Asian quote

---

## General Overview

A broker offers an airline a one-year call on the average price of jet fuel at \$5.854 a barrel. The contract reads the price once a week, 52 times; each reading is a **fixing**. At the end of the year it pays, per barrel, the average of the fixings above the \$100 strike. Each fixing reads the futures market. Jet fuel is \$100 today, and futures prices rise along the delivery dates as $100e^{0.05t}$ for delivery in $t$ years, reaching \$105.13 for December. The bank rate is 5 percent.

Every input to the price can be looked up except one: the **volatility**, the yearly spread of the futures price's log changes. Desks argue in volatility, not dollars. So the premium is run backwards: the **implied volatility** is the one volatility at which the pricing formula returns the quote.

The quick formula for this contract is Turnbull-Wakeman, which treats the average as lognormal (its log follows a bell curve) with the average's exact mean and mean square ([The Asian option desks trade](03-arithmetic-asian-option.md)). Run backwards on \$5.854, it answers 19.91 percent. A simulation of the exact model, run backwards the same way, answers 20.00 percent. The \$5.854 was that simulation's price at 20 percent, so both roads agree the quote means 20 percent volatility.

Now read the same \$5.854 through the plain call formula, fed the strip's own forward, the swap price of \$102.59. It answers 11.75 percent. Fed the December futures price, it answers 7.08 percent. Neither is a volatility of jet fuel: an average moves less than one price, and the plain formula mistakes the averaging for calm. The wrong contract gives the wrong vol. A rule of thumb repairs the reading: an average taken evenly from today to expiry carries about one third of the last price's total variance, so 11.75 percent times the square root of 3 should land near the Asian's vol. It gives 20.36 percent.

**The moment-matched price rises strictly with volatility, so an Asian quote between its zero-volatility floor and its infinite-volatility ceiling gives exactly one implied vol, on the same scale as a vanilla's; the same premium read through the vanilla formula returns the average's own spread, about the square root of a third of it.**

**What kind of fact this is:** a method, inverting a price formula, resting on a theorem: the price rises strictly with volatility, proved on this card in Why it works for Turnbull-Wakeman and on [Asian Greeks and implied volatility](../17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/03-asian-greeks-and-implied-volatility.md) for the exact price. The divide-by-three rule is an approximation, its error stated in Worked numbers.

### The picture: two price curves, one quote

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Price against volatility: jet fuel Asian call and December vanilla, strike $100"
    x-axis "Volatility of jet fuel futures (%)" ["0", "5", "10", "15", "20", "25", "30", "35", "40"]
    y-axis "Premium ($ per barrel)" 0 --> 20
    line [2.47, 2.77, 3.71, 4.77, 5.87, 6.99, 8.11, 9.25, 10.38]
    line [4.88, 5.28, 6.80, 8.59, 10.45, 12.34, 14.23, 16.13, 18.02]
    line [5.85, 5.85, 5.85, 5.85, 5.85, 5.85, 5.85, 5.85, 5.85]
```

First line, lower: the Asian call by Turnbull-Wakeman, rising from its floor of \$2.47 at zero volatility. Second line, upper: a plain call on the December futures, from its floor of \$4.88. Flat line: the \$5.854 quote. Each rising line crosses the quote once. The Asian crosses near 20 percent; the vanilla crosses between 5 and 10 percent, at 7.08.

---

## The formula

Notation first, in words. $Q$ is the quoted premium. $C_{TW}(\sigma)$ is the Turnbull-Wakeman price when every fixing has volatility $\sigma$. The implied volatility $\hat\sigma$, read "sigma hat", is the solution of one equation:

$$C_{TW}(\hat\sigma) = Q, \qquad C_{TW}(\sigma) = e^{-rT}\big(M_1\,N(e_1) - K\,N(e_2)\big)$$

**Read it aloud:** find the volatility at which the moment-matched price of the average equals the quote.

The price is Black-76, the plain call formula for a futures price, fed the average's forward $M_1$ and the average's own log-spread $v_A$. [The Asian option desks trade](03-arithmetic-asian-option.md) derives the parts; here they are in one line each.

$$M_1 = \frac1n\sum_{i=1}^{n} F(0,t_i), \qquad M_2(\sigma) = \frac{1}{n^2}\sum_{i=1}^{n}\sum_{j=1}^{n} F(0,t_i)\,F(0,t_j)\,e^{\sigma^2\min(t_i,\,t_j)}$$

In words: $M_1$ is the plain average of the futures curve at the fixing dates, the price of the matching swap; $M_2$ is the average's mean square, and it is the only place volatility enters.

$$v_A(\sigma) = \sqrt{\ln\!\big(M_2/M_1^2\big)}, \qquad e_1 = \frac{\ln(M_1/K) + \tfrac12 v_A^2}{v_A}, \qquad e_2 = e_1 - v_A$$

In words: $v_A$ is the log-spread a lognormal needs to have both moments; $e_1$ and $e_2$ are the plain call's cut-offs with the average in place of the futures price.

A solution exists, and only one, exactly when the quote sits inside a band:

$$e^{-rT}\,(M_1 - K)^+ \;<\; Q \;<\; e^{-rT}\,M_1$$

**Read it aloud:** the quote must exceed the discounted payoff with no volatility at all, and stay below the discounted value of the whole average.

Newton's method solves it fast, stepping by the price error over the slope:

$$\sigma_{k+1} = \sigma_k - \frac{C_{TW}(\sigma_k) - Q}{\mathcal{V}(\sigma_k)}, \qquad \mathcal{V}(\sigma) = e^{-rT}\,M_1\,\varphi(e_1)\,\frac{M_2'(\sigma)}{2\,v_A\,M_2}$$

In words: $\mathcal{V}$, the vega, is the price's slope in volatility; $\varphi$ is the bell curve's height; and $M_2'$ is the slope of $M_2$, the same double sum with each term multiplied by $2\sigma\min(t_i,t_j)$.

The sanity check reads the vanilla formula's answer back into an Asian vol:

$$\sigma_{\text{van}} \approx \hat\sigma\,\sqrt{c}, \qquad c = \frac{(n+1)(2n+1)}{6n^2} \;\to\; \frac13, \qquad c \approx \frac{t_0 + L/3}{T} \text{ for a window}$$

**Read it aloud:** the vol the plain formula reads is the Asian's vol times the square root of the share of variance the average keeps: a third for an average from today to expiry, more for an average squeezed near expiry.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $Q$ | the quoted Asian premium, per barrel | \$5.854 | implied vol rises |
| $\sigma$, $\sigma_k$, $\hat\sigma$ | a trial volatility; Newton's k-th guess; the implied volatility | 20%; from 30%; 19.91% by the formula, 20.00% by simulation | — |
| $C_{TW}$ | the Turnbull-Wakeman price at a given volatility | \$5.87 at 20% | is the answer's target |
| $K$, $r$, $T$ | strike; bank rate, continuously compounded; expiry in years; $e^{-rT}$ discounts a dollar paid at $T$ | \$100; 5%; 1 | $K$ up: implied vol up for the same quote |
| $n$, $i$, $j$, $t_i$ | number of fixings; their counters; date of fixing $i$ in years | 52 weekly; $t_i = i/52$ | $n$ up: slightly less variance kept |
| $F(0,t)$, $F_i$, $t$ | today's futures price for delivery at date $t$; the one at fixing $i$ | $100e^{0.05t}$; \$105.13 for December | curve up: implied vol down |
| $M_1$, $M_2$, $M_2'$ | mean of the average, the swap price; its mean square; that square's slope in $\sigma$ | \$102.59 | $M_1$ up: floor and ceiling rise |
| $v_A$, $e_1$, $e_2$ | the average's fitted log-spread over the whole life; the cut-offs | 0.1180 at 20% | $v_A$ up: price up |
| $N$, $\varphi$ | bell-curve area to the left; bell-curve height | — | — |
| $\mathcal{V}$ | vega, dollars per unit of volatility | \$0.2219 per point at 20% | bigger vega: flatter inverse, a tighter vol |
| $\sigma_{\text{van}}$, $c$ | the vol the plain formula reads from $Q$; share of the last price's log-variance the average keeps | 11.75%; 0.343 | $c$ up: the two vols converge |
| $t_0$, $L$, $W$ | start and length of an averaging window; in the proofs, the one random path moving the curve | December: 11/12 and 1/12 of a year | $t_0$ up: $c$ nearer 1 |

### When it holds

- **One volatility for every fixing.** Near-dated energy futures usually move more than far-dated ones. The Asian's single implied vol is then a blend of the strip's vols, weighted toward the later fixings, and it need not equal the December option's vol even when the market is consistent.
- **One random path moves the whole curve.** If the fixings read delivery months that are not perfectly correlated, the true $M_2$ is smaller, the market price is lower, and the implied vol reads low.
- **The lognormal fit.** Turnbull-Wakeman overprices this contract by 1.9 cents at 20 percent. Divided by the vega of 22 cents a point, that is roughly the gap between its 19.91 percent and the simulation's 20.00 percent, and it grows with the total variance $\sigma^2 T$.
- **A quote inside the band.** Below \$2.47 or above \$97.59 no volatility fits; a solver without the check returns the edge of its search interval, which means nothing.
- **No fixings banked.** Part-way through the year, invert the open part of the contract with its shifted strike ([Asian Greeks and the average already banked](04-asian-greeks-and-the-running-average.md)). If the banked fixings already guarantee payment, the price no longer depends on volatility and no implied vol exists.

---

## Why it works

### Step 0: an inverse needs a price that only climbs

A quote maps to one volatility only if the price rises strictly as volatility rises. Then each price level is crossed once, and a search that keeps the half of an interval containing the quote cannot miss. The equity card on shelf 17 proves the exact Asian price has this property, by a convexity argument, and inverts an Acme quote back to 20 percent ([Asian Greeks and implied volatility](../17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/03-asian-greeks-and-implied-volatility.md)). This card spends its length on what a commodity changes: the average is of futures prices along a curve, the formula is Black-76 with the strip's forward in place of a spot price, and the fixing schedule is the contract's own.

### Step 1: the band comes from the swap price

With no volatility every fixing lands on today's futures price, so the average lands on $M_1$, the swap price, \$102.59. The call then pays $M_1 - K$ for sure, worth $e^{-rT}(M_1 - K)$ = \$2.47 today. That is the floor.

With unbounded volatility almost every path's average collapses toward zero while its mean stays at $M_1$: the rare huge paths carry the whole mean. The strike then almost never matters, and the call is worth the discounted average itself, \$97.59. That is the ceiling.

The floor is commodity-specific. An equity desk grows a spot price at the bank rate less the dividend yield. A fuel desk reads the curve at each fixing date. The December vanilla's floor is higher, \$4.88, because its forward is the curve's far end, \$105.13, not the average of the curve.

### Step 2: the moment-matched price rises strictly with volatility

Volatility enters only through $M_2$. Each term of $M_2$ is $F_i F_j e^{\sigma^2\min(t_i,t_j)}$, which grows with $\sigma$. So $M_2$ grows, and $v_A$ grows with it. The Black-76 price grows with $v_A$: a wider spread lifts a call, whose loss is capped. A chain of increasing steps is increasing.

<details>
<summary>Detailed proof: monotone, continuous, and one root</summary>

**Slope in the spread.** Write $B(v) = e^{-rT}\big(M_1 N(e_1) - K N(e_1 - v)\big)$. The identity $M_1\varphi(e_1) = K\varphi(e_2)$ holds because $\ln(M_1/K) = \tfrac12(e_1^2 - e_2^2)$, which is the definition of $e_1$ rearranged. Differentiating, the terms in $\partial e_1/\partial v$ cancel by that identity, leaving $B'(v) = e^{-rT} M_1\varphi(e_1) > 0$.

**Slope of the spread.** $v_A^2 = \ln M_2 - 2\ln M_1$, and $M_1$ does not involve $\sigma$. So $2 v_A v_A' = M_2'/M_2$. Every term of $M_2'$ is $2\sigma\min(t_i,t_j)F_iF_je^{\sigma^2\min(t_i,t_j)}$, positive for $\sigma > 0$. Hence $v_A' > 0$, and by the chain rule $\mathcal{V} = B'(v_A)\,v_A' > 0$: the formula in The formula.

**Limits.** As $\sigma \to 0$, $M_2 \to M_1^2$ and $v_A \to 0$. If $M_1 > K$, both cut-offs run to $+\infty$ and the price tends to $e^{-rT}(M_1 - K)$; if $M_1 < K$, both run to $-\infty$ and it tends to 0. Either way the limit is the floor. As $\sigma \to \infty$, $M_2 \to \infty$ and $v_A \to \infty$; then $e_1 \to +\infty$ and $e_2 = (\ln(M_1/K) - \tfrac12 v_A^2)/v_A \to -\infty$, so the price tends to $e^{-rT}M_1$.

**One root.** The price is continuous and strictly increasing in $\sigma$ and runs between the two limits without reaching either. By the intermediate value theorem each $Q$ strictly inside the band is hit exactly once, and no $Q$ outside it is hit at all.

</details>

### Step 3: two solvers on the formula

**Bisection** brackets the root between 0.0001 percent and 500 percent, checks that the quote lies between the prices at the two ends, and halves until the interval is narrower than $10^{-13}$. It cannot fail, because the price only climbs.

**Newton's method** replaces the price curve by its tangent at the current guess and jumps to where the tangent meets the quote ([Newton's method](../../06-Calculus%20and%20analysis/03-What%20Derivatives%20Tell%20You/06-newtons-method.md)). The slope is the exact vega from Step 2. From 30 percent the guesses run 19.987221, 19.913274, 19.913267 percent. The curve in the picture is nearly straight, so the first jump lands within a tenth of a point. Bisection and Newton agree to every printed digit.

### Step 4: a third road, inverting the simulation

Turnbull-Wakeman is an approximation. The exact model has no formula, but it has a precise simulation: 50,000 simulated years of weekly fixings, priced with the geometric average as a control, whose exact price corrects most of the noise (the method of [The Asian option desks trade](03-arithmetic-asian-option.md)). At 20 percent it gives \$5.854446 with an error bar of a tenth of a cent.

To invert it, draw the random numbers once and reuse them at every trial volatility. Then the simulated price is a smooth function of $\sigma$, not a new noisy number at each try. The secant method, Newton with the slope estimated from the last two tries, needs 6 simulated prices to find 19.998 percent. The formula's 19.91 percent is the lognormal fit's error expressed in volatility.

### Step 5: why the vanilla formula reads the average's spread

Turnbull-Wakeman *is* Black-76, fed $M_1$ and $v_A$. So if the vanilla formula is fed the swap price $M_1$ and asked what volatility reproduces \$5.854, it must answer $v_A(\hat\sigma)$, the average's log-spread over the year: 11.75 percent. The code prints both: they agree to every digit.

That number is a property of the average, not of jet fuel. $\hat\sigma$ is the volatility of each fixing, the same kind of number as the December vanilla's implied vol, and the two can be compared directly. $\sigma_{\text{van}}$ is smaller because averaging cancels part of the movement.

Feeding the December futures instead, \$105.13, gives 7.08 percent. The vanilla formula then also believes the payoff centres on \$105.13 rather than \$102.59, and cuts the volatility further to hold the price down.

### Step 6: total variance divided by three

The log of an average behaves nearly like the average of the logs, and that is a bell curve whose variance can be counted. For an average taken evenly from today to expiry, it keeps a share $c$ of the last price's log-variance $\sigma^2 T$. Continuous averaging keeps exactly one third. Weekly averaging over 52 weeks keeps 0.343, a touch more because the last fixing sits on the expiry date.

So $v_A \approx \hat\sigma\sqrt{cT}$, and the Asian's vol can be recovered from the vanilla reading: 11.75 percent times the square root of 3 is 20.36 percent; divided by the square root of 0.343 it is 20.07 percent. Both land within half a point of 20.00. What remains is the curve's slope and the lognormal fit.

<details>
<summary>Detailed proof: where the three comes from</summary>

Let $W$ be the Brownian path driving every fixing: its values at two dates have covariance equal to the earlier date. The log of fixing $i$ is a constant plus $\sigma W_{t_i}$, so the average of the logs has variance $\sigma^2$ times $\frac{1}{n^2}\sum_i\sum_j \min(t_i,t_j)$.

With $t_i = iT/n$, the double sum counts each $\min(i,j)$: $\sum_i\sum_j \min(i,j) = \sum_{k=1}^{n}(n-k+1)^2 = n(n+1)(2n+1)/6$. So the variance is $\sigma^2 T\,(n+1)(2n+1)/(6n^2) = \sigma^2 T c$. As $n$ grows, $c \to 2n^3/(6n^3) = 1/3$.

For a window of length $L$ ending at $T$, starting at $t_0 = T - L$, split the path at each fixing into its value at the window's start plus its movement after that. The first part is shared by every fixing and contributes $t_0$. The second is a fresh average over length $L$ and contributes $L/3$. So $c \approx (t_0 + L/3)/T$.

</details>

### Step 7: the fixing schedule changes the rule

Commodity average options often settle on one calendar month: the average of the daily prices in that month. Take one on the December month, bought now: 21 daily fixings from 11/12 of a year to one year.

**Conventions verified 28 Sep 2026:** a listed Gulf Coast jet fuel swap averages a daily price over every business day of its contract month ([Asian Greeks and the average already banked](04-asian-greeks-and-the-running-average.md)). The 52 weekly fixings elsewhere on this card are the shelf's simpler schedule.

Most of the variance is already in place before the window opens, so the average keeps almost all of it: $c \approx 11/12 + 1/36$, and the rule says $\sigma_{\text{van}} \approx$ 19.44 percent.

The card's own check prices this contract at 20 percent: \$10.12, next to \$10.45 for the December vanilla. Read through the vanilla formula on its swap price, \$104.92, it gives 19.46 percent, against the rule's 19.44. Applying "divide by three" blindly would claim the Asian's vol is 33.70 percent. The rule is about the schedule, not about Asians.

---

## Worked numbers, by hand

Jet fuel: curve $100e^{0.05t}$, $K$ = \$100, $r$ = 5%, $T$ = 1 year, 52 weekly fixings, quote $Q$ = \$5.854.

| Step | Arithmetic | Value |
| --- | --- | --- |
| swap price | $M_1 = \frac{1}{52}\sum 100e^{0.05\,i/52}$ | \$102.5915 |
| floor | $e^{-0.05}(102.5915 - 100)$ | \$2.4651 |
| ceiling | $e^{-0.05} \times 102.5915$ | \$97.5881 |
| quote inside the band? | 2.4651 < 5.854 < 97.5881 | yes: one vol |
| Turnbull-Wakeman at 20% | Black-76 on $M_1$, $v_A$ = 0.1180 | \$5.873245 |
| gap to the quote | 5.873245 − 5.854 | \$0.019245 |
| vega at 20% | per volatility point | \$0.221911 |
| one Newton step | 20% − 0.019245 / 0.221911 points | 19.9133% |
| a second step | the step is now tiny | **19.913267%** |
| simulation, inverted | 6 prices on shared draws | **20.00%** |
| vanilla formula on $M_1$ | the log-spread at which Black-76 gives 5.854 | 11.75% |
| times the square root of 3 | continuous-average rule | 20.36% |
| divided by the square root of 0.343 | weekly-average rule | 20.07% |

A broker's \$5.854 is a quote for 20 percent volatility on jet fuel futures, the same volatility a December option at \$10.45 carries.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Read the Asian premium with the vanilla formula on the December futures | 7.08% | the wrong payoff and the wrong forward; averaging read as calm |
| Read it with the vanilla formula on the swap price | 11.75% | that is the average's spread, not a fixing's volatility |
| Price the average off a flat \$100, the equity habit with no carry | 26.29% | the forward is too low, so the volatility inflates to fill the premium |
| Treat the 52 fixings as independent draws | 118.71% | neighbouring weeks share almost all their movement |
| Solve a quote of \$2.40, below the floor | no volatility | the quote is under the zero-volatility value; the model cannot reach it |
| Apply divide-by-three to a December-month average | 33.70%, not 19.46% read | its window opens late, so it keeps most of the variance |

The code prints all six.

---

## Code, from first principles, and it actually runs

The code reaches the implied vol by three roads: bisection on Turnbull-Wakeman, Newton's method on Turnbull-Wakeman with its exact vega, and the secant method on the controlled simulation with shared random draws. It then reads the quote through the vanilla formula two ways, runs the divide-by-three check for the weekly and the December schedules, and prints every number on the card. The simulation uses the arithmetic-asian-option card's seed, so its price at 20 percent matches that card's.

### Python

```python
# Implied vol from an Asian quote on jet fuel: 52 weekly fixings read the futures curve 100 e^(0.05 t).
# Standard library only.  Nothing imported knows the answer: the bell-curve area, both root finders,
# the random numbers (splitmix64 + Box-Muller) and every simulated path are written out below.
from math import log, sqrt, exp, cos, pi, isnan
from array import array

K, r, T, n, Q = 100.0, 0.05, 1.0, 52, 5.854        # Q: the house Asian quote, $ per barrel

def N(x):                                   # area left of x: Marsaglia's series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        i += 2.0
        b, t = b * x * x / i, s
        s += b
    return 0.5 + s * exp(-0.5 * x * x - 0.91893853320467274178)
def black(F, v, k=K, tp=T):                 # Black-76: call on a lognormal with forward F, whole-life log-spread v
    d1 = (log(F / k) + 0.5 * v * v) / v
    return exp(-r * tp) * (F * N(d1) - k * N(d1 - v))
def curve(c, lvl=100.0): return lambda t: lvl * exp(c * t)
def dates(m, t1=T, t0=0.0): return [t0 + (t1 - t0) * (i + 1) / m for i in range(m)]
fw, ts = curve(0.05), dates(n)

def tw(s, f=fw, tx=ts, k=K):                # Turnbull-Wakeman price and its exact slope in s (vega)
    m, Fs = len(tx), [f(t) for t in tx]
    M1 = sum(Fs) / m
    M2 = dM2 = 0.0
    for i in range(m):
        for j in range(m):
            a = Fs[i] * Fs[j] * exp(s * s * min(tx[i], tx[j]))
            M2, dM2 = M2 + a, dM2 + a * 2.0 * s * min(tx[i], tx[j])
    M2, dM2 = M2 / (m * m), dM2 / (m * m)
    v = sqrt(log(M2 / (M1 * M1)))
    e1 = (log(M1 / k) + 0.5 * v * v) / v
    return black(M1, v, k, tx[-1]), exp(-r * tx[-1]) * M1 * exp(-0.5 * e1 * e1) / sqrt(2.0 * pi) * dM2 / (2.0 * v * M2), M1, v

def bisect(f, q, lo=1e-6, hi=5.0):         # f increasing: keep the half that straddles q
    if not f(lo) < q < f(hi): return float("nan")        # outside the band: no volatility fits
    while hi - lo > 1e-13:
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < q else (lo, mid)
    return 0.5 * (lo + hi)
def newton(q, s=0.30):                      # step by price error over vega; the path is kept
    path = [s]
    while True:
        p, vg = tw(s)[:2]
        s -= (p - q) / vg
        path.append(s)
        if abs(path[-1] - path[-2]) < 1e-13: return s, path

state = 20260927                            # splitmix64, the arithmetic-asian-option card's seed
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

PATHS = 50000                               # one set of draws, reused at every trial volatility
Z = array("d", (sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform()) for _ in range(PATHS * n)))

def kv(s):                                  # geometric twin, exact (Kemna-Vorst on the curve)
    mu = sum(log(fw(t)) - 0.5 * s * s * t for t in ts) / n
    var = s * s * sum(min(a, b) for a in ts for b in ts) / (n * n)
    return black(exp(mu + 0.5 * var), sqrt(var))

def mc(s):                                  # controlled simulation: the geometric twin as control
    d, base = exp(-r * T), [log(fw(t)) - 0.5 * s * s * t for t in ts]
    steps = [s * sqrt(t - u) for t, u in zip(ts, [0.0] + ts[:-1])]
    sx = sxx = sy = syy = sxy = 0.0
    for p in range(PATHS):
        W = tot = totlog = 0.0
        for i in range(n):
            W += steps[i] * Z[p * n + i]
            tot, totlog = tot + exp(base[i] + W), totlog + base[i] + W
        X, Y = d * max(tot / n - K, 0.0), d * max(exp(totlog / n) - K, 0.0)
        sx, sxx, sy, syy, sxy = sx + X, sxx + X * X, sy + Y, syy + Y * Y, sxy + X * Y
    mx, my = sx / PATHS, sy / PATHS
    vy, cxy, vx = syy / PATHS - my * my, sxy / PATHS - mx * my, sxx / PATHS - mx * mx
    beta = cxy / vy
    return mx - beta * (my - kv(s)), sqrt((vx - beta * cxy) / PATHS)
def secant(f, q, a=0.19, b=0.21):           # road 3: root of the simulated price, secant steps
    fa, fb, k = f(a) - q, f(b) - q, 2
    while abs(b - a) > 1e-9:
        a, b, fa = b, b - fb * (b - a) / (fb - fa), fb
        fb, k = f(b) - q, k + 1
    return b, k

def row(label, *vals, dp=6):
    print(f"{label:<44}" + "".join(f"{v:>12.{dp}f}" for v in vals))

TW20, vega20, M1, vA20 = tw(0.20)
floor, ceil = exp(-r * T) * max(M1 - K, 0.0), exp(-r * T) * M1
iv_bis = bisect(lambda s: tw(s)[0], Q)
iv_new, npath = newton(Q)
mc20, se20 = mc(0.20)
iv_mc, evals = secant(lambda s: mc(s)[0], Q)
van_M1 = bisect(lambda v: black(M1, v), Q)           # vanilla formula on the strip's forward (the swap price)
van_dec = bisect(lambda v: black(fw(T), v), Q)       # vanilla formula on the December futures
c_week, below = (n + 1) * (2 * n + 1) / (6.0 * n * n), bisect(lambda s: tw(s)[0], 2.40)  # c: variance kept

for label, *vals in [("quote Q; strip forward M1; Dec futures", Q, M1, fw(T)),
        ("band: floor e^-rT (M1-K)+, ceiling e^-rT M1", floor, ceil),
        ("TW at 20%; vega/pt; gap to Q; one Newton step", TW20, vega20 / 100, TW20 - Q, 0.20 - (TW20 - Q) / vega20), ("TW log-spread vA at 20%", vA20),
        ("controlled simulation at 20%; error bar", mc20, se20),
        ("1 implied vol, bisection on TW", iv_bis), ("2 implied vol, Newton on TW", iv_new),
        ("3 implied vol, secant on simulation", iv_mc), ("  simulated prices used", evals),
        ("vanilla formula on M1 reads", van_M1), ("  TW log-spread at the TW implied vol", tw(iv_bis)[3]),
        ("vanilla formula on Dec futures reads", van_dec),
        ("sanity: read x sqrt(3); x 1/sqrt(c); c", van_M1 * sqrt(3.0), van_M1 / sqrt(c_week), c_week),
        ("wrong: flat curve at $100, TW implied", bisect(lambda s: tw(s, curve(0.0))[0], Q)),
        ("wrong: fixings independent, implied", bisect(lambda s: black(M1, s * sqrt(sum(ts)) / n), Q)),
        ("wrong: quote 2.40, below the floor", below)]:
    row(label, *vals)
print(f"{'Newton from 30%, vol in % after each step':<44}" + "".join(f"{100 * s:>12.6f}" for s in npath[1:5]))

dec = [11.0 / 12 + (i + 1) / 252.0 for i in range(21)]      # December average: 21 daily fixings
TWd, _, M1d, _ = tw(0.20, tx=dec)
van_d, rule_d = bisect(lambda v: black(M1d, v), TWd), 0.20 * sqrt(11.0 / 12 + 1.0 / 36)
row("Dec-only average: TW at 20%; M1; Dec vanilla", TWd, M1d, black(fw(T), 0.20))
row("  vanilla on its M1 reads; x sqrt(3); rule", van_d, van_d * sqrt(3.0), rule_d)
vols = [0, 5, 10, 15, 20, 25, 30, 35, 40]
curves = [[tw(max(v, 1e-4) / 100)[0] for v in vols], [black(fw(T), max(v, 1e-4) / 100) for v in vols]]
print(f"{'chart, vol %':<28}" + "".join(f"{v:>8d}" for v in vols))
for lab, cv in (("chart, Asian TW price", curves[0]), ("chart, vanilla on Dec price", curves[1])):
    print(f"{lab:<28}" + "".join(f"{p:>8.2f}" for p in cv))

assert abs(iv_bis - iv_new) < 1e-10, "bisection and Newton land on one root"
assert abs(tw(iv_bis)[0] - Q) < 1e-9, "the implied vol reprices the quote"
assert abs(vega20 - (tw(0.200001)[0] - tw(0.199999)[0]) / 2e-6) < 1e-5, "exact vega matches the price's slope"
assert abs(iv_mc - 0.20) < 0.002 and abs(mc20 - Q) < 3 * se20, "the simulation reads back 20% from its own price"
assert 0.0 < iv_mc - iv_bis < 0.003, "TW's small overpricing makes its implied vol slightly low"
assert abs(van_M1 - tw(iv_bis)[3]) < 1e-9, "vanilla on M1 reads exactly TW's fitted log-spread"
assert abs(van_M1 * sqrt(3.0) - iv_mc) < 0.01, "total variance over three: within one vol point"
assert abs(c_week - sum(min(a, b) for a in ts for b in ts) / (n * n * T)) < 1e-12, "c counts the weekly overlap"
assert abs(van_d - rule_d) < 0.001, "the window rule reads the December average"
assert all(a < b for a, b in zip(curves[0], curves[0][1:])) and abs(curves[0][0] - floor) < 1e-9, "rising from the floor"
assert isnan(below) and not isnan(bisect(lambda s: tw(s)[0], floor + 0.01)), "no vol below the floor, one just above"
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
quote Q; strip forward M1; Dec futures          5.854000  102.591500  105.127110
band: floor e^-rT (M1-K)+, ceiling e^-rT M1     2.465111   97.588053
TW at 20%; vega/pt; gap to Q; one Newton step    5.873245    0.221911    0.019245    0.199133
TW log-spread vA at 20%                         0.118036
controlled simulation at 20%; error bar         5.854446    0.001010
1 implied vol, bisection on TW                  0.199133
2 implied vol, Newton on TW                     0.199133
3 implied vol, secant on simulation             0.199980
  simulated prices used                         6.000000
vanilla formula on M1 reads                     0.117523
  TW log-spread at the TW implied vol           0.117523
vanilla formula on Dec futures reads            0.070834
sanity: read x sqrt(3); x 1/sqrt(c); c          0.203555    0.200663    0.343010
wrong: flat curve at $100, TW implied           0.262917
wrong: fixings independent, implied             1.187139
wrong: quote 2.40, below the floor                   nan
Newton from 30%, vol in % after each step      19.987221   19.913274   19.913267   19.913267
Dec-only average: TW at 20%; M1; Dec vanilla   10.121086  104.918807   10.450584
  vanilla on its M1 reads; x sqrt(3); rule      0.194576    0.337016    0.194365
chart, vol %                       0       5      10      15      20      25      30      35      40
chart, Asian TW price           2.47    2.77    3.71    4.77    5.87    6.99    8.11    9.25   10.38
chart, vanilla on Dec price     4.88    5.28    6.80    8.59   10.45   12.34   14.23   16.13   18.02
ALL CHECKS PASS
```

### Rust

```rust
// Implied vol from an Asian quote on jet fuel: 52 weekly fixings read the futures curve 100 e^(0.05 t).
// Rust std only.  Nothing imported knows the answer: the bell-curve area, both root finders,
// the random numbers (splitmix64 + Box-Muller) and every simulated path are written out below.
use std::f64::consts::PI;
const K: f64 = 100.0;
const R: f64 = 0.05;
const T: f64 = 1.0;
const NF: usize = 52;
const Q: f64 = 5.854; // the house Asian quote, $ per barrel
const PATHS: usize = 50000; // one set of draws, reused at every trial volatility

fn ncdf(x: f64) -> f64 { // area left of x: Marsaglia's series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t { i += 2.0; b = b * x * x / i; t = s; s += b; }
    0.5 + s * (-0.5 * x * x - 0.91893853320467274178).exp()
}
fn black(f: f64, v: f64, k: f64, tp: f64) -> f64 { // Black-76 on a lognormal with forward f, log-spread v
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    (-R * tp).exp() * (f * ncdf(d1) - k * ncdf(d1 - v))
}
fn fwd(c: f64, t: f64) -> f64 { 100.0 * (c * t).exp() } // futures price for delivery at t
// Turnbull-Wakeman on curve slope c and dates tx: (price, exact vega, M1, fitted log-spread)
fn tw(s: f64, c: f64, tx: &[f64], k: f64) -> (f64, f64, f64, f64) {
    let m = tx.len() as f64;
    let fs: Vec<f64> = tx.iter().map(|&t| fwd(c, t)).collect();
    let m1 = fs.iter().sum::<f64>() / m;
    let (mut m2, mut dm2) = (0.0, 0.0);
    for i in 0..tx.len() {
        for j in 0..tx.len() {
            let mn = tx[i].min(tx[j]);
            let a = fs[i] * fs[j] * (s * s * mn).exp();
            m2 += a; dm2 += a * 2.0 * s * mn;
        }
    }
    m2 /= m * m; dm2 /= m * m;
    let v = (m2 / (m1 * m1)).ln().sqrt();
    let e1 = ((m1 / k).ln() + 0.5 * v * v) / v;
    let tl = tx[tx.len() - 1];
    (black(m1, v, k, tl), (-R * tl).exp() * m1 * (-0.5 * e1 * e1).exp() / (2.0 * PI).sqrt() * dm2 / (2.0 * v * m2), m1, v)
}
fn bisect<F: Fn(f64) -> f64>(f: F, q: f64) -> f64 { // f increasing: keep the half that straddles q
    let (mut lo, mut hi) = (1e-6, 5.0);
    if !(f(lo) < q && q < f(hi)) { return f64::NAN; } // outside the band: no volatility fits
    while hi - lo > 1e-13 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < q { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
struct Rng(u64);
impl Rng { // splitmix64, the arithmetic-asian-option card's seed
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn kv(s: f64, ts: &[f64]) -> f64 { // geometric twin, exact (Kemna-Vorst on the curve)
    let n = ts.len() as f64;
    let mu = ts.iter().map(|&t| fwd(0.05, t).ln() - 0.5 * s * s * t).sum::<f64>() / n;
    let mut var = 0.0;
    for &a in ts { for &b in ts { var += a.min(b); } }
    var = s * s * var / (n * n);
    black((mu + 0.5 * var).exp(), var.sqrt(), K, T)
}
fn mc(s: f64, ts: &[f64], z: &[f64]) -> (f64, f64) { // controlled simulation, geometric twin as control
    let d = (-R * T).exp();
    let base: Vec<f64> = ts.iter().map(|&t| fwd(0.05, t).ln() - 0.5 * s * s * t).collect();
    let steps: Vec<f64> = (0..NF).map(|i| s * (ts[i] - if i == 0 { 0.0 } else { ts[i - 1] }).sqrt()).collect();
    let (mut sx, mut sxx, mut sy, mut syy, mut sxy) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for p in 0..PATHS {
        let (mut w, mut tot, mut totlog) = (0.0, 0.0, 0.0);
        for i in 0..NF {
            w += steps[i] * z[p * NF + i];
            tot += (base[i] + w).exp(); totlog += base[i] + w;
        }
        let x = d * (tot / NF as f64 - K).max(0.0);
        let y = d * ((totlog / NF as f64).exp() - K).max(0.0);
        sx += x; sxx += x * x; sy += y; syy += y * y; sxy += x * y;
    }
    let pn = PATHS as f64;
    let (mx, my) = (sx / pn, sy / pn);
    let (vy, cxy, vx) = (syy / pn - my * my, sxy / pn - mx * my, sxx / pn - mx * mx);
    let beta = cxy / vy;
    (mx - beta * (my - kv(s, ts)), ((vx - beta * cxy) / pn).sqrt())
}
fn row(label: &str, vals: &[f64]) {
    let mut line = format!("{:<44}", label);
    for v in vals { line += &if v.is_nan() { format!("{:>12}", "nan") } else { format!("{:>12.6}", v) }; }
    println!("{}", line);
}
fn main() {
    let ts: Vec<f64> = (0..NF).map(|i| T * (i + 1) as f64 / NF as f64).collect();
    let mut rng = Rng(20260927);
    let z: Vec<f64> = (0..PATHS * NF).map(|_| { let u1 = rng.uniform(); let u2 = rng.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }).collect();
    let twp = |s: f64| tw(s, 0.05, &ts, K).0;
    let (tw20, vega20, m1, va20) = tw(0.20, 0.05, &ts, K);
    let (floor, ceil) = ((-R * T).exp() * (m1 - K).max(0.0), (-R * T).exp() * m1);
    let iv_bis = bisect(twp, Q);
    let mut npath = vec![0.30]; // Newton: step by price error over vega
    loop {
        let s = *npath.last().unwrap();
        let (p, vg, _, _) = tw(s, 0.05, &ts, K);
        npath.push(s - (p - Q) / vg);
        if (npath[npath.len() - 1] - s).abs() < 1e-13 { break; }
    }
    let iv_new = *npath.last().unwrap();
    let (mc20, se20) = mc(0.20, &ts, &z);
    // road 3: secant steps on the simulated price
    let (mut a, mut b) = (0.19, 0.21);
    let (mut fa, mut fb, mut evals) = (mc(a, &ts, &z).0 - Q, mc(b, &ts, &z).0 - Q, 2.0);
    while (b - a).abs() > 1e-9 {
        let nb = b - fb * (b - a) / (fb - fa);
        a = b; fa = fb; b = nb;
        fb = mc(b, &ts, &z).0 - Q; evals += 1.0;
    }
    let iv_mc = b;
    let van_m1 = bisect(|v| black(m1, v, K, T), Q); // vanilla formula on the strip's forward
    let van_dec = bisect(|v| black(fwd(0.05, T), v, K, T), Q); // vanilla formula on December futures
    let c_week = (NF as f64 + 1.0) * (2.0 * NF as f64 + 1.0) / (6.0 * (NF * NF) as f64);
    let below = bisect(twp, 2.40);
    row("quote Q; strip forward M1; Dec futures", &[Q, m1, fwd(0.05, T)]);
    row("band: floor e^-rT (M1-K)+, ceiling e^-rT M1", &[floor, ceil]);
    row("TW at 20%; vega/pt; gap to Q; one Newton step", &[tw20, vega20 / 100.0, tw20 - Q, 0.20 - (tw20 - Q) / vega20]);
    row("TW log-spread vA at 20%", &[va20]);
    row("controlled simulation at 20%; error bar", &[mc20, se20]);
    row("1 implied vol, bisection on TW", &[iv_bis]);
    row("2 implied vol, Newton on TW", &[iv_new]);
    row("3 implied vol, secant on simulation", &[iv_mc]);
    row("  simulated prices used", &[evals]);
    row("vanilla formula on M1 reads", &[van_m1]);
    row("  TW log-spread at the TW implied vol", &[tw(iv_bis, 0.05, &ts, K).3]);
    row("vanilla formula on Dec futures reads", &[van_dec]);
    row("sanity: read x sqrt(3); x 1/sqrt(c); c", &[van_m1 * 3f64.sqrt(), van_m1 / c_week.sqrt(), c_week]);
    row("wrong: flat curve at $100, TW implied", &[bisect(|s| tw(s, 0.0, &ts, K).0, Q)]);
    row("wrong: fixings independent, implied", &[bisect(|s| black(m1, s * ts.iter().sum::<f64>().sqrt() / NF as f64, K, T), Q)]);
    row("wrong: quote 2.40, below the floor", &[below]);
    row("Newton from 30%, vol in % after each step", &npath[1..5].iter().map(|s| 100.0 * s).collect::<Vec<f64>>());
    let dec: Vec<f64> = (0..21).map(|i| 11.0 / 12.0 + (i + 1) as f64 / 252.0).collect(); // 21 daily fixings
    let (twd, _, m1d, _) = tw(0.20, 0.05, &dec, K);
    let (van_d, rule_d) = (bisect(|v| black(m1d, v, K, T), twd), 0.20 * (11.0 / 12.0 + 1.0 / 36.0f64).sqrt());
    row("Dec-only average: TW at 20%; M1; Dec vanilla", &[twd, m1d, black(fwd(0.05, T), 0.20, K, T)]);
    row("  vanilla on its M1 reads; x sqrt(3); rule", &[van_d, van_d * 3f64.sqrt(), rule_d]);
    let vols = [0, 5, 10, 15, 20, 25, 30, 35, 40];
    let asian: Vec<f64> = vols.iter().map(|&v| twp((v as f64).max(1e-4) / 100.0)).collect();
    let van: Vec<f64> = vols.iter().map(|&v| black(fwd(0.05, T), (v as f64).max(1e-4) / 100.0, K, T)).collect();
    println!("{:<28}{}", "chart, vol %", vols.iter().map(|v| format!("{:>8}", v)).collect::<String>());
    println!("{:<28}{}", "chart, Asian TW price", asian.iter().map(|p| format!("{:>8.2}", p)).collect::<String>());
    println!("{:<28}{}", "chart, vanilla on Dec price", van.iter().map(|p| format!("{:>8.2}", p)).collect::<String>());
    assert!((iv_bis - iv_new).abs() < 1e-10, "bisection and Newton land on one root");
    assert!((twp(iv_bis) - Q).abs() < 1e-9, "the implied vol reprices the quote");
    assert!((vega20 - (twp(0.200001) - twp(0.199999)) / 2e-6).abs() < 1e-5, "exact vega matches the price's slope");
    assert!((iv_mc - 0.20).abs() < 0.002 && (mc20 - Q).abs() < 3.0 * se20, "the simulation reads back 20%");
    assert!(iv_mc - iv_bis > 0.0 && iv_mc - iv_bis < 0.003, "TW's small overpricing makes its implied vol low");
    assert!((van_m1 - tw(iv_bis, 0.05, &ts, K).3).abs() < 1e-9, "vanilla on M1 reads TW's fitted log-spread");
    assert!((van_m1 * 3f64.sqrt() - iv_mc).abs() < 0.01, "total variance over three: within one vol point");
    let overlap: f64 = ts.iter().map(|&a| ts.iter().map(|&b| a.min(b)).sum::<f64>()).sum();
    assert!((c_week - overlap / ((NF * NF) as f64 * T)).abs() < 1e-12, "c counts the weekly overlap");
    assert!((van_d - rule_d).abs() < 0.001, "the window rule reads the December average");
    assert!(asian.windows(2).all(|w| w[0] < w[1]) && (asian[0] - floor).abs() < 1e-9, "rising from the floor");
    assert!(below.is_nan() && !bisect(twp, floor + 0.01).is_nan(), "no vol below the floor, one just above");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
quote Q; strip forward M1; Dec futures          5.854000  102.591500  105.127110
band: floor e^-rT (M1-K)+, ceiling e^-rT M1     2.465111   97.588053
TW at 20%; vega/pt; gap to Q; one Newton step    5.873245    0.221911    0.019245    0.199133
TW log-spread vA at 20%                         0.118036
controlled simulation at 20%; error bar         5.854446    0.001010
1 implied vol, bisection on TW                  0.199133
2 implied vol, Newton on TW                     0.199133
3 implied vol, secant on simulation             0.199980
  simulated prices used                         6.000000
vanilla formula on M1 reads                     0.117523
  TW log-spread at the TW implied vol           0.117523
vanilla formula on Dec futures reads            0.070834
sanity: read x sqrt(3); x 1/sqrt(c); c          0.203555    0.200663    0.343010
wrong: flat curve at $100, TW implied           0.262917
wrong: fixings independent, implied             1.187139
wrong: quote 2.40, below the floor                   nan
Newton from 30%, vol in % after each step      19.987221   19.913274   19.913267   19.913267
Dec-only average: TW at 20%; M1; Dec vanilla   10.121086  104.918807   10.450584
  vanilla on its M1 reads; x sqrt(3); rule      0.194576    0.337016    0.194365
chart, vol %                       0       5      10      15      20      25      30      35      40
chart, Asian TW price           2.47    2.77    3.71    4.77    5.87    6.99    8.11    9.25   10.38
chart, vanilla on Dec price     4.88    5.28    6.80    8.59   10.45   12.34   14.23   16.13   18.02
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves the facts the inverse rests on, for any positive futures prices, any fixing dates after today and any positive strike.

- The Turnbull-Wakeman price rises strictly with volatility.
- As volatility falls to zero, the price tends to the floor. As volatility grows without bound, it tends to the ceiling.
- A quote has an implied volatility exactly when it lies strictly between the floor and the ceiling. Such a quote has exactly one.
- Take any volatility above zero. Then the vanilla formula on the swap price returns that Turnbull-Wakeman premium at exactly one volatility, $v_A/\sqrt{T}$.
- Take $n$ evenly spaced fixings. Then the share of variance kept is exactly $c = (n+1)(2n+1)/(6n^2)$.
- As the number of fixings grows, $c$ tends to one third.
- Take 52 weekly fixings. Then $c$ is exactly 1855/5408, about 0.343.

The solvers, the simulation, the window rule and every printed number are left to the Python and Rust checks.

```lean
-- Implied vol from an Asian quote: the Turnbull-Wakeman price of an Asian call on a futures strip rises strictly with volatility from its zero-volatility floor to its infinite-volatility ceiling, so a quote has an implied vol exactly when it lies strictly inside that band and then exactly one, the vanilla Black-76 formula on the swap price reads back the average's own log-spread instead, and the share of variance an evenly spread average keeps is (n+1)(2n+1)/(6n²), which tends to one third.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Filter.AtTopBot.Basic

open Real ProbabilityTheory Finset Filter Topology Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Black-76 fed a forward `F` and a whole-life log-spread `v`:
`e^(-rT) (F N(e₁) - K N(e₂))` with `e₁ = (ln(F/K) + v²/2) / v` and `e₂ = e₁ - v`. -/
noncomputable def black76OnSpread (F K r T v : ℝ) : ℝ :=
  exp (-r * T) * (F * stdNormalCDF ((log (F / K) + v ^ 2 / 2) / v)
    - K * stdNormalCDF ((log (F / K) + v ^ 2 / 2) / v - v))

/-- The plain (vanilla) Black-76 call on a forward `F` with yearly volatility `s` and expiry `T`:
Black-76 fed the log-spread `s √T`. -/
noncomputable def black76Call (F K r s T : ℝ) : ℝ :=
  black76OnSpread F K r T (s * √T)

/-- `M₁`, the mean of the average, the swap price: the plain average of today's futures prices
`F i` at the `n` fixing dates. -/
noncomputable def stripMean (n : ℕ) (F : Fin n → ℝ) : ℝ :=
  (∑ i, F i) / n

/-- `M₂(σ)`, the average's mean square when one random path moves the whole curve with
volatility `σ`: `(1/n²) Σᵢ Σⱼ Fᵢ Fⱼ e^(σ² min(tᵢ, tⱼ))`. -/
noncomputable def stripMeanSquare (n : ℕ) (F t : Fin n → ℝ) (σ : ℝ) : ℝ :=
  (∑ i, ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j))) / (n : ℝ) ^ 2

/-- `v_A(σ) = √(ln(M₂ / M₁²))`, the log-spread a lognormal needs to match both moments. -/
noncomputable def averageLogSpread (n : ℕ) (F t : Fin n → ℝ) (σ : ℝ) : ℝ :=
  √(log (stripMeanSquare n F t σ / stripMean n F ^ 2))

/-- `C_TW(σ)`, the Turnbull-Wakeman (moment-matched) Asian call price: Black-76 fed the
swap price `M₁` and the average's log-spread `v_A(σ)`, discounted from the payment date `T`. -/
noncomputable def turnbullWakemanCall (n : ℕ) (F t : Fin n → ℝ) (K r T σ : ℝ) : ℝ :=
  black76OnSpread (stripMean n F) K r T (averageLogSpread n F t σ)

open MeasureTheory in
lemma stdNormalCDF_eq (x : ℝ) : stdNormalCDF x = ∫ y in Iic x, gaussianPDFReal 0 1 y := by
  unfold stdNormalCDF
  rw [cdf_eq_real, Measure.real, gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun y _ => gaussianPDFReal_nonneg _ _ y)

open MeasureTheory in
lemma stdNormalCDF_hasDerivAt (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hcont : Continuous (gaussianPDFReal 0 1) := by
    unfold gaussianPDFReal; fun_prop
  have hint : ∀ b : ℝ, IntegrableOn (gaussianPDFReal 0 1) (Iic b) :=
    fun b => (integrable_gaussianPDFReal 0 1).integrableOn
  have h : ∀ y, stdNormalCDF y = stdNormalCDF 0 + ∫ z in (0:ℝ)..y, gaussianPDFReal 0 1 z := by
    intro y
    rw [stdNormalCDF_eq, stdNormalCDF_eq, ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint y)]
    ring
  have hd : HasDerivAt (fun y => ∫ z in (0:ℝ)..y, gaussianPDFReal 0 1 z) (gaussianPDFReal 0 1 x) x :=
    intervalIntegral.integral_hasDerivAt_right (hcont.intervalIntegrable _ _)
      (hcont.stronglyMeasurableAtFilter _ _) hcont.continuousAt
  have hfun : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ z in (0:ℝ)..y, gaussianPDFReal 0 1 z :=
    funext h
  rw [hfun]
  exact hd.const_add _

lemma stdNormalCDF_continuous : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (stdNormalCDF_hasDerivAt x).continuousAt

lemma stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (𝓝 1) := tendsto_cdf_atTop _

lemma stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (𝓝 0) := tendsto_cdf_atBot _

lemma pdf_ratio (F K v : ℝ) (hF : 0 < F) (hK : 0 < K) (hv : v ≠ 0) :
    K * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v - v) =
      F * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v) := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  have hexp : -((log (F / K) + v ^ 2 / 2) / v - v) ^ 2 / 2
      = -((log (F / K) + v ^ 2 / 2) / v) ^ 2 / 2 + log (F / K) := by
    field_simp; ring
  rw [hexp, exp_add, exp_log (div_pos hF hK)]
  field_simp

lemma black76OnSpread_hasDerivAt (F K r T v : ℝ) (hF : 0 < F) (hK : 0 < K) (hv : 0 < v) :
    HasDerivAt (black76OnSpread F K r T)
      (exp (-r * T) * F * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v)) v := by
  set a := log (F / K) with ha
  have he1 : HasDerivAt (fun v : ℝ => (a + v ^ 2 / 2) / v)
      (((↑2 * v ^ (2 - 1) * 1 / 2) * v - (a + v ^ 2 / 2) * 1) / v ^ 2) v :=
    ((((hasDerivAt_id v).pow 2).div_const 2).const_add a).div (hasDerivAt_id v) hv.ne'
  set d := ((↑2 * v ^ (2 - 1) * 1 / 2) * v - (a + v ^ 2 / 2) * 1) / v ^ 2
  have he2 : HasDerivAt (fun v : ℝ => (a + v ^ 2 / 2) / v - v) (d - 1) v :=
    he1.sub (hasDerivAt_id v)
  have h1 := (stdNormalCDF_hasDerivAt _).comp v he1
  have h2 := (stdNormalCDF_hasDerivAt _).comp v he2
  have h := ((h1.const_mul F).sub (h2.const_mul K)).const_mul (exp (-r * T))
  have hfun : black76OnSpread F K r T = fun v => exp (-r * T) *
      (F * (stdNormalCDF ∘ fun v : ℝ => (a + v ^ 2 / 2) / v) v
        - K * (stdNormalCDF ∘ fun v : ℝ => (a + v ^ 2 / 2) / v - v) v) := by
    funext w; rfl
  rw [hfun]
  convert h using 1
  have key := pdf_ratio F K v hF hK hv.ne'
  rw [← ha] at key
  linear_combination (exp (-r * T) * (d - 1)) * key


lemma black76OnSpread_strictMonoOn (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) :
    StrictMonoOn (black76OnSpread F K r T) (Ioi 0) := by
  apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
  · intro x hx
    exact (black76OnSpread_hasDerivAt F K r T x hF hK hx).continuousAt.continuousWithinAt
  · intro x hx
    rw [interior_Ioi] at hx
    rw [(black76OnSpread_hasDerivAt F K r T x hF hK hx).deriv]
    have := gaussianPDFReal_pos 0 1 ((log (F / K) + x ^ 2 / 2) / x) one_ne_zero
    positivity

lemma black76OnSpread_continuousOn (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) :
    ContinuousOn (black76OnSpread F K r T) (Ioi 0) := fun x hx =>
  (black76OnSpread_hasDerivAt F K r T x hF hK hx).continuousAt.continuousWithinAt

lemma black76OnSpread_eq (F K r T v : ℝ) (hv : v ≠ 0) :
    black76OnSpread F K r T v = exp (-r * T) * (F * stdNormalCDF (log (F / K) * v⁻¹ + v / 2)
      - K * stdNormalCDF (log (F / K) * v⁻¹ - v / 2)) := by
  unfold black76OnSpread
  have e1 : (log (F / K) + v ^ 2 / 2) / v = log (F / K) * v⁻¹ + v / 2 := by
    field_simp
  rw [e1, show log (F / K) * v⁻¹ + v / 2 - v = log (F / K) * v⁻¹ - v / 2 by ring]

lemma black76OnSpread_atTop (F K r T : ℝ) :
    Tendsto (black76OnSpread F K r T) atTop (𝓝 (exp (-r * T) * F)) := by
  have hinv : Tendsto (fun v : ℝ => log (F / K) * v⁻¹) atTop (𝓝 0) := by
    simpa using tendsto_inv_atTop_zero.const_mul (log (F / K))
  have hhalf : Tendsto (fun v : ℝ => v / 2) atTop atTop :=
    tendsto_id.atTop_div_const (by norm_num)
  have h1 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ + v / 2) atTop atTop := hinv.add_atTop hhalf
  have h2 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ - v / 2) atTop atBot := by
    simpa [sub_eq_add_neg] using hinv.add_atBot (tendsto_neg_atTop_atBot.comp hhalf)
  have hlim := (((stdNormalCDF_atTop.comp h1).const_mul F).sub
    ((stdNormalCDF_atBot.comp h2).const_mul K)).const_mul (exp (-r * T))
  simp only [mul_one, mul_zero, sub_zero] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with v hv
  rw [black76OnSpread_eq F K r T v hv.ne']
  rfl

lemma black76OnSpread_nhdsGT (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) :
    Tendsto (black76OnSpread F K r T) (𝓝[>] 0) (𝓝 (exp (-r * T) * max (F - K) 0)) := by
  have hhalf : Tendsto (fun v : ℝ => v / 2) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun v : ℝ => v / 2) (𝓝 0) (𝓝 (0 / 2)) := tendsto_id.div_const 2
    simpa using this.mono_left nhdsWithin_le_nhds
  have heq : ∀ᶠ v in 𝓝[>] (0:ℝ), exp (-r * T) * (F * stdNormalCDF (log (F / K) * v⁻¹ + v / 2)
      - K * stdNormalCDF (log (F / K) * v⁻¹ - v / 2)) = black76OnSpread F K r T v := by
    filter_upwards [self_mem_nhdsWithin] with v hv
    rw [black76OnSpread_eq F K r T v (ne_of_gt hv)]
  refine Tendsto.congr' heq ?_
  rcases lt_trichotomy (log (F / K)) 0 with ha | ha | ha
  · have hFK : F < K := by
      have := (log_neg_iff (div_pos hF hK)).1 ha
      rwa [div_lt_one hK] at this
    rw [max_eq_right (by linarith)]
    have hinv : Tendsto (fun v : ℝ => log (F / K) * v⁻¹) (𝓝[>] 0) atBot :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg ha
    have h1 := hinv.atBot_add hhalf
    have h2 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ - v / 2) (𝓝[>] 0) atBot := by
      simpa [sub_eq_add_neg] using hinv.atBot_add hhalf.neg
    have := (((stdNormalCDF_atBot.comp h1).const_mul F).sub
      ((stdNormalCDF_atBot.comp h2).const_mul K)).const_mul (exp (-r * T))
    simpa using this
  · have hFK : F = K := by
      have := eq_one_of_pos_of_log_eq_zero (div_pos hF hK) ha
      rwa [div_eq_one_iff_eq hK.ne'] at this
    simp only [ha, zero_mul, zero_add, zero_sub]
    have h1 := (stdNormalCDF_continuous.tendsto 0).comp hhalf
    have h2 := (stdNormalCDF_continuous.tendsto 0).comp (by simpa using hhalf.neg)
    have := ((h1.const_mul F).sub (h2.const_mul K)).const_mul (exp (-r * T))
    convert this using 2 <;> simp [hFK]
  · have hFK : K < F := by
      have := (log_pos_iff (div_pos hF hK).le).1 ha
      rwa [one_lt_div hK] at this
    rw [max_eq_left (by linarith)]
    have hinv : Tendsto (fun v : ℝ => log (F / K) * v⁻¹) (𝓝[>] 0) atTop :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop ha
    have h1 := hinv.atTop_add hhalf
    have h2 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ - v / 2) (𝓝[>] 0) atTop := by
      simpa [sub_eq_add_neg] using hinv.atTop_add hhalf.neg
    have := (((stdNormalCDF_atTop.comp h1).const_mul F).sub
      ((stdNormalCDF_atTop.comp h2).const_mul K)).const_mul (exp (-r * T))
    simpa using this

lemma stripMean_pos (n : ℕ) (hn : 0 < n) (F : Fin n → ℝ) (hF : ∀ i, 0 < F i) :
    0 < stripMean n F := by
  unfold stripMean
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have : (0:ℝ) < ∑ i, F i :=
    Finset.sum_pos (fun i _ => hF i) (Finset.univ_nonempty_iff.2 ⟨⟨0, hn⟩⟩)
  positivity

lemma stripMeanSquare_zero (n : ℕ) (F t : Fin n → ℝ) :
    stripMeanSquare n F t 0 = stripMean n F ^ 2 := by
  unfold stripMeanSquare stripMean
  simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, zero_mul, exp_zero, mul_one]
  rw [div_pow, sq (∑ i, F i), Finset.sum_mul_sum]

lemma stripMeanSquare_pos (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (σ : ℝ) :
    0 < stripMeanSquare n F t σ := by
  unfold stripMeanSquare
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have hne : (Finset.univ : Finset (Fin n)).Nonempty := Finset.univ_nonempty_iff.2 ⟨⟨0, hn⟩⟩
  have : (0:ℝ) < ∑ i, ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j)) :=
    Finset.sum_pos (fun i _ => Finset.sum_pos (fun j _ => by
      have := hF i; have := hF j; positivity) hne) hne
  positivity

lemma stripMeanSquare_strictMonoOn (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i)
    (ht : ∀ i, 0 < t i) : StrictMonoOn (stripMeanSquare n F t) (Ici 0) := by
  intro a ha b hb hab
  unfold stripMeanSquare
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have hne : (Finset.univ : Finset (Fin n)).Nonempty := Finset.univ_nonempty_iff.2 ⟨⟨0, hn⟩⟩
  rw [div_lt_div_iff_of_pos_right (pow_pos hn' 2)]
  apply Finset.sum_lt_sum_of_nonempty hne
  intro i _
  apply Finset.sum_lt_sum_of_nonempty hne
  intro j _
  have hm : 0 < min (t i) (t j) := lt_min (ht i) (ht j)
  have ha' : (0:ℝ) ≤ a := ha
  have hsq : a ^ 2 < b ^ 2 := by nlinarith
  have := mul_pos (hF i) (hF j)
  gcongr

lemma stripMeanSquare_continuous (n : ℕ) (F t : Fin n → ℝ) :
    Continuous (stripMeanSquare n F t) := by
  unfold stripMeanSquare
  fun_prop

lemma stripMeanSquare_ge (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (σ : ℝ) :
    F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * t ⟨0, hn⟩) / (n : ℝ) ^ 2 ≤ stripMeanSquare n F t σ := by
  unfold stripMeanSquare
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  gcongr
  have hnn : ∀ i j, 0 ≤ F i * F j * exp (σ ^ 2 * min (t i) (t j)) := fun i j => by
    have := hF i; have := hF j; positivity
  calc F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * t ⟨0, hn⟩)
      = F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * min (t ⟨0, hn⟩) (t ⟨0, hn⟩)) := by rw [min_self]
    _ ≤ ∑ j, F ⟨0, hn⟩ * F j * exp (σ ^ 2 * min (t ⟨0, hn⟩) (t j)) :=
        Finset.single_le_sum (f := fun j => F ⟨0, hn⟩ * F j * exp (σ ^ 2 * min (t ⟨0, hn⟩) (t j)))
          (fun j _ => hnn _ j) (Finset.mem_univ _)
    _ ≤ ∑ i, ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j)) :=
        Finset.single_le_sum (f := fun i => ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j)))
          (fun i _ => Finset.sum_nonneg fun j _ => hnn i j) (Finset.mem_univ _)

lemma meanRatio_gt_one (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i)
    (ht : ∀ i, 0 < t i) {a b : ℝ} (ha : 0 ≤ a) (hab : a < b) :
    stripMeanSquare n F t a / stripMean n F ^ 2 < stripMeanSquare n F t b / stripMean n F ^ 2 := by
  have hM := stripMean_pos n hn F hF
  rw [div_lt_div_iff_of_pos_right (by positivity)]
  exact stripMeanSquare_strictMonoOn n hn F t hF ht ha (mem_Ici.2 (ha.trans hab.le)) hab

lemma meanRatio_zero (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) :
    stripMeanSquare n F t 0 / stripMean n F ^ 2 = 1 := by
  have hM := stripMean_pos n hn F hF
  rw [stripMeanSquare_zero, div_self (by positivity)]

lemma averageLogSpread_pos (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i)
    (ht : ∀ i, 0 < t i) {σ : ℝ} (hσ : 0 < σ) : 0 < averageLogSpread n F t σ := by
  unfold averageLogSpread
  apply Real.sqrt_pos.2
  apply Real.log_pos
  have := meanRatio_gt_one n hn F t hF ht le_rfl hσ
  rwa [meanRatio_zero n hn F t hF] at this

lemma averageLogSpread_strictMonoOn (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i) :
    StrictMonoOn (averageLogSpread n F t) (Ioi 0) := by
  intro a ha b hb hab
  have ha' : (0:ℝ) < a := ha
  unfold averageLogSpread
  have h1 := meanRatio_gt_one n hn F t hF ht le_rfl ha'
  rw [meanRatio_zero n hn F t hF] at h1
  apply Real.sqrt_lt_sqrt (Real.log_pos h1).le
  exact Real.log_lt_log (by linarith) (meanRatio_gt_one n hn F t hF ht ha'.le hab)

lemma averageLogSpread_continuous (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) : Continuous (averageLogSpread n F t) := by
  have hM := stripMean_pos n hn F hF
  unfold averageLogSpread
  apply Real.continuous_sqrt.comp
  apply Continuous.log ((stripMeanSquare_continuous n F t).div_const _)
  intro σ
  have := stripMeanSquare_pos n hn F t hF σ
  positivity

lemma averageLogSpread_nhdsGT (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i) :
    Tendsto (averageLogSpread n F t) (𝓝[>] 0) (𝓝[>] 0) := by
  have h0 : averageLogSpread n F t 0 = 0 := by
    unfold averageLogSpread
    rw [meanRatio_zero n hn F t hF, Real.log_one, Real.sqrt_zero]
  apply tendsto_nhdsWithin_iff.2
  constructor
  · have := (averageLogSpread_continuous n hn F t hF).tendsto 0
    rw [h0] at this
    exact this.mono_left nhdsWithin_le_nhds
  · filter_upwards [self_mem_nhdsWithin] with σ hσ
    exact averageLogSpread_pos n hn F t hF ht hσ

lemma averageLogSpread_atTop (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i) :
    Tendsto (averageLogSpread n F t) atTop atTop := by
  have hM := stripMean_pos n hn F hF
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have hF0 := hF ⟨0, hn⟩
  have ht0 := ht ⟨0, hn⟩
  set c := F ⟨0, hn⟩ * F ⟨0, hn⟩ / (n : ℝ) ^ 2 / stripMean n F ^ 2 with hc
  have hcpos : 0 < c := by positivity
  have hlow : ∀ σ : ℝ, log c + σ ^ 2 * t ⟨0, hn⟩
      ≤ log (stripMeanSquare n F t σ / stripMean n F ^ 2) := by
    intro σ
    rw [← Real.log_exp (σ ^ 2 * t ⟨0, hn⟩), ← Real.log_mul hcpos.ne' (exp_pos _).ne']
    apply Real.log_le_log (by positivity)
    have := stripMeanSquare_ge n hn F t hF σ
    rw [hc, le_div_iff₀ (by positivity)]
    calc F ⟨0, hn⟩ * F ⟨0, hn⟩ / ↑n ^ 2 / stripMean n F ^ 2 * rexp (σ ^ 2 * t ⟨0, hn⟩)
          * stripMean n F ^ 2
        = F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * t ⟨0, hn⟩) / (n : ℝ) ^ 2 := by
          field_simp
      _ ≤ _ := this
  have hsq : Tendsto (fun σ : ℝ => log c + σ ^ 2 * t ⟨0, hn⟩) atTop atTop :=
    tendsto_atTop_add_const_left _ _
      ((tendsto_pow_atTop two_ne_zero).atTop_mul_const ht0)
  have hlog := tendsto_atTop_mono hlow hsq
  exact tendsto_sqrt_atTop.comp hlog

lemma band_of_strictMonoOn {f : ℝ → ℝ} {L U : ℝ}
    (hmono : StrictMonoOn f (Ioi 0)) (hcont : ContinuousOn f (Ioi 0))
    (h0 : Tendsto f (𝓝[>] 0) (𝓝 L)) (hinf : Tendsto f atTop (𝓝 U)) (Q : ℝ) :
    ((∃ σ : ℝ, 0 < σ ∧ f σ = Q) ↔ (L < Q ∧ Q < U)) ∧
    ((L < Q ∧ Q < U) → ∃! σ : ℝ, 0 < σ ∧ f σ = Q) := by
  have hL : ∀ x, 0 < x → L ≤ f x := by
    intro x hx
    apply le_of_tendsto h0
    filter_upwards [Ioo_mem_nhdsGT hx] with y hy
    exact (hmono hy.1 hx hy.2).le
  have hU : ∀ x, 0 < x → f x ≤ U := by
    intro x hx
    apply ge_of_tendsto hinf
    filter_upwards [eventually_ge_atTop x] with y hy
    exact hmono.monotoneOn hx (lt_of_lt_of_le hx hy) hy
  have hex : L < Q ∧ Q < U → ∃ σ : ℝ, 0 < σ ∧ f σ = Q := by
    rintro ⟨hLQ, hQU⟩
    obtain ⟨a, haQ, ha⟩ :=
      ((h0.eventually (gt_mem_nhds hLQ)).and self_mem_nhdsWithin).exists
    obtain ⟨b, hbQ, hb⟩ :=
      ((hinf.eventually (lt_mem_nhds hQU)).and (eventually_gt_atTop 0)).exists
    have ha' : (0:ℝ) < a := ha
    have hab : a ≤ b := by
      by_contra h
      exact absurd (hmono hb ha' (not_le.1 h)) (by linarith)
    obtain ⟨c, hc, hcQ⟩ := intermediate_value_Icc hab
      (hcont.mono fun x hx => lt_of_lt_of_le ha' hx.1) ⟨haQ.le, hbQ.le⟩
    exact ⟨c, lt_of_lt_of_le ha' hc.1, hcQ⟩
  refine ⟨⟨?_, hex⟩, fun h => ?_⟩
  · rintro ⟨σ, hσ, rfl⟩
    refine ⟨?_, ?_⟩
    · exact lt_of_le_of_lt (hL (σ / 2) (by linarith))
        (hmono (show (0:ℝ) < σ / 2 by linarith) hσ (by linarith))
    · exact lt_of_lt_of_le (hmono hσ (show (0:ℝ) < 2 * σ by linarith) (by linarith))
        (hU (2 * σ) (by linarith))
  · obtain ⟨σ, hσ, hfσ⟩ := hex h
    refine ⟨σ, ⟨hσ, hfσ⟩, fun τ ⟨hτ, hfτ⟩ => ?_⟩
    exact hmono.injOn hτ hσ (hfτ.trans hfσ.symm)

lemma sum_Icc_id_two (n : ℕ) : 2 * ∑ j ∈ Icc 1 n, j = n * (n + 1) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih]
    ring

/-- **One implied vol, exactly when the quote is inside the band.** Take `n ≥ 1` fixings, read
from today's futures prices `F i > 0` at dates `t i > 0` (no fixing banked yet), one volatility
`σ` for every fixing, one random path moving the whole curve, a strike `K > 0`, a bank rate `r`
and a payment date `T`. Then the moment-matched price `C_TW(σ)` rises strictly with volatility
`σ > 0`; it tends to the floor `e^(-rT) (M₁ - K)⁺` as volatility falls to zero and to the
ceiling `e^(-rT) M₁` as volatility grows without bound; a quote `Q` is matched by some
volatility `σ > 0` exactly when `e^(-rT) (M₁ - K)⁺ < Q < e^(-rT) M₁`; and every such quote is
matched by exactly one volatility. -/
theorem asian_quote_in_band_has_one_implied_vol
    (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i)
    (K r T : ℝ) (hK : 0 < K) :
    StrictMonoOn (turnbullWakemanCall n F t K r T) (Ioi 0) ∧
    Tendsto (turnbullWakemanCall n F t K r T) (𝓝[>] 0)
      (𝓝 (exp (-r * T) * max (stripMean n F - K) 0)) ∧
    Tendsto (turnbullWakemanCall n F t K r T) atTop (𝓝 (exp (-r * T) * stripMean n F)) ∧
    ∀ Q : ℝ,
      ((∃ σ : ℝ, 0 < σ ∧ turnbullWakemanCall n F t K r T σ = Q) ↔
        (exp (-r * T) * max (stripMean n F - K) 0 < Q ∧ Q < exp (-r * T) * stripMean n F)) ∧
      ((exp (-r * T) * max (stripMean n F - K) 0 < Q ∧ Q < exp (-r * T) * stripMean n F) →
        ∃! σ : ℝ, 0 < σ ∧ turnbullWakemanCall n F t K r T σ = Q) := by
  have hM := stripMean_pos n hn F hF
  have hfun : turnbullWakemanCall n F t K r T =
      black76OnSpread (stripMean n F) K r T ∘ averageLogSpread n F t := rfl
  have hmaps : MapsTo (averageLogSpread n F t) (Ioi 0) (Ioi 0) :=
    fun σ hσ => averageLogSpread_pos n hn F t hF ht hσ
  have hmono : StrictMonoOn (turnbullWakemanCall n F t K r T) (Ioi 0) := by
    intro a ha b hb hab
    exact black76OnSpread_strictMonoOn _ K r T hM hK (hmaps ha) (hmaps hb)
      (averageLogSpread_strictMonoOn n hn F t hF ht ha hb hab)
  have hcont : ContinuousOn (turnbullWakemanCall n F t K r T) (Ioi 0) := by
    rw [hfun]
    exact (black76OnSpread_continuousOn _ K r T hM hK).comp
      (averageLogSpread_continuous n hn F t hF).continuousOn hmaps
  have h0 : Tendsto (turnbullWakemanCall n F t K r T) (𝓝[>] 0)
      (𝓝 (exp (-r * T) * max (stripMean n F - K) 0)) := by
    rw [hfun]
    exact (black76OnSpread_nhdsGT _ K r T hM hK).comp (averageLogSpread_nhdsGT n hn F t hF ht)
  have hinf : Tendsto (turnbullWakemanCall n F t K r T) atTop
      (𝓝 (exp (-r * T) * stripMean n F)) := by
    rw [hfun]
    exact (black76OnSpread_atTop _ K r T).comp (averageLogSpread_atTop n hn F t hF ht)
  exact ⟨hmono, h0, hinf, band_of_strictMonoOn hmono hcont h0 hinf⟩

/-- **The vanilla formula reads the average's spread, not a fixing's vol** (Step 5). Under the
same conditions, with expiry `T > 0`: at any volatility `σ > 0`, the plain Black-76 call on the
swap price `M₁` reproduces the Turnbull-Wakeman premium `C_TW(σ)` at exactly one volatility
`s > 0`, namely `s = v_A(σ) / √T`: the average's own log-spread, put on a yearly scale. -/
theorem vanilla_on_swap_price_reads_average_spread
    (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i)
    (K r T : ℝ) (hK : 0 < K) (hT : 0 < T) (σ : ℝ) (hσ : 0 < σ) :
    ∀ s : ℝ, 0 < s →
      (black76Call (stripMean n F) K r s T = turnbullWakemanCall n F t K r T σ ↔
        s = averageLogSpread n F t σ / √T) := by
  intro s hs
  have hM := stripMean_pos n hn F hF
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hv := averageLogSpread_pos n hn F t hF ht hσ
  unfold black76Call turnbullWakemanCall
  rw [(black76OnSpread_strictMonoOn _ K r T hM hK).injOn.eq_iff
    (show s * √T ∈ Set.Ioi 0 from mul_pos hs hsT)
    (show averageLogSpread n F t σ ∈ Set.Ioi 0 from hv),
    eq_div_iff hsT.ne']

/-- **Where the three comes from** (Step 6). For evenly spaced fixings `tᵢ = iT/n` the
average of the logs keeps the share `c = (1/(n² T)) Σᵢ Σⱼ min(tᵢ, tⱼ)` of the last price's
log-variance. The count is `Σᵢ Σⱼ min(i, j) = n(n+1)(2n+1)/6` for `i, j = 1, …, n`, so
`c = (n+1)(2n+1)/(6n²)`, and `c` tends to one third as the number of fixings grows. -/
theorem average_keeps_one_third_of_variance (n : ℕ) :
    6 * ∑ i ∈ Icc 1 n, ∑ j ∈ Icc 1 n, min i j = n * (n + 1) * (2 * n + 1) ∧
    Tendsto (fun m : ℕ => ((m : ℝ) + 1) * (2 * m + 1) / (6 * (m : ℝ) ^ 2)) atTop
      (𝓝 (1 / 3)) := by
  constructor
  · induction n with
    | zero => simp
    | succ k ih =>
      have hrow : ∑ j ∈ Icc 1 k, min (k + 1) j = ∑ j ∈ Icc 1 k, j :=
        Finset.sum_congr rfl fun j hj => min_eq_right (by simp at hj; omega)
      have hcol : ∑ i ∈ Icc 1 k, min i (k + 1) = ∑ i ∈ Icc 1 k, i :=
        Finset.sum_congr rfl fun i hi => min_eq_left (by simp at hi; omega)
      have hs := sum_Icc_id_two k
      rw [Finset.sum_Icc_succ_top (by omega)]
      simp only [Finset.sum_Icc_succ_top (show 1 ≤ k + 1 by omega)]
      rw [Finset.sum_add_distrib, hcol, hrow, min_self]
      nlinarith [ih, hs]
  · have hinv : Tendsto (fun m : ℕ => ((m : ℝ))⁻¹) atTop (𝓝 0) :=
      tendsto_inv_atTop_zero.comp tendsto_natCast_atTop_atTop
    have hlim : Tendsto (fun m : ℕ => 1 / 3 + (1 / 2) * ((m : ℝ))⁻¹ + (1 / 6) * ((m : ℝ))⁻¹ ^ 2)
        atTop (𝓝 (1 / 3 + (1 / 2) * 0 + (1 / 6) * 0 ^ 2)) :=
      ((tendsto_const_nhds.add (hinv.const_mul _)).add ((hinv.pow 2).const_mul _))
    simp only [mul_zero, add_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow]
      at hlim
    refine hlim.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with m hm
    have hm' : (m : ℝ) ≠ 0 := Nat.cast_ne_zero.2 hm.ne'
    field_simp
    ring

-- The card's 52 weekly fixings: Σᵢ Σⱼ min(i, j) = 52·53·105/6 = 48230.
example : ∑ i ∈ Icc 1 52, ∑ j ∈ Icc 1 52, min i j = 48230 := by decide
example : 52 * 53 * 105 / 6 = 48230 := by norm_num
-- The share kept by 52 weekly fixings: c = 53·105/(6·52²) = 1855/5408 (about 0.343).
example : ((52 + 1) * (2 * 52 + 1) : ℚ) / (6 * 52 ^ 2) = 1855 / 5408 := by norm_num
example : (48230 : ℚ) / 52 ^ 2 / 52 = 1855 / 5408 := by norm_num

#print axioms asian_quote_in_band_has_one_implied_vol
#print axioms vanilla_on_swap_price_reads_average_spread
#print axioms average_keeps_one_third_of_variance
#print axioms stdNormalCDF_eq
#print axioms stdNormalCDF_hasDerivAt
#print axioms stdNormalCDF_continuous
#print axioms stdNormalCDF_atTop
#print axioms stdNormalCDF_atBot
#print axioms pdf_ratio
#print axioms black76OnSpread_hasDerivAt
#print axioms black76OnSpread_strictMonoOn
#print axioms black76OnSpread_continuousOn
#print axioms black76OnSpread_eq
#print axioms black76OnSpread_atTop
#print axioms black76OnSpread_nhdsGT
#print axioms stripMean_pos
#print axioms stripMeanSquare_zero
#print axioms stripMeanSquare_pos
#print axioms stripMeanSquare_strictMonoOn
#print axioms stripMeanSquare_continuous
#print axioms stripMeanSquare_ge
#print axioms meanRatio_gt_one
#print axioms meanRatio_zero
#print axioms averageLogSpread_pos
#print axioms averageLogSpread_strictMonoOn
#print axioms averageLogSpread_continuous
#print axioms averageLogSpread_nhdsGT
#print axioms averageLogSpread_atTop
#print axioms band_of_strictMonoOn
#print axioms sum_Icc_id_two
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'asian_quote_in_band_has_one_implied_vol' depends on axioms: [propext, Classical.choice, Quot.sound]
'vanilla_on_swap_price_reads_average_spread' depends on axioms: [propext, Classical.choice, Quot.sound]
'average_keeps_one_third_of_variance' depends on axioms: [propext, Classical.choice, Quot.sound]
'stdNormalCDF_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'stdNormalCDF_hasDerivAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'stdNormalCDF_continuous' depends on axioms: [propext, Classical.choice, Quot.sound]
'stdNormalCDF_atTop' depends on axioms: [propext, Classical.choice, Quot.sound]
'stdNormalCDF_atBot' depends on axioms: [propext, Classical.choice, Quot.sound]
'pdf_ratio' depends on axioms: [propext, Classical.choice, Quot.sound]
'black76OnSpread_hasDerivAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'black76OnSpread_strictMonoOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'black76OnSpread_continuousOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'black76OnSpread_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'black76OnSpread_atTop' depends on axioms: [propext, Classical.choice, Quot.sound]
'black76OnSpread_nhdsGT' depends on axioms: [propext, Classical.choice, Quot.sound]
'stripMean_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'stripMeanSquare_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'stripMeanSquare_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'stripMeanSquare_strictMonoOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'stripMeanSquare_continuous' depends on axioms: [propext, Classical.choice, Quot.sound]
'stripMeanSquare_ge' depends on axioms: [propext, Classical.choice, Quot.sound]
'meanRatio_gt_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'meanRatio_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'averageLogSpread_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'averageLogSpread_strictMonoOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'averageLogSpread_continuous' depends on axioms: [propext, Classical.choice, Quot.sound]
'averageLogSpread_nhdsGT' depends on axioms: [propext, Classical.choice, Quot.sound]
'averageLogSpread_atTop' depends on axioms: [propext, Classical.choice, Quot.sound]
'band_of_strictMonoOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_Icc_id_two' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **A quote under the floor.** Guess first: what does a quote of \$2.40 imply? Change `Q` to 2.40. No volatility: the solver refuses, because \$2.40 is below the \$2.47 floor.
> - **Forget the curve.** Guess first: flat futures at \$100, same quote. Pass `curve(0.0)` to `tw` in the first inversion. The answer rises to 26.29 percent.
> - **Squeeze the window.** Guess first: does a December-month average read closer to the vanilla? Price it at 20 percent with `tx=dec`: \$10.12, and the vanilla formula reads it at 19.46 percent.
> - **The rule's constant.** Replace `c_week` by one third. The weekly sanity check moves from 20.07 to 20.36 percent.

---

## The usual mistake

> [!warning]
> **Comparing an Asian's premium-implied vol from the vanilla formula with the vanilla vols on the screen.** Read through the plain call formula, \$5.854 looks like 11.75 or 7.08 percent volatility, and the Asian looks like cheap volatility. It is not cheap. The averaging lowers the premium; the volatility is the same 20 percent. The Asian's vol must come from an Asian formula.
>
> Smaller traps:
> - **Feeding a spot price where the curve belongs.** A flat \$100 in place of the jet fuel curve reads 26.29 percent. The forward of an average of futures is the swap price, \$102.59.
> - **Trusting the formula's vol to the last digit.** Turnbull-Wakeman reads 19.91 percent where the exact model reads 20.00. At higher volatility or longer dates the gap widens.
> - **Solving outside the band.** A quote under \$2.47 has no volatility. A solver that returns 0.0001 percent there is reporting its search limit.
> - **Carrying divide-by-three to every schedule.** It holds for an average running evenly from today. A December-month average keeps almost all the variance.

---

## Where you meet it in real life

- **An airline's hedge desk.** Before paying \$5.854 a barrel, the desk inverts the quote and compares 20 percent with the December option's implied vol ([Implied vol on a futures option and the commodity smile](../26-Options%20on%20commodity%20futures%20and%20spreads/03-commodity-implied-vol-and-the-call-skew.md)). Like for like, the premium is fair or it is not.
- **Talking in volatility.** A desk compares options of different shapes by their volatility, not their premium. For an average-price option that comparison needs this inverse, and a counterparty checking a premium against an agreed volatility runs it too.
- **Model validation.** The gap between the formula's implied vol and the simulation's, 19.91 against 20.00 percent, states an approximation's error in the units traders use.
- **Seasoned trades.** Halfway through the year, the vol is read off the open part of the average with its shifted strike ([Asian Greeks and the average already banked](04-asian-greeks-and-the-running-average.md)).
- **The swap underneath.** The floor and the rule both start from the swap price ([Commodity swap](01-commodity-swap-and-average-price-forward.md)); the geometric twin that steers the simulation is priced exactly on [Kemna-Vorst](02-kemna-vorst-geometric-asian.md).

> **Say it back**
> An Asian quote is turned into a volatility by solving the moment-matched price for $\sigma$. That price rises strictly with volatility, from the discounted swap-price payoff to the discounted swap price, so every quote in between has one answer. For jet fuel, \$5.854 means 20 percent, the same kind of number as a vanilla's vol. The vanilla formula applied to the same premium reads the average's own spread, 11.75 percent. Multiply that by the square root of 3, or by the schedule's own factor, and the fixing's volatility comes back.

---

## What this builds on

- [Asian Greeks and the average already banked](04-asian-greeks-and-the-running-average.md): the Asian's vega, the slope every solver here uses, and the seasoned contract with its shifted strike.
- [Implied vol on a futures option and the commodity smile](../26-Options%20on%20commodity%20futures%20and%20spreads/03-commodity-implied-vol-and-the-call-skew.md): implied vol for a plain option on one futures contract, the number the Asian's vol is compared with.
- [Newton's method](../../06-Calculus%20and%20analysis/03-What%20Derivatives%20Tell%20You/06-newtons-method.md): the tangent-line step that solves the equation in a few steps.
- [Asian Greeks and implied volatility](../17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/03-asian-greeks-and-implied-volatility.md): the equity version, which proves the exact Asian price rises strictly with volatility and inverts it on the Acme market.

## Where this goes next

- [Caplet stripping](../29-Caps%2C%20Floors%20and%20Swaptions/03-caplet-stripping.md): a strip of interest-rate options read back into one volatility per date, the problem an Asian's single blended vol hides.
- [Solving rate options backwards](../29-Caps%2C%20Floors%20and%20Swaptions/09-rate-option-inverses.md): the same existence, uniqueness and solver argument for rate options.

This card reads one flat volatility off one average; when near fuel contracts move more than far ones, which volatility belongs to which fixing is the question stripping answers.

---

## Sources

Verified 2026-11-13: every link below resolves to the publisher's page.

- Turnbull, Stuart M., and Lee Macdonald Wakeman. "A Quick Algorithm for Pricing European Average Options." *Journal of Financial and Quantitative Analysis* 26, no. 3 (1991): 377–389. [doi:10.2307/2331213](https://doi.org/10.2307/2331213). The moment-matched price inverted here.
- Levy, Edmond. "Pricing European Average Rate Currency Options." *Journal of International Money and Finance* 11, no. 5 (1992): 474–491. [doi:10.1016/0261-5606(92)90013-N](https://doi.org/10.1016/0261-5606(92)90013-N). The two-moment lognormal fit in the form used on this card.
- Kemna, A. G. Z., and A. C. F. Vorst. "A Pricing Method for Options Based on Average Asset Values." *Journal of Banking and Finance* 14, no. 1 (1990): 113–129. [doi:10.1016/0378-4266(90)90039-5](https://doi.org/10.1016/0378-4266(90)90039-5). The geometric twin, and the variance of an average that gives the one third.
- Black, Fischer. "The Pricing of Commodity Contracts." *Journal of Financial Economics* 3, no. 1–2 (1976): 167–179. [doi:10.1016/0304-405X(76)90024-6](https://doi.org/10.1016/0304-405X(76)90024-6). The futures-price call formula underneath Turnbull-Wakeman.
- Carr, Peter, Christian-Oliver Ewald, and Yajun Xiao. "On the Qualitative Effect of Volatility and Duration on Prices of Asian Options." *Finance Research Letters* 5, no. 3 (2008): 162–171. [doi:10.1016/j.frl.2008.05.001](https://doi.org/10.1016/j.frl.2008.05.001). The exact Asian price rises with volatility, so its implied vol is unique.
