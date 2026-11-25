# Paraproducts: sort a product by which factor carries the high frequencies

[Syllabus](../../../SYLLABUS.md) → [Harmonic analysis](../README.md) → [Multipliers and Estimates for PDE](../README.md#s07) → Paraproducts

---

## General Overview

Take two equaliser tracks. Track one is a whistle: a pure tone at 3.5 kHz (3,500 cycles a second), 0.5 V tall. Track two is a bass line: a tone at 55 Hz, 1 V tall. Multiply them, sample by sample, as a ring modulator does.

The product has exactly two tones, at 3,445 Hz and 3,555 Hz: the whistle's frequency plus and minus the bass's. Each is 0.25 V² tall. Nothing lands near 55 Hz. The whistle decides *where* the product sits. The bass only acts as a slow volume knob on the whistle.

That is the whole idea of a **paraproduct**. Cut each factor into octave bands, as an equaliser does. Then sort every pair of bands into one of three piles:

- **low-high:** the first factor is at least two octaves below the second;
- **high-low:** the first factor is at least two octaves above the second;
- **high-high:** the two are within one octave of each other.

In the first two piles, the high factor sets the output frequency and the low factor only scales it. In the third pile, two high tones can cancel down to a low one: 3,500 Hz against 3,000 Hz gives 500 Hz, three octaves down.

As a map from the slow factor to the piece, the high-low piece stays bounded in energy even when the high factor is unbounded. It needs only bounded mean oscillation (BMO): its average distance from its own average stays bounded on every interval. The same sorting shows that a product of smooth signals is smooth, the estimate behind nonlinear wave and fluid equations.

**Split each factor into octave bands and a product falls into three exact pieces: in two of them the higher factor alone sets the output's octave, to within one band, and the piece with high frequencies b and low frequencies f, the paraproduct, is bounded in energy exactly when b has bounded mean oscillation.**

**What kind of fact this is:** theorems. The three-piece split and where each piece lives are proved on this card. The energy bound for the paraproduct is proved in full in its dyadic (Haar) form and in outline in its octave form. The product rule is proved in outline. The Coifman–Meyer theorem is stated with its source and key idea.

### The picture: the two-track product, line by line

Next, two two-tone tracks. One holds the bass (1 V at 55 Hz) and the whistle (0.5 V at 3,500 Hz); the other holds an A (0.6 V at 440 Hz) and a high tone (0.4 V at 3,000 Hz). Their product has eight lines. The bars show each line's mean square, the product's energy per second at that frequency, in V⁴:

```
385 Hz   low-high   ########################################  9/200
495 Hz   low-high   ########################################  9/200
2945 Hz  low-high   ##################                        1/50
3055 Hz  low-high   ##################                        1/50
3060 Hz  high-low   ##########                                9/800
3940 Hz  high-low   ##########                                9/800
500 Hz   high-high  ####                                      1/200
6500 Hz  high-high  ####                                      1/200
```

The piles hold 13/100, 9/400 and 1/100 V⁴ of the total 13/80 V⁴. Only the high-high lines leave the octave of their higher factor: 6,500 Hz rises one band, and 500 Hz falls three. The signals are synthetic.

---

## The formula

Notation from earlier cards: time $`t`$ in seconds, frequency $`\xi`$ (xi) in hertz, and the transform $`\hat f(\xi)`$. Here every signal lasts 1 s and repeats, so its frequencies are whole numbers of hertz and $`\hat f(\xi)`$ is the coefficient of $`e^{2\pi i\xi t}`$.

**Octave pieces.** For a whole number $`j \ge 0`$, $`\Delta_j f`$ (delta j of f) keeps the part of $`f`$ with $`2^j \le \lvert\xi\rvert < 2^{j+1}`$ Hz: octave band $`j`$. The constant part, $`\xi = 0`$, is band $`-1`$. $`S_m f`$ is everything in bands up to $`m`$: the part below $`2^{m+1}`$ Hz, a low-pass part, not the square function of [Littlewood-Paley](02-littlewood-paley-theory.md), whose bands had other edges; any octave split works. This card cuts the bands sharply so the sums are exact; the bound theorems use the smooth cut-offs of that card.

**Bony's split.** For two signals $`f`$ and $`g`$:

```math
fg = \underbrace{\sum_j S_{j-2}f\,\Delta_j g}_{\text{low-high}} + \underbrace{\sum_j \Delta_j f\,S_{j-2}g}_{\text{high-low}} + \underbrace{\sum_{\lvert j-k\rvert\le 1} \Delta_j f\,\Delta_k g}_{\text{high-high}}
```

**Read it aloud:** f times g is f's low part times g's band j, summed over j, plus the same with roles swapped, plus every pair of bands at most one octave apart.

**The paraproduct.** For a signal $`b`$ (the factor that carries the high frequencies), the **paraproduct** is the high-low piece with $`b`$ first:

```math
\pi_b f = \sum_j \Delta_j b \cdot S_{j-2} f
```

**Read it aloud:** pi b of f adds, band by band, b's band j times f's part two or more octaves lower.

**The paraproduct theorem.** Write $`\lVert f\rVert_2`$ for the energy norm, the square root of the area under $`\lvert f\rvert^2`$, and $`\lVert b\rVert_{\mathrm{BMO}}`$ for the size of $`b`$'s mean oscillation: the largest, over all intervals $`I`$, average distance of $`b`$ from its own average on $`I`$ ([BMO](../06-Maximal%20Functions%20and%20Beyond/09-bmo-and-the-john-nirenberg-inequality.md)). Then there are constants $`c, C > 0`$ with

```math
c\,\lVert b\rVert_{\mathrm{BMO}} \le \lVert \pi_b\rVert_{2\to 2} \le C\,\lVert b\rVert_{\mathrm{BMO}}
```

**Read it aloud:** the operator norm of pi b, the most it can stretch any signal's energy norm, is at least c times and at most C times the BMO size of b.

So $`\pi_b`$ is bounded on $`L^2`$ (signals of finite energy) exactly when $`b`$ is in BMO. Multiplying by $`b`$ itself needs more: $`b`$ must be bounded, with norm $`\sup\lvert b\rvert`$.

**The dyadic twin.** Step 4 proves the same theorem for a Haar version $`\pi^d_b`$, whose squared norm lies between the **Carleson constant** $`C_b`$ (the largest mean squared oscillation of $`b`$ on a dyadic interval) and $`4C_b`$. Squared oscillation gives the same BMO as plain oscillation, by the John–Nirenberg inequality.

**The Coifman–Meyer theorem (stated).** A bilinear multiplier with symbol $`\sigma(\xi, \eta)`$ acts on two signals by

```math
T_\sigma(f, g)(t) = \iint \sigma(\xi,\eta)\,\hat f(\xi)\,\hat g(\eta)\,e^{2\pi i(\xi+\eta)t}\,d\xi\,d\eta
```

If ($`\partial`$ is a partial derivative) $`\lvert\partial_\xi^{\alpha}\partial_\eta^{\beta}\sigma(\xi,\eta)\rvert \le A\,(\lvert\xi\rvert + \lvert\eta\rvert)^{-\alpha-\beta}`$ for all orders $`\alpha + \beta`$ up to a fixed number, then $`\lVert T_\sigma(f, g)\rVert_r \le C\,\lVert f\rVert_p\,\lVert g\rVert_q`$ whenever $`1 < p, q < \infty`$ and $`1/r = 1/p + 1/q`$.

**Read it aloud:** if each derivative of the symbol shrinks like the total frequency to the power minus its order, then T sigma maps an L p signal and an L q signal to an L r signal, as plain multiplication does.

**The product rule.** For $`s > 0`$, with the height $`\lVert h\rVert_\infty = \sup\lvert h\rvert`$ and the smoothness norm $`\lVert h\rVert_{H^s}^2 = \sum_\xi (1 + \xi^2)^s\,\lvert\hat h(\xi)\rvert^2`$:

```math
\lVert fg\rVert_{H^s} \le C_s\big(\lVert f\rVert_\infty\,\lVert g\rVert_{H^s} + \lVert f\rVert_{H^s}\,\lVert g\rVert_\infty\big)
```

**Read it aloud:** the s-smoothness of f g is at most a constant times the height of f times the smoothness of g, plus the smoothness of f times the height of g.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`t`$, $`x`$, $`\xi`$, $`\eta`$, $`\theta`$, $`\omega`$ | time in s; position in $`[0, 1)`$ in the dyadic model; frequency in Hz; the second factor's frequency; two cosines' angles | 1 s window; ξ = 3,500 Hz, η = 55 Hz | — |
| $`f`$, $`g`$, $`\hat f`$ | the two factors; a factor's coefficients | whistle 0.5 V at 3,500 Hz, bass 1 V at 55 Hz | — |
| $`j`$, $`k`$, $`m`$ | octave band numbers; band $`j`$ covers $`2^j`$ to $`2^{j+1} - 1`$ Hz | 55 Hz in band 5, 440 Hz in 8, 3,000 and 3,500 Hz in 11 | higher band: the piece moves up an octave |
| $`\Delta_j`$, $`S_m`$, $`T_j`$ | keep band $`j`$; keep every band up to $`m`$; the paraproduct's term $`j`$ | $`\Delta_{11}f`$ is the whistle; $`S_9 g`$ is the whole bass | — |
| $`b`$, $`\pi_b`$, $`\pi^*`$ | the high-frequency factor; the paraproduct; its adjoint, the transpose in energy | $`\pi_f g`$ is the whole whistle-times-bass product | larger $`\lVert b\rVert_{\mathrm{BMO}}`$: larger norm |
| $`\lVert\cdot\rVert_2`$, $`L^2`$, $`\lVert T\rVert_{2\to 2}`$ | energy norm; finite-energy signals; an operator's largest stretch | $`\lVert\pi^d_b\rVert = 2.0356`$ for $`b = \log_2(1/x)`$ | — |
| $`\lVert b\rVert_{\mathrm{BMO}}`$, $`I`$, $`J`$, $`\lvert I\rvert`$ | mean-oscillation size; intervals; an interval's length | $`\log_2(1/x)`$: oscillation variance 2.0814 on every $`(0, a)`$ | — |
| $`h_I`$, $`b_I`$, $`\langle f\rangle_I`$, $`\pi^d_b`$, $`1_J`$, $`a_I`$ | Step 4's Haar function, Haar coefficient, average on $`I`$, dyadic paraproduct, indicator of $`J`$, Carleson sequence | 1,024 points: $`C_b = 2.0699`$ | — |
| $`C_b`$, $`c`$, $`C`$, $`\mu`$ | Carleson constant; constants in the bounds; the Carleson measure of Step 5 | $`\lVert\pi^d_b\rVert^2 = 4.1436`$, between 2.0699 and 8.2797 | larger $`C_b`$: larger norm |
| $`\sigma`$, $`T_\sigma`$, $`A`$, $`\alpha`$, $`\beta`$, $`\psi_j`$, $`\phi_m`$ | a two-frequency symbol; its operator; its constant; derivative orders; smooth band and low-pass cut-offs | the high-low piece: σ = 1 when ξ is two octaves above η, 0 otherwise | — |
| $`p`$, $`q`$, $`r`$, $`\lVert\cdot\rVert_p`$ | powers for the input and output norms; the p-norm | not computed here: stated with its source | — |
| $`s`$, $`H^s`$, $`\lVert\cdot\rVert_\infty`$, $`C_s`$, $`Mf`$, $`M_d f`$, $`\lambda`$ | smoothness order; its norm; height; the product-rule constant; the maximal function and its dyadic form; a level | s = 1: $`\lVert fg\rVert_{H^1} = 932.898`$ against 2,541.278 | larger s: high bands weigh more |

### When it holds

- **All three piles.** The split is exact for any two signals whose band sums converge. Without the high-high pile, the two-track product loses 1/100 of 13/80 V⁴.
- **A gap of two octaves.** Only then does the output stay in bands $`j - 1`$ to $`j + 1`$. Within one band, 3,500 Hz against 3,000 Hz gives 500 Hz, three bands down.
- **b in BMO for the energy bound.** If $`b`$'s mean oscillation is unbounded, so is $`\pi_b`$. For $`b = (\log_2(1/x))^2`$ the Carleson constant grows from 151.2048 to 484.5407 as the grid goes from 64 to 1,024 points.
- **Smooth cut-offs for the bounds.** A sharp band edge is a jump in the symbol, which fails the Coifman–Meyer derivative condition.
- **s > 0 in the product rule.** The high-high pile sends energy down to low bands, and that sum over bands converges only when $`s > 0`$.

---

## Why it works

### Step 0: frequencies add when signals multiply

$`e^{2\pi i\xi t}\cdot e^{2\pi i\eta t} = e^{2\pi i(\xi+\eta)t}`$. So a product's frequencies are sums of one frequency from each factor. If one is far below the other, the sum stays close to the bigger one.

For the example, $`\cos\theta\cos\omega = \tfrac12\cos(\theta - \omega) + \tfrac12\cos(\theta + \omega)`$: the whistle times the bass gives 3,445 Hz and 3,555 Hz, both in band 11, the whistle's own band.

### Step 1: the split is exact

Write $`f = \sum_j \Delta_j f`$ and $`g = \sum_k \Delta_k g`$, bands from $`-1`$ up. Then $`fg = \sum_{j,k} \Delta_j f\,\Delta_k g`$ over all pairs. Every pair $`(j, k)`$ has exactly one of $`k \ge j + 2`$, $`j \ge k + 2`$ or $`\lvert j - k\rvert \le 1`$.

Group the first kind by $`k`$: for fixed $`k`$, the sum over $`j \le k - 2`$ of $`\Delta_j f`$ is $`S_{k-2}f`$. That gives the low-high pile. The second kind gives high-low the same way. What is left is high-high. No pair is counted twice or missed.

The check confirms it exactly on the coefficients, and within $`10^{-9}`$ on 16,384 samples.

### Step 2: where each piece lives

Take one low-high term, $`S_{j-2}f\,\Delta_j g`$. $`g`$'s part has $`2^j \le \lvert\eta\rvert < 2^{j+1}`$. $`f`$'s part has $`\lvert\xi\rvert < 2^{j-1}`$. Their sum satisfies

```math
2^{j-1} < \lvert\xi + \eta\rvert < 2^{j+1} + 2^{j-1}
```

So the term's output lies in bands $`j - 1`$ to $`j + 1`$ only, and the same holds for high-low. The bass (band 5) times the A (band 8) gives 385 Hz and 495 Hz, both in band 8.

A high-high term $`\Delta_j f\,\Delta_k g`$ with $`k \le j \le k + 1`$ has $`\lvert\xi + \eta\rvert < 2^{j+1} + 2^{k+1} \le 2^{j+2}`$ and no lower limit. The whistle and the 3,000 Hz tone, both in band 11, give 6,500 Hz and 500 Hz. The 500 Hz line lands in band 8, three bands below both.

### Step 3: near-orthogonality turns a sum into a sum of energies

Two signals whose frequencies do not overlap are orthogonal: the energy of their sum is the sum of their energies ([Plancherel](../02-The%20Fourier%20Transform/05-plancherel-and-l2.md)). By Step 2, the terms $`T_j = \Delta_j b\,S_{j-2}f`$ of the paraproduct with $`\lvert j - j'\rvert \ge 3`$ share no band. Split the $`j`$ into three classes by their remainder after dividing by 3. Inside a class the terms are orthogonal. Adding three classes costs at most a factor of 3:

```math
\lVert\pi_b f\rVert_2^2 \le 3\sum_j \lVert\Delta_j b\cdot S_{j-2}f\rVert_2^2 = 3\sum_j\int \lvert\Delta_j b(t)\rvert^2\,\lvert S_{j-2}f(t)\rvert^2\,dt
```

The sum weighs $`f`$'s local averages ($`S_{j-2}f`$ is $`f`$ blurred over about $`2^{-j}`$ s) against $`b`$'s energy at scale $`2^{-j}`$.

### Step 4: the dyadic twin, where the answer is exact

On $`[0, 1)`$, with position $`x`$, take the dyadic intervals $`I`$ (halves, quarters, eighths, …). The Haar function $`h_I`$ is $`+1/\sqrt{\lvert I\rvert}`$ on the left half of $`I`$ and $`-1/\sqrt{\lvert I\rvert}`$ on the right ([The Haar wavelet](../05-Wavelets%20and%20Time-Frequency/03-haar-wavelet-and-multiresolution.md)). Write $`b_I = \int b\,h_I`$ and $`\langle f\rangle_I`$ for the average of $`f`$ on $`I`$. Here the Haar piece $`b_I h_I`$ plays $`\Delta_j b`$ and the average plays $`S_{j-2}f`$:

```math
\pi^d_b f = \sum_I b_I\,\langle f\rangle_I\,h_I, \qquad \lVert\pi^d_b f\rVert_2^2 = \sum_I b_I^2\,\langle f\rangle_I^2, \qquad C_b = \sup_J \frac{1}{\lvert J\rvert}\sum_{I \subseteq J} b_I^2
```

**Read it aloud:** the dyadic paraproduct takes b's Haar coefficient times f's average on each interval; its energy is the sum of their squares, because the Haar functions are orthonormal; the Carleson constant is the largest energy of b's pieces inside an interval J, per unit length.

Expand $`b`$ on $`J`$ in Haar functions: its average is the constant part and the rest is $`\sum_{I\subseteq J} b_I h_I`$. So $`\sum_{I\subseteq J} b_I^2 = \int_J \lvert b - \langle b\rangle_J\rvert^2`$, and $`C_b`$ is the largest mean squared oscillation: the dyadic BMO size, squared.

**Lower bound.** Take $`f = 1_J`$, which is 1 on $`J`$ and 0 elsewhere. Every $`I \subseteq J`$ has $`\langle f\rangle_I = 1`$, so $`\lVert\pi^d_b 1_J\rVert^2 \ge \sum_{I\subseteq J} b_I^2`$ while $`\lVert 1_J\rVert^2 = \lvert J\rvert`$. Hence $`\lVert\pi^d_b\rVert^2 \ge C_b`$: a bounded paraproduct forces bounded mean oscillation.

**Upper bound.** The numbers $`a_I = b_I^2`$ have $`\sum_{I \subseteq J} a_I \le C_b\lvert J\rvert`$ for every $`J`$: a **Carleson sequence**. The dyadic Carleson embedding, proved in the fold, gives $`\sum_I a_I\langle f\rangle_I^2 \le 4\,C_b\,\lVert f\rVert_2^2`$.

<details>
<summary>Detailed proof: the dyadic Carleson embedding, constant 4</summary>

Replace $`f`$ by $`\lvert f\rvert`$; this does not lower any $`\langle f\rangle_I^2`$. Let $`M_d f(x)`$ be the dyadic maximal function: the largest $`\langle\lvert f\rvert\rangle_I`$ over dyadic $`I`$ containing $`x`$ ([The maximal function](../06-Maximal%20Functions%20and%20Beyond/01-hardy-littlewood-maximal-function.md)).

Slice the sum by levels. For $`\lambda > 0`$:

$`\displaystyle \sum_I a_I\langle f\rangle_I^2 = \int_0^\infty \sum_{I:\ \langle f\rangle_I^2 > \lambda} a_I\,d\lambda .`$

The intervals with $`\langle f\rangle_I > \sqrt\lambda`$ all lie inside the largest such intervals $`J_1, J_2, \ldots`$, which do not overlap. Their union is the set where $`M_d f > \sqrt\lambda`$. By the Carleson condition on each $`J_i`$:

$`\displaystyle \sum_{I:\ \langle f\rangle_I^2 > \lambda} a_I \le C_b\sum_i \lvert J_i\rvert = C_b\,\lvert\{M_d f > \sqrt\lambda\}\rvert .`$

Integrate in $`\lambda`$: the right side gives $`C_b\int (M_d f)^2`$. Doob's maximal inequality gives $`\int (M_d f)^2 \le 4\int f^2`$, the constant $`(p/(p-1))^2`$ at $`p = 2`$. So $`\sum_I a_I\langle f\rangle_I^2 \le 4\,C_b\,\lVert f\rVert_2^2`$.

</details>

The check builds $`\pi^d_b`$ on 64, 256 and 1,024 points for $`b = \log_2(1/x)`$, an unbounded signal in BMO. It finds the norm by power iteration (apply $`\pi^*\pi`$ again and again, starting from the worst $`1_J`$).

| Points | $`C_b`$ by Haar sums | by oscillation | $`\lVert\pi^d_b\rVert^2`$ | $`4C_b`$ | $`\lVert\pi^d_b\rVert`$ | $`\sup\lvert b\rvert`$ |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 64 | 1.9608 | 1.9608 | 3.1014 | 7.8433 | 1.7611 | 7 |
| 256 | 2.0434 | 2.0434 | 3.7020 | 8.1738 | 1.9241 | 9 |
| 1,024 | 2.0699 | 2.0699 | 4.1436 | 8.2797 | 2.0356 | 11 |

The Carleson constant creeps up to 2.0814 = $`1/(\ln 2)^2`$, the variance of $`\log_2(1/x)`$ on every interval $`(0, a)`$. So the norm never passes $`2/\ln 2 = 2.8854`$. $`\sup\lvert b\rvert`$ grows by 2 every time the grid gets four times finer. Multiplying by $`b`$ is unbounded; the paraproduct is not.

### Step 5: the octave version, in outline

Step 3 reduced $`\pi_b`$ to the sum $`\sum_j\int\lvert\Delta_j b\rvert^2\lvert S_{j-2}f\rvert^2`$. Place the weight $`\lvert\Delta_j b(t)\rvert^2\,dt`$ at the point $`(t, 2^{-j})`$: time $`t`$, scale $`2^{-j}`$ s. This is a measure $`\mu`$ on the upper half-plane.

- **Carleson measure.** $`\mu`$ puts at most $`C\lVert b\rVert_{\mathrm{BMO}}^2\,\lvert I\rvert`$ on the box above any interval $`I`$ (the scales below $`\lvert I\rvert`$, the times in $`I`$). This is Fefferman and Stein's characterisation of BMO, the continuous form of Step 4's $`C_b`$.
- **Carleson embedding.** For such a $`\mu`$, $`\int\lvert S_{j-2} f\rvert^2\,d\mu \le C'\lVert\mu\rVert\,\lVert Mf\rVert_2^2`$, by the same slicing as the fold: $`\lvert S_{j-2}f(t)\rvert`$ is at most a constant times the maximal function $`Mf(t)`$.
- **Maximal bound.** $`\lVert Mf\rVert_2 \le C''\lVert f\rVert_2`$ ([The maximal function](../06-Maximal%20Functions%20and%20Beyond/01-hardy-littlewood-maximal-function.md)).

Chained, these give $`\lVert\pi_b f\rVert_2 \le C\lVert b\rVert_{\mathrm{BMO}}\lVert f\rVert_2`$. The converse is Step 4's lower bound with a smooth bump in place of $`1_J`$. In dual form, $`\langle\pi_b f, g\rangle`$ pairs $`b`$ with a signal in $`H^1`$, which is [The Hardy space H¹](../06-Maximal%20Functions%20and%20Beyond/10-hardy-space-h1-and-its-duality-with-bmo.md) and its duality with BMO at work.

### Step 6: Coifman–Meyer, the key idea

The high-low pile is $`T_\sigma`$ with $`\sigma(\xi, \eta) = \sum_j \psi_j(\xi)\,\phi_{j-2}(\eta)`$, where $`\psi_j`$ is band $`j`$'s smooth cut-off and $`\phi_{j-2}`$ the low-pass one. Each derivative of a band-$`j`$ cut-off costs about $`2^{-j}`$, where $`\lvert\xi\rvert + \lvert\eta\rvert`$ is about $`2^j`$, so σ meets the condition.

Coifman and Meyer ran this backwards. Cut any σ meeting the condition into dyadic shells in $`(\xi, \eta)`$, and expand it on each shell in a fast-converging Fourier series. Each term is a paraproduct-type piece, bounded by the Steps above. Their theorem covers $`r \ge 1`$; the range below 1, down to $`r > 1/2`$, came later (Kenig and Stein, 1999; Grafakos and Torres, 2002) and is proved in Grafakos (chapter 7).

<details>
<summary>Proof outline: the product rule from the three piles</summary>

Write $`\lVert h\rVert_{H^s}^2`$ as about $`\sum_j 4^{js}\lVert\Delta_j h\rVert_2^2`$: band $`j`$ costs $`(2^j)^{2s}`$.

**Low-high.** Term $`j`$ lives in bands $`j-1`$ to $`j+1`$, with energy norm at most $`C\lVert f\rVert_\infty\lVert\Delta_j g\rVert_2`$. So the pile costs $`C\lVert f\rVert_\infty\lVert g\rVert_{H^s}`$; high-low likewise.

**High-high.** Term $`j`$ lands in bands up to $`j + 2`$ and is at most $`\lVert g\rVert_\infty\lVert\Delta_j f\rVert_2`$ in energy. Band $`k`$ of the pile collects terms with $`j \ge k - 3`$:

$`\displaystyle 2^{ks}\lVert\Delta_k(\text{high-high})\rVert_2 \le C\lVert g\rVert_\infty\sum_{j \ge k-3} 2^{(k-j)s}\,2^{js}\lVert\Delta_j f\rVert_2 .`$

The weights $`2^{(k-j)s}`$ have a finite sum over $`j \ge k - 3`$ only when $`s > 0`$, and then Young's inequality gives $`C\lVert f\rVert_{H^s}\lVert g\rVert_\infty`$.

</details>

On the two tracks with $`s = 1`$, the check finds $`\lVert fg\rVert_{H^1} = 932.898`$. The right side, with $`C_1 = 1`$ (proved by $`(fg)' = f'g + fg'`$ and the triangle inequality), is $`1.500 \times 868.820 + 1238.048 \times 1.000 = 2541.278`$, a ratio of 0.3671. The three piles have $`H^1`$ norms 614.669, 529.132 and 460.977; they share no line here, so their squares add to $`932.898^2`$. Samples of $`fg`$ and its slope $`f'g + fg'`$ give 932.898 again.

---

## Worked numbers, by hand

The whistle (0.5 V at 3,500 Hz) times the bass (1 V at 55 Hz).

| Step | Arithmetic | Value |
| --- | --- | --- |
| Whistle's band | $`2^{11} = 2048 \le 3500 < 4096`$ | band 11 |
| Bass's band | $`2^5 = 32 \le 55 < 64`$ | band 5 |
| Which pile | 11 ≥ 5 + 2, the whistle is the high factor | high-low |
| Product formula | $`0.5\cos\theta \times 1\cos\omega = 0.25\cos(\theta-\omega) + 0.25\cos(\theta+\omega)`$ | two tones, 0.25 V² each |
| Their frequencies | 3,500 − 55 and 3,500 + 55 | 3,445 Hz and 3,555 Hz |
| Their bands | both between 2,048 and 4,095 | band 11 |
| Mean square of each | $`0.25^2 / 2`$ | 1/32 V⁴ |
| Mean square of the product | 1/32 + 1/32 | **1/16 = 0.0625 V⁴, all in high-low** |

The product sits in the whistle's octave and carries the bass only as a slow change of volume: it is $`\pi_f g`$, with nothing in the other two piles.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drop the high-high pile from the two-track product | 61/400 = 0.1525 V⁴ of 13/80 = 0.1625 | 3,500 Hz against 3,000 Hz, both band 11, leaves a 500 Hz line in band 8 |
| Take b out of BMO: $`b = (\log_2(1/x))^2`$ | $`C_b`$ = 151.2048, 294.0925, 484.5407; norm 15.4295, 22.0454, 29.0446 at 64, 256, 1,024 points | the mean oscillation grows with depth near 0, so no energy bound holds |
| Bound $`\pi_b`$ by $`\sup\lvert b\rvert`$ for $`b = \log_2(1/x)`$ | 7, 9, 11 at 64, 256, 1,024 points, without limit | the true norm is 1.7611, 1.9241, 2.0356, never above 2.8854 |

---

## Code, from first principles, and it actually runs

The script writes every piece itself: exact fractions, a radix-2 fast Fourier transform, the octave cuts, the Haar paraproduct, its adjoint and power iteration. Five independent roads: exact piles against the product and against each pair of tones, including pairs two bands and one band apart; sampled piles against the sampled product and the exact spectra; the $`H^1`$ norm from coefficients and from samples; $`C_b`$ by Haar sums and by mean oscillation; the norm by power iteration, checked by the Haar energy sum, the adjoint identity and, at 64 points, the explicit matrix.

### Python

```python
# Paraproducts and the Coifman-Meyer theorem -- the check behind the card.
# Standard library only.  Signals last 1 s, so every frequency is a whole number of hertz.
# Octave band j holds 2^j <= |xi| < 2^(j+1) Hz; band -1 holds xi = 0.
from fractions import Fraction as Fr
from math import cos, sin, pi, log, log2, sqrt, floor

def tones(*pairs):                            # amplitude A at a Hz is A/2 at +a and at -a
    c = {}
    for amp, a in pairs: c[a] = c[-a] = c.get(a, 0) + Fr(amp) / 2
    return c

band = lambda x: -1 if x == 0 else abs(x).bit_length() - 1
pile = lambda j, k: "LH" if k >= j + 2 else "HL" if j >= k + 2 else "HH"   # Bony's rule on two band numbers
def conv(f, g):                               # spectrum of the product: frequencies add
    h = {}
    for x, a in f.items():
        for y, b in g.items(): h[x + y] = h.get(x + y, 0) + a * b
    return {k: v for k, v in h.items() if v != 0}

def pieces(f, g):                             # low-high, high-low, high-high, from band pairs
    out = {"LH": {}, "HL": {}, "HH": {}}
    for x, a in f.items():
        for y, b in g.items():
            p = out[pile(band(x), band(y))]; p[x + y] = p.get(x + y, 0) + a * b
    return {k: {x: v for x, v in p.items() if v != 0} for k, p in out.items()}

def fft(a, inv=False):                        # iterative radix-2 transform, length a power of 2
    a, n, j = a[:], len(a), 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit: j ^= bit; bit >>= 1
        j |= bit
        if i < j: a[i], a[j] = a[j], a[i]
    m = 2
    while m <= n:
        w = complex(cos(2 * pi / m), (1 if inv else -1) * sin(2 * pi / m))
        for s in range(0, n, m):
            z = 1
            for k in range(m // 2):
                u, v = a[s + k], a[s + k + m // 2] * z
                a[s + k], a[s + k + m // 2] = u + v, u - v; z *= w
        m *= 2
    return [x / n for x in a] if inv else a

ms = lambda c: sum(v * v for v in c.values())  # mean square over the second (energy per second)
show = lambda k, p: "%s piece: mean square %s; lines %s" % (k, ms(p), [("%d Hz" % x, str(2 * p[x] ** 2)) for x in sorted(p) if x > 0])
N = 16384                                     # samples in the 1 s window
def samples(c): return [sum(float(v) * cos(2 * pi * x * k / N) for x, v in c.items()) for k in range(N)]

pairs = [("bass x whistle", ((Fr(1, 2), 3500),), ((1, 55),)),
         ("two tracks", ((1, 55), (Fr(1, 2), 3500)), ((Fr(3, 5), 440), (Fr(2, 5), 3000))),
         ("440 Hz x (1000 Hz + 1500 Hz)", ((1, 440),), ((1, 1000), (1, 1500))), ("(1000 Hz + 1500 Hz) x 440 Hz", ((1, 1000), (1, 1500)), ((1, 440),))]
for name, ft, gt in pairs:
    f, g = tones(*ft), tones(*gt); P, fg = pieces(f, g), conv(f, g)
    tot = {x: sum(p.get(x, 0) for p in P.values()) for x in set().union(*P.values())}
    assert {k: v for k, v in tot.items() if v != 0} == fg  # road 1: exact fractions
    E = {"LH": {}, "HL": {}, "HH": {}}                      # each pile rebuilt from which tone meets which, bands by logarithm
    for (u, a), (v, c) in [(s, t) for s in ft for t in gt]:
        e = E["LH" if c >= 4 * 2 ** floor(log2(a)) else "HL" if a >= 4 * 2 ** floor(log2(c)) else "HH"]
        for x, y in conv(tones((u, a)), tones((v, c))).items(): e[x] = e.get(x, 0) + y
    assert {k: {x: y for x, y in p.items() if y != 0} for k, p in E.items()} == P
    assert all(abs(band(x + y) - max(band(x), band(y))) <= 1 for x in f for y in g if pile(band(x), band(y)) != "HH")  # Step 2
    print("%s: product lines at %s Hz, mean square %s V^4" % (name, sorted(x for x in fg if x > 0), ms(fg)))
    for k in ("LH", "HL", "HH"): print("  " + show(k, P[k]))
    sf, sg = samples(f), samples(g); F, G = fft([complex(v) for v in sf]), fft([complex(v) for v in sg])
    def bandpart(S, js):                      # road 2: cut the sampled transform into octave bands
        return [z.real for z in fft([S[i] if band(i if i < N // 2 else i - N) in js else 0 for i in range(N)], True)]
    jf = sorted({band(x) for x in f}); jg = sorted({band(x) for x in g})
    df = {j: bandpart(F, {j}) for j in jf}; dg = {j: bandpart(G, {j}) for j in jg}
    T = {"LH": [0.0] * N, "HL": [0.0] * N, "HH": [0.0] * N}
    for j, k in [(j, k) for j in jf for k in jg]: T[pile(j, k)] = [t + u * v for t, u, v in zip(T[pile(j, k)], df[j], dg[k])]
    err = max(abs(a * b - x - y - z) for a, b, x, y, z in zip(sf, sg, T["LH"], T["HL"], T["HH"]))
    S = {k: fft([complex(v) for v in T[k]]) for k in T}
    gap = max(abs(S[k][x % N] / N - float(P[k].get(x, 0))) for k in T for x in range(-N // 2, N // 2))
    assert err < 1e-9 and gap < 1e-9
    print("  time road: LH + HL + HH = f g at all %d samples, gap below 1e-9; piece spectra match, gap below 1e-9" % N)

assert all(2 ** band(x) <= x < 2 ** (band(x) + 1) for x in range(1, 9000))
print("bands: " + ", ".join("%d Hz in %d (%d to %d Hz)" % (x, band(x), 2 ** band(x), 2 ** (band(x) + 1) - 1) for x in (55, 440, 500, 1000, 1500, 3000, 3500)))
for label, gt in (("bass at 1500 Hz", ((1, 1500),)), ("bass doubled", ((2, 55),))):
    print("try: bass x whistle, %s: %s" % (label, "; ".join(show(k, p) for k, p in pieces(tones(*pairs[0][1]), tones(*gt)).items() if p)))
name, ft, gt = pairs[1]; f, g = tones(*ft), tones(*gt); P = pieces(f, g)
print("drop HH: LH + HL keep mean square %s of %s; 3500 - 3000 = 500 Hz lands in band %d, from two lines in band %d"
      % (ms(P["LH"]) + ms(P["HL"]), ms(conv(f, g)), band(500), band(3500)))
H1 = lambda c: sqrt(sum((1 + x * x) * float(v * v) for x, v in c.items()))
sup = lambda c: max(abs(v) for v in samples(c))
lhs, rhs = H1(conv(f, g)), sup(f) * H1(g) + H1(f) * sup(g)
print("product rule s = 1: ||fg||_H1 = %.3f, ||f||_sup = %.3f, ||g||_H1 = %.3f, ||f||_H1 = %.3f, ||g||_sup = %.3f"
      % (lhs, sup(f), H1(g), H1(f), sup(g)))
deriv = lambda c: [sum(-2 * pi * x * float(v) * sin(2 * pi * x * k / N) for x, v in c.items()) for k in range(N)]
sf, sg, df, dg = samples(f), samples(g), deriv(f), deriv(g)  # time road: ||h||_H1^2 = mean h^2 + mean (h'/2 pi)^2
h1t = sqrt(sum((a * b) ** 2 + ((da * b + a * db) / (2 * pi)) ** 2 for a, b, da, db in zip(sf, sg, df, dg)) / N)
print("  time road: ||fg||_H1 from samples of fg and (fg)' = f'g + fg' = %.3f" % h1t)
print("  bound ||f||_sup ||g||_H1 + ||f||_H1 ||g||_sup = %.3f, ratio %.4f" % (rhs, lhs / rhs))
for k in ("LH", "HL", "HH"): print("  %s piece: ||.||_H1 = %.3f" % (k, H1(P[k])))
assert lhs <= rhs and abs(lhs ** 2 - sum(H1(p) ** 2 for p in P.values())) < 1e-6 * lhs ** 2 and abs(h1t - lhs) < 1e-6 * lhs

# The dyadic paraproduct on [0, 1): pi_b f = sum over dyadic I of b_I <f>_I h_I, N = 2^n points.
def dyadic(b, n):
    M = 2 ** n; Is = [(s, L) for L in [M >> m for m in range(n)] for s in range(0, M, L)]
    coef = {(s, L): (sum(b[s:s + L // 2]) - sum(b[s + L // 2:s + L])) / sqrt(L * M) for s, L in Is}
    def op(f):                                # pi_b f
        out = [0.0] * M
        for (s, L), c in coef.items():
            a, h = c * sum(f[s:s + L]) / L, sqrt(M / L)
            for i in range(s, s + L): out[i] += a * h if i < s + L // 2 else -a * h
        return out
    def adj(g):                               # its adjoint: sum of b_I <g, h_I> 1_I / |I|
        out = [0.0] * M
        for (s, L), c in coef.items():
            a = c * sqrt(M / L) * (sum(g[s:s + L // 2]) - sum(g[s + L // 2:s + L])) / M * M / L
            for i in range(s, s + L): out[i] += a
        return out
    car, s0, L0 = max((sum(c * c for (s2, L2), c in coef.items() if s <= s2 and s2 + L2 <= s + L) * M / L, s, L) for s, L in Is)
    osc = max(sum((v - sum(b[s:s + L]) / L) ** 2 for v in b[s:s + L]) / L for s, L in Is)
    x = [1.0 if s0 <= i < s0 + L0 else 0.0 for i in range(M)]
    for _ in range(300):                       # power iteration on pi* pi, Rayleigh quotient rises
        y = adj(op(x)); r = sqrt(sum(v * v for v in y)); x = [v / r for v in y]
    q = sum(v * v for v in op(x)) / sum(v * v for v in x)
    haar = M * sum(c * c * (sum(x[s:s + L]) / L) ** 2 for (s, L), c in coef.items()) / sum(v * v for v in x)
    ip = [sum(u * v for u, v in zip(op(b), x)), sum(u * v for u, v in zip(b, adj(x)))]
    assert abs(haar - q) < 1e-9 * q and abs(ip[0] - ip[1]) < 1e-9 * abs(ip[0])  # sum b_I^2 <x>_I^2; <pi b, x> = <b, pi* x>
    lam = 0.0
    if n == 6:                                # second road: the explicit 64 x 64 matrix A, its transpose, top eigenvalue of A^T A
        A = [op([float(i == k) for i in range(M)]) for k in range(M)]
        Gm = [[sum(u * v for u, v in zip(A[r], A[c])) for c in range(M)] for r in range(M)]; z = [1.0] * M
        for _ in range(300): y = [sum(u * v for u, v in zip(row, z)) for row in Gm]; r = sqrt(sum(v * v for v in y)); z = [v / r for v in y]
        lam = sum(u * v for u, v in zip([sum(a * c for a, c in zip(row, z)) for row in Gm], z))
    return car, osc, q, max(abs(v) for v in b), lam

for label, p in [("log2(1/x)", 1), ("log2(1/x)^2", 2)]:
    for n in (6, 8, 10, 12):
        b = [log2(2 ** n / (i + 0.5)) ** p for i in range(2 ** n)]
        C, osc, q, top, lam = dyadic(b, n)
        print("%sb = %s, %4d points: Carleson %.4f, oscillation %.4f, ||pi_b||^2 %.4f, 4C %.4f, ||pi_b|| %.4f, max|b| %.4f"
              % ("try: " if n == 12 else "", label, 2 ** n, C, osc, q, 4 * C, sqrt(q), top))
        if lam: print("  explicit %d x %d matrix: top eigenvalue of its transpose times it %.4f" % (2 ** n, 2 ** n, lam))
        assert abs(C - osc) < 1e-9 and C - 1e-9 <= q <= 4 * C and (p == 2 or C < 1 / log(2) ** 2) and (n > 6 or abs(lam - q) < 1e-9 * q)
print("mean oscillation of log2(1/x) on any (0, a), unsampled: variance 1/(ln 2)^2 = %.4f, so ||pi_b|| <= 2/ln 2 = %.4f" % (1 / log(2) ** 2, 2 / log(2)))
print("ALL CHECKS PASS")
```

**Ran 2026-11-24 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
bass x whistle: product lines at [3445, 3555] Hz, mean square 1/16 V^4
  LH piece: mean square 0; lines []
  HL piece: mean square 1/16; lines [('3445 Hz', '1/32'), ('3555 Hz', '1/32')]
  HH piece: mean square 0; lines []
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
two tracks: product lines at [385, 495, 500, 2945, 3055, 3060, 3940, 6500] Hz, mean square 13/80 V^4
  LH piece: mean square 13/100; lines [('385 Hz', '9/200'), ('495 Hz', '9/200'), ('2945 Hz', '1/50'), ('3055 Hz', '1/50')]
  HL piece: mean square 9/400; lines [('3060 Hz', '9/800'), ('3940 Hz', '9/800')]
  HH piece: mean square 1/100; lines [('500 Hz', '1/200'), ('6500 Hz', '1/200')]
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
440 Hz x (1000 Hz + 1500 Hz): product lines at [560, 1060, 1440, 1940] Hz, mean square 1/2 V^4
  LH piece: mean square 1/4; lines [('1060 Hz', '1/8'), ('1940 Hz', '1/8')]
  HL piece: mean square 0; lines []
  HH piece: mean square 1/4; lines [('560 Hz', '1/8'), ('1440 Hz', '1/8')]
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
(1000 Hz + 1500 Hz) x 440 Hz: product lines at [560, 1060, 1440, 1940] Hz, mean square 1/2 V^4
  LH piece: mean square 0; lines []
  HL piece: mean square 1/4; lines [('1060 Hz', '1/8'), ('1940 Hz', '1/8')]
  HH piece: mean square 1/4; lines [('560 Hz', '1/8'), ('1440 Hz', '1/8')]
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
bands: 55 Hz in 5 (32 to 63 Hz), 440 Hz in 8 (256 to 511 Hz), 500 Hz in 8 (256 to 511 Hz), 1000 Hz in 9 (512 to 1023 Hz), 1500 Hz in 10 (1024 to 2047 Hz), 3000 Hz in 11 (2048 to 4095 Hz), 3500 Hz in 11 (2048 to 4095 Hz)
try: bass x whistle, bass at 1500 Hz: HH piece: mean square 1/16; lines [('2000 Hz', '1/32'), ('5000 Hz', '1/32')]
try: bass x whistle, bass doubled: HL piece: mean square 1/4; lines [('3445 Hz', '1/8'), ('3555 Hz', '1/8')]
drop HH: LH + HL keep mean square 61/400 of 13/80; 3500 - 3000 = 500 Hz lands in band 8, from two lines in band 11
product rule s = 1: ||fg||_H1 = 932.898, ||f||_sup = 1.500, ||g||_H1 = 868.820, ||f||_H1 = 1238.048, ||g||_sup = 1.000
  time road: ||fg||_H1 from samples of fg and (fg)' = f'g + fg' = 932.898
  bound ||f||_sup ||g||_H1 + ||f||_H1 ||g||_sup = 2541.278, ratio 0.3671
  LH piece: ||.||_H1 = 614.669
  HL piece: ||.||_H1 = 529.132
  HH piece: ||.||_H1 = 460.977
b = log2(1/x),   64 points: Carleson 1.9608, oscillation 1.9608, ||pi_b||^2 3.1014, 4C 7.8433, ||pi_b|| 1.7611, max|b| 7.0000
  explicit 64 x 64 matrix: top eigenvalue of its transpose times it 3.1014
b = log2(1/x),  256 points: Carleson 2.0434, oscillation 2.0434, ||pi_b||^2 3.7020, 4C 8.1738, ||pi_b|| 1.9241, max|b| 9.0000
b = log2(1/x), 1024 points: Carleson 2.0699, oscillation 2.0699, ||pi_b||^2 4.1436, 4C 8.2797, ||pi_b|| 2.0356, max|b| 11.0000
try: b = log2(1/x), 4096 points: Carleson 2.0780, oscillation 2.0780, ||pi_b||^2 4.4728, 4C 8.3121, ||pi_b|| 2.1149, max|b| 13.0000
b = log2(1/x)^2,   64 points: Carleson 151.2048, oscillation 151.2048, ||pi_b||^2 238.0690, 4C 604.8192, ||pi_b|| 15.4295, max|b| 49.0000
  explicit 64 x 64 matrix: top eigenvalue of its transpose times it 238.0690
b = log2(1/x)^2,  256 points: Carleson 294.0925, oscillation 294.0925, ||pi_b||^2 485.9984, 4C 1176.3698, ||pi_b|| 22.0454, max|b| 81.0000
b = log2(1/x)^2, 1024 points: Carleson 484.5407, oscillation 484.5407, ||pi_b||^2 843.5917, 4C 1938.1627, ||pi_b|| 29.0446, max|b| 121.0000
try: b = log2(1/x)^2, 4096 points: Carleson 731.9152, oscillation 731.9152, ||pi_b||^2 1320.0707, 4C 2927.6609, ||pi_b|| 36.3328, max|b| 169.0000
mean oscillation of log2(1/x) on any (0, a), unsampled: variance 1/(ln 2)^2 = 2.0814, so ||pi_b|| <= 2/ln 2 = 2.8854
ALL CHECKS PASS
```

### Rust

```rust
// Paraproducts and the Coifman-Meyer theorem -- the check behind the card.
// std only.  Signals last 1 s, so every frequency is a whole number of hertz.
// Octave band j holds 2^j <= |xi| < 2^(j+1) Hz; band -1 holds xi = 0.
use std::collections::BTreeMap;
use std::f64::consts::PI;

#[derive(Clone, Copy, PartialEq)]
struct Q(i64, i64); // an exact fraction, always in lowest terms with a positive denominator
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; Q(s * n / g, s * d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn qs(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn qf(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
type Spec = BTreeMap<i64, Q>;

fn tones(p: &[(Q, i64)]) -> Spec { // amplitude A at a Hz is A/2 at +a and at -a
    let mut c = Spec::new(); for &(amp, a) in p { for x in [a, -a] { let v = *c.get(&x).unwrap_or(&Q(0, 1)); c.insert(x, add(v, mul(amp, Q(1, 2)))); } } c
}
fn band(x: i64) -> i64 { if x == 0 { -1 } else { 63 - x.abs().leading_zeros() as i64 } }
fn key(j: i64, k: i64) -> usize { if k >= j + 2 { 0 } else if j >= k + 2 { 1 } else { 2 } } // Bony's rule on two band numbers
fn clean(h: Spec) -> Spec { h.into_iter().filter(|(_, v)| v.0 != 0).collect() }
fn pieces(f: &Spec, g: &Spec) -> (Spec, [Spec; 3]) { // whole product, then low-high, high-low, high-high
    let (mut h, mut out) = (Spec::new(), [Spec::new(), Spec::new(), Spec::new()]);
    for (&x, &a) in f { for (&y, &b) in g {
        let e = h.entry(x + y).or_insert(Q(0, 1)); *e = add(*e, mul(a, b));
        let e = out[key(band(x), band(y))].entry(x + y).or_insert(Q(0, 1)); *e = add(*e, mul(a, b));
    } }
    let [a, b, c] = out;
    (clean(h), [clean(a), clean(b), clean(c)])
}

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn cm(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn fft(a0: &[C], inv: bool) -> Vec<C> { // iterative radix-2 transform, length a power of 2
    let (mut a, n, mut j) = (a0.to_vec(), a0.len(), 0usize);
    for i in 1..n {
        let mut bit = n >> 1; while j & bit != 0 { j ^= bit; bit >>= 1; }
        j |= bit; if i < j { a.swap(i, j); }
    }
    let mut m = 2;
    while m <= n {
        let w = C { re: (2.0 * PI / m as f64).cos(), im: (if inv { 1.0 } else { -1.0 }) * (2.0 * PI / m as f64).sin() };
        for s in (0..n).step_by(m) {
            let mut z = C { re: 1.0, im: 0.0 };
            for k in 0..m / 2 {
                let (u, v) = (a[s + k], cm(a[s + k + m / 2], z));
                a[s + k] = C { re: u.re + v.re, im: u.im + v.im }; a[s + k + m / 2] = C { re: u.re - v.re, im: u.im - v.im }; z = cm(z, w);
            }
        }
        m *= 2;
    }
    if inv { a.iter().map(|x| C { re: x.re / n as f64, im: x.im / n as f64 }).collect() } else { a }
}

const N: usize = 16384; // samples in the 1 s window
fn ms(c: &Spec) -> Q { c.values().fold(Q(0, 1), |s, &v| add(s, mul(v, v))) }
fn samples(c: &Spec) -> Vec<f64> {
    (0..N).map(|k| c.iter().map(|(&x, &v)| qf(v) * (2.0 * PI * x as f64 * k as f64 / N as f64).cos()).sum()).collect()
}
fn show(k: usize, p: &Spec) -> String { format!("{} piece: mean square {}; lines [{}]", ["LH", "HL", "HH"][k], qs(ms(p)),
    p.iter().filter(|(&x, _)| x > 0).map(|(x, &v)| format!("('{} Hz', '{}')", x, qs(mul(Q(2, 1), mul(v, v))))).collect::<Vec<_>>().join(", ")) }
fn lines(c: &Spec) -> String { format!("[{}]", c.keys().filter(|&&x| x > 0).map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn cx(v: &[f64]) -> Vec<C> { v.iter().map(|&x| C { re: x, im: 0.0 }).collect() }
fn bandpart(s: &[C], j: i64) -> Vec<f64> { // cut the sampled transform to one octave band
    let m: Vec<C> = (0..N).map(|i| { let x = if i < N / 2 { i as i64 } else { i as i64 - N as i64 };
        if band(x) == j { s[i] } else { C { re: 0.0, im: 0.0 } } }).collect();
    fft(&m, true).iter().map(|z| z.re).collect()
}
fn h1(c: &Spec) -> f64 { c.iter().map(|(&x, &v)| (1.0 + (x * x) as f64) * qf(mul(v, v))).sum::<f64>().sqrt() }
fn deriv(c: &Spec) -> Vec<f64> {
    (0..N).map(|k| c.iter().map(|(&x, &v)| -2.0 * PI * x as f64 * qf(v) * (2.0 * PI * x as f64 * k as f64 / N as f64).sin()).sum()).collect()
}
fn sup(c: &Spec) -> f64 { samples(c).iter().fold(0.0, |m: f64, v| m.max(v.abs())) }

fn dyadic(b: &[f64], n: u32) -> (f64, f64, f64, f64, f64) { // the dyadic paraproduct on 2^n points
    let mm = 1usize << n; let mut is = vec![];
    for m in 0..n { let l = mm >> m; for s in (0..mm).step_by(l) { is.push((s, l)); } }
    let sum = |v: &[f64]| v.iter().sum::<f64>();
    let coef: Vec<f64> = is.iter().map(|&(s, l)| (sum(&b[s..s + l / 2]) - sum(&b[s + l / 2..s + l])) / ((l * mm) as f64).sqrt()).collect();
    let op = |f: &[f64]| { let mut out = vec![0.0; mm];
        for (t, &(s, l)) in is.iter().enumerate() { let (a, h) = (coef[t] * sum(&f[s..s + l]) / l as f64, (mm as f64 / l as f64).sqrt());
            for i in s..s + l { out[i] += if i < s + l / 2 { a * h } else { -a * h }; } }
        out };
    let adj = |g: &[f64]| { let mut out = vec![0.0; mm];
        for (t, &(s, l)) in is.iter().enumerate() {
            let a = coef[t] * (mm as f64 / l as f64).sqrt() * (sum(&g[s..s + l / 2]) - sum(&g[s + l / 2..s + l])) / mm as f64 * mm as f64 / l as f64; for i in s..s + l { out[i] += a; } }
        out };
    let (mut car, mut s0, mut l0) = (-1.0, 0, 0);
    for &(s, l) in &is { let c: f64 = is.iter().zip(&coef).filter(|(&(s2, l2), _)| s <= s2 && s2 + l2 <= s + l).map(|(_, c)| c * c).sum::<f64>() * mm as f64 / l as f64;
        if c > car { car = c; s0 = s; l0 = l; } }
    let osc = is.iter().map(|&(s, l)| { let a = sum(&b[s..s + l]) / l as f64; b[s..s + l].iter().map(|v| (v - a).powi(2)).sum::<f64>() / l as f64 }).fold(0.0, f64::max);
    let mut x: Vec<f64> = (0..mm).map(|i| if s0 <= i && i < s0 + l0 { 1.0 } else { 0.0 }).collect();
    for _ in 0..300 { let y = adj(&op(&x)); let r = y.iter().map(|v| v * v).sum::<f64>().sqrt(); x = y.iter().map(|v| v / r).collect(); }
    let qq = op(&x).iter().map(|v| v * v).sum::<f64>() / x.iter().map(|v| v * v).sum::<f64>();
    let haar = mm as f64 * is.iter().zip(&coef).map(|(&(s, l), c)| c * c * (sum(&x[s..s + l]) / l as f64).powi(2)).sum::<f64>() / x.iter().map(|v| v * v).sum::<f64>();
    let ip = [op(b).iter().zip(&x).map(|(u, v)| u * v).sum::<f64>(), b.iter().zip(&adj(&x)).map(|(u, v)| u * v).sum::<f64>()];
    assert!((haar - qq).abs() < 1e-9 * qq && (ip[0] - ip[1]).abs() < 1e-9 * ip[0].abs()); // sum b_I^2 <x>_I^2; <pi b, x> = <b, pi* x>
    let mut lam = 0.0; if n == 6 { // second road: the explicit 64 x 64 matrix A, its transpose, top eigenvalue of A^T A
        let a: Vec<Vec<f64>> = (0..mm).map(|k| op(&(0..mm).map(|i| if i == k { 1.0 } else { 0.0 }).collect::<Vec<_>>())).collect();
        let gm: Vec<Vec<f64>> = (0..mm).map(|r| (0..mm).map(|c| a[r].iter().zip(&a[c]).map(|(u, v)| u * v).sum()).collect()).collect(); let mut z = vec![1.0; mm];
        for _ in 0..300 { let y: Vec<f64> = gm.iter().map(|row| row.iter().zip(&z).map(|(u, v)| u * v).sum()).collect(); let r = y.iter().map(|v| v * v).sum::<f64>().sqrt(); z = y.iter().map(|v| v / r).collect(); }
        lam = gm.iter().map(|row| row.iter().zip(&z).map(|(u, v)| u * v).sum::<f64>()).zip(&z).map(|(u, v)| u * v).sum();
    }
    (car, osc, qq, b.iter().fold(0.0, |m: f64, v| m.max(v.abs())), lam)
}

fn main() {
    let pairs: [(&str, Vec<(Q, i64)>, Vec<(Q, i64)>); 4] = [("bass x whistle", vec![(Q(1, 2), 3500)], vec![(Q(1, 1), 55)]),
                 ("two tracks", vec![(Q(1, 1), 55), (Q(1, 2), 3500)], vec![(Q(3, 5), 440), (Q(2, 5), 3000)]),
                 ("440 Hz x (1000 Hz + 1500 Hz)", vec![(Q(1, 1), 440)], vec![(Q(1, 1), 1000), (Q(1, 1), 1500)]), ("(1000 Hz + 1500 Hz) x 440 Hz", vec![(Q(1, 1), 1000), (Q(1, 1), 1500)], vec![(Q(1, 1), 440)])];
    for (name, ft, gt) in &pairs {
        let (f, g) = (tones(ft), tones(gt)); let (fg, p) = pieces(&f, &g);
        let mut tot = Spec::new();
        for pc in &p { for (&x, &v) in pc { let e = tot.entry(x).or_insert(Q(0, 1)); *e = add(*e, v); } }
        let direct: Spec = { let mut h = Spec::new(); for (&x, &a) in &f { for (&y, &b) in &g { let e = h.entry(x + y).or_insert(Q(0, 1)); *e = add(*e, mul(a, b)); } } clean(h) };
        assert!(clean(tot) == direct && direct == fg); // road 1: exact fractions
        let mut e = [Spec::new(), Spec::new(), Spec::new()]; // each pile rebuilt from which tone meets which, bands by logarithm
        for &(u, a) in ft { for &(v, c) in gt {
            let k = if c as f64 >= 4.0 * 2f64.powf((a as f64).log2().floor()) { 0 } else if a as f64 >= 4.0 * 2f64.powf((c as f64).log2().floor()) { 1 } else { 2 };
            for (x, y) in pieces(&tones(&[(u, a)]), &tones(&[(v, c)])).0 { let s = e[k].entry(x).or_insert(Q(0, 1)); *s = add(*s, y); } } }
        assert!(e.map(clean) == p);
        assert!(f.keys().all(|&x| g.keys().all(|&y| key(band(x), band(y)) == 2 || (band(x + y) - band(x).max(band(y))).abs() <= 1))); // Step 2
        println!("{}: product lines at {} Hz, mean square {} V^4", name, lines(&fg), qs(ms(&fg)));
        for k in 0..3 { println!("  {}", show(k, &p[k])); }
        let (sf, sg) = (samples(&f), samples(&g)); let (ff, gg) = (fft(&cx(&sf), false), fft(&cx(&sg), false));
        let mut t = vec![vec![0.0; N]; 3];
        let (mut jf, mut jg): (Vec<i64>, Vec<i64>) = (f.keys().map(|&x| band(x)).collect(), g.keys().map(|&x| band(x)).collect());
        jf.sort(); jf.dedup(); jg.sort(); jg.dedup();
        for &j in &jf { let dj = bandpart(&ff, j); for &k in &jg { let dk = bandpart(&gg, k);
            for i in 0..N { t[key(j, k)][i] += dj[i] * dk[i]; } } }
        let err = (0..N).map(|i| (sf[i] * sg[i] - t[0][i] - t[1][i] - t[2][i]).abs()).fold(0.0, f64::max);
        let mut gap: f64 = 0.0;
        for k in 0..3 { let s = fft(&cx(&t[k]), false);
            for x in -(N as i64) / 2..(N as i64) / 2 { let z = s[x.rem_euclid(N as i64) as usize]; let e = p[k].get(&x).map(|&v| qf(v)).unwrap_or(0.0);
                gap = gap.max(((z.re / N as f64 - e).powi(2) + (z.im / N as f64).powi(2)).sqrt()); } }
        assert!(err < 1e-9 && gap < 1e-9);
        println!("  time road: LH + HL + HH = f g at all {} samples, gap below 1e-9; piece spectra match, gap below 1e-9", N);
    }
    assert!((1..9000i64).all(|x| (1i64 << band(x)) <= x && x < (1i64 << (band(x) + 1))));
    println!("bands: {}", [55i64, 440, 500, 1000, 1500, 3000, 3500].iter().map(|&x| format!("{} Hz in {} ({} to {} Hz)", x, band(x), 1i64 << band(x), (1i64 << (band(x) + 1)) - 1)).collect::<Vec<_>>().join(", "));
    for (label, gt) in [("bass at 1500 Hz", [(Q(1, 1), 1500)]), ("bass doubled", [(Q(2, 1), 55)])] {
        let (_, p) = pieces(&tones(&pairs[0].1), &tones(&gt)); println!("try: bass x whistle, {}: {}", label, (0..3).filter(|&k| !p[k].is_empty()).map(|k| show(k, &p[k])).collect::<Vec<_>>().join("; ")); }
    let (f, g) = (tones(&pairs[1].1), tones(&pairs[1].2)); let (fg, p) = pieces(&f, &g);
    println!("drop HH: LH + HL keep mean square {} of {}; 3500 - 3000 = 500 Hz lands in band {}, from two lines in band {}",
             qs(add(ms(&p[0]), ms(&p[1]))), qs(ms(&fg)), band(500), band(3500));
    let (lhs, rhs) = (h1(&fg), sup(&f) * h1(&g) + h1(&f) * sup(&g));
    println!("product rule s = 1: ||fg||_H1 = {:.3}, ||f||_sup = {:.3}, ||g||_H1 = {:.3}, ||f||_H1 = {:.3}, ||g||_sup = {:.3}",
             lhs, sup(&f), h1(&g), h1(&f), sup(&g));
    let (sf, sg, df, dg) = (samples(&f), samples(&g), deriv(&f), deriv(&g)); // time road: ||h||_H1^2 = mean h^2 + mean (h'/2 pi)^2
    let h1t = ((0..N).map(|i| (sf[i] * sg[i]).powi(2) + ((df[i] * sg[i] + sf[i] * dg[i]) / (2.0 * PI)).powi(2)).sum::<f64>() / N as f64).sqrt();
    println!("  time road: ||fg||_H1 from samples of fg and (fg)' = f'g + fg' = {:.3}", h1t);
    println!("  bound ||f||_sup ||g||_H1 + ||f||_H1 ||g||_sup = {:.3}, ratio {:.4}", rhs, lhs / rhs);
    for k in 0..3 { println!("  {} piece: ||.||_H1 = {:.3}", ["LH", "HL", "HH"][k], h1(&p[k])); }
    assert!(lhs <= rhs && (lhs * lhs - p.iter().map(|c| h1(c).powi(2)).sum::<f64>()).abs() < 1e-6 * lhs * lhs && (h1t - lhs).abs() < 1e-6 * lhs);

    for (label, pw) in [("log2(1/x)", 1), ("log2(1/x)^2", 2)] {
        for n in [6u32, 8, 10, 12] {
            let b: Vec<f64> = (0..1usize << n).map(|i| ((1u64 << n) as f64 / (i as f64 + 0.5)).log2().powi(pw)).collect();
            let (c, osc, qq, top, lam) = dyadic(&b, n);
            println!("{}b = {}, {:4} points: Carleson {:.4}, oscillation {:.4}, ||pi_b||^2 {:.4}, 4C {:.4}, ||pi_b|| {:.4}, max|b| {:.4}",
                     if n == 12 { "try: " } else { "" }, label, 1u32 << n, c, osc, qq, 4.0 * c, qq.sqrt(), top);
            if lam > 0.0 { println!("  explicit {} x {} matrix: top eigenvalue of its transpose times it {:.4}", 1u32 << n, 1u32 << n, lam); }
            assert!((c - osc).abs() < 1e-9 && c - 1e-9 <= qq && qq <= 4.0 * c && (pw == 2 || c < 1.0 / 2f64.ln().powi(2)) && (n > 6 || (lam - qq).abs() < 1e-9 * qq));
        }
    }
    println!("mean oscillation of log2(1/x) on any (0, a), unsampled: variance 1/(ln 2)^2 = {:.4}, so ||pi_b|| <= 2/ln 2 = {:.4}", 1.0 / 2f64.ln().powi(2), 2.0 / 2f64.ln());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
bass x whistle: product lines at [3445, 3555] Hz, mean square 1/16 V^4
  LH piece: mean square 0; lines []
  HL piece: mean square 1/16; lines [('3445 Hz', '1/32'), ('3555 Hz', '1/32')]
  HH piece: mean square 0; lines []
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
two tracks: product lines at [385, 495, 500, 2945, 3055, 3060, 3940, 6500] Hz, mean square 13/80 V^4
  LH piece: mean square 13/100; lines [('385 Hz', '9/200'), ('495 Hz', '9/200'), ('2945 Hz', '1/50'), ('3055 Hz', '1/50')]
  HL piece: mean square 9/400; lines [('3060 Hz', '9/800'), ('3940 Hz', '9/800')]
  HH piece: mean square 1/100; lines [('500 Hz', '1/200'), ('6500 Hz', '1/200')]
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
440 Hz x (1000 Hz + 1500 Hz): product lines at [560, 1060, 1440, 1940] Hz, mean square 1/2 V^4
  LH piece: mean square 1/4; lines [('1060 Hz', '1/8'), ('1940 Hz', '1/8')]
  HL piece: mean square 0; lines []
  HH piece: mean square 1/4; lines [('560 Hz', '1/8'), ('1440 Hz', '1/8')]
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
(1000 Hz + 1500 Hz) x 440 Hz: product lines at [560, 1060, 1440, 1940] Hz, mean square 1/2 V^4
  LH piece: mean square 0; lines []
  HL piece: mean square 1/4; lines [('1060 Hz', '1/8'), ('1940 Hz', '1/8')]
  HH piece: mean square 1/4; lines [('560 Hz', '1/8'), ('1440 Hz', '1/8')]
  time road: LH + HL + HH = f g at all 16384 samples, gap below 1e-9; piece spectra match, gap below 1e-9
bands: 55 Hz in 5 (32 to 63 Hz), 440 Hz in 8 (256 to 511 Hz), 500 Hz in 8 (256 to 511 Hz), 1000 Hz in 9 (512 to 1023 Hz), 1500 Hz in 10 (1024 to 2047 Hz), 3000 Hz in 11 (2048 to 4095 Hz), 3500 Hz in 11 (2048 to 4095 Hz)
try: bass x whistle, bass at 1500 Hz: HH piece: mean square 1/16; lines [('2000 Hz', '1/32'), ('5000 Hz', '1/32')]
try: bass x whistle, bass doubled: HL piece: mean square 1/4; lines [('3445 Hz', '1/8'), ('3555 Hz', '1/8')]
drop HH: LH + HL keep mean square 61/400 of 13/80; 3500 - 3000 = 500 Hz lands in band 8, from two lines in band 11
product rule s = 1: ||fg||_H1 = 932.898, ||f||_sup = 1.500, ||g||_H1 = 868.820, ||f||_H1 = 1238.048, ||g||_sup = 1.000
  time road: ||fg||_H1 from samples of fg and (fg)' = f'g + fg' = 932.898
  bound ||f||_sup ||g||_H1 + ||f||_H1 ||g||_sup = 2541.278, ratio 0.3671
  LH piece: ||.||_H1 = 614.669
  HL piece: ||.||_H1 = 529.132
  HH piece: ||.||_H1 = 460.977
b = log2(1/x),   64 points: Carleson 1.9608, oscillation 1.9608, ||pi_b||^2 3.1014, 4C 7.8433, ||pi_b|| 1.7611, max|b| 7.0000
  explicit 64 x 64 matrix: top eigenvalue of its transpose times it 3.1014
b = log2(1/x),  256 points: Carleson 2.0434, oscillation 2.0434, ||pi_b||^2 3.7020, 4C 8.1738, ||pi_b|| 1.9241, max|b| 9.0000
b = log2(1/x), 1024 points: Carleson 2.0699, oscillation 2.0699, ||pi_b||^2 4.1436, 4C 8.2797, ||pi_b|| 2.0356, max|b| 11.0000
try: b = log2(1/x), 4096 points: Carleson 2.0780, oscillation 2.0780, ||pi_b||^2 4.4728, 4C 8.3121, ||pi_b|| 2.1149, max|b| 13.0000
b = log2(1/x)^2,   64 points: Carleson 151.2048, oscillation 151.2048, ||pi_b||^2 238.0690, 4C 604.8192, ||pi_b|| 15.4295, max|b| 49.0000
  explicit 64 x 64 matrix: top eigenvalue of its transpose times it 238.0690
b = log2(1/x)^2,  256 points: Carleson 294.0925, oscillation 294.0925, ||pi_b||^2 485.9984, 4C 1176.3698, ||pi_b|| 22.0454, max|b| 81.0000
b = log2(1/x)^2, 1024 points: Carleson 484.5407, oscillation 484.5407, ||pi_b||^2 843.5917, 4C 1938.1627, ||pi_b|| 29.0446, max|b| 121.0000
try: b = log2(1/x)^2, 4096 points: Carleson 731.9152, oscillation 731.9152, ||pi_b||^2 1320.0707, 4C 2927.6609, ||pi_b|| 36.3328, max|b| 169.0000
mean oscillation of log2(1/x) on any (0, a), unsampled: variance 1/(ln 2)^2 = 2.0814, so ||pi_b|| <= 2/ln 2 = 2.8854
ALL CHECKS PASS
```

### Lean

Lean proves Bony's split for any finite band sums, and where low-high and high-high terms land, for every band.

- Suppose $`f`$ and $`g`$ are each a sum of finitely many octave pieces. Then $`fg`$ is exactly the sum of the low-high, high-low and high-high piles.
- Take $`\eta`$ in band $`j`$ and $`\xi`$ in bands up to $`j - 2`$, as in a low-high term. Then $`2^{j-1} < \lvert\xi + \eta\rvert < 2^{j+1} + 2^{j-1}`$.
- Take $`\xi`$ in bands up to $`j`$, $`\eta`$ in bands up to $`k`$, and $`k \le j \le k + 1`$. Then $`\lvert\xi + \eta\rvert < 2^{j+1} + 2^{k+1} \le 2^{j+2}`$.
- Lean also checks the worked numbers, such as the whistle in band 11 and the piles' total of 13/80 V⁴.

The paraproduct's energy bound, the Carleson constants, the product rule and every decimal are left to the Python and Rust checks.

```lean
-- Paraproducts: Bony's split of a product of two band sums into low-high, high-low and high-high piles is exact, and a low-high term stays within one band of its high factor.
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.Field.Power
import Mathlib.Basic.Complex.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
import Mathlib.Tactic.Linarith

open Finset

/-- Bony's split is exact. Cut two signals `f` and `g` into octave pieces,
`f = ∑ Δf j` and `g = ∑ Δg k` (index `i` stands for band `i - 1`, so index 0 is
the constant part). Then `f g` is the low-high pile `∑ₖ S_{k-2} f · Δ_k g`, plus
the high-low pile `∑ⱼ Δ_j f · S_{j-2} g`, plus the high-high pile of all pairs of
bands at most one octave apart; here `S_{k-2} f` is the sum of `f`'s bands `j`
with `j + 2 ≤ k`. No pair of bands is missed or counted twice. -/
theorem bony_split_exact (n : ℕ) (Δf Δg : ℕ → ℝ → ℂ) (f g : ℝ → ℂ)
    (hf : f = ∑ j ∈ range n, Δf j) (hg : g = ∑ k ∈ range n, Δg k) :
    f * g =
      (∑ k ∈ range n, (∑ j ∈ (range n).filter (fun j => j + 2 ≤ k), Δf j) * Δg k)
      + (∑ j ∈ range n, Δf j * (∑ k ∈ (range n).filter (fun k => k + 2 ≤ j), Δg k))
      + (∑ j ∈ range n, ∑ k ∈ (range n).filter (fun k => k ≤ j + 1 ∧ j ≤ k + 1),
          Δf j * Δg k) := by
  subst hf hg
  rw [Finset.sum_mul_sum]
  simp_rw [Finset.sum_mul, Finset.mul_sum, Finset.sum_filter]
  rw [Finset.sum_comm (s := range n) (t := range n) (f := fun k j => if j + 2 ≤ k then Δf j * Δg k else 0)]
  rw [← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun k _ => ?_
  split_ifs <;> first | omega | simp

/-- Where a low-high term lives. If the high factor's frequency `η` is in octave
band `j` (`2^j ≤ |η| < 2^(j+1)` Hz) and the low factor's frequency `ξ` is below
`2^(j-1)` Hz (bands up to `j - 2`), then the product's frequency `ξ + η` satisfies
`2^(j-1) < |ξ + η| < 2^(j+1) + 2^(j-1)`, so it lies in bands `j - 1` to `j + 1`. -/
theorem low_high_term_stays_near_band (j : ℤ) (ξ η : ℝ)
    (hη₁ : (2 : ℝ) ^ j ≤ |η|) (hη₂ : |η| < (2 : ℝ) ^ (j + 1))
    (hξ : |ξ| < (2 : ℝ) ^ (j - 1)) :
    (2 : ℝ) ^ (j - 1) < |ξ + η| ∧ |ξ + η| < (2 : ℝ) ^ (j + 1) + (2 : ℝ) ^ (j - 1) := by
  have h2 : (2 : ℝ) ^ j = 2 * (2 : ℝ) ^ (j - 1) := by
    rw [← zpow_one_add₀ (by norm_num : (2:ℝ) ≠ 0)]; ring_nf
  constructor
  · have := abs_sub_abs_le_abs_sub η (-ξ)
    rw [sub_neg_eq_add, add_comm η ξ, abs_neg] at this
    linarith
  · have := abs_add_le ξ η
    linarith

/-- Where a high-high term lives. If `|ξ| < 2^(j+1)` and `|η| < 2^(k+1)` with
`k ≤ j ≤ k + 1`, then `|ξ + η| < 2^(j+1) + 2^(k+1) ≤ 2^(j+2)`: the output rises at
most one band, and there is no lower limit. -/
theorem high_high_term_upper_band (j k : ℤ) (ξ η : ℝ)
    (hkj : k ≤ j) (hjk : j ≤ k + 1)
    (hξ : |ξ| < (2 : ℝ) ^ (j + 1)) (hη : |η| < (2 : ℝ) ^ (k + 1)) :
    |ξ + η| < (2 : ℝ) ^ (j + 1) + (2 : ℝ) ^ (k + 1) ∧
      (2 : ℝ) ^ (j + 1) + (2 : ℝ) ^ (k + 1) ≤ (2 : ℝ) ^ (j + 2) := by
  refine ⟨lt_of_le_of_lt (abs_add_le ξ η) (add_lt_add hξ hη), ?_⟩
  have h2 : (2 : ℝ) ^ (j + 2) = 2 * (2 : ℝ) ^ (j + 1) := by
    rw [← zpow_one_add₀ (by norm_num : (2:ℝ) ≠ 0)]; ring_nf
  have h3 : (2 : ℝ) ^ (k + 1) ≤ (2 : ℝ) ^ (j + 1) :=
    zpow_le_zpow_right₀ (by norm_num) (by omega)
  linarith

-- Worked numbers: the whistle (3,500 Hz) is in band 11 and the bass (55 Hz) in band 5.
example : 2 ^ 11 ≤ 3500 ∧ 3500 < 2 ^ 12 := by norm_num
example : 2 ^ 5 ≤ 55 ∧ 55 < 2 ^ 6 := by norm_num
-- 11 ≥ 5 + 2: the whistle is the high factor, so the product is in the high-low pile.
example : 5 + 2 ≤ 11 := by norm_num
-- The product's lines, 3,500 - 55 and 3,500 + 55 Hz, both lie in band 11.
example : 3500 - 55 = 3445 ∧ 3500 + 55 = 3555 := by norm_num
example : 2 ^ 11 ≤ 3445 ∧ 3555 < 2 ^ 12 := by norm_num
-- Each line has height 1/4 V² and mean square (1/4)²/2 = 1/32; the product's is 1/16.
example : ((1 : ℚ) / 2 * 1 / 2) ^ 2 / 2 = 1 / 32 := by norm_num
example : (1 : ℚ) / 32 + 1 / 32 = 1 / 16 := by norm_num
-- Two tracks: the bass (band 5) times the A (440 Hz, band 8) gives 385 and 495 Hz, in band 8.
example : 2 ^ 8 ≤ 440 ∧ 440 < 2 ^ 9 := by norm_num
example : 440 - 55 = 385 ∧ 440 + 55 = 495 ∧ 2 ^ 8 ≤ 385 ∧ 495 < 2 ^ 9 := by norm_num
-- 3,500 and 3,000 Hz are both band 11; they give 500 Hz (band 8) and 6,500 Hz (band 12).
example : 2 ^ 11 ≤ 3000 ∧ 3000 < 2 ^ 12 := by norm_num
example : 3500 - 3000 = 500 ∧ 2 ^ 8 ≤ 500 ∧ 500 < 2 ^ 9 := by norm_num
example : 3500 + 3000 = 6500 ∧ 2 ^ 12 ≤ 6500 ∧ 6500 < 2 ^ 13 := by norm_num
-- Line mean squares: bass x A gives (1 · 3/5 / 2)²/2 = 9/200 V⁴ per line.
example : ((1 : ℚ) * (3 / 5) / 2) ^ 2 / 2 = 9 / 200 := by norm_num
example : ((1 : ℚ) * (2 / 5) / 2) ^ 2 / 2 = 1 / 50 := by norm_num
example : ((1 : ℚ) / 2 * (3 / 5) / 2) ^ 2 / 2 = 9 / 800 := by norm_num
example : ((1 : ℚ) / 2 * (2 / 5) / 2) ^ 2 / 2 = 1 / 200 := by norm_num
-- The piles hold 13/100, 9/400 and 1/100 V⁴, adding to the total 13/80 V⁴.
example : (2 : ℚ) * (9 / 200) + 2 * (1 / 50) = 13 / 100 := by norm_num
example : (2 : ℚ) * (9 / 800) = 9 / 400 ∧ (2 : ℚ) * (1 / 200) = 1 / 100 := by norm_num
example : (13 : ℚ) / 100 + 9 / 400 + 1 / 100 = 13 / 80 := by norm_num
-- Dropping the high-high pile keeps 61/400 of 13/80 V⁴.
example : (13 : ℚ) / 100 + 9 / 400 = 61 / 400 ∧ (13 : ℚ) / 80 - 61 / 400 = 1 / 100 := by norm_num

#print axioms bony_split_exact
#print axioms low_high_term_stays_near_band
#print axioms high_high_term_upper_band
```

**Checked 2026-11-24 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'bony_split_exact' depends on axioms: [propext, Classical.choice, Quot.sound]
'low_high_term_stays_near_band' depends on axioms: [propext, Classical.choice, Quot.sound]
'high_high_term_upper_band' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then read the answer from the `try:` lines.
> - **Raise the bass.** In the first pair, change `(1, 55)` to `(1, 1500)`. Guess first: 1,500 Hz is band 10, within one band of the whistle. The whole product moves to the high-high pile, at 2,000 Hz and 5,000 Hz, mean square 1/16 still. A "bass" one band below the whistle is no longer a volume knob.
> - **Refine the grid.** The `try:` rows run 4,096 points, `n = 12`. Guess first: for $`\log_2(1/x)`$ on 4,096 points, $`C_b = 2.0780`$ and the norm 2.1149, still under 2.8854, while $`\sup\lvert b\rvert`$ is 13. For the square, $`C_b`$ jumps to 731.9152 and the norm to 36.3328.
> - **Double the bass.** In the first pair, change `(1, 55)` to `(2, 55)`. Guess first: the lines stay at 3,445 Hz and 3,555 Hz, each 1/8 V⁴, total 1/4: the low factor scales the volume, never the frequency.

---

## The usual mistake

> [!warning]
> **Treating a product as if both factors were equally high.** Multiplying by a slow signal does not spread a high tone across the spectrum: the whistle times the bass stays in the whistle's octave, at 3,445 and 3,555 Hz. Only the high-high pile moves energy to new octaves, down as easily as up.
>
> - **Forgetting the high-high pile.** The other two piles of the two tracks hold 61/400 V⁴ of 13/80.
> - **Asking for a bounded b.** The paraproduct needs only BMO. For $`\log_2(1/x)`$ on 1,024 points the norm is 2.0356 while $`\sup\lvert b\rvert`$ is 11.
> - **Reading one test signal as the norm.** $`1_J`$ gives at least $`C_b`$ = 2.0699; the squared norm is 4.1436.

---

## Where you meet it in real life

- **AM radio and ring modulators.** A voice signal times a carrier far above it is a high-low product: it sits at the carrier plus and minus the voice, within the voice's bandwidth of the carrier, where the receiver is tuned.
- **Nonlinear wave and fluid equations.** Navier–Stokes and nonlinear Schrödinger equations multiply the unknown by itself. The product rule keeps those products as smooth as the factors, so solutions stay in their space for a time. Bony built his paradifferential calculus on this split.
- **Commutators in analysis.** The commutator $`[H, b]f = H(bf) - b\,Hf`$ of the Hilbert transform $`H`$ with multiplication by b is bounded exactly when b is in BMO. Its proof splits the commutator into paraproducts.

> **Say it back**
> Cut each factor into octave bands and sort every pair of bands: low-high, high-low or high-high, an exact split. In the first two the higher factor alone sets the output's octave, as the whistle times the 55 Hz bass stays at 3,445 and 3,555 Hz. The paraproduct, b high and f low, is bounded in energy exactly when b has bounded mean oscillation, because the squared norm is a Carleson sum of b's pieces against f's averages. The high-high pile can send energy to low octaves, which is why the product rule needs s > 0.

---

## What this builds on

- [Littlewood-Paley](02-littlewood-paley-theory.md): cuts a signal into octave bands $`\Delta_j f`$ and shows their energies add; this card multiplies two such cuts.
- [Fourier multipliers](01-mihlin-hormander-multiplier-theorem.md): the one-signal condition on a symbol's derivatives; Coifman–Meyer is its two-signal form.
- [BMO](../06-Maximal%20Functions%20and%20Beyond/09-bmo-and-the-john-nirenberg-inequality.md): defines bounded mean oscillation, the exact condition for the paraproduct's energy bound.
- [The Hardy space H¹](../06-Maximal%20Functions%20and%20Beyond/10-hardy-space-h1-and-its-duality-with-bmo.md): the space whose dual is BMO; in dual form the paraproduct pairs b with a signal in H¹.

## Where this goes next

- [The T(1) theorem](04-the-t1-theorem.md): the next card. A paraproduct $`\pi_b`$ is a singular integral with $`\pi_b 1 = b`$, up to its lowest bands, and $`\pi_b^* 1 = 0`$. So subtracting $`\pi_{T1}`$ reduces any singular integral to one with $`T1 = 0`$.
- [Pseudodifferential operators](05-pseudodifferential-operators.md): symbols that change with position; Bony's split is how they act on products.

Left open: the high-high pile has no fixed octave. When the two factors are rough, at $`s \le 0`$, what replaces the product rule, and when is the product defined at all?

---

## Sources

Verified 2026-11-24: every link below resolves to the publisher's page.

- Coifman, R. R., and Y. Meyer. "On commutators of singular integrals and bilinear singular integrals." *Transactions of the American Mathematical Society* 212 (1975): 315–331. [doi:10.1090/S0002-9947-1975-0380244-8](https://doi.org/10.1090/S0002-9947-1975-0380244-8). The first bounds for bilinear multipliers of this kind, through commutators.
- Coifman, R. R., and Y. Meyer. *Au delà des opérateurs pseudo-différentiels*. Astérisque 57, Société Mathématique de France, 1978. [numdam.org/item/AST_1978__57__1_0](http://www.numdam.org/item/AST_1978__57__1_0/). The bilinear multiplier theorem and paraproducts in full.
- Bony, J.-M. "Calcul symbolique et propagation des singularités pour les équations aux dérivées partielles non linéaires." *Annales scientifiques de l'École normale supérieure* 14 (1981): 209–246. [doi:10.24033/asens.1404](https://doi.org/10.24033/asens.1404). The three-piece split and the paradifferential calculus for nonlinear equations.
- Fefferman, C., and E. M. Stein. "Hᵖ spaces of several variables." *Acta Mathematica* 129 (1972): 137–193. [doi:10.1007/BF02392215](https://doi.org/10.1007/BF02392215). BMO as the dual of H¹ and its characterisation by Carleson measures.
- Grafakos, L. *Modern Fourier Analysis*, 3rd edition. Springer, Graduate Texts in Mathematics 250, 2014. [doi:10.1007/978-1-4939-1230-8](https://doi.org/10.1007/978-1-4939-1230-8). Chapter 3 treats BMO and Carleson measures; chapter 7, multilinear harmonic analysis, treats the Coifman–Meyer theorem.
