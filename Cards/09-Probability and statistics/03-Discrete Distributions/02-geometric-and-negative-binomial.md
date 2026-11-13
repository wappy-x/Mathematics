# Waiting for a success: how many tries until the first, and until the r-th

[Syllabus](../../../SYLLABUS.md) → [Probability and statistics](../README.md) → [Discrete Distributions](../README.md#s03) → Waiting for a success

---

## General Overview

A board game says: roll a fair die, and you may not leave the start square until you throw a six. How many rolls does that take?

The count is random, but its pattern is not. The first six lands on roll 1 with chance 0.166667, and on roll 5 with chance 0.080376: about 8 games in 100. The wait averages exactly 6 rolls, yet just over half of all waits are over by roll 4. A rule that asks for three sixes gives a wait averaging 18 rolls.

The rolls up to and including the first six follow the **geometric law**. The rolls up to and including the third six, or the r-th, follow the **negative binomial law**. Both come from two facts: the rolls do not influence each other, and every roll has the same chance.

The geometric wait also forgets. After ten misses, the wait still to come is as long, on average, as a wait from scratch. That is **memorylessness**, and among waits counted in whole tries only the geometric has it.

**Count the tries up to and including each success; independent tries with a fixed chance make the first-success wait geometric, with mean one over the chance, and the r-th-success wait a sum of r such waits.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, about a model: fair, independent rolls with the same chance each time.

### The picture: when the first six and the third six land

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Chance that the six lands on exactly roll k, fair die"
    x-axis "Roll number k" [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
    y-axis "Probability" 0 --> 0.18
    bar [0.1667, 0.1389, 0.1157, 0.0965, 0.0804, 0.0670, 0.0558, 0.0465, 0.0388, 0.0323, 0.0269, 0.0224, 0.0187, 0.0156, 0.0130, 0.0108, 0.0090, 0.0075, 0.0063, 0.0052, 0.0043, 0.0036, 0.0030, 0.0025, 0.0021]
    line [0.0000, 0.0000, 0.0046, 0.0116, 0.0193, 0.0268, 0.0335, 0.0391, 0.0434, 0.0465, 0.0485, 0.0493, 0.0493, 0.0486, 0.0473, 0.0454, 0.0433, 0.0409, 0.0383, 0.0357, 0.0330, 0.0304, 0.0279, 0.0255, 0.0231]
```

Bars: the first six (geometric); each bar is five sixths of the one before. Line: the third six (negative binomial); it cannot land before roll 3 and peaks at rolls 12 and 13. Both tails run past roll 25.

---

## The formula

Notation first, in words. $p$ is the chance of a six on one roll, here 1/6, and $q = 1 - p$ the chance of a miss. As on the [Binomial](01-bernoulli-and-binomial.md) card, a capital letter is a random count and $P(X = k)$ is the chance it takes the value $k$. $P(A \mid B)$ is the chance of A given B. $E[X]$ is the average value of $X$ in the long run, and $\operatorname{Var}(X)$ its variance: the average squared distance from that mean. "$X \sim \text{Geometric}(p)$" is read "X follows the geometric law with chance p".

The first six. Let $X$ be the roll on which it lands.

$$P(X = k) = q^{\,k-1}\,p, \qquad k = 1, 2, 3, \dots$$

**Read it aloud:** the chance the first six comes on roll k is the chance of k − 1 misses in a row, times the chance of a six.

The tail, the mean and the variance:

$$P(X > k) = q^{\,k}, \qquad E[X] = \frac{1}{p}, \qquad \operatorname{Var}(X) = \frac{q}{p^2}.$$

Memorylessness, for any whole numbers $s, t \ge 0$ (with p below 1, so that s misses can happen):

$$P(X > s + t \mid X > s) = P(X > t).$$

**Read it aloud:** given s misses so far, the chance of t more misses is the same as if no roll had yet been made.

The r-th six. A rule may ask for $r$ sixes; let $T_r$ be the roll on which the r-th lands, so $T_1 = X$.

$$P(T_r = k) = \binom{k-1}{r-1}\,p^{\,r}\,q^{\,k-r}, \qquad k = r, r+1, \dots$$

$$E[T_r] = \frac{r}{p}, \qquad \operatorname{Var}(T_r) = \frac{r\,q}{p^2}.$$

**Read it aloud:** roll k must be a six, and the other r − 1 sixes can sit anywhere among the first k − 1 rolls.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $p$ | chance of a success (a six) on one try | 1/6 = 0.166667 | waits shorten; mean 1/p falls |
| $q$ | chance of a miss, 1 − p | 5/6 = 0.833333 | waits lengthen; tails fatten |
| $X$ | rolls up to and including the first six | often 1 to 10; mean 6 | — |
| $k$ | one particular roll number | 5 | its chance shrinks by q per roll |
| $r$ | how many sixes the wait needs | 3 | mean r/p grows in step |
| $T_r$, $T_3$ | the roll on which the r-th six lands; $T_3$ for the third | mean 18 | — |
| $G_1$, $G_2$, $G_3$ | the gaps: rolls from one six to the next | each with mean 6 | — |
| $s$, $t$ | rolls already missed; further rolls asked about | 4 missed, 3 more | memoryless: s has no effect |
| $n$ | a fixed number of rolls | 12 or 18 | P(T_r > n) falls |
| $\binom{k-1}{r-1}$ | ways to place the earlier r − 1 sixes among k − 1 rolls | C(4, 2) = 6 | more placements, more chance |
| $E[X]$ | the long-run average wait | 6 rolls | — |
| $\operatorname{Var}(X)$ | variance: average squared distance from the mean | 30 (rolls squared) | wider spread of waits |
| $\sqrt{\operatorname{Var}(X)}$ | standard deviation: the square root of the variance, a typical distance from the mean | 5.477226 rolls | wider spread of waits |

### When it holds

- **Independent tries.** Drop this and pattern chances no longer multiply: dealing six cards numbered 1 to 6 until the 6 appears takes 3.5 turns on average, not 6.
- **The same chance every try.** If p drifts (a machine wearing out), each roll needs its own chance and the q^(k−1) pattern breaks.
- **p above zero.** With p = 0 no six ever comes. With p = 1 the wait is exactly r tries.
- **Counting tries, not misses.** Counting only misses shifts the law down by r and the mean to r q/p.

---

## Why it works

### Step 0: every roll is a fresh start

A wait is a pattern: some misses, then a six. Independence says the chance of a pattern is the product of the chances of its rolls. And after any miss, the problem left over is the problem there at the start. Everything below uses one of those two facts.

### Step 1: the geometric mass, and why the wait ends

The first six lands on roll k exactly when rolls 1 to k − 1 miss and roll k hits. Multiply:

$$P(X = k) = \underbrace{q \times q \times \cdots \times q}_{k-1 \text{ misses}} \times p = q^{\,k-1} p.$$

These chances add up to 1. The sum $p(1 + q + q^2 + \cdots)$ is a geometric series with ratio q below 1, so it equals $p / (1 - q) = p / p = 1$. The law takes its name from that series. So the wait ends with probability 1, even though no fixed number of rolls guarantees a six.

### Step 2: the tail is one line

"No six yet after k rolls" means the first k rolls all missed. That is one pattern, with chance

$$P(X > k) = q^{\,k}.$$

No summing needed. For the die, $P(X > 3) = (5/6)^3 = 0.578704$.

### Step 3: the mean, by restarting

Roll once. With chance p the wait is over after 1 roll. With chance q it missed, one roll is spent, and a fresh wait of the same law begins.

```mermaid
flowchart LR
    A["Roll once<br/>(1 roll spent)"] -->|"six: chance p"| B["Done"]
    A -->|"miss: chance q"| C["Start again:<br/>a fresh wait, same law"]
    C --> A
```

Averaging over the two branches:

$$E[X] = 1 + q\,E[X] \quad\Longrightarrow\quad (1 - q)\,E[X] = 1 \quad\Longrightarrow\quad E[X] = \frac{1}{p}.$$

A second road: a wait of length X is "still waiting" after 0, 1, …, X − 1 rolls, X checkpoints in all, so $E[X] = \sum_{j \ge 0} P(X > j) = 1 + q + q^2 + \cdots = 1/p$. For the die, 6 rolls. Restarting on the square of X gives the variance $q/p^2 = 30$ (detailed proof below).

### Step 4: memorylessness

Given s misses, the chance of t more is a ratio of two tails from Step 2:

$$P(X > s + t \mid X > s) = \frac{q^{\,s+t}}{q^{\,s}} = q^{\,t} = P(X > t).$$

After four misses, the chance of three more is 0.578704, the same as from a standing start. Conversely, a wait in whole tries that forgets its past must be geometric (detailed proof below).

### Step 5: the negative binomial mass

The r-th six lands on roll k exactly when two things happen together. Roll k is a six. And the first k − 1 rolls hold exactly r − 1 sixes. The second event is a binomial count (the [Binomial](01-bernoulli-and-binomial.md) card): its chance is $\binom{k-1}{r-1} p^{r-1} q^{k-r}$. The two involve different rolls, so they multiply:

$$P(T_r = k) = \binom{k-1}{r-1}\,p^{\,r-1} q^{\,k-r} \times p = \binom{k-1}{r-1}\,p^{\,r}\,q^{\,k-r}.$$

### Step 6: the r-th wait is r first waits laid end to end

Cut the wait for the third six at each six. $G_1$ rolls to the first six, then $G_2$ more to the second, then $G_3$ more to the third:

$$T_3 = G_1 + G_2 + G_3.$$

By Step 0, the rolls after a six start a fresh wait, so each gap is geometric with the same p, and the gaps are independent: each uses its own rolls. Averages add, so $E[T_3] = 3 \times 6 = 18$. For independent counts variances also add (the [Adding counts](06-sums-of-discrete-variables.md) card), so $\operatorname{Var}(T_3) = 3 \times 30 = 90$.

The negative binomial is not memoryless. After two rolls, both may already be sixes, and then one more six ends the wait. So $P(T_3 > 3 \mid T_3 > 2) = 1 - p^3 = 0.995370$, while from scratch $P(T_3 > 1) = 1$. The wait remembers progress.

### Step 7: the same event, counted two ways

The third six comes after roll n exactly when the first n rolls hold fewer than three sixes. So one tail can be read off the binomial, adding the chances of j = 0, 1 or 2 sixes in n rolls:

$$P(T_3 > n) = \sum_{j=0}^{2} \binom{n}{j} p^{\,j} q^{\,n-j}.$$

For n = 18 both sides give 0.402654: the wait for the third six overshoots its own mean of 18 rolls about 40 times in 100.

<details>
<summary>Detailed proof</summary>

**The masses sum to 1 (negative binomial).** By Step 6, $T_r = G_1 + \cdots + G_r$ with each gap finite with probability 1 (Step 1), so $T_r$ is finite with probability 1 and its masses, which partition that event by the value of k, add to 1.

**The variance of X, by restarting.** Write $X = 1 + X'$ on a miss, where $X'$ is a fresh wait with the same law, and $X = 1$ on a six. Square and average:
$$E[X^2] = p \cdot 1 + q\,E[(1 + X')^2] = 1 + 2q\,E[X] + q\,E[X^2].$$
So $p\,E[X^2] = 1 + 2q/p$, which gives $E[X^2] = (p + 2q)/p^2 = (2 - p)/p^2$. Subtract the squared mean:
$$\operatorname{Var}(X) = \frac{2 - p}{p^2} - \frac{1}{p^2} = \frac{1 - p}{p^2} = \frac{q}{p^2}.$$
For p = 1/6: $(5/6) \times 36 = 30$. The restart step is legitimate because $E[X^2]$ is finite: $\sum k^2 q^{k-1}$ converges by the ratio test.

**Only the geometric forgets.** Let $S(k) = P(X > k)$ for a wait in whole tries, with $S(0) = 1$. Memorylessness with every s and t says $S(s + t) = S(s)\,S(t)$. Put $a = S(1)$. Then $S(2) = a^2$, $S(3) = a^3$, and by induction $S(k) = a^k$. So $P(X = k) = S(k-1) - S(k) = a^{k-1}(1 - a)$: geometric with chance $p = 1 - a$.

**Tail-sum formula.** For a count taking values 1, 2, …, $X = \sum_{j \ge 0} \mathbf{1}[X > j]$, where $\mathbf{1}[\cdot]$ is 1 when the bracket is true and 0 otherwise. The terms are never negative, so the average can be taken term by term: $E[X] = \sum_{j \ge 0} P(X > j)$.

</details>

When a wait can end at any instant, not only at whole tries, it becomes the exponential law of the [Exponential](../04-Continuous%20Distributions/03-exponential-distribution.md) card, reached through the [Poisson](04-poisson.md) card's arrivals.

---

## Worked numbers, by hand

The fair die: p = 1/6, q = 5/6.

| Step | Arithmetic | Value |
| --- | --- | --- |
| first six on roll 5 | (5/6)^4 × 1/6 = 625/7776 | 0.080376 |
| no six in the first 3 rolls | (5/6)^3 = 125/216 | 0.578704 |
| a six within 4 rolls | 1 − (5/6)^4 | 0.517747 |
| a six within 6 rolls | 1 − (5/6)^6 | 0.665102 |
| mean wait for the first six | 1 / (1/6) | 6 |
| its variance | (5/6) / (1/36) | 30 |
| its standard deviation | √30 | 5.477226 |
| third six on roll 5 | C(4, 2) × (1/6)^3 × (5/6)^2 = 6 × 25/7776 | 0.019290 |
| variance for the third six | 3 × 30 | 90 |
| standard deviation for the third six | √90 | 9.486833 |
| **mean wait for the third six** | 3 × 6 | **18** |

One six takes 6 rolls on average, give or take about 5.5; three take 18, give or take about 9.5. The mean triples, the standard deviation grows only by √3.

The shelf's house example runs the same way in time. A help desk gets 12 emails an hour on average. Model each of its 3,600 seconds as a try with chance 12/3600: the wait for the first email is geometric, with mean 300 seconds.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Count only the misses | mean 5 (right: 6) | The six is a roll too; misses-only has mean q/p. |
| Take the third-six wait as three times one wait | variance 270 (right: 90) | The gaps are independent, so variances add: 30 + 30 + 30. |
| Deal six cards numbered 1 to 6, turn until the 6 | mean 3.5; after five misses, next-card chance 1.000000 (not 0.166667) | No replacement: independence and memorylessness both fail. |
| Read the mean as the typical wait | "half need 6 rolls or more" | P(X ≤ 6) = 0.665102; half are done by roll 4. |

---

## Code, from first principles, and it actually runs

Five roads to the same numbers: the formula; a count over all 46,656 equally likely sequences of six rolls; the masses summed term by term out to roll 600; the binomial count of sixes; and a simulation of 200,000 first-six waits and 100,000 third-six waits from a SplitMix64 generator (seed 20260928) written out in both languages, so both draw identical rolls. Simulated numbers carry their standard errors (the typical size of the chance error in a simulated result), and the asserts allow four of them.

### Python

```python
# Geometric and negative binomial -- the check behind the card.  Standard library only.
# Rolling a fair die until the first six (X), and until the third six (T3).
# Roads: the formula; a count over all 6^6 sequences of six rolls; the masses summed
# term by term; the binomial count of sixes; a seeded simulation (SplitMix64).
from math import sqrt

p, q, M64 = 1.0 / 6.0, 5.0 / 6.0, (1 << 64) - 1

def pw(x, n):                        # x to the power n, by repeated multiplication
    out = 1.0
    for _ in range(n):
        out *= x
    return out
def comb(n, k):                      # C(n, k), exact in integers
    out = 1
    for j in range(1, k + 1):
        out = out * (n - k + j) // j
    return out
def geo(k):                          # P(X = k): k-1 misses, then a six
    return pw(q, k - 1) * p
def negbin(r, k):                    # P(T_r = k): r-1 sixes in the first k-1 rolls, then a six
    return comb(k - 1, r - 1) * pw(p, r) * pw(q, k - r) if k >= r else 0.0
def row(label, v): print(f"{label:<46}{v:>12.6f}")

# ---- road 1: the formula ----
for label, v in (("formula  P(X=1)", geo(1)), ("formula  P(X=5)", geo(5)),
                 ("formula  P(X>3)  no six in 3 rolls", pw(q, 3)),
                 ("formula  P(X<=4) a six within 4 rolls", 1.0 - pw(q, 4)),
                 ("formula  P(X<=6) a six within 6 rolls", 1.0 - pw(q, 6)),
                 ("formula  P(X>20) no six in 20 rolls", pw(q, 20)),
                 ("formula  E[X] = 1/p", 1.0 / p), ("formula  Var(X) = q/p^2", q / (p * p)),
                 ("formula  sd(X)", sqrt(q / (p * p))), ("formula  P(T3=5)", negbin(3, 5)),
                 ("formula  E[T3] = 3/p", 3.0 / p), ("formula  Var(T3) = 3q/p^2", 3.0 * q / (p * p)),
                 ("formula  sd(T3)", sqrt(3.0 * q / (p * p))),
                 ("formula  P(T3>3 | T3>2) = 1 - p^3", 1.0 - pw(p, 3))):
    row(label, v)

# ---- road 2: count every sequence of six rolls (6^6 = 46656, all equally likely) ----
first5 = third5 = none2 = none3 = none5 = 0
for code in range(6 ** 6):
    sixes, c = [], code
    for i in range(1, 7):
        if c % 6 == 5: sixes.append(i)
        c //= 6
    first = sixes[0] if sixes else 99
    first5 += first == 5
    third5 += len(sixes) >= 3 and sixes[2] == 5
    none2 += first > 2; none3 += first > 3; none5 += first > 5
print(f"{'count  of 46656 sequences, first six on roll 5':<46}{first5:>12d}")
print(f"{'count  of 46656 sequences, third six on roll 5':<46}{third5:>12d}")
row("count  P(X=5)", first5 / 46656)
row("count  P(T3=5)", third5 / 46656)
row("count  P(X>5 | X>2)", none5 / none2)
row("count  P(X>3)", none3 / 46656)

# ---- road 3: sum the masses term by term, out to roll 600 ----
tx = m1 = m2 = tt = t1 = t2 = 0.0
for k in range(1, 601):
    gx, gt = geo(k), negbin(3, k)
    tx += gx; m1 += k * gx; m2 += k * k * gx
    tt += gt; t1 += k * gt; t2 += k * k * gt
for label, v in (("series  total mass of X, rolls 1 to 600", tx), ("series  E[X]", m1), ("series  Var(X)", m2 - m1 * m1),
                 ("series  total mass of T3", tt), ("series  E[T3]", t1), ("series  Var(T3)", t2 - t1 * t1)):
    row(label, v)

# ---- road 4: the third six comes after roll n exactly when n rolls hold fewer than 3 sixes ----
tails = []
for n in (12, 18):
    by_binom = sum(comb(n, j) * pw(p, j) * pw(q, n - j) for j in range(3))
    by_mass = 1.0 - sum(negbin(3, k) for k in range(3, n + 1))
    row(f"binomial  P(fewer than 3 sixes in {n} rolls)", by_binom)
    row(f"negbin    P(T3 > {n})", by_mass)
    tails.append((by_binom, by_mass))

# ---- road 5: seeded simulation, SplitMix64 ----
state = 20260928
def die():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    z ^= z >> 31
    return ((z * 6) >> 64) + 1       # a face from 1 to 6
def wait_for(r):
    n = got = 0
    while got < r:
        n += 1
        if die() == 6: got += 1
    return n

def mean_se(s, s2, n): return s / n, sqrt((s2 - s * s / n) / (n - 1) / n)

N, NT = 200000, 100000
s = s2 = past4 = past7 = 0
for _ in range(N):
    x = wait_for(1)
    s += x; s2 += x * x; past4 += x > 4; past7 += x > 7
mx, sex = mean_se(s, s2, N)
frac = past7 / past4
se_frac = sqrt(frac * (1.0 - frac) / past4)
s = s2 = 0
for _ in range(NT):
    t = wait_for(3)
    s += t; s2 += t * t
mt, set3 = mean_se(s, s2, NT)
for label, v in (("sim  mean wait for first six, 200000 runs", mx), ("sim    standard error", sex),
                 ("sim  P(X>7 | X>4)", frac), ("sim    standard error", se_frac),
                 ("sim  mean wait for third six, 100000 runs", mt), ("sim    standard error", set3)):
    row(label, v)

# ---- what breaks ----
deal = sum((6 - j) / 6 for j in range(6))       # six cards, no replacement: P(the 6 not in first j)
for label, v in (("wrong: count misses only, mean q/p", q / p),
                 ("wrong: T3 as 3 copies of one wait, Var 9q/p^2", 9.0 * q / (p * p)),
                 ("wrong: deal 6 cards, mean draws to the 6", deal),
                 ("wrong: deal, P(6 next | 5 misses)", (1 / 6) / ((6 - 5) / 6)),
                 # ---- try changing ----
                 ("try: coin, p=1/2, mean", 1.0 / 0.5), ("try: coin, p=1/2, variance", 0.5 / (0.5 * 0.5)),
                 ("try: r=10 sixes, mean", 10.0 / p), ("try: r=10 sixes, sd", sqrt(10.0 * q / (p * p))),
                 ("try: p=1/100, mean", 1.0 / 0.01), ("try: p=1/100, sd", sqrt(0.99 / (0.01 * 0.01))),
                 ("house: emails 12/3600 a second, mean wait s", 1.0 / (12.0 / 3600.0))):
    row(label, v)

# ---- chart points, rolls 1 to 25 ----
print("chart, k       " + " ".join(f"{k:d}" for k in range(1, 26)))
print("chart, P(X=k)  " + " ".join(f"{geo(k):.4f}" for k in range(1, 26)))
print("chart, P(T3=k) " + " ".join(f"{negbin(3, k):.4f}" for k in range(1, 26)))

assert first5 == 5 ** 4 * 6, "count of sequences vs 4 misses, a six, any sixth roll"
assert abs(third5 / 46656 - negbin(3, 5)) < 1e-15, "count vs negative binomial mass"
assert abs(none5 / none2 - none3 / 46656) < 1e-15 and abs(none3 / 46656 - pw(q, 3)) < 1e-12, "memoryless and tail, by counting"
assert abs(m1 - 1.0 / p) < 1e-9 and abs(m2 - m1 * m1 - q / (p * p)) < 1e-9, "series mean and variance vs 1/p, q/p^2"
assert abs(t2 - t1 * t1 - 3.0 * q / (p * p)) < 1e-9, "series variance vs rq/p^2"
assert all(abs(a - b) < 1e-12 for a, b in tails), "binomial tail vs negative binomial tail"
assert abs(mx - 6.0) < 4 * sex, "simulated first-six wait within 4 standard errors"
assert abs(mt - 18.0) < 4 * set3, "simulated third-six wait within 4 standard errors"
assert abs(frac - 125 / 216) < 4 * se_frac, "simulated memorylessness vs (5/6)^3"
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
formula  P(X=1)                                   0.166667
formula  P(X=5)                                   0.080376
formula  P(X>3)  no six in 3 rolls                0.578704
formula  P(X<=4) a six within 4 rolls             0.517747
formula  P(X<=6) a six within 6 rolls             0.665102
formula  P(X>20) no six in 20 rolls               0.026084
formula  E[X] = 1/p                               6.000000
formula  Var(X) = q/p^2                          30.000000
formula  sd(X)                                    5.477226
formula  P(T3=5)                                  0.019290
formula  E[T3] = 3/p                             18.000000
formula  Var(T3) = 3q/p^2                        90.000000
formula  sd(T3)                                   9.486833
formula  P(T3>3 | T3>2) = 1 - p^3                 0.995370
count  of 46656 sequences, first six on roll 5        3750
count  of 46656 sequences, third six on roll 5         900
count  P(X=5)                                     0.080376
count  P(T3=5)                                    0.019290
count  P(X>5 | X>2)                               0.578704
count  P(X>3)                                     0.578704
series  total mass of X, rolls 1 to 600           1.000000
series  E[X]                                      6.000000
series  Var(X)                                   30.000000
series  total mass of T3                          1.000000
series  E[T3]                                    18.000000
series  Var(T3)                                  90.000000
binomial  P(fewer than 3 sixes in 12 rolls)       0.677426
negbin    P(T3 > 12)                              0.677426
binomial  P(fewer than 3 sixes in 18 rolls)       0.402654
negbin    P(T3 > 18)                              0.402654
sim  mean wait for first six, 200000 runs         6.028130
sim    standard error                             0.012266
sim  P(X>7 | X>4)                                 0.581852
sim    standard error                             0.001584
sim  mean wait for third six, 100000 runs        18.051010
sim    standard error                             0.030108
wrong: count misses only, mean q/p                5.000000
wrong: T3 as 3 copies of one wait, Var 9q/p^2   270.000000
wrong: deal 6 cards, mean draws to the 6          3.500000
wrong: deal, P(6 next | 5 misses)                 1.000000
try: coin, p=1/2, mean                            2.000000
try: coin, p=1/2, variance                        2.000000
try: r=10 sixes, mean                            60.000000
try: r=10 sixes, sd                              17.320508
try: p=1/100, mean                              100.000000
try: p=1/100, sd                                 99.498744
house: emails 12/3600 a second, mean wait s     300.000000
chart, k       1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
chart, P(X=k)  0.1667 0.1389 0.1157 0.0965 0.0804 0.0670 0.0558 0.0465 0.0388 0.0323 0.0269 0.0224 0.0187 0.0156 0.0130 0.0108 0.0090 0.0075 0.0063 0.0052 0.0043 0.0036 0.0030 0.0025 0.0021
chart, P(T3=k) 0.0000 0.0000 0.0046 0.0116 0.0193 0.0268 0.0335 0.0391 0.0434 0.0465 0.0485 0.0493 0.0493 0.0486 0.0473 0.0454 0.0433 0.0409 0.0383 0.0357 0.0330 0.0304 0.0279 0.0255 0.0231
ALL CHECKS PASS
```

### Rust

```rust
// Geometric and negative binomial -- the same check as the Python, in Rust.  Std only, no crates.
// Rolling a fair die until the first six (X), and until the third six (T3).
// Roads: the formula; a count over all 6^6 sequences of six rolls; the masses summed
// term by term; the binomial count of sixes; a seeded simulation (SplitMix64).
const P: f64 = 1.0 / 6.0;
const Q: f64 = 5.0 / 6.0;

fn pw(x: f64, n: u32) -> f64 {        // x to the power n, by repeated multiplication
    let mut out = 1.0;
    for _ in 0..n { out *= x; }
    out
}
fn comb(n: u64, k: u64) -> u64 {      // C(n, k), exact in integers
    let mut out = 1u64;
    for j in 1..=k { out = out * (n - k + j) / j; }
    out
}
fn geo(k: u32) -> f64 {               // P(X = k): k-1 misses, then a six
    pw(Q, k - 1) * P
}
fn negbin(r: u32, k: u32) -> f64 {    // P(T_r = k): r-1 sixes in the first k-1 rolls, then a six
    if k >= r { comb((k - 1) as u64, (r - 1) as u64) as f64 * pw(P, r) * pw(Q, k - r) } else { 0.0 }
}
fn row(label: &str, v: f64) {
    println!("{:<46}{:>12.6}", label, v);
}

struct SplitMix(u64);
impl SplitMix {
    fn die(&mut self) -> u64 {            // a face from 1 to 6
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (((z as u128) * 6) >> 64) as u64 + 1
    }
    fn wait_for(&mut self, r: u32) -> u64 {
        let (mut n, mut got) = (0u64, 0u32);
        while got < r {
            n += 1;
            if self.die() == 6 { got += 1; }
        }
        n
    }
}
fn mean_se(s: u64, s2: u64, n: u64) -> (f64, f64) {
    let (sf, nf) = (s as f64, n as f64);
    (sf / nf, ((s2 as f64 - sf * sf / nf) / (nf - 1.0) / nf).sqrt())
}

fn main() {
    // ---- road 1: the formula ----
    for (label, v) in [
        ("formula  P(X=1)", geo(1)), ("formula  P(X=5)", geo(5)),
        ("formula  P(X>3)  no six in 3 rolls", pw(Q, 3)),
        ("formula  P(X<=4) a six within 4 rolls", 1.0 - pw(Q, 4)),
        ("formula  P(X<=6) a six within 6 rolls", 1.0 - pw(Q, 6)),
        ("formula  P(X>20) no six in 20 rolls", pw(Q, 20)),
        ("formula  E[X] = 1/p", 1.0 / P), ("formula  Var(X) = q/p^2", Q / (P * P)),
        ("formula  sd(X)", (Q / (P * P)).sqrt()), ("formula  P(T3=5)", negbin(3, 5)),
        ("formula  E[T3] = 3/p", 3.0 / P), ("formula  Var(T3) = 3q/p^2", 3.0 * Q / (P * P)),
        ("formula  sd(T3)", (3.0 * Q / (P * P)).sqrt()),
        ("formula  P(T3>3 | T3>2) = 1 - p^3", 1.0 - pw(P, 3)),
    ] {
        row(label, v);
    }

    // ---- road 2: count every sequence of six rolls (6^6 = 46656, all equally likely) ----
    let (mut first5, mut third5, mut none2, mut none3, mut none5) = (0u64, 0u64, 0u64, 0u64, 0u64);
    for code in 0..6u64.pow(6) {
        let (mut sixes, mut c) = (Vec::new(), code);
        for i in 1..=6u32 {
            if c % 6 == 5 { sixes.push(i); }
            c /= 6;
        }
        let first = if sixes.is_empty() { 99 } else { sixes[0] };
        first5 += (first == 5) as u64;
        third5 += (sixes.len() >= 3 && sixes[2] == 5) as u64;
        none2 += (first > 2) as u64;
        none3 += (first > 3) as u64;
        none5 += (first > 5) as u64;
    }
    println!("{:<46}{:>12}", "count  of 46656 sequences, first six on roll 5", first5);
    println!("{:<46}{:>12}", "count  of 46656 sequences, third six on roll 5", third5);
    row("count  P(X=5)", first5 as f64 / 46656.0);
    row("count  P(T3=5)", third5 as f64 / 46656.0);
    row("count  P(X>5 | X>2)", none5 as f64 / none2 as f64);
    row("count  P(X>3)", none3 as f64 / 46656.0);

    // ---- road 3: sum the masses term by term, out to roll 600 ----
    let (mut tx, mut m1, mut m2, mut tt, mut t1, mut t2) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    for k in 1..=600u32 {
        let (gx, gt, kf) = (geo(k), negbin(3, k), k as f64);
        tx += gx; m1 += kf * gx; m2 += kf * kf * gx;
        tt += gt; t1 += kf * gt; t2 += kf * kf * gt;
    }
    for (label, v) in [("series  total mass of X, rolls 1 to 600", tx), ("series  E[X]", m1), ("series  Var(X)", m2 - m1 * m1),
                       ("series  total mass of T3", tt), ("series  E[T3]", t1), ("series  Var(T3)", t2 - t1 * t1)] {
        row(label, v);
    }

    // ---- road 4: the third six comes after roll n exactly when n rolls hold fewer than 3 sixes ----
    let mut tails = Vec::new();
    for n in [12u32, 18] {
        let by_binom = (0..3u32).fold(0.0, |a, j| a + comb(n as u64, j as u64) as f64 * pw(P, j) * pw(Q, n - j));
        let by_mass = 1.0 - (3..=n).fold(0.0, |a, k| a + negbin(3, k));
        row(&format!("binomial  P(fewer than 3 sixes in {} rolls)", n), by_binom);
        row(&format!("negbin    P(T3 > {})", n), by_mass);
        tails.push((by_binom, by_mass));
    }

    // ---- road 5: seeded simulation, SplitMix64 ----
    let mut rng = SplitMix(20260928);
    let (n1, nt) = (200000u64, 100000u64);
    let (mut s, mut s2, mut past4, mut past7) = (0u64, 0u64, 0u64, 0u64);
    for _ in 0..n1 {
        let x = rng.wait_for(1);
        s += x; s2 += x * x; past4 += (x > 4) as u64; past7 += (x > 7) as u64;
    }
    let (mx, sex) = mean_se(s, s2, n1);
    let frac = past7 as f64 / past4 as f64;
    let se_frac = (frac * (1.0 - frac) / past4 as f64).sqrt();
    let (mut s, mut s2) = (0u64, 0u64);
    for _ in 0..nt {
        let t = rng.wait_for(3);
        s += t; s2 += t * t;
    }
    let (mt, set3) = mean_se(s, s2, nt);
    for (label, v) in [("sim  mean wait for first six, 200000 runs", mx), ("sim    standard error", sex),
                       ("sim  P(X>7 | X>4)", frac), ("sim    standard error", se_frac),
                       ("sim  mean wait for third six, 100000 runs", mt), ("sim    standard error", set3)] {
        row(label, v);
    }

    // ---- what breaks, then try changing ----
    let deal = (0..6).fold(0.0, |a, j| a + (6 - j) as f64 / 6.0);   // six cards, no replacement
    for (label, v) in [
        ("wrong: count misses only, mean q/p", Q / P),
        ("wrong: T3 as 3 copies of one wait, Var 9q/p^2", 9.0 * Q / (P * P)),
        ("wrong: deal 6 cards, mean draws to the 6", deal),
        ("wrong: deal, P(6 next | 5 misses)", (1.0 / 6.0) / ((6.0 - 5.0) / 6.0)),
        ("try: coin, p=1/2, mean", 1.0 / 0.5), ("try: coin, p=1/2, variance", 0.5 / (0.5 * 0.5)),
        ("try: r=10 sixes, mean", 10.0 / P), ("try: r=10 sixes, sd", (10.0 * Q / (P * P)).sqrt()),
        ("try: p=1/100, mean", 1.0 / 0.01), ("try: p=1/100, sd", (0.99f64 / (0.01 * 0.01)).sqrt()),
        ("house: emails 12/3600 a second, mean wait s", 1.0 / (12.0 / 3600.0)),
    ] {
        row(label, v);
    }

    // ---- chart points, rolls 1 to 25 ----
    let ks: Vec<String> = (1..=25u32).map(|k| format!("{}", k)).collect();
    let gs: Vec<String> = (1..=25u32).map(|k| format!("{:.4}", geo(k))).collect();
    let ns: Vec<String> = (1..=25u32).map(|k| format!("{:.4}", negbin(3, k))).collect();
    println!("chart, k       {}", ks.join(" "));
    println!("chart, P(X=k)  {}", gs.join(" "));
    println!("chart, P(T3=k) {}", ns.join(" "));

    assert!(first5 == 5u64.pow(4) * 6, "count of sequences vs 4 misses, a six, any sixth roll");
    assert!((third5 as f64 / 46656.0 - negbin(3, 5)).abs() < 1e-15, "count vs negative binomial mass");
    assert!((none5 as f64 / none2 as f64 - none3 as f64 / 46656.0).abs() < 1e-15
        && (none3 as f64 / 46656.0 - pw(Q, 3)).abs() < 1e-12, "memoryless and tail, by counting");
    assert!((m1 - 1.0 / P).abs() < 1e-9 && (m2 - m1 * m1 - Q / (P * P)).abs() < 1e-9, "series mean and variance vs 1/p, q/p^2");
    assert!((t2 - t1 * t1 - 3.0 * Q / (P * P)).abs() < 1e-9, "series variance vs rq/p^2");
    assert!(tails.iter().all(|&(a, b)| (a - b).abs() < 1e-12), "binomial tail vs negative binomial tail");
    assert!((mx - 6.0).abs() < 4.0 * sex, "simulated first-six wait within 4 standard errors");
    assert!((mt - 18.0).abs() < 4.0 * set3, "simulated third-six wait within 4 standard errors");
    assert!((frac - 125.0 / 216.0).abs() < 4.0 * se_frac, "simulated memorylessness vs (5/6)^3");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
formula  P(X=1)                                   0.166667
formula  P(X=5)                                   0.080376
formula  P(X>3)  no six in 3 rolls                0.578704
formula  P(X<=4) a six within 4 rolls             0.517747
formula  P(X<=6) a six within 6 rolls             0.665102
formula  P(X>20) no six in 20 rolls               0.026084
formula  E[X] = 1/p                               6.000000
formula  Var(X) = q/p^2                          30.000000
formula  sd(X)                                    5.477226
formula  P(T3=5)                                  0.019290
formula  E[T3] = 3/p                             18.000000
formula  Var(T3) = 3q/p^2                        90.000000
formula  sd(T3)                                   9.486833
formula  P(T3>3 | T3>2) = 1 - p^3                 0.995370
count  of 46656 sequences, first six on roll 5        3750
count  of 46656 sequences, third six on roll 5         900
count  P(X=5)                                     0.080376
count  P(T3=5)                                    0.019290
count  P(X>5 | X>2)                               0.578704
count  P(X>3)                                     0.578704
series  total mass of X, rolls 1 to 600           1.000000
series  E[X]                                      6.000000
series  Var(X)                                   30.000000
series  total mass of T3                          1.000000
series  E[T3]                                    18.000000
series  Var(T3)                                  90.000000
binomial  P(fewer than 3 sixes in 12 rolls)       0.677426
negbin    P(T3 > 12)                              0.677426
binomial  P(fewer than 3 sixes in 18 rolls)       0.402654
negbin    P(T3 > 18)                              0.402654
sim  mean wait for first six, 200000 runs         6.028130
sim    standard error                             0.012266
sim  P(X>7 | X>4)                                 0.581852
sim    standard error                             0.001584
sim  mean wait for third six, 100000 runs        18.051010
sim    standard error                             0.030108
wrong: count misses only, mean q/p                5.000000
wrong: T3 as 3 copies of one wait, Var 9q/p^2   270.000000
wrong: deal 6 cards, mean draws to the 6          3.500000
wrong: deal, P(6 next | 5 misses)                 1.000000
try: coin, p=1/2, mean                            2.000000
try: coin, p=1/2, variance                        2.000000
try: r=10 sixes, mean                            60.000000
try: r=10 sixes, sd                              17.320508
try: p=1/100, mean                              100.000000
try: p=1/100, sd                                 99.498744
house: emails 12/3600 a second, mean wait s     300.000000
chart, k       1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
chart, P(X=k)  0.1667 0.1389 0.1157 0.0965 0.0804 0.0670 0.0558 0.0465 0.0388 0.0323 0.0269 0.0224 0.0187 0.0156 0.0130 0.0108 0.0090 0.0075 0.0063 0.0052 0.0043 0.0036 0.0030 0.0025 0.0021
chart, P(T3=k) 0.0000 0.0000 0.0046 0.0116 0.0193 0.0268 0.0335 0.0391 0.0434 0.0465 0.0485 0.0493 0.0493 0.0486 0.0473 0.0454 0.0433 0.0409 0.0383 0.0357 0.0330 0.0304 0.0279 0.0255 0.0231
ALL CHECKS PASS
```

The outputs agree byte for byte. Counting gives the formula's 0.080376 and 0.019290 exactly; the three simulated numbers sit within four standard errors of 6, 18 and 0.578704.

### Lean

Lean proves the card's rules for every chance p above 0 and every r of at least 1, and checks the worked arithmetic exactly.

- Take independent tries, each a success with the same chance p above 0. Then the first-success wait X ends with probability 1.
- Take the same tries. Then $P(X = k) = q^{\,k-1}\,p$ for every roll number k from 1 on.
- Take the same tries and any whole number k. Then $P(X > k) = q^{\,k}$.
- Take the same tries. Then $E[X] = 1/p$ and $\operatorname{Var}(X) = q/p^2$.
- Suppose also p is below 1, and s, t are whole numbers. Then $P(X > s + t \mid X > s) = P(X > t)$.
- Take the same tries and r at least 1. Then the r-th-success wait $T_r$ ends with probability 1.
- Take r at least 1 and k at least r. Then $P(T_r = k) = \binom{k-1}{r-1}\,p^{\,r}\,q^{\,k-r}$.
- Take r at least 1. Then $E[T_r] = r/p$ and $\operatorname{Var}(T_r) = r\,q/p^2$.
- The worked arithmetic: the die's chances, means and variances, the counted sequences, Step 7 for n = 12 and 18, and the mistakes.

The decimals, the count of sequences, the sums to roll 600, the simulation and the chart are left to the Python and Rust checks.

```lean
-- Waiting for a success: with independent tries that each succeed with the same chance p > 0, the wait for the first success ends for sure, lands on try k with chance (1 - p)^(k-1) p, averages 1/p tries with variance (1 - p)/p², forgets its past, and the wait for the r-th success lands on try k with chance C(k-1, r-1) p^r (1 - p)^(k-r), averaging r/p with variance r(1 - p)/p².
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.ConditionalProbability
import Mathlib.Probability.Moments.Variance
import Mathlib.Basic.Real.ENatENNReal
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.MeasureTheory.Integral.Lebesgue.Countable
import Mathlib.MeasureTheory.Function.L2Space

open MeasureTheory ProbabilityTheory
open scoped ENNReal

open Classical in
/-- The try on which the `r`-th success lands, counting tries from 1. Try `i + 1` is a success
exactly when the outcome `ω` lies in the event `A i`. The wait is the least `k` such that the
first `k` tries hold at least `r` successes, and `⊤` (it never ends) if there is no such `k`.
For `r = 1` this is the wait for the first success. -/
noncomputable def waitFor {Ω : Type*} (r : ℕ) (A : ℕ → Set Ω) (ω : Ω) : ℕ∞ :=
  ⨅ (k : ℕ) (_ : r ≤ ((Finset.range k).filter (fun i => ω ∈ A i)).card), (k : ℕ∞)

open Classical in
lemma gnb_waitFor_le_iff {Ω : Type*} (r : ℕ) (A : ℕ → Set Ω) (ω : Ω) (n : ℕ) :
    waitFor r A ω ≤ n ↔ r ≤ ((Finset.range n).filter (fun i => ω ∈ A i)).card := by
  constructor
  · intro h
    have h' : waitFor r A ω < ((n + 1 : ℕ) : ℕ∞) :=
      lt_of_le_of_lt h (by exact_mod_cast Nat.lt_succ_self n)
    unfold waitFor at h'
    rw [iInf_lt_iff] at h'
    obtain ⟨j, hj⟩ := h'
    rw [iInf_lt_iff] at hj
    obtain ⟨hrj, hjn⟩ := hj
    have hjn' : j ≤ n := by
      have : j < n + 1 := by exact_mod_cast hjn
      omega
    exact hrj.trans (Finset.card_le_card
      (Finset.filter_subset_filter _ (Finset.range_subset_range.2 hjn')))
  · intro h
    unfold waitFor
    exact iInf₂_le n h

open Classical in
lemma gnb_measurable_card {Ω : Type*} [MeasurableSpace Ω] (A : ℕ → Set Ω)
    (hA : ∀ i, MeasurableSet (A i)) (n : ℕ) :
    Measurable (fun ω => ((Finset.range n).filter (fun i => ω ∈ A i)).card) := by
  simp_rw [Finset.card_filter]
  exact Finset.measurable_sum _ (fun i _ => Measurable.ite (hA i) measurable_const measurable_const)

lemma gnb_enat_eq_succ_iff (x : ℕ∞) (k : ℕ) :
    x = ((k + 1 : ℕ) : ℕ∞) ↔ x ≤ ((k + 1 : ℕ) : ℕ∞) ∧ ¬ x ≤ (k : ℕ∞) := by
  induction x using ENat.recTopCoe with
  | top =>
    exact ⟨fun h => absurd h.symm (ENat.natCast_ne_top _),
      fun h => absurd (top_le_iff.1 h.1) (ENat.natCast_ne_top _)⟩
  | coe n => norm_cast; omega

lemma gnb_enat_eq_top_iff (x : ℕ∞) : x = ⊤ ↔ ∀ n : ℕ, ¬ x ≤ (n : ℕ∞) := by
  induction x using ENat.recTopCoe with
  | top => simp
  | coe n => simp only [ENat.natCast_ne_top, false_iff, not_forall, not_not]; exact ⟨n, le_rfl⟩

open Classical in
lemma gnb_measurable_waitFor {Ω : Type*} [MeasurableSpace Ω] (r : ℕ) (A : ℕ → Set Ω)
    (hA : ∀ i, MeasurableSet (A i)) : Measurable (waitFor r A) := by
  have hle : ∀ n : ℕ, MeasurableSet {ω | waitFor r A ω ≤ (n : ℕ∞)} := by
    intro n
    simp_rw [gnb_waitFor_le_iff]
    exact gnb_measurable_card A hA n (MeasurableSet.of_discrete (s := {k | r ≤ k}))
  refine measurable_to_countable' (fun x => ?_)
  induction x using ENat.recTopCoe with
  | top =>
    have : waitFor r A ⁻¹' {⊤} = ⋂ n : ℕ, {ω | waitFor r A ω ≤ (n : ℕ∞)}ᶜ := by
      ext ω; simp [gnb_enat_eq_top_iff (waitFor r A ω)]
    rw [this]; exact MeasurableSet.iInter fun n => (hle n).compl
  | coe n =>
    cases n with
    | zero =>
      have : waitFor r A ⁻¹' {((0 : ℕ) : ℕ∞)} = {ω | waitFor r A ω ≤ ((0 : ℕ) : ℕ∞)} := by
        ext ω; simp
      rw [this]; exact hle 0
    | succ k =>
      have : waitFor r A ⁻¹' {((k + 1 : ℕ) : ℕ∞)} =
          {ω | waitFor r A ω ≤ ((k + 1 : ℕ) : ℕ∞)} ∩ {ω | waitFor r A ω ≤ (k : ℕ∞)}ᶜ := by
        ext ω; simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_inter_iff,
          Set.mem_ofPred_eq, Set.mem_compl_iff]
        exact gnb_enat_eq_succ_iff _ k
      rw [this]; exact (hle (k + 1)).inter (hle k).compl

open Classical in
lemma gnb_pattern_set_eq {Ω : Type*} (A : ℕ → Set Ω) (n : ℕ) (T : Finset ℕ)
    (hT : T ⊆ Finset.range n) :
    {ω | (Finset.range n).filter (fun i => ω ∈ A i) = T} =
      ⋂ i ∈ Finset.range n, (if i ∈ T then A i else (A i)ᶜ) := by
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_iInter]
  constructor
  · rintro rfl i hi
    by_cases h : ω ∈ A i
    · have : i ∈ (Finset.range n).filter (fun i => ω ∈ A i) := Finset.mem_filter.2 ⟨hi, h⟩
      simp only [this, ite_true]; exact h
    · have : i ∉ (Finset.range n).filter (fun i => ω ∈ A i) := fun h' =>
        h (Finset.mem_filter.1 h').2
      simp only [this, ite_false]; exact h
  · intro h
    ext i
    simp only [Finset.mem_filter]
    constructor
    · rintro ⟨hi, hiA⟩
      by_contra hiT
      have := h i hi
      simp only [hiT, ite_false] at this
      exact this hiA
    · intro hiT
      have hi := hT hiT
      have := h i hi
      simp only [hiT, ite_true] at this
      exact ⟨hi, this⟩

open Classical in
lemma gnb_pattern_meas {Ω : Type*} [MeasurableSpace Ω] (A : ℕ → Set Ω)
    (hA : ∀ i, MeasurableSet (A i)) (n : ℕ) (T : Finset ℕ) (hT : T ⊆ Finset.range n) :
    MeasurableSet {ω | (Finset.range n).filter (fun i => ω ∈ A i) = T} := by
  rw [gnb_pattern_set_eq A n T hT]
  refine Finset.measurableSet_biInter _ (fun i _ => ?_)
  split_ifs
  · exact hA i
  · exact (hA i).compl

open Classical in
lemma gnb_pattern_prob {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (n : ℕ) (T : Finset ℕ) (hT : T ⊆ Finset.range n) :
    P.real {ω | (Finset.range n).filter (fun i => ω ∈ A i) = T} =
      p ^ T.card * (1 - p) ^ (n - T.card) := by
  have hind' := (iIndepSet_iff_iIndep A P).1 hind
  rw [gnb_pattern_set_eq A n T hT, measureReal_def, hind'.meas_biInter (fun i _ => ?_),
    ENNReal.toReal_prod]
  · rw [← Finset.prod_sdiff hT]
    have h1 : ∀ i ∈ Finset.range n \ T,
        (P (if i ∈ T then A i else (A i)ᶜ)).toReal = 1 - p := by
      intro i hi
      rw [Finset.mem_sdiff] at hi
      simp only [hi.2, ite_false]
      rw [← measureReal_def, probReal_compl_eq_one_sub (hA i), hp i]
    have h2 : ∀ i ∈ T, (P (if i ∈ T then A i else (A i)ᶜ)).toReal = p := by
      intro i hi
      simp only [hi, ite_true]
      rw [← measureReal_def, hp i]
    rw [Finset.prod_congr rfl h1, Finset.prod_congr rfl h2, Finset.prod_const, Finset.prod_const,
      Finset.card_sdiff_of_subset hT, Finset.card_range, mul_comm]
  · split_ifs
    · exact MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)
    · exact (MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)).compl

open Classical in
lemma gnb_filter_succ {Ω : Type*} (A : ℕ → Set Ω) (ω : Ω) (k : ℕ) :
    (Finset.range (k + 1)).filter (fun i => ω ∈ A i) =
      if ω ∈ A k then insert k ((Finset.range k).filter (fun i => ω ∈ A i))
      else (Finset.range k).filter (fun i => ω ∈ A i) := by
  rw [Finset.range_add_one, Finset.filter_insert]

open Classical in
lemma gnb_waitFor_eq_set {Ω : Type*} (A : ℕ → Set Ω) (s m : ℕ) :
    {ω | waitFor (s + 1) A ω = ((m + s + 1 : ℕ) : ℕ∞)} =
      ⋃ T ∈ (Finset.range (m + s)).powersetCard s,
        {ω | (Finset.range (m + s + 1)).filter (fun i => ω ∈ A i) = insert (m + s) T} := by
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_powersetCard, exists_prop]
  rw [gnb_enat_eq_succ_iff, gnb_waitFor_le_iff, gnb_waitFor_le_iff, gnb_filter_succ]
  have hnot : m + s ∉ (Finset.range (m + s)).filter (fun i => ω ∈ A i) := by
    simp
  constructor
  · rintro ⟨h1, h2⟩
    by_cases hk : ω ∈ A (m + s)
    · simp only [hk, ite_true] at h1 ⊢
      rw [Finset.card_insert_of_notMem hnot] at h1
      refine ⟨_, ⟨Finset.filter_subset _ _, by omega⟩, rfl⟩
    · simp only [hk, ite_false] at h1
      omega
  · rintro ⟨T, ⟨hTsub, hTcard⟩, hT⟩
    by_cases hk : ω ∈ A (m + s)
    · simp only [hk, ite_true] at hT
      have hTk : m + s ∉ T := fun h => by simpa using hTsub h
      have := congrArg (fun S => S.erase (m + s)) hT
      simp only [Finset.erase_insert hnot, Finset.erase_insert hTk] at this
      simp only [hk, ite_true]
      rw [Finset.card_insert_of_notMem hnot, this, hTcard]
      omega
    · simp only [hk, ite_false] at hT
      exfalso
      have : m + s ∈ (Finset.range (m + s)).filter (fun i => ω ∈ A i) := by
        rw [hT]; exact Finset.mem_insert_self _ _
      exact hnot this

open Classical in
lemma gnb_prob_eq {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (s m : ℕ) :
    P.real {ω | waitFor (s + 1) A ω = ((m + s + 1 : ℕ) : ℕ∞)} =
      ((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m := by
  rw [gnb_waitFor_eq_set, measureReal_biUnion_finset]
  · have hsub : ∀ T ∈ (Finset.range (m + s)).powersetCard s,
        insert (m + s) T ⊆ Finset.range (m + s + 1) ∧ (insert (m + s) T).card = s + 1 := by
      intro T hT
      rw [Finset.mem_powersetCard] at hT
      have hTk : m + s ∉ T := fun h => by simpa using hT.1 h
      refine ⟨?_, by rw [Finset.card_insert_of_notMem hTk, hT.2]⟩
      rw [Finset.range_add_one]
      exact Finset.insert_subset_insert _ hT.1
    rw [Finset.sum_congr rfl (fun T hT => by
      rw [gnb_pattern_prob P A p hA hind hp _ _ (hsub T hT).1, (hsub T hT).2])]
    rw [Finset.sum_const, Finset.card_powersetCard, Finset.card_range, nsmul_eq_mul,
      show m + s + 1 - (s + 1) = m by omega]
    ring
  · intro T₁ hT₁ T₂ hT₂ hne
    rw [Function.onFun, Set.disjoint_left]
    intro ω h1 h2
    simp only [Set.mem_ofPred_eq] at h1 h2
    rw [h1] at h2
    have hT₁' := (Finset.mem_powersetCard.1 hT₁).1
    have hT₂' := (Finset.mem_powersetCard.1 hT₂).1
    have hk1 : m + s ∉ T₁ := fun h => by simpa using hT₁' h
    have hk2 : m + s ∉ T₂ := fun h => by simpa using hT₂' h
    have := congrArg (fun S => S.erase (m + s)) h2
    simp only [Finset.erase_insert hk1, Finset.erase_insert hk2] at this
    exact hne this
  · intro T hT
    have hT' := (Finset.mem_powersetCard.1 hT).1
    apply gnb_pattern_meas A hA
    rw [Finset.range_add_one]
    exact Finset.insert_subset_insert _ hT'

open Classical in
lemma gnb_waitFor_lt_empty {Ω : Type*} (A : ℕ → Set Ω) (s n : ℕ) (hn : n < s + 1) :
    {ω | waitFor (s + 1) A ω = (n : ℕ∞)} = ∅ := by
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
  intro h
  have h' := (gnb_waitFor_le_iff (s + 1) A ω n).1 h.le
  have : ((Finset.range n).filter (fun i => ω ∈ A i)).card ≤ n :=
    (Finset.card_filter_le _ _).trans (Finset.card_range n).le
  omega

open Classical in
lemma gnb_tail_prob {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (n : ℕ) :
    P.real {ω | (n : ℕ∞) < waitFor 1 A ω} = (1 - p) ^ n := by
  have : {ω | (n : ℕ∞) < waitFor 1 A ω} =
      {ω | (Finset.range n).filter (fun i => ω ∈ A i) = ∅} := by
    ext ω
    simp only [Set.mem_ofPred_eq, ← not_le, gnb_waitFor_le_iff, Nat.one_le_iff_ne_zero, ne_eq,
      not_not, Finset.card_eq_zero]
  rw [this, gnb_pattern_prob P A p hA hind hp n ∅ (Finset.empty_subset _)]
  simp

lemma gnb_choose_one (m s : ℕ) :
    ((m + (s + 1) : ℕ) : ℝ) * ((m + s).choose s : ℝ) =
      ((s : ℝ) + 1) * ((m + (s + 1)).choose (s + 1) : ℝ) := by
  have h := Nat.add_one_mul_choose_eq (m + s) s
  have h' : (m + (s + 1)) * (m + s).choose s = (s + 1) * (m + (s + 1)).choose (s + 1) := by
    rw [show m + (s + 1) = m + s + 1 by omega, h, mul_comm]
  exact_mod_cast h'

lemma gnb_choose_two (m s : ℕ) :
    ((m + (s + 2) : ℕ) : ℝ) * ((m + (s + 1)).choose (s + 1) : ℝ) =
      ((s : ℝ) + 2) * ((m + (s + 2)).choose (s + 2) : ℝ) := by
  have h := Nat.add_one_mul_choose_eq (m + s + 1) (s + 1)
  have h' : (m + (s + 2)) * (m + (s + 1)).choose (s + 1) =
      (s + 2) * (m + (s + 2)).choose (s + 2) := by
    rw [show m + (s + 2) = m + s + 1 + 1 by omega, show m + (s + 1) = m + s + 1 by omega, h,
      mul_comm]
  exact_mod_cast h'

open Classical in
lemma gnb_main {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) (s : ℕ) :
    P {ω | waitFor (s + 1) A ω = ⊤} = 0 ∧
    ∫⁻ ω, (waitFor (s + 1) A ω : ℝ≥0∞) ∂P = ENNReal.ofReal ((s + 1) / p) ∧
    variance (fun ω => ((waitFor (s + 1) A ω).toNat : ℝ)) P = (s + 1) * (1 - p) / p ^ 2 := by
  have hWm : Measurable (waitFor (s + 1) A) := gnb_measurable_waitFor _ A hA
  have hp1 : p ≤ 1 := by rw [← hp 0]; exact measureReal_le_one
  have hq0 : 0 ≤ 1 - p := by linarith
  have hq1 : ‖1 - p‖ < 1 := by rw [Real.norm_eq_abs, abs_of_nonneg hq0]; linarith
  have hp' : 1 - (1 - p) = p := by ring
  set F : ℕ → ℝ := fun n => P.real {ω | waitFor (s + 1) A ω = n} with hF
  have hF0 : ∀ n, 0 ≤ F n := fun n => measureReal_nonneg
  have hFlt : ∀ n ∈ Finset.range (s + 1), F n = 0 := by
    intro n hn
    simp only [hF]
    rw [gnb_waitFor_lt_empty A s n (Finset.mem_range.1 hn)]
    simp
  have hFm : ∀ m, F (m + (s + 1)) = ((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m := by
    intro m
    simp only [hF]
    rw [show m + (s + 1) = m + s + 1 by omega]
    exact gnb_prob_eq P A p hA hind hp s m
  have shift : ∀ (w : ℕ → ℝ) (S : ℝ),
      HasSum (fun m => w (m + (s + 1)) * F (m + (s + 1))) S → HasSum (fun n => w n * F n) S := by
    intro w S h
    rw [← hasSum_nat_add_iff' (s + 1)]
    rw [Finset.sum_eq_zero (fun n hn => by rw [hFlt n hn, mul_zero]), sub_zero]
    exact h
  have hS0 : HasSum (fun n => (1 : ℝ) * F n) 1 := by
    apply shift
    have := (hasSum_choose_mul_geometric_of_norm_lt_one s hq1).mul_left (p ^ (s + 1))
    rw [hp'] at this
    convert this using 1
    · funext m; rw [hFm]; ring
    · field_simp
  have hS1 : HasSum (fun n : ℕ => (n : ℝ) * F n) ((s + 1) / p) := by
    apply shift
    have := (hasSum_choose_mul_geometric_of_norm_lt_one (s + 1) hq1).mul_left
      (((s : ℝ) + 1) * p ^ (s + 1))
    rw [hp'] at this
    convert this using 1
    · funext m
      rw [hFm]
      have := gnb_choose_one m s
      calc ((m + (s + 1) : ℕ) : ℝ) * (((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m)
          = (((m + (s + 1) : ℕ) : ℝ) * ((m + s).choose s : ℝ)) * p ^ (s + 1) * (1 - p) ^ m := by
            ring
        _ = _ := by rw [this]; ring
    · field_simp
      ring
  have hS2 : HasSum (fun n : ℕ => ((n : ℝ) * ((n : ℝ) + 1)) * F n) ((s + 1) * (s + 2) / p ^ 2) := by
    apply shift
    have := (hasSum_choose_mul_geometric_of_norm_lt_one (s + 2) hq1).mul_left
      (((s : ℝ) + 1) * ((s : ℝ) + 2) * p ^ (s + 1))
    rw [hp'] at this
    convert this using 1
    · funext m
      rw [hFm]
      have h1 := gnb_choose_one m s
      have h2 := gnb_choose_two m s
      have e : ((m + (s + 1) : ℕ) : ℝ) + 1 = ((m + (s + 2) : ℕ) : ℝ) := by push_cast; ring
      rw [e]
      calc ((m + (s + 1) : ℕ) : ℝ) * ((m + (s + 2) : ℕ) : ℝ) *
            (((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m)
          = ((m + (s + 2) : ℕ) : ℝ) * (((m + (s + 1) : ℕ) : ℝ) * ((m + s).choose s : ℝ)) *
              p ^ (s + 1) * (1 - p) ^ m := by ring
        _ = ((s : ℝ) + 1) * (((m + (s + 2) : ℕ) : ℝ) * ((m + (s + 1)).choose (s + 1) : ℝ)) *
              p ^ (s + 1) * (1 - p) ^ m := by rw [h1]; ring
        _ = _ := by rw [h2]; ring
    · field_simp
      ring
  have hS2' : HasSum (fun n : ℕ => (n : ℝ) ^ 2 * F n) ((s + 1) * (s + 2) / p ^ 2 - (s + 1) / p) := by
    convert hS2.sub hS1 using 1
    funext n; ring
  have hPW : ∀ n : ℕ, P {ω | waitFor (s + 1) A ω = n} = ENNReal.ofReal (F n) :=
    fun n => (ofReal_measureReal).symm
  have hmeas : ∀ n : ℕ, MeasurableSet {ω | waitFor (s + 1) A ω = n} :=
    fun n => hWm (measurableSet_singleton _)
  have htop : P {ω | waitFor (s + 1) A ω = ⊤} = 0 := by
    have hU : {ω | waitFor (s + 1) A ω ≠ ⊤} = ⋃ n : ℕ, {ω | waitFor (s + 1) A ω = n} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_iUnion, ENat.ne_top_iff_exists]
      exact ⟨fun ⟨m, hm⟩ => ⟨m, hm.symm⟩, fun ⟨m, hm⟩ => ⟨m, hm.symm⟩⟩
    have h1 : P {ω | waitFor (s + 1) A ω ≠ ⊤} = 1 := by
      rw [hU, measure_iUnion (fun i j hij => ?_) hmeas]
      · simp_rw [hPW]
        rw [← ENNReal.ofReal_tsum_of_nonneg hF0 (by simpa using hS0.summable)]
        have : ∑' n, F n = 1 := by simpa using hS0.tsum_eq
        rw [this, ENNReal.ofReal_one]
      · rw [Function.onFun, Set.disjoint_left]
        intro ω h1 h2
        simp only [Set.mem_ofPred_eq] at h1 h2
        rw [h1] at h2
        exact hij (by exact_mod_cast h2)
    have hc : {ω | waitFor (s + 1) A ω = ⊤} = {ω | waitFor (s + 1) A ω ≠ ⊤}ᶜ := by
      ext ω; simp
    have hmc : MeasurableSet {ω | waitFor (s + 1) A ω ≠ ⊤} :=
      (hWm (measurableSet_singleton ⊤)).compl
    rw [hc, prob_compl_eq_one_sub hmc, h1, tsub_self]
  set N : Ω → ℕ := fun ω => (waitFor (s + 1) A ω).toNat with hN
  have hNm : Measurable N := (Measurable.of_discrete (f := ENat.toNat)).comp hWm
  have hae : ∀ᵐ ω ∂P, waitFor (s + 1) A ω = (N ω : ℕ∞) := by
    have : ∀ᵐ ω ∂P, waitFor (s + 1) A ω ≠ ⊤ := by
      rw [ae_iff]; simpa using htop
    filter_upwards [this] with ω hω
    exact (ENat.natCast_toNat hω).symm
  have hPN : ∀ n : ℕ, P (N ⁻¹' {n}) = P {ω | waitFor (s + 1) A ω = n} := by
    intro n
    apply measure_congr
    filter_upwards [hae] with ω hω
    show (ω ∈ N ⁻¹' {n}) = (ω ∈ {ω | waitFor (s + 1) A ω = n})
    simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_ofPred_eq, hω, Nat.cast_inj]
  have hlin : ∀ g : ℕ → ℝ≥0∞, ∫⁻ ω, g (N ω) ∂P = ∑' n, g n * ENNReal.ofReal (F n) := by
    intro g
    rw [← lintegral_map Measurable.of_discrete hNm, lintegral_countable']
    congr 1
    funext n
    rw [Measure.map_apply hNm (measurableSet_singleton _), hPN, hPW]
  have key : ∀ w : ℕ → ℝ, (∀ n, 0 ≤ w n) → ∀ S, HasSum (fun n => w n * F n) S →
      ∫⁻ ω, ENNReal.ofReal (w (N ω)) ∂P = ENNReal.ofReal S := by
    intro w hw S h
    rw [hlin (fun n => ENNReal.ofReal (w n))]
    simp_rw [← ENNReal.ofReal_mul (hw _)]
    rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => mul_nonneg (hw n) (hF0 n)) h.summable,
      h.tsum_eq]
  have hE1 := key (fun n => (n : ℝ)) (fun n => Nat.cast_nonneg n) _ hS1
  have hE2 := key (fun n => (n : ℝ) ^ 2) (fun n => by positivity) _ hS2'
  refine ⟨htop, ?_, ?_⟩
  · rw [← hE1]
    apply lintegral_congr_ae
    filter_upwards [hae] with ω hω
    rw [hω, ENat.toENNReal_coe, ENNReal.ofReal_natCast]
  · set X : Ω → ℝ := fun ω => (N ω : ℝ) with hX
    have hXm : Measurable X := (Measurable.of_discrete (f := fun n : ℕ => (n : ℝ))).comp hNm
    have hX0 : 0 ≤ᵐ[P] X := ae_of_all _ (fun ω => Nat.cast_nonneg _)
    have hX20 : 0 ≤ᵐ[P] (X ^ 2) := ae_of_all _ (fun ω => by
      simp only [Pi.zero_apply, Pi.pow_apply]; positivity)
    have hint2 : Integrable (X ^ 2) P :=
      (lintegral_ofReal_ne_top_iff_integrable (hXm.pow_const 2).aestronglyMeasurable hX20).1
        (by
          have : ∫⁻ ω, ENNReal.ofReal (X ω ^ 2) ∂P = ENNReal.ofReal
              ((s + 1) * (s + 2) / p ^ 2 - (s + 1) / p) := hE2
          rw [this]; exact ENNReal.ofReal_ne_top)
    have hmemLp : MemLp X 2 P := (memLp_two_iff_integrable_sq hXm.aestronglyMeasurable).2 hint2
    have hI1 : ∫ ω, X ω ∂P = (s + 1) / p := by
      rw [integral_eq_lintegral_of_nonneg_ae hX0 hXm.aestronglyMeasurable]
      rw [show ∫⁻ ω, ENNReal.ofReal (X ω) ∂P = ENNReal.ofReal ((s + 1) / p) from hE1]
      rw [ENNReal.toReal_ofReal (by positivity)]
    have hI2 : ∫ ω, (X ^ 2) ω ∂P = (s + 1) * (s + 2) / p ^ 2 - (s + 1) / p := by
      rw [integral_eq_lintegral_of_nonneg_ae hX20 (hXm.pow_const 2).aestronglyMeasurable]
      rw [show ∫⁻ ω, ENNReal.ofReal ((X ^ 2) ω) ∂P = ENNReal.ofReal
          ((s + 1) * (s + 2) / p ^ 2 - (s + 1) / p) from hE2]
      rw [ENNReal.toReal_ofReal (hS2'.nonneg (fun n => mul_nonneg (by positivity) (hF0 n)))]
    show variance X P = _
    rw [variance_eq_sub hmemLp, hI2, hI1]
    field_simp
    ring

#print axioms gnb_waitFor_le_iff
#print axioms gnb_measurable_card
#print axioms gnb_enat_eq_succ_iff
#print axioms gnb_enat_eq_top_iff
#print axioms gnb_measurable_waitFor
#print axioms gnb_pattern_set_eq
#print axioms gnb_pattern_meas
#print axioms gnb_pattern_prob
#print axioms gnb_filter_succ
#print axioms gnb_waitFor_eq_set
#print axioms gnb_prob_eq
#print axioms gnb_waitFor_lt_empty
#print axioms gnb_tail_prob
#print axioms gnb_choose_one
#print axioms gnb_choose_two
#print axioms gnb_main

/-- The geometric law. Make independent tries, each a success with the same chance `p`, where
`p > 0`, and count the tries up to and including the first success. Then the wait ends with
probability 1; the first success lands on try `k` (for `k = 1, 2, 3, …`) with chance
`(1 - p)^(k-1) p`; the chance of no success in the first `k` tries is `(1 - p)^k`; the average
wait is `1/p` tries; and its variance is `(1 - p)/p²`. -/
theorem first_success_wait_is_geometric {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (A : ℕ → Set Ω) (p : ℝ)
    (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) :
    P {ω | waitFor 1 A ω = ⊤} = 0 ∧
    (∀ k : ℕ, 1 ≤ k → P.real {ω | waitFor 1 A ω = k} = (1 - p) ^ (k - 1) * p) ∧
    (∀ k : ℕ, P.real {ω | (k : ℕ∞) < waitFor 1 A ω} = (1 - p) ^ k) ∧
    ∫⁻ ω, (waitFor 1 A ω : ℝ≥0∞) ∂P = ENNReal.ofReal (1 / p) ∧
    variance (fun ω => ((waitFor 1 A ω).toNat : ℝ)) P = (1 - p) / p ^ 2 := by
  obtain ⟨h1, h2, h3⟩ := gnb_main P A p hA hind hp hp0 0
  simp only [zero_add, Nat.cast_zero] at h1 h2 h3
  refine ⟨h1, ?_, gnb_tail_prob P A p hA hind hp, h2, ?_⟩
  · intro k hk
    have h := gnb_prob_eq P A p hA hind hp 0 (k - 1)
    simp only [zero_add, add_zero, Nat.choose_zero_right, Nat.cast_one, one_mul, pow_one] at h
    rw [show k - 1 + 1 = k by omega] at h
    rw [h, mul_comm]
  · rw [h3]; ring

/-- Memorylessness. With the same independent tries, each a success with chance `p`, where now
`0 < p < 1`: for any whole numbers `s, t ≥ 0`, given that the first `s` tries all missed, the
chance that the next `t` tries also all miss is the same as the chance that the first `t` tries
miss from a standing start: `P(X > s + t | X > s) = P(X > t)`. -/
theorem first_success_wait_memoryless {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (A : ℕ → Set Ω) (p : ℝ)
    (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) (hp1 : p < 1) (s t : ℕ) :
    P[{ω | ((s + t : ℕ) : ℕ∞) < waitFor 1 A ω} | {ω | (s : ℕ∞) < waitFor 1 A ω}] =
      P {ω | (t : ℕ∞) < waitFor 1 A ω} := by
  have hq : 0 < 1 - p := by linarith
  have hmB : MeasurableSet {ω | (s : ℕ∞) < waitFor 1 A ω} :=
    gnb_measurable_waitFor 1 A hA (MeasurableSet.of_discrete (s := {x : ℕ∞ | (s : ℕ∞) < x}))
  rw [cond_apply hmB]
  have hsub : {ω | (s : ℕ∞) < waitFor 1 A ω} ∩ {ω | ((s + t : ℕ) : ℕ∞) < waitFor 1 A ω} =
      {ω | ((s + t : ℕ) : ℕ∞) < waitFor 1 A ω} := by
    refine Set.inter_eq_right.2 (fun ω hω => ?_)
    simp only [Set.mem_ofPred_eq] at hω ⊢
    exact lt_of_le_of_lt (by exact_mod_cast Nat.le_add_right s t) hω
  rw [hsub, ← ofReal_measureReal, ← ofReal_measureReal, ← ofReal_measureReal,
    gnb_tail_prob P A p hA hind hp, gnb_tail_prob P A p hA hind hp,
    gnb_tail_prob P A p hA hind hp, ← ENNReal.ofReal_inv_of_pos (by positivity),
    ← ENNReal.ofReal_mul (by positivity)]
  congr 1
  rw [pow_add]
  field_simp

/-- The negative binomial law. With the same independent tries, each a success with chance
`p > 0`, count the tries up to and including the `r`-th success, for any `r ≥ 1`. Then this
wait ends with probability 1; the `r`-th success lands on try `k` (for `k = r, r + 1, …`) with
chance `C(k-1, r-1) p^r (1 - p)^(k-r)`; and, being `r` geometric waits laid end to end, it
averages `r/p` tries with variance `r(1 - p)/p²`. -/
theorem rth_success_wait_is_negative_binomial {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (A : ℕ → Set Ω) (p : ℝ)
    (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) (r : ℕ) (hr : 1 ≤ r) :
    P {ω | waitFor r A ω = ⊤} = 0 ∧
    (∀ k : ℕ, r ≤ k → P.real {ω | waitFor r A ω = k} =
      ((k - 1).choose (r - 1) : ℝ) * p ^ r * (1 - p) ^ (k - r)) ∧
    ∫⁻ ω, (waitFor r A ω : ℝ≥0∞) ∂P = ENNReal.ofReal (r / p) ∧
    variance (fun ω => ((waitFor r A ω).toNat : ℝ)) P = r * (1 - p) / p ^ 2 := by
  obtain ⟨s, rfl⟩ : ∃ s, r = s + 1 := ⟨r - 1, by omega⟩
  obtain ⟨h1, h2, h3⟩ := gnb_main P A p hA hind hp hp0 s
  refine ⟨h1, ?_, ?_, ?_⟩
  · intro k hk
    obtain ⟨m, rfl⟩ : ∃ m, k = m + s + 1 := ⟨k - (s + 1), by omega⟩
    rw [gnb_prob_eq P A p hA hind hp s m, show m + s + 1 - 1 = m + s by omega,
      show s + 1 - 1 = s by omega, show m + s + 1 - (s + 1) = m by omega]
  · rw [h2]; push_cast; rfl
  · rw [h3]; push_cast; ring

/-! Worked numbers for a fair die: p = 1/6, q = 5/6. -/

-- First six on roll 5: (5/6)^4 × 1/6 = 625/7776.
example : (5 / 6 : ℚ) ^ 4 * (1 / 6) = 625 / 7776 := by norm_num
-- No six in the first 3 rolls: (5/6)^3 = 125/216.
example : (5 / 6 : ℚ) ^ 3 = 125 / 216 := by norm_num
-- A six within 4 rolls: 1 - (5/6)^4 = 671/1296 (0.517747).
example : 1 - (5 / 6 : ℚ) ^ 4 = 671 / 1296 := by norm_num
-- A six within 6 rolls: 1 - (5/6)^6 = 31031/46656 (0.665102).
example : 1 - (5 / 6 : ℚ) ^ 6 = 31031 / 46656 := by norm_num
-- Mean wait for the first six: 1 / (1/6) = 6.
example : 1 / (1 / 6 : ℚ) = 6 := by norm_num
-- Its variance: (5/6) / (1/6)^2 = 30.
example : (5 / 6 : ℚ) / (1 / 6) ^ 2 = 30 := by norm_num
-- Third six on roll 5: C(4, 2) × (1/6)^3 × (5/6)^2 = 6 × 25/7776.
example : (Nat.choose 4 2 : ℚ) * (1 / 6) ^ 3 * (5 / 6) ^ 2 = 6 * 25 / 7776 := by
  norm_num [Nat.choose]
-- Mean and variance for the third six: 3 × 6 = 18 and 3 × 30 = 90.
example : 3 / (1 / 6 : ℚ) = 18 := by norm_num
example : 3 * (5 / 6 : ℚ) / (1 / 6) ^ 2 = 90 := by norm_num
-- Memorylessness after four misses: (5/6)^(4+3) / (5/6)^4 = (5/6)^3 = 125/216.
example : (5 / 6 : ℚ) ^ (4 + 3) / (5 / 6) ^ 4 = 125 / 216 := by norm_num
-- The third-six wait remembers: P(T3 > 3 | T3 > 2) = 1 - (1/6)^3 = 215/216.
example : 1 - (1 / 6 : ℚ) ^ 3 = 215 / 216 := by norm_num
-- Counting all 6^6 = 46656 sequences of six rolls: the first six on roll 5 in 5^4 × 6 = 3750
-- of them, and 3750/46656 = 625/7776.
example : (6 : ℕ) ^ 6 = 46656 ∧ 5 ^ 4 * 6 = 3750 := by norm_num
example : (3750 : ℚ) / 46656 = 625 / 7776 := by norm_num
-- The third six on roll 5 in C(4, 2) × 5^2 × 6 = 900 of them, and 900/46656 = 150/7776.
example : Nat.choose 4 2 * 5 ^ 2 * 6 = 900 := by decide
example : (900 : ℚ) / 46656 = 6 * 25 / 7776 := by norm_num
-- Step 7, the same event counted two ways for n = 12 and n = 18: fewer than three sixes in
-- n rolls has the same chance as the third six landing after roll n.
example : (∑ j ∈ Finset.range 3, (Nat.choose 12 j : ℚ) * (1 / 6) ^ j * (5 / 6) ^ (12 - j)) =
    1 - ∑ k ∈ Finset.Icc 3 12, (Nat.choose (k - 1) 2 : ℚ) * (1 / 6) ^ 3 * (5 / 6) ^ (k - 3) := by
  decide +kernel
example : (∑ j ∈ Finset.range 3, (Nat.choose 18 j : ℚ) * (1 / 6) ^ j * (5 / 6) ^ (18 - j)) =
    1 - ∑ k ∈ Finset.Icc 3 18, (Nat.choose (k - 1) 2 : ℚ) * (1 / 6) ^ 3 * (5 / 6) ^ (k - 3) := by
  decide +kernel
-- Counting misses only: mean q/p = (5/6) / (1/6) = 5, one less than 6.
example : (5 / 6 : ℚ) / (1 / 6) = 5 := by norm_num
-- Variance of three waits wrongly taken as 3^2 × 30 = 270, not 3 × 30 = 90.
example : (3 : ℚ) ^ 2 * 30 = 270 ∧ (3 : ℚ) * 30 = 90 := by norm_num
-- Dealing six cards without replacement until the 6: mean (1 + 2 + … + 6)/6 = 7/2.
example : (∑ i ∈ Finset.range 6, ((i : ℚ) + 1)) / 6 = 7 / 2 := by
  norm_num [Finset.sum_range_succ]
-- Help desk: 12 emails an hour, one try per second: mean wait 1 / (12/3600) = 300 seconds.
example : 1 / ((12 : ℚ) / 3600) = 300 := by norm_num
-- Try-it: ten sixes average 10 × 6 = 60 rolls; a 1-in-100 prize averages 100 tries.
example : 10 / (1 / 6 : ℚ) = 60 := by norm_num
example : 1 / (1 / 100 : ℚ) = 100 := by norm_num

#print axioms first_success_wait_is_geometric
#print axioms first_success_wait_memoryless
#print axioms rth_success_wait_is_negative_binomial
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'gnb_waitFor_le_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_measurable_card' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_enat_eq_succ_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_enat_eq_top_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_measurable_waitFor' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_pattern_set_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_pattern_meas' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_pattern_prob' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_filter_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_waitFor_eq_set' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_prob_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_waitFor_lt_empty' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_tail_prob' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_choose_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_choose_two' depends on axioms: [propext, Classical.choice, Quot.sound]
'gnb_main' depends on axioms: [propext, Classical.choice, Quot.sound]
'first_success_wait_is_geometric' depends on axioms: [propext, Classical.choice, Quot.sound]
'first_success_wait_memoryless' depends on axioms: [propext, Classical.choice, Quot.sound]
'rth_success_wait_is_negative_binomial' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **A coin instead of a die.** Guess first: flips until the first head. Set p = 1/2. Mean 2 flips, variance 2.
> - **Ten sixes.** Guess first: how long, and how spread? Set r = 10. Mean 60 rolls, standard deviation 17.320508.
> - **A rare prize.** Guess first: a 1-in-100 chance per try. Set p = 1/100. Mean 100 tries, standard deviation 99.498744: almost as large as the mean.
> - **A long drought.** Guess first: the chance of no six in 20 rolls. The tail $q^{20}$ gives 0.026084, between 2 and 3 games in 100.

---

## The usual mistake

> [!warning]
> **"Ten misses, so a six is due."** It is not. By memorylessness the next roll's chance is still 0.166667 and the expected wait from here is still 6 rolls. The long-run share of sixes settles near one sixth because later rolls dilute a drought, never because the die corrects it.
>
> - **Trials or misses.** Some books define the geometric as the number of misses before the first success, starting at 0, with mean q/p = 5 for the die. Both are correct; mixing them is off by one on every value and every mean.
> - **Mean read as median (the middle wait).** Half of all waits end by roll 4 (0.517747), though the mean is 6. The long right tail pulls the mean up.
> - **Variance of r waits taken as r^2 times one.** That treats the gaps as one wait repeated: 270 instead of 90 for three sixes.
> - **Memorylessness where there is none.** Draws without replacement remember (the [Hypergeometric](03-hypergeometric.md) card), and so does the wait for two or more sixes.

---

## Where you meet it in real life

- **Retrying a connection.** With a fixed loss chance per try, the number of sends until a packet gets through is geometric; past failures say nothing about the next try.
- **Screening.** A clinic screening patients until r qualify waits a negative binomial number of screenings; r/p sets the budget.
- **Counts that spread more than a Poisson.** Ecologists and insurers fit the negative binomial to counts whose variance exceeds their mean, where the [Poisson](04-poisson.md) law would force the two to be equal.

> **Say it back**
> With independent tries at chance p, the first success lands on try k with chance q^(k−1) p. The wait ends for sure, averages 1/p tries and has variance q/p^2. After any run of failures the remaining wait has the same law as a fresh one; no other law in whole tries does that. The r-th success is r such waits end to end: mean r/p, variance r q/p^2. For a die, 6 rolls for the first six and 18 for the third.

---

## What this builds on

- [Binomial](01-bernoulli-and-binomial.md): the single try with chance p, and the count of successes in n tries that places the earlier r − 1 sixes and gives the tail of Step 7.

## Where this goes next

- [Two classics](07-birthday-and-coupon-collector.md): the wait until every face of the die has shown is a sum of six geometric waits whose chances fall from 6/6 to 1/6.
- [Exponential](../04-Continuous%20Distributions/03-exponential-distribution.md): the memoryless wait in continuous time, the partner of the geometric.

This card counts the wait in whole tries; it leaves open how long a wait lasts when a success can come at any instant.

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Siegrist, Kyle. "The Geometric Distribution." *Probability, Mathematical Statistics, and Stochastic Processes*, Random Services. [Chapter page](https://www.randomservices.org/random/bernoulli/Geometric.html). Mass, tail, moments and the memoryless characterization, both counting conventions.
- Siegrist, Kyle. "The Negative Binomial Distribution." Random Services. [Chapter page](https://www.randomservices.org/random/bernoulli/NegativeBinomial.html). The r-th success, the binomial duality of Step 7, and the gap decomposition.
- Feller, William. *An Introduction to Probability Theory and Its Applications*, Volume 1, 3rd ed. Wiley. [Publisher page](https://www.wiley.com/en-us/An+Introduction+to+Probability+Theory+and+Its+Applications%2C+Volume+1%2C+3rd+Edition-p-9780471257080). Chapter VI treats waiting times in Bernoulli trials and the negative binomial.
- Blitzstein, Joseph K., and Jessica Hwang. *Introduction to Probability*, 2nd ed. CRC Press. [Publisher page](https://www.routledge.com/Introduction-to-Probability-Second-Edition/Blitzstein-Hwang/p/book/9781138369917). Chapter 4 tells the story of both laws and derives their means.
