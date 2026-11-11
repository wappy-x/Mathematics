# Line integrals of a function: mass of a wire from its density

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Vector Calculus](../README.md#s09) → Line integrals of a function

---

## General Overview

A wire is bent into a curve: from above it follows the parabola y = x^2/2, from x = 1 m to x = 2 m. It is drawn thicker as it goes. Its **density**, the mass of one metre of wire, rises from 3 kg/m at the near end to 6 kg/m at the far end. At a point x metres along the ground it is 3x kg/m. How heavy is the wire?

Density times length fails, because the density changes. Cut the wire into short pieces. Each piece weighs about its density at its middle times its length. Add the pieces. One straight piece, end to end, gives 8.112490 kg. Four pieces give 8.337034 kg. Sixteen give 8.350983 kg. The totals close in on 8.351913 kg, the wire's mass.

That limit is a **line integral of a function**: a function (here density) added along a curve, each bit weighted by the length of wire it sits on.

It can be computed from any clock that runs along the wire once, with no pieces at all. The answer does not depend on the clock or the end it starts from. Such a clock is a **parametrisation** of the curve; its reading t is the **parameter**, and the end it starts from is its **orientation**.

<p align="center"><img src="../figures/scalar-line-integrals.svg" alt="A wire along y = x^2/2 from x = 1 to 2 m drawn to scale, with the four-chord chain under it and the density marked at both ends" width="420"></p>

Drawn to scale at 100 units per metre in both directions; the bottom line is y = 0. Chord points every 0.25 m of x; a chord is a straight piece joining two points of the wire.

**The mass of a wire is the limit of density times piece length as the pieces shrink, and it equals the integral of density times speed along any clock that runs the wire once, in either direction.**

**What kind of fact this is:** a definition (the limit of pieces) and a theorem: that it equals the speed formula for every such clock, proved on this card in Why it works.

---

## The formula

Notation first, in words. The integral sign with a C at its foot means "add along the curve C". The $ds$ after it names what is added over: tiny lengths of wire, measured along the wire, never negative. The Greek letter $\rho$ (rho) stands for density.

$$M = \int_C \rho\, ds = \int_a^b \rho\big(x(t), y(t)\big)\,\sqrt{x'(t)^2 + y'(t)^2}\; dt$$

**Read it aloud:** the mass adds density times length along the wire; with a clock t, that is density at the point reached, times the speed there, added over the clock.

The square root is the clock's **speed**: metres of wire per unit of clock, as on [Arc length](../05-Curves%20and%20Solids/02-arc-length.md). It turns a step of clock into a length of wire.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $C$ | the curve the wire follows, run once | y = x^2/2, x from 1 to 2 m | a longer wire weighs more |
| $M$ | the wire's mass, kg | 8.351913 kg | — |
| $\rho$ | density at a point: kg per metre of wire | 3x, so 3 to 6 kg/m | mass rises in step |
| $ds$ | a tiny length along the wire, always positive | — | — |
| $t$, $a$, $b$ | a clock and its start and end | x = t, t from 1 to 2 | a faster clock changes speed, not mass |
| $x(t)$, $y(t)$ | where the clock has reached | t and t^2/2 | — |
| $x'(t)$, $y'(t)$ | their rates: metres per unit of clock | 1 and t | more speed, more wire per tick |
| $n$ | number of straight pieces | 4 | more pieces, closer total |

Units: kg/m times metres per unit of clock, added over the clock, leaves kg.

### When it holds

- **The wire has no jumps, and the clock's rates change without jumps.** A corner is fine: split there and add the two parts.
- **Density changes without jumps along the wire.** Then short pieces have nearly one density each, which is what Step 2 uses.
- **The clock runs the wire once.** A clock that goes out and back weighs the wire twice: 16.703826 kg.
- **Density is not negative, if the answer is a mass.** A signed function, such as charge, is added the same way and can total below zero.

---

## Why it works

### Step 0: the definition is pieces, not a formula

Cut the wire into n pieces. Take the density at a point of each piece, multiply by the piece's length, and add. The mass is the number these totals close in on as every piece shrinks. The formula is a way to reach that number; the pieces are what it means.

### Step 1: a piece's length is its speed times its clock time

From [Arc length](../05-Curves%20and%20Solids/02-arc-length.md), the length of wire covered while the clock runs from one tick to the next is the integral of speed over that stretch of clock. So the piece total is a sum of density times an integral of speed.

### Step 2: pieces become one integral

Over a short stretch of clock the density barely changes, since it has no jumps. Replace "density at the chosen point" by "density at each instant" inside each piece's speed integral.

This changes the total by at most the largest density change inside a piece, times the whole length of the wire. That change shrinks to zero with the pieces. What remains is one integral over the clock of density times speed: the formula.

The tolerance game, on the wire: to land within 0.001 kg, sixteen equal pieces suffice, off by 0.000930 kg. Each fourfold refinement cuts the error about sixteenfold: 0.014879, 0.000930, 0.000058 kg.

<details>
<summary>Detailed proof: the piece totals tend to the formula</summary>

Let $q(t)$ be the density at the point reached at clock time t, and $v(t)$ the speed. Both are continuous (without jumps) on the closed stretch from a to b, so q is uniformly continuous. For every ε > 0 there is a δ > 0 such that clock times less than δ apart give densities less than ε apart. Let L be the wire's length, the integral of v.

Cut the clock at $a = t_0 < t_1 < \dots < t_n = b$, every step shorter than δ, and pick a clock time $t_{i-1} \le \tau_i \le t_i$ in each step. The piece total is $S = \sum q(\tau_i)\,\ell_i$, where $\ell_i = \int_{t_{i-1}}^{t_i} v(t)\,dt$ is the length of piece i. Let I be the integral of q times v. Then
$$\lvert S - I\rvert = \Big\lvert \sum \int_{t_{i-1}}^{t_i} \big(q(\tau_i) - q(t)\big)\,v(t)\,dt \Big\rvert \le \varepsilon \int_a^b v(t)\,dt = \varepsilon L.$$
Since ε was any positive number, S tends to I whichever points are picked. Speed is never negative, so the bound needs no sign; that is also why reversing the clock cannot flip the total.

</details>

### Step 3: a new clock leaves the mass alone

Run the same wire with a different clock that still runs it once: the old clock t is now some function of a new one, u. The [Chain rule](../02-Derivatives/03-chain-rule.md) says rates multiply when one quantity drives another. Here, each position's rate on the new clock is its old rate times the rate of t per unit of u. So the new speed is the old speed times the size of that rate.

Two effects cancel: a clock twice as fast doubles the speed and halves the clock time. As integrals, this is [Substitution](../04-Integrals/03-substitution.md), the chain rule run backwards, which turns the new integral back into the old one.

On the wire, the clock $x = \sqrt{u}$ for u from 1 to 4 gives speed $\sqrt{1 + u}/(2\sqrt{u})$ and density $3\sqrt{u}$. Their product is $\tfrac{3}{2}\sqrt{1+u}$, and its integral is again 8.351913 kg.

### Step 4: running backwards changes nothing

Reverse the orientation, starting at the far end: $x = 3 - s$, for s from 1 to 2. Now the rate of x is −1, but speed is a square root of squares, so it stays positive. The density met is the same, the lengths are the same, and the total is 8.351913 kg.

As substitution, a backwards clock brings two minus signs, one from taking the rate's size and one from limits in the other order, and they cancel.

<details>
<summary>Why this is different for a force</summary>

Work done by a force uses its component along the direction of travel, so reversing the path flips its sign. Density has no direction, so mass cannot flip. The field version is [Line integrals of a field](02-line-integrals.md).

</details>

A second road to the mass needs no clock at all: the piece totals themselves, straight chords times midpoint density, computed in the code up to 256 pieces.

---

## Worked numbers, by hand

Use the clock x = t, so $x' = 1$ and $y' = t$.

| Step | Arithmetic | Value |
| --- | --- | --- |
| density at the point | 3 times x | 3t kg/m |
| speed | sqrt(1^2 + t^2) | sqrt(1 + t^2) m per m of x |
| what is added | density times speed | 3t sqrt(1 + t^2) |
| an antiderivative | (1 + t^2)^(3/2); its rate, by the chain rule, is (3/2)(1 + t^2)^(1/2) × 2t | matches |
| at the far end, t = 2 | 5^1.5 | 11.180340 |
| at the near end, t = 1 | 2^1.5 | 2.828427 |
| mass | 11.180340 − 2.828427 | **8.351913 kg** |

The wire is 1.810092 m long, so its average density is 4.6141 kg/m. That sits above 4.5, the average of 3 and 6, because the far end is steeper: more wire lies where the density is high.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drop the speed: density times dx | 4.500000 kg | Adds over 1 m of ground, not 1.810092 m of wire |
| Signed length when reversed | −8.351913 kg | ds is a length; it has no direction |
| A clock that runs out and back | 16.703826 kg | The once-through condition dropped: each metre counted twice |
| One straight piece, midpoint density | 8.112490 kg | One density, 4.5 kg/m, for a wire averaging 4.6141 kg/m; and a chord is shorter than the curve |

The code prints all four.

---

## Code, from first principles, and it actually runs

Two roads. One: density times speed, integrated by Simpson's rule on three clocks: x = t, x = sqrt(u), and the reversed x = 3 − s. Simpson's rule is a strip sum that fits a parabola over each pair of strips; the code uses 200 strips. Two: the definition, straight pieces times midpoint density, with the error printed as the pieces shrink. Both are checked against the antiderivative $(1 + t^2)^{3/2}$.

### Python

```python
# Line integral of a function -- the check behind the card.  Standard library
# only; math gives sqrt as a primitive, and every sum below is written out here.
# A wire bent along y = x^2 / 2 from x = 1 to x = 2 m.  Its density is 3x kg/m,
# rising from 3 at the near end to 6 at the far end.  Its mass, two roads.
from math import sqrt

def rho(x, y): return 3 * x                      # density, kg per metre
def y_of(x):   return x * x / 2                  # the wire's shape

def simpson(g, a, b, n=200):                     # Simpson's rule, n even strips
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

def line_integral(x, y, dx, dy, a, b):           # density times speed, over the clock
    return simpson(lambda t: rho(x(t), y(t)) * sqrt(dx(t) ** 2 + dy(t) ** 2), a, b)

def pieces(n):                                   # road two: the definition itself
    xs = [1 + i / n for i in range(n + 1)]
    total = 0.0
    for p, q in zip(xs, xs[1:]):
        chord = sqrt((q - p) ** 2 + (y_of(q) - y_of(p)) ** 2)
        m = (p + q) / 2
        total += rho(m, y_of(m)) * chord         # density at the middle, times chord
    return total

exact = 5 ** 1.5 - 2 ** 1.5                      # (1 + x^2)^(3/2) from x = 1 to 2
by_x = line_integral(lambda t: t, lambda t: t * t / 2, lambda t: 1.0, lambda t: t, 1, 2)
by_u = line_integral(lambda u: sqrt(u), lambda u: u / 2,
                     lambda u: 1 / (2 * sqrt(u)), lambda u: 0.5, 1, 4)
back = line_integral(lambda s: 3 - s, lambda s: (3 - s) ** 2 / 2,
                     lambda s: -1.0, lambda s: -(3 - s), 1, 2)
sign = lambda t: -1.0 if t > 0 else 1.0           # out to the far end, then back
twice = line_integral(lambda t: 2 - abs(t), lambda t: (2 - abs(t)) ** 2 / 2,
                      sign, lambda t: (2 - abs(t)) * sign(t), -1, 1)
length = simpson(lambda t: sqrt(1 + t * t), 1, 2)
print("wire y = x^2/2 from x = 1 to 2 m; density 3x: 3.0 kg/m at the near end, 6.0 at the far end")
print(f"closed form 5^1.5 - 2^1.5 = {5 ** 1.5:.6f} - {2 ** 1.5:.6f} = {exact:.6f} kg")
print(f"clock x = t, t from 1 to 2, speed sqrt(1 + t^2): {by_x:.6f} kg")
print(f"clock x = sqrt(u), u from 1 to 4, speed sqrt(1 + u)/(2 sqrt u): {by_u:.6f} kg")
print(f"reversed, x = 3 - s, s from 1 to 2, far end first: {back:.6f} kg")
for n in (1, 4, 16, 64, 256):
    print(f"pieces {n:5d}: density x chord {pieces(n):.6f} kg, off by {pieces(n) - exact:+.6f}")
print(f"wire length (density 1): {length:.6f} m; average density {exact / length:.4f} kg/m")
print(f"mistake, drop the speed (density x dx): {simpson(lambda t: rho(t, y_of(t)), 1, 2):.6f} kg")
print(f"mistake, signed length when reversed: {simpson(lambda t: rho(t, y_of(t)) * sqrt(1 + t * t), 2, 1):.6f} kg")
X = lambda x: 40 + 100 * x
Y = lambda x: 220 - 100 * y_of(x)
print(f"mistake, a clock that runs out and back: {twice:.6f} kg")
print("figure, 100 units per m, curve:", " ".join(f"{X(1 + i / 10):.1f},{Y(1 + i / 10):.1f}" for i in range(11)))
print("figure, chord points:", " ".join(f"{X(1 + i / 4):.1f},{Y(1 + i / 4):.1f}" for i in range(5)))
assert abs(by_x - exact) < 1e-9                  # the formula against the antiderivative
assert abs(by_u - exact) < 1e-9                  # a new clock, the same mass
assert abs(back - exact) < 1e-9                  # the other direction, the same mass
assert abs(pieces(256) - exact) < 1e-5          # the definition closes in on it
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
wire y = x^2/2 from x = 1 to 2 m; density 3x: 3.0 kg/m at the near end, 6.0 at the far end
closed form 5^1.5 - 2^1.5 = 11.180340 - 2.828427 = 8.351913 kg
clock x = t, t from 1 to 2, speed sqrt(1 + t^2): 8.351913 kg
clock x = sqrt(u), u from 1 to 4, speed sqrt(1 + u)/(2 sqrt u): 8.351913 kg
reversed, x = 3 - s, s from 1 to 2, far end first: 8.351913 kg
pieces     1: density x chord 8.112490 kg, off by -0.239422
pieces     4: density x chord 8.337034 kg, off by -0.014879
pieces    16: density x chord 8.350983 kg, off by -0.000930
pieces    64: density x chord 8.351855 kg, off by -0.000058
pieces   256: density x chord 8.351909 kg, off by -0.000004
wire length (density 1): 1.810092 m; average density 4.6141 kg/m
mistake, drop the speed (density x dx): 4.500000 kg
mistake, signed length when reversed: -8.351913 kg
mistake, a clock that runs out and back: 16.703826 kg
figure, 100 units per m, curve: 140.0,170.0 150.0,159.5 160.0,148.0 170.0,135.5 180.0,122.0 190.0,107.5 200.0,92.0 210.0,75.5 220.0,58.0 230.0,39.5 240.0,20.0
figure, chord points: 140.0,170.0 165.0,141.9 190.0,107.5 215.0,66.9 240.0,20.0
ALL CHECKS PASS
```

### Rust

```rust
// Line integral of a function -- the same check as the Python, in Rust.  No
// crates; sqrt is a primitive, and every sum below is written out here.
// A wire bent along y = x^2 / 2 from x = 1 to x = 2 m.  Its density is 3x kg/m,
// rising from 3 at the near end to 6 at the far end.  Its mass, two roads.
fn rho(x: f64, _y: f64) -> f64 { 3.0 * x } // density, kg per metre
fn y_of(x: f64) -> f64 { x * x / 2.0 } // the wire's shape
fn sign(t: f64) -> f64 { if t > 0.0 { -1.0 } else { 1.0 } } // out to the far end, then back

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { // Simpson's rule, 200 strips
    let n = 200;
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h);
    }
    s * h / 3.0
}

type F = dyn Fn(f64) -> f64;
fn line_integral(x: &F, y: &F, dx: &F, dy: &F, a: f64, b: f64) -> f64 { // density times speed
    simpson(&|t| rho(x(t), y(t)) * (dx(t).powi(2) + dy(t).powi(2)).sqrt(), a, b)
}

fn pieces(n: usize) -> f64 { // road two: the definition itself
    let xs: Vec<f64> = (0..=n).map(|i| 1.0 + i as f64 / n as f64).collect();
    xs.windows(2).map(|w| {
        let (p, q) = (w[0], w[1]);
        let chord = ((q - p).powi(2) + (y_of(q) - y_of(p)).powi(2)).sqrt();
        let m = (p + q) / 2.0;
        rho(m, y_of(m)) * chord // density at the middle, times chord
    }).sum()
}

fn main() {
    let exact = 5f64.powf(1.5) - 2f64.powf(1.5); // (1 + x^2)^(3/2) from x = 1 to 2
    let by_x = line_integral(&|t| t, &|t| t * t / 2.0, &|_| 1.0, &|t| t, 1.0, 2.0);
    let by_u = line_integral(&|u: f64| u.sqrt(), &|u| u / 2.0,
                             &|u: f64| 1.0 / (2.0 * u.sqrt()), &|_| 0.5, 1.0, 4.0);
    let back = line_integral(&|s| 3.0 - s, &|s| (3.0 - s).powi(2) / 2.0,
                             &|_| -1.0, &|s| -(3.0 - s), 1.0, 2.0);
    let twice = line_integral(&|t: f64| 2.0 - t.abs(), &|t: f64| (2.0 - t.abs()).powi(2) / 2.0,
                              &sign, &|t: f64| (2.0 - t.abs()) * sign(t), -1.0, 1.0);
    let length = simpson(&|t| (1.0 + t * t).sqrt(), 1.0, 2.0);
    println!("wire y = x^2/2 from x = 1 to 2 m; density 3x: 3.0 kg/m at the near end, 6.0 at the far end");
    println!("closed form 5^1.5 - 2^1.5 = {:.6} - {:.6} = {:.6} kg", 5f64.powf(1.5), 2f64.powf(1.5), exact);
    println!("clock x = t, t from 1 to 2, speed sqrt(1 + t^2): {:.6} kg", by_x);
    println!("clock x = sqrt(u), u from 1 to 4, speed sqrt(1 + u)/(2 sqrt u): {:.6} kg", by_u);
    println!("reversed, x = 3 - s, s from 1 to 2, far end first: {:.6} kg", back);
    for n in [1, 4, 16, 64, 256] {
        println!("pieces {:5}: density x chord {:.6} kg, off by {:+.6}", n, pieces(n), pieces(n) - exact);
    }
    println!("wire length (density 1): {:.6} m; average density {:.4} kg/m", length, exact / length);
    println!("mistake, drop the speed (density x dx): {:.6} kg", simpson(&|t| rho(t, y_of(t)), 1.0, 2.0));
    println!("mistake, signed length when reversed: {:.6} kg",
             simpson(&|t| rho(t, y_of(t)) * (1.0 + t * t).sqrt(), 2.0, 1.0));
    println!("mistake, a clock that runs out and back: {:.6} kg", twice);
    let pt = |x: f64| format!("{:.1},{:.1}", 40.0 + 100.0 * x, 220.0 - 100.0 * y_of(x));
    let curve: Vec<String> = (0..=10).map(|i| pt(1.0 + i as f64 / 10.0)).collect();
    let chords: Vec<String> = (0..=4).map(|i| pt(1.0 + i as f64 / 4.0)).collect();
    println!("figure, 100 units per m, curve: {}", curve.join(" "));
    println!("figure, chord points: {}", chords.join(" "));
    assert!((by_x - exact).abs() < 1e-9); // the formula against the antiderivative
    assert!((by_u - exact).abs() < 1e-9); // a new clock, the same mass
    assert!((back - exact).abs() < 1e-9); // the other direction, the same mass
    assert!((pieces(256) - exact).abs() < 1e-5); // the definition closes in on it
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
wire y = x^2/2 from x = 1 to 2 m; density 3x: 3.0 kg/m at the near end, 6.0 at the far end
closed form 5^1.5 - 2^1.5 = 11.180340 - 2.828427 = 8.351913 kg
clock x = t, t from 1 to 2, speed sqrt(1 + t^2): 8.351913 kg
clock x = sqrt(u), u from 1 to 4, speed sqrt(1 + u)/(2 sqrt u): 8.351913 kg
reversed, x = 3 - s, s from 1 to 2, far end first: 8.351913 kg
pieces     1: density x chord 8.112490 kg, off by -0.239422
pieces     4: density x chord 8.337034 kg, off by -0.014879
pieces    16: density x chord 8.350983 kg, off by -0.000930
pieces    64: density x chord 8.351855 kg, off by -0.000058
pieces   256: density x chord 8.351909 kg, off by -0.000004
wire length (density 1): 1.810092 m; average density 4.6141 kg/m
mistake, drop the speed (density x dx): 4.500000 kg
mistake, signed length when reversed: -8.351913 kg
mistake, a clock that runs out and back: 16.703826 kg
figure, 100 units per m, curve: 140.0,170.0 150.0,159.5 160.0,148.0 170.0,135.5 180.0,122.0 190.0,107.5 200.0,92.0 210.0,75.5 220.0,58.0 230.0,39.5 240.0,20.0
figure, chord points: 140.0,170.0 165.0,141.9 190.0,107.5 215.0,66.9 240.0,20.0
ALL CHECKS PASS
```

### Lean

Lean proves the card's main claims for every wire, clock and density meeting When it holds, and it proves the card's wire exactly.

- Take a wire with no jumps, a clock that runs it once, rates that change without jumps, and density without jumps. Cut the clock into pieces. Take density at any point of each piece times that piece's true length along the wire. As every piece shrinks, these totals close in on the integral of density times speed. The density may be negative.
- Take a new clock that runs the same wire once, from either end, with a rate that changes without jumps. As in Step 3, the old clock's reading is a function of the new one's. Density times speed, integrated over the new clock, equals the same integral over the old clock.
- Take the card's wire: y = x^2/2 from x = 1 to 2 m, density 3x, clock x = t. That integral is exactly 5^1.5 − 2^1.5 kg.
- The hand arithmetic holds exactly. That covers the end densities, the antiderivative's end values, the 4.5 kg mistake and the speeds on both new clocks.

Decimal values, the chord totals, the out-and-back and signed-length mistakes, and the figure are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 370 lines</summary>

```lean
-- Line integrals of a function: the piece totals of density times piece length along a wire close in on the integral of density times speed, that integral is the same for every clock that runs the wire once in either direction, and the card's wire y = x^2/2 with density 3x weighs exactly 5√5 − 2√2 kg.
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Normed.Group.Bounded
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp

open Set Real

lemma sli_hasDerivAt_of_mem_Ioo {f : ℝ → ℝ} {a b t : ℝ} (hf : ContDiffOn ℝ 1 f (Icc a b))
    (ht : t ∈ Ioo a b) : HasDerivAt f (derivWithin f (Icc a b) t) t := by
  have hn : Icc a b ∈ nhds t := Icc_mem_nhds ht.1 ht.2
  rw [derivWithin_of_mem_nhds hn]
  exact (((hf.differentiableOn one_ne_zero) t (Ioo_subset_Icc_self ht)).differentiableAt
    hn).hasDerivAt

#print axioms sli_hasDerivAt_of_mem_Ioo

lemma sli_integral_congr_Ioo {f g : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b) (h : EqOn f g (Ioo a b)) :
    ∫ t in a..b, f t = ∫ t in a..b, g t := by
  rw [intervalIntegral.integral_of_le hab, intervalIntegral.integral_of_le hab,
    MeasureTheory.integral_Ioc_eq_integral_Ioo, MeasureTheory.integral_Ioc_eq_integral_Ioo]
  exact MeasureTheory.setIntegral_congr_fun measurableSet_Ioo h

#print axioms sli_integral_congr_Ioo

lemma sli_mono {t : ℕ → ℝ} {n : ℕ} (h : ∀ i < n, t i < t (i + 1)) :
    ∀ i j, i ≤ j → j ≤ n → t i ≤ t j := by
  intro i j hij hjn
  induction j with
  | zero => obtain rfl : i = 0 := by omega
            exact le_rfl
  | succ j ih =>
    rcases Nat.eq_or_lt_of_le hij with h' | h'
    · rw [h']
    · exact (ih (by omega) (by omega)).trans (h j (by omega)).le

#print axioms sli_mono

lemma sli_piece {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {γ γ' : ℝ → E}
    {p q η : ℝ} (hpq : p ≤ q)
    (hγ : ∀ s ∈ Icc p q, HasDerivWithinAt γ (γ' s) (Icc p q) s)
    (hη : ∀ s ∈ Icc p q, ‖γ' s - γ' p‖ ≤ η) :
    |(eVariationOn γ (Icc p q)).toReal - (q - p) * ‖γ' p‖| ≤ η * (q - p) := by
  have hp : p ∈ Icc p q := left_mem_Icc.2 hpq
  have hq : q ∈ Icc p q := right_mem_Icc.2 hpq
  have hη0 : 0 ≤ η := by simpa using hη p hp
  set K : NNReal := ⟨‖γ' p‖ + η, by positivity⟩ with hK
  have hlip : LipschitzOnWith K γ (Icc p q) := LipschitzOnWith.of_dist_le_mul fun s hs r hr => by
    rw [dist_eq_norm, dist_eq_norm]
    refine Convex.norm_image_sub_le_of_norm_hasDerivWithin_le hγ (fun u hu => ?_) (convex_Icc p q) hr hs
    have := norm_sub_norm_le (γ' u) (γ' p)
    have := hη u hu
    show ‖γ' u‖ ≤ ‖γ' p‖ + η
    linarith
  have hup : eVariationOn γ (Icc p q) ≤ K * ENNReal.ofReal (q - p) := by
    have := hlip.comp_eVariationOn_le (g := id) (s := Icc p q) (mapsTo_id _)
    simpa using this
  have hfin : eVariationOn γ (Icc p q) ≠ ⊤ :=
    ne_top_of_le_ne_top (ENNReal.mul_ne_top ENNReal.coe_ne_top ENNReal.ofReal_ne_top) hup
  have hup' : (eVariationOn γ (Icc p q)).toReal ≤ (‖γ' p‖ + η) * (q - p) := by
    have := ENNReal.toReal_mono (ENNReal.mul_ne_top ENNReal.coe_ne_top ENNReal.ofReal_ne_top) hup
    rwa [ENNReal.toReal_mul, ENNReal.coe_toReal, ENNReal.toReal_ofReal (sub_nonneg.2 hpq)] at this
  have hlow : dist (γ p) (γ q) ≤ (eVariationOn γ (Icc p q)).toReal := by
    have h := eVariationOn.edist_le γ hp hq
    rw [edist_dist] at h
    have := ENNReal.toReal_mono hfin h
    rwa [ENNReal.toReal_ofReal dist_nonneg] at this
  have hmvt : ‖(γ q - q • γ' p) - (γ p - p • γ' p)‖ ≤ η * ‖q - p‖ :=
    Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := fun s => γ s - s • γ' p)
      (f' := fun s => γ' s - γ' p)
      (fun s hs => by
        have h := (hγ s hs).sub ((hasDerivWithinAt_id s _).smul_const (γ' p))
        simp only [one_smul] at h
        exact h)
      (fun s hs => hη s hs) (convex_Icc p q) hp hq
  have heq : (γ q - q • γ' p) - (γ p - p • γ' p) = (γ q - γ p) - (q - p) • γ' p := by
    rw [sub_smul]; abel
  rw [heq, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 hpq)] at hmvt
  have h3 : (q - p) * ‖γ' p‖ - ‖γ q - γ p‖ ≤ ‖(γ q - γ p) - (q - p) • γ' p‖ := by
    have := norm_sub_norm_le ((q - p) • γ' p) (γ q - γ p)
    rw [norm_sub_rev ((q - p) • γ' p)] at this
    rwa [norm_smul, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 hpq)] at this
  rw [dist_eq_norm, norm_sub_rev] at hlow
  rw [abs_le]; constructor <;> nlinarith

#print axioms sli_piece

lemma sli_sqrt_scale (A B p : ℝ) : √((A * p) ^ 2 + (B * p) ^ 2) = √(A ^ 2 + B ^ 2) * |p| := by
  rw [show (A * p) ^ 2 + (B * p) ^ 2 = (A ^ 2 + B ^ 2) * p ^ 2 by ring,
    Real.sqrt_mul (by positivity), Real.sqrt_sq_eq_abs]

#print axioms sli_sqrt_scale

/-- **The mass of a wire is the integral of density times speed.** A clock runs a wire once:
at clock time t, from a to b, it has reached the point (x(t), y(t)). The wire has no jumps and
the clock's rates x'(t), y'(t) change without jumps (x and y are continuously differentiable on
[a, b]); the clock runs the wire once (no point is reached twice); and the density ρ changes
without jumps along the wire. Cut the clock at a = t₀ < t₁ < … < tₙ = b, pick a clock time τᵢ
in each step [tᵢ, tᵢ₊₁], and add density at the point reached at τᵢ times the length of that
piece of wire. A piece's length is its true length along the wire: the least upper bound of
its chord totals (Mathlib's `eVariationOn`). As the pieces shrink, these totals close in on
∫ from a to b of ρ(x(t), y(t)) · √(x'(t)^2 + y'(t)^2) dt, whichever points are picked: for every
ε > 0 there is a δ > 0 such that every cut with all steps shorter than δ gives a total within
ε of that integral. The density may take either sign. -/
theorem wire_mass_eq_integral_density_mul_speed {x y : ℝ → ℝ} {ρ : ℝ × ℝ → ℝ} {a b : ℝ}
    (hab : a ≤ b)
    (hx : ContDiffOn ℝ 1 x (Icc a b)) (hy : ContDiffOn ℝ 1 y (Icc a b))
    (honce : InjOn (fun t => (x t, y t)) (Icc a b))
    (hρ : ContinuousOn ρ ((fun t => (x t, y t)) '' Icc a b)) :
    ∀ ε > 0, ∃ δ > 0, ∀ (n : ℕ) (t τ : ℕ → ℝ),
      t 0 = a → t n = b → (∀ i < n, t i < t (i + 1) ∧ t (i + 1) - t i < δ) →
      (∀ i < n, τ i ∈ Icc (t i) (t (i + 1))) →
      |∑ i ∈ Finset.range n,
          ρ (x (τ i), y (τ i)) *
            (eVariationOn (fun s => !₂[x s, y s]) (Icc (t i) (t (i + 1)))).toReal -
        ∫ s in a..b, ρ (x s, y s) * √(deriv x s ^ 2 + deriv y s ^ 2)| < ε := by
  intro ε hε
  rcases hab.eq_or_lt with hab' | hab'
  · refine ⟨1, one_pos, fun n t τ h0 hn hstep _ => ?_⟩
    have hmono := sli_mono (fun i hi => (hstep i hi).1)
    obtain rfl : n = 0 := by
      by_contra hne
      have h1 := (hstep 0 (Nat.pos_of_ne_zero hne)).1
      have h2 := hmono 1 n (by omega) le_rfl
      linarith
    simpa [hab'] using hε
  have hXc : ContinuousOn (derivWithin x (Icc a b)) (Icc a b) :=
    hx.continuousOn_derivWithin (uniqueDiffOn_Icc hab') le_rfl
  have hYc : ContinuousOn (derivWithin y (Icc a b)) (Icc a b) :=
    hy.continuousOn_derivWithin (uniqueDiffOn_Icc hab') le_rfl
  set X := derivWithin x (Icc a b) with hXdef
  set Y := derivWithin y (Icc a b) with hYdef
  set e0 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 0 1 with he0
  set e1 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 1 1 with he1
  have hγeq : (fun s => !₂[x s, y s]) = fun s => x s • e0 + y s • e1 := by
    funext s; ext i; fin_cases i <;> simp [e0, e1]
  set γ' : ℝ → EuclideanSpace ℝ (Fin 2) := fun s => X s • e0 + Y s • e1 with hγ'def
  have hγ'norm : ∀ s, ‖γ' s‖ = √(X s ^ 2 + Y s ^ 2) := by
    intro s; simp [γ', e0, e1, EuclideanSpace.norm_eq, Fin.sum_univ_two]
  have hγd : ∀ s ∈ Icc a b,
      HasDerivWithinAt (fun s => !₂[x s, y s]) (γ' s) (Icc a b) s := by
    intro s hs; rw [hγeq]
    exact (((hx.differentiableOn one_ne_zero) s hs).hasDerivWithinAt.smul_const e0).add
      (((hy.differentiableOn one_ne_zero) s hs).hasDerivWithinAt.smul_const e1)
  have hγ'c : ContinuousOn γ' (Icc a b) :=
    (hXc.smul continuousOn_const).add (hYc.smul continuousOn_const)
  set R : ℝ → ℝ := fun s => ρ (x s, y s) with hRdef
  have hRc : ContinuousOn R (Icc a b) :=
    hρ.comp (hx.continuousOn.prodMk hy.continuousOn) (mapsTo_image _ _)
  set S : ℝ → ℝ := fun s => √(X s ^ 2 + Y s ^ 2) with hSdef
  have hSc : ContinuousOn S (Icc a b) := ((hXc.pow 2).add (hYc.pow 2)).sqrt
  set F : ℝ → ℝ := fun s => R s * S s with hFdef
  have hFc : ContinuousOn F (Icc a b) := hRc.mul hSc
  have hint : ∫ s in a..b, ρ (x s, y s) * √(deriv x s ^ 2 + deriv y s ^ 2) =
      ∫ s in a..b, F s := by
    refine sli_integral_congr_Ioo hab fun s hs => ?_
    rw [(sli_hasDerivAt_of_mem_Ioo hx hs).deriv, (sli_hasDerivAt_of_mem_Ioo hy hs).deriv]
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hRc
  set M1 := |M| + 1 with hM1def
  have hM1 : 0 < M1 := by positivity
  have hRb : ∀ s ∈ Icc a b, |R s| ≤ M1 := fun s hs => by
    have := hM s hs
    rw [Real.norm_eq_abs] at this
    linarith [le_abs_self M]
  have hba : 0 < b - a := sub_pos.2 hab'
  set η := ε / (4 * M1 * (b - a)) with hηdef
  set η' := ε / (4 * (b - a)) with hη'def
  have hη : 0 < η := by positivity
  have hη' : 0 < η' := by positivity
  obtain ⟨δ1, hδ1, h1⟩ := Metric.uniformContinuousOn_iff.1
    (isCompact_Icc.uniformContinuousOn_of_continuous hγ'c) η hη
  have hHc : ContinuousOn (fun z : ℝ × ℝ => R z.1 * S z.2) (Icc a b ×ˢ Icc a b) :=
    (hRc.comp continuousOn_fst (fun (z : ℝ × ℝ) (hz : z ∈ Icc a b ×ˢ Icc a b) => hz.1)).mul
      (hSc.comp continuousOn_snd (fun (z : ℝ × ℝ) (hz : z ∈ Icc a b ×ˢ Icc a b) => hz.2))
  obtain ⟨δ2, hδ2, h2⟩ := Metric.uniformContinuousOn_iff.1
    ((isCompact_Icc.prod isCompact_Icc).uniformContinuousOn_of_continuous hHc) η' hη'
  refine ⟨min δ1 δ2, lt_min hδ1 hδ2, fun n t τ h0 hn hstep hτ => ?_⟩
  have hmono := sli_mono (fun i hi => (hstep i hi).1)
  have hmem : ∀ i ≤ n, t i ∈ Icc a b := fun i hi =>
    ⟨h0 ▸ hmono 0 i (Nat.zero_le _) hi, hn ▸ hmono i n hi le_rfl⟩
  have hpiece : ∀ i < n, |R (τ i) *
      (eVariationOn (fun s => !₂[x s, y s]) (Icc (t i) (t (i + 1)))).toReal -
        ∫ s in t i..t (i + 1), F s| ≤ (M1 * η + η') * (t (i + 1) - t i) := by
    intro i hi
    have hp := hmem i hi.le
    have hq := hmem (i + 1) hi
    have hpq : t i < t (i + 1) := (hstep i hi).1
    have hqp : t (i + 1) - t i < min δ1 δ2 := (hstep i hi).2
    have hsub : Icc (t i) (t (i + 1)) ⊆ Icc a b := Icc_subset_Icc hp.1 hq.2
    have hτi := hτ i hi
    set p := t i
    set q := t (i + 1)
    set L := (eVariationOn (fun s => !₂[x s, y s]) (Icc p q)).toReal
    have hA : |L - (q - p) * ‖γ' p‖| ≤ η * (q - p) :=
      sli_piece hpq.le (fun s hs => (hγd s (hsub hs)).mono hsub) (fun s hs => by
        have := h1 s (hsub hs) p hp (by
          rw [Real.dist_eq, abs_of_nonneg (by linarith [hs.1])]
          linarith [hs.2, min_le_left δ1 δ2])
        rw [dist_eq_norm] at this; exact this.le)
    rw [hγ'norm] at hA
    have hB : |∫ s in p..q, (R (τ i) * S p - F s)| ≤ η' * (q - p) := by
      have := intervalIntegral.norm_integral_le_of_norm_le_const (a := p) (b := q) (C := η')
        (f := fun s => R (τ i) * S p - F s) (fun s hs => ?_)
      · rwa [Real.norm_eq_abs, abs_of_pos (sub_pos.2 hpq)] at this
      · rw [uIoc_of_le hpq.le] at hs
        have hsI : s ∈ Icc a b := hsub ⟨hs.1.le, hs.2⟩
        have := h2 (τ i, p) ⟨hsub hτi, hp⟩ (s, s) ⟨hsI, hsI⟩ ?_
        · rw [Real.dist_eq] at this; exact this.le
        · rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq, max_lt_iff]
          constructor <;> rw [abs_lt] <;> constructor <;>
            linarith [hτi.1, hτi.2, hs.1, hs.2, min_le_right δ1 δ2]
    have hFi : IntervalIntegrable F MeasureTheory.volume p q :=
      (hFc.mono (by rw [uIcc_of_le hpq.le]; exact hsub)).intervalIntegrable
    have hsplit : ∫ s in p..q, (R (τ i) * S p - F s) =
        (q - p) * (R (τ i) * S p) - ∫ s in p..q, F s := by
      rw [intervalIntegral.integral_sub intervalIntegrable_const hFi,
        intervalIntegral.integral_const, smul_eq_mul]
    rw [hsplit] at hB
    have hRt : |R (τ i)| ≤ M1 := hRb _ (hsub hτi)
    have key : R (τ i) * L - ∫ s in p..q, F s = R (τ i) * (L - (q - p) * S p) +
        ((q - p) * (R (τ i) * S p) - ∫ s in p..q, F s) := by ring
    rw [key]
    calc _ ≤ |R (τ i) * (L - (q - p) * S p)| +
          |(q - p) * (R (τ i) * S p) - ∫ s in p..q, F s| := abs_add_le _ _
      _ ≤ M1 * (η * (q - p)) + η' * (q - p) := by
          gcongr
          rw [abs_mul]; exact mul_le_mul hRt hA (abs_nonneg _) hM1.le
      _ = _ := by ring
  have hsumint : ∑ i ∈ Finset.range n, ∫ s in t i..t (i + 1), F s = ∫ s in a..b, F s := by
    rw [intervalIntegral.sum_integral_adjacent_intervals, h0, hn]
    intro k hk
    exact (hFc.mono (by
      rw [uIcc_of_le (hstep k hk).1.le]
      exact Icc_subset_Icc (hmem k hk.le).1 (hmem (k + 1) hk).2)).intervalIntegrable
  rw [hint, ← hsumint, ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans_lt ?_
  calc _ ≤ ∑ i ∈ Finset.range n, (M1 * η + η') * (t (i + 1) - t i) :=
        Finset.sum_le_sum fun i hi => hpiece i (Finset.mem_range.1 hi)
    _ = (M1 * η + η') * (b - a) := by
        rw [← Finset.mul_sum, Finset.sum_range_sub (fun i => t i), h0, hn]
    _ < ε := by
        have e1 : M1 * η * (b - a) = ε / 4 := by
          rw [hηdef]; field_simp
        have e2 : η' * (b - a) = ε / 4 := by
          rw [hη'def]; field_simp
        nlinarith

/-- **Any clock that runs the wire once, in either direction, gives the same mass.** Keep the
wire, clock and density of the main theorem. A new clock u runs from c to d, and the old clock
reads φ(u) when the new one reads u, so the new clock reaches the point (x(φ(u)), y(φ(u))).
Its rate φ' changes without jumps (φ is continuously differentiable on [c, d]), and it runs the
wire once: either φ rises strictly from a to b (same direction), or it falls strictly from b to
a (the far end first). Then density times the new clock's speed, integrated over the new clock,
equals density times the old clock's speed, integrated over the old clock. -/
theorem integral_density_mul_speed_indep_of_clock {x y φ : ℝ → ℝ} {ρ : ℝ × ℝ → ℝ}
    {a b c d : ℝ} (hab : a ≤ b) (hcd : c ≤ d)
    (hx : ContDiffOn ℝ 1 x (Icc a b)) (hy : ContDiffOn ℝ 1 y (Icc a b))
    (honce : InjOn (fun t => (x t, y t)) (Icc a b))
    (hρ : ContinuousOn ρ ((fun t => (x t, y t)) '' Icc a b))
    (hφ : ContDiffOn ℝ 1 φ (Icc c d))
    (hrun : (StrictMonoOn φ (Icc c d) ∧ φ c = a ∧ φ d = b) ∨
      (StrictAntiOn φ (Icc c d) ∧ φ c = b ∧ φ d = a)) :
    ∫ u in c..d, ρ (x (φ u), y (φ u)) * √(deriv (x ∘ φ) u ^ 2 + deriv (y ∘ φ) u ^ 2) =
      ∫ t in a..b, ρ (x t, y t) * √(deriv x t ^ 2 + deriv y t ^ 2) := by
  set X := derivWithin x (Icc a b)
  set Y := derivWithin y (Icc a b)
  set P := derivWithin φ (Icc c d)
  set G : ℝ → ℝ := fun t => ρ (x t, y t) * √(X t ^ 2 + Y t ^ 2) with hGdef
  have hR : ∫ t in a..b, ρ (x t, y t) * √(deriv x t ^ 2 + deriv y t ^ 2) = ∫ t in a..b, G t := by
    refine sli_integral_congr_Ioo hab fun t ht => ?_
    rw [(sli_hasDerivAt_of_mem_Ioo hx ht).deriv, (sli_hasDerivAt_of_mem_Ioo hy ht).deriv]
  rw [hR]
  have hP : ∀ u ∈ Ioo (min c d) (max c d), HasDerivAt φ (P u) u := by
    rw [min_eq_left hcd, max_eq_right hcd]
    exact fun u hu => sli_hasDerivAt_of_mem_Ioo hφ hu
  have hφc : ContinuousOn φ (uIcc c d) := by
    rw [uIcc_of_le hcd]; exact hφ.continuousOn
  have hin : (∀ u ∈ Ioo c d, φ u ∈ Ioo a b) := by
    intro u hu
    have huI : u ∈ Icc c d := Ioo_subset_Icc_self hu
    rcases hrun with ⟨hm, h1, h2⟩ | ⟨hm, h1, h2⟩
    · exact ⟨h1 ▸ hm (left_mem_Icc.2 hcd) huI hu.1, h2 ▸ hm huI (right_mem_Icc.2 hcd) hu.2⟩
    · exact ⟨h2 ▸ hm huI (right_mem_Icc.2 hcd) hu.2, h1 ▸ hm (left_mem_Icc.2 hcd) huI hu.1⟩
  have hL : ∀ u ∈ Ioo c d, ρ (x (φ u), y (φ u)) * √(deriv (x ∘ φ) u ^ 2 + deriv (y ∘ φ) u ^ 2)
      = G (φ u) * |P u| := by
    intro u hu
    have hPu := sli_hasDerivAt_of_mem_Ioo hφ hu
    rw [((sli_hasDerivAt_of_mem_Ioo hx (hin u hu)).comp u hPu).deriv,
      ((sli_hasDerivAt_of_mem_Ioo hy (hin u hu)).comp u hPu).deriv, sli_sqrt_scale]
    simp only [G]; ring
  rcases hrun with ⟨hm, h1, h2⟩ | ⟨hm, h1, h2⟩
  · have hnn : ∀ u, 0 ≤ P u := fun u => hm.monotoneOn.derivWithin_nonneg
    rw [sli_integral_congr_Ioo hcd (g := fun u => (G ∘ φ) u * P u) (fun u hu => by
      rw [hL u hu, abs_of_nonneg (hnn u)]; rfl)]
    rw [intervalIntegral.integral_comp_mul_deriv_of_deriv_nonneg hφc hP (fun u _ => hnn u), h1, h2]
  · have hnp : ∀ u, P u ≤ 0 := fun u => hm.antitoneOn.derivWithin_nonpos
    rw [sli_integral_congr_Ioo hcd (g := fun u => -((G ∘ φ) u * P u)) (fun u hu => by
      rw [hL u hu, abs_of_nonpos (hnp u)]; simp only [Function.comp]; ring)]
    rw [intervalIntegral.integral_neg,
      intervalIntegral.integral_comp_mul_deriv_of_deriv_nonpos hφc hP (fun u _ => hnp u), h1, h2,
      intervalIntegral.integral_symm, neg_neg]

/-- **The card's wire.** The wire follows y = x^2/2 from x = 1 to x = 2 m, run by the clock
x = t, y = t^2/2 for t from 1 to 2. Its density at the point (x, y) is 3x kg/m. Density times
speed, integrated over the clock, is exactly 5^(3/2) − 2^(3/2) = 5√5 − 2√2 kg, about
8.351913 kg. -/
theorem card_wire_mass :
    ∫ t in (1 : ℝ)..2, (fun p : ℝ × ℝ => 3 * p.1) (t, t ^ 2 / 2) *
        √(deriv (fun s : ℝ => s) t ^ 2 + deriv (fun s : ℝ => s ^ 2 / 2) t ^ 2) =
      5 * √5 - 2 * √2 := by
  have hd : ∀ t : ℝ, deriv (fun s : ℝ => s ^ 2 / 2) t = t := by
    intro t
    have : HasDerivAt (fun s : ℝ => s ^ 2 / 2) ((2 * t ^ 1) / 2) t :=
      (hasDerivAt_pow 2 t).div_const 2
    rw [this.deriv]; ring
  simp only [deriv_id'', hd, one_pow]
  have hF : ∀ t : ℝ, HasDerivAt (fun s : ℝ => (1 + s ^ 2) * √(1 + s ^ 2))
      (3 * t * √(1 + t ^ 2)) t := by
    intro t
    have h1 : HasDerivAt (fun s : ℝ => 1 + s ^ 2) (2 * t) t := by
      simpa using ((hasDerivAt_pow 2 t).const_add 1)
    have hpos : (0 : ℝ) < 1 + t ^ 2 := by positivity
    have h2 := h1.mul (h1.sqrt hpos.ne')
    convert h2 using 1
    have hs : 0 < √(1 + t ^ 2) := Real.sqrt_pos.2 hpos
    field_simp
    rw [Real.sq_sqrt hpos.le]; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hF t)
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num

-- Density 3x at the two ends of the wire: 3 kg/m at x = 1, 6 kg/m at x = 2.
example : (3 : ℚ) * 1 = 3 ∧ (3 : ℚ) * 2 = 6 := by norm_num
-- The ends of the wire: y = 1^2/2 = 1/2 m at x = 1 and y = 2^2/2 = 2 m at x = 2.
example : (1 : ℚ) ^ 2 / 2 = 1 / 2 ∧ (2 : ℚ) ^ 2 / 2 = 2 := by norm_num
-- The antiderivative (1 + t^2)^(3/2) at the ends: 1 + 2^2 = 5 and 1 + 1^2 = 2, so the mass
-- is 5^(3/2) − 2^(3/2), and 5^3 = 125, 2^3 = 8 are the squares of 5√5 and 2√2.
example : (1 : ℚ) + 2 ^ 2 = 5 ∧ (1 : ℚ) + 1 ^ 2 = 2 ∧ (5 : ℚ) ^ 2 * 5 = 5 ^ 3 ∧ (2 : ℚ) ^ 2 * 2 = 2 ^ 3 := by
  norm_num
-- The chain rule check on the antiderivative: (3/2) · 2t = 3t.
example : ∀ t : ℚ, 3 / 2 * (2 * t) = 3 * t := by intro t; ring
-- Mistake, drop the speed: ∫ from 1 to 2 of 3x dx = 3 · (2^2 − 1^2)/2 = 4.5 kg.
example : (3 : ℚ) * (2 ^ 2 - 1 ^ 2) / 2 = 9 / 2 := by norm_num
-- The average of the end densities, (3 + 6)/2 = 4.5 kg/m.
example : ((3 : ℚ) + 6) / 2 = 9 / 2 := by norm_num
-- The clock x = √u runs u from 1 to 4: √1 = 1 and √4 = 2, the two ends of the wire.
example : (1 : ℚ) ^ 2 = 1 ∧ (2 : ℚ) ^ 2 = 4 := by norm_num
-- On that clock y = u/2, so the rates are 1/(2√u) and 1/2, and the speed squared is
-- 1/(4u) + 1/4 = (1 + u)/(4u).
example : ∀ u : ℚ, u ≠ 0 → 1 / (4 * u) + 1 / 4 = (1 + u) / (4 * u) := by
  intro u hu; field_simp
-- The reversed clock x = 3 − s, s from 1 to 2, starts at the far end x = 2 and ends at x = 1;
-- its rate is −1, and (−1)^2 = 1, so its speed is the same as before.
example : (3 : ℚ) - 1 = 2 ∧ (3 : ℚ) - 2 = 1 ∧ (-1 : ℚ) ^ 2 = 1 := by norm_num

#print axioms wire_mass_eq_integral_density_mul_speed
#print axioms integral_density_mul_speed_indep_of_clock
#print axioms card_wire_mass
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'sli_hasDerivAt_of_mem_Ioo' depends on axioms: [propext, Classical.choice, Quot.sound]
'sli_integral_congr_Ioo' depends on axioms: [propext, Classical.choice, Quot.sound]
'sli_mono' depends on axioms: [propext, Classical.choice, Quot.sound]
'sli_piece' depends on axioms: [propext, Classical.choice, Quot.sound]
'sli_sqrt_scale' depends on axioms: [propext, Classical.choice, Quot.sound]
'wire_mass_eq_integral_density_mul_speed' depends on axioms: [propext, Classical.choice, Quot.sound]
'integral_density_mul_speed_indep_of_clock' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_wire_mass' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Density 3 everywhere.** Guess first: more or less than 8.351913 kg? Set `rho` to return 3. The mass becomes 3 times the wire's length of 1.810092 m, and the asserts fail, since the antiderivative belongs to density 3x.
> - **A clock twice as fast.** Guess first. Use x = 2w for w from 1/2 to 1, with rates 2 and 4w. Speed doubles, clock time halves, and the mass stays 8.351913 kg.
> - **More pieces.** Guess first: 1024 pieces, how far off? About sixteen times closer than 256 pieces: under a millionth of a kilogram.
> - **Break the rule.** Replace the speed by the signed rate of x times sqrt(1 + x^2). The reversed clock then gives −8.351913 kg and the third assert fails.

---

## The usual mistake

> [!warning]
> **Treating ds as dx.** Adding density over the ground the wire covers, 1 m of x, gives 4.500000 kg. The wire is 1.810092 m long; the speed factor is what converts ground into wire.
>
> - **Giving ds a sign.** Integrating from the far end with a signed length gives −8.351913 kg. A wire has no negative mass whichever end is weighed first.
> - **A clock that doubles back.** Out and back gives 16.703826 kg: the formula counts every pass.

---

## Where you meet it in real life

- **Cables and pipes.** A cable whose gauge changes along a route, or a pipe coated more heavily on a bend, is weighed this way before it is lifted.
- **Averages along a route.** Dividing by length gives a length-weighted average: 4.6141 kg/m here. Average pollution along a road is the same integral with pollution in place of density.
- **Surfaces.** The same pieces-times-size idea over a patch of surface gives [Surface integrals](05-surface-integrals-and-flux.md).

> **Say it back**
> The mass of a wire is the limit of density times piece length as the pieces shrink. With a clock along the wire, each length is speed times clock time, so the mass is the integral of density times speed. Any clock that runs the wire once gives the same answer, and running backwards cannot flip it, because speed is never negative. The bent wire with density 3x from x = 1 to 2 m weighs 8.351913 kg.

---

## What this builds on

- [Arc length](../05-Curves%20and%20Solids/02-arc-length.md): length as the integral of speed; this card weights each length by a density.
- [Substitution](../04-Integrals/03-substitution.md): why a new clock, or a reversed one, leaves the integral unchanged.

## Where this goes next

- [Line integrals of a field](02-line-integrals.md): adds a force's push along the direction of travel, and there direction matters.

Density has no direction, so the wire weighs the same from either end; what changes when the thing added along the wire points one way, as a force does, is [Line integrals of a field](02-line-integrals.md).

---

## Sources

Verified 2026-09-27: every link below resolves to the publisher's page.

- Strang, Gilbert, Edwin Herman et al. *Calculus Volume 3*, OpenStax. [Section 6.2, Line Integrals](https://openstax.org/books/calculus-volume-3/pages/6-2-line-integrals). Scalar line integrals as limits of pieces, the speed formula, and wire mass.
- Auroux, Denis, Arthur Mattuck and Jeremy Orloff. *18.02SC Multivariable Calculus*, MIT OpenCourseWare, Fall 2010. [Course page](https://ocw.mit.edu/courses/18-02sc-multivariable-calculus-fall-2010/). Line integrals and their independence of parametrisation, with worked sessions.
