# Regression error bars: standard errors, t-tests and prediction intervals for a fitted line

[Syllabus](../../../SYLLABUS.md) → [Probability and statistics](../README.md) → [Regression](../README.md#s09) → Regression error bars

---

## General Overview

A café logged two numbers on ten summer days: the midday temperature and the iced coffees sold.

| Temperature, °C | 16 | 18 | 20 | 22 | 24 | 26 | 28 | 30 | 32 | 34 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Iced coffees sold | 37 | 33 | 34 | 31 | 35 | 49 | 40 | 53 | 50 | 38 |

The least-squares line through these points ([Least squares](01-least-squares-regression.md)) says sales are 20 coffees plus 0.8 for every degree. The owner asks the plain question: is the slope different from zero, or could a flat line have produced these ten days by luck?

Ten other days would give a different line. The slope is an estimate, and it needs an error bar. Here the error bar is 0.36 coffees per degree, the slope's standard error: the typical distance between a fitted slope and the true one.

The slope sits 2.22 standard errors above zero. With only ten days that is not quite enough: the 95 percent interval for the slope runs from −0.03 to 1.63, and it contains zero. The p-value is 0.057. That is not the chance that heat does nothing. It says a truly flat café would produce a slope this far from zero, either way, about 1 time in 17.

The same machinery forecasts. On a 30 °C day the line predicts 44 coffees. The 95 percent interval for the average over many such days runs from 37.7 to 50.3. For one particular day it runs from 27.6 to 60.4, because a single day carries its own noise on top of the line's uncertainty.

**The fitted slope is a weighted sum of the days' noise, so its spread can be computed exactly; estimate the noise from the leftovers, divide, and the ratio follows Student's t law, which gives the test, the interval for the slope, and, with one extra term for a new day's own noise, the prediction interval.**

**What kind of fact this is:** a theorem inside a model. The model is the assumption that each day's sales are the line plus independent normal noise of one fixed spread; given it, the variances and the t law are proved on this card in Why it works. The intervals and the test built on them are a method.

### The picture: ten days, the line, and its two bands

<p align="center"><img src="../figures/regression-inference.svg" alt="Ten days of iced-coffee sales against midday temperature, to scale, with the fitted line, the shaded 95 percent band for mean sales and the dashed 95 percent band for one new day" width="420"></p>

The ten circles are the days, drawn to scale. The solid line is the fit. The shaded band is the 95 percent interval for mean sales at each temperature; it is narrowest at 25 °C, the average temperature, and flares towards the ends. The dashed lines bound the 95 percent interval for one new day. Each band is 95 percent at one temperature at a time, not for the whole line at once. Every coordinate is printed by both checks on the lines starting `figure,`.

---

## The formula

Notation first. Greek letters are the true, unknown numbers; a hat marks an estimate of one from the data (shelf 07). Capital $Y_i$ is day i's sales before the day happens, a random variable; lower-case $y_i$ is the number recorded. The model says each day is the true line plus noise drawn from the normal law with mean 0 and variance $\sigma^2$, written $N(0, \sigma^2)$:

$$Y_i = \beta_0 + \beta_1 x_i + \varepsilon_i, \qquad \varepsilon_1, \dots, \varepsilon_n \text{ independent, each } N(0, \sigma^2).$$

Two sums carry everything. $S_{xx} = \sum (x_i - \bar x)^2$ measures how spread out the temperatures are, with $\bar x$ their average. SSE is the sum of the squared leftovers, each day's recorded sales minus the line's value. Then:

$$\mathrm{Var}(\hat\beta_1) = \frac{\sigma^2}{S_{xx}}, \qquad s^2 = \frac{\mathrm{SSE}}{n-2}, \qquad \mathrm{SE}(\hat\beta_1) = \frac{s}{\sqrt{S_{xx}}}, \qquad t = \frac{\hat\beta_1 - \beta_1}{\mathrm{SE}(\hat\beta_1)} \sim t_{n-2}.$$

**Read it aloud:** the slope wobbles by the noise's spread divided by the root of how spread out the temperatures are; replace the unknown noise spread by the one estimated from the leftovers, with n − 2 in the divisor, and the slope's distance from the truth, counted in standard errors, follows Student's t law with n − 2 degrees of freedom.

Write $t_*$ for the 95 percent cutoff of that law: the number with 95 percent of its area between $-t_*$ and $t_*$. The interval for the slope, and the test of "slope zero", are that sentence turned round:

$$\hat\beta_1 \pm t_* \,\mathrm{SE}(\hat\beta_1), \qquad \text{reject slope zero when } \left|\hat\beta_1\right| / \mathrm{SE}(\hat\beta_1) > t_*.$$

At a new temperature $x_0$ the line predicts $\hat y_0 = \hat\beta_0 + \hat\beta_1 x_0$, and two intervals come from one number $h_0$:

$$h_0 = \frac1n + \frac{(x_0 - \bar x)^2}{S_{xx}}, \qquad \text{mean sales: } \hat y_0 \pm t_*\, s\sqrt{h_0}, \qquad \text{one new day: } \hat y_0 \pm t_*\, s\sqrt{1 + h_0}.$$

**Read it aloud:** the line is least sure far from the average temperature; one new day adds its own full noise, the 1 under the root.

The intercept is the line's height at 0 °C, so its standard error is the mean-sales one with $x_0 = 0$: $\mathrm{SE}(\hat\beta_0) = s\sqrt{1/n + \bar x^2/S_{xx}}$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x_i$, $y_i$, $Y_i$, $n$ | day i's temperature; its sales as recorded; its sales as a random variable; the number of days | 16 °C and 37 coffees on day 1; n = 10 | more days: every error bar shrinks |
| $\bar x$, $\bar y$, $\bar Y$ | average temperature, average sales; $\bar Y$ is the average sales as a random variable | 25 °C, 40 coffees | — |
| $S_{xx}$ | sum of squared distances of the temperatures from their average: how spread out the days were | 330 | the slope's error bar shrinks as one over its root |
| $S_{yy}$ | sum of squared distances of the sales from their average: the flat line's squared leftovers | 554 | with SSE held, the slope removes more and F rises |
| $F$ | the F ratio: what the slope removes from the flat line's squared leftovers, $S_{yy} - \mathrm{SSE}$, divided by $s^2$ | 4.929 | t rises with it, since F is $t^2$ |
| $w_i$ | the weight day i gets in the fitted slope, $(x_i - \bar x)/S_{xx}$ | −0.0273 at 16 °C, 0.0273 at 34 °C | — |
| $\beta_0$, $\beta_1$ | the true intercept and slope, never seen | unknown | — |
| $\hat\beta_0$, $\hat\beta_1$ | the fitted intercept and slope | 20 coffees, 0.8 coffees per degree | a bigger slope: a bigger t |
| $\varepsilon_i$, $\bar\varepsilon$, $\sigma$ | day i's noise; the average of the ten noises; the noise's true spread (standard deviation) | unknown; the simulation uses 6.546 | every error bar grows in step |
| $e_i$, $\mathrm{SSE}$ | day i's leftover (residual), recorded minus fitted; the sum of their squares | 4.2 on day 1; 342.8 | — |
| $s$ | the estimated noise spread, the root of SSE over n − 2 | 6.546 coffees | every interval widens in step |
| $\mathrm{SE}$ | standard error: the estimated standard deviation of an estimate | 0.3603 for the slope, 9.243 for the intercept | t falls |
| $t$, $t_*$ | the slope in standard errors; the 95 percent cutoff of Student's t on n − 2 degrees of freedom | 2.220; 2.306, on 8 degrees | more degrees: the cutoff falls towards 1.96 |
| $x_0$, $\hat y_0$, $h_0$, $Y_0$ | a new temperature; the line's forecast there; its distance factor; that day's actual sales, still to come | 30 °C; 44 coffees; 0.1758; unknown | $x_0$ far from 25: both intervals widen |
| $u_k$, $Z_k$ | in the folded proof: n perpendicular directions of length one, the first along the 1s and the second along the temperature gaps; the noise measured along direction k, in units of σ | — | — |

### When it holds

- **The mean really is a straight line.** If sales level off in the heat, the leftovers carry the bend, s is inflated, and the forecast at 34 °C is biased in a way no interval reports.
- **The days are independent.** If busy days follow busy days (a day-to-day correlation of 0.8) and the ten days run in temperature order, a truly flat café is declared "sloped" 40 percent of the time instead of 5. The checks print that rate.
- **One noise spread for every temperature.** If hot days are noisier, the single s is too small at 34 °C and too large at 16 °C, and the prediction band is wrong at both ends.
- **Normal noise.** With ten days the t law needs it. With many days the central limit theorem makes the slope nearly normal anyway, so the slope's interval survives; the prediction interval for one day does not, because one day's noise is never averaged.
- **The temperatures are fixed, not chosen after looking at sales.** Picking the days that fit best makes every error bar a lie.

---

## Why it works

### Step 0: the slope is a weighted sum of noise

The fitted slope is fixed arithmetic on the ten sales figures, and each figure is the true line plus noise. So the fitted slope is the true slope plus a weighted sum of the ten noises. The spread of a weighted sum of independent noises is known exactly: each weight enters squared ([Variance](../02-Random%20Variables/03-variance-and-standard-deviation.md)), and independent variances add ([Two variables at once](../02-Random%20Variables/04-joint-distributions-and-covariance.md)). Everything on this card is that one observation, worked out.

### Step 1: the slope's weights

The least-squares slope is $\hat\beta_1 = \sum (x_i - \bar x)\, y_i / S_{xx}$. Written as weights, $\hat\beta_1 = \sum w_i Y_i$ with $w_i = (x_i - \bar x)/S_{xx}$. The 16 °C day gets weight −9/330, which is −0.0273; the 34 °C day gets +0.0273; the days at 24 and 26 °C barely count. Days far from the average temperature steer the slope.

The weights add to zero, and $\sum w_i x_i = 1$. Put the model in: $\sum w_i(\beta_0 + \beta_1 x_i) = \beta_1$. So $\hat\beta_1 = \beta_1 + \sum w_i \varepsilon_i$. The noise averages to zero, so the fitted slope is right on average: unbiased.

### Step 2: the variances add

Independent noises add their variances, each scaled by its weight squared: $\mathrm{Var}(\hat\beta_1) = \sigma^2 \sum w_i^2 = \sigma^2 S_{xx}/S_{xx}^2 = \sigma^2/S_{xx}$. Spreading the temperatures out, a bigger $S_{xx}$, is the cheap way to a tight slope: ten days from 16 to 34 °C beat ten days from 24 to 26.

The line's height at $x_0$ is $\hat y_0 = \bar Y + \hat\beta_1 (x_0 - \bar x)$. The average $\bar Y$ has variance $\sigma^2/n$. Its covariance with the slope is $\sigma^2 \sum w_i / n = 0$, because the weights add to zero. So the two variances add: $\mathrm{Var}(\hat y_0) = \sigma^2 h_0$. A new day's sales $Y_0$ bring fresh noise, independent of the ten, so $\mathrm{Var}(Y_0 - \hat y_0) = \sigma^2 (1 + h_0)$. That is the 1 under the root.

### Step 3: estimate the noise, dividing by n − 2

The noise spread is unknown. The leftovers estimate it. Fitting two numbers, an intercept and a slope, forces two constraints on the leftovers: they add to zero, and they have no slope against temperature. Only n − 2 of them are free. The sum of their squares is too small by exactly two noise variances on average: the expected SSE is $(n-2)\sigma^2$. Dividing by n − 2 makes $s^2$ right on average. Dividing by n gives s = 5.855 here instead of 6.546; in the simulation that divisor averages 34.25 in squares when the truth is 42.85.

### Step 4: the ratio is Student's t

The slope is a weighted sum of normals, so it is normal: $(\hat\beta_1 - \beta_1)/(\sigma/\sqrt{S_{xx}})$ is standard normal. The leftovers' sum of squares over $\sigma^2$ is a chi-square variable with n − 2 degrees of freedom, and it is independent of the slope. A standard normal divided by the root of an independent chi-square over its degrees is Student's t by definition ([The reference distributions](../07-Sampling%20and%20Estimation/03-chi-square-t-and-f-distributions.md)). The unknown σ cancels between top and bottom. What is left uses only data: that is t. The same argument with $\hat y_0$ or $Y_0 - \hat y_0$ on top gives the two forecast intervals.

<details>
<summary>Detailed proof</summary>

**The expected SSE.** The leftovers satisfy $\mathrm{SSE} = S_{yy} - \hat\beta_1^2 S_{xx}$, where $S_{yy} = \sum (Y_i - \bar Y)^2$: the flat line's squared leftovers, minus what the slope removes. Under the model, $Y_i - \bar Y = \beta_1(x_i - \bar x) + (\varepsilon_i - \bar\varepsilon)$, so $E[S_{yy}] = \beta_1^2 S_{xx} + (n-1)\sigma^2$, using the sample-variance fact $E\big[\sum(\varepsilon_i - \bar\varepsilon)^2\big] = (n-1)\sigma^2$. And $E[\hat\beta_1^2] = \mathrm{Var}(\hat\beta_1) + \beta_1^2 = \sigma^2/S_{xx} + \beta_1^2$. Subtract: $E[\mathrm{SSE}] = (n-2)\sigma^2$.

**Chi-square, and independent of the slope.** Write the ten days as a list of ten numbers, a vector. Take $u_1 = (1, \dots, 1)/\sqrt n$ and $u_2 = (x_1 - \bar x, \dots, x_n - \bar x)/\sqrt{S_{xx}}$. They have length one and are at right angles, since the deviations add to zero. Complete them with $u_3, \dots, u_n$ to a set of n mutually perpendicular unit vectors. Set $Z_k = (u_k \cdot \varepsilon)/\sigma$. A rotation of independent standard normals is again independent standard normals ([Multivariate normal](../05-Transformations%20and%20Joint%20Laws/06-multivariate-normal.md)), so $Z_1, \dots, Z_n$ are independent standard normals.

The fitted values are the projection of the data onto the plane spanned by the first two unit vectors; that is what least squares does. The true line $\beta_0 + \beta_1 x$ already lies in that plane, so the leftovers are the part of the noise off the plane: $e = \sigma \sum_{k \ge 3} Z_k u_k$. Hence $\mathrm{SSE}/\sigma^2 = Z_3^2 + \dots + Z_n^2$, a chi-square with n − 2 degrees.

Meanwhile $\hat\beta_1 - \beta_1 = \sigma Z_2/\sqrt{S_{xx}}$ and $\bar Y = \beta_0 + \beta_1 \bar x + \sigma Z_1/\sqrt n$ use only the first two coordinates. Different independent coordinates: independent. A new day's noise is independent of all n of them, which covers the prediction interval.

</details>

### Step 5: the test, the interval and the F ratio are one fact

"Zero lies outside $\hat\beta_1 \pm t_*\mathrm{SE}$" and "$\left|\hat\beta_1\right|/\mathrm{SE} > t_*$" are the same inequality rearranged. So the test at 5 percent and the 95 percent interval always agree. Here t = 2.220 falls short of 2.306, and zero sits just inside the interval.

A second road reaches the same t. Drop the slope and fit a flat line at 40 coffees: its squared leftovers are $S_{yy} = 554$. The slope removes 554 − 342.8 = 211.2 of that. Divided by $s^2$ = 42.85, the removal is 4.929, the F ratio. It equals $t^2$ exactly, because the removal is $\hat\beta_1^2 S_{xx}$ and $s^2/S_{xx}$ is $\mathrm{SE}^2$. The matrix form of the same variances, $\sigma^2$ times the inverse of a 2 × 2 table of sums, is the route [Multiple regression](03-multiple-regression-and-gauss-markov.md) takes to many predictors; the checks compute it as a third road.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| averages | 250 / 10 and 400 / 10 | 25 °C and 40 coffees |
| $S_{xx}$ | 81 + 49 + 25 + 9 + 1, doubled | 330 |
| cross sum | −9 × 37 − 7 × 33 − … + 9 × 38 | 264 |
| slope | 264 / 330 | **0.8** coffees per degree |
| intercept | 40 − 0.8 × 25 | 20 |
| leftovers | 37 − 32.8, 33 − 34.4, … , 38 − 47.2 | 4.2, −1.4, −2.0, −6.6, −4.2, 8.2, −2.4, 9.0, 4.4, −9.2 |
| SSE | 17.64 + 1.96 + … + 84.64 | 342.8 |
| $s^2$, s | 342.8 / 8, then the root | 42.85; 6.546 |
| slope's SE | 6.546 / √330 = 6.546 / 18.166 | 0.3603 |
| t | 0.8 / 0.3603 | **2.220** |
| cutoff, 8 degrees | table of Student's t, or the checks' bisection | 2.306 |
| slope interval | 0.8 ± 2.306 × 0.3603 = 0.8 ± 0.831 | **−0.031 to 1.631** |
| p-value | area of t on 8 degrees beyond ±2.220 | 0.057 |
| intercept's SE | 6.546 × √(0.1 + 625/330) = 6.546 × √1.9939 | 9.243 |
| at 30 °C | 20 + 0.8 × 30; h = 0.1 + 25/330 | 44 coffees; 0.1758 |
| mean sales | 44 ± 2.306 × 6.546 × √0.1758 = 44 ± 6.33 | **37.67 to 50.33** |
| one new day | 44 ± 2.306 × 6.546 × √1.1758 = 44 ± 16.37 | **27.63 to 60.37** |

Ten days put the slope at 0.8 coffees per degree with a standard error of 0.36. That is suggestive, and it is not settled at 95 percent: a flat café throws a slope this steep 5.7 percent of the time. On a 30 °C day, plan stock for anything from about 28 to 60.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| The normal cutoff 1.96 instead of t on 8 degrees | p = 0.026, "significant"; in truth the rule fires for 8.6 percent of flat cafés, not 5 | s is itself a guess from ten days, and t's heavier tails pay for it |
| SSE divided by n instead of n − 2 | s = 5.855, t = 2.482, p = 0.038 | two leftovers were spent fitting the line; this s averages 34.25 in squares against the true 42.85 |
| The mean-sales interval used for one day | 37.67 to 50.33 holds a new day's sales 60 percent of the time | the new day's own noise, the 1 under the root, was left out |
| Busy days follow busy days, correlation 0.8 | a truly flat café "shows a slope" 40 percent of the time | independence dropped: ten correlated days carry the information of far fewer |

---

## Code, from first principles, and it actually runs

The scripts fit the ten days, then reach every number by at least two roads. The slope's standard error comes from the deviations and from the inverse of the 2 × 2 table of raw sums; t comes from the slope and, as $t^2$, from the F ratio of dropping the slope; the p-value and the cutoff come from a finite series for Student's t and from Simpson's rule on its density.

A seeded simulation then refits 20,000 imaginary cafés whose true line is 20 + 0.8x with noise spread 6.546, and counts how often each interval holds its target; a second run drops independence. Random numbers come from SplitMix64 and the Box-Muller recipe, written out in both languages, so Python and Rust draw the same stream.

### Python

```python
# Regression error bars -- the check behind the card.  Standard library only; nothing imported
# holds the answer.  A cafe logged midday temperature and iced coffees sold on ten summer days.
# Roads: the slope's standard error from deviations and from the 2x2 matrix inverse; t from the
# slope and F from dropping the slope; t tail areas from a finite series and from Simpson's rule;
# a seeded simulation (SplitMix64, Box-Muller) that refits thousands of cafes and counts coverage.
from math import sqrt, atan, sin, cos, log, pi

X = [16, 18, 20, 22, 24, 26, 28, 30, 32, 34]          # midday temperature, degrees C
Y = [37, 33, 34, 31, 35, 49, 40, 53, 50, 38]          # iced coffees sold
N, NU, X0 = len(X), len(X) - 2, 30                     # ten days, 8 degrees of freedom, a 30 C day

def fit(x, y):                                         # least squares from deviations
    n = len(x); mx, my = sum(x) / n, sum(y) / n
    sxx = sum((a - mx) ** 2 for a in x); sxy = sum((a - mx) * b for a, b in zip(x, y))
    b1 = sxy / sxx; b0 = my - b1 * mx
    sse = sum((b - b0 - b1 * a) ** 2 for a, b in zip(x, y))
    return b0, b1, sse, sxx, mx

def t_inside(t, v):                                    # P(|T| <= t), even v: finite series in the angle
    th = atan(t / sqrt(v)); c, term, tot = cos(th) ** 2, 1.0, 1.0
    for k in range(1, v // 2):
        term *= c * (2 * k - 1) / (2 * k); tot += term
    return sin(th) * tot

def simpson(f, a, b, m=2000):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m)))

def t_dens(t, v=8):                                    # Gamma(9/2) / (sqrt(8 pi) Gamma(4)), Gammas by hand
    g = 3.5 * 2.5 * 1.5 * 0.5 * sqrt(pi) / (sqrt(v * pi) * 6.0)
    return g * (1 + t * t / v) ** (-(v + 1) / 2)

def z_dens(z): return 2.718281828459045 ** (-z * z / 2) / sqrt(2 * pi)

def bisect(f, target, lo, hi):
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return (lo + hi) / 2

b0, b1, sse, sxx, mx = fit(X, Y)
s = sqrt(sse / NU); se1 = s / sqrt(sxx); se0 = s * sqrt(1 / N + mx ** 2 / sxx)
sx, sxx_raw = sum(X), sum(a * a for a in X)            # road 2: (X'X)^-1 from raw sums, no deviations
g22 = N / (N * sxx_raw - sx * sx); g11 = sxx_raw / (N * sxx_raw - sx * sx); g12 = -sx / (N * sxx_raw - sx * sx)
t = b1 / se1
syy = sum((b - sum(Y) / N) ** 2 for b in Y)            # road 2 for t: the flat line's SSE against the fitted one
F = (syy - sse) / (sse / NU)
tq = bisect(lambda q: t_inside(q, NU), 0.95, 0.0, 20.0)
p_ser, p_simp = 1 - t_inside(t, NU), 1 - 2 * simpson(t_dens, 0.0, t)
h = 1 / N + (X0 - mx) ** 2 / sxx; h_mat = g11 + 2 * X0 * g12 + X0 * X0 * g22
yhat0, hw_m, hw_p = b0 + b1 * X0, tq * s * sqrt(h), tq * s * sqrt(1 + h)
print("data, temperature C  " + " ".join(f"{a:>3}" for a in X))
print("data, iced coffees   " + " ".join(f"{b:>3}" for b in Y))
print(f"sums: mean x {mx:.4f}, mean y {sum(Y) / N:.4f}, Sxx {sxx:.4f}, Sxy {b1 * sxx:.4f}, Syy {syy:.4f}")
print(f"fit: slope {b1:.4f} coffees per degree, intercept {b0:.4f}")
print("residuals " + " ".join(f"{b - b0 - b1 * a:.1f}" for a, b in zip(X, Y)))
print(f"SSE {sse:.4f}; s^2 = SSE/8 {s * s:.4f}; s {s:.4f}")
print(f"hand: sqrt(Sxx) {sqrt(sxx):.4f}; weights at 16 and 34 C {(16 - mx) / sxx:.4f} {(34 - mx) / sxx:.4f}; h at 0 C {1 / N + mx ** 2 / sxx:.4f}")
print(f"road 1, SE(slope) = s/sqrt(Sxx)        {se1:.4f}")
print(f"road 2, SE(slope) = s sqrt(G22)        {s * sqrt(g22):.4f}")
print(f"SE(intercept) {se0:.4f}; road 2 {s * sqrt(g11):.4f}")
print(f"road 1, t = slope / SE                 {t:.4f}; t^2 {t * t:.4f}")
print(f"road 2, F = (Syy - SSE) / s^2          {F:.4f}; Syy - SSE {syy - sse:.4f}")
print(f"cutoff t* for 95%, 8 df                {tq:.4f}; Simpson area outside it {1 - 2 * simpson(t_dens, 0.0, tq):.4f}")
print(f"p-value, t on 8 df: series {p_ser:.4f}; Simpson {p_simp:.4f}")
print(f"95% interval for the slope: {b1 - tq * se1:.4f} to {b1 + tq * se1:.4f} (half-width {tq * se1:.4f})")
print(f"at 30 C: fitted {yhat0:.4f}; h {h:.4f}; h from the matrix {h_mat:.4f}")
print(f"mean sales at 30 C: {yhat0 - hw_m:.2f} to {yhat0 + hw_m:.2f} (SE {s * sqrt(h):.4f}, half-width {hw_m:.2f})")
print(f"one new 30 C day:   {yhat0 - hw_p:.2f} to {yhat0 + hw_p:.2f} (SE {s * sqrt(1 + h):.4f}, half-width {hw_p:.2f})")
p_z = 1 - 2 * simpson(z_dens, 0.0, t); s_n = sqrt(sse / N)
print(f"mistake, normal cutoff: p {p_z:.4f}; true false-alarm rate of 1.96 on 8 df {1 - t_inside(1.96, NU):.4f}")
print(f"mistake, SSE/n: s {s_n:.4f}, SE {s_n / sqrt(sxx):.4f}, t {b1 / (s_n / sqrt(sxx)):.4f}, p {1 - t_inside(b1 / (s_n / sqrt(sxx)), NU):.4f}")
cov_mix = t_inside(tq * sqrt(h / (1 + h)), NU)
print(f"mistake, mean interval for one new day: closed-form coverage {cov_mix:.4f}")

state = 20260928                                      # SplitMix64, the same stream in Python and Rust
def u01():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
def gauss():                                          # Box-Muller, one draw per call
    u = u01()
    while u == 0.0: u = u01()
    return sqrt(-2 * log(u)) * cos(2 * pi * u01())

def cafes(slope, rho, m=20000):                       # refit m simulated cafes; errors AR(1) with rho
    hits = [0] * 5; sb = sb2 = ss2 = 0.0
    for _ in range(m):
        e = s * gauss(); errs = [e]
        for _ in range(N - 1):
            e = rho * e + s * sqrt(1 - rho * rho) * gauss(); errs.append(e)
        y = [b0 + slope * a + ea for a, ea in zip(X, errs)]
        c0, c1, cse, _, _ = fit(X, y); cs = sqrt(cse / NU); cse1 = cs / sqrt(sxx)
        new = b0 + slope * X0 + s * gauss(); mid = c0 + c1 * X0
        sb += c1; sb2 += c1 * c1; ss2 += cs * cs
        hits[0] += abs(c1 - slope) <= tq * cse1; hits[1] += abs(c1 - slope) <= 1.96 * cse1
        hits[2] += abs(mid - (b0 + slope * X0)) <= tq * cs * sqrt(h)
        hits[3] += abs(mid - new) <= tq * cs * sqrt(1 + h); hits[4] += abs(mid - new) <= tq * cs * sqrt(h)
    return [k / m for k in hits], sqrt(sb2 / m - (sb / m) ** 2), ss2 / m, m

rates, sd1, ms2, m = cafes(b1, 0.0)
e = lambda r: sqrt(r * (1 - r) / m)
print(f"simulation, {m} cafes, seed 20260928, true slope 0.8, s as sigma:")
print(f"  spread of fitted slopes {sd1:.4f} (+/- {sd1 / sqrt(2 * m):.4f}); formula sigma/sqrt(Sxx) {s / sqrt(sxx):.4f}")
print(f"  average s^2 {ms2:.4f} (+/- {s * s * sqrt(2 / NU / m):.4f}); true sigma^2 {s * s:.4f}; average SSE/n {ms2 * NU / N:.4f}")
names = ["t interval holds the slope", "1.96 interval holds the slope", "mean interval holds the mean",
         "prediction interval holds the new day", "mean interval holds the new day"]
for nm, r in zip(names, rates): print(f"  {nm:<38}{r:.4f} (+/- {e(r):.4f})")
bad, _, _, _ = cafes(0.0, 0.8)
print(f"drop independence: rho 0.8 day to day, true slope 0; t test rejects {1 - bad[0]:.4f} (+/- {e(bad[0]):.4f}) of cafes")
px = lambda a: 40 + 15 * (a - 15); py = lambda v: 200 - 3 * (v - 10)
grid = list(range(16, 35, 2)); band = lambda a, one: tq * s * sqrt(one + 1 / N + (a - mx) ** 2 / sxx)
print("figure, points " + " ".join(f"{px(a):.1f},{py(b):.1f}" for a, b in zip(X, Y)))
print(f"figure, fit line {px(16):.1f},{py(b0 + b1 * 16):.1f} {px(34):.1f},{py(b0 + b1 * 34):.1f}")
for lab, one, sg in (("mean band upper", 0, 1), ("mean band lower", 0, -1), ("prediction upper", 1, 1), ("prediction lower", 1, -1)):
    print(f"figure, {lab} " + " ".join(f"{px(a):.1f},{py(b0 + b1 * a + sg * band(a, one)):.1f}" for a in grid))
assert abs(t * t - F) < 1e-9 and abs(s * sqrt(g22) - se1) < 1e-12   # two roads to t, two to the SE
assert abs(p_ser - p_simp) < 1e-8 and abs(h - h_mat) < 1e-12        # series against Simpson; h two ways
assert abs(b1 - 0.8) < 1e-12 and abs(sse - 342.8) < 1e-9            # the hand table's numbers
assert abs(sd1 - s / sqrt(sxx)) < 4 * sd1 / sqrt(2 * m) and abs(ms2 - s * s) < 4 * s * s * sqrt(2 / NU / m)
for r, want in zip(rates, [0.95, t_inside(1.96, NU), 0.95, 0.95, cov_mix]): assert abs(r - want) < 4 * e(want)
assert 1 - bad[0] > 0.05 + 4 * e(0.05)                              # dependence breaks the 5 percent
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
data, temperature C   16  18  20  22  24  26  28  30  32  34
data, iced coffees    37  33  34  31  35  49  40  53  50  38
sums: mean x 25.0000, mean y 40.0000, Sxx 330.0000, Sxy 264.0000, Syy 554.0000
fit: slope 0.8000 coffees per degree, intercept 20.0000
residuals 4.2 -1.4 -2.0 -6.6 -4.2 8.2 -2.4 9.0 4.4 -9.2
SSE 342.8000; s^2 = SSE/8 42.8500; s 6.5460
hand: sqrt(Sxx) 18.1659; weights at 16 and 34 C -0.0273 0.0273; h at 0 C 1.9939
road 1, SE(slope) = s/sqrt(Sxx)        0.3603
road 2, SE(slope) = s sqrt(G22)        0.3603
SE(intercept) 9.2434; road 2 9.2434
road 1, t = slope / SE                 2.2201; t^2 4.9288
road 2, F = (Syy - SSE) / s^2          4.9288; Syy - SSE 211.2000
cutoff t* for 95%, 8 df                2.3060; Simpson area outside it 0.0500
p-value, t on 8 df: series 0.0572; Simpson 0.0572
95% interval for the slope: -0.0310 to 1.6310 (half-width 0.8310)
at 30 C: fitted 44.0000; h 0.1758; h from the matrix 0.1758
mean sales at 30 C: 37.67 to 50.33 (SE 2.7443, half-width 6.33)
one new 30 C day:   27.63 to 60.37 (SE 7.0980, half-width 16.37)
mistake, normal cutoff: p 0.0264; true false-alarm rate of 1.96 on 8 df 0.0857
mistake, SSE/n: s 5.8549, SE 0.3223, t 2.4821, p 0.0380
mistake, mean interval for one new day: closed-form coverage 0.6014
simulation, 20000 cafes, seed 20260928, true slope 0.8, s as sigma:
  spread of fitted slopes 0.3576 (+/- 0.0018); formula sigma/sqrt(Sxx) 0.3603
  average s^2 42.8071 (+/- 0.1515); true sigma^2 42.8500; average SSE/n 34.2457
  t interval holds the slope            0.9521 (+/- 0.0015)
  1.96 interval holds the slope         0.9159 (+/- 0.0020)
  mean interval holds the mean          0.9520 (+/- 0.0015)
  prediction interval holds the new day 0.9490 (+/- 0.0016)
  mean interval holds the new day       0.5975 (+/- 0.0035)
drop independence: rho 0.8 day to day, true slope 0; t test rejects 0.4001 (+/- 0.0035) of cafes
figure, points 55.0,119.0 85.0,131.0 115.0,128.0 145.0,137.0 175.0,125.0 205.0,83.0 235.0,110.0 265.0,71.0 295.0,80.0 325.0,116.0
figure, fit line 55.0,131.6 325.0,88.4
figure, mean band upper 55.0,105.0 85.0,104.2 115.0,103.0 145.0,101.0 175.0,97.9 205.0,93.1 235.0,86.6 265.0,79.0 295.0,70.6 325.0,61.8
figure, mean band lower 55.0,158.2 85.0,149.4 115.0,141.0 145.0,133.4 175.0,126.9 205.0,122.1 235.0,119.0 265.0,117.0 295.0,115.8 325.0,115.0
figure, prediction upper 55.0,79.1 85.0,76.2 115.0,72.9 145.0,69.1 175.0,64.8 205.0,60.0 235.0,54.7 265.0,48.9 295.0,42.6 325.0,35.9
figure, prediction lower 55.0,184.1 85.0,177.4 115.0,171.1 145.0,165.3 175.0,160.0 205.0,155.2 235.0,150.9 265.0,147.1 295.0,143.8 325.0,140.9
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Regression error bars -- the same check as the Python, in Rust.  No crates.  A cafe logged
// midday temperature and iced coffees sold on ten summer days.  Roads: the slope's standard error
// from deviations and from the 2x2 matrix inverse; t from the slope and F from dropping the slope;
// t tail areas from a finite series and from Simpson's rule; a seeded simulation (SplitMix64,
// Box-Muller) that refits thousands of cafes and counts coverage.
use std::f64::consts::PI;

const X: [f64; 10] = [16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0, 34.0];
const Y: [f64; 10] = [37.0, 33.0, 34.0, 31.0, 35.0, 49.0, 40.0, 53.0, 50.0, 38.0];
const N: usize = 10;
const NU: u32 = 8;
const X0: f64 = 30.0;

fn fit(x: &[f64], y: &[f64]) -> (f64, f64, f64, f64, f64) {
    let n = x.len() as f64;
    let mx = x.iter().sum::<f64>() / n;
    let my = y.iter().sum::<f64>() / n;
    let sxx: f64 = x.iter().map(|a| (a - mx).powi(2)).sum();
    let sxy: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * b).sum();
    let b1 = sxy / sxx;
    let b0 = my - b1 * mx;
    let sse: f64 = x.iter().zip(y).map(|(a, b)| (b - b0 - b1 * a).powi(2)).sum();
    (b0, b1, sse, sxx, mx)
}
fn t_inside(t: f64, v: u32) -> f64 {              // P(|T| <= t), even v: finite series in the angle
    let th = (t / (v as f64).sqrt()).atan();
    let c = th.cos().powi(2);
    let (mut term, mut tot) = (1.0, 1.0);
    for k in 1..(v / 2) {
        term *= c * (2 * k - 1) as f64 / (2 * k) as f64;
        tot += term;
    }
    th.sin() * tot
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let m = 2000;
    let h = (b - a) / m as f64;
    let inner: f64 = (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}
fn t_dens(t: f64) -> f64 {                         // Gamma(9/2) / (sqrt(8 pi) Gamma(4)), by hand
    let v = 8.0;
    let g = 3.5 * 2.5 * 1.5 * 0.5 * PI.sqrt() / ((v * PI).sqrt() * 6.0);
    g * (1.0 + t * t / v).powf(-(v + 1.0) / 2.0)
}
fn z_dens(z: f64) -> f64 { 2.718281828459045f64.powf(-z * z / 2.0) / (2.0 * PI).sqrt() }
fn bisect(f: &dyn Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if f(mid) < target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
struct Rng(u64);                                   // SplitMix64, the same stream as the Python
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn gauss(&mut self) -> f64 {                   // Box-Muller, one draw per call
        let mut u = self.u01();
        while u == 0.0 { u = self.u01(); }
        (-2.0 * u.ln()).sqrt() * (2.0 * PI * self.u01()).cos()
    }
}
fn main() {
    let (b0, b1, sse, sxx, mx) = fit(&X, &Y);
    let n = N as f64;
    let s = (sse / NU as f64).sqrt();
    let se1 = s / sxx.sqrt();
    let se0 = s * (1.0 / n + mx * mx / sxx).sqrt();
    let sx: f64 = X.iter().sum();                   // road 2: (X'X)^-1 from raw sums, no deviations
    let sxx_raw: f64 = X.iter().map(|a| a * a).sum();
    let det = n * sxx_raw - sx * sx;
    let (g11, g12, g22) = (sxx_raw / det, -sx / det, n / det);
    let t = b1 / se1;
    let ybar = Y.iter().sum::<f64>() / n;
    let syy: f64 = Y.iter().map(|b| (b - ybar).powi(2)).sum();   // road 2 for t: the flat line's SSE
    let f_stat = (syy - sse) / (sse / NU as f64);
    let tq = bisect(&|q| t_inside(q, NU), 0.95, 0.0, 20.0);
    let (p_ser, p_simp) = (1.0 - t_inside(t, NU), 1.0 - 2.0 * simpson(&t_dens, 0.0, t));
    let h = 1.0 / n + (X0 - mx).powi(2) / sxx;
    let h_mat = g11 + 2.0 * X0 * g12 + X0 * X0 * g22;
    let (yhat0, hw_m, hw_p) = (b0 + b1 * X0, tq * s * h.sqrt(), tq * s * (1.0 + h).sqrt());
    let row = |v: &[f64]| v.iter().map(|a| format!("{:>3}", a)).collect::<Vec<_>>().join(" ");
    println!("data, temperature C  {}", row(&X));
    println!("data, iced coffees   {}", row(&Y));
    println!("sums: mean x {:.4}, mean y {:.4}, Sxx {:.4}, Sxy {:.4}, Syy {:.4}", mx, ybar, sxx, b1 * sxx, syy);
    println!("fit: slope {:.4} coffees per degree, intercept {:.4}", b1, b0);
    let res: Vec<String> = X.iter().zip(&Y).map(|(a, b)| format!("{:.1}", b - b0 - b1 * a)).collect();
    println!("residuals {}", res.join(" "));
    println!("SSE {:.4}; s^2 = SSE/8 {:.4}; s {:.4}", sse, s * s, s);
    println!("hand: sqrt(Sxx) {:.4}; weights at 16 and 34 C {:.4} {:.4}; h at 0 C {:.4}", sxx.sqrt(), (16.0 - mx) / sxx, (34.0 - mx) / sxx, 1.0 / n + mx * mx / sxx);
    println!("road 1, SE(slope) = s/sqrt(Sxx)        {:.4}", se1);
    println!("road 2, SE(slope) = s sqrt(G22)        {:.4}", s * g22.sqrt());
    println!("SE(intercept) {:.4}; road 2 {:.4}", se0, s * g11.sqrt());
    println!("road 1, t = slope / SE                 {:.4}; t^2 {:.4}", t, t * t);
    println!("road 2, F = (Syy - SSE) / s^2          {:.4}; Syy - SSE {:.4}", f_stat, syy - sse);
    println!("cutoff t* for 95%, 8 df                {:.4}; Simpson area outside it {:.4}", tq, 1.0 - 2.0 * simpson(&t_dens, 0.0, tq));
    println!("p-value, t on 8 df: series {:.4}; Simpson {:.4}", p_ser, p_simp);
    println!("95% interval for the slope: {:.4} to {:.4} (half-width {:.4})", b1 - tq * se1, b1 + tq * se1, tq * se1);
    println!("at 30 C: fitted {:.4}; h {:.4}; h from the matrix {:.4}", yhat0, h, h_mat);
    println!("mean sales at 30 C: {:.2} to {:.2} (SE {:.4}, half-width {:.2})", yhat0 - hw_m, yhat0 + hw_m, s * h.sqrt(), hw_m);
    println!("one new 30 C day:   {:.2} to {:.2} (SE {:.4}, half-width {:.2})", yhat0 - hw_p, yhat0 + hw_p, s * (1.0 + h).sqrt(), hw_p);
    let (p_z, s_n) = (1.0 - 2.0 * simpson(&z_dens, 0.0, t), (sse / n).sqrt());
    println!("mistake, normal cutoff: p {:.4}; true false-alarm rate of 1.96 on 8 df {:.4}", p_z, 1.0 - t_inside(1.96, NU));
    let tn = b1 / (s_n / sxx.sqrt());
    println!("mistake, SSE/n: s {:.4}, SE {:.4}, t {:.4}, p {:.4}", s_n, s_n / sxx.sqrt(), tn, 1.0 - t_inside(tn, NU));
    let cov_mix = t_inside(tq * (h / (1.0 + h)).sqrt(), NU);
    println!("mistake, mean interval for one new day: closed-form coverage {:.4}", cov_mix);

    let mut rng = Rng(20260928);
    let mut cafes = |slope: f64, rho: f64, m: usize| -> ([f64; 5], f64, f64) {
        let (mut hits, mut sb, mut sb2, mut ss2) = ([0usize; 5], 0.0, 0.0, 0.0);
        for _ in 0..m {
            let mut e = s * rng.gauss();
            let mut errs = vec![e];
            for _ in 0..N - 1 { e = rho * e + s * (1.0 - rho * rho).sqrt() * rng.gauss(); errs.push(e); }
            let y: Vec<f64> = X.iter().zip(&errs).map(|(a, ea)| b0 + slope * a + ea).collect();
            let (c0, c1, cse, _, _) = fit(&X, &y);
            let cs = (cse / NU as f64).sqrt();
            let cse1 = cs / sxx.sqrt();
            let new = b0 + slope * X0 + s * rng.gauss();
            let mid = c0 + c1 * X0;
            sb += c1; sb2 += c1 * c1; ss2 += cs * cs;
            hits[0] += ((c1 - slope).abs() <= tq * cse1) as usize;
            hits[1] += ((c1 - slope).abs() <= 1.96 * cse1) as usize;
            hits[2] += ((mid - (b0 + slope * X0)).abs() <= tq * cs * h.sqrt()) as usize;
            hits[3] += ((mid - new).abs() <= tq * cs * (1.0 + h).sqrt()) as usize;
            hits[4] += ((mid - new).abs() <= tq * cs * h.sqrt()) as usize;
        }
        let mf = m as f64;
        (hits.map(|k| k as f64 / mf), (sb2 / mf - (sb / mf).powi(2)).sqrt(), ss2 / mf)
    };
    let m = 20000usize;
    let mf = m as f64;
    let (rates, sd1, ms2) = cafes(b1, 0.0, m);
    let e = |r: f64| (r * (1.0 - r) / mf).sqrt();
    println!("simulation, {} cafes, seed 20260928, true slope 0.8, s as sigma:", m);
    println!("  spread of fitted slopes {:.4} (+/- {:.4}); formula sigma/sqrt(Sxx) {:.4}", sd1, sd1 / (2.0 * mf).sqrt(), s / sxx.sqrt());
    println!("  average s^2 {:.4} (+/- {:.4}); true sigma^2 {:.4}; average SSE/n {:.4}", ms2, s * s * (2.0 / NU as f64 / mf).sqrt(), s * s, ms2 * NU as f64 / n);
    let names = ["t interval holds the slope", "1.96 interval holds the slope", "mean interval holds the mean",
                 "prediction interval holds the new day", "mean interval holds the new day"];
    for (nm, r) in names.iter().zip(rates.iter()) { println!("  {:<38}{:.4} (+/- {:.4})", nm, r, e(*r)); }
    let (bad, _, _) = cafes(0.0, 0.8, m);
    println!("drop independence: rho 0.8 day to day, true slope 0; t test rejects {:.4} (+/- {:.4}) of cafes", 1.0 - bad[0], e(bad[0]));
    let px = |a: f64| 40.0 + 15.0 * (a - 15.0);
    let py = |v: f64| 200.0 - 3.0 * (v - 10.0);
    let band = |a: f64, one: f64| tq * s * (one + 1.0 / n + (a - mx).powi(2) / sxx).sqrt();
    let pts: Vec<String> = X.iter().zip(&Y).map(|(a, b)| format!("{:.1},{:.1}", px(*a), py(*b))).collect();
    println!("figure, points {}", pts.join(" "));
    println!("figure, fit line {:.1},{:.1} {:.1},{:.1}", px(16.0), py(b0 + b1 * 16.0), px(34.0), py(b0 + b1 * 34.0));
    for (lab, one, sg) in [("mean band upper", 0.0, 1.0), ("mean band lower", 0.0, -1.0), ("prediction upper", 1.0, 1.0), ("prediction lower", 1.0, -1.0)] {
        let v: Vec<String> = X.iter().map(|a| format!("{:.1},{:.1}", px(*a), py(b0 + b1 * a + sg * band(*a, one)))).collect();
        println!("figure, {} {}", lab, v.join(" "));
    }
    assert!((t * t - f_stat).abs() < 1e-9 && (s * g22.sqrt() - se1).abs() < 1e-12);   // two roads to t, to the SE
    assert!((p_ser - p_simp).abs() < 1e-8 && (h - h_mat).abs() < 1e-12);            // series vs Simpson; h two ways
    assert!((b1 - 0.8).abs() < 1e-12 && (sse - 342.8).abs() < 1e-9);                // the hand table's numbers
    assert!((sd1 - s / sxx.sqrt()).abs() < 4.0 * sd1 / (2.0 * mf).sqrt() && (ms2 - s * s).abs() < 4.0 * s * s * (2.0 / NU as f64 / mf).sqrt());
    for (r, want) in rates.iter().zip([0.95, t_inside(1.96, NU), 0.95, 0.95, cov_mix]) { assert!((r - want).abs() < 4.0 * e(want)); }
    assert!(1.0 - bad[0] > 0.05 + 4.0 * e(0.05));                                   // dependence breaks the 5 percent
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
data, temperature C   16  18  20  22  24  26  28  30  32  34
data, iced coffees    37  33  34  31  35  49  40  53  50  38
sums: mean x 25.0000, mean y 40.0000, Sxx 330.0000, Sxy 264.0000, Syy 554.0000
fit: slope 0.8000 coffees per degree, intercept 20.0000
residuals 4.2 -1.4 -2.0 -6.6 -4.2 8.2 -2.4 9.0 4.4 -9.2
SSE 342.8000; s^2 = SSE/8 42.8500; s 6.5460
hand: sqrt(Sxx) 18.1659; weights at 16 and 34 C -0.0273 0.0273; h at 0 C 1.9939
road 1, SE(slope) = s/sqrt(Sxx)        0.3603
road 2, SE(slope) = s sqrt(G22)        0.3603
SE(intercept) 9.2434; road 2 9.2434
road 1, t = slope / SE                 2.2201; t^2 4.9288
road 2, F = (Syy - SSE) / s^2          4.9288; Syy - SSE 211.2000
cutoff t* for 95%, 8 df                2.3060; Simpson area outside it 0.0500
p-value, t on 8 df: series 0.0572; Simpson 0.0572
95% interval for the slope: -0.0310 to 1.6310 (half-width 0.8310)
at 30 C: fitted 44.0000; h 0.1758; h from the matrix 0.1758
mean sales at 30 C: 37.67 to 50.33 (SE 2.7443, half-width 6.33)
one new 30 C day:   27.63 to 60.37 (SE 7.0980, half-width 16.37)
mistake, normal cutoff: p 0.0264; true false-alarm rate of 1.96 on 8 df 0.0857
mistake, SSE/n: s 5.8549, SE 0.3223, t 2.4821, p 0.0380
mistake, mean interval for one new day: closed-form coverage 0.6014
simulation, 20000 cafes, seed 20260928, true slope 0.8, s as sigma:
  spread of fitted slopes 0.3576 (+/- 0.0018); formula sigma/sqrt(Sxx) 0.3603
  average s^2 42.8071 (+/- 0.1515); true sigma^2 42.8500; average SSE/n 34.2457
  t interval holds the slope            0.9521 (+/- 0.0015)
  1.96 interval holds the slope         0.9159 (+/- 0.0020)
  mean interval holds the mean          0.9520 (+/- 0.0015)
  prediction interval holds the new day 0.9490 (+/- 0.0016)
  mean interval holds the new day       0.5975 (+/- 0.0035)
drop independence: rho 0.8 day to day, true slope 0; t test rejects 0.4001 (+/- 0.0035) of cafes
figure, points 55.0,119.0 85.0,131.0 115.0,128.0 145.0,137.0 175.0,125.0 205.0,83.0 235.0,110.0 265.0,71.0 295.0,80.0 325.0,116.0
figure, fit line 55.0,131.6 325.0,88.4
figure, mean band upper 55.0,105.0 85.0,104.2 115.0,103.0 145.0,101.0 175.0,97.9 205.0,93.1 235.0,86.6 265.0,79.0 295.0,70.6 325.0,61.8
figure, mean band lower 55.0,158.2 85.0,149.4 115.0,141.0 145.0,133.4 175.0,126.9 205.0,122.1 235.0,119.0 265.0,117.0 295.0,115.8 325.0,115.0
figure, prediction upper 55.0,79.1 85.0,76.2 115.0,72.9 145.0,69.1 175.0,64.8 205.0,60.0 235.0,54.7 265.0,48.9 295.0,42.6 325.0,35.9
figure, prediction lower 55.0,184.1 85.0,177.4 115.0,171.1 145.0,165.3 175.0,160.0 205.0,155.2 235.0,150.9 265.0,147.1 295.0,143.8 325.0,140.9
ALL CHECKS PASS
```

The two outputs match line for line, simulation included, because both draw the same SplitMix64 stream. The simulated spread of slopes, 0.3576, sits 1.5 of its standard errors from the formula's 0.3603; every coverage lands within its band.

### Lean

Lean proves the card's results for any three or more days at fixed temperatures, not all equal, and checks the café's sums exactly.

- Suppose each day's sales are the true line plus independent noise, each $N(0, \sigma^2)$ with $\sigma$ above 0. Then the fitted slope is unbiased, and $\mathrm{Var}(\hat\beta_1) = \sigma^2/S_{xx}$.
- Take the same model. Then $s^2 = \mathrm{SSE}/(n-2)$ is right on average: its mean is $\sigma^2$.
- Take the same model. Then $(\hat\beta_1 - \beta_1)/\mathrm{SE}(\hat\beta_1)$ follows Student's t law with n − 2 degrees of freedom.
- Take the same model and a new temperature $x_0$. Then $(\hat y_0 - \beta_0 - \beta_1 x_0)/(s\sqrt{h_0})$ follows Student's t law with n − 2 degrees.
- Take a new day's sales $Y_0$ at $x_0$, whose own $N(0, \sigma^2)$ noise is independent of the other days' noise. Then $(Y_0 - \hat y_0)/(s\sqrt{1 + h_0})$ follows Student's t law with n − 2 degrees.
- The café's sums hold exactly: averages 25 °C and 40 coffees, $S_{xx} = 330$, slope 0.8 and intercept 20.
- SSE is 342.8, so $s^2 = 42.85$. At 30 °C the line gives 44, and $h_0 = 29/165$.
- The F ratio's removal checks too: 554 − 342.8 = 211.2, which is $0.8^2 \times 330$.

The cutoff 2.306, the p-values, the interval ends, the matrix form, the simulations and the figure are left to the Python and Rust checks.

```lean
-- Regression error bars: when each day's value is a straight line in a fixed temperature plus independent normal noise of one spread, the fitted slope is unbiased with variance σ²/S_xx, s² = SSE/(n − 2) is unbiased for σ², and the slope's t ratio and both forecast t ratios follow Student's t law on n − 2 degrees of freedom.
import Mathlib.Probability.Distributions.Gaussian.Multivariate
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Integral.Gamma
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.MeasureTheory.Integral.Pi
import Mathlib.MeasureTheory.Group.Convolution
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt

/-! Notation as on the card. The data are `n` days; day `i` has temperature `x i` and sales
`y i`. A bar is an average; `S_xx` is the spread of the temperatures; the fitted slope is
`∑ (xᵢ − x̄) yᵢ / S_xx`, the fitted intercept is `ȳ − slope · x̄`; `SSE` is the sum of the
squared leftovers; `s² = SSE / (n − 2)`; `SE(slope) = s / √S_xx`; at a new temperature `x₀`,
`h₀ = 1/n + (x₀ − x̄)² / S_xx`. -/

open MeasureTheory ProbabilityTheory Real
open scoped ENNReal NNReal

noncomputable section

namespace RegressionInference

variable {n : ℕ}

/-- The average of `n` readings, `(∑ xᵢ) / n`. -/
def mean (x : Fin n → ℝ) : ℝ := (∑ i, x i) / n

/-- `S_xx = ∑ (xᵢ − x̄)²`: how spread out the temperatures are. -/
def Sxx (x : Fin n → ℝ) : ℝ := ∑ i, (x i - mean x) ^ 2

/-- The least-squares slope, written as weights: `∑ (xᵢ − x̄) yᵢ / S_xx`. -/
def slope (x y : Fin n → ℝ) : ℝ := (∑ i, (x i - mean x) * y i) / Sxx x

/-- The least-squares intercept `ȳ − slope · x̄`. -/
def intercept (x y : Fin n → ℝ) : ℝ := mean y - slope x y * mean x

/-- `SSE`: the sum of the squared leftovers, recorded minus fitted. -/
def SSE (x y : Fin n → ℝ) : ℝ := ∑ i, (y i - intercept x y - slope x y * x i) ^ 2

/-- `s² = SSE / (n − 2)`: the estimated noise variance. -/
def s2 (x y : Fin n → ℝ) : ℝ := SSE x y / ((n : ℝ) - 2)

/-- The slope's standard error `s / √S_xx`. -/
def seSlope (x y : Fin n → ℝ) : ℝ := √(s2 x y) / √(Sxx x)

/-- The distance factor at a new temperature `x₀`: `h₀ = 1/n + (x₀ − x̄)² / S_xx`. -/
def h0 (x : Fin n → ℝ) (x0 : ℝ) : ℝ := 1 / n + (x0 - mean x) ^ 2 / Sxx x

/-- Student's t density with ν degrees of freedom:
`Γ((ν+1)/2) / (√(νπ) Γ(ν/2)) · (1 + t²/ν)^(−(ν+1)/2)`. -/
def studentTPDF (ν t : ℝ) : ℝ :=
  Gamma ((ν + 1) / 2) / (√(ν * π) * Gamma (ν / 2)) * (1 + t ^ 2 / ν) ^ (-(ν + 1) / 2)

/-! ### Helper lemmas -/

lemma lintegral_pi_prod_aux : ∀ (m : ℕ) (μ : Fin m → Measure ℝ) [∀ i, SigmaFinite (μ i)]
    (f : Fin m → ℝ → ℝ≥0∞), (∀ i, Measurable (f i)) →
    ∫⁻ w, ∏ i, f i (w i) ∂(Measure.pi μ) = ∏ i, ∫⁻ x, f i x ∂(μ i)
  | 0, μ, _, f, _ => by simp
  | m + 1, μ, _, f, hf => by
    have h := ((measurePreserving_piFinSuccAbove μ 0).symm
      _).lintegral_comp_emb (MeasurableEquiv.measurableEmbedding _) (fun w => ∏ i, f i (w i))
    rw [← h]
    simp only [MeasurableEquiv.piFinSuccAbove_symm_apply, Fin.prod_univ_succ, Fin.insertNthEquiv_apply,
      Fin.insertNth_zero', Fin.cons_zero, Fin.cons_succ]
    rw [lintegral_prod_mul (g := fun w : Fin m → ℝ => ∏ x, f x.succ (w x)) (hf 0).aemeasurable]
    · simp only [Fin.succAbove_zero]
      rw [lintegral_pi_prod_aux m _ _ (fun i => hf i.succ)]
    exact (Finset.measurable_prod _ fun i _ => (hf i.succ).comp (measurable_pi_apply i)).aemeasurable

/-- `n` independent standard normals have the product of the normal densities as their joint density. -/
lemma gaussPi_eq_withDensity (m : ℕ) :
    Measure.pi (fun _ : Fin m => gaussianReal 0 1) =
      (volume : Measure (Fin m → ℝ)).withDensity (fun w => ∏ i, gaussianPDF 0 1 (w i)) := by
  refine (Measure.pi_eq (μ := fun _ : Fin m => gaussianReal 0 1) fun s hs => ?_)
  rw [withDensity_apply _ (MeasurableSet.univ_pi hs), volume_pi, Measure.restrict_pi_pi,
    lintegral_pi_prod_aux m _ _ (fun _ => measurable_gaussianPDF 0 1)]
  refine Finset.prod_congr rfl fun i _ => ?_
  rw [gaussianReal_apply 0 one_ne_zero]

/-- The Gaussian density of `z` at `t` when `z / √(S/m)` is standard normal. -/
def qd (m S t : ℝ) : ℝ := √S / √(2 * π * m) * exp (-(t ^ 2 * S) / (2 * m))

/-- The product of `m` standard normal densities is `(2π)^(−m/2) · exp(−∑ wᵢ² / 2)`. -/
lemma prod_gaussianPDF (m : ℕ) (w : Fin m → ℝ) :
    ∏ i, gaussianPDF 0 1 (w i) = ENNReal.ofReal ((√(2 * π))⁻¹ ^ m * exp (-(∑ i, w i ^ 2) / 2)) := by
  simp only [gaussianPDF]
  rw [← ENNReal.ofReal_prod_of_nonneg (fun i _ => gaussianPDFReal_nonneg _ _ _)]
  congr 1
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  rw [Finset.prod_mul_distrib, Finset.prod_const, Finset.card_univ, Fintype.card_fin, ← Real.exp_sum]
  congr 2
  rw [← Finset.sum_div, Finset.sum_neg_distrib]

/-- Averaging the scaled normal density over `m` independent standard normals gives the Student t density with `m` degrees of freedom. -/
lemma key_K (m : ℕ) (hm : 0 < m) (t : ℝ) :
    ∫⁻ w, ENNReal.ofReal (qd m (∑ k, w k ^ 2) t) ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1) =
      ENNReal.ofReal (studentTPDF m t) := by
  set C : ℝ := (√(2 * π))⁻¹ ^ m / √(2 * π * m) with hC
  set b : ℝ := 1 / 2 + t ^ 2 / (2 * m) with hb
  have hb0 : 0 < b := by positivity
  set G : ℝ → ℝ := fun y => C * (|y| * exp (-b * y ^ 2)) with hG
  have hGnn : ∀ y, 0 ≤ G y := fun y => by positivity
  rw [gaussPi_eq_withDensity, lintegral_withDensity_eq_lintegral_mul _ (by fun_prop) (by unfold qd; fun_prop)]
  simp only [Pi.mul_apply]
  have h1 : ∀ w : Fin m → ℝ, (∏ i, gaussianPDF 0 1 (w i)) * ENNReal.ofReal (qd m (∑ k, w k ^ 2) t)
      = ENNReal.ofReal (G (√(∑ k, w k ^ 2))) := by
    intro w
    have hS : 0 ≤ ∑ k, w k ^ 2 := Finset.sum_nonneg fun k _ => sq_nonneg _
    rw [prod_gaussianPDF, ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    simp only [hG, qd, hC, hb, abs_of_nonneg (Real.sqrt_nonneg _), Real.sq_sqrt hS]
    have hmpos : (0 : ℝ) < m := by exact_mod_cast hm
    rw [show -(1 / 2 + t ^ 2 / (2 * (m : ℝ))) * ∑ k, w k ^ 2
        = -(∑ k, w k ^ 2) / 2 + -(t ^ 2 * ∑ k, w k ^ 2) / (2 * m) by field_simp; ring, Real.exp_add]
    ring
  simp_rw [h1]
  rw [← (PiLp.volume_preserving_ofLp (Fin m)).lintegral_comp (by fun_prop)]
  simp_rw [← EuclideanSpace.real_norm_sq_eq, Real.sqrt_sq (norm_nonneg _)]
  have hm1 : (-1 : ℝ) < m := by linarith [(Nat.cast_nonneg m : (0:ℝ) ≤ m)]
  have : Nonempty (Fin m) := ⟨⟨0, hm⟩⟩
  have hdim : Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) = m := finrank_euclideanSpace_fin
  have hcongr : Set.EqOn (fun y : ℝ => y ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) - 1) • G y)
      (fun y => C * (y ^ (m : ℝ) * exp (-b * y ^ (2 : ℝ)))) (Set.Ioi 0) := by
    intro y hy
    have hy : 0 < y := hy
    simp only [hdim, hG, smul_eq_mul, abs_of_pos hy, Real.rpow_two, Real.rpow_natCast]
    rw [← pow_sub_one_mul hm.ne' y]
    ring
  have hint : IntegrableOn (fun y : ℝ => y ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) - 1) • G y)
      (Set.Ioi 0) := by
    refine (IntegrableOn.congr_fun ?_ hcongr.symm measurableSet_Ioi)
    exact (integrableOn_rpow_mul_exp_neg_mul_rpow hm1 two_pos hb0).const_mul C
  rw [← ofReal_integral_eq_lintegral_ofReal ((integrable_fun_norm_addHaar volume).2 hint)
    (ae_of_all _ fun v => hGnn _), integral_fun_norm_addHaar volume G,
    setIntegral_congr_fun measurableSet_Ioi hcongr, integral_const_mul,
    integral_rpow_mul_exp_neg_mul_rpow two_pos hm1 hb0, hdim]
  congr 1
  rw [Measure.real, EuclideanSpace.volume_ball]
  have hmpos : (0 : ℝ) < m := by exact_mod_cast hm
  have hG1 : 0 < Gamma ((m : ℝ) / 2 + 1) := Real.Gamma_pos_of_pos (by positivity)
  simp only [Fintype.card_fin, ENNReal.ofReal_one, one_pow, one_mul, nsmul_eq_mul, smul_eq_mul]
  rw [ENNReal.toReal_ofReal (by positivity), Real.Gamma_add_one (by positivity), studentTPDF]
  have hb' : b = (1 + t ^ 2 / m) / 2 := by rw [hb]; ring
  have hX : 0 ≤ 1 + t ^ 2 / (m : ℝ) := by positivity
  have h2 : (2 : ℝ) ^ (-(-((m : ℝ) + 1) / 2)) = √2 ^ (m + 1) := by
    rw [Real.sqrt_eq_rpow, ← Real.rpow_natCast, ← Real.rpow_mul (by norm_num)]
    congr 1; push_cast; ring
  rw [hb', Real.div_rpow hX (by norm_num), div_eq_mul_inv _ ((2 : ℝ) ^ _), ← Real.rpow_neg (by norm_num), h2, hC]
  have hs2 : 0 < √2 := by positivity
  have hsp : 0 < √π := by positivity
  have hsm : 0 < √(m : ℝ) := by positivity
  rw [show √(2 * π * m) = √2 * √π * √m by rw [Real.sqrt_mul (by positivity), Real.sqrt_mul (by positivity)],
    show √(2 * π) = √2 * √π by rw [Real.sqrt_mul (by positivity)],
    show √(m * π) = √m * √π by rw [Real.sqrt_mul (by positivity)]]
  have hGm : 0 < Gamma ((m : ℝ) / 2) := Real.Gamma_pos_of_pos (by positivity)
  simp only [inv_pow, mul_pow]
  field_simp
  ring

/-- Given `S > 0`, the law of `z / √(S/m)` for a standard normal `z` has density `qd m S`. -/
lemma inner_law (m : ℕ) (hm : 0 < m) (S : ℝ) (hS : 0 < S) (A : Set ℝ) (hA : MeasurableSet A) :
    gaussianReal 0 1 ((fun z => z / √(S / m)) ⁻¹' A) = ∫⁻ t in A, ENNReal.ofReal (qd m S t) := by
  have hmpos : (0 : ℝ) < m := by exact_mod_cast hm
  have hc : 0 < √(S / m) := Real.sqrt_pos.2 (by positivity)
  rw [← Measure.map_apply (by fun_prop) hA, gaussianReal_map_div_const, gaussianReal_apply _ (by
    apply ne_of_gt; apply div_pos one_pos; rw [← NNReal.coe_pos, NNReal.coe_mk]; positivity)]
  refine setLIntegral_congr_fun hA fun t _ => ?_
  simp only [gaussianPDF, gaussianPDFReal, qd]
  congr 1
  simp only [NNReal.coe_div, NNReal.coe_one, NNReal.coe_mk, Real.sq_sqrt (by positivity : 0 ≤ S / m),
    zero_div, sub_zero]
  rw [show 2 * π * (1 / (S / m)) = 2 * π * m / S by field_simp, Real.sqrt_div' _ hS.le,
    show -t ^ 2 / (2 * (1 / (S / m))) = -(t ^ 2 * S) / (2 * m) by field_simp, inv_div]

/-- **Student t law.** If `z` is standard normal and independent of `w₁, …, w_m`, which are independent standard normals, then `z / √((∑ wₖ²)/m)` has the Student t density with `m` degrees of freedom. -/
lemma t_law (m : ℕ) (hm : 0 < m) :
    ((gaussianReal 0 1).prod (Measure.pi fun _ : Fin m => gaussianReal 0 1)).map
      (fun p => p.1 / √((∑ k, p.2 k ^ 2) / m)) =
      volume.withDensity (fun t => ENNReal.ofReal (studentTPDF m t)) := by
  ext A hA
  rw [Measure.map_apply (by fun_prop) hA, withDensity_apply _ hA,
    Measure.prod_apply_symm (measurableSet_preimage (by fun_prop) hA)]
  have hae : ∀ᵐ w ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1), 0 < ∑ k, w k ^ 2 := by
    have h0 : (Measure.pi fun _ : Fin m => gaussianReal 0 1) {w | w ⟨0, hm⟩ = 0} = 0 := by
      have := (measurePreserving_eval (fun _ : Fin m => gaussianReal 0 1) ⟨0, hm⟩).measure_preimage
        (s := {0}) (measurableSet_singleton _).nullMeasurableSet
      rw [show {w : Fin m → ℝ | w ⟨0, hm⟩ = 0} = (Function.eval ⟨0, hm⟩) ⁻¹' {0} from rfl, this]
      have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
      exact measure_singleton 0
    filter_upwards [measure_eq_zero_iff_ae_notMem.1 h0] with w hw
    have hw : w ⟨0, hm⟩ ≠ 0 := hw
    exact lt_of_lt_of_le (by positivity) (Finset.single_le_sum (fun k _ => sq_nonneg (w k))
      (Finset.mem_univ _))
  calc _ = ∫⁻ w, (∫⁻ t in A, ENNReal.ofReal (qd m (∑ k, w k ^ 2) t))
        ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1) := by
        refine lintegral_congr_ae ?_
        filter_upwards [hae] with w hw
        exact inner_law m hm _ hw A hA
    _ = ∫⁻ t in A, (∫⁻ w, ENNReal.ofReal (qd m (∑ k, w k ^ 2) t)
        ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1)) := by
        refine lintegral_lintegral_swap ?_
        unfold qd
        exact Measurable.aemeasurable (by fun_prop)
    _ = _ := by simp_rw [key_K m hm]

/-- A function whose law is a normal law with positive variance is almost everywhere measurable. -/
lemma aemeasurable_of_map_gaussianReal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {f : Ω → ℝ} {μ : ℝ} {v : ℝ≥0} (hv : v ≠ 0)
    (h : P.map f = gaussianReal μ v) : AEMeasurable f P := by
  by_contra hf
  have h3 : ∀ x : ℝ, (P.map f) {x} = 0 := by
    rw [h]; intro x
    have := nullSingletonClass_gaussianReal (μ := μ) hv
    exact measure_singleton x
  rw [Measure.map_of_not_aemeasurable_of_ne_zero hf (IsProbabilityMeasure.ne_zero P)] at h3
  have := h3 (@Classical.ofNonempty ℝ _)
  simp at this

/-- Independent normal noises with variance `σ²`, divided by `σ`, are independent standard normals. -/
lemma noise_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (σ : ℝ≥0) (hσ : 0 < σ) (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2)) :
    P.map (fun ω i => ε i ω / σ) = Measure.pi (fun _ => gaussianReal 0 1) := by
  have hσ2 : σ ^ 2 ≠ 0 := by positivity
  have hm : ∀ i, AEMeasurable (ε i) P := fun i => aemeasurable_of_map_gaussianReal hσ2 (hlaw i)
  have h1 := (iIndepFun_iff_map_fun_eq_pi_map hm).1 hind
  have h2 : (fun ω i => ε i ω / σ) = (fun z : Fin n → ℝ => fun i => z i / σ) ∘ (fun ω i => ε i ω) := rfl
  rw [h2, ← AEMeasurable.map_map_of_aemeasurable (Measurable.aemeasurable (by fun_prop))
    (AEMeasurable.of_eval hm), h1, funext hlaw,
    Measure.pi_map_pi (f := fun _ (x : ℝ) => x / (σ : ℝ)) (fun i => by fun_prop)]
  congr 1
  funext i
  rw [gaussianReal_map_div_const]
  congr 1
  · simp
  · ext; simp [hσ.ne']

/-- Rotating `N` independent standard normals into another orthonormal basis gives `N` independent standard normals. -/
lemma rotation_law {N : ℕ} (b : OrthonormalBasis (Fin N) ℝ (EuclideanSpace ℝ (Fin N))) :
    (Measure.pi (fun _ : Fin N => gaussianReal 0 1)).map
      (fun z k => inner ℝ (b k) (WithLp.toLp 2 z)) = Measure.pi (fun _ => gaussianReal 0 1) := by
  have h1 : (fun z : Fin N → ℝ => fun k => inner ℝ (b k) (WithLp.toLp 2 z)) =
      WithLp.ofLp ∘ b.repr ∘ WithLp.toLp 2 := by
    funext z k; simp [OrthonormalBasis.repr_apply_apply]
  have h2 : (stdGaussian (EuclideanSpace ℝ (Fin N))).map WithLp.ofLp =
      Measure.pi (fun _ : Fin N => gaussianReal 0 1) := by
    rw [← map_pi_eq_stdGaussian, Measure.map_map (by fun_prop) (by fun_prop)]
    rw [show (WithLp.ofLp ∘ WithLp.toLp 2 : (Fin N → ℝ) → (Fin N → ℝ)) = id from rfl, Measure.map_id]
  rw [h1, ← Measure.map_map (by fun_prop) (by fun_prop), ← Measure.map_map (by fun_prop) (by fun_prop),
    map_pi_eq_stdGaussian]
  rw [stdGaussian_map b.repr, h2]

/-- Dropping the first of `m + 1` independent standard normals leaves `m` independent standard normals. -/
lemma tail_law (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map (fun u k => u (Fin.succ k)) =
      Measure.pi (fun _ : Fin m => gaussianReal 0 1) := by
  have h := (measurePreserving_piFinSuccAbove (fun _ : Fin (m + 1) => gaussianReal 0 1) 0).map_eq
  have h2 : (fun u : Fin (m + 1) → ℝ => fun k => u (Fin.succ k)) =
      Prod.snd ∘ (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 1) => ℝ) 0) := by
    funext u k; simp [MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [h2, ← Measure.map_map measurable_snd (MeasurableEquiv.measurable _), h, Measure.map_snd_prod]
  simp

/-- The first of `m + 2` independent standard normals is independent of the last `m`. -/
lemma proj_law (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 2) => gaussianReal 0 1)).map
      (fun u => (u 0, fun k : Fin m => u k.succ.succ)) =
      (gaussianReal 0 1).prod (Measure.pi (fun _ : Fin m => gaussianReal 0 1)) := by
  have h := (measurePreserving_piFinSuccAbove (fun _ : Fin (m + 2) => gaussianReal 0 1) 0).map_eq
  have h2 : (fun u : Fin (m + 2) → ℝ => (u 0, fun k : Fin m => u k.succ.succ)) =
      Prod.map id (fun v : Fin (m + 1) → ℝ => fun k => v k.succ) ∘
        (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 2) => ℝ) 0) := by
    funext u; simp [MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [h2, ← Measure.map_map (by fun_prop) (MeasurableEquiv.measurable _), h,
    ← Measure.map_prod_map _ _ measurable_id (by fun_prop), Measure.map_id]
  rw [tail_law]

/-- If `v` and `a` are independent standard normals, then `(v − α a) / √(1 + α²)` is standard normal. -/
lemma combo_law (α : ℝ) :
    ((gaussianReal 0 1).prod (gaussianReal 0 1)).map (fun p : ℝ × ℝ => (p.1 - α * p.2) / √(1 + α ^ 2)) =
      gaussianReal 0 1 := by
  have h : (fun p : ℝ × ℝ => (p.1 - α * p.2) / √(1 + α ^ 2)) =
      (fun x => x / √(1 + α ^ 2)) ∘ (fun p : ℝ × ℝ => p.1 + p.2) ∘ Prod.map id (fun a => (-α) * a) := by
    funext p; simp [sub_eq_add_neg]
  rw [h, ← Measure.map_map (by fun_prop) (by fun_prop), ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_prod_map _ _ measurable_id (by fun_prop), Measure.map_id, gaussianReal_map_const_mul]
  change (Measure.conv _ _).map _ = _
  rw [gaussianReal_conv_gaussianReal, gaussianReal_map_div_const]
  congr 1
  · simp
  · ext
    simp only [NNReal.coe_div, NNReal.coe_add, NNReal.coe_one, NNReal.coe_mk, mul_one]
    rw [Real.sq_sqrt (by positivity), neg_sq, div_self (by positivity)]

/-- A new independent standard normal mixed with the first rotated coordinate stays independent of the last `m` coordinates. -/
lemma newday_law (m : ℕ) (α : ℝ) :
    ((gaussianReal 0 1).prod (Measure.pi fun _ : Fin (m + 2) => gaussianReal 0 1)).map
      (fun p => ((p.1 - α * p.2 0) / √(1 + α ^ 2), fun k : Fin m => p.2 k.succ.succ)) =
      (gaussianReal 0 1).prod (Measure.pi fun _ : Fin m => gaussianReal 0 1) := by
  have h : (fun p : ℝ × (Fin (m + 2) → ℝ) =>
      ((p.1 - α * p.2 0) / √(1 + α ^ 2), fun k : Fin m => p.2 k.succ.succ)) =
      Prod.map (fun p : ℝ × ℝ => (p.1 - α * p.2) / √(1 + α ^ 2)) id ∘
        (MeasurableEquiv.prodAssoc (α := ℝ) (β := ℝ) (γ := Fin m → ℝ)).symm ∘
        Prod.map id (fun u : Fin (m + 2) → ℝ => (u 0, fun k : Fin m => u k.succ.succ)) := by
    funext p; simp [MeasurableEquiv.prodAssoc]
  rw [h, ← Measure.map_map (by fun_prop) (by fun_prop), ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_prod_map _ _ measurable_id (by fun_prop), Measure.map_id, proj_law,
    (measurePreserving_prodAssoc (gaussianReal 0 1) (gaussianReal 0 1)
      (Measure.pi fun _ : Fin m => gaussianReal 0 1)).symm.map_eq,
    ← Measure.map_prod_map _ _ (by fun_prop) measurable_id, Measure.map_id, combo_law]

/-- `(∑ eᵢ) / √n`. -/
def a1 (e : Fin n → ℝ) : ℝ := (∑ i, e i) / √n
/-- `(∑ (xᵢ − x̄) eᵢ) / √S_xx`. -/
def ax (x e : Fin n → ℝ) : ℝ := (∑ i, (x i - mean x) * e i) / √(Sxx x)
/-- The vector `α · 1/√n + β · (x − x̄)/√S_xx`. -/
def comb (x : Fin n → ℝ) (α β : ℝ) : Fin n → ℝ := fun i => α / √n + β * ((x i - mean x) / √(Sxx x))

/-- The deviations from the mean add up to zero. -/
lemma sum_dev (x : Fin n → ℝ) (hn : n ≠ 0) : ∑ i, (x i - mean x) = 0 := by
  rw [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, mean]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  field_simp
  ring

/-- `∑ (xᵢ − x̄) xᵢ = S_xx`. -/
lemma sum_dev_mul (x : Fin n → ℝ) (hn : n ≠ 0) : ∑ i, (x i - mean x) * x i = Sxx x := by
  have : ∀ i, (x i - mean x) * x i = (x i - mean x) ^ 2 + mean x * (x i - mean x) := fun i => by ring
  simp_rw [this, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, mul_zero, add_zero, Sxx]

/-- If the temperatures are not all equal, then `S_xx > 0`. -/
lemma Sxx_pos (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j) : 0 < Sxx x := by
  obtain ⟨i, j, hij⟩ := hx
  refine lt_of_le_of_ne (Finset.sum_nonneg fun k _ => sq_nonneg _) fun h => hij ?_
  have h' := (Finset.sum_eq_zero_iff_of_nonneg (fun k _ => sq_nonneg (x k - mean x))).1 h.symm
  have hi := h' i (Finset.mem_univ _)
  have hj := h' j (Finset.mem_univ _)
  have : x i - mean x = 0 := pow_eq_zero_iff (two_ne_zero) |>.1 hi
  have : x j - mean x = 0 := pow_eq_zero_iff (two_ne_zero) |>.1 hj
  linarith

/-- The mean of the model values `β₀ + β₁ xᵢ + eᵢ`. -/
lemma mean_model (x e : Fin n → ℝ) (β₀ β₁ : ℝ) (hn : n ≠ 0) :
    mean (fun i => β₀ + β₁ * x i + e i) = β₀ + β₁ * mean x + mean e := by
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  simp only [mean, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
    nsmul_eq_mul, ← Finset.mul_sum]
  field_simp

/-- The fitted slope under the model is the true slope plus a weighted sum of the noise. -/
lemma slope_model (x e : Fin n → ℝ) (β₀ β₁ : ℝ) (hn : n ≠ 0) (hS : Sxx x ≠ 0) :
    slope x (fun i => β₀ + β₁ * x i + e i) = β₁ + (∑ i, (x i - mean x) * e i) / Sxx x := by
  have : ∀ i, (x i - mean x) * (β₀ + β₁ * x i + e i) =
      β₀ * (x i - mean x) + β₁ * ((x i - mean x) * x i) + (x i - mean x) * e i := fun i => by ring
  simp only [slope]
  simp_rw [this, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, sum_dev_mul x hn]
  field_simp
  ring

/-- The forecast error at `x₀` under the model. -/
lemma forecast_model (x e : Fin n → ℝ) (β₀ β₁ x0 : ℝ) (hn : n ≠ 0) (hS : Sxx x ≠ 0) :
    intercept x (fun i => β₀ + β₁ * x i + e i) + slope x (fun i => β₀ + β₁ * x i + e i) * x0 -
      (β₀ + β₁ * x0) = mean e + (∑ i, (x i - mean x) * e i) / Sxx x * (x0 - mean x) := by
  rw [intercept, mean_model x e β₀ β₁ hn, slope_model x e β₀ β₁ hn hS]
  ring

/-- The leftover sum of squares under the model, written with the noise only. -/
lemma SSE_model (x e : Fin n → ℝ) (β₀ β₁ : ℝ) (hn : n ≠ 0) (hS : Sxx x ≠ 0) :
    SSE x (fun i => β₀ + β₁ * x i + e i) =
      ∑ i, e i ^ 2 - (∑ i, e i) ^ 2 / n - (∑ i, (x i - mean x) * e i) ^ 2 / Sxx x := by
  set B := (∑ i, (x i - mean x) * e i) / Sxx x with hB
  have hres : ∀ i, (β₀ + β₁ * x i + e i) - intercept x (fun i => β₀ + β₁ * x i + e i) -
      slope x (fun i => β₀ + β₁ * x i + e i) * x i = e i - mean e - B * (x i - mean x) := by
    intro i; rw [intercept, mean_model x e β₀ β₁ hn, slope_model x e β₀ β₁ hn hS]; ring
  have hexp : ∀ i, (e i - mean e - B * (x i - mean x)) ^ 2 = e i ^ 2 + (-2 * mean e) * e i +
      (-2 * B) * ((x i - mean x) * e i) + mean e ^ 2 + (2 * mean e * B) * (x i - mean x) +
      B ^ 2 * (x i - mean x) ^ 2 := fun i => by ring
  simp only [SSE, hres, hexp, Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, sum_dev x hn]
  rw [show ∑ i, (x i - mean x) ^ 2 = Sxx x from rfl, hB, mean]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  field_simp
  ring

/-- Inner product of a combination vector with any vector. -/
lemma inner_comb (x : Fin n → ℝ) (α β : ℝ) (e : Fin n → ℝ) :
    inner ℝ (WithLp.toLp 2 (comb x α β)) (WithLp.toLp 2 e) = α * a1 e + β * ax x e := by
  simp only [PiLp.inner_apply, comb, a1, ax, RCLike.inner_apply, conj_trivial]
  simp only [mul_div_assoc', Finset.mul_sum, Finset.sum_div, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => by ring

/-- The `1/√n` coordinate of a combination vector. -/
lemma a1_comb (x : Fin n → ℝ) (α β : ℝ) (hn : n ≠ 0) : a1 (comb x α β) = α := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero hn
  have h : ∀ i, comb x α β i = α / √n + (β / √(Sxx x)) * (x i - mean x) := fun i => by
    simp only [comb]; ring
  simp only [a1, h, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, mul_zero, add_zero,
    Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have : √(n : ℝ) ≠ 0 := (Real.sqrt_pos.2 hn').ne'
  field_simp
  rw [Real.sq_sqrt hn'.le]
  ring

/-- The `(x − x̄)/√S_xx` coordinate of a combination vector. -/
lemma ax_comb (x : Fin n → ℝ) (α β : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) : ax x (comb x α β) = β := by
  have h : ∀ i, (x i - mean x) * comb x α β i =
      (α / √n) * (x i - mean x) + (β / √(Sxx x)) * (x i - mean x) ^ 2 := fun i => by
    simp only [comb]; ring
  simp only [ax, h, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, mul_zero, zero_add]
  rw [show ∑ i, (x i - mean x) ^ 2 = Sxx x from rfl]
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  field_simp
  rw [Real.sq_sqrt hS.le]

/-- Inner product of two combination vectors. -/
lemma inner_comb_comb (x : Fin n → ℝ) (α β α' β' : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    inner ℝ (WithLp.toLp 2 (comb x α β)) (WithLp.toLp 2 (comb x α' β')) = α * α' + β * β' := by
  rw [inner_comb, a1_comb x _ _ hn, ax_comb x _ _ hn hS]

/-- Two orthonormal combination vectors extend to an orthonormal basis. -/
lemma exists_basis (m : ℕ) (x : Fin (m + 2) → ℝ) (hS : 0 < Sxx x) (p q : ℝ) (hpq : p ^ 2 + q ^ 2 = 1) :
    ∃ b : OrthonormalBasis (Fin (m + 2)) ℝ (EuclideanSpace ℝ (Fin (m + 2))),
      b 0 = WithLp.toLp 2 (comb x p q) ∧ b 1 = WithLp.toLp 2 (comb x (-q) p) := by
  set v : Fin (m + 2) → EuclideanSpace ℝ (Fin (m + 2)) := fun i =>
    if i = 0 then WithLp.toLp 2 (comb x p q) else WithLp.toLp 2 (comb x (-q) p) with hv
  have hn : m + 2 ≠ 0 := by omega
  have h01 : (1 : Fin (m + 2)) ≠ 0 := by simp
  have hon : Orthonormal ℝ (({0, 1} : Set (Fin (m + 2))).domRestrict v) := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, hi⟩ ⟨j, hj⟩
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hi hj
    simp only [Set.domRestrict_apply, Subtype.mk.injEq, hv]
    rcases hi with rfl | rfl <;> rcases hj with rfl | rfl <;>
      simp only [h01, h01.symm, ite_true, ite_false, inner_comb_comb x _ _ _ _ hn hS] <;>
      linarith
  obtain ⟨b, hb⟩ := Orthonormal.exists_orthonormalBasis_extension_of_card_eq
    (by simp) hon
  refine ⟨b, ?_, ?_⟩
  · rw [hb 0 (by simp)]; simp [hv]
  · rw [hb 1 (by simp)]; simp [hv, h01]

/-- The squared coordinates along the last `m` basis vectors add up to the leftover sum of squares. -/
lemma tail_sq (m : ℕ) (x : Fin (m + 2) → ℝ) (p q : ℝ) (hpq : p ^ 2 + q ^ 2 = 1)
    (b : OrthonormalBasis (Fin (m + 2)) ℝ (EuclideanSpace ℝ (Fin (m + 2))))
    (hb0 : b 0 = WithLp.toLp 2 (comb x p q)) (hb1 : b 1 = WithLp.toLp 2 (comb x (-q) p))
    (z : Fin (m + 2) → ℝ) :
    ∑ k : Fin m, inner ℝ (b k.succ.succ) (WithLp.toLp 2 z) ^ 2 = ∑ i, z i ^ 2 - a1 z ^ 2 - ax x z ^ 2 := by
  have h := b.sum_sq_inner_right (WithLp.toLp 2 z)
  rw [EuclideanSpace.real_norm_sq_eq, Fin.sum_univ_succ, Fin.sum_univ_succ] at h
  simp only [Fin.succ_zero_eq_one, hb0, hb1, inner_comb] at h
  linear_combination h - (a1 z ^ 2 + ax x z ^ 2) * hpq

/-- The slope under the model, with the noise written as `σ · z`. -/
lemma slope_model' (x z : Fin n → ℝ) (β₀ β₁ σ : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    slope x (fun i => β₀ + β₁ * x i + σ * z i) = β₁ + σ * ax x z / √(Sxx x) := by
  rw [slope_model x _ β₀ β₁ hn hS.ne', ax]
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  simp_rw [show ∀ i, (x i - mean x) * (σ * z i) = σ * ((x i - mean x) * z i) from fun i => by ring,
    ← Finset.mul_sum]
  field_simp
  rw [Real.sq_sqrt hS.le]
  ring

/-- The forecast error under the model, with the noise written as `σ · z`. -/
lemma forecast_model' (x z : Fin n → ℝ) (β₀ β₁ σ x0 : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    intercept x (fun i => β₀ + β₁ * x i + σ * z i) + slope x (fun i => β₀ + β₁ * x i + σ * z i) * x0 -
      (β₀ + β₁ * x0) = σ * (a1 z / √n + (x0 - mean x) / √(Sxx x) * ax x z) := by
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  have hn' : (0 : ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero hn
  have : √(n : ℝ) ≠ 0 := (Real.sqrt_pos.2 hn').ne'
  have hmean : mean (fun i => σ * z i) = σ * a1 z / √n := by
    simp only [mean, a1, ← Finset.mul_sum]
    field_simp
    rw [Real.sq_sqrt hn'.le]
  rw [forecast_model x _ β₀ β₁ x0 hn hS.ne', hmean, ax]
  simp_rw [show ∀ i, (x i - mean x) * (σ * z i) = σ * ((x i - mean x) * z i) from fun i => by ring,
    ← Finset.mul_sum]
  field_simp
  rw [Real.sq_sqrt hS.le]
  ring

/-- `SSE` under the model, with the noise written as `σ · z`. -/
lemma SSE_model' (x z : Fin n → ℝ) (β₀ β₁ σ : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    SSE x (fun i => β₀ + β₁ * x i + σ * z i) = σ ^ 2 * (∑ i, z i ^ 2 - a1 z ^ 2 - ax x z ^ 2) := by
  rw [SSE_model x _ β₀ β₁ hn hS.ne', ax, a1]
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  have hn' : (0 : ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero hn
  have : √(n : ℝ) ≠ 0 := (Real.sqrt_pos.2 hn').ne'
  simp_rw [show ∀ i, (x i - mean x) * (σ * z i) = σ * ((x i - mean x) * z i) from fun i => by ring,
    ← Finset.mul_sum, mul_pow σ, ← Finset.mul_sum, div_pow, Real.sq_sqrt hS.le, Real.sq_sqrt hn'.le]
  field_simp

/-- Cancelling `σ` and `K` in the slope ratio. -/
lemma ratio_aux (σ A Q m K : ℝ) (hσ : 0 < σ) (hK : 0 < K) :
    (σ * A / K) / (√(σ ^ 2 * Q / m) / K) = A / √(Q / m) := by
  rw [show σ ^ 2 * Q / m = σ ^ 2 * (Q / m) by ring, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ.le,
    div_div_div_cancel_right₀ hK.ne', mul_div_mul_left _ _ hσ.ne']

/-- Cancelling `σ` and `K` in the mean-forecast ratio. -/
lemma ratio_aux' (σ A Q m K : ℝ) (hσ : 0 < σ) (hK : 0 < K) :
    (σ * (K * A)) / (√(σ ^ 2 * Q / m) * K) = A / √(Q / m) := by
  rw [show σ ^ 2 * Q / m = σ ^ 2 * (Q / m) by ring, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ.le,
    show σ * (K * A) = (σ * K) * A by ring, show σ * √(Q / m) * K = (σ * K) * √(Q / m) by ring,
    mul_div_mul_left _ _ (mul_pos hσ hK).ne']

/-- The noise, scaled to unit variance and rotated into an orthonormal basis, is again a vector
of independent standard normals. -/
lemma rotated_noise_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {N : ℕ} (σ : ℝ≥0) (hσ : 0 < σ) (ε : Fin N → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2))
    (b : OrthonormalBasis (Fin N) ℝ (EuclideanSpace ℝ (Fin N))) :
    AEMeasurable (fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ)))) P ∧
    P.map (fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ)))) =
      Measure.pi (fun _ => gaussianReal 0 1) := by
  have hmeas : ∀ i, AEMeasurable (ε i) P := fun i =>
    aemeasurable_of_map_gaussianReal (by positivity) (hlaw i)
  have hZ : AEMeasurable (fun ω i => ε i ω / (σ : ℝ)) P :=
    AEMeasurable.of_eval fun i => (hmeas i).div_const _
  have hR : Measurable (fun (z : Fin N → ℝ) (k : Fin N) => inner ℝ (b k) (WithLp.toLp 2 z)) := by
    fun_prop
  refine ⟨hR.comp_aemeasurable hZ, ?_⟩
  rw [show (fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ)))) =
    (fun (z : Fin N → ℝ) (k : Fin N) => inner ℝ (b k) (WithLp.toLp 2 z)) ∘
      (fun ω i => ε i ω / (σ : ℝ)) from rfl,
    ← AEMeasurable.map_map_of_aemeasurable hR.aemeasurable hZ, noise_law σ hσ ε hind hlaw,
    rotation_law]

/-- Cancelling `σ` in the new-day ratio. -/
lemma ratio_aux'' (σ B Q m K : ℝ) (hσ : 0 < σ) :
    (σ * B) / (√(σ ^ 2 * Q / m) * K) = (B / K) / √(Q / m) := by
  rw [show σ ^ 2 * Q / m = σ ^ 2 * (Q / m) by ring, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ.le,
    show σ * √(Q / m) * K = σ * (√(Q / m) * K) by ring, mul_div_mul_left _ _ hσ.ne', div_div,
    mul_comm K]

#print axioms lintegral_pi_prod_aux
#print axioms gaussPi_eq_withDensity
#print axioms prod_gaussianPDF
#print axioms key_K
#print axioms inner_law
#print axioms t_law
#print axioms aemeasurable_of_map_gaussianReal
#print axioms noise_law
#print axioms rotation_law
#print axioms tail_law
#print axioms proj_law
#print axioms combo_law
#print axioms newday_law
#print axioms sum_dev
#print axioms sum_dev_mul
#print axioms Sxx_pos
#print axioms mean_model
#print axioms slope_model
#print axioms forecast_model
#print axioms SSE_model
#print axioms inner_comb
#print axioms a1_comb
#print axioms ax_comb
#print axioms inner_comb_comb
#print axioms exists_basis
#print axioms tail_sq
#print axioms slope_model'
#print axioms forecast_model'
#print axioms SSE_model'
#print axioms ratio_aux
#print axioms ratio_aux'
#print axioms rotated_noise_law
#print axioms ratio_aux''

/-- **The slope's t ratio follows Student's t law on n − 2 degrees of freedom.** Take `n ≥ 3`
days at fixed temperatures `x₁, …, xₙ`, not all equal. Suppose each day's sales are the true line
plus noise, `Yᵢ = β₀ + β₁ xᵢ + εᵢ`, where the noises `ε₁, …, εₙ` are independent and each is
normal with mean 0 and the same variance `σ² > 0`. Then the fitted slope's distance from the
true slope, counted in standard errors, `(β̂₁ − β₁) / SE(β̂₁)` with `SE(β̂₁) = s / √S_xx` and
`s² = SSE / (n − 2)`, has Student's t density with `n − 2` degrees of freedom. This is the fact
behind the test of "slope zero" and the interval `β̂₁ ± t_* SE(β̂₁)`. -/
theorem slope_t_ratio_has_student_t_law
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (hn : 3 ≤ n) (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j)
    (β₀ β₁ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2)) :
    P.map (fun ω => (slope x (fun i => β₀ + β₁ * x i + ε i ω) - β₁) /
        seSlope x (fun i => β₀ + β₁ * x i + ε i ω)) =
      volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 2) t)) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  have hm : 0 < m := by omega
  have hn0 : m + 2 ≠ 0 := by omega
  have hS := Sxx_pos x hx
  have hσ' : (0 : ℝ) < σ := hσ
  obtain ⟨b, hb0, hb1⟩ := exists_basis m x hS 0 1 (by norm_num)
  obtain ⟨hUm, hU⟩ := rotated_noise_law σ hσ ε hind hlaw b
  have hcast : ((m + 2 : ℕ) : ℝ) - 2 = m := by push_cast; ring
  rw [hcast, ← t_law m hm, ← proj_law m, Measure.map_map (by fun_prop) (by fun_prop), ← hU,
    AEMeasurable.map_map_of_aemeasurable (by fun_prop) hUm]
  congr 1
  funext ω
  have hε : (fun i => β₀ + β₁ * x i + ε i ω) =
      fun i => β₀ + β₁ * x i + (σ : ℝ) * (ε i ω / σ) := by
    funext i; field_simp
  simp only [Function.comp_apply, hε, seSlope, s2, hcast, slope_model' x _ β₀ β₁ _ hn0 hS,
    SSE_model' x _ β₀ β₁ _ hn0 hS, tail_sq m x 0 1 (by norm_num) b hb0 hb1, hb0, inner_comb,
    zero_mul, zero_add, one_mul, add_sub_cancel_left]
  exact ratio_aux _ _ _ _ _ hσ' (Real.sqrt_pos.2 hS)

/-- **The slope's spread, and the noise estimate (Steps 1 to 3).** Under the same model, the
fitted slope is right on average, `E[β̂₁] = β₁`; its variance is `σ² / S_xx`; and the estimated
noise variance `s² = SSE / (n − 2)` is right on average, `E[s²] = σ²`. -/
theorem slope_unbiased_variance_and_s2_unbiased
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (hn : 3 ≤ n) (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j)
    (β₀ β₁ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2)) :
    ∫ ω, slope x (fun i => β₀ + β₁ * x i + ε i ω) ∂P = β₁ ∧
      variance (fun ω => slope x (fun i => β₀ + β₁ * x i + ε i ω)) P = (σ : ℝ) ^ 2 / Sxx x ∧
      ∫ ω, s2 x (fun i => β₀ + β₁ * x i + ε i ω) ∂P = (σ : ℝ) ^ 2 := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  have hm : 0 < m := by omega
  have hn0 : m + 2 ≠ 0 := by omega
  have hS := Sxx_pos x hx
  have hσ' : (0 : ℝ) < σ := hσ
  obtain ⟨b, hb0, hb1⟩ := exists_basis m x hS 0 1 (by norm_num)
  obtain ⟨hUm, hU⟩ := rotated_noise_law σ hσ ε hind hlaw b
  set U := fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ))) with hUdef
  have hcast : ((m + 2 : ℕ) : ℝ) - 2 = m := by push_cast; ring
  have hε : ∀ ω, (fun i => β₀ + β₁ * x i + ε i ω) =
      fun i => β₀ + β₁ * x i + (σ : ℝ) * (ε i ω / σ) := fun ω => by
    funext i; field_simp
  have hslope : (fun ω => slope x (fun i => β₀ + β₁ * x i + ε i ω)) =
      (fun u : Fin (m + 2) → ℝ => β₁ + σ / √(Sxx x) * u 0) ∘ U := by
    funext ω
    simp only [Function.comp_apply, hε, slope_model' x _ β₀ β₁ _ hn0 hS, hUdef, hb0, inner_comb,
      zero_mul, zero_add, one_mul]
    ring
  have hs2 : (fun ω => s2 x (fun i => β₀ + β₁ * x i + ε i ω)) =
      (fun u : Fin (m + 2) → ℝ => (σ : ℝ) ^ 2 / m * ∑ k : Fin m, u k.succ.succ ^ 2) ∘ U := by
    funext ω
    simp only [Function.comp_apply, hε, s2, SSE_model' x _ β₀ β₁ _ hn0 hS, hcast,
      ← tail_sq m x 0 1 (by norm_num) b hb0 hb1, hUdef]
    ring
  have hsq : ∀ j : Fin (m + 2), ∫ u, u j ^ 2 ∂(Measure.pi fun _ : Fin (m + 2) => gaussianReal 0 1) = 1 := by
    intro j
    rw [integral_comp_eval (X := fun _ : Fin (m + 2) => ℝ) (μ := fun _ => gaussianReal 0 1) (i := j)
        (f := fun x : ℝ => x ^ 2) (by fun_prop)]
    have h1 : Var[id; gaussianReal 0 1] = ∫ x, x ^ 2 ∂gaussianReal 0 1 :=
      variance_of_integral_eq_zero aemeasurable_id (by simp)
    rw [← h1, variance_id_gaussianReal]
    simp
  have hint : ∀ g : (Fin (m + 2) → ℝ) → ℝ, Measurable g →
      ∫ ω, (g ∘ U) ω ∂P = ∫ u, g u ∂(Measure.pi fun _ : Fin (m + 2) => gaussianReal 0 1) :=
    fun g hg => by rw [← hU, integral_map hUm hg.aestronglyMeasurable]; rfl
  have hv0 : Var[fun u : Fin (m + 2) → ℝ => u 0; Measure.pi fun _ => gaussianReal 0 1] = 1 := by
    rw [show (fun u : Fin (m + 2) → ℝ => u 0) = fun u => id (Function.eval 0 u) from rfl,
      (measurePreserving_eval (fun _ : Fin (m + 2) => gaussianReal 0 1) 0).variance_fun_comp
        aemeasurable_id, variance_id_gaussianReal]
    simp
  refine ⟨?_, ?_, ?_⟩
  · rw [hslope, hint _ (by fun_prop),
      integral_add (integrable_const _) ((integrable_eval IsGaussian.integrable_id).const_mul _),
      integral_const_mul, integral_eval, integral_id_gaussianReal]
    simp
  · rw [hslope, ← variance_map (Measurable.aemeasurable (by fun_prop)) hUm, hU,
      variance_const_add (Measurable.aestronglyMeasurable (by fun_prop)),
      variance_const_mul, hv0, div_pow, Real.sq_sqrt hS.le, mul_one]
  · rw [hs2, hint _ (by fun_prop), integral_const_mul,
      integral_finsetSum _ (fun k _ => ?_)]
    · simp only [hsq, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, mul_one]
      have : (m : ℝ) ≠ 0 := by exact_mod_cast hm.ne'
      field_simp
    · exact integrable_comp_eval (X := fun _ : Fin (m + 2) => ℝ) (μ := fun _ => gaussianReal 0 1)
        (i := k.succ.succ) (f := fun x : ℝ => x ^ 2)
        ((memLp_id_gaussianReal (μ := 0) (v := 1) 2).integrable_sq)

/-- **The two forecast intervals (Steps 2 and 4).** Under the same model, fix a new temperature
`x₀` and let `ŷ₀ = β̂₀ + β̂₁ x₀` be the line's forecast there. Let a new day's sales be
`Y₀ = β₀ + β₁ x₀ + ε₀`, with its own noise `ε₀` normal with mean 0 and variance `σ²`, independent
of the `n` recorded noises. Then both
* the mean-sales ratio `(ŷ₀ − (β₀ + β₁ x₀)) / (s √h₀)`, and
* the new-day ratio `(Y₀ − ŷ₀) / (s √(1 + h₀))`, with the extra 1 for the new day's own noise,
have Student's t density with `n − 2` degrees of freedom. -/
theorem forecast_t_ratios_have_student_t_law
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (hn : 3 ≤ n) (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j)
    (β₀ β₁ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2))
    (x0 : ℝ) (ε0 : Ω → ℝ) (hind0 : IndepFun ε0 (fun ω i => ε i ω) P)
    (hlaw0 : P.map ε0 = gaussianReal 0 (σ ^ 2)) :
    P.map (fun ω =>
        (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
            slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0 - (β₀ + β₁ * x0)) /
          (√(s2 x (fun i => β₀ + β₁ * x i + ε i ω)) * √(h0 x x0))) =
        volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 2) t)) ∧
      P.map (fun ω =>
        (β₀ + β₁ * x0 + ε0 ω -
            (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
              slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0)) /
          (√(s2 x (fun i => β₀ + β₁ * x i + ε i ω)) * √(1 + h0 x x0))) =
        volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 2) t)) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  have hm : 0 < m := by omega
  have hn0 : m + 2 ≠ 0 := by omega
  have hS := Sxx_pos x hx
  have hσ' : (0 : ℝ) < σ := hσ
  have hn' : (0 : ℝ) < ((m + 2 : ℕ) : ℝ) := by positivity
  have hhpos : 0 < h0 x x0 := by rw [h0]; positivity
  set p := (1 / √((m + 2 : ℕ) : ℝ)) / √(h0 x x0) with hp
  set q := ((x0 - mean x) / √(Sxx x)) / √(h0 x x0) with hq
  have hpq : p ^ 2 + q ^ 2 = 1 := by
    rw [hp, hq, div_pow, div_pow, div_pow, div_pow, Real.sq_sqrt hhpos.le, Real.sq_sqrt hS.le,
      Real.sq_sqrt hn'.le, ← add_div, one_pow]
    exact div_self hhpos.ne'
  obtain ⟨b, hb0, hb1⟩ := exists_basis m x hS p q hpq
  obtain ⟨hUm, hU⟩ := rotated_noise_law σ hσ ε hind hlaw b
  set U := fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ))) with hUdef
  have hcast : ((m + 2 : ℕ) : ℝ) - 2 = m := by push_cast; ring
  have hε : ∀ ω, (fun i => β₀ + β₁ * x i + ε i ω) =
      fun i => β₀ + β₁ * x i + (σ : ℝ) * (ε i ω / σ) := fun ω => by
    funext i; field_simp
  have hkey : ∀ z : Fin (m + 2) → ℝ, a1 z / √((m + 2 : ℕ) : ℝ) + (x0 - mean x) / √(Sxx x) * ax x z =
      √(h0 x x0) * (p * a1 z + q * ax x z) := by
    intro z
    have : √(h0 x x0) ≠ 0 := (Real.sqrt_pos.2 hhpos).ne'
    rw [hp, hq]
    field_simp
  have hfc : ∀ ω, intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
      slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0 - (β₀ + β₁ * x0) =
      (σ : ℝ) * (√(h0 x x0) * U ω 0) := by
    intro ω
    rw [hε ω, forecast_model' x _ β₀ β₁ _ x0 hn0 hS, hkey]
    simp only [hUdef, hb0, inner_comb]
  have hs2 : ∀ ω, s2 x (fun i => β₀ + β₁ * x i + ε i ω) =
      (σ : ℝ) ^ 2 * (∑ k : Fin m, U ω k.succ.succ ^ 2) / m := by
    intro ω
    rw [hε ω, s2, SSE_model' x _ β₀ β₁ _ hn0 hS, hcast, ← tail_sq m x p q hpq b hb0 hb1]
  constructor
  · rw [hcast, ← t_law m hm, ← proj_law m, Measure.map_map (by fun_prop) (by fun_prop), ← hU,
      AEMeasurable.map_map_of_aemeasurable (by fun_prop) hUm]
    congr 1
    funext ω
    rw [hfc ω, hs2 ω]
    exact ratio_aux' _ _ _ _ _ hσ' (Real.sqrt_pos.2 hhpos)
  · have hε0m : AEMeasurable ε0 P := aemeasurable_of_map_gaussianReal (by positivity) hlaw0
    have hV : P.map (fun ω => ε0 ω / σ) = gaussianReal 0 1 := by
      rw [show (fun ω => ε0 ω / (σ : ℝ)) = (fun t => t / (σ : ℝ)) ∘ ε0 from rfl,
        ← AEMeasurable.map_map_of_aemeasurable (by fun_prop) hε0m, hlaw0, gaussianReal_map_div_const]
      congr 1
      · simp
      · ext; simp [hσ.ne']
    have hψ : Measurable (fun (e : Fin (m + 2) → ℝ) (k : Fin (m + 2)) =>
        inner ℝ (b k) (WithLp.toLp 2 (fun i => e i / (σ : ℝ)))) := by fun_prop
    have hφ : Measurable (fun t : ℝ => t / (σ : ℝ)) := by fun_prop
    have hindVU : IndepFun (fun ω => ε0 ω / σ) U P := hind0.comp hφ hψ
    have hVU : P.map (fun ω => (ε0 ω / σ, U ω)) =
        (gaussianReal 0 1).prod (Measure.pi fun _ => gaussianReal 0 1) := by
      rw [(indepFun_iff_map_prod_eq_prod_map_map (hε0m.div_const _) hUm).1 hindVU, hV, hU]
    rw [hcast, ← t_law m hm, ← newday_law m (√(h0 x x0)), ← hVU,
      Measure.map_map (by fun_prop) (by fun_prop),
      AEMeasurable.map_map_of_aemeasurable (by fun_prop) ((hε0m.div_const _).prodMk hUm)]
    congr 1
    funext ω
    rw [hs2 ω, Real.sq_sqrt hhpos.le,
      show β₀ + β₁ * x0 + ε0 ω - (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
          slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0) =
        ε0 ω - (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
          slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0 - (β₀ + β₁ * x0)) by ring, hfc ω,
      show ε0 ω - (σ : ℝ) * (√(h0 x x0) * U ω 0) = (σ : ℝ) * (ε0 ω / σ - √(h0 x x0) * U ω 0) by
        field_simp]
    exact ratio_aux'' _ _ _ _ _ hσ'

/-! The card's café: ten days at 16, 18, …, 34 °C. -/

/-- Midday temperatures, °C. -/
def temps : Fin 10 → ℝ := ![16, 18, 20, 22, 24, 26, 28, 30, 32, 34]

/-- Iced coffees sold. -/
def sales : Fin 10 → ℝ := ![37, 33, 34, 31, 35, 49, 40, 53, 50, 38]

-- Averages: 25 °C and 40 coffees.
example : mean temps = 25 ∧ mean sales = 40 := by
  norm_num [mean, temps, sales, Fin.sum_univ_succ]
-- S_xx = 330.
example : Sxx temps = 330 := by
  norm_num [Sxx, mean, temps, Fin.sum_univ_succ]
-- The slope is 264 / 330 = 0.8 coffees per degree, and the intercept is 20.
example : slope temps sales = 4 / 5 ∧ intercept temps sales = 20 := by
  norm_num [intercept, slope, Sxx, mean, temps, sales, Fin.sum_univ_succ]
-- SSE = 342.8, so s² = 342.8 / 8 = 42.85.
example : SSE temps sales = 1714 / 5 ∧ s2 temps sales = 857 / 20 := by
  norm_num [s2, SSE, intercept, slope, Sxx, mean, temps, sales, Fin.sum_univ_succ]
-- The F road: S_yy − SSE = 554 − 342.8 = 211.2 = slope² · S_xx.
example : (554 : ℚ) - 1714 / 5 = (4 / 5) ^ 2 * 330 := by norm_num
-- At 30 °C: the line predicts 44, and h₀ = 1/10 + 25/330 = 29/165 (about 0.1758).
example : intercept temps sales + slope temps sales * 30 = 44 ∧ h0 temps 30 = 29 / 165 := by
  norm_num [h0, intercept, slope, Sxx, mean, temps, sales, Fin.sum_univ_succ]

#print axioms slope_t_ratio_has_student_t_law
#print axioms slope_unbiased_variance_and_s2_unbiased
#print axioms forecast_t_ratios_have_student_t_law

end RegressionInference
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'RegressionInference.lintegral_pi_prod_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.gaussPi_eq_withDensity' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.prod_gaussianPDF' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.key_K' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.inner_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.t_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.aemeasurable_of_map_gaussianReal' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.noise_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.rotation_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.tail_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.proj_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.combo_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.newday_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.sum_dev' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.sum_dev_mul' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.Sxx_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.mean_model' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.slope_model' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.forecast_model' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.SSE_model' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.inner_comb' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.a1_comb' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.ax_comb' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.inner_comb_comb' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.exists_basis' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.tail_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.slope_model'' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.forecast_model'' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.SSE_model'' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.ratio_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.ratio_aux'' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.rotated_noise_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.ratio_aux''' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.slope_t_ratio_has_student_t_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.slope_unbiased_variance_and_s2_unbiased' depends on axioms: [propext, Classical.choice, Quot.sound]
'RegressionInference.forecast_t_ratios_have_student_t_law' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Make the days independent again.** In the second simulation, change `cafes(0.0, 0.8)` to `cafes(0.0, 0.0)`. The false-alarm rate falls from 0.4001 to 0.0497, the promised 5 percent, and the last assert stops the run because nothing is broken any more.
> - **Forecast a 40 °C day.** Set `X0` to 40, beyond every recorded day. The forecast is 52 coffees; the mean interval widens to 38.65 to 65.35 and one day to 31.85 to 72.15, because h grows to 0.7818. The mean-sales interval now holds a new day 83 percent of the time, and all checks still pass: the formula knows how far out it is, though not whether the line still holds at 40 °C.
> - **Give the hottest day a strong 58 coffees instead of 38.** Change the last sales figure. The slope rises to 1.3455, t to 4.4941, p to 0.0020, and the interval, 0.6551 to 2.0358, clears zero. The assert pinned to the hand table's 0.8 stops the run. One day moved the verdict: see [Diagnostics](04-diagnostics-and-residuals.md).

---

## The usual mistake

> [!warning]
> **Reading "not significant" as "no effect".** The interval, −0.031 to 1.631, contains zero, and it also contains 1.5 coffees a degree. Ten days cannot tell a flat café from a strongly heat-driven one. The honest report is the slope with its interval, not a verdict. The same goes the other way: a p-value below 0.05 is not the chance the slope is real, and a real slope is not proof that heat causes sales; a school holiday that falls in the hot weeks would do the same.
>
> - **The mean interval as a forecast.** "44 ± 6.33" describes the average 30 °C day; one day needs 44 ± 16.37. The narrow one holds a single day about 60 percent of the time.
> - **1.96 with ten points.** With 8 degrees of freedom the cutoff is 2.306. Using 1.96 turns p = 0.057 into 0.026 and fires on 8.6 percent of flat cafés.
> - **n in the divisor.** s comes out at 5.855 instead of 6.546, every error bar shrinks by the factor √(8/10), and t becomes 2.482.
> - **The interval as a statement about this slope.** "95 percent" describes the recipe: over many cafés, 95 in 100 of its intervals hold the true slope (the simulation counts 0.9521). This café's interval either holds it or does not.

---

## Where you meet it in real life

- **Every regression table.** Statistics software prints each coefficient with a standard error, a t value and a p-value; these are the four columns derived here, for one predictor.
- **Calibration in a laboratory.** A machine's reading is fitted against known standards, and the prediction interval says how far an unknown sample's reading can be trusted.
- **Stock planning.** Stock is ordered for one particular day, so the forecast needs the prediction interval.
- **Finance.** A stock's beta is a regression slope, and its standard error says how much of it is noise; the finance wing uses this card's formulas there.
- **Checking the assumptions.** The leftovers themselves test the model: [Diagnostics](04-diagnostics-and-residuals.md).

> **Say it back**
> The fitted slope is the true slope plus a weighted sum of the days' noise, so its variance is the noise variance over the temperatures' spread. The noise is estimated from the leftovers, dividing by n − 2 because the line used two of them. The slope divided by its standard error follows Student's t with n − 2 degrees, which gives both the test and the interval. A forecast for the mean at a new temperature carries the line's uncertainty; a forecast for one day adds that day's own noise. For the café, 0.8 ± 0.83 coffees per degree: ten days cannot yet rule out zero.

---

## What this builds on

- [Least squares](01-least-squares-regression.md): the fitted line, its slope as a cross sum over $S_{xx}$, and the leftovers that add to zero.
- [Confidence intervals](../08-Confidence%20Intervals%20and%20Tests/01-confidence-intervals.md): the t interval for one mean, and what "95 percent" promises; this card runs the same recipe on a slope.

## Where this goes next

- [Multiple regression](03-multiple-regression-and-gauss-markov.md): several predictors at once, the matrix form of these variances, and why least squares has the smallest ones among unbiased linear fits. It shows how a slope changes once other predictors enter the fit: there, a house's floor area once its age and distance to the station are held fixed.

Ten days gave heat the credit for everything that moves with it, such as a school holiday in the hot weeks; what the slope becomes once a second cause is held fixed is the question this card leaves open.

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Student. "The Probable Error of a Mean." *Biometrika* 6, no. 1 (1908): 1–25. [doi:10.2307/2331554](https://doi.org/10.2307/2331554). The t law for a mean whose spread is estimated from the same data.
- Fisher, R. A. "The Goodness of Fit of Regression Formulae, and the Distribution of Regression Coefficients." *Journal of the Royal Statistical Society* 85, no. 4 (1922): 597–612. [doi:10.2307/2341124](https://doi.org/10.2307/2341124). Shows the fitted coefficient over its estimated standard error follows Student's law, with the degrees reduced by the coefficients fitted.
- Seber, George A. F., and Alan J. Lee. *Linear Regression Analysis*, 2nd ed. Wiley, 2003. [Publisher page](https://www.wiley.com/en-us/Linear+Regression+Analysis%2C+2nd+Edition-p-9780471415404). The projection proof of independence and the chi-square law, in full.
- Weisberg, Sanford. *Applied Linear Regression*, 4th ed. Wiley, 2014. [Publisher page](https://www.wiley.com/en-us/Applied+Linear+Regression%2C+4th+Edition-p-9781118386088). Standard errors, the t test, and the mean and prediction intervals for one predictor, with worked data.
