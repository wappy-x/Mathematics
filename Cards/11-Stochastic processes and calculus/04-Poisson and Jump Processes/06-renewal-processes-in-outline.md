# Renewal processes: arrivals with any gap distribution

[Syllabus](../../../SYLLABUS.md) → [Stochastic processes and calculus](../README.md) → [Poisson and Jump Processes](../README.md#s04) → Renewal processes

---

## General Overview

A bus stop is served by one route. After each bus leaves, the next one comes either 5 minutes later or 15 minutes later, like a coin toss, and each gap is decided afresh. The average gap is 10 minutes, so over a long day six buses an hour pass the stop.

A passenger who turns up without a timetable waits for the next bus. The natural guess is half the average gap, 5 minutes. The true average is 6.25. A passenger is three times as likely to walk into a 15-minute gap as a 5-minute one, because long gaps cover three quarters of the clock.

Arrivals whose gaps are independent and share one law, any law, form a **renewal process**: each arrival renews the stop, and the future then looks as it did at the start. The Poisson process ([Poisson process](01-poisson-process.md)) is the case with exponential gaps. Two facts hold for every gap law. The **elementary renewal theorem**: in the long run, arrivals come at one per mean gap. The **inspection paradox**: a random moment tends to fall in a long gap, so the wait is at least half the mean gap, and more whenever the gaps vary.

**Over a long time, arrivals come at one per mean gap; but a moment picked at random lands in gaps in proportion to their length, so the average wait is the mean square gap over twice the mean gap.**

**What kind of fact this is:** a theorem, in two parts, both proved on this card in Why it works; a sharper statement about a fixed far-off time is quoted with its source.

### The picture: the wait, minute by minute, over one hour

One hour, to scale, with gaps of 5, 15, 5, 5, 15, 15 minutes, chosen by hand rather than drawn at random so that each length appears as often as its chance says. Height is the wait for a passenger arriving at that minute: it starts at the full gap just after a bus leaves and falls to zero as the next one pulls in. Long gaps are shaded.

<p align="center"><img src="../figures/renewal-processes-in-outline.svg" alt="Sawtooth of the waiting time over one hour, gaps 5, 15, 5, 5, 15, 15 minutes, long teeth shaded, mean wait 6.25 minutes dashed" width="420"></p>

The area under the teeth, divided by the 60 minutes, is the average wait over the hour: 6.25 minutes, the dashed line. A small tooth has area 12.5 and a large one 112.5: nine times the area from three times the gap. Both checks print the coordinates on their `figure,` lines.

---

## The formula

Notation first, in words. The gaps are $X_1, X_2, \dots$: $X_k$ is the time between bus $k-1$ and bus $k$, with bus 0 leaving at time 0. They are independent and all follow the same law, written $X$ for a typical one. The time of bus $n$ is $S_n = X_1 + \dots + X_n$. As on the Poisson card, $N(t)$ counts the arrivals up to time $t$: the number of $n \ge 1$ with $S_n \le t$. Its average is written $m(t) = E[N(t)]$, the **renewal function**.

**Part 1, the elementary renewal theorem.** If the mean gap $\mu = E[X]$ is finite and positive,

$$\lim_{t \to \infty} \frac{N(t)}{t} = \frac{1}{\mu} \ \text{ almost surely}, \qquad \lim_{t \to \infty} \frac{m(t)}{t} = \frac{1}{\mu}.$$

**Read it aloud:** over a long stretch, the number of buses per minute settles at one over the mean gap, on almost every run and on average.

**Part 2, the inspection paradox.** A passenger arrives at a time spread evenly over a long stretch. Let $L$ be the length of the gap the passenger lands in, and $W$ the wait for the next bus. In the long run,

$$P(L = x) = \frac{x \, P(X = x)}{\mu}, \qquad E[W] = \frac{E[X^2]}{2\mu} = \frac{\mu}{2} + \frac{\sigma^2}{2\mu}.$$

**Read it aloud:** each gap length is seen in proportion to its chance times its length; the average wait is half the mean gap plus a penalty that grows with how uneven the gaps are.

For gaps with a density instead of a list of values, replace the chance $P(X = x)$ by the density; nothing else changes.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $X_k$, $X$ | the gap before bus $k$; a typical gap | 5 or 15 minutes | — |
| $\mu$ | mean gap, $E[X]$ | 10 minutes | rate falls, wait rises |
| $E[X^2]$ | mean of the squared gap | 125 square minutes | wait rises |
| $\sigma^2$ | variance of the gap, $E[X^2] - \mu^2$ | 25 square minutes | wait rises; the rate does not move |
| $S_n$ | time of bus $n$ | bus 2 comes at 10, 20 or 30 | — |
| $t$, $s$ | clock time; $s$ a passenger's arrival time, in minutes | 60 in the hand table | — |
| $N(t)$ | buses after time 0 up to time $t$ | about 6 per hour | — |
| $m(t)$ | average of $N(t)$ | 5.870850 at $t$ = 60 | — |
| $L$ | length of the gap a random passenger lands in | 15 with chance 0.75 | — |
| $W$ | the passenger's wait | 6.25 minutes on average | — |
| $k$, $n$, $a$, $b$, $\mu_b$ | counters; in the proof, a floor $a$ and a cap $b$ on gap length, and $\mu_b$ the capped mean | — | — |
| $T$, $q$ | in the proof: the index of the first bus after $t$, $N(t) + 1$; the chance $P(X \ge a)$ that a gap reaches the floor | — | — |
| $\bar X_k$, $\bar N(t)$, $\bar m(t)$ | in the proof: gap $k$ capped at $b$; the count of buses with capped gaps, and its average | — | — |

### When it holds

- **Independent gaps with one law.** Make every gap copy the first and the average rate is 8 buses an hour, not 6.
- **A finite mean gap.** If $\mu$ is infinite, $N(t)/t$ goes to 0. Part 2 also needs a finite $E[X^2]$; without it the average wait is infinite even when the mean gap is not.
- **Arrival times spread evenly, blind to the buses.** Part 2 averages over arrival times. A passenger who always arrives on a 5-minute mark, the buses' grid, waits 3.75 minutes on average, not 6.25, when a bus that pulls in at that very moment counts as caught, a wait of 0.
- **Gaps off any grid, for claims at a fixed time.** The average number of buses in the minute after a fixed far-off time settles at $1/\mu$ only when the gaps are not all multiples of one step: Blackwell's renewal theorem, stated in Feller's volume II (Sources), not proved here. This card's gaps sit on a 5-minute grid, so it averages over time throughout.

---

## Why it works

### Step 0: each bus restarts the clock

After bus $n$ leaves, the gaps still to come are $X_{n+1}, X_{n+2}, \dots$. They are independent of everything before, with the same law as the original gaps. So the stop, watched from time $S_n$, is a fresh copy of the stop watched from time 0. Every argument below rests on this, together with the strong law of large numbers ([The strong law of large numbers](../../10-Measure%20and%20integration/10-The%20Limit%20Theorems%2C%20Proved/04-strong-law-of-large-numbers.md)): the average of the first $n$ gaps tends to $\mu$ on almost every run.

### Step 1: the count is squeezed between two bus times

At time $t$ exactly $N(t)$ buses have come, so bus $N(t)$ is at or before $t$ and bus $N(t)+1$ is after it:

$$S_{N(t)} \le t < S_{N(t)+1}.$$

At $t$ = 60 minutes, if 5 buses have come, the fifth is at or before minute 60 and the sixth is later.

### Step 2: divide by the count, and the rate appears

Divide the squeeze by $N(t)$. The left side, $S_{N(t)}/N(t)$, is the average of the first $N(t)$ gaps. As $t$ grows, $N(t)$ grows without limit, because each gap is finite. So by the strong law the left side tends to $\mu$. The right side is $S_{N(t)+1}/(N(t)+1)$ times $(N(t)+1)/N(t)$, which tends to $\mu$ times 1. The middle, $t/N(t)$, is trapped between them, so it tends to $\mu$ too, on almost every run. Turn it over: $N(t)/t$ tends to $1/\mu$, one bus per 10 minutes, 6 an hour.

### Step 3: the average count, through Wald's identity

Almost-sure convergence does not by itself carry over to averages, so $m(t)/t$ needs its own argument.

The index $N(t)+1$ is a **stopping time** ([Stopping times](../02-Martingales/03-stopping-times-and-optional-stopping.md)): whether bus $n$ is the first after $t$ is known from the first $n$ gaps. For such an index, **Wald's identity** says the average total of the gaps is the average number of gaps times the mean gap:

$$E[S_{N(t)+1}] = \mu \,\big(m(t) + 1\big).$$

Now take averages in the squeeze. The first bus after $t$ is after $t$, and in this example it is at most 15 minutes after, since no gap exceeds 15. So $t < \mu(m(t)+1) \le t + 15$, which gives

$$\frac{t}{\mu} - 1 < m(t) \le \frac{t + 15}{\mu} - 1.$$

At $t$ = 60 this says the average count lies above 5 and at most 6.5; the exact value is 5.870850. Divide by $t$ and let $t$ grow: both bounds tend to $1/\mu$.

With unbounded gaps the upper bound needs one more move, capping every gap at a level $b$; the folded proof below does it.

<details>
<summary>Detailed proof: Wald's identity, and the elementary renewal theorem for any gap law</summary>

**Wald's identity.** Write $T = N(t)+1$. Then $S_T = \sum_{k \ge 1} X_k \, 1\{T \ge k\}$. The event $T \ge k$ is the event $S_{k-1} \le t$, which depends only on $X_1, \dots, X_{k-1}$, so it is independent of $X_k$. Every term is non-negative, so the sum and the average can be swapped (monotone convergence, wing 10): $E[S_T] = \sum_k E[X_k] \, P(T \ge k) = \mu \sum_k P(T \ge k) = \mu \, E[T]$. The last step is the tail-sum formula for a count: $E[T] = \sum_{k \ge 1} P(T \ge k)$. For $E[T]$ to be finite: the gaps are not all zero, so some $a > 0$ has $P(X \ge a) = q > 0$; the count of gaps up to time $t$ is at most the count of tries until $\lceil t/a \rceil + 1$ gaps of at least $a$ have appeared, whose average is finite.

**Lower bound.** $S_T > t$, so $\mu(m(t)+1) > t$, and $\liminf m(t)/t \ge 1/\mu$. If $\mu$ is infinite this says nothing, and the upper bound alone gives the limit 0.

**Upper bound.** Fix a cap $b$ and let $\bar X_k = \min(X_k, b)$, with mean $\mu_b$. The capped gaps form a renewal process whose buses come no later than the originals, so its count $\bar N(t) \ge N(t)$. Its first bus after $t$ overshoots $t$ by at most $b$, so Wald gives $\mu_b(\bar m(t) + 1) \le t + b$. Hence $m(t)/t \le \bar m(t)/t \le (t+b)/(t\mu_b)$, and $\limsup m(t)/t \le 1/\mu_b$. As $b$ grows, $\mu_b$ rises to $\mu$ by monotone convergence, so $\limsup m(t)/t \le 1/\mu$. With the lower bound, $m(t)/t \to 1/\mu$.

</details>

### Step 4: the wait, as area under a sawtooth

A passenger arriving at time $s$ waits from $s$ to the next bus. Plotted against $s$, that is the sawtooth in the picture: in a gap of length $x$ it falls from $x$ to 0, a triangle of area $x^2/2$.

The average wait over arrivals spread evenly on $[0, t]$ is the area under the sawtooth divided by $t$. Up to the one unfinished tooth at the end, that is

$$\frac{1}{t}\sum_{k=1}^{N(t)} \frac{X_k^2}{2} \;=\; \frac{N(t)}{t} \cdot \frac{1}{N(t)} \sum_{k=1}^{N(t)} \frac{X_k^2}{2}.$$

The first factor tends to $1/\mu$ by Step 2. The second is an average of independent copies of $X^2/2$, so by the strong law it tends to $E[X^2]/2$. The product tends to $E[X^2]/(2\mu)$: 125 over 20, 6.25 minutes. The unfinished tooth, divided by $t$, vanishes when $E[X^2]$ is finite.

This argument, a reward per gap averaged over time, is the **renewal-reward theorem** in outline: long-run reward per minute equals mean reward per gap over mean gap length.

### Step 5: the same answer by length bias

Change the reward to the minutes spent in 15-minute gaps. Per gap it averages 0.5 × 15; over the mean gap of 10 that makes 0.75 of all time, and short gaps take 0.25. So a passenger lands in a long gap with chance 0.75, not 0.5: that is $P(L = x) = x P(X = x)/\mu$.

Within its gap the arrival is spread evenly, so the wait averages half the gap: 2.5 or 7.5 minutes. Together, 0.25 × 2.5 + 0.75 × 7.5 = 6.25 minutes, by a different path. The average gap a passenger finds is $E[X^2]/\mu$ = 12.5 minutes, not 10.

<details>
<summary>Why the variance appears</summary>

Write $E[X^2] = \mu^2 + \sigma^2$. Then $E[X^2]/(2\mu) = \mu/2 + \sigma^2/(2\mu)$. Buses exactly 10 minutes apart have $\sigma^2 = 0$ and a wait of half the gap. Unevenness adds to the wait while leaving the rate alone; here the penalty is 25 over 20, 1.25 minutes.

</details>

### The other door: the Poisson case

With exponential gaps of mean $\mu$, $E[X^2] = 2\mu^2$ and the formula gives a wait of $\mu$: the full mean gap, not half. That is the memoryless property of [Poisson process](01-poisson-process.md). At the shelf's switchboard, with calls at 4 an hour, an operator who looks up at a random moment waits 15 minutes on average for the next call, not 7.5.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| mean gap $\mu$ | 0.5 × 5 + 0.5 × 15 | 10 minutes |
| rate | 1 / 10 per minute | **6 buses an hour** |
| mean square gap | 0.5 × 25 + 0.5 × 225 | 125 |
| variance | 125 − 10 × 10 | 25 |
| sandwich for $m(60)$ | 60/10 − 1 and 75/10 − 1 | between 5 and 6.5 |
| share of time in 15-minute gaps | 0.5 × 15 / 10 | 0.75 |
| share of time in 5-minute gaps | 0.5 × 5 / 10 | 0.25 |
| wait inside each kind of gap | half the gap | 2.5 and 7.5 minutes |
| **mean wait** | 0.25 × 2.5 + 0.75 × 7.5 | **6.25 minutes** |
| gap a passenger lands in, on average | 125 / 10 | 12.5 minutes |

A passenger who turns up at random waits 6.25 minutes, a quarter longer than half the average gap, and 125 / (2 × 10) agrees.

### How fast the rate settles

The exact average count, from the recursion in the code, divided by the time, in buses per hour:

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Average buses per hour up to time t, m(t)/t x 60"
    x-axis "t (minutes)" [15, 30, 60, 120, 240, 480]
    y-axis "Buses per hour" 5.4 --> 6.1
    line [5.50, 5.72, 5.87, 5.94, 5.97, 5.98]
    line [6, 6, 6, 6, 6, 6]
```

Rising line: $m(t)/t$ in buses per hour, exact. Flat line: the limit, 6 an hour. By the sandwich the shortfall is under one bus, so it shrinks like one over $t$.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Half the mean gap | 5 minutes, not 6.25 | averages over buses, not over the clock: short gaps are counted as often as long ones |
| The gap a passenger finds is the mean gap | 10 minutes, not 12.5 | same slip; long gaps are three quarters of the clock |
| Passenger always arrives on a 5-minute mark | 3.75 minutes, not 6.25 | arrival tied to the buses' grid; a thousandth of a minute later it is 8.749 |
| Every gap equal to the first one | 8 buses an hour, not 6 | gaps not independent: the rate averages a 5-minute stop and a 15-minute stop, not one over the average gap |

The third row is measured at minute 6000, with a bus that pulls in at that minute counted as caught; only the average over a whole 5-minute cell comes to 6.25. In the fourth, with chance 0.5 buses come every 5 minutes forever, else every 15, so $N(t)/t$ has no single limit.

---

## Code, from first principles, and it actually runs

Three roads.

- **Formulas:** rate and wait.
- **Exact recursion:** every gap is 1 or 3 five-minute steps, so the average count, the average overshoot past a time and the chance of a bus at each step obey short recursions over every bus pattern, each conditioning on the first gap (Step 0). They give $m(t)$, Wald's identity as two separate computations that must agree, and the exact average wait over arrivals in the first 60, 600 and 6000 minutes. A brute-force count over all 4096 patterns of the first 12 gaps confirms $m(60)$ = 24047/4096 in whole numbers.
- **Simulation:** SplitMix64 (a short random-number generator written into each script), seed 20260929; 40,000 passengers, each on a fresh run of buses, arriving evenly over the first 600 minutes; the switchboard; and one 1,000,000-minute run cut into 100 batches for the rate.

Each simulated number carries its standard error, and its assert allows four. The simulated wait is compared with the exact 600-minute value, 6.263021, since a stop that starts with a bus at time 0 has not yet reached the long run.

### Python

```python
# Renewal processes in outline -- the check behind the card.  Standard library
# only.  Buses leave a stop with gaps of 5 or 15 minutes, each with chance 0.5,
# the gaps independent.  Three roads: the formulas; an exact recursion over
# every bus pattern (in steps of 5 minutes, since every gap is a multiple of 5);
# and seeded simulations, each printed with its standard error.
from math import log, sqrt
MASK, SEED = (1 << 64) - 1, 20260929
GAPS, P = (5, 15), (0.5, 0.5)                 # minutes, and their chances

state = SEED
def unif():                                   # SplitMix64 -> a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
def bus_gap(): return 5.0 if unif() < 0.5 else 15.0
def exp_gap(): return -15.0 * log(1.0 - unif())   # house example: 4 calls an hour

# ---- road 1: the formulas ----
mu = sum(p * x for p, x in zip(P, GAPS))
ex2 = sum(p * x * x for p, x in zip(P, GAPS))
var = ex2 - mu * mu
wait = ex2 / (2 * mu)
long_share = P[1] * GAPS[1] / mu              # length-biased chance of a 15-minute gap
print(f"formula,mean gap mu,{mu:.6f}")
print(f"formula,mean square gap E[X^2],{ex2:.6f}")
print(f"formula,variance of gap,{var:.6f}")
print(f"formula,rate 1/mu per minute,{1 / mu:.6f}")
print(f"formula,rate per hour,{60 / mu:.6f}")
print(f"formula,mean wait E[X^2]/(2 mu),{wait:.6f}")
print(f"formula,mu/2 + var/(2 mu),{mu / 2 + var / (2 * mu):.6f}")
print(f"formula,share of time in 15-min gaps,{long_share:.6f}")
print(f"formula,mean gap a passenger lands in,{ex2 / mu:.6f}")
print(f"hand,share of time in 5-min gaps,{P[0] * GAPS[0] / mu:.6f}")
print(f"hand,mean wait inside a 5-min / 15-min gap,{GAPS[0] / 2:.6f} {GAPS[1] / 2:.6f}")
print(f"hand,extra wait var/(2 mu),{var / (2 * mu):.6f}")
print(f"hand,sandwich at t=60 lower upper,{60 / mu - 1:.6f} {75 / mu - 1:.6f}")
print(f"formula,wait at a 5-minute mark,{5 * sum(p * (x // 5) * (x // 5 - 1) / 2 for p, x in zip(P, GAPS)) / (mu / 5):.6f}")

# ---- road 2: exact recursion, step = 5 minutes, gaps of 1 or 3 steps ----
K = 1200                                      # 6000 minutes
steps = [(x // 5, p) for x, p in zip(GAPS, P)]
m = [0.0] * (K + 2)                           # m[k] = E[N(5k)], buses after time 0 up to 5k
D = [0.0] * (K + 2)                           # D[k] = E[first bus at or after 5k] - 5k, in steps
u = [1.0] + [0.0] * (K + 1)                   # u[k] = chance a bus leaves at exactly 5k
for k in range(1, K + 2):
    m[k] = sum(p * (1 + m[k - s]) for s, p in steps if s <= k)
    D[k] = sum(p * (s - k if s >= k else D[k - s]) for s, p in steps)
    u[k] = sum(p * u[k - s] for s, p in steps if s <= k)
# brute force: all 2**12 patterns of 12 gaps (bit i set: gap i + 1 is 3 steps), buses by step 12, whole numbers
A12 = sum(sum(1 for n in range(1, 13) if sum(1 + 2 * ((b >> i) & 1) for i in range(n)) <= 12) for b in range(4096))
print(f"exact,E[N(60)] by brute force over all 4096 patterns of 12 gaps,{A12}/4096")
print(f"exact,E[N(60)],{m[12]:.6f}")
ok_bounds = all(5 * k / mu - 1 < m[k] <= (5 * k + 15) / mu - 1 for k in range(1, K + 1))
for t in (15, 30, 60, 120, 240, 480, 6000):
    print(f"exact,buses per hour m(t)/t*60 at t={t},{60 * m[t // 5] / t:.6f}")
print("chart,m(t)/t*60 at t=15 30 60 120 240 480," + " ".join(f"{60 * m[t // 5] / t:.2f}" for t in (15, 30, 60, 120, 240, 480)))
wald_l, wald_r = (mu / 5) * (m[K] + 1), K + 1 + D[K + 1]
print(f"exact,Wald mu*(m(t)+1) at t=6000 (steps),{wald_l:.6f}")
print(f"exact,E[time of first bus after t] (steps),{wald_r:.6f}")
for T in (60, 600, 6000):
    k = T // 5
    print(f"exact,mean wait over arrivals in [0 {T}),{5 * sum(D[j + 1] + 0.5 for j in range(k)) / k:.6f}")
ex_share = sum(0.5 * sum(u[i] for i in (j - 2, j - 1, j) if i >= 0) for j in range(120)) / 120
print(f"exact,share of [0 600) in 15-min gaps,{ex_share:.6f}")
print(f"exact,wait arriving exactly at t=6000,{5 * D[K]:.6f}")
print(f"exact,wait arriving at t=6000.001,{5 * D[K + 1] + 5 - 0.001:.6f}")

# ---- road 3: seeded simulation ----
def passengers(n, gap, horizon):              # each passenger gets a fresh bus run
    w = w2 = hit = 0.0
    for _ in range(n):
        s, b = horizon * unif(), 0.0
        while b < s: a, b = b, b + gap()
        w += b - s; w2 += (b - s) ** 2; hit += (b - a) > 10
    mean = w / n
    return mean, sqrt((w2 / n - mean * mean) / (n - 1)), hit / n
NP = 40000
sw, sse, sh = passengers(NP, bus_gap, 600.0)
print(f"sim,mean wait arriving in [0 600),{sw:.6f}")
print(f"sim,standard error,{sse:.6f}")
print(f"sim,share landing in a 15-min gap,{sh:.6f}")
print(f"sim,standard error of share,{sqrt(sh * (1 - sh) / NP):.6f}")
pw, pse, _ = passengers(NP, exp_gap, 600.0)
print(f"sim,house example wait (4 calls/hour),{pw:.6f}")
print(f"sim,house standard error,{pse:.6f}")
print(f"formula,house example wait E[X^2]/(2 mu),{2 * 15.0 ** 2 / (2 * 15.0):.6f}")
b, cnt, batches = 0.0, [0] * 100, 10000.0     # one long run, counted in 100 batches
while True:
    b += bus_gap()
    if b >= 100 * batches: break
    cnt[int(b // batches)] += 1
rates = [60 * c / batches for c in cnt]
rm = sum(rates) / 100
rse = sqrt(sum((r - rm) ** 2 for r in rates) / 99 / 100)
print(f"sim,buses per hour over 1000000 min,{rm:.6f}")
print(f"sim,standard error of rate,{rse:.6f}")

# ---- what breaks ----
print(f"breaks,half the mean gap,{mu / 2:.6f}")
print(f"breaks,mean gap counted per bus,{mu:.6f}")
dep = 0.5 * (6000 // 5) / 6000 * 60 + 0.5 * (6000 // 15) / 6000 * 60
print(f"breaks,every gap = the first gap: buses per hour at t=6000,{dep:.6f}")

for name, g, q in (("even 10 min", (10, 10), (0.5, 0.5)), ("short 0.75", (5, 15), (0.75, 0.25)), ("1 or 19", (1, 19), (0.5, 0.5))):
    m1, m2 = q[0] * g[0] + q[1] * g[1], q[0] * g[0] ** 2 + q[1] * g[1] ** 2
    print(f"try,{name}: mean gap / per hour / wait / half gap,{m1:.6f} {60 / m1:.6f} {m2 / (2 * m1):.6f} {m1 / 2:.6f}")

# ---- figure: the sawtooth over one hour, gaps 5 15 5 5 15 15 ----
fig, x = [], 0
for g in (5, 15, 5, 5, 15, 15):
    fig.append(f"{40 + 5 * x}:{190 - 10 * g}"); x += g
area = sum(g * g / 2 for g in (5, 15, 5, 5, 15, 15))
print("figure,tooth start x:top y," + " ".join(fig) + f",end x {40 + 5 * x},mean line y {190 - 10 * area / 60}")
print(f"figure,tooth areas small large,{5 * 5 / 2:.6f} {15 * 15 / 2:.6f}")
print(f"figure,sawtooth area / 60,{area / 60:.6f}")

assert ok_bounds, "sandwich t/mu - 1 < m(t) <= (t + 15)/mu - 1 failed"
assert abs(60 * m[K] / 6000 - 60 / mu) < 60 * 1.5 / 6000, "elementary renewal theorem"
assert abs(wald_l - wald_r) < 1e-9, "Wald's identity: two recursions disagree"
assert A12 == m[12] * 4096, "brute force over every gap pattern vs recursion"
assert abs(5 * D[K] - 5 * sum(p * (x // 5) * (x // 5 - 1) / 2 for p, x in zip(P, GAPS)) / (mu / 5)) < 1e-6, "wait at a 5-minute mark: exact vs formula"
assert abs(5 * sum(D[j + 1] + 0.5 for j in range(K)) / K - wait) < 0.01, "exact wait vs formula"
assert abs(sw - 5 * sum(D[j + 1] + 0.5 for j in range(120)) / 120) < 4 * sse, "sim wait vs exact"
assert abs(sh - ex_share) < 4 * sqrt(sh * (1 - sh) / NP), "length bias: sim vs exact"
assert abs(sum(0.5 * sum(u[i] for i in (j - 2, j - 1, j) if i >= 0) for j in range(K)) / K - long_share) < 0.01, "length bias: exact vs formula"
assert abs(pw - 15.0) < 4 * pse, "Poisson wait is the full mean gap"
assert abs(rm - 60 / mu) < 4 * rse, "simulated rate"
print("all checks passed")
print("ALL CHECKS PASS")
```

**Ran 2026-11-13 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
formula,mean gap mu,10.000000
formula,mean square gap E[X^2],125.000000
formula,variance of gap,25.000000
formula,rate 1/mu per minute,0.100000
formula,rate per hour,6.000000
formula,mean wait E[X^2]/(2 mu),6.250000
formula,mu/2 + var/(2 mu),6.250000
formula,share of time in 15-min gaps,0.750000
formula,mean gap a passenger lands in,12.500000
hand,share of time in 5-min gaps,0.250000
hand,mean wait inside a 5-min / 15-min gap,2.500000 7.500000
hand,extra wait var/(2 mu),1.250000
hand,sandwich at t=60 lower upper,5.000000 6.500000
formula,wait at a 5-minute mark,3.750000
exact,E[N(60)] by brute force over all 4096 patterns of 12 gaps,24047/4096
exact,E[N(60)],5.870850
exact,buses per hour m(t)/t*60 at t=15,5.500000
exact,buses per hour m(t)/t*60 at t=30,5.718750
exact,buses per hour m(t)/t*60 at t=60,5.870850
exact,buses per hour m(t)/t*60 at t=120,5.937509
exact,buses per hour m(t)/t*60 at t=240,5.968750
exact,buses per hour m(t)/t*60 at t=480,5.984375
exact,buses per hour m(t)/t*60 at t=6000,5.998750
chart,m(t)/t*60 at t=15 30 60 120 240 480,5.50 5.72 5.87 5.94 5.97 5.98
exact,Wald mu*(m(t)+1) at t=6000 (steps),1201.750000
exact,E[time of first bus after t] (steps),1201.750000
exact,mean wait over arrivals in [0 60),6.382243
exact,mean wait over arrivals in [0 600),6.263021
exact,mean wait over arrivals in [0 6000),6.251302
exact,share of [0 600) in 15-min gaps,0.748437
exact,wait arriving exactly at t=6000,3.750000
exact,wait arriving at t=6000.001,8.749000
sim,mean wait arriving in [0 600),6.279658
sim,standard error,0.022005
sim,share landing in a 15-min gap,0.748200
sim,standard error of share,0.002170
sim,house example wait (4 calls/hour),14.973520
sim,house standard error,0.075258
formula,house example wait E[X^2]/(2 mu),15.000000
sim,buses per hour over 1000000 min,5.998080
sim,standard error of rate,0.008719
breaks,half the mean gap,5.000000
breaks,mean gap counted per bus,10.000000
breaks,every gap = the first gap: buses per hour at t=6000,8.000000
try,even 10 min: mean gap / per hour / wait / half gap,10.000000 6.000000 5.000000 5.000000
try,short 0.75: mean gap / per hour / wait / half gap,7.500000 8.000000 5.000000 3.750000
try,1 or 19: mean gap / per hour / wait / half gap,10.000000 6.000000 9.050000 5.000000
figure,tooth start x:top y,40:140 65:40 140:140 165:140 190:40 265:40,end x 340,mean line y 127.5
figure,tooth areas small large,12.500000 112.500000
figure,sawtooth area / 60,6.250000
all checks passed
ALL CHECKS PASS
```

### Rust

```rust
// Renewal processes in outline -- the check behind the card.  Rust std only.
// Buses leave a stop with gaps of 5 or 15 minutes, each with chance 0.5, the
// gaps independent.  Three roads: the formulas; an exact recursion over every
// bus pattern (in steps of 5 minutes, since every gap is a multiple of 5); and
// seeded simulations, each printed with its standard error.
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 { // SplitMix64 -> a number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn bus_gap(&mut self) -> f64 { if self.unif() < 0.5 { 5.0 } else { 15.0 } }
    fn exp_gap(&mut self) -> f64 { -15.0 * (1.0 - self.unif()).ln() } // house example: 4 calls an hour
}

fn passengers(r: &mut Rng, n: usize, bus: bool, horizon: f64) -> (f64, f64, f64) {
    let (mut w, mut w2, mut hit) = (0.0, 0.0, 0.0); // each passenger gets a fresh bus run
    for _ in 0..n {
        let s = horizon * r.unif();
        let (mut a, mut b) = (0.0, 0.0);
        while b < s { a = b; b += if bus { r.bus_gap() } else { r.exp_gap() }; }
        w += b - s; w2 += (b - s) * (b - s); if b - a > 10.0 { hit += 1.0; }
    }
    let nf = n as f64; let mean = w / nf;
    (mean, ((w2 / nf - mean * mean) / (nf - 1.0)).sqrt(), hit / nf)
}

fn main() {
    let mut r = Rng(20260929);
    let gaps = [5.0f64, 15.0]; let p = [0.5f64, 0.5];
    // ---- road 1: the formulas ----
    let mu = p[0] * gaps[0] + p[1] * gaps[1];
    let ex2 = p[0] * gaps[0] * gaps[0] + p[1] * gaps[1] * gaps[1];
    let var = ex2 - mu * mu;
    let wait = ex2 / (2.0 * mu);
    let long_share = p[1] * gaps[1] / mu; // length-biased chance of a 15-minute gap
    println!("formula,mean gap mu,{:.6}", mu);
    println!("formula,mean square gap E[X^2],{:.6}", ex2);
    println!("formula,variance of gap,{:.6}", var);
    println!("formula,rate 1/mu per minute,{:.6}", 1.0 / mu);
    println!("formula,rate per hour,{:.6}", 60.0 / mu);
    println!("formula,mean wait E[X^2]/(2 mu),{:.6}", wait);
    println!("formula,mu/2 + var/(2 mu),{:.6}", mu / 2.0 + var / (2.0 * mu));
    println!("formula,share of time in 15-min gaps,{:.6}", long_share);
    println!("formula,mean gap a passenger lands in,{:.6}", ex2 / mu);
    println!("hand,share of time in 5-min gaps,{:.6}", p[0] * gaps[0] / mu);
    println!("hand,mean wait inside a 5-min / 15-min gap,{:.6} {:.6}", gaps[0] / 2.0, gaps[1] / 2.0);
    println!("hand,extra wait var/(2 mu),{:.6}", var / (2.0 * mu));
    println!("hand,sandwich at t=60 lower upper,{:.6} {:.6}", 60.0 / mu - 1.0, 75.0 / mu - 1.0);
    let mut mark = 0.0;
    for i in 0..2 { let l = (gaps[i] / 5.0).floor(); mark += p[i] * l * (l - 1.0) / 2.0; }
    println!("formula,wait at a 5-minute mark,{:.6}", 5.0 * mark / (mu / 5.0));

    // ---- road 2: exact recursion, step = 5 minutes, gaps of 1 or 3 steps ----
    const K: usize = 1200; // 6000 minutes
    let steps = [(1usize, 0.5f64), (3usize, 0.5f64)];
    let mut m = vec![0.0f64; K + 2]; // m[k] = E[N(5k)]
    let mut d = vec![0.0f64; K + 2]; // d[k] = E[first bus at or after 5k] - 5k, in steps
    let mut u = vec![0.0f64; K + 2]; u[0] = 1.0; // chance a bus leaves at exactly 5k
    for k in 1..K + 2 {
        let (mut mk, mut dk, mut uk) = (0.0, 0.0, 0.0);
        for &(s, q) in steps.iter() {
            if s <= k { mk += q * (1.0 + m[k - s]); uk += q * u[k - s]; }
            dk += q * if s >= k { (s - k) as f64 } else { d[k - s] };
        }
        m[k] = mk; d[k] = dk; u[k] = uk;
    }
    // brute force: all 2^12 patterns of 12 gaps (bit i set: gap i + 1 is 3 steps), buses by step 12, whole numbers
    let a12: u64 = (0u64..4096).map(|b| (1..=12u64).filter(|&n| (0..n).map(|i| 1 + 2 * ((b >> i) & 1)).sum::<u64>() <= 12).count() as u64).sum();
    println!("exact,E[N(60)] by brute force over all 4096 patterns of 12 gaps,{}/4096", a12);
    println!("exact,E[N(60)],{:.6}", m[12]);
    let ok_bounds = (1..K + 1).all(|k| 5.0 * k as f64 / mu - 1.0 < m[k] && m[k] <= (5.0 * k as f64 + 15.0) / mu - 1.0);
    for &t in [15usize, 30, 60, 120, 240, 480, 6000].iter() {
        println!("exact,buses per hour m(t)/t*60 at t={},{:.6}", t, 60.0 * m[t / 5] / t as f64);
    }
    let ch: Vec<String> = [15usize, 30, 60, 120, 240, 480].iter().map(|&t| format!("{:.2}", 60.0 * m[t / 5] / t as f64)).collect();
    println!("chart,m(t)/t*60 at t=15 30 60 120 240 480,{}", ch.join(" "));
    let wald_l = (mu / 5.0) * (m[K] + 1.0);
    let wald_r = (K + 1) as f64 + d[K + 1];
    println!("exact,Wald mu*(m(t)+1) at t=6000 (steps),{:.6}", wald_l);
    println!("exact,E[time of first bus after t] (steps),{:.6}", wald_r);
    let window = |k: usize| { let mut s = 0.0; for j in 0..k { s += d[j + 1] + 0.5; } 5.0 * s / k as f64 };
    for &tt in [60usize, 600, 6000].iter() {
        println!("exact,mean wait over arrivals in [0 {}),{:.6}", tt, window(tt / 5));
    }
    let share = |k: usize| {
        let mut s = 0.0;
        for j in 0..k as i64 { let mut c = 0.0; for i in j - 2..=j { if i >= 0 { c += u[i as usize]; } } s += 0.5 * c; }
        s / k as f64
    };
    let ex_share = share(120);
    println!("exact,share of [0 600) in 15-min gaps,{:.6}", ex_share);
    println!("exact,wait arriving exactly at t=6000,{:.6}", 5.0 * d[K]);
    println!("exact,wait arriving at t=6000.001,{:.6}", 5.0 * d[K + 1] + 5.0 - 0.001);

    // ---- road 3: seeded simulation ----
    const NP: usize = 40000;
    let (sw, sse, sh) = passengers(&mut r, NP, true, 600.0);
    let sh_se = (sh * (1.0 - sh) / NP as f64).sqrt();
    println!("sim,mean wait arriving in [0 600),{:.6}", sw);
    println!("sim,standard error,{:.6}", sse);
    println!("sim,share landing in a 15-min gap,{:.6}", sh);
    println!("sim,standard error of share,{:.6}", sh_se);
    let (pw, pse, _) = passengers(&mut r, NP, false, 600.0);
    println!("sim,house example wait (4 calls/hour),{:.6}", pw);
    println!("sim,house standard error,{:.6}", pse);
    println!("formula,house example wait E[X^2]/(2 mu),{:.6}", 2.0 * 15.0f64 * 15.0 / (2.0 * 15.0));
    let batches = 10000.0; // one long run, counted in 100 batches
    let (mut b, mut cnt) = (0.0f64, [0u32; 100]);
    loop {
        b += r.bus_gap();
        if b >= 100.0 * batches { break; }
        cnt[(b / batches).floor() as usize] += 1;
    }
    let rates: Vec<f64> = cnt.iter().map(|&c| 60.0 * c as f64 / batches).collect();
    let rm = rates.iter().fold(0.0, |s, x| s + x) / 100.0;
    let rse = (rates.iter().fold(0.0, |s, x| s + (x - rm) * (x - rm)) / 99.0 / 100.0).sqrt();
    println!("sim,buses per hour over 1000000 min,{:.6}", rm);
    println!("sim,standard error of rate,{:.6}", rse);

    // ---- what breaks ----
    println!("breaks,half the mean gap,{:.6}", mu / 2.0);
    println!("breaks,mean gap counted per bus,{:.6}", mu);
    let dep = 0.5 * (6000 / 5) as f64 / 6000.0 * 60.0 + 0.5 * (6000 / 15) as f64 / 6000.0 * 60.0;
    println!("breaks,every gap = the first gap: buses per hour at t=6000,{:.6}", dep);

    for &(name, g, q) in [("even 10 min", [10.0f64, 10.0], [0.5f64, 0.5]), ("short 0.75", [5.0, 15.0], [0.75, 0.25]), ("1 or 19", [1.0, 19.0], [0.5, 0.5])].iter() {
        let (m1, m2) = (q[0] * g[0] + q[1] * g[1], q[0] * g[0] * g[0] + q[1] * g[1] * g[1]);
        println!("try,{}: mean gap / per hour / wait / half gap,{:.6} {:.6} {:.6} {:.6}", name, m1, 60.0 / m1, m2 / (2.0 * m1), m1 / 2.0);
    }

    // ---- figure: the sawtooth over one hour, gaps 5 15 5 5 15 15 ----
    let (mut fig, mut x, mut area) = (Vec::new(), 0i64, 0.0);
    for &g in [5i64, 15, 5, 5, 15, 15].iter() {
        fig.push(format!("{}:{}", 40 + 5 * x, 190 - 10 * g)); x += g; area += (g * g) as f64 / 2.0;
    }
    println!("figure,tooth start x:top y,{},end x {},mean line y {}", fig.join(" "), 40 + 5 * x, 190.0 - 10.0 * area / 60.0);
    println!("figure,tooth areas small large,{:.6} {:.6}", 5.0 * 5.0 / 2.0, 15.0 * 15.0 / 2.0);
    println!("figure,sawtooth area / 60,{:.6}", area / 60.0);

    assert!(ok_bounds, "sandwich t/mu - 1 < m(t) <= (t + 15)/mu - 1 failed");
    assert!((60.0 * m[K] / 6000.0 - 60.0 / mu).abs() < 60.0 * 1.5 / 6000.0, "elementary renewal theorem");
    assert!((wald_l - wald_r).abs() < 1e-9, "Wald's identity: two recursions disagree");
    assert!(a12 as f64 == m[12] * 4096.0, "brute force over every gap pattern vs recursion");
    assert!((5.0 * d[K] - 5.0 * mark / (mu / 5.0)).abs() < 1e-6, "wait at a 5-minute mark: exact vs formula");
    assert!((window(K) - wait).abs() < 0.01, "exact wait vs formula");
    assert!((sw - window(120)).abs() < 4.0 * sse, "sim wait vs exact");
    assert!((sh - ex_share).abs() < 4.0 * sh_se, "length bias: sim vs exact");
    assert!((share(K) - long_share).abs() < 0.01, "length bias: exact vs formula");
    assert!((pw - 15.0).abs() < 4.0 * pse, "Poisson wait is the full mean gap");
    assert!((rm - 60.0 / mu).abs() < 4.0 * rse, "simulated rate");
    println!("all checks passed");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-13 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
formula,mean gap mu,10.000000
formula,mean square gap E[X^2],125.000000
formula,variance of gap,25.000000
formula,rate 1/mu per minute,0.100000
formula,rate per hour,6.000000
formula,mean wait E[X^2]/(2 mu),6.250000
formula,mu/2 + var/(2 mu),6.250000
formula,share of time in 15-min gaps,0.750000
formula,mean gap a passenger lands in,12.500000
hand,share of time in 5-min gaps,0.250000
hand,mean wait inside a 5-min / 15-min gap,2.500000 7.500000
hand,extra wait var/(2 mu),1.250000
hand,sandwich at t=60 lower upper,5.000000 6.500000
formula,wait at a 5-minute mark,3.750000
exact,E[N(60)] by brute force over all 4096 patterns of 12 gaps,24047/4096
exact,E[N(60)],5.870850
exact,buses per hour m(t)/t*60 at t=15,5.500000
exact,buses per hour m(t)/t*60 at t=30,5.718750
exact,buses per hour m(t)/t*60 at t=60,5.870850
exact,buses per hour m(t)/t*60 at t=120,5.937509
exact,buses per hour m(t)/t*60 at t=240,5.968750
exact,buses per hour m(t)/t*60 at t=480,5.984375
exact,buses per hour m(t)/t*60 at t=6000,5.998750
chart,m(t)/t*60 at t=15 30 60 120 240 480,5.50 5.72 5.87 5.94 5.97 5.98
exact,Wald mu*(m(t)+1) at t=6000 (steps),1201.750000
exact,E[time of first bus after t] (steps),1201.750000
exact,mean wait over arrivals in [0 60),6.382243
exact,mean wait over arrivals in [0 600),6.263021
exact,mean wait over arrivals in [0 6000),6.251302
exact,share of [0 600) in 15-min gaps,0.748437
exact,wait arriving exactly at t=6000,3.750000
exact,wait arriving at t=6000.001,8.749000
sim,mean wait arriving in [0 600),6.279658
sim,standard error,0.022005
sim,share landing in a 15-min gap,0.748200
sim,standard error of share,0.002170
sim,house example wait (4 calls/hour),14.973520
sim,house standard error,0.075258
formula,house example wait E[X^2]/(2 mu),15.000000
sim,buses per hour over 1000000 min,5.998080
sim,standard error of rate,0.008719
breaks,half the mean gap,5.000000
breaks,mean gap counted per bus,10.000000
breaks,every gap = the first gap: buses per hour at t=6000,8.000000
try,even 10 min: mean gap / per hour / wait / half gap,10.000000 6.000000 5.000000 5.000000
try,short 0.75: mean gap / per hour / wait / half gap,7.500000 8.000000 5.000000 3.750000
try,1 or 19: mean gap / per hour / wait / half gap,10.000000 6.000000 9.050000 5.000000
figure,tooth start x:top y,40:140 65:40 140:140 165:140 190:40 265:40,end x 340,mean line y 127.5
figure,tooth areas small large,12.500000 112.500000
figure,sawtooth area / 60,6.250000
all checks passed
ALL CHECKS PASS
```

The two outputs are identical line for line.

### Lean

Lean proves the elementary renewal theorem and the mean wait of the inspection paradox, for any gap law, and checks the worked numbers.

- Take independent gaps with one law, none negative, and a finite positive mean gap $\mu$. Then $N(t)/t \to 1/\mu$ on almost every run.
- Take the same gaps. Then $m(t)/t \to 1/\mu$, so the average count settles at the same rate.
- Take the same gaps, and suppose $E[X^2]$ is finite. Then on almost every run, the average wait over arrivals spread evenly on $[0, t]$ tends to $E[X^2]/(2\mu)$.
- The 5-or-15 stop has mean gap 10, mean square gap 125, 6 buses an hour and a mean wait of 6.25 minutes.
- Long gaps hold 0.75 of the time, and 0.25 × 2.5 + 0.75 × 7.5 = 6.25.
- The brute-force count over all 4096 patterns gives 24047/4096 for $m(60)$, inside the sandwich of 5 and 6.5.

The law of $L$, the exact recursion and the simulations are left to the Python and Rust checks.

```lean
-- Renewal processes: for independent, identically distributed gaps with a finite positive mean, arrivals come at one per mean gap in the long run, and the time-averaged wait for the next arrival is the mean square gap over twice the mean gap.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Notation
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Data.Set.Card
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory ProbabilityTheory Filter Topology


variable {Ω : Type*} [MeasurableSpace Ω]

/-- `busTime X n ω` is $S_n$, the time of bus `n`: the sum of the first `n` gaps.
Gap `X i` is the time between bus `i` and bus `i + 1`, with bus 0 leaving at time 0. -/
noncomputable def busTime (X : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) : ℝ :=
  ∑ i ∈ Finset.range n, X i ω

/-- `arrivalCount X t ω` is $N(t)$: the number of buses `n ≥ 1` with $S_n \le t$. -/
noncomputable def arrivalCount (X : ℕ → Ω → ℝ) (t : ℝ) (ω : Ω) : ℕ :=
  Set.ncard {n : ℕ | 1 ≤ n ∧ busTime X n ω ≤ t}

/-- `wait X s ω` is the wait of a passenger arriving at time `s`: the time of the first bus
after `s`, bus $N(s)+1$, minus `s`. -/
noncomputable def wait (X : ℕ → Ω → ℝ) (s : ℝ) (ω : Ω) : ℝ :=
  busTime X (arrivalCount X s ω + 1) ω - s

lemma rp_busTime_zero (X : ℕ → Ω → ℝ) (ω : Ω) : busTime X 0 ω = 0 := by simp [busTime]

lemma rp_busTime_succ (X : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) :
    busTime X (n + 1) ω = busTime X n ω + X n ω := by
  simp [busTime, Finset.sum_range_succ]

lemma rp_busTime_mono {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω) :
    Monotone (fun n => busTime X n ω) := by
  intro a b hab
  exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_mono hab) (fun i _ _ => h0 i)

lemma rp_le_iff {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) (n : ℕ) :
    busTime X n ω ≤ t ↔ n ≤ arrivalCount X t ω := by
  classical
  have hex : ∃ m, t < busTime X m ω := (hunb.eventually_gt_atTop t).exists
  set K := Nat.find hex with hK
  have hS : ∀ m, busTime X m ω ≤ t ↔ m < K := by
    intro m
    constructor
    · intro hm
      by_contra hc
      push Not at hc
      have h1 := rp_busTime_mono h0 hc
      have h2 := Nat.find_spec hex
      simp only at h1
      linarith
    · intro hm
      exact not_lt.1 (Nat.find_min hex hm)
  have hKpos : 0 < K := (hS 0).1 (by simp [rp_busTime_zero, ht])
  have hset : {m : ℕ | 1 ≤ m ∧ busTime X m ω ≤ t} = ((Finset.Ico 1 K : Finset ℕ) : Set ℕ) := by
    ext m; simp [hS m]
  have hN : arrivalCount X t ω = K - 1 := by
    unfold arrivalCount; rw [hset, Set.ncard_coe_finset]; simp
  rw [hS n, hN]; omega

lemma rp_le_t {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    busTime X (arrivalCount X t ω) ω ≤ t :=
  (rp_le_iff h0 hunb ht _).2 le_rfl

lemma rp_lt_next {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    t < busTime X (arrivalCount X t ω + 1) ω := by
  by_contra h
  push Not at h
  have := (rp_le_iff h0 hunb ht _).1 h
  omega

lemma rp_count_mono {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {s t : ℝ} (hs : 0 ≤ s) (hst : s ≤ t) :
    arrivalCount X s ω ≤ arrivalCount X t ω :=
  (rp_le_iff h0 hunb (hs.trans hst) _).1 ((rp_le_t h0 hunb hs).trans hst)

lemma rp_count_tendsto {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) :
    Tendsto (fun t : ℝ => arrivalCount X t ω) atTop atTop := by
  rw [tendsto_atTop]
  intro n
  filter_upwards [eventually_ge_atTop (max 0 (busTime X n ω))] with t ht
  exact (rp_le_iff h0 hunb ((le_max_left _ _).trans ht) n).1 ((le_max_right _ _).trans ht)

lemma rp_ae_good (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0]) :
    ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop ∧
      Tendsto (fun n : ℕ => busTime X n ω / n) atTop (𝓝 P[X 0]) := by
  have hslln := strong_law_ae_real X hint (fun i j hij => hindep.indepFun hij) hident
  filter_upwards [ae_all_iff.2 hnonneg, hslln] with ω h0 hl
  refine ⟨h0, ?_, hl⟩
  have h2 : Tendsto (fun n : ℕ => busTime X n ω / n * (n : ℝ)) atTop atTop :=
    Tendsto.pos_mul_atTop hpos hl tendsto_natCast_atTop_atTop
  refine h2.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have : (n : ℝ) ≠ 0 := by positivity
  field_simp

lemma rp_ratio_tendsto {X : ℕ → Ω → ℝ} {ω : Ω} {μ : ℝ} (hμ : 0 < μ) (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop)
    (hl : Tendsto (fun n : ℕ => busTime X n ω / n) atTop (𝓝 μ)) :
    Tendsto (fun t : ℝ => (arrivalCount X t ω : ℝ) / t) atTop (𝓝 (1 / μ)) := by
  have hN := rp_count_tendsto h0 hunb
  -- a(n+1) * ((n+1)/n) → μ
  have hl1 : Tendsto (fun n : ℕ => busTime X (n + 1) ω / ((n + 1 : ℕ) : ℝ)) atTop (𝓝 μ) :=
    (tendsto_add_atTop_iff_nat 1).2 hl
  have hr : Tendsto (fun n : ℕ => ((n + 1 : ℕ) : ℝ) / n) atTop (𝓝 1) := by
    have : Tendsto (fun n : ℕ => (1 : ℝ) + 1 / n) atTop (𝓝 (1 + 0)) :=
      tendsto_const_nhds.add tendsto_one_div_atTop_nhds_zero_nat
    rw [add_zero] at this
    refine this.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have : (n : ℝ) ≠ 0 := by positivity
    push_cast
    field_simp
  have hb : Tendsto (fun n : ℕ => busTime X (n + 1) ω / ((n + 1 : ℕ) : ℝ) * (((n + 1 : ℕ) : ℝ) / n))
      atTop (𝓝 μ) := by simpa using hl1.mul hr
  have hlow := hl.comp hN
  have hup := hb.comp hN
  have hsq : Tendsto (fun t : ℝ => t / (arrivalCount X t ω : ℝ)) atTop (𝓝 μ) := by
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow hup ?_ ?_
    · filter_upwards [eventually_ge_atTop 0, hN.eventually_ge_atTop 1] with t ht hn
      have hpos : (0 : ℝ) < arrivalCount X t ω := by exact_mod_cast hn
      simp only [Function.comp]
      exact div_le_div_of_nonneg_right (rp_le_t h0 hunb ht) hpos.le
    · filter_upwards [eventually_ge_atTop 0, hN.eventually_ge_atTop 1] with t ht hn
      have hpos : (0 : ℝ) < arrivalCount X t ω := by exact_mod_cast hn
      simp only [Function.comp]
      have hn1 : ((arrivalCount X t ω + 1 : ℕ) : ℝ) ≠ 0 := by positivity
      rw [div_mul_div_cancel₀ hn1]
      exact div_le_div_of_nonneg_right (rp_lt_next h0 hunb ht).le hpos.le
  have := hsq.inv₀ hμ.ne'
  simpa [inv_div, one_div] using this

lemma rp_wait_eq {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {k : ℕ} {s : ℝ}
    (hs1 : busTime X k ω ≤ s) (hs2 : s < busTime X (k + 1) ω) (hs0 : 0 ≤ s) :
    wait X s ω = busTime X (k + 1) ω - s := by
  have hk : arrivalCount X s ω = k := by
    apply le_antisymm
    · by_contra h
      push Not at h
      have := (rp_le_iff h0 hunb hs0 (k + 1)).2 h
      linarith
    · exact (rp_le_iff h0 hunb hs0 k).1 hs1
  simp [wait, hk]

lemma rp_wait_nonneg {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {s : ℝ} (hs : 0 ≤ s) :
    0 ≤ wait X s ω := by
  unfold wait
  linarith [rp_lt_next h0 hunb hs]

lemma rp_busTime_nonneg {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω) (n : ℕ) :
    0 ≤ busTime X n ω := by
  simpa [rp_busTime_zero] using rp_busTime_mono h0 (Nat.zero_le n)

lemma rp_wait_ii {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {a b : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) :
    IntervalIntegrable (fun s => wait X s ω) volume a b := by
  have hm : MonotoneOn (fun s => busTime X (arrivalCount X s ω + 1) ω) (Set.uIcc a b) := by
    intro x hx y hy hxy
    have hx0 : 0 ≤ x := by
      rcases Set.mem_uIcc.1 hx with h | h
      · linarith [h.1]
      · linarith [h.1]
    exact rp_busTime_mono h0 (Nat.succ_le_succ (rp_count_mono h0 hunb hx0 hxy))
  exact hm.intervalIntegrable.sub (continuous_id.intervalIntegrable a b)

lemma rp_piece {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) (k : ℕ) :
    ∫ s in busTime X k ω..busTime X (k + 1) ω, wait X s ω = X k ω ^ 2 / 2 := by
  have hab : busTime X k ω ≤ busTime X (k + 1) ω := rp_busTime_mono h0 (Nat.le_succ k)
  have hk0 : 0 ≤ busTime X k ω := rp_busTime_nonneg h0 k
  have heq : ∫ s in busTime X k ω..busTime X (k + 1) ω, wait X s ω =
      ∫ s in busTime X k ω..busTime X (k + 1) ω, (busTime X (k + 1) ω - s) := by
    rw [intervalIntegral.integral_of_le hab, intervalIntegral.integral_of_le hab,
      integral_Ioc_eq_integral_Ioo, integral_Ioc_eq_integral_Ioo]
    refine setIntegral_congr_fun measurableSet_Ioo (fun s hs => ?_)
    exact rp_wait_eq h0 hunb hs.1.le hs.2 (hk0.trans hs.1.le)
  rw [heq, intervalIntegral.integral_sub (f := fun _ : ℝ => busTime X (k + 1) ω)
    (g := fun s : ℝ => s) intervalIntegrable_const
    (continuous_id'.intervalIntegrable _ _), intervalIntegral.integral_const, integral_id,
    rp_busTime_succ]
  simp only [smul_eq_mul]
  ring

lemma rp_int_busTime {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) (n : ℕ) :
    ∫ s in (0 : ℝ)..busTime X n ω, wait X s ω = (∑ k ∈ Finset.range n, X k ω ^ 2) / 2 := by
  induction n with
  | zero => simp [rp_busTime_zero]
  | succ n ih =>
    rw [← intervalIntegral.integral_add_adjacent_intervals
      (rp_wait_ii h0 hunb le_rfl (rp_busTime_nonneg h0 n))
      (rp_wait_ii h0 hunb (rp_busTime_nonneg h0 n) (rp_busTime_nonneg h0 (n + 1))), ih,
      rp_piece h0 hunb, Finset.sum_range_succ]
    ring

lemma rp_int_bounds {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    (∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / 2 ≤ ∫ s in (0 : ℝ)..t, wait X s ω ∧
    ∫ s in (0 : ℝ)..t, wait X s ω ≤
      (∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) / 2 := by
  constructor
  · rw [← rp_int_busTime h0 hunb]
    refine intervalIntegral.integral_mono_interval le_rfl (rp_busTime_nonneg h0 _)
      (rp_le_t h0 hunb ht) ?_ (rp_wait_ii h0 hunb le_rfl ht)
    exact (ae_restrict_iff' measurableSet_Ioc).2
      (Eventually.of_forall fun s hs => rp_wait_nonneg h0 hunb hs.1.le)
  · rw [← rp_int_busTime h0 hunb]
    refine intervalIntegral.integral_mono_interval le_rfl ht (rp_lt_next h0 hunb ht).le ?_
      (rp_wait_ii h0 hunb le_rfl (rp_busTime_nonneg h0 _))
    exact (ae_restrict_iff' measurableSet_Ioc).2
      (Eventually.of_forall fun s hs => rp_wait_nonneg h0 hunb hs.1.le)

lemma rp_wait_tendsto {X : ℕ → Ω → ℝ} {ω : Ω} {μ m2 : ℝ} (hμ : 0 < μ) (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop)
    (hl : Tendsto (fun n : ℕ => busTime X n ω / n) atTop (𝓝 μ))
    (hq : Tendsto (fun n : ℕ => (∑ k ∈ Finset.range n, X k ω ^ 2) / n) atTop (𝓝 m2)) :
    Tendsto (fun t : ℝ => (∫ s in (0 : ℝ)..t, wait X s ω) / t) atTop (𝓝 (m2 / (2 * μ))) := by
  have hN := rp_count_tendsto h0 hunb
  have hR := rp_ratio_tendsto hμ h0 hunb hl
  have hlow : Tendsto (fun t : ℝ =>
      (∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / (arrivalCount X t ω : ℝ) *
        ((arrivalCount X t ω : ℝ) / t) / 2) atTop (𝓝 (m2 * (1 / μ) / 2)) :=
    ((hq.comp hN).mul hR).div_const 2
  have hN1 : Tendsto (fun t : ℝ => arrivalCount X t ω + 1) atTop atTop :=
    (tendsto_add_atTop_nat 1).comp hN
  have hup : Tendsto (fun t : ℝ =>
      (∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) /
        ((arrivalCount X t ω + 1 : ℕ) : ℝ) *
        ((arrivalCount X t ω : ℝ) / t + 1 / t) / 2) atTop (𝓝 (m2 * (1 / μ + 0) / 2)) :=
    ((hq.comp hN1).mul (hR.add (tendsto_const_nhds.div_atTop tendsto_id))).div_const 2
  rw [add_zero] at hup
  have hlim : m2 / (2 * μ) = m2 * (1 / μ) / 2 := by ring
  rw [hlim]
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow hup ?_ ?_
  · filter_upwards [eventually_gt_atTop 0, hN.eventually_ge_atTop 1] with t ht hn
    have hNpos : (0 : ℝ) < arrivalCount X t ω := by exact_mod_cast hn
    have e : (∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / (arrivalCount X t ω : ℝ) *
        ((arrivalCount X t ω : ℝ) / t) / 2 =
        ((∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / 2) / t := by
      field_simp
    rw [e]
    exact div_le_div_of_nonneg_right (rp_int_bounds h0 hunb ht.le).1 ht.le
  · filter_upwards [eventually_gt_atTop 0] with t ht
    have e : (∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) /
        ((arrivalCount X t ω + 1 : ℕ) : ℝ) * ((arrivalCount X t ω : ℝ) / t + 1 / t) / 2 =
        ((∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) / 2) / t := by
      have : ((arrivalCount X t ω + 1 : ℕ) : ℝ) ≠ 0 := by positivity
      push_cast at this ⊢
      field_simp
    rw [e]
    exact div_le_div_of_nonneg_right (rp_int_bounds h0 hunb ht.le).2 ht.le

lemma rp_tsum_count {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    ∑' i, (if busTime X i ω ≤ t then (1 : ENNReal) else 0) = (arrivalCount X t ω : ENNReal) + 1 := by
  have e : ∀ i, (if busTime X i ω ≤ t then (1 : ENNReal) else 0) =
      if i ∈ Finset.range (arrivalCount X t ω + 1) then 1 else 0 := by
    intro i
    simp [rp_le_iff h0 hunb ht]
  simp_rw [e]
  rw [tsum_eq_sum (s := Finset.range (arrivalCount X t ω + 1)) (by intro i hi; simp [hi]),
    Finset.sum_ite_of_true (fun i hi => hi)]
  simp

lemma rp_tsum_time {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    ∑' i, ENNReal.ofReal (X i ω) * (if busTime X i ω ≤ t then (1 : ENNReal) else 0) =
      ENNReal.ofReal (busTime X (arrivalCount X t ω + 1) ω) := by
  have e : ∀ i, ENNReal.ofReal (X i ω) * (if busTime X i ω ≤ t then (1 : ENNReal) else 0) =
      if i ∈ Finset.range (arrivalCount X t ω + 1) then ENNReal.ofReal (X i ω) else 0 := by
    intro i
    simp [rp_le_iff h0 hunb ht]
  simp_rw [e]
  rw [tsum_eq_sum (s := Finset.range (arrivalCount X t ω + 1)) (by intro i hi; simp [hi]),
    Finset.sum_ite_of_true (fun i hi => hi)]
  rw [busTime, ENNReal.ofReal_sum_of_nonneg (fun i _ => h0 i)]

lemma rp_wald (P : Measure Ω) [IsProbabilityMeasure P] (Y : ℕ → Ω → ℝ) (hindep : iIndepFun Y P)
    (hident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hgood : ∀ᵐ ω ∂P, (∀ i, 0 ≤ Y i ω) ∧ Tendsto (fun n => busTime Y n ω) atTop atTop)
    {t : ℝ} (ht : 0 ≤ t) :
    ∫⁻ ω, ENNReal.ofReal (busTime Y (arrivalCount Y t ω + 1) ω) ∂P =
      (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * (∫⁻ ω, (arrivalCount Y t ω : ENNReal) ∂P + 1) := by
  have hmeas : ∀ i, AEMeasurable (Y i) P := fun i => (hident i).aemeasurable_fst
  set g : ℝ → ENNReal := fun x => if x ≤ t then 1 else 0 with hgdef
  have hg : Measurable g := Measurable.ite measurableSet_Iic measurable_const measurable_const
  have hS : ∀ i, (fun ω => busTime Y i ω) = ∑ j ∈ Finset.range i, Y j := by
    intro i; ext ω; simp [busTime, Finset.sum_apply]
  have hSm : ∀ i, AEMeasurable (fun ω => busTime Y i ω) P := by
    intro i; rw [hS]; exact Finset.aemeasurable_sum _ (fun j _ => hmeas j)
  have hind : ∀ i, IndepFun (fun ω => ENNReal.ofReal (Y i ω)) (fun ω => g (busTime Y i ω)) P := by
    intro i
    have h := (hindep.indepFun_finsetSum_of_notMem₀ hmeas (s := Finset.range i) (i := i)
      (by simp)).symm
    rw [← hS] at h
    exact h.comp ENNReal.measurable_ofReal hg
  have hfm : ∀ i, AEMeasurable (fun ω => ENNReal.ofReal (Y i ω)) P := fun i =>
    ENNReal.measurable_ofReal.comp_aemeasurable (hmeas i)
  have hgm : ∀ i, AEMeasurable (fun ω => g (busTime Y i ω)) P := fun i =>
    hg.comp_aemeasurable (hSm i)
  have hterm : ∀ i, ∫⁻ ω, ENNReal.ofReal (Y i ω) * g (busTime Y i ω) ∂P =
      (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, g (busTime Y i ω) ∂P := by
    intro i
    have e : ∫⁻ ω, ENNReal.ofReal (Y i ω) ∂P = ∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P :=
      ((hident i).comp ENNReal.measurable_ofReal).lintegral_eq
    rw [← e]
    exact lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun' (hfm i) (hgm i) (hind i)
  calc ∫⁻ ω, ENNReal.ofReal (busTime Y (arrivalCount Y t ω + 1) ω) ∂P
      = ∫⁻ ω, ∑' i, ENNReal.ofReal (Y i ω) * g (busTime Y i ω) ∂P := by
        apply lintegral_congr_ae
        filter_upwards [hgood] with ω hω
        exact (rp_tsum_time hω.1 hω.2 ht).symm
    _ = ∑' i, ∫⁻ ω, ENNReal.ofReal (Y i ω) * g (busTime Y i ω) ∂P :=
        lintegral_tsum (fun i => (hfm i).mul (hgm i))
    _ = ∑' i, (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, g (busTime Y i ω) ∂P :=
        tsum_congr hterm
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∑' i, ∫⁻ ω, g (busTime Y i ω) ∂P :=
        ENNReal.tsum_mul_left
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, ∑' i, g (busTime Y i ω) ∂P := by
        rw [lintegral_tsum hgm]
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, ((arrivalCount Y t ω : ENNReal) + 1) ∂P := by
        congr 1
        apply lintegral_congr_ae
        filter_upwards [hgood] with ω hω
        exact rp_tsum_count hω.1 hω.2 ht
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * (∫⁻ ω, (arrivalCount Y t ω : ENNReal) ∂P + 1) := by
        rw [lintegral_add_right _ measurable_const]
        simp

lemma rp_count_aemeas (P : Measure Ω) (Y : ℕ → Ω → ℝ)
    (hident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hgood : ∀ᵐ ω ∂P, (∀ i, 0 ≤ Y i ω) ∧ Tendsto (fun n => busTime Y n ω) atTop atTop)
    {t : ℝ} (ht : 0 ≤ t) :
    AEMeasurable (fun ω => (arrivalCount Y t ω : ℝ)) P := by
  have hmeas : ∀ i, AEMeasurable (Y i) P := fun i => (hident i).aemeasurable_fst
  have hSm : ∀ i, AEMeasurable (fun ω => busTime Y i ω) P := by
    intro i
    have : (fun ω => busTime Y i ω) = ∑ j ∈ Finset.range i, Y j := by
      ext ω; simp [busTime, Finset.sum_apply]
    rw [this]; exact Finset.aemeasurable_sum _ (fun j _ => hmeas j)
  have hg : Measurable (fun x : ℝ => if x ≤ t then (1 : ENNReal) else 0) :=
    Measurable.ite measurableSet_Iic measurable_const measurable_const
  have hm : AEMeasurable (fun ω => (∑' i, (if busTime Y i ω ≤ t then (1 : ENNReal) else 0)).toReal
      - 1) P :=
    ((AEMeasurable.tsum (fun i => hg.comp_aemeasurable (hSm i))).ennreal_toReal).sub_const _
  refine hm.congr ?_
  filter_upwards [hgood] with ω hω
  rw [rp_tsum_count hω.1 hω.2 ht]
  rw [show ((arrivalCount Y t ω : ENNReal) + 1) = ((arrivalCount Y t ω + 1 : ℕ) : ENNReal) by
    push_cast; rfl, ENNReal.toReal_natCast]
  push_cast
  ring

lemma rp_trunc_integrable (P : Measure Ω) (X : ℕ → Ω → ℝ) (hint : Integrable (X 0) P) (c : ℝ)
    [IsFiniteMeasure P] : Integrable (fun ω => min (X 0 ω) c) P :=
  hint.inf (integrable_const c)

lemma rp_trunc_tendsto (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hnonneg0 : ∀ᵐ ω ∂P, 0 ≤ X 0 ω) (hint : Integrable (X 0) P) :
    Tendsto (fun n : ℕ => P[fun ω => min (X 0 ω) (n : ℝ)]) atTop (𝓝 P[X 0]) := by
  refine tendsto_integral_of_dominated_convergence (fun ω => ‖X 0 ω‖)
    (fun n => (rp_trunc_integrable P X hint _).aestronglyMeasurable) hint.norm
    (fun n => ?_) (Eventually.of_forall fun ω => ?_)
  · filter_upwards [hnonneg0] with ω h
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (le_min h (Nat.cast_nonneg n)),
      abs_of_nonneg h]
    exact min_le_left _ _
  · refine tendsto_const_nhds.congr' ?_
    filter_upwards [eventually_ge_atTop ⌈X 0 ω⌉₊] with n hn
    exact (min_eq_left (Nat.ceil_le.1 hn)).symm

lemma rp_upper (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    {t : ℝ} (ht : 0 ≤ t) (n : ℕ) (hposn : 0 < P[fun ω => min (X 0 ω) (n : ℝ)]) :
    ∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P ≠ ⊤ ∧
    P[fun ω => min (X 0 ω) (n : ℝ)] * ((∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P).toReal + 1)
      ≤ t + n := by
  set Y : ℕ → Ω → ℝ := fun i ω => min (X i ω) (n : ℝ) with hYdef
  have hYind : iIndepFun Y P :=
    hindep.comp (fun _ x => min x (n : ℝ)) (fun _ => measurable_id.min measurable_const)
  have hYid : ∀ i, IdentDistrib (Y i) (Y 0) P P := fun i =>
    (hident i).comp (measurable_id.min measurable_const)
  have hYint : Integrable (Y 0) P := rp_trunc_integrable P X hint _
  have hYnn : ∀ i, ∀ᵐ ω ∂P, 0 ≤ Y i ω := by
    intro i
    filter_upwards [hnonneg i] with ω h
    exact le_min h (Nat.cast_nonneg n)
  have hgX := rp_ae_good P X hindep hident hnonneg hint hpos
  have hgY := rp_ae_good P Y hYind hYid hYnn hYint hposn
  have hgX' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop := by
    filter_upwards [hgX] with ω h using ⟨h.1, h.2.1⟩
  have hgY' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ Y i ω) ∧ Tendsto (fun n => busTime Y n ω) atTop atTop := by
    filter_upwards [hgY] with ω h using ⟨h.1, h.2.1⟩
  have hWY := rp_wald P Y hYind hYid hgY' ht
  have hmuY : ∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P = ENNReal.ofReal (P[Y 0]) :=
    (ofReal_integral_eq_lintegral_ofReal hYint (hYnn 0)).symm
  set AY := ∫⁻ ω, (arrivalCount Y t ω : ENNReal) ∂P with hAY
  set A := ∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P with hA
  have h2 : ENNReal.ofReal (P[Y 0]) * (AY + 1) ≤ ENNReal.ofReal (t + n) := by
    rw [← hmuY, ← hWY]
    calc ∫⁻ ω, ENNReal.ofReal (busTime Y (arrivalCount Y t ω + 1) ω) ∂P
        ≤ ∫⁻ _, ENNReal.ofReal (t + n) ∂P := by
          apply lintegral_mono_ae
          filter_upwards [hgY'] with ω hω
          apply ENNReal.ofReal_le_ofReal
          rw [rp_busTime_succ]
          have h1 := rp_le_t hω.1 hω.2 ht
          have h3 : Y (arrivalCount Y t ω) ω ≤ n := min_le_right _ _
          linarith
      _ = ENNReal.ofReal (t + n) := by simp
  have h3 : A ≤ AY := by
    apply lintegral_mono_ae
    filter_upwards [hgX', hgY'] with ω hX hY
    have hle : busTime Y (arrivalCount X t ω) ω ≤ busTime X (arrivalCount X t ω) ω :=
      Finset.sum_le_sum (fun i _ => min_le_left _ _)
    have := (rp_le_iff hY.1 hY.2 ht _).1 (hle.trans (rp_le_t hX.1 hX.2 ht))
    exact_mod_cast this
  have hYpos : 0 < ENNReal.ofReal (P[Y 0]) := ENNReal.ofReal_pos.2 hposn
  have hAYtop : AY ≠ ⊤ := by
    intro htop
    rw [htop, top_add, ENNReal.mul_top hYpos.ne'] at h2
    exact ENNReal.ofReal_ne_top (top_le_iff.1 h2)
  have hAtop : A ≠ ⊤ := ne_top_of_le_ne_top hAYtop h3
  refine ⟨hAtop, ?_⟩
  have h4 := ENNReal.toReal_mono ENNReal.ofReal_ne_top h2
  rw [ENNReal.toReal_mul, ENNReal.toReal_add hAYtop ENNReal.one_ne_top,
    ENNReal.toReal_ofReal hposn.le, ENNReal.toReal_ofReal (by positivity), ENNReal.toReal_one] at h4
  have h5 : A.toReal ≤ AY.toReal := ENNReal.toReal_mono hAYtop h3
  calc P[Y 0] * (A.toReal + 1) ≤ P[Y 0] * (AY.toReal + 1) := by gcongr
    _ ≤ t + n := h4

lemma rp_lower (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    {t : ℝ} (ht : 0 ≤ t) (hA : ∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P ≠ ⊤) :
    t ≤ P[X 0] * ((∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P).toReal + 1) := by
  have hgX := rp_ae_good P X hindep hident hnonneg hint hpos
  have hgX' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop := by
    filter_upwards [hgX] with ω h using ⟨h.1, h.2.1⟩
  have hW := rp_wald P X hindep hident hgX' ht
  have hmu : ∫⁻ ω, ENNReal.ofReal (X 0 ω) ∂P = ENNReal.ofReal (P[X 0]) :=
    (ofReal_integral_eq_lintegral_ofReal hint (hnonneg 0)).symm
  have h1 : ENNReal.ofReal t ≤
      ENNReal.ofReal (P[X 0]) * (∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P + 1) := by
    rw [← hmu, ← hW]
    calc ENNReal.ofReal t = ∫⁻ _, ENNReal.ofReal t ∂P := by simp
      _ ≤ _ := by
          apply lintegral_mono_ae
          filter_upwards [hgX'] with ω hω
          exact ENNReal.ofReal_le_ofReal (rp_lt_next hω.1 hω.2 ht).le
  have hne : ENNReal.ofReal (P[X 0]) * (∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P + 1) ≠ ⊤ :=
    ENNReal.mul_ne_top ENNReal.ofReal_ne_top (ENNReal.add_ne_top.2 ⟨hA, ENNReal.one_ne_top⟩)
  have h4 := ENNReal.toReal_mono hne h1
  rwa [ENNReal.toReal_mul, ENNReal.toReal_add hA ENNReal.one_ne_top,
    ENNReal.toReal_ofReal hpos.le, ENNReal.toReal_ofReal ht, ENNReal.toReal_one] at h4

lemma rp_integral_count (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    {t : ℝ} (ht : 0 ≤ t) :
    ∫ ω, (arrivalCount X t ω : ℝ) ∂P = (∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P).toReal := by
  have hgX := rp_ae_good P X hindep hident hnonneg hint hpos
  have hgX' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop := by
    filter_upwards [hgX] with ω h using ⟨h.1, h.2.1⟩
  rw [integral_eq_lintegral_of_nonneg_ae (Eventually.of_forall fun ω => Nat.cast_nonneg _)
    (rp_count_aemeas P X hident hgX' ht).aestronglyMeasurable]
  simp only [ENNReal.ofReal_natCast]

lemma rp_limit {μ : ℝ} (hμ : 0 < μ) (e : ℝ → ℝ) (μc : ℕ → ℝ) (hμc : Tendsto μc atTop (𝓝 μ))
    (hlow : ∀ t ≥ 0, t ≤ μ * (e t + 1))
    (hup : ∀ t ≥ 0, ∀ n : ℕ, 0 < μc n → μc n * (e t + 1) ≤ t + n) :
    Tendsto (fun t => e t / t) atTop (𝓝 (1 / μ)) := by
  rw [tendsto_order]
  constructor
  · intro a ha
    have hL : Tendsto (fun t : ℝ => 1 / μ - t⁻¹) atTop (𝓝 (1 / μ - 0)) :=
      tendsto_const_nhds.sub tendsto_inv_atTop_zero
    rw [sub_zero] at hL
    filter_upwards [(tendsto_order.1 hL).1 a ha, eventually_gt_atTop 0] with t h1 h2
    refine lt_of_lt_of_le h1 ?_
    have h3 := hlow t h2.le
    rw [le_div_iff₀ h2]
    have : (1 / μ - t⁻¹) * t = t / μ - 1 := by field_simp
    rw [this, sub_le_iff_le_add, div_le_iff₀ hμ]
    linarith
  · intro b hb
    have hinv : Tendsto (fun n => 1 / μc n) atTop (𝓝 (1 / μ)) :=
      tendsto_const_nhds.div hμc hμ.ne'
    obtain ⟨n, hn1, hn2⟩ := ((tendsto_order.1 hinv).2 b hb |>.and
      ((tendsto_order.1 hμc).1 0 hμ)).exists
    have hU : Tendsto (fun t : ℝ => 1 / μc n + (n / μc n - 1) * t⁻¹) atTop
        (𝓝 (1 / μc n + (n / μc n - 1) * 0)) :=
      tendsto_const_nhds.add (tendsto_const_nhds.mul tendsto_inv_atTop_zero)
    rw [mul_zero, add_zero] at hU
    filter_upwards [(tendsto_order.1 hU).2 b hn1, eventually_gt_atTop 0] with t h1 h2
    refine lt_of_le_of_lt ?_ h1
    have h3 := hup t h2.le n hn2
    rw [div_le_iff₀ h2]
    have : (1 / μc n + (n / μc n - 1) * t⁻¹) * t = (t + n) / μc n - 1 := by
      field_simp
      ring
    rw [this, le_sub_iff_add_le, le_div_iff₀ hn2]
    linarith

#print axioms rp_busTime_zero
#print axioms rp_busTime_succ
#print axioms rp_busTime_mono
#print axioms rp_le_iff
#print axioms rp_le_t
#print axioms rp_lt_next
#print axioms rp_count_mono
#print axioms rp_count_tendsto
#print axioms rp_ae_good
#print axioms rp_ratio_tendsto
#print axioms rp_wait_eq
#print axioms rp_wait_nonneg
#print axioms rp_busTime_nonneg
#print axioms rp_wait_ii
#print axioms rp_piece
#print axioms rp_int_busTime
#print axioms rp_int_bounds
#print axioms rp_wait_tendsto
#print axioms rp_tsum_count
#print axioms rp_tsum_time
#print axioms rp_wald
#print axioms rp_count_aemeas
#print axioms rp_trunc_integrable
#print axioms rp_trunc_tendsto
#print axioms rp_upper
#print axioms rp_lower
#print axioms rp_integral_count
#print axioms rp_limit

/-- Elementary renewal theorem, almost-sure form: if the gaps are non-negative, independent,
share one law, and have a finite positive mean $\mu$, then $N(t)/t \to 1/\mu$ on almost every run. -/
theorem elementary_renewal_theorem_ae (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0]) :
    ∀ᵐ ω ∂P, Tendsto (fun t : ℝ => (arrivalCount X t ω : ℝ) / t) atTop (𝓝 (1 / P[X 0])) := by

  filter_upwards [rp_ae_good P X hindep hident hnonneg hint hpos] with ω hω
  exact rp_ratio_tendsto hpos hω.1 hω.2.1 hω.2.2

/-- Elementary renewal theorem, form for averages: under the same hypotheses, the renewal
function $m(t) = E[N(t)]$ satisfies $m(t)/t \to 1/\mu$. -/
theorem elementary_renewal_theorem_mean (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0]) :
    Tendsto (fun t : ℝ => (∫ ω, (arrivalCount X t ω : ℝ) ∂P) / t) atTop (𝓝 (1 / P[X 0])) := by

  have hμc := rp_trunc_tendsto P X (hnonneg 0) hint
  obtain ⟨n0, hn0⟩ := ((tendsto_order.1 hμc).1 0 hpos).exists
  refine rp_limit hpos (fun t => ∫ ω, (arrivalCount X t ω : ℝ) ∂P)
    (fun n : ℕ => P[fun ω => min (X 0 ω) (n : ℝ)]) hμc ?_ ?_
  · intro t ht
    have hA := (rp_upper P X hindep hident hnonneg hint hpos ht n0 hn0).1
    rw [rp_integral_count P X hindep hident hnonneg hint hpos ht]
    exact rp_lower P X hindep hident hnonneg hint hpos ht hA
  · intro t ht n hn
    rw [rp_integral_count P X hindep hident hnonneg hint hpos ht]
    exact (rp_upper P X hindep hident hnonneg hint hpos ht n hn).2

/-- Inspection paradox: if moreover $E[X^2]$ is finite, then on almost every run the wait of a
passenger arriving at a time spread evenly over $[0, t]$ averages, as $t \to \infty$, to
$E[X^2] / (2\mu)$. -/
theorem inspection_paradox_mean_wait (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    (hint2 : Integrable (fun ω => X 0 ω ^ 2) P) :
    ∀ᵐ ω ∂P, Tendsto (fun t : ℝ => (∫ s in (0 : ℝ)..t, wait X s ω) / t) atTop
      (𝓝 (P[fun ω => X 0 ω ^ 2] / (2 * P[X 0]))) := by

  have hY := strong_law_ae_real (fun i ω => X i ω ^ 2) hint2
    (fun i j hij => (hindep.indepFun hij).comp (measurable_id.pow_const 2)
      (measurable_id.pow_const 2))
    (fun i => (hident i).comp (measurable_id.pow_const 2))
  filter_upwards [rp_ae_good P X hindep hident hnonneg hint hpos, hY] with ω hω hq
  exact rp_wait_tendsto hpos hω.1 hω.2.1 hω.2.2 hq


/-! Worked numbers from the card: gaps of 5 or 15 minutes, each with chance 1/2. -/

-- mean gap 10, mean square gap 125, variance 25
example : (1 / 2 : ℚ) * 5 + 1 / 2 * 15 = 10 := by norm_num
example : (1 / 2 : ℚ) * 5 ^ 2 + 1 / 2 * 15 ^ 2 = 125 := by norm_num
example : (125 : ℚ) - 10 * 10 = 25 := by norm_num
-- rate: 6 buses an hour
example : (60 : ℚ) / 10 = 6 := by norm_num
-- mean wait: 125 / (2 * 10) = 25/4 minutes, and the same as mu/2 + var/(2 mu)
example : (125 : ℚ) / (2 * 10) = 25 / 4 := by norm_num
example : (10 : ℚ) / 2 + 25 / (2 * 10) = 25 / 4 := by norm_num
-- length bias: share of time in 15-minute gaps 3/4, in 5-minute gaps 1/4; wait 1/4 * 5/2 + 3/4 * 15/2
example : (1 / 2 : ℚ) * 15 / 10 = 3 / 4 := by norm_num
example : (1 / 2 : ℚ) * 5 / 10 = 1 / 4 := by norm_num
example : (1 / 4 : ℚ) * (5 / 2) + 3 / 4 * (15 / 2) = 25 / 4 := by norm_num
-- the gap a passenger lands in averages 125 / 10 = 25/2 minutes
example : (125 : ℚ) / 10 = 25 / 2 := by norm_num
-- the sawtooth over one hour, gaps 5 15 5 5 15 15: tooth areas 25/2 and 225/2, area / 60 = 25/4
example : ((5 ^ 2 + 15 ^ 2 + 5 ^ 2 + 5 ^ 2 + 15 ^ 2 + 15 ^ 2 : ℚ) / 2) / 60 = 25 / 4 := by norm_num
-- sandwich at t = 60: 60/10 - 1 = 5 and (60 + 15)/10 - 1 = 13/2
example : (60 : ℚ) / 10 - 1 = 5 ∧ (60 + 15 : ℚ) / 10 - 1 = 13 / 2 := by norm_num
-- brute force over all 4096 patterns of 12 gaps (1 or 3 steps of 5 minutes): buses by minute 60 total 24047
example : (∑ b ∈ Finset.range 4096, ((Finset.Icc 1 12).filter
    (fun n => ∑ i ∈ Finset.range n, (1 + 2 * ((b / 2 ^ i) % 2)) ≤ 12)).card) = 24047 := by
  decide +kernel
-- m(60) = 24047/4096 sits inside the sandwich
example : (5 : ℚ) < 24047 / 4096 ∧ (24047 : ℚ) / 4096 ≤ 13 / 2 := by norm_num
-- passenger on a 5-minute mark: 5 * (1/2 * 0 + 1/2 * 3) / (10/5) = 15/4 minutes
example : (5 : ℚ) * (1 / 2 * (1 * 0 / 2) + 1 / 2 * (3 * 2 / 2)) / (10 / 5) = 15 / 4 := by norm_num
-- every gap a copy of the first: 1/2 * 12 + 1/2 * 4 = 8 buses an hour
example : (1 / 2 : ℚ) * (60 / 5) + 1 / 2 * (60 / 15) = 8 := by norm_num
-- try lines: gaps 1 or 19 give wait 181/20; short gaps with chance 3/4 give rate 8 and wait 5
example : ((1 / 2 : ℚ) * 1 ^ 2 + 1 / 2 * 19 ^ 2) / (2 * 10) = 181 / 20 := by norm_num
example : (60 : ℚ) / (3 / 4 * 5 + 1 / 4 * 15) = 8 ∧
    ((3 / 4 : ℚ) * 5 ^ 2 + 1 / 4 * 15 ^ 2) / (2 * (3 / 4 * 5 + 1 / 4 * 15)) = 5 := by norm_num
-- Poisson case, mean gap 15: E[X^2] = 2 * 15^2, wait 15
example : (2 * 15 ^ 2 : ℚ) / (2 * 15) = 15 := by norm_num

#print axioms elementary_renewal_theorem_ae
#print axioms elementary_renewal_theorem_mean
#print axioms inspection_paradox_mean_wait
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'rp_busTime_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_busTime_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_busTime_mono' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_le_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_le_t' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_lt_next' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_count_mono' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_count_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_ae_good' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_ratio_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_wait_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_wait_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_busTime_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_wait_ii' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_piece' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_int_busTime' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_int_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_wait_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_tsum_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_tsum_time' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_wald' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_count_aemeas' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_trunc_integrable' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_trunc_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_upper' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_lower' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_integral_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'rp_limit' depends on axioms: [propext, Classical.choice, Quot.sound]
'elementary_renewal_theorem_ae' depends on axioms: [propext, Classical.choice, Quot.sound]
'elementary_renewal_theorem_mean' depends on axioms: [propext, Classical.choice, Quot.sound]
'inspection_paradox_mean_wait' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> The first three are printed on the `try,` lines, by the formula only; the recursion and simulation are written for the 5-or-15 stop.
> - **Even buses.** Guess first: gaps of exactly 10 minutes. The rate stays at 6 an hour and the mean wait falls to 5, half the gap, since the variance is 0.
> - **Rarer long gaps.** Guess first: short gaps with chance 0.75, long with 0.25. The mean gap is 7.5 minutes, the rate 8 an hour, and the mean wait 5 minutes, while half the mean gap is 3.75.
> - **An extreme gap.** Guess first: gaps of 1 or 19 minutes, half each. The mean gap is still 10 and the rate still 6 an hour; the mean wait is 9.05 minutes, nearly the whole mean gap.
> - **The switchboard.** Guess first: calls at 4 an hour. The simulated wait is 14.973520 with standard error 0.075258, against 15 by the formula: the full gap, not half.

---

## The usual mistake

> [!warning]
> **Averaging over buses when the question is about the clock.** "Half the buses come after 5 minutes and half after 15" is a statement per bus. A passenger does not sample a bus; the passenger samples a moment, and moments sit mostly in long gaps. Counting per bus gives 5 minutes; counting per moment gives 6.25.
>
> - **Thinking the rate depends on the spread.** It does not. Gaps of 5 or 15 minutes and gaps of exactly 10 both give 6 buses an hour; only the wait changes.
> - **Blaming bad luck.** Nothing about the buses is unfair; long gaps hold 0.75 of the time by arithmetic.
> - **Quoting 6.25 for a fixed clock time.** On a 5-minute grid, arriving exactly at minute 6000 gives 3.75, just after gives 8.749; 6.25 is an average over arrival times.
> - **Dropping independence.** If each gap copies the last, the average rate is 8 an hour, not 6.

---

## Where you meet it in real life

- **Waiting for buses, trains and lifts.** Transit agencies report "excess wait time": the passengers' average wait minus half the scheduled gap. When buses keep the scheduled average spacing, that excess is the $\sigma^2/(2\mu)$ term, and bunching raises it.
- **Class sizes.** The average class size per class is smaller than the average class size per student, because large classes hold more students: length bias, with size for length.
- **Replacing parts.** Bulbs replaced on failure form a renewal process: bulbs bought per year is one over the mean life, whatever the spread, and the bulb found burning at a random inspection is on average longer-lived than a typical one.
- **Queues and chains.** The times a continuous-time chain returns to a state are renewal times, and the long-run share of time spent there is the mean stay over the mean return time: [Continuous-time chains](05-continuous-time-markov-chains-and-queues.md).
- **Claims on an insurer.** A claims process with non-exponential gaps between claims is a renewal process; the total paid is then a sum over a renewal count, the non-Poisson cousin of [Compound Poisson](04-compound-poisson.md).

> **Say it back**
> A renewal process is a stream of arrivals with independent gaps sharing one law; each arrival starts it afresh. In the long run arrivals come at one per mean gap, because the count is squeezed between two sums of gaps and the strong law pins both. A random moment lands in a gap with chance proportional to its length, so the wait averages the mean square gap over twice the mean gap. For buses 5 or 15 minutes apart that is 6.25 minutes, not 5; for Poisson arrivals it is the whole mean gap.

---

## What this builds on

- [Poisson process](01-poisson-process.md): the counting process $N(t)$ and the exponential gaps whose memorylessness gives the Poisson case of the paradox.
- [The strong law of large numbers](../../10-Measure%20and%20integration/10-The%20Limit%20Theorems%2C%20Proved/04-strong-law-of-large-numbers.md): pins the average gap and the average squared gap on almost every run.
- [Stopping times](../02-Martingales/03-stopping-times-and-optional-stopping.md): why the index of the first bus after $t$ is a stopping time, the hypothesis Wald's identity needs.

## Where this goes next

- [Daily monitoring](../../12-Financial%20mathematics/16-Barriers%2C%20touches%20and%20lookbacks/03-discrete-monitoring-correction.md): a barrier option checked once a day; its correction rests on this card's mean wait, $E[X^2]/(2\mu)$, read as the mean overshoot of the daily price walk past a far barrier, with the amounts by which the walk beats its previous record as the gaps.

A passenger's wait past a random moment averages $E[X^2]/(2\mu)$; how far a price checked only at the daily close has overshot a barrier when a close is first seen beyond it, and how far that moves the option's price, is the question [Daily monitoring](../../12-Financial%20mathematics/16-Barriers%2C%20touches%20and%20lookbacks/03-discrete-monitoring-correction.md) answers.

---

## Sources

Verified 30 Sep 2026: every link below resolves to the publisher's page.

- Feller, William. "On the Integral Equation of Renewal Theory." *The Annals of Mathematical Statistics* 12, no. 3 (1941): 243–267. [doi:10.1214/aoms/1177731708](https://doi.org/10.1214/aoms/1177731708). The renewal equation, the recursion the code solves, and the long-run rate from it.
- Doob, J. L. "Renewal Theory from the Point of View of the Theory of Probability." *Transactions of the American Mathematical Society* 63, no. 3 (1948): 422–438. [doi:10.1090/S0002-9947-1948-0025098-8](https://doi.org/10.1090/S0002-9947-1948-0025098-8). Renewal limits proved from the strong law, the route of Steps 1 and 2.
- Feller, William. *An Introduction to Probability Theory and Its Applications*, Volume 2, 2nd ed. Wiley, 1971. [Publisher page](https://www.wiley.com/en-us/An+Introduction+to+Probability+Theory+and+Its+Applications%2C+Volume+2%2C+2nd+Edition-p-9780471257097). The waiting-time paradox for Poisson arrivals, and the renewal theorems for gaps off a grid that this card quotes without proof.
- Ross, Sheldon M. *Introduction to Probability Models*, 13th ed. Elsevier, 2023. [Publisher page](https://shop.elsevier.com/books/introduction-to-probability-models/ross/978-0-443-18761-2). The renewal-theory chapter: Wald's identity, renewal-reward processes and the inspection paradox at textbook pace.
