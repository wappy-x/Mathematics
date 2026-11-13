# Poisson process: arrivals with exponential gaps, and counts that are Poisson

[Syllabus](../../../SYLLABUS.md) → [Stochastic processes and calculus](../README.md) → [Poisson and Jump Processes](../README.md#s04) → Poisson process

---

## General Overview

A switchboard takes calls at 4 an hour on average. The callers do not know about each other. It is nine o'clock. How many calls arrive in the next quarter hour?

No call at all about 37% of the time. Exactly one, also about 37%. Two about 18%, three about 6%, four or more about 2%. These are the chances of the Poisson law with mean 1 ([Poisson](../../09-Probability%20and%20statistics/03-Discrete%20Distributions/04-poisson.md)). The same table holds for every quarter hour of the morning, and how busy one quarter hour was says nothing about the next.

Those numbers come from a construction. Draw the wait for the first call from the exponential law with a mean of 15 minutes ([Exponential](../../09-Probability%20and%20statistics/04-Continuous%20Distributions/03-exponential-distribution.md)). Draw each later wait afresh, independently, from the same law. Add up the waits and the call times appear.

Count the calls so far: the count sits still between calls and rises by one at each. That count, followed through time, is the **Poisson process**: a process in the sense of [Stochastic processes](../01-Random%20Walks%20and%20Filtrations/01-processes-and-paths.md), one random count for each moment.

**Independent exponential gaps between calls make the count in every window Poisson, with mean rate times length, and make the counts in separate windows independent.**

**What kind of fact this is:** a theorem, proved in full on this card in Why it works. The process built from gaps is a definition. Using it for a real switchboard is a model, and When it holds says where it fails.

### The picture: one morning's calls

One sample path from a seeded simulation (the SplitMix64 random-number generator, seed 20260929, written out in the code), read off every 3 minutes for two hours.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Calls so far, one sample path, at 4 calls an hour"
    x-axis "Minutes after nine" [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93, 96, 99, 102, 105, 108, 111, 114, 117, 120]
    y-axis "Calls so far" 0 --> 8
    line [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6]
    line [0.00, 0.20, 0.40, 0.60, 0.80, 1.00, 1.20, 1.40, 1.60, 1.80, 2.00, 2.20, 2.40, 2.60, 2.80, 3.00, 3.20, 3.40, 3.60, 3.80, 4.00, 4.20, 4.40, 4.60, 4.80, 5.00, 5.20, 5.40, 5.60, 5.80, 6.00, 6.20, 6.40, 6.60, 6.80, 7.00, 7.20, 7.40, 7.60, 7.80, 8.00]
```

Orange: the count on this one morning, with calls at 2.8, 28.9, 45.3, 63.9, 73.5 and 107.3 minutes. The real path jumps by exactly one at each call; the chart joins points 3 minutes apart, so each jump shows as a short ramp. Green: the mean count, 4 an hour times the hours elapsed. This morning ended on 6 calls against a mean of 8: one path is one sample, not the law.

---

## The formula

Notation first, in words. The rate is $\lambda$ (lambda), in calls per hour; time $t$ is in hours after nine. $E_n$ is the $n$-th gap, the wait from call $n-1$ to call $n$, with call 0 meaning nine o'clock. $T_n$ is the time of call $n$. $N(t)$ counts the calls by time $t$, a call exactly at $t$ included. The construction:

$$T_n = E_1 + E_2 + \dots + E_n, \qquad N(t) = \text{the largest } n \text{ with } T_n \le t$$

with $E_1, E_2, \dots$ independent and each exponential with rate $\lambda$: $P(E_n > u) = e^{-\lambda u}$.

The theorem. The count in the window from $s$ to $s+t$ is an **increment** of the process, $N(s+t) - N(s)$, and

$$P\big(N(s+t) - N(s) = k\big) = e^{-\lambda t}\,\frac{(\lambda t)^k}{k!}, \qquad k = 0, 1, 2, \dots$$

**Read it aloud:** the chance of exactly $k$ calls in a window is the Poisson chance with mean rate times length, wherever the window sits.

For back-to-back windows with ends $0 = t_0 < t_1 < \dots < t_q$, the counts $N(t_1) - N(t_0), \dots, N(t_q) - N(t_{q-1})$ are **independent**: the chance of any joint pattern is the product of the separate chances.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $\lambda$ | the rate: calls per hour on average | 4 | more calls in every window |
| $t$ | a length of time, in hours | 0.25, a quarter hour | more calls, in step |
| $s$ | where a window starts | 0 or 0.25 | nothing changes |
| $E_n$ | the $n$-th gap between calls | exponential, mean 0.25 hour = 15 minutes | — |
| $g_1$ to $g_n$, $x_1$ to $x_n$, $g_i$, $x_i$ | possible values of the gaps and of the call times, the variables of Steps 1 to 3 and the proof; i numbers them | call times 2.8, 28.9, … minutes on the pictured path | — |
| $T_n$ | the time of call $n$; $T_0 = 0$ | first call at 2.8 minutes, pictured path | — |
| $N(t)$ | calls by time $t$ | 6 by 120 minutes on the pictured path | — |
| $n$, $k$, $m$, $j$, $k_1$, $k_2$, $k_j$ | whole numbers: call number, count, total, window number, count in window $j$ | $k$ = 0, 1, 2 calls | — |
| $e^{-\lambda t}$ | chance of no call in a window of length $t$ | $e^{-1}$ = 0.3679 | — |
| $k!$ | $k$ factorial, 1 × 2 × … × $k$; 0! = 1 | 2! = 2 | — |
| $t_j$, $t_q$, $q$ | the ends of $q$ back-to-back windows | 0, 0.25, 0.5 | — |
| $u$, $u_1$ to $u_n$, $h$ | spare time lengths; a slot length | $h$ = 1 minute to 1 second | slots drift from the process |

At 4 calls an hour and a quarter hour, $\lambda t$ = 1: one call expected.

### When it holds

- **A constant rate.** At 8 calls an hour over lunch and 4 in the morning, no single $\lambda$ describes the day.
- **Gaps independent of one another.** Callers who redial after a busy signal bring calls in clumps, and the count spreads more than a Poisson count, whose variance equals its mean.
- **Exponential gaps, not merely the right mean.** Gaps spread evenly between 0 and 30 minutes also average 15 minutes, yet leave the first quarter hour empty half the time, and consecutive quarter hours correlate at −0.2940 ± 0.0022 in simulation instead of 0.
- **One call at a time.** If calls could arrive in pairs, the count would jump by two. That is [Compound Poisson](04-compound-poisson.md).
- **Windows fixed in advance.** The busiest quarter hour of the morning, picked after the fact, does not have the Poisson law with mean 1.

---

## Why it works

### Step 0: at any fixed moment, the process starts again

At a quarter past nine, a quarter hour has gone by. The wait from then to the next call still averages 15 minutes: the simulation gives 14.96 minutes, with a standard error of 0.03 (the typical size of the simulation's random error). The gap in progress has forgotten how long it has run: the no-memory property proved on [Exponential](../../09-Probability%20and%20statistics/04-Continuous%20Distributions/03-exponential-distribution.md). The gaps after it are fresh draws, untouched by the past.

So what happens after quarter past is a new copy of the same process, independent of what came before. The steps below make this restart precise.

### Step 1: the call times have a flat joint density

The first $n$ gaps have a joint density, a chance per unit of volume in $n$ dimensions, equal to the product of $n$ exponential densities:

$$\lambda e^{-\lambda g_1} \times \dots \times \lambda e^{-\lambda g_n} = \lambda^n e^{-\lambda (g_1 + \dots + g_n)}$$

where $g_1, \dots, g_n$ are the gap values. The sum in the exponent is the time of the last call, a value $x_n$ of $T_n$. Switching from gaps to call times $x_1 < x_2 < \dots < x_n$ slides each coordinate by the ones before it (a shear), which keeps volumes, so the density of the call times is

$$\lambda^n e^{-\lambda x_n} \quad \text{on } 0 < x_1 < x_2 < \dots < x_n.$$

Only the last call time appears. Where the earlier calls sit, in order, does not change the density. Integrating out the earlier ones gives the gamma law for $T_n$, as on [Gamma and beta](../../09-Probability%20and%20statistics/04-Continuous%20Distributions/07-gamma-and-beta-distributions.md).

### Step 2: exactly k calls makes the density constant

Exactly $k$ calls by time $t$ means the first $k$ calls come by $t$ and the next gap outlasts what is left of the window: $E_{k+1} > t - T_k$, which has chance $e^{-\lambda (t - x_k)}$. Multiply:

$$\lambda^k e^{-\lambda x_k} \times e^{-\lambda (t - x_k)} = \lambda^k e^{-\lambda t}.$$

The call times have dropped out. Every arrangement of $k$ calls in the window is equally likely. So the chance of $k$ calls is $\lambda^k e^{-\lambda t}$ times the volume of the set of arrangements, $0 < x_1 < \dots < x_k < t$.

That volume is $t^k / k!$. The cube of all $k$ unordered times has volume $t^k$. It splits into $k!$ equal pieces, one for each order the times can come in, and the ordered set is one of them. So

$$P\big(N(t) = k\big) = \lambda^k e^{-\lambda t} \times \frac{t^k}{k!} = e^{-\lambda t}\frac{(\lambda t)^k}{k!}.$$

For $k$ = 0: no call by $t$ means the first gap outlasts $t$, chance $e^{-\lambda t}$.

### Step 3: several windows at once

Take back-to-back windows ending at $t_1 < \dots < t_q$, and ask for $k_1$ calls in the first, $k_2$ in the second, and so on, $m$ in all. The same cancellation gives the constant density $\lambda^m e^{-\lambda t_q}$. The allowed arrangements put an ordered group of $k_j$ calls inside each window $j$, so their volume is a product of one volume per window. Splitting $e^{-\lambda t_q}$ and $\lambda^m$ window by window gives

$$\prod_{j=1}^{q} e^{-\lambda (t_j - t_{j-1})}\,\frac{\big(\lambda (t_j - t_{j-1})\big)^{k_j}}{k_j!}.$$

A product of Poisson chances, one per window, is exactly what independence means. Each factor depends on its window's length alone, not on where it starts. Taking windows from 0 to $s$ and from $s$ to $s+t$ gives the displayed formula for any start $s$.

### Step 4: the calls never pile up

Could infinitely many calls crowd into one morning? The strong law of large numbers ([The strong law of large numbers](../../10-Measure%20and%20integration/10-The%20Limit%20Theorems%2C%20Proved/04-strong-law-of-large-numbers.md)) says $T_n / n$ settles at the mean gap, 0.25 hour, with probability one. So $T_n$ grows without limit, and only finitely many calls come by any time. On the leftover set of chance zero, define the count to be 0; no probability changes.

<details>
<summary>Detailed proof: every step, with the change of variables written out</summary>

*Gaps to call times.* By independence the gaps $(E_1, \dots, E_n)$ have density $\lambda^n e^{-\lambda(g_1 + \dots + g_n)}$ for positive values. The map $x_i = g_1 + \dots + g_i$ is linear with inverse $g_i = x_i - x_{i-1}$, whose matrix has ones on the diagonal and minus ones just below: determinant 1. The change-of-variables rule gives $(T_1, \dots, T_n)$ the density $\lambda^n e^{-\lambda x_n}$ on $0 < x_1 < \dots < x_n$, and $(T_1, \dots, T_n, E_{n+1})$ the density $\lambda^{n+1} e^{-\lambda(x_n + g_{n+1})}$, with $g_{n+1}$ the value of the next gap.

*One window.* Off a null set (a set of chance zero), $N(t) = k$ is the event "$T_k \le t$ and $E_{k+1} > t - T_k$". Integrate the next gap from $t - x_k$ to infinity, then the call times over $0 < x_1 < \dots < x_k < t$:
$$P\big(N(t) = k\big) = \int \lambda^k e^{-\lambda x_k}\, e^{-\lambda(t - x_k)}\, dx = \lambda^k e^{-\lambda t} \cdot \frac{t^k}{k!}.$$
The ordered set is one of $k!$ pieces of the cube $(0,t)^k$ obtained by permuting coordinates; permutations keep volume and ties have volume zero.

*Several windows.* For counts $k_1, \dots, k_q$ with total $m \ge 1$, the event puts calls number $k_1 + \dots + k_{j-1} + 1$ to $k_1 + \dots + k_j$ inside window $j$, and needs $E_{m+1} > t_q - T_m$. The allowed set is a product of ordered sets with volume $\prod_j (t_j - t_{j-1})^{k_j} / k_j!$; times $\lambda^m e^{-\lambda t_q}$ this regroups into the product of Poisson chances. For $m = 0$ the chance is $P(E_1 > t_q) = e^{-\lambda t_q}$, the same formula. Summing over any sets of counts, one per window, still factorises, since each Poisson law sums to 1: that is mutual independence. Windows with space between them count the spaces as extra windows, summed out.

*The converse.* A counting process that starts at 0, rises by one at a time and has independent Poisson increments with mean rate times length has independent exponential gaps. For the first gap alone, $P(E_1 > u) = P(N(u) = 0) = e^{-\lambda u}$. For all of them at once, call $n$ has come by time $u$ exactly when $N(u) \ge n$, so $P(T_1 \le u_1, \dots, T_n \le u_n) = P(N(u_1) \ge 1, \dots, N(u_n) \ge n)$, and the right side depends only on the joint law of the counts, which the independent Poisson increments fix. The process built from gaps has those same count laws, so its call times, and with them its gaps, have the same joint law: independent exponentials. Either description therefore defines the same process.

</details>

### Two other roads to the same law

Condition on the first gap $u$: if it ends inside the window, the process restarts there, and $k$ calls by $t$ needs $k - 1$ in the time left. So $P(N(t) = k)$ is the integral over $u$ from 0 to $t$ of $\lambda e^{-\lambda u}$ times $P(N(t-u) = k-1)$, a recursion the code solves on a grid.

Or cut time into slots of length $h$, each holding a call with chance $\lambda h$, and let $h$ shrink: the binomial count tends to the Poisson count, as [Poisson](../../09-Probability%20and%20statistics/03-Discrete%20Distributions/04-poisson.md) proves. The code takes both roads.

---

## Worked numbers, by hand

The next quarter hour: $\lambda$ = 4 calls an hour, $t$ = 0.25 hour.

| Step | Arithmetic | Value |
| --- | --- | --- |
| expected calls, $\lambda t$ | 4 × 0.25 | 1 |
| mean gap, $1/\lambda$ | 1/4 hour | 0.25 hour = 15 minutes |
| no call | $e^{-1}$ | 0.3679 |
| exactly one call | $e^{-1} \times 1^1 / 1!$ | 0.3679 |
| exactly two | $e^{-1} / 2$ | 0.1839 |
| exactly three | $e^{-1} / 6$ | 0.0613 |
| four or more | 1 − 0.3679 − 0.3679 − 0.1839 − 0.0613 | 0.0190 |
| one call, then two in the following quarter hour | 0.3679 × 0.1839, by independence | 0.0677 |
| three calls in the half hour | $e^{-2} \times 2^3 / 3!$ | 0.1804 |
| **no call in the next quarter hour** | $e^{-\lambda t}$ | **0.3679** |

More than a third of quarter hours pass with no call at all, although a call is expected every 15 minutes. Running totals, unlike increments, are not independent: the count by half past contains the count by quarter past. Their variances are 1 and 2, their covariance is $\lambda$ times the shorter time, 4 × 0.25 = 1, so they correlate at $1/\sqrt{2}$ = 0.7071.

### The picture: the law of the quarter-hour count

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Calls in the quarter hour after nine, 4 calls an hour"
    x-axis "Calls in the quarter hour" [0, 1, 2, 3, 4, 5]
    y-axis "Chance" 0 --> 0.6
    bar [0.37, 0.37, 0.18, 0.06, 0.02, 0.00]
    line [0.37, 0.37, 0.18, 0.06, 0.02, 0.00]
    line [0.50, 0.37, 0.10, 0.02, 0.00, 0.00]
```

Orange bars: the Poisson law with mean 1. Green: 200,000 simulated quarter hours from exponential gaps, sitting on the bars. Dark blue: 200,000 quarter hours from gaps spread evenly between 0 and 30 minutes, the same mean; empty half the time, rarely busy. The mean gap alone does not fix the law. Every simulated value has a standard error of at most 0.0011.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Treating the totals $N(0.25)$ and $N(0.5)$ as independent | chance of 1 by quarter past and 2 by half past: 0.0996, true 0.1353 | the later total contains the earlier one; only the increments are independent |
| Using 1 − $\lambda t$ for the chance of no call | 0 for a quarter hour (true 0.3679); −3 for an hour (true 0.0183) | the short-window approximation stretched to a long window |
| Gaps even between 0 and 30 minutes, same mean | empty first quarter 0.5000; consecutive quarters correlated −0.2940 ± 0.0022, simulated; wait from quarter past 9.75 ± 0.01 minutes, simulated, not 15 | only exponential gaps restart at a fixed time |
| Slots of 1 minute, at most one call each | no call 0.3553, off by up to 0.0128 | two calls in one minute are forbidden; 1-second slots cut the error to 0.0002 |

The code prints every one.

---

## Code, from first principles, and it actually runs

Four roads to the law of the quarter-hour count. Road one is the Poisson formula. Road two never uses it: it solves the first-gap recursion on a grid of 1,000 steps with the trapezoid rule. Road three uses slots of 1 minute, 10 seconds and 1 second. Road four simulates 200,000 half hours from exponential gaps, drawn by inverse transform (minus the log of a random number between 0 and 1, divided by the rate) from a SplitMix64 generator written out, seed 20260929, with a standard error on every simulated number; it also checks independence, the totals' correlation and the restart at quarter past. A second simulation with evenly spread gaps shows what breaks.

### Python

```python
# Poisson process -- the check behind the card.  Standard library only; nothing
# imported holds the answer.  Calls reach a switchboard at 4 an hour.  The process
# is built from independent exponential gaps, and the count in the next quarter
# hour is reached four ways: the Poisson formula; a first-step recursion on the
# first gap, integrated on a grid; time cut into slots of length h, the error
# printed as h shrinks; and a seeded simulation (SplitMix64, seed 20260929).
from math import exp, log, sqrt

LAM, WIN, DAY = 4.0, 0.25, 2.0          # calls per hour; window and plotted span, hours
SEED, RUNS, KMAX = 20260929, 200_000, 5
M64 = (1 << 64) - 1
state = SEED

def uniform():                          # SplitMix64, turned into a number in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0**53

def gap():                              # exponential gap, rate LAM, by inverse transform
    return -log(uniform()) / LAM

def fact(k):
    f = 1
    for i in range(2, k + 1):
        f *= i
    return f

def pois(k, m):                         # Road 1: the Poisson formula
    return exp(-m) * m**k / fact(k)

def by_first_gap(t, kmax, n=1000):      # Road 2: p_k(t) = int_0^t LAM e^(-LAM u) p_(k-1)(t-u) du
    h = t / n
    f = [LAM * exp(-LAM * i * h) for i in range(n + 1)]
    q = [exp(-LAM * i * h) for i in range(n + 1)]     # p_0: the first gap outlasts the time
    out = [q[n]]
    for k in range(1, kmax + 1):
        r = [0.0]
        for i in range(1, n + 1):                     # trapezoid rule over the first gap u
            s = 0.5 * (f[0] * q[i] + f[i] * q[0])
            for j in range(1, i):
                s += f[j] * q[i - j]
            r.append(s * h)
        q = r
        out.append(q[n])
    return out

def by_slots(t, h, k):                  # Road 3: slots of length h, one call each with chance LAM h
    m, p, c = round(t / h), LAM * h, 1
    for i in range(k):
        c = c * (m - i) // (i + 1)
    return c * p**k * (1 - p)**(m - k)

def two_windows(draw):                  # Road 4: counts in the first and second quarter hour
    t, c1, c2 = draw(), 0, 0
    while t <= WIN:
        c1, t = c1 + 1, t + draw()
    w = t - WIN                                       # wait from quarter past to the next call
    while t <= 2 * WIN:
        c2, t = c2 + 1, t + draw()
    return c1, c2, w

def simulate(draw):
    hist, both, s1, s2, s11, s22, s12, s3, s4, sw, sww = [0] * (KMAX + 2), 0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0.0
    for _ in range(RUNS):
        c1, c2, w = two_windows(draw)
        hist[min(c1, KMAX + 1)] += 1
        both += c1 == 1 and c2 == 2
        s1, s2, s11, s22, s12 = s1 + c1, s2 + c2, s11 + c1 * c1, s22 + c2 * c2, s12 + c1 * c2
        s3, s4 = s3 + c1 * c1 * c1, s4 + c1 * c1 * c1 * c1
        sw, sww = sw + w, sww + w * w
    m1, m2 = s1 / RUNS, s2 / RUNS
    v1, v2, cv = s11 / RUNS - m1 * m1, s22 / RUNS - m2 * m2, s12 / RUNS - m1 * m2
    mw, m4 = sw / RUNS, s4 / RUNS - 4 * m1 * s3 / RUNS + 6 * m1 * m1 * s11 / RUNS - 3 * m1 * m1 * m1 * m1
    return (hist, both / RUNS, m1, v1, cv / sqrt(v1 * v2), (v1 + cv) / sqrt(v1 * (v1 + v2 + 2 * cv)),
            mw, sqrt((sww / RUNS - mw * mw) / RUNS), sqrt(v1 / RUNS), sqrt((m4 - v1 * v1) / RUNS))

def se(f):
    return sqrt(f * (1 - f) / RUNS)

path, t = [], gap()                     # one sample path over two hours, for the picture
while t <= DAY:
    path.append(t)
    t += gap()
grid = [3 * i for i in range(41)]                     # minutes
steps = [sum(1 for a in path if 60 * a <= g) for g in grid]

exact = [pois(k, LAM * WIN) for k in range(KMAX + 1)]
rec = by_first_gap(WIN, KMAX)
hist, both, m1, v1, r12, r1t, mw, sew, sem, sev = simulate(gap)
uhist, _, _, _, ur12, _, umw, usew, _, _ = simulate(lambda: 2 * uniform() / LAM)   # the mistake: same mean
pu = max(0.0, 1 - LAM * WIN / 2)                      # its exact chance of an empty first window
freq, ufreq = [c / RUNS for c in hist], [c / RUNS for c in uhist]
rse = 1 / sqrt(RUNS)                                  # standard error of a correlation near 0

print(f"rate {LAM:.0f} calls an hour; window {WIN} hour; mean count LAM t = {LAM * WIN:.4f}")
print("calls in the quarter hour: formula, first-gap recursion, simulated +- se")
for k in range(KMAX + 1):
    print(f"  {k}: {exact[k]:.6f}  {rec[k]:.6f}  {freq[k]:.4f} +- {se(freq[k]):.4f}")
print(f"P(4 or more): formula {1 - sum(exact[:4]):.4f}; simulated {sum(freq[4:]):.4f} +- {se(sum(freq[4:])):.4f}")
print(f"mean and variance of the count, simulated: {m1:.4f} +- {sem:.4f}, {v1:.4f} +- {sev:.4f}")
errs = []
for name, h in (("1 minute", 1 / 60), ("10 seconds", 1 / 360), ("1 second", 1 / 3600)):
    errs.append(max(abs(by_slots(WIN, h, k) - exact[k]) for k in range(KMAX + 1)))
    print(f"slots of {name}: P(0) = {by_slots(WIN, h, 0):.6f}, largest error {errs[-1]:.6f}")
print(f"wait from quarter past to the next call: {60 * mw:.2f} +- {60 * sew:.2f} minutes (mean gap 15)")
print(f"P(1 call, then 2 calls): formula {exact[1] * exact[2]:.4f}; simulated {both:.4f} +- {se(both):.4f}")
print(f"corr(first quarter, second quarter): {r12:.4f} +- {rse:.4f}; formula 0")
print(f"corr(N(0.25), N(0.5)): {r1t:.4f} +- {(1 - r1t * r1t) * rse:.4f}; formula sqrt(1/2) = {sqrt(0.5):.4f}")
print(f"P(N(0.5) = 3) = {pois(3, 2 * LAM * WIN):.4f}; Cov(N(0.25), N(0.5)) = LAM x 0.25 = {LAM * WIN:.4f}")
print(f"mistake, totals as independent: P(N(0.25) = 1 and N(0.5) = 2) = {exact[1] ** 2:.4f}, "
      f"product of the two laws {exact[1] * pois(2, 2 * LAM * WIN):.4f}")
print(f"mistake, 1 - LAM t for no call: quarter hour {1 - LAM * WIN:.4f} vs {exact[0]:.4f}; "
      f"one hour {1 - LAM:.4f} vs {exp(-LAM):.4f}")
print(f"mistake, gaps uniform on 0 to {120 / LAM:.0f} minutes: P(no call in first quarter) exact {pu:.4f}, "
      f"simulated {ufreq[0]:.4f} +- {se(ufreq[0]):.4f}")
print(f"  its corr(first quarter, second quarter): {ur12:.4f} +- {rse:.4f}; "
      f"wait from quarter past: {60 * umw:.2f} +- {60 * usew:.2f} minutes")
print("sample path, arrival minutes: " + ", ".join(f"{60 * a:.1f}" for a in path))
print("chart, minutes: " + ", ".join(str(g) for g in grid))
print("chart, calls so far: " + ", ".join(str(c) for c in steps))
print("chart, mean 4t: " + ", ".join(f"{g / 15:.2f}" for g in grid))
print("chart, formula: " + ", ".join(f"{p:.2f}" for p in exact))
print("chart, simulated exponential gaps: " + ", ".join(f"{p:.2f}" for p in freq[:KMAX + 1]))
print(f"chart, simulated uniform gaps (se at most {max(se(p) for p in ufreq):.4f}): "
      + ", ".join(f"{p:.2f}" for p in ufreq[:KMAX + 1]))

assert max(abs(rec[k] - exact[k]) for k in range(KMAX + 1)) < 1e-6   # recursion against formula
assert errs[0] > errs[1] > errs[2] and errs[2] < 5e-4                # slots close in on the formula
assert all(abs(freq[k] - exact[k]) < 4 * se(exact[k]) for k in range(KMAX + 1)) and abs(m1 - v1) < 4 * sev
assert abs(both - exact[1] * exact[2]) < 4 * se(both)               # increments multiply
assert abs(r12) < 4 * rse and abs(r1t - sqrt(0.5)) < 4 * (1 - r1t * r1t) * rse   # increments vs totals
assert abs(mw - 1 / LAM) < 4 * sew                                     # the restart at a fixed time
assert abs(ufreq[0] - pu) <= 4 * se(pu) and abs(ur12) > 4 * rse      # uniform gaps break it
print("ALL CHECKS PASS")
```

**Ran 2026-09-30 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
rate 4 calls an hour; window 0.25 hour; mean count LAM t = 1.0000
calls in the quarter hour: formula, first-gap recursion, simulated +- se
  0: 0.367879  0.367879  0.3679 +- 0.0011
  1: 0.367879  0.367879  0.3686 +- 0.0011
  2: 0.183940  0.183940  0.1839 +- 0.0009
  3: 0.061313  0.061313  0.0609 +- 0.0005
  4: 0.015328  0.015328  0.0152 +- 0.0003
  5: 0.003066  0.003066  0.0031 +- 0.0001
P(4 or more): formula 0.0190; simulated 0.0187 +- 0.0003
mean and variance of the count, simulated: 0.9980 +- 0.0022, 0.9933 +- 0.0038
slots of 1 minute: P(0) = 0.355264, largest error 0.012761
slots of 10 seconds: P(0) = 0.365826, largest error 0.002057
slots of 1 second: P(0) = 0.367675, largest error 0.000205
wait from quarter past to the next call: 14.96 +- 0.03 minutes (mean gap 15)
P(1 call, then 2 calls): formula 0.0677; simulated 0.0678 +- 0.0006
corr(first quarter, second quarter): 0.0004 +- 0.0022; formula 0
corr(N(0.25), N(0.5)): 0.7047 +- 0.0011; formula sqrt(1/2) = 0.7071
P(N(0.5) = 3) = 0.1804; Cov(N(0.25), N(0.5)) = LAM x 0.25 = 1.0000
mistake, totals as independent: P(N(0.25) = 1 and N(0.5) = 2) = 0.1353, product of the two laws 0.0996
mistake, 1 - LAM t for no call: quarter hour 0.0000 vs 0.3679; one hour -3.0000 vs 0.0183
mistake, gaps uniform on 0 to 30 minutes: P(no call in first quarter) exact 0.5000, simulated 0.4999 +- 0.0011
  its corr(first quarter, second quarter): -0.2940 +- 0.0022; wait from quarter past: 9.75 +- 0.01 minutes
sample path, arrival minutes: 2.8, 28.9, 45.3, 63.9, 73.5, 107.3
chart, minutes: 0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93, 96, 99, 102, 105, 108, 111, 114, 117, 120
chart, calls so far: 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6
chart, mean 4t: 0.00, 0.20, 0.40, 0.60, 0.80, 1.00, 1.20, 1.40, 1.60, 1.80, 2.00, 2.20, 2.40, 2.60, 2.80, 3.00, 3.20, 3.40, 3.60, 3.80, 4.00, 4.20, 4.40, 4.60, 4.80, 5.00, 5.20, 5.40, 5.60, 5.80, 6.00, 6.20, 6.40, 6.60, 6.80, 7.00, 7.20, 7.40, 7.60, 7.80, 8.00
chart, formula: 0.37, 0.37, 0.18, 0.06, 0.02, 0.00
chart, simulated exponential gaps: 0.37, 0.37, 0.18, 0.06, 0.02, 0.00
chart, simulated uniform gaps (se at most 0.0011): 0.50, 0.37, 0.10, 0.02, 0.00, 0.00
ALL CHECKS PASS
```

The recursion matches the formula to six decimals, and the slot error shrinks in proportion to the slot length.

### Rust

Same roads, same labels, built with `rustc --edition 2021 -O`.

```rust
// Poisson process -- the same check in Rust.  No crates.  Calls reach a
// switchboard at 4 an hour.  The process is built from independent exponential
// gaps, and the count in the next quarter hour is reached four ways: the Poisson
// formula; a first-step recursion on the first gap, integrated on a grid; time
// cut into slots of length h, the error printed as h shrinks; and a seeded
// simulation (SplitMix64, seed 20260929).
const LAM: f64 = 4.0;                   // calls per hour
const WIN: f64 = 0.25;                  // the window, hours
const DAY: f64 = 2.0;                   // the plotted span, hours
const RUNS: usize = 200_000;
const KMAX: usize = 5;

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {      // SplitMix64, turned into a number in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 2f64.powi(53)
    }
    fn gap(&mut self, uniform_gaps: bool) -> f64 {
        if uniform_gaps { 2.0 * self.uniform() / LAM }  // the mistake: uniform on 0 to 2/LAM, same mean
        else { -self.uniform().ln() / LAM }              // exponential gap, by inverse transform
    }
}

fn fact(k: usize) -> f64 { (2..=k).fold(1u64, |f, i| f * i as u64) as f64 }

fn pois(k: usize, m: f64) -> f64 { (-m).exp() * m.powf(k as f64) / fact(k) }   // Road 1

fn by_first_gap(t: f64, kmax: usize, n: usize) -> Vec<f64> {   // Road 2
    let h = t / n as f64;
    let f: Vec<f64> = (0..=n).map(|i| LAM * (-LAM * i as f64 * h).exp()).collect();
    let mut q: Vec<f64> = (0..=n).map(|i| (-LAM * i as f64 * h).exp()).collect();
    let mut out = vec![q[n]];
    for _ in 1..=kmax {
        let mut r = vec![0.0];
        for i in 1..=n {                                 // trapezoid rule over the first gap u
            let mut s = 0.5 * (f[0] * q[i] + f[i] * q[0]);
            for j in 1..i { s += f[j] * q[i - j] }
            r.push(s * h);
        }
        q = r;
        out.push(q[n]);
    }
    out
}

fn by_slots(t: f64, h: f64, k: usize) -> f64 {  // Road 3: one call per slot, chance LAM h
    let (m, p) = ((t / h).round() as u64, LAM * h);
    let mut c: u64 = 1;
    for i in 0..k as u64 { c = c * (m - i) / (i + 1) }
    c as f64 * p.powf(k as f64) * (1.0 - p).powf((m - k as u64) as f64)
}

fn two_windows(g: &mut Rng, u: bool) -> (u64, u64, f64) {   // Road 4
    let (mut t, mut c1, mut c2) = (g.gap(u), 0u64, 0u64);
    while t <= WIN { c1 += 1; t += g.gap(u) }
    let w = t - WIN;                                     // wait from quarter past to the next call
    while t <= 2.0 * WIN { c2 += 1; t += g.gap(u) }
    (c1, c2, w)
}

fn simulate(g: &mut Rng, u: bool) -> (Vec<u64>, f64, f64, f64, f64, f64, f64, f64, f64, f64) {
    let (mut hist, mut both) = (vec![0u64; KMAX + 2], 0u64);
    let (mut s1, mut s2, mut s11, mut s22, mut s12, mut sw, mut sww) = (0u64, 0u64, 0u64, 0u64, 0u64, 0.0, 0.0);
    let (mut s3, mut s4) = (0u64, 0u64);
    for _ in 0..RUNS {
        let (c1, c2, w) = two_windows(g, u);
        hist[(c1 as usize).min(KMAX + 1)] += 1;
        if c1 == 1 && c2 == 2 { both += 1 }
        s1 += c1; s2 += c2; s11 += c1 * c1; s22 += c2 * c2; s12 += c1 * c2;
        s3 += c1 * c1 * c1; s4 += c1 * c1 * c1 * c1;
        sw += w; sww += w * w;
    }
    let n = RUNS as f64;
    let (m1, m2) = (s1 as f64 / n, s2 as f64 / n);
    let (v1, v2, cv) = (s11 as f64 / n - m1 * m1, s22 as f64 / n - m2 * m2, s12 as f64 / n - m1 * m2);
    let (mw, m4) = (sw / n, s4 as f64 / n - 4.0 * m1 * s3 as f64 / n + 6.0 * m1 * m1 * s11 as f64 / n - 3.0 * m1 * m1 * m1 * m1);
    (hist, both as f64 / n, m1, v1, cv / (v1 * v2).sqrt(), (v1 + cv) / (v1 * (v1 + v2 + 2.0 * cv)).sqrt(),
     mw, ((sww / n - mw * mw) / n).sqrt(), (v1 / n).sqrt(), ((m4 - v1 * v1) / n).sqrt())
}

fn se(f: f64) -> f64 { (f * (1.0 - f) / RUNS as f64).sqrt() }

fn join<T>(v: &[T], f: impl Fn(&T) -> String) -> String { v.iter().map(f).collect::<Vec<_>>().join(", ") }

fn main() {
    let mut g = Rng(20260929);
    let (mut path, mut t) = (vec![], g.gap(false));      // one sample path over two hours
    while t <= DAY { path.push(t); t += g.gap(false) }
    let grid: Vec<u64> = (0..41).map(|i| 3 * i).collect();                  // minutes
    let steps: Vec<usize> = grid.iter().map(|&m| path.iter().filter(|&&a| 60.0 * a <= m as f64).count()).collect();

    let exact: Vec<f64> = (0..=KMAX).map(|k| pois(k, LAM * WIN)).collect();
    let rec = by_first_gap(WIN, KMAX, 1000);
    let (hist, both, m1, v1, r12, r1t, mw, sew, sem, sev) = simulate(&mut g, false);
    let (uhist, _, _, _, ur12, _, umw, usew, _, _) = simulate(&mut g, true);
    let freq: Vec<f64> = hist.iter().map(|&c| c as f64 / RUNS as f64).collect();
    let ufreq: Vec<f64> = uhist.iter().map(|&c| c as f64 / RUNS as f64).collect();
    let rse = 1.0 / (RUNS as f64).sqrt();                // standard error of a correlation near 0
    let pu = (1.0 - LAM * WIN / 2.0).max(0.0);           // uniform gaps: exact chance of an empty first window

    println!("rate {:.0} calls an hour; window {} hour; mean count LAM t = {:.4}", LAM, WIN, LAM * WIN);
    println!("calls in the quarter hour: formula, first-gap recursion, simulated +- se");
    for k in 0..=KMAX {
        println!("  {}: {:.6}  {:.6}  {:.4} +- {:.4}", k, exact[k], rec[k], freq[k], se(freq[k]));
    }
    let f4: f64 = freq[4..].iter().sum();
    println!("P(4 or more): formula {:.4}; simulated {:.4} +- {:.4}", 1.0 - exact[..4].iter().sum::<f64>(), f4, se(f4));
    println!("mean and variance of the count, simulated: {:.4} +- {:.4}, {:.4} +- {:.4}", m1, sem, v1, sev);
    let mut errs = vec![];
    for (name, h) in [("1 minute", 1.0 / 60.0), ("10 seconds", 1.0 / 360.0), ("1 second", 1.0 / 3600.0)] {
        errs.push((0..=KMAX).map(|k| (by_slots(WIN, h, k) - exact[k]).abs()).fold(0.0, f64::max));
        println!("slots of {}: P(0) = {:.6}, largest error {:.6}", name, by_slots(WIN, h, 0), errs[errs.len() - 1]);
    }
    println!("wait from quarter past to the next call: {:.2} +- {:.2} minutes (mean gap 15)", 60.0 * mw, 60.0 * sew);
    println!("P(1 call, then 2 calls): formula {:.4}; simulated {:.4} +- {:.4}", exact[1] * exact[2], both, se(both));
    println!("corr(first quarter, second quarter): {:.4} +- {:.4}; formula 0", r12, rse);
    println!("corr(N(0.25), N(0.5)): {:.4} +- {:.4}; formula sqrt(1/2) = {:.4}", r1t, (1.0 - r1t * r1t) * rse, 0.5f64.sqrt());
    println!("P(N(0.5) = 3) = {:.4}; Cov(N(0.25), N(0.5)) = LAM x 0.25 = {:.4}", pois(3, 2.0 * LAM * WIN), LAM * WIN);
    println!("mistake, totals as independent: P(N(0.25) = 1 and N(0.5) = 2) = {:.4}, product of the two laws {:.4}",
             exact[1].powf(2.0), exact[1] * pois(2, 2.0 * LAM * WIN));
    println!("mistake, 1 - LAM t for no call: quarter hour {:.4} vs {:.4}; one hour {:.4} vs {:.4}",
             1.0 - LAM * WIN, exact[0], 1.0 - LAM, (-LAM).exp());
    println!("mistake, gaps uniform on 0 to {:.0} minutes: P(no call in first quarter) exact {:.4}, simulated {:.4} +- {:.4}",
             120.0 / LAM, pu, ufreq[0], se(ufreq[0]));
    println!("  its corr(first quarter, second quarter): {:.4} +- {:.4}; wait from quarter past: {:.2} +- {:.2} minutes",
             ur12, rse, 60.0 * umw, 60.0 * usew);
    println!("sample path, arrival minutes: {}", join(&path, |a| format!("{:.1}", 60.0 * a)));
    println!("chart, minutes: {}", join(&grid, |m| m.to_string()));
    println!("chart, calls so far: {}", join(&steps, |c| c.to_string()));
    println!("chart, mean 4t: {}", join(&grid, |&m| format!("{:.2}", m as f64 / 15.0)));
    println!("chart, formula: {}", join(&exact, |p| format!("{:.2}", p)));
    println!("chart, simulated exponential gaps: {}", join(&freq[..=KMAX], |p| format!("{:.2}", p)));
    println!("chart, simulated uniform gaps (se at most {:.4}): {}", ufreq.iter().map(|&p| se(p)).fold(0.0, f64::max),
             join(&ufreq[..=KMAX], |p| format!("{:.2}", p)));

    assert!((0..=KMAX).all(|k| (rec[k] - exact[k]).abs() < 1e-6));           // recursion against formula
    assert!(errs[0] > errs[1] && errs[1] > errs[2] && errs[2] < 5e-4);       // slots close in on the formula
    assert!((0..=KMAX).all(|k| (freq[k] - exact[k]).abs() < 4.0 * se(exact[k])) && (m1 - v1).abs() < 4.0 * sev);
    assert!((both - exact[1] * exact[2]).abs() < 4.0 * se(both));           // increments multiply
    assert!(r12.abs() < 4.0 * rse && (r1t - 0.5f64.sqrt()).abs() < 4.0 * (1.0 - r1t * r1t) * rse); // increments vs totals
    assert!((mw - 1.0 / LAM).abs() < 4.0 * sew);                            // the restart at a fixed time
    assert!((ufreq[0] - pu).abs() <= 4.0 * se(pu) && ur12.abs() > 4.0 * rse); // uniform gaps break it
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-30 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
rate 4 calls an hour; window 0.25 hour; mean count LAM t = 1.0000
calls in the quarter hour: formula, first-gap recursion, simulated +- se
  0: 0.367879  0.367879  0.3679 +- 0.0011
  1: 0.367879  0.367879  0.3686 +- 0.0011
  2: 0.183940  0.183940  0.1839 +- 0.0009
  3: 0.061313  0.061313  0.0609 +- 0.0005
  4: 0.015328  0.015328  0.0152 +- 0.0003
  5: 0.003066  0.003066  0.0031 +- 0.0001
P(4 or more): formula 0.0190; simulated 0.0187 +- 0.0003
mean and variance of the count, simulated: 0.9980 +- 0.0022, 0.9933 +- 0.0038
slots of 1 minute: P(0) = 0.355264, largest error 0.012761
slots of 10 seconds: P(0) = 0.365826, largest error 0.002057
slots of 1 second: P(0) = 0.367675, largest error 0.000205
wait from quarter past to the next call: 14.96 +- 0.03 minutes (mean gap 15)
P(1 call, then 2 calls): formula 0.0677; simulated 0.0678 +- 0.0006
corr(first quarter, second quarter): 0.0004 +- 0.0022; formula 0
corr(N(0.25), N(0.5)): 0.7047 +- 0.0011; formula sqrt(1/2) = 0.7071
P(N(0.5) = 3) = 0.1804; Cov(N(0.25), N(0.5)) = LAM x 0.25 = 1.0000
mistake, totals as independent: P(N(0.25) = 1 and N(0.5) = 2) = 0.1353, product of the two laws 0.0996
mistake, 1 - LAM t for no call: quarter hour 0.0000 vs 0.3679; one hour -3.0000 vs 0.0183
mistake, gaps uniform on 0 to 30 minutes: P(no call in first quarter) exact 0.5000, simulated 0.4999 +- 0.0011
  its corr(first quarter, second quarter): -0.2940 +- 0.0022; wait from quarter past: 9.75 +- 0.01 minutes
sample path, arrival minutes: 2.8, 28.9, 45.3, 63.9, 73.5, 107.3
chart, minutes: 0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93, 96, 99, 102, 105, 108, 111, 114, 117, 120
chart, calls so far: 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6
chart, mean 4t: 0.00, 0.20, 0.40, 0.60, 0.80, 1.00, 1.20, 1.40, 1.60, 1.80, 2.00, 2.20, 2.40, 2.60, 2.80, 3.00, 3.20, 3.40, 3.60, 3.80, 4.00, 4.20, 4.40, 4.60, 4.80, 5.00, 5.20, 5.40, 5.60, 5.80, 6.00, 6.20, 6.40, 6.60, 6.80, 7.00, 7.20, 7.40, 7.60, 7.80, 8.00
chart, formula: 0.37, 0.37, 0.18, 0.06, 0.02, 0.00
chart, simulated exponential gaps: 0.37, 0.37, 0.18, 0.06, 0.02, 0.00
chart, simulated uniform gaps (se at most 0.0011): 0.50, 0.37, 0.10, 0.02, 0.00, 0.00
ALL CHECKS PASS
```

The two outputs are identical line for line.

### Lean

Lean proves the count laws and that calls never pile up, for every rate $\lambda > 0$ and all windows fixed in advance.

- Suppose the gaps are independent and exponential with rate $\lambda > 0$, and $s, t \ge 0$. Then the chance of exactly $k$ calls from $s$ to $s+t$ is $e^{-\lambda t}(\lambda t)^k/k!$.
- Take the same gaps and window ends $0 = t_0 < t_1 < \dots < t_q$. Then the chance of $k_j$ calls in each window $j$ at once is the product of the Poisson chances.
- With the same gaps, only finitely many calls come by any time $t$, with probability one.
- At 4 calls an hour, a quarter hour gives $\lambda t$ = 1 and a mean gap of 15 minutes.
- No call and exactly one call each have chance $e^{-1}$; two calls $e^{-1}/2$; three calls $e^{-1}/6$.
- Four or more calls have chance $1 - (8/3)e^{-1}$, and three calls in the half hour $(4/3)e^{-2}$.
- From variances 1 and 2 and covariance 1, the running totals correlate at $1/\sqrt{2}$.
- Over the two hours of the chart, the mean count is 4 × 2 = 8.

The decimals, the first-gap recursion, the slots, the simulation and the evenly spread gaps are left to the Python and Rust checks.

```lean
-- Poisson process: when the gaps between calls are independent and exponential with rate λ, the count in every window is Poisson with mean λ times its length, counts in back-to-back windows multiply, and calls never pile up.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.HasLaw
import Mathlib.Order.ConditionallyCompleteLattice.Basic
import Mathlib.Tactic.NormNum
import Mathlib

namespace PoissonProcess

open MeasureTheory ProbabilityTheory Real
open scoped Nat

/-- The time of call `n`: `T_n = E_1 + ... + E_n`, with the gaps stored as `E 0, E 1, ...`
(so `E i` is the card's `E_(i+1)`), and `T_0 = 0`, nine o'clock. -/
noncomputable def callTime {Ω : Type*} (E : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) : ℝ :=
  ∑ i ∈ Finset.range n, E i ω

/-- The count of calls by time `t`, a call exactly at `t` included: the largest `n` with
`T_n ≤ t`. When there is no largest one (infinitely many calls by `t`, a set of chance zero),
Lean's `sSup` of an unbounded set of whole numbers is `0`, the card's convention. -/
noncomputable def count {Ω : Type*} (E : ℕ → Ω → ℝ) (t : ℝ) (ω : Ω) : ℕ :=
  sSup {n : ℕ | callTime E n ω ≤ t}

section Helpers

open Filter Set

/-- Call times of a fixed list of gaps. -/
noncomputable def T (e : ℕ → ℝ) (n : ℕ) : ℝ := callTime (fun i (x : ℕ → ℝ) => x i) n e

/-- Count of calls by time `t` for a fixed list of gaps. -/
noncomputable def cnt (e : ℕ → ℝ) (t : ℝ) : ℕ := count (fun i (x : ℕ → ℝ) => x i) t e

/-- Drop the first gap. -/
def tl (e : ℕ → ℝ) : ℕ → ℝ := fun n => e (n + 1)

/-- Put a gap in front. -/
def cs (x : ℝ) (y : ℕ → ℝ) : ℕ → ℝ := fun n =>
  match n with
  | 0 => x
  | m + 1 => y m

/-- Gaps all positive, call times unbounded. -/
def Nice (e : ℕ → ℝ) : Prop := (∀ i, 0 < e i) ∧ ∀ t : ℝ, ∃ n, t < T e n

lemma T_zero (e : ℕ → ℝ) : T e 0 = 0 := by simp [T, callTime]

lemma T_succ (e : ℕ → ℝ) (n : ℕ) : T e (n + 1) = T e n + e n := by
  simp [T, callTime, Finset.sum_range_succ]

lemma T_tl (e : ℕ → ℝ) (n : ℕ) : T (tl e) n = T e (n + 1) - e 0 := by
  simp only [T, callTime, tl]
  rw [Finset.sum_range_succ']
  ring

lemma T_cs_succ (x : ℝ) (y : ℕ → ℝ) (n : ℕ) : T (cs x y) (n + 1) = x + T y n := by
  simp only [T, callTime]
  rw [Finset.sum_range_succ']
  simp [cs]
  ring

lemma T_cs_tl (e : ℕ → ℝ) (d : ℝ) (n : ℕ) : T (cs (e 0 - d) (tl e)) (n + 1) = T e (n + 1) - d := by
  rw [T_cs_succ, T_tl]; ring

lemma T_strictMono {e : ℕ → ℝ} (h : ∀ i, 0 < e i) : StrictMono (T e) :=
  strictMono_nat_of_lt_succ fun n => by rw [T_succ]; linarith [h n]

lemma cnt_def (e : ℕ → ℝ) (t : ℝ) : cnt e t = sSup {n : ℕ | T e n ≤ t} := rfl

lemma cnt_eq_iff {e : ℕ → ℝ} (h : Nice e) {t : ℝ} (ht : 0 ≤ t) (K : ℕ) :
    cnt e t = K ↔ T e K ≤ t ∧ t < T e (K + 1) := by
  have hm := T_strictMono h.1
  obtain ⟨N, hN⟩ := h.2 t
  have hlt : ∀ n, T e n ≤ t → n < N := fun n hn => by
    by_contra hc; push Not at hc; linarith [hm.monotone hc]
  have hbdd : BddAbove {n : ℕ | T e n ≤ t} := ⟨N, fun n hn => (hlt n hn).le⟩
  have hne : ({n : ℕ | T e n ≤ t}).Nonempty := ⟨0, by simp [T_zero, ht]⟩
  rw [cnt_def]
  constructor
  · rintro rfl
    refine ⟨Nat.sSup_mem hne hbdd, ?_⟩
    by_contra hc; push Not at hc
    have := le_csSup hbdd (show sSup {n : ℕ | T e n ≤ t} + 1 ∈ {n : ℕ | T e n ≤ t} from hc)
    omega
  · rintro ⟨h1, h2⟩
    have : {n : ℕ | T e n ≤ t} = Set.Iic K := by
      ext n
      simp only [mem_ofPred_eq, mem_Iic]
      constructor
      · intro hn; by_contra hc; push Not at hc
        linarith [hm.monotone (Nat.succ_le_of_lt hc)]
      · intro hn; exact (hm.monotone hn).trans h1
    rw [this, csSup_Iic]

lemma cnt_zero {e : ℕ → ℝ} (h : Nice e) : cnt e 0 = 0 :=
  (cnt_eq_iff h le_rfl 0).2 ⟨by simp [T_zero], by simpa [T_succ, T_zero] using h.1 0⟩

lemma nice_tl {e : ℕ → ℝ} (h : Nice e) : Nice (tl e) := by
  refine ⟨fun i => h.1 (i + 1), fun t => ?_⟩
  obtain ⟨N, hN⟩ := h.2 (t + e 0)
  refine ⟨N, ?_⟩
  rw [T_tl]
  have := (T_strictMono h.1).monotone (Nat.le_succ N)
  linarith

lemma nice_cs {e : ℕ → ℝ} (h : Nice e) {d : ℝ} (hd : d < e 0) : Nice (cs (e 0 - d) (tl e)) := by
  refine ⟨fun i => ?_, fun t => ?_⟩
  · cases i with
    | zero => simp [cs]; linarith
    | succ m => simpa [cs, tl] using h.1 (m + 1)
  · obtain ⟨N, hN⟩ := h.2 (t + d)
    refine ⟨N + 1, ?_⟩
    rw [T_cs_tl]
    have := (T_strictMono h.1).monotone (Nat.le_succ N)
    linarith

lemma cnt_tl {e : ℕ → ℝ} (h : Nice e) {t : ℝ} (ht : e 0 ≤ t) :
    cnt e t = cnt (tl e) (t - e 0) + 1 := by
  have h0 : 0 ≤ t := le_trans (h.1 0).le ht
  have := (cnt_eq_iff (nice_tl h) (sub_nonneg.2 ht) (cnt (tl e) (t - e 0))).1 rfl
  rw [T_tl, T_tl] at this
  exact (cnt_eq_iff h h0 _).2 ⟨by linarith, by linarith⟩

lemma cnt_cs {e : ℕ → ℝ} (h : Nice e) {d : ℝ} (hd : d < e 0) {t : ℝ} (ht : d ≤ t) (hd0 : 0 ≤ d) :
    cnt e t = cnt (cs (e 0 - d) (tl e)) (t - d) := by
  have := (cnt_eq_iff (nice_cs h hd) (sub_nonneg.2 ht) (cnt (cs (e 0 - d) (tl e)) (t - d))).1 rfl
  apply (cnt_eq_iff h (by linarith) _).2
  generalize cnt (cs (e 0 - d) (tl e)) (t - d) = K at this ⊢
  cases K with
  | zero =>
    rw [T_cs_tl, T_zero] at this
    rw [T_zero, zero_add]
    have h1 := this.2
    rw [zero_add] at h1
    constructor <;> linarith
  | succ m =>
    rw [T_cs_tl, T_cs_tl] at this
    constructor <;> linarith

/-- The count conditions along a list of windows `(length, number of calls)`. -/
def CG : List (ℝ × ℕ) → ℝ → ℕ → (ℕ → ℝ) → Prop
  | [], _, _, _ => True
  | p :: L, D, K, e => cnt e (D + p.1) = K + p.2 ∧ CG L (D + p.1) (K + p.2) e

lemma CG_tl {e : ℕ → ℝ} (h : Nice e) : ∀ (L : List (ℝ × ℕ)) (D : ℝ) (K : ℕ), e 0 ≤ D →
    (∀ p ∈ L, 0 ≤ p.1) → (CG L D (K + 1) e ↔ CG L (D - e 0) K (tl e)) := by
  intro L
  induction L with
  | nil => intros; simp [CG]
  | cons p L ih =>
    intro D K hD hL
    have hp := hL p (List.mem_cons_self ..)
    have hD' : e 0 ≤ D + p.1 := by linarith
    have e1 : D - e 0 + p.1 = D + p.1 - e 0 := by ring
    have e2 : K + 1 + p.2 = (K + p.2) + 1 := by omega
    simp only [CG]
    rw [e1, e2, ih (D + p.1) (K + p.2) hD' (fun q hq => hL q (List.mem_cons_of_mem _ hq)),
      cnt_tl h hD']
    constructor <;> rintro ⟨a, b⟩ <;> exact ⟨by omega, b⟩

lemma CG_cs {e : ℕ → ℝ} (h : Nice e) {d : ℝ} (hd : d < e 0) (hd0 : 0 ≤ d) :
    ∀ (L : List (ℝ × ℕ)) (D : ℝ) (K : ℕ), d ≤ D →
    (∀ p ∈ L, 0 ≤ p.1) → (CG L D K e ↔ CG L (D - d) K (cs (e 0 - d) (tl e))) := by
  intro L
  induction L with
  | nil => intros; simp [CG]
  | cons p L ih =>
    intro D K hD hL
    have hp := hL p (List.mem_cons_self ..)
    have hD' : d ≤ D + p.1 := by linarith
    have e1 : D - d + p.1 = D + p.1 - d := by ring
    simp only [CG]
    rw [e1, ih (D + p.1) (K + p.2) hD' (fun q hq => hL q (List.mem_cons_of_mem _ hq)),
      cnt_cs h hd hD' hd0]

/-- The windows event, built gap by gap. -/
def G (R : Set (ℕ → ℝ)) : ℕ → Set (ℝ × (ℕ → ℝ))
  | 0 => {p | p.1 < p.2 0 ∧ cs (p.2 0 - p.1) (tl p.2) ∈ R}
  | k + 1 => {p | 0 ≤ p.2 0 ∧ p.2 0 ≤ p.1 ∧ (p.1 - p.2 0, tl p.2) ∈ G R k}

def Good : List (ℝ × ℕ) → Set (ℕ → ℝ)
  | [] => univ
  | p :: L => {e | (p.1, e) ∈ G (Good L) p.2}

lemma good_iff : ∀ (L : List (ℝ × ℕ)), (∀ p ∈ L, 0 ≤ p.1) → ∀ e, Nice e →
    (e ∈ Good L ↔ CG L 0 0 e) := by
  intro L
  induction L with
  | nil => intros; simp [Good, CG]
  | cons p L ih =>
    intro hL e he
    have hL' : ∀ q ∈ L, 0 ≤ q.1 := fun q hq => hL q (List.mem_cons_of_mem _ hq)
    have key : ∀ (k : ℕ) (d : ℝ) (e : ℕ → ℝ), 0 ≤ d → Nice e →
        ((d, e) ∈ G (Good L) k ↔ cnt e d = k ∧ CG L d k e) := by
      intro k
      induction k with
      | zero =>
        intro d e hd he
        simp only [G, mem_ofPred_eq]
        rw [cnt_eq_iff he hd, T_zero, T_succ, T_zero, zero_add]
        constructor
        · rintro ⟨h1, h2⟩
          rw [ih hL' _ (nice_cs he h1)] at h2
          refine ⟨⟨hd, h1⟩, ?_⟩
          rw [CG_cs he h1 hd L d 0 le_rfl hL', sub_self]
          exact h2
        · rintro ⟨⟨-, h1⟩, h2⟩
          refine ⟨h1, ?_⟩
          rw [ih hL' _ (nice_cs he h1)]
          rw [CG_cs he h1 hd L d 0 le_rfl hL', sub_self] at h2
          exact h2
      | succ k ihk =>
        intro d e hd he
        simp only [G, mem_ofPred_eq]
        constructor
        · rintro ⟨-, h1, h2⟩
          rw [ihk (d - e 0) (tl e) (by linarith) (nice_tl he)] at h2
          exact ⟨by rw [cnt_tl he h1]; omega, (CG_tl he L d k h1 hL').2 h2.2⟩
        · rintro ⟨h1, h2⟩
          have h0 : e 0 ≤ d := by
            by_contra hc; push Not at hc
            have : cnt e d = 0 := (cnt_eq_iff he hd 0).2
              ⟨by rw [T_zero]; exact hd, by rw [T_succ, T_zero, zero_add]; exact hc⟩
            omega
          refine ⟨(he.1 0).le, h0, ?_⟩
          rw [ihk (d - e 0) (tl e) (by linarith) (nice_tl he)]
          exact ⟨by have := cnt_tl he h0; omega, (CG_tl he L d k h0 hL').1 h2⟩
    simp only [Good, mem_ofPred_eq, CG, zero_add]
    exact key p.2 p.1 e (hL p (List.mem_cons_self ..)) he


lemma measurable_tl : Measurable tl :=
  measurable_pi_iff.2 fun n => measurable_pi_apply (n + 1)

lemma measurable_cs : Measurable (fun q : ℝ × (ℕ → ℝ) => cs q.1 q.2) := by
  refine measurable_pi_iff.2 fun n => ?_
  cases n with
  | zero => simpa [cs] using measurable_fst
  | succ m =>
    show Measurable fun q : ℝ × (ℕ → ℝ) => q.2 m
    exact (measurable_pi_apply m).comp measurable_snd

lemma cs_tl (e : ℕ → ℝ) : cs (e 0) (tl e) = e := by
  funext n; cases n <;> rfl

/-- The Poisson chance of `k` calls in a window of length `d`. -/
noncomputable def poi (r d : ℝ) (k : ℕ) : ℝ := exp (-(r * d)) * (r * d) ^ k / k !

lemma poi_nonneg {r d : ℝ} (hr : 0 ≤ r) (hd : 0 ≤ d) (k : ℕ) : 0 ≤ poi r d k := by
  unfold poi; have := mul_nonneg hr hd; positivity

/-- Law of an independent sequence of exponential gaps. -/
noncomputable abbrev nu (r : ℝ) [IsProbabilityMeasure (expMeasure r)] : Measure (ℕ → ℝ) :=
  Measure.infinitePi (fun _ : ℕ => expMeasure r)

section
variable {r : ℝ}

lemma expMeasure_eq : expMeasure r = volume.withDensity (exponentialPDF r) := rfl

lemma measurable_exponentialPDF : Measurable (exponentialPDF r) :=
  (measurable_exponentialPDFReal r).ennreal_ofReal

/-- Memorylessness, as an integral. -/
lemma lintegral_memoryless {d : ℝ} (hd : 0 ≤ d) {f : ℝ → ENNReal}
    (hf : Measurable f) :
    ∫⁻ x, (Ioi d).indicator (fun x => f (x - d)) x ∂(expMeasure r) =
      ENNReal.ofReal (exp (-(r * d))) * ∫⁻ x, f x ∂(expMeasure r) := by
  have hsing : expMeasure r {d} = 0 := by
    rw [expMeasure_eq, withDensity_apply _ (measurableSet_singleton d),
      Measure.restrict_eq_zero.2 Real.volume_singleton, lintegral_zero_measure]
  have h1 : ∫⁻ x, (Ioi d).indicator (fun x => f (x - d)) x ∂(expMeasure r) =
      ∫⁻ x, (Ici d).indicator (fun x => f (x - d)) x ∂(expMeasure r) := by
    apply lintegral_congr_ae
    filter_upwards [measure_eq_zero_iff_ae_notMem.1 hsing] with x hx
    have hx' : x ≠ d := by simpa using hx
    by_cases h : d < x
    · simp [indicator, h, h.le]
    · have : ¬ d ≤ x := fun h' => h (lt_of_le_of_ne h' hx'.symm)
      simp [indicator, h, this]
  have hg : Measurable fun x => (Ici d).indicator (fun x => f (x - d)) x :=
    (hf.comp (measurable_id.sub_const d)).indicator measurableSet_Ici
  rw [h1, expMeasure_eq, lintegral_withDensity_eq_lintegral_mul _ measurable_exponentialPDF hg,
    lintegral_withDensity_eq_lintegral_mul _ measurable_exponentialPDF hf,
    ← lintegral_add_right_eq_self _ d, ← lintegral_const_mul _ (measurable_exponentialPDF.mul hf)]
  congr 1
  funext y
  simp only [Pi.mul_apply]
  by_cases hy : 0 ≤ y
  · have hyd : d ≤ y + d := by linarith
    simp only [indicator, mem_Ici, hyd, ite_true, add_sub_cancel_right]
    rw [exponentialPDF_of_nonneg (by linarith), exponentialPDF_of_nonneg hy, ← mul_assoc,
      ← ENNReal.ofReal_mul (exp_pos _).le]
    congr 2
    rw [show -(r * (y + d)) = -(r * d) + -(r * y) by ring, exp_add]
    ring
  · push Not at hy
    have hyd : ¬ d ≤ y + d := by linarith
    simp [indicator, hyd, exponentialPDF_of_neg hy]

lemma lintegral_window (hr : 0 < r) {d : ℝ} (hd : 0 ≤ d) (k : ℕ) :
    ∫⁻ x, (Icc 0 d).indicator (fun x => ENNReal.ofReal (poi r (d - x) k)) x ∂(expMeasure r) =
      ENNReal.ofReal (poi r d (k + 1)) := by
  have hg : Measurable fun x => ENNReal.ofReal (poi r (d - x) k) := by
    unfold poi; fun_prop
  rw [lintegral_indicator measurableSet_Icc, expMeasure_eq,
    setLIntegral_withDensity_eq_setLIntegral_mul _ measurable_exponentialPDF hg measurableSet_Icc]
  rw [setLIntegral_congr_fun measurableSet_Icc (g := fun x => ENNReal.ofReal
    (exp (-(r * d)) * r ^ (k + 1) / k ! * (d - x) ^ k))]
  swap
  · intro x hx
    simp only [Pi.mul_apply]
    rw [exponentialPDF_of_nonneg hx.1, ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    unfold poi
    have : exp (-(r * x)) * exp (-(r * (d - x))) = exp (-(r * d)) := by
      rw [← exp_add]; ring_nf
    rw [mul_pow, pow_succ]
    field_simp
    rw [← this]
    ring
  have hcont : Continuous fun x : ℝ => exp (-(r * d)) * r ^ (k + 1) / k ! * (d - x) ^ k := by
    fun_prop
  rw [← ofReal_integral_eq_lintegral_ofReal (hcont.integrableOn_Icc)]
  swap
  · refine ae_restrict_of_forall_mem measurableSet_Icc fun x hx => ?_
    have : 0 ≤ d - x := sub_nonneg.2 hx.2
    positivity
  congr 1
  rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le hd,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_comp_sub_left (fun x => x ^ k),
    integral_pow]
  simp only [sub_self, sub_zero, ne_eq, Nat.succ_ne_zero, not_false_eq_true, zero_pow]
  unfold poi
  rw [Nat.factorial_succ]
  push_cast
  rw [mul_pow]
  field_simp

end

variable {r : ℝ} [IsProbabilityMeasure (expMeasure r)]

lemma nu_split : (nu r).map (fun e => (e 0, tl e)) = (expMeasure r).prod (nu r) := by
  have hind : iIndepFun (fun i (e : ℕ → ℝ) => e i) (nu r) :=
    iIndepFun_infinitePi (X := fun _ x => x) (fun _ => measurable_id)
  have h2 := hind.indepFun_set {0} {n | n ≠ 0} (by simp) (fun i => measurable_pi_apply i)
  have h3 : IndepFun (fun e : ℕ → ℝ => e 0) tl (nu r) :=
    h2.comp (show Measurable (fun f : ({0} : Set ℕ) → ℝ => f ⟨0, rfl⟩) from measurable_pi_apply _)
      (show Measurable (fun f : {n : ℕ | n ≠ 0} → ℝ => fun n => f ⟨n + 1, Nat.succ_ne_zero n⟩)
        from measurable_pi_iff.2 fun n => measurable_pi_apply _)
  rw [(indepFun_iff_map_prod_eq_prod_map_map (measurable_pi_apply 0).aemeasurable
    measurable_tl.aemeasurable).1 h3]
  congr 1
  · exact Measure.infinitePi_map_eval _ 0
  · exact Measure.map_infinitePi_infinitePi_of_inj (P := fun _ : ℕ => expMeasure r)
      (f := Nat.succ) Nat.succ_injective

lemma nu_split_apply {A : Set (ℝ × (ℕ → ℝ))} (hA : MeasurableSet A) :
    nu r {e | (e 0, tl e) ∈ A} = ∫⁻ x, nu r (Prod.mk x ⁻¹' A) ∂(expMeasure r) := by
  rw [← Measure.prod_apply hA, ← nu_split,
    Measure.map_apply ((measurable_pi_apply 0).prodMk measurable_tl) hA]
  rfl

lemma nu_cs {R : Set (ℕ → ℝ)} (hR : MeasurableSet R) :
    ∫⁻ x, nu r (Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R}) ∂(expMeasure r) = nu r R := by
  rw [← nu_split_apply (A := {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R}) (measurable_cs hR)]
  simp only [mem_ofPred_eq, cs_tl]
  rfl


lemma measurableSet_G {R : Set (ℕ → ℝ)} (hR : MeasurableSet R) : ∀ k, MeasurableSet (G R k) := by
  intro k
  induction k with
  | zero =>
    have hm : Measurable fun p : ℝ × (ℕ → ℝ) => (p.2 0 - p.1, tl p.2) :=
      (((measurable_pi_apply 0).comp measurable_snd).sub measurable_fst).prodMk
          (measurable_tl.comp measurable_snd)
    have h2 : MeasurableSet {p : ℝ × (ℕ → ℝ) | cs (p.2 0 - p.1) (tl p.2) ∈ R} :=
      hR.preimage (measurable_cs.comp hm)
    have h1 : MeasurableSet {p : ℝ × (ℕ → ℝ) | p.1 < p.2 0} :=
      measurableSet_lt measurable_fst ((measurable_pi_apply 0).comp measurable_snd)
    exact h1.inter h2
  | succ k ih =>
    have hm : Measurable fun p : ℝ × (ℕ → ℝ) => (p.1 - p.2 0, tl p.2) :=
      (measurable_fst.sub ((measurable_pi_apply 0).comp measurable_snd)).prodMk
          (measurable_tl.comp measurable_snd)
    have h3 : MeasurableSet {p : ℝ × (ℕ → ℝ) | (p.1 - p.2 0, tl p.2) ∈ G R k} := ih.preimage hm
    have h1 : MeasurableSet {p : ℝ × (ℕ → ℝ) | 0 ≤ p.2 0} :=
      measurableSet_le measurable_const ((measurable_pi_apply 0).comp measurable_snd)
    have h2 : MeasurableSet {p : ℝ × (ℕ → ℝ) | p.2 0 ≤ p.1} :=
      measurableSet_le ((measurable_pi_apply 0).comp measurable_snd) measurable_fst
    exact h1.inter (h2.inter h3)

lemma measurableSet_Good : ∀ L : List (ℝ × ℕ), MeasurableSet (Good L)
  | [] => MeasurableSet.univ
  | p :: L => measurable_prodMk_left (measurableSet_G (measurableSet_Good L) p.2)

lemma nu_G (hr : 0 < r) {R : Set (ℕ → ℝ)} (hR : MeasurableSet R) :
    ∀ (k : ℕ) (d : ℝ), 0 ≤ d → nu r {e | (d, e) ∈ G R k} = ENNReal.ofReal (poi r d k) * nu r R := by
  intro k
  induction k with
  | zero =>
    intro d hd
    have hA1 : MeasurableSet {q : ℝ × (ℕ → ℝ) | d < q.1} :=
      measurableSet_lt measurable_const measurable_fst
    have hm : Measurable fun q : ℝ × (ℕ → ℝ) => (q.1 - d, q.2) :=
      (measurable_fst.sub_const d).prodMk measurable_snd
    have hA2 : MeasurableSet {q : ℝ × (ℕ → ℝ) | cs (q.1 - d) q.2 ∈ R} :=
      hR.preimage (measurable_cs.comp hm)
    have hA : MeasurableSet {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R} := hA1.inter hA2
    have hB : MeasurableSet {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R} := measurable_cs hR
    have hset : {e | (d, e) ∈ G R 0} =
        {e | (e 0, tl e) ∈ {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R}} := rfl
    rw [hset, nu_split_apply hA]
    have hpt : ∀ x, nu r (Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R}) =
        (Ioi d).indicator (fun x => nu r (Prod.mk (x - d) ⁻¹'
          {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R})) x := by
      intro x
      by_cases hx : d < x
      · simp only [indicator, mem_Ioi, hx, ite_true]
        congr 1
        ext y; simp [hx]
      · simp only [indicator, mem_Ioi, hx, ite_false]
        have : Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R} = ∅ := by
          ext y; simp [hx]
        rw [this, measure_empty]
    simp_rw [hpt]
    rw [lintegral_memoryless hd (measurable_measure_prodMk_left hB), nu_cs hR]
    simp [poi]
  | succ k ih =>
    intro d hd
    have hA1 : MeasurableSet {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1} :=
      measurableSet_le measurable_const measurable_fst
    have hA2 : MeasurableSet {q : ℝ × (ℕ → ℝ) | q.1 ≤ d} :=
      measurableSet_le measurable_fst measurable_const
    have hm : Measurable fun q : ℝ × (ℕ → ℝ) => (d - q.1, q.2) :=
      (measurable_const.sub measurable_fst).prodMk measurable_snd
    have hA3 : MeasurableSet {q : ℝ × (ℕ → ℝ) | (d - q.1, q.2) ∈ G R k} :=
      (measurableSet_G hR k).preimage hm
    have hA : MeasurableSet {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k} :=
      hA1.inter (hA2.inter hA3)
    have hset : {e | (d, e) ∈ G R (k + 1)} =
        {e | (e 0, tl e) ∈ {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k}} := rfl
    rw [hset, nu_split_apply hA]
    have hpt : ∀ x, nu r (Prod.mk x ⁻¹'
        {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k}) =
        (Icc 0 d).indicator (fun x => ENNReal.ofReal (poi r (d - x) k)) x * nu r R := by
      intro x
      by_cases hx : x ∈ Icc 0 d
      · simp only [indicator, hx, ite_true]
        rw [← ih (d - x) (sub_nonneg.2 hx.2)]
        congr 1
        ext y; simp [hx.1, hx.2]
      · simp only [indicator, hx, ite_false, zero_mul]
        have : Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k} = ∅ := by
          ext y
          simp only [mem_preimage, mem_ofPred_eq, mem_empty_iff_false, iff_false]
          rintro ⟨h1, h2, -⟩
          exact hx ⟨h1, h2⟩
        rw [this, measure_empty]
    simp_rw [hpt]
    rw [lintegral_mul_const _ ((Measurable.ennreal_ofReal (by unfold poi; fun_prop)).indicator
      measurableSet_Icc), lintegral_window hr hd]

lemma nu_Good (hr : 0 < r) : ∀ L : List (ℝ × ℕ), (∀ p ∈ L, 0 ≤ p.1) →
    nu r (Good L) = ENNReal.ofReal ((L.map fun p => poi r p.1 p.2).prod) := by
  intro L
  induction L with
  | nil => intro; simp [Good]
  | cons p L ih =>
    intro hL
    have hp := hL p (List.mem_cons_self ..)
    have hL' : ∀ q ∈ L, 0 ≤ q.1 := fun q hq => hL q (List.mem_cons_of_mem _ hq)
    show nu r {e | (p.1, e) ∈ G (Good L) p.2} = _
    rw [nu_G hr (measurableSet_Good L) p.2 p.1 hp, ih hL', List.map_cons, List.prod_cons,
      ENNReal.ofReal_mul (poi_nonneg hr.le hp _)]

lemma expMeasure_Iic_zero (hr : 0 < r) : expMeasure r (Iic 0) = 0 := by
  have h := cdf_expMeasure_eq hr 0
  rw [cdf_eq_real] at h
  simp at h
  exact (measureReal_eq_zero_iff).1 h

lemma ae_pos (hr : 0 < r) (i : ℕ) : ∀ᵐ e ∂(nu r), 0 < e i := by
  rw [ae_iff]
  have : {e : ℕ → ℝ | ¬ 0 < e i} = (fun e : ℕ → ℝ => e i) ⁻¹' Iic 0 := by
    ext e; simp
  rw [this, ← Measure.map_apply (measurable_pi_apply i) measurableSet_Iic,
    Measure.infinitePi_map_eval, expMeasure_Iic_zero hr]

/-- The truncated gap used with the strong law. -/
noncomputable def trunc (x : ℝ) : ℝ := max (min x 1) 0

lemma measurable_trunc : Measurable trunc := by unfold trunc; fun_prop

lemma ae_nice (hr : 0 < r) : ∀ᵐ e ∂(nu r), Nice e := by
  have hpos : ∀ᵐ e ∂(nu r), ∀ i, 0 < e i := ae_all_iff.2 (ae_pos hr)
  set Y : ℕ → (ℕ → ℝ) → ℝ := fun i e => trunc (e i) with hY
  have hind : iIndepFun (fun i (e : ℕ → ℝ) => e i) (nu r) :=
    iIndepFun_infinitePi (X := fun _ x => x) (fun _ => measurable_id)
  have hindY : iIndepFun Y (nu r) := hind.comp (fun _ => trunc) (fun _ => measurable_trunc)
  have hmY : ∀ i, Measurable (Y i) := fun i => measurable_trunc.comp (measurable_pi_apply i)
  have hint : Integrable (Y 0) (nu r) := by
    refine Integrable.of_bound (hmY 0).aestronglyMeasurable 1 (Eventually.of_forall fun e => ?_)
    simp only [hY, trunc, Real.norm_eq_abs]
    rw [abs_le]; constructor
    · have := le_max_right (min (e 0) 1) 0; linarith
    · exact max_le (min_le_right _ _) zero_le_one
  have hident : ∀ i, IdentDistrib (Y i) (Y 0) (nu r) (nu r) := by
    intro i
    refine ⟨(hmY i).aemeasurable, (hmY 0).aemeasurable, ?_⟩
    have h1 : Y i = trunc ∘ (fun e : ℕ → ℝ => e i) := rfl
    have h2 : Y 0 = trunc ∘ (fun e : ℕ → ℝ => e 0) := rfl
    rw [h1, h2, ← Measure.map_map measurable_trunc (measurable_pi_apply i),
      ← Measure.map_map measurable_trunc (measurable_pi_apply 0),
      Measure.infinitePi_map_eval, Measure.infinitePi_map_eval]
  have hslln := strong_law_ae Y hint (fun i j hij => hindY.indepFun hij) hident
  have hmean : 0 < ∫ e, Y 0 e ∂(nu r) := by
    have hnn : 0 ≤ᵐ[nu r] Y 0 := Eventually.of_forall fun e => le_max_right _ _
    rw [integral_pos_iff_support_of_nonneg_ae hnn hint, pos_iff_ne_zero]
    intro h0
    have h1 := measure_eq_zero_iff_ae_notMem.1 h0
    have : ∀ᵐ e ∂(nu r), False := by
      filter_upwards [h1, hpos] with e h1 h2
      simp only [Function.mem_support, ne_eq, not_not, hY, trunc] at h1
      have : 0 < min (e 0) 1 := lt_min (h2 0) zero_lt_one
      have := le_max_left (min (e 0) 1) 0
      linarith
    rw [Filter.eventually_false_iff_eq_bot, ae_eq_bot] at this
    exact IsProbabilityMeasure.ne_zero _ this
  filter_upwards [hpos, hslln] with e hp hl
  refine ⟨hp, fun t => ?_⟩
  have hS : Tendsto (fun n : ℕ => ∑ i ∈ Finset.range n, Y i e) atTop atTop := by
    have := tendsto_natCast_atTop_atTop.atTop_mul_pos hmean hl
    refine this.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    simp only [smul_eq_mul]
    have : (n : ℝ) ≠ 0 := by positivity
    field_simp
  have hle : ∀ n, ∑ i ∈ Finset.range n, Y i e ≤ T e n := by
    intro n
    simp only [T, callTime]
    refine Finset.sum_le_sum fun i _ => ?_
    simp only [hY, trunc]
    exact max_le (min_le_left _ _) (hp i).le
  obtain ⟨n, hn⟩ := (hS.eventually_gt_atTop t).exists
  exact ⟨n, hn.trans_le (hle n)⟩

lemma finite_of_nice {e : ℕ → ℝ} (h : Nice e) (t : ℝ) : {n : ℕ | T e n ≤ t}.Finite := by
  obtain ⟨N, hN⟩ := h.2 t
  refine (Set.finite_lt_nat N).subset fun n hn => ?_
  by_contra hc
  simp only [mem_ofPred_eq, not_lt] at hn hc
  linarith [(T_strictMono h.1).monotone hc]

lemma CG_ofFn : ∀ (q : ℕ) (t : Fin (q + 1) → ℝ) (k : Fin q → ℕ) (K : ℕ) (e : ℕ → ℝ),
    cnt e (t 0) = K →
    (CG (List.ofFn fun j : Fin q => (t j.succ - t j.castSucc, k j)) (t 0) K e ↔
      ∀ j : Fin q, (cnt e (t j.succ) : ℤ) - cnt e (t j.castSucc) = k j) := by
  intro q
  induction q with
  | zero => intros; simp [CG]
  | succ q ih =>
    intro t k K e hK
    rw [List.ofFn_succ, Fin.forall_fin_succ]
    simp only [CG]
    have ht : t 0 + (t (Fin.succ 0) - t (Fin.castSucc 0)) = t (Fin.succ 0) := by
      simp
    rw [ht]
    have := ih (fun i => t i.succ) (fun i => k i.succ) (K + k 0) e
    simp only [Fin.succ_castSucc] at this
    simp only [Fin.castSucc_zero]
    constructor
    · rintro ⟨h1, h2⟩
      refine ⟨by rw [h1, hK]; push_cast; ring, (this h1).1 h2⟩
    · rintro ⟨h1, h2⟩
      have h1' : cnt e (t (Fin.succ 0)) = K + k 0 := by rw [hK] at h1; omega
      exact ⟨h1', (this h1').2 h2⟩

lemma law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {E : ℕ → Ω → ℝ} (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure r) P) :
    HasLaw (fun ω i => E i ω) (nu r) P :=
  hind.hasLaw_infinitePi hexp (aemeasurable_pi_iff.2 fun i => (hexp i).aemeasurable)

end Helpers

#print axioms T_zero
#print axioms T_succ
#print axioms T_tl
#print axioms T_cs_succ
#print axioms T_cs_tl
#print axioms T_strictMono
#print axioms cnt_def
#print axioms cnt_eq_iff
#print axioms cnt_zero
#print axioms nice_tl
#print axioms nice_cs
#print axioms cnt_tl
#print axioms cnt_cs
#print axioms CG_tl
#print axioms CG_cs
#print axioms good_iff
#print axioms measurable_tl
#print axioms measurable_cs
#print axioms cs_tl
#print axioms poi_nonneg
#print axioms expMeasure_eq
#print axioms measurable_exponentialPDF
#print axioms lintegral_memoryless
#print axioms lintegral_window
#print axioms nu_split
#print axioms nu_split_apply
#print axioms nu_cs
#print axioms measurableSet_G
#print axioms measurableSet_Good
#print axioms nu_G
#print axioms nu_Good
#print axioms expMeasure_Iic_zero
#print axioms ae_pos
#print axioms measurable_trunc
#print axioms ae_nice
#print axioms finite_of_nice
#print axioms CG_ofFn
#print axioms law

/-- **Counts in a window are Poisson.** Let the gaps between calls `E_1, E_2, ...` be
independent, each exponential with rate `λ > 0`. Build the call times `T_n = E_1 + ... + E_n`
and the count `N(t)` = the largest `n` with `T_n ≤ t`. Then for every window from `s` to
`s + t` (with `s, t ≥ 0`) and every whole number `k`, the chance of exactly `k` calls in the
window is `e^(-λt) (λt)^k / k!`: the Poisson chance with mean rate times length, wherever the
window sits. -/
theorem increment_is_poisson {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (rate : ℝ) (hrate : 0 < rate) (E : ℕ → Ω → ℝ)
    (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure rate) P)
    (s t : ℝ) (hs : 0 ≤ s) (ht : 0 ≤ t) (k : ℕ) :
    P.real {ω | ((count E (s + t) ω : ℤ) - count E s ω) = k} =
      exp (-(rate * t)) * (rate * t) ^ k / k ! := by
  have := isProbabilityMeasure_expMeasure hrate
  have hL := law (r := rate) hind hexp
  have hsum : HasSum (fun n => poi rate s n) 1 := by
    have := hasSum_one_poissonMeasure ⟨rate * s, mul_nonneg hrate.le hs⟩
    exact this
  set Z : Set (ℕ → ℝ) := {e | ((cnt e (s + t) : ℤ) - cnt e s) = k} with hZdef
  set ZK : ℕ → Set (ℕ → ℝ) := fun K => {e | cnt e s = K ∧ cnt e (s + t) = K + k} with hZKdef
  have hZ : Z = ⋃ K, ZK K := by
    ext e
    simp only [hZdef, hZKdef, Set.mem_ofPred_eq, Set.mem_iUnion]
    constructor
    · intro h; exact ⟨cnt e s, rfl, by omega⟩
    · rintro ⟨K, h1, h2⟩; rw [h1, h2]; push_cast; ring
  have hLnn : ∀ K : ℕ, ∀ p ∈ [(s, K), (t, k)], 0 ≤ p.1 := by
    intro K p hp
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hp
    rcases hp with rfl | rfl <;> assumption
  have hae : ∀ K, ZK K =ᵐ[nu rate] Good [(s, K), (t, k)] := by
    intro K
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [ae_nice hrate] with e he
    rw [good_iff _ (hLnn K) e he]
    simp only [hZKdef, Set.mem_ofPred_eq, CG, zero_add, and_true]
  have hnm : ∀ K, NullMeasurableSet (ZK K) (nu rate) := fun K =>
    (measurableSet_Good _).nullMeasurableSet.congr (hae K).symm
  have hdisj : Pairwise (Function.onFun (AEDisjoint (nu rate)) ZK) := by
    intro K K' hKK'
    refine Disjoint.aedisjoint (Set.disjoint_left.2 fun e h1 h2 => hKK' ?_)
    exact h1.1.symm.trans h2.1
  have hZm : NullMeasurableSet Z (nu rate) := by rw [hZ]; exact NullMeasurableSet.iUnion hnm
  have hset : {ω | ((count E (s + t) ω : ℤ) - count E s ω) = k} = (fun ω i => E i ω) ⁻¹' Z := rfl
  rw [hset, measureReal_def, ← Measure.map_apply₀ hL.aemeasurable (by rw [hL.map_eq]; exact hZm),
    hL.map_eq, hZ, measure_iUnion₀ hdisj hnm,
    tsum_congr (fun K => (measure_congr (hae K)).trans (nu_Good hrate _ (hLnn K)))]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, mul_one]
  simp_rw [ENNReal.ofReal_mul (poi_nonneg hrate.le hs _)]
  rw [ENNReal.tsum_mul_right, ← ENNReal.ofReal_tsum_of_nonneg (fun n => poi_nonneg hrate.le hs n)
    hsum.summable, hsum.tsum_eq, ENNReal.ofReal_one, one_mul,
    ENNReal.toReal_ofReal (poi_nonneg hrate.le ht k)]
  rfl

/-- **Counts in back-to-back windows are independent.** With the same gaps, take window ends
`0 = t_0 < t_1 < ... < t_q`. For every choice of counts `k_1, ..., k_q`, the chance of exactly
`k_j` calls in window `j` for every `j` at once is the product over the windows of the Poisson
chances `e^(-λ(t_j - t_(j-1))) (λ(t_j - t_(j-1)))^(k_j) / k_j!`. -/
theorem increments_independent {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (rate : ℝ) (hrate : 0 < rate) (E : ℕ → Ω → ℝ)
    (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure rate) P)
    (q : ℕ) (t : Fin (q + 1) → ℝ) (ht0 : t 0 = 0) (hmono : StrictMono t) (k : Fin q → ℕ) :
    P.real (⋂ j : Fin q,
        {ω | ((count E (t j.succ) ω : ℤ) - count E (t j.castSucc) ω) = k j}) =
      ∏ j : Fin q, exp (-(rate * (t j.succ - t j.castSucc))) *
        (rate * (t j.succ - t j.castSucc)) ^ (k j) / (k j) ! := by
  have := isProbabilityMeasure_expMeasure hrate
  have hL := law (r := rate) hind hexp
  set L := List.ofFn fun j : Fin q => (t j.succ - t j.castSucc, k j) with hLdef
  have hLnn : ∀ p ∈ L, 0 ≤ p.1 := by
    intro p hp
    rw [hLdef, List.mem_ofFn] at hp
    obtain ⟨j, rfl⟩ := hp
    exact sub_nonneg.2 (hmono Fin.castSucc_lt_succ).le
  set Y : Set (ℕ → ℝ) :=
    {e | ∀ j : Fin q, (cnt e (t j.succ) : ℤ) - cnt e (t j.castSucc) = k j} with hYdef
  have hset : (⋂ j : Fin q,
      {ω | ((count E (t j.succ) ω : ℤ) - count E (t j.castSucc) ω) = k j}) =
      (fun ω i => E i ω) ⁻¹' Y := by
    ext ω
    simp only [Set.mem_iInter, Set.mem_ofPred_eq, Set.mem_preimage, hYdef]
    rfl
  have hae : Y =ᵐ[nu rate] Good L := by
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [ae_nice hrate] with e he
    rw [good_iff L hLnn e he]
    have h0 : cnt e (t 0) = 0 := by rw [ht0]; exact cnt_zero he
    have := CG_ofFn q t k 0 e h0
    rw [ht0] at this
    exact this.symm
  have hY : NullMeasurableSet Y (Measure.map (fun ω i => E i ω) P) := by
    rw [hL.map_eq]; exact (measurableSet_Good L).nullMeasurableSet.congr hae.symm
  have hprod : 0 ≤ (L.map fun p => poi rate p.1 p.2).prod :=
    List.prod_nonneg fun a ha => by
      obtain ⟨p, hp, rfl⟩ := List.mem_map.1 ha
      exact poi_nonneg hrate.le (hLnn p hp) _
  rw [hset, measureReal_def, ← Measure.map_apply₀ hL.aemeasurable hY, hL.map_eq,
    measure_congr hae, nu_Good hrate L hLnn, ENNReal.toReal_ofReal hprod, hLdef, List.map_ofFn,
    List.prod_ofFn]
  rfl

/-- **The calls never pile up.** With the same gaps, with probability one only finitely many
calls come by any time `t`: the set of `n` with `T_n ≤ t` is finite for every `t`. -/
theorem calls_never_pile_up {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (rate : ℝ) (hrate : 0 < rate) (E : ℕ → Ω → ℝ)
    (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure rate) P) :
    ∀ᵐ ω ∂P, ∀ t : ℝ, {n : ℕ | callTime E n ω ≤ t}.Finite := by
  have := isProbabilityMeasure_expMeasure hrate
  have hL := law (r := rate) hind hexp
  have h : ∀ᵐ ω ∂P, Nice (fun i => E i ω) :=
    ae_of_ae_map hL.aemeasurable (by rw [hL.map_eq]; exact ae_nice hrate)
  filter_upwards [h] with ω hω t
  exact finite_of_nice hω t

/-! The card's worked numbers: `λ = 4` calls an hour, a quarter hour `t = 1/4`. -/

-- Expected calls in the quarter hour: λt = 4 × 1/4 = 1; the mean gap is 1/4 hour = 15 minutes.
example : (4 : ℝ) * (1 / 4) = 1 ∧ (1 : ℚ) / 4 * 60 = 15 := by norm_num
-- No call: e^(-1). Exactly one: e^(-1) × 1^1 / 1!. Exactly two: e^(-1) / 2. Exactly three: e^(-1) / 6.
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 0 / (0 ! : ℝ) = exp (-1) := by
  norm_num
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 1 / (1 ! : ℝ) = exp (-1) := by
  norm_num
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 2 / (2 ! : ℝ) = exp (-1) / 2 := by
  norm_num [Nat.factorial]
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 3 / (3 ! : ℝ) = exp (-1) / 6 := by
  norm_num [Nat.factorial]
-- Four or more: 1 - e^(-1) (1 + 1 + 1/2 + 1/6) = 1 - (8/3) e^(-1).
example : 1 - (exp (-1) + exp (-1) + exp (-1) / 2 + exp (-1) / 6) = 1 - 8 / 3 * exp (-1) := by
  ring
-- Three calls in the half hour: λt = 4 × 1/2 = 2, and e^(-2) × 2^3 / 3! = (4/3) e^(-2).
example : exp (-((4 : ℝ) * (1 / 2))) * ((4 : ℝ) * (1 / 2)) ^ 3 / (3 ! : ℝ) = 4 / 3 * exp (-2) := by
  norm_num [Nat.factorial]; ring
-- Running totals: variances 4 × 1/4 = 1 and 4 × 1/2 = 2, covariance 4 × 1/4 = 1,
-- correlation 1 / √(1 × 2) = 1/√2.
example : (4 : ℝ) * (1 / 4) / √((4 * (1 / 4)) * (4 * (1 / 2))) = 1 / √2 := by norm_num
-- The chart's mean line: 4 calls an hour over two hours is 8.
example : (4 : ℕ) * 2 = 8 := by norm_num

#print axioms increment_is_poisson
#print axioms increments_independent
#print axioms calls_never_pile_up

end PoissonProcess
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'PoissonProcess.T_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.T_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.T_tl' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.T_cs_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.T_cs_tl' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.T_strictMono' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.cnt_def' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.cnt_eq_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.cnt_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.nice_tl' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.nice_cs' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.cnt_tl' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.cnt_cs' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.CG_tl' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.CG_cs' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.good_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.measurable_tl' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.measurable_cs' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.cs_tl' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.poi_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.expMeasure_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.measurable_exponentialPDF' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.lintegral_memoryless' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.lintegral_window' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.nu_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.nu_split_apply' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.nu_cs' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.measurableSet_G' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.measurableSet_Good' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.nu_G' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.nu_Good' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.expMeasure_Iic_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.ae_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.measurable_trunc' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.ae_nice' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.finite_of_nice' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.CG_ofFn' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.law' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.increment_is_poisson' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.increments_independent' depends on axioms: [propext, Classical.choice, Quot.sound]
'PoissonProcess.calls_never_pile_up' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Double the rate, halve the window.** Set `LAM = 8.0` and `WIN = 0.125`. Only $\lambda t$ = 1 enters the law, so the formula column stays at 0.367879 down to 0.003066.
> - **Watch a half hour instead.** Set `WIN = 0.5`. The mean count becomes 2, no call has chance $e^{-2}$ = 0.1353, and exactly three calls 0.1804.
> - **Swap the gap law.** Replace the exponential gap by `0.5 * uniform()`, same 15-minute mean. The asserts fail: the first quarter hour is empty about half the time (exactly 0.5), and consecutive quarters correlate near −0.29.

---

## The usual mistake

> [!warning]
> **Reading independent increments as independent totals.** The calls in 9:00 to 9:15 and in 9:15 to 9:30 are independent. The totals by 9:15 and by 9:30 are not: the second contains the first. Treating them as independent gives 0.0996 for "1 by quarter past, 2 by half past" instead of 0.1353, and misses a correlation of 0.7071.
>
> - **"A call is due."** After a quiet quarter hour, the wait for the next call still averages 15 minutes. Silence does not build up credit.
> - **Right mean, wrong shape.** Evenly spread gaps with the same 15-minute mean leave the first quarter hour empty half the time. Only exponential gaps give the Poisson table.
> - **1 − $\lambda t$ for "no call".** Fine for a few seconds. For a quarter hour it gives 0 instead of 0.3679.
> - **Mixed units.** The rate is per hour, so the window is 0.25, not 15.

---

## Where you meet it in real life

- **Telephone exchanges.** Agner Krarup Erlang, at the Copenhagen Telephone Company, used this model early in the twentieth century to size exchanges. Queues fed by it are on [Continuous-time chains](05-continuous-time-markov-chains-and-queues.md) and [Queues](../../14-Applied%20and%20computational/05-Operations%20Research/07-queueing-theory-and-littles-law.md).
- **Radioactive decay.** Clicks of a Geiger counter near a long-lived source: each atom decays independently, and the rate barely changes over an afternoon.
- **Insurance claims.** Claims arrive as a Poisson process; attach a random size to each and the total is [Compound Poisson](04-compound-poisson.md), the base of the classical ruin model.
- **Jumps in prices.** Models of sudden price moves place jumps at Poisson times; the general family is [Levy processes](../09-Beyond%20Brownian/01-levy-processes.md).

> **Say it back**
> Add up independent exponential gaps to get call times, and count the calls so far. The exponential forgets how long it has waited, so at any fixed moment the process starts afresh. Given k calls in a window, every ordered arrangement of them is equally likely, and those arrangements fill a share 1/k! of the cube. That makes the count Poisson with mean rate times length. Separate windows get independent counts; running totals share early calls and are correlated.

---

## What this builds on

- [Stochastic processes](../01-Random%20Walks%20and%20Filtrations/01-processes-and-paths.md): a process as one random variable per time, and a path as one outcome followed through time. The staircase of calls is such a path.
- [Exponential](../../09-Probability%20and%20statistics/04-Continuous%20Distributions/03-exponential-distribution.md): the gap law and its lack of memory, which is Step 0.
- [Poisson](../../09-Probability%20and%20statistics/03-Discrete%20Distributions/04-poisson.md): the Poisson law itself, its mean equal to its variance, and the binomial limit behind the slot road.

## Where this goes next

- [Given n arrivals, when did they happen](02-arrival-times-and-order-statistics.md): given k calls in a window, their times are k uniform points put in order, Step 2 read backwards.
- [Splitting and merging](03-splitting-and-superposition.md): sorting one stream into two, and merging two into one.
- [Compound Poisson](04-compound-poisson.md): a random amount attached to each arrival, summed.
- [Continuous-time chains](05-continuous-time-markov-chains-and-queues.md): exponential waits between changes of state, with a rate matrix in place of one rate.
- [Renewal processes](06-renewal-processes-in-outline.md): independent gaps of any law, such as the evenly spread gaps above.
- [Levy processes](../09-Beyond%20Brownian/01-levy-processes.md): independent, stationary increments in general, built from Poisson jumps and Brownian motion.
- [Queues](../../14-Applied%20and%20computational/05-Operations%20Research/07-queueing-theory-and-littles-law.md): Poisson arrivals meeting a server.

This card fixes how many calls a window holds; where inside the window they sit is what the arrival-times card answers.

---

## Sources

Verified 30 Sep 2026: every link below resolves to the publisher's page.

- Durrett, Rick. *Probability: Theory and Examples*, 5th ed. Cambridge University Press, 2019. [doi:10.1017/9781108591034](https://doi.org/10.1017/9781108591034). Section 3.7 builds the process from exponential gaps, proves the Poisson counts, and gives the short-window definition.
- Last, Günter, and Mathew Penrose. *Lectures on the Poisson Process*. Cambridge University Press, 2017. [doi:10.1017/9781316104477](https://doi.org/10.1017/9781316104477). Poisson points on a general space; calls on a time line are the simplest case.
- Ross, Sheldon M. *Introduction to Probability Models*, 13th ed. Elsevier. [Publisher page](https://shop.elsevier.com/books/introduction-to-probability-models/ross/978-0-443-18761-2). Chapter 5, "The Exponential Distribution and the Poisson Process": the applied route.
