# Superposition: for a linear equation, solutions add and scale, so two of them are enough

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Oscillators - Second-Order Linear Equations](../README.md#s03) → Superposition

---

## General Overview

A weight hangs from a spring. Pull it 1 cm up and let go: it bobs, back at 1 cm every 6.28 seconds. Start it at rest height with an upward flick of 1 cm per second: same rhythm, a quarter-swing later.

Now pull it 3 cm up and flick it down at 2 cm per second. No new calculation is needed: the motion is 3 copies of the first swing minus 2 copies of the second.

It works because the spring's pull is proportional to the stretch. An equation built only from the unknown and its rates, each times a number, then added, is called **linear**. Its solutions add and scale the way the pulls do, and that is called **superposition**.

Two independent swings (neither a multiple of the other), weighted by two numbers, cover every motion; the starting height and speed fix the numbers. Lift the ceiling hook at a steady 0.5 cm per second, and one motion that copes with the hook, plus the free family, gives every motion.

**For a linear equation, any weighted sum of free solutions is a free solution; two independent ones cover them all, two starting values pick the weights, and a forced equation's solutions are one forced solution plus that free family.**

**What kind of fact this is:** a theorem, proved for the spring in Why it works; the general second-order case is in the Detailed proof, resting on [The Picard-Lindelof theorem](../02-Existence%2C%20Uniqueness%20and%20Sensitivity/02-lipschitz-and-the-picard-lindelof-theorem.md).

### The picture: a free swing, the hook, and the forced motion

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Weight on a spring, started 3 cm up at -2 cm/s"
    x-axis "Time since release (s)" [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8]
    y-axis "Height above rest (cm)" -4 --> 7
    line [0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.25, 3.50, 3.75, 4.00]
    line [3.00, 1.67, -0.06, -1.78, -3.07, -3.60, -3.25, -2.11, -0.45, 1.32, 2.77, 3.54, 3.44, 2.50, 0.95, -0.84, -2.42]
    line [3.00, 1.68, 0.02, -1.53, -2.52, -2.65, -1.82, -0.18, 1.93, 4.06, 5.75, 6.64, 6.58, 5.64, 4.12, 2.44, 1.09]
```

Orange, straight: the hook's height t/2 cm, itself a forced solution. Green: the free swing 3 cos t − 2 sin t, peaking at 3.61 cm. Dark blue: the same start with the hook rising.

---

## The formula

Notation first, in words. As on [A differential equation](../01-Rate%20Equations/01-what-a-differential-equation-says.md), a dash means a rate: $y'$ is the weight's speed, and $y''$, "y double prime", its acceleration. $L[y]$ is a machine that takes a whole curve and returns another: the curve's acceleration plus the curve itself.

The spring pulls 1 cm/s^2 per cm of stretch (stiffness over mass, 1 per s^2), so with the hook fixed

$$L[y] = y'' + y = 0.$$

**Read it aloud:** the acceleration is always the height with its sign flipped.

For any numbers $a$ and $b$ and any curves $y_1$ and $y_2$,

$$L[a\,y_1 + b\,y_2] = a\,L[y_1] + b\,L[y_2].$$

**Read it aloud:** the machine applied to a weighted sum is the same weighted sum of its outputs.

Every free solution is (Step 3 proves nothing is missed)

$$y_h = c_1 \cos t + c_2 \sin t, \qquad c_1 = y(0),\; c_2 = y'(0),$$

and with the hook rising, $L[y] = f(t)$ with $f(t) = t/2$, every solution is

$$y = y_p + c_1 \cos t + c_2 \sin t, \qquad y_p = t/2.$$

**Read it aloud:** one forced motion plus any free swing.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $t$ | time since release, s | 0 to 8 s | the swing repeats every 6.28 s |
| $y$, $y'$, $y''$ | height above rest (cm), speed (cm/s), acceleration (cm/s^2) | 3 cm and −2 cm/s at the start | — |
| $L[y]$ | acceleration plus height: the push per kg the curve needs | 0 for a free swing | — |
| $f(t)$ | the forcing: the hook's pull per kg, set by its height | t/2 | the motion drifts upwards |
| $y_1$, $y_2$ | two free solutions | cos t and sin t | — |
| $a$, $b$, $c_1$, $c_2$ | weights in a sum; $c_1$, $c_2$ are the ones the start fixes | 3 and −2 free, 3 and −2.5 forced | taller swing |
| $y_h$, $y_p$ | a free (homogeneous) solution; one particular forced solution | 3 cos t − 2 sin t; t/2 | — |
| $E$ | twice the energy per kg: speed squared plus height squared | 13 for the free swing | — |

**Homogeneous** means the forcing is zero, the hook held still. A **particular solution** is any one solution of the forced equation.

### When it holds

- **The equation is linear:** each term is the unknown or a rate, times a number or a function of time. A pendulum's sin y breaks it: its upside-down balance at π radians is a solution, half of it is not.
- **Only free solutions add.** Two forced solutions add to one with the forcing doubled, 2.000 instead of 1.000 at t = 2 s.
- **The two solutions are independent.** cos t and 2 cos t both start at speed 0, so no mix of them starts at −2 cm/s.
- **Two starting values.** Height alone leaves the second weight free.

---

## Why it works

### Step 0: rates respect sums and multiples

The rate of a sum is the sum of the rates; the rate of 3 times a curve is 3 times its rate. Twice over, for the acceleration: $L[a\,y_1 + b\,y_2] = a\,y_1'' + b\,y_2'' + a\,y_1 + b\,y_2 = a\,L[y_1] + b\,L[y_2]$.

### Step 1: weighted sums of free swings are free swings

cos t has acceleration −cos t, so $L[\cos t] = 0$; likewise $L[\sin t] = 0$. By Step 0, $L[3\cos t - 2\sin t] = 3 \times 0 - 2 \times 0 = 0$. The free solutions are closed under weighted sums ([Linear combinations and span](../../03-Algebra/03-Vectors/03-linear-combinations-and-span.md)): a vector space whose members are curves.

### Step 2: two starting readings fix the two weights

At t = 0, cos is 1 with speed 0 and sin is 0 with speed 1, so $y_h(0) = c_1$ and $y_h'(0) = c_2$: here 3 and −2. Height alone allows 3 cos t + c sin t for every number c.

The pair works because its starting table, height and speed of each, has determinant 1, not 0. The determinant is the first's height times the second's speed, minus the second's height times the first's speed. That test is [The Wronskian](04-wronskian-and-reduction-of-order.md).

### Step 3: nothing is missed

Take any free motion $y$. Build $w = y(0)\cos t + y'(0)\sin t$, which starts the same way. The difference $z = y - w$ is free and starts at height 0, speed 0.

Its $E = z'^2 + z^2$ has rate $2z'z'' + 2zz' = 2z'(z'' + z) = 0$, so $E$ stays at its starting value, 0. Two squares summing to 0 force $z = 0$.

So $y = w$: every free motion is exactly one mix of cos t and sin t. The free solutions form a space of dimension 2 with basis cos t and sin t ([Basis and dimension](../../03-Algebra/03-Vectors/05-basis-and-dimension.md)).

For the swing 3 cos t − 2 sin t, $E$ reads 13 throughout, so it peaks at √13 = 3.61 cm.

### Step 4: forced motions differ by a free motion

If $y$ and $y_p$ both solve $L[y] = t/2$, Step 0 gives $L[y - y_p] = t/2 - t/2 = 0$, so the difference is free. By Step 3 it is $c_1 \cos t + c_2 \sin t$.

A straight line has acceleration 0, so $L[t/2] = t/2$: following the hook is one forced motion. The start 3 cm, −2 cm/s gives $c_1 = 3$ and $1/2 + c_2 = -2$, so $c_2 = -2.5$.

### Step 5: forcing scales and adds

$L[2y] = 2L[y]$: twice a motion needs twice the forcing. Raise the hook at 1 cm/s, start at 6 cm, −4 cm/s, and the weight moves exactly twice as far. Two forcings together are met by the sum of their responses, which is why [Undetermined coefficients](05-undetermined-coefficients.md) can treat a forcing term by term.

<details>
<summary>Detailed proof: any second-order linear equation</summary>

Let the coefficients p(t), q(t) and the forcing f(t) be continuous on an interval containing 0, and L[y] = y'' + p(t)y' + q(t)y. Step 0 holds unchanged whatever the coefficients.

Send each homogeneous solution to its starting pair, height and speed at 0. This map is linear. By the existence and uniqueness theorem for linear equations, each pair is reached by exactly one solution on the whole interval, since linear equations never blow up ([Blow-up](../02-Existence%2C%20Uniqueness%20and%20Sensitivity/03-blow-up-and-the-life-span-of-a-solution.md)). So the map is one-to-one and onto the plane: the solutions form a vector space of dimension 2, and two of them are a basis exactly when their starting pairs are independent.

For $L[y] = f$, if $y_p$ is one solution then $L[y - y_p] = 0$ for every other, so $y - y_p$ lies in that plane of solutions. The forced solutions are one point plus that plane, not a vector space: two of them sum to forcing 2f.

</details>

A second road needs no formula: from the start, step the height by the speed and the speed by the rule's acceleration, in small time steps. This is Euler's rule, given its own card at [Euler's method](../05-Numerical%20Evolution/01-eulers-method.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| free weights | $c_1$ = height, $c_2$ = speed at the start | 3 and −2 |
| energy of the free swing | (−2)^2 + 3^2 | 13, so a peak of 3.61 cm |
| one forced solution | L[t/2] = 0 + t/2 | t/2 |
| forced weights | 3 = 0 + $c_1$; −2 = 1/2 + $c_2$ | 3 and −2.5 |
| cos and sin at 2 s | from tables or a calculator | −0.4161 and 0.9093 |
| forced motion at t = 2 s | 1 + 3 × (−0.4161) − 2.5 × 0.9093 | **−2.5217 cm** |
| doubled hook and start | 2 × (−2.5217) | −5.0434 cm |

Two seconds in, the weight is 2.52 cm below rest though the hook has risen 1 cm: the swing outweighs the drift.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Adding two forced solutions | forcing 2.000 at t = 2 s, not 1.000 | Forcings add too |
| Halving the pendulum's balance, $y'' + \sin y = 0$, from y = π to π/2 | residual 1.000 rad/s^2, not 0.000 | sin y is not linear |
| A dependent pair, cos t and 2 cos t | start determinant 0.000 | Both start at speed 0; no mix reaches −2 cm/s |
| Height as the only starting value | 3 cos t + c sin t, any c | The speed is needed too |

---

## Code, from first principles, and it actually runs

Two roads. Road one puts each closed form (the solution written as a formula) into $L$. It measures acceleration by a centred difference: the heights a small step before and after t, compared with the height at t.

Road two is Euler's rule, stepping from the start with the rate law alone; it must match the closed form at t = 2 s, its error falling tenfold with the step. The doubled case is stepped separately and must land at twice the formula. Every chart point and what-breaks number is printed.

### Python

```python
# Superposition -- the check behind the card.  Standard library only.
# A weight on a spring: y'' + y = f(t), y in cm above rest, t in s.  Road one:
# closed forms, tested by substitution.  Road two: Euler's rule, rate law only.
import math

cos, sin, pi = math.cos, math.sin, math.pi

def L(y, t, d=1e-3):                   # y'' + y, with y'' by a centred difference
    return (y(t + d) - 2 * y(t) + y(t - d)) / d ** 2 + y(t)

def D(y, t, d=1e-6):                   # slope by a centred difference
    return (y(t + d) - y(t - d)) / (2 * d)

def det(g1, g2):                       # starting values of two solutions, as a determinant
    return g1(0) * D(g2, 0) - g2(0) * D(g1, 0)

def euler(f, y0, v0, t_end, n):        # y' = v, v' = f(t) - y, in n small steps
    h, y, v = t_end / n, y0, v0
    for k in range(n):
        y, v = y + h * v, v + h * (f(k * h) - y)
    return y

combo = lambda t: 3 * cos(t) - 2 * sin(t)          # free swing from 3 cm, -2 cm/s
hook = lambda t: t / 2                             # one forced solution: follow the hook
forced = lambda t: t / 2 + 3 * cos(t) - 2.5 * sin(t)
ts, grid = [0.5, 1, 2, 3], [k / 2 for k in range(17)]
worst = max(abs(L(g, t)) for g in (cos, sin, combo) for t in ts)
c1, c2 = 3, -2 - 0.5                               # y(0) = c1, y'(0) = 1/2 + c2
energy = [(-3 * sin(t) - 2 * cos(t)) ** 2 + combo(t) ** 2 for t in (0, 1, 2)]
print(f"residual y'' + y, largest over cos t, sin t, 3 cos t - 2 sin t: {worst:.6f}")
print(f"y'^2 + y^2 for 3 cos t - 2 sin t at t = 0, 1, 2: " + ", ".join(f"{e:.3f}" for e in energy)
      + f"; amplitude {math.sqrt(energy[0]):.2f} cm")
print("forcing of t/2 at t = 1, 2, 3: " + ", ".join(f"{L(hook, t):.3f}" for t in (1, 2, 3)))
print(f"forced solution: c1 = {c1:.1f}, c2 = {c2:.1f}; start {forced(0):.3f} cm, {D(forced, 0):.3f} cm/s; "
      f"forcing at t = 2 is {L(forced, 2):.3f}")
for name, g in (("t/2", hook), ("3 cos t - 2 sin t", combo), ("t/2 + 3 cos t - 2.5 sin t", forced)):
    print(f"chart, {name}: " + ", ".join(f"{g(t):.2f}" for t in grid))
f_half, f_one, errs = (lambda t: t / 2), (lambda t: t), []
for n in (1000, 10000, 100000):
    y = euler(f_half, 3, -2, 2, n)
    errs.append(abs(y - forced(2)))
    print(f"euler, {n} steps to t = 2: y = {y:.4f}, closed form {forced(2):.4f}, error {errs[-1]:.5f}")
print(f"euler, error ratio 10000 vs 100000 steps: {errs[1] / errs[2]:.2f}")
free = euler(lambda t: 0, 3, -2, 2, 100000)
print(f"at t = 2: cos t = {cos(2):.4f}, sin t = {sin(2):.4f}; euler free swing {free:.4f}, "
      f"closed form {combo(2):.4f}; period 2 pi = {2 * pi:.4f}")
double = euler(f_one, 6, -4, 2, 100000)
print(f"doubled: hook at 1 cm/s from 6 cm, -4 cm/s: euler {double:.4f}, 2 x closed form {2 * forced(2):.4f}")
both = lambda t: hook(t) + forced(t)
print(f"mistake, adding two forced solutions: forcing at t = 2 is {L(both, 2):.3f}, not {hook(2):.3f}")
pend = lambda y, t: L(y, t) - y(t) + sin(y(t))      # the pendulum's y'' + sin y
print(f"mistake, pendulum y'' + sin y = 0: y = pi leaves {pend(lambda t: pi, 1):.3f}, "
      f"y = pi/2 leaves {pend(lambda t: pi / 2, 1):.3f}")
print(f"mistake, start determinant: cos t, sin t -> {det(cos, sin):.3f}; "
      f"cos t, 2 cos t -> {det(cos, lambda t: 2 * cos(t)):.3f}")
assert worst < 1e-5 and abs(L(both, 2) - 2.0) < 1e-5        # combinations pass; a sum of forced ones does not
assert abs(euler(f_half, 3, -2, 2, 100000) - forced(2)) < 1e-3  # the two roads agree
assert 9 < errs[1] / errs[2] < 11                            # error shrinks with the step
assert abs(double - 2 * forced(2)) < 2e-3                   # double the forcing, double the answer
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
residual y'' + y, largest over cos t, sin t, 3 cos t - 2 sin t: 0.000000
y'^2 + y^2 for 3 cos t - 2 sin t at t = 0, 1, 2: 13.000, 13.000, 13.000; amplitude 3.61 cm
forcing of t/2 at t = 1, 2, 3: 0.500, 1.000, 1.500
forced solution: c1 = 3.0, c2 = -2.5; start 3.000 cm, -2.000 cm/s; forcing at t = 2 is 1.000
chart, t/2: 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.25, 3.50, 3.75, 4.00
chart, 3 cos t - 2 sin t: 3.00, 1.67, -0.06, -1.78, -3.07, -3.60, -3.25, -2.11, -0.45, 1.32, 2.77, 3.54, 3.44, 2.50, 0.95, -0.84, -2.42
chart, t/2 + 3 cos t - 2.5 sin t: 3.00, 1.68, 0.02, -1.53, -2.52, -2.65, -1.82, -0.18, 1.93, 4.06, 5.75, 6.64, 6.58, 5.64, 4.12, 2.44, 1.09
euler, 1000 steps to t = 2: y = -2.5287, closed form -2.5217, error 0.00705
euler, 10000 steps to t = 2: y = -2.5224, closed form -2.5217, error 0.00070
euler, 100000 steps to t = 2: y = -2.5218, closed form -2.5217, error 0.00007
euler, error ratio 10000 vs 100000 steps: 10.00
at t = 2: cos t = -0.4161, sin t = 0.9093; euler free swing -3.0671, closed form -3.0670; period 2 pi = 6.2832
doubled: hook at 1 cm/s from 6 cm, -4 cm/s: euler -5.0435, 2 x closed form -5.0434
mistake, adding two forced solutions: forcing at t = 2 is 2.000, not 1.000
mistake, pendulum y'' + sin y = 0: y = pi leaves 0.000, y = pi/2 leaves 1.000
mistake, start determinant: cos t, sin t -> 1.000; cos t, 2 cos t -> 0.000
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Superposition -- the same check as the Python, in Rust, std only.
// A weight on a spring: y'' + y = f(t), y in cm above rest, t in s.  Road one:
// closed forms, tested by substitution.  Road two: Euler's rule.
use std::f64::consts::PI;

// y'' + y, with y'' by a centred difference
fn l(y: &dyn Fn(f64) -> f64, t: f64) -> f64 {
    let d = 1e-3;
    (y(t + d) - 2.0 * y(t) + y(t - d)) / (d * d) + y(t)
}
fn slope(y: &dyn Fn(f64) -> f64, t: f64) -> f64 { let d = 1e-6; (y(t + d) - y(t - d)) / (2.0 * d) }
fn det(g1: &dyn Fn(f64) -> f64, g2: &dyn Fn(f64) -> f64) -> f64 { g1(0.0) * slope(g2, 0.0) - g2(0.0) * slope(g1, 0.0) }
// y' = v, v' = f(t) - y, in n small steps
fn euler(f: &dyn Fn(f64) -> f64, y0: f64, v0: f64, t_end: f64, n: usize) -> f64 {
    let (h, mut y, mut v) = (t_end / n as f64, y0, v0);
    for k in 0..n { let (y1, v1) = (y + h * v, v + h * (f(k as f64 * h) - y)); y = y1; v = v1; }
    y
}
fn list(g: &dyn Fn(f64) -> f64, ts: &[f64], p: usize) -> String {
    ts.iter().map(|&t| format!("{:.*}", p, g(t))).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (cos, sin) = (|t: f64| t.cos(), |t: f64| t.sin());
    let combo = |t: f64| 3.0 * t.cos() - 2.0 * t.sin(); // free swing from 3 cm, -2 cm/s
    let hook = |t: f64| t / 2.0; // one forced solution: follow the hook
    let forced = |t: f64| t / 2.0 + 3.0 * t.cos() - 2.5 * t.sin();
    let ts = [0.5, 1.0, 2.0, 3.0];
    let grid: Vec<f64> = (0..17).map(|k| k as f64 / 2.0).collect();
    let mut worst: f64 = 0.0;
    for g in [&cos as &dyn Fn(f64) -> f64, &sin, &combo] { for &t in &ts { worst = worst.max(l(g, t).abs()); } }
    let (c1, c2) = (3.0, -2.0 - 0.5); // y(0) = c1, y'(0) = 1/2 + c2
    let energy: Vec<f64> = [0.0f64, 1.0, 2.0].iter()
        .map(|&t| (-3.0 * t.sin() - 2.0 * t.cos()).powi(2) + combo(t).powi(2)).collect();
    println!("residual y'' + y, largest over cos t, sin t, 3 cos t - 2 sin t: {:.6}", worst);
    println!("y'^2 + y^2 for 3 cos t - 2 sin t at t = 0, 1, 2: {:.3}, {:.3}, {:.3}; amplitude {:.2} cm",
        energy[0], energy[1], energy[2], energy[0].sqrt());
    println!("forcing of t/2 at t = 1, 2, 3: {}", list(&|t| l(&hook, t), &[1.0, 2.0, 3.0], 3));
    println!("forced solution: c1 = {:.1}, c2 = {:.1}; start {:.3} cm, {:.3} cm/s; forcing at t = 2 is {:.3}",
        c1, c2, forced(0.0), slope(&forced, 0.0), l(&forced, 2.0));
    println!("chart, t/2: {}", list(&hook, &grid, 2));
    println!("chart, 3 cos t - 2 sin t: {}", list(&combo, &grid, 2));
    println!("chart, t/2 + 3 cos t - 2.5 sin t: {}", list(&forced, &grid, 2));
    let (f_half, f_one) = (|t: f64| t / 2.0, |t: f64| t);
    let mut errs = Vec::new();
    for n in [1000usize, 10000, 100000] {
        let y = euler(&f_half, 3.0, -2.0, 2.0, n);
        errs.push((y - forced(2.0)).abs());
        println!("euler, {} steps to t = 2: y = {:.4}, closed form {:.4}, error {:.5}", n, y, forced(2.0), errs[errs.len() - 1]);
    }
    println!("euler, error ratio 10000 vs 100000 steps: {:.2}", errs[1] / errs[2]);
    let free = euler(&|_t| 0.0, 3.0, -2.0, 2.0, 100000);
    println!("at t = 2: cos t = {:.4}, sin t = {:.4}; euler free swing {:.4}, closed form {:.4}; period 2 pi = {:.4}",
        2f64.cos(), 2f64.sin(), free, combo(2.0), 2.0 * PI);
    let double = euler(&f_one, 6.0, -4.0, 2.0, 100000);
    println!("doubled: hook at 1 cm/s from 6 cm, -4 cm/s: euler {:.4}, 2 x closed form {:.4}", double, 2.0 * forced(2.0));
    let both = |t: f64| hook(t) + forced(t);
    println!("mistake, adding two forced solutions: forcing at t = 2 is {:.3}, not {:.3}", l(&both, 2.0), hook(2.0));
    let pend = |y: &dyn Fn(f64) -> f64, t: f64| l(y, t) - y(t) + y(t).sin(); // the pendulum's y'' + sin y
    println!("mistake, pendulum y'' + sin y = 0: y = pi leaves {:.3}, y = pi/2 leaves {:.3}",
        pend(&|_t| PI, 1.0), pend(&|_t| PI / 2.0, 1.0));
    println!("mistake, start determinant: cos t, sin t -> {:.3}; cos t, 2 cos t -> {:.3}",
        det(&cos, &sin), det(&cos, &|t: f64| 2.0 * t.cos()));
    assert!(worst < 1e-5 && (l(&both, 2.0) - 2.0).abs() < 1e-5); // combinations pass; a sum of forced ones does not
    assert!((euler(&f_half, 3.0, -2.0, 2.0, 100000) - forced(2.0)).abs() < 1e-3); // the two roads agree
    assert!(errs[1] / errs[2] > 9.0 && errs[1] / errs[2] < 11.0); // error shrinks with the step
    assert!((double - 2.0 * forced(2.0)).abs() < 2e-3); // double the forcing, double the answer
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
residual y'' + y, largest over cos t, sin t, 3 cos t - 2 sin t: 0.000000
y'^2 + y^2 for 3 cos t - 2 sin t at t = 0, 1, 2: 13.000, 13.000, 13.000; amplitude 3.61 cm
forcing of t/2 at t = 1, 2, 3: 0.500, 1.000, 1.500
forced solution: c1 = 3.0, c2 = -2.5; start 3.000 cm, -2.000 cm/s; forcing at t = 2 is 1.000
chart, t/2: 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00, 3.25, 3.50, 3.75, 4.00
chart, 3 cos t - 2 sin t: 3.00, 1.67, -0.06, -1.78, -3.07, -3.60, -3.25, -2.11, -0.45, 1.32, 2.77, 3.54, 3.44, 2.50, 0.95, -0.84, -2.42
chart, t/2 + 3 cos t - 2.5 sin t: 3.00, 1.68, 0.02, -1.53, -2.52, -2.65, -1.82, -0.18, 1.93, 4.06, 5.75, 6.64, 6.58, 5.64, 4.12, 2.44, 1.09
euler, 1000 steps to t = 2: y = -2.5287, closed form -2.5217, error 0.00705
euler, 10000 steps to t = 2: y = -2.5224, closed form -2.5217, error 0.00070
euler, 100000 steps to t = 2: y = -2.5218, closed form -2.5217, error 0.00007
euler, error ratio 10000 vs 100000 steps: 10.00
at t = 2: cos t = -0.4161, sin t = 0.9093; euler free swing -3.0671, closed form -3.0670; period 2 pi = 6.2832
doubled: hook at 1 cm/s from 6 cm, -4 cm/s: euler -5.0435, 2 x closed form -5.0434
mistake, adding two forced solutions: forcing at t = 2 is 2.000, not 1.000
mistake, pendulum y'' + sin y = 0: y = pi leaves 0.000, y = pi/2 leaves 1.000
mistake, start determinant: cos t, sin t -> 1.000; cos t, 2 cos t -> 0.000
ALL CHECKS PASS
```

### Lean

Lean proves superposition for every second-order linear equation with continuous p(t), q(t) and f(t), and the spring's motions for every start.

- For any weights a and b, a weighted sum of two solutions meets the same weighted sum of their forcings.
- So a weighted sum of free solutions is free, and two forced solutions add to one with the forcing doubled.
- Take two free solutions whose starting table has determinant not 0, and one forced solution.
- A curve then solves the forced equation exactly when it is that forced solution plus a mix of the two free ones.
- The two weights of that mix are unique.
- For the spring, every free motion is y(0) cos t + y'(0) sin t, so the starting height and speed are the weights.
- With the hook rising, every motion is t/2 + y(0) cos t + (y'(0) − 1/2) sin t.
- By plain arithmetic: (−2)^2 + 3^2 = 13, the forced weights are 3 and −2.5, and the start determinants are 1 and 0.
- Also by arithmetic: two forced solutions carry forcing 2, not 1, at t = 2 s, and the pendulum residuals are 0 and 1.

The decimals, the Euler runs, the energy over time, the chart and the doubled run's −5.0434 are left to the Python and Rust checks.

```lean
-- Superposition: for a second-order linear equation y'' + p y' + q y = f, weighted sums of solutions solve the equation with the same weighted sum of forcings, every solution is one forced solution plus a unique mix of two independent free solutions, and for the spring y'' + y = 0 (and y'' + y = t/2) the starting height and speed fix the mix.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Tactic.NormNum

set_option autoImplicit false

open Real

/-- `y` solves the second-order linear equation `y'' + p(t) y' + q(t) y = f(t)` at every time:
`y` and its rate `y'` are differentiable, and the acceleration plus `p` times the speed plus
`q` times the height equals the forcing `f`. With `f = 0` the solution is free (homogeneous). -/
def IsSolution (p q f : ℝ → ℝ) (y : ℝ → ℝ) : Prop :=
  Differentiable ℝ y ∧ Differentiable ℝ (deriv y) ∧
    ∀ t, deriv (deriv y) t + p t * deriv y t + q t * y t = f t

theorem slin_deriv_comb (y₁ y₂ : ℝ → ℝ) (a b : ℝ) (h₁ : Differentiable ℝ y₁)
    (h₂ : Differentiable ℝ y₂) :
    deriv (fun t => a * y₁ t + b * y₂ t) = fun t => a * deriv y₁ t + b * deriv y₂ t := by
  funext t
  exact (((h₁ t).hasDerivAt.const_mul a).add ((h₂ t).hasDerivAt.const_mul b)).deriv

#print axioms slin_deriv_comb

theorem slin_comb_solution
    (p q f₁ f₂ y₁ y₂ : ℝ → ℝ) (a b : ℝ)
    (h₁ : IsSolution p q f₁ y₁) (h₂ : IsSolution p q f₂ y₂) :
    IsSolution p q (fun t => a * f₁ t + b * f₂ t) (fun t => a * y₁ t + b * y₂ t) := by
  obtain ⟨d₁, dd₁, e₁⟩ := h₁
  obtain ⟨d₂, dd₂, e₂⟩ := h₂
  have hd := slin_deriv_comb y₁ y₂ a b d₁ d₂
  have hdd := slin_deriv_comb (deriv y₁) (deriv y₂) a b dd₁ dd₂
  refine ⟨(d₁.const_mul a).add (d₂.const_mul b), ?_, ?_⟩
  · rw [hd]; exact (dd₁.const_mul a).add (dd₂.const_mul b)
  · intro t
    rw [hd, hdd]
    linear_combination a * e₁ t + b * e₂ t

#print axioms slin_comb_solution

theorem slin_congr (p q f f' y y' : ℝ → ℝ) (h : IsSolution p q f y)
    (hf : ∀ t, f t = f' t) (hy : ∀ t, y t = y' t) : IsSolution p q f' y' := by
  have e1 : f = f' := funext hf
  have e2 : y = y' := funext hy
  subst e1 e2
  exact h

#print axioms slin_congr

theorem slin_free_unique (p q : ℝ → ℝ) (hp : Continuous p) (hq : Continuous q)
    (w : ℝ → ℝ) (hw : IsSolution p q 0 w) (h0 : w 0 = 0) (h1 : deriv w 0 = 0) :
    ∀ t, w t = 0 := by
  intro t
  obtain ⟨hd, hdd, heq⟩ := hw
  set R : ℝ := |t| + 1 with hR
  have hc : IsCompact (Set.Icc (-R) R) := isCompact_Icc
  obtain ⟨Cp, hCp⟩ := hc.exists_bound_of_continuousOn hp.continuousOn
  obtain ⟨Cq, hCq⟩ := hc.exists_bound_of_continuousOn hq.continuousOn
  let v : ℝ → ℝ × ℝ → ℝ × ℝ := fun s x => (x.2, -(p s * x.2) - q s * x.1)
  let F : ℝ → ℝ × ℝ := fun s => (w s, deriv w s)
  have hF : ∀ s, HasDerivAt F (v s (F s)) s := by
    intro s
    have h := ((hd s).hasDerivAt).prodMk ((hdd s).hasDerivAt)
    convert h using 1
    have := heq s
    simp only [Pi.zero_apply] at this
    simp only [v, F, Prod.mk.injEq, true_and]
    linarith
  have hG : ∀ s, HasDerivAt (fun _ => (0 : ℝ × ℝ)) (v s 0) s := by
    intro s
    have h0v : v s 0 = 0 := by simp [v]
    rw [h0v]
    exact hasDerivAt_const s (0 : ℝ × ℝ)
  let K : NNReal := ⟨1 + |Cp| + |Cq|, by positivity⟩
  have hlip : ∀ s ∈ Set.Ioo (-R) R, LipschitzOnWith K (v s) Set.univ := by
    intro s hs
    have hs' : s ∈ Set.Icc (-R) R := Set.Ioo_subset_Icc_self hs
    have hps : |p s| ≤ |Cp| := by
      have := hCp s hs'; rw [Real.norm_eq_abs] at this; exact this.trans (le_abs_self _)
    have hqs : |q s| ≤ |Cq| := by
      have := hCq s hs'; rw [Real.norm_eq_abs] at this; exact this.trans (le_abs_self _)
    refine (LipschitzWith.of_dist_le_mul fun x y => ?_).lipschitzOnWith
    have hK : (K : ℝ) = 1 + |Cp| + |Cq| := rfl
    rw [hK]
    simp only [Prod.dist_eq, Real.dist_eq, v]
    set M := max |x.1 - y.1| |x.2 - y.2|
    have ha : |x.1 - y.1| ≤ M := le_max_left _ _
    have hb : |x.2 - y.2| ≤ M := le_max_right _ _
    have hM : 0 ≤ M := (abs_nonneg _).trans ha
    have hCp0 : 0 ≤ |Cp| := abs_nonneg _
    have hCq0 : 0 ≤ |Cq| := abs_nonneg _
    apply max_le
    · nlinarith
    · have e : -(p s * x.2) - q s * x.1 - (-(p s * y.2) - q s * y.1)
          = -(p s * (x.2 - y.2)) + -(q s * (x.1 - y.1)) := by ring
      rw [e]
      calc |-(p s * (x.2 - y.2)) + -(q s * (x.1 - y.1))|
          ≤ |-(p s * (x.2 - y.2))| + |-(q s * (x.1 - y.1))| := abs_add_le _ _
        _ = |p s| * |x.2 - y.2| + |q s| * |x.1 - y.1| := by rw [abs_neg, abs_neg, abs_mul, abs_mul]
        _ ≤ |Cp| * M + |Cq| * M := by
            gcongr
        _ ≤ (1 + |Cp| + |Cq|) * M := by nlinarith
  have hRpos : (0 : ℝ) ∈ Set.Ioo (-R) R := by
    constructor <;> [skip; skip] <;> (have := abs_nonneg t; linarith)
  have htR : t ∈ Set.Ioo (-R) R := by
    constructor
    · have := neg_abs_le t; linarith
    · have := le_abs_self t; linarith
  have key := ODE_solution_unique_of_mem_Ioo hlip hRpos
    (fun s _ => ⟨hF s, Set.mem_univ _⟩) (fun s _ => ⟨hG s, Set.mem_univ _⟩)
    (by simp [F, h0, h1]) htR
  have := congrArg Prod.fst key
  simpa [F] using this

#print axioms slin_free_unique

theorem slin_ivp_unique (p q f : ℝ → ℝ) (hp : Continuous p) (hq : Continuous q)
    (y g : ℝ → ℝ) (hy : IsSolution p q f y) (hg : IsSolution p q f g)
    (h0 : y 0 = g 0) (h1 : deriv y 0 = deriv g 0) : ∀ t, y t = g t := by
  have hw := slin_congr _ _ _ 0 _ (fun t => y t - g t)
    (slin_comb_solution p q f f y g 1 (-1) hy hg) (fun t => by simp) (fun t => by ring)
  have hd : deriv (fun t => y t - g t) 0 = 0 := by
    have hc := slin_deriv_comb y g 1 (-1) hy.1 hg.1
    have e : (fun t => y t - g t) = fun t => 1 * y t + (-1) * g t := by funext t; ring
    rw [e, hc]
    simp [h1]
  intro t
  have := slin_free_unique p q hp hq _ hw (by simp [h0]) hd t
  exact sub_eq_zero.mp this

#print axioms slin_ivp_unique

theorem slin_mix_solution (p q f yp y₁ y₂ : ℝ → ℝ) (c₁ c₂ : ℝ)
    (hyp : IsSolution p q f yp) (h₁ : IsSolution p q 0 y₁) (h₂ : IsSolution p q 0 y₂) :
    IsSolution p q f (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) ∧
      deriv (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) =
        fun t => deriv yp t + c₁ * deriv y₁ t + c₂ * deriv y₂ t := by
  have hu := slin_comb_solution p q 0 0 y₁ y₂ c₁ c₂ h₁ h₂
  have hs := slin_comb_solution p q f _ yp _ 1 1 hyp hu
  constructor
  · exact slin_congr _ _ _ _ _ _ hs (fun t => by simp) (fun t => by ring)
  · have e : (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t)
        = fun t => 1 * yp t + 1 * (c₁ * y₁ t + c₂ * y₂ t) := by funext t; ring
    rw [e, slin_deriv_comb yp (fun t => c₁ * y₁ t + c₂ * y₂ t) 1 1 hyp.1 hu.1,
      slin_deriv_comb y₁ y₂ c₁ c₂ h₁.1 h₂.1]
    funext t
    ring

#print axioms slin_mix_solution

/-- Superposition for any second-order linear equation `y'' + p(t) y' + q(t) y = f(t)` with
continuous coefficients `p`, `q` and continuous forcing `f`. Take two free solutions `y₁`, `y₂`
that are independent (their starting table has determinant
`y₁(0) y₂'(0) - y₂(0) y₁'(0) ≠ 0`) and one forced solution `yp`. Then a curve `y` solves the
forced equation exactly when it is `yp` plus a weighted sum `c₁ y₁ + c₂ y₂`, and the
weights are unique: the forced solutions are one forced solution plus the free family, and two
independent free solutions cover that family. -/
theorem solutions_are_one_forced_plus_free_mix
    (p q f : ℝ → ℝ) (hp : Continuous p) (hq : Continuous q) (hf : Continuous f)
    (y₁ y₂ yp : ℝ → ℝ) (h₁ : IsSolution p q 0 y₁) (h₂ : IsSolution p q 0 y₂)
    (hind : y₁ 0 * deriv y₂ 0 - y₂ 0 * deriv y₁ 0 ≠ 0)
    (hyp : IsSolution p q f yp) (y : ℝ → ℝ) :
    IsSolution p q f y ↔ ∃! c : ℝ × ℝ, ∀ t, y t = yp t + c.1 * y₁ t + c.2 * y₂ t := by
  constructor
  · intro hy
    set W := y₁ 0 * deriv y₂ 0 - y₂ 0 * deriv y₁ 0 with hW
    set z₀ := y 0 - yp 0 with hz₀
    set z₁ := deriv y 0 - deriv yp 0 with hz₁
    set c₁ := (z₀ * deriv y₂ 0 - y₂ 0 * z₁) / W with hc₁
    set c₂ := (y₁ 0 * z₁ - z₀ * deriv y₁ 0) / W with hc₂
    obtain ⟨hg, hgd⟩ := slin_mix_solution p q f yp y₁ y₂ c₁ c₂ hyp h₁ h₂
    have hex : ∀ t, y t = yp t + c₁ * y₁ t + c₂ * y₂ t := by
      refine slin_ivp_unique p q f hp hq y _ hy hg ?_ ?_
      · show y 0 = yp 0 + c₁ * y₁ 0 + c₂ * y₂ 0
        rw [hc₁, hc₂]
        field_simp
        rw [hz₀, hz₁, hW]
        ring
      · rw [hgd]
        show deriv y 0 = deriv yp 0 + c₁ * deriv y₁ 0 + c₂ * deriv y₂ 0
        rw [hc₁, hc₂]
        field_simp
        rw [hz₀, hz₁, hW]
        ring
    refine ⟨(c₁, c₂), hex, fun c' hc' => ?_⟩
    have hfun : (fun t => yp t + c'.1 * y₁ t + c'.2 * y₂ t)
        = (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) :=
      funext fun t => (hc' t).symm.trans (hex t)
    have hdd : deriv (fun t => yp t + c'.1 * y₁ t + c'.2 * y₂ t) 0
        = deriv (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) 0 := by rw [hfun]
    rw [(slin_mix_solution p q f yp y₁ y₂ c'.1 c'.2 hyp h₁ h₂).2, hgd] at hdd
    have e₁ : (c'.1 - c₁) * y₁ 0 + (c'.2 - c₂) * y₂ 0 = 0 := by
      have := (hc' 0).symm.trans (hex 0); linarith
    have e₂ : (c'.1 - c₁) * deriv y₁ 0 + (c'.2 - c₂) * deriv y₂ 0 = 0 := by linarith
    have ha : (c'.1 - c₁) * W = 0 := by
      rw [hW]; linear_combination (deriv y₂ 0) * e₁ - (y₂ 0) * e₂
    have hb : (c'.2 - c₂) * W = 0 := by
      rw [hW]; linear_combination (y₁ 0) * e₂ - (deriv y₁ 0) * e₁
    have ha' := (mul_eq_zero.mp ha).resolve_right hind
    have hb' := (mul_eq_zero.mp hb).resolve_right hind
    exact Prod.ext (by linarith) (by linarith)
  · rintro ⟨c, hc, -⟩
    exact slin_congr _ _ _ _ _ _ (slin_mix_solution p q f yp y₁ y₂ c.1 c.2 hyp h₁ h₂).1
      (fun _ => rfl) (fun t => (hc t).symm)

/-- Step 0: the machine `L[y] = y'' + p y' + q y` respects sums and multiples. If `y₁` meets
forcing `f₁` and `y₂` meets forcing `f₂`, then `a y₁ + b y₂` meets forcing `a f₁ + b f₂`,
for any numbers `a`, `b` and any coefficients `p`, `q`. So any weighted sum of free solutions
is free (`f₁ = f₂ = 0`), two forced solutions add to one with the forcing doubled, and twice a
motion needs twice the forcing. -/
theorem linear_operator_respects_weighted_sums
    (p q f₁ f₂ y₁ y₂ : ℝ → ℝ) (a b : ℝ)
    (h₁ : IsSolution p q f₁ y₁) (h₂ : IsSolution p q f₂ y₂) :
    IsSolution p q (fun t => a * f₁ t + b * f₂ t) (fun t => a * y₁ t + b * y₂ t) := by
  exact slin_comb_solution p q f₁ f₂ y₁ y₂ a b h₁ h₂

/-- The spring, Steps 2 to 4: every free motion of `y'' + y = 0` is
`y(0) cos t + y'(0) sin t`, so the starting height and speed are the two weights; and every
motion of `y'' + y = t/2`, with the hook rising, is `t/2 + y(0) cos t + (y'(0) - 1/2) sin t`. -/
theorem spring_motion_fixed_by_start (y : ℝ → ℝ) :
    (IsSolution 0 1 0 y → ∀ t, y t = y 0 * cos t + deriv y 0 * sin t) ∧
    (IsSolution 0 1 (fun t => t / 2) y →
      ∀ t, y t = t / 2 + y 0 * cos t + (deriv y 0 - 1 / 2) * sin t) := by
  have hdc : deriv (fun x => -sin x) = fun x => -cos x := by
    funext x; exact (hasDerivAt_sin x).neg.deriv
  have hcos : IsSolution 0 1 0 cos := by
    refine ⟨differentiable_cos, ?_, fun t => ?_⟩
    · rw [deriv_cos']; exact differentiable_sin.neg
    · rw [deriv_cos', hdc]; simp
  have hsin : IsSolution 0 1 0 sin := by
    refine ⟨differentiable_sin, ?_, fun t => ?_⟩
    · rw [Real.deriv_sin]; exact differentiable_cos
    · rw [Real.deriv_sin, deriv_cos']; simp
  have hl : deriv (fun t : ℝ => t / 2) = fun _ => 1 / 2 := by
    funext t; exact ((hasDerivAt_id' t).div_const 2).deriv
  have hlin : IsSolution 0 1 (fun t => t / 2) (fun t => t / 2) := by
    refine ⟨fun t => ((hasDerivAt_id' t).div_const 2).differentiableAt, ?_, fun t => ?_⟩
    · rw [hl]; exact differentiable_const _
    · rw [hl]; simp
  constructor
  · intro hy
    have hg := slin_congr _ _ _ 0 _ _
      (slin_comb_solution 0 1 0 0 cos sin (y 0) (deriv y 0) hcos hsin)
      (fun t => by simp) (fun _ => rfl)
    refine slin_ivp_unique 0 1 0 continuous_zero continuous_one y _ hy hg (by simp) ?_
    have h : HasDerivAt (fun t => y 0 * cos t + deriv y 0 * sin t)
        (y 0 * -sin 0 + deriv y 0 * cos 0) 0 :=
      ((hasDerivAt_cos 0).const_mul (y 0)).add ((hasDerivAt_sin 0).const_mul (deriv y 0))
    rw [h.deriv]
    simp
  · intro hy
    have hu := slin_congr _ _ _ 0 _ _
      (slin_comb_solution 0 1 0 0 cos sin (y 0) (deriv y 0 - 1 / 2) hcos hsin)
      (fun t => by simp) (fun _ => rfl)
    have hg := slin_congr _ _ _ (fun t => t / 2) _
      (fun t => t / 2 + y 0 * cos t + (deriv y 0 - 1 / 2) * sin t)
      (slin_comb_solution 0 1 _ _ _ _ 1 1 hlin hu) (fun t => by simp) (fun t => by ring)
    refine slin_ivp_unique 0 1 _ continuous_zero continuous_one y _ hy hg (by simp) ?_
    have h : HasDerivAt (fun t => t / 2 + y 0 * cos t + (deriv y 0 - 1 / 2) * sin t)
        (1 / 2 + y 0 * -sin 0 + (deriv y 0 - 1 / 2) * cos 0) 0 :=
      (((hasDerivAt_id' 0).div_const 2).add ((hasDerivAt_cos 0).const_mul (y 0))).add
        ((hasDerivAt_sin 0).const_mul (deriv y 0 - 1 / 2))
    rw [h.deriv]
    simp

-- Free weights from the start 3 cm, -2 cm/s, and twice the energy per kg: (-2)^2 + 3^2 = 13.
example : (-2 : ℤ) ^ 2 + 3 ^ 2 = 13 := by norm_num
-- Forced weights with the hook: 3 = 0 + c₁ and -2 = 1/2 + c₂ give c₁ = 3 and c₂ = -5/2.
example : (3 : ℚ) = 0 + 3 ∧ (-2 : ℚ) = 1 / 2 + (-5 / 2) := by norm_num
-- The starting table of cos t and sin t has determinant 1; of cos t and 2 cos t, determinant 0.
example : cos 0 * cos 0 - sin 0 * (-sin 0) = 1 ∧
    cos 0 * (2 * -sin 0) - 2 * cos 0 * (-sin 0) = 0 := by simp
-- The forcing t/2 at t = 2 s is 1; two forced solutions added carry forcing 2, not 1.
example : (2 : ℚ) / 2 = 1 ∧ (2 : ℚ) / 2 + 2 / 2 = 2 := by norm_num
-- The pendulum y'' + sin y = 0: the balance y = π leaves residual 0, its half y = π/2 leaves 1.
example : sin π = 0 ∧ sin (π / 2) = 1 := ⟨sin_pi, sin_pi_div_two⟩
-- Doubled hook and start: 1 cm/s = 2 × 1/2, 6 = 2 × 3, -4 = 2 × (-2).
example : (1 : ℚ) = 2 * (1 / 2) ∧ (6 : ℤ) = 2 * 3 ∧ (-4 : ℤ) = 2 * (-2) := by norm_num

#print axioms solutions_are_one_forced_plus_free_mix
#print axioms linear_operator_respects_weighted_sums
#print axioms spring_motion_fixed_by_start
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'slin_deriv_comb' depends on axioms: [propext, Classical.choice, Quot.sound]
'slin_comb_solution' depends on axioms: [propext, Classical.choice, Quot.sound]
'slin_congr' depends on axioms: [propext, Classical.choice, Quot.sound]
'slin_free_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'slin_ivp_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'slin_mix_solution' depends on axioms: [propext, Classical.choice, Quot.sound]
'solutions_are_one_forced_plus_free_mix' depends on axioms: [propext, Classical.choice, Quot.sound]
'linear_operator_respects_weighted_sums' depends on axioms: [propext, Classical.choice, Quot.sound]
'spring_motion_fixed_by_start' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Start the forced Euler run at 6 and −4 but keep the forcing t/2.** Guess whether the answer doubles. It does not: the hook part t/2 stays single, so the result lands below −5.0434.
> - **Add 1000000 to the list of step counts.** Guess the error first. About a tenth of 0.00007: Euler's rule is first order, so its error is proportional to the step.
> - **Swap the second function in the start determinant for cos t + sin t.** Guess whether the pair is independent. It is: the determinant reads 1.000, and every start can be reached.

---

## The usual mistake

> [!warning]
> **Adding solutions of a forced equation.** Two forced solutions add to one for twice the forcing: 2.000 cm/s^2 at t = 2 s, not 1.000.
>
> - **Fixing the weights before adding the particular solution.** The free family alone gives −2 for the second weight; the hook's own 0.5 cm/s must be counted, giving −2.5.
> - **Superposing a nonlinear equation.** For a wide-swinging pendulum twice a motion is not a motion: the upside-down balance halved leaves a residual of 1.000.

---

## Where you meet it in real life

- **Structural engineering.** Under small loads a beam bends linearly, so each load case is computed alone and the results added; this fails once the steel yields.
- **Electrical circuits.** A circuit of resistors, coils and capacitors obeys the spring's kind of equation; its response to two sources is the sum of the responses ([The RLC circuit](08-the-rlc-circuit-and-the-spring.md)).
- **Shaking at the natural rhythm.** Shake the hook at the spring's own rhythm and the particular solution grows without bound: [Resonance](06-resonance-and-beats.md).

> **Say it back**
> For a linear equation, the machine that checks a curve respects sums and multiples. So weighted sums of free solutions are free solutions, and two independent ones, here cos t and sin t, cover every free motion. The starting height and speed fix the two weights. A forced solution is one particular solution, here t/2, plus a free one. Double the forcing and the start, and the motion doubles.

---

## What this builds on

- [A differential equation](../01-Rate%20Equations/01-what-a-differential-equation-says.md): rate rules, substitution, and the order counting starting values.
- [Linear combinations and span](../../03-Algebra/03-Vectors/03-linear-combinations-and-span.md): weighted sums, and the set they reach.
- [Basis and dimension](../../03-Algebra/03-Vectors/05-basis-and-dimension.md): why two independent solutions are exactly enough.

## Where this goes next

- [The characteristic equation](02-the-characteristic-equation.md): the two solutions of any constant-coefficient equation, by trying an exponential.
- [Series solutions](../07-Series%20Solutions%20and%20Boundary%20Problems/01-power-series-at-an-ordinary-point.md): the two solutions as power series when coefficients vary.

Left open: for a damped spring, such as a car's shock absorber, which two solutions take the place of cos t and sin t? The characteristic equation supplies them.

---

## Sources

Verified 28 Sep 2026: every link below resolves to the publisher's or the author's own page.

- Lebl, Jiří. *Notes on Diffy Qs: Differential Equations for Engineers*, §2.1 "Second-order linear ODEs". [Author's free edition](https://www.jirka.org/diffyqs/html/solinear_section.html). Superposition (Theorem 2.1.1), uniqueness, and the general solution.
- OpenStax. *Calculus Volume 3*, §7.1 "Second-Order Linear Equations". [OpenStax](https://openstax.org/books/calculus-volume-3/pages/7-1-second-order-linear-equations). Superposition, and particular plus homogeneous for forced equations.
- Teschl, Gerald. *Ordinary Differential Equations and Dynamical Systems*. AMS Graduate Studies in Mathematics 140. [Author's text, posted with AMS permission](https://mat.univie.ac.at/~gerald/ftp/book-ode/). §3.2 and §3.5: the solution space's dimension, and forced solutions as one plus that space.
