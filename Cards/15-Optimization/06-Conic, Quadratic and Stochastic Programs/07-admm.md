# ADMM: split the problem, solve the easy halves, reconcile each round

[Syllabus](../../../SYLLABUS.md) → [Optimization](../README.md) → [Conic, Quadratic and Stochastic Programs](../README.md#s06) → ADMM

---

## General Overview

A fund wants to copy a balanced index with as few of five holdings as possible: UK shares, US shares, UK gilts (government bonds), gold and property. It has eight months of returns (invented for this card), in percent a month, for the index and for each holding. It chooses five weights: the fraction of each pound to put in each holding, with whatever is left over kept in cash. It **minimises** a total of two parts. The **fit** is half the sum, over the eight months, of the squared gap between the copy's return and the index's return. The **penalty** is 2 times the sum of the weights' sizes. That is the lasso (least squares plus a charge on the size of every weight), and its charge pushes small holdings to exactly zero.

Each part alone is easy. The fit alone is a smooth bowl, solved by one linear system. The penalty alone is solved weight by weight: shrink each weight towards zero and cut it to zero when it is small. Together they are awkward for plain gradient descent, because the penalty has corners. [Proximal gradient](06-proximal-methods-ista-fista-and-the-lasso.md) handles the pair with small steps, each sized by how sharply the bowl curves. ADMM (the alternating direction method of multipliers) gives each part its own copy of the weights. It solves the fit for one copy and the penalty for the other, then charges a price for the gap between the copies and does it again. Each half is solved exactly every round, and the fit's linear system keeps the same matrix throughout. How hard the gap is charged changes only the speed, never whether the copies meet, whereas a gradient step must stay under a limit set by the curvature. The same split also works when the penalty has no cheap shrink, or when the data sit on many machines.

Starting from all zeros, with an agreement weight of 3 on the gap between the copies, the two copies agree to within 0.0000005 after **60 rounds**. The answer, per £1,000,000: **£312,500 in UK shares, £200,000 in US shares, £50,000 in property, nothing in gilts or gold, £437,500 in cash.** A list of all 243 sign patterns finds the same weights, and a check of the lasso's optimality conditions proves that no other weights cost less.

**ADMM splits a problem into two halves that are easy alone, solves each half in turn against a shared price on their disagreement, and updates that price by the disagreement left over; for two convex halves the disagreement and the price change both fall to zero, and what remains is the optimum.**

**What kind of fact this is:** a method. Its stopping test is justified on this card (Why it works, Step 3). Its convergence for two convex halves is a theorem, stated with its source and proved in outline in a fold, and the code checks the proof's key inequality at every round. The final weights are certified optimal by the lasso's conditions, checked in the code.

### The picture: the disagreement falling, round by round

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "ADMM on the five-holding lasso, agreement weight 3"
    x-axis "round k" [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    y-axis "log10 of the size (weights, a fraction)" -8 --> 0
    line [-1.324, -1.677, -2.249, -2.696, -3.162, -3.631, -4.085, -4.544, -5.003, -5.461, -5.919, -6.377]
    line [-0.372, -1.850, -2.193, -2.728, -3.647, -4.128, -4.693, -5.097, -5.780, -6.193, -6.581, -7.093]
    line [-1.243, -1.652, -2.664, -2.857, -3.744, -4.275, -4.513, -5.110, -5.601, -5.996, -6.466, -6.945]
```

Orange: the primal residual $r_k$, the gap between the fit's copy and the penalty's copy. Green: the dual residual $s_k$, how far the penalty's copy moved this round. Dark: the true error, the distance from the exact answer. Each step down by 1 is a factor of 10. All three fall together, roughly in a straight line, and the run stops when the first two are both below $\varepsilon = 5 \times 10^{-7}$.

---

## The formula

The problem, with the agreement written as a constraint:

$$\text{minimise } f(x) + g(z) \quad\text{subject to}\quad x = z, \qquad f(x) = \tfrac12\|Ax - b\|^2, \quad g(z) = \lambda\|z\|_1 .$$

ADMM, in scaled form, from $x_0 = z_0 = u_0 = 0$, for $k = 0, 1, 2, \dots$:

$$
\begin{aligned}
x_{k+1} &= \operatorname*{argmin}_x \Big( f(x) + \tfrac{\rho}{2}\|x - z_k + u_k\|^2 \Big) && \text{so } (A^T A + \rho I)\,x_{k+1} = A^T b + \rho(z_k - u_k) \\
z_{k+1} &= \operatorname*{argmin}_z \Big( g(z) + \tfrac{\rho}{2}\|x_{k+1} - z + u_k\|^2 \Big) && \text{so } z_{k+1} = S_{\lambda/\rho}(x_{k+1} + u_k) \\
u_{k+1} &= u_k + x_{k+1} - z_{k+1}
\end{aligned}
$$

Stop when $r_{k+1} = \|x_{k+1} - z_{k+1}\|$ and $s_{k+1} = \rho\|z_{k+1} - z_k\|$ are both below $\varepsilon$.

**Read it aloud:** fit the data while being pulled towards the penalty's copy, shrink the result while being pulled towards the fit's copy, then add the remaining gap to the running price, and repeat until the copies agree and stop moving.

Here $S_t$ is soft-thresholding (shrink every entry towards zero by $t$, and set it to zero if it is smaller than $t$), the proximal step of the $\ell_1$ penalty taught on [Proximal gradient](06-proximal-methods-ista-fista-and-the-lasso.md).

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $A$, $b$, $I$ | the holdings' monthly returns (8 rows, 5 columns) and the index's, in percent; $I$ the 5-by-5 identity (1 on the diagonal, 0 elsewhere) | first month: $(2, 3, -1, 1, 2)$ and 1.8 | — |
| $f$, $\nabla f$ | the fit: half the sum of squared monthly gaps; its gradient $A^T(Ax - b)$ | 0.408125 at the answer | — |
| $g$, $\partial g$ | the penalty $\lambda\|z\|_1$ (sum of sizes); its subdifferential, the set of its slopes | 1.125 at the answer | — |
| $\lambda$ | the lasso weight: the price of holding anything at all | 2 | fewer holdings: at 4, only UK and US shares |
| $x$, $z$; $k$ | the fit's copy and the penalty's copy of the five weights; $x_k$, $z_k$ are their values after round $k$ | $z = (0.3125, 0.2, 0, 0, 0.05)$ | — |
| $\rho$ | the agreement weight: how hard disagreement between the copies is charged (the penalty weight of shelf 03's penalty card) | 3 | rounds fall, then rise: 324 at 0.5, 43 at 10, 252 at 100 |
| $y$, $u = y/\rho$ | the price on the gap $x - z$ (the equality multiplier, written ν on [KKT conditions](../03-Constrained%20Optimisation/02-kkt-conditions.md)), and the same price scaled | $u_1 = x_1$ | — |
| $L_\rho$, $L_0$ | the augmented Lagrangian: cost plus price times gap plus $\tfrac{\rho}{2}$ times gap squared; $L_0$, the plain Lagrangian, is the same with $\rho = 0$ | — | — |
| $S_t$ | soft-thresholding at level $t$ | $t = \lambda/\rho = 2/3$ | more entries cut to zero |
| $r_k$, $s_k$, $\varepsilon$ | primal residual (copies' gap), dual residual (penalty copy's move times $\rho$), stopping level | $\varepsilon = 5 \times 10^{-7}$ | a smaller $\varepsilon$ takes more rounds |
| $x^*$, $y^*$, $p^*$ | the optimal weights, optimal price and optimal cost | $p^* = 1.533125$ | — |
| $V_k$ | the yardstick in the convergence proof: $\tfrac{1}{\rho}\|y_k - y^*\|^2 + \rho\|z_k - x^*\|^2$ | falls every round | — |

The agreement weight $\rho$ is the penalty weight of [Penalties and augmented Lagrangians](../03-Constrained%20Optimisation/07-penalty-and-augmented-lagrangian-methods.md). The fit and penalty at the answer, 0.408125 and 1.125, add to $p^* = 1.533125$, which the code prints.

### When it holds

- **Both halves convex, closed and proper.** Closed: at the edge of where the function is finite, it does not jump up above the values it approaches. Proper: never −∞, and finite somewhere. Here $f$ is a bowl and $g$ a sum of V shapes. If one half has two separate dips, ADMM can settle at a point that satisfies the stopping test but is only a local answer, and nothing on this card certifies it.
- **An optimum and a matching price exist.** The theorem needs a saddle point of the plain Lagrangian $L_0$: weights and a price where no change of weights lowers $L_0$ and no change of price raises it ([Saddle points](../03-Constrained%20Optimisation/06-saddle-points-and-minimax.md)). For the lasso one always exists. For a problem with no feasible point, $r_k$ never reaches zero and $u_k$ grows without bound.
- **Exactly two blocks.** Updating three unknowns in turn with one shared price is not covered, and can blow up: in What breaks, the sizes grow from 1.7321 to 413.7233 in 200 rounds.
- **The dual step equals $\rho$.** The price must move by exactly $\rho$ times the gap, which in scaled form is $u + (x - z)$. Any other step loses the property in Step 3 that makes the stopping test correct.
- **Each half solved exactly.** Here both steps are exact. Inexact inner solves need errors that shrink fast enough (Eckstein and Bertsekas), or the residuals stall.

---

## Why it works

### Step 0: give each half its own copy, then charge for disagreement

Minimising $f(x) + g(x)$ in one go is hard because $f$ is smooth and $g$ has corners. Write the same problem with two copies, $f(x) + g(z)$ with $x = z$. Now each half sees only its own variable. The one thing joining them is the constraint $x = z$, and a constraint can be priced, as Lagrange multipliers do. A price $y$ on the gap plus a quadratic penalty on its size gives a cost that each copy can minimise separately while the other copy stays fixed.

### Step 1: the augmented Lagrangian

$$L_\rho(x, z, y) = f(x) + g(z) + y^T(x - z) + \tfrac{\rho}{2}\|x - z\|^2 .$$

The method of multipliers minimises $L_\rho$ over $x$ and $z$ together, then moves the price: $y \leftarrow y + \rho(x - z)$. The quadratic term makes each inner problem well behaved, and the price update steers the gap to zero without sending $\rho$ to infinity, as [Penalties and augmented Lagrangians](../03-Constrained%20Optimisation/07-penalty-and-augmented-lagrangian-methods.md) shows. The trouble is "together": minimising over $x$ and $z$ at once is the original hard problem again.

### Step 2: one sweep instead of a joint minimisation

ADMM replaces the joint minimisation by one pass: minimise $L_\rho$ over $x$ with $z$ fixed, then over $z$ with the new $x$ fixed, then update $y$. Each pass touches only one half.

Completing the square makes the steps tidy. With $u = y/\rho$,

$$y^T(x - z) + \tfrac{\rho}{2}\|x - z\|^2 = \tfrac{\rho}{2}\|x - z + u\|^2 - \tfrac{\rho}{2}\|u\|^2 ,$$

and the last term does not depend on $x$ or $z$. So the $x$ step minimises $f(x) + \tfrac{\rho}{2}\|x - z_k + u_k\|^2$. Setting its gradient to zero gives $A^T(Ax - b) + \rho(x - z_k + u_k) = 0$, the linear system in The formula. The $z$ step minimises $\lambda\|z\|_1 + \tfrac{\rho}{2}\|z - (x_{k+1} + u_k)\|^2$, which separates into five one-variable problems, each solved by shrinking by $\lambda/\rho$. The price update $y \leftarrow y + \rho(x - z)$ becomes $u \leftarrow u + x - z$.

### Step 3: why the two residuals are the right stopping test

The lasso is optimal at $x^* = z^*$ with price $y^*$ exactly when three conditions hold: $x^* = z^*$; $\nabla f(x^*) + y^* = 0$; and $y^* \in \partial g(z^*)$, a slope of the penalty at $z^*$. ADMM satisfies the third one exactly at every round, leaves the first as $r$, and leaves the second as $s$.

**The penalty's condition always holds.** The $z$ step is optimal, so $0 \in \partial g(z_{k+1}) - y_k - \rho(x_{k+1} - z_{k+1})$. The price update turns the last two terms into $-y_{k+1}$. So $y_{k+1} \in \partial g(z_{k+1})$ at every round. This is why the price step must be exactly $\rho$.

**The fit's condition is off by $s$.** The $x$ step is optimal, so $\nabla f(x_{k+1}) + y_k + \rho(x_{k+1} - z_k) = 0$. Since $y_k + \rho(x_{k+1} - z_k) = y_{k+1} + \rho(z_{k+1} - z_k)$, this reads

$$\nabla f(x_{k+1}) + y_{k+1} = -\rho\,(z_{k+1} - z_k).$$

The right side has size $s_{k+1}$. **The agreement condition is off by $r$**, by definition. So when $r$ and $s$ are both zero, all three conditions hold, and for a convex problem those conditions mean optimal. Small $r$ and $s$ mean the conditions nearly hold. That is the whole justification for the test.

### Step 4: the two residuals must fall to zero

The convergence theorem (Gabay and Mercier 1976; in this form, Boyd and co-authors 2011, section 3.2): if $f$ and $g$ are closed, proper and convex and the plain Lagrangian $L_0$ has a saddle point, then for any $\rho > 0$, $r_k \to 0$, $f(x_k) + g(z_k) \to p^*$, and $y_k \to$ an optimal price. Nothing about smoothness or strong convexity is needed. Without more hypotheses the guaranteed rate is slow, $O(1/k)$ in an averaged sense (He and Yuan 2012). On this lasso the residuals fell much faster, by a roughly constant factor each round, as the straight lines in the chart show.

<details>
<summary>Detailed proof, in outline: a yardstick that falls every round</summary>

Take an optimal pair $(x^*, y^*)$ and define

$$V_k = \tfrac{1}{\rho}\|y_k - y^*\|^2 + \rho\|z_k - x^*\|^2 .$$

The proof adds two inequalities. One comes from the optimality of the $x$ step and of $x^*$. The other comes from the optimality of the $z$ step. Each is a statement that a convex function lies above its tangent. The cross terms cancel, and what is left is

$$V_{k+1} \le V_k - \rho\,r_{k+1}^2 - \rho\,\|z_{k+1} - z_k\|^2 .$$

So $V$ never rises, and it falls by at least $\rho r^2 + s^2/\rho$ each round. Since $V \ge 0$, the total of all those falls is finite, which forces $r_k \to 0$ and $z_{k+1} - z_k \to 0$. Feeding those limits back into Step 3 gives the cost and price limits. Boyd and co-authors give the algebra in full in their Appendix A.

The code computes $V_k$ from the exact $x^*$ and $y^* = -\nabla f(x^*)$ and asserts this inequality at every one of the 60 rounds. The smallest ratio of actual fall to the required fall is 1.7866: never below the floor.

</details>

### Step 5: the certificate at the end

For the lasso, the conditions of Step 3 read: on every holding, $-\nabla f$ equals $\lambda$ times the weight's sign; on every zero weight, $-\nabla f$ lies between $-\lambda$ and $\lambda$. At the final $z$, $-\nabla f = (2.00000, 2.00000, 1.00000, 1.66250, 2.00000)$: the three holdings sit at $\lambda = 2$, and gilts and gold lie inside $[-2, 2]$. That is the printed certificate that the answer is optimal, not only the best found. Worked numbers checks it by hand.

---

## Worked numbers, by hand

The data: $A^T A$ and $A^T b$ are what the fit sees.

| Step | Arithmetic | Value |
| --- | --- | --- |
| $A^T A$ diagonal | each holding's sum of squared returns | 24, 24, 21, 20, 24 |
| $A^T b$ | each holding's returns times the index's, summed | 12.7, 10.8, −6.1, 5.8, 9.2 |
| round 1, fit half | solve $(A^T A + 3I)x_1 = A^T b$ | $x_1 = (0.253348, 0.267164, 0.087908, 0.122235, 0.169723)$ |
| round 1, penalty half | shrink $x_1 + u_0 = x_1$ by $\lambda/\rho = 2/3$; every entry is below 0.6667 | $z_1 = (0, 0, 0, 0, 0)$ |
| round 1, reconcile | $u_1 = 0 + x_1 - 0$ | $u_1 = x_1$ |
| round 1, residuals | $r_1 = \|x_1\|$; $s_1 = 3\|z_1 - z_0\|$ | 0.432478, 0 |
| round 60, the copies | $z_{60}$; $x_{60}$ agrees to within $5 \times 10^{-7}$ | $(0.3125, 0.2, 0, 0, 0.05)$ |
| certificate, UK row | $24(0.3125) + 12(0.2) + 16(0.05) = 7.5 + 2.4 + 0.8$ | $10.7 = 12.7 - 2$ ✓ |
| certificate, US row | $12(0.3125) + 24(0.2) + 5(0.05) = 3.75 + 4.8 + 0.25$ | $8.8 = 10.8 - 2$ ✓ |
| certificate, property row | $16(0.3125) + 5(0.2) + 24(0.05) = 5 + 1 + 1.2$ | $7.2 = 9.2 - 2$ ✓ |
| certificate, gilts | $-6.1 - (-16)(0.3125) - (-9)(0.2) - (-6)(0.05) = -6.1 + 5 + 1.8 + 0.3$ | $1.0$, inside $[-2, 2]$ ✓ |
| certificate, gold | $5.8 - 11(0.3125) - 4(0.2) - (-2)(0.05) = 5.8 - 3.4375 - 0.8 + 0.1$ | $1.6625$, inside $[-2, 2]$ ✓ |
| lasso cost | fit plus penalty | $p^* = 1.533125$ |
| **per £1,000,000** | weights times £1,000,000 | **£312,500 UK shares, £200,000 US shares, £50,000 property, £437,500 cash** |

On each holding the fit's pull is exactly balanced by the charge of 2; towards gilts and gold the pull is weaker than the charge, so neither is worth holding. The copy tracks the index with a root-mean-square gap of 0.3194 percent a month. It misses by more than plain least squares would, which holds all five, $(0.436692, 0.279295, 0.206540, 0.065030, 0.091073)$, but it needs three holdings, not five.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| No reconcile step: $u$ stays 0 | after 2,000 rounds, $z = 0$ and $x = x_1$; the gap is still 0.432478 | Without a price the rounds minimise $f(x) + g(z) + \tfrac{\rho}{2}\|x - z\|^2$, a different problem whose best point has the copies apart. The price is what closes the gap. |
| Shrink by $\lambda$, not $\lambda/\rho$ | $z = (0.238889, 0.080556, 0, 0, 0)$ | The $z$ step solved a lasso with weight $\rho\lambda = 6$. ADMM converged, to the wrong problem. |
| Stop when $s$ alone is small | stops at round 1 with $s_1 = 0$, holding nothing; $r_1 = 0.432478$ | At rounds 1 and 2 the penalty copy has not moved yet. Only both residuals together certify the answer. |
| Three unknowns updated in turn, one price: minimise 0 subject to `[[1, 1, 1], [1, 1, 2], [1, 2, 2]]` times the unknowns equal to 0, $\rho = 1$, start `(1, 1, 1)` | the unknowns' size goes 1.7321, 3.2759, 6.9647, 32.0870, 413.7233 at rounds 0, 1, 50, 100, 200 | The answer is all zeros, but the theorem covers two blocks only. This is the counterexample of Chen, He, Ye and Yuan: the three-block sweep is not a contraction and the iterates grow without bound. |

---

## Watching the residuals fall

Each round, the fit copy pulls towards the index, the penalty copy towards few, small weights, and the price $u$ keeps a running total of their disagreement.

### One run, round by round

| Round $k$ | UK shares $z$ | US shares $z$ | property $z$ | $r_k$ | $s_k$ |
| --- | --- | --- | --- | --- | --- |
| 1 | 0.000000 | 0.000000 | 0.000000 | 0.432478314 | 0.000000000 |
| 2 | 0.000000 | 0.000000 | 0.000000 | 0.381480604 | 0.000000000 |
| 3 | 0.000000 | 0.058012 | 0.000000 | 0.311769833 | 0.174037038 |
| 5 | 0.261978 | 0.218413 | 0.069303 | 0.047377849 | 0.424325815 |
| 10 | 0.333080 | 0.199459 | 0.041474 | 0.021017609 | 0.014118658 |
| 20 | 0.311611 | 0.200424 | 0.050982 | 0.002012895 | 0.001870240 |
| 40 | 0.312500 | 0.200004 | 0.050007 | 0.000028574 | 0.000008003 |
| 59 | 0.312500 | 0.200000 | 0.050000 | 0.000000518 | 0.000000102 |
| 60 | 0.312500 | 0.200000 | 0.050000 | 0.000000420 | 0.000000081 |

For two rounds the penalty copy holds nothing: the shrink of 2/3 is bigger than any entry of $x + u$. Meanwhile $u$ piles up the gap, so the penalty copy sees $x + u$, larger each round, and at round 3 US shares cross the threshold. By round 5 all three holdings are in. UK shares overshoot to 0.333 at round 10, then settle back to 0.3125. Round 59 is still just above the stopping level ($r = 5.18 \times 10^{-7}$); round 60 is below it on both counts. Gilts and gold stay at exactly zero in $z$ from the first round to the last. In $x$ they are never exactly zero: at round 60 they are 0.000000320 and 0.000000272.

### One force at a time: the agreement weight $\rho$

The agreement weight trades one residual against the other. A small $\rho$ lets the copies disagree cheaply, so $r$ falls slowly. A large $\rho$ forces agreement but makes the price move in big jumps and the penalty copy crawl, so $s$ falls slowly. Rounds to reach both residuals below $5 \times 10^{-7}$:

```
     rho   rounds to stop
    0.5   ████████████████████████████████  324
      1   █████████████████                 166
      3   ██████                             60
     10   ████                               43
     30   ███████                            74
    100   █████████████████████████          252
```

Of these weights, 10 is the fastest, not 3. No formula picks $\rho$ in general; practical codes adjust it during the run by comparing $r$ and $s$.

---

## Code, from first principles, and it actually runs

The script writes ADMM out in full: the $x$ step is a 5-by-5 linear system solved by Gauss–Jordan elimination, the $z$ step is soft-thresholding, the $u$ step one line. It reaches the answer by **four independent roads**. Road 1 is ADMM from zero. Road 2 lists all 243 sign patterns (each holding positive, negative or zero), solves the lasso's equations for each and keeps the one that passes the optimality test; exactly one does. Road 3 checks the lasso's optimality conditions at ADMM's answer, the certificate. Road 4 checks the convergence proof's inequality $V_{k+1} \le V_k - \rho r^2 - s^2/\rho$ at every round. Then it prints the mistakes, the three-block blow-up and the chart's points.

### Python

```python
# ADMM on a split lasso: copy an index with few of five assets.  Standard library only.
# Minimise f(x) + g(z) = 1/2 |Ax - b|^2 + lam*|z|_1 subject to x = z.  Returns in percent a month.
from itertools import product
from math import sqrt, log10

A = [[2, 3, -1, 1, 2], [-1, 1, 2, 0, -2], [3, 2, -2, 2, 1], [1, -2, 1, -1, 3],
     [-2, -1, 3, 1, -1], [0, 2, 0, -2, 1], [2, 0, -1, 3, 0], [1, 1, 1, 0, 2]]  # 8 months x 5 assets
b = [1.8, 0.1, 1.6, 0.3, -0.6, 0.5, 0.9, 1.1]          # the index, same 8 months
LAM, RHO, EPS, N = 2.0, 3.0, 5e-7, 5
AtA = [[float(sum(r[i] * r[j] for r in A)) for j in range(N)] for i in range(N)]
Atb = [sum(r[i] * bb for r, bb in zip(A, b)) for i in range(N)]

def solve(M, v):                        # Gauss-Jordan elimination with row swaps
    k = len(v); M = [list(M[i]) + [v[i]] for i in range(k)]
    for c in range(k):
        p = max(range(c, k), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(k):
            if r != c:
                f = M[r][c] / M[c][c]
                M[r] = [a - f * bb for a, bb in zip(M[r], M[c])]
    return [M[i][k] / M[i][i] for i in range(k)]
def norm(v): return sqrt(sum(t * t for t in v))
def soft(v, t): return 0.0 if abs(v) <= t else (v - t if v > 0 else v + t)
def grad(x): return [sum(AtA[i][j] * x[j] for j in range(N)) - Atb[i] for i in range(N)]
def cost(x): return 0.5 * sum((sum(a * t for a, t in zip(r, x)) - bb) ** 2 for r, bb in zip(A, b)) + LAM * sum(map(abs, x))
def show(v): return " ".join(f"{t:9.6f}" for t in v)

def admm(rho, rounds=1000, eps=EPS, shrink=None, dual=True):
    M = [[AtA[i][j] + (rho if i == j else 0.0) for j in range(N)] for i in range(N)]
    x, z, u, hist = [0.0] * N, [0.0] * N, [0.0] * N, []
    for k in range(1, rounds + 1):
        x = solve(M, [Atb[i] + rho * (z[i] - u[i]) for i in range(N)])   # fit half
        z_old, z = z, [soft(x[i] + u[i], shrink or LAM / rho) for i in range(N)]  # penalty half
        if dual: u = [u[i] + x[i] - z[i] for i in range(N)]               # reconcile
        r, s = norm([x[i] - z[i] for i in range(N)]), rho * norm([z[i] - z_old[i] for i in range(N)])
        hist.append((k, x, z, u, r, s))
        if r < eps and s < eps: break
    return hist

# Road 1: ADMM from x = z = u = 0
hist = admm(RHO); K, x, z, u, r, s = hist[-1]
# Road 2: every sign pattern (+, -, 0 for each asset); keep the one that passes the lasso's test
found = []
for sg in product((1, -1, 0), repeat=N):
    S = [i for i in range(N) if sg[i]]
    w = [0.0] * N
    for i, t in zip(S, solve([[AtA[i][j] for j in S] for i in S], [Atb[i] - LAM * sg[i] for i in S]) if S else []): w[i] = t
    g = grad(w)
    if all(w[i] * sg[i] > 0 for i in S) and all(abs(g[i]) <= LAM + 1e-12 for i in range(N) if not sg[i]): found.append(w)
assert len(found) == 1; xs = found[0]
# Road 3: the certificate.  -grad f(z) must equal lam*sign on holdings and lie in [-lam, lam] elsewhere
gz = grad(z); ystar = [-t for t in grad(xs)]
assert all(abs(gz[i] + LAM * (1 if z[i] > 0 else -1)) < 1e-5 for i in range(N) if z[i] != 0)
assert all(abs(gz[i]) < LAM for i in range(N) if z[i] == 0)
assert max(abs(z[i] - xs[i]) for i in range(N)) < 1e-6 and K == 60
# Road 4: the convergence proof's yardstick V falls every round by at least rho(|r|^2 + |dz|^2)
V = lambda zz, uu: sum((RHO * uu[i] - ystar[i]) ** 2 for i in range(N)) / RHO + RHO * sum((zz[i] - xs[i]) ** 2 for i in range(N))
prev, worst = ([0.0] * N, [0.0] * N), float("inf")
for k, xk, zk, uk, rk, sk in hist:
    drop = V(*prev) - V(zk, uk); need = RHO * rk * rk + sk * sk / RHO
    assert drop >= need - 1e-12; worst = min(worst, drop / need) if need > 1e-20 else worst; prev = (zk, uk)

print("A^T A rows:"); [print("  ", show(row)) for row in AtA]
print("A^T b      ", show(Atb))
print("round 1 x  ", show(hist[0][1]), f" shrink lam/rho = {LAM / RHO:.4f}"); print("round 60 x ", " ".join(f"{t:.9f}" for t in x))
print("rounds, k: z_UK z_US z_prop |r| |s|")
for k, xk, zk, uk, rk, sk in hist:
    if k in (1, 2, 3, 5, 10, 20, 40, 59, 60):
        print(f"  {k:3d} {zk[0]:.6f} {zk[1]:.6f} {zk[4]:.6f} {rk:.9f} {sk:.9f}")
print("ADMM z     ", show(z)); print("enumerated ", show(xs))
print("-grad f(z) ", " ".join(f"{-t:.5f}" for t in gz), "  (lam = 2)")
print(f"lasso cost at z {cost(z):.6f}, at enumerated {cost(xs):.6f} = fit {cost(xs) - LAM * sum(map(abs, xs)):.6f} + penalty {LAM * sum(map(abs, xs)):.6f}")
print("least squares", show(solve(AtA, Atb)))
fit = [sum(a * t for a, t in zip(row, xs)) for row in A]
print("copy's returns", " ".join(f"{t:.4f}" for t in fit), f" rms gap {sqrt(sum((f - bb) ** 2 for f, bb in zip(fit, b)) / 8):.4f}")
print(f"per 1000000 pounds: UK shares {xs[0]*1e6:.0f}, US shares {xs[1]*1e6:.0f}, property {xs[4]*1e6:.0f}, cash {(1-sum(xs))*1e6:.0f}")
print(f"V falls every round; smallest drop / proof's floor = {worst:.4f}")
print("chart, k: log10|r|, log10|s|, log10|z - z*|")
for k, xk, zk, uk, rk, sk in hist:
    if k % 5 == 0:
        print(f"  {k:3d} {log10(rk):7.3f} {log10(sk):7.3f} {log10(norm([zk[i] - xs[i] for i in range(N)])):7.3f}")
print("rounds to stop at rho 0.5, 1, 3, 10, 30, 100:", " ".join(str(admm(rho)[-1][0]) for rho in (0.5, 1.0, 3.0, 10.0, 30.0, 100.0)))
# What breaks
nd = admm(RHO, rounds=2000, dual=False)[-1]
print(f"no dual update, after {nd[0]} rounds: x {show(nd[1])}, z {show(nd[2])}, |x - z| {nd[4]:.6f}")
assert nd[4] > 0.01
ws = admm(RHO, shrink=LAM)[-1]
print(f"shrink by lam not lam/rho: z {show(ws[2])}, the lasso at weight rho*lam = {RHO * LAM:.1f}")
assert abs(ws[2][1] - xs[1]) > 0.05
# Three blocks: minimise 0 subject to B1 v1 + B2 v2 + B3 v3 = 0, sweeping one block at a time
B = [[1, 1, 1], [1, 1, 2], [1, 2, 2]]; v, y = [1.0, 1.0, 1.0], [0.0, 0.0, 0.0]
print(f"three blocks, round   0: |v| = {norm(v):.4f}")
for k in range(1, 201):
    for j in range(3):
        rest = [sum(B[i][m] * v[m] for m in range(3) if m != j) + y[i] for i in range(3)]
        v[j] = -sum(B[i][j] * rest[i] for i in range(3)) / sum(B[i][j] ** 2 for i in range(3))
    y = [y[i] + sum(B[i][m] * v[m] for m in range(3)) for i in range(3)]
    if k in (1, 50, 100, 200): print(f"three blocks, round {k:3d}: |v| = {norm(v):.4f}")
assert norm(v) > 10
for lam in (1.0, 4.0):
    LAM = lam; print(f"try lam {lam}: z {show(admm(RHO)[-1][2])}")
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
A^T A rows:
   24.000000 12.000000 -16.000000 11.000000 16.000000
   12.000000 24.000000 -9.000000  4.000000  5.000000
   -16.000000 -9.000000 21.000000 -6.000000 -6.000000
   11.000000  4.000000 -6.000000 20.000000 -2.000000
   16.000000  5.000000 -6.000000 -2.000000 24.000000
A^T b       12.700000 10.800000 -6.100000  5.800000  9.200000
round 1 x    0.253348  0.267164  0.087908  0.122235  0.169723  shrink lam/rho = 0.6667
round 60 x  0.312499994 0.200000059 0.000000320 0.000000272 0.050000097
rounds, k: z_UK z_US z_prop |r| |s|
    1 0.000000 0.000000 0.000000 0.432478314 0.000000000
    2 0.000000 0.000000 0.000000 0.381480604 0.000000000
    3 0.000000 0.058012 0.000000 0.311769833 0.174037038
    5 0.261978 0.218413 0.069303 0.047377849 0.424325815
   10 0.333080 0.199459 0.041474 0.021017609 0.014118658
   20 0.311611 0.200424 0.050982 0.002012895 0.001870240
   40 0.312500 0.200004 0.050007 0.000028574 0.000008003
   59 0.312500 0.200000 0.050000 0.000000518 0.000000102
   60 0.312500 0.200000 0.050000 0.000000420 0.000000081
ADMM z       0.312500  0.200000  0.000000  0.000000  0.050000
enumerated   0.312500  0.200000  0.000000  0.000000  0.050000
-grad f(z)  2.00000 2.00000 1.00000 1.66250 2.00000   (lam = 2)
lasso cost at z 1.533125, at enumerated 1.533125 = fit 0.408125 + penalty 1.125000
least squares  0.436692  0.279295  0.206540  0.065030  0.091073
copy's returns 1.3250 -0.2125 1.3875 0.0625 -0.8750 0.4500 0.6250 0.6125  rms gap 0.3194
per 1000000 pounds: UK shares 312500, US shares 200000, property 50000, cash 437500
V falls every round; smallest drop / proof's floor = 1.7866
chart, k: log10|r|, log10|s|, log10|z - z*|
    5  -1.324  -0.372  -1.243
   10  -1.677  -1.850  -1.652
   15  -2.249  -2.193  -2.664
   20  -2.696  -2.728  -2.857
   25  -3.162  -3.647  -3.744
   30  -3.631  -4.128  -4.275
   35  -4.085  -4.693  -4.513
   40  -4.544  -5.097  -5.110
   45  -5.003  -5.780  -5.601
   50  -5.461  -6.193  -5.996
   55  -5.919  -6.581  -6.466
   60  -6.377  -7.093  -6.945
rounds to stop at rho 0.5, 1, 3, 10, 30, 100: 324 166 60 43 74 252
no dual update, after 2000 rounds: x  0.253348  0.267164  0.087908  0.122235  0.169723, z  0.000000  0.000000  0.000000  0.000000  0.000000, |x - z| 0.432478
shrink by lam not lam/rho: z  0.238889  0.080556  0.000000  0.000000  0.000000, the lasso at weight rho*lam = 6.0
three blocks, round   0: |v| = 1.7321
three blocks, round   1: |v| = 3.2759
three blocks, round  50: |v| = 6.9647
three blocks, round 100: |v| = 32.0870
three blocks, round 200: |v| = 413.7233
try lam 1.0: z  0.294488  0.243661  0.036055  0.050899  0.107834
try lam 4.0: z  0.294444  0.136111  0.000000  0.000000  0.000000
ALL CHECKS PASS
```

### Rust

```rust
// ADMM on a split lasso: copy an index with few of five assets.  Standard library only.
// Minimise f(x) + g(z) = 1/2 |Ax - b|^2 + lam*|z|_1 subject to x = z.  Returns in percent a month.
const N: usize = 5;
const A: [[f64; 5]; 8] = [[2., 3., -1., 1., 2.], [-1., 1., 2., 0., -2.], [3., 2., -2., 2., 1.], [1., -2., 1., -1., 3.],
    [-2., -1., 3., 1., -1.], [0., 2., 0., -2., 1.], [2., 0., -1., 3., 0.], [1., 1., 1., 0., 2.]]; // 8 months x 5 assets
const B: [f64; 8] = [1.8, 0.1, 1.6, 0.3, -0.6, 0.5, 0.9, 1.1]; // the index, same 8 months
const RHO: f64 = 3.0;
const EPS: f64 = 5e-7;

struct P { ata: Vec<Vec<f64>>, atb: Vec<f64>, lam: f64 }
type Round = (usize, Vec<f64>, Vec<f64>, Vec<f64>, f64, f64);

fn solve(m: &[Vec<f64>], v: &[f64]) -> Vec<f64> { // Gauss-Jordan elimination with row swaps
    let k = v.len();
    let mut m: Vec<Vec<f64>> = (0..k).map(|i| { let mut r = m[i].clone(); r.push(v[i]); r }).collect();
    for c in 0..k {
        let mut p = c;
        for r in c + 1..k { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in 0..k {
            if r != c {
                let f = m[r][c] / m[c][c];
                let pivot = m[c].clone();
                for j in 0..=k { m[r][j] = m[r][j] - f * pivot[j]; }
            }
        }
    }
    (0..k).map(|i| m[i][k] / m[i][i]).collect()
}
fn norm(v: &[f64]) -> f64 { v.iter().fold(0.0, |a, t| a + t * t).sqrt() }
fn soft(v: f64, t: f64) -> f64 { if v.abs() <= t { 0.0 } else if v > 0.0 { v - t } else { v + t } }
fn diff(a: &[f64], b: &[f64]) -> Vec<f64> { (0..a.len()).map(|i| a[i] - b[i]).collect() }
fn show(v: &[f64]) -> String { v.iter().map(|t| format!("{:9.6}", t)).collect::<Vec<_>>().join(" ") }
fn fitted(x: &[f64]) -> Vec<f64> { A.iter().map(|r| (0..N).fold(0.0, |a, j| a + r[j] * x[j])).collect() }
impl P {
    fn grad(&self, x: &[f64]) -> Vec<f64> {
        (0..N).map(|i| (0..N).fold(0.0, |a, j| a + self.ata[i][j] * x[j]) - self.atb[i]).collect()
    }
    fn cost(&self, x: &[f64]) -> f64 {
        let f = fitted(x);
        0.5 * (0..8).fold(0.0, |a, r| a + (f[r] - B[r]).powi(2)) + self.lam * x.iter().fold(0.0, |a, t| a + t.abs())
    }
    fn admm(&self, rho: f64, rounds: usize, shrink: Option<f64>, dual: bool) -> Vec<Round> {
        let m: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| self.ata[i][j] + if i == j { rho } else { 0.0 }).collect()).collect();
        let (mut z, mut u, mut hist) = (vec![0.0; N], vec![0.0; N], Vec::new());
        for k in 1..=rounds {
            let rhs: Vec<f64> = (0..N).map(|i| self.atb[i] + rho * (z[i] - u[i])).collect();
            let x = solve(&m, &rhs); // fit half
            let t = shrink.unwrap_or(self.lam / rho);
            let z_new: Vec<f64> = (0..N).map(|i| soft(x[i] + u[i], t)).collect(); // penalty half
            if dual { u = (0..N).map(|i| u[i] + x[i] - z_new[i]).collect(); } // reconcile
            let r = norm(&diff(&x, &z_new));
            let s = rho * norm(&diff(&z_new, &z));
            z = z_new;
            hist.push((k, x, z.clone(), u.clone(), r, s));
            if r < EPS && s < EPS { break; }
        }
        hist
    }
}

fn main() {
    let ata: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| A.iter().fold(0.0, |a, r| a + r[i] * r[j])).collect()).collect();
    let atb: Vec<f64> = (0..N).map(|i| (0..8).fold(0.0, |a, r| a + A[r][i] * B[r])).collect();
    let mut p = P { ata, atb, lam: 2.0 };
    // Road 1: ADMM from x = z = u = 0
    let hist = p.admm(RHO, 1000, None, true);
    let (kk, xk, z, _, _, _) = hist.last().unwrap().clone();
    // Road 2: every sign pattern (+, -, 0 for each asset); keep the one that passes the lasso's test
    let mut found: Vec<Vec<f64>> = Vec::new();
    for code in 0..243usize {
        let mut c = code;
        let mut sg = [0i32; N];
        for i in (0..N).rev() { sg[i] = [1, -1, 0][c % 3]; c /= 3; }
        let s: Vec<usize> = (0..N).filter(|&i| sg[i] != 0).collect();
        let mut w = vec![0.0; N];
        if !s.is_empty() {
            let m: Vec<Vec<f64>> = s.iter().map(|&i| s.iter().map(|&j| p.ata[i][j]).collect()).collect();
            let rhs: Vec<f64> = s.iter().map(|&i| p.atb[i] - p.lam * sg[i] as f64).collect();
            for (&i, t) in s.iter().zip(solve(&m, &rhs)) { w[i] = t; }
        }
        let g = p.grad(&w);
        if s.iter().all(|&i| w[i] * sg[i] as f64 > 0.0) && (0..N).all(|i| sg[i] != 0 || g[i].abs() <= p.lam + 1e-12) { found.push(w); }
    }
    assert!(found.len() == 1);
    let xs = found[0].clone();
    // Road 3: the certificate.  -grad f(z) must equal lam*sign on holdings and lie in [-lam, lam] elsewhere
    let gz = p.grad(&z);
    let ystar: Vec<f64> = p.grad(&xs).iter().map(|t| -t).collect();
    assert!((0..N).all(|i| z[i] == 0.0 || (gz[i] + p.lam * z[i].signum()).abs() < 1e-5));
    assert!((0..N).all(|i| z[i] != 0.0 || gz[i].abs() < p.lam));
    assert!(diff(&z, &xs).iter().all(|t| t.abs() < 1e-6) && kk == 60);
    // Road 4: the convergence proof's yardstick V falls every round by at least rho(|r|^2 + |dz|^2)
    let v = |zz: &[f64], uu: &[f64]| (0..N).fold(0.0, |a, i| a + (RHO * uu[i] - ystar[i]).powi(2)) / RHO
        + RHO * (0..N).fold(0.0, |a, i| a + (zz[i] - xs[i]).powi(2));
    let (mut pz, mut pu, mut worst) = (vec![0.0; N], vec![0.0; N], f64::INFINITY);
    for (_, _, zk, uk, rk, sk) in &hist {
        let drop = v(&pz, &pu) - v(zk, uk);
        let need = RHO * rk * rk + sk * sk / RHO;
        assert!(drop >= need - 1e-12);
        if need > 1e-20 { worst = worst.min(drop / need); }
        pz = zk.clone(); pu = uk.clone();
    }

    println!("A^T A rows:");
    for row in &p.ata { println!("   {}", show(row)); }
    println!("A^T b       {}", show(&p.atb));
    println!("round 1 x   {}  shrink lam/rho = {:.4}", show(&hist[0].1), p.lam / RHO);
    println!("round 60 x  {}", xk.iter().map(|t| format!("{:.9}", t)).collect::<Vec<_>>().join(" "));
    println!("rounds, k: z_UK z_US z_prop |r| |s|");
    for (k, _, zk, _, rk, sk) in &hist {
        if [1, 2, 3, 5, 10, 20, 40, 59, 60].contains(k) {
            println!("  {:3} {:.6} {:.6} {:.6} {:.9} {:.9}", k, zk[0], zk[1], zk[4], rk, sk);
        }
    }
    println!("ADMM z      {}", show(&z));
    println!("enumerated  {}", show(&xs));
    println!("-grad f(z)  {}   (lam = 2)", gz.iter().map(|t| format!("{:.5}", -t)).collect::<Vec<_>>().join(" "));
    let pen = p.lam * xs.iter().fold(0.0, |a, t| a + t.abs());
    println!("lasso cost at z {:.6}, at enumerated {:.6} = fit {:.6} + penalty {:.6}", p.cost(&z), p.cost(&xs), p.cost(&xs) - pen, pen);
    println!("least squares {}", show(&solve(&p.ata, &p.atb)));
    let fit = fitted(&xs);
    let gap = ((0..8).fold(0.0, |a, r| a + (fit[r] - B[r]).powi(2)) / 8.0).sqrt();
    println!("copy's returns {}  rms gap {:.4}", fit.iter().map(|t| format!("{:.4}", t)).collect::<Vec<_>>().join(" "), gap);
    let total = xs.iter().fold(0.0, |a, t| a + t);
    println!("per 1000000 pounds: UK shares {:.0}, US shares {:.0}, property {:.0}, cash {:.0}",
        xs[0] * 1e6, xs[1] * 1e6, xs[4] * 1e6, (1.0 - total) * 1e6);
    println!("V falls every round; smallest drop / proof's floor = {:.4}", worst);
    println!("chart, k: log10|r|, log10|s|, log10|z - z*|");
    for (k, _, zk, _, rk, sk) in &hist {
        if k % 5 == 0 {
            println!("  {:3} {:7.3} {:7.3} {:7.3}", k, rk.log10(), sk.log10(), norm(&diff(zk, &xs)).log10());
        }
    }
    let counts: Vec<String> = [0.5, 1.0, 3.0, 10.0, 30.0, 100.0].iter().map(|&rho| p.admm(rho, 1000, None, true).last().unwrap().0.to_string()).collect();
    println!("rounds to stop at rho 0.5, 1, 3, 10, 30, 100: {}", counts.join(" "));
    // What breaks
    let nd = p.admm(RHO, 2000, None, false).last().unwrap().clone();
    println!("no dual update, after {} rounds: x {}, z {}, |x - z| {:.6}", nd.0, show(&nd.1), show(&nd.2), nd.4);
    assert!(nd.4 > 0.01);
    let ws = p.admm(RHO, 1000, Some(p.lam), true).last().unwrap().clone();
    println!("shrink by lam not lam/rho: z {}, the lasso at weight rho*lam = {:.1}", show(&ws.2), RHO * p.lam);
    assert!((ws.2[1] - xs[1]).abs() > 0.05);
    // Three blocks: minimise 0 subject to B1 v1 + B2 v2 + B3 v3 = 0, sweeping one block at a time
    let bm = [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [1.0, 2.0, 2.0]];
    let (mut vv, mut y) = ([1.0f64; 3], [0.0f64; 3]);
    println!("three blocks, round   0: |v| = {:.4}", norm(&vv));
    for k in 1..=200 {
        for j in 0..3 {
            let rest: Vec<f64> = (0..3).map(|i| (0..3).filter(|&m| m != j).fold(0.0, |a, m| a + bm[i][m] * vv[m]) + y[i]).collect();
            vv[j] = -(0..3).fold(0.0, |a, i| a + bm[i][j] * rest[i]) / (0..3).fold(0.0, |a, i| a + bm[i][j] * bm[i][j]);
        }
        for i in 0..3 { y[i] = y[i] + (0..3).fold(0.0, |a, m| a + bm[i][m] * vv[m]); }
        if [1, 50, 100, 200].contains(&k) { println!("three blocks, round {:3}: |v| = {:.4}", k, norm(&vv)); }
    }
    assert!(norm(&vv) > 10.0);
    for lam in [1.0, 4.0] {
        p.lam = lam;
        println!("try lam {:.1}: z {}", lam, show(&p.admm(RHO, 1000, None, true).last().unwrap().2));
    }
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
A^T A rows:
   24.000000 12.000000 -16.000000 11.000000 16.000000
   12.000000 24.000000 -9.000000  4.000000  5.000000
   -16.000000 -9.000000 21.000000 -6.000000 -6.000000
   11.000000  4.000000 -6.000000 20.000000 -2.000000
   16.000000  5.000000 -6.000000 -2.000000 24.000000
A^T b       12.700000 10.800000 -6.100000  5.800000  9.200000
round 1 x    0.253348  0.267164  0.087908  0.122235  0.169723  shrink lam/rho = 0.6667
round 60 x  0.312499994 0.200000059 0.000000320 0.000000272 0.050000097
rounds, k: z_UK z_US z_prop |r| |s|
    1 0.000000 0.000000 0.000000 0.432478314 0.000000000
    2 0.000000 0.000000 0.000000 0.381480604 0.000000000
    3 0.000000 0.058012 0.000000 0.311769833 0.174037038
    5 0.261978 0.218413 0.069303 0.047377849 0.424325815
   10 0.333080 0.199459 0.041474 0.021017609 0.014118658
   20 0.311611 0.200424 0.050982 0.002012895 0.001870240
   40 0.312500 0.200004 0.050007 0.000028574 0.000008003
   59 0.312500 0.200000 0.050000 0.000000518 0.000000102
   60 0.312500 0.200000 0.050000 0.000000420 0.000000081
ADMM z       0.312500  0.200000  0.000000  0.000000  0.050000
enumerated   0.312500  0.200000  0.000000  0.000000  0.050000
-grad f(z)  2.00000 2.00000 1.00000 1.66250 2.00000   (lam = 2)
lasso cost at z 1.533125, at enumerated 1.533125 = fit 0.408125 + penalty 1.125000
least squares  0.436692  0.279295  0.206540  0.065030  0.091073
copy's returns 1.3250 -0.2125 1.3875 0.0625 -0.8750 0.4500 0.6250 0.6125  rms gap 0.3194
per 1000000 pounds: UK shares 312500, US shares 200000, property 50000, cash 437500
V falls every round; smallest drop / proof's floor = 1.7866
chart, k: log10|r|, log10|s|, log10|z - z*|
    5  -1.324  -0.372  -1.243
   10  -1.677  -1.850  -1.652
   15  -2.249  -2.193  -2.664
   20  -2.696  -2.728  -2.857
   25  -3.162  -3.647  -3.744
   30  -3.631  -4.128  -4.275
   35  -4.085  -4.693  -4.513
   40  -4.544  -5.097  -5.110
   45  -5.003  -5.780  -5.601
   50  -5.461  -6.193  -5.996
   55  -5.919  -6.581  -6.466
   60  -6.377  -7.093  -6.945
rounds to stop at rho 0.5, 1, 3, 10, 30, 100: 324 166 60 43 74 252
no dual update, after 2000 rounds: x  0.253348  0.267164  0.087908  0.122235  0.169723, z  0.000000  0.000000  0.000000  0.000000  0.000000, |x - z| 0.432478
shrink by lam not lam/rho: z  0.238889  0.080556  0.000000  0.000000  0.000000, the lasso at weight rho*lam = 6.0
three blocks, round   0: |v| = 1.7321
three blocks, round   1: |v| = 3.2759
three blocks, round  50: |v| = 6.9647
three blocks, round 100: |v| = 32.0870
three blocks, round 200: |v| = 413.7233
try lam 1.0: z  0.294488  0.243661  0.036055  0.050899  0.107834
try lam 4.0: z  0.294444  0.136111  0.000000  0.000000  0.000000
ALL CHECKS PASS
```

> [!TIP]
> **Try changing**
> - Guess first: does a larger lasso weight drop property or a share holding? Set `LAM` to 4 (the last loop already does). Property goes: $z = (0.294444, 0.136111, 0, 0, 0)$.
> - Guess first: does a smaller weight keep three holdings? At `LAM = 1.0` all five are held: $(0.294488, 0.243661, 0.036055, 0.050899, 0.107834)$.
> - Guess first: is a bigger $\rho$ always faster? Set `RHO` to 10 and the run stops at round 43; at 100 it takes 252 rounds. (The assert `K == 60` will then fail, as it should.)
> - Guess first: how much of the work does the price do? Call `admm(RHO, rounds=2000, dual=False)`, as the "What breaks" part of the script does: after 2,000 rounds the copies are still 0.432478 apart, and $z$ holds nothing.

---

## The usual mistake

> [!warning]
> **Stopping when the copies look settled, without checking both residuals.** At rounds 1 and 2 the penalty copy does not move at all, so $s = 0$, yet it holds nothing and sits 0.432478 away from the fit copy. Only $r$ and $s$ together match the optimality conditions of Step 3; here $s$ alone was zero at an answer that holds nothing.
>
> - **Shrinking by $\lambda$ instead of $\lambda/\rho$.** The run converges cleanly, to $(0.238889, 0.080556, 0, 0, 0)$, the lasso with weight 6.
> - **Reading the answer from $x$.** The sparse answer is $z$. The fit copy is never exactly zero: gilts sit at 0.000000320 in $x_{60}$.
> - **Dropping the price update.** The copies stay 0.432478 apart for ever, and $z$ holds nothing.
> - **Adding a third block "the same way".** With three unknowns updated in turn and one price, the sizes grow from 1.7321 to 413.7233 in 200 rounds. Group the unknowns into two blocks first.

---

## Where you meet it in real life

- **Fitting one model on many machines.** Each machine fits its own share of the data as an $x$ step, and the shared answer is the $z$ step: an average followed by the penalty's shrink. Only the copies travel over the network, never the data.
- **Quadratic-program solvers in controllers.** Embedded solvers for problems like [Quadratic programs](01-quadratic-programs-and-markowitz.md) split "minimise the bowl" from "stay inside the box" and run ADMM rounds, because each round is one cached linear solve and a clip, cheap enough for a control loop.
- **Medical imaging.** Scanners that take fewer measurements rebuild the image by a fit to the measurements plus a penalty on edges; the two are split exactly as here.
- **Portfolio rebalancing.** A trading cost on each change of holding is an $\ell_1$ penalty on the trades, and the same split separates "track the target" from "trade little".

> **Say it back**
> ADMM gives each half of a hard problem its own copy of the unknowns and joins the copies with the constraint that they are equal. Each round, it solves the fit with the penalty copy fixed, then the penalty with the new fit copy fixed, then adds the leftover gap to a running price. The penalty's optimality condition then holds exactly every round, and the other two conditions are measured by the primal and dual residuals. For two convex halves both residuals fall to zero. On the five-holding lasso they did so in 60 rounds, at £312,500, £200,000 and £50,000 per million, certified by the lasso's conditions.

---

## What this builds on

- [Penalties and augmented Lagrangians](../03-Constrained%20Optimisation/07-penalty-and-augmented-lagrangian-methods.md): the augmented Lagrangian $L_\rho$, the method of multipliers, and why a price update beats sending the penalty weight to infinity.
- [Proximal gradient](06-proximal-methods-ista-fista-and-the-lasso.md): the lasso, soft-thresholding as the proximal step of the $\ell_1$ penalty, and a one-copy method for the same problem.

## Where this goes next

- [Stochastic gradient](08-stochastic-gradient-and-sample-average-approximation.md): the next card, for when there is too much data even for one linear solve per round, so each step uses a sample.
- [Robust and chance constraints](10-robust-and-chance-constrained-optimisation.md): problems with a shared answer across many scenarios, where splitting by scenario and agreeing through a price is the same consensus idea.

The open question this card leaves: how to choose $\rho$ well before the run, rather than adjusting it during the run.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Boyd, S., Parikh, N., Chu, E., Peleato, B. and Eckstein, J. (2011), "Distributed optimization and statistical learning via the alternating direction method of multipliers", *Foundations and Trends in Machine Learning* 3(1), 1–122. [doi:10.1561/2200000016](https://doi.org/10.1561/2200000016). The scaled form, the residuals and stopping test, the convergence theorem with its yardstick $V$, and the lasso and consensus examples.
- Gabay, D. and Mercier, B. (1976), "A dual algorithm for the solution of nonlinear variational problems via finite element approximation", *Computers & Mathematics with Applications* 2(1), 17–40. [doi:10.1016/0898-1221(76)90003-1](https://doi.org/10.1016/0898-1221(76)90003-1). One of the two original papers on the method, with its first convergence proof.
- Eckstein, J. and Bertsekas, D. P. (1992), "On the Douglas–Rachford splitting method and the proximal point algorithm for maximal monotone operators", *Mathematical Programming* 55, 293–318. [doi:10.1007/BF01581204](https://doi.org/10.1007/BF01581204). Shows ADMM is Douglas–Rachford splitting applied to the dual, and allows inexact inner solves.
- He, B. and Yuan, X. (2012), "On the O(1/n) convergence rate of the Douglas–Rachford alternating direction method", *SIAM Journal on Numerical Analysis* 50(2), 700–709. [doi:10.1137/110836936](https://doi.org/10.1137/110836936). The general averaged $O(1/k)$ rate quoted in Step 4.
- Chen, C., He, B., Ye, Y. and Yuan, X. (2016), "The direct extension of ADMM for multi-block convex minimization problems is not necessarily convergent", *Mathematical Programming* 155(1–2), 57–79. [doi:10.1007/s10107-014-0826-5](https://doi.org/10.1007/s10107-014-0826-5). The three-block counterexample in What breaks.
