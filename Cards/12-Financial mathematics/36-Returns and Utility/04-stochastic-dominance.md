# Stochastic dominance: when one gamble beats another for every sensible investor

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Returns and Utility](../README.md#s36) → Stochastic dominance

---

## General Overview

Three funds each take $100 for one year. Steady pays back $102 for certain. Swing pays back $98 or $106, each with probability one half. Upside pays back $98 or $108, each with probability one half. On $100, a return of 2 percent is exactly $2, so returns and dollars read the same on this card.

Which fund is better? Expected utility answers that question one investor at a time: pick a utility (a score for each outcome, higher for outcomes the investor likes more), average the scores, take the higher average ([Expected utility](02-expected-utility-and-risk-aversion.md)). But nobody knows anyone's utility exactly. Stochastic dominance asks a stronger question: does one fund win for every investor in a whole class at once?

Two classes matter. The first is every investor who prefers more money to less. The second is every investor who prefers more money to less and also dislikes risk. A fund that wins for the whole first class **first-order dominates**; one that wins for the whole second class **second-order dominates**.

The surprise is that neither needs a utility at all. Each reduces to a test on the funds' probabilities alone, and the three funds give all three possible verdicts:

- Upside beats Swing for everyone who likes money. Same bad outcome, better good one.
- Steady beats Swing for everyone who likes money and dislikes risk. Same average, less spread. Some risk-lovers disagree.
- Steady and Upside are not ranked by either class. Some risk-averse investors pick one, some the other.

**One fund dominates another when its chance of ending at or below every threshold is never higher (first order), or when its average shortfall below every cutoff is never higher (second order); each test is equivalent to winning for a whole class of investors at once.**

**What kind of fact this is:** two definitions (the orders) and a theorem (each order equals a test on the probabilities alone), proved on this card in Why it works.

### The picture: Upside is never more likely to end low

The chance of ending at or below a threshold, for Swing and Upside, at the four returns either fund can produce. One █ is 0.05.

```
threshold   fund     chance of ending at or below it
t = -2      Swing    ██████████            0.50
            Upside   ██████████            0.50
t =  2      Swing    ██████████            0.50
            Upside   ██████████            0.50
t =  6      Swing    ████████████████████  1.00
            Upside   ██████████            0.50
t =  8      Swing    ████████████████████  1.00
            Upside   ████████████████████  1.00
```

Upside's bar is never longer than Swing's. At 6 percent it is shorter: Swing has certainly finished by then, Upside has a half chance of going further. That picture is first-order dominance.

---

## The formula

Notation first, in words. $A$ and $B$ are the one-year returns of two funds, in percent, before they are known. $F_A(t)$ is the **cumulative distribution function** (CDF) of $A$: the chance that $A$ ends at or below the threshold $t$ ([Densities](../../09-Probability%20and%20statistics/04-Continuous%20Distributions/01-densities-and-cdfs.md)). $E[\cdot]$ is the average, weighted by probability. $u$ is a utility. $A \succeq_1 B$ reads "A first-order dominates B"; $A \succeq_2 B$ reads "A second-order dominates B".

**First order.** For every increasing utility $u$, meaning more return never scores less:

$$A \succeq_1 B \iff E[u(A)] \ge E[u(B)] \text{ for every increasing } u \iff F_A(t) \le F_B(t) \text{ for every } t$$

**Read it aloud:** A wins for every investor who prefers more to less exactly when, at every threshold, A is no more likely than B to end at or below it.

**Second order.** Write $(x)^+$ for $\max(x, 0)$: $x$ when positive, zero otherwise. The **shortfall** of $A$ below a cutoff $k$ is the average amount by which $A$ falls short of $k$, counting zero when it does not:

$$P_A(k) = E\big[(k - A)^+\big] = \int_{-\infty}^{k} F_A(t)\,dt$$

The second equality, proved in Step 2, says the shortfall is the area under the CDF up to $k$. Then, for every utility $u$ that is increasing and **concave** (its slope never rises, which is what risk aversion means in the expected-utility model):

$$A \succeq_2 B \iff E[u(A)] \ge E[u(B)] \text{ for every increasing concave } u \iff P_A(k) \le P_B(k) \text{ for every } k$$

**Read it aloud:** A wins for every risk-averse investor who prefers more to less exactly when, at every cutoff, A's average shortfall is no larger than B's.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $A$, $B$ | the two funds' one-year returns, in percent | Upside and Swing | — |
| $t$, $k$ | a threshold return (t for the CDF, k for the shortfall cutoff) | −2, 2, 6, 8 | tests a higher slice of outcomes |
| $F_A(t)$, $F_B(t)$ | chance of ending at or below $t$ | Swing at 6: 1.00; Upside at 6: 0.50 | a higher CDF is the worse fund |
| $P_A(k)$, $P_B(k)$ | average shortfall below $k$: area under the CDF up to $k$ | Steady at 8: 6.00; Upside at 8: 5.00 | a higher shortfall is the worse fund |
| $(x)^+$ | $x$ if positive, else zero | $(2 - (-2))^+ = 4$ | — |
| $E[\cdot]$ | average weighted by probability | $E[\text{Upside}] = 3$ | — |
| $u$, $u'$, $u''$ | a utility; its slope; the change in its slope | $u(r) = \ln(100 + r)$ | — |
| $\succeq_1$, $\succeq_2$ | first- and second-order dominance | Upside $\succeq_1$ Swing; Steady $\succeq_2$ Swing | — |
| $a$, $b$ | lowest and highest return either fund can produce | −2 and 8 | — |
| $\mu$, $\sigma$ | mean and spread (standard deviation) of a normally distributed fund | 8% and 15% | more mean helps; more spread hurts risk-averse investors |
| $N(x)$, $\varphi(x)$ | the normal curve's area to the left of $x$, and its height at $x$ | $N(-0.2667) = 0.3949$ | — |
| $z$ | distance from the mean in spreads, $(k - \mu)/\sigma$ | $(4 - 8)/15 = -0.2667$ | — |

### When it holds

- **Same horizon, same money, fees included.** A one-year return against a two-year return, or a gross return against a net one, compares different things; convert first.
- **Known probabilities.** The tests are theorems about the stated distributions. Estimated from a short history, a cutoff where two shortfalls nearly touch can flip with a few more years of data.
- **Investors judge only the final outcome, by expected utility.** Someone who scores gains and losses from a reference point, or bends probabilities, as in [Prospect theory in outline](06-prospect-theory-in-outline.md), sits outside both classes and can choose a dominated fund.
- **Risk aversion, for second order only.** A lottery buyer has a utility that bends upward somewhere and sits outside the class; Steady $\succeq_2$ Swing says nothing about that buyer.
- **Finite averages.** The utility side compares averages, so it covers only utilities whose averages exist. With returns heavy enough that some are infinite, the tests rank the funds for the utilities that remain.

---

## Why it works

### Step 0: every investor is built from simple pieces

The class "every increasing utility" is too big to test member by member. But every member is a weighted sum of very simple members, so testing the simple ones tests every sum of them.

For first order the pieces are **threshold bets**: score 1 if the return beats $t$, else 0. For second order the pieces are **capped investors**: score the return, but never more than $k$. Each piece's average is a value of the CDF or of the shortfall. That is why the tests contain no utility.

### Step 1: first order is the CDF test

A threshold bet $u(r) = 1$ if $r > t$, else 0, is increasing. Its average for fund $A$ is the chance $A$ beats $t$, which is $1 - F_A(t)$. So if A is to win for every increasing utility, it must win for this one: $F_A(t) \le F_B(t)$. That is one direction.

For the other, write a smooth increasing utility as its lowest value plus a stack of threshold bets, one for each thin slice of thresholds between $a$ and $b$, weighted by the slope $u'(t)$:

$$u(x) = u(a) + \int_a^b u'(t)\,[x > t]\,dt$$

The bracket $[x > t]$ is 1 when true, 0 when false. Average both sides, and the bracket averages to $1 - F(t)$:

$$E[u(A)] - E[u(B)] = \int_a^b u'(t)\,\big(F_B(t) - F_A(t)\big)\,dt$$

Every factor is at least zero when the CDF test holds, so the difference is at least zero. A kinked or stepped utility is the same stack with some steps concentrated at points. The test is exact in both directions.

On the funds: the threshold bet at $t = 2$ scores Steady 0.00, Swing 0.50, Upside 0.50. A money-lover who only cares about beating 2 percent prefers Swing, so Steady does not first-order dominate Swing.

### Step 2: the shortfall is the area under the CDF

For one outcome $x$, the shortfall below $k$ is $(k - x)^+$: the length of the stretch of thresholds from $x$ up to $k$. As a sum of thresholds:

$$(k - x)^+ = \int_{-\infty}^{k} [x \le t]\,dt$$

Average over the fund's outcomes: the bracket averages to $F(t)$, so $P(k) = \int_{-\infty}^{k} F(t)\,dt$. On Swing at $k = 4$: the CDF is 0 up to −2 and 0.50 from −2 to 4, an area of $0.50 \times 6 = 3$; directly, Swing falls short of 4 by 6 half the time, an average of 3.

The chart traces the three shortfall curves. Between the returns a fund can produce, each curve is a straight line, so the knots at −2, 2, 6 and 8 are the only places a comparison can change.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Average shortfall below a cutoff, three funds"
    x-axis "Cutoff k (percent return)" [-4, -2, 0, 2, 4, 6, 8, 10]
    y-axis "Average shortfall (percentage points)" 0 --> 9
    line [0, 0, 0, 0, 2, 4, 6, 8]
    line [0, 0, 1, 2, 3, 4, 6, 8]
    line [0, 0, 1, 2, 3, 4, 5, 7]
```

Orange: Steady. Green: Swing. Dark blue: Upside. Steady never lies above Swing: second-order dominance. Upside never lies above Swing: implied by its first-order win. Steady and Upside cross at 6, so neither ranks the other.

### Step 3: second order is the shortfall test

A capped investor $u(r) = \min(r, k)$ is increasing and concave. Its average is $k - P(k)$, because capping a return at $k$ removes exactly its shortfall below $k$ from $k$: $\min(r, k) = k - (k - r)^+$. So a fund that wins for every risk-averse investor must win for each capped one, and $P_A(k) \le P_B(k)$ follows. That is one direction.

For the other, take a smooth increasing concave $u$ on $[a, b]$. Taylor's theorem with its remainder written as an integral rewrites it as a line plus a stack of capped pieces, weighted by $-u''(k)$: minus the rate at which the slope changes, which concavity makes non-negative. Averaging gives the identity the code checks:

$$E[u(A)] - E[u(B)] = u'(b)\,\big(E[A] - E[B]\big) + \int_a^b \big(-u''(k)\big)\,\big(P_B(k) - P_A(k)\big)\,dk$$

At the top cutoff $b$ every outcome falls short, so $P(b) = b - E[\cdot]$ and $E[A] - E[B] = P_B(b) - P_A(b)$. When the shortfall test holds, every term is a product of non-negative numbers. The difference is at least zero.

For log utility on wealth, $u(r) = \ln(100 + r)$, Steady against Swing: the direct average difference is 0.000769527, and the identity gives 0.000769527.

<details>
<summary>Detailed proof: the identity, kinked utilities, and why four cutoffs suffice</summary>

**The identity.** For $x$ in $[a, b]$, $u(x) = u(b) - \int_x^b u'(s)\,ds$ and $u'(s) = u'(b) - \int_s^b u''(k)\,dk$. Substituting and swapping the order of integration gives $\int_x^b u'(s)\,ds = u'(b)(b - x) - \int_x^b u''(k)(k - x)\,dk$. So $u(x) = u(b) + u'(b)(x - b) + \int_a^b u''(k)\,(k - x)^+\,dk$. Averaging over $A$, then over $B$, and subtracting gives the identity in Step 3, with $E[(k - A)^+] = P_A(k)$.

**Kinked utilities.** A concave increasing $u$ need not have a second derivative. On a fund with finitely many outcomes $s_1 < \dots < s_m$, only $u$'s values there matter. The slopes between neighbouring outcomes, $d_1, \dots, d_{m-1}$, are non-negative and fall. Then $u$ agrees on the outcomes with $u(s_1) + d_{m-1}(r - s_1) + \sum_{j=2}^{m-1} (d_{j-1} - d_j)\,(\min(r, s_j) - s_1)$: a rising line plus non-negative multiples of capped investors. Each capped piece is ranked by the shortfall test; the line is ranked by the mean, which is the shortfall at the top cutoff. So the sum is ranked.

**Four cutoffs suffice.** Below every outcome both shortfalls are zero. Between neighbouring outcomes each shortfall is a straight line in $k$, so their difference is too, and a straight line that is non-negative at both ends is non-negative between. Above every outcome the difference is the constant $E[A] - E[B]$. So checking the outcomes themselves checks every real $k$. The same holds for CDFs, which are constant between outcomes.

</details>

### Step 4: first order implies second order

If $F_A(t) \le F_B(t)$ at every $t$, the areas under the two CDFs up to any $k$ are ordered the same way, so $P_A(k) \le P_B(k)$. In utility terms: every increasing concave utility is an increasing utility, so winning for the bigger class includes winning for the smaller. Upside against Swing shows it on the chart: Upside's shortfall is never above Swing's.

### Step 5: equal means, and what second order then says

Steady and Swing have the same mean, 2 percent. Swing is Steady plus a coin flip of ±4 points that averages zero: a **mean-preserving spread**.

Rothschild and Stiglitz proved that with equal means, $A \succeq_2 B$ holds exactly when $B$ is $A$ plus noise that averages zero given $A$. This card states that equivalence and does not prove it; the construction of the noise is in their paper, listed under Sources. Without equal means the reading fails: Upside has more spread than Steady and a higher mean, and neither dominates.

An alternative route to first order runs through quantiles: sort each fund's outcomes from worst to best, and first-order dominance says A's outcome at every rank is at least B's. The code takes that route as a second test for first order.

---

## Worked numbers, by hand

The funds, per $100 for one year, even odds where there are two outcomes.

| Step | Arithmetic | Value |
| --- | --- | --- |
| means | Steady 2; Swing $(-2 + 6)/2$; Upside $(-2 + 8)/2$ | 2.00, 2.00, 3.00 |
| spreads | Steady 0; Swing half of 8; Upside half of 10 | 0.00, 4.00, 5.00 |
| Upside vs Swing, CDFs at −2, 2, 6, 8 | Upside 0.50, 0.50, 0.50, 1.00 against Swing 0.50, 0.50, 1.00, 1.00 | never higher: **Upside $\succeq_1$ Swing** |
| Steady vs Swing, CDF at 2 | Steady 1.00 against Swing 0.50 | first order fails |
| Steady vs Swing, shortfalls at −2, 2, 6, 8 | Steady 0, 0, 4, 6 against Swing 0, 2, 4, 6 | never higher: **Steady $\succeq_2$ Swing** |
| Steady vs Upside, shortfall at 2 | Steady 0.00 against Upside 2.00 | Upside cannot dominate |
| Steady vs Upside, shortfall at 8 | Steady 6.00 against Upside 5.00 | Steady cannot dominate: **neither** |
| a witness for each side | capped at 2: Steady 2.00, Upside 0.00; linear: Steady 2.00, Upside 3.00 | two risk-averse investors disagree |

Two risk-averse investors disagreeing is what "not ranked" means.

### The shelf's house example

A saver chooses between a 4 percent deposit and a fund whose return is normally distributed with mean $\mu$ = 8 percent and spread $\sigma$ = 15 percent. For a normal fund, the shortfall has a closed form: with $z = (k - \mu)/\sigma$,

$$P(k) = \sigma\,\varphi(z) + (k - \mu)\,N(z)$$

where $N$ is the normal curve's area to the left and $\varphi$ its height.

| Step | Arithmetic | Value |
| --- | --- | --- |
| chance the fund ends below 4% | $N((4 - 8)/15) = N(-0.2667)$ | 0.3949 |
| deposit's shortfall at 4 | $(4 - 4)^+$ | 0.0000 |
| fund's shortfall at 4 | $15\,\varphi(-0.2667) - 4\,N(-0.2667)$ | 4.1957 |
| deposit's shortfall at 30 | $30 - 4$ | 26.0000 |
| fund's shortfall at 30 | same formula | 22.4741 |
| verdict | the curves cross | **neither dominates** |

The fund's higher mean wins for a linear investor, 8 against 4. An investor capped at 4 percent scores the fund at $4 - 4.1957 = -0.1957$ and the deposit at 4. A normal fund always has some chance of ending below any sure rate, so it never dominates a deposit, whatever its mean.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Judge by the mean alone | Steady minus Swing: 0.00, "a tie" | Every risk-averse investor prefers Steady; the mean cannot see spread |
| Judge by the spread alone | Upside riskier by 5.00 points, "Steady wins" | The linear investor prefers Upside, 3.00 to 2.00; nothing dominates |
| Check one shortfall cutoff, k = 8 | Upside lower by 1.00, "Upside wins at second order" | At k = 2 Upside is higher by 2.00; the test is every cutoff |
| Check one CDF threshold, t = −2 | Steady lower by 0.50, "Steady wins at first order" | At t = 2 Steady is higher by 0.50 |

---

## Code, from first principles, and it actually runs

The code tests every ordered pair of funds four ways. For first order: the CDF test, the quantile test, and a search over 2,000 random increasing utilities that counts how many rank the pair the wrong way. For second order: the shortfall test and the same search over 2,000 random increasing concave utilities. The random numbers come from a hand-written generator, identical in both languages, so the counts match. Each shortfall is computed twice, as an average and as an area under the CDF. The Step 3 identity is checked against the direct average. On the house example, the normal curve's area is built two ways (Simpson's rule and a power series), and the fund's shortfall two ways (the closed form and a brute-force integral). Every number on this card is printed.

### Python

```python
# Stochastic dominance -- the check behind the card.  Standard library only.
# Three funds, one year, returns in percent, even odds.  Every number quoted on
# the card is printed here.  The normal CDF, the integrator and the random
# numbers are written out below; nothing imported knows the answer.
from math import exp, log, sqrt, pi

FUNDS = {"Steady": [(2.0, 1.0)], "Swing": [(-2.0, 0.5), (6.0, 0.5)],
         "Upside": [(-2.0, 0.5), (8.0, 0.5)]}
KNOTS = [-2.0, 2.0, 6.0, 8.0]
PAIRS = [("Upside", "Swing"), ("Swing", "Upside"), ("Steady", "Swing"),
         ("Swing", "Steady"), ("Steady", "Upside"), ("Upside", "Steady")]

def mean(f):        return sum(p * x for x, p in f)
def spread(f):      return sqrt(sum(p * (x - mean(f)) ** 2 for x, p in f))
def cdf(f, t):      return sum(p for x, p in f if x <= t)
def shortfall(f, k): return sum(p * max(k - x, 0.0) for x, p in f)    # road 1: E[(k - X)+]
def area(f, k, lo=-10.0, h=0.01):                                     # road 2: area under the CDF
    n = round((k - lo) / h)
    return sum(cdf(f, lo + (i + 0.5) * h) for i in range(n)) * h
def quantile(f, q):  return min(x for x, p in f if cdf(f, x) >= q)

def rng(seed):                               # 64-bit LCG, top 53 bits -> [0, 1)
    s = seed
    while True:
        s = (s * 6364136223846793005 + 1442695040888963407) % 2 ** 64
        yield (s >> 11) / 2.0 ** 53

def search(a, b, concave, draws=2000, seed=7):
    # Road 3: random utilities on the knots.  Count those ranking a below b.
    r, bad = rng(seed), 0
    for _ in range(draws):
        s = [next(r), next(r), next(r)]      # slopes on -2..2, 2..6, 6..8
        if concave: s.sort(reverse=True)     # slopes that only fall: concave
        u = [0.0, 4 * s[0], 4 * s[0] + 4 * s[1], 4 * s[0] + 4 * s[1] + 2 * s[2]]
        score = lambda f: sum(p * u[KNOTS.index(x)] for x, p in f)
        bad += score(FUNDS[a]) < score(FUNDS[b]) - 1e-12
    return bad

def yn(c): return "yes" if c else "no "

print("fund     outcomes        mean  spread")
for n, f in FUNDS.items():
    print(f"{n:<8} {' or '.join(f'{x:+.0f}' for x, _ in f):<14}{mean(f):6.2f}{spread(f):8.2f}")
print("CDF F(t) at t =          " + "".join(f"{t:7.0f}" for t in KNOTS))
for n, f in FUNDS.items():
    print(f"  {n:<22}" + "".join(f"{cdf(f, t):7.2f}" for t in KNOTS))
CH = [-4.0 + 2 * i for i in range(8)]
print("shortfall P(k) at k =    " + "".join(f"{k:7.0f}" for k in CH))
worst = 0.0
for n, f in FUNDS.items():
    print(f"  {n:<22}" + "".join(f"{shortfall(f, k):7.2f}" for k in CH))
    worst = max(worst, max(abs(shortfall(f, k) - area(f, k)) for k in CH))
print(f"largest gap, E[(k-X)+] vs area under CDF   {worst:.12f}")
assert worst < 1e-9, "shortfall must equal the area under the CDF"

print("pair               | 1st: CDF  quantile  increasing u bad | 2nd: shortfall  concave u bad")
verdicts = []
for a, b in PAIRS:
    fa, fb = FUNDS[a], FUNDS[b]
    c1 = all(cdf(fa, t) <= cdf(fb, t) for t in KNOTS)
    q1 = all(quantile(fa, (i + 0.5) / 100) >= quantile(fb, (i + 0.5) / 100) for i in range(100))
    s1 = search(a, b, False)
    c2 = all(shortfall(fa, k) <= shortfall(fb, k) + 1e-12 for k in KNOTS)
    s2 = search(a, b, True)
    verdicts.append((c1, c2))
    print(f"{a + ' over ' + b:<19}|      {yn(c1)}  {yn(q1)}       {s1:5d} of 2000 |"
          f"           {yn(c2)}  {s2:5d} of 2000")
    assert c1 == q1 == (s1 == 0), "three first-order roads must agree"
    assert c2 == (s2 == 0), "shortfall test and concave search must agree"

WIT = [("linear, u(r) = r", lambda r: r), ("capped, u(r) = min(r, 2)", lambda r: min(r, 2.0)),
       ("log wealth, ln(100 + r)", lambda r: log(100 + r)), ("bet, 1 if r > 2", lambda r: float(r > 2))]
beat = sum(p * q for x, p in FUNDS["Swing"] for y, q in FUNDS["Upside"] if x > y)
print(f"independent draws: chance Swing ends above Upside {beat:.2f}")
print("witness utility            Steady    Swing   Upside")
for n, u in WIT:
    print(f"{n:<25}" + "".join(f"{sum(p * u(x) for x, p in f):9.4f}" for f in FUNDS.values()))

def simpson(g, a, b, n=2000):
    h = (b - a) / n
    return (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))) * h / 3
# Road 4, the identity of Why it works, Step 3, with u = ln(100 + r) on [a, b] = [-2, 8]
for a, b in (("Steady", "Swing"), ("Upside", "Steady")):
    fa, fb = FUNDS[a], FUNDS[b]
    direct = sum(p * log(100 + x) for x, p in fa) - sum(p * log(100 + x) for x, p in fb)
    ident = (mean(fa) - mean(fb)) / 108 + simpson(
        lambda k: (shortfall(fb, k) - shortfall(fa, k)) / (100 + k) ** 2, -2.0, 8.0)
    print(f"Eu({a}) - Eu({b}): direct {direct:.9f}  identity {ident:.9f}")
    assert abs(direct - ident) < 1e-9, "the Step 3 identity must match the direct average"

phi = lambda x: exp(-0.5 * x * x) / sqrt(2 * pi)
def N_simpson(x): return 0.5 + simpson(phi, 0.0, x)
def N_series(x):                                        # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    term, total, j = x, x, 1
    while abs(term) > 1e-17:
        term *= x * x / (2 * j + 1); total += term; j += 1
    return 0.5 + phi(x) * total
MU, SIG, DEP = 8.0, 15.0, 4.0                          # house fund and deposit, percent
def fund_short(k, mu=MU, sig=SIG):                     # closed form: sigma phi(z) + (k - mu) N(z)
    z = (k - mu) / sig
    return sig * phi(z) + (k - mu) * N_series(z)
def fund_short_int(k):                                 # the same by brute force over the bell curve
    return simpson(lambda x: (k - x) * phi((x - MU) / SIG) / SIG, MU - 12 * SIG, k, 20000)
z4 = (DEP - MU) / SIG
print(f"house: z = (4 - 8) / 15 = {z4:.4f}")
print(f"house: chance fund ends below 4%: Simpson {N_simpson(z4):.6f}  series {N_series(z4):.6f}")
for k in (4.0, 30.0):
    print(f"house: shortfall at {k:4.0f}  deposit {max(k - DEP, 0):7.4f}  fund {fund_short(k):7.4f}"
          f"  by integral {fund_short_int(k):7.4f}")
    assert abs(fund_short(k) - fund_short_int(k)) < 1e-8, "closed form vs integral"
assert abs(N_simpson(z4) - N_series(z4)) < 1e-12, "two roads to N(z)"
print(f"house: capped at 4, E min(fund, 4) = {DEP - fund_short(DEP):.4f} vs deposit 4.0000")

MIS = [("means only: Steady vs Swing", mean(FUNDS["Steady"]) - mean(FUNDS["Swing"])),
       ("spreads only: Upside minus Steady", spread(FUNDS["Upside"]) - spread(FUNDS["Steady"])),
       ("one cutoff, k = 8: P_Upside - P_Steady", shortfall(FUNDS["Upside"], 8) - shortfall(FUNDS["Steady"], 8)),
       ("same, k = 2: P_Upside - P_Steady", shortfall(FUNDS["Upside"], 2) - shortfall(FUNDS["Steady"], 2)),
       ("one threshold, t = -2: F_Steady - F_Swing", cdf(FUNDS["Steady"], -2) - cdf(FUNDS["Swing"], -2)),
       ("same, t = 2: F_Steady - F_Swing", cdf(FUNDS["Steady"], 2) - cdf(FUNDS["Swing"], 2))]
for n, v in MIS: print(f"wrong: {n:<42}{v:7.2f}")
sw7 = [(-2.0, 0.5), (7.0, 0.5)]
up3 = [(-3.0, 0.5), (8.0, 0.5)]
print(f"try: Swing -2 or +7, shortfall at 8: Steady {shortfall(FUNDS['Steady'], 8):.2f}, Swing {shortfall(sw7, 8):.2f}")
print(f"try: Upside -3 or +8, CDF at -3: Upside {cdf(up3, -3):.2f}, Swing {cdf(FUNDS['Swing'], -3):.2f};"
      f" shortfall at -2: Upside {shortfall(up3, -2):.2f}, Swing {shortfall(FUNDS['Swing'], -2):.2f}")
print(f"try: fund spread 1%, chance below 4% per million {1e6 * N_series(-4.0):.3f},"
      f" shortfall at 4 per million {1e6 * fund_short(4.0, 8.0, 1.0):.3f}")
assert verdicts == [(True, True), (False, False), (False, True), (False, False), (False, False), (False, False)]
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
fund     outcomes        mean  spread
Steady   +2              2.00    0.00
Swing    -2 or +6        2.00    4.00
Upside   -2 or +8        3.00    5.00
CDF F(t) at t =               -2      2      6      8
  Steady                   0.00   1.00   1.00   1.00
  Swing                    0.50   0.50   1.00   1.00
  Upside                   0.50   0.50   0.50   1.00
shortfall P(k) at k =         -4     -2      0      2      4      6      8     10
  Steady                   0.00   0.00   0.00   0.00   2.00   4.00   6.00   8.00
  Swing                    0.00   0.00   1.00   2.00   3.00   4.00   6.00   8.00
  Upside                   0.00   0.00   1.00   2.00   3.00   4.00   5.00   7.00
largest gap, E[(k-X)+] vs area under CDF   0.000000000000
pair               | 1st: CDF  quantile  increasing u bad | 2nd: shortfall  concave u bad
Upside over Swing  |      yes  yes           0 of 2000 |           yes      0 of 2000
Swing over Upside  |      no   no         2000 of 2000 |           no    2000 of 2000
Steady over Swing  |      no   no          975 of 2000 |           yes      0 of 2000
Swing over Steady  |      no   no         1025 of 2000 |           no    2000 of 2000
Steady over Upside |      no   no         1399 of 2000 |           no     639 of 2000
Upside over Steady |      no   no          601 of 2000 |           no    1361 of 2000
independent draws: chance Swing ends above Upside 0.25
witness utility            Steady    Swing   Upside
linear, u(r) = r            2.0000   2.0000   3.0000
capped, u(r) = min(r, 2)    2.0000   0.0000   0.0000
log wealth, ln(100 + r)     4.6250   4.6242   4.6335
bet, 1 if r > 2             0.0000   0.5000   0.5000
Eu(Steady) - Eu(Swing): direct 0.000769527  identity 0.000769527
Eu(Upside) - Eu(Steady): direct 0.008576540  identity 0.008576540
house: z = (4 - 8) / 15 = -0.2667
house: chance fund ends below 4%: Simpson 0.394863  series 0.394863
house: shortfall at    4  deposit  0.0000  fund  4.1957  by integral  4.1957
house: shortfall at   30  deposit 26.0000  fund 22.4741  by integral 22.4741
house: capped at 4, E min(fund, 4) = -0.1957 vs deposit 4.0000
wrong: means only: Steady vs Swing                  0.00
wrong: spreads only: Upside minus Steady            5.00
wrong: one cutoff, k = 8: P_Upside - P_Steady      -1.00
wrong: same, k = 2: P_Upside - P_Steady             2.00
wrong: one threshold, t = -2: F_Steady - F_Swing   -0.50
wrong: same, t = 2: F_Steady - F_Swing              0.50
try: Swing -2 or +7, shortfall at 8: Steady 6.00, Swing 5.50
try: Upside -3 or +8, CDF at -3: Upside 0.50, Swing 0.00; shortfall at -2: Upside 0.50, Swing 0.00
try: fund spread 1%, chance below 4% per million 31.671, shortfall at 4 per million 7.145
ALL CHECKS PASS
```

A zero in the "bad" column means no random utility in that class ranked the pair the wrong way, and every such zero lines up with a "yes" from the probability test. Where a test says "no", the search found hundreds of investors on the other side. Steady over Upside at second order: 639 of 2,000 risk-averse utilities rank Steady lower, and 1,361 rank Upside lower.

### Rust

Same checks, same labels, built with `rustc --edition 2021 -O`.

```rust
// Stochastic dominance -- the same check as the Python, in Rust.  No crates.
// Three funds, one year, returns in percent, even odds.  The normal CDF, the
// integrator and the random numbers are written out below.
use std::f64::consts::PI;

type Fund = Vec<(f64, f64)>; // (return in percent, probability)
const KNOTS: [f64; 4] = [-2.0, 2.0, 6.0, 8.0];

fn mean(f: &Fund) -> f64 { f.iter().map(|&(x, p)| p * x).sum() }
fn spread(f: &Fund) -> f64 { let m = mean(f); f.iter().map(|&(x, p)| p * (x - m).powi(2)).sum::<f64>().sqrt() }
fn cdf(f: &Fund, t: f64) -> f64 { f.iter().filter(|&&(x, _)| x <= t).map(|&(_, p)| p).fold(0.0, |s, p| s + p) }
fn shortfall(f: &Fund, k: f64) -> f64 { f.iter().map(|&(x, p)| p * (k - x).max(0.0)).sum() } // road 1
fn area(f: &Fund, k: f64) -> f64 {                                   // road 2: area under the CDF
    let (lo, h) = (-10.0, 0.01);
    let n = ((k - lo) / h).round() as usize;
    (0..n).map(|i| cdf(f, lo + (i as f64 + 0.5) * h)).sum::<f64>() * h
}
fn quantile(f: &Fund, q: f64) -> f64 {
    f.iter().filter(|&&(x, _)| cdf(f, x) >= q).map(|&(x, _)| x).fold(f64::INFINITY, f64::min)
}
struct Lcg(u64);                                                     // 64-bit LCG, top 53 bits -> [0, 1)
impl Lcg {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 11) as f64 / 9007199254740992.0
    }
}
fn search(a: &Fund, b: &Fund, concave: bool) -> usize {             // road 3: random utilities
    let mut r = Lcg(7);
    let mut bad = 0;
    for _ in 0..2000 {
        let mut s = [r.next(), r.next(), r.next()];                  // slopes on -2..2, 2..6, 6..8
        if concave { s.sort_by(|x, y| y.partial_cmp(x).unwrap()); }  // slopes that only fall
        let u = [0.0, 4.0 * s[0], 4.0 * s[0] + 4.0 * s[1], 4.0 * s[0] + 4.0 * s[1] + 2.0 * s[2]];
        let score = |f: &Fund| -> f64 {
            f.iter().map(|&(x, p)| p * u[KNOTS.iter().position(|&k| k == x).unwrap()]).sum()
        };
        if score(a) < score(b) - 1e-12 { bad += 1; }
    }
    bad
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no " } }
fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h)).sum();
    (g(a) + g(b) + inner) * h / 3.0
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_simpson(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 2000) }
fn n_series(x: f64) -> f64 {                                         // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut j) = (x, x, 1.0);
    while term.abs() > 1e-17 { term *= x * x / (2.0 * j + 1.0); total += term; j += 1.0; }
    0.5 + phi(x) * total
}
const MU: f64 = 8.0;
const SIG: f64 = 15.0;
const DEP: f64 = 4.0;
fn fund_short(k: f64, mu: f64, sig: f64) -> f64 { let z = (k - mu) / sig; sig * phi(z) + (k - mu) * n_series(z) }
fn fund_short_int(k: f64) -> f64 { simpson(|x| (k - x) * phi((x - MU) / SIG) / SIG, MU - 12.0 * SIG, k, 20000) }

fn main() {
    let names = ["Steady", "Swing", "Upside"];
    let funds: Vec<Fund> = vec![vec![(2.0, 1.0)], vec![(-2.0, 0.5), (6.0, 0.5)], vec![(-2.0, 0.5), (8.0, 0.5)]];
    let pairs = [(2, 1), (1, 2), (0, 1), (1, 0), (0, 2), (2, 0)];
    println!("fund     outcomes        mean  spread");
    for (n, f) in names.iter().zip(&funds) {
        let outs: Vec<String> = f.iter().map(|&(x, _)| format!("{:+.0}", x)).collect();
        println!("{:<8} {:<14}{:6.2}{:8.2}", n, outs.join(" or "), mean(f), spread(f));
    }
    let row = |xs: &[f64]| -> String { xs.iter().map(|v| format!("{:7.2}", v)).collect() };
    println!("CDF F(t) at t =          {}", KNOTS.iter().map(|t| format!("{:7.0}", t)).collect::<String>());
    for (n, f) in names.iter().zip(&funds) {
        println!("  {:<22}{}", n, row(&KNOTS.iter().map(|&t| cdf(f, t)).collect::<Vec<_>>()));
    }
    let ch: Vec<f64> = (0..8).map(|i| -4.0 + 2.0 * i as f64).collect();
    println!("shortfall P(k) at k =    {}", ch.iter().map(|k| format!("{:7.0}", k)).collect::<String>());
    let mut worst: f64 = 0.0;
    for (n, f) in names.iter().zip(&funds) {
        println!("  {:<22}{}", n, row(&ch.iter().map(|&k| shortfall(f, k)).collect::<Vec<_>>()));
        for &k in &ch { worst = worst.max((shortfall(f, k) - area(f, k)).abs()); }
    }
    println!("largest gap, E[(k-X)+] vs area under CDF   {:.12}", worst);
    assert!(worst < 1e-9, "shortfall must equal the area under the CDF");

    println!("pair               | 1st: CDF  quantile  increasing u bad | 2nd: shortfall  concave u bad");
    let mut verdicts = Vec::new();
    for &(a, b) in &pairs {
        let (fa, fb) = (&funds[a], &funds[b]);
        let c1 = KNOTS.iter().all(|&t| cdf(fa, t) <= cdf(fb, t));
        let q1 = (0..100).all(|i| { let q = (i as f64 + 0.5) / 100.0; quantile(fa, q) >= quantile(fb, q) });
        let s1 = search(fa, fb, false);
        let c2 = KNOTS.iter().all(|&k| shortfall(fa, k) <= shortfall(fb, k) + 1e-12);
        let s2 = search(fa, fb, true);
        verdicts.push((c1, c2));
        println!("{:<19}|      {}  {}       {:5} of 2000 |           {}  {:5} of 2000",
                 format!("{} over {}", names[a], names[b]), yn(c1), yn(q1), s1, yn(c2), s2);
        assert!(c1 == q1 && q1 == (s1 == 0), "three first-order roads must agree");
        assert!(c2 == (s2 == 0), "shortfall test and concave search must agree");
    }

    let beat: f64 = funds[1].iter().map(|&(x, p)| funds[2].iter().filter(|&&(y, _)| x > y).map(|&(_, q)| p * q).sum::<f64>()).sum();
    println!("independent draws: chance Swing ends above Upside {:.2}", beat);

    let wit: [(&str, fn(f64) -> f64); 4] = [
        ("linear, u(r) = r", |r| r), ("capped, u(r) = min(r, 2)", |r| r.min(2.0)),
        ("log wealth, ln(100 + r)", |r| (100.0 + r).ln()), ("bet, 1 if r > 2", |r| if r > 2.0 { 1.0 } else { 0.0 })];
    println!("witness utility            Steady    Swing   Upside");
    for (n, u) in wit.iter() {
        let vals: String = funds.iter().map(|f| format!("{:9.4}", f.iter().map(|&(x, p)| p * u(x)).sum::<f64>())).collect();
        println!("{:<25}{}", n, vals);
    }
    // Road 4, the identity of Why it works, Step 3, with u = ln(100 + r) on [a, b] = [-2, 8]
    for &(a, b) in &[(0usize, 1usize), (2, 0)] {
        let (fa, fb) = (&funds[a], &funds[b]);
        let lu = |f: &Fund| -> f64 { f.iter().map(|&(x, p)| p * (100.0 + x).ln()).sum() };
        let direct = lu(fa) - lu(fb);
        let ident = (mean(fa) - mean(fb)) / 108.0
            + simpson(|k| (shortfall(fb, k) - shortfall(fa, k)) / (100.0 + k).powi(2), -2.0, 8.0, 2000);
        println!("Eu({}) - Eu({}): direct {:.9}  identity {:.9}", names[a], names[b], direct, ident);
        assert!((direct - ident).abs() < 1e-9, "the Step 3 identity must match the direct average");
    }

    let z4 = (DEP - MU) / SIG;
    println!("house: z = (4 - 8) / 15 = {:.4}", z4);
    println!("house: chance fund ends below 4%: Simpson {:.6}  series {:.6}", n_simpson(z4), n_series(z4));
    for &k in &[4.0f64, 30.0] {
        println!("house: shortfall at {:4.0}  deposit {:7.4}  fund {:7.4}  by integral {:7.4}",
                 k, (k - DEP).max(0.0), fund_short(k, MU, SIG), fund_short_int(k));
        assert!((fund_short(k, MU, SIG) - fund_short_int(k)).abs() < 1e-8, "closed form vs integral");
    }
    assert!((n_simpson(z4) - n_series(z4)).abs() < 1e-12, "two roads to N(z)");
    println!("house: capped at 4, E min(fund, 4) = {:.4} vs deposit 4.0000", DEP - fund_short(DEP, MU, SIG));

    let (st, sw, up) = (&funds[0], &funds[1], &funds[2]);
    let mis = [("means only: Steady vs Swing", mean(st) - mean(sw)),
        ("spreads only: Upside minus Steady", spread(up) - spread(st)),
        ("one cutoff, k = 8: P_Upside - P_Steady", shortfall(up, 8.0) - shortfall(st, 8.0)),
        ("same, k = 2: P_Upside - P_Steady", shortfall(up, 2.0) - shortfall(st, 2.0)),
        ("one threshold, t = -2: F_Steady - F_Swing", cdf(st, -2.0) - cdf(sw, -2.0)),
        ("same, t = 2: F_Steady - F_Swing", cdf(st, 2.0) - cdf(sw, 2.0))];
    for (n, v) in mis.iter() { println!("wrong: {:<42}{:7.2}", n, v); }
    let sw7: Fund = vec![(-2.0, 0.5), (7.0, 0.5)];
    let up3: Fund = vec![(-3.0, 0.5), (8.0, 0.5)];
    println!("try: Swing -2 or +7, shortfall at 8: Steady {:.2}, Swing {:.2}", shortfall(st, 8.0), shortfall(&sw7, 8.0));
    println!("try: Upside -3 or +8, CDF at -3: Upside {:.2}, Swing {:.2}; shortfall at -2: Upside {:.2}, Swing {:.2}",
             cdf(&up3, -3.0), cdf(sw, -3.0), shortfall(&up3, -2.0), shortfall(sw, -2.0));
    println!("try: fund spread 1%, chance below 4% per million {:.3}, shortfall at 4 per million {:.3}",
             1e6 * n_series(-4.0), 1e6 * fund_short(4.0, 8.0, 1.0));
    assert!(verdicts == vec![(true, true), (false, false), (false, true), (false, false), (false, false), (false, false)]);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
fund     outcomes        mean  spread
Steady   +2              2.00    0.00
Swing    -2 or +6        2.00    4.00
Upside   -2 or +8        3.00    5.00
CDF F(t) at t =               -2      2      6      8
  Steady                   0.00   1.00   1.00   1.00
  Swing                    0.50   0.50   1.00   1.00
  Upside                   0.50   0.50   0.50   1.00
shortfall P(k) at k =         -4     -2      0      2      4      6      8     10
  Steady                   0.00   0.00   0.00   0.00   2.00   4.00   6.00   8.00
  Swing                    0.00   0.00   1.00   2.00   3.00   4.00   6.00   8.00
  Upside                   0.00   0.00   1.00   2.00   3.00   4.00   5.00   7.00
largest gap, E[(k-X)+] vs area under CDF   0.000000000000
pair               | 1st: CDF  quantile  increasing u bad | 2nd: shortfall  concave u bad
Upside over Swing  |      yes  yes           0 of 2000 |           yes      0 of 2000
Swing over Upside  |      no   no         2000 of 2000 |           no    2000 of 2000
Steady over Swing  |      no   no          975 of 2000 |           yes      0 of 2000
Swing over Steady  |      no   no         1025 of 2000 |           no    2000 of 2000
Steady over Upside |      no   no         1399 of 2000 |           no     639 of 2000
Upside over Steady |      no   no          601 of 2000 |           no    1361 of 2000
independent draws: chance Swing ends above Upside 0.25
witness utility            Steady    Swing   Upside
linear, u(r) = r            2.0000   2.0000   3.0000
capped, u(r) = min(r, 2)    2.0000   0.0000   0.0000
log wealth, ln(100 + r)     4.6250   4.6242   4.6335
bet, 1 if r > 2             0.0000   0.5000   0.5000
Eu(Steady) - Eu(Swing): direct 0.000769527  identity 0.000769527
Eu(Upside) - Eu(Steady): direct 0.008576540  identity 0.008576540
house: z = (4 - 8) / 15 = -0.2667
house: chance fund ends below 4%: Simpson 0.394863  series 0.394863
house: shortfall at    4  deposit  0.0000  fund  4.1957  by integral  4.1957
house: shortfall at   30  deposit 26.0000  fund 22.4741  by integral 22.4741
house: capped at 4, E min(fund, 4) = -0.1957 vs deposit 4.0000
wrong: means only: Steady vs Swing                  0.00
wrong: spreads only: Upside minus Steady            5.00
wrong: one cutoff, k = 8: P_Upside - P_Steady      -1.00
wrong: same, k = 2: P_Upside - P_Steady             2.00
wrong: one threshold, t = -2: F_Steady - F_Swing   -0.50
wrong: same, t = 2: F_Steady - F_Swing              0.50
try: Swing -2 or +7, shortfall at 8: Steady 6.00, Swing 5.50
try: Upside -3 or +8, CDF at -3: Upside 0.50, Swing 0.00; shortfall at -2: Upside 0.50, Swing 0.00
try: fund spread 1%, chance below 4% per million 31.671, shortfall at 4 per million 7.145
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves both dominance tests and the shortfall's area formula for any two funds, and checks the worked numbers.

- First order. Take two funds $A$ and $B$, counting only utilities whose averages exist. Then $A \succeq_1 B$ exactly when $F_A(t) \le F_B(t)$ at every threshold $t$.
- Second order. Take two funds with finite averages, counting only utilities whose averages exist. Then $A \succeq_2 B$ exactly when $P_A(k) \le P_B(k)$ at every cutoff $k$.
- Take any fund $A$ and any cutoff $k$. Then the shortfall $P_A(k)$ is the area under the CDF up to $k$.
- The worked numbers hold: the means, the CDFs and shortfalls at −2, 2, 6 and 8, and the two disagreeing witnesses.
- Swing's shortfall at 4 is 3, the same as the area under its CDF.

The normal house fund, the random search over 2,000 utilities and the log-utility identity are left to the Python and Rust checks.

```lean
-- Stochastic dominance: one fund beats another for every investor who likes more money exactly when its CDF is never higher, and for every risk-averse such investor exactly when its average shortfall below every cutoff is never higher.
import Mathlib.Probability.CDF
import Mathlib.Analysis.Convex.Function
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory ProbabilityTheory

theorem sd_shortfall_lintegral (μ : Measure ℝ) [IsProbabilityMeasure μ] (k : ℝ) :
    ∫⁻ x, ENNReal.ofReal (max (k - x) 0) ∂μ = ∫⁻ t in Set.Iic k, ENNReal.ofReal (cdf μ t) := by
  rw [lintegral_eq_lintegral_meas_le (f := fun x => max (k - x) 0) μ (Filter.Eventually.of_forall fun x => le_max_right _ _)
    (by fun_prop)]
  have h1 : ∀ s ∈ Set.Ioi (0:ℝ), μ {a | s ≤ max (k - a) 0} = ENNReal.ofReal (cdf μ (k - s)) := by
    intro s hs
    rw [ofReal_cdf]
    congr 1
    ext a
    simp only [Set.mem_ofPred_eq, Set.mem_Iic, le_max_iff]
    constructor
    · rintro (h | h)
      · linarith
      · exact absurd h (not_le.mpr hs)
    · intro h; left; linarith
  rw [setLIntegral_congr_fun measurableSet_Ioi h1]
  rw [← lintegral_indicator measurableSet_Ioi, ← lintegral_indicator measurableSet_Iic]
  rw [← lintegral_sub_left_eq_self _ k]
  apply lintegral_congr_ae
  have : ∀ᵐ t ∂(volume : Measure ℝ), t ≠ k := by
    simp [ae_iff, measure_singleton]
  filter_upwards [this] with t ht
  simp only [Set.indicator, Set.mem_Ioi, Set.mem_Iic, sub_pos, sub_sub_cancel]
  by_cases h : t < k
  · simp [h, h.le]
  · have : ¬ t ≤ k := fun h' => h (lt_of_le_of_ne h' ht)
    simp [h, this]

#print axioms sd_shortfall_lintegral

theorem sd_lowerSet_le (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hF : ∀ t : ℝ, cdf μ t ≤ cdf ν t) (L : Set ℝ) (hL : IsLowerSet L) : μ L ≤ ν L := by
  by_cases hmax : ∃ s ∈ L, ∀ x ∈ L, x ≤ s
  · obtain ⟨s, hs, hsm⟩ := hmax
    have hLs : L = Set.Iic s := by
      ext x
      exact ⟨fun hx => hsm x hx, fun hx => hL hx hs⟩
    rw [hLs, ← ofReal_cdf, ← ofReal_cdf]
    exact ENNReal.ofReal_le_ofReal (hF s)
  · push Not at hmax
    set A : ℚ → Set ℝ := fun q => {x | x ≤ (q : ℝ) ∧ (q : ℝ) ∈ L} with hA
    have hU : L = ⋃ q, A q := by
      ext x
      simp only [Set.mem_iUnion, hA, Set.mem_ofPred_eq]
      constructor
      · intro hx
        obtain ⟨y, hy, hxy⟩ := hmax x hx
        obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn hxy
        exact ⟨q, hq1.le, hL hq2.le hy⟩
      · rintro ⟨q, hxq, hq⟩
        exact hL hxq hq
    have hdir : Directed (· ⊆ ·) A := by
      intro q1 q2
      have key : ∀ a b : ℚ, a ≤ b → ∃ r, A a ⊆ A r ∧ A b ⊆ A r := by
        intro a b hab
        by_cases hb : (b : ℝ) ∈ L
        · refine ⟨b, fun x hx => ⟨hx.1.trans (by exact_mod_cast hab), hb⟩, le_rfl⟩
        · refine ⟨a, le_rfl, fun x hx => absurd hx.2 hb⟩
      rcases le_total q1 q2 with h | h
      · exact key q1 q2 h
      · obtain ⟨r, h1, h2⟩ := key q2 q1 h
        exact ⟨r, h2, h1⟩
    have hle : ∀ q, μ (A q) ≤ ν (A q) := by
      intro q
      by_cases hq : (q : ℝ) ∈ L
      · have : A q = Set.Iic (q : ℝ) := by
          ext x; simp [hA, hq]
        rw [this, ← ofReal_cdf, ← ofReal_cdf]
        exact ENNReal.ofReal_le_ofReal (hF q)
      · have : A q = ∅ := by
          ext x; simp [hA, hq]
        simp [this]
    rw [hU, hdir.measure_iUnion, hdir.measure_iUnion]
    exact iSup_mono hle

#print axioms sd_lowerSet_le

theorem sd_upperSet_le (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hF : ∀ t : ℝ, cdf μ t ≤ cdf ν t) (S : Set ℝ) (hS : IsUpperSet S) (hSm : MeasurableSet S) :
    ν S ≤ μ S := by
  have h1 : ν S = 1 - ν Sᶜ := by
    rw [prob_compl_eq_one_sub hSm, ENNReal.sub_sub_cancel ENNReal.one_ne_top prob_le_one]
  have h2 : μ S = 1 - μ Sᶜ := by
    rw [prob_compl_eq_one_sub hSm, ENNReal.sub_sub_cancel ENNReal.one_ne_top prob_le_one]
  rw [h1, h2]
  exact tsub_le_tsub_left (sd_lowerSet_le μ ν hF Sᶜ hS.compl) 1

#print axioms sd_upperSet_le

theorem sd_min_integrable (ρ : Measure ℝ) [IsProbabilityMeasure ρ]
    (h : Integrable (fun x => x) ρ) (k : ℝ) : Integrable (fun x => min (x - k) 0) ρ := by
  refine ((integrable_const k).sub h).pos_part.neg.congr (ae_of_all _ fun x => ?_)
  simp only [Pi.neg_apply, Pi.sub_apply]
  rw [min_def, max_def]
  split_ifs <;> linarith

#print axioms sd_min_integrable

theorem sd_ramp_integral (ρ : Measure ℝ) [IsProbabilityMeasure ρ]
    (hρ : Integrable (fun x => x) ρ) (d h a b : ℝ) :
    Integrable (fun x => d * ((min (x - a) 0 - min (x - b) 0) / h + 1)) ρ ∧
    ∫ x, d * ((min (x - a) 0 - min (x - b) 0) / h + 1) ∂ρ =
      d * ((∫ x, min (x - a) 0 ∂ρ - ∫ x, min (x - b) 0 ∂ρ) / h + 1) := by
  have ha := sd_min_integrable ρ hρ a
  have hb := sd_min_integrable ρ hρ b
  constructor
  · exact (((ha.sub hb).div_const h).add (integrable_const 1)).const_mul d
  · have hs : Integrable (fun x => (min (x - a) 0 - min (x - b) 0) / h) ρ :=
      (ha.sub hb).div_const h
    rw [integral_const_mul, integral_add hs (integrable_const 1),
      integral_div, integral_sub ha hb]
    simp

#print axioms sd_ramp_integral

theorem sd_cone (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hμ : Integrable (fun x => x) μ) (hν : Integrable (fun x => x) ν)
    (H : ∀ k, ∫ x, min (x - k) 0 ∂ν ≤ ∫ x, min (x - k) 0 ∂μ)
    (c h : ℝ) (hh : 0 < h) (p D : ℕ → ℝ) (hDa : ∀ j, D (j + 1) ≤ D j)
    (m : ℕ) :
    Integrable (fun x => c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
      D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1)) μ ∧
    Integrable (fun x => c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
      D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1)) ν ∧
    D m * (∫ x, min (x - p m) 0 ∂μ - ∫ x, min (x - p m) 0 ∂ν) / h ≤
      (∫ x, c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
        D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1) ∂μ) -
      (∫ x, c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
        D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1) ∂ν) := by
  induction m with
  | zero =>
    have h0 : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] → Integrable (fun x => x) ρ →
        Integrable (fun x => c + D 0 * min (x - p 0) 0 / h) ρ ∧
        ∫ x, c + D 0 * min (x - p 0) 0 / h ∂ρ = c + D 0 * (∫ x, min (x - p 0) 0 ∂ρ) / h := by
      intro ρ _ hρ
      have hg := sd_min_integrable ρ hρ (p 0)
      refine ⟨(integrable_const c).add ((hg.const_mul (D 0)).div_const h), ?_⟩
      rw [integral_add (integrable_const c) ((hg.const_mul (D 0)).div_const h), integral_div,
        integral_const_mul]
      simp
    simp only [Finset.range_zero, Finset.sum_empty, add_zero]
    obtain ⟨i1, e1⟩ := h0 μ hμ
    obtain ⟨i2, e2⟩ := h0 ν hν
    refine ⟨i1, i2, ?_⟩
    rw [e1, e2]
    apply le_of_eq
    ring
  | succ m ih =>
    obtain ⟨i1, i2, hle⟩ := ih
    obtain ⟨r1, f1⟩ := sd_ramp_integral μ hμ (D m) h (p (m + 1)) (p m)
    obtain ⟨r2, f2⟩ := sd_ramp_integral ν hν (D m) h (p (m + 1)) (p m)
    simp only [Finset.sum_range_succ, ← add_assoc]
    refine ⟨i1.add r1, i2.add r2, ?_⟩
    rw [integral_add i1 r1, integral_add i2 r2, f1, f2]
    have hA : 0 ≤ ∫ x, min (x - p (m + 1)) 0 ∂μ - ∫ x, min (x - p (m + 1)) 0 ∂ν :=
      sub_nonneg.mpr (H _)
    have hA' : 0 ≤ ∫ x, min (x - p m) 0 ∂μ - ∫ x, min (x - p m) 0 ∂ν :=
      sub_nonneg.mpr (H _)
    have key : D (m + 1) * (∫ x, min (x - p (m + 1)) 0 ∂μ - ∫ x, min (x - p (m + 1)) 0 ∂ν) ≤
        D m * (∫ x, min (x - p (m + 1)) 0 ∂μ - ∫ x, min (x - p (m + 1)) 0 ∂ν) :=
      mul_le_mul_of_nonneg_right (hDa m) hA
    rw [div_le_iff₀ hh] at hle ⊢
    have alg : ∀ Iμ Iν a1 a2 b1 b2 : ℝ, (Iμ + D m * ((a1 - a2) / h + 1) -
        (Iν + D m * ((b1 - b2) / h + 1))) * h =
        (Iμ - Iν) * h + D m * ((a1 - b1) - (a2 - b2)) := by
      intros; field_simp; ring
    rw [alg]
    nlinarith

#print axioms sd_cone

theorem sd_ramp (h : ℝ) (hh : 0 < h) (q1 q2 x : ℝ) (hq : q2 = q1 + h) :
    0 ≤ (min (x - q2) 0 - min (x - q1) 0) / h + 1 ∧
    (min (x - q2) 0 - min (x - q1) 0) / h + 1 ≤ 1 ∧
    (q2 ≤ x → (min (x - q2) 0 - min (x - q1) 0) / h + 1 = 1) ∧
    (x ≤ q1 → (min (x - q2) 0 - min (x - q1) 0) / h + 1 = 0) := by
  subst hq
  refine ⟨?_, ?_, fun hx => ?_, fun hx => ?_⟩
  · have : -h ≤ min (x - (q1 + h)) 0 - min (x - q1) 0 := by
      rw [min_def, min_def]; split_ifs <;> linarith
    have : -1 ≤ (min (x - (q1 + h)) 0 - min (x - q1) 0) / h := by
      rw [le_div_iff₀ hh]; linarith
    linarith
  · have : min (x - (q1 + h)) 0 - min (x - q1) 0 ≤ 0 := by
      rw [min_def, min_def]; split_ifs <;> linarith
    have : (min (x - (q1 + h)) 0 - min (x - q1) 0) / h ≤ 0 := div_nonpos_of_nonpos_of_nonneg this hh.le
    linarith
  · rw [min_eq_right (by linarith), min_eq_right (by linarith)]; simp
  · rw [min_eq_left (by linarith), min_eq_left (by linarith)]
    field_simp; ring

#print axioms sd_ramp

theorem sd_sum_bounds (h : ℝ) (hh : 0 < h) (b : ℝ) (D : ℕ → ℝ) (hD : ∀ j, 0 ≤ D j) (m : ℕ)
    (x : ℝ) :
    (x ≤ b → ∑ j ∈ Finset.range m,
      D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        = 0) ∧
    (b + (m : ℝ) * h ≤ x → ∑ j ∈ Finset.range m,
      D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        = ∑ j ∈ Finset.range m, D j) ∧
    (∀ i, i < m → b + (i : ℝ) * h ≤ x → x ≤ b + ((i + 1 : ℕ) : ℝ) * h →
      ∑ j ∈ Finset.range i, D j ≤ ∑ j ∈ Finset.range m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1) ∧
      ∑ j ∈ Finset.range m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        ≤ ∑ j ∈ Finset.range (i + 1), D j) := by
  have R := fun j : ℕ => sd_ramp h hh (b + (j : ℝ) * h) (b + ((j + 1 : ℕ) : ℝ) * h) x
    (by push_cast; ring)
  have hmono : ∀ i j : ℕ, i ≤ j → b + (i : ℝ) * h ≤ b + (j : ℝ) * h := by
    intro i j hij
    have : (i : ℝ) ≤ j := by exact_mod_cast hij
    nlinarith
  refine ⟨fun hx => ?_, fun hx => ?_, fun i hi hx1 hx2 => ⟨?_, ?_⟩⟩
  · refine Finset.sum_eq_zero fun j _ => ?_
    rw [(R j).2.2.2 (hx.trans (by simpa using hmono 0 j (Nat.zero_le j))), mul_zero]
  · refine Finset.sum_congr rfl fun j hj => ?_
    rw [(R j).2.2.1 ((hmono (j + 1) m (Finset.mem_range.mp hj)).trans hx), mul_one]
  · rw [← Finset.sum_range_add_sum_Ico _ hi.le]
    have h1 : ∑ j ∈ Finset.range i, D j = ∑ j ∈ Finset.range i,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1) := by
      refine Finset.sum_congr rfl fun j hj => ?_
      rw [(R j).2.2.1 ((hmono (j + 1) i (Finset.mem_range.mp hj)).trans hx1), mul_one]
    have h2 : 0 ≤ ∑ j ∈ Finset.Ico i m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1) :=
      Finset.sum_nonneg fun j _ => mul_nonneg (hD j) (R j).1
    linarith
  · rw [← Finset.sum_range_add_sum_Ico _ (Nat.succ_le_of_lt hi)]
    have h1 : ∑ j ∈ Finset.range (i + 1),
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        ≤ ∑ j ∈ Finset.range (i + 1), D j :=
      Finset.sum_le_sum fun j _ => mul_le_of_le_one_right (hD j) (R j).2.1
    have h2 : ∑ j ∈ Finset.Ico (i + 1) m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        = 0 := by
      refine Finset.sum_eq_zero fun j hj => ?_
      rw [(R j).2.2.2 (hx2.trans (hmono (i + 1) j (Finset.mem_Ico.mp hj).1)), mul_zero]
    linarith

#print axioms sd_sum_bounds

theorem sd_cover (b h : ℝ) (hh : 0 < h) (m : ℕ) (x : ℝ) :
    x ≤ b ∨ b + (m : ℝ) * h ≤ x ∨
      ∃ i, i < m ∧ b + (i : ℝ) * h ≤ x ∧ x ≤ b + ((i + 1 : ℕ) : ℝ) * h := by
  by_cases h1 : x ≤ b
  · exact Or.inl h1
  by_cases h2 : b + (m : ℝ) * h ≤ x
  · exact Or.inr (Or.inl h2)
  right; right
  push Not at h1 h2
  have hpos : 0 ≤ (x - b) / h := div_nonneg (by linarith) hh.le
  refine ⟨⌊(x - b) / h⌋₊, ?_, ?_, ?_⟩
  · rw [Nat.floor_lt hpos, div_lt_iff₀ hh]; linarith
  · have := Nat.floor_le hpos
    rw [le_div_iff₀ hh] at this; linarith
  · have := Nat.lt_floor_add_one ((x - b) / h)
    rw [div_lt_iff₀ hh] at this; push_cast; linarith

#print axioms sd_cover

theorem sd_approx (u : ℝ → ℝ) (hu : Monotone u) (hc : ConcaveOn ℝ Set.univ u) (a h : ℝ)
    (hh : 0 < h) (D : ℕ → ℝ) (hD : ∀ j, D j = u (a + ((j + 1 : ℕ) : ℝ) * h) - u (a + (j : ℝ) * h))
    (m : ℕ) (x : ℝ) :
    (x ≤ a - h + ((0 : ℕ) : ℝ) * h → u x ≤ u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
      ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
        min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ∧
      u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
      ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
        min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ≤ u a) ∧
    (a - h + (m : ℝ) * h ≤ x → u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
      ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
        min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) = u (a + (m : ℝ) * h)) ∧
    (∀ i, i < m → a - h + (i : ℝ) * h ≤ x → x ≤ a - h + ((i + 1 : ℕ) : ℝ) * h →
      u (a + (i : ℝ) * h) ≤ u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
        ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
          min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ∧
      u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
        ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
          min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ≤ u (a + ((i + 1 : ℕ) : ℝ) * h)) := by
  have hDnn : ∀ j, 0 ≤ D j := by
    intro j; rw [hD j]; apply sub_nonneg.mpr; apply hu; push_cast; nlinarith
  have tele : ∀ i, ∑ j ∈ Finset.range i, D j = u (a + (i : ℝ) * h) - u a := by
    intro i
    have := Finset.sum_range_sub (fun j : ℕ => u (a + (j : ℝ) * h)) i
    simp only [Nat.cast_zero, zero_mul, add_zero] at this
    rw [← this]
    exact Finset.sum_congr rfl fun j _ => hD j
  obtain ⟨S1, S2, S3⟩ := sd_sum_bounds h hh (a - h) D hDnn m x
  simp only [Nat.cast_zero, zero_mul, add_zero] at S1 ⊢
  refine ⟨fun hx => ?_, fun hx => ?_, fun i hi hx1 hx2 => ?_⟩
  · rw [S1 hx, add_zero, min_eq_left (by linarith)]
    have hD0 : D 0 = u (a + h) - u a := by rw [hD 0]; simp
    have hslope := hc.slope_anti_adjacent (Set.mem_univ x) (Set.mem_univ (a + h))
      (show x < a by linarith) (show a < a + h by linarith)
    rw [add_sub_cancel_left, ← hD0, div_le_div_iff₀ hh (by linarith)] at hslope
    have hd0 := hDnn 0
    constructor
    · have e : D 0 * (x - (a - h)) / h = D 0 * (x - a) / h + D 0 := by field_simp; ring
      have e2 : D 0 * (x - a) / h ≥ -(u a - u x) := by
        rw [ge_iff_le, le_div_iff₀ hh]; nlinarith
      linarith
    · have : D 0 * (x - (a - h)) / h ≤ 0 :=
        div_nonpos_of_nonpos_of_nonneg (mul_nonpos_of_nonneg_of_nonpos hd0 (by linarith)) hh.le
      linarith
  · have hx0 : a - h ≤ x := by
      have : (0 : ℝ) ≤ (m : ℝ) * h := by positivity
      linarith
    rw [S2 hx, min_eq_right (by linarith), tele m]; simp
  · have hx0 : a - h ≤ x := by
      have : (0 : ℝ) ≤ (i : ℝ) * h := by positivity
      linarith
    obtain ⟨L, U⟩ := S3 i hi hx1 hx2
    rw [min_eq_right (by linarith), tele] at *
    simp only [mul_zero, zero_div, add_zero]
    constructor <;> linarith

#print axioms sd_approx

/-- First-order stochastic dominance. Fund A (return distribution `μ`) gives every investor who
prefers more money to less (every increasing utility `u` whose averages exist) at least the
average utility of fund B (distribution `ν`) exactly when, at every threshold `t`, A is no more
likely than B to end at or below `t`: `F_A(t) ≤ F_B(t)`. -/
theorem first_order_dominance_iff_cdf_le (μ ν : Measure ℝ)
    [IsProbabilityMeasure μ] [IsProbabilityMeasure ν] :
    (∀ u : ℝ → ℝ, Monotone u → Integrable u μ → Integrable u ν →
        ∫ x, u x ∂ν ≤ ∫ x, u x ∂μ) ↔
      ∀ t : ℝ, cdf μ t ≤ cdf ν t := by
  constructor
  · intro H t
    have hmono : Monotone ((Set.Ioi t).indicator (1 : ℝ → ℝ)) := by
      intro a b hab
      simp only [Set.indicator, Set.mem_Ioi, Pi.one_apply]
      split_ifs with h1 h2 <;> first | exact le_rfl | exact absurd (h1.trans_le hab) h2 | norm_num
    have hint : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] →
        Integrable ((Set.Ioi t).indicator (1 : ℝ → ℝ)) ρ := fun ρ _ =>
      (integrable_const (1 : ℝ)).indicator measurableSet_Ioi
    have hval : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] →
        ∫ x, (Set.Ioi t).indicator (1 : ℝ → ℝ) x ∂ρ = 1 - cdf ρ t := by
      intro ρ _
      rw [integral_indicator_one measurableSet_Ioi, cdf_eq_real, ← Set.compl_Iic,
        probReal_compl_eq_one_sub measurableSet_Iic]
    have := H _ hmono (hint μ) (hint ν)
    rw [hval, hval] at this
    linarith
  · intro hF u hu hiμ hiν
    have hum : Measurable u := hu.measurable
    rw [integral_eq_lintegral_pos_part_sub_lintegral_neg_part hiμ,
      integral_eq_lintegral_pos_part_sub_lintegral_neg_part hiν]
    have hpos : ∀ ρ : Measure ℝ, ∫⁻ x, ENNReal.ofReal (u x) ∂ρ =
        ∫⁻ s in Set.Ioi 0, ρ {a | s < max (u a) 0} := by
      intro ρ
      rw [← lintegral_eq_lintegral_meas_lt (f := fun x => max (u x) 0) ρ
        (Filter.Eventually.of_forall fun x => le_max_right _ _) (by fun_prop)]
      congr 1; ext x; simp [ENNReal.ofReal_max]
    have hneg : ∀ ρ : Measure ℝ, ∫⁻ x, ENNReal.ofReal (-u x) ∂ρ =
        ∫⁻ s in Set.Ioi 0, ρ {a | s < max (-u a) 0} := by
      intro ρ
      rw [← lintegral_eq_lintegral_meas_lt (f := fun x => max (-u x) 0) ρ
        (Filter.Eventually.of_forall fun x => le_max_right _ _) (by fun_prop)]
      congr 1; ext x; simp [ENNReal.ofReal_max]
    have hP : ∫⁻ x, ENNReal.ofReal (u x) ∂ν ≤ ∫⁻ x, ENNReal.ofReal (u x) ∂μ := by
      rw [hpos, hpos]
      refine lintegral_mono fun s => ?_
      refine sd_upperSet_le μ ν hF _ ?_ (measurableSet_lt measurable_const (by fun_prop))
      intro a b hab ha
      simp only [Set.mem_ofPred_eq] at ha ⊢
      exact ha.trans_le (max_le_max (hu hab) le_rfl)
    have hN : ∫⁻ x, ENNReal.ofReal (-u x) ∂μ ≤ ∫⁻ x, ENNReal.ofReal (-u x) ∂ν := by
      rw [hneg, hneg]
      refine lintegral_mono fun s => ?_
      refine sd_lowerSet_le μ ν hF _ ?_
      intro a b hab ha
      simp only [Set.mem_ofPred_eq] at ha ⊢
      exact ha.trans_le (max_le_max (neg_le_neg (hu hab)) le_rfl)
    have h1 := ENNReal.toReal_mono hiμ.lintegral_lt_top.ne hP
    have hfin : ∫⁻ x, ENNReal.ofReal (-u x) ∂ν < ⊤ := hiν.neg.lintegral_lt_top
    have h2 := ENNReal.toReal_mono hfin.ne hN
    linarith

/-- Second-order stochastic dominance. When both funds have finite averages, fund A (`μ`) gives
every investor who prefers more money to less and dislikes risk (every increasing concave
utility `u` whose averages exist) at least the average utility of fund B (`ν`) exactly when, at
every cutoff `k`, A's average shortfall `E[(k - A)⁺]` is no larger than B's. -/
theorem second_order_dominance_iff_shortfall_le (μ ν : Measure ℝ)
    [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hμ : Integrable (fun x => x) μ) (hν : Integrable (fun x => x) ν) :
    (∀ u : ℝ → ℝ, Monotone u → ConcaveOn ℝ Set.univ u → Integrable u μ → Integrable u ν →
        ∫ x, u x ∂ν ≤ ∫ x, u x ∂μ) ↔
      ∀ k : ℝ, ∫ x, max (k - x) 0 ∂μ ≤ ∫ x, max (k - x) 0 ∂ν := by
  have e : ∀ (ρ : Measure ℝ) (k : ℝ), ∫ x, min (x - k) 0 ∂ρ = -∫ x, max (k - x) 0 ∂ρ := by
    intro ρ k
    rw [← integral_neg]
    congr 1
    funext x
    rw [min_def, max_def]
    split_ifs <;> linarith
  constructor
  · intro H k
    have hmono : Monotone (fun x : ℝ => min (x - k) 0) :=
      fun a b hab => min_le_min (by linarith) le_rfl
    have hconc : ConcaveOn ℝ Set.univ (fun x : ℝ => min (x - k) 0) := by
      refine ⟨convex_univ, fun x _ y _ a b ha hb hab => ?_⟩
      simp only [smul_eq_mul]
      refine le_min ?_ ?_
      · have h1 := mul_le_mul_of_nonneg_left (min_le_left (x - k) 0) ha
        have h2 := mul_le_mul_of_nonneg_left (min_le_left (y - k) 0) hb
        have hk : a * (x - k) + b * (y - k) = a * x + b * y - k := by linear_combination (-k) * hab
        linarith
      · nlinarith [min_le_right (x - k) 0, min_le_right (y - k) 0]
    have := H _ hmono hconc (sd_min_integrable μ hμ k) (sd_min_integrable ν hν k)
    rw [e, e] at this
    linarith
  · intro hS u hu hc hiμ hiν
    have H : ∀ k, ∫ x, min (x - k) 0 ∂ν ≤ ∫ x, min (x - k) 0 ∂μ := by
      intro k; rw [e, e]; linarith [hS k]
    have hcont : Continuous u := by
      have := hc.continuousOn_interior
      rw [interior_univ] at this
      exact continuousOn_univ.mp this
    set a : ℕ → ℝ := fun n => -((n : ℝ) + 1) with ha
    set h : ℕ → ℝ := fun n => 1 / ((n : ℝ) + 1) with hh
    set m : ℕ → ℕ := fun n => 2 * (n + 1) ^ 2 with hm
    set Dn : ℕ → ℕ → ℝ := fun n j => u (a n + ((j + 1 : ℕ) : ℝ) * h n) - u (a n + (j : ℝ) * h n)
      with hDn
    set V : ℕ → ℝ → ℝ := fun n x => u (a n) +
      Dn n 0 * min (x - (a n - h n + ((0 : ℕ) : ℝ) * h n)) 0 / h n +
      ∑ j ∈ Finset.range (m n), Dn n j * ((min (x - (a n - h n + ((j + 1 : ℕ) : ℝ) * h n)) 0 -
        min (x - (a n - h n + (j : ℝ) * h n)) 0) / h n + 1) with hV
    have hpos : ∀ n, 0 < h n := fun n => by simp only [hh]; positivity
    have hle1 : ∀ n, h n ≤ 1 := fun n => by
      simp only [hh]
      rw [div_le_one (by positivity)]
      have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      linarith
    have hmh : ∀ n, ((m n : ℕ) : ℝ) * h n = 2 * ((n : ℝ) + 1) := fun n => by
      simp only [hm, hh]; push_cast; field_simp
    have hDnn : ∀ n j, 0 ≤ Dn n j := by
      intro n j; simp only [hDn]; apply sub_nonneg.mpr; apply hu
      have := hpos n; push_cast; nlinarith
    have hDa : ∀ n j, Dn n (j + 1) ≤ Dn n j := by
      intro n j
      have hp := hpos n
      have hs := hc.slope_anti_adjacent (Set.mem_univ (a n + (j : ℝ) * h n))
        (Set.mem_univ (a n + ((j + 1 + 1 : ℕ) : ℝ) * h n))
        (show a n + (j : ℝ) * h n < a n + ((j + 1 : ℕ) : ℝ) * h n by push_cast; linarith)
        (show a n + ((j + 1 : ℕ) : ℝ) * h n < a n + ((j + 1 + 1 : ℕ) : ℝ) * h n by
          push_cast; linarith)
      have e1 : a n + ((j + 1 + 1 : ℕ) : ℝ) * h n - (a n + ((j + 1 : ℕ) : ℝ) * h n) = h n := by
        push_cast; ring
      have e2 : a n + ((j + 1 : ℕ) : ℝ) * h n - (a n + (j : ℝ) * h n) = h n := by
        push_cast; ring
      rw [e1, e2, div_le_div_iff_of_pos_right hp] at hs
      simpa only [hDn] using hs
    -- comparison for each approximant
    have hcone := fun n => sd_cone μ ν hμ hν H (u (a n)) (h n) (hpos n)
      (fun j => a n - h n + (j : ℝ) * h n) (Dn n) (hDa n) (m n)
    have hcmp : ∀ n, ∫ x, V n x ∂ν ≤ ∫ x, V n x ∂μ := by
      intro n
      obtain ⟨_, _, hle⟩ := hcone n
      have h0 : 0 ≤ Dn n (m n) * (∫ x, min (x - (a n - h n + ((m n : ℕ) : ℝ) * h n)) 0 ∂μ -
          ∫ x, min (x - (a n - h n + ((m n : ℕ) : ℝ) * h n)) 0 ∂ν) / h n :=
        div_nonneg (mul_nonneg (hDnn n (m n)) (sub_nonneg.mpr (H _))) (hpos n).le
      exact sub_nonneg.mp (h0.trans hle)
    -- pointwise bounds
    have hbound : ∀ n x, (min (u x) (u 0) ≤ V n x ∧ V n x ≤ u (max x 0 + 2)) ∧
        (a n - h n < x → x < a n - h n + ((m n : ℕ) : ℝ) * h n →
          u x ≤ V n x ∧ V n x ≤ u (x + 2 * h n)) := by
      intro n x
      have hp := hpos n
      have h1 := hle1 n
      have hmhn := hmh n
      have han : a n = -((n : ℝ) + 1) := rfl
      have hn0 : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      obtain ⟨A1, A2, A3⟩ := sd_approx u hu hc (a n) (h n) hp (Dn n) (fun j => rfl) (m n) x
      have hmax : x ≤ max x 0 := le_max_left _ _
      have hmax0 : 0 ≤ max x 0 := le_max_right _ _
      rcases sd_cover (a n - h n) (h n) hp (m n) x with hx | hx | ⟨i, hi, hx1, hx2⟩
      · obtain ⟨l, r⟩ := A1 (by simpa using hx)
        refine ⟨⟨(min_le_left _ _).trans l, r.trans (hu (by linarith))⟩, fun hx' _ => ?_⟩
        exact absurd hx (not_le.mpr hx')
      · have hv := A2 hx
        have hN : a n + ((m n : ℕ) : ℝ) * h n = (n : ℝ) + 1 := by rw [hmhn, han]; ring
        rw [hN] at hv
        refine ⟨⟨?_, ?_⟩, fun _ hx' => absurd hx (not_le.mpr hx')⟩
        · exact (min_le_right _ _).trans ((hu (by linarith : (0 : ℝ) ≤ (n : ℝ) + 1)).trans hv.ge)
        · exact hv.le.trans (hu (by linarith))
      · obtain ⟨l, r⟩ := A3 i hi hx1 hx2
        have hx2' : x ≤ a n + (i : ℝ) * h n := by push_cast at hx2; linarith
        have hup : a n + ((i + 1 : ℕ) : ℝ) * h n ≤ x + 2 * h n := by push_cast; linarith
        refine ⟨⟨(min_le_left _ _).trans ((hu hx2').trans l), r.trans (hu (by linarith))⟩,
          fun _ _ => ⟨(hu hx2').trans l, r.trans (hu hup)⟩⟩
    -- domination
    set c := u 0 - u (-1) with hcdef
    have hc0 : 0 ≤ c := sub_nonneg.mpr (hu (by norm_num))
    have hlin : ∀ y, 0 < y → u y ≤ u 0 + c * y := by
      intro y hy
      have hs := hc.slope_anti_adjacent (Set.mem_univ (-1 : ℝ)) (Set.mem_univ y)
        (show (-1 : ℝ) < 0 by norm_num) hy
      rw [sub_zero, show (0 : ℝ) - -1 = 1 by norm_num, div_one, div_le_iff₀ hy] at hs
      linarith
    have hG : ∀ n x, ‖V n x‖ ≤ |u x| + 2 * |u 0| + c * (|x| + 2) := by
      intro n x
      obtain ⟨⟨l, r⟩, _⟩ := hbound n x
      have r2 := hlin (max x 0 + 2) (by positivity)
      have hmx : max x 0 ≤ |x| := max_le (le_abs_self x) (abs_nonneg x)
      have hcm : c * (max x 0 + 2) ≤ c * (|x| + 2) := mul_le_mul_of_nonneg_left (by linarith) hc0
      have hcm0 : 0 ≤ c * (|x| + 2) := mul_nonneg hc0 (by positivity)
      have lo : -|u x| - |u 0| ≤ min (u x) (u 0) :=
        le_min (by linarith [neg_abs_le (u x), abs_nonneg (u 0)])
          (by linarith [neg_abs_le (u 0), abs_nonneg (u x)])
      rw [Real.norm_eq_abs, abs_le]
      constructor
      · linarith [abs_nonneg (u 0)]
      · linarith [le_abs_self (u 0), abs_nonneg (u x), abs_nonneg (u 0)]
    have hGint : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] → Integrable u ρ →
        Integrable (fun x => x) ρ → Integrable (fun x => |u x| + 2 * |u 0| + c * (|x| + 2)) ρ := by
      intro ρ _ hu' hx'
      exact (hu'.abs.add (integrable_const _)).add ((hx'.abs.add (integrable_const 2)).const_mul c)
    -- convergence
    have hlim : ∀ x, Filter.Tendsto (fun n => V n x) Filter.atTop (nhds (u x)) := by
      intro x
      have ht : Filter.Tendsto (fun n : ℕ => x + 2 * h n) Filter.atTop (nhds x) := by
        have := ((tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).const_mul 2).const_add x
        rw [mul_zero, add_zero] at this
        exact this
      have hev : ∀ᶠ n in Filter.atTop, u x ≤ V n x ∧ V n x ≤ u (x + 2 * h n) := by
        refine Filter.eventually_atTop.2 ⟨⌈|x|⌉₊ + 1, fun n hn => ?_⟩
        have hn' : (⌈|x|⌉₊ : ℝ) + 1 ≤ n := by exact_mod_cast hn
        have hc1 := Nat.le_ceil |x|
        have hax := neg_abs_le x
        have hxa := le_abs_self x
        have hp := hpos n
        have h1 := hle1 n
        refine (hbound n x).2 ?_ ?_
        · simp only [ha]; linarith
        · rw [hmh n]; simp only [ha]; linarith
      exact tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds
        ((hcont.tendsto x).comp ht) (hev.mono fun n hn => hn.1) (hev.mono fun n hn => hn.2)
    have Tμ := tendsto_integral_of_dominated_convergence (μ := μ) (F := V) (f := u) _
      (fun n => (hcone n).1.aestronglyMeasurable) (hGint μ hiμ hμ)
      (fun n => ae_of_all _ (hG n)) (ae_of_all _ hlim)
    have Tν := tendsto_integral_of_dominated_convergence (μ := ν) (F := V) (f := u) _
      (fun n => (hcone n).2.1.aestronglyMeasurable) (hGint ν hiν hν)
      (fun n => ae_of_all _ (hG n)) (ae_of_all _ hlim)
    exact le_of_tendsto_of_tendsto' Tν Tμ hcmp

/-- The shortfall is the area under the CDF: the average amount `E[(k - A)⁺]` by which a fund
falls short of a cutoff `k` equals `∫_{-∞}^{k} F_A(t) dt`. -/
theorem shortfall_eq_integral_cdf (μ : Measure ℝ) [IsProbabilityMeasure μ] (k : ℝ) :
    ∫ x, max (k - x) 0 ∂μ = ∫ t in Set.Iic k, cdf μ t := by
  rw [integral_eq_lintegral_of_nonneg_ae (f := fun x => max (k - x) 0) (Filter.Eventually.of_forall fun x => le_max_right _ _)
    (by fun_prop),
    integral_eq_lintegral_of_nonneg_ae (f := fun t => cdf μ t) (Filter.Eventually.of_forall fun x => cdf_nonneg μ x)
    ((monotone_cdf μ).measurable.aestronglyMeasurable), sd_shortfall_lintegral]

/-! The card's three funds, as lists of (return in percent, probability). -/

/-- Chance that a finite fund ends at or below `t`. -/
def fundCdf (f : List (ℚ × ℚ)) (t : ℚ) : ℚ :=
  ((f.filter fun p => p.1 ≤ t).map Prod.snd).sum

/-- Average shortfall `E[(k - X)⁺]` of a finite fund below the cutoff `k`. -/
def fundShortfall (f : List (ℚ × ℚ)) (k : ℚ) : ℚ :=
  (f.map fun p => p.2 * max (k - p.1) 0).sum

/-- Average utility `E[u(X)]` of a finite fund. -/
def fundAvg (f : List (ℚ × ℚ)) (u : ℚ → ℚ) : ℚ :=
  (f.map fun p => p.2 * u p.1).sum

def steady : List (ℚ × ℚ) := [(2, 1)]
def swing : List (ℚ × ℚ) := [(-2, 1/2), (6, 1/2)]
def upside : List (ℚ × ℚ) := [(-2, 1/2), (8, 1/2)]

-- Means: Steady 2, Swing 2, Upside 3.
example : fundAvg steady id = 2 ∧ fundAvg swing id = 2 ∧ fundAvg upside id = 3 := by
  norm_num [fundAvg, steady, swing, upside]

-- Upside vs Swing, CDFs at -2, 2, 6, 8: Upside 1/2, 1/2, 1/2, 1 against Swing 1/2, 1/2, 1, 1.
example : [fundCdf upside (-2), fundCdf upside 2, fundCdf upside 6, fundCdf upside 8] = [1/2, 1/2, 1/2, 1] ∧
    [fundCdf swing (-2), fundCdf swing 2, fundCdf swing 6, fundCdf swing 8] = [1/2, 1/2, 1, 1] := by
  norm_num [fundCdf, upside, swing]

-- Steady vs Swing, CDF at 2: Steady 1 against Swing 1/2, so first order fails.
example : fundCdf steady 2 = 1 ∧ fundCdf swing 2 = 1/2 := by
  norm_num [fundCdf, steady, swing]

-- Steady vs Swing, shortfalls at -2, 2, 6, 8: Steady 0, 0, 4, 6 against Swing 0, 2, 4, 6.
example : [fundShortfall steady (-2), fundShortfall steady 2, fundShortfall steady 6, fundShortfall steady 8] = [0, 0, 4, 6] ∧
    [fundShortfall swing (-2), fundShortfall swing 2, fundShortfall swing 6, fundShortfall swing 8] = [0, 2, 4, 6] := by
  norm_num [fundShortfall, steady, swing]

-- Steady vs Upside: shortfall at 2 is 0 against 2, at 8 is 6 against 5, so neither dominates.
example : fundShortfall steady 2 = 0 ∧ fundShortfall upside 2 = 2 ∧
    fundShortfall steady 8 = 6 ∧ fundShortfall upside 8 = 5 := by
  norm_num [fundShortfall, steady, upside]

-- Swing's shortfall at 4 is 3, the same as the area under its CDF: 1/2 × 6.
example : fundShortfall swing 4 = 3 ∧ fundCdf swing 4 * (4 - (-2)) = 3 := by
  norm_num [fundShortfall, fundCdf, swing]

-- Two risk-averse witnesses disagree: capped at 2, Steady 2 against Upside 0; linear, Steady 2 against Upside 3.
example : fundAvg steady (fun r => min r 2) = 2 ∧ fundAvg upside (fun r => min r 2) = 0 ∧
    fundAvg steady id = 2 ∧ fundAvg upside id = 3 := by
  norm_num [fundAvg, steady, upside]

#print axioms first_order_dominance_iff_cdf_le
#print axioms second_order_dominance_iff_shortfall_le
#print axioms shortfall_eq_integral_cdf
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'sd_shortfall_lintegral' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_lowerSet_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_upperSet_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_min_integrable' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_ramp_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_cone' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_ramp' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_sum_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_cover' depends on axioms: [propext, Classical.choice, Quot.sound]
'sd_approx' depends on axioms: [propext, Classical.choice, Quot.sound]
'first_order_dominance_iff_cdf_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'second_order_dominance_iff_shortfall_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'shortfall_eq_integral_cdf' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run.
> - **Swing's good outcome from 6 to 7.** Does Steady still dominate Swing at second order? No. At cutoff 8 its shortfall is 5.50 against Steady's 6.00. The pair becomes unranked.
> - **Upside's bad outcome from −2 to −3.** Does Upside still dominate Swing? Not at either order. At −3 Upside's CDF is 0.50 and Swing's 0.00; at cutoff −2 Upside's shortfall is 0.50 and Swing's 0.00.
> - **The house fund's spread from 15% to 1%.** Its chance of ending below 4% falls to 31.671 per million, and its shortfall at 4 to 7.145 per million. Tiny, not zero: still no dominance over the deposit.

---

## The usual mistake

> [!warning]
> **Reading first-order dominance as "wins in every outcome".** It is a statement about two distributions, not about how the funds move together. Upside first-order dominates Swing, yet if the two are drawn independently, Swing ends above Upside with probability 0.25: Swing lands on +6 while Upside lands on −2. Outcome-by-outcome dominance is a stronger condition, and it needs a statement about how the funds are linked.
>
> Smaller traps:
> - **Mean and spread as a verdict.** Steady and Swing tie on the mean (difference 0.00); Upside has 5.00 more spread than Steady yet a linear investor prefers it. Dominance uses the whole distribution.
> - **Unranked read as equal.** Steady and Upside are not equally good; they are unranked. 639 of 2,000 random risk-averse investors prefer Upside, the rest prefer Steady.
> - **Second order without the mean.** A linear utility is increasing and concave, so a second-order winner never has the lower mean. Steady, at 2, cannot second-order dominate Upside, at 3.
> - **Fewer cutoffs than outcomes.** One cutoff proves nothing: Upside's shortfall is 1.00 lower at 8 and 2.00 higher at 2.

---

## Where you meet it in real life

- **Choosing among funds.** A fund that is first-order dominated by another with the same fees is a choice no money-lover should make; academic tests of whether a market index is second-order efficient (no portfolio of the same assets second-order dominates it) ask the same question of a whole portfolio.
- **Insurance.** Insuring at a fair premium swaps a gamble for its average: the insured position second-order dominates the uninsured one, as Steady dominates Swing. Every risk-averse buyer gains; the insurer's loading (the part of the premium above the average loss) is what makes the choice depend on the utility.
- **Income distributions.** At equal average income, one distribution second-order dominates another exactly when its Lorenz curve (the share of income held by the poorest fraction) is never below the other's. Welfare economists rank countries this way without choosing a welfare function.
- **Risk aversion measured in cash.** When dominance leaves two funds unranked, a single investor's ranking comes from comparing sure amounts: [Risk premium](03-certainty-equivalent-and-risk-premium.md).
- **Returns measured properly.** The tests need both funds' returns on one horizon and one convention: [Returns](01-returns-simple-log-and-annualised.md).

> **Say it back**
> First-order dominance means a fund wins for every investor who prefers more money to less. It holds exactly when the fund's chance of ending at or below every threshold is never higher. Second-order dominance means a fund wins for every such investor who is also risk-averse, and it holds exactly when the fund's average shortfall below every cutoff is never higher. Each test works because every utility in the class is a sum of simple bets whose averages are the CDF or the shortfall. Many pairs of funds, such as a sure deposit and a normal fund, are ranked by neither test.

---

## What this builds on

- [Expected utility](02-expected-utility-and-risk-aversion.md): the utility, its average as the investor's score, and concavity as risk aversion. This card ranks funds for all such investors at once.
- [Densities](../../09-Probability%20and%20statistics/04-Continuous%20Distributions/01-densities-and-cdfs.md): the CDF, the whole content of the first-order test, and the area under it, which is the shortfall.

## Where this goes next

- [Kelly](05-kelly-criterion-and-growth.md): one utility, the logarithm of wealth, chosen for a reason: it maximises long-run growth. It ranks the unranked pair Steady and Upside, in Upside's favour: 4.6335 against 4.6250.
- [Prospect theory in outline](06-prospect-theory-in-outline.md): how real people rank gambles, including the ways they violate first-order dominance.

When dominance leaves two funds unranked, a decision needs one utility, and the question becomes which one to choose.

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Hanoch, Giora, and Haim Levy. "The Efficiency Analysis of Choices Involving Risk." *Review of Economic Studies* 36, no. 3 (1969): 335–346. [doi:10.2307/2296431](https://doi.org/10.2307/2296431). First- and second-order tests and their equivalence with increasing and increasing concave utilities.
- Rothschild, Michael, and Joseph E. Stiglitz. "Increasing Risk: I. A Definition." *Journal of Economic Theory* 2, no. 3 (1970): 225–243. [doi:10.1016/0022-0531(70)90038-4](https://doi.org/10.1016/0022-0531(70)90038-4). The mean-preserving spread and the equal-mean equivalence stated in Step 5.
- Levy, Haim. *Stochastic Dominance: Investment Decision Making under Uncertainty*. Springer, 2016. [Publisher page](https://doi.org/10.1007/978-3-319-21708-6). The book-length treatment, with finance applications and the finite-outcome algorithms.
- MIT OpenCourseWare, 14.123 Microeconomic Theory III (Spring 2015), *Stochastic Dominance* lecture notes. [PDF](https://ocw.mit.edu/courses/14-123-microeconomic-theory-iii-spring-2015/875150f8deb05a910756a02a4f9f78a5_MIT14_123S15_Chap4.pdf). The CDF and integrated-CDF forms, proved by integration by parts.
