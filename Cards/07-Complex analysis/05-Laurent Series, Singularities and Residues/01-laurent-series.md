# Laurent series: allow negative powers, and a function with a hole expands in a ring

[Syllabus](../../../SYLLABUS.md) → [Complex analysis](../README.md) → [Laurent Series, Singularities and Residues](../README.md#s05) → Laurent series

---

## General Overview

The function f(z) = 1/(z(z − 1)) is defined everywhere in the plane except z = 0 and z = 1, where its denominator is zero; call these its bad points, or **singularities**. At z = 0.5 it gives −4; at z = 2, 0.5.

A Taylor series about 0 ([Taylor series in the plane](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/01-taylor-series-in-the-plane.md)) needs a value at its centre, and there is none. The fix is to allow negative powers too: 1/z, 1/z^2, 1/z^3.

Picture a flat doughnut round the centre: the region between two circles. A series with negative powers converges on such a ring.

This function has two rings round 0, split by the circle through its other bad point, 1. Inside, where 0 < |z| < 1, it equals −1/z − 1 − z − z^2 − …. Outside, where |z| > 1, it equals 1/z^2 + 1/z^3 + ….

From here on the ring is an **annulus**, and such a series a **Laurent series**, after Pierre Alphonse Laurent, whose memoir Cauchy reported on in May 1843.

A second example, e^z/z^3 = 1/z^3 + 1/z^2 + (1/2)/z + 1/6 + …, has one ring: every z but 0. Its 1/z coefficient, 1/2, will matter most.

**A function holomorphic (with a complex derivative) on a ring round a centre equals exactly one series in positive and negative powers of the distance from that centre; change the ring and the series can change.**

**What kind of fact this is:** a theorem, proved in Why it works, the full argument folded; finding the series by geometric series is a method.

### The picture: two rings round one centre

<p align="center"><img src="../figures/laurent-series.svg" alt="The plane round z = 0: the shaded inner ring 0 &lt; |z| &lt; 1, the outer ring beyond the dashed unit circle, holes at 0 and 1, the loops of radius 0.5 and 2 running anticlockwise, and the test points 0.3 + 0.4i and 1.2 + 1.6i" width="420"></p>

To scale: 50 units per 1, with 0 at (150, 120) and the hole 1 at (200, 120). Shaded: the inner ring; beyond the dashed unit circle: the outer ring. The loops, radius 0.5 and 2, carry the test points at (165, 100) and (210, 40).

---

## The formula

Notation first, in words. A sum from −∞ to ∞ means two sums, over the powers 0, 1, 2, … and over −1, −2, …, each converging on its own. The loop sign $\oint$ is the contour integral round a closed path, anticlockwise ([Deforming a loop](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/04-deforming-contours-and-winding-numbers.md)).

If $f$ is holomorphic (has a complex derivative) at every point of the ring $r < |z - a| < R$, then on that ring

$$f(z)=\sum_{n=-\infty}^{\infty}c_n(z-a)^n=\cdots+\frac{c_{-2}}{(z-a)^2}+\frac{c_{-1}}{z-a}+c_0+c_1(z-a)+\cdots$$

**Read it aloud:** on the ring, the function is a sum of whole-number powers of z minus the centre, negative ones included.

The coefficients, for any circle radius between r and R:

$$c_n=\frac{1}{2\pi i}\oint_{|\zeta-a|=\rho}\frac{f(\zeta)}{(\zeta-a)^{n+1}}\,d\zeta,\qquad r<\rho<R$$

**Read it aloud:** for the n-th coefficient, divide by one power more, go once round any circle in the ring, and divide by 2πi.

Walking the circle as $\zeta = a + \rho e^{it}$ turns this into an average: $c_n$ is the mean of $f(\zeta)(\zeta - a)^{-n}$ round the circle, which the code takes at $m$ equally spaced points. The negative-power terms together are the **principal part**.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $f$, $z$ | the function; a point in the plane | 1/(z(z − 1)); also e^z/z^3 | — |
| $a$ | the centre of the rings | 0 | the rings move with it |
| $r$, $R$ | inner and outer radius of the ring | 0 and 1 inside; 1 and ∞ outside | a new ring can mean new coefficients |
| $c_n$, $n$ | coefficient of the n-th power; n any whole number | inside −1 from n = −1 up; outside 1 from n = −2 down | — |
| $\rho$ | radius of the reading circle | 0.5, 0.75 inside; 1.5, 2 outside | same answer until it crosses a hole |
| $\zeta$, $t$ | a point walking the circle; its angle in radians | ζ = 0.5e^{it} | — |
| $m$ | points in the average | 128; with 4, error 0.066667 | error shrinks like 0.5^m |
| $\oint$, $i$ | loop integral, anticlockwise; i^2 = −1 | loop of 1/z is 2πi | — |

### When it holds

- **Holomorphic on the whole ring.** The ring from radius 0.5 to 1.5 contains the hole at 1; no series about 0 fits it, since the inner one diverges past 1 and the outer one inside it.
- **Open ring.** On |z| = 1 neither series converges, since its terms keep size 1, though f has values there except at 1.
- **One ring at a time.** About the same centre, c_{-1} is −1 inside and 0 outside.

---

## Why it works

### Step 0: one geometric series for small things, another for large ones

The geometric series 1/(1 − w) = 1 + w + w^2 + … converges when |w| < 1. For small z, write a fraction in powers of z; for large z, in powers of 1/z. A ring has a hole to avoid and an edge to stay inside, so it needs both.

### Step 1: the example by algebra

Split the fraction ([Rational functions](03-rational-functions-and-partial-fractions.md)): 1/(z(z − 1)) = 1/(z − 1) − 1/z; at z = 2, 1 − 0.5 = 0.5. Only 1/(z − 1) needs expanding.

Inside, |z| < 1, use ratio z: 1/(z − 1) = −1/(1 − z) = −1 − z − z^2 − …. So f = −1/z − 1 − z − z^2 − …, and every coefficient from $c_{-1}$ up is −1.

Outside, |z| > 1, use ratio 1/z: 1/(z − 1) = (1/z) · 1/(1 − 1/z) = 1/z + 1/z^2 + 1/z^3 + …. Adding −1/z cancels the first term. So f = 1/z^2 + 1/z^3 + …, and $c_{-1} = 0$.

### Step 2: the exponential example by shifting

The series $e^z = 1 + z + z^2/2! + z^3/3! + \cdots$ converges for every z ([Taylor series in the plane](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/01-taylor-series-in-the-plane.md)). Dividing by z^3 lowers every power by 3.

The coefficient of z^n becomes 1/(n + 3)! for n ≥ −3. The 1/z term comes from z^2/2!, so $c_{-1} = 1/2$. The only hole is 0, so the ring is 0 < |z| < ∞.

### Step 3: every holomorphic function on a ring has such a series

Cauchy's integral formula gives f(z) as a loop integral of f(ζ)/(ζ − z) round z, divided by 2πi. Used on the ring, it writes f(z) as an integral round an outer circle minus one round an inner circle. On the outer circle the loop point ζ is farther out than z, so 1/(ζ − z) expands in powers of z. On the inner circle ζ is nearer the centre, so it expands in powers of 1/z.

That is Step 0 inside an integral.

<details>
<summary>Detailed proof</summary>

Take $a = 0$ and z with ρ1 < |z| < ρ2, both radii inside the ring. Cut a small disc round z from the region between the circles. The function $f(\zeta)/(\zeta - z)$ is holomorphic on what remains, so by the deformation theorem the outer loop integral equals the inner one plus the small loop's, and shrinking the small loop gives $2\pi i f(z)$. So
$$f(z)=\frac{1}{2\pi i}\oint_{|\zeta|=\rho_2}\frac{f(\zeta)}{\zeta-z}\,d\zeta-\frac{1}{2\pi i}\oint_{|\zeta|=\rho_1}\frac{f(\zeta)}{\zeta-z}\,d\zeta.$$
On the outer circle $1/(\zeta-z)=\sum_{n\ge0}z^n/\zeta^{n+1}$, ratio |z|/ρ2 < 1. On the inner circle $-1/(\zeta-z)=\sum_{k\ge0}\zeta^k/z^{k+1}$, ratio ρ1/|z| < 1.

Each ratio has a fixed size below 1 on its circle and f is bounded there, so each series converges uniformly and integrates term by term. The two integrals give the non-negative and the negative powers, with the coefficients above. The coefficient integral is the same on every circle in the ring (Step 4), so one series serves the whole ring.

</details>

### Step 4: one loop integral sees one power, so the series is unique

On the circle z = ρe^(it), the loop integral of z^k is the integral of iρ^(k+1)e^(i(k+1)t) over one turn. That is 0 for every whole number k except −1, where the integrand is the constant i and the answer is 2πi, or 6.283185i.

Suppose f equals some series in positive and negative powers on the ring. Divide by z^(k+1) and integrate term by term round a circle in the ring; each half converges uniformly on that circle, which allows it. Uniformly means one number of terms makes the error small at every point of the circle at once.

Every term dies except the power k, leaving 2πi times the coefficient of z^k. So each coefficient is the loop integral in the formula, fixed by f and the ring, and every method gives the same numbers.

By [Deforming a loop](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/04-deforming-contours-and-winding-numbers.md), the loop integral stays put as the circle moves within the ring: radii 0.5 and 0.75 give $c_{-1} = -1$, radii 1.5 and 2 give 0. Crossing the hole at 1 changes it.

### Step 5: reading the annulus

The widest rings round a centre are bounded by circles through the bad points. In the example, each geometric ratio reaches size 1 exactly there. For 1/(z(z − 1)) about 0 the bad points lie at distances 0 and 1: rings 0 < |z| < 1 and 1 < |z| < ∞.

The code's second road is this formula, as an average round a circle. Faster rules for $c_{-1}$ alone are in [Residues](04-residues.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| inner series at 0.5, five terms | −2 − 1 − 1/2 − 1/4 − 1/8 | −3.875 |
| size of its gap | tail −z^4/(1 − z) = −(1/16)/(1/2) = −0.125 | 0.125 |
| outer series at 2, five terms | 1/4 + 1/8 + 1/16 + 1/32 + 1/64 | 0.484375 |
| size of its gap | tail 2^(−7)/(1 − 1/2) | 0.015625 |
| inner $c_{-1}$ | coefficient of 1/z in −1/z − 1 − z − … | **−1** |
| outer $c_{-1}$ | the 1/z terms cancel | **0** |
| $c_{-1}$ of e^z/z^3 | the z^2 term of e^z, 1/2! | **1/2** |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Inner series used at z = 2 | −15.5, not 0.5 | its ratio z has size 2 |
| Outer series used at z = 0.5 | 124, not −4 | its ratio 1/z has size 2 |
| $c_{-1}$ of e^z/z^3 read as 1/3! | 0.166667, not 0.5 | z^2/2!, not z^3/3!, lands on 1/z |
| $c_{-1}$ read on radius 2 for the inner ring | 0, not −1 | the circle crossed the hole at 1 |

The code prints all four.

---

## Code, from first principles, and it actually runs

Two roads to every coefficient: the algebra of Steps 1 and 2, written as rules, and the average round a circle, a trapezoid sum of 128 points on four radii that never sees the algebra. It also checks each five-term sum plus its geometric tail against f, and the averaging error against 0.5^m/(1 − 0.5^m).

### Python

```python
# Laurent series -- the check behind the card.  Standard library only.
# f(z) = 1/(z(z - 1)) has one expansion in the ring 0 < |z| < 1 and another in
# |z| > 1.  Road one: geometric-series algebra.  Road two: a trapezoid sum round
# a circle of radius rho, c_n = the average of f(z) z^(-n) over m equal steps.
from math import cos, sin, exp, pi

def f(z): return 1 / (z * (z - 1))
def g(z): return complex(exp(z.real) * cos(z.imag), exp(z.real) * sin(z.imag)) / z**3
def inner(n): return -1.0 if n >= -1 else 0.0          # -1/z - 1 - z - z^2 - ...
def outer(n): return 1.0 if n <= -2 else 0.0           # 1/z^2 + 1/z^3 + ...
def exp_coef(n):                                        # e^z/z^3: 1/(n + 3)! for n >= -3
    out = 1.0 if n >= -3 else 0.0
    for k in range(2, n + 4): out /= k
    return out
def contour(h, n, rho, m=128):                         # (1/2 pi i) loop of h(z)/z^(n+1) dz
    total = 0j
    for j in range(m):
        z = rho * complex(cos(2 * pi * j / m), sin(2 * pi * j / m))
        total += h(z) * z ** (-n)
    return total / m
def partial(ring, z, lo, hi): return sum(ring(n) * z**n for n in range(lo, hi + 1))
def c(w):
    re, im = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

tails = []
for name, ring, lo, hi, z in (("inner", inner, -1, 3, 0.5 + 0j), ("inner", inner, -1, 3, 0.3 + 0.4j),
                              ("outer", outer, -6, -2, 2 + 0j), ("outer", outer, -6, -2, 1.2 + 1.6j)):
    s = partial(ring, z, lo, hi)
    tail = -z**4 / (1 - z) if name == "inner" else z**-7 / (1 - 1 / z)   # geometric remainder
    tails.append(abs(f(z) - s - tail))
    print(f"{name} ring, z = {c(z)}: five terms {c(s)}, exact {c(f(z))}, gap {abs(f(z) - s):.6f}")
coef_gap = []
for name, ring, rho in (("inner", inner, 0.5), ("inner", inner, 0.75), ("outer", outer, 1.5), ("outer", outer, 2.0)):
    got = [contour(f, n, rho) for n in (-2, -1, 0)]
    coef_gap += [abs(w - ring(n)) for w, n in zip(got, (-2, -1, 0))]
    print(f"{name} ring, loop radius {rho:.2f}: c[-2] = {c(got[0])}, c[-1] = {c(got[1])}, c[0] = {c(got[2])}")
alias = [(abs(contour(f, -1, 0.5, m) - inner(-1)), 0.5**m / (1 - 0.5**m)) for m in (4, 8, 16)]
print("c[-1] error, radius 0.50, m = 4, 8, 16 steps: " + ", ".join(f"{e:.6f}" for e, _ in alias))
series = [exp_coef(n) for n in (-3, -2, -1, 0)]
loop = [contour(g, n, 1.0) for n in (-3, -2, -1, 0)]
print("e^z/z^3 by series, c[-3] c[-2] c[-1] c[0]: " + ", ".join(f"{v:.6f}" for v in series))
print("e^z/z^3 by loop radius 1, same four:      " + ", ".join(c(w) for w in loop))
print("loop integral of e^z/z^3 = 2 pi i c[-1]: " + c(2j * pi * contour(g, -1, 1.0)))
print("loop integral of z^k, k = -3..1: " + ", ".join(c(2j * pi * contour(lambda z: z**k, -1, 0.5)) for k in range(-3, 2)))
print(f"mistake 1, inner series at z = 2: {partial(inner, 2, -1, 3):.6f}, not {f(2):.6f}")
print(f"mistake 2, outer series at z = 0.5: {partial(outer, 0.5, -6, -2):.6f}, not {f(0.5):.6f}")
print(f"mistake 3, e^z/z^3 c[-1] read as 1/3!: {exp_coef(0):.6f}, not {exp_coef(-1):.6f}")
s = 50
pts = [(150 + s * z.real, 120 - s * z.imag) for z in (0j, 1 + 0j, 0.3 + 0.4j, 1.2 + 1.6j)]
print("figure, 50 units per 1: 0, 1, 0.3+0.4i, 1.2+1.6i at " + " ".join(f"({x:.0f}, {y:.0f})" for x, y in pts)
      + f"; radii {0.5 * s:.0f}, {1.0 * s:.0f}, {2.0 * s:.0f}")
assert max(coef_gap) < 1e-12                            # loop sums agree with the algebra
assert max(tails) < 1e-12                               # five terms + geometric tail = f
assert all(abs(w - v) < 1e-12 for w, v in zip(loop, series))
assert all(abs(e - p) < 1e-12 for e, p in alias)        # error is exactly rho^m/(1 - rho^m)
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
inner ring, z = 0.500000 + 0.000000i: five terms -3.875000 + 0.000000i, exact -4.000000 + 0.000000i, gap 0.125000
inner ring, z = 0.300000 + 0.400000i: five terms -2.313000 + 0.916000i, exact -2.276923 + 0.984615i, gap 0.077522
outer ring, z = 2.000000 + 0.000000i: five terms 0.484375 + 0.000000i, exact 0.500000 + 0.000000i, gap 0.015625
outer ring, z = 1.200000 + 1.600000i: five terms -0.230317 - 0.208944i, exact -0.223077 - 0.215385i, gap 0.009690
inner ring, loop radius 0.50: c[-2] = 0.000000 + 0.000000i, c[-1] = -1.000000 + 0.000000i, c[0] = -1.000000 + 0.000000i
inner ring, loop radius 0.75: c[-2] = 0.000000 + 0.000000i, c[-1] = -1.000000 + 0.000000i, c[0] = -1.000000 + 0.000000i
outer ring, loop radius 1.50: c[-2] = 1.000000 + 0.000000i, c[-1] = 0.000000 + 0.000000i, c[0] = 0.000000 + 0.000000i
outer ring, loop radius 2.00: c[-2] = 1.000000 + 0.000000i, c[-1] = 0.000000 + 0.000000i, c[0] = 0.000000 + 0.000000i
c[-1] error, radius 0.50, m = 4, 8, 16 steps: 0.066667, 0.003922, 0.000015
e^z/z^3 by series, c[-3] c[-2] c[-1] c[0]: 1.000000, 1.000000, 0.500000, 0.166667
e^z/z^3 by loop radius 1, same four:      1.000000 + 0.000000i, 1.000000 + 0.000000i, 0.500000 + 0.000000i, 0.166667 + 0.000000i
loop integral of e^z/z^3 = 2 pi i c[-1]: 0.000000 + 3.141593i
loop integral of z^k, k = -3..1: 0.000000 + 0.000000i, 0.000000 + 0.000000i, 0.000000 + 6.283185i, 0.000000 + 0.000000i, 0.000000 + 0.000000i
mistake 1, inner series at z = 2: -15.500000, not 0.500000
mistake 2, outer series at z = 0.5: 124.000000, not -4.000000
mistake 3, e^z/z^3 c[-1] read as 1/3!: 0.166667, not 0.500000
figure, 50 units per 1: 0, 1, 0.3+0.4i, 1.2+1.6i at (150, 120) (200, 120) (165, 100) (210, 40); radii 25, 50, 100
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Laurent series -- the same check as the Python, in Rust.  No crates.
// f(z) = 1/(z(z - 1)) has one expansion in the ring 0 < |z| < 1 and another in
// |z| > 1.  Road one: geometric-series algebra.  Road two: a trapezoid sum round
// a circle of radius rho, c_n = the average of f(z) z^(-n) over m equal steps.
use std::f64::consts::PI;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { cx(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { cx(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { cx(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; cx((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn pw(z: C, n: i32) -> C {
    let mut p = cx(1.0, 0.0); for _ in 0..n.abs() { p = mul(p, z) }
    if n < 0 { div(cx(1.0, 0.0), p) } else { p }
}
fn f(z: C) -> C { div(cx(1.0, 0.0), mul(z, sub(z, cx(1.0, 0.0)))) }
fn g(z: C) -> C { div(cx(z.re.exp() * z.im.cos(), z.re.exp() * z.im.sin()), pw(z, 3)) }
fn inner(n: i32) -> f64 { if n >= -1 { -1.0 } else { 0.0 } }       // -1/z - 1 - z - z^2 - ...
fn outer(n: i32) -> f64 { if n <= -2 { 1.0 } else { 0.0 } }        // 1/z^2 + 1/z^3 + ...
fn exp_coef(n: i32) -> f64 {                                        // e^z/z^3: 1/(n + 3)! for n >= -3
    let mut out = if n >= -3 { 1.0 } else { 0.0 }; for k in 2..n + 4 { out /= k as f64 }
    out
}
fn contour(h: &dyn Fn(C) -> C, n: i32, rho: f64, m: usize) -> C {  // (1/2 pi i) loop of h(z)/z^(n+1) dz
    let mut total = cx(0.0, 0.0);
    for j in 0..m {
        let t = 2.0 * PI * j as f64 / m as f64;
        let z = cx(rho * t.cos(), rho * t.sin());
        total = add(total, mul(h(z), pw(z, -n)));
    }
    cx(total.re / m as f64, total.im / m as f64)
}
fn partial(ring: fn(i32) -> f64, z: C, lo: i32, hi: i32) -> C {
    (lo..=hi).fold(cx(0.0, 0.0), |s, n| add(s, mul(cx(ring(n), 0.0), pw(z, n))))
}
fn c(w: C) -> String {
    let (re, im) = ((w.re * 1e6).round() / 1e6 + 0.0, (w.im * 1e6).round() / 1e6 + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn main() {
    let one = cx(1.0, 0.0);
    let mut tails = Vec::new();
    for (name, ring, lo, hi, z) in [("inner", inner as fn(i32) -> f64, -1, 3, cx(0.5, 0.0)), ("inner", inner, -1, 3, cx(0.3, 0.4)),
                                    ("outer", outer, -6, -2, cx(2.0, 0.0)), ("outer", outer, -6, -2, cx(1.2, 1.6))] {
        let s = partial(ring, z, lo, hi);
        let tail = if name == "inner" { div(mul(cx(-1.0, 0.0), pw(z, 4)), sub(one, z)) } else { div(pw(z, -7), sub(one, div(one, z))) };
        tails.push(abs(sub(sub(f(z), s), tail)));
        println!("{} ring, z = {}: five terms {}, exact {}, gap {:.6}", name, c(z), c(s), c(f(z)), abs(sub(f(z), s)));
    }
    let mut coef_gap = Vec::new();
    for (name, ring, rho) in [("inner", inner as fn(i32) -> f64, 0.5), ("inner", inner, 0.75), ("outer", outer, 1.5), ("outer", outer, 2.0)] {
        let got: Vec<C> = [-2, -1, 0].iter().map(|&n| contour(&f, n, rho, 128)).collect();
        for (w, n) in got.iter().zip([-2, -1, 0]) { coef_gap.push(abs(sub(*w, cx(ring(n), 0.0)))) }
        println!("{} ring, loop radius {:.2}: c[-2] = {}, c[-1] = {}, c[0] = {}", name, rho, c(got[0]), c(got[1]), c(got[2]));
    }
    let alias: Vec<(f64, f64)> = [4, 8, 16].iter()
        .map(|&m| (abs(sub(contour(&f, -1, 0.5, m), cx(inner(-1), 0.0))), 0.5f64.powi(m as i32) / (1.0 - 0.5f64.powi(m as i32)))).collect();
    println!("c[-1] error, radius 0.50, m = 4, 8, 16 steps: {}", alias.iter().map(|a| format!("{:.6}", a.0)).collect::<Vec<_>>().join(", "));
    let series: Vec<f64> = [-3, -2, -1, 0].iter().map(|&n| exp_coef(n)).collect();
    let lp: Vec<C> = [-3, -2, -1, 0].iter().map(|&n| contour(&g, n, 1.0, 128)).collect();
    println!("e^z/z^3 by series, c[-3] c[-2] c[-1] c[0]: {}", series.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(", "));
    println!("e^z/z^3 by loop radius 1, same four:      {}", lp.iter().map(|w| c(*w)).collect::<Vec<_>>().join(", "));
    println!("loop integral of e^z/z^3 = 2 pi i c[-1]: {}", c(mul(cx(0.0, 2.0 * PI), contour(&g, -1, 1.0, 128))));
    let zk: Vec<String> = (-3..2).map(|k| c(mul(cx(0.0, 2.0 * PI), contour(&move |z: C| pw(z, k), -1, 0.5, 128)))).collect();
    println!("loop integral of z^k, k = -3..1: {}", zk.join(", "));
    println!("mistake 1, inner series at z = 2: {:.6}, not {:.6}", partial(inner, cx(2.0, 0.0), -1, 3).re, f(cx(2.0, 0.0)).re);
    println!("mistake 2, outer series at z = 0.5: {:.6}, not {:.6}", partial(outer, cx(0.5, 0.0), -6, -2).re, f(cx(0.5, 0.0)).re);
    println!("mistake 3, e^z/z^3 c[-1] read as 1/3!: {:.6}, not {:.6}", exp_coef(0), exp_coef(-1));
    let s = 50.0;
    let pts: Vec<String> = [cx(0.0, 0.0), one, cx(0.3, 0.4), cx(1.2, 1.6)].iter()
        .map(|z| format!("({:.0}, {:.0})", 150.0 + s * z.re, 120.0 - s * z.im)).collect();
    println!("figure, 50 units per 1: 0, 1, 0.3+0.4i, 1.2+1.6i at {}; radii {:.0}, {:.0}, {:.0}", pts.join(" "), 0.5 * s, 1.0 * s, 2.0 * s);
    assert!(coef_gap.iter().all(|&e| e < 1e-12));                   // loop sums agree with the algebra
    assert!(tails.iter().all(|&e| e < 1e-12));                      // five terms + geometric tail = f
    assert!(lp.iter().zip(&series).all(|(w, v)| abs(sub(*w, cx(*v, 0.0))) < 1e-12));
    assert!(alias.iter().all(|(e, p)| (e - p).abs() < 1e-12));      // error is exactly rho^m/(1 - rho^m)
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
inner ring, z = 0.500000 + 0.000000i: five terms -3.875000 + 0.000000i, exact -4.000000 + 0.000000i, gap 0.125000
inner ring, z = 0.300000 + 0.400000i: five terms -2.313000 + 0.916000i, exact -2.276923 + 0.984615i, gap 0.077522
outer ring, z = 2.000000 + 0.000000i: five terms 0.484375 + 0.000000i, exact 0.500000 + 0.000000i, gap 0.015625
outer ring, z = 1.200000 + 1.600000i: five terms -0.230317 - 0.208944i, exact -0.223077 - 0.215385i, gap 0.009690
inner ring, loop radius 0.50: c[-2] = 0.000000 + 0.000000i, c[-1] = -1.000000 + 0.000000i, c[0] = -1.000000 + 0.000000i
inner ring, loop radius 0.75: c[-2] = 0.000000 + 0.000000i, c[-1] = -1.000000 + 0.000000i, c[0] = -1.000000 + 0.000000i
outer ring, loop radius 1.50: c[-2] = 1.000000 + 0.000000i, c[-1] = 0.000000 + 0.000000i, c[0] = 0.000000 + 0.000000i
outer ring, loop radius 2.00: c[-2] = 1.000000 + 0.000000i, c[-1] = 0.000000 + 0.000000i, c[0] = 0.000000 + 0.000000i
c[-1] error, radius 0.50, m = 4, 8, 16 steps: 0.066667, 0.003922, 0.000015
e^z/z^3 by series, c[-3] c[-2] c[-1] c[0]: 1.000000, 1.000000, 0.500000, 0.166667
e^z/z^3 by loop radius 1, same four:      1.000000 + 0.000000i, 1.000000 + 0.000000i, 0.500000 + 0.000000i, 0.166667 + 0.000000i
loop integral of e^z/z^3 = 2 pi i c[-1]: 0.000000 + 3.141593i
loop integral of z^k, k = -3..1: 0.000000 + 0.000000i, 0.000000 + 0.000000i, 0.000000 + 6.283185i, 0.000000 + 0.000000i, 0.000000 + 0.000000i
mistake 1, inner series at z = 2: -15.500000, not 0.500000
mistake 2, outer series at z = 0.5: 124.000000, not -4.000000
mistake 3, e^z/z^3 c[-1] read as 1/3!: 0.166667, not 0.500000
figure, 50 units per 1: 0, 1, 0.3+0.4i, 1.2+1.6i at (150, 120) (200, 120) (165, 100) (210, 40); radii 25, 50, 100
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the Laurent series theorem for every ring round any centre, and both series of 1/(z(z − 1)) about 0.

- A function holomorphic on the open ring r < |z − a| < R equals exactly one series in powers of z − a there.
- That series allows negative powers, and the ring may have r = 0 or R = ∞.
- Each coefficient $c_n$ is the loop integral in the formula, on every circle radius ρ between r and R.
- Inside, where 0 < |z| < 1, 1/(z(z − 1)) equals −1/z − 1 − z − z^2 − …, so $c_{-1}$ = −1.
- Outside, where |z| > 1, it equals 1/z^2 + 1/z^3 + …, so $c_{-1}$ = 0.
- The hand arithmetic holds exactly: f at 0.5 and 2, the five-term sums and tails, the first two mistakes, and 1/2! against 1/3!.

The decimals, the circle averages and their error, and the series of e^z/z^3 are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 397 lines</summary>

```lean
-- Laurent series: a function with a complex derivative on an open ring round a centre equals exactly one series in positive and negative powers of z minus the centre, its coefficients are loop integrals, and 1/(z(z - 1)) has different series inside and outside the unit circle.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open Complex Real
open scoped ENNReal

open Metric Set Filter MeasureTheory in
theorem laurentAux_coeff {f : ℂ → ℂ} {a : ℂ} {c : ℤ → ℂ} {ρ : ℝ} (hρ : 0 < ρ)
    (hc : ∀ z : ℂ, ‖z - a‖ = ρ → HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z)) (n : ℤ) :
    c n = (2 * π * I)⁻¹ * ∮ ζ in C(a, ρ), f ζ / (ζ - a) ^ (n + 1) := by
  have hsum : Summable (fun k : ℤ => ‖c k‖ * ρ ^ k) := by
    have h0 := hc (a + ρ) (by simp [abs_of_pos hρ])
    have := summable_norm_iff.mpr h0.summable
    simpa [norm_zpow, abs_of_pos hρ] using this
  have hne : ∀ θ, circleMap a ρ θ - a ≠ 0 := fun θ =>
    sub_ne_zero.2 (circleMap_ne_center hρ.ne')
  have hcont : Continuous (fun θ => circleMap a ρ θ - a) := by fun_prop
  have key : HasSum (fun k : ℤ => ∮ ζ in C(a, ρ), c k * (ζ - a) ^ k / (ζ - a) ^ (n + 1))
      (∮ ζ in C(a, ρ), f ζ / (ζ - a) ^ (n + 1)) := by
    unfold circleIntegral
    refine intervalIntegral.hasSum_integral_of_dominated_convergence
      (fun k _ => ρ * (‖c k‖ * ρ ^ k) / ρ ^ (n + 1)) (fun k => ?_) (fun k => ?_) ?_ ?_ ?_
    · apply Continuous.aestronglyMeasurable
      simp only [deriv_circleMap]
      have h1 := hcont.zpow₀ k (fun θ => Or.inl (hne θ))
      have h2 := hcont.zpow₀ (n + 1) (fun θ => Or.inl (hne θ))
      exact (by fun_prop : Continuous fun θ => circleMap 0 ρ θ * I).smul
        ((continuous_const.mul h1).div h2 (fun θ => zpow_ne_zero _ (hne θ)))
    · refine Eventually.of_forall fun θ _ => le_of_eq ?_
      simp [deriv_circleMap, norm_zpow, circleMap_sub_center, abs_of_pos hρ]
      ring
    · exact Eventually.of_forall fun _ _ => (hsum.mul_left ρ).div_const _
    · exact intervalIntegrable_const
    · refine Eventually.of_forall fun θ _ => ?_
      have := (hc (circleMap a ρ θ) (by simp [abs_of_pos hρ])).div_const ((circleMap a ρ θ - a) ^ (n + 1))
      exact this.const_smul (deriv (circleMap a ρ) θ)
  have hterm : ∀ k : ℤ, (∮ ζ in C(a, ρ), c k * (ζ - a) ^ k / (ζ - a) ^ (n + 1)) =
      if k = n then c k * (2 * π * I) else 0 := by
    intro k
    have : (∮ ζ in C(a, ρ), c k * (ζ - a) ^ k / (ζ - a) ^ (n + 1)) =
        c k * ∮ ζ in C(a, ρ), (ζ - a) ^ (k - (n + 1)) := by
      rw [← circleIntegral.integral_const_mul]
      refine circleIntegral.integral_congr hρ.le fun ζ hζ => ?_
      have hz : ζ - a ≠ 0 := by
        rw [sub_ne_zero]; rintro rfl; simp at hζ; linarith
      rw [zpow_sub₀ hz, mul_div_assoc]
    rw [this]
    split_ifs with h
    · subst h
      have : k - (k + 1) = -1 := by ring
      simp only [this, zpow_neg_one]
      rw [circleIntegral.integral_sub_center_inv _ hρ.ne']
    · rw [circleIntegral.integral_sub_zpow_of_ne (by omega), mul_zero]
  simp only [hterm] at key
  have h2 : HasSum (fun k : ℤ => if k = n then c k * (2 * π * I) else 0) (c n * (2 * π * I)) := by
    convert hasSum_ite_eq n (c n * (2 * π * I)) using 2 with k
    split_ifs with h <;> simp [h]
  rw [key.unique h2]
  field_simp [two_pi_I_ne_zero]

#print axioms laurentAux_coeff

open Metric Set Filter MeasureTheory in
theorem laurentAux_neg {f : ℂ → ℂ} {a w : ℂ} {r₁ : ℝ} (hf : CircleIntegrable f a r₁)
    (h0 : 0 < r₁) (hw : r₁ < ‖w‖) :
    HasSum (fun m : ℕ => ∮ ζ in C(a, r₁), ((ζ - a) / w) ^ m • w⁻¹ • f ζ)
      (-∮ ζ in C(a, r₁), (ζ - (a + w))⁻¹ • f ζ) := by
  have hw0 : 0 < ‖w‖ := h0.trans hw
  have hwne : w ≠ 0 := norm_pos_iff.1 hw0
  have hwR : r₁ / ‖w‖ ∈ Ico (0 : ℝ) 1 := ⟨by positivity, (div_lt_one hw0).2 hw⟩
  unfold circleIntegral
  rw [← intervalIntegral.integral_neg]
  refine intervalIntegral.hasSum_integral_of_dominated_convergence
      (fun n θ => r₁ * ‖w‖⁻¹ * ‖f (circleMap a r₁ θ)‖ * (r₁ / ‖w‖) ^ n)
      (fun n => ?_) (fun n => ?_) ?_ ?_ ?_
  · simp only [deriv_circleMap]
    exact ((by fun_prop : Continuous fun θ => circleMap 0 r₁ θ * I).aestronglyMeasurable).smul
      (((by fun_prop : Continuous fun θ => ((circleMap a r₁ θ - a) / w) ^ n).aestronglyMeasurable).smul
        (hf.def'.1.const_smul w⁻¹))
  · refine Eventually.of_forall fun θ _ => le_of_eq ?_
    simp [deriv_circleMap, circleMap_sub_center, abs_of_pos h0, div_pow]
    ring
  · exact Eventually.of_forall fun _ _ => (summable_geometric_of_lt_one hwR.1 hwR.2).mul_left _
  · simpa only [tsum_mul_left, tsum_geometric_of_lt_one hwR.1 hwR.2] using
      (hf.norm.const_mul (r₁ * ‖w‖⁻¹)).mul_continuousOn continuousOn_const
  · refine Eventually.of_forall fun θ _ => ?_
    have hξ : ‖(circleMap a r₁ θ - a) / w‖ < 1 := by
      simpa [circleMap_sub_center, abs_of_pos h0, norm_div] using hwR.2
    have h1 : (1 : ℂ) - (circleMap a r₁ θ - a) / w ≠ 0 := by
      intro h; rw [sub_eq_zero] at h; rw [← h] at hξ; simp at hξ
    have h2 : circleMap a r₁ θ - (a + w) ≠ 0 := by
      intro h; apply h1; field_simp; linear_combination -h
    have := ((hasSum_geometric_of_norm_lt_one hξ).mul_right (w⁻¹ * f (circleMap a r₁ θ))).const_smul
      (deriv (circleMap a r₁) θ)
    have e : (1 - (circleMap a r₁ θ - a) / w)⁻¹ * w⁻¹ = -(circleMap a r₁ θ - (a + w))⁻¹ := by
      rw [← mul_inv, sub_mul, div_mul_cancel₀ _ hwne, one_mul, ← inv_neg]; congr 1; ring
    convert this using 1
    simp only [smul_eq_mul]
    rw [← mul_assoc ((1 - (circleMap a r₁ θ - a) / w)⁻¹), e]; ring

#print axioms laurentAux_neg

open Metric Set Filter MeasureTheory in
theorem laurentAux_cauchy {f : ℂ → ℂ} {a z : ℂ} {r₁ R₁ : ℝ} (h0 : 0 < r₁)
    (h1 : r₁ < ‖z - a‖) (h2 : ‖z - a‖ < R₁)
    (hf : ∀ ζ ∈ closedBall a R₁ \ ball a r₁, DifferentiableAt ℂ f ζ) :
    (∮ ζ in C(a, R₁), (ζ - z)⁻¹ • f ζ) - (∮ ζ in C(a, r₁), (ζ - z)⁻¹ • f ζ) =
      (2 * π * I) * f z := by
  set K := closedBall a R₁ \ ball a r₁
  have hR0 : 0 < R₁ := h0.trans (h1.trans h2)
  have hzK' : z ∈ ball a R₁ \ closedBall a r₁ := by
    simp [dist_eq_norm, h2, h1]
  have hKn : K ∈ nhds z :=
    mem_of_superset ((isOpen_ball.sdiff isClosed_closedBall).mem_nhds hzK')
      (sdiff_subset_sdiff ball_subset_closedBall ball_subset_closedBall)
  have hfc : ContinuousOn f K := fun ζ hζ => (hf ζ hζ).continuousAt.continuousWithinAt
  set G := dslope f z
  have hcG : ContinuousOn G K := (continuousOn_dslope hKn).2 ⟨hfc, hf z (mem_of_mem_nhds hKn)⟩
  have hdG : ∀ w ∈ (ball a R₁ \ closedBall a r₁) \ {z}, DifferentiableAt ℂ G w := by
    intro w hw
    exact (differentiableAt_dslope_of_ne hw.2).2
      (hf w (sdiff_subset_sdiff ball_subset_closedBall ball_subset_closedBall hw.1))
  have hG := circleIntegral_eq_of_differentiable_on_annulus_off_countable h0
    (h1.trans h2).le (countable_singleton z) hcG hdG
  -- G on the two circles
  have hsph : ∀ ρ : ℝ, (ρ = r₁ ∨ ρ = R₁) → EqOn G (fun ζ => (ζ - z)⁻¹ • f ζ - (ζ - z)⁻¹ • f z)
      (sphere a ρ) := by
    intro ρ hρ ζ hζ
    have hne : ζ ≠ z := by
      rintro rfl; simp at hζ; rcases hρ with rfl | rfl <;> linarith
    simp only [G, dslope_of_ne _ hne, slope_def_module, smul_sub]
  have hint : ∀ ρ : ℝ, (ρ = r₁ ∨ ρ = R₁) → 0 < ρ →
      CircleIntegrable (fun ζ => (ζ - z)⁻¹ • f ζ) a ρ ∧
      CircleIntegrable (fun ζ => (ζ - z)⁻¹ • f z) a ρ := by
    intro ρ hρ hρ0
    have hne : ∀ ζ ∈ sphere a ρ, ζ - z ≠ 0 := by
      intro ζ hζ h; rw [sub_eq_zero] at h; subst h
      simp at hζ; rcases hρ with rfl | rfl <;> linarith
    have hc' : ContinuousOn (fun ζ => (ζ - z)⁻¹) (sphere a ρ) :=
      (continuousOn_id.sub continuousOn_const).inv₀ hne
    have hsK : sphere a ρ ⊆ K := by
      intro ζ hζ; simp [K, dist_eq_norm] at hζ ⊢
      rcases hρ with rfl | rfl <;> constructor <;> linarith
    exact ⟨(hc'.smul (hfc.mono hsK)).circleIntegrable hρ0.le,
      (hc'.smul continuousOn_const).circleIntegrable hρ0.le⟩
  rw [circleIntegral.integral_congr hR0.le (hsph R₁ (Or.inr rfl)),
    circleIntegral.integral_congr h0.le (hsph r₁ (Or.inl rfl)),
    circleIntegral.integral_sub (hint R₁ (Or.inr rfl) hR0).1 (hint R₁ (Or.inr rfl) hR0).2,
    circleIntegral.integral_sub (hint r₁ (Or.inl rfl) h0).1 (hint r₁ (Or.inl rfl) h0).2,
    circleIntegral.integral_smul_const, circleIntegral.integral_smul_const,
    circleIntegral.integral_sub_inv_of_mem_ball (by simpa [dist_eq_norm] using h2)] at hG
  have hzero : (∮ ζ in C(a, r₁), (ζ - z)⁻¹) = 0 := by
    have hne : ∀ ζ ∈ closedBall a r₁, ζ - z ≠ 0 := by
      intro ζ hζ h; rw [sub_eq_zero] at h; subst h
      simp [dist_eq_norm] at hζ; linarith
    refine circleIntegral_eq_zero_of_differentiable_on_off_countable h0.le countable_empty
      ((continuousOn_id.sub continuousOn_const).inv₀ hne) ?_
    intro ζ hζ
    exact ((differentiableAt_id.sub_const z).inv (hne ζ (ball_subset_closedBall hζ.1)))
  rw [hzero, zero_smul, sub_zero, smul_eq_mul] at hG
  linear_combination hG

#print axioms laurentAux_cauchy

open Metric Set Filter MeasureTheory in
theorem laurentAux_diffAt {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) (m : ℤ) {ζ : ℂ}
    (hζ : ζ ∈ {z | r < edist z a ∧ edist z a < R}) :
    DifferentiableAt ℂ (fun ζ => f ζ / (ζ - a) ^ m) ζ := by
  have hS : IsOpen {z : ℂ | r < edist z a ∧ edist z a < R} :=
    (isOpen_lt continuous_const (continuous_id.edist continuous_const)).inter
      (isOpen_lt (continuous_id.edist continuous_const) continuous_const)
  have hne : ζ - a ≠ 0 := by
    rw [sub_ne_zero]; rintro rfl; simp at hζ
  exact (hf.differentiableAt (hS.mem_nhds hζ)).div
    ((differentiableAt_id.sub_const a).zpow (Or.inl hne)) (zpow_ne_zero _ hne)

#print axioms laurentAux_diffAt

open Metric Set Filter MeasureTheory in
theorem laurentAux_indep {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) (n : ℤ) {ρ₁ ρ₂ : ℝ}
    (h1r : r < ENNReal.ofReal ρ₁) (h1R : ENNReal.ofReal ρ₁ < R)
    (h2r : r < ENNReal.ofReal ρ₂) (h2R : ENNReal.ofReal ρ₂ < R) :
    (∮ ζ in C(a, ρ₁), f ζ / (ζ - a) ^ (n + 1)) = ∮ ζ in C(a, ρ₂), f ζ / (ζ - a) ^ (n + 1) := by
  wlog h : ρ₁ ≤ ρ₂ generalizing ρ₁ ρ₂
  · exact (this h2r h2R h1r h1R (le_of_not_ge h)).symm
  have hρ0 : 0 < ρ₁ := ENNReal.ofReal_pos.1 (pos_of_gt h1r)
  have hsub : closedBall a ρ₂ \ ball a ρ₁ ⊆ {z | r < edist z a ∧ edist z a < R} := by
    intro ζ hζ
    simp only [Set.mem_sdiff, mem_closedBall, mem_ball, not_lt] at hζ
    simp only [mem_ofPred_eq, edist_dist]
    exact ⟨h1r.trans_le (ENNReal.ofReal_le_ofReal hζ.2),
      (ENNReal.ofReal_le_ofReal hζ.1).trans_lt h2R⟩
  refine (circleIntegral_eq_of_differentiable_on_annulus_off_countable hρ0 h
    countable_empty ?_ ?_).symm
  · exact fun ζ hζ => (laurentAux_diffAt hf _ (hsub hζ)).continuousAt.continuousWithinAt
  · intro ζ hζ
    exact laurentAux_diffAt hf _
      (hsub (sdiff_subset_sdiff ball_subset_closedBall ball_subset_closedBall hζ.1))

#print axioms laurentAux_indep

open Metric Set Filter MeasureTheory in
theorem laurentAux_exists {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hrR : r < R) (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) :
    ∃ c : ℤ → ℂ, ∀ z : ℂ, r < edist z a → edist z a < R →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z) := by
  obtain ⟨ρ₀, -, h0r, h0R⟩ := ENNReal.lt_iff_exists_real_btwn.1 hrR
  set J : ℤ → ℂ := fun n => ∮ ζ in C(a, ρ₀), f ζ / (ζ - a) ^ (n + 1) with hJ
  refine ⟨fun n => (2 * π * I)⁻¹ * J n, fun z hzr hzR => ?_⟩
  have hS : IsOpen {z : ℂ | r < edist z a ∧ edist z a < R} :=
    (isOpen_lt continuous_const (continuous_id.edist continuous_const)).inter
      (isOpen_lt (continuous_id.edist continuous_const) continuous_const)
  have hfint : ∀ ρ : ℝ, 0 < ρ → r < ENNReal.ofReal ρ → ENNReal.ofReal ρ < R →
      CircleIntegrable f a ρ := by
    intro ρ hρ h1 h2
    refine ContinuousOn.circleIntegrable hρ.le (hf.continuousOn.mono fun ζ hζ => ?_)
    simp only [mem_sphere] at hζ
    simp only [Set.mem_ofPred_eq, edist_dist, hζ]
    exact ⟨h1, h2⟩
  rw [edist_dist, dist_eq_norm] at hzr hzR
  obtain ⟨r₁, -, h1r, h1d⟩ := ENNReal.lt_iff_exists_real_btwn.1 hzr
  obtain ⟨R₁, -, h2d, h2R⟩ := ENNReal.lt_iff_exists_real_btwn.1 hzR
  have hr₁ : 0 < r₁ := ENNReal.ofReal_pos.1 (pos_of_gt h1r)
  have hR₁ : 0 < R₁ := ENNReal.ofReal_pos.1 (pos_of_gt h2d)
  have hd : 0 < ‖z - a‖ := ENNReal.ofReal_pos.1 (pos_of_gt hzr)
  have hlt1 : r₁ < ‖z - a‖ := (ENNReal.ofReal_lt_ofReal_iff hd).1 h1d
  have hlt2 : ‖z - a‖ < R₁ := (ENNReal.ofReal_lt_ofReal_iff hR₁).1 h2d
  have h1R : ENNReal.ofReal r₁ < R := h1d.trans hzR
  have h2r : r < ENNReal.ofReal R₁ := hzr.trans h2d
  have hKS : closedBall a R₁ \ ball a r₁ ⊆ {z | r < edist z a ∧ edist z a < R} := by
    intro ζ hζ
    simp only [Set.mem_sdiff, mem_closedBall, mem_ball, not_lt] at hζ
    simp only [Set.mem_ofPred_eq, edist_dist]
    exact ⟨h1r.trans_le (ENNReal.ofReal_le_ofReal hζ.2),
      (ENNReal.ofReal_le_ofReal hζ.1).trans_lt h2R⟩
  have hC := laurentAux_cauchy hr₁ hlt1 hlt2
    (fun ζ hζ => hf.differentiableAt (hS.mem_nhds (hKS hζ)))
  have hpos := hasSum_two_pi_I_cauchyPowerSeries_integral (hfint R₁ hR₁ h2r h2R) hlt2
  simp only [add_sub_cancel] at hpos
  have hpos' : HasSum (fun n : ℕ => J n * (z - a) ^ (n : ℤ))
      (∮ ζ in C(a, R₁), (ζ - z)⁻¹ • f ζ) := by
    convert hpos using 1
    funext n
    rw [hJ]
    simp only
    rw [laurentAux_indep hf n h0r h0R h2r h2R, mul_comm, ← circleIntegral.integral_const_mul]
    refine circleIntegral.integral_congr hR₁.le fun ζ hζ => ?_
    have hne : ζ - a ≠ 0 := by
      rw [sub_ne_zero]; rintro rfl; simp at hζ; linarith
    simp only [smul_eq_mul]
    rw [← Nat.cast_succ, zpow_natCast, zpow_natCast, div_pow, pow_succ]
    field_simp
  have hneg := laurentAux_neg (w := z - a) (hfint r₁ hr₁ h1r h1R) hr₁ hlt1
  simp only [add_sub_cancel] at hneg
  have hneg' : HasSum (fun m : ℕ => J (-((m : ℤ) + 1)) * (z - a) ^ (-((m : ℤ) + 1)))
      (-∮ ζ in C(a, r₁), (ζ - z)⁻¹ • f ζ) := by
    convert hneg using 1
    funext m
    rw [hJ]
    simp only
    rw [laurentAux_indep hf _ h0r h0R h1r h1R, mul_comm, ← circleIntegral.integral_const_mul]
    refine circleIntegral.integral_congr hr₁.le fun ζ hζ => ?_
    have hne : ζ - a ≠ 0 := by
      rw [sub_ne_zero]; rintro rfl; simp at hζ; linarith
    have hne' : z - a ≠ 0 := norm_pos_iff.1 hd
    simp only [smul_eq_mul]
    rw [show -((m : ℤ) + 1) + 1 = -(m : ℤ) by ring, zpow_neg, zpow_neg, ← Nat.cast_succ,
      zpow_natCast, zpow_natCast, div_pow, pow_succ]
    field_simp
  have htot : HasSum (fun n : ℤ => J n * (z - a) ^ n)
      ((∮ ζ in C(a, R₁), (ζ - z)⁻¹ • f ζ) + -∮ ζ in C(a, r₁), (ζ - z)⁻¹ • f ζ) :=
    HasSum.of_nat_of_neg_add_one hpos' hneg'
  rw [← sub_eq_add_neg, hC] at htot
  convert htot.mul_left (2 * π * I)⁻¹ using 1
  · funext n; ring
  · field_simp [two_pi_I_ne_zero]

#print axioms laurentAux_exists

/-- A function holomorphic (with a complex derivative) at every point of the open ring
`r < |z - a| < R` round the centre `a` equals exactly one series in positive and negative
powers of `z - a` on that ring: there is one and only one choice of coefficients `c n`,
`n` any whole number, with `∑ c n (z - a)ⁿ = f z` at every point `z` of the ring.
The radii may be `0` inside and `∞` outside. -/
theorem holomorphic_on_annulus_has_unique_laurent_series {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hrR : r < R) (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) :
    ∃! c : ℤ → ℂ, ∀ z : ℂ, r < edist z a → edist z a < R →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z) := by
  obtain ⟨c, hc⟩ := laurentAux_exists hrR hf
  refine ⟨c, hc, fun c' hc' => funext fun n => ?_⟩
  obtain ⟨ρ, -, hρr, hρR⟩ := ENNReal.lt_iff_exists_real_btwn.1 hrR
  have hρ : 0 < ρ := ENNReal.ofReal_pos.1 (pos_of_gt hρr)
  have hsph : ∀ z : ℂ, ‖z - a‖ = ρ → r < edist z a ∧ edist z a < R := by
    intro z hz
    rw [edist_dist, dist_eq_norm, hz]
    exact ⟨hρr, hρR⟩
  rw [laurentAux_coeff hρ (fun z hz => hc' z (hsph z hz).1 (hsph z hz).2) n,
    laurentAux_coeff hρ (fun z hz => hc z (hsph z hz).1 (hsph z hz).2) n]

/-- The coefficients are loop integrals: if `f` is holomorphic on the ring `r < |z - a| < R`
and equals `∑ c n (z - a)ⁿ` there, then for every circle radius `ρ` between `r` and `R`,
`c n = (1 / 2πi) ∮_{|ζ - a| = ρ} f ζ / (ζ - a)^(n + 1) dζ`. -/
theorem laurent_coeff_eq_circle_integral {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) {c : ℤ → ℂ}
    (hc : ∀ z : ℂ, r < edist z a → edist z a < R →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    {ρ : ℝ} (hρr : r < ENNReal.ofReal ρ) (hρR : ENNReal.ofReal ρ < R) (n : ℤ) :
    c n = (2 * π * I)⁻¹ * ∮ ζ in C(a, ρ), f ζ / (ζ - a) ^ (n + 1) := by
  have hρ : 0 < ρ := ENNReal.ofReal_pos.1 (pos_of_gt hρr)
  refine laurentAux_coeff hρ (fun z hz => hc z ?_ ?_) n
  · rw [edist_dist, dist_eq_norm, hz]; exact hρr
  · rw [edist_dist, dist_eq_norm, hz]; exact hρR

/-- One function, two rings: about 0, `1/(z(z - 1))` equals `-1/z - 1 - z - z² - …`
(every coefficient from `c₋₁` up is `-1`) when `0 < |z| < 1`, and equals
`1/z² + 1/z³ + …` (every coefficient from `c₋₂` down is `1`, so `c₋₁ = 0`) when `|z| > 1`. -/
theorem laurent_series_of_inv_z_mul_z_sub_one_inside_and_outside :
    (∀ z : ℂ, 0 < ‖z‖ → ‖z‖ < 1 →
      HasSum (fun n : ℤ ↦ (if -1 ≤ n then (-1 : ℂ) else 0) * z ^ n) (1 / (z * (z - 1)))) ∧
    (∀ z : ℂ, 1 < ‖z‖ →
      HasSum (fun n : ℤ ↦ (if n ≤ -2 then (1 : ℂ) else 0) * z ^ n) (1 / (z * (z - 1)))) := by
  constructor
  · intro z hz0 hz1
    have hz : z ≠ 0 := norm_pos_iff.1 hz0
    have h1 : z - 1 ≠ 0 := by
      intro h; rw [sub_eq_zero] at h; subst h; simp at hz1
    have hg : Function.Injective (fun m : ℕ => (m : ℤ) - 1) := fun x y h => by simpa using h
    rw [← hg.hasSum_iff]
    · have := (hasSum_geometric_of_norm_lt_one hz1).mul_left (-z⁻¹)
      convert this using 1
      · funext m
        simp only [Function.comp, show -1 ≤ (m : ℤ) - 1 by omega, ite_true]
        rw [zpow_sub_one₀ hz, zpow_natCast]; ring
      · have h2 : (1:ℂ) - z ≠ 0 := by
          rw [sub_ne_zero]; exact fun h => h1 (by rw [← h]; ring)
        field_simp
        ring
    · intro n hn
      have : ¬ (-1 ≤ n) := fun h => hn ⟨(n + 1).toNat, by simp; omega⟩
      simp [this]
  · intro z hz1
    have hz : z ≠ 0 := by rintro rfl; simp at hz1; linarith
    have h1 : z - 1 ≠ 0 := by
      intro h; rw [sub_eq_zero] at h; subst h; simp at hz1
    have hzi : ‖z⁻¹‖ < 1 := by rw [norm_inv]; exact inv_lt_one_of_one_lt₀ hz1
    have hg : Function.Injective (fun m : ℕ => -((m : ℤ) + 2)) := fun x y h => by simpa using h
    rw [← hg.hasSum_iff]
    · have := (hasSum_geometric_of_norm_lt_one hzi).mul_left (z⁻¹ ^ 2)
      convert this using 1
      · funext m
        simp only [Function.comp, show -((m : ℤ) + 2) ≤ -2 by omega, ite_true]
        rw [zpow_neg, ← inv_zpow, show (m : ℤ) + 2 = ((m + 2 : ℕ) : ℤ) by push_cast; ring,
          zpow_natCast]
        ring
      · have h2 : 1 - z⁻¹ ≠ 0 := by
          rw [sub_ne_zero]; intro h; rw [eq_comm, inv_eq_one] at h; subst h; simp at hz1
        field_simp
    · intro n hn
      have : ¬ (n ≤ -2) := fun h => hn ⟨(-n - 2).toNat, by simp; omega⟩
      simp [this]

-- f(z) = 1/(z(z - 1)): at z = 1/2 it is -4, at z = 2 it is 1/2.
example : (1 : ℚ) / ((1 / 2) * (1 / 2 - 1)) = -4 := by norm_num
example : (1 : ℚ) / (2 * (2 - 1)) = 1 / 2 := by norm_num

-- Partial fractions at z = 2: 1/(z - 1) - 1/z = 1 - 1/2 = 1/2.
example : (1 : ℚ) / (2 - 1) - 1 / 2 = 1 / 2 := by norm_num

-- Inner series at 1/2, five terms: -2 - 1 - 1/2 - 1/4 - 1/8 = -31/8 (-3.875);
-- the tail -z^4/(1 - z) = -(1/16)/(1/2) = -1/8 closes the gap to -4.
example : (-2 : ℚ) - 1 - 1 / 2 - 1 / 4 - 1 / 8 = -31 / 8 := by norm_num
example : -((1 / 2 : ℚ) ^ 4) / (1 - 1 / 2) = -1 / 8 := by norm_num
example : (-31 / 8 : ℚ) + (-1 / 8) = -4 := by norm_num

-- Outer series at 2, five terms: 1/4 + 1/8 + 1/16 + 1/32 + 1/64 = 31/64 (0.484375);
-- the tail 2^(-7)/(1 - 1/2) = 1/64 closes the gap to 1/2.
example : (1 / 4 : ℚ) + 1 / 8 + 1 / 16 + 1 / 32 + 1 / 64 = 31 / 64 := by norm_num
example : ((1 : ℚ) / 2 ^ 7) / (1 - 1 / 2) = 1 / 64 := by norm_num
example : (31 / 64 : ℚ) + 1 / 64 = 1 / 2 := by norm_num

-- Mistake 1: five inner terms at z = 2 give -1/2 - 1 - 2 - 4 - 8 = -31/2 (-15.5), not 1/2.
example : (-1 / 2 : ℚ) - 1 - 2 - 4 - 8 = -31 / 2 := by norm_num
-- Mistake 2: five outer terms at z = 1/2 give 4 + 8 + 16 + 32 + 64 = 124, not -4.
example : (4 : ℚ) + 8 + 16 + 32 + 64 = 124 := by norm_num

-- e^z/z^3: the 1/z coefficient is 1/2! = 1/2, not 1/3! = 1/6 (mistake 3).
example : (1 : ℚ) / (Nat.factorial 2) = 1 / 2 := by norm_num [Nat.factorial]
example : (1 : ℚ) / (Nat.factorial 3) = 1 / 6 := by norm_num [Nat.factorial]

#print axioms holomorphic_on_annulus_has_unique_laurent_series
#print axioms laurent_coeff_eq_circle_integral
#print axioms laurent_series_of_inv_z_mul_z_sub_one_inside_and_outside
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'laurentAux_coeff' depends on axioms: [propext, Classical.choice, Quot.sound]
'laurentAux_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
'laurentAux_cauchy' depends on axioms: [propext, Classical.choice, Quot.sound]
'laurentAux_diffAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'laurentAux_indep' depends on axioms: [propext, Classical.choice, Quot.sound]
'laurentAux_exists' depends on axioms: [propext, Classical.choice, Quot.sound]
'holomorphic_on_annulus_has_unique_laurent_series' depends on axioms: [propext, Classical.choice, Quot.sound]
'laurent_coeff_eq_circle_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'laurent_series_of_inv_z_mul_z_sub_one_inside_and_outside' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Forget the 1/z term.** Change the inner rule to `n >= 0`. The circle averages still read c[-1] as −1, so the first assert stops the run.
> - **One more power down.** Change `z**3` to `z**4` in `g`. The loop reads c[-1] as 0.166667 and the third assert stops it.
> - **A smaller circle.** Change every 0.5 on the error line to 0.25. Each error roughly squares, as 0.25^m = (0.5^m)^2; the asserts pass.

---

## The usual mistake

> [!warning]
> **A Laurent series without its ring is not an answer.** About 0, 1/(z(z − 1)) has two series whose 1/z coefficients disagree: −1 inside the unit circle, 0 outside. Each is right only in its own ring.
>
> - **Summing outside the ring.** Five inner terms at z = 2 give −15.5, not 0.5; five outer terms at z = 0.5 give 124, not −4.
> - **Losing the shift.** The 1/z coefficient of e^z/z^3 is 1/2!, not 1/3!: 0.5, not 0.166667.
> - **Judging the centre from the wrong ring.** The outer series has endless negative powers, yet 0 is a mild bad point; only a ring 0 < |z − a| < R speaks for a: [Isolated singularities](02-classifying-singularities.md).

---

## Where you meet it in real life

- **Digital filters.** A sampled signal's z-transform is a Laurent series, and its ring decides the signal: 1/(z − 1) outside and inside the unit circle are two different signals ([The z-transform](../../13-Engineering%20mathematics/02-Linear%20Systems%20and%20Transforms/08-z-transform-and-discrete-time-systems.md)).
- **Contour integrals.** A loop integral sees only $c_{-1}$: e^z/z^3 round the unit circle gives 2πi times 1/2, or 3.141593i ([The residue theorem](05-the-residue-theorem.md)).
- **Matrices.** For large z, the inverse of z − A is 1/z + A/z^2 + A^2/z^3 + …, the outer series with a matrix A in place of 1 (Spectrum).

> **Say it back**
> A Laurent series allows negative powers, so it can describe a function round a hole. It converges on a ring bounded by circles through the bad points. On a given ring it is unique, since each coefficient is a loop integral. About 0, 1/(z(z − 1)) is −1/z − 1 − z − … inside the unit circle and 1/z^2 + 1/z^3 + … outside. The 1/z coefficient of e^z/z^3 is 1/2.

---

## What this builds on

- [Taylor series in the plane](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/01-taylor-series-in-the-plane.md): the one-sided series, Cauchy's integral formula, and the series for e^z.
- [Deforming a loop](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/04-deforming-contours-and-winding-numbers.md): why a loop integral stays put as the circle moves within the ring.
- [Infinite series](../../06-Calculus%20and%20analysis/06-Series/01-series-convergence.md): the geometric series and when a sum converges.

## Where this goes next

- [Isolated singularities](02-classifying-singularities.md): the principal part sorts bad points into kinds.
- [The z-transform](../../13-Engineering%20mathematics/02-Linear%20Systems%20and%20Transforms/08-z-transform-and-discrete-time-systems.md): the ring as a region of convergence.
- [Pade approximants](../../16-Numerical%20analysis/04-Interpolation%20and%20Approximation/09-pade-and-rational-approximation.md): fractions matched to series.
- Spectrum: the outer series for operators.
- Divisors and Riemann-Roch: the lowest power as a zero's or pole's order.

The question this card leaves open: on the ring 0 < |z − a| < R, what do the negative powers say about the bad point a itself?

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Lebl, Jiří. *Guide to Cultivating Complex Analysis: Working the Complex Field*. [Book page and free PDF](https://www.jirka.org/ca/). Section 4.4 proves existence on an annulus.
- Orloff, Jeremy. *18.04 Complex Variables with Applications*, Spring 2018, MIT OpenCourseWare. [Lecture notes](https://ocw.mit.edu/courses/18-04-complex-variables-with-applications-spring-2018/pages/lecture-notes/). Topic 7 treats Taylor and Laurent series.
- O'Connor, J. J., and E. F. Robertson. "Pierre Alphonse Laurent." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Laurent_Pierre/). Cauchy's 1843 report on Laurent's memoir.
