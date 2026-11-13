# Hull-White: Vasicek with a time-dependent drift that fits today's curve exactly

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Short-Rate Models](../README.md#s30) → Hull-White

---

## General Overview

One morning a screen carries six quotes: two deposits and four par swaps, from six months out to five years. The ladder on [Bootstrapping](../02-Curves/04-bootstrapping-the-discount-curve.md) turns them into six prices of a future dollar. A dollar due in five years costs 0.79621728 dollars that morning. Every bond and swap on the desk is valued off those six numbers.

Now the desk sells an option on a bond. The option pays off only if rates move, so its price needs a model of how the overnight rate wanders. The shelf's model is Vasicek ([Vasicek](02-vasicek-model.md)): the rate is pulled toward 5 percent at speed 0.3 a year, shaken with volatility 1 percent a year, and starts at 4 percent. It prices every bond in closed form. It prices the five-year dollar at 0.79985563. On a 10,000,000 dollar payment that is 36,383.48 dollars too much.

That miss is fatal. An option hedged with bonds the model misprices is priced off the wrong bonds.

John Hull and Alan White fixed this in 1990 with one change. Vasicek pulls toward a fixed level. Hull and White let the level move with the calendar, and set its path so that every model bond price equals the market's. The model carries that path as the **drift term** θ(t) (theta), a known function of time; the moving level is θ(t) divided by the pull speed. Theta is not a forecast. It is the curve, rewritten as a push on the rate.

**Hull-White keeps Vasicek's pull and noise but moves the pull's target through time, and for each choice of pull speed and noise exactly one path of target makes every zero-coupon price match today's curve.**

**What kind of fact this is:** a model (an assumption about how rates move, which fits markets well enough, not a law), with a theorem inside it: given the speed and the noise, the fitting drift exists, is unique, and is derived on this card in Why it works.

### The picture: the curve Vasicek cannot draw

A **forward rate** is the rate the curve charges for borrowing over one instant at a future date, locked today. Between two quoted dates the six quotes pin only an average, so this card holds the forward flat in each gap: the simplest rule on [Between the pillars](../02-Curves/05-curve-interpolation-and-shape.md).

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Forward rate: the market's curve against plain Vasicek's"
    x-axis "Years from today" [0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.25, 3.50, 3.75, 4.00, 4.25, 4.50, 4.75, 5.00]
    y-axis "Forward rate (percent a year)" 3.8 --> 5.0
    line [3.96, 3.96, 4.27, 4.27, 4.51, 4.51, 4.51, 4.51, 4.76, 4.76, 4.76, 4.76, 4.74, 4.74, 4.74, 4.74, 4.67, 4.67, 4.67, 4.67, 4.67]
    line [4.00, 4.07, 4.14, 4.20, 4.26, 4.31, 4.36, 4.40, 4.44, 4.48, 4.51, 4.54, 4.57, 4.60, 4.63, 4.65, 4.67, 4.69, 4.71, 4.73, 4.74]
```

Orange: the market's forward curve, flat inside each gap and stepping at each quoted date; it rises to 4.76 percent in the third year and then falls. Green: plain Vasicek's forward curve, one smooth rise from 4.00 to 4.74 percent. Its three numbers allow only a few shapes, and a hump that turns down after three years is not one of them. Hull-White's forward curve is the orange line exactly.

---

## The formula

Notation first, in words.

- The **short rate** $r(t)$ is the rate for borrowing over one instant at time $t$, in years from today.
- $dr$ is its change over the next instant, $dt$ is that instant's length, and $dW$ is a random kick with mean zero and variance $dt$: the Brownian step of [Mean reversion](../../11-Stochastic%20processes%20and%20calculus/06-Ito%20Calculus/05-ornstein-uhlenbeck-and-cir-processes.md).
- $D(T)$ is the discount factor: today's price of a dollar due at time $T$.
- $f(0,t)$ is today's forward rate for the instant at $t$, and $f'(0,t)$ is its slope, how fast it changes with the date. They are tied by $D(T) = e^{-\int_0^T f(0,s)\,ds}$: a future dollar is discounted at the forward rate of every instant on the way.
- $a$ is the pull speed and $\sigma$ the noise size, Vasicek's two constants.
- $\theta(t)$ is the drift term.

The model:

$$dr \;=\; \bigl(\theta(t) - a\,r\bigr)\,dt \;+\; \sigma\,dW$$

The drift that fits the curve:

$$\boxed{\;\theta(t) \;=\; f'(0,t) \;+\; a\,f(0,t) \;+\; \frac{\sigma^2}{2a}\bigl(1 - e^{-2at}\bigr)\;}$$

**Read it aloud:** the push at each date is the forward curve's slope, plus the pull speed times the forward level, plus a small lift that pays for the noise.

Once theta is set, a zero-coupon bond (one dollar at $T$, nothing before) is worth, at a later date $t$ with the short rate at $r(t)$:

$$P(t,T) \;=\; \frac{D(T)}{D(t)}\,\exp\!\Bigl(B\,f(0,t) \;-\; \frac{\sigma^2}{4a}\bigl(1 - e^{-2at}\bigr)B^2 \;-\; B\,r(t)\Bigr), \qquad B = B(t,T) = \frac{1 - e^{-a(T-t)}}{a}$$

Everything in front of $e^{-B\,r(t)}$ is called $A(t,T)$. At $t = 0$ with the rate starting at the curve's own front end, $r(0) = f(0,0)$, this is $D(T)$ for every $T$. That is the fit, by construction.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $r(t)$, $r$ | the short rate: borrowing for one instant at time $t$ | starts at 3.9605 percent, the first forward | every bond falls; its logarithm by $B$ per unit of rate |
| $t$, $T$ | today-to-date in years; $T$ a bond's payment date | 0 to 5 | a later $T$ is discounted longer |
| $a$ | the pull speed: how hard the rate is drawn to its target | 0.3 a year, half-life 2.31 years | the noise fades faster; the lift shrinks |
| $\sigma$ | the noise size, per year | 1 percent | the lift grows; zero prices stay fixed, theta rises |
| $dW$, $dt$, $dr$ | a random kick with variance $dt$; one instant of time; the rate's change over it | — | — |
| $\theta(t)$ | the drift: the push toward the moving target | 1.4400 percent a year at 2.5 years | the rate's mean path rises; bonds fall |
| $f(0,t)$, $f'(0,t)$ | today's forward rate at $t$; its slope | 4.7569 percent in the third year; slope 0 inside a gap | theta rises with either |
| $D(T)$ | today's price of a dollar due at $T$: the curve | 0.79621728 at five years | — |
| $P(t,T)$ | the model's price at $t$ of a dollar due at $T$ | 0.848232 at 1.5 years, if the rate sits at its expected 4.5134 percent | — |
| $B(t,T)$, $A$ | $B$: the bond's exposure to the rate, in years of the rate's memory left; $A$: everything in front of $e^{-B r}$ | $B$ = 2.589566 for $t = 0$, $T = 5$ | the bond swings more per unit of rate |
| $x(t)$, $\varphi(t)$ | the rate's noise part, pulled to zero and starting there; its known part, the expected path | $\varphi$ = 4.5134 percent at 1.5 years | — |
| $V(T)$ | the variance of the total rate paid from today to $T$ | 0.001561 at five years | the price lift from averaging grows |

Two helper pieces, used in Why it works. The **lift** is how far the rate's expected path sits above the forward curve:

$$\text{lift}(t) \;=\; \frac{\sigma^2}{2a^2}\bigl(1 - e^{-at}\bigr)^2$$

It is 0.0335 percent at five years. The variance of the rate paid over the whole life is

$$V(T) \;=\; \frac{\sigma^2}{a^2}\Bigl(T - 2B(0,T) + \frac{1 - e^{-2aT}}{2a}\Bigr)$$

**Existence, uniqueness and the edges.** For fixed $a$ and $\sigma$, theta exists wherever the forward curve has a slope, and it is unique: the curve fixes it with no freedom left. Where the forward jumps, as it does at each quoted date on this curve, the slope is a one-off step and theta carries a **kick**: at that instant the rate is lifted by the size of the jump. As $a$ falls to zero the formula tends to $f'(0,t) + \sigma^2 t$, the Ho-Lee model's drift, with no pull at all. As $\sigma$ falls to zero the lift vanishes and the rate simply walks along the forward curve.

### When it holds

- **Rates are normally distributed.** The noise is added, not multiplied, so the rate can go below zero. Here the five-year rate has mean 4.7077 percent and spread 1.2584 percent, and the chance it sits below zero is 0.000092. Products that break at a negative rate need [Cox-Ingersoll-Ross](03-cox-ingersoll-ross-model.md) or a lognormal cousin.
- **One source of noise.** Every maturity is driven by the same kick, so long and short rates always move the same way. Products that pay on the curve's shape are mispriced; [Beyond one factor](07-two-factor-and-lognormal-short-rate-models.md) adds a second.
- **Speed and noise are constants.** Two numbers cannot match every option quote across expiries; which quotes pin them is [Calibrating Hull-White](08-calibrating-a-short-rate-model.md).
- **The curve is filled between its quotes.** Theta needs a forward at every date. The quoted prices are matched whatever the fill; the prices between them, and theta's kicks, belong to the interpolation rule, not the market.
- **Today only.** Tomorrow's curve needs a new theta, so model prices move when the curve moves, not only when the rate does.

---

## Why it works

### Step 0: a bond price depends on the rate's average path and its spread, and only the drift touches the average

A zero-coupon bond pays one dollar at $T$. Its price today is the average, over every path the rate might take (weighted the pricing way, not by real-world odds), of the discount $e^{-\int_0^T r\,dt}$ ([A short-rate model](01-the-term-structure-equation.md)). In a Vasicek-type model the total rate paid, $\int_0^T r\,dt$, is normally distributed. So the price depends on two things only: the total's mean and its variance. The noise sets the variance, and the drift cannot change it. The drift sets the mean. A moving target can steer the mean path one date at a time, and a curve is one condition per date. That match of freedom to conditions is the whole idea.

### Step 1: split the rate into a known path and pure noise

Write the rate as $r(t) = \varphi(t) + x(t)$. Here $\varphi(t)$ (phi) is a path known today, the rate's expected path. $x(t)$ is the noise part: it obeys $dx = -a\,x\,dt + \sigma\,dW$ and starts at zero. That is an Ornstein-Uhlenbeck process, pulled toward zero ([Mean reversion](../../11-Stochastic%20processes%20and%20calculus/06-Ito%20Calculus/05-ornstein-uhlenbeck-and-cir-processes.md)). Adding the two equations shows the split works whenever

$$\theta(t) \;=\; \varphi'(t) + a\,\varphi(t)$$

So choosing theta and choosing the mean path are the same choice.

### Step 2: price the bond with the path and the noise separated

The known path comes out of the average untouched:

$$P(0,T) \;=\; e^{-\int_0^T \varphi(t)\,dt}\;\cdot\;\text{average of } e^{-\int_0^T x\,dt}$$

The total noise $\int_0^T x\,dt$ is normal with mean zero and variance $V(T)$. For a normal quantity with mean zero and variance $V$, the average of its negative exponential is $e^{V/2}$: the exponential weighs low values more than it discounts high ones, so averaging lifts the price. Hence

$$P(0,T) \;=\; \exp\Bigl(-\int_0^T \varphi(t)\,dt \;+\; \tfrac12 V(T)\Bigr)$$

The Monte Carlo road in the code (an average over simulated random paths) measures that lift directly. At five years it finds 1.00078107, with standard error 0.00000781; the formula says 1.00078061.

### Step 3: force every price onto the curve

The market says $P(0,T) = D(T) = e^{-\int_0^T f(0,s)\,ds}$ for every $T$. Setting the two exponents equal:

$$\int_0^T \varphi(t)\,dt \;=\; \int_0^T f(0,t)\,dt \;+\; \tfrac12 V(T) \quad\text{for every } T$$

Two quantities equal for every $T$ have equal slopes in $T$. The slope of $V$ is $(\sigma^2/a^2)(1 - e^{-aT})^2$. So

$$\varphi(t) \;=\; f(0,t) \;+\; \frac{\sigma^2}{2a^2}\bigl(1 - e^{-at}\bigr)^2 \;=\; f(0,t) + \text{lift}(t)$$

The expected rate must sit above the forward curve by exactly the lift. The lift adds up over the life to exactly half the variance, and that cancels the averaging bonus of Step 2. At five years both come to 0.000780.

### Step 4: read the drift off the mean path

Put this $\varphi(t)$ into Step 1's rule, $\theta = \varphi' + a\varphi$:

$$\theta(t) \;=\; f'(0,t) + a\,f(0,t) + \frac{\sigma^2}{a}\bigl(1 - e^{-at}\bigr)e^{-at} + \frac{\sigma^2}{2a}\bigl(1 - e^{-at}\bigr)^2$$

The last two terms share the factor $1 - e^{-at}$; the bracket left over is $2e^{-at} + 1 - e^{-at} = 1 + e^{-at}$, and $(1 - e^{-at})(1 + e^{-at}) = 1 - e^{-2at}$. That is the boxed formula.

Uniqueness comes from the same chain run backwards. The curve fixes $\int_0^T \varphi$ for every $T$, so it fixes $\varphi$, so it fixes theta. Nothing was chosen along the way except $a$ and $\sigma$.

### Step 5: the fit holds by construction, and at later dates too

At $t = 0$, $B(0,T)$ multiplies $f(0,0) - r(0)$, which is zero, and the other correction has the factor $1 - e^{0} = 0$. The price formula returns $D(T)$ exactly. At a later date, the same split gives the price in terms of the noise part $x(t)$. Substituting $x(t) = r(t) - f(0,t) - \text{lift}(t)$ turns it into the $A$, $B$ form in The formula.

<details>
<summary>Detailed proof: the bond price at a later date</summary>

Fix $t < T$ and condition on the noise part $x(t)$. From $t$ on, $x$ decays as $x(t)e^{-a(u-t)}$ plus fresh noise, so $\int_t^T x\,du$ is normal with mean $B(t,T)\,x(t)$ and variance $V(T - t)$, the same formula as $V$ with the clock restarted.

The known path contributes $\int_t^T \varphi = \int_t^T f(0,u)\,du + \tfrac12\bigl(V(T) - V(t)\bigr)$, by Step 3 at two dates. And $e^{-\int_t^T f(0,u)\,du} = D(T)/D(t)$. So

$$P(t,T) = \frac{D(T)}{D(t)}\exp\Bigl(-\tfrac12\bigl[V(T) - V(t) - V(T-t)\bigr] - B\,x(t)\Bigr)$$

Write $E = e^{-at}$ and $F = e^{-a(T-t)}$, so $e^{-aT} = EF$ and $aB = 1 - F$. Expanding the three $V$ terms, the plain time terms cancel and

$$\tfrac12\bigl[V(T) - V(t) - V(T-t)\bigr] = \frac{\sigma^2}{2a^3}\Bigl[2(1-E)(1-F) - \tfrac12(1-E^2)(1-F^2)\Bigr]$$

Put $1 - F = aB$ and $1 - F^2 = aB(2 - aB)$. The bracket becomes $aB\bigl[(1-E)^2 + \tfrac12(1-E^2)\,aB\bigr]$,
so the whole term equals $\frac{\sigma^2}{2a^2}(1-E)^2 B + \frac{\sigma^2}{4a}(1-E^2)B^2$, that is, $B\cdot\text{lift}(t) + \frac{\sigma^2}{4a}(1 - e^{-2at})B^2$. Substituting $x(t) = r(t) - f(0,t) - \text{lift}(t)$ cancels the $B\cdot\text{lift}(t)$ term and leaves the $A$, $B$ formula. The fourth road in the code tests the result independently: it simulates the rate to 1.5 years, prices the remaining bond with the formula, discounts along each path, and averages back to 0.79621618 against the market's 0.79621728, well inside the standard error of 0.00000337.

</details>

The same drift falls out of a different road. [Heath-Jarrow-Morton](../31-Forward-Rate%20Models/01-hjm-framework-and-the-drift-condition.md) models the whole forward curve, lets no-arbitrage fix its drift, and recovers Hull-White when each forward's volatility fades as $\sigma e^{-a(T-t)}$. [The Hull-White tree](06-hull-white-trinomial-tree.md) finds theta numerically instead, one tree step at a time.

---

## Worked numbers, by hand

The curve first: the six discount factors and the forward in each gap, from the bootstrap ladder.

| Gap, years | $D$ at the gap's end | Forward in the gap, percent | Kick at the gap's end, percentage points |
| --- | --- | --- | --- |
| 0 to 0.5 | 0.98039216 | 3.9605 | +0.3073 |
| 0.5 to 1 | 0.95969290 | 4.2679 | +0.2383 |
| 1 to 2 | 0.91740758 | 4.5061 | +0.2508 |
| 2 to 3 | 0.87478903 | 4.7569 | −0.0200 |
| 3 to 4 | 0.83431725 | 4.7369 | −0.0627 |
| 4 to 5 | 0.79621728 | 4.6742 | none |

Inside each gap the forward is flat, so its slope is zero and theta is $a f + $ the noise term. Theta across each gap, in percent a year: 1.1882 to 1.1925, 1.2847 to 1.2879, 1.3594 to 1.3635, 1.4387 to 1.4410, 1.4350 to 1.4362, 1.4174 to 1.4181. The kicks carry the slope.

Theta at 2.5 years, and the five-year zero rebuilt from it:

| Step | Arithmetic | Value |
| --- | --- | --- |
| forward at 2.5 years | the 2-to-3 gap | 4.7569 percent |
| pull times forward | 0.3 × 4.7569 | 1.4271 percent |
| noise term | $\frac{0.01^2}{0.6}(1 - e^{-1.5})$ | 0.0129 percent |
| **theta at 2.5 years** | 1.4271 + 0.0129 | **1.4400 percent a year** |
| the target it pulls toward | theta ÷ 0.3 | 4.8001 percent |
| forward rate paid, 0 to 5 years | $-\ln D(5)$, the gaps' forwards times their lengths | 0.227883 |
| lift paid, 0 to 5 years | integral of the lift | 0.000780 |
| half the variance | $\tfrac12 V(5)$, with $B(0,5) = 2.589566$ | 0.000780 |
| **five-year zero** | $e^{-0.227883 - 0.000780 + 0.000780}$ | **0.79621728** |

The expected rate pays a little more than the forward curve, and the spread of outcomes hands exactly that back.

A second case, at a later date. At 1.5 years the rate's expected level is 4.5134 percent, and there the bond maturing at five years is worth 0.848232. If the rate has climbed to 6 percent instead, it is worth 0.821345.

### What breaks if you drop a piece

The five-year zero, rebuilt from a damaged theta, against the market's 0.79621728; dollar errors on 10,000,000.

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drop the noise term from theta | 0.79683882, 6,215.38 too much | The expected rate sits on the forward curve, and averaging over the spread lifts the price |
| Drop the kicks at the quoted dates | 0.81007656, 138,592.78 too much | The slope term is gone, so the rate never climbs the curve's steps |
| Start the rate at 4 percent, not the curve's 3.9605 | 0.79540379, 8,134.93 too little | The fit needs $r(0) = f(0,0)$; the gap fades only at the pull speed, worth $B(0,5) = 2.59$ years of it |
| Plain Vasicek, fixed target 5 percent | 0.79985563, 36,383.48 too much | Three numbers cannot draw this curve |

Vasicek's miss is not one number. It changes sign along the curve.

```
Vasicek's price minus the market's, on 10,000,000.00 dollars due at each date (█ = $2,000)
0.5 y  ███                      −$5,414.59
1 y    █                        −$1,969.80
2 y    ██████                   +$12,210.86
3 y    █████████████████        +$33,263.01
4 y    █████████████████████    +$41,074.62
5 y    ██████████████████       +$36,383.48
```

Hull-White draws no bar: its prices equal the market's to eight decimals.

---

## Code, from first principles, and it actually runs

Both programs build the slice E curve (the code's name for the six-quote curve in the General Overview) with the bootstrap ladder, then reach the fit by five roads.

- Road 1 is the closed form, which matches by construction.
- Road 2 feeds theta, kicks included, into the equation for the rate's mean path, solves it step by step (fourth-order Runge-Kutta, 400 steps a year), and prices each quoted date from the result; it never uses the lift formula.
- Road 3 simulates the noise part with exact pull-to-zero steps, 50 a year, 20,000 paths each paired with its mirror image, and measures the averaging lift.
- Road 4 simulates to 1.5 years, prices the remaining bond with the $A$, $B$ formula, and discounts back.
- Road 5 hands theta's formula plain Vasicek's own curve, differentiated numerically, and must get back Vasicek's fixed push, 0.3 × 5 percent = 0.01500000.

The random numbers are a 64-bit linear congruential generator and Box-Muller, written out; the normal CDF is Simpson's rule.

### Python

```python
# Hull-White check: Vasicek's spring with a moving anchor theta(t), fitted to the slice E
# curve.  Standard library only; nothing imported that already knows an answer.  Roads:
# (1) the A, B closed form; (2) theta(t) fed into the mean-rate equation, integrated by
# RK4, kicks at the pillars; (3) Monte Carlo of the spring noise, own random numbers;
# (4) Monte Carlo of a discounted bond price 18 months out; (5) theta read off plain
# Vasicek's own curve by numerical differentiation, which must come out flat at a*b.
from math import exp, log, sqrt, cos, pi

DEPOSITS = ((0.5, 0.0400), (1.0, 0.0420))            # (years, simple rate)
SWAPS = ((2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465))   # (years, par rate)
A, SIG = 0.3, 0.01                    # reversion speed and volatility: the shelf's house pair
VB, VR0 = 0.05, 0.04                  # plain Vasicek: fixed anchor and starting rate
LOAN = 10_000_000.0

D = {0.0: 1.0}                        # the bootstrap ladder, as on the slice E card
for T, r in DEPOSITS: D[T] = 1.0 / (1.0 + T * r)
for n, S in SWAPS: D[float(n)] = (1.0 - S * sum(D[float(j)] for j in range(1, n))) / (1.0 + S)
PIL = sorted(D)                                       # 0, 0.5, 1, 2, 3, 4, 5
FW = [log(D[PIL[i]] / D[PIL[i + 1]]) / (PIL[i + 1] - PIL[i]) for i in range(6)]

def gap(t): return min(sum(1 for p in PIL[1:] if t >= p), 5)   # which gap t sits in
def f0(t): return FW[gap(t)]                          # forward rate f(0,t), flat in each gap
def Dt(t): i = gap(t); return D[PIL[i]] * exp(-FW[i] * (t - PIL[i]))
def Bf(t, T): return (1.0 - exp(-A * (T - t))) / A
def V(T): return SIG**2 / A**2 * (T - 2.0 * Bf(0.0, T) + (1.0 - exp(-2.0 * A * T)) / (2.0 * A))
def lift(t): return SIG**2 / (2.0 * A**2) * (1.0 - exp(-A * t))**2   # mean rate minus forward
def conv(t): return SIG**2 / (2.0 * A) * (1.0 - exp(-2.0 * A * t))
def closed(t, T, r):                                  # road 1: P(t,T) = A(t,T) exp(-B r)
    B = Bf(t, T)
    return Dt(T) / Dt(t) * exp(B * f0(t) - SIG**2 / (4.0 * A) * (1.0 - exp(-2.0 * A * t)) * B * B - B * r)

def road2(r0, use_conv=True, kicks=True):             # dm/dt = theta - a m, dI/dt = m
    m, I, out = r0, 0.0, {}
    for i in range(6):
        t0, n = PIL[i], int(400 * (PIL[i + 1] - PIL[i])); h = (PIL[i + 1] - t0) / n
        th = lambda t: A * FW[i] + (conv(t) if use_conv else 0.0)  # f' = 0 inside a gap
        for k in range(n):
            t = t0 + k * h
            k1 = th(t) - A * m;                 j1 = m
            k2 = th(t + h / 2) - A * (m + h / 2 * k1); j2 = m + h / 2 * k1
            k3 = th(t + h / 2) - A * (m + h / 2 * k2); j3 = m + h / 2 * k2
            k4 = th(t + h) - A * (m + h * k3);  j4 = m + h * k3
            m += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4); I += h / 6 * (j1 + 2 * j2 + 2 * j3 + j4)
        out[PIL[i + 1]] = exp(-I + 0.5 * V(PIL[i + 1]))
        if kicks and i < 5: m += FW[i + 1] - FW[i]      # f' at a pillar: the rate steps
    return out

def simpson(g, a, b, n=200):
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n)))
def ncdf(x): return 0.5 + (1 if x > 0 else -1) * simpson(lambda u: exp(-u * u / 2) / sqrt(2 * pi), 0.0, abs(x), 2000)

state = 20260928                                      # 64-bit LCG, then Box-Muller
def unif():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
def gauss(): u1 = unif(); u2 = unif(); return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

NP, STEPS, TS = 20000, 50, 1.5                        # antithetic pairs, steps a year, scenario date
dt = 1.0 / STEPS; ea = exp(-A * dt); sd = SIG * sqrt((1.0 - exp(-2.0 * A * dt)) / (2.0 * A))
iphi = {T: -log(Dt(T)) + simpson(lift, 0.0, T) for T in (1.0, TS, 5.0)}   # integral of the mean path
stats = {1.0: [0.0, 0.0], 5.0: [0.0, 0.0], TS: [0.0, 0.0]}
for _ in range(NP):
    x = I = 0.0
    for k in range(1, 5 * STEPS + 1):
        nx = x * ea + sd * gauss(); I += 0.5 * dt * (x + nx); x = nx   # exact spring step
        if k in (STEPS, 5 * STEPS):
            v = 0.5 * (exp(-I) + exp(I)); s = stats[k / STEPS]; s[0] += v; s[1] += v * v
        if k == int(TS * STEPS):                      # road 4: discount, then price the bond
            rp = f0(TS) + lift(TS)
            v = 0.5 * (exp(-iphi[TS] - I) * closed(TS, 5.0, rp + x) + exp(-iphi[TS] + I) * closed(TS, 5.0, rp - x))
            s = stats[TS]; s[0] += v; s[1] += v * v
def mc(T): s = stats[T]; mu = s[0] / NP; return mu, sqrt((s[1] / NP - mu * mu) / NP)

def lnDV(T): B = Bf(0.0, T); return (VB - SIG**2 / (2 * A**2)) * (B - T) - SIG**2 * B * B / (4 * A) - B * VR0
def vas_theta(t, h=1e-3):                             # road 5: theta from Vasicek's own curve
    f = -(lnDV(t + h) - lnDV(t - h)) / (2 * h); fp = -(lnDV(t + h) - 2 * lnDV(t) + lnDV(t - h)) / (h * h)
    return fp + A * f + conv(t)

R2 = road2(FW[0])
print("the slice E curve: pillar, D(T), forward % in the gap ending there")
for i, T in enumerate(PIL[1:]): print(f"  {T:3.1f}  {D[T]:.8f}  {100 * FW[i]:.4f}")
print("theta % a year: gap, at its start, at its end, kick at its end")
for i in range(6):
    kick = f"{100 * (FW[i + 1] - FW[i]):+.4f}" if i < 5 else "  none"
    print(f"  {PIL[i]:3.1f}-{PIL[i + 1]:3.1f}  {100 * (A * FW[i] + conv(PIL[i])):.4f}  {100 * (A * FW[i] + conv(PIL[i + 1])):.4f}  {kick}")
print(f"theta at 2.5 y %: a f {100 * A * f0(2.5):.4f} + convexity {100 * conv(2.5):.4f} = {100 * (A * f0(2.5) + conv(2.5)):.4f}; "
      f"anchor theta/a {100 * (f0(2.5) + conv(2.5) / A):.4f}")
print(f"pieces: half-life {log(2) / A:.2f} y; B(0,5) {Bf(0.0, 5.0):.6f}; V(5) {V(5.0):.6f}; lift(5) % {100 * lift(5.0):.4f}")
il = simpson(lift, 0.0, 5.0)
print("5-year zero, by hand: integral of forward, integral of lift, half variance, price")
print(f"  {-log(D[5.0]):.6f}  {il:.6f}  {0.5 * V(5.0):.6f}  {exp(log(D[5.0]) - il + 0.5 * V(5.0)):.8f}")
print("pillar: market, road 1 closed form, road 2 theta integrated, Vasicek; Vasicek miss $ on 10m")
for T in PIL[1:]:
    dv = exp(lnDV(T))
    print(f"  {T:3.1f}  {D[T]:.8f}  {closed(0.0, T, FW[0]):.8f}  {R2[T]:.8f}  {dv:.8f}  {LOAN * (dv - D[T]):.2f}")
for T in (1.0, 5.0):
    mu, se = mc(T)
    print(f"road 3, {T:.0f} y: E[exp(-int x)] {mu:.8f} se {se:.8f}; exp(V/2) {exp(0.5 * V(T)):.8f}; "
          f"price {exp(-iphi[T]) * mu:.8f}")
mu4, se4 = mc(TS)
print(f"road 4: E[discount to 1.5 y x P(1.5,5)] {mu4:.8f} se {se4:.8f}; market D(5) {D[5.0]:.8f}")
rs = f0(TS) + lift(TS)
print(f"at 1.5 y: expected rate % {100 * rs:.4f}; P(1.5,5) there {closed(TS, 5.0, rs):.6f}; at 6% {closed(TS, 5.0, 0.06):.6f}")
th5 = [vas_theta(t) for t in (1.0, 2.5, 4.0)]
print("road 5, theta from Vasicek's curve at 1, 2.5, 4 y: " + " ".join(f"{v:.8f}" for v in th5) + f"; a*b {A * VB:.8f}")
m5, s5 = f0(5.0) + lift(5.0), sqrt(conv(5.0))
print(f"r(5): mean % {100 * m5:.4f}, sd % {100 * s5:.4f}, chance below zero {ncdf(-m5 / s5):.6f}")
print("what breaks, 5-year price and $ error on 10m:")
for lab, p in (("no convexity term", road2(FW[0], use_conv=False)[5.0]), ("no kicks", road2(FW[0], kicks=False)[5.0]),
               ("start at 4%", road2(VR0)[5.0]), ("plain Vasicek", exp(lnDV(5.0)))):
    print(f"  {lab:<18} {p:.8f}  {LOAN * (p - D[5.0]):.2f}")
tg = [0.25 * k for k in range(21)]
print("chart, years      " + " ".join(f"{t:5.2f}" for t in tg))
print("chart, market f % " + " ".join(f"{100 * f0(t):5.2f}" for t in tg))
print("chart, Vasicek f %" + " ".join(f"{100 * (VR0 * exp(-A * t) + VB * (1 - exp(-A * t)) - lift(t)):5.2f}" for t in tg))

assert all(abs(R2[T] / D[T] - 1.0) < 1e-9 for T in PIL[1:]), "theta integrated must land on every pillar"
for T in (1.0, 5.0):
    mu, se = mc(T); assert abs(mu - exp(0.5 * V(T))) < 4 * se, "spring noise must lift the price by exp(V/2)"
assert abs(mu4 - D[5.0]) < 4 * se4, "discounted bond price must average back to today's price"
assert all(abs(v - A * VB) < 1e-7 for v in th5), "Vasicek's own curve must return its constant anchor"
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
the slice E curve: pillar, D(T), forward % in the gap ending there
  0.5  0.98039216  3.9605
  1.0  0.95969290  4.2679
  2.0  0.91740758  4.5061
  3.0  0.87478903  4.7569
  4.0  0.83431725  4.7369
  5.0  0.79621728  4.6742
theta % a year: gap, at its start, at its end, kick at its end
  0.0-0.5  1.1882  1.1925  +0.3073
  0.5-1.0  1.2847  1.2879  +0.2383
  1.0-2.0  1.3594  1.3635  +0.2508
  2.0-3.0  1.4387  1.4410  -0.0200
  3.0-4.0  1.4350  1.4362  -0.0627
  4.0-5.0  1.4174  1.4181    none
theta at 2.5 y %: a f 1.4271 + convexity 0.0129 = 1.4400; anchor theta/a 4.8001
pieces: half-life 2.31 y; B(0,5) 2.589566; V(5) 0.001561; lift(5) % 0.0335
5-year zero, by hand: integral of forward, integral of lift, half variance, price
  0.227883  0.000780  0.000780  0.79621728
pillar: market, road 1 closed form, road 2 theta integrated, Vasicek; Vasicek miss $ on 10m
  0.5  0.98039216  0.98039216  0.98039216  0.97985070  -5414.59
  1.0  0.95969290  0.95969290  0.95969290  0.95949592  -1969.80
  2.0  0.91740758  0.91740758  0.91740758  0.91862867  12210.86
  3.0  0.87478903  0.87478903  0.87478903  0.87811533  33263.01
  4.0  0.83431725  0.83431725  0.83431725  0.83842471  41074.62
  5.0  0.79621728  0.79621728  0.79621728  0.79985563  36383.48
road 3, 1 y: E[exp(-int x)] 1.00001320 se 0.00000013; exp(V/2) 1.00001339; price 0.95969271
road 3, 5 y: E[exp(-int x)] 1.00078107 se 0.00000781; exp(V/2) 1.00078061; price 0.79621764
road 4: E[discount to 1.5 y x P(1.5,5)] 0.79621618 se 0.00000337; market D(5) 0.79621728
at 1.5 y: expected rate % 4.5134; P(1.5,5) there 0.848232; at 6% 0.821345
road 5, theta from Vasicek's curve at 1, 2.5, 4 y: 0.01500000 0.01500000 0.01500000; a*b 0.01500000
r(5): mean % 4.7077, sd % 1.2584, chance below zero 0.000092
what breaks, 5-year price and $ error on 10m:
  no convexity term  0.79683882  6215.38
  no kicks           0.81007656  138592.78
  start at 4%        0.79540379  -8134.93
  plain Vasicek      0.79985563  36383.48
chart, years       0.00  0.25  0.50  0.75  1.00  1.25  1.50  1.75  2.00  2.25  2.50  2.75  3.00  3.25  3.50  3.75  4.00  4.25  4.50  4.75  5.00
chart, market f %  3.96  3.96  4.27  4.27  4.51  4.51  4.51  4.51  4.76  4.76  4.76  4.76  4.74  4.74  4.74  4.74  4.67  4.67  4.67  4.67  4.67
chart, Vasicek f % 4.00  4.07  4.14  4.20  4.26  4.31  4.36  4.40  4.44  4.48  4.51  4.54  4.57  4.60  4.63  4.65  4.67  4.69  4.71  4.73  4.74
ALL CHECKS PASS
```

### Rust

```rust
// Hull-White check: Vasicek's spring with a moving anchor theta(t), fitted to the slice E
// curve.  Rust std only; nothing used that already knows an answer.  Roads: (1) the A, B
// closed form; (2) theta(t) fed into the mean-rate equation, integrated by RK4, kicks at
// the pillars; (3) Monte Carlo of the spring noise, own random numbers; (4) Monte Carlo
// of a discounted bond price 18 months out; (5) theta read off plain Vasicek's own curve
// by numerical differentiation, which must come out flat at a*b.
use std::f64::consts::PI;

const A: f64 = 0.3; // reversion speed and volatility: the shelf's house pair
const SIG: f64 = 0.01;
const VB: f64 = 0.05; // plain Vasicek: fixed anchor and starting rate
const VR0: f64 = 0.04;
const LOAN: f64 = 10_000_000.0;
const PIL: [f64; 7] = [0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0];

struct Curve { d: [f64; 7], fw: [f64; 6] }
impl Curve {
    fn gap(&self, t: f64) -> usize { PIL[1..].iter().filter(|&&p| t >= p).count().min(5) }
    fn f0(&self, t: f64) -> f64 { self.fw[self.gap(t)] } // forward rate f(0,t), flat in each gap
    fn dt(&self, t: f64) -> f64 { let i = self.gap(t); self.d[i] * (-self.fw[i] * (t - PIL[i])).exp() }
    fn closed(&self, t: f64, tt: f64, r: f64) -> f64 { // road 1: P(t,T) = A(t,T) exp(-B r)
        let b = bf(t, tt);
        self.dt(tt) / self.dt(t) * (b * self.f0(t) - SIG.powi(2) / (4.0 * A) * (1.0 - (-2.0 * A * t).exp()) * b * b - b * r).exp()
    }
    fn road2(&self, r0: f64, use_conv: bool, kicks: bool) -> [f64; 7] { // dm/dt = theta - a m, dI/dt = m
        let (mut m, mut int, mut out) = (r0, 0.0, [1.0; 7]);
        for i in 0..6 {
            let t0 = PIL[i];
            let n = (400.0 * (PIL[i + 1] - PIL[i])) as usize;
            let h = (PIL[i + 1] - t0) / n as f64;
            let th = |t: f64| A * self.fw[i] + if use_conv { conv(t) } else { 0.0 }; // f' = 0 inside a gap
            for k in 0..n {
                let t = t0 + k as f64 * h;
                let k1 = th(t) - A * m; let j1 = m;
                let k2 = th(t + h / 2.0) - A * (m + h / 2.0 * k1); let j2 = m + h / 2.0 * k1;
                let k3 = th(t + h / 2.0) - A * (m + h / 2.0 * k2); let j3 = m + h / 2.0 * k2;
                let k4 = th(t + h) - A * (m + h * k3); let j4 = m + h * k3;
                m += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
                int += h / 6.0 * (j1 + 2.0 * j2 + 2.0 * j3 + j4);
            }
            out[i + 1] = (-int + 0.5 * v(PIL[i + 1])).exp();
            if kicks && i < 5 { m += self.fw[i + 1] - self.fw[i]; } // f' at a pillar: the rate steps
        }
        out
    }
}
fn bf(t: f64, tt: f64) -> f64 { (1.0 - (-A * (tt - t)).exp()) / A }
fn v(tt: f64) -> f64 { SIG.powi(2) / A.powi(2) * (tt - 2.0 * bf(0.0, tt) + (1.0 - (-2.0 * A * tt).exp()) / (2.0 * A)) }
fn lift(t: f64) -> f64 { SIG.powi(2) / (2.0 * A.powi(2)) * (1.0 - (-A * t).exp()).powi(2) } // mean rate minus forward
fn conv(t: f64) -> f64 { SIG.powi(2) / (2.0 * A) * (1.0 - (-2.0 * A * t).exp()) }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * h); }
    h / 3.0 * (g(a) + g(b) + s)
}
fn ncdf(x: f64) -> f64 {
    let sgn = if x > 0.0 { 1.0 } else { -1.0 };
    0.5 + sgn * simpson(&|u: f64| (-u * u / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, x.abs(), 2000)
}
struct Rng(u64); // 64-bit LCG, then Box-Muller
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u1 = self.unif(); let u2 = self.unif(); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }
}
fn ln_dv(tt: f64) -> f64 { let b = bf(0.0, tt); (VB - SIG.powi(2) / (2.0 * A.powi(2))) * (b - tt) - SIG.powi(2) * b * b / (4.0 * A) - b * VR0 }
fn vas_theta(t: f64) -> f64 { // road 5: theta from Vasicek's own curve
    let h = 1e-3;
    let f = -(ln_dv(t + h) - ln_dv(t - h)) / (2.0 * h);
    let fp = -(ln_dv(t + h) - 2.0 * ln_dv(t) + ln_dv(t - h)) / (h * h);
    fp + A * f + conv(t)
}

fn main() {
    let mut d = [1.0f64; 7]; // the bootstrap ladder, as on the slice E card
    d[1] = 1.0 / (1.0 + 0.5 * 0.0400);
    d[2] = 1.0 / (1.0 + 1.0 * 0.0420);
    for (n, s) in [(2usize, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)] {
        let mut b = 0.0;
        for j in 1..n { b += d[j + 1]; }
        d[n + 1] = (1.0 - s * b) / (1.0 + s);
    }
    let mut fw = [0.0f64; 6];
    for i in 0..6 { fw[i] = (d[i] / d[i + 1]).ln() / (PIL[i + 1] - PIL[i]); }
    let c = Curve { d, fw };
    let (np, steps, ts) = (20000usize, 50usize, 1.5);
    let dt = 1.0 / steps as f64;
    let ea = (-A * dt).exp();
    let sd = SIG * ((1.0 - (-2.0 * A * dt).exp()) / (2.0 * A)).sqrt();
    let iphi = |t: f64| -c.dt(t).ln() + simpson(&lift, 0.0, t, 200); // integral of the mean path
    let (ip1, ip5, ips) = (iphi(1.0), iphi(5.0), iphi(ts));
    let mut st = [[0.0f64; 2]; 3]; // 1 y, 5 y, road 4
    let mut rng = Rng(20260928);
    for _ in 0..np {
        let (mut x, mut int) = (0.0f64, 0.0f64);
        for k in 1..=5 * steps {
            let nx = x * ea + sd * rng.gauss(); int += 0.5 * dt * (x + nx); x = nx; // exact spring step
            if k == steps || k == 5 * steps {
                let val = 0.5 * ((-int).exp() + int.exp());
                let s = &mut st[if k == steps { 0 } else { 1 }]; s[0] += val; s[1] += val * val;
            }
            if k == (ts * steps as f64) as usize { // road 4: discount, then price the bond
                let rp = c.f0(ts) + lift(ts);
                let val = 0.5 * ((-ips - int).exp() * c.closed(ts, 5.0, rp + x) + (-ips + int).exp() * c.closed(ts, 5.0, rp - x));
                st[2][0] += val; st[2][1] += val * val;
            }
        }
    }
    let mc = |j: usize| { let mu = st[j][0] / np as f64; (mu, ((st[j][1] / np as f64 - mu * mu) / np as f64).sqrt()) };
    let r2 = c.road2(fw[0], true, true);
    println!("the slice E curve: pillar, D(T), forward % in the gap ending there");
    for i in 0..6 { println!("  {:3.1}  {:.8}  {:.4}", PIL[i + 1], d[i + 1], 100.0 * fw[i]); }
    println!("theta % a year: gap, at its start, at its end, kick at its end");
    for i in 0..6 {
        let kick = if i < 5 { format!("{:+.4}", 100.0 * (fw[i + 1] - fw[i])) } else { "  none".to_string() };
        println!("  {:3.1}-{:3.1}  {:.4}  {:.4}  {}", PIL[i], PIL[i + 1], 100.0 * (A * fw[i] + conv(PIL[i])), 100.0 * (A * fw[i] + conv(PIL[i + 1])), kick);
    }
    println!("theta at 2.5 y %: a f {:.4} + convexity {:.4} = {:.4}; anchor theta/a {:.4}", 100.0 * A * c.f0(2.5), 100.0 * conv(2.5),
             100.0 * (A * c.f0(2.5) + conv(2.5)), 100.0 * (c.f0(2.5) + conv(2.5) / A));
    println!("pieces: half-life {:.2} y; B(0,5) {:.6}; V(5) {:.6}; lift(5) % {:.4}", 2f64.ln() / A, bf(0.0, 5.0), v(5.0), 100.0 * lift(5.0));
    let il = simpson(&lift, 0.0, 5.0, 200);
    println!("5-year zero, by hand: integral of forward, integral of lift, half variance, price");
    println!("  {:.6}  {:.6}  {:.6}  {:.8}", -d[6].ln(), il, 0.5 * v(5.0), (d[6].ln() - il + 0.5 * v(5.0)).exp());
    println!("pillar: market, road 1 closed form, road 2 theta integrated, Vasicek; Vasicek miss $ on 10m");
    for i in 1..7 {
        let dv = ln_dv(PIL[i]).exp();
        println!("  {:3.1}  {:.8}  {:.8}  {:.8}  {:.8}  {:.2}", PIL[i], d[i], c.closed(0.0, PIL[i], fw[0]), r2[i], dv, LOAN * (dv - d[i]));
    }
    for (j, tt, ip) in [(0usize, 1.0, ip1), (1, 5.0, ip5)] {
        let (mu, se) = mc(j);
        println!("road 3, {:.0} y: E[exp(-int x)] {:.8} se {:.8}; exp(V/2) {:.8}; price {:.8}", tt, mu, se, (0.5 * v(tt)).exp(), (-ip).exp() * mu);
    }
    let (mu4, se4) = mc(2);
    println!("road 4: E[discount to 1.5 y x P(1.5,5)] {:.8} se {:.8}; market D(5) {:.8}", mu4, se4, d[6]);
    let rs = c.f0(ts) + lift(ts);
    println!("at 1.5 y: expected rate % {:.4}; P(1.5,5) there {:.6}; at 6% {:.6}", 100.0 * rs, c.closed(ts, 5.0, rs), c.closed(ts, 5.0, 0.06));
    let th5 = [vas_theta(1.0), vas_theta(2.5), vas_theta(4.0)];
    println!("road 5, theta from Vasicek's curve at 1, 2.5, 4 y: {:.8} {:.8} {:.8}; a*b {:.8}", th5[0], th5[1], th5[2], A * VB);
    let (m5, s5) = (c.f0(5.0) + lift(5.0), conv(5.0).sqrt());
    println!("r(5): mean % {:.4}, sd % {:.4}, chance below zero {:.6}", 100.0 * m5, 100.0 * s5, ncdf(-m5 / s5));
    println!("what breaks, 5-year price and $ error on 10m:");
    for (lab, p) in [("no convexity term", c.road2(fw[0], false, true)[6]), ("no kicks", c.road2(fw[0], true, false)[6]),
                     ("start at 4%", c.road2(VR0, true, true)[6]), ("plain Vasicek", ln_dv(5.0).exp())] {
        println!("  {:<18} {:.8}  {:.2}", lab, p, LOAN * (p - d[6]));
    }
    let tg: Vec<f64> = (0..21).map(|k| 0.25 * k as f64).collect();
    let row = |g: &dyn Fn(f64) -> f64| tg.iter().map(|&t| format!("{:5.2}", g(t))).collect::<Vec<_>>().join(" ");
    println!("chart, years      {}", row(&|t| t));
    println!("chart, market f % {}", row(&|t| 100.0 * c.f0(t)));
    println!("chart, Vasicek f %{}", row(&|t| 100.0 * (VR0 * (-A * t).exp() + VB * (1.0 - (-A * t).exp()) - lift(t))));

    assert!((1..7).all(|i| (r2[i] / d[i] - 1.0).abs() < 1e-9), "theta integrated must land on every pillar");
    for (j, tt) in [(0usize, 1.0), (1, 5.0)] {
        let (mu, se) = mc(j); assert!((mu - (0.5 * v(tt)).exp()).abs() < 4.0 * se, "spring noise must lift the price by exp(V/2)");
    }
    assert!((mu4 - d[6]).abs() < 4.0 * se4, "discounted bond price must average back to today's price");
    assert!(th5.iter().all(|&x| (x - A * VB).abs() < 1e-7), "Vasicek's own curve must return its constant anchor");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
the slice E curve: pillar, D(T), forward % in the gap ending there
  0.5  0.98039216  3.9605
  1.0  0.95969290  4.2679
  2.0  0.91740758  4.5061
  3.0  0.87478903  4.7569
  4.0  0.83431725  4.7369
  5.0  0.79621728  4.6742
theta % a year: gap, at its start, at its end, kick at its end
  0.0-0.5  1.1882  1.1925  +0.3073
  0.5-1.0  1.2847  1.2879  +0.2383
  1.0-2.0  1.3594  1.3635  +0.2508
  2.0-3.0  1.4387  1.4410  -0.0200
  3.0-4.0  1.4350  1.4362  -0.0627
  4.0-5.0  1.4174  1.4181    none
theta at 2.5 y %: a f 1.4271 + convexity 0.0129 = 1.4400; anchor theta/a 4.8001
pieces: half-life 2.31 y; B(0,5) 2.589566; V(5) 0.001561; lift(5) % 0.0335
5-year zero, by hand: integral of forward, integral of lift, half variance, price
  0.227883  0.000780  0.000780  0.79621728
pillar: market, road 1 closed form, road 2 theta integrated, Vasicek; Vasicek miss $ on 10m
  0.5  0.98039216  0.98039216  0.98039216  0.97985070  -5414.59
  1.0  0.95969290  0.95969290  0.95969290  0.95949592  -1969.80
  2.0  0.91740758  0.91740758  0.91740758  0.91862867  12210.86
  3.0  0.87478903  0.87478903  0.87478903  0.87811533  33263.01
  4.0  0.83431725  0.83431725  0.83431725  0.83842471  41074.62
  5.0  0.79621728  0.79621728  0.79621728  0.79985563  36383.48
road 3, 1 y: E[exp(-int x)] 1.00001320 se 0.00000013; exp(V/2) 1.00001339; price 0.95969271
road 3, 5 y: E[exp(-int x)] 1.00078107 se 0.00000781; exp(V/2) 1.00078061; price 0.79621764
road 4: E[discount to 1.5 y x P(1.5,5)] 0.79621618 se 0.00000337; market D(5) 0.79621728
at 1.5 y: expected rate % 4.5134; P(1.5,5) there 0.848232; at 6% 0.821345
road 5, theta from Vasicek's curve at 1, 2.5, 4 y: 0.01500000 0.01500000 0.01500000; a*b 0.01500000
r(5): mean % 4.7077, sd % 1.2584, chance below zero 0.000092
what breaks, 5-year price and $ error on 10m:
  no convexity term  0.79683882  6215.38
  no kicks           0.81007656  138592.78
  start at 4%        0.79540379  -8134.93
  plain Vasicek      0.79985563  36383.48
chart, years       0.00  0.25  0.50  0.75  1.00  1.25  1.50  1.75  2.00  2.25  2.50  2.75  3.00  3.25  3.50  3.75  4.00  4.25  4.50  4.75  5.00
chart, market f %  3.96  3.96  4.27  4.27  4.51  4.51  4.51  4.51  4.76  4.76  4.76  4.76  4.74  4.74  4.74  4.74  4.67  4.67  4.67  4.67  4.67
chart, Vasicek f % 4.00  4.07  4.14  4.20  4.26  4.31  4.36  4.40  4.44  4.48  4.51  4.54  4.57  4.60  4.63  4.65  4.67  4.69  4.71  4.73  4.74
ALL CHECKS PASS
```

The two outputs are identical, digit for digit, including the Monte Carlo lines: the same generator, seed and arithmetic order run in both.

### Lean

Lean proves the fit and its uniqueness for any pull speed above zero, any noise, and any forward curve with a continuous slope.

- Suppose the rate starts at $f(0,0)$ and follows the model with the boxed $\theta(t)$. Then every zero-coupon price equals $D(T)$, for every $T \ge 0$.
- Suppose another continuous drift, with the same start and the same noise, also prices every zero-coupon bond at $D(T)$. Then it equals the boxed $\theta(t)$ at every date from today on.
- Take any date $T$. Then the lift, added up from 0 to $T$, comes to exactly $\tfrac12 V(T)$.
- Suppose an expected path $\varphi$ is continuous and meets Step 3's condition at every date. Then $\varphi(t) = f(0,t) + \text{lift}(t)$ for every $t \ge 0$.
- Take the path $f(0,t) + \text{lift}(t)$. Then its slope plus $a$ times the path is the boxed $\theta(t)$, at every date.
- Take $t = 0$, with the rate at $f(0,0)$. Then the closed-form price $P(0,T)$ equals $D(T)$ for every $T$.
- Take any dates $t$ and $T$. Then the variance identity at the end of the detailed proof holds exactly.
- The first two rungs of the ladder are exact: $D(0.5) = 50/51$ and $D(1) = 500/521$.
- At 2.5 years, $\sigma^2/(2a)$ is exactly 1/6000 and $2at$ is exactly 1.5.
- Plain Vasicek's fixed push, 0.3 times 5 percent, is exactly 0.015.
- Take $E = e^{-at}$. Then Step 4's bracket $2E + 1 - E$ is $1 + E$, and $(1 - E)(1 + E) = 1 - E^2$.

The stepped curve with its kicks, the later-date price and every simulated number are left to the Python and Rust checks.

```lean
-- Hull-White: for a pull speed a > 0 and a noise size σ, the drift θ(t) = f'(0,t) + a f(0,t) + σ²/(2a)(1 - e^(-2at)) makes every zero-coupon price equal today's curve, it is the only continuous drift that does, and the closed-form bond price returns the curve at time 0.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Tactic.NormNum
import Mathlib

namespace HullWhiteModel

open MeasureTheory ProbabilityTheory Real
open scoped NNReal

/-! Setting. Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion
under `P` (here the pricing-world weighting of paths): its finite-dimensional laws are those of
a Brownian motion and its paths are continuous almost surely.

Today's forward curve is a function `f : ℝ → ℝ`, `f t` being the forward rate `f(0,t)` for the
instant at `t`; today's price of a dollar due at `T` is `D(T) = e^(-∫₀ᵀ f)`.

Mathlib has no Ito integral. The Hull-White noise is added, not multiplied, so the equation
`dr = (θ(t) - a r) dt + σ dW` is written path by path:
`r_t = r₀ + ∫₀ᵗ (θ(u) - a r_u) du + σ W_t`, with continuous paths. -/

/-- Today's discount factor `D(T) = e^(-∫₀ᵀ f(0,s) ds)` built from the forward curve `f`. -/
noncomputable def discount (f : ℝ → ℝ) (T : ℝ) : ℝ := exp (-∫ s in (0 : ℝ)..T, f s)

/-- The Hull-White drift `θ(t) = f'(0,t) + a f(0,t) + σ²/(2a) (1 - e^(-2at))`: the card's boxed
formula. -/
noncomputable def hwTheta (a σ : ℝ) (f : ℝ → ℝ) (t : ℝ) : ℝ :=
  deriv f t + a * f t + σ ^ 2 / (2 * a) * (1 - exp (-2 * a * t))

/-- `B(t,T) = (1 - e^(-a(T-t)))/a`: the bond's exposure to the rate. -/
noncomputable def hwB (a t T : ℝ) : ℝ := (1 - exp (-a * (T - t))) / a

/-- `V(T) = σ²/a² (T - 2B(0,T) + (1 - e^(-2aT))/(2a))`: the variance of the total rate paid
from today to `T`. -/
noncomputable def hwV (a σ T : ℝ) : ℝ :=
  σ ^ 2 / a ^ 2 * (T - 2 * hwB a 0 T + (1 - exp (-2 * a * T)) / (2 * a))

/-- `lift(t) = σ²/(2a²) (1 - e^(-at))²`: how far the expected rate sits above the forward curve. -/
noncomputable def hwLift (a σ t : ℝ) : ℝ := σ ^ 2 / (2 * a ^ 2) * (1 - exp (-a * t)) ^ 2

/-- The closed-form bond price at a later date `t`, with the short rate at `r`:
`P(t,T) = D(T)/D(t) · exp(B f(0,t) - σ²/(4a) (1 - e^(-2at)) B² - B r)`, `B = B(t,T)`. -/
noncomputable def hwPrice (a σ : ℝ) (f : ℝ → ℝ) (t T r : ℝ) : ℝ :=
  discount f T / discount f t *
    exp (hwB a t T * f t - σ ^ 2 / (4 * a) * (1 - exp (-2 * a * t)) * hwB a t T ^ 2
      - hwB a t T * r)

section HullWhiteHelpers

open Filter Topology

/-- A continuous function whose integrals from `0` vanish on `[0, ∞)` vanishes there. -/
theorem hw_eq_zero_of_integral_eq_zero {h : ℝ → ℝ} (hh : Continuous h)
    (H : ∀ T : ℝ, 0 ≤ T → ∫ u in (0 : ℝ)..T, h u = 0) : ∀ t : ℝ, 0 ≤ t → h t = 0 := by
  intro t ht
  have h1 : HasDerivWithinAt (fun T => ∫ u in (0 : ℝ)..T, h u) (h t) (Set.Ici t) t :=
    intervalIntegral.integral_hasDerivWithinAt_right (hh.intervalIntegrable _ _)
      (hh.stronglyMeasurableAtFilter _ _) hh.continuousWithinAt
  have h2 : HasDerivWithinAt (fun T => ∫ u in (0 : ℝ)..T, h u) 0 (Set.Ici t) t := by
    apply (hasDerivWithinAt_const t (Set.Ici t) (0 : ℝ)).congr
    · intro y hy; exact H y (le_trans ht hy)
    · exact H t ht
  exact (uniqueDiffOn_Ici t t (by simp)).eq_deriv _ h1 h2

theorem hw_lift_hasDerivAt (a σ : ℝ) (ha : a ≠ 0) (x : ℝ) :
    HasDerivAt (fun t => σ ^ 2 / (2 * a ^ 2) * (t + 2 / a * exp (-a * t)
      - 1 / (2 * a) * exp (-2 * a * t))) (hwLift a σ x) x := by
  have e1 := ((hasDerivAt_id' x).const_mul (-a)).exp
  have e2 := ((hasDerivAt_id' x).const_mul (-2 * a)).exp
  have := (((hasDerivAt_id' x).fun_add (e1.const_mul (2 / a))).fun_sub
    (e2.const_mul (1 / (2 * a)))).const_mul (σ ^ 2 / (2 * a ^ 2))
  convert this using 1
  simp only [hwLift]
  have : exp (-2 * a * x) = exp (-a * x) ^ 2 := by
    rw [← Real.exp_nat_mul]; congr 1; push_cast; ring
  rw [this]
  field_simp
  ring

theorem hw_lift_deriv (a σ : ℝ) (ha : a ≠ 0) (x : ℝ) :
    HasDerivAt (hwLift a σ) (σ ^ 2 / a * (1 - exp (-a * x)) * exp (-a * x)) x := by
  have e1 := ((hasDerivAt_id' x).const_mul (-a)).exp
  have := ((e1.const_sub 1).fun_pow 2).const_mul (σ ^ 2 / (2 * a ^ 2))
  convert this using 1
  · rfl
  · push_cast
    field_simp

theorem hw_ode {a : ℝ} {ρ h : ℝ → ℝ} (hρ : Continuous ρ) (hh : Continuous h)
    (H : ∀ t : ℝ, 0 ≤ t → ρ t = h t - a * ∫ u in (0 : ℝ)..t, ρ u) (T : ℝ) (hT : 0 ≤ T) :
    ∫ u in (0 : ℝ)..T, ρ u = ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * h u := by
  set D : ℝ → ℝ := fun t => exp (a * t) * (∫ u in (0 : ℝ)..t, ρ u)
    - ∫ u in (0 : ℝ)..t, exp (a * u) * h u with hDdef
  have hcE : Continuous fun u => exp (a * u) * h u := by fun_prop
  have hderiv : ∀ x, HasDerivAt D (exp (a * x) * (a * (∫ u in (0 : ℝ)..x, ρ u) + ρ x - h x)) x := by
    intro x
    have e := ((hasDerivAt_id' x).const_mul a).exp
    have i1 := (hρ.integral_hasStrictDerivAt 0 x).hasDerivAt
    have i2 := (hcE.integral_hasStrictDerivAt 0 x).hasDerivAt
    convert (e.fun_mul i1).fun_sub i2 using 1
    ring
  have hDc : Continuous D := continuous_iff_continuousAt.2 fun x => (hderiv x).continuousAt
  have hconst := constant_of_has_deriv_right_zero (a := 0) (b := T) hDc.continuousOn
    (fun x hx => by
      have := (hderiv x).hasDerivWithinAt (s := Set.Ici x)
      rw [H x hx.1] at this
      convert this using 1
      ring)
  have h1 := hconst T ⟨hT, le_rfl⟩
  simp only [hDdef, intervalIntegral.integral_same, mul_zero, sub_zero] at h1
  have h2 : ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * h u
      = exp (-a * T) * ∫ u in (0 : ℝ)..T, exp (a * u) * h u := by
    rw [← intervalIntegral.integral_const_mul]
    congr 1
    funext u
    rw [← mul_assoc, ← Real.exp_add]
    ring_nf
  rw [h2, ← sub_eq_zero.1 h1, ← mul_assoc, ← Real.exp_add]
  simp

/-- The grid point `k T / n`. -/
noncomputable def hwGrid (T : ℝ) (n k : ℕ) : ℝ := k * T / n

theorem hw_riemann {F ψ : ℝ → ℝ} (hF : Continuous F) (hψ : Continuous ψ) {T : ℝ} (hT : 0 ≤ T)
    (p : ℕ → ℕ → ℝ) (hp : ∀ n k, k < n → p n k ∈ Set.Icc (hwGrid T n k) (hwGrid T n (k + 1))) :
    Tendsto (fun n : ℕ => ∑ k ∈ Finset.range n,
        (∫ u in (hwGrid T n k)..(hwGrid T n (k + 1)), ψ u) * F (p n k))
      atTop (𝓝 (∫ u in (0 : ℝ)..T, ψ u * F u)) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨C, hC⟩ := isCompact_Icc.exists_bound_of_continuousOn (hψ.continuousOn (s := Set.Icc 0 T))
  set M := max C 0 + 1 with hM
  have hMpos : 0 < M := by positivity
  have huc := isCompact_Icc.uniformContinuousOn_of_continuous (hF.continuousOn (s := Set.Icc 0 T))
  rw [Metric.uniformContinuousOn_iff] at huc
  obtain ⟨δ, hδ, hδ'⟩ := huc (ε / (2 * M * (T + 1))) (by positivity)
  obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
  refine ⟨N + 1, fun n hn => ?_⟩
  have hn0 : (0 : ℝ) < n := by
    have : (1 : ℕ) ≤ n := by omega
    exact_mod_cast this
  have hNn : (N : ℝ) < n := by exact_mod_cast (show N < n by omega)
  have hmesh : T / n < δ := by
    rw [div_lt_iff₀ hn0]
    rw [div_lt_iff₀ hδ] at hN
    nlinarith
  set a := hwGrid T n with ha
  have hstep : ∀ k, a (k + 1) - a k = T / n := by
    intro k; simp only [ha, hwGrid]; push_cast; ring
  have hmono : ∀ k, a k ≤ a (k + 1) := by
    intro k; have := hstep k; have : 0 ≤ T / n := by positivity
    linarith
  have hlo : ∀ k, 0 ≤ a k := by intro k; simp only [ha, hwGrid]; positivity
  have hhi : ∀ k, k ≤ n → a k ≤ T := by
    intro k hk; simp only [ha, hwGrid]
    rw [div_le_iff₀ hn0]
    have : (k : ℝ) ≤ n := by exact_mod_cast hk
    nlinarith
  have hsplit : ∑ k ∈ Finset.range n, ∫ u in (a k)..(a (k + 1)), ψ u * F u
      = ∫ u in (0 : ℝ)..T, ψ u * F u := by
    rw [intervalIntegral.sum_integral_adjacent_intervals]
    · congr 1
      · simp [ha, hwGrid]
      · simp only [ha, hwGrid]; field_simp
    · intro k _; exact (hψ.mul hF).intervalIntegrable _ _
  have hterm : ∀ k, (∫ u in (a k)..(a (k + 1)), ψ u) * F (p n k) - ∫ u in (a k)..(a (k + 1)), ψ u * F u
      = ∫ u in (a k)..(a (k + 1)), ψ u * (F (p n k) - F u) := by
    intro k
    simp_rw [mul_sub]
    rw [intervalIntegral.integral_sub, intervalIntegral.integral_mul_const]
    · exact (hψ.mul continuous_const).intervalIntegrable _ _
    · exact (hψ.mul hF).intervalIntegrable _ _
  have hbound : ∀ k ∈ Finset.range n,
      ‖∫ u in (a k)..(a (k + 1)), ψ u * (F (p n k) - F u)‖ ≤ M * (ε / (2 * M * (T + 1))) * (T / n) := by
    intro k hk
    rw [Finset.mem_range] at hk
    rw [← hstep k, ← abs_of_nonneg (sub_nonneg.2 (hmono k))]
    apply intervalIntegral.norm_integral_le_of_norm_le_const
    intro u hu
    rw [Set.uIoc_of_le (hmono k)] at hu
    have hu0 : u ∈ Set.Icc 0 T := ⟨le_trans (hlo k) hu.1.le, le_trans hu.2 (hhi (k + 1) hk)⟩
    have hpk := hp n k hk
    have hp0 : p n k ∈ Set.Icc 0 T := ⟨le_trans (hlo k) hpk.1, le_trans hpk.2 (hhi (k + 1) hk)⟩
    have hd : dist (p n k) u < δ := by
      rw [Real.dist_eq, abs_lt]
      have := hstep k
      constructor <;> linarith [hu.1, hu.2, hpk.1, hpk.2]
    have h1 := hδ' _ hp0 _ hu0 hd
    rw [Real.dist_eq] at h1
    rw [norm_mul, Real.norm_eq_abs (F (p n k) - F u)]
    have h2 : ‖ψ u‖ ≤ M := le_trans (hC u hu0) (by rw [hM]; linarith [le_max_left C 0])
    exact mul_le_mul h2 h1.le (abs_nonneg _) hMpos.le
  rw [dist_eq_norm, ← hsplit, ← Finset.sum_sub_distrib]
  simp_rw [hterm]
  refine lt_of_le_of_lt (le_trans (norm_sum_le _ _) (Finset.sum_le_sum hbound)) ?_
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  have : (n : ℝ) * (M * (ε / (2 * M * (T + 1))) * (T / n)) = ε * (T / (2 * (T + 1))) := by
    field_simp
  rw [this]
  have : T / (2 * (T + 1)) < 1 := by rw [div_lt_one (by positivity)]; linarith
  nlinarith

theorem hw_abel (G V : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ Finset.range n, G (k + 1) * (V (k + 1) - V k)
      = G n * V n - G 0 * V 0 + ∑ k ∈ Finset.range n, (G k - G (k + 1)) * V k := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, ih, Finset.sum_range_succ]; ring

theorem hw_gauss {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsBrownianReal W P) {g G : ℝ → ℝ} (hg : Continuous g) (hG : Continuous G)
    {T : ℝ} (hT : 0 ≤ T) (hGint : ∀ s, G s = ∫ u in s..T, g u) :
    HasLaw (fun ω => ∫ u in (0 : ℝ)..T, g u * W u.toNNReal ω)
      (gaussianReal 0 (NNReal.mk (∫ s in (0 : ℝ)..T, G s ^ 2)
        (intervalIntegral.integral_nonneg hT (fun _ _ => sq_nonneg _)))) P := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  set v : ℝ≥0 := NNReal.mk (∫ s in (0 : ℝ)..T, G s ^ 2)
    (intervalIntegral.integral_nonneg hT (fun _ _ => sq_nonneg _)) with hvdef
  set X : Ω → ℝ := fun ω => ∫ u in (0 : ℝ)..T, g u * W u.toNNReal ω with hXdef
  -- the grid and the discrete sums
  set t : ℕ → ℕ → ℝ≥0 := fun n k => (hwGrid T n k).toNNReal with htdef
  have hgrid0 : ∀ n k, 0 ≤ hwGrid T n k := fun n k => by unfold hwGrid; positivity
  have htcoe : ∀ n k, ((t n k : ℝ≥0) : ℝ) = hwGrid T n k := fun n k =>
    Real.coe_toNNReal _ (hgrid0 n k)
  have hgridmono : ∀ n, Monotone (hwGrid T n) := by
    intro n i j hij
    unfold hwGrid
    have : (i : ℝ) ≤ j := by exact_mod_cast hij
    have : (0 : ℝ) ≤ n := by positivity
    gcongr
  have hstep : ∀ n k, hwGrid T n k ≤ hwGrid T n (k + 1) := fun n k => hgridmono n (by omega)
  set Z : ℕ → ℕ → Ω → ℝ := fun n k ω =>
    G (hwGrid T n (k + 1)) * (W (t n (k + 1)) ω - W (t n k) ω) with hZdef
  set S : ℕ → Ω → ℝ := fun n => ∑ k ∈ Finset.range n, Z n k with hSdef
  set w : ℕ → ℕ → ℝ≥0 := fun n k =>
    NNReal.mk (G (hwGrid T n (k + 1)) ^ 2) (sq_nonneg _) * nndist (t n (k + 1)).1 (t n k).1 with hwdef
  set vn : ℕ → ℝ≥0 := fun n => ∑ k ∈ Finset.range n, w n k with hvndef
  have hmeasW : ∀ s, AEMeasurable (W s) P := fun s => hW.aemeasurable s
  have hZmeas : ∀ n k, AEMeasurable (Z n k) P := by
    intro n k
    exact ((hmeasW _).sub (hmeasW _)).const_mul _
  have hSmeas : ∀ n, AEMeasurable (S n) P := by
    intro n
    exact Finset.aemeasurable_sum _ (fun k _ => hZmeas n k)
  -- the law of each discrete sum
  have hZlaw : ∀ n k, HasLaw (Z n k) (gaussianReal 0 (w n k)) P := by
    intro n k
    have := gaussianReal_const_mul (hW.hasLaw_sub (t n (k + 1)) (t n k)) (G (hwGrid T n (k + 1)))
    rw [mul_zero] at this
    exact this
  have hindep : ∀ n, iIndepFun (Z n) P := by
    intro n
    have hm : Monotone (t n) := fun i j hij => Real.toNNReal_le_toNNReal (hgridmono n hij)
    exact (hW.hasIndepIncrements.nat hm).comp (fun k x => G (hwGrid T n (k + 1)) * x)
      (fun k => measurable_const.mul measurable_id)
  have hSlaw : ∀ n, HasLaw (S n) (gaussianReal 0 (vn n)) P := by
    intro n
    have : ∀ m, HasLaw (∑ k ∈ Finset.range m, Z n k)
        (gaussianReal 0 (∑ k ∈ Finset.range m, w n k)) P := by
      intro m
      induction m with
      | zero =>
        refine ⟨by simp; fun_prop, ?_⟩
        simp only [Finset.range_zero, Finset.sum_empty, gaussianReal_zero_var]
        show P.map (fun _ => (0 : ℝ)) = _
        rw [Measure.map_const, measure_univ, one_smul]
      | succ m ih =>
        rw [Finset.sum_range_succ, Finset.sum_range_succ]
        refine ⟨ih.aemeasurable.add (hZmeas n m), ?_⟩
        rw [gaussianReal_add_gaussianReal_of_indepFun
          ((hindep n).indepFun_sum_range_succ₀ (hZmeas n) m) ih (hZlaw n m), add_zero]
    exact this n
  -- convergence of the variances
  have hvn : ∀ n, ((vn n : ℝ≥0) : ℝ) = ∑ k ∈ Finset.range n,
      (∫ _ in (hwGrid T n k)..(hwGrid T n (k + 1)), (1 : ℝ)) * (fun s => G s ^ 2)
        (hwGrid T n (k + 1)) := by
    intro n
    simp only [hvndef, hwdef, NNReal.coe_sum, NNReal.coe_mul, NNReal.coe_mk, coe_nndist,
      intervalIntegral.integral_const, smul_eq_mul, mul_one, Real.dist_eq]
    refine Finset.sum_congr rfl fun k _ => ?_
    have e1 : ((t n (k + 1)).1 : ℝ) = hwGrid T n (k + 1) := htcoe _ _
    have e2 : ((t n k).1 : ℝ) = hwGrid T n k := htcoe _ _
    simp only [e1, e2]
    rw [abs_of_nonneg (sub_nonneg.2 (hstep n k))]
    ring
  have hvlim : Tendsto (fun n => vn n) atTop (𝓝 v) := by
    have := hw_riemann (F := fun s => G s ^ 2) (ψ := fun _ => (1 : ℝ)) (hG.pow 2)
      continuous_const hT (fun n k => hwGrid T n (k + 1))
      (fun n k _ => ⟨hstep n k, le_rfl⟩)
    have hv' : ((v : ℝ≥0) : ℝ)
        = ∫ u in (0 : ℝ)..T, (fun _ => (1 : ℝ)) u * (fun s => G s ^ 2) u := by
      simp [hvdef]
    rw [← NNReal.tendsto_coe]
    refine Tendsto.congr (fun n => (hvn n).symm) ?_
    rw [hv']
    exact this
  -- almost sure convergence of the discrete sums
  have hSlim : ∀ᵐ ω ∂P, Tendsto (fun n => S n ω) atTop (𝓝 (X ω)) := by
    filter_upwards [hW.cont, hW.eval_zero_ae_eq_zero] with ω hc h0
    have hwc : Continuous fun u : ℝ => W u.toNNReal ω := hc.comp continuous_real_toNNReal
    have hR := hw_riemann (F := fun u : ℝ => W u.toNNReal ω) (ψ := g) hwc hg hT
      (fun n k => hwGrid T n k) (fun n k _ => ⟨le_rfl, hstep n k⟩)
    refine hR.congr' ?_
    rw [EventuallyEq, eventually_atTop]
    refine ⟨1, fun n hn => ?_⟩
    have hab := hw_abel (fun k => G (hwGrid T n k)) (fun k => W (t n k) ω) n
    simp only [hSdef, hZdef, Finset.sum_apply]
    rw [hab]
    have hn : (n : ℝ) ≠ 0 := by have : (1 : ℝ) ≤ n := by exact_mod_cast hn
                                linarith
    have hGn : G (hwGrid T n n) = 0 := by
      rw [hGint]
      have : hwGrid T n n = T := by unfold hwGrid; field_simp
      rw [this, intervalIntegral.integral_same]
    have ht0 : t n 0 = 0 := by simp [htdef, hwGrid]
    rw [hGn, ht0, h0, zero_mul, mul_zero, sub_zero, zero_add]
    refine Finset.sum_congr rfl fun k _ => ?_
    have hadd := intervalIntegral.integral_add_adjacent_intervals
      (hg.intervalIntegrable (μ := volume) (hwGrid T n k) (hwGrid T n (k + 1)))
      (hg.intervalIntegrable (μ := volume) (hwGrid T n (k + 1)) T)
    rw [hGint, hGint, ← hadd]
    simp [htdef]
  have hXmeas : AEMeasurable X P := aemeasurable_of_tendsto_metrizable_ae' hSmeas hSlim
  -- characteristic functions
  refine ⟨hXmeas, ?_⟩
  apply Measure.ext_of_charFun
  funext τ
  have hcf : ∀ (Y : Ω → ℝ), AEMeasurable Y P →
      charFun (P.map Y) τ = ∫ ω, Complex.exp (τ * Y ω * Complex.I) ∂P := by
    intro Y hY
    rw [charFun_apply_real, integral_map hY]
    exact (by fun_prop : Continuous fun x : ℝ => Complex.exp (τ * x * Complex.I)).aestronglyMeasurable
  have hlim1 : Tendsto (fun n => charFun (P.map (S n)) τ) atTop (𝓝 (charFun (P.map X) τ)) := by
    simp_rw [hcf _ (hSmeas _), hcf _ hXmeas]
    refine tendsto_integral_of_dominated_convergence (fun _ => 1) (fun n => ?_)
      (integrable_const _) (fun n => Eventually.of_forall fun ω => ?_) ?_
    · exact ((by fun_prop : Continuous fun x : ℝ => Complex.exp (τ * x * Complex.I)).measurable.comp_aemeasurable
        (hSmeas n)).aestronglyMeasurable
    · rw [← Complex.ofReal_mul, Complex.norm_exp_ofReal_mul_I]
    · filter_upwards [hSlim] with ω hω
      exact ((by fun_prop : Continuous fun x : ℝ => Complex.exp (τ * x * Complex.I)).tendsto _).comp hω
  have hlim2 : Tendsto (fun n => charFun (P.map (S n)) τ) atTop
      (𝓝 (charFun (gaussianReal 0 v) τ)) := by
    simp_rw [fun n => (hSlaw n).map_eq, charFun_gaussianReal]
    exact ((by fun_prop : Continuous fun x : ℝ≥0 =>
      Complex.exp (τ * ((0 : ℝ) : ℂ) * Complex.I - ((x : ℝ) : ℂ) * τ ^ 2 / 2)).tendsto v).comp hvlim
  exact tendsto_nhds_unique hlim1 hlim2

theorem hw_B_eq_integral {a : ℝ} (ha : a ≠ 0) (T s : ℝ) :
    hwB a s T = ∫ u in s..T, exp (-a * (T - u)) := by
  have hd : ∀ x, HasDerivAt (fun u => exp (-a * (T - u)) / a) (exp (-a * (T - x))) x := by
    intro x
    have e := ((((hasDerivAt_id' x).const_sub T).const_mul (-a)).exp).div_const a
    convert e using 1
    field_simp
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x)
    ((by fun_prop : Continuous fun u => exp (-a * (T - u))).intervalIntegrable _ _)]
  simp only [hwB, sub_self, mul_zero, exp_zero]
  ring

theorem hw_V_eq_integral {a : ℝ} (ha : a ≠ 0) (σ T : ℝ) :
    hwV a σ T = σ ^ 2 * ∫ s in (0 : ℝ)..T, hwB a s T ^ 2 := by
  have hd : ∀ x, HasDerivAt (fun s => (s - 2 / a * exp (-a * (T - s))
      + 1 / (2 * a) * exp (-2 * a * (T - s))) / a ^ 2) (hwB a x T ^ 2) x := by
    intro x
    have e1 := (((hasDerivAt_id' x).const_sub T).const_mul (-a)).exp
    have e2 := (((hasDerivAt_id' x).const_sub T).const_mul (-2 * a)).exp
    have := (((hasDerivAt_id' x).fun_sub (e1.const_mul (2 / a))).fun_add
      (e2.const_mul (1 / (2 * a)))).div_const (a ^ 2)
    convert this using 1
    simp only [hwB]
    have h2 : exp (-2 * a * (T - x)) = exp (-a * (T - x)) ^ 2 := by
      rw [← Real.exp_nat_mul]; congr 1; push_cast; ring
    rw [h2]
    field_simp
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x)
    ((by unfold hwB; fun_prop : Continuous fun s => hwB a s T ^ 2).intervalIntegrable _ _)]
  simp only [hwV, hwB, sub_self, sub_zero, mul_zero, exp_zero]
  field_simp
  ring

theorem hw_exp_factor (a T : ℝ) (k : ℝ → ℝ) :
    ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * k u
      = exp (-a * T) * ∫ u in (0 : ℝ)..T, exp (a * u) * k u := by
  rw [← intervalIntegral.integral_const_mul]
  congr 1
  funext u
  rw [← mul_assoc, ← Real.exp_add]
  ring_nf

theorem hw_primitive_continuous {θ : ℝ → ℝ} (hθ : Continuous θ) :
    Continuous fun u => ∫ x in (0 : ℝ)..u, θ x :=
  continuous_iff_continuousAt.2 fun u => (hθ.integral_hasStrictDerivAt 0 u).hasDerivAt.continuousAt

theorem hw_conv_eq {a f0 : ℝ} {θ₁ θ₂ : ℝ → ℝ} (h₁ : Continuous θ₁) (h₂ : Continuous θ₂)
    (H : ∀ T : ℝ, 0 ≤ T →
      ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ₁ x)
        = ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ₂ x)) :
    ∀ t : ℝ, 0 ≤ t → θ₁ t = θ₂ t := by
  intro t ht
  have hI1 := hw_primitive_continuous h₁
  have hI2 := hw_primitive_continuous h₂
  have step1 : ∀ T : ℝ, 0 ≤ T → ∫ u in (0 : ℝ)..T,
      exp (a * u) * ((∫ x in (0 : ℝ)..u, θ₁ x) - ∫ x in (0 : ℝ)..u, θ₂ x) = 0 := by
    intro T hT
    have h := H T hT
    rw [hw_exp_factor, hw_exp_factor] at h
    have h' := mul_left_cancel₀ (exp_ne_zero _) h
    rw [← sub_eq_zero, ← intervalIntegral.integral_sub] at h'
    · refine Eq.trans ?_ h'
      congr 1
      funext u
      ring
    · exact ((by fun_prop : Continuous fun u : ℝ => exp (a * u)).mul
        (continuous_const.add hI1)).intervalIntegrable _ _
    · exact ((by fun_prop : Continuous fun u : ℝ => exp (a * u)).mul
        (continuous_const.add hI2)).intervalIntegrable _ _
  have step2 := hw_eq_zero_of_integral_eq_zero
    ((by fun_prop : Continuous fun u : ℝ => exp (a * u)).mul (hI1.sub hI2)) step1
  have step3 : ∀ T : ℝ, 0 ≤ T → ∫ x in (0 : ℝ)..T, (θ₁ x - θ₂ x) = 0 := by
    intro T hT
    rw [intervalIntegral.integral_sub (h₁.intervalIntegrable _ _) (h₂.intervalIntegrable _ _)]
    rcases mul_eq_zero.1 (step2 T hT) with h | h
    · exact absurd h (exp_ne_zero _)
    · exact h
  have := hw_eq_zero_of_integral_eq_zero (h := fun x => θ₁ x - θ₂ x) (h₁.sub h₂) step3 t ht
  linarith

theorem hw_mean_path_and_drift {a σ : ℝ} (ha : 0 < a) {f : ℝ → ℝ}
    (hf : Differentiable ℝ f) :
    (∀ T : ℝ, ∫ t in (0 : ℝ)..T, hwLift a σ t = hwV a σ T / 2) ∧
    (∀ φ : ℝ → ℝ, Continuous φ →
      (∀ T : ℝ, 0 ≤ T → ∫ t in (0 : ℝ)..T, φ t = (∫ t in (0 : ℝ)..T, f t) + hwV a σ T / 2) →
      ∀ t : ℝ, 0 ≤ t → φ t = f t + hwLift a σ t) ∧
    (∀ t : ℝ, deriv (fun s => f s + hwLift a σ s) t + a * (f t + hwLift a σ t)
      = hwTheta a σ f t) := by
  have ha' : a ≠ 0 := ha.ne'
  have hint : ∀ T : ℝ, ∫ t in (0 : ℝ)..T, hwLift a σ t = hwV a σ T / 2 := by
    intro T
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hw_lift_hasDerivAt a σ ha' x)]
    · simp only [hwV, hwB]
      have h0 : exp (-a * 0) = 1 := by simp
      have h0' : exp (-2 * a * 0) = 1 := by simp
      rw [h0, h0', sub_zero]
      field_simp
      ring
    · exact (by unfold hwLift; fun_prop : Continuous (hwLift a σ)).intervalIntegrable _ _
  have hcont : Continuous (hwLift a σ) := by unfold hwLift; fun_prop
  refine ⟨hint, ?_, ?_⟩
  · intro φ hφ H t ht
    have key := hw_eq_zero_of_integral_eq_zero (h := fun u => φ u - (f u + hwLift a σ u))
      (hφ.sub (hf.continuous.add hcont)) ?_ t ht
    · linarith
    intro T hT
    rw [intervalIntegral.integral_sub (f := φ) (g := fun u => f u + hwLift a σ u)
      (hφ.intervalIntegrable _ _)
      ((hf.continuous.add hcont : Continuous fun u => f u + hwLift a σ u).intervalIntegrable _ _),
      intervalIntegral.integral_add (hf.continuous.intervalIntegrable _ _)
      (hcont.intervalIntegrable _ _), H T hT, hint]
    ring
  · intro t
    rw [((hf t).hasDerivAt.fun_add (hw_lift_deriv a σ ha' t)).deriv]
    simp only [hwTheta, hwLift]
    have : exp (-2 * a * t) = exp (-a * t) ^ 2 := by
      rw [← Real.exp_nat_mul]; congr 1; push_cast; ring
    rw [this]
    field_simp
    ring

theorem hw_price {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsBrownianReal W P) {a σ : ℝ} (ha : 0 < a) {f0 : ℝ} {θ : ℝ → ℝ} (hθ : Continuous θ)
    (r : ℝ → Ω → ℝ)
    (hr : ∀ᵐ ω ∂P, ContinuousOn (fun s => r s ω) (Set.Ici 0) ∧
      ∀ t : ℝ≥0, r t ω = f0 + (∫ u in (0 : ℝ)..t, (θ u - a * r u ω)) + σ * W t ω)
    (T : ℝ) (hT : 0 ≤ T) :
    ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P
      = exp (-(∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ x))
        + hwV a σ T / 2) := by
  have ha' : a ≠ 0 := ha.ne'
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  have hΘ := hw_primitive_continuous hθ
  have hgauss := hw_gauss hW (g := fun u => exp (-a * (T - u))) (G := fun s => hwB a s T)
    (by fun_prop) (by unfold hwB; fun_prop) hT (fun s => hw_B_eq_integral ha' T s)
  set X : Ω → ℝ := fun ω => ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * W u.toNNReal ω with hXdef
  set m : ℝ := ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ x) with hmdef
  have hpath : ∀ᵐ ω ∂P, ∫ u in (0 : ℝ)..T, r u ω = m + σ * X ω := by
    filter_upwards [hr, hW.cont] with ω hω hc
    obtain ⟨hrc, hreq⟩ := hω
    set ρ : ℝ → ℝ := fun t => r (max t 0) ω with hρdef
    have hρc : Continuous ρ :=
      hrc.comp_continuous (continuous_id.max continuous_const) (fun t => le_max_right t 0)
    have hρeq : ∀ t : ℝ, 0 ≤ t → ∫ u in (0 : ℝ)..t, r u ω = ∫ u in (0 : ℝ)..t, ρ u := by
      intro t ht
      refine intervalIntegral.integral_congr (fun u hu => ?_)
      rw [Set.uIcc_of_le ht] at hu
      simp only [hρdef, max_eq_left hu.1]
    have hwc : Continuous fun u : ℝ => W u.toNNReal ω := hc.comp continuous_real_toNNReal
    set h : ℝ → ℝ := fun t => (f0 + ∫ x in (0 : ℝ)..t, θ x) + σ * W t.toNNReal ω with hhdef
    have hh : Continuous h := (continuous_const.add hΘ).add (continuous_const.mul hwc)
    have H : ∀ t : ℝ, 0 ≤ t → ρ t = h t - a * ∫ u in (0 : ℝ)..t, ρ u := by
      intro t ht
      have e := hreq t.toNNReal
      rw [Real.coe_toNNReal t ht] at e
      have hri : IntervalIntegrable (fun u => r u ω) volume 0 t := by
        apply ContinuousOn.intervalIntegrable
        rw [Set.uIcc_of_le ht]
        exact hrc.mono Set.Icc_subset_Ici_self
      rw [intervalIntegral.integral_sub (hθ.intervalIntegrable _ _) (hri.const_mul a),
        intervalIntegral.integral_const_mul, hρeq t ht] at e
      simp only [hρdef, hhdef, max_eq_left ht]
      rw [e]
      ring
    have hode := hw_ode hρc hh H T hT
    rw [hρeq T hT, hode, hmdef, hXdef]
    simp only [hhdef]
    rw [← intervalIntegral.integral_const_mul, ← intervalIntegral.integral_add]
    · congr 1
      funext u
      ring
    · exact ((by fun_prop : Continuous fun u : ℝ => exp (-a * (T - u))).mul
        (continuous_const.add hΘ)).intervalIntegrable _ _
    · exact (continuous_const.mul ((by fun_prop : Continuous fun u : ℝ => exp (-a * (T - u))).mul
        hwc)).intervalIntegrable _ _
  calc ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P
      = ∫ ω, exp (-m) * exp ((-σ) * X ω) ∂P := by
        refine integral_congr_ae (hpath.mono fun ω hω => ?_)
        simp only
        rw [hω, ← Real.exp_add]
        congr 1
        ring
    _ = exp (-m) * mgf X P (-σ) := by
        rw [integral_const_mul]
        rfl
    _ = exp (-m + hwV a σ T / 2) := by
        rw [mgf_gaussianReal hgauss, ← Real.exp_add, hw_V_eq_integral ha' σ T]
        congr 1
        simp only [NNReal.coe_mk]
        ring

#print axioms hw_eq_zero_of_integral_eq_zero
#print axioms hw_lift_hasDerivAt
#print axioms hw_lift_deriv
#print axioms hw_ode
#print axioms hw_riemann
#print axioms hw_abel
#print axioms hw_gauss
#print axioms hw_B_eq_integral
#print axioms hw_V_eq_integral
#print axioms hw_exp_factor
#print axioms hw_primitive_continuous
#print axioms hw_conv_eq
#print axioms hw_mean_path_and_drift
#print axioms hw_price

end HullWhiteHelpers

/-- **Hull-White fits today's curve, and only one drift does** (the card's main claim). Let `W`
be a Brownian motion, `a > 0` the pull speed, `σ` the noise size, and `f` today's forward curve,
with a continuous slope at every date. Start the rate at the curve's front end, `r₀ = f(0,0)`.

1. With the drift `θ(t) = f'(0,t) + a f(0,t) + σ²/(2a)(1 - e^(-2at))`, if the short rate `r`
   solves `r_t = f(0,0) + ∫₀ᵗ (θ(u) - a r_u) du + σ W_t` with continuous paths, then every
   zero-coupon price, the average of `e^(-∫₀ᵀ r)`, equals today's `D(T)`, for every `T ≥ 0`.
2. If any other continuous drift `θ'` gives a short rate `r'` (same equation, same start, same
   noise) whose zero-coupon prices all equal `D(T)`, then `θ'` is that same drift at every date
   `t ≥ 0`. -/
theorem hull_white_drift_fits_curve_uniquely {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {a σ : ℝ} (ha : 0 < a)
    {f : ℝ → ℝ} (hf : ContDiff ℝ 1 f) :
    (∀ r : ℝ → Ω → ℝ,
      (∀ᵐ ω ∂P, ContinuousOn (fun s => r s ω) (Set.Ici 0) ∧
        ∀ t : ℝ≥0, r t ω = f 0 + (∫ u in (0 : ℝ)..t, (hwTheta a σ f u - a * r u ω))
          + σ * W t ω) →
      ∀ T : ℝ≥0, ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P = discount f T) ∧
    (∀ (θ' : ℝ → ℝ) (r' : ℝ → Ω → ℝ), Continuous θ' →
      (∀ᵐ ω ∂P, ContinuousOn (fun s => r' s ω) (Set.Ici 0) ∧
        ∀ t : ℝ≥0, r' t ω = f 0 + (∫ u in (0 : ℝ)..t, (θ' u - a * r' u ω)) + σ * W t ω) →
      (∀ T : ℝ≥0, ∫ ω, exp (-∫ u in (0 : ℝ)..T, r' u ω) ∂P = discount f T) →
      ∀ t : ℝ, 0 ≤ t → θ' t = hwTheta a σ f t) := by
  have hfd : Differentiable ℝ f := hf.differentiable one_ne_zero
  have hdc : Continuous (deriv f) := hf.continuous_deriv le_rfl
  have hfc : Continuous f := hfd.continuous
  have hθc : Continuous (hwTheta a σ f) := by unfold hwTheta; fun_prop
  have hlc : Continuous (hwLift a σ) := by unfold hwLift; fun_prop
  obtain ⟨hint, -, hderiv⟩ := hw_mean_path_and_drift (σ := σ) ha hfd
  set φ : ℝ → ℝ := fun s => f s + hwLift a σ s with hφdef
  have hφc : Continuous φ := hfc.add hlc
  have hφeq : ∀ t : ℝ, 0 ≤ t →
      φ t = (f 0 + ∫ x in (0 : ℝ)..t, hwTheta a σ f x) - a * ∫ u in (0 : ℝ)..t, φ u := by
    intro t _
    have hφd : ∀ x, HasDerivAt φ (hwTheta a σ f x - a * φ x) x := by
      intro x
      have hdiff : DifferentiableAt ℝ φ x :=
        (hfd x).add ((hw_lift_deriv a σ ha.ne' x).differentiableAt)
      have e := hdiff.hasDerivAt
      have hx := hderiv x
      rw [show deriv φ x = hwTheta a σ f x - a * φ x by simp only [hφdef] at hx ⊢; linarith] at e
      exact e
    have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hφd x)
      ((hθc.sub (continuous_const.mul hφc)).intervalIntegrable 0 t)
    rw [intervalIntegral.integral_sub (f := hwTheta a σ f) (g := fun x => a * φ x)
      (hθc.intervalIntegrable _ _) ((continuous_const.mul hφc).intervalIntegrable _ _),
      intervalIntegral.integral_const_mul] at hftc
    have h0 : φ 0 = f 0 := by simp [hφdef, hwLift]
    linarith
  have hmθ : ∀ T : ℝ, 0 ≤ T →
      ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f 0 + ∫ x in (0 : ℝ)..u, hwTheta a σ f x)
        = (∫ u in (0 : ℝ)..T, f u) + hwV a σ T / 2 := by
    intro T hT
    rw [← hw_ode (h := fun t => f 0 + ∫ x in (0 : ℝ)..t, hwTheta a σ f x) hφc
      (continuous_const.add (hw_primitive_continuous hθc)) hφeq T hT, hφdef,
      intervalIntegral.integral_add (hfc.intervalIntegrable _ _) (hlc.intervalIntegrable _ _),
      hint]
  refine ⟨fun r hr T => ?_, fun θ' r' hθ' hr' hprice t ht => ?_⟩
  · rw [hw_price hW ha hθc r hr T T.2, hmθ T T.2, discount]
    congr 1
    ring
  · refine hw_conv_eq (a := a) (f0 := f 0) hθ' hθc (fun T hT => ?_) t ht
    have e := hprice T.toNNReal
    rw [Real.coe_toNNReal T hT] at e
    rw [hw_price hW ha hθ' r' hr' T hT, discount] at e
    have e' := Real.exp_injective e
    rw [hmθ T hT]
    linarith

/-- **The mean path and the drift read off it** (the card's Steps 3 and 4). Let `a > 0`, `σ` be
any noise size and `f` a forward curve with a slope at every date.

1. The lift adds up to half the variance: `∫₀ᵀ lift = V(T)/2` for every `T`.
2. A continuous expected path `φ` whose integral is the forward's plus half the variance,
   `∫₀ᵀ φ = ∫₀ᵀ f + V(T)/2` for every `T ≥ 0`, must be `φ(t) = f(0,t) + lift(t)` for `t ≥ 0`.
3. That path's drift, `φ' + aφ`, is the boxed formula `θ(t)` at every date. -/
theorem hull_white_mean_path_and_drift {a σ : ℝ} (ha : 0 < a) {f : ℝ → ℝ}
    (hf : Differentiable ℝ f) :
    (∀ T : ℝ, ∫ t in (0 : ℝ)..T, hwLift a σ t = hwV a σ T / 2) ∧
    (∀ φ : ℝ → ℝ, Continuous φ →
      (∀ T : ℝ, 0 ≤ T → ∫ t in (0 : ℝ)..T, φ t = (∫ t in (0 : ℝ)..T, f t) + hwV a σ T / 2) →
      ∀ t : ℝ, 0 ≤ t → φ t = f t + hwLift a σ t) ∧
    (∀ t : ℝ, deriv (fun s => f s + hwLift a σ s) t + a * (f t + hwLift a σ t)
      = hwTheta a σ f t) := by
  exact hw_mean_path_and_drift ha hf

/-- **The closed-form price returns the curve** (the card's Step 5 and its Detailed proof). With
`a > 0` and any forward curve `f`:

1. At `t = 0`, with the rate at the curve's front end `r = f(0,0)`, the closed-form price
   `P(0,T)` is today's `D(T)`, for every `T`.
2. The variance pieces behind the later-date formula combine as the card says:
   `½[V(T) - V(t) - V(T-t)] = B(t,T) lift(t) + σ²/(4a)(1 - e^(-2at)) B(t,T)²`, for every
   `t` and `T`. -/
theorem hull_white_closed_form_matches_curve {a σ : ℝ} (ha : 0 < a) (f : ℝ → ℝ) :
    (∀ T : ℝ, hwPrice a σ f 0 T (f 0) = discount f T) ∧
    (∀ t T : ℝ, (hwV a σ T - hwV a σ t - hwV a σ (T - t)) / 2
      = hwB a t T * hwLift a σ t + σ ^ 2 / (4 * a) * (1 - exp (-2 * a * t)) * hwB a t T ^ 2) := by
  have ha' : a ≠ 0 := ha.ne'
  refine ⟨fun T => ?_, fun t T => ?_⟩
  · simp [hwPrice, discount]
  · set u := exp (a * t) with hu
    set v := exp (a * T) with hv
    have upos : 0 < u := exp_pos _
    have vpos : 0 < v := exp_pos _
    have h1 : exp (-a * (T - t)) = u / v := by rw [hu, hv, ← Real.exp_sub]; congr 1; ring
    have h2 : exp (-a * T) = 1 / v := by rw [hv, one_div, ← Real.exp_neg]; congr 1; ring
    have h3 : exp (-2 * a * T) = 1 / v ^ 2 := by
      rw [hv, one_div, ← Real.exp_nat_mul, ← Real.exp_neg]; congr 1; push_cast; ring
    have h5 : exp (-2 * a * (T - t)) = u ^ 2 / v ^ 2 := by
      rw [hu, hv, ← Real.exp_nat_mul, ← Real.exp_nat_mul, ← Real.exp_sub]; congr 1; push_cast; ring
    have h6 : exp (-a * t) = 1 / u := by rw [hu, one_div, ← Real.exp_neg]; congr 1; ring
    have h7 : exp (-2 * a * t) = 1 / u ^ 2 := by
      rw [hu, one_div, ← Real.exp_nat_mul, ← Real.exp_neg]; congr 1; push_cast; ring
    simp only [hwV, hwB, hwLift, sub_zero]
    rw [h1, h2, h3, h5, h6, h7]
    field_simp
    ring

/-! The card's exact numbers, as fractions: `a = 3/10`, `σ = 1/100`, Vasicek's level `5/100`. -/

-- The first two rungs of the bootstrap ladder: D(0.5) = 1/(1 + 0.5 × 0.04) = 50/51 and
-- D(1) = 1/(1 + 1 × 0.042) = 500/521.
example : 1 / (1 + (1 / 2 : ℚ) * (4 / 100)) = 50 / 51 ∧
    1 / (1 + (1 : ℚ) * (42 / 1000)) = 500 / 521 := by
  norm_num

-- The noise term at 2.5 years: σ²/(2a) = 0.01²/0.6 = 1/6000, and the exponent 2at = 1.5.
example : ((1 : ℚ) / 100) ^ 2 / (2 * (3 / 10)) = 1 / 6000 ∧ 2 * (3 / 10 : ℚ) * (5 / 2) = 3 / 2 := by
  norm_num

-- Road 5: plain Vasicek's fixed push, a × level = 0.3 × 0.05 = 0.015.
example : (3 / 10 : ℚ) * (5 / 100) = 15 / 1000 := by
  norm_num

-- Step 4's bracket: with E = e^(-at), 2E + 1 - E = 1 + E and (1 - E)(1 + E) = 1 - E².
example (E : ℝ) : 2 * E + 1 - E = 1 + E ∧ (1 - E) * (1 + E) = 1 - E ^ 2 := by
  constructor <;> ring

#print axioms hull_white_drift_fits_curve_uniquely
#print axioms hull_white_mean_path_and_drift
#print axioms hull_white_closed_form_matches_curve

end HullWhiteModel
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'HullWhiteModel.hw_eq_zero_of_integral_eq_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_lift_hasDerivAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_lift_deriv' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_ode' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_riemann' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_abel' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_gauss' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_B_eq_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_V_eq_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_exp_factor' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_primitive_continuous' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_conv_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_mean_path_and_drift' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hw_price' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hull_white_drift_fits_curve_uniquely' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hull_white_mean_path_and_drift' depends on axioms: [propext, Classical.choice, Quot.sound]
'HullWhiteModel.hull_white_closed_form_matches_curve' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Double the noise.** Guess first: does the five-year price move? Set `SIG` to `0.02`. Road 2 still lands on 0.79621728 and every assert passes. The noise term in theta grows fourfold instead.
> - **Move a quote.** Guess first: which road breaks? Set the five-year swap to `0.0480`. None does. The last forward jumps and Vasicek's miss at five years grows; Hull-White still matches every date, because theta is rebuilt from the new curve.
> - **Forget the kicks.** Guess first: how far off? In road 2 call `road2(FW[0], kicks=False)` for `R2`. The first assert stops the run; the five-year price is the 0.81007656 in the what-breaks table.
> - **Start Vasicek higher.** Guess first: does road 5 notice? Set `VR0` to `0.06`. Vasicek's curve now falls, its miss at five years turns into a shortfall, and road 5 still returns 0.01500000 at every date. A Vasicek curve always hands back a flat theta; this curve's theta moves, so no Vasicek curve with this pull and noise can draw it.

---

## The usual mistake

> [!warning]
> **Reading theta as a forecast of rates.** Theta is the curve rewritten as a push. It holds no view on where rates are going; it holds whatever the six quotes said this morning, plus a noise term. Only $a$ and $\sigma$ are the model's own, and they are fitted to option prices, never to the curve.
>
> - **Reading theta as the target level.** The target is theta ÷ $a$: 4.8001 percent at 2.5 years, not theta's 1.4400.
> - **Starting the rate anywhere but the curve's front end.** The fit needs $r(0) = f(0,0)$, here 3.9605 percent. Starting at a round 4 percent makes the five-year zero 0.79540379, 8,134.93 dollars short on 10,000,000.
> - **Dropping the slope term.** Writing theta as $a f + \dots$ without $f'$ leaves the rate unable to follow a rising curve: 138,592.78 dollars too much at five years here.
> - **Dropping the noise term.** It is small, 0.0129 percent a year at 2.5 years, and without it the five-year zero is 6,215.38 dollars too dear.
> - **Believing the prices between quotes.** The model matches whatever curve it is given. Between the quoted dates that curve is an interpolation rule, and theta's kicks are the rule's steps, not the market's.

---

## Where you meet it in real life

- **Rates option desks.** The one-factor Hull-White model is a standard engine for Bermudan swaptions (options to enter a swap, exercisable on any of several set dates) and callable bonds: fit the curve with theta, fit $a$ and $\sigma$ to swaption quotes, price on a tree. The tree is [The Hull-White tree](06-hull-white-trinomial-tree.md).
- **Bond and cap options in closed form.** Because the rate stays normal, an option on a zero-coupon bond has a Black-type formula, and a caplet is a put on a zero. That is [Bond options](05-bond-options-and-jamshidians-trick.md).
- **Futures convexity.** The gap between a rate future and the matching forward rate agreement is a Hull-White calculation on most desks: [Futures against forwards](../32-Convexity%20and%20Exotics/01-futures-forward-convexity.md).
- **Risk and valuation adjustments.** Exposure simulations need thousands of future curves consistent with today's; each is the $A$, $B$ formula at one simulated rate.
- **Negative rates.** Euro, Swiss franc and yen rates went below zero from 2014 onward; a normal model allowed that, positive-rate models did not.

> **Say it back**
> Vasicek pulls the rate toward a fixed level, so it draws only a few curves; here it misprices the five-year dollar by 36,383.48 on 10,000,000. Hull-White lets the level move. The noise sets the spread of the rate's paths; the drift sets their average at the forward curve plus a small lift that pays for the spread. That drift is the forward's slope plus the pull times the forward plus a noise term, and for fixed pull and noise it is the only one that fits. Every zero price then matches the curve by construction.

---

## What this builds on

- [Vasicek](02-vasicek-model.md): the pull, the noise, the normal rate and the closed-form bond; this card changes only the target.

---

## Where this goes next

- [Bond options](05-bond-options-and-jamshidians-trick.md): numbered next on this shelf. It prices an option on a zero with the $A$, $B$ formula, and an option on a coupon bond as a bundle of them.
- [The Hull-White tree](06-hull-white-trinomial-tree.md): theta found numerically on a lattice, for payoffs with early exercise.
- [Beyond one factor](07-two-factor-and-lognormal-short-rate-models.md): a second noise so the curve can twist, and lognormal models that keep rates positive.
- [Heath-Jarrow-Morton](../31-Forward-Rate%20Models/01-hjm-framework-and-the-drift-condition.md): the same fit seen from the forward curve, where no-arbitrage fixes the drift of every maturity at once.
- [Futures against forwards](../32-Convexity%20and%20Exotics/01-futures-forward-convexity.md): the model's first everyday job, the gap between a rate future and a forward.
- [Calibrating Hull-White](08-calibrating-a-short-rate-model.md): fits $a$ and $\sigma$ to option quotes, the two numbers the curve leaves open.

The curve fixes theta but leaves $a$ and $\sigma$ open, and they decide every option price.

---

## Sources

Verified 2026-11-13: every link below resolves to the publisher's page.

- Hull, J. and White, A. (1990). "Pricing Interest-Rate-Derivative Securities." *The Review of Financial Studies* 3(4), 573–592. [doi:10.1093/rfs/3.4.573](https://doi.org/10.1093/rfs/3.4.573). The model: Vasicek with a time-dependent drift fitted to the initial curve, and its bond and bond-option prices.
- Vasicek, O. (1977). "An Equilibrium Characterization of the Term Structure." *Journal of Financial Economics* 5(2), 177–188. [doi:10.1016/0304-405X(77)90016-2](https://doi.org/10.1016/0304-405X(77)90016-2). The mean-reverting normal rate this card extends.
- Brigo, D. and Mercurio, F. (2006). *Interest Rate Models — Theory and Practice*, 2nd edition. Springer. [doi:10.1007/978-3-540-34604-3](https://doi.org/10.1007/978-3-540-34604-3). The chapter on one-factor short-rate models: the split of the rate into a known path plus noise used in Why it works.
- Heath, D., Jarrow, R. and Morton, A. (1992). "Bond Pricing and the Term Structure of Interest Rates: A New Methodology for Contingent Claims Valuation." *Econometrica* 60(1), 77–105. [doi:10.2307/2951677](https://doi.org/10.2307/2951677). The forward-curve road to the same drift.
