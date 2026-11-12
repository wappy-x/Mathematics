# Many dimensions: a product grid explodes, random points do not

[Syllabus](../../../SYLLABUS.md) → [Numerical analysis](../README.md) → [Quadrature](../README.md#s05) → Many dimensions

---

## General Overview

A fund holds a basket of five assets, $100 in all. Over a year, each asset grows by a factor somewhere between 0.8 and 1.2, every value equally likely and each asset on its own (an illustrative model). A basket call pays the gain above $100 at year end, and nothing on a loss. What does it pay on average?

That average is an integral over five numbers at once, one growth factor per asset: a five-dimensional integral. The exact answer here is **$2.081597**. The target is the cents digit, an error under 0.005.

Two ways to estimate it:

- **A product grid.** Take 10 evenly spaced values for each asset and try every combination. That is 10 × 10 × 10 × 10 × 10 = 100,000 payoffs. The grid's answer is 2.073600, a true error of −0.007997.
- **Random points.** Draw 10,000 random baskets and average their payoffs. The answer is 2.076778, with a standard error (the typical miss of such an average) of 0.030004.

In five dimensions the grid still wins. Give the random average the same 100,000 evaluations and its standard error is 0.009487, a little more than the grid's miss of 0.007997. But the grid's cost is 10 raised to the number of assets. With 10 assets it is 10,000,000,000 payoffs; with 20 it is 100,000,000,000,000,000,000. The random average still takes 10,000 draws, and its error bar does not grow: with 10 assets its standard error is 0.021106.

**A product grid's cost is its points per axis raised to the dimension d, so its error falls only like N^(−2/d) in its point count N, while an average of N random points misses by σ/√N (σ, the spread of one payoff) in every dimension; the grid wins in low dimension, and random points win once the dimension, or the roughness of the integrand, grows.**

**What kind of fact this is:** two theorems, both proved on this card in Why it works: the product midpoint rule's error bound, and the Monte Carlo error σ/√N. The crossover point is an estimate from the measured constants, and the card says so where it appears.

### The picture: what a 10-point grid costs as the dimension climbs

```
evaluations needed; each block is a factor of 10
grid, 10 per axis, d = 1    █                                10
grid, 10 per axis, d = 2    ██                               100
grid, 10 per axis, d = 3    ███                              1,000
grid, 10 per axis, d = 4    ████                             10,000
grid, 10 per axis, d = 5    █████                            100,000
grid, 10 per axis, d = 10   ██████████                       10,000,000,000
grid, 10 per axis, d = 20   ████████████████████             100,000,000,000,000,000,000
random points, any d        ████                             10,000
```

The bars are logarithmic: each extra block multiplies the count by 10. The grid's bar grows one block per dimension. The random sample's bar does not grow at all.

---

## The formula

The integrand $f$ (the function being integrated) is the payoff of one basket. Its input is a point $\mathbf u = (u_1, \dots, u_d)$ in the unit cube, one number $u_i$ between 0 and 1 per asset; asset $i$ grows by $0.8 + 0.4u_i$. The target is the integral over the whole cube:

$$I = \int_0^1\!\!\cdots\!\int_0^1 f(u_1, \dots, u_d)\,du_1\cdots du_d$$

**The product midpoint rule.** Put $m$ points on each axis, at the midpoints $x_j = (j - \tfrac12)/m$ of $m$ equal pieces of width $h = 1/m$. Try every combination and average:

$$Q_m = \frac{1}{m^d}\sum_{j_1=1}^{m}\cdots\sum_{j_d=1}^{m} f(x_{j_1}, \dots, x_{j_d}), \qquad N = m^d, \qquad |Q_m - I| \le \frac{d\,M\,h^2}{24} = \frac{d\,M}{24}\,N^{-2/d}$$

**Read it aloud:** the grid's estimate is the plain average of f over all m-to-the-d grid points; it costs N = m to the d evaluations, and it misses by at most d times M times h squared over 24, which is N to the minus two over d.

**Monte Carlo.** Draw $N$ independent random points $\mathbf U_1, \dots, \mathbf U_N$, each spread evenly over the cube, and average:

$$\hat I_N = \frac1N\sum_{i=1}^{N} f(\mathbf U_i), \qquad \mathrm{SE} = \frac{\sigma}{\sqrt N}$$

**Read it aloud:** the random estimate is the average of f at N random points, and its root-mean-square miss is one payoff's spread divided by the square root of N, with no d anywhere.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $d$ | the dimension: how many numbers one input has | 5 assets | the grid's cost explodes; Monte Carlo's does not |
| $\mathbf u$, $u_i$, $S$, $L$ | one point in the cube; its $i$-th coordinate; $S$ is the sum of the coordinates; $L$ is a stretch length in the closed-form fold | one basket's five draws | — |
| $f$, $A$, $g$ | the integrand: one basket's payoff, in dollars; $A$ is the basket's average growth factor; $g$ is a function of fewer variables inside the proofs | $f = 100 \times \max(A - 1, 0)$ | — |
| $I$ | the true value: the average payoff | $2.081597 | — |
| $m$, $h$, $x_j$ | grid points per axis; their spacing $1/m$; the $j$-th midpoint | 10; 0.1 | more points per axis: smaller grid error |
| $N$ | number of evaluations, grid points or random points | 100,000 grid; 10,000 random | smaller error, higher cost |
| $Q_m$, $E_k$, $R_k$ | the product-grid estimate; in the proof, exact integration and the midpoint rule along axis $k$ | 2.073600 | — |
| $M$, $C$ | $M$: the largest second derivative of $f$ along any one axis; $C$: the constant in a grid error of the form $C N^{-2/d}$, read off a run | $M$ none, since the payoff has a corner; $C$ = 0.7997 | larger grid error |
| $\hat I_N$, $\mathbf U_i$, $X_i$, $Z_i$ | the Monte Carlo estimate (the hat marks a computed value); the $i$-th random point; its payoff; its miss $X_i - I$ | 2.076778 | — |
| $\sigma$, $s$, $E[\cdot]$ | spread (standard deviation) of one payoff; $s$ is the same spread measured from the run; $E[\cdot]$ is the long-run average | 3.000048; 3.000391 | wider error bar |
| $\mathrm{SE}$ | standard error: the root-mean-square miss of $\hat I_N$ | 0.030004 from the run | — |
| $i$, $j$, $k$ | counters: a coordinate or a draw; a grid position; an axis or a term of a sum | — | — |

### When it holds

- **The grid bound needs a bounded second derivative along each axis.** The basket payoff has a corner where the basket breaks even, so $M$ does not exist and the bound says nothing. The errors still fell like $h^2$ for even $m$, but they jump about: 4 per axis missed by −0.050347, and 5 per axis by −0.056637.
- **Monte Carlo needs independent points spread evenly over the cube.** Reuse one random number for all five assets and the average aims at a different, one-dimensional integral, worth 5.000000; the run reads 4.991290 instead of 2.081597.
- **Monte Carlo needs a finite spread σ.** The rate σ/√N has no $d$ in it, but σ itself depends on the integrand. Here σ fell from 3.000048 at $d = 5$ to 1.505635 at $d = 20$, because a bigger basket averages out; another integrand could make it grow.
- **Costs are counted in evaluations of $f$.** Each random point needs $d$ random numbers, so its work grows in proportion to $d$, not like a power of $d$.

---

## Why it works

### Step 0: a grid spends its points on every axis at once

A one-dimensional rule with 10 points has spacing 0.1, and its error depends on that spacing. A product grid keeps the spacing 0.1 on every axis, so it needs 10 points on each, multiplied together. Its accuracy is set by the spacing, but its cost by the spacing raised to the power $-d$.

Random points do not divide up the axes. Each one is an independent sample of the payoff, and averaging $N$ samples cuts the spread of the average by $\sqrt N$, whatever a sample's dimension. The dimension never enters the error formula.

The rest of this section proves both facts and then sets them side by side. The comparison of rates alone is on [Monte Carlo integration](../../14-Applied%20and%20computational/02-Randomised%20and%20Approximate%20Algorithms/05-monte-carlo-integration-in-many-dimensions.md); this card adds the proofs, the constants and the cost of each.

### Step 1: the product grid's error is at most d one-dimensional errors

In one dimension, the composite midpoint rule with spacing $h$ on 0 to 1 misses by at most $h^2 M / 24$, where $M$ bounds $|g''|$. That bound is proved on [Numerical integration](../../06-Calculus%20and%20analysis/04-Integrals/08-numerical-integration.md).

The product rule applies that one-dimensional rule on each axis in turn. The total error splits into $d$ pieces, one per axis. Each piece is a one-dimensional midpoint error on that axis, after the other axes have been averaged. Averaging cannot make a number bigger than its largest value, so each piece stays within $h^2 M / 24$. Adding $d$ pieces gives $d M h^2 / 24$.

<details>
<summary>Detailed proof: the product rule's error splits axis by axis</summary>

Write $E_k$ for "integrate over axis $k$" and $R_k$ for "apply the midpoint rule on axis $k$". Both act on a function of several variables and remove one of them. The true integral is $E_1 E_2 \cdots E_d f$, and the grid estimate is $R_1 R_2 \cdots R_d f$.

The difference telescopes (each middle term appears once with each sign):

$$E_1 \cdots E_d f - R_1 \cdots R_d f = \sum_{k=1}^{d} R_1 \cdots R_{k-1}\,(E_k - R_k)\,E_{k+1} \cdots E_d f.$$

Fix $k$. Let $g = E_{k+1} \cdots E_d f$, a function of $u_1, \dots, u_k$. Integrating over the later axes does not increase the second derivative along axis $k$, so $|\partial^2 g / \partial u_k^2| \le M$. The one-dimensional bound then gives $|(E_k - R_k) g| \le h^2 M / 24$ at every value of $u_1, \dots, u_{k-1}$.

Finally, $R_1 \cdots R_{k-1}$ takes averages with positive weights that add to 1, so it keeps the bound. Each of the $d$ terms is at most $h^2 M / 24$, and the triangle inequality gives $|Q_m - I| \le d M h^2 / 24$.

</details>

### Step 2: in point count, the grid's rate gets worse with every dimension

The bound is $h^2$, but the cost is $N = m^d = h^{-d}$. So $h = N^{-1/d}$ and the error bound is $\frac{dM}{24} N^{-2/d}$.

To halve the error, $h$ must shrink by $\sqrt 2$ on every axis. That multiplies $N$ by $2^{d/2}$:

| Dimension $d$ | Grid, 10 per axis | Grid rate, power of $1/N$ | To halve the grid error | To halve the Monte Carlo error |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 10 | 2.00 | ×1.41 | ×4 |
| 2 | 100 | 1.00 | ×2.00 | ×4 |
| 3 | 1,000 | 0.67 | ×2.83 | ×4 |
| 4 | 10,000 | 0.50 | ×4.00 | ×4 |
| 5 | 100,000 | 0.40 | ×5.66 | ×4 |
| 10 | 10,000,000,000 | 0.20 | ×32.00 | ×4 |
| 20 | 100,000,000,000,000,000,000 | 0.10 | ×1024.00 | ×4 |

At $d = 4$ the two rates tie. Above it, the grid's rate is the slower one.

**The bound, checked on a smooth integrand.** The basket payoff has a corner, so take a smooth stand-in: $100\,e^{A - 1}$, where $A$ is the basket's average growth factor. Along each axis its second derivative is at most $100 \times 0.08^2 \times e^{0.2}$. With 10 per axis in five dimensions, the bound is 0.00162854 and the true error is −0.00133510. The bound is 1.2198 times the true error, so it is nearly tight. The grid reads low because this integrand curves upward.

**The rate, observed on the basket payoff.** Even $m$ gives a clean ladder. The observed order in $h$ is 2.0368, 2.0118, 2.0059, 2.0035, against the theorem's 2; per $N$ that is 0.4007 at the end, against $2/5 = 0.40$. Odd $m$ breaks the pattern: with odd $m$, some grid points sit exactly on the payoff's corner, and with even $m$ none do.

### Step 3: the Monte Carlo error is σ/√N, whatever the dimension

The full statement, with the 95 percent interval from the central limit theorem, is on [Monte Carlo](../../09-Probability%20and%20statistics/11-Simulation/04-monte-carlo-estimates-and-error.md). The core is short.

Each payoff $X_i = f(\mathbf U_i)$ has mean $I$ and variance $\sigma^2$ (its average squared distance from the mean). The estimate's error is the average of the misses $X_i - I$. Independent misses do not cancel or reinforce on average, so the variances add: $N$ misses give variance $N\sigma^2$, and dividing by $N$ divides the variance by $N^2$.

<details>
<summary>Detailed proof: the variance of an average of independent draws</summary>

Write $Z_i = X_i - I$, the $i$-th draw's miss. Write $E[\cdot]$ for the long-run average (the expectation; it has nothing to do with the axis operators $E_k$ above). Then $E[Z_i] = 0$ and $E[Z_i^2] = \sigma^2$. The estimate's error is $\hat I_N - I = \frac1N \sum_i Z_i$, so

$$E\big[(\hat I_N - I)^2\big] = \frac{1}{N^2}\sum_{i=1}^{N}\sum_{j=1}^{N} E[Z_i Z_j].$$

For $i \ne j$, independence gives $E[Z_i Z_j] = E[Z_i]\,E[Z_j] = 0$. Only the $N$ terms with $i = j$ remain, each equal to $\sigma^2$. So the mean squared error is $\sigma^2 / N$, and the root-mean-square error is $\sigma / \sqrt N$.

Nothing in the argument mentions $d$. The point $\mathbf U_i$ may have five coordinates or thousands; only the spread of $f(\mathbf U_i)$ counts. Chebyshev's inequality turns this into a guarantee: a miss of more than $k$ standard errors has probability at most $1/k^2$.

</details>

**Observed.** Over 40 independent runs at each size, the root-mean-square error was:

| $N$ | Root-mean-square error | $\sigma / \sqrt N$ | Ratio |
| ---: | ---: | ---: | ---: |
| 100 | 0.298810 | 0.300005 | 0.9960 |
| 1,000 | 0.093133 | 0.094870 | 0.9817 |
| 10,000 | 0.028595 | 0.030000 | 0.9531 |

The observed order per $N$, from 100 to 10,000 points, is 0.5096, against the theorem's 0.5.

### Step 4: a faster rate is not yet a smaller error

In five dimensions Monte Carlo has the faster rate, 0.5 against 0.40. Yet at the same budget of 100,000 evaluations the grid misses by −0.007997, while Monte Carlo's standard error is σ/√N = 0.009487. The constants decide.

Model the grid's even-$m$ errors as $C N^{-0.4}$ and read $C$ off the $m = 10$ grid: $C = 0.7997$. Monte Carlo's constant is $\sigma = 3.000048$. The two error curves cross where $C N^{-0.4} = \sigma N^{-0.5}$, that is at $N = (\sigma / C)^{10}$ = 551,938 points. This is an **estimate**, extrapolated from that one reading of $C$, not a run. Below it the grid wins in five dimensions; above it, random points do.

Double the dimension and the picture flips at once. In ten dimensions a grid of 3 per axis costs 59,049 evaluations and misses by −0.098967. Monte Carlo with 10,000 draws has standard error 0.021106. The grid's miss is 4.69 of those standard errors.

### Step 5: when each method wins

| Situation | Method that wins | Why |
| --- | --- | --- |
| Smooth integrand, 1 to 3 dimensions | Product rule, ideally a [Gaussian quadrature](03-gaussian-quadrature.md) rule on each axis | A high-order rule needs few points per axis, and $m^d$ stays small |
| Smooth integrand, moderate dimension | Sparse grids or quasi-Monte Carlo ([Quasi-Monte Carlo and sparse grids](07-quasi-monte-carlo-and-sparse-grids.md)) | They keep part of a rule's accuracy without the full $m^d$ cost |
| High dimension, rough integrand, or an error bar is needed | Monte Carlo | σ/√N in any dimension, and $s$ from the run gives the error bar for free |

A grid gives no error bar of its own. Monte Carlo's comes from the same run that gives the estimate.

---

## Worked numbers, by hand

The basket pays $100 \times \max(A - 1, 0)$, where $A = 0.8 + 0.4 \times S/5$ and $S = u_1 + \dots + u_5$. Then $A - 1 = 0.08\,(S - 2.5)$, so the payoff is $8 \times \max(S - 2.5, 0)$.

The sum $S$ is symmetric about its mean 2.5, so $\max(S - 2.5, 0)$ has the same average as $\max(2.5 - S, 0)$. That average has a closed form (the fold below derives it).

| Step | Arithmetic | Value |
| --- | --- | --- |
| first term | $2.5^6$ | 244.140625 |
| second term | $5 \times 1.5^6$ | 56.953125 |
| third term | $10 \times 0.5^6$ | 0.156250 |
| alternating sum | $244.140625 - 56.953125 + 0.156250$ | 187.343750 |
| divide by $6! = 720$ | $187.343750 / 720$ | 0.260200 |
| times 8: the average payoff $I$ | $8 \times 0.260200$ | **$2.081597** |
| average squared payoff | $64 \times 5/24$ | 13.333333 |
| variance $\sigma^2$ | $13.333333 - 2.081597^2 = 13.333333 - 4.333047$ | 9.000286 |
| spread $\sigma$ | $\sqrt{9.000286}$ | 3.000048 |
| Monte Carlo standard error, $N = 10{,}000$ | $3.000048 / 100$ | 0.030000 |
| grid, 10 per axis, $N = 100{,}000$ | true error $2.073600 - 2.081597$ | −0.007997 |

The basket call is worth $2.08 on average per $100. The 100,000-point grid reads 2.0736, a miss of 0.008: within a cent, but just outside the 0.005 target. 10,000 random points give 2.08 ± 0.03.

<details>
<summary>Where the closed form comes from</summary>

The sum $S$ of five independent uniform numbers has a density (the Irwin–Hall density) built from polynomial pieces. One piece switches on at each whole number $k$ from 0 to 5. It is $(S - k)^4 / 4!$ beyond $k$ and zero before, weighted by $(-1)^k \binom5k$: signs alternate, and the weights are 1, 5, 10 and so on.

To average $\max(2.5 - S, 0)$, multiply each piece by $(2.5 - S)$ and integrate from $k$ up to 2.5. With $L = 2.5 - k$ the length of that stretch, a beta integral gives $L^6 / 6!$. Only the pieces for $k = 0, 1, 2$ switch on below 2.5. That gives the three terms in the table: $2.5^6$, $5 \times 1.5^6$ and $10 \times 0.5^6$, over $6!$.

For the second moment, $E[(S - 2.5)^2] = \mathrm{Var}\,S = 5/12$. By the same symmetry, the positive and negative parts each carry half, so $E[\max(S - 2.5, 0)^2] = 5/24$. Times $8^2 = 64$ gives the average squared payoff.

</details>

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Grid at the corners of each cell instead of the midpoints, 10 per axis | 1.216600, error −0.864997 | The corner rule has order 1 in $h$, not 2, and it misses on the same side on every axis |
| One random number reused for all five assets | 4.991290, error +2.909693 | The draws are not independent, so the average estimates a one-dimensional integral, worth 5.000000, not the basket |
| Error bar $s/N$ instead of $s/\sqrt N$ | 0.000300; the true error is 16.1 of these | It shrinks the bar by a further factor of $\sqrt N$, claiming precision the run does not have |
| Payoff with a corner, 5 per axis instead of 4 | error −0.056637, worse than −0.050347 | The bound's second derivative does not exist; more points can do worse |
| Grid in 10 dimensions, 3 per axis | 59,049 evaluations, error −0.098967 | 3 points per axis cannot resolve anything; it is 4.69 Monte Carlo standard errors off |

---

## Code, from first principles, and it actually runs

The script reaches the basket's value by three independent roads. Road 1 is the closed form: exact rational arithmetic in Python, and the same formula in floating point in Rust. Road 2 is the product midpoint grid, which closes in on road 1 at the proved order 2 in $h$. Road 3 is Monte Carlo with a SplitMix64 generator (a small, fully specified random-number recipe from wing 09), seed 2026, which lands within a few standard errors. Forty repeat runs then test σ/√N itself, and a smooth integrand tests the grid's bound. Both programs print identical output.

### Python

```python
# Many dimensions: a product grid against random points.  Standard library only.
# Five assets; over a year each grows by a factor 0.8 + 0.4u, u uniform on 0 to 1
# (illustrative).  Wanted: the expected payoff of a $100 basket call,
# 100 * max(average factor - 1, 0), which is an integral over the 5-dimensional cube.
from fractions import Fraction
from math import comb, factorial, sqrt, exp, log
from itertools import product

MASK = (1 << 64) - 1
def splitmix64(seed):                      # the generator, written out, as in wing 09
    state = seed
    def next_u():
        nonlocal state
        state = (state + 0x9E3779B97F4A7C15) & MASK
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        z ^= z >> 31
        return (z >> 11) * 2.0 ** -53       # uniform on [0, 1)
    return next_u

def basket(us):                             # average growth factor, 0.8 to 1.2
    s = 0.0
    for u in us:
        s += u
    return 0.8 + 0.4 * s / len(us)

def payoff(us):                             # dollars, on a $100 basket
    return 100.0 * max(basket(us) - 1.0, 0.0)

def exact(d):                               # road 1: exact rationals
    # payoff = (40/d)(S - d/2)+ with S = u1 + ... + ud.  S is symmetric about d/2, so
    # E(S - d/2)+ = E(d/2 - S)+ = sum_k (-1)^k C(d,k) (d/2 - k)+^(d+1) / (d+1)!.
    c = Fraction(d, 2)
    low = sum((-1) ** k * comb(d, k) * (c - k) ** (d + 1) for k in range(d + 1) if c > k)
    mean = Fraction(40, d) * low / factorial(d + 1)
    var = Fraction(40, d) ** 2 * Fraction(d, 24) - mean ** 2   # E(S - d/2)+^2 = Var S / 2 = d/24
    return float(mean), sqrt(float(var))

def grid(d, m, f, left=False):              # road 2: the product midpoint rule, m per axis
    xs = [(j + (0.0 if left else 0.5)) / m for j in range(m)]
    t = 0.0
    for p in product(xs, repeat=d):
        t += f(p)
    return t / m ** d

def monte_carlo(d, n, nxt, same=False):     # road 3: n random points, mean and s
    t = t2 = 0.0
    for _ in range(n):
        if same:
            u = nxt(); x = payoff([u] * d)  # wrong: one draw reused for every asset
        else:
            x = payoff([nxt() for _ in range(d)])
        t += x; t2 += x * x
    mean = t / n
    return mean, sqrt((t2 - n * mean * mean) / (n - 1))

I5, sig5 = exact(5)
print(f"exact, d=5      I = {I5:.6f}   sigma = {sig5:.6f}")
assert abs(I5 - 2.081597) < 1e-6 and abs(sig5 - 3.000048) < 1e-6
t = [comb(5, k) * (2.5 - k) ** 6 for k in range(3)]; low = t[0] - t[1] + t[2]
print(f"hand: {t[0]:.6f} - {t[1]:.6f} + {t[2]:.6f} = {low:.6f}; /720 = {low / 720:.6f}; x8 = {8 * low / 720:.6f}")
print(f"hand: E[X^2] = 64 x 5/24 = {64 * 5 / 24:.6f}; minus I^2 {I5 * I5:.6f} = variance {64 * 5 / 24 - I5 * I5:.6f}")

print("grid, d=5:  m   N = m^5   estimate   true error")
err = {}
for m in range(2, 11):
    g = grid(5, m, payoff); err[m] = g - I5
    print(f"           {m:2d} {m ** 5:9d} {g:10.6f} {err[m]:+12.6f}")
print("observed order in h (even m):")
for a, b in ((2, 4), (4, 6), (6, 8), (8, 10)):
    p = log(abs(err[a] / err[b])) / log(b / a)
    print(f"  m {a:2d} -> {b:2d}   order {p:.4f}   per N {p / 5:.4f}")
assert abs(log(abs(err[8] / err[10])) / log(10 / 8) - 2.0) < 0.1   # h^2, as proved
assert abs(err[5]) > abs(err[4])                                     # the kink: more points, worse
assert abs(err[10]) < 0.01                                           # grid closes in on road 1

# the smooth check: f = 100 exp(A - 1) has f_ii <= 100 * 0.08^2 * e^0.2 everywhere
smooth = lambda us: 100.0 * exp(basket(us) - 1.0)
J = 100.0 * exp(-0.2) * ((exp(0.08) - 1.0) / 0.08) ** 5
ej = grid(5, 10, smooth) - J
bound = 5 * 100.0 * 0.0064 * exp(0.2) * 0.1 ** 2 / 24
print(f"smooth, m=10: true error {ej:+.8f}  bound {bound:.8f}  ratio {bound / -ej:.4f}")
assert 0 < -ej <= bound   # convex f: the midpoint grid reads low

nxt = splitmix64(2026)
est, s = monte_carlo(5, 10000, nxt)
e5, s5, se = est, s, s / sqrt(10000)
print(f"MC, d=5, N=10000: estimate {est:.6f}  s {s:.6f}  SE {se:.6f}")
print(f"  true error {est - I5:+.6f} = {(est - I5) / se:+.4f} SE;  sigma/sqrt(N) {sig5 / 100:.6f}")
assert abs(est - I5) < 4 * se and abs(s / sig5 - 1) < 0.05

print("MC root-mean-square error over 40 runs, d=5:")
rms = {}
for n in (100, 1000, 10000):
    sq = 0.0
    for _ in range(40):
        e, _s = monte_carlo(5, n, nxt); sq += (e - I5) ** 2
    rms[n] = sqrt(sq / 40)
    print(f"  N {n:6d}   rms {rms[n]:.6f}   sigma/sqrt(N) {sig5 / sqrt(n):.6f}   ratio {rms[n] * sqrt(n) / sig5:.4f}")
    assert abs(rms[n] * sqrt(n) / sig5 - 1) < 0.35
print(f"  observed order per N, 100 -> 10000: {log(rms[100] / rms[10000]) / log(100):.4f}")

C = abs(err[10]) * 100000 ** 0.4                 # grid error about C N^-0.4 (even m)
print(f"crossover estimate, d=5: C {C:.4f}  MC wins above N = {(sig5 / C) ** 10:.0f}")
print(f"equal budget, d=5, N=100000: grid error {err[10]:+.6f}  MC sigma/sqrt(N) {sig5 / sqrt(100000):.6f}")
assert abs(err[10]) < sig5 / sqrt(100000)                          # below the crossover, the grid wins
print("cost: d   grid 10 per axis   grid rate 2/d   x to halve grid error   x to halve MC error")
for d in (1, 2, 3, 4, 5, 10, 20):
    print(f"   {d:3d} {10 ** d:22d} {2 / d:9.2f} {2 ** (d / 2):14.2f} {4:12d}")

se_mc = {}
for d in (10, 20):
    Id, sd = exact(d)
    est, s = monte_carlo(d, 10000, nxt)
    print(f"d={d}: I {Id:.6f} sigma {sd:.6f}  MC {est:.6f} SE {s / 100:.6f} err {est - Id:+.6f}")
    assert abs(est - Id) < 4 * s / 100
    se_mc[d] = s / 100
I10 = exact(10)[0]
for m in (2, 3):
    g = grid(10, m, payoff)
    print(f"grid d=10, m={m}: N {m ** 10:6d}  estimate {g:.6f}  true error {g - I10:+.6f}")
print(f"  m=3 grid error / MC SE at d=10: {abs(g - I10) / se_mc[10]:.2f}")

print("what breaks, d=5:")
gl = grid(5, 10, payoff, left=True)
print(f"  left-corner grid, m=10      {gl:.6f}  error {gl - I5:+.6f}")
bad, sb = monte_carlo(5, 10000, splitmix64(2026), same=True)
aim = 100 * 0.2 * 0.5 / 2                  # what that averages: 100 max(0.4u - 0.2, 0) on 0 to 1, a triangle
print(f"  one draw for all 5 assets   {bad:.6f}  error {bad - I5:+.6f}  aims at {aim:.6f}")
print(f"  error bar s/N, not s/sqrt(N) {s5 / 10000:.6f}  true error is {abs(e5 - I5) / (s5 / 10000):.1f} of them")
assert abs(bad - aim) < 4 * sb / 100       # it estimates that 1-D integral, not the basket
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
exact, d=5      I = 2.081597   sigma = 3.000048
hand: 244.140625 - 56.953125 + 0.156250 = 187.343750; /720 = 0.260200; x8 = 2.081597
hand: E[X^2] = 64 x 5/24 = 13.333333; minus I^2 4.333047 = variance 9.000286
grid, d=5:  m   N = m^5   estimate   true error
            2        32   1.875000    -0.206597
            3       243   1.920439    -0.161158
            4      1024   2.031250    -0.050347
            5      3125   2.024960    -0.056637
            6      7776   2.059328    -0.022269
            7     16807   2.052886    -0.028711
            8     32768   2.069092    -0.012505
            9     59049   2.064274    -0.017323
           10    100000   2.073600    -0.007997
observed order in h (even m):
  m  2 ->  4   order 2.0368   per N 0.4074
  m  4 ->  6   order 2.0118   per N 0.4024
  m  6 ->  8   order 2.0059   per N 0.4012
  m  8 -> 10   order 2.0035   per N 0.4007
smooth, m=10: true error -0.00133510  bound 0.00162854  ratio 1.2198
MC, d=5, N=10000: estimate 2.076778  s 3.000391  SE 0.030004
  true error -0.004819 = -0.1606 SE;  sigma/sqrt(N) 0.030000
MC root-mean-square error over 40 runs, d=5:
  N    100   rms 0.298810   sigma/sqrt(N) 0.300005   ratio 0.9960
  N   1000   rms 0.093133   sigma/sqrt(N) 0.094870   ratio 0.9817
  N  10000   rms 0.028595   sigma/sqrt(N) 0.030000   ratio 0.9531
  observed order per N, 100 -> 10000: 0.5096
crossover estimate, d=5: C 0.7997  MC wins above N = 551938
equal budget, d=5, N=100000: grid error -0.007997  MC sigma/sqrt(N) 0.009487
cost: d   grid 10 per axis   grid rate 2/d   x to halve grid error   x to halve MC error
     1                     10      2.00           1.41            4
     2                    100      1.00           2.00            4
     3                   1000      0.67           2.83            4
     4                  10000      0.50           4.00            4
     5                 100000      0.40           5.66            4
    10            10000000000      0.20          32.00            4
    20  100000000000000000000      0.10        1024.00            4
d=10: I 1.464160 sigma 2.126711  MC 1.429174 SE 0.021106 err -0.034987
d=20: I 1.032665 sigma 1.505635  MC 1.015184 SE 0.014737 err -0.017482
grid d=10, m=2: N   1024  estimate 1.230469  true error -0.233692
grid d=10, m=3: N  59049  estimate 1.365194  true error -0.098967
  m=3 grid error / MC SE at d=10: 4.69
what breaks, d=5:
  left-corner grid, m=10      1.216600  error -0.864997
  one draw for all 5 assets   4.991290  error +2.909693  aims at 5.000000
  error bar s/N, not s/sqrt(N) 0.000300  true error is 16.1 of them
ALL CHECKS PASS
```

### Rust

```rust
// Many dimensions: a product grid against random points.  Rust std only.
// Five assets; over a year each grows by a factor 0.8 + 0.4u, u uniform on 0 to 1
// (illustrative).  Wanted: the expected payoff of a $100 basket call,
// 100 * max(average factor - 1, 0), which is an integral over the 5-dimensional cube.

struct SplitMix64 { state: u64 } // the generator, written out, as in wing 09
impl SplitMix64 {
    fn next_u(&mut self) -> f64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (z >> 11) as f64 * (2.0f64).powi(-53) // uniform on [0, 1)
    }
}

fn basket(us: &[f64]) -> f64 { // average growth factor, 0.8 to 1.2
    let mut s = 0.0;
    for u in us { s += u; }
    0.8 + 0.4 * s / us.len() as f64
}

fn payoff(us: &[f64]) -> f64 { 100.0 * (basket(us) - 1.0).max(0.0) } // dollars, $100 basket

fn smooth(us: &[f64]) -> f64 { 100.0 * (basket(us) - 1.0).exp() }

fn comb(n: usize, k: usize) -> f64 { (0..k).fold(1.0, |a, i| a * (n - i) as f64 / (i + 1) as f64) }

fn exact(d: usize) -> (f64, f64) { // road 1: the closed form, in floating point
    // E(d/2 - S)+ = sum_k (-1)^k C(d,k) (d/2 - k)+^(d+1) / (d+1)!, and S is symmetric about d/2
    let c = d as f64 / 2.0;
    let mut low = 0.0;
    for k in 0..=d {
        if c > k as f64 {
            let sign = if k % 2 == 0 { 1.0 } else { -1.0 };
            low += sign * comb(d, k) * (c - k as f64).powi(d as i32 + 1);
        }
    }
    let fact: f64 = (1..=d + 1).map(|i| i as f64).product();
    let mean = 40.0 / d as f64 * low / fact;
    let var = (40.0 / d as f64).powi(2) * (d as f64 / 24.0) - mean * mean;
    (mean, var.sqrt())
}

fn grid(d: usize, m: usize, f: fn(&[f64]) -> f64, left: bool) -> f64 { // road 2
    let off = if left { 0.0 } else { 0.5 };
    let xs: Vec<f64> = (0..m).map(|j| (j as f64 + off) / m as f64).collect();
    let mut idx = vec![0usize; d];
    let mut p = vec![0.0; d];
    let mut t = 0.0;
    loop {
        for a in 0..d { p[a] = xs[idx[a]]; }
        t += f(&p);
        let mut a = d; // odometer: the last axis turns fastest
        loop {
            if a == 0 { return t / (m as f64).powi(d as i32); }
            a -= 1;
            idx[a] += 1;
            if idx[a] < m { break; }
            idx[a] = 0;
        }
    }
}

fn monte_carlo(d: usize, n: usize, g: &mut SplitMix64, same: bool) -> (f64, f64) { // road 3
    let (mut t, mut t2) = (0.0, 0.0);
    for _ in 0..n {
        let x = if same {
            let u = g.next_u(); payoff(&vec![u; d]) // wrong: one draw reused for every asset
        } else {
            let us: Vec<f64> = (0..d).map(|_| g.next_u()).collect(); payoff(&us)
        };
        t += x; t2 += x * x;
    }
    let mean = t / n as f64;
    (mean, ((t2 - n as f64 * mean * mean) / (n as f64 - 1.0)).sqrt())
}

fn main() {
    let (i5, sig5) = exact(5);
    println!("exact, d=5      I = {:.6}   sigma = {:.6}", i5, sig5);
    assert!((i5 - 2.081597).abs() < 1e-6 && (sig5 - 3.000048).abs() < 1e-6);
    let t: Vec<f64> = (0..3).map(|k| comb(5, k) * (2.5 - k as f64).powi(6)).collect();
    let low = t[0] - t[1] + t[2];
    println!("hand: {:.6} - {:.6} + {:.6} = {:.6}; /720 = {:.6}; x8 = {:.6}", t[0], t[1], t[2], low, low / 720.0, 8.0 * low / 720.0);
    println!("hand: E[X^2] = 64 x 5/24 = {:.6}; minus I^2 {:.6} = variance {:.6}", 64.0 * 5.0 / 24.0, i5 * i5, 64.0 * 5.0 / 24.0 - i5 * i5);

    println!("grid, d=5:  m   N = m^5   estimate   true error");
    let mut err = [0.0f64; 11];
    for m in 2..=10usize {
        let g = grid(5, m, payoff, false); err[m] = g - i5;
        println!("           {:2} {:9} {:10.6} {:+12.6}", m, m.pow(5), g, err[m]);
    }
    println!("observed order in h (even m):");
    for (a, b) in [(2usize, 4usize), (4, 6), (6, 8), (8, 10)] {
        let p = (err[a] / err[b]).abs().ln() / (b as f64 / a as f64).ln();
        println!("  m {:2} -> {:2}   order {:.4}   per N {:.4}", a, b, p, p / 5.0);
    }
    assert!(((err[8] / err[10]).abs().ln() / (10.0f64 / 8.0).ln() - 2.0).abs() < 0.1); // h^2
    assert!(err[5].abs() > err[4].abs()); // the kink: more points, worse
    assert!(err[10].abs() < 0.01); // grid closes in on road 1

    // the smooth check: f = 100 exp(A - 1) has f_ii <= 100 * 0.08^2 * e^0.2 everywhere
    let j = 100.0 * (-0.2f64).exp() * (((0.08f64).exp() - 1.0) / 0.08).powf(5.0);
    let ej = grid(5, 10, smooth, false) - j;
    let bound = 5.0 * 100.0 * 0.0064 * (0.2f64).exp() * (0.1f64).powf(2.0) / 24.0;
    println!("smooth, m=10: true error {:+.8}  bound {:.8}  ratio {:.4}", ej, bound, bound / -ej);
    assert!(0.0 < -ej && -ej <= bound); // convex f: the midpoint grid reads low

    let mut g = SplitMix64 { state: 2026 };
    let (e5, s5) = monte_carlo(5, 10000, &mut g, false);
    let se = s5 / (10000.0f64).sqrt();
    println!("MC, d=5, N=10000: estimate {:.6}  s {:.6}  SE {:.6}", e5, s5, se);
    println!("  true error {:+.6} = {:+.4} SE;  sigma/sqrt(N) {:.6}", e5 - i5, (e5 - i5) / se, sig5 / 100.0);
    assert!((e5 - i5).abs() < 4.0 * se && (s5 / sig5 - 1.0).abs() < 0.05);

    println!("MC root-mean-square error over 40 runs, d=5:");
    let mut rms = Vec::new();
    for n in [100usize, 1000, 10000] {
        let mut sq = 0.0;
        for _ in 0..40 { let (e, _) = monte_carlo(5, n, &mut g, false); sq += (e - i5) * (e - i5); }
        let r = (sq / 40.0).sqrt();
        let rt = (n as f64).sqrt();
        println!("  N {:6}   rms {:.6}   sigma/sqrt(N) {:.6}   ratio {:.4}", n, r, sig5 / rt, r * rt / sig5);
        assert!((r * rt / sig5 - 1.0).abs() < 0.35);
        rms.push(r);
    }
    println!("  observed order per N, 100 -> 10000: {:.4}", (rms[0] / rms[2]).ln() / (100.0f64).ln());

    let c = err[10].abs() * (100000.0f64).powf(0.4); // grid error about C N^-0.4 (even m)
    println!("crossover estimate, d=5: C {:.4}  MC wins above N = {:.0}", c, (sig5 / c).powf(10.0));
    println!("equal budget, d=5, N=100000: grid error {:+.6}  MC sigma/sqrt(N) {:.6}", err[10], sig5 / (100000.0f64).sqrt());
    assert!(err[10].abs() < sig5 / (100000.0f64).sqrt()); // below the crossover, the grid wins
    println!("cost: d   grid 10 per axis   grid rate 2/d   x to halve grid error   x to halve MC error");
    for d in [1u32, 2, 3, 4, 5, 10, 20] {
        println!("   {:3} {:22} {:9.2} {:14.2} {:12}", d, 10u128.pow(d), 2.0 / d as f64,
                 (2.0f64).powf(d as f64 / 2.0), 4);
    }

    let mut se10 = 0.0;
    for d in [10usize, 20] {
        let (id, sd) = exact(d);
        let (est, s) = monte_carlo(d, 10000, &mut g, false);
        println!("d={}: I {:.6} sigma {:.6}  MC {:.6} SE {:.6} err {:+.6}", d, id, sd, est, s / 100.0, est - id);
        assert!((est - id).abs() < 4.0 * s / 100.0);
        if d == 10 { se10 = s / 100.0; }
    }
    let i10 = exact(10).0;
    let mut last = 0.0;
    for m in [2usize, 3] {
        let gr = grid(10, m, payoff, false);
        println!("grid d=10, m={}: N {:6}  estimate {:.6}  true error {:+.6}", m, m.pow(10), gr, gr - i10);
        last = gr;
    }
    println!("  m=3 grid error / MC SE at d=10: {:.2}", (last - i10).abs() / se10);

    println!("what breaks, d=5:");
    let gl = grid(5, 10, payoff, true);
    println!("  left-corner grid, m=10      {:.6}  error {:+.6}", gl, gl - i5);
    let (bad, sb) = monte_carlo(5, 10000, &mut SplitMix64 { state: 2026 }, true);
    let aim = 100.0 * 0.2 * 0.5 / 2.0; // what that averages: 100 max(0.4u - 0.2, 0) on 0 to 1, a triangle
    println!("  one draw for all 5 assets   {:.6}  error {:+.6}  aims at {:.6}", bad, bad - i5, aim);
    println!("  error bar s/N, not s/sqrt(N) {:.6}  true error is {:.1} of them", s5 / 10000.0, (e5 - i5).abs() / (s5 / 10000.0));
    assert!((bad - aim).abs() < 4.0 * sb / 100.0); // it estimates that 1-D integral, not the basket
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
exact, d=5      I = 2.081597   sigma = 3.000048
hand: 244.140625 - 56.953125 + 0.156250 = 187.343750; /720 = 0.260200; x8 = 2.081597
hand: E[X^2] = 64 x 5/24 = 13.333333; minus I^2 4.333047 = variance 9.000286
grid, d=5:  m   N = m^5   estimate   true error
            2        32   1.875000    -0.206597
            3       243   1.920439    -0.161158
            4      1024   2.031250    -0.050347
            5      3125   2.024960    -0.056637
            6      7776   2.059328    -0.022269
            7     16807   2.052886    -0.028711
            8     32768   2.069092    -0.012505
            9     59049   2.064274    -0.017323
           10    100000   2.073600    -0.007997
observed order in h (even m):
  m  2 ->  4   order 2.0368   per N 0.4074
  m  4 ->  6   order 2.0118   per N 0.4024
  m  6 ->  8   order 2.0059   per N 0.4012
  m  8 -> 10   order 2.0035   per N 0.4007
smooth, m=10: true error -0.00133510  bound 0.00162854  ratio 1.2198
MC, d=5, N=10000: estimate 2.076778  s 3.000391  SE 0.030004
  true error -0.004819 = -0.1606 SE;  sigma/sqrt(N) 0.030000
MC root-mean-square error over 40 runs, d=5:
  N    100   rms 0.298810   sigma/sqrt(N) 0.300005   ratio 0.9960
  N   1000   rms 0.093133   sigma/sqrt(N) 0.094870   ratio 0.9817
  N  10000   rms 0.028595   sigma/sqrt(N) 0.030000   ratio 0.9531
  observed order per N, 100 -> 10000: 0.5096
crossover estimate, d=5: C 0.7997  MC wins above N = 551938
equal budget, d=5, N=100000: grid error -0.007997  MC sigma/sqrt(N) 0.009487
cost: d   grid 10 per axis   grid rate 2/d   x to halve grid error   x to halve MC error
     1                     10      2.00           1.41            4
     2                    100      1.00           2.00            4
     3                   1000      0.67           2.83            4
     4                  10000      0.50           4.00            4
     5                 100000      0.40           5.66            4
    10            10000000000      0.20          32.00            4
    20  100000000000000000000      0.10        1024.00            4
d=10: I 1.464160 sigma 2.126711  MC 1.429174 SE 0.021106 err -0.034987
d=20: I 1.032665 sigma 1.505635  MC 1.015184 SE 0.014737 err -0.017482
grid d=10, m=2: N   1024  estimate 1.230469  true error -0.233692
grid d=10, m=3: N  59049  estimate 1.365194  true error -0.098967
  m=3 grid error / MC SE at d=10: 4.69
what breaks, d=5:
  left-corner grid, m=10      1.216600  error -0.864997
  one draw for all 5 assets   4.991290  error +2.909693  aims at 5.000000
  error bar s/N, not s/sqrt(N) 0.000300  true error is 16.1 of them
ALL CHECKS PASS
```

### Lean

Lean proves the grid's error bound, its cost and rate, and the Monte Carlo mean squared error, for every dimension d and every m and N.

- Suppose f has two continuous derivatives, and its second derivative along each axis is at most M in size on the cube. Then $|Q_m - I| \le d\,M\,h^2/24$, with $h = 1/m$.
- A grid of m points on each of d axes has $N = m^d$ points, and $h^2 = N^{-2/d}$, so the bound falls like $N^{-2/d}$.
- Suppose $\mathbf U_1, \dots, \mathbf U_N$ are independent, each spread evenly over the cube, and $f^2$ has a finite average there. Then $E[(\hat I_N - I)^2] = \sigma^2/N$ exactly, with no $d$ in it.
- The hand arithmetic holds exactly: the grid sizes $10^5$, $10^{10}$, $10^{20}$, $2^{10}$, $3^{10}$ and $4^{10}$, and the closed-form steps giving $I = 1199/576$. So do the average squared payoff 40/3, $\sigma^2 = 40/3 - I^2$ and the reused-draw target 5.

The closed form, the runs, the observed orders, the crossover estimate and the failure cases are left to the Python and Rust checks.

```lean
-- Many dimensions: the product midpoint grid on the d-cube misses by at most d·M·h²/24 at a cost of m^d points, while the average of N independent uniform random points has mean-square error σ²/N in every dimension.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.Prod

open MeasureTheory ProbabilityTheory Set

lemma second_diff_bound (g : ℝ → ℝ) (hg : ContDiff ℝ 2 g) (M : ℝ)
    (hM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M) (c t : ℝ) (ht : 0 ≤ t)
    (h1 : 0 ≤ c - t) (h2 : c + t ≤ 1) :
    |g (c + t) + g (c - t) - 2 * g c| ≤ M * t ^ 2 := by
  obtain ⟨hd1, -, hcd⟩ := contDiff_succ_iff_deriv.1 (show ContDiff ℝ (1 + 1) g from hg)
  have hd2 : Differentiable ℝ (deriv g) := hcd.differentiable one_ne_zero
  have hcont : Continuous (deriv g) := hcd.continuous
  have lip : ∀ y ∈ Icc (0 : ℝ) 1, ∀ z ∈ Icc (0 : ℝ) 1, |deriv g y - deriv g z| ≤ M * |y - z| := by
    intro y hy z hz
    have := (convex_Icc (0 : ℝ) 1).norm_image_sub_le_of_norm_deriv_le
      (fun x _ => hd2 x) (fun x hx => by simpa using hM x hx) hz hy
    simpa [Real.norm_eq_abs] using this
  have hftc : ∫ s in (0 : ℝ)..t, (deriv g (c + s) * 1 + deriv g (c - s) * (-1)) =
      (g (c + t) + g (c - t)) - (g (c + 0) + g (c - 0)) := by
    apply intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun s => g (c + s) + g (c - s))
    · intro s _
      exact ((hd1 (c + s)).hasDerivAt.comp s ((hasDerivAt_id s).const_add c)).add
        ((hd1 (c - s)).hasDerivAt.comp s ((hasDerivAt_id s).const_sub c))
    · apply Continuous.intervalIntegrable
      fun_prop
  simp only [add_zero, sub_zero, mul_one, mul_neg_one] at hftc
  rw [show g (c + t) + g (c - t) - 2 * g c = g (c + t) + g (c - t) - (g c + g c) by ring,
    ← hftc]
  have hb : ‖∫ s in (0 : ℝ)..t, (deriv g (c + s) + -deriv g (c - s))‖ ≤
      ∫ s in (0 : ℝ)..t, 2 * M * s := by
    apply intervalIntegral.norm_integral_le_of_norm_le ht
    · refine Filter.Eventually.of_forall (fun s hs => ?_)
      have := lip (c + s) ⟨by linarith [hs.1], by linarith [hs.2]⟩ (c - s)
        ⟨by linarith [hs.2], by linarith [hs.1]⟩
      rw [Real.norm_eq_abs, ← sub_eq_add_neg]
      calc |deriv g (c + s) - deriv g (c - s)| ≤ M * |c + s - (c - s)| := this
        _ = 2 * M * s := by
          rw [show c + s - (c - s) = 2 * s by ring, abs_of_nonneg (by linarith [hs.1])]; ring
    · apply Continuous.intervalIntegrable; fun_prop
  rw [Real.norm_eq_abs] at hb
  refine hb.trans (le_of_eq ?_)
  rw [intervalIntegral.integral_const_mul, integral_id]
  ring

#print axioms second_diff_bound

lemma cell_bound (g : ℝ → ℝ) (hg : ContDiff ℝ 2 g) (M : ℝ)
    (hM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M) (c r : ℝ) (hr : 0 ≤ r)
    (h1 : 0 ≤ c - r) (h2 : c + r ≤ 1) :
    |(∫ x in (c - r)..(c + r), g x) - 2 * r * g c| ≤ M * r ^ 3 / 3 := by
  have hgc : Continuous g := hg.continuous
  have e : (∫ x in (c - r)..(c + r), g x) - 2 * r * g c =
      ∫ t in (0 : ℝ)..r, (g (c + t) + g (c - t) - 2 * g c) := by
    have i1 : IntervalIntegrable (fun t => g (c + t)) volume 0 r :=
      (hgc.comp (continuous_const.add continuous_id)).intervalIntegrable _ _
    have i2 : IntervalIntegrable (fun t => g (c - t)) volume 0 r :=
      (hgc.comp (continuous_const.sub continuous_id)).intervalIntegrable _ _
    rw [intervalIntegral.integral_sub (i1.add i2) intervalIntegrable_const,
      intervalIntegral.integral_add i1 i2, intervalIntegral.integral_comp_add_left,
      intervalIntegral.integral_comp_sub_left, intervalIntegral.integral_const,
      ← intervalIntegral.integral_add_adjacent_intervals (b := c)
        (hgc.intervalIntegrable _ _) (hgc.intervalIntegrable _ _)]
    simp only [add_zero, sub_zero, smul_eq_mul]
    ring
  rw [e]
  have hb : ‖∫ t in (0 : ℝ)..r, (g (c + t) + g (c - t) - 2 * g c)‖ ≤
      ∫ t in (0 : ℝ)..r, M * t ^ 2 := by
    apply intervalIntegral.norm_integral_le_of_norm_le hr
    · refine Filter.Eventually.of_forall (fun s hs => ?_)
      rw [Real.norm_eq_abs]
      exact second_diff_bound g hg M hM c s hs.1.le (by linarith [hs.2]) (by linarith [hs.2])
    · apply Continuous.intervalIntegrable; fun_prop
  rw [Real.norm_eq_abs] at hb
  refine hb.trans (le_of_eq ?_)
  simp
  ring

#print axioms cell_bound

lemma midpoint_1d (g : ℝ → ℝ) (hg : ContDiff ℝ 2 g) (M : ℝ)
    (hM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M) (m : ℕ) (hm : 0 < m) :
    |(∑ j : Fin m, g (((j : ℝ) + 1 / 2) / m)) / m - ∫ t in Icc (0 : ℝ) 1, g t| ≤
      M * (1 / (m : ℝ)) ^ 2 / 24 := by
  have hgc : Continuous g := hg.continuous
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  have hI : ∫ t in Icc (0 : ℝ) 1, g t = ∑ k ∈ Finset.range m,
      ∫ x in ((k : ℝ) / m)..(((k + 1 : ℕ) : ℝ) / m), g x := by
    have := intervalIntegral.sum_integral_adjacent_intervals (μ := volume) (f := g)
      (a := fun k : ℕ => (k : ℝ) / m) (n := m) (fun k _ => hgc.intervalIntegrable _ _)
    rw [this, integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le zero_le_one]
    simp [hm'.ne']
  rw [hI, Fin.sum_univ_eq_sum_range (fun j : ℕ => g (((j : ℝ) + 1 / 2) / m)) m, Finset.sum_div,
    ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
  have hterm : ∀ k ∈ Finset.range m, |g (((k : ℝ) + 1 / 2) / m) / m -
      ∫ x in ((k : ℝ) / m)..(((k + 1 : ℕ) : ℝ) / m), g x| ≤ M * (1 / (2 * m)) ^ 3 / 3 := by
    intro k hk
    have hk' : (k : ℝ) + 1 ≤ m := by exact_mod_cast Finset.mem_range.1 hk
    set c := ((k : ℝ) + 1 / 2) / m
    set r := 1 / (2 * (m : ℝ))
    have ea : (k : ℝ) / m = c - r := by simp only [c, r]; field_simp; ring
    have eb : ((k + 1 : ℕ) : ℝ) / m = c + r := by simp only [c, r]; push_cast; field_simp; ring
    have ec : g c / m = 2 * r * g c := by simp only [r]; field_simp
    rw [ea, eb, ec, abs_sub_comm]
    apply cell_bound g hg M hM c r (by positivity)
    · rw [← ea]; positivity
    · rw [← eb, div_le_one hm']; push_cast; exact hk'
  refine (Finset.sum_le_sum hterm).trans (le_of_eq ?_)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  field_simp
  ring

#print axioms midpoint_1d

lemma measurable_finCons (n : ℕ) :
    Measurable (fun p : ℝ × (Fin n → ℝ) => (Fin.cons p.1 p.2 : Fin (n + 1) → ℝ)) := by
  refine measurable_pi_iff.2 (fun i => ?_)
  refine Fin.cases ?_ (fun j => ?_) i
  · simp only [Fin.cons_zero]; exact measurable_fst
  · simp only [Fin.cons_succ]; exact (measurable_pi_apply j).comp measurable_snd

#print axioms measurable_finCons

lemma grid_telescope (m : ℕ) (hm : 0 < m) (node : Fin m → ℝ) (ν : Measure ℝ)
    [IsProbabilityMeasure ν] (ε : ℝ) :
    ∀ (d : ℕ) (F : (Fin d → ℝ) → ℝ), Measurable F → (∃ C, ∀ x, |F x| ≤ C) →
      (∀ x k, |(∑ j : Fin m, F (Function.update x k (node j))) / m -
        ∫ t, F (Function.update x k t) ∂ν| ≤ ε) →
      |(∑ j : Fin d → Fin m, F (fun i => node (j i))) / (m : ℝ) ^ d -
        ∫ x, F x ∂(Measure.pi fun _ : Fin d => ν)| ≤ d * ε := by
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  intro d
  induction d with
  | zero =>
    intro F _ _ _
    simp only [Fintype.sum_unique, pow_zero, div_one, integral_unique, CharP.cast_eq_zero,
      zero_mul, probReal_univ, one_smul]
    simp only [abs_nonpos_iff, sub_eq_zero]
    exact congrArg F (Subsingleton.elim _ _)
  | succ n ih =>
    intro F hF ⟨C, hC⟩ hloc
    set ν' := Measure.pi fun _ : Fin n => ν with hν'
    have hcm := measurable_finCons n
    -- the integral over the cube splits off the first coordinate
    have hmp := (measurePreserving_piFinSuccAbove (fun _ : Fin (n + 1) => ν) 0).symm
    have hsplit : ∫ x, F x ∂(Measure.pi fun _ : Fin (n + 1) => ν) =
        ∫ p, F (Fin.cons p.1 p.2) ∂(ν.prod ν') := by
      rw [← hmp.integral_comp' F]
      congr 1
      funext p
      simp [MeasurableEquiv.piFinSuccAbove_symm_apply]
    have hGm : Measurable (fun p : ℝ × (Fin n → ℝ) => F (Fin.cons p.1 p.2)) := hF.comp hcm
    have hGint : Integrable (fun p : ℝ × (Fin n → ℝ) => F (Fin.cons p.1 p.2)) (ν.prod ν') :=
      Integrable.of_bound hGm.aestronglyMeasurable C (Filter.Eventually.of_forall fun p => hC _)
    rw [hsplit, integral_prod _ hGint]
    -- the grid sum splits off the first coordinate
    have hsum : (∑ j : Fin (n + 1) → Fin m, F (fun i => node (j i))) =
        ∑ j' : Fin n → Fin m, ∑ j0 : Fin m,
          F (Fin.cons (node j0) (fun i => node (j' i))) := by
      rw [← (Fin.consEquiv fun _ => Fin m).sum_comp, Fintype.sum_prod_type, Finset.sum_comm]
      refine Finset.sum_congr rfl (fun j' _ => Finset.sum_congr rfl (fun j0 _ => ?_))
      congr 1
      funext i
      refine Fin.cases ?_ (fun k => ?_) i <;> simp
    rw [hsum]
    have hsec : ∀ y : Fin n → ℝ, Integrable (fun a => F (Fin.cons a y)) ν := fun y =>
      Integrable.of_bound (hGm.comp (measurable_id.prodMk measurable_const)).aestronglyMeasurable
        C (Filter.Eventually.of_forall fun a => hC _)
    -- first term: the last-coordinate rule against the integral, averaged over the grid
    have hA : ∀ j' : Fin n → Fin m,
        |(∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) / m -
          ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν| ≤ ε := by
      intro j'
      have := hloc (Fin.cons 0 (fun i => node (j' i))) 0
      simpa only [Fin.update_cons_zero] using this
    -- second term: the induction hypothesis on each slice
    have hB : ∀ a : ℝ,
        |(∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n -
          ∫ y, F (Fin.cons a y) ∂ν'| ≤ n * ε := by
      intro a
      apply ih (fun y => F (Fin.cons a y)) (hGm.comp (measurable_const.prodMk measurable_id))
        ⟨C, fun y => hC _⟩
      intro y k
      simpa only [Fin.cons_update] using hloc (Fin.cons a y) k.succ
    have hI1 : Integrable (fun a => (∑ j' : Fin n → Fin m,
        F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n) ν :=
      (integrable_finsetSum _ (fun j' _ => hsec _)).div_const _
    have hI2 : Integrable (fun a => ∫ y, F (Fin.cons a y) ∂ν') ν := hGint.integral_prod_left
    have hH : ∫ a, (∑ j' : Fin n → Fin m,
        F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n ∂ν =
        (∑ j' : Fin n → Fin m, ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν) / (m : ℝ) ^ n := by
      rw [integral_div, integral_finsetSum _ (fun j' _ => hsec _)]
    have hdecomp :
        (∑ j' : Fin n → Fin m, ∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) /
            (m : ℝ) ^ (n + 1) - ∫ a, ∫ y, F (Fin.cons a y) ∂ν' ∂ν =
          (∑ j' : Fin n → Fin m,
            ((∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) / m -
              ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν)) / (m : ℝ) ^ n +
          ∫ a, ((∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n -
            ∫ y, F (Fin.cons a y) ∂ν') ∂ν := by
      rw [integral_sub hI1 hI2, hH, Finset.sum_sub_distrib, ← Finset.sum_div, pow_succ]
      field_simp
      ring
    rw [hdecomp]
    have hcard : (Finset.univ : Finset (Fin n → Fin m)).card = m ^ n := by simp
    have h1 : |(∑ j' : Fin n → Fin m,
            ((∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) / m -
              ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν)) / (m : ℝ) ^ n| ≤ ε := by
      rw [abs_div, abs_of_pos (pow_pos hm' n), div_le_iff₀ (pow_pos hm' n)]
      refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
      refine (Finset.sum_le_sum (fun j' _ => hA j')).trans (le_of_eq ?_)
      rw [Finset.sum_const, hcard, nsmul_eq_mul]
      push_cast
      ring
    have h2 : |∫ a, ((∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) /
        (m : ℝ) ^ n - ∫ y, F (Fin.cons a y) ∂ν') ∂ν| ≤ n * ε := by
      have := norm_integral_le_of_norm_le_const (μ := ν) (C := n * ε)
        (f := fun a => (∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) /
          (m : ℝ) ^ n - ∫ y, F (Fin.cons a y) ∂ν')
        (Filter.Eventually.of_forall fun a => by rw [Real.norm_eq_abs]; exact hB a)
      rw [Real.norm_eq_abs, probReal_univ, mul_one] at this
      exact this
    push_cast
    calc _ ≤ _ := abs_add_le _ _
      _ ≤ ε + n * ε := add_le_add h1 h2
      _ = (n + 1) * ε := by ring

#print axioms grid_telescope

lemma unitCube_isProb (d : ℕ) :
    IsProbabilityMeasure (volume.restrict (Icc (0 : Fin d → ℝ) 1)) :=
  ⟨by simp [Real.volume_Icc_pi]⟩

#print axioms unitCube_isProb

lemma aemeasurable_of_map_eq_unitCube {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (d : ℕ) (V : Ω → (Fin d → ℝ))
    (h : P.map V = volume.restrict (Icc (0 : Fin d → ℝ) 1)) : AEMeasurable V P := by
  by_contra hV
  rcases Nat.eq_zero_or_pos d with hd | hd
  · subst hd
    exact hV (measurable_pi_iff.2 (fun i => i.elim0)).aemeasurable
  · obtain ⟨c, hc⟩ : ∃ c, P.map V = Measure.dirac c :=
      ⟨_, Measure.map_of_not_aemeasurable_of_ne_zero hV (IsProbabilityMeasure.ne_zero P)⟩
    rw [hc] at h
    have h2 := congrArg (fun ν : Measure (Fin d → ℝ) => ν {c}) h
    have h0 : volume ({c} : Set (Fin d → ℝ)) = 0 := by
      rw [← Icc_self, Real.volume_Icc_pi]
      exact Finset.prod_eq_zero (Finset.mem_univ ⟨0, hd⟩) (by simp)
    have h3 : (volume.restrict (Icc (0 : Fin d → ℝ) 1)) {c} = 0 :=
      le_antisymm ((Measure.restrict_apply_le _ _).trans h0.le) zero_le
    simp only [Measure.dirac_apply_of_mem (mem_singleton c)] at h2
    rw [h3] at h2
    exact one_ne_zero h2

#print axioms aemeasurable_of_map_eq_unitCube

/-- The product midpoint rule with `m` points per axis on the unit cube in `d` dimensions:
the plain average of `f` over all `m ^ d` points whose coordinates are midpoints
`(j + 1/2) / m`, `j = 0, …, m - 1` (the card's `(j - 1/2)/m`, `j = 1, …, m`). -/
noncomputable def productMidpoint (d m : ℕ) (f : (Fin d → ℝ) → ℝ) : ℝ :=
  (∑ j : Fin d → Fin m, f (fun i => ((j i : ℝ) + 1 / 2) / m)) / (m : ℝ) ^ d

/-- The product grid's error is at most `d` one-dimensional errors: if `f` has a second
derivative along each axis bounded by `M` on the unit cube, the product midpoint rule with
`m` points per axis (spacing `h = 1/m`) misses the integral over the cube by at most
`d · M · h² / 24`. -/
theorem product_midpoint_error_bound (d m : ℕ) (hm : 0 < m) (f : (Fin d → ℝ) → ℝ) (M : ℝ)
    (hf : ContDiff ℝ 2 f)
    (hM : ∀ x ∈ Icc (0 : Fin d → ℝ) 1, ∀ k : Fin d,
      |deriv (deriv fun t => f (Function.update x k t)) (x k)| ≤ M) :
    |productMidpoint d m f - ∫ u in Icc (0 : Fin d → ℝ) 1, f u| ≤
      d * M * (1 / (m : ℝ)) ^ 2 / 24 := by
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  -- clamp each coordinate into [0, 1]; this changes nothing on the cube
  set clamp : (Fin d → ℝ) → (Fin d → ℝ) := fun x i => max 0 (min (x i) 1) with hclamp
  have hcl_mem : ∀ x, clamp x ∈ Icc (0 : Fin d → ℝ) 1 := fun x =>
    ⟨fun i => le_max_left _ _, fun i => max_le zero_le_one (min_le_right _ _)⟩
  have hcl1 : ∀ t ∈ Icc (0 : ℝ) 1, max 0 (min t 1) = t := fun t ht => by
    rw [min_eq_left ht.2, max_eq_right ht.1]
  have hcl_id : ∀ x ∈ Icc (0 : Fin d → ℝ) 1, clamp x = x := fun x hx => funext fun i =>
    hcl1 (x i) ⟨hx.1 i, hx.2 i⟩
  have hcl_cont : Continuous clamp :=
    continuous_pi fun i => continuous_const.max ((continuous_apply i).min continuous_const)
  have hcl_upd : ∀ x k t, t ∈ Icc (0 : ℝ) 1 →
      clamp (Function.update x k t) = Function.update (clamp x) k t := by
    intro x k t ht
    funext i
    by_cases h : i = k
    · subst h; simp only [hclamp, Function.update_self]; exact hcl1 t ht
    · simp [hclamp, Function.update_of_ne h]
  set F : (Fin d → ℝ) → ℝ := fun x => f (clamp x) with hF
  have hFc : Continuous F := hf.continuous.comp hcl_cont
  obtain ⟨C, hC⟩ := (isCompact_Icc (a := (0 : Fin d → ℝ)) (b := 1)).exists_bound_of_continuousOn
    hf.continuous.continuousOn
  have hFb : ∀ x, |F x| ≤ C := fun x => by
    simpa [Real.norm_eq_abs] using hC (clamp x) (hcl_mem x)
  set node : Fin m → ℝ := fun j => ((j : ℝ) + 1 / 2) / m with hnode_def
  have hnode : ∀ j, node j ∈ Icc (0 : ℝ) 1 := fun j => by
    have hj : (j : ℝ) + 1 ≤ m := by exact_mod_cast j.isLt
    refine ⟨by positivity, ?_⟩
    rw [hnode_def, div_le_one hm']
    linarith
  have : IsProbabilityMeasure (volume.restrict (Icc (0 : ℝ) 1)) := ⟨by simp⟩
  have hloc : ∀ x k, |(∑ j : Fin m, F (Function.update x k (node j))) / m -
      ∫ t, F (Function.update x k t) ∂(volume.restrict (Icc (0 : ℝ) 1))| ≤
        M * (1 / (m : ℝ)) ^ 2 / 24 := by
    intro x k
    set x' := clamp x
    set g : ℝ → ℝ := fun t => f (Function.update x' k t) with hg_def
    have hg : ContDiff ℝ 2 g := hf.comp (contDiff_update 2 x' k)
    have hgM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M := by
      intro t ht
      have hmem : Function.update x' k t ∈ Icc (0 : Fin d → ℝ) 1 := by
        refine ⟨fun i => ?_, fun i => ?_⟩ <;> by_cases h : i = k
        · subst h; simpa using ht.1
        · simpa [Function.update_of_ne h] using (hcl_mem x).1 i
        · subst h; simpa using ht.2
        · simpa [Function.update_of_ne h] using (hcl_mem x).2 i
      simpa [hg_def] using hM _ hmem k
    have e1 : ∀ j, F (Function.update x k (node j)) = g (node j) := fun j => by
      simp only [hF, hg_def]; rw [hcl_upd x k _ (hnode j)]
    have e2 : ∫ t, F (Function.update x k t) ∂(volume.restrict (Icc (0 : ℝ) 1)) =
        ∫ t in Icc (0 : ℝ) 1, g t :=
      setIntegral_congr_fun measurableSet_Icc (fun t ht => by
        simp only [hF, hg_def]; rw [hcl_upd x k t ht])
    rw [e2]
    simp only [e1]
    exact midpoint_1d g hg M hgM m hm
  have hT := grid_telescope m hm node (volume.restrict (Icc (0 : ℝ) 1))
    (M * (1 / (m : ℝ)) ^ 2 / 24) d F hFc.measurable ⟨C, hFb⟩ hloc
  have eS : productMidpoint d m f =
      (∑ j : Fin d → Fin m, F (fun i => node (j i))) / (m : ℝ) ^ d := by
    unfold productMidpoint
    congr 1
    refine Finset.sum_congr rfl (fun j _ => ?_)
    simp only [hF]
    rw [hcl_id _ ⟨fun i => (hnode (j i)).1, fun i => (hnode (j i)).2⟩]
  have hvol : volume.restrict (Icc (0 : Fin d → ℝ) 1) =
      Measure.pi fun _ : Fin d => volume.restrict (Icc (0 : ℝ) 1) := by
    rw [← Set.pi_univ_Icc, volume_pi, Measure.restrict_pi_pi]
    rfl
  have eI : ∫ u in Icc (0 : Fin d → ℝ) 1, f u =
      ∫ x, F x ∂(Measure.pi fun _ : Fin d => volume.restrict (Icc (0 : ℝ) 1)) := by
    rw [setIntegral_congr_fun measurableSet_Icc (g := F) (fun u hu => by
      simp only [hF]; rw [hcl_id u hu]), hvol]
  rw [eS, eI]
  refine hT.trans (le_of_eq ?_)
  ring

/-- The Monte Carlo error is σ/√N whatever the dimension: if `U₁, …, U_N` are independent
random points, each spread evenly over the unit cube in `d` dimensions, and the payoff `f`
has finite spread σ (finite mean square on the cube), then the average of `f(U_i)` has
mean-square miss from the true integral `I` equal to `σ² / N`, where `σ²` is the mean of
`(f - I)²` over the cube. No `d` appears in the answer. -/
theorem monte_carlo_mean_square_error {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (d N : ℕ) (hN : 0 < N) (f : (Fin d → ℝ) → ℝ)
    (U : Fin N → Ω → (Fin d → ℝ)) (hind : iIndepFun U P)
    (hunif : ∀ i, P.map (U i) = volume.restrict (Icc (0 : Fin d → ℝ) 1))
    (hσ : MemLp f 2 (volume.restrict (Icc (0 : Fin d → ℝ) 1))) :
    ∫ ω, ((∑ i, f (U i ω)) / N - ∫ u in Icc (0 : Fin d → ℝ) 1, f u) ^ 2 ∂P =
      (∫ u in Icc (0 : Fin d → ℝ) 1,
        (f u - ∫ v in Icc (0 : Fin d → ℝ) 1, f v) ^ 2) / N := by
  have hUm : ∀ i, AEMeasurable (U i) P := fun i =>
    aemeasurable_of_map_eq_unitCube d (U i) (hunif i)
  set μ := volume.restrict (Icc (0 : Fin d → ℝ) 1) with hμ
  have : IsProbabilityMeasure μ := unitCube_isProb d
  set I := ∫ u, f u ∂μ with hI
  have hfs := hσ.aestronglyMeasurable
  have hfm : ∀ i, AEMeasurable f (P.map (U i)) := fun i => by
    rw [hunif i]; exact hfs.aemeasurable
  set X : Fin N → Ω → ℝ := fun i ω => f (U i ω) with hX
  have hXind : iIndepFun X P := hind.comp₀ (fun _ => f) hUm hfm
  have hXL2 : ∀ i, MemLp (X i) 2 P := fun i =>
    (memLp_map_measure_iff (by rw [hunif i]; exact hfs) (hUm i)).1 (by rw [hunif i]; exact hσ)
  have hXint : ∀ i, ∫ ω, X i ω ∂P = I := fun i => by
    rw [hI, ← hunif i, integral_map (hUm i) (by rw [hunif i]; exact hfs)]
  have hXvar : ∀ i, variance (X i) P = ∫ u, (f u - I) ^ 2 ∂μ := fun i => by
    have := variance_map (hfm i) (hUm i)
    rw [hunif i] at this
    rw [show X i = f ∘ U i from rfl, ← this, variance_eq_integral hfs.aemeasurable]
  have hsum := IndepFun.variance_sum (s := Finset.univ) (fun i _ => hXL2 i)
    (fun i _ j _ hij => hXind.indepFun hij)
  have hSint : ∫ ω, (∑ i, X i) ω ∂P = N * I := by
    simp only [Finset.sum_apply]
    rw [integral_finsetSum _ (fun i _ => (hXL2 i).integrable one_le_two)]
    simp [hXint]
  have hSm : AEMeasurable (∑ i, X i) P :=
    Finset.aemeasurable_sum _ (fun i _ => (hXL2 i).aestronglyMeasurable.aemeasurable)
  rw [variance_eq_integral hSm, hSint] at hsum
  simp only [hXvar, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
    Finset.sum_apply] at hsum
  have hN' : (N : ℝ) ≠ 0 := by exact_mod_cast hN.ne'
  have key : ∀ ω, ((∑ i, f (U i ω)) / N - I) ^ 2 = (∑ i, X i ω - N * I) ^ 2 / (N : ℝ) ^ 2 := by
    intro ω
    simp only [hX]
    field_simp
  simp_rw [key]
  rw [integral_div, hsum]
  field_simp

/-- The grid's cost and rate in point count: a product grid with `m` points on each of `d`
axes has `N = m ^ d` points, and its spacing squared `h² = (1/m)²` equals `N ^ (-2/d)`,
so the error bound `d · M · h² / 24` falls only like `N ^ (-2/d)`. -/
theorem product_grid_cost_and_rate (d m : ℕ) (hd : 0 < d) (hm : 0 < m) :
    Fintype.card (Fin d → Fin m) = m ^ d ∧
      (1 / (m : ℝ)) ^ 2 = ((m : ℝ) ^ d) ^ (-(2 : ℝ) / d) := by
  refine ⟨by simp, ?_⟩
  have hm' : (0 : ℝ) ≤ m := Nat.cast_nonneg m
  have hd' : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
  rw [← Real.rpow_natCast (m : ℝ) d, ← Real.rpow_mul hm', mul_div_cancel₀ _ hd',
    Real.rpow_neg hm', one_div, inv_pow]
  norm_num

-- The card's grid sizes: 10 per axis in 5, 10 and 20 dimensions; 2, 3 and 4 per axis in 10.
example : Fintype.card (Fin 5 → Fin 10) = 100000 := by simp
example : (10 : ℕ) ^ 10 = 10000000000 := by norm_num
example : (10 : ℕ) ^ 20 = 100000000000000000000 := by norm_num
example : (2 : ℕ) ^ 10 = 1024 := by norm_num
example : (3 : ℕ) ^ 10 = 59049 := by norm_num
example : (4 : ℕ) ^ 10 = 1048576 := by norm_num

-- The hand computation of the basket's value: 2.5^6 - 5 × 1.5^6 + 10 × 0.5^6 = 187.34375,
-- then divided by 6! = 720 and times 8 gives I = 1199/576 (about 2.081597).
example : (5 / 2 : ℚ) ^ 6 - 5 * (3 / 2) ^ 6 + 10 * (1 / 2) ^ 6 = 5995 / 32 := by norm_num
example : (Nat.factorial 6 : ℚ) = 720 := by decide
example : 8 * (5995 / 32 : ℚ) / 720 = 1199 / 576 := by norm_num
-- The average squared payoff 64 × 5/24 = 40/3, and the variance σ² = 40/3 - I².
example : (64 : ℚ) * (5 / 24) = 40 / 3 := by norm_num
example : (40 / 3 : ℚ) - (1199 / 576) ^ 2 = 2986079 / 331776 := by norm_num
-- The reused-draw mistake aims at a one-dimensional triangle: 100 × 0.2 × 0.5 / 2 = 5.
example : (100 : ℚ) * (1 / 5) * (1 / 2) / 2 = 5 := by norm_num

#print axioms product_midpoint_error_bound
#print axioms monte_carlo_mean_square_error
#print axioms product_grid_cost_and_rate
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'second_diff_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'cell_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'midpoint_1d' depends on axioms: [propext, Classical.choice, Quot.sound]
'measurable_finCons' depends on axioms: [propext, Classical.choice, Quot.sound]
'grid_telescope' depends on axioms: [propext, Classical.choice, Quot.sound]
'unitCube_isProb' depends on axioms: [propext, Classical.choice, Quot.sound]
'aemeasurable_of_map_eq_unitCube' depends on axioms: [propext, Classical.choice, Quot.sound]
'product_midpoint_error_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'monte_carlo_mean_square_error' depends on axioms: [propext, Classical.choice, Quot.sound]
'product_grid_cost_and_rate' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Another seed.** Guess first: how far does the 10,000-draw estimate move? Change `splitmix64(2026)` on the `nxt =` line to `splitmix64(7)`. The estimate becomes 2.057204, an error of −0.024393, which is −0.8200 standard errors. Every check still passes, because the asserts allow 4 standard errors.
> - **Corners instead of midpoints.** Guess first: does the grid's order survive? In `grid`, change the `0.5` offset to `0.0`. The 10-per-axis estimate becomes 1.216600, with error −0.864997, the observed order starts at 0.3082, and the order-2 assert stops the run.
> - **A finer grid in ten dimensions.** Guess first: does 4 per axis catch Monte Carlo? Change `for m in (2, 3):` to `for m in (2, 3, 4):`. The grid now costs 1,048,576 evaluations and misses by −0.054821, still 2.60 standard errors of a 10,000-draw average.

---

## The usual mistake

> [!warning]
> **Choosing by the rate alone.** Above four dimensions, Monte Carlo's rate N^(−1/2) beats the midpoint grid's N^(−2/d). But a rate says nothing about the constant in front. In five dimensions the 100,000-point grid misses by −0.007997, while 100,000 random points would have standard error 0.009487. The estimated crossover is 551,938 points. Compare errors at the budget you can afford, not exponents.
>
> - **Quoting s/N as the error bar.** That gives 0.000300, and the true error is 16.1 of those. The square root is the whole point of the theorem.
> - **Reusing one random number across the dimensions.** The average settles on 5.000000, a one-dimensional integral, not 2.081597; this run reads 4.991290. More draws make it more precisely wrong.
> - **Trusting one lucky run.** This run's error, −0.004819, is only 0.1606 standard errors. Over 40 runs the typical error at 10,000 draws was 0.028595. Quote the standard error, not the lucky miss.

---

## Where you meet it in real life

- **Basket options and portfolio risk.** A payoff on many assets is an integral with one dimension per asset. Banks price such contracts and measure portfolio losses with Monte Carlo for exactly the reason on this card.
- **Path-dependent contracts.** An option on the average of daily prices over a year has one dimension per day, a few hundred in all. No grid can reach that.
- **Film and game rendering.** Each bounce of a light ray adds dimensions to the integral of light reaching one pixel. Path tracing estimates it with random rays, and the grain in a fast render is the σ/√N error made visible.
- **Engineering in two and three dimensions.** Heat over a plate or stress in a solid is a low-dimensional integral of a smooth function. Finite-element codes use product Gauss rules there, and they win easily.

> **Say it back**
> A product grid puts m points on each of d axes, so it costs m to the d evaluations. Its error is at most d times the one-dimensional error, so in point count it falls only like N to the minus two over d. An average of N independent random points misses by σ over root N, because independent misses add in variance, and the dimension never enters. Which wins depends on the constants as well as the rates: in five dimensions a 100,000-point grid beat the same number of random points, but in ten dimensions a 59,049-point grid missed by 4.69 standard errors. Smooth low-dimensional integrals belong to grids; high-dimensional or rough ones belong to random points.

---

## What this builds on

- [Adaptive quadrature and awkward integrals](05-adaptive-and-improper-quadrature.md): one-dimensional rules that place points where the integrand is hard; in many dimensions even an adaptive grid pays the m-to-the-d cost.
- [Monte Carlo](../../09-Probability%20and%20statistics/11-Simulation/04-monte-carlo-estimates-and-error.md): the standard error σ/√N and the 95 percent interval, stated in one line here.
- [Double integrals](../../06-Calculus%20and%20analysis/08-Multiple%20Integrals/01-double-integrals.md): an integral over a region computed as integrals over one axis at a time, the idea behind the product rule.
- [Monte Carlo integration](../../14-Applied%20and%20computational/02-Randomised%20and%20Approximate%20Algorithms/05-monte-carlo-integration-in-many-dimensions.md): the rate comparison N^(−1/2) against N^(−2/d), which this card proves and prices.

## Where this goes next

- [Quasi-Monte Carlo and sparse grids](07-quasi-monte-carlo-and-sparse-grids.md): points spread more evenly than random ones, and grids that drop most of the m-to-the-d combinations, for the middle ground between this card's two methods.

Left open: is there a set of points that keeps Monte Carlo's freedom from the dimension but beats its square-root rate on smooth integrands?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Davis, Philip J., and Philip Rabinowitz. *Methods of Numerical Integration*, 2nd ed. Academic Press, 1984. [doi:10.1016/C2013-0-10566-1](https://doi.org/10.1016/C2013-0-10566-1). Product rules in several dimensions, their error and their cost, and Monte Carlo as the alternative.
- Metropolis, Nicholas, and S. Ulam. "The Monte Carlo Method." *Journal of the American Statistical Association* 44, no. 247 (1949): 335–341. [doi:10.1080/01621459.1949.10483310](https://doi.org/10.1080/01621459.1949.10483310). The paper that named the method and argued for random sampling of many-dimensional integrals.
- Caflisch, Russel E. "Monte Carlo and quasi-Monte Carlo methods." *Acta Numerica* 7 (1998): 1–49. [doi:10.1017/S0962492900002804](https://doi.org/10.1017/S0962492900002804). The σ/√N error, why it is free of the dimension, and how it compares with grids and quasi-Monte Carlo.
- Glasserman, Paul. *Monte Carlo Methods in Financial Engineering*. Springer, 2003. [doi:10.1007/978-0-387-21617-1](https://doi.org/10.1007/978-0-387-21617-1). Monte Carlo for multi-asset and path-dependent contracts, and why grids fail there.
