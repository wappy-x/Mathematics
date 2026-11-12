# Fourier series: any repeating signal is a sum of spinning arrows e to the inx, and each coefficient is an average

[Syllabus](../../../SYLLABUS.md) → [Complex analysis](../README.md) → [Transforms in Outline](../README.md#s08) → Fourier series

---

## General Overview

A synthesiser's square-wave oscillator plays A below middle C, 220 cycles a second. Its voltage sits at +1 for half of each cycle and −1 for the other half. It sounds buzzy, unlike a tuning fork on the same note.

The difference is hidden tones. A spectrum analyser shows energy at 220, 660 and 1100 Hz and every further odd multiple of 220, each quieter than the last. Even multiples are silent.

Each pure tone is an arrow spinning round a circle, the point e^(inx) of [Euler's formula](../01-Complex%20Numbers%20and%20the%20Plane/04-eulers-formula.md). How much of each arrow the signal holds is one average over a cycle.

**A signal that repeats every 2π is a sum of arrows c_n e^(inx), each spinning n times per cycle, and each coefficient c_n is the average over one cycle of the signal times e^(−inx).**

**What kind of fact this is:** a theorem. The coefficient formula is proved in Why it works. That the sum returns the signal, under the conditions in When it holds, is proved in Fourier coefficients. Parseval's identity is stated, its proof folded.

### The picture: two arrows make one real tone

<p align="center"><img src="../figures/fourier-series-in-complex-form.svg" alt="At x equals pi over 4, the arrow for n equals 1 points down and right, its partner for n equals minus 1 points up and right, and the two added tip to tail land on the real axis at 0.900316" width="420"></p>

To scale: 160 units per 1, origin at (120, 120). At x = π/4 the n = 1 arrow is 0.450158 − 0.450158i, tip at (192.03, 192.03); its partner is 0.450158 + 0.450158i, tip at (192.03, 47.97). Both ride the dashed circle of radius 0.636620, turning opposite ways. Their sum is real: 0.900316, the first tone's height at that moment.

---

## The formula

Notation first, in words. The sigma sign adds the terms for every whole number n, negative ones included. Vertical bars, as in |c|, give the modulus: the length of the arrow c. The coefficient c_n is a complex number: its length sets the loudness of tone n, its angle where that arrow starts.

$$f(x)=\sum_{n=-\infty}^{\infty} c_n\, e^{inx}, \qquad c_n=\frac{1}{2\pi}\int_{-\pi}^{\pi} f(x)\, e^{-inx}\, dx$$

**Read it aloud:** the signal is a sum of spinning arrows; the amount of arrow n is the signal's average over a cycle, once turned back by n times the angle.

Two partner arrows, n and −n, give one real sine-and-cosine pair:

$$a_n=c_n+c_{-n}, \qquad b_n=i\,(c_n - c_{-n}), \qquad f(x)=c_0+\sum_{n=1}^{\infty} \big(a_n \cos nx+b_n \sin nx\big)$$

**Read it aloud:** the cosine amount is the sum of the partners; the sine amount is i times their difference.

For the square wave, f = +1 on (0, π) and −1 on (−π, 0):

$$c_n=\frac{2}{i\pi n}\ \ (n \text{ odd}), \qquad c_n=0\ \ (n \text{ even}), \qquad f(x)=\frac{4}{\pi}\Big(\sin x+\frac{\sin 3x}{3}+\frac{\sin 5x}{5}+\cdots\Big)$$

**Read it aloud:** only odd tones; arrow n > 0 starts straight down, its partner straight up, each of length two over π|n|; as sines, four over π n.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$ | position in the cycle, in radians | x = 2π × 220 × t, t in seconds | the pattern repeats every 2π |
| $f(x)$ | the signal's height at x | +1 on (0, π), −1 on (−π, 0) | every c_n grows in proportion |
| $n$ | tone number; arrow n turns n times per cycle | ±1, ±3, ±5: 220, 660, 1100 Hz | higher pitch, n × 220 Hz |
| $e^{inx}$ | the arrow of length 1 at angle nx | at x = 0 every arrow points to 1 | — |
| $c_n$ | amount of arrow n: length and starting angle | c_1 = −0.636620i, c_(−1) = +0.636620i | falls like 1/n across a jump |
| $a_n$, $b_n$ | cosine and sine amounts in the real form | a_n = 0; b_1, b_3, b_5 = 1.273240, 0.424413, 0.254648 | — |
| $S_N(x)$ | partial sum: the arrows from −N to N added | S_5(π/2) = 1.103474 | closer to f, except next to the jump |
| $N$ | highest tone kept | 1, 5, 21, 101 | overshoot moves toward the jump; its peak falls only toward 1.178980 |

### When it holds

- **Repeats every 2π, finite average size.** Otherwise, as for 1/x near 0, the averages do not exist.
- **Piecewise smooth, for each point.** With finitely many jumps, S_N(x) tends to f(x) where f is continuous and to the jump's midpoint at a jump: 0 at x = 0, however f(0) is set.
- **Also continuous, for uniform closeness.** Only without jumps does the largest error shrink to 0. Beside each jump the square wave's sums overshoot above 1.178980 for every N: the Gibbs phenomenon.
- **Finite average of |f|^2, for closeness on average.** Then the average of |f − S_N|^2 tends to 0 and Parseval holds.

---

## Why it works

### Step 0: arrows at different speeds average to nothing

An arrow that turns a whole number of times, k ≠ 0, per cycle points every way equally often, so it averages to 0. An arrow that does not turn averages to 1.

### Step 1: the averages, computed

For a whole number k ≠ 0, e^(ikx) has antiderivative e^(ikx)/(ik), by [Euler's formula](../01-Complex%20Numbers%20and%20the%20Plane/04-eulers-formula.md). At x = π and x = −π it takes the same value, since e^(ikπ) and e^(−ikπ) are both (−1)^k. With k = m − n, e^(imx) e^(−inx) is e^(ikx), so

$$\frac{1}{2\pi}\int_{-\pi}^{\pi} e^{imx}\, e^{-inx}\, dx=\begin{cases} 1 & m=n \\ 0 & m \neq n \end{cases}$$

This is orthogonality: two different arrows, one turned back against the other, average to zero.

### Step 2: each coefficient is an average

Suppose f is a sum of arrows c_m e^(imx). Multiply by e^(−inx), turning every arrow back by n times the angle. Arrow n stops turning; every other arrow still turns. Average over one cycle: by Step 1 only c_n survives. Swapping the average with the infinite sum needs the sum to converge well enough ([Limits and regions in the plane](../01-Complex%20Numbers%20and%20the%20Plane/06-complex-limits-series-and-regions.md)).

### Step 3: partners make a real signal

Expand the partners with Euler's formula: c_n e^(inx) + c_(−n) e^(−inx) = (c_n + c_(−n)) cos nx + i(c_n − c_(−n)) sin nx. That gives a_n and b_n. For a real signal c_(−n) is the conjugate of c_n (its mirror image in the real axis), so imaginary parts cancel, as in the picture.

### Step 4: smoothness sets how fast the coefficients fall

If f is smooth and repeats, [Integration by parts](../../06-Calculus%20and%20analysis/04-Integrals/04-integration-by-parts.md) shows the coefficient of the slope f′ is in times c_n; the boundary terms cancel because both factors repeat. So each derivative buys a factor 1/n. A jump allows none: the square wave's coefficients fall only like 1/n, so it sounds bright. A triangle wave, cornered but unbroken, falls like 1/n^2.

### Step 5: Parseval

The average of |f|^2 over a cycle equals the sum of |c_n|^2: the power of a signal is the sum of the powers of its tones. For the square wave |f|^2 = 1, and each odd pair contributes 2 × 4/(π^2 n^2), so

$$1=\frac{8}{\pi^2}\Big(1+\frac{1}{9}+\frac{1}{25}+\cdots\Big), \qquad 1+\frac{1}{9}+\frac{1}{25}+\cdots=\frac{\pi^2}{8}$$

Three terms give 1.151111; the full odd sum is 1.233700550.

<details>
<summary>Detailed proof: Parseval's identity, in outline</summary>

Let S_N be the sum of the arrows from −N to N. For |n| ≤ N the average of (f − S_N) e^(−inx) is c_n − c_n = 0 by Step 2, so the error f − S_N is orthogonal to S_N.

Orthogonal pieces add their powers, as a right triangle's sides do. The average of |f|^2 is that of |S_N|^2 plus that of |f − S_N|^2. By Step 1 the first is the sum of |c_n|^2 for |n| ≤ N. For N = 5 the mean-square error is 1 − 0.933056 = 0.066944, matched by integrating (f − S_5)^2.

The error is never negative, so partial sums of |c_n|^2 never exceed the average of |f|^2 (Bessel's inequality). Equality in the limit says the arrows suffice: Completeness of sines and cosines.

</details>

The real form reaches the same series with three formulas where one does.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Split at the jump | c_n = (1/2π)(integral of e^(−inx) over (0, π) − over (−π, 0)) | two pieces |
| High half | (1 − e^(−inπ))/(in) = (1 − (−1)^n)/(in) | 2/(in) for odd n, 0 for even |
| Low half | (e^(inπ) − 1)/(in) = ((−1)^n − 1)/(in) | −2/(in) for odd n |
| Difference over 2π | (4/(in))/(2π) | 2/(iπn) |
| Odd tones 1, 3, 5 | 2/(iπ), 2/(3iπ), 2/(5iπ) | −0.636620i, −0.212207i, −0.127324i |
| Sine amounts | b_n = i(c_n − c_(−n)) = 4/(πn) | 1.273240, 0.424413, 0.254648 |
| Three tones at x = π/2 | (4/π)(1 − 1/3 + 1/5) | **1.103474** |

Mid-way through the high half, three tones already stand at 1.103474 against a true level of 1: 220, 660 and 1100 Hz carry most of the sound.

### The picture: three tones against the square wave

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Square wave and its first Fourier partial sums over one cycle"
    x-axis "Position in the cycle, x (eighths of pi)" [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    y-axis "Height (volts, on the ±1 scale)" -1.5 --> 1.5
    line [0.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.00, -1.00, -1.00, -1.00, -1.00, -1.00, -1.00, -1.00, 0.00]
    line [0.00, 0.49, 0.90, 1.18, 1.27, 1.18, 0.90, 0.49, 0.00, -0.49, -0.90, -1.18, -1.27, -1.18, -0.90, -0.49, 0.00]
    line [0.00, 1.11, 1.02, 0.92, 1.10, 0.92, 1.02, 1.11, 0.00, -1.11, -1.02, -0.92, -1.10, -0.92, -1.02, -1.11, 0.00]
```

Orange: the square wave, through 0 at the jumps, where the series lands. Teal: the first tone alone, S_1, height 1.27. Dark blue: tones 1, 3 and 5, S_5, already square-shouldered and rippling about the true level.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| 1/π in front of the average, not 1/(2π) | c_1 = −1.273240i; S_5(π/2) = 2.206949 | 1/π belongs to the real form; every tone doubles |
| e^(+inx) in the average | c_1 = +0.636620i; S_5(π/2) = −1.103474 | that average is c_(−n): the wave flips |
| Only n > 0 kept | 0.5000 at x = π/2, not 1 | each real tone is two arrows; one gives half |
| Continuity dropped: the value at the jump | S_5(0) = S_101(0) = 0.000000 | a jump gets the midpoint of −1 and +1 |

---

## Code, from first principles, and it actually runs

Two roads to every coefficient, n from −7 to 7: the closed form 2/(iπn), and the average itself by Simpson's rule (a weighted sum over 2,000 slices per half-cycle). Sine amounts come from the partners and from the real average of f times sin nx. Parseval is checked two ways: the odd sum against π^2/8, and S_5's mean-square error against a direct integral. Gibbs peaks approach (2/π) Si(π), where Si(π) is the integral of sin t / t from 0 to π.

### Python

```python
# Fourier series of a square wave -- the check behind the card.  Standard library.
# f(x) = +1 on (0, pi), -1 on (-pi, 0), repeating every 2 pi: a synthesiser's square tone.
# Road 1: the closed form c_n = 2/(i pi n) for odd n, 0 for even n.
# Road 2: each c_n as an average, (1/2 pi) times the integral of f(x) e^(-inx), by Simpson's rule.
# Parseval, the mean-square error and the Gibbs peak each get a second road as well.
import math
PI = math.pi

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

def simpson(g, a, b, m=2000):                 # m even panels
    h = (b - a) / m
    return (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, m))) * h / 3

def spin(n, x): return complex(math.cos(n * x), math.sin(n * x))                  # e^(inx)
def average(g): return (simpson(g, 0, PI) - simpson(g, -PI, 0)) / (2 * PI)        # of f(x) g(x)
def closed(n): return 2 / (1j * PI * n) if n % 2 else 0j
def partial(x, N): return sum(closed(n) * spin(n, x) for n in range(-N, N + 1)).real  # S_N(x)

ns = range(-7, 8)
numeric = {n: average(lambda x: spin(-n, x)) for n in ns}
print("c_n closed form, n = 1, 3, 5: " + ", ".join(show(closed(n)) for n in (1, 3, 5)))
print("c_n by averaging, n = 1, 3, 5: " + ", ".join(show(numeric[n]) for n in (1, 3, 5)))
print("c_n by averaging, n = 0, 2, -1: " + ", ".join(show(numeric[n]) for n in (0, 2, -1)))
b_conv = [(1j * (closed(n) - closed(-n))).real for n in (1, 3, 5)]
b_real = [average(lambda x: math.sin(n * x)) * 2 for n in (1, 3, 5)]
print("b_n = i(c_n - c_-n), n = 1, 3, 5: " + ", ".join(f"{b:.6f}" for b in b_conv) + "; by (1/pi) int f sin nx: " + ", ".join(f"{b:.6f}" for b in b_real))
print(f"a_n = c_n + c_-n, n = 1, 3: {(closed(1) + closed(-1)).real:.6f}, {(closed(3) + closed(-3)).real:.6f}; tone 220 Hz: harmonics at {220}, {3 * 220}, {5 * 220} Hz")
xs = [k * PI / 8 for k in range(17)]
print("chart, square wave: " + ", ".join(f"{(0 if k % 8 == 0 else 1 if k < 8 else -1):.2f}" for k in range(17)))
for N, name in ((1, "first harmonic S_1"), (5, "three harmonics S_5")):
    print(f"chart, {name}: " + ", ".join(f"{round(partial(x, N), 2) + 0.0:.2f}" for x in xs))
arrow, partner = closed(1) * spin(1, PI / 4), closed(-1) * spin(-1, PI / 4)
print(f"arrows at x = pi/4: {show(arrow)} + {show(partner)} = {show(arrow + partner)}; |c_1| = {abs(closed(1)):.6f}")
print(f"figure, 160 per unit, origin (120, 120), arrow ({120 + 160 * arrow.real:.2f}, {120 - 160 * arrow.imag:.2f}), partner ({120 + 160 * partner.real:.2f}, {120 - 160 * partner.imag:.2f}), sum ({120 + 160 * (arrow + partner).real:.2f}, 120), radius {160 * abs(closed(1)):.2f}")
p5 = sum(abs(closed(n)) ** 2 for n in range(-5, 6))
odd = sum(1 / n ** 2 for n in range(1, 2 * 10 ** 6, 2)) + 1 / (4 * 10 ** 6)    # plus the tail, about 1/(2N)
print(f"Parseval: 1 + 1/9 + 1/25 = {1 + 1 / 9 + 1 / 25:.6f}; odd n to 2e6 plus tail = {odd:.9f}; pi^2/8 = {PI ** 2 / 8:.9f}")
S5 = lambda x: partial(x, 5)
msq = (simpson(lambda x: (1 - S5(x)) ** 2, 0, PI) + simpson(lambda x: (-1 - S5(x)) ** 2, -PI, 0)) / (2 * PI)
print(f"S_5: sum |c_n|^2 = {p5:.6f}; mean-square error by Parseval {1 - p5:.6f}, by integrating (f - S_5)^2 {msq:.6f}")
peaks = [max(partial(k * 4 * PI / ((N + 1) * 2000), N) for k in range(1, 2001)) for N in (5, 21, 101)]
gibbs = 2 / PI * simpson(lambda t: math.sin(t) / t if t else 1.0, 0, PI)
print("Gibbs peak of S_N, N = 5, 21, 101: " + ", ".join(f"{p:.6f}" for p in peaks) + f"; limit (2/pi) Si(pi) = {gibbs:.6f}")
print(f"hypothesis dropped, at the jump x = 0: S_5 = {partial(0, 5):.6f}, S_101 = {partial(0, 101):.6f}; f is -1 just left, +1 just right")
print(f"mistake, 1/pi for 1/2 pi: c_1 = {show(2 * closed(1))}, S_5(pi/2) = {2 * S5(PI / 2):.6f}; true S_5(pi/2) = {S5(PI / 2):.6f}")
flip = {n: average(lambda x: spin(n, x)) for n in range(-5, 6)}                    # e^(+inx) in the average
print(f"mistake, e^(+inx) in the average: c_1 = {show(flip[1])}, S_5(pi/2) = {sum(flip[n] * spin(n, PI / 2) for n in flip).real:.6f}")
half = sum(closed(n) * spin(n, PI / 2) for n in range(1, 200001, 2))
print(f"mistake, n > 0 only, n to 200000, at x = pi/2: {half.real:.4f} instead of 1")
assert all(abs(numeric[n] - closed(n)) < 1e-9 for n in ns)                        # average against formula
assert all(abs(u - v) < 1e-9 for u, v in zip(b_conv, b_real))                     # complex form against real form
assert abs(msq - (1 - p5)) < 1e-9 and abs(odd - PI ** 2 / 8) < 1e-9               # Parseval, two ways
assert peaks[0] > peaks[1] > peaks[2] > gibbs and peaks[2] - gibbs < 1e-3         # Gibbs does not go away
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
c_n closed form, n = 1, 3, 5: 0.000000 - 0.636620i, 0.000000 - 0.212207i, 0.000000 - 0.127324i
c_n by averaging, n = 1, 3, 5: 0.000000 - 0.636620i, 0.000000 - 0.212207i, 0.000000 - 0.127324i
c_n by averaging, n = 0, 2, -1: 0.000000 + 0.000000i, 0.000000 + 0.000000i, 0.000000 + 0.636620i
b_n = i(c_n - c_-n), n = 1, 3, 5: 1.273240, 0.424413, 0.254648; by (1/pi) int f sin nx: 1.273240, 0.424413, 0.254648
a_n = c_n + c_-n, n = 1, 3: 0.000000, 0.000000; tone 220 Hz: harmonics at 220, 660, 1100 Hz
chart, square wave: 0.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.00, -1.00, -1.00, -1.00, -1.00, -1.00, -1.00, -1.00, 0.00
chart, first harmonic S_1: 0.00, 0.49, 0.90, 1.18, 1.27, 1.18, 0.90, 0.49, 0.00, -0.49, -0.90, -1.18, -1.27, -1.18, -0.90, -0.49, 0.00
chart, three harmonics S_5: 0.00, 1.11, 1.02, 0.92, 1.10, 0.92, 1.02, 1.11, 0.00, -1.11, -1.02, -0.92, -1.10, -0.92, -1.02, -1.11, 0.00
arrows at x = pi/4: 0.450158 - 0.450158i + 0.450158 + 0.450158i = 0.900316 + 0.000000i; |c_1| = 0.636620
figure, 160 per unit, origin (120, 120), arrow (192.03, 192.03), partner (192.03, 47.97), sum (264.05, 120), radius 101.86
Parseval: 1 + 1/9 + 1/25 = 1.151111; odd n to 2e6 plus tail = 1.233700550; pi^2/8 = 1.233700550
S_5: sum |c_n|^2 = 0.933056; mean-square error by Parseval 0.066944, by integrating (f - S_5)^2 0.066944
Gibbs peak of S_N, N = 5, 21, 101: 1.188357, 1.179669, 1.179012; limit (2/pi) Si(pi) = 1.178980
hypothesis dropped, at the jump x = 0: S_5 = 0.000000, S_101 = 0.000000; f is -1 just left, +1 just right
mistake, 1/pi for 1/2 pi: c_1 = 0.000000 - 1.273240i, S_5(pi/2) = 2.206949; true S_5(pi/2) = 1.103474
mistake, e^(+inx) in the average: c_1 = 0.000000 + 0.636620i, S_5(pi/2) = -1.103474
mistake, n > 0 only, n to 200000, at x = pi/2: 0.5000 instead of 1
ALL CHECKS PASS
```

### Rust

Same labels, built with `rustc --edition 2021 -O`, with its own complex type.

```rust
// Fourier series of a square wave -- the same check as the Python, in Rust.  No crates.
// f(x) = +1 on (0, pi), -1 on (-pi, 0), repeating every 2 pi: a synthesiser's square tone.
// Road 1: the closed form c_n = 2/(i pi n) for odd n, 0 for even n.
// Road 2: each c_n as an average, (1/2 pi) times the integral of f(x) e^(-inx), by Simpson's rule.
// Parseval, the mean-square error and the Gibbs peak each get a second road as well.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn simpson(g: &dyn Fn(f64) -> C, a: f64, b: f64, m: usize) -> C { // m even panels
    let h = (b - a) / m as f64;
    let mut s = add(g(a), g(b));
    for k in 1..m { s = add(s, sc(g(a + k as f64 * h), if k % 2 == 1 { 4.0 } else { 2.0 })) }
    sc(s, h / 3.0)
}
fn spin(n: i64, x: f64) -> C { c((n as f64 * x).cos(), (n as f64 * x).sin()) } // e^(inx)
fn average(g: &dyn Fn(f64) -> C) -> C { sc(sub(simpson(g, 0.0, PI, 2000), simpson(g, -PI, 0.0, 2000)), 1.0 / (2.0 * PI)) } // of f(x) g(x)
fn closed(n: i64) -> C { if n % 2 != 0 { c(0.0, -2.0 / (PI * n as f64)) } else { c(0.0, 0.0) } }
fn partial(x: f64, n: i64) -> f64 { (-n..=n).map(|k| mul(closed(k), spin(k, x)).re).sum() } // S_N(x)
fn real(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { simpson(&|x| c(g(x), 0.0), a, b, 2000).re }
fn list(v: &[f64], d: usize) -> String { // d = 2 rounds first, as the Python does, so no -0.00
    v.iter().map(|&x| format!("{:.*}", d, if d == 2 { (x * 100.0).round() / 100.0 + 0.0 } else { x })).collect::<Vec<_>>().join(", ")
}
fn main() {
    let numeric: Vec<C> = (-7..=7).map(|n| average(&|x| spin(-n, x))).collect(); // index n + 7
    println!("c_n closed form, n = 1, 3, 5: {}", [1, 3, 5].map(|n| show(closed(n))).join(", "));
    println!("c_n by averaging, n = 1, 3, 5: {}", [1, 3, 5].map(|n| show(numeric[n as usize + 7])).join(", "));
    println!("c_n by averaging, n = 0, 2, -1: {}", [0i64, 2, -1].map(|n| show(numeric[(n + 7) as usize])).join(", "));
    let b_conv = [1, 3, 5].map(|n| mul(c(0.0, 1.0), sub(closed(n), closed(-n))).re);
    let b_real = [1, 3, 5].map(|n| average(&|x| c((n as f64 * x).sin(), 0.0)).re * 2.0);
    println!("b_n = i(c_n - c_-n), n = 1, 3, 5: {}; by (1/pi) int f sin nx: {}", list(&b_conv, 6), list(&b_real, 6));
    println!("a_n = c_n + c_-n, n = 1, 3: {:.6}, {:.6}; tone 220 Hz: harmonics at {}, {}, {} Hz", add(closed(1), closed(-1)).re, add(closed(3), closed(-3)).re, 220, 3 * 220, 5 * 220);
    let xs: Vec<f64> = (0..17).map(|k| k as f64 * PI / 8.0).collect();
    let sq: Vec<f64> = (0..17).map(|k| if k % 8 == 0 { 0.0 } else if k < 8 { 1.0 } else { -1.0 }).collect();
    println!("chart, square wave: {}", list(&sq, 2));
    for (n, name) in [(1, "first harmonic S_1"), (5, "three harmonics S_5")] {
        println!("chart, {}: {}", name, list(&xs.iter().map(|&x| partial(x, n)).collect::<Vec<_>>(), 2));
    }
    let (arrow, partner) = (mul(closed(1), spin(1, PI / 4.0)), mul(closed(-1), spin(-1, PI / 4.0)));
    let sum = add(arrow, partner);
    println!("arrows at x = pi/4: {} + {} = {}; |c_1| = {:.6}", show(arrow), show(partner), show(sum), modulus(closed(1)));
    println!("figure, 160 per unit, origin (120, 120), arrow ({:.2}, {:.2}), partner ({:.2}, {:.2}), sum ({:.2}, 120), radius {:.2}",
        120.0 + 160.0 * arrow.re, 120.0 - 160.0 * arrow.im, 120.0 + 160.0 * partner.re, 120.0 - 160.0 * partner.im, 120.0 + 160.0 * sum.re, 160.0 * modulus(closed(1)));
    let p5: f64 = (-5..=5).map(|n| modulus(closed(n)).powi(2)).sum();
    let odd: f64 = (1..2_000_000u64).step_by(2).map(|n| 1.0 / (n as f64 * n as f64)).sum::<f64>() + 1.0 / 4e6; // plus the tail
    println!("Parseval: 1 + 1/9 + 1/25 = {:.6}; odd n to 2e6 plus tail = {:.9}; pi^2/8 = {:.9}", 1.0 + 1.0 / 9.0 + 1.0 / 25.0, odd, PI * PI / 8.0);
    let msq = (real(&|x| (1.0 - partial(x, 5)).powi(2), 0.0, PI) + real(&|x| (-1.0 - partial(x, 5)).powi(2), -PI, 0.0)) / (2.0 * PI);
    println!("S_5: sum |c_n|^2 = {:.6}; mean-square error by Parseval {:.6}, by integrating (f - S_5)^2 {:.6}", p5, 1.0 - p5, msq);
    let peaks = [5i64, 21, 101].map(|n| (1..=2000).map(|k| partial(k as f64 * 4.0 * PI / ((n + 1) as f64 * 2000.0), n)).fold(f64::MIN, f64::max));
    let gibbs = 2.0 / PI * real(&|t| if t == 0.0 { 1.0 } else { t.sin() / t }, 0.0, PI);
    println!("Gibbs peak of S_N, N = 5, 21, 101: {}; limit (2/pi) Si(pi) = {:.6}", list(&peaks, 6), gibbs);
    println!("hypothesis dropped, at the jump x = 0: S_5 = {:.6}, S_101 = {:.6}; f is -1 just left, +1 just right", partial(0.0, 5) + 0.0, partial(0.0, 101) + 0.0);
    println!("mistake, 1/pi for 1/2 pi: c_1 = {}, S_5(pi/2) = {:.6}; true S_5(pi/2) = {:.6}", show(sc(closed(1), 2.0)), 2.0 * partial(PI / 2.0, 5), partial(PI / 2.0, 5));
    let flip: Vec<C> = (-5..=5).map(|n| average(&|x| spin(n, x))).collect(); // e^(+inx) in the average
    let rebuilt: f64 = (-5..=5).map(|n| mul(flip[(n + 5) as usize], spin(n, PI / 2.0)).re).sum();
    println!("mistake, e^(+inx) in the average: c_1 = {}, S_5(pi/2) = {:.6}", show(flip[6]), rebuilt);
    let half: f64 = (1..200001i64).step_by(2).map(|n| mul(closed(n), spin(n, PI / 2.0)).re).sum();
    println!("mistake, n > 0 only, n to 200000, at x = pi/2: {:.4} instead of 1", half);
    assert!((-7..=7).all(|n| modulus(sub(numeric[(n + 7) as usize], closed(n))) < 1e-9)); // average against formula
    assert!(b_conv.iter().zip(b_real.iter()).all(|(u, v)| (u - v).abs() < 1e-9)); // complex form against real form
    assert!((msq - (1.0 - p5)).abs() < 1e-9 && (odd - PI * PI / 8.0).abs() < 1e-9); // Parseval, two ways
    assert!(peaks[0] > peaks[1] && peaks[1] > peaks[2] && peaks[2] > gibbs && peaks[2] - gibbs < 1e-3); // Gibbs stays
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
c_n closed form, n = 1, 3, 5: 0.000000 - 0.636620i, 0.000000 - 0.212207i, 0.000000 - 0.127324i
c_n by averaging, n = 1, 3, 5: 0.000000 - 0.636620i, 0.000000 - 0.212207i, 0.000000 - 0.127324i
c_n by averaging, n = 0, 2, -1: 0.000000 + 0.000000i, 0.000000 + 0.000000i, 0.000000 + 0.636620i
b_n = i(c_n - c_-n), n = 1, 3, 5: 1.273240, 0.424413, 0.254648; by (1/pi) int f sin nx: 1.273240, 0.424413, 0.254648
a_n = c_n + c_-n, n = 1, 3: 0.000000, 0.000000; tone 220 Hz: harmonics at 220, 660, 1100 Hz
chart, square wave: 0.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.00, -1.00, -1.00, -1.00, -1.00, -1.00, -1.00, -1.00, 0.00
chart, first harmonic S_1: 0.00, 0.49, 0.90, 1.18, 1.27, 1.18, 0.90, 0.49, 0.00, -0.49, -0.90, -1.18, -1.27, -1.18, -0.90, -0.49, 0.00
chart, three harmonics S_5: 0.00, 1.11, 1.02, 0.92, 1.10, 0.92, 1.02, 1.11, 0.00, -1.11, -1.02, -0.92, -1.10, -0.92, -1.02, -1.11, 0.00
arrows at x = pi/4: 0.450158 - 0.450158i + 0.450158 + 0.450158i = 0.900316 + 0.000000i; |c_1| = 0.636620
figure, 160 per unit, origin (120, 120), arrow (192.03, 192.03), partner (192.03, 47.97), sum (264.05, 120), radius 101.86
Parseval: 1 + 1/9 + 1/25 = 1.151111; odd n to 2e6 plus tail = 1.233700550; pi^2/8 = 1.233700550
S_5: sum |c_n|^2 = 0.933056; mean-square error by Parseval 0.066944, by integrating (f - S_5)^2 0.066944
Gibbs peak of S_N, N = 5, 21, 101: 1.188357, 1.179669, 1.179012; limit (2/pi) Si(pi) = 1.178980
hypothesis dropped, at the jump x = 0: S_5 = 0.000000, S_101 = 0.000000; f is -1 just left, +1 just right
mistake, 1/pi for 1/2 pi: c_1 = 0.000000 - 1.273240i, S_5(pi/2) = 2.206949; true S_5(pi/2) = 1.103474
mistake, e^(+inx) in the average: c_1 = 0.000000 + 0.636620i, S_5(pi/2) = -1.103474
mistake, n > 0 only, n to 200000, at x = pi/2: 0.5000 instead of 1
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves closeness on average, Parseval and the coefficient formula for every signal meeting the conditions, and the square wave's amounts exactly.

- Take a signal that repeats every 2π, with a finite average of |f|^2. The average of |f − S_N|^2 tends to 0 as N grows.
- For the same signal, the sum of |c_n|^2 over every whole number n equals the average of |f|^2. This is Parseval.
- Suppose f is a sum of arrows c_m e^(imx), and the lengths |c_m| have a finite sum. Then each c_n is the average of f(x) e^(−inx).
- Take any f that is +1 on (0, π) and −1 on (−π, 0). Then c_n = 2/(iπn) for every odd n, and c_n = 0 for every even n.
- The small sums come out exact: tones at 220, 660 and 1100 Hz, 1 − 1/3 + 1/5 = 13/15, and 1 + 1/9 + 1/25 = 259/225.

Closeness at each point, uniform closeness, the Gibbs overshoot, a_n and b_n, and π^2/8 are left to the Python and Rust checks.

```lean
-- Fourier series: for a signal that repeats every 2π and has a finite average of |f|^2, the sums of the arrows c_n e^(inx), with each c_n the average of f(x) e^(−inx) over one cycle, close in on the signal on average and Parseval holds; a convergent sum of arrows gives back its own amounts as these averages; and the square wave's amounts are 2/(iπn) for odd n and 0 for even n.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Tactic.NormNum
import Mathlib.Order.Filter.AtTopBot.Interval
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Complex MeasureTheory Filter Topology
open Real

lemma fs_fourier_coe (n : ℤ) (x : ℝ) :
    haveI : Fact (0 < 2 * π) := ⟨by positivity⟩
    fourier n (x : AddCircle (2 * π)) = Complex.exp (n * x * I) := by
  rw [fourier_coe_apply]
  congr 1
  have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  field_simp
  push_cast; ring

#print axioms fs_fourier_coe

lemma fs_haar_integral (g : ℝ → ℝ) :
    haveI : Fact (0 < 2 * π) := ⟨by positivity⟩
    ∫ t : AddCircle (2 * π), AddCircle.liftIoc (2 * π) (-π) g t ∂AddCircle.haarAddCircle
      = (1 / (2 * π)) * ∫ x in (-π)..π, g x := by
  haveI : Fact (0 < 2 * π) := ⟨by positivity⟩
  rw [AddCircle.integral_haarAddCircle, AddCircle.integral_liftIoc_eq_intervalIntegral,
    show -π + 2 * π = π by ring, smul_eq_mul, one_div]

#print axioms fs_haar_integral

lemma fs_L2_norm_sq {α : Type*} [MeasurableSpace α] {μ : Measure α} (G : Lp ℂ 2 μ) :
    ‖G‖ ^ 2 = ∫ t, ‖G t‖ ^ 2 ∂μ := by
  have h := L2.inner_def (𝕜 := ℂ) G G
  rw [inner_self_eq_norm_sq_to_K] at h
  simp_rw [inner_self_eq_norm_sq_to_K] at h
  apply Complex.ofReal_injective
  rw [integral_complex_ofReal.symm]
  push_cast
  exact h

#print axioms fs_L2_norm_sq

lemma fs_exp_odd (n : ℤ) (hn : Odd n) : Complex.exp (n * π * I) = -1 := by
  obtain ⟨k, rfl⟩ := hn
  have : ((2 * k + 1 : ℤ) : ℂ) * π * I = k * (2 * π * I) + π * I := by push_cast; ring
  rw [this, Complex.exp_add, exp_int_mul_two_pi_mul_I, exp_pi_mul_I, one_mul]

#print axioms fs_exp_odd

lemma fs_exp_even (n : ℤ) (hn : Even n) : Complex.exp (n * π * I) = 1 := by
  obtain ⟨k, rfl⟩ := hn
  have : ((k + k : ℤ) : ℂ) * π * I = k * (2 * π * I) := by push_cast; ring
  rw [this, exp_int_mul_two_pi_mul_I]

#print axioms fs_exp_even

lemma fs_exp_neg (k : ℤ) : Complex.exp (-(k * π * I)) = Complex.exp (k * π * I) := by
  rw [← mul_one (Complex.exp (-(k * π * I))), ← exp_int_mul_two_pi_mul_I k, ← Complex.exp_add]
  congr 1; ring

#print axioms fs_exp_neg

lemma fs_int_exp (n : ℤ) (hn : n ≠ 0) (a b : ℝ) :
    ∫ x in a..b, Complex.exp (-(n * x * I)) =
      (Complex.exp (-(n * b * I)) - Complex.exp (-(n * a * I))) / (-(n * I)) := by
  have hc : (-(n * I) : ℂ) ≠ 0 := by simp [hn]
  simp_rw [show ∀ x : ℝ, -((n : ℂ) * x * I) = (-(n * I)) * x by intro; ring]
  exact integral_exp_mul_complex hc

#print axioms fs_int_exp

lemma fs_int_exp_cycle (n : ℤ) (hn : n ≠ 0) :
    ∫ x in (-π)..π, Complex.exp (-(n * x * I)) = 0 := by
  rw [fs_int_exp n hn, fs_exp_neg]
  push_cast
  rw [show -((n : ℂ) * -π * I) = n * π * I by ring, sub_self, zero_div]

#print axioms fs_int_exp_cycle

lemma fs_square_split (f : ℝ → ℂ) (hpos : ∀ x ∈ Set.Ioo 0 π, f x = 1)
    (hneg : ∀ x ∈ Set.Ioo (-π) 0, f x = -1) (n : ℤ) :
    ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) =
      -(∫ x in (-π)..0, Complex.exp (-(n * x * I))) + ∫ x in (0 : ℝ)..π, Complex.exp (-(n * x * I)) := by
  have hp := pi_pos
  have i1 : IntervalIntegrable (fun x : ℝ => f x * Complex.exp (-(n * x * I))) volume (-π) 0 := by
    have : IntervalIntegrable (fun x : ℝ => -Complex.exp (-(n * x * I))) volume (-π) 0 :=
      (by fun_prop : Continuous fun x : ℝ => -Complex.exp (-(n * x * I))).intervalIntegrable _ _
    refine this.congr_uIoo fun x hx => ?_
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp [hneg x hx]
  have i2 : IntervalIntegrable (fun x : ℝ => f x * Complex.exp (-(n * x * I))) volume 0 π := by
    have : IntervalIntegrable (fun x : ℝ => Complex.exp (-(n * x * I))) volume 0 π :=
      (by fun_prop : Continuous fun x : ℝ => Complex.exp (-(n * x * I))).intervalIntegrable _ _
    refine this.congr_uIoo fun x hx => ?_
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp [hpos x hx]
  rw [← intervalIntegral.integral_add_adjacent_intervals i1 i2, ← intervalIntegral.integral_neg]
  congr 1
  · refine intervalIntegral.integral_congr_Ioo_of_le (by linarith) fun x hx => ?_
    simp [hneg x hx]
  · refine intervalIntegral.integral_congr_Ioo_of_le (by linarith) fun x hx => ?_
    simp [hpos x hx]

#print axioms fs_square_split

/-- **A repeating signal is the sum of its arrows, and Parseval holds.** Let f be a signal that
repeats every 2π and whose square |f|^2 has a finite average over one cycle (f is measurable
and the integral of |f(x)|^2 from −π to π is finite). Let c_n be the average over one cycle of
f(x) e^(−inx), that is c_n = (1/2π) ∫_{−π}^{π} f(x) e^(−inx) dx. Let S_N be the sum of the
arrows c_n e^(inx) for n from −N to N. Then the average of |f − S_N|^2 over a cycle tends to 0
as N grows, and the sum over all whole numbers n of |c_n|^2 equals the average of |f|^2. -/
theorem fourier_series_converges_in_mean_and_parseval
    (f : ℝ → ℂ) (hper : Function.Periodic f (2 * π))
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π)))
    (c : ℤ → ℂ)
    (hc : ∀ n : ℤ, c n = (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I))) :
    Tendsto (fun N : ℕ => (1 / (2 * π)) * ∫ x in (-π)..π,
        ‖f x - ∑ n ∈ Finset.Icc (-(N : ℤ)) N, c n * Complex.exp (n * x * I)‖ ^ 2) atTop (𝓝 0) ∧
      HasSum (fun n : ℤ => ‖c n‖ ^ 2) ((1 / (2 * π)) * ∫ x in (-π)..π, ‖f x‖ ^ 2) := by
  haveI hT : Fact (0 < 2 * π) := ⟨by positivity⟩
  have hab : -π + 2 * π = π := by ring
  have hf' : MemLp f 2 (volume.restrict (Set.Ioc (-π) (-π + 2 * π))) := by rw [hab]; exact hf
  have hL := (hf'.memLp_liftIoc (T := 2 * π)).haarAddCircle
  set F := hL.toLp with hFdef
  have hcoef : ∀ n : ℤ, fourierCoeff (F : AddCircle (2 * π) → ℂ) n = c n := by
    intro n
    rw [fourierCoeff_congr_ae hL.coeFn_toLp, fourierCoeff_eq_intervalIntegral _ n (-π), hab, hc n,
      Complex.real_smul]
    congr 1
    · push_cast; ring
    · apply intervalIntegral.integral_congr_ae
      refine ae_of_all _ fun x hx => ?_
      rw [Set.uIoc_of_le (by linarith [Real.pi_pos])] at hx
      rw [AddCircle.liftIoc_coe_apply (by rwa [hab]), fs_fourier_coe, smul_eq_mul, mul_comm]
      congr 2
      push_cast; ring
  constructor
  · have hS := hasSum_fourier_series_L2 F
    simp_rw [hcoef] at hS
    have h1 := (hS.comp (Finset.tendsto_Icc_neg (R := ℤ)))
    have h2 := (tendsto_iff_norm_sub_tendsto_zero.mp h1).pow 2
    rw [zero_pow two_ne_zero] at h2
    refine h2.congr fun N => ?_
    simp only [Function.comp_apply]
    rw [norm_sub_rev, fs_L2_norm_sq,
      ← fs_haar_integral (fun x => ‖f x - ∑ n ∈ Finset.Icc (-(N : ℤ)) N,
        c n * Complex.exp (n * x * I)‖ ^ 2)]
    have hsum : (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourierLp (T := 2 * π) 2 i) =
        ContinuousMap.toLp 2 AddCircle.haarAddCircle ℂ
          (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourier i) := by
      rw [map_sum]; simp [map_smul]
    rw [hsum]
    apply integral_congr_ae
    filter_upwards [Lp.coeFn_sub F (ContinuousMap.toLp 2 AddCircle.haarAddCircle ℂ
          (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourier i)), hL.coeFn_toLp,
        ContinuousMap.coeFn_toLp (p := 2) (𝕜 := ℂ) (μ := AddCircle.haarAddCircle)
          (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourier i)] with t h1 h2 h3
    rw [h1, Pi.sub_apply, h2, h3]
    simp only [AddCircle.liftIoc, Function.comp_apply, Set.domRestrict_apply,
      AddCircle.coe_equivIoc, ContinuousMap.coe_sum, ContinuousMap.coe_smul, Finset.sum_apply,
      Pi.smul_apply, smul_eq_mul]
    congr 3
    refine Finset.sum_congr rfl fun n _ => ?_
    rw [← fs_fourier_coe, AddCircle.coe_equivIoc]
  · have hP := hasSum_sq_fourierCoeff F
    simp_rw [hcoef] at hP
    convert hP using 1
    rw [← fs_haar_integral]
    apply integral_congr_ae
    filter_upwards [hL.coeFn_toLp] with t ht
    rw [ht]
    rfl

/-- **Each coefficient is an average.** If a signal f is a sum of arrows c_m e^(imx) over all
whole numbers m, and the sum converges well enough (the lengths |c_m| have a finite sum), then
for every whole number n the amount c_n is the average over one cycle of f(x) e^(−inx):
c_n = (1/2π) ∫_{−π}^{π} f(x) e^(−inx) dx. -/
theorem fourier_coefficient_eq_average
    (c : ℤ → ℂ) (hc : Summable fun m : ℤ => ‖c m‖)
    (f : ℝ → ℂ) (hf : ∀ x : ℝ, f x = ∑' m : ℤ, c m * Complex.exp (m * x * I)) (n : ℤ) :
    c n = (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) := by
  have hπ : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  let g : ℤ → C(ℝ, ℂ) := fun m =>
    ⟨fun x => c m * Complex.exp (m * x * I) * Complex.exp (-(n * x * I)), by fun_prop⟩
  have hsum : Summable fun m => ‖(g m).restrict
      (⟨Set.uIcc (-π) π, isCompact_uIcc⟩ : TopologicalSpace.Compacts ℝ)‖ := by
    refine Summable.of_nonneg_of_le (fun _ => norm_nonneg _) (fun m => ?_) hc
    refine (ContinuousMap.norm_le _ (norm_nonneg _)).mpr fun x => ?_
    simp only [ContinuousMap.restrict_apply, ContinuousMap.coe_mk, g, norm_mul]
    rw [show (m : ℂ) * (x : ℝ) * I = ((m * x : ℝ) : ℂ) * I by push_cast; ring,
      show -((n : ℂ) * (x : ℝ) * I) = ((-(n * x) : ℝ) : ℂ) * I by push_cast; ring,
      Complex.norm_exp_ofReal_mul_I, Complex.norm_exp_ofReal_mul_I]
    simp
  have key := intervalIntegral.tsum_intervalIntegral_eq_of_summable_norm hsum
  have hint : ∀ m, ∫ x in (-π)..π, g m x = if m = n then 2 * π * c n else 0 := by
    intro m
    simp only [ContinuousMap.coe_mk, g]
    split_ifs with hmn
    · subst hmn
      simp_rw [mul_assoc, ← Complex.exp_add, add_neg_cancel, Complex.exp_zero, mul_one]
      simp
      ring
    · have : (fun x : ℝ => c m * Complex.exp (m * x * I) * Complex.exp (-(n * x * I))) =
          fun x : ℝ => c m * Complex.exp (-(((n - m : ℤ) : ℂ) * x * I)) := by
        funext x
        rw [mul_assoc, ← Complex.exp_add]
        congr 2
        push_cast; ring
      rw [this, intervalIntegral.integral_const_mul,
        fs_int_exp_cycle _ (sub_ne_zero.mpr (Ne.symm hmn)), mul_zero]
  have hfx : (fun x : ℝ => f x * Complex.exp (-(n * x * I))) = fun x => ∑' m, g m x := by
    funext x
    rw [hf, ← tsum_mul_right]
    rfl
  rw [hfx, ← key]
  simp_rw [hint]
  rw [tsum_ite_eq]
  field_simp

/-- **The square wave has only odd tones.** Let f be +1 on (0, π) and −1 on (−π, 0). Then the
average over one cycle of f(x) e^(−inx) is 2/(iπn) for every odd n and 0 for every even n. -/
theorem square_wave_fourier_coefficients
    (f : ℝ → ℂ) (hpos : ∀ x ∈ Set.Ioo 0 π, f x = 1) (hneg : ∀ x ∈ Set.Ioo (-π) 0, f x = -1) :
    (∀ n : ℤ, Odd n →
        (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) = 2 / (I * π * n)) ∧
      (∀ n : ℤ, Even n →
        (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) = 0) := by
  have hπ : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  constructor
  · intro n hn
    have hn0 : n ≠ 0 := by rintro rfl; simp at hn
    have hn0' : (n : ℂ) ≠ 0 := by exact_mod_cast hn0
    rw [fs_square_split f hpos hneg, fs_int_exp n hn0, fs_int_exp n hn0]
    have e1 : Complex.exp (-(n * ((π : ℝ) : ℂ) * I)) = -1 := by
      rw [fs_exp_neg, fs_exp_odd n hn]
    have e2 : Complex.exp (-(n * ((-π : ℝ) : ℂ) * I)) = -1 := by
      rw [show -((n : ℂ) * ((-π : ℝ) : ℂ) * I) = n * π * I by push_cast; ring, fs_exp_odd n hn]
    rw [e1, e2]
    simp only [ofReal_zero, mul_zero, zero_mul, neg_zero, Complex.exp_zero]
    field_simp
    ring_nf
  · intro n hn
    rcases eq_or_ne n 0 with rfl | hn0
    · rw [fs_square_split f hpos hneg]
      simp
    · rw [fs_square_split f hpos hneg, fs_int_exp n hn0, fs_int_exp n hn0]
      have e1 : Complex.exp (-(n * ((π : ℝ) : ℂ) * I)) = 1 := by
        rw [fs_exp_neg, fs_exp_even n hn]
      have e2 : Complex.exp (-(n * ((-π : ℝ) : ℂ) * I)) = 1 := by
        rw [show -((n : ℂ) * ((-π : ℝ) : ℂ) * I) = n * π * I by push_cast; ring, fs_exp_even n hn]
      rw [e1, e2]
      simp

-- The tones of a 220 Hz square wave: odd multiples 1, 3 and 5 of 220 give 220, 660 and 1100 Hz.
example : 1 * 220 = 220 ∧ 3 * 220 = 660 ∧ 5 * 220 = 1100 := by norm_num
-- The high half: 1 − (−1)^n is 2 for odd n and 0 for even n (here n = 3 and n = 4).
example : (1 : ℤ) - (-1) ^ 3 = 2 ∧ (1 : ℤ) - (-1) ^ 4 = 0 := by norm_num
-- Three tones at x = π/2: the bracket in (4/π)(1 − 1/3 + 1/5) is 13/15.
example : (1 : ℚ) - 1 / 3 + 1 / 5 = 13 / 15 := by norm_num
-- Parseval for the square wave, first three terms: 1 + 1/9 + 1/25 = 259/225.
example : (1 : ℚ) + 1 / 9 + 1 / 25 = 259 / 225 := by norm_num

#print axioms fourier_series_converges_in_mean_and_parseval
#print axioms fourier_coefficient_eq_average
#print axioms square_wave_fourier_coefficients
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'fs_fourier_coe' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_haar_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_L2_norm_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_exp_odd' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_exp_even' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_exp_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_int_exp' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_int_exp_cycle' depends on axioms: [propext, Classical.choice, Quot.sound]
'fs_square_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_series_converges_in_mean_and_parseval' depends on axioms: [propext, Classical.choice, Quot.sound]
'fourier_coefficient_eq_average' depends on axioms: [propext, Classical.choice, Quot.sound]
'square_wave_fourier_coefficients' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A coarse average.** In `simpson`, change `m=2000` to `m=20`. The averages drift to −0.636622i, −0.212266i, −0.127614i; the first assert stops the run.
> - **More tones near the jump.** Change `(5, 21, 101)` to `(5, 21, 401)` in the Gibbs line. The peak is 1.178982: still above 1.178980; every assert passes.
> - **Forget the tail.** Change `1 / (4 * 10 ** 6)` to `0`. The odd sum falls short of π^2/8 by about 1/(4 × 10^6); the third assert stops the run.

---

## The usual mistake

> [!warning]
> **Expecting more tones to remove the overshoot.** The peak beside the jump is 1.188357 up to tone 5, 1.179669 up to 21, 1.179012 up to 101; the limit is 1.178980, not 1. More tones push the overshoot toward the jump: convergence at every point, not uniform.
>
> - **Wrong constant.** With 1/π in place of 1/(2π) every coefficient doubles: c_1 = −1.273240i.
> - **Wrong sign in the exponent.** Averaging against e^(+inx) returns c_(−n); the rebuilt wave flips to −1.103474 at x = π/2.
> - **Positive n only.** Half of every real tone is lost: 0.5000 where the wave is 1.

---

## Where you meet it in real life

- **Synthesisers.** A square oscillator has only odd harmonics, falling like 1/n. A filter dimming the upper ones softens the buzz; its action on each coefficient is [Convolution](04-convolution-theorem.md).
- **Heat.** Fourier invented the series for heat flow: each tone of a temperature profile fades at its own rate.
- **Digital audio.** A sampled signal has only finitely many tones, found by [The discrete Fourier transform](02-discrete-fourier-transform.md).

> **Say it back**
> A signal repeating every 2π is a sum of arrows e^(inx), each turning n times per cycle. Different arrows average to zero against each other, so the amount of arrow n is the average of the signal times e^(−inx). Partners n and −n make a real cosine and sine. The square wave has only odd tones, c_n = 2/(iπn), and Parseval gives 1 + 1/9 + 1/25 + … = π^2/8. Beside a jump the sums overshoot to about 1.178980, however many tones are kept.

---

## What this builds on

- [Euler's formula](../01-Complex%20Numbers%20and%20the%20Plane/04-eulers-formula.md): e^(ix) is the point at angle x on the unit circle.
- [Limits and regions in the plane](../01-Complex%20Numbers%20and%20the%20Plane/06-complex-limits-series-and-regions.md): when an infinite complex sum converges.
- [Integration by parts](../../06-Calculus%20and%20analysis/04-Integrals/04-integration-by-parts.md): ties smoothness to how fast coefficients fall.

## Where this goes next

- [The discrete Fourier transform](02-discrete-fourier-transform.md): the same coefficients from finitely many samples.
- [The Fourier transform](03-fourier-transform.md): a signal that never repeats; the tones fill a continuum.
- Completeness of sines and cosines: why the arrows are enough; Parseval in full.
- Wiener's lemma: when a filter's action on the coefficients can be undone.
- Fourier coefficients: the three kinds of convergence, proved.
- Poisson summation and sampling: series and transform tied together.
- Equidistribution: arrow averages deciding whether a sequence spreads evenly.
- Isoperimetric and four-vertex: Parseval proving the circle encloses the most area.

A repeating signal has a list of tones; a camera shutter's one-second pulse never repeats, and what replaces the list is [The Fourier transform](03-fourier-transform.md).

---

## Sources

Verified 28 Sep 2026: every link below resolves to the publisher's page.

- Stein, Elias M., and Rami Shakarchi. *Fourier Analysis: An Introduction*. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113845/fourier-analysis). Coefficients, convergence and Parseval, with proofs.
- Mattuck, Arthur, Haynes Miller, Jeremy Orloff, and John Lewis. "Fourier Series: Basics." 18.03SC Differential Equations, MIT OpenCourseWare, Fall 2011. [Course page](https://ocw.mit.edu/courses/18-03sc-differential-equations-fall-2011/pages/unit-iii-fourier-series-and-laplace-transform/fourier-series-basics/). Free notes on orthogonality and computing coefficients.
- O'Connor, J. J., and E. F. Robertson. "Joseph Fourier." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Fourier/). Fourier's heat problem and his series.
