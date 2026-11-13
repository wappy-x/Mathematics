# Novikov: when the exponential martingale is a true martingale

[Syllabus](../../../SYLLABUS.md) → [Stochastic processes and calculus](../README.md) → [Changing Measure](../README.md#s07) → Novikov

---

## General Overview

A share drifts up 8 percent a year with volatility 20 percent. A trader prices it as if it drifted 5 percent. Girsanov's theorem ([Girsanov](02-girsanov-theorem.md)) builds the trader's world by giving every possible path of the share a weight, a positive number, and averaging with the weights. Paths that rose a lot get light weights; paths that fell get heavy ones. The real-world drift of 8 percent becomes 5 percent under the weighted average, and the volatility stays 20 percent.

That only works if the weights average exactly 1. Weights are chances in disguise: a weighted world whose chances add up to 0.68 is not a world. For the share, the weights do average 1, and the check is one line.

Now let the tilt that sets the weights grow as the path goes. Grow it slowly and nothing goes wrong. Grow it fast enough, so that the extra drift it adds feeds on itself, and the weights average 0.682689 after one year.

About 32 percent of the probability has leaked away. The leak rides on ever rarer paths whose weights climb ever higher, and vanishes with them.

Novikov's condition is the standard test that rules the leak out. Take half the accumulated squared tilt, raise e to that power, and average over all paths. If that average is finite, the weights average 1 and Girsanov applies. It is a sufficient test, not a necessary one: a tilt can fail it and still be safe.

**The candidate weights of Girsanov always average at most 1, and they average exactly 1 whenever the average of e to the half the accumulated squared tilt is finite; a tilt that feeds on the weight itself breaks this, and the missing mass is the chance that the weighted world blows up.**

**What kind of fact this is:** a theorem, proved on this card in Why it works (the full proof is in a folded callout), together with an exact counterexample proved on the card.

### The picture: how much weight survives

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Average weight at the horizon, by horizon"
    x-axis "Horizon T (years)" [0.25, 0.5, 1, 2, 4, 8]
    y-axis "Average of the weights" 0 --> 1.1
    line [0.95, 0.84, 0.68, 0.52, 0.38, 0.28]
    line [1.00, 1.00, 1.00, 1.00, 1.00, 1.00]
```

The falling line is tilt C below, the tilt that feeds on the weight: its weights average $2\Phi(1/\sqrt{T}) - 1$, which is 0.68 at one year and keeps falling. The flat line at 1 is the share's constant tilt, and also tilt B, which grows with the path and still loses nothing. Both lines come from the closed forms printed by the code; the falling one is confirmed at one year by an exact lattice walk and by a simulation.

---

## The formula

Notation first, with one-line reminders. Time $t$ is in years and runs to a horizon $T$. A measure is a rule that gives each set of paths its chance. $W_t$ is Brownian motion under the real-world measure $P$, and $E$ averages under $P$. Brownian motion is a continuous random path whose move over any h years is normal with mean 0 and variance h ([Brownian motion](../05-Brownian%20Motion/01-brownian-motion.md)). A second measure $Q$, with averages $E^Q$, is the reweighted world of [Changing the measure](01-change-of-measure-and-density-processes.md).

The filtration $\mathcal{F}_t$ is what is known by time t. A martingale is a process whose average later value, given what is known now, equals its present value: a fair game ([Martingales](../02-Martingales/01-martingales.md)). The tilt $\theta_t$ is any amount chosen using only what is known by time t. Its weight process is

$$Z_t = \exp\!\Big(-\int_0^t \theta_s\,dW_s - \tfrac12\int_0^t \theta_s^2\,ds\Big), \qquad dZ_t = -\theta_t Z_t\,dW_t, \qquad Z_0 = 1.$$

Here $dW_t$ is shorthand for an Ito integral, never a derivative, because the path has none. An Ito integral is the limit of sums of the path's small moves, each times an amount fixed before the move ([The Ito integral](../06-Ito%20Calculus/01-ito-integral.md)). Girsanov sets $Q(A) = E[Z_T\,1_A]$ for each event A, where $1_A$ is 1 on the paths in A and 0 elsewhere. Under Q, $\widetilde W_t = W_t + \int_0^t \theta_s\,ds$ is a Brownian motion. **Novikov's condition:**

$$E\Big[\exp\!\Big(\tfrac12\int_0^T \theta_t^2\,dt\Big)\Big] < \infty \quad\Longrightarrow\quad E[Z_T] = 1, \text{ and } (Z_t) \text{ is a martingale on } [0, T].$$

**Read it aloud:** if e to the half the total squared tilt has a finite average, then the weights average exactly one, so Q is a genuine probability and Girsanov's theorem holds.

Without the condition only the inequality survives: $E[Z_T] \le 1$ always. The three tilts on this card:

| Tilt | $\theta_t$ | Novikov average, $T = 1$ | $E[Z_T]$ |
| --- | --- | --- | --- |
| A, the share | $(\mu - r)/\sigma = 0.15$ | 1.011314 | 1 |
| B, grows with the wander | $c\,W_t$, with $c = 1$ per year | 1.360447 (infinite from $T = \pi/2$) | 1 for every T |
| C, feeds on the weight | $-Z_t$, so $dZ_t = Z_t^2\,dW_t$ | infinite | $2\Phi(1/\sqrt{T}) - 1 = 0.682689$ |

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $W_t$, $\widetilde W_t$, $dW_t$ | Brownian motion under P; the shifted process that is Brownian under Q; shorthand inside an Ito integral | — | — |
| $t$, $s$, $T$ | times in years, s the earlier; T the horizon | T = 1 year, and 2 years for tilt B | C: the weights average less |
| $P$, $Q$, $Q_n$, $E$, $E^Q$, $1_A$ | the real-world measure, the reweighted one, and the reweighted one with the weight capped at n; averages; 1 on event A, else 0 | — | — |
| $\theta_t$ | the tilt, in units per square-root year: how hard the weights lean | 0.15; $W_t$; $-Z_t$ | the Novikov average rises |
| $Z_t$, $Z_T$, $Z_0$ | the weight process, the candidate density $dQ/dP$ seen at time t; its start | starts at 1 | — |
| $\mu$, $r$, $\sigma$ | the share's drift, the pricing drift, its volatility | 0.08, 0.05, 0.20 | $\mu$ up: tilt A up |
| $c$ | how fast tilt B grows with the path, per year | 1 | the Novikov horizon $\pi/(2c)$ shrinks |
| $\Phi$ | the standard normal cumulative distribution function | $\Phi(1) = 0.841345$ | — |
| $R_t$, $R_0$ | the reciprocal $1/Z_t$ under tilt C, and its start | starts at 1 | $R_0$ up: less leaks |
| $\tau_n$, $n$ | a cap time: in Step 1 when the running total of $\theta^2Z^2$ reaches n; under tilt C when the weight reaches the cap n | caps 10, 100, 1000 | fewer paths reach the cap |
| $M_t$, $\lambda$ | in the proof: $M_t = -\int_0^t\theta_s\,dW_s$, and a number between 0 and 1 | — | — |
| $h$ | the step of the lattice walk in the code | 0.1 down to 0.025 | the lattice error grows |

### When it holds

- **The tilt is chosen from the past.** $\theta_t$ may use the path up to t and nothing later. A tilt that peeks ahead makes the Ito integral meaningless and the theorem says nothing.
- **The tilt's total square is finite on every path.** Novikov's average needs $\int_0^T \theta_t^2\,dt$ to be finite; tilt A gives 0.0225 per year of horizon, tilt B gives $\int_0^T W_t^2\,dt$, finite on every path.
- **The average is finite, not merely each value.** Tilt B's total square is finite on every path, yet past $T = \pi/2 = 1.570796$ years its exponential has an infinite average. The test fails there while the weights still average 1: Novikov is sufficient, not necessary.
- **One fixed horizon.** The condition is checked on $[0, T]$ and certifies only that interval. On an infinite horizon a constant tilt passes every finite-T test, yet the weights tend to 0 along almost every path, and Q and P disagree completely about the far future.

---

## Why it works

### Step 0: fair over each instant is not fair over the year

The weight has no dt term: over each short step its average change is zero. A fair game in small steps adds up to a fair game over the year only if no average escapes along the way. Average can escape into rare paths whose weights run off to infinity, the way a lottery's tiny chance of a huge prize carries real value. Every step below is about whether that escape route is open.

### Step 1: the weight is fair up to any cap

For each n let $\tau_n$ be the first time the running total $\int_0^t \theta_s^2 Z_s^2\,ds$ reaches n (or T if it never does). Stopped there, the Ito integral $Z_{t \wedge \tau_n} - 1 = -\int_0^{t\wedge\tau_n}\theta_s Z_s\,dW_s$ has a finite second moment (its square has a finite average), so it is a true martingale ([The Ito integral](../06-Ito%20Calculus/01-ito-integral.md)). Here $t \wedge \tau_n$ means whichever comes first. So $E[Z_{t\wedge\tau_n}] = 1$ for every n. A process that is a martingale once stopped at such a sequence of times, rising to the end, is called a **local martingale**.

### Step 2: the weights average at most 1

$Z$ is positive. As n grows, $Z_{t\wedge\tau_n}$ tends to $Z_t$ on every path. Fatou's lemma (wing 10: the average of a limit of positive variables is at most the limit of the averages) gives, for s before t,

$$E[Z_t \mid \mathcal{F}_s] \le \liminf_{n} E[Z_{t\wedge\tau_n} \mid \mathcal{F}_s] = Z_s.$$

Here $E[Z_t \mid \mathcal{F}_s]$ is the average of $Z_t$ given what is known by time s, and $\liminf_n$ is the smallest value the sequence approaches as n grows.

So Z is a **supermartingale**: its forecast never exceeds its present value. In particular $E[Z_T] \le 1$. Equality forces the full martingale property: $Z_s - E[Z_T \mid \mathcal{F}_s]$ is never negative and averages $E[Z_s] - 1 \le 0$, so it is zero. The whole question is whether Fatou's inequality is strict.

### Step 3: Girsanov needs the equality

$Q(\text{all paths}) = E[Z_T]$. If that is 0.68, Q is not a probability. Rescaling by 1/0.68 restores a total of 1, but Girsanov's proof uses $E[Z_t \mid \mathcal{F}_s] = Z_s$ to compute every conditional Q-average, and that identity is now false. Under the rescaled measure $\widetilde W$ is not a Brownian motion. A price computed under such a Q is not a price.

### Step 4: Novikov's test closes the escape route

Write $M_t = -\int_0^t \theta_s\,dW_s$, so $Z_t = e^{M_t - \frac12\int_0^t\theta_s^2 ds}$. The proof splits $e^{M/2}$ into the square root of the weight times $e^{\frac14\int\theta^2}$. Cauchy-Schwarz then bounds the average of $e^{M/2}$ at every stopping time (a random time decided by the path so far, as in [Stopping times](../02-Martingales/03-stopping-times-and-optional-stopping.md)) by the square root of Novikov's average. That bound makes slightly smaller exponential martingales, with the tilt scaled by a number $\lambda$ below 1, uniformly integrable (wing 10: no average can escape to large values), hence true martingales. Hölder's inequality transfers their average of 1 back to $Z$ as $\lambda$ rises to 1.

<details>
<summary>Detailed proof</summary>

Let $K = E[\exp(\tfrac12\int_0^T\theta_t^2dt)] < \infty$ and write $A_t = \int_0^t\theta_s^2ds$, so $Z = e^{M - A/2}$.

1. **A bound at every stopping time.** For a stopping time $\rho \le T$, $e^{M_\rho/2} = Z_\rho^{1/2}\,e^{A_\rho/4}$. By Cauchy-Schwarz, $E[e^{M_\rho/2}] \le E[Z_\rho]^{1/2}E[e^{A_\rho/2}]^{1/2} \le \sqrt{K}$, using $E[Z_\rho] \le 1$ (optional stopping for the positive supermartingale Z at a bounded time).
2. **A smaller tilt.** Fix $0 < \lambda < 1$ and let $Z^{(\lambda)} = e^{\lambda M - \lambda^2 A/2}$, the weight for the tilt $\lambda\theta$; it is a positive local martingale by Step 1. Check the algebra: $Z^{(\lambda)} = Z^{\lambda^2}\,e^{\lambda(1-\lambda)M}$.
3. **Hölder with exponents $1/\lambda^2$ and $1/(1-\lambda^2)$.** For any event B, $E[Z^{(\lambda)}_\rho 1_B] \le E[Z_\rho]^{\lambda^2}\,E[1_B e^{\gamma M_\rho}]^{1-\lambda^2}$ with $\gamma = \lambda(1-\lambda)/(1-\lambda^2) = \lambda/(1+\lambda) < \tfrac12$.
4. **Uniform integrability.** By Hölder again, $E[1_B e^{\gamma M_\rho}] \le P(B)^{1-2\gamma}\,E[e^{M_\rho/2}]^{2\gamma} \le P(B)^{1-2\gamma}K^{\gamma}$. This is small whenever $P(B)$ is small, uniformly over $\rho \le T$. So the stopped values $Z^{(\lambda)}_\rho$ are uniformly integrable, and the limit $n \to \infty$ in $E[Z^{(\lambda)}_{t\wedge\tau_n}\mid\mathcal{F}_s] = Z^{(\lambda)}_{s\wedge\tau_n}$ passes through the average (wing 10, Vitali). $Z^{(\lambda)}$ is a true martingale and $E[Z^{(\lambda)}_T] = 1$.
5. **Let $\lambda$ rise to 1.** Point 3 with B = all paths and $\rho = T$, then point 4's bound with $P(B) = 1$: $1 \le E[Z_T]^{\lambda^2}K^{\gamma(1-\lambda^2)} = E[Z_T]^{\lambda^2}K^{\lambda(1-\lambda)}$. As $\lambda \to 1$ the second factor tends to 1, so $E[Z_T] \ge 1$. Step 2 gave $\le 1$. Hence $E[Z_T] = 1$.

The proof used only the bound in step 1, on $\sup_\rho E[e^{M_\rho/2}]$. That weaker hypothesis is Kazamaki's condition. Revuz and Yor, chapter VIII, give this argument; Karatzas and Shreve, section 3.5, give another.

</details>

Tilt A passes at once. A constant tilt gives $\int_0^T\theta^2dt = \theta^2T$, a plain number, and Novikov's average is $e^{\theta^2T/2} = e^{0.01125} = 1.011314$. The share's weighted world exists, and under it the drift is $\mu - \sigma\theta = 0.05$.

### Step 5: a tilt that feeds on the weight leaks exactly $2 - 2\Phi(1/\sqrt{T})$

Take $\theta_t = -Z_t$, so $dZ_t = Z_t^2\,dW_t$. Under the would-be Q, W gains the drift $+Z_t$, and the weight's own equation becomes $dZ_t = Z_t^3\,dt + Z_t^2\,d\widetilde W_t$. Drop the noise and $dy = y^3dt$ from 1 gives $y = 1/\sqrt{1 - 2t}$, which blows up at 0.50 years. The drift grows too fast. The noise does not save it.

The reciprocal makes it exact. Ito's lemma ([Ito's lemma](../06-Ito%20Calculus/02-itos-lemma.md)) with $f(z) = 1/z$, $f'(z) = -1/z^2$, $f''(z) = 2/z^3$:

$$dR_t = -\frac{dZ_t}{Z_t^2} + \frac{(dZ_t)^2}{Z_t^3} = -dW_t + Z_t\,dt = -\big(dW_t - Z_t\,dt\big) = -d\widetilde W_t.$$

Under Q, $R_t = 1/Z_t$ is a Brownian motion started at 1. Brownian motion from 1 reaches 0 at some finite time, and at that moment Z is infinite. The leak is the Q-chance of reaching 0 by T. Made rigorous with caps:

1. **Cap the weight.** Let $\tau_n$ be the first time $Z_t = n$. The stopped weight lies between 0 and n, so its tilt is bounded and Novikov holds: $Q_n(A) = E[Z_{T\wedge\tau_n}1_A]$ is a probability.
2. **Under the capped measure, R is Brownian.** By Girsanov under $Q_n$, $\widetilde W$ is Brownian until $\tau_n$, so R is a Brownian motion from 1 until it reaches $1/n$.
3. **Reflection.** By [Reflection principle](../05-Brownian%20Motion/04-reflection-principle-and-running-maximum.md), a Brownian motion from 1 stays above $1/n$ through T with chance $2\Phi((1 - 1/n)/\sqrt{T}) - 1$.
4. **Split the average of 1.** $1 = E[Z_{T\wedge\tau_n}] = E[Z_T\,1_{\{\tau_n > T\}}] + n\,P(\tau_n \le T)$. The first term is $Q_n(\tau_n > T)$, the chance in point 3.
5. **Let the cap rise.** The second term tends to $2 - 2\Phi(1/\sqrt{T})$, which stays positive, so $P(\tau_n \le T)$ falls like $1/n$: under P the weight never blows up. Monotone convergence (wing 10: when positive variables rise to a limit, their averages rise to the limit's average) gives $E[Z_T] = 2\Phi(1/\sqrt{T}) - 1$.

At one year: $2\Phi(1) - 1 = 0.682689$, and 0.317311 has leaked.

Point 4 shows where it went. With a cap of 100, mass 0.322174 rides on paths that hit the cap, and those paths have chance only 0.003222. With a cap of 1000 the mass is 0.317795 on a chance of 0.000318.

The mass stays near 0.32 while the paths carrying it thin out to nothing. In the limit the paths are gone and the mass with them. By Novikov's own theorem, read backwards, $E[\exp(\tfrac12\int_0^1 Z_t^2\,dt)]$ must be infinite.

<details>
<summary>Another way to see the same weight</summary>

Under P, R has $dR_t = -dW_t + dt/R_t$: a Brownian motion pushed away from 0 by a force of size 1/R. That is the law of the distance from the origin of a three-dimensional Brownian motion started at distance 1, a Bessel process (Revuz and Yor, chapter XI). A three-dimensional Brownian motion started away from the origin never hits it, so R stays positive and Z stays finite. The code uses this fact as its second road: $Z_1 = 1/|(1,0,0) + G|$, with G three independent standard normals.

</details>

### Step 6: a tilt that grows with the wander fails the test and stays safe

Take $\theta_t = c\,W_t$ with $c = 1$ per year. Under Q, $dW_t = -cW_t\,dt + d\widetilde W_t$: W is pulled back toward 0, an Ornstein-Uhlenbeck process ([Mean reversion](../06-Ito%20Calculus/05-ornstein-uhlenbeck-and-cir-processes.md)), which never blows up. Ito's lemma gives $\int_0^T W_t\,dW_t = \tfrac12(W_T^2 - T)$, so

$$Z_T = \exp\!\Big(\tfrac{c}{2}T - \tfrac{c}{2}W_T^2 - \tfrac{c^2}{2}\int_0^T W_t^2\,dt\Big).$$

A classical formula of Cameron and Martin gives $E[e^{-aW_T^2 - b\int_0^T W_t^2dt}] = (\cosh\kappa T + \tfrac{2a}{\kappa}\sinh\kappa T)^{-1/2}$ with $\kappa = \sqrt{2b}$. Here cosh and sinh are the hyperbolic cosine and sine, $(e^x + e^{-x})/2$ and $(e^x - e^{-x})/2$.

With $a = c/2$, $b = c^2/2$, the bracket is $e^{cT}$, and $E[Z_T] = e^{cT/2}e^{-cT/2} = 1$ for every T. With $a = 0$ and $b = -c^2/2$ the same formula, with cosh turned into cos, gives Novikov's average $1/\sqrt{\cos cT}$, finite only while $cT < \pi/2$. This card states the formula with its source and checks it by an exact Gaussian computation on a grid, which the code prints converging.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Tilt B: Novikov's average runs off, the weights stay at 1"
    x-axis "Horizon T (years)" [0.25, 0.5, 0.75, 1, 1.25, 1.5]
    y-axis "Average" 0 --> 4
    line [1.02, 1.07, 1.17, 1.36, 1.78, 3.76]
    line [1.00, 1.00, 1.00, 1.00, 1.00, 1.00]
```

The rising line is Novikov's average $1/\sqrt{\cos T}$, which is infinite from $T = \pi/2 = 1.570796$ years. The flat line is $E[Z_T] = 1$, from the Cameron-Martin formula on the code's `chart, B E[Z_T]` row. The test is a sufficient condition with room to spare. A different sufficient test, Beneš's condition (Karatzas and Shreve, section 3.5), accepts any tilt read off the path of W itself that grows at most in proportion to the path's size. Tilt B passes it at every horizon. Neither test implies the other.

### The other door

A direct route skips the general theorem: find the Q-dynamics, check they do not blow up, and conclude that Z is a martingale. That is what Steps 5 and 6 did. It is the test practitioners run on stochastic volatility models, where the tilt depends on the state and Novikov's average is often infinite.

---

## Worked numbers, by hand

The share and the leaking tilt, over T = 1 year.

| Step | Arithmetic | Value |
| --- | --- | --- |
| tilt A, the share | (0.08 − 0.05) / 0.20 | 0.15 |
| its square | 0.15 × 0.15 | 0.0225 |
| half the total squared tilt | 0.0225 × 1 / 2 | 0.01125 |
| Novikov's average | $e^{0.01125}$ | 1.011314, finite: Girsanov applies |
| drift under Q | 0.08 − 0.20 × 0.15 | 0.05 |
| tilt B's horizon | $\pi/2$ with c = 1 | 1.570796 years |
| tilt B's Novikov average at 1 year | $1/\sqrt{\cos 1} = 1/\sqrt{0.540302}$ | 1.360447 |
| tilt C: $\Phi(1/\sqrt{1})$ | table or series | 0.841345 |
| **tilt C: average weight** | 2 × 0.841345 − 1 | **0.682689** |
| leaked mass | 1 − 0.682689 | 0.317311 |

Under tilt C, a market built on these weights would price a sure dollar at one year at about 68 cents before discounting. The other 32 cents ride on ever rarer paths as the cap rises, and vanish with them.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Treat a positive local martingale as a martingale (tilt C) | $E[Z_1] = 1$ claimed; it is 0.682689 | no dt term means fair over each instant, not over the year |
| Read Novikov as necessary (tilt B at T = 2) | "no change of measure" claimed; the grid gives $E[Z_2]$ = 0.999847 at n = 1600, and 1 in the limit | the test is sufficient only |
| Check the condition on a shorter horizon | tilt B passes at T = 1.5 (3.759898), fails at T = 1.6 | the certificate covers $[0, T]$ only |
| Cap the weight and declare victory (tilt C, cap 100) | the capped weight averages 1, but 0.322174 of it sits on paths of chance 0.003222 | the cap hides the leak; lifting it loses the mass |

---

## Code, from first principles, and it actually runs

The code takes three roads for tilts B and C, and two for the share.

- **Road 1** is the closed forms, with the normal distribution built from its Taylor series.
- **Road 2** is exact arithmetic on a grid. For tilt B, it computes the averages of Gaussian exponentials as determinants of a tridiagonal matrix (the grid path's inverse covariance) at four step counts, and scans T in steps of 0.01 for where Novikov's average first turns infinite. For tilt C, a lattice walk of steps h every $h^2$ years from 1, absorbed at 0, is solved exactly by stepping its probabilities forward at three step sizes.
- **Road 3** is a seeded simulation with SplitMix64 (a simple random number generator) and Box-Muller (a recipe that turns uniform draws into normal ones) written out, seed 20260930, each average printed with its standard error.

Tilt B's simulation runs on a grid of 200 steps over 2 years and is compared with the exact mean on that same grid. Tilt C's simulation needs no grid: it uses the three-dimensional fact in the fold under Step 5, which is independent of the reflection argument it checks.

### Python

```python
# Novikov's condition -- the check behind the card.  Standard library only.
# Three tilts theta_t for Girsanov, time in years, W_t a Brownian motion under P:
#   A  constant 0.15: the share drifting 8% a year, priced at 5%, volatility 20%
#   B  theta_t = c W_t, c = 1 per year: the tilt grows with the wander
#   C  theta_t = -Z_t: the tilt grows with the weight itself, so dZ = Z^2 dW
# Roads: closed forms; exact Gaussian determinants and an exact lattice walk on
# shrinking grids; seeded simulation (SplitMix64 + Box-Muller) with standard errors.
from math import sqrt, exp, log, cos, sin, cosh, sinh, pi

def erf(x):                                   # Taylor series, accurate for |x| <= 3
    term, total, n = x, x, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -x * x / n
        total += term / (2 * n + 1)
    return 2.0 / sqrt(pi) * total

class Rng:                                    # SplitMix64 uniforms, Box-Muller normals
    def __init__(self, seed): self.s, self.spare = seed, None
    def u(self):
        M = (1 << 64) - 1
        self.s = (self.s + 0x9E3779B97F4A7C15) & M
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def normal(self):
        if self.spare is not None:
            g, self.spare = self.spare, None
            return g
        r, a = sqrt(-2.0 * log(1.0 - self.u())), 2.0 * pi * self.u()
        self.spare = r * sin(a)
        return r * cos(a)

def mean_se(xs):                              # plain running sums (sum() compensates, Rust does not)
    s1 = s2 = 0.0
    for x in xs: s1, s2 = s1 + x, s2 + x * x
    m = s1 / len(xs)
    return m, sqrt((s2 / len(xs) - m * m) / len(xs))

def gauss(n, T, a, b):
    # E[exp(-a W_T^2 - b dt sum_{k=1..n} W_{k dt}^2)], dt = T/n, exactly: det(Tn + 2b dt^2 I + 2a dt e_n e_n)^(-1/2),
    # Tn = inverse covariance of the grid path times dt (diagonal 2,..,2,1, off-diagonal -1).  None = infinite.
    dt, d0, d1 = T / n, 1.0, 1.0
    for k in range(1, n + 1):
        dk = (2.0 if k < n else 1.0 + 2.0 * a * dt) + 2.0 * b * dt * dt
        d0, d1 = d1, dk * d1 - (d0 if k > 1 else 0.0)
        if d1 <= 0.0: return None
    return 1.0 / sqrt(d1)

def fmt(v): return "infinite" if v is None else f"{v:.6f}"

# ---- A: constant tilt, the shelf's share ----
mu, r, sig, T = 0.08, 0.05, 0.20, 1.0
th = (mu - r) / sig
rng = Rng(20260930)
zs = [exp(-th * sqrt(T) * g - 0.5 * th * th * T) for g in (rng.normal() for _ in range(100000))]
mA, sA = mean_se(zs)
print(f"A theta {th:.2f}   theta^2 {th * th:.4f}   half theta^2 T {0.5 * th * th * T:.5f}")
print(f"A Novikov E[exp(half int theta^2)] {exp(0.5 * th * th * T):.6f}   Q drift {mu - sig * th:.2f}")
print(f"A simulated E[Z_1], 100000 draws  {mA:.4f}  se {sA:.4f}")

# ---- B: theta_t = c W_t ----
c = 1.0
def novB(T): return 1.0 / sqrt(cos(c * T)) if c * T < pi / 2 else None
def ezB(T): return exp(0.5 * c * T) / sqrt(cosh(c * T) + sinh(c * T))   # Cameron-Martin, a = c/2, b = c^2/2
print(f"B Novikov horizon pi/(2c) {pi / (2 * c):.6f} years   cos(1) {cos(1.0):.6f}")
print("B grid n    Novikov T=1    error       E[Z_2] grid   error      Novikov T=2")
for n in (25, 100, 400, 1600):
    nv, ez = gauss(n, 1.0, 0.0, -0.5 * c * c), exp(c) * gauss(n, 2.0, 0.5 * c, 0.5 * c * c)
    print(f"B {n:6d} {nv:12.6f} {nv - novB(1.0):+11.7f} {ez:12.6f} {ez - 1.0:+11.7f}   {fmt(gauss(n, 2.0, 0.0, -0.5 * c * c))}")
print(f"B formula Novikov T=1 {novB(1.0):.6f}   T=1.5 {fmt(novB(1.5))}   T=1.6 {fmt(novB(1.6))}   T=2 {fmt(novB(2.0))}")
tstar = next(k / 100 for k in range(1, 401) if gauss(1600, k / 100, 0.0, -0.5 * c * c) is None)
print(f"B grid n 1600, T in steps of 0.01: Novikov first infinite at T = {tstar:.2f}   formula pi/(2c) {pi / (2 * c):.6f}")
steps, T2 = 200, 2.0
dt, zs = T2 / steps, []
for _ in range(20000):
    w, s = 0.0, 0.0
    for _ in range(steps):
        w += sqrt(dt) * rng.normal()
        s += dt * w * w
    zs.append(exp(0.5 * c * T2 - 0.5 * c * w * w - 0.5 * c * c * s))
mB, sB = mean_se(zs)
print(f"B simulated E[Z_2], 200 steps, 20000 paths {mB:.4f}  se {sB:.4f}   same grid exact {exp(c) * gauss(steps, T2, 0.5 * c, 0.5 * c * c):.6f}")
print("chart, B T          " + " ".join(f"{t:6.2f}" for t in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5)))
print("chart, B Novikov    " + " ".join(f"{novB(t):6.2f}" for t in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5)))
print("chart, B E[Z_T]     " + " ".join(f"{ezB(t):6.2f}" for t in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5)))

# ---- C: dZ = Z^2 dW, the weight that feeds its own tilt ----
R0 = 1.0                                       # start of R = 1/Z, so Z_0 = 1/R0; weights are Z/Z_0
def survC(T): return erf(R0 / sqrt(2.0 * T))    # chance a Brownian motion from R0 stays above 0 to T
def lattice(h, T):                             # walk of +-h every h^2 years from R0, absorbed at 0
    k0, n = round(R0 / h), round(T / (h * h))
    p = [0.0] * (k0 + n + 2)
    p[k0] = 1.0
    for _ in range(n):
        p = [0.0] + [0.5 * (p[j - 1] + p[j + 1]) for j in range(1, len(p) - 1)] + [0.0]
        p[0] = 0.0
    tot = 0.0
    for v in p[1:]: tot += v
    return tot
print(f"C deterministic part dy = y^3 dt from 1 blows up at t = {0.5:.2f} years")
print(f"C formula E[Z_1] = 2 Phi(R0) - 1 = {survC(1.0):.6f}   Phi(1) {0.5 * (1 + erf(1 / sqrt(2))):.6f}   leak {1 - survC(1.0):.6f}")
lat = []
for h in (0.1, 0.05, 0.025):
    lat.append(lattice(h, 1.0))
    print(f"C lattice h {h:5.3f}  survival {lat[-1]:.6f}  error {lat[-1] - survC(1.0):+.6f}")
zs = []
for _ in range(200000):                        # Z_1/Z_0 = R0/|(R0,0,0) + 3-d Brownian motion at time 1|
    g1, g2, g3 = rng.normal(), rng.normal(), rng.normal()
    zs.append(R0 / sqrt((R0 + g1) * (R0 + g1) + g2 * g2 + g3 * g3))
mC, sC = mean_se(zs)
print(f"C simulated E[Z_1] under P, 200000 paths {mC:.4f}  se {sC:.4f}")
for cap in (10, 100, 1000):
    lost = 1.0 - erf((R0 - 1.0 / cap) / sqrt(2.0))
    print(f"C cap {cap:5d}: mass on capped paths {lost:.6f}, their chance {lost / (cap * R0):.6f}")
tc = (0.25, 0.5, 1.0, 2.0, 4.0, 8.0)
print("chart, C T          " + " ".join(f"{t:6.2f}" for t in tc))
print("chart, C E[Z_T]     " + " ".join(f"{survC(t):6.2f}" for t in tc))
print("chart, A E[Z_T]     " + " ".join(f"{exp(-0.5 * th * th * t) * exp(0.5 * th * th * t):6.2f}" for t in tc))

assert abs(mA - 1.0) < 4 * sA, "A: constant tilt, weights average 1"
assert abs(gauss(1600, 1.0, 0.0, -0.5 * c * c) - novB(1.0)) < 1e-3, "B: grid determinant vs 1/sqrt(cos cT)"
assert (gauss(1600, 2.0, 0.0, -0.5 * c * c) is None) == (novB(2.0) is None), "B: both roads agree on Novikov at T = 2"
assert abs(tstar - pi / (2 * c)) < 0.01, "B: the grid road blows up within a step of pi/(2c)"
assert abs(exp(c) * gauss(1600, 2.0, 0.5 * c, 0.5 * c * c) - 1.0) < 1e-3, "B: E[Z_2] = 1 though Novikov fails"
assert abs(mB - exp(c) * gauss(steps, T2, 0.5 * c, 0.5 * c * c)) < 4 * sB, "B: simulation vs same-grid exact"
assert abs(lat[-1] - survC(1.0)) < 0.01 and abs(lat[-1] - survC(1.0)) < abs(lat[0] - survC(1.0)), "C: lattice -> formula"
assert abs(mC - survC(1.0)) < 4 * sC, "C: P-side simulation vs Q-side reflection formula"
assert 1.0 - mC > 20 * sC, "C: the leak is real"
print("ALL CHECKS PASS")
```

**Ran 2026-10-07 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
A theta 0.15   theta^2 0.0225   half theta^2 T 0.01125
A Novikov E[exp(half int theta^2)] 1.011314   Q drift 0.05
A simulated E[Z_1], 100000 draws  0.9997  se 0.0005
B Novikov horizon pi/(2c) 1.570796 years   cos(1) 0.540302
B grid n    Novikov T=1    error       E[Z_2] grid   error      Novikov T=2
B     25     1.382222  +0.0217754     0.990788  -0.0092123   infinite
B    100     1.365779  +0.0053326     0.997584  -0.0024163   infinite
B    400     1.361773  +0.0013264     0.999389  -0.0006112   infinite
B   1600     1.360778  +0.0003312     0.999847  -0.0001532   infinite
B formula Novikov T=1 1.360447   T=1.5 3.759898   T=1.6 infinite   T=2 infinite
B grid n 1600, T in steps of 0.01: Novikov first infinite at T = 1.58   formula pi/(2c) 1.570796
B simulated E[Z_2], 200 steps, 20000 paths 0.9970  se 0.0056   same grid exact 0.998782
chart, B T            0.25   0.50   0.75   1.00   1.25   1.50
chart, B Novikov      1.02   1.07   1.17   1.36   1.78   3.76
chart, B E[Z_T]       1.00   1.00   1.00   1.00   1.00   1.00
C deterministic part dy = y^3 dt from 1 blows up at t = 0.50 years
C formula E[Z_1] = 2 Phi(R0) - 1 = 0.682689   Phi(1) 0.841345   leak 0.317311
C lattice h 0.100  survival 0.680273  error -0.002417
C lattice h 0.050  survival 0.682085  error -0.000605
C lattice h 0.025  survival 0.682538  error -0.000151
C simulated E[Z_1] under P, 200000 paths 0.6814  se 0.0011
C cap    10: mass on capped paths 0.368120, their chance 0.036812
C cap   100: mass on capped paths 0.322174, their chance 0.003222
C cap  1000: mass on capped paths 0.317795, their chance 0.000318
chart, C T            0.25   0.50   1.00   2.00   4.00   8.00
chart, C E[Z_T]       0.95   0.84   0.68   0.52   0.38   0.28
chart, A E[Z_T]       1.00   1.00   1.00   1.00   1.00   1.00
ALL CHECKS PASS
```

### Rust

```rust
// Novikov's condition -- the check behind the card.  Rust std only.
// Three tilts theta_t for Girsanov, time in years, W_t a Brownian motion under P:
//   A  constant 0.15: the share drifting 8% a year, priced at 5%, volatility 20%
//   B  theta_t = c W_t, c = 1 per year: the tilt grows with the wander
//   C  theta_t = -Z_t: the tilt grows with the weight itself, so dZ = Z^2 dW
// Roads: closed forms; exact Gaussian determinants and an exact lattice walk on
// shrinking grids; seeded simulation (SplitMix64 + Box-Muller) with standard errors.
use std::f64::consts::PI;

fn erf(x: f64) -> f64 { // Taylor series, accurate for |x| <= 3
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= -x * x / n;
        total += term / (2.0 * n + 1.0);
    }
    2.0 / PI.sqrt() * total
}

struct Rng { s: u64, spare: Option<f64> } // SplitMix64 uniforms, Box-Muller normals
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 {
        if let Some(g) = self.spare.take() { return g; }
        let r = (-2.0 * (1.0 - self.u()).ln()).sqrt();
        let a = 2.0 * PI * self.u();
        self.spare = Some(r * a.sin());
        r * a.cos()
    }
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let (mut s1, mut s2) = (0.0, 0.0);
    for &x in xs { s1 += x; s2 += x * x; }
    let n = xs.len() as f64;
    let m = s1 / n;
    (m, ((s2 / n - m * m) / n).sqrt())
}

// E[exp(-a W_T^2 - b dt sum_{k=1..n} W_{k dt}^2)], dt = T/n, exactly: det(Tn + 2b dt^2 I + 2a dt e_n e_n)^(-1/2).
fn gauss(n: usize, t: f64, a: f64, b: f64) -> Option<f64> {
    let (dt, mut d0, mut d1) = (t / n as f64, 1.0, 1.0);
    for k in 1..=n {
        let dk = (if k < n { 2.0 } else { 1.0 + 2.0 * a * dt }) + 2.0 * b * dt * dt;
        let next = dk * d1 - if k > 1 { d0 } else { 0.0 };
        d0 = d1;
        d1 = next;
        if d1 <= 0.0 { return None; }
    }
    Some(1.0 / d1.sqrt())
}

fn fmt(v: Option<f64>) -> String { match v { None => "infinite".to_string(), Some(x) => format!("{:.6}", x) } }
fn row(xs: &[f64]) -> String { xs.iter().map(|v| format!("{:6.2}", v)).collect::<Vec<_>>().join(" ") }

fn main() {
    // ---- A: constant tilt, the shelf's share ----
    let (mu, r, sig, t) = (0.08, 0.05, 0.20, 1.0);
    let th: f64 = (mu - r) / sig;
    let mut rng = Rng { s: 20260930, spare: None };
    let zs: Vec<f64> = (0..100000).map(|_| { let g = rng.normal(); (-th * f64::sqrt(t) * g - 0.5 * th * th * t).exp() }).collect();
    let (ma, sa) = mean_se(&zs);
    println!("A theta {:.2}   theta^2 {:.4}   half theta^2 T {:.5}", th, th * th, 0.5 * th * th * t);
    println!("A Novikov E[exp(half int theta^2)] {:.6}   Q drift {:.2}", (0.5 * th * th * t).exp(), mu - sig * th);
    println!("A simulated E[Z_1], 100000 draws  {:.4}  se {:.4}", ma, sa);

    // ---- B: theta_t = c W_t ----
    let c: f64 = 1.0;
    let nov_b = |t: f64| -> Option<f64> { if c * t < PI / 2.0 { Some(1.0 / (c * t).cos().sqrt()) } else { None } };
    let ez_b = |t: f64| (0.5 * c * t).exp() / ((c * t).cosh() + (c * t).sinh()).sqrt(); // Cameron-Martin, a = c/2, b = c^2/2
    println!("B Novikov horizon pi/(2c) {:.6} years   cos(1) {:.6}", PI / (2.0 * c), 1f64.cos());
    println!("B grid n    Novikov T=1    error       E[Z_2] grid   error      Novikov T=2");
    for n in [25usize, 100, 400, 1600] {
        let nv = gauss(n, 1.0, 0.0, -0.5 * c * c).unwrap();
        let ez = c.exp() * gauss(n, 2.0, 0.5 * c, 0.5 * c * c).unwrap();
        println!("B {:6} {:12.6} {:+11.7} {:12.6} {:+11.7}   {}", n, nv, nv - nov_b(1.0).unwrap(), ez, ez - 1.0, fmt(gauss(n, 2.0, 0.0, -0.5 * c * c)));
    }
    println!("B formula Novikov T=1 {:.6}   T=1.5 {}   T=1.6 {}   T=2 {}", nov_b(1.0).unwrap(), fmt(nov_b(1.5)), fmt(nov_b(1.6)), fmt(nov_b(2.0)));
    let tstar = (1..=400).map(|k| k as f64 / 100.0).find(|&x| gauss(1600, x, 0.0, -0.5 * c * c).is_none()).unwrap();
    println!("B grid n 1600, T in steps of 0.01: Novikov first infinite at T = {:.2}   formula pi/(2c) {:.6}", tstar, PI / (2.0 * c));
    let (steps, t2) = (200usize, 2.0);
    let dt = t2 / steps as f64;
    let mut zs = Vec::new();
    for _ in 0..20000 {
        let (mut w, mut s) = (0.0, 0.0);
        for _ in 0..steps {
            w += dt.sqrt() * rng.normal();
            s += dt * w * w;
        }
        zs.push((0.5 * c * t2 - 0.5 * c * w * w - 0.5 * c * c * s).exp());
    }
    let (mb, sb) = mean_se(&zs);
    let grid_b = c.exp() * gauss(steps, t2, 0.5 * c, 0.5 * c * c).unwrap();
    println!("B simulated E[Z_2], 200 steps, 20000 paths {:.4}  se {:.4}   same grid exact {:.6}", mb, sb, grid_b);
    let tb = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5];
    println!("chart, B T          {}", row(&tb));
    println!("chart, B Novikov    {}", row(&tb.iter().map(|&x| nov_b(x).unwrap()).collect::<Vec<_>>()));
    println!("chart, B E[Z_T]     {}", row(&tb.iter().map(|&x| ez_b(x)).collect::<Vec<_>>()));

    // ---- C: dZ = Z^2 dW, the weight that feeds its own tilt ----
    let r0: f64 = 1.0; // start of R = 1/Z, so Z_0 = 1/R0; weights are Z/Z_0
    let surv_c = |t: f64| erf(r0 / (2.0 * t).sqrt()); // chance a Brownian motion from R0 stays above 0 to T
    let lattice = |h: f64, t: f64| -> f64 { // walk of +-h every h^2 years from R0, absorbed at 0
        let (k0, n) = ((r0 / h).round() as usize, (t / (h * h)).round() as usize);
        let mut p = vec![0.0; k0 + n + 2];
        p[k0] = 1.0;
        for _ in 0..n {
            let mut q = vec![0.0; p.len()];
            for j in 1..p.len() - 1 { q[j] = 0.5 * (p[j - 1] + p[j + 1]); }
            q[0] = 0.0;
            p = q;
        }
        let mut tot = 0.0;
        for v in &p[1..] { tot += v; }
        tot
    };
    println!("C deterministic part dy = y^3 dt from 1 blows up at t = {:.2} years", 0.5);
    let s1 = surv_c(1.0);
    println!("C formula E[Z_1] = 2 Phi(R0) - 1 = {:.6}   Phi(1) {:.6}   leak {:.6}", s1, 0.5 * (1.0 + erf(1.0 / 2f64.sqrt())), 1.0 - s1);
    let mut lat = Vec::new();
    for h in [0.1, 0.05, 0.025] {
        lat.push(lattice(h, 1.0));
        let l = *lat.last().unwrap();
        println!("C lattice h {:5.3}  survival {:.6}  error {:+.6}", h, l, l - s1);
    }
    let mut zs = Vec::new();
    for _ in 0..200000 { // Z_1/Z_0 = R0/|(R0,0,0) + 3-d Brownian motion at time 1|
        let (g1, g2, g3) = (rng.normal(), rng.normal(), rng.normal());
        zs.push(r0 / ((r0 + g1) * (r0 + g1) + g2 * g2 + g3 * g3).sqrt());
    }
    let (mc, sc) = mean_se(&zs);
    println!("C simulated E[Z_1] under P, 200000 paths {:.4}  se {:.4}", mc, sc);
    for cap in [10usize, 100, 1000] {
        let lost = 1.0 - erf((r0 - 1.0 / cap as f64) / 2f64.sqrt());
        println!("C cap {:5}: mass on capped paths {:.6}, their chance {:.6}", cap, lost, lost / (cap as f64 * r0));
    }
    let tc = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0];
    println!("chart, C T          {}", row(&tc));
    println!("chart, C E[Z_T]     {}", row(&tc.iter().map(|&x| surv_c(x)).collect::<Vec<_>>()));
    println!("chart, A E[Z_T]     {}", row(&tc.iter().map(|&x| (-0.5 * th * th * x).exp() * (0.5 * th * th * x).exp()).collect::<Vec<_>>()));

    assert!((ma - 1.0).abs() < 4.0 * sa, "A: constant tilt, weights average 1");
    assert!((gauss(1600, 1.0, 0.0, -0.5 * c * c).unwrap() - nov_b(1.0).unwrap()).abs() < 1e-3, "B: grid determinant vs 1/sqrt(cos cT)");
    assert!(gauss(1600, 2.0, 0.0, -0.5 * c * c).is_none() == nov_b(2.0).is_none(), "B: both roads agree on Novikov at T = 2");
    assert!((tstar - PI / (2.0 * c)).abs() < 0.01, "B: the grid road blows up within a step of pi/(2c)");
    assert!((c.exp() * gauss(1600, 2.0, 0.5 * c, 0.5 * c * c).unwrap() - 1.0).abs() < 1e-3, "B: E[Z_2] = 1 though Novikov fails");
    assert!((mb - grid_b).abs() < 4.0 * sb, "B: simulation vs same-grid exact");
    assert!((lat[2] - s1).abs() < 0.01 && (lat[2] - s1).abs() < (lat[0] - s1).abs(), "C: lattice -> formula");
    assert!((mc - s1).abs() < 4.0 * sc, "C: P-side simulation vs Q-side reflection formula");
    assert!(1.0 - mc > 20.0 * sc, "C: the leak is real");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-10-07 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
A theta 0.15   theta^2 0.0225   half theta^2 T 0.01125
A Novikov E[exp(half int theta^2)] 1.011314   Q drift 0.05
A simulated E[Z_1], 100000 draws  0.9997  se 0.0005
B Novikov horizon pi/(2c) 1.570796 years   cos(1) 0.540302
B grid n    Novikov T=1    error       E[Z_2] grid   error      Novikov T=2
B     25     1.382222  +0.0217754     0.990788  -0.0092123   infinite
B    100     1.365779  +0.0053326     0.997584  -0.0024163   infinite
B    400     1.361773  +0.0013264     0.999389  -0.0006112   infinite
B   1600     1.360778  +0.0003312     0.999847  -0.0001532   infinite
B formula Novikov T=1 1.360447   T=1.5 3.759898   T=1.6 infinite   T=2 infinite
B grid n 1600, T in steps of 0.01: Novikov first infinite at T = 1.58   formula pi/(2c) 1.570796
B simulated E[Z_2], 200 steps, 20000 paths 0.9970  se 0.0056   same grid exact 0.998782
chart, B T            0.25   0.50   0.75   1.00   1.25   1.50
chart, B Novikov      1.02   1.07   1.17   1.36   1.78   3.76
chart, B E[Z_T]       1.00   1.00   1.00   1.00   1.00   1.00
C deterministic part dy = y^3 dt from 1 blows up at t = 0.50 years
C formula E[Z_1] = 2 Phi(R0) - 1 = 0.682689   Phi(1) 0.841345   leak 0.317311
C lattice h 0.100  survival 0.680273  error -0.002417
C lattice h 0.050  survival 0.682085  error -0.000605
C lattice h 0.025  survival 0.682538  error -0.000151
C simulated E[Z_1] under P, 200000 paths 0.6814  se 0.0011
C cap    10: mass on capped paths 0.368120, their chance 0.036812
C cap   100: mass on capped paths 0.322174, their chance 0.003222
C cap  1000: mass on capped paths 0.317795, their chance 0.000318
chart, C T            0.25   0.50   1.00   2.00   4.00   8.00
chart, C E[Z_T]       0.95   0.84   0.68   0.52   0.38   0.28
chart, A E[Z_T]       1.00   1.00   1.00   1.00   1.00   1.00
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves that the weights of any tilt average at most 1, and finds tilt C's exact average at every horizon.

- Take a tilt chosen from the past, with finite total square on every path, whose weight is a local martingale as in Step 1. Then the weight is a supermartingale, and $E[Z_T] \le 1$ at every horizon T.
- With the same tilt, suppose $E[Z_T] = 1$ at a horizon T. Then $(Z_t)$ is a martingale on $[0, T]$.
- Step 1 itself is taken as given, because Lean has no Ito integral yet.
- Take tilt C at any horizon $T > 0$, using the three-dimensional picture in the fold under Step 5. Then its weights average exactly $2\Phi(1/\sqrt{T}) - 1$, below 1.
- The share's numbers, the leak 0.317311, Step 5's Ito coefficients, the Detailed proof's algebra and tilt B's bracket $e^{cT}$ also check.

Novikov's test itself, tilt C's three-dimensional picture and tilt B's averages are left to the card's proof and the Python and Rust checks.

```lean
-- Novikov: the exponential weight of a tilt is a supermartingale, so it always averages at most 1 and averaging exactly 1 makes it a fair game on [0, T]; the self-feeding tilt's weight averages only 2Φ(1/√T) - 1.
import Mathlib.Probability.Process.LocalProperty
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

open MeasureTheory ProbabilityTheory Real
open scoped NNReal ENNReal

/-! Setting, as on the card. Time runs over `ℝ≥0`; `ℱ t` is what is known by time `t`.
The tilt is `θ t ω`. Its accumulated square is `A t ω = ∫₀ᵗ θ_s² ds`, written out below as an
interval integral. The card's `M t = -∫₀ᵗ θ_s dW_s` is an Ito integral, which Mathlib does not
build yet. So `M` is taken as given, with the properties the Ito integral has on the card:
it is known by time `t` (adapted to `ℱ`), it starts at 0, and the weight
`Z_t = exp (M_t - A_t / 2)` is a local martingale (the card's Step 1, by Ito's lemma).
Mathlib's `Locally (fun Y => Martingale Y ℱ P) ℱ X P` is "X is a local martingale":
there are stopping times rising to infinity at which the stopped process is a martingale.
The card's "When it holds": the tilt is chosen from the past (progressive measurability) and
its total square is finite on every path (interval integrability).

Scope. The full Novikov theorem (`E[exp (A_T / 2)] < ∞` gives `E[Z_T] = 1`) is not stated here:
its proof needs optional stopping at general continuous-time stopping times, uniform
integrability and a Hölder limit, which this Mathlib does not supply in a usable size.
This file states the card's Step 2 (the weights always average at most 1, and averaging
exactly 1 forces the fair game), the tilt C average from the card's code, and the card's
exact arithmetic. -/

section NovikovHelpers1
open Filter Topology
/-- Key set-integral inequality for a nonnegative local martingale. -/
lemma nonneg_localMart_lintegral_le {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (Z : ℝ≥0 → Ω → ℝ)
    (hZnn : ∀ t ω, 0 ≤ Z t ω)
    (hloc : Locally (fun Y => Martingale Y ℱ P) ℱ Z P)
    {i j : ℝ≥0} (hij : i ≤ j) {A : Set Ω} (hA : MeasurableSet[ℱ i] A) :
    ∫⁻ ω in A, ENNReal.ofReal (Z j ω) ∂P ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P := by
  obtain ⟨τ, hτ, hmart⟩ := hloc
  set Y : ℕ → ℝ≥0 → Ω → ℝ :=
    fun n => stoppedProcess (fun r ↦ {ω | ⊥ < τ n ω}.indicator (Z r)) (τ n) with hY
  have hYnn : ∀ n r ω, 0 ≤ Y n r ω := by
    intro n r ω
    simp only [hY, stoppedProcess]
    exact Set.indicator_nonneg (fun ω _ => hZnn _ ω) ω
  set B : ℕ → Set Ω := fun n => A ∩ {ω | (i : WithTop ℝ≥0) < τ n ω} with hB
  have hBmeas : ∀ n, MeasurableSet[ℱ i] (B n) := by
    intro n
    refine hA.inter ?_
    have h := (hτ.isStoppingTime n) i
    have : {ω | (i : WithTop ℝ≥0) < τ n ω} = {ω | τ n ω ≤ i}ᶜ := by
      ext ω; simp only [Set.mem_ofPred_eq, Set.mem_compl_iff, not_le]
    rw [this]; exact h.compl
  have hYi : ∀ n, ∀ ω ∈ B n, Y n i ω = Z i ω := by
    intro n ω hω
    have h1 : (i : WithTop ℝ≥0) < τ n ω := hω.2
    have h2 : (⊥ : WithTop ℝ≥0) < τ n ω := lt_of_le_of_lt bot_le h1
    simp only [hY, stoppedProcess, min_eq_left h1.le]
    rw [Set.indicator_of_mem (show ω ∈ {ω | ⊥ < τ n ω} from h2)]
    rfl
  -- bound for each n
  have hbound : ∀ n, ∫⁻ ω in B n, ENNReal.ofReal (Y n j ω) ∂P
      ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P := by
    intro n
    have hm := hmart n
    have hint_j : Integrable (Y n j) P := hm.integrable j
    have hint_i : Integrable (Y n i) P := hm.integrable i
    have heq := hm.setIntegral_eq hij (hBmeas n)
    rw [← ofReal_integral_eq_lintegral_ofReal hint_j.integrableOn
      (ae_of_all _ (fun ω => hYnn n j ω)), ← heq,
      ofReal_integral_eq_lintegral_ofReal hint_i.integrableOn
      (ae_of_all _ (fun ω => hYnn n i ω))]
    calc ∫⁻ ω in B n, ENNReal.ofReal (Y n i ω) ∂P
        = ∫⁻ ω in B n, ENNReal.ofReal (Z i ω) ∂P := by
          refine setLIntegral_congr_fun (ℱ.le i _ (hBmeas n)) ?_
          intro ω hω; dsimp only; rw [hYi n ω hω]
      _ ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P :=
          lintegral_mono_set Set.inter_subset_left
  -- Fatou
  have hmeasY : ∀ n, Measurable fun ω => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω := by
    intro n
    refine Measurable.indicator ?_ (ℱ.le i _ (hBmeas n))
    exact ENNReal.measurable_ofReal.comp
      (((hmart n).stronglyAdapted j).mono (ℱ.le j)).measurable
  have hlim : ∀ᵐ ω ∂P, liminf (fun n => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω)
      atTop = A.indicator (fun ω => ENNReal.ofReal (Z j ω)) ω := by
    filter_upwards [hτ.tendsto_top] with ω hω
    have hev : ∀ᶠ n in atTop, (j : WithTop ℝ≥0) < τ n ω :=
      hω.eventually (lt_mem_nhds (WithTop.coe_lt_top j))
    have hEv : (fun n => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω)
        =ᶠ[atTop] fun _ => A.indicator (fun ω => ENNReal.ofReal (Z j ω)) ω := by
      filter_upwards [hev] with n hn
      have hin : (i : WithTop ℝ≥0) < τ n ω := lt_of_le_of_lt (WithTop.coe_le_coe.2 hij) hn
      have h2 : (⊥ : WithTop ℝ≥0) < τ n ω := lt_of_le_of_lt bot_le hn
      have hYj : Y n j ω = Z j ω := by
        simp only [hY, stoppedProcess, min_eq_left hn.le]
        rw [Set.indicator_of_mem (show ω ∈ {ω | ⊥ < τ n ω} from h2)]
        rfl
      by_cases hωA : ω ∈ A
      · have : ω ∈ B n := ⟨hωA, hin⟩
        rw [Set.indicator_of_mem this, Set.indicator_of_mem hωA, hYj]
      · have : ω ∉ B n := fun h => hωA h.1
        rw [Set.indicator_of_notMem this, Set.indicator_of_notMem hωA]
    rw [Filter.liminf_congr hEv, liminf_const]
  calc ∫⁻ ω in A, ENNReal.ofReal (Z j ω) ∂P
      = ∫⁻ ω, A.indicator (fun ω => ENNReal.ofReal (Z j ω)) ω ∂P :=
        (lintegral_indicator (ℱ.le i _ hA) _).symm
    _ = ∫⁻ ω, liminf (fun n => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω) atTop ∂P :=
        lintegral_congr_ae (hlim.mono fun ω h => h.symm)
    _ ≤ liminf (fun n => ∫⁻ ω, (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω ∂P) atTop :=
        lintegral_liminf_le hmeasY
    _ ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P := by
        refine liminf_le_of_frequently_le' (Frequently.of_forall fun n => ?_)
        rw [lintegral_indicator (ℱ.le i _ (hBmeas n))]
        exact hbound n

lemma nonneg_localMart_supermartingale {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (Z : ℝ≥0 → Ω → ℝ)
    (hZad : StronglyAdapted ℱ Z) (hZnn : ∀ t ω, 0 ≤ Z t ω) (hZ0 : ∀ ω, Z 0 ω = 1)
    (hloc : Locally (fun Y => Martingale Y ℱ P) ℱ Z P) :
    Supermartingale Z ℱ P := by
  have hint : ∀ t, Integrable (Z t) P := by
    intro t
    refine ⟨((hZad t).mono (ℱ.le t)).aestronglyMeasurable, ?_⟩
    rw [hasFiniteIntegral_iff_ofReal (ae_of_all _ (hZnn t))]
    have h := nonneg_localMart_lintegral_le P ℱ Z hZnn hloc (zero_le : (0:ℝ≥0) ≤ t)
      (MeasurableSet.univ)
    simp only [Measure.restrict_univ, hZ0, ENNReal.ofReal_one, lintegral_const,
      measure_univ, mul_one] at h
    exact lt_of_le_of_lt h ENNReal.one_lt_top
  have hsub : Submartingale (-Z) ℱ P := by
    refine submartingale_of_setIntegral_le hZad.neg (fun t => (hint t).neg) ?_
    intro i j hij A hA
    simp only [Pi.neg_apply, integral_neg, neg_le_neg_iff]
    have h := nonneg_localMart_lintegral_le P ℱ Z hZnn hloc hij hA
    rw [← ofReal_integral_eq_lintegral_ofReal (hint j).integrableOn
      (ae_of_all _ (hZnn j)), ← ofReal_integral_eq_lintegral_ofReal (hint i).integrableOn
      (ae_of_all _ (hZnn i))] at h
    exact (ENNReal.ofReal_le_ofReal_iff (setIntegral_nonneg (ℱ.le i _ hA)
      (fun ω _ => hZnn i ω))).1 h
  simpa using hsub.neg

lemma supermartingale_stopped_martingale {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (Z : ℝ≥0 → Ω → ℝ)
    (hZ : Supermartingale Z ℱ P) (hZ0 : ∫ ω, Z 0 ω ∂P = 1) (T : ℝ≥0)
    (hT : ∫ ω, Z T ω ∂P = 1) :
    Martingale (fun t ω => Z (min t T) ω) ℱ P := by
  refine ⟨fun t => (hZ.1 (min t T)).mono (ℱ.mono (min_le_left t T)), fun i j hij => ?_⟩
  rcases le_or_gt T i with hTi | hiT
  · have h1 : min i T = T := min_eq_right hTi
    have h2 : min j T = T := min_eq_right (hTi.trans hij)
    simp only [h1, h2]
    exact (condExp_of_stronglyMeasurable (ℱ.le i) ((hZ.1 T).mono (ℱ.mono hTi))
      (hZ.integrable T)).eventuallyEq
  · have h1 : min i T = i := min_eq_left hiT.le
    simp only [h1]
    have hle : P[Z (min j T) | ℱ i] ≤ᵐ[P] Z i := hZ.2.1 i (min j T) (le_min hij hiT.le)
    have hE1 : ∫ ω, Z (min j T) ω ∂P ≥ 1 := by
      have := hZ.setIntegral_le (min_le_right j T) (s := Set.univ) MeasurableSet.univ
      simp only [Measure.restrict_univ] at this
      linarith
    have hE2 : ∫ ω, Z i ω ∂P ≤ 1 := by
      have := hZ.setIntegral_le (zero_le : (0:ℝ≥0) ≤ i) (s := Set.univ) MeasurableSet.univ
      simp only [Measure.restrict_univ] at this
      linarith
    have hg : 0 ≤ᵐ[P] fun ω => Z i ω - P[Z (min j T) | ℱ i] ω := by
      filter_upwards [hle] with ω hω; show (0:ℝ) ≤ _; linarith
    have hgint : Integrable (fun ω => Z i ω - P[Z (min j T) | ℱ i] ω) P :=
      (hZ.integrable i).sub integrable_condExp
    have hzero : ∫ ω, (Z i ω - P[Z (min j T) | ℱ i] ω) ∂P = 0 := by
      rw [integral_sub (hZ.integrable i) integrable_condExp, integral_condExp (ℱ.le i)]
      have := integral_nonneg_of_ae hg
      rw [integral_sub (hZ.integrable i) integrable_condExp, integral_condExp (ℱ.le i)] at this
      linarith
    have := (integral_eq_zero_iff_of_nonneg_ae hg hgint).1 hzero
    filter_upwards [this] with ω hω
    simp only [Pi.zero_apply] at hω
    linarith
lemma stronglyMeasurable_integral_sq_of_slice {Ω : Type*} [MeasurableSpace Ω]
    (θ : ℝ≥0 → Ω → ℝ) (t : ℝ≥0)
    (hΘ : StronglyMeasurable fun p : Set.Iic t × Ω => θ p.1 p.2) :
    StronglyMeasurable fun ω => ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2 := by
  let g : ℝ → Set.Iic t := fun s => ⟨min s.toNNReal t, Set.mem_Iic.2 (min_le_right _ _)⟩
  have hg : Measurable g :=
    (measurable_real_toNNReal.min measurable_const).subtype_mk
  have hφ : Measurable fun p : ℝ × Ω => (g p.1, p.2) :=
    (hg.comp measurable_fst).prodMk measurable_snd
  have hH : StronglyMeasurable (Function.uncurry fun (s : ℝ) (ω : Ω) => θ (g s).1 ω ^ 2) := by
    have := (hΘ.comp_measurable hφ)
    exact this.pow 2
  have hint := hH.integral_prod_left (μ := (volume : Measure ℝ).restrict (Set.Ioc 0 t))
  convert hint using 1
  funext ω
  rw [intervalIntegral.integral_of_le (NNReal.coe_nonneg t)]
  refine setIntegral_congr_fun measurableSet_Ioc (fun s hs => ?_)
  have : s.toNNReal ≤ t := (Real.toNNReal_le_iff_le_coe).2 hs.2
  simp only [g, min_eq_left this]

lemma stronglyAdapted_exp_weight {Ω : Type*} {mΩ : MeasurableSpace Ω}
    (ℱ : Filtration ℝ≥0 mΩ) (θ M : ℝ≥0 → Ω → ℝ)
    (hθ : IsStronglyProgressive ℱ θ) (hMad : StronglyAdapted ℱ M) :
    StronglyAdapted ℱ
      (fun t ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2)) := by
  intro t
  have hI := @stronglyMeasurable_integral_sq_of_slice Ω (ℱ t) θ t (hθ t)
  have h := (hMad t).sub (hI.const_mul (1 / 2))
  exact Real.continuous_exp.comp_stronglyMeasurable h

end NovikovHelpers1

/-- **The weights always average at most 1 (Step 2).** Let the tilt `θ` be chosen from the past,
with finite total square `A_t = ∫₀ᵗ θ_s² ds` on every path, and let `M_t = -∫₀ᵗ θ_s dW_s`
(see the setting above), so the candidate weight is `Z_t = exp (M_t - A_t / 2)`, a positive
local martingale starting at 1. Then, with no further condition, `Z` is a supermartingale
(its forecast never exceeds its present value), so `E[Z_T] ≤ 1` at every horizon `T`; and if
`E[Z_T] = 1` at a horizon `T`, then `Z` is a true martingale on `[0, T]` (written as the
process stopped at `T`). -/
theorem exponential_weight_supermartingale {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (θ M : ℝ≥0 → Ω → ℝ)
    (hθ : IsStronglyProgressive ℱ θ)
    (hθsq : ∀ ω (t : ℝ≥0), IntervalIntegrable (fun s : ℝ => θ s.toNNReal ω ^ 2) volume 0 t)
    (hMad : StronglyAdapted ℱ M) (hM0 : ∀ ω, M 0 ω = 0)
    (hZloc : Locally (fun Y => Martingale Y ℱ P) ℱ
      (fun t ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2)) P) :
    Supermartingale (fun t ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2))
        ℱ P ∧
      ∀ T : ℝ≥0,
        ∫ ω, exp (M T ω - 1 / 2 * ∫ s in (0 : ℝ)..T, θ s.toNNReal ω ^ 2) ∂P ≤ 1 ∧
        (∫ ω, exp (M T ω - 1 / 2 * ∫ s in (0 : ℝ)..T, θ s.toNNReal ω ^ 2) ∂P = 1 →
          Martingale (fun t ω => exp (M (min t T) ω
            - 1 / 2 * ∫ s in (0 : ℝ)..(min t T : ℝ≥0), θ s.toNNReal ω ^ 2)) ℱ P) := by
  have hZad := stronglyAdapted_exp_weight ℱ θ M hθ hMad
  have hZ0 : ∀ ω, (fun (t : ℝ≥0) ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t,
      θ s.toNNReal ω ^ 2)) 0 ω = 1 := by
    intro ω; simp [hM0]
  have hsup := nonneg_localMart_supermartingale P ℱ _ hZad (fun t ω => (exp_pos _).le) hZ0 hZloc
  have hint0 : ∫ ω, (fun (t : ℝ≥0) ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t,
      θ s.toNNReal ω ^ 2)) 0 ω ∂P = 1 := by
    simp only [hZ0, integral_const, probReal_univ, smul_eq_mul, mul_one]
  refine ⟨hsup, fun T => ⟨?_, fun h => ?_⟩⟩
  · have := hsup.setIntegral_le (zero_le : (0:ℝ≥0) ≤ T) (s := Set.univ) MeasurableSet.univ
    simp only [Measure.restrict_univ] at this
    exact this.trans hint0.le
  · exact supermartingale_stopped_martingale P ℱ _ hsup hint0 T h

section NovikovHelpers2
open Filter Topology
/-- One coordinate: `E[exp (-λ (a + Y)²)]` for `Y` normal with mean 0 and variance `v`. -/
lemma integral_exp_neg_mul_sq_add_gaussianReal (v : ℝ≥0) (hv : v ≠ 0) (lam a : ℝ)
    (hlam : 0 ≤ lam) :
    ∫ y, exp (-lam * (a + y) ^ 2) ∂(gaussianReal 0 v)
      = (√(1 + 2 * lam * v))⁻¹ * exp (-lam * a ^ 2 / (1 + 2 * lam * v)) := by
  have hv' : (0 : ℝ) < v := lt_of_le_of_ne v.2 (fun h => hv (NNReal.coe_eq_zero.1 h.symm))
  set k : ℝ := 1 + 2 * lam * v with hk
  have hkpos : 0 < k := by rw [hk]; positivity
  set β : ℝ := k / (2 * v) with hβ
  have hβpos : 0 < β := by rw [hβ]; positivity
  set γ : ℝ := 2 * lam * a * v / k with hγ
  set δ : ℝ := -lam * a ^ 2 / k with hδ
  rw [integral_gaussianReal_eq_integral_smul hv]
  have hpt : ∀ x : ℝ, gaussianPDFReal 0 v x • exp (-lam * (a + x) ^ 2)
      = ((√(2 * π * v))⁻¹ * exp δ) * exp (-β * (x + γ) ^ 2) := by
    intro x
    rw [gaussianPDFReal, smul_eq_mul, mul_assoc, ← exp_add,
      mul_assoc ((√(2 * π * v))⁻¹) (exp δ), ← exp_add]
    congr 2
    rw [hδ, hβ, hγ]
    field_simp
    rw [hk]
    ring
  simp_rw [hpt]
  rw [integral_const_mul, integral_add_right_eq_self (fun x => exp (-β * x ^ 2)) γ,
    integral_gaussian]
  have h1 : π / β = (2 * π * v) / k := by rw [hβ]; field_simp
  rw [h1, Real.sqrt_div (by positivity)]
  have h2 : (0 : ℝ) < √(2 * π * v) := Real.sqrt_pos.2 (by positivity)
  field_simp

/-- The three-coordinate Gaussian average of `exp (-(q/2) s²)`, `q = |(1,0,0) + x|²`. -/
lemma integral_exp_neg_half_sq_pi (T : ℝ≥0) (hT : T ≠ 0) (s : ℝ) :
    ∫ x, exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)
        ∂(Measure.pi fun _ : Fin 3 => gaussianReal 0 T)
      = exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2) / ((1 + T * s ^ 2) * √(1 + T * s ^ 2)) := by
  let f : Fin 3 → ℝ → ℝ := fun i y => exp (-(s ^ 2 / 2) * ((if i = 0 then 1 else 0) + y) ^ 2)
  have hpt : ∀ x : Fin 3 → ℝ, exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)
      = ∏ i, f i (x i) := by
    intro x
    simp only [f, Fin.prod_univ_three]
    simp only [Fin.isValue, ↓reduceIte, one_ne_zero, Fin.reduceEq, zero_add]
    rw [← exp_add, ← exp_add]
    congr 1
    ring
  simp_rw [hpt]
  rw [integral_fintype_prod_eq_prod]
  have hlam : (0 : ℝ) ≤ s ^ 2 / 2 := by positivity
  have hk : 1 + 2 * (s ^ 2 / 2) * (T : ℝ) = 1 + T * s ^ 2 := by ring
  simp only [f, integral_exp_neg_mul_sq_add_gaussianReal T hT _ _ hlam, hk, Fin.prod_univ_three]
  simp only [Fin.isValue, ↓reduceIte, one_ne_zero, Fin.reduceEq, one_pow, mul_one, ne_eq,
    OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero, zero_div, exp_zero]
  have hkpos : 0 < 1 + (T : ℝ) * s ^ 2 := by positivity
  have hsq : √(1 + (T : ℝ) * s ^ 2) ^ 2 = 1 + T * s ^ 2 := Real.sq_sqrt hkpos.le
  have hsqpos : 0 < √(1 + (T : ℝ) * s ^ 2) := Real.sqrt_pos.2 hkpos
  have he : -(s ^ 2 / 2) / (1 + T * s ^ 2) = -(s ^ 2 / (1 + T * s ^ 2)) / 2 := by ring
  rw [he]
  field_simp
  rw [hsq]

lemma hasDerivAt_normal_primitive_comp (T : ℝ) (hT : 0 ≤ T) (s : ℝ) :
    HasDerivAt (fun s => ∫ v in (0 : ℝ)..(s / √(1 + T * s ^ 2)), exp (-v ^ 2 / 2))
      (exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2) / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))) s := by
  have hk : 0 < 1 + T * s ^ 2 := by positivity
  have hsqpos : 0 < √(1 + T * s ^ 2) := Real.sqrt_pos.2 hk
  have hsq : √(1 + T * s ^ 2) ^ 2 = 1 + T * s ^ 2 := Real.sq_sqrt hk.le
  have h1 : HasDerivAt (fun s => 1 + T * s ^ 2) (T * (2 * s)) s := by
    have := ((hasDerivAt_pow 2 s).const_mul T).const_add 1
    simpa using this
  have h2 := h1.sqrt hk.ne'
  have h3 := (hasDerivAt_id s).div h2 hsqpos.ne'
  have hu : HasDerivAt (fun s => s / √(1 + T * s ^ 2))
      (1 / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))) s := by
    refine h3.congr_deriv ?_
    simp only [id]
    field_simp
    rw [hsq]
    ring
  have hΨ : HasDerivAt (fun u => ∫ v in (0 : ℝ)..u, exp (-v ^ 2 / 2))
      (exp (-(s / √(1 + T * s ^ 2)) ^ 2 / 2)) (s / √(1 + T * s ^ 2)) :=
    (Continuous.integral_hasStrictDerivAt (by fun_prop) 0 _).hasDerivAt
  refine (hΨ.comp s hu).congr_deriv ?_
  rw [div_pow, hsq]
  field_simp

lemma tendsto_div_sqrt_one_add (T : ℝ) (hT : 0 < T) :
    Tendsto (fun s => s / √(1 + T * s ^ 2)) atTop (𝓝 (1 / √T)) := by
  have key : ∀ s : ℝ, 0 < s → s / √(1 + T * s ^ 2) = √((T + (s ^ 2)⁻¹)⁻¹) := by
    intro s hs
    have h : 1 + T * s ^ 2 = s ^ 2 * (T + (s ^ 2)⁻¹) := by field_simp; ring
    rw [h, Real.sqrt_mul (sq_nonneg s), Real.sqrt_sq hs.le, Real.sqrt_inv]
    have : 0 < √(T + (s ^ 2)⁻¹) := Real.sqrt_pos.2 (by positivity)
    field_simp
  have hlim : Tendsto (fun s : ℝ => √((T + (s ^ 2)⁻¹)⁻¹)) atTop (𝓝 (√((T + 0)⁻¹))) := by
    refine Tendsto.sqrt (Tendsto.inv₀ ?_ (by simp [hT.ne']))
    exact tendsto_const_nhds.add
      (tendsto_inv_atTop_zero.comp (tendsto_pow_atTop two_ne_zero))
  rw [add_zero, Real.sqrt_inv, ← one_div] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with s hs
  exact (key s hs).symm

lemma integral_Ioi_weight (T : ℝ) (hT : 0 < T) :
    IntegrableOn (fun s => exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2)
        / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))) (Set.Ioi 0) ∧
    ∫ s in Set.Ioi (0 : ℝ), exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2)
        / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))
      = ∫ v in (0 : ℝ)..(1 / √T), exp (-v ^ 2 / 2) := by
  have hderiv := hasDerivAt_normal_primitive_comp T hT.le
  have hΨc : Continuous fun u => ∫ v in (0 : ℝ)..u, exp (-v ^ 2 / 2) :=
    continuous_iff_continuousAt.2 fun u =>
      (Continuous.integral_hasStrictDerivAt (by fun_prop) 0 u).hasDerivAt.continuousAt
  have hlim : Tendsto (fun s => ∫ v in (0 : ℝ)..(s / √(1 + T * s ^ 2)), exp (-v ^ 2 / 2))
      atTop (𝓝 (∫ v in (0 : ℝ)..(1 / √T), exp (-v ^ 2 / 2))) :=
    (hΨc.tendsto _).comp (tendsto_div_sqrt_one_add T hT)
  have hcont : ContinuousWithinAt
      (fun s => ∫ v in (0 : ℝ)..(s / √(1 + T * s ^ 2)), exp (-v ^ 2 / 2)) (Set.Ici 0) 0 :=
    (hderiv 0).continuousAt.continuousWithinAt
  have hpos : ∀ s ∈ Set.Ioi (0 : ℝ), 0 ≤ exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2)
      / ((1 + T * s ^ 2) * √(1 + T * s ^ 2)) := fun s _ => by positivity
  refine ⟨integrableOn_Ioi_deriv_of_nonneg hcont (fun s _ => hderiv s) hpos hlim, ?_⟩
  rw [integral_Ioi_of_hasDerivAt_of_nonneg hcont (fun s _ => hderiv s) hpos hlim]
  simp

lemma one_div_sqrt_eq_integral_Ioi (q : ℝ) (hq : 0 ≤ q) :
    1 / √q = 2 / √(2 * π) * ∫ s in Set.Ioi (0 : ℝ), exp (-(q / 2) * s ^ 2) := by
  rw [integral_gaussian_Ioi]
  rcases hq.eq_or_lt with h | h
  · subst h; simp
  · have h1 : π / (q / 2) = (2 * π) / q := by field_simp
    rw [h1, Real.sqrt_div (by positivity)]
    have : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
    have : 0 < √q := Real.sqrt_pos.2 h
    field_simp

lemma two_cdf_standard_normal_sub_one (y : ℝ) :
    2 * cdf (gaussianReal 0 1) y - 1 = 2 / √(2 * π) * ∫ v in (0 : ℝ)..y, exp (-v ^ 2 / 2) := by
  have hφ : ∀ x, gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
    intro x
    simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  have hcdf : cdf (gaussianReal 0 1) y = ∫ x in Set.Iic y, gaussianPDFReal 0 1 x := by
    rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
      ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
        (fun x _ => gaussianPDFReal_nonneg 0 1 x))]
  have hint := integrable_gaussianPDFReal 0 1
  have hsplit := intervalIntegral.integral_Iic_sub_Iic (f := gaussianPDFReal 0 1) (a := 0)
    (b := y) (μ := volume) hint.integrableOn hint.integrableOn
  have hhalf : ∫ x in Set.Iic (0 : ℝ), gaussianPDFReal 0 1 x = 1 / 2 := by
    have heven : (fun x => gaussianPDFReal 0 1 x) = fun x => gaussianPDFReal 0 1 (-x) := by
      funext x; simp only [hφ, even_two, Even.neg_pow]
    rw [heven, integral_comp_neg_Iic, neg_zero]
    simp_rw [hφ]
    rw [integral_const_mul]
    have he : (fun x : ℝ => exp (-x ^ 2 / 2)) = fun x => exp (-(1 / 2) * x ^ 2) := by
      funext x; ring_nf
    rw [he, integral_gaussian_Ioi]
    have h1 : π / (1 / 2) = 2 * π := by field_simp
    rw [h1]
    have : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
    field_simp
  rw [hcdf, ← sub_add_cancel (∫ x in Set.Iic y, gaussianPDFReal 0 1 x)
    (∫ x in Set.Iic (0 : ℝ), gaussianPDFReal 0 1 x), hsplit, hhalf]
  simp_rw [hφ]
  rw [intervalIntegral.integral_const_mul]
  have : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
  field_simp
  ring

end NovikovHelpers2

/-- **Tilt C leaks (Step 5 and its fold).** For the tilt `θ_t = -Z_t`, so `dZ_t = Z_t² dW_t`
from `Z_0 = 1`, the weight at horizon `T` has the law of `1 / |(1, 0, 0) + G|`, where `G` is
three independent normal draws with mean 0 and variance `T` (the three-dimensional Bessel
picture the code uses; that identification is cited on the card, not proved here). Its average
is `2 Φ(1/√T) - 1`, which is below 1: at `T = 1` it is 0.682689, and 0.317311 of the
probability has leaked. Here `Φ` is the standard normal cumulative distribution function. -/
theorem self_feeding_tilt_average (T : ℝ≥0) (hT : 0 < T) :
    ∫ x, 1 / √((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2)
        ∂(Measure.pi fun _ : Fin 3 => gaussianReal 0 T)
      = 2 * cdf (gaussianReal 0 1) (1 / √(T : ℝ)) - 1 := by
  have hT0 : T ≠ 0 := hT.ne'
  have hTr : (0 : ℝ) < T := hT
  have h1 : ∀ x : Fin 3 → ℝ, 1 / √((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2)
      = 2 / √(2 * π) * ∫ s in Set.Ioi (0 : ℝ),
          exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2) :=
    fun x => one_div_sqrt_eq_integral_Ioi _ (by positivity)
  simp_rw [h1]
  rw [integral_const_mul]
  have hW := integral_Ioi_weight (T : ℝ) hTr
  have hint : Integrable (Function.uncurry fun (x : Fin 3 → ℝ) (s : ℝ) =>
      exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2))
      ((Measure.pi fun _ : Fin 3 => gaussianReal 0 T).prod
        ((volume : Measure ℝ).restrict (Set.Ioi 0))) := by
    have hc : Continuous (Function.uncurry fun (x : Fin 3 → ℝ) (s : ℝ) =>
        exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)) := by
      unfold Function.uncurry; fun_prop
    rw [integrable_prod_iff' hc.aestronglyMeasurable]
    refine ⟨ae_of_all _ fun s => ?_, ?_⟩
    · refine Integrable.of_bound (by fun_prop : Continuous fun x : Fin 3 → ℝ =>
        exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)).aestronglyMeasurable 1
        (ae_of_all _ fun x => ?_)
      simp only [Function.uncurry_apply_pair]
      rw [Real.norm_of_nonneg (exp_pos _).le, exp_le_one_iff]
      have : 0 ≤ ((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2 * s ^ 2 := by positivity
      linarith
    · simp only [Function.uncurry_apply_pair, Real.norm_of_nonneg (exp_pos _).le,
        integral_exp_neg_half_sq_pi T hT0]
      exact hW.1
  rw [integral_integral_swap hint]
  simp_rw [integral_exp_neg_half_sq_pi T hT0]
  rw [hW.2, two_cdf_standard_normal_sub_one]

/-! The card's exact worked arithmetic and the proof's algebra. -/

-- Tilt A, the share: θ = (μ - r)/σ = (0.08 - 0.05)/0.20 = 0.15.
example : ((8 : ℚ) / 100 - 5 / 100) / (20 / 100) = 15 / 100 := by norm_num
-- Its square 0.0225, and half the total squared tilt over T = 1 year, 0.01125.
example : ((15 : ℚ) / 100) ^ 2 = 225 / 10000 := by norm_num
example : (225 : ℚ) / 10000 * 1 / 2 = 1125 / 100000 := by norm_num
-- Drift under Q: μ - σ θ = 0.08 - 0.20 × 0.15 = 0.05.
example : (8 : ℚ) / 100 - 20 / 100 * (15 / 100) = 5 / 100 := by norm_num
-- Tilt C at one year: the leaked mass 1 - 0.682689 = 0.317311.
example : (1 : ℚ) - 682689 / 1000000 = 317311 / 1000000 := by norm_num
-- Tilt C without noise: dy = y³ dt from 1 gives y = 1/√(1 - 2t), which blows up at t = 1/2.
example : (1 : ℚ) - 2 * (1 / 2) = 0 := by norm_num
-- Step 5, Ito's lemma for R = 1/Z with dZ = Z² dW: the dW coefficient f'(z) z² is -1 and the
-- dt coefficient f''(z) (z²)² / 2 is z, so dR = -dW + Z dt.
example (z : ℝ) (hz : z ≠ 0) :
    -(1 / z ^ 2) * z ^ 2 = -1 ∧ 1 / 2 * (2 / z ^ 3) * (z ^ 2) ^ 2 = z := by
  constructor <;> field_simp
-- Detailed proof, point 2: Z^(λ) = Z^(λ²) e^(λ(1-λ)M), as an identity of exponents.
example (lam M A : ℝ) :
    lam * M - lam ^ 2 * A / 2 = lam ^ 2 * (M - A / 2) + lam * (1 - lam) * M := by ring
-- Point 3: γ = λ(1-λ)/(1-λ²) = λ/(1+λ), and γ(1-λ²) = λ(1-λ), for 0 < λ < 1.
example (lam : ℝ) (h0 : 0 < lam) (h1 : lam < 1) :
    lam * (1 - lam) / (1 - lam ^ 2) = lam / (1 + lam) := by
  have h2 : (1 - lam ^ 2) ≠ 0 := by nlinarith
  have h3 : (1 + lam) ≠ 0 := by linarith
  field_simp
  ring
example (lam : ℝ) (h1 : lam < 1) (h0 : 0 < lam) :
    lam / (1 + lam) * (1 - lam ^ 2) = lam * (1 - lam) := by
  have h3 : (1 + lam) ≠ 0 := by linarith
  field_simp
  ring
-- Tilt B: with a = c/2, b = c²/2, κ = √(2b) = c, the Cameron-Martin bracket is
-- cosh cT + sinh cT = e^(cT), so E[Z_T] = e^(cT/2) e^(-cT/2) = 1.
example (x : ℝ) : cosh x + sinh x = exp x := by rw [cosh_add_sinh]
example (x : ℝ) : exp (x / 2) * exp (-(x / 2)) = 1 := by rw [← exp_add]; simp

#print axioms nonneg_localMart_lintegral_le
#print axioms nonneg_localMart_supermartingale
#print axioms supermartingale_stopped_martingale
#print axioms stronglyMeasurable_integral_sq_of_slice
#print axioms stronglyAdapted_exp_weight
#print axioms integral_exp_neg_mul_sq_add_gaussianReal
#print axioms integral_exp_neg_half_sq_pi
#print axioms hasDerivAt_normal_primitive_comp
#print axioms tendsto_div_sqrt_one_add
#print axioms integral_Ioi_weight
#print axioms one_div_sqrt_eq_integral_Ioi
#print axioms two_cdf_standard_normal_sub_one
#print axioms exponential_weight_supermartingale
#print axioms self_feeding_tilt_average
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'nonneg_localMart_lintegral_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'nonneg_localMart_supermartingale' depends on axioms: [propext, Classical.choice, Quot.sound]
'supermartingale_stopped_martingale' depends on axioms: [propext, Classical.choice, Quot.sound]
'stronglyMeasurable_integral_sq_of_slice' depends on axioms: [propext, Classical.choice, Quot.sound]
'stronglyAdapted_exp_weight' depends on axioms: [propext, Classical.choice, Quot.sound]
'integral_exp_neg_mul_sq_add_gaussianReal' depends on axioms: [propext, Classical.choice, Quot.sound]
'integral_exp_neg_half_sq_pi' depends on axioms: [propext, Classical.choice, Quot.sound]
'hasDerivAt_normal_primitive_comp' depends on axioms: [propext, Classical.choice, Quot.sound]
'tendsto_div_sqrt_one_add' depends on axioms: [propext, Classical.choice, Quot.sound]
'integral_Ioi_weight' depends on axioms: [propext, Classical.choice, Quot.sound]
'one_div_sqrt_eq_integral_Ioi' depends on axioms: [propext, Classical.choice, Quot.sound]
'two_cdf_standard_normal_sub_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'exponential_weight_supermartingale' depends on axioms: [propext, Classical.choice, Quot.sound]
'self_feeding_tilt_average' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Guess first: add `16.0` to tilt C's horizons `tc`.** Does the leak ever stop? The new point on the `chart, C E[Z_T]` row is 0.20, after 0.52 at 2 years and 0.28 at 8. The leak never stops, because a Brownian motion from 1 reaches 0 eventually with certainty.
> - **Guess first: set `c = 0.5` in the B block.** The Novikov horizon $\pi/(2c)$ doubles to 3.141593 years and the grid first fails at T = 3.15. Both roads now give a finite Novikov average at T = 2, 1.360447 by the formula and 1.360778 on the grid of 1600 steps, and every assert still passes: the test now certifies 2 years.
> - **Guess first: drop the 1/2 from tilt A's weight**, using `exp(-th * sqrt(T) * g)`. The simulated mean becomes $e^{0.01125}$ instead of 1 and the first assert fails.
> - **Guess first: set `R0 = 0.5` in the C block** (`r0` in Rust). That starts tilt C's weight at $Z_0 = 1/R_0 = 2$ and divides the weight by it. The reciprocal starts nearer 0, the Brownian motion reaches it sooner, and more mass leaks: the formula becomes $2\Phi(R_0/\sqrt{T}) - 1$ = 0.382925 at one year, the lattice and the simulation (0.3825, standard error 0.0006) follow it, and every assert still passes.

---

## The usual mistake

> [!warning]
> **"The weight has no dt term, so it is a martingale."** No dt term makes the weight a local martingale: fair up to every cap. A true martingale needs the caps to be removable without losing average, and a tilt that feeds on the weight removes 0.317311 of it in one year. Check Novikov, or find the Q-dynamics and check they do not blow up.
>
> - **Reading Novikov as an "if and only if".** Tilt B fails it from 1.570796 years on and its weights average 1 at every horizon.
> - **Trusting a grid.** The grid version of tilt C's weight, multiplied step by step by $e^{Z\Delta W - Z^2\Delta t/2}$, where $\Delta W$ is the path's move over a grid step of length $\Delta t$, is an exact martingale on the grid, with average 1 at every step size. The leak appears only in the limit. Tilt C's simulation samples the exact weight, which is why it can find 0.6814.
> - **Rescaling a leaky Q to total 1.** The total is fixed; the Brownian property of $\widetilde W$ is not, and every price computed under it is off.
> - **Weakening the 1/2 inside Novikov's exponential.** The 1/2 is sharp: for any smaller constant in front there are tilts that pass the weakened test and whose weights still leak.

---

## Where you meet it in real life

- **Black-Scholes pricing.** The share's constant tilt passes in one line, which is why [Black–Scholes call](../../12-Financial%20mathematics/08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md) can switch from 8 percent to 5 percent without a second thought.
- **Stochastic volatility and short-rate models.** The market price of risk, the tilt $\theta_t$, depends on the state, Novikov's average is often infinite, and modellers prove the weights are a martingale by the direct route of Step 6 instead.
- **Price bubbles.** The process $dZ_t = Z_t^2\,dW_t$ is the standard example of a strict local martingale: a local martingale that is not a true martingale. Used as a price under a risk-neutral measure (a pricing world Q like the trader's), it is a price that is fair over each instant yet expected to fall: the textbook model of a bubble.
- **Importance sampling.** Simulating under a tilted measure and multiplying by the weight is unbiased only if the weights average 1; a leaking tilt biases every estimate low.

> **Say it back**
> Girsanov's weights are always fair over each instant and always average at most one. They average exactly one when e to the half the total squared tilt has a finite average: that is Novikov's condition. A tilt that feeds on the weight breaks it, and the weights average $2\Phi(1/\sqrt{T}) - 1$, which is 0.68 after one year. The missing mass rides on ever rarer, ever heavier paths and vanishes with them. The test is sufficient, not necessary: a tilt that grows only with the path's size fails it and is still safe.

---

## What this builds on

- [Girsanov](02-girsanov-theorem.md): the weight process and the shifted Brownian motion this card certifies.
- [Brownian martingales](../05-Brownian%20Motion/06-brownian-martingales-and-exponential-martingale.md): the constant-tilt case, a true martingale by a direct Gaussian average.
- [Stopping without a bound](../02-Martingales/06-uniform-integrability-and-unbounded-stopping.md): why a fair game can lose its average at the limit.
- [Ito's lemma](../06-Ito%20Calculus/02-itos-lemma.md): the reciprocal $1/Z$ and the integral of W against itself.

---

## Where this goes next

- [Martingale representation](04-martingale-representation-theorem.md): every Q-martingale is an Ito integral, which turns a certified change of measure into a hedge.
- [Change of numeraire](05-change-of-numeraire.md): weights built from a traded asset's price, where the martingale property is the asset's own fairness.

With the weights certified, the open question is what the reweighted world buys: which payoffs can be built from the share and cash, and at what cost.

---

## Sources

Verified 2026-10-06: every link below resolves to the publisher's page naming the cited work; both DOIs checked against Crossref.

- Novikov, A. A. "On an Identity for Stochastic Integrals." *Theory of Probability and Its Applications* 17, no. 4 (1972; English edition issued 1973): 717–720. [doi:10.1137/1117088](https://doi.org/10.1137/1117088). The condition, in the original.
- Karatzas, I., and S. E. Shreve. *Brownian Motion and Stochastic Calculus*, 2nd ed. Springer, Graduate Texts in Mathematics 113. [Springer](https://link.springer.com/book/10.1007/978-1-4612-0949-2). Section 3.5: Girsanov, Novikov's condition and Beneš's linear-growth condition.
- Revuz, D., and M. Yor. *Continuous Martingales and Brownian Motion*, 3rd ed. Springer, Grundlehren 293. [Springer](https://link.springer.com/book/10.1007/978-3-662-06400-9). Chapter VIII: the Hölder proof of Novikov's criterion via Kazamaki's; chapter XI: Bessel processes.
- Cameron, R. H., and W. T. Martin. "Transformations of Wiener Integrals under a General Class of Linear Transformations." *Transactions of the American Mathematical Society* 58 (1945): 184–219. [doi:10.1090/S0002-9947-1945-0013240-1](https://doi.org/10.1090/S0002-9947-1945-0013240-1). The Gaussian average of $\exp(-b\int W^2)$ used for tilt B.
