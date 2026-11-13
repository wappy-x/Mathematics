# Gambler's ruin: the chance of reaching the target before the floor

[Syllabus](../../../SYLLABUS.md) → [Stochastic processes and calculus](../README.md) → [Random Walks and Filtrations](../README.md#s01) → Gambler's ruin

---

## General Overview

A gambler sits down with 10 chips. Each round she stakes 1 chip on an even-money bet: win and she gains a chip, lose and she gives one up. She has set herself two rules. Reach 20 chips and she leaves, bankroll doubled. Reach 0 and she has no choice: she is ruined.

Two questions decide whether the evening is worth having. How likely is she to double up before she goes broke? And how many rounds will it take, on average?

At a fair table, where each round is won half the time, the answers are 50 percent and 100 rounds. At a table tilted a single point against her, where each round is won 49 times in 100, the chance of doubling falls to about 40 percent and the average game lasts 98.70 rounds.

Each round costs her 0.02 chips on average. Over about 99 rounds that is about 2 chips, a tenth of the 20 that separate the walls, and that tenth comes off her chance: 50 percent becomes about 40.

Both answers come from one move, **first-step analysis**: the first round sends her to 9 chips or to 11, and from there the game starts afresh. Written down for every chip count, that gives one equation per count, and a recurrence solves them exactly.

**The chance of reaching the target first satisfies "chance here = win chance × chance one chip up + lose chance × chance one chip down", with 0 at the floor and 1 at the target; the solution is k/L for a fair game and (1 − r^k)/(1 − r^L) with r = lose chance / win chance otherwise, and the expected length solves the same equation with 1 added for the round just played.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, with the complete argument in a folded Detailed proof.

### The picture: one fair game, from 10 chips to 20

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "One simulated fair game, chips read every 4 rounds"
    x-axis "Round (every 4th round)" [0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112]
    y-axis "Chips held" 0 --> 20
    line [10, 12, 14, 12, 12, 14, 18, 16, 14, 14, 14, 12, 14, 14, 14, 12, 8, 6, 8, 12, 12, 10, 12, 12, 12, 12, 14, 18, 20]
```

This is one sample: the first of 20000 games the code plays at a fair table, seed 20260929, read on a grid of every fourth round. Between grid points the path dipped as low as 5 chips and rose to 19 before it hit 20 at round 112. Another seed draws another path.

---

## The formula

Notation first, in words. The chips after round n are written $X_n$, the value of the process at time n, with time counted in rounds ([Stochastic processes](01-processes-and-paths.md)). Between the walls, $X_n$ is a simple random walk ([Simple random walk](02-simple-random-walk.md)): each round adds 1 with chance $p$ and subtracts 1 with chance $q = 1 - p$, independently of every other round. The game ends at the round $T$, the first round at which the chips reach 0 or the target $L$.

Start with $k$ chips. Write $h_k$ for the chance of reaching $L$ before 0, and $t_k$ for the expected number of rounds, $E[T]$. Then

$$h_k = \frac{k}{L} \quad \text{if } p = q, \qquad h_k = \frac{1 - r^k}{1 - r^L}, \quad r = \frac{q}{p}, \quad \text{if } p \ne q.$$

**Read it aloud:** at a fair table the chance of doubling up is the fraction of the way to the target already held; at a tilted table each chip nearer the target adds r times the chance the chip below it added, and the answer is the share of those growing steps already climbed.

The expected length follows from the chance:

$$t_k = k\,(L - k) \quad \text{if } p = q, \qquad t_k = \frac{k - L\,h_k}{q - p} \quad \text{if } p \ne q.$$

**Read it aloud:** a fair game lasts, on average, the distance to the floor times the distance to the target; a tilted game lasts the expected chips lost, divided by the chips lost per round.

The chance of ruin is $1 - h_k$, because the game ends at one wall or the other (Step 1 proves it ends).

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $X_n$, $n$ | chips held after round n; the round count | 10 at round 0 | — |
| $k$ | chips at the start | 10 | $h_k$ rises towards 1 |
| $L$ | the target, where she leaves | 20 | $h_k$ falls, $t_k$ grows |
| $p$ | chance of winning one round | 0.50 or 0.49 | $h_k$ rises |
| $q$ | chance of losing one round, $1 - p$ | 0.50 or 0.51 | $h_k$ falls |
| $r$ | the tilt, $q/p$ | 1 or 1.040816 | $h_k$ falls |
| $h_k$ | chance of reaching $L$ before 0 from $k$ chips | 0.5 or 0.4013 | — |
| $t_k$ | expected rounds until either wall, $E[T]$ | 100 or 98.70 | — |
| $T$ | the round the game ends | 112 in the pictured game | — |
| $d_k$ | the step up in chance from $k - 1$ chips to $k$, $h_k - h_{k-1}$ | 1/20 each, fair | — |
| $g_k$ | the duration minus its drift part, $t_k - k/(q-p)$ | used in Step 5 | — |
| $\xi_1$, $B_j$, $u_k$, $P_k$, $E_k$ | in the Detailed proof only: the first round's +1 or −1; block j all wins; a difference of two solutions; chance and average from start k | — | — |

The chance as a function of the starting chips, at both tables:

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Chance of reaching 20 chips before 0"
    x-axis "Chips at the start" [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
    y-axis "Chance" 0 --> 1
    line [0.00, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00]
    line [0.00, 0.07, 0.14, 0.22, 0.31, 0.40, 0.50, 0.61, 0.73, 0.86, 1.00]
```

Orange: the fair table, a straight line. Green: the table at 0.49, which sags below it everywhere between the walls. The sag is largest in the middle, where the game is longest.

### When it holds

- **Fixed stakes of one chip.** Stake all 10 chips on one round at 0.49 and the chance of doubling is 0.49, not 0.4013: the formula describes one strategy, not every strategy.
- **The same chance every round, rounds independent.** Without this the first round does not restart the game; the equations change and so does the answer.
- **Two walls.** Remove the target and a fair game ruins her with certainty, while its expected length is infinite (Step 6).
- **Whole chips and a target reached exactly.** With stakes of one chip the walk cannot jump past a wall; with larger stakes it can overshoot, and the walls need redefining.

---

## Why it works

### Step 0: the first round restarts the game

After one round she holds 11 chips with chance $p$ or 9 with chance $q$. Each round is a fresh, independent bet, so from 11 chips the rest of the game is the same game, started at 11. Averaging over the first round turns one question about whole paths into one question per chip count, each about its two neighbours.

### Step 1: the game ends

Before any average is taken, the game must be known to stop. From any chip count, $L$ wins in a row reach the target, wherever she stands.

Split the rounds into blocks of $L$. Each block, whatever came before, is all wins with chance $p^L$, which is more than 0. So the game is still running after m blocks with chance at most $(1 - p^L)^m$.

That shrinks geometrically: the game ends with probability 1, and $E[T]$ is finite. The bound is crude; in the code, less than one in $10^{16}$ of the chance is unresolved after 3000 rounds.

### Step 2: the chance equations

Condition on the first round. With chance $p$ she moves to $k + 1$ and then reaches $L$ first with chance $h_{k+1}$; with chance $q$ she moves to $k - 1$. The law of total probability adds the chances of the two cases, each weighted by the chance of that case ([Conditional probability](../../09-Probability%20and%20statistics/01-Chance%20and%20Events/05-conditional-probability.md)). Here it gives, for every $k$ from 1 to $L - 1$,

$$h_k = p\,h_{k+1} + q\,h_{k-1}, \qquad h_0 = 0, \quad h_L = 1.$$

At 0 she has already lost, at $L$ already won: $L - 1$ equations in $L - 1$ unknowns.

### Step 3: the steps between neighbours form a first-order recurrence

Write $d_k = h_k - h_{k-1}$ for the step up in chance from $k - 1$ chips to $k$. Write $h_k = p\,h_k + q\,h_k$, since $p + q = 1$, and subtract from the equation of Step 2:

$$p\,(h_{k+1} - h_k) = q\,(h_k - h_{k-1}), \qquad \text{so} \qquad d_{k+1} = r\,d_k.$$

Each step up the ladder of chances is the tilt $r$ times the previous one: a first-order recurrence with no added constant ([First-order recurrences](../../04-Combinatorics%20and%20graphs/05-Recurrences/03-first-order-recurrences-and-loans.md)). So $d_k = r^{k-1} d_1$. The steps from 0 to $L$ add up to $h_L - h_0 = 1$:

$$d_1\,(1 + r + \dots + r^{L-1}) = 1, \qquad h_k = d_1\,(1 + r + \dots + r^{k-1}).$$

Divide the two sums. At a fair table $r = 1$, every step is the same, $1/L$, and $h_k = k/L$: a twentieth per chip, 0.5 at 10 chips. Otherwise the geometric sum $1 + r + \dots + r^{k-1}$ equals $(1 - r^k)/(1 - r)$, and the ratio is the formula.

At 0.49 the tilt is $r$ = 1.040816, so each chip nearer the target is worth about 4 percent more chance than the chip below it. Most of the climb from 0 to 1 happens near the top, which is why the green curve sags.

### Step 4: only one answer fits

The equations of Step 2 have exactly one solution.

If two sequences both satisfied them, their difference would be 0 at both walls and would equal, at every inner point, a weighted average of its two neighbours. An average cannot exceed both of the numbers it averages, so the largest value of the difference, if positive, would be shared by the neighbours, and by theirs, all the way to a wall, where it is 0.

So the difference is never positive, and by the same argument never negative. The chance and the formula satisfy the same equations; they are the same numbers.

### Step 5: the duration equations

The same conditioning, with one round counted for the round just played:

$$t_k = 1 + p\,t_{k+1} + q\,t_{k-1}, \qquad t_0 = t_L = 0.$$

This step uses Step 1: an equation between expectations says nothing if $t_k$ could be infinite.

At a fair table, rearranging gives $(t_{k+1} - t_k) - (t_k - t_{k-1}) = -2$. The steps fall by 2 each time, so $t_k$ is a downward parabola with zeros at 0 and $L$: $t_k = k(L - k)$. Check it: $k(L - k)$ is 0 at both walls, and $\tfrac12(k+1)(L-k-1) + \tfrac12(k-1)(L-k+1) = k(L-k) - 1$. At 10 chips, 10 × 10 = 100 rounds.

At a tilted table, each round loses $q - p$ chips on average, so $k/(q - p)$ solves the equation away from the walls: the drift part. It misses the walls, so correct it. Let $g_k = t_k - k/(q - p)$. Substituting, the 1 cancels against the drift, and

$$g_k = p\,g_{k+1} + q\,g_{k-1}, \qquad g_0 = 0, \quad g_L = -\frac{L}{q - p}.$$

That is the chance equation again, scaled: $g_k = -L\,h_k/(q - p)$, by Step 4's uniqueness. Adding back the drift part gives $t_k = (k - L\,h_k)/(q - p)$. The numerator is her expected loss of chips, $k$ minus the expected chips at the end, $L\,h_k$; dividing by the loss per round gives rounds. At 0.49: $(10 - 8.025990)/0.02$ = 98.7005.

### Step 6: move the target away

Hold 10 chips and raise the target at a fair table. The chance of reaching it is $10/L$: 0.5, 0.3333, 0.25, down to 0.01 at a target of 1000, and to 0 as the target leaves altogether. With no upper wall, ruin is certain.

Yet the expected length, $10(L - 10)$, runs 100, 200, 300 and on to 9900: it has no finite limit. Playing until ruin lasts at least as long as playing until ruin or $L$, so its mean is at least $10(L - 10)$ for every $L$.

A fair game played until ruin ends with probability 1 and has an infinite expected length. Fair does not mean safe: the expected length is carried by rare, very long games that climb far before they fall.

Tilt the table her way instead, 0.51 a round. Then $r = 0.49/0.51 < 1$, $r^L$ vanishes as $L$ grows, and $h_k \to 1 - r^k$. From 10 chips the chance of never going broke is 0.3297, about one in three. At 0.49, $r > 1$, $h_k \to 0$ and ruin is certain.

<details>
<summary>Detailed proof</summary>

**Setting.** Let $\xi_1, \xi_2, \dots$ be independent, each $+1$ with probability $p \in (0, 1)$ and $-1$ with probability $q = 1 - p$. For a start $k \in \{0, \dots, L\}$ put $X_0 = k$, $X_n = k + \xi_1 + \dots + \xi_n$ until the first $n$ with $X_n \in \{0, L\}$, and $T$ that first $n$ (infinite if no such $n$ exists). Write $P_k$, $E_k$ for probability and expectation from start $k$.

**1. Finite exit time.** For $j \ge 0$ let $B_j$ be the event that $\xi_{jL+1}, \dots, \xi_{(j+1)L}$ are all $+1$. If $T > jL$ and $B_j$ happens then $T \le (j+1)L$, since $L$ up-steps from any interior point reach $L$. The $B_j$ are independent with probability $p^L$, so $P_k(T > mL) \le P(B_0^c \cap \dots \cap B_{m-1}^c) = (1 - p^L)^m$. Hence the game ends with $P_k$-probability 1 and $E_k T = \sum_{n \ge 0} P_k(T > n) \le L \sum_{m \ge 0} (1 - p^L)^m = L/p^L < \infty$.

**2. First-step identities.** For $0 < k < L$, on $\{\xi_1 = +1\}$ the shifted sequence $\xi_2, \xi_3, \dots$ is independent of $\xi_1$ with the same law, and the game it drives from $k + 1$ is the remaining game. So $P_k(X_T = L \mid \xi_1 = +1) = P_{k+1}(X_T = L)$, likewise for $-1$, and the law of total probability gives $h_k = p h_{k+1} + q h_{k-1}$. For duration, $T = 1 + T'$ with $T'$ the exit time of the shifted game, so conditioning on $\xi_1$ (all terms finite by part 1) gives $t_k = 1 + p t_{k+1} + q t_{k-1}$. The boundary values are immediate from $T = 0$ at a wall.

**3. Uniqueness.** Let $u$ satisfy $u_k = p u_{k+1} + q u_{k-1}$ for $0 < k < L$ with $u_0 = u_L = 0$. Suppose its largest value is positive, at some interior $k$. Then $u_k = p u_{k+1} + q u_{k-1}$ with both weights positive and both neighbours at most $u_k$ forces both neighbours to equal $u_k$. Repeating, $u_{k+1} = u_{k+2} = \dots = u_L = 0$, a contradiction. So $u \le 0$; applied to $-u$, $u \ge 0$. The difference of two solutions of either the chance or the duration system is such a $u$, so each system has one solution.

**4. Solving.** Step 3 of Why it works gives $h_k = \sum_{j<k} r^j / \sum_{j<L} r^j$, which is $k/L$ at $r = 1$ and $(1 - r^k)/(1 - r^L)$ otherwise; it satisfies the system, so by part 3 it is the chance. For duration, $v_k = k(L - k)$ at $p = q$, and $v_k = (k - L h_k)/(q - p)$ otherwise, satisfy the duration system, as checked in Step 5; by part 3, $t_k = v_k$.

**5. Ruin.** Part 1 gives $P_k(X_T \in \{0, L\}) = 1$, so $P_k(\text{ruin}) = 1 - h_k$.

</details>

**Another road.** At a fair table the chips are a fair game, a martingale ([Martingales](../02-Martingales/01-martingales.md)) in the language of this wing's second shelf: the expected chips after the next round equal the chips now. Stopping a fair game when it leaves a finite range keeps the average, so $10 = 20\,h_{10} + 0$, and $h_{10} = 0.5$ in one line.

At a tilted table the same trick works on $r^{X_n}$, de Moivre's choice, and on $X_n + (q - p)n$ for the duration. The martingale cards of that shelf state when stopping keeps the average ([Stopping times](../02-Martingales/03-stopping-times-and-optional-stopping.md)), and show the doubling strategy, where it does not.

---

## Worked numbers, by hand

The tilted table: 10 chips, target 20, each round won with chance 0.49.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the tilt $r$ | 0.51 / 0.49 | 1.040816 |
| $r^{10}$ | 1.040816 multiplied by itself ten times | 1.491904 |
| shortcut | $1 - r^{20} = (1 - r^{10})(1 + r^{10})$, so $h_{10} = 1/(1 + r^{10})$ | — |
| chance of doubling | 1 / 2.491904 | **0.401300** |
| chance of ruin | 1 − 0.401300 | 0.598700 |
| expected chips at the end | 20 × the chance of doubling, unrounded | 8.025990 |
| expected rounds | (10 − 8.025990) / 0.02 | **98.7005** |
| fair table, for comparison | 10 / 20 and 10 × 10 | 0.5 and 100 |

At the tilted table she doubles up about 40 times in 100 evenings and is ruined about 60 times, where a fair table would split them evenly; the evenings are almost as long either way.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Fair formula k/L at 0.49 | 0.5000, against 0.4013 | The tilt compounds over about 99 rounds; it is not a rounding error |
| Tilt upside down, $p/q$ for $q/p$ | 0.5987 | That is the ruin chance, or the chance at 0.51: the two walls swapped |
| All 10 chips on one round at 0.49 | 0.49, simulated 0.4934 ± 0.0035 | Fixed stakes dropped: at a table tilted against her, fewer rounds means less tilt |
| Top wall raised to 1000, fair | chance 0.0100, 9900 rounds | Two walls dropped in the limit: ruin certain, expected length infinite |

The code prints every row. The third row is why fixed stakes sit under "When it holds": at a fair table bold and timid play both give 0.5, but at 0.49 bold play wins more often.

---

## Code, from first principles, and it actually runs

The code takes four independent roads to the chance of doubling from 10 chips and the expected length, at 0.50 and at 0.49. The first is the closed forms. The second solves the first-step equations as a linear system by elimination, knowing nothing of the formulas.

The third pushes the chance mass forward round by round for 3000 rounds: whatever reaches 20 is added to the chance, the chance of still playing is added to the length, and what is still unresolved is printed.

The fourth plays 20000 games with a SplitMix64 generator written out, seed 20260929, and prints each estimate with its standard error, the typical size of its random error. The asserts compare the formulas against elimination, against mass flow within the unresolved mass, and against simulation within 4 standard errors.

### Python

```python
# Gambler's ruin -- the check behind the card.  Nothing is imported.
# A gambler holds 10 chips, bets 1 chip a round, and stops at 0 or at 20.
# Four roads to the chance h of reaching 20 first and the expected number of
# rounds t: the closed forms; the first-step equations solved by elimination;
# the chance mass pushed forward round by round; and a seeded simulation.
K, L, SEED, GAMES = 10, 20, 20260929, 20000
MASK = (1 << 64) - 1

def formula(k, n, p):                    # the closed forms from Why it works
    q = 1 - p
    if p == 0.5:
        return k / n, k * (n - k)
    r = q / p
    h = (1 - r ** k) / (1 - r ** n) + 0.0
    return h, (k - n * h) / (q - p)

def first_step(n, p, rhs, end):          # q x[i-1] - x[i] + p x[i+1] = -rhs
    q = 1 - p                            # for i = 1..n-1, x[0] = 0, x[n] = end
    c, d = [0.0] * n, [0.0] * n          # forward sweep of Thomas elimination
    for i in range(1, n):
        den = -1 - q * c[i - 1]
        c[i] = p / den
        d[i] = (-rhs - q * d[i - 1]) / den
    x = [0.0] * (n + 1)
    x[n] = end
    for i in range(n - 1, 0, -1):        # back substitution
        x[i] = d[i] - c[i] * x[i + 1]
    return x

def mass_flow(k, n, p, rounds):          # move every scrap of chance, round by round
    m = [0.0] * (n + 1)
    m[k] = 1.0
    top = dur = 0.0
    for _ in range(rounds):
        dur += sum(m[1:n])               # P(still playing) adds up to E[rounds]
        new = [0.0] * (n + 1)
        for i in range(1, n):
            new[i + 1] += p * m[i]
            new[i - 1] += (1 - p) * m[i]
        top += new[n]
        new[0] = new[n] = 0.0
        m = new
    return top, dur, sum(m)

class SplitMix64:                        # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def play(g, k, n, p, path):              # one game; returns (reached n, rounds)
    x, t = k, 0
    while 0 < x < n:
        x += 1 if g.uniform() < p else -1
        t += 1
        path.append(x)
    return x == n, t

def simulate(k, n, p):
    g, wins, s1, s2 = SplitMix64(SEED), 0, 0.0, 0.0
    for _ in range(GAMES):
        won, t = play(g, k, n, p, [])
        wins, s1, s2 = wins + won, s1 + t, s2 + t * t
    h, mt = wins / GAMES, s1 / GAMES
    return h, (h * (1 - h) / GAMES) ** 0.5, mt, ((s2 / GAMES - mt * mt) / (GAMES - 1)) ** 0.5

print(f"game: start {K} chips, stop at 0 or {L}, stake 1 chip a round")
for p in (0.5, 0.49):
    hf, tf = formula(K, L, p)
    hs, ts = first_step(L, p, 0.0, 1.0)[K], first_step(L, p, 1.0, 0.0)[K]
    hm, tm, left = mass_flow(K, L, p, 3000)
    hr, seh, tr, set_ = simulate(K, L, p)
    print(f"p = {p:.2f}  formula     h = {hf:.6f}  t = {tf:.4f}")
    print(f"p = {p:.2f}  first-step  h = {hs:.6f}  t = {ts:.4f}")
    print(f"p = {p:.2f}  mass flow   h = {hm:.6f}  t = {tm:.4f}  unresolved after 3000 rounds {left:.1e}")
    print(f"p = {p:.2f}  simulated   h = {hr:.4f} +- {seh:.4f}  t = {tr:.2f} +- {set_:.2f}  ({GAMES} games)")
    print(f"p = {p:.2f}  ruin chance 1 - h = {1 - hf:.6f}")
    assert abs(hf - hs) < 1e-12                  # closed form against elimination
    assert abs(tf - ts) < 1e-9
    assert abs(hf - hm) <= left + 1e-12          # closed form against mass flow
    assert abs(tf - tm) < 1e-6
    assert abs(hr - hf) < 4 * seh                # simulation, within 4 standard errors
    assert abs(tr - tf) < 4 * set_
r = 0.51 / 0.49
r10 = 1.0
for _ in range(10):
    r10 *= r
h49 = 1 / (1 + r10)
print(f"worked, p = 0.49: r = {r:.6f}, r^10 = {r10:.6f}, h = 1/(1 + r^10) = {h49:.6f}")
print(f"worked, p = 0.49: 20 h = {20 * h49:.6f}, t = (10 - 20 h)/0.02 = {(10 - 20 * h49) / 0.02:.4f}")
assert abs(h49 - formula(K, L, 0.49)[0]) < 1e-12              # the 1/(1 + r^10) shortcut
for p in (0.5, 0.49):
    row = ", ".join(f"{formula(k, L, p)[0]:.2f}" for k in range(0, L + 1, 2))
    print(f"figure, h by start k = 0, 2, ..., 20, p = {p:.2f}: {row}")
path = [K]
won, T = play(SplitMix64(SEED), K, L, 0.5, path)
print(f"figure, first simulated fair game, chips every 4 rounds: {', '.join(str(path[i]) for i in range(0, T + 1, 4))}")
print(f"figure, that game ends at round {T} on {path[-1]}; lowest {min(path)}, highest before the end {max(path[:-1])}")
print(f"mistake, fair formula k/L used at p = 0.49: {K / L:.4f} against {formula(K, L, 0.49)[0]:.4f}")
print(f"mistake, ratio upside down, p/q for q/p: {formula(K, L, 0.51)[0]:.4f}")
g, wins = SplitMix64(SEED), 0
for _ in range(GAMES):                   # bold play: stake all 10 chips at once
    wins += g.uniform() < 0.49
se_b = (wins / GAMES * (1 - wins / GAMES) / GAMES) ** 0.5
print(f"mistake, stake all 10 chips in one round at p = 0.49: simulated {wins / GAMES:.4f} +- {se_b:.4f}, exact 0.4900")
assert abs(wins / GAMES - 0.49) < 4 * se_b
for n in (20, 30, 40, 80, 160, 1000):
    hf, tf = formula(K, n, 0.5)
    print(f"top wall moved up, fair, target {n}: h = {hf:.4f}, t = {tf:.0f}")
hf = formula(K, 1000, 0.51)[0]
q10 = 1.0
for _ in range(10):
    q10 *= 0.49 / 0.51
print(f"top wall moved up, p = 0.51: h at target 1000 = {hf:.4f}; limit 1 - (0.49/0.51)^10 = {1 - q10:.4f}")
assert abs(hf - (1 - q10)) < 1e-9
for k, n, p, what in ((100, 200, 0.49, "100 chips to 200 at 0.49"), (K, L, 18 / 38, "10 chips to 20 on red, 18/38")):
    hf, tf = formula(k, n, p)
    print(f"scale, {what}: h = {hf:.4f}, t = {tf:.2f}")
print("ALL CHECKS PASS")
```

**Ran 2026-09-29 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
game: start 10 chips, stop at 0 or 20, stake 1 chip a round
p = 0.50  formula     h = 0.500000  t = 100.0000
p = 0.50  first-step  h = 0.500000  t = 100.0000
p = 0.50  mass flow   h = 0.500000  t = 100.0000  unresolved after 3000 rounds 9.1e-17
p = 0.50  simulated   h = 0.5022 +- 0.0035  t = 100.80 +- 0.58  (20000 games)
p = 0.50  ruin chance 1 - h = 0.500000
p = 0.49  formula     h = 0.401300  t = 98.7005
p = 0.49  first-step  h = 0.401300  t = 98.7005
p = 0.49  mass flow   h = 0.401300  t = 98.7005  unresolved after 3000 rounds 5.0e-17
p = 0.49  simulated   h = 0.4049 +- 0.0035  t = 98.37 +- 0.55  (20000 games)
p = 0.49  ruin chance 1 - h = 0.598700
worked, p = 0.49: r = 1.040816, r^10 = 1.491904, h = 1/(1 + r^10) = 0.401300
worked, p = 0.49: 20 h = 8.025990, t = (10 - 20 h)/0.02 = 98.7005
figure, h by start k = 0, 2, ..., 20, p = 0.50: 0.00, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00
figure, h by start k = 0, 2, ..., 20, p = 0.49: 0.00, 0.07, 0.14, 0.22, 0.31, 0.40, 0.50, 0.61, 0.73, 0.86, 1.00
figure, first simulated fair game, chips every 4 rounds: 10, 12, 14, 12, 12, 14, 18, 16, 14, 14, 14, 12, 14, 14, 14, 12, 8, 6, 8, 12, 12, 10, 12, 12, 12, 12, 14, 18, 20
figure, that game ends at round 112 on 20; lowest 5, highest before the end 19
mistake, fair formula k/L used at p = 0.49: 0.5000 against 0.4013
mistake, ratio upside down, p/q for q/p: 0.5987
mistake, stake all 10 chips in one round at p = 0.49: simulated 0.4934 +- 0.0035, exact 0.4900
top wall moved up, fair, target 20: h = 0.5000, t = 100
top wall moved up, fair, target 30: h = 0.3333, t = 200
top wall moved up, fair, target 40: h = 0.2500, t = 300
top wall moved up, fair, target 80: h = 0.1250, t = 700
top wall moved up, fair, target 160: h = 0.0625, t = 1500
top wall moved up, fair, target 1000: h = 0.0100, t = 9900
top wall moved up, p = 0.51: h at target 1000 = 0.3297; limit 1 - (0.49/0.51)^10 = 0.3297
scale, 100 chips to 200 at 0.49: h = 0.0180, t = 4820.23
scale, 10 chips to 20 on red, 18/38: h = 0.2585, t = 91.76
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Gambler's ruin -- the same check as the Python, in Rust.  No crates.
// A gambler holds 10 chips, bets 1 chip a round, and stops at 0 or at 20.
// Four roads to the chance h of reaching 20 first and the expected number of
// rounds t: the closed forms; the first-step equations solved by elimination;
// the chance mass pushed forward round by round; and a seeded simulation.
const K: usize = 10;
const L: usize = 20;
const SEED: u64 = 20260929;
const GAMES: usize = 20000;

fn formula(k: usize, n: usize, p: f64) -> (f64, f64) {  // the closed forms from Why it works
    let q = 1.0 - p;
    if p == 0.5 {
        return (k as f64 / n as f64, (k * (n - k)) as f64);
    }
    let r = q / p;
    let h = (1.0 - r.powi(k as i32)) / (1.0 - r.powi(n as i32)) + 0.0;
    (h, (k as f64 - n as f64 * h) / (q - p))
}

fn first_step(n: usize, p: f64, rhs: f64, end: f64) -> Vec<f64> {  // q x[i-1] - x[i] + p x[i+1] = -rhs
    let q = 1.0 - p;                                              // for i = 1..n-1, x[0] = 0, x[n] = end
    let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);            // forward sweep of Thomas elimination
    for i in 1..n {
        let den = -1.0 - q * c[i - 1];
        c[i] = p / den;
        d[i] = (-rhs - q * d[i - 1]) / den;
    }
    let mut x = vec![0.0; n + 1];
    x[n] = end;
    for i in (1..n).rev() {                                       // back substitution
        x[i] = d[i] - c[i] * x[i + 1];
    }
    x
}

fn mass_flow(k: usize, n: usize, p: f64, rounds: usize) -> (f64, f64, f64) {  // move every scrap of chance
    let mut m = vec![0.0; n + 1];
    m[k] = 1.0;
    let (mut top, mut dur) = (0.0, 0.0);
    for _ in 0..rounds {
        dur += m[1..n].iter().sum::<f64>();                       // P(still playing) adds up to E[rounds]
        let mut new = vec![0.0; n + 1];
        for i in 1..n {
            new[i + 1] += p * m[i];
            new[i - 1] += (1.0 - p) * m[i];
        }
        top += new[n];
        new[0] = 0.0;
        new[n] = 0.0;
        m = new;
    }
    (top, dur, m.iter().sum::<f64>())
}

struct SplitMix64 { s: u64 }                                      // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn play(g: &mut SplitMix64, k: usize, n: usize, p: f64, path: &mut Vec<usize>) -> (bool, usize) {
    let (mut x, mut t) = (k, 0);                                  // one game; returns (reached n, rounds)
    while x > 0 && x < n {
        if g.uniform() < p { x += 1 } else { x -= 1 }
        t += 1;
        path.push(x);
    }
    (x == n, t)
}

fn simulate(k: usize, n: usize, p: f64) -> (f64, f64, f64, f64) {
    let mut g = SplitMix64 { s: SEED };
    let (mut wins, mut s1, mut s2) = (0usize, 0.0f64, 0.0f64);
    for _ in 0..GAMES {
        let (won, t) = play(&mut g, k, n, p, &mut Vec::new());
        wins += won as usize;
        s1 += t as f64;
        s2 += (t * t) as f64;
    }
    let gm = GAMES as f64;
    let (h, mt) = (wins as f64 / gm, s1 / gm);
    (h, (h * (1.0 - h) / gm).sqrt(), mt, ((s2 / gm - mt * mt) / (gm - 1.0)).sqrt())
}

fn main() {
    println!("game: start {} chips, stop at 0 or {}, stake 1 chip a round", K, L);
    for p in [0.5, 0.49] {
        let (hf, tf) = formula(K, L, p);
        let (hs, ts) = (first_step(L, p, 0.0, 1.0)[K], first_step(L, p, 1.0, 0.0)[K]);
        let (hm, tm, left) = mass_flow(K, L, p, 3000);
        let (hr, seh, tr, set) = simulate(K, L, p);
        println!("p = {:.2}  formula     h = {:.6}  t = {:.4}", p, hf, tf);
        println!("p = {:.2}  first-step  h = {:.6}  t = {:.4}", p, hs, ts);
        println!("p = {:.2}  mass flow   h = {:.6}  t = {:.4}  unresolved after 3000 rounds {:.1e}", p, hm, tm, left);
        println!("p = {:.2}  simulated   h = {:.4} +- {:.4}  t = {:.2} +- {:.2}  ({} games)", p, hr, seh, tr, set, GAMES);
        println!("p = {:.2}  ruin chance 1 - h = {:.6}", p, 1.0 - hf);
        assert!((hf - hs).abs() < 1e-12);                         // closed form against elimination
        assert!((tf - ts).abs() < 1e-9);
        assert!((hf - hm).abs() <= left + 1e-12);                 // closed form against mass flow
        assert!((tf - tm).abs() < 1e-6);
        assert!((hr - hf).abs() < 4.0 * seh);                     // simulation, within 4 standard errors
        assert!((tr - tf).abs() < 4.0 * set);
    }
    let r = 0.51 / 0.49;
    let mut r10 = 1.0;
    for _ in 0..10 { r10 *= r }
    let h49 = 1.0 / (1.0 + r10);
    println!("worked, p = 0.49: r = {:.6}, r^10 = {:.6}, h = 1/(1 + r^10) = {:.6}", r, r10, h49);
    println!("worked, p = 0.49: 20 h = {:.6}, t = (10 - 20 h)/0.02 = {:.4}", 20.0 * h49, (10.0 - 20.0 * h49) / 0.02);
    assert!((h49 - formula(K, L, 0.49).0).abs() < 1e-12);         // the 1/(1 + r^10) shortcut
    for p in [0.5, 0.49] {
        let row: Vec<String> = (0..=L).step_by(2).map(|k| format!("{:.2}", formula(k, L, p).0)).collect();
        println!("figure, h by start k = 0, 2, ..., 20, p = {:.2}: {}", p, row.join(", "));
    }
    let mut path = vec![K];
    let (_, t_end) = play(&mut SplitMix64 { s: SEED }, K, L, 0.5, &mut path);
    let pts: Vec<String> = (0..=t_end).step_by(4).map(|i| path[i].to_string()).collect();
    println!("figure, first simulated fair game, chips every 4 rounds: {}", pts.join(", "));
    println!("figure, that game ends at round {} on {}; lowest {}, highest before the end {}",
             t_end, path[t_end], path.iter().min().unwrap(), path[..t_end].iter().max().unwrap());
    println!("mistake, fair formula k/L used at p = 0.49: {:.4} against {:.4}", K as f64 / L as f64, formula(K, L, 0.49).0);
    println!("mistake, ratio upside down, p/q for q/p: {:.4}", formula(K, L, 0.51).0);
    let (mut g, mut wins) = (SplitMix64 { s: SEED }, 0usize);
    for _ in 0..GAMES {                                           // bold play: stake all 10 chips at once
        wins += (g.uniform() < 0.49) as usize;
    }
    let hb = wins as f64 / GAMES as f64;
    let se_b = (hb * (1.0 - hb) / GAMES as f64).sqrt();
    println!("mistake, stake all 10 chips in one round at p = 0.49: simulated {:.4} +- {:.4}, exact 0.4900", hb, se_b);
    assert!((hb - 0.49).abs() < 4.0 * se_b);
    for n in [20, 30, 40, 80, 160, 1000] {
        let (hf, tf) = formula(K, n, 0.5);
        println!("top wall moved up, fair, target {}: h = {:.4}, t = {:.0}", n, hf, tf);
    }
    let hf = formula(K, 1000, 0.51).0;
    let mut q10 = 1.0;
    for _ in 0..10 { q10 *= 0.49 / 0.51 }
    println!("top wall moved up, p = 0.51: h at target 1000 = {:.4}; limit 1 - (0.49/0.51)^10 = {:.4}", hf, 1.0 - q10);
    assert!((hf - (1.0 - q10)).abs() < 1e-9);
    for (k, n, p, what) in [(100, 200, 0.49, "100 chips to 200 at 0.49"), (K, L, 18.0 / 38.0, "10 chips to 20 on red, 18/38")] {
        let (hf, tf) = formula(k, n, p);
        println!("scale, {}: h = {:.4}, t = {:.2}", what, hf, tf);
    }
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-29 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
game: start 10 chips, stop at 0 or 20, stake 1 chip a round
p = 0.50  formula     h = 0.500000  t = 100.0000
p = 0.50  first-step  h = 0.500000  t = 100.0000
p = 0.50  mass flow   h = 0.500000  t = 100.0000  unresolved after 3000 rounds 9.1e-17
p = 0.50  simulated   h = 0.5022 +- 0.0035  t = 100.80 +- 0.58  (20000 games)
p = 0.50  ruin chance 1 - h = 0.500000
p = 0.49  formula     h = 0.401300  t = 98.7005
p = 0.49  first-step  h = 0.401300  t = 98.7005
p = 0.49  mass flow   h = 0.401300  t = 98.7005  unresolved after 3000 rounds 5.0e-17
p = 0.49  simulated   h = 0.4049 +- 0.0035  t = 98.37 +- 0.55  (20000 games)
p = 0.49  ruin chance 1 - h = 0.598700
worked, p = 0.49: r = 1.040816, r^10 = 1.491904, h = 1/(1 + r^10) = 0.401300
worked, p = 0.49: 20 h = 8.025990, t = (10 - 20 h)/0.02 = 98.7005
figure, h by start k = 0, 2, ..., 20, p = 0.50: 0.00, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00
figure, h by start k = 0, 2, ..., 20, p = 0.49: 0.00, 0.07, 0.14, 0.22, 0.31, 0.40, 0.50, 0.61, 0.73, 0.86, 1.00
figure, first simulated fair game, chips every 4 rounds: 10, 12, 14, 12, 12, 14, 18, 16, 14, 14, 14, 12, 14, 14, 14, 12, 8, 6, 8, 12, 12, 10, 12, 12, 12, 12, 14, 18, 20
figure, that game ends at round 112 on 20; lowest 5, highest before the end 19
mistake, fair formula k/L used at p = 0.49: 0.5000 against 0.4013
mistake, ratio upside down, p/q for q/p: 0.5987
mistake, stake all 10 chips in one round at p = 0.49: simulated 0.4934 +- 0.0035, exact 0.4900
top wall moved up, fair, target 20: h = 0.5000, t = 100
top wall moved up, fair, target 30: h = 0.3333, t = 200
top wall moved up, fair, target 40: h = 0.2500, t = 300
top wall moved up, fair, target 80: h = 0.1250, t = 700
top wall moved up, fair, target 160: h = 0.0625, t = 1500
top wall moved up, fair, target 1000: h = 0.0100, t = 9900
top wall moved up, p = 0.51: h at target 1000 = 0.3297; limit 1 - (0.49/0.51)^10 = 0.3297
scale, 100 chips to 200 at 0.49: h = 0.0180, t = 4820.23
scale, 10 chips to 20 on red, 18/38: h = 0.2585, t = 91.76
ALL CHECKS PASS
```

The two outputs match line for line, including the simulated ones: the generator is the same integer arithmetic in both languages.

### Lean

Lean proves the formulas for $h_k$, ruin and $t_k$, for every start, target and win chance between 0 and 1.

- Suppose the rounds are independent, each won with chance $p$ between 0 and 1, and she starts with $k \le L$ chips. Then the chance of reaching $L$ before 0 is $k/L$ when $p = q$, and $(1 - r^k)/(1 - r^L)$ otherwise.
- Take the same game. Then the chance of reaching 0 first, ruin, is $1 - h_k$.
- Take the same game. Then it ends at a wall with chance 1, and $E[T]$ is finite.
- Take the same game. Then $E[T]$ is $k(L - k)$ when $p = q$, and $(k - L\,h_k)/(q - p)$ otherwise.
- Take any $p$ between 0 and 1. Then the chance equations of Step 2 have exactly one solution, the formula for $h_k$.
- From 10 chips to 20 at a fair table, the chance is 1/2 and the length is 10 × 10 = 100 rounds.
- Take the table at 0.49. Then the tilt $r$ is exactly 51/49, and the shortcut $h_{10} = 1/(1 + r^{10})$ holds.
- Take a fair table. Then $k(L - k)$ passes the check in Step 5, for every $k$ and $L$.
- Raise the fair target from 20 to 30, 40, 80, 160 and 1000. The chance from 10 chips falls to 1/3, 1/4, 1/8, 1/16 and 1/100.
- Over the same targets, the lengths are 200, 300, 700, 1500 and 9900 rounds.
- From 10 chips to 40 at a fair table, 40 × 1/4 = 10: the average chips at the end equal the start.

The decimals, the simulation, bold play and the limit with no top wall are left to the Python and Rust checks.

```lean
-- Gambler's ruin: betting one chip a round with win chance p, from k chips the chance of reaching L before 0 is k/L when fair and (1 - r^k)/(1 - r^L) with r = q/p otherwise, ruin has the rest of the chance, and the average game length is k(L - k) when fair and (k - L h_k)/(q - p) otherwise.
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib

open MeasureTheory ProbabilityTheory

/-! Setting. `Ω` with probability measure `μ`. Round `i + 1` is `ξ i ω` (`true` = she wins one
chip, `false` = she loses one chip). The rounds are independent and each is won with the same
chance `p`, with `0 < p < 1` and `q = 1 - p`. She starts with `k` chips, `0 ≤ k ≤ L`, and the walls
are the floor 0 and the target `L > 0`. -/

/-- The chips after the first `n` rounds, from a start of `k` chips, if she kept playing. -/
def chips {Ω : Type*} (k : ℕ) (ξ : ℕ → Ω → Bool) (n : ℕ) (ω : Ω) : ℤ :=
  (k : ℤ) + ∑ i ∈ Finset.range n, if ξ i ω then 1 else -1

/-- The round at which the game ends: the first `n` with the chips at 0 or at `L`. -/
noncomputable def exitRound {Ω : Type*} (k L : ℕ) (ξ : ℕ → Ω → Bool) (ω : Ω) : ℕ :=
  sInf {n : ℕ | chips k ξ n ω = 0 ∨ chips k ξ n ω = L}

/-- The card's formula `h_k`: `k/L` at a fair table (`p = q = 1/2`), and
`(1 - r^k)/(1 - r^L)` with `r = q/p` otherwise. -/
noncomputable def targetChance (p : ℝ) (L k : ℕ) : ℝ :=
  if p = 1 / 2 then (k : ℝ) / L else (1 - ((1 - p) / p) ^ k) / (1 - ((1 - p) / p) ^ L)

lemma gr_denom_ne {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) (hp : ¬ p = 1 / 2) {L : ℕ} (hL : 0 < L) :
    1 - ((1 - p) / p) ^ L ≠ 0 := by
  intro h
  have h1 : ((1 - p) / p) ^ L = 1 := by linarith
  rw [pow_eq_one_iff_of_nonneg (div_pos (by linarith) hp0).le hL.ne'] at h1
  rw [div_eq_one_iff_eq hp0.ne'] at h1
  exact hp (by linarith)

lemma gr_target_zero (p : ℝ) (L : ℕ) : targetChance p L 0 = 0 := by
  unfold targetChance; split_ifs <;> simp

lemma gr_target_L {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) {L : ℕ} (hL : 0 < L) :
    targetChance p L L = 1 := by
  unfold targetChance; split_ifs with h
  · have : (L : ℝ) ≠ 0 := by exact_mod_cast hL.ne'
    exact div_self this
  · exact div_self (gr_denom_ne hp0 hp1 h hL)

lemma gr_target_harm {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) (L : ℕ) (k : ℕ) (hk : 0 < k) :
    targetChance p L k = p * targetChance p L (k + 1) + (1 - p) * targetChance p L (k - 1) := by
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
  simp only [Nat.add_sub_cancel]
  unfold targetChance
  split_ifs with h
  · subst h; push_cast; ring
  · set r := (1 - p) / p with hr_def
    have hr : p * r = 1 - p := by rw [hr_def]; field_simp
    have key : p * r ^ (j + 1 + 1) + (1 - p) * r ^ j = r ^ (j + 1) := by
      linear_combination (r ^ (j + 1) - r ^ j) * hr
    rw [mul_div_assoc', mul_div_assoc', ← add_div]
    congr 1
    linear_combination key

/-- One round of the game, stopped once the chips are at a wall. -/
def grStep (L x : ℕ) (b : Bool) : ℕ :=
  if 0 < x ∧ x < L then (if b then x + 1 else x - 1) else x

/-- The game stopped at the walls, driven by a sequence of round results. -/
def grWalk (L k : ℕ) (b : ℕ → Bool) : ℕ → ℕ
  | 0 => k
  | n + 1 => grStep L (grWalk L k b n) (b n)

/-- The stopped chips after `n` rounds. -/
def grY {Ω : Type*} (L k : ℕ) (ξ : ℕ → Ω → Bool) (n : ℕ) (ω : Ω) : ℕ :=
  grWalk L k (fun i => ξ i ω) n

section walk
variable {Ω : Type*} {ξ : ℕ → Ω → Bool} {L k : ℕ}

lemma gr_chips_zero (ω : Ω) : chips k ξ 0 ω = k := by simp [chips]

lemma gr_chips_succ (n : ℕ) (ω : Ω) :
    chips k ξ (n + 1) ω = chips k ξ n ω + (if ξ n ω then 1 else -1) := by
  simp [chips, Finset.sum_range_succ, add_assoc]

lemma grWalk_congr (L k : ℕ) {b b' : ℕ → Bool} (n : ℕ) (h : ∀ i < n, b i = b' i) :
    grWalk L k b n = grWalk L k b' n := by
  induction n with
  | zero => rfl
  | succ n ih =>
    simp only [grWalk]; rw [ih (fun i hi => h i (by omega)), h n (by omega)]

lemma grY_succ (n : ℕ) (ω : Ω) : grY L k ξ (n + 1) ω = grStep L (grY L k ξ n ω) (ξ n ω) := rfl

lemma grY_zero (ω : Ω) : grY L k ξ 0 ω = k := rfl

lemma grY_le (hk : k ≤ L) (n : ℕ) (ω : Ω) : grY L k ξ n ω ≤ L := by
  induction n with
  | zero => simpa [grY_zero]
  | succ n ih =>
    rw [grY_succ, grStep]
    split_ifs <;> omega

lemma grY_absorb {n : ℕ} {ω : Ω} (h : ¬(0 < grY L k ξ n ω ∧ grY L k ξ n ω < L)) :
    ∀ m, n ≤ m → grY L k ξ m ω = grY L k ξ n ω := by
  intro m hm
  induction m, hm using Nat.le_induction with
  | base => rfl
  | succ m hm ih => rw [grY_succ, grStep, ih, if_neg h]

lemma grY_eq_chips {n : ℕ} {ω : Ω} (h : ∀ m < n, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L) :
    (grY L k ξ n ω : ℤ) = chips k ξ n ω := by
  induction n with
  | zero => simp [grY_zero, gr_chips_zero]
  | succ n ih =>
    have hn := h n (by omega)
    rw [grY_succ, gr_chips_succ, ← ih (fun m hm => h m (by omega)), grStep, if_pos hn]
    cases ξ n ω <;> simp <;> omega

lemma gr_pathA (hL : 0 < L) (hk : k ≤ L) (ω : Ω) :
    (∃ n, chips k ξ n ω = L ∧ ∀ m < n, 0 < chips k ξ m ω) ↔ ∃ n, grY L k ξ n ω = L := by
  classical
  constructor
  · rintro ⟨n, hn, hpos⟩
    have hex : ∃ n, chips k ξ n ω = L := ⟨n, hn⟩
    have hn0le : Nat.find hex ≤ n := Nat.find_min' hex hn
    have hlt : ∀ m < Nat.find hex, chips k ξ m ω < L := by
      intro m
      induction m with
      | zero =>
        intro h0
        have h1 := Nat.find_min hex h0
        have h2 := hpos 0 (by omega)
        rw [gr_chips_zero] at h1 h2 ⊢
        omega
      | succ m ih =>
        intro hm
        have h1 := Nat.find_min hex hm
        have h2 := ih (by omega)
        rw [gr_chips_succ] at h1 ⊢
        split_ifs at h1 ⊢ <;> omega
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m
      induction m using Nat.strong_induction_on with
      | _ m ih =>
        intro hm
        have e := grY_eq_chips (n := m) (fun j hj => ih j hj (by omega))
        have h1 := hpos m (by omega)
        have h2 := hlt m hm
        omega
    refine ⟨Nat.find hex, ?_⟩
    have e := grY_eq_chips hal
    have := Nat.find_spec hex
    omega
  · rintro ⟨n, hn⟩
    have hex : ∃ n, grY L k ξ n ω = L := ⟨n, hn⟩
    have hspec := Nat.find_spec hex
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m hm
      have h1 := Nat.find_min hex hm
      have hle := grY_le (ξ := ξ) hk m ω
      refine ⟨?_, by omega⟩
      by_contra h0
      have := grY_absorb (L := L) (k := k) (ξ := ξ) (n := m) (ω := ω) (by omega) (Nat.find hex) hm.le
      omega
    refine ⟨Nat.find hex, ?_, ?_⟩
    · have e := grY_eq_chips hal
      omega
    · intro m hm
      have e := grY_eq_chips (n := m) (fun j hj => hal j (by omega))
      have := hal m hm
      omega

lemma gr_pathB (hL : 0 < L) (hk : k ≤ L) (ω : Ω) :
    (∃ n, chips k ξ n ω = 0 ∧ ∀ m < n, chips k ξ m ω < L) ↔ ∃ n, grY L k ξ n ω = 0 := by
  classical
  constructor
  · rintro ⟨n, hn, hlt⟩
    have hex : ∃ n, chips k ξ n ω = 0 := ⟨n, hn⟩
    have hn0le : Nat.find hex ≤ n := Nat.find_min' hex hn
    have hpos : ∀ m < Nat.find hex, 0 < chips k ξ m ω := by
      intro m
      induction m with
      | zero =>
        intro h0
        have h1 := Nat.find_min hex h0
        rw [gr_chips_zero] at h1 ⊢
        omega
      | succ m ih =>
        intro hm
        have h1 := Nat.find_min hex hm
        have h2 := ih (by omega)
        rw [gr_chips_succ] at h1 ⊢
        split_ifs at h1 ⊢ <;> omega
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m
      induction m using Nat.strong_induction_on with
      | _ m ih =>
        intro hm
        have e := grY_eq_chips (n := m) (fun j hj => ih j hj (by omega))
        have h1 := hpos m hm
        have h2 := hlt m (by omega)
        omega
    refine ⟨Nat.find hex, ?_⟩
    have e := grY_eq_chips hal
    have := Nat.find_spec hex
    omega
  · rintro ⟨n, hn⟩
    have hex : ∃ n, grY L k ξ n ω = 0 := ⟨n, hn⟩
    have hspec := Nat.find_spec hex
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m hm
      have h1 := Nat.find_min hex hm
      have hle := grY_le (ξ := ξ) hk m ω
      refine ⟨by omega, ?_⟩
      by_contra h0
      have := grY_absorb (L := L) (k := k) (ξ := ξ) (n := m) (ω := ω) (by omega) (Nat.find hex) hm.le
      omega
    refine ⟨Nat.find hex, ?_, ?_⟩
    · have e := grY_eq_chips hal
      omega
    · intro m hm
      have e := grY_eq_chips (n := m) (fun j hj => hal j (by omega))
      have := hal m hm
      omega

lemma gr_pathC (hk : k ≤ L) (ω : Ω) (h : ∃ n, ¬(0 < grY L k ξ n ω ∧ grY L k ξ n ω < L)) :
    (chips k ξ (Nat.find h) ω = 0 ∨ chips k ξ (Nat.find h) ω = L) ∧
      exitRound k L ξ ω = Nat.find h ∧
      ∀ m, (0 < grY L k ξ m ω ∧ grY L k ξ m ω < L) ↔ m < Nat.find h := by
  have hal : ∀ m < Nat.find h, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
    intro m hm
    have := Nat.find_min h hm
    simpa using this
  have hN : chips k ξ (Nat.find h) ω = 0 ∨ chips k ξ (Nat.find h) ω = L := by
    have e := grY_eq_chips hal
    have h1 := Nat.find_spec h
    have h2 := grY_le (ξ := ξ) hk (Nat.find h) ω
    omega
  refine ⟨hN, ?_, ?_⟩
  · unfold exitRound
    apply le_antisymm (Nat.sInf_le hN)
    by_contra hlt0
    have hlt := not_le.mp hlt0
    have hmem := Nat.sInf_mem (s := {n : ℕ | chips k ξ n ω = 0 ∨ chips k ξ n ω = L}) ⟨_, hN⟩
    set m := sInf {n : ℕ | chips k ξ n ω = 0 ∨ chips k ξ n ω = L}
    have e := grY_eq_chips (n := m) (fun j hj => hal j (by omega))
    have := hal m hlt
    simp only [Set.mem_setOf_eq] at hmem
    omega
  · intro m
    constructor
    · intro hm
      by_contra hge0
      have hge := not_lt.mp hge0
      have := grY_absorb (L := L) (k := k) (ξ := ξ) (Nat.find_spec h) m hge
      rw [this] at hm
      exact Nat.find_spec h hm
    · exact hal m

end walk

/-- The card's average game length, as a function of the start. -/
noncomputable def grDur (p : ℝ) (L x : ℕ) : ℝ :=
  if p = 1 / 2 then (x : ℝ) * ((L : ℝ) - x) else ((x : ℝ) - L * targetChance p L x) / ((1 - p) - p)

lemma gr_dur_zero (p : ℝ) (L : ℕ) : grDur p L 0 = 0 := by
  unfold grDur; split_ifs <;> simp [gr_target_zero]

lemma gr_dur_L {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) {L : ℕ} (hL : 0 < L) : grDur p L L = 0 := by
  unfold grDur; split_ifs <;> simp [gr_target_L hp0 hp1 hL]

lemma gr_dur_harm {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) (L x : ℕ) (hx : 0 < x) :
    grDur p L x = 1 + p * grDur p L (x + 1) + (1 - p) * grDur p L (x - 1) := by
  obtain ⟨j, rfl⟩ : ∃ j, x = j + 1 := ⟨x - 1, by omega⟩
  have ht := gr_target_harm hp0 hp1 L (j + 1) (by omega)
  simp only [Nat.add_sub_cancel] at ht ⊢
  unfold grDur
  split_ifs with h
  · subst h; push_cast; ring
  · have hd : (1 - p) - p ≠ 0 := by intro h'; apply h; linarith
    field_simp
    push_cast
    linear_combination (-(L : ℝ)) * ht

section prob
variable {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
  {ξ : ℕ → Ω → Bool} {L k : ℕ}

lemma grY_measurable (hmeas : ∀ i, Measurable (ξ i)) (n : ℕ) : Measurable (grY L k ξ n) := by
  induction n with
  | zero => exact measurable_const
  | succ n ih =>
    have : grY L k ξ (n + 1) =
        (fun z : ℕ × Bool => grStep L z.1 z.2) ∘ (fun ω => (grY L k ξ n ω, ξ n ω)) := rfl
    rw [this]
    exact (measurable_of_countable _).comp (ih.prodMk (hmeas n))

lemma gr_integrable (hmeas : ∀ i, Measurable (ξ i)) (hk : k ≤ L) (Φ : ℕ → Bool → ℝ) (n : ℕ) :
    Integrable (fun ω => Φ (grY L k ξ n ω) (ξ n ω)) μ := by
  refine Integrable.of_bound ?_ (∑ x ∈ Finset.range (L + 1), (|Φ x true| + |Φ x false|))
    (ae_of_all _ fun ω => ?_)
  · exact ((measurable_of_countable (fun z : ℕ × Bool => Φ z.1 z.2)).comp
      ((grY_measurable hmeas n).prodMk (hmeas n))).aestronglyMeasurable
  · have hx : grY L k ξ n ω ∈ Finset.range (L + 1) :=
      Finset.mem_range.mpr (Nat.lt_succ_of_le (grY_le hk n ω))
    refine le_trans ?_ (Finset.single_le_sum (f := fun x => |Φ x true| + |Φ x false|)
      (fun x _ => by positivity) hx)
    rw [Real.norm_eq_abs]
    have h1 := abs_nonneg (Φ (grY L k ξ n ω) true)
    have h2 := abs_nonneg (Φ (grY L k ξ n ω) false)
    cases ξ n ω <;> linarith

lemma gr_measurableSet (hmeas : ∀ i, Measurable (ξ i)) (n : ℕ) (P : ℕ → Prop) :
    MeasurableSet {ω | P (grY L k ξ n ω)} :=
  (grY_measurable hmeas n) (Set.to_countable _).measurableSet

lemma gr_int_ind (hmeas : ∀ i, Measurable (ξ i)) (n : ℕ) (P : ℕ → Prop) [DecidablePred P] :
    ∫ ω, (if P (grY L k ξ n ω) then (1 : ℝ) else 0) ∂μ = μ.real {ω | P (grY L k ξ n ω)} := by
  rw [← integral_indicator_one (gr_measurableSet hmeas n P)]
  congr 1
  funext ω
  simp [Set.indicator]

lemma gr_indep (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) (n : ℕ) :
    IndepFun (grY L k ξ n) (ξ n) μ := by
  have hdisj : Disjoint (Finset.range n) {n} := by simp
  have h := hind.indepFun_finset (Finset.range n) {n} hdisj hmeas
  let F : (Finset.range n → Bool) → ℕ := fun v =>
    grWalk L k (fun i => if hi : i ∈ Finset.range n then v ⟨i, hi⟩ else false) n
  have h2 := h.comp (measurable_of_countable F)
    (measurable_pi_apply (⟨n, Finset.mem_singleton_self n⟩ : ({n} : Finset ℕ)))
  convert h2 using 1
  · funext ω
    simp only [Function.comp, F, grY]
    apply grWalk_congr
    intro i hi
    simp [hi]
  · rfl

lemma gr_step_int (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hk : k ≤ L) (Φ : ℕ → Bool → ℝ) (n : ℕ) :
    ∫ ω, Φ (grY L k ξ n ω) (ξ n ω) ∂μ =
      ∫ ω, (p * Φ (grY L k ξ n ω) true + (1 - p) * Φ (grY L k ξ n ω) false) ∂μ := by
  have hβ : ∫ ω, (if ξ n ω = true then (1 : ℝ) else 0) ∂μ = p := by
    rw [← hp n, ← integral_indicator_one (s := {ω | ξ n ω = true}) (hmeas n (measurableSet_singleton true))]
    congr 1
    funext ω
    simp [Set.indicator]
  have hβ' : ∫ ω, (1 - if ξ n ω = true then (1 : ℝ) else 0) ∂μ = 1 - p := by
    rw [integral_sub (integrable_const 1) (gr_integrable (k := k) hmeas hk
      (fun _ b => if b = true then (1 : ℝ) else 0) n), hβ]
    simp
  have hpt : ∀ ω, Φ (grY L k ξ n ω) (ξ n ω) =
      Φ (grY L k ξ n ω) true * (if ξ n ω = true then (1 : ℝ) else 0) +
        Φ (grY L k ξ n ω) false * (1 - if ξ n ω = true then (1 : ℝ) else 0) := by
    intro ω; cases ξ n ω <;> simp
  have hI := gr_indep (k := k) (L := L) hmeas hind n
  have i1 : IndepFun (fun ω => Φ (grY L k ξ n ω) true)
      (fun ω => if ξ n ω = true then (1 : ℝ) else 0) μ :=
    hI.comp (measurable_from_nat (f := fun x => Φ x true))
      (measurable_of_countable (fun b : Bool => if b = true then (1 : ℝ) else 0))
  have i2 : IndepFun (fun ω => Φ (grY L k ξ n ω) false)
      (fun ω => 1 - if ξ n ω = true then (1 : ℝ) else 0) μ :=
    hI.comp (measurable_from_nat (f := fun x => Φ x false))
      (measurable_of_countable (fun b : Bool => 1 - if b = true then (1 : ℝ) else 0))
  have m1 : AEStronglyMeasurable (fun ω => Φ (grY L k ξ n ω) true) μ :=
    (gr_integrable (k := k) hmeas hk (fun x _ => Φ x true) n).aestronglyMeasurable
  have m2 : AEStronglyMeasurable (fun ω => Φ (grY L k ξ n ω) false) μ :=
    (gr_integrable (k := k) hmeas hk (fun x _ => Φ x false) n).aestronglyMeasurable
  have m3 : AEStronglyMeasurable (fun ω => if ξ n ω = true then (1 : ℝ) else 0) μ :=
    (gr_integrable (k := k) hmeas hk (fun _ b => if b = true then (1 : ℝ) else 0) n).aestronglyMeasurable
  have m4 : AEStronglyMeasurable (fun ω => 1 - if ξ n ω = true then (1 : ℝ) else 0) μ :=
    (gr_integrable (k := k) hmeas hk (fun _ b => 1 - if b = true then (1 : ℝ) else 0) n).aestronglyMeasurable
  rw [integral_congr_ae (ae_of_all _ hpt)]
  rw [integral_add (gr_integrable (k := k) hmeas hk
      (fun x b => Φ x true * (if b = true then (1 : ℝ) else 0)) n)
    (gr_integrable (k := k) hmeas hk
      (fun x b => Φ x false * (1 - if b = true then (1 : ℝ) else 0)) n)]
  rw [i1.integral_fun_mul_eq_mul_integral m1 m3, i2.integral_fun_mul_eq_mul_integral m2 m4, hβ, hβ']
  rw [integral_add (gr_integrable (k := k) hmeas hk (fun x _ => p * Φ x true) n)
    (gr_integrable (k := k) hmeas hk (fun x _ => (1 - p) * Φ x false) n),
    integral_const_mul, integral_const_mul]
  ring

lemma gr_identity (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hk : k ≤ L) (f : ℕ → ℝ) (c : ℝ)
    (hf : ∀ x, 0 < x → x < L → f x = c + p * f (x + 1) + (1 - p) * f (x - 1)) (n : ℕ) :
    ∫ ω, f (grY L k ξ n ω) ∂μ +
      c * ∑ m ∈ Finset.range n, μ.real {ω | 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L} = f k := by
  induction n with
  | zero => simp [grY_zero]
  | succ n ih =>
    rw [Finset.sum_range_succ, ← ih]
    have h1 := gr_step_int hmeas hind hp hk (fun x b => f (grStep L x b)) n
    have h2 : ∀ x, p * f (grStep L x true) + (1 - p) * f (grStep L x false) =
        f x - c * (if 0 < x ∧ x < L then (1 : ℝ) else 0) := by
      intro x
      by_cases hx : 0 < x ∧ x < L
      · rw [show grStep L x true = x + 1 by simp [grStep, hx],
          show grStep L x false = x - 1 by simp [grStep, hx], if_pos hx, hf x hx.1 hx.2]
        ring
      · rw [show grStep L x true = x by simp [grStep, hx],
          show grStep L x false = x by simp [grStep, hx], if_neg hx]
        ring
    simp only [h2] at h1
    have h3 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => 0 < x ∧ x < L)
    have h1' : ∫ ω, f (grY L k ξ (n + 1) ω) ∂μ =
        ∫ ω, (f (grY L k ξ n ω) - c * (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then (1 : ℝ) else 0)) ∂μ :=
      h1
    rw [h1', integral_sub (gr_integrable (k := k) hmeas hk (fun x _ => f x) n)
      (gr_integrable (k := k) hmeas hk (fun x _ => c * (if 0 < x ∧ x < L then (1 : ℝ) else 0)) n),
      integral_const_mul, h3]
    ring

lemma gr_middle (hmeas : ∀ i, Measurable (ξ i)) (hk : k ≤ L)
    (hdecay : Filter.Tendsto (fun n => μ.real {ω | 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L})
      Filter.atTop (nhds 0)) (f : ℕ → ℝ) :
    Filter.Tendsto (fun n => ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L
      then f (grY L k ξ n ω) else 0) ∂μ) Filter.atTop (nhds 0) := by
  set M := ∑ x ∈ Finset.range (L + 1), |f x|
  have hb : ∀ n, ‖∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L
      then f (grY L k ξ n ω) else 0) ∂μ‖ ≤
      M * μ.real {ω | 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} := by
    intro n
    have h3 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => 0 < x ∧ x < L)
    rw [← h3, ← integral_const_mul]
    refine norm_integral_le_of_norm_le
      (gr_integrable (k := k) hmeas hk (fun x _ => M * (if 0 < x ∧ x < L then (1 : ℝ) else 0)) n)
      (ae_of_all _ fun ω => ?_)
    have hx : grY L k ξ n ω ∈ Finset.range (L + 1) :=
      Finset.mem_range.mpr (Nat.lt_succ_of_le (grY_le hk n ω))
    have := Finset.single_le_sum (f := fun x => |f x|) (fun x _ => abs_nonneg _) hx
    split_ifs
    · simpa using this
    · simp
  refine squeeze_zero_norm hb ?_
  simpa using hdecay.const_mul M

lemma gr_decay (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hk : k ≤ L) :
    Filter.Tendsto (fun n => μ.real {ω | 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L})
      Filter.atTop (nhds 0) := by
  set M := ∑ x ∈ Finset.range (L + 1), |grDur p L x|
  set f : ℕ → ℝ := fun x => grDur p L x + M with hfdef
  have hf : ∀ x, 0 < x → x < L → f x = 1 + p * f (x + 1) + (1 - p) * f (x - 1) := by
    intro x hx _
    simp only [hfdef]
    rw [gr_dur_harm hp0 hp1 L x hx]
    ring
  have hid := gr_identity hmeas hind hp hk f 1 hf
  have hnonneg : ∀ n, 0 ≤ ∫ ω, f (grY L k ξ n ω) ∂μ := fun n =>
    integral_nonneg (fun ω => by
      show (0 : ℝ) ≤ f (grY L k ξ n ω)
      have hx : grY L k ξ n ω ∈ Finset.range (L + 1) :=
        Finset.mem_range.mpr (Nat.lt_succ_of_le (grY_le hk n ω))
      have h1 := Finset.single_le_sum (f := fun x => |grDur p L x|) (fun x _ => abs_nonneg _) hx
      have h2 := neg_abs_le (grDur p L (grY L k ξ n ω))
      simp only [hfdef]
      linarith)
  have hsum : Summable (fun m => μ.real {ω | 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L}) :=
    summable_of_sum_range_le (c := f k) (fun m => measureReal_nonneg) (fun n => by
      have := hid n; have := hnonneg n; linarith)
  exact hsum.tendsto_atTop_zero

lemma gr_boundary (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hL : 0 < L)
    (hk : k ≤ L) (f : ℕ → ℝ)
    (hf : ∀ x, 0 < x → x < L → f x = p * f (x + 1) + (1 - p) * f (x - 1)) :
    Filter.Tendsto (fun n => f 0 * μ.real {ω | grY L k ξ n ω = 0} +
      f L * μ.real {ω | grY L k ξ n ω = L}) Filter.atTop (nhds (f k)) := by
  have hid := gr_identity hmeas hind hp hk f 0 (fun x hx hxL => by rw [hf x hx hxL]; ring)
  have hmid := gr_middle hmeas hk (gr_decay hmeas hind hp0 hp1 hp hk) f
  have heq : ∀ n, f 0 * μ.real {ω | grY L k ξ n ω = 0} + f L * μ.real {ω | grY L k ξ n ω = L} =
      f k - ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then f (grY L k ξ n ω) else 0) ∂μ := by
    intro n
    have hdec : ∀ ω, f (grY L k ξ n ω) =
        f 0 * (if grY L k ξ n ω = 0 then (1 : ℝ) else 0) +
          f L * (if grY L k ξ n ω = L then (1 : ℝ) else 0) +
          (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then f (grY L k ξ n ω) else 0) := by
      intro ω
      have hle := grY_le (ξ := ξ) hk n ω
      generalize grY L k ξ n ω = y at hle ⊢
      by_cases h0 : y = 0
      · subst h0; simp [hL.ne]
      · by_cases h1 : y = L
        · subst h1; simp [h0]
        · have h2 : 0 < y ∧ y < L := ⟨by omega, by omega⟩
          simp [h0, h1, h2]
    have e1 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => x = 0)
    have e2 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => x = L)
    have hI : ∫ ω, f (grY L k ξ n ω) ∂μ = f 0 * μ.real {ω | grY L k ξ n ω = 0} +
        f L * μ.real {ω | grY L k ξ n ω = L} +
        ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then f (grY L k ξ n ω) else 0) ∂μ := by
      rw [integral_congr_ae (ae_of_all _ hdec),
        integral_add (by
          exact (gr_integrable (k := k) hmeas hk
            (fun x _ => f 0 * (if x = 0 then (1 : ℝ) else 0)) n).add
            (gr_integrable (k := k) hmeas hk (fun x _ => f L * (if x = L then (1 : ℝ) else 0)) n))
          (gr_integrable (k := k) hmeas hk
            (fun x _ => if 0 < x ∧ x < L then f x else 0) n),
        integral_add (gr_integrable (k := k) hmeas hk
            (fun x _ => f 0 * (if x = 0 then (1 : ℝ) else 0)) n)
            (gr_integrable (k := k) hmeas hk (fun x _ => f L * (if x = L then (1 : ℝ) else 0)) n),
        integral_const_mul, integral_const_mul, e1, e2]
    have := hid n
    simp only [zero_mul, add_zero] at this
    linarith
  refine Filter.Tendsto.congr (fun n => (heq n).symm) ?_
  simpa using (tendsto_const_nhds (x := f k)).sub hmid

end prob

#print axioms gr_denom_ne
#print axioms gr_target_zero
#print axioms gr_target_L
#print axioms gr_target_harm
#print axioms grStep
#print axioms grWalk
#print axioms grY
#print axioms gr_chips_zero
#print axioms gr_chips_succ
#print axioms grWalk_congr
#print axioms grY_succ
#print axioms grY_zero
#print axioms grY_le
#print axioms grY_absorb
#print axioms grY_eq_chips
#print axioms gr_pathA
#print axioms gr_pathB
#print axioms gr_pathC
#print axioms grDur
#print axioms gr_dur_zero
#print axioms gr_dur_L
#print axioms gr_dur_harm
#print axioms grY_measurable
#print axioms gr_integrable
#print axioms gr_measurableSet
#print axioms gr_int_ind
#print axioms gr_indep
#print axioms gr_step_int
#print axioms gr_identity
#print axioms gr_middle
#print axioms gr_decay
#print axioms gr_boundary

/-- Gambler's ruin. Betting one chip a round on independent rounds, each won with the same
chance `p`, from `k` chips (between 0 and the target `L`): the chance of reaching `L` before 0 is
`k/L` at a fair table and `(1 - r^k)/(1 - r^L)` with `r = q/p` otherwise, and the chance of
reaching 0 first (ruin) is 1 minus that. -/
theorem chance_reach_target_before_floor
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (ξ : ℕ → Ω → Bool) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ)
    (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p)
    (L k : ℕ) (hL : 0 < L) (hk : k ≤ L) :
    μ.real {ω | ∃ n, chips k ξ n ω = L ∧ ∀ m < n, 0 < chips k ξ m ω} = targetChance p L k ∧
      μ.real {ω | ∃ n, chips k ξ n ω = 0 ∧ ∀ m < n, chips k ξ m ω < L} = 1 - targetChance p L k := by
  have hbA := gr_boundary hmeas hind hp0 hp1 hp hL hk (targetChance p L)
    (fun x hx _ => gr_target_harm hp0 hp1 L x hx)
  have hbB := gr_boundary hmeas hind hp0 hp1 hp hL hk (fun x => 1 - targetChance p L x)
    (fun x hx _ => by rw [gr_target_harm hp0 hp1 L x hx]; ring)
  simp only [gr_target_zero, gr_target_L hp0 hp1 hL, zero_mul, one_mul, zero_add, sub_zero,
    sub_self, add_zero] at hbA hbB
  have hmonoL : Monotone (fun n => {ω | grY L k ξ n ω = L}) := by
    intro a b hab ω hω
    simp only [Set.mem_setOf_eq] at hω ⊢
    rw [grY_absorb (by omega) b hab, hω]
  have hmono0 : Monotone (fun n => {ω | grY L k ξ n ω = 0}) := by
    intro a b hab ω hω
    simp only [Set.mem_setOf_eq] at hω ⊢
    rw [grY_absorb (by omega) b hab, hω]
  have hlimA := (ENNReal.tendsto_toReal (measure_ne_top μ _)).comp
    (tendsto_measure_iUnion_atTop (μ := μ) hmonoL)
  have hlimB := (ENNReal.tendsto_toReal (measure_ne_top μ _)).comp
    (tendsto_measure_iUnion_atTop (μ := μ) hmono0)
  have hsetA : {ω | ∃ n, chips k ξ n ω = L ∧ ∀ m < n, 0 < chips k ξ m ω} =
      ⋃ n, {ω | grY L k ξ n ω = L} := by
    ext ω
    simp only [Set.mem_setOf_eq, Set.mem_iUnion]
    exact gr_pathA hL hk ω
  have hsetB : {ω | ∃ n, chips k ξ n ω = 0 ∧ ∀ m < n, chips k ξ m ω < L} =
      ⋃ n, {ω | grY L k ξ n ω = 0} := by
    ext ω
    simp only [Set.mem_setOf_eq, Set.mem_iUnion]
    exact gr_pathB hL hk ω
  refine ⟨?_, ?_⟩
  · rw [hsetA]; exact tendsto_nhds_unique hlimA hbA
  · rw [hsetB]; exact tendsto_nhds_unique hlimB hbB


/-- The expected length. In the same game, play ends at 0 or `L` with chance 1, the number of
rounds `T` has a finite average, and that average is `k(L - k)` at a fair table and
`(k - L h_k)/(q - p)` otherwise. -/
theorem expected_rounds_until_a_wall
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (ξ : ℕ → Ω → Bool) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ)
    (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p)
    (L k : ℕ) (hL : 0 < L) (hk : k ≤ L) :
    (∀ᵐ ω ∂μ, ∃ n, chips k ξ n ω = 0 ∨ chips k ξ n ω = L) ∧
      Integrable (fun ω => (exitRound k L ξ ω : ℝ)) μ ∧
      ∫ ω, (exitRound k L ξ ω : ℝ) ∂μ =
        if p = 1 / 2 then (k : ℝ) * ((L : ℝ) - k)
        else ((k : ℝ) - L * targetChance p L k) / ((1 - p) - p) := by
  have hdecay := gr_decay hmeas hind hp0 hp1 hp hk
  set A : ℕ → Set Ω := fun m => {ω | 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L} with hA
  have hnull : μ {ω | ∀ n, 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} = 0 := by
    have hle : ∀ n, μ.real {ω | ∀ n, 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} ≤ μ.real (A n) :=
      fun n => measureReal_mono (fun ω hω => hω n)
    have h0 : μ.real {ω | ∀ n, 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} ≤ 0 :=
      ge_of_tendsto' hdecay hle
    exact (measureReal_eq_zero_iff).mp (le_antisymm h0 measureReal_nonneg)
  have hae : ∀ᵐ ω ∂μ, ∃ n, ¬(0 < grY L k ξ n ω ∧ grY L k ξ n ω < L) := by
    rw [ae_iff]
    refine measure_mono_null (fun ω hω => ?_) hnull
    simp only [Set.mem_setOf_eq, not_exists, not_not] at hω ⊢
    exact hω
  have hD := gr_identity hmeas hind hp hk (grDur p L) 1
    (fun x hx _ => gr_dur_harm hp0 hp1 L x hx)
  have hmid := gr_middle hmeas hk hdecay (grDur p L)
  have hDeq : ∀ n, ∫ ω, grDur p L (grY L k ξ n ω) ∂μ =
      ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then grDur p L (grY L k ξ n ω) else 0) ∂μ := by
    intro n
    congr 1
    funext ω
    have hle := grY_le (ξ := ξ) hk n ω
    split_ifs with h
    · rfl
    · rcases (show grY L k ξ n ω = 0 ∨ grY L k ξ n ω = L by omega) with h' | h' <;> rw [h']
      · exact gr_dur_zero p L
      · exact gr_dur_L hp0 hp1 hL
  have htend : Filter.Tendsto (fun n => ∑ m ∈ Finset.range n, μ.real (A m)) Filter.atTop
      (nhds (grDur p L k)) := by
    have e : ∀ n, ∑ m ∈ Finset.range n, μ.real (A m) = grDur p L k -
        ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then grDur p L (grY L k ξ n ω) else 0) ∂μ := by
      intro n
      have := hD n
      rw [hDeq] at this
      simp only [hA]
      linarith
    refine Filter.Tendsto.congr (fun n => (e n).symm) ?_
    simpa using (tendsto_const_nhds (x := grDur p L k)).sub hmid
  have hsum : HasSum (fun m => μ.real (A m)) (grDur p L k) :=
    (hasSum_iff_tendsto_nat_of_nonneg (fun m => measureReal_nonneg) _).mpr htend
  have hDk : 0 ≤ grDur p L k := hsum.nonneg (fun m => measureReal_nonneg)
  have hAmeas : ∀ m, MeasurableSet (A m) := fun m =>
    gr_measurableSet hmeas m (fun x => 0 < x ∧ x < L)
  have hT : ∀ᵐ ω ∂μ, (exitRound k L ξ ω : ENNReal) = ∑' m, (A m).indicator 1 ω := by
    filter_upwards [hae] with ω h
    obtain ⟨-, hex, hiff⟩ := gr_pathC hk ω h
    rw [hex]
    have e : ∀ m, (A m).indicator (1 : Ω → ENNReal) ω = if m < Nat.find h then 1 else 0 := by
      intro m
      by_cases hm : m < Nat.find h
      · rw [if_pos hm]
        exact Set.indicator_of_mem (show ω ∈ A m from (hiff m).mpr hm) _
      · rw [if_neg hm]
        exact Set.indicator_of_notMem (show ω ∉ A m from fun h' => hm ((hiff m).mp h')) _
    simp_rw [e]
    rw [tsum_eq_sum (s := Finset.range (Nat.find h)) (fun m hm => by
      rw [Finset.mem_range] at hm; rw [if_neg hm])]
    rw [Finset.sum_congr rfl (fun m hm => if_pos (Finset.mem_range.mp hm))]
    simp
  have hmeasT : AEMeasurable (fun ω => (exitRound k L ξ ω : ENNReal)) μ :=
    (Measurable.ennreal_tsum (fun m => measurable_one.indicator (hAmeas m))).aemeasurable.congr
      (hT.mono fun ω h => h.symm)
  have hlin : ∫⁻ ω, (exitRound k L ξ ω : ENNReal) ∂μ = ENNReal.ofReal (grDur p L k) := by
    rw [lintegral_congr_ae hT,
      lintegral_tsum (fun m => (measurable_one.indicator (hAmeas m)).aemeasurable)]
    simp_rw [lintegral_indicator_one (hAmeas _)]
    rw [← hsum.tsum_eq, ENNReal.ofReal_tsum_of_nonneg (fun m => measureReal_nonneg) hsum.summable]
    congr 1
    funext m
    exact (ofReal_measureReal).symm
  have hcast : (fun ω => (exitRound k L ξ ω : ℝ)) = fun ω => ((exitRound k L ξ ω : ENNReal)).toReal := by
    funext ω; simp
  refine ⟨?_, ?_, ?_⟩
  · filter_upwards [hae] with ω h
    exact ⟨_, (gr_pathC hk ω h).1⟩
  · rw [hcast]
    exact integrable_toReal_of_lintegral_ne_top hmeasT (by rw [hlin]; exact ENNReal.ofReal_ne_top)
  · rw [hcast, integral_toReal hmeasT (ae_of_all _ fun ω => by simp), hlin, ENNReal.toReal_ofReal hDk]
    rfl

/-- The first-step equations have exactly one solution, the card's formula: a list of numbers
`h_0, …, h_L` satisfies `h_k = p h_{k+1} + q h_{k-1}` for `0 < k < L` with `h_0 = 0` and
`h_L = 1` exactly when each `h_k` equals `k/L` (fair) or `(1 - r^k)/(1 - r^L)` (tilted). -/
theorem first_step_equations_solution_unique
    (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (L : ℕ) (hL : 0 < L) (h : ℕ → ℝ) :
    (h 0 = 0 ∧ h L = 1 ∧ ∀ k, 0 < k → k < L → h k = p * h (k + 1) + (1 - p) * h (k - 1)) ↔
      ∀ k ≤ L, h k = targetChance p L k := by
  constructor
  · rintro ⟨h0, hL1, hrec⟩
    set g : ℕ → ℝ := fun k => h k - targetChance p L k with hg
    have e0 : g 0 = 0 := by simp [hg, h0, gr_target_zero]
    have eL : g L = 0 := by simp [hg, hL1, gr_target_L hp0 hp1 hL]
    have erec : ∀ k, 0 < k → k < L → p * g (k + 1) = g k - (1 - p) * g (k - 1) := by
      intro k hk hkL
      simp only [hg]
      rw [hrec k hk hkL, gr_target_harm hp0 hp1 L k hk]; ring
    set r := (1 - p) / p with hr_def
    have hr : p * r = 1 - p := by rw [hr_def]; field_simp
    set S : ℕ → ℝ := fun k => ∑ i ∈ Finset.range k, r ^ i with hS
    have Srec : ∀ k, p * S (k + 2) = S (k + 1) - (1 - p) * S k := by
      intro k
      simp only [hS, Finset.sum_range_succ]
      linear_combination r ^ k * hr
    have key : ∀ k, k + 1 ≤ L → g k = g 1 * S k ∧ g (k + 1) = g 1 * S (k + 1) := by
      intro k
      induction k with
      | zero => intro _; simp [hS, e0]
      | succ k ih =>
        intro hk
        obtain ⟨ih1, ih2⟩ := ih (by omega)
        refine ⟨ih2, ?_⟩
        have e := erec (k + 1) (by omega) (by omega)
        simp only [Nat.add_sub_cancel] at e
        have hp' : p ≠ 0 := hp0.ne'
        apply mul_left_cancel₀ hp'
        rw [e, ih1, ih2]
        have := Srec k
        linear_combination (-(g 1)) * this
    have rpos : 0 < r := div_pos (by linarith) hp0
    have SLpos : 0 < S L := by
      simp only [hS]
      apply Finset.sum_pos (fun i _ => pow_pos rpos i)
      exact ⟨0, by simp [hL]⟩
    have g1 : g 1 = 0 := by
      have := (key (L - 1) (by omega)).2
      rw [Nat.sub_add_cancel hL, eL] at this
      rcases mul_eq_zero.mp this.symm with h1 | h1
      · exact h1
      · exact absurd h1 SLpos.ne'
    intro k hk
    rcases eq_or_lt_of_le hk with rfl | hlt
    · have := eL; simp only [hg] at this; linarith
    · have := (key k (by omega)).1
      rw [g1, zero_mul] at this
      simp only [hg] at this; linarith
  · intro H
    refine ⟨by rw [H 0 (Nat.zero_le _), gr_target_zero], by rw [H L le_rfl, gr_target_L hp0 hp1 hL],
      fun k hk hkL => ?_⟩
    rw [H k hkL.le, H (k + 1) hkL, H (k - 1) (by omega)]
    exact gr_target_harm hp0 hp1 L k hk

-- Fair table, 10 chips, target 20: chance 10/20 = 1/2 and 10 × 10 = 100 rounds.
example : ((10 : ℚ) / 20 = 1 / 2) ∧ 10 * (20 - 10) = 100 := by norm_num
-- At 49 in 100 the tilt is r = 0.51/0.49 = 51/49.
example : ((1 : ℚ) - 49 / 100) / (49 / 100) = 51 / 49 := by norm_num
-- The shortcut when the target is twice the start: (1 - r^10)/(1 - r^20) = 1/(1 + r^10).
example : ((1 : ℚ) - (51 / 49) ^ 10) / (1 - (51 / 49) ^ 20) = 1 / (1 + (51 / 49) ^ 10) := by
  norm_num
-- The fair duration check: (1/2)(k+1)(L-k-1) + (1/2)(k-1)(L-k+1) = k(L-k) - 1.
example (k L : ℚ) :
    (1 / 2) * (k + 1) * (L - k - 1) + (1 / 2) * (k - 1) * (L - k + 1) = k * (L - k) - 1 := by
  ring
-- Moving the top wall up, fair, from 10 chips: chances 10/30, 10/40, 10/80, 10/160, 10/1000.
example : ((10 : ℚ) / 30 = 1 / 3) ∧ ((10 : ℚ) / 40 = 1 / 4) ∧ ((10 : ℚ) / 80 = 1 / 8) ∧
    ((10 : ℚ) / 160 = 1 / 16) ∧ ((10 : ℚ) / 1000 = 1 / 100) := by norm_num
-- … and lengths 10(L - 10): 200, 300, 700, 1500, 9900 rounds.
example : 10 * (30 - 10) = 200 ∧ 10 * (40 - 10) = 300 ∧ 10 * (80 - 10) = 700 ∧
    10 * (160 - 10) = 1500 ∧ 10 * (1000 - 10) = 9900 := by norm_num
-- Fair from 10 chips to 40: the average chips at the end equal the start, 40 × 1/4 = 10.
example : (40 : ℚ) * (1 / 4) = 10 := by norm_num

#print axioms chance_reach_target_before_floor
#print axioms expected_rounds_until_a_wall
#print axioms first_step_equations_solution_unique
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'gr_denom_ne' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_target_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_target_L' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_target_harm' depends on axioms: [propext, Classical.choice, Quot.sound]
'grStep' does not depend on any axioms
'grWalk' does not depend on any axioms
'grY' does not depend on any axioms
'gr_chips_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_chips_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'grWalk_congr' depends on axioms: [propext, Quot.sound]
'grY_succ' does not depend on any axioms
'grY_zero' does not depend on any axioms
'grY_le' depends on axioms: [propext, Quot.sound]
'grY_absorb' does not depend on any axioms
'grY_eq_chips' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_pathA' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_pathB' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_pathC' depends on axioms: [propext, Classical.choice, Quot.sound]
'grDur' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_dur_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_dur_L' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_dur_harm' depends on axioms: [propext, Classical.choice, Quot.sound]
'grY_measurable' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_integrable' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_measurableSet' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_int_ind' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_indep' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_step_int' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_identity' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_middle' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_decay' depends on axioms: [propext, Classical.choice, Quot.sound]
'gr_boundary' depends on axioms: [propext, Classical.choice, Quot.sound]
'chance_reach_target_before_floor' depends on axioms: [propext, Classical.choice, Quot.sound]
'expected_rounds_until_a_wall' depends on axioms: [propext, Classical.choice, Quot.sound]
'first_step_equations_solution_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A higher target.** Set `L` to 30. Guess the fair chance from 10 chips. It is 0.3333 with 200 rounds, as the top-wall rows show. The run then stops at the mass-flow length assert: the longer game leaves about 8 in 100 million of its chance unresolved after 3000 rounds. Raise the 3000 in the `mass_flow` call to 6000 and it stops at the shortcut assert instead, because $1/(1 + r^{10})$ holds only when the target is twice the start.
> - **Turn the tilt round.** Change the first loop to `(0.5, 0.51)`. The chance becomes 0.5987 and the length stays 98.7005: the game at 0.51 from 10 is the game at 0.49 seen upside down.
> - **Fewer games.** Set `GAMES` to 2000. The standard errors grow by a factor of about the square root of 10, and the simulated numbers wander further from the formulas while staying within the 4-standard-error asserts.
> - **Break the formula.** Swap `r = q / p` for `r = p / q`. The first assert stops the run at 0.49: elimination knows nothing of the formula and disagrees.

---

## The usual mistake

> [!warning]
> **Reading a small edge as a small cost.** One point per round sounds like a one-point loss. It is not: the edge acts on every round, and the evening is about 99 rounds long. At 10 chips to 20 it takes the chance from 50 to 40 percent. Scale the bankroll up to 100 chips with a target of 200 and the same one-point edge leaves a chance of 0.0180, under 2 percent, over a game about 4820 rounds long. The longer the game, the more surely the tilt wins.
>
> - **"Fair means an even chance."** Only from halfway. From 10 chips with a target of 40 the fair chance is 0.25: the average chips at the end still equal the start, 40 × 0.25 = 10, but the likely outcome is ruin. Fair never means she cannot win, and never means she is likely to.
> - **Reading the expected length as a typical length.** The pictured fair game took 112 rounds against an average of 100, and the simulated average, 100.80 ± 0.58, carries its own error; single games vary widely around it.
> - **Using $k(L - k)$ at a tilted table.** It gives 100, against 98.7005; the tilted duration needs $h_k$.

---

## Where you meet it in real life

- **Casino bankrolls.** A bet on red at an American roulette wheel wins with chance 18/38. From 10 chips to 20, one chip a spin, the chance of doubling is 0.2585, over about 91.76 spins.
- **Sequential testing.** A test that stops when a running score first crosses one of two thresholds is a walk between two walls; its error rates are chances of hitting the wrong wall first.
- **Electrical networks.** Hold node 0 at 0 volts and node 20 at 1 volt along a chain of equal resistors: the voltage at node k solves the same averaging equation, so it equals $h_k$ at a fair table ([Random walks as circuits](../../14-Applied%20and%20computational/07-Network%20Science%20and%20Spectral%20Graphs/08-random-walks-and-electrical-networks.md)).
- **Insurance.** An insurer's surplus rising with premiums and falling with claims faces the same question with one wall, ruin, and the tilted-table limit of Step 6 is its first model.

> **Say it back**
> A gambler betting one chip a round stops at 0 or at the target. The first round sends her one chip up or down, and the game restarts from there, so the chance of reaching the target satisfies a chain of averaging equations with 0 and 1 at the walls. The steps between neighbouring chances multiply by the tilt q/p, which gives k/L at a fair table and (1 − r^k)/(1 − r^L) otherwise. The expected length solves the same equations with one round added each time: k(L − k) when fair. From 10 chips to 20, that is 50 percent in 100 rounds at a fair table, and 40 percent in about 99 rounds at 49 percent a round.

---

## What this builds on

- [Simple random walk](02-simple-random-walk.md): the walk that moves one step up or down each round, here stopped at two walls.
- [First-order recurrences](../../04-Combinatorics%20and%20graphs/05-Recurrences/03-first-order-recurrences-and-loans.md): the recurrence $d_{k+1} = r\,d_k$ and its geometric sum.

## Where this goes next

- [Hitting times](06-first-passage-and-hitting-times.md): the whole law of the first-passage time to one level, why the fair walk returns for sure, and why the mean wait is infinite.
- [Random walks as circuits](../../14-Applied%20and%20computational/07-Network%20Science%20and%20Spectral%20Graphs/08-random-walks-and-electrical-networks.md): the chance of hitting one wall first as a voltage, on any graph.

What this card leaves open: with only one wall, how fast the chance of still waiting shrinks round by round, and whether a fair walk always comes back to where it started.

---

## Sources

Verified 2026-09-30: every link below resolves to the publisher's page or to a copy the authors host.

- Feller, William. *An Introduction to Probability Theory and Its Applications*, Volume 1, 3rd ed. Wiley, 1968. [Publisher page](https://www.wiley.com/en-us/An+Introduction+to+Probability+Theory+and+Its+Applications%2C+Volume+1%2C+3rd+Edition-p-9780471257080). Chapter XIV, random walk and ruin problems: the chance and duration equations solved by difference equations, and the limit of an infinitely rich adversary.
- Grinstead, Charles M., and J. Laurie Snell. *Introduction to Probability*, 2nd revised ed. American Mathematical Society, 1997. [Full text](https://math.dartmouth.edu/~prob/prob/prob.pdf). Section 12.2, gambler's ruin, at the level of this card.
- Norris, J. R. *Markov Chains*. Cambridge University Press, 1997. [Publisher page](https://www.cambridge.org/core/books/markov-chains/A3F966B10633A32C8F06F37158031739). Section 1.3: hitting probabilities as the smallest solution of the first-step equations, with gambler's ruin as the worked example.
- Levin, David A., Yuval Peres, and Elizabeth L. Wilmer. *Markov Chains and Mixing Times*, 2nd ed. American Mathematical Society, 2017. [Authors' page](https://pages.uoregon.edu/dlevin/MARKOV/). Section 2.1: gambler's ruin, the chance and the expected duration k(L − k) by the same argument.
