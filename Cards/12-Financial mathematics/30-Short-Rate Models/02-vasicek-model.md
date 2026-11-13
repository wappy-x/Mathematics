# Vasicek: a mean-reverting normal rate with closed-form bonds

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Short-Rate Models](../README.md#s30) → Vasicek

---

## General Overview

A bond that pays $1 in five years and nothing before is a **zero-coupon bond**, or a zero. Today the overnight rate, the interest earned on cash lent until tomorrow, is 4 percent a year.

Over the next five years it will not stay there. It will also not wander off without limit: when rates run high, borrowing dries up and central banks cut; when they run low, the reverse. Rates are drawn back toward a usual level, here 5 percent.

A ball on a rubber band behaves this way. Pull it and it heads back, fast when far away, slowly when close, while being knocked about at random. Finance calls the pull **mean reversion**: a quantity drawn back toward a long-run level. From here on the target is the **level** and the strength of the pull is the **speed**.

In 1977 Oldřich Vasicek wrote the simplest model with that pull. The rate for the next instant, the **short rate**, is pulled toward 5 percent at speed 0.3 a year and knocked by normal shocks that, left alone for a year, would spread it by a standard deviation of 1 percentage point. Every zero, of every maturity, then has a price in closed form, an exact formula.

The 5-year zero is worth $0.7999, about 80 cents on the dollar, a yield of 4.47 percent a year: the flat rate that gives that price. The same formula prices every maturity at once, so it draws a whole yield curve from four numbers. It also allows the rate to fall below zero, which was a flaw in 1977 and a feature after 2014.

**Model the short rate as a random walk pulled toward a level; the area under its path is then normal, and a bond price, the average of e raised to minus that area, comes out as an exponential of a straight line in today's rate.**

**What kind of fact this is:** a model: normal, mean-reverting rate moves are an assumption that fits calm markets well enough, not a law. Inside the model, the bond formula is a theorem, proved on this card in Why it works.

### The picture: three curves from one formula

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Vasicek yield curves: level 5%, speed 0.3, volatility 1%"
    x-axis "Years to maturity" [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    y-axis "Yield (percent a year)" 0 --> 9
    line [2.00, 2.41, 2.74, 3.01, 3.24, 3.43, 3.59, 3.72, 3.84, 3.94, 4.02]
    line [4.00, 4.13, 4.24, 4.33, 4.41, 4.47, 4.52, 4.56, 4.60, 4.63, 4.65]
    line [8.00, 7.59, 7.25, 6.97, 6.74, 6.54, 6.37, 6.23, 6.11, 6.01, 5.92]
```

Bottom line: today's rate 2 percent, a steeply rising curve. Middle line: the house example, today's rate 4 percent, gently rising; at five years it reads 4.47. Top line: today's rate 8 percent, a falling curve. All three head for the same long yield, 4.94 percent, a little under the 5 percent level; Step 3 explains the gap.

---

## The formula

Notation first. The model is written in the shorthand of Itô calculus ([Ito's lemma](../../11-Stochastic%20processes%20and%20calculus/06-Ito%20Calculus/02-itos-lemma.md)): $dr_t$ is the change in the rate over a short step of time $dt$, and $dW_t$ is a random shock over that step, with average zero and variance $dt$. The model is an Ornstein-Uhlenbeck process, a random walk with a pull toward a level ([Mean reversion](../../11-Stochastic%20processes%20and%20calculus/06-Ito%20Calculus/05-ornstein-uhlenbeck-and-cir-processes.md)):

$$dr_t = a\,(\theta - r_t)\,dt + \sigma\,dW_t$$

**Read it aloud:** each instant the rate moves a fraction of the way toward the level, plus a normal shock of fixed size.

The price today of $1 paid at time $T$:

$$P(0,T) = e^{\,A(T) - B(T)\,r_0}, \qquad B(T) = \frac{1 - e^{-aT}}{a}, \qquad A(T) = \Big(\theta - \frac{\sigma^2}{2a^2}\Big)\big(B(T) - T\big) - \frac{\sigma^2 B(T)^2}{4a}$$

**Read it aloud:** the log of the bond price is a straight line in today's rate, with slope minus $B$ and intercept $A$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $r_t$, $r_0$, $r$, $dr_t$ | the short rate at time $t$; today's value; the rate as a variable; its change over one short step | 4% today | $r_0$ up: every bond cheaper, short ones most |
| $\theta$ | the level the rate is pulled toward (read "theta") | 5% | bonds cheaper, long ones most |
| $a$ | the speed of the pull, per year | 0.3 | the curve reaches the level sooner |
| $\sigma$ | the size of the shocks, per year (read "sigma") | 1% | bonds dearer: see Step 3 |
| $dW_t$ | a normal shock over one short step | — | — |
| $t$, $s$, $\tau$, $dt$ | a date; the date a shock lands; time left to maturity; a short step of time | — | — |
| $T$ | years until the $1 is paid | 5 | bond cheaper |
| $P(0,T)$ | today's price of $1 paid at $T$ | 0.7999 | — |
| $B(T)$ | how much a change in today's rate moves the log price; also the rate's remembered weight, in years | 2.5896 | — |
| $A(T)$ | the part of the log price that does not depend on today's rate | −0.1197 | — |
| $R(T)$, $R_\infty$ | the yield $-\ln P(0,T)/T$, the flat rate giving the same price; the yield of a very long bond, $\theta - \sigma^2/(2a^2)$ | 4.47%; 4.94% | — |
| $I_T$, $I$, $m$, $v$ | the area under the rate's path from now to $T$, whose $e^{-I_T}$ is that path's discount factor; its mean; its variance | mean 0.2241, variance 0.001561 | — |

### When it holds

- **Normal shocks of one size.** Real rate volatility changes with the rate's level. Near zero, normal shocks of fixed size put too much weight on deeply negative rates; [Cox-Ingersoll-Ross](03-cox-ingersoll-ross-model.md) scales the shocks with the rate.
- **One source of randomness.** Every yield moves with the same shock, so the 2-year and 30-year yields are perfectly correlated. Real curves also twist; [Beyond one factor](07-two-factor-and-lognormal-short-rate-models.md) adds a second shock.
- **A constant level.** Four numbers cannot reproduce the curve the market shows today, which has its own bends. Bonds priced off Vasicek disagree with quoted prices by basis points (hundredths of a percent) or more; [Hull-White](04-hull-white-model.md) lets the level move with time to fit it exactly.
- **The level is the pricing-world level.** $\theta$ is the level in the pricing world set up on [A short-rate model](01-the-term-structure-equation.md), with the market price of risk (the extra return investors demand for carrying rate risk) folded in. It is not a forecast of where rates will settle.

---

## Why it works

### Step 0: a bond is an average of discount factors

From [A short-rate model](01-the-term-structure-equation.md): in the pricing world (the risk-neutral weighting of paths, under which a price is an average of discounted payoffs), a zero is worth the average, over all paths the rate might take, of $e^{-I_T}$, where $I_T$ is the area under the path from now to $T$. A path that stays at 4 percent for five years has area 0.2 and discounts $1 to $e^{-0.2}$.

The rest is one fact about normal variables. Vasicek's rate at every date is built from the same normal shocks, added with fixed weights. Any such weighted sum of shared normal shocks is normal, and an area is a sum.

So $I_T$ is normal, and the average of $e^{-I}$ for a normal $I$ with mean $m$ and variance $v$ is $e^{-m + v/2}$, the mean of a lognormal variable ([Geometric Brownian motion](../../11-Stochastic%20processes%20and%20calculus/05-Brownian%20Motion/07-geometric-brownian-motion.md) uses the same fact). Only $m$ and $v$ are needed.

### Step 1: solve the rate

Write $x_t = r_t - \theta$, the distance above the level. The pull shrinks it at rate $a$, so without shocks $x_t = x_0 e^{-at}$. Each shock, once it lands, decays the same way. Summing them:

$$r_t = \theta + (r_0 - \theta)\,e^{-at} + \sigma \int_0^t e^{-a(t-s)}\,dW_s$$

The last term is a sum of normal shocks, so $r_t$ is normal. Its mean is $\theta + (r_0 - \theta)e^{-at}$: at five years, 4.78 percent, most of the way from 4 to 5. Its standard deviation at five years is 1.26 percent. The [Mean reversion](../../11-Stochastic%20processes%20and%20calculus/06-Ito%20Calculus/05-ornstein-uhlenbeck-and-cir-processes.md) card derives both.

### Step 2: the area under the path

Integrate the mean from 0 to $T$. The level contributes $\theta T$. The starting gap $r_0 - \theta$ contributes that gap times

$$\int_0^T e^{-at}\,dt = \frac{1 - e^{-aT}}{a} = B(T).$$

So $B(T)$ is how many years' worth of today's gap the path remembers. A rate with no pull remembers all of it, and $B = T$. At speed 0.3 over five years the path remembers 2.59 years' worth. The mean area is $m = \theta T + (r_0 - \theta)B(T)$, which is 0.2241 here.

The variance of the area is

$$v = \frac{\sigma^2}{a^2}\Big(T - B(T) - \frac{a\,B(T)^2}{2}\Big),$$

0.001561 here. A shock that lands at time $s$ keeps pushing the rate until $T$, adding $B(T-s)$ to the area per unit of shock. Adding the squares of those weights over the whole life gives $v$.

<details>
<summary>The algebra behind the variance</summary>

Swap the order of integration: $\int_0^T \int_0^t e^{-a(t-s)}\,dW_s\,dt = \int_0^T B(T-s)\,dW_s$, since $\int_s^T e^{-a(t-s)}dt = B(T-s)$. The variance of $\int_0^T f(s)\,dW_s$ is $\int_0^T f(s)^2\,ds$ (the Itô isometry). So
$$v = \frac{\sigma^2}{a^2}\int_0^T \big(1 - 2e^{-a\tau} + e^{-2a\tau}\big)d\tau = \frac{\sigma^2}{a^2}\Big(T - 2B + \frac{1 - e^{-2aT}}{2a}\Big).$$
Write $e^{-aT} = 1 - aB$. Then $\frac{1 - e^{-2aT}}{2a} = \frac{(1 - e^{-aT})(1 + e^{-aT})}{2a} = \frac{B(2 - aB)}{2} = B - \frac{aB^2}{2}$, and $v = \frac{\sigma^2}{a^2}\big(T - B - \frac{aB^2}{2}\big)$.

</details>

### Step 3: collect the terms

The price is $e^{-m + v/2}$. Sort the exponent into the part that multiplies $r_0$ and the part that does not:

$$-m = \theta\,(B - T) - B\,r_0, \qquad \frac{v}{2} = -\frac{\sigma^2}{2a^2}(B - T) - \frac{\sigma^2 B^2}{4a}.$$

The terms without $r_0$ add to $A(T)$. The term with $r_0$ is $-B(T)\,r_0$. That is the formula.

The $+v/2$ is **convexity**: $e^{-I}$ bends upward, so spreading $I$ out raises its average (Jensen's inequality). Randomness makes bonds dearer, and more so the longer they run. It is why the long yield $R_\infty$ sits at 4.94 percent, below the 5 percent level: divide the exponent by $T$ and let $T$ grow, and only $\theta - \sigma^2/(2a^2)$ survives.

### Step 4: the same answer from the bond equation

[A short-rate model](01-the-term-structure-equation.md) says every bond price $P$, as a function of the rate $r$ and the time left $\tau$, satisfies

$$\frac{\partial P}{\partial \tau} = a(\theta - r)\frac{\partial P}{\partial r} + \tfrac12\sigma^2 \frac{\partial^2 P}{\partial r^2} - rP, \qquad P = 1 \text{ at } \tau = 0.$$

Guess $P = e^{A(\tau) - B(\tau) r}$. Each derivative brings down a factor: $\partial P/\partial r = -BP$, $\partial^2 P/\partial r^2 = B^2 P$. Divide by $P$ and the equation must hold for every $r$, so the terms in $r$ and the constant terms must each balance:

$$B' = 1 - aB, \qquad A' = -a\theta B + \tfrac12\sigma^2 B^2, \qquad A(0) = B(0) = 0.$$

The first is solved by $B = (1 - e^{-a\tau})/a$; integrating the second gives the same $A$ as Step 3. The code solves both by stepping them forward numerically, without the closed form, and lands on the same price.

A model whose log bond prices are straight lines in the rate is called **affine**. Duffie and Kan (1996) showed which rate models have this property: the drift and the variance of the shocks must both be straight lines in the rate. Vasicek has a straight-line drift and a constant variance; [Cox-Ingersoll-Ross](03-cox-ingersoll-ross-model.md) has a variance proportional to the rate. Both are affine.

---

## Worked numbers, by hand

Level $\theta$ = 5 percent, speed $a$ = 0.3, volatility $\sigma$ = 1 percent, today's rate $r_0$ = 4 percent, $T$ = 5 years.

| Step | Arithmetic | Value |
| --- | --- | --- |
| $e^{-aT}$ | $e^{-1.5}$ | 0.223130 |
| $B(5)$ | $(1 - 0.223130)/0.3$ | 2.589566 |
| level part | $(0.05 - 0.0001/0.18) \times (2.589566 - 5)$ | −0.119183 |
| spread part | $0.0001 \times 2.589566^2 / 1.2$ | 0.000559 |
| $A(5)$ | $-0.119183 - 0.000559$ | −0.119741 |
| rate part | $-2.589566 \times 0.04$ | −0.103583 |
| log of price | $-0.119741 - 0.103583$ | −0.223324 |
| **price** | $e^{-0.223324}$ | **0.7999** |
| yield | $0.223324/5$ | 4.47% |

A promise of $1 in five years costs $0.7999 today. The same $1 discounted at a flat 4 percent would cost $0.8187; the pull toward 5 percent makes the bond cheaper.

### What breaks if you drop a piece

Correct answer $0.7999 for the 5-year zero.

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Discount at today's 4% for all five years | 0.8187 | Ignores the pull toward 5% |
| Discount at the 5% level for all five years | 0.7788 | Ignores that the rate starts below the level |
| Discount along the expected path, no convexity | 0.7992; 30-year 0.2307 against 0.2339 | Average of discount factors taken as the discount factor of the average rate |
| Convexity sign flipped, $-v/2$ | 0.7986 | Spreading the area out raises the average of $e^{-I}$; it does not lower it |
| No pull, speed near 0 | 0.8204 | The path remembers all five years of today's rate, and the shocks pile up without limit |

The code prints every one.

---

## How the curve moves with today's rate

One number, today's short rate, sets the whole curve. The level, speed and volatility fix its shape; $r_0$ slides it.

### The 5-year zero, one rate at a time

```
today's rate   price of $1 in 5 years
    -1%   ████████████████████████████████████  0.9104
     0%   ███████████████████████████████████   0.8871
     2%   █████████████████████████████████     0.8424
     4%   ███████████████████████████████       0.7999
     6%   ██████████████████████████████        0.7595
     8%   ████████████████████████████          0.7212
```

From 2 to 4 percent the price falls from 0.8424 to 0.7999. A flat rate held for five years would fall much further, since the bond would feel all five years of the move.

The pull prevents that: a move in today's rate is expected to fade, so the bond feels only $B(5)$ = 2.59 years of it. The 5-year yield moves 0.52 of a point for each point in $r_0$. The code confirms 2.59 by nudging $r_0$ and repricing.

### Negative rates are allowed

The rate at any date is normal, so it has some chance of being below zero. At five years the rate averages 4.78 percent with a standard deviation of 1.26 percent. The chance it is negative is 0.0074 percent at the house volatility, and 2.89 percent if the volatility is 2 percent; 200,000 simulated draws give 2.93 percent.

When today's rate is already negative, a short zero costs more than it pays. At $r_0$ = −0.5 percent, a 3-month zero costs $1.0007 per $1 back. Euro-area, Swiss and Japanese bonds traded like that for years in the decade after 2014. A model with no negative rates cannot price them at all.

### A hump

With larger shocks the long end bends back down, because convexity grows with maturity. Volatility 3 percent, today's rate 4.5 percent:

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Humped Vasicek curve: level 5%, speed 0.3, volatility 3%, today 4.5%"
    x-axis "Years to maturity" [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20]
    y-axis "Yield (percent a year)" 4.4 --> 4.7
    line [4.50, 4.56, 4.58, 4.60, 4.60, 4.60, 4.60, 4.59, 4.58, 4.55, 4.54]
```

The one line: the yield climbs from 4.50 toward the level, peaks at 4.60 around four years, then sinks toward the long yield as convexity takes over. So Vasicek draws rising, falling and humped curves. It cannot draw a dip followed by a rise, or match an arbitrary market curve; that needs [Hull-White](04-hull-white-model.md).

---

## Code, from first principles, and it actually runs

The 5-year zero is priced four ways that share no code.

First, the closed form. Second, the mean and variance of the area under the path, then the lognormal mean $e^{-m + v/2}$. Third, the bond equation's two ordinary differential equations (ODEs) for $A$ and $B$, stepped forward by fourth-order Runge-Kutta with no closed form in sight. Fourth, 8,000 simulated rate paths (4,000 mirrored pairs), each discounted along its own area.

The random numbers come from a hand-written generator and the normal CDF (cumulative distribution function: the chance a normal draw falls below a value) from Simpson's rule. The rate sensitivity is checked by nudging $r_0$; the chance of a negative rate is checked by drawing 200,000 rates.

### Python

```python
# Vasicek model -- the check behind the card.  Standard library only.
# Short rate r pulled toward level th at speed a, with volatility s:
#   dr = a (th - r) dt + s dW.   House example: a = 0.3, th = 5%, s = 1%, r0 = 4%.
# The 5-year zero is priced four ways that share no code: the closed form,
# the Gaussian integral of the rate, the bond equation solved as two ODEs by
# Runge-Kutta, and simulated rate paths.  The normal CDF and the random
# numbers are written here.
from math import exp, log, sqrt, cos, pi

A_, TH, S_, R0, T = 0.3, 0.05, 0.01, 0.04, 5.0

def closed(r0, t, a=A_, th=TH, s=S_):                 # road 1: P = exp(lnA - B r0)
    b = (1 - exp(-a * t)) / a
    ln_a = (th - s * s / (2 * a * a)) * (b - t) - s * s * b * b / (4 * a)
    return exp(ln_a - b * r0)

def integral_moments(r0, t, a=A_, th=TH, s=S_):       # mean and variance of the area under r
    b = (1 - exp(-a * t)) / a
    return th * t + (r0 - th) * b, s * s / (a * a) * (t - b - a * b * b / 2)

def by_moments(r0, t):                                # road 2: E[exp(-I)] for a normal I
    m, v = integral_moments(r0, t)
    return exp(-m + v / 2)

def by_ode(r0, t, n=1000):                            # road 3: B' = 1 - aB, lnA' = -a th B + s^2 B^2 / 2
    f = lambda y: (1 - A_ * y[0], -A_ * TH * y[0] + S_ * S_ * y[0] * y[0] / 2)
    y, h = (0.0, 0.0), t / n
    for _ in range(n):
        k1 = f(y); k2 = f((y[0] + h / 2 * k1[0], y[1] + h / 2 * k1[1]))
        k3 = f((y[0] + h / 2 * k2[0], y[1] + h / 2 * k2[1])); k4 = f((y[0] + h * k3[0], y[1] + h * k3[1]))
        y = (y[0] + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]), y[1] + h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]))
    return exp(y[1] - y[0] * r0), y[0]

M64 = (1 << 64) - 1
state = 20260928
def uniform():                                        # splitmix64, written out
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 9007199254740992.0

def normal():                                         # Box-Muller, cosine half
    u1, u2 = uniform(), uniform()
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2)

def by_paths(r0, t, pairs=4000, steps=250):           # road 4: simulate, discount, average
    dt = t / steps
    decay, sd = exp(-A_ * dt), S_ * sqrt((1 - exp(-2 * A_ * dt)) / (2 * A_))
    vals = []
    for _ in range(pairs):
        rp = rm = r0; ip = im = 0.0
        for _ in range(steps):
            z = normal()
            np_ = TH + (rp - TH) * decay + sd * z; nm = TH + (rm - TH) * decay - sd * z
            ip += (rp + np_) / 2 * dt; im += (rm + nm) / 2 * dt; rp, rm = np_, nm
        vals.append((exp(-ip) + exp(-im)) / 2)
    mean = sum(vals) / pairs
    se = sqrt(sum((x - mean) ** 2 for x in vals) / (pairs - 1) / pairs)
    return mean, se

def ncdf(x, n=2000):                                  # bell-curve area left of x, Simpson
    h = x / n
    g = lambda u: exp(-u * u / 2) / sqrt(2 * pi)
    tot = g(0) + g(x) + sum((4 if i % 2 else 2) * g(i * h) for i in range(1, n))
    return 0.5 + tot * h / 3

def rate_at(t, r0=R0, s=S_):                          # mean and sd of r_t
    return TH + (r0 - TH) * exp(-A_ * t), s * sqrt((1 - exp(-2 * A_ * t)) / (2 * A_))

def yld(r0, t, s=S_): return 100 * (-log(closed(r0, t, s=s)) / t) if t > 0 else 100 * r0

p1 = closed(R0, T); p2 = by_moments(R0, T); p3, b_ode = by_ode(R0, T); p4, se = by_paths(R0, T)
b = (1 - exp(-A_ * T)) / A_
m, v = integral_moments(R0, T)
h = 1e-4
dur_bump = -(closed(R0 + h, T) - closed(R0 - h, T)) / (2 * h) / p1
mu5, sd5 = rate_at(T); mu5b, sd5b = rate_at(T, s=0.02)
neg_1 = ncdf(-mu5 / sd5); neg_2 = ncdf(-mu5b / sd5b)
draws = 200000
neg_count = sum(1 for _ in range(draws) if mu5b + sd5b * normal() < 0)

rows = [
    ("e^(-aT)", exp(-A_ * T)), ("B(5), rate sensitivity in years", b), ("B(5) from the ODE", b_ode),
    ("level part (th - s^2/2a^2)(B - T)", (TH - S_ * S_ / (2 * A_ * A_)) * (b - T)),
    ("spread part s^2 B^2 / 4a", S_ * S_ * b * b / (4 * A_)),
    ("A(5)", log(p1) + b * R0), ("-B(5) r0", -b * R0), ("log of price", log(p1)),
    ("mean of area under r, 0 to 5", m), ("variance of that area", v),
    ("1 closed form P(0,5)", p1), ("2 Gaussian integral", p2), ("3 Runge-Kutta ODE", p3),
    ("4 paths, 4000 antithetic pairs", p4), ("  standard error", se),
    ("5-year yield, percent", yld(R0, T)), ("long yield, percent", 100 * (TH - S_ * S_ / (2 * A_ * A_))),
    ("5-year yield move per point of r0", b / T), ("bumped rate sensitivity", dur_bump),
    ("expected r at 5y, percent", 100 * mu5), ("sd of r at 5y, percent", 100 * sd5),
    ("P(r5 < 0), s = 1%, percent", 100 * neg_1), ("P(r5 < 0), s = 2%, percent", 100 * neg_2),
    ("  simulated, 200000 draws, percent", 100 * neg_count / draws),
    ("3-month zero at r0 = -0.5%", closed(-0.005, 0.25)),
    ("wrong: flat at today's 4%", exp(-R0 * T)), ("wrong: flat at the 5% level", exp(-TH * T)),
    ("wrong: expected path, no convexity", exp(-m)), ("wrong: convexity sign flipped", exp(-m - v / 2)),
    ("wrong: no reversion, a -> 0", exp(-R0 * T + S_ * S_ * T ** 3 / 6)),
    ("30-year zero", closed(R0, 30.0)), ("  30-year, no convexity", exp(-integral_moments(R0, 30.0)[0])),
    ("try: a = 0.03", closed(R0, T, a=0.03)), ("try: s = 3%", closed(R0, T, s=0.03)),
    ("try: r0 = 8%", closed(0.08, T)), ("try: r0 = 0%", closed(0.0, T)),
]
for name, val in rows:
    print(f"{name:<36} {val:>12.6f}")
print()
print("5-year zero by today's rate, percent: price")
for r in (-1, 0, 2, 4, 6, 8):
    print(f"  r0 = {r:>2}%   {closed(r / 100, T):.4f}")
print()
mats = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
print("yield curve, percent" + "".join(f"{t:>6}" for t in mats))
for r in (2, 4, 8):
    print(f"  r0 = {r}%, s = 1%    " + "".join(f"{yld(r / 100, t):6.2f}" for t in mats))
humps = (0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20)
print("hump, maturities   " + "".join(f"{t:>6}" for t in humps))
print("  r0 = 4.5%, s = 3%" + "".join(f"{yld(0.045, t, s=0.03):6.2f}" for t in humps))

assert abs(p1 - p2) < 1e-12, "closed form vs Gaussian integral"
assert abs(p1 - p3) < 1e-10, "closed form vs Runge-Kutta on the bond equation"
assert abs(p4 - p1) < 4 * se, "simulated paths within four standard errors"
assert abs(dur_bump - b_ode) < 1e-6, "bumped sensitivity vs B from the ODE"
assert abs(neg_count / draws - neg_2) < 0.002, "simulated negative-rate share vs normal CDF"
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
e^(-aT)                                  0.223130
B(5), rate sensitivity in years          2.589566
B(5) from the ODE                        2.589566
level part (th - s^2/2a^2)(B - T)       -0.119183
spread part s^2 B^2 / 4a                 0.000559
A(5)                                    -0.119741
-B(5) r0                                -0.103583
log of price                            -0.223324
mean of area under r, 0 to 5             0.224104
variance of that area                    0.001561
1 closed form P(0,5)                     0.799856
2 Gaussian integral                      0.799856
3 Runge-Kutta ODE                        0.799856
4 paths, 4000 antithetic pairs           0.799848
  standard error                         0.000014
5-year yield, percent                    4.466481
long yield, percent                      4.944444
5-year yield move per point of r0        0.517913
bumped rate sensitivity                  2.589566
expected r at 5y, percent                4.776870
sd of r at 5y, percent                   1.258447
P(r5 < 0), s = 1%, percent               0.007357
P(r5 < 0), s = 2%, percent               2.885312
  simulated, 200000 draws, percent       2.928500
3-month zero at r0 = -0.5%               1.000748
wrong: flat at today's 4%                0.818731
wrong: flat at the 5% level              0.778801
wrong: expected path, no convexity       0.799232
wrong: convexity sign flipped            0.798608
wrong: no reversion, a -> 0              0.820438
30-year zero                             0.233919
  30-year, no convexity                  0.230692
try: a = 0.03                            0.817336
try: s = 3%                              0.804864
try: r0 = 8%                             0.721151
try: r0 = 0%                             0.887150

5-year zero by today's rate, percent: price
  r0 = -1%   0.9104
  r0 =  0%   0.8871
  r0 =  2%   0.8424
  r0 =  4%   0.7999
  r0 =  6%   0.7595
  r0 =  8%   0.7212

yield curve, percent     0     1     2     3     4     5     6     7     8     9    10
  r0 = 2%, s = 1%      2.00  2.41  2.74  3.01  3.24  3.43  3.59  3.72  3.84  3.94  4.02
  r0 = 4%, s = 1%      4.00  4.13  4.24  4.33  4.41  4.47  4.52  4.56  4.60  4.63  4.65
  r0 = 8%, s = 1%      8.00  7.59  7.25  6.97  6.74  6.54  6.37  6.23  6.11  6.01  5.92
hump, maturities        0     1     2     3     4     5     6     8    10    15    20
  r0 = 4.5%, s = 3%  4.50  4.56  4.58  4.60  4.60  4.60  4.60  4.59  4.58  4.55  4.54
ALL CHECKS PASS
```

Four roads, one price. The closed form, the Gaussian integral and Runge-Kutta agree to the last printed digit. The simulated paths land within one standard error, 0.000014, of them.

### Rust

Same roads, same generator seed, same labels; built with `rustc --edition 2021 -O`.

```rust
// Vasicek model -- the same check as vasicek_model_check.py, in Rust.  No crates.
// Short rate r pulled toward level th at speed a, with volatility s:
//   dr = a (th - r) dt + s dW.   House example: a = 0.3, th = 5%, s = 1%, r0 = 4%.
// The 5-year zero is priced four ways that share no code: the closed form,
// the Gaussian integral of the rate, the bond equation solved as two ODEs by
// Runge-Kutta, and simulated rate paths.  The normal CDF and the random
// numbers are written here.
use std::f64::consts::PI;

const A_: f64 = 0.3;
const TH: f64 = 0.05;
const S_: f64 = 0.01;
const R0: f64 = 0.04;
const T: f64 = 5.0;

fn closed_g(r0: f64, t: f64, a: f64, s: f64) -> f64 {  // road 1: P = exp(lnA - B r0)
    let b = (1.0 - (-a * t).exp()) / a;
    let ln_a = (TH - s * s / (2.0 * a * a)) * (b - t) - s * s * b * b / (4.0 * a);
    (ln_a - b * r0).exp()
}
fn closed(r0: f64, t: f64) -> f64 { closed_g(r0, t, A_, S_) }

fn integral_moments(r0: f64, t: f64) -> (f64, f64) {  // mean and variance of the area under r
    let b = (1.0 - (-A_ * t).exp()) / A_;
    (TH * t + (r0 - TH) * b, S_ * S_ / (A_ * A_) * (t - b - A_ * b * b / 2.0))
}

fn by_moments(r0: f64, t: f64) -> f64 {                // road 2: E[exp(-I)] for a normal I
    let (m, v) = integral_moments(r0, t);
    (-m + v / 2.0).exp()
}

fn by_ode(r0: f64, t: f64, n: usize) -> (f64, f64) {    // road 3: B' = 1 - aB, lnA' = -a th B + s^2 B^2 / 2
    let f = |y: (f64, f64)| (1.0 - A_ * y.0, -A_ * TH * y.0 + S_ * S_ * y.0 * y.0 / 2.0);
    let (mut y, h) = ((0.0f64, 0.0f64), t / n as f64);
    for _ in 0..n {
        let k1 = f(y);
        let k2 = f((y.0 + h / 2.0 * k1.0, y.1 + h / 2.0 * k1.1));
        let k3 = f((y.0 + h / 2.0 * k2.0, y.1 + h / 2.0 * k2.1));
        let k4 = f((y.0 + h * k3.0, y.1 + h * k3.1));
        y = (y.0 + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0),
             y.1 + h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1));
    }
    ((y.1 - y.0 * r0).exp(), y.0)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                      // splitmix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                       // Box-Muller, cosine half
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn by_paths(rng: &mut Rng, r0: f64, t: f64, pairs: usize, steps: usize) -> (f64, f64) {  // road 4
    let dt = t / steps as f64;
    let (decay, sd) = ((-A_ * dt).exp(), S_ * ((1.0 - (-2.0 * A_ * dt).exp()) / (2.0 * A_)).sqrt());
    let mut vals = Vec::with_capacity(pairs);
    for _ in 0..pairs {
        let (mut rp, mut rm, mut ip, mut im) = (r0, r0, 0.0f64, 0.0f64);
        for _ in 0..steps {
            let z = rng.normal();
            let np = TH + (rp - TH) * decay + sd * z;
            let nm = TH + (rm - TH) * decay - sd * z;
            ip += (rp + np) / 2.0 * dt; im += (rm + nm) / 2.0 * dt; rp = np; rm = nm;
        }
        vals.push(((-ip).exp() + (-im).exp()) / 2.0);
    }
    let mut mean = 0.0; for x in &vals { mean += x; } mean /= pairs as f64;
    let mut ss = 0.0; for x in &vals { ss += (x - mean).powi(2); }
    (mean, (ss / (pairs - 1) as f64 / pairs as f64).sqrt())
}

fn ncdf(x: f64) -> f64 {                                // bell-curve area left of x, Simpson
    let n = 2000;
    let h = x / n as f64;
    let g = |u: f64| (-u * u / 2.0).exp() / (2.0 * PI).sqrt();
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(i as f64 * h); }
    let tot = g(0.0) + g(x) + s;
    0.5 + tot * h / 3.0
}

fn rate_at(t: f64, s: f64) -> (f64, f64) {              // mean and sd of r_t
    (TH + (R0 - TH) * (-A_ * t).exp(), s * ((1.0 - (-2.0 * A_ * t).exp()) / (2.0 * A_)).sqrt())
}

fn yld(r0: f64, t: f64, s: f64) -> f64 {
    if t > 0.0 { 100.0 * (-closed_g(r0, t, A_, s).ln() / t) } else { 100.0 * r0 }
}

fn main() {
    let mut rng = Rng(20260928);
    let p1 = closed(R0, T); let p2 = by_moments(R0, T);
    let (p3, b_ode) = by_ode(R0, T, 1000); let (p4, se) = by_paths(&mut rng, R0, T, 4000, 250);
    let b = (1.0 - (-A_ * T).exp()) / A_;
    let (m, v) = integral_moments(R0, T);
    let h = 1e-4;
    let dur_bump = -(closed(R0 + h, T) - closed(R0 - h, T)) / (2.0 * h) / p1;
    let (mu5, sd5) = rate_at(T, S_); let (mu5b, sd5b) = rate_at(T, 0.02);
    let (neg_1, neg_2) = (ncdf(-mu5 / sd5), ncdf(-mu5b / sd5b));
    let draws = 200000;
    let mut neg_count = 0;
    for _ in 0..draws { if mu5b + sd5b * rng.normal() < 0.0 { neg_count += 1; } }
    let rows: Vec<(&str, f64)> = vec![
        ("e^(-aT)", (-A_ * T).exp()), ("B(5), rate sensitivity in years", b), ("B(5) from the ODE", b_ode),
        ("level part (th - s^2/2a^2)(B - T)", (TH - S_ * S_ / (2.0 * A_ * A_)) * (b - T)),
        ("spread part s^2 B^2 / 4a", S_ * S_ * b * b / (4.0 * A_)),
        ("A(5)", p1.ln() + b * R0), ("-B(5) r0", -b * R0), ("log of price", p1.ln()),
        ("mean of area under r, 0 to 5", m), ("variance of that area", v),
        ("1 closed form P(0,5)", p1), ("2 Gaussian integral", p2), ("3 Runge-Kutta ODE", p3),
        ("4 paths, 4000 antithetic pairs", p4), ("  standard error", se),
        ("5-year yield, percent", yld(R0, T, S_)), ("long yield, percent", 100.0 * (TH - S_ * S_ / (2.0 * A_ * A_))),
        ("5-year yield move per point of r0", b / T), ("bumped rate sensitivity", dur_bump),
        ("expected r at 5y, percent", 100.0 * mu5), ("sd of r at 5y, percent", 100.0 * sd5),
        ("P(r5 < 0), s = 1%, percent", 100.0 * neg_1), ("P(r5 < 0), s = 2%, percent", 100.0 * neg_2),
        ("  simulated, 200000 draws, percent", 100.0 * neg_count as f64 / draws as f64),
        ("3-month zero at r0 = -0.5%", closed(-0.005, 0.25)),
        ("wrong: flat at today's 4%", (-R0 * T).exp()), ("wrong: flat at the 5% level", (-TH * T).exp()),
        ("wrong: expected path, no convexity", (-m).exp()), ("wrong: convexity sign flipped", (-m - v / 2.0).exp()),
        ("wrong: no reversion, a -> 0", (-R0 * T + S_ * S_ * T.powi(3) / 6.0).exp()),
        ("30-year zero", closed(R0, 30.0)), ("  30-year, no convexity", (-integral_moments(R0, 30.0).0).exp()),
        ("try: a = 0.03", closed_g(R0, T, 0.03, S_)), ("try: s = 3%", closed_g(R0, T, A_, 0.03)),
        ("try: r0 = 8%", closed(0.08, T)), ("try: r0 = 0%", closed(0.0, T)),
    ];
    for (name, val) in &rows { println!("{:<36} {:>12.6}", name, val); }
    println!();
    println!("5-year zero by today's rate, percent: price");
    for r in [-1i32, 0, 2, 4, 6, 8] { println!("  r0 = {:>2}%   {:.4}", r, closed(r as f64 / 100.0, T)); }
    println!();
    let mats = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let head: String = mats.iter().map(|t| format!("{:>6}", t)).collect();
    println!("yield curve, percent{}", head);
    for r in [2, 4, 8] {
        let row: String = mats.iter().map(|&t| format!("{:6.2}", yld(r as f64 / 100.0, t as f64, S_))).collect();
        println!("  r0 = {}%, s = 1%    {}", r, row);
    }
    let humps = [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20];
    let head: String = humps.iter().map(|t| format!("{:>6}", t)).collect();
    println!("hump, maturities   {}", head);
    let row: String = humps.iter().map(|&t| format!("{:6.2}", yld(0.045, t as f64, 0.03))).collect();
    println!("  r0 = 4.5%, s = 3%{}", row);

    assert!((p1 - p2).abs() < 1e-12, "closed form vs Gaussian integral");
    assert!((p1 - p3).abs() < 1e-10, "closed form vs Runge-Kutta on the bond equation");
    assert!((p4 - p1).abs() < 4.0 * se, "simulated paths within four standard errors");
    assert!((dur_bump - b_ode).abs() < 1e-6, "bumped sensitivity vs B from the ODE");
    assert!((neg_count as f64 / draws as f64 - neg_2).abs() < 0.002, "simulated negative-rate share vs normal CDF");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
e^(-aT)                                  0.223130
B(5), rate sensitivity in years          2.589566
B(5) from the ODE                        2.589566
level part (th - s^2/2a^2)(B - T)       -0.119183
spread part s^2 B^2 / 4a                 0.000559
A(5)                                    -0.119741
-B(5) r0                                -0.103583
log of price                            -0.223324
mean of area under r, 0 to 5             0.224104
variance of that area                    0.001561
1 closed form P(0,5)                     0.799856
2 Gaussian integral                      0.799856
3 Runge-Kutta ODE                        0.799856
4 paths, 4000 antithetic pairs           0.799848
  standard error                         0.000014
5-year yield, percent                    4.466481
long yield, percent                      4.944444
5-year yield move per point of r0        0.517913
bumped rate sensitivity                  2.589566
expected r at 5y, percent                4.776870
sd of r at 5y, percent                   1.258447
P(r5 < 0), s = 1%, percent               0.007357
P(r5 < 0), s = 2%, percent               2.885312
  simulated, 200000 draws, percent       2.928500
3-month zero at r0 = -0.5%               1.000748
wrong: flat at today's 4%                0.818731
wrong: flat at the 5% level              0.778801
wrong: expected path, no convexity       0.799232
wrong: convexity sign flipped            0.798608
wrong: no reversion, a -> 0              0.820438
30-year zero                             0.233919
  30-year, no convexity                  0.230692
try: a = 0.03                            0.817336
try: s = 3%                              0.804864
try: r0 = 8%                             0.721151
try: r0 = 0%                             0.887150

5-year zero by today's rate, percent: price
  r0 = -1%   0.9104
  r0 =  0%   0.8871
  r0 =  2%   0.8424
  r0 =  4%   0.7999
  r0 =  6%   0.7595
  r0 =  8%   0.7212

yield curve, percent     0     1     2     3     4     5     6     7     8     9    10
  r0 = 2%, s = 1%      2.00  2.41  2.74  3.01  3.24  3.43  3.59  3.72  3.84  3.94  4.02
  r0 = 4%, s = 1%      4.00  4.13  4.24  4.33  4.41  4.47  4.52  4.56  4.60  4.63  4.65
  r0 = 8%, s = 1%      8.00  7.59  7.25  6.97  6.74  6.54  6.37  6.23  6.11  6.01  5.92
hump, maturities        0     1     2     3     4     5     6     8    10    15    20
  r0 = 4.5%, s = 3%  4.50  4.56  4.58  4.60  4.60  4.60  4.60  4.59  4.58  4.55  4.54
ALL CHECKS PASS
```

The two outputs match line for line, simulations included, since both use the same generator and seed.

### Lean

Lean proves the card's three main facts, for every speed $a > 0$ and any level, shock size and today's rate.

- Suppose the short rate follows the card's model, with speed $a > 0$, in the pricing world. Then, for every maturity $T$, the area $I_T$ under its path is normal, with mean $m$ and variance $v$. The bond price, the average of $e^{-I_T}$, is $e^{A(T) - B(T)\,r_0}$.
- Suppose $a > 0$. Then the closed-form price equals 1 when no time is left, and it solves the bond equation of Step 4 at every rate.
- Suppose $a > 0$. Then the yield $R(T)$ tends to $R_\infty$ as $T$ grows, whatever today's rate.
- Take $\theta$ = 5 percent, $a$ = 0.3 and $\sigma$ = 1 percent. Then $\sigma^2/(2a^2) = 1/1800$ and $R_\infty = 89/1800$, below the level.

The decimal figures, such as the price 0.7999, and the simulated paths are left to the Python and Rust checks.

```lean
-- Vasicek: when the short rate is a Brownian motion pulled toward a level, the area under its path is normal and the zero-coupon bond price is exp(A(T) - B(T) r₀), that price solves the bond equation, and long yields settle at θ - σ²/(2a²).
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum

namespace VasicekModel

open MeasureTheory ProbabilityTheory Real Filter Topology
open scoped NNReal

/-! Setting. Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion
under `P` (here the pricing-world weighting of paths). `HasLaw X μ P` says the random variable
`X` has law `μ`, and `gaussianReal m v` is the normal law with mean `m` and variance `v`.

Mathlib has no Ito integral, so the Vasicek equation `dr = a(θ - r) dt + σ dW` is written path
by path: `r_t = r₀ + ∫₀ᵗ a(θ - r_u) du + σ W_t`, with continuous paths. -/

/-- `B(T) = (1 - e^(-aT))/a`: how much a change in today's rate moves the log bond price. -/
noncomputable def vasicekB (a T : ℝ) : ℝ := (1 - exp (-a * T)) / a

/-- `A(T) = (θ - σ²/(2a²))(B(T) - T) - σ² B(T)²/(4a)`: the part of the log bond price that does
not depend on today's rate. -/
noncomputable def vasicekA (a θ σ T : ℝ) : ℝ :=
  (θ - σ ^ 2 / (2 * a ^ 2)) * (vasicekB a T - T) - σ ^ 2 * vasicekB a T ^ 2 / (4 * a)

/-- The closed-form price `P(τ, r) = e^(A(τ) - B(τ) r)` of $1 paid after time `τ`, when the
short rate is `r` now. -/
noncomputable def vasicekPrice (a θ σ τ r : ℝ) : ℝ := exp (vasicekA a θ σ τ - vasicekB a τ * r)

/-- Helper: grid facts for the points `k T / n`. -/
lemma grid_facts {T : ℝ} (hT : 0 ≤ T) {n k : ℕ} (hk : k < n) :
    0 ≤ (k : ℝ) * T / n ∧ ((k + 1 : ℕ) : ℝ) * T / n ≤ T ∧
      ((k + 1 : ℕ) : ℝ) * T / n - (k : ℝ) * T / n = T / n ∧ 0 ≤ T / n := by
  have hn : (0 : ℝ) < n := by exact_mod_cast (lt_of_le_of_lt (Nat.zero_le k) hk)
  have hk1 : ((k + 1 : ℕ) : ℝ) ≤ n := by exact_mod_cast hk
  refine ⟨by positivity, ?_, ?_, by positivity⟩
  · rw [div_le_iff₀ hn]; nlinarith
  · push_cast; field_simp; ring

#print axioms grid_facts

/-- Helper: Riemann sums `∑ (∫ over the k-th piece of g) · h(point in the piece)` converge to
`∫₀ᵀ g h` for continuous `g`, `h`. -/
lemma riemann_tendsto {g h : ℝ → ℝ} (hg : Continuous g) (hh : Continuous h) {T : ℝ}
    (hT : 0 ≤ T) (p : ℕ → ℕ → ℝ)
    (hp : ∀ n k : ℕ, k < n → (k : ℝ) * T / n ≤ p n k ∧ p n k ≤ ((k + 1 : ℕ) : ℝ) * T / n) :
    Tendsto (fun n : ℕ => ∑ k ∈ Finset.range n,
      (∫ u in (k : ℝ) * T / n..((k + 1 : ℕ) : ℝ) * T / n, g u) * h (p n k)) atTop
      (𝓝 (∫ u in (0 : ℝ)..T, g u * h u)) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨C, hC⟩ :=
    (isCompact_Icc (a := (0 : ℝ)) (b := T)).exists_bound_of_continuousOn hg.continuousOn
  set M := |C| + 1 with hM
  have hMpos : 0 < M := by positivity
  have hgM : ∀ x ∈ Set.Icc 0 T, ‖g x‖ ≤ M := fun x hx =>
    (hC x hx).trans (by rw [hM]; linarith [le_abs_self C])
  set ε' := ε / (2 * M * (T + 1)) with hε'
  have hε'pos : 0 < ε' := by positivity
  obtain ⟨δ, hδ, hU⟩ := Metric.uniformContinuousOn_iff.1
    ((isCompact_Icc (a := (0 : ℝ)) (b := T)).uniformContinuousOn_of_continuous
      hh.continuousOn) ε' hε'pos
  obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
  refine ⟨N, fun n hn => ?_⟩
  have hNpos : (0 : ℝ) < N := lt_of_le_of_lt (div_nonneg hT hδ.le) hN
  have hnN : (N : ℝ) ≤ n := by exact_mod_cast hn
  have hnpos : (0 : ℝ) < n := lt_of_lt_of_le hNpos hnN
  have hn0 : n ≠ 0 := by rintro rfl; simp at hnpos
  have hstep : T / n < δ := by
    rw [div_lt_iff₀ hnpos]
    have := (div_lt_iff₀ hδ).1 hN
    nlinarith
  set t : ℕ → ℝ := fun k => (k : ℝ) * T / n with ht
  have hsplit : ∫ u in (0 : ℝ)..T, g u * h u =
      ∑ k ∈ Finset.range n, ∫ u in t k..t (k + 1), g u * h u := by
    rw [intervalIntegral.sum_integral_adjacent_intervals]
    · simp [t, hn0]
    · intro k _; exact (hg.mul hh).intervalIntegrable _ _
  rw [dist_eq_norm, hsplit, ← Finset.sum_sub_distrib]
  calc ‖∑ k ∈ Finset.range n, ((∫ u in t k..t (k + 1), g u) * h (p n k)
          - ∫ u in t k..t (k + 1), g u * h u)‖
      ≤ ∑ k ∈ Finset.range n, ‖(∫ u in t k..t (k + 1), g u) * h (p n k)
          - ∫ u in t k..t (k + 1), g u * h u‖ := norm_sum_le _ _
    _ ≤ ∑ k ∈ Finset.range n, M * ε' * (t (k + 1) - t k) := by
        apply Finset.sum_le_sum
        intro k hk
        rw [Finset.mem_range] at hk
        obtain ⟨h0, h1, h2, h3⟩ := grid_facts hT hk
        obtain ⟨hp1, hp2⟩ := hp n k hk
        have hle : t k ≤ t (k + 1) := by simp only [t]; linarith
        rw [← intervalIntegral.integral_mul_const]
        have hsub : (∫ u in t k..t (k + 1), g u * h (p n k)) - ∫ u in t k..t (k + 1), g u * h u
            = ∫ u in t k..t (k + 1), (g u * h (p n k) - g u * h u) :=
          (intervalIntegral.integral_sub
            ((hg.mul continuous_const).intervalIntegrable _ _)
            ((hg.mul hh).intervalIntegrable _ _)).symm
        rw [hsub]
        have := intervalIntegral.norm_integral_le_of_norm_le_const
          (a := t k) (b := t (k + 1)) (C := M * ε')
          (f := fun u => g u * h (p n k) - g u * h u) (fun x hx => ?_)
        · rwa [abs_of_nonneg (by linarith)] at this
        rw [Set.uIoc_of_le hle] at hx
        obtain ⟨hx1, hx2⟩ := hx
        have hxs : x ∈ Set.Icc 0 T := ⟨by simp only [t] at hx1; linarith, by
          simp only [t] at hx2; linarith⟩
        have hps : p n k ∈ Set.Icc 0 T := ⟨by linarith, by linarith⟩
        have hdist : dist (p n k) x < δ := by
          rw [Real.dist_eq, abs_lt]
          simp only [t] at hx1 hx2
          constructor <;> linarith
        have hd := hU (p n k) hps x hxs hdist
        rw [Real.dist_eq] at hd
        rw [← mul_sub, norm_mul, Real.norm_eq_abs (h (p n k) - h x)]
        exact mul_le_mul (hgM x hxs) hd.le (abs_nonneg _) hMpos.le
    _ = M * ε' * T := by
        rw [← Finset.mul_sum, Finset.sum_range_sub]; simp [t, hn0]
    _ < ε := by
        rw [hε']
        have hT1 : 0 < T + 1 := by linarith
        rw [show M * (ε / (2 * M * (T + 1))) * T = ε * (T / (2 * (T + 1))) by
          field_simp]
        have : T / (2 * (T + 1)) < 1 := by rw [div_lt_one (by positivity)]; linarith
        nlinarith

#print axioms riemann_tendsto

/-- Helper: summation by parts. -/
lemma sum_by_parts (F G : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ Finset.range n, F k * (G (k + 1) - G k) =
      F n * G n - F 0 * G 0 - ∑ k ∈ Finset.range n, (F (k + 1) - F k) * G (k + 1) := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, Finset.sum_range_succ, ih]; ring

#print axioms sum_by_parts

/-- Helper: the integral of `e^(a u)` over `[x, y]`. -/
lemma integral_exp_mul_eq {a : ℝ} (ha : a ≠ 0) (x y : ℝ) :
    ∫ u in x..y, exp (a * u) = (exp (a * y) - exp (a * x)) / a := by
  have h : ∀ u ∈ Set.uIcc x y, HasDerivAt (fun u => exp (a * u) / a) (exp (a * u)) u := by
    intro u _
    have := (((hasDerivAt_id' u).const_mul a).exp).div_const a
    refine this.congr_deriv ?_
    field_simp
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    ((by fun_prop : Continuous fun u => exp (a * u)).intervalIntegrable _ _)]
  ring

#print axioms integral_exp_mul_eq

/-- **The Vasicek bond formula** (the card's main claim). Let `W` be a Brownian motion, `a > 0`
the speed of the pull, `θ` the level, `σ` the size of the shocks and `r₀` today's rate. If the
short rate `r` solves `r_t = r₀ + ∫₀ᵗ a(θ - r_u) du + σ W_t` with continuous paths, then for
every maturity `T ≥ 0` the area `I_T = ∫₀ᵀ r_u du` under the path is normal, with mean
`m = θT + (r₀ - θ)B(T)` and variance `v = σ²/a² (T - B(T) - a B(T)²/2)`, and the zero-coupon
bond price, the average of `e^(-I_T)`, is `e^(A(T) - B(T) r₀)`: an exponential of a straight
line in today's rate. (The variance is never negative, so `toNNReal` only changes its type.) -/
theorem vasicek_zero_coupon_bond_price {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {a θ σ r₀ : ℝ} (ha : 0 < a)
    {r : ℝ → Ω → ℝ}
    (hr : ∀ᵐ ω ∂P, ContinuousOn (fun s => r s ω) (Set.Ici 0) ∧
      ∀ t : ℝ≥0, r t ω = r₀ + (∫ u in (0 : ℝ)..t, a * (θ - r u ω)) + σ * W t ω)
    (T : ℝ≥0) :
    HasLaw (fun ω => ∫ u in (0 : ℝ)..T, r u ω)
        (gaussianReal (θ * T + (r₀ - θ) * vasicekB a T)
          (σ ^ 2 / a ^ 2 * (T - vasicekB a T - a * vasicekB a T ^ 2 / 2)).toNNReal) P ∧
      ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P = vasicekPrice a θ σ T r₀ := by
  classical
  have ha0 : a ≠ 0 := ha.ne'
  have hPr : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  set Tr : ℝ := (T : ℝ) with hTr
  have hT0 : 0 ≤ Tr := T.2
  set X : ℝ := exp (a * Tr) with hX
  have hXpos : 0 < X := exp_pos _
  let wp : Ω → ℝ → ℝ := fun ω u => W u.toNNReal ω
  let f : ℝ → ℝ := fun u => (X - exp (a * u)) / a
  have hfc : Continuous f := by fun_prop
  let tg : ℕ → ℕ → ℝ := fun n k => (k : ℝ) * Tr / n
  have htg_nonneg : ∀ n k, 0 ≤ tg n k := fun n k => by positivity
  have htg_step : ∀ n k, tg n (k + 1) - tg n k = Tr / n := fun n k => by
    simp only [tg]; push_cast; ring
  have htg_le : ∀ n k, tg n k ≤ tg n (k + 1) := fun n k => by
    have := htg_step n k; have : 0 ≤ Tr / n := by positivity
    linarith
  let Y : ℕ → Ω → ℝ := fun n ω =>
    ∑ k ∈ Finset.range n, f (tg n k) * (wp ω (tg n (k + 1)) - wp ω (tg n k))
  let S : Ω → ℝ := fun ω => ∫ u in (0 : ℝ)..Tr, exp (a * u) * wp ω u
  let Vn : ℕ → ℝ := fun n =>
    ∑ k ∈ Finset.range n, (∫ _ in tg n k..tg n (k + 1), (1 : ℝ)) * f (tg n k) ^ 2
  let V : ℝ := ∫ u in (0 : ℝ)..Tr, 1 * f u ^ 2
  -- Riemann sums of the variance converge.
  have hVn : Tendsto Vn atTop (𝓝 V) :=
    riemann_tendsto (g := fun _ => (1 : ℝ)) (h := fun u => f u ^ 2) continuous_const
      (hfc.pow 2) hT0 (fun n k => tg n k) (fun n k _ => ⟨le_rfl, htg_le n k⟩)
  -- Pathwise convergence of the discrete sums.
  have hconv : ∀ᵐ ω ∂P, Tendsto (fun n => Y n ω) atTop (𝓝 (S ω)) := by
    filter_upwards [hW.cont, hW.eval_zero_ae_eq_zero] with ω hc h0
    have hwc : Continuous (wp ω) := hc.comp continuous_real_toNNReal
    have hR := riemann_tendsto (g := fun u => exp (a * u)) (h := wp ω) (by fun_prop) hwc hT0
      (fun n k => tg n (k + 1)) (fun n k _ => ⟨htg_le n k, le_rfl⟩)
    refine hR.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have hn' : (n : ℝ) ≠ 0 := by
      have : (1 : ℝ) ≤ n := by exact_mod_cast hn
      linarith
    simp only [Y]
    rw [sum_by_parts (fun k => f (tg n k)) (fun k => wp ω (tg n k)) n]
    have hfn : f (tg n n) = 0 := by
      have : tg n n = Tr := by simp only [tg]; field_simp
      simp only [this, f, X, sub_self, zero_div]
    have hw0 : wp ω (tg n 0) = 0 := by simp [wp, tg, h0]
    rw [hfn, hw0, zero_mul, mul_zero, sub_zero, zero_sub, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl (fun k _ => ?_)
    rw [integral_exp_mul_eq ha0]
    simp only [f, tg]
    ring
  -- Measurability.
  have hYmeas : ∀ n, AEMeasurable (Y n) P := fun n =>
    Finset.aemeasurable_fun_sum _ (fun k _ =>
      ((hW.aemeasurable _).sub (hW.aemeasurable _)).const_mul _)
  have hSmeas : AEMeasurable S P := aemeasurable_of_tendsto_metrizable_ae' hYmeas hconv
  -- Characteristic function of the discrete sums.
  have hchar : ∀ n (ξ : ℝ), ∫ ω, Complex.exp (ξ * Y n ω * Complex.I) ∂P = Complex.exp (((-(Vn n * ξ ^ 2 / 2) : ℝ) : ℂ)) := by
    intro n ξ
    let tt : Fin (n + 1) → ℝ≥0 := fun i => (tg n i).toNNReal
    have htt : Monotone tt := by
      intro i j hij
      apply Real.toNNReal_le_toNNReal
      simp only [tg]
      have : (i : ℝ) ≤ j := by exact_mod_cast hij
      gcongr
    have hind := (hW.hasIndepIncrements n tt htt).comp (fun i (x : ℝ) => f (tg n i) * x)
      (fun i => measurable_const.mul measurable_id)
    let Xf : Fin n → Ω → ℝ := fun i ω => f (tg n i) * (W (tt i.succ) ω - W (tt i.castSucc) ω)
    have hYeq : Y n = fun ω => ∑ i, Xf i ω := by
      funext ω
      simp only [Y, Xf]
      rw [← Fin.sum_univ_eq_sum_range]
      rfl
    have hmeasX : ∀ i, AEMeasurable (Xf i) P := fun i =>
      ((hW.aemeasurable _).sub (hW.aemeasurable _)).const_mul _
    have hc := iIndepFun.charFun_map_fun_sum_eq_prod (X := Xf) hmeasX hind
    have hlaw : ∀ i, P.map (Xf i) = gaussianReal (f (tg n i) * 0)
        (⟨f (tg n i) ^ 2, sq_nonneg _⟩ * nndist (tt i.succ : ℝ) (tt i.castSucc)) := fun i =>
      (gaussianReal_const_mul (hW.hasLaw_sub (tt i.succ) (tt i.castSucc)) _).map_eq
    have hfac : ∀ i : Fin n, charFun (P.map (Xf i)) ξ = Complex.exp
        (((-(f (tg n i) ^ 2 * (tg n (i + 1) - tg n i) * ξ ^ 2 / 2)) : ℝ) : ℂ) := by
      intro i
      have h1 : ((tt i.succ : ℝ)) = tg n (i + 1) := by
        simp only [tt]; rw [Real.coe_toNNReal _ (htg_nonneg _ _)]; simp
      have h2 : ((tt i.castSucc : ℝ)) = tg n i := by
        simp only [tt]; rw [Real.coe_toNNReal _ (htg_nonneg _ _)]; simp
      have h3 : ((⟨f (tg n i) ^ 2, sq_nonneg _⟩ * nndist (tt i.succ : ℝ) (tt i.castSucc) : ℝ≥0)
          : ℝ) = f (tg n i) ^ 2 * (tg n (i + 1) - tg n i) := by
        change f (tg n i) ^ 2 * ((nndist (tt i.succ : ℝ) (tt i.castSucc) : ℝ≥0) : ℝ) = _
        rw [coe_nndist, h1, h2, Real.dist_eq, abs_of_nonneg (by linarith [htg_le n i])]
      rw [hlaw i, charFun_gaussianReal]
      congr 1
      have h4 : (((⟨f (tg n i) ^ 2, sq_nonneg _⟩ * nndist (tt i.succ : ℝ) (tt i.castSucc) : ℝ≥0)
          : ℝ) : ℂ) = ((f (tg n i) ^ 2 * (tg n (i + 1) - tg n i) : ℝ) : ℂ) := by rw [h3]
      rw [h4]
      push_cast
      ring
    have hcξ := congrFun hc ξ
    rw [charFun_apply_real, integral_map (hYeq ▸ hYmeas n)
      (by fun_prop : Continuous fun x : ℝ => Complex.exp (ξ * x * Complex.I)).aestronglyMeasurable]
      at hcξ
    rw [hYeq, hcξ, Finset.prod_apply]
    simp_rw [hfac]
    rw [← Complex.exp_sum, ← Complex.ofReal_sum]
    congr 2
    simp only [Vn]
    rw [← Fin.sum_univ_eq_sum_range, Finset.sum_mul, Finset.sum_div, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    rw [intervalIntegral.integral_const, smul_eq_mul, mul_one]
    ring
  -- The limit variance.
  have hV0 : 0 ≤ V := intervalIntegral.integral_nonneg hT0 (fun u _ => by positivity)
  have hVval : V = (X ^ 2 * Tr - 2 * X * X / a + X ^ 2 / (2 * a)) / a ^ 2
      - (0 - 2 * X * 1 / a + 1 / (2 * a)) / a ^ 2 := by
    let K : ℝ → ℝ := fun u =>
      (X ^ 2 * u - 2 * X * exp (a * u) / a + exp (a * u) ^ 2 / (2 * a)) / a ^ 2
    have hK : ∀ u ∈ Set.uIcc 0 Tr, HasDerivAt K (1 * f u ^ 2) u := by
      intro u _
      have e := ((hasDerivAt_id' u).const_mul a).exp
      have h := ((((hasDerivAt_id' u).const_mul (X ^ 2)).sub ((e.const_mul (2 * X)).div_const a)).add
        ((e.pow 2).div_const (2 * a))).div_const (a ^ 2)
      refine h.congr_deriv ?_
      simp only [f]
      field_simp
      ring
    have := intervalIntegral.integral_eq_sub_of_hasDerivAt hK
      ((continuous_const.mul (hfc.pow 2)).intervalIntegrable _ _)
    show (∫ u in (0 : ℝ)..Tr, 1 * f u ^ 2) = _
    rw [this]
    simp only [K, mul_zero, exp_zero, X]
    ring
  have hXinv : exp (-a * Tr) = X⁻¹ := by rw [neg_mul, Real.exp_neg]
  have hkey : (σ * X⁻¹) ^ 2 * V = σ ^ 2 / a ^ 2 * (Tr - vasicekB a Tr - a * vasicekB a Tr ^ 2 / 2) := by
    rw [hVval]
    simp only [vasicekB, hXinv]
    field_simp
    ring
  -- The law of `S`.
  have hS : HasLaw S (gaussianReal 0 V.toNNReal) P := by
    refine ⟨hSmeas, ?_⟩
    apply Measure.ext_of_charFun
    funext ξ
    have hcont : Continuous fun x : ℝ => Complex.exp (ξ * x * Complex.I) := by fun_prop
    rw [charFun_gaussianReal, charFun_apply_real, integral_map hSmeas hcont.aestronglyMeasurable]
    have lim1 : Tendsto (fun n => ∫ ω, Complex.exp (ξ * Y n ω * Complex.I) ∂P) atTop
        (𝓝 (∫ ω, Complex.exp (ξ * S ω * Complex.I) ∂P)) := by
      refine tendsto_integral_of_dominated_convergence (fun _ => 1)
        (fun n => (hcont.measurable.comp_aemeasurable (hYmeas n)).aestronglyMeasurable)
        (integrable_const 1) (fun n => ae_of_all _ (fun ω => ?_)) ?_
      · rw [← Complex.ofReal_mul, Complex.norm_exp_ofReal_mul_I]
      · filter_upwards [hconv] with ω hω
        exact (hcont.tendsto _).comp hω
    have lim2 : Tendsto (fun n => ∫ ω, Complex.exp (ξ * Y n ω * Complex.I) ∂P) atTop
        (𝓝 (Complex.exp (((-(V * ξ ^ 2 / 2)) : ℝ) : ℂ))) := by
      simp_rw [hchar]
      have hc2 : Continuous fun x : ℝ => Complex.exp (((-(x * ξ ^ 2 / 2)) : ℝ) : ℂ) := by fun_prop
      exact (hc2.tendsto _).comp hVn
    rw [tendsto_nhds_unique lim1 lim2, Real.coe_toNNReal _ hV0]
    congr 1
    push_cast
    ring
  -- Pathwise: the area under the rate path.
  have hident : ∀ᵐ ω ∂P, (∫ u in (0 : ℝ)..Tr, r u ω) =
      (θ * Tr + (r₀ - θ) * vasicekB a Tr) + σ * X⁻¹ * S ω := by
    filter_upwards [hr, hW.cont] with ω hrω hc
    obtain ⟨hcont, heq⟩ := hrω
    have hwc : Continuous (wp ω) := hc.comp continuous_real_toNNReal
    let rt : ℝ → ℝ := fun u => r (max u 0) ω
    have hrt : Continuous rt :=
      hcont.comp_continuous (continuous_id.max continuous_const) (fun u => le_max_right u 0)
    let R : ℝ → ℝ := fun u => ∫ v in (0 : ℝ)..u, rt v
    have hcongr : ∀ u, 0 ≤ u → ∀ v ∈ Set.uIcc 0 u, r v ω = rt v := by
      intro u hu v hv
      rw [Set.uIcc_of_le hu] at hv
      simp [rt, max_eq_left hv.1]
    have hRr : ∀ u, 0 ≤ u → (∫ v in (0 : ℝ)..u, r v ω) = R u := fun u hu =>
      intervalIntegral.integral_congr (hcongr u hu)
    have hrel : ∀ u, 0 ≤ u → rt u = r₀ + a * θ * u - a * R u + σ * wp ω u := by
      intro u hu
      have h1 := heq u.toNNReal
      rw [Real.coe_toNNReal _ hu] at h1
      have h2 : (∫ v in (0 : ℝ)..u, a * (θ - r v ω)) = a * θ * u - a * R u := by
        rw [intervalIntegral.integral_congr (g := fun v => a * (θ - rt v))
          (fun v hv => by simp only [hcongr u hu v hv])]
        rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_sub
          intervalIntegrable_const (hrt.intervalIntegrable _ _)]
        simp only [intervalIntegral.integral_const, smul_eq_mul, sub_zero, R]
        ring
      have h3 : rt u = r u ω := by simp [rt, max_eq_left hu]
      rw [h3, h1, h2]
      simp only [wp]
      ring
    let G : ℝ → ℝ := fun u => exp (a * u) * (R u - (r₀ / a + θ * u - θ / a))
    have hG : ∀ u ∈ Set.uIcc 0 Tr, HasDerivAt G (exp (a * u) * (σ * wp ω u)) u := by
      intro u hu
      rw [Set.uIcc_of_le hT0] at hu
      have hR : HasDerivAt R (rt u) u := (hrt.integral_hasStrictDerivAt 0 u).hasDerivAt
      have e := ((hasDerivAt_id' u).const_mul a).exp
      have h := e.mul (hR.sub ((((hasDerivAt_id' u).const_mul θ).const_add (r₀ / a)).sub_const
        (θ / a)))
      refine h.congr_deriv ?_
      rw [hrel u hu.1]
      simp only [Pi.sub_apply]
      field_simp
      ring
    have hFTC := intervalIntegral.integral_eq_sub_of_hasDerivAt hG
      ((by fun_prop : Continuous fun u => exp (a * u) * (σ * wp ω u)).intervalIntegrable _ _)
    have hint : (∫ u in (0 : ℝ)..Tr, exp (a * u) * (σ * wp ω u)) = σ * S ω := by
      simp only [S]
      rw [← intervalIntegral.integral_const_mul]
      congr 1
      funext u
      ring
    rw [hint] at hFTC
    have hR0 : R 0 = 0 := by simp [R]
    simp only [G, hR0, mul_zero, exp_zero] at hFTC
    rw [hRr Tr hT0]
    simp only [vasicekB, hXinv]
    have hXX : X⁻¹ * X = 1 := inv_mul_cancel₀ hXpos.ne'
    linear_combination (-X⁻¹) * hFTC - (R Tr - θ * Tr - (r₀ - θ) / a) * hXX
  -- Combine.
  have hlaw2 := gaussianReal_const_add (gaussianReal_const_mul hS (σ * X⁻¹))
    (θ * Tr + (r₀ - θ) * vasicekB a Tr)
  have hvnn : 0 ≤ σ ^ 2 / a ^ 2 * (Tr - vasicekB a Tr - a * vasicekB a Tr ^ 2 / 2) :=
    hkey ▸ mul_nonneg (sq_nonneg _) hV0
  have hI : HasLaw (fun ω => ∫ u in (0 : ℝ)..Tr, r u ω)
      (gaussianReal (θ * Tr + (r₀ - θ) * vasicekB a Tr)
        (σ ^ 2 / a ^ 2 * (Tr - vasicekB a Tr - a * vasicekB a Tr ^ 2 / 2)).toNNReal) P := by
    convert hlaw2.congr hident using 2
    · ring
    · ext
      rw [Real.coe_toNNReal _ hvnn, ← hkey, NNReal.coe_mul, Real.coe_toNNReal _ hV0]
      rfl
  refine ⟨hI, ?_⟩
  have hm := mgf_gaussianReal hI (-1)
  simp only [mgf, neg_one_mul] at hm
  rw [hm, Real.coe_toNNReal _ hvnn]
  simp only [vasicekPrice, vasicekA]
  congr 1
  field_simp
  ring

/-- **The same answer from the bond equation** (the card's Step 4). With `a > 0`, the price
`P(τ, r) = e^(A(τ) - B(τ) r)` equals 1 at `τ = 0` for every rate `r`, and at every time left `τ`
and every rate `r` it satisfies
`∂P/∂τ = a(θ - r) ∂P/∂r + ½σ² ∂²P/∂r² - rP`. -/
theorem vasicek_price_solves_bond_equation {a : ℝ} (ha : 0 < a) (θ σ : ℝ) :
    (∀ r : ℝ, vasicekPrice a θ σ 0 r = 1) ∧
      ∀ τ r : ℝ, HasDerivAt (fun τ' => vasicekPrice a θ σ τ' r)
        (a * (θ - r) * deriv (fun x => vasicekPrice a θ σ τ x) r
          + 1 / 2 * σ ^ 2 * deriv (deriv (fun x => vasicekPrice a θ σ τ x)) r
          - r * vasicekPrice a θ σ τ r) τ := by
  have ha0 : a ≠ 0 := ha.ne'
  refine ⟨fun r => by simp [vasicekPrice, vasicekA, vasicekB], fun τ r => ?_⟩
  have hx : ∀ x, HasDerivAt (fun x => vasicekPrice a θ σ τ x)
      (-vasicekB a τ * vasicekPrice a θ σ τ x) x := by
    intro x
    have h := (((hasDerivAt_id' x).const_mul (vasicekB a τ)).const_sub (vasicekA a θ σ τ)).exp
    refine h.congr_deriv ?_
    simp only [vasicekPrice]
    ring
  have hd : deriv (fun x => vasicekPrice a θ σ τ x) = fun x => -vasicekB a τ * vasicekPrice a θ σ τ x :=
    funext fun x => (hx x).deriv
  have hdd : deriv (deriv (fun x => vasicekPrice a θ σ τ x)) r =
      vasicekB a τ ^ 2 * vasicekPrice a θ σ τ r := by
    rw [hd]
    rw [((hx r).const_mul (-vasicekB a τ)).deriv]
    ring
  rw [hdd, hd]
  have hB : ∀ s, HasDerivAt (fun s => vasicekB a s) (exp (-a * s)) s := by
    intro s
    have h := ((((hasDerivAt_id' s).const_mul (-a)).exp).const_sub 1).div_const a
    refine h.congr_deriv ?_
    field_simp
  have hA : HasDerivAt (fun s => vasicekA a θ σ s)
      ((θ - σ ^ 2 / (2 * a ^ 2)) * (exp (-a * τ) - 1)
        - σ ^ 2 * (2 * vasicekB a τ * exp (-a * τ)) / (4 * a)) τ := by
    have h := (((hB τ).sub (hasDerivAt_id' τ)).const_mul (θ - σ ^ 2 / (2 * a ^ 2))).sub
      ((((hB τ).pow 2).const_mul (σ ^ 2)).div_const (4 * a))
    refine h.congr_deriv ?_
    norm_num
  have hP : HasDerivAt (fun s => exp (vasicekA a θ σ s - vasicekB a s * r))
      (exp (vasicekA a θ σ τ - vasicekB a τ * r) *
        ((θ - σ ^ 2 / (2 * a ^ 2)) * (exp (-a * τ) - 1)
        - σ ^ 2 * (2 * vasicekB a τ * exp (-a * τ)) / (4 * a) - exp (-a * τ) * r)) τ :=
    (hA.sub ((hB τ).mul_const r)).exp
  refine hP.congr_deriv ?_
  simp only [vasicekPrice]
  generalize exp (vasicekA a θ σ τ - vasicekB a τ * r) = P
  have hBv : vasicekB a τ = (1 - exp (-a * τ)) / a := rfl
  rw [hBv]
  field_simp
  ring

/-- **The long yield.** With `a > 0`, the yield `-ln P(0,T)/T` of a zero maturing at `T` tends,
as `T` grows, to `R∞ = θ - σ²/(2a²)`, below the level `θ` by the convexity term, whatever
today's rate `r₀`. -/
theorem vasicek_long_yield {a : ℝ} (ha : 0 < a) (θ σ r₀ : ℝ) :
    Tendsto (fun T : ℝ => -log (vasicekPrice a θ σ T r₀) / T) atTop
      (𝓝 (θ - σ ^ 2 / (2 * a ^ 2))) := by
  have ha0 : a ≠ 0 := ha.ne'
  have hE : Tendsto (fun T : ℝ => exp (-a * T)) atTop (𝓝 0) := by
    have : Tendsto (fun T : ℝ => -a * T) atTop atBot := by
      have h := tendsto_neg_atTop_atBot.comp (tendsto_id.const_mul_atTop ha)
      refine h.congr (fun T => ?_)
      simp [neg_mul]
    exact Real.tendsto_exp_atBot.comp this
  have hBlim : Tendsto (fun T : ℝ => vasicekB a T) atTop (𝓝 ((1 - 0) / a)) :=
    (tendsto_const_nhds.sub hE).div_const a
  have hg : Tendsto (fun T : ℝ => vasicekB a T * r₀ - (θ - σ ^ 2 / (2 * a ^ 2)) * vasicekB a T
      + σ ^ 2 * vasicekB a T ^ 2 / (4 * a)) atTop
      (𝓝 ((1 - 0) / a * r₀ - (θ - σ ^ 2 / (2 * a ^ 2)) * ((1 - 0) / a)
        + σ ^ 2 * ((1 - 0) / a) ^ 2 / (4 * a))) :=
    ((hBlim.mul_const r₀).sub (hBlim.const_mul _)).add (((hBlim.pow 2).const_mul _).div_const _)
  have h2 := (hg.div_atTop tendsto_id).const_add (θ - σ ^ 2 / (2 * a ^ 2))
  rw [add_zero] at h2
  refine h2.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with T hT
  simp only [vasicekPrice, Real.log_exp, vasicekA, id]
  field_simp
  ring

/-! The card's exact numbers, as fractions: `θ = 5/100`, `a = 3/10`, `σ = 1/100`, `r₀ = 4/100`. -/

-- Step 0: a path that stays at 4 percent for five years has area 0.2.
example : (4 / 100 : ℚ) * 5 = 1 / 5 := by norm_num

-- Worked numbers: σ²/(2a²) = 0.0001/0.18 = 1/1800, and the spread part divides by 4a = 1.2.
example : ((1 : ℚ) / 100) ^ 2 / (2 * (3 / 10) ^ 2) = 1 / 1800 ∧ 4 * (3 / 10 : ℚ) = 6 / 5 := by
  norm_num

-- The long yield θ - σ²/(2a²) = 0.05 - 1/1800 = 89/1800 = 4.9444 percent, under the 5% level.
example : (5 / 100 : ℚ) - ((1 : ℚ) / 100) ^ 2 / (2 * (3 / 10) ^ 2) = 89 / 1800 ∧
    (89 / 1800 : ℚ) < 5 / 100 := by
  norm_num

#print axioms vasicek_zero_coupon_bond_price
#print axioms vasicek_price_solves_bond_equation
#print axioms vasicek_long_yield

end VasicekModel
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'VasicekModel.grid_facts' depends on axioms: [propext, Classical.choice, Quot.sound]
'VasicekModel.riemann_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'VasicekModel.sum_by_parts' depends on axioms: [propext, Classical.choice, Quot.sound]
'VasicekModel.integral_exp_mul_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'VasicekModel.vasicek_zero_coupon_bond_price' depends on axioms: [propext, Classical.choice, Quot.sound]
'VasicekModel.vasicek_price_solves_bond_equation' depends on axioms: [propext, Classical.choice, Quot.sound]
'VasicekModel.vasicek_long_yield' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A weak pull.** Speed $a$ from 0.3 to 0.03. The rate barely moves off 4 percent in five years, so the price nears the flat-4-percent $0.8187: it comes out at $0.8173.
> - **Bigger shocks.** $\sigma$ from 1 to 3 percent. More convexity, a dearer bond: $0.8049.
> - **A high start.** $r_0$ = 8 percent: $0.7212, and the curve falls, as in the first chart. At $r_0$ = 0: $0.8871.
> - **Longer.** $T$ = 30: $0.2339; without the convexity term, 0.2307.

---

## The usual mistake

> [!warning]
> **Discounting at the average rate.** The expected rate path gives an average area of 0.2241 and a discount factor of 0.7992. The bond is the average of discount factors, 0.7999. For five years the gap is small; for thirty years it is 0.2307 against 0.2339. The curve of $e^{-I}$ bends, so the average of the discount factors beats the discount factor of the average.
>
> - **Taking the maturity as the rate sensitivity.** A 1-point rise in today's rate cuts the 5-year zero's price by about $B(5)$ = 2.59 percent, not 5 percent. The pull means today's rate is remembered for 2.59 years only.
> - **Reading the level as the long yield.** The long yield is 4.94 percent, not 5, because convexity pulls it down by $\sigma^2/(2a^2)$.
> - **Reading the level as a forecast.** $\theta$ is fitted to bond prices, so it includes the premium investors charge for rate risk. A forecast of rates needs the real-world level, which differs by the market price of risk.
> - **Ruling out negative rates.** At 1 percent volatility the chance is small, 0.0074 percent at five years. At 2 percent it is 2.89 percent, enough to misprice an option that pays when rates are low.

---

## Where you meet it in real life

- **Bank and insurance balance sheets.** Asset-liability models project thousands of short-rate paths to value deposits and pension promises; Vasicek and its time-varying cousin are the usual first choice because every bond price along every path is closed-form.
- **Negative-rate markets.** Euro-area, Swiss and Japanese short rates sat below zero for years after 2014. A normal model prices those bonds without special handling; a model with rates kept positive cannot.
- **Bond options.** Because the log bond price is normal, a bond option has a Black-Scholes-style formula: [Bond options](05-bond-options-and-jamshidians-trick.md).
- **Credit portfolios.** The Basel capital formula carries Vasicek's name from a different paper, on loan defaults driven by one common factor. Same author, a different model.

> **Say it back**
> Vasicek models the short rate as a random walk pulled toward a level at a fixed speed, with normal shocks of fixed size. The rate is then normal at every date, and so is the area under its path. A zero is the average of e raised to minus that area, which for a normal area is a closed form: an exponential of a straight line in today's rate. The slope, $B(T)$, is how long today's rate is remembered, 2.59 years for the 5-year zero, which costs $0.7999. The price of the formula is normal rates: they can go negative, and one shock moves every yield together.

---

## What this builds on

- [A short-rate model](01-the-term-structure-equation.md): a bond as the pricing-world average of the path's discount factor, and the equation every bond price satisfies.
- [Mean reversion](../../11-Stochastic%20processes%20and%20calculus/06-Ito%20Calculus/05-ornstein-uhlenbeck-and-cir-processes.md): the pulled random walk itself, with the mean and spread of the rate at each date used in Step 1.

## Where this goes next

- [Cox-Ingersoll-Ross](03-cox-ingersoll-ross-model.md): shocks that shrink as the rate nears zero, keeping it positive, still with closed-form bonds.
- [Hull-White](04-hull-white-model.md): Vasicek with a level that moves over time, chosen to reproduce today's market curve exactly.

Vasicek's four numbers cannot reproduce the curve the market quotes today, so its bonds disagree with real prices; how to keep its closed forms and match that curve is [Hull-White](04-hull-white-model.md).

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Vasicek, Oldřich. "An equilibrium characterization of the term structure." *Journal of Financial Economics* 5(2), 1977, 177–188. [DOI](https://doi.org/10.1016/0304-405X(77)90016-2). The original paper: the mean-reverting normal rate and the closed-form bond price.
- Brigo, Damiano, and Fabio Mercurio. *Interest Rate Models: Theory and Practice*, 2nd ed. Springer, 2006. [Publisher page](https://doi.org/10.1007/978-3-540-34604-3). Chapter 3 derives Vasicek's bond price, its curve shapes and its bond options.
- Duffie, Darrell, and Rui Kan. "A yield-factor model of interest rates." *Mathematical Finance* 6(4), 1996, 379–406. [DOI](https://doi.org/10.1111/j.1467-9965.1996.tb00123.x). Which short-rate models give log bond prices that are straight lines in the rate: the affine family.
