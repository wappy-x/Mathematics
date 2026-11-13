# The reference distributions: chi-square, t and F, and where each comes from

[Syllabus](../../../SYLLABUS.md) → [Probability and statistics](../README.md) → [Sampling and Estimation](../README.md#s07) → The reference distributions

---

## General Overview

A machine fills bags of flour labelled 500 grams. An inspector pulls ten bags off the line and weighs them: 507, 498, 505, 500, 503, 502, 501, 497, 505 and 502 grams. The average is 502. Is the machine overfilling, or are two extra grams the luck of ten bags?

If the machine's spread were known, the answer would come from the standard error ([Standard error](02-sample-mean-and-standard-error.md)). Nobody knows it. The same ten bags must supply the spread as well as the average. Their sample standard deviation is 3.162 grams, so the standard error is 3.162/√10 = 1.000 gram, and the average sits 2.000 standard errors above the label.

Read 2.000 against the normal curve and a gap that large, either way, turns up 4.55 percent of the time when the label is right. That treats 3.162 as the true spread. It is a guess from ten bags, and a guess that comes out low makes every gap look big. The honest reference is **Student's t distribution with 9 degrees of freedom** (ten bags, less one used up by the average): 7.66 percent, about 1 time in 13.

Three laws do this work. The **chi-square** law describes a sum of squared standard normals (normal variables with mean 0 and standard deviation 1), and so how a sample's spread scatters. The **t** law describes a standard normal divided by an estimated spread. The **F** law describes a ratio of two estimated spreads, as when a second machine's bags are weighed too. They are called **reference distributions**: the laws a statistic is read against.

**Square independent standard normals and add them: that is chi-square; divide a standard normal by the square root of an independent chi-square per degree of freedom: that is t; divide two independent chi-squares, each per degree of freedom: that is F. For a normal sample, the sample's own statistics follow these laws exactly, with the unknown spread cancelled.**

**What kind of fact this is:** three definitions, one law per construction; that each law has the density shown, and that a normal sample's statistics follow these laws, are theorems proved on this card in Why it works.

### The picture: an estimated spread fattens the tails

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Standard normal against t: density of the ratio"
    x-axis "Gap in standard errors" [-4.0, -3.5, -3.0, -2.5, -2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]
    y-axis "Density (chance per unit of gap)" 0 --> 0.45
    line [0.00, 0.00, 0.00, 0.02, 0.05, 0.13, 0.24, 0.35, 0.40, 0.35, 0.24, 0.13, 0.05, 0.02, 0.00, 0.00, 0.00]
    line [0.00, 0.01, 0.01, 0.03, 0.06, 0.13, 0.23, 0.34, 0.39, 0.34, 0.23, 0.13, 0.06, 0.03, 0.01, 0.01, 0.00]
    line [0.01, 0.02, 0.03, 0.04, 0.07, 0.11, 0.19, 0.30, 0.35, 0.30, 0.19, 0.11, 0.07, 0.04, 0.03, 0.02, 0.01]
```

Orange: the standard normal, right when the spread is known. Green: t with 9 degrees of freedom, right for ten bags whose spread is estimated. Dark blue: t with 2 degrees of freedom, three bags. Beyond 2 standard errors either way the green curve holds 0.0766 of the chance and the orange 0.0455: the fewer the bags, the heavier the tails.

---

## The formula

Notation first, in words. $Z$ is a standard normal, N(0, 1). Several of them, Z_1 to Z_k, are independent. The Greek letter chi is written χ and read "kai". $\chi^2_k$ is read "chi-square with k degrees of freedom", and $\nu$ (nu) is the usual letter for a count of degrees of freedom. Γ is the gamma integral of [Gamma and beta](../04-Continuous%20Distributions/07-gamma-and-beta-distributions.md), with Γ(1/2) = √π. The gamma law on that card has two settings: the shape, which sets the power of v in its density, and the rate, which sets how fast its exponential tail falls.

**Chi-square: a sum of squares.**

$$V = Z_1^2 + Z_2^2 + \dots + Z_k^2 \sim \chi^2_k, \qquad f_V(v) = \frac{v^{k/2-1}\,e^{-v/2}}{2^{k/2}\,\Gamma(k/2)} \ (v > 0), \qquad E[V] = k, \quad \mathrm{Var}(V) = 2k$$

**Read it aloud:** add k independent squared standard normals; the total follows the gamma law with shape k/2 and rate 1/2, averaging k.

**t: a normal over an estimated spread.** With $V \sim \chi^2_\nu$ independent of $Z$:

$$T = \frac{Z}{\sqrt{V/\nu}} \sim t_\nu, \qquad f_T(t) = \frac{\Gamma\big(\tfrac{\nu+1}{2}\big)}{\sqrt{\nu\pi}\;\Gamma\big(\tfrac{\nu}{2}\big)} \left(1 + \frac{t^2}{\nu}\right)^{-(\nu+1)/2}, \qquad \mathrm{Var}(T) = \frac{\nu}{\nu - 2} \ (\nu > 2)$$

**Read it aloud:** divide a standard normal by the square root of a chi-square's average per degree of freedom; the result is bell-shaped, but its tails fall off as a power of t, not as e to the minus t squared over 2.

**F: a ratio of two spreads.** With $U \sim \chi^2_{\nu_1}$ and $V \sim \chi^2_{\nu_2}$ independent, and $c = \nu_1/\nu_2$:

$$F = \frac{U/\nu_1}{V/\nu_2} \sim F(\nu_1, \nu_2), \qquad f_F(x) = \frac{\Gamma\big(\tfrac{\nu_1+\nu_2}{2}\big)\, c^{\nu_1/2}\, x^{\nu_1/2-1}}{\Gamma\big(\tfrac{\nu_1}{2}\big)\Gamma\big(\tfrac{\nu_2}{2}\big)\,(1 + c x)^{(\nu_1+\nu_2)/2}} \ (x > 0), \qquad E[F] = \frac{\nu_2}{\nu_2 - 2} \ (\nu_2 > 2)$$

**Read it aloud:** divide one chi-square per degree of freedom by another; the order matters, numerator first.

**What a normal sample gives.** Take $n$ independent measurements, X_1 to X_n, from N(μ, σ^2). Their average is $\bar X$. A residual is one measurement's gap from the average. Their sample variance, $S^2$, is the squared residuals added and divided by n − 1; $S$ is its square root. For two machines, a subscript 1 or 2 marks the sample: sizes $n_1$ and $n_2$, sample variances $S_1^2$ and $S_2^2$, and true standard deviations $\sigma_1$ and $\sigma_2$.

$$\frac{(n-1)\,S^2}{\sigma^2} \sim \chi^2_{n-1}, \qquad \frac{\bar X - \mu}{S/\sqrt{n}} \sim t_{n-1}, \qquad \frac{S_1^2/\sigma_1^2}{S_2^2/\sigma_2^2} \sim F(n_1 - 1,\, n_2 - 1)$$

**Read it aloud:** the scaled sample variance is chi-square with one degree of freedom fewer than the sample size; the gap between average and true mean, in estimated standard errors, is t with the same count; and two independent samples' variances, each divided by its true variance, give an F ratio.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $n$, $n_1$, $n_2$ | number of measurements; $n_1$ and $n_2$ for the two machines | 10 bags (7 from the second machine) | S wobbles less; t moves towards the normal |
| $X_i$, $\bar X$ | one bag's weight; the average of the sample | 507 g; 502 g | a larger gap to explain |
| $\mu$ | the machine's true average | 500 g if the label is right | — |
| $\sigma$, $\sigma_1$, $\sigma_2$ | the machine's true standard deviation; one per machine in the F ratio | unknown; 3 g put to the test | wider scatter of every statistic |
| $S$, $S_1$, $S_2$ | the sample standard deviation, with n − 1; one per machine | 3.162 g, so S^2 = 10; the second machine's S_2^2 = 4 | the t ratio shrinks |
| $Z$, $Z_i$ | independent standard normals | the bags' errors divided by σ | — |
| $k$, $\nu$ | degrees of freedom: independent squares in a chi-square | 9 = 10 − 1 | tails thin towards the normal |
| $V$, $U$ | chi-square variables | V = 9 S^2/3^2 = 10.000 | — |
| $T$ | the t ratio | 2.000 | stronger evidence against the label |
| $F$, $c$ | the F ratio, and the degrees-of-freedom ratio in its density | 10/4 = 2.500 on (9, 6); c = 1.5 | the first spread looks larger |
| $f_V$, $f_T$, $f_F$ | densities: chance per unit of the statistic | f_T peaks at 0.39 | — |
| $\Gamma$ | the gamma integral, each law's constant | Γ(1/2) = 1.772454 | — |
| $\Phi$, $\varphi$ | the standard normal's cumulative area, and its density | 2(1 − Φ(2)) = 0.0455; φ(0) = 0.40 | — |
| $W_i$, $B$, $a$, $b$, $\beta$, $u$, $\theta$, $s$ | proof-only letters: the rotated standard normals (Step 3); two gamma shapes $a$, $b$ and their total $u$ (Step 2); the beta share U/(U + V), with parameters $a = \nu_1/2$ and $\beta = \nu_2/2$ and value b (Step 5); the angle in the t-tail tip; the generating function's argument (Step 2) | a = 9/2 and β = 6/2 for F(9, 6) | — |

### The picture: the chi-square law of a sample's spread

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Chi-square densities"
    x-axis "Value of V, the sum of squares (no unit)" [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24]
    y-axis "Density (chance per unit of V)" 0 --> 0.25
    line [0.00, 0.21, 0.11, 0.05, 0.02, 0.01, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]
    line [0.00, 0.02, 0.07, 0.10, 0.10, 0.08, 0.06, 0.04, 0.02, 0.01, 0.01, 0.00, 0.00]
```

Orange: 3 degrees of freedom, four bags. Green: 9 degrees of freedom, the ten bags, averaging 9 with a long right tail. The bags' own value, 10.000, sits just right of the green hump.

### When it holds

- **Independent measurements.** Bags filled one after another by a drifting machine are not independent; the residuals then share a trend and S understates the spread.
- **A normal population.** The chi-square law of S^2 is fragile. With skewed bags of the same mean and spread, a one-sided 5 percent chi-square test of σ = 3 rejects 12.03 percent of the time in simulation (standard error 0.10). The t ratio recovers as the bags grow in number, because their average tends to normal, but at ten skewed bags a 5 percent two-sided t test on the label still rejects 9.98 percent of the time (standard error 0.09); the chi-square test does not recover as the bags grow in number.
- **The right count of degrees of freedom.** Estimating the mean from the same bags uses one up: n − 1, not n. Reading 9 degrees as 10 turns a chance of 0.3505 into 0.4405.
- **For F, two independent normal samples.** A ratio of two spreads from the same bags, or from paired bags, has no F law.
- **A positive spread and at least two bags.** With one bag, n − 1 = 0 and S is undefined; with σ = 0 there is nothing to divide by.

---

## Why it works

### Step 0: divide out what is unknown

Every bag's error is σ times a standard normal. A ratio with σ once on top and once underneath loses it, so its law can be worked out once, for all machines. The unknown numbers cancel; only counts remain.

### Step 1: one squared normal is gamma with shape 1/2

$Z^2$ is at most v exactly when Z lies between −√v and √v. Both signs land on the same square, so both halves count:

$$P(Z^2 \le v) = \Phi(\sqrt v) - \Phi(-\sqrt v) = 2\,\Phi(\sqrt v) - 1.$$

Here Φ is the standard normal's cumulative area ([Normal](../04-Continuous%20Distributions/04-normal-distribution.md)). Differentiating, by the chain rule of [Transforming a variable](../05-Transformations%20and%20Joint%20Laws/01-transforming-a-random-variable.md):

$$f_{Z^2}(v) = 2\,\varphi(\sqrt v)\cdot\frac{1}{2\sqrt v} = \frac{v^{-1/2}\,e^{-v/2}}{\sqrt{2\pi}}.$$

Here φ is the normal density. This is the gamma density with shape 1/2 and rate 1/2, since 2^(1/2)Γ(1/2) = √2 · √π = √(2π). One squared normal has mean 1 and variance 2: shape over rate, and shape over rate squared.

### Step 2: independent squares add their shapes

Two independent gamma variables at the same rate add to a gamma variable whose shape is the sum of the two shapes. The proof is in the gamma card's Step 4, at rate 1: the joint density of shapes a and b splits into a part in the total u and a part in the share, and the total's part, u^(a+b−1)e^(−u)/Γ(a + b), is the gamma density with shape a + b.

Nothing there needs whole-number shapes, and a change of units moves the rate without touching the shapes, so it covers squares of shape 1/2 at rate 1/2. Adding k squared normals, each of shape 1/2, gives shape k/2 at rate 1/2. That is the chi-square density in The formula. Averages and variances add: mean k, variance 2k. For 9 degrees of freedom: mean 9, variance 18.

A second road: the moment generating function of one square is (1 − 2s)^(−1/2) for s below 1/2, where s is the function's argument. Independent terms multiply their generating functions, giving (1 − 2s)^(−k/2), the gamma law's own ([Moment generating functions](../02-Random%20Variables/07-moment-generating-functions.md)).

### Step 3: a normal sample's spread is chi-square with n − 1

Write each bag as μ + σZ_i. Then the residual X_i − X̄ is σ(Z_i − Z̄): μ is gone, and dividing the squared residuals by σ^2 removes σ. What is left, the sum of (Z_i − Z̄)^2, is a sum of n squares. Only n − 1 of them are free, because residuals always add to zero: the last is fixed by the others. The proof below turns that count into a law.

<details>
<summary>Detailed proof: the rotation that splits off the mean</summary>

The joint density of $Z_1, \dots, Z_n$ is $(2\pi)^{-n/2} e^{-(z_1^2 + \dots + z_n^2)/2}$. It depends only on the point's distance from the origin. A rotation keeps distances and volumes, so rotated coordinates $W_1, \dots, W_n$ have the same density: independent standard normals again ([Multivariate normal](../05-Transformations%20and%20Joint%20Laws/06-multivariate-normal.md)).

Choose the rotation whose first new axis points along `(1, 1, ..., 1)/√n`. Then $W_1 = (Z_1 + \dots + Z_n)/\sqrt n = \sqrt n\,\bar Z$. Distances are kept, so
$$Z_1^2 + \dots + Z_n^2 = W_1^2 + W_2^2 + \dots + W_n^2.$$
Expanding the squares also gives $\sum Z_i^2 = \sum (Z_i - \bar Z)^2 + n\bar Z^2$, and $n\bar Z^2 = W_1^2$. Subtracting,
$$\frac{(n-1)S^2}{\sigma^2} = \sum_{i=1}^n (Z_i - \bar Z)^2 = W_2^2 + \dots + W_n^2.$$
That is n − 1 independent squared standard normals: $\chi^2_{n-1}$ by Step 2. It uses only $W_2, \dots, W_n$, while the average uses only W_1. So for a normal sample the average and the sample variance are **independent**, the fact Step 4 needs. Non-normal samples lose it: the rotation argument used the density's dependence on distance alone.

</details>

For the ten bags, test the claim σ = 3. The statistic is V = 9 × 10 / 9 = 10.000, on 9 degrees of freedom. A value above 10 occurs with chance 0.3505, about 1 time in 3: the bags' spread is ordinary for σ = 3.

The middle 95 percent of the chi-square law with 9 degrees runs from 2.700 to 19.023. Since σ^2/9 = 1 here, S^2 itself lands between 2.700 and 19.023 in 95 of 100 samples of ten bags. A sample variance of ten bags is a rough instrument.

### Step 4: t is a normal over an independent estimated spread

The standardised gap with σ known is Z = (X̄ − μ)/(σ/√n), a standard normal. Replace σ by S and divide top and bottom by σ:

$$\frac{\bar X - \mu}{S/\sqrt n} = \frac{(\bar X - \mu)/(\sigma/\sqrt n)}{\sqrt{S^2/\sigma^2}} = \frac{Z}{\sqrt{V/(n-1)}}, \qquad V = \frac{(n-1)S^2}{\sigma^2}.$$

σ cancels. The top is a standard normal. The bottom is the square root of a chi-square per degree of freedom, and Step 3 made it independent of the top. That is the t construction with ν = n − 1.

Why the tails are heavier: V/ν averages 1, but in some samples it is small, and a small denominator throws the ratio far out. V/ν has variance 2/ν, so as ν grows it settles at 1 ([Law of large numbers](../06-Limit%20Theorems%20in%20Practice/01-law-of-large-numbers.md)) and t becomes the normal. At ν = 1 the denominator is |Z'| for a second normal Z', and t is the Cauchy law of [Heavy tails](../04-Continuous%20Distributions/08-heavy-tails-pareto-and-cauchy.md): a gap beyond 2 has chance 0.2952 there.

The variance: E[T^2] = ν · E[Z^2] · E[1/V], and the gamma integral gives E[1/V] = 1/(ν − 2). For ten bags, 9/7 = 1.2857. Below three degrees of freedom the variance is infinite.

<details>
<summary>Detailed proof: the t density</summary>

Hold V at a value v. Then T = Z / √(v/ν) is normal with standard deviation √(ν/v), density $\sqrt{v/\nu}\,\varphi(t\sqrt{v/\nu})$. Average over v with the chi-square density:
$$f_T(t) = \int_0^\infty \sqrt{\tfrac{v}{\nu}}\,\frac{e^{-t^2 v/(2\nu)}}{\sqrt{2\pi}} \cdot \frac{v^{\nu/2-1} e^{-v/2}}{2^{\nu/2}\Gamma(\nu/2)}\,dv = \frac{1}{\sqrt{2\pi\nu}\;2^{\nu/2}\,\Gamma(\nu/2)} \int_0^\infty v^{\frac{\nu+1}{2}-1} e^{-v\,(1 + t^2/\nu)/2}\,dv.$$
The gamma integral $\int_0^\infty v^{a-1}e^{-bv}\,dv = \Gamma(a)/b^a$ with $a = (\nu+1)/2$ and $b = (1 + t^2/\nu)/2$ gives $\Gamma(\frac{\nu+1}{2})\,2^{(\nu+1)/2}(1 + t^2/\nu)^{-(\nu+1)/2}$. The powers of 2 reduce to $\sqrt2$, and $\sqrt2/\sqrt{2\pi\nu} = 1/\sqrt{\nu\pi}$, which is the density in The formula. Averaging a density over v uses independence: the law of Z is the same whatever V turned out to be.

</details>

<details>
<summary>Why the code can write the t tail as a finite sum</summary>

Put $t = \sqrt\nu\,\tan\theta$. Then $1 + t^2/\nu = 1/\cos^2\theta$ and the density times dt becomes a constant times $\cos^{\nu-1}\theta\,d\theta$. At ν = 1 that is flat in θ, so $P(|T| < t) = 2\theta/\pi$, the Cauchy law. For odd ν the power of cosine is even, and repeated integration by parts gives θ plus sin θ times a finite sum of odd powers of cos θ, with weights 1, 2/3, 8/15 and so on. The check uses that sum for ν = 9.

</details>

### Step 5: F is a ratio, and a beta variable in disguise

Weigh seven bags from a second machine, 503, 498, 501, 498, 502, 499 and 499 grams: average 500, sample variance 4 grams squared. If both machines share one σ, the ratio of the two sample variances is

$$\frac{S_1^2}{S_2^2} = \frac{\big(9 S_1^2/\sigma^2\big)/9}{\big(6 S_2^2/\sigma^2\big)/6} = \frac{U/9}{V/6},$$

with U and V independent chi-squares on 9 and 6 degrees: the F construction, F(9, 6). The σ cancels again. Here the ratio is 10/4 = 2.500, and a ratio at least that large turns up with chance 0.1385 when the spreads are equal: about 1 time in 7.

The share U/(U + V) of two independent gamma variables at one rate follows the beta law with parameters ν1/2 and ν2/2: the gamma card's Step 4. Since cF = U/V, that share equals cF/(1 + cF). So every F tail is a beta tail, which is how the check computes 0.1385.

<details>
<summary>Detailed proof: the F density from the beta share</summary>

Let B = U/(U + V), with density $b^{a-1}(1-b)^{\beta-1}\Gamma(a+\beta)/(\Gamma(a)\Gamma(\beta))$, where a = ν1/2 and β = ν2/2. Then cF = B/(1 − B), so B = cx/(1 + cx) when F = x, and 1 − B = 1/(1 + cx). The stretch factor is dB/dx = c/(1 + cx)^2. Multiplying,
$$f_F(x) = \frac{\Gamma(a+\beta)}{\Gamma(a)\Gamma(\beta)} \cdot \frac{(cx)^{a-1}}{(1+cx)^{a-1}} \cdot \frac{1}{(1+cx)^{\beta-1}} \cdot \frac{c}{(1+cx)^2} = \frac{\Gamma(a+\beta)\,c^{a}\,x^{a-1}}{\Gamma(a)\Gamma(\beta)\,(1+cx)^{a+\beta}}.$$
The mean: E[F] = (ν2/ν1) E[U] E[1/V] = (ν2/ν1) · ν1 · 1/(ν2 − 2) = ν2/(ν2 − 2), which is 6/4 = 1.5000 for (9, 6). Swapping the two samples gives 1/F, which is F(ν2, ν1).

</details>

Two links close the family. A squared standard normal is chi-square with 1 degree, so T^2 = Z^2/(V/ν) is F(1, ν): a two-sided t question is a one-sided F question. And ν1 F(ν1, ν2) becomes chi-square on ν1 as ν2 grows, since the denominator settles at 1.

The same laws can be reached with no density at all: draw normal samples, compute the statistics, and count, as the check does. [Bootstrap](08-bootstrap.md) runs that idea on the data themselves when no normal model is trusted.

---

## Worked numbers, by hand

**Is the label right?** Ten bags, spread unknown.

| Step | Arithmetic | Value |
| --- | --- | --- |
| average | the ten weights added, over 10 | 502 g |
| residuals from 502 | 5, −4, 3, −2, 1, 0, −1, −5, 3, 0 | they add to 0 |
| squared residuals | 25 + 16 + 9 + 4 + 1 + 0 + 1 + 25 + 9 + 0 | 90 |
| sample variance | 90 / (10 − 1) | S^2 = 10.000 |
| sample standard deviation | √10 | 3.162 g |
| estimated standard error | 3.162 / √10 | 1.000 g |
| t ratio | (502 − 500) / 1.000 | **2.000** on 9 degrees |
| 5 percent two-sided cutoff | t with 9 degrees | 2.262 (normal: 1.960) |
| chance of a gap this large | t tail, both sides | **0.0766** |

If the label were right, ten bags would sit 2 or more standard errors from 500 about 1 time in 13. That is not rare enough to condemn the machine at the 5 percent level, since 2.000 falls short of 2.262. The 0.0766 is a p-value: the chance of a gap this large if the label is right. It is not the chance that the label is right.

**Is the spread σ = 3?** V = 9 × 10 / 9 = **10.000** on 9 degrees; chance of a value above 10: **0.3505**.

**Do two machines differ in spread?** The seven bags sit 3, −2, 1, −2, 2, −1 and −1 grams from their average of 500; the squares add to 9 + 4 + 1 + 4 + 4 + 1 + 1 = 24, so S^2 = 24 / 6 = 4.000. F = 10 / 4 = **2.500** on (9, 6); chance of 2.5 or more with equal spreads: **0.1385**, and the 5 percent cutoff is 4.099.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Normal cutoff 1.96 with an estimated spread | a correct label rejected 8.16 percent of the time, not 5 | S was treated as σ; its wobble fattens the tails |
| 10 degrees of freedom for the chi-square | P(V > 10) = 0.4405, not 0.3505 | fitting the average uses one degree up |
| F read on (6, 9) for (9, 6) | P(F > 2.5) = 0.1047, not 0.1385 | numerator degrees come first |
| Skewed bags, same mean and spread | a 5 percent chi-square test on σ = 3 rejects 12.03 percent | the chi-square law of S^2 needs normal data |

The first and last rows are hypotheses dropped; the code prints all four, the first and last also by simulation.

---

## Code, from first principles, and it actually runs

Nothing imported contains the answer: no statistics module, no random module, no gamma function. Three roads reach each tail chance. The closed forms use a series for the normal curve, finite sums for chi-square and odd-degree t, and the beta sum for F. Simpson's rule integrates the densities. A simulation weighs 100,000 rounds of ten bags plus seven from normal machines, drawing from a SplitMix64 generator (a small, written-out source of random bits, seed 20260928) through the Box-Muller recipe, which turns two uniform draws into two independent normals. It computes S^2, the t ratio and the variance ratio from the weights, never from a formula for their laws. Estimates carry standard errors; the asserts compare different roads.

### Python

```python
# The reference distributions -- the check behind the card.  Nothing imported holds the answer.
# Ten bags from a filling machine labelled 500 g, spread unknown; seven bags from a second machine.
# Roads: closed forms (a normal series, finite sums for chi-square, t and F); Simpson's rule on the
# densities; a seeded simulation that weighs whole samples and never uses a chi-square, t or F formula.
from math import exp, log, sqrt, pi, atan, sin, cos

A = [507, 498, 505, 500, 503, 502, 501, 497, 505, 502]   # machine one, grams
B = [503, 498, 501, 498, 502, 499, 499]                  # machine two, grams
LABEL, SIGMA = 500.0, 3.0                                # the label; a spread to test against

def summary(xs):                             # size, mean, sample variance with n - 1
    m = sum(xs) / len(xs)
    return len(xs), m, sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
def phi(x):                                  # the standard normal density
    return exp(-x * x / 2) / sqrt(2 * pi)
def Phi(x):                                  # 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    term = s = x
    for j in range(1, 200):
        term *= x * x / (2 * j + 1)
        s += term
    return 0.5 + phi(x) * s
def gam(h2):                                 # Gamma(h2 / 2), for a whole number h2 >= 1
    g, h = (sqrt(pi), 0.5) if h2 % 2 else (1.0, 1.0)
    while h < h2 / 2:
        g, h = g * h, h + 1
    return g
def chi_d(x, k):                             # chi-square density: Gamma(k/2, rate 1/2)
    return x ** (k / 2 - 1) * exp(-x / 2) / (2 ** (k / 2) * gam(k))
def t_d(t, v):
    return gam(v + 1) / (sqrt(v * pi) * gam(v)) * (1 + t * t / v) ** (-(v + 1) / 2)
def f_d(x, v1, v2):                          # F density, with c = v1 / v2
    return gam(v1 + v2) / (gam(v1) * gam(v2)) * (v1 / v2) ** (v1 / 2) * x ** (v1 / 2 - 1) * (1 + v1 * x / v2) ** (-(v1 + v2) / 2)
def chi_tail(x, k):                          # P(V > x): Poisson sum (even k), normal road (odd k)
    if k % 2 == 0:
        term = s = 1.0
        for j in range(1, k // 2):
            term *= x / 2 / j
            s += term
        return exp(-x / 2) * s
    term, s = sqrt(x), 0.0
    for r in range(1, (k - 1) // 2 + 1):
        s += term
        term *= x / (2 * r + 1)
    return 2 * (1 - Phi(sqrt(x))) + 2 * phi(sqrt(x)) * s
def t_tail2(t, v):                           # P(|T| > t), odd v, through the angle atan(t / sqrt v)
    th = atan(t / sqrt(v))
    c, w, s = cos(th), 1.0, 0.0
    for j in range((v - 1) // 2):
        s += w * c ** (2 * j + 1)
        w *= (2 * j + 2) / (2 * j + 3)
    return 1 - 2 / pi * (th + sin(th) * s)
def beta_cdf(y, a, b):                       # needs a whole number a or b
    if b != int(b):
        return 1 - beta_cdf(1 - y, b, a)
    term = s = 1.0
    for j in range(1, int(b)):
        term *= (a + j - 1) / j * (1 - y)
        s += term
    return y ** a * s
def f_tail(x, v1, v2):                       # P(F > x), through the beta variable cF / (1 + cF)
    return 1 - beta_cdf(v1 * x / (v2 + v1 * x), v1 / 2, v2 / 2)
def simpson(g, lo, hi, n=4000):
    h = (hi - lo) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(lo + i * h) for i in range(n + 1))
def bisect(g, target, lo, hi):               # g decreasing
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if g(mid) > target else (lo, mid)
    return (lo + hi) / 2
MASK, state = (1 << 64) - 1, 20260928        # SplitMix64, seed 20260928
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def normals(k):                              # Box-Muller, two at a time
    out = []
    while len(out) < k:
        r, a = sqrt(-2 * log(uniform())), 2 * pi * uniform()
        out += [r * cos(a), r * sin(a)]
    return out[:k]

n, m, s2 = summary(A)
nb, mb, s2b = summary(B)
se = sqrt(s2 / n)
t_obs, q_obs, f_obs = (m - LABEL) / se, (n - 1) * s2 / SIGMA ** 2, s2 / s2b
print(f"machine one: n {n}, mean {m:.3f}, squared residuals {s2 * (n - 1):.1f}, S^2 {s2:.3f}, S {sqrt(s2):.3f}, S/sqrt(n) {se:.3f}")
print(f"machine two: n {nb}, mean {mb:.3f}, squared residuals {s2b * (nb - 1):.1f}, S^2 {s2b:.3f}")
print(f"observed: t {t_obs:.3f} on 9; V = 9 S^2/3^2 {q_obs:.3f} on 9; F = S1^2/S2^2 {f_obs:.3f} on (9, 6)")
p_t, p_q, p_f = t_tail2(t_obs, 9), chi_tail(q_obs, 9), f_tail(f_obs, 9, 6)
s_t = 1 - 2 * simpson(lambda x: t_d(x, 9), 0.0, t_obs)
s_q = 1 - simpson(lambda x: chi_d(x, 9), 0.0, q_obs)
s_f = 1 - simpson(lambda x: f_d(x, 9, 6), 0.0, f_obs)
print(f"P(|T| > 2) on 9: closed form {p_t:.4f}; Simpson {s_t:.4f}; normal instead {2 * (1 - Phi(2.0)):.4f}")
print(f"P(V > 10) on 9: closed form {p_q:.4f}; Simpson {s_q:.4f}. P(F > 2.5) on (9, 6): beta sum {p_f:.4f}; Simpson {s_f:.4f}")
print(f"Gamma(1/2) {gam(1):.6f}; Gamma(9/2) {gam(9):.6f}; area under t on 9 {2 * simpson(lambda x: t_d(x, 9), 0.0, 60.0):.6f}")
q_t = bisect(lambda x: t_tail2(x, 9), 0.05, 0.0, 20.0)
q_lo, q_hi = bisect(lambda x: chi_tail(x, 9), 0.975, 0.0, 60.0), bisect(lambda x: chi_tail(x, 9), 0.025, 0.0, 60.0)
q_95, f_95 = bisect(lambda x: chi_tail(x, 9), 0.05, 0.0, 60.0), bisect(lambda x: f_tail(x, 9, 6), 0.05, 0.0, 60.0)
print(f"cutoffs: t on 9, 2.5% each side {q_t:.3f}; normal {bisect(lambda x: 2 * (1 - Phi(x)), 0.05, 0.0, 10.0):.3f}")
print(f"cutoffs: chi-square 9, middle 95% {q_lo:.3f} to {q_hi:.3f}, top 5% {q_95:.3f}; F (9, 6) top 5% {f_95:.3f}")
print(f"P(|T| > 1.96): t on 9 {t_tail2(1.96, 9):.4f}; t on 1 (Cauchy) P(|T| > 2) {t_tail2(2.0, 1):.4f}")
N = 100_000
c_t = c_z = c_q = c_f = c_sk = c_st = 0
sq = sq2 = st2 = st4 = sf = sf2 = 0.0
for _ in range(N):
    _, ma, va = summary([LABEL + SIGMA * z for z in normals(10)])
    _, _, vb = summary([LABEL + SIGMA * z for z in normals(7)])
    _, me, ve = summary([LABEL - SIGMA - SIGMA * log(uniform()) for _ in range(10)])
    t, q, f = (ma - LABEL) / sqrt(va / 10), 9 * va / SIGMA ** 2, va / vb
    c_t, c_z, c_q, c_f = c_t + (abs(t) > 2), c_z + (abs(t) > 1.96), c_q + (q > 10), c_f + (f > 2.5)
    c_sk, c_st = c_sk + (9 * ve / SIGMA ** 2 > q_95), c_st + (abs((me - LABEL) / sqrt(ve / 10)) > q_t)
    sq, sq2, st2, st4, sf, sf2 = sq + q, sq2 + q * q, st2 + t * t, st4 + t ** 4, sf + f, sf2 + f * f
est = lambda c: (c / N, sqrt(c / N * (1 - c / N) / N))   # a share and its standard error
(r_t, e_t), (r_z, e_z), (r_q, e_q), (r_f, e_f), (r_sk, e_sk), (r_st, e_st) = map(est, (c_t, c_z, c_q, c_f, c_sk, c_st))
mq, vq = sq / N, sq2 / N - (sq / N) ** 2
mt2, et2, mf, ef = st2 / N, sqrt((st4 / N - (st2 / N) ** 2) / N), sf / N, sqrt((sf2 / N - (sf / N) ** 2) / N)
print(f"simulated {N} rounds of 10 + 7 bags, true mean 500, sigma 3, seed 20260928; estimate (standard error)")
print(f"  P(|T| > 2) {r_t:.4f} ({e_t:.4f}); P(V > 10) {r_q:.4f} ({e_q:.4f}); P(F > 2.5) {r_f:.4f} ({e_f:.4f})")
print(f"  V: mean {mq:.3f} ({sqrt(vq / N):.3f}), variance {vq:.3f}; T: mean square {mt2:.4f} ({et2:.4f}), formula 9/7 = {9 / 7:.4f}; F: mean {mf:.4f} ({ef:.4f}), formula 6/4 = {6 / 4:.4f}")
print(f"mistake, cutoff 1.96 with an estimated spread: true label rejected {r_z:.4f} ({e_z:.4f}), closed form {t_tail2(1.96, 9):.4f}")
print(f"mistake, 10 degrees of freedom for 9: P(V > 10) {chi_tail(10.0, 10):.4f}, not {p_q:.4f}")
print(f"mistake, F read on (6, 9) for (9, 6): P(F > 2.5) {f_tail(2.5, 6, 9):.4f}, not {p_f:.4f}")
print(f"mistake, skewed bags (exponential, same mean and sd): 5% chi-square test rejects {r_sk:.4f} ({e_sk:.4f}); 5% t test {r_st:.4f} ({e_st:.4f})")
xs = [0.5 * i for i in range(-8, 9)]
print("figure, t: " + ", ".join(f"{x:.1f}" for x in xs))
print("figure, normal: " + ", ".join(f"{phi(x):.2f}" for x in xs))
print("figure, t on 9: " + ", ".join(f"{t_d(x, 9):.2f}" for x in xs))
print("figure, t on 2: " + ", ".join(f"{t_d(x, 2):.2f}" for x in xs))
vs = [2.0 * i for i in range(13)]
print("figure, v: " + ", ".join(f"{v:.0f}" for v in vs))
for k in (3, 9):
    print(f"figure, chi-square {k}: " + ", ".join(f"{chi_d(v, k):.2f}" for v in vs))
assert abs(p_t - s_t) < 1e-9 and abs(p_q - s_q) < 1e-9 and abs(p_f - s_f) < 1e-9   # closed forms against Simpson
assert abs(chi_tail(10.0, 10) - (1 - simpson(lambda x: chi_d(x, 10), 0.0, 10.0))) < 1e-9 and abs(f_tail(2.5, 6, 9) - (1 - simpson(lambda x: f_d(x, 6, 9), 0.0, 2.5))) < 1e-9
assert abs(r_t - p_t) < 4 * e_t and abs(r_q - p_q) < 4 * e_q and abs(r_f - p_f) < 4 * e_f
assert abs(mq - 9) < 4 * sqrt(vq / N) and abs(vq - 18) < 0.42   # nine squares: mean 9, variance 18 (SE 0.104)
assert abs(r_z - t_tail2(1.96, 9)) < 4 * e_z and abs(mt2 - 9 / 7) < 4 * et2 and abs(mf - 1.5) < 4 * ef and r_sk - 0.05 > 4 * e_sk and r_st - 0.05 > 4 * e_st
print("ALL CHECKS PASS")
```

**Ran 2026-10-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
machine one: n 10, mean 502.000, squared residuals 90.0, S^2 10.000, S 3.162, S/sqrt(n) 1.000
machine two: n 7, mean 500.000, squared residuals 24.0, S^2 4.000
observed: t 2.000 on 9; V = 9 S^2/3^2 10.000 on 9; F = S1^2/S2^2 2.500 on (9, 6)
P(|T| > 2) on 9: closed form 0.0766; Simpson 0.0766; normal instead 0.0455
P(V > 10) on 9: closed form 0.3505; Simpson 0.3505. P(F > 2.5) on (9, 6): beta sum 0.1385; Simpson 0.1385
Gamma(1/2) 1.772454; Gamma(9/2) 11.631728; area under t on 9 1.000000
cutoffs: t on 9, 2.5% each side 2.262; normal 1.960
cutoffs: chi-square 9, middle 95% 2.700 to 19.023, top 5% 16.919; F (9, 6) top 5% 4.099
P(|T| > 1.96): t on 9 0.0816; t on 1 (Cauchy) P(|T| > 2) 0.2952
simulated 100000 rounds of 10 + 7 bags, true mean 500, sigma 3, seed 20260928; estimate (standard error)
  P(|T| > 2) 0.0770 (0.0008); P(V > 10) 0.3513 (0.0015); P(F > 2.5) 0.1385 (0.0011)
  V: mean 9.013 (0.013), variance 18.098; T: mean square 1.2956 (0.0075), formula 9/7 = 1.2857; F: mean 1.5024 (0.0057), formula 6/4 = 1.5000
mistake, cutoff 1.96 with an estimated spread: true label rejected 0.0823 (0.0009), closed form 0.0816
mistake, 10 degrees of freedom for 9: P(V > 10) 0.4405, not 0.3505
mistake, F read on (6, 9) for (9, 6): P(F > 2.5) 0.1047, not 0.1385
mistake, skewed bags (exponential, same mean and sd): 5% chi-square test rejects 0.1203 (0.0010); 5% t test 0.0998 (0.0009)
figure, t: -4.0, -3.5, -3.0, -2.5, -2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0
figure, normal: 0.00, 0.00, 0.00, 0.02, 0.05, 0.13, 0.24, 0.35, 0.40, 0.35, 0.24, 0.13, 0.05, 0.02, 0.00, 0.00, 0.00
figure, t on 9: 0.00, 0.01, 0.01, 0.03, 0.06, 0.13, 0.23, 0.34, 0.39, 0.34, 0.23, 0.13, 0.06, 0.03, 0.01, 0.01, 0.00
figure, t on 2: 0.01, 0.02, 0.03, 0.04, 0.07, 0.11, 0.19, 0.30, 0.35, 0.30, 0.19, 0.11, 0.07, 0.04, 0.03, 0.02, 0.01
figure, v: 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24
figure, chi-square 3: 0.00, 0.21, 0.11, 0.05, 0.02, 0.01, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00
figure, chi-square 9: 0.00, 0.02, 0.07, 0.10, 0.10, 0.08, 0.06, 0.04, 0.02, 0.01, 0.01, 0.00, 0.00
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// The reference distributions -- the same check as the Python, in Rust.  No crates.
// Ten bags from a filling machine labelled 500 g, spread unknown; seven bags from a second machine.
// Roads: closed forms (a normal series, finite sums for chi-square, t and F); Simpson's rule on the
// densities; a seeded simulation that weighs whole samples and never uses a chi-square, t or F formula.
use std::f64::consts::PI;

const LABEL: f64 = 500.0;
const SIGMA: f64 = 3.0;

fn summary(xs: &[f64]) -> (usize, f64, f64) {      // size, mean, sample variance with n - 1
    let n = xs.len();
    let m = xs.iter().sum::<f64>() / n as f64;
    (n, m, xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (n - 1) as f64)
}
fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() }
fn big_phi(x: f64) -> f64 {                        // 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    let (mut term, mut s) = (x, x);
    for j in 1..200 { term *= x * x / (2 * j + 1) as f64; s += term; }
    0.5 + phi(x) * s
}
fn gam(h2: u32) -> f64 {                           // Gamma(h2 / 2), for a whole number h2 >= 1
    let (mut g, mut h) = if h2 % 2 == 1 { (PI.sqrt(), 0.5) } else { (1.0, 1.0) };
    while h < h2 as f64 / 2.0 { g *= h; h += 1.0; }
    g
}
fn chi_d(x: f64, k: u32) -> f64 {                  // chi-square density: Gamma(k/2, rate 1/2)
    let kf = k as f64;
    x.powf(kf / 2.0 - 1.0) * (-x / 2.0).exp() / (2f64.powf(kf / 2.0) * gam(k))
}
fn t_d(t: f64, v: u32) -> f64 {
    let vf = v as f64;
    gam(v + 1) / ((vf * PI).sqrt() * gam(v)) * (1.0 + t * t / vf).powf(-(vf + 1.0) / 2.0)
}
fn f_d(x: f64, v1: u32, v2: u32) -> f64 {          // F density, with c = v1 / v2
    let (a, b) = (v1 as f64, v2 as f64);
    gam(v1 + v2) / (gam(v1) * gam(v2)) * (a / b).powf(a / 2.0) * x.powf(a / 2.0 - 1.0)
        * (1.0 + a * x / b).powf(-(a + b) / 2.0)
}
fn chi_tail(x: f64, k: u32) -> f64 {               // P(V > x): Poisson sum (even k), normal road (odd k)
    if k % 2 == 0 {
        let (mut term, mut s) = (1.0, 1.0);
        for j in 1..k / 2 { term *= x / 2.0 / j as f64; s += term; }
        return (-x / 2.0).exp() * s;
    }
    let (mut term, mut s) = (x.sqrt(), 0.0);
    for r in 1..=(k - 1) / 2 { s += term; term *= x / (2 * r + 1) as f64; }
    2.0 * (1.0 - big_phi(x.sqrt())) + 2.0 * phi(x.sqrt()) * s
}
fn t_tail2(t: f64, v: u32) -> f64 {                // P(|T| > t), odd v, through the angle atan(t / sqrt v)
    let th = (t / (v as f64).sqrt()).atan();
    let (c, mut w, mut s) = (th.cos(), 1.0, 0.0);
    for j in 0..(v - 1) / 2 { s += w * c.powi(2 * j as i32 + 1); w *= (2 * j + 2) as f64 / (2 * j + 3) as f64; }
    1.0 - 2.0 / PI * (th + th.sin() * s)
}
fn beta_cdf(y: f64, a: f64, b: f64) -> f64 {       // needs a whole number a or b
    if b != b.trunc() { return 1.0 - beta_cdf(1.0 - y, b, a); }
    let (mut term, mut s) = (1.0, 1.0);
    for j in 1..b as u32 { term *= (a + j as f64 - 1.0) / j as f64 * (1.0 - y); s += term; }
    y.powf(a) * s
}
fn f_tail(x: f64, v1: u32, v2: u32) -> f64 {       // P(F > x), through the beta variable cF / (1 + cF)
    let (a, b) = (v1 as f64, v2 as f64);
    1.0 - beta_cdf(a * x / (b + a * x), a / 2.0, b / 2.0)
}
fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {
    let (n, h) = (4000, (hi - lo) / 4000.0);
    h / 3.0 * (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * g(lo + i as f64 * h)).sum::<f64>()
}
fn bisect(g: &dyn Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 {   // g decreasing
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if g(mid) > target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
struct Rng(u64);                                   // SplitMix64, seed 20260928
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normals(&mut self, k: usize) -> Vec<f64> {  // Box-Muller, two at a time
        let mut out = Vec::new();
        while out.len() < k {
            let r = (-2.0 * self.uniform().ln()).sqrt();
            let a = 2.0 * PI * self.uniform();
            out.push(r * a.cos());
            out.push(r * a.sin());
        }
        out.truncate(k);
        out
    }
}
fn join(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let a: Vec<f64> = [507, 498, 505, 500, 503, 502, 501, 497, 505, 502].iter().map(|&x| x as f64).collect();
    let b: Vec<f64> = [503, 498, 501, 498, 502, 499, 499].iter().map(|&x| x as f64).collect();
    let ((n, m, s2), (nb, mb, s2b)) = (summary(&a), summary(&b));
    let se = (s2 / n as f64).sqrt();
    let (t_obs, q_obs, f_obs) = ((m - LABEL) / se, (n - 1) as f64 * s2 / SIGMA.powi(2), s2 / s2b);
    println!("machine one: n {}, mean {:.3}, squared residuals {:.1}, S^2 {:.3}, S {:.3}, S/sqrt(n) {:.3}", n, m, s2 * (n - 1) as f64, s2, s2.sqrt(), se);
    println!("machine two: n {}, mean {:.3}, squared residuals {:.1}, S^2 {:.3}", nb, mb, s2b * (nb - 1) as f64, s2b);
    println!("observed: t {:.3} on 9; V = 9 S^2/3^2 {:.3} on 9; F = S1^2/S2^2 {:.3} on (9, 6)", t_obs, q_obs, f_obs);
    let (p_t, p_q, p_f) = (t_tail2(t_obs, 9), chi_tail(q_obs, 9), f_tail(f_obs, 9, 6));
    let s_t = 1.0 - 2.0 * simpson(&|x| t_d(x, 9), 0.0, t_obs);
    let s_q = 1.0 - simpson(&|x| chi_d(x, 9), 0.0, q_obs);
    let s_f = 1.0 - simpson(&|x| f_d(x, 9, 6), 0.0, f_obs);
    println!("P(|T| > 2) on 9: closed form {:.4}; Simpson {:.4}; normal instead {:.4}", p_t, s_t, 2.0 * (1.0 - big_phi(2.0)));
    println!("P(V > 10) on 9: closed form {:.4}; Simpson {:.4}. P(F > 2.5) on (9, 6): beta sum {:.4}; Simpson {:.4}", p_q, s_q, p_f, s_f);
    println!("Gamma(1/2) {:.6}; Gamma(9/2) {:.6}; area under t on 9 {:.6}", gam(1), gam(9), 2.0 * simpson(&|x| t_d(x, 9), 0.0, 60.0));
    let q_t = bisect(&|x| t_tail2(x, 9), 0.05, 0.0, 20.0);
    let (q_lo, q_hi) = (bisect(&|x| chi_tail(x, 9), 0.975, 0.0, 60.0), bisect(&|x| chi_tail(x, 9), 0.025, 0.0, 60.0));
    let (q_95, f_95) = (bisect(&|x| chi_tail(x, 9), 0.05, 0.0, 60.0), bisect(&|x| f_tail(x, 9, 6), 0.05, 0.0, 60.0));
    println!("cutoffs: t on 9, 2.5% each side {:.3}; normal {:.3}", q_t, bisect(&|x| 2.0 * (1.0 - big_phi(x)), 0.05, 0.0, 10.0));
    println!("cutoffs: chi-square 9, middle 95% {:.3} to {:.3}, top 5% {:.3}; F (9, 6) top 5% {:.3}", q_lo, q_hi, q_95, f_95);
    println!("P(|T| > 1.96): t on 9 {:.4}; t on 1 (Cauchy) P(|T| > 2) {:.4}", t_tail2(1.96, 9), t_tail2(2.0, 1));
    let big_n = 100_000;
    let mut rng = Rng(20260928);
    let (mut c_t, mut c_z, mut c_q, mut c_f, mut c_sk, mut c_st) = (0, 0, 0, 0, 0, 0);
    let (mut sq, mut sq2, mut st2, mut st4, mut sf, mut sf2) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    for _ in 0..big_n {
        let (_, ma, va) = summary(&rng.normals(10).iter().map(|z| LABEL + SIGMA * z).collect::<Vec<_>>());
        let (_, _, vb) = summary(&rng.normals(7).iter().map(|z| LABEL + SIGMA * z).collect::<Vec<_>>());
        let (_, me, ve) = summary(&(0..10).map(|_| LABEL - SIGMA - SIGMA * rng.uniform().ln()).collect::<Vec<_>>());
        let (t, q, f) = ((ma - LABEL) / (va / 10.0).sqrt(), 9.0 * va / SIGMA.powi(2), va / vb);
        c_t += (t.abs() > 2.0) as u32; c_z += (t.abs() > 1.96) as u32; c_q += (q > 10.0) as u32; c_f += (f > 2.5) as u32;
        c_sk += (9.0 * ve / SIGMA.powi(2) > q_95) as u32; c_st += (((me - LABEL) / (ve / 10.0).sqrt()).abs() > q_t) as u32;
        sq += q; sq2 += q * q; st2 += t * t; st4 += t.powi(4); sf += f; sf2 += f * f;
    }
    let nf = big_n as f64;
    let est = |c: u32| (c as f64 / nf, (c as f64 / nf * (1.0 - c as f64 / nf) / nf).sqrt());   // a share and its standard error
    let ((r_t, e_t), (r_z, e_z), (r_q, e_q), (r_f, e_f), (r_sk, e_sk), (r_st, e_st)) = (est(c_t), est(c_z), est(c_q), est(c_f), est(c_sk), est(c_st));
    let (mq, vq) = (sq / nf, sq2 / nf - (sq / nf).powi(2));
    let (mt2, et2, mf, ef) = (st2 / nf, ((st4 / nf - (st2 / nf).powi(2)) / nf).sqrt(), sf / nf, ((sf2 / nf - (sf / nf).powi(2)) / nf).sqrt());
    println!("simulated {} rounds of 10 + 7 bags, true mean 500, sigma 3, seed 20260928; estimate (standard error)", big_n);
    println!("  P(|T| > 2) {:.4} ({:.4}); P(V > 10) {:.4} ({:.4}); P(F > 2.5) {:.4} ({:.4})", r_t, e_t, r_q, e_q, r_f, e_f);
    println!("  V: mean {:.3} ({:.3}), variance {:.3}; T: mean square {:.4} ({:.4}), formula 9/7 = {:.4}; F: mean {:.4} ({:.4}), formula 6/4 = {:.4}",
             mq, (vq / nf).sqrt(), vq, mt2, et2, 9.0 / 7.0, mf, ef, 6.0 / 4.0);
    println!("mistake, cutoff 1.96 with an estimated spread: true label rejected {:.4} ({:.4}), closed form {:.4}", r_z, e_z, t_tail2(1.96, 9));
    println!("mistake, 10 degrees of freedom for 9: P(V > 10) {:.4}, not {:.4}", chi_tail(10.0, 10), p_q);
    println!("mistake, F read on (6, 9) for (9, 6): P(F > 2.5) {:.4}, not {:.4}", f_tail(2.5, 6, 9), p_f);
    println!("mistake, skewed bags (exponential, same mean and sd): 5% chi-square test rejects {:.4} ({:.4}); 5% t test {:.4} ({:.4})", r_sk, e_sk, r_st, e_st);
    let xs: Vec<f64> = (-8..=8).map(|i| 0.5 * i as f64).collect();
    println!("figure, t: {}", join(&xs, 1));
    println!("figure, normal: {}", join(&xs.iter().map(|&x| phi(x)).collect::<Vec<_>>(), 2));
    println!("figure, t on 9: {}", join(&xs.iter().map(|&x| t_d(x, 9)).collect::<Vec<_>>(), 2));
    println!("figure, t on 2: {}", join(&xs.iter().map(|&x| t_d(x, 2)).collect::<Vec<_>>(), 2));
    let vs: Vec<f64> = (0..13).map(|i| 2.0 * i as f64).collect();
    println!("figure, v: {}", join(&vs, 0));
    for k in [3, 9] {
        println!("figure, chi-square {}: {}", k, join(&vs.iter().map(|&v| chi_d(v, k)).collect::<Vec<_>>(), 2));
    }
    assert!((p_t - s_t).abs() < 1e-9 && (p_q - s_q).abs() < 1e-9 && (p_f - s_f).abs() < 1e-9);   // closed forms against Simpson
    assert!((chi_tail(10.0, 10) - (1.0 - simpson(&|x| chi_d(x, 10), 0.0, 10.0))).abs() < 1e-9);
    assert!((f_tail(2.5, 6, 9) - (1.0 - simpson(&|x| f_d(x, 6, 9), 0.0, 2.5))).abs() < 1e-9);   // the swapped-beta branch
    assert!((r_t - p_t).abs() < 4.0 * e_t && (r_q - p_q).abs() < 4.0 * e_q && (r_f - p_f).abs() < 4.0 * e_f);
    assert!((mq - 9.0).abs() < 4.0 * (vq / nf).sqrt() && (vq - 18.0).abs() < 0.42);   // nine squares: mean 9, variance 18 (SE 0.104)
    assert!((r_z - t_tail2(1.96, 9)).abs() < 4.0 * e_z && (mt2 - 9.0 / 7.0).abs() < 4.0 * et2 && (mf - 1.5).abs() < 4.0 * ef);
    assert!(r_sk - 0.05 > 4.0 * e_sk);                  // skewed bags break the 5 percent promise
    assert!(r_st - 0.05 > 4.0 * e_st);                  // the t test's too, at ten bags
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-10-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
machine one: n 10, mean 502.000, squared residuals 90.0, S^2 10.000, S 3.162, S/sqrt(n) 1.000
machine two: n 7, mean 500.000, squared residuals 24.0, S^2 4.000
observed: t 2.000 on 9; V = 9 S^2/3^2 10.000 on 9; F = S1^2/S2^2 2.500 on (9, 6)
P(|T| > 2) on 9: closed form 0.0766; Simpson 0.0766; normal instead 0.0455
P(V > 10) on 9: closed form 0.3505; Simpson 0.3505. P(F > 2.5) on (9, 6): beta sum 0.1385; Simpson 0.1385
Gamma(1/2) 1.772454; Gamma(9/2) 11.631728; area under t on 9 1.000000
cutoffs: t on 9, 2.5% each side 2.262; normal 1.960
cutoffs: chi-square 9, middle 95% 2.700 to 19.023, top 5% 16.919; F (9, 6) top 5% 4.099
P(|T| > 1.96): t on 9 0.0816; t on 1 (Cauchy) P(|T| > 2) 0.2952
simulated 100000 rounds of 10 + 7 bags, true mean 500, sigma 3, seed 20260928; estimate (standard error)
  P(|T| > 2) 0.0770 (0.0008); P(V > 10) 0.3513 (0.0015); P(F > 2.5) 0.1385 (0.0011)
  V: mean 9.013 (0.013), variance 18.098; T: mean square 1.2956 (0.0075), formula 9/7 = 1.2857; F: mean 1.5024 (0.0057), formula 6/4 = 1.5000
mistake, cutoff 1.96 with an estimated spread: true label rejected 0.0823 (0.0009), closed form 0.0816
mistake, 10 degrees of freedom for 9: P(V > 10) 0.4405, not 0.3505
mistake, F read on (6, 9) for (9, 6): P(F > 2.5) 0.1047, not 0.1385
mistake, skewed bags (exponential, same mean and sd): 5% chi-square test rejects 0.1203 (0.0010); 5% t test 0.0998 (0.0009)
figure, t: -4.0, -3.5, -3.0, -2.5, -2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0
figure, normal: 0.00, 0.00, 0.00, 0.02, 0.05, 0.13, 0.24, 0.35, 0.40, 0.35, 0.24, 0.13, 0.05, 0.02, 0.00, 0.00, 0.00
figure, t on 9: 0.00, 0.01, 0.01, 0.03, 0.06, 0.13, 0.23, 0.34, 0.39, 0.34, 0.23, 0.13, 0.06, 0.03, 0.01, 0.01, 0.00
figure, t on 2: 0.01, 0.02, 0.03, 0.04, 0.07, 0.11, 0.19, 0.30, 0.35, 0.30, 0.19, 0.11, 0.07, 0.04, 0.03, 0.02, 0.01
figure, v: 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24
figure, chi-square 3: 0.00, 0.21, 0.11, 0.05, 0.02, 0.01, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00
figure, chi-square 9: 0.00, 0.02, 0.07, 0.10, 0.10, 0.08, 0.06, 0.04, 0.02, 0.01, 0.01, 0.00, 0.00
ALL CHECKS PASS
```

The two outputs match line for line, the simulation included, since both languages draw the same numbers from the same seed.

### Lean

Lean proves the chi-square, t and F laws for any normal machine and any number of bags from two up.

- Take k independent standard normals, with k at least 1. Then the sum of their squares follows the gamma law with shape k/2 and rate 1/2.
- Take the same k squares. Then their sum averages k, and its variance is 2k.
- Take n independent measurements from N(μ, σ^2), with n at least 2 and σ above 0. Then (n − 1)S^2/σ^2 is chi-square with n − 1 degrees of freedom.
- In the same sample, the average and the sample variance are independent.
- Take the same sample. Then the t ratio (X̄ − μ)/(S/√n) follows the t law with n − 1 degrees of freedom, whatever σ is.
- Take two normal samples of n_1 and n_2 bags, each at least 2, every bag independent and both spreads above 0. Then (S_1^2/σ_1^2)/(S_2^2/σ_2^2) follows the F law on (n_1 − 1, n_2 − 1).
- The ten bags average 502, their squared residuals add to 90, and their sample variance is 10.
- The seven bags average 500, with sample variance 4.
- The t ratio comes to 2, V to 10 when σ is 3, and the F ratio to 2.5.

Tail chances, cutoffs, Var(T), E[F], the simulation and the mistake table are left to the Python and Rust checks.

```lean
-- The reference distributions: a sum of k independent squared standard normals has the chi-square law (gamma with shape k/2 and rate 1/2, mean k, variance 2k), and for normal samples the scaled sample variance is chi-square on n − 1 degrees and independent of the average, the t ratio has Student's t density on n − 1 degrees, and the ratio of two samples' scaled variances has the F density on (n₁ − 1, n₂ − 1).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Gamma
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib

open MeasureTheory ProbabilityTheory Set Real
open scoped ENNReal NNReal

/-- The average of n measurements: their sum divided by n. -/
noncomputable def sampleMean {n : ℕ} (x : Fin n → ℝ) : ℝ := (∑ i, x i) / n

/-- The sample variance S²: the squared residuals (gaps from the average) added and divided
by n − 1. -/
noncomputable def sampleVar {n : ℕ} (x : Fin n → ℝ) : ℝ :=
  (∑ i, (x i - sampleMean x) ^ 2) / ((n : ℝ) - 1)

/-- Student's t density with ν degrees of freedom, as on the card:
f_T(t) = Γ((ν+1)/2) / (√(νπ) Γ(ν/2)) · (1 + t²/ν)^(−(ν+1)/2). -/
noncomputable def studentTPDF (ν t : ℝ) : ℝ :=
  Gamma ((ν + 1) / 2) / (√(ν * π) * Gamma (ν / 2)) * (1 + t ^ 2 / ν) ^ (-(ν + 1) / 2)

/-- The F density with ν₁ and ν₂ degrees of freedom, as on the card, with c = ν₁/ν₂:
f_F(x) = Γ((ν₁+ν₂)/2) c^(ν₁/2) x^(ν₁/2−1) / (Γ(ν₁/2) Γ(ν₂/2) (1 + c x)^((ν₁+ν₂)/2)) for x > 0,
and 0 for x ≤ 0. -/
noncomputable def fisherFPDF (ν₁ ν₂ x : ℝ) : ℝ :=
  if 0 < x then
    Gamma ((ν₁ + ν₂) / 2) * (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1) /
      (Gamma (ν₁ / 2) * Gamma (ν₂ / 2) * (1 + ν₁ / ν₂ * x) ^ ((ν₁ + ν₂) / 2))
  else 0

lemma lintegral_rpow_exp_Ioi {a b : ℝ} (ha : 0 < a) (hb : 0 < b) :
    ∫⁻ x in Ioi (0:ℝ), ENNReal.ofReal (x ^ (a - 1) * exp (-(b * x))) =
      ENNReal.ofReal ((1 / b) ^ a * Gamma a) := by
  rw [← integral_rpow_mul_exp_neg_mul_Ioi ha hb, ofReal_integral_eq_lintegral_ofReal]
  · apply Integrable.of_integral_ne_zero
    rw [integral_rpow_mul_exp_neg_mul_Ioi ha hb]; positivity
  · filter_upwards [ae_restrict_mem measurableSet_Ioi] with x hx
    have : (0:ℝ) ≤ x := le_of_lt hx
    positivity

#print axioms lintegral_rpow_exp_Ioi

lemma lintegral_comp_mul_left' (f : ℝ → ℝ≥0∞) {c : ℝ} (hc : c ≠ 0) :
    ∫⁻ x, f (c * x) = ENNReal.ofReal |c⁻¹| * ∫⁻ y, f y := by
  have e : MeasurableEmbedding (fun x : ℝ => c * x) :=
    (Homeomorph.mulLeft₀ c hc).measurableEmbedding
  rw [← e.lintegral_map, Real.map_volume_mul_left hc, lintegral_smul_measure, smul_eq_mul]

#print axioms lintegral_comp_mul_left'

lemma lintegral_eq_ofReal_mul_comp {F : ℝ → ℝ≥0∞} {z : ℝ} (hz : 0 < z) :
    ∫⁻ w, F w = ENNReal.ofReal z * ∫⁻ t, F (z * t) := by
  rw [lintegral_comp_mul_left' F hz.ne', ← mul_assoc, ← ENNReal.ofReal_mul (le_of_lt hz),
    abs_of_pos (inv_pos.2 hz), mul_inv_cancel₀ hz.ne', ENNReal.ofReal_one, one_mul]

#print axioms lintegral_eq_ofReal_mul_comp

lemma gamma_beta_identity {a b r z t : ℝ} (ha : 0 < a) (hb : 0 < b) (hr : 0 < r) (hz : 0 < z)
    (ht0 : 0 < t) (ht1 : t < 1) :
    r ^ b / Gamma b * (z * t) ^ (b - 1) * exp (-(r * (z * t))) *
      (r ^ a / Gamma a * (z - z * t) ^ (a - 1) * exp (-(r * (z - z * t)))) =
    r ^ (a + b) / Gamma (a + b) * z ^ (a + b - 1) * exp (-(r * z)) / z *
      (1 / beta b a * t ^ (b - 1) * (1 - t) ^ (a - 1)) := by
  have h1t : 0 < 1 - t := by linarith
  rw [mul_rpow hz.le ht0.le, show z - z * t = z * (1 - t) by ring, mul_rpow hz.le h1t.le,
    show a + b - 1 = (b - 1) + (a - 1) + 1 by ring, rpow_add hz, rpow_add hz, rpow_one,
    rpow_add hr, beta, add_comm b a]
  have hexp : exp (-(r * (z * t))) * exp (-(r * (z * (1 - t)))) = exp (-(r * z)) := by
    rw [← exp_add]; ring_nf
  have hGa := (Gamma_pos_of_pos ha).ne'
  have hGb := (Gamma_pos_of_pos hb).ne'
  have hGab := (Gamma_pos_of_pos (add_pos ha hb)).ne'
  rw [← hexp]
  field_simp

#print axioms gamma_beta_identity

lemma gamma_conv_density {a b r z : ℝ} (ha : 0 < a) (hb : 0 < b) (hr : 0 < r) (hz : 0 < z) :
    ∫⁻ w, gammaPDF b r w * gammaPDF a r (z - w) = gammaPDF (a + b) r z := by
  set C : ℝ := r ^ (a + b) / Gamma (a + b) * z ^ (a + b - 1) * exp (-(r * z)) / z
  have hC : 0 ≤ C := by positivity
  rw [lintegral_eq_ofReal_mul_comp hz]
  have hae : (fun t => gammaPDF b r (z * t) * gammaPDF a r (z - z * t)) =ᵐ[volume]
      fun t => ENNReal.ofReal C * betaPDF b a t := by
    filter_upwards [Measure.ae_ne volume 0, Measure.ae_ne volume 1] with t h0 h1
    rcases lt_or_gt_of_ne h0 with ht | ht
    · rw [gammaPDF_of_neg (mul_neg_of_pos_of_neg hz ht), betaPDF_eq_zero_of_nonpos ht.le]
      simp
    rcases lt_or_gt_of_ne h1 with ht' | ht'
    · rw [gammaPDF_of_nonneg (by positivity), gammaPDF_of_nonneg (by nlinarith),
        betaPDF_of_pos_lt_one ht ht', ← ENNReal.ofReal_mul (by positivity),
        ← ENNReal.ofReal_mul hC]
      congr 1
      exact gamma_beta_identity ha hb hr hz ht ht'
    · rw [gammaPDF_of_neg (a := a) (by nlinarith), betaPDF_eq_zero_of_one_le ht'.le]
      simp
  have hmb : Measurable (betaPDF b a) := (measurable_betaPDFReal b a).ennreal_ofReal
  rw [lintegral_congr_ae hae, lintegral_const_mul _ hmb,
    lintegral_betaPDF_eq_one hb ha, mul_one, ← ENNReal.ofReal_mul hz.le,
    gammaPDF_of_nonneg hz.le]
  congr 1
  simp only [C]
  field_simp

#print axioms gamma_conv_density

lemma measurable_gammaPDF' (a r : ℝ) : Measurable (gammaPDF a r) :=
  (measurable_gammaPDFReal a r).ennreal_ofReal

#print axioms measurable_gammaPDF'

lemma map_prod_withDensity_apply {f g : ℝ → ℝ≥0∞} (hf : Measurable f) (hg : Measurable g)
    {F : ℝ × ℝ → ℝ} (hF : Measurable F) {s : Set ℝ} (hs : MeasurableSet s) :
    (((volume.withDensity f).prod (volume.withDensity g)).map F) s =
      ∫⁻ y, g y * ∫⁻ x, f x * s.indicator 1 (F (x, y)) := by
  have hm : Measurable ((F ⁻¹' s).indicator (1 : ℝ × ℝ → ℝ≥0∞)) :=
    measurable_one.indicator (hF hs)
  rw [Measure.map_apply hF hs, ← lintegral_indicator_one (hF hs),
    lintegral_prod_symm _ hm.aemeasurable,
    lintegral_withDensity_eq_lintegral_mul _ hg (hm.lintegral_prod_left')]
  congr 1; ext y
  simp only [Pi.mul_apply]
  congr 1
  exact lintegral_withDensity_eq_lintegral_mul _ hf (hm.comp measurable_prodMk_right)

#print axioms map_prod_withDensity_apply

lemma gamma_conv {a b r : ℝ} (ha : 0 < a) (hb : 0 < b) (hr : 0 < r) :
    ((gammaMeasure a r).prod (gammaMeasure b r)).map (fun p => p.1 + p.2) =
      gammaMeasure (a + b) r := by
  ext s hs
  have hma := measurable_gammaPDF' a r
  have hmb := measurable_gammaPDF' b r
  rw [gammaMeasure, gammaMeasure, map_prod_withDensity_apply hma hmb measurable_add hs,
    gammaMeasure, withDensity_apply _ hs]
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  have h1 : ∀ y, gammaPDF b r y * ∫⁻ x, gammaPDF a r x * s.indicator 1 ((x, y).1 + (x, y).2) =
      ∫⁻ z, gammaPDF b r y * gammaPDF a r (z - y) * s.indicator 1 z := by
    intro y
    rw [← lintegral_add_right_eq_self (fun z => gammaPDF b r y * gammaPDF a r (z - y) *
      s.indicator 1 z) y]
    simp only [add_sub_cancel_right, mul_assoc]
    rw [lintegral_const_mul' _ _ (by simp [gammaPDF])]
  simp_rw [h1]
  rw [lintegral_lintegral_swap (by fun_prop), ← lintegral_indicator hs]
  apply lintegral_congr_ae
  filter_upwards [Measure.ae_ne volume 0] with z hz
  by_cases hzs : z ∈ s
  · simp only [indicator_of_mem hzs, Pi.one_apply, mul_one]
    rcases lt_or_gt_of_ne hz with hz | hz
    · rw [gammaPDF_of_neg hz]
      apply lintegral_eq_zero_of_ae_eq_zero (Filter.Eventually.of_forall fun y => ?_)
      rcases lt_or_ge y 0 with hy | hy
      · simp [gammaPDF_of_neg hy]
      · simp [gammaPDF_of_neg (show z - y < 0 by linarith)]
    · exact gamma_conv_density ha hb hr hz
  · simp [hzs]

#print axioms gamma_conv

instance sFinite_gammaMeasure (a r : ℝ) : SFinite (gammaMeasure a r) := by
  unfold gammaMeasure; infer_instance

#print axioms sFinite_gammaMeasure

lemma sq_density_identity {x : ℝ} (hx : 0 < x) :
    |2 * x| * ((1 / 2 : ℝ) ^ (1 / 2 : ℝ) / Gamma (1 / 2) * (x ^ 2) ^ ((1 / 2 : ℝ) - 1) *
      exp (-(1 / 2 * x ^ 2))) =
    2 * ((√(2 * π * ((1 : ℝ≥0) : ℝ)))⁻¹ * exp (-(x - 0) ^ 2 / (2 * ((1 : ℝ≥0) : ℝ)))) := by
  rw [Gamma_one_half_eq, show (1 / 2 : ℝ) - 1 = -(1 / 2) by norm_num,
    rpow_neg (sq_nonneg x), ← sqrt_eq_rpow, ← sqrt_eq_rpow, sqrt_sq hx.le,
    abs_of_pos (by positivity), NNReal.coe_one, mul_one, sqrt_mul (by norm_num), sub_zero]
  have h2 : (0:ℝ) < √2 := by positivity
  have hp : (0:ℝ) < √π := by positivity
  have hs : √(1/2 : ℝ) = 1 / √2 := by rw [sqrt_div' _ (by norm_num), sqrt_one]
  rw [hs, show -(1 / 2 * x ^ 2) = -x ^ 2 / 2 by ring]
  field_simp

#print axioms sq_density_identity

lemma gaussianPDF_neg (x : ℝ) : gaussianPDF 0 1 (-x) = gaussianPDF 0 1 x := by
  simp [gaussianPDF, gaussianPDFReal]

#print axioms gaussianPDF_neg

lemma image_sq_Ioi : (fun x : ℝ => x ^ 2) '' Ioi 0 = Ioi 0 := by
  ext v; constructor
  · rintro ⟨x, hx, rfl⟩; exact pow_pos (mem_Ioi.mp hx) 2
  · intro hv; exact ⟨√v, sqrt_pos.2 hv, sq_sqrt (le_of_lt hv)⟩

#print axioms image_sq_Ioi

lemma gaussian_map_sq :
    (gaussianReal 0 1).map (fun x => x ^ 2) = gammaMeasure (1 / 2) (1 / 2) := by
  ext s hs
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  have hφ : Measurable (gaussianPDF 0 1) := by fun_prop
  set h : ℝ → ℝ≥0∞ := fun x => gaussianPDF 0 1 x * s.indicator 1 (x ^ 2) with hh
  have hmh : Measurable h := hφ.mul (hsi.comp (measurable_id.pow_const 2))
  have hpre : MeasurableSet ((fun x : ℝ => x ^ 2) ⁻¹' s) := (continuous_pow 2).measurable hs
  have hL : ((gaussianReal 0 1).map (fun x => x ^ 2)) s = ∫⁻ x, h x := by
    rw [Measure.map_apply (by fun_prop) hs, gaussianReal_of_var_ne_zero _ one_ne_zero,
      withDensity_apply _ hpre, ← lintegral_indicator hpre]
    congr 1; ext x
    by_cases hx : x ^ 2 ∈ s <;> simp [hh, indicator, hx]
  have hsym : ∫⁻ x in Iic 0, h x = ∫⁻ x in Ioi 0, h x := by
    rw [← lintegral_indicator measurableSet_Iic, ← lintegral_neg_eq_self,
      setLIntegral_congr Ioi_ae_eq_Ici, ← lintegral_indicator measurableSet_Ici]
    congr 1; ext x
    simp only [indicator, mem_Iic, mem_Ici, neg_nonpos, hh, gaussianPDF_neg]
    rw [neg_sq]
  have hL2 : ∫⁻ x, h x = 2 * ∫⁻ x in Ioi 0, h x := by
    rw [← lintegral_add_compl _ measurableSet_Iic, compl_Iic, hsym, two_mul]
  set G : ℝ → ℝ≥0∞ := fun v => gammaPDF (1 / 2) (1 / 2) v * s.indicator 1 v with hG
  have hR : (gammaMeasure (1 / 2) (1 / 2)) s = ∫⁻ v in Ioi 0, G v := by
    rw [gammaMeasure, withDensity_apply _ hs, ← lintegral_indicator hs,
      ← lintegral_add_compl _ measurableSet_Iic, compl_Iic,
      setLIntegral_eq_zero measurableSet_Iic, zero_add]
    · apply setLIntegral_congr_fun measurableSet_Ioi (fun x _ => ?_)
      simp only [hG, indicator, Pi.one_apply]
      split_ifs <;> simp
    · intro x hx
      simp only [indicator]
      split_ifs
      · rcases (mem_Iic.mp hx).lt_or_eq with hx | hx
        · exact gammaPDF_of_neg hx
        · rw [hx, gammaPDF_of_nonneg le_rfl, zero_rpow (by norm_num)]; simp
      · rfl
  have hI : ∫⁻ v in Ioi 0, G v = ∫⁻ x in Ioi 0, ENNReal.ofReal |2 * x| * G (x ^ 2) := by
    conv_lhs => rw [← image_sq_Ioi]
    exact lintegral_image_eq_lintegral_abs_deriv_mul measurableSet_Ioi
      (f' := fun x => 2 * x) (fun x _ => by simpa using (hasDerivAt_pow 2 x).hasDerivWithinAt)
      (fun x hx y hy hxy => (pow_left_inj₀ (mem_Ioi.mp hx).le (mem_Ioi.mp hy).le
        two_ne_zero).1 hxy) G
  rw [hL, hR, hL2, hI, ← lintegral_const_mul _ hmh]
  apply setLIntegral_congr_fun measurableSet_Ioi (fun x hx => ?_)
  have hx : 0 < x := hx
  simp only [hh, hG, ← mul_assoc]
  congr 1
  rw [gammaPDF_of_nonneg (sq_nonneg x), gaussianPDF, ← ENNReal.ofReal_mul (abs_nonneg _),
    sq_density_identity hx, ENNReal.ofReal_mul (by norm_num)]
  simp [gaussianPDFReal]

#print axioms gaussian_map_sq

lemma pi_sumsq_step (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2) =
      (((gaussianReal 0 1).map (fun x => x ^ 2)).prod
        ((Measure.pi (fun _ : Fin m => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2))).map
          (fun p => p.1 + p.2) := by
  have hmp := measurePreserving_piFinSuccAbove (fun _ : Fin (m + 1) => gaussianReal 0 1) 0
  have hfun : (fun x : Fin (m + 1) → ℝ => ∑ i, x i ^ 2) =
      (fun p : ℝ × (Fin m → ℝ) => p.1 ^ 2 + ∑ i, p.2 i ^ 2) ∘
        (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 1) => ℝ) 0) := by
    ext x
    simp [Fin.sum_univ_succ, MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [hfun, ← Measure.map_map (by fun_prop) (MeasurableEquiv.measurable _), hmp.map_eq,
    Measure.map_prod_map _ _ (by fun_prop) (by fun_prop), Measure.map_map (by fun_prop)
      (by fun_prop)]
  rfl

#print axioms pi_sumsq_step

lemma pi_sumsq_chi' (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2) =
      gammaMeasure (((m + 1 : ℕ) : ℝ) / 2) (1 / 2) := by
  induction m with
  | zero =>
    rw [pi_sumsq_step, gaussian_map_sq]
    simp only [Finset.univ_eq_empty, Finset.sum_empty, Measure.map_const, measure_univ,
      one_smul]
    rw [Measure.prod_dirac, Measure.map_map (by fun_prop) (by fun_prop)]
    simp [Function.comp_def]
  | succ m ih =>
    rw [pi_sumsq_step, gaussian_map_sq, ih, gamma_conv (by norm_num) (by positivity)
      (by norm_num)]
    congr 1
    push_cast; ring

#print axioms pi_sumsq_chi'

lemma pi_sumsq_chi (k : ℕ) (hk : 0 < k) :
    (Measure.pi (fun _ : Fin k => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2) =
      gammaMeasure ((k : ℝ) / 2) (1 / 2) := by
  obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
  exact pi_sumsq_chi' m

#print axioms pi_sumsq_chi

lemma pi_head_rest (m : ℕ) (hm : 0 < m) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map
      (fun x => (x 0, ∑ i, x i ^ 2 - x 0 ^ 2)) =
      (gaussianReal 0 1).prod (gammaMeasure ((m : ℝ) / 2) (1 / 2)) := by
  have hmp := measurePreserving_piFinSuccAbove (fun _ : Fin (m + 1) => gaussianReal 0 1) 0
  have hfun : (fun x : Fin (m + 1) → ℝ => (x 0, ∑ i, x i ^ 2 - x 0 ^ 2)) =
      (Prod.map id (fun y : Fin m → ℝ => ∑ i, y i ^ 2)) ∘
        (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 1) => ℝ) 0) := by
    ext x
    · simp [MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv]
    · simp [Fin.sum_univ_succ, MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [hfun, ← Measure.map_map (by fun_prop) (MeasurableEquiv.measurable _), hmp.map_eq,
    ← Measure.map_prod_map _ _ (by fun_prop) (by fun_prop), Measure.map_id, pi_sumsq_chi m hm]

#print axioms pi_head_rest

@[fun_prop]
lemma measurable_sampleMean (n : ℕ) : Measurable (fun x : Fin n → ℝ => sampleMean x) := by
  unfold sampleMean; fun_prop

#print axioms measurable_sampleMean

lemma sum_sq_sub_mean {n : ℕ} (hn : 0 < n) (x : Fin n → ℝ) :
    ∑ i, (x i - sampleMean x) ^ 2 = ∑ i, x i ^ 2 - (∑ i, x i) ^ 2 / n := by
  have hN : (n : ℝ) ≠ 0 := by positivity
  simp only [sampleMean, sub_sq, Finset.sum_add_distrib, Finset.sum_sub_distrib,
    ← Finset.sum_mul, ← Finset.mul_sum, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
    nsmul_eq_mul]
  field_simp
  ring

#print axioms sum_sq_sub_mean

lemma pi_sample_stats (n : ℕ) (hn : 2 ≤ n) :
    (Measure.pi (fun _ : Fin n => gaussianReal 0 1)).map
      (fun x => (√(n : ℝ) * sampleMean x, ∑ i, (x i - sampleMean x) ^ 2)) =
    (gaussianReal 0 1).prod (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  set N : ℝ := ((m + 1 : ℕ) : ℝ) with hNdef
  have hN : 0 < N := by positivity
  let E := EuclideanSpace ℝ (Fin (m + 1))
  let u : E := WithLp.toLp 2 (fun _ => 1 / √N)
  let e0 : E := EuclideanSpace.single 0 1
  have he0 : ‖e0‖ = 1 := by
    have : ‖e0‖ ^ 2 = 1 := by
      rw [EuclideanSpace.real_norm_sq_eq]
      simp [e0]
    nlinarith [norm_nonneg e0]
  have hu1 : ‖u‖ = 1 := by
    have : ‖u‖ ^ 2 = 1 := by
      rw [EuclideanSpace.real_norm_sq_eq]
      simp [u, Real.sq_sqrt hN.le, ← hNdef]
    nlinarith [norm_nonneg u]
  have hu : ‖u‖ = ‖e0‖ := by rw [he0, hu1]
  let R := (ℝ ∙ (u - e0))ᗮ.reflection
  have hRu : R u = e0 := Submodule.reflection_sub hu
  have hRe : R e0 = u := by rw [← hRu, Submodule.reflection_reflection]
  have h0 : ∀ z : E, (R z).ofLp 0 = ∑ i, z.ofLp i / √N := by
    intro z
    have h1 : (R z).ofLp 0 = inner ℝ e0 (R z) := by
      rw [EuclideanSpace.inner_single_left]; simp
    rw [h1, ← LinearIsometryEquiv.inner_map_map R, hRe, Submodule.reflection_reflection]
    rw [PiLp.inner_apply]; simp [u, div_eq_mul_inv, mul_comm]
  have hsq : ∀ z : E, ∑ i, (R z).ofLp i ^ 2 = ∑ i, z.ofLp i ^ 2 := by
    intro z
    rw [← EuclideanSpace.real_norm_sq_eq, ← EuclideanSpace.real_norm_sq_eq,
      LinearIsometryEquiv.norm_map]
  have hsN : √N ^ 2 = N := Real.sq_sqrt hN.le
  have hsN0 : √N ≠ 0 := by positivity
  have hstat : (fun x : Fin (m + 1) → ℝ => (√N * sampleMean x, ∑ i, (x i - sampleMean x) ^ 2)) =
      (fun y : Fin (m + 1) → ℝ => (y 0, ∑ i, y i ^ 2 - y 0 ^ 2)) ∘ WithLp.ofLp ∘ R ∘
        WithLp.toLp 2 := by
    ext x
    · simp only [Function.comp_apply, h0, ← Finset.sum_div, sampleMean, ← hNdef]
      field_simp
      rw [hsN]; ring
    · simp only [Function.comp_apply, h0, hsq, ← Finset.sum_div,
        sum_sq_sub_mean (Nat.succ_pos m), ← hNdef]
      rw [div_pow, hsN]
  rw [hstat, ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_map (by fun_prop) (by fun_prop), map_pi_eq_stdGaussian, stdGaussian_map R,
    ← map_pi_eq_stdGaussian, Measure.map_map (by fun_prop) (by fun_prop)]
  rw [Measure.map_map (by fun_prop) (by fun_prop)]
  convert pi_head_rest m (by omega) using 3
  all_goals first | rfl | (rw [hNdef]; push_cast; ring)

#print axioms pi_sample_stats

lemma t_pointwise {ν v t : ℝ} (hν : 0 < ν) (hv : 0 < v) :
    (1 / 2 : ℝ) ^ (ν / 2) / Gamma (ν / 2) * v ^ (ν / 2 - 1) * exp (-(1 / 2 * v)) *
      (√(v / ν) * ((√(2 * π * ((1 : ℝ≥0) : ℝ)))⁻¹ *
        exp (-(√(v / ν) * t - 0) ^ 2 / (2 * ((1 : ℝ≥0) : ℝ))))) =
    (1 / 2 : ℝ) ^ (ν / 2) / (Gamma (ν / 2) * √(2 * π * ν)) *
      (v ^ ((ν + 1) / 2 - 1) * exp (-((1 + t ^ 2 / ν) / 2 * v))) := by
  have hexp : exp (-(1 / 2 * v)) * exp (-(√(v / ν) * t - 0) ^ 2 / (2 * ((1 : ℝ≥0) : ℝ))) =
      exp (-((1 + t ^ 2 / ν) / 2 * v)) := by
    rw [← exp_add, sub_zero, mul_pow, sq_sqrt (by positivity)]
    congr 1; push_cast; field_simp; ring
  rw [show (ν + 1) / 2 - 1 = (ν / 2 - 1) + 1 / 2 by ring, rpow_add hv, ← sqrt_eq_rpow, ← hexp,
    sqrt_div' _ hν.le, NNReal.coe_one, mul_one, sqrt_mul (by positivity) ν]
  have h1 := (Gamma_pos_of_pos (half_pos hν)).ne'
  have h2 : 0 < √(2 * π) := by positivity
  have h3 : 0 < √ν := by positivity
  field_simp

#print axioms t_pointwise

lemma t_const {ν t : ℝ} (hν : 0 < ν) :
    (1 / 2 : ℝ) ^ (ν / 2) / (Gamma (ν / 2) * √(2 * π * ν)) *
      ((1 / ((1 + t ^ 2 / ν) / 2)) ^ ((ν + 1) / 2) * Gamma ((ν + 1) / 2)) = studentTPDF ν t := by
  have hb : 0 < 1 + t ^ 2 / ν := by positivity
  rw [studentTPDF, one_div_div, div_rpow (by norm_num) hb.le,
    show -(ν + 1) / 2 = -((ν + 1) / 2) by ring, rpow_neg hb.le,
    show (ν + 1) / 2 = ν / 2 + 1 / 2 by ring, rpow_add (by norm_num : (0:ℝ) < 2),
    ← sqrt_eq_rpow, div_rpow (by norm_num) (by norm_num), one_rpow,
    show 2 * π * ν = 2 * (ν * π) by ring, sqrt_mul (by norm_num)]
  have h1 := (Gamma_pos_of_pos (half_pos hν)).ne'
  have h2 : 0 < √2 := by positivity
  have h3 : 0 < √(ν * π) := by positivity
  have h4 : 0 < (2 : ℝ) ^ (ν / 2) := by positivity
  have h5 : 0 < (1 + t ^ 2 / ν) ^ (ν / 2 + 1 / 2) := by positivity
  field_simp

#print axioms t_const

lemma t_density_at {ν : ℝ} (hν : 0 < ν) (t : ℝ) :
    ∫⁻ v, gammaPDF (ν / 2) (1 / 2) v * (ENNReal.ofReal (√(v / ν)) *
      gaussianPDF 0 1 (√(v / ν) * t)) = ENNReal.ofReal (studentTPDF ν t) := by
  rw [← lintegral_add_compl _ measurableSet_Iic, compl_Iic,
    setLIntegral_eq_zero measurableSet_Iic, zero_add]
  · rw [setLIntegral_congr_fun measurableSet_Ioi (g := fun v => ENNReal.ofReal
      ((1 / 2 : ℝ) ^ (ν / 2) / (Gamma (ν / 2) * √(2 * π * ν)) *
      (v ^ ((ν + 1) / 2 - 1) * exp (-((1 + t ^ 2 / ν) / 2 * v)))))]
    · rw [← t_const hν (t := t), ENNReal.ofReal_mul (by positivity),
        ← lintegral_rpow_exp_Ioi (by positivity) (by positivity),
        ← lintegral_const_mul]
      · simp_rw [← ENNReal.ofReal_mul (by positivity : (0:ℝ) ≤ (1 / 2 : ℝ) ^ (ν / 2) /
          (Gamma (ν / 2) * √(2 * π * ν)))]
        rfl
      · exact (((measurable_id.pow_const _).mul
          (measurable_id.const_mul _).neg.exp)).ennreal_ofReal
    · intro v hv
      have hv : 0 < v := hv
      dsimp only
      rw [gammaPDF_of_nonneg hv.le, gaussianPDF, gaussianPDFReal, ← ENNReal.ofReal_mul
        (by positivity), ← ENNReal.ofReal_mul (by positivity), t_pointwise hν hv]
  · intro v hv
    rcases (mem_Iic.mp hv).lt_or_eq with hv | hv
    · dsimp only; rw [gammaPDF_of_neg hv, zero_mul]; rfl
    · rw [hv]; simp

#print axioms t_density_at

lemma t_law {ν : ℝ} (hν : 0 < ν) :
    ((gaussianReal 0 1).prod (gammaMeasure (ν / 2) (1 / 2))).map (fun p => p.1 / √(p.2 / ν)) =
      volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ν t)) := by
  ext s hs
  have hφ : Measurable (gaussianPDF 0 1) := by fun_prop
  have hg := measurable_gammaPDF' (ν / 2) (1 / 2)
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  rw [gaussianReal_of_var_ne_zero 0 one_ne_zero, gammaMeasure,
    map_prod_withDensity_apply hφ hg (by fun_prop) hs, withDensity_apply _ hs]
  have h1 : ∀ᵐ v ∂volume, gammaPDF (ν / 2) (1 / 2) v *
      ∫⁻ z, gaussianPDF 0 1 z * s.indicator 1 ((z, v).1 / √((z, v).2 / ν)) =
      ∫⁻ t, gammaPDF (ν / 2) (1 / 2) v * (ENNReal.ofReal (√(v / ν)) *
        gaussianPDF 0 1 (√(v / ν) * t)) * s.indicator 1 t := by
    filter_upwards [Measure.ae_ne volume 0] with v hv
    rcases lt_or_gt_of_ne hv with hv | hv
    · simp [gammaPDF_of_neg hv]
    · have hc : 0 < √(v / ν) := sqrt_pos.2 (div_pos hv hν)
      rw [lintegral_eq_ofReal_mul_comp hc, ← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top,
        ← lintegral_const_mul' _ _ (by simp [gammaPDF])]
      congr 1; ext t
      simp only [mul_div_cancel_left₀ t hc.ne']
      ring
  rw [lintegral_congr_ae h1, lintegral_lintegral_swap, ← lintegral_indicator hs]
  · congr 1; ext t
    rw [lintegral_mul_const _ (by fun_prop), t_density_at hν t]
    by_cases ht : t ∈ s <;> simp [ht]
  · apply Measurable.aemeasurable
    apply Measurable.mul _ (hsi.comp measurable_snd)
    apply Measurable.mul (hg.comp measurable_fst)
    exact ((measurable_fst.div_const ν).sqrt.ennreal_ofReal).mul
      (hφ.comp (((measurable_fst.div_const ν).sqrt).mul measurable_snd))

#print axioms t_law

lemma f_pointwise {a b q w x : ℝ} (ha : 0 < a) (hb : 0 < b) (hq : 0 < q) (hw : 0 < w) (hx : 0 < x) :
    (1 / 2 : ℝ) ^ b / Gamma b * w ^ (b - 1) * exp (-(1 / 2 * w)) *
      (q * w * ((1 / 2 : ℝ) ^ a / Gamma a * (q * w * x) ^ (a - 1) *
        exp (-(1 / 2 * (q * w * x))))) =
    (1 / 2 : ℝ) ^ a * (1 / 2 : ℝ) ^ b / (Gamma a * Gamma b) * q ^ a * x ^ (a - 1) *
      (w ^ ((a + b) - 1) * exp (-((1 + q * x) / 2 * w))) := by
  have hexp : exp (-(1 / 2 * w)) * exp (-(1 / 2 * (q * w * x))) =
      exp (-((1 + q * x) / 2 * w)) := by
    rw [← exp_add]; congr 1; ring
  rw [mul_rpow (by positivity) hx.le, mul_rpow hq.le hw.le,
    show a + b - 1 = (b - 1) + (a - 1) + 1 by ring, rpow_add hw, rpow_add hw, rpow_one,
    show q ^ a = q ^ (a - 1 + 1) by ring_nf, rpow_add hq, rpow_one, ← hexp]
  have h1 : Gamma a ≠ 0 := (Gamma_pos_of_pos ha).ne'
  have h2 : Gamma b ≠ 0 := (Gamma_pos_of_pos hb).ne'
  field_simp

#print axioms f_pointwise

lemma f_const {ν₁ ν₂ x : ℝ} (h1 : 0 < ν₁) (h2 : 0 < ν₂) (hx : 0 < x) :
    (1 / 2 : ℝ) ^ (ν₁ / 2) * (1 / 2 : ℝ) ^ (ν₂ / 2) / (Gamma (ν₁ / 2) * Gamma (ν₂ / 2)) *
      (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1) *
      ((1 / ((1 + ν₁ / ν₂ * x) / 2)) ^ (ν₁ / 2 + ν₂ / 2) * Gamma (ν₁ / 2 + ν₂ / 2)) =
    fisherFPDF ν₁ ν₂ x := by
  have hb : 0 < 1 + ν₁ / ν₂ * x := by positivity
  simp only [fisherFPDF, hx, ↓reduceIte]
  rw [one_div_div, div_rpow (by norm_num) hb.le,
    show (ν₁ + ν₂) / 2 = ν₁ / 2 + ν₂ / 2 by ring, rpow_add (by norm_num : (0:ℝ) < 2),
    div_rpow (by norm_num) (by norm_num), div_rpow (by norm_num) (by norm_num), one_rpow, one_rpow]
  have g1 := (Gamma_pos_of_pos (half_pos h1)).ne'
  have g2 := (Gamma_pos_of_pos (half_pos h2)).ne'
  have h4 : 0 < (2 : ℝ) ^ (ν₁ / 2) := by positivity
  have h4' : 0 < (2 : ℝ) ^ (ν₂ / 2) := by positivity
  have h5 : 0 < (1 + ν₁ / ν₂ * x) ^ (ν₁ / 2 + ν₂ / 2) := by positivity
  field_simp

#print axioms f_const

lemma f_density_at {ν₁ ν₂ : ℝ} (h1 : 0 < ν₁) (h2 : 0 < ν₂) {x : ℝ} (hx : x ≠ 0) :
    ∫⁻ w, gammaPDF (ν₂ / 2) (1 / 2) w * (ENNReal.ofReal (ν₁ / ν₂ * w) *
      gammaPDF (ν₁ / 2) (1 / 2) (ν₁ / ν₂ * w * x)) = ENNReal.ofReal (fisherFPDF ν₁ ν₂ x) := by
  have hq : 0 < ν₁ / ν₂ := div_pos h1 h2
  rcases lt_or_gt_of_ne hx with hx | hx
  · have : fisherFPDF ν₁ ν₂ x = 0 := by simp [fisherFPDF, hx.not_gt]
    rw [this, ENNReal.ofReal_zero]
    apply lintegral_eq_zero_of_ae_eq_zero (Filter.Eventually.of_forall fun w => ?_)
    rcases lt_trichotomy w 0 with hw | hw | hw
    · simp [gammaPDF_of_neg hw]
    · simp [hw]
    · simp [gammaPDF_of_neg (mul_neg_of_pos_of_neg (mul_pos hq hw) hx)]
  rw [← lintegral_add_compl _ measurableSet_Iic, compl_Iic,
    setLIntegral_eq_zero measurableSet_Iic, zero_add]
  · rw [setLIntegral_congr_fun measurableSet_Ioi (g := fun w => ENNReal.ofReal
      ((1 / 2 : ℝ) ^ (ν₁ / 2) * (1 / 2 : ℝ) ^ (ν₂ / 2) / (Gamma (ν₁ / 2) * Gamma (ν₂ / 2)) *
        (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1) *
      (w ^ ((ν₁ / 2 + ν₂ / 2) - 1) * exp (-((1 + ν₁ / ν₂ * x) / 2 * w)))))]
    · rw [← f_const h1 h2 hx, ENNReal.ofReal_mul (by positivity),
        ← lintegral_rpow_exp_Ioi (by positivity) (by positivity),
        ← lintegral_const_mul]
      · simp_rw [← ENNReal.ofReal_mul (by positivity : (0:ℝ) ≤ (1 / 2 : ℝ) ^ (ν₁ / 2) *
          (1 / 2 : ℝ) ^ (ν₂ / 2) / (Gamma (ν₁ / 2) * Gamma (ν₂ / 2)) *
          (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1))]
        rfl
      · exact (((measurable_id.pow_const _).mul
          (measurable_id.const_mul _).neg.exp)).ennreal_ofReal
    · intro w hw
      have hw : 0 < w := hw
      dsimp only
      rw [gammaPDF_of_nonneg hw.le, gammaPDF_of_nonneg (by positivity), ← ENNReal.ofReal_mul
        (by positivity), ← ENNReal.ofReal_mul (by positivity),
        f_pointwise (half_pos h1) (half_pos h2) hq hw hx]
  · intro w hw
    rcases (mem_Iic.mp hw).lt_or_eq with hw | hw
    · dsimp only; rw [gammaPDF_of_neg hw, zero_mul]; rfl
    · rw [hw]; simp

#print axioms f_density_at

lemma f_law {ν₁ ν₂ : ℝ} (h1 : 0 < ν₁) (h2 : 0 < ν₂) :
    ((gammaMeasure (ν₁ / 2) (1 / 2)).prod (gammaMeasure (ν₂ / 2) (1 / 2))).map
      (fun p => (p.1 / ν₁) / (p.2 / ν₂)) =
      volume.withDensity (fun x => ENNReal.ofReal (fisherFPDF ν₁ ν₂ x)) := by
  ext s hs
  have ha := measurable_gammaPDF' (ν₁ / 2) (1 / 2)
  have hb := measurable_gammaPDF' (ν₂ / 2) (1 / 2)
  have hq : 0 < ν₁ / ν₂ := div_pos h1 h2
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  rw [gammaMeasure, gammaMeasure, map_prod_withDensity_apply ha hb (by fun_prop) hs,
    withDensity_apply _ hs]
  have e1 : ∀ᵐ w ∂volume, gammaPDF (ν₂ / 2) (1 / 2) w *
      ∫⁻ u, gammaPDF (ν₁ / 2) (1 / 2) u * s.indicator 1 (((u, w).1 / ν₁) / ((u, w).2 / ν₂)) =
      ∫⁻ x, gammaPDF (ν₂ / 2) (1 / 2) w * (ENNReal.ofReal (ν₁ / ν₂ * w) *
        gammaPDF (ν₁ / 2) (1 / 2) (ν₁ / ν₂ * w * x)) * s.indicator 1 x := by
    filter_upwards [Measure.ae_ne volume 0] with w hw
    rcases lt_or_gt_of_ne hw with hw | hw
    · simp [gammaPDF_of_neg hw]
    · have hc : 0 < ν₁ / ν₂ * w := mul_pos hq hw
      rw [lintegral_eq_ofReal_mul_comp hc, ← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top,
        ← lintegral_const_mul' _ _ (by simp [gammaPDF])]
      congr 1; ext x
      have : ν₁ / ν₂ * w * x / ν₁ / (w / ν₂) = x := by field_simp
      simp only [this]
      ring
  rw [lintegral_congr_ae e1, lintegral_lintegral_swap, ← lintegral_indicator hs]
  · apply lintegral_congr_ae
    filter_upwards [Measure.ae_ne volume 0] with x hx
    rw [lintegral_mul_const _ (by fun_prop), f_density_at h1 h2 hx]
    by_cases hxs : x ∈ s <;> simp [hxs]
  · apply Measurable.aemeasurable
    apply Measurable.mul _ (hsi.comp measurable_snd)
    apply Measurable.mul (hb.comp measurable_fst)
    exact ((measurable_fst.const_mul _).ennreal_ofReal).mul
      (ha.comp ((measurable_fst.const_mul _).mul measurable_snd))

#print axioms f_law

lemma gamma_moment_fun {a r : ℝ} (p : ℕ) (hp : 1 ≤ p) :
    (fun x => gammaPDFReal a r x * x ^ p) =
      (Ioi 0).indicator (fun x => r ^ a / Gamma a * (x ^ (a + p - 1) * exp (-(r * x)))) := by
  ext x
  by_cases hx : 0 < x
  · simp only [indicator, mem_Ioi, hx, ↓reduceIte, gammaPDFReal, hx.le]
    rw [show a + p - 1 = (a - 1) + (p : ℝ) by ring, rpow_add hx, rpow_natCast]
    ring
  · simp only [indicator, mem_Ioi, hx, ↓reduceIte]
    rcases (not_lt.mp hx).lt_or_eq with hx | hx
    · simp [gammaPDFReal, hx.not_ge]
    · rw [hx]; simp [zero_pow (by omega : p ≠ 0)]

#print axioms gamma_moment_fun

lemma gamma_moment {a r : ℝ} (ha : 0 < a) (hr : 0 < r) (p : ℕ) (hp : 1 ≤ p) :
    Integrable (fun x => x ^ p) (gammaMeasure a r) ∧
      ∫ x, x ^ p ∂(gammaMeasure a r) = r ^ a / Gamma a * ((1 / r) ^ (a + p) * Gamma (a + p)) := by
  have hm := measurable_gammaPDF' a r
  have hlt : ∀ᵐ x ∂(volume : Measure ℝ), gammaPDF a r x < ∞ :=
    Filter.Eventually.of_forall fun x => by simp [gammaPDF]
  have hto : ∀ x, (gammaPDF a r x).toReal = gammaPDFReal a r x := fun x =>
    ENNReal.toReal_ofReal (gammaPDFReal_nonneg ha hr x)
  have hap : 0 < a + p := by positivity
  have hI : ∫ x in Ioi (0:ℝ), r ^ a / Gamma a * (x ^ (a + p - 1) * exp (-(r * x))) =
      r ^ a / Gamma a * ((1 / r) ^ (a + p) * Gamma (a + p)) := by
    rw [integral_const_mul, integral_rpow_mul_exp_neg_mul_Ioi hap hr]
  have hint : IntegrableOn (fun x => r ^ a / Gamma a * (x ^ (a + p - 1) * exp (-(r * x))))
      (Ioi 0) := by
    apply Integrable.of_integral_ne_zero
    rw [hI]; positivity
  constructor
  · rw [gammaMeasure, integrable_withDensity_iff hm hlt]
    simp_rw [hto, mul_comm _ (gammaPDFReal a r _)]
    rw [gamma_moment_fun p hp, integrable_indicator_iff measurableSet_Ioi]
    exact hint
  · rw [gammaMeasure, integral_withDensity_eq_integral_toReal_smul hm hlt]
    simp_rw [hto, smul_eq_mul]
    rw [gamma_moment_fun p hp, integral_indicator measurableSet_Ioi, hI]

#print axioms gamma_moment

lemma gamma_mean {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    ∫ x, x ∂(gammaMeasure a r) = a / r := by
  have h := (gamma_moment ha hr 1 le_rfl).2
  simp only [pow_one, Nat.cast_one] at h
  rw [h, Gamma_add_one ha.ne', rpow_add_one (by positivity), div_rpow zero_le_one hr.le,
    one_rpow]
  have := (Gamma_pos_of_pos ha).ne'
  have : r ^ a ≠ 0 := (rpow_pos_of_pos hr a).ne'
  field_simp

#print axioms gamma_mean

lemma gamma_variance {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    variance id (gammaMeasure a r) = a / r ^ 2 := by
  have := isProbabilityMeasure_gammaMeasure ha hr
  have h2 := gamma_moment ha hr 2 (by norm_num)
  have hmem : MemLp id 2 (gammaMeasure a r) :=
    (memLp_two_iff_integrable_sq aestronglyMeasurable_id).2 h2.1
  rw [variance_eq_sub hmem]
  simp only [id_eq]
  rw [show (∫ x, x ∂(gammaMeasure a r)) = a / r from gamma_mean ha hr]
  rw [show (∫ x, (id ^ 2 : ℝ → ℝ) x ∂(gammaMeasure a r)) = ∫ x, x ^ 2 ∂(gammaMeasure a r) from rfl,
    h2.2]
  rw [show a + ((2 : ℕ) : ℝ) = (a + 1) + 1 by push_cast; ring, Gamma_add_one (by positivity),
    Gamma_add_one ha.ne', rpow_add_one (by positivity), rpow_add_one (by positivity),
    div_rpow zero_le_one hr.le, one_rpow]
  have := (Gamma_pos_of_pos ha).ne'
  have : r ^ a ≠ 0 := (rpow_pos_of_pos hr a).ne'
  field_simp
  ring

#print axioms gamma_variance

lemma gaussianReal_singleton (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) (c : ℝ) :
    gaussianReal μ v {c} = 0 := by
  rw [gaussianReal_of_var_ne_zero μ hv, withDensity_apply _ (measurableSet_singleton c),
    Measure.restrict_eq_zero.2 Real.volume_singleton, lintegral_zero_measure]

#print axioms gaussianReal_singleton

lemma aemeasurable_of_map_eq {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {f : Ω → ℝ}
    {μ : Measure ℝ} (hμ : ∀ c, μ {c} = 0) (h : P.map f = μ) : AEMeasurable f P := by
  by_contra hf
  rw [Measure.map_of_not_aemeasurable_of_ne_zero hf (IsProbabilityMeasure.ne_zero P)] at h
  have := congrArg (fun m : Measure ℝ => m {Classical.ofNonempty}) h
  simp [hμ] at this

#print axioms aemeasurable_of_map_eq

lemma gaussian_standardize (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (gaussianReal μ (σ ^ 2)).map (fun x => (x - μ) / σ) = gaussianReal 0 1 := by
  have h : (fun x : ℝ => (x - μ) / σ) = (· / (σ : ℝ)) ∘ (· - μ) := rfl
  rw [h, ← Measure.map_map (by fun_prop) (by fun_prop), gaussianReal_map_sub_const,
    gaussianReal_map_div_const, sub_self, zero_div]
  congr 1
  ext
  have : (σ : ℝ) ≠ 0 := by positivity
  simp [this]

#print axioms gaussian_standardize

lemma pi_gaussian_standardize (n : ℕ) (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2))).map
      (fun x i => (x i - μ) / σ) = Measure.pi (fun _ : Fin n => gaussianReal 0 1) := by
  refine (Measure.pi_map_pi (μ := fun _ : Fin n => gaussianReal μ (σ ^ 2))
    (f := fun _ y => (y - μ) / (σ : ℝ)) (fun _ => by fun_prop)).trans ?_
  simp_rw [gaussian_standardize μ hσ]

#print axioms pi_gaussian_standardize

lemma sampleMean_standardize {n : ℕ} (hn : 0 < n) (x : Fin n → ℝ) (μ σ : ℝ) :
    sampleMean (fun i => (x i - μ) / σ) = (sampleMean x - μ) / σ := by
  have hN : (n : ℝ) ≠ 0 := by positivity
  simp only [sampleMean, ← Finset.sum_div, Finset.sum_sub_distrib, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  by_cases hσ : σ = 0
  · simp [hσ]
  field_simp

#print axioms sampleMean_standardize

lemma pi_gaussian_sample_stats (n : ℕ) (hn : 2 ≤ n) (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2))).map
      (fun x => (√(n : ℝ) * ((sampleMean x - μ) / σ),
        (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2)) =
    (gaussianReal 0 1).prod (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) := by
  have hσ' : (σ : ℝ) ≠ 0 := by positivity
  have hfun : (fun x : Fin n → ℝ => (√(n : ℝ) * ((sampleMean x - μ) / σ),
        (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2)) =
      (fun z : Fin n → ℝ => (√(n : ℝ) * sampleMean z, ∑ i, (z i - sampleMean z) ^ 2)) ∘
        (fun x i => (x i - μ) / σ) := by
    ext x
    · simp [sampleMean_standardize (by omega : 0 < n)]
    · simp only [Function.comp_apply, sampleMean_standardize (by omega : 0 < n), Finset.sum_div]
      congr 1; ext i
      field_simp
      ring
  rw [hfun, ← Measure.map_map (by fun_prop) (by fun_prop), pi_gaussian_standardize n μ hσ,
    pi_sample_stats n hn]

#print axioms pi_gaussian_sample_stats

lemma pi_gaussian_sumsq_law (n : ℕ) (hn : 2 ≤ n) (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2))).map
      (fun x => (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2) =
    gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2) := by
  have := pi_gaussian_sample_stats n hn μ hσ
  rw [show (fun x : Fin n → ℝ => (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2) =
      Prod.snd ∘ (fun x => (√(n : ℝ) * ((sampleMean x - μ) / σ),
        (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2)) from rfl,
    ← Measure.map_map measurable_snd (by fun_prop), this, Measure.map_snd_prod, measure_univ,
    one_smul]

#print axioms pi_gaussian_sumsq_law

/-- **What a normal sample gives.** Take n ≥ 2 independent measurements X₁, …, Xₙ, each normal
with true mean μ and true standard deviation σ > 0. Let X̄ be their average and S² their sample
variance (divided by n − 1). Then
* (n − 1) S² / σ² has the chi-square law with n − 1 degrees of freedom, that is, the gamma
  law with shape (n − 1)/2 and rate 1/2;
* the average X̄ and the sample variance S² are independent;
* the t ratio (X̄ − μ) / (S/√n) has Student's t density with n − 1 degrees of freedom.
The unknown σ has cancelled from both laws. -/
theorem normal_sample_statistics_follow_chi_square_and_t
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (hn : 2 ≤ n) (μ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (X : Fin n → Ω → ℝ) (hind : iIndepFun X P)
    (hlaw : ∀ i, P.map (X i) = gaussianReal μ (σ ^ 2)) :
    P.map (fun ω => ((n : ℝ) - 1) * sampleVar (fun i => X i ω) / (σ : ℝ) ^ 2) =
        gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2) ∧
      IndepFun (fun ω => sampleMean (fun i => X i ω)) (fun ω => sampleVar (fun i => X i ω)) P ∧
      P.map (fun ω => (sampleMean (fun i => X i ω) - μ) /
          (√(sampleVar (fun i => X i ω)) / √(n : ℝ))) =
        volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 1) t)) := by
  have hσ' : (σ : ℝ) ≠ 0 := by positivity
  have hm : ∀ i, AEMeasurable (X i) P := fun i =>
    aemeasurable_of_map_eq (gaussianReal_singleton μ (pow_ne_zero 2 hσ.ne')) (hlaw i)
  have hvm : AEMeasurable (fun ω i => X i ω) P := AEMeasurable.of_eval hm
  have hvec : P.map (fun ω i => X i ω) =
      Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2)) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hm).1 hind]
    simp_rw [hlaw]
  set Gf : (Fin n → ℝ) → ℝ × ℝ := fun x => (√(n : ℝ) * ((sampleMean x - μ) / σ),
    (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2) with hGf
  have hGm : Measurable Gf := by fun_prop
  set W : Ω → ℝ × ℝ := fun ω => Gf (fun i => X i ω) with hWdef
  have hWm : AEMeasurable W P := hGm.comp_aemeasurable hvm
  have hW : P.map W = (gaussianReal 0 1).prod (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) := by
    rw [show W = Gf ∘ (fun ω i => X i ω) from rfl,
      ← AEMeasurable.map_map_of_aemeasurable hGm.aemeasurable hvm, hvec,
      pi_gaussian_sample_stats n hn μ hσ]
  have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have hn1 : (n : ℝ) - 1 ≠ 0 := by linarith
  have hsn : √(n : ℝ) ≠ 0 := by positivity
  have hGp : IsProbabilityMeasure (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) :=
    isProbabilityMeasure_gammaMeasure (by linarith) (by norm_num)
  have e1 : (fun ω => ((n : ℝ) - 1) * sampleVar (fun i => X i ω) / (σ : ℝ) ^ 2) =
      Prod.snd ∘ W := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf, sampleVar]
    field_simp
  have e2 : (fun ω => sampleMean (fun i => X i ω)) =
      (fun a => μ + σ / √(n : ℝ) * a) ∘ (Prod.fst ∘ W) := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf]
    field_simp
    ring
  have e3 : (fun ω => sampleVar (fun i => X i ω)) =
      (fun b => (σ : ℝ) ^ 2 / ((n : ℝ) - 1) * b) ∘ (Prod.snd ∘ W) := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf, sampleVar]
    field_simp
  have e4 : (fun ω => (sampleMean (fun i => X i ω) - μ) /
      (√(sampleVar (fun i => X i ω)) / √(n : ℝ))) =
      (fun p : ℝ × ℝ => p.1 / √(p.2 / ((n : ℝ) - 1))) ∘ W := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf, sampleVar]
    rw [div_div_eq_mul_div, div_right_comm _ ((σ : ℝ) ^ 2), sqrt_div' _ (sq_nonneg _),
      sqrt_sq (by positivity), div_div_eq_mul_div]
    field_simp
  refine ⟨?_, ?_, ?_⟩
  · rw [e1, ← AEMeasurable.map_map_of_aemeasurable measurable_snd.aemeasurable hWm, hW,
      Measure.map_snd_prod, measure_univ, one_smul]
  · rw [e2, e3]
    apply IndepFun.comp _ (by fun_prop) (by fun_prop)
    rw [indepFun_iff_map_prod_eq_prod_map_map (measurable_fst.comp_aemeasurable hWm)
      (measurable_snd.comp_aemeasurable hWm)]
    rw [show (fun ω => ((Prod.fst ∘ W) ω, (Prod.snd ∘ W) ω)) = W from rfl,
      ← AEMeasurable.map_map_of_aemeasurable measurable_fst.aemeasurable hWm,
      ← AEMeasurable.map_map_of_aemeasurable measurable_snd.aemeasurable hWm, hW,
      Measure.map_fst_prod, Measure.map_snd_prod, measure_univ, measure_univ, one_smul, one_smul]
  · rw [e4, ← AEMeasurable.map_map_of_aemeasurable (by fun_prop) hWm, hW,
      t_law (by linarith)]

/-- **Chi-square: a sum of squares.** If Z₁, …, Z_k (k ≥ 1) are independent standard normals,
then V = Z₁² + ⋯ + Z_k² has the chi-square law with k degrees of freedom: the gamma law with
shape k/2 and rate 1/2, whose density is v^(k/2−1) e^(−v/2) / (2^(k/2) Γ(k/2)) for v > 0.
Its mean is k and its variance is 2k. -/
theorem sum_of_squared_standard_normals_is_chi_square
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (k : ℕ) (hk : 0 < k) (Z : Fin k → Ω → ℝ) (hind : iIndepFun Z P)
    (hlaw : ∀ i, P.map (Z i) = gaussianReal 0 1) :
    P.map (fun ω => ∑ i, Z i ω ^ 2) = gammaMeasure ((k : ℝ) / 2) (1 / 2) ∧
      ∫ ω, (∑ i, Z i ω ^ 2) ∂P = k ∧
      variance (fun ω => ∑ i, Z i ω ^ 2) P = 2 * k := by
  have hm : ∀ i, AEMeasurable (Z i) P := fun i =>
    aemeasurable_of_map_eq (gaussianReal_singleton 0 one_ne_zero) (hlaw i)
  have hvm : AEMeasurable (fun ω i => Z i ω) P := AEMeasurable.of_eval hm
  have hvec : P.map (fun ω i => Z i ω) = Measure.pi (fun _ : Fin k => gaussianReal 0 1) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hm).1 hind]
    simp_rw [hlaw]
  have hsm : Measurable (fun x : Fin k → ℝ => ∑ i, x i ^ 2) := by fun_prop
  have hVm : AEMeasurable (fun ω => ∑ i, Z i ω ^ 2) P := hsm.comp_aemeasurable hvm
  have hV : P.map (fun ω => ∑ i, Z i ω ^ 2) = gammaMeasure ((k : ℝ) / 2) (1 / 2) := by
    rw [show (fun ω => ∑ i, Z i ω ^ 2) =
        (fun x : Fin k → ℝ => ∑ i, x i ^ 2) ∘ (fun ω i => Z i ω) from rfl,
      ← AEMeasurable.map_map_of_aemeasurable hsm.aemeasurable hvm, hvec, pi_sumsq_chi k hk]
  refine ⟨hV, ?_, ?_⟩
  · rw [show ∫ ω, (∑ i, Z i ω ^ 2) ∂P = ∫ y, y ∂(P.map (fun ω => ∑ i, Z i ω ^ 2)) from
      (integral_map hVm aestronglyMeasurable_id).symm, hV,
      gamma_mean (by positivity) (by norm_num)]
    field_simp
  · rw [show (fun ω => ∑ i, Z i ω ^ 2) = id ∘ (fun ω => ∑ i, Z i ω ^ 2) from rfl,
      ← variance_map aemeasurable_id hVm, hV, gamma_variance (by positivity) (by norm_num)]
    ring

/-- **F: a ratio of two spreads.** Take two independent normal samples: n₁ ≥ 2 measurements
X₁, …, X_{n₁} from N(μ₁, σ₁²) and n₂ ≥ 2 measurements Y₁, …, Y_{n₂} from N(μ₂, σ₂²), with
σ₁, σ₂ > 0 and all n₁ + n₂ measurements independent. Then the ratio
(S₁²/σ₁²) / (S₂²/σ₂²) of the sample variances, each divided by its true variance, has the
F density with n₁ − 1 and n₂ − 1 degrees of freedom (numerator first). -/
theorem two_normal_samples_variance_ratio_is_F
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n₁ n₂ : ℕ) (hn₁ : 2 ≤ n₁) (hn₂ : 2 ≤ n₂) (μ₁ μ₂ : ℝ) (σ₁ σ₂ : ℝ≥0)
    (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂)
    (X : Fin n₁ → Ω → ℝ) (Y : Fin n₂ → Ω → ℝ) (hind : iIndepFun (Sum.elim X Y) P)
    (hX : ∀ i, P.map (X i) = gaussianReal μ₁ (σ₁ ^ 2))
    (hY : ∀ j, P.map (Y j) = gaussianReal μ₂ (σ₂ ^ 2)) :
    P.map (fun ω => (sampleVar (fun i => X i ω) / (σ₁ : ℝ) ^ 2) /
        (sampleVar (fun j => Y j ω) / (σ₂ : ℝ) ^ 2)) =
      volume.withDensity (fun x => ENNReal.ofReal (fisherFPDF ((n₁ : ℝ) - 1) ((n₂ : ℝ) - 1) x)) := by
  have hmX : ∀ i, AEMeasurable (X i) P := fun i =>
    aemeasurable_of_map_eq (gaussianReal_singleton μ₁ (pow_ne_zero 2 hσ₁.ne')) (hX i)
  have hmY : ∀ j, AEMeasurable (Y j) P := fun j =>
    aemeasurable_of_map_eq (gaussianReal_singleton μ₂ (pow_ne_zero 2 hσ₂.ne')) (hY j)
  have hm : ∀ k, AEMeasurable (Sum.elim X Y k) P := by
    rintro (i | j)
    · exact hmX i
    · exact hmY j
  set L : Fin n₁ ⊕ Fin n₂ → Measure ℝ :=
    Sum.elim (fun _ => gaussianReal μ₁ (σ₁ ^ 2)) (fun _ => gaussianReal μ₂ (σ₂ ^ 2)) with hL
  have hLs : ∀ i, SigmaFinite (L i) := by
    rintro (i | j) <;> simp only [hL, Sum.elim_inl, Sum.elim_inr] <;> infer_instance
  have hU : P.map (fun ω k => Sum.elim X Y k ω) = Measure.pi L := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hm).1 hind]
    congr 1; ext1 k
    rcases k with i | j
    · simp [hL, hX]
    · simp [hL, hY]
  have hUm : AEMeasurable (fun ω k => Sum.elim X Y k ω) P := AEMeasurable.of_eval hm
  have hXY : P.map (fun ω => ((fun i => X i ω), (fun j => Y j ω))) =
      (Measure.pi (fun _ : Fin n₁ => gaussianReal μ₁ (σ₁ ^ 2))).prod
        (Measure.pi (fun _ : Fin n₂ => gaussianReal μ₂ (σ₂ ^ 2))) := by
    have := (measurePreserving_sumPiEquivProdPi L).map_eq
    rw [show (fun ω => ((fun i => X i ω), (fun j => Y j ω))) =
        (MeasurableEquiv.sumPiEquivProdPi (fun _ => ℝ)) ∘ (fun ω k => Sum.elim X Y k ω) from rfl,
      ← AEMeasurable.map_map_of_aemeasurable (MeasurableEquiv.measurable _).aemeasurable hUm, hU,
      this]
    rfl
  have hXYm : AEMeasurable (fun ω => ((fun i => X i ω), (fun j => Y j ω))) P :=
    (AEMeasurable.of_eval hmX).prodMk (AEMeasurable.of_eval hmY)
  set h₁ : (Fin n₁ → ℝ) → ℝ := fun x => (∑ i, (x i - sampleMean x) ^ 2) / (σ₁ : ℝ) ^ 2
  set h₂ : (Fin n₂ → ℝ) → ℝ := fun x => (∑ i, (x i - sampleMean x) ^ 2) / (σ₂ : ℝ) ^ 2
  have hh₁ : Measurable h₁ := by fun_prop
  have hh₂ : Measurable h₂ := by fun_prop
  have hF : (fun ω => (sampleVar (fun i => X i ω) / (σ₁ : ℝ) ^ 2) /
        (sampleVar (fun j => Y j ω) / (σ₂ : ℝ) ^ 2)) =
      (fun p : ℝ × ℝ => (p.1 / ((n₁ : ℝ) - 1)) / (p.2 / ((n₂ : ℝ) - 1))) ∘ Prod.map h₁ h₂ ∘
        (fun ω => ((fun i => X i ω), (fun j => Y j ω))) := by
    ext ω
    simp only [Function.comp_apply, Prod.map, h₁, h₂, sampleVar]
    ring
  have h1 : (0 : ℝ) < (n₁ : ℝ) - 1 := by
    have : (2 : ℝ) ≤ n₁ := by exact_mod_cast hn₁
    linarith
  have h2 : (0 : ℝ) < (n₂ : ℝ) - 1 := by
    have : (2 : ℝ) ≤ n₂ := by exact_mod_cast hn₂
    linarith
  rw [hF, ← AEMeasurable.map_map_of_aemeasurable (by fun_prop)
      ((hh₁.prodMap hh₂).comp_aemeasurable hXYm),
    ← AEMeasurable.map_map_of_aemeasurable (hh₁.prodMap hh₂).aemeasurable hXYm, hXY,
    ← Measure.map_prod_map _ _ hh₁ hh₂, pi_gaussian_sumsq_law n₁ hn₁ μ₁ hσ₁,
    pi_gaussian_sumsq_law n₂ hn₂ μ₂ hσ₂, f_law h1 h2]

-- The ten bags from machine one: average 502 grams.
example : sampleMean (![507, 498, 505, 500, 503, 502, 501, 497, 505, 502] : Fin 10 → ℝ) = 502 := by
  norm_num [sampleMean, Fin.sum_univ_succ]

-- Their residuals from 502 add to 0, and the squared residuals add to 90.
example : (507 - 502 : ℤ) + (498 - 502) + (505 - 502) + (500 - 502) + (503 - 502) + (502 - 502) +
    (501 - 502) + (497 - 502) + (505 - 502) + (502 - 502) = 0 := by
  decide

example : (507 - 502 : ℤ) ^ 2 + (498 - 502) ^ 2 + (505 - 502) ^ 2 + (500 - 502) ^ 2 +
    (503 - 502) ^ 2 + (502 - 502) ^ 2 + (501 - 502) ^ 2 + (497 - 502) ^ 2 + (505 - 502) ^ 2 +
    (502 - 502) ^ 2 = 90 := by
  decide

-- Sample variance S² = 90 / 9 = 10.
example : sampleVar (![507, 498, 505, 500, 503, 502, 501, 497, 505, 502] : Fin 10 → ℝ) = 10 := by
  norm_num [sampleVar, sampleMean, Fin.sum_univ_succ]

-- The seven bags from machine two: average 500, squared residuals 24, S² = 24 / 6 = 4.
example : sampleMean (![503, 498, 501, 498, 502, 499, 499] : Fin 7 → ℝ) = 500 := by
  norm_num [sampleMean, Fin.sum_univ_succ]

example : sampleVar (![503, 498, 501, 498, 502, 499, 499] : Fin 7 → ℝ) = 4 := by
  norm_num [sampleVar, sampleMean, Fin.sum_univ_succ]

-- The t ratio: (502 − 500) / (√10 / √10) = 2 on 9 degrees.
example : ((502 : ℝ) - 500) / (√10 / √10) = 2 := by
  have h : (√(10 : ℝ)) ≠ 0 := by positivity
  rw [div_self h]; norm_num

-- Testing σ = 3: V = 9 × 10 / 3² = 10 on 9 degrees.
example : (9 : ℚ) * 10 / 3 ^ 2 = 10 := by norm_num

-- The F ratio 10 / 4 = 2.5 on (9, 6), with c = 9/6 = 1.5.
example : (10 : ℚ) / 4 = 5 / 2 ∧ (9 : ℚ) / 6 = 3 / 2 := by norm_num

-- Nine squares: mean 9, variance 2 × 9 = 18; Var(T) = 9/7 on 9 degrees; E[F] = 6/(6 − 2) = 3/2.
example : 2 * 9 = 18 ∧ (9 : ℚ) / (9 - 2) = 9 / 7 ∧ (6 : ℚ) / (6 - 2) = 3 / 2 := by norm_num

#print axioms normal_sample_statistics_follow_chi_square_and_t
#print axioms sum_of_squared_standard_normals_is_chi_square
#print axioms two_normal_samples_variance_ratio_is_F
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'lintegral_rpow_exp_Ioi' depends on axioms: [propext, Classical.choice, Quot.sound]
'lintegral_comp_mul_left'' depends on axioms: [propext, Classical.choice, Quot.sound]
'lintegral_eq_ofReal_mul_comp' depends on axioms: [propext, Classical.choice, Quot.sound]
'gamma_beta_identity' depends on axioms: [propext, Classical.choice, Quot.sound]
'gamma_conv_density' depends on axioms: [propext, Classical.choice, Quot.sound]
'measurable_gammaPDF'' depends on axioms: [propext, Classical.choice, Quot.sound]
'map_prod_withDensity_apply' depends on axioms: [propext, Classical.choice, Quot.sound]
'gamma_conv' depends on axioms: [propext, Classical.choice, Quot.sound]
'sFinite_gammaMeasure' depends on axioms: [propext, Classical.choice, Quot.sound]
'sq_density_identity' depends on axioms: [propext, Classical.choice, Quot.sound]
'gaussianPDF_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
'image_sq_Ioi' depends on axioms: [propext, Classical.choice, Quot.sound]
'gaussian_map_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_sumsq_step' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_sumsq_chi'' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_sumsq_chi' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_head_rest' depends on axioms: [propext, Classical.choice, Quot.sound]
'measurable_sampleMean' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_sq_sub_mean' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_sample_stats' depends on axioms: [propext, Classical.choice, Quot.sound]
't_pointwise' depends on axioms: [propext, Classical.choice, Quot.sound]
't_const' depends on axioms: [propext, Classical.choice, Quot.sound]
't_density_at' depends on axioms: [propext, Classical.choice, Quot.sound]
't_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'f_pointwise' depends on axioms: [propext, Classical.choice, Quot.sound]
'f_const' depends on axioms: [propext, Classical.choice, Quot.sound]
'f_density_at' depends on axioms: [propext, Classical.choice, Quot.sound]
'f_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'gamma_moment_fun' depends on axioms: [propext, Classical.choice, Quot.sound]
'gamma_moment' depends on axioms: [propext, Classical.choice, Quot.sound]
'gamma_mean' depends on axioms: [propext, Classical.choice, Quot.sound]
'gamma_variance' depends on axioms: [propext, Classical.choice, Quot.sound]
'gaussianReal_singleton' depends on axioms: [propext, Classical.choice, Quot.sound]
'aemeasurable_of_map_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'gaussian_standardize' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_gaussian_standardize' depends on axioms: [propext, Classical.choice, Quot.sound]
'sampleMean_standardize' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_gaussian_sample_stats' depends on axioms: [propext, Classical.choice, Quot.sound]
'pi_gaussian_sumsq_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'normal_sample_statistics_follow_chi_square_and_t' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_of_squared_standard_normals_is_chi_square' depends on axioms: [propext, Classical.choice, Quot.sound]
'two_normal_samples_variance_ratio_is_F' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Two bags instead of ten.** Call `t_tail2(2.0, 1)`: the t law with 1 degree is Cauchy, and the chance of a gap past 2 jumps from 0.0766 to 0.2952.
> - **Normal bags in the skewed round.** Replace the exponential weights with `LABEL + SIGMA * z` for ten fresh normals: the chi-square rejection rate falls from 0.1203, and the t test's from 0.0998, to about the 5 percent each test promises, and the assert that skewed bags break the 5 percent promise stops the program.
> - **Divide by n.** Change `(len(xs) - 1)` to `len(xs)` in `summary`: the ten-bag variances shrink by a tenth and the seven-bag ones by a seventh, the simulated chi-square mean falls below 9, and an assert stops the run.
> - **Move the F threshold.** Call `f_tail(4.099, 9, 6)`: it returns about 0.0500, since 4.099 is the printed 5 percent cutoff.

---

## The usual mistake

> [!warning]
> **Plugging the sample's spread into a normal table.** S is a guess, and a small guess inflates the ratio. With ten bags, the normal cutoff 1.96 rejects a correct label 8.16 percent of the time instead of 5, and the gap of 2.000 standard errors looks like a 0.0455 event when it is a 0.0766 event. Use t with n − 1 degrees whenever the spread comes from the same data.
>
> - **Counting n degrees of freedom, not n − 1.** P(V > 10) comes out 0.4405 instead of 0.3505.
> - **Swapping the F degrees.** Reading 2.5 on F(6, 9) gives 0.1047; the ratio was variance of ten bags over variance of seven, so F(9, 6) and 0.1385.
> - **Trusting the chi-square law for skewed data.** A 5 percent test of the spread rejects 12.03 percent of the time with exponential-shaped bags.
> - **Reading 0.0766 as the chance the label is right.** It is the chance of a gap this large if the label is right.

---

## Where you meet it in real life

- **Quality control.** A sample from a production line, a t ratio against the label, and a decision: [t-tests](../08-Confidence%20Intervals%20and%20Tests/05-t-tests-and-comparing-means.md).
- **Laboratory measurement.** Five or ten repeat readings of one quantity give an interval of average ± t cutoff × S/√n: [Confidence intervals](../08-Confidence%20Intervals%20and%20Tests/01-confidence-intervals.md).
- **Comparing spreads and groups.** Two instruments' precision, or several fertilisers' yields, are compared by F ratios; analysis of variance is built on them.
- **Finance.** Returns with heavy tails are often modelled with the t law, and dependence between defaults with the t copula: [Tail dependence](../../12-Financial%20mathematics/45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/07-tail-dependence-and-the-t-copula.md).

> **Say it back**
> Chi-square is a sum of independent squared standard normals, the gamma law with shape half the count. For a normal sample the squared residuals over σ^2 are chi-square with n − 1 degrees, and independent of the average. Dividing the standardised gap by the estimated spread cancels σ and gives Student's t, whose tails are heavier because the estimate wobbles. Dividing two independent sample variances gives F, a beta variable in disguise. Ten bags 2 standard errors from the label: 0.0766 by t, not 0.0455 by the normal.

---

## What this builds on

- [Standard error](02-sample-mean-and-standard-error.md): the standard error σ/√n, and the sample standard deviation that replaces σ.
- [Gamma and beta](../04-Continuous%20Distributions/07-gamma-and-beta-distributions.md): the gamma law and integral, Γ(1/2) = √π, gamma totals adding shapes, and the beta share behind F.

## Where this goes next

- [Confidence intervals](../08-Confidence%20Intervals%20and%20Tests/01-confidence-intervals.md): turning the t law into an interval for the machine's mean, and saying what 95 percent is a statement about.
- [t-tests](../08-Confidence%20Intervals%20and%20Tests/05-t-tests-and-comparing-means.md): the t ratio as a test, for one sample, two samples and paired data.
- [Chi-square tests](../08-Confidence%20Intervals%20and%20Tests/06-chi-square-tests.md): the chi-square law as the reference for counts in a table, against a model or between rows.
- [Tail dependence](../../12-Financial%20mathematics/45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/07-tail-dependence-and-the-t-copula.md): the t law's heavy tails used to make joint crashes more likely than a normal model allows.

These laws say how far a statistic strays when the model is true; how to turn that into a statement about the unknown mean, with a stated rate of being wrong, is [Confidence intervals](../08-Confidence%20Intervals%20and%20Tests/01-confidence-intervals.md).

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Student (W. S. Gosset). "The Probable Error of a Mean." *Biometrika* 6(1), 1908, 1–25. [DOI](https://doi.org/10.2307/2331554). The t law found for small samples of unknown spread.
- Casella, George, and Roger L. Berger. *Statistical Inference*, 2nd ed. Routledge. [Publisher page](https://www.routledge.com/Statistical-Inference/Casella-Berger/p/book/9781032593036). Chapter 5: the sample-variance theorem, and the t and F laws derived from it.
- Wasserman, Larry. *All of Statistics*. Springer, 2004. [Publisher page](https://link.springer.com/book/10.1007/978-0-387-21736-9). Concise definitions of chi-square, t and F and their use in tests.
- NIST Digital Library of Mathematical Functions, §8.4. [Special values of the incomplete gamma functions](https://dlmf.nist.gov/8.4). The Poisson sum and the normal-plus-finite-sum forms used for chi-square tails.
- NIST Digital Library of Mathematical Functions, §8.17. [Incomplete beta functions](https://dlmf.nist.gov/8.17). The beta tail behind every F probability.
