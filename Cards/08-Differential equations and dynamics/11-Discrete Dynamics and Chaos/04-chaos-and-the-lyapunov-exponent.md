# The Lyapunov exponent: how fast two nearly identical starts drift apart, and positive means chaos

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Discrete Dynamics and Chaos](../README.md#s11) → The Lyapunov exponent

---

## General Overview

A forest's moths are counted once a year, as a fraction of the most the forest can carry. Next year's fraction is 3.9 times this year's, times the room left: the logistic map of [The logistic map](03-the-logistic-map-and-period-doubling.md). The rule has no chance in it. Two forecasts start from 0.2, one off by 1e-10, a ten-billionth.

The error grows by a roughly steady factor each year until the two forecasts differ by 0.5, half the whole range. From 0.2 that takes 40 years; across 1,000 starting fractions, a median of 45. The rule is exact; the uncertainty about the start is what grows. That is **sensitive dependence on initial conditions**.

The **Lyapunov exponent**, after Aleksandr Lyapunov, is that growth rate per step, on a logarithmic scale (ln, the natural logarithm, to base e). Negative: nearby starts close up. Positive: they drift apart exponentially, and the map is **chaotic** in the working sense used here. At growth factor 3.9 it is 0.4965 per step. At 4 it is exactly ln 2 = 0.6931: on average each step doubles the error, using up one binary digit of the start.

**The Lyapunov exponent is the long-run average of the logarithm of one step's stretch of a tiny gap; the gap grows like e to the exponent times the steps, so a positive exponent means chaos and fixes how far ahead a forecast can see.**

**What kind of fact this is:** a definition; its exact value ln 2 at growth factor 4 is a theorem, proved on this card in Why it works.

### The picture: an error of 1e-10 at growth factor 3.9

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Two starts 1e-10 apart, from 0.2, growth factor 3.9"
    x-axis "step (years)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    y-axis "log10 of the gap" -10 --> 3
    line [-10.00, -8.55, -8.24, -6.80, -5.42, -4.10, -2.88, -1.36, -0.29, -0.43, -1.03, -0.13, -0.13]
    line [-10.00, -8.92, -7.84, -6.77, -5.69, -4.61, -3.53, -2.45, -1.38, -0.30, 0.78, 1.86, 2.94]
```

Orange: the base-10 logarithm of the true gap; each unit up is a tenfold larger error. Green: the line the exponent predicts, rising 0.4965 / ln 10 per step. The true gap climbs at about that slope, a little ahead, until step 40; then it fills the range and wanders.

---

## The formula

Reminder: a map $x_{n+1} = f(x_n)$ turns this year's state into next year's; the list $x_0, x_1, x_2, \dots$ is the orbit. Here $f(x) = r x (1 - x)$, and the size of its derivative, $\lvert f'(x) \rvert = \lvert r(1 - 2x) \rvert$, is one step's stretch at $x$; the bars drop the sign. The capital sigma, Σ, adds the terms after it, for $k$ from 0 to $n - 1$.

$$\lambda = \lim_{n \to \infty} \frac{1}{n} \sum_{k=0}^{n-1} \ln \lvert f'(x_k) \rvert$$

**Read it aloud:** follow the orbit, take the logarithm of each step's stretch, and average over the long run.

The error law and the forecast horizon follow:

$$\delta_n \approx \delta_0 \, e^{\lambda n}, \qquad n_* = \frac{\ln(\Delta / \delta_0)}{\lambda}$$

**Read it aloud:** a small error grows by a factor e to the lambda per step, so it reaches the tolerance after ln of tolerance over error, divided by lambda, steps.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x_n$, $x_0$, $x_k$ | the state after $n$ steps; the start; at step $k$ | start 0.2 | — |
| $r$ | the growth factor in the map | 3.9, and 4 | larger exponent, not steadily |
| $f$, $f'$ | the map; one step's stretch | 2.34 at 0.2 | — |
| $\lambda$ | the Lyapunov exponent, per step | 0.4965 at 3.9; 0.6931 at 4 | horizon shrinks |
| $\delta_0$, $\delta_n$ | the gap at the start; after $n$ steps | 1e-10 | horizon shrinks, logarithmically |
| $n$, $k$ | step counts | years | — |
| $\Delta$, $n_*$ | the tolerance; the horizon in steps | 0.5; 44.98 | horizon grows |
| $\theta$, $\theta_0$, $\theta_k$ | an angle with $x = \sin^2\theta$ | $\sin^2\theta_0 = 0.2$ | — |

### When it holds

- **A typical start.** Exceptional starts differ: at growth factor 4 the start 0 is an unstable fixed point (a state the map sends to itself) giving ln 4 = 1.3863, and 0.5 lands on 0.
- **A small gap.** The law $\delta_0 e^{\lambda n}$ holds while the gap is far smaller than the range; near 0.5 it stops growing.
- **A typical horizon, not a guarantee.** Over 1,000 starts the gap reached 0.5 between steps 34 and 72, median 45, against the predicted 44.98.
- **Negative means settled.** At growth factor 2.8 the orbit settles on a fixed point where the stretch is 0.8, and the exponent is ln 0.8 = −0.2231: every error shrinks to 0.8 of itself per step.

---

## Why it works

### Step 1: stretches multiply, so their logarithms add

Start orbits at $x_0$ and $x_0 + \delta_0$. By the chain rule the derivative of $n$ steps is the product of one-step derivatives along the orbit. The capital pi, ∏, multiplies terms as Σ adds them, so

$$\delta_n \approx \delta_0 \prod_{k=0}^{n-1} \lvert f'(x_k) \rvert = \delta_0 \, e^{\sum \ln \lvert f'(x_k) \rvert} \approx \delta_0 \, e^{\lambda n}.$$

The logarithm of a product is a sum; the last step replaces that sum by $n$ times its average. Solving $\delta_0 e^{\lambda n} = \Delta$ gives the horizon: 22.33 / 0.4965 = 44.98 steps.

### Step 2: the logarithm is what makes the horizon cheap to extend

The horizon depends on $\ln(\Delta / \delta_0)$. A survey a thousand times sharper, 1e-13 instead of 1e-10, buys ln(1000) / 0.4965 = 13.91 more years; across 1,000 starts it bought 13.97. Each tenfold gain in precision buys the same fixed number of steps.

### Step 3: at growth factor 4, the sine-squared substitution doubles an angle

Write the state as $x = \sin^2\theta$ ([Trig identities](../../05-Geometry%20and%20trig/03-Trigonometry/03-trig-identities.md)). Then $1 - x = \cos^2\theta$ and

$$f(x) = 4\sin^2\theta\cos^2\theta = (2\sin\theta\cos\theta)^2 = \sin^2(2\theta).$$

Each step doubles the angle: $\theta_k = 2^k \theta_0$. From 0.2, twenty steps give 0.82001387, as does $\sin^2(2^{20}\theta_0)$.

### Step 4: the stretches telescope to 2^n

By the cosine double-angle formula, $f'(x_k) = 4(1 - 2\sin^2\theta_k) = 4\cos 2\theta_k$. The sine one, $\sin 4\theta = 2\sin 2\theta \cos 2\theta$, rewrites it as

$$\lvert f'(x_k) \rvert = 2\,\frac{\lvert \sin 2\theta_{k+1} \rvert}{\lvert \sin 2\theta_k \rvert}.$$

Multiplied over $n$ steps, every inner sine cancels:

$$\prod_{k=0}^{n-1} \lvert f'(x_k) \rvert = 2^n \, \frac{\lvert \sin 2\theta_n \rvert}{\lvert \sin 2\theta_0 \rvert}.$$

Over 20 steps from 0.2 both sides are 1007094.07. Take logarithms and divide by $n$:

$$\frac{1}{n}\sum_{k=0}^{n-1} \ln \lvert f'(x_k) \rvert = \ln 2 + \frac{1}{n} \ln \frac{\lvert \sin 2\theta_n \rvert}{\lvert \sin 2\theta_0 \rvert}.$$

For a typical start the last term shrinks to zero, so $\lambda = \ln 2$: one bit lost per step.

<details>
<summary>Detailed proof: the correction term vanishes</summary>

From above: $\lvert \sin 2\theta_n \rvert \le 1$, so the correction is at most $\frac{1}{n}\ln(1/\lvert \sin 2\theta_0 \rvert)$, which tends to 0 when $x_0$ is neither 0 nor 1.

From below: $\theta_n / \pi$ doubles each step, and only its fractional part matters. $\sin 2\theta_n$ is tiny only when that part is near 0, 1/2 or 1. Doubling shifts the binary digits of $\theta_0 / \pi$ one place left, so that part comes within a tiny distance of those points only when the digits from place $n + 2$ begin with a long run of equal digits; the closer, the longer the run. Given $\varepsilon > 0$, the correction falls below $-\varepsilon$ at step $n$ only if $\lvert \sin 2\theta_n \rvert < e^{-\varepsilon n}$, which needs a run of length proportional to $n$. A start whose digits never carry runs growing in proportion to their position has correction tending to 0 from below too, so $\lambda = \ln 2$. Starts whose digits end in all zeros, such as 0.5 (angle $\pi/4$, digits 0.01), land on 0: the exceptions.

</details>

A second road never uses the derivative: carry a twin orbit a fixed tiny distance away, record the log of each step's stretch of that distance, and pull the twin back. The code takes it; it agrees to four decimals. Angle doubling read as a shift of binary digits is [The doubling map](05-the-doubling-map-and-symbolic-dynamics.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| exponent at 3.9 | orbit average of ln of the stretch | 0.4965 per step |
| same, in bits | 0.4965 / ln 2 | 0.716 bits per step |
| distance to cover | ln(0.5 / 1e-10) = ln(5e9) | 22.33 |
| horizon | 22.33 / 0.4965 | **44.98 steps** |
| test on 1,000 starts | median step the gap hits 0.5 | 45 |
| start 1,000 times sharper | 6.91 / 0.4965 | 13.91 more; measured 13.97 |
| exponent at 4 | ln 2, from Step 4 | **0.6931, 1.000 bit per step** |

A forecast from a survey good to 1e-10 is worthless after about 45 years; a survey a thousand times sharper adds 13.91.

### The picture: the exponent across growth factors

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Lyapunov exponent of the logistic map, from 0.2"
    x-axis "growth factor r" [2.8, 2.9, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 4.0]
    y-axis "exponent (per step)" -1 --> 1
    line [-0.22, -0.11, -0.00, -0.26, -0.92, -0.62, -0.14, -0.87, 0.18, 0.35, 0.43, 0.50, 0.69]
```

Orange: the orbit-average exponent. Below zero the orbit settles: −0.2231 on the fixed point at 2.8, −0.9163 on the two-cycle (an orbit that repeats every two steps) at 3.2, −0.8725 on the four-cycle at 3.5. It touches zero at 3.0, where the fixed point loses stability, and turns positive between 3.5 and 3.6, past the period-doubling cascade.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Average the stretch, then take ln | ln 2.5455 = 0.9343 at 4 | the log of an average exceeds the average of logs |
| Read the exponent off one step | ln 2.34 = 0.8502, horizon 26.27 | one stretch is local |
| Start on the fixed point 0 at 4 | 1.3863 = ln 4 | an exceptional orbit |
| Trust one pair of starts | 40 steps from 0.2 | horizons scatter, 34 to 72 |

The code prints all four.

---

## Code, from first principles, and it actually runs

Two roads to the exponent share only the map: the average of ln of the stretch along one orbit, and a twin orbit with no derivative. At growth factor 4 the scripts check the telescope over 20 steps, finding the angle by bisection. At 3.9 they test the horizon on 1,000 pairs of starts, and print every charted point and wrong answer.

### Python

```python
# The Lyapunov exponent of the logistic map x -> r x (1 - x): the check behind the card.
# Standard library only; math.log and math.sin are the only borrowed functions.
import math
f = lambda r, x: r * x * (1 - x)
fmt = lambda v: ", ".join(f"{u:.2f}" for u in v)

def lam(r, x=0.2, d0=1e-9, n=200000):     # road 1: mean of ln|f'| on one orbit
    for _ in range(1000):                  # road 2: a twin orbit d0 away, no derivative
        x = f(r, x)
    y, s1, s2, s3 = x + d0, 0.0, 0.0, 0.0
    for _ in range(n):
        s1, s3 = s1 + math.log(abs(r * (1 - 2 * x))), s3 + abs(r * (1 - 2 * x))
        x, y = f(r, x), f(r, y)
        s2 += math.log(abs(y - x) / d0)
        y = x + (d0 if y > x else -d0)      # pull the twin back to distance d0
    return s1 / n, s2 / n, s3 / n

def cross(r, x, d):                        # steps until two starts d apart differ by 0.5
    y, n = x + d, 0
    while abs(x - y) < 0.5 and n < 1000:
        x, y, n = f(r, x), f(r, y), n + 1
    return n

(l4, t4, mean4), (l39, t39, _) = lam(4.0), lam(3.9)
lo, hi = 0.0, math.pi / 2                  # bisection for theta with sin^2(theta) = 0.2
for _ in range(100):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if math.sin(mid) ** 2 < 0.2 else (lo, mid)
x, prod = 0.2, 1.0
for _ in range(20):
    prod, x = prod * abs(4 * (1 - 2 * x)), f(4.0, x)
x20, sin20 = x, math.sin(2 ** 20 * lo) ** 2
tele = 2 ** 20 * abs(math.sin(2 ** 21 * lo) / math.sin(2 * lo))
hor, gain = math.log(0.5 / 1e-10) / l39, math.log(1000) / l39
c10 = sorted(cross(3.9, (k + 0.5) / 1000, 1e-10) for k in range(1000))
m10, m13 = sum(c10) / 1000, sum(cross(3.9, (k + 0.5) / 1000, 1e-13) for k in range(1000)) / 1000
x, y, gap = 0.2, 0.2 + 1e-10, []
for n in range(61):
    gap += [math.log(abs(x - y)) / math.log(10)] if n % 5 == 0 else []
    x, y = f(3.9, x), f(3.9, y)
lr = [lam(2.8 + k / 10)[0] for k in range(13)]
print(f"r = 4.0: road 1, average of ln|f'| = {l4:.4f}; road 2, twin orbits = {t4:.4f}; ln 2 = {math.log(2):.4f}")
print(f"r = 3.9: road 1, average of ln|f'| = {l39:.4f}; road 2, twin orbits = {t39:.4f}; bits per step {l39 / math.log(2):.3f}")
print(f"r = 4.0, from 0.2: x20 by the map = {x20:.8f}; sin^2(2^20 theta) = {sin20:.8f}")
print(f"product of |f'| over 20 steps = {prod:.2f}; 2^20 |sin 2theta20 / sin 2theta0| = {tele:.2f}")
print(f"horizon at r = 3.9, gap 1e-10 to 0.5: ln(5e9) = {math.log(5e9):.2f}, / lambda = {hor:.2f} steps")
print(f"1000 starts, first step the gap reaches 0.5: median {(c10[499] + c10[500]) / 2:.0f}, mean {m10:.2f}, fewest {c10[0]}, most {c10[-1]}; from 0.2 alone {cross(3.9, 0.2, 1e-10)}")
print(f"gap 1e-13 instead: mean {m13:.2f}, {m13 - m10:.2f} steps gained; ln(1000) = {math.log(1000):.2f}, / lambda = {gain:.2f}")
print(f"settled: r = 2.8 gives {lr[0]:.4f}, ln 0.8 = {math.log(0.8):.4f}; r = 3.2 gives {lr[4]:.4f}, ln(0.16) / 2 = {math.log(0.16) / 2:.4f}; r = 3.5 gives {lr[7]:.4f}")
print(f"figure, lambda at r = 2.8, 2.9, ..., 4.0: {fmt(lr)}")
print(f"figure, log10 of the gap from 0.2 at steps 0, 5, ..., 60: {fmt(gap)}")
print(f"figure, prediction -10 + lambda n / ln 10: {fmt([-10 + l39 * 5 * k / math.log(10) for k in range(13)])}")
print(f"mistake 1, ln of the average |f'| at r = 4: ln {mean4:.4f} = {math.log(mean4):.4f}")
print(f"mistake 2, one step from 0.2 at r = 3.9: ln 2.34 = {math.log(2.34):.4f}, horizon {math.log(5e9) / math.log(2.34):.2f} steps")
print(f"mistake 3, start on the fixed point 0 at r = 4: {lam(4.0, 0.0)[0]:.4f} = ln 4")
assert abs(l39 - t39) < 0.01 and abs(l4 - t4) < 0.01         # two roads to lambda agree
assert abs(l4 - math.log(2)) < 0.005 and abs(lr[0] - math.log(0.8)) < 1e-6
assert abs(prod / tele - 1) < 1e-6 and abs(x20 - sin20) < 1e-6  # the sine-squared telescope
assert abs((c10[499] + c10[500]) / 2 - hor) < 1 and abs(m13 - m10 - gain) < 1
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
r = 4.0: road 1, average of ln|f'| = 0.6931; road 2, twin orbits = 0.6931; ln 2 = 0.6931
r = 3.9: road 1, average of ln|f'| = 0.4965; road 2, twin orbits = 0.4965; bits per step 0.716
r = 4.0, from 0.2: x20 by the map = 0.82001387; sin^2(2^20 theta) = 0.82001387
product of |f'| over 20 steps = 1007094.07; 2^20 |sin 2theta20 / sin 2theta0| = 1007094.07
horizon at r = 3.9, gap 1e-10 to 0.5: ln(5e9) = 22.33, / lambda = 44.98 steps
1000 starts, first step the gap reaches 0.5: median 45, mean 46.22, fewest 34, most 72; from 0.2 alone 40
gap 1e-13 instead: mean 60.19, 13.97 steps gained; ln(1000) = 6.91, / lambda = 13.91
settled: r = 2.8 gives -0.2231, ln 0.8 = -0.2231; r = 3.2 gives -0.9163, ln(0.16) / 2 = -0.9163; r = 3.5 gives -0.8725
figure, lambda at r = 2.8, 2.9, ..., 4.0: -0.22, -0.11, -0.00, -0.26, -0.92, -0.62, -0.14, -0.87, 0.18, 0.35, 0.43, 0.50, 0.69
figure, log10 of the gap from 0.2 at steps 0, 5, ..., 60: -10.00, -8.55, -8.24, -6.80, -5.42, -4.10, -2.88, -1.36, -0.29, -0.43, -1.03, -0.13, -0.13
figure, prediction -10 + lambda n / ln 10: -10.00, -8.92, -7.84, -6.77, -5.69, -4.61, -3.53, -2.45, -1.38, -0.30, 0.78, 1.86, 2.94
mistake 1, ln of the average |f'| at r = 4: ln 2.5455 = 0.9343
mistake 2, one step from 0.2 at r = 3.9: ln 2.34 = 0.8502, horizon 26.27 steps
mistake 3, start on the fixed point 0 at r = 4: 1.3863 = ln 4
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// The Lyapunov exponent of the logistic map x -> r x (1 - x): the same check in Rust.
// No crates; ln and sin from std are the only borrowed functions.
fn f(r: f64, x: f64) -> f64 { r * x * (1.0 - x) }

fn fmt(v: &[f64]) -> String { v.iter().map(|u| format!("{:.2}", u)).collect::<Vec<_>>().join(", ") }

fn lam(r: f64, mut x: f64) -> (f64, f64, f64) {  // road 1: mean of ln|f'| on one orbit
    let (d0, n) = (1e-9, 200000);                 // road 2: a twin orbit d0 away, no derivative
    for _ in 0..1000 { x = f(r, x) }
    let (mut y, mut s1, mut s2, mut s3) = (x + d0, 0.0, 0.0, 0.0);
    for _ in 0..n {
        s1 += (r * (1.0 - 2.0 * x)).abs().ln();
        s3 += (r * (1.0 - 2.0 * x)).abs();
        x = f(r, x);
        y = f(r, y);
        s2 += ((y - x).abs() / d0).ln();
        y = x + if y > x { d0 } else { -d0 };     // pull the twin back to distance d0
    }
    (s1 / n as f64, s2 / n as f64, s3 / n as f64)
}

fn cross(r: f64, mut x: f64, d: f64) -> i32 {     // steps until two starts d apart differ by 0.5
    let (mut y, mut n) = (x + d, 0);
    while (x - y).abs() < 0.5 && n < 1000 { x = f(r, x); y = f(r, y); n += 1 }
    n
}

fn main() {
    let ((l4, t4, mean4), (l39, t39, _)) = (lam(4.0, 0.2), lam(3.9, 0.2));
    let (mut lo, mut hi) = (0.0_f64, std::f64::consts::PI / 2.0);  // bisection: sin^2(theta) = 0.2
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if mid.sin().powi(2) < 0.2 { lo = mid } else { hi = mid }
    }
    let (mut x, mut prod) = (0.2_f64, 1.0_f64);
    for _ in 0..20 { prod *= (4.0 * (1.0 - 2.0 * x)).abs(); x = f(4.0, x) }
    let (x20, sin20) = (x, (1048576.0 * lo).sin().powi(2));
    let tele = 1048576.0 * ((2097152.0 * lo).sin() / (2.0 * lo).sin()).abs();
    let (hor, gain) = ((0.5_f64 / 1e-10).ln() / l39, 1000.0_f64.ln() / l39);
    let mut c10: Vec<i32> = (0..1000).map(|k| cross(3.9, (k as f64 + 0.5) / 1000.0, 1e-10)).collect();
    c10.sort();
    let m10 = c10.iter().sum::<i32>() as f64 / 1000.0;
    let m13 = (0..1000).map(|k| cross(3.9, (k as f64 + 0.5) / 1000.0, 1e-13)).sum::<i32>() as f64 / 1000.0;
    let med = (c10[499] + c10[500]) as f64 / 2.0;
    let (mut x, mut y, mut gap) = (0.2_f64, 0.2_f64 + 1e-10, Vec::new());
    for n in 0..61 {
        if n % 5 == 0 { gap.push((x - y).abs().ln() / 10.0_f64.ln()) }
        x = f(3.9, x);
        y = f(3.9, y);
    }
    let lr: Vec<f64> = (0..13).map(|k| lam(2.8 + k as f64 / 10.0, 0.2).0).collect();
    let pred: Vec<f64> = (0..13).map(|k| -10.0 + l39 * 5.0 * k as f64 / 10.0_f64.ln()).collect();
    let (ln2, ln08, half016) = (2.0_f64.ln(), 0.8_f64.ln(), 0.16_f64.ln() / 2.0);
    println!("r = 4.0: road 1, average of ln|f'| = {:.4}; road 2, twin orbits = {:.4}; ln 2 = {:.4}", l4, t4, ln2);
    println!("r = 3.9: road 1, average of ln|f'| = {:.4}; road 2, twin orbits = {:.4}; bits per step {:.3}", l39, t39, l39 / ln2);
    println!("r = 4.0, from 0.2: x20 by the map = {:.8}; sin^2(2^20 theta) = {:.8}", x20, sin20);
    println!("product of |f'| over 20 steps = {:.2}; 2^20 |sin 2theta20 / sin 2theta0| = {:.2}", prod, tele);
    println!("horizon at r = 3.9, gap 1e-10 to 0.5: ln(5e9) = {:.2}, / lambda = {:.2} steps", 5e9_f64.ln(), hor);
    println!("1000 starts, first step the gap reaches 0.5: median {:.0}, mean {:.2}, fewest {}, most {}; from 0.2 alone {}",
             med, m10, c10[0], c10[999], cross(3.9, 0.2, 1e-10));
    println!("gap 1e-13 instead: mean {:.2}, {:.2} steps gained; ln(1000) = {:.2}, / lambda = {:.2}", m13, m13 - m10, 1000.0_f64.ln(), gain);
    println!("settled: r = 2.8 gives {:.4}, ln 0.8 = {:.4}; r = 3.2 gives {:.4}, ln(0.16) / 2 = {:.4}; r = 3.5 gives {:.4}",
             lr[0], ln08, lr[4], half016, lr[7]);
    println!("figure, lambda at r = 2.8, 2.9, ..., 4.0: {}", fmt(&lr));
    println!("figure, log10 of the gap from 0.2 at steps 0, 5, ..., 60: {}", fmt(&gap));
    println!("figure, prediction -10 + lambda n / ln 10: {}", fmt(&pred));
    println!("mistake 1, ln of the average |f'| at r = 4: ln {:.4} = {:.4}", mean4, mean4.ln());
    println!("mistake 2, one step from 0.2 at r = 3.9: ln 2.34 = {:.4}, horizon {:.2} steps", 2.34_f64.ln(), 5e9_f64.ln() / 2.34_f64.ln());
    println!("mistake 3, start on the fixed point 0 at r = 4: {:.4} = ln 4", lam(4.0, 0.0).0);
    assert!((l39 - t39).abs() < 0.01 && (l4 - t4).abs() < 0.01);          // two roads to lambda agree
    assert!((l4 - ln2).abs() < 0.005 && (lr[0] - ln08).abs() < 1e-6);
    assert!((prod / tele - 1.0).abs() < 1e-6 && (x20 - sin20).abs() < 1e-6); // the sine-squared telescope
    assert!((med - hor).abs() < 1.0 && (m13 - m10 - gain).abs() < 1.0);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
r = 4.0: road 1, average of ln|f'| = 0.6931; road 2, twin orbits = 0.6931; ln 2 = 0.6931
r = 3.9: road 1, average of ln|f'| = 0.4965; road 2, twin orbits = 0.4965; bits per step 0.716
r = 4.0, from 0.2: x20 by the map = 0.82001387; sin^2(2^20 theta) = 0.82001387
product of |f'| over 20 steps = 1007094.07; 2^20 |sin 2theta20 / sin 2theta0| = 1007094.07
horizon at r = 3.9, gap 1e-10 to 0.5: ln(5e9) = 22.33, / lambda = 44.98 steps
1000 starts, first step the gap reaches 0.5: median 45, mean 46.22, fewest 34, most 72; from 0.2 alone 40
gap 1e-13 instead: mean 60.19, 13.97 steps gained; ln(1000) = 6.91, / lambda = 13.91
settled: r = 2.8 gives -0.2231, ln 0.8 = -0.2231; r = 3.2 gives -0.9163, ln(0.16) / 2 = -0.9163; r = 3.5 gives -0.8725
figure, lambda at r = 2.8, 2.9, ..., 4.0: -0.22, -0.11, -0.00, -0.26, -0.92, -0.62, -0.14, -0.87, 0.18, 0.35, 0.43, 0.50, 0.69
figure, log10 of the gap from 0.2 at steps 0, 5, ..., 60: -10.00, -8.55, -8.24, -6.80, -5.42, -4.10, -2.88, -1.36, -0.29, -0.43, -1.03, -0.13, -0.13
figure, prediction -10 + lambda n / ln 10: -10.00, -8.92, -7.84, -6.77, -5.69, -4.61, -3.53, -2.45, -1.38, -0.30, 0.78, 1.86, 2.94
mistake 1, ln of the average |f'| at r = 4: ln 2.5455 = 0.9343
mistake 2, one step from 0.2 at r = 3.9: ln 2.34 = 0.8502, horizon 26.27 steps
mistake 3, start on the fixed point 0 at r = 4: 1.3863 = ln 4
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the exact exponent at growth factors 4 and 2.8, and the telescope of the stretches for every angle.

- Take growth factor 4 and a typical start between 0 and 1. Then the average of ln of the stretch over the first $n$ steps tends to ln 2 as $n$ grows. The starts that fail, such as 0 and 0.5, have total length zero.
- Take growth factor 4 and a start $x_0 = \sin^2\theta_0$. Then $\lvert \sin 2\theta_0 \rvert$ times the product of the first $n$ stretches equals $2^n \lvert \sin 2\theta_n \rvert$. Written without division, it holds for every angle, even where $\sin 2\theta_0$ is 0.
- Take growth factor 2.8 and the start 0.2. Then the average of ln of the stretch tends to ln 0.8, which is negative: the orbit settles.
- At growth factor 2.8 the fixed point is 9/14, and the stretch there is 0.8.
- At growth factor 4 the start 0 is a fixed point with stretch 4, and 0.5 lands on 0 in two steps.
- At growth factor 3.9 the stretch at 0.2 is 2.34.

Python and Rust check the rest: the decimals at 3.9, the horizons, the survey of 1,000 starts, the twin orbits and the charts.

```lean
-- The Lyapunov exponent: at growth factor 4 the logistic map's exponent is exactly ln 2 for almost every start in [0, 1], because the one-step stretches telescope to 2^n, while at growth factor 2.8 the orbit from 0.2 settles and its exponent is ln 0.8.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.MeasureTheory.OuterMeasure.BorelCantelli
import Mathlib.Analysis.Asymptotics.SpecificAsymptotics
import Mathlib.Analysis.SpecificLimits.Basic

open Real Filter Topology MeasureTheory

/-- The logistic map `x ↦ r x (1 - x)`. -/
def logistic (r x : ℝ) : ℝ := r * x * (1 - x)

/-- The orbit average of the logarithm of one step's stretch `|f'(x_k)| = |r (1 - 2 x_k)|`
over the first `n` steps from the start `x₀`: `(1/n) Σ_{k<n} ln |f'(x_k)|`.
The Lyapunov exponent is its limit as `n → ∞`. -/
noncomputable def lyapunovAvg (r x₀ : ℝ) (n : ℕ) : ℝ :=
  (1 / (n : ℝ)) * ∑ k ∈ Finset.range n, Real.log |r * (1 - 2 * (logistic r)^[k] x₀)|

theorem logistic_four_iterate_sin_sq (θ : ℝ) (k : ℕ) :
    (logistic 4)^[k] (Real.sin θ ^ 2) = Real.sin (2 ^ k * θ) ^ 2 := by
  induction k with
  | zero => simp
  | succ k ih =>
    have e : (2 : ℝ) ^ (k + 1) * θ = 2 * (2 ^ k * θ) := by rw [pow_succ]; ring
    rw [Function.iterate_succ_apply', ih, logistic, e, Real.sin_two_mul]
    have := Real.sin_sq_add_cos_sq (2 ^ k * θ)
    nlinarith [this]

#print axioms logistic_four_iterate_sin_sq

theorem logistic_four_iterate_mem (x : ℝ) (hx : x ∈ Set.Icc (0 : ℝ) 1) (m : ℕ) :
    (logistic 4)^[m] x ∈ Set.Icc (0 : ℝ) 1 := by
  induction m with
  | zero => simpa using hx
  | succ m ih =>
    rw [Function.iterate_succ_apply']
    generalize (logistic 4)^[m] x = y at ih ⊢
    obtain ⟨h0, h1⟩ := ih
    constructor
    · unfold logistic; nlinarith
    · unfold logistic; nlinarith [sq_nonneg (2 * y - 1)]

#print axioms logistic_four_iterate_mem

theorem logistic_four_near_root (x : ℝ) (hx : x ∈ Set.Icc (0 : ℝ) 1) (n : ℕ) (η : ℝ)
    (hη : 0 < η) (h : (logistic 4)^[n] x < η ^ 2) :
    ∃ k ∈ Finset.range (2 ^ n + 1),
      x ∈ Set.Icc (Real.sin (k * π / 2 ^ n) ^ 2 - π * η / 2 ^ n)
        (Real.sin (k * π / 2 ^ n) ^ 2 + π * η / 2 ^ n) := by
  obtain ⟨hx0, hx1⟩ := hx
  set θ := Real.arcsin (Real.sqrt x) with hθ
  have hs : Real.sin θ = Real.sqrt x :=
    Real.sin_arcsin (by linarith [Real.sqrt_nonneg x]) (Real.sqrt_le_one.mpr hx1)
  have hθx : Real.sin θ ^ 2 = x := by rw [hs, Real.sq_sqrt hx0]
  have hθ0 : 0 ≤ θ := Real.arcsin_nonneg.mpr (Real.sqrt_nonneg x)
  have hθ1 : θ ≤ π / 2 := Real.arcsin_le_pi_div_two _
  rw [← hθx, logistic_four_iterate_sin_sq] at h
  set y := 2 ^ n * θ with hy
  have hP : (0 : ℝ) < 2 ^ n := by positivity
  have hy0 : 0 ≤ y := by positivity
  have hyle : y ≤ 2 ^ n * π / 2 := by rw [hy]; nlinarith
  set k := ⌊y / π + 1 / 2⌋₊ with hk
  have hk1 : (k : ℝ) ≤ y / π + 1 / 2 := Nat.floor_le (by positivity)
  have hk2 : y / π + 1 / 2 < k + 1 := Nat.lt_floor_add_one _
  have hk1' : (k : ℝ) * π ≤ y + π / 2 := by
    have := mul_le_mul_of_nonneg_right hk1 pi_pos.le
    rw [add_mul, div_mul_cancel₀ _ pi_ne_zero] at this; linarith
  have hk2' : y + π / 2 < (k : ℝ) * π + π := by
    have := mul_lt_mul_of_pos_right hk2 pi_pos
    rw [add_mul, add_mul, div_mul_cancel₀ _ pi_ne_zero] at this; linarith
  set z := y - k * π with hz
  have hsz : |Real.sin y| = |Real.sin z| := by
    have : y = z + k * π := by rw [hz]; ring
    rw [this, Real.sin_add_nat_mul_pi, abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul]
  have hlow : 2 / π * |z| ≤ |Real.sin z| := by
    rcases le_total 0 z with hz0 | hz0
    · rw [abs_of_nonneg hz0]
      exact (Real.mul_le_sin hz0 (by linarith)).trans (le_abs_self _)
    · rw [abs_of_nonpos hz0]
      have := Real.mul_le_sin (neg_nonneg.mpr hz0) (by linarith)
      rw [Real.sin_neg] at this
      exact this.trans (neg_le_abs _)
  have hsy : |Real.sin y| < η := abs_lt_of_sq_lt_sq h hη.le
  have hzlt : 2 * |z| < π * η := by
    have h3 : 2 / π * |z| < η := by linarith
    rw [div_mul_eq_mul_div, div_lt_iff₀ pi_pos] at h3; linarith
  have hkle : k ≤ 2 ^ n := by
    have : (k : ℝ) < 2 ^ n + 1 := by
      have : (k : ℝ) * π < 2 ^ n * π + π := by nlinarith
      nlinarith [pi_pos]
    exact_mod_cast Nat.lt_succ_iff.mp (by exact_mod_cast this)
  refine ⟨k, Finset.mem_range.mpr (Nat.lt_succ_of_le hkle), ?_⟩
  set b := (k : ℝ) * π / 2 ^ n with hb
  have hθb : θ - b = z / 2 ^ n := by rw [hz, hy, hb]; field_simp
  have hdiff : |Real.sin θ ^ 2 - Real.sin b ^ 2| ≤ π * η / 2 ^ n := by
    have e : Real.sin θ ^ 2 - Real.sin b ^ 2 =
        (Real.sin θ - Real.sin b) * (Real.sin θ + Real.sin b) := by ring
    have hsum : |Real.sin θ + Real.sin b| ≤ 2 := by
      have := abs_add_le (Real.sin θ) (Real.sin b)
      linarith [Real.abs_sin_le_one θ, Real.abs_sin_le_one b]
    have h1 := Real.abs_sin_sub_sin_le θ b
    rw [hθb, abs_div, abs_of_pos hP] at h1
    rw [e, abs_mul]
    calc |Real.sin θ - Real.sin b| * |Real.sin θ + Real.sin b|
        ≤ |z| / 2 ^ n * 2 := mul_le_mul h1 hsum (abs_nonneg _) (by positivity)
      _ = 2 * |z| / 2 ^ n := by ring
      _ ≤ π * η / 2 ^ n := by gcongr
  rw [abs_le] at hdiff
  constructor <;> linarith [hdiff.1, hdiff.2]

#print axioms logistic_four_near_root

theorem logistic_four_small_measure (n : ℕ) (η : ℝ) (hη : 0 < η) :
    volume ({x | (logistic 4)^[n] x < η ^ 2} ∩ Set.Icc (0 : ℝ) 1) ≤
      ENNReal.ofReal (4 * π * η) := by
  set a := π * η / 2 ^ n with ha
  set c : ℕ → ℝ := fun k => Real.sin (k * π / 2 ^ n) ^ 2 with hc
  have hsub : {x | (logistic 4)^[n] x < η ^ 2} ∩ Set.Icc (0 : ℝ) 1 ⊆
      ⋃ k ∈ Finset.range (2 ^ n + 1), Set.Icc (c k - a) (c k + a) := by
    intro x ⟨hx1, hx2⟩
    obtain ⟨k, hk, hmem⟩ := logistic_four_near_root x hx2 n η hη hx1
    exact Set.mem_biUnion hk hmem
  have hvol : ∀ k, volume (Set.Icc (c k - a) (c k + a)) = ENNReal.ofReal (2 * a) := by
    intro k; rw [Real.volume_Icc]; ring_nf
  have hP : (1 : ℝ) ≤ 2 ^ n := one_le_pow₀ (by norm_num)
  have ha0 : 0 ≤ a := by positivity
  calc volume ({x | (logistic 4)^[n] x < η ^ 2} ∩ Set.Icc (0 : ℝ) 1)
      ≤ volume (⋃ k ∈ Finset.range (2 ^ n + 1), Set.Icc (c k - a) (c k + a)) :=
        measure_mono hsub
    _ ≤ ∑ k ∈ Finset.range (2 ^ n + 1), volume (Set.Icc (c k - a) (c k + a)) :=
        measure_biUnion_finset_le _ _
    _ = ((2 ^ n + 1 : ℕ) : ENNReal) * ENNReal.ofReal (2 * a) := by
        simp only [hvol, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    _ = ENNReal.ofReal ((2 ^ n + 1 : ℕ) * (2 * a)) := by
        rw [ENNReal.ofReal_mul (p := ((2 ^ n + 1 : ℕ) : ℝ)) (by positivity), ENNReal.ofReal_natCast]
    _ ≤ ENNReal.ofReal (4 * π * η) := by
        apply ENNReal.ofReal_le_ofReal
        have h2 : (2 : ℝ) ^ n * a = π * η := by rw [ha]; field_simp
        have h3 : a ≤ π * η := by rw [ha]; exact div_le_self (by positivity) hP
        push_cast
        nlinarith

#print axioms logistic_four_small_measure

theorem logistic_four_ae_eventually_ge (r : ℝ) (hr0 : 0 < r) (hr1 : r < 1) :
    ∀ᵐ x ∂(volume.restrict (Set.Icc (0 : ℝ) 1)),
      ∀ᶠ n in atTop, (r ^ n) ^ 2 ≤ (logistic 4)^[n] x := by
  have hs : (∑' n, volume.restrict (Set.Icc (0 : ℝ) 1)
      {x | (logistic 4)^[n] x < (r ^ n) ^ 2}) ≠ ⊤ := by
    have hsum : Summable (fun n : ℕ => 4 * π * r ^ n) :=
      (summable_geometric_of_lt_one hr0.le hr1).mul_left _
    refine ne_top_of_le_ne_top (b := ∑' n : ℕ, ENNReal.ofReal (4 * π * r ^ n)) ?_ ?_
    · rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => by positivity) hsum]
      exact ENNReal.ofReal_ne_top
    · refine tsum_le_tsum (fun n => ?_)
      rw [Measure.restrict_apply' measurableSet_Icc]
      exact logistic_four_small_measure n (r ^ n) (by positivity)
  filter_upwards [ae_eventually_notMem hs] with x hx
  filter_upwards [hx] with n hn
  exact not_lt.mp hn

#print axioms logistic_four_ae_eventually_ge

theorem logistic_four_log_step (x : ℝ) (k : ℕ) (h : (logistic 4)^[k + 2] x ≠ 0) :
    2 * Real.log |4 * (1 - 2 * (logistic 4)^[k] x)| + Real.log ((logistic 4)^[k + 1] x) =
      2 * Real.log 2 + Real.log ((logistic 4)^[k + 2] x) := by
  rw [Function.iterate_succ_apply'] at h ⊢
  rw [Function.iterate_succ_apply', Function.iterate_succ_apply'] at *
  set y := (logistic 4)^[k] x
  have key : (4 * (1 - 2 * y)) ^ 2 * logistic 4 y = 4 * logistic 4 (logistic 4 y) := by
    unfold logistic; ring
  have h4 : (4 * (1 - 2 * y)) ^ 2 * logistic 4 y ≠ 0 := by
    rw [key]; exact mul_ne_zero (by norm_num) h
  have ha : (4 * (1 - 2 * y)) ^ 2 ≠ 0 := left_ne_zero_of_mul h4
  have hb : logistic 4 y ≠ 0 := right_ne_zero_of_mul h4
  have e := congrArg Real.log key
  have h42 : Real.log 4 = 2 * Real.log 2 := by
    rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.log_pow]; norm_num
  rw [Real.log_mul ha hb, Real.log_mul (by norm_num) h, Real.log_pow, h42,
    ← Real.log_abs (4 * (1 - 2 * y))] at e
  push_cast at e
  linarith

#print axioms logistic_four_log_step

theorem logistic_four_log_sum (x : ℝ) (h : ∀ m, (logistic 4)^[m] x ≠ 0) (n : ℕ) :
    ∑ k ∈ Finset.range n, Real.log |4 * (1 - 2 * (logistic 4)^[k] x)| =
      n * Real.log 2 + (Real.log ((logistic 4)^[n + 1] x) - Real.log ((logistic 4)^[1] x)) / 2 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, ih]
    have := logistic_four_log_step x n (h (n + 2))
    push_cast
    rw [show n + 1 + 1 = n + 2 by ring]
    linarith

#print axioms logistic_four_log_sum

theorem logistic_four_iterate_zero (m : ℕ) : (logistic 4)^[m] 0 = 0 :=
  Function.iterate_fixed (by norm_num [logistic]) m

#print axioms logistic_four_iterate_zero

theorem settled_contract (y : ℝ) (hy : |y - 9 / 14| ≤ 1 / 20) :
    |logistic (14 / 5) y - 9 / 14| ≤ 47 / 50 * |y - 9 / 14| := by
  have h : logistic (14 / 5) y - 9 / 14 = (1 - 14 / 5 * y) * (y - 9 / 14) := by
    unfold logistic; ring
  rw [h, abs_mul]
  apply mul_le_mul_of_nonneg_right _ (abs_nonneg _)
  rw [abs_le] at hy ⊢
  constructor <;> linarith [hy.1, hy.2]

#print axioms settled_contract

theorem settled_orbit_bound (k : ℕ) :
    |(logistic (14 / 5))^[k + 3] (1 / 5) - 9 / 14| ≤ 1 / 20 * (47 / 50) ^ k := by
  induction k with
  | zero => norm_num [logistic, abs_le]
  | succ k ih =>
    rw [show k + 1 + 3 = (k + 3) + 1 by ring, Function.iterate_succ_apply']
    have hy : |(logistic (14 / 5))^[k + 3] (1 / 5) - 9 / 14| ≤ 1 / 20 :=
      ih.trans (mul_le_of_le_one_right (by norm_num) (pow_le_one₀ (by norm_num) (by norm_num)))
    calc _ ≤ 47 / 50 * |(logistic (14 / 5))^[k + 3] (1 / 5) - 9 / 14| := settled_contract _ hy
      _ ≤ 47 / 50 * (1 / 20 * (47 / 50) ^ k) := by gcongr
      _ = _ := by ring

#print axioms settled_orbit_bound

theorem settled_orbit_tendsto :
    Tendsto (fun k => (logistic (14 / 5))^[k] (1 / 5)) atTop (𝓝 (9 / 14)) := by
  rw [← Filter.tendsto_add_atTop_iff_nat 3]
  have hg : Tendsto (fun k : ℕ => 1 / 20 * (47 / 50 : ℝ) ^ k) atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 47 / 50)
      (by norm_num)).const_mul (1 / 20 : ℝ)
  have := squeeze_zero (fun k => abs_nonneg _) settled_orbit_bound hg
  rw [tendsto_iff_norm_sub_tendsto_zero]
  simpa [Real.norm_eq_abs] using this

#print axioms settled_orbit_tendsto

/-- The card's main theorem: at growth factor 4, for a typical start (every start in [0, 1]
outside a set of length zero), the long-run average of ln of one step's stretch tends to
ln 2, so the Lyapunov exponent is exactly ln 2: one binary digit of the start lost per step. -/
theorem lyapunov_exponent_logistic_four_eq_log_two :
    ∀ᵐ x₀ ∂(volume.restrict (Set.Icc (0 : ℝ) 1)),
      Tendsto (lyapunovAvg 4 x₀) atTop (𝓝 (Real.log 2)) := by
  set r : ℕ → ℝ := fun j => Real.exp (-(1 / ((j : ℝ) + 1)) / 2) with hr
  have hr0 : ∀ j, 0 < r j := fun j => Real.exp_pos _
  have hr1 : ∀ j, r j < 1 := fun j => by
    rw [hr]; apply Real.exp_lt_one_iff.mpr
    have : 0 < 1 / ((j : ℝ) + 1) := by positivity
    linarith
  have hlogr : ∀ (j m : ℕ), Real.log ((r j ^ m) ^ 2) = -((m : ℝ) * (1 / ((j : ℝ) + 1))) := by
    intro j m
    rw [Real.log_pow, Real.log_pow, hr, Real.log_exp]
    push_cast; ring
  have h1 : ∀ᵐ x ∂(volume.restrict (Set.Icc (0 : ℝ) 1)), x ∈ Set.Icc (0 : ℝ) 1 :=
    ae_restrict_mem measurableSet_Icc
  have h2 : ∀ᵐ x ∂(volume.restrict (Set.Icc (0 : ℝ) 1)),
      ∀ j : ℕ, ∀ᶠ n in atTop, (r j ^ n) ^ 2 ≤ (logistic 4)^[n] x :=
    ae_all_iff.mpr (fun j => logistic_four_ae_eventually_ge (r j) (hr0 j) (hr1 j))
  filter_upwards [h1, h2] with x hx hj
  have hmem := logistic_four_iterate_mem x hx
  have hne : ∀ m, (logistic 4)^[m] x ≠ 0 := by
    intro m hm
    obtain ⟨N, hN⟩ := Filter.eventually_atTop.mp (hj 0)
    have h3 := hN (N + m) (by omega)
    rw [Function.iterate_add_apply, hm, logistic_four_iterate_zero] at h3
    have : 0 < (r 0 ^ (N + m)) ^ 2 := by have := hr0 0; positivity
    linarith
  -- the tail term `log x_{n+1} / n` tends to zero
  have htail : Tendsto (fun n : ℕ => Real.log ((logistic 4)^[n + 1] x) / n) atTop (𝓝 0) := by
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨j, hjε⟩ := exists_nat_one_div_lt (half_pos hε)
    obtain ⟨M, hM⟩ := Filter.eventually_atTop.mp (hj j)
    refine ⟨M + 1, fun n hn => ?_⟩
    have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast (show 1 ≤ n by omega)
    have hb := hM (n + 1) (by omega)
    have hpos : 0 < (logistic 4)^[n + 1] x :=
      lt_of_le_of_ne (hmem (n + 1)).1 (Ne.symm (hne (n + 1)))
    have hL0 : Real.log ((logistic 4)^[n + 1] x) ≤ 0 :=
      Real.log_nonpos (hmem (n + 1)).1 (hmem (n + 1)).2
    have hL1 : -(((n + 1 : ℕ) : ℝ) * (1 / ((j : ℝ) + 1))) ≤
        Real.log ((logistic 4)^[n + 1] x) := by
      rw [← hlogr j (n + 1)]
      exact Real.log_le_log (by have := hr0 j; positivity) hb
    push_cast at hL1
    set L := Real.log ((logistic 4)^[n + 1] x)
    set a := 1 / ((j : ℝ) + 1)
    have ha0 : 0 < a := by positivity
    rw [Real.dist_eq, sub_zero, abs_div, abs_of_nonpos hL0, Nat.abs_cast,
      div_lt_iff₀ (by linarith)]
    have h5 : ((n : ℝ) + 1) * a < ((n : ℝ) + 1) * (ε / 2) :=
      mul_lt_mul_of_pos_left hjε (by linarith)
    nlinarith
  have hlim : Tendsto (fun n : ℕ => Real.log 2 + 1 / 2 * (Real.log ((logistic 4)^[n + 1] x) / n)
      - 1 / 2 * (Real.log ((logistic 4)^[1] x) / n)) atTop (𝓝 (Real.log 2)) := by
    have := ((tendsto_const_nhds (x := Real.log 2)).add (htail.const_mul (1 / 2))).sub
      ((tendsto_const_div_atTop_nhds_zero_nat (Real.log ((logistic 4)^[1] x))).const_mul (1 / 2))
    simpa using this
  refine hlim.congr' ?_
  filter_upwards [Filter.eventually_ge_atTop 1] with n hn
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast (show n ≠ 0 by omega)
  unfold lyapunovAvg
  rw [logistic_four_log_sum x hne n]
  field_simp
  ring

/-- Steps 3 and 4: write the start as `x₀ = sin² θ₀`. At growth factor 4 the angle doubles
each step, and the stretches telescope: `∏_{k<n} |f'(x_k)| = 2^n |sin 2θ_n| / |sin 2θ₀|`
with `θ_n = 2^n θ₀`. Stated with the denominator cleared, so it holds for every angle. -/
theorem stretches_telescope_to_two_pow (θ₀ : ℝ) (n : ℕ) :
    |Real.sin (2 * θ₀)| *
        ∏ k ∈ Finset.range n, |4 * (1 - 2 * (logistic 4)^[k] (Real.sin θ₀ ^ 2))| =
      2 ^ n * |Real.sin (2 * (2 ^ n * θ₀))| := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.prod_range_succ, ← mul_assoc, ih, logistic_four_iterate_sin_sq]
    set φ := 2 ^ n * θ₀
    have h1 : 2 * (2 ^ (n + 1) * θ₀) = 2 * (2 * φ) := by rw [pow_succ]; ring
    have h2 : 1 - 2 * Real.sin φ ^ 2 = Real.cos (2 * φ) := by
      rw [Real.cos_two_mul, Real.cos_sq']; ring
    rw [h1, h2, Real.sin_two_mul (2 * φ), pow_succ]
    simp only [abs_mul]
    norm_num
    ring

/-- Negative means settled: at growth factor 2.8, the orbit from 0.2 settles on the fixed
point 9/14, where the stretch is 0.8, and the Lyapunov exponent is ln 0.8 < 0. -/
theorem lyapunov_exponent_settled_at_two_point_eight :
    Tendsto (lyapunovAvg (14 / 5) (1 / 5)) atTop (𝓝 (Real.log (4 / 5))) := by
  have hu : Tendsto (fun k => Real.log |14 / 5 * (1 - 2 * (logistic (14 / 5))^[k] (1 / 5))|)
      atTop (𝓝 (Real.log (4 / 5))) := by
    have hc : ContinuousAt (fun y : ℝ => Real.log |14 / 5 * (1 - 2 * y)|) (9 / 14) := by
      apply ContinuousAt.log
      · fun_prop
      · norm_num [abs_of_neg]
    have := hc.tendsto.comp settled_orbit_tendsto
    have e : Real.log |14 / 5 * (1 - 2 * (9 / 14 : ℝ))| = Real.log (4 / 5) := by
      norm_num [abs_of_neg]
    rw [e] at this
    exact this
  have := hu.cesaro
  unfold lyapunovAvg
  simpa [one_div] using this

-- At growth factor 2.8 the fixed point is 9/14, and the stretch there is 0.8.
example : logistic (14 / 5) (9 / 14) = 9 / 14 := by norm_num [logistic]
example : |(14 / 5 : ℝ) * (1 - 2 * (9 / 14))| = 4 / 5 := by norm_num [abs_of_neg]

-- At growth factor 4 the start 0 is a fixed point, with stretch 4 (so ln 4 there).
example : logistic 4 0 = 0 := by norm_num [logistic]
example : |(4 : ℝ) * (1 - 2 * 0)| = 4 := by norm_num

-- At growth factor 4 the start 0.5 lands on 0: 0.5 goes to 1, and 1 goes to 0.
example : (logistic 4)^[2] (1 / 2) = 0 := by norm_num [logistic]

-- One step's stretch at 0.2 with growth factor 3.9 is 2.34.
example : |(39 / 10 : ℝ) * (1 - 2 * (1 / 5))| = 117 / 50 := by norm_num [abs_of_pos]

#print axioms lyapunov_exponent_logistic_four_eq_log_two
#print axioms stretches_telescope_to_two_pow
#print axioms lyapunov_exponent_settled_at_two_point_eight
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'logistic_four_iterate_sin_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'logistic_four_iterate_mem' depends on axioms: [propext, Classical.choice, Quot.sound]
'logistic_four_near_root' depends on axioms: [propext, Classical.choice, Quot.sound]
'logistic_four_small_measure' depends on axioms: [propext, Classical.choice, Quot.sound]
'logistic_four_ae_eventually_ge' depends on axioms: [propext, Classical.choice, Quot.sound]
'logistic_four_log_step' depends on axioms: [propext, Classical.choice, Quot.sound]
'logistic_four_log_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
'logistic_four_iterate_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'settled_contract' depends on axioms: [propext, Classical.choice, Quot.sound]
'settled_orbit_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'settled_orbit_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'lyapunov_exponent_logistic_four_eq_log_two' depends on axioms: [propext, Classical.choice, Quot.sound]
'stretches_telescope_to_two_pow' depends on axioms: [propext, Classical.choice, Quot.sound]
'lyapunov_exponent_settled_at_two_point_eight' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Growth factor 3.83.** Change `lam(3.9)` to `lam(3.83)`. Guess the sign. Negative: the orbit settles on a three-cycle, and the last assert stops the run.
> - **A sharper survey.** Change `1e-13` to `1e-14` and `math.log(1000)` to `math.log(10000)`. The last assert stops the run: a few twin starts now round to one floating-point number, never separate, and drag the mean up.
> - **Break the derivative.** In the first sum, write `r * (1 - x)` for `r * (1 - 2 * x)`. Road 1 leaves the twin orbit, and the first assert stops it.

---

## The usual mistake

> [!warning]
> **Reading chaos as randomness.** The map has no chance in it: the same start gives the same orbit every time. The exponent measures how fast uncertainty about the start grows, 0.716 bits per step at 3.9. An exact rule does not help without an exact start.
>
> - **Expecting precision to buy time in proportion.** A thousand-fold sharper survey adds 13.91 steps to a 44.98-step horizon.
> - **An exceptional start.** The fixed point 0 at growth factor 4 gives ln 4, but it repels; typical orbits never stay there.

---

## Where you meet it in real life

- **Weather forecasting.** The atmosphere has a positive exponent, so forecast skill fades after a stretch of days, and better instruments add days only logarithmically. The model flow is [The Lorenz system](06-the-lorenz-system-and-strange-attractors.md).
- **Population ecology.** Robert May's 1976 survey showed the logistic map can be chaotic, so erratic census data need not mean a noisy environment.
- **Measured data.** Wolf and colleagues estimate the exponent from a recorded series alone, following nearby points as the twin-orbit road does.

> **Say it back**
> The Lyapunov exponent is the long-run average of the logarithm of one step's stretch. A tiny error grows like e to the exponent times the steps: positive means chaos, negative means the orbit settles. At growth factor 3.9 it is 0.4965, and a 1e-10 error reaches 0.5 after about 45 steps. At 4, writing the state as a sine squared doubles an angle each step, the stretches telescope to 2 to the n, and the exponent is exactly ln 2. Sharper starts buy time only logarithmically.

---

## What this builds on

- [The logistic map](03-the-logistic-map-and-period-doubling.md): the map, its cycles, and the cascade into chaos that the exponent measures.
- [Trig identities](../../05-Geometry%20and%20trig/03-Trigonometry/03-trig-identities.md): the double-angle formulas behind the exact value ln 2.

## Where this goes next

- [The doubling map](05-the-doubling-map-and-symbolic-dynamics.md): the angle doubling of Step 3 read as a shift of binary digits.
- [The Lorenz system](06-the-lorenz-system-and-strange-attractors.md): a positive exponent in a continuous flow in three dimensions.

Left open: if every small gap keeps stretching, how do the orbits stay inside the range, and what shape do they trace there?

---

## Sources

Verified 28 Sep 2026: every link below resolves to the publisher's page.

- Strogatz, Steven H. *Nonlinear Dynamics and Chaos*, 2nd ed. CRC Press. [Publisher page](https://www.routledge.com/Nonlinear-Dynamics-and-Chaos-With-Applications-to-Physics-Biology-Chemistry-and-Engineering/Strogatz/p/book/9780367026509). Chapter 10: the exponent as an orbit average, for the logistic map.
- May, Robert M. "Simple mathematical models with very complicated dynamics." *Nature* 261 (1976): 459–467. [DOI](https://doi.org/10.1038/261459a0). The logistic map's chaos, for ecology.
- Benettin, G., L. Galgani, A. Giorgilli and J.-M. Strelcyn. "Lyapunov characteristic exponents for smooth dynamical systems and for Hamiltonian systems; a method for computing all of them. Part 1: Theory." *Meccanica* 15 (1980): 9–20. [DOI](https://doi.org/10.1007/BF02128236). The twin-orbit method of the second road.
- Wolf, A., J. B. Swift, H. L. Swinney and J. A. Vastano. "Determining Lyapunov exponents from a time series." *Physica D* 16 (1985): 285–317. [DOI](https://doi.org/10.1016/0167-2789(85)90011-9). The exponent from recorded data.
