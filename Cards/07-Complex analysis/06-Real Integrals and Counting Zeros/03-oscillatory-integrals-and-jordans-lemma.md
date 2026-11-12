# Jordan's lemma: with an e to the iax factor the big arc still vanishes, so cosine integrals fall to residues

[Syllabus](../../../SYLLABUS.md) → [Complex analysis](../README.md) → [Real Integrals and Counting Zeros](../README.md#s06) → Jordan's lemma

---

## General Overview

A radio receiver meets a click: a voltage pulse shaped like 1/(1 + x^2), with x the time in microseconds from the peak. A filter tuned to frequency a, in radians per microsecond, measures how much of that tone the click holds: the integral of the pulse times cos(ax) over all time.

At a = 1 that integral is 1.155727. At a = 0 it is π, the area under the pulse, found on [The semicircle contour](01-semicircle-contours.md). In general it is π e^(−|a|): the click's content falls off exponentially with frequency, the same on both sides of zero.

Two obstacles block the semicircle method. First, cos z is huge off the real line. The fix is to write cos(ax) as the real part of e^(iax), a wave that shrinks as it rises into the upper half-plane. Second, for a slower-falling partner such as x/(1 + x^2), the length-times-maximum bound no longer kills the arc. Jordan's lemma does: the wave's decay over most of the arc is worth a whole factor of R.

**Replace the cosine by e^(iax), close the real line with an arc in the half-plane where that wave decays, and the arc vanishes whenever the rest of the integrand shrinks to zero there, however slowly; the integral is then the residues' contribution.**

**What kind of fact this is:** a theorem, proved on this card in Why it works from the inequality sin t ≥ 2t/π.

### The picture: the click's content at each frequency

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Integral of cos(ax)/(1 + x^2) over all time"
    x-axis "Frequency a, radians per microsecond" ["-3", "-2.5", "-2", "-1.5", "-1", "-0.5", "0", "0.5", "1", "1.5", "2", "2.5", "3"]
    y-axis "Content of that frequency" 0 --> 3.5
    line [0.16, 0.26, 0.43, 0.70, 1.16, 1.91, 3.14, 1.91, 1.16, 0.70, 0.43, 0.26, 0.16]
```

One line: π e^(−|a|), to two decimals. The peak at a = 0 is π, the pulse's area; the corner there comes from the |a|.

---

## The formula

A reminder from [Euler's formula](../01-Complex%20Numbers%20and%20the%20Plane/04-eulers-formula.md): e^(iθ) = cos θ + i sin θ, so on the real line cos(ax) is the real part of e^(iax). Off the line, at z = x + iy, the size of e^(iaz) is e^(−ay): for a > 0 it shrinks as y grows.

**Jordan's lemma.** Let $a > 0$. Let $C_R$ be the upper half-circle of radius R about 0, and let $M_R$ be the largest size on it of a continuous function g. Then

$$\left|\int_{C_R} g(z)\,e^{iaz}\,dz\right| \le \frac{\pi}{a}\,M_R.$$

**Read it aloud:** on the upper arc, the wave's decay makes the integral no bigger than π over a times g's largest size there; the arc's length R has cancelled.

So if $M_R \to 0$, the arc vanishes. The ML bound (arc length πR times $M_R$) needs $M_R$ to fall faster than 1/R.

Applied to the click, with the one pole i above the axis:

$$\int_{-\infty}^{\infty} \frac{\cos ax}{1 + x^2}\,dx = \operatorname{Re}\left[2\pi i\,\operatorname{Res}\!\left(\frac{e^{iaz}}{1 + z^2},\, i\right)\right] = \pi e^{-a}, \qquad a > 0.$$

**Read it aloud:** the cosine integral is the real part of 2πi times the residue of the wave-times-pulse at i, which is π e^(−a).

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$, $z$ | time in microseconds; a point x + iy of the plane | the real line, then the half-plane above | — |
| $y$ | height above the real axis, Im z | R sin t on the arc | e^(iaz) shrinks as e^(−ay) |
| $a$ | frequency, radians per microsecond | 1 | the content falls as e^(−a) |
| $g$ | the part of the integrand that does not oscillate | 1/(1 + z^2); then z/(1 + z^2) | — |
| $R$, $C_R$, $t$ | the arc's radius; the arc z = Re^(it); its angle, 0 to π | R = 2, 4, 8, 16 | the arc shrinks |
| $M_R$ | g's largest size on the arc | at most R/(R^2 − 1) for z/(1 + z^2) | a bigger arc bound |
| $\operatorname{Res}$ | the residue: coefficient of 1/(z − i) near the pole | −0.183940i | — |
| $i$, $\pi$, $e$ | the quarter turn, i^2 = −1; the half-turn; the base of natural logs | pole at i | — |

### When it holds

- **a > 0, arc above.** For a < 0 the wave grows upward: at a = −1 the upper arc at R = 8 carries 7.354818. Close below, clockwise.
- **g shrinks on the arc, at any rate.** With g = 1 the arc is −2 sin(aR)/a, which swings for ever: −1.978717 at R = 8, 0.575807 at R = 16.
- **e^(iax) in the loop, never cos(az).** Take the real part after integrating; this is valid because g is real on the real line.
- **No pole on the real line.** Otherwise see [Poles on the path](04-indented-contours-and-principal-values.md).

---

## Why it works

### Step 0: trade the cosine for a wave that decays upward

cos z = (e^(iz) + e^(−iz))/2. At z = iy the second term is e^(y)/2, enormous far up, so no upper arc can vanish with it on board. The wave e^(iaz) alone has size e^(−ay): at most 1, and tiny high up. Integrate e^(iax) g(x) and take the real part at the end.

### Step 1: close the loop and price it

Close the segment from −R to R with the upper arc, as on [The semicircle contour](01-semicircle-contours.md). For the click, e^(iaz)/(1 + z^2) = e^(iaz)/((z − i)(z + i)). The residue at i is the rest evaluated at i: e^(ia·i)/(2i) = e^(−a)/(2i). At a = 1 that is −0.183940i. The loop is worth 2πi e^(−a)/(2i) = π e^(−a) = 1.155727, for every R > 1.

### Step 2: bound the arc, point by point

On the arc z = Re^(it), so y = R sin t and the step |dz| = R dt. Then

$$\left|\int_{C_R} g\,e^{iaz}\,dz\right| \le \int_0^\pi M_R\, e^{-aR\sin t}\, R\,dt = M_R R \int_0^\pi e^{-aR\sin t}\,dt.$$

ML would replace e^(−aR sin t) by its largest value, 1, throwing the decay away. The wave is near size 1 only at the arc's ends; elsewhere it is tiny.

### Step 3: the sine lies above its chord

On 0 ≤ t ≤ π/2 the sine bends downward (its second derivative, −sin t, is not positive), so it lies above its chord from (0, 0) to (π/2, 1): sin t ≥ 2t/π.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The sine curve above its chord, 0 to pi/2"
    x-axis "Angle t, radians" ["0", "π/12", "π/6", "π/4", "π/3", "5π/12", "π/2"]
    y-axis "Height" 0 --> 1
    line [0.00, 0.26, 0.50, 0.71, 0.87, 0.97, 1.00]
    line [0.00, 0.17, 0.33, 0.50, 0.67, 0.83, 1.00]
```

The upper line is sin t; the lower is the chord 2t/π. They meet only at the ends.

### Step 4: integrate the easier exponential

By symmetry about t = π/2, the integral to π is twice the one to π/2. There sin t ≥ 2t/π gives e^(−aR sin t) ≤ e^(−2aRt/π), which integrates exactly:

$$\int_0^\pi e^{-aR\sin t}\,dt \le 2\int_0^{\pi/2} e^{-2aRt/\pi}\,dt = \frac{\pi}{aR}\left(1 - e^{-aR}\right) < \frac{\pi}{aR}.$$

Multiply by $M_R R$ from Step 2: the R cancels, leaving π$M_R$/a. That is Jordan's lemma. At aR = 8 the integral is 0.254724 against the bound 0.392699.

### Step 5: let R grow

For the click, $M_R$ ≤ 1/(R^2 − 1), so even ML suffices, and the real part gives π e^(−a).

Jordan earns its keep on the tilted pulse z e^(iaz)/(1 + z^2), where $M_R$ ≤ R/(R^2 − 1) falls only like 1/R. ML gives about π for every R, 3.153913 at R = 16. Jordan gives πR/(a(R^2 − 1)), 0.197120 at R = 16, tending to 0. The residue at i is e^(−a)/2, so the loop is πi e^(−a), and its imaginary part is the sine integral:

$$\int_{-\infty}^{\infty} \frac{x \sin ax}{1 + x^2}\,dx = \pi e^{-a} = 1.155727 \text{ at } a = 1.$$

<details>
<summary>Detailed proof: from the loop to the improper integral</summary>

Fix a > 0; let g = p/q, q with no real zeros, degree of q at least degree of p plus 1. As on the semicircle card, |g(z)| ≤ C/|z| for large |z|, so $M_R$ ≤ C/R → 0.

For R beyond every pole, segment plus arc equals 2πi times the residues of g e^(iaz) above the axis. By Jordan the arc is at most πC/(aR), so the segment tends to the residue sum.

That limit is symmetric, −R to R together. When the degrees differ by exactly 1, each tail converges only through cancellation: on [R, S], integrating by parts with e^(iax) = d(e^(iax))/(ia) leaves boundary terms at most 2C/(aR) plus the integral of |g′|/a, which is at most 2C/(aR) once g is monotone for large x. So each tail converges and the symmetric limit is the improper integral. For a < 0 use the lower arc, clockwise.

</details>

A second road needs no complex numbers: Simpson's rule on cos(x)/(1 + x^2) from 0 to L, plus the tail beyond L from integrating by parts twice. It is off by 8.5e-06 at L = 25 and 4.0e-10 at L = 400.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Pole inside | 1 + z^2 = (z − i)(z + i) | i |
| Residue at i | e^(i·i)/(2i) = e^(−1)/(2i) | −0.183940i |
| Loop value | 2πi × e^(−1)/(2i) = π e^(−1) | 1.155727 |
| Check at R = 4 | segment 1.108700 + arc 0.047027 | 1.155727 |
| Jordan bound, tilted pulse, R = 16 | π × 16/(1 × 255) | 0.197120 |
| Real part | cosine integral at a = 1 | **1.155727** |

A filter tuned to 1 radian per microsecond picks up 1.155727 from the click: a share e^(−1) of the 3.14 it would catch at zero frequency.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| cos(az) kept in the loop | 4.847731 (π cosh 1); arc at R = 8 still 3.662814 | e^(−iz) inside cos z grows upward; the arc never fades |
| a = −1 closed upward | 8.539734 (π e) | e^(−iz) grows upward; close below for a < 0 |
| g = 1, which does not shrink | arc −1.978717 at R = 8, 0.575807 at R = 16 | Jordan needs $M_R$ → 0 |
| Real part taken for the sine integral | 0 | x sin(ax) is the imaginary part of x e^(iax) |

---

## Code, from first principles, and it actually runs

Both programs reach 1.155727 by three roads: 2πi times the residue; the real line alone, by Simpson's rule plus a tail; and segment plus arc at R = 4. The four asserts: at every radius the wave's arc integral stays under π/(aR) and the tilted arc under Jordan's bound; road two matches π e^(−|a|) at all twelve nonzero chart frequencies; the closed loops match the residues; sin t ≥ 2t/π at 1001 points.

### Python

```python
# Jordan's lemma -- the check behind the card.  Standard library only.
# The Cauchy pulse 1/(1+x^2): its frequency content at a is the integral of
# cos(ax)/(1+x^2) over the real line, claimed to be pi e^(-|a|).
# Road 1: 2 pi i x residue at i.  Road 2: the real line only, Simpson plus a tail.
# Road 3: segment plus upper arc at finite R, each a trapezoid sum.
import math

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def cexp(w): return math.exp(w.real) * complex(math.cos(w.imag), math.sin(w.imag))
def trap(g, lo, hi, n=40000):                 # trapezoid sum of g from lo to hi
    h = (hi - lo) / n
    return h * (sum(g(lo + j * h) for j in range(1, n)) + (g(lo) + g(hi)) / 2)
def arc(g, R):                                # z = R e^(it), dz = i z dt, t from 0 to pi
    return trap(lambda t: g(R * cexp(1j * t)) * 1j * R * cexp(1j * t), 0, math.pi)
def real_line(a, L=400.0, n=40000):           # road 2: 2 x (Simpson on [0, L] + tail by parts)
    h = L / n
    s = sum((1 if j in (0, n) else 4 if j % 2 else 2) * math.cos(a * j * h) / (1 + (j * h) ** 2) for j in range(n + 1))
    tail = -math.sin(a * L) / (a * (1 + L * L)) + 2 * L * math.cos(a * L) / (a * a * (1 + L * L) ** 2)
    return 2 * (s * h / 3 + tail)

a = 1.0
pulse = lambda z: cexp(1j * a * z) / (1 + z * z)        # e^(iaz)/(1+z^2)
tilted = lambda z: z * cexp(1j * a * z) / (1 + z * z)   # degree gap 1: needs Jordan
res = cexp(1j * a * 1j) / (2j)                          # (z - i) x pulse, at z = i
road1 = 2j * math.pi * res
print(f"pulse, a = {a:g}: residue at i {show(res)}; road 1, 2 pi i x residue: {show(road1)}")
r2 = {L: real_line(a, L, int(100 * L)) for L in (25, 100, 400)}
print("road 2, real line to L plus tail: " + "; ".join(f"L = {L}: {v:.6f} (off {abs(v - road1.real):.1e})" for L, v in r2.items()))
seg, arc4 = trap(lambda x: pulse(complex(x, 0)), -4, 4), arc(pulse, 4)
print(f"road 3, R = 4: segment {show(seg)} + arc {show(arc4)} = {show(seg + arc4)}")
for R in (2, 4, 8, 16):
    J, ta = trap(lambda t: math.exp(-a * R * math.sin(t)), 0, math.pi), abs(arc(tilted, R))
    ml, jb = math.pi * R * R / (R * R - 1), math.pi * R / (a * (R * R - 1))
    print(f"R = {R}: e^(-aR sin t) summed {J:.6f} < pi/(aR) {math.pi / (a * R):.6f}; tilted arc {ta:.6f}, ML {ml:.6f}, Jordan {jb:.6f}")
    assert J < math.pi / (a * R) and ta <= jb
res_t = 1j * cexp(1j * a * 1j) / (2j)                   # (z - i) x tilted, at z = i
closed16 = trap(lambda x: tilted(complex(x, 0)), -16, 16) + arc(tilted, 16)
print(f"tilted, x e^(iax)/(1+x^2): 2 pi i x residue {show(2j * math.pi * res_t)}; R = 16 closed {show(closed16)}")
freqs = [k / 2 for k in range(-6, 7)]
print("chart, pi e^(-|a|) at a = -3 to 3 by 0.5: " + ", ".join(f"{math.pi * math.exp(-abs(f)):.2f}" for f in freqs))
ts = [k * math.pi / 12 for k in range(7)]
print("chart, t = k pi/12: sin t " + ", ".join(f"{math.sin(t):.2f}" for t in ts) + "; 2t/pi " + ", ".join(f"{2 * t / math.pi:.2f}" for t in ts))
cosk = lambda z: (cexp(1j * z) + cexp(-1j * z)) / 2 / (1 + z * z)
print(f"mistake, cos(az) kept: loop gives {show(2j * math.pi * (cexp(-1) + cexp(1)) / 2 / 2j)}; its arc at R = 8 {show(arc(cosk, 8))}")
neg = lambda z: cexp(-1j * z) / (1 + z * z)
print(f"mistake, a = -1 closed upward: 2 pi i x residue {show(2j * math.pi * cexp(1) / 2j)}; arc at R = 8 {show(arc(neg, 8))}")
flat = lambda z: cexp(1j * a * z)
print(f"mistake, g = 1 does not shrink: arc at R = 8 {show(arc(flat, 8))}, at R = 16 {show(arc(flat, 16))}")
print(f"mistake, real part taken for the sine integral: {(2j * math.pi * res_t).real:.6f}")
assert all(abs(real_line(f) - math.pi * math.exp(-abs(f))) < 1e-7 for f in freqs if f != 0)
assert abs(seg + arc4 - road1) < 1e-7 and abs(closed16 - 2j * math.pi * res_t) < 1e-6
assert all(math.sin(k * math.pi / 2000) >= k / 1000 - 1e-15 for k in range(1001))
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
pulse, a = 1: residue at i 0.000000 - 0.183940i; road 1, 2 pi i x residue: 1.155727 + 0.000000i
road 2, real line to L plus tail: L = 25: 1.155736 (off 8.5e-06); L = 100: 1.155727 (off 6.5e-08); L = 400: 1.155727 (off 4.0e-10)
road 3, R = 4: segment 1.108700 + 0.000000i + arc 0.047027 + 0.000000i = 1.155727 + 0.000000i
R = 2: e^(-aR sin t) summed 1.074901 < pi/(aR) 1.570796; tilted arc 0.110617, ML 4.188790, Jordan 2.094395
R = 4: e^(-aR sin t) summed 0.536809 < pi/(aR) 0.785398; tilted arc 0.352688, ML 3.351032, Jordan 0.837758
R = 8: e^(-aR sin t) summed 0.254724 < pi/(aR) 0.392699; tilted arc 0.007425, ML 3.191459, Jordan 0.398932
R = 16: e^(-aR sin t) summed 0.125508 < pi/(aR) 0.196350; tilted arc 0.120541, ML 3.153913, Jordan 0.197120
tilted, x e^(iax)/(1+x^2): 2 pi i x residue 0.000000 + 1.155727i; R = 16 closed 0.000000 + 1.155727i
chart, pi e^(-|a|) at a = -3 to 3 by 0.5: 0.16, 0.26, 0.43, 0.70, 1.16, 1.91, 3.14, 1.91, 1.16, 0.70, 0.43, 0.26, 0.16
chart, t = k pi/12: sin t 0.00, 0.26, 0.50, 0.71, 0.87, 0.97, 1.00; 2t/pi 0.00, 0.17, 0.33, 0.50, 0.67, 0.83, 1.00
mistake, cos(az) kept: loop gives 4.847731 + 0.000000i; its arc at R = 8 3.662814 + 0.000000i
mistake, a = -1 closed upward: 2 pi i x residue 8.539734 + 0.000000i; arc at R = 8 7.354818 + 0.000000i
mistake, g = 1 does not shrink: arc at R = 8 -1.978717 + 0.000000i, at R = 16 0.575807 + 0.000000i
mistake, real part taken for the sine integral: 0.000000
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Jordan's lemma -- the same check as the Python, in Rust.  No crates.
// The Cauchy pulse 1/(1+x^2): its frequency content at a is the integral of
// cos(ax)/(1+x^2) over the real line, claimed to be pi e^(-|a|).
// Road 1: 2 pi i x residue at i.  Road 2: the real line only, Simpson plus a tail.
// Road 3: segment plus upper arc at finite R, each a trapezoid sum.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(w: C) -> C { scale(c(w.im.cos(), w.im.sin()), w.re.exp()) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn trap(g: &dyn Fn(f64) -> C, lo: f64, hi: f64) -> C { // trapezoid sum of g from lo to hi
    let (n, h) = (40000, (hi - lo) / 40000.0);
    let mut s = scale(add(g(lo), g(hi)), 0.5);
    for j in 1..n { s = add(s, g(lo + j as f64 * h)) }
    scale(s, h)
}
fn arc(g: &dyn Fn(C) -> C, r: f64) -> C { // z = R e^(it), dz = i z dt, t from 0 to pi
    trap(&|t: f64| { let z = c(r * t.cos(), r * t.sin()); mul(g(z), mul(c(0.0, 1.0), z)) }, 0.0, PI)
}
fn real_line(a: f64, l: f64, n: usize) -> f64 { // road 2: 2 x (Simpson on [0, L] + tail by parts)
    let h = l / n as f64;
    let s: f64 = (0..=n).map(|j| { let x = j as f64 * h; let w = if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
        w * (a * x).cos() / (1.0 + x * x) }).sum();
    let tail = -(a * l).sin() / (a * (1.0 + l * l)) + 2.0 * l * (a * l).cos() / (a * a * (1.0 + l * l).powi(2));
    2.0 * (s * h / 3.0 + tail)
}
fn main() {
    let a = 1.0;
    let one = c(1.0, 0.0);
    let pulse = move |z: C| div(cexp(mul(c(0.0, a), z)), add(one, mul(z, z))); // e^(iaz)/(1+z^2)
    let tilted = move |z: C| mul(z, pulse(z)); // degree gap 1: needs Jordan
    let res = div(cexp(c(-a, 0.0)), c(0.0, 2.0)); // (z - i) x pulse, at z = i
    let road1 = mul(c(0.0, 2.0 * PI), res);
    println!("pulse, a = {}: residue at i {}; road 1, 2 pi i x residue: {}", a, show(res), show(road1));
    let r2: Vec<String> = [25.0, 100.0, 400.0].iter().map(|&l: &f64| { let v = real_line(a, l, (100.0 * l) as usize);
        let (d, e) = ((v - road1.re).abs(), (v - road1.re).abs().log10().floor()); // '8.5e-06', as Python prints it
        format!("L = {}: {:.6} (off {:.1}e-{:02})", l, v, d / 10f64.powf(e), -e) }).collect();
    println!("road 2, real line to L plus tail: {}", r2.join("; "));
    let (seg, arc4) = (trap(&|x: f64| pulse(c(x, 0.0)), -4.0, 4.0), arc(&pulse, 4.0));
    println!("road 3, R = 4: segment {} + arc {} = {}", show(seg), show(arc4), show(add(seg, arc4)));
    for r in [2.0f64, 4.0, 8.0, 16.0] {
        let j = trap(&|t: f64| c((-a * r * t.sin()).exp(), 0.0), 0.0, PI).re;
        let (ta, ml, jb) = (abs(arc(&tilted, r)), PI * r * r / (r * r - 1.0), PI * r / (a * (r * r - 1.0)));
        println!("R = {}: e^(-aR sin t) summed {:.6} < pi/(aR) {:.6}; tilted arc {:.6}, ML {:.6}, Jordan {:.6}", r, j, PI / (a * r), ta, ml, jb);
        assert!(j < PI / (a * r) && ta <= jb);
    }
    let road1_t = mul(c(0.0, 2.0 * PI), div(mul(c(0.0, 1.0), cexp(c(-a, 0.0))), c(0.0, 2.0))); // residue: (z - i) x tilted, at z = i
    let closed16 = add(trap(&|x: f64| tilted(c(x, 0.0)), -16.0, 16.0), arc(&tilted, 16.0));
    println!("tilted, x e^(iax)/(1+x^2): 2 pi i x residue {}; R = 16 closed {}", show(road1_t), show(closed16));
    let freqs: Vec<f64> = (-6..=6).map(|k| k as f64 / 2.0).collect();
    let fc: Vec<String> = freqs.iter().map(|f| format!("{:.2}", PI * (-f.abs()).exp())).collect();
    println!("chart, pi e^(-|a|) at a = -3 to 3 by 0.5: {}", fc.join(", "));
    let ts: Vec<f64> = (0..7).map(|k| k as f64 * PI / 12.0).collect();
    let st: Vec<String> = ts.iter().map(|t| format!("{:.2}", t.sin())).collect();
    let ch: Vec<String> = ts.iter().map(|t| format!("{:.2}", 2.0 * t / PI)).collect();
    println!("chart, t = k pi/12: sin t {}; 2t/pi {}", st.join(", "), ch.join(", "));
    let cosk = move |z: C| div(scale(add(cexp(mul(c(0.0, 1.0), z)), cexp(mul(c(0.0, -1.0), z))), 0.5), add(one, mul(z, z)));
    let cosh_loop = scale(c(1.0f64.exp() + (-1.0f64).exp(), 0.0), PI / 2.0); // 2 pi i x cosh(1)/(2i)
    println!("mistake, cos(az) kept: loop gives {}; its arc at R = 8 {}", show(cosh_loop), show(arc(&cosk, 8.0)));
    let neg = move |z: C| div(cexp(mul(c(0.0, -1.0), z)), add(one, mul(z, z)));
    println!("mistake, a = -1 closed upward: 2 pi i x residue {}; arc at R = 8 {}", show(c(PI * 1.0f64.exp(), 0.0)), show(arc(&neg, 8.0)));
    let flat = move |z: C| cexp(mul(c(0.0, a), z));
    println!("mistake, g = 1 does not shrink: arc at R = 8 {}, at R = 16 {}", show(arc(&flat, 8.0)), show(arc(&flat, 16.0)));
    println!("mistake, real part taken for the sine integral: {:.6}", road1_t.re);
    assert!(freqs.iter().filter(|&&f| f != 0.0).all(|&f| (real_line(f, 400.0, 40000) - PI * (-f.abs()).exp()).abs() < 1e-7));
    assert!(abs(add(add(seg, arc4), scale(road1, -1.0))) < 1e-7 && abs(add(closed16, scale(road1_t, -1.0))) < 1e-6);
    assert!((0..=1000).all(|k| (k as f64 * PI / 2000.0).sin() >= k as f64 / 1000.0 - 1e-15));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
pulse, a = 1: residue at i 0.000000 - 0.183940i; road 1, 2 pi i x residue: 1.155727 + 0.000000i
road 2, real line to L plus tail: L = 25: 1.155736 (off 8.5e-06); L = 100: 1.155727 (off 6.5e-08); L = 400: 1.155727 (off 4.0e-10)
road 3, R = 4: segment 1.108700 + 0.000000i + arc 0.047027 + 0.000000i = 1.155727 + 0.000000i
R = 2: e^(-aR sin t) summed 1.074901 < pi/(aR) 1.570796; tilted arc 0.110617, ML 4.188790, Jordan 2.094395
R = 4: e^(-aR sin t) summed 0.536809 < pi/(aR) 0.785398; tilted arc 0.352688, ML 3.351032, Jordan 0.837758
R = 8: e^(-aR sin t) summed 0.254724 < pi/(aR) 0.392699; tilted arc 0.007425, ML 3.191459, Jordan 0.398932
R = 16: e^(-aR sin t) summed 0.125508 < pi/(aR) 0.196350; tilted arc 0.120541, ML 3.153913, Jordan 0.197120
tilted, x e^(iax)/(1+x^2): 2 pi i x residue 0.000000 + 1.155727i; R = 16 closed 0.000000 + 1.155727i
chart, pi e^(-|a|) at a = -3 to 3 by 0.5: 0.16, 0.26, 0.43, 0.70, 1.16, 1.91, 3.14, 1.91, 1.16, 0.70, 0.43, 0.26, 0.16
chart, t = k pi/12: sin t 0.00, 0.26, 0.50, 0.71, 0.87, 0.97, 1.00; 2t/pi 0.00, 0.17, 0.33, 0.50, 0.67, 0.83, 1.00
mistake, cos(az) kept: loop gives 4.847731 + 0.000000i; its arc at R = 8 3.662814 + 0.000000i
mistake, a = -1 closed upward: 2 pi i x residue 8.539734 + 0.000000i; arc at R = 8 7.354818 + 0.000000i
mistake, g = 1 does not shrink: arc at R = 8 -1.978717 + 0.000000i, at R = 16 0.575807 + 0.000000i
mistake, real part taken for the sine integral: 0.000000
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Jordan's lemma for every a > 0 and every radius, and both real-line integrals exactly.

- For a > 0 and any radius R, the arc integral of g e^(iaz) is at most π/a times $M_R$, or any larger bound.
- For every frequency a, the click's integral of cos(ax)/(1 + x^2) over the real line is π e^(−|a|).
- For a > 0, the tilted pulse's sine integral, x sin(ax)/(1 + x^2) from A to B, tends to π e^(−a) as A → −∞ and B → ∞ independently.
- The hand steps hold exactly: 1 + z^2 = (z − i)(z + i), the residue at i, the loop value, and Jordan's bound at R = 16.

Lean reaches both integrals without residues; the loop's residue price, the decimals, the charts and the mistakes table are left to the Python and Rust checks.

```lean
-- Jordan's lemma: for a > 0 the integral of g(z) e^(iaz) over the upper half-circle of radius R is at most π/a times the largest size of g on that arc, the click's cosine integral of cos(ax)/(1 + x²) over the real line is π e^(−|a|), and the tilted pulse's improper integral of x sin(ax)/(1 + x²) is π e^(−a) for a > 0.
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic

open Complex Filter Topology MeasureTheory

/-! Helper lemmas for the proofs below. -/

lemma jl_jordan_exp_integral_le (c : ℝ) (hc : 0 < c) :
    ∫ t in (0 : ℝ)..Real.pi, Real.exp (-(c * Real.sin t)) ≤ Real.pi / c := by
  have hpi := Real.pi_pos
  set k := 2 / Real.pi * c with hkdef
  have hk : 0 < k := by positivity
  have h1 : ∀ t ∈ Set.Icc (0 : ℝ) Real.pi, Real.exp (-(c * Real.sin t)) ≤
      Real.exp (-(k * t)) + Real.exp (-(k * (Real.pi - t))) := by
    intro t ht
    rcases le_total t (Real.pi / 2) with h | h
    · have := Real.mul_le_sin ht.1 h
      have : k * t ≤ c * Real.sin t := by
        rw [hkdef]; nlinarith
      have := Real.exp_le_exp.mpr (neg_le_neg this)
      have := Real.exp_pos (-(k * (Real.pi - t)))
      linarith
    · have := Real.mul_le_sin (x := Real.pi - t) (by linarith [ht.2]) (by linarith)
      rw [Real.sin_pi_sub] at this
      have : k * (Real.pi - t) ≤ c * Real.sin t := by
        rw [hkdef]; nlinarith
      have := Real.exp_le_exp.mpr (neg_le_neg this)
      have := Real.exp_pos (-(k * t))
      linarith
  have hint : ∀ u : ℝ, IntervalIntegrable (fun t => Real.exp (-(u * t))) volume 0 Real.pi :=
    fun u => (by fun_prop : Continuous fun t => Real.exp (-(u * t))).intervalIntegrable _ _
  have hE : ∫ t in (0 : ℝ)..Real.pi, Real.exp (-(k * t)) = (1 - Real.exp (-(k * Real.pi))) / k := by
    have := intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun t => -Real.exp (-k * t) / k) (f' := fun t => Real.exp (-k * t))
      (a := 0) (b := Real.pi) (fun x _ => by
        have h0 : HasDerivAt (fun t : ℝ => -k * t) (-k) x := by
          simpa using (hasDerivAt_id x).const_mul (-k)
        have := h0.exp.neg.div_const k
        convert this using 1
        field_simp) (by simpa [neg_mul] using hint k)
    simp only [neg_mul] at this
    rw [this]; field_simp; simp; ring
  calc ∫ t in (0 : ℝ)..Real.pi, Real.exp (-(c * Real.sin t))
      ≤ ∫ t in (0 : ℝ)..Real.pi, (Real.exp (-(k * t)) + Real.exp (-(k * (Real.pi - t)))) :=
        intervalIntegral.integral_mono_on hpi.le
          ((by fun_prop : Continuous fun t => Real.exp (-(c * Real.sin t))).intervalIntegrable _ _)
          ((by fun_prop : Continuous fun t =>
            Real.exp (-(k * t)) + Real.exp (-(k * (Real.pi - t)))).intervalIntegrable _ _) h1
    _ = 2 * ((1 - Real.exp (-(k * Real.pi))) / k) := by
        rw [intervalIntegral.integral_add (hint k)
          ((by fun_prop : Continuous fun t => Real.exp (-(k * (Real.pi - t)))).intervalIntegrable _ _),
          intervalIntegral.integral_comp_sub_left (fun t => Real.exp (-(k * t)))]
        simp only [sub_self, sub_zero]
        rw [hE]; ring
    _ ≤ Real.pi / c := by
        have := Real.exp_pos (-(k * Real.pi))
        have hkpi : k * Real.pi = 2 * c := by rw [hkdef]; field_simp
        rw [hkpi] at this ⊢
        have e : 2 * ((1 - Real.exp (-(2 * c))) / k) = Real.pi * (1 - Real.exp (-(2 * c))) / c := by
          rw [hkdef]; field_simp
        rw [e]
        apply div_le_div_of_nonneg_right _ hc.le
        nlinarith

#print axioms jl_jordan_exp_integral_le

lemma jl_integrable_exp_neg_abs : Integrable (fun v : ℝ => Real.exp (-|v|)) := by
  refine (integrable_inv_one_add_sq.const_mul 2).mono'
    (by fun_prop : Continuous fun v : ℝ => Real.exp (-|v|)).aestronglyMeasurable
    (Eventually.of_forall fun v => ?_)
  rw [Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
  have h := Real.quadratic_le_exp_of_nonneg (abs_nonneg v)
  have hv : v ^ 2 = |v| ^ 2 := (sq_abs v).symm
  rw [Real.exp_neg, ← div_eq_mul_inv, inv_eq_one_div, div_le_div_iff₀ (Real.exp_pos _) (by positivity)]
  nlinarith [abs_nonneg v]

#print axioms jl_integrable_exp_neg_abs

lemma jl_integrable_abs_mul_exp_neg_abs : Integrable (fun v : ℝ => |v| * Real.exp (-|v|)) := by
  refine (integrable_inv_one_add_sq.const_mul 27).mono'
    (by fun_prop : Continuous fun v : ℝ => |v| * Real.exp (-|v|)).aestronglyMeasurable
    (Eventually.of_forall fun v => ?_)
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  set t := |v| with ht
  have t0 : 0 ≤ t := abs_nonneg v
  have hv : v ^ 2 = t ^ 2 := (sq_abs v).symm
  have h := Real.add_one_le_exp (t / 3)
  have h3 : (t / 3 + 1) ^ 3 ≤ Real.exp t := by
    have : Real.exp t = Real.exp (t / 3) ^ 3 := by rw [← Real.exp_nat_mul]; ring_nf
    rw [this]; exact pow_le_pow_left₀ (by positivity) h 3
  rw [Real.exp_neg, hv, ← div_eq_mul_inv, ← div_eq_mul_inv, div_le_div_iff₀ (Real.exp_pos _) (by positivity)]
  nlinarith [sq_nonneg t, mul_nonneg t0 (sq_nonneg t)]

#print axioms jl_integrable_abs_mul_exp_neg_abs

lemma jl_integral_Ioi_exp (c : ℂ) (hc : c.re = -1) :
    ∫ v : ℝ in Set.Ioi 0, Complex.exp (c * v) = -1 / c := by
  rw [integral_exp_mul_complex_Ioi (by rw [hc]; norm_num) 0]; simp

#print axioms jl_integral_Ioi_exp

lemma jl_integral_Ioi_mul_exp (c : ℂ) (hc : c.re = -1) :
    ∫ v : ℝ in Set.Ioi 0, (v : ℂ) * Complex.exp (c * v) = 1 / c ^ 2 := by
  have hc0 : c ≠ 0 := by rintro rfl; simp at hc
  have hnorm : ∀ v : ℝ, ‖(v : ℂ) * Complex.exp (c * v)‖ = |v| * Real.exp (-v) := by
    intro v; rw [norm_mul, Complex.norm_exp]; simp [hc]
  have hnorm' : ∀ v : ℝ, ‖Complex.exp (c * v)‖ = Real.exp (-v) := by
    intro v; rw [Complex.norm_exp]; simp [hc]
  have hint : IntegrableOn (fun v : ℝ => (v : ℂ) * Complex.exp (c * v)) (Set.Ioi 0) := by
    have hg : IntegrableOn (fun v : ℝ => v * Real.exp (-v)) (Set.Ioi 0) := by
      have := Real.GammaIntegral_convergent (s := 2) two_pos
      refine this.congr_fun (fun v _ => ?_) measurableSet_Ioi
      norm_num [Real.rpow_one]; ring
    refine Integrable.mono' hg
      (by fun_prop : Continuous fun v : ℝ => (v : ℂ) * Complex.exp (c * v)).aestronglyMeasurable ?_
    refine (ae_restrict_iff' measurableSet_Ioi).mpr (Eventually.of_forall fun v hv => ?_)
    rw [hnorm, abs_of_pos hv]
  have hA : Tendsto (fun v : ℝ => (v : ℂ) * Complex.exp (c * v)) atTop (𝓝 0) := by
    rw [tendsto_zero_iff_norm_tendsto_zero]
    have hlim : Tendsto (fun v : ℝ => v * Real.exp (-v)) atTop (𝓝 0) := by
      simpa using Real.tendsto_pow_mul_exp_neg_atTop_nhds_zero 1
    refine hlim.congr' ?_
    filter_upwards [eventually_ge_atTop 0] with v hv
    rw [hnorm, abs_of_nonneg hv]
  have hB : Tendsto (fun v : ℝ => Complex.exp (c * v)) atTop (𝓝 0) := by
    rw [tendsto_zero_iff_norm_tendsto_zero]
    simpa [hnorm'] using Real.tendsto_exp_neg_atTop_nhds_zero
  have hF : Tendsto (fun v : ℝ => ((v : ℂ) / c - 1 / c ^ 2) * Complex.exp (c * v)) atTop (𝓝 0) := by
    have := (hA.const_mul (1 / c)).sub (hB.const_mul (1 / c ^ 2))
    simp only [mul_zero, sub_zero] at this
    refine this.congr (fun v => ?_)
    ring
  have := integral_Ioi_of_hasDerivAt_of_tendsto' (a := 0) (m := 0)
    (f := fun v : ℝ => ((v : ℂ) / c - 1 / c ^ 2) * Complex.exp (c * v))
    (f' := fun v : ℝ => (v : ℂ) * Complex.exp (c * v)) ?_ hint hF
  · rw [this]; simp
  · intro x _
    have h1 : HasDerivAt (fun v : ℝ => (v : ℂ)) 1 x := (hasDerivAt_id x).ofReal_comp
    have h2 : HasDerivAt (fun v : ℝ => c * (v : ℂ)) c x := by simpa using h1.const_mul c
    have := ((h1.div_const c).sub_const (1 / c ^ 2)).mul h2.cexp
    convert this using 1
    field_simp
    ring

#print axioms jl_integral_Ioi_mul_exp

lemma jl_split_line (F : ℝ → ℂ) (hF : Integrable F) :
    ∫ v, F v = (∫ v in Set.Ioi 0, F v) + ∫ v in Set.Ioi 0, F (-v) := by
  rw [← integral_add_compl (s := Set.Ioi (0 : ℝ)) measurableSet_Ioi hF, Set.compl_Ioi,
    integral_comp_neg_Ioi, neg_zero]

#print axioms jl_split_line

open scoped FourierTransform in
lemma jl_cos_formula (φ G : ℝ → ℝ) (hφc : Continuous φ) (hφi : Integrable φ) (hG : Integrable G)
    (hF : ∀ ξ, 𝓕 (fun v => (φ v : ℂ)) ξ = (G (2 * Real.pi * ξ) : ℂ)) (x : ℝ) :
    ∫ u, Real.cos (u * x) * G u = 2 * Real.pi * φ x := by
  have hpi : (2 * Real.pi) ≠ 0 := by positivity
  have h1 : Integrable (𝓕 (fun v => (φ v : ℂ))) := by
    rw [show 𝓕 (fun v => (φ v : ℂ)) = fun ξ => ((G (2 * Real.pi * ξ)) : ℂ) from funext hF]
    exact (hG.comp_mul_left' hpi).ofReal
  have h2 := (hφi.ofReal).fourierInv_fourier_eq h1
    (Complex.continuous_ofReal.comp hφc).continuousAt (v := x)
  rw [Real.fourierInv_eq'] at h2
  simp_rw [hF] at h2
  set H : ℝ → ℂ := fun u => Complex.exp (((u * x : ℝ) : ℂ) * I) * (G u : ℂ) with hHdef
  have h3 : (fun v : ℝ => Complex.exp (((2 * Real.pi * inner ℝ v x : ℝ) : ℂ) * I) •
      ((G (2 * Real.pi * v) : ℝ) : ℂ)) = fun v => H (2 * Real.pi * v) := by
    ext v
    simp only [hHdef, smul_eq_mul]
    congr 3
    simp
    ring
  rw [h3, Measure.integral_comp_mul_left] at h2
  have hH : Integrable H := by
    refine Integrable.mono' hG.norm
      (((by fun_prop : Continuous fun u : ℝ => Complex.exp (((u * x : ℝ) : ℂ) * I)).aestronglyMeasurable).mul
        hG.ofReal.aestronglyMeasurable) (Eventually.of_forall fun u => ?_)
    simp only [hHdef, norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul, Complex.norm_real]
    rfl
  have h4 : ∫ u, H u = ((2 * Real.pi * φ x : ℝ) : ℂ) := by
    rw [abs_inv, abs_of_pos (by positivity : (0 : ℝ) < 2 * Real.pi)] at h2
    have hpi' : (2 * (Real.pi : ℂ)) ≠ 0 := by exact_mod_cast hpi
    rw [Complex.real_smul] at h2
    push_cast at h2 ⊢
    rw [← h2]
    field_simp
  have h5 := integral_re hH
  rw [h4] at h5
  simp only [RCLike.re_to_complex, Complex.ofReal_re] at h5
  rw [← h5]
  refine integral_congr_ae (Eventually.of_forall fun u => ?_)
  simp only [hHdef, Complex.mul_re, Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im,
    Complex.ofReal_re, Complex.ofReal_im, mul_zero, sub_zero]

#print axioms jl_cos_formula

open scoped FourierTransform in
lemma jl_fourier_exp_neg_abs (ξ : ℝ) :
    𝓕 (fun v : ℝ => ((Real.exp (-|v|) : ℝ) : ℂ)) ξ =
      ((2 / (1 + (2 * Real.pi * ξ) ^ 2) : ℝ) : ℂ) := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  set ω : ℝ := 2 * Real.pi * ξ with hω
  set F : ℝ → ℂ := fun v => Complex.exp (((-2 * Real.pi * v * ξ : ℝ) : ℂ) * I) •
    ((Real.exp (-|v|) : ℝ) : ℂ) with hFdef
  have hF : Integrable F := by
    refine Integrable.mono' jl_integrable_exp_neg_abs
      (by fun_prop : Continuous F).aestronglyMeasurable (Eventually.of_forall fun v => ?_)
    refine le_of_eq ?_
    simp only [hFdef, smul_eq_mul, norm_mul, Complex.norm_exp_ofReal_mul_I, Complex.norm_real,
      Real.norm_eq_abs, one_mul]
    simp [abs_of_pos (Real.exp_pos _)]
  rw [jl_split_line F hF]
  have e1 : ∫ v in Set.Ioi 0, F v = ∫ v : ℝ in Set.Ioi 0, Complex.exp ((-1 - ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_of_pos (show (0 : ℝ) < v from hv), Complex.ofReal_exp,
      ← Complex.exp_add]
    congr 1; simp only [hω]; push_cast; ring
  have e2 : ∫ v in Set.Ioi 0, F (-v) = ∫ v : ℝ in Set.Ioi 0, Complex.exp ((-1 + ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_neg, abs_of_pos (show (0 : ℝ) < v from hv),
      Complex.ofReal_exp, ← Complex.exp_add]
    congr 1; simp only [hω]; push_cast; ring
  rw [e1, e2, jl_integral_Ioi_exp _ (by simp), jl_integral_Ioi_exp _ (by simp)]
  have h1 : (-1 - ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h2 : (-1 + ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h3 : (1 + (ω : ℂ) ^ 2) ≠ 0 := by exact_mod_cast (by positivity : (1 + ω ^ 2) ≠ 0)
  push_cast
  field_simp
  ring_nf
  simp only [I_sq]
  ring

#print axioms jl_fourier_exp_neg_abs

open scoped FourierTransform in
lemma jl_fourier_abs_mul_exp_neg_abs (ξ : ℝ) :
    𝓕 (fun v : ℝ => ((|v| * Real.exp (-|v|) : ℝ) : ℂ)) ξ =
      ((2 * (1 - (2 * Real.pi * ξ) ^ 2) / (1 + (2 * Real.pi * ξ) ^ 2) ^ 2 : ℝ) : ℂ) := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  set ω : ℝ := 2 * Real.pi * ξ with hω
  set F : ℝ → ℂ := fun v => Complex.exp (((-2 * Real.pi * v * ξ : ℝ) : ℂ) * I) •
    ((|v| * Real.exp (-|v|) : ℝ) : ℂ) with hFdef
  have hF : Integrable F := by
    refine Integrable.mono' jl_integrable_abs_mul_exp_neg_abs
      (by fun_prop : Continuous F).aestronglyMeasurable (Eventually.of_forall fun v => ?_)
    refine le_of_eq ?_
    simp only [hFdef, smul_eq_mul, norm_mul, Complex.norm_exp_ofReal_mul_I, Complex.norm_real,
      Real.norm_eq_abs, one_mul]
    simp [abs_of_pos (Real.exp_pos _)]
  rw [jl_split_line F hF]
  have e1 : ∫ v in Set.Ioi 0, F v =
      ∫ v : ℝ in Set.Ioi 0, (v : ℂ) * Complex.exp ((-1 - ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_of_pos (show (0 : ℝ) < v from hv), Complex.ofReal_mul,
      Complex.ofReal_exp]
    rw [mul_left_comm, ← Complex.exp_add]
    congr 2; simp only [hω]; push_cast; ring
  have e2 : ∫ v in Set.Ioi 0, F (-v) =
      ∫ v : ℝ in Set.Ioi 0, (v : ℂ) * Complex.exp ((-1 + ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_neg, abs_of_pos (show (0 : ℝ) < v from hv),
      Complex.ofReal_mul, Complex.ofReal_exp]
    rw [mul_left_comm, ← Complex.exp_add]
    congr 2; simp only [hω]; push_cast; ring
  rw [e1, e2, jl_integral_Ioi_mul_exp _ (by simp), jl_integral_Ioi_mul_exp _ (by simp)]
  have h1 : (-1 - ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h2 : (-1 + ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h3 : (1 + (ω : ℂ) ^ 2) ≠ 0 := by exact_mod_cast (by positivity : (1 + ω ^ 2) ≠ 0)
  have h4 : (-1 - ω * I) * (-1 + ω * I) = 1 + (ω : ℂ) ^ 2 := by
    ring_nf; simp only [I_sq]; ring
  push_cast
  field_simp
  ring_nf
  simp only [I_sq, I_pow_four]
  ring

#print axioms jl_fourier_abs_mul_exp_neg_abs

lemma jl_integrable_two_div : Integrable (fun u : ℝ => 2 / (1 + u ^ 2)) := by
  simpa [div_eq_mul_inv] using integrable_inv_one_add_sq.const_mul 2

#print axioms jl_integrable_two_div

lemma jl_integrable_G1 : Integrable (fun u : ℝ => 2 * (1 - u ^ 2) / (1 + u ^ 2) ^ 2) := by
  refine (integrable_inv_one_add_sq.const_mul 2).mono'
    ((by fun_prop : Continuous fun u : ℝ => 2 * (1 - u ^ 2)).div (by fun_prop)
      (fun u => by positivity)).aestronglyMeasurable
    (Eventually.of_forall fun u => ?_)
  have h1 : 0 < 1 + u ^ 2 := by positivity
  rw [Real.norm_eq_abs, abs_div, abs_of_pos (by positivity : (0 : ℝ) < (1 + u ^ 2) ^ 2),
    div_le_iff₀ (by positivity), abs_mul, abs_two]
  have : |1 - u ^ 2| ≤ 1 + u ^ 2 := abs_le.mpr ⟨by nlinarith [sq_nonneg u], by nlinarith [sq_nonneg u]⟩
  have e : 2 * (1 + u ^ 2)⁻¹ * (1 + u ^ 2) ^ 2 = 2 * (1 + u ^ 2) := by field_simp
  rw [e]; linarith

#print axioms jl_integrable_G1

lemma jl_cos_lorentz (x : ℝ) :
    ∫ u, Real.cos (u * x) * (2 / (1 + u ^ 2)) = 2 * Real.pi * Real.exp (-|x|) :=
  jl_cos_formula (fun v => Real.exp (-|v|)) (fun u => 2 / (1 + u ^ 2)) (by fun_prop)
    jl_integrable_exp_neg_abs jl_integrable_two_div jl_fourier_exp_neg_abs x

#print axioms jl_cos_lorentz

lemma jl_cos_G1 (x : ℝ) :
    ∫ u, Real.cos (u * x) * (2 * (1 - u ^ 2) / (1 + u ^ 2) ^ 2) =
      2 * Real.pi * (|x| * Real.exp (-|x|)) :=
  jl_cos_formula (fun v => |v| * Real.exp (-|v|)) (fun u => 2 * (1 - u ^ 2) / (1 + u ^ 2) ^ 2)
    (by fun_prop) jl_integrable_abs_mul_exp_neg_abs jl_integrable_G1
    jl_fourier_abs_mul_exp_neg_abs x

#print axioms jl_cos_G1

lemma jl_w_tendsto {l : Filter ℝ} (hl : Tendsto (fun x : ℝ => |x|) l atTop) :
    Tendsto (fun x : ℝ => x / (1 + x ^ 2)) l (𝓝 0) := by
  have h0 := tendsto_inv_atTop_zero.comp hl
  refine squeeze_zero_norm' ?_ h0
  filter_upwards [hl.eventually_gt_atTop 0] with x hx
  have h1 : 0 < 1 + x ^ 2 := by positivity
  rw [Real.norm_eq_abs, abs_div, abs_of_pos h1, div_le_iff₀ h1, Function.comp_apply,
    ← sq_abs x]
  rw [inv_mul_eq_div, le_div_iff₀ hx]
  nlinarith

#print axioms jl_w_tendsto

/-- Jordan's lemma. Let a > 0 and let C_R be the upper half-circle z = R e^(it), 0 ≤ t ≤ π, of
radius R > 0. Let g be continuous on that arc, and let M be at least g's size at every point of
the arc (for example M = M_R, g's largest size there). Then the integral of g(z) e^(iaz) dz along
the arc, with dz = i R e^(it) dt, has size at most (π / a) · M: the arc's length R has cancelled. -/
theorem jordans_lemma_upper_arc_bound (g : ℂ → ℂ) (a R M : ℝ) (ha : 0 < a) (hR : 0 < R)
    (hg : ContinuousOn g (Metric.sphere (0 : ℂ) R ∩ {z : ℂ | 0 ≤ z.im}))
    (hM : ∀ t ∈ Set.Icc (0 : ℝ) Real.pi, ‖g (R * Complex.exp (t * I))‖ ≤ M) :
    ‖∫ t in (0 : ℝ)..Real.pi,
        g (R * Complex.exp (t * I)) * Complex.exp (I * a * (R * Complex.exp (t * I))) *
          (I * R * Complex.exp (t * I))‖ ≤ Real.pi / a * M := by
  have hpi := Real.pi_pos
  have hM0 : 0 ≤ M := le_trans (norm_nonneg _) (hM 0 ⟨le_rfl, hpi.le⟩)
  have hb : ∀ t ∈ Set.Icc (0 : ℝ) Real.pi,
      ‖g (R * Complex.exp (t * I)) * Complex.exp (I * a * (R * Complex.exp (t * I))) *
          (I * R * Complex.exp (t * I))‖ ≤ M * R * Real.exp (-((a * R) * Real.sin t)) := by
    intro t ht
    rw [norm_mul, norm_mul, Complex.norm_exp]
    have e1 : (I * a * (R * Complex.exp (t * I))).re = -((a * R) * Real.sin t) := by
      simp [Complex.mul_re, Complex.mul_im, exp_ofReal_mul_I_re, exp_ofReal_mul_I_im]; ring
    have e2 : ‖I * R * Complex.exp (t * I)‖ = R := by
      rw [norm_mul, norm_mul, Complex.norm_exp_ofReal_mul_I]; simp [abs_of_pos hR]
    rw [e1, e2]
    have := hM t ht
    have := Real.exp_pos (-((a * R) * Real.sin t))
    calc ‖g (R * Complex.exp (t * I))‖ * Real.exp (-((a * R) * Real.sin t)) * R
        ≤ M * Real.exp (-((a * R) * Real.sin t)) * R := by gcongr
      _ = _ := by ring
  calc _ ≤ ∫ t in (0 : ℝ)..Real.pi, M * R * Real.exp (-((a * R) * Real.sin t)) :=
        intervalIntegral.norm_integral_le_of_norm_le hpi.le
          (Eventually.of_forall fun t ht => hb t ⟨ht.1.le, ht.2⟩)
          ((by fun_prop : Continuous fun t =>
            M * R * Real.exp (-((a * R) * Real.sin t))).intervalIntegrable _ _)
    _ = M * R * ∫ t in (0 : ℝ)..Real.pi, Real.exp (-((a * R) * Real.sin t)) :=
        intervalIntegral.integral_const_mul _ _
    _ ≤ M * R * (Real.pi / (a * R)) := by
        gcongr
        exact jl_jordan_exp_integral_le (a * R) (by positivity)
    _ = Real.pi / a * M := by field_simp

/-- The click's content at frequency a. For every real a, the integral over the whole real line
of cos(ax) / (1 + x²) is π e^(−|a|); at a = 0 this is π, the area under the pulse. -/
theorem integral_cos_mul_div_one_add_sq (a : ℝ) :
    ∫ x : ℝ, Real.cos (a * x) / (1 + x ^ 2) = Real.pi * Real.exp (-|a|) := by
  have h := jl_cos_lorentz a
  have e : (fun x : ℝ => Real.cos (a * x) / (1 + x ^ 2)) =
      fun x => (1 / 2) * (Real.cos (x * a) * (2 / (1 + x ^ 2))) := by
    ext x; rw [mul_comm a x]; field_simp
  rw [e, integral_const_mul, h]; ring

/-- The tilted pulse, where Jordan's lemma earns its keep. For a > 0, the integral of
x sin(ax) / (1 + x²) from A to B tends to π e^(−a) as A → −∞ and B → +∞ independently:
the improper integral over the whole real line exists and equals π e^(−a). -/
theorem tendsto_integral_mul_sin_div_one_add_sq (a : ℝ) (ha : 0 < a) :
    Tendsto (fun p : ℝ × ℝ => ∫ x in p.1..p.2, x * Real.sin (a * x) / (1 + x ^ 2))
      (atBot ×ˢ atTop) (𝓝 (Real.pi * Real.exp (-a))) := by
  have ha' : a ≠ 0 := ha.ne'
  set w : ℝ → ℝ := fun x => x / (1 + x ^ 2) with hw
  set K : ℝ → ℝ := fun x => Real.cos (x * a) * (2 * (1 - x ^ 2) / (1 + x ^ 2) ^ 2) with hKdef
  have hK : Integrable K :=
    jl_integrable_G1.bdd_mul (c := 1) (by fun_prop : Continuous fun x : ℝ => Real.cos (x * a)).aestronglyMeasurable
      (Eventually.of_forall fun x => by simpa using Real.abs_cos_le_one (x * a))
  have hKval : ∫ x, K x = 2 * Real.pi * (a * Real.exp (-a)) := by
    rw [hKdef, jl_cos_G1 a, abs_of_pos ha]
  have hibp : ∀ A B : ℝ, ∫ x in A..B, x * Real.sin (a * x) / (1 + x ^ 2) =
      w B * (-Real.cos (a * B) / a) - w A * (-Real.cos (a * A) / a) +
        1 / (2 * a) * ∫ x in A..B, K x := by
    intro A B
    have hd1 : ∀ x ∈ Set.uIcc A B, HasDerivAt w ((1 - x ^ 2) / (1 + x ^ 2) ^ 2) x := by
      intro x _
      have h1 : (1 + x ^ 2) ≠ 0 := by positivity
      have := (hasDerivAt_id x).div (((hasDerivAt_id x).pow 2).const_add 1) h1
      convert this using 1
      · ext y; simp [hw]
      · simp; field_simp; ring
    have hd2 : ∀ x ∈ Set.uIcc A B,
        HasDerivAt (fun x => -Real.cos (a * x) / a) (Real.sin (a * x)) x := by
      intro x _
      have h0 : HasDerivAt (fun x : ℝ => a * x) a x := by
        simpa using (hasDerivAt_id x).const_mul a
      have := ((Real.hasDerivAt_cos (a * x)).comp x h0).neg.div_const a
      convert this using 1
      · ext y; simp
      · field_simp
    have hi := intervalIntegral.integral_mul_deriv_eq_deriv_mul hd1 hd2
      (((by fun_prop : Continuous fun x : ℝ => 1 - x ^ 2).div (by fun_prop)
        (fun x => by positivity)).intervalIntegrable _ _)
      ((by fun_prop : Continuous fun x : ℝ => Real.sin (a * x)).intervalIntegrable _ _)
    have e1 : (∫ x in A..B, x * Real.sin (a * x) / (1 + x ^ 2)) =
        ∫ x in A..B, w x * Real.sin (a * x) := by
      refine intervalIntegral.integral_congr (fun x _ => ?_)
      simp only [hw]; ring
    have e2 : (∫ x in A..B, (1 - x ^ 2) / (1 + x ^ 2) ^ 2 * (-Real.cos (a * x) / a)) =
        -(1 / (2 * a)) * ∫ x in A..B, K x := by
      rw [← intervalIntegral.integral_const_mul]
      refine intervalIntegral.integral_congr (fun x _ => ?_)
      simp only [hKdef]
      rw [mul_comm x a]
      field_simp
    rw [e1, hi, e2]
    ring
  have hT1 : Tendsto (fun p : ℝ × ℝ => ∫ x in p.1..p.2, K x) (atBot ×ˢ atTop) (𝓝 (∫ x, K x)) :=
    intervalIntegral_tendsto_integral hK tendsto_fst tendsto_snd
  have hbd : ∀ {l : Filter (ℝ × ℝ)} {f : ℝ × ℝ → ℝ}, Tendsto (fun p => w (f p)) l (𝓝 0) →
      Tendsto (fun p => w (f p) * (-Real.cos (a * f p) / a)) l (𝓝 0) := by
    intro l f hf
    refine squeeze_zero_norm (a := fun p => ‖w (f p)‖ * (1 / a)) (fun p => ?_) ?_
    · rw [norm_mul]
      gcongr
      rw [Real.norm_eq_abs, abs_div, abs_neg, abs_of_pos ha]
      gcongr
      exact Real.abs_cos_le_one _
    · simpa using hf.norm.mul_const (1 / a)
  have hT2 := hbd (l := atBot ×ˢ atTop) (f := Prod.snd)
    ((jl_w_tendsto tendsto_abs_atTop_atTop).comp tendsto_snd)
  have hT3 := hbd (l := atBot ×ˢ atTop) (f := Prod.fst)
    ((jl_w_tendsto tendsto_abs_atBot_atTop).comp tendsto_fst)
  have hT := (hT2.sub hT3).add (hT1.const_mul (1 / (2 * a)))
  rw [hKval] at hT
  convert hT using 1
  · ext p; exact hibp p.1 p.2
  · congr 1; field_simp; ring

/-! The card's exact worked steps at a = 1. -/

-- The pole inside: 1 + z² = (z − i)(z + i).
example (z : ℂ) : 1 + z ^ 2 = (z - I) * (z + I) := by
  linear_combination I_sq

-- The residue at i: e^(i·i) / (2i) = −(e^(−1)/2) i.
example : Complex.exp (I * I) / (2 * I) = -((Real.exp (-1) / 2 : ℝ) : ℂ) * I := by
  rw [I_mul_I]; push_cast; field_simp; ring_nf; simp [I_sq]

-- The loop value: 2πi × e^(−1)/(2i) = π e^(−1).
example : 2 * (Real.pi : ℂ) * I * (Complex.exp (-1) / (2 * I)) =
    ((Real.pi * Real.exp (-1) : ℝ) : ℂ) := by
  push_cast; field_simp

-- Jordan's bound for the tilted pulse at R = 16, a = 1: π · 16 / (1 · (16² − 1)) = 16π/255.
example : Real.pi * 16 / (1 * (16 ^ 2 - 1)) = 16 * Real.pi / 255 := by
  ring

#print axioms jordans_lemma_upper_arc_bound
#print axioms integral_cos_mul_div_one_add_sq
#print axioms tendsto_integral_mul_sin_div_one_add_sq
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'jl_jordan_exp_integral_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_integrable_exp_neg_abs' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_integrable_abs_mul_exp_neg_abs' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_integral_Ioi_exp' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_integral_Ioi_mul_exp' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_split_line' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_cos_formula' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_fourier_exp_neg_abs' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_fourier_abs_mul_exp_neg_abs' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_integrable_two_div' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_integrable_G1' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_cos_lorentz' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_cos_G1' depends on axioms: [propext, Classical.choice, Quot.sound]
'jl_w_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'jordans_lemma_upper_arc_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'integral_cos_mul_div_one_add_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'tendsto_integral_mul_sin_div_one_add_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A higher tone.** Set `a = 2.0`. Guess: π e^(−2), about 0.43, the chart's value at a = 2. Every road moves there together, and all four asserts still pass.
> - **Take the wrong residue.** Change `/ (2j)` in the line defining `res` to `/ (1j)`. The loop value doubles; the second-to-last assert stops it.
> - **Throw away dz.** In `arc`, delete `1j * R * cexp(1j * t)` and its `*`. Road three misses; an assert stops it.

---

## The usual mistake

> [!warning]
> **Putting cos(az) into the contour.** Off the real line cos z contains e^(−iz), which grows upward. The loop is then worth π cosh 1 = 4.847731, and the arc at R = 8 still carries 3.662814. Use e^(iaz); take the real part at the end.
>
> - **Closing on the wrong side.** For a < 0 close below; the upper residue gives π e = 8.539734 at a = −1.
> - **Mixing real and imaginary parts.** The cosine integral is the real part, the sine integral the imaginary part.

---

## Where you meet it in real life

- **Spectral lines and filters.** A damped oscillation decaying like e^(−|t|) has the bell 1/(1 + x^2) as its spectrum, the Lorentzian line shape of atomic physics. This card runs the pair backwards: a bell-shaped click has exponential content in frequency.
- **The Fourier transform.** The integral of f(x) e^(iax), for every a at once, is [The Fourier transform](../08-Transforms%20in%20Outline/03-fourier-transform.md); Jordan's lemma fills its tables.
- **sin x / x.** The integral of sin x / x needs this lemma plus a detour round the pole at 0: [Poles on the path](04-indented-contours-and-principal-values.md).

> **Say it back**
> The cosine blows up off the real line, so write cos(ax) as the real part of e^(iax), which decays upward when a > 0. Close the real line with the upper arc and price the loop by its residues. Since sin t ≥ 2t/π, the arc is at most π/a times g's largest size there, so any g that shrinks at all loses its arc. For the click 1/(1 + x^2), the content at frequency a is π e^(−|a|), 1.155727 at a = 1.

---

## What this builds on

- [The semicircle contour](01-semicircle-contours.md): closing the real line with an upper arc, the ML bound, and the area π under 1/(1 + x^2).

## Where this goes next

- [Poles on the path](04-indented-contours-and-principal-values.md): a pole on the real line, as in sin x / x, dodged by a small half-circle.
- [The Fourier transform](../08-Transforms%20in%20Outline/03-fourier-transform.md): the same integral for every frequency, as one function.

For sin x / x the partner e^(iz)/z has its pole at 0, on the path itself; what a contour does then is the open question.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Stein, Elias M., and Rami Shakarchi. *Complex Analysis*. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113852/complex-analysis). Chapter 3 works the transform of 1/(1 + x^2) by residues.
- Orloff, Jeremy. "Topic 9: Definite integrals using the residue theorem." MIT OpenCourseWare 18.04, Spring 2018. [Course notes](https://ocw.mit.edu/courses/18-04-complex-variables-with-applications-spring-2018/resources/mit18_04s18_topic9/). Decay theorems for e^(iaz) integrands; cosines as real parts.
- Lebl, Jiří. *Guide to Cultivating Complex Analysis*. [Book page and free text](https://www.jirka.org/ca/). Residues and arc bounds.
