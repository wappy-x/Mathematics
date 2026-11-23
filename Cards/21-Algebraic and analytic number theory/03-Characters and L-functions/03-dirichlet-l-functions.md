# Dirichlet L-functions: one series per character, each with its own Euler product

[Syllabus](../../../SYLLABUS.md) → [Algebraic and analytic number theory](../README.md) → [Characters and L-functions](../README.md#s03) → Dirichlet L-functions

---

## General Overview

There are 78,498 primes below a million. Apart from 2, each one is odd, so it leaves remainder 1 or 3 when divided by 4. A sieve counts 39,175 primes that leave 1 and 39,322 that leave 3. That is close to half each. Split by last digit instead, and 1, 3, 7 and 9 take 19,617, 19,665, 19,621 and 19,593: close to a quarter each.

A count to a million is evidence, not proof. In 1837 Peter Gustav Lejeune Dirichlet proved that each such class holds infinitely many primes. His tool was a weighted copy of the zeta series. Give each whole number n a weight: +1 if n leaves remainder 1 on division by 4, −1 if it leaves 3, and 0 if n is even. Divide each weight by n and add:

1 − 1/3 + 1/5 − 1/7 + 1/9 − … = π/4 = 0.785398.

That sum is the **L-function** of the weight pattern, taken at the power 1. The weight pattern is a **Dirichlet character**: a pattern that repeats and multiplies the way the numbers do. Each character gets its own L-function. Each L-function is also a product over the primes, which is how it sees the primes in one class against the primes in another.

The zeta function already pushes the sum of 1/p over all primes to infinity. The L-function's value at 1, here π/4, decides how that infinity is shared between the classes. If the value were 0, one class could miss out. So everything rests on one fact: the value at 1 is never 0.

**A Dirichlet L-function adds a character's weights against the powers of the whole numbers; it equals a product over the primes because the weights multiply, and its value at 1 is not zero, which for the odd character mod 4 is the series 1 − 1/3 + 1/5 − … = π/4.**

**What kind of fact this is:** theorems. The Euler product and the value π/4 are proved on this card in Why it works. That the value at 1 is never zero is proved here for every character other than the principal one, in two folds of Step 5: one for complex characters, one for real ones. The prime counts are evidence to a million.

### The picture: the series zigzags round π/4

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Partial sums of 1 - 1/3 + 1/5 - 1/7 + ..."
    x-axis "terms kept (count)" ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    y-axis "partial sum (unitless)" 0.6 --> 1.0
    line [1.0000, 0.6667, 0.8667, 0.7238, 0.8349, 0.7440, 0.8209, 0.7543, 0.8131, 0.7605, 0.8081, 0.7646]
    line [0.7854, 0.7854, 0.7854, 0.7854, 0.7854, 0.7854, 0.7854, 0.7854, 0.7854, 0.7854, 0.7854, 0.7854]
```

Orange: the partial sums, which land above and below in turn. Green: π/4 = 0.7854. The gap shrinks like one over the number of terms, which Step 3 proves.

---

## The formula

Notation first, in words. A **Dirichlet character** χ ("chi") mod q is a weight on the whole numbers that repeats every q steps, is 0 on numbers sharing a factor with q, and is **completely multiplicative**: χ(mn) = χ(m)χ(n) for all m and n ([Dirichlet characters](01-dirichlet-characters.md)). The **modulus** q is the length of the repeat. The **principal character** χ₀, called the trivial character on [Dirichlet characters](01-dirichlet-characters.md), is 1 on every number coprime to q. Our example is χ₄, the character mod 4 with weights 1, 0, −1, 0, repeating. It is **odd**: χ₄(−1) = −1.

As on the wing's zeta cards, s = σ + it is a complex power with real part σ, $`n^{-s}`$ means $`e^{-s\log n}`$, and log is the natural logarithm. The letter p is always a prime.

```math
L(s,\chi) = \sum_{n=1}^{\infty} \frac{\chi(n)}{n^{s}} = \prod_{p} \frac{1}{1 - \chi(p)\,p^{-s}} \qquad (\sigma > 1)
```

**Read it aloud:** L of s and chi is the sum of chi of n over n to the s, and it equals the product, over every prime p, of one over one minus chi of p over p to the s.

```math
L(1,\chi_4) = 1 - \frac{1}{3} + \frac{1}{5} - \frac{1}{7} + \cdots = \frac{\pi}{4}, \qquad L(1,\chi) \ne 0 \ \text{ for every character } \chi \ne \chi_0
```

**Read it aloud:** L at 1 for the character mod 4 is one minus a third plus a fifth and so on, which is pi over four; and L at 1 is not zero for any character other than the principal one.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`s`$, $`\sigma`$, $`i`$ | complex power; its real part; the square root of −1 | s = 1, 2 and 3 | larger σ: the terms shrink faster |
| $`n`$, $`d`$, $`m`$, $`k`$ | whole numbers; $`d`$ divides $`n`$; $`k`$ an exponent or term number | n up to 1,000,000 | — |
| $`N`$ | terms kept, or a cut-off | N = 10: error 0.024938259 | error shrinks like 1/(4N) |
| $`p`$ | a prime, always | 3, 5, 7, … | its factor nears 1 |
| $`q`$ | the modulus: the length of the repeat | 4, and 10 for last digits | more characters, φ(q) of them |
| $`\chi`$, $`\chi_0`$, $`\bar\chi`$ | a character; the principal character; the conjugate character, χ with each value replaced by its complex conjugate | χ₀ mod 4 is 1 on odd n; χ̄₄ = χ₄ | — |
| $`\chi_4`$ | the odd character mod 4 | weights 1, 0, −1, 0, … | — |
| $`L(s,\chi)`$ | the character's L-function | L(1, χ₄) = 0.785398, L(2, χ₄) = 0.915965594 | rises towards 1 as s grows |
| $`\zeta(s)`$ | zeta: the L-function of the all-ones weight | pole at s = 1 | — |
| $`r(n)`$ | the sum of $`\chi_4(d)`$ over the divisors $`d`$ of $`n`$ | r(5) = 2, r(3) = 0 | — |
| $`A(x)`$, $`x`$ | the sum of $`r(n)/\sqrt n`$ for n up to x; the cut-off | A(10⁶) = 1569.810344 | grows like √x |
| $`a`$, $`b`$, $`u`$, $`C`$, $`c`$, $`y`$ | helpers: a point's coordinates; the log series' variable; C bounds a character's running total; the second fold's constant c and split point y | 36 points (a, b) for N = 10 | — |

### When it holds

- **σ > 1, for the Euler product.** The factors' sizes add up only there. At s = 1 the principal character's series is 1 + 1/3 + 1/5 + …, which reaches 4.089059 by 1,000 and 7.542937 by a million, and keeps climbing.
- **Complete multiplicativity, for the product.** The weight $`(-1)^{n+1}`$, which runs 1, −1, 1, −1, …, also repeats. But the weight at 2 times itself is +1, while the weight at 4 is −1. Its product at s = 2 gives 0.986960, while its series gives π²/12 = 0.822467.
- **A non-principal character, for a value at s = 1.** The weights over one full repeat add to 0, so the partial sums of χ stay bounded and the series converges for σ > 0. The principal character never cancels, and its series has a pole at 1.
- **The natural order, at s = 1.** The series at 1 converges only because plus and minus terms cancel. Take two plus terms for every minus term and the sum becomes 0.958685, not 0.785398.

---

## Why it works

### Step 0: the idea

Zeta weights every whole number by 1, and its Euler product works because every number factors into primes in one way. A character keeps the product working, because its weights multiply exactly as the numbers do. The new information sits in the signs: χ₄(p) is +1 on the primes that leave 1 and −1 on those that leave 3. So the log of L(s, χ₄) is, up to small terms, the sum of $`1/p^s`$ over the first class minus the sum over the second. Zeta gives the same two sums added.

Adding and subtracting separates the two classes. That works only if the log of L stays finite at s = 1, which means L(1, χ₄) ≠ 0.

### Step 1: the series converges

For σ > 1 the sizes $`|\chi(n)/n^s|`$ are at most $`n^{-\sigma}`$, which add up, so the series converges absolutely.

For a non-principal character the weights over one full repeat add to 0 ([Dirichlet characters](01-dirichlet-characters.md)). For χ₄ the running total 1, 1, 0, 0, 1, 1, 0, 0, … never leaves 0 or 1. [Partial summation](../01-Arithmetic%20Functions%20Again/06-abel-and-partial-summation.md) turns a bounded running total against the falling sizes $`n^{-\sigma}`$ into a convergent series for every σ > 0. That is why L(1, χ) has a value at all.

For real s it gives more. If the running total stays within C, the terms after the N-th add to at most $`2C/N^{s}`$ in size, and that bound only shrinks as s grows. So above any fixed positive s the series converges at one rate for all s at once (uniformly), and L(s, χ) is continuous for real s > 0, at s = 1 included.

### Step 2: the Euler product

[The zeta function](../../07-Complex%20analysis/09-Special%20Functions%20and%20the%20Zeta%20Function/05-zeta-function-and-euler-product.md) proves the product over primes from unique factorisation. The same proof works with any completely multiplicative weight. Expand each factor as a geometric series, $`1/(1 - \chi(p)p^{-s}) = 1 + \chi(p)p^{-s} + \chi(p)^2p^{-2s} + \cdots`$. A term of the expanded product picks one power of each prime, and multiplicativity turns $`\chi(p_1)^{a_1}\chi(p_2)^{a_2}\cdots`$ into χ(n) for $`n = p_1^{a_1}p_2^{a_2}\cdots`$.

For χ₄ the factor at 2 is 1, so the product splits by class:

```math
L(s,\chi_4) = \prod_{p \equiv 1 \bmod 4} \frac{1}{1 - p^{-s}} \prod_{p \equiv 3 \bmod 4} \frac{1}{1 + p^{-s}} \qquad (\sigma > 1)
```

At s = 2 the running product over 3, then 3 and 5, then 3, 5 and 7 gives 0.900000, 0.937500 and 0.918750. All primes below a million give 0.915965594, the same nine decimals as the series. This number is Catalan's constant, the usual name for L(2, χ₄). As on the zeta card, no factor is 0 and the product converges absolutely, so L(s, χ) ≠ 0 for σ > 1.

The principal character mod 4 just removes the factor at 2: $`L(s,\chi_0) = (1 - 2^{-s})\zeta(s)`$. It keeps zeta's pole at 1.

### Step 3: the value at 1 is π/4

Add the geometric series for $`1/(1 + x^2)`$ up to N terms. What is left over is exact:

```math
\frac{1}{1+x^2} = \sum_{k=0}^{N-1} (-1)^k x^{2k} + (-1)^N \frac{x^{2N}}{1+x^2}
```

Integrate from 0 to 1. The left side gives arctan 1 = π/4. Each term on the right gives $`(-1)^k/(2k+1)`$, the series' k-th term. The leftover integrand lies between $`x^{2N}/2`$ and $`x^{2N}`$, because 1 + x² lies between 1 and 2. So after N terms the error lies strictly between 1/(2(2N + 1)) and 1/(2N + 1). It tends to 0, which proves the series equals π/4.

| Terms N | Partial sum | Error | Proved bracket |
| --- | --- | --- | --- |
| 10 | 0.760459905 | 0.024938259 | 0.023809524 to 0.047619048 |
| 100 | 0.782898226 | 0.002499938 | 0.002487562 to 0.004975124 |
| 1,000 | 0.785148163 | 0.000250000 | 0.000249875 to 0.000499750 |
| 1,000,000 | 0.785397913 | 0.00000025000000 | 0.00000024999988 to 0.00000049999975 |

The code finds π independently, by Machin's formula π = 16 arctan(1/5) − 4 arctan(1/239), as 3.14159265359.

### Step 4: logs separate the two classes

Take logs of the product in Step 2. With $`-\log(1 - u) = u + u^2/2 + u^3/3 + \cdots`$:

```math
\log L(s,\chi) = \sum_{p} \frac{\chi(p)}{p^{s}} + \sum_{p}\sum_{k \ge 2} \frac{\chi(p)^k}{k\,p^{ks}}
```

The double sum is at most the sum of $`1/(p(p-1))`$, below 1, for every s ≥ 1. So it is a small, bounded correction. Apply this to the principal character and to χ₄, then add and subtract. For real s > 1, with the bounded corrections written as "+ bounded":

```math
\sum_{p \equiv 1 \bmod 4} \frac{1}{p^{s}} = \tfrac12\big[\log L(s,\chi_0) + \log L(s,\chi_4)\big] + \text{bounded}, \qquad \sum_{p \equiv 3 \bmod 4} \frac{1}{p^{s}} = \tfrac12\big[\log L(s,\chi_0) - \log L(s,\chi_4)\big] + \text{bounded}
```

As s falls to 1, log L(s, χ₀) goes to infinity with zeta's pole. And log L(s, χ₄) tends to log(π/4) = −0.241564, a finite number, because L(s, χ₄) is continuous at 1 (Step 1). [Dirichlet's theorem](04-dirichlets-theorem-on-primes-in-progressions.md) turns this into infinitely many primes in each class, for every modulus.

If L(1, χ₄) were 0, log L(s, χ₄) would fall to minus infinity. In the first sum it could cancel the pole, and the primes that leave 1 could be finite in number. That is the sense in which non-vanishing at 1 is the whole difficulty.

The primes see the value at 1 directly. Below a million, the sum of χ₄(p)/p (1/p over the primes that leave 1, minus the same over those that leave 3) is −0.3350. Theory predicts its limit as log(π/4) minus the prime-power correction above: −0.334981. That the sum converges to this limit is a theorem (Montgomery and Vaughan, in Sources); the sum to a million is evidence for it.

The same works for any modulus. Characters mod q can be combined to pick out one remainder class ([Dirichlet characters](01-dirichlet-characters.md)), and the argument goes through if L(1, χ) ≠ 0 for every non-principal χ mod q. For last digits, q = 10, there are three such characters. The code finds L(1, χ) = 0.966883 + 0.228250i, 0.645613, and 0.966883 − 0.228250i: sizes 0.993459, 0.645613 and 0.993459, none near 0. The middle one is real and matches a closed form, 3 log((1 + √5)/2)/√5 = 0.645613. Its character is the real character mod 5 with the prime 2 removed. That mod-5 character is −1 at 2, so its Euler factor there is 1/(1 + 1/2) = 2/3, and dropping that factor multiplies the L-value by 3/2. The mod-5 value is 2 log((1 + √5)/2)/√5 = 0.430409, the code finds the ratio 1.500000, and 0.430409 is the value [The class number formula](../06-Algebraic%20Numbers/06-class-number-formula-and-the-dedekind-zeta-function.md) gives.

### Step 5: why L(1, χ) is never zero

The product over primes proves L(s, χ) ≠ 0 only for σ > 1. At s = 1 the product no longer converges absolutely, and that argument stops. A new idea is needed.

**Complex characters.** If χ takes a non-real value, then its conjugate χ̄ is a different character with L(1, χ̄) equal to the conjugate of L(1, χ). A zero at 1 for one is a zero for both. The product of all the L-functions mod q has non-negative coefficients, so it is at least 1 for real s > 1, yet two zeros would overpower zeta's one pole and drive it to 0. The fold below gives the full proof.

<details>
<summary>Detailed proof: L(1, χ) is not zero for a complex character</summary>

Let χ mod q take a non-real value, and suppose L(1, χ) = 0. Take s real with 1 < s ≤ 2. Every non-principal character mod q has its running total within C = φ(q), since a full repeat adds to 0.

**The product of all φ(q) L-functions is at least 1.** For each character the double sum $`\sum_p \sum_{k \ge 1} \chi(p)^k/(k\,p^{ks})`$ converges absolutely, and e to that power is the Euler product, because $`e^{u + u^2/2 + u^3/3 + \cdots} = 1/(1-u)`$. Add these sums over the characters. By [Dirichlet characters](01-dirichlet-characters.md), $`\sum_\chi \chi(p^k)`$ is φ(q) when $`p^k \equiv 1 \pmod q`$ and 0 otherwise. So

$`\displaystyle \prod_{\chi \bmod q} L(s,\chi) = e^{\,\varphi(q) \sum_{p^k \equiv 1 \bmod q} 1/(k\,p^{ks})} \ge 1.`$

**Sizes near 1.** The principal L-function adds $`1/n^{s}`$ over only some n, so it is at most ζ(s), and comparing ζ(s) with an integral gives ζ(s) ≤ 1 + 1/(s − 1) = s/(s − 1). For a non-principal character, partial summation bounds the sum of χ(n) times weights that tend to 0 by C times the total amount the weights rise and fall. The weights $`n^{-s}`$ fall from 1 to 0, so |L(s, χ)| ≤ C. The weights $`1/n - 1/n^{s}`$ start at 0, rise while $`n^{s-1} < s`$, and then fall back towards 0; each is at most $`(s-1)(\log n)/n \le (s-1)/2`$. They rise and fall by at most s − 1 in total, so $`|L(1,\chi) - L(s,\chi)| \le C(s-1)`$.

**The clash.** L(1, χ̄) is the complex conjugate of L(1, χ), so it is 0 too, and χ̄ ≠ χ because χ is not real. So these two factors are at most C(s − 1) in size, the principal one is at most s/(s − 1), and the other φ(q) − 3 are at most C:

$`\displaystyle 1 \le \prod_{\chi \bmod q} |L(s,\chi)| \le \frac{s}{s-1}\,\big(C(s-1)\big)^2\,C^{\varphi(q)-3} = s\,C^{\varphi(q)-1}\,(s-1).`$

The right side tends to 0 as s comes down to 1, a contradiction. So L(1, χ) ≠ 0. For a real character only one factor vanishes, the bound stays at $`s\,C^{\varphi(q)-1}`$, and nothing clashes: that case needs the next fold.

</details>

**Real characters.** Here χ̄ = χ, and that trick finds only one zero against one pole. The proof uses r(n), the sum of χ(d) over the divisors d of n. It is multiplicative, and at a prime power $`p^k`$ it is $`1 + \chi(p) + \cdots + \chi(p)^k`$. That is k + 1 when χ(p) = 1, 1 when χ(p) = 0, and 1 or 0 when χ(p) = −1, for even or odd k. So r(n) is never negative, and it is at least 1 when n is a square. Below a million the code finds the smallest r(n) is 0 and the smallest at a square is 1.

For χ₄, r(n) has a picture. By Jacobi's two-squares theorem (1829), stated here and proved on [Two squares](../07-Diophantine%20and%20Modular/02-sums-of-squares-and-gaussian-integers.md), 4r(n) counts the integer points (a, b) with a² + b² = n. So adding r(n) up to N counts the integer points inside a circle of area πN, divided by 4. Swapping the order of summation, the same total is the sum of χ₄(d)⌊N/d⌋, where ⌊ ⌋ means "round down". At N = 1,000,000 there are 3,141,548 points, and the divisor sum is 785,387, a quarter of that exactly. Divided by N it gives 0.785387, close to π/4. A count of points in a circle is a second road to L(1, χ₄).

Now the proof. Let A(x) be the sum of r(n)/√n for n up to x.

1. **A floor.** Keep only the squares n = m², where r(n) ≥ 1. That leaves 1 + 1/2 + … + 1/√x, at least (log x)/2.
2. **A ceiling.** Write r(n) as its divisor sum and swap the order. The total becomes $`2\sqrt{x}\,L(1,\chi)`$ plus a bounded error, because the character's running total is bounded.
3. **The clash.** If L(1, χ) = 0, A(x) stays bounded. But the floor grows without limit. So L(1, χ) ≠ 0.

| x | A(x) | 2√x · π/4 | difference | floor (log x)/2 |
| --- | --- | --- | --- | --- |
| 100 | 14.801469 | 15.707963 | −0.906494 | 2.302585 |
| 10,000 | 156.107211 | 157.079633 | −0.972422 | 4.605170 |
| 1,000,000 | 1569.810344 | 1570.796327 | −0.985982 | 6.907755 |

The difference stays near −1 while A(x) grows a hundredfold, as the ceiling says.

<details>
<summary>Detailed proof: L(1, χ) is not zero for a real non-principal character</summary>

Let χ be real and non-principal mod q, and let C bound its running total: $`|\sum_{a < n \le b}\chi(n)| \le C`$ for all a < b. Partial summation then gives $`|\sum_{n > y}\chi(n)/n| \le 2C/y`$ and $`|\sum_{a < n \le b}\chi(n)/\sqrt n| \le 2C/\sqrt a`$. Comparing with an integral, $`\sum_{m \le z} 1/\sqrt m = 2\sqrt z + c + O(1/\sqrt z)`$ for a constant c.

**Floor.** $`A(x) \ge \sum_{m \le \sqrt x} 1/m \ge \log\sqrt x = \tfrac12 \log x`$.

**Ceiling.** Put $`y = \sqrt x`$. Every pair d·m ≤ x has d ≤ y or m ≤ y, so

$`\displaystyle A(x) = \sum_{d \le y} \frac{\chi(d)}{\sqrt d}\sum_{m \le x/d} \frac{1}{\sqrt m} + \sum_{m \le y} \frac{1}{\sqrt m}\sum_{y < d \le x/m} \frac{\chi(d)}{\sqrt d}.`$

In the first part, the inner sum is $`2\sqrt{x/d} + c + O(\sqrt{d/x})`$. That gives $`2\sqrt x\sum_{d \le y}\chi(d)/d`$, plus c times a bounded sum, plus at most a constant times $`y/\sqrt x = 1`$. The tail bound turns the first piece into $`2\sqrt x\,L(1,\chi)`$ with an error at most $`4C\sqrt x / y = 4C`$. In the second part the inner sum is at most $`2C/\sqrt y`$, and the outer weights add to at most $`2\sqrt y`$, so it is at most 4C. Hence $`A(x) = 2\sqrt x\,L(1,\chi) + O(1)`$.

**Clash.** If L(1, χ) = 0 then A(x) is bounded, against the floor $`\tfrac12\log x`$. So L(1, χ) ≠ 0. For χ₄ itself Step 3 already gives π/4 > 0. The argument matters for the real characters whose value has no easy formula.

</details>

---

## Worked numbers, by hand

The character mod 4 at N = 10, then the series and the product.

| Step | Arithmetic | Value |
| --- | --- | --- |
| Weights χ₄(1) to χ₄(10) | repeat 1, 0, −1, 0 | 1, 0, −1, 0, 1, 0, −1, 0, 1, 0 |
| Divisor sum to 10 | χ₄(d)⌊10/d⌋ for d = 1, 3, 5, 7, 9: 10 − 3 + 2 − 1 + 1 | 9 |
| Points with 0 < a² + b² ≤ 10 | 4 + 4 + 4 + 8 + 4 + 4 + 8, for n = 1, 2, 4, 5, 8, 9, 10 | 36 = 4 × 9 |
| Share of the circle | 9/10 | 0.900000 |
| Running Euler product at s = 2 | (9/10)(25/24)(49/50), for 3, 5, 7 | 0.900000, 0.937500, 0.918750 |
| Ten terms at s = 1 | 1 − 1/3 + … − 1/19 | 0.760459905 |
| Error after ten terms | inside 1/42 to 1/21 | 0.024938259 |
| **L(1, χ₄)** | π/4, π by Machin | **0.785398163397** |

So weighting the primes by their class mod 4 gives a function whose value at 1 is π/4, about 0.785: finite and well away from 0. That keeps the log in Step 4 finite, so both classes share zeta's infinity.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Use the principal character at s = 1 | 4.089059 by 1,000, 7.542937 by a million, still climbing | no cancellation: this is zeta's pole, not a value |
| Build an Euler product from the repeating but non-multiplicative weight $`(-1)^{n+1}`$, at s = 2 | 0.986960, against the true 0.822467 | the product needs χ(mn) = χ(m)χ(n) |
| Rearrange the series at s = 1: two plus terms per minus term | 0.958685 = π/4 + (log 2)/4 | the series converges only conditionally at 1, so order matters |

---

## Code, from first principles, and it actually runs

The script takes three roads to L(1, χ₄) = π/4: the series with Step 3's proved error bracket, π from Machin's arctangent formula, and integer points in a circle against the divisor sum. It checks the Euler product at s = 2 against the series, sieves the primes below a million, and prints the sum of χ₄(p)/p beside its predicted limit. It also checks Step 5's floor and ceiling at three sizes, and finds the three L-values mod 10, the real one against a closed form and against the value mod 5. Series at s ≥ 1 are averaged over one full repeat of the partial sums, which cancels the leading error. Rust repeats every step in the same order and prints identical lines.

### Python

```python
# Dirichlet L-functions: the check behind the card.  Standard library only.
# Roads to L(1, chi_4) = pi/4: the series with its proved error bracket, pi from
# Machin's arctangent formula, and lattice points in a circle.  Primes: a sieve.
import math

def chi4(n): return 0 if n % 2 == 0 else (1 if n % 4 == 1 else -1)
def f(x, k=6): return f"{x:.{k}f}"

def atan_series(x):  # arctan x = x - x^3/3 + x^5/5 - ..., 40 terms, |x| <= 1/5
    total, power = 0.0, x
    for k in range(40):
        total += (1.0 if k % 2 == 0 else -1.0) * power / (2 * k + 1)
        power *= x * x
    return total

def avg_tail(chi, q, s, M):  # sum chi(n)/n^s, averaged over the partial sums
    total, acc = 0.0, 0.0    # at N = M .. M+q-1: the 1/M error term cancels
    for n in range(1, M + q):
        total += chi(n) / float(n ** s)
        if n >= M: acc += total
    return acc / q

PI = 16 * atan_series(1 / 5) - 4 * atan_series(1 / 239)
Q = PI / 4
print("pi by Machin", f(PI, 11), "| pi/4", f(Q, 12))

# ---- the series L(1, chi_4) = 1 - 1/3 + 1/5 - ..., error bracket from Step 3 ----
s, part = 0.0, []
for k in range(12):
    s += (1.0 if k % 2 == 0 else -1.0) / (2 * k + 1); part.append(s)
print("chart, partial sums, 1 to 12 terms:", ", ".join(f(x, 4) for x in part))
print("terms N, partial sum, error, bracket 1/(2(2N+1)) to 1/(2N+1)")
s, k = 0.0, 0
for N in [10, 100, 1000, 10 ** 6]:
    while k < N:
        s += (1.0 if k % 2 == 0 else -1.0) / (2 * k + 1); k += 1
    err = abs(s - Q)
    assert 1 / (2 * (2 * N + 1)) < err < 1 / (2 * N + 1)   # Step 3's bracket
    dp = 14 if N == 10 ** 6 else 9               # at 10^6, nine decimals would hide the gap to the low end
    print(N, f(s, 9), f(err, dp), f(1 / (2 * (2 * N + 1)), dp), f(1 / (2 * N + 1), dp))

# ---- primes below a million, and the Euler product at s = 2 ----
X = 10 ** 6
sv = bytearray([1]) * X; sv[0] = sv[1] = 0
for i in range(2, 1001):
    if sv[i]: sv[i * i::i] = bytearray(len(range(i * i, X, i)))
primes = [p for p in range(X) if sv[p]]
G = avg_tail(chi4, 4, 2, X)                      # Catalan's constant, by the series
E = 1.0
for p in primes: E /= 1 - chi4(p) / (p * p)
E3 = []
for p in (3, 5, 7): E3.append((E3[-1] if E3 else 1.0) / (1 - chi4(p) / (p * p)))
print("Euler product at s=2, primes 3; 3, 5; 3, 5, 7:", ", ".join(f(v) for v in E3))
print("L(2,chi4) series", f(G, 9), "| Euler product, primes below 10^6", f(E, 9), "| gap", f(abs(G - E), 9))
assert abs(G - E) < 1e-6                         # Step 2: gap below 1/1,000,000
alt = lambda n: 1 if n % 2 == 1 else -1          # periodic, but not multiplicative
Ealt = 1.0
for p in primes: Ealt /= 1 - alt(p) / (p * p)
Salt = avg_tail(alt, 2, 2, X)
assert abs(Salt - PI * PI / 12) < 1e-9 and abs(Ealt - Salt) > 0.1
print("weight (-1)^(n+1) at s=2: series", f(Salt), "= pi^2/12", f(PI * PI / 12), "| fake product", f(Ealt))
h = []
for N in (10 ** 3, 10 ** 6):
    t = 0.0
    for n in range(1, N + 1, 2): t += 1 / n
    h.append(t)
print("principal chi0 mod 4 at s=1: odd n to 10^3", f(h[0]), "| to 10^6", f(h[1]))
r3, i, j = 0.0, 0, 0                             # rearranged: two plus terms, one minus
for b in range(300000):
    r3 += 1 / (4 * i + 1) + 1 / (4 * i + 5) - 1 / (4 * j + 3); i += 2; j += 1
print("rearranged 1 + 1/5 - 1/3 + ...:", f(r3), "| pi/4 + (log 2)/4", f(Q + math.log(2) / 4))
assert abs(r3 - (Q + math.log(2) / 4)) < 1e-5

# ---- lattice points: sum of r(n) = sum chi4(d) floor(N/d) = (points in circle)/4 ----
def lattice(N):  # points (a, b) with 0 < a^2 + b^2 <= N
    R = math.isqrt(N)
    return sum(2 * math.isqrt(N - a * a) + 1 for a in range(-R, R + 1)) - 1
for N in (10, X):
    D = sum(chi4(d) * (N // d) for d in range(1, N + 1))
    assert lattice(N) == 4 * D                   # Jacobi's two-squares count, checked
    print("N", N, "| lattice points", lattice(N), "| divisor sum", D, "| sum/N", f(D / N))
assert abs(D / X - Q) < 2 / math.sqrt(X)
r = [0] * (X + 1)                                # r(n) = sum of chi4(d) over d | n
for d in range(1, X + 1, 2):
    c = chi4(d)
    for m in range(d, X + 1, d): r[m] += c
assert min(r[1:]) >= 0 and min(r[m * m] for m in range(1, 1001)) >= 1
print("r(n) for n <= 10^6: smallest", min(r[1:]), "| smallest at a square", min(r[m * m] for m in range(1, 1001)))
print("x, A(x) = sum r(n)/sqrt(n), 2 sqrt(x) pi/4, difference, floor (log x)/2")
A, n = 0.0, 0
for x in (10 ** 2, 10 ** 4, 10 ** 6):
    while n < x:
        n += 1; A += r[n] / math.sqrt(n)
    main = 2 * math.sqrt(x) * Q
    assert A >= math.log(x) / 2 and abs(A - main) < 2
    print(x, f(A), f(main), f(A - main), f(math.log(x) / 2))

# ---- primes in the two classes mod 4: the sum of chi4(p)/p against its predicted limit ----
print("primes below 10^6: 1 mod 4", sum(1 for p in primes if p % 4 == 1), "| 3 mod 4", sum(1 for p in primes if p % 4 == 3))
Sd = corr = 0.0                                  # sum of chi4(p)/p; prime powers p^k, k >= 2, in log L
for p in primes:
    t = chi4(p) / p; tk = t; Sd += t
    for k in range(2, 41):
        tk *= t; corr += tk / k
pred = math.log(Q) - corr
assert abs(Sd - pred) < 0.001
print("sum chi4(p)/p, p below 10^6", f(Sd, 4), "| log(pi/4)", f(math.log(Q)), "| minus prime powers: predicted limit", f(pred), "| gap", f(Sd - pred))

# ---- last digits: the characters mod 10, chi(3) = i^j ----
print("last digit 1, 3, 7, 9:", ", ".join(str(sum(1 for p in primes if p % 10 == a)) for a in (1, 3, 7, 9)))
pos, I4 = {1: 0, 3: 1, 9: 2, 7: 3}, (1, 1j, -1, -1j)    # 3^k mod 10 is 1, 3, 9, 7
for jj in (1, 2, 3):
    ch = lambda n: I4[jj * pos[n % 10] % 4] if n % 10 in pos else 0
    L = avg_tail(ch, 10, 1, X)
    assert abs(L) > 0.3                            # nonzero, as the theorem needs
    print("mod 10, chi(3) = i^%d: L(1,chi) = %s %s %si | size %s" % (jj, f(L.real), "+" if L.imag >= 0 else "-", f(abs(L.imag)), f(abs(L))))
    if jj == 2:
        L10, cf = L.real, 3 * math.log((1 + math.sqrt(5)) / 2) / math.sqrt(5)
        assert abs(L.real - cf) < 1e-9
        print("closed form 3 log((1 + sqrt 5)/2)/sqrt 5", f(cf))

# ---- two more values with closed forms ----
L3 = avg_tail(chi4, 4, 3, X)
print("L(3,chi4)", f(L3), "| pi^3/32", f(PI * PI * PI / 32))
assert abs(L3 - PI * PI * PI / 32) < 1e-12
chi5 = lambda n: (0, 1, -1, -1, 1)[n % 5]        # the real character mod 5, (n/5)
L15, cf5 = avg_tail(chi5, 5, 1, X), 2 * math.log((1 + math.sqrt(5)) / 2) / math.sqrt(5)
print("mod 5, L(1,chi5)", f(L15), "| 2 log((1 + sqrt 5)/2)/sqrt 5", f(cf5), "| mod-10 value / mod-5 value", f(L10 / L15))
assert abs(L15 - cf5) < 1e-9 and abs(L10 / L15 - 1.5) < 1e-9   # the mod-10 value drops the factor at 2
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
pi by Machin 3.14159265359 | pi/4 0.785398163397
chart, partial sums, 1 to 12 terms: 1.0000, 0.6667, 0.8667, 0.7238, 0.8349, 0.7440, 0.8209, 0.7543, 0.8131, 0.7605, 0.8081, 0.7646
terms N, partial sum, error, bracket 1/(2(2N+1)) to 1/(2N+1)
10 0.760459905 0.024938259 0.023809524 0.047619048
100 0.782898226 0.002499938 0.002487562 0.004975124
1000 0.785148163 0.000250000 0.000249875 0.000499750
1000000 0.785397913 0.00000025000000 0.00000024999988 0.00000049999975
Euler product at s=2, primes 3; 3, 5; 3, 5, 7: 0.900000, 0.937500, 0.918750
L(2,chi4) series 0.915965594 | Euler product, primes below 10^6 0.915965594 | gap 0.000000000
weight (-1)^(n+1) at s=2: series 0.822467 = pi^2/12 0.822467 | fake product 0.986960
principal chi0 mod 4 at s=1: odd n to 10^3 4.089059 | to 10^6 7.542937
rearranged 1 + 1/5 - 1/3 + ...: 0.958685 | pi/4 + (log 2)/4 0.958685
N 10 | lattice points 36 | divisor sum 9 | sum/N 0.900000
N 1000000 | lattice points 3141548 | divisor sum 785387 | sum/N 0.785387
r(n) for n <= 10^6: smallest 0 | smallest at a square 1
x, A(x) = sum r(n)/sqrt(n), 2 sqrt(x) pi/4, difference, floor (log x)/2
100 14.801469 15.707963 -0.906494 2.302585
10000 156.107211 157.079633 -0.972422 4.605170
1000000 1569.810344 1570.796327 -0.985982 6.907755
primes below 10^6: 1 mod 4 39175 | 3 mod 4 39322
sum chi4(p)/p, p below 10^6 -0.3350 | log(pi/4) -0.241564 | minus prime powers: predicted limit -0.334981 | gap 0.000002
last digit 1, 3, 7, 9: 19617, 19665, 19621, 19593
mod 10, chi(3) = i^1: L(1,chi) = 0.966883 + 0.228250i | size 0.993459
mod 10, chi(3) = i^2: L(1,chi) = 0.645613 + 0.000000i | size 0.645613
closed form 3 log((1 + sqrt 5)/2)/sqrt 5 0.645613
mod 10, chi(3) = i^3: L(1,chi) = 0.966883 - 0.228250i | size 0.993459
L(3,chi4) 0.968946 | pi^3/32 0.968946
mod 5, L(1,chi5) 0.430409 | 2 log((1 + sqrt 5)/2)/sqrt 5 0.430409 | mod-10 value / mod-5 value 1.500000
ALL CHECKS PASS
```

### Rust

```rust
// Dirichlet L-functions: the check behind the card.  Rust std only, no crates.
// Roads to L(1, chi_4) = pi/4: the series with its proved error bracket, pi from
// Machin's arctangent formula, and lattice points in a circle.  Primes: a sieve.

fn chi4(n: u64) -> i64 { if n % 2 == 0 { 0 } else if n % 4 == 1 { 1 } else { -1 } }
fn f(x: f64, k: usize) -> String { format!("{:.*}", k, x) }
fn isqrt(n: u64) -> u64 {
    let mut r = (n as f64).sqrt() as u64;
    while r * r > n { r -= 1; }
    while (r + 1) * (r + 1) <= n { r += 1; }
    r
}
fn atan_series(x: f64) -> f64 { // arctan x = x - x^3/3 + x^5/5 - ..., 40 terms
    let (mut total, mut power) = (0.0, x);
    for k in 0..40 {
        total += (if k % 2 == 0 { 1.0 } else { -1.0 }) * power / (2 * k + 1) as f64;
        power *= x * x;
    }
    total
}
// sum chi(n)/n^s with complex chi = (re, im), averaged over the partial sums at
// N = M .. M+q-1: the 1/M error term cancels
fn avg_tail(chi: &dyn Fn(u64) -> (f64, f64), q: u64, s: u32, m: u64) -> (f64, f64) {
    let (mut tr, mut ti, mut ar, mut ai) = (0.0, 0.0, 0.0, 0.0);
    for n in 1..m + q {
        let (cr, ci) = chi(n);
        let d = n.pow(s) as f64;
        tr += cr / d; ti += ci / d;
        if n >= m { ar += tr; ai += ti; }
    }
    (ar / q as f64, ai / q as f64)
}
fn real(g: fn(u64) -> i64) -> impl Fn(u64) -> (f64, f64) { move |n| (g(n) as f64, 0.0) }

fn main() {
    let pi = 16.0 * atan_series(1.0 / 5.0) - 4.0 * atan_series(1.0 / 239.0); let q = pi / 4.0;
    println!("pi by Machin {} | pi/4 {}", f(pi, 11), f(q, 12));

    // ---- the series L(1, chi_4) = 1 - 1/3 + 1/5 - ..., error bracket from Step 3 ----
    let (mut s, mut part) = (0.0f64, vec![]);
    for k in 0..12 { s += (if k % 2 == 0 { 1.0 } else { -1.0 }) / (2 * k + 1) as f64; part.push(f(s, 4)); }
    println!("chart, partial sums, 1 to 12 terms: {}", part.join(", "));
    println!("terms N, partial sum, error, bracket 1/(2(2N+1)) to 1/(2N+1)");
    let (mut s, mut k) = (0.0f64, 0u64);
    for &n in &[10u64, 100, 1000, 1_000_000] {
        while k < n { s += (if k % 2 == 0 { 1.0 } else { -1.0 }) / (2 * k + 1) as f64; k += 1; }
        let err = (s - q).abs();
        let (lo, hi) = (1.0 / (2 * (2 * n + 1)) as f64, 1.0 / (2 * n + 1) as f64);
        assert!(lo < err && err < hi); // Step 3's bracket
        let dp = if n == 1_000_000 { 14 } else { 9 }; // at 10^6, nine decimals would hide the gap to the low end
        println!("{} {} {} {} {}", n, f(s, 9), f(err, dp), f(lo, dp), f(hi, dp));
    }

    // ---- primes below a million, and the Euler product at s = 2 ----
    let x: u64 = 1_000_000;
    let mut sv = vec![true; x as usize]; sv[0] = false; sv[1] = false;
    for i in 2..1001usize { if sv[i] { let mut j = i * i; while j < x as usize { sv[j] = false; j += i; } } }
    let primes: Vec<u64> = (0..x).filter(|&p| sv[p as usize]).collect();
    let g = avg_tail(&real(chi4), 4, 2, x).0; // Catalan's constant, by the series
    let mut e = 1.0;
    for &p in &primes { e /= 1.0 - chi4(p) as f64 / (p * p) as f64; }
    let (mut e3, mut v) = (vec![], 1.0);
    for &p in &[3u64, 5, 7] { v /= 1.0 - chi4(p) as f64 / (p * p) as f64; e3.push(f(v, 6)); }
    println!("Euler product at s=2, primes 3; 3, 5; 3, 5, 7: {}", e3.join(", "));
    println!("L(2,chi4) series {} | Euler product, primes below 10^6 {} | gap {}", f(g, 9), f(e, 9), f((g - e).abs(), 9));
    assert!((g - e).abs() < 1e-6); // Step 2: gap below 1/1,000,000
    fn alt(n: u64) -> i64 { if n % 2 == 1 { 1 } else { -1 } } // periodic, not multiplicative
    let mut ealt = 1.0;
    for &p in &primes { ealt /= 1.0 - alt(p) as f64 / (p * p) as f64; }
    let salt = avg_tail(&real(alt), 2, 2, x).0;
    assert!((salt - pi * pi / 12.0).abs() < 1e-9 && (ealt - salt).abs() > 0.1);
    println!("weight (-1)^(n+1) at s=2: series {} = pi^2/12 {} | fake product {}", f(salt, 6), f(pi * pi / 12.0, 6), f(ealt, 6));
    let mut h = vec![];
    for &n in &[1000u64, 1_000_000] {
        let mut t = 0.0; let mut m = 1u64;
        while m <= n { t += 1.0 / m as f64; m += 2; }
        h.push(t);
    }
    println!("principal chi0 mod 4 at s=1: odd n to 10^3 {} | to 10^6 {}", f(h[0], 6), f(h[1], 6));
    let (mut r3, mut i, mut j) = (0.0f64, 0u64, 0u64); // two plus terms, one minus
    for _ in 0..300000 {
        r3 += 1.0 / (4 * i + 1) as f64 + 1.0 / (4 * i + 5) as f64 - 1.0 / (4 * j + 3) as f64; i += 2; j += 1;
    }
    let target = q + 2f64.ln() / 4.0;
    println!("rearranged 1 + 1/5 - 1/3 + ...: {} | pi/4 + (log 2)/4 {}", f(r3, 6), f(target, 6));
    assert!((r3 - target).abs() < 1e-5);

    // ---- lattice points: sum of r(n) = sum chi4(d) floor(N/d) = (points in circle)/4 ----
    let lattice = |n: u64| -> i64 { // points (a, b) with 0 < a^2 + b^2 <= n
        let r = isqrt(n) as i64;
        (-r..=r).map(|a| 2 * isqrt(n - (a * a) as u64) as i64 + 1).sum::<i64>() - 1
    };
    let mut dlast = 0i64;
    for &n in &[10u64, x] {
        let d: i64 = (1..=n).map(|d| chi4(d) * (n / d) as i64).sum();
        assert_eq!(lattice(n), 4 * d); // Jacobi's two-squares count, checked
        println!("N {} | lattice points {} | divisor sum {} | sum/N {}", n, lattice(n), d, f(d as f64 / n as f64, 6));
        dlast = d;
    }
    assert!((dlast as f64 / x as f64 - q).abs() < 2.0 / (x as f64).sqrt());
    let mut r = vec![0i64; x as usize + 1]; // r(n) = sum of chi4(d) over d | n
    let mut d = 1u64;
    while d <= x { let c = chi4(d); let mut m = d; while m <= x { r[m as usize] += c; m += d; } d += 2; }
    let rmin = *r[1..].iter().min().unwrap();
    let sqmin = (1..1001usize).map(|m| r[m * m]).min().unwrap();
    assert!(rmin >= 0 && sqmin >= 1);
    println!("r(n) for n <= 10^6: smallest {} | smallest at a square {}", rmin, sqmin);
    println!("x, A(x) = sum r(n)/sqrt(n), 2 sqrt(x) pi/4, difference, floor (log x)/2");
    let (mut a, mut n) = (0.0f64, 0usize);
    for &xx in &[100usize, 10000, 1_000_000] {
        while n < xx { n += 1; a += r[n] as f64 / (n as f64).sqrt(); }
        let main = 2.0 * (xx as f64).sqrt() * q;
        let fl = (xx as f64).ln() / 2.0;
        assert!(a >= fl && (a - main).abs() < 2.0);
        println!("{} {} {} {} {}", xx, f(a, 6), f(main, 6), f(a - main, 6), f(fl, 6));
    }

    // ---- primes in the two classes mod 4: the sum of chi4(p)/p against its predicted limit ----
    let c1 = primes.iter().filter(|&&p| p % 4 == 1).count();
    let c3 = primes.iter().filter(|&&p| p % 4 == 3).count();
    println!("primes below 10^6: 1 mod 4 {} | 3 mod 4 {}", c1, c3);
    let (mut sd, mut corr) = (0.0f64, 0.0f64); // sum of chi4(p)/p; prime powers p^k, k >= 2, in log L
    for &p in &primes {
        let t = chi4(p) as f64 / p as f64; let mut tk = t; sd += t;
        for k in 2..41 { tk *= t; corr += tk / k as f64; }
    }
    let pred = q.ln() - corr;
    assert!((sd - pred).abs() < 0.001);
    println!("sum chi4(p)/p, p below 10^6 {} | log(pi/4) {} | minus prime powers: predicted limit {} | gap {}",
             f(sd, 4), f(q.ln(), 6), f(pred, 6), f(sd - pred, 6));

    // ---- last digits: the characters mod 10, chi(3) = i^j ----
    let digits: Vec<String> = [1u64, 3, 7, 9].iter().map(|&a| primes.iter().filter(|&&p| p % 10 == a).count().to_string()).collect();
    println!("last digit 1, 3, 7, 9: {}", digits.join(", "));
    let i4 = [(1.0, 0.0), (0.0, 1.0), (-1.0, 0.0), (0.0, -1.0)]; // 3^k mod 10 is 1, 3, 9, 7
    let mut l10 = 0.0;
    for jj in 1..4usize {
        let ch = move |n: u64| -> (f64, f64) {
            match n % 10 { 1 => i4[0], 3 => i4[jj % 4], 9 => i4[2 * jj % 4], 7 => i4[3 * jj % 4], _ => (0.0, 0.0) }
        };
        let (lr, li) = avg_tail(&ch, 10, 1, x);
        let size = (lr * lr + li * li).sqrt();
        assert!(size > 0.3); // nonzero, as the theorem needs
        println!("mod 10, chi(3) = i^{}: L(1,chi) = {} {} {}i | size {}", jj, f(lr, 6), if li >= 0.0 { "+" } else { "-" }, f(li.abs(), 6), f(size, 6));
        if jj == 2 {
            l10 = lr;
            let cf = 3.0 * ((1.0 + 5f64.sqrt()) / 2.0).ln() / 5f64.sqrt();
            assert!((lr - cf).abs() < 1e-9);
            println!("closed form 3 log((1 + sqrt 5)/2)/sqrt 5 {}", f(cf, 6));
        }
    }

    // ---- two more values with closed forms ----
    let l3 = avg_tail(&real(chi4), 4, 3, x).0;
    println!("L(3,chi4) {} | pi^3/32 {}", f(l3, 6), f(pi * pi * pi / 32.0, 6));
    assert!((l3 - pi * pi * pi / 32.0).abs() < 1e-12);
    fn chi5(n: u64) -> i64 { [0, 1, -1, -1, 1][(n % 5) as usize] } // the real character mod 5, (n/5)
    let (l15, cf5) = (avg_tail(&real(chi5), 5, 1, x).0, 2.0 * ((1.0 + 5f64.sqrt()) / 2.0).ln() / 5f64.sqrt());
    println!("mod 5, L(1,chi5) {} | 2 log((1 + sqrt 5)/2)/sqrt 5 {} | mod-10 value / mod-5 value {}", f(l15, 6), f(cf5, 6), f(l10 / l15, 6));
    assert!((l15 - cf5).abs() < 1e-9 && (l10 / l15 - 1.5).abs() < 1e-9); // the mod-10 value drops the factor at 2
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
pi by Machin 3.14159265359 | pi/4 0.785398163397
chart, partial sums, 1 to 12 terms: 1.0000, 0.6667, 0.8667, 0.7238, 0.8349, 0.7440, 0.8209, 0.7543, 0.8131, 0.7605, 0.8081, 0.7646
terms N, partial sum, error, bracket 1/(2(2N+1)) to 1/(2N+1)
10 0.760459905 0.024938259 0.023809524 0.047619048
100 0.782898226 0.002499938 0.002487562 0.004975124
1000 0.785148163 0.000250000 0.000249875 0.000499750
1000000 0.785397913 0.00000025000000 0.00000024999988 0.00000049999975
Euler product at s=2, primes 3; 3, 5; 3, 5, 7: 0.900000, 0.937500, 0.918750
L(2,chi4) series 0.915965594 | Euler product, primes below 10^6 0.915965594 | gap 0.000000000
weight (-1)^(n+1) at s=2: series 0.822467 = pi^2/12 0.822467 | fake product 0.986960
principal chi0 mod 4 at s=1: odd n to 10^3 4.089059 | to 10^6 7.542937
rearranged 1 + 1/5 - 1/3 + ...: 0.958685 | pi/4 + (log 2)/4 0.958685
N 10 | lattice points 36 | divisor sum 9 | sum/N 0.900000
N 1000000 | lattice points 3141548 | divisor sum 785387 | sum/N 0.785387
r(n) for n <= 10^6: smallest 0 | smallest at a square 1
x, A(x) = sum r(n)/sqrt(n), 2 sqrt(x) pi/4, difference, floor (log x)/2
100 14.801469 15.707963 -0.906494 2.302585
10000 156.107211 157.079633 -0.972422 4.605170
1000000 1569.810344 1570.796327 -0.985982 6.907755
primes below 10^6: 1 mod 4 39175 | 3 mod 4 39322
sum chi4(p)/p, p below 10^6 -0.3350 | log(pi/4) -0.241564 | minus prime powers: predicted limit -0.334981 | gap 0.000002
last digit 1, 3, 7, 9: 19617, 19665, 19621, 19593
mod 10, chi(3) = i^1: L(1,chi) = 0.966883 + 0.228250i | size 0.993459
mod 10, chi(3) = i^2: L(1,chi) = 0.645613 + 0.000000i | size 0.645613
closed form 3 log((1 + sqrt 5)/2)/sqrt 5 0.645613
mod 10, chi(3) = i^3: L(1,chi) = 0.966883 - 0.228250i | size 0.993459
L(3,chi4) 0.968946 | pi^3/32 0.968946
mod 5, L(1,chi5) 0.430409 | 2 log((1 + sqrt 5)/2)/sqrt 5 0.430409 | mod-10 value / mod-5 value 1.500000
ALL CHECKS PASS
```

### Lean

Lean proves the card's three theorems for every modulus: L(1, χ) ≠ 0, the series and Euler product, and π/4 for χ₄.

- Take any modulus q and any character χ mod q other than the principal character χ₀. Then L(1, χ) ≠ 0.
- Take any character χ and any s with σ > 1. Then L(s, χ) equals the sum of $`\chi(n)/n^{s}`$ over all whole numbers n. It also equals the product over every prime p of $`1/(1 - \chi(p)\,p^{-s})`$.
- Take the partial sums of 1 − 1/3 + 1/5 − …, in the natural order. Then they tend to π/4.
- The hand arithmetic is checked too: the weights χ₄(1) to χ₄(10), the divisor sum 9 and the 36 points.
- So are r(5) = 2, r(3) = 0, the running Euler product at s = 2, and the weight that fails to multiply.

Every decimal, every count to a million and the mod-10 values are left to the Python and Rust checks.

```lean
-- Dirichlet L-functions: the L-function of every non-principal Dirichlet character is nonzero at 1, for σ > 1 it is the series of χ(n)/n^s and the product over primes of 1/(1 − χ(p)p^(−s)), and for the character mod 4 the series 1 − 1/3 + 1/5 − … sums to π/4.
import Mathlib.NumberTheory.LSeries.Nonvanishing
import Mathlib.NumberTheory.EulerProduct.DirichletLSeries
import Mathlib.NumberTheory.LegendreSymbol.ZModChar
import Mathlib.Analysis.Real.Pi.Leibniz

open Filter Topology Finset

/-- The value at 1 is never zero: for every Dirichlet character χ mod q other than the
principal character (the modulus q a positive whole number), the L-function L(s, χ) is not
zero at s = 1. -/
theorem dirichlet_L_one_ne_zero {q : ℕ} [NeZero q] (χ : DirichletCharacter ℂ q) (hχ : χ ≠ 1) :
    DirichletCharacter.LFunction χ 1 ≠ 0 := by
  exact DirichletCharacter.LFunction_apply_one_ne_zero hχ

/-- The series and the Euler product: when the real part of s is above 1, the L-function of a
Dirichlet character χ is the sum of χ(n)/n^s over the whole numbers n, and it is also the
product over all primes p of 1/(1 − χ(p) p^(−s)). -/
theorem dirichlet_L_series_and_euler_product {q : ℕ} [NeZero q] (χ : DirichletCharacter ℂ q) {s : ℂ}
    (hs : 1 < s.re) :
    HasSum (fun n : ℕ ↦ χ n / (n : ℂ) ^ s) (DirichletCharacter.LFunction χ s) ∧
      HasProd (fun p : Nat.Primes ↦ (1 - χ p * (p : ℂ) ^ (-s))⁻¹)
        (DirichletCharacter.LFunction χ s) := by
  have hsum : HasSum (fun n : ℕ ↦ χ n / (n : ℂ) ^ s) (DirichletCharacter.LFunction χ s) := by
    rw [DirichletCharacter.LFunction_eq_LSeries χ hs]
    have h := (DirichletCharacter.LSeriesSummable_of_one_lt_re χ hs).LSeriesHasSum
    have hs0 : s ≠ 0 := by
      intro h0
      rw [h0] at hs
      simp at hs
      linarith
    unfold LSeriesHasSum at h
    convert h using 1
    funext n
    rcases eq_or_ne n 0 with rfl | hn
    · simp [Complex.zero_cpow hs0]
    · rw [LSeries.term_of_ne_zero hn]
  refine ⟨hsum, ?_⟩
  rw [DirichletCharacter.LFunction_eq_LSeries χ hs]
  exact DirichletCharacter.LSeries_eulerProduct_hasProd χ hs

/-- The odd character mod 4 at s = 1: the partial sums of χ₄(n)/n, that is
1 − 1/3 + 1/5 − 1/7 + …, tend to π/4. -/
theorem chi4_L_one_eq_pi_div_four :
    Tendsto (fun N : ℕ ↦ ∑ n ∈ range N, ((ZMod.χ₄ (n : ZMod 4) : ℤ) : ℝ) / n) atTop
      (𝓝 (Real.pi / 4)) := by
  have key : ∀ k : ℕ,
      (∑ n ∈ range (2 * k), ((ZMod.χ₄ (n : ZMod 4) : ℤ) : ℝ) / n) =
        ∑ i ∈ range k, (-1 : ℝ) ^ i / (2 * i + 1) := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [show 2 * (k + 1) = 2 * k + 1 + 1 by ring, sum_range_succ, sum_range_succ, ih,
        sum_range_succ]
      have h0 : ZMod.χ₄ ((2 * k : ℕ) : ZMod 4) = 0 := by
        rw [ZMod.χ₄_nat_eq_if_mod_four]
        simp [Nat.mul_mod_right]
      have h1 : ZMod.χ₄ ((2 * k + 1 : ℕ) : ZMod 4) = (-1) ^ k := by
        rw [ZMod.χ₄_eq_neg_one_pow (by omega)]
        congr 1
        omega
      rw [h0, h1]
      push_cast
      ring
  have key' : ∀ N : ℕ,
      (∑ n ∈ range N, ((ZMod.χ₄ (n : ZMod 4) : ℤ) : ℝ) / n) =
        ∑ i ∈ range (N / 2), (-1 : ℝ) ^ i / (2 * i + 1) := by
    intro N
    rcases Nat.even_or_odd' N with ⟨k, rfl | rfl⟩
    · rw [key, show 2 * k / 2 = k by omega]
    · rw [sum_range_succ, key, show (2 * k + 1) / 2 = k by omega]
      have h0 : ZMod.χ₄ ((2 * k : ℕ) : ZMod 4) = 0 := by
        rw [ZMod.χ₄_nat_eq_if_mod_four]
        simp [Nat.mul_mod_right]
      rw [h0]
      simp
  have hdiv : Tendsto (fun N : ℕ ↦ N / 2) atTop atTop := by
    rw [tendsto_atTop_atTop]
    intro b
    exact ⟨2 * b, fun n hn ↦ by omega⟩
  simp_rw [key']
  exact Real.tendsto_sum_pi_div_four.comp hdiv

-- The weights χ₄(1) to χ₄(10): 1, 0, −1, 0, 1, 0, −1, 0, 1, 0.
example : (List.range' 1 10).map (fun n : ℕ ↦ ZMod.χ₄ (n : ZMod 4)) =
    [1, 0, -1, 0, 1, 0, -1, 0, 1, 0] := by decide

-- The divisor sum to 10: the sum of χ₄(d)⌊10/d⌋ for d from 1 to 10 is 10 − 3 + 2 − 1 + 1 = 9.
example : ∑ d ∈ Icc (1 : ℕ) 10, ZMod.χ₄ (d : ZMod 4) * ((10 / d : ℕ) : ℤ) = 9 := by decide

-- The integer points (a, b) with 0 < a² + b² ≤ 10 number 36 = 4 × 9.
example : ((Icc (-3 : ℤ) 3 ×ˢ Icc (-3 : ℤ) 3).filter
    (fun x ↦ 0 < x.1 ^ 2 + x.2 ^ 2 ∧ x.1 ^ 2 + x.2 ^ 2 ≤ 10)).card = 36 := by decide

-- r(5) = χ₄(1) + χ₄(5) = 2 and r(3) = χ₄(1) + χ₄(3) = 0.
example : ∑ d ∈ Nat.divisors 5, ZMod.χ₄ (d : ZMod 4) = 2 := by decide
example : ∑ d ∈ Nat.divisors 3, ZMod.χ₄ (d : ZMod 4) = 0 := by decide

-- The running Euler product at s = 2 over 3, 5, 7: 9/10, then 15/16, then 147/160.
example : (1 - (ZMod.χ₄ (3 : ZMod 4) : ℚ) / 3 ^ 2)⁻¹ = 9 / 10 := by norm_num [ZMod.χ₄_int_three_mod_four]
example : (1 - (-1 : ℚ) / 3 ^ 2)⁻¹ * (1 - (1 : ℚ) / 5 ^ 2)⁻¹ = 15 / 16 := by norm_num
example : (1 - (-1 : ℚ) / 3 ^ 2)⁻¹ * (1 - (1 : ℚ) / 5 ^ 2)⁻¹ * (1 - (-1 : ℚ) / 7 ^ 2)⁻¹ =
    147 / 160 := by norm_num

-- The weight (−1)^(n+1) is not multiplicative: its value at 2 times itself is +1, at 4 it is −1.
example : ((-1 : ℤ) ^ (2 + 1)) * ((-1 : ℤ) ^ (2 + 1)) = 1 ∧ (-1 : ℤ) ^ (4 + 1) = -1 := by decide

#print axioms dirichlet_L_one_ne_zero
#print axioms dirichlet_L_series_and_euler_product
#print axioms chi4_L_one_eq_pi_div_four
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'dirichlet_L_one_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'dirichlet_L_series_and_euler_product' depends on axioms: [propext, Classical.choice, Quot.sound]
'chi4_L_one_eq_pi_div_four' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **The power in the Euler product.** In the line `for p in primes: E /= 1 - chi4(p) / (p * p)`, change `(p * p)` to `(p * p * p)`. Guess first: does the product still match the series for L(2, χ₄)? No: it now builds L(3, χ₄) and prints 0.968946146, a gap of 0.052980552, and the Step 2 assert stops the run.
> - **A higher power in the series.** Change `avg_tail(chi4, 4, 3, X)` to `avg_tail(chi4, 4, 5, X)`. Guess first: nearer 1 or further? Nearer: the `L(3,chi4)` line prints 0.996158, which is 5π⁵/1536, and the assert after it stops the run, since it pins π³/32.
> - **A bigger circle.** In the lattice loop, change `(10, X)` to `(100, X)`. Guess first: about π × 100 points. The line prints 316 points and a divisor sum of 79, a quarter of 316, so the share is 0.790000. Every assert still passes.
> - **Three plus terms per minus term.** In the rearranged loop, add `+ 1 / (4 * i + 9)` after the second plus term and change `i += 2` to `i += 3`. Guess first: the sum moves up again. It prints 1.060051, which is π/4 + (log 3)/4, and the assert after it stops the run, since it pins the log 2 value.

---

## The usual mistake

> [!warning]
> **Reading the Euler product as a proof that L(1, χ) ≠ 0.** A product of non-zero factors is non-zero where it converges absolutely, which is σ > 1. At s = 1 that argument is gone. The principal character's product there does not converge at all: 1 + 1/3 + 1/5 + … reaches 7.542937 by a million and keeps climbing. Non-vanishing at 1 needs Step 5's separate argument: two zeros against one pole for complex characters, and the floor-and-ceiling count of r(n)/√n for real ones.
>
> Smaller traps:
> - **Rearranging the series at 1.** Two plus terms per minus term gives 0.958685, not 0.785398.
> - **Stopping early.** Ten terms give 0.760459905, off by 0.024938259. The error falls only like 1/(4N).
> - **Using a repeating weight that does not multiply.** The weight $`(-1)^{n+1}`$ gives a product of 0.986960 at s = 2, against its true series value 0.822467.
> - **Taking the counts as proof.** 39,175 primes leave 1 and 39,322 leave 3 below a million. That is evidence to a million, not a statement about all primes.

---

## Where you meet it in real life

- **Primes in any progression.** [Dirichlet's theorem](04-dirichlets-theorem-on-primes-in-progressions.md) is this card's mechanism run for every modulus: infinitely many primes end in 1, 3, 7 or 9, and each class gets a quarter of them in the long run.
- **Cryptography.** The Rabin cryptosystem and the Blum Blum Shub generator use primes that leave 3 on division by 4, so that square roots mod p are easy to take. Key generators find them fast because about half of all primes qualify (39,322 below a million): the prime number theorem for progressions, stated on [Dirichlet's theorem](04-dirichlets-theorem-on-primes-in-progressions.md), says that share tends to one half.
- **Computing π.** The series 1 − 1/3 + 1/5 − … is L(1, χ₄). It converges too slowly to use, which is why the code uses Machin's arctangent formula, its faster relative.
- **Class numbers.** For a real character, L(1, χ) measures how far unique factorisation fails in a quadratic number field. The value 2 log((1 + √5)/2)/√5 = 0.430409 for the real character mod 5 is an example, and the mod-10 value 0.645613 is 3/2 times it (Step 4); [The class number formula](../06-Algebraic%20Numbers/06-class-number-formula-and-the-dedekind-zeta-function.md) explains it.
- **Prime races.** Below a million the class 3 mod 4 is ahead, 39,322 to 39,175. Rubinstein and Sarnak (Sources) showed, assuming the generalised Riemann hypothesis (proved for these L-functions in 2026) and a further condition on the zeros of L(s, χ₄), that class 3 leads most of the time.

> **Say it back**
> A Dirichlet character weights the whole numbers in a repeating, completely multiplicative pattern, and its L-function adds those weights against the powers of n. Because the weights multiply, the L-function is a product over the primes, by the same proof as zeta's. For the odd character mod 4 the value at 1 is 1 − 1/3 + 1/5 − … = π/4. Logs of the product separate the primes by class: zeta's pole sends the total to infinity, and a finite, non-zero L(1, χ) shares it out. So the whole difficulty is proving L(1, χ) ≠ 0, which needs a new argument because the product stops converging absolutely at 1.

---

## What this builds on

- [Dirichlet characters](01-dirichlet-characters.md): the weights χ, their period q, complete multiplicativity, the zero sum over a repeat, and how characters combine to pick out one class.
- [Dirichlet series](../../07-Complex%20analysis/09-Special%20Functions%20and%20the%20Zeta%20Function/06-dirichlet-series-and-mobius-inversion.md): series of a weight against n to the minus s, absolute convergence for σ > 1, and products that convolve weights over divisors, as r = 1 * χ does here.
- [The zeta function](../../07-Complex%20analysis/09-Special%20Functions%20and%20the%20Zeta%20Function/05-zeta-function-and-euler-product.md): the Euler product from unique factorisation, no zeros for σ > 1, and the pole at 1 that this card shares out between the classes.

## Where this goes next

- [Dirichlet's theorem](04-dirichlets-theorem-on-primes-in-progressions.md): runs Step 4 for every modulus, with this card's L(1, χ) ≠ 0 as the one extra input, so every progression coprime to its step holds infinitely many primes.
- [The class number formula](../06-Algebraic%20Numbers/06-class-number-formula-and-the-dedekind-zeta-function.md): turns L(1, χ) for a real character into the class number of a quadratic field, explaining values such as 0.430409 mod 5.
- [Birch-Swinnerton-Dyer](../07-Diophantine%20and%20Modular/06-birch-swinnerton-dyer-and-the-congruent-number-problem.md): the same build, a series with an Euler product, made from an elliptic curve, whose behaviour at s = 1 is conjectured to count its rational points.
- [The L-function](../../22-Algebraic%20geometry/04-Elliptic%20Curves/07-l-functions-of-elliptic-curves.md): the general pattern of a series with an Euler product, a functional equation and zeros, of which zeta and these are the first cases.

The siblings [Siegel-Walfisz](05-siegel-walfisz-in-outline.md) and [Gauss sums](06-gauss-sums.md) take L(s, χ) further: how many primes each class holds by x, and the functional equation's constant.

The question this card leaves open: L(1, χ) is never 0, but how close to 1 can a zero of L(s, χ) sit, and how small can L(1, χ) be?

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Dirichlet, Peter Gustav Lejeune. "Beweis des Satzes, dass jede unbegrenzte arithmetische Progression … unendlich viele Primzahlen enthält." *Abhandlungen der Königlichen Preussischen Akademie der Wissenschaften* (1837), English translation by R. Stephan. [arXiv:0808.1408](https://arxiv.org/abs/0808.1408). The first L-series, their products over primes, and the proof for primes in progressions.
- Apostol, Tom M. *Introduction to Analytic Number Theory*. Springer, 1976. [doi:10.1007/978-1-4757-5579-4](https://doi.org/10.1007/978-1-4757-5579-4). Characters, L-series, and the proof that L(1, χ) ≠ 0 for a real character by the floor and ceiling of the sum of r(n)/√n.
- Davenport, Harold. *Multiplicative Number Theory*, 2nd ed., revised by Hugh L. Montgomery. Springer, 1980. [doi:10.1007/978-1-4757-5927-3](https://doi.org/10.1007/978-1-4757-5927-3). Dirichlet's argument with logs of L-functions, and its history.
- Montgomery, Hugh L., and Robert C. Vaughan. *Multiplicative Number Theory I: Classical Theory*. Cambridge University Press, 2006. [doi:10.1017/CBO9780511618314](https://doi.org/10.1017/CBO9780511618314). Primes in progressions, including the convergence of the sum of χ(p)/p for a non-principal character.
- Rubinstein, Michael, and Peter Sarnak. "Chebyshev's bias." *Experimental Mathematics* 3, no. 3 (1994): 173–197. [doi:10.1080/10586458.1994.10504289](https://doi.org/10.1080/10586458.1994.10504289). Why the class 3 mod 4 usually leads the prime race, under stated hypotheses.
