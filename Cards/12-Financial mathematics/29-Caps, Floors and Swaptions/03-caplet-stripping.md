# Caplet stripping: recovering each caplet's volatility from cap quotes

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Caps, Floors and Swaptions](../README.md#s29) → Caplet stripping

---

## General Overview

A company borrows $1 million at a floating rate that resets every three months. It buys a cap: insurance that pays, at the end of each quarter, the amount by which that quarter's rate exceeded 5 percent. Each quarter's payment is a small option called a **caplet**. A cap is a bundle of caplets, one per reset ([Caplets and floorlets](01-caplets-and-floorlets.md)).

Brokers do not quote caps in dollars. They quote one volatility per cap, called the **flat volatility**: the single number that, fed into every caplet of that cap, reproduces the cap's price. Volatility here means how widely the future rate may spread, per square root of a year. On one screen sit eight such quotes, for caps holding one caplet, two caplets, and so on up to eight. The 2-year cap, which holds seven caplets, is quoted at 30 percent. The 2.25-year cap, which holds eight, at 29.4 percent.

The flat volatility is a bookkeeping number. It belongs to the whole cap, not to any caplet in it. The caplet that fixes in 1 year is shared by every cap from the fourth onward, yet each of those caps prices it at a different flat volatility. A single caplet can only have one volatility. Recovering that one number for each caplet, from the flat quotes, is **caplet stripping**. On this card's quotes, the eight flat volatilities rise from 26 to 30.8 percent and drift back to 29.4. The eight caplet volatilities behind them rise to 32.36 percent at the 1-year reset and fall to 26.37 percent at the last one.

The method is a relay. The difference between two neighbouring caps' prices is exactly one caplet's price. Each difference is then turned back into a volatility, one caplet at a time. The card also proves the answer is the only one the quotes allow, and names the quotes that allow none.

**Eight cap quotes become eight cap prices; neighbouring prices subtract to eight caplet prices; each caplet price has exactly one volatility, so the eight caplet volatilities are unique whenever each price difference lies strictly between that caplet's zero-volatility and infinite-volatility values.**

**What kind of fact this is:** a method, with the uniqueness of its answer a theorem proved on this card in Why it works.

### The picture: flat volatilities and the caplet volatilities under them

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Flat cap volatility and stripped caplet volatility"
    x-axis "Fixing date of the cap's last caplet (years)" [0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.00]
    y-axis "Volatility (%)" 24 --> 34
    line [26.00, 28.00, 29.50, 30.50, 30.80, 30.60, 30.00, 29.40]
    line [26.00, 28.95, 31.21, 32.36, 31.58, 29.93, 27.49, 26.37]
```

Orange: the quoted flat volatility of the cap whose last caplet fixes on that date. Green: the stripped volatility of that one caplet. The two agree at the first point, where the cap is a single caplet. After that the caplet line swings further than the flat line, both up and down. A flat volatility is an average over every caplet in its cap, so it moves slowly. To pull an average up, the newest member must sit well above it.

---

## The formula

Notation first, in words. Caplets are numbered 1 to 8 in date order; the letter *i* names one caplet and the letter *k* names the cap made of caplets 1 to *k*. A capital sigma, $\Sigma_k$, is the flat volatility quoted for cap *k*. A small sigma, $\sigma_i$, is the volatility of caplet *i* alone. A summation sign adds a term for each caplet from 1 to *k*.

The price of caplet *i* at a volatility $\sigma$ is Black's formula for rates ([Caplets and floorlets](01-caplets-and-floorlets.md)):

$$c_i(\sigma) = L\,\tau\,D(T_i+\tau)\,\big[F_i\,N(d_1) - K\,N(d_2)\big], \qquad d_{1,2} = \frac{\ln(F_i/K) \pm \tfrac12\sigma^2 T_i}{\sigma\sqrt{T_i}}$$

A flat quote is converted to a price by using one volatility for every caplet in the cap:

$$C_k = \sum_{i=1}^{k} c_i(\Sigma_k)$$

Stripping asks for caplet volatilities that reproduce every cap price at once:

$$\sum_{i=1}^{k} c_i(\sigma_i) = C_k \quad\text{for } k = 1,\dots,8 \qquad\Longrightarrow\qquad c_k(\sigma_k) = C_k - C_{k-1}$$

**Read it aloud:** price each cap at its own flat volatility; subtract the previous cap's price to isolate the newest caplet's price; find the one volatility that gives that caplet that price.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $L$ | notional: the loan amount the rate is applied to | $1,000,000 | every price scales with it; the volatilities do not move |
| $K$ | strike: the capped rate | 5% | caplets cheapen; stripped volatilities shift because volatility depends on strike |
| $T_i$, $\tau$ | fixing date of caplet *i*, in years; accrual length, the quarter it pays for | 0.25 to 2.00; 0.25 | a later fix gives the rate longer to spread |
| $D(t)$ | discount factor: today's value of $1 paid at time *t* | 0.89109 at 2.25 years | caplet prices rise in proportion |
| $F_i$ | forward rate: today's fair fixed rate for caplet *i*'s quarter | 4.3990% to 6.1721% | caplet worth more |
| $\Sigma_k$ | flat volatility quoted for cap *k* | 29.40% for cap 8 | cap price rises |
| $\sigma_i$, $\sigma$ | caplet volatility: the one number for caplet *i* alone | 26.3744% for caplet 8 | that caplet's price rises |
| $C_k$ | price of cap *k*, from its flat quote | $14,908.96 for cap 8 | caplet *k* worth more, and caplet *k*+1 worth less |
| $c_i$ | price of caplet *i* at a given volatility | $3,427.96 for caplet 8 | — |
| $N(x)$, $\varphi$ | bell-curve area to the left of *x*, a probability; bell-curve height | — | — |
| $d_1$, $d_2$ | the forward's distance from the strike in units of $\sigma\sqrt{T_i}$, one half-unit either side | — | — |
| $\nu_i$ | vega of caplet *i*: its price rise per unit of volatility | used in Step 5 | that caplet weighs more in the flat volatility |

$D(T_i+\tau)$ discounts from the payment date, a quarter after the fixing: the rate is known at $T_i$ but the money moves at $T_i + \tau$.

### When it holds

The inverse first: when a caplet volatility exists, when it is unique, and what happens at the edges.

- **Existence.** Caplet *k*'s price must lie strictly between its **floor**, the value at zero volatility, $L\tau D(T_k+\tau)\max(F_k-K,0)$, and its **ceiling**, the value as volatility grows without limit, $L\tau D(T_k+\tau)F_k$. For caplet 8 that window is $2,611.19 to $13,749.78, and the quotes put it at $3,427.96. A difference below the floor has no volatility; exactly at the floor the answer is zero volatility; at or above the ceiling there is none.
- **Uniqueness.** Each caplet's price rises strictly with its volatility, because vega is positive. A strictly rising curve crosses a level once at most. Cap *k* depends only on caplets 1 to *k*, so the eight equations are solved in order and each has one answer.
- **Enough quotes.** One cap per caplet date. With quotes only at 1 year and 2 years, eight unknowns face two equations, and an interpolation rule (a choice, not a consequence) fills the gap. Different rules give different caplet volatilities.
- **One strike across the strip.** All eight caps here are struck at 5%. Market cap quotes are often at-the-money, each struck at its own swap rate (the fair fixed rate over that cap's life); then neighbouring caps hold caplets at different strikes and the difference is no longer one caplet. The strike dimension needs a smile model, one that lets volatility vary with strike ([SABR for rates](07-sabr-for-rates-and-the-volatility-cube.md)).
- **Lognormal quoting.** Black's formula needs positive forwards and strikes. Where rates sit near or below zero, quotes are in normal or shifted volatility ([Rate volatilities](06-normal-and-shifted-volatilities-for-rates.md)). The stripping logic is unchanged; only $c_i$ is swapped.

**Conventions, as of 28 Sep 2026.** This card takes each accrual as exactly 0.25 years and uses one curve for forwards and discounting. Market caps differ in four ways:

- They count days on the contract's basis.
- They leave out the first period, because its rate is already fixed.
- They project forwards and discount on separate curves.
- In US dollars they now reference SOFR (the Secured Overnight Financing Rate, the US overnight benchmark), compounded over the period rather than fixed at its start.

None of these changes the stripping; each changes the inputs to $c_i$.

---

## Why it works

### Step 0: prices add, volatilities do not

A cap pays the sum of its caplets' payments, so its price is the sum of their prices. That is no-arbitrage bookkeeping (no trade makes a riskless profit), true in any model ([Caps and floors](02-caps-floors-and-parity.md)). Volatilities have no such rule: a caplet's price is a curved function of its volatility, so no average of volatilities is guaranteed to give the right sum of prices. The method therefore works in prices and converts to volatilities only at the last moment.

### Step 1: turn every quote into a price

Each flat quote $\Sigma_k$ is the market's shorthand for the price $C_k = \sum c_i(\Sigma_k)$. The 2-year cap at 30% is worth $11,481.00 on this curve and notional. The 2.25-year cap at 29.40% is worth $14,908.96. These two prices are market facts; the volatilities used to compute them are not facts about any caplet.

### Step 2: neighbouring caps differ by exactly one caplet

Cap 8 holds caplets 1 to 8. Cap 7 holds caplets 1 to 7. Whatever the true caplet volatilities, the first seven caplets are the same contracts in both caps, so their true prices cancel:

$$C_8 - C_7 = c_8(\sigma_8) = 14{,}908.96 - 11{,}481.00 = 3{,}427.96.$$

That subtraction is in dollars, and it is exact. It never asks what volatility the first seven caplets carry.

### Step 3: one price has exactly one volatility

Now solve $c_8(\sigma) = 3{,}427.96$. Three facts about the curve $c_8(\sigma)$ settle it.

- **It starts at the floor.** As $\sigma$ shrinks to zero, the forward stops spreading, and the caplet is worth its discounted intrinsic value, $2,611.19.
- **It climbs toward the ceiling.** As $\sigma$ grows without limit, the price approaches $L\tau D F_8$, $13,749.78: the value of receiving the whole floating payment.
- **It climbs strictly in between.** Its slope is vega, $\nu = L\tau D(T_i+\tau) F_i\sqrt{T_i}\,\varphi(d_1)$, where $\varphi$ is the bell curve's height, which is positive everywhere.

A continuous curve that runs from $2,611.19 to $13,749.78 crosses $3,427.96 at least once (the intermediate value theorem). A strictly rising curve crosses it at most once. So there is exactly one caplet 8 volatility. The chart shows the crossing between 20% and 30%; the root finder places it at 26.3744%.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Caplet 8: price against volatility, and the price the quotes demand"
    x-axis "Caplet 8 volatility (%)" [10, 20, 30, 40, 50, 60]
    y-axis "Caplet 8 price ($)" 2500 --> 5600
    line [2663.66, 3071.94, 3643.68, 4260.97, 4888.78, 5512.53]
    line [3427.96, 3427.96, 3427.96, 3427.96, 3427.96, 3427.96]
    line [2611.19, 2611.19, 2611.19, 2611.19, 2611.19, 2611.19]
```

Orange: caplet 8's Black price as its volatility runs from 10% to 60%. Green: the price the two cap quotes demand, $3,427.96. Dark: the zero-volatility floor, $2,611.19. The orange curve never falls, so it meets the green line once. A quote that puts the green line below the dark one leaves no crossing at all.

### Step 4: the eight equations are a staircase

Cap 1 involves only caplet 1. Cap 2 involves caplets 1 and 2. Cap *k* involves caplets 1 to *k*. Written as a system, each new equation adds one new unknown: a **triangular** system, solvable top to bottom. Step 3 gives each rung one answer, so the whole ladder of eight has one answer.

The staircase also says which quotes move which caplets. Raise cap 7's quote from 30.00% to 30.10% and hold the rest. Caplets 1 to 6 move by +0.0000 points: they never saw cap 7. Caplet 7 rises by +0.5214 points, because $C_7 - C_6$ grew. Caplet 8 falls by −0.5136 points, because $C_8 - C_7$ shrank by the same dollars. One quote, two caplets, opposite signs. That sawtooth is how a rates desk reads the volatility risk of a cap book, bucket by bucket.

<details>
<summary>Detailed proof: the caplet volatilities are unique</summary>

Claim: if, for every *k* from 1 to 8, the difference $C_k - C_{k-1}$ (with $C_0 = 0$) lies strictly between caplet *k*'s floor and ceiling, then exactly one list $\sigma_1, \dots, \sigma_8$ of positive numbers satisfies $\sum_{i \le k} c_i(\sigma_i) = C_k$ for all *k*.

**Each caplet curve.** Write $v = \sigma\sqrt{T_k}$. Black's bracket $F N(d_1) - K N(d_2)$ has derivative with respect to that product equal to $F\varphi(d_1)$, by the identity $F\varphi(d_1) = K\varphi(d_2)$ that follows from $d_1^2 - d_2^2 = 2\ln(F/K)$. That derivative is positive, so each caplet price is continuous and strictly increasing in $\sigma$. As $v \to 0$, $d_1$ and $d_2$ go to $+\infty$ together if $F > K$, to $-\infty$ together if $F < K$, and to 0 together if $F = K$, giving $\max(F-K,0)$ in every case. As $v \to \infty$, $d_1 \to +\infty$ and $d_2 \to -\infty$, giving the forward itself. By the intermediate value theorem each level strictly inside $(\text{floor}, \text{ceiling})$ is hit, and by strict increase it is hit once.

**Induction on *k*.** For $k = 1$ the equation is $c_1(\sigma_1) = C_1$: one unknown, one solution. Suppose $\sigma_1, \dots, \sigma_{k-1}$ are uniquely fixed by the first $k-1$ equations. Subtract equation $k-1$ from equation *k*: every term with $i < k$ cancels, leaving $c_k(\sigma_k) = C_k - C_{k-1}$, which has exactly one solution. Any list satisfying all eight equations must agree with this one at every rung, so it is the same list.

**Existence fails at the edges.** If some difference is at or below caplet *k*'s floor, no positive volatility reproduces it, whatever the other caplets do: buying cap *k*, selling cap *k*−1 and agreeing to receive the strike against the floating rate for that quarter then costs nothing or less up front and never pays out a negative amount. If a difference is at or above the ceiling, the reverse trade (sell cap *k*, buy cap *k*−1, receive the floating payment) does the same.

</details>

### Step 5: what a flat volatility is, roughly

For a small spread of caplet volatilities, the flat volatility is close to a vega-weighted average of them: $\Sigma_k \approx \sum \nu_i\sigma_i / \sum \nu_i$, with each vega taken at $\Sigma_k$. For cap 7 the weighted average of the stripped caplet volatilities is 29.9853%, against a quote of 30.0000%. Long-dated caplets have the largest vegas (more time, larger $\sqrt{T_i}$), so they dominate the average. That is why the caplet line in the first chart overshoots: a flat line that bends only a little needs its newest, heaviest member to bend a lot.

<details>
<summary>Why not strip by subtracting volatilities?</summary>

If flat volatility were a plain average, $8\Sigma_8 - 7\Sigma_7$ would be caplet 8's volatility. It gives 25.2000%, not 26.3744%. The weights are not equal, and prices are not straight lines in volatility. The approximation in Step 5 is for reading a quote, never for stripping one.

</details>

A second road reaches the same eight numbers without differencing. It solves each whole cap directly for its last caplet's volatility, holding the earlier ones fixed. It prices every caplet by adding up its payoff over the bell curve instead of by Black's formula. When quotes are missing or noisy, the exact staircase gives way to fitting a smooth curve of caplet volatilities by least squares ([Calibration](../07-Greeks%20by%20Numbers%20and%20Calibration/06-calibration-as-least-squares.md)).

---

## Worked numbers, by hand

Stripping caplet 8. Curve: discount factor $D(t) = e^{-(0.04 + 0.005t)t}$. Notional $1,000,000, strike 5%, quarterly accrual 0.25.

| Step | Arithmetic | Value |
| --- | --- | --- |
| Caplet 8 fixes, pays | $T_8 = 2.00$, paid at $2.25$ | |
| Discount to payment | $D(2.25)$ | 0.89109 |
| Forward for the quarter | $(D(2.00)/D(2.25) - 1)/0.25$ | 6.1721% |
| Cap 8 price at its flat 29.40% | sum of 8 Black caplets at 29.40% | $14,908.96 |
| Cap 7 price at its flat 30.00% | sum of 7 Black caplets at 30.00% | $11,481.00 |
| Caplet 8 price | $14,908.96 − 11,481.00$ | $3,427.96 |
| Floor (zero volatility) | $1{,}000{,}000 \times 0.25 \times 0.89109 \times (6.1721\% - 5\%)$ | $2,611.19 |
| Ceiling (volatility without limit) | $1{,}000{,}000 \times 0.25 \times 0.89109 \times 6.1721\%$ | $13,749.78 |
| Inside the window? | $2,611.19 < 3,427.96 < 13,749.78$ | yes: one answer |
| Bracket | $c_8(20\%) = 3,071.94$, $c_8(30\%) = 3,643.68$ | root between 20% and 30% |
| Bisection | halve a 0% to 500% bracket 100 times | **26.3744%** |

Caplet 8 carries 26.37% volatility, three points below the 29.40% the 2.25-year cap is quoted at. Any other contract that depends on the rate for the quarter from 2.00 to 2.25 years, such as a single caplet or a cap starting later, is priced with 26.37%, not with 29.40%.

The other seven rows run the same way: the table in the code output lists each caplet's price, floor, ceiling and volatility. The house 2-year cap at 5% and 30% is cap 7, worth $11,481.00 on this curve.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Price caplet 7 on its own at the 2-year cap's flat 30% | $3,151.12 (right: $3,006.16) | The flat volatility belongs to the cap. Caplet 7's own volatility is 27.4919%. |
| Strip by subtracting volatilities, $8 \times 29.4 - 7 \times 30.0$ | 25.2000% (right: 26.3744%) | Volatilities are not prices. They do not add, and caplets carry unequal weights. |
| Quote cap 8 at 20% with cap 7 left at 30% | caplet 8 must be worth $148.99, below its floor of $2,611.19 | No volatility, even zero, gives that price. The two quotes contradict each other. |
| Quote cap 8 below 27.1140% | no caplet 8 volatility exists | 27.1140% is the lowest cap 8 quote that the cap 7 quote allows; there caplet 8's volatility is exactly zero. |

The last two rows are the boundary case in numbers. A term structure of flat volatilities (the quotes lined up by cap length) may fall, but not too fast: a falling flat line forces the newest caplet's volatility down harder still, and there is a floor under it.

---

## Code, from first principles, and it actually runs

The code strips all eight caplets by two independent roads. Road 1 converts each quote to a cap price with Black's formula, differences neighbouring caps, and inverts each caplet by bisection. Road 2 never uses Black's formula or differences: it prices each caplet by integrating its payoff over the bell curve with Simpson's rule, and solves each whole cap for its last caplet's volatility by the secant method. Both write their own bell-curve area and root finders. The checks then test:

- the staircase: a bumped quote moves only its own caplet and the next;
- the monotone price curve;
- the empty-window boundary;
- a rebuild of cap 8 from the road 1 volatilities through the road 2 pricer;
- the vega-weighted reading of a flat volatility.

### Python

```python
# Caplet stripping -- the check behind the card.  Standard library only.
# Eight flat cap volatilities in, eight caplet volatilities out, by two roads:
# road 1 differences cap prices and inverts Black's formula by bisection;
# road 2 prices every caplet by integrating the payoff over the bell curve and
# solves each whole cap by the secant method.  Nothing imported knows the answer.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)           # bell-curve height
def simpson(f, a, b, n):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def N(x):                                                         # bell-curve area left of x
    x = max(-10.0, min(10.0, x)); return 0.5 + simpson(phi, 0.0, x, 2000)

L, TAU, K = 1_000_000.0, 0.25, 0.05                               # notional, accrual, strike
def D(t): return exp(-(0.04 + 0.005 * t) * t)                     # discount curve
T = [0.25 * (i + 1) for i in range(8)]                            # fixing dates
F = [(D(t) / D(t + TAU) - 1.0) / TAU for t in T]                  # simple forward rates
FLAT = [0.26, 0.28, 0.295, 0.305, 0.308, 0.306, 0.300, 0.294]     # quoted flat cap vols

def black(i, s, k=K):                                             # Black caplet price
    v = s * sqrt(T[i]); d1 = (log(F[i] / k) + 0.5 * v * v) / v
    return L * TAU * D(T[i] + TAU) * (F[i] * N(d1) - k * N(d1 - v))
def by_integral(i, s):                                            # road 2 caplet price
    v = s * sqrt(T[i]); zk = (log(K / F[i]) + 0.5 * v * v) / v    # below zk it pays nothing
    pay = lambda z: (F[i] * exp(-0.5 * v * v + v * z) - K) * phi(z)
    return L * TAU * D(T[i] + TAU) * simpson(pay, max(zk, -10.0), 10.0, 2000)
def floor_(i): return L * TAU * D(T[i] + TAU) * max(F[i] - K, 0.0)  # value at zero vol
def ceil_(i): return L * TAU * D(T[i] + TAU) * F[i]                 # value as vol -> infinity
def bisect(f, lo, hi):
    for _ in range(100):
        m = 0.5 * (lo + hi)
        if f(m) > 0: hi = m
        else: lo = m
    return 0.5 * (lo + hi)

def strip(flat):                                                  # road 1: bootstrap
    caps = [sum(black(i, flat[k]) for i in range(k + 1)) for k in range(8)]
    sig, parts = [], []
    for k in range(8):
        p = caps[k] - (caps[k - 1] if k else 0.0); parts.append(p)
        sig.append(bisect(lambda s: black(k, s) - p, 1e-6, 5.0) if p > floor_(k) else float("nan"))
    return caps, parts, sig

caps, parts, s1 = strip(FLAT)
s2 = []                                                           # road 2: whole cap, secant
for k in range(8):
    target = sum(by_integral(i, FLAT[k]) for i in range(k + 1))
    known = sum(by_integral(i, s2[i]) for i in range(k))
    g = lambda s: known + by_integral(k, s) - target
    a, b = 0.20, 0.40; ga, gb = g(a), g(b)
    while abs(b - a) > 1e-13:
        a, b, ga = b, b - gb * (b - a) / (gb - ga), gb; gb = g(b)
    s2.append(b)

print(" k  fix  pay  D(pay)     F %   flat %   cap price $  caplet $   floor $   ceiling $  road1 %  road2 %")
for k in range(8):
    print(f"{k+1:>2} {T[k]:4.2f} {T[k]+TAU:4.2f} {D(T[k]+TAU):.5f} {100*F[k]:.4f} {100*FLAT[k]:6.2f} "
          f"{caps[k]:12.2f} {parts[k]:9.2f} {floor_(k):9.2f} {ceil_(k):11.2f} {100*s1[k]:8.4f} {100*s2[k]:8.4f}")

scan = [black(7, 0.10 * j) for j in range(1, 7)]                 # uniqueness: price rises with vol
print("caplet 8 price at vol 10..60%: " + " ".join(f"{p:.2f}" for p in scan))
bumped = strip(FLAT[:6] + [0.301] + FLAT[7:])[2]                  # cap 7 quote up 0.1 vol point
print("cap 7 quote +0.10 pt, caplet vol change in pts: " + " ".join(f"{100*(b-a):+.4f}" for a, b in zip(s1, bumped)))
vg = [L * TAU * D(T[i] + TAU) * F[i] * sqrt(T[i]) * phi((log(F[i] / K) + 0.5 * FLAT[6] ** 2 * T[i]) / (FLAT[6] * sqrt(T[i]))) for i in range(7)]
approx = sum(v * s for v, s in zip(vg, s1)) / sum(vg)
print(f"cap 7: vega-weighted caplet vol {100*approx:.4f} % against flat {100*FLAT[6]:.4f} %")

lowest = bisect(lambda s: sum(black(i, s) for i in range(8)) - caps[6] - floor_(7), 0.01, FLAT[7])
low20 = sum(black(i, 0.20) for i in range(8)) - caps[6]
print(f"lowest cap 8 flat vol with a solution {100*lowest:.4f} %")
print(f"cap 8 quoted at 20%: caplet 8 must be worth {low20:.2f}, below its floor {floor_(7):.2f}")
rebuilt = sum(by_integral(i, s1[i]) for i in range(8))           # cap 8 rebuilt, road 2 pricer
print(f"cap 8 rebuilt from the eight caplet vols by integral {rebuilt:.2f}")
print(f"wrong: flat 30% on caplet 7 alone {black(6, 0.30):.2f}, right {parts[6]:.2f}")
print(f"wrong: vols subtracted, 8 x 29.4 - 7 x 30.0 = {100*(8*FLAT[7]-7*FLAT[6]):.4f} %")
print(f"try: all flat 30%, caplet vols {' '.join(f'{100*s:.2f}' for s in strip([0.30]*8)[2])}")
print(f"try: cap 8 at 31%, caplet 8 vol {100*strip(FLAT[:7] + [0.31])[2][7]:.4f} %")
print("chart, flat vol %   " + " ".join(f"{100*s:.2f}" for s in FLAT))
print("chart, caplet vol % " + " ".join(f"{100*s:.2f}" for s in s1))

assert max(abs(a - b) for a, b in zip(s1, s2)) < 1e-7, "two roads give the same eight vols"
assert abs(s1[0] - FLAT[0]) < 1e-9, "a one-caplet cap: its flat vol is its caplet vol"
assert max(abs(b - a) for a, b in zip(s1[:6], bumped[:6])) < 1e-12, "earlier caplets untouched"
assert bumped[6] - s1[6] > 1e-3, "the bumped cap's own caplet moves"
assert all(x < y for x, y in zip(scan, scan[1:])), "caplet price rises with vol: one root at most"
assert low20 < floor_(7), "a 20% quote leaves caplet 8 below its zero-vol floor"
assert abs(rebuilt - caps[7]) < 1e-6, "road 2 pricer rebuilds the quoted cap from road 1 vols"
assert abs(approx - FLAT[6]) < 0.005, "flat vol is close to the vega-weighted caplet vols"
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
 k  fix  pay  D(pay)     F %   flat %   cap price $  caplet $   floor $   ceiling $  road1 %  road2 %
 1 0.25 0.50 0.97897 4.3990  26.00       127.73    127.73      0.00    10766.30  26.0000  26.0000
 2 0.50 0.75 0.96772 4.6518  28.00       716.67    588.94      0.00    11254.20  28.9483  28.9483
 3 0.75 1.00 0.95600 4.9048  29.50      1878.55   1161.89      0.00    11722.51  31.2102  31.2102
 4 1.00 1.25 0.94383 5.1580  30.50      3612.17   1733.62    372.75    12170.58  32.3555  32.3555
 5 1.25 1.50 0.93123 5.4113  30.80      5830.96   2218.79    957.48    12597.84  31.5782  31.5782
 6 1.50 1.75 0.91823 5.6647  30.60      8474.84   2643.87   1525.95    13003.76  29.9278  29.9278
 7 1.75 2.00 0.90484 5.9184  30.00     11481.00   3006.16   2077.41    13387.88  27.4919  27.4919
 8 2.00 2.25 0.89109 6.1721  29.40     14908.96   3427.96   2611.19    13749.78  26.3744  26.3744
caplet 8 price at vol 10..60%: 2663.66 3071.94 3643.68 4260.97 4888.78 5512.53
cap 7 quote +0.10 pt, caplet vol change in pts: +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.5214 -0.5136
cap 7: vega-weighted caplet vol 29.9853 % against flat 30.0000 %
lowest cap 8 flat vol with a solution 27.1140 %
cap 8 quoted at 20%: caplet 8 must be worth 148.99, below its floor 2611.19
cap 8 rebuilt from the eight caplet vols by integral 14908.96
wrong: flat 30% on caplet 7 alone 3151.12, right 3006.16
wrong: vols subtracted, 8 x 29.4 - 7 x 30.0 = 25.2000 %
try: all flat 30%, caplet vols 30.00 30.00 30.00 30.00 30.00 30.00 30.00 30.00
try: cap 8 at 31%, caplet 8 vol 35.8823 %
chart, flat vol %   26.00 28.00 29.50 30.50 30.80 30.60 30.00 29.40
chart, caplet vol % 26.00 28.95 31.21 32.36 31.58 29.93 27.49 26.37
ALL CHECKS PASS
```

The two volatility columns agree to four decimals, and the asserts hold them within one ten-millionth. Caplets 1 to 3 have floors of $0.00: their forwards, 4.3990% to 4.9048%, sit below the 5% strike, so at zero volatility they would pay nothing.

### Rust

The same checks, the same inputs, std only. The bell-curve area is Simpson's rule in both languages.

```rust
// Caplet stripping -- the same check as caplet_stripping_check.py, in Rust, std only.
// Road 1 differences cap prices and inverts Black's formula by bisection; road 2
// prices each caplet by integrating its payoff over the bell curve and solves each
// whole cap by the secant method.  Rust has no erf: N(x) is Simpson's rule.
use std::f64::consts::PI;

const L: f64 = 1_000_000.0; // notional
const TAU: f64 = 0.25; // accrual, years
const K: f64 = 0.05; // strike
const FLAT: [f64; 8] = [0.26, 0.28, 0.295, 0.305, 0.308, 0.306, 0.300, 0.294];

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x.max(-10.0).min(10.0), 2000) }
fn d(t: f64) -> f64 { (-(0.04 + 0.005 * t) * t).exp() } // discount curve
fn tfix(i: usize) -> f64 { 0.25 * (i + 1) as f64 } // fixing dates
fn fwd(i: usize) -> f64 { let t = tfix(i); (d(t) / d(t + TAU) - 1.0) / TAU }

fn black(i: usize, s: f64) -> f64 {
    let (t, f) = (tfix(i), fwd(i));
    let v = s * t.sqrt();
    let d1 = ((f / K).ln() + 0.5 * v * v) / v;
    L * TAU * d(t + TAU) * (f * n_cdf(d1) - K * n_cdf(d1 - v))
}
fn by_integral(i: usize, s: f64) -> f64 {
    let (t, f) = (tfix(i), fwd(i));
    let v = s * t.sqrt();
    let zk = ((K / f).ln() + 0.5 * v * v) / v; // below zk the caplet pays nothing
    let pay = |z: f64| (f * (-0.5 * v * v + v * z).exp() - K) * phi(z);
    L * TAU * d(t + TAU) * simpson(pay, zk.max(-10.0), 10.0, 2000)
}
fn floor_(i: usize) -> f64 { L * TAU * d(tfix(i) + TAU) * (fwd(i) - K).max(0.0) }
fn ceil_(i: usize) -> f64 { L * TAU * d(tfix(i) + TAU) * fwd(i) }
fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let m = 0.5 * (lo + hi);
        if f(m) > 0.0 { hi = m } else { lo = m }
    }
    0.5 * (lo + hi)
}
fn strip(flat: &[f64; 8]) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let caps: Vec<f64> = (0..8).map(|k| (0..=k).map(|i| black(i, flat[k])).sum()).collect();
    let (mut sig, mut parts) = (Vec::new(), Vec::new());
    for k in 0..8 {
        let p = caps[k] - if k > 0 { caps[k - 1] } else { 0.0 };
        parts.push(p);
        sig.push(if p > floor_(k) { bisect(|s| black(k, s) - p, 1e-6, 5.0) } else { f64::NAN });
    }
    (caps, parts, sig)
}
fn join(v: &[f64], f: impl Fn(f64) -> String) -> String { v.iter().map(|x| f(*x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (caps, parts, s1) = strip(&FLAT);
    let mut s2: Vec<f64> = Vec::new(); // road 2: whole cap, secant
    for k in 0..8 {
        let target: f64 = (0..=k).map(|i| by_integral(i, FLAT[k])).sum();
        let known: f64 = (0..k).map(|i| by_integral(i, s2[i])).sum();
        let g = |s: f64| known + by_integral(k, s) - target;
        let (mut a, mut b) = (0.20, 0.40);
        let (mut ga, mut gb) = (g(a), g(b));
        while (b - a).abs() > 1e-13 {
            let nb = b - gb * (b - a) / (gb - ga);
            a = b; ga = gb; b = nb; gb = g(b);
        }
        s2.push(b);
    }
    println!(" k  fix  pay  D(pay)     F %   flat %   cap price $  caplet $   floor $   ceiling $  road1 %  road2 %");
    for k in 0..8 {
        println!("{:>2} {:4.2} {:4.2} {:.5} {:.4} {:6.2} {:12.2} {:9.2} {:9.2} {:11.2} {:8.4} {:8.4}",
            k + 1, tfix(k), tfix(k) + TAU, d(tfix(k) + TAU), 100.0 * fwd(k), 100.0 * FLAT[k],
            caps[k], parts[k], floor_(k), ceil_(k), 100.0 * s1[k], 100.0 * s2[k]);
    }
    let scan: Vec<f64> = (1..7).map(|j| black(7, 0.10 * j as f64)).collect();
    println!("caplet 8 price at vol 10..60%: {}", join(&scan, |p| format!("{:.2}", p)));
    let mut fb = FLAT; fb[6] = 0.301; // cap 7 quote up 0.1 vol point
    let bumped = strip(&fb).2;
    let dv: Vec<f64> = (0..8).map(|i| 100.0 * (bumped[i] - s1[i])).collect();
    println!("cap 7 quote +0.10 pt, caplet vol change in pts: {}", join(&dv, |x| format!("{:+.4}", x)));
    let vg: Vec<f64> = (0..7).map(|i| {
        let (t, f) = (tfix(i), fwd(i));
        L * TAU * d(t + TAU) * f * t.sqrt() * phi(((f / K).ln() + 0.5 * FLAT[6].powi(2) * t) / (FLAT[6] * t.sqrt()))
    }).collect();
    let approx = (0..7).map(|i| vg[i] * s1[i]).sum::<f64>() / vg.iter().sum::<f64>();
    println!("cap 7: vega-weighted caplet vol {:.4} % against flat {:.4} %", 100.0 * approx, 100.0 * FLAT[6]);

    let cap8 = |s: f64| (0..8).map(|i| black(i, s)).sum::<f64>();
    let lowest = bisect(|s| cap8(s) - caps[6] - floor_(7), 0.01, FLAT[7]);
    let low20 = cap8(0.20) - caps[6];
    println!("lowest cap 8 flat vol with a solution {:.4} %", 100.0 * lowest);
    println!("cap 8 quoted at 20%: caplet 8 must be worth {:.2}, below its floor {:.2}", low20, floor_(7));
    let rebuilt: f64 = (0..8).map(|i| by_integral(i, s1[i])).sum(); // cap 8 rebuilt, road 2 pricer
    println!("cap 8 rebuilt from the eight caplet vols by integral {:.2}", rebuilt);
    println!("wrong: flat 30% on caplet 7 alone {:.2}, right {:.2}", black(6, 0.30), parts[6]);
    println!("wrong: vols subtracted, 8 x 29.4 - 7 x 30.0 = {:.4} %", 100.0 * (8.0 * FLAT[7] - 7.0 * FLAT[6]));
    println!("try: all flat 30%, caplet vols {}", join(&strip(&[0.30; 8]).2, |s| format!("{:.2}", 100.0 * s)));
    let mut f31 = FLAT; f31[7] = 0.31;
    println!("try: cap 8 at 31%, caplet 8 vol {:.4} %", 100.0 * strip(&f31).2[7]);
    println!("chart, flat vol %   {}", join(&FLAT, |s| format!("{:.2}", 100.0 * s)));
    println!("chart, caplet vol % {}", join(&s1, |s| format!("{:.2}", 100.0 * s)));

    assert!((0..8).all(|i| (s1[i] - s2[i]).abs() < 1e-7), "two roads give the same eight vols");
    assert!((s1[0] - FLAT[0]).abs() < 1e-9, "a one-caplet cap: its flat vol is its caplet vol");
    assert!((0..6).all(|i| (bumped[i] - s1[i]).abs() < 1e-12), "earlier caplets untouched");
    assert!(bumped[6] - s1[6] > 1e-3, "the bumped cap's own caplet moves");
    assert!(scan.windows(2).all(|w| w[0] < w[1]), "caplet price rises with vol: one root at most");
    assert!(low20 < floor_(7), "a 20% quote leaves caplet 8 below its zero-vol floor");
    assert!((rebuilt - caps[7]).abs() < 1e-6, "road 2 pricer rebuilds the quoted cap from road 1 vols");
    assert!((approx - FLAT[6]).abs() < 0.005, "flat vol is close to the vega-weighted caplet vols");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
 k  fix  pay  D(pay)     F %   flat %   cap price $  caplet $   floor $   ceiling $  road1 %  road2 %
 1 0.25 0.50 0.97897 4.3990  26.00       127.73    127.73      0.00    10766.30  26.0000  26.0000
 2 0.50 0.75 0.96772 4.6518  28.00       716.67    588.94      0.00    11254.20  28.9483  28.9483
 3 0.75 1.00 0.95600 4.9048  29.50      1878.55   1161.89      0.00    11722.51  31.2102  31.2102
 4 1.00 1.25 0.94383 5.1580  30.50      3612.17   1733.62    372.75    12170.58  32.3555  32.3555
 5 1.25 1.50 0.93123 5.4113  30.80      5830.96   2218.79    957.48    12597.84  31.5782  31.5782
 6 1.50 1.75 0.91823 5.6647  30.60      8474.84   2643.87   1525.95    13003.76  29.9278  29.9278
 7 1.75 2.00 0.90484 5.9184  30.00     11481.00   3006.16   2077.41    13387.88  27.4919  27.4919
 8 2.00 2.25 0.89109 6.1721  29.40     14908.96   3427.96   2611.19    13749.78  26.3744  26.3744
caplet 8 price at vol 10..60%: 2663.66 3071.94 3643.68 4260.97 4888.78 5512.53
cap 7 quote +0.10 pt, caplet vol change in pts: +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.5214 -0.5136
cap 7: vega-weighted caplet vol 29.9853 % against flat 30.0000 %
lowest cap 8 flat vol with a solution 27.1140 %
cap 8 quoted at 20%: caplet 8 must be worth 148.99, below its floor 2611.19
cap 8 rebuilt from the eight caplet vols by integral 14908.96
wrong: flat 30% on caplet 7 alone 3151.12, right 3006.16
wrong: vols subtracted, 8 x 29.4 - 7 x 30.0 = 25.2000 %
try: all flat 30%, caplet vols 30.00 30.00 30.00 30.00 30.00 30.00 30.00 30.00
try: cap 8 at 31%, caplet 8 vol 35.8823 %
chart, flat vol %   26.00 28.00 29.50 30.50 30.80 30.60 30.00 29.40
chart, caplet vol % 26.00 28.95 31.21 32.36 31.58 29.93 27.49 26.37
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves the card's existence and uniqueness claims for any number of caplets at one strike, with every input positive.

- Take one caplet. Then at every positive volatility its price lies strictly between its floor and its ceiling.
- Take the same caplet. Then its price rises strictly with volatility. It tends to the floor as volatility shrinks to zero, and to the ceiling as volatility grows without limit.
- Take a price strictly between one caplet's floor and ceiling. Then exactly one positive volatility gives that caplet that price.
- Suppose every neighbouring cap price difference, $C_k - C_{k-1}$, lies strictly between caplet *k*'s floor and ceiling. Then exactly one list of positive caplet volatilities reproduces every cap price.
- Suppose one neighbouring price difference sits at or below its caplet's floor, or at or above its ceiling. Then no list of positive caplet volatilities reproduces every cap price.
- Take cap 8 at $14,908.96 and cap 7 at $11,481.00. Then caplet 8 is worth $3,427.96, inside its window of $2,611.19 to $13,749.78.
- Take the wrong road, subtracting volatilities. Then $8 \times 29.4 - 7 \times 30.0 = 25.2$.

The cap prices themselves, the eight stripped volatilities and the bumped-quote sawtooth are left to the Python and Rust checks.

```lean
-- Caplet stripping: when each neighbouring cap price difference lies strictly between that caplet's zero-volatility floor and infinite-volatility ceiling, exactly one list of positive caplet volatilities reproduces every cap price under Black's formula, and when some difference lies outside that window no list does.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory Set Filter Topology

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Black's formula for one caplet (The formula): notional `L`, accrual `τ`, discount factor `D`
to the payment date, forward `F`, strike `K`, fixing date `T`, volatility `σ`:
`c(σ) = L τ D [F N(d₁) - K N(d₂)]`, `d₁ = (ln(F/K) + σ²T/2)/(σ√T)`, `d₂ = d₁ - σ√T`. -/
noncomputable def capletPrice (L τ D F K T σ : ℝ) : ℝ :=
  let d1 := (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)
  L * τ * D * (F * stdNormalCDF d1 - K * stdNormalCDF (d1 - σ * √T))

/-- The caplet's floor, its value at zero volatility: `L τ D max(F - K, 0)`. -/
noncomputable def capletFloor (L τ D F K : ℝ) : ℝ := L * τ * D * max (F - K) 0

/-- The caplet's ceiling, its value as volatility grows without limit: `L τ D F`. -/
noncomputable def capletCeiling (L τ D F : ℝ) : ℝ := L * τ * D * F

/-- The price of cap `k` (caplets `0, …, k-1`, numbered from 0 here) from its flat quote `s`:
every caplet in the cap is priced at the same volatility, `C_k = ∑_{i<k} c_i(s)`.
Caplet `i` fixes at `T i`, has forward `F i`, and is discounted from its payment date by `D i`. -/
noncomputable def capPrice (L τ K : ℝ) (T F D : ℕ → ℝ) (k : ℕ) (s : ℝ) : ℝ :=
  ∑ i ∈ Finset.range k, capletPrice L τ (D i) (F i) K (T i) s

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg 0 1 t)

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma hasDerivAt_stdNormalCDF (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hint : ∀ y, IntegrableOn (gaussianPDFReal 0 1) (Iic y) :=
    fun y => (integrable_gaussianPDFReal 0 1).integrableOn
  have h : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
      ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint y)]
    ring
  rw [h]
  exact ((continuous_stdPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma stdNormalCDF_strictMono : StrictMono stdNormalCDF :=
  strictMono_of_hasDerivAt_pos hasDerivAt_stdNormalCDF
    (fun x => gaussianPDFReal_pos 0 1 x one_ne_zero)

lemma continuous_stdNormalCDF : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_stdNormalCDF x).continuousAt

lemma tendsto_stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (𝓝 1) := tendsto_cdf_atTop _
lemma tendsto_stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (𝓝 0) := tendsto_cdf_atBot _

/-- `K φ(d - s) = F φ(d)` when `d s - s²/2 = log (F/K)`. -/
lemma pdf_identity (F K s : ℝ) (hF : 0 < F) (hK : 0 < K) (hs : s ≠ 0) :
    F * gaussianPDFReal 0 1 (log (F / K) * s⁻¹ + s / 2) =
      K * gaussianPDFReal 0 1 (log (F / K) * s⁻¹ + s / 2 - s) := by
  simp only [gaussianPDFReal_def, NNReal.coe_one, mul_one, sub_zero]
  have key : -(log (F / K) * s⁻¹ + s / 2 - s) ^ 2 / 2 =
      -(log (F / K) * s⁻¹ + s / 2) ^ 2 / 2 + log (F / K) := by
    field_simp
    ring
  rw [key, exp_add, exp_log (div_pos hF hK)]
  field_simp

lemma core_hasDerivAt (F K a σ : ℝ) (hF : 0 < F) (hK : 0 < K) (ha : 0 < a) (hσ : σ ≠ 0) :
    HasDerivAt (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a))
      (K * gaussianPDFReal 0 1 (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) * a) σ := by
  have hs : σ * a ≠ 0 := mul_ne_zero hσ ha.ne'
  have hlin : HasDerivAt (fun σ => σ * a) a σ := by simpa using (hasDerivAt_id σ).mul_const a
  obtain ⟨d, he⟩ : ∃ d, HasDerivAt (fun σ => log (F / K) * (σ * a)⁻¹ + σ * a / 2) d σ :=
    ⟨_, ((hlin.inv hs).const_mul _).add (hlin.div_const 2)⟩
  have h1 : HasDerivAt (fun σ => stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2))
      (gaussianPDFReal 0 1 (log (F / K) * (σ * a)⁻¹ + σ * a / 2) * d) σ :=
    (hasDerivAt_stdNormalCDF _).comp σ he
  have h2 : HasDerivAt (fun σ => stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a))
      (gaussianPDFReal 0 1 (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) * (d - a)) σ :=
    (hasDerivAt_stdNormalCDF _).comp σ (he.sub hlin)
  have hid := pdf_identity F K (σ * a) hF hK hs
  convert (h1.const_mul F).sub (h2.const_mul K) using 1
  linear_combination (-d) * hid

lemma core_strictMonoOn (F K a : ℝ) (hF : 0 < F) (hK : 0 < K) (ha : 0 < a) :
    StrictMonoOn (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (Ioi 0) ∧
    ContinuousOn (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (Ioi 0) := by
  have hc : ContinuousOn (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (Ioi 0) :=
    fun σ hσ => (core_hasDerivAt F K a σ hF hK ha (ne_of_gt hσ)).continuousAt.continuousWithinAt
  refine ⟨strictMonoOn_of_deriv_pos (convex_Ioi 0) hc ?_, hc⟩
  intro σ hσ
  rw [interior_Ioi] at hσ
  rw [(core_hasDerivAt F K a σ hF hK ha (ne_of_gt hσ)).deriv]
  exact mul_pos (mul_pos hK (gaussianPDFReal_pos 0 1 _ one_ne_zero)) ha

lemma core_tendsto_atTop (F K a : ℝ) (ha : 0 < a) :
    Tendsto (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) atTop (𝓝 F) := by
  have hs : Tendsto (fun σ : ℝ => σ * a) atTop atTop := tendsto_id.atTop_mul_const ha
  have hu : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹) atTop (𝓝 0) := by
    simpa using (tendsto_inv_atTop_zero.comp hs).const_mul (log (F / K))
  have hv : Tendsto (fun σ : ℝ => σ * a / 2) atTop atTop := hs.atTop_div_const two_pos
  have h1 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2) atTop atTop :=
    hu.add_atTop hv
  have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) atTop atBot := by
    have := hu.add_atBot (tendsto_neg_atTop_atBot.comp hv)
    refine this.congr (fun σ => ?_)
    simp only [Function.comp]; ring
  have := ((tendsto_stdNormalCDF_atTop.comp h1).const_mul F).sub
    ((tendsto_stdNormalCDF_atBot.comp h2).const_mul K)
  simpa using this

lemma core_tendsto_zero (F K a : ℝ) (hF : 0 < F) (hK : 0 < K) (ha : 0 < a) :
    Tendsto (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (𝓝[>] 0)
        (𝓝 (max (F - K) 0)) := by
  have hv : Tendsto (fun σ : ℝ => σ * a / 2) (𝓝[>] 0) (𝓝 0) := by
    have := ((continuous_id.mul continuous_const).div_const 2 :
      Continuous (fun σ : ℝ => σ * a / 2)).tendsto 0
    simpa using this.mono_left nhdsWithin_le_nhds
  have hw : Tendsto (fun σ : ℝ => -(σ * a / 2)) (𝓝[>] 0) (𝓝 0) := by
    simpa using hv.neg
  have hinv : Tendsto (fun σ : ℝ => σ⁻¹) (𝓝[>] 0) atTop := tendsto_inv_nhdsGT_zero
  have hu_eq : ∀ σ : ℝ, log (F / K) * (σ * a)⁻¹ = (log (F / K) * a⁻¹) * σ⁻¹ := by
    intro σ; rw [mul_inv]; ring
  have e1 : ∀ σ : ℝ, log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a =
      log (F / K) * (σ * a)⁻¹ + -(σ * a / 2) := by intro σ; ring
  rcases lt_trichotomy (log (F / K)) 0 with hm | hm | hm
  · -- F < K: both arguments go to -∞, price to 0
    have hFK : F < K := by
      have := (log_neg_iff (div_pos hF hK)).1 hm
      rwa [div_lt_one hK] at this
    have hu : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹) (𝓝[>] 0) atBot := by
      simp only [hu_eq]
      exact hinv.const_mul_atTop_of_neg (mul_neg_of_neg_of_pos hm (inv_pos.2 ha))
    have h1 := hu.atBot_add hv
    have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) (𝓝[>] 0)
        atBot := by simp only [e1]; exact hu.atBot_add hw
    have := ((tendsto_stdNormalCDF_atBot.comp h1).const_mul F).sub
      ((tendsto_stdNormalCDF_atBot.comp h2).const_mul K)
    rw [max_eq_right (by linarith)]
    simpa using this
  · -- F = K
    have hFK : F = K := by
      rcases log_eq_zero.1 hm with h | h | h
      · exact absurd h (div_pos hF hK).ne'
      · exact (div_eq_one_iff_eq hK.ne').1 h
      · linarith [div_pos hF hK]
    have h1 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2) (𝓝[>] 0) (𝓝 0) := by
      simpa [hm] using hv
    have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) (𝓝[>] 0)
        (𝓝 0) := by simp only [e1]; simpa [hm] using hw
    have := (((continuous_stdNormalCDF.tendsto 0).comp h1).const_mul F).sub
      (((continuous_stdNormalCDF.tendsto 0).comp h2).const_mul K)
    rw [hFK] at this ⊢
    simpa using this
  · -- F > K
    have hFK : K < F := by
      have := (log_pos_iff (div_pos hF hK).le).1 hm
      rwa [one_lt_div hK] at this
    have hu : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹) (𝓝[>] 0) atTop := by
      simp only [hu_eq]
      exact hinv.const_mul_atTop (mul_pos hm (inv_pos.2 ha))
    have h1 := hu.atTop_add hv
    have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) (𝓝[>] 0)
        atTop := by simp only [e1]; exact hu.atTop_add hw
    have := ((tendsto_stdNormalCDF_atTop.comp h1).const_mul F).sub
      ((tendsto_stdNormalCDF_atTop.comp h2).const_mul K)
    rw [max_eq_left (by linarith)]
    simpa using this

lemma window_of_strictMonoOn (f : ℝ → ℝ) (lo hi : ℝ) (hmono : StrictMonoOn f (Ioi 0))
    (hcont : ContinuousOn f (Ioi 0)) (h0 : Tendsto f (𝓝[>] 0) (𝓝 lo))
    (hinf : Tendsto f atTop (𝓝 hi)) :
    (∀ σ, 0 < σ → lo < f σ ∧ f σ < hi) ∧ ∀ c, lo < c → c < hi → ∃! σ, 0 < σ ∧ f σ = c := by
  refine ⟨fun σ hσ => ⟨?_, ?_⟩, fun c hlo hhi => ?_⟩
  · have hσ2 : 0 < σ / 2 := by positivity
    have hle : lo ≤ f (σ / 2) := by
      refine le_of_tendsto h0 ?_
      filter_upwards [Ioo_mem_nhdsGT hσ2] with x hx
      exact (hmono.lt_iff_lt hx.1 hσ2).2 hx.2 |>.le
    exact hle.trans_lt (hmono hσ2 hσ (by linarith))
  · have h2 : 0 < 2 * σ := by positivity
    have hle : f (2 * σ) ≤ hi := by
      refine ge_of_tendsto hinf ?_
      filter_upwards [eventually_ge_atTop (2 * σ)] with x hx
      exact hmono.monotoneOn h2 (lt_of_lt_of_le h2 hx) hx
    exact (hmono hσ h2 (by linarith)).trans_le hle
  · obtain ⟨x1, hx1c, hx1⟩ :=
      ((h0.eventually_lt_const hlo).and self_mem_nhdsWithin).exists
    obtain ⟨x2, hx2c, hx2⟩ :=
      ((hinf.eventually_const_lt hhi).and (eventually_gt_atTop 0)).exists
    have hx12 : x1 ≤ x2 := by
      by_contra h
      have := hmono hx2 hx1 (not_le.1 h)
      linarith
    obtain ⟨σ, hσI, hσc⟩ : c ∈ f '' Icc x1 x2 :=
      intermediate_value_Icc hx12 (hcont.mono fun y hy => lt_of_lt_of_le hx1 hy.1)
        ⟨hx1c.le, hx2c.le⟩
    have hσ : 0 < σ := lt_of_lt_of_le hx1 hσI.1
    refine ⟨σ, ⟨hσ, hσc⟩, fun y hy => ?_⟩
    exact hmono.injOn hy.1 hσ (hy.2.trans hσc.symm)

lemma d1_eq (m σ a : ℝ) : (m + σ ^ 2 * a ^ 2 / 2) / (σ * a) = m * (σ * a)⁻¹ + σ * a / 2 := by
  by_cases h : σ * a = 0
  · rcases mul_eq_zero.1 h with h | h <;> simp [h]
  · field_simp

lemma capletPrice_eq (L τ D F K T σ : ℝ) (hT : 0 ≤ T) :
    capletPrice L τ D F K T σ = L * τ * D *
      (F * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2)
        - K * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2 - σ * √T)) := by
  unfold capletPrice
  have h := sq_sqrt hT
  simp only
  rw [← d1_eq, h]

lemma caplet_price_window_aux (L τ D F K T : ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hD : 0 < D) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    (∀ σ : ℝ, 0 < σ →
        capletFloor L τ D F K < capletPrice L τ D F K T σ ∧
          capletPrice L τ D F K T σ < capletCeiling L τ D F) ∧
      StrictMonoOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) (𝓝[>] 0) (𝓝 (capletFloor L τ D F K)) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) atTop (𝓝 (capletCeiling L τ D F)) ∧
      ∀ c : ℝ, capletFloor L τ D F K < c → c < capletCeiling L τ D F →
        ∃! σ : ℝ, 0 < σ ∧ capletPrice L τ D F K T σ = c := by
  have ha : 0 < √T := sqrt_pos.2 hT
  have hc : 0 < L * τ * D := by positivity
  have hfun : (fun σ ↦ capletPrice L τ D F K T σ) = fun σ => L * τ * D *
      (F * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2)
        - K * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2 - σ * √T)) := by
    funext σ; exact capletPrice_eq L τ D F K T σ hT.le
  obtain ⟨hmono, hcont⟩ := core_strictMonoOn F K (√T) hF hK ha
  have hmono' : StrictMonoOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) := by
    rw [hfun]
    intro x hx y hy hxy
    exact mul_lt_mul_of_pos_left (hmono hx hy hxy) hc
  have hcont' : ContinuousOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) := by
    rw [hfun]; exact hcont.const_smul (L * τ * D)
  have h0 : Tendsto (fun σ ↦ capletPrice L τ D F K T σ) (𝓝[>] 0)
      (𝓝 (capletFloor L τ D F K)) := by
    rw [hfun]; exact (core_tendsto_zero F K (√T) hF hK ha).const_mul (L * τ * D)
  have hinf : Tendsto (fun σ ↦ capletPrice L τ D F K T σ) atTop
      (𝓝 (capletCeiling L τ D F)) := by
    rw [hfun]; exact (core_tendsto_atTop F K (√T) ha).const_mul (L * τ * D)
  obtain ⟨hb, hu⟩ := window_of_strictMonoOn _ _ _ hmono' hcont' h0 hinf
  exact ⟨hb, hmono', h0, hinf, hu⟩

lemma sum_Iic_fin_eq (n : ℕ) (g : Fin n → ℝ) (k : Fin n) :
    ∑ i ∈ Finset.Iic k, g i =
      ∑ j ∈ Finset.range ((k : ℕ) + 1), (if h : j < n then g ⟨j, h⟩ else 0) := by
  rw [Nat.range_succ_eq_Iic, ← Fin.map_valEmbedding_Iic, Finset.sum_map]
  simp

lemma sum_Iic_fin_iff (n : ℕ) (g : Fin n → ℝ) (C : ℕ → ℝ) (hC : C 0 = 0) :
    (∀ k : Fin n, ∑ i ∈ Finset.Iic k, g i = C (k + 1)) ↔
      ∀ k : Fin n, g k = C (k + 1) - C k := by
  set g' : ℕ → ℝ := fun j => if h : j < n then g ⟨j, h⟩ else 0 with hg'
  have hgk : ∀ k : Fin n, g k = g' k := fun k => by simp [hg']
  simp only [sum_Iic_fin_eq]
  constructor
  · intro h k
    have h1 := h k
    rw [Finset.sum_range_succ] at h1
    have h0 : ∑ j ∈ Finset.range (k : ℕ), g' j = C k := by
      rcases Nat.eq_zero_or_eq_succ_pred (k : ℕ) with hk | hk
      · rw [hk, Finset.sum_range_zero, hC]
      · have := h ⟨(k : ℕ) - 1, by omega⟩
        simp only at this
        rw [show (k : ℕ) - 1 + 1 = k by omega] at this
        exact this
    rw [hgk]
    linarith
  · intro h
    have key : ∀ m, m < n → ∑ j ∈ Finset.range (m + 1), g' j = C (m + 1) := by
      intro m
      induction m with
      | zero =>
        intro hm
        have := h ⟨0, hm⟩
        rw [hgk] at this
        simp only at this
        simp [this, hC]
      | succ m ih =>
        intro hm
        have := h ⟨m + 1, hm⟩
        rw [hgk] at this
        simp only at this
        rw [Finset.sum_range_succ, ih (by omega), this]
        ring
    exact fun k => key k k.2

/-- **Caplet stripping has exactly one answer** (Why it works, Steps 2 to 4, and the detailed
proof). Take `n` caplets with one notional `L > 0`, one accrual `τ > 0` and one strike `K > 0`
across the strip; caplet `i` fixes at `T i > 0`, has a positive forward `F i` and a positive
discount factor `D i` to its payment date. Quote one flat volatility `flat k` for each cap
`k = 1, …, n`, turn each quote into the cap price `C_k = ∑_{i<k} c_i(flat k)` (with `C_0 = 0`).
If every neighbouring difference `C_{k+1} - C_k` lies strictly between caplet `k`'s floor and
ceiling, then exactly one list of positive caplet volatilities `σ` reproduces every cap price:
`∑_{i ≤ k} c_i(σ_i) = C_{k+1}` for every `k`. -/
theorem caplet_volatilities_exist_and_are_unique (n : ℕ) (L τ K : ℝ) (T F D flat : ℕ → ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hK : 0 < K)
    (hT : ∀ i < n, 0 < T i) (hF : ∀ i < n, 0 < F i) (hD : ∀ i < n, 0 < D i)
    (hwindow : ∀ k < n,
      capletFloor L τ (D k) (F k) K <
          capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) ∧
        capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) <
          capletCeiling L τ (D k) (F k)) :
    ∃! σ : Fin n → ℝ, (∀ i, 0 < σ i) ∧
      ∀ k : Fin n, ∑ i ∈ Finset.Iic k, capletPrice L τ (D i) (F i) K (T i) (σ i) =
        capPrice L τ K T F D (k + 1) (flat (k + 1)) := by
  have hC : capPrice L τ K T F D 0 (flat 0) = 0 := by simp [capPrice]
  have hex : ∀ k : Fin n, ∃! s : ℝ, 0 < s ∧ capletPrice L τ (D k) (F k) K (T k) s =
      capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) :=
    fun k => (caplet_price_window_aux L τ (D k) (F k) K (T k) hL hτ (hD k k.2) (hF k k.2) hK
      (hT k k.2)).2.2.2.2 _ (hwindow k k.2).1 (hwindow k k.2).2
  choose σ hσ hσu using hex
  refine ⟨σ, ⟨fun i => (hσ i).1, ?_⟩, ?_⟩
  · exact (sum_Iic_fin_iff n (fun i => capletPrice L τ (D i) (F i) K (T i) (σ i))
      (fun j => capPrice L τ K T F D j (flat j)) hC).2 (fun k => (hσ k).2)
  · rintro σ' ⟨hpos', hsum'⟩
    have h := (sum_Iic_fin_iff n (fun i => capletPrice L τ (D i) (F i) K (T i) (σ' i))
      (fun j => capPrice L τ K T F D j (flat j)) hC).1 hsum'
    funext k
    exact hσu k (σ' k) ⟨hpos' k, h k⟩

/-- **One caplet's price curve** (Why it works, Step 3, and the detailed proof). For a notional
`L > 0`, accrual `τ > 0`, discount factor `D > 0`, forward `F > 0`, strike `K > 0` and fixing
date `T > 0`, the caplet price at every positive volatility lies strictly between the floor
`L τ D max(F - K, 0)` and the ceiling `L τ D F`; it rises strictly with volatility; it tends to
the floor as volatility shrinks to zero and to the ceiling as volatility grows without limit;
so every price strictly inside the window comes from exactly one positive volatility. -/
theorem caplet_price_rises_strictly_from_floor_to_ceiling (L τ D F K T : ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hD : 0 < D) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    (∀ σ : ℝ, 0 < σ →
        capletFloor L τ D F K < capletPrice L τ D F K T σ ∧
          capletPrice L τ D F K T σ < capletCeiling L τ D F) ∧
      StrictMonoOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) (𝓝[>] 0) (𝓝 (capletFloor L τ D F K)) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) atTop (𝓝 (capletCeiling L τ D F)) ∧
      ∀ c : ℝ, capletFloor L τ D F K < c → c < capletCeiling L τ D F →
        ∃! σ : ℝ, 0 < σ ∧ capletPrice L τ D F K T σ = c := by
  exact caplet_price_window_aux L τ D F K T hL hτ hD hF hK hT

/-- **Quotes that allow no answer** (When it holds, Existence; the detailed proof, "Existence
fails at the edges"). With the same setup, if for some caplet `k` the cap price difference
`C_{k+1} - C_k` is at or below that caplet's floor, or at or above its ceiling, then no list of
positive caplet volatilities reproduces every cap price. -/
theorem no_caplet_volatilities_outside_the_window (n : ℕ) (L τ K : ℝ) (T F D flat : ℕ → ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hK : 0 < K)
    (hT : ∀ i < n, 0 < T i) (hF : ∀ i < n, 0 < F i) (hD : ∀ i < n, 0 < D i)
    (k : ℕ) (hk : k < n)
    (hout : capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) ≤
          capletFloor L τ (D k) (F k) K ∨
        capletCeiling L τ (D k) (F k) ≤
          capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k)) :
    ¬ ∃ σ : Fin n → ℝ, (∀ i, 0 < σ i) ∧
      ∀ j : Fin n, ∑ i ∈ Finset.Iic j, capletPrice L τ (D i) (F i) K (T i) (σ i) =
        capPrice L τ K T F D (j + 1) (flat (j + 1)) := by
  rintro ⟨σ, hpos, hsum⟩
  have hC : capPrice L τ K T F D 0 (flat 0) = 0 := by simp [capPrice]
  have h := (sum_Iic_fin_iff n (fun i => capletPrice L τ (D i) (F i) K (T i) (σ i))
      (fun j => capPrice L τ K T F D j (flat j)) hC).1 hsum ⟨k, hk⟩
  have hb := (caplet_price_window_aux L τ (D k) (F k) K (T k) hL hτ (hD k hk) (hF k hk) hK
      (hT k hk)).1 (σ ⟨k, hk⟩) (hpos _)
  simp only at h
  rw [h] at hb
  rcases hout with hout | hout
  · linarith [hb.1]
  · linarith [hb.2]

-- Step 2 in cents: cap 8 minus cap 7 is caplet 8's price, 14,908.96 - 11,481.00 = 3,427.96.
example : (1490896 : ℤ) - 1148100 = 342796 := by norm_num
-- Worked numbers: caplet 8's price sits inside its window, 2,611.19 < 3,427.96 < 13,749.78.
example : (261119 : ℕ) < 342796 ∧ (342796 : ℕ) < 1374978 := by decide
-- The wrong road, in tenths of a percent: 8 × 29.4 - 7 × 30.0 = 25.2.
example : (8 : ℤ) * 294 - 7 * 300 = 252 := by norm_num
-- The 2-year cap is cap 7: its last caplet fixes at 7 quarters = 1.75 years and pays at 2 years.
example : (7 : ℚ) * (1 / 4) = 7 / 4 ∧ (7 : ℚ) / 4 + 1 / 4 = 2 := by norm_num

#print axioms caplet_volatilities_exist_and_are_unique
#print axioms caplet_price_rises_strictly_from_floor_to_ceiling
#print axioms no_caplet_volatilities_outside_the_window
#print axioms stdNormalCDF_eq_integral
#print axioms continuous_stdPDF
#print axioms hasDerivAt_stdNormalCDF
#print axioms stdNormalCDF_strictMono
#print axioms continuous_stdNormalCDF
#print axioms tendsto_stdNormalCDF_atTop
#print axioms tendsto_stdNormalCDF_atBot
#print axioms pdf_identity
#print axioms core_hasDerivAt
#print axioms core_strictMonoOn
#print axioms core_tendsto_atTop
#print axioms core_tendsto_zero
#print axioms window_of_strictMonoOn
#print axioms d1_eq
#print axioms capletPrice_eq
#print axioms caplet_price_window_aux
#print axioms sum_Iic_fin_eq
#print axioms sum_Iic_fin_iff
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'caplet_volatilities_exist_and_are_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'caplet_price_rises_strictly_from_floor_to_ceiling' depends on axioms: [propext, Classical.choice, Quot.sound]
'no_caplet_volatilities_outside_the_window' depends on axioms: [propext, Classical.choice, Quot.sound]
'stdNormalCDF_eq_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'continuous_stdPDF' depends on axioms: [propext, Classical.choice, Quot.sound]
'hasDerivAt_stdNormalCDF' depends on axioms: [propext, Classical.choice, Quot.sound]
'stdNormalCDF_strictMono' depends on axioms: [propext, Classical.choice, Quot.sound]
'continuous_stdNormalCDF' depends on axioms: [propext, Classical.choice, Quot.sound]
'tendsto_stdNormalCDF_atTop' depends on axioms: [propext, Classical.choice, Quot.sound]
'tendsto_stdNormalCDF_atBot' depends on axioms: [propext, Classical.choice, Quot.sound]
'pdf_identity' depends on axioms: [propext, Classical.choice, Quot.sound]
'core_hasDerivAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'core_strictMonoOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'core_tendsto_atTop' depends on axioms: [propext, Classical.choice, Quot.sound]
'core_tendsto_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'window_of_strictMonoOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'd1_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'capletPrice_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'caplet_price_window_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_Iic_fin_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_Iic_fin_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run.
> - **Make every quote 30%.** Set `FLAT = [0.30] * 8`. Every caplet strips to 30.00%. A flat line of flat volatilities means a flat line of caplet volatilities, and only then are the two the same thing.
> - **Raise the last quote one point.** Set cap 8's quote to `0.31`. Caplet 8 jumps from 26.3744% to 35.8823%: one point on the cap is nearly ten on the caplet. The one point raises all eight caplets' prices, about six times caplet 8's own vega in dollars, and caplet 8 alone must carry that rise.
> - **Bump the 2-year quote.** Set cap 7's quote to `0.301`. Caplets 1 to 6 do not move; caplet 7 rises 0.5214 points and caplet 8 falls 0.5136. The staircase in action.
> - **Walk cap 8 down.** Lower cap 8's quote toward 27.1140%. Caplet 8's volatility slides to zero; one step below, `strip` returns `nan` for it, the code's way of saying no volatility exists.

---

## The usual mistake

> [!warning]
> **Pricing a caplet at its cap's flat volatility.** The flat volatility is a device for quoting a whole cap in one number. Caplet 7 inside the 2-year cap is worth $3,006.16, not the $3,151.12 that 30% gives it. The error grows with the slope of the term structure and is largest for the newest caplet in a cap.
>
> Smaller traps:
> - **Stripping volatilities instead of prices.** $8\Sigma_8 - 7\Sigma_7$ gives 25.2000% instead of 26.3744%. Only dollar prices subtract.
> - **Differencing two caps at one volatility.** Pricing cap 8 and cap 7 both at 29.40% and subtracting returns caplet 8 at 29.40%, the flat quote again. Each cap must be priced at its own quote before the subtraction.
> - **Forcing a solution the quotes do not allow.** A root finder given a price below the floor either fails or returns garbage near zero. Check the window first: here caplet 8 needs between $2,611.19 and $13,749.78.
> - **Mixing strikes.** Differencing an at-the-money 2-year cap and an at-the-money 2.25-year cap subtracts caplets struck at different rates. The result is not a caplet price, and its volatility belongs to no strike.

---

## Where you meet it in real life

- **Rates desks, every morning.** Broker screens show flat cap volatilities. Pricing systems strip them into caplet volatilities before valuing any cap, floor or single caplet that does not match a quoted contract exactly.
- **Odd-dated and amortizing caps.** A 1.6-year cap, or a cap on a loan whose notional shrinks each quarter, is a different bag of caplets. Only caplet volatilities price it; no flat quote exists for it.
- **Volatility risk by bucket.** The sawtooth in Step 4 is how a book's exposure is split by expiry: one quote moves two caplets in opposite directions. Hedging a single caplet needs two neighbouring caps. See [Swaption Greeks](08-swaption-greeks-and-hedging.md) for the swaption side of the same bookkeeping.
- **Calibrating rate models.** Models of the whole curve, such as the LIBOR market model (named after LIBOR, the London interbank rate it was built for), take caplet volatilities as inputs: one per forward rate. Swaption volatilities add information about how forward rates move together ([Swaptions](04-swaptions-payer-and-receiver.md)).
- **The strike dimension.** Stripping at each strike on the screen gives a grid of caplet volatilities by date and strike, which a smile model then smooths ([SABR for rates](07-sabr-for-rates-and-the-volatility-cube.md)).
- **Quote checks.** A falling flat volatility term structure that leaves a caplet window empty is a stale or mistyped quote. Stripping is the test.

> **Say it back**
> A cap is quoted by one flat volatility, which belongs to the whole cap and to none of its caplets. Converting each quote to a price and subtracting neighbouring caps isolates one caplet's price, exactly, in any model. A caplet's price rises strictly with its volatility between a zero-volatility floor and a ceiling, so each price inside that window has exactly one volatility. The caps form a staircase, so the eight caplet volatilities are solved in order and are unique. A quote that pushes a caplet's price below its floor has no answer and signals inconsistent quotes.

---

## What this builds on

- [Caps and floors](02-caps-floors-and-parity.md): a cap is the sum of its caplets, and its price is the sum of their prices. Step 2 is that fact used as a subtraction.
- [Solving backwards](../07-Greeks%20by%20Numbers%20and%20Calibration/05-root-finding-for-inverses.md): bisection, the secant method, and the bracket-first discipline that Step 3 relies on.

## Where this goes next

- [Swaptions](04-swaptions-payer-and-receiver.md): the other standard rates option, one option on a whole swap rather than a strip of small options, so no stripping by subtraction is possible.
- [Rate volatilities](06-normal-and-shifted-volatilities-for-rates.md): the same stripping with the caplet formula swapped for a normal or shifted one, as markets quote today.
- [SABR for rates](07-sabr-for-rates-and-the-volatility-cube.md): caplet volatilities at many strikes, smoothed by one model per expiry.
- [Solving rate options backwards](09-rate-option-inverses.md): the full catalogue of solving rate options backwards, with their existence and boundary cases.

Stripping gives one volatility per caplet at one strike; what it cannot say is how the volatility changes with the strike, or how the eight forward rates move together, and those are the questions the smile and swaption cards answer.

---

## Sources

Verified 28 Sep 2026: every link below resolves to the publisher's page.

- Black, Fischer. "The Pricing of Commodity Contracts." *Journal of Financial Economics* 3, no. 1–2 (1976): 167–179. [doi:10.1016/0304-405X(76)90024-6](https://doi.org/10.1016/0304-405X(76)90024-6). The formula each caplet is priced with.
- Brigo, Damiano, and Fabio Mercurio. *Interest Rate Models — Theory and Practice: With Smile, Inflation and Credit*, 2nd ed. Springer, 2006. [Publisher page](https://link.springer.com/book/10.1007/978-3-540-34604-3). Caps, caplet volatilities and their stripping from market quotes, and the market model they feed.
- Hull, John C. *Options, Futures, and Other Derivatives*, 11th ed. Pearson. [Publisher page](https://www.pearson.com/en-us/subject-catalog/p/options-futures-and-other-derivatives/P200000005938). The chapter on standard market models for interest rate derivatives: flat volatilities against the volatilities of single caplets.
