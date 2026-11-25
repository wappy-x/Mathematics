# Zero-density estimates: counting the zeros that might sit off the line, and what that buys for primes in short intervals

[Syllabus](../../../SYLLABUS.md) → [Algebraic and analytic number theory](../README.md) → [The Zeta Function and the Prime Number Theorem](../README.md#s02) → Zero-density estimates

---

## General Overview

There are 78,498 primes below a million. Now look only at the short window from 1,000,000 to 1,003,162. A sieve finds **246** primes in it. Near a million, primes come about once every log 10^6 = 13.8155 integers (log is the natural logarithm on this card), so the window should hold 3,162 / 13.8155 = **228.9**. The count is 7.5 percent high, but it is the right size.

Is that luck, or is every window of that shape guaranteed its fair share once x is large? The prime number theorem cannot say. Write the window's width as a power of x, x^θ, with the exponent θ below 1 (here θ = 7/12). The theorem's error term is larger than x^θ for every θ below 1, so it says nothing about such a window.

The answer runs through the zeros of zeta. Each zero ρ = β + it (β its real part, t its height) adds one wave of size about x^β to the prime count ([The explicit formula](07-the-explicit-formula.md)). Across a window of width h, that wave moves by at most h x^(β − 1). A zero with β near 1 could swamp the window. A **zero-density estimate** is a theorem that such zeros are rare: it bounds N(σ, T), the number of zeros up to height T with real part at least σ.

The bound has the shape T^(A(1 − σ)), and the number A, the **density exponent**, is what matters. The smaller A is, the shorter the windows the primes are guaranteed to fill:

```
bar Ingham 1937   ############################  x^theta = 5,623
bar Huxley 1972   ################              x^theta = 3,162
bar Guth-Maynard  #############                 x^theta = 2,511
bar density hyp.  #####                         x^theta = 1,000
```

Each bar is the window width x^θ at x = 10^6, with θ = 1 − 1/A, one # per 200 integers. Ingham's A = 8/3 gives θ = 5/8, Huxley's 12/5 gives 7/12, Guth and Maynard's 30/13 gives 17/30. The **density hypothesis**, A = 2, gives 1/2 (its status is below).

**If at most about T^(A(1 − σ)) zeros up to height T have real part σ or more, then the explicit formula shows that every window [x, x + x^θ] with θ > 1 − 1/A holds about x^θ / log x primes once x is large; Huxley's A = 12/5 covers every θ above 7/12, and at a million the edge window x^(7/12), 3,162 wide, holds 246 primes against 228.9 predicted.**

**What kind of fact this is:** a theorem and two kinds of input. The step from a density exponent to short windows is proved on this card in Why it works, from two stated inputs: the cut explicit formula ([The explicit formula](07-the-explicit-formula.md)) and the Vinogradov–Korobov zero-free region (Montgomery, 1971). The density bounds of Ingham (1937 and 1940), Huxley (1972) and Guth and Maynard (2024, published 2026) are theorems stated with their sources, their method shown in outline. The window counts at a million are computations: evidence, not proof. The theorem gives no explicit starting point, so a million may sit below where it applies.

On status: the Riemann hypothesis (every nontrivial zero at real part 1/2) implies the density hypothesis. It was open until 2026-11-21, when a formal proof was certified; its dated status is on [The Riemann hypothesis](../../25-Frontier/02-The%20Millennium%20Problems/01-riemann-hypothesis.md). So the density hypothesis, and with it every θ above 1/2, now follows from that certified proof; zero-density methods alone have not reached it. Zero density is the route that reached short windows long before that, with proofs a person can read and without assuming anything about the zeros.

---

## The formula

Notation first, in words. As on the rest of this shelf, s = σ + it is zeta's complex input, and a zero in the critical strip is ρ = β + it. **N(σ, T)** counts the zeros with real part β ≥ σ and height t between 0 and T. At σ = 1/2 it counts every zero on the line, so it is essentially N(T), the count of all zeros. As σ rises toward 1 it counts only stragglers far from the line.

The density estimate, with density exponent A:

```math
N(\sigma, T) \le T^{A(1-\sigma) + o(1)} \qquad \left(\tfrac12 \le \sigma \le 1\right)
```

**Read it aloud:** the number of zeros up to height T with real part at least σ is at most T to the power A times one minus σ, times a factor that grows more slowly than any power of T.

Here o(1) is a quantity that shrinks to 0 as T grows. At σ = 1/2 the bound allows $`T^{A/2}`$ zeros, at least T: no limit beyond the count of all zeros. At σ = 1 it allows $`T^{o(1)}`$. The exponent falls in a straight line between.

What it buys, for every fixed θ with $`1 - 1/A < \theta < 1`$:

```math
\pi(x + x^{\theta}) - \pi(x) \sim \frac{x^{\theta}}{\log x} \qquad (x \to \infty)
```

**Read it aloud:** the number of primes between x and x plus x to the θ, divided by x to the θ over log x, tends to 1.

So for large x every such window holds a prime. For shorter windows the method gives less: almost every window, all but a vanishing share of x between X and 2X, holds its share once $`\theta > 1 - 2/A`$.

| Name | A | Every window, θ above | Almost every window, θ above | Window at 10^6 | Primes | Predicted |
| --- | --- | --- | --- | --- | --- | --- |
| Carlson 1921 | 4 | 3/4 | 1/2 | 31,622 | 2,315 | 2,288.9 |
| Ingham 1937 | 8/3 | 5/8 | 1/4 | 5,623 | 420 | 407.0 |
| Huxley 1972 | 12/5 | **7/12** | 1/6 | 3,162 | **246** | **228.9** |
| Guth–Maynard 2024 | 30/13 | 17/30 | 2/15 | 2,511 | 193 | 181.8 |
| density hypothesis | 2 | 1/2 | 0 | 1,000 | 75 | 72.4 |

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`x`$, $`h`$ | where the window starts; its width | 10^6; 3,162 | a longer window is easier to fill |
| $`\theta`$ | the window width as a power, $`h = x^{\theta}`$ | 7/12 | easier; below 1 − 1/A the proof gives nothing |
| $`\pi(x)`$, $`\psi(x)`$, $`\Lambda(n)`$ | primes up to x; the weighted count, log p at each prime power; its step sizes | 246 primes and ψ-gain 1.0750 h in the window | — |
| $`\rho = \beta + it`$, $`\sigma`$ | a zero, its real part, its height; a level of real part | first zero 1/2 + 14.134725i | a zero further right makes a bigger wave |
| $`T`$ | the height where the zero sum is cut: x/h, times a power of log x | x/h = 316.3 | more zeros to control |
| $`N(T)`$ | all zeros with height between 0 and T | smooth count 147.8 at height x/h = 316.3 | grows like (T/2π) log(T/2π) |
| $`N(\sigma, T)`$ | zeros up to height T with real part at least σ | 0 for σ > 1/2 up to height 3 × 10^12, by computation (Platt and Trudgian, 2021) | falls as σ rises |
| $`A`$ | the density exponent | 12/5 | longer windows needed |
| $`\kappa`$ | the margin $`1 - A(1-\theta)`$ that the proof spends | 1/10 at A = 12/5, θ = 5/8; 0 at the edge θ = 7/12 | faster saving |
| $`\eta(T)`$, $`c_{\mathrm{VK}}`$, $`R_0`$ | width of a zero-free strip left of real part 1; the fixed constants in its Vinogradov–Korobov and classical forms | about $`(\log T)^{-2/3}`$ in the Vinogradov–Korobov form; $`R_0`$ = 5.558691 in the classical $`1/(R_0 \log T)`$ | more saving near the edge |
| $`C`$, $`B`$; $`c`$ | the constant and the power of log T in a density bound; the exponent in a bound for zeta on the critical line | not computed; c = 1/6 in Ingham's 1937 bound | — |
| $`M_Y(s)`$, $`\mu`$, $`N`$, $`V`$, $`R`$ | the mollifier of Step 6 and the Möbius function in it; a Dirichlet polynomial's length; a size it reaches; how many places reach it | — | — |

Here $`f \sim g`$ means f/g tends to 1, and log is the natural logarithm.

### When it holds

- **x large, with no explicit start.** The proof wins by factors like $`\exp(-(\log x)^{1/4})`$, and its constants are not worked out. At x = 10^6 that factor is exp(−1.928) = 0.1454, with an unknown constant in front. The count of 246 is a check, not a consequence.
- **θ strictly above 1 − 1/A.** At θ = 1 − 1/A exactly, the margin κ is 0 and the density bound saves nothing. Below it, the possible stragglers outweigh the window.
- **A zero-free region wider than the classical one.** The classical region ([The zero-free region](03-the-zero-free-region.md)) saves only a fixed fraction (Step 5's fold). The proof needs the Vinogradov–Korobov width, about $`(\log T)^{-2/3}`$.
- **The bound near σ = 1 with only log losses.** A factor $`T^{o(1)}`$ is harmless in the middle of the strip but not right next to σ = 1. Guth and Maynard close that gap with older bounds that lose only powers of log T there.
- **Every window, not almost every.** The exponent 1 − 1/A is for every window; 1 − 2/A covers only all but a few (The usual mistake).

---

## Why it works

### Step 0: count against size

The idea in words. In the explicit formula, the prime count across a window is the window's width minus one term per zero. A zero with real part β makes a term of relative size about $`x^{\beta - 1}`$. Zeros on the line make tiny terms, near $`x^{-1/2}`$. A zero near real part 1 makes a term near 1, as big as the window itself.

So two numbers fight: how many zeros sit at real part σ, and how big each one's term is. The density bound caps the first at $`T^{A(1-\sigma)}`$. The size is $`x^{\sigma - 1}`$. Their product is $`(T^A/x)^{1-\sigma}`$. With T about x/h, this is small exactly when $`A(1-\theta) < 1`$, that is when θ > 1 − 1/A.

The theorem proved here takes the density bound in the form

```math
N(\sigma, T) \le C\, T^{A(1-\sigma)} (\log T)^{B} \qquad \left(\tfrac12 \le \sigma \le 1,\ T \ge 2\right)
```

with constants C and B. Guth and Maynard's bound, joined to older ones near σ = 1, gives this for every A larger than 30/13. That is enough for every θ > 17/30.

### Step 1: the explicit formula across a window

[The explicit formula](07-the-explicit-formula.md) gives, for 2 ≤ T ≤ x,

```math
\psi(x+h) - \psi(x) = h - \sum_{|t| \le T} \frac{(x+h)^{\rho} - x^{\rho}}{\rho} + O\left(\frac{x \log^2 x}{T}\right)
```

**Read it aloud:** the weighted prime count across the window is the width h, minus one term for each zero below height T, plus an error of size about x log² x over T.

Each zero's term is an integral, and its size is easy to bound, because $`|u^{\rho - 1}| = u^{\beta - 1} \le x^{\beta - 1}`$ for u at least x:

```math
\left|\frac{(x+h)^{\rho} - x^{\rho}}{\rho}\right| = \left|\int_x^{x+h} u^{\rho - 1}\, du\right| \le h\, x^{\beta - 1}
```

So everything rests on the sum of $`x^{\beta - 1}`$ over the zeros below T.

### Step 2: sort the zeros by real part

Write each zero's size as a pile of thin layers, one for every level σ it passes: $`x^{\beta-1} = x^{-1/2} + \log x \int_{1/2}^{\beta} x^{\sigma - 1}\, d\sigma`$ when β ≥ 1/2. Adding over zeros, a level σ is passed by exactly the zeros with β ≥ σ, which is N(σ, T) zeros of positive height. Zeros with β < 1/2, left of the line, cost less than $`x^{-1/2}`$ each. With the mirror zeros at negative heights:

```math
\sum_{|t| \le T} x^{\beta - 1} \le 2N(T)\, x^{-1/2} + 2 \log x \int_{1/2}^{1} x^{\sigma - 1} N(\sigma, T)\, d\sigma
```

**Read it aloud:** the zeros' total size is at most twice the number of zeros times one over root x, plus twice log x times the integral over σ of x to the σ minus one times the number of zeros at real part σ or more.

The first piece is the zeros near the line; the second, where the density bound goes, is the stragglers.

### Step 3: choose the cut height

Take $`T = (x/h)(\log x)^3`$. The cut error is then $`x\log^2 x / T = h / \log x`$, a vanishing share of h.

The zeros near the line cost $`h \cdot 2N(T) x^{-1/2}`$. Since N(T) is about T log T, this is about $`h\, x^{1/2-\theta} (\log x)^4`$, again a vanishing share of h, because θ > 1/2.

At x = 10^6 and h = 3,162, x/h, the cut height up to log factors, is 316.3, with about 147.8 zeros below it.

### Step 4: the density bound meets the size

Put the density bound into the integrand:

```math
x^{\sigma - 1} N(\sigma, T) \le C (\log T)^B \left(\frac{T^A}{x}\right)^{1-\sigma}, \qquad \frac{T^A}{x} = x^{-\kappa} (\log x)^{3A}, \quad \kappa = 1 - A(1 - \theta)
```

**Read it aloud:** each level's cost is at most a constant times a power of log T, times T to the A over x, raised to one minus σ; and T to the A over x is x to the minus κ, up to logs, where κ is one minus A times one minus θ.

The margin κ is positive exactly when θ > 1 − 1/A. The example's window x^(7/12) is the edge case: there κ = 0 and the proof gives nothing, so the theorem needs θ = 7/12 + ε. Take θ = 5/8 instead: for Huxley's A = 12/5, κ = 1 − (12/5)(3/8) = 1/10. Then each level σ costs about $`x^{-\kappa(1-\sigma)}`$, up to logs: tiny in the middle of the strip, but close to 1 as σ approaches 1.

### Step 5: the zero-free region clears the last strip

Near σ = 1 the factor $`x^{-\kappa(1-\sigma)}`$ saves almost nothing. A zero-free region removes those levels: N(σ, T) = 0 for σ > 1 − η(T).

The Vinogradov–Korobov region has $`\eta(T) = c_{\mathrm{VK}} (\log T)^{-2/3} (\log\log T)^{-1/3}`$, with a fixed constant $`c_{\mathrm{VK}} > 0`$ (Montgomery, 1971). On every level left, $`1 - \sigma \ge \eta(T)`$, so the cost is at most

```math
C (\log x)^{B} \exp\left(-\tfrac{\kappa}{2}\, \eta(T) \log x\right)
```

Since log T is at most log x, the exponent is at least a constant times $`(\log x)^{1/3} (\log\log x)^{-1/3}`$. That beats every power of log x. So the stragglers' total, times the extra log x of Step 2, is also a vanishing share of h. Adding Steps 3 to 5:

```math
\psi(x + x^{\theta}) - \psi(x) = x^{\theta}\,(1 + o(1))
```

From ψ to π: the window holds few prime powers $`p^k`$ with k ≥ 2, at most about $`h/\sqrt{x}`$ squares and fewer higher powers. Each prime in the window carries weight log p, between log x and log(x + h). Dividing by log x gives the prime count in The formula. At a million the weighted gain is 1.0750 h, and the plain count gives the same 1.075.

<details>
<summary>Detailed proof: why the classical zero-free region is not enough</summary>

The classical region has $`\eta(T) = 1/(R_0 \log T)`$ with $`R_0`$ = 5.558691. With T about $`x^{1-\theta}`$, log x / log T is about $`1/(1-\theta)`$, so the best saving on the last level is

$`\displaystyle \exp\left(-\kappa\, \eta(T) \log x\right) \approx \exp\left(-\frac{\kappa}{R_0(1-\theta)}\right)`$

That is a fixed number, not one that shrinks as x grows. For A = 12/5 and θ = 5/8 it is $`\exp(-0.1/(5.558691 \times 0.375)) = 0.9532`$. The power of log T in the density bound and the log x from Step 2 then win. The stragglers' bound becomes a power of log x times h, larger than the window itself, so the proof cannot even show that the window holds a prime. A region beats the logs only when $`\eta(T) \log T / \log\log T`$ grows without limit; the Vinogradov–Korobov region does. Guth and Maynard's Section 13 runs Steps 1 to 5 with the Vinogradov–Korobov region and gets the error $`x^{\theta}\exp(-(\log x)^{1/4})`$.

</details>

### Step 6: where density bounds come from, in outline

This step is stated, not proved. The idea is to turn each zero into a place where a short sum is large, then count such places.

1. **A mollifier.** Let $`M_Y(s) = \sum_{n \le Y} \mu(n) n^{-s}`$, a sum of length Y built to undo zeta (μ is the Möbius function). In $`\zeta(s) M_Y(s) = \sum a_n n^{-s}`$ the coefficient $`a_n`$ is the sum of μ(d) over divisors d ≤ Y of n. So $`a_1 = 1`$, and $`a_n = 0`$ for 2 ≤ n ≤ Y.
2. **Zeros detect themselves.** At a zero, $`\zeta M_Y = 0`$, so the terms with n > Y add to −1. Cut those terms into blocks with n between N and 2N. One block, a **Dirichlet polynomial** of length N (a sum of terms $`b_n n^{-it}`$; here N is a length, not a zero count), must be large at the zero's height: size V about $`N^{\sigma}`$, up to logs.
3. **Count large values.** Zeros, thinned to heights at least 1 apart, become points where a Dirichlet polynomial reaches V. The mean value theorem (an orthogonality bound on the average of its square) caps their number R by about $`(T + N) N V^{-2}`$. With $`V = N^{\sigma}`$ and N near T, that is $`T^{2(1-\sigma)}`$: the density hypothesis shape.
4. **The middle lengths are the hard case.** Short polynomials are raised to a power to make them long. The worst case is a length N near $`T^{4/5}`$ and a size V near $`N^{3/4}`$. Huxley's large values estimate there gives his envelope $`3/(3\sigma - 1)`$; Guth and Maynard's new estimate gives $`15/(3+5\sigma)`$.

Each bound is an envelope A(σ), and the density exponent is its largest value. Ingham has two. His 1937 bound gives the flat A = 8/3 (below). His 1940 bound, A(σ) = 3/(2 − σ), is at most 8/3 up to σ = 7/8 and reaches 3 only at σ = 1. Below σ = 3/4, Huxley uses that 1940 envelope; below 7/10, so do Guth and Maynard. The check scans σ from 1/2 to 1 in exact fractions. Huxley's envelope peaks at σ = 3/4 with value 12/5. Guth and Maynard's peaks at σ = 7/10 with value 30/13.

The older route, Carlson's and Ingham's, counts the zeros of $`f = \zeta M_Y`$ directly by Littlewood's lemma, a rectangle form of [Jensen's formula](../../07-Complex%20analysis/10-Entire%20and%20Meromorphic%20Functions/02-jensens-formula-and-order-of-growth.md). The average of log |f| along the rectangle's edge bounds the zeros inside, and the mean square of $`1 - \zeta M_Y`$ is small. In 1937 Ingham fed in a bound on zeta on the critical line, $`|\zeta(1/2 + it)| \ll t^{c + \varepsilon}`$ with c = 1/6, and got A = 2(1 + 2c) = 8/3.

### Step 7: almost every window, stated

Average the squared error of Step 1 over x from X to 2X. Pairs of zeros appear, and their cross terms cancel unless the heights are close. What is left is about $`X h^{2}\, (T^{A}/X^{2})^{1-\sigma}`$ per level, against $`X h^{2}`$ for an error as large as the window. The x² in place of x doubles the margin, so the condition becomes θ > 1 − 2/A. Huxley's 12/5 gives 1/6, and Guth and Maynard's 30/13 gives 2/15, as their Corollary 1.4 states.

---

## Worked numbers, by hand

Huxley's exponent at the house example's scale, x = 10^6:

| Step | Arithmetic | Value |
| --- | --- | --- |
| window exponent | 1 − 1/A = 1 − 5/12 | 7/12 |
| window width | 10^(6 × 7/12) = 10^3.5 | 3162.28, so h = 3,162 |
| prime density | log 10^6 | 13.8155 |
| predicted primes | 3,162 ÷ 13.8155 | 228.9 |
| counted primes | sieve, and trial division | **246** |
| ratio | 246 ÷ 228.9 | 1.075 |
| difference | 246 − 228.9 | 17.1 |
| weighted gain | sum of log p over the window ÷ h | 1.0750 |

The window holds 7.5 percent more primes than its share: the right size, as the theorem predicts for large x.

Across every window (y, y + y^(7/12)] with y from 10^5 to 10^6, the check finds no empty window. The worst ratio is 0.7896, at y = 180,541, and the best is 1.1802.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Window exponent θ = 1/3, below every threshold | the gap of 114 after 492,113: (p, p + 78] holds 0 primes, predicted 5.95; 620 empty windows from 10^5 to 10^6; below 10^8 the last empty ones sit in the gap of 148 after 2,010,733, against a window of 126 | below 1 − 1/A the theorem says nothing, and even A = 2 needs θ > 1/2. A prime in every window [x, x + x^θ] with θ ≤ 1/2 is open as of 2026-11-24; Cramér's model predicts it, and these empty windows are a small-x effect |
| Read the almost-all exponent 1/6 as "every window" | count times size for one window at θ = 1/6: T^A/x = x^1, above 1, so the stragglers' bound exceeds the window; averaged over x, T^A/x^2 = x^0, the edge | only Step 7's average doubles the margin. A prime in every window of width x^(1/6) is not proved: it is open as of 2026-11-24, and Cramér's model predicts it |
| No density bound: every zero may have β near 1 | 147.8 zeros below height x/h = 316.3, error bound 296 times h | without a count of stragglers the zero sum outweighs the window |
| Classical zero-free region only | saving factor 0.9532 at every x | width 1/log T saves a fixed fraction, not one that shrinks |

The code prints every row.

---

## Code, from first principles, and it actually runs

The code takes three independent roads. **Exponents:** every θ and almost-all exponent is computed in exact fractions from A, checked against the values the papers state, and the envelopes of Huxley and of Guth and Maynard are scanned over 501 values of σ in exact fractions to recover 12/5 and 30/13, and Ingham's 1940 envelope is set against his 1937 8/3. **Counts:** a sieve counts the primes in each window, and trial division counts them again without the sieve; the weighted gain checks ψ. **Evidence:** every window from 10^5 to 10^6 is scanned at θ = 7/12, 1/3 and 1/6, the θ = 1/6 count is set beside a random model, the largest prime gap below a million is found, and a sieve to 10^8 finds the last empty window of width p^(1/3). Both programs print identical output.

### Python

```python
# Zero-density estimates and primes in short intervals -- the check behind the card.
# Standard library only.  Roads: exact exponent algebra in fractions; the density
# envelopes scanned on a grid; primes counted by a sieve and again by trial division.
import itertools
import math
from fractions import Fraction as F

X = 10 ** 6
LIM = X + 40000
BIG = 10 ** 8                                              # the cube-root windows are followed this far
ok = bytearray([0, 0]) + bytearray([1]) * (BIG - 1)       # Eratosthenes up to BIG
for i in range(2, int(BIG ** 0.5) + 1):
    if ok[i]:
        ok[i * i::i] = bytearray(len(range(i * i, BIG + 1, i)))
pi = [0] * (LIM + 1)                                       # pi[n] = primes up to n
for n in range(1, LIM + 1):
    pi[n] = pi[n - 1] + ok[n]

def is_prime_td(n):                                        # trial division, no sieve
    if n < 2:
        return False
    d = 2
    while d * d <= n:
        if n % d == 0:
            return False
        d += 1
    return True

def count(y, h):                                           # primes in (y, y + h]
    return pi[y + h] - pi[y]

print("house: primes below a million =", pi[X])
assert pi[X] == 78498                                      # the shelf's house count

# Road 1: the density envelopes, scanned on a grid of sigma, in exact fractions.
def huxley(s):
    return min(F(3) / (2 - s), F(3) / (3 * s - 1))
def guth_maynard(s):
    return min(F(3) / (2 - s), F(15) / (3 + 5 * s))
grid = [F(k, 1000) for k in range(500, 1001)]
for name, env, s_star in (("Huxley", huxley, F(3, 4)), ("Guth-Maynard", guth_maynard, F(7, 10))):
    best = max(grid, key=env)
    print(f"envelope {name}: max over sigma at {best} = {env(best)} (crossing solved: {s_star})")
    assert best == s_star
assert huxley(F(3, 4)) == F(12, 5) and guth_maynard(F(7, 10)) == F(30, 13)
cross = max(s for s in grid if F(3) / (2 - s) <= F(8, 3))  # Ingham 1940 against Ingham 1937's flat 8/3
print(f"envelope Ingham 1940: 3/(2 - sigma) is {F(3) / (2 - F(1))} at sigma = 1, at most 8/3 up to sigma = {cross} (solved: {2 - F(9, 8)})")
assert cross == 2 - F(9, 8)

# Road 2: theta = 1 - 1/A for every interval, 1 - 2/A for almost every interval.
rows = (("Carlson 1921", F(4)), ("Ingham 1937", F(8, 3)), ("Huxley 1972", F(12, 5)),
        ("Guth-Maynard", F(30, 13)), ("density hyp.", F(2)))
quoted_every = {F(8, 3): F(5, 8), F(12, 5): F(7, 12), F(30, 13): F(17, 30)}  # as stated by the papers
quoted_almost = {F(12, 5): F(1, 6), F(30, 13): F(2, 15)}
print(f"x = 10^6, log x = {math.log(X):.4f}")
r4 = math.log(X) ** 0.25
print(f"error shape exp(-(log x)^(1/4)) at 10^6 = exp(-{r4:.3f}) = {math.exp(-r4):.4f}")
print("name          A      theta  almost-all   x^theta      h  primes  h/log x    diff  ratio  psi-gain/h")
bars = []
for name, A in rows:
    th, aa = 1 - 1 / A, 1 - 2 / A
    if A in quoted_every:                                  # theta against the papers
        assert th == quoted_every[A]
    if A in quoted_almost:
        assert aa == quoted_almost[A]
    h = math.floor(X ** float(th))
    c = count(X, h)
    c_td = sum(1 for n in range(X + 1, X + h + 1) if is_prime_td(n))
    assert c == c_td                                       # sieve against trial division
    gain = sum(math.log(n) for n in range(X + 1, X + h + 1) if ok[n])
    pred = h / math.log(X)
    print(f"{name:13} {str(A):6} {str(th):6} {str(aa):10} {X ** float(th):9.2f} {h:6,}  {c:6}  {pred:7.1f}  {c - pred:6.1f}  {c / pred:.3f}  {gain / h:.4f}")
    bars.append((name, h))
for name, h in bars[1:]:                                   # one # per 200 integers
    print(f"bar {name:13} {'#' * round(h / 200):29} x^theta = {h:,}")

# Evidence across [10^5, 10^6]: every interval (y, y + y^theta] for two exponents.
for th, label in ((F(7, 12), "7/12"), (F(1, 3), "1/3")):
    lo, hi, arg_lo, empty = 9.0, 0.0, 0, 0
    for y in range(10 ** 5, X + 1):
        h = math.floor(y ** float(th))
        r = count(y, h) / (h / math.log(y))
        if r < lo:
            lo, arg_lo = r, y
        hi = max(hi, r)
        empty += count(y, h) == 0
    print(f"scan theta={label}: worst ratio {lo:.4f} at y={arg_lo:,}, best {hi:.4f}, empty intervals {empty:,}")
    if th == F(7, 12):
        assert empty == 0 and lo > 0.75
    else:
        assert empty > 0

# What breaks 1: the largest prime gap below a million, against theta = 1/3.
ps = [n for n in range(2, X + 1) if ok[n]]
g, p = max((ps[k + 1] - ps[k], ps[k]) for k in range(len(ps) - 1))
h = math.floor(p ** (1 / 3))
print(f"breaks: gap {g} after {p:,}; (p, p + {h}] holds {count(p, h)} primes, predicted {h / math.log(p):.2f}")
assert g == 114 and p == 492113 and count(p, h) == 0
last, prev = None, 2                                       # the last empty (p, p + p^(1/3)] below BIG
for p in itertools.compress(range(BIG + 1), ok):
    if p - prev > math.floor(prev ** (1 / 3)):
        last = (prev, p - prev, math.floor(prev ** (1 / 3)))
    prev = p
print(f"breaks: below 10^8 the last empty (p, p + p^(1/3)] is at p = {last[0]:,}: gap {last[1]} against a window of {last[2]}")
assert last[:2] == (2010733, 148)                          # a record gap in the maximal-gap tables

# What breaks 2: read the almost-all exponent 1/6 as 'every interval'. Count times size as a power of x,
# T = x^(1 - theta): one window (T^A/x)^(1-sigma), Step 0, k = 1; averaged over x (T^A/x^2)^(1-sigma), Step 7, k = 2.
A = F(12, 5)
def cs(th, k):
    return A * (1 - th) - k
print(f"breaks: count x size, A=12/5, as a power of x: one window x^{cs(1 - 1 / A, 1)} at theta=7/12, "
      f"x^{cs(F(1, 6), 1)} at theta=1/6; averaged over x, x^{cs(F(1, 6), 2)} at theta=1/6")
assert cs(F(1, 6), 1) > 0 >= cs(F(1, 6), 2)
bad, model, hs = 0, 0.0, set()                             # at a million: windows shorter than the mean gap
for y in range(10 ** 5, X + 1):
    h = math.floor(y ** (1 / 6))
    hs.add(h)
    bad += count(y, h) == 0
    model += (1 - 1 / math.log(y)) ** h                    # each integer prime with chance 1/log y
print(f"breaks: theta=1/6, widths {min(hs)} to {max(hs)}, mean gap log y {math.log(10 ** 5):.4f} to {math.log(X):.4f}; "
      f"empty {bad:,} of 900,001 = {bad / 900001:.4f}, random model {model / 900001:.4f}")
assert abs(bad - model) < 0.1 * 900001

# What breaks 3: no density bound. Up to T = x/h every zero may add up to 2h.
T = X / 3162
NT = T / (2 * math.pi) * math.log(T / (2 * math.pi)) - T / (2 * math.pi) + 7 / 8
print(f"breaks: no density bound, T = {T:.1f}, smooth N(T) = {NT:.1f}, error bound {2 * NT:.0f} times h")

# What breaks 4: classical zero-free region only, width 1/(5.558691 log T).
kappa = 1 - F(12, 5) * F(3, 8)                             # A = 12/5, theta = 5/8
saving = math.exp(-float(kappa) / 5.558691 / (3 / 8))
print(f"breaks: classical region, A=12/5, theta=5/8, kappa={kappa}, saving factor {saving:.4f} at every x")
assert kappa == F(1, 10) and 0.9 < saving < 1
print("quoted, not computed: classical region width 1/(5.558691 log t); zeros on the line to 3 x 10^12;")
print("quoted, not computed: first zero 1/2 + 14.134725i; Ingham uses |zeta(1/2 + it)| << t^(1/6 + eps)")
print("quoted, not computed: a prime in every [x - x^0.525, x] (Baker-Harman-Pintz 2001)")
print("ALL CHECKS PASS")
```

**Ran 2026-11-24 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
house: primes below a million = 78498
envelope Huxley: max over sigma at 3/4 = 12/5 (crossing solved: 3/4)
envelope Guth-Maynard: max over sigma at 7/10 = 30/13 (crossing solved: 7/10)
envelope Ingham 1940: 3/(2 - sigma) is 3 at sigma = 1, at most 8/3 up to sigma = 7/8 (solved: 7/8)
x = 10^6, log x = 13.8155
error shape exp(-(log x)^(1/4)) at 10^6 = exp(-1.928) = 0.1454
name          A      theta  almost-all   x^theta      h  primes  h/log x    diff  ratio  psi-gain/h
Carlson 1921  4      3/4    1/2         31622.78 31,622    2315   2288.9    26.1  1.011  1.0125
Ingham 1937   8/3    5/8    1/4          5623.41  5,623     420    407.0    13.0  1.032  1.0321
Huxley 1972   12/5   7/12   1/6          3162.28  3,162     246    228.9    17.1  1.075  1.0750
Guth-Maynard  30/13  17/30  2/15         2511.89  2,511     193    181.8    11.2  1.062  1.0620
density hyp.  2      1/2    0            1000.00  1,000      75     72.4     2.6  1.036  1.0362
bar Ingham 1937   ############################  x^theta = 5,623
bar Huxley 1972   ################              x^theta = 3,162
bar Guth-Maynard  #############                 x^theta = 2,511
bar density hyp.  #####                         x^theta = 1,000
scan theta=7/12: worst ratio 0.7896 at y=180,541, best 1.1802, empty intervals 0
scan theta=1/3: worst ratio 0.0000 at y=100,853, best 2.6667, empty intervals 620
breaks: gap 114 after 492,113; (p, p + 78] holds 0 primes, predicted 5.95
breaks: below 10^8 the last empty (p, p + p^(1/3)] is at p = 2,010,733: gap 148 against a window of 126
breaks: count x size, A=12/5, as a power of x: one window x^0 at theta=7/12, x^1 at theta=1/6; averaged over x, x^0 at theta=1/6
breaks: theta=1/6, widths 6 to 9, mean gap log y 11.5129 to 13.8155; empty 430,516 of 900,001 = 0.4784, random model 0.5168
breaks: no density bound, T = 316.3, smooth N(T) = 147.8, error bound 296 times h
breaks: classical region, A=12/5, theta=5/8, kappa=1/10, saving factor 0.9532 at every x
quoted, not computed: classical region width 1/(5.558691 log t); zeros on the line to 3 x 10^12;
quoted, not computed: first zero 1/2 + 14.134725i; Ingham uses |zeta(1/2 + it)| << t^(1/6 + eps)
quoted, not computed: a prime in every [x - x^0.525, x] (Baker-Harman-Pintz 2001)
ALL CHECKS PASS
```

### Rust

```rust
// Zero-density estimates and primes in short intervals -- the check behind the card.
// std only.  Roads: exact exponent algebra in fractions; the density envelopes
// scanned on a grid; primes counted by a sieve and again by trial division.
use std::cmp::Ordering;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }                                // a reduced fraction n/d, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d) * if d < 0 { -1 } else { 1 };
    Q { n: n / g, d: d / g }
}
impl Q {
    fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) }
    fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) }
    fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) }
    fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) }
    fn cmp(self, o: Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) }
    fn min(self, o: Q) -> Q { if self.cmp(o) == Ordering::Greater { o } else { self } }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
    fn s(self) -> String { if self.d == 1 { format!("{}", self.n) } else { format!("{}/{}", self.n, self.d) } }
}
fn int(n: i128) -> Q { q(n, 1) }
fn commas(n: u64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
fn is_prime_td(n: usize) -> bool {                           // trial division, no sieve
    if n < 2 { return false; }
    let mut d = 2;
    while d * d <= n { if n % d == 0 { return false; } d += 1; }
    true
}
fn huxley(s: Q) -> Q { int(3).div(int(2).sub(s)).min(int(3).div(int(3).mul(s).sub(int(1)))) }
fn guth_maynard(s: Q) -> Q { int(3).div(int(2).sub(s)).min(int(15).div(int(3).add(int(5).mul(s)))) }

fn main() {
    const X: usize = 1_000_000;
    const LIM: usize = X + 40000;
    const BIG: usize = 100_000_000;                          // the cube-root windows are followed this far
    let mut ok = vec![true; BIG + 1];                        // Eratosthenes up to BIG
    ok[0] = false; ok[1] = false;
    let mut i = 2;
    while i * i <= BIG {
        if ok[i] { let mut j = i * i; while j <= BIG { ok[j] = false; j += i; } }
        i += 1;
    }
    let mut pi = vec![0usize; LIM + 1];                      // pi[n] = primes up to n
    for n in 1..=LIM { pi[n] = pi[n - 1] + ok[n] as usize; }
    let count = |y: usize, h: usize| pi[y + h] - pi[y];      // primes in (y, y + h]
    println!("house: primes below a million = {}", pi[X]);
    assert_eq!(pi[X], 78498);

    // Road 1: the density envelopes, scanned on a grid of sigma, in exact fractions.
    let envs: [(&str, fn(Q) -> Q, Q); 2] = [("Huxley", huxley, q(3, 4)), ("Guth-Maynard", guth_maynard, q(7, 10))];
    for (name, env, s_star) in envs {
        let mut best = q(500, 1000);
        for k in 500..=1000 { let s = q(k, 1000); if env(s).cmp(env(best)) == Ordering::Greater { best = s; } }
        println!("envelope {}: max over sigma at {} = {} (crossing solved: {})", name, best.s(), env(best).s(), s_star.s());
        assert!(best == s_star);
    }
    assert!(huxley(q(3, 4)) == q(12, 5) && guth_maynard(q(7, 10)) == q(30, 13));
    let ing40 = |s: Q| int(3).div(int(2).sub(s));            // Ingham 1940 against Ingham 1937's flat 8/3
    let cross = (500..=1000).map(|k| q(k, 1000)).filter(|&s| ing40(s).cmp(q(8, 3)) != Ordering::Greater).last().unwrap();
    println!("envelope Ingham 1940: 3/(2 - sigma) is {} at sigma = 1, at most 8/3 up to sigma = {} (solved: {})", ing40(int(1)).s(), cross.s(), int(2).sub(q(9, 8)).s());
    assert!(cross == int(2).sub(q(9, 8)));

    // Road 2: theta = 1 - 1/A for every interval, 1 - 2/A for almost every interval.
    let rows = [("Carlson 1921", int(4)), ("Ingham 1937", q(8, 3)), ("Huxley 1972", q(12, 5)),
                ("Guth-Maynard", q(30, 13)), ("density hyp.", int(2))];
    let quoted = [(q(8, 3), q(5, 8)), (q(12, 5), q(7, 12)), (q(30, 13), q(17, 30))]; // as stated by the papers
    let quoted_aa = [(q(12, 5), q(1, 6)), (q(30, 13), q(2, 15))];
    println!("x = 10^6, log x = {:.4}", (X as f64).ln());
    let r4 = (X as f64).ln().powf(0.25);
    println!("error shape exp(-(log x)^(1/4)) at 10^6 = exp(-{:.3}) = {:.4}", r4, (-r4).exp());
    println!("name          A      theta  almost-all   x^theta      h  primes  h/log x    diff  ratio  psi-gain/h");
    let mut bars = Vec::new();
    for (name, a) in rows {
        let th = int(1).sub(int(1).div(a));
        let aa = int(1).sub(int(2).div(a));
        for (qa, qe) in quoted { if a == qa { assert!(th == qe); } }          // theta against the papers
        for (qa, qaa) in quoted_aa { if a == qa { assert!(aa == qaa); } }
        let h = (X as f64).powf(th.f()).floor() as usize;
        let c = count(X, h);
        let c_td = (X + 1..=X + h).filter(|&n| is_prime_td(n)).count();
        assert_eq!(c, c_td);                                 // sieve against trial division
        let mut gain = 0.0f64;
        for n in X + 1..=X + h { if ok[n] { gain += (n as f64).ln(); } }
        let pred = h as f64 / (X as f64).ln();
        println!("{:13} {:6} {:6} {:10} {:9.2} {:>6}  {:6}  {:7.1}  {:6.1}  {:.3}  {:.4}", name, a.s(), th.s(), aa.s(),
                 (X as f64).powf(th.f()), commas(h as u64), c, pred, c as f64 - pred, c as f64 / pred, gain / h as f64);
        bars.push((name, h));
    }
    for &(name, h) in &bars[1..] {                           // one # per 200 integers
        let n = (h as f64 / 200.0).round() as usize;
        println!("bar {:13} {:29} x^theta = {}", name, "#".repeat(n), commas(h as u64));
    }

    // Evidence across [10^5, 10^6]: every interval (y, y + y^theta] for two exponents.
    for (th, label) in [(q(7, 12), "7/12"), (q(1, 3), "1/3")] {
        let (mut lo, mut hi, mut arg_lo, mut empty) = (9.0f64, 0.0f64, 0usize, 0usize);
        for y in 100_000..=X {
            let h = (y as f64).powf(th.f()).floor() as usize;
            let r = count(y, h) as f64 / (h as f64 / (y as f64).ln());
            if r < lo { lo = r; arg_lo = y; }
            hi = hi.max(r);
            if count(y, h) == 0 { empty += 1; }
        }
        println!("scan theta={}: worst ratio {:.4} at y={}, best {:.4}, empty intervals {}", label, lo,
                 commas(arg_lo as u64), hi, commas(empty as u64));
        if th == q(7, 12) { assert!(empty == 0 && lo > 0.75); } else { assert!(empty > 0); }
    }

    // What breaks 1: the largest prime gap below a million, against theta = 1/3.
    let ps: Vec<usize> = (2..=X).filter(|&n| ok[n]).collect();
    let (mut g, mut p) = (0usize, 0usize);
    for k in 0..ps.len() - 1 { let d = ps[k + 1] - ps[k]; if d > g || (d == g && ps[k] > p) { g = d; p = ps[k]; } }
    let h = (p as f64).powf(1.0 / 3.0).floor() as usize;
    println!("breaks: gap {} after {}; (p, p + {}] holds {} primes, predicted {:.2}", g, commas(p as u64), h,
             count(p, h), h as f64 / (p as f64).ln());
    assert!(g == 114 && p == 492113 && count(p, h) == 0);
    let (mut last, mut prev) = ((0usize, 0usize, 0usize), 2usize); // the last empty (p, p + p^(1/3)] below BIG
    for p in (3..=BIG).filter(|&n| ok[n]) {
        let h = (prev as f64).powf(1.0 / 3.0).floor() as usize;
        if p - prev > h { last = (prev, p - prev, h); }
        prev = p;
    }
    println!("breaks: below 10^8 the last empty (p, p + p^(1/3)] is at p = {}: gap {} against a window of {}", commas(last.0 as u64), last.1, last.2);
    assert!(last.0 == 2010733 && last.1 == 148);             // a record gap in the maximal-gap tables

    // What breaks 2: read the almost-all exponent 1/6 as 'every interval'. Count times size as a power of x,
    // T = x^(1 - theta): one window (T^A/x)^(1-sigma), Step 0, k = 1; averaged over x (T^A/x^2)^(1-sigma), Step 7, k = 2.
    let a = q(12, 5);
    let cs = |th: Q, k: i128| a.mul(int(1).sub(th)).sub(int(k));
    println!("breaks: count x size, A=12/5, as a power of x: one window x^{} at theta=7/12, x^{} at theta=1/6; averaged over x, x^{} at theta=1/6",
             cs(int(1).sub(int(1).div(a)), 1).s(), cs(q(1, 6), 1).s(), cs(q(1, 6), 2).s());
    assert!(cs(q(1, 6), 1).cmp(int(0)) == Ordering::Greater && cs(q(1, 6), 2).cmp(int(0)) != Ordering::Greater);
    let (mut bad, mut model, mut hmin, mut hmax) = (0usize, 0.0f64, usize::MAX, 0usize); // windows shorter than the mean gap
    for y in 100_000..=X {
        let h = (y as f64).powf(1.0 / 6.0).floor() as usize;
        hmin = hmin.min(h); hmax = hmax.max(h);
        if count(y, h) == 0 { bad += 1; }
        model += (1.0 - 1.0 / (y as f64).ln()).powf(h as f64); // each integer prime with chance 1/log y
    }
    println!("breaks: theta=1/6, widths {} to {}, mean gap log y {:.4} to {:.4}; empty {} of 900,001 = {:.4}, random model {:.4}",
             hmin, hmax, (100_000f64).ln(), (X as f64).ln(), commas(bad as u64), bad as f64 / 900001.0, model / 900001.0);
    assert!((bad as f64 - model).abs() < 0.1 * 900001.0);

    // What breaks 3: no density bound. Up to T = x/h every zero may add up to 2h.
    let t = X as f64 / 3162.0;
    let tp = 2.0 * std::f64::consts::PI;
    let nt = t / tp * (t / tp).ln() - t / tp + 7.0 / 8.0;
    println!("breaks: no density bound, T = {:.1}, smooth N(T) = {:.1}, error bound {:.0} times h", t, nt, 2.0 * nt);

    // What breaks 4: classical zero-free region only, width 1/(5.558691 log T).
    let kappa = int(1).sub(q(12, 5).mul(q(3, 8)));          // A = 12/5, theta = 5/8
    let saving = (-kappa.f() / 5.558691 / (3.0 / 8.0)).exp();
    println!("breaks: classical region, A=12/5, theta=5/8, kappa={}, saving factor {:.4} at every x", kappa.s(), saving);
    assert!(kappa == q(1, 10) && 0.9 < saving && saving < 1.0);
    println!("quoted, not computed: classical region width 1/(5.558691 log t); zeros on the line to 3 x 10^12;");
    println!("quoted, not computed: first zero 1/2 + 14.134725i; Ingham uses |zeta(1/2 + it)| << t^(1/6 + eps)");
    println!("quoted, not computed: a prime in every [x - x^0.525, x] (Baker-Harman-Pintz 2001)");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
house: primes below a million = 78498
envelope Huxley: max over sigma at 3/4 = 12/5 (crossing solved: 3/4)
envelope Guth-Maynard: max over sigma at 7/10 = 30/13 (crossing solved: 7/10)
envelope Ingham 1940: 3/(2 - sigma) is 3 at sigma = 1, at most 8/3 up to sigma = 7/8 (solved: 7/8)
x = 10^6, log x = 13.8155
error shape exp(-(log x)^(1/4)) at 10^6 = exp(-1.928) = 0.1454
name          A      theta  almost-all   x^theta      h  primes  h/log x    diff  ratio  psi-gain/h
Carlson 1921  4      3/4    1/2         31622.78 31,622    2315   2288.9    26.1  1.011  1.0125
Ingham 1937   8/3    5/8    1/4          5623.41  5,623     420    407.0    13.0  1.032  1.0321
Huxley 1972   12/5   7/12   1/6          3162.28  3,162     246    228.9    17.1  1.075  1.0750
Guth-Maynard  30/13  17/30  2/15         2511.89  2,511     193    181.8    11.2  1.062  1.0620
density hyp.  2      1/2    0            1000.00  1,000      75     72.4     2.6  1.036  1.0362
bar Ingham 1937   ############################  x^theta = 5,623
bar Huxley 1972   ################              x^theta = 3,162
bar Guth-Maynard  #############                 x^theta = 2,511
bar density hyp.  #####                         x^theta = 1,000
scan theta=7/12: worst ratio 0.7896 at y=180,541, best 1.1802, empty intervals 0
scan theta=1/3: worst ratio 0.0000 at y=100,853, best 2.6667, empty intervals 620
breaks: gap 114 after 492,113; (p, p + 78] holds 0 primes, predicted 5.95
breaks: below 10^8 the last empty (p, p + p^(1/3)] is at p = 2,010,733: gap 148 against a window of 126
breaks: count x size, A=12/5, as a power of x: one window x^0 at theta=7/12, x^1 at theta=1/6; averaged over x, x^0 at theta=1/6
breaks: theta=1/6, widths 6 to 9, mean gap log y 11.5129 to 13.8155; empty 430,516 of 900,001 = 0.4784, random model 0.5168
breaks: no density bound, T = 316.3, smooth N(T) = 147.8, error bound 296 times h
breaks: classical region, A=12/5, theta=5/8, kappa=1/10, saving factor 0.9532 at every x
quoted, not computed: classical region width 1/(5.558691 log t); zeros on the line to 3 x 10^12;
quoted, not computed: first zero 1/2 + 14.134725i; Ingham uses |zeta(1/2 + it)| << t^(1/6 + eps)
quoted, not computed: a prime in every [x - x^0.525, x] (Baker-Harman-Pintz 2001)
ALL CHECKS PASS
```

### Lean

Lean proves Step 0's count times size for every A > 0, x > 1 and σ < 1, and the peaks of two envelopes.

- Take $`A > 0`$, $`x > 1`$, $`\sigma < 1`$ and $`T = x^{1-\theta}`$. Then $`(T^A/x)^{1-\sigma} = x^{-\kappa(1-\sigma)}`$, and it is below 1 exactly when $`\theta > 1 - 1/A`$.
- Take σ from 1/2 to 1. Then Huxley's envelope $`\min(3/(2-\sigma), 3/(3\sigma-1))`$ is at most 12/5, with equality at σ = 3/4.
- Take σ from 1/2 to 1. Then Guth and Maynard's envelope $`\min(3/(2-\sigma), 15/(3+5\sigma))`$ is at most 30/13, with equality at σ = 7/10.
- Lean also checks the first table's exponents: every window and almost every window, for all five values of A.
- It checks the margin κ: 1/10 at A = 12/5 and θ = 5/8, and 0 at the edge θ = 7/12.
- It checks Ingham's 1940 envelope 3/(2 − σ): 8/3 at σ = 7/8, and 3 at σ = 1.
- It checks the window widths at a million: 3,162, 5,623 and 2,511.
- It checks the gap of 114 after the prime 492,113, so the window (p, p + 78] holds no prime.

The other prime counts, the scans and every decimal are left to the Python and Rust checks; the density bounds stay quoted from their sources.

```lean
-- Zero-density estimates: count times size, (T^A/x)^(1 − σ) with T = x^(1 − θ), is below 1 exactly when θ > 1 − 1/A, and the envelopes of Huxley and of Guth and Maynard peak at 12/5 and 30/13.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.IntervalCases

open Real

/-- Count against size (Steps 0 and 4). Take the cut height `T = x^(1 − θ)`, so that a density
exponent `A > 0` allows about `T^(A(1 − σ))` zeros with real part at least `σ`, each of relative size
`x^(σ − 1)`. Their product `(T^A / x)^(1 − σ)` equals `x^(−κ(1 − σ))` with margin
`κ = 1 − A(1 − θ)`, and for `x > 1` and `σ < 1` it is below 1 exactly when `θ > 1 − 1/A`. -/
theorem count_times_size_lt_one_iff {A θ σ x : ℝ} (hA : 0 < A) (hx : 1 < x) (hσ : σ < 1) :
    ((x ^ (1 - θ)) ^ A / x) ^ (1 - σ) = x ^ (-(1 - A * (1 - θ)) * (1 - σ)) ∧
      (((x ^ (1 - θ)) ^ A / x) ^ (1 - σ) < 1 ↔ 1 - 1 / A < θ) := by
  have hx0 : 0 < x := by linarith
  have key : ((x ^ (1 - θ)) ^ A / x) ^ (1 - σ) = x ^ (-(1 - A * (1 - θ)) * (1 - σ)) := by
    rw [← Real.rpow_mul hx0.le]
    conv_lhs => rw [show x ^ ((1 - θ) * A) / x = x ^ ((1 - θ) * A) / x ^ (1:ℝ) by rw [Real.rpow_one]]
    rw [← Real.rpow_sub hx0, ← Real.rpow_mul hx0.le]
    congr 1; ring
  refine ⟨key, ?_⟩
  rw [key]
  have e1 : ∀ e : ℝ, x ^ e < 1 ↔ e < 0 := fun e => by
    simpa using Real.rpow_lt_rpow_left_iff hx (y := e) (z := 0)
  rw [e1]
  have h1σ : 0 < 1 - σ := by linarith
  constructor
  · intro h
    have h2 : 0 < 1 - A * (1 - θ) := by
      by_contra hc
      push Not at hc
      nlinarith
    have : A * (1 - θ) < 1 := by linarith
    have h3 : 1 - θ < 1 / A := by rw [lt_div_iff₀ hA]; linarith
    linarith
  · intro h
    have h3 : 1 - θ < 1 / A := by linarith
    rw [lt_div_iff₀ hA] at h3
    nlinarith

/-- Huxley's density exponent (Step 6): the envelope `A(σ) = min(3/(2 − σ), 3/(3σ − 1))`, Ingham's
1940 bound joined to Huxley's large-values bound, has largest value `12/5` over `1/2 ≤ σ ≤ 1`,
reached at `σ = 3/4`. -/
theorem huxley_envelope_max :
    IsGreatest ((fun σ : ℝ => min (3 / (2 - σ)) (3 / (3 * σ - 1))) '' Set.Icc (1 / 2) 1) (12 / 5) ∧
      min (3 / (2 - (3 / 4 : ℝ))) (3 / (3 * (3 / 4) - 1)) = 12 / 5 := by
  have hv : min (3 / (2 - (3 / 4 : ℝ))) (3 / (3 * (3 / 4) - 1)) = 12 / 5 := by norm_num
  refine ⟨⟨⟨3 / 4, ⟨by norm_num, by norm_num⟩, hv⟩, ?_⟩, hv⟩
  rintro y ⟨σ, ⟨h1, h2⟩, rfl⟩
  rcases le_total σ (3 / 4) with h | h
  · refine (min_le_left _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith
  · refine (min_le_right _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith

/-- Guth and Maynard's density exponent (Step 6): the envelope
`A(σ) = min(3/(2 − σ), 15/(3 + 5σ))` has largest value `30/13` over `1/2 ≤ σ ≤ 1`, reached at
`σ = 7/10`. -/
theorem guth_maynard_envelope_max :
    IsGreatest ((fun σ : ℝ => min (3 / (2 - σ)) (15 / (3 + 5 * σ))) '' Set.Icc (1 / 2) 1) (30 / 13) ∧
      min (3 / (2 - (7 / 10 : ℝ))) (15 / (3 + 5 * (7 / 10))) = 30 / 13 := by
  have hv : min (3 / (2 - (7 / 10 : ℝ))) (15 / (3 + 5 * (7 / 10))) = 30 / 13 := by norm_num
  refine ⟨⟨⟨7 / 10, ⟨by norm_num, by norm_num⟩, hv⟩, ?_⟩, hv⟩
  rintro y ⟨σ, ⟨h1, h2⟩, rfl⟩
  rcases le_total σ (7 / 10) with h | h
  · refine (min_le_left _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith
  · refine (min_le_right _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith

-- Every window, θ = 1 − 1/A: Carlson 4 → 3/4, Ingham 8/3 → 5/8, Huxley 12/5 → 7/12,
-- Guth–Maynard 30/13 → 17/30, the density hypothesis 2 → 1/2.
example : (1 - 1 / 4 : ℚ) = 3 / 4 ∧ (1 - 1 / (8 / 3) : ℚ) = 5 / 8 ∧
    (1 - 1 / (12 / 5) : ℚ) = 7 / 12 ∧ (1 - 1 / (30 / 13) : ℚ) = 17 / 30 ∧
    (1 - 1 / 2 : ℚ) = 1 / 2 := by
  norm_num

-- Almost every window, θ = 1 − 2/A: 1/2, 1/4, 1/6, 2/15 and 0.
example : (1 - 2 / 4 : ℚ) = 1 / 2 ∧ (1 - 2 / (8 / 3) : ℚ) = 1 / 4 ∧
    (1 - 2 / (12 / 5) : ℚ) = 1 / 6 ∧ (1 - 2 / (30 / 13) : ℚ) = 2 / 15 ∧
    (1 - 2 / 2 : ℚ) = 0 := by
  norm_num

-- The margin at A = 12/5, θ = 5/8 is κ = 1/10; at the edge θ = 7/12 it is 0.
example : (1 - 12 / 5 * (1 - 5 / 8) : ℚ) = 1 / 10 ∧ (1 - 12 / 5 * (1 - 7 / 12) : ℚ) = 0 := by
  norm_num

-- Ingham's 1940 envelope 3/(2 − σ) is at most 8/3 up to σ = 7/8, where it equals 8/3, and is 3 at σ = 1.
example : (3 / (2 - 7 / 8) : ℚ) = 8 / 3 ∧ (3 / (2 - 1) : ℚ) = 3 := by
  norm_num

-- Window widths at x = 10^6: ⌊10^(7/12 · 6)⌋ = ⌊√(10^7)⌋ = 3,162, ⌊10^(15/4)⌋ = 5,623 and
-- ⌊10^(17/5)⌋ = 2,511.
example : 3162 ^ 2 ≤ 10 ^ 7 ∧ 10 ^ 7 < 3163 ^ 2 := by
  norm_num

example : 5623 ^ 4 ≤ 10 ^ 15 ∧ 10 ^ 15 < 5624 ^ 4 := by
  norm_num

example : 2511 ^ 5 ≤ 10 ^ 17 ∧ 10 ^ 17 < 2512 ^ 5 := by
  norm_num

-- What breaks: the gap of 114 after the prime 492,113; the next prime is 492,227, so the window
-- (p, p + 78] of width ⌊p^(1/3)⌋ = 78 holds no prime.
example : Nat.Prime 492113 ∧ Nat.Prime 492227 ∧
    (∀ m, 492113 < m → m < 492227 → ¬ Nat.Prime m) ∧
    78 ^ 3 ≤ 492113 ∧ 492113 < 79 ^ 3 := by
  refine ⟨by norm_num, by norm_num, ?_, by norm_num, by norm_num⟩
  intro m h1 h2
  interval_cases m <;> norm_num

#print axioms count_times_size_lt_one_iff
#print axioms huxley_envelope_max
#print axioms guth_maynard_envelope_max
```

**Checked 2026-11-24 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'count_times_size_lt_one_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'huxley_envelope_max' depends on axioms: [propext, Classical.choice, Quot.sound]
'guth_maynard_envelope_max' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: use A = 3, the largest value of Ingham's 1940 envelope 3/(2 − σ), at σ = 1. Window and count? θ = 2/3, a window of 10,000 (the code's float floor prints 9,999) that holds 753 primes against 723.8 predicted.
> - Guess first: move the Huxley window from 10^6 to 10^7. Is the ratio closer to 1? Yes: the window is 12,115 wide and holds 746 primes against 751.6, ratio 0.9925.
> - Guess first: scan every window (y, y + √y] from 10^5 to 10^6, the density hypothesis's shape. Any empty? None; the worst ratio is 0.5469, at y = 250,169.

---

## The usual mistake

> [!warning]
> **Mixing up the two exponents.** 1 − 1/A is for every window; 1 − 2/A is for almost every window. Guth and Maynard's 30/13 gives 17/30 for every window and 2/15 for almost every one. Reading 2/15, or Huxley's 1/6, as a promise for every window claims what is not proved. For one window, count times size at θ = 1/6 is T^A/x = x^1, above 1; only the average over x brings it down to x^0. Whether every window [x, x + x^(1/6)] holds a prime for large x is open as of 2026-11-24, and Cramér's model predicts that it does. A count at a million cannot settle it: there the windows (y, y + y^(1/6)] are 6 to 9 wide, under the mean gap log y of 11.5 to 13.8, so 430,516 of 900,001 are empty, a share of 0.4784; a model with each integer prime with chance 1/log y gives 0.5168.
>
> Smaller traps:
> - **Reading a density bound as "no zeros off the line".** It says stragglers are few, not that there are none. For σ just above 1/2 it still allows about $`T^{A/2}`$ of them.
> - **Confusing a share with a prime.** Every window [x − x^0.525, x] holds a prime for large x (Baker, Harman and Pintz, 2001; see [Large gaps](../04-Sieves%20and%20Prime%20Gaps/06-large-gaps-and-the-cramer-model.md)). That beats 17/30, but the sieve gives only a lower bound of the right order, not the asymptotic count x^θ / log x.
> - **Taking the million-scale check as proof.** The worst ratio over windows of width y^(7/12) is 0.7896, at y = 180,541. That is evidence. The theorem has no explicit starting point.

---

## Where you meet it in real life

- **Bounds on prime gaps.** Huxley's theorem shows the gap after a prime p is at most $`p^{7/12 + \varepsilon}`$ for large p. The gap of 114 after 492,113 is far below $`492113^{7/12}`$.
- **Searching for a prime near a target.** Key generation in cryptography steps upward from a random start until it hits a prime. In practice that takes about log x steps. A guarantee on the worst search length is a short-window theorem.
- **Primes in progressions.** The same large-values machinery works for many Dirichlet L-functions at once, where the generalized Riemann hypothesis is still open. Bombieri's 1965 proof of [Bombieri-Vinogradov](../04-Sieves%20and%20Prime%20Gaps/04-bombieri-vinogradov.md) ran through such a density theorem.
- **Machine verification.** Every zero below height 3 × 10^12 is on the line (Platt and Trudgian, 2021; [Zeros on the line](10-zeros-on-the-critical-line-and-proportion-results.md)). So N(σ, T) = 0 for σ > 1/2 below that height, and explicit prime results use this in place of a density bound there.

> **Say it back**
> Each zero of zeta adds a wave to the prime count, and across a window of width h a zero with real part β moves it by at most h x^(β − 1). A zero-density estimate caps the zeros at real part σ or more by T^(A(1 − σ)). Count times size is (T^A/x)^(1 − σ), small exactly when the window is wider than x^(1 − 1/A). Huxley's A = 12/5 gives windows of width x^θ for every θ above 7/12, and at a million the edge window of 3,162 holds 246 primes against 228.9 predicted. Guth and Maynard's 30/13 lowers this to 17/30, and the density hypothesis, now a consequence of the certified proof of the Riemann hypothesis, gives 1/2.

---

## What this builds on

- [The explicit formula](07-the-explicit-formula.md): the prime count as the width minus one wave per zero, with the cut error used in Step 1.
- [Counting the zeros](08-counting-the-zeros-riemann-von-mangoldt.md): about T log T zeros below T, the count used for the zeros near the line in Step 3.
- [The Riemann hypothesis](09-riemann-hypothesis-statement-and-equivalents.md): the statement that N(σ, T) = 0 for every σ > 1/2, the strongest possible density bound.
- [Zeros on the line](10-zeros-on-the-critical-line-and-proportion-results.md): the computed range where N(σ, T) = 0, and what is proved about zeros on the line.
- [Jensen's formula](../../07-Complex%20analysis/10-Entire%20and%20Meromorphic%20Functions/02-jensens-formula-and-order-of-growth.md): slow growth means few zeros, the idea behind Ingham's count in Step 6.
- [The zero-free region](03-the-zero-free-region.md): the classical strip next to real part 1, and why Step 5 needs a wider one.

## Where this goes next

- [Bounded gaps](../04-Sieves%20and%20Prime%20Gaps/05-bounded-gaps-zhang-maynard.md): from windows of width x^θ to pairs of primes a bounded distance apart, by sieves, not zeros.
- [Large gaps](../04-Sieves%20and%20Prime%20Gaps/06-large-gaps-and-the-cramer-model.md): the longest prime-free runs, and the x^0.525 bound that sieve methods reach.
- [Bombieri-Vinogradov](../04-Sieves%20and%20Prime%20Gaps/04-bombieri-vinogradov.md): density ideas for many L-functions at once, giving primes in progressions on average.
- [The Riemann hypothesis](../../25-Frontier/02-The%20Millennium%20Problems/01-riemann-hypothesis.md): the frontier card, whose table lists the 30/13 bound among the results proved without the hypothesis.

The question this card leaves open: can the density hypothesis A = 2 be proved by a method a person can read, and can the same method reach the families of L-functions where the generalized hypothesis is still open?

---

## Sources

Verified 2026-11-24: every link below resolves to the publisher's page.

- Ingham, A. E. "On the Difference Between Consecutive Primes." *The Quarterly Journal of Mathematics* os-8, no. 1 (1937): 255–266. [doi:10.1093/qmath/os-8.1.255](https://doi.org/10.1093/qmath/os-8.1.255). The density bound N(σ, T) ≪ T^(2(1+2c)(1−σ)), times a power of log T, from a bound on zeta on the critical line, and windows of width x^(5/8+ε). With Ingham, A. E. "On the Estimation of N(σ, T)." *The Quarterly Journal of Mathematics* os-11, no. 1 (1940): 201–202. [doi:10.1093/qmath/os-11.1.201](https://doi.org/10.1093/qmath/os-11.1.201). The envelope 3/(2 − σ) of Step 6.
- Huxley, M. N. "On the Difference Between Consecutive Primes." *Inventiones Mathematicae* 15, no. 2 (1971/72): 164–170 (issue dated June 1971; usually cited as 1972, as here). [doi:10.1007/BF01418933](https://doi.org/10.1007/BF01418933). The exponent 12/5, windows of width x^(7/12) and almost-all windows of width x^(1/6).
- Guth, Larry, and James Maynard. "New Large Value Estimates for Dirichlet Polynomials." *Annals of Mathematics* 203, no. 2 (2026): 623–675. [doi:10.4007/annals.2026.203.2.6](https://doi.org/10.4007/annals.2026.203.2.6). The exponent 30/13, the envelopes compared in Step 6, the citation for Carlson (1921) in the first table row, and Section 13, which runs Steps 1 to 5 and Step 7.
- Montgomery, Hugh L. *Topics in Multiplicative Number Theory*. Lecture Notes in Mathematics 227. Springer, 1971. [doi:10.1007/BFb0060851](https://doi.org/10.1007/BFb0060851). Mean and large values of Dirichlet polynomials, the Vinogradov–Korobov zero-free region used in Step 5, and density bounds near σ = 1.
- Davenport, Harold. *Multiplicative Number Theory*, 2nd ed. Graduate Texts in Mathematics 74. Springer, 1980. [doi:10.1007/978-1-4757-5927-3](https://doi.org/10.1007/978-1-4757-5927-3). Chapter 17, the cut explicit formula used in Step 1.
