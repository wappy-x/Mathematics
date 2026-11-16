# Plancherel: the transform preserves energy, and extends to every square-integrable signal

[Syllabus](../../../SYLLABUS.md) → [Harmonic analysis](../README.md) → [The Fourier Transform](../README.md#s02) → Plancherel

---

## General Overview

A guitarist plucks the open A string, which rings at 110 Hz. The pickup's voltage is a sine wave that starts at 1 V and shrinks in size by a factor of e (about 2.718) every second. Before the pluck it is 0 V. The numbers are illustrative.

The note's **energy** is the area under the square of the voltage over all time. Here it is 0.249999 V²·s: about a quarter of a joule if the voltage drove a 1-ohm load.

The Fourier transform splits the same note into frequencies. It shows two sharp peaks, at +110 Hz and −110 Hz, each 0.5 V·s high. Each peak falls to half power only 0.159155 Hz from its centre (its half-power half-width). Add up the square of the transform over every frequency, and the total is 0.249999477 V²·s. That matches the time side to nine digits. About nine tenths of it, 89.9528 %, sits within 1 Hz of the two peaks.

**Plancherel's theorem** says this is no coincidence: energy counted second by second always equals energy counted hertz by hertz. The card proves it in two moves.

1. **Prove it on rapidly decreasing signals**, smooth signals that fade faster than any power of time. On these the transform integral and its inverse always converge and undo each other, and one swap of integrals gives the identity.
2. **Extend by limits.** Every finite-energy signal can be approached as closely as wanted, in energy, by rapidly decreasing ones. Because the transform keeps energy, it keeps distances, so the transforms of close signals are close and settle on a limit. That limit is the transform of every finite-energy signal, including ones where the transform integral itself fails.

The guitar note needs the second move. Its slope jumps at the pluck, so it is not rapidly decreasing, yet it keeps its energy exactly.

**For every rapidly decreasing signal, the energy summed over frequencies equals the energy summed over time; because these signals come as close as wanted in energy to every square-integrable signal, the transform extends by limits to a map on all square-integrable signals that keeps every energy and every distance.**

**What kind of fact this is:** a theorem (Plancherel's), proved on this card in Why it works. Two ingredients are proved on linked cards: inversion for rapidly decreasing signals ([Fourier inversion](04-fourier-inversion-theorem.md)), and the fact that finite-energy signals have no holes ([Riesz-Fischer](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/05-completeness-of-lp.md)).

### The picture: where the note's energy sits

```
share of the note's energy within d Hz of 110 Hz (both peaks counted)
d = 0.1 Hz   ██████████████                              35.7133 %
d = 0.5 Hz   ████████████████████████████████            80.3817 %
d = 1 Hz     ████████████████████████████████████        89.9528 %
d = 5 Hz     ███████████████████████████████████████     97.9774 %
d = 50 Hz    ████████████████████████████████████████    99.8299 %
```

Each bar is the area under the squared transform over the band, divided by the time-side energy. Both checks print every value.

---

## The formula

Notation first, in words.

- $`t`$ is time in seconds and $`\xi`$ (xi) is frequency in hertz. The transform is $`\hat f(\xi) = \int f(t)\, e^{-2\pi i \xi t}\, dt`$, fixed on [The Fourier transform of an absolutely integrable signal, and why it fades at infinity](01-fourier-transform-on-l1-and-riemann-lebesgue.md). The **inverse** of a frequency function $`g`$ is $`\check g(t) = \int g(\xi)\, e^{2\pi i \xi t}\, d\xi`$, with no factor in front ([Fourier inversion](04-fourier-inversion-theorem.md)).
- $`L^2(\mathbb{R})`$ is the set of **square-integrable signals** on the whole time line: signals whose energy $`\|f\|_2^2 = \int |f(t)|^2\, dt`$ is finite. Two signals that differ only on a set of total length zero count as one ([Lp spaces](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/01-lp-spaces.md)).
- The **inner product** $`\langle f, g\rangle = \int f(t)\, \overline{g(t)}\, dt`$ is linear in $`f`$; the bar is the complex conjugate. So $`\langle f, f\rangle = \|f\|_2^2`$, and $`\|f - g\|_2`$ is the **distance** between two signals.
- A **rapidly decreasing signal** is smooth, and it and every derivative fade faster than any power of $`1/|t|`$. The bell $`e^{-\pi t^2}`$ is one. The set of them is the Schwartz space $`\mathcal{S}`$, defined on [Tempered distributions](../../18-Functional%20analysis/04-Distributions%20and%20Sobolev%20Spaces/05-tempered-distributions-and-the-fourier-transform.md). The transform sends $`\mathcal{S}`$ into itself.
- $`\mathcal{F}`$ is **the transform on all of** $`L^2(\mathbb{R})`$, built on this card. On signals with finite area under $`|f|`$ it equals the hat.

The energy identity on rapidly decreasing signals:

```math
\int_{-\infty}^{\infty} |\hat f(\xi)|^2\, d\xi \;=\; \int_{-\infty}^{\infty} |f(t)|^2\, dt, \qquad f \in \mathcal{S}
```

**Read it aloud:** the area under the squared transform, over all frequencies in hertz, equals the area under the squared signal, over all time.

The extension to every square-integrable signal:

```math
\mathcal{F}f = \lim_{n \to \infty} \hat\varphi_n \ \text{ in energy, where } \varphi_n \in \mathcal{S},\ \|\varphi_n - f\|_2 \to 0; \qquad \|\mathcal{F}f - \mathcal{F}g\|_2 = \|f - g\|_2
```

**Read it aloud:** to transform any finite-energy signal, approach it by rapidly decreasing signals and take the limit of their transforms in energy; the result keeps the distance between every two signals.

On the note: $`\|f\|_2^2 = 0.249999477`$ V²·s, and the area under $`|\hat f|^2`$ is 0.249999477 V²·s.

[Plancherel](../../18-Functional%20analysis/03-Bounded%20Operators/04-the-fourier-transform-as-a-unitary-operator.md) on the functional-analysis wing proved the same fact in the ω form, with ω in radians per second: $`\int |F(\omega)|^2\, d\omega = 2\pi \|f\|_2^2`$. In this wing's hertz form the factor is 1, because $`\omega = 2\pi\xi`$ stretches the frequency axis by exactly $`2\pi`$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`t`$, $`\xi`$, $`\omega`$ | time in seconds; frequency in hertz; frequency in radians per second | pluck at $`t = 0`$; peaks at $`\xi = \pm 110`$ | — |
| $`f`$, $`\hat f`$, $`F`$ | the signal in volts; its transform in V·s; the transform in the ω form, $`F(\omega) = \hat f(\omega/2\pi)`$ | the note; $`\lvert \hat f(110)\rvert = 0.5`$ V·s | energy grows with the square of the size |
| $`A`$, $`f_0`$, $`\tau`$ | the note's starting size, pitch and decay time | 1 V, 110 Hz, 1 s | longer $`\tau`$: more energy, narrower peaks |
| $`b`$ | $`2\pi f_0 \tau`$, the phase turned in one decay time | 691.150384 | energy nears $`\tau/4`$ |
| $`\check g`$; $`g`$, $`h`$ | the inverse transform of $`g`$; other signals or spectra | $`\check{\hat f} = f`$ on $`\mathcal{S}`$ | — |
| $`\mathcal{S}`$, $`\varphi_n`$, $`\psi_n`$ | rapidly decreasing signals; sequences of them, term $`n`$ or $`m`$ | the smoothed notes $`f_\varepsilon`$ | later terms: closer to the target |
| $`L^2(\mathbb{R})`$, $`\lVert f\rVert_2`$ | finite-energy signals; square root of the energy | $`\lVert f\rVert_2^2 = 0.249999477`$ V²·s | — |
| $`\langle f, g\rangle`$ | inner product: area under $`f`$ times conjugate $`g`$ | $`\langle f, f\rangle`$ is the energy | — |
| $`\mathcal{F}`$, $`\mathcal{F}^{-1}`$ | the transform on all of $`L^2(\mathbb{R})`$; its inverse | $`\mathcal{F}f = \hat f`$ for the note | — |
| $`\varepsilon`$, $`G_\varepsilon`$, $`f_\varepsilon`$ | bell width in seconds; the bell $`e^{-\pi t^2/\varepsilon^2}/\varepsilon`$, area 1; the note smoothed by it | $`\varepsilon = 1`$ ms keeps 0.231708111 V²·s | wider bell: farther from the note |
| $`T`$ | the shutter's opening time | 1 ms; energy 0.001 V²·s | spectrum narrows like $`1/T`$ |
| $`i`$, $`a`$, $`c`$, $`L`$, $`d`$, $`\theta`$ | the imaginary unit; any two numbers; a cut-off time; a band's half-width in Hz; the code's angle | $`d = 1`$ Hz holds 89.9528 % | — |

### When it holds

- **Finite energy.** A string that never decays has energy 0.5, 5 and 50 V²·s over its first 1, 10 and 100 seconds, growing without end. It is not in $`L^2(\mathbb{R})`$, and its spectrum is a pair of spikes, not a function ([Schwartz space and tempered distributions](06-schwartz-space-and-tempered-distributions.md)).
- **The hertz form, or the factor.** In the ω form the squared transform's area is $`2\pi`$ times the energy: 1.570793 for the note, not 0.249999.
- **The integral formula needs finite area under $`|f|`$.** The shutter's spectrum, read as a signal, has finite energy but its area grows by 0.933 V for every tenfold widening of the band. So the transform integral is not absolutely convergent, and the hat's definition does not apply; the limit $`\mathcal{F}`$ still defines its transform.
- **Equality in energy, not at each frequency.** $`\mathcal{F}f`$ is a limit in energy, so it is fixed only up to sets of total length zero. Its value at one single frequency means nothing, unless $`f`$ also has finite area; then $`\mathcal{F}f`$ is the continuous function $`\hat f`$.

---

## Why it works

### Step 0: the transform moves across an integral

Energy is a signal's inner product with itself. Two facts let the transform move from one side of that inner product to the other.

1. **The swap.** In $`\int \hat f(\xi)\, g(\xi)\, d\xi`$ the transform can be moved onto $`g`$: the result is $`\int f(t)\, \hat g(t)\, dt`$. This is one exchange of the order of integration.
2. **Inversion turns a conjugate around.** Take $`g = \overline{\hat f}`$. Its transform is $`\overline{f}`$, because transforming a conjugate is inverting and then conjugating, and inversion brings $`f`$ back.

Put together, $`\int \hat f\, \overline{\hat f} = \int f\, \overline f`$: the energy identity. Both facts need integrals that converge, which rapidly decreasing signals guarantee. Then a limit carries the identity to every finite-energy signal.

### Step 1: the swap

Let $`f`$ and $`g`$ have finite area under their size: $`\int |f| < \infty`$ and $`\int |g| < \infty`$. Then

```math
\int_{-\infty}^{\infty} \hat f(\xi)\, g(\xi)\, d\xi \;=\; \int\!\!\int f(t)\, e^{-2\pi i \xi t}\, g(\xi)\, dt\, d\xi \;=\; \int_{-\infty}^{\infty} f(t)\, \hat g(t)\, dt .
```

**Read it aloud:** weighting the transform of $`f`$ by $`g`$ gives the same total as weighting $`f`$ by the transform of $`g`$.

The size of the double integrand is $`|f(t)|\,|g(\xi)|`$, whose double area is $`\int|f| \times \int|g|`$, finite. So the order of integration may be swapped (Fubini's theorem), and the inner integral over $`\xi`$ is exactly $`\hat g(t)`$.

### Step 2: Plancherel on rapidly decreasing signals

Let $`f`$ and $`h`$ be rapidly decreasing. Their transforms are rapidly decreasing too, so every integral below converges. Put $`g = \overline{\hat h}`$ in Step 1. Its transform is

```math
\hat g(t) = \int \overline{\hat h(\xi)}\, e^{-2\pi i \xi t}\, d\xi = \overline{\int \hat h(\xi)\, e^{2\pi i \xi t}\, d\xi} = \overline{h(t)},
```

where the last step is [Fourier inversion](04-fourier-inversion-theorem.md). Step 1 then reads

```math
\langle \hat f, \hat h\rangle = \int \hat f\, \overline{\hat h}\, d\xi = \int f\, \overline{h}\, dt = \langle f, h\rangle .
```

**Read it aloud:** the transform keeps the inner product of every two rapidly decreasing signals.

Put $`h = f`$ and this is the energy identity. Put $`h`$ equal to a shifted copy of $`f`$ and it says the transform also keeps the overlap between a signal and its echo.

### Step 3: the guitar note, three ways

The note is $`f(t) = A\, e^{-t/\tau} \sin(2\pi f_0 t)`$ for $`t \ge 0`$ and 0 before, with $`A = 1`$ V, $`f_0 = 110`$ Hz and $`\tau = 1`$ s. It is not rapidly decreasing: its slope jumps from 0 to $`2\pi f_0 A`$, about 691 V/s, at the pluck. Step 2 does not cover it yet, so it is a fair test of what Steps 4 and 5 add.

Its transform has a closed form, two fractions, one per peak:

```math
\hat f(\xi) = \frac{A}{2i}\left(\frac{1}{1/\tau + 2\pi i(\xi - f_0)} - \frac{1}{1/\tau + 2\pi i(\xi + f_0)}\right).
```

**Read it aloud:** a narrow peak centred at +110 Hz minus a narrow peak centred at −110 Hz, each of width set by the decay rate $`1/\tau`$.

The code reaches the energy three ways. Simpson's rule, used throughout, adds up equally spaced samples with weights 1, 4, 2, 4, …, 1 to approximate an area.

- **Time, exactly.** The integral of $`e^{-2t/\tau}\sin^2(2\pi f_0 t)`$ has the closed form $`(\tau/4)\, b^2/(1+b^2)`$ with $`b = 2\pi f_0\tau = 691.150384`$. That is 0.249999477 V²·s. Simpson's rule on 0 to 10 s agrees, with a tail of at most $`1.03 \times 10^{-9}`$.
- **Frequency.** Simpson's rule on $`|\hat f|^2`$ over all frequencies gives 0.249999478 at 2000 steps and 0.249999477 at 4000. Each squared peak is a bell-shaped curve called a Lorentzian, with area $`\tau/8 = 0.125`$. A small cross term between the two peaks accounts for the gap below 0.25.
- **Samples.** Sample the note 4096 times a second for 8 s, and take a written-out fast Fourier transform (FFT) of the 32,768 samples. The finite version of Plancherel holds exactly: both sides read 0.249999448. The gap from the true energy, $`-2.82 \times 10^{-8}`$, is the cost of sampling and of cutting at 8 s. At 110 Hz the scaled FFT reads 0.499832. That is $`|\hat f(110)| = 0.5`$ times $`1 - e^{-8}`$, the part of the peak left after the 8 s cut, and an assert holds the two within $`10^{-6}`$. So the FFT really computes the transform, not just some energy-keeping map.

### Step 4: rapidly decreasing signals come close to everything

Smooth the note with a narrow bell. The bell $`G_\varepsilon(t) = e^{-\pi t^2/\varepsilon^2}/\varepsilon`$ has area 1 and width about $`\varepsilon`$. The smoothed note $`f_\varepsilon`$ is the note averaged against the bell at each moment (a convolution, $`f_\varepsilon = f * G_\varepsilon`$). It has no kink, and it fades like the note on the right and like the bell on the left, so it is rapidly decreasing.

Its transform is the note's transform times the bell's, $`\hat f(\xi)\, e^{-\pi\varepsilon^2\xi^2}`$, by Step 1's exchange of integrals and the bell pair on [Two pairs worth memorising](03-gaussian-and-sinc-transform-pairs.md). The smoothed notes are rapidly decreasing, so Step 2 covers them and their differences. Their energies and the distances between two of them are areas in frequency.

The distance from a smoothed note to the note itself is different. The note is not rapidly decreasing, so reading that distance in frequency would assume what Step 5 proves. The code measures $`\lVert f - f_\varepsilon\rVert_2^2`$ in time instead. It builds $`f_\varepsilon`$ by integrating the note against the bell: by Simpson's rule near the pluck, and in closed form after $`6\varepsilon`$, where the bell no longer reaches back to the kink.

| bell width $`\varepsilon`$ | gain at 110 Hz | energy of $`f_\varepsilon`$, V²·s | $`\lVert f - f_\varepsilon\rVert_2^2`$, in time | the same, as an area in frequency | distance² to the row above |
| --- | --- | --- | --- | --- | --- |
| 10 ms | 0.022341 | 0.000303749 | $`2.385 \times 10^{-1}`$ | $`2.385 \times 10^{-1}`$ | — |
| 1 ms | 0.962700 | 0.231708111 | $`3.507 \times 10^{-4}`$ | $`3.507 \times 10^{-4}`$ | $`2.207 \times 10^{-1}`$ |
| 0.1 ms | 0.999620 | 0.249809494 | $`3.945 \times 10^{-8}`$ | $`3.945 \times 10^{-8}`$ | $`3.436 \times 10^{-4}`$ |
| 0.01 ms | 0.999996 | 0.249997576 | $`6.954 \times 10^{-12}`$ | $`6.954 \times 10^{-12}`$ | $`3.862 \times 10^{-8}`$ |

A 10 ms bell is wider than one cycle of the note (1/110 s), so it averages the tone away. From 1 ms down, the smoothed notes close in on the note, measured in time, and on each other. Each tenfold narrower bell cuts the distance less than 10,000-fold: the smooth part of the note shrinks like $`\varepsilon^4`$, but the kink at the pluck only like $`\varepsilon^3`$.

The frequency column agrees with the time column at every width, and an assert holds them within 0.1 %. That is Plancherel for the note's error $`f - f_\varepsilon`$: confirmed here, proved in Step 5, never used. As a check of Step 2 at 1 ms, the energy of $`f_\varepsilon`$ built in time is 0.231708111, the same as in frequency.

The same works for every finite-energy signal. [Riesz-Fischer](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/05-completeness-of-lp.md) shows that continuous signals that are zero outside a bounded interval come as close as wanted in energy. Smoothing such a signal by a narrow bell gives a rapidly decreasing signal, as close again as wanted. So $`\mathcal{S}`$ is **dense** in $`L^2(\mathbb{R})`$: every finite-energy signal is an energy-limit of rapidly decreasing ones.

### Step 5: extending by limits

Take any $`f`$ in $`L^2(\mathbb{R})`$ and rapidly decreasing $`\varphi_n`$ with $`\|\varphi_n - f\|_2 \to 0`$. The transform is linear, so Step 2 gives

```math
\|\hat\varphi_n - \hat\varphi_m\|_2 = \|\varphi_n - \varphi_m\|_2 .
```

The right side goes to 0, so the transforms crowd together: they form a **Cauchy sequence** (late terms are close to each other). $`L^2(\mathbb{R})`$ has no holes ([Riesz-Fischer](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/05-completeness-of-lp.md)), so they converge in energy. Call the limit $`\mathcal{F}f`$.

Three things follow, each proved in the fold.

- **The limit does not depend on the sequence.** Two sequences aimed at $`f`$ have transforms whose distance goes to 0.
- **Energy and distance are kept.** $`\|\mathcal{F}f\|_2 = \lim \|\hat\varphi_n\|_2 = \lim\|\varphi_n\|_2 = \|f\|_2`$, and by linearity $`\|\mathcal{F}f - \mathcal{F}g\|_2 = \|f - g\|_2`$.
- **Where the integral works, it agrees.** If $`f`$ also has finite area under $`|f|`$, then $`\mathcal{F}f = \hat f`$.

For the note, the table's time column shows $`f_\varepsilon \to f`$ in energy, with no transform involved. So Step 5 makes $`\mathcal{F}f`$ the energy-limit of $`\hat f_\varepsilon = \hat f\, e^{-\pi\varepsilon^2\xi^2}`$. The frequency column shows those spectra closing in on the closed-form $`\hat f`$ in energy, so the two limits are one signal. $`\mathcal{F}`$ of the note is the closed form, as the fold's last part says for every signal with finite area, and its energy is the time-side 0.249999477.

<details>
<summary>Detailed proof: the extension is well defined, keeps distances, and agrees with the integral</summary>

**Well defined.** Let $`\varphi_n \to f`$ and $`\psi_n \to f`$ in energy, both rapidly decreasing. By Step 2 and the triangle inequality,

$`\displaystyle \|\hat\varphi_n - \hat\psi_n\|_2 = \|\varphi_n - \psi_n\|_2 \le \|\varphi_n - f\|_2 + \|f - \psi_n\|_2 \to 0 .`$

So the two limits are the same signal.

**Linear and distance-keeping.** If $`\varphi_n \to f`$ and $`\psi_n \to g`$, then $`a\varphi_n + c\psi_n \to af + cg`$ for any numbers $`a`$ and $`c`$, so $`\mathcal{F}(af + cg) = a\mathcal{F}f + c\mathcal{F}g`$. The norm is continuous, so $`\|\mathcal{F}f\|_2 = \lim\|\hat\varphi_n\|_2 = \lim\|\varphi_n\|_2 = \|f\|_2`$. Apply this to $`f - g`$.

**Agreement with the integral.** Let $`f`$ have finite energy and finite area. Cut it to $`[-L, L]`$, approximate the cut signal by a continuous signal that is zero outside a bounded interval, and smooth that by a narrow bell. Each move can be made small in area and in energy at once, so there are rapidly decreasing $`\varphi_n`$ with $`\int|\varphi_n - f| \to 0`$ and $`\|\varphi_n - f\|_2 \to 0`$.

The first limit gives, at every frequency,

$`\displaystyle |\hat\varphi_n(\xi) - \hat f(\xi)| \le \int |\varphi_n(t) - f(t)|\, dt \to 0 .`$

The second gives $`\hat\varphi_n \to \mathcal{F}f`$ in energy. [Riesz-Fischer](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/05-completeness-of-lp.md) shows a sequence converging in energy has a subsequence converging at almost every point, and there it converges to $`\hat f`$. So $`\mathcal{F}f = \hat f`$ except on a set of total length zero.

</details>

### Step 6: the map is onto, so it can be undone

The inverse transform extends in the same way, from $`\mathcal{S}`$ to an energy-keeping map on all of $`L^2(\mathbb{R})`$. On $`\mathcal{S}`$ the two undo each other ([Fourier inversion](04-fourier-inversion-theorem.md)). Both extended maps keep distances, so they are continuous, and two continuous maps that agree on a dense set agree everywhere. So $`\mathcal{F}`$ is one to one and onto: every finite-energy spectrum belongs to exactly one finite-energy signal.

The shutter shows why this matters. Its spectrum $`\sin(\pi\xi T)/(\pi\xi)`$, with $`T = 1`$ ms, has energy 0.001 V²·s, and 90.2823 % of it sits below 1 kHz. Read as a signal, it has no finite area: 2.105726, 3.038857 and 3.972059 V over bands of 10, 100 and 1000 kHz. The inverse integral of this spectrum is not absolutely convergent, so it is not a Lebesgue integral, yet $`\mathcal{F}^{-1}`$ turns it back into the 1 ms gate.

A map that keeps every distance and is onto is called **unitary**. That operator view, with its adjoint and its quarter-turn eigenvalues, is the subject of [Plancherel](../../18-Functional%20analysis/03-Bounded%20Operators/04-the-fourier-transform-as-a-unitary-operator.md).

---

## Worked numbers, by hand

The energy of the note, once in time and once in frequency.

| Step | Arithmetic | Value |
| --- | --- | --- |
| phase turned in one decay time | $`b = 2\pi \times 110 \times 1`$ | 691.150384 |
| correction factor | $`b^2/(1 + b^2)`$ | 0.999997907 |
| energy in time | $`(\tau/4) \times 0.999997907`$ | **0.249999477 V²·s** |
| one peak in frequency | Lorentzian area $`\tau/8`$ | 0.125 V²·s |
| two peaks, by Simpson's rule | 2 × 0.125, less a small cross term | **0.249999477 V²·s** |
| share within 1 Hz of 110 Hz | $`(2/\pi)\arctan(2\pi)`$, one peak's Lorentzian | 89.9522 % (exact 89.9528 %) |

Counted second by second or hertz by hertz, the note holds 0.249999477 V²·s, and nine tenths of it lives within 1 Hz of the pitch.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| ω form with no $`1/2\pi`$ | 1.570793 against 0.249999 | $`d\omega = 2\pi\, d\xi`$ stretches the frequency axis by $`2\pi`$ |
| A string that never decays | 0.5, 5, 50 V²·s over 1, 10, 100 s | infinite energy: not in $`L^2(\mathbb{R})`$ |
| The integral formula on the shutter's spectrum as a signal | area 2.105726, 3.038857, 3.972059 V, no limit | finite energy but infinite area; only the limit $`\mathcal{F}`$ applies |
| Counting positive frequencies only | 0.125000 against 0.249999 | a real signal has $`\lvert\hat f(-\xi)\rvert = \lvert\hat f(\xi)\rvert`$, so half its energy is at negative $`\xi`$ |

The code prints all four.

---

## Code, from first principles, and it actually runs

The code takes four roads to the note's energy. The closed form and Simpson's rule work in time. Simpson's rule on the closed-form transform works in frequency, after the substitution $`\xi = f_0 + \tan(\theta)/(2\pi\tau)`$, which flattens the narrow peak. Above 1 kHz a second substitution spreads the steps out to infinity, so they reach far past $`1/\varepsilon`$, where a narrow bell's cut sets in. A written-out FFT of the samples gives the finite version. It then smooths the note by bells to show density. The distance to the note is measured in time and checked against frequency, and one smoothed note's energy is checked both ways. Last it measures the shutter's spectrum. Both programs print the same lines.

### Python

```python
# Plancherel -- the check behind the card.  Standard library only.
# The note: f(t) = A e^(-t/tau) sin(2 pi f0 t) for t >= 0, 0 before the pluck,
# with A = 1 V, f0 = 110 Hz, tau = 1 s (illustrative).  Hertz form:
# fhat(xi) = integral f(t) e^(-2 pi i xi t) dt, xi in hertz, energy in V^2 s.
# Roads: energy in time, closed form and Simpson; in frequency, Simpson on the
# closed-form fhat; a written-out FFT; smoothed notes built in time by Simpson.
# Nothing imported knows the answer: math gives exp, sin, cos, atan, tan, sqrt, pi.
import math
PI, A, F0, TAU = math.pi, 1.0, 110.0, 1.0
AL = 1 / TAU                                   # decay rate, per second
S = complex(-AL, 2 * PI * F0)                  # the note is Im(A e^(S t)) for t >= 0
cis = lambda a: complex(math.cos(a), math.sin(a))

def simpson(g, a, b, m):                       # Simpson's rule, m even slices
    h, s = (b - a) / m, g(a) + g(b)
    for k in range(1, m):
        s += (4 if k % 2 else 2) * g(a + k * h)
    return s * h / 3

def note(t): return A * math.exp(-t / TAU) * math.sin(2 * PI * F0 * t) if t >= 0 else 0.0

def fhat(xi):                                  # closed form, a complex number
    p, q = 1 / complex(AL, 2 * PI * (xi - F0)), 1 / complex(AL, 2 * PI * (xi + F0))
    return A * (p - q) / 2j
power = lambda xi: abs(fhat(xi)) ** 2

def band(lo, hi, w, m):                       # integral of power * w over lo..hi Hz
    th = lambda xi: math.atan(2 * PI * (xi - F0) / AL)  # xi = F0 + (AL/2pi) tan(th):
    def g(u):                                           # flattens the peak at F0
        xi = F0 + AL / (2 * PI) * math.tan(u)
        return power(xi) * w(xi) * AL / (2 * PI) / math.cos(u) ** 2
    return simpson(g, th(lo), th(hi), m)

def freq_int(w, m):                            # all xi: power is even in xi
    cuts = (0, F0 - 1, F0 + 1, 1e3)            # three pieces, peak in the middle
    top = lambda u: power(1e3 / u ** 4) * w(1e3 / u ** 4) * 4e3 / u ** 5 if u else 0.0
    s = sum(band(cuts[i], cuts[i + 1], w, m) for i in range(3)) + simpson(top, 0, 1, m)
    return 2 * s                               # last piece: xi = 1 kHz / u^4, out to infinity

def in_time(e, c):                             # energy of c f - f_eps, in time: no transform
    m, G = 6 * e, lambda u: math.exp(-PI * u * u / (e * e)) / e   # the bell, cut at 6 eps
    fe = lambda t: simpson(lambda u: note(t - u) * G(u), -m, min(t, m), 400) if t > -m else 0.0
    g = lambda t: (c * note(t) - fe(t)) ** 2   # fe(t) = f_eps(t) = integral f(t - u) G(u) du
    K = simpson(lambda u: cis(-S.imag * u) * math.exp(AL * u) * G(u), -m, m, 400)
    D, E = A * (c - K), cis(2 * S.imag * m) * math.exp(-2 * AL * m)  # past m: Im(D e^(S t))
    far = (abs(D) ** 2 * math.exp(-2 * AL * m) / (2 * AL) + (D * D * E / (2 * S)).real) / 2
    return simpson(g, -m, 0, 400) + simpson(g, 0, m, 400) + far   # near part split at the kink

def fft(x):                                    # radix-2, written out
    n = len(x)
    if n == 1:
        return x
    ev, od = fft(x[0::2]), fft(x[1::2])
    out = [0j] * n
    for k in range(n // 2):
        tw = cis(-2 * PI * k / n) * od[k]
        out[k], out[k + n // 2] = ev[k] + tw, ev[k] - tw
    return out

one = lambda w: 1.0
f6 = lambda v: f"{v:.6f}"
f9 = lambda v: f"{v:.9f}"
print("== the note: 1 V, 110 Hz, amplitude falls by e each second ==")
bt = 2 * PI * F0 * TAU
print(f"b = 2 pi f0 tau = {f6(bt)}; b^2/(1 + b^2) = {f9(bt * bt / (1 + bt * bt))}")
e_exact = TAU / 4 * bt * bt / (1 + bt * bt)
e_simp = simpson(lambda t: note(t) ** 2, 0, 10, 200000)
tail_t = TAU / 2 * math.exp(-20 / TAU)
print(f"energy in time, closed form (tau/4) b^2/(1 + b^2), b = 2 pi f0 tau: {f9(e_exact)} V^2 s")
print(f"energy in time, Simpson on 0..10 s: {f9(e_simp)}; tail beyond 10 s at most {tail_t:.2e}")
assert abs(e_simp - e_exact) < 1e-9                        # road 1 = road 2
e_f1, e_f2 = freq_int(one, 2000), freq_int(one, 4000)
print(f"energy in frequency, Simpson, 2000 and 4000 steps: {f9(e_f1)} and {f9(e_f2)} V^2 s")
assert abs(e_f2 - e_exact) < 1e-9                          # Plancherel on the note
assert abs(e_f1 - e_f2) < 1e-8
print(f"peak |fhat(110)| = {f6(abs(fhat(F0)))} V s; half-power half-width 1/(2 pi tau) = {f6(AL / (2 * PI))} Hz")
print("bars, share of the energy within d Hz of +-110 Hz: d | share")
for d in (0.1, 0.5, 1, 5, 50):
    print(f"bars, {d} | {100 * 2 * band(F0 - d, F0 + d, one, 2000) / e_exact:.4f} %")
print(f"Lorentz estimate for d = 1, (2/pi) atan(2 pi): {100 * 2 / PI * math.atan(2 * PI):.4f} %")

print("== the samples: 4096 a second for 8 s, N = 32768, written-out FFT ==")
fs, N = 4096, 32768
dt, dxi = 1 / fs, fs / N
x = [complex(note(n * dt), 0) for n in range(N)]
X = fft(x)
s_time, s_freq = 0.0, 0.0
for n in range(N):
    s_time += abs(x[n]) ** 2 * dt
    s_freq += abs(X[n] * dt) ** 2 * dxi
print(f"dt sum x^2 = {f9(s_time)}; dxi sum |dt X|^2 = {f9(s_freq)} V^2 s")
assert abs(s_time - s_freq) < 1e-12                        # finite Parseval, exact
print(f"gap from the true energy (sampling and the 8 s cut): {s_time - e_exact:.2e}")
assert abs(s_time - e_exact) < 1e-6
k = round(F0 / dxi)
cut = abs(fhat(F0)) * (1 - math.exp(-8 / TAU))  # the 8 s cut drops e^(-8) of the peak
print(f"bin {k} at {f6(k * dxi)} Hz: |dt X| = {f6(abs(X[k] * dt))}; |fhat| = {f6(abs(fhat(F0)))}, times 1 - e^-8 = {f6(cut)}")
assert abs(abs(X[k] * dt) - cut) < 1e-6                    # the FFT is the transform

print("== density: bell-smoothed notes f_eps, each rapidly decreasing ==")
print("eps ms | gain at 110 Hz | energy of f_eps | ||f - f_eps||^2 in time | in frequency | ||f_eps - f_prev||^2")
eps_list, dist, ens = (10, 1, 0.1, 0.01), [], []
for i, eps_ms in enumerate(eps_list):
    e, p = eps_ms / 1000, eps_list[i - 1] / 1000
    sm = lambda xi, e=e: math.exp(-PI * e * e * xi * xi)   # the bell's transform
    ens.append(freq_int(lambda xi: sm(xi) ** 2, 4000))
    dist.append(in_time(e, 1))                             # f is not in S: measured in time
    d_f = freq_int(lambda xi: (1 - sm(xi)) ** 2, 4000)
    c = "-" if i == 0 else f"{freq_int(lambda xi: (sm(xi) - sm(xi, p)) ** 2, 4000):.3e}"
    print(f"{eps_ms} | {f6(sm(F0))} | {f9(ens[i])} | {dist[i]:.3e} | {d_f:.3e} | {c}")
    assert abs(d_f - dist[i]) < 1e-3 * dist[i]             # time side = frequency side
assert dist[0] > dist[1] > dist[2] > dist[3] and dist[3] < 1e-5 * dist[0]
e_time = in_time(0.001, 0)                     # f_eps for eps = 1 ms, built in time
print(f"eps = 1 ms: energy of f_eps in time {f9(e_time)}, in frequency {f9(ens[1])} V^2 s")
assert abs(e_time - ens[1]) < 1e-8                         # Plancherel on a smooth note

print("== the shutter: 1 V for 1 ms; its spectrum sin(pi xi T)/(pi xi) ==")
T = 0.001
gate = lambda xi: T if xi == 0 else math.sin(PI * xi * T) / (PI * xi)
lobe = 2 * simpson(lambda xi: gate(xi) ** 2, 0, 1 / T, 2000)
print(f"gate energy {f6(T * 1000)} V^2 ms; main lobe |xi| < 1 kHz holds {100 * lobe / T:.4f} %")
area, edge, areas = 0.0, 0.0, []
for W in (10, 100, 1000):                      # in units of kHz; lobes of 1 kHz
    while edge < W:
        area += 2 * simpson(lambda xi: abs(gate(xi)), edge / T, (edge + 1) / T, 40)
        edge += 1
    print(f"area under |spectrum| for |xi| < {W} kHz: {f6(area)} V")
    areas.append(area)
grow = 4 / PI ** 2 * math.log(10)
print(f"growth per tenfold band: {f6(areas[2] - areas[1])} V; (4/pi^2) ln 10 = {f6(grow)}")
assert abs(areas[2] - areas[1] - grow) < 1e-3              # no finite area

print("== what breaks ==")
print(f"omega form, no 1/2pi: integral |F(omega)|^2 d omega = 2 pi x {f6(e_f2)} = {f6(2 * PI * e_f2)}")
for L in (1, 10, 100):
    print(f"string that never decays: energy over the first {L} s = {f6(simpson(lambda t: math.sin(2 * PI * F0 * t) ** 2, 0, L, 2000 * L))} V^2 s")
print(f"positive frequencies only: {f6(e_f2 / 2)} against {f6(e_exact)}")
print(f"because |fhat(-110)| = {f6(abs(fhat(-F0)))} = |fhat(110)|")
assert abs(power(-F0) - power(F0)) < 1e-12                 # a real note: even power
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
== the note: 1 V, 110 Hz, amplitude falls by e each second ==
b = 2 pi f0 tau = 691.150384; b^2/(1 + b^2) = 0.999997907
energy in time, closed form (tau/4) b^2/(1 + b^2), b = 2 pi f0 tau: 0.249999477 V^2 s
energy in time, Simpson on 0..10 s: 0.249999476; tail beyond 10 s at most 1.03e-09
energy in frequency, Simpson, 2000 and 4000 steps: 0.249999478 and 0.249999477 V^2 s
peak |fhat(110)| = 0.500000 V s; half-power half-width 1/(2 pi tau) = 0.159155 Hz
bars, share of the energy within d Hz of +-110 Hz: d | share
bars, 0.1 | 35.7133 %
bars, 0.5 | 80.3817 %
bars, 1 | 89.9528 %
bars, 5 | 97.9774 %
bars, 50 | 99.8299 %
Lorentz estimate for d = 1, (2/pi) atan(2 pi): 89.9522 %
== the samples: 4096 a second for 8 s, N = 32768, written-out FFT ==
dt sum x^2 = 0.249999448; dxi sum |dt X|^2 = 0.249999448 V^2 s
gap from the true energy (sampling and the 8 s cut): -2.82e-08
bin 880 at 110.000000 Hz: |dt X| = 0.499832; |fhat| = 0.500000, times 1 - e^-8 = 0.499832
== density: bell-smoothed notes f_eps, each rapidly decreasing ==
eps ms | gain at 110 Hz | energy of f_eps | ||f - f_eps||^2 in time | in frequency | ||f_eps - f_prev||^2
10 | 0.022341 | 0.000303749 | 2.385e-01 | 2.385e-01 | -
1 | 0.962700 | 0.231708111 | 3.507e-04 | 3.507e-04 | 2.207e-01
0.1 | 0.999620 | 0.249809494 | 3.945e-08 | 3.945e-08 | 3.436e-04
0.01 | 0.999996 | 0.249997576 | 6.954e-12 | 6.954e-12 | 3.862e-08
eps = 1 ms: energy of f_eps in time 0.231708111, in frequency 0.231708111 V^2 s
== the shutter: 1 V for 1 ms; its spectrum sin(pi xi T)/(pi xi) ==
gate energy 1.000000 V^2 ms; main lobe |xi| < 1 kHz holds 90.2823 %
area under |spectrum| for |xi| < 10 kHz: 2.105726 V
area under |spectrum| for |xi| < 100 kHz: 3.038857 V
area under |spectrum| for |xi| < 1000 kHz: 3.972059 V
growth per tenfold band: 0.933202 V; (4/pi^2) ln 10 = 0.933203
== what breaks ==
omega form, no 1/2pi: integral |F(omega)|^2 d omega = 2 pi x 0.249999 = 1.570793
string that never decays: energy over the first 1 s = 0.500000 V^2 s
string that never decays: energy over the first 10 s = 5.000000 V^2 s
string that never decays: energy over the first 100 s = 50.000000 V^2 s
positive frequencies only: 0.125000 against 0.249999
because |fhat(-110)| = 0.500000 = |fhat(110)|
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Plancherel -- the same check as the Python, in Rust.  No crates.
// The note: f(t) = A e^(-t/tau) sin(2 pi f0 t) for t >= 0, 0 before the pluck,
// with A = 1 V, f0 = 110 Hz, tau = 1 s (illustrative).  Hertz form:
// fhat(xi) = integral f(t) e^(-2 pi i xi t) dt, xi in hertz, energy in V^2 s.
// Roads as in the Python.  A complex number is a small struct.
use std::f64::consts::PI;
const A: f64 = 1.0; const F0: f64 = 110.0; const TAU: f64 = 1.0;
const AL: f64 = 1.0 / TAU;                         // decay rate, per second
const SI: f64 = 2.0 * PI * F0;                     // the note is Im(A e^(S t)), S = -AL + i SI
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn inv(self) -> C { let d = self.re * self.re + self.im * self.im; C { re: self.re / d, im: -self.im / d } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn cis(a: f64) -> C { C { re: a.cos(), im: a.sin() } }
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = g(a) + g(b);
    for k in 1..m { s += if k % 2 == 1 { 4.0 } else { 2.0 } * g(a + k as f64 * h); }
    s * h / 3.0
}
fn note(t: f64) -> f64 { if t >= 0.0 { A * (-t / TAU).exp() * (2.0 * PI * F0 * t).sin() } else { 0.0 } }
fn fhat(xi: f64) -> C {                            // closed form, a complex number
    let (p, q) = (C { re: AL, im: 2.0 * PI * (xi - F0) }.inv(), C { re: AL, im: 2.0 * PI * (xi + F0) }.inv());
    let d = p.sub(q).scale(A / 2.0);               // divide by 2i: (re, im) -> (im, -re)
    C { re: d.im, im: -d.re }
}
fn power(xi: f64) -> f64 { fhat(xi).abs().powi(2) }

fn band(lo: f64, hi: f64, w: &dyn Fn(f64) -> f64, m: usize) -> f64 {
    let th = |xi: f64| (2.0 * PI * (xi - F0) / AL).atan();  // xi = F0 + (AL/2pi) tan(th):
    let g = |u: f64| {                                      // flattens the peak at F0
        let xi = F0 + AL / (2.0 * PI) * u.tan();
        power(xi) * w(xi) * AL / (2.0 * PI) / u.cos().powi(2)
    };
    simpson(&g, th(lo), th(hi), m)
}
fn freq_int(w: &dyn Fn(f64) -> f64, m: usize) -> f64 {   // all xi: power is even
    let cuts = [0.0, F0 - 1.0, F0 + 1.0, 1e3];            // three pieces, peak in the middle
    let top = |u: f64| if u > 0.0 { let xi = 1e3 / u.powi(4); power(xi) * w(xi) * 4e3 / u.powi(5) } else { 0.0 };
    let s = (0..3).map(|i| band(cuts[i], cuts[i + 1], w, m)).sum::<f64>() + simpson(&top, 0.0, 1.0, m);
    2.0 * s                                               // last piece: xi = 1 kHz / u^4, out to infinity
}

fn in_time(e: f64, c: f64) -> f64 {               // energy of c f - f_eps, in time: no transform
    let (m, s) = (6.0 * e, C { re: -AL, im: SI });
    let gb = |u: f64| (-PI * u * u / (e * e)).exp() / e;              // the bell, cut at 6 eps
    let fe = |t: f64| if t > -m { simpson(&|u| note(t - u) * gb(u), -m, t.min(m), 400) } else { 0.0 };
    let g = |t: f64| (c * note(t) - fe(t)).powi(2);  // fe(t) = f_eps(t) = integral f(t - u) G(u) du
    let kp = |p: fn(C) -> f64| simpson(&|u| p(C::cis(-SI * u)) * (AL * u).exp() * gb(u), -m, m, 400);
    let d = C { re: c, im: 0.0 }.sub(C { re: kp(|z| z.re), im: kp(|z| z.im) }).scale(A);
    let ee = C::cis(2.0 * SI * m).scale((-2.0 * AL * m).exp());     // past m: Im(D e^(S t))
    let far = (d.abs().powi(2) * (-2.0 * AL * m).exp() / (2.0 * AL) + d.mul(d).mul(ee).mul(s.scale(2.0).inv()).re) / 2.0;
    simpson(&g, -m, 0.0, 400) + simpson(&g, 0.0, m, 400) + far      // near part split at the kink
}
fn fft(x: &[C]) -> Vec<C> {                        // radix-2, written out
    let n = x.len();
    if n == 1 { return x.to_vec(); }
    let ev: Vec<C> = x.iter().step_by(2).cloned().collect();
    let od: Vec<C> = x.iter().skip(1).step_by(2).cloned().collect();
    let (ev, od) = (fft(&ev), fft(&od));
    let mut out = vec![C { re: 0.0, im: 0.0 }; n];
    for k in 0..n / 2 {
        let tw = C::cis(-2.0 * PI * k as f64 / n as f64).mul(od[k]);
        out[k] = ev[k].add(tw);
        out[k + n / 2] = ev[k].sub(tw);
    }
    out
}
fn sci(v: f64, d: usize) -> String {               // Python's e format: 2.385e-01
    let s = format!("{:.*e}", d, v);
    let (m, e) = s.split_once('e').unwrap();
    let ex: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ex < 0 { '-' } else { '+' }, ex.abs())
}
fn f6(v: f64) -> String { format!("{:.6}", v) }
fn f9(v: f64) -> String { format!("{:.9}", v) }

fn main() {
    let one = |_: f64| 1.0;
    println!("== the note: 1 V, 110 Hz, amplitude falls by e each second ==");
    let bt = 2.0 * PI * F0 * TAU;
    println!("b = 2 pi f0 tau = {}; b^2/(1 + b^2) = {}", f6(bt), f9(bt * bt / (1.0 + bt * bt)));
    let e_exact = TAU / 4.0 * bt * bt / (1.0 + bt * bt);
    let e_simp = simpson(&|t| note(t).powi(2), 0.0, 10.0, 200000);
    let tail_t = TAU / 2.0 * (-20.0 / TAU).exp();
    println!("energy in time, closed form (tau/4) b^2/(1 + b^2), b = 2 pi f0 tau: {} V^2 s", f9(e_exact));
    println!("energy in time, Simpson on 0..10 s: {}; tail beyond 10 s at most {}", f9(e_simp), sci(tail_t, 2));
    assert!((e_simp - e_exact).abs() < 1e-9);                 // road 1 = road 2
    let (e_f1, e_f2) = (freq_int(&one, 2000), freq_int(&one, 4000));
    println!("energy in frequency, Simpson, 2000 and 4000 steps: {} and {} V^2 s", f9(e_f1), f9(e_f2));
    assert!((e_f2 - e_exact).abs() < 1e-9);                   // Plancherel on the note
    assert!((e_f1 - e_f2).abs() < 1e-8);
    println!("peak |fhat(110)| = {} V s; half-power half-width 1/(2 pi tau) = {} Hz", f6(fhat(F0).abs()), f6(AL / (2.0 * PI)));
    println!("bars, share of the energy within d Hz of +-110 Hz: d | share");
    for d in [0.1, 0.5, 1.0, 5.0, 50.0] {
        println!("bars, {} | {:.4} %", d, 100.0 * 2.0 * band(F0 - d, F0 + d, &one, 2000) / e_exact);
    }
    println!("Lorentz estimate for d = 1, (2/pi) atan(2 pi): {:.4} %", 100.0 * 2.0 / PI * (2.0 * PI).atan());

    println!("== the samples: 4096 a second for 8 s, N = 32768, written-out FFT ==");
    let (fs, n) = (4096.0, 32768usize);
    let (dt, dxi) = (1.0 / fs, fs / n as f64);
    let x: Vec<C> = (0..n).map(|k| C { re: note(k as f64 * dt), im: 0.0 }).collect();
    let xx = fft(&x);
    let (mut s_time, mut s_freq) = (0.0, 0.0);
    for k in 0..n {
        s_time += x[k].abs().powi(2) * dt;
        s_freq += xx[k].scale(dt).abs().powi(2) * dxi;
    }
    println!("dt sum x^2 = {}; dxi sum |dt X|^2 = {} V^2 s", f9(s_time), f9(s_freq));
    assert!((s_time - s_freq).abs() < 1e-12);                 // finite Parseval, exact
    println!("gap from the true energy (sampling and the 8 s cut): {}", sci(s_time - e_exact, 2));
    assert!((s_time - e_exact).abs() < 1e-6);
    let k = (F0 / dxi).round() as usize;
    let cut = fhat(F0).abs() * (1.0 - (-8.0 / TAU).exp());  // the 8 s cut drops e^(-8) of the peak
    println!("bin {} at {} Hz: |dt X| = {}; |fhat| = {}, times 1 - e^-8 = {}", k, f6(k as f64 * dxi), f6(xx[k].scale(dt).abs()), f6(fhat(F0).abs()), f6(cut));
    assert!((xx[k].scale(dt).abs() - cut).abs() < 1e-6);      // the FFT is the transform

    println!("== density: bell-smoothed notes f_eps, each rapidly decreasing ==");
    println!("eps ms | gain at 110 Hz | energy of f_eps | ||f - f_eps||^2 in time | in frequency | ||f_eps - f_prev||^2");
    let eps_list = [10.0, 1.0, 0.1, 0.01];
    let (mut dist, mut ens): (Vec<f64>, Vec<f64>) = (Vec::new(), Vec::new());
    for i in 0..4 {
        let e = eps_list[i] / 1000.0;
        let p = eps_list[(i + 3) % 4] / 1000.0;
        let sm = |xi: f64, e: f64| (-PI * e * e * xi * xi).exp();   // the bell's transform
        ens.push(freq_int(&|xi| sm(xi, e).powi(2), 4000));
        dist.push(in_time(e, 1.0));                                // f is not in S: measured in time
        let d_f = freq_int(&|xi| (1.0 - sm(xi, e)).powi(2), 4000);
        let c = if i == 0 { "-".to_string() } else { sci(freq_int(&|xi| (sm(xi, e) - sm(xi, p)).powi(2), 4000), 3) };
        println!("{} | {} | {} | {} | {} | {}", eps_list[i], f6(sm(F0, e)), f9(ens[i]), sci(dist[i], 3), sci(d_f, 3), c);
        assert!((d_f - dist[i]).abs() < 1e-3 * dist[i]);          // time side = frequency side
    }
    assert!(dist[0] > dist[1] && dist[1] > dist[2] && dist[2] > dist[3] && dist[3] < 1e-5 * dist[0]);
    let e_time = in_time(0.001, 0.0);              // f_eps for eps = 1 ms, built in time
    println!("eps = 1 ms: energy of f_eps in time {}, in frequency {} V^2 s", f9(e_time), f9(ens[1]));
    assert!((e_time - ens[1]).abs() < 1e-8);                  // Plancherel on a smooth note

    println!("== the shutter: 1 V for 1 ms; its spectrum sin(pi xi T)/(pi xi) ==");
    let t_open = 0.001;
    let gate = |xi: f64| if xi == 0.0 { t_open } else { (PI * xi * t_open).sin() / (PI * xi) };
    let lobe = 2.0 * simpson(&|xi| gate(xi).powi(2), 0.0, 1.0 / t_open, 2000);
    println!("gate energy {} V^2 ms; main lobe |xi| < 1 kHz holds {:.4} %", f6(t_open * 1000.0), 100.0 * lobe / t_open);
    let (mut area, mut edge, mut areas) = (0.0, 0.0, Vec::new());
    for w in [10.0, 100.0, 1000.0] {               // in units of kHz; lobes of 1 kHz
        while edge < w { area += 2.0 * simpson(&|xi| gate(xi).abs(), edge / t_open, (edge + 1.0) / t_open, 40); edge += 1.0; }
        println!("area under |spectrum| for |xi| < {} kHz: {} V", w, f6(area));
        areas.push(area);
    }
    let grow = 4.0 / (PI * PI) * 10f64.ln();
    println!("growth per tenfold band: {} V; (4/pi^2) ln 10 = {}", f6(areas[2] - areas[1]), f6(grow));
    assert!((areas[2] - areas[1] - grow).abs() < 1e-3);       // no finite area

    println!("== what breaks ==");
    println!("omega form, no 1/2pi: integral |F(omega)|^2 d omega = 2 pi x {} = {}", f6(e_f2), f6(2.0 * PI * e_f2));
    for l in [1usize, 10, 100] {
        let en = simpson(&|t| (2.0 * PI * F0 * t).sin().powi(2), 0.0, l as f64, 2000 * l);
        println!("string that never decays: energy over the first {} s = {} V^2 s", l, f6(en));
    }
    println!("positive frequencies only: {} against {}", f6(e_f2 / 2.0), f6(e_exact));
    println!("because |fhat(-110)| = {} = |fhat(110)|", f6(fhat(-F0).abs()));
    assert!((power(-F0) - power(F0)).abs() < 1e-12);          // a real note: even power
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
== the note: 1 V, 110 Hz, amplitude falls by e each second ==
b = 2 pi f0 tau = 691.150384; b^2/(1 + b^2) = 0.999997907
energy in time, closed form (tau/4) b^2/(1 + b^2), b = 2 pi f0 tau: 0.249999477 V^2 s
energy in time, Simpson on 0..10 s: 0.249999476; tail beyond 10 s at most 1.03e-09
energy in frequency, Simpson, 2000 and 4000 steps: 0.249999478 and 0.249999477 V^2 s
peak |fhat(110)| = 0.500000 V s; half-power half-width 1/(2 pi tau) = 0.159155 Hz
bars, share of the energy within d Hz of +-110 Hz: d | share
bars, 0.1 | 35.7133 %
bars, 0.5 | 80.3817 %
bars, 1 | 89.9528 %
bars, 5 | 97.9774 %
bars, 50 | 99.8299 %
Lorentz estimate for d = 1, (2/pi) atan(2 pi): 89.9522 %
== the samples: 4096 a second for 8 s, N = 32768, written-out FFT ==
dt sum x^2 = 0.249999448; dxi sum |dt X|^2 = 0.249999448 V^2 s
gap from the true energy (sampling and the 8 s cut): -2.82e-08
bin 880 at 110.000000 Hz: |dt X| = 0.499832; |fhat| = 0.500000, times 1 - e^-8 = 0.499832
== density: bell-smoothed notes f_eps, each rapidly decreasing ==
eps ms | gain at 110 Hz | energy of f_eps | ||f - f_eps||^2 in time | in frequency | ||f_eps - f_prev||^2
10 | 0.022341 | 0.000303749 | 2.385e-01 | 2.385e-01 | -
1 | 0.962700 | 0.231708111 | 3.507e-04 | 3.507e-04 | 2.207e-01
0.1 | 0.999620 | 0.249809494 | 3.945e-08 | 3.945e-08 | 3.436e-04
0.01 | 0.999996 | 0.249997576 | 6.954e-12 | 6.954e-12 | 3.862e-08
eps = 1 ms: energy of f_eps in time 0.231708111, in frequency 0.231708111 V^2 s
== the shutter: 1 V for 1 ms; its spectrum sin(pi xi T)/(pi xi) ==
gate energy 1.000000 V^2 ms; main lobe |xi| < 1 kHz holds 90.2823 %
area under |spectrum| for |xi| < 10 kHz: 2.105726 V
area under |spectrum| for |xi| < 100 kHz: 3.038857 V
area under |spectrum| for |xi| < 1000 kHz: 3.972059 V
growth per tenfold band: 0.933202 V; (4/pi^2) ln 10 = 0.933203
== what breaks ==
omega form, no 1/2pi: integral |F(omega)|^2 d omega = 2 pi x 0.249999 = 1.570793
string that never decays: energy over the first 1 s = 0.500000 V^2 s
string that never decays: energy over the first 10 s = 5.000000 V^2 s
string that never decays: energy over the first 100 s = 50.000000 V^2 s
positive frequencies only: 0.125000 against 0.249999
because |fhat(-110)| = 0.500000 = |fhat(110)|
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the energy identity and the extension's main facts, for every rapidly decreasing signal and every finite-energy signal.

- Take a rapidly decreasing signal $`f`$. Then $`\int |\hat f(\xi)|^2\, d\xi = \int |f(t)|^2\, dt`$.
- Take rapidly decreasing signals $`f`$ and $`h`$. Then $`\langle \hat f, \hat h\rangle = \langle f, h\rangle`$.
- Take a finite-energy signal $`f`$, and rapidly decreasing $`\varphi_n`$ with $`\|\varphi_n - f\|_2 \to 0`$. Then $`\|\hat\varphi_n - \mathcal{F}f\|_2 \to 0`$.
- Take finite-energy signals $`f`$ and $`g`$. Then $`\|\mathcal{F}f - \mathcal{F}g\|_2 = \|f - g\|_2`$, so $`\mathcal{F}`$ keeps every distance and every energy.
- $`\mathcal{F}`$ is one to one and onto: every finite-energy spectrum belongs to exactly one finite-energy signal.
- The card's transform, with $`2\pi`$ in the exponent and ξ in hertz, is the transform built into Lean's maths library.

Every number on the note, the smoothed notes and the shutter, and the broken cases, are left to the Python and Rust checks.

```lean
-- Plancherel: on rapidly decreasing signals the transform keeps energy, and its extension to all square-integrable signals keeps every energy and distance, is the energy-limit of the transforms of rapidly decreasing approximations, and is one to one and onto.
import Mathlib.Analysis.Fourier.LpSpace

open MeasureTheory Filter Topology SchwartzMap
open scoped FourierTransform ComplexInnerProductSpace

noncomputable section


/-- The finite-energy signals on the time line: `L²(ℝ)`, complex valued, with Lebesgue measure. -/
abbrev L2Signal := Lp ℂ 2 (volume : Measure ℝ)

/-- **Plancherel.** For every rapidly decreasing signal `f` (a Schwartz function `ℝ → ℂ`), with the
hertz-form transform `f̂(ξ) = ∫ f(t) e^(-2πiξt) dt` (Mathlib's `𝓕`), the energy summed over
frequencies equals the energy summed over time: `∫ |f̂(ξ)|² dξ = ∫ |f(t)|² dt`.
And the transform `𝓕` on all finite-energy signals `L²(ℝ)` extends it by limits: whenever
rapidly decreasing `φₙ` approach `f` in energy, the transforms `φ̂ₙ` approach `𝓕 f` in energy;
and `𝓕` keeps every distance, `‖𝓕 f - 𝓕 g‖₂ = ‖f - g‖₂` (so, with `g = 0`, every energy). -/
theorem plancherel_energy_and_extension_to_L2 :
    (∀ f : 𝓢(ℝ, ℂ), ∫ ξ, ‖𝓕 (f : ℝ → ℂ) ξ‖ ^ 2 = ∫ t, ‖f t‖ ^ 2) ∧
    (∀ (f : L2Signal) (φ : ℕ → 𝓢(ℝ, ℂ)),
      Tendsto (fun n => (φ n).toLp 2) atTop (𝓝 f) →
      Tendsto (fun n => (𝓕 (φ n)).toLp 2) atTop (𝓝 (𝓕 f : L2Signal))) ∧
    (∀ f g : L2Signal, ‖(𝓕 f : L2Signal) - 𝓕 g‖ = ‖f - g‖) := by
  refine ⟨fun f => ?_, fun f φ hφ => ?_, fun f g => ?_⟩
  · simpa [SchwartzMap.fourier_coe] using SchwartzMap.integral_norm_sq_fourier f
  · have hc : Continuous (fun x : L2Signal => (𝓕 x : L2Signal)) :=
      (MeasureTheory.Lp.fourierTransformₗᵢ ℝ ℂ).continuous
    have := (hc.tendsto f).comp hφ
    simpa [Function.comp_def, SchwartzMap.toLp_fourier_eq] using this
  · have h := (MeasureTheory.Lp.fourierTransformₗᵢ ℝ ℂ).norm_map (f - g)
    rw [map_sub] at h
    exact h

/-- **Step 2: the transform keeps inner products.** For every two rapidly decreasing signals
`f` and `h`, `⟨f̂, ĥ⟩ = ∫ f̂(ξ) conj(ĥ(ξ)) dξ` equals `⟨f, h⟩ = ∫ f(t) conj(h(t)) dt`. -/
theorem fourier_keeps_inner_product_schwartz (f h : 𝓢(ℝ, ℂ)) :
    ∫ ξ, 𝓕 (f : ℝ → ℂ) ξ * starRingEnd ℂ (𝓕 (h : ℝ → ℂ) ξ) =
      ∫ t, f t * starRingEnd ℂ (h t) := by
  have := SchwartzMap.integral_inner_fourier_fourier h f
  simpa [SchwartzMap.fourier_coe, RCLike.inner_apply] using this

/-- **Step 6: the map is onto, so it can be undone.** The transform `𝓕` on `L²(ℝ)` is one to one
and onto: every finite-energy spectrum belongs to exactly one finite-energy signal. -/
theorem fourier_L2_bijective : Function.Bijective (fun f : L2Signal => (𝓕 f : L2Signal)) := by
  exact (MeasureTheory.Lp.fourierTransformₗᵢ ℝ ℂ).bijective


#print axioms plancherel_energy_and_extension_to_L2
#print axioms fourier_keeps_inner_product_schwartz
#print axioms fourier_L2_bijective
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'plancherel_energy_and_extension_to_L2' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_keeps_inner_product_schwartz' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_L2_bijective' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: does a longer-ringing string break anything? Set `TAU` to 2.0. The closed form reads 0.499999738, but Simpson's rule on 0 to 10 s reads 0.499977038 and the tail bound grows to 4.54e-05. The first assert stops the run: the cut-off at 10 s is now too short.
> - Guess first: does a coarser sampling rate break the FFT's energy balance? Set `fs, N = 1024, 8192`. Both sides still agree exactly, at 0.249999441; only the gap from the true energy grows, to -3.59e-08.
> - Guess first: how close does a 0.001 ms bell come? Change the last entry of `eps_list` to 0.001. The squared distance to the note falls to 3.703e-15, in time and in frequency alike.
> - Guess first: what if the code counts positive frequencies only? Change `return 2 * s` to `return s` in `freq_int`. The frequency side reads 0.124999738, half the energy, and the Plancherel assert stops the run.

---

## The usual mistake

> [!warning]
> **Treating the integral $`\int f(t)\, e^{-2\pi i\xi t}\, dt`$ as the transform of every finite-energy signal.** The integral needs finite area under $`|f|`$. The shutter's spectrum, read as a signal, has energy 0.001 V²·s, yet its area grows: 2.105726, 3.038857, 3.972059 V over 10, 100, 1000 kHz. On such a signal the transform is $`\mathcal{F}`$, the energy-limit of Step 5, not an integral.
>
> Smaller traps:
> - **Dropping the $`2\pi`$ when switching forms.** In the ω form the note's frequency side reads 1.570793, not 0.249999. The hertz form needs no factor.
> - **Counting positive frequencies only.** The note's +110 Hz peak holds 0.125000 V²·s; the other half is at −110 Hz.
> - **Reading $`\mathcal{F}f`$ at one frequency.** For a signal with infinite area, $`\mathcal{F}f`$ is defined only up to sets of length zero. Plancherel is a statement about energy.
> - **Smoothing too much.** A 10 ms bell keeps only 0.000303749 V²·s of the note's energy: the approximation must get close in energy, not just be smooth.

---

## Where you meet it in real life

- **Instrument tuners.** A tuner reads the pitch from where the energy sits in frequency. The note's peak has a half-power half-width of only $`1/(2\pi\tau) = 0.159155`$ Hz, so a 1 s ring pins the pitch to a fraction of a hertz.
- **Audio meters and spectrum analysers.** Band energies add up to the signal's total energy. The note's bars add to 99.8299 % within 50 Hz of the pitch.
- **Filter design.** By Plancherel, a filter's squared error over time equals the energy it removes in frequency. That lets engineers design in whichever domain is easier.
- **Cameras.** A 1 ms exposure, the shutter of the shelf, puts 90.2823 % of its energy below 1 kHz. A flicker much faster than that barely registers.
- **Quantum mechanics.** A particle's position and momentum wave functions are transforms of each other. Plancherel makes the total probability 1 in both.

> **Say it back**
> A plucked string holds the same energy, 0.249999477 V²·s, whether it is counted over time or over frequency. For rapidly decreasing signals this follows from swapping two integrals and from inversion, which turns the transform of a conjugate spectrum back into the conjugate signal. These signals come as close as wanted to any finite-energy signal, and the transform keeps distances, so their transforms settle on a limit. That limit is the transform of every square-integrable signal, even when the integral fails. It keeps every energy and every distance, and it can be undone.

---

## What this builds on

- [Fourier inversion](04-fourier-inversion-theorem.md): the inverse brings a rapidly decreasing signal back from its transform. Step 2 uses it to turn $`\overline{\hat h}`$ into $`\overline h`$.
- [Lp spaces](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/01-lp-spaces.md): the energy norm $`\lVert f\rVert_2`$ and the rule that signals equal except on length zero count as one.
- [Riesz-Fischer](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/05-completeness-of-lp.md): $`L^2(\mathbb{R})`$ has no holes, and continuous signals that are zero outside a bounded interval are dense. Steps 4 and 5 use both, and the fold uses its almost-everywhere subsequence.
- [Orthonormal bases](../../18-Functional%20analysis/02-Hilbert%20Spaces/03-orthonormal-bases-and-parseval.md): Parseval for a list of perpendicular signals. The FFT's exact energy balance in Step 3 is that identity on 32,768 samples.
- [Plancherel](../../18-Functional%20analysis/03-Bounded%20Operators/04-the-fourier-transform-as-a-unitary-operator.md): the same theorem in the ω form, $`\int|F|^2\, d\omega = 2\pi\|f\|_2^2`$, seen as a unitary operator.
- [Tempered distributions](../../18-Functional%20analysis/04-Distributions%20and%20Sobolev%20Spaces/05-tempered-distributions-and-the-fourier-transform.md): defines the rapidly decreasing signals and proves the transform keeps them rapidly decreasing.

## Where this goes next

- [Schwartz space and tempered distributions](06-schwartz-space-and-tempered-distributions.md): the transform of signals with infinite energy, such as the string that never decays.
- [The uncertainty principle](07-uncertainty-principle.md): energy is spread the same total amount in time and frequency, but not in the same place. A note cannot be short in both.
- [The Hilbert transform](09-hilbert-transform-and-analytic-signals.md): a frequency multiplier of size 1 keeps energy by Plancherel, so it is defined on every finite-energy signal.
- [Short-time Fourier transform](../05-Wavelets%20and%20Time-Frequency/01-short-time-fourier-and-gabor.md): energy split over time and frequency at once, with a Plancherel identity of its own.
- [Interpolation](../06-Maximal%20Functions%20and%20Beyond/04-interpolation-riesz-thorin-and-marcinkiewicz.md): from area and energy to the norms in between, giving the Hausdorff-Young inequality.

The question this card leaves open: the transform keeps energy, the $`L^2`$ norm, exactly; what does it do to the other $`L^p`$ norms, between finite area and finite energy?

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Plancherel, Michel. "Contribution à l'étude de la représentation d'une fonction arbitraire par des intégrales définies." *Rendiconti del Circolo Matematico di Palermo* 30 (1910): 289–335. [doi:10.1007/BF03014877](https://doi.org/10.1007/BF03014877). The original theorem that the transform keeps energy on all square-integrable signals.
- Stein, Elias M., and Rami Shakarchi. *Fourier Analysis: An Introduction*. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113845/fourier-analysis). Chapter 5: the transform on rapidly decreasing functions, the multiplication formula and the Plancherel formula, the route of Steps 1 and 2.
- Katznelson, Yitzhak. *An Introduction to Harmonic Analysis*, 3rd ed. Cambridge University Press, 2004. [doi:10.1017/CBO9781139165372](https://doi.org/10.1017/CBO9781139165372). Chapter VI: the transform on the line and its extension to square-integrable functions.
- Grafakos, Loukas. *Classical Fourier Analysis*, 3rd ed. Springer, 2014. [doi:10.1007/978-1-4939-1194-3](https://doi.org/10.1007/978-1-4939-1194-3). Chapter 2: Schwartz functions, Plancherel's identity by density, and the Hausdorff-Young inequality.
