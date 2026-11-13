# Half-range series: extend a function on [0, L] as odd or even so the series matches fixed or insulated ends

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Fourier Series](../README.md#s09) → Half-range series

---

## General Overview

A string 1 m long is pinned at both ends. Pull its middle 1 cm aside and hold it. The string makes a triangle: 0 cm at the ends, 1 cm at the middle. Released, it vibrates in its own shapes, the modes: one hump, two, three, each pinned at both ends. Which mix makes the triangle?

The Fourier series of [Fourier series](01-fourier-series-and-orthogonality.md) needs a function that repeats forever. The string lives only on 0 to 1 m, so invent the rest: reflect the triangle across the left end, and repeat. Flip the copy upside down and only sine waves appear, each zero at both ends, as a pinned string demands. Mirror it upright and only cosines appear, each flat at both ends.

Flat ends suit a metal rod. Heat flows along it at a rate set by the slope of its temperature, so zero slope at an end means no heat crosses: an insulated end. Give a 1 m rod the same triangle as its temperature, in °C above the room, and the cosine series describes it.

**On a stretch from 0 to L, a function can be written with sines alone or with cosines alone; sines fit ends held at zero, cosines fit sealed ends, and each coefficient is twice the average of the function times its mode.**

**What kind of fact this is:** a method: the reflection is a choice matched to the ends; the coefficient formulas it rests on are proved on this card in Why it works.

### The picture: one triangle, two reflections

<p align="center"><img src="../figures/half-range-sine-and-cosine-series.svg" alt="The plucked-string triangle on 0 to 1 m, peak 1 cm at 0.5 m, drawn solid; above, its odd reflection on -1 to 0 m drawn dashed and upside down; below, its even reflection drawn dashed and upright" width="420"></p>

Scale: 150 units per metre across, 40 per centimetre up. Solid: the real string. Dashed: the invented half, flipped (top) or mirrored (bottom). Dotted: the left end, x = 0. Each picture repeats every 2 m.

---

## The formula

Notation first, in words. The string's shape is $f$: at position $x$ metres from the left end, it stands f(x) centimetres aside. Its length is $L$. The **odd extension** $F_o$ copies $f$ onto the left half upside down; the **even extension** $F_e$ copies it upright. For x between −L and 0:

$$F_o(x) = -f(-x), \qquad F_e(x) = f(-x)$$

Both then repeat every 2L. Σ adds a term for each n = 1, 2, 3 and on.

$$b_n = \frac{2}{L}\int_0^L f(x)\sin\frac{n\pi x}{L}\,dx, \qquad a_n = \frac{2}{L}\int_0^L f(x)\cos\frac{n\pi x}{L}\,dx$$

$$f(x) = \sum_{n=1}^{\infty} b_n \sin\frac{n\pi x}{L} = \frac{a_0}{2} + \sum_{n=1}^{\infty} a_n \cos\frac{n\pi x}{L} \quad \text{for } 0 < x < L$$

**Read it aloud:** each coefficient is twice the average of the shape times its mode; adding the modes back rebuilds the shape.

For the triangle, with L = 1 m, integration by parts gives:

$$b_n = \frac{8\sin(n\pi/2)}{n^2\pi^2}, \qquad a_n = \frac{4\,\big(2\cos(n\pi/2) - 1 - (-1)^n\big)}{n^2\pi^2}, \qquad a_0 = 1$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$ | position, metres from the left end | 0 to 1 m | walks along the triangle |
| $L$ | length of the string or rod | 1 m | every mode stretches to fit |
| $f$ | the shape: pull in cm, or °C above the room | 1 at x = 0.5 m | every coefficient scales with it |
| $n$ | mode number: n half-waves fit in the length | 1, 3, 5 carry the string | coefficients shrink like 1/n^2 |
| $b_n$ | sine coefficient, cm | b1 = 0.8106, b3 = −0.0901 | a bigger share of that mode |
| $a_n$, $a_0$ | cosine coefficients; a0/2 is the average | a0 = 1, a2 = −0.4053 | a bigger share of that mode |
| $F_o$, $F_e$ | the odd and even extensions, period 2L | the two dashed pictures | they agree with f on 0 to L |
| $N$ | how many modes a partial sum keeps | 1, 3, 5, 99 | the sum closes on f |

Here sin(nπ/2) is 1, −1, 1 on n = 1, 3, 5 and 0 on even n; the cosine coefficients vanish except at n = 2, 6, 10.

### When it holds

- **Ends at zero, or ends sealed.** Sines suit f = 0 at both ends (a Dirichlet condition: the value is fixed); cosines suit zero slope (a Neumann condition: the slope is fixed). An end held at 20 °C needs the straight line through the end values subtracted first.
- **A piecewise smooth shape.** Finitely many corners and jumps; then both series converge inside ([Convergence](02-convergence-jumps-and-gibbs.md)). The triangle has one corner.
- **Matching ends for speed.** With f(0) = f(L) = 0 the odd extension is continuous and the sine coefficients shrink like 1/n^2. With f(L) ≠ 0 it jumps: coefficients shrink like 1/n and the sum overshoots beside the end. The even extension never jumps when f is continuous, so cosine coefficients shrink like 1/n^2 whatever the end values.
- **The same kind of end at both ends.** One pinned and one sealed end need quarter waves instead, sin((2k − 1)πx/(2L)).

---

## Why it works

### Step 0: reflect, then use the full-period series

Reflection builds a function of period 2L equal to f on 0 to L. Its full series, read on 0 to L, is a series for f; the reflection decides which modes survive.

### Step 1: the odd reflection kills every cosine

Over the full period, $a_n$ is 1/L times the integral from −L to L of the extension against cos(nπx/L), and $b_n$ the same with sin. An odd function times the even cosine is odd: its left half cancels its right half, so every cosine coefficient is 0. Times the odd sine it is even: the halves are equal, and the doubling turns 1/L into 2/L.

<details>
<summary>The algebra behind this</summary>

On the left half put x = −u. The odd extension at −u is −f(u) and sin(−nπu/L) = −sin(nπu/L); the two signs cancel, and dx = −du flips the limits back to 0 to L, so the left half equals the right half. With cosine, cos(−nπu/L) = cos(nπu/L), one sign survives, and the halves cancel.

</details>

### Step 2: the even reflection kills every sine

Swap the roles: even times sine cancels, even times cosine doubles. The cosine series keeps n = 0, the constant mode; its term a0/2 is the average of f, 0.5 °C for the rod.

### Step 3: the modes are the ends' own shapes

The same formulas come from the ends alone. Pinned ends ask X(0) = X(L) = 0 of each mode shape X; the problem X'' = −λX, with X'' the second derivative of X and λ a constant to be found, then has the solutions sin(nπx/L). Sealed ends, X'(0) = X'(L) = 0, with X' the slope, give cos(nπx/L) for n = 0, 1, 2 and on ([Eigenvalue problems](../07-Series%20Solutions%20and%20Boundary%20Problems/08-eigenvalues-and-eigenfunctions.md)).

On 0 to L the integral of sin(mπx/L) sin(nπx/L) is 0 when m ≠ n and L/2 when m = n. The cosines behave the same, except the constant mode, whose integral is L, which is why its term is a0/2. Multiply the series by one mode and integrate: one term survives, and the formula returns. Every partial sum obeys the end condition term by term.

### Step 4: the triangle's coefficients

Split at the peak. The right half mirrors the left, and mirroring a mode multiplies it by ±1, so all reduces to one integral of 2x against a sine or cosine on 0 to ½, done by parts. Even sine modes cancel: they are lopsided about the middle, and the triangle is not.

<details>
<summary>Detailed proof: the coefficients by parts</summary>

Take L = 1 and k = nπ. On the right half put x = 1 − u, so f = 2u. Since sin(nπ − ku) = −(−1)^n sin(ku) and cos(nπ − ku) = (−1)^n cos(ku),

$$b_n = 2\big(1 - (-1)^n\big) I, \quad a_n = 2\big(1 + (-1)^n\big) J,$$

with I and J the integrals of 2u sin(ku) and 2u cos(ku) from 0 to ½. By parts, u sin(ku) and u cos(ku) have antiderivatives −u cos(ku)/k + sin(ku)/k^2 and u sin(ku)/k + cos(ku)/k^2. Doubling and evaluating from 0 to ½:

$$I = -\frac{\cos(n\pi/2)}{n\pi} + \frac{2\sin(n\pi/2)}{n^2\pi^2}, \qquad J = \frac{\sin(n\pi/2)}{n\pi} + \frac{2\big(\cos(n\pi/2) - 1\big)}{n^2\pi^2}.$$

For odd n, cos(nπ/2) = 0, so the sine coefficient is 4I = 8 sin(nπ/2)/(n^2π^2) and the cosine coefficient is 0. For even n, the sine coefficient is 0 and sin(nπ/2) = 0, so the cosine coefficient is 4J = 8(cos(nπ/2) − 1)/(n^2π^2): zero when 4 divides n, −16/(n^2π^2) otherwise. Both cases fit the single cosine formula above. Finally a0 = 2 times the triangle's area, 2 × ½ × 1 × 1 = 1.

</details>

### Step 5: why so few modes suffice

A corner, not a jump, makes the coefficients shrink like 1/n^2. Their sizes add to a finite total, so after N modes the error anywhere is at most the sum of the dropped ones. For odd n above 99 that sum is below 8/(π^2 × 198), which is 0.00409 cm; the check measures 0.00405 cm.

A third road checks the coefficients through the sum of their squares: [Parseval's identity](03-parsevals-identity.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| first sine coefficient | 8/π^2 | b1 = 0.8106 cm |
| third and fifth | −8/(9π^2), 8/(25π^2) | −0.0901, 0.0324 cm |
| peak, modes 1 and 3 | 8/π^2 + 8/(9π^2) | 0.9006 cm |
| peak, modes 1, 3, 5 | add 8/(25π^2) | 0.9331 cm |
| rod: average, then a2 | a0/2 = ½; −16/(4π^2) | 0.5000, −0.4053 °C |
| rod middle, through a2 | 0.5 + 0.4053 | 0.9053 °C |
| **peak, all modes** | (8/π^2)(1 + 1/9 + 1/25 + …) | **1 cm** |

The fundamental carries 0.81 cm of the 1 cm pull; no even mode is present. Read backwards, the last row says 1 + 1/9 + 1/25 + … = π^2/8.

### The picture: the sine sums closing on the triangle

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Plucked string and its sine sums"
    x-axis "position x (m)" [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
    y-axis "displacement (cm)" 0 --> 1.1
    line [0.00, 0.20, 0.40, 0.60, 0.80, 1.00, 0.80, 0.60, 0.40, 0.20, 0.00]
    line [0.00, 0.25, 0.48, 0.66, 0.77, 0.81, 0.77, 0.66, 0.48, 0.25, 0.00]
    line [0.00, 0.21, 0.39, 0.60, 0.82, 0.93, 0.82, 0.60, 0.39, 0.21, 0.00]
```

Orange: the triangle. Teal: mode 1 alone, peaking at 0.81 cm. Dark blue: modes 1, 3 and 5, peaking at 0.93 cm. Every sum is 0 at both ends.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Full-period factor 1/L on the half range | b1 = 0.4053 cm; peak 0.5000 cm | The doubling of Step 1 was dropped |
| Cosine modes for the pinned string | end reads 0.0947 cm with a0 and a2 | Cosines are not zero at the ends |
| Alternating signs dropped | peak reads 0.7425 cm, not 1 | Mode 3 now subtracts at the middle |

The code prints all three.

---

## Code, from first principles, and it actually runs

Two roads to every coefficient: the by-parts formula, and the odd or even extension integrated against its mode over the whole period, −L to L, with factor 1/L and a hand-written Simpson rule (a weighted sum of 2,001 sampled values). Road two never uses the half-range formula, so it tests the reflection itself. The sums are held to Step 5's tail bound on 101 points.

### Python

```python
# Half-range series -- the check behind the card.  Only math.sin, cos and pi
# are imported.  A 1 m string is pulled 1 cm aside at its middle: the triangle
# f.  Road one: coefficients by integration by parts.  Road two: build the odd
# and even reflections and integrate them over the whole period, -L to L.
from math import sin, cos, pi
L = 1.0
def f(x):                                   # the triangle, in cm, 0 <= x <= L
    return 2 * x / L if x <= L / 2 else 2 * (L - x) / L
def odd(x): return f(x) if x >= 0 else -f(-x)       # reflect with a sign flip
def even(x): return f(abs(x))                       # reflect without one
def simpson(g, a, b, m=2000):               # composite Simpson rule, written out
    h = (b - a) / m
    return h / 3 * (g(a) + g(b) + sum((4 if j % 2 else 2) * g(a + j * h) for j in range(1, m)))
def b(n): return 8 * [0, 1, 0, -1][n % 4] / (n * pi) ** 2     # road one, sine
def a(n):                                                      # road one, cosine
    return 1.0 if n == 0 else 4 * (2 * [1, 0, -1, 0][n % 4] - 1 - (-1) ** n) / (n * pi) ** 2
def S(x, N): return sum(b(n) * sin(n * pi * x / L) for n in range(1, N + 1))
def C(x, N): return a(0) / 2 + sum(a(n) * cos(n * pi * x / L) for n in range(1, N + 1))
def r(v, d=4): return f"{round(v, d) + 0.0:.{d}f}"
def row(vals, d=4): return " ".join(r(v, d) for v in vals)
b_int = [simpson(lambda x: odd(x) * sin(n * pi * x / L), -L, L) / L for n in range(1, 8)]
a_int = [simpson(lambda x: even(x) * cos(n * pi * x / L), -L, L) / L for n in range(0, 7)]
print("sine b1..b7, by parts:      ", row(b(n) for n in range(1, 8)))
print("sine b1..b7, odd reflection:", row(b_int))
print("cosine a0..a6, by parts:      ", row(a(n) for n in range(0, 7)))
print("cosine a0..a6, even reflection:", row(a_int))
print("string peak, sine sum with modes 1 / 1,3 / 1,3,5:", row(S(0.5, N) for N in (1, 3, 5)))
print("rod middle, cosine sum through a2 / through a6:", row(C(0.5, N) for N in (2, 6)))
ends = max(abs(S(x, N)) for x in (0, L) for N in (1, 3, 5, 99))
slopes = max(abs(sum(-a(n) * n * pi / L * sin(n * pi * x / L) for n in range(1, 100))) for x in (0, L))
print("sine sums at both ends below 1e-12:", "yes" if ends < 1e-12 else "no",
      "; cosine end slopes below 1e-12:", "yes" if slopes < 1e-12 else "no")
grid = [k / 100 for k in range(101)]
err_s = max(abs(S(x, 99) - f(x)) for x in grid)
err_c = max(abs(C(x, 99) - f(x)) for x in grid)
tail_s = 8 / pi ** 2 / (2 * 99)             # odd n > 99: sum of 1/n^2 <= 1/198
tail_c = 16 / pi ** 2 / (4 * 98)            # n = 102, 106, ...: sum <= 1/392
print(f"99 modes, 101 points: sine max error {r(err_s, 5)} (tail bound {r(tail_s, 5)}), "
      f"cosine {r(err_c, 5)} (bound {r(tail_c, 5)})")
print("rod, insulated: mean", r(simpson(f, 0, L) / L), "= a0/2 =", r(a(0) / 2))
xs = [k / 10 for k in range(11)]
print("chart, triangle:", row((f(x) for x in xs), 2))
print("chart, mode 1:  ", row((S(x, 1) for x in xs), 2))
print("chart, modes 1,3,5:", row((S(x, 5) for x in xs), 2))
X = lambda x: 190 + 150 * x
for name, g, base in (("odd", odd, 70), ("even", even, 190)):
    print(f"figure, {name}:", " ".join(f"{X(x):.0f},{base - 40 * g(x):.0f}" for x in (-1, -0.5, 0, 0.5, 1)))
print("mistake 1, factor 1/L on half the range: b1 =", r(simpson(lambda x: f(x) * sin(pi * x), 0, L) / L),
      "cm, peak reads", r(S(0.5, 9999) / 2), "cm")
print("mistake 2, cosine modes for the pinned string: end reads", r(C(0, 2)), "cm, not 0")
print("mistake 3, alternating signs dropped: peak reads",
      r(sum(abs(b(n)) * sin(n * pi / 2) for n in range(1, 10000))), "cm, not 1")
assert all(abs(p - q) < 1e-9 for p, q in zip((b(n) for n in range(1, 8)), b_int))  # two roads, sine
assert all(abs(p - q) < 1e-9 for p, q in zip((a(n) for n in range(0, 7)), a_int))  # two roads, cosine
assert err_s <= tail_s + 1e-12 and err_c <= tail_c + 1e-12      # sums land on f
assert abs(S(0.5, 9999) - f(0.5)) < 1e-4                        # the peak is 1 cm
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
sine b1..b7, by parts:       0.8106 0.0000 -0.0901 0.0000 0.0324 0.0000 -0.0165
sine b1..b7, odd reflection: 0.8106 0.0000 -0.0901 0.0000 0.0324 0.0000 -0.0165
cosine a0..a6, by parts:       1.0000 0.0000 -0.4053 0.0000 0.0000 0.0000 -0.0450
cosine a0..a6, even reflection: 1.0000 0.0000 -0.4053 0.0000 0.0000 0.0000 -0.0450
string peak, sine sum with modes 1 / 1,3 / 1,3,5: 0.8106 0.9006 0.9331
rod middle, cosine sum through a2 / through a6: 0.9053 0.9503
sine sums at both ends below 1e-12: yes ; cosine end slopes below 1e-12: yes
99 modes, 101 points: sine max error 0.00405 (tail bound 0.00409), cosine 0.00405 (bound 0.00414)
rod, insulated: mean 0.5000 = a0/2 = 0.5000
chart, triangle: 0.00 0.20 0.40 0.60 0.80 1.00 0.80 0.60 0.40 0.20 0.00
chart, mode 1:   0.00 0.25 0.48 0.66 0.77 0.81 0.77 0.66 0.48 0.25 0.00
chart, modes 1,3,5: 0.00 0.21 0.39 0.60 0.82 0.93 0.82 0.60 0.39 0.21 0.00
figure, odd: 40,70 115,110 190,70 265,30 340,70
figure, even: 40,190 115,150 190,190 265,150 340,190
mistake 1, factor 1/L on half the range: b1 = 0.4053 cm, peak reads 0.5000 cm
mistake 2, cosine modes for the pinned string: end reads 0.0947 cm, not 0
mistake 3, alternating signs dropped: peak reads 0.7425 cm, not 1
ALL CHECKS PASS
```

### Rust

```rust
// Half-range series -- the same check as the Python, in Rust, std only.  A 1 m
// string is pulled 1 cm aside at its middle: the triangle f.  Road one:
// coefficients by integration by parts.  Road two: build the odd and even
// reflections and integrate them over the whole period, -L to L.
use std::f64::consts::PI;
const L: f64 = 1.0;
fn f(x: f64) -> f64 { if x <= L / 2.0 { 2.0 * x / L } else { 2.0 * (L - x) / L } }
fn odd(x: f64) -> f64 { if x >= 0.0 { f(x) } else { -f(-x) } }
fn even(x: f64) -> f64 { f(x.abs()) }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let m = 2000;
    let h = (b - a) / m as f64;
    let inner: f64 = (1..m).map(|j| if j % 2 == 1 { 4.0 } else { 2.0 } * g(a + j as f64 * h)).sum();
    h / 3.0 * (g(a) + g(b) + inner)
}
fn b(n: i64) -> f64 { 8.0 * [0.0, 1.0, 0.0, -1.0][(n % 4) as usize] / (n as f64 * PI).powi(2) }
fn a(n: i64) -> f64 {
    if n == 0 { return 1.0; }
    let c = [1.0, 0.0, -1.0, 0.0][(n % 4) as usize];
    let alt = if n % 2 == 0 { 1.0 } else { -1.0 };
    4.0 * (2.0 * c - 1.0 - alt) / (n as f64 * PI).powi(2)
}
fn s(x: f64, n: i64) -> f64 { (1..=n).map(|k| b(k) * (k as f64 * PI * x / L).sin()).sum() }
fn c(x: f64, n: i64) -> f64 { a(0) / 2.0 + (1..=n).map(|k| a(k) * (k as f64 * PI * x / L).cos()).sum::<f64>() }
fn r(v: f64, d: i32) -> String {
    let p = 10f64.powi(d);
    format!("{:.*}", d as usize, (v * p).round() / p + 0.0)
}
fn row(vals: &[f64], d: i32) -> String { vals.iter().map(|&v| r(v, d)).collect::<Vec<_>>().join(" ") }
fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }
fn main() {
    let b_int: Vec<f64> = (1..8).map(|n| simpson(&|x| odd(x) * (n as f64 * PI * x / L).sin(), -L, L) / L).collect();
    let a_int: Vec<f64> = (0..7).map(|n| simpson(&|x| even(x) * (n as f64 * PI * x / L).cos(), -L, L) / L).collect();
    let b_by: Vec<f64> = (1..8).map(b).collect();
    let a_by: Vec<f64> = (0..7).map(a).collect();
    println!("sine b1..b7, by parts:       {}", row(&b_by, 4));
    println!("sine b1..b7, odd reflection: {}", row(&b_int, 4));
    println!("cosine a0..a6, by parts:       {}", row(&a_by, 4));
    println!("cosine a0..a6, even reflection: {}", row(&a_int, 4));
    println!("string peak, sine sum with modes 1 / 1,3 / 1,3,5: {}", row(&[s(0.5, 1), s(0.5, 3), s(0.5, 5)], 4));
    println!("rod middle, cosine sum through a2 / through a6: {}", row(&[c(0.5, 2), c(0.5, 6)], 4));
    let mut ends: f64 = 0.0;
    for x in [0.0, L] { for n in [1, 3, 5, 99] { ends = ends.max(s(x, n).abs()); } }
    let slopes = [0.0, L].iter().map(|&x| (1..100).map(|k| -a(k) * k as f64 * PI / L * (k as f64 * PI * x / L).sin())
        .sum::<f64>().abs()).fold(0.0, f64::max);
    println!("sine sums at both ends below 1e-12: {} ; cosine end slopes below 1e-12: {}", yn(ends < 1e-12), yn(slopes < 1e-12));
    let grid: Vec<f64> = (0..101).map(|k| k as f64 / 100.0).collect();
    let err_s = grid.iter().map(|&x| (s(x, 99) - f(x)).abs()).fold(0.0, f64::max);
    let err_c = grid.iter().map(|&x| (c(x, 99) - f(x)).abs()).fold(0.0, f64::max);
    let tail_s = 8.0 / PI.powi(2) / (2.0 * 99.0); // odd n > 99: sum of 1/n^2 <= 1/198
    let tail_c = 16.0 / PI.powi(2) / (4.0 * 98.0); // n = 102, 106, ...: sum <= 1/392
    println!("99 modes, 101 points: sine max error {} (tail bound {}), cosine {} (bound {})",
        r(err_s, 5), r(tail_s, 5), r(err_c, 5), r(tail_c, 5));
    println!("rod, insulated: mean {} = a0/2 = {}", r(simpson(&f, 0.0, L) / L, 4), r(a(0) / 2.0, 4));
    let xs: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    println!("chart, triangle: {}", row(&xs.iter().map(|&x| f(x)).collect::<Vec<_>>(), 2));
    println!("chart, mode 1:   {}", row(&xs.iter().map(|&x| s(x, 1)).collect::<Vec<_>>(), 2));
    println!("chart, modes 1,3,5: {}", row(&xs.iter().map(|&x| s(x, 5)).collect::<Vec<_>>(), 2));
    let fx = |x: f64| 190.0 + 150.0 * x;
    for (name, g, base) in [("odd", odd as fn(f64) -> f64, 70.0), ("even", even, 190.0)] {
        let pts: Vec<String> = [-1.0, -0.5, 0.0, 0.5, 1.0].iter()
            .map(|&x| format!("{:.0},{:.0}", fx(x), base - 40.0 * g(x))).collect();
        println!("figure, {}: {}", name, pts.join(" "));
    }
    println!("mistake 1, factor 1/L on half the range: b1 = {} cm, peak reads {} cm",
        r(simpson(&|x| f(x) * (PI * x).sin(), 0.0, L) / L, 4), r(s(0.5, 9999) / 2.0, 4));
    println!("mistake 2, cosine modes for the pinned string: end reads {} cm, not 0", r(c(0.0, 2), 4));
    let dropped: f64 = (1..10000).map(|n| b(n).abs() * (n as f64 * PI / 2.0).sin()).sum();
    println!("mistake 3, alternating signs dropped: peak reads {} cm, not 1", r(dropped, 4));
    assert!(b_by.iter().zip(&b_int).all(|(p, q)| (p - q).abs() < 1e-9)); // two roads, sine
    assert!(a_by.iter().zip(&a_int).all(|(p, q)| (p - q).abs() < 1e-9)); // two roads, cosine
    assert!(err_s <= tail_s + 1e-12 && err_c <= tail_c + 1e-12); // sums land on f
    assert!((s(0.5, 9999) - f(0.5)).abs() < 1e-4); // the peak is 1 cm
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
sine b1..b7, by parts:       0.8106 0.0000 -0.0901 0.0000 0.0324 0.0000 -0.0165
sine b1..b7, odd reflection: 0.8106 0.0000 -0.0901 0.0000 0.0324 0.0000 -0.0165
cosine a0..a6, by parts:       1.0000 0.0000 -0.4053 0.0000 0.0000 0.0000 -0.0450
cosine a0..a6, even reflection: 1.0000 0.0000 -0.4053 0.0000 0.0000 0.0000 -0.0450
string peak, sine sum with modes 1 / 1,3 / 1,3,5: 0.8106 0.9006 0.9331
rod middle, cosine sum through a2 / through a6: 0.9053 0.9503
sine sums at both ends below 1e-12: yes ; cosine end slopes below 1e-12: yes
99 modes, 101 points: sine max error 0.00405 (tail bound 0.00409), cosine 0.00405 (bound 0.00414)
rod, insulated: mean 0.5000 = a0/2 = 0.5000
chart, triangle: 0.00 0.20 0.40 0.60 0.80 1.00 0.80 0.60 0.40 0.20 0.00
chart, mode 1:   0.00 0.25 0.48 0.66 0.77 0.81 0.77 0.66 0.48 0.25 0.00
chart, modes 1,3,5: 0.00 0.21 0.39 0.60 0.82 0.93 0.82 0.60 0.39 0.21 0.00
figure, odd: 40,70 115,110 190,70 265,30 340,70
figure, even: 40,190 115,150 190,190 265,150 340,190
mistake 1, factor 1/L on half the range: b1 = 0.4053 cm, peak reads 0.5000 cm
mistake 2, cosine modes for the pinned string: end reads 0.0947 cm, not 0
mistake 3, alternating signs dropped: peak reads 0.7425 cm, not 1
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves the reflection rule and the end conditions for every length, and the triangle's coefficients and middle sums exactly.

- Take any length L above 0 and any shape f that can be integrated on 0 to L. Then the odd extension has every full-period cosine coefficient 0.
- With the same L and f, the odd extension's full-period sine coefficients are exactly $b_n$, for every n.
- With the same L and f, the even extension has every full-period sine coefficient 0. Its full-period cosine coefficients are exactly $a_n$, $a_0$ included.
- Take any L above 0, any coefficients and any number of modes N. Then the sine partial sum is 0 at x = 0 and at x = L.
- With the same choices, the cosine partial sum has slope 0 at x = 0 and at x = L.
- Take the triangle, with L = 1. Then for every n from 1 up, $b_n$ and $a_n$ equal the by-parts formulas above, and $a_0 = 1$.
- At the middle, x = 0.5, the sine series adds up to exactly 1, the peak.
- At the middle, a0/2 plus the cosine series also adds up to exactly 1.
- The hand arithmetic holds exactly: a0 as twice the area, which low modes vanish, and the −16 in a2.

The decimals, the 99-mode error bound and the mistakes are left to the Python and Rust checks; Lean sums the series only at the middle.

```lean
-- Half-range series: reflecting f on [0, L] as odd keeps only sines and as even keeps only cosines, each coefficient being (2/L) times the integral of f against its mode; sine sums vanish at both ends and cosine sums are flat there; and the plucked triangle has b_n = 8 sin(nπ/2)/(n²π²), a_n = 4(2cos(nπ/2) − 1 − (−1)^n)/(n²π²), a_0 = 1, with both series giving its middle value.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.NumberTheory.ZetaValues
import Mathlib.Tactic.NormNum

open Real MeasureTheory

/-- The odd extension of f: f itself for x ≥ 0, and −f(−x) for x < 0. -/
noncomputable def oddExt (f : ℝ → ℝ) (x : ℝ) : ℝ := if 0 ≤ x then f x else -f (-x)

/-- The even extension of f: f itself for x ≥ 0, and f(−x) for x < 0. -/
noncomputable def evenExt (f : ℝ → ℝ) (x : ℝ) : ℝ := if 0 ≤ x then f x else f (-x)

/-- The half-range sine coefficient b_n = (2/L) ∫₀ᴸ f(x) sin(nπx/L) dx. -/
noncomputable def halfSineCoeff (L : ℝ) (f : ℝ → ℝ) (n : ℕ) : ℝ :=
  (2 / L) * ∫ x in (0 : ℝ)..L, f x * Real.sin (n * π * x / L)

/-- The half-range cosine coefficient a_n = (2/L) ∫₀ᴸ f(x) cos(nπx/L) dx. -/
noncomputable def halfCosineCoeff (L : ℝ) (f : ℝ → ℝ) (n : ℕ) : ℝ :=
  (2 / L) * ∫ x in (0 : ℝ)..L, f x * Real.cos (n * π * x / L)

/-- The plucked string on [0, 1]: 2x up to the middle, 2(1 − x) after it, peak 1 at x = 1/2. -/
noncomputable def pluck (x : ℝ) : ℝ := if x ≤ 1 / 2 then 2 * x else 2 * (1 - x)

lemma intervalIntegrable_congr_Ioo {g h : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hg : IntervalIntegrable g volume a b) (heq : Set.EqOn g h (Set.Ioo a b)) :
    IntervalIntegrable h volume a b := by
  rw [intervalIntegrable_iff_integrableOn_Ioo_of_le hab] at hg ⊢
  exact hg.congr_fun heq measurableSet_Ioo

lemma integral_symm_split (L : ℝ) (F : ℝ → ℝ) (h0 : IntervalIntegrable F volume 0 L)
    (h1 : IntervalIntegrable (fun x => F (-x)) volume 0 L) :
    (∫ x in (-L)..L, F x) = (∫ x in (0 : ℝ)..L, F (-x)) + ∫ x in (0 : ℝ)..L, F x := by
  have h1' : IntervalIntegrable F volume (-L) 0 := by
    have := (IntervalIntegrable.iff_comp_neg (f := fun x => F (-x))).mp h1
    simpa using this.symm
  rw [← intervalIntegral.integral_add_adjacent_intervals h1' h0, intervalIntegral.integral_comp_neg]
  simp

lemma pluck_eq_min : pluck = fun x => min (2 * x) (2 * (1 - x)) := by
  ext x; unfold pluck
  split_ifs with h
  · rw [min_eq_left (by linarith)]
  · rw [min_eq_right (by linarith)]

lemma pluck_continuous : Continuous pluck := by
  rw [pluck_eq_min]; fun_prop

lemma pluck_integral (g : ℝ → ℝ) (hg : Continuous g) (F G : ℝ → ℝ)
    (hF : ∀ x, HasDerivAt F (2 * x * g x) x) (hG : ∀ x, HasDerivAt G (2 * (1 - x) * g x) x) :
    (∫ x in (0:ℝ)..1, pluck x * g x) = (F (1 / 2) - F 0) + (G 1 - G (1 / 2)) := by
  have hc : Continuous (fun x => pluck x * g x) := pluck_continuous.mul hg
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := 1 / 2)
    (hc.intervalIntegrable _ _) (hc.intervalIntegrable _ _)]
  have e1 : (∫ x in (0:ℝ)..1 / 2, pluck x * g x) = ∫ x in (0:ℝ)..1 / 2, 2 * x * g x := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by norm_num)] at hx
    have hx2 : x ≤ 1 / 2 := hx.2
    simp only [pluck, hx2, ↓reduceIte]
  have e2 : (∫ x in (1 / 2 : ℝ)..1, pluck x * g x) = ∫ x in (1 / 2 : ℝ)..1, 2 * (1 - x) * g x := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by norm_num)] at hx
    simp only [pluck]
    split_ifs with h
    · have : x = 1 / 2 := le_antisymm h hx.1
      subst this; ring
    · rfl
  rw [e1, e2, intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hF x)
      ((by fun_prop : Continuous fun x => 2 * x * g x).intervalIntegrable _ _),
    intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hG x)
      ((by fun_prop : Continuous fun x => 2 * (1 - x) * g x).intervalIntegrable _ _)]

lemma pluck_sine (n : ℕ) (hn : 1 ≤ n) :
    halfSineCoeff 1 pluck n = 8 * Real.sin (n * π / 2) / (n ^ 2 * π ^ 2) := by
  set k : ℝ := n * π with hk
  have hk0 : k ≠ 0 := by
    have : (n : ℝ) ≠ 0 := by exact_mod_cast (by omega : n ≠ 0)
    exact mul_ne_zero this pi_ne_zero
  have hlin : ∀ x, HasDerivAt (fun x : ℝ => k * x) k x := fun x => by
    simpa using (hasDerivAt_id x).const_mul k
  have hI := pluck_integral (fun x => Real.sin (k * x)) (by fun_prop)
    (fun x => 2 * (-(x * Real.cos (k * x)) / k + Real.sin (k * x) / k ^ 2))
    (fun x => 2 * ((x - 1) * Real.cos (k * x) / k - Real.sin (k * x) / k ^ 2))
    (fun x => by
      have := (((((hasDerivAt_id' x).mul (hlin x).cos).neg).div_const k).add
        ((hlin x).sin.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
    (fun x => by
      have := (((((hasDerivAt_id' x).sub_const 1).mul (hlin x).cos).div_const k).sub
        ((hlin x).sin.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
  unfold halfSineCoeff
  simp only [div_one]
  rw [hI]
  have h1 : Real.sin (k * 1) = 0 := by rw [mul_one, hk, Real.sin_nat_mul_pi]
  have h2 : k * (1 / 2) = n * π / 2 := by rw [hk]; ring
  simp only [h1, h2, mul_zero, Real.sin_zero, Real.cos_zero]
  rw [hk]
  field_simp
  ring

lemma pluck_cosine (n : ℕ) (hn : 1 ≤ n) :
    halfCosineCoeff 1 pluck n = 4 * (2 * Real.cos (n * π / 2) - 1 - (-1) ^ n) / (n ^ 2 * π ^ 2) := by
  set k : ℝ := n * π with hk
  have hk0 : k ≠ 0 := by
    have : (n : ℝ) ≠ 0 := by exact_mod_cast (by omega : n ≠ 0)
    exact mul_ne_zero this pi_ne_zero
  have hlin : ∀ x, HasDerivAt (fun x : ℝ => k * x) k x := fun x => by
    simpa using (hasDerivAt_id x).const_mul k
  have hI := pluck_integral (fun x => Real.cos (k * x)) (by fun_prop)
    (fun x => 2 * (x * Real.sin (k * x) / k + Real.cos (k * x) / k ^ 2))
    (fun x => 2 * (-((x - 1) * Real.sin (k * x)) / k - Real.cos (k * x) / k ^ 2))
    (fun x => by
      have := ((((hasDerivAt_id' x).mul (hlin x).sin).div_const k).add
        ((hlin x).cos.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
    (fun x => by
      have := ((((((hasDerivAt_id' x).sub_const 1).mul (hlin x).sin).neg).div_const k).sub
        ((hlin x).cos.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
  unfold halfCosineCoeff
  simp only [div_one]
  rw [hI]
  have h1 : Real.sin (k * 1) = 0 := by rw [mul_one, hk, Real.sin_nat_mul_pi]
  have h1' : Real.cos (k * 1) = (-1) ^ n := by rw [mul_one, hk, Real.cos_nat_mul_pi]
  have h2 : k * (1 / 2) = n * π / 2 := by rw [hk]; ring
  simp only [h1, h1', h2, mul_zero, Real.sin_zero, Real.cos_zero]
  rw [hk]
  field_simp
  ring

lemma pluck_cosine_zero : halfCosineCoeff 1 pluck 0 = 1 := by
  unfold halfCosineCoeff
  simp only [Nat.cast_zero, zero_mul, Real.cos_zero, mul_one, div_one]
  have hI := pluck_integral (fun _ => 1) continuous_const (fun x => x ^ 2) (fun x => 2 * x - x ^ 2)
    (fun x => by
      convert hasDerivAt_pow 2 x using 1; ring)
    (fun x => by
      convert ((hasDerivAt_id' x).const_mul 2).sub (hasDerivAt_pow 2 x) using 1
      norm_num; ring)
  simp only [mul_one] at hI
  rw [hI]; norm_num

lemma hasSum_odd_inv_sq : HasSum (fun k : ℕ => 1 / ((2 * k + 1 : ℕ) : ℝ) ^ 2) (π ^ 2 / 8) := by
  have hz := hasSum_zeta_two
  have he : HasSum (fun k : ℕ => (1 : ℝ) / ((2 * k : ℕ) : ℝ) ^ 2) (π ^ 2 / 24) := by
    have := hz.mul_left (1 / 4)
    convert this using 1
    · ext k; push_cast; ring
    · ring
  have ho : Summable (fun k : ℕ => (1 : ℝ) / ((2 * k + 1 : ℕ) : ℝ) ^ 2) :=
    hz.summable.comp_injective (f := fun n : ℕ => (1 : ℝ) / (n : ℝ) ^ 2)
      (i := fun k : ℕ => 2 * k + 1) (fun a b h => by simpa using h)
  have hs := HasSum.even_add_odd (f := fun n : ℕ => (1 : ℝ) / (n : ℝ) ^ 2) he ho.hasSum
  have := hs.unique hz
  convert ho.hasSum using 1
  linarith

lemma sin_odd_half (k : ℕ) : Real.sin (((2 * k + 1 : ℕ) : ℝ) * π / 2) = (-1) ^ k := by
  rw [show (((2 * k + 1 : ℕ) : ℝ)) * π / 2 = k * π + π / 2 by push_cast; ring,
    Real.sin_add_pi_div_two, Real.cos_nat_mul_pi]

lemma cos_odd_half (k : ℕ) : Real.cos (((2 * k + 1 : ℕ) : ℝ) * π / 2) = 0 := by
  rw [show (((2 * k + 1 : ℕ) : ℝ)) * π / 2 = k * π + π / 2 by push_cast; ring,
    Real.cos_add_pi_div_two, Real.sin_nat_mul_pi, neg_zero]

lemma neg_one_sq_pow (k : ℕ) : ((-1 : ℝ) ^ k) ^ 2 = 1 := by
  rw [← pow_mul, mul_comm, pow_mul]; norm_num

#print axioms intervalIntegrable_congr_Ioo
#print axioms integral_symm_split
#print axioms pluck_eq_min
#print axioms pluck_continuous
#print axioms pluck_integral
#print axioms pluck_sine
#print axioms pluck_cosine
#print axioms pluck_cosine_zero
#print axioms hasSum_odd_inv_sq
#print axioms sin_odd_half
#print axioms cos_odd_half
#print axioms neg_one_sq_pow

/-- **The reflection decides the modes, and each coefficient is twice the average of f times
its mode.** Let f be integrable on [0, L] with L > 0. Over one full period −L to L, the full
Fourier coefficients (1/L) ∫ F(x) cos(nπx/L) dx and (1/L) ∫ F(x) sin(nπx/L) dx behave so:
for the odd extension every cosine coefficient is 0 and every sine coefficient equals the
half-range b_n = (2/L) ∫₀ᴸ f(x) sin(nπx/L) dx; for the even extension every sine coefficient
is 0 and every cosine coefficient equals the half-range a_n = (2/L) ∫₀ᴸ f(x) cos(nπx/L) dx. -/
theorem half_range_coefficients_from_reflection (L : ℝ) (hL : 0 < L) (f : ℝ → ℝ)
    (hf : IntervalIntegrable f volume 0 L) (n : ℕ) :
    (1 / L) * (∫ x in (-L)..L, oddExt f x * Real.cos (n * π * x / L)) = 0 ∧
    (1 / L) * (∫ x in (-L)..L, oddExt f x * Real.sin (n * π * x / L)) = halfSineCoeff L f n ∧
    (1 / L) * (∫ x in (-L)..L, evenExt f x * Real.sin (n * π * x / L)) = 0 ∧
    (1 / L) * (∫ x in (-L)..L, evenExt f x * Real.cos (n * π * x / L)) = halfCosineCoeff L f n := by
  have hc : Continuous (fun x : ℝ => Real.cos (n * π * x / L)) := by fun_prop
  have hs : Continuous (fun x : ℝ => Real.sin (n * π * x / L)) := by fun_prop
  have hfc : IntervalIntegrable (fun x => f x * Real.cos (n * π * x / L)) volume 0 L :=
    hf.mul_continuousOn hc.continuousOn
  have hfs : IntervalIntegrable (fun x => f x * Real.sin (n * π * x / L)) volume 0 L :=
    hf.mul_continuousOn hs.continuousOn
  -- on (0, L): the extensions agree with f, reflected points see -f or f
  have pos : ∀ (E : ℝ → ℝ) (m : ℝ → ℝ), (E = oddExt f ∨ E = evenExt f) →
      Set.EqOn (fun x => f x * m x) (fun x => E x * m x) (Set.uIcc 0 L) := by
    intro E m hE x hx
    rw [Set.uIcc_of_le hL.le] at hx
    rcases hE with rfl | rfl <;> simp [oddExt, evenExt, hx.1]
  have negO : ∀ x ∈ Set.Ioc (0 : ℝ) L, oddExt f (-x) = -f x := by
    intro x hx; simp [oddExt, not_le.mpr (neg_neg_of_pos hx.1)]
  have negE : ∀ x ∈ Set.Ioc (0 : ℝ) L, evenExt f (-x) = f x := by
    intro x hx; simp [evenExt, not_le.mpr (neg_neg_of_pos hx.1)]
  have cneg : ∀ x : ℝ, Real.cos (n * π * -x / L) = Real.cos (n * π * x / L) := by
    intro x; rw [show (n:ℝ) * π * -x / L = -(n * π * x / L) by ring, Real.cos_neg]
  have sneg : ∀ x : ℝ, Real.sin (n * π * -x / L) = -Real.sin (n * π * x / L) := by
    intro x; rw [show (n:ℝ) * π * -x / L = -(n * π * x / L) by ring, Real.sin_neg]
  have ioo : Set.Ioo (0 : ℝ) L ⊆ Set.Ioc 0 L := Set.Ioo_subset_Ioc_self
  refine ⟨?_, ?_, ?_, ?_⟩
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfc
      (fun x hx => pos (oddExt f) (fun x => Real.cos (n * π * x / L)) (Or.inl rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfc.neg (g := fun x => -(f x * Real.cos (n * π * x / L)))
      (h := fun x => oddExt f (-x) * Real.cos (n * π * -x / L))
      (fun x hx => by simp only; rw [negO x (ioo hx), cneg]; ring)
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, oddExt f (-x) * Real.cos (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, -(f x * Real.cos (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negO x hx, cneg]; ring
    have e2 : (∫ x in (0:ℝ)..L, oddExt f x * Real.cos (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.cos (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.cos (n * π * x / L)) (Or.inl rfl))).symm
    rw [e1, e2, intervalIntegral.integral_neg]; ring
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfs
      (fun x hx => pos (oddExt f) (fun x => Real.sin (n * π * x / L)) (Or.inl rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfs (g := fun x => (f x * Real.sin (n * π * x / L)))
      (h := fun x => oddExt f (-x) * Real.sin (n * π * -x / L))
      (fun x hx => by simp only; rw [negO x (ioo hx), sneg]; ring)
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, oddExt f (-x) * Real.sin (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, (f x * Real.sin (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negO x hx, sneg]; ring
    have e2 : (∫ x in (0:ℝ)..L, oddExt f x * Real.sin (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.sin (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.sin (n * π * x / L)) (Or.inl rfl))).symm
    rw [e1, e2, halfSineCoeff]; ring
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfs
      (fun x hx => pos (evenExt f) (fun x => Real.sin (n * π * x / L)) (Or.inr rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfs.neg (g := fun x => -(f x * Real.sin (n * π * x / L)))
      (h := fun x => evenExt f (-x) * Real.sin (n * π * -x / L))
      (fun x hx => by simp only; rw [negE x (ioo hx), sneg]; ring)
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, evenExt f (-x) * Real.sin (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, -(f x * Real.sin (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negE x hx, sneg]; ring
    have e2 : (∫ x in (0:ℝ)..L, evenExt f x * Real.sin (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.sin (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.sin (n * π * x / L)) (Or.inr rfl))).symm
    rw [e1, e2, intervalIntegral.integral_neg]; ring
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfc
      (fun x hx => pos (evenExt f) (fun x => Real.cos (n * π * x / L)) (Or.inr rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfc (g := fun x => (f x * Real.cos (n * π * x / L)))
      (h := fun x => evenExt f (-x) * Real.cos (n * π * -x / L))
      (fun x hx => by simp only; rw [negE x (ioo hx), cneg])
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, evenExt f (-x) * Real.cos (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, (f x * Real.cos (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negE x hx, cneg]
    have e2 : (∫ x in (0:ℝ)..L, evenExt f x * Real.cos (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.cos (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.cos (n * π * x / L)) (Or.inr rfl))).symm
    rw [e1, e2, halfCosineCoeff]; ring

/-- **Sines fit ends held at zero; cosines fit sealed ends.** For any length L > 0, any
coefficients c_n and any number of modes N, the sine sum Σ c_n sin(nπx/L) is 0 at x = 0 and
at x = L, and the cosine sum Σ c_n cos(nπx/L) has slope 0 at x = 0 and at x = L. -/
theorem half_range_modes_fit_the_ends (L : ℝ) (hL : 0 < L) (c : ℕ → ℝ) (N : ℕ) :
    (∑ n ∈ Finset.range N, c n * Real.sin (n * π * 0 / L)) = 0 ∧
    (∑ n ∈ Finset.range N, c n * Real.sin (n * π * L / L)) = 0 ∧
    deriv (fun x => ∑ n ∈ Finset.range N, c n * Real.cos (n * π * x / L)) 0 = 0 ∧
    deriv (fun x => ∑ n ∈ Finset.range N, c n * Real.cos (n * π * x / L)) L = 0 := by
  have hd : ∀ x, HasDerivAt (fun x => ∑ n ∈ Finset.range N, c n * Real.cos (n * π * x / L))
      (∑ n ∈ Finset.range N, c n * (-Real.sin (n * π * x / L) * (n * π * 1 / L))) x := by
    intro x
    apply HasDerivAt.fun_sum
    intro n _
    exact ((((hasDerivAt_id x).const_mul ((n : ℝ) * π)).div_const L).cos).const_mul (c n)
  have hsin : ∀ n : ℕ, Real.sin (n * π * L / L) = 0 := by
    intro n
    rw [mul_div_assoc, div_self hL.ne', mul_one, Real.sin_nat_mul_pi]
  refine ⟨by simp, by simp [hsin], ?_, ?_⟩
  · rw [(hd 0).deriv]; simp
  · rw [(hd L).deriv]; simp [hsin]

/-- **The plucked triangle.** For the string of length 1 pulled to 1 at its middle, for every
n ≥ 1 the sine coefficient is b_n = 8 sin(nπ/2)/(n²π²) and the cosine coefficient is
a_n = 4(2cos(nπ/2) − 1 − (−1)^n)/(n²π²), and a_0 = 1. At the middle x = 1/2, the sine series
Σ b_n sin(nπ/2) adds up to the peak 1, and the cosine series a_0/2 + Σ a_n cos(nπ/2) adds up to
the same value 1. -/
theorem plucked_triangle_half_range_series :
    (∀ n : ℕ, 1 ≤ n →
        halfSineCoeff 1 pluck n = 8 * Real.sin (n * π / 2) / (n ^ 2 * π ^ 2)) ∧
    (∀ n : ℕ, 1 ≤ n →
        halfCosineCoeff 1 pluck n =
          4 * (2 * Real.cos (n * π / 2) - 1 - (-1) ^ n) / (n ^ 2 * π ^ 2)) ∧
    halfCosineCoeff 1 pluck 0 = 1 ∧
    HasSum (fun n : ℕ => halfSineCoeff 1 pluck n * Real.sin (n * π * (1 / 2) / 1))
      (pluck (1 / 2)) ∧
    HasSum (fun n : ℕ => halfCosineCoeff 1 pluck (n + 1) *
        Real.cos ((n + 1 : ℕ) * π * (1 / 2) / 1))
      (pluck (1 / 2) - halfCosineCoeff 1 pluck 0 / 2) := by
  have hp : pluck (1 / 2) = 1 := by norm_num [pluck]
  have hpi : π ≠ 0 := pi_ne_zero
  refine ⟨pluck_sine, pluck_cosine, pluck_cosine_zero, ?_, ?_⟩
  · rw [show pluck (1 / 2) = 0 + 1 by rw [hp]; norm_num]
    apply HasSum.even_add_odd
    · convert hasSum_zero with k
      rw [show ((2 * k : ℕ) : ℝ) * π * (1 / 2) / 1 = k * π by push_cast; ring,
        Real.sin_nat_mul_pi, mul_zero]
    · convert hasSum_odd_inv_sq.mul_left (8 / π ^ 2) using 1
      · ext k
        rw [pluck_sine _ (by omega),
          show ((2 * k + 1 : ℕ) : ℝ) * π * (1 / 2) / 1 = ((2 * k + 1 : ℕ) : ℝ) * π / 2 by ring,
          sin_odd_half]
        have h := neg_one_sq_pow k
        have hn : ((2 * k + 1 : ℕ) : ℝ) ≠ 0 := by positivity
        field_simp
        linear_combination h
      · field_simp
  · rw [show pluck (1 / 2) - halfCosineCoeff 1 pluck 0 / 2 = 0 + (1 / 2 + 0) by
      rw [hp, pluck_cosine_zero]; norm_num]
    apply HasSum.even_add_odd
    · convert hasSum_zero with k
      rw [show ((2 * k + 1 : ℕ) : ℝ) * π * (1 / 2) / 1 = ((2 * k + 1 : ℕ) : ℝ) * π / 2 by ring,
        cos_odd_half, mul_zero]
    · apply HasSum.even_add_odd
      · convert hasSum_odd_inv_sq.mul_left (4 / π ^ 2) using 1
        · ext j
          rw [pluck_cosine _ (by omega)]
          have hc : Real.cos (((2 * (2 * j) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1) = -1 := by
            rw [show ((2 * (2 * j) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1
              = ((2 * j + 1 : ℕ) : ℝ) * π by push_cast; ring, Real.cos_nat_mul_pi]
            rw [pow_succ, pow_mul]; norm_num
          have hc' : Real.cos (((2 * (2 * j) + 1 + 1 : ℕ) : ℝ) * π / 2) = -1 := by
            rw [← hc]; ring_nf
          have hpow : ((-1 : ℝ)) ^ (2 * (2 * j) + 1 + 1) = 1 := by
            rw [show 2 * (2 * j) + 1 + 1 = 2 * (2 * j + 1) by ring, pow_mul]; norm_num
          rw [hc, hc', hpow]
          have hn : ((2 * j + 1 : ℕ) : ℝ) ≠ 0 := by positivity
          push_cast
          field_simp
          ring
        · field_simp; ring
      · convert hasSum_zero with j
        rw [pluck_cosine _ (by omega)]
        have hc : Real.cos (((2 * (2 * j + 1) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1) = 1 := by
          rw [show ((2 * (2 * j + 1) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1
            = ((2 * (j + 1) : ℕ) : ℝ) * π by push_cast; ring, Real.cos_nat_mul_pi, pow_mul]
          norm_num
        have hc' : Real.cos (((2 * (2 * j + 1) + 1 + 1 : ℕ) : ℝ) * π / 2) = 1 := by
          rw [← hc]; ring_nf
        have hpow : ((-1 : ℝ)) ^ (2 * (2 * j + 1) + 1 + 1) = 1 := by
          rw [show 2 * (2 * j + 1) + 1 + 1 = 2 * (2 * j + 2) by ring, pow_mul]; norm_num
        rw [hc, hc', hpow]
        ring

-- a_0 is twice the triangle's area: 2 × (1/2 × 1 × 1) = 1, so the rod's average a_0/2 is 1/2.
example : (2 : ℚ) * (1 / 2 * 1 * 1) = 1 ∧ (1 : ℚ) / 2 = 1 / 2 := by norm_num
-- sin(nπ/2) runs 0, 1, 0, −1: it is nonzero exactly for odd n, so b_2, b_4, b_6 are 0.
example : ∀ n < 12, (([0, 1, 0, -1] : List ℤ).getD (n % 4) 0 ≠ 0 ↔ n % 2 = 1) := by decide
-- The cosine factor 2cos(nπ/2) − 1 − (−1)^n is nonzero exactly at n = 2, 6, 10.
example : ∀ n < 12,
    (2 * ([1, 0, -1, 0] : List ℤ).getD (n % 4) 0 - 1 - (-1) ^ n ≠ 0 ↔ n % 4 = 2) := by decide
-- At n = 2 the cosine factor times 4 is −16, so a_2 = −16/(4π²).
example : (4 : ℤ) * (2 * (-1) - 1 - (-1) ^ 2) = -16 := by norm_num
-- The bracket in the peak sums (8/π²)(1 + 1/9) and (8/π²)(1 + 1/9 + 1/25).
example : (1 : ℚ) + 1 / 9 = 10 / 9 ∧ (1 : ℚ) + 1 / 9 + 1 / 25 = 259 / 225 := by norm_num

#print axioms half_range_coefficients_from_reflection
#print axioms half_range_modes_fit_the_ends
#print axioms plucked_triangle_half_range_series
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'intervalIntegrable_congr_Ioo' depends on axioms: [propext, Classical.choice, Quot.sound]
'integral_symm_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'pluck_eq_min' depends on axioms: [propext, Classical.choice, Quot.sound]
'pluck_continuous' depends on axioms: [propext, Classical.choice, Quot.sound]
'pluck_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'pluck_sine' depends on axioms: [propext, Classical.choice, Quot.sound]
'pluck_cosine' depends on axioms: [propext, Classical.choice, Quot.sound]
'pluck_cosine_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'hasSum_odd_inv_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'sin_odd_half' depends on axioms: [propext, Classical.choice, Quot.sound]
'cos_odd_half' depends on axioms: [propext, Classical.choice, Quot.sound]
'neg_one_sq_pow' depends on axioms: [propext, Classical.choice, Quot.sound]
'half_range_coefficients_from_reflection' depends on axioms: [propext, Classical.choice, Quot.sound]
'half_range_modes_fit_the_ends' depends on axioms: [propext, Classical.choice, Quot.sound]
'plucked_triangle_half_range_series' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Swap the reflection.** Guess first: what do the sine integrals give with `even` in place of `odd` in road two? All 0, since an even function times a sine cancels; the first assert fails.
> - **Pluck at a quarter.** Guess first: move the peak of `f` to x = 0.25 m and read road two. Even modes appear, but modes 4, 8, 12 vanish: each rests exactly where the string was pulled.
> - **Lift to room temperature.** Guess first: add 20 to `f`. Road two moves, road one does not, and the first assert fails.

---

## The usual mistake

> [!warning]
> **Choosing sines or cosines by the look of the shape, not by the ends.** The triangle looks like a sine hump, yet it is a sine series on a pinned string and a cosine series in a sealed rod. Both equal it inside. They differ at the ends: once time runs, the wrong family lets heat leak or a pinned end move.
>
> - **Reading a0 as the average.** The average is a0/2. Taking a0 = 1 puts the rod's settled temperature at 1 °C above the room, twice the true 0.5000.

---

## Where you meet it in real life

- **A guitar string.** Plucked at the middle, it sounds no even harmonics: b2, b4 and b6 are 0.
- **A sealed rod or lagged pipe (one wrapped in insulation).** The cosine series starts the heat calculation; the rod settles at a0/2.
- **JPEG images.** Each 8 × 8 pixel block is coded in cosines, the even reflection in discrete form: no jump at the edge, so most coefficients are tiny and dropped.

> **Say it back**
> A shape on 0 to L can be reflected into one that repeats every 2L. Flipped, it has only sines, zero at the ends: a pinned string. Mirrored, only cosines, flat at the ends: a sealed rod. Each coefficient is 2/L times the integral of the shape against its mode. The plucked triangle gets 8/(n^2π^2) on odd modes, signs alternating.

---

## What this builds on

- [Fourier series](01-fourier-series-and-orthogonality.md): the full-period series and its coefficients, which the reflection reuses.
- [Eigenvalue problems](../07-Series%20Solutions%20and%20Boundary%20Problems/08-eigenvalues-and-eigenfunctions.md): sines and cosines as the mode shapes that pinned and sealed ends allow.

## Where this goes next

- [Separation of variables](../10-The%20Classical%20PDEs/04-separation-of-variables-for-the-heat-equation.md): each mode here decays at its own rate once heat flows.
- Reflection: the two reflections solving waves on a half-line.
- The Gibbs overshoot and the cure: the overshoot beside an end not at zero, and how averaging tames it.

The question this card leaves open: once the string is released or the rod starts to cool, how does each mode change with time?

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Lebl, Jiří. *Notes on Diffy Qs: Differential Equations for Engineers*, §4.4 "Sine and cosine series". [Section page](https://www.jirka.org/diffyqs/html/sec_scs.html). Extensions, half-range formulas, boundary problems.
- Strauss, Walter A. *Partial Differential Equations: An Introduction*, 2nd ed. Wiley, 2008. [Publisher page](https://www.wiley.com/en-us/Partial+Differential+Equations%3A+An+Introduction%2C+2nd+Edition-p-9780470054567). Chapter 5: sine and cosine series from Dirichlet and Neumann ends, and the extensions.
