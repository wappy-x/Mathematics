# Stationary distributions: the mix that stays the same under one more step

[Syllabus](../../../SYLLABUS.md) → [Stochastic processes and calculus](../README.md) → [Markov Chains](../README.md#s03) → Stationary distributions

---

## General Overview

A town logs its weather once a day as sunny, cloudy or rainy. Years of records show that tomorrow depends on today and on nothing earlier. After a sunny day, tomorrow is sunny 6 times in 10, cloudy 3 times, rainy once. After a cloudy day the chances are 0.4, 0.4 and 0.2. After a rainy day they are 0.4, 0.3 and 0.3. This town is not the one on the earlier cards of this shelf; its numbers are chosen so the answers come out round.

A reservoir engineer wants one number from this: over many years, what fraction of days are rainy? Not the chance of rain tomorrow, which depends on today. The share of all days.

The answer is 1 day in 6. Half of all days are sunny and a third are cloudy. These three shares have a second property, and it is the one that makes them computable. Suppose the only thing known about today is "sunny with chance 1/2, cloudy with 1/3, rainy with 1/6". Push that mix through one night of weather and tomorrow's mix is again 1/2, 1/3, 1/6. The weather still changes every day; the mix of chances does not. A mix with that property is called a **stationary distribution**, the term used from here on.

The card solves for that mix, proves it is the only one, and proves it is also the long-run share of days. One over a share is the average wait between visits: rain comes back every 6 days on average.

**A stationary distribution is a mix of chances over the states that one more step of the chain leaves unchanged; on a finite chain where every state can reach every other there is exactly one, and its entries are the long-run fractions of time spent in each state.**

**What kind of fact this is:** a definition (the balance equations), and three theorems about it — existence, uniqueness, and the long-run time fractions — each proved on this card in Why it works, with the full arguments in a folded Detailed proof.

### The picture: one run of 100,000 days

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Rainy days per 100, counted from the start of one simulated run"
    x-axis "Days simulated" [10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000]
    y-axis "Rainy days per 100 days" 0 --> 20
    line [0.00, 10.00, 13.00, 15.33, 15.40, 16.27, 16.53, 16.90, 16.86]
    line [16.67, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67]
```

Orange: the running share of rainy days in one sample, 100,000 days drawn with a SplitMix64 random-number generator, seed 20260929, starting from a sunny day, read at the days marked (not evenly spaced). The first ten days happened to be dry. Green: the stationary share, 1/6, which is 16.67 rainy days per 100. After 100,000 days the sample reads 16.86, a share of 0.1686 with a standard error of 0.0015. Another seed draws another path; almost every path settles on the same line.

---

## The formula

Notation first, in words. The kind of day on day $n$ is written $X_n$, the value of the process at time $n$, with time counted in days ([Stochastic processes](../01-Random%20Walks%20and%20Filtrations/01-processes-and-paths.md)). The chances of one night's change sit in a table $P$, the transition matrix ([Markov chains](01-markov-chains.md)): its entry $p_{ij}$, in row $i$ and column $j$, is the chance tomorrow is $j$ given today is $i$. Each row adds to 1. Rows and columns run sunny, cloudy, rainy:

`P = [[0.6, 0.3, 0.1], [0.4, 0.4, 0.2], [0.4, 0.3, 0.3]]`

A mix of chances over the three kinds of day is written as a row of three numbers. The row $\mu P$, the row times the table, is tomorrow's mix when today's is $\mu$; $\mu P^n$ is the mix $n$ days on ([n-step transitions](02-multi-step-transitions.md)).

The Greek letter $\pi$ (here a row of shares, not the circle constant) names the stationary distribution. With $N$ states, here $N = 3$, it is any row with

$$\pi P = \pi, \qquad \pi_j \ge 0 \text{ for every } j, \qquad \pi_1 + \pi_2 + \dots + \pi_N = 1.$$

**Read it aloud:** a mix of chances that one more day of weather hands back unchanged, with no negative entries and a total of 1.

Written out one column at a time, $\pi P = \pi$ is one equation per state, the **balance equations**:

$$\pi_j = \sum_{i} \pi_i \, p_{ij} \quad \text{for every state } j.$$

**Read it aloud:** the share of days that are $j$ equals the sum, over every kind of day $i$, of the share of $i$-days times the chance an $i$-day is followed by a $j$-day.

Subtract $\pi_j p_{jj}$ from both sides and the same equation reads as a flow: days leaving $j$ balance days arriving.

$$\pi_j\,(1 - p_{jj}) = \sum_{i \ne j} \pi_i \, p_{ij}.$$

The mean return time $m_j$ is the average number of days from a $j$-day to the next $j$-day. The third theorem gives it for free:

$$m_j = \frac{1}{\pi_j}.$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $X_n$, $n$ | the kind of day on day $n$; days counted from today, day 0 | sunny on day 0 | — |
| $i$, $j$, $k$ | two states, today's and tomorrow's; $k$ a third state, or a count of visits or steps | $i$ sunny, $j$ rainy | — |
| $N$ | the number of states, here kinds of day | 3 | more equations, same method |
| $P$, $p_{ij}$, $I$ | the transition matrix; chance tomorrow is $j$ given today is $i$; the table that changes nothing | 0.1 from sunny to rainy, 0.3 from rainy to rainy | raising a chance into rainy raises $\pi_R$ |
| $\mu$ | a starting mix, a row; $\mu P^n$ is the mix $n$ days later | sunny for certain: (1, 0, 0) | — |
| $\pi$, $\pi_i$, $\pi_j$ | the stationary distribution; its entry for a state | (1/2, 1/3, 1/6) | — |
| $\pi_S$, $\pi_C$, $\pi_R$ | the long-run shares of sunny, cloudy, rainy days | 1/2, 1/3, 1/6 | — |
| $m_j$, $m_R$ | mean days from a $j$-day to the next $j$-day; the same for rain | 2, 3, 6; $m_R$ = 6 | a larger mean wait means a smaller share |
| $V_n$ | the count of $j$-days among days 1 to $n$ | 16,857 rainy in 100,000 | — |
| $v$, $w$, $h$, $\delta$ | in the proofs: a row with $vP = v$; its entries made non-negative; a column with $Ph = h$; a smallest chance of reaching $j$ | — | — |
| $T_j$, $\tau_k$, $\tau_1$, $P_i$, $P_j$, $E_i$ | in the proofs: the first day after day 0 that is $j$; the day of the $k$-th visit; chance and average starting from $i$ | — | — |
| $\nu$, $\nu_i$, $\nu_R$ | in the proofs: expected days of each kind in one stretch between two $j$-days | (3, 2, 1) for $j$ rainy | — |

### The picture: the town's weather as a chain

<p align="center"><img src="../figures/stationary-distributions.svg" alt="The town&#x27;s weather as a chain: three kinds of day, each circle&#x27;s area proportional to its long-run share of days, arrows labelled with the chance of each change overnight" width="420"></p>

Each circle's area is drawn to the scale of its long-run share of days, so the sunny circle has three times the area of the rainy one. Arrows carry the chance of each change overnight; the chance of staying is written beside each circle.

### When it holds

- **Finitely many states.** With a finite list a stationary distribution always exists. On an endless list it can fail to: a walk on all the whole numbers, stepping up or down with chance 1/2, would need every state to hold the same share, and no equal shares of infinitely many states add to 1.
- **Every state reachable from every other**, the chain being **irreducible** ([Classifying states](03-classifying-states.md)). This buys uniqueness and start-free time fractions. Split the town into a dry spell that never rains and a wet spell that never clears, and two different mixes both balance; the long-run share of rain is 0 or 1 depending on the first day. One closed class plus transient states also gives just one: chance only drains out of the transient states, so a mix that never changes gives them 0, and Step 3 applies on the closed class. On the board from Classifying states the start square gets 0 and the jail 2/3, the 0.6667 seen there after 200 turns.
- **The same table every day.** A seasonal climate has a different table each month; one fixed $\pi$ then describes nothing, and the long-run shares come from the year-long cycle instead.
- **Tomorrow depends on today only.** If a third wet day in a row were likelier than a second, the three-state table is the wrong model. Fitted by counting the record's changes, it still gets the share of rainy days right, since counted changes balance as in Step 0; but long wet spells come out too rare, and forecasts two or more days ahead are off.
- **Not needed: settling down.** Neither existence, uniqueness nor the time fractions needs the day-by-day forecasts to converge. That extra property, and the aperiodicity it requires, is the business of [Convergence to equilibrium](05-convergence-to-equilibrium.md).

---

## Why it works

### Step 0: a long record balances its flows

Count the rainy days in a long record. Each one began either as a change into rain or as rain carrying on, and each one ends by carrying on or by changing out. Over a long record the changes into rain and out of rain differ by at most one. Divide by the length of the record and the share of days that turn rainy equals the share that stop being rainy. That is the flow equation above for rainy, and the same holds for every state. The long-run shares must balance, so they must solve $\pi P = \pi$. The steps below make this exact: a balancing mix exists, it is the only one, and the long-run shares do settle on it.

### Step 1: a stationary start stays stationary

If today's mix is $\pi$, tomorrow's is $\pi P = \pi$, and the day after is $\pi P = \pi$ again. By induction $\pi P^n = \pi$ for every $n$: forecasts of any day ahead are the same mix. More holds. The chance of any run of weather, say sunny then rainy then sunny, starting on day $n$ is $\pi_S\,p_{SR}\,p_{RS}$ whatever $n$ is, because only the first factor could depend on $n$. The whole process, not only each day's mix, looks the same from any starting day. That is what **stationary** means: the statistics stand still while the weather moves.

### Step 2: a balancing mix always exists

Each row of $P$ adds to 1, so $P$ times a column of ones is that column of ones: 1 is an eigenvalue of $P$ ([Eigenvalues and eigenvectors](../../03-Algebra/07-Eigenvalues%20and%20Symmetric%20Matrices/02-eigenvalues-and-eigenvectors.md)). A square table and its transpose, the table flipped across its diagonal, share eigenvalues, so some row $v$, not all zero, has $vP = v$. It is a left eigenvector: it multiplies from the left.

Its entries could be negative, and a share cannot be. Replace every entry by its size, giving $w$. Each entry of the row $w$ times $P$ is at least the matching entry of $w$, because the size of a sum is at most the sum of the sizes. But both rows have the same total, because every row of $P$ adds to 1. A row that is nowhere smaller and has the same total is equal: $wP = w$. Divide $w$ by its total and it is a stationary distribution. Nothing here used irreducibility: every finite chain has at least one.

### Step 3: irreducible means only one

Take any column $h$ with $Ph = h$. Each entry of $P$ times $h$ is an average of entries of $h$, weighted by a row of $P$. Look at the largest entry of $h$. It is an average of entries none larger than itself, so every entry it averages over, every state reachable in one day, holds the same largest value. In an irreducible chain that spreads to every state. So $h$ is constant: the only columns $P$ leaves unchanged are multiples of the column of ones.

That fixes a count. The solutions of $(P - I)h = 0$, with $I$ the table that changes nothing, form a line, so $P - I$ has rank $N - 1$: the rank, the number of independent rows, and the dimension of the solutions add up to $N$ ([Rank and nullity](../../03-Algebra/05-Solving%20Systems/05-rank-nullity.md)). A table and its transpose have the same rank, so the rows with $v(P - I) = 0$ also form a line. Requiring a total of 1 picks one point on it. The stationary distribution is unique.

Every entry is positive, too. Some state $i$ has $\pi_i > 0$; state $j$ is reachable from $i$ in some number of days $n$, so $\pi_j = (\pi P^n)_j \ge \pi_i\,(P^n)_{ij} > 0$.

### Step 4: the stationary share is the long-run time fraction

Fix rainy. Cut one long run of weather at every rainy day. The stretches between consecutive rainy days are **excursions**. Each excursion starts from a rainy day, and from then on the chain forgets everything earlier. So the excursions are independent, and their lengths all follow one distribution, with mean $m_R$.

By the strong law of large numbers ([The strong law of large numbers](../../10-Measure%20and%20integration/10-The%20Limit%20Theorems%2C%20Proved/04-strong-law-of-large-numbers.md)), $k$ excursions take about $k\,m_R$ days, with probability 1. So among $n$ days about $n / m_R$ are rainy: the fraction of rainy days tends to $1/m_R$ on almost every path, whatever the first day.

It remains to see that $1/m_R$ is $\pi_R$. Let $\nu_i$ be the expected number of $i$-days in one excursion, counting its opening rainy day. Then $\nu_R = 1$, and the $\nu_i$ add to $m_R$, the excursion's mean length. One more day moves each excursion's days one place along: its opening rainy day drops off the front and the rainy day that closes it arrives at the back. So $\nu P = \nu$. By Step 3, $\nu / m_R$ is $\pi$, and its rainy entry is $1/m_R$. Here $\nu$ = (3, 2, 1): an excursion from rain averages 3 sunny days, 2 cloudy and the 1 rainy day, 6 in all.

### Step 5: stationary is not the same as settling

Replace the weather by a rota: sunny, then cloudy, then rainy, then sunny again, for certain. Every state reaches every other, so Steps 2 to 4 apply. The stationary distribution is (1/3, 1/3, 1/3), and a third of days are rainy.

Now forecast from a sunny day. The chance of rain on day $n$ is 0, 1, 0, 0, 1, 0, …: it never settles. The rota is **periodic**: it returns to each state only in multiples of 3 days.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The rota, from a sunny day 0: forecast against share"
    x-axis "Day n" [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    y-axis "Per 100" 0 --> 100
    line [0.00, 100.00, 0.00, 0.00, 100.00, 0.00, 0.00, 100.00, 0.00, 0.00, 100.00, 0.00]
    line [0.00, 50.00, 33.33, 25.00, 40.00, 33.33, 28.57, 37.50, 33.33, 30.00, 36.36, 33.33]
    line [33.33, 33.33, 33.33, 33.33, 33.33, 33.33, 33.33, 33.33, 33.33, 33.33, 33.33, 33.33]
```

Orange: the chance, per 100, that day $n$ is rainy; it jumps between 0 and 100 forever. Green: rainy days per 100 up to day $n$, closing in on 33.33. Dark: the stationary share. A stationary distribution, a settling forecast and a time fraction are three different things; the town has all three, the rota only the first and third.

<details>
<summary>Detailed proof</summary>

**Setting.** A chain on the states 1 to $N$ with transition matrix $P$: $p_{ij} \ge 0$ and $\sum_j p_{ij} = 1$ for each $i$. Write $\mathbf{1}$ for the column of ones and $P_i$, $E_i$ for chance and average when $X_0 = i$.

**1. Existence (any finite chain).** $P\mathbf{1} = \mathbf{1}$, so $P - I$ is singular, so is its transpose, and some row $v \ne 0$ has $vP = v$. Let $w_j = \lvert v_j\rvert$. Then $w_j = \lvert\sum_i v_i p_{ij}\rvert \le \sum_i w_i p_{ij} = (wP)_j$. Summing over $j$, $\sum_j (wP)_j = \sum_i w_i \sum_j p_{ij} = \sum_i w_i$. So the non-negative differences $(wP)_j - w_j$ add to 0 and all vanish: $wP = w$, and $\pi = w / \sum_i w_i$ is stationary.

**2. Uniqueness and positivity (irreducible).** Let $Ph = h$ and let $h_i = \max_k h_k$. Then $0 = \sum_k p_{ik}(h_i - h_k)$, a sum of non-negative terms, so $h_k = h_i$ whenever $p_{ik} > 0$. Repeating along a path from $i$ to any state, which irreducibility provides, $h$ is constant. So the null space of $P - I$ is spanned by $\mathbf{1}$, its rank is $N - 1$, the left null space has dimension $N - (N - 1) = 1$, and at most one row in it has entries adding to 1. With part 1, exactly one does. Positivity is Step 3's inequality.

**3. Finite mean return time.** Irreducibility gives, for each start $i$, a path to $j$ of at most $N$ days with positive chance; let $\delta > 0$ be the smallest of these $N$ chances. Let $T_j$ be the first day $n \ge 1$ with $X_n = j$. From any state, $j$ is reached within the next $N$ days with chance at least $\delta$, so by the Markov property $P_i(T_j > kN) \le (1 - \delta)^k$ and $E_i T_j = \sum_{n \ge 0} P_i(T_j > n) \le N/\delta < \infty$. Write $m_j = E_j T_j$.

**4. Time fractions.** Let $\tau_1 < \tau_2 < \dots$ be the successive days $n \ge 1$ with $X_n = j$; each is finite with probability 1 by part 3, and each is a stopping time (the day can be recognised when it arrives). By the strong Markov property, the gaps $\tau_{k+1} - \tau_k$ are independent, each with the law of $T_j$ under $P_j$, and independent of $\tau_1$. The strong law gives $\tau_k / k \to m_j$ almost surely. With $V_n$ the number of $j$-days among days 1 to $n$, $\tau_{V_n} \le n < \tau_{V_n + 1}$, so $V_n/n \to 1/m_j$ almost surely, from any start.

**5. Kac's formula, $\pi_j = 1/m_j$.** Let $\nu_i = E_j \sum_{k=0}^{T_j - 1} \mathbf{1}\{X_k = i\} = \sum_{k \ge 0} P_j(X_k = i,\ k < T_j)$. Then $\nu_j = 1$ and $\sum_i \nu_i = E_j T_j = m_j$. The event $\{k < T_j\}$ is decided by $X_0, \dots, X_k$, so the Markov property gives $\sum_i P_j(X_k = i, k < T_j)\,p_{il} = P_j(X_{k+1} = l, k + 1 \le T_j)$. Summing over $k \ge 0$: $(\nu P)_l = E_j \sum_{k=1}^{T_j} \mathbf{1}\{X_k = l\}$. Since $X_0 = X_{T_j} = j$, shifting the window from days $0, \dots, T_j - 1$ to days $1, \dots, T_j$ changes no count, and $(\nu P)_l = \nu_l$. So $\nu / m_j$ is stationary; by part 2 it is $\pi$, and $\pi_j = \nu_j / m_j = 1/m_j$. With part 4, the fraction of $j$-days tends to $\pi_j$.

</details>

**Another road.** When every change is matched by its reverse, $\pi_i p_{ij} = \pi_j p_{ji}$ for every pair, the flows balance link by link, and summing over $i$ gives $\pi P = \pi$ at once. This **detailed balance** is how [Random walks on a graph](../../09-Probability%20and%20statistics/14-Random%20Graphs%20and%20the%20Probabilistic%20Method/05-random-walks-on-graphs-and-mixing.md) finds a random walk's stationary distribution, proportional to each page's number of links, and how [MCMC](07-markov-chain-monte-carlo.md) builds a chain with a chosen $\pi$. The town's weather does not have it: $\pi_S p_{SR}$ = 0.05 but $\pi_R p_{RS}$ = 0.0667, so fewer days go straight from sunny to rainy than from rainy to sunny. A net drift round the loop sunny, cloudy, rainy makes up the difference.

---

## Worked numbers, by hand

Solve the flow equations for the town. The sunny equation first, then the rainy one.

| Step | Arithmetic | Value |
| --- | --- | --- |
| sunny: out = in | $0.4\,\pi_S = 0.4\,\pi_C + 0.4\,\pi_R$ | $\pi_S = \pi_C + \pi_R$ |
| shares add to 1 | $\pi_S + (\pi_C + \pi_R) = 2\,\pi_S = 1$ | $\pi_S$ = 1/2 |
| rainy: out = in | $0.7\,\pi_R = 0.1 \times \tfrac12 + 0.2\,\pi_C$ | — |
| use $\pi_C = \tfrac12 - \pi_R$ | $0.7\,\pi_R = 0.05 + 0.1 - 0.2\,\pi_R$, so $0.9\,\pi_R = 0.15$ | **$\pi_R$ = 1/6** |
| cloudy | $1 - \tfrac12 - \tfrac16$ | $\pi_C$ = 1/3 |
| check the spare equation, cloudy | $\tfrac12(0.3) + \tfrac13(0.4) + \tfrac16(0.3) = 0.15 + 0.1333 + 0.05$ | 1/3 |
| flow out of rainy, per day | $\tfrac16 \times 0.7$ | 7/60 |
| flow into rainy, per day | $\tfrac12 \times 0.1 + \tfrac13 \times 0.2$ | 7/60 |
| mean return to rain | $1 / \pi_R$ | **6 days** |

One day in six is rainy, about 61 days a year, and a rainy day comes back after 6 days on average. A sunny day recurs every 2 days on average and a cloudy one every 3. The code reaches 2, 3 and 6 a second way, from the first-step equations for the waiting time, knowing nothing of $\pi$. Each such equation says the wait from a state is one day plus the average wait from wherever tomorrow lands ([Absorption](06-absorption-and-first-step-analysis.md)).

The three balance equations are one too many: they always add up to "total in = total out", so one is spare, and the total of 1 takes its place. The check row confirms the spare one.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Solve $P x = x$, a column, instead of $\pi P = \pi$ | 1/3 rainy, against 1/6 | Every row of $P$ adds to 1, so the column of ones always solves it; the answer is uniform whatever the weather |
| Average the rain column: (0.1 + 0.2 + 0.3)/3 | 1/5 | Weights each kind of today equally; sunny days are three times as common as rainy ones |
| Read rain-after-rain as the share | 3/10 | That is a chance given today is rainy, not a share of all days |
| Drop irreducibility: dry spell and wet spell never meet | 0 or 1, depending on day 0 | Two mixes balance, (1/2, 1/2, 0) and (0, 0, 1), and the record picks one |
| Expect a periodic chain's forecast to reach $\pi$ | forecast 0, 100, 0 per 100 forever | $\pi$ exists and is the time fraction, but the forecast never settles |

The code prints every row.

---

## Code, from first principles, and it actually runs

The code takes three independent roads to the long-run shares. The first solves the balance equations exactly in fractions by elimination, with the spare equation replaced by the total. The second solves the first-step equations for the mean wait until each state returns, exactly, and takes one over each: Kac's formula, reached without ever writing $\pi P = \pi$. The third simulates 100,000 days with a SplitMix64 generator written out, seed 20260929, and prints each share with a standard error from 100 blocks of 1,000 days, since neighbouring days are not independent. It also prints every other number on the card. The asserts tie the roads together, hold the simulated shares to within 4 standard errors, and check the rota, the split climate and the transient start of the classifying-states board.

### Python

```python
# Stationary distributions -- the check behind the card.  Nothing is imported.
# A town's days are sunny, cloudy or rainy; tomorrow depends only on today.
# Three roads to the long-run share of each kind of day: the balance equations
# solved exactly; mean return times from first-step equations (share = 1/return
# time); and 100000 simulated days, with a standard error from blocks of days.
from fractions import Fraction as Fr

NAMES = ("sunny", "cloudy", "rainy")
TENTHS = [[6, 3, 1], [4, 4, 2], [4, 3, 3]]    # row = today, column = tomorrow
P = [[Fr(x, 10) for x in row] for row in TENTHS]
DAYS, BLOCKS, SEED = 100000, 100, 20260929
MASK = (1 << 64) - 1

def solve(A, b):                               # exact Gaussian elimination
    n = len(A)
    M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        piv = next(r for r in range(c, n) if M[r][c] != 0)
        M[c], M[piv] = M[piv], M[c]
        for r in range(n):
            if r != c and M[r][c] != 0:
                f = M[r][c] / M[c][c]
                M[r] = [x - f * y for x, y in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def balance(P, left=True):                     # pi P = pi (left) or P x = x (right), sum 1
    n = len(P)
    A = [[(P[i][j] if left else P[j][i]) - (1 if i == j else 0) for i in range(n)] for j in range(n)]
    A[-1] = [Fr(1)] * n                        # one balance equation is spare: swap in the total
    return solve(A, [Fr(0)] * (n - 1) + [Fr(1)])

def mean_return(P, j):                         # first-step equations for days until j
    others = [i for i in range(len(P)) if i != j]
    A = [[(1 if a == b else 0) - P[a][b] for b in others] for a in others]
    h = dict(zip(others, solve(A, [Fr(1)] * len(others))))
    return 1 + sum(P[j][k] * h[k] for k in others)

def vecmat(v, P):
    return [sum(v[i] * P[i][j] for i in range(len(v))) for j in range(len(P[0]))]

class SplitMix64:
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def step(g, today):
    u, acc = g.uniform(), 0
    for j in range(3):
        acc += TENTHS[today][j]
        if u < acc / 10: return j
    return 2

pi = balance(P)
print("table P, rows today sunny, cloudy, rainy: " + "; ".join(", ".join(f"{float(x):.1f}" for x in row) for row in P))
print("road 1, balance equations: " + ", ".join(f"{NAMES[i]} {pi[i]}" for i in range(3)))
m = [mean_return(P, j) for j in range(3)]
print("road 2, mean days between visits: " + ", ".join(f"{NAMES[j]} {m[j]}" for j in range(3)))
print("road 2, one over those: " + ", ".join(f"{NAMES[j]} {1 / m[j]}" for j in range(3)))
assert [1 / x for x in m] == pi                # two exact roads agree
assert vecmat(pi, P) == pi                     # includes the balance equation that was swapped out
print(f"hand, sunny: pi_S = pi_C + pi_R and sum 1 give pi_S = {pi[0]}")
pr = (P[0][2] * pi[0] + P[1][2] * (1 - pi[0])) / (1 - P[2][2] + P[1][2])   # rainy balance, pi_C = 1/2 - pi_R
assert pr == pi[2]                             # the hand route lands on road 1
print(f"hand, rainy: 0.7 pi_R = 0.1 (1/2) + 0.2 (1/2 - pi_R), so 0.9 pi_R = 0.15, pi_R = {pr}")
print(f"hand, spare cloudy equation: {float(pi[0] * P[0][1]):.4f} + {float(pi[1] * P[1][1]):.4f} + {float(pi[2] * P[2][1]):.4f} = {vecmat(pi, P)[1]}")
print(f"rainy days in a 365-day year: {float(365 * pi[2]):.2f}")
print("excursion from rain, expected days of each kind, pi times m_R: " + ", ".join(str(x * m[2]) for x in pi))
print(f"detailed balance fails: pi_S p_SR = {float(pi[0] * P[0][2]):.4f}, pi_R p_RS = {float(pi[2] * P[2][0]):.4f}")
print("flow, out of rainy per day: " + f"{pi[2] * (1 - P[2][2])}; into rainy: {pi[0] * P[0][2] + pi[1] * P[1][2]}")

g, today, counts, blk, cur = SplitMix64(SEED), 0, [0, 0, 0], [], [0, 0, 0]
marks = (10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000)
running = []
for d in range(1, DAYS + 1):                   # day 0 is sunny; count days 1 .. DAYS
    today = step(g, today)
    counts[today] += 1
    cur[today] += 1
    if d % (DAYS // BLOCKS) == 0: blk.append(cur); cur = [0, 0, 0]
    if d in marks: running.append(100 * counts[2] / d)
print("figure, rainy days per 100, running, days " + ", ".join(map(str, marks)) + ": " + ", ".join(f"{x:.2f}" for x in running) + f"; exact {100 * float(pi[2]):.2f}")
frac = [c / DAYS for c in counts]
bs = DAYS // BLOCKS
ses = [(sum((b[i] / bs - frac[i]) ** 2 for b in blk) / (BLOCKS - 1) / BLOCKS) ** 0.5 for i in range(3)]
se = ses[2]
naive = (frac[2] * (1 - frac[2]) / DAYS) ** 0.5
print("road 3, simulated shares of 100000 days: " + ", ".join(f"{NAMES[i]} {frac[i]:.4f} +- {ses[i]:.4f}" for i in range(3)))
print(f"road 3, rainy share {frac[2]:.4f} +- {se:.4f} (100 blocks of 1000 days); naive iid s.e. {naive:.4f}")
print(f"road 3, rainy days {counts[2]}, days per rainy day, simulated: {DAYS / counts[2]:.2f} +- {se / frac[2] ** 2:.2f}; exact mean return {m[2]}")
assert all(abs(frac[i] - float(pi[i])) < 4 * ses[i] for i in range(3))   # simulation against the exact shares

v = [1.0, 0.0, 0.0]
fc = {}
for n in range(1, 61):
    v = vecmat(v, [[float(x) for x in r] for r in P])
    fc[n] = v[2]
print("forecast, chance of rain n days after a sunny day, n = 1, 2, 3, 5, 10: " + ", ".join(f"{fc[n]:.4f}" for n in (1, 2, 3, 5, 10)))
assert abs(fc[60] - float(pi[2])) < 1e-12      # this chain's forecasts settle (next card: why)

print(f"mistake, column convention P x = x: rainy {balance(P, left=False)[2]} (uniform, since rows sum to 1)")
print(f"mistake, average of the rain column: {sum(P[i][2] for i in range(3)) / 3}")
print(f"mistake, rain after rain read as the share: {P[2][2]}")
ROTA = [[Fr(0), Fr(1), Fr(0)], [Fr(0), Fr(0), Fr(1)], [Fr(1), Fr(0), Fr(0)]]
rp = balance(ROTA)
print("rota sunny -> cloudy -> rainy -> sunny: stationary " + ", ".join(str(x) for x in rp))
v, st, seen, fcr, frr = [Fr(1), Fr(0), Fr(0)], 0, 0, [], []
for n in range(1, 13):
    v = vecmat(v, ROTA); st = (st + 1) % 3; seen += st == 2
    fcr.append(100 * v[2]); frr.append(100 * seen / n)
print("figure, rota, chance of rain on day n (per 100), n = 1..12: " + ", ".join(f"{float(x):.2f}" for x in fcr))
print("figure, rota, rainy days per 100 up to day n, n = 1..12: " + ", ".join(f"{x:.2f}" for x in frr))
assert fcr[9] == 0 and fcr[10] == 100         # day 10 dry for sure, day 11 wet for sure: no settling
assert abs(frr[-1] - 100 * float(rp[2])) < 1e-9   # yet the share of rainy days is the stationary 1/3
SPLIT = [[Fr(1, 2), Fr(1, 2), Fr(0)], [Fr(1, 2), Fr(1, 2), Fr(0)], [Fr(0), Fr(0), Fr(1)]]
a, b = [Fr(1, 2), Fr(1, 2), Fr(0)], [Fr(0), Fr(0), Fr(1)]
assert vecmat(a, SPLIT) == a and vecmat(b, SPLIT) == b
print("split climate (rain stays, dry stays dry): stationary (1/2, 1/2, 0) and (0, 0, 1); rainy share 0 or 1")
z, s6, hf = Fr(0), Fr(1, 6), Fr(1, 2)          # classifying-states' board: start S, ring A, B, C, jail J
BOARD = [[1 - s6, s6, z, z, z], [z, z, hf, z, hf], [z, hf, z, hf, z], [z, z, hf, z, hf], [z, s6, z, z, 1 - s6]]
bp = balance(BOARD)
print("one closed class plus a transient start (classifying-states' board, S A B C J): stationary " + ", ".join(str(x) for x in bp))
assert bp[0] == 0                              # the transient start gets share 0
assert vecmat(bp, BOARD) == bp                 # includes the balance equation that was swapped out
TRY = [[Fr(x, 10) for x in row] for row in ([6, 3, 1], [4, 4, 2], [2, 3, 5])]
print("try, rain stays with 0.5 (rainy row 0.2, 0.3, 0.5): " + ", ".join(str(x) for x in balance(TRY)) + f"; rain returns every {mean_return(TRY, 2)} days")
r = [40 * (float(x) / 0.5) ** 0.5 for x in pi]
print("figure, circle radius 40 sqrt(share / 0.5): " + ", ".join(f"{NAMES[i]} {r[i]:.2f}" for i in range(3)) + "; centres (80, 160), (280, 160), (180, 62)")
print("ALL CHECKS PASS")
```

**Ran 2026-10-07 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
table P, rows today sunny, cloudy, rainy: 0.6, 0.3, 0.1; 0.4, 0.4, 0.2; 0.4, 0.3, 0.3
road 1, balance equations: sunny 1/2, cloudy 1/3, rainy 1/6
road 2, mean days between visits: sunny 2, cloudy 3, rainy 6
road 2, one over those: sunny 1/2, cloudy 1/3, rainy 1/6
hand, sunny: pi_S = pi_C + pi_R and sum 1 give pi_S = 1/2
hand, rainy: 0.7 pi_R = 0.1 (1/2) + 0.2 (1/2 - pi_R), so 0.9 pi_R = 0.15, pi_R = 1/6
hand, spare cloudy equation: 0.1500 + 0.1333 + 0.0500 = 1/3
rainy days in a 365-day year: 60.83
excursion from rain, expected days of each kind, pi times m_R: 3, 2, 1
detailed balance fails: pi_S p_SR = 0.0500, pi_R p_RS = 0.0667
flow, out of rainy per day: 7/60; into rainy: 7/60
figure, rainy days per 100, running, days 10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000: 0.00, 10.00, 13.00, 15.33, 15.40, 16.27, 16.53, 16.90, 16.86; exact 16.67
road 3, simulated shares of 100000 days: sunny 0.4971 +- 0.0018, cloudy 0.3343 +- 0.0016, rainy 0.1686 +- 0.0015
road 3, rainy share 0.1686 +- 0.0015 (100 blocks of 1000 days); naive iid s.e. 0.0012
road 3, rainy days 16857, days per rainy day, simulated: 5.93 +- 0.05; exact mean return 6
forecast, chance of rain n days after a sunny day, n = 1, 2, 3, 5, 10: 0.1000, 0.1500, 0.1630, 0.1665, 0.1667
mistake, column convention P x = x: rainy 1/3 (uniform, since rows sum to 1)
mistake, average of the rain column: 1/5
mistake, rain after rain read as the share: 3/10
rota sunny -> cloudy -> rainy -> sunny: stationary 1/3, 1/3, 1/3
figure, rota, chance of rain on day n (per 100), n = 1..12: 0.00, 100.00, 0.00, 0.00, 100.00, 0.00, 0.00, 100.00, 0.00, 0.00, 100.00, 0.00
figure, rota, rainy days per 100 up to day n, n = 1..12: 0.00, 50.00, 33.33, 25.00, 40.00, 33.33, 28.57, 37.50, 33.33, 30.00, 36.36, 33.33
split climate (rain stays, dry stays dry): stationary (1/2, 1/2, 0) and (0, 0, 1); rainy share 0 or 1
one closed class plus a transient start (classifying-states' board, S A B C J): stationary 0, 1/6, 1/9, 1/18, 2/3
try, rain stays with 0.5 (rainy row 0.2, 0.3, 0.5): 4/9, 1/3, 2/9; rain returns every 9/2 days
figure, circle radius 40 sqrt(share / 0.5): sunny 40.00, cloudy 32.66, rainy 23.09; centres (80, 160), (280, 160), (180, 62)
ALL CHECKS PASS
```

### Rust

```rust
// Stationary distributions -- the check behind the card.  std only.
// A town's days are sunny, cloudy or rainy; tomorrow depends only on today.
// Three roads to the long-run share of each kind of day: the balance equations
// solved exactly; mean return times from first-step equations (share = 1/return
// time); and 100000 simulated days, with a standard error from blocks of days.
use std::fmt;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128); // exact fraction, numerator / denominator, kept in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) }
    }
}
fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
type M = Vec<Vec<Q>>;
const NAMES: [&str; 3] = ["sunny", "cloudy", "rainy"];
const TENTHS: [[i128; 3]; 3] = [[6, 3, 1], [4, 4, 2], [4, 3, 3]]; // row = today, column = tomorrow

fn solve(a: &M, b: &[Q]) -> Vec<Q> { // exact Gaussian elimination
    let n = a.len();
    let mut m: M = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let piv = (c..n).find(|&r| m[r][c].0 != 0).unwrap();
        m.swap(c, piv);
        for r in 0..n {
            if r != c && m[r][c].0 != 0 {
                let f = m[r][c] / m[c][c];
                for k in 0..=n { m[r][k] = m[r][k] - f * m[c][k]; }
            }
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}
fn eye(i: usize, j: usize) -> Q { if i == j { q(1, 1) } else { q(0, 1) } }
fn balance(p: &M, left: bool) -> Vec<Q> { // pi P = pi (left) or P x = x (right), sum 1
    let n = p.len();
    let mut a: M = (0..n).map(|j| (0..n).map(|i| (if left { p[i][j] } else { p[j][i] }) - eye(i, j)).collect()).collect();
    a[n - 1] = vec![q(1, 1); n]; // one balance equation is spare: swap in the total
    let mut b = vec![q(0, 1); n];
    b[n - 1] = q(1, 1);
    solve(&a, &b)
}
fn mean_return(p: &M, j: usize) -> Q { // first-step equations for days until j
    let others: Vec<usize> = (0..p.len()).filter(|&i| i != j).collect();
    let a: M = others.iter().map(|&x| others.iter().map(|&y| eye(x, y) - p[x][y]).collect()).collect();
    let h = solve(&a, &vec![q(1, 1); others.len()]);
    others.iter().zip(h.iter()).fold(q(1, 1), |s, (&k, &hk)| s + p[j][k] * hk)
}
fn vecmat(v: &[Q], p: &M) -> Vec<Q> {
    (0..p[0].len()).map(|j| (0..v.len()).fold(q(0, 1), |s, i| s + v[i] * p[i][j])).collect()
}
struct SplitMix64(u64);
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn step(g: &mut SplitMix64, today: usize) -> usize {
    let (u, mut acc) = (g.uniform(), 0);
    for j in 0..3 {
        acc += TENTHS[today][j];
        if u < acc as f64 / 10.0 { return j; }
    }
    2
}
fn join<T: fmt::Display>(v: &[T]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn f2(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let p: M = TENTHS.iter().map(|r| r.iter().map(|&x| q(x, 10)).collect()).collect();
    let (days, blocks, seed) = (100000usize, 100usize, 20260929u64);
    let pi = balance(&p, true);
    println!("table P, rows today sunny, cloudy, rainy: {}", p.iter().map(|r| r.iter().map(|&x| format!("{:.1}", fl(x))).collect::<Vec<_>>().join(", ")).collect::<Vec<_>>().join("; "));
    println!("road 1, balance equations: {}", (0..3).map(|i| format!("{} {}", NAMES[i], pi[i])).collect::<Vec<_>>().join(", "));
    let m: Vec<Q> = (0..3).map(|j| mean_return(&p, j)).collect();
    println!("road 2, mean days between visits: {}", (0..3).map(|j| format!("{} {}", NAMES[j], m[j])).collect::<Vec<_>>().join(", "));
    println!("road 2, one over those: {}", (0..3).map(|j| format!("{} {}", NAMES[j], q(1, 1) / m[j])).collect::<Vec<_>>().join(", "));
    assert!((0..3).all(|j| q(1, 1) / m[j] == pi[j])); // two exact roads agree
    assert_eq!(vecmat(&pi, &p), pi); // includes the balance equation that was swapped out
    println!("hand, sunny: pi_S = pi_C + pi_R and sum 1 give pi_S = {}", pi[0]);
    let pr = (p[0][2] * pi[0] + p[1][2] * (q(1, 1) - pi[0])) / (q(1, 1) - p[2][2] + p[1][2]); // rainy balance, pi_C = 1/2 - pi_R
    assert_eq!(pr, pi[2]); // the hand route lands on road 1
    println!("hand, rainy: 0.7 pi_R = 0.1 (1/2) + 0.2 (1/2 - pi_R), so 0.9 pi_R = 0.15, pi_R = {}", pr);
    println!("hand, spare cloudy equation: {:.4} + {:.4} + {:.4} = {}", fl(pi[0] * p[0][1]), fl(pi[1] * p[1][1]), fl(pi[2] * p[2][1]), vecmat(&pi, &p)[1]);
    println!("rainy days in a 365-day year: {:.2}", fl(q(365, 1) * pi[2]));
    println!("excursion from rain, expected days of each kind, pi times m_R: {}", join(&pi.iter().map(|&x| x * m[2]).collect::<Vec<_>>()));
    println!("detailed balance fails: pi_S p_SR = {:.4}, pi_R p_RS = {:.4}", fl(pi[0] * p[0][2]), fl(pi[2] * p[2][0]));
    println!("flow, out of rainy per day: {}; into rainy: {}", pi[2] * (q(1, 1) - p[2][2]), pi[0] * p[0][2] + pi[1] * p[1][2]);

    let (mut g, mut today, mut counts, mut blk, mut cur) = (SplitMix64(seed), 0usize, [0usize; 3], Vec::new(), [0usize; 3]);
    let marks = [10usize, 30, 100, 300, 1000, 3000, 10000, 30000, 100000];
    let mut running = Vec::new();
    for d in 1..=days { // day 0 is sunny; count days 1 .. days
        today = step(&mut g, today);
        counts[today] += 1;
        cur[today] += 1;
        if d % (days / blocks) == 0 { blk.push(cur); cur = [0; 3]; }
        if marks.contains(&d) { running.push(100.0 * counts[2] as f64 / d as f64); }
    }
    println!("figure, rainy days per 100, running, days {}: {}; exact {:.2}", join(&marks), f2(&running), 100.0 * fl(pi[2]));
    let frac: Vec<f64> = counts.iter().map(|&c| c as f64 / days as f64).collect();
    let bs = (days / blocks) as f64;
    let ses: Vec<f64> = (0..3).map(|i| (blk.iter().map(|b| (b[i] as f64 / bs - frac[i]).powi(2)).sum::<f64>() / (blocks - 1) as f64 / blocks as f64).sqrt()).collect();
    let se = ses[2];
    let naive = (frac[2] * (1.0 - frac[2]) / days as f64).sqrt();
    println!("road 3, simulated shares of 100000 days: {}", (0..3).map(|i| format!("{} {:.4} +- {:.4}", NAMES[i], frac[i], ses[i])).collect::<Vec<_>>().join(", "));
    println!("road 3, rainy share {:.4} +- {:.4} (100 blocks of 1000 days); naive iid s.e. {:.4}", frac[2], se, naive);
    println!("road 3, rainy days {}, days per rainy day, simulated: {:.2} +- {:.2}; exact mean return {}", counts[2], days as f64 / counts[2] as f64, se / frac[2].powi(2), m[2]);
    assert!((0..3).all(|i| (frac[i] - fl(pi[i])).abs() < 4.0 * ses[i])); // simulation against the exact shares

    let pf: Vec<Vec<f64>> = p.iter().map(|r| r.iter().map(|&x| fl(x)).collect()).collect();
    let (mut v, mut fc) = (vec![1.0f64, 0.0, 0.0], vec![0.0f64; 61]);
    for n in 1..=60 {
        v = (0..3).map(|j| (0..3).map(|i| v[i] * pf[i][j]).sum()).collect();
        fc[n] = v[2];
    }
    println!("forecast, chance of rain n days after a sunny day, n = 1, 2, 3, 5, 10: {}", [1, 2, 3, 5, 10].iter().map(|&n| format!("{:.4}", fc[n])).collect::<Vec<_>>().join(", "));
    assert!((fc[60] - fl(pi[2])).abs() < 1e-12); // this chain's forecasts settle (next card: why)

    println!("mistake, column convention P x = x: rainy {} (uniform, since rows sum to 1)", balance(&p, false)[2]);
    println!("mistake, average of the rain column: {}", (p[0][2] + p[1][2] + p[2][2]) / q(3, 1));
    println!("mistake, rain after rain read as the share: {}", p[2][2]);
    let (o, z) = (q(1, 1), q(0, 1));
    let rota: M = vec![vec![z, o, z], vec![z, z, o], vec![o, z, z]];
    let rp = balance(&rota, true);
    println!("rota sunny -> cloudy -> rainy -> sunny: stationary {}", join(&rp));
    let (mut v, mut st, mut seen, mut fcr, mut frr) = (vec![o, z, z], 0usize, 0usize, Vec::new(), Vec::new());
    for n in 1..=12 {
        v = vecmat(&v, &rota);
        st = (st + 1) % 3;
        if st == 2 { seen += 1; }
        fcr.push(100.0 * fl(v[2]));
        frr.push(100.0 * seen as f64 / n as f64);
    }
    println!("figure, rota, chance of rain on day n (per 100), n = 1..12: {}", f2(&fcr));
    println!("figure, rota, rainy days per 100 up to day n, n = 1..12: {}", f2(&frr));
    assert!(fcr[9] == 0.0 && fcr[10] == 100.0); // day 10 dry for sure, day 11 wet for sure: no settling
    assert!((frr[11] - 100.0 * fl(rp[2])).abs() < 1e-9); // yet the share of rainy days is the stationary 1/3
    let h = q(1, 2);
    let split: M = vec![vec![h, h, z], vec![h, h, z], vec![z, z, o]];
    let (a, b) = (vec![h, h, z], vec![z, z, o]);
    assert!(vecmat(&a, &split) == a && vecmat(&b, &split) == b);
    println!("split climate (rain stays, dry stays dry): stationary (1/2, 1/2, 0) and (0, 0, 1); rainy share 0 or 1");
    let s6 = q(1, 6); // classifying-states' board: start S, ring A, B, C, jail J
    let board: M = vec![vec![o - s6, s6, z, z, z], vec![z, z, h, z, h], vec![z, h, z, h, z], vec![z, z, h, z, h], vec![z, s6, z, z, o - s6]];
    let bp = balance(&board, true);
    println!("one closed class plus a transient start (classifying-states' board, S A B C J): stationary {}", join(&bp));
    assert!(bp[0] == z); // the transient start gets share 0
    assert_eq!(vecmat(&bp, &board), bp); // includes the balance equation that was swapped out
    let tr: M = [[6, 3, 1], [4, 4, 2], [2, 3, 5]].iter().map(|r| r.iter().map(|&x| q(x, 10)).collect()).collect();
    println!("try, rain stays with 0.5 (rainy row 0.2, 0.3, 0.5): {}; rain returns every {} days", join(&balance(&tr, true)), mean_return(&tr, 2));
    let r: Vec<f64> = pi.iter().map(|&x| 40.0 * (fl(x) / 0.5).sqrt()).collect();
    println!("figure, circle radius 40 sqrt(share / 0.5): {}; centres (80, 160), (280, 160), (180, 62)", (0..3).map(|i| format!("{} {:.2}", NAMES[i], r[i])).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-10-07 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
table P, rows today sunny, cloudy, rainy: 0.6, 0.3, 0.1; 0.4, 0.4, 0.2; 0.4, 0.3, 0.3
road 1, balance equations: sunny 1/2, cloudy 1/3, rainy 1/6
road 2, mean days between visits: sunny 2, cloudy 3, rainy 6
road 2, one over those: sunny 1/2, cloudy 1/3, rainy 1/6
hand, sunny: pi_S = pi_C + pi_R and sum 1 give pi_S = 1/2
hand, rainy: 0.7 pi_R = 0.1 (1/2) + 0.2 (1/2 - pi_R), so 0.9 pi_R = 0.15, pi_R = 1/6
hand, spare cloudy equation: 0.1500 + 0.1333 + 0.0500 = 1/3
rainy days in a 365-day year: 60.83
excursion from rain, expected days of each kind, pi times m_R: 3, 2, 1
detailed balance fails: pi_S p_SR = 0.0500, pi_R p_RS = 0.0667
flow, out of rainy per day: 7/60; into rainy: 7/60
figure, rainy days per 100, running, days 10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000: 0.00, 10.00, 13.00, 15.33, 15.40, 16.27, 16.53, 16.90, 16.86; exact 16.67
road 3, simulated shares of 100000 days: sunny 0.4971 +- 0.0018, cloudy 0.3343 +- 0.0016, rainy 0.1686 +- 0.0015
road 3, rainy share 0.1686 +- 0.0015 (100 blocks of 1000 days); naive iid s.e. 0.0012
road 3, rainy days 16857, days per rainy day, simulated: 5.93 +- 0.05; exact mean return 6
forecast, chance of rain n days after a sunny day, n = 1, 2, 3, 5, 10: 0.1000, 0.1500, 0.1630, 0.1665, 0.1667
mistake, column convention P x = x: rainy 1/3 (uniform, since rows sum to 1)
mistake, average of the rain column: 1/5
mistake, rain after rain read as the share: 3/10
rota sunny -> cloudy -> rainy -> sunny: stationary 1/3, 1/3, 1/3
figure, rota, chance of rain on day n (per 100), n = 1..12: 0.00, 100.00, 0.00, 0.00, 100.00, 0.00, 0.00, 100.00, 0.00, 0.00, 100.00, 0.00
figure, rota, rainy days per 100 up to day n, n = 1..12: 0.00, 50.00, 33.33, 25.00, 40.00, 33.33, 28.57, 37.50, 33.33, 30.00, 36.36, 33.33
split climate (rain stays, dry stays dry): stationary (1/2, 1/2, 0) and (0, 0, 1); rainy share 0 or 1
one closed class plus a transient start (classifying-states' board, S A B C J): stationary 0, 1/6, 1/9, 1/18, 2/3
try, rain stays with 0.5 (rainy row 0.2, 0.3, 0.5): 4/9, 1/3, 2/9; rain returns every 9/2 days
figure, circle radius 40 sqrt(share / 0.5): sunny 40.00, cloudy 32.66, rainy 23.09; centres (80, 160), (280, 160), (180, 62)
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves existence, uniqueness and the long-run time fractions for every finite chain, and checks the card's exact numbers.

- Every chain on finitely many states has at least one stationary distribution.
- Suppose the chain is also irreducible. Then it has exactly one stationary distribution.
- Suppose an irreducible chain uses the same table every day, and tomorrow depends on today only. Then, from any first day, with probability 1 the fraction of $j$-days among days 1 to $n$ tends to $\pi_j$.
- Take the town's table. Then (1/2, 1/3, 1/6) is its stationary distribution, and every state reaches every other in one day.
- The hand solution, the spare cloudy equation and the flows of 7/60 check out in exact fractions. So does the failure of detailed balance.
- Take the rota. Then (1/3, 1/3, 1/3) is its stationary distribution.
- Take the rota from a sunny day. Then the chance of rain is 0 on day 10 and 1 on day 11.
- Take the split climate. Then (1/2, 1/2, 0) and (0, 0, 1) both balance it.
- Take the town's table. Then the column of ones solves $P x = x$, and averaging the rain column gives 1/5, not 1/6.

The mean return times, the positive entries and the 100,000-day simulation are left to the Python and Rust checks.

```lean
-- Stationary distributions: every finite Markov chain has a mix of chances that one more step leaves unchanged, an irreducible one has exactly one, and its entries are the long-run fractions of days spent in each state.
import Mathlib.LinearAlgebra.Matrix.Stochastic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib

namespace StationaryDistributions

open Matrix MeasureTheory Filter Topology

/-! Setting. The states are a finite, non-empty type `ι` (the card's states 1 to `N`). The
transition matrix `P` is row-stochastic: `P i j ≥ 0` is the chance tomorrow is `j` given today is
`i`, and each row adds to 1 (Mathlib's `Matrix.rowStochastic`). A mix of chances is a row
`π : ι → R`; `π ᵥ* P` is tomorrow's mix when today's is `π`. -/

/-- A **stationary distribution** of `P`: a row with no negative entries and total 1 that one
more step hands back unchanged, `π P = π` (the balance equations). -/
def IsStationaryDistribution {R ι : Type*} [Fintype ι] [Semiring R] [PartialOrder R]
    (P : Matrix ι ι R) (π : ι → R) : Prop :=
  (∀ j, 0 ≤ π j) ∧ ∑ j, π j = 1 ∧ π ᵥ* P = π

/-- The chain is **irreducible**: every state can reach every other, i.e. for all states `i`, `j`
some number of steps `n` takes `i` to `j` with positive chance, `(P^n) i j > 0`. -/
def Irreducible {R ι : Type*} [Fintype ι] [DecidableEq ι] [Semiring R] [PartialOrder R]
    (P : Matrix ι ι R) : Prop :=
  ∀ i j, ∃ n : ℕ, 0 < (P ^ n) i j

/-- Maximum principle: on an irreducible chain, a function with `P h = h` is constant. -/
lemma harmonic_const {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    (h : ι → ℝ) (hh : P *ᵥ h = h) : h = fun _ => h (Classical.arbitrary ι) := by
  obtain ⟨i0, hi0⟩ := Finite.exists_max h
  have step : ∀ m k, h m = h i0 → 0 < P m k → h k = h i0 := by
    intro m k hm hmk
    have e1 : ∑ l, P m l * h l = h m := by
      have := congrFun hh m; simpa [mulVec, dotProduct] using this
    have e2 : ∑ l, P m l = 1 := sum_row_of_mem_rowStochastic hP m
    have hsum : ∑ l, P m l * (h i0 - h l) = 0 := by
      simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, e1, e2, hm]; ring
    have hnn : ∀ l ∈ Finset.univ, 0 ≤ P m l * (h i0 - h l) := fun l _ =>
      mul_nonneg (hP.1 m l) (sub_nonneg.2 (hi0 l))
    have := (Finset.sum_eq_zero_iff_of_nonneg hnn).1 hsum k (Finset.mem_univ _)
    rcases mul_eq_zero.1 this with h1 | h1
    · exact absurd h1 hmk.ne'
    · linarith
  have reach : ∀ n k, 0 < (P ^ n) i0 k → h k = h i0 := by
    intro n
    induction n with
    | zero =>
      intro k hk
      by_cases hik : i0 = k
      · rw [hik]
      · simp [hik] at hk
    | succ n ih =>
      intro k hk
      rw [pow_succ, Matrix.mul_apply] at hk
      by_contra hne
      have hle : ∀ m ∈ Finset.univ, (P ^ n) i0 m * P m k ≤ 0 := by
        intro m _
        by_contra hpos'
        have hpos := not_le.1 hpos'
        have ha : 0 ≤ (P ^ n) i0 m := (pow_mem hP n).1 i0 m
        have hb : 0 ≤ P m k := hP.1 m k
        have ha' : 0 < (P ^ n) i0 m := lt_of_le_of_ne ha (fun e => by
          rw [← e, zero_mul] at hpos; exact lt_irrefl _ hpos)
        have hb' : 0 < P m k := lt_of_le_of_ne hb (fun e => by
          rw [← e, mul_zero] at hpos; exact lt_irrefl _ hpos)
        exact hne (step m k (ih m ha') hb')
      linarith [Finset.sum_nonpos hle]
  have hc : ∀ k, h k = h i0 := fun k => by
    obtain ⟨n, hn⟩ := hirr i0 k; exact reach n k hn
  funext k; rw [hc k, hc (Classical.arbitrary ι)]

/-- For an irreducible chain, the kernel of `1 - P` acting on columns is one-dimensional. -/
lemma finrank_ker_one_sub {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P) :
    Module.finrank ℝ (LinearMap.ker (1 - P).mulVecLin) = 1 := by
  have hmem : (fun _ : ι => (1 : ℝ)) ∈ LinearMap.ker (1 - P).mulVecLin := by
    rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, sub_mulVec, one_mulVec]
    have := one_vecMul_of_mem_rowStochastic hP
    rw [sub_eq_zero]; exact this.symm
  have hne : (⟨fun _ => 1, hmem⟩ : LinearMap.ker (1 - P).mulVecLin) ≠ 0 := by
    intro e
    have := congrFun (congrArg Subtype.val e) (Classical.arbitrary ι)
    simp at this
  rw [finrank_eq_one_iff_of_ne_zero' _ hne]
  rintro ⟨w, hw⟩
  rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, sub_mulVec, one_mulVec, sub_eq_zero] at hw
  have := harmonic_const hP hirr w hw.symm
  refine ⟨w (Classical.arbitrary ι), ?_⟩
  ext k
  simp only [SetLike.mk_smul_mk]
  rw [this]; simp

lemma rank_one_sub {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P) :
    (1 - P).rank + 1 = Fintype.card ι := by
  have := LinearMap.finrank_range_add_finrank_ker (1 - P).mulVecLin
  rw [finrank_ker_one_sub hP hirr, Module.finrank_fintype_fun_eq_card] at this
  exact this

/-- Existence of a stationary distribution for any finite row-stochastic matrix. -/
lemma exists_stationary {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) :
    ∃ π : ι → ℝ, IsStationaryDistribution P π := by
  have hdet : (1 - P).det = 0 := by
    rw [← Matrix.exists_mulVec_eq_zero_iff]
    refine ⟨fun _ => 1, ?_, ?_⟩
    · intro e; have := congrFun e (Classical.arbitrary ι); simp at this
    · rw [sub_mulVec, one_mulVec]
      have := one_vecMul_of_mem_rowStochastic hP
      rw [sub_eq_zero]; exact this.symm
  rw [← Matrix.exists_vecMul_eq_zero_iff] at hdet
  obtain ⟨v, hv0, hv⟩ := hdet
  rw [vecMul_sub, vecMul_one, sub_eq_zero] at hv
  -- hv : v = v ᵥ* P
  set u : ι → ℝ := fun i => |v i| with hu
  have hge : ∀ j, u j ≤ (u ᵥ* P) j := by
    intro j
    have e : v j = ∑ i, v i * P i j := by
      conv_lhs => rw [hv]
      simp [vecMul, dotProduct]
    simp only [hu, vecMul, dotProduct]
    rw [e]
    refine (Finset.abs_sum_le_sum_abs _ _).trans (le_of_eq ?_)
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [abs_mul, abs_of_nonneg (hP.1 i j)]
  have hsumeq : ∑ j, (u ᵥ* P) j = ∑ j, u j := by
    simp only [vecMul, dotProduct]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Finset.mul_sum, sum_row_of_mem_rowStochastic hP i, mul_one]
  have hfix : ∀ j, (u ᵥ* P) j = u j := by
    have h0 : ∑ j, ((u ᵥ* P) j - u j) = 0 := by
      rw [Finset.sum_sub_distrib, hsumeq, sub_self]
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sub_nonneg.2 (hge j))).1 h0
    intro j; have := this j (Finset.mem_univ _); linarith
  obtain ⟨i1, hi1⟩ : ∃ i, v i ≠ 0 := by
    by_contra hcon; exact hv0 (funext fun i => not_not.1 fun hi => hcon ⟨i, hi⟩)
  have hspos : 0 < ∑ j, u j := by
    have : u i1 ≤ ∑ j, u j :=
      Finset.single_le_sum (fun j _ => abs_nonneg (v j)) (Finset.mem_univ i1)
    have : 0 < u i1 := abs_pos.2 hi1
    linarith
  refine ⟨fun i => u i / ∑ j, u j, ?_, ?_, ?_⟩
  · intro j; exact div_nonneg (abs_nonneg _) hspos.le
  · rw [← Finset.sum_div]; exact div_self hspos.ne'
  · funext j
    have := hfix j
    simp only [vecMul, dotProduct] at this ⊢
    simp_rw [div_mul_eq_mul_div]
    rw [← Finset.sum_div, this]

/-- Uniqueness: two stationary distributions of an irreducible chain agree. -/
lemma stationary_unique {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    {π π' : ι → ℝ} (h1 : IsStationaryDistribution P π) (h2 : IsStationaryDistribution P π') :
    π' = π := by
  have hrk := rank_one_sub hP hirr
  have hker := LinearMap.finrank_range_add_finrank_ker (1 - P)ᵀ.mulVecLin
  rw [Module.finrank_fintype_fun_eq_card] at hker
  have hrkT : Module.finrank ℝ (LinearMap.range (1 - P)ᵀ.mulVecLin) = (1 - P).rank := by
    rw [← Matrix.rank_transpose]; rfl
  have hk1 : Module.finrank ℝ (LinearMap.ker (1 - P)ᵀ.mulVecLin) = 1 := by omega
  have mem : ∀ ρ : ι → ℝ, IsStationaryDistribution P ρ → ρ ∈ LinearMap.ker (1 - P)ᵀ.mulVecLin := by
    intro ρ hρ
    rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, mulVec_transpose, vecMul_sub, vecMul_one,
      hρ.2.2, sub_self]
  have hne : (⟨π, mem π h1⟩ : LinearMap.ker (1 - P)ᵀ.mulVecLin) ≠ 0 := by
    intro e
    have := congrArg Subtype.val e
    have hs := h1.2.1
    simp only [ZeroMemClass.coe_zero] at this
    rw [this] at hs; simp at hs
  obtain ⟨c, hc⟩ := (finrank_eq_one_iff_of_ne_zero' _ hne).1 hk1 ⟨π', mem π' h2⟩
  have hc' : c • π = π' := congrArg Subtype.val hc
  have : c = 1 := by
    have := congrArg (fun ρ : ι → ℝ => ∑ j, ρ j) hc'
    simp only [Pi.smul_apply, smul_eq_mul, ← Finset.mul_sum, h1.2.1, h2.2.1, mul_one] at this
    exact this
  rw [← hc', this, one_smul]

/-- Poisson equation: if `π ⬝ f = 0` then `f = (1 - P) g` for some `g`. -/
lemma poisson {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    {π : ι → ℝ} (hπ : IsStationaryDistribution P π) (f : ι → ℝ) (hf : π ⬝ᵥ f = 0) :
    ∃ g : ι → ℝ, (1 - P) *ᵥ g = f := by
  let φ : (ι → ℝ) →ₗ[ℝ] ℝ :=
    { toFun := fun x => π ⬝ᵥ x
      map_add' := fun x y => dotProduct_add π x y
      map_smul' := fun c x => by simp [dotProduct_smul] }
  have hsurj : LinearMap.range φ = ⊤ := by
    rw [LinearMap.range_eq_top]
    intro y
    refine ⟨fun _ => y, ?_⟩
    show π ⬝ᵥ (fun _ => y) = y
    simp only [dotProduct]
    rw [← Finset.sum_mul, hπ.2.1, one_mul]
  have hφ := LinearMap.finrank_range_add_finrank_ker φ
  rw [hsurj, finrank_top, Module.finrank_self, Module.finrank_fintype_fun_eq_card] at hφ
  have hrk := rank_one_sub hP hirr
  have hle : LinearMap.range (1 - P).mulVecLin ≤ LinearMap.ker φ := by
    rintro _ ⟨g, rfl⟩
    rw [LinearMap.mem_ker]
    show π ⬝ᵥ ((1 - P) *ᵥ g) = 0
    rw [dotProduct_mulVec, vecMul_sub, vecMul_one, hπ.2.2, sub_self, zero_dotProduct]
  have heq := Submodule.eq_of_le_of_finrank_eq hle (by
    show (1 - P).rank = _
    omega)
  have hfm : f ∈ LinearMap.ker φ := hf
  rw [← heq] at hfm
  obtain ⟨g, hg⟩ := hfm
  exact ⟨g, hg⟩


/-- The first `n + 1` states of a run, as a tuple. -/
def pathOf {ι Ω : Type*} (X : ℕ → Ω → ι) (n : ℕ) (ω : Ω) : Fin (n + 1) → ι := fun k => X k ω

lemma measurableSet_path {ι Ω : Type*} [MeasurableSpace Ω] (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i}) (n : ℕ) (t : Fin (n + 1) → ι) :
    MeasurableSet {ω | pathOf X n ω = t} := by
  have : {ω | pathOf X n ω = t} = ⋂ k : Fin (n + 1), {ω | X k ω = t k} := by
    ext ω; simp [pathOf, funext_iff]
  rw [this]; exact MeasurableSet.iInter fun k => hX _ _

lemma measureReal_path_pred {ι Ω : Type*} [Fintype ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsFiniteMeasure μ] (X : ℕ → Ω → ι) (hX : ∀ n i, MeasurableSet {ω | X n ω = i}) (n : ℕ)
    (Q : (Fin (n + 1) → ι) → Prop) [DecidablePred Q] :
    μ.real {ω | Q (pathOf X n ω)} =
      ∑ t ∈ Finset.univ.filter Q, μ.real {ω | pathOf X n ω = t} := by
  classical
  have : {ω | Q (pathOf X n ω)} = ⋃ t ∈ Finset.univ.filter Q, {ω | pathOf X n ω = t} := by
    ext ω; simp
  rw [this, measureReal_biUnion_finset]
  · intro t _ t' _ htt'
    refine Set.disjoint_left.2 fun ω h1 h2 => htt' ?_
    simp only [Set.mem_ofPred_eq] at h1 h2
    rw [← h1, ← h2]
  · intro t _; exact measurableSet_path X hX n t

lemma sum_measureReal_path {ι Ω : Type*} [Fintype ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ι) (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (n : ℕ) : ∑ t, μ.real {ω | pathOf X n ω = t} = 1 := by
  classical
  have := measureReal_path_pred μ X hX n (fun _ => True)
  simpa using this.symm

lemma measureReal_path_snoc {ι Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (P : Matrix ι ι ℝ) (X : ℕ → Ω → ι)
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (n : ℕ) (t : Fin (n + 1) → ι) (b : ι) :
    μ.real {ω | pathOf X (n + 1) ω = Fin.snoc t b} =
      μ.real {ω | pathOf X n ω = t} * P (t (Fin.last n)) b := by
  let s : ℕ → ι := fun k => if h : k < n + 2 then (Fin.snoc t b : Fin (n + 2) → ι) ⟨k, h⟩ else b
  have hs1 : ∀ k (hk : k < n + 1), s k = t ⟨k, hk⟩ := by
    intro k hk
    simp [s, show k < n + 2 by omega, Fin.snoc, show k ≤ n by omega]
  have hs2 : s (n + 1) = b := by simp [s, Fin.snoc]
  have h1 : {ω | pathOf X (n + 1) ω = Fin.snoc t b} = {ω | ∀ k ≤ n + 1, X k ω = s k} := by
    ext ω
    simp only [Set.mem_ofPred_eq, funext_iff, pathOf]
    constructor
    · intro h k hk
      have := h ⟨k, by omega⟩
      simp only [s, (show k < n + 2 by omega), ↓reduceDIte]
      exact this
    · intro h k
      have := h k (by omega)
      simp only [s, k.isLt, ↓reduceDIte] at this
      exact this
  have h2 : {ω | pathOf X n ω = t} = {ω | ∀ k ≤ n, X k ω = s k} := by
    ext ω
    simp only [Set.mem_ofPred_eq, funext_iff, pathOf]
    constructor
    · intro h k hk
      rw [hs1 k (by omega)]; exact h ⟨k, by omega⟩
    · intro h k
      have := h k (by omega)
      rw [hs1 k k.isLt] at this; exact this
  rw [h1, h2, hMarkov n s, hs2, hs1 n (by omega)]
  rfl

lemma sum_snoc {ι : Type*} [Fintype ι] {n : ℕ} (F : (Fin (n + 2) → ι) → ℝ) :
    ∑ t', F t' = ∑ t : Fin (n + 1) → ι, ∑ b, F (Fin.snoc t b) := by
  rw [← (Fin.snocEquiv (fun _ => ι)).sum_comp, Fintype.sum_prod_type_right]
  simp [Fin.snocEquiv_apply]

/-- The martingale part along a tuple of states. -/
def martPart {ι : Type*} (D : ι → ι → ℝ) (n : ℕ) (t : Fin (n + 1) → ι) : ℝ :=
  ∑ k : Fin n, D (t k.castSucc) (t k.succ)

lemma martPart_snoc {ι : Type*} (D : ι → ι → ℝ) (n : ℕ) (t : Fin (n + 1) → ι) (b : ι) :
    martPart D (n + 1) (Fin.snoc t b) = martPart D n t + D (t (Fin.last n)) b := by
  unfold martPart
  rw [Fin.sum_univ_castSucc]
  simp only [Fin.snoc_castSucc, Fin.succ_castSucc, Fin.succ_last, Fin.snoc_last]

lemma moment_step {ι Ω : Type*} [Fintype ι] [MeasurableSpace Ω] (μ : Measure Ω)
    (P : Matrix ι ι ℝ) (X : ℕ → Ω → ι)
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (Φ Ψ : ℝ → ℝ) (hΦ : ∀ a S, ∑ b, P a b * Φ (S + D a b) ≤ Ψ S) (n : ℕ) :
    ∑ t', μ.real {ω | pathOf X (n + 1) ω = t'} * Φ (martPart D (n + 1) t') ≤
      ∑ t, μ.real {ω | pathOf X n ω = t} * Ψ (martPart D n t) := by
  rw [sum_snoc]
  refine Finset.sum_le_sum fun t _ => ?_
  simp_rw [measureReal_path_snoc μ P X hMarkov, martPart_snoc, mul_assoc, ← Finset.mul_sum]
  exact mul_le_mul_of_nonneg_left (hΦ _ _) measureReal_nonneg

lemma inner_sq {ι : Type*} [Fintype ι] (q d : ι → ℝ) (hq : ∀ b, 0 ≤ q b) (hq1 : ∑ b, q b = 1)
    (hd0 : ∑ b, q b * d b = 0) (c : ℝ) (hc : ∀ b, |d b| ≤ c) (S : ℝ) :
    ∑ b, q b * (S + d b) ^ 2 ≤ S ^ 2 + c ^ 2 := by
  have hpt : ∀ b, q b * (S + d b) ^ 2 ≤ S ^ 2 * q b + 2 * S * (q b * d b) + c ^ 2 * q b := by
    intro b
    have h1 : d b ^ 2 ≤ c ^ 2 := by
      rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) (hc b) 2
    have : q b * d b ^ 2 ≤ q b * c ^ 2 := mul_le_mul_of_nonneg_left h1 (hq b)
    nlinarith
  refine (Finset.sum_le_sum fun b _ => hpt b).trans (le_of_eq ?_)
  rw [Finset.sum_add_distrib, Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum,
    ← Finset.mul_sum, hq1, hd0]
  ring

lemma inner_four {ι : Type*} [Fintype ι] (q d : ι → ℝ) (hq : ∀ b, 0 ≤ q b) (hq1 : ∑ b, q b = 1)
    (hd0 : ∑ b, q b * d b = 0) (c : ℝ) (hc : ∀ b, |d b| ≤ c) (S : ℝ) :
    ∑ b, q b * (S + d b) ^ 4 ≤ S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4 := by
  have hpt : ∀ b, q b * (S + d b) ^ 4 ≤
      (S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4) * q b + 4 * S ^ 3 * (q b * d b) := by
    intro b
    have hc0 : 0 ≤ c := (abs_nonneg _).trans (hc b)
    have h1 : d b ^ 2 ≤ c ^ 2 := by
      rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) (hc b) 2
    have h4 : d b ^ 4 ≤ c ^ 4 := by
      have : d b ^ 4 = (d b ^ 2) ^ 2 := by ring
      rw [this, show c ^ 4 = (c ^ 2) ^ 2 by ring]
      exact pow_le_pow_left₀ (sq_nonneg _) h1 2
    have h3 : S * d b ^ 3 ≤ |S| * c ^ 3 := by
      calc S * d b ^ 3 ≤ |S * d b ^ 3| := le_abs_self _
        _ = |S| * |d b| ^ 3 := by rw [abs_mul, abs_pow]
        _ ≤ |S| * c ^ 3 := mul_le_mul_of_nonneg_left
            (pow_le_pow_left₀ (abs_nonneg _) (hc b) 3) (abs_nonneg _)
    have h3' : 4 * (|S| * c ^ 3) ≤ 2 * c ^ 2 * S ^ 2 + 2 * c ^ 4 := by
      have : 0 ≤ 2 * c ^ 2 * (|S| - c) ^ 2 := by positivity
      have hS : |S| ^ 2 = S ^ 2 := sq_abs S
      nlinarith
    have h2 : S ^ 2 * d b ^ 2 ≤ S ^ 2 * c ^ 2 := mul_le_mul_of_nonneg_left h1 (sq_nonneg _)
    have key : (S + d b) ^ 4 ≤ S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4 + 4 * S ^ 3 * d b := by
      nlinarith
    have := mul_le_mul_of_nonneg_left key (hq b)
    nlinarith
  refine (Finset.sum_le_sum fun b _ => hpt b).trans (le_of_eq ?_)
  rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum, hq1, hd0]
  ring

lemma moment_bounds {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (hD0 : ∀ a, ∑ b, P a b * D a b = 0) (c : ℝ) (hc : ∀ a b, |D a b| ≤ c)
    (n : ℕ) :
    ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 2 ≤ c ^ 2 * n ∧
      ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4 ≤ 8 * c ^ 4 * n ^ 2 := by
  classical
  induction n with
  | zero => simp [martPart]
  | succ n ih =>
    have hq : ∀ a b, 0 ≤ P a b := hP.1
    have hq1 : ∀ a, ∑ b, P a b = 1 := sum_row_of_mem_rowStochastic hP
    have s2 := moment_step μ P X hMarkov D (fun x => x ^ 2) (fun S => S ^ 2 + c ^ 2)
      (fun a S => inner_sq (P a) (D a) (hq a) (hq1 a) (hD0 a) c (hc a) S) n
    have s4 := moment_step μ P X hMarkov D (fun x => x ^ 4)
      (fun S => S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4)
      (fun a S => inner_four (P a) (D a) (hq a) (hq1 a) (hD0 a) c (hc a) S) n
    have hw := sum_measureReal_path μ X hX n
    have e2 : ∑ t, μ.real {ω | pathOf X n ω = t} * (martPart D n t ^ 2 + c ^ 2) =
        ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 2 + c ^ 2 := by
      simp only [mul_add, Finset.sum_add_distrib, ← Finset.sum_mul, hw, one_mul]
    have e4 : ∑ t, μ.real {ω | pathOf X n ω = t} *
          (martPart D n t ^ 4 + 8 * c ^ 2 * martPart D n t ^ 2 + 3 * c ^ 4) =
        ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4 +
          8 * c ^ 2 * ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 2 + 3 * c ^ 4 := by
      simp only [mul_add, Finset.sum_add_distrib, ← Finset.sum_mul, hw, one_mul, Finset.mul_sum]
      congr 1
      · congr 1
        refine Finset.sum_congr rfl fun t _ => ?_
        ring
    rw [e2] at s2
    rw [e4] at s4
    obtain ⟨ih2, ih4⟩ := ih
    have hc2 : 0 ≤ c ^ 2 := sq_nonneg c
    push_cast
    have hc4 : 0 ≤ c ^ 4 := by positivity
    have hn0 : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    have h8 := mul_le_mul_of_nonneg_left ih2 (by positivity : (0 : ℝ) ≤ 8 * c ^ 2)
    have hcn : 0 ≤ c ^ 4 * (n : ℝ) := mul_nonneg hc4 hn0
    constructor
    · nlinarith
    · have : 8 * c ^ 2 * (c ^ 2 * (n : ℝ)) = 8 * (c ^ 4 * n) := by ring
      nlinarith

lemma tail_bound {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (hD0 : ∀ a, ∑ b, P a b * D a b = 0) (c : ℝ) (hc : ∀ a b, |D a b| ≤ c)
    (r n : ℕ) :
    ((n : ℝ) + 1) ^ 2 * μ.real {ω | (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n (pathOf X n ω)|} ≤
      1 + 32 * c ^ 4 * ((r : ℝ) + 1) ^ 4 := by
  classical
  set A := μ.real {ω | (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n (pathOf X n ω)|} with hA
  have hA0 : 0 ≤ A := measureReal_nonneg
  have hA1 : A ≤ 1 := measureReal_le_one
  have hK : 0 ≤ 32 * c ^ 4 * ((r : ℝ) + 1) ^ 4 := by positivity
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn; simp only [Nat.cast_zero, zero_add, one_pow, one_mul]; linarith
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hsum := measureReal_path_pred μ X hX n
    (fun t => (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n t|)
  rw [← hA] at hsum
  have h4 := (moment_bounds μ P hP X hX hMarkov D hD0 c hc n).2
  have hcheb : (n : ℝ) ^ 4 * A ≤ ((r : ℝ) + 1) ^ 4 * (8 * c ^ 4 * (n : ℝ) ^ 2) := by
    rw [hsum, Finset.mul_sum]
    calc ∑ t ∈ Finset.univ.filter (fun t => (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n t|),
          (n : ℝ) ^ 4 * μ.real {ω | pathOf X n ω = t}
        ≤ ∑ t ∈ Finset.univ.filter (fun t => (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n t|),
          ((r : ℝ) + 1) ^ 4 * (μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4) := by
          refine Finset.sum_le_sum fun t ht => ?_
          have ht' := (Finset.mem_filter.1 ht).2
          have hp : (n : ℝ) ^ 4 ≤ (((r : ℝ) + 1) * |martPart D n t|) ^ 4 :=
            pow_le_pow_left₀ (by positivity) ht' 4
          have habs : |martPart D n t| ^ 4 = martPart D n t ^ 4 := by
            calc |martPart D n t| ^ 4 = (|martPart D n t| ^ 2) ^ 2 := by ring
              _ = (martPart D n t ^ 2) ^ 2 := by rw [sq_abs]
              _ = martPart D n t ^ 4 := by ring
          rw [mul_pow, habs] at hp
          have hw0 : 0 ≤ μ.real {ω | pathOf X n ω = t} := measureReal_nonneg
          nlinarith
      _ ≤ ∑ t, ((r : ℝ) + 1) ^ 4 * (μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4) := by
          refine Finset.sum_le_sum_of_subset_of_nonneg (Finset.filter_subset _ _) fun t _ _ => ?_
          have hw0 : 0 ≤ μ.real {ω | pathOf X n ω = t} := measureReal_nonneg
          positivity
      _ ≤ ((r : ℝ) + 1) ^ 4 * (8 * c ^ 4 * (n : ℝ) ^ 2) := by
          rw [← Finset.mul_sum]
          exact mul_le_mul_of_nonneg_left h4 (by positivity)
  have hn2 : 0 < (n : ℝ) ^ 2 := by positivity
  have hA2 : (n : ℝ) ^ 2 * A ≤ 8 * c ^ 4 * ((r : ℝ) + 1) ^ 4 := by
    have : (n : ℝ) ^ 2 * ((n : ℝ) ^ 2 * A) ≤ (n : ℝ) ^ 2 * (8 * c ^ 4 * ((r : ℝ) + 1) ^ 4) := by
      nlinarith
    exact le_of_mul_le_mul_left this hn2
  have hsq : ((n : ℝ) + 1) ^ 2 ≤ 4 * (n : ℝ) ^ 2 := by nlinarith
  have := mul_le_mul_of_nonneg_right hsq hA0
  nlinarith

lemma ae_martPart_div {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (hD0 : ∀ a, ∑ b, P a b * D a b = 0) (c : ℝ) (hc : ∀ a b, |D a b| ≤ c) :
    ∀ᵐ ω ∂μ, Tendsto (fun n : ℕ => martPart D n (pathOf X n ω) / n) atTop (𝓝 0) := by
  have key : ∀ r : ℕ, ∀ᵐ ω ∂μ, ∀ᶠ n : ℕ in atTop,
      ω ∉ {ω | (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n (pathOf X n ω)|} := by
    intro r
    apply ae_eventually_notMem
    set C := 1 + 32 * c ^ 4 * ((r : ℝ) + 1) ^ 4 with hC
    have hC0 : 0 ≤ C := by positivity
    have hsum : Summable (fun n : ℕ => C / ((n : ℝ) + 1) ^ 2) := by
      have := ((summable_nat_add_iff 1).2
        (Real.summable_one_div_nat_pow.2 one_lt_two)).mul_left C
      refine this.congr fun n => ?_
      push_cast
      ring
    have hne : ∑' n : ℕ, ENNReal.ofReal (C / ((n : ℝ) + 1) ^ 2) ≠ ⊤ := by
      rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => by positivity) hsum]
      exact ENNReal.ofReal_ne_top
    refine ne_top_of_le_ne_top hne (tsum_le_tsum fun n => ?_)
    rw [← ofReal_measureReal]
    apply ENNReal.ofReal_le_ofReal
    rw [le_div_iff₀ (by positivity), mul_comm]
    exact tail_bound μ P hP X hX hMarkov D hD0 c hc r n
  filter_upwards [ae_all_iff.2 key] with ω hω
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨r, hr⟩ := exists_nat_one_div_lt hε
  obtain ⟨N, hN⟩ := eventually_atTop.1 (hω r)
  refine ⟨max N 1, fun n hn => ?_⟩
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast le_of_max_le_right hn
  have h := hN n (le_of_max_le_left hn)
  simp only [not_le] at h
  rw [Real.dist_eq, sub_zero, abs_div, Nat.abs_cast, div_lt_iff₀ (by linarith)]
  have hr' : 1 < ε * ((r : ℝ) + 1) := by
    rwa [div_lt_iff₀ (by positivity)] at hr
  have h1 := mul_lt_mul_of_pos_left h hε
  have h2 : 0 ≤ |martPart D n (pathOf X n ω)| := abs_nonneg _
  nlinarith

lemma count_eq_sum {ι Ω : Type*} [DecidableEq ι] (X : ℕ → Ω → ι) (ω : Ω) (j : ι) (n : ℕ) :
    ((((Finset.Icc 1 n).filter (fun k => X k ω = j)).card : ℕ) : ℝ) =
      ∑ k ∈ Finset.range n, if X (k + 1) ω = j then (1 : ℝ) else 0 := by
  rw [Finset.card_filter]
  push_cast
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_Icc_succ_top (by omega), Finset.sum_range_succ, ih]

#print axioms harmonic_const
#print axioms finrank_ker_one_sub
#print axioms rank_one_sub
#print axioms exists_stationary
#print axioms stationary_unique
#print axioms poisson
#print axioms measurableSet_path
#print axioms measureReal_path_pred
#print axioms sum_measureReal_path
#print axioms measureReal_path_snoc
#print axioms sum_snoc
#print axioms martPart_snoc
#print axioms moment_step
#print axioms inner_sq
#print axioms inner_four
#print axioms moment_bounds
#print axioms tail_bound
#print axioms ae_martPart_div
#print axioms count_eq_sum

/-- **Existence and uniqueness.** On a finite chain where every state can reach every other
(irreducible), there is exactly one stationary distribution: exactly one mix of chances over the
states, with no negative entries and total 1, that one more step leaves unchanged. -/
theorem irreducible_has_unique_stationary_distribution
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P) :
    ∃! π : ι → ℝ, IsStationaryDistribution P π := by
  obtain ⟨π, hπ⟩ := exists_stationary P hP
  exact ⟨π, hπ, fun π' h' => stationary_unique hP hirr hπ h'⟩

/-- **Existence needs no irreducibility.** Every chain on finitely many states has at least one
stationary distribution. -/
theorem finite_chain_has_stationary_distribution
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) :
    ∃ π : ι → ℝ, IsStationaryDistribution P π := by
  exact exists_stationary P hP

/-- **The stationary shares are the long-run time fractions.** Let `X 0, X 1, X 2, …` be a Markov
chain with the fixed table `P` on a finite irreducible state space, from any first day: on a
probability space `(Ω, μ)`, the chance of any run of states `s 0, …, s (n + 1)` is the chance of
`s 0, …, s n` times `P (s n) (s (n + 1))` (tomorrow depends on today only, by the same table
every day). Let `π` be its stationary distribution. Then for every state `j`, with probability 1
the fraction of days among days `1` to `n` that are `j` tends to `π j` as `n` grows. -/
theorem fraction_of_days_tends_to_stationary_share
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ι) (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (π : ι → ℝ) (hπ : IsStationaryDistribution P π) (j : ι) :
    ∀ᵐ ω ∂μ, Tendsto
      (fun n : ℕ => (((Finset.Icc 1 n).filter (fun k => X k ω = j)).card : ℝ) / n)
      atTop (𝓝 (π j)) := by
  classical
  set f : ι → ℝ := fun i => (if i = j then 1 else 0) - π j with hf
  have hfπ : π ⬝ᵥ f = 0 := by
    simp only [dotProduct, hf, mul_sub, mul_ite, mul_one, mul_zero, Finset.sum_sub_distrib,
      Finset.sum_ite_eq', Finset.mem_univ, ite_true, ← Finset.sum_mul, hπ.2.1, one_mul, sub_self]
  obtain ⟨g, hg⟩ := poisson hP hirr hπ f hfπ
  set h : ι → ℝ := P *ᵥ g with hh
  have hgh : ∀ i, g i - h i = f i := by
    intro i
    have := congrFun hg i
    rw [sub_mulVec, one_mulVec] at this
    exact this
  set D : ι → ι → ℝ := fun a b => g b - h a with hD
  set c : ℝ := ∑ i, |g i| + ∑ i, |h i| with hc
  have hgc : ∀ i, |g i| ≤ ∑ i, |g i| := fun i =>
    Finset.single_le_sum (fun i _ => abs_nonneg (g i)) (Finset.mem_univ i)
  have hhc : ∀ i, |h i| ≤ ∑ i, |h i| := fun i =>
    Finset.single_le_sum (fun i _ => abs_nonneg (h i)) (Finset.mem_univ i)
  have hDc : ∀ a b, |D a b| ≤ c := fun a b =>
    (abs_sub _ _).trans (add_le_add (hgc b) (hhc a))
  have hD0 : ∀ a, ∑ b, P a b * D a b = 0 := by
    intro a
    simp only [hD, mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul,
      sum_row_of_mem_rowStochastic hP a, one_mul]
    simp [hh, mulVec, dotProduct]
  filter_upwards [ae_martPart_div μ P hP X hX hMarkov D hD0 c hDc] with ω hω
  have hid : ∀ n : ℕ, ((((Finset.Icc 1 n).filter (fun k => X k ω = j)).card : ℕ) : ℝ) =
      n * π j + martPart D n (pathOf X n ω) + (h (X 0 ω) - h (X n ω)) := by
    intro n
    rw [count_eq_sum]
    have hM : martPart D n (pathOf X n ω) =
        ∑ k ∈ Finset.range n, (g (X (k + 1) ω) - h (X k ω)) := by
      unfold martPart
      rw [← Fin.sum_univ_eq_sum_range (fun k => g (X (k + 1) ω) - h (X k ω)) n]
      rfl
    have hsplit : ∑ k ∈ Finset.range n, (g (X (k + 1) ω) - h (X k ω)) =
        ∑ k ∈ Finset.range n, f (X (k + 1) ω) +
          ∑ k ∈ Finset.range n, (h (X (k + 1) ω) - h (X k ω)) := by
      rw [← Finset.sum_add_distrib]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [← hgh]; ring
    have htel := Finset.sum_range_sub (fun k => h (X k ω)) n
    have hfsum : ∑ k ∈ Finset.range n, f (X (k + 1) ω) =
        (∑ k ∈ Finset.range n, if X (k + 1) ω = j then (1 : ℝ) else 0) - n * π j := by
      simp only [hf, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    rw [hM, hsplit, htel, hfsum]
    ring
  have hB : Tendsto (fun n : ℕ => (h (X 0 ω) - h (X n ω)) / n) atTop (𝓝 0) := by
    refine squeeze_zero_norm (fun n => ?_) (tendsto_const_div_atTop_nhds_zero_nat (2 * c))
    rw [Real.norm_eq_abs, abs_div, Nat.abs_cast]
    refine div_le_div_of_nonneg_right ?_ (Nat.cast_nonneg n)
    have h1 := (abs_sub (h (X 0 ω)) (h (X n ω)))
    have h2 := hhc (X 0 ω)
    have h3 := hhc (X n ω)
    have h4 : 0 ≤ ∑ i, |g i| := Finset.sum_nonneg fun i _ => abs_nonneg (g i)
    linarith
  have hlim := (tendsto_const_nhds (x := π j)).add (hω.add hB)
  simp only [add_zero] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have hn' : (n : ℝ) ≠ 0 := by
    have : (1 : ℝ) ≤ n := by exact_mod_cast hn
    linarith
  rw [hid n]
  field_simp
  ring

/-! Worked numbers from the card, in exact fractions. States in the order sunny, cloudy, rainy. -/

/-- The town's table: after sunny 6, 3, 1 in 10; after cloudy 4, 4, 2; after rainy 4, 3, 3. -/
def town : Matrix (Fin 3) (Fin 3) ℚ :=
  !![6/10, 3/10, 1/10; 4/10, 4/10, 2/10; 4/10, 3/10, 3/10]

-- The town's table is a transition matrix: entries non-negative, each row adds to 1.
example : (∀ i j, 0 ≤ town i j) ∧ ∀ i, ∑ j, town i j = 1 := by
  refine ⟨?_, ?_⟩
  · intro i j; fin_cases i <;> fin_cases j <;> simp [town] <;> norm_num
  · intro i; fin_cases i <;> simp [town, Fin.sum_univ_three] <;> norm_num

-- Every entry is positive, so every state reaches every other in one day.
example : Irreducible town := by
  intro i j; refine ⟨1, ?_⟩
  fin_cases i <;> fin_cases j <;> simp [town]

-- (1/2, 1/3, 1/6) is a stationary distribution of the town's table.
example : IsStationaryDistribution town ![1/2, 1/3, 1/6] := by
  refine ⟨?_, ?_, ?_⟩
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]; norm_num
  · ext j; fin_cases j <;> simp [town, vecMul, dotProduct, Fin.sum_univ_three] <;> norm_num

-- Hand solution: sunny 0.4 π_S = 0.4 π_C + 0.4 π_R with total 1 gives π_S = 1/2; then
-- 0.7 π_R = 0.1 (1/2) + 0.2 (1/2 - π_R), so 0.9 π_R = 0.15 and π_R = 1/6; π_C = 1 - 1/2 - 1/6.
example : (9 : ℚ) / 10 * (1 / 6) = 15 / 100 ∧ (1 : ℚ) - 1 / 2 - 1 / 6 = 1 / 3 := by norm_num
-- The spare cloudy equation: (1/2)(0.3) + (1/3)(0.4) + (1/6)(0.3) = 1/3.
example : (1 : ℚ) / 2 * (3 / 10) + 1 / 3 * (4 / 10) + 1 / 6 * (3 / 10) = 1 / 3 := by norm_num
-- Flow out of rainy per day, (1/6)(0.7), equals flow in, (1/2)(0.1) + (1/3)(0.2): both 7/60.
example : (1 : ℚ) / 6 * (7 / 10) = 7 / 60 ∧
    (1 : ℚ) / 2 * (1 / 10) + 1 / 3 * (2 / 10) = 7 / 60 := by norm_num
-- Mean return times 1/π: sunny 2, cloudy 3, rainy 6 days.
example : 1 / ((1 : ℚ) / 2) = 2 ∧ 1 / ((1 : ℚ) / 3) = 3 ∧ 1 / ((1 : ℚ) / 6) = 6 := by norm_num
-- An excursion from rain: ν = (3, 2, 1), 6 days in all, and ν / 6 = π.
example : (3 : ℚ) + 2 + 1 = 6 ∧ (3 : ℚ) / 6 = 1 / 2 ∧ (2 : ℚ) / 6 = 1 / 3 ∧ (1 : ℚ) / 6 = 1 / 6 := by
  norm_num
-- Detailed balance fails: π_S p_SR = 1/20 but π_R p_RS = 1/15.
example : (1 : ℚ) / 2 * (1 / 10) = 1 / 20 ∧ (1 : ℚ) / 6 * (4 / 10) = 1 / 15 ∧
    (1 : ℚ) / 20 ≠ 1 / 15 := by norm_num
-- Mistakes: averaging the rain column gives 1/5; rain after rain is 3/10; neither is 1/6.
example : ((1 : ℚ) / 10 + 2 / 10 + 3 / 10) / 3 = 1 / 5 ∧ (1 : ℚ) / 5 ≠ 1 / 6 ∧
    (3 : ℚ) / 10 ≠ 1 / 6 := by norm_num
-- Mistake: the column of ones solves P x = x for the town, giving the uniform 1/3.
example : town *ᵥ (fun _ => 1) = fun _ => 1 := by
  ext i; fin_cases i <;> simp [town, mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num

/-- The rota: sunny, then cloudy, then rainy, then sunny again, for certain. -/
def rota : Matrix (Fin 3) (Fin 3) ℚ := !![0, 1, 0; 0, 0, 1; 1, 0, 0]

-- The rota's stationary distribution is (1/3, 1/3, 1/3).
example : IsStationaryDistribution rota ![1/3, 1/3, 1/3] := by
  refine ⟨?_, ?_, ?_⟩
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]; norm_num
  · ext j; fin_cases j <;> simp [rota, vecMul, dotProduct, Fin.sum_univ_three]

-- From a sunny day the rota's chance of rain on day 10 is 0 and on day 11 is 1: no settling.
example : (rota ^ 10) 0 2 = 0 ∧ (rota ^ 11) 0 2 = 1 := by
  simp [rota, pow_succ]

/-- The split climate: a dry spell (sunny and cloudy, half and half) that never rains and a wet
spell that never clears. -/
def split : Matrix (Fin 3) (Fin 3) ℚ := !![1/2, 1/2, 0; 1/2, 1/2, 0; 0, 0, 1]

-- Without irreducibility two different mixes balance: (1/2, 1/2, 0) and (0, 0, 1).
example : IsStationaryDistribution split ![1/2, 1/2, 0] ∧
    IsStationaryDistribution split ![0, 0, 1] ∧ (![1/2, 1/2, 0] : Fin 3 → ℚ) ≠ ![0, 0, 1] := by
  refine ⟨⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩, ?_⟩
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]; norm_num
  · ext j; fin_cases j <;> simp [split, vecMul, dotProduct, Fin.sum_univ_three] <;> norm_num
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]
  · ext j; fin_cases j <;> simp [split, vecMul, dotProduct, Fin.sum_univ_three]
  · intro h; have := congrFun h 2; simp at this

#print axioms irreducible_has_unique_stationary_distribution
#print axioms finite_chain_has_stationary_distribution
#print axioms fraction_of_days_tends_to_stationary_share

end StationaryDistributions
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'StationaryDistributions.harmonic_const' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.finrank_ker_one_sub' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.rank_one_sub' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.exists_stationary' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.stationary_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.poisson' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.measurableSet_path' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.measureReal_path_pred' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.sum_measureReal_path' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.measureReal_path_snoc' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.sum_snoc' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.martPart_snoc' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.moment_step' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.inner_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.inner_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.moment_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.tail_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.ae_martPart_div' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.count_eq_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.irreducible_has_unique_stationary_distribution' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.finite_chain_has_stationary_distribution' depends on axioms: [propext, Classical.choice, Quot.sound]
'StationaryDistributions.fraction_of_days_tends_to_stationary_share' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Make rain stickier.** Change the rainy row to 0.2, 0.3, 0.5. Guess first: does the rainy share pass 1/5? It does: the shares become 4/9, 1/3, 2/9, and rain returns every 9/2 days. The cloudy share stays at 1/3; the cloudy equation happens not to change.
> - **Change the seed.** The path in the first chart changes, and so does the third decimal of the simulated share. Guess first: will it stay within a few standard errors of 1/6? It almost always does; the simulation assert allows four.
> - **Replace the table by the rota.** Guess first: what is the chance of rain on day 12? It is 0, since 12 is a multiple of 3 and day 0 is sunny; yet the rainy days up to day 12 are exactly 33.33 per 100.
> - **Solve with the column convention.** Call `balance(P, left=False)` in road 1. The first assert fails: the answer is 1/3 for every state.

---

## The usual mistake

> [!warning]
> **Taking the stationary distribution to be where the chain ends up.** The weather never stops changing. What stands still is the mix of chances, and the long-run fraction of time. A chain started in its stationary distribution is still sunny one day and rainy the next; only its statistics are the same from day to day. And a chain started elsewhere need not have its forecasts approach $\pi$ at all: the rota's never do, while its time fractions still are $\pi$.
>
> - **Row against column.** $\pi$ multiplies $P$ from the left. Solving $P x = x$ gives the column of ones, 1/3 for each kind of day, whatever the table.
> - **Forgetting the total.** The balance equations alone have a whole line of solutions, including all zeros; only the total of 1 picks the shares.
> - **Independent-days error bars.** Treating 100,000 simulated days as independent gives a standard error of 0.0012; blocks of 1,000 days give 0.0015. Neighbouring days are alike, so a run carries less information than its length suggests.
> - **Share read as return time.** A share of 1/6 means rain returns every 6 days on average, not that it returns every 6 days: excursions from rain vary in length, and only their mean is 6.

---

## Where you meet it in real life

- **Weather generators.** Crop and flood models draw wet and dry days from a Markov chain fitted to a station's record; the fitted chain's stationary share of wet days is checked against the record's long-run share.
- **Web search.** PageRank is the stationary distribution of a surfer clicking links with occasional random jumps ([Centrality](../../14-Applied%20and%20computational/07-Network%20Science%20and%20Spectral%20Graphs/01-centrality-and-pagerank.md)).
- **Queues and call centres.** The long-run chance that a line holds $k$ callers is the stationary distribution of a chain in continuous time ([Continuous-time chains](../04-Poisson%20and%20Jump%20Processes/05-continuous-time-markov-chains-and-queues.md)).
- **Sampling hard distributions.** MCMC turns this card round: choose the $\pi$ to sample, build a chain that has it, and read averages off one long run, the time fractions of Step 4 ([MCMC](07-markov-chain-monte-carlo.md)).
- **Credit ratings.** Rating agencies publish tables of yearly moves between grades. Default is a trap, so with it in the table the stationary mix is all default ([Absorption](06-absorption-and-first-step-analysis.md)); with default left out and rows rescaled over surviving bonds, it is the long-run spread of grades, if nothing else changes.

> **Say it back**
> A stationary distribution is a mix of chances over the states that one more step leaves unchanged: $\pi P = \pi$, with non-negative entries adding to 1. Every finite chain has one, and if every state can reach every other it has exactly one, with every entry positive. Its entries are the long-run fractions of time in each state, and one over an entry is the mean time to return. For the town, one day in six is rainy and rain comes back every 6 days on average. None of this needs the forecasts to settle; that is a separate property.

---

## What this builds on

- [Classifying states](03-classifying-states.md): irreducible and periodic chains, the hypotheses that decide uniqueness and settling.
- [Eigenvalues and eigenvectors](../../03-Algebra/07-Eigenvalues%20and%20Symmetric%20Matrices/02-eigenvalues-and-eigenvectors.md): $\pi$ is a left eigenvector for eigenvalue 1.
- [Rank and nullity](../../03-Algebra/05-Solving%20Systems/05-rank-nullity.md): how Step 3 counts the stationary distributions.
- [Random walks on a graph](../../09-Probability%20and%20statistics/14-Random%20Graphs%20and%20the%20Probabilistic%20Method/05-random-walks-on-graphs-and-mixing.md): the special case solved by detailed balance, shares in proportion to links.

## Where this goes next

- [Convergence to equilibrium](05-convergence-to-equilibrium.md): when forecasts from any start approach $\pi$, and how fast.
- [MCMC](07-markov-chain-monte-carlo.md): building a chain whose stationary distribution is a target.
- [Continuous-time chains](../04-Poisson%20and%20Jump%20Processes/05-continuous-time-markov-chains-and-queues.md): the balance equations with rates in place of chances.
- [MCMC as a tool](../../14-Applied%20and%20computational/02-Randomised%20and%20Approximate%20Algorithms/08-markov-chain-monte-carlo-for-computation.md): sampling and counting by running a chain to its stationary distribution.
- [Centrality](../../14-Applied%20and%20computational/07-Network%20Science%20and%20Spectral%20Graphs/01-centrality-and-pagerank.md): a stationary distribution as a ranking.
- [Value and policy iteration](../../15-Optimization/07-Dynamic%20Programming%20and%20Learning/03-value-and-policy-iteration.md): long-run average rewards, weighted by a policy's stationary distribution.

The town's forecasts close in on 1/6 while the rota's never do; why one settles and the other does not, and how fast, is [Convergence to equilibrium](05-convergence-to-equilibrium.md).

---

## Sources

Verified 30 Sep 2026: every link below resolves to the publisher's page or the authors' own page for the book.

- Norris, J. R. *Markov Chains*. Cambridge University Press, 1997. [Publisher page](https://www.cambridge.org/core/books/markov-chains/A3F966B10633A32C8F06F37158031739). Section 1.7 proves existence and uniqueness of the invariant distribution and $\pi_j = 1/m_j$ by the excursion argument used here; Section 1.10 proves the time fractions.
- Levin, David A., and Yuval Peres, with Elizabeth L. Wilmer. *Markov Chains and Mixing Times*, 2nd ed. American Mathematical Society, 2017. [Authors' page, with the full text](https://pages.uoregon.edu/dlevin/MARKOV/). Chapter 1 builds the stationary distribution from expected visits during an excursion and proves uniqueness from harmonic functions, the two arguments of Steps 3 and 4.
