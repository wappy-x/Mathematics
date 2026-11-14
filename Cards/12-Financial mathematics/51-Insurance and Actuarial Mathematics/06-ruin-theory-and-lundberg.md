# Ruin: the chance an insurer's surplus ever goes below zero

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Insurance and Actuarial Mathematics](../README.md#s51) → Ruin

---

## General Overview

A small insurer opens its doors with \$1 million in the bank. It expects 10 claims a year, and a claim costs \$10,000 on average. So it expects to pay \$100,000 a year. It charges \$110,000 a year in premiums: 10% more than the claims it expects. That extra 10% is the **safety loading**.

On average, the bank balance climbs by \$10,000 a year. But claims do not arrive on average. They arrive at random, in random sizes. A bad run early on could empty the account before the loading has time to pile up. The question is how likely that is, with no end date: the chance the balance *ever*, in all future time, drops below zero.

That event is called **ruin**. The money in the bank, premiums in minus claims out, is the **surplus**. The answer for this insurer is about 0.01%: roughly one chance in ten thousand. The card derives a single number, the **adjustment coefficient**, from the claim pattern and the premium. Every extra \$110,000 of starting surplus then divides the chance of ruin by e, about 2.72. That exponential shield is **Lundberg's inequality**, found by Filip Lundberg in 1903 and made rigorous by Harald Cramér around 1930.

**The chance of ruin is at most e to the minus (adjustment coefficient times starting surplus), where the adjustment coefficient is the one rate at which exponential claim growth exactly balances premium income.**

**What kind of fact this is:** a model — claims are *taken* to arrive like a Poisson stream (one at a time, at random moments, at a steady average rate) with independent sizes, an assumption that fits some portfolios well and storms badly — and, inside it, a theorem: Lundberg's inequality, proved on this card in Why it works.

### The picture: ruin chance against starting surplus

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Chance of ever going below zero: 10 claims a year, mean $10,000, 10% loading"
    x-axis "Starting surplus ($ thousands)" [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
    y-axis "Chance of ruin (%)" 0 --> 100
    line [100.00, 40.29, 16.23, 6.54, 2.63, 1.06, 0.43, 0.17, 0.07, 0.03, 0.01]
    line [90.91, 36.63, 14.76, 5.95, 2.40, 0.97, 0.39, 0.16, 0.06, 0.03, 0.01]
    line [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
```

Top line, orange: Lundberg's upper bound. Middle line, green: the exact ruin chance, which this claim pattern allows in closed form. Flat line, dark: a 1% target. Both curves fall by the same factor for every \$100,000 added; the bound sits 10% above the exact value all the way along. The bound drops under 1% between \$500,000 and \$600,000 of surplus. At \$1 million both read 0.01%.

---

## The formula

Notation first, in words. The surplus at time $t$ years is $U_t$. The number of claims so far is $N_t$. The claims themselves are $X_1, X_2, \ldots$, each a random dollar amount. The **Cramér–Lundberg model** says

$$U_t = u + c\,t - \sum_{i=1}^{N_t} X_i .$$

**Read it aloud:** the surplus now is the starting money, plus premiums collected so far, minus every claim paid so far.

Between claims the surplus climbs in a straight line at $c$ dollars a year. At each claim it drops by that claim's size. Ruin happens at the first time $\tau$ that $U_t$ falls below zero. The **ruin probability** $\psi(u)$ ("psi of u") is the chance that $\tau$ ever arrives.

The adjustment coefficient $R$ is the positive number that solves

$$\lambda\,\bigl(M_X(R) - 1\bigr) = c\,R, \qquad M_X(r) = E\!\left[e^{rX}\right].$$

**Read it aloud:** at the rate $R$, the yearly growth that random claims give an exponential of the claim total exactly cancels the shrinkage that steady premiums give it.

Lundberg's inequality is then

$$\psi(u) \le e^{-R u}.$$

**Read it aloud:** the chance of ever being ruined is at most e raised to minus the adjustment coefficient times the starting surplus.

| Symbol | Plain meaning | In our example | Push it up and the ruin chance… |
| --- | --- | --- | --- |
| $U_t$, $t$, $s$ | surplus at time $t$ years; $s$ is an earlier time | starts at \$1,000,000 | — |
| $u$ | starting surplus, dollars | \$1,000,000 | falls, exponentially |
| $c$ | premium income, dollars a year | \$110,000 | falls |
| $\lambda$, $N_t$, $T_i$, $i$, $n$ | claims a year (say "lambda"); claims counted up to time $t$; arrival time of claim $i$; a claim count | 10 | rises, if premium stays fixed |
| $X$, $\mu$ | one claim's size; its average (say "mu") | exponential, mean \$10,000 | rises |
| $\theta$ | safety loading: $c = (1+\theta)\lambda\mu$ (say "theta") | 10% | falls |
| $\tau$ | time of ruin; infinite if ruin never comes (say "tau") | — | — |
| $\psi(u)$ | chance that ruin ever comes | 0.0102% exact | — |
| $M_X(r)$, $r$ | the claim's **moment generating function**: the average of $e^{rX}$, at a rate $r$ per dollar | $1/(1-\mu r)$ | — |
| $\kappa(r)$ | $\lambda(M_X(r)-1) - c\,r$: net yearly growth rate of the exponential score (say "kappa") | 0 at $r = R$ | — |
| $R$ | adjustment coefficient, per dollar | 1/110,000, or 9.0909 per \$1M | falls as $R$ rises |
| $Z_t$, $Z_s$ | $e^{-R U_t}$: the score that stays fair on average | $e^{-9.0909}$ at the start | — |

For exponential claims, the kind in the example, the equation solves by hand:

$$R = \frac{\theta}{(1+\theta)\,\mu}, \qquad \psi(u) = \frac{1}{1+\theta}\,e^{-R u}.$$

In words: the adjustment coefficient is the loading's share of the premium, per dollar of average claim. And the exact ruin chance is the bound times $1/(1+\theta)$.

### When it holds

- **Claims arrive as a Poisson stream, sizes independent of each other and of the timing.** A hurricane files thousands of linked claims in a day. Clustering like that raises the true ruin chance, and the bound computed from the unclustered model can fall below it.
- **Light tails: $M_X(r)$ is finite for some positive $r$, and far enough out for the claims side of the equation to overtake the premium side.** Claims with a power-law tail, such as a Pareto distribution, make $M_X(r)$ infinite for every positive $r$. There is no $R$, and ruin then fades like a power of $u$, far more slowly than any exponential.
- **A positive loading, $c > \lambda\mu$.** With no loading the surplus has no upward pull and ruin is certain: $\psi(u) = 1$ at every $u$.
- **Nothing else moves the money.** No interest earned, no expenses, no dividends paid out, premiums fixed forever. Interest on the surplus lowers ruin; paying out every dollar above a ceiling makes ruin certain.
- **Forever is the horizon.** The bound covers all future time, so it also caps the chance of ruin within any fixed number of years.

---

## Why it works

### Step 0: find a score that is fair, then a fair score rarely climbs high

The surplus drifts upward, so it is not a fair game. The trick is to find a transformation of it that *is* fair: a quantity whose expected future value always equals its value today. That kind of quantity is a **martingale** ([Martingales](../../11-Stochastic%20processes%20and%20calculus/02-Martingales/01-martingales.md)). Take $Z_t = e^{-r U_t}$ for some rate $r$. When the surplus is high, $Z_t$ is tiny. When the surplus goes below zero, $Z_t$ exceeds 1. A fair, never-negative score that starts at $e^{-ru}$ can reach 1 with chance at most $e^{-ru}$: on average it cannot gain, and reaching 1 would be a gain. So the whole job is to find the $r$ that makes $Z_t$ fair.

### Step 1: how an exponential of the claims grows

Write the claims paid by time $t$ as a sum. For a fixed rate $r$, the average of $e^{r \times (\text{claims} - \text{premiums})}$ over $t$ years is

$$E\!\left[e^{\,r\left(\sum_{i \le N_t} X_i \,-\, c\,t\right)}\right] = e^{\,t\,\kappa(r)}, \qquad \kappa(r) = \lambda\bigl(M_X(r)-1\bigr) - c\,r .$$

Each claim multiplies the exponential by $e^{rX}$, whose average is $M_X(r)$. The number of claims is Poisson with mean $\lambda t$, and averaging a Poisson number of such factors gives $e^{\lambda t (M_X(r)-1)}$. The premiums contribute $e^{-crt}$ and are not random. Aggregate claims as a random sum are built on [Aggregate claims](04-collective-risk-and-compound-poisson.md).

<details>
<summary>The algebra behind this</summary>

Given exactly $n$ claims, the sizes are independent, so the average of $e^{r(X_1 + \cdots + X_n)}$ is $M_X(r)^n$. The chance of $n$ claims is $e^{-\lambda t}(\lambda t)^n / n!$. Sum over $n$:
$$e^{-\lambda t}\sum_{n \ge 0}\frac{(\lambda t\, M_X(r))^n}{n!} = e^{-\lambda t}\,e^{\lambda t M_X(r)} = e^{\lambda t (M_X(r) - 1)}.$$
Multiply by $e^{-crt}$ for the premiums. The exponent is $t\,\kappa(r)$.

</details>

### Step 2: the adjustment coefficient is where the growth rate is zero

If $\kappa(r) = 0$, the exponential neither grows nor shrinks on average. That rate is $R$. Now check that exactly one positive $R$ exists. This is an inverse problem, so existence, uniqueness and the boundary cases come first.

- **At $r = 0$:** $M_X(0) = 1$, so $\kappa(0) = 0$. Zero is always a root, and it is useless: it gives the bound $e^0 = 1$.
- **Just above zero:** the slope of $\kappa$ at 0 is $\lambda\mu - c = -\theta\lambda\mu$, negative whenever there is a loading. So $\kappa$ dips below zero first.
- **Further out:** $M_X(r)$ curves upward faster and faster (it is **convex**: its slope only increases), so $\kappa$ does too. For exponential claims $M_X(r) = 1/(1-\mu r)$ shoots to infinity as $r$ nears $1/\mu$. So $\kappa$ comes back up through zero, once.
- **Boundaries:** with $\theta = 0$ the dip never happens and the only root is 0. With a heavy tail, $M_X(r)$ is infinite past 0 and there is nowhere for the second root to live. In between, some claim laws have $M_X$ finite only up to an edge where $\kappa$ is still negative; then no $R$ exists either. The general rule, given a loading: a positive $R$ exists when $\kappa(r) > 0$ at some $r$ where $M_X(r)$ is finite.

A convex curve that starts at zero, dips, and climbs to infinity crosses zero exactly once more. That crossing is $R$.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The two sides of the adjustment equation"
    x-axis "Rate r (per $1 million)" [0, 2, 4, 6, 8, 10, 12, 14]
    y-axis "Yearly rate" 0 --> 1.7
    line [0.00, 0.20, 0.42, 0.64, 0.87, 1.11, 1.36, 1.63]
    line [0.00, 0.22, 0.44, 0.66, 0.88, 1.10, 1.32, 1.54]
```

Orange: the claims side, $\lambda(M_X(r)-1)$, which bends upward. Green: the premium side, $c\,r$, a straight line. Both start at 0. The straight line is ahead at first, because premiums exceed expected claims. The curve catches it between 8 and 10 per million: at $R$ = 9.0909 per million, where both equal 1.

### Step 3: solve it for exponential claims

With $M_X(r) = 1/(1-\mu r)$ and $c = (1+\theta)\lambda\mu$, the equation reads $\lambda\mu r/(1-\mu r) = (1+\theta)\lambda\mu r$. Divide by $\lambda\mu r$, allowed since the root sought is not zero: $1/(1-\mu r) = 1+\theta$. So $\mu R = \theta/(1+\theta)$. With a 10% loading, $\mu R = 1/11$: the length $1/R$ is eleven average claims, \$110,000.

### Step 4: with that rate, the score is fair

Set $Z_t = e^{-R U_t}$. Over any stretch from time $s$ to time $t$, the new claims and premiums are independent of everything before $s$, because Poisson arrivals and independent sizes forget the past. So the expected $Z_t$, given all history to time $s$, is $Z_s$ times the growth factor from Step 1 over that stretch, which is $e^{(t-s)\kappa(R)} = 1$. The score is a martingale: fair, and never negative.

### Step 5: stop the game at ruin, and read off the bound

A fair game stays fair if it is stopped by a rule that looks only at the past and acts before a fixed deadline. That is the **optional stopping theorem** for bounded stopping times, from [Martingales](../../11-Stochastic%20processes%20and%20calculus/02-Martingales/01-martingales.md). Stop at ruin or at year $t$, whichever comes first. Then

$$e^{-Ru} = E\bigl[Z_{\min(\tau, t)}\bigr] \ge E\bigl[Z_\tau \text{ on ruin by } t\bigr] \ge \Pr(\tau \le t).$$

The first inequality drops the paths not ruined by $t$, where $Z$ is still positive. The second uses that at ruin the surplus is below zero, so $Z_\tau > 1$. Let $t$ run to infinity: the chance of ruin by $t$ climbs to $\psi(u)$, and the bound holds at every step. So $\psi(u) \le e^{-Ru}$.

<details>
<summary>Detailed proof</summary>

Let $\mathcal{F}_s$ be the history of arrival times and claim sizes up to time $s$. The claim total over $(s, t]$ is a compound Poisson sum with count mean $\lambda(t-s)$, independent of $\mathcal{F}_s$. Hence
$$E[Z_t \mid \mathcal{F}_s] = Z_s\, E\!\left[e^{R\left(\sum_{s < T_i \le t} X_i \,-\, c(t-s)\right)}\right] = Z_s\, e^{(t-s)\kappa(R)} = Z_s,$$
where $T_i$ is the arrival time of claim $i$. Each $Z_t$ has finite mean $e^{-Ru}$, so $Z$ is a nonnegative martingale. Ruin can only happen at a claim, since premiums only raise the surplus, and paths have finitely many claims in any bounded interval, so $\tau$ is a stopping time and $Z$ is right-continuous. For fixed $t$, $\min(\tau, t)$ is a bounded stopping time, and optional stopping gives $E[Z_{\min(\tau,t)}] = Z_0 = e^{-Ru}$. Split this mean over the events $\{\tau \le t\}$ and $\{\tau > t\}$. The second part is nonnegative. On the first, $U_\tau < 0$ strictly, so $Z_\tau = e^{-RU_\tau} > 1$. Therefore $\Pr(\tau \le t) < E[Z_\tau;\ \tau \le t] \le e^{-Ru}$. The events $\{\tau \le t\}$ increase with $t$ to $\{\tau < \infty\}$, so by continuity of probability $\psi(u) = \lim_{t \to \infty}\Pr(\tau \le t) \le e^{-Ru}$.

</details>

### Step 6: why the bound is not the answer

The bound throws away one thing: how far below zero the surplus lands at ruin. That shortfall is the **overshoot**. If ruin always happened exactly at zero, the bound would be exact. It never does, so the bound is always a little high.

For exponential claims the exact answer is known: $\psi(u) = e^{-Ru}/(1+\theta)$. It comes from the **Pollaczek–Khinchine formula**. Each time the surplus sets a new low, the chance it ever sets another is $1/(1+\theta)$, and for exponential claims each new low is an exponential drop of mean $\mu$. Ruin is the event that these record drops add up past $u$. The code sums that series directly as its second road to $\psi$. The formula is stated here without proof; Asmussen and Albrecher prove it (Sources). For other claim laws, Cramér showed $\psi(u)$ behaves like a constant times $e^{-Ru}$ once $u$ is large, so $R$ sets the rate of decay in general, not just a ceiling.

A second road to the inequality itself: Gerber's induction on the number of claims. The chance of ruin within the first $n$ claims is at most $e^{-Ru}$ for every $n$, proved by conditioning on the first claim and using $\kappa(R) = 0$; let $n$ grow. It avoids martingales entirely and is the proof in Dickson (Sources).

---

## Worked numbers, by hand

The insurer: starting surplus \$1,000,000, 10 claims a year, exponential claims with mean \$10,000, loading 10%.

| Step | Arithmetic | Value |
| --- | --- | --- |
| expected claims a year | 10 × \$10,000 | \$100,000 |
| premium $c$ | 1.10 × \$100,000 | \$110,000 |
| adjustment equation | 10 × (1/(1 − 10,000 R) − 1) = 110,000 R | — |
| divide by 100,000 R (the root is not 0) | 1/(1 − 10,000 R) = 1.1 | — |
| solve | 10,000 R = 1/11 | R = 1/110,000 per dollar |
| same thing per million | 1,000,000/110,000 | 9.0909 |
| check: $M_X(R)$ | 1/(1 − 1/11) | 1.1 |
| exponent $R \times u$ | 1,000,000/110,000 | 9.0909 |
| Lundberg bound | $e^{-9.0909}$ | 0.000112686 |
| exact ruin chance | 0.000112686 / 1.1 | **0.000102441, about 0.0102%** |
| surplus for 1% by the bound | 110,000 × ln 100 | \$506,568.72 |
| surplus for 1% exactly | 110,000 × ln(100/1.1) | \$496,084.60 |

With \$1 million, the insurer's chance of ever being ruined is about one in ten thousand, well under 1%. About half that money, \$496,084.60, would already have met a 1% target. The bound is the safe side of the truth: planning with it asks for \$10,484.12 more than needed.

### What breaks if you drop a piece

Same insurer, right answer 0.0102% (bound 0.0113%):

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Take the root $R = 0$ | bound 1.000000000, i.e. 100% | Zero always solves the equation. It says ruin is at most certain: nothing. |
| Charge no loading, $\theta = 0$ | exact ruin 100% | No upward pull. The surplus wanders like a fair coin and hits zero eventually. |
| Use only the claims' mean and variance | R = 10 per \$1M; bound 0.0000454 | This "diffusion" shortcut, 2(c − λμ)/(λ E[X^2]), ignores the tail beyond the variance. The "bound" lands below the true 0.0102%: it is no longer a bound. |
| Same 10% loading, claims ten times bigger (\$100,000 mean) | bound 40.29%, exact 36.63% | The loading is a percentage; ruin depends on surplus measured in average claims. \$1M is now ten claims, not a hundred. |

Every number in that table is printed by the code below.

---

## Code, from first principles, and it actually runs

The code reaches the adjustment coefficient two ways: the closed form, and a bisection root finder on $\kappa$ with $M_X$ integrated numerically by Simpson's rule, so the hand-solved $1/(1-\mu r)$ never enters. It reaches the exact ruin chance two ways: the closed form, and the Pollaczek–Khinchine series summed term by term. For the \$100,000-claim case it adds a third road: 20,000 simulated surplus paths, claim by claim, driven by a hand-written random number generator. Each path stops at ruin or once the surplus passes \$11 million, where the chance of later ruin is below $e^{-10}$. Five asserts compare the roads. Each was mutation-tested: skewing the closed-form root, the series, the simulated claim size, or the exact formula makes an assert fail.

### Python

```python
# Ruin and Lundberg's inequality -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the integrator, the root finder, the series
# and the random numbers are all written out below.
from math import exp, log, sqrt

LAM, B, THETA, U = 10.0, 10_000.0, 0.10, 1_000_000.0   # claims a year, mean claim $, loading, surplus $
C = (1.0 + THETA) * LAM * B                            # premium income, $ a year

def mgf(r, b, n=20000):
    # Road 2 for M_X(r) = E[e^{rX}]: Simpson's rule on e^{rx} times the exponential density.
    k = 1.0 / b - r                                     # net decay rate of the integrand
    top = 60.0 / k                                      # e^{-60} of the mass lies beyond
    h = top / n
    f = lambda x: exp(r * x) * exp(-x / b) / b
    s = f(0.0) + f(top)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(i * h)
    return s * h / 3.0

def kappa(r, lam, b, c):                                # claims side minus premium side
    return lam * (mgf(r, b) - 1.0) - c * r

def bisect(g, lo, hi, iters=80):                        # g(lo) < 0 < g(hi)
    for _ in range(iters):
        mid = 0.5 * (lo + hi)
        if g(mid) < 0.0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def psi_exact(u, b, theta):                             # closed form, exponential claims
    return exp(-theta * u / ((1.0 + theta) * b)) / (1.0 + theta)

def psi_series(u, b, theta, nmax=3000):
    # Road 2 for psi: Pollaczek-Khinchine.  Ruin = the record drops add past u.
    # A record drop happens with chance p = 1/(1+theta); for exponential claims each
    # drop is exponential with mean b, so n drops exceed u with an Erlang tail.
    p, x = 1.0 / (1.0 + theta), u / b
    pois, tail, pn, total = exp(-x), 0.0, 1.0, 0.0
    for n in range(1, nmax + 1):
        tail += pois                                    # P(n drops > u) = sum_{k<n} e^-x x^k/k!
        pois *= x / n
        pn *= p
        total += (1.0 - p) * pn * tail
    return total

MASK = (1 << 64) - 1
def uniforms(seed):                                     # xorshift64*, written out
    s = seed
    while True:
        s ^= s >> 12; s ^= (s << 25) & MASK; s ^= s >> 27
        yield (((s * 0x2545F4914F6CDD1D) & MASK) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0

def psi_monte_carlo(u, lam, b, c, paths, cap, seed=20260928):
    # Road 3: run surplus paths claim by claim; stop at ruin or once surplus passes cap.
    g, ruined = uniforms(seed), 0
    for _ in range(paths):
        s = u
        while 0.0 <= s < cap:
            s += c * (-log(next(g)) / lam) + b * log(next(g))
        ruined += s < 0.0
    return ruined / paths

# ---- the adjustment coefficient, two roads ----
R1 = THETA / ((1.0 + THETA) * B)                        # closed form for exponential claims
R2 = bisect(lambda r: kappa(r, LAM, B, C), 1e-3 / B, 0.5 / B)
bound, exact, series = exp(-R1 * U), psi_exact(U, B, THETA), psi_series(U, B, THETA)
cap_bound = log(100.0) / R1
cap_exact = log(100.0 / (1.0 + THETA)) / R1
cap_series = bisect(lambda u: 0.01 - psi_series(u, B, THETA), 0.0, 2e6)

# ---- same 10% loading, claims ten times bigger ----
B2 = 100_000.0; C2 = (1.0 + THETA) * LAM * B2
bound2, exact2, series2 = exp(-THETA / ((1 + THETA) * B2) * U), psi_exact(U, B2, THETA), psi_series(U, B2, THETA)
N = 20000
mc2 = psi_monte_carlo(U, LAM, B2, C2, N, U + 10e6)
se2 = sqrt(mc2 * (1.0 - mc2) / N)

# ---- what breaks ----
R_diff = 2.0 * (C - LAM * B) / (LAM * 2.0 * B * B)     # mean-and-variance only: 2(c - lam mu)/(lam E[X^2])

assert abs(R2 / R1 - 1.0) < 1e-9, "root finder disagrees with closed form"
assert abs(series / exact - 1.0) < 1e-9 and abs(series2 / exact2 - 1.0) < 1e-9, "series disagrees"
assert abs(mc2 - exact2) < 4.0 * se2, "simulation disagrees with exact ruin chance"
assert exact < bound < 0.01 and exact2 < bound2, "Lundberg bound fails"
assert abs(cap_series / cap_exact - 1.0) < 1e-9, "capital by series disagrees"

rows = [
    ("R closed form, per $1M", R1 * 1e6), ("R bisection on Simpson MGF, per $1M", R2 * 1e6),
    ("1/R, dollars", 1.0 / R1), ("M_X(R)", mgf(R1, B)), ("R u", R1 * U),
    ("Lundberg bound e^-Ru", bound), ("exact psi, closed form", exact),
    ("exact psi, Pollaczek-Khinchine series", series), ("bound / exact", bound / exact),
    ("capital for 1%, by the bound $", cap_bound), ("capital for 1%, exact $", cap_exact),
    ("capital for 1%, series + bisection $", cap_series), ("extra capital, bound over exact $", cap_bound - cap_exact),
    ("mean $100k: R per $1M", THETA / ((1 + THETA) * B2) * 1e6), ("mean $100k: bound", bound2),
    ("mean $100k: exact, closed form", exact2), ("mean $100k: exact, series", series2),
    ("mean $100k: simulation, 20000 paths", mc2), ("mean $100k: simulation std error", se2),
    ("wrong: root R = 0, bound", exp(-0.0 * U)), ("wrong: no loading, exact psi", psi_exact(U, B, 0.0)),
    ("wrong: mean-variance R, per $1M", R_diff * 1e6), ("wrong: mean-variance bound", exp(-R_diff * U)),
    ("try: loading 20%, bound", exp(-0.2 / (1.2 * B) * U)), ("try: surplus $500k, bound", exp(-R1 * 500_000.0)),
    ("try: mean $50k, bound", exp(-THETA / ((1 + THETA) * 50_000.0) * U)),
    ("try: 20 claims/yr, premium x2, R per $1M", 1e6 * bisect(lambda r: kappa(r, 20.0, B, 2 * C), 1e-3 / B, 0.5 / B)),
]
for name, v in rows:
    print(f"{name:<42} {v:>16.9f}")

print()
print("chart: ruin chance in percent, surplus in $ thousands")
print(f"{'u':>6} {'bound %':>9} {'exact %':>9}")
for k in range(11):
    u = 100_000.0 * k
    print(f"{100 * k:>6} {100 * exp(-R1 * u):>9.2f} {100 * psi_exact(u, B, THETA):>9.2f}")
print()
print("chart: two sides of the adjustment equation, per year; r per $1M")
print(f"{'r':>6} {'claims':>9} {'premium':>9}")
for r in range(0, 15, 2):
    print(f"{r:>6} {LAM * (mgf(r / 1e6, B) - 1.0):>9.2f} {C * r / 1e6:>9.2f}")
print("ALL CHECKS PASS")
```

**Ran 2026-11-14 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
R closed form, per $1M                          9.090909091
R bisection on Simpson MGF, per $1M             9.090909090
1/R, dollars                               110000.000000000
M_X(R)                                          1.100000000
R u                                             9.090909091
Lundberg bound e^-Ru                            0.000112686
exact psi, closed form                          0.000102441
exact psi, Pollaczek-Khinchine series           0.000102441
bound / exact                                   1.100000000
capital for 1%, by the bound $             506568.720458690
capital for 1%, exact $                    496084.600680214
capital for 1%, series + bisection $       496084.600680214
extra capital, bound over exact $           10484.119778476
mean $100k: R per $1M                           0.909090909
mean $100k: bound                               0.402890322
mean $100k: exact, closed form                  0.366263929
mean $100k: exact, series                       0.366263929
mean $100k: simulation, 20000 paths             0.364100000
mean $100k: simulation std error                0.003402434
wrong: root R = 0, bound                        1.000000000
wrong: no loading, exact psi                    1.000000000
wrong: mean-variance R, per $1M                10.000000000
wrong: mean-variance bound                      0.000045400
try: loading 20%, bound                         0.000000058
try: surplus $500k, bound                       0.010615346
try: mean $50k, bound                           0.162320611
try: 20 claims/yr, premium x2, R per $1M        9.090909090

chart: ruin chance in percent, surplus in $ thousands
     u   bound %   exact %
     0    100.00     90.91
   100     40.29     36.63
   200     16.23     14.76
   300      6.54      5.95
   400      2.63      2.40
   500      1.06      0.97
   600      0.43      0.39
   700      0.17      0.16
   800      0.07      0.06
   900      0.03      0.03
  1000      0.01      0.01

chart: two sides of the adjustment equation, per year; r per $1M
     r    claims   premium
     0      0.00      0.00
     2      0.20      0.22
     4      0.42      0.44
     6      0.64      0.66
     8      0.87      0.88
    10      1.11      1.10
    12      1.36      1.32
    14      1.63      1.54
ALL CHECKS PASS
```

### Rust

```rust
// Ruin and Lundberg's inequality -- the check behind the card.  Rust std only.
// Nothing imported knows the answer: the integrator, the root finder, the series
// and the random numbers are all written out below.

const LAM: f64 = 10.0; // claims a year
const B: f64 = 10_000.0; // mean claim, dollars
const THETA: f64 = 0.10; // safety loading
const U: f64 = 1_000_000.0; // starting surplus, dollars

// Road 2 for M_X(r) = E[e^{rX}]: Simpson's rule on e^{rx} times the exponential density.
fn mgf(r: f64, b: f64) -> f64 {
    let n = 20000;
    let k = 1.0 / b - r; // net decay rate of the integrand
    let top = 60.0 / k; // e^{-60} of the mass lies beyond
    let h = top / n as f64;
    let f = |x: f64| (r * x).exp() * (-x / b).exp() / b;
    let mut s = f(0.0) + f(top);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h);
    }
    s * h / 3.0
}

fn kappa(r: f64, lam: f64, b: f64, c: f64) -> f64 {
    lam * (mgf(r, b) - 1.0) - c * r // claims side minus premium side
}

fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if g(mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn psi_exact(u: f64, b: f64, theta: f64) -> f64 {
    (-theta * u / ((1.0 + theta) * b)).exp() / (1.0 + theta) // closed form, exponential claims
}

// Road 2 for psi: Pollaczek-Khinchine. Ruin = the record drops add past u.
// A record drop happens with chance p = 1/(1+theta); for exponential claims each
// drop is exponential with mean b, so n drops exceed u with an Erlang tail.
fn psi_series(u: f64, b: f64, theta: f64) -> f64 {
    let (p, x) = (1.0 / (1.0 + theta), u / b);
    let (mut pois, mut tail, mut pn, mut total) = ((-x).exp(), 0.0, 1.0, 0.0);
    for n in 1..=3000 {
        tail += pois; // P(n drops > u) = sum_{k<n} e^-x x^k/k!
        pois *= x / n as f64;
        pn *= p;
        total += (1.0 - p) * pn * tail;
    }
    total
}

struct Rng(u64); // xorshift64*, written out
impl Rng {
    fn next(&mut self) -> f64 {
        let mut s = self.0;
        s ^= s >> 12; s ^= s << 25; s ^= s >> 27;
        self.0 = s;
        (s.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0
    }
}

// Road 3: run surplus paths claim by claim; stop at ruin or once surplus passes cap.
fn psi_monte_carlo(u: f64, lam: f64, b: f64, c: f64, paths: u32, cap: f64) -> f64 {
    let mut g = Rng(20260928);
    let mut ruined = 0u32;
    for _ in 0..paths {
        let mut s = u;
        while s >= 0.0 && s < cap {
            let wait = -g.next().ln() / lam;
            s += c * wait + b * g.next().ln();
        }
        if s < 0.0 { ruined += 1; }
    }
    ruined as f64 / paths as f64
}

fn main() {
    let c = (1.0 + THETA) * LAM * B; // premium income, $ a year
    // ---- the adjustment coefficient, two roads ----
    let r1 = THETA / ((1.0 + THETA) * B); // closed form for exponential claims
    let r2 = bisect(|r| kappa(r, LAM, B, c), 1e-3 / B, 0.5 / B);
    let (bound, exact, series) = ((-r1 * U).exp(), psi_exact(U, B, THETA), psi_series(U, B, THETA));
    let cap_bound = 100.0_f64.ln() / r1;
    let cap_exact = (100.0 / (1.0 + THETA)).ln() / r1;
    let cap_series = bisect(|u| 0.01 - psi_series(u, B, THETA), 0.0, 2e6);

    // ---- same 10% loading, claims ten times bigger ----
    let b2 = 100_000.0;
    let c2 = (1.0 + THETA) * LAM * b2;
    let bound2 = (-THETA / ((1.0 + THETA) * b2) * U).exp();
    let (exact2, series2) = (psi_exact(U, b2, THETA), psi_series(U, b2, THETA));
    let n = 20000u32;
    let mc2 = psi_monte_carlo(U, LAM, b2, c2, n, U + 10e6);
    let se2 = (mc2 * (1.0 - mc2) / n as f64).sqrt();

    // ---- what breaks ----
    let r_diff = 2.0 * (c - LAM * B) / (LAM * 2.0 * B * B); // mean-and-variance only

    assert!((r2 / r1 - 1.0).abs() < 1e-9, "root finder disagrees with closed form");
    assert!((series / exact - 1.0).abs() < 1e-9 && (series2 / exact2 - 1.0).abs() < 1e-9, "series disagrees");
    assert!((mc2 - exact2).abs() < 4.0 * se2, "simulation disagrees with exact ruin chance");
    assert!(exact < bound && bound < 0.01 && exact2 < bound2, "Lundberg bound fails");
    assert!((cap_series / cap_exact - 1.0).abs() < 1e-9, "capital by series disagrees");

    let rows: Vec<(&str, f64)> = vec![
        ("R closed form, per $1M", r1 * 1e6), ("R bisection on Simpson MGF, per $1M", r2 * 1e6),
        ("1/R, dollars", 1.0 / r1), ("M_X(R)", mgf(r1, B)), ("R u", r1 * U),
        ("Lundberg bound e^-Ru", bound), ("exact psi, closed form", exact),
        ("exact psi, Pollaczek-Khinchine series", series), ("bound / exact", bound / exact),
        ("capital for 1%, by the bound $", cap_bound), ("capital for 1%, exact $", cap_exact),
        ("capital for 1%, series + bisection $", cap_series), ("extra capital, bound over exact $", cap_bound - cap_exact),
        ("mean $100k: R per $1M", THETA / ((1.0 + THETA) * b2) * 1e6), ("mean $100k: bound", bound2),
        ("mean $100k: exact, closed form", exact2), ("mean $100k: exact, series", series2),
        ("mean $100k: simulation, 20000 paths", mc2), ("mean $100k: simulation std error", se2),
        ("wrong: root R = 0, bound", (-0.0 * U).exp()), ("wrong: no loading, exact psi", psi_exact(U, B, 0.0)),
        ("wrong: mean-variance R, per $1M", r_diff * 1e6), ("wrong: mean-variance bound", (-r_diff * U).exp()),
        ("try: loading 20%, bound", (-0.2 / (1.2 * B) * U).exp()), ("try: surplus $500k, bound", (-r1 * 500_000.0).exp()),
        ("try: mean $50k, bound", (-THETA / ((1.0 + THETA) * 50_000.0) * U).exp()),
        ("try: 20 claims/yr, premium x2, R per $1M", 1e6 * bisect(|r| kappa(r, 20.0, B, 2.0 * c), 1e-3 / B, 0.5 / B)),
    ];
    for (name, v) in &rows {
        println!("{:<42} {:>16.9}", name, v);
    }

    println!();
    println!("chart: ruin chance in percent, surplus in $ thousands");
    println!("{:>6} {:>9} {:>9}", "u", "bound %", "exact %");
    for k in 0..11 {
        let u = 100_000.0 * k as f64;
        println!("{:>6} {:>9.2} {:>9.2}", 100 * k, 100.0 * (-r1 * u).exp(), 100.0 * psi_exact(u, B, THETA));
    }
    println!();
    println!("chart: two sides of the adjustment equation, per year; r per $1M");
    println!("{:>6} {:>9} {:>9}", "r", "claims", "premium");
    for r in (0..15).step_by(2) {
        let rr = r as f64 / 1e6;
        println!("{:>6} {:>9.2} {:>9.2}", r, LAM * (mgf(rr, B) - 1.0), c * rr);
    }
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-14 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
R closed form, per $1M                          9.090909091
R bisection on Simpson MGF, per $1M             9.090909090
1/R, dollars                               110000.000000000
M_X(R)                                          1.100000000
R u                                             9.090909091
Lundberg bound e^-Ru                            0.000112686
exact psi, closed form                          0.000102441
exact psi, Pollaczek-Khinchine series           0.000102441
bound / exact                                   1.100000000
capital for 1%, by the bound $             506568.720458690
capital for 1%, exact $                    496084.600680214
capital for 1%, series + bisection $       496084.600680214
extra capital, bound over exact $           10484.119778476
mean $100k: R per $1M                           0.909090909
mean $100k: bound                               0.402890322
mean $100k: exact, closed form                  0.366263929
mean $100k: exact, series                       0.366263929
mean $100k: simulation, 20000 paths             0.364100000
mean $100k: simulation std error                0.003402434
wrong: root R = 0, bound                        1.000000000
wrong: no loading, exact psi                    1.000000000
wrong: mean-variance R, per $1M                10.000000000
wrong: mean-variance bound                      0.000045400
try: loading 20%, bound                         0.000000058
try: surplus $500k, bound                       0.010615346
try: mean $50k, bound                           0.162320611
try: 20 claims/yr, premium x2, R per $1M        9.090909090

chart: ruin chance in percent, surplus in $ thousands
     u   bound %   exact %
     0    100.00     90.91
   100     40.29     36.63
   200     16.23     14.76
   300      6.54      5.95
   400      2.63      2.40
   500      1.06      0.97
   600      0.43      0.39
   700      0.17      0.16
   800      0.07      0.06
   900      0.03      0.03
  1000      0.01      0.01

chart: two sides of the adjustment equation, per year; r per $1M
     r    claims   premium
     0      0.00      0.00
     2      0.20      0.22
     4      0.42      0.44
     6      0.64      0.66
     8      0.87      0.88
    10      1.11      1.10
    12      1.36      1.32
    14      1.63      1.54
ALL CHECKS PASS
```

The two outputs are identical to the last printed digit, including the simulation, since both programs run the same xorshift64* generator from the same seed.

The simulation reads 0.3641 against the exact 0.3663, within one standard error of 0.0034.

### Lean

Lean proves Lundberg's inequality for every claim law with light tails, plus Steps 1 and 3, and checks the worked numbers.

- Take a Poisson stream of independent claims of one law, a positive loading, and an adjustment coefficient $R$ with $M_X(R)$ finite. Then the chance of ruin is at most $e^{-Ru}$.
- Take a rate $r$ with $M_X(r)$ finite, and a time $t \ge 0$. Then the average of $e^{r \times (\text{claims} - \text{premiums})}$ over $t$ years is $e^{t\,\kappa(r)}$.
- Take exponential claims with mean $\mu$, and premium $c = (1+\theta)\lambda\mu$ with $\theta > 0$. Then the only positive root of the adjustment equation is $R = \theta/((1+\theta)\mu)$.
- The worked numbers hold exactly. $R$ = 1/110,000 per dollar, $M_X(R)$ = 1.1, and $Ru$ = 100/11.
- The "what breaks" rates hold too. Claims ten times bigger give $R$ = 10/11 per \$1M; the mean-variance shortcut gives 10.
- With 20 claims a year and the premium doubled, $R$ = 1/110,000 still solves the adjustment equation.

The exact ruin chance, the Pollaczek–Khinchine series, the simulation and the capital figures are left to the Python and Rust checks.

```lean
-- Ruin: in the Cramér–Lundberg model, with Poisson claim arrivals, independent light-tailed claims and a positive loading, the chance the surplus ever drops below zero is at most e^(-R u), where R is the positive root of λ(M_X(R) - 1) = c R.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Real

theorem lintegral_ofReal_exp_expMeasure_lt {a s : ℝ} (ha : 0 < a) (hs : s < a) :
    ∫⁻ x, ENNReal.ofReal (exp (s * x)) ∂(expMeasure a) = ENNReal.ofReal (a / (a - s)) := by
  have has : 0 < a - s := by linarith
  have hg : Measurable (gammaPDF 1 a) := (measurable_gammaPDFReal 1 a).ennreal_ofReal
  rw [expMeasure, gammaMeasure, lintegral_withDensity_eq_lintegral_mul _ hg (by fun_prop)]
  have key : ∀ x, (gammaPDF 1 a * fun x => ENNReal.ofReal (exp (s * x))) x
      = ENNReal.ofReal (a / (a - s)) * exponentialPDF (a - s) x := by
    intro x
    show exponentialPDF a x * ENNReal.ofReal (exp (s * x)) = _
    rcases lt_or_ge x 0 with hx | hx
    · simp [exponentialPDF_of_neg hx]
    · rw [exponentialPDF_of_nonneg hx, exponentialPDF_of_nonneg hx,
        ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity)]
      congr 1
      rw [mul_assoc, ← exp_add]
      field_simp
      ring_nf
  simp_rw [key]
  have hg2 : Measurable (exponentialPDF (a - s)) := (measurable_gammaPDFReal 1 (a - s)).ennreal_ofReal
  rw [lintegral_const_mul _ hg2,
    lintegral_exponentialPDF_eq_one has, mul_one]

theorem lintegral_ofReal_exp_expMeasure_ge {a s : ℝ} (ha : 0 < a) (hs : a ≤ s) :
    ∫⁻ x, ENNReal.ofReal (exp (s * x)) ∂(expMeasure a) = ⊤ := by
  have hg : Measurable (gammaPDF 1 a) := (measurable_gammaPDFReal 1 a).ennreal_ofReal
  rw [expMeasure, gammaMeasure, lintegral_withDensity_eq_lintegral_mul _ hg (by fun_prop)]
  apply eq_top_iff.mpr
  calc (⊤ : ENNReal) = ∫⁻ x, (Set.Ici (0:ℝ)).indicator (fun _ => ENNReal.ofReal a) x := by
        rw [lintegral_indicator measurableSet_Ici, setLIntegral_const, Real.volume_Ici,
          ENNReal.mul_top (by simp [ha])]
    _ ≤ _ := by
        apply lintegral_mono
        intro x
        show _ ≤ exponentialPDF a x * ENNReal.ofReal (exp (s * x))
        by_cases hx : x ∈ Set.Ici (0:ℝ)
        · rw [Set.indicator_of_mem hx]
          rw [Set.mem_Ici] at hx
          rw [exponentialPDF_of_nonneg hx, ← ENNReal.ofReal_mul (by positivity)]
          apply ENNReal.ofReal_le_ofReal
          rw [mul_assoc, ← exp_add]
          have : 1 ≤ exp (-(a * x) + s * x) := one_le_exp (by nlinarith)
          nlinarith
        · rw [Set.indicator_of_notMem hx]; exact zero_le

theorem indepFun_of_depends {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (f : ι → Ω → ℝ) (hf : iIndepFun f P) (hmeas : ∀ i, Measurable (f i))
    (S T : Set ι) (hST : Disjoint S T) {β γ : Type*} [MeasurableSpace β] [MeasurableSpace γ]
    (F : (ι → ℝ) → β) (G : (ι → ℝ) → γ) (hF : Measurable F) (hG : Measurable G)
    (hFS : ∀ v v' : ι → ℝ, (∀ i ∈ S, v i = v' i) → F v = F v')
    (hGT : ∀ v v' : ι → ℝ, (∀ i ∈ T, v i = v' i) → G v = G v') :
    IndepFun (fun ω => F (fun i => f i ω)) (fun ω => G (fun i => f i ω)) P := by
  classical
  let eS : (S → ℝ) → (ι → ℝ) := fun w i => if h : i ∈ S then w ⟨i, h⟩ else 0
  let eT : (T → ℝ) → (ι → ℝ) := fun w i => if h : i ∈ T then w ⟨i, h⟩ else 0
  have heS : Measurable eS := by
    refine Measurable.of_eval (fun i => ?_)
    by_cases h : i ∈ S
    · simp only [eS, h, dite_true]; exact measurable_pi_apply _
    · simp only [eS, h, dite_false]; exact measurable_const
  have heT : Measurable eT := by
    refine Measurable.of_eval (fun i => ?_)
    by_cases h : i ∈ T
    · simp only [eT, h, dite_true]; exact measurable_pi_apply _
    · simp only [eT, h, dite_false]; exact measurable_const
  have h1 : (fun ω => F (fun i => f i ω)) = (F ∘ eS) ∘ (fun ω (i : S) => f i ω) := by
    funext ω; exact hFS _ _ (fun i hi => by simp [eS, hi])
  have h2 : (fun ω => G (fun i => f i ω)) = (G ∘ eT) ∘ (fun ω (i : T) => f i ω) := by
    funext ω; exact hGT _ _ (fun i hi => by simp [eT, hi])
  rw [h1, h2]
  exact (hf.indepFun_set S T hST hmeas).comp (hF.comp heS) (hG.comp heT)

theorem lintegral_mul_of_depends {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (f : ι → Ω → ℝ) (hf : iIndepFun f P) (hmeas : ∀ i, Measurable (f i))
    (S T : Set ι) (hST : Disjoint S T)
    (F G : (ι → ℝ) → ENNReal) (hF : Measurable F) (hG : Measurable G)
    (hFS : ∀ v v' : ι → ℝ, (∀ i ∈ S, v i = v' i) → F v = F v')
    (hGT : ∀ v v' : ι → ℝ, (∀ i ∈ T, v i = v' i) → G v = G v') :
    ∫⁻ ω, F (fun i => f i ω) * G (fun i => f i ω) ∂P
      = (∫⁻ ω, F (fun i => f i ω) ∂P) * ∫⁻ ω, G (fun i => f i ω) ∂P := by
  have hV : Measurable (fun ω i => f i ω) := Measurable.of_eval hmeas
  exact lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun'' (hF.comp hV).aemeasurable
    (hG.comp hV).aemeasurable (indepFun_of_depends f hf hmeas S T hST F G hF hG hFS hGT)

/-- The coordinates of block `B`: claim sizes and waits with index in `B`. -/
def blk (B : Set ℕ) : Set (ℕ ⊕ ℕ) := {k | Sum.elim (· ∈ B) (· ∈ B) k}

theorem blk_disjoint {B B' : Set ℕ} (h : Disjoint B B') : Disjoint (blk B) (blk B') := by
  rw [Set.disjoint_left]
  intro k hk hk'
  cases k with
  | inl i => exact Set.disjoint_left.mp h hk hk'
  | inr i => exact Set.disjoint_left.mp h hk hk'

/-- The chance that the sum of `m` independent exponential waits with rate `lam` is at most `t`. -/
noncomputable def erlH (lam : ℝ) (m : ℕ) (t : ℝ) : ℝ :=
  if 0 ≤ t then 1 - exp (-(lam * t)) * ∑ j ∈ Finset.range m, (lam * t) ^ j / (Nat.factorial j : ℝ)
  else 0

theorem erlH_nonneg {lam : ℝ} (hlam : 0 ≤ lam) (m : ℕ) (t : ℝ) : 0 ≤ erlH lam m t := by
  unfold erlH
  split_ifs with ht
  · have h1 := Real.sum_le_exp_of_nonneg (mul_nonneg hlam ht) m
    have h2 : exp (-(lam * t)) * exp (lam * t) = 1 := by rw [← exp_add]; simp
    have h3 : exp (-(lam * t)) * ∑ j ∈ Finset.range m, (lam * t) ^ j / (Nat.factorial j : ℝ)
        ≤ exp (-(lam * t)) * exp (lam * t) := mul_le_mul_of_nonneg_left h1 (exp_pos _).le
    linarith
  · exact le_rfl

theorem erlH_conv {lam : ℝ} (hlam : 0 < lam) (m : ℕ) (t : ℝ) :
    ∫⁻ y, ENNReal.ofReal (erlH lam m (t - y)) ∂(expMeasure lam)
      = ENNReal.ofReal (erlH lam (m + 1) t) := by
  have hmeas : Measurable (gammaPDF 1 lam) := (measurable_gammaPDFReal 1 lam).ennreal_ofReal
  rw [expMeasure, gammaMeasure, lintegral_withDensity_eq_lintegral_mul_non_measurable _ hmeas
    (Filter.Eventually.of_forall (fun _ => ENNReal.ofReal_lt_top))]
  rcases lt_or_ge t 0 with ht | ht
  · have hz : ∀ y, (gammaPDF 1 lam * fun y => ENNReal.ofReal (erlH lam m (t - y))) y = 0 := by
      intro y
      show exponentialPDF lam y * _ = 0
      rcases lt_or_ge y 0 with hy | hy
      · simp [exponentialPDF_of_neg hy]
      · simp [erlH, show ¬ (0 ≤ t - y) by linarith]
    simp only [hz, lintegral_zero]
    simp [erlH, not_le.mpr ht]
  set φ : ℝ → ℝ := fun y => lam * exp (-(lam * y)) - lam * exp (-(lam * t)) *
    ∑ j ∈ Finset.range m, (lam * (t - y)) ^ j / (Nat.factorial j : ℝ) with hφ
  have hφeq : ∀ y, y ≤ t → φ y = lam * exp (-(lam * y)) * erlH lam m (t - y) := by
    intro y hyt
    simp only [hφ, erlH, if_pos (sub_nonneg.mpr hyt)]
    have : exp (-(lam * y)) * exp (-(lam * (t - y))) = exp (-(lam * t)) := by
      rw [← exp_add]; ring_nf
    linear_combination (lam * ∑ j ∈ Finset.range m, (lam * (t - y)) ^ j / (Nat.factorial j : ℝ))
      * this
  have hpt : ∀ y, (gammaPDF 1 lam * fun y => ENNReal.ofReal (erlH lam m (t - y))) y
      = (Set.Icc 0 t).indicator (fun y => ENNReal.ofReal (φ y)) y := by
    intro y
    show exponentialPDF lam y * _ = _
    rcases lt_or_ge y 0 with hy | hy
    · rw [exponentialPDF_of_neg hy, zero_mul, Set.indicator_of_notMem
        (show y ∉ Set.Icc 0 t from fun h => by linarith [h.1])]
    · by_cases hyt : y ≤ t
      · rw [Set.indicator_of_mem (show y ∈ Set.Icc 0 t from ⟨hy, hyt⟩), exponentialPDF_of_nonneg hy,
          ← ENNReal.ofReal_mul (by positivity), hφeq y hyt]
      · rw [Set.indicator_of_notMem (show y ∉ Set.Icc 0 t from fun h => hyt h.2)]
        simp [erlH, show ¬ 0 ≤ t - y by linarith]
  simp only [hpt]
  have hφc : Continuous φ := by rw [hφ]; fun_prop
  rw [lintegral_indicator measurableSet_Icc, ← ofReal_integral_eq_lintegral_ofReal
    (hφc.integrableOn_Icc) ((ae_restrict_iff' measurableSet_Icc).mpr
      (Filter.Eventually.of_forall (fun y hy => by
        rw [hφeq y hy.2]
        exact mul_nonneg (by positivity) (erlH_nonneg hlam.le _ _))))]
  congr 1
  set F : ℝ → ℝ := fun y => -exp (-(lam * y)) + exp (-(lam * t)) *
    ∑ j ∈ Finset.range m, (lam * (t - y)) ^ (j + 1) / (Nat.factorial (j + 1) : ℝ) with hF
  have hderiv : ∀ y, HasDerivAt F (φ y) y := by
    intro y
    have h1 : HasDerivAt (fun y => -exp (-(lam * y))) (lam * exp (-(lam * y))) y := by
      refine (((hasDerivAt_id y).const_mul lam).neg.exp).neg.congr_deriv ?_
      simp [mul_comm]
    have h2 : ∀ j ∈ Finset.range m, HasDerivAt
        (fun y => (lam * (t - y)) ^ (j + 1) / (Nat.factorial (j + 1) : ℝ))
        (-(lam * ((lam * (t - y)) ^ j / (Nat.factorial j : ℝ)))) y := by
      intro j _
      have := ((((hasDerivAt_id y).const_sub t).const_mul lam).pow (j + 1)).div_const
        (Nat.factorial (j + 1) : ℝ)
      refine this.congr_deriv ?_
      simp only [id, Nat.add_sub_cancel, Nat.factorial_succ]
      push_cast
      field_simp
    have h3 := (HasDerivAt.fun_sum h2).const_mul (exp (-(lam * t)))
    convert h1.add h3 using 1
    rw [hφ]
    simp only [Finset.sum_neg_distrib, ← Finset.mul_sum]
    ring
  rw [MeasureTheory.integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le ht,
    intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hderiv y)
      (hφc.intervalIntegrable _ _)]
  simp only [hF, erlH, if_pos ht, Finset.sum_range_succ', sub_self, mul_zero]
  simp
  ring

theorem erlang_cdf {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam : ℝ) (hlam : 0 < lam) (W : ℕ → Ω → ℝ) (hWmeas : ∀ i, Measurable (W i))
    (hWexp : ∀ i, P.map (W i) = expMeasure lam) (hW : iIndepFun W P) (m : ℕ) (t : ℝ) :
    P {ω | ∑ j ∈ Finset.range m, W j ω ≤ t} = ENNReal.ofReal (erlH lam m t) := by
  induction m generalizing t with
  | zero => by_cases ht : 0 ≤ t <;> simp [erlH, ht]
  | succ m ih =>
    set Sm : Ω → ℝ := fun ω => ∑ j ∈ Finset.range m, W j ω with hSmdef
    have hSm : Measurable Sm := Finset.measurable_fun_sum _ (fun j _ => hWmeas j)
    have hind : IndepFun Sm (W m) P := by
      have := hW.indepFun_finsetSum_of_notMem hWmeas (Finset.notMem_range_self (n := m))
      convert this using 1
      funext ω
      simp [Sm, Finset.sum_apply]
    have hset : {ω | ∑ j ∈ Finset.range (m + 1), W j ω ≤ t}
        = (fun ω => (Sm ω, W m ω)) ⁻¹' {p : ℝ × ℝ | p.1 + p.2 ≤ t} := by
      ext ω; simp [Finset.sum_range_succ, Sm]
    have hmeasS : MeasurableSet {p : ℝ × ℝ | p.1 + p.2 ≤ t} :=
      measurableSet_le (by fun_prop) measurable_const
    rw [hset, ← Measure.map_apply (by fun_prop) hmeasS,
      (indepFun_iff_map_prod_eq_prod_map_map hSm.aemeasurable (hWmeas m).aemeasurable).mp hind,
      Measure.prod_apply_symm hmeasS, hWexp m]
    have hy : ∀ y, (P.map Sm) ((fun x => (x, y)) ⁻¹' {p : ℝ × ℝ | p.1 + p.2 ≤ t})
        = ENNReal.ofReal (erlH lam m (t - y)) := by
      intro y
      rw [Measure.map_apply hSm ((by fun_prop : Measurable (fun x : ℝ => (x, y))) hmeasS), ← ih (t - y)]
      congr 1
      ext ω
      simp only [Set.mem_preimage, Set.mem_setOf_eq, Sm]
      constructor <;> intro h <;> linarith
    simp_rw [hy]
    exact erlH_conv hlam m t

/-- Lundberg's inequality. An insurer starts with surplus `u` and collects premium at `c`
dollars a year. Claims arrive as a Poisson stream with `lam > 0` claims a year: the waits
`W 0, W 1, ...` between claims are independent and exponential with rate `lam`, so claim `i`
arrives at time `T_i = W 0 + ... + W i`. Claim sizes `X 0, X 1, ...` are nonnegative, have one
common law, and are independent of each other and of the timing. The loading is positive:
`c > lam * E[X]`. The adjustment coefficient `R > 0` has `M_X(R) = E[e^(R X)]` finite and solves
`lam * (M_X(R) - 1) = c * R`. The surplus at time `t ≥ 0` is `u + c t` minus every claim that has
arrived by `t`; it is below zero exactly when, for some `n`, `u + c t` minus the claims among the
first `n` that have arrived by `t` is below zero. Then the chance that the surplus is ever below
zero is at most `e^(-R u)`. -/
theorem lundberg_inequality
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam c u R : ℝ) (hlam : 0 < lam)
    (X W : ℕ → Ω → ℝ) (hXmeas : ∀ i, Measurable (X i)) (hWmeas : ∀ i, Measurable (W i))
    (hXnonneg : ∀ i ω, 0 ≤ X i ω)
    (hXident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hWexp : ∀ i, P.map (W i) = expMeasure lam)
    (hindep : iIndepFun (fun k : ℕ ⊕ ℕ => Sum.elim X W k) P)
    (hload : lam * ∫ ω, X 0 ω ∂P < c)
    (hR : 0 < R) (hlight : Integrable (fun ω => exp (R * X 0 ω)) P)
    (hadj : lam * (mgf (X 0) P R - 1) = c * R) :
    P.real {ω | ∃ t : ℝ, 0 ≤ t ∧ ∃ n : ℕ,
        u + c * t - ∑ i ∈ (Finset.range n).filter
          (fun i => ∑ j ∈ Finset.range (i + 1), W j ω ≤ t), X i ω < 0}
      ≤ exp (-R * u) := by
  classical
  set f : ℕ ⊕ ℕ → Ω → ℝ := fun k => Sum.elim X W k with hfdef
  have hfmeas : ∀ k, Measurable (f k) := by
    intro k
    cases k with
    | inl i => exact hXmeas i
    | inr i => exact hWmeas i
  have hEX : 0 ≤ ∫ ω, X 0 ω ∂P := integral_nonneg (hXnonneg 0)
  have hc : 0 < c := by nlinarith
  rcases lt_or_ge u 0 with hu | hu
  · calc _ ≤ 1 := measureReal_le_one
      _ ≤ exp (-R * u) := one_le_exp (by nlinarith)
  -- functions of the whole vector of claims and waits
  let s : ℕ → (ℕ ⊕ ℕ → ℝ) → ℝ := fun n v =>
    ∑ i ∈ Finset.range n, (v (Sum.inl i) - c * v (Sum.inr i))
  let A : ℕ → Set (ℕ ⊕ ℕ → ℝ) := fun k => {v | u < s (k + 1) v ∧ ∀ j < k, s (j + 1) v ≤ u}
  let z : ℕ → (ℕ ⊕ ℕ → ℝ) → ENNReal := fun i v =>
    ENNReal.ofReal (exp (R * (v (Sum.inl i) - c * v (Sum.inr i))))
  let g : ℕ → (ℕ ⊕ ℕ → ℝ) → ENNReal := fun n v => ENNReal.ofReal (exp (R * s n v))
  let V : Ω → (ℕ ⊕ ℕ → ℝ) := fun ω k => f k ω
  have hV : Measurable V := Measurable.of_eval hfmeas
  have hs : ∀ n, Measurable (s n) := by
    intro n
    apply Finset.measurable_sum
    intro i _
    fun_prop
  have hA : ∀ k, MeasurableSet (A k) := by
    intro k
    have : A k = {v | u < s (k + 1) v} ∩ ⋂ j ∈ Finset.range k, {v | s (j + 1) v ≤ u} := by
      ext v; simp [A]
    rw [this]
    exact (measurableSet_lt measurable_const (hs _)).inter
      (Finset.measurableSet_biInter _ (fun j _ => measurableSet_le (hs _) measurable_const))
  have hz : ∀ i, Measurable (z i) := by
    intro i
    fun_prop
  have hg : ∀ n, Measurable (g n) := fun n => by
    have := hs n
    fun_prop
  have hgprod : ∀ n v, g n v = ∏ i ∈ Finset.range n, z i v := by
    intro n v
    simp only [g, s, z]
    rw [Finset.mul_sum, exp_sum, ENNReal.ofReal_prod_of_nonneg (fun i _ => (exp_pos _).le)]
  -- one step has mean one
  have hM0 : 0 ≤ mgf (X 0) P R := mgf_nonneg
  have hz1 : ∀ i, ∫⁻ ω, z i (V ω) ∂P = 1 := by
    intro i
    have hsplit : ∀ ω, z i (V ω) = ENNReal.ofReal (exp (R * X i ω))
        * ENNReal.ofReal (exp ((-(c * R)) * W i ω)) := by
      intro ω
      simp only [z, V, hfdef, Sum.elim_inl, Sum.elim_inr]
      rw [← ENNReal.ofReal_mul (exp_pos _).le, ← exp_add]
      ring_nf
    simp_rw [hsplit]
    have hind : IndepFun (X i) (W i) P := hindep.indepFun Sum.inl_ne_inr
    rw [lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun''
      ((hXmeas i).const_mul R).exp.ennreal_ofReal.aemeasurable
      ((hWmeas i).const_mul _).exp.ennreal_ofReal.aemeasurable
      (hind.comp (φ := fun x => ENNReal.ofReal (exp (R * x)))
        (ψ := fun x => ENNReal.ofReal (exp ((-(c * R)) * x))) (by fun_prop) (by fun_prop))]
    have e1 : ∫⁻ ω, ENNReal.ofReal (exp (R * X i ω)) ∂P = ENNReal.ofReal (mgf (X 0) P R) := by
      have := ((hXident i).comp (u := fun x => ENNReal.ofReal (exp (R * x)))
        (by fun_prop)).lintegral_eq
      simp only [Function.comp_def] at this
      rw [this, mgf, ofReal_integral_eq_lintegral_ofReal hlight
        (Filter.Eventually.of_forall (fun ω => (exp_pos _).le))]
    have e2 : ∫⁻ ω, ENNReal.ofReal (exp ((-(c * R)) * W i ω)) ∂P
        = ENNReal.ofReal (lam / (lam - (-(c * R)))) := by
      rw [← lintegral_map (f := fun x => ENNReal.ofReal (exp ((-(c * R)) * x))) (by fun_prop)
        (hWmeas i), hWexp i]
      exact lintegral_ofReal_exp_expMeasure_lt hlam (by nlinarith)
    rw [e1, e2, ← ENNReal.ofReal_mul hM0]
    have hden : 0 < lam - -(c * R) := by nlinarith
    have : mgf (X 0) P R * (lam / (lam - -(c * R))) = 1 := by
      rw [mul_div_assoc', div_eq_one_iff_eq hden.ne']
      linarith
    rw [this, ENNReal.ofReal_one]
  -- products over any finite set of steps have mean one
  have hzprod : ∀ t : Finset ℕ, ∫⁻ ω, ∏ i ∈ t, z i (V ω) ∂P = 1 := by
    intro t
    induction t using Finset.induction_on with
    | empty => simp
    | insert j t hj ih =>
      simp_rw [Finset.prod_insert hj]
      rw [lintegral_mul_of_depends f hindep hfmeas (blk {j}) (blk ↑t)
        (blk_disjoint (by simpa using hj)) (z j) (fun v => ∏ i ∈ t, z i v) (hz j)
        (Finset.measurable_prod _ (fun i _ => hz i)) ?_ ?_]
      · change (∫⁻ ω, z j (V ω) ∂P) * ∫⁻ ω, ∏ i ∈ t, z i (V ω) ∂P = 1
        rw [hz1, ih, one_mul]
      · intro v v' h
        simp only [z]
        rw [h (Sum.inl j) (by simp [blk]), h (Sum.inr j) (by simp [blk])]
      · intro v v' h
        apply Finset.prod_congr rfl
        intro i hi
        simp only [z]
        rw [h (Sum.inl i) (by simp [blk, hi]), h (Sum.inr i) (by simp [blk, hi])]
  -- the sets A k are disjoint
  have hAdisj : ∀ k k' v, v ∈ A k → v ∈ A k' → k = k' := by
    intro k k' v hk hk'
    by_contra hne
    rcases Nat.lt_or_gt_of_ne hne with h | h
    · exact absurd (hk'.2 k h) (not_le.mpr hk.1)
    · exact absurd (hk.2 k' h) (not_le.mpr hk'.1)
  -- key bound for each N
  have hfin : ∀ N, ∑ k ∈ Finset.range N, P (V ⁻¹' A k) ≤ ENNReal.ofReal (exp (-R * u)) := by
    intro N
    have hstep : ∀ k ∈ Finset.range N, ENNReal.ofReal (exp (R * u)) * P (V ⁻¹' A k)
        ≤ ∫⁻ ω, (A k).indicator (g N) (V ω) ∂P := by
      intro k hk
      have hkN : k + 1 ≤ N := Finset.mem_range.mp hk
      have e1 : ENNReal.ofReal (exp (R * u)) * P (V ⁻¹' A k)
          ≤ ∫⁻ ω, (A k).indicator (g (k + 1)) (V ω) ∂P := by
        rw [← lintegral_indicator_const (hV (hA k))]
        apply lintegral_mono
        intro ω
        dsimp only
        by_cases hω : V ω ∈ A k
        · rw [Set.indicator_of_mem (show ω ∈ V ⁻¹' A k from hω), Set.indicator_of_mem hω]
          exact ENNReal.ofReal_le_ofReal (exp_le_exp.mpr
            (mul_le_mul_of_nonneg_left hω.1.le hR.le))
        · rw [Set.indicator_of_notMem (show ω ∉ V ⁻¹' A k from hω)]
          exact zero_le
      have hsplit : ∀ v, (A k).indicator (g N) v
          = (A k).indicator (g (k + 1)) v * ∏ i ∈ Finset.Ico (k + 1) N, z i v := by
        intro v
        by_cases hv : v ∈ A k
        · rw [Set.indicator_of_mem hv, Set.indicator_of_mem hv, hgprod, hgprod,
            ← Finset.prod_range_mul_prod_Ico _ hkN]
        · simp [hv]
      have e2 : ∫⁻ ω, (A k).indicator (g N) (V ω) ∂P
          = ∫⁻ ω, (A k).indicator (g (k + 1)) (V ω) ∂P := by
        simp_rw [hsplit]
        rw [lintegral_mul_of_depends f hindep hfmeas (blk {i | i < k + 1}) (blk {i | k + 1 ≤ i})
          (blk_disjoint ?_) ((A k).indicator (g (k + 1)))
          (fun v => ∏ i ∈ Finset.Ico (k + 1) N, z i v)
          ((hg _).indicator (hA k)) (Finset.measurable_prod _ (fun i _ => hz i)) ?_ ?_]
        · change (∫⁻ ω, (A k).indicator (g (k + 1)) (V ω) ∂P)
            * ∫⁻ ω, ∏ i ∈ Finset.Ico (k + 1) N, z i (V ω) ∂P = _
          rw [hzprod, mul_one]
        · rw [Set.disjoint_left]; intro i h1 h2; simp at h1 h2; omega
        · intro v v' h
          have key : ∀ n ≤ k + 1, s n v = s n v' := by
            intro n hn
            apply Finset.sum_congr rfl
            intro i hi
            have hi' : i < k + 1 := by simp at hi; omega
            rw [h (Sum.inl i) (by simpa [blk] using hi'), h (Sum.inr i) (by simpa [blk] using hi')]
          have hmem : v ∈ A k ↔ v' ∈ A k := by
            simp only [A, Set.mem_ofPred_eq]
            rw [key (k + 1) le_rfl]
            exact and_congr_right' (forall₂_congr (fun j hj => by rw [key (j + 1) (by omega)]))
          by_cases hv : v ∈ A k
          · rw [Set.indicator_of_mem hv, Set.indicator_of_mem (hmem.mp hv)]
            simp only [g]; rw [key (k + 1) le_rfl]
          · rw [Set.indicator_of_notMem hv, Set.indicator_of_notMem (fun h' => hv (hmem.mpr h'))]
        · intro v v' h
          apply Finset.prod_congr rfl
          intro i hi
          have hi' : k + 1 ≤ i := (Finset.mem_Ico.mp hi).1
          simp only [z]
          rw [h (Sum.inl i) (by simpa [blk] using hi'), h (Sum.inr i) (by simpa [blk] using hi')]
      rw [e2]; exact e1
    have htot : ∑ k ∈ Finset.range N, ∫⁻ ω, (A k).indicator (g N) (V ω) ∂P ≤ 1 := by
      rw [← lintegral_finsetSum (f := fun k ω => (A k).indicator (g N) (V ω)) _
        (fun k _ => ((hg N).indicator (hA k)).comp hV)]
      calc ∫⁻ ω, ∑ k ∈ Finset.range N, (A k).indicator (g N) (V ω) ∂P
          ≤ ∫⁻ ω, g N (V ω) ∂P := by
            apply lintegral_mono
            intro ω
            dsimp only
            by_cases hex : ∃ k ∈ Finset.range N, V ω ∈ A k
            · obtain ⟨k, hk, hmem⟩ := hex
              rw [Finset.sum_eq_single k]
              · exact Set.indicator_le_self _ _ _
              · intro b _ hb
                rw [Set.indicator_of_notMem]
                intro hb'
                exact hb (hAdisj _ _ _ hb' hmem)
              · intro h; exact absurd hk h
            · push Not at hex
              rw [Finset.sum_eq_zero (fun k hk => Set.indicator_of_notMem (hex k hk) _)]
              exact zero_le
        _ = 1 := by simp_rw [hgprod]; exact hzprod _
    have hmul : ENNReal.ofReal (exp (R * u)) * ∑ k ∈ Finset.range N, P (V ⁻¹' A k) ≤ 1 := by
      rw [Finset.mul_sum]
      exact (Finset.sum_le_sum hstep).trans htot
    have hone : ENNReal.ofReal (exp (-R * u)) * ENNReal.ofReal (exp (R * u)) = 1 := by
      rw [← ENNReal.ofReal_mul (exp_pos _).le, ← exp_add]; simp
    calc ∑ k ∈ Finset.range N, P (V ⁻¹' A k)
        = ENNReal.ofReal (exp (-R * u)) * (ENNReal.ofReal (exp (R * u))
            * ∑ k ∈ Finset.range N, P (V ⁻¹' A k)) := by
          rw [← mul_assoc, hone, one_mul]
      _ ≤ ENNReal.ofReal (exp (-R * u)) * 1 := by gcongr
      _ = _ := mul_one _
  -- the ruin event lies in the union of the A k
  have hsub : {ω | ∃ t : ℝ, 0 ≤ t ∧ ∃ n : ℕ,
        u + c * t - ∑ i ∈ (Finset.range n).filter
          (fun i => ∑ j ∈ Finset.range (i + 1), W j ω ≤ t), X i ω < 0} ⊆ ⋃ k, V ⁻¹' A k := by
    intro ω ⟨t, ht, n, hn⟩
    set B := (Finset.range n).filter (fun i => ∑ j ∈ Finset.range (i + 1), W j ω ≤ t) with hB
    have hex : ∃ k, u < s (k + 1) (V ω) := by
      rcases B.eq_empty_or_nonempty with hBe | hBne
      · rw [hBe, Finset.sum_empty] at hn; nlinarith [mul_nonneg hc.le ht]
      · set k := B.max' hBne
        have hkB : k ∈ B := B.max'_mem hBne
        have hTk : ∑ j ∈ Finset.range (k + 1), W j ω ≤ t := (Finset.mem_filter.mp hkB).2
        have hsubB : B ⊆ Finset.range (k + 1) := by
          intro i hi; rw [Finset.mem_range]; exact Nat.lt_succ_of_le (B.le_max' i hi)
        have hle : ∑ i ∈ B, X i ω ≤ ∑ i ∈ Finset.range (k + 1), X i ω :=
          Finset.sum_le_sum_of_subset_of_nonneg hsubB (fun i _ _ => hXnonneg i ω)
        refine ⟨k, ?_⟩
        have : s (k + 1) (V ω) = ∑ i ∈ Finset.range (k + 1), X i ω
            - c * ∑ j ∈ Finset.range (k + 1), W j ω := by
          simp only [s, V, hfdef, Sum.elim_inl, Sum.elim_inr]
          rw [Finset.sum_sub_distrib, Finset.mul_sum]
        rw [this]
        nlinarith [mul_le_mul_of_nonneg_left hTk hc.le]
    exact Set.mem_iUnion.mpr ⟨Nat.find hex, Nat.find_spec hex,
      fun j hj => not_lt.mp (Nat.find_min hex hj)⟩
  -- conclude
  have hU : P (⋃ k, V ⁻¹' A k) ≤ ENNReal.ofReal (exp (-R * u)) :=
    (measure_iUnion_le _).trans (ENNReal.tsum_le_of_sum_range_le hfin)
  calc _ ≤ P.real (⋃ k, V ⁻¹' A k) := measureReal_mono hsub (measure_ne_top _ _)
    _ ≤ _ := ENNReal.toReal_le_of_le_ofReal (exp_pos _).le hU

/-- Step 1: how an exponential of the claims grows. In the same claim stream, fix a rate `r`
with `M_X(r) = E[e^(r X)]` finite and a time `t ≥ 0`. Let `S_t` be the total of the claims that
have arrived by time `t`. Then the average of `e^(r (S_t - c t))` is `e^(t κ(r))`, with
`κ(r) = lam (M_X(r) - 1) - c r`. -/
theorem compound_poisson_exponential_growth
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam c r t : ℝ) (hlam : 0 < lam) (ht : 0 ≤ t)
    (X W : ℕ → Ω → ℝ) (hXmeas : ∀ i, Measurable (X i)) (hWmeas : ∀ i, Measurable (W i))
    (hXident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hWexp : ∀ i, P.map (W i) = expMeasure lam)
    (hindep : iIndepFun (fun k : ℕ ⊕ ℕ => Sum.elim X W k) P)
    (hr : Integrable (fun ω => exp (r * X 0 ω)) P) :
    ∫ ω, exp (r * ((∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t then X i ω else 0) - c * t)) ∂P
      = exp (t * (lam * (mgf (X 0) P r - 1) - c * r)) := by
  classical
  set f : ℕ ⊕ ℕ → Ω → ℝ := fun k => Sum.elim X W k with hfdef
  have hfmeas : ∀ k, Measurable (f k) := by
    intro k
    cases k with
    | inl i => exact hXmeas i
    | inr i => exact hWmeas i
  have hW : iIndepFun W P := by
    have h := hindep.precomp Sum.inr_injective
    exact h
  have hX : iIndepFun X P := by
    have h := hindep.precomp Sum.inl_injective
    exact h
  have hXW : IndepFun (fun ω i => X i ω) (fun ω j => W j ω) P :=
    indepFun_of_depends f hindep hfmeas (Set.range Sum.inl) (Set.range Sum.inr)
      Set.isCompl_range_inl_range_inr.disjoint (fun v i => v (Sum.inl i))
      (fun v j => v (Sum.inr j)) (Measurable.of_eval (fun i => measurable_pi_apply _))
      (Measurable.of_eval (fun i => measurable_pi_apply _))
      (fun v v' h => funext fun i => h _ ⟨i, rfl⟩) (fun v v' h => funext fun j => h _ ⟨j, rfl⟩)
  set M := mgf (X 0) P r with hMdef
  have hM0 : 0 ≤ M := mgf_nonneg
  have hXm : ∀ i, ∫⁻ ω, ENNReal.ofReal (exp (r * X i ω)) ∂P = ENNReal.ofReal M := by
    intro i
    have := ((hXident i).comp (u := fun x => ENNReal.ofReal (exp (r * x)))
      (by fun_prop)).lintegral_eq
    simp only [Function.comp_def] at this
    rw [this, hMdef, mgf, ofReal_integral_eq_lintegral_ofReal hr
      (Filter.Eventually.of_forall (fun ω => (exp_pos _).le))]
  -- waits are nonnegative almost surely
  have hWnn : ∀ i, ∀ᵐ ω ∂P, 0 ≤ W i ω := by
    intro i
    have hneg : P (W i ⁻¹' Set.Iio 0) = 0 := by
      rw [← Measure.map_apply (hWmeas i) measurableSet_Iio, hWexp i, expMeasure, gammaMeasure,
        withDensity_apply _ measurableSet_Iio]
      exact lintegral_exponentialPDF_of_nonpos le_rfl
    rw [ae_iff]
    have hset : {a | ¬ 0 ≤ W i a} = W i ⁻¹' Set.Iio 0 := by ext; simp
    rw [hset]; exact hneg
  have hcdf := erlang_cdf P lam hlam W hWmeas hWexp hW
  -- the event "exactly m claims by time t"
  let Ew : ℕ → Set (ℕ → ℝ) := fun m =>
    {w | ∑ j ∈ Finset.range m, w j ≤ t} \ {w | ∑ j ∈ Finset.range (m + 1), w j ≤ t}
  have hEw : ∀ m, MeasurableSet (Ew m) := by
    intro m
    exact (measurableSet_le (Finset.measurable_fun_sum _ (fun j _ => measurable_pi_apply j))
      measurable_const).diff (measurableSet_le (Finset.measurable_fun_sum _
        (fun j _ => measurable_pi_apply j)) measurable_const)
  let Wv : Ω → (ℕ → ℝ) := fun ω j => W j ω
  let Xv : Ω → (ℕ → ℝ) := fun ω i => X i ω
  have hWv : Measurable Wv := Measurable.of_eval hWmeas
  have hXv : Measurable Xv := Measurable.of_eval hXmeas
  have hPE : ∀ m, P (Wv ⁻¹' Ew m)
      = ENNReal.ofReal (exp (-(lam * t)) * (lam * t) ^ m / (Nat.factorial m : ℝ)) := by
    intro m
    set A := {ω | ∑ j ∈ Finset.range m, W j ω ≤ t} with hA
    set B := {ω | ∑ j ∈ Finset.range (m + 1), W j ω ≤ t} with hB
    have hAm : MeasurableSet A := measurableSet_le (Finset.measurable_fun_sum _
      (fun j _ => hWmeas j)) measurable_const
    have hBm : MeasurableSet B := measurableSet_le (Finset.measurable_fun_sum _
      (fun j _ => hWmeas j)) measurable_const
    have h1 : Wv ⁻¹' Ew m = A \ (A ∩ B) := by
      ext ω; simp [Wv, Ew, A, B]
    have h2 : (A ∩ B : Set Ω) =ᵐ[P] B := by
      filter_upwards [hWnn m] with ω hω
      apply propext
      constructor
      · exact fun h => h.2
      · intro h
        refine ⟨?_, h⟩
        simp only [B, Set.mem_setOf_eq, Finset.sum_range_succ] at h
        show ∑ j ∈ Finset.range m, W j ω ≤ t
        linarith
    rw [h1, measure_diff Set.inter_subset_left (hAm.inter hBm).nullMeasurableSet
      (measure_ne_top _ _), measure_congr h2, hA, hB, hcdf, hcdf,
      ← ENNReal.ofReal_sub _ (erlH_nonneg hlam.le _ _)]
    congr 1
    simp only [erlH, if_pos ht, Finset.sum_range_succ]
    ring
  -- almost surely only finitely many claims arrive by time t
  have hfin : ∀ᵐ ω ∂P, ∃ m, t < ∑ j ∈ Finset.range m, W j ω := by
    rw [ae_iff]
    have htend : Filter.Tendsto (fun m => ENNReal.ofReal (erlH lam m t)) Filter.atTop
        (nhds 0) := by
      rw [← ENNReal.ofReal_zero]
      apply ENNReal.tendsto_ofReal
      have hs := (NormedSpace.expSeries_div_hasSum_exp (lam * t)).tendsto_sum_nat
      rw [← Real.exp_eq_exp_ℝ] at hs
      have : Filter.Tendsto (fun m => 1 - exp (-(lam * t)) *
          ∑ j ∈ Finset.range m, (lam * t) ^ j / (Nat.factorial j : ℝ)) Filter.atTop
          (nhds (1 - exp (-(lam * t)) * exp (lam * t))) :=
        tendsto_const_nhds.sub (tendsto_const_nhds.mul hs)
      rw [← exp_add, neg_add_cancel, exp_zero, sub_self] at this
      simpa [erlH, ht] using this
    apply le_antisymm _ (zero_le)
    apply ge_of_tendsto' htend
    intro m
    rw [← hcdf m t]
    apply measure_mono
    intro ω hω
    simp only [Set.mem_setOf_eq, not_exists, not_lt] at hω
    exact hω m
  -- the integrand as a sum over the number of claims
  let C : ℝ := exp (-(r * (c * t)))
  let Gx : ℕ → (ℕ → ℝ) → ENNReal := fun m x =>
    ENNReal.ofReal C * ∏ i ∈ Finset.range m, ENNReal.ofReal (exp (r * x i))
  have hGx : ∀ m, Measurable (Gx m) := by
    intro m
    exact measurable_const.mul (Finset.measurable_fun_prod _ (fun i _ =>
      (measurable_exp.comp (measurable_const.mul (measurable_pi_apply i))).ennreal_ofReal))
  let term : ℕ → Ω → ENNReal := fun m ω => (Ew m).indicator 1 (Wv ω) * Gx m (Xv ω)
  have hterm : ∀ m, Measurable (term m) := fun m =>
    ((measurable_one.indicator (hEw m)).comp hWv).mul ((hGx m).comp hXv)
  have hpt : ∀ᵐ ω ∂P, ENNReal.ofReal (exp (r * ((∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t
      then X i ω else 0) - c * t))) = ∑' m, term m ω := by
    filter_upwards [ae_all_iff.mpr hWnn, hfin] with ω hnn hex
    have mono : ∀ a b, a ≤ b → ∑ j ∈ Finset.range a, W j ω ≤ ∑ j ∈ Finset.range b, W j ω :=
      fun a b hab => Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_subset_range.mpr hab)
        (fun i _ _ => hnn i)
    have hm0 : t < ∑ j ∈ Finset.range (Nat.find hex), W j ω := Nat.find_spec hex
    have hm0pos : Nat.find hex ≠ 0 := by
      intro h; rw [h] at hm0; simp at hm0; linarith
    obtain ⟨m, hm⟩ := Nat.exists_eq_succ_of_ne_zero hm0pos
    have hle : ∑ j ∈ Finset.range m, W j ω ≤ t :=
      not_lt.mp (Nat.find_min hex (by omega : m < Nat.find hex))
    have hgt : t < ∑ j ∈ Finset.range (m + 1), W j ω := by rw [hm] at hm0; exact hm0
    have hmem : Wv ω ∈ Ew m := ⟨hle, not_le.mpr hgt⟩
    have hnot : ∀ m' ≠ m, Wv ω ∉ Ew m' := by
      intro m' hne hm'
      rcases Nat.lt_or_gt_of_ne hne with h | h
      · exact hm'.2 ((mono _ _ h).trans hle)
      · exact absurd (hgt.trans_le (mono _ _ h)) (not_lt.mpr hm'.1)
    have hsumX : (∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t then X i ω else 0)
        = ∑ i ∈ Finset.range m, X i ω := by
      rw [tsum_eq_sum (s := Finset.range m)]
      · apply Finset.sum_congr rfl
        intro i hi
        rw [if_pos ((mono _ _ (Finset.mem_range.mp hi)).trans hle)]
      · intro i hi
        rw [Finset.mem_range, not_lt] at hi
        rw [if_neg (not_le.mpr (hgt.trans_le (mono _ _ (by omega))))]
    rw [hsumX]
    rw [tsum_eq_single m (fun m' hne => by simp [term, Set.indicator_of_notMem (hnot m' hne)])]
    simp only [term, Set.indicator_of_mem hmem, Pi.one_apply, one_mul, Gx, Xv]
    rw [← ENNReal.ofReal_prod_of_nonneg (fun i _ => (exp_pos _).le),
      ← ENNReal.ofReal_mul (exp_pos _).le, ← exp_sum, ← exp_add]
    congr 2
    rw [← Finset.mul_sum]
    ring
  have hint_term : ∀ m, ∫⁻ ω, term m ω ∂P = ENNReal.ofReal
      (C * (exp (-(lam * t)) * (lam * t * M) ^ m / (Nat.factorial m : ℝ))) := by
    intro m
    have hind : IndepFun (fun ω => (Ew m).indicator (1 : (ℕ → ℝ) → ENNReal) (Wv ω))
        (fun ω => Gx m (Xv ω)) P :=
      hXW.symm.comp (measurable_one.indicator (hEw m)) (hGx m)
    have key := lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun''
      (f := fun ω => (Ew m).indicator (1 : (ℕ → ℝ) → ENNReal) (Wv ω))
      (g := fun ω => Gx m (Xv ω))
      ((measurable_one.indicator (hEw m)).comp hWv).aemeasurable
      ((hGx m).comp hXv).aemeasurable hind
    simp only [term]
    rw [key]
    have e1 : ∫⁻ ω, (Ew m).indicator (1 : (ℕ → ℝ) → ENNReal) (Wv ω) ∂P = P (Wv ⁻¹' Ew m) := by
      rw [← lintegral_map (measurable_one.indicator (hEw m)) hWv, lintegral_indicator_one (hEw m),
        Measure.map_apply hWv (hEw m)]
    have e2 : ∫⁻ ω, Gx m (Xv ω) ∂P = ENNReal.ofReal C * ENNReal.ofReal M ^ m := by
      simp only [Gx, Xv]
      rw [lintegral_const_mul _ (Finset.measurable_fun_prod _ (fun i _ =>
        ((hXmeas i).const_mul r).exp.ennreal_ofReal))]
      rw [lintegral_prod_eq_prod_lintegral_of_indepFun (Finset.range m)
        (fun i ω => ENNReal.ofReal (exp (r * X i ω)))
        (hX.comp (fun _ x => ENNReal.ofReal (exp (r * x))) (fun _ => by fun_prop))
        (fun i => ((hXmeas i).const_mul r).exp.ennreal_ofReal)]
      simp only [hXm, Finset.prod_const, Finset.card_range]
    rw [e1, e2, hPE m, ← ENNReal.ofReal_pow hM0, ← ENNReal.ofReal_mul (exp_pos _).le,
      ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    rw [mul_pow]
    ring
  have hsum : HasSum (fun m => C * (exp (-(lam * t)) * (lam * t * M) ^ m / (Nat.factorial m : ℝ)))
      (C * (exp (-(lam * t)) * exp (lam * t * M))) := by
    have hs := NormedSpace.expSeries_div_hasSum_exp (lam * t * M)
    rw [← Real.exp_eq_exp_ℝ] at hs
    have := (hs.mul_left (exp (-(lam * t)))).mul_left C
    simpa only [mul_div_assoc] using this
  have hL : ∫⁻ ω, ∑' m, term m ω ∂P = ENNReal.ofReal (C * (exp (-(lam * t)) * exp (lam * t * M))) := by
    rw [lintegral_tsum (fun m => (hterm m).aemeasurable)]
    simp_rw [hint_term]
    rw [← ENNReal.ofReal_tsum_of_nonneg (fun m => by positivity) hsum.summable, hsum.tsum_eq]
  have hae : ∀ᵐ ω ∂P, exp (r * ((∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t
      then X i ω else 0) - c * t)) = (∑' m, term m ω).toReal :=
    hpt.mono (fun ω h => by rw [← h, ENNReal.toReal_ofReal (exp_pos _).le])
  rw [integral_congr_ae hae, integral_toReal (Measurable.ennreal_tsum hterm).aemeasurable
    (ae_lt_top (Measurable.ennreal_tsum hterm) (by rw [hL]; exact ENNReal.ofReal_ne_top)), hL,
    ENNReal.toReal_ofReal (by positivity)]
  simp only [C, ← exp_add]
  congr 1
  ring

/-- Step 3: the adjustment coefficient for exponential claims. If a claim `X` is exponential
with mean `mu > 0`, there are `lam > 0` claims a year, and the premium is
`c = (1 + theta) lam mu` with a positive loading `theta`, then the adjustment equation
`lam (M_X(R) - 1) = c R` has exactly one positive root: `R = theta / ((1 + theta) mu)`. -/
theorem adjustment_coefficient_exponential_claims
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam mu theta : ℝ) (hlam : 0 < lam) (hmu : 0 < mu) (htheta : 0 < theta)
    (X : Ω → ℝ) (hXmeas : Measurable X) (hXexp : P.map X = expMeasure (1 / mu))
    (R : ℝ) (hR : 0 < R) :
    lam * (mgf X P R - 1) = (1 + theta) * lam * mu * R ↔ R = theta / ((1 + theta) * mu) := by
  have hmap : mgf X P R = ∫ x, exp (R * x) ∂(P.map X) := by
    rw [integral_map hXmeas.aemeasurable (by fun_prop)]; rfl
  rw [hXexp, integral_eq_lintegral_of_nonneg_ae (Filter.Eventually.of_forall
    (fun x => (exp_pos _).le)) (by fun_prop)] at hmap
  have ha : 0 < 1 / mu := by positivity
  rcases lt_or_ge R (1 / mu) with hlt | hge
  · rw [lintegral_ofReal_exp_expMeasure_lt ha hlt, ENNReal.toReal_ofReal
      (div_nonneg ha.le (by linarith))] at hmap
    have hmR : mu * R < 1 := by rwa [lt_div_iff₀ hmu, mul_comm] at hlt
    have hM : mgf X P R = 1 / (1 - mu * R) := by
      rw [hmap]; field_simp
    rw [hM]
    have h1 : 0 < 1 - mu * R := by linarith
    constructor
    · intro h
      have h2 : mu * R / (1 - mu * R) = (1 + theta) * mu * R := by
        have : lam * (mu * R / (1 - mu * R)) = lam * ((1 + theta) * mu * R) := by
          calc lam * (mu * R / (1 - mu * R)) = lam * (1 / (1 - mu * R) - 1) := by
                field_simp; ring
            _ = _ := h
            _ = _ := by ring
        exact mul_left_cancel₀ hlam.ne' this
      rw [div_eq_iff h1.ne'] at h2
      have h3 : 1 = (1 + theta) * (1 - mu * R) := by
        have hmR0 : 0 < mu * R := by positivity
        nlinarith
      rw [eq_div_iff (by positivity)]
      nlinarith
    · intro h
      rw [h]
      field_simp
      ring
  · rw [lintegral_ofReal_exp_expMeasure_ge ha hge, ENNReal.toReal_top] at hmap
    rw [hmap]
    constructor
    · intro h
      have : 0 < (1 + theta) * lam * mu * R := by positivity
      nlinarith
    · intro h
      exfalso
      have : theta / ((1 + theta) * mu) < 1 / mu := by
        rw [div_lt_div_iff₀ (by positivity) hmu]; nlinarith
      linarith

-- The insurer: 10 claims a year, mean claim $10,000, 10% loading, surplus $1,000,000.
-- Expected claims a year: 10 × 10,000 = 100,000.
example : (10 : ℕ) * 10000 = 100000 := by norm_num
-- Premium: 1.1 × 100,000 = 110,000.
example : (11 / 10 : ℚ) * 100000 = 110000 := by norm_num
-- R = 1/110,000 solves 10 × (1/(1 - 10,000 R) - 1) = 110,000 R (both sides equal 1).
example : (10 : ℚ) * (1 / (1 - 10000 * (1 / 110000)) - 1) = 110000 * (1 / 110000) := by norm_num
example : (110000 : ℚ) * (1 / 110000) = 1 := by norm_num
-- The closed form theta / ((1 + theta) mu) gives the same R: (1/10) / ((11/10) × 10,000).
example : (1 / 10 : ℚ) / ((1 + 1 / 10) * 10000) = 1 / 110000 := by norm_num
-- Check M_X(R) = 1/(1 - 1/11) = 1.1.
example : (1 : ℚ) / (1 - 1 / 11) = 11 / 10 := by norm_num
-- Exponent R u = 1,000,000 / 110,000 = 100/11, about 9.0909 (also R per $1M).
example : (1000000 : ℚ) * (1 / 110000) = 100 / 11 := by norm_num
-- Claims ten times bigger ($100,000 mean): R per $1M = 1,000,000 / 1,100,000 = 10/11.
example : (1 / 10 : ℚ) / ((1 + 1 / 10) * 100000) * 1000000 = 10 / 11 := by norm_num
-- Mean-variance shortcut 2(c - lam mu)/(lam E[X^2]) with E[X^2] = 2 × 10,000^2: 10 per $1M.
example : (2 : ℚ) * (110000 - 100000) / (10 * (2 * 10000 ^ 2)) * 1000000 = 10 := by norm_num
-- 20 claims a year with premium doubled to 220,000: R is still 1/110,000.
example : (20 : ℚ) * (1 / (1 - 10000 * (1 / 110000)) - 1) = 220000 * (1 / 110000) := by norm_num

#print axioms lundberg_inequality
#print axioms compound_poisson_exponential_growth
#print axioms adjustment_coefficient_exponential_claims
#print axioms lintegral_ofReal_exp_expMeasure_lt
#print axioms lintegral_ofReal_exp_expMeasure_ge
#print axioms indepFun_of_depends
#print axioms lintegral_mul_of_depends
#print axioms blk_disjoint
#print axioms erlH_nonneg
#print axioms erlH_conv
#print axioms erlang_cdf
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'lundberg_inequality' depends on axioms: [propext, Classical.choice, Quot.sound]
'compound_poisson_exponential_growth' depends on axioms: [propext, Classical.choice, Quot.sound]
'adjustment_coefficient_exponential_claims' depends on axioms: [propext, Classical.choice, Quot.sound]
'lintegral_ofReal_exp_expMeasure_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'lintegral_ofReal_exp_expMeasure_ge' depends on axioms: [propext, Classical.choice, Quot.sound]
'indepFun_of_depends' depends on axioms: [propext, Classical.choice, Quot.sound]
'lintegral_mul_of_depends' depends on axioms: [propext, Classical.choice, Quot.sound]
'blk_disjoint' depends on axioms: [propext, Classical.choice, Quot.sound]
'erlH_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'erlH_conv' depends on axioms: [propext, Classical.choice, Quot.sound]
'erlang_cdf' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Raise the loading to 20%.** Guess first: does ruin halve? Set the premium to \$120,000. The bound falls to 0.000000058, about 6 in 100 million: $R$ nearly doubles, and it sits in an exponent.
> - **Start with \$500,000 instead.** Guess first: comfortably under 1%? The bound reads 1.06%, just over. The exact chance is 0.97%, just under. Near a target, the gap between bound and truth decides.
> - **Make the average claim \$50,000,** premium scaled to keep the 10% loading. The bound jumps to 16.23%. Same money, same loading, fatter claims.
> - **Double the claim count to 20 a year and double the premium.** Guess first: more claims, more danger? $R$ stays 9.0909 per million. Scaling the business in time changes nothing about ruin that never ends.

---

## The usual mistake

> [!warning]
> **Believing the loading alone buys safety.** It does not. A 10% loading gives 0.0102% ruin when \$1 million covers a hundred average claims, and 36.63% when it covers ten. What matters is the surplus measured in units of $1/R$, and $R$ depends on the whole claim distribution through $M_X$, not on the percentage loading.
>
> - **Reading the bound as the ruin chance.** 0.0113% is a ceiling; the truth here is 0.0102%. Planning to the bound costs \$10,484.12 of spare capital for a 1% target.
> - **Keeping the root $R = 0$.** Every root finder started near zero will find it. It gives the bound 1. Bracket the search away from zero.
> - **Fitting only a mean and a variance.** The mean-variance rate of 10 per million produces a bound of 0.0000454, below the true 0.0102%. The tail of the claims is what ruins insurers.
> - **Using the bound on heavy-tailed claims.** Fire, liability and catastrophe losses often have Pareto-like tails. There $M_X(r)$ is infinite for every $r > 0$, and a positive $R$ computed from a fitted light-tailed model is an answer to a different portfolio.

---

## Where you meet it in real life

- **Setting capital.** A surplus of ln(1/target)/R caps the model's ruin chance at the target: \$506,568.72 for a 1% target here. Regulators work with one-year horizons instead, but the exponential logic of capital against tail risk is the same.
- **Choosing reinsurance.** Passing the largest claims to a reinsurer thins the tail, which raises $R$, but costs premium, which lowers it. The retention that maximises $R$ is a classic answer: [Credibility and reinsurance](08-credibility-and-reinsurance.md).
- **Pricing the loading.** Inverting the equation gives the premium needed for a target $R$: $c = \lambda(M_X(R)-1)/R$. The premium principle that falls out is called the exponential principle.
- **Queues.** The Pollaczek–Khinchine formula first described waiting times at a single server. The ruin chance equals the chance a customer in the matching queue waits longer than $u$.
- **Next door on this shelf.** The distribution of one year's claim total is the job of [Panjer's recursion](05-panjer-recursion-and-aggregate-claims.md). Ruin asks whether the path of surplus ever crosses zero, a question about all years at once.

> **Say it back**
> An insurer's surplus climbs with premiums and drops with each claim. Ruin is the surplus ever going below zero. The adjustment coefficient $R$ is the rate at which the exponential score $e^{-RU_t}$ is a fair game, found where claim growth $\lambda(M_X(R)-1)$ equals premium $c\,R$. A fair, nonnegative score starting at $e^{-Ru}$ reaches 1 with chance at most $e^{-Ru}$, and ruin forces it past 1: that is Lundberg's inequality. For a million dollars of surplus, 10 claims a year averaging ten thousand dollars and a 10% loading, the bound is 0.0113% and the truth 0.0102%.

---

## What this builds on

- [Aggregate claims](04-collective-risk-and-compound-poisson.md): the claim total as a Poisson number of independent claims, and its moment generating function, which Step 1 turns into the growth rate $\kappa$.
- [Martingales](../../11-Stochastic%20processes%20and%20calculus/02-Martingales/01-martingales.md): fair games and optional stopping, which turn the fair score into the bound in Step 5.

## Where this goes next

- [Credibility and reinsurance](08-credibility-and-reinsurance.md): reinsurance reshapes the claim distribution, and with it $R$; this card's equation is how the trade-off is scored.
- [Reserving](07-reserving-chain-ladder-and-bornhuetter-ferguson.md): the surplus here assumes each claim is paid the moment it happens; reserving handles claims that are reported and settled years later.

Lundberg's inequality says how much surplus keeps a given claim stream survivable; what it leaves open is how an insurer changes the claim stream itself, by passing the tail to a reinsurer, and that is the credibility-and-reinsurance card's question.

---

## Sources

Verified 2026-11-14: every link below resolves to the publisher's page.

- Dickson, David C. M. *Insurance Risk and Ruin*, 2nd ed. Cambridge University Press, 2016. [doi:10.1017/9781316650776](https://doi.org/10.1017/9781316650776). The Cramér–Lundberg model, the adjustment coefficient and Lundberg's inequality by induction on claims, with exponential-claim examples.
- Asmussen, Søren, and Hansjörg Albrecher. *Ruin Probabilities*, 2nd ed. World Scientific, 2010. [doi:10.1142/7431](https://doi.org/10.1142/7431). The martingale proof, the Pollaczek–Khinchine formula, Cramér's asymptotic, and heavy-tailed claims.
- Kovchegov, Yevgeniy. *MTH 467/567 Lectures 24–27: the adjustment coefficient, Lundberg inequality*. Oregon State University, 2018. [PDF](http://sites.science.oregonstate.edu/~kovchegy/math567spring2018/567_lecture24-27.pdf). A short lecture treatment of the adjustment-coefficient equation and the exponential example.
