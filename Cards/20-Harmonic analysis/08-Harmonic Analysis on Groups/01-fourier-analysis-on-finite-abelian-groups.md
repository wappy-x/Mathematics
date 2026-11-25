# Fourier analysis on a finite abelian group: characters as the waves, and the transform on bit strings

[Syllabus](../../../SYLLABUS.md) → [Harmonic analysis](../README.md) → [Harmonic Analysis on Groups](../README.md#s08) → Fourier analysis on a finite abelian group

---

## General Overview

Three judges vote on a contest, each +1 (for) or −1 (against). The verdict is the majority. Write it as a sum of simple patterns, one per set of judges:

```math
\mathrm{Maj}(x_1, x_2, x_3) = \tfrac12 x_1 + \tfrac12 x_2 + \tfrac12 x_3 - \tfrac12 x_1 x_2 x_3
```

Try (1, 1, −1): 0.5 + 0.5 − 0.5 + 0.5 = 1, a win. The squares of the four amounts add to 1. Three quarters of that sits on single judges, one quarter on the triple. That split answers a practical question. Average over all eight vote patterns, and misread each vote with chance 10%: the verdict flips with chance 0.136, read straight off the ¾ and ¼ (Step 8 shows how).

The products $`x_1`$, $`x_1 x_2 x_3`$ and so on are **characters**: the waves of a finite group. A 12-hour clock has its own 12 characters, the turning pointers $`k \mapsto e^{2\pi i jk/12}`$, and they are the waves of the discrete Fourier transform ([The DFT and the FFT](../../13-Engineering%20mathematics/05-Signals/02-discrete-fourier-transform-and-the-fft.md)). This card shows one theory behind both cases. It works for any finite group whose operation ignores order.

**On a finite abelian group the characters, the maps that turn the group's addition into multiplication of unit complex numbers, are as many as the members and perpendicular, so every function is one sum of them: energy is kept (Plancherel), convolution becomes multiplication, and a function and its transform cannot both be concentrated.**

**What kind of fact this is:** theorems, proved on this card in Why it works. The character, the dual group and the transform are definitions. The match between a group and its dual exists but depends on a choice.

### The picture: where the verdict's energy sits

The Fourier weight at each degree: the summed squares of the amounts on sets of that many judges.

```
degree 0  (no judge)     |                                0.00
degree 1  (one judge)    |██████████████████████████████  0.75
degree 2  (two judges)   |                                0.00
degree 3  (all three)    |██████████                      0.25
```

The weights add to 1, the average of the squared verdict. Both checks print every bar.

---

## The formula

Notation first, in words.

- An **abelian group** $`G`$ is a group whose operation ignores order. Here it is written as $`+`$. $`\lvert G\rvert`$ is its number of members. $`x`$ and $`y`$ are members.
- $`\mathbb{Z}/N`$ is the $`N`$-hour clock: hours 0 to $`N-1`$, added with wrap-round (the direct-products card writes it Z mod n). The house example is $`\mathbb{Z}/12`$, and $`k`$ is an hour.
- A **character** $`\chi`$ (chi) maps each member to a complex number of size 1 and turns sums into products: $`\chi(x + y) = \chi(x)\chi(y)`$. On the clock, $`\chi_j(k) = e^{2\pi i jk/12}`$ is the pointer that turns $`j`$ twelfths of a circle per hour. Here $`j`$ labels a character, not a wavelet level, and $`i`$ is the imaginary unit.
- The **dual group** $`\widehat G`$ is the set of all characters, multiplied value by value.
- For complex functions $`f`$ and $`g`$ on $`G`$, the inner product averages over the group: $`\langle f, g\rangle = \frac{1}{\lvert G\rvert}\sum_x f(x)\overline{g(x)}`$. The bar is the complex conjugate. This is the circle's average with $`1/2\pi`$ ([Convergence in energy](../01-Fourier%20Series%20in%20Depth/05-l2-convergence-and-riesz-fischer.md)), with the sum in place of the integral.

The transform takes one inner product per character, and four facts follow:

```math
\hat f(\chi) = \frac{1}{\lvert G\rvert}\sum_{x \in G} f(x)\,\overline{\chi(x)}, \qquad f = \sum_{\chi \in \widehat G} \hat f(\chi)\,\chi, \qquad \frac{1}{\lvert G\rvert}\sum_{x} \lvert f(x)\rvert^2 = \sum_{\chi} \lvert \hat f(\chi)\rvert^2
```

**Read it aloud:** the amount of wave $`\chi`$ in $`f`$ is the average of $`f`$ against that wave; adding every wave times its amount rebuilds $`f`$; the average energy of $`f`$ equals the summed energy of its amounts.

```math
\widehat{f * g}(\chi) = \hat f(\chi)\,\hat g(\chi), \qquad (f * g)(x) = \frac{1}{\lvert G\rvert}\sum_{y} f(y)\,g(x - y), \qquad \lvert\mathrm{supp}\, f\rvert \cdot \lvert\mathrm{supp}\, \hat f\rvert \ge \lvert G\rvert
```

**Read it aloud:** blending two functions by convolution multiplies their amounts wave by wave; and for a nonzero $`f`$, the members where $`f`$ is nonzero times the characters where $`\hat f`$ is nonzero number at least the group's size.

On bit strings the group is $`\{-1, 1\}^n`$ under multiplication, entry by entry. Its characters are the products $`\chi_S(x) = \prod_{i \in S} x_i`$, one per set $`S`$ of positions, and the transform is the **Walsh-Hadamard transform**, $`\hat f(S)`$. The **Fourier weight at degree** $`d`$, written $`W^d`$, adds $`\hat f(S)^2`$ over the sets with $`d`$ members.

One warning on scale. [The DFT and the FFT](../../13-Engineering%20mathematics/05-Signals/02-discrete-fourier-transform-and-the-fft.md) has no $`1/N`$ in front, so its output on the clock is $`X[j] = 12\,\hat f(\chi_j)`$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`G`$, $`\lvert G\rvert`$, $`x`$, $`y`$, $`z`$, $`H`$ | an abelian group; its size; members; a subgroup or second group | $`\mathbb{Z}/12`$, 12; $`H`$ = quarter marks 0, 3, 6, 9 | more characters, one per member |
| $`\mathbb{Z}/N`$, $`k`$, $`k_1`$, $`k_2`$; $`a`$, $`b`$ | the $`N`$-hour clock; an hour; its hour mod 4 and mod 3; character labels on $`\mathbb{Z}/4`$ and $`\mathbb{Z}/3`$ | $`\mathbb{Z}/12`$, $`\mathbb{Z}/4`$, $`\mathbb{Z}/3`$; $`\chi_1`$ is $`(a, b) = (3, 1)`$ | — |
| $`\chi`$, $`\psi`$, $`\chi_j`$, $`j`$, $`l`$ | characters; the clock's character number $`j`$ or $`l`$ | $`\chi_1(k) = e^{2\pi i k/12}`$ | a faster-turning pointer |
| $`\widehat G`$ | the dual group: all characters | 12 characters on the clock | — |
| $`i`$, $`e^{i\theta}`$, $`\overline{z}`$ | imaginary unit; the point at angle $`\theta`$ on the unit circle; complex conjugate | $`\chi_4(1) = e^{2\pi i/3}`$ | — |
| $`f`$, $`g`$, $`\mathbf{1}_H`$ | functions on $`G`$; the function that is 1 on $`H`$ and 0 elsewhere | $`f = \mathbf{1}_H`$; $`g`$ = 1 at hours 0 and 1 | — |
| $`\langle f, g\rangle`$ | inner product: average of $`f`$ times conjugate $`g`$ | $`\langle f, f\rangle = 0.333333`$ | — |
| $`\hat f(\chi)`$, $`\hat f(S)`$ | the amount of character $`\chi`$, or $`\chi_S`$, in $`f`$ | $`\hat f(\chi_4) = 1/3`$; $`\widehat{\mathrm{Maj}}(\{1\}) = 0.5`$ | — |
| $`f * g`$ | convolution: the average over $`y`$ of $`f(y)\,g(x - y)`$ | 1/12 on hours 0, 1, 3, 4, … | — |
| $`\mathrm{supp}\, f`$ | the support: where $`f`$ is nonzero | 4 hours for $`f`$, 3 characters for $`\hat f`$ | the other support may shrink |
| $`M`$, $`x_0`$; $`K`$, $`u`$, $`m`$, $`w`$ | Step 6: the largest size of $`f`$ and where it sits; the fold: a subgroup, a member outside it, the steps until a multiple of $`u`$ lands in $`K`$, the value $`\chi'(u)`$ | $`f = \mathbf{1}_H`$: $`M = 1`$ at $`x_0 = 0`$ | — |
| $`n`$, $`x_i`$, $`S`$, $`T`$, $`\chi_S`$, $`\mathrm{Maj}`$, $`W^d`$ | number of positions; vote $`i`$; sets of positions; the product of the votes in $`S`$; majority; weight at degree $`d`$ | 3 judges; $`W^1 = 0.75`$, $`W^3 = 0.25`$ | — |

### When it holds

- **The group is abelian.** The shuffles of three things, $`S_3`$, have 6 members but only 2 characters. Those two keep only a third of the energy of the function that is 1 on one swap. Non-abelian groups need matrices, not numbers: [Peter-Weyl](04-peter-weyl-theorem.md).
- **The group is finite.** The average divides by $`\lvert G\rvert`$. The circle and the line need an integral that ignores shifts, [Haar measure](02-haar-measure.md), and their duals are $`\mathbb{Z}`$ and the line.
- **Characters take complex values.** Only bit strings get by with ±1. On the clock only $`\chi_0`$ and $`\chi_6`$ are real.
- **The clock splits only along sizes that share no factor.** $`\mathbb{Z}/12`$ is $`\mathbb{Z}/4 \times \mathbb{Z}/3`$. It is not $`\mathbb{Z}/6 \times \mathbb{Z}/2`$, whose characters all repeat within 6 steps, while $`\chi_1`$ needs 12.
- **One normalisation, kept throughout.** The $`1/\lvert G\rvert`$ sits on the transform and on convolution, and nowhere else. Mix in the DFT's sums and Plancherel is off by a factor of 12.

---

## Why it works

### Step 0: a character is a wave that shifting only rescales

Slide a function by one hour. Most functions change shape. A character does not: $`\chi(x + y) = \chi(y)\,\chi(x)`$, so sliding by $`y`$ multiplies the whole wave by the fixed number $`\chi(y)`$.

That is the whole engine. In the coordinates given by the characters, every shift becomes a list of multiplications. Convolution is an average of shifts, so it becomes multiplication too. And an average over the group cannot change under a shift, which forces a nontrivial character to average to zero.

### Step 1: the clock's 12 characters

Let $`\chi`$ be a character of $`\mathbb{Z}/12`$. Twelve steps of one hour return to 0, so $`\chi(1)^{12} = \chi(0) = 1`$. Then $`\chi(1)`$ is a 12th root of 1, one of the 12 points $`e^{2\pi i j/12}`$. It fixes everything else: $`\chi(k) = \chi(1)^k`$.

So $`\widehat{\mathbb{Z}/12}`$ holds exactly 12 characters, and $`\chi_j\chi_l = \chi_{j+l}`$. The dual is itself a 12-hour clock. The same holds for every $`\mathbb{Z}/N`$.

The match is not canonical: it rests on a choice. Sending hour 1 to $`\chi_1`$ works, and so do $`\chi_5`$, $`\chi_7`$ and $`\chi_{11}`$, the four characters that need all 12 steps to return to 1. Four equally good matches, and nothing in the group picks one. The match between $`G`$ and the dual of $`\widehat G`$ needs no choice: [Pontryagin duality](03-pontryagin-duality.md).

### Step 2: products of groups have products of characters

On a direct product $`G \times H`$ ([Direct products](../../03-Algebra/08-Groups/07-direct-products.md)), a character of each half gives a character of pairs: $`(x, y) \mapsto \chi(x)\psi(y)`$, with $`\psi`$ a character of $`H`$. Every character of pairs arises this way, so $`\widehat{G \times H}`$ is $`\widehat G \times \widehat H`$.

Two cases matter here.

- **The clock.** [The Chinese remainder theorem](../../02-Number%20theory/03-Clock%20Arithmetic/06-chinese-remainder-theorem.md) matches hour $`k`$ with the pair (k mod 4, k mod 3). Back again, $`k = (9k_1 + 4k_2) \bmod 12`$. Then $`e^{2\pi i jk/12}`$ splits as a $`\mathbb{Z}/4`$ wave times a $`\mathbb{Z}/3`$ wave exactly when $`j = (3a + 4b) \bmod 12`$. For $`\chi_1`$: $`3 \times 3 + 4 \times 1 = 13`$, which wraps to 1.
- **Bit strings.** $`\{-1, 1\}`$ under multiplication is a 2-hour clock, with characters $`x \mapsto 1`$ and $`x \mapsto x`$. So $`\{-1, 1\}^n`$ has the $`2^n`$ characters $`\chi_S`$: choose, position by position, whether $`x_i`$ enters the product.

Every finite abelian group has exactly $`\lvert G\rvert`$ characters. The fold proves it without knowing how the group splits.

<details>
<summary>Detailed proof: a finite abelian group has as many characters as members</summary>

Build $`G`$ up one member at a time. Let $`K`$ be a subgroup, let $`u`$ be a member outside it, and let $`m`$ be the smallest positive whole number with $`mu`$ in $`K`$. The members of $`K' = K + \langle u\rangle`$, all sums of a member of $`K`$ and a multiple of $`u`$, are written $`h + tu`$, with $`h`$ in $`K`$ and $`0 \le t < m`$, each one exactly once, so $`\lvert K'\rvert = m\lvert K\rvert`$.

Take a character $`\chi`$ of $`K`$. A character $`\chi'`$ of $`K'`$ that extends it is fixed by $`w = \chi'(u)`$, through $`\chi'(h + tu) = \chi(h)\,w^t`$. The value $`w`$ must satisfy

$`\displaystyle w^m = \chi'(mu) = \chi(mu),`$

which has exactly $`m`$ solutions on the unit circle. Each solution gives a well-defined character, since the rule turns sums into products: when $`t + t'`$ passes $`m`$, the extra $`mu`$ is absorbed by $`w^m = \chi(mu)`$.

So each character of $`K`$ extends in exactly $`m`$ ways, and $`K'`$ has $`m`$ times as many characters as $`K`$. Start from the subgroup $`\{0\}`$, with one character and one member. Both counts multiply by the same factor at every step, so they stay equal up to $`G`$.

</details>

### Step 3: different characters are perpendicular

Take a character $`\chi`$ other than the constant 1, and a member $`y`$ with $`\chi(y) \ne 1`$. Shifting the sum by $`y`$ reorders it:

```math
\sum_x \chi(x) = \sum_x \chi(x + y) = \chi(y)\sum_x \chi(x)
```

**Read it aloud:** the total is unchanged by the shift, yet the shift multiplies it by a number other than 1, so the total is 0.

For two characters, $`\chi\overline{\psi}`$ is again a character, constant 1 only when $`\chi = \psi`$. So $`\langle \chi, \psi\rangle`$ is 1 for equal characters and 0 otherwise. The checks test all 144 pairs on the clock. For every finite group, abelian or not, the same orthogonality comes from Schur's lemma ([Schur's lemma and orthogonality](../../03-Algebra/12-Group%20Representations/02-schurs-lemma-and-character-orthogonality.md)). The shift argument above is the abelian shortcut.

### Step 4: inversion and Plancherel

The functions on $`G`$ form a space of dimension $`\lvert G\rvert`$: one number per member. Step 2 gives $`\lvert G\rvert`$ characters, and Step 3 makes them perpendicular with length 1. So they are an orthonormal basis, and the rest is the usual coordinates in an orthonormal basis.

- The coordinate of $`f`$ along $`\chi`$ is $`\langle f, \chi\rangle = \hat f(\chi)`$. Adding coordinate times basis vector rebuilds $`f`$: inversion.
- Length squared is the sum of squared coordinates: Plancherel.

On the clock, $`\mathbf{1}_H`$ for the quarter marks has average energy 4/12 = 0.333333. Its transform is 1/3 at $`\chi_0`$, $`\chi_4`$ and $`\chi_8`$, so the summed energy is 3/9 = 0.333333. Infinite series needed a completeness theorem for this ([Convergence in energy](../01-Fourier%20Series%20in%20Depth/05-l2-convergence-and-riesz-fischer.md)). A finite group needs only a count.

### Step 5: convolution becomes multiplication

Write $`x = y + z`$. Then $`\overline{\chi(x)} = \overline{\chi(y)}\,\overline{\chi(z)}`$, and the double sum splits:

```math
\widehat{f * g}(\chi) = \frac{1}{\lvert G\rvert^2}\sum_{y}\sum_{z} f(y)\,g(z)\,\overline{\chi(y)}\,\overline{\chi(z)} = \hat f(\chi)\,\hat g(\chi)
```

**Read it aloud:** because a character turns the sum $`y + z`$ into a product, the transform of a blend factors into the two transforms.

This is the finite twin of [The convolution theorem](../03-Convolution%20and%20Approximate%20Identities/02-convolution-theorem-and-impulse-response.md). On the clock, take $`f = \mathbf{1}_H`$ and the two-hour window $`g`$. Then $`(f * g)`$ is 1/12 on hours 0, 1, 3, 4, 6, 7, 9, 10, and its transform at $`\chi_4`$ is $`0.013889 - 0.024056i = \hat f(\chi_4)\,\hat g(\chi_4)`$.

### Step 6: a function and its transform cannot both be small

Let $`f`$ be nonzero, with its largest size $`M`$ at some member $`x_0`$. Three inequalities chain together:

- Inversion: $`M = \lvert f(x_0)\rvert \le \sum_\chi \lvert \hat f(\chi)\rvert`$.
- Cauchy-Schwarz (a sum of products is at most the product of the square roots of the sums of squares) over the $`\lvert\mathrm{supp}\, \hat f\rvert`$ nonzero terms: that sum is at most $`\sqrt{\lvert\mathrm{supp}\, \hat f\rvert}\,\sqrt{\sum_\chi \lvert\hat f(\chi)\rvert^2}`$.
- Plancherel, with each $`\lvert f(x)\rvert^2 \le M^2`$ on the support: $`\sum_\chi \lvert\hat f(\chi)\rvert^2 \le M^2\,\lvert\mathrm{supp}\, f\rvert / \lvert G\rvert`$.

Chain them, divide by $`M`$ and square: $`\lvert G\rvert \le \lvert\mathrm{supp}\, f\rvert\cdot\lvert\mathrm{supp}\, \hat f\rvert`$.

The quarter marks meet it exactly: 4 hours and 3 characters, 4 × 3 = 12. A subgroup's indicator has its transform on the characters that equal 1 on the subgroup, and there are $`\lvert G\rvert/\lvert H\rvert`$ of those ([Cosets and Lagrange's theorem](../../03-Algebra/08-Groups/04-cosets-and-lagranges-theorem.md)). The two-hour window is far from the bound: 2 hours, 11 characters, 22. The checks try all 4,095 nonempty sets of hours. The smallest product is 12, reached by exactly the 28 cosets of the clock's 6 subgroups.

### Step 7: fast transforms come from splitting the group

A direct transform on the clock takes 12 × 12 = 144 products. The split $`\mathbb{Z}/4 \times \mathbb{Z}/3`$ does it in two passes: 3-point transforms for each of the 4 values of $`k_1`$, then 4-point sums for each of the 12 outputs. That is 84 products in all, and it needs no twiddle factors, because the Chinese remainder theorem makes the clock an honest product.

On bit strings the split goes all the way down to $`\mathbb{Z}/2`$ factors. Each pass pairs inputs that differ in one position and replaces them by their sum and difference, a butterfly. For three judges: 3 passes of 4 butterflies, 24 additions and subtractions, against 8 × 8 = 64 products for the direct sums.

### Step 8: noise, read off the weights

Let $`y`$ be the votes $`x`$ with each one misread, independently, with chance 0.1. The verdict flips exactly when $`\mathrm{Maj}(x)\,\mathrm{Maj}(y) = -1`$, so the chance of a flip is ½ − ½ times the average of $`\mathrm{Maj}(x)\,\mathrm{Maj}(y)`$ over all votes and misreadings.

Expand both factors in characters. A cross term $`\chi_S(x)\,\chi_T(y)`$ with $`S \ne T`$ averages to 0: some judge sits in only one of the two sets, and that lone vote is +1 or −1 with equal chance, whatever the other factors are. A matching term $`\chi_S(x)\,\chi_S(y)`$ is a product of $`\lvert S\rvert`$ independent factors $`x_i y_i`$, each +1 with chance 0.9 and −1 with chance 0.1, so it averages $`0.8^{\lvert S\rvert}`$. What survives is

```math
\text{chance of a flip} = \tfrac12 - \tfrac12 \sum_S 0.8^{\lvert S\rvert}\,\widehat{\mathrm{Maj}}(S)^2 = \tfrac12 - \tfrac12\,(0.75 \times 0.8 + 0.25 \times 0.512) = 0.136
```

**Read it aloud:** each set's weight counts towards keeping the verdict, discounted by 0.8 for every vote in the set, since each of those votes can be misread.

The same move, expand and let orthogonality remove the cross terms, gives the influence of a judge and the pass chance of the linearity test (fold).

<details>
<summary>Detailed proof: influence and the linearity test from the weights</summary>

**Influence.** Judge 1's influence is the chance that switching vote 1 alone changes the verdict. Half the change in the verdict when vote 1 goes from −1 to 1 is ±1 when judge 1 decides and 0 otherwise, so the influence is the average square of that half-change. In characters, the half-change keeps exactly the products that hold $`x_1`$, with $`x_1`$ struck out and the amounts unchanged. These are different characters, so Plancherel makes the influence the weight on the sets holding judge 1: 0.25 + 0.25 = 0.5.

**The linearity test.** It picks $`x`$ and $`y`$ at random and passes when $`\mathrm{Maj}(x)\,\mathrm{Maj}(y) = \mathrm{Maj}(xy)`$, where $`xy`$ multiplies the votes position by position. That happens when the product of the three values is 1, so the pass chance is ½ + ½ times the average of that product. Expand all three factors in characters and use $`\chi_S(xy) = \chi_S(x)\,\chi_S(y)`$. Averaging over $`x`$ and over $`y`$ separately, Step 3 removes every term except those with one set $`S`$ in all three places, which leave $`\widehat{\mathrm{Maj}}(S)^3`$:

$`\displaystyle \text{pass chance} = \tfrac12 + \tfrac12 \sum_S \widehat{\mathrm{Maj}}(S)^3 = \tfrac12 + \tfrac12\,(3 \times 0.125 - 0.125) = 0.625 .`$

</details>

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| verdicts, inputs (1,1,1) to (−1,−1,−1) | majority of three | 1, 1, 1, −1, 1, −1, −1, −1 |
| $`\widehat{\mathrm{Maj}}(\{1\})`$ | $`x_1`$ agrees with the verdict on 6 inputs, disagrees on 2: (6 − 2)/8 | **0.5** |
| $`\widehat{\mathrm{Maj}}(\{1,2\})`$ | 4 agreements, 4 disagreements | 0 |
| $`\widehat{\mathrm{Maj}}(\{1,2,3\})`$ | (1,1,1) gives +1; the three with one −1 give −3; the three with two −1 give −3; (−1,−1,−1) gives +1: −4/8 | **−0.5** |
| weights | $`W^1 = 3 \times 0.25`$, $`W^3 = 0.25`$ | **0.75 and 0.25** |
| Plancherel | 0.75 + 0.25 against the average of $`\mathrm{Maj}^2 = 1`$ | 1 = 1 |
| one judge's influence | the weights on the sets holding judge 1: 0.25 + 0.25 | 0.5 |
| verdict flips under 10% misreads | each matching pair $`\chi_S(x)\,\chi_S(y)`$ averages $`0.8^{\lvert S\rvert}`$ (Step 8): ½ − ½(0.75 × 0.8 + 0.25 × 0.512) | **0.136** |
| clock: $`\hat g(\chi_4)`$, window at hours 0, 1 | $`(1 + e^{-2\pi i/3})/12`$ | $`0.041667 - 0.072169i`$ |
| clock: $`\hat f(\chi_4)\,\hat g(\chi_4)`$ | 1/3 times that | $`0.013889 - 0.024056i`$ |

So with three judges each misread one time in ten, the verdict changes 13.6% of the time: worse than one judge alone at 10%. The cause is the quarter of the weight on the triple product: three votes enter it, so it has three chances to be misread where a single vote has one. The influence 0.5 means that in half of all vote patterns, one judge's vote decides the verdict.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| The shuffles of three things, $`S_3`$, not abelian | 2 characters for 6 members; they keep 0.333333 of one swap's energy | Too few characters to be a basis |
| Splitting 12 as 6 × 2 instead of 4 × 3 | highest character order 6, not 12 | 6 and 2 share a factor, so no character of the pair group matches $`\chi_1`$ |
| Majority's amounts added without squaring | 2.00, not 1 | Plancherel adds squares |
| Quarter marks: plain sums on both sides, DFT outputs | 4 against 48 | The 1/12 belongs on one side only |

The code prints all four.

---

## Code, from first principles, and it actually runs

The Python imports only `math`, for cos, sin, pi, gcd and prod; the Rust uses `std` alone. The scripts build every character, transform and convolution by hand. They reach each answer by at least two independent roads:

- characters checked as homomorphisms on all 144 pairs and matched to $`\mathbb{Z}/4 \times \mathbb{Z}/3`$ by search, against the rule $`j = 3a + 4b`$;
- the clock's transform by the direct sum and by the Chinese remainder split;
- Majority's amounts by averaging and by the butterflies;
- the noise, influence and linearity numbers by counting every case, against the formulas from the weights;
- the uncertainty bound against an exhaustive search over all sets of hours and of inputs.

### Python

```python
# Fourier analysis on a finite abelian group -- the check behind the card.
# Standard library only: math gives cos, sin, pi, gcd and prod.  Every
# character, transform, convolution and count is written out here.  Two
# groups: the 12-hour clock Z/12, and three votes in {-1, 1}^3.
import math

def cis(t):                                   # the point at angle t on the unit circle
    return complex(math.cos(t), math.sin(t))

def fmt(z):                                   # a+bi, 6 decimals, rounding dust dropped
    re = 0.0 if abs(z.real) < 1e-9 else z.real
    im = 0.0 if abs(z.imag) < 1e-9 else z.imag
    return f"{re:.6f}{'+' if im >= 0 else '-'}{abs(im):.6f}i"

close = lambda a, b: abs(a - b) < 1e-9
yn = lambda claim: "yes" if claim else "no"
fl = lambda v: "[" + ", ".join(f"{x:.2f}" for x in v) + "]"  # a list of reals, 2 decimals

N = 12
chars = [[cis(2 * math.pi * j * k / N) for k in range(N)] for j in range(N)]
hom = all(close(c[(a + b) % N], c[a] * c[b]) for c in chars for a in range(N) for b in range(N))
gram = all(close(sum(chars[j][k] * chars[l][k].conjugate() for k in range(N)) / N, j == l)
           for j in range(N) for l in range(N))
order = [next(m for m in range(1, N + 1) if close(chars[j][1] ** m, 1)) for j in range(N)]
print(f"Z/12: 12 characters, each turns sums into products on all 144 pairs: {yn(hom)}")
print(f"the 144 averages <chi_j, chi_l> are 1 when j = l and 0 otherwise: {yn(gram)}")
print(f"orders of chi_0..chi_11: {order}; of order 12: {order.count(12)}, so {order.count(12)} ways to match Z/12 with its dual")
assert hom and gram and order.count(12) == sum(1 for j in range(N) if math.gcd(j, N) == 1)

pairs = [(k % 4, k % 3) for k in range(N)]                       # Chinese remainder split
back = {p: k for k, p in enumerate(pairs)}
match = {}
for j in range(N):                                               # search for (a, b) per character
    for a in range(4):
        for b in range(3):
            if all(close(chars[j][k], cis(2 * math.pi * a * (k % 4) / 4) * cis(2 * math.pi * b * (k % 3) / 3)) for k in range(N)):
                match[j] = (a, b)
print(f"k -> (k mod 4, k mod 3) hits all 12 pairs: {yn(len(back) == 12)}; back again: k = (9 k1 + 4 k2) mod 12: {yn(all(back[(x, y)] == (9 * x + 4 * y) % N for x, y in pairs))}")
print("character j as (a on Z/4, b on Z/3): " + ", ".join(f"{j}:({a},{b})" for j, (a, b) in sorted(match.items())))
print(f"j = (3a + 4b) mod 12 for all twelve: {yn(all((3 * a + 4 * b) % N == j for j, (a, b) in match.items()))}")
assert len(match) == 12 and all((3 * a + 4 * b) % N == j for j, (a, b) in match.items())

count = [0, 0]                                # products used: direct sum, Chinese remainder split

def hat(f):                                   # f^(j) = (1/12) sum_k f(k) conj chi_j(k)
    count[0] += N * N
    return [sum(f[k] * chars[j][k].conjugate() for k in range(N)) / N for j in range(N)]

def hat_crt(f):                               # the same through Z/4 x Z/3, 3 then 4 at a time
    count[1] += 4 * 3 * 3 + 4 * 3 * 4
    inner = {(k1, b): sum(f[back[(k1, k2)]] * cis(-2 * math.pi * b * k2 / 3) for k2 in range(3))
             for k1 in range(4) for b in range(3)}
    out = [0] * N
    for a in range(4):
        for b in range(3):
            out[(3 * a + 4 * b) % N] = sum(inner[(k1, b)] * cis(-2 * math.pi * a * k1 / 4) for k1 in range(4)) / N
    return out

f = [1 if k % 3 == 0 else 0 for k in range(N)]                   # the quarter marks 0, 3, 6, 9
g = [1 if k in (0, 1) else 0 for k in range(N)]                  # a two-hour window
fh, gh = hat(f), hat(g)
supp = lambda v: sum(1 for z in v if abs(z) > 1e-9)
print(f"f = quarter marks: f^ nonzero at j = {[j for j in range(N) if abs(fh[j]) > 1e-9]}, each {fmt(fh[0])}")
print(f"g = window 0, 1: g^(1) = {fmt(gh[1])}, g^(4) = {fmt(gh[4])}, g^(6) = {fmt(gh[6])}")
crt_ok = all(close(x, y) for x, y in zip(hat_crt(f) + hat_crt(g), fh + gh))
print(f"transform through Z/4 x Z/3 equals the direct sum: {yn(crt_ok)}; products {count[1] // 2} against {count[0] // 2}")
inv_ok = all(close(sum(h[j] * chars[j][k] for j in range(N)), v[k]) for v, h in ((f, fh), (g, gh)) for k in range(N))
print(f"sum of f^(j) chi_j rebuilds f and g at all 12 hours: {yn(inv_ok)}")
for name, v, h in (("f", f, fh), ("g", g, gh)):
    print(f"Plancherel for {name}: mean |{name}|^2 = {sum(abs(x) ** 2 for x in v) / N:.6f}, sum |{name}^|^2 = {sum(abs(z) ** 2 for z in h):.6f}")
conv = [sum(f[y] * g[(x - y) % N] for y in range(N)) / N for x in range(N)]
ch = hat(conv)
print(f"(f*g)(x) times 12, x = 0..11: {[round(12 * c) for c in conv]}")
print(f"(f*g)^(4) = {fmt(ch[4])}; f^(4) g^(4) = {fmt(fh[4] * gh[4])}; all 12 agree: {yn(all(close(ch[j], fh[j] * gh[j]) for j in range(N)))}")
assert crt_ok and inv_ok and all(close(ch[j], fh[j] * gh[j]) for j in range(N))
delta = [1 if k == 0 else 0 for k in range(N)]
print(f"support sizes: f {supp(f)} x {supp(fh)} = {supp(f) * supp(fh)}; g {supp(g)} x {supp(gh)} = {supp(g) * supp(gh)}; one hour {supp(delta)} x {supp(hat(delta))} = {supp(hat(delta))}")
prods = {s: bin(s).count("1") * supp(hat([(s >> k) & 1 for k in range(N)])) for s in range(1, 2 ** N)}
best = min(prods.values())
reach = {s for s, p in prods.items() if p == best}
cosets = {sum(1 << ((c + h * d) % N) for h in range(N // d)) for d in range(1, N + 1) if N % d == 0 for c in range(N)}
print(f"all 4095 nonempty sets of hours: smallest product {best}, reached by {len(reach)} sets; cosets of the 6 subgroups: {len(cosets)}, the same sets: {yn(reach == cosets)}")
assert best == N and reach == cosets

n = 3
xs = [tuple(1 - 2 * ((b >> (n - 1 - i)) & 1) for i in range(n)) for b in range(2 ** n)]
maj = [1 if sum(x) > 0 else -1 for x in xs]
chiS = lambda S, x: math.prod(x[i] for i in range(n) if (S >> (n - 1 - i)) & 1)
brute = [sum(maj[t] * chiS(S, xs[t]) for t in range(8)) / 8 for S in range(8)]
v, h, ops = maj[:], 1, 0                                         # fast Walsh-Hadamard butterflies
while h < 8:
    for i in range(0, 8, 2 * h):
        for j in range(i, i + h):
            v[j], v[j + h], ops = v[j] + v[j + h], v[j] - v[j + h], ops + 2
    h *= 2
fast = [x / 8 for x in v]
name = lambda S: "".join(f"x{i + 1}" for i in range(n) if (S >> (n - 1 - i)) & 1)
print(f"Maj on the 8 inputs from (1,1,1) to (-1,-1,-1): {maj}")
print(f"coefficients by averaging equal the butterflies: {yn(brute == fast)}; operations {ops} against {8 * 8}")
terms = sorted((bin(S).count("1"), name(S), c) for S, c in enumerate(brute) if c != 0)
print("Maj = " + " ".join(f"{'+' if c > 0 else '-'} {abs(c):.1f} {nm}" for _, nm, c in terms).lstrip("+ "))
print(f"sum of Maj^(S) chi_S rebuilds Maj on all 8 inputs: {yn(all(sum(brute[S] * chiS(S, x) for S in range(8)) == m for x, m in zip(xs, maj)))}")
deg = [sum(brute[S] ** 2 for S in range(8) if bin(S).count("1") == d) for d in range(n + 1)]
print(f"Fourier weight at degree 0..3: {fl(deg)}; total {sum(deg):.2f}; mean Maj^2 {sum(m * m for m in maj) / 8:.2f}")
flip = lambda x, i: tuple(-c if k == i else c for k, c in enumerate(x))
infl = [sum(1 for t, x in enumerate(xs) if maj[xs.index(flip(x, i))] != maj[t]) / 8 for i in range(n)]
infl_w = [sum(brute[S] ** 2 for S in range(8) if (S >> (n - 1 - i)) & 1) for i in range(n)]
print(f"influence of each voter: by flipping {fl(infl)}; from weights {fl(infl_w)}")
p = 0.1
noisy = sum((p ** sum(e)) * ((1 - p) ** (n - sum(e))) / 8 * (maj[t] != maj[xs.index(tuple(c * (1 - 2 * s) for c, s in zip(x, e)))])
            for t, x in enumerate(xs) for e in [((b >> 2) & 1, (b >> 1) & 1, b & 1) for b in range(8)])
stab = 0.5 - 0.5 * sum((1 - 2 * p) ** bin(S).count("1") * brute[S] ** 2 for S in range(8))
print(f"each vote misread with chance {p}: winner changes, counted {noisy:.6f}, from weights {stab:.6f}; one voter alone {p:.6f}")
mul = lambda x, y: tuple(a * b for a, b in zip(x, y))
blr = sum(1 for x in xs for y in xs if maj[xs.index(x)] * maj[xs.index(y)] == maj[xs.index(mul(x, y))]) / 64
print(f"linearity test f(x)f(y) = f(xy) passes: counted {blr:.6f}, from weights {0.5 + 0.5 * sum(c ** 3 for c in brute):.6f}")
cube = min(bin(s).count("1") * sum(1 for S in range(8) if sum(((s >> t) & 1) * chiS(S, xs[t]) for t in range(8)) != 0) for s in range(1, 256))
print(f"uncertainty on the cube: Maj {len(maj)} x {sum(1 for c in brute if c)} = {8 * sum(1 for c in brute if c)}; smallest over 255 sets of inputs: {cube}")
assert brute == fast and deg == [0, 0.75, 0, 0.25] and infl == [0.5] * 3 == infl_w and cube == 8
assert close(noisy, stab) and close(blr, 0.5 + 0.5 * sum(c ** 3 for c in brute))

S3 = [(0, 1, 2), (1, 0, 2), (0, 2, 1), (2, 1, 0), (1, 2, 0), (2, 0, 1)]  # shuffles of 3 things
comp, homs = lambda p, q: tuple(p[q[i]] for i in range(3)), []
for c in range(6 ** 6):                                          # every map to sixth roots of 1
    e = [(c // 6 ** i) % 6 for i in range(6)]
    if all(e[S3.index(comp(a, b))] == (e[S3.index(a)] + e[S3.index(b)]) % 6 for a in S3 for b in S3):
        homs.append(e)
swap = [1 if s == (1, 0, 2) else 0 for s in S3]
kept = sum(abs(sum(swap[t] * cis(-2 * math.pi * e[t] / 6) for t in range(6)) / 6) ** 2 for e in homs)
print(f"break 1, S3 is not abelian: {len(homs)} characters for 6 members; they keep {kept / (1 / 6):.6f} of a swap's energy")
o62 = max(next(m for m in range(1, 13) if all(close(cis(2 * math.pi * m * (a * x / 6 + b * y / 2)), 1) for x in range(6) for y in range(2)))
          for a in range(6) for b in range(2))
print(f"break 2, Z/6 x Z/2 (6 and 2 share a factor): highest character order {o62}, not 12")
print(f"break 3, Maj coefficients added unsquared: {sum(abs(c) for c in brute):.2f}, not 1")
print(f"break 4, sums on both sides for f: sum |f|^2 = {sum(f)}, sum |12 f^|^2 = {sum(abs(12 * z) ** 2 for z in fh):.6f}")
assert len(homs) == 2 and close(kept * 6, 1 / 3) and o62 == 6
print("ALL CHECKS PASS")
```

**Ran 2026-11-24 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
Z/12: 12 characters, each turns sums into products on all 144 pairs: yes
the 144 averages <chi_j, chi_l> are 1 when j = l and 0 otherwise: yes
orders of chi_0..chi_11: [1, 12, 6, 4, 3, 12, 2, 12, 3, 4, 6, 12]; of order 12: 4, so 4 ways to match Z/12 with its dual
k -> (k mod 4, k mod 3) hits all 12 pairs: yes; back again: k = (9 k1 + 4 k2) mod 12: yes
character j as (a on Z/4, b on Z/3): 0:(0,0), 1:(3,1), 2:(2,2), 3:(1,0), 4:(0,1), 5:(3,2), 6:(2,0), 7:(1,1), 8:(0,2), 9:(3,0), 10:(2,1), 11:(1,2)
j = (3a + 4b) mod 12 for all twelve: yes
f = quarter marks: f^ nonzero at j = [0, 4, 8], each 0.333333+0.000000i
g = window 0, 1: g^(1) = 0.155502-0.041667i, g^(4) = 0.041667-0.072169i, g^(6) = 0.000000+0.000000i
transform through Z/4 x Z/3 equals the direct sum: yes; products 84 against 144
sum of f^(j) chi_j rebuilds f and g at all 12 hours: yes
Plancherel for f: mean |f|^2 = 0.333333, sum |f^|^2 = 0.333333
Plancherel for g: mean |g|^2 = 0.166667, sum |g^|^2 = 0.166667
(f*g)(x) times 12, x = 0..11: [1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0]
(f*g)^(4) = 0.013889-0.024056i; f^(4) g^(4) = 0.013889-0.024056i; all 12 agree: yes
support sizes: f 4 x 3 = 12; g 2 x 11 = 22; one hour 1 x 12 = 12
all 4095 nonempty sets of hours: smallest product 12, reached by 28 sets; cosets of the 6 subgroups: 28, the same sets: yes
Maj on the 8 inputs from (1,1,1) to (-1,-1,-1): [1, 1, 1, -1, 1, -1, -1, -1]
coefficients by averaging equal the butterflies: yes; operations 24 against 64
Maj = 0.5 x1 + 0.5 x2 + 0.5 x3 - 0.5 x1x2x3
sum of Maj^(S) chi_S rebuilds Maj on all 8 inputs: yes
Fourier weight at degree 0..3: [0.00, 0.75, 0.00, 0.25]; total 1.00; mean Maj^2 1.00
influence of each voter: by flipping [0.50, 0.50, 0.50]; from weights [0.50, 0.50, 0.50]
each vote misread with chance 0.1: winner changes, counted 0.136000, from weights 0.136000; one voter alone 0.100000
linearity test f(x)f(y) = f(xy) passes: counted 0.625000, from weights 0.625000
uncertainty on the cube: Maj 8 x 4 = 32; smallest over 255 sets of inputs: 8
break 1, S3 is not abelian: 2 characters for 6 members; they keep 0.333333 of a swap's energy
break 2, Z/6 x Z/2 (6 and 2 share a factor): highest character order 6, not 12
break 3, Maj coefficients added unsquared: 2.00, not 1
break 4, sums on both sides for f: sum |f|^2 = 4, sum |12 f^|^2 = 48.000000
ALL CHECKS PASS
```

### Rust

Same numbers and labels, built with `rustc --edition 2021 -O`.

```rust
// Fourier analysis on a finite abelian group -- the same check as the Python,
// in Rust.  No crates.  A complex number is a small struct; every character,
// transform, convolution and count is written out here.  Two groups: the
// 12-hour clock Z/12, and three votes in {-1, 1}^3.
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}
const ZERO: C = C { re: 0.0, im: 0.0 };
const N: usize = 12;
fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } }            // the point at angle t on the unit circle
fn re(x: f64) -> C { C { re: x, im: 0.0 } }
fn close(a: C, b: C) -> bool { a.sub(b).abs() < 1e-9 }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn fmt(z: C) -> String {                                          // a+bi, 6 decimals, rounding dust dropped
    let r = if z.re.abs() < 1e-9 { 0.0 } else { z.re };
    let i = if z.im.abs() < 1e-9 { 0.0 } else { z.im };
    format!("{:.6}{}{:.6}i", r, if i >= 0.0 { "+" } else { "-" }, i.abs())
}
fn fl(v: &[f64]) -> String { format!("[{}]", v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ")) }
fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn ones(s: usize) -> usize { s.count_ones() as usize }

fn hat(f: &[C], ch: &[Vec<C>], count: &mut usize) -> Vec<C> {    // f^(j) = (1/12) sum_k f(k) conj chi_j(k)
    *count += N * N;
    (0..N).map(|j| (0..N).fold(ZERO, |s, k| s.add(f[k].mul(ch[j][k].conj()))).scale(1.0 / N as f64)).collect()
}
fn hat_crt(f: &[C], back: &BTreeMap<(usize, usize), usize>, count: &mut usize) -> Vec<C> {
    *count += 4 * 3 * 3 + 4 * 3 * 4;                              // through Z/4 x Z/3, 3 then 4 at a time
    let mut inner = BTreeMap::new();
    for k1 in 0..4 { for b in 0..3 {
        inner.insert((k1, b), (0..3).fold(ZERO, |s, k2| s.add(f[back[&(k1, k2)]].mul(cis(-2.0 * PI * (b * k2) as f64 / 3.0)))));
    } }
    let mut out = vec![ZERO; N];
    for a in 0..4 { for b in 0..3 {
        out[(3 * a + 4 * b) % N] = (0..4).fold(ZERO, |s, k1| s.add(inner[&(k1, b)].mul(cis(-2.0 * PI * (a * k1) as f64 / 4.0)))).scale(1.0 / N as f64);
    } }
    out
}
fn supp(v: &[C]) -> usize { v.iter().filter(|z| z.abs() > 1e-9).count() }
fn main() {
    let ch: Vec<Vec<C>> = (0..N).map(|j| (0..N).map(|k| cis(2.0 * PI * (j * k) as f64 / N as f64)).collect()).collect();
    let hom = ch.iter().all(|c| (0..N).all(|a| (0..N).all(|b| close(c[(a + b) % N], c[a].mul(c[b])))));
    let gram = (0..N).all(|j| (0..N).all(|l| close((0..N).fold(ZERO, |s, k| s.add(ch[j][k].mul(ch[l][k].conj()))).scale(1.0 / N as f64), re(if j == l { 1.0 } else { 0.0 }))));
    let order: Vec<usize> = (0..N).map(|j| (1..=N).find(|&m| { let mut p = re(1.0); for _ in 0..m { p = p.mul(ch[j][1]) } close(p, re(1.0)) }).unwrap()).collect();
    let o12 = order.iter().filter(|&&o| o == 12).count();
    println!("Z/12: 12 characters, each turns sums into products on all 144 pairs: {}", yn(hom));
    println!("the 144 averages <chi_j, chi_l> are 1 when j = l and 0 otherwise: {}", yn(gram));
    println!("orders of chi_0..chi_11: {:?}; of order 12: {}, so {} ways to match Z/12 with its dual", order, o12, o12);
    assert!(hom && gram && o12 == (0..N).filter(|&j| gcd(j, N) == 1).count());

    let pairs: Vec<(usize, usize)> = (0..N).map(|k| (k % 4, k % 3)).collect();          // Chinese remainder split
    let back: BTreeMap<(usize, usize), usize> = pairs.iter().enumerate().map(|(k, &p)| (p, k)).collect();
    let mut mat: BTreeMap<usize, (usize, usize)> = BTreeMap::new();
    for j in 0..N { for a in 0..4 { for b in 0..3 {                                     // search for (a, b) per character
        if (0..N).all(|k| close(ch[j][k], cis(2.0 * PI * (a * (k % 4)) as f64 / 4.0).mul(cis(2.0 * PI * (b * (k % 3)) as f64 / 3.0)))) { mat.insert(j, (a, b)); }
    } } }
    println!("k -> (k mod 4, k mod 3) hits all 12 pairs: {}; back again: k = (9 k1 + 4 k2) mod 12: {}", yn(back.len() == 12), yn(pairs.iter().all(|&(x, y)| back[&(x, y)] == (9 * x + 4 * y) % N)));
    println!("character j as (a on Z/4, b on Z/3): {}", mat.iter().map(|(j, (a, b))| format!("{}:({},{})", j, a, b)).collect::<Vec<_>>().join(", "));
    let crt_rule = mat.iter().all(|(&j, &(a, b))| (3 * a + 4 * b) % N == j);
    println!("j = (3a + 4b) mod 12 for all twelve: {}", yn(crt_rule));
    assert!(mat.len() == 12 && crt_rule);

    let f: Vec<C> = (0..N).map(|k| re(if k % 3 == 0 { 1.0 } else { 0.0 })).collect();   // the quarter marks
    let g: Vec<C> = (0..N).map(|k| re(if k < 2 { 1.0 } else { 0.0 })).collect();        // a two-hour window
    let mut count = [0usize, 0usize];
    let (fh, gh) = (hat(&f, &ch, &mut count[0]), hat(&g, &ch, &mut count[0]));
    let nz: Vec<usize> = (0..N).filter(|&j| fh[j].abs() > 1e-9).collect();
    println!("f = quarter marks: f^ nonzero at j = {:?}, each {}", nz, fmt(fh[0]));
    println!("g = window 0, 1: g^(1) = {}, g^(4) = {}, g^(6) = {}", fmt(gh[1]), fmt(gh[4]), fmt(gh[6]));
    let (cf, cg) = (hat_crt(&f, &back, &mut count[1]), hat_crt(&g, &back, &mut count[1]));
    let crt_ok = (0..N).all(|j| close(cf[j], fh[j]) && close(cg[j], gh[j]));
    println!("transform through Z/4 x Z/3 equals the direct sum: {}; products {} against {}", yn(crt_ok), count[1] / 2, count[0] / 2);
    let inv_ok = [(&f, &fh), (&g, &gh)].iter().all(|(v, h)| (0..N).all(|k| close((0..N).fold(ZERO, |s, j| s.add(h[j].mul(ch[j][k]))), v[k])));
    println!("sum of f^(j) chi_j rebuilds f and g at all 12 hours: {}", yn(inv_ok));
    for (name, v, h) in [("f", &f, &fh), ("g", &g, &gh)] { println!("Plancherel for {}: mean |{}|^2 = {:.6}, sum |{}^|^2 = {:.6}", name, name,
        v.iter().map(|x| x.abs().powi(2)).sum::<f64>() / N as f64, name, h.iter().map(|z| z.abs().powi(2)).sum::<f64>()) }
    let conv: Vec<C> = (0..N).map(|x| (0..N).fold(ZERO, |s, y| s.add(f[y].mul(g[(x + N - y) % N]))).scale(1.0 / N as f64)).collect();
    let chh = hat(&conv, &ch, &mut count[0]);
    let conv_ok = (0..N).all(|j| close(chh[j], fh[j].mul(gh[j])));
    println!("(f*g)(x) times 12, x = 0..11: {:?}", conv.iter().map(|c| (12.0 * c.re).round() as i64).collect::<Vec<_>>());
    println!("(f*g)^(4) = {}; f^(4) g^(4) = {}; all 12 agree: {}", fmt(chh[4]), fmt(fh[4].mul(gh[4])), yn(conv_ok));
    assert!(crt_ok && inv_ok && conv_ok);
    let delta: Vec<C> = (0..N).map(|k| re(if k == 0 { 1.0 } else { 0.0 })).collect();   // one hour
    let dh = supp(&hat(&delta, &ch, &mut count[0]));
    println!("support sizes: f {} x {} = {}; g {} x {} = {}; one hour {} x {} = {}", supp(&f), supp(&fh), supp(&f) * supp(&fh),
             supp(&g), supp(&gh), supp(&g) * supp(&gh), supp(&delta), dh, dh);
    let prods: Vec<(usize, usize)> = (1..1usize << N).map(|s| {
        let v: Vec<C> = (0..N).map(|k| re(((s >> k) & 1) as f64)).collect();
        (s, ones(s) * supp(&hat(&v, &ch, &mut count[0])))
    }).collect();
    let best = prods.iter().map(|p| p.1).min().unwrap();
    let reach: BTreeSet<usize> = prods.iter().filter(|p| p.1 == best).map(|p| p.0).collect();
    let mut cosets = BTreeSet::new();
    for d in (1..=N).filter(|d| N % d == 0) { for c in 0..N { cosets.insert((0..N / d).map(|h| 1usize << ((c + h * d) % N)).sum::<usize>()); } }
    println!("all 4095 nonempty sets of hours: smallest product {}, reached by {} sets; cosets of the 6 subgroups: {}, the same sets: {}",
             best, reach.len(), cosets.len(), yn(reach == cosets));
    assert!(best == N && reach == cosets);

    let n = 3;
    let xs: Vec<Vec<i64>> = (0..8).map(|b| (0..n).map(|i| 1 - 2 * ((b >> (n - 1 - i)) & 1) as i64).collect()).collect();
    let maj: Vec<i64> = xs.iter().map(|x| if x.iter().sum::<i64>() > 0 { 1 } else { -1 }).collect();
    let chi_s = |s: usize, x: &Vec<i64>| -> i64 { (0..n).filter(|i| (s >> (n - 1 - i)) & 1 == 1).map(|i| x[i]).product() };
    let idx = |x: &Vec<i64>| xs.iter().position(|y| y == x).unwrap();
    let brute: Vec<f64> = (0..8).map(|s| (0..8).map(|t| maj[t] * chi_s(s, &xs[t])).sum::<i64>() as f64 / 8.0).collect();
    let (mut v, mut h, mut ops) = (maj.clone(), 1, 0);                                   // fast Walsh-Hadamard butterflies
    while h < 8 {
        for i in (0..8).step_by(2 * h) { for j in i..i + h { let (a, b) = (v[j], v[j + h]); v[j] = a + b; v[j + h] = a - b; ops += 2; } } h *= 2;
    }
    let fast: Vec<f64> = v.iter().map(|&x| x as f64 / 8.0).collect();
    let name = |s: usize| (0..n).filter(|i| (s >> (n - 1 - i)) & 1 == 1).map(|i| format!("x{}", i + 1)).collect::<String>();
    println!("Maj on the 8 inputs from (1,1,1) to (-1,-1,-1): {:?}", maj);
    println!("coefficients by averaging equal the butterflies: {}; operations {} against {}", yn(brute == fast), ops, 8 * 8);
    let mut terms: Vec<(usize, String, f64)> = (0..8).filter(|&s| brute[s] != 0.0).map(|s| (ones(s), name(s), brute[s])).collect();
    terms.sort_by(|a, b| (a.0, &a.1).cmp(&(b.0, &b.1)));
    let line = terms.iter().map(|(_, nm, c)| format!("{} {:.1} {}", if *c > 0.0 { "+" } else { "-" }, c.abs(), nm)).collect::<Vec<_>>().join(" ");
    println!("Maj = {}", line.trim_start_matches(|c| c == '+' || c == ' '));
    let rebuild = xs.iter().zip(&maj).all(|(x, &m)| (0..8).map(|s| brute[s] * chi_s(s, x) as f64).sum::<f64>() == m as f64);
    println!("sum of Maj^(S) chi_S rebuilds Maj on all 8 inputs: {}", yn(rebuild));
    let deg: Vec<f64> = (0..=n).map(|d| (0..8).filter(|&s| ones(s) == d).map(|s| brute[s].powi(2)).sum()).collect();
    println!("Fourier weight at degree 0..3: {}; total {:.2}; mean Maj^2 {:.2}", fl(&deg), deg.iter().sum::<f64>(), maj.iter().map(|m| m * m).sum::<i64>() as f64 / 8.0);
    let infl: Vec<f64> = (0..n).map(|i| (0..8).filter(|&t| { let mut y = xs[t].clone(); y[i] = -y[i]; maj[idx(&y)] != maj[t] }).count() as f64 / 8.0).collect();
    let infl_w: Vec<f64> = (0..n).map(|i| (0..8).filter(|&s| (s >> (n - 1 - i)) & 1 == 1).map(|s| brute[s].powi(2)).sum()).collect();
    println!("influence of each voter: by flipping {}; from weights {}", fl(&infl), fl(&infl_w));
    let (p, mut noisy) = (0.1f64, 0.0);
    for t in 0..8 { for b in 0..8usize {
        let (e, k) = ([(b >> 2) & 1, (b >> 1) & 1, b & 1], b.count_ones() as i32);
        let y: Vec<i64> = (0..n).map(|i| xs[t][i] * (1 - 2 * e[i] as i64)).collect();
        noisy += p.powi(k) * (1.0 - p).powi(n as i32 - k) / 8.0 * if maj[t] != maj[idx(&y)] { 1.0 } else { 0.0 };
    } }
    let stab = 0.5 - 0.5 * (0..8).map(|s| (1.0 - 2.0 * p).powi(ones(s) as i32) * brute[s].powi(2)).sum::<f64>();
    println!("each vote misread with chance {}: winner changes, counted {:.6}, from weights {:.6}; one voter alone {:.6}", p, noisy, stab, p);
    let mut pass = 0;
    for x in &xs { for y in &xs { let xy: Vec<i64> = (0..n).map(|i| x[i] * y[i]).collect(); if maj[idx(x)] * maj[idx(y)] == maj[idx(&xy)] { pass += 1 } } }
    let (blr, blr_w) = (pass as f64 / 64.0, 0.5 + 0.5 * brute.iter().map(|c| c.powi(3)).sum::<f64>());
    println!("linearity test f(x)f(y) = f(xy) passes: counted {:.6}, from weights {:.6}", blr, blr_w);
    let cube = (1..256usize).map(|s| ones(s) * (0..8).filter(|&q| (0..8).map(|t| ((s >> t) & 1) as i64 * chi_s(q, &xs[t])).sum::<i64>() != 0).count()).min().unwrap();
    let nzm = brute.iter().filter(|&&c| c != 0.0).count();
    println!("uncertainty on the cube: Maj {} x {} = {}; smallest over 255 sets of inputs: {}", maj.len(), nzm, 8 * nzm, cube);
    assert!(brute == fast && deg == vec![0.0, 0.75, 0.0, 0.25] && infl == vec![0.5; 3] && infl == infl_w && cube == 8);
    assert!((noisy - stab).abs() < 1e-9 && (blr - blr_w).abs() < 1e-9);

    let s3: [[usize; 3]; 6] = [[0, 1, 2], [1, 0, 2], [0, 2, 1], [2, 1, 0], [1, 2, 0], [2, 0, 1]];   // shuffles of 3 things
    let (pos, mut homs) = (|p: [usize; 3]| s3.iter().position(|q| *q == p).unwrap(), Vec::new());
    for c in 0..6usize.pow(6) {                                                         // every map to sixth roots of 1
        let e: Vec<usize> = (0..6).map(|i| (c / 6usize.pow(i)) % 6).collect();
        if s3.iter().all(|a| s3.iter().all(|b| e[pos([a[b[0]], a[b[1]], a[b[2]]])] == (e[pos(*a)] + e[pos(*b)]) % 6)) { homs.push(e) }
    }
    let swap: Vec<f64> = s3.iter().map(|s| if *s == [1, 0, 2] { 1.0 } else { 0.0 }).collect();   // one swap
    let kept: f64 = homs.iter().map(|e| (0..6).fold(ZERO, |s, t| s.add(cis(-2.0 * PI * e[t] as f64 / 6.0).scale(swap[t]))).scale(1.0 / 6.0).abs().powi(2)).sum();
    println!("break 1, S3 is not abelian: {} characters for 6 members; they keep {:.6} of a swap's energy", homs.len(), kept / (1.0 / 6.0));
    let o62 = (0..6).flat_map(|a| (0..2).map(move |b| (a, b))).map(|(a, b)| (1..13).find(|&m| (0..6).all(|x| (0..2).all(|y|
        close(cis(2.0 * PI * m as f64 * ((a * x) as f64 / 6.0 + (b * y) as f64 / 2.0)), re(1.0))))).unwrap()).max().unwrap();
    println!("break 2, Z/6 x Z/2 (6 and 2 share a factor): highest character order {}, not 12", o62);
    println!("break 3, Maj coefficients added unsquared: {:.2}, not 1", brute.iter().map(|c| c.abs()).sum::<f64>());
    println!("break 4, sums on both sides for f: sum |f|^2 = {}, sum |12 f^|^2 = {:.6}", f.iter().map(|z| z.re).sum::<f64>() as i64,
             fh.iter().map(|z| z.scale(12.0).abs().powi(2)).sum::<f64>());
    assert!(homs.len() == 2 && (kept * 6.0 - 1.0 / 3.0).abs() < 1e-9 && o62 == 6);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
Z/12: 12 characters, each turns sums into products on all 144 pairs: yes
the 144 averages <chi_j, chi_l> are 1 when j = l and 0 otherwise: yes
orders of chi_0..chi_11: [1, 12, 6, 4, 3, 12, 2, 12, 3, 4, 6, 12]; of order 12: 4, so 4 ways to match Z/12 with its dual
k -> (k mod 4, k mod 3) hits all 12 pairs: yes; back again: k = (9 k1 + 4 k2) mod 12: yes
character j as (a on Z/4, b on Z/3): 0:(0,0), 1:(3,1), 2:(2,2), 3:(1,0), 4:(0,1), 5:(3,2), 6:(2,0), 7:(1,1), 8:(0,2), 9:(3,0), 10:(2,1), 11:(1,2)
j = (3a + 4b) mod 12 for all twelve: yes
f = quarter marks: f^ nonzero at j = [0, 4, 8], each 0.333333+0.000000i
g = window 0, 1: g^(1) = 0.155502-0.041667i, g^(4) = 0.041667-0.072169i, g^(6) = 0.000000+0.000000i
transform through Z/4 x Z/3 equals the direct sum: yes; products 84 against 144
sum of f^(j) chi_j rebuilds f and g at all 12 hours: yes
Plancherel for f: mean |f|^2 = 0.333333, sum |f^|^2 = 0.333333
Plancherel for g: mean |g|^2 = 0.166667, sum |g^|^2 = 0.166667
(f*g)(x) times 12, x = 0..11: [1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0]
(f*g)^(4) = 0.013889-0.024056i; f^(4) g^(4) = 0.013889-0.024056i; all 12 agree: yes
support sizes: f 4 x 3 = 12; g 2 x 11 = 22; one hour 1 x 12 = 12
all 4095 nonempty sets of hours: smallest product 12, reached by 28 sets; cosets of the 6 subgroups: 28, the same sets: yes
Maj on the 8 inputs from (1,1,1) to (-1,-1,-1): [1, 1, 1, -1, 1, -1, -1, -1]
coefficients by averaging equal the butterflies: yes; operations 24 against 64
Maj = 0.5 x1 + 0.5 x2 + 0.5 x3 - 0.5 x1x2x3
sum of Maj^(S) chi_S rebuilds Maj on all 8 inputs: yes
Fourier weight at degree 0..3: [0.00, 0.75, 0.00, 0.25]; total 1.00; mean Maj^2 1.00
influence of each voter: by flipping [0.50, 0.50, 0.50]; from weights [0.50, 0.50, 0.50]
each vote misread with chance 0.1: winner changes, counted 0.136000, from weights 0.136000; one voter alone 0.100000
linearity test f(x)f(y) = f(xy) passes: counted 0.625000, from weights 0.625000
uncertainty on the cube: Maj 8 x 4 = 32; smallest over 255 sets of inputs: 8
break 1, S3 is not abelian: 2 characters for 6 members; they keep 0.333333 of a swap's energy
break 2, Z/6 x Z/2 (6 and 2 share a factor): highest character order 6, not 12
break 3, Maj coefficients added unsquared: 2.00, not 1
break 4, sums on both sides for f: sum |f|^2 = 4, sum |12 f^|^2 = 48.000000
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's main facts for every finite abelian group, and checks the worked numbers on the votes and the clock.

- Every character takes values of size 1.
- A finite abelian group has exactly as many characters as members. Its dual group matches it, through a match that needs a choice.
- Take characters $`\chi`$ and $`\psi`$ of $`G`$. Then $`\langle \chi, \psi\rangle`$ is 1 when they are equal and 0 otherwise.
- Take a complex function $`f`$ on $`G`$. Then $`f = \sum_{\chi} \hat f(\chi)\,\chi`$, summed over all characters.
- Plancherel holds for every complex function on $`G`$: its average energy equals the summed energy of its amounts.
- Take complex functions $`f`$ and $`g`$ on $`G`$, and a character $`\chi`$. Then $`\widehat{f * g}(\chi) = \hat f(\chi)\,\hat g(\chi)`$.
- Take a nonzero function $`f`$ on $`G`$. Then $`\lvert\mathrm{supp}\, f\rvert \cdot \lvert\mathrm{supp}\, \hat f\rvert \ge \lvert G\rvert`$.
- Take any of the 8 vote patterns. Then $`\mathrm{Maj}`$ equals $`\tfrac12 x_1 + \tfrac12 x_2 + \tfrac12 x_3 - \tfrac12 x_1 x_2 x_3`$ there.
- Averaging gives Majority's amounts: 0.5 on judge 1, 0 on judges 1 and 2, −0.5 on the triple, and 0 on no judge.
- The weights 0.75 and 0.25 add to 1, the average of the squared verdict.
- Switching vote 1 alone changes the verdict on 4 of the 8 inputs, an influence of 0.5.
- With each vote misread with chance 10%, counting every case gives a flip chance of 0.136. The formula from the weights gives the same.
- The linearity test passes on 40 of the 64 pairs, which is 0.625. The formula from the weights gives the same.
- Take an hour $`k`$, with $`k_1 = k \bmod 4`$ and $`k_2 = k \bmod 3`$. Then $`k = (9k_1 + 4k_2) \bmod 12`$.
- Take $`a < 4`$ and $`b < 3`$. Then the labels $`j = (3a + 4b) \bmod 12`$ hit all 12 characters.
- Exactly four labels $`j`$ share no factor with 12: 1, 5, 7 and 11.
- The quarter marks are 4 hours. The labels $`j`$ with $`3j \equiv 0 \pmod{12}`$ are exactly 0, 4 and 8, so the support product is 12.

The fast transforms, the clock's decimal values, the search over all sets of hours and the four broken cases are left to Python and Rust.

```lean
-- Fourier analysis on a finite abelian group: the complex characters of a finite abelian group are as many as its members, match the group, and are orthonormal, so every function is the sum of its characters with energy kept, convolution turns into multiplication, and the supports of a nonzero function and of its transform multiply to at least the group's size.
import Mathlib.Analysis.Fourier.FiniteAbelian.PontryaginDuality
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum

/-! `G` is a finite abelian group, written additively. A character is Mathlib's `AddChar G ℂ`:
a map `χ : G → ℂ` with `χ 0 = 1` and `χ (x + y) = χ x * χ y`. The dual group `Ĝ` is
`AddChar G ℂ`; Mathlib writes its operation (pointwise multiplication) additively, so
`G ≃+ AddChar G ℂ` is a match between the group and its dual. The card's normalisation is used:
the transform `f̂(χ) = (1/|G|) ∑ₓ f(x) conj(χ(x))` and the convolution
`(f * g)(x) = (1/|G|) ∑_y f(y) g(x − y)`. The support of a function is Mathlib's
`Function.support`, the points where it is nonzero, and `Set.ncard` counts it. -/

open ComplexConjugate

variable {G : Type*} [AddCommGroup G] [Fintype G]

/-- The card's transform: the amount of the character `χ` in `f`,
`f̂(χ) = (1/|G|) ∑ₓ f(x) · conj (χ x)`. -/
noncomputable def charTransform (f : G → ℂ) (χ : AddChar G ℂ) : ℂ :=
  (Fintype.card G : ℂ)⁻¹ * ∑ x, f x * conj (χ x)

/-- The card's convolution: `(f * g)(x) = (1/|G|) ∑_y f(y) g(x − y)`. -/
noncomputable def charConv (f g : G → ℂ) (x : G) : ℂ :=
  (Fintype.card G : ℂ)⁻¹ * ∑ y, f y * g (x - y)

theorem fourier_sum_mul_conj (χ ψ : AddChar G ℂ) [Decidable (χ = ψ)] :
    ∑ x, χ x * conj (ψ x) = if χ = ψ then (Fintype.card G : ℂ) else 0 := by
  classical
  have h : ∀ x, χ x * conj (ψ x) = (χ - ψ) x := by
    intro x; rw [AddChar.sub_apply, AddChar.map_neg_eq_conj]
  simp_rw [h]
  rw [AddChar.sum_eq_ite]
  simp only [sub_eq_zero]

theorem fourier_inversion_aux (f : G → ℂ) (x : G) :
    f x = ∑ χ : AddChar G ℂ, charTransform f χ * χ x := by
  classical
  have hc : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  have h1 : ∀ (χ : AddChar G ℂ) (y : G), conj (χ y) * χ x = χ (x - y) := by
    intro χ y
    rw [sub_eq_add_neg, AddChar.map_add_eq_mul, AddChar.map_neg_eq_conj, mul_comm]
  calc f x = (Fintype.card G : ℂ)⁻¹ * ∑ y, f y * ∑ χ : AddChar G ℂ, χ (x - y) := by
        simp_rw [AddChar.sum_apply_eq_ite, sub_eq_zero, mul_ite, mul_zero]
        rw [Finset.sum_ite_eq]
        simp only [Finset.mem_univ, ite_true]
        field_simp
    _ = ∑ χ : AddChar G ℂ, charTransform f χ * χ x := by
        simp_rw [charTransform, Finset.mul_sum, Finset.sum_mul]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun y _ => Finset.sum_congr rfl fun χ _ => ?_
        rw [← h1]; ring

theorem fourier_plancherel_aux (f : G → ℂ) :
    (Fintype.card G : ℝ)⁻¹ * ∑ x, ‖f x‖ ^ 2 = ∑ χ : AddChar G ℂ, ‖charTransform f χ‖ ^ 2 := by
  have hc : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  apply Complex.ofReal_injective
  push_cast
  simp_rw [← Complex.mul_conj']
  have h1 : ∀ x, conj (f x) = ∑ χ : AddChar G ℂ, conj (charTransform f χ) * conj (χ x) := by
    intro x
    conv_lhs => rw [fourier_inversion_aux f x]
    simp [map_sum]
  have h2 : ∀ χ : AddChar G ℂ, ∑ x, f x * conj (χ x) = (Fintype.card G : ℂ) * charTransform f χ := by
    intro χ; rw [charTransform, ← mul_assoc, mul_inv_cancel₀ hc, one_mul]
  calc (Fintype.card G : ℂ)⁻¹ * ∑ x, f x * conj (f x)
      = (Fintype.card G : ℂ)⁻¹ * ∑ χ : AddChar G ℂ, conj (charTransform f χ) * ∑ x, f x * conj (χ x) := by
        congr 1
        simp_rw [h1, Finset.mul_sum]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun χ _ => Finset.sum_congr rfl fun y _ => ?_
        ring
    _ = ∑ χ : AddChar G ℂ, charTransform f χ * conj (charTransform f χ) := by
        simp_rw [h2, Finset.mul_sum]
        refine Finset.sum_congr rfl fun χ _ => ?_
        field_simp

theorem fourier_exists_addEquiv : Nonempty (G ≃+ AddChar G ℂ) := by
  classical
  obtain ⟨ι, _, n, hn, ⟨e⟩⟩ := AddCommGroup.equiv_directSum_zmod_of_finite' G
  have hn' : ∀ i, NeZero (n i) := fun i => ⟨by have := hn i; omega⟩
  let e' : G ≃+ ((i : ι) → ZMod (n i)) := e.trans (DirectSum.addEquivProd _)
  let φ : ((i : ι) → ZMod (n i)) → AddChar ((i : ι) → ZMod (n i)) ℂ := fun u =>
    { toFun := fun x => ∏ i, AddChar.zmodAddEquiv (u i) (x i)
      map_zero_eq_one' := by simp
      map_add_eq_mul' := fun x y => by
        simp only [Pi.add_apply, AddChar.map_add_eq_mul, Finset.prod_mul_distrib] }
  let Ψ : G →+ AddChar G ℂ :=
    { toFun := fun g => (φ (e' g)).compAddMonoidHom e'.toAddMonoidHom
      map_zero' := by ext x; simp [φ, -AddChar.zmodAddEquiv_apply]
      map_add' := fun g h => by
        ext x; simp [φ, -AddChar.zmodAddEquiv_apply, Finset.prod_mul_distrib] }
  have hinj : Function.Injective Ψ := by
    rw [injective_iff_map_eq_zero]
    intro g hg
    apply e'.injective
    rw [map_zero]
    funext i
    have key : ∀ y : ZMod (n i), AddChar.zmodAddEquiv (e' g i) y = 1 := by
      intro y
      have := DFunLike.congr_fun hg (e'.symm (Pi.single i y))
      simp only [Ψ, φ, AddMonoidHom.coe_mk, ZeroHom.coe_mk, AddChar.compAddMonoidHom_apply,
        AddEquiv.coe_toAddMonoidHom, AddEquiv.apply_symm_apply, AddChar.coe_mk,
        AddChar.zero_apply] at this
      rw [Finset.prod_eq_single i] at this
      · simpa using this
      · intro j _ hj; simp [hj]
      · simp
    have : AddChar.zmodAddEquiv (e' g i) = 0 := AddChar.eq_zero_iff.2 key
    exact (map_eq_zero_iff _ AddChar.zmodAddEquiv.injective).1 this
  have hbij : Function.Bijective Ψ := by
    rw [Fintype.bijective_iff_injective_and_card]
    exact ⟨hinj, (AddChar.card_eq).symm⟩
  exact ⟨AddEquiv.ofBijective Ψ hbij⟩

theorem fourier_sum_norm_le_ncard_mul {α : Type*} [Fintype α] (φ : α → ℂ) (B : ℝ)
    (hB : ∀ a, ‖φ a‖ ≤ B) : ∑ a, ‖φ a‖ ≤ (Function.support φ).ncard * B := by
  classical
  have hs : (Function.support φ).ncard = (Finset.univ.filter (fun a => φ a ≠ 0)).card := by
    rw [← Set.ncard_coe_finset]; congr 1; ext a; simp
  rw [hs]
  calc ∑ a, ‖φ a‖ = ∑ a ∈ Finset.univ.filter (fun a => φ a ≠ 0), ‖φ a‖ := by
        rw [Finset.sum_filter]
        refine Finset.sum_congr rfl fun a _ => ?_
        split_ifs with h
        · rfl
        · simp only [not_not] at h; simp [h]
    _ ≤ (Finset.univ.filter (fun a => φ a ≠ 0)).card • B := Finset.sum_le_card_nsmul _ _ _ (fun a _ => hB a)
    _ = _ := by rw [nsmul_eq_mul]

/-- On a finite abelian group the characters take values of size 1; there are exactly as many
characters as members, and the dual group matches the group (by a match that needs a choice);
different characters are perpendicular and each has length 1 for the averaged inner product
`⟨f, g⟩ = (1/|G|) ∑ₓ f(x) conj(g(x))`; every function is the sum of its characters times their
amounts, `f = ∑_χ f̂(χ) χ`; and energy is kept (Plancherel):
`(1/|G|) ∑ₓ |f(x)|² = ∑_χ |f̂(χ)|²`. -/
theorem characters_orthonormal_basis_inversion_plancherel :
    (∀ (χ : AddChar G ℂ) (x : G), ‖χ x‖ = 1) ∧
    Fintype.card (AddChar G ℂ) = Fintype.card G ∧
    Nonempty (G ≃+ AddChar G ℂ) ∧
    (∀ χ : AddChar G ℂ, (Fintype.card G : ℂ)⁻¹ * ∑ x, χ x * conj (χ x) = 1) ∧
    (∀ χ ψ : AddChar G ℂ, χ ≠ ψ → (Fintype.card G : ℂ)⁻¹ * ∑ x, χ x * conj (ψ x) = 0) ∧
    (∀ (f : G → ℂ) (x : G), f x = ∑ χ : AddChar G ℂ, charTransform f χ * χ x) ∧
    (∀ f : G → ℂ,
      (Fintype.card G : ℝ)⁻¹ * ∑ x, ‖f x‖ ^ 2 = ∑ χ : AddChar G ℂ, ‖charTransform f χ‖ ^ 2) := by
  classical
  have hc : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  refine ⟨fun χ x => AddChar.norm_apply χ x, AddChar.card_eq, fourier_exists_addEquiv,
    fun χ => ?_, fun χ ψ h => ?_, fourier_inversion_aux, fourier_plancherel_aux⟩
  · rw [fourier_sum_mul_conj, ite_eq_left_iff.2 (fun h => absurd rfl h), inv_mul_cancel₀ hc]
  · rw [fourier_sum_mul_conj, ite_eq_right_iff.2 (fun h' => absurd h' h), mul_zero]

/-- The convolution rule: the transform of a convolution is the product of the transforms,
character by character, `(f * g)^(χ) = f̂(χ) ĝ(χ)`. -/
theorem transform_conv (f g : G → ℂ) (χ : AddChar G ℂ) :
    charTransform (charConv f g) χ = charTransform f χ * charTransform g χ := by
  have h1 : ∀ y : G, ∑ x, f y * g (x - y) * conj (χ x) =
      ∑ z, f y * conj (χ y) * (g z * conj (χ z)) := by
    intro y
    refine Fintype.sum_equiv (Equiv.subRight y) _ _ fun x => ?_
    have : χ x = χ y * χ (x - y) := by
      rw [← AddChar.map_add_eq_mul]; congr 1; abel
    simp only [Equiv.subRight_apply]
    rw [this, map_mul]; ring
  have h3 : ∑ x, ((Fintype.card G : ℂ)⁻¹ * ∑ y, f y * g (x - y)) * conj (χ x) =
      (Fintype.card G : ℂ)⁻¹ * ∑ y, ∑ z, f y * conj (χ y) * (g z * conj (χ z)) := by
    simp_rw [← h1, Finset.mul_sum, Finset.sum_mul]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun y _ => Finset.sum_congr rfl fun x _ => ?_
    ring
  simp only [charTransform, charConv]
  rw [h3, mul_mul_mul_comm, Finset.sum_mul_sum]
  ring

/-- The uncertainty bound: a nonzero function and its transform cannot both be concentrated;
the number of members where `f` is nonzero times the number of characters where `f̂` is nonzero
is at least the size of the group, `|supp f| · |supp f̂| ≥ |G|`. -/
theorem card_le_support_mul_support_transform (f : G → ℂ) (hf : f ≠ 0) :
    Fintype.card G ≤ (Function.support f).ncard * (Function.support (charTransform f)).ncard := by
  classical
  have hcpos : (0 : ℝ) < Fintype.card G := Nat.cast_pos.2 Fintype.card_pos
  obtain ⟨x₀, -, hx₀⟩ := Finset.exists_max_image Finset.univ (fun x => ‖f x‖) Finset.univ_nonempty
  set M := ‖f x₀‖ with hM
  have hMpos : 0 < M := by
    by_contra h
    push Not at h
    apply hf; funext x
    have := hx₀ x (Finset.mem_univ x)
    have : ‖f x‖ = 0 := le_antisymm (this.trans h) (norm_nonneg _)
    simpa using this
  set S := (Function.support f).ncard
  set T := (Function.support (charTransform f)).ncard
  have hA : ∀ χ : AddChar G ℂ, ‖charTransform f χ‖ ≤ (Fintype.card G : ℝ)⁻¹ * (S * M) := by
    intro χ
    rw [charTransform, norm_mul, norm_inv, Complex.norm_natCast]
    gcongr
    calc ‖∑ x, f x * conj (χ x)‖ ≤ ∑ x, ‖f x * conj (χ x)‖ := norm_sum_le _ _
      _ = ∑ x, ‖f x‖ := by simp
      _ ≤ S * M := fourier_sum_norm_le_ncard_mul f M fun x => hx₀ x (Finset.mem_univ x)
  have hB : M ≤ T * ((Fintype.card G : ℝ)⁻¹ * (S * M)) := by
    calc M = ‖∑ χ : AddChar G ℂ, charTransform f χ * χ x₀‖ := by
          rw [hM, ← fourier_inversion_aux]
      _ ≤ ∑ χ : AddChar G ℂ, ‖charTransform f χ * χ x₀‖ := norm_sum_le _ _
      _ = ∑ χ : AddChar G ℂ, ‖charTransform f χ‖ := by simp
      _ ≤ T * ((Fintype.card G : ℝ)⁻¹ * (S * M)) := fourier_sum_norm_le_ncard_mul _ _ hA
  have : (Fintype.card G : ℝ) ≤ S * T := by
    have h3 : M * Fintype.card G ≤ M * (S * T) := by
      have := mul_le_mul_of_nonneg_right hB hcpos.le
      calc M * Fintype.card G ≤ T * ((Fintype.card G : ℝ)⁻¹ * (S * M)) * Fintype.card G := this
        _ = M * (S * T) := by field_simp
    exact le_of_mul_le_mul_left h3 hMpos
  exact_mod_cast this

/-! The card's whole-number worked examples. Votes are `Bool`, read as `+1` (true) and `−1`
(false); the product of two votes is `+1` exactly when they agree. -/

/-- A vote as `+1` or `−1`. -/
def vote (b : Bool) : ℤ := if b then 1 else -1

/-- Majority of three votes. -/
def maj (a b c : Bool) : ℤ := if vote a + vote b + vote c > 0 then 1 else -1

-- The expansion `Maj = ½x₁ + ½x₂ + ½x₃ − ½x₁x₂x₃` on all 8 inputs, cleared of the halves.
example : ∀ a b c : Bool,
    2 * maj a b c = vote a + vote b + vote c - vote a * vote b * vote c := by decide

-- Majority's amounts times 8: 4 on one judge (so 1/2), 0 on two judges, −4 on all three
-- (so −1/2), and 0 on no judge.
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, maj a b c * vote a) = 4 := by decide
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, maj a b c * (vote a * vote b)) = 0 := by decide
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool,
    maj a b c * (vote a * vote b * vote c)) = -4 := by decide
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, maj a b c) = 0 := by decide

-- Weights 3/4 on single judges and 1/4 on the triple, adding to the mean of Maj², which is 1.
example : (3 * (1 / 2 : ℚ) ^ 2, (-1 / 2 : ℚ) ^ 2) = (3 / 4, 1 / 4) := by norm_num
example : 3 * (1 / 2 : ℚ) ^ 2 + (-1 / 2 : ℚ) ^ 2 = 1 := by norm_num

-- One judge's influence: switching vote 1 alone changes the verdict on 4 of the 8 inputs (0.5).
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool,
    if maj a b c ≠ maj (!a) b c then (1 : ℕ) else 0) = 4 := by decide

-- Each vote misread with chance 1/10: counted over all inputs and misreadings, the verdict
-- flips with chance 1088 / 8000 = 0.136 (a misreading pattern with k misread votes has
-- weight 9^(3 − k) / 1000) ...
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, ∑ e₁ : Bool, ∑ e₂ : Bool, ∑ e₃ : Bool,
    if maj a b c ≠ maj (xor a e₁) (xor b e₂) (xor c e₃) then
      9 ^ ((if e₁ then 0 else 1) + (if e₂ then 0 else 1) + (if e₃ then 0 else 1))
    else (0 : ℕ)) = 1088 := by decide
-- ... and read off the weights, ½ − ½(¾ · 0.8 + ¼ · 0.8³) = 17/125 = 0.136.
example : (1 / 2 : ℚ) - 1 / 2 * (3 / 4 * (4 / 5) + 1 / 4 * (4 / 5) ^ 3) = 17 / 125 := by norm_num
example : (1088 : ℚ) / 8000 = 17 / 125 := by norm_num

-- The linearity test Maj(x)Maj(y) = Maj(xy) passes on 40 of the 64 pairs (0.625), and the
-- weights give ½ + ½(3 · (1/2)³ − (1/2)³) = 5/8.
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, ∑ a' : Bool, ∑ b' : Bool, ∑ c' : Bool,
    if maj a b c * maj a' b' c' = maj (a == a') (b == b') (c == c') then (1 : ℕ) else 0)
      = 40 := by decide
example : (1 / 2 : ℚ) + 1 / 2 * (3 * (1 / 2) ^ 3 - (1 / 2) ^ 3) = 5 / 8 := by norm_num
example : (40 : ℚ) / 64 = 5 / 8 := by norm_num

-- The clock ℤ/12 splits as ℤ/4 × ℤ/3: hour k comes back from (k mod 4, k mod 3)
-- as (9 k₁ + 4 k₂) mod 12.
example : ∀ k : Fin 12, (9 * (k.val % 4) + 4 * (k.val % 3)) % 12 = k.val := by decide

-- The labels j = (3a + 4b) mod 12, for a < 4 and b < 3, hit all 12 characters.
example : ((Finset.range 4 ×ˢ Finset.range 3).image
    (fun p : ℕ × ℕ => (3 * p.1 + 4 * p.2) % 12)) = Finset.range 12 := by decide

-- Four characters need all 12 steps (χ₁, χ₅, χ₇, χ₁₁): 4 ways to match ℤ/12 with its dual.
example : ((Finset.range 12).filter (fun j => Nat.Coprime j 12)) = {1, 5, 7, 11} := by decide

-- The quarter marks H = {0, 3, 6, 9}: the characters χ_j equal to 1 on H are those with
-- 3j ≡ 0 mod 12, namely j = 0, 4, 8, so the support product is 4 × 3 = 12.
example : ((Finset.univ : Finset (ZMod 12)).filter (fun k => 3 ∣ k.val)).card = 4 := by decide
example : ((Finset.univ : Finset (ZMod 12)).filter (fun j => 3 * j = 0)) = {0, 4, 8} := by decide

#print axioms fourier_sum_mul_conj
#print axioms fourier_inversion_aux
#print axioms fourier_plancherel_aux
#print axioms fourier_exists_addEquiv
#print axioms fourier_sum_norm_le_ncard_mul
#print axioms characters_orthonormal_basis_inversion_plancherel
#print axioms transform_conv
#print axioms card_le_support_mul_support_transform
```

**Checked 2026-11-24 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'fourier_sum_mul_conj' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_inversion_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_plancherel_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_exists_addEquiv' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_sum_norm_le_ncard_mul' depends on axioms: [propext, Classical.choice, Quot.sound]
'characters_orthonormal_basis_inversion_plancherel' depends on axioms: [propext, Classical.choice, Quot.sound]
'transform_conv' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_le_support_mul_support_transform' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run the Python.
> - **Thirds of the clock.** Set `f` to `1 if k % 4 == 0 else 0`, the hours 0, 4, 8. Guess the support product. Answer: the transform sits on $`\chi_0`$, $`\chi_3`$, $`\chi_6`$, $`\chi_9`$, each 0.25, so 3 × 4 = 12 again, since 0, 4, 8 is a subgroup.
> - **A three-hour window.** Set `g` to `k in (0, 1, 2)`. Answer: $`\hat g`$ vanishes at $`\chi_4`$ and $`\chi_8`$, so the product is 3 × 10 = 30, and Plancherel reads 0.25 on both sides.
> - **Noisier judges.** Set `p = 0.2`. Answer: the verdict flips 0.248 of the time, against 0.2 for one judge; the gap widens.
> - **Break the split.** In `hat_crt`, change `3 * a + 4 * b` to `4 * a + 3 * b`. Answer: an assert stops it, because the waves land on the wrong characters.

---

## The usual mistake

> [!warning]
> **Mixing two normalisations.** This card puts $`1/\lvert G\rvert`$ on the transform and on convolution. The DFT card puts nothing on the transform and $`1/N`$ on the inverse. Take sums on both sides of Plancherel with DFT outputs and the quarter marks read 4 against 48. Each formula is right only with its own convention.
>
> - **Amounts read as weights.** Majority's four amounts of size 0.5 add to 2. Weights are their squares: 0.75 on single judges, 0.25 on the triple.
> - **Treating the match with the dual as given.** $`\mathbb{Z}/12`$ and its dual can be matched 4 ways, one for each of $`\chi_1`$, $`\chi_5`$, $`\chi_7`$, $`\chi_{11}`$. A result that depends on which match was chosen is not a fact about the group.
> - **Using 0 and 1 votes with ±1 formulas.** With bits $`b_i`$, the character is $`(-1)^{\sum_{i \in S} b_i}`$, not $`\prod_{i\in S} b_i`$. A product of bits takes the value 0, so it is no character.
> - **Expecting every small set to be tight.** The bound is reached only by cosets of subgroups, 28 of the 4,095 sets of hours. The two-hour window gives 22, not 12.

---

## Where you meet it in real life

- **Spectrum analysers and audio software.** The DFT is this card on $`\mathbb{Z}/N`$, scaled by $`N`$ ([The DFT and the FFT](../../13-Engineering%20mathematics/05-Signals/02-discrete-fourier-transform-and-the-fft.md)).
- **Prime-factor fast transforms.** Transforms of lengths such as 12 = 4 × 3 split along the Chinese remainder theorem, as in Step 7: 84 products instead of 144, with no twiddle factors.
- **Voting and noise.** The weights of a voting rule say how often a misread vote changes the result. For Majority of three, 0.136 against 0.1 for one judge.
- **Checking a function by spot tests.** The linearity test picks random $`x`$ and $`y`$ and checks $`f(x)f(y) = f(xy)`$. It passes with chance ½ + ½ times the sum of the cubed amounts. Majority passes 0.625 of the time, well short of the certain pass that every character scores. Tests of this kind sit inside [Interactive proofs](../../24-Computability%20and%20complexity/05-Algebraic%2C%20Interactive%20and%20Quantum/04-interactive-proofs-ip-pspace-and-the-pcp-theorem.md).
- **Quantum computers.** A Hadamard gate on each of $`n`$ qubits applies the Walsh-Hadamard transform, scaled to keep length. Shor's algorithm uses the transform on $`\mathbb{Z}/256`$ when factoring 15 ([Shor and Grover](../../24-Computability%20and%20complexity/05-Algebraic%2C%20Interactive%20and%20Quantum/07-shors-and-grovers-algorithms.md)).
- **Cell-phone codes.** Walsh functions, the characters $`\chi_S`$ of bit strings, separate users who share one radio channel, because different characters are perpendicular.

> **Say it back**
> A character of a finite abelian group turns the group's addition into multiplication of unit complex numbers, so shifting only rescales it. A group has exactly as many characters as members, and they are perpendicular, so they form a basis. The transform's amounts rebuild every function, keep its energy, and turn convolution into multiplication. A function and its transform cannot both be concentrated: their supports multiply to at least the group's size. On three votes the waves are products of votes, and Majority puts weight 0.75 on single judges and 0.25 on all three.

---

## What this builds on

- [Convergence in energy](../01-Fourier%20Series%20in%20Depth/05-l2-convergence-and-riesz-fischer.md): Parseval and the circle's inner product, which this card shrinks to a finite average.
- [The convolution theorem](../03-Convolution%20and%20Approximate%20Identities/02-convolution-theorem-and-impulse-response.md): blending in time is multiplying in frequency, here on a group.
- [Schur's lemma and orthogonality](../../03-Algebra/12-Group%20Representations/02-schurs-lemma-and-character-orthogonality.md): character orthogonality for every finite group, which Step 3 reaches by a shortcut.
- [Direct products](../../03-Algebra/08-Groups/07-direct-products.md): groups side by side, whose characters multiply.
- [The Chinese remainder theorem](../../02-Number%20theory/03-Clock%20Arithmetic/06-chinese-remainder-theorem.md): the clock of 12 as clocks of 4 and 3.
- [The DFT and the FFT](../../13-Engineering%20mathematics/05-Signals/02-discrete-fourier-transform-and-the-fft.md): the transform on $`\mathbb{Z}/N`$ and the butterfly, both seen here as one case.

## Where this goes next

- [Haar measure](02-haar-measure.md): the average over a group that ignores shifts, which replaces $`1/\lvert G\rvert`$ on the circle, the line and other compact groups.
- [Pontryagin duality](03-pontryagin-duality.md): the dual of the dual is the group itself, with no choice needed, for locally compact abelian groups.
- [Peter-Weyl](04-peter-weyl-theorem.md): compact groups that are not abelian, where matrices take the place of characters.
- [Dirichlet characters](../../21-Algebraic%20and%20analytic%20number%20theory/03-Characters%20and%20L-functions/01-dirichlet-characters.md): characters of the units of a clock, which pick out primes in one remainder class.
- [Gauss sums](../../21-Algebraic%20and%20analytic%20number%20theory/03-Characters%20and%20L-functions/06-gauss-sums.md): a character of addition against a character of multiplication, with an exact size.
- [Interactive proofs](../../24-Computability%20and%20complexity/05-Algebraic%2C%20Interactive%20and%20Quantum/04-interactive-proofs-ip-pspace-and-the-pcp-theorem.md): proofs checked by a few spot tests, where tests like the linearity test do the work.
- [Boolean functions](../../24-Computability%20and%20complexity/04-Beyond%20Worst%20Case/12-boolean-functions-fourier-and-sensitivity.md): decision trees, Fourier coefficients, and Huang's sensitivity theorem.

The question this card leaves open: the circle has infinitely many members, so what average replaces $`1/\lvert G\rvert`$ and keeps Steps 3 to 5 true?

---

## Sources

Verified 2026-11-24: every link below resolves to the publisher's page.

- Stein, Elias M., and Rami Shakarchi. *Fourier Analysis: An Introduction*. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113845/fourier-analysis). Chapter 7, "Finite Fourier Analysis": the transform on $`\mathbb{Z}/N`$ and on finite abelian groups, with the same $`1/\lvert G\rvert`$ convention.
- O'Donnell, Ryan. *Analysis of Boolean Functions*. Cambridge University Press, 2014. [doi:10.1017/CBO9781139814782](https://doi.org/10.1017/CBO9781139814782). Chapter 1: the transform on $`\{-1, 1\}^n`$, Majority's expansion, Fourier weight and the linearity test.
- Terras, Audrey. *Fourier Analysis on Finite Groups and Applications*. Cambridge University Press, 1999. [doi:10.1017/CBO9780511626265](https://doi.org/10.1017/CBO9780511626265). Characters, duals and fast transforms on finite abelian groups, with applications.
- Donoho, David L., and Philip B. Stark. "Uncertainty Principles and Signal Recovery." *SIAM Journal on Applied Mathematics* 49, no. 3 (1989): 906–931. [doi:10.1137/0149053](https://doi.org/10.1137/0149053). The support bound on $`\mathbb{Z}/N`$ and its equality cases.
- Blum, Manuel, Michael Luby, and Ronitt Rubinfeld. "Self-Testing/Correcting with Applications to Numerical Problems." *Journal of Computer and System Sciences* 47, no. 3 (1993): 549–595. [doi:10.1016/0022-0000(93)90044-W](https://doi.org/10.1016/0022-0000(93)90044-W). The linearity test.
