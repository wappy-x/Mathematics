# Bessel's equation: the drum's answer is a new function whose zeros set the drum's notes

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Series Solutions and Boundary Problems](../README.md#s07) → Bessel's equation

---

## General Overview

A timpani head is a round plastic sheet, 0.3 m in radius, clamped at the rim of a kettle. Waves cross it at 100 m/s, a speed set by its tension and its mass per square metre. Modelled as a thin sheet with no air behind it, its round notes are 127.6 Hz (vibrations per second), 292.8 Hz and 459.1 Hz.

A string with that lowest note would add 255.2 Hz and 382.7 Hz, two and three times it: a whole-number ladder, heard as one clear pitch. A string's notes come from sin(nπx), whose zeros are evenly spaced. The drum's come from the zeros of a new curve, which are not: 2.295 and 3.598 times the fundamental.

The Frobenius method builds that curve as a power series, J0, Bessel's function of order zero. Its first three zeros, 2.404826, 5.520078 and 8.653728, found numerically, fix the three lowest round notes.

**A pure note of a round drum has the shape J0(kr), the one solution of Bessel's equation that stays finite at the centre; clamping the rim forces kR onto a zero of J0, and those zeros are not in whole-number ratio.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; the zeros are computed, and their spacing rule is an approximation.

### The picture: the head's shape in its three lowest round notes

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Timpani head, radius 30 cm: height across a radius"
    x-axis "Distance from the centre, in cm" [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30]
    y-axis "Height, as a fraction of the centre's" -0.5 --> 1
    line [1.00, 0.99, 0.94, 0.87, 0.78, 0.67, 0.54, 0.41, 0.27, 0.13, 0.00]
    line [1.00, 0.93, 0.72, 0.42, 0.11, -0.17, -0.35, -0.40, -0.34, -0.19, 0.00]
    line [1.00, 0.82, 0.38, -0.09, -0.37, -0.36, -0.11, 0.17, 0.30, 0.22, 0.00]
```

Orange: the fundamental, 127.6 Hz. Teal: 292.8 Hz, one still circle inside the rim. Dark blue: 459.1 Hz, two. Each is J0 stretched so its first, second or third zero lands on the rim.

---

## The formula

Reminder: a differential equation links a function to its own rates ([A differential equation](../01-Rate%20Equations/01-what-a-differential-equation-says.md)); here the rates run outward from the centre.

Bessel's equation of order zero, and its solution equal to 1 at the centre:

$$x^2 y'' + x\,y' + x^2 y = 0, \qquad J_0(x) = \sum_{m=0}^{\infty} \frac{(-1)^m\, x^{2m}}{4^m\,(m!)^2} = 1 - \frac{x^2}{4} + \frac{x^4}{64} - \frac{x^6}{2304} + \cdots$$

**Read it aloud:** start at 1; each term is the last times minus x squared, over four times the term's number squared.

The drum's notes:

$$f_n = \frac{c\, j_n}{2\pi R}$$

**Read it aloud:** the n-th round note is the wave speed times the n-th zero of J0, over the rim's circumference.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $r$, $R$ | distance from the centre; the rim's radius | 0 to 0.3 m; R = 0.3 m | R up: every note falls |
| $w$ | the head's height in a pure note, as a fraction of the centre's | 1 at the centre, 0 at the rim | — |
| $f$, $c$ | a note's frequency, in Hz; the speed of waves across the head | 127.6 Hz; 100 m/s | c up: notes rise, ratios fixed |
| $k$ | 2πf/c, radians of wave per metre | j_n/R for note n | — |
| $x$, $y$ | the scaled distance kr, a pure number; the shape in terms of x | 0 to 2.404826 for the fundamental | — |
| $s$, $a_n$ | the Frobenius trial power; the coefficient of x^n | s = 0; a_2 = −1/4 | — |
| $J_0$ | the series solution, 1 at the centre: Bessel's function of order zero | J0(2.4) = 0.002508 | — |
| $j_n$ | the n-th zero of J0 | 2.404826, 5.520078, 8.653728 | later zeros space out by about π |

m counts terms; m! is 1 × 2 × … × m.

### When it holds

- **A uniform head at even tension**, so c is the same everywhere; otherwise J0 does not describe it.
- **Round notes only**: shapes that depend on distance, not direction. Notes with a still diameter solve Bessel's equations of higher order, with solutions J1, J2 and so on.
- **Small swings.** A hard strike stretches the head and raises its tension, so the notes rise with loudness.
- **A thin head in empty space.** Stiffness and the kettle's air shift real notes.

---

## Why it works

### Step 0: a note is a shape that keeps its form

In a pure note every point swings in step: height w(r) times cos(2πft), t the time in s. Which shapes and which f does a clamped round head allow?

### Step 1: forces on a ring give the equation

Cut the head into thin rings. Tension pulls each ring from inside and outside. The pull scales with slope times edge length, r w'; where that changes across the ring, the pulls fail to cancel and drive it. Force equals mass times acceleration:

$$w'' + \frac{1}{r}\,w' + k^2 w = 0, \qquad k = \frac{2\pi f}{c}.$$

The middle term is what a string lacks: an outer ring is longer.

<details>
<summary>The ring balance</summary>

Take the ring between r and r + dr. Tension T (newtons per metre of edge) has upward part T w' per metre, over 2πr metres: 2πT r w'. The net upward force is its change across dr, 2πT (r w')' dr. The ring's mass is σ 2πr dr, σ the mass per square metre, and its acceleration is −(2πf)^2 times its height. So T (r w')' = −σ (2πf)^2 r w. Expand (r w')' = r w'' + w', divide by T r, and write c^2 = T/σ.

</details>

Measure distance as x = kr, a pure number. Each rate picks up a factor k, cancelling the k^2; multiplying by x^2 gives Bessel's equation.

### Step 2: the centre is a regular singular point, so try Frobenius

Divided by x^2 the equation reads y'' + y'/x + y = 0. The 1/x blows up at the centre, but no faster than 1/x: a regular singular point, where [Frobenius](02-frobenius-and-regular-singular-points.md) tries a power x^s times a power series:

$$y = \sum_{n \ge 0} a_n\, x^{n+s}.$$

Put it in. The x^2 y'' and x y' terms give (n + s)^2 a_n x^(n+s); the x^2 y term shifts each power up by two. Matching powers:

- lowest, n = 0: s^2 a_0 = 0, so s = 0 twice (the indicial equation);
- n = 1: a_1 = 0;
- every later n: n^2 a_n = −a_(n−2).

Odd coefficients vanish; with a_0 = 1, a_2 = −1/4, a_4 = 1/64, a_6 = −1/2304, a_8 = 1/147456.

### Step 3: the series converges everywhere and solves the equation

Each term is the last times x^2/(4m^2) in size. For fixed x that factor drops below 1/2 once m is large, so the tail is below a halving series: the sum converges for every x. A convergent power series may be differentiated term by term, and the recurrence cancels every power.

### Step 4: the centre rules out the other solution

A second-order equation has two independent solutions. A double indicial root forces the second to carry a logarithm (the Frobenius card): J0(x) ln x plus a series, named Y0 once normalised. It falls without bound at x = 0. A drumhead's centre has finite height, so its shape is a constant times J0(kr).

### Step 5: the clamped rim picks the notes

At the rim the height is zero: J0(kR) = 0. So kR is a zero j_n, and since k = 2πf/c, f_n = c j_n/(2πR). J0(2.4) = 0.002508 and J0(2.41) = −0.002683 bracket the first zero; halving the bracket over and over pins it at 2.404826. Scanning x in steps of 0.1 for sign changes finds 5.520078 and 8.653728.

### Step 6: why the zeros are not evenly spaced

Write y = u/√x. Bessel's equation becomes

$$u'' + \left(1 + \frac{1}{4x^2}\right) u = 0.$$

Far out the 1/(4x^2) is tiny, u behaves like a sine wave, and zeros settle to a spacing of π. Near the centre that term shifts where the wave starts. The zeros come out near (n − 1/4)π: 2.356, 5.498, 8.639, with ratios (4n − 1)/3, that is 2.333 and 3.667, not 2 and 3. The quarter-step offset puts the drum out of tune with itself.

<details>
<summary>Detailed proof: the substitution, and what is stated without proof</summary>

With y = u x^(−1/2): y' = u' x^(−1/2) − (1/2) u x^(−3/2) and y'' = u'' x^(−1/2) − u' x^(−3/2) + (3/4) u x^(−5/2). Then x^2 y'' + x y' + x^2 y = x^(3/2) [u'' + u + u/(4x^2)]: the u' terms cancel.

Not proved here: the phase. J0(x) ≈ √(2/(πx)) cos(x − π/4) for large x (DLMF §10.17). McMahon's correction puts the n-th zero near β + 1/(8β), with β = (n − 1/4)π: 2.4092, 5.5205, 8.6538. The code checks each lies within 0.005 of the computed zero.

</details>

A second road uses no series: Runge-Kutta 4 ([Runge-Kutta four](../05-Numerical%20Evolution/04-runge-kutta-four.md)) steps the equation out from height 1 and slope 0. At x = 0, y'/x is replaced by its limit y''(0), which makes y''(0) = −y(0)/2.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| indicial equation | lowest power: s^2 a_0 = 0 | s = 0, twice |
| coefficients | a_n = −a_(n−2)/n^2 from a_0 = 1 | −1/4, 1/64, −1/2304, 1/147456 |
| J0(2.4) | 1 − 1.440000 + 0.518400 − 0.082944 + 0.007465 − 0.000430 + 0.000017 | 0.002508 |
| J0(2.41) | the same sum | −0.002683 |
| first zero | halve the bracket until it stops moving | **2.404826** |
| fundamental | 100 × 2.404826 / (2π × 0.3) | **127.6 Hz** |
| overtones | the same with 5.520078 and 8.653728 | **292.8 Hz, 459.1 Hz** |
| ratios | 5.520078 / 2.404826, 8.653728 / 2.404826 | **2.295, 3.598** |

No whole-number ladder: a coloured thud, not a clear pitch.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Overtones assumed to be whole multiples | 255.2 and 382.7 Hz, not 292.8 and 459.1 | a string's pattern, not a drum's |
| The y'/x term dropped | cos x: zeros 1.571, 4.712, 7.854, fundamental 83.3 Hz; in the real equation at x = 1.5 it leaves −1.496 | ignores the rings' growing circumference |
| Only four terms of the series kept | 1 zero below 10, at 2.392 | −x^6/2304 takes over; the curve never returns |

---

## Code, from first principles, and it actually runs

Road one sums the series and bisects each sign change. Road two steps the equation by Runge-Kutta 4 at three step lengths; its gap to road one shrinks about sixteenfold per halving.

### Python

```python
# Bessel's equation and the drum -- the check behind the card.  Standard library only.  A timpani
# head, radius 0.3 m, wave speed 100 m/s.  A pure note's shape y(x), x = k r, obeys x^2 y'' + x y' + x^2 y = 0.
# Road one: the Frobenius series J0, zeros by bisection.  Road two: Runge-Kutta 4 out from the centre.
import math
R, C = 0.3, 100.0                          # drum radius (m), wave speed on the head (m/s)
def terms(x, n, wrong=False):              # a_n = -a_(n-2) / n^2; wrong: n(n - 1), y'/x dropped
    out = [1.0]
    for k in range(1, n): out.append(out[-1] * -x * x / ((2 * k) * (2 * k - 1) if wrong else 4 * k * k))
    return out

series = lambda x, n=40, wrong=False: sum(terms(x, n, wrong))
def bisect(f, lo, hi):
    for _ in range(80): lo, hi = ((lo + hi) / 2, hi) if f(lo) * f((lo + hi) / 2) > 0 else (lo, (lo + hi) / 2)
    return (lo + hi) / 2
def zeros(f, xmax=10.0, step=0.1):         # every sign change of f below xmax, refined
    return [bisect(f, i * step, (i + 1) * step) for i in range(int(xmax / step)) if f(i * step) * f((i + 1) * step) < 0]
def rk4(x, y, v, h):                       # one step of y'' = -y'/x - y; at x = 0, y'' = -y/2
    f = lambda x, y, v: (v, -y / 2 if x == 0 else -v / x - y)
    k1 = f(x, y, v); k2 = f(x + h / 2, y + h / 2 * k1[0], v + h / 2 * k1[1])
    k3 = f(x + h / 2, y + h / 2 * k2[0], v + h / 2 * k2[1]); k4 = f(x + h, y + h * k3[0], v + h * k3[1])
    return y + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]), v + h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
def rk4_zeros(h, xmax=10.0):               # step out from y(0) = 1, y'(0) = 0; refine each crossing
    x, y, v, found = 0.0, 1.0, 0.0, []
    while x < xmax - h / 2:
        y2, v2 = rk4(x, y, v, h)
        if y * y2 < 0: found.append(x + bisect(lambda s: rk4(x, y, v, s)[0], 0.0, h))
        x, y, v = x + h, y2, v2
    return found
row = lambda vals, p: " ".join(f"{round(v, p) + 0.0:.{p}f}" for v in vals)
resid = lambda g, x, h=1e-3: x * x * (g(x + h) - 2 * g(x) + g(x - h)) / h ** 2 + x * (g(x + h) - g(x - h)) / (2 * h) + x * x * g(x)
print("indicial s^2 = 0: double root s = 0; a1 = 0; a2, a4, a6, a8 = -1/4, 1/64, -1/2304, 1/147456")
print(f"J0 put into the equation at x = 1.5, rates by differences: residual below 1e-5: {'yes' if abs(resid(series, 1.5)) < 1e-5 else 'no'}")
print("hand check, terms at x = 2.4:", row(terms(2.4, 7), 6), f"; J0(2.4) = {series(2.4):.6f}, J0(2.41) = {series(2.41):.6f}")
js = zeros(series)
print("zeros, series and bisection:", row(js, 6))
errs = []
for h in (0.2, 0.1, 0.05):
    rz = rk4_zeros(h)
    errs.append(max(abs(a - b) for a, b in zip(rz, js)))
    print(f"zeros, RK4 from the centre, h = {h:.2f}:", row(rz, 6), f"; worst error {errs[-1] * 1e6:.2f} millionths")
print(f"error ratio when h halves: {errs[0] / errs[1]:.1f}, {errs[1] / errs[2]:.1f}")
beta = [(n - 0.25) * math.pi for n in (1, 2, 3)]
print("overtone ratios j2/j1, j3/j1:", row([j / js[0] for j in js[1:]], 3), "; large-x estimate (n - 1/4) pi:", row(beta, 3),
      "; its ratios", row([b / beta[0] for b in beta[1:]], 3), "; with 1/(8 beta) added:", row([b + 1 / (8 * b) for b in beta], 4))
fs = [C * j / (2 * math.pi * R) for j in js]
print(f"timpani R = {R} m, c = {C:.0f} m/s: notes", row(fs, 1), "Hz")
print("figure, r (cm):", " ".join(f"{3 * i:5d}" for i in range(11)))
for n in range(3): print(f"figure, mode {n + 1}: ", " ".join(f"{round(series(js[n] * i / 10), 2) + 0.0:5.2f}" for i in range(11)))
print(f"mistake, harmonic overtones: {2 * fs[0]:.1f} and {3 * fs[0]:.1f} Hz, not {fs[1]:.1f} and {fs[2]:.1f}")
cz = zeros(lambda x: series(x, wrong=True))
print("mistake, y'/x dropped (cos x): zeros", row(cz, 3), "; ratios", row([z / cz[0] for z in cz[1:]], 3),
      f"; fundamental {C * cz[0] / (2 * math.pi * R):.1f} Hz; cos x in J0's equation at 1.5: {resid(math.cos, 1.5):.3f}")
tz = zeros(lambda x: series(x, 4))
print(f"mistake, 4 terms of the series: {len(tz)} zero below 10, at {tz[0]:.3f}")
assert errs[-1] < 5e-7                                                         # two roads, one set of zeros
assert 10 < errs[0] / errs[1] < 22 and 10 < errs[1] / errs[2] < 22          # the gap shrinks at fourth order
assert abs(resid(series, 1.5)) < 1e-5 and abs(resid(math.cos, 1.5)) > 1     # J0 solves it, cos x does not
assert all(abs(j - b - 1 / (8 * b)) < 0.005 for j, b in zip(js, beta))     # large-x estimate agrees
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
indicial s^2 = 0: double root s = 0; a1 = 0; a2, a4, a6, a8 = -1/4, 1/64, -1/2304, 1/147456
J0 put into the equation at x = 1.5, rates by differences: residual below 1e-5: yes
hand check, terms at x = 2.4: 1.000000 -1.440000 0.518400 -0.082944 0.007465 -0.000430 0.000017 ; J0(2.4) = 0.002508, J0(2.41) = -0.002683
zeros, series and bisection: 2.404826 5.520078 8.653728
zeros, RK4 from the centre, h = 0.20: 2.404827 5.520115 8.653807 ; worst error 78.59 millionths
zeros, RK4 from the centre, h = 0.10: 2.404825 5.520080 8.653732 ; worst error 4.56 millionths
zeros, RK4 from the centre, h = 0.05: 2.404826 5.520078 8.653728 ; worst error 0.28 millionths
error ratio when h halves: 17.2, 16.5
overtone ratios j2/j1, j3/j1: 2.295 3.598 ; large-x estimate (n - 1/4) pi: 2.356 5.498 8.639 ; its ratios 2.333 3.667 ; with 1/(8 beta) added: 2.4092 5.5205 8.6538
timpani R = 0.3 m, c = 100 m/s: notes 127.6 292.8 459.1 Hz
figure, r (cm):     0     3     6     9    12    15    18    21    24    27    30
figure, mode 1:   1.00  0.99  0.94  0.87  0.78  0.67  0.54  0.41  0.27  0.13  0.00
figure, mode 2:   1.00  0.93  0.72  0.42  0.11 -0.17 -0.35 -0.40 -0.34 -0.19  0.00
figure, mode 3:   1.00  0.82  0.38 -0.09 -0.37 -0.36 -0.11  0.17  0.30  0.22  0.00
mistake, harmonic overtones: 255.2 and 382.7 Hz, not 292.8 and 459.1
mistake, y'/x dropped (cos x): zeros 1.571 4.712 7.854 ; ratios 3.000 5.000 ; fundamental 83.3 Hz; cos x in J0's equation at 1.5: -1.496
mistake, 4 terms of the series: 1 zero below 10, at 2.392
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Bessel's equation and the drum -- the same check as the Python, in Rust.  No crates.  A timpani
// head, radius 0.3 m, wave speed 100 m/s.  A pure note's shape y(x), x = k r, obeys x^2 y'' + x y' + x^2 y = 0.
// Road one: the Frobenius series J0, zeros by bisection.  Road two: Runge-Kutta 4 out from the centre.
use std::f64::consts::PI;
const R: f64 = 0.3; const C: f64 = 100.0;              // drum radius (m), wave speed on the head (m/s)

fn terms(x: f64, n: usize, wrong: bool) -> Vec<f64> {  // a_n = -a_(n-2) / n^2; wrong: n(n - 1), y'/x dropped
    let mut out = vec![1.0];
    for k in 1..n { let d = if wrong { (2 * k * (2 * k - 1)) as f64 } else { (4 * k * k) as f64 }; out.push(out[k - 1] * -x * x / d); }
    out
}
fn series(x: f64) -> f64 { terms(x, 40, false).iter().sum() }
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..80 { let mid = (lo + hi) / 2.0; if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn zeros(f: &dyn Fn(f64) -> f64) -> Vec<f64> {         // every sign change of f below 10, refined
    (0..100).map(|i| i as f64 * 0.1).filter(|&a| f(a) * f(a + 0.1) < 0.0).map(|a| bisect(f, a, a + 0.1)).collect()
}
fn rk4(x: f64, y: f64, v: f64, h: f64) -> (f64, f64) { // one step of y'' = -y'/x - y; at x = 0, y'' = -y/2
    let f = |x: f64, y: f64, v: f64| (v, if x == 0.0 { -y / 2.0 } else { -v / x - y });
    let k1 = f(x, y, v); let k2 = f(x + h / 2.0, y + h / 2.0 * k1.0, v + h / 2.0 * k1.1);
    let k3 = f(x + h / 2.0, y + h / 2.0 * k2.0, v + h / 2.0 * k2.1); let k4 = f(x + h, y + h * k3.0, v + h * k3.1);
    (y + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0), v + h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1))
}
fn rk4_zeros(h: f64) -> Vec<f64> {                     // step out from y(0) = 1, y'(0) = 0; refine each crossing
    let (mut x, mut y, mut v, mut found) = (0.0, 1.0, 0.0, Vec::new());
    while x < 10.0 - h / 2.0 {
        let (y2, v2) = rk4(x, y, v, h);
        if y * y2 < 0.0 { found.push(x + bisect(&|s| rk4(x, y, v, s).0, 0.0, h)); }
        x += h; y = y2; v = v2;
    }
    found
}
fn fx(v: f64, p: usize, w: usize) -> String {          // fixed decimals, no "-0.00"
    let s = format!("{:w$.p$}", v, w = w, p = p);
    if s.trim_start_matches(|c: char| c == ' ' || c == '-').chars().all(|c| c == '0' || c == '.') { format!("{:w$.p$}", 0.0, w = w, p = p) } else { s }
}
fn row(vals: &[f64], p: usize) -> String { vals.iter().map(|&v| fx(v, p, 0)).collect::<Vec<_>>().join(" ") }
fn resid(g: &dyn Fn(f64) -> f64, x: f64) -> f64 {
    let h = 1e-3;
    x * x * (g(x + h) - 2.0 * g(x) + g(x - h)) / (h * h) + x * (g(x + h) - g(x - h)) / (2.0 * h) + x * x * g(x)
}

fn main() {
    println!("indicial s^2 = 0: double root s = 0; a1 = 0; a2, a4, a6, a8 = -1/4, 1/64, -1/2304, 1/147456");
    println!("J0 put into the equation at x = 1.5, rates by differences: residual below 1e-5: {}", if resid(&series, 1.5).abs() < 1e-5 { "yes" } else { "no" });
    println!("hand check, terms at x = 2.4: {} ; J0(2.4) = {:.6}, J0(2.41) = {:.6}", row(&terms(2.4, 7, false), 6), series(2.4), series(2.41));
    let js = zeros(&series);
    println!("zeros, series and bisection: {}", row(&js, 6));
    let mut errs: Vec<f64> = Vec::new();
    for h in [0.2, 0.1, 0.05] {
        let rz = rk4_zeros(h);
        errs.push(rz.iter().zip(&js).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max));
        println!("zeros, RK4 from the centre, h = {:.2}: {} ; worst error {:.2} millionths", h, row(&rz, 6), errs[errs.len() - 1] * 1e6);
    }
    println!("error ratio when h halves: {:.1}, {:.1}", errs[0] / errs[1], errs[1] / errs[2]);
    let beta: Vec<f64> = (1..=3).map(|n| (n as f64 - 0.25) * PI).collect();
    let ratios: Vec<f64> = js[1..].iter().map(|j| j / js[0]).collect();
    let bratios: Vec<f64> = beta[1..].iter().map(|b| b / beta[0]).collect();
    let mcm: Vec<f64> = beta.iter().map(|b| b + 1.0 / (8.0 * b)).collect();
    println!("overtone ratios j2/j1, j3/j1: {} ; large-x estimate (n - 1/4) pi: {} ; its ratios {} ; with 1/(8 beta) added: {}", row(&ratios, 3), row(&beta, 3), row(&bratios, 3), row(&mcm, 4));
    let fs: Vec<f64> = js.iter().map(|j| C * j / (2.0 * PI * R)).collect();
    println!("timpani R = {} m, c = {:.0} m/s: notes {} Hz", R, C, row(&fs, 1));
    println!("figure, r (cm): {}", (0..11).map(|i| format!("{:5}", 3 * i)).collect::<Vec<_>>().join(" "));
    for n in 0..3 { println!("figure, mode {}:  {}", n + 1, (0..11).map(|i| fx(series(js[n] * i as f64 / 10.0), 2, 5)).collect::<Vec<_>>().join(" ")); }
    println!("mistake, harmonic overtones: {:.1} and {:.1} Hz, not {:.1} and {:.1}", 2.0 * fs[0], 3.0 * fs[0], fs[1], fs[2]);
    let cz = zeros(&|x| terms(x, 40, true).iter().sum());
    let cr: Vec<f64> = cz[1..].iter().map(|z| z / cz[0]).collect();
    println!("mistake, y'/x dropped (cos x): zeros {} ; ratios {} ; fundamental {:.1} Hz; cos x in J0's equation at 1.5: {:.3}", row(&cz, 3), row(&cr, 3), C * cz[0] / (2.0 * PI * R), resid(&|x: f64| x.cos(), 1.5));
    let tz = zeros(&|x| terms(x, 4, false).iter().sum());
    println!("mistake, 4 terms of the series: {} zero below 10, at {:.3}", tz.len(), tz[0]);
    assert!(errs[errs.len() - 1] < 5e-7);                                            // two roads, one set of zeros
    assert!(10.0 < errs[0] / errs[1] && errs[0] / errs[1] < 22.0 && 10.0 < errs[1] / errs[2] && errs[1] / errs[2] < 22.0);
    assert!(resid(&series, 1.5).abs() < 1e-5 && resid(&|x: f64| x.cos(), 1.5).abs() > 1.0);   // J0 solves it, cos x does not
    assert!(js.iter().zip(&beta).all(|(j, b)| (j - b - 1.0 / (8.0 * b)).abs() < 0.005));     // large-x estimate agrees
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
indicial s^2 = 0: double root s = 0; a1 = 0; a2, a4, a6, a8 = -1/4, 1/64, -1/2304, 1/147456
J0 put into the equation at x = 1.5, rates by differences: residual below 1e-5: yes
hand check, terms at x = 2.4: 1.000000 -1.440000 0.518400 -0.082944 0.007465 -0.000430 0.000017 ; J0(2.4) = 0.002508, J0(2.41) = -0.002683
zeros, series and bisection: 2.404826 5.520078 8.653728
zeros, RK4 from the centre, h = 0.20: 2.404827 5.520115 8.653807 ; worst error 78.59 millionths
zeros, RK4 from the centre, h = 0.10: 2.404825 5.520080 8.653732 ; worst error 4.56 millionths
zeros, RK4 from the centre, h = 0.05: 2.404826 5.520078 8.653728 ; worst error 0.28 millionths
error ratio when h halves: 17.2, 16.5
overtone ratios j2/j1, j3/j1: 2.295 3.598 ; large-x estimate (n - 1/4) pi: 2.356 5.498 8.639 ; its ratios 2.333 3.667 ; with 1/(8 beta) added: 2.4092 5.5205 8.6538
timpani R = 0.3 m, c = 100 m/s: notes 127.6 292.8 459.1 Hz
figure, r (cm):     0     3     6     9    12    15    18    21    24    27    30
figure, mode 1:   1.00  0.99  0.94  0.87  0.78  0.67  0.54  0.41  0.27  0.13  0.00
figure, mode 2:   1.00  0.93  0.72  0.42  0.11 -0.17 -0.35 -0.40 -0.34 -0.19  0.00
figure, mode 3:   1.00  0.82  0.38 -0.09 -0.37 -0.36 -0.11  0.17  0.30  0.22  0.00
mistake, harmonic overtones: 255.2 and 382.7 Hz, not 292.8 and 459.1
mistake, y'/x dropped (cos x): zeros 1.571 4.712 7.854 ; ratios 3.000 5.000 ; fundamental 83.3 Hz; cos x in J0's equation at 1.5: -1.496
mistake, 4 terms of the series: 1 zero below 10, at 2.392
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's main theorem for every x, along with the Frobenius and substitution steps behind it.

- The series for J0 converges for every x, equals 1 at the centre, and solves Bessel's equation everywhere.
- Take any solution of Bessel's equation from the centre out to some x. If it stays finite near the centre, it is a constant times J0.
- With a_0 = 1, the rules a_1 = 0 and n^2 a_n = −a_(n−2) have exactly one answer: J0's coefficients.
- Writing y = u/√x turns Bessel's equation into u'' + (1 + 1/(4x^2)) u = 0 for every x above 0.
- The hand arithmetic holds exactly: a_2 to a_8, the denominators 4, 64, 2304 and 147456, and the estimate's ratios 7/3 and 11/3.

The zeros of J0, the notes in Hz, the Runge-Kutta 4 runs and the figure are left to the Python and Rust checks.

```lean
-- Bessel's equation: the series J0 converges everywhere, equals 1 at the centre and solves x²y'' + xy' + x²y = 0, every solution that stays bounded at the centre is a constant times J0, its coefficients are forced by the Frobenius recurrence, and the substitution y = u/√x turns the equation into u'' + (1 + 1/(4x²))u = 0.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Deriv

open Set

namespace BesselDrum

/-- The m-th term of the card's series for J0: (-1)^m x^(2m) / (4^m (m!)^2). -/
noncomputable def J0Term (m : ℕ) (x : ℝ) : ℝ :=
  (-1) ^ m * x ^ (2 * m) / (4 ^ m * (m.factorial : ℝ) ^ 2)

/-- Bessel's function of order zero, as the card defines it: the sum of the series
1 - x²/4 + x⁴/64 - x⁶/2304 + ⋯. -/
noncomputable def J0 (x : ℝ) : ℝ := ∑' m : ℕ, J0Term m x

/-- The Frobenius coefficient a_n of x^n in J0: zero for odd n, and
(-1)^m / (4^m (m!)^2) for n = 2m. -/
noncomputable def besselCoeff (n : ℕ) : ℝ :=
  if Even n then (-1) ^ (n / 2) / (4 ^ (n / 2) * ((n / 2).factorial : ℝ) ^ 2) else 0

/-- Helper: first termwise derivative. -/

noncomputable def bdD1 (m : ℕ) (x : ℝ) : ℝ :=
  (-1) ^ m * ((2 * m : ℕ) : ℝ) * x ^ (2 * m - 1) / (4 ^ m * (m.factorial : ℝ) ^ 2)
#print axioms bdD1

/-- Helper: second termwise derivative. -/

noncomputable def bdD2 (m : ℕ) (x : ℝ) : ℝ :=
  (-1) ^ m * ((2 * m : ℕ) : ℝ) * ((2 * m - 1 : ℕ) : ℝ) * x ^ (2 * m - 1 - 1) /
    (4 ^ m * (m.factorial : ℝ) ^ 2)
#print axioms bdD2

/-- Helper: a uniform bound for the terms. -/

theorem bd_key (m k N : ℕ) (hk : k ≤ 2 * m) (hN : N ≤ 4 * 4 ^ m) (S x : ℝ) (hS : 1 ≤ S)
    (hx : |x| ≤ S) :
    |(-1) ^ m * (N : ℝ) * x ^ k / (4 ^ m * (m.factorial : ℝ) ^ 2)| ≤
      4 * (S ^ 2) ^ m / m.factorial := by
  have hf : (1 : ℝ) ≤ m.factorial := by exact_mod_cast Nat.one_le_iff_ne_zero.mpr (Nat.factorial_ne_zero m)
  have h4 : (0 : ℝ) < 4 ^ m := by positivity
  rw [abs_div, abs_mul, abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul, abs_pow,
    abs_of_pos (by positivity : (0 : ℝ) < 4 ^ m * (m.factorial : ℝ) ^ 2), Nat.abs_cast]
  have hxk : |x| ^ k ≤ S ^ (2 * m) :=
    (pow_le_pow_left₀ (abs_nonneg x) hx k).trans (pow_le_pow_right₀ hS hk)
  have hN' : (N : ℝ) ≤ 4 * 4 ^ m := by exact_mod_cast hN
  rw [div_le_div_iff₀ (by positivity) (by positivity), ← pow_mul]
  have hS0 : 0 ≤ S ^ (2 * m) := by positivity
  calc (N : ℝ) * |x| ^ k * m.factorial ≤ (4 * 4 ^ m) * S ^ (2 * m) * m.factorial := by
        gcongr
    _ ≤ 4 * S ^ (2 * m) * (4 ^ m * (m.factorial : ℝ) ^ 2) := by
        have : (m.factorial : ℝ) ≤ (m.factorial : ℝ) ^ 2 := by nlinarith
        have h2 : 0 ≤ 4 * S ^ (2 * m) * 4 ^ m := by positivity
        nlinarith
#print axioms bd_key

theorem bd_sq_le (m : ℕ) : m * m ≤ 4 ^ m := by
  have := Nat.lt_two_pow_self (n := m)
  have h : 4 ^ m = 2 ^ m * 2 ^ m := by rw [← mul_pow]; norm_num
  rw [h]; exact Nat.mul_le_mul this.le this.le
#print axioms bd_sq_le

theorem bd_bound0 (m : ℕ) (S x : ℝ) (hS : 1 ≤ S) (hx : |x| ≤ S) :
    ‖J0Term m x‖ ≤ 4 * (S ^ 2) ^ m / m.factorial := by
  have := bd_key m (2 * m) 1 le_rfl (by have := Nat.one_le_pow m 4 (by norm_num); omega) S x hS hx
  have e : J0Term m x = (-1) ^ m * ((1 : ℕ) : ℝ) * x ^ (2 * m) / (4 ^ m * (m.factorial : ℝ) ^ 2) := by
    simp [J0Term]
  rw [Real.norm_eq_abs, e]; exact this
#print axioms bd_bound0

theorem bd_bound1 (m : ℕ) (S x : ℝ) (hS : 1 ≤ S) (hx : |x| ≤ S) :
    ‖bdD1 m x‖ ≤ 4 * (S ^ 2) ^ m / m.factorial := by
  have := bd_key m (2 * m - 1) (2 * m) (by omega) (by have := bd_sq_le m; nlinarith) S x hS hx
  rw [Real.norm_eq_abs]; exact this
#print axioms bd_bound1

theorem bd_bound2 (m : ℕ) (S x : ℝ) (hS : 1 ≤ S) (hx : |x| ≤ S) :
    ‖bdD2 m x‖ ≤ 4 * (S ^ 2) ^ m / m.factorial := by
  have := bd_key m (2 * m - 1 - 1) (2 * m * (2 * m - 1)) (by omega)
    (by have := bd_sq_le m; have : 2 * m * (2 * m - 1) ≤ 2 * m * (2 * m) := Nat.mul_le_mul_left _ (by omega)
        nlinarith) S x hS hx
  rw [Nat.cast_mul] at this
  rw [Real.norm_eq_abs]; unfold bdD2; rw [mul_assoc ((-1 : ℝ) ^ m)]; exact this
#print axioms bd_bound2

theorem bd_summable_u (S : ℝ) : Summable (fun m : ℕ => 4 * (S ^ 2) ^ m / m.factorial) := by
  simpa [mul_div_assoc] using (Real.summable_pow_div_factorial (S ^ 2)).mul_left 4
#print axioms bd_summable_u

theorem bd_hasDerivAt0 (m : ℕ) (x : ℝ) : HasDerivAt (J0Term m) (bdD1 m x) x := by
  show HasDerivAt (fun x => (-1) ^ m * x ^ (2 * m) / (4 ^ m * (m.factorial : ℝ) ^ 2)) _ x
  have := ((hasDerivAt_pow (2 * m) x).const_mul ((-1 : ℝ) ^ m)).div_const
    (4 ^ m * (m.factorial : ℝ) ^ 2)
  convert this using 1
  · unfold bdD1; ring
#print axioms bd_hasDerivAt0

theorem bd_hasDerivAt1 (m : ℕ) (x : ℝ) : HasDerivAt (bdD1 m) (bdD2 m x) x := by
  have := ((hasDerivAt_pow (2 * m - 1) x).const_mul ((-1 : ℝ) ^ m * ((2 * m : ℕ) : ℝ))).div_const
    (4 ^ m * (m.factorial : ℝ) ^ 2)
  convert this using 1
  · ext t; simp [bdD1]
  · simp [bdD2, mul_assoc]
#print axioms bd_hasDerivAt1

theorem bd_summable0 (x : ℝ) : Summable (fun m : ℕ => J0Term m x) :=
  Summable.of_norm_bounded (bd_summable_u (|x| + 1))
    (fun m => bd_bound0 m (|x| + 1) x (by linarith [abs_nonneg x]) (by linarith))
#print axioms bd_summable0

theorem bd_summable1 (x : ℝ) : Summable (fun m : ℕ => bdD1 m x) :=
  Summable.of_norm_bounded (bd_summable_u (|x| + 1))
    (fun m => bd_bound1 m (|x| + 1) x (by linarith [abs_nonneg x]) (by linarith))
#print axioms bd_summable1

theorem bd_summable2 (x : ℝ) : Summable (fun m : ℕ => bdD2 m x) :=
  Summable.of_norm_bounded (bd_summable_u (|x| + 1))
    (fun m => bd_bound2 m (|x| + 1) x (by linarith [abs_nonneg x]) (by linarith))
#print axioms bd_summable2

/-- Helper: the first derivative of J0 as a series. -/

noncomputable def bdJ1 (x : ℝ) : ℝ := ∑' m : ℕ, bdD1 m x
#print axioms bdJ1

/-- Helper: the second derivative of J0 as a series. -/

noncomputable def bdJ2 (x : ℝ) : ℝ := ∑' m : ℕ, bdD2 m x
#print axioms bdJ2

theorem bd_mem_ball {x z : ℝ} (hz : z ∈ Metric.ball (0 : ℝ) (|x| + 1)) : |z| ≤ |x| + 1 := by
  rw [Metric.mem_ball, Real.dist_eq, sub_zero] at hz; exact hz.le
#print axioms bd_mem_ball

theorem bd_hasDerivAt_J0 (x : ℝ) : HasDerivAt J0 (bdJ1 x) x := by
  have hx : x ∈ Metric.ball (0 : ℝ) (|x| + 1) := by
    rw [Metric.mem_ball, Real.dist_eq, sub_zero]; linarith
  exact hasDerivAt_tsum_of_isPreconnected (bd_summable_u (|x| + 1)) Metric.isOpen_ball
    (convex_ball _ _).isPreconnected (fun m z _ => bd_hasDerivAt0 m z)
    (fun m z hz => bd_bound1 m _ z (by linarith [abs_nonneg x]) (bd_mem_ball hz)) hx
    (bd_summable0 x) hx
#print axioms bd_hasDerivAt_J0

theorem bd_hasDerivAt_J1 (x : ℝ) : HasDerivAt bdJ1 (bdJ2 x) x := by
  have hx : x ∈ Metric.ball (0 : ℝ) (|x| + 1) := by
    rw [Metric.mem_ball, Real.dist_eq, sub_zero]; linarith
  exact hasDerivAt_tsum_of_isPreconnected (bd_summable_u (|x| + 1)) Metric.isOpen_ball
    (convex_ball _ _).isPreconnected (fun m z _ => bd_hasDerivAt1 m z)
    (fun m z hz => bd_bound2 m _ z (by linarith [abs_nonneg x]) (bd_mem_ball hz)) hx
    (bd_summable1 x) hx
#print axioms bd_hasDerivAt_J1

theorem bd_continuous_J2 : Continuous bdJ2 := by
  rw [continuous_iff_continuousAt]
  intro x
  have hx : x ∈ Metric.ball (0 : ℝ) (|x| + 1) := by
    rw [Metric.mem_ball, Real.dist_eq, sub_zero]; linarith
  have : ContinuousOn bdJ2 (Metric.ball (0 : ℝ) (|x| + 1)) :=
    continuousOn_tsum (fun m => by unfold bdD2; fun_prop) (bd_summable_u (|x| + 1))
      (fun m z hz => bd_bound2 m _ z (by linarith [abs_nonneg x]) (bd_mem_ball hz))
  exact this.continuousAt (Metric.isOpen_ball.mem_nhds hx)
#print axioms bd_continuous_J2

theorem bd_deriv_J0 : deriv J0 = bdJ1 := funext fun x => (bd_hasDerivAt_J0 x).deriv
#print axioms bd_deriv_J0

theorem bd_deriv_J1 : deriv bdJ1 = bdJ2 := funext fun x => (bd_hasDerivAt_J1 x).deriv
#print axioms bd_deriv_J1

theorem bd_J0_zero : J0 0 = 1 := by
  unfold J0
  rw [tsum_eq_single 0]
  · simp [J0Term]
  · intro m hm
    simp [J0Term, hm]
#print axioms bd_J0_zero

theorem bd_contDiff : ContDiff ℝ 2 J0 := by
  rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
  refine ⟨fun x => (bd_hasDerivAt_J0 x).differentiableAt, by simp, ?_⟩
  rw [bd_deriv_J0, contDiff_one_iff_deriv, bd_deriv_J1]
  exact ⟨fun x => (bd_hasDerivAt_J1 x).differentiableAt, bd_continuous_J2⟩
#print axioms bd_contDiff

theorem bd_coeff_rec (m : ℕ) (x : ℝ) :
    x ^ 2 * bdD2 (m + 1) x + x * bdD1 (m + 1) x = -(x ^ 2 * J0Term m x) := by
  unfold bdD2 bdD1 J0Term
  have e1 : 2 * (m + 1) - 1 = 2 * m + 1 := by omega
  have e2 : 2 * m + 1 - 1 = 2 * m := by omega
  rw [e1, e2, Nat.factorial_succ]
  push_cast
  have : (m.factorial : ℝ) ≠ 0 := by positivity
  field_simp
  ring
#print axioms bd_coeff_rec

theorem bd_bessel (x : ℝ) : x ^ 2 * bdJ2 x + x * bdJ1 x + x ^ 2 * J0 x = 0 := by
  unfold bdJ2 bdJ1 J0
  rw [← tsum_mul_left, ← tsum_mul_left, ← tsum_mul_left,
    ← ((bd_summable2 x).mul_left _).tsum_add ((bd_summable1 x).mul_left _)]
  have hA : Summable (fun m => x ^ 2 * bdD2 m x + x * bdD1 m x) :=
    ((bd_summable2 x).mul_left _).add ((bd_summable1 x).mul_left _)
  rw [hA.tsum_eq_zero_add]
  simp only [bd_coeff_rec, tsum_neg]
  simp [bdD1, bdD2]
#print axioms bd_bessel

theorem bd_anti {f f' : ℝ → ℝ} {p q : ℝ} (hf : ∀ x ∈ Ioo p q, HasDerivAt f (f' x) x)
    (h : ∀ x ∈ Ioo p q, f' x ≤ 0) : AntitoneOn f (Ioo p q) :=
  antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ioo p q)
    (fun x hx => (hf x hx).continuousAt.continuousWithinAt)
    (by rw [interior_Ioo]; exact fun x hx => (hf x hx).hasDerivWithinAt)
    (by rw [interior_Ioo]; exact h)
#print axioms bd_anti

theorem bd_const {f : ℝ → ℝ} {p q : ℝ} (hf : ∀ x ∈ Ioo p q, HasDerivAt f 0 x) :
    ∀ x ∈ Ioo p q, ∀ w ∈ Ioo p q, f x = f w := by
  have h1 := bd_anti (f' := fun _ => 0) hf (fun _ _ => le_rfl)
  have h2 := bd_anti (f := fun t => -f t) (f' := fun _ => 0)
    (fun x hx => by have := (hf x hx).neg; rw [neg_zero] at this; exact this) (fun _ _ => le_rfl)
  intro x hx w hw
  rcases le_total x w with h | h
  · have := h1 hx hw h; have := h2 hx hw h; simp at this; linarith
  · have := h1 hw hx h; have := h2 hw hx h; simp at this; linarith
#print axioms bd_const

theorem bd_unique (F F1 F2 : ℝ → ℝ) (hF : ∀ x, HasDerivAt F (F1 x) x)
    (hF1 : ∀ x, HasDerivAt F1 (F2 x) x) (hE : ∀ x, x ^ 2 * F2 x + x * F1 x + x ^ 2 * F x = 0)
    (hc : Continuous F) (h0 : F 0 = 1) :
    ∀ (a : ℝ) (y y' y'' : ℝ → ℝ), 0 < a →
      (∀ x ∈ Ioo 0 a, HasDerivAt y (y' x) x) →
      (∀ x ∈ Ioo 0 a, HasDerivAt y' (y'' x) x) →
      (∀ x ∈ Ioo 0 a, x ^ 2 * y'' x + x * y' x + x ^ 2 * y x = 0) →
      (∃ M δ : ℝ, 0 < δ ∧ ∀ x ∈ Ioo 0 δ, |y x| ≤ M) →
      ∃ C : ℝ, ∀ x ∈ Ioo 0 a, y x = C * F x := by
  intro a y y' y'' ha hy hy' hode ⟨M, δ, hδ, hM⟩
  -- the scaled Wronskian is constant
  set V : ℝ → ℝ := fun x => x * (y x * F1 x - y' x * F x) with hVdef
  have hV : ∀ x ∈ Ioo 0 a, HasDerivAt V 0 x := by
    intro x hx
    have hx0 : x ≠ 0 := hx.1.ne'
    have h := (hasDerivAt_id' x).mul (((hy x hx).mul (hF1 x)).sub ((hy' x hx).mul (hF x)))
    convert h using 1
    simp only [Pi.mul_apply, Pi.sub_apply]
    apply mul_left_cancel₀ hx0
    linear_combination -(y x) * hE x + F x * hode x hx
  set c := V (a / 2) with hcdef
  have hVc : ∀ x ∈ Ioo 0 a, V x = c := fun x hx =>
    bd_const hV x hx (a / 2) ⟨by linarith, by linarith⟩
  clear_value c
  -- a small interval where F stays between 1/2 and 2
  obtain ⟨η, hη, hηF⟩ := Metric.continuousAt_iff.1 hc.continuousAt (1 / 2) (by norm_num)
  set ε := min η (min δ (a / 2)) with hεdef
  have hε : 0 < ε := lt_min hη (lt_min hδ (by linarith))
  have hεη : ε ≤ η := min_le_left _ _
  have hεδ : ε ≤ δ := (min_le_right _ _).trans (min_le_left _ _)
  have hεa : ε < a := lt_of_le_of_lt ((min_le_right _ _).trans (min_le_right _ _)) (by linarith)
  have hsub : ∀ x ∈ Ioo 0 ε, x ∈ Ioo 0 a := fun x hx => ⟨hx.1, by linarith [hx.2]⟩
  have hFb : ∀ x ∈ Ioo 0 ε, 1 / 2 ≤ F x ∧ F x ≤ 2 := by
    intro x hx
    have : dist x 0 < η := by
      rw [Real.dist_eq, sub_zero, abs_of_pos hx.1]; linarith [hx.2]
    have h := hηF this
    rw [Real.dist_eq, h0] at h
    have := abs_lt.1 h
    constructor <;> linarith
  -- the quotient y / F
  set q : ℝ → ℝ := fun x => y x / F x with hqdef
  have hq : ∀ x ∈ Ioo 0 ε, HasDerivAt q (-c / (x * F x ^ 2)) x := by
    intro x hx
    have hFx : F x ≠ 0 := by linarith [(hFb x hx).1]
    have hx0 : x ≠ 0 := hx.1.ne'
    have h := (hy x (hsub x hx)).div (hF x) hFx
    convert h using 1
    have hv := hVc x (hsub x hx)
    simp only [hVdef] at hv
    field_simp
    linear_combination hv
  -- c must vanish, or y / F would grow like log x near the centre
  have hc0 : c = 0 := by
    by_contra hcne
    set h : ℝ → ℝ := fun x => c * q x + c ^ 2 / 4 * Real.log x with hhdef
    have hh : ∀ x ∈ Ioo 0 ε, HasDerivAt h (c * (-c / (x * F x ^ 2)) + c ^ 2 / 4 * x⁻¹) x :=
      fun x hx => ((hq x hx).const_mul c).add ((Real.hasDerivAt_log hx.1.ne').const_mul _)
    have hanti := bd_anti hh (by
      intro x hx
      have hFx := hFb x hx
      have hFp : 0 < F x := by linarith
      have hx0 := hx.1
      have e : c * (-c / (x * F x ^ 2)) + c ^ 2 / 4 * x⁻¹ =
          c ^ 2 * (F x ^ 2 - 4) / (4 * x * F x ^ 2) := by
        field_simp; ring
      rw [e]
      apply div_nonpos_of_nonpos_of_nonneg
      · apply mul_nonpos_of_nonneg_of_nonpos (sq_nonneg c); nlinarith
      · positivity)
    set x0 := ε / 2 with hx0def
    have hx0 : x0 ∈ Ioo 0 ε := ⟨by linarith, by linarith⟩
    set K := 2 * |c| * M - h x0 with hKdef
    have hc2 : 0 < c ^ 2 := by positivity
    set T := |Real.log x0| + 4 * |K| / c ^ 2 + 1 with hTdef
    set x := Real.exp (-T) with hxdef
    have hxpos : 0 < x := Real.exp_pos _
    have hxlt : x < x0 := by
      rw [hxdef, ← Real.exp_log hx0.1]
      apply Real.exp_lt_exp.2
      have : 0 ≤ 4 * |K| / c ^ 2 := by positivity
      have := neg_abs_le (Real.log x0)
      linarith
    have hxI : x ∈ Ioo 0 ε := ⟨hxpos, by linarith [hx0.2]⟩
    have hmono := hanti hxI hx0 hxlt.le
    have hlog : Real.log x = -T := Real.log_exp _
    have hFx := hFb x hxI
    have hyx : |y x| ≤ M := hM x ⟨hxpos, by linarith [hxI.2]⟩
    have hqx : |c * q x| ≤ 2 * |c| * M := by
      rw [abs_mul, hqdef, abs_div, abs_of_pos (by linarith : 0 < F x)]
      rw [mul_div_assoc', div_le_iff₀ (by linarith)]
      have h1 : |c| * |y x| ≤ |c| * M := mul_le_mul_of_nonneg_left hyx (abs_nonneg c)
      have h2 : 0 ≤ |c| * M := le_trans (by positivity) h1
      nlinarith [mul_le_mul_of_nonneg_left (by linarith : 1 ≤ 2 * F x) h2]
    have h1 : h x0 ≤ c * q x + c ^ 2 / 4 * Real.log x := hmono
    rw [hlog] at h1
    have h2 := (abs_le.1 hqx).2
    have h3 : c ^ 2 / 4 * T ≤ K := by rw [hKdef]; linarith
    have h4 : c ^ 2 / 4 * T = c ^ 2 / 4 * (|Real.log x0| + 1) + |K| := by
      rw [hTdef]; field_simp; ring
    have := abs_nonneg (Real.log x0)
    have := le_abs_self K
    nlinarith
  -- so y / F is constant near the centre
  have hq0 : ∀ x ∈ Ioo 0 ε, HasDerivAt q 0 x := fun x hx => by
    simpa [hc0] using hq x hx
  set C := q (ε / 2) with hCdef
  have hyC : ∀ x ∈ Ioo 0 ε, y x = C * F x := by
    intro x hx
    have h := bd_const hq0 x hx (ε / 2) ⟨by linarith, by linarith⟩
    have hFx : F x ≠ 0 := by linarith [(hFb x hx).1]
    rw [← hCdef, hqdef] at h
    simp only at h
    rw [← h]; field_simp
  -- the energy of z = y - C F cannot grow, and it is zero near the centre
  refine ⟨C, ?_⟩
  set z : ℝ → ℝ := fun x => y x - C * F x with hzdef
  set z' : ℝ → ℝ := fun x => y' x - C * F1 x with hz'def
  have hz : ∀ x ∈ Ioo 0 a, HasDerivAt z (z' x) x := fun x hx =>
    (hy x hx).sub ((hF x).const_mul C)
  have hz' : ∀ x ∈ Ioo 0 a, HasDerivAt z' (y'' x - C * F2 x) x := fun x hx =>
    (hy' x hx).sub ((hF1 x).const_mul C)
  set En : ℝ → ℝ := fun x => z x * z x + z' x * z' x with hEndef
  have hEn : ∀ x ∈ Ioo 0 a, HasDerivAt En
      (z' x * z x + z x * z' x + ((y'' x - C * F2 x) * z' x + z' x * (y'' x - C * F2 x))) x :=
    fun x hx => ((hz x hx).mul (hz x hx)).add ((hz' x hx).mul (hz' x hx))
  have hanti := bd_anti hEn (by
    intro x hx
    have hx0 := hx.1
    have key : x ^ 2 * (z' x * z x + z x * z' x +
        ((y'' x - C * F2 x) * z' x + z' x * (y'' x - C * F2 x))) = -2 * x * z' x ^ 2 := by
      simp only [hzdef, hz'def]
      linear_combination (2 * (y' x - C * F1 x)) * hode x hx - (2 * C * (y' x - C * F1 x)) * hE x
    by_contra hD
    push Not at hD
    have := mul_pos (pow_pos hx0 2) hD
    rw [key] at this
    nlinarith [sq_nonneg (z' x)])
  have hE0 : ∀ x ∈ Ioo 0 ε, En x = 0 := by
    intro x hx
    have hzx : ∀ t ∈ Ioo 0 ε, z t = 0 := fun t ht => by simp [hzdef, hyC t ht]
    have hd : HasDerivAt z 0 x :=
      (hasDerivAt_const x (0 : ℝ)).congr_of_eventuallyEq
        (Filter.eventually_of_mem (Ioo_mem_nhds hx.1 hx.2) (fun t ht => hzx t ht))
    have hz'x : z' x = 0 := (hz x (hsub x hx)).unique hd
    simp [hEndef, hzx x hx, hz'x]
  intro x hx
  set x1 := min x (ε / 2) with hx1def
  have hx1 : x1 ∈ Ioo 0 ε :=
    ⟨lt_min hx.1 (by linarith), lt_of_le_of_lt (min_le_right _ _) (by linarith)⟩
  have hle := hanti (hsub x1 hx1) hx (min_le_left _ _)
  rw [hE0 x1 hx1] at hle
  have hzx : z x = 0 := by
    simp only [hEndef] at hle
    nlinarith [mul_self_nonneg (z x), mul_self_nonneg (z' x)]
  simp only [hzdef] at hzx
  linarith
#print axioms bd_unique

theorem bd_coeff_step (n : ℕ) :
    ((n + 2 : ℕ) : ℝ) ^ 2 * besselCoeff (n + 2) = -besselCoeff n := by
  rcases Nat.even_or_odd n with ⟨k, rfl⟩ | ⟨k, rfl⟩
  · have e1 : Even (k + k + 2) := ⟨k + 1, by omega⟩
    have e2 : Even (k + k) := ⟨k, rfl⟩
    have d1 : (k + k + 2) / 2 = k + 1 := by omega
    have d2 : (k + k) / 2 = k := by omega
    unfold besselCoeff
    simp only [e1, e2, ↓reduceIte]
    rw [d1, d2, Nat.factorial_succ]
    push_cast
    have : (k.factorial : ℝ) ≠ 0 := by positivity
    field_simp
    ring
  · have e1 : ¬ Even (2 * k + 1 + 2) := by
      rw [Nat.not_even_iff_odd]; exact ⟨k + 1, by omega⟩
    have e2 : ¬ Even (2 * k + 1) := by
      rw [Nat.not_even_iff_odd]; exact ⟨k, rfl⟩
    unfold besselCoeff
    simp [e1, e2]
#print axioms bd_coeff_step

/-- The card's main claim. The series J0 converges for every x, equals 1 at the centre, is twice
differentiable and solves Bessel's equation x²y'' + xy' + x²y = 0 everywhere. And it is the one
solution that stays finite at the centre: any solution y of Bessel's equation on an interval
(0, a) that stays bounded near x = 0 is a constant times J0 there. (The other solution, Y0,
carries a logarithm and falls without bound at the centre.) -/
theorem J0_is_the_solution_finite_at_centre :
    (∀ x : ℝ, Summable (fun m : ℕ => J0Term m x)) ∧
    J0 0 = 1 ∧
    ContDiff ℝ 2 J0 ∧
    (∀ x : ℝ, x ^ 2 * deriv (deriv J0) x + x * deriv J0 x + x ^ 2 * J0 x = 0) ∧
    (∀ (a : ℝ) (y y' y'' : ℝ → ℝ), 0 < a →
      (∀ x ∈ Ioo 0 a, HasDerivAt y (y' x) x) →
      (∀ x ∈ Ioo 0 a, HasDerivAt y' (y'' x) x) →
      (∀ x ∈ Ioo 0 a, x ^ 2 * y'' x + x * y' x + x ^ 2 * y x = 0) →
      (∃ M δ : ℝ, 0 < δ ∧ ∀ x ∈ Ioo 0 δ, |y x| ≤ M) →
      ∃ C : ℝ, ∀ x ∈ Ioo 0 a, y x = C * J0 x) := by
  refine ⟨bd_summable0, bd_J0_zero, bd_contDiff, ?_, ?_⟩
  · intro x
    rw [bd_deriv_J0, bd_deriv_J1]
    exact bd_bessel x
  · exact bd_unique J0 bdJ1 bdJ2 bd_hasDerivAt_J0 bd_hasDerivAt_J1 bd_bessel
      bd_contDiff.continuous bd_J0_zero

/-- Frobenius at the centre: with trial power s = 0, matching powers gives a_0 = 1 (chosen),
a_1 = 0 and n² a_n = -a_(n-2) for every later n. These rules have exactly one solution,
and it is the sequence of J0's coefficients. -/
theorem frobenius_recurrence_gives_J0_coefficients (a : ℕ → ℝ) :
    (a 0 = 1 ∧ a 1 = 0 ∧ ∀ n : ℕ, 2 ≤ n → (n : ℝ) ^ 2 * a n = -a (n - 2)) ↔
      a = besselCoeff := by
  constructor
  · rintro ⟨h0, h1, hrec⟩
    funext n
    induction n using Nat.strong_induction_on with
    | _ n ih =>
      match n, ih with
      | 0, _ => simp [h0, besselCoeff]
      | 1, _ => simp [h1, besselCoeff]
      | n + 2, ih =>
        have h := hrec (n + 2) (by omega)
        rw [show n + 2 - 2 = n by omega, ih n (by omega), ← bd_coeff_step n] at h
        have hne : ((n + 2 : ℕ) : ℝ) ^ 2 ≠ 0 := by positivity
        exact mul_left_cancel₀ hne h
  · rintro rfl
    refine ⟨by simp [besselCoeff], by simp [besselCoeff], ?_⟩
    intro n hn
    obtain ⟨k, rfl⟩ : ∃ k, n = k + 2 := ⟨n - 2, by omega⟩
    rw [show k + 2 - 2 = k by omega]
    exact bd_coeff_step k

/-- The substitution y = u/√x: for x > 0 and any u twice differentiable for x > 0,
x²y'' + xy' + x²y = x^(3/2) (u'' + (1 + 1/(4x²)) u). So y solves Bessel's equation exactly when
u solves u'' + (1 + 1/(4x²)) u = 0: the u' terms cancel. -/
theorem bessel_sqrt_substitution (u : ℝ → ℝ) (hu : ContDiffOn ℝ 2 u (Ioi 0)) (x : ℝ)
    (hx : 0 < x) :
    let y : ℝ → ℝ := fun t => u t * t ^ (-(1 : ℝ) / 2)
    x ^ 2 * deriv (deriv y) x + x * deriv y x + x ^ 2 * y x =
      x ^ ((3 : ℝ) / 2) * (deriv (deriv u) x + (1 + 1 / (4 * x ^ 2)) * u x) := by
  intro y
  set p : ℝ := -(1 : ℝ) / 2 with hpdef
  have hdiff : DifferentiableOn ℝ u (Ioi 0) := hu.differentiableOn (by norm_num)
  have hu1 : ∀ t, 0 < t → HasDerivAt u (deriv u t) t := fun t ht =>
    ((hdiff t ht).differentiableAt (Ioi_mem_nhds ht)).hasDerivAt
  have hdu : ContDiffOn ℝ 1 (deriv u) (Ioi 0) :=
    hu.deriv_of_isOpen isOpen_Ioi (by norm_num)
  have hu2 : HasDerivAt (deriv u) (deriv (deriv u) x) x :=
    (((hdu.differentiableOn (by norm_num)) x hx).differentiableAt (Ioi_mem_nhds hx)).hasDerivAt
  have hp : ∀ t, 0 < t → HasDerivAt (fun t : ℝ => t ^ p) (p * t ^ (p - 1)) t := fun t ht =>
    Real.hasDerivAt_rpow_const (Or.inl ht.ne')
  have hp2 : HasDerivAt (fun t : ℝ => p * t ^ (p - 1)) (p * ((p - 1) * x ^ (p - 1 - 1))) x :=
    (Real.hasDerivAt_rpow_const (Or.inl hx.ne')).const_mul p
  have dy : ∀ t, 0 < t → HasDerivAt y (deriv u t * t ^ p + u t * (p * t ^ (p - 1))) t :=
    fun t ht => (hu1 t ht).mul (hp t ht)
  have hev : deriv y =ᶠ[nhds x] fun t => deriv u t * t ^ p + u t * (p * t ^ (p - 1)) :=
    Filter.eventually_of_mem (Ioi_mem_nhds hx) (fun t ht => (dy t ht).deriv)
  have d2 : HasDerivAt (fun t => deriv u t * t ^ p + u t * (p * t ^ (p - 1)))
      (deriv (deriv u) x * x ^ p + deriv u x * (p * x ^ (p - 1)) +
        (deriv u x * (p * x ^ (p - 1)) + u x * (p * ((p - 1) * x ^ (p - 1 - 1))))) x :=
    (hu2.mul (hp x hx)).add ((hu1 x hx).mul hp2)
  rw [hev.deriv_eq, d2.deriv, (dy x hx).deriv]
  have hyx : y x = u x * x ^ p := rfl
  rw [hyx]
  have r1 : x ^ (p - 1) = x ^ p / x := Real.rpow_sub_one hx.ne' p
  have r2 : x ^ (p - 1 - 1) = x ^ p / x / x := by
    rw [Real.rpow_sub_one hx.ne', r1]
  have r3 : x ^ ((3 : ℝ) / 2) = x ^ p * x ^ 2 := by
    rw [show (3 : ℝ) / 2 = p + 2 by rw [hpdef]; norm_num, Real.rpow_add hx, Real.rpow_two]
  rw [r1, r2, r3, hpdef]
  field_simp
  ring

-- The card's coefficients: a_2 = -1/4, a_4 = 1/64, a_6 = -1/2304, a_8 = 1/147456; odd ones vanish.
example : besselCoeff 1 = 0 := by norm_num [besselCoeff]
example : besselCoeff 2 = -1 / 4 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
example : besselCoeff 4 = 1 / 64 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
example : besselCoeff 6 = -1 / 2304 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
example : besselCoeff 8 = 1 / 147456 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
-- The denominators of the series terms: 4^m (m!)^2 for m = 1, 2, 3, 4.
example : (4 ^ 1 * (Nat.factorial 1) ^ 2, 4 ^ 2 * (Nat.factorial 2) ^ 2,
    4 ^ 3 * (Nat.factorial 3) ^ 2, 4 ^ 4 * (Nat.factorial 4) ^ 2) = (4, 64, 2304, 147456) := by decide
-- The large-x estimate puts the n-th zero near (n - 1/4)π, so its ratios are (4n - 1)/3:
-- 7/3 and 11/3, not 2 and 3.
example : ((2 : ℚ) - 1 / 4) / (1 - 1 / 4) = 7 / 3 := by norm_num
example : ((3 : ℚ) - 1 / 4) / (1 - 1 / 4) = 11 / 3 := by norm_num

#print axioms J0_is_the_solution_finite_at_centre
#print axioms frobenius_recurrence_gives_J0_coefficients
#print axioms bessel_sqrt_substitution

end BesselDrum
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'BesselDrum.bdD1' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bdD2' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_key' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_sq_le' depends on axioms: [propext]
'BesselDrum.bd_bound0' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_bound1' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_bound2' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_summable_u' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_hasDerivAt0' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_hasDerivAt1' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_summable0' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_summable1' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_summable2' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bdJ1' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bdJ2' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_mem_ball' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_hasDerivAt_J0' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_hasDerivAt_J1' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_continuous_J2' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_deriv_J0' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_deriv_J1' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_J0_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_contDiff' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_coeff_rec' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_bessel' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_anti' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_const' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bd_coeff_step' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.J0_is_the_solution_finite_at_centre' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.frobenius_recurrence_gives_J0_coefficients' depends on axioms: [propext, Classical.choice, Quot.sound]
'BesselDrum.bessel_sqrt_substitution' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Tighten the head.** Double `C`. Every note doubles; the ratios stay 2.295 and 3.598.
> - **A bigger drum.** Set `R` to `0.6`. Every note halves.
> - **Coarser steps.** Put `0.4` first in the step lengths. Its worst error is about seventeen times that at 0.2, near the sixteen fourth order predicts.

---

## The usual mistake

> [!warning]
> **Expecting a drum's overtones to be whole multiples, as a string's are.** A string's notes come from sin(nπx), with evenly spaced zeros. J0's zeros sit near (n − 1/4)π: evenly spaced far out, but shifted a quarter step, so their ratios are not whole numbers. The overtones land at 2.295 and 3.598 times the fundamental, 292.8 and 459.1 Hz, not 255.2 and 382.7.
>
> - **Dropping y'/x.** The answer becomes cos x, fundamental 83.3 Hz.
> - **Keeping Y0 as well.** It is infinite at the centre.
> - **Trusting a short series far out.** Four terms find one zero, at 2.392.

---

## Where you meet it in real life

- **Orchestral timpani.** The kettle's air pulls the notes with still diameters, J1 and higher, close to a whole-number ladder, and the round J0 notes fade fast: that is how timpani get a pitch at all.
- **This shelf.** The notes are eigenvalues of a boundary problem, the special values that allow a nonzero solution ([Eigenvalue problems](08-eigenvalues-and-eigenfunctions.md)); aiming from the centre at the rim is [Shooting](06-the-shooting-method.md).

> **Say it back**
> Forces on thin rings of a drumhead give Bessel's equation. Frobenius gives J0, a series converging everywhere; the other solution is infinite at the centre, so the shape is J0(kr). A clamped rim puts kR on a zero of J0: 2.404826, 5.520078, 8.653728. These sit near (n − 1/4)π, so the overtones are 2.295 and 3.598 times the fundamental: no clear pitch.

---

## What this builds on

- [Frobenius](02-frobenius-and-regular-singular-points.md): the trial x^s times a series, the indicial equation, and the logarithm a double root forces.

## Where this goes next

- [Sturm-Liouville](09-sturm-liouville-and-orthogonality.md): why the zeros never run out, and why the shapes are orthogonal: two different shapes multiplied together average to zero over the head's area.
- [Waves on strings and drums](../../13-Engineering%20mathematics/09-Quantum%20Mechanics%20in%20Outline/01-wave-equation-for-strings-and-membranes.md): the wave equation behind the ring balance.
- Drumheads: every mode, including those with still diameters.

A real strike sounds many notes at once; how much of each it contains is the orthogonality question Sturm-Liouville answers.

---

## Sources

Verified 2026-11-12: every link below resolves to the publisher's page.

- NIST Digital Library of Mathematical Functions, §10.2, "Definitions," Bessel Functions. [dlmf.nist.gov/10.2](https://dlmf.nist.gov/10.2). The equation, J0's series, and the logarithmic second solution.
- NIST Digital Library of Mathematical Functions, §10.21, "Zeros." [dlmf.nist.gov/10.21](https://dlmf.nist.gov/10.21). Zeros of J0 and McMahon's expansion.
- Bender, Carl M., and Steven A. Orszag. *Advanced Mathematical Methods for Scientists and Engineers I*. Springer, 1999. [DOI 10.1007/978-1-4757-3069-2](https://doi.org/10.1007/978-1-4757-3069-2). Frobenius series at a regular singular point; Bessel as the model case.
- Fletcher, Neville H., and Thomas D. Rossing. *The Physics of Musical Instruments*, 2nd ed. Springer, 1998. [DOI 10.1007/978-0-387-21603-4](https://doi.org/10.1007/978-0-387-21603-4). The round membrane's modes, and how the kettle's air tunes timpani.
