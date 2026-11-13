# American options: exercise any day, so the price is the best stopping rule, found by working backwards

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [American and Bermudan exercise](../README.md#s15) → American options

---

## General Overview

Acme trades at $100.00. A put on Acme is the right, not the duty, to sell one share for $100.00, the **strike**, within one year. The European put allows the sale on the last day only, and costs $6.33. The American put allows it on any day of the year. Same share, same strike, same year. It costs $6.66.

The extra 33 cents buys one thing: the choice of day. The holder watches Acme and may sell early when that looks better than waiting. The choice has to be made with what is known on the day. Nobody may sell today on the strength of next month's price.

A plan of that kind is a **stopping rule**: an instruction that, looking only at what Acme has done so far, says "sell now" or "wait". "Never sell early" is one rule. "Sell the first time Acme touches $80.00" is another.

Each rule has a price, found the European way: average its payoff over the market's futures, discounted back to today. The American put is worth the price of the best rule. No holder can do better than the best rule, and the seller must be ready for a holder who uses it.

**An American option is worth the most that any stopping rule can collect from it, and the best rule is found by comparing "exercise now" with "wait" at every point, working backwards from expiry.**

**What kind of fact this is:** a definition, the price as a best stopping rule, carrying two theorems proved on this card in Why it works: the backward walk finds that best rule, and American call and put prices obey a parity band instead of an equation.

### The picture: every rule is a lower bound

Nine stopping rules for the house put, each priced exactly on the same 2,000-step tree. "Sell at or below L" means sell the first time Acme is at or below that level while the put pays something.

```
stopping rule                              price of the rule
never sell early (European)        █████████████████████████████████   $6.3291
sell at or below $70               ██████████████████████████████████  $6.3948
sell at or below $75               ██████████████████████████████████  $6.4789
sell at or below $80               ███████████████████████████████████ $6.5935
sell at or below $82               ███████████████████████████████████ $6.6129
sell at or below $85               ███████████████████████████████████ $6.5606
sell at or below $90               ███████████████████████████████     $5.9275
sell as soon as the put pays       ██                                  $0.4374
best rule: compare at every node   ███████████████████████████████████ $6.6602
```

Each bar is the price of one plan. A low level waits too long. A high level sells too eagerly and throws away the chance of a bigger fall. The best whole-dollar level, $82, reaches $6.61 and still falls short of $6.66. The best rule does not stick to one level: it sells at a level that rises as expiry approaches ([The exercise boundary and smooth pasting](04-exercise-boundary-and-smooth-pasting.md)).

---

## The formula

Notation first, in words. A stopping rule picks a date, and the date depends on how Acme moves, so it is a random date; its letter is $\tau$, said "tau".

$\mathbb{E}^{\mathbb{Q}}$ is the **risk-neutral average**: the average over Acme's futures in the pricing world where every asset grows at the riskless rate, as on [Black-Scholes put](../08-The%20Black-Scholes%20call%20and%20put/02-black-scholes-put.md).

The word $\sup$, "supremum", means the best value over a whole family, here every stopping rule; it equals the largest value when a largest exists.

$$V_0 \;=\; \sup_{\tau\ \text{a stopping rule},\ 0 \le \tau \le T}\; \mathbb{E}^{\mathbb{Q}}\!\left[\,e^{-r\tau}\,g(S_\tau)\,\right]$$

**Read it aloud:** the American option is worth the best, over every rule for picking the day, of the average discounted payoff that rule collects.

For the put the payoff is $g(S) = \max(K - S,\,0)$: the strike minus the share price when that is positive, zero otherwise. For the call it is $\max(S - K,\,0)$.

A node is one point on a tree: one possible Acme price on one date. On a tree of $N$ steps the supremum becomes a backward walk, the method of [Early exercise](../04-Binomial%20Trees/05-american-exercise-on-a-tree.md):

$$V_{\text{node}} \;=\; \max\Big(\,g(S_{\text{node}}),\;\; e^{-r\Delta t}\big[\,p\,V_{\text{up}} + (1-p)\,V_{\text{down}}\,\big]\Big)$$

**Read it aloud:** at every node, take the larger of the payoff now and the discounted average of the two values one step ahead.

The American call and put are tied by a band, not an equation:

$$S e^{-qT} - K \;\le\; C_A - P_A \;\le\; S - K e^{-rT}$$

**Read it aloud:** the American call minus the American put lies between the dividend-shrunk share minus the full strike and the full share minus the discounted strike.

The proof of the band's left half also gives a cap on what the right to choose the day can be worth:

$$P_A - P_E \;\le\; K\,(1 - e^{-rT})$$

**Read it aloud:** the early-exercise premium is at most the strike less its discounted value: the interest the strike earns over the option's life, in today's money.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $S$, $S_t$ | Acme's price today; its price at time $t$ | $100.00 | put cheaper, call dearer |
| $K$ | the strike: the price the put may sell at | $100.00 | put dearer |
| $r$, $e^{-rT}$ | the riskless rate, continuously compounded; the discount on a dollar due at $T$ | 5% | early exercise pays more for a put: premium 0.897825 at 10% (500 steps) |
| $q$ | the dividend yield Acme pays out, per year | 2% | put dearer; at 0 the American put is 6.088810 (500 steps) |
| $\sigma$ | volatility: how jumpy Acme is. Say "sigma". | 20% | both prices rise |
| $T$, $t$ | the option's life in years; a moment within it | 1 year | more time: more rules to choose among |
| $N$, $n$, $\Delta t$, $u$, $p$ | tree steps; a date on the tree; one step's length $T/N$; the up factor $e^{\sigma\sqrt{\Delta t}}$; the risk-neutral weight on up | 2,000 steps; see Worked numbers | more steps: closer to the true price |
| $g$ | the payoff function: what exercising pays at a given price | $\max(K - S, 0)$ for the put | — |
| $\tau$, $L$ | a stopping rule's random date; a fixed selling level in a simple rule | "first time at or below $82" | — |
| $\mathbb{E}^{\mathbb{Q}}$ | the risk-neutral average over Acme's futures | — | — |
| $V_0$, $V_n$, $W_n$, $\sup$ | the price today; the backward-walk value and the best-rule value on date $n$; the best value over all rules | 6.660226 | — |
| $P_A$, $C_A$, $P_E$, $C_E$ | American put and call; European put and call | 6.660226, 9.226034; 6.330081, 9.227006 | — |

$\Delta t = T/N$, $u = e^{\sigma\sqrt{\Delta t}}$, down factor $1/u$, and $p = (e^{(r-q)\Delta t} - 1/u)/(u - 1/u)$ are the Cox–Ross–Rubinstein settings of [Cox-Ross-Rubinstein](../04-Binomial%20Trees/04-crr-tree-and-convergence.md), used unchanged.

### When it holds

- **Rules may look back, never forward.** A rule that saw tomorrow's price would sell at the exact bottom; no seller could hedge that "price".
- **A holder who never errs.** The price is what the seller must be funded for against the best holder. A holder who follows a worse rule collects less: $6.61 with the best whole-dollar level, $0.44 by selling as soon as the put pays.
- **Constant rate, yield and volatility, and geometric Brownian motion for Acme.** Geometric Brownian motion means Acme moves in small random percentage steps whose spread never changes. The definition needs none of this; the numbers do. Let volatility move and the best rule moves with it.
- **Exercise settles at once, with no fee.** A fee lowers the payoff side of every comparison and shrinks the premium.
- **The parity band needs only no free money.** It holds in any model, with any volatility, as long as the dividend is a yield paid while the share is held and the rate is not negative.

---

## Why it works

### Step 0: a price must cover the best rule and need not cover more

Two arguments pin the price from both sides.

From below: the holder may use any stopping rule. Whatever rule the holder picks, the seller must pay out its payoff. So the seller must charge at least the price of every rule, and so at least the supremum.

From above: a seller who takes in the supremum can hedge, trading shares and cash so that the account covers the payoff on whatever day the holder exercises. The account never runs short, because at every moment it holds at least what exercising pays and at least what waiting is worth. A seller charging more could be undercut by a rival who charges the supremum, hedges, and never runs short.

The object that does this, the smallest process that sits above the payoff and, once discounted, never drifts upward in the pricing world, is the **Snell envelope**. Its construction and the proof that it equals the supremum are on [Optimal stopping](../../11-Stochastic%20processes%20and%20calculus/08-Generators%2C%20Densities%20and%20Simulation/07-optimal-stopping-and-snell-envelope.md). This card uses the result.

### Step 1: on a tree, the rules can be listed

On a tree the futures are finite, so the stopping rules are finite too. A two-step tree for the house put, six months a step, has three rules worth distinguishing: sell today (worth nothing, since Acme is at the strike), never sell early, and sell after a first fall. Worked numbers prices each one. Never selling early is worth 5.445368; selling after a fall is worth 6.200042. The larger is the tree's American price.

Past a handful of steps the list explodes: a rule is a yes-or-no at every node, and a 2,000-step tree has about two million nodes.

### Step 2: the backward walk finds the best rule

On the last date every rule collects the payoff, so the best value there is the payoff. One step earlier, any rule either stops, collecting the payoff, or continues, collecting at most the discounted average of the best values one step ahead.

So no rule beats the larger of those two numbers, and the rule "take the larger here, then play best" reaches it. Repeat to the root: the root value is the best over all rules, found without listing one.

<details>
<summary>Detailed proof: backward induction equals the supremum on a tree</summary>

Number the dates $0, 1, \dots, N$. Write $W_n$ for the best value, at a node on date $n$, over rules that have not yet stopped: the supremum over rules taking values in dates $n$ to $N$. Claim: $W_n$ equals the backward-walk value $V_n$ at every node.

Date $N$: every rule stops at $N$, so $W_N = g(S_N) = V_N$.

Suppose $W_{n+1} = V_{n+1}$ at every node of date $n+1$. Take any rule $\tau$ with $\tau \ge n$. On the event $\tau = n$ it collects $g(S_n)$. On the event $\tau > n$ it is a rule starting from date $n+1$, so from each next node it collects at most $W_{n+1} = V_{n+1}$; its value at date $n$ is at most $e^{-r\Delta t}[\,p V_{\text{up}} + (1-p) V_{\text{down}}\,]$. The decision "stop at $n$ or not" is known at date $n$, so the value of $\tau$ is at most the larger of the two numbers, $V_n$. Hence $W_n \le V_n$.

The rule "stop at $n$ if $g(S_n)$ is the larger, otherwise follow the best rule from $n+1$" collects exactly $V_n$. Hence $W_n \ge V_n$, and $W_n = V_n$. At $n = 0$ this is the claim of the card.

</details>

### Step 3: two rules give two floors

"Never sell early" is one of the rules, so the American put is worth at least the European put, and the **early-exercise premium** $P_A - P_E$ is never negative. "Sell now" is another rule, so the American put is worth at least its payoff today. A European put can fall below its payoff: its holder may not cash in.

### Step 4: why a put ever wants the cash early

Push Acme toward zero. The put then pays almost the full strike, whichever day it is exercised. Exercise now and the $100.00 goes into the bank and earns 5% for the rest of the year. Wait, and the same $100.00 arrives later. Deep enough, the interest beats the small chance of a further fall.

That is the whole premium, and it is an interest-rate story: at a zero rate there is nothing to collect by hurrying, and the American and European prices agree exactly, 8.912076 both on a 500-step tree.

For a call the logic runs the other way: exercising pays the strike early and gives up its interest. With no dividend the American call is never exercised early, which is [Merton's theorem](02-mertons-no-early-exercise-theorem.md). With Acme's 2% yield the right is worth something, but only in futures far above today's price: the tree prices it at 0.034101 millionths of a dollar. To every printed digit, the American call equals its European twin.

### Step 5: the parity band

Put–call parity, $C_E - P_E = S e^{-qT} - K e^{-rT}$, is an equation for European options ([Put-call parity](../08-The%20Black-Scholes%20call%20and%20put/03-put-call-parity.md)). Its proof holds both options to the end. Once either side may exercise early, the proof fails and only a band survives.

Each half compares two portfolios, one never worth less than the other on whatever day an exercise happens: an American put plus a share against an American call plus discounted cash for the upper half, a European call plus the full strike in cash against an American put plus a dividend-shrunk share for the lower. The folded proof runs both.

The lower half, rearranged with parity for the European options, says $P_A - P_E \le K(1 - e^{-rT})$. That is Step 4 in one line: the right to choose the day is worth at most a year's interest on the strike, $4.88 here. The house put collects $0.33 of it.

<details>
<summary>Detailed proof: the two halves of the band</summary>

**Upper half, $C_A - P_A \le S - K e^{-rT}$.** Portfolio I: one American put and one share, dividends kept as cash. Portfolio II: one American call and $K e^{-rT}$ in the bank. Let the holder of II exercise the call at any date $t$. Then II is worth $(S_t - K) + K e^{-r(T-t)} \le S_t$, since $K e^{-r(T-t)} \le K$. Portfolio I is worth at least $S_t$ at that moment, since the put is worth at least zero. If the call is never exercised, at $T$ II is worth $\max(S_T - K, 0) + K = \max(S_T, K)$ and I is worth at least $\max(K - S_T, 0) + S_T = \max(K, S_T)$. So I is worth at least II in every case, and today $P_A + S \ge C_A + K e^{-rT}$.

**Lower half, $C_A - P_A \ge S e^{-qT} - K$.** Portfolio III: one European call and $K$ in the bank. Portfolio IV: one American put and $e^{-qT}$ shares, dividends reinvested so the holding grows to one share at $T$. Let IV's put be exercised at date $t$. Then IV is worth $(K - S_t) + e^{-q(T-t)} S_t \le K$, and III is worth at least $K e^{rt} \ge K$. If the put is never exercised, at $T$ IV is worth $\max(K - S_T, 0) + S_T = \max(K, S_T)$ and III is worth $\max(S_T - K, 0) + K e^{rT} \ge \max(S_T, K)$. So $C_E + K \ge P_A + S e^{-qT}$. With $C_A \ge C_E$ (Step 3, for the call) this gives $C_A - P_A \ge S e^{-qT} - K$.

**The premium cap.** From $C_E + K \ge P_A + S e^{-qT}$ and European parity $C_E = P_E + S e^{-qT} - K e^{-rT}$: $P_E + K - K e^{-rT} \ge P_A$, so $P_A - P_E \le K(1 - e^{-rT})$.

</details>

### Step 6: more steps, more rules, a higher price

A tree of $N$ steps lets the holder exercise on $N + 1$ dates, not on any day. That makes it a Bermudan option ([Bermudan options](03-bermudan-options.md)). Doubling the steps keeps every old date and adds new ones, so every old rule is still available and the best can only improve.

The tree also refines its picture of Acme at the same time, which wiggles the price by the tree's own error. On the sequence 50, 100, 200, 500, 1,000, 2,000 steps the American price climbs every time: 6.641549 to 6.660226.

The climb has a limit, and two roads estimate it. The tree's error for the European put halves each time the steps double, so twice the 2,000-step price minus the 1,000-step price cancels most of it: 6.330081 for the European, the closed form (the Black–Scholes formula) to six decimals, and 6.660692 for the American.

A second machine, a grid that solves [The Black-Scholes equation](../08-The%20Black-Scholes%20call%20and%20put/07-black-scholes-equation.md) with the payoff as a floor, gives 6.660608. That equation is the rule every option price obeys as time passes; the grid steps it backwards from expiry. The two roads agree to a hundredth of a cent. The 2,000-step tree sits about four hundredths of a cent below the limit.

---

## Worked numbers, by hand

A two-step tree for the house put: $S = K = 100$, $r = 5\%$, $q = 2\%$, $\sigma = 20\%$, $T = 1$, $N = 2$, so $\Delta t = 0.5$. Every rule is priced by hand.

| Step | Arithmetic | Value |
| --- | --- | --- |
| up factor $u$ | $e^{0.20 \times \sqrt{0.5}}$ | 1.151910 |
| weight on up, $p$ | $(e^{0.03 \times 0.5} - 1/u)/(u - 1/u)$ | 0.517959 |
| one-step discount | $e^{-0.05 \times 0.5}$ | 0.975310 |
| Acme after a fall | $100 / 1.151910$ | 86.812345 |
| Acme after two falls | $86.812345 / 1.151910$ | 75.363832 |
| payoff after two falls | $100 - 75.363832$ | 24.636168 |
| after a fall: wait | $0.975310 \times (1 - 0.517959) \times 24.636168$ | 11.582444 |
| after a fall: sell now | $100 - 86.812345$ | 13.187655 |
| rule "never sell early" | $0.975310 \times (1 - 0.517959) \times 11.582444$ | 5.445368 |
| rule "sell after a fall" | $0.975310 \times (1 - 0.517959) \times 13.187655$ | 6.200042 |
| **best rule = tree with max** | larger of the two | **6.200042** |

After a rise every later node pays nothing, so the up branch contributes zero to every line. The backward walk makes one comparison, after a fall: selling, 13.187655, beats waiting, 11.582444. The tree price is the "sell after a fall" rule, as Step 2 promised. Two steps is crude; 2,000 steps give 6.660226.

The house numbers, from the 2,000-step tree and the closed forms:

| Step | Arithmetic | Value |
| --- | --- | --- |
| American put $P_A$ | tree, 2,000 steps | 6.660226 |
| European put $P_E$ | closed form | 6.330081 |
| **premium** | $6.660226 - 6.330081$ | **0.330145** |
| premium cap | $100 \times (1 - e^{-0.05})$ | 4.877058 |
| American call $C_A$ | tree, 2,000 steps | 9.226034 |
| band, lower | $100 e^{-0.02} - 100$ | −1.980133 |
| $C_A - P_A$ | $9.226034 - 6.660226$ | 2.565808 |
| band, upper | $100 - 100 e^{-0.05}$ | 4.877058 |
| European $C - P$, for comparison | $9.227006 - 6.330081$ | 2.896925 |

The right to choose the day adds 33 cents to a $6.33 put, about 5%, against a ceiling of $4.88. The American difference, 2.565808, sits inside the band and below the European 2.896925: the put gains from early exercise and the call barely does. The band's upper edge equals the premium cap here only because $S = K$.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drop the max: value the put as European on the tree | 6.329109 | the holder's choice of day is thrown away; 33 cents missing |
| Exercise as soon as the put pays anything | 0.437372 | sells at the first dip, $99.55, for 45 cents, giving up every larger fall |
| Stick to one selling level, the best whole-dollar one, $82 | 6.612919 | the best level rises toward expiry; a fixed one is 4.7 cents short |
| Forget the 2% dividend (500 steps) | 6.088810 | the dividend drags Acme down, which a put holder gains from |
| Stop the tree at 50 steps | 6.641549 | 51 exercise dates are a Bermudan; 1.9 cents short of 2,000 steps |

Every number in that table is printed by both checks.

---

## Code, from first principles, and it actually runs

The code prices the house put three independent ways.

- Road 1 is the Cox–Ross–Rubinstein tree with the max at every node.
- Road 2 is a grid on the logarithm of Acme's price that steps the Black–Scholes equation back in time by the Crank–Nicolson scheme and imposes the payoff as a floor with the Brennan–Schwartz sweep: no tree, no coin flips. Crank–Nicolson averages the old and new slopes in each time step. Brennan–Schwartz solves each step in one sweep up from the lowest price, lifting any value below the payoff up to it.
- Road 3 prices fixed stopping rules on the tree, each a lower bound that must fall short of Road 1.

The European put comes from the closed form, with a normal curve area built by Simpson's rule (adding up thin slices under the bell curve), no error function imported. The asserts check tree against grid, both machines against the closed-form European, every fixed rule against the best, the parity band, the climb with steps, and the zero-rate case.

### Python

```python
# American put: the price is the best stopping rule, found by working backwards.
# Standard library only. Roads: (1) CRR tree with a max at every node, (2) a
# Crank-Nicolson grid solved by Brennan-Schwartz, (3) fixed stopping rules on the
# same tree, each a lower bound. Our own normal CDF (Simpson), no erf.
from math import exp, log, sqrt, pi

def ncdf(x, n=2000):                        # area under the bell curve left of x
    if x < 0: return 1.0 - ncdf(-x, n)
    h = x / n; f = lambda z: exp(-0.5 * z * z)
    s = f(0.0) + f(x) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))
    return 0.5 + s * h / 3.0 / sqrt(2.0 * pi)

def bs(S, K, r, q, sig, T):                 # European call and put, closed form
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
    c = S * exp(-q * T) * ncdf(d1) - K * exp(-r * T) * ncdf(d2)
    p = K * exp(-r * T) * ncdf(-d2) - S * exp(-q * T) * ncdf(-d1)
    return c, p

def tree(S, K, r, q, sig, T, N, call=False, rule="best", level=0.0):
    # rule: "best" = max at every node; "never" = European; "level" = exercise
    # the first time Acme is at or below `level` (and the put pays something)
    dt = T / N; u = exp(sig * sqrt(dt)); p = (exp((r - q) * dt) - 1 / u) / (u - 1 / u)
    a, b = exp(-r * dt) * p, exp(-r * dt) * (1 - p)
    w = 1.0 if call else -1.0
    v = [max(w * (S * u ** (2 * j - N) - K), 0.0) for j in range(N + 1)]
    for n in range(N - 1, -1, -1):
        v = [b * v[j] + a * v[j + 1] for j in range(n + 1)]
        if rule == "never": continue
        for j in range(n + 1):
            s = S * u ** (2 * j - n); g = w * (s - K)
            if rule == "best":
                if g > v[j]: v[j] = g
            elif s <= level and g > 0: v[j] = g
    return v[0]

def grid(S, K, r, q, sig, T, M=2400, NT=2000, american=True):
    # Crank-Nicolson in x = ln S (two implicit first steps), Brennan-Schwartz for the max
    dx, dt = 3.0 / M, T / NT; x0 = log(S) - 1.5
    Sx = [exp(x0 + i * dx) for i in range(M + 1)]
    g = [max(K - s, 0.0) for s in Sx]; v = g[:]
    nu = r - q - 0.5 * sig * sig
    al = 0.5 * sig * sig / dx / dx - 0.5 * nu / dx
    ga = 0.5 * sig * sig / dx / dx + 0.5 * nu / dx
    be = -sig * sig / dx / dx - r
    for k in range(1, NT + 1):
        th = 1.0 if k <= 2 else 0.5; tau = k * dt
        A, B, C = -th * dt * al, 1 - th * dt * be, -th * dt * ga
        R = [0.0] * (M + 1)
        for i in range(1, M):
            R[i] = v[i] + (1 - th) * dt * (al * v[i - 1] + be * v[i] + ga * v[i + 1])
        lo = g[0] if american else K * exp(-r * tau) - Sx[0] * exp(-q * tau)
        Bp, Rp = [0.0] * (M + 1), [0.0] * (M + 1)
        Bp[M - 1], Rp[M - 1] = B, R[M - 1]
        for i in range(M - 2, 0, -1):
            f = C / Bp[i + 1]; Bp[i] = B - f * A; Rp[i] = R[i] - f * Rp[i + 1]
        new = [0.0] * (M + 1); new[0] = lo
        for i in range(1, M):
            new[i] = (Rp[i] - A * new[i - 1]) / Bp[i]
            if american and g[i] > new[i]: new[i] = g[i]
        v = new
    return v[M // 2]

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
N = 2000
ce, pe = bs(S, K, r, q, sig, T)
PA, PEt = tree(S, K, r, q, sig, T, N), tree(S, K, r, q, sig, T, N, rule="never")
CA, CEt = tree(S, K, r, q, sig, T, N, call=True), tree(S, K, r, q, sig, T, N, call=True, rule="never")
PAg, PEg = grid(S, K, r, q, sig, T), grid(S, K, r, q, sig, T, american=False)
PA1 = tree(S, K, r, q, sig, T, 1000); PE1 = tree(S, K, r, q, sig, T, 1000, rule="never")
rows = [("European put, closed form", pe), ("European call, closed form", ce),
        ("1 American put, tree 2000", PA), ("  European put, same tree", PEt),
        ("  limit, 2 x tree 2000 - tree 1000", 2 * PA - PA1), ("  same for the European", 2 * PEt - PE1),
        ("2 American put, grid", PAg), ("  European put, same grid", PEg),
        ("premium, tree 2000 - closed form", PA - pe), ("premium, like for like on tree", PA - PEt),
        ("premium, like for like on grid", PAg - PEg),
        ("American call, tree 2000", CA), ("  European call, same tree", CEt),
        ("  call difference x 1e6", (CA - CEt) * 1e6)]
lo, hi = S * exp(-q * T) - K, S - K * exp(-r * T)
rows += [("parity lower  S e^-qT - K", lo), ("  C_A - P_A", CA - PA), ("parity upper  S - K e^-rT", hi),
         ("  European C - P", ce - pe), ("premium cap  K(1 - e^-rT)", K * (1 - exp(-r * T)))]
# two-step tree by hand
dt = T / 2; u = exp(sig * sqrt(dt)); d = 1 / u; p = (exp((r - q) * dt) - d) / (u - d); D = exp(-r * dt)
Sd, Sdd = S * d, S * d * d
hold_d = D * (1 - p) * (K - Sdd)             # after a rise, every later node pays nothing
rows += [("2-step: u", u), ("2-step: p", p), ("2-step: one-step discount", D), ("2-step: Acme after a fall", Sd),
         ("2-step: after two falls", Sdd), ("2-step: payoff after two falls", K - Sdd), ("2-step: hold after a fall", hold_d),
         ("2-step: exercise after a fall", K - Sd), ("2-step: rule 'never'", D * (1 - p) * hold_d),
         ("2-step: rule 'sell after a fall'", D * (1 - p) * (K - Sd)), ("2-step: tree with max", tree(S, K, r, q, sig, T, 2))]
for name, val in rows: print(f"{name:<34} {val:>12.6f}")
print("stopping rules on the 2000-step tree: exercise first time Acme <= L")
best_rule = 0.0
for L in (70.0, 75.0, 80.0, 82.0, 85.0, 90.0, 99.99):
    val = tree(S, K, r, q, sig, T, N, rule="level", level=L); best_rule = max(best_rule, val)
    print(f"  L = {L:6.2f}   {val:10.6f}")
print("convergence: American put, European put, gap to closed form")
steps = (50, 100, 200, 500, 1000, 2000)
am = [tree(S, K, r, q, sig, T, n) for n in steps[:-2]] + [PA1, PA]
for n, a_ in zip(steps, am):
    e_ = tree(S, K, r, q, sig, T, n, rule="never")
    print(f"  N = {n:5d}   {a_:10.6f}   {e_:10.6f}   {e_ - pe:+.6f}")
tries = [("try r = 0: American", tree(S, K, 0.0, q, sig, T, 500)), ("try r = 0: European", tree(S, K, 0.0, q, sig, T, 500, rule="never")),
         ("try r = 10%: premium", tree(S, K, 0.10, q, sig, T, 500) - tree(S, K, 0.10, q, sig, T, 500, rule="never")),
         ("try q = 0: American put", tree(S, K, r, 0.0, sig, T, 500)),
         ("try sigma = 40%: premium", tree(S, K, r, q, 0.4, T, 500) - tree(S, K, r, q, 0.4, T, 500, rule="never"))]
for name, val in tries: print(f"{name:<34} {val:>12.6f}")
assert abs(pe - 6.330080627550) < 1e-9, "own normal CDF reproduces the house put"
assert abs(PA - PAg) < 0.001 and abs(2 * PA - PA1 - PAg) < 2e-4, "tree and grid agree on the American put"
assert abs(PEt - pe) < 0.002 and abs(PEg - pe) < 0.002, "both machines price the European put"
assert best_rule < PA, "no fixed level beats the best stopping rule"
assert lo < CA - PA < hi and CA - PA < ce - pe, "American parity band, below European parity"
assert all(a2 > a1 for a1, a2 in zip(am, am[1:])), "the tree price climbs as steps grow"
assert abs(tries[0][1] - tries[1][1]) < 1e-9, "no rate, no reason to sell early"
print("ALL CHECKS PASS")
```

**Ran 2026-09-24 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
European put, closed form              6.330081
European call, closed form             9.227006
1 American put, tree 2000              6.660226
  European put, same tree              6.329109
  limit, 2 x tree 2000 - tree 1000     6.660692
  same for the European                6.330081
2 American put, grid                   6.660608
  European put, same grid              6.330044
premium, tree 2000 - closed form       0.330145
premium, like for like on tree         0.331117
premium, like for like on grid         0.330565
American call, tree 2000               9.226034
  European call, same tree             9.226034
  call difference x 1e6                0.034101
parity lower  S e^-qT - K             -1.980133
  C_A - P_A                            2.565808
parity upper  S - K e^-rT              4.877058
  European C - P                       2.896925
premium cap  K(1 - e^-rT)              4.877058
2-step: u                              1.151910
2-step: p                              0.517959
2-step: one-step discount              0.975310
2-step: Acme after a fall             86.812345
2-step: after two falls               75.363832
2-step: payoff after two falls        24.636168
2-step: hold after a fall             11.582444
2-step: exercise after a fall         13.187655
2-step: rule 'never'                   5.445368
2-step: rule 'sell after a fall'       6.200042
2-step: tree with max                  6.200042
stopping rules on the 2000-step tree: exercise first time Acme <= L
  L =  70.00     6.394784
  L =  75.00     6.478945
  L =  80.00     6.593496
  L =  82.00     6.612919
  L =  85.00     6.560609
  L =  90.00     5.927474
  L =  99.99     0.437372
convergence: American put, European put, gap to closed form
  N =    50     6.641549     6.291300   -0.038781
  N =   100     6.651030     6.310665   -0.019416
  N =   200     6.655974     6.320367   -0.009714
  N =   500     6.658816     6.326194   -0.003887
  N =  1000     6.659759     6.328137   -0.001944
  N =  2000     6.660226     6.329109   -0.000972
try r = 0: American                    8.912076
try r = 0: European                    8.912076
try r = 10%: premium                   0.897825
try q = 0: American put                6.088810
try sigma = 40%: premium               0.373495
ALL CHECKS PASS
```

Tree and grid agree to four hundredths of a cent; their limit estimates, to a hundredth. The grid's European put misses the closed form by four thousandths of a cent, so the grid is the sharper machine here.

### Rust

The same checks in Rust, std only. The tree walks the same nodes; the grid solves the same equations. Outputs agree line for line.

```rust
// American put: the price is the best stopping rule, found by working backwards.
// Rust std only, no crates. Same three roads as the Python check: (1) CRR tree
// with a max at every node, (2) a Crank-Nicolson grid solved by Brennan-Schwartz,
// (3) fixed stopping rules on the same tree. Own normal CDF (Simpson), no erf.
use std::f64::consts::PI;

fn ncdf(x: f64) -> f64 {                     // area under the bell curve left of x
    if x < 0.0 { return 1.0 - ncdf(-x); }
    let n = 2000; let h = x / n as f64;
    let f = |z: f64| (-0.5 * z * z).exp();
    let mut acc = 0.0;
    for i in 1..n { acc += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h); }
    0.5 + (f(0.0) + f(x) + acc) * h / 3.0 / (2.0 * PI).sqrt()
}

fn bs(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    let c = s * (-q * t).exp() * ncdf(d1) - k * (-r * t).exp() * ncdf(d2);
    let p = k * (-r * t).exp() * ncdf(-d2) - s * (-q * t).exp() * ncdf(-d1);
    (c, p)
}

#[derive(Clone, Copy, PartialEq)]
enum Rule { Best, Never, Level(f64) }

fn tree(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, n: usize, call: bool, rule: Rule) -> f64 {
    let dt = t / n as f64; let u = (sig * dt.sqrt()).exp();
    let p = (((r - q) * dt).exp() - 1.0 / u) / (u - 1.0 / u);
    let (a, b) = ((-r * dt).exp() * p, (-r * dt).exp() * (1.0 - p));
    let w = if call { 1.0 } else { -1.0 };
    let node = |j: usize, m: usize| s * u.powf(2.0 * j as f64 - m as f64);
    let mut v: Vec<f64> = (0..=n).map(|j| (w * (node(j, n) - k)).max(0.0)).collect();
    for m in (0..n).rev() {
        v = (0..=m).map(|j| b * v[j] + a * v[j + 1]).collect();
        if rule == Rule::Never { continue; }
        for j in 0..=m {
            let sn = node(j, m); let g = w * (sn - k);
            match rule {
                Rule::Best => { if g > v[j] { v[j] = g; } }
                Rule::Level(l) => { if sn <= l && g > 0.0 { v[j] = g; } }
                Rule::Never => {}
            }
        }
    }
    v[0]
}

fn grid(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, american: bool) -> f64 {
    // Crank-Nicolson in x = ln S (two implicit first steps), Brennan-Schwartz for the max
    let (m, nt) = (2400usize, 2000usize);
    let (dx, dt) = (3.0 / m as f64, t / nt as f64); let x0 = s.ln() - 1.5;
    let sx: Vec<f64> = (0..=m).map(|i| (x0 + i as f64 * dx).exp()).collect();
    let g: Vec<f64> = sx.iter().map(|&y| (k - y).max(0.0)).collect();
    let mut v = g.clone();
    let nu = r - q - 0.5 * sig * sig;
    let al = 0.5 * sig * sig / dx / dx - 0.5 * nu / dx;
    let ga = 0.5 * sig * sig / dx / dx + 0.5 * nu / dx;
    let be = -sig * sig / dx / dx - r;
    for step in 1..=nt {
        let th = if step <= 2 { 1.0 } else { 0.5 }; let tau = step as f64 * dt;
        let (aa, bb, cc) = (-th * dt * al, 1.0 - th * dt * be, -th * dt * ga);
        let mut rr = vec![0.0; m + 1];
        for i in 1..m { rr[i] = v[i] + (1.0 - th) * dt * (al * v[i - 1] + be * v[i] + ga * v[i + 1]); }
        let lo = if american { g[0] } else { k * (-r * tau).exp() - sx[0] * (-q * tau).exp() };
        let (mut bp, mut rp) = (vec![0.0; m + 1], vec![0.0; m + 1]);
        bp[m - 1] = bb; rp[m - 1] = rr[m - 1];
        for i in (1..m - 1).rev() { let f = cc / bp[i + 1]; bp[i] = bb - f * aa; rp[i] = rr[i] - f * rp[i + 1]; }
        let mut new = vec![0.0; m + 1]; new[0] = lo;
        for i in 1..m {
            new[i] = (rp[i] - aa * new[i - 1]) / bp[i];
            if american && g[i] > new[i] { new[i] = g[i]; }
        }
        v = new;
    }
    v[m / 2]
}

fn main() {
    let (s, k, r, q, sig, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let n = 2000;
    let (ce, pe) = bs(s, k, r, q, sig, t);
    let tr = |r: f64, q: f64, sig: f64, n: usize, call: bool, rule: Rule| tree(s, k, r, q, sig, t, n, call, rule);
    let (pa, pet) = (tr(r, q, sig, n, false, Rule::Best), tr(r, q, sig, n, false, Rule::Never));
    let (ca, cet) = (tr(r, q, sig, n, true, Rule::Best), tr(r, q, sig, n, true, Rule::Never));
    let (pag, peg) = (grid(s, k, r, q, sig, t, true), grid(s, k, r, q, sig, t, false));
    let (pa1, pe1) = (tr(r, q, sig, 1000, false, Rule::Best), tr(r, q, sig, 1000, false, Rule::Never));
    let (lo, hi) = (s * (-q * t).exp() - k, s - k * (-r * t).exp());
    let dt = t / 2.0; let u = (sig * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d); let dd = (-r * dt).exp();
    let (sd, sdd) = (s * d, s * d * d);
    let hold_d = dd * (1.0 - p) * (k - sdd);     // after a rise, every later node pays nothing
    let rows: Vec<(&str, f64)> = vec![
        ("European put, closed form", pe), ("European call, closed form", ce),
        ("1 American put, tree 2000", pa), ("  European put, same tree", pet),
        ("  limit, 2 x tree 2000 - tree 1000", 2.0 * pa - pa1), ("  same for the European", 2.0 * pet - pe1),
        ("2 American put, grid", pag), ("  European put, same grid", peg),
        ("premium, tree 2000 - closed form", pa - pe), ("premium, like for like on tree", pa - pet),
        ("premium, like for like on grid", pag - peg),
        ("American call, tree 2000", ca), ("  European call, same tree", cet),
        ("  call difference x 1e6", (ca - cet) * 1e6),
        ("parity lower  S e^-qT - K", lo), ("  C_A - P_A", ca - pa), ("parity upper  S - K e^-rT", hi),
        ("  European C - P", ce - pe), ("premium cap  K(1 - e^-rT)", k * (1.0 - (-r * t).exp())),
        ("2-step: u", u), ("2-step: p", p), ("2-step: one-step discount", dd), ("2-step: Acme after a fall", sd),
        ("2-step: after two falls", sdd), ("2-step: payoff after two falls", k - sdd), ("2-step: hold after a fall", hold_d),
        ("2-step: exercise after a fall", k - sd), ("2-step: rule 'never'", dd * (1.0 - p) * hold_d),
        ("2-step: rule 'sell after a fall'", dd * (1.0 - p) * (k - sd)),
        ("2-step: tree with max", tr(r, q, sig, 2, false, Rule::Best)),
    ];
    for (name, val) in &rows { println!("{:<34} {:>12.6}", name, val); }
    println!("stopping rules on the 2000-step tree: exercise first time Acme <= L");
    let mut best_rule = 0.0_f64;
    for l in [70.0, 75.0, 80.0, 82.0, 85.0, 90.0, 99.99] {
        let val = tr(r, q, sig, n, false, Rule::Level(l)); best_rule = best_rule.max(val);
        println!("  L = {:6.2}   {:10.6}", l, val);
    }
    println!("convergence: American put, European put, gap to closed form");
    let steps = [50usize, 100, 200, 500, 1000, 2000];
    let mut am = Vec::new();
    for &m in &steps {
        let a = if m == 1000 { pa1 } else if m == 2000 { pa } else { tr(r, q, sig, m, false, Rule::Best) };
        let e = tr(r, q, sig, m, false, Rule::Never); am.push(a);
        println!("  N = {:5}   {:10.6}   {:10.6}   {:+.6}", m, a, e, e - pe);
    }
    let tries: Vec<(&str, f64)> = vec![
        ("try r = 0: American", tr(0.0, q, sig, 500, false, Rule::Best)),
        ("try r = 0: European", tr(0.0, q, sig, 500, false, Rule::Never)),
        ("try r = 10%: premium", tr(0.10, q, sig, 500, false, Rule::Best) - tr(0.10, q, sig, 500, false, Rule::Never)),
        ("try q = 0: American put", tr(r, 0.0, sig, 500, false, Rule::Best)),
        ("try sigma = 40%: premium", tr(r, q, 0.4, 500, false, Rule::Best) - tr(r, q, 0.4, 500, false, Rule::Never)),
    ];
    for (name, val) in &tries { println!("{:<34} {:>12.6}", name, val); }
    assert!((pe - 6.330080627550).abs() < 1e-9, "own normal CDF reproduces the house put");
    assert!((pa - pag).abs() < 0.001 && (2.0 * pa - pa1 - pag).abs() < 2e-4, "tree and grid agree on the American put");
    assert!((pet - pe).abs() < 0.002 && (peg - pe).abs() < 0.002, "both machines price the European put");
    assert!(best_rule < pa, "no fixed level beats the best stopping rule");
    assert!(lo < ca - pa && ca - pa < hi && ca - pa < ce - pe, "American parity band, below European parity");
    assert!(am.windows(2).all(|w| w[1] > w[0]), "the tree price climbs as steps grow");
    assert!((tries[0].1 - tries[1].1).abs() < 1e-9, "no rate, no reason to sell early");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
European put, closed form              6.330081
European call, closed form             9.227006
1 American put, tree 2000              6.660226
  European put, same tree              6.329109
  limit, 2 x tree 2000 - tree 1000     6.660692
  same for the European                6.330081
2 American put, grid                   6.660608
  European put, same grid              6.330044
premium, tree 2000 - closed form       0.330145
premium, like for like on tree         0.331117
premium, like for like on grid         0.330565
American call, tree 2000               9.226034
  European call, same tree             9.226034
  call difference x 1e6                0.034101
parity lower  S e^-qT - K             -1.980133
  C_A - P_A                            2.565808
parity upper  S - K e^-rT              4.877058
  European C - P                       2.896925
premium cap  K(1 - e^-rT)              4.877058
2-step: u                              1.151910
2-step: p                              0.517959
2-step: one-step discount              0.975310
2-step: Acme after a fall             86.812345
2-step: after two falls               75.363832
2-step: payoff after two falls        24.636168
2-step: hold after a fall             11.582444
2-step: exercise after a fall         13.187655
2-step: rule 'never'                   5.445368
2-step: rule 'sell after a fall'       6.200042
2-step: tree with max                  6.200042
stopping rules on the 2000-step tree: exercise first time Acme <= L
  L =  70.00     6.394784
  L =  75.00     6.478945
  L =  80.00     6.593496
  L =  82.00     6.612919
  L =  85.00     6.560609
  L =  90.00     5.927474
  L =  99.99     0.437372
convergence: American put, European put, gap to closed form
  N =    50     6.641549     6.291300   -0.038781
  N =   100     6.651030     6.310665   -0.019416
  N =   200     6.655974     6.320367   -0.009714
  N =   500     6.658816     6.326194   -0.003887
  N =  1000     6.659759     6.328137   -0.001944
  N =  2000     6.660226     6.329109   -0.000972
try r = 0: American                    8.912076
try r = 0: European                    8.912076
try r = 10%: premium                   0.897825
try q = 0: American put                6.088810
try sigma = 40%: premium               0.373495
ALL CHECKS PASS
```

The two outputs are byte-identical.

### Lean

Lean proves Step 2, the parity band and the premium bounds, on a tree of any number of steps.

- Take any payoff $g$ and a weight $p$ between 0 and 1. Then the backward walk's value is the price of some stopping rule, and no stopping rule is worth more.
- Take the Cox–Ross–Rubinstein tree, with $r$, $q$, $S$ and $K$ not negative and $p$ between 0 and 1. Then $S e^{-qT} - K \le C_A - P_A \le S - K e^{-rT}$.
- Take the same tree, with $P_E$ the European put on it. Then $0 \le P_A - P_E \le K(1 - e^{-rT})$.

Every dollar figure, the climb as steps grow, and the agreement of tree and grid are left to the Python and Rust checks.

```lean
-- American options: on a binomial tree the backward walk equals the best stopping rule, and the American put and call obey the parity band and the premium cap.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Bounds.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Finset

namespace AmericanOption

/-- Acme's price at the tree node on date `n` reached after `j` rises: `S * u ^ (2 j - n)`
(each fall divides by `u`, the Cox–Ross–Rubinstein down factor `1 / u`). -/
noncomputable def node (S u : ℝ) (n j : ℕ) : ℝ := S * u ^ ((2 * j : ℤ) - n)

/-- The backward walk with `k` steps left, at the node on date `n` with `j` rises:
the larger of the payoff now and the discounted average of the two values one step ahead. -/
noncomputable def walk (g : ℝ → ℝ) (S u p D : ℝ) : ℕ → ℕ → ℕ → ℝ
  | 0, n, j => g (node S u n j)
  | k + 1, n, j => max (g (node S u n j))
      (D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j))

/-- The same walk with the max dropped: the European option on the same tree. -/
noncomputable def euro (g : ℝ → ℝ) (S u p D : ℝ) : ℕ → ℕ → ℕ → ℝ
  | 0, n, j => g (node S u n j)
  | k + 1, n, j =>
      D * (p * euro g S u p D k (n + 1) (j + 1) + (1 - p) * euro g S u p D k (n + 1) j)

/-- Number of rises among the first `n` moves of a path of `N` up (`true`) or down moves. -/
def ups {N : ℕ} (ω : Fin N → Bool) (n : ℕ) : ℕ :=
  (univ.filter (fun i : Fin N => i.val < n ∧ ω i = true)).card

/-- Risk-neutral probability of one whole path: `p` per rise, `1 - p` per fall. -/
noncomputable def pathProb (p : ℝ) {N : ℕ} (ω : Fin N → Bool) : ℝ :=
  p ^ ups ω N * (1 - p) ^ (N - ups ω N)

/-- A stopping rule on an `N`-step tree: it picks a date `0 … N` for each path, and whether it
stops on date `n` depends only on the first `n` moves (it looks back, never forward). -/
def IsStoppingRule (N : ℕ) (τ : (Fin N → Bool) → ℕ) : Prop :=
  (∀ ω, τ ω ≤ N) ∧
    ∀ (n : ℕ) (ω ω' : Fin N → Bool), (∀ i : Fin N, i.val < n → ω i = ω' i) → (τ ω = n ↔ τ ω' = n)

/-- The price of a stopping rule: the risk-neutral average of its payoff,
discounted by `D` per step back to today. -/
noncomputable def ruleValue (g : ℝ → ℝ) (S u p D : ℝ) (N : ℕ) (τ : (Fin N → Bool) → ℕ) : ℝ :=
  ∑ ω : Fin N → Bool, pathProb p ω * D ^ τ ω * g (node S u (τ ω) (ups ω (τ ω)))

/-- Up factor of the Cox–Ross–Rubinstein tree: `u = e^{σ √Δt}` with `Δt = T / N`. -/
noncomputable def crrU (σ T : ℝ) (N : ℕ) : ℝ := Real.exp (σ * Real.sqrt (T / N))

/-- Risk-neutral weight on up: `p = (e^{(r - q) Δt} - 1/u) / (u - 1/u)`. -/
noncomputable def crrP (r q σ T : ℝ) (N : ℕ) : ℝ :=
  (Real.exp ((r - q) * (T / N)) - 1 / crrU σ T N) / (crrU σ T N - 1 / crrU σ T N)

/-- One-step discount `e^{-r Δt}`. -/
noncomputable def crrD (r T : ℝ) (N : ℕ) : ℝ := Real.exp (-(r * (T / N)))

theorem ups_zero {N : ℕ} (ω : Fin N → Bool) : ups ω 0 = 0 := by
  simp [ups]

theorem ups_le {N : ℕ} (ω : Fin N → Bool) : ups ω N ≤ N := by
  unfold ups
  exact (card_filter_le _ _).trans (by simp)

theorem ups_cons_succ {k : ℕ} (b : Bool) (ω : Fin k → Bool) (m : ℕ) :
    ups (Fin.cons b ω : Fin (k + 1) → Bool) (m + 1) = (if b then 1 else 0) + ups ω m := by
  unfold ups
  rw [card_filter, card_filter, Fin.sum_univ_succ]
  simp [Fin.cons_zero, Fin.cons_succ]

theorem pathProb_cons (p : ℝ) {k : ℕ} (b : Bool) (ω : Fin k → Bool) :
    pathProb p (Fin.cons b ω : Fin (k + 1) → Bool) = (if b then p else 1 - p) * pathProb p ω := by
  unfold pathProb
  rw [ups_cons_succ]
  have h := ups_le ω
  cases b
  · simp only [Bool.false_eq_true, ite_false, zero_add]
    rw [show k + 1 - ups ω k = (k - ups ω k) + 1 by omega, pow_succ]
    ring
  · simp only [ite_true]
    rw [show k + 1 - (1 + ups ω k) = k - ups ω k by omega, add_comm 1, pow_succ]
    ring

theorem sum_cons {k : ℕ} (F : (Fin (k + 1) → Bool) → ℝ) :
    ∑ ω, F ω = ∑ ω : Fin k → Bool, F (Fin.cons true ω) + ∑ ω : Fin k → Bool, F (Fin.cons false ω) := by
  rw [← (Fin.consEquiv (fun _ => Bool)).sum_comp, Fintype.sum_prod_type, Fintype.sum_bool]
  simp

theorem sum_pathProb (p : ℝ) : ∀ k : ℕ, ∑ ω : Fin k → Bool, pathProb p ω = 1
  | 0 => by simp [pathProb, ups]
  | k + 1 => by
    rw [sum_cons]
    simp only [pathProb_cons, ite_true, Bool.false_eq_true, ite_false, ← mul_sum, sum_pathProb p k]
    ring

noncomputable def subValue (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) (τ : (Fin k → Bool) → ℕ) : ℝ :=
  ∑ ω : Fin k → Bool, pathProb p ω * D ^ τ ω * g (node S u (n + τ ω) (j + ups ω (τ ω)))

theorem rule_zero_or_pos {k : ℕ} {τ : (Fin k → Bool) → ℕ} (h : IsStoppingRule k τ) :
    (∀ ω, τ ω = 0) ∨ (∀ ω, 0 < τ ω) := by
  by_cases h0 : τ (fun _ => false) = 0
  · left
    intro ω
    exact (h.2 0 ω (fun _ => false) (fun i hi => absurd hi (Nat.not_lt_zero _))).2 h0
  · right
    intro ω
    rw [Nat.pos_iff_ne_zero]
    intro hω
    exact h0 ((h.2 0 ω (fun _ => false) (fun i hi => absurd hi (Nat.not_lt_zero _))).1 hω)

theorem subValue_of_zero (g : ℝ → ℝ) (S u p D : ℝ) {k : ℕ} (n j : ℕ) {τ : (Fin k → Bool) → ℕ}
    (hτ : ∀ ω, τ ω = 0) : subValue g S u p D k n j τ = g (node S u n j) := by
  simp [subValue, hτ, ups_zero, ← sum_mul, sum_pathProb]

theorem sub_rule {k : ℕ} {τ : (Fin (k + 1) → Bool) → ℕ} (h : IsStoppingRule (k + 1) τ)
    (hpos : ∀ ω, 0 < τ ω) (b : Bool) : IsStoppingRule k (fun ω => τ (Fin.cons b ω) - 1) := by
  constructor
  · intro ω
    have := h.1 (Fin.cons b ω)
    show τ (Fin.cons b ω) - 1 ≤ k
    omega
  · intro m ω ω' hag
    have key := h.2 (m + 1) (Fin.cons b ω) (Fin.cons b ω') (by
      intro i hi
      cases i using Fin.cases with
      | zero => simp
      | succ i =>
        simp only [Fin.cons_succ]
        exact hag i (by simp at hi; omega))
    have p1 := hpos (Fin.cons b ω)
    have p2 := hpos (Fin.cons b ω')
    simp only
    omega

theorem subValue_succ (g : ℝ → ℝ) (S u p D : ℝ) {k : ℕ} (n j : ℕ) {τ : (Fin (k + 1) → Bool) → ℕ}
    (hpos : ∀ ω, 0 < τ ω) :
    subValue g S u p D (k + 1) n j τ =
      D * (p * subValue g S u p D k (n + 1) (j + 1) (fun ω => τ (Fin.cons true ω) - 1) +
        (1 - p) * subValue g S u p D k (n + 1) j (fun ω => τ (Fin.cons false ω) - 1)) := by
  unfold subValue
  rw [sum_cons, mul_sum, mul_sum, ← sum_add_distrib, ← sum_add_distrib, mul_sum]
  refine sum_congr rfl (fun ω _ => ?_)
  obtain ⟨m, hm⟩ : ∃ m, τ (Fin.cons true ω) = m + 1 :=
    ⟨_, (Nat.succ_pred_eq_of_pos (hpos _)).symm⟩
  obtain ⟨m', hm'⟩ : ∃ m, τ (Fin.cons false ω) = m + 1 :=
    ⟨_, (Nat.succ_pred_eq_of_pos (hpos _)).symm⟩
  beta_reduce
  rw [hm, hm', Nat.add_sub_cancel, Nat.add_sub_cancel, ups_cons_succ, ups_cons_succ,
    pathProb_cons, pathProb_cons]
  simp only [ite_true, Bool.false_eq_true, ite_false]
  rw [show n + (m + 1) = n + 1 + m by omega, show j + (1 + ups ω m) = j + 1 + ups ω m by omega,
    show n + (m' + 1) = n + 1 + m' by omega, zero_add, pow_succ, pow_succ]
  ring

/-- Wait one step, then follow `τ1` after a rise or `τ0` after a fall. -/
def comb {k : ℕ} (τ1 τ0 : (Fin k → Bool) → ℕ) (ω : Fin (k + 1) → Bool) : ℕ :=
  (if ω 0 then τ1 (Fin.tail ω) else τ0 (Fin.tail ω)) + 1

theorem comb_rule {k : ℕ} {τ1 τ0 : (Fin k → Bool) → ℕ} (h1 : IsStoppingRule k τ1)
    (h0 : IsStoppingRule k τ0) : IsStoppingRule (k + 1) (comb τ1 τ0) := by
  constructor
  · intro ω
    unfold comb
    split
    · have := h1.1 (Fin.tail ω); omega
    · have := h0.1 (Fin.tail ω); omega
  · intro m ω ω' hag
    cases m with
    | zero => simp [comb]
    | succ m =>
      have e0 : ω 0 = ω' 0 := hag 0 (by simp)
      have ht : ∀ i : Fin k, i.val < m → Fin.tail ω i = Fin.tail ω' i :=
        fun i hi => hag i.succ (by simp; omega)
      simp only [comb, e0, Nat.add_right_cancel_iff]
      split
      · exact h1.2 m _ _ ht
      · exact h0.2 m _ _ ht

theorem zero_rule (k : ℕ) : IsStoppingRule k (fun _ => 0) :=
  ⟨fun _ => Nat.zero_le _, fun _ _ _ _ => Iff.rfl⟩

theorem walk_ge (g : ℝ → ℝ) (S u p D : ℝ) (hD : 0 ≤ D) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    ∀ (k n j : ℕ) (τ : (Fin k → Bool) → ℕ), IsStoppingRule k τ →
      subValue g S u p D k n j τ ≤ walk g S u p D k n j
  | 0, n, j, τ, h => by
    rw [subValue_of_zero g S u p D n j (fun ω => by have := h.1 ω; omega)]
    rfl
  | k + 1, n, j, τ, h => by
    rw [walk]
    rcases rule_zero_or_pos h with h0 | hpos
    · rw [subValue_of_zero g S u p D n j h0]
      exact le_max_left _ _
    · rw [subValue_succ g S u p D n j hpos]
      refine le_max_of_le_right (mul_le_mul_of_nonneg_left (add_le_add ?_ ?_) hD)
      · exact mul_le_mul_of_nonneg_left
          (walk_ge g S u p D hD hp0 hp1 k _ _ _ (sub_rule h hpos true)) hp0
      · exact mul_le_mul_of_nonneg_left
          (walk_ge g S u p D hD hp0 hp1 k _ _ _ (sub_rule h hpos false)) (by linarith)

theorem walk_attained (g : ℝ → ℝ) (S u p D : ℝ) :
    ∀ (k n j : ℕ), ∃ τ : (Fin k → Bool) → ℕ, IsStoppingRule k τ ∧
      subValue g S u p D k n j τ = walk g S u p D k n j
  | 0, n, j => ⟨fun _ => 0, zero_rule 0, by rw [subValue_of_zero g S u p D n j (fun _ => rfl)]; rfl⟩
  | k + 1, n, j => by
    obtain ⟨τ1, h1, e1⟩ := walk_attained g S u p D k (n + 1) (j + 1)
    obtain ⟨τ0, h0, e0⟩ := walk_attained g S u p D k (n + 1) j
    rw [walk]
    by_cases hc : D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j)
        ≤ g (node S u n j)
    · exact ⟨fun _ => 0, zero_rule _, by
        rw [subValue_of_zero g S u p D n j (fun _ => rfl), max_eq_left hc]⟩
    · refine ⟨comb τ1 τ0, comb_rule h1 h0, ?_⟩
      rw [subValue_succ g S u p D (τ := comb τ1 τ0) n j (fun ω => Nat.succ_pos _), max_eq_right (le_of_not_ge hc)]
      have c1 : (fun ω => comb τ1 τ0 (Fin.cons true ω) - 1) = τ1 := by
        funext ω; simp [comb]
      have c0 : (fun ω => comb τ1 τ0 (Fin.cons false ω) - 1) = τ0 := by
        funext ω; simp [comb]
      rw [c1, c0, e1, e0]

theorem ruleValue_eq (g : ℝ → ℝ) (S u p D : ℝ) (N : ℕ) (τ : (Fin N → Bool) → ℕ) :
    ruleValue g S u p D N τ = subValue g S u p D N 0 0 τ := by
  simp [ruleValue, subValue]

theorem node_up (S : ℝ) {u : ℝ} (hu : u ≠ 0) (n j : ℕ) :
    node S u (n + 1) (j + 1) = node S u n j * u := by
  unfold node
  rw [show (2 * ((j + 1 : ℕ) : ℤ) - ((n + 1 : ℕ) : ℤ)) = (2 * (j : ℤ) - n) + 1 by push_cast; ring,
    zpow_add₀ hu, zpow_one, mul_assoc]

theorem node_down (S : ℝ) {u : ℝ} (hu : u ≠ 0) (n j : ℕ) :
    node S u (n + 1) j = node S u n j * u⁻¹ := by
  unfold node
  rw [show (2 * (j : ℤ) - ((n + 1 : ℕ) : ℤ)) = (2 * (j : ℤ) - n) + (-1) by push_cast; ring,
    zpow_add₀ hu, zpow_neg_one, mul_assoc]

theorem node_nonneg {S u : ℝ} (hS : 0 ≤ S) (hu : 0 < u) (n j : ℕ) : 0 ≤ node S u n j :=
  mul_nonneg hS (zpow_nonneg hu.le _)

theorem node_exp {S u p D δ : ℝ} (hu : u ≠ 0) (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (n j : ℕ) :
    D * (p * node S u (n + 1) (j + 1) + (1 - p) * node S u (n + 1) j) = δ * node S u n j := by
  rw [node_up S hu, node_down S hu, ← hE]
  ring

theorem walk_succ (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    walk g S u p D (k + 1) n j = max (g (node S u n j))
      (D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j)) := by
  rw [walk]

theorem euro_succ (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    euro g S u p D (k + 1) n j =
      D * (p * euro g S u p D k (n + 1) (j + 1) + (1 - p) * euro g S u p D k (n + 1) j) := by
  rw [euro]

theorem walk_ge_pay (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    g (node S u n j) ≤ walk g S u p D k n j := by
  cases k with
  | zero => exact le_refl _
  | succ k => rw [walk]; exact le_max_left _ _

theorem walk_cont (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j)
      ≤ walk g S u p D (k + 1) n j := by
  rw [walk_succ]
  exact le_max_right _ _

theorem parity_upper (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hD1 : D ≤ 1) (hδ1 : δ ≤ 1)
    (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    ∀ k n j : ℕ, walk (fun s => max (s - K) 0) S u p D k n j
        - walk (fun s => max (K - s) 0) S u p D k n j ≤ node S u n j - K * D ^ k
  | 0, n, j => by
    simp only [walk, pow_zero, mul_one]
    rcases le_total (node S u n j) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; linarith
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; linarith
  | k + 1, n, j => by
    have ih1 := parity_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ1 hE hS hK k (n + 1) (j + 1)
    have ih0 := parity_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ1 hE hS hK k (n + 1) j
    have hE' := node_exp (S := S) hu.ne' hE n j
    have hs := node_nonneg hS hu n j
    have hPpay := walk_ge_pay (fun s => max (K - s) 0) S u p D (k + 1) n j
    have hPcont := walk_cont (fun s => max (K - s) 0) S u p D k n j
    have hm1 := le_max_left (K - node S u n j) 0
    have hm2 := le_max_right (K - node S u n j) 0
    have hDk : K * (D ^ k * D) ≤ K := mul_le_of_le_one_right hK (by
      rw [← pow_succ]; exact pow_le_one₀ hD0 hD1)
    have hδs : δ * node S u n j ≤ node S u n j := mul_le_of_le_one_left hs hδ1
    have h1 : D * p * (walk (fun s => max (s - K) 0) S u p D k (n + 1) (j + 1)
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
        - (node S u (n + 1) (j + 1) - K * D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (walk (fun s => max (s - K) 0) S u p D k (n + 1) j
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) j
        - (node S u (n + 1) j - K * D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    rw [walk_succ (fun s => max (s - K) 0), pow_succ]
    have key : max (max (node S u n j - K) 0)
        (D * (p * walk (fun s => max (s - K) 0) S u p D k (n + 1) (j + 1)
          + (1 - p) * walk (fun s => max (s - K) 0) S u p D k (n + 1) j))
        ≤ walk (fun s => max (K - s) 0) S u p D (k + 1) n j + node S u n j - K * (D ^ k * D) :=
      max_le (max_le (by linarith) (by linarith)) (by linarith)
    linarith


theorem parity_lower (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hD1 : D ≤ 1) (hδ0 : 0 ≤ δ) (hδ1 : δ ≤ 1)
    (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    ∀ k n j : ℕ, node S u n j * δ ^ k - K ≤ walk (fun s => max (s - K) 0) S u p D k n j
        - walk (fun s => max (K - s) 0) S u p D k n j
  | 0, n, j => by
    simp only [walk, pow_zero, mul_one]
    rcases le_total (node S u n j) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; linarith
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; linarith
  | k + 1, n, j => by
    have ih1 := parity_lower S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) (j + 1)
    have ih0 := parity_lower S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) j
    have hE' := node_exp (S := S) hu.ne' hE n j
    have hE'' : D * (p * (node S u (n + 1) (j + 1) * δ ^ k) + (1 - p) * (node S u (n + 1) j * δ ^ k))
        = δ ^ k * δ * node S u n j := by linear_combination δ ^ k * hE'
    have hs := node_nonneg hS hu n j
    have hCpay := walk_ge_pay (fun s => max (s - K) 0) S u p D (k + 1) n j
    have hCcont := walk_cont (fun s => max (s - K) 0) S u p D k n j
    have hm1 := le_max_left (node S u n j - K) 0
    have hm2 := le_max_right (node S u n j - K) 0
    have hKD : K * D ≤ K := mul_le_of_le_one_right hK hD1
    have hδs : δ ^ k * δ * node S u n j ≤ node S u n j := mul_le_of_le_one_left hs (by
      rw [← pow_succ]; exact pow_le_one₀ hδ0 hδ1)
    have h1 : D * p * (node S u (n + 1) (j + 1) * δ ^ k - K
        - (walk (fun s => max (s - K) 0) S u p D k (n + 1) (j + 1)
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1))) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (node S u (n + 1) j * δ ^ k - K
        - (walk (fun s => max (s - K) 0) S u p D k (n + 1) j
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) j)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    rw [walk_succ (fun s => max (K - s) 0), pow_succ]
    have key : max (max (K - node S u n j) 0)
        (D * (p * walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
          + (1 - p) * walk (fun s => max (K - s) 0) S u p D k (n + 1) j))
        ≤ walk (fun s => max (s - K) 0) S u p D (k + 1) n j + K - node S u n j * (δ ^ k * δ) :=
      max_le (max_le (by linarith) (by linarith)) (by linarith)
    linarith

theorem euro_le_walk (g : ℝ → ℝ) (S u p D : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (hD0 : 0 ≤ D) :
    ∀ k n j : ℕ, euro g S u p D k n j ≤ walk g S u p D k n j
  | 0, n, j => le_refl _
  | k + 1, n, j => by
    rw [euro_succ, walk_succ]
    exact le_max_of_le_right (mul_le_mul_of_nonneg_left (add_le_add
      (mul_le_mul_of_nonneg_left (euro_le_walk g S u p D hp0 hp1 hD0 k _ _) hp0)
      (mul_le_mul_of_nonneg_left (euro_le_walk g S u p D hp0 hp1 hD0 k _ _) (by linarith))) hD0)

theorem euro_nonneg (g : ℝ → ℝ) (hg : ∀ s, 0 ≤ g s) (S u p D : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) : ∀ k n j : ℕ, 0 ≤ euro g S u p D k n j
  | 0, n, j => hg _
  | k + 1, n, j => by
    rw [euro_succ]
    exact mul_nonneg hD0 (add_nonneg
      (mul_nonneg hp0 (euro_nonneg g hg S u p D hp0 hp1 hD0 k _ _))
      (mul_nonneg (by linarith) (euro_nonneg g hg S u p D hp0 hp1 hD0 k _ _)))

theorem euro_put_lower (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hE : D * (p * u + (1 - p) * u⁻¹) = δ) :
    ∀ k n j : ℕ, K * D ^ k - node S u n j * δ ^ k ≤ euro (fun s => max (K - s) 0) S u p D k n j
  | 0, n, j => by
    simp only [euro, pow_zero, mul_one]
    exact le_max_left _ _
  | k + 1, n, j => by
    have ih1 := euro_put_lower S K u p D δ hu hp0 hp1 hD0 hE k (n + 1) (j + 1)
    have ih0 := euro_put_lower S K u p D δ hu hp0 hp1 hD0 hE k (n + 1) j
    have hE' := node_exp (S := S) hu.ne' hE n j
    have hE'' : D * (p * (node S u (n + 1) (j + 1) * δ ^ k) + (1 - p) * (node S u (n + 1) j * δ ^ k))
        = δ ^ k * δ * node S u n j := by linear_combination δ ^ k * hE'
    have h1 : D * p * (K * D ^ k - node S u (n + 1) (j + 1) * δ ^ k
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (K * D ^ k - node S u (n + 1) j * δ ^ k
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) j) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    rw [euro_succ, pow_succ, pow_succ]
    linarith

theorem premium_upper (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hD1 : D ≤ 1) (hδ0 : 0 ≤ δ) (hδ1 : δ ≤ 1)
    (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    ∀ k n j : ℕ, walk (fun s => max (K - s) 0) S u p D k n j
        - euro (fun s => max (K - s) 0) S u p D k n j ≤ K * (1 - D ^ k)
  | 0, n, j => by simp [walk, euro]
  | k + 1, n, j => by
    have ih1 := premium_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) (j + 1)
    have ih0 := premium_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) j
    have hs := node_nonneg hS hu n j
    have hEl := euro_put_lower S K u p D δ hu hp0 hp1 hD0 hE (k + 1) n j
    have hEn := euro_nonneg (fun s => max (K - s) 0) (fun s => le_max_right _ _) S u p D hp0 hp1
      hD0 (k + 1) n j
    have hEq := euro_succ (fun s => max (K - s) 0) S u p D k n j
    have hKD : K * D ≤ K := mul_le_of_le_one_right hK hD1
    have hDk : K * D ^ (k + 1) ≤ K := mul_le_of_le_one_right hK (pow_le_one₀ hD0 hD1)
    have hδs : node S u n j * δ ^ (k + 1) ≤ node S u n j :=
      mul_le_of_le_one_right hs (pow_le_one₀ hδ0 hδ1)
    have h1 : D * p * (walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1) - K * (1 - D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (walk (fun s => max (K - s) 0) S u p D k (n + 1) j
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) j - K * (1 - D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    have hpow : D ^ (k + 1) = D ^ k * D := pow_succ D k
    have key : max (max (K - node S u n j) 0)
        (D * (p * walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
          + (1 - p) * walk (fun s => max (K - s) 0) S u p D k (n + 1) j))
        ≤ euro (fun s => max (K - s) 0) S u p D (k + 1) n j + K * (1 - D ^ (k + 1)) := by
      refine max_le (max_le (by linarith) (by linarith)) ?_
      rw [hEq, hpow]
      linarith
    rw [walk_succ (fun s => max (K - s) 0)]
    linarith

theorem crr_facts (r q σ T : ℝ) (N : ℕ) (hr : 0 ≤ r) (hq : 0 ≤ q) (hσ : 0 < σ) (hT : 0 < T)
    (hN : 0 < N) :
    0 < crrU σ T N ∧ 0 ≤ crrD r T N ∧ crrD r T N ≤ 1 ∧
      0 ≤ Real.exp (-(q * (T / N))) ∧ Real.exp (-(q * (T / N))) ≤ 1 ∧
      crrD r T N * (crrP r q σ T N * crrU σ T N + (1 - crrP r q σ T N) * (crrU σ T N)⁻¹)
        = Real.exp (-(q * (T / N))) ∧
      crrD r T N ^ N = Real.exp (-(r * T)) ∧ Real.exp (-(q * (T / N))) ^ N = Real.exp (-(q * T)) := by
  have hNpos : (0 : ℝ) < N := Nat.cast_pos.mpr hN
  have htN : 0 < T / N := div_pos hT hNpos
  have hu1 : 1 < crrU σ T N := by
    unfold crrU
    rw [Real.one_lt_exp_iff]
    exact mul_pos hσ (Real.sqrt_pos.mpr htN)
  have hu0 : 0 < crrU σ T N := by linarith
  have hinv : 1 / crrU σ T N < 1 := (div_lt_one hu0).mpr hu1
  have hne : crrU σ T N - 1 / crrU σ T N ≠ 0 := by linarith
  have hpu : crrP r q σ T N * (crrU σ T N - 1 / crrU σ T N)
      = Real.exp ((r - q) * (T / N)) - 1 / crrU σ T N := by
    unfold crrP
    exact div_mul_cancel₀ _ hne
  refine ⟨hu0, (Real.exp_pos _).le, ?_, (Real.exp_pos _).le, ?_, ?_, ?_, ?_⟩
  · unfold crrD
    rw [Real.exp_le_one_iff]
    nlinarith
  · rw [Real.exp_le_one_iff]
    nlinarith
  · have : crrP r q σ T N * crrU σ T N + (1 - crrP r q σ T N) * (crrU σ T N)⁻¹
        = Real.exp ((r - q) * (T / N)) := by
      rw [← one_div]
      linear_combination hpu
    rw [this]
    unfold crrD
    rw [← Real.exp_add]
    congr 1
    ring
  · unfold crrD
    rw [← Real.exp_nat_mul]
    congr 1
    field_simp
  · rw [← Real.exp_nat_mul]
    congr 1
    field_simp

#print axioms ups_zero
#print axioms ups_le
#print axioms ups_cons_succ
#print axioms pathProb_cons
#print axioms sum_cons
#print axioms sum_pathProb
#print axioms rule_zero_or_pos
#print axioms subValue_of_zero
#print axioms sub_rule
#print axioms subValue_succ
#print axioms comb_rule
#print axioms zero_rule
#print axioms walk_ge
#print axioms walk_attained
#print axioms ruleValue_eq
#print axioms node_up
#print axioms node_down
#print axioms node_nonneg
#print axioms node_exp
#print axioms walk_succ
#print axioms euro_succ
#print axioms walk_ge_pay
#print axioms walk_cont
#print axioms parity_upper
#print axioms parity_lower
#print axioms euro_le_walk
#print axioms euro_nonneg
#print axioms euro_put_lower
#print axioms premium_upper
#print axioms crr_facts

/-- **The backward walk finds the best stopping rule.** On an `N`-step tree, for any payoff `g`,
the value found by comparing "exercise now" with "wait" at every node, working backwards from
expiry, is the price of some stopping rule and no stopping rule is worth more:
the American option's price is the best over all rules. -/
theorem backward_walk_is_best_stopping_rule (N : ℕ) (g : ℝ → ℝ) (S u p r dt : ℝ)
    (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    IsGreatest
      {v | ∃ τ, IsStoppingRule N τ ∧ v = ruleValue g S u p (Real.exp (-(r * dt))) N τ}
      (walk g S u p (Real.exp (-(r * dt))) N 0 0) := by
  constructor
  · obtain ⟨τ, hτ, e⟩ := walk_attained g S u p (Real.exp (-(r * dt))) N 0 0
    exact ⟨τ, hτ, by rw [ruleValue_eq, e]⟩
  · rintro v ⟨τ, hτ, rfl⟩
    rw [ruleValue_eq]
    exact walk_ge g S u p _ (Real.exp_pos _).le hp0 hp1 N 0 0 τ hτ

/-- **The parity band.** On the Cox–Ross–Rubinstein tree, with a non-negative rate and dividend
yield, the American call minus the American put lies between `S e^{-qT} - K` and `S - K e^{-rT}`. -/
theorem american_parity_band (S K r q σ T : ℝ) (N : ℕ)
    (hS : 0 ≤ S) (hK : 0 ≤ K) (hr : 0 ≤ r) (hq : 0 ≤ q) (hσ : 0 < σ) (hT : 0 < T) (hN : 0 < N)
    (hp0 : 0 ≤ crrP r q σ T N) (hp1 : crrP r q σ T N ≤ 1) :
    let CA := walk (fun s => max (s - K) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    let PA := walk (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    S * Real.exp (-(q * T)) - K ≤ CA - PA ∧ CA - PA ≤ S - K * Real.exp (-(r * T)) := by
  obtain ⟨hu, hD0, hD1, hδ0, hδ1, hE, hDN, hδN⟩ := crr_facts r q σ T N hr hq hσ hT hN
  have h1 := parity_upper S K _ _ _ _ hu hp0 hp1 hD0 hD1 hδ1 hE hS hK N 0 0
  have h2 := parity_lower S K _ _ _ _ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK N 0 0
  have hn : node S (crrU σ T N) 0 0 = S := by simp [node]
  rw [hn, hDN] at h1
  rw [hn, hδN] at h2
  exact ⟨h2, h1⟩

/-- **The early-exercise premium is never negative and at most the interest on the strike.**
On the Cox–Ross–Rubinstein tree, `0 ≤ P_A - P_E ≤ K (1 - e^{-rT})`. -/
theorem early_exercise_premium_bounds (S K r q σ T : ℝ) (N : ℕ)
    (hS : 0 ≤ S) (hK : 0 ≤ K) (hr : 0 ≤ r) (hq : 0 ≤ q) (hσ : 0 < σ) (hT : 0 < T) (hN : 0 < N)
    (hp0 : 0 ≤ crrP r q σ T N) (hp1 : crrP r q σ T N ≤ 1) :
    let PA := walk (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    let PE := euro (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    0 ≤ PA - PE ∧ PA - PE ≤ K * (1 - Real.exp (-(r * T))) := by
  obtain ⟨hu, hD0, hD1, hδ0, hδ1, hE, hDN, hδN⟩ := crr_facts r q σ T N hr hq hσ hT hN
  have h1 := euro_le_walk (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N)
    hp0 hp1 hD0 N 0 0
  have h2 := premium_upper S K _ _ _ _ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK N 0 0
  rw [hDN] at h2
  exact ⟨sub_nonneg.mpr h1, h2⟩

#print axioms backward_walk_is_best_stopping_rule
#print axioms american_parity_band
#print axioms early_exercise_premium_bounds

end AmericanOption
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'AmericanOption.ups_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.ups_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.ups_cons_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.pathProb_cons' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.sum_cons' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.sum_pathProb' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.rule_zero_or_pos' depends on axioms: [propext]
'AmericanOption.subValue_of_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.sub_rule' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.subValue_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.comb_rule' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.zero_rule' does not depend on any axioms
'AmericanOption.walk_ge' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.walk_attained' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.ruleValue_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.node_up' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.node_down' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.node_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.node_exp' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.walk_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.euro_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.walk_ge_pay' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.walk_cont' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.parity_upper' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.parity_lower' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.euro_le_walk' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.euro_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.euro_put_lower' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.premium_upper' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.crr_facts' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.backward_walk_is_best_stopping_rule' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.american_parity_band' depends on axioms: [propext, Classical.choice, Quot.sound]
'AmericanOption.early_exercise_premium_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess the direction first, then run.
> - **Set the rate to zero** (`try r = 0` rows). The American and European puts are both 8.912076: no interest on the strike, no reason to hurry, no premium.
> - **Double the rate to 10%.** The premium, like for like on a 500-step tree, rises from about 0.33 to 0.897825: faster-growing cash makes an early sale worth more.
> - **Double volatility to 40%.** The premium rises only to 0.373495, same tree. A jumpier Acme makes waiting for a bigger fall worth more, so the extra freedom is used less often, even though both prices rise.
> - **Drop the dividend.** The American put falls to 6.088810. A dividend drags the share price down, and a put holder gains from that.

---

## The usual mistake

> [!warning]
> **Treating early exercise as a forecast.** Selling early is not a bet that Acme will rebound. The best rule sells deep down because the interest on the strike outweighs the value of waiting for a further fall, a comparison of two prices made on the day. The American price rests on that comparison at every node, not on any view of where Acme is going.
>
> Smaller traps:
> - **Using parity as an equation for American options.** $C_A - P_A$ is 2.565808, not the European 2.896925. Backing the American put out of the American call by European parity returns the European put's value and misses the premium.
> - **Exercising the moment the put pays.** Worth $0.44 as a rule, against $6.66. A put barely in the money is worth far more alive.
> - **Reading a tree's price as the American price.** An $N$-step tree prices $N + 1$ exercise dates. At 50 steps it is 6.641549, 1.9 cents short of 2,000 steps; the limit is near 6.6606.
> - **Measuring the premium against a different machine.** Tree American minus closed-form European is 0.330145; minus the same tree's European it is 0.331117. The second is like for like; the first mixes in the tree's error.

---

## Where you meet it in real life

- **Listed options on US shares.** Options on single US stocks and exchange-traded funds are American-style; options on the S&P 500 index, SPX and the mini XSP, are European-style. Conventions verified 24 Sep 2026 on the product pages of Cboe, the Chicago options exchange.
- **Early assignment before a dividend.** A seller of an American call on a stock about to pay a large dividend can be assigned the day before, because the dividend is the one thing that makes early call exercise worth it: [Merton's theorem](02-mertons-no-early-exercise-theorem.md). Assigned means the holder exercises and the seller must hand over the shares at the strike.
- **Mortgages and callable bonds.** A borrower who may repay any day holds an American option on the loan, and uses it when rates fall.
- **Swaptions with a schedule.** A swaption is the right to enter a swap, a contract that trades fixed interest payments for floating ones. Many interest-rate options may be exercised only on coupon dates: [Bermudan options](03-bermudan-options.md).
- **Quick prices on a desk.** A tree is slow; an analytic approximation gets within cents in microseconds: [Barone-Adesi-Whaley](06-barone-adesi-whaley-approximation.md). With no expiry at all there is an exact formula: [The perpetual American put](05-perpetual-american-put.md).

> **Say it back**
> An American option can be exercised on any day, using only what is known on that day. Every plan for choosing the day has a price, and the American option is worth the best of them. The best plan is found by walking backwards and, at every point, keeping the larger of exercising now and waiting. The house put comes out at $6.66 against $6.33 for the European, a premium of 33 cents, capped by a year's interest on the strike. American calls and puts obey a parity band instead of an equation.

---

## What this builds on

- [Black-Scholes put](../08-The%20Black-Scholes%20call%20and%20put/02-black-scholes-put.md): the European put, $6.33, the floor the American price is measured from, and the risk-neutral average.
- [Put-call parity](../08-The%20Black-Scholes%20call%20and%20put/03-put-call-parity.md): the European equation that becomes a band once exercise can come early.
- [Cox-Ross-Rubinstein](../04-Binomial%20Trees/04-crr-tree-and-convergence.md): the tree's up factor, weight and error, used unchanged in Road 1.
- [Optimal stopping](../../11-Stochastic%20processes%20and%20calculus/08-Generators%2C%20Densities%20and%20Simulation/07-optimal-stopping-and-snell-envelope.md): why the best stopping rule is a fair price, through the Snell envelope.

## Where this goes next

- [Merton's theorem](02-mertons-no-early-exercise-theorem.md): why an American call on a share that pays nothing is never exercised early, and what a dividend changes.
- [Bermudan options](03-bermudan-options.md): exercise on a schedule of dates, between European and American.
- [American Greeks and implied volatility](07-american-greeks-and-implied-volatility.md): how the American price moves with its inputs, and running it backwards for volatility.
- [Optimal stopping](../../11-Stochastic%20processes%20and%20calculus/08-Generators%2C%20Densities%20and%20Simulation/07-optimal-stopping-and-snell-envelope.md): the backward walk as a general method for any decision of when to stop.

This card finds the price but not the rule's shape: the level at which the best holder sells, and how it rises toward the strike as expiry nears, is the next question, answered on [The exercise boundary and smooth pasting](04-exercise-boundary-and-smooth-pasting.md).

---

## Sources

Verified 24 Sep 2026: every link below resolves to the publisher's page.

- Merton, Robert C. "Theory of Rational Option Pricing." *Bell Journal of Economics and Management Science* 4, no. 1 (1973): 141–183. [doi:10.2307/3003143](https://doi.org/10.2307/3003143). The bounds that need no model, the American call on a share with no dividend, and the early-exercise premium of the put.
- Brennan, Michael J., and Eduardo S. Schwartz. "The Valuation of American Put Options." *Journal of Finance* 32, no. 2 (1977): 449–462. [doi:10.2307/2326779](https://doi.org/10.2307/2326779). The American put priced on a grid with the payoff as a floor; Road 2 in the code.
- Cox, John C., Stephen A. Ross, and Mark Rubinstein. "Option Pricing: A Simplified Approach." *Journal of Financial Economics* 7, no. 3 (1979): 229–263. [doi:10.1016/0304-405X(79)90015-1](https://doi.org/10.1016/0304-405X(79)90015-1). The tree, and the American put by backward induction; Road 1.
- Karatzas, Ioannis. "On the Pricing of American Options." *Applied Mathematics and Optimization* 17 (1988): 37–60. [doi:10.1007/BF01448358](https://doi.org/10.1007/BF01448358). The price as a supremum over stopping times, and the hedge that funds it.
