# Hitting times: when a walk first reaches a level, and why the wait can have infinite mean

[Syllabus](../../../SYLLABUS.md) → [Stochastic processes and calculus](../README.md) → [Random Walks and Filtrations](../README.md#s01) → Hitting times

---

## General Overview

Ana and Ben toss a fair coin once a round. The winner of each toss takes $1 from the other. They start level, and nobody runs out of money: the match goes on as long as it must. Time is counted in rounds.

When is the score level again? Half the time at round 2. About 1 time in 4 it is still not level after 10 rounds; about 1 time in 40, after 1,000 rounds.

The score comes back to level with probability 1. Yet the average wait is infinite. No contradiction: the very long waits are rare, but not rare enough, and they drag the average up without limit.

The first round on which a walk reaches a chosen level is its **hitting time**, or **first passage time**; for the starting level it is the **return time**. Two questions: does it arrive, and how long does it take.

**The fair walk reaches every level, and comes back to its start, with probability 1; but the average wait for either is infinite, because the chance of still waiting after n rounds shrinks only like one over the square root of n.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; the complete arguments sit in folded Detailed proof callouts.

### The picture: one match, and the round it comes back level

<p align="center"><img src="../figures/first-passage-and-hitting-times.svg" alt="One sample match of 16 rounds: the score falls to minus 7 dollars at round 7 and climbs back to level at round 16, the return time" width="420"></p>

One sample match from the seeded generator in the code (seed 7, the first match whose return falls in rounds 10 to 24), one step per round, drawn to scale. The score is Ana's winnings. Ben pulls $7 ahead by round 7; Ana wins it back, and the score is level at round 16, the return time.

---

## The formula

Notation first, in words. The score after n rounds is written $S_n$: Ana's total winnings in dollars, the simple random walk of [Simple random walk](02-simple-random-walk.md). Each round it moves up one dollar with probability $p$ and down one dollar with probability $q = 1 - p$. The Greek letter tau, $\tau_a$, is the first round on which the score equals the level $a$. The return time $T$ is the first round, after round 0, on which the score is level again.

$$\tau_a = \min\{\,n \ge 1 : S_n = a\,\}, \qquad T = \tau_0, \qquad \tau_a = \infty \text{ if the score never gets there.}$$

**Read it aloud:** the hitting time of a level is the first round the score stands on it; if that never happens, the hitting time is infinite.

Whether it arrives, for a target $a$ of 1 or more:

$$P(\tau_a < \infty) = \begin{cases} 1 & p \ge \tfrac12 \\ (p/q)^a & p < \tfrac12 \end{cases} \qquad\qquad P(T < \infty) = 1 - \lvert p - q \rvert.$$

**Read it aloud:** a fair walk, or one tilted towards the target, gets there for sure; one tilted away loses a factor p over q per level; and the chance of ever coming back is one minus the gap between p and q.

How long, for the fair coin:

$$P(T > 2n) = u_{2n} = \binom{2n}{n}\frac{1}{2^{2n}}, \qquad E[T] = \infty.$$

**Read it aloud:** the chance of no return in 2n rounds equals the chance of a tie at round 2n; and the average return time is infinite.

The binomial coefficient $\binom{2n}{n}$ counts the ways to choose which n of 2n rounds Ana wins. The return time is always even: a tie needs as many wins as losses.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $S_n$, $S_{2n}$ | the score after n rounds: Ana's winnings in dollars | starts at 0 | — |
| $n$ | rounds played: the clock | 10, 100, 1,000 | fewer matches still waiting |
| $p$ | chance Ana wins a round | 0.5; tilted: 0.4, 0.6 | upward targets come sooner |
| $q$ | chance Ben wins a round, 1 − p | 0.5 | upward targets may be missed |
| $a$ | the target level, in dollars | +1, +3 | a tilted-away walk arrives less often |
| $\tau_a$, $\tau_1$ | hitting time: first round the score equals a | at least 1 round | — |
| $T$ | return time: first round after 0 with the score level | 16 in the picture | — |
| $b$ | depth of a temporary floor at −b dollars | 10, 100, 1,000 | the capped wait grows with it |
| $h$ | chance the score ever climbs one level | 1 when fair; 0.666667 at p = 0.4 | — |
| $u_{2n}$, $u_0$, $u_2$, $u_4$, $u_6$, $u_8$, $u_{10}$ | chance of a tie at round 2n, and of no return by then | $u_{10}$ = 0.246094 | — |
| $N$ | half the cap: the wait is cut off at 2N rounds | cap 10: N = 5 | capped average grows like √N |
| $k$ | a whole-number counter inside steps and proofs: a round, a number of returns, half a final score, or a factor's place | — | — |
| $M(j)$ | in the reflection proof: the number of (2n − 1)-round matches whose net change is j | $M(1)$, half of $\binom{2n}{n}$ | — |
| $s$ | the dial of the generating function: the chance of a first return at round 2n is weighted by s to the power 2n | s = 1 adds up the chances themselves | — |

### When it holds

- **Steps of exactly one dollar.** The score cannot jump a level, so reaching +3 means reaching +1, +2, +3 in turn. With larger steps it can leap past, and the power $(p/q)^a$ is wrong.
- **Independent rounds with the same p.** After each hit the game restarts afresh, which the first-step equations use. If the chance drifts from round to round, the formulas do not apply.
- **Exact fairness, for the sure return and the infinite mean.** At p = 0.4 or 0.6 the chance of ever being level again drops to 0.8. At p = 0.6 the wait to reach +1 has a finite average of 5 rounds.
- **No floor and no deadline.** A gambler with 10 chips who stops at 0 or 11 plays 10 rounds on average. The infinite mean needs unlimited credit and time.
- **One dimension.** Pólya proved in 1921 that a walk on a street grid also returns for sure in two dimensions, but not in three. This card proves only the line.

---

## Why it works

### Step 0: a hitting time is decided by the past, and the game restarts after it

Watching round by round, anyone can say whether the level has been reached yet, without seeing future tosses. Such a time is a stopping time ([Stopping times](../02-Martingales/03-stopping-times-and-optional-stopping.md)); the hitting time is its first example.

The tosses after a hit are new coins, untouched by it, so the game restarts afresh at every hit. That fresh start turns "does it arrive" into a short equation. A temporary floor, moved further and further down, ties the endless game to the finite one solved in [Gambler's ruin](04-gamblers-ruin.md).

### Step 1: the chance of ever climbing one level solves a quadratic

Let $h$ be the chance that the score ever reaches +1. With chance p Ana wins round 1 and is there. With chance q she loses it; from −1 the score must climb two levels, each a fresh copy of the first, with chance h times h.

$$h = p + q\,h^2.$$

It factors as $(h - 1)(q\,h - p) = 0$, so h is 1 or p/q. The equation cannot choose; a floor can. Ask for +1 before a floor at −b: that is gambler's ruin, with answer b/(b + 1) for the fair coin. A match that reaches +1 dips only so far first, so a deep enough floor never interferes. Hence h is the limit as b grows: 1 for the fair coin, p/q when p is below one half (0.666667 at p = 0.4).

Reaching +a is a climbs of one level in a row, so $P(\tau_a < \infty) = h^a$. At p = 0.4 the chance of ever being $3 ahead is 0.296296.

<details>
<summary>Detailed proof: the fresh start and the moving floor</summary>

**Fresh start.** Whether the first hit of +1 is at round k is decided by tosses 1 to k. Later tosses are independent of those, with the same law. Summing over k, the chance of reaching +1 and then climbing once more is the sum of P(first hit at k) times h, that is h times h. Downward climbs work the same way.

**First step.** Condition on round 1 (the law of total probability, from [Conditional probability](../../09-Probability%20and%20statistics/01-Chance%20and%20Events/05-conditional-probability.md)): up gives chance 1, down needs two fresh climbs, chance $h^2$. Hence $h = p + q\,h^2$.

**Moving floor.** Let E(b) be the event that the score reaches +1 before −b. Steps are ±1, so to reach −(b + 1) the score must first touch −b; hence E(b) is contained in E(b + 1). A match with $\tau_1 = k$ has a lowest score on rounds 0 to k; any floor −b below that puts the match in E(b). So the union of the events E(b) is the event that $\tau_1$ is finite, and continuity of probability along an increasing sequence ([Continuity and subadditivity](../../10-Measure%20and%20integration/01-Sets%20You%20Can%20Measure/05-continuity-of-measure.md)) gives $P(\tau_1 < \infty) = \lim_b P(E(b))$.

**The limit.** [Gambler's ruin](04-gamblers-ruin.md) gives P(E(b)) = b/(b + 1) when p = q, and $(1 - (q/p)^b)/(1 - (q/p)^{b+1})$ otherwise. Fair: the limit is 1. When p > q, q/p is below 1, its powers shrink to 0, and the limit is 1. When p < q, divide top and bottom by $(q/p)^{b+1}$: the limit is p/q. Then $P(\tau_a < \infty) = h^a$, by a fresh climbs in a row.

</details>

### Step 2: the chance of ever coming back is one minus the gap between p and q

After round 1 the score is +1 (chance p) or −1 (chance q). From +1, getting back is one level downward: Step 1 with p and q swapped gives chance 1 if q ≥ p, else q/p. From −1 it is 1 if p ≥ q, else p/q. So

$$P(T < \infty) = p\cdot\min(1, q/p) + q\cdot\min(1, p/q) = 2\min(p, q) = 1 - \lvert p - q\rvert.$$

using p + q = 1. For the fair coin it is 1: the walk is **recurrent**, meaning it comes back for sure. Each return restarts the game, so it comes back again and again, infinitely often. At p = 0.4 the chance is 0.8, and at least k returns has chance 0.8 to the power k: after a few returns the walk leaves for good, which is called **transient**.

Inside walls at +b and −b, the fair score is level again before a wall with chance 1 − 1/b: 0.9, 0.99, 0.999 for b = 10, 100, 1,000. It climbs towards 1 and reaches it only with no walls.

### Step 3: the chance of still waiting after 2n rounds is the chance of a tie at 2n

The reflection principle of [Reflection principle](05-reflection-principle-for-walks.md) gives the law. Count the 2n-round matches in which Ana stays strictly ahead. Reflection turns the count into a telescoping sum, which collapses to half the ways to tie at round 2n. Adding the mirror case, Ben ahead, gives $\binom{2n}{n}$ of the $2^{2n}$ matches never level after the start:

$$P(T > 2n) = u_{2n}.$$

Differences give the first-return chances, $P(T = 2n) = u_{2n-2} - u_{2n}$: 1/2, 1/8, 1/16 and 5/128 for rounds 2, 4, 6 and 8.

The wait for +1 has the same law, one round earlier. The return time is round 1 plus a one-level wait back to 0, which by the mirror has the law of $\tau_1$. So $P(\tau_1 = 2n - 1) = P(T = 2n)$: 1/2, 1/8, 1/16 and 5/128 for rounds 1, 3, 5 and 7. The code confirms both laws on all 65,536 matches of 16 rounds.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Chance the fair score has not yet been level again"
    x-axis "Rounds played, n" [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    y-axis "P(T > n)" 0 --> 1
    line [1.00, 0.25, 0.18, 0.14, 0.13, 0.11, 0.10, 0.10, 0.09, 0.08, 0.08]
```

The line is the chance of no return yet, at every tenth round, to two places. It drops fast, then crawls: 0.25 at round 10, 0.08 at round 100. By [Stirling's approximation](../../06-Calculus%20and%20analysis/06-Series/09-stirlings-approximation.md), $u_{2n}$ is close to one over the square root of π n: at round 1,000, so n = 500, that gives 0.025231 against the true 0.025225.

<details>
<summary>Detailed proof: the reflection count, and the first-return law</summary>

Call a match of 2n rounds **Ana-ahead** if the score is positive on every round 1 to 2n. Such a match wins round 1 and then runs 2n − 1 rounds from +1 without touching 0. Fix its final score 2k, with k from 1 to n. Write $M(j)$ for the number of (2n − 1)-round matches whose net change is j.

Matches from +1 to 2k: $M(2k - 1)$ of them. Those that touch 0: reflect the part before the first touch in the level 0. That swaps them one for one with matches from −1 to 2k, of which there are $M(2k + 1)$ (the reflection principle). So Ana-ahead matches ending at 2k number $M(2k - 1) - M(2k + 1)$.

Sum over k from 1 to n. Each negative term cancels the next positive one, and $M(2n + 1) = 0$, leaving $M(1)$: matches of 2n − 1 rounds with n wins and n − 1 losses, which is $\binom{2n-1}{n}$, half of $\binom{2n}{n}$. Adding the mirror Ben-ahead matches gives $\binom{2n}{n}$ matches never level after the start, and dividing by $2^{2n}$ gives $P(T > 2n) = u_{2n}$.

T is even, so $P(T = 2n) = P(T > 2n - 2) - P(T > 2n) = u_{2n-2} - u_{2n}$. With $u_0$ = 1 and each $u_{2n}$ equal to the one before times (2n − 1)/(2n), this gives 1/2, 1/8, 1/16, 5/128.

</details>

### Step 4: the average wait is infinite, by two roads

**Road one: a floor only shortens the wait.** Reaching +1 or −b, whichever comes first, never takes longer than reaching +1. By [Gambler's ruin](04-gamblers-ruin.md), a fair game starting 1 below the top and b above the floor lasts 1 × b rounds on average. So the average wait for +1 is at least b, for every b, and $E[\tau_1] = \infty$. The return time is one round plus a wait of this kind, so $E[T] = \infty$ too.

The house example is b = 10: a gambler with 10 chips who stops at 0 or 11 reaches 11 with chance 0.909091 and plays 10 rounds on average. Without the floor the wait only grows.

**Road two: add up the chances of still waiting.** A count's average is the sum of the chances that it exceeds 0, 1, 2 and so on (the tail sum of [Expectation](../../09-Probability%20and%20statistics/02-Random%20Variables/02-expectation.md)). Cut the wait off at 2N rounds; T is even, so each $u_{2n}$ appears twice:

$$E[\min(T, 2N)] = 2\sum_{n=0}^{N-1} u_{2n} = 2(2N - 1)\,u_{2N-2} \;\ge\; \sqrt{N}.$$

The capped average grows like the square root of the cap, so the uncapped average is infinite.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Average return time when the wait is cut off at a cap"
    x-axis "Cap on the wait, in rounds" [10, 100, 1000, 10000, 100000]
    y-axis "Capped average wait, in rounds" 0 --> 550
    bar [4.92, 15.92, 50.45, 159.57, 504.63]
```

Each bar is the exact capped average for one cap, to two places. It never settles.

<details>
<summary>Detailed proof: the tail sum, the square-root floor and the closed form</summary>

**Tail sum.** A count X equals the number of k ≥ 0 with k < X; averaging, E[X] is the sum of P(X > k). For min(T, 2N), T even gives P(T > 2n + 1) = P(T > 2n) = $u_{2n}$.

**Square-root floor.** $u_{2n}$ is the product of the factors (2k − 1)/(2k) for k = 1 to n. For k ≥ 2, $(2k-1)^2 = 4k^2 - 4k + 1 > (2k)(2k - 2)$, so (2k − 1)/(2k) exceeds (2k − 2)/(2k − 1).

Write $u_{2n}^2$ as the product times itself. In the second copy keep the factor 1/2 for k = 1 and shrink each later factor to (2k − 2)/(2k − 1). Pairing factor k of the first copy with the shrunk one leaves (2k − 2)/(2k) = (k − 1)/k, and those telescope to 1/n. So $u_{2n}^2 \ge \tfrac12 \cdot \tfrac12 \cdot \tfrac1n$ and $u_{2n} \ge 1/(2\sqrt{n})$.

Then the capped average is at least 2 plus the sum of $1/\sqrt{n}$ for n = 1 to N − 1. That is at least the sum for n = 1 to N, which is at least N times $1/\sqrt{N}$, that is √N.

**Closed form.** By induction, $u_0 + u_2 + \dots + u_{2m} = (2m + 1)\,u_{2m}$: true at m = 0, and adding $u_{2m+2}$ to $(2m + 1)u_{2m} = (2m + 2)u_{2m+2}$ gives $(2m + 3)u_{2m+2}$.

**Road one, in full.** On every match, $\min(\tau_1, \tau_{-b}) \le \tau_1$, allowing the value ∞. Averages of variables that are never negative keep that order (monotonicity of the integral, from [The integral of a non-negative function](../../10-Measure%20and%20integration/04-The%20Lebesgue%20Integral/02-integral-of-a-nonnegative-function.md)), so $E[\tau_1] \ge b$. After round 1 the score is ±1 and the remaining wait is a copy of $\tau_1$ or its mirror, so $E[T] = 1 + E[\tau_1] = \infty$.

</details>

### The other door: generating functions

The classical route packs the first-return chances into one power series in s, the generating function, equal to $1 - \sqrt{1 - s^2}$. At s = 1 it is 1: sure return. Its slope there is infinite: infinite mean. Feller, under Sources, takes this door.

---

## Worked numbers, by hand

Fair coin; cap the wait at 10 rounds, so N = 5.

| Step | Arithmetic | Value |
| --- | --- | --- |
| $u_2$, no tie yet after 2 rounds | 1/2 | 0.5 |
| $u_4$ | 0.5 × 3/4 | 0.375 |
| $u_6$ | 0.375 × 5/6 | 0.3125 |
| $u_8$ | 0.3125 × 7/8 | 0.273438 |
| $u_{10}$, still waiting after 10 rounds | 0.273438 × 9/10 | 0.246094 |
| P(T = 8), level first at round 8 | $u_6 - u_8$ = 0.3125 − 0.273438 | 5/128 |
| capped average, E[min(T, 10)] | 2 × (1 + 0.5 + 0.375 + 0.3125 + 0.273438) | 4.921875 |
| same, closed form | 2 × 9 × $u_8$ | 4.921875 |
| square-root floor, √N | √5 | 2.236068 |
| **house cross-check: 10 chips, stop at 0 or 11** | chance of 11 is 10/11; rounds on average 10 × 1 | **0.909091 and 10 rounds** |

Half of all fair matches are level after 2 rounds, yet about 1 in 4 is still waiting after 10, and the average wait capped at 10 rounds is already 4.92 rounds.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Tilt the coin to p = 0.4 and still expect a sure return | 0.8 chance of ever being level again | fairness is a hypothesis: 1 match in 5 never returns |
| Assume every sure hit has an infinite mean | at p = 0.6 the wait for +1 averages 5 rounds | the tilt towards the target makes the mean finite |
| Treat "sure to return" as a deadline | 0.025225 chance of still waiting after 1,000 rounds | probability 1 bounds nothing; about 1 in 40 matches waits longer |
| Report a capped average as the mean | 50.45 at cap 1,000; 504.63 at cap 100,000 | the capped average tracks the cap, not a fixed number |

---

## Code, from first principles, and it actually runs

Every number on this card is reached by at least two independent roads. Road 1: the formula, built as a product. Road 2: all 65,536 matches of 16 rounds listed, first returns and first passages to +1 counted in exact fractions. Road 3: probability pushed forward round by round for 1,000 rounds, the level absorbing whatever reaches it, checked against the formula at every round. Road 4: first-step equations with a floor, solved by elimination. Road 5: a seeded simulation of 20,000 matches, each cut off at 10,000 rounds, with standard errors, from a SplitMix64 generator written out in both languages.

### Python

```python
# Hitting times of the simple random walk -- the check behind the card.  Standard library only.
# Roads: the formula; every path of 16 rounds enumerated; probability pushed along every path
# round by round; first-step equations solved by elimination; a seeded simulation with its
# standard error.  Nothing imported knows the answer.
from fractions import Fraction
from math import sqrt, pi

M64 = (1 << 64) - 1
class SplitMix64:                                  # the small generator, written out
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def step(self): return 1 if self.next() >> 63 else -1   # top bit: +1 or -1, each half the time

def u(two_n, x=1.0):                               # formula: P(S_2n = 0) = C(2n, n) / 2^(2n), as a product
    for k in range(1, two_n // 2 + 1): x = x * (2 * k - 1) / (2 * k)
    return x

def first_step(lo, hi, p, start, top, bottom, cost):
    # h_k = cost + p h_(k+1) + (1 - p) h_(k-1) for lo < k < hi, h_lo = bottom, h_hi = top.
    q, n = 1.0 - p, hi - lo - 1
    b, c, d = [1.0] * n, [-p] * n, [cost] * n
    d[0] += q * bottom; d[-1] += p * top
    for i in range(1, n):                          # eliminate downwards
        m = -q / b[i - 1]; b[i] -= m * c[i - 1]; d[i] -= m * d[i - 1]
    h = [0.0] * n; h[-1] = d[-1] / b[-1]
    for i in range(n - 2, -1, -1): h[i] = (d[i] - c[i] * h[i + 1]) / b[i]
    return h[start - lo - 1]

def row(name, *vals): print(f"{name:<40}" + "".join(f"{v:>12.6f}" for v in vals))
def row_eq(name, got, want): row(name, got, want); assert abs(got - want) < 1e-9, name

# ---- road 2: every one of the 2^16 paths of 16 rounds, first return to level recorded ----
L = 16
first, hit1, never = [0] * (L + 1), [0] * (L + 1), 0
for w in range(1 << L):
    s, back, up = 0, 0, 0
    for i in range(L):
        s += 1 if (w >> i) & 1 else -1
        if s == 0 and not back: first[i + 1] += 1; back = 1
        if s == 1 and not up: hit1[i + 1] += 1; up = 1
    never += not back
print(f"{'first return T, all 65536 paths of 16':<40}{'enumerated':>12}{'formula':>12}")
for t in (2, 4, 6, 8):
    e, f = Fraction(first[t], 1 << L), u(t - 2, Fraction(1)) - u(t, Fraction(1))
    print(f"{'  P(T = ' + str(t) + ')':<40}{str(e):>12}{str(f):>12}")
    assert e == f, "enumerated first-return law vs u(2n-2) - u(2n)"
e16 = Fraction(never, 1 << L)
print(f"{'  P(T > 16)':<40}{str(e16):>12}{str(u(16, Fraction(1))):>12}")
assert e16 == u(16, Fraction(1)), "no return in 16 rounds vs P(S_16 = 0)"
for t in (1, 3, 5, 7):                             # first passage to +1 at round t = 2n - 1 has P(T = 2n)
    e, f = Fraction(hit1[t], 1 << L), u(t - 1, Fraction(1)) - u(t + 1, Fraction(1))
    print(f"{'  P(tau_1 = ' + str(t) + ')':<40}{str(e):>12}{str(f):>12}")
    assert e == f, "enumerated first passage to +1 vs P(T = t + 1)"

# ---- road 3: push probability along every path, level absorbs; survival to 1000 rounds ----
N = 1000
dist = {0: 1.0}; surv = [1.0]
for k in range(1, N + 1):
    new = {}
    for x, pr in dist.items():
        for y in (x - 1, x + 1):
            if y != 0: new[y] = new.get(y, 0.0) + pr / 2
    dist = new; surv.append(sum(dist.values()))
print(f"{'still waiting, P(T > n)':<40}{'pushed':>12}{'formula':>12}")
for n in range(N + 1):                             # every n checked; a few printed
    if n in (0, 2, 4, 6, 8, 10, 20, 40, 60, 80, 100, 1000): row(f"  n = {n}", surv[n], u(n))
    assert abs(surv[n] - u(n)) < 1e-12, "pushed survival vs C(n, n/2) / 2^n"
row("  1 / sqrt(pi * 500), estimate at 1000", 1 / sqrt(pi * 500))
print("chart, P(T > n), n = 0 to 100 by 10:", " ".join(f"{surv[n]:.2f}" for n in range(0, 101, 10)))

# ---- the mean: capped averages E[min(T, cap)] grow without limit ----
print(f"{'capped mean E[min(T, cap)]':<40}{'tail sum':>12}{'closed':>12}{'sqrt(cap/2)':>12}")
run, tail, capped = 1.0, 0.0, {}
for n in range(0, 50000):                          # tail sum: E[min(T, 2N)] = 2 * sum of u(2n), n < N
    tail += 2 * run
    if 2 * (n + 1) in (10, 100, 1000, 10000, 100000):
        cap = 2 * (n + 1); capped[cap] = tail
        row(f"  cap = {cap}", tail, 2 * (cap - 1) * u(cap - 2), sqrt(cap / 2))
        assert abs(tail - 2 * (cap - 1) * u(cap - 2)) < 1e-9 * cap, "tail sum vs closed form"
        assert tail >= sqrt(cap / 2), "capped mean at least sqrt(cap/2), from u(2n) >= 1/(2 sqrt n)"
    run *= (2 * n + 1) / (2 * n + 2)
print("chart, capped mean, caps 10 to 100000:", " ".join(f"{capped[c]:.2f}" for c in sorted(capped)))
assert abs(sum(surv[:1000]) - capped[1000]) < 1e-9, "pushed survival summed vs formula tail sum"

# ---- road 4: first-step equations with a floor at -b; the wait for +1 is at least b ----
print(f"{'first-step equations':<40}{'solved':>12}{'formula':>12}")
row_eq("  10 chips, stop at 0 or 11: P(reach 11)", first_step(-10, 1, 0.5, 0, 1.0, 0.0, 0.0), 10 / 11)
for b in (10, 100, 1000):
    m = first_step(-b, 1, 0.5, 0, 0.0, 0.0, 1.0)
    row(f"  fair, mean rounds to +1 or -{b}", m, b * 1.0)
    assert abs(m - b) < 1e-6 * b, "first-step duration vs b * 1 from gambler's ruin"
for b in (10, 100, 1000):
    row_eq(f"  fair, P(level again before +-{b})", first_step(0, b, 0.5, 1, 0.0, 1.0, 0.0), 1 - 1 / b)
for p in (0.4, 0.6):
    q = 1 - p
    up = first_step(-400, 1, p, 0, 1.0, 0.0, 0.0)
    back = p * first_step(0, 400, p, 1, 0.0, 1.0, 0.0) + q * first_step(-400, 0, p, -1, 1.0, 0.0, 0.0)
    row_eq(f"  p = {p}: P(ever reach +1)", up, min(1.0, p / q))
    row_eq(f"  p = {p}: P(ever level again)", back, 1 - abs(p - q))
row_eq("  p = 0.4: P(ever reach +3)", first_step(-400, 3, 0.4, 0, 1.0, 0.0, 0.0), (0.4 / 0.6) ** 3)
row_eq("  p = 0.6: mean rounds to reach +1", first_step(-400, 1, 0.6, 0, 0.0, 0.0, 1.0), 1 / (0.6 - 0.4))

# ---- road 5: seeded simulation, 20000 matches, each capped at 10000 rounds ----
rng, NS, CAP = SplitMix64(20260929), 20000, 10000
t2 = over100 = 0; tot = tot2 = 0.0
for _ in range(NS):
    s, t = rng.step(), 1
    while s != 0 and t < CAP: s += rng.step(); t += 1
    t2 += t == 2; over100 += t > 100; tot += t; tot2 += t * t
mean = tot / NS; se = sqrt((tot2 / NS - mean * mean) / NS)
for name, k, f in (("P(T = 2)", t2, 0.5), ("P(T > 100)", over100, u(100))):
    ph = k / NS; sep = sqrt(ph * (1 - ph) / NS)
    print(f"sim {name:<36}{ph:>12.6f} +- {sep:.6f}  formula {f:.6f}")
    assert abs(ph - f) < 4 * sep, "simulated chance within 4 standard errors"
print(f"sim E[min(T, 10000)]{'':<20}{mean:>12.6f} +- {se:.6f}  formula {capped[10000]:.6f}")
assert abs(mean - capped[10000]) < 4 * se, "simulated capped mean within 4 standard errors"

# ---- the picture: one sample match, seed 7, the first whose return comes in rounds 10 to 24 ----
g = SplitMix64(7)
while True:
    path = [0]
    while len(path) < 25 and (len(path) == 1 or path[-1] != 0): path.append(path[-1] + g.step())
    if path[-1] == 0 and len(path) >= 11: break
print("figure, T =", len(path) - 1, "scores:", " ".join(str(x) for x in path))
print("figure, svg points:", " ".join(f"{30 + 18 * i},{50 - 20 * x}" for i, x in enumerate(path)))
print("ALL CHECKS PASS")
```

**Ran 2026-09-30 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
first return T, all 65536 paths of 16     enumerated     formula
  P(T = 2)                                       1/2         1/2
  P(T = 4)                                       1/8         1/8
  P(T = 6)                                      1/16        1/16
  P(T = 8)                                     5/128       5/128
  P(T > 16)                               6435/32768  6435/32768
  P(tau_1 = 1)                                   1/2         1/2
  P(tau_1 = 3)                                   1/8         1/8
  P(tau_1 = 5)                                  1/16        1/16
  P(tau_1 = 7)                                 5/128       5/128
still waiting, P(T > n)                       pushed     formula
  n = 0                                     1.000000    1.000000
  n = 2                                     0.500000    0.500000
  n = 4                                     0.375000    0.375000
  n = 6                                     0.312500    0.312500
  n = 8                                     0.273438    0.273438
  n = 10                                    0.246094    0.246094
  n = 20                                    0.176197    0.176197
  n = 40                                    0.125371    0.125371
  n = 60                                    0.102578    0.102578
  n = 80                                    0.088928    0.088928
  n = 100                                   0.079589    0.079589
  n = 1000                                  0.025225    0.025225
  1 / sqrt(pi * 500), estimate at 1000      0.025231
chart, P(T > n), n = 0 to 100 by 10: 1.00 0.25 0.18 0.14 0.13 0.11 0.10 0.10 0.09 0.08 0.08
capped mean E[min(T, cap)]                  tail sum      closed sqrt(cap/2)
  cap = 10                                  4.921875    4.921875    2.236068
  cap = 100                                15.917847   15.917847    7.071068
  cap = 1000                               50.450036   50.450036   22.360680
  cap = 10000                             159.572923  159.572923   70.710678
  cap = 100000                            504.625243  504.625243  223.606798
chart, capped mean, caps 10 to 100000: 4.92 15.92 50.45 159.57 504.63
first-step equations                          solved     formula
  10 chips, stop at 0 or 11: P(reach 11)    0.909091    0.909091
  fair, mean rounds to +1 or -10           10.000000   10.000000
  fair, mean rounds to +1 or -100         100.000000  100.000000
  fair, mean rounds to +1 or -1000       1000.000000 1000.000000
  fair, P(level again before +-10)          0.900000    0.900000
  fair, P(level again before +-100)         0.990000    0.990000
  fair, P(level again before +-1000)        0.999000    0.999000
  p = 0.4: P(ever reach +1)                 0.666667    0.666667
  p = 0.4: P(ever level again)              0.800000    0.800000
  p = 0.6: P(ever reach +1)                 1.000000    1.000000
  p = 0.6: P(ever level again)              0.800000    0.800000
  p = 0.4: P(ever reach +3)                 0.296296    0.296296
  p = 0.6: mean rounds to reach +1          5.000000    5.000000
sim P(T = 2)                                0.492700 +- 0.003535  formula 0.500000
sim P(T > 100)                              0.078500 +- 0.001902  formula 0.079589
sim E[min(T, 10000)]                      161.691900 +- 7.373439  formula 159.572923
figure, T = 16 scores: 0 -1 -2 -3 -4 -5 -6 -7 -6 -5 -4 -3 -2 -1 -2 -1 0
figure, svg points: 30,50 48,70 66,90 84,110 102,130 120,150 138,170 156,190 174,170 192,150 210,130 228,110 246,90 264,70 282,90 300,70 318,50
ALL CHECKS PASS
```

### Rust

```rust
// Hitting times of the simple random walk -- the same check as first_passage_and_hitting_times_check.py.
// Std only, no crates.  Roads: the formula; every path of 16 rounds enumerated; probability pushed
// along every path round by round; first-step equations solved by elimination; a seeded simulation
// with its standard error.  Exact fractions are kept as u128 numerator over a power of 4.
// Compile: rustc --edition 2021 -O first_passage_and_hitting_times_check.rs -o /tmp/<dir>/chk
use std::f64::consts::PI;

struct SplitMix64 { s: u64 }                       // the small generator, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn step(&mut self) -> i64 { if self.next() >> 63 == 1 { 1 } else { -1 } }
}

fn u(two_n: usize) -> f64 {                        // formula: P(S_2n = 0) = C(2n, n) / 2^(2n), as a product
    let mut x = 1.0;
    for k in 1..=two_n / 2 { x = x * (2 * k - 1) as f64 / (2 * k) as f64; }
    x
}
fn central(two_n: u128) -> u128 {                  // C(2n, n) exactly
    let mut c: u128 = 1;
    for k in 0..two_n / 2 { c = c * (two_n - k) / (k + 1); }
    c
}
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn frac(num: u128, den: u128) -> String { let g = gcd(num, den); format!("{}/{}", num / g, den / g) }

fn first_step(lo: i64, hi: i64, p: f64, start: i64, top: f64, bottom: f64, cost: f64) -> f64 {
    // h_k = cost + p h_(k+1) + (1 - p) h_(k-1) for lo < k < hi, h_lo = bottom, h_hi = top.
    let (q, n) = (1.0 - p, (hi - lo - 1) as usize);
    let (mut b, c, mut d) = (vec![1.0; n], vec![-p; n], vec![cost; n]);
    d[0] += q * bottom; d[n - 1] += p * top;
    for i in 1..n {                                // eliminate downwards
        let m = -q / b[i - 1]; b[i] -= m * c[i - 1]; d[i] -= m * d[i - 1];
    }
    let mut h = vec![0.0; n]; h[n - 1] = d[n - 1] / b[n - 1];   // then substitute back upwards
    for i in (0..n - 1).rev() { h[i] = (d[i] - c[i] * h[i + 1]) / b[i]; }
    h[(start - lo - 1) as usize]
}

fn row(name: &str, vals: &[f64]) { println!("{:<40}{}", name, vals.iter().map(|v| format!("{:>12.6}", v)).collect::<String>()); }
fn row_eq(name: &str, got: f64, want: f64) { row(name, &[got, want]); assert!((got - want).abs() < 1e-9, "{}", name); }

fn main() {
    // ---- road 2: every one of the 2^16 paths of 16 rounds, first return to level recorded ----
    const L: usize = 16;
    let (mut first, mut hit1, mut never) = ([0u128; L + 1], [0u128; L + 1], 0u128);
    for w in 0u32..(1 << L) {
        let (mut s, mut back, mut up) = (0i64, false, false);
        for i in 0..L {
            s += if (w >> i) & 1 == 1 { 1 } else { -1 };
            if s == 0 && !back { first[i + 1] += 1; back = true; }
            if s == 1 && !up { hit1[i + 1] += 1; up = true; }
        }
        if !back { never += 1; }
    }
    println!("{:<40}{:>12}{:>12}", "first return T, all 65536 paths of 16", "enumerated", "formula");
    for t in [2u128, 4, 6, 8] {
        let den = 1u128 << t;                      // u(t-2) - u(t) over the common denominator 2^t
        let f_num = 4 * central(t - 2) - central(t);
        println!("{:<40}{:>12}{:>12}", format!("  P(T = {})", t), frac(first[t as usize], 1 << L), frac(f_num, den));
        assert!(first[t as usize] * den == f_num * (1u128 << L), "enumerated first-return law vs u(2n-2) - u(2n)");
    }
    println!("{:<40}{:>12}{:>12}", "  P(T > 16)", frac(never, 1 << L), frac(central(16), 1 << 16));
    assert!(never == central(16), "no return in 16 rounds vs P(S_16 = 0)");
    for t in [1u128, 3, 5, 7] {                    // first passage to +1 at round t = 2n - 1 has P(T = 2n)
        let (den, f_num) = (1u128 << (t + 1), 4 * central(t - 1) - central(t + 1));
        println!("{:<40}{:>12}{:>12}", format!("  P(tau_1 = {})", t), frac(hit1[t as usize], 1 << L), frac(f_num, den));
        assert!(hit1[t as usize] * den == f_num * (1u128 << L), "enumerated first passage to +1 vs P(T = t + 1)");
    }

    // ---- road 3: push probability along every path, level absorbs; survival to 1000 rounds ----
    const N: usize = 1000;
    let off = N + 1;
    let (mut dist, mut surv) = (vec![0.0f64; 2 * off + 1], vec![1.0f64]); dist[off] = 1.0;
    for _ in 1..=N {
        let mut new = vec![0.0f64; dist.len()];
        for i in 1..dist.len() - 1 {
            if dist[i] != 0.0 { new[i - 1] += dist[i] / 2.0; new[i + 1] += dist[i] / 2.0; }
        }
        new[off] = 0.0; surv.push(new.iter().sum()); dist = new;
    }
    println!("{:<40}{:>12}{:>12}", "still waiting, P(T > n)", "pushed", "formula");
    for n in 0..=N {                               // every n checked; a few printed
        if [0, 2, 4, 6, 8, 10, 20, 40, 60, 80, 100, 1000].contains(&n) { row(&format!("  n = {}", n), &[surv[n], u(n)]); }
        assert!((surv[n] - u(n)).abs() < 1e-12, "pushed survival vs C(n, n/2) / 2^n");
    }
    row("  1 / sqrt(pi * 500), estimate at 1000", &[1.0 / (PI * 500.0).sqrt()]);
    let pts: Vec<String> = (0..=100).step_by(10).map(|n| format!("{:.2}", surv[n])).collect();
    println!("chart, P(T > n), n = 0 to 100 by 10: {}", pts.join(" "));

    // ---- the mean: capped averages E[min(T, cap)] grow without limit ----
    println!("{:<40}{:>12}{:>12}{:>12}", "capped mean E[min(T, cap)]", "tail sum", "closed", "sqrt(cap/2)");
    let (mut run, mut tail) = (1.0f64, 0.0f64);
    let mut capped: Vec<f64> = Vec::new();
    for n in 0..50000usize {                       // tail sum: E[min(T, 2N)] = 2 * sum of u(2n), n < N
        tail += 2.0 * run;
        let cap = 2 * (n + 1);
        if [10, 100, 1000, 10000, 100000].contains(&cap) {
            let closed = 2.0 * (cap - 1) as f64 * u(cap - 2);
            row(&format!("  cap = {}", cap), &[tail, closed, (cap as f64 / 2.0).sqrt()]);
            assert!((tail - closed).abs() < 1e-9 * cap as f64, "tail sum vs closed form");
            assert!(tail >= (cap as f64 / 2.0).sqrt(), "capped mean at least sqrt(cap/2)");
            capped.push(tail);
        }
        run *= (2 * n + 1) as f64 / (2 * n + 2) as f64;
    }
    let pts: Vec<String> = capped.iter().map(|c| format!("{:.2}", c)).collect();
    println!("chart, capped mean, caps 10 to 100000: {}", pts.join(" "));
    assert!((surv[..1000].iter().sum::<f64>() - capped[2]).abs() < 1e-9, "pushed survival summed vs formula tail sum");

    // ---- road 4: first-step equations with a floor at -b; the wait for +1 is at least b ----
    println!("{:<40}{:>12}{:>12}", "first-step equations", "solved", "formula");
    row_eq("  10 chips, stop at 0 or 11: P(reach 11)", first_step(-10, 1, 0.5, 0, 1.0, 0.0, 0.0), 10.0 / 11.0);
    for b in [10i64, 100, 1000] {
        let m = first_step(-b, 1, 0.5, 0, 0.0, 0.0, 1.0);
        row(&format!("  fair, mean rounds to +1 or -{}", b), &[m, b as f64]);
        assert!((m - b as f64).abs() < 1e-6 * b as f64, "first-step duration vs b * 1 from gambler's ruin");
    }
    for b in [10i64, 100, 1000] {
        row_eq(&format!("  fair, P(level again before +-{})", b), first_step(0, b, 0.5, 1, 0.0, 1.0, 0.0), 1.0 - 1.0 / b as f64);
    }
    for p in [0.4f64, 0.6] {
        let q = 1.0 - p;
        let up = first_step(-400, 1, p, 0, 1.0, 0.0, 0.0);
        let back = p * first_step(0, 400, p, 1, 0.0, 1.0, 0.0) + q * first_step(-400, 0, p, -1, 1.0, 0.0, 0.0);
        row_eq(&format!("  p = {}: P(ever reach +1)", p), up, (p / q).min(1.0));
        row_eq(&format!("  p = {}: P(ever level again)", p), back, 1.0 - (p - q).abs());
    }
    row_eq("  p = 0.4: P(ever reach +3)", first_step(-400, 3, 0.4, 0, 1.0, 0.0, 0.0), (0.4f64 / 0.6).powi(3));
    row_eq("  p = 0.6: mean rounds to reach +1", first_step(-400, 1, 0.6, 0, 0.0, 0.0, 1.0), 1.0 / (0.6 - 0.4));

    // ---- road 5: seeded simulation, 20000 matches, each capped at 10000 rounds ----
    let (mut rng, ns, cap) = (SplitMix64 { s: 20260929 }, 20000usize, 10000u64);
    let (mut t2, mut over100, mut tot, mut tot2) = (0usize, 0usize, 0.0f64, 0.0f64);
    for _ in 0..ns {
        let (mut s, mut t) = (rng.step(), 1u64);
        while s != 0 && t < cap { s += rng.step(); t += 1; }
        if t == 2 { t2 += 1; } else if t > 100 { over100 += 1; }
        tot += t as f64; tot2 += (t * t) as f64;
    }
    let nsf = ns as f64; let mean = tot / nsf; let se = ((tot2 / nsf - mean * mean) / nsf).sqrt();
    for (name, k, f) in [("P(T = 2)", t2, 0.5), ("P(T > 100)", over100, u(100))] {
        let ph = k as f64 / nsf; let sep = (ph * (1.0 - ph) / nsf).sqrt();
        println!("sim {:<36}{:>12.6} +- {:.6}  formula {:.6}", name, ph, sep, f);
        assert!((ph - f).abs() < 4.0 * sep, "simulated chance within 4 standard errors");
    }
    println!("sim E[min(T, 10000)]{:<20}{:>12.6} +- {:.6}  formula {:.6}", "", mean, se, capped[3]);
    assert!((mean - capped[3]).abs() < 4.0 * se, "simulated capped mean within 4 standard errors");

    // ---- the picture: one sample match, seed 7, the first whose return comes in rounds 10 to 24 ----
    let mut g = SplitMix64 { s: 7 };
    let path = loop {
        let mut path = vec![0i64];
        while path.len() < 25 && (path.len() == 1 || *path.last().unwrap() != 0) {
            let next = path.last().unwrap() + g.step(); path.push(next);
        }
        if *path.last().unwrap() == 0 && path.len() >= 11 { break path; }
    };
    println!("figure, T = {} scores: {}", path.len() - 1, path.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" "));
    let pts: Vec<String> = path.iter().enumerate().map(|(i, x)| format!("{},{}", 30 + 18 * i as i64, 50 - 20 * x)).collect();
    println!("figure, svg points: {}", pts.join(" "));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-30 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
first return T, all 65536 paths of 16     enumerated     formula
  P(T = 2)                                       1/2         1/2
  P(T = 4)                                       1/8         1/8
  P(T = 6)                                      1/16        1/16
  P(T = 8)                                     5/128       5/128
  P(T > 16)                               6435/32768  6435/32768
  P(tau_1 = 1)                                   1/2         1/2
  P(tau_1 = 3)                                   1/8         1/8
  P(tau_1 = 5)                                  1/16        1/16
  P(tau_1 = 7)                                 5/128       5/128
still waiting, P(T > n)                       pushed     formula
  n = 0                                     1.000000    1.000000
  n = 2                                     0.500000    0.500000
  n = 4                                     0.375000    0.375000
  n = 6                                     0.312500    0.312500
  n = 8                                     0.273438    0.273438
  n = 10                                    0.246094    0.246094
  n = 20                                    0.176197    0.176197
  n = 40                                    0.125371    0.125371
  n = 60                                    0.102578    0.102578
  n = 80                                    0.088928    0.088928
  n = 100                                   0.079589    0.079589
  n = 1000                                  0.025225    0.025225
  1 / sqrt(pi * 500), estimate at 1000      0.025231
chart, P(T > n), n = 0 to 100 by 10: 1.00 0.25 0.18 0.14 0.13 0.11 0.10 0.10 0.09 0.08 0.08
capped mean E[min(T, cap)]                  tail sum      closed sqrt(cap/2)
  cap = 10                                  4.921875    4.921875    2.236068
  cap = 100                                15.917847   15.917847    7.071068
  cap = 1000                               50.450036   50.450036   22.360680
  cap = 10000                             159.572923  159.572923   70.710678
  cap = 100000                            504.625243  504.625243  223.606798
chart, capped mean, caps 10 to 100000: 4.92 15.92 50.45 159.57 504.63
first-step equations                          solved     formula
  10 chips, stop at 0 or 11: P(reach 11)    0.909091    0.909091
  fair, mean rounds to +1 or -10           10.000000   10.000000
  fair, mean rounds to +1 or -100         100.000000  100.000000
  fair, mean rounds to +1 or -1000       1000.000000 1000.000000
  fair, P(level again before +-10)          0.900000    0.900000
  fair, P(level again before +-100)         0.990000    0.990000
  fair, P(level again before +-1000)        0.999000    0.999000
  p = 0.4: P(ever reach +1)                 0.666667    0.666667
  p = 0.4: P(ever level again)              0.800000    0.800000
  p = 0.6: P(ever reach +1)                 1.000000    1.000000
  p = 0.6: P(ever level again)              0.800000    0.800000
  p = 0.4: P(ever reach +3)                 0.296296    0.296296
  p = 0.6: mean rounds to reach +1          5.000000    5.000000
sim P(T = 2)                                0.492700 +- 0.003535  formula 0.500000
sim P(T > 100)                              0.078500 +- 0.001902  formula 0.079589
sim E[min(T, 10000)]                      161.691900 +- 7.373439  formula 159.572923
figure, T = 16 scores: 0 -1 -2 -3 -4 -5 -6 -7 -6 -5 -4 -3 -2 -1 -2 -1 0
figure, svg points: 30,50 48,70 66,90 84,110 102,130 120,150 138,170 156,190 174,170 192,150 210,130 228,110 246,90 264,70 282,90 300,70 318,50
ALL CHECKS PASS
```

The two outputs agree line for line. The simulation lands within about two standard errors of the formula: 0.492700 against 0.5, 0.078500 against 0.079589, and 161.691900 ± 7.373439 against 159.572923.

### Lean

Lean proves the arrival chances, the infinite fair mean and the reflection count, for independent rounds with steps of one dollar.

- Take a fair coin, independent rounds, and any level $a$: above, below or at the start. Then $P(\tau_a < \infty) = 1$ and $E[\tau_a] = \infty$.
- Take independent rounds, up one dollar with chance $p$ and down with chance $q$, and a target $a$ of 1 or more. Then $P(\tau_a < \infty)$ is 1 when $p \ge 1/2$, and $(p/q)^a$ when $p < 1/2$.
- Take the same rounds, with any $p$. Then $P(T < \infty) = 1 - \lvert p - q \rvert$.
- Take the $2^{2n}$ fair matches of 2n rounds. Then exactly $\binom{2n}{n}$ of them are never level after the start: the count behind $P(T > 2n) = u_{2n}$.
- The small counts hold: 2 of the 4 matches of 2 rounds, 6 of 16 for 4 rounds, and 70 of 256 for 8 rounds.
- The worked numbers hold: $u_2$ to $u_{10}$, and the capped average 4.921875 at cap 10.
- The first-return chances 1/2, 1/8, 1/16 and 5/128 hold, and so does 6435/32768 for no return in 16 rounds.
- At p = 0.4 the chances 2/3 of climbing one level, 8/27 of reaching +3, and 4/5 of coming back hold.
- The pictured match falls to −7 at round 7, and is first level again at round 16.

The square-root rate, the capped averages beyond cap 10, the floors and the simulation are left to the Python and Rust checks.

```lean
-- Hitting times: a fair walk with steps of one reaches every level, its start included, with probability 1 but after an infinite average wait; a tilted walk reaches a level a above with chance 1 or (p/q)^a and returns with chance 1 − |p − q|; and C(2n, n) of the 2^(2n) fair matches of 2n rounds are never level after the start.
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Analysis.PSeries
import Mathlib.Data.Nat.Choose.Central

open MeasureTheory ProbabilityTheory Finset
open scoped ENNReal

/-! The endless match. On a probability space, `X i` is the step of round `i + 1`: +1 when Ana
wins it, −1 when Ben does. The score after `n` rounds is the sum of the first `n` steps. -/

/-- The score `S n` after `n` rounds: the sum of the first `n` steps, so `S 0 = 0`. -/
def walkScore {Ω : Type*} (X : ℕ → Ω → ℤ) (n : ℕ) (ω : Ω) : ℤ :=
  ∑ i ∈ range n, X i ω

/-- The hitting time `τ_a`: the first round `n ≥ 1` on which the score equals `a`, counted in
`ℝ≥0∞` so that it is `∞` when the score never gets there. The return time is `T = τ_0`. -/
noncomputable def hitTime {Ω : Type*} (X : ℕ → Ω → ℤ) (a : ℤ) (ω : Ω) : ℝ≥0∞ :=
  ⨅ (n : ℕ) (_ : 1 ≤ n ∧ walkScore X n ω = a), (n : ℝ≥0∞)

/-- A copy of `fpScore` (defined further down) for the helper lemmas: the score after the
first `k` rounds of a match of `m` rounds. -/
def fpScore {m : ℕ} (ω : Fin m → Bool) (k : ℕ) : ℤ :=
  ∑ i : Fin m, if (i : ℕ) < k then (if ω i then 1 else -1) else 0

/-- A match of `n` rounds whose score is never `a` on rounds 1 to `n`. -/
def fpAvoids {n : ℕ} (a : ℤ) (x : Fin n → Bool) : Prop := ∀ k ∈ Icc 1 n, fpScore x k ≠ a

instance {n : ℕ} (a : ℤ) : DecidablePred (@fpAvoids n a) := fun x =>
  inferInstanceAs (Decidable (∀ k ∈ Icc 1 n, fpScore x k ≠ a))

def fpSg (c : Bool) : ℤ := if c then 1 else -1

lemma fp_sum_split {M : Type*} [AddCommMonoid M] {n : ℕ} (F : (Fin (n+1) → Bool) → M) :
    ∑ x, F x = ∑ y : Fin n → Bool, F (Fin.cons true y) +
      ∑ y : Fin n → Bool, F (Fin.cons false y) := by
  rw [← (Fin.consEquiv fun _ => Bool).sum_comp, Fintype.sum_prod_type, Fintype.sum_bool]
  rfl

lemma fp_ms_zero {m : ℕ} (x : Fin m → Bool) : fpScore x 0 = 0 := by
  simp [fpScore]

lemma fp_ms_cons {m : ℕ} (c : Bool) (y : Fin m → Bool) (k : ℕ) :
    fpScore (Fin.cons c y : Fin (m+1) → Bool) (k+1) = fpSg c + fpScore y k := by
  simp [fpScore, Fin.sum_univ_succ, fpSg]

lemma fp_ms_not {m : ℕ} (x : Fin m → Bool) (k : ℕ) :
    fpScore (fun i => !x i) k = - fpScore x k := by
  simp only [fpScore, ← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  by_cases h : x i = true <;> simp [h] <;> split_ifs <;> simp

lemma fp_forall_le_succ {P : ℕ → Prop} {m : ℕ} :
    (∀ k ≤ m + 1, P k) ↔ P 0 ∧ ∀ j ≤ m, P (j + 1) :=
  ⟨fun h => ⟨h 0 (by omega), fun j hj => h _ (by omega)⟩, fun ⟨h0, h⟩ k hk => by
    cases k with
    | zero => exact h0
    | succ j => exact h j (by omega)⟩

lemma fp_sum_not {M : Type*} [AddCommMonoid M] {n : ℕ} (F : (Fin n → Bool) → M) :
    ∑ x, F x = ∑ x : Fin n → Bool, F (fun i => !x i) := by
  have hinv : Function.Involutive (fun (x : Fin n → Bool) (i : Fin n) => !x i) := by
    intro x; funext i; simp
  exact Fintype.sum_bijective _ hinv.bijective F (fun x : Fin n → Bool => F (fun i => !x i))
    (fun x => by simp)

open Classical in
/-- Count of matches of `m` rounds whose score, shifted up by `h`, never goes below 0. -/
noncomputable def fpN (m : ℕ) (h : ℤ) : ℕ :=
  ∑ x : Fin m → Bool, if (∀ k ≤ m, 0 ≤ h + fpScore x k) then 1 else 0

open Classical in
/-- Count of matches of `m` rounds whose final score lies in `[lo, hi]`. -/
noncomputable def fpM (m : ℕ) (lo hi : ℤ) : ℕ :=
  ∑ x : Fin m → Bool, if lo ≤ fpScore x m ∧ fpScore x m ≤ hi then 1 else 0

lemma fp_cons_exists {m : ℕ} (x : Fin (m+1) → Bool) :
    ∃ c y, x = (Fin.cons c y : Fin (m+1) → Bool) :=
  ⟨x 0, Fin.tail x, (Fin.cons_self_tail x).symm⟩

lemma fp_ms_bounds (m : ℕ) (x : Fin m → Bool) :
    -(m : ℤ) ≤ fpScore x m ∧ fpScore x m ≤ m ∧ (fpScore x m + m) % 2 = 0 := by
  induction m with
  | zero => simp [fpScore]
  | succ m ih =>
    obtain ⟨c, y, rfl⟩ := fp_cons_exists x
    rw [fp_ms_cons]
    have := ih y
    cases c <;> simp [fpSg] <;> omega

lemma fpM_succ (m : ℕ) (lo hi : ℤ) :
    fpM (m+1) lo hi = fpM m (lo - 1) (hi - 1) + fpM m (lo + 1) (hi + 1) := by
  unfold fpM
  rw [fp_sum_split]
  simp only [fp_ms_cons, fpSg]
  congr 1 <;> refine Finset.sum_congr rfl fun y _ => ?_ <;> simp only [Bool.false_eq_true,
    ite_true, ite_false] <;> split_ifs <;> omega

lemma fpM_split (m : ℕ) (lo c hi : ℤ) (h1 : lo ≤ c + 1) (h2 : c ≤ hi) :
    fpM m lo hi = fpM m lo c + fpM m (c + 1) hi := by
  unfold fpM
  rw [← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun y _ => ?_
  split_ifs <;> omega

lemma fpM_zero_of (m : ℕ) (lo hi : ℤ) (h : ∀ x : Fin m → Bool,
    ¬ (lo ≤ fpScore x m ∧ fpScore x m ≤ hi)) : fpM m lo hi = 0 := by
  unfold fpM
  exact Finset.sum_eq_zero fun x _ => if_neg (h x)

lemma fpN_succ (m : ℕ) (h : ℤ) :
    fpN (m+1) h = if 0 ≤ h then fpN m (h + 1) + fpN m (h - 1) else 0 := by
  unfold fpN
  rw [fp_sum_split]
  simp only [fp_forall_le_succ, fp_ms_zero, fp_ms_cons, fpSg, add_zero, Bool.false_eq_true,
    ite_true, ite_false]
  by_cases h0 : 0 ≤ h
  · simp only [h0, true_and, ite_true]
    congr 1 <;> refine Finset.sum_congr rfl fun y _ => ?_ <;> congr 1 <;>
      refine propext (forall_congr' fun j => imp_congr_right fun _ => ?_) <;> constructor <;>
      intro <;> omega
  · simp [h0]

lemma fpN_eq_fpM (m : ℕ) (h : ℤ) (hh : -1 ≤ h) : fpN m h = fpM m (-h) (h + 1) := by
  induction m generalizing h with
  | zero =>
    unfold fpN fpM
    simp only [Finset.univ_unique, Finset.sum_singleton]
    simp only [fpScore, Finset.univ_eq_empty, Finset.sum_empty]
    split_ifs with h1 h2 h2 <;> first | rfl | (exfalso; simp at h1; omega)
  | succ m ih =>
    rw [fpN_succ]
    split_ifs with h0
    · rw [ih (h+1) (by omega), ih (h-1) (by omega), fpM_succ,
        fpM_split m (-(h+1)) h (h+1+1) (by omega) (by omega),
        fpM_split m (-h + 1) h (h + 1 + 1) (by omega) (by omega)]
      have e1 : -(h - 1) = -h + 1 := by ring
      have e2 : h - 1 + 1 = h := by ring
      have e3 : -h - 1 = -(h+1) := by ring
      have e4 : h + 1 - 1 = h := by ring
      rw [e1, e2, e3, e4]
      omega
    · symm
      apply fpM_zero_of
      intro x; omega

lemma fpM_binom (m k : ℕ) (j : ℤ) (hj : j = 2 * (k : ℤ) - m) : fpM m j j = m.choose k := by
  induction m generalizing k j with
  | zero =>
    unfold fpM
    simp only [Finset.univ_unique, Finset.sum_singleton, fpScore, Finset.univ_eq_empty,
      Finset.sum_empty]
    cases k with
    | zero => simp at hj; simp [hj]
    | succ k => simp at hj; rw [if_neg (by omega)]; simp
  | succ m ih =>
    rw [fpM_succ]
    cases k with
    | zero =>
      rw [fpM_zero_of m (j - 1) (j - 1) (fun x => by have := fp_ms_bounds m x; push_cast at hj; omega),
        ih 0 (j + 1) (by push_cast at hj ⊢; omega)]
      simp
    | succ k =>
      rw [ih k (j - 1) (by push_cast at hj ⊢; omega), ih (k + 1) (j + 1) (by push_cast at hj ⊢; omega),
        Nat.choose_succ_succ]

lemma fpM_odd (m : ℕ) (j : ℤ) (hj : (j + m) % 2 = 1) : fpM m j j = 0 :=
  fpM_zero_of m j j (fun x => by have := fp_ms_bounds m x; omega)

lemma fp_forall_Icc_succ {P : ℕ → Prop} {m : ℕ} :
    (∀ k ∈ Icc 1 (m + 1), P k) ↔ ∀ j ≤ m, P (j + 1) :=
  ⟨fun h j hj => h _ (by simp; omega), fun h k hk => by
    simp at hk
    obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
    exact h j (by omega)⟩

lemma fp_ivt (m : ℕ) (y : Fin m → Bool) (h : ℤ) (hh : 0 ≤ h) :
    (∀ j ≤ m, h + 1 + fpScore y j ≠ 0) ↔ (∀ j ≤ m, 0 ≤ h + fpScore y j) := by
  induction m generalizing h with
  | zero =>
    constructor <;> intro _ j hj <;> obtain rfl : j = 0 := (by omega) <;> simp [fp_ms_zero] <;>
      omega
  | succ m ih =>
    obtain ⟨c, t, rfl⟩ := fp_cons_exists y
    rw [fp_forall_le_succ, fp_forall_le_succ]
    simp only [fp_ms_zero, fp_ms_cons]
    cases c
    · simp only [fpSg, Bool.false_eq_true, ite_false]
      rcases eq_or_lt_of_le hh with h0 | h0
      · subst h0
        constructor
        · rintro ⟨_, h2⟩; have := h2 0 (by omega); simp [fp_ms_zero] at this
        · rintro ⟨_, h2⟩; have := h2 0 (by omega); simp [fp_ms_zero] at this
      · have := ih t (h - 1) (by omega)
        constructor
        · rintro ⟨_, h2⟩
          refine ⟨by omega, fun j hj => ?_⟩
          have := this.mp (fun j hj => by have := h2 j hj; omega) j hj
          omega
        · rintro ⟨_, h2⟩
          refine ⟨by omega, fun j hj => ?_⟩
          have := this.mpr (fun j hj => by have := h2 j hj; omega) j hj
          omega
    · simp only [fpSg, ite_true]
      have := ih t (h + 1) (by omega)
      constructor
      · rintro ⟨_, h2⟩
        refine ⟨by omega, fun j hj => ?_⟩
        have := this.mp (fun j hj => by have := h2 j hj; omega) j hj
        omega
      · rintro ⟨_, h2⟩
        refine ⟨by omega, fun j hj => ?_⟩
        have := this.mpr (fun j hj => by have := h2 j hj; omega) j hj
        omega

lemma fp_never_level_succ (m : ℕ) :
    #(univ.filter (fun ω : Fin (m+1) → Bool => fpAvoids 0 ω)) = 2 * fpN m 0 := by
  rw [Finset.card_filter, fp_sum_split]
  simp only [fpAvoids, fp_forall_Icc_succ, fp_ms_cons, fpSg, Bool.false_eq_true, ite_true,
    ite_false]
  have key : ∀ y : Fin m → Bool, (∀ j ≤ m, 1 + fpScore y j ≠ 0) ↔
      (∀ j ≤ m, 0 ≤ 0 + fpScore y j) := by
    intro y
    have := fp_ivt m y 0 le_rfl
    simpa using this
  have h1 : (∑ y : Fin m → Bool, if (∀ j ≤ m, 1 + fpScore y j ≠ 0) then 1 else 0) = fpN m 0 := by
    unfold fpN
    refine Finset.sum_congr rfl fun y _ => ?_
    simp only [key y]
  rw [fp_sum_not (fun y : Fin m → Bool => if (∀ j ≤ m, -1 + fpScore y j ≠ 0) then 1 else 0)]
  simp only [fp_ms_not]
  have h2 : (∑ y : Fin m → Bool, if (∀ j ≤ m, -1 + -fpScore y j ≠ 0) then 1 else 0) =
      (∑ y : Fin m → Bool, if (∀ j ≤ m, 1 + fpScore y j ≠ 0) then 1 else 0) := by
    refine Finset.sum_congr rfl fun y _ => ?_
    congr 1
    refine propext (forall_congr' fun j => imp_congr_right fun _ => ?_)
    constructor <;> intro h <;> omega
  rw [h2, h1]
  ring

lemma fp_card_avoid_zero (n : ℕ) :
    #(univ.filter (fun ω : Fin (2 * n) → Bool => fpAvoids 0 ω)) = Nat.choose (2 * n) n := by
  rcases n with _ | n
  · decide
  · have e : 2 * (n + 1) = (2 * n + 1) + 1 := by ring
    rw [e, fp_never_level_succ, fpN_eq_fpM _ _ (by norm_num), neg_zero, zero_add,
      fpM_split _ 0 0 1 (by norm_num) (by norm_num), fpM_odd _ _ (by push_cast; omega), zero_add, zero_add,
      fpM_binom (2 * n + 1) (n + 1) _ (by push_cast; ring), Nat.choose_succ_succ (2 * n + 1) n,
      Nat.choose_symm_half]
    ring

/-- The chance of one particular win-loss sequence when each round is won with chance `p`. -/
noncomputable def fpW (p : ℝ) {n : ℕ} (x : Fin n → Bool) : ℝ :=
  ∏ i, (if x i then p else 1 - p)

open Classical in
/-- Chance that the score equals `b` on some round from 0 to `n`. -/
noncomputable def fpPhi (p : ℝ) (n : ℕ) (b : ℤ) : ℝ :=
  ∑ x : Fin n → Bool, if (∃ k ≤ n, fpScore x k = b) then fpW p x else 0

open Classical in
/-- Chance that the score equals `a` on some round from 1 to `n`. -/
noncomputable def fpPsi (p : ℝ) (n : ℕ) (a : ℤ) : ℝ :=
  ∑ x : Fin n → Bool, if (∃ k ∈ Icc 1 n, fpScore x k = a) then fpW p x else 0

lemma fpW_cons (p : ℝ) {n : ℕ} (c : Bool) (y : Fin n → Bool) :
    fpW p (Fin.cons c y : Fin (n+1) → Bool) = (if c then p else 1 - p) * fpW p y := by
  simp [fpW, Fin.prod_univ_succ]

lemma fpW_sum (p : ℝ) (n : ℕ) : ∑ x : Fin n → Bool, fpW p x = 1 := by
  induction n with
  | zero => simp [fpW]
  | succ n ih =>
    rw [fp_sum_split]
    simp only [fpW_cons, ite_true, Bool.false_eq_true, ite_false, ← Finset.mul_sum, ih]
    ring

lemma fpW_nonneg (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) {n : ℕ} (x : Fin n → Bool) :
    0 ≤ fpW p x :=
  Finset.prod_nonneg fun i _ => by split_ifs <;> linarith

lemma fp_exists_Icc_succ {P : ℕ → Prop} {m : ℕ} :
    (∃ k ∈ Icc 1 (m + 1), P k) ↔ ∃ j ≤ m, P (j + 1) :=
  ⟨fun ⟨k, hk, h⟩ => by
    simp at hk
    obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
    exact ⟨j, by omega, h⟩, fun ⟨j, hj, h⟩ => ⟨j + 1, by simp; omega, h⟩⟩

lemma fpPhi_eq (p : ℝ) (n : ℕ) (b : ℤ) :
    fpPhi p n b = if b = 0 then 1 else fpPsi p n b := by
  unfold fpPhi fpPsi
  split_ifs with hb
  · subst hb
    rw [← fpW_sum p n]
    exact Finset.sum_congr rfl fun x _ => if_pos ⟨0, Nat.zero_le _, fp_ms_zero x⟩
  · refine Finset.sum_congr rfl fun x _ => ?_
    congr 1
    refine propext ⟨fun ⟨k, hk, h⟩ => ⟨k, ?_, h⟩, fun ⟨k, hk, h⟩ => ⟨k, by simp at hk; omega, h⟩⟩
    rcases k with _ | k
    · rw [fp_ms_zero] at h; exact absurd h.symm hb
    · simp; omega

lemma fpPsi_succ (p : ℝ) (n : ℕ) (a : ℤ) :
    fpPsi p (n+1) a = p * fpPhi p n (a - 1) + (1 - p) * fpPhi p n (a + 1) := by
  unfold fpPsi fpPhi
  rw [fp_sum_split]
  simp only [fp_exists_Icc_succ, fp_ms_cons, fpW_cons, fpSg, ite_true, Bool.false_eq_true,
    ite_false, Finset.mul_sum]
  congr 1 <;> refine Finset.sum_congr rfl fun y _ => ?_ <;> rw [mul_ite, mul_zero] <;> congr 1 <;>
    refine propext (exists_congr fun j => and_congr_right fun _ => ?_) <;> constructor <;>
    intro <;> omega

lemma fpPhi_zero (p : ℝ) (b : ℤ) : fpPhi p 0 b = if b = 0 then 1 else 0 := by
  rw [fpPhi_eq]
  split_ifs
  · rfl
  · unfold fpPsi
    exact Finset.sum_eq_zero fun x _ => if_neg (by simp)

lemma fpPhi_succ (p : ℝ) (n : ℕ) (b : ℤ) :
    fpPhi p (n+1) b = if b = 0 then 1 else p * fpPhi p n (b - 1) + (1 - p) * fpPhi p n (b + 1) := by
  rw [fpPhi_eq, fpPsi_succ]

lemma fpPhi_bounds (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (n : ℕ) (b : ℤ) :
    0 ≤ fpPhi p n b ∧ fpPhi p n b ≤ 1 := by
  induction n generalizing b with
  | zero => rw [fpPhi_zero]; split_ifs <;> norm_num
  | succ n ih =>
    rw [fpPhi_succ]
    split_ifs
    · norm_num
    · have h1 := ih (b - 1); have h2 := ih (b + 1)
      constructor <;> nlinarith

lemma fpPhi_mono (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (n : ℕ) (b : ℤ) :
    fpPhi p n b ≤ fpPhi p (n+1) b := by
  induction n generalizing b with
  | zero =>
    rw [fpPhi_zero, fpPhi_succ]
    split_ifs
    · rfl
    · have h1 := fpPhi_bounds p hp0 hp1 0 (b - 1); have h2 := fpPhi_bounds p hp0 hp1 0 (b + 1)
      nlinarith
  | succ n ih =>
    rw [fpPhi_succ p (n+1), fpPhi_succ p n]
    split_ifs
    · rfl
    · have h1 := ih (b - 1); have h2 := ih (b + 1)
      nlinarith

lemma fpPhi_symm (p : ℝ) (n : ℕ) (b : ℤ) : fpPhi p n b = fpPhi (1 - p) n (-b) := by
  induction n generalizing b with
  | zero => rw [fpPhi_zero, fpPhi_zero]; simp
  | succ n ih =>
    rw [fpPhi_succ, fpPhi_succ, ih (b - 1), ih (b + 1)]
    simp only [neg_eq_zero]
    split_ifs
    · rfl
    · rw [show -(b - 1) = -b + 1 by ring, show -(b + 1) = -b - 1 by ring]
      ring

lemma fpPhi_le (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (φ : ℤ → ℝ) (hφ0 : ∀ b, 0 ≤ φ b)
    (hφ1 : 1 ≤ φ 0) (hφ : ∀ b, b ≠ 0 → p * φ (b - 1) + (1 - p) * φ (b + 1) ≤ φ b)
    (n : ℕ) (b : ℤ) : fpPhi p n b ≤ φ b := by
  induction n generalizing b with
  | zero =>
    rw [fpPhi_zero]
    split_ifs with hb
    · subst hb; exact hφ1
    · exact hφ0 b
  | succ n ih =>
    rw [fpPhi_succ]
    split_ifs with hb
    · subst hb; exact hφ1
    · have h1 := ih (b - 1); have h2 := ih (b + 1); have h3 := hφ b hb
      nlinarith

/-- The chance of ever reaching `b` (time 0 included). -/
noncomputable def fpH (p : ℝ) (b : ℤ) : ℝ := ⨆ n, fpPhi p n b

lemma fpPhi_bdd (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) :
    BddAbove (Set.range fun n => fpPhi p n b) :=
  ⟨1, by rintro _ ⟨n, rfl⟩; exact (fpPhi_bounds p hp0 hp1 n b).2⟩

lemma fpPhi_tendsto (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) :
    Filter.Tendsto (fun n => fpPhi p n b) Filter.atTop (nhds (fpH p b)) :=
  tendsto_atTop_ciSup (monotone_nat_of_le_succ fun n => fpPhi_mono p hp0 hp1 n b)
    (fpPhi_bdd p hp0 hp1 b)

lemma fpH_bounds (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) : 0 ≤ fpH p b ∧ fpH p b ≤ 1 :=
  ⟨le_ciSup_of_le (fpPhi_bdd p hp0 hp1 b) 0 (fpPhi_bounds p hp0 hp1 0 b).1,
    ciSup_le fun n => (fpPhi_bounds p hp0 hp1 n b).2⟩

lemma fpH_zero (p : ℝ) : fpH p 0 = 1 := by
  have : ∀ n, fpPhi p n 0 = 1 := by
    intro n; cases n with
    | zero => rw [fpPhi_zero]; simp
    | succ n => rw [fpPhi_succ]; simp
  simp [fpH, this]

lemma fpH_rec (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) (hb : b ≠ 0) :
    fpH p b = p * fpH p (b - 1) + (1 - p) * fpH p (b + 1) := by
  have t1 : Filter.Tendsto (fun n => fpPhi p (n + 1) b) Filter.atTop (nhds (fpH p b)) :=
    (fpPhi_tendsto p hp0 hp1 b).comp (Filter.tendsto_add_atTop_nat 1)
  have t2 : Filter.Tendsto (fun n => fpPhi p (n + 1) b) Filter.atTop
      (nhds (p * fpH p (b - 1) + (1 - p) * fpH p (b + 1))) := by
    simp_rw [fpPhi_succ, if_neg hb]
    exact ((fpPhi_tendsto p hp0 hp1 _).const_mul p).add
      ((fpPhi_tendsto p hp0 hp1 _).const_mul (1 - p))
  exact tendsto_nhds_unique t1 t2

lemma fpH_le (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (φ : ℤ → ℝ) (hφ0 : ∀ b, 0 ≤ φ b)
    (hφ1 : 1 ≤ φ 0) (hφ : ∀ b, b ≠ 0 → p * φ (b - 1) + (1 - p) * φ (b + 1) ≤ φ b)
    (b : ℤ) : fpH p b ≤ φ b :=
  ciSup_le fun n => fpPhi_le p hp0 hp1 φ hφ0 hφ1 hφ n b

lemma fpH_symm (p : ℝ) (b : ℤ) : fpH p b = fpH (1 - p) (-b) := by
  unfold fpH
  simp_rw [fpPhi_symm p _ b]

/-- The chance of ever reaching level `n ≥ 0`. -/
noncomputable def fpHN (p : ℝ) (n : ℕ) : ℝ := fpH p n

lemma fpHN_rec (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (n : ℕ) :
    fpHN p (n + 1) = p * fpHN p n + (1 - p) * fpHN p (n + 2) := by
  have := fpH_rec p hp0 hp1 ((n + 1 : ℕ) : ℤ) (by omega)
  unfold fpHN
  convert this using 4 <;> push_cast <;> ring

lemma fpHN_gen (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (hq : 0 < 1 - p) (n : ℕ) :
    fpHN p n = 1 + (fpHN p 1 - 1) * ∑ i ∈ range n, (p / (1 - p)) ^ i := by
  have H0 : fpHN p 0 = 1 := by simp [fpHN, fpH_zero]
  have hD : ∀ n, fpHN p (n + 1) - fpHN p n = (p / (1 - p)) ^ n * (fpHN p 1 - 1) := by
    intro n
    induction n with
    | zero => simp [H0]
    | succ n ih =>
      have key : (1 - p) * (fpHN p (n + 2) - fpHN p (n + 1)) =
          p * (fpHN p (n + 1) - fpHN p n) := by
        linear_combination (-1 : ℝ) * fpHN_rec p hp0 hp1 n
      have key2 : fpHN p (n + 2) - fpHN p (n + 1) = p / (1 - p) * (fpHN p (n + 1) - fpHN p n) := by
        rw [div_mul_eq_mul_div, eq_div_iff hq.ne']
        linarith
      rw [key2, ih]
      ring
  induction n with
  | zero => simp [H0]
  | succ n ih =>
    rw [sum_range_succ]
    have := hD n
    linear_combination this + ih

lemma fpH_level (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (a : ℕ) :
    fpH p a = if 1 / 2 ≤ p then 1 else (p / (1 - p)) ^ a := by
  show fpHN p a = _
  have H0 : fpHN p 0 = 1 := by simp [fpHN, fpH_zero]
  have Hb : ∀ n, 0 ≤ fpHN p n ∧ fpHN p n ≤ 1 := fun n => fpH_bounds p hp0 hp1 n
  by_cases hp : 1 / 2 ≤ p
  · rw [if_pos hp]
    by_cases hp1' : p = 1
    · subst hp1'
      have : ∀ n, fpHN 1 n = 1 := by
        intro n
        induction n with
        | zero => exact H0
        | succ n ih => have := fpHN_rec 1 hp0 hp1 n; rw [this, ih]; ring
      exact this a
    · have hq : 0 < 1 - p := by
        have := lt_of_le_of_ne hp1 hp1'
        linarith
      have hc : fpHN p 1 - 1 = 0 := by
        by_contra hc
        have hcpos : 0 < |fpHN p 1 - 1| := abs_pos.mpr hc
        obtain ⟨N, hN⟩ := exists_nat_gt (1 / |fpHN p 1 - 1|)
        have hR : 1 ≤ p / (1 - p) := by rw [le_div_iff₀ hq]; linarith
        have hG : (N : ℝ) ≤ ∑ i ∈ range N, (p / (1 - p)) ^ i := by
          calc (N : ℝ) = ∑ i ∈ range N, (1 : ℝ) := by simp
            _ ≤ _ := Finset.sum_le_sum fun i _ => one_le_pow₀ hR
        have h1 := fpHN_gen p hp0 hp1 hq N
        have h2 := Hb N
        have h3 : 1 < |fpHN p 1 - 1| * N := by
          rw [div_lt_iff₀ hcpos] at hN; linarith
        have h4 : |fpHN p N - 1| ≤ 1 := by rw [abs_le]; constructor <;> linarith
        rw [h1, add_sub_cancel_left, abs_mul,
          abs_of_nonneg (le_trans (Nat.cast_nonneg N) hG)] at h4
        nlinarith
      have := fpHN_gen p hp0 hp1 hq a
      rw [hc] at this
      simpa using this
  · rw [if_neg hp]
    replace hp := not_le.mp hp
    have hq : 0 < 1 - p := by linarith
    have hr0 : 0 ≤ p / (1 - p) := div_nonneg hp0 hq.le
    have hr1 : p / (1 - p) < 1 := by rw [div_lt_one hq]; linarith
    have hup : ∀ n : ℕ, fpHN p n ≤ (p / (1 - p)) ^ n := by
      intro n
      have := fpH_le p hp0 hp1 (fun b => (p / (1 - p)) ^ b.toNat) (fun b => pow_nonneg hr0 _)
        (by simp) ?_ n
      · simpa [fpHN] using this
      · intro b hb
        rcases lt_or_gt_of_ne hb with hb | hb
        · have e1 : (b - 1).toNat = 0 := by omega
          have e2 : (b + 1).toNat = 0 := by omega
          have e3 : b.toNat = 0 := by omega
          simp only [e1, e2, e3, pow_zero]
          linarith
        · obtain ⟨m, rfl⟩ : ∃ m : ℕ, b = m + 1 := ⟨(b - 1).toNat, by omega⟩
          have e1 : ((m : ℤ) + 1 - 1).toNat = m := by omega
          have e2 : ((m : ℤ) + 1 + 1).toNat = m + 2 := by omega
          have e3 : ((m : ℤ) + 1).toNat = m + 1 := by omega
          simp only [e1, e2, e3]
          have : p + (1 - p) * (p / (1 - p)) ^ 2 = p / (1 - p) := by
            field_simp; ring
          apply le_of_eq
          calc p * (p / (1 - p)) ^ m + (1 - p) * (p / (1 - p)) ^ (m + 2)
              = (p / (1 - p)) ^ m * (p + (1 - p) * (p / (1 - p)) ^ 2) := by ring
            _ = (p / (1 - p)) ^ (m + 1) := by rw [this]; ring
    have hG : ∀ n, (∑ i ∈ range n, (p / (1 - p)) ^ i) * (p / (1 - p) - 1) =
        (p / (1 - p)) ^ n - 1 := fun n => geom_sum_mul _ n
    have hform : ∀ n, fpHN p n = (p / (1 - p)) ^ n +
        (fpHN p 1 - 1 - (p / (1 - p) - 1)) * ∑ i ∈ range n, (p / (1 - p)) ^ i := by
      intro n
      rw [fpHN_gen p hp0 hp1 hq n]
      linear_combination hG n
    have he1 : fpHN p 1 - 1 - (p / (1 - p) - 1) ≤ 0 := by
      have := hup 1
      rw [hform 1] at this
      simp at this
      linarith
    have he : fpHN p 1 - 1 - (p / (1 - p) - 1) = 0 := by
      by_contra hne
      have he' := lt_of_le_of_ne he1 hne
      obtain ⟨N, hN⟩ := exists_pow_lt_of_lt_one (neg_pos.mpr he') hr1
      have hGe : 1 ≤ ∑ i ∈ range (N + 1), (p / (1 - p)) ^ i := by
        rw [sum_range_succ']
        simp only [pow_zero]
        have : 0 ≤ ∑ i ∈ range N, (p / (1 - p)) ^ (i + 1) :=
          Finset.sum_nonneg fun i _ => pow_nonneg hr0 _
        linarith
      have h1 := hform (N + 1)
      have h2 := (Hb (N + 1)).1
      have h3 : (p / (1 - p)) ^ (N + 1) ≤ (p / (1 - p)) ^ N :=
        pow_le_pow_of_le_one hr0 hr1.le (by omega)
      nlinarith
    rw [hform, he]
    simp

lemma fp_return_value (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    p * fpH p (-1) + (1 - p) * fpH p 1 = 1 - |p - (1 - p)| := by
  rw [fpH_symm p (-1), neg_neg]
  have h1 := fpH_level p hp0 hp1 1
  have h2 := fpH_level (1 - p) (by linarith) (by linarith) 1
  push_cast at h1 h2
  rw [h1, h2]
  by_cases hp : 1 / 2 ≤ p
  · rw [if_pos hp]
    by_cases hq : 1 / 2 ≤ 1 - p
    · rw [if_pos hq]
      have : p = 1 / 2 := by linarith
      subst this; norm_num
    · rw [if_neg hq, abs_of_nonneg (by linarith), pow_one]
      have hp' : 0 < p := by linarith
      rw [show 1 - (1 - p) = p by ring]
      field_simp
      ring
  · rw [if_neg hp, if_pos (by linarith), abs_of_neg (by linarith), pow_one]
    have hq : 0 < 1 - p := by linarith
    field_simp
    ring

lemma fpPsi_tendsto_ne (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (a : ℤ) (ha : a ≠ 0) :
    Filter.Tendsto (fun n => fpPsi p n a) Filter.atTop (nhds (fpH p a)) := by
  have := fpPhi_tendsto p hp0 hp1 a
  simp_rw [fpPhi_eq, if_neg ha] at this
  exact this

lemma fpPsi_tendsto_zero (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    Filter.Tendsto (fun n => fpPsi p n 0) Filter.atTop
      (nhds (p * fpH p (-1) + (1 - p) * fpH p 1)) := by
  rw [← Filter.tendsto_add_atTop_iff_nat 1]
  simp_rw [fpPsi_succ, zero_sub, zero_add]
  exact ((fpPhi_tendsto p hp0 hp1 _).const_mul p).add
    ((fpPhi_tendsto p hp0 hp1 _).const_mul (1 - p))

lemma fp_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p) (n : ℕ)
    (Q : (Fin n → Bool) → Prop) [DecidablePred Q] :
    P {ω | Q (fun i => decide (X i ω = 1))} =
      ENNReal.ofReal (∑ x, if Q x then fpW p x else 0) := by
  classical
  have hYm : ∀ i : ℕ, Measurable (fun ω => decide (X i ω = 1)) :=
    fun i => (measurable_of_countable (fun z : ℤ => decide (z = 1))).comp (hmeas i)
  have hY : iIndepFun (fun (i : Fin n) ω => decide (X i ω = 1)) P := by
    have h1 := hind.precomp (g := fun i : Fin n => (i : ℕ)) Fin.val_injective
    exact h1.comp (fun _ z => decide (z = 1)) (fun _ => measurable_of_countable _)
  have hcyl : ∀ x : Fin n → Bool, P {ω | (fun i : Fin n => decide (X i ω = 1)) = x} =
      ENNReal.ofReal (fpW p x) := by
    intro x
    have hset : {ω | (fun i : Fin n => decide (X i ω = 1)) = x} =
        ⋂ i ∈ (univ : Finset (Fin n)), (fun ω => decide (X i ω = 1)) ⁻¹' {x i} := by
      ext ω; simp [funext_iff]
    rw [hset, hY.measure_inter_preimage_eq_mul univ (fun i _ => measurableSet_singleton _)]
    unfold fpW
    rw [ENNReal.ofReal_prod_of_nonneg (fun i _ => by split_ifs <;> linarith)]
    refine Finset.prod_congr rfl fun i _ => ?_
    have hm1 : MeasurableSet {ω | X i ω = 1} := hmeas i (measurableSet_singleton (1 : ℤ))
    cases hx : x i
    · have : (fun ω => decide (X i ω = 1)) ⁻¹' {false} = {ω | X i ω = 1}ᶜ := by
        ext ω; simp
      rw [this, prob_compl_eq_one_sub hm1, hup]
      simp only [Bool.false_eq_true, ite_false]
      rw [ENNReal.ofReal_sub _ hp0, ENNReal.ofReal_one]
    · have : (fun ω => decide (X i ω = 1)) ⁻¹' {true} = {ω | X i ω = 1} := by
        ext ω; simp
      rw [this, hup]
      simp
  have hU : {ω | Q (fun i => decide (X i ω = 1))} =
      ⋃ x ∈ univ.filter Q, {ω | (fun i : Fin n => decide (X i ω = 1)) = x} := by
    ext ω; simp
  rw [hU, measure_biUnion_finset]
  · simp_rw [hcyl]
    rw [← ENNReal.ofReal_sum_of_nonneg (fun x _ => fpW_nonneg p hp0 hp1 x), Finset.sum_filter]
  · intro x _ y _ hxy
    rw [Function.onFun, Set.disjoint_left]
    intro ω h1 h2
    exact hxy (h1.symm.trans h2)
  · intro x _
    exact (measurable_pi_iff.mpr (fun i : Fin n => hYm i)) (measurableSet_singleton x)

lemma fp_ae_pm {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) :
    ∀ᵐ ω ∂P, ∀ i, X i ω = 1 ∨ X i ω = -1 := by
  rw [ae_all_iff]
  intro i
  have hm1 : MeasurableSet {ω | X i ω = 1} := hmeas i (measurableSet_singleton (1 : ℤ))
  have hm2 : MeasurableSet {ω | X i ω = -1} := hmeas i (measurableSet_singleton (-1 : ℤ))
  have hu : P ({ω | X i ω = 1} ∪ {ω | X i ω = -1}) = 1 := by
    rw [measure_union _ hm2, hup, hdown, ← ENNReal.ofReal_add hp0 (by linarith)]
    · simp
    · rw [Set.disjoint_left]; intro ω h1 h2; simp at h1 h2; omega
  have := (prob_compl_eq_zero_iff (hm1.union hm2)).mpr hu
  rw [ae_iff]
  refine measure_mono_null ?_ this
  intro ω hω
  simp only [Set.mem_setOf_eq, not_or] at hω
  simp [hω.1, hω.2]

lemma fp_score_eq {Ω : Type*} (X : ℕ → Ω → ℤ) (ω : Ω) (hω : ∀ i, X i ω = 1 ∨ X i ω = -1)
    (n k : ℕ) (hk : k ≤ n) :
    walkScore X k ω = fpScore (fun i : Fin n => decide (X i ω = 1)) k := by
  unfold walkScore fpScore
  rw [Fin.sum_univ_eq_sum_range
    (fun j => if j < k then (if decide (X j ω = 1) = true then (1 : ℤ) else -1) else 0) n,
    ← Finset.sum_filter]
  have : (range n).filter (· < k) = range k := by
    ext j; simp; omega
  rw [this]
  refine Finset.sum_congr rfl fun i _ => ?_
  rcases hω i with h | h <;> simp [h]

lemma fp_walk_meas {Ω : Type*} [MeasurableSpace Ω] (X : ℕ → Ω → ℤ)
    (hmeas : ∀ i, Measurable (X i)) (k : ℕ) : Measurable (fun ω => walkScore X k ω) :=
  Finset.measurable_sum _ (fun i _ => hmeas i)

lemma fp_event_hit {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) (n : ℕ) (a : ℤ) :
    P {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a} = ENNReal.ofReal (fpPsi p n a) := by
  have h := fp_law X hmeas hind p hp0 hp1 hup n (fun x => ∃ k ∈ Icc (1:ℕ) n, fpScore x k = a)
  have hset : {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a} =ᵐ[P]
      {ω | ∃ k ∈ Icc 1 n, fpScore (fun i : Fin n => decide (X i ω = 1)) k = a} := by
    rw [Filter.eventuallyEq_set]
    filter_upwards [fp_ae_pm X hmeas p hp0 hp1 hup hdown] with ω hω
    constructor
    · rintro ⟨k, hk, h⟩
      exact ⟨k, hk, by rw [← fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h⟩
    · rintro ⟨k, hk, h⟩
      exact ⟨k, hk, by rw [fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h⟩
  rw [measure_congr hset, h, fpPsi]
  congr 1
  refine Finset.sum_congr rfl fun x _ => ?_
  congr 1

lemma fp_event_avoid {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) (n : ℕ) (a : ℤ) :
    P {ω | ∀ k ∈ Icc 1 n, walkScore X k ω ≠ a} = ENNReal.ofReal
      (∑ x : Fin n → Bool, if fpAvoids a x then fpW p x else 0) := by
  have h := fp_law X hmeas hind p hp0 hp1 hup n (fpAvoids a)
  have hset : {ω | ∀ k ∈ Icc 1 n, walkScore X k ω ≠ a} =ᵐ[P]
      {ω | fpAvoids a (fun i : Fin n => decide (X i ω = 1))} := by
    rw [Filter.eventuallyEq_set]
    filter_upwards [fp_ae_pm X hmeas p hp0 hp1 hup hdown] with ω hω
    simp only [Set.mem_setOf_eq, fpAvoids]
    constructor
    · intro h k hk
      rw [← fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h k hk
    · intro h k hk
      rw [fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h k hk
  rw [measure_congr hset, h]

lemma fp_hit_set {Ω : Type*} (X : ℕ → Ω → ℤ) (a : ℤ) :
    {ω | hitTime X a ω < ∞} = ⋃ n, {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a} := by
  ext ω
  simp only [hitTime, Set.mem_setOf_eq, Set.mem_iUnion, iInf_lt_iff, Finset.mem_Icc]
  constructor
  · rintro ⟨n, ⟨h1, h2⟩, -⟩
    exact ⟨n, n, ⟨h1, le_rfl⟩, h2⟩
  · rintro ⟨n, k, ⟨h1, -⟩, h2⟩
    exact ⟨k, ⟨h1, h2⟩, ENNReal.natCast_lt_top k⟩

lemma fp_hit_prob {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) (a : ℤ) (L : ℝ)
    (hL : Filter.Tendsto (fun n => fpPsi p n a) Filter.atTop (nhds L)) :
    P {ω | hitTime X a ω < ∞} = ENNReal.ofReal L := by
  rw [fp_hit_set]
  have hmono : Monotone (fun n => {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a}) := by
    intro n m hnm ω ⟨k, hk, h⟩
    exact ⟨k, by simp at hk ⊢; omega, h⟩
  have t1 := tendsto_measure_iUnion_atTop (μ := P) hmono
  have t2 : Filter.Tendsto (P ∘ fun n => {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a})
      Filter.atTop (nhds (ENNReal.ofReal L)) := by
    have : (P ∘ fun n => {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a}) =
        fun n => ENNReal.ofReal (fpPsi p n a) := by
      funext n
      exact fp_event_hit X hmeas hind p hp0 hp1 hup hdown n a
    rw [this]
    exact (ENNReal.continuous_ofReal.tendsto L).comp hL
  exact tendsto_nhds_unique t1 t2


lemma fp_count_avoid (a : ℤ) (m : ℕ) :
    ((2 * m).choose m : ℝ) ≤ ∑ x : Fin (2 * m) → Bool, if fpAvoids a x then (1 : ℝ) else 0 := by
  have base : ((2 * m).choose m : ℝ) ≤ fpN (2 * m) 0 := by
    have : (2 * m).choose m ≤ fpN (2 * m) 0 := by
      rw [fpN_eq_fpM _ _ (by norm_num), neg_zero, zero_add,
        fpM_split (2 * m) 0 0 1 (by norm_num) (by norm_num),
        fpM_binom (2 * m) m 0 (by push_cast; ring)]
      omega
    exact_mod_cast this
  have hpt : ∀ (P Q : Prop) [Decidable P] [Decidable Q], (P → Q) →
      (if P then (1 : ℝ) else 0) ≤ (if Q then (1 : ℝ) else 0) := by
    intro P Q _ _ hPQ
    by_cases hP : P
    · simp [hP, hPQ hP]
    · simp only [hP, if_false]; split_ifs <;> norm_num
  rcases lt_trichotomy a 0 with ha | rfl | ha
  · refine base.trans ?_
    unfold fpN
    push_cast
    refine Finset.sum_le_sum fun x _ => hpt _ _ fun h1 k hk => ?_
    have := h1 k (Finset.mem_Icc.mp hk).2
    omega
  · have := fp_card_avoid_zero m
    rw [Finset.card_filter] at this
    rw [← this]
    push_cast
    exact le_of_eq rfl
  · refine base.trans ?_
    rw [fp_sum_not (fun x : Fin (2 * m) → Bool => if fpAvoids a x then (1 : ℝ) else 0)]
    unfold fpN
    push_cast
    refine Finset.sum_le_sum fun x _ => hpt _ _ fun h1 k hk => ?_
    rw [fp_ms_not]
    have := h1 k (Finset.mem_Icc.mp hk).2
    omega

lemma fp_harmonic_odd : ∑' m : ℕ, ENNReal.ofReal (1 / (2 * (m : ℝ) + 1)) = ∞ := by
  by_contra h
  have h' : Summable (fun m : ℕ => Real.toNNReal (1 / (2 * (m : ℝ) + 1))) :=
    ENNReal.tsum_coe_ne_top_iff_summable.mp h
  have h'' : Summable (fun m : ℕ => 1 / (2 * (m : ℝ) + 1)) := by
    have := NNReal.summable_coe.mpr h'
    refine this.congr fun m => ?_
    simp only [Real.coe_toNNReal _ (by positivity : (0 : ℝ) ≤ 1 / (2 * (m : ℝ) + 1))]
  have h3 : Summable (fun m : ℕ => 1 / ((m + 1 : ℕ) : ℝ)) := by
    refine Summable.of_nonneg_of_le (fun m => by positivity) (fun m => ?_) (h''.mul_left 2)
    push_cast
    rw [mul_one_div, div_le_div_iff₀ (by positivity) (by positivity)]
    nlinarith
  exact Real.not_summable_one_div_natCast ((summable_nat_add_iff 1).mp h3)

#print axioms fp_sum_split
#print axioms fp_ms_zero
#print axioms fp_ms_cons
#print axioms fp_ms_not
#print axioms fp_forall_le_succ
#print axioms fp_sum_not
#print axioms fp_cons_exists
#print axioms fp_ms_bounds
#print axioms fpM_succ
#print axioms fpM_split
#print axioms fpM_zero_of
#print axioms fpN_succ
#print axioms fpN_eq_fpM
#print axioms fpM_binom
#print axioms fpM_odd
#print axioms fp_forall_Icc_succ
#print axioms fp_ivt
#print axioms fp_never_level_succ
#print axioms fp_card_avoid_zero
#print axioms fpW_cons
#print axioms fpW_sum
#print axioms fpW_nonneg
#print axioms fp_exists_Icc_succ
#print axioms fpPhi_eq
#print axioms fpPsi_succ
#print axioms fpPhi_zero
#print axioms fpPhi_succ
#print axioms fpPhi_bounds
#print axioms fpPhi_mono
#print axioms fpPhi_symm
#print axioms fpPhi_le
#print axioms fpPhi_bdd
#print axioms fpPhi_tendsto
#print axioms fpH_bounds
#print axioms fpH_zero
#print axioms fpH_rec
#print axioms fpH_le
#print axioms fpH_symm
#print axioms fpHN_rec
#print axioms fpHN_gen
#print axioms fpH_level
#print axioms fp_return_value
#print axioms fpPsi_tendsto_ne
#print axioms fpPsi_tendsto_zero
#print axioms fp_law
#print axioms fp_ae_pm
#print axioms fp_score_eq
#print axioms fp_walk_meas
#print axioms fp_event_hit
#print axioms fp_event_avoid
#print axioms fp_hit_set
#print axioms fp_hit_prob
#print axioms fp_count_avoid
#print axioms fp_harmonic_odd

/-- **Sure arrival, infinite mean.** Let the rounds be independent, each a step of exactly one
dollar, up with chance 1/2 and down with chance 1/2: the fair walk, with no floor and no
deadline. Then for every level `a` (the start `a = 0` included, which is the return time `T`)
the score reaches `a` with probability 1, and yet the average wait for it is infinite. -/
theorem fair_walk_hits_every_level_surely_with_infinite_mean_wait
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hup : ∀ i, P {ω | X i ω = 1} = 1 / 2) (hdown : ∀ i, P {ω | X i ω = -1} = 1 / 2)
    (a : ℤ) :
    P {ω | hitTime X a ω < ∞} = 1 ∧ ∫⁻ ω, hitTime X a ω ∂P = ∞ := by
  have hhalf : ENNReal.ofReal (1 / 2) = 1 / 2 := by
    rw [ENNReal.ofReal_div_of_pos (by norm_num)]; simp
  have hp0 : (0 : ℝ) ≤ 1 / 2 := by norm_num
  have hp1 : (1 / 2 : ℝ) ≤ 1 := by norm_num
  have hup' : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal (1 / 2) := fun i => by rw [hup, hhalf]
  have hdown' : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - 1 / 2) := fun i => by
    rw [hdown, show (1 : ℝ) - 1 / 2 = 1 / 2 by norm_num, hhalf]
  constructor
  · rcases lt_trichotomy a 0 with ha | rfl | ha
    · rw [fp_hit_prob X hmeas hind _ hp0 hp1 hup' hdown' a _
        (fpPsi_tendsto_ne _ hp0 hp1 a ha.ne), fpH_symm]
      have e : -a = (((-a).toNat : ℕ) : ℤ) := by omega
      rw [e, fpH_level _ (by norm_num) (by norm_num), if_pos (by norm_num)]
      simp
    · rw [fp_hit_prob X hmeas hind _ hp0 hp1 hup' hdown' 0 _ (fpPsi_tendsto_zero _ hp0 hp1),
        fp_return_value _ hp0 hp1]
      norm_num
    · rw [fp_hit_prob X hmeas hind _ hp0 hp1 hup' hdown' a _
        (fpPsi_tendsto_ne _ hp0 hp1 a ha.ne')]
      have e : a = ((a.toNat : ℕ) : ℤ) := by omega
      rw [e, fpH_level _ hp0 hp1, if_pos (by norm_num)]
      simp
  · let A : ℕ → Set Ω := fun j => {ω | ∀ k ∈ Icc (1:ℕ) j, walkScore X k ω ≠ a}
    have hAm : ∀ j, MeasurableSet (A j) := by
      intro j
      have : A j = ⋂ k ∈ Icc (1:ℕ) j, (fun ω => walkScore X k ω) ⁻¹' {a}ᶜ := by
        ext ω; simp [A]
      rw [this]
      exact Finset.measurableSet_biInter _
        (fun k _ => (fp_walk_meas X hmeas k) (measurableSet_singleton a).compl)
    have hle : ∀ ω, ∑' j, (A j).indicator 1 ω ≤ hitTime X a ω := by
      intro ω
      refine ENNReal.tsum_le_of_sum_range_le fun N => ?_
      unfold hitTime
      refine le_iInf₂ fun n hn => ?_
      calc ∑ j ∈ range N, (A j).indicator 1 ω
          ≤ ∑ j ∈ range N, (if j < n then (1 : ℝ≥0∞) else 0) := by
            refine Finset.sum_le_sum fun j _ => ?_
            by_cases hj : j < n
            · rw [if_pos hj]
              unfold Set.indicator
              split_ifs <;> simp
            · rw [if_neg hj]
              have : ω ∉ A j := by
                simp only [A, Set.mem_setOf_eq, not_forall, not_not]
                exact ⟨n, by simp; omega, hn.2⟩
              simp [this]
        _ ≤ n := by
            rw [← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul, mul_one]
            exact_mod_cast (Finset.card_le_card (fun j hj => by simp at hj ⊢; omega)).trans_eq
              (Finset.card_range n)
    have hint : ∑' j, P (A j) ≤ ∫⁻ ω, hitTime X a ω ∂P := by
      calc ∑' j, P (A j) = ∑' j, ∫⁻ ω, (A j).indicator 1 ω ∂P := by
            simp_rw [lintegral_indicator_one (hAm _)]
        _ = ∫⁻ ω, ∑' j, (A j).indicator 1 ω ∂P :=
            (lintegral_tsum fun j => (measurable_one.indicator (hAm j)).aemeasurable).symm
        _ ≤ ∫⁻ ω, hitTime X a ω ∂P := lintegral_mono hle
    have hPA : ∀ m : ℕ, ENNReal.ofReal (1 / (2 * (m : ℝ) + 1)) ≤ P (A (2 * m)) := by
      intro m
      rw [show P (A (2 * m)) = _ from fp_event_avoid X hmeas hind _ hp0 hp1 hup' hdown' (2 * m) a]
      apply ENNReal.ofReal_le_ofReal
      have hW : ∀ x : Fin (2 * m) → Bool, fpW (1 / 2) x = (1 / 4 : ℝ) ^ m := by
        intro x
        unfold fpW
        have : ∀ i, (if x i then (1 / 2 : ℝ) else 1 - 1 / 2) = 1 / 2 := by
          intro i; split_ifs <;> norm_num
        simp only [this, Finset.prod_const, Finset.card_univ, Fintype.card_fin, pow_mul]
        norm_num
      simp_rw [hW]
      have hsplit : ∀ x : Fin (2 * m) → Bool,
          (if fpAvoids a x then (1 / 4 : ℝ) ^ m else 0) =
          (1 / 4 : ℝ) ^ m * (if fpAvoids a x then (1 : ℝ) else 0) := by
        intro x; split_ifs <;> simp
      simp_rw [hsplit]
      rw [← Finset.mul_sum]
      have hc := fp_count_avoid a m
      have h4 := Nat.four_pow_le_two_mul_add_one_mul_centralBinom m
      rw [Nat.centralBinom_eq_two_mul_choose] at h4
      have h4' : (4 : ℝ) ^ m ≤ (2 * m + 1) * ((2 * m).choose m : ℝ) := by exact_mod_cast h4
      have h6 : (0 : ℝ) < 4 ^ m := by positivity
      rw [div_le_iff₀ (by positivity), one_div_pow]
      rw [show ∀ c : ℝ, 1 / 4 ^ m * c * (2 * m + 1) = (2 * m + 1) * c / 4 ^ m by
        intro c; field_simp]
      rw [le_div_iff₀ h6]
      nlinarith
    have hsum : ∑' m : ℕ, P (A (2 * m)) ≤ ∑' j, P (A j) :=
      ENNReal.tsum_comp_le_tsum_of_injective (fun x y h => by simpa using h) (fun j => P (A j))
    refine top_unique ?_
    calc (∞ : ℝ≥0∞) = ∑' m : ℕ, ENNReal.ofReal (1 / (2 * (m : ℝ) + 1)) := fp_harmonic_odd.symm
      _ ≤ ∑' m : ℕ, P (A (2 * m)) := ENNReal.tsum_le_tsum hPA
      _ ≤ ∑' j, P (A j) := hsum
      _ ≤ _ := hint

/-- **Whether it arrives, for any coin.** Let the rounds be independent steps of exactly one
dollar, up with chance `p` and down with chance `q = 1 − p`. For a target `a` of 1 or more,
the chance of ever reaching `a` is 1 when `p ≥ 1/2` and `(p/q)^a` when `p < 1/2`; and the
chance of ever being level again is `1 − |p − q|`. -/
theorem walk_arrival_and_return_chances
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp : p ∈ Set.Icc (0 : ℝ) 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) :
    (∀ a : ℕ, 1 ≤ a → P {ω | hitTime X a ω < ∞} =
        ENNReal.ofReal (if 1 / 2 ≤ p then 1 else (p / (1 - p)) ^ a)) ∧
      P {ω | hitTime X 0 ω < ∞} = ENNReal.ofReal (1 - |p - (1 - p)|) := by
  obtain ⟨hp0, hp1⟩ := hp
  refine ⟨fun a ha => ?_, ?_⟩
  · rw [fp_hit_prob X hmeas hind p hp0 hp1 hup hdown (a : ℤ) _
      (fpPsi_tendsto_ne p hp0 hp1 a (by omega)), fpH_level p hp0 hp1 a]
  · rw [fp_hit_prob X hmeas hind p hp0 hp1 hup hdown 0 _ (fpPsi_tendsto_zero p hp0 hp1),
      fp_return_value p hp0 hp1]

/-! One match of `m` rounds is a win-loss sequence `ω : Fin m → Bool` (`true` = Ana wins the
round). For the fair coin all `2^m` sequences are equally likely, so a count over `2^m` is a
chance. -/

/-- The score after the first `k` rounds of a match of `m` rounds. -/
def matchScore {m : ℕ} (ω : Fin m → Bool) (k : ℕ) : ℤ :=
  ∑ i : Fin m, if (i : ℕ) < k then (if ω i then 1 else -1) else 0

/-- A match of `m` rounds is never level after the start: its score is not 0 on any round
from 1 to `m`. -/
def neverLevel {m : ℕ} (ω : Fin m → Bool) : Prop :=
  ∀ k ∈ Icc 1 m, matchScore ω k ≠ 0

instance {m : ℕ} : DecidablePred (@neverLevel m) := fun ω =>
  inferInstanceAs (Decidable (∀ k ∈ Icc 1 m, matchScore ω k ≠ 0))

/-- **Still waiting after 2n rounds (Step 3).** Of the `2^(2n)` matches of `2n` rounds,
exactly `C(2n, n)` are never level on any round from 1 to `2n`. Dividing by `2^(2n)`:
the chance that the fair return time exceeds `2n` is `u_{2n} = C(2n, n) / 2^(2n)`, the chance
of a tie at round `2n`. -/
theorem card_never_level_eq_choose (n : ℕ) :
    #(univ.filter (fun ω : Fin (2 * n) → Bool => neverLevel ω)) = Nat.choose (2 * n) n := by
  exact fp_card_avoid_zero n

-- Small cases of the count: 2 of the 4 matches of 2 rounds, 6 of the 16 of 4 rounds and
-- 70 of the 256 of 8 rounds are never level; C(2, 1) = 2, C(4, 2) = 6 and C(8, 4) = 70.
example : #(univ.filter (fun ω : Fin 2 → Bool => neverLevel ω)) = Nat.choose 2 1 := by decide
example : #(univ.filter (fun ω : Fin 4 → Bool => neverLevel ω)) = Nat.choose 4 2 := by decide
example : #(univ.filter (fun ω : Fin 8 → Bool => neverLevel ω)) = Nat.choose 8 4 := by decide
-- Worked numbers: u_2, u_4, u_6, u_8, u_10 = C(2n, n) / 2^(2n) are 1/2, 3/8, 5/16, 35/128, 63/256
-- (0.5, 0.375, 0.3125, 0.273438, 0.246094).
example : (Nat.choose 2 1 : ℚ) / 2 ^ 2 = 1 / 2 ∧ (Nat.choose 4 2 : ℚ) / 2 ^ 4 = 3 / 8 ∧
    (Nat.choose 6 3 : ℚ) / 2 ^ 6 = 5 / 16 ∧ (Nat.choose 8 4 : ℚ) / 2 ^ 8 = 35 / 128 ∧
    (Nat.choose 10 5 : ℚ) / 2 ^ 10 = 63 / 256 := by
  norm_num [Nat.choose]
-- Each u is the one before times (2n − 1)/(2n): 1/2 · 3/4 = 3/8, · 5/6 = 5/16, · 7/8 = 35/128, · 9/10 = 63/256.
example : (1 : ℚ) / 2 * (3 / 4) = 3 / 8 ∧ (3 : ℚ) / 8 * (5 / 6) = 5 / 16 ∧
    (5 : ℚ) / 16 * (7 / 8) = 35 / 128 ∧ (35 : ℚ) / 128 * (9 / 10) = 63 / 256 := by norm_num
-- First returns P(T = 2n) = u_{2n−2} − u_{2n}: 1/2, 1/8, 1/16, 5/128 at rounds 2, 4, 6, 8.
example : (1 : ℚ) - 1 / 2 = 1 / 2 ∧ (1 : ℚ) / 2 - 3 / 8 = 1 / 8 ∧ (3 : ℚ) / 8 - 5 / 16 = 1 / 16 ∧
    (5 : ℚ) / 16 - 35 / 128 = 5 / 128 := by norm_num
-- No return in 16 rounds: C(16, 8) = 12870 of the 65536 matches, 6435/32768.
example : Nat.choose 16 8 = 12870 ∧ 2 ^ 16 = 65536 ∧ (12870 : ℚ) / 65536 = 6435 / 32768 := by
  norm_num [Nat.choose]
-- Capped mean at cap 10 (N = 5): 2 (1 + 1/2 + 3/8 + 5/16 + 35/128) = 315/64 = 4.921875,
-- equal to the closed form 2 · 9 · u_8, and at least the square-root floor √5 (its square is at least 5).
example : 2 * ((1 : ℚ) + 1 / 2 + 3 / 8 + 5 / 16 + 35 / 128) = 315 / 64 ∧
    (2 : ℚ) * 9 * (35 / 128) = 315 / 64 ∧ (5 : ℚ) ≤ (315 / 64) ^ 2 := by norm_num
-- Tilted coin p = 2/5, q = 3/5: ever one level up 2/3, ever 3 up (2/3)^3 = 8/27 = 0.296296,
-- ever level again 1 − |p − q| = 4/5.
example : (2 / 5 : ℚ) / (3 / 5) = 2 / 3 ∧ ((2 / 5 : ℚ) / (3 / 5)) ^ 3 = 8 / 27 ∧
    1 - |(2 / 5 : ℚ) - 3 / 5| = 4 / 5 := by norm_num [abs_of_neg]

/-- The pictured match: seven losses, six wins, a loss, two wins. -/
def pictured : Fin 16 → Bool := fun i =>
  [false, false, false, false, false, false, false, true, true, true, true, true, true,
   false, true, true].getD i false

-- It falls to −7 at round 7, is not level on rounds 1 to 15, and is level at round 16: T = 16.
example : matchScore pictured 7 = -7 ∧ (∀ k ∈ Icc 1 15, matchScore pictured k ≠ 0) ∧
    matchScore pictured 16 = 0 := by decide

#print axioms fair_walk_hits_every_level_surely_with_infinite_mean_wait
#print axioms walk_arrival_and_return_chances
#print axioms card_never_level_eq_choose
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'fp_sum_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_ms_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_ms_cons' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_ms_not' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_forall_le_succ' depends on axioms: [propext, Quot.sound]
'fp_sum_not' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_cons_exists' depends on axioms: [propext, Quot.sound]
'fp_ms_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpM_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpM_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpM_zero_of' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpN_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpN_eq_fpM' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpM_binom' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpM_odd' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_forall_Icc_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_ivt' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_never_level_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_card_avoid_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpW_cons' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpW_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpW_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_exists_Icc_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPsi_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_mono' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_symm' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_bdd' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPhi_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpH_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpH_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpH_rec' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpH_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpH_symm' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpHN_rec' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpHN_gen' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpH_level' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_return_value' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPsi_tendsto_ne' depends on axioms: [propext, Classical.choice, Quot.sound]
'fpPsi_tendsto_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_law' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_ae_pm' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_score_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_walk_meas' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_event_hit' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_event_avoid' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_hit_set' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_hit_prob' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_count_avoid' depends on axioms: [propext, Classical.choice, Quot.sound]
'fp_harmonic_odd' depends on axioms: [propext, Classical.choice, Quot.sound]
'fair_walk_hits_every_level_surely_with_infinite_mean_wait' depends on axioms: [propext, Classical.choice, Quot.sound]
'walk_arrival_and_return_chances' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_never_level_eq_choose' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run.
> - **Deepen the floor.** In road 4, add 10000 to the first list of floors, `(10, 100, 1000)`. The new row gives an average wait for +1 or −10,000 of 10,000 rounds: it equals the floor's depth, with no ceiling.
> - **Change the seed.** Replace `20260929` with another number. The three simulated lines move, typically by about one standard error, and stay near their formulas; the exact roads do not move at all.
> - **Tilt towards the target.** In the last line of road 4, change 0.6 to 0.55 and 0.4 to 0.45. The wait for +1 then averages 10 rounds, against 5 at p = 0.6: it is 1/(p − q), and as p falls to 0.5 it grows without bound.

---

## The usual mistake

> [!warning]
> **Reading "probability 1" as "soon on average".** The fair score is level again for sure, half the time within 2 rounds, yet the average wait is infinite. Rare long waits carry the average: 1 match in 40 still waits after 1,000 rounds.
>
> - **Counting from round 0.** With n ≥ 0 in the definition the return time would be 0, since the score starts level.
> - **"Wait until ahead" beats a fair game.** Stopping when Ana is first $1 ahead wins $1 for sure. The stopping time has no bound and needs unlimited credit; [Stopping times](../02-Martingales/03-stopping-times-and-optional-stopping.md) shows where the fair-game theorem stops applying.
> - **Carrying fair answers to a tilted coin.** At p = 0.4 the chance of ever being $3 ahead is 0.296296, not 1.

---

## Where you meet it in real life

- **Waiting to get back to even.** A position held "until it comes back" on a fair random walk gets there for sure in the model, after an infinite average wait and with no bound on the credit needed.
- **Long leads in fair contests.** The chance of no tie in the first 100 rounds of a fair match is 0.079589, about 1 in 13.
- **Default as a first passage.** Structural credit models call a firm in default the first time its assets hit a barrier: [Black-Cox](../../12-Financial%20mathematics/43-Structural%20Models%20-%20Default%20from%20the%20Balance%20Sheet/05-black-cox-first-passage-default.md).
- **Wandering particles.** A molecule hopping on a line or a flat grid returns for sure; on a three-dimensional grid it may never return (Pólya).
- **Any Markov chain.** Recurrent and transient are the words for every chain: [Classifying states](../03-Markov%20Chains/03-classifying-states.md).

> **Say it back**
> A hitting time is the first round a walk stands on a chosen level; the return time is the first round back at the start. The chance of ever climbing one level solves a quadratic, and a floor moved away picks the root: 1 when fair, p/q when tilted away. The chance of ever returning is one minus the gap between p and q, so only the fair walk surely comes back. For it, the chance of still waiting after 2n rounds equals the chance of a tie at 2n, shrinking like one over the square root of n. That is too slow for a finite average: return is certain, and the mean wait is infinite.

---

## What this builds on

- [Gambler's ruin](04-gamblers-ruin.md): the chance of the top before the floor, and the average duration b × 1, which this card pushes to an infinite floor.
- [Reflection principle](05-reflection-principle-for-walks.md): the path swap that turns "never level" into "level at the end".

## Where this goes next

- [Stopping times](../02-Martingales/03-stopping-times-and-optional-stopping.md): the hitting time as the model stopping time, and "wait until ahead" as the unbounded counterexample.
- [Stopping without a bound](../02-Martingales/06-uniform-integrability-and-unbounded-stopping.md): the extra condition under which an unbounded hitting time is safe to stop at.
- [Classifying states](../03-Markov%20Chains/03-classifying-states.md): recurrence and transience for any chain.
- [Absorption](../03-Markov%20Chains/06-absorption-and-first-step-analysis.md): Step 1's first-step equation, solved on any finite chain.
- [Reflection principle](../05-Brownian%20Motion/04-reflection-principle-and-running-maximum.md): the same hitting times for the walk seen from far away, Brownian motion.

What this card leaves open: when stopping a fair game at such an unbounded time keeps it fair.

---

## Sources

Verified 2026-09-30: every link below resolves to the publisher's page.

- Feller, William. *An Introduction to Probability Theory and Its Applications*, Volume 1, 3rd ed. Wiley, 1968. [Publisher page](https://www.wiley.com/en-us/An+Introduction+to+Probability+Theory+and+Its+Applications%2C+Volume+1%2C+3rd+Edition-p-9780471257080). Chapter III proves that no return by round 2n has the chance of a tie at 2n; the later chapters on generating functions take the other door.
- Norris, J. R. *Markov Chains*. Cambridge University Press, 1997. [Publisher page](https://www.cambridge.org/core/books/markov-chains/A3F966B10633A32C8F06F37158031739). Hitting probabilities as the smallest solution of the first-step equations, and recurrence of the simple walk.
- Pólya, Georg. "Über eine Aufgabe der Wahrscheinlichkeitsrechnung betreffend die Irrfahrt im Straßennetz." *Mathematische Annalen* 84 (1921): 149–160. [doi:10.1007/BF01458701](https://doi.org/10.1007/BF01458701). The original: sure return on the line and the plane, not in space.
