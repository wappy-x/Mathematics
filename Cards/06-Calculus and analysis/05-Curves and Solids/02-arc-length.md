# Arc length: the length of a curve as the integral of speed

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Curves and Solids](../README.md#s05) → Arc length

---

## General Overview

A suspension bridge hangs its deck from main cables. Take one cable between towers 400 m apart, dipping 40 m at midspan; that dip is the **sag**. The deck's weight, spread evenly along the road, pulls the cable into a parabola. Before any wire is spun, the builders need its length.

A ruler measures straight lines, not curves. So join points on the cable by straight pieces, called **chords**, and add them. One chord, tower to tower, gives 400 m. Four give 409.80 m. Sixty-four give 410.42 m. The totals climb towards one number: the cable's length, 410.424 m.

Calculus reaches it without chords. Each tiny piece of cable is almost straight, so its length is its width stretched by a factor set by the slope there. An integral adds the stretched widths.

<p align="center"><img src="../figures/arc-length.svg" alt="A suspension cable of span 400 m and sag 40 m drawn to scale: the parabola, a four-chord polygon under it, the straight line between the tower tops, and the sag marked at midspan" width="420"></p>

Drawn to scale at 0.8 units per metre; chord points every 100 m. The deck line marks the span only, not its height.

**The length of a curve is the limit of the lengths of ever finer chord chains, and for a smooth curve that limit is the integral of $\sqrt{1 + f'(x)^2}$, or, for a moving point, the integral of its speed.**

**What kind of fact this is:** a theorem. Length is defined by chords; that it equals the integral is proved on this card in Why it works.

---

## The formula

A reminder: $f'(x)$ is the derivative, "the rate of height per unit of x", here the cable's slope.

For a graph, height $f(x)$ over the stretch from $a$ to $b$:

$$L = \int_a^b \sqrt{1 + f'(x)^2}\, dx$$

**Read it aloud:** the length adds each tiny width, stretched by the square root of one plus the slope squared.

For a point moving along a curve, its position at clock time $t$ is $(x(t), y(t))$, as on [Parametric motion](01-parametric-motion.md). Its speed is $\sqrt{x'(t)^2 + y'(t)^2}$, and

$$L = \int_{t_0}^{t_1} \sqrt{x'(t)^2 + y'(t)^2}\, dt$$

**Read it aloud:** the length is the integral of speed over the time the trip takes.

The graph formula is the second one with the clock set to $x$ itself: then $x'(t) = 1$ and $y'(t) = f'(x)$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$ | horizontal position, metres from midspan | −200 to 200 | a wider stretch is longer |
| $f(x)$ | cable height above its lowest point, metres | x^2/1000, so 40 at a tower | a deeper sag lengthens the cable |
| $f'(x)$ | slope: metres of rise per metre across | x/500, so 0.4 at a tower | steeper stretches count for more |
| $a$, $b$ | the two ends of the stretch | −200 and 200 m | — |
| $L$ | the length along the curve, metres | 410.424 m | — |
| $t$, $t_0$, $t_1$ | a clock for the moving point, its start and end | −1 to 1 | a faster clock changes speed, not length |
| $x(t)$, $y(t)$ | position at time t; primes are their rates | 200t and 40t^2 | — |
| $n$, $\Delta x$ | number of chords, and the width of each | 4 chords, 100 m wide | more chords, closer total |

The slope is metres per metre, so the square root is a pure stretch factor and the length is in metres.

### When it holds

- **The curve has no jumps and its slope changes without jumps.** A corner is fine: split the curve there and add the pieces. A 40 m step at midspan has slope 0 on both sides, so the formula says 400.00 m, while 1024 chords give 439.61 m.
- **The stretch is finite.** A curve running off forever may have no length.
- **No endless crinkling.** A continuous curve can wiggle at every scale so its chord totals grow without limit; smoothness rules that out.
- **A moving point counts each pass.** Out and back along the cable is twice the length.

---

## Why it works

### Step 0: chords undershoot, and refining can only help

A straight line is the shortest route, so no chord is longer than the curve it cuts across. Split a chord at a point on the curve and the three chords form a triangle, whose two sides together are at least the third. Adding points never shortens the total. The cable's totals, 400.00, 407.92, 409.80 m, only climb.

So the **length** of a curve is defined as the least upper bound (written sup: the smallest number no chord total exceeds) of all its chord totals.

### Step 1: one chord is a width times a stretch factor

Cut the stretch from a to b into $n$ strips of width $\Delta x$. Over one strip the height changes by an amount called the rise. By Pythagoras the chord is

$$\sqrt{\Delta x^2 + \text{rise}^2} = \Delta x \sqrt{1 + (\text{rise}/\Delta x)^2}$$

Rise over width is the chord's slope. The **mean value theorem** (on a smooth stretch, some point inside has slope equal to the chord's: [Mean value theorem](../03-What%20Derivatives%20Tell%20You/02-mean-value-theorem.md)) puts a point in the strip where $f'(x)$ is exactly that ratio. So each chord is its width times $\sqrt{1 + f'(x)^2}$ at some point of its own strip.

### Step 2: the chord total is a Riemann sum

Add the chords: widths times values of the stretch factor, one value from each strip. That is a Riemann sum ([The integral](../04-Integrals/01-riemann-integral.md)). The stretch factor is continuous because the slope is, so these sums close in on its integral as the strips narrow, wherever in each strip the value is taken.

### Step 3: closing in from below means the least upper bound

Chord totals climb (Step 0) and close in on the integral (Step 2); a climbing list that closes in on a number never passes it. So the integral bounds every chord total, and nothing smaller does: it is the least upper bound, the length.

The tolerance game: to land within 0.01 m, 32 equal chords suffice, short by 0.0097 m. Halving the chord width cuts the shortfall to about a quarter: 0.6206 m at 4 chords, 0.1548 m at 8, 0.0387 m at 16.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Cable length from equal chords"
    x-axis "number of chords" ["1", "2", "4", "8", "16", "32", "64"]
    y-axis "length (m)" 398 --> 412
    line [400.00, 407.92, 409.80, 410.27, 410.39, 410.41, 410.42]
    line [410.424, 410.424, 410.424, 410.424, 410.424, 410.424, 410.424]
```

Orange: the chord total. Green: the integral, 410.424 m. Orange climbs to green and never crosses it.

### Step 4: a moving point, and why the graph is a special case

For a moving point, cut the clock into short steps. In one step the point moves about $x'(t)$ times the step across and $y'(t)$ times it up, so each chord is about speed times step. One catch: the mean value theorem, applied to each coordinate, may pick two different instants in a step; because the rates have no jumps, the mismatch vanishes as steps shrink.

The cable as a moving point, $x(t) = 200t$ and $y(t) = 40t^2$ for t from −1 to 1, traces the same parabola; its speed integral gives 410.424252 m. A new clock changes speed, not length.

<details>
<summary>Detailed proof: chord totals close in on the speed integral</summary>

Let $x(t)$ and $y(t)$ have continuous rates from $t_0$ to $t_1$, and let L be the speed integral. Cut the clock at $t_0 < s_1 < \dots < s_n = t_1$, widest step h.

On each step, the mean value theorem gives instants c_i and d_i in that step with $\Delta x_i = x'(c_i)\,\Delta s_i$ and $\Delta y_i = y'(d_i)\,\Delta s_i$. So that step's chord has length $\sqrt{x'(c_i)^2 + y'(d_i)^2}\,\Delta s_i$.

A rate continuous on a closed interval is uniformly continuous: for every ε > 0 there is a δ > 0 such that instants less than δ apart have rates less than ε apart. Take h < δ. The reverse triangle inequality in the plane (the lengths of two arrows differ by at most the length of their difference) gives
$$\left|\sqrt{x'(c_i)^2 + y'(d_i)^2} - \sqrt{x'(c_i)^2 + y'(c_i)^2}\right| \le |y'(d_i) - y'(c_i)| < \varepsilon.$$
So the chord total is within ε times the clock's length of the Riemann sum $\sum \sqrt{x'(c_i)^2 + y'(c_i)^2}\,\Delta s_i$, which is within ε of L once h is small, since speed is continuous. The chord totals tend to L.

Refining never shortens a total, and any cutting refines to fine ones, so every total is at most L while fine ones come within any ε of it: L is the least upper bound.

</details>

### Step 5: the cable's integral in closed form

For the cable, $f'(x) = x/500$. The hyperbolic sine and cosine are $\sinh w = (e^w - e^{-w})/2$ and $\cosh w = (e^w + e^{-w})/2$, for any number $w$ ([Hyperbolic functions](../02-Derivatives/07-hyperbolic-functions.md)). Substituting $x = 500 \sinh w$ turns $\sqrt{1 + (x/500)^2}$ into a cosh, since $\cosh^2 w - \sinh^2 w = 1$. The result is

$$L = 500\left(0.4\sqrt{1.16} + \operatorname{asinh} 0.4\right)$$

where asinh is the inverse of sinh, and $\operatorname{asinh} u = \ln\left(u + \sqrt{1 + u^2}\right)$.

<details>
<summary>The algebra behind this</summary>

With $x = 500 \sinh w$, the width element is $500 \cosh w$ times the step in w, and the integrand becomes $500 \cosh^2 w$. Since $\cosh^2 w = (1 + \cosh 2w)/2$, an antiderivative is $250\,(w + \sinh w \cosh w)$. The ends are $\sinh w = \pm 0.4$, where $\cosh w = \sqrt{1.16}$; both ends contribute equally.

</details>

Most curves have no such closed form, so engineers integrate numerically, as the code does.

---

## Worked numbers, by hand

The cable: span 400 m, sag 40 m, height $f(x) = x^2/1000$ from −200 to 200 m.

| Step | Arithmetic | Value |
| --- | --- | --- |
| slope | derivative of x^2/1000 | x/500 |
| slope at a tower | 200/500 | 0.4 |
| stretch factor at a tower | sqrt(1 + 0.16) | 1.077033 |
| first term | 0.4 × 1.077033 | 0.430813 |
| second term | asinh 0.4 = ln(0.4 + 1.077033) = ln(1.477033) | 0.390035 |
| sum | 0.430813 + 0.390035 | 0.820849 |
| length | 500 × 0.820849 | **410.424 m** |

(The sum's last digit uses unrounded terms.) A 40 m sag costs 10.4243 m of wire beyond the span. The shallow-sag rule of thumb, span plus 8 × sag^2 / (3 × span), gives 410.667 m.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Measure tower to tower | 400.00 m | One chord; the sag is ignored |
| Integrate the slope's size, forgetting the 1 | 80.000 m | Only vertical travel, 40 m down and 40 m up |
| Drop the square root | 421.333 m | Squares added, not Pythagoras: the extra wire roughly doubles |
| Formula across a 40 m step | 400.00 m, not 439.61 m | Jump dropped: no slope sees the step |

The code prints each one.

---

## Code, from first principles, and it actually runs

Three roads. One: chord totals, the definition, with the shortfall printed. Two: Simpson's rule (a strip sum fitting a parabola over each pair of strips: [Numerical integration](../04-Integrals/08-numerical-integration.md)) on the stretch factor and on the moving point's speed. Three: Step 5's closed form. The asserts compare roads and check that chord totals climb and stay below.

### Python

```python
# Arc length -- the check behind the card.  Standard library only; math gives
# sqrt and log as primitives, and every sum below is written out here.
# A suspension cable hangs as the parabola y = x^2 / 1000 between towers at
# x = -200 and x = 200 m: span 400 m, sag 40 m.  Its length, three roads.
from math import sqrt, log

S, D = 400.0, 40.0                 # span and sag, metres
A, B = -S / 2, S / 2               # the towers
def f(x):  return 4 * D * x * x / (S * S)          # height above the low point
def fp(x): return 8 * D * x / (S * S)              # slope, metres per metre

def step(x): return D if x >= 0 else 0.0            # a 40 m jump at midspan

def polygon(n, g=f):               # road one: n straight chords, tower to tower
    xs = [A + (B - A) * i / n for i in range(n + 1)]
    return sum(sqrt((xs[i] - xs[i - 1]) ** 2 + (g(xs[i]) - g(xs[i - 1])) ** 2)
               for i in range(1, n + 1))

def simpson(g, a, b, n):           # road two: Simpson's rule, n even strips
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

k = 8 * D / (S * S)                # slope per metre of x: 1/500
u = k * B                          # slope at the tower: 0.4
exact = (u * sqrt(1 + u * u) + log(u + sqrt(1 + u * u))) / k   # road three
graph = simpson(lambda x: sqrt(1 + fp(x) ** 2), A, B, 100)
param = simpson(lambda t: sqrt((S / 2) ** 2 + (2 * D * t) ** 2), -1.0, 1.0, 100)

r = sqrt(1 + u * u)
print(f"span {S:.0f} m, sag {D:.0f} m, cable y = x^2/1000, slope x/500, at the tower {u:.1f}")
print(f"sqrt(1.16) = {r:.6f}; 0.4 x it = {u * r:.6f}; asinh 0.4 = ln({u + r:.6f}) = "
      f"{log(u + r):.6f}; sum {u * r + log(u + r):.6f}")
print(f"closed form, 500 x (0.4 x sqrt(1.16) + asinh 0.4): {exact:.6f} m")
print(f"Simpson on sqrt(1 + f'(x)^2), 100 strips: {graph:.6f} m")
print(f"Simpson on the speed of x = 200t, y = 40t^2, 100 strips: {param:.6f} m")
lengths = []
for n in (1, 2, 4, 8, 16, 32, 64):
    lengths.append(polygon(n))
    print(f"chords {n:4d}: polygon {lengths[-1]:.2f} m, short by {exact - lengths[-1]:.4f} m")
print(f"mistake 1, integrate |slope| only: {simpson(lambda x: abs(fp(x)), A, B, 100):.3f} m")
print(f"mistake 2, drop the square root: {simpson(lambda x: 1 + fp(x) ** 2, A, B, 100):.3f} m")
print(f"no jumps dropped, a {D:.0f} m step at midspan: formula (slope 0) {S:.2f} m, "
      f"1024 chords {polygon(1024, step):.2f} m")
print(f"rule of thumb s + 8d^2/(3s): {S + 8 * D * D / (3 * S):.3f} m")
X = lambda x: 180 + 0.8 * x
Y = lambda x: 150 - 0.8 * f(x)
print("figure, 0.8 units per m, chord points:",
      " ".join(f"({X(x):.1f},{Y(x):.1f})" for x in (-200, -100, 0, 100, 200)))
assert abs(graph - exact) < 1e-7                  # road two against road three
assert abs(param - exact) < 1e-7                  # a new clock, the same length
assert all(p < q for p, q in zip(lengths, lengths[1:] + [exact]))   # chords climb, stay under
assert 0 < exact - polygon(1024) < 1e-4           # road one closes the gap, from below
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
span 400 m, sag 40 m, cable y = x^2/1000, slope x/500, at the tower 0.4
sqrt(1.16) = 1.077033; 0.4 x it = 0.430813; asinh 0.4 = ln(1.477033) = 0.390035; sum 0.820849
closed form, 500 x (0.4 x sqrt(1.16) + asinh 0.4): 410.424252 m
Simpson on sqrt(1 + f'(x)^2), 100 strips: 410.424252 m
Simpson on the speed of x = 200t, y = 40t^2, 100 strips: 410.424252 m
chords    1: polygon 400.00 m, short by 10.4243 m
chords    2: polygon 407.92 m, short by 2.5027 m
chords    4: polygon 409.80 m, short by 0.6206 m
chords    8: polygon 410.27 m, short by 0.1548 m
chords   16: polygon 410.39 m, short by 0.0387 m
chords   32: polygon 410.41 m, short by 0.0097 m
chords   64: polygon 410.42 m, short by 0.0024 m
mistake 1, integrate |slope| only: 80.000 m
mistake 2, drop the square root: 421.333 m
no jumps dropped, a 40 m step at midspan: formula (slope 0) 400.00 m, 1024 chords 439.61 m
rule of thumb s + 8d^2/(3s): 410.667 m
figure, 0.8 units per m, chord points: (20.0,118.0) (100.0,142.0) (180.0,150.0) (260.0,142.0) (340.0,118.0)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Arc length -- the same check as the Python, in Rust.  No crates; sqrt and
// ln are primitives, and every sum below is written out here.
// A suspension cable hangs as the parabola y = x^2 / 1000 between towers at
// x = -200 and x = 200 m: span 400 m, sag 40 m.  Its length, three roads.
const S: f64 = 400.0; // span, metres
const D: f64 = 40.0; // sag, metres
const A: f64 = -S / 2.0;
const B: f64 = S / 2.0;

fn f(x: f64) -> f64 { 4.0 * D * x * x / (S * S) } // height above the low point
fn fp(x: f64) -> f64 { 8.0 * D * x / (S * S) } // slope, metres per metre

fn step(x: f64) -> f64 { if x >= 0.0 { D } else { 0.0 } } // a 40 m jump at midspan

fn polygon(n: usize, g: &dyn Fn(f64) -> f64) -> f64 { // road one: n straight chords
    let xs: Vec<f64> = (0..=n).map(|i| A + (B - A) * i as f64 / n as f64).collect();
    (1..=n).map(|i| ((xs[i] - xs[i - 1]).powi(2) + (g(xs[i]) - g(xs[i - 1])).powi(2)).sqrt()).sum()
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // road two
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h);
    }
    s * h / 3.0
}

fn main() {
    let k = 8.0 * D / (S * S); // slope per metre of x: 1/500
    let u = k * B; // slope at the tower: 0.4
    let exact = (u * (1.0 + u * u).sqrt() + (u + (1.0 + u * u).sqrt()).ln()) / k; // road three
    let graph = simpson(&|x| (1.0 + fp(x).powi(2)).sqrt(), A, B, 100);
    let param = simpson(&|t| ((S / 2.0).powi(2) + (2.0 * D * t).powi(2)).sqrt(), -1.0, 1.0, 100);

    let r = (1.0 + u * u).sqrt();
    println!("span {:.0} m, sag {:.0} m, cable y = x^2/1000, slope x/500, at the tower {:.1}", S, D, u);
    println!("sqrt(1.16) = {:.6}; 0.4 x it = {:.6}; asinh 0.4 = ln({:.6}) = {:.6}; sum {:.6}",
             r, u * r, u + r, (u + r).ln(), u * r + (u + r).ln());
    println!("closed form, 500 x (0.4 x sqrt(1.16) + asinh 0.4): {:.6} m", exact);
    println!("Simpson on sqrt(1 + f'(x)^2), 100 strips: {:.6} m", graph);
    println!("Simpson on the speed of x = 200t, y = 40t^2, 100 strips: {:.6} m", param);
    let mut lengths: Vec<f64> = Vec::new();
    for n in [1, 2, 4, 8, 16, 32, 64] {
        lengths.push(polygon(n, &f));
        let p = lengths[lengths.len() - 1];
        println!("chords {:4}: polygon {:.2} m, short by {:.4} m", n, p, exact - p);
    }
    println!("mistake 1, integrate |slope| only: {:.3} m", simpson(&|x| fp(x).abs(), A, B, 100));
    println!("mistake 2, drop the square root: {:.3} m", simpson(&|x| 1.0 + fp(x).powi(2), A, B, 100));
    println!("no jumps dropped, a {:.0} m step at midspan: formula (slope 0) {:.2} m, 1024 chords {:.2} m",
             D, S, polygon(1024, &step));
    println!("rule of thumb s + 8d^2/(3s): {:.3} m", S + 8.0 * D * D / (3.0 * S));
    let pts: Vec<String> = [-200.0, -100.0, 0.0, 100.0, 200.0].iter()
        .map(|&x: &f64| format!("({:.1},{:.1})", 180.0 + 0.8 * x, 150.0 - 0.8 * f(x))).collect();
    println!("figure, 0.8 units per m, chord points: {}", pts.join(" "));
    assert!((graph - exact).abs() < 1e-7); // road two against road three
    assert!((param - exact).abs() < 1e-7); // a new clock, the same length
    let mut climb = lengths.clone();
    climb.push(exact);
    assert!(climb.windows(2).all(|w| w[0] < w[1])); // chords climb, stay under
    let gap = exact - polygon(1024, &f);
    assert!(gap > 0.0 && gap < 1e-4); // road one closes the gap, from below
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
span 400 m, sag 40 m, cable y = x^2/1000, slope x/500, at the tower 0.4
sqrt(1.16) = 1.077033; 0.4 x it = 0.430813; asinh 0.4 = ln(1.477033) = 0.390035; sum 0.820849
closed form, 500 x (0.4 x sqrt(1.16) + asinh 0.4): 410.424252 m
Simpson on sqrt(1 + f'(x)^2), 100 strips: 410.424252 m
Simpson on the speed of x = 200t, y = 40t^2, 100 strips: 410.424252 m
chords    1: polygon 400.00 m, short by 10.4243 m
chords    2: polygon 407.92 m, short by 2.5027 m
chords    4: polygon 409.80 m, short by 0.6206 m
chords    8: polygon 410.27 m, short by 0.1548 m
chords   16: polygon 410.39 m, short by 0.0387 m
chords   32: polygon 410.41 m, short by 0.0097 m
chords   64: polygon 410.42 m, short by 0.0024 m
mistake 1, integrate |slope| only: 80.000 m
mistake 2, drop the square root: 421.333 m
no jumps dropped, a 40 m step at midspan: formula (slope 0) 400.00 m, 1024 chords 439.61 m
rule of thumb s + 8d^2/(3s): 410.667 m
figure, 0.8 units per m, chord points: (20.0,118.0) (100.0,142.0) (180.0,150.0) (260.0,142.0) (340.0,118.0)
ALL CHECKS PASS
```

The outputs match line for line.

### Lean

Lean proves both length formulas for every curve whose slope has no jumps, and the cable's exact length.

- For a moving point whose rates have no jumps, the least upper bound of its chord totals equals the integral of its speed. Each pass counts.
- For a graph whose height and slope have no jumps, the length is the integral of $\sqrt{1 + f'(x)^2}$.
- The cable, height x^2/1000 from −200 to 200 m, is exactly $500\left(0.4\sqrt{1.16} + \operatorname{asinh} 0.4\right)$ m long. That is Step 5's closed form.
- The moving point x = 200t, y = 40t^2 traces the same parabola, tower to tower.
- The hand arithmetic holds exactly, as fractions: the 40 m sag, the 0.4 slope at a tower, 1.16 and the 80 m vertical travel.
- Dropping the square root gives exactly 1264/3 m, and the rule of thumb gives 1232/3 m.

The decimals, the Simpson sums, the chord totals and the 40 m step are left to the Python and Rust checks.

```lean
-- Arc length: for a point moving in the plane with rates that have no jumps, the least upper bound of its chord totals equals the integral of its speed, a graph's length is the integral of √(1 + f'(x)^2), and the card's cable y = x^2/1000 from −200 to 200 m is exactly 500(0.4·√1.16 + asinh 0.4) metres long.
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Analysis.BoundedVariation
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Arsinh
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Set Real

lemma arcLen_sqrt_le (X Y p q : ℝ) :
    √(X ^ 2 + Y ^ 2) ≤ √(p ^ 2 + q ^ 2) + |X - p| + |Y - q| := by
  set N := √(p ^ 2 + q ^ 2) with hNdef
  have hN : N ^ 2 = p ^ 2 + q ^ 2 := Real.sq_sqrt (by positivity)
  have hN0 : 0 ≤ N := Real.sqrt_nonneg _
  have hp : |p| ≤ N := Real.abs_le_sqrt (by nlinarith [sq_nonneg q])
  have hq : |q| ≤ N := Real.abs_le_sqrt (by nlinarith [sq_nonneg p])
  have h1 : p * (X - p) ≤ N * |X - p| :=
    (le_abs_self _).trans (by rw [abs_mul]; exact mul_le_mul_of_nonneg_right hp (abs_nonneg _))
  have h2 : q * (Y - q) ≤ N * |Y - q| :=
    (le_abs_self _).trans (by rw [abs_mul]; exact mul_le_mul_of_nonneg_right hq (abs_nonneg _))
  have h3 : |X - p| ^ 2 = (X - p) ^ 2 := sq_abs _
  have h4 : |Y - q| ^ 2 = (Y - q) ^ 2 := sq_abs _
  have h5 : 0 ≤ |X - p| * |Y - q| := mul_nonneg (abs_nonneg _) (abs_nonneg _)
  calc √(X ^ 2 + Y ^ 2) ≤ √((N + |X - p| + |Y - q|) ^ 2) :=
        Real.sqrt_le_sqrt (by nlinarith)
    _ = N + |X - p| + |Y - q| := Real.sqrt_sq (by positivity)

lemma arcLen_dot_le (c s X Y : ℝ) (h : c ^ 2 + s ^ 2 = 1) : c * X + s * Y ≤ √(X ^ 2 + Y ^ 2) :=
  (le_abs_self _).trans (Real.abs_le_sqrt (by nlinarith [sq_nonneg (c * Y - s * X)]))

lemma arcLen_dist_eq (a b c d : ℝ) :
    dist (!₂[a, b]) (!₂[c, d]) = √((a - c) ^ 2 + (b - d) ^ 2) := by
  rw [EuclideanSpace.dist_eq]; simp [Fin.sum_univ_two, Real.dist_eq, sq_abs]

lemma arcLen_dist_le_integral {x y x' y' : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hxc : ContinuousOn x (Icc a b)) (hyc : ContinuousOn y (Icc a b))
    (hxd : ∀ t ∈ Ioo a b, HasDerivAt x (x' t) t) (hyd : ∀ t ∈ Ioo a b, HasDerivAt y (y' t) t)
    (hx'c : ContinuousOn x' (Icc a b)) (hy'c : ContinuousOn y' (Icc a b)) :
    dist (!₂[x b, y b]) (!₂[x a, y a]) ≤ ∫ t in a..b, √(x' t ^ 2 + y' t ^ 2) := by
  have hA : ∫ t in a..b, x' t = x b - x a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hxc hxd
      (hx'c.intervalIntegrable_of_Icc hab)
  have hB : ∫ t in a..b, y' t = y b - y a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hyc hyd
      (hy'c.intervalIntegrable_of_Icc hab)
  have hvc : ContinuousOn (fun t => √(x' t ^ 2 + y' t ^ 2)) (Icc a b) :=
    ((hx'c.pow 2).add (hy'c.pow 2)).sqrt
  rw [arcLen_dist_eq]
  set A := x b - x a
  set B := y b - y a
  rcases eq_or_lt_of_le (Real.sqrt_nonneg (A ^ 2 + B ^ 2)) with h0 | hpos
  · rw [← h0]; exact intervalIntegral.integral_nonneg hab (fun t _ => Real.sqrt_nonneg _)
  · set N := √(A ^ 2 + B ^ 2) with hNdef
    have hN2 : N ^ 2 = A ^ 2 + B ^ 2 := Real.sq_sqrt (by positivity)
    have key : N = ∫ t in a..b, ((A / N) * x' t + (B / N) * y' t) := by
      rw [intervalIntegral.integral_add, intervalIntegral.integral_const_mul,
        intervalIntegral.integral_const_mul, hA, hB]
      · field_simp; linarith [hN2]
      · exact ((continuousOn_const.mul hx'c).intervalIntegrable_of_Icc hab)
      · exact ((continuousOn_const.mul hy'c).intervalIntegrable_of_Icc hab)
    rw [key]
    apply intervalIntegral.integral_mono_on hab
    · exact (((continuousOn_const.mul hx'c).add (continuousOn_const.mul hy'c)).intervalIntegrable_of_Icc hab)
    · exact hvc.intervalIntegrable_of_Icc hab
    · intro t _
      apply arcLen_dot_le
      field_simp; linarith [hN2]

lemma arcLen_integral_le_dist {x y x' y' : ℝ → ℝ} {a b ε : ℝ} (hab : a ≤ b)
    (hxc : ContinuousOn x (Icc a b)) (hyc : ContinuousOn y (Icc a b))
    (hxd : ∀ t ∈ Ioo a b, HasDerivAt x (x' t) t) (hyd : ∀ t ∈ Ioo a b, HasDerivAt y (y' t) t)
    (hx'c : ContinuousOn x' (Icc a b)) (hy'c : ContinuousOn y' (Icc a b))
    (hεx : ∀ t ∈ Icc a b, |x' t - x' a| ≤ ε) (hεy : ∀ t ∈ Icc a b, |y' t - y' a| ≤ ε) :
    ∫ t in a..b, √(x' t ^ 2 + y' t ^ 2) ≤ dist (!₂[x b, y b]) (!₂[x a, y a]) + 4 * ε * (b - a) := by
  have hA : ∫ t in a..b, x' t = x b - x a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hxc hxd
      (hx'c.intervalIntegrable_of_Icc hab)
  have hB : ∫ t in a..b, y' t = y b - y a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hyc hyd
      (hy'c.intervalIntegrable_of_Icc hab)
  have hvc : ContinuousOn (fun t => √(x' t ^ 2 + y' t ^ 2)) (Icc a b) :=
    ((hx'c.pow 2).add (hy'c.pow 2)).sqrt
  rw [arcLen_dist_eq]
  set p := x' a
  set q := y' a
  have h1 : ∫ t in a..b, √(x' t ^ 2 + y' t ^ 2) ≤ ∫ t in a..b, (√(p ^ 2 + q ^ 2) + 2 * ε) :=
    intervalIntegral.integral_mono_on hab (hvc.intervalIntegrable_of_Icc hab)
      intervalIntegrable_const
      (fun t ht => (arcLen_sqrt_le _ _ p q).trans (by linarith [hεx t ht, hεy t ht]))
  rw [intervalIntegral.integral_const, smul_eq_mul] at h1
  have hba : |b - a| = b - a := abs_of_nonneg (sub_nonneg.2 hab)
  have hxA : |(b - a) * p - (x b - x a)| ≤ ε * (b - a) := by
    have : (x b - x a) - (b - a) * p = ∫ t in a..b, (x' t - p) := by
      rw [intervalIntegral.integral_sub (hx'c.intervalIntegrable_of_Icc hab)
        intervalIntegrable_const, hA, intervalIntegral.integral_const, smul_eq_mul]
    rw [abs_sub_comm, this]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := a) (b := b) (C := ε)
      (f := fun t => x' t - p)
      (fun t ht => hεx t (Ioc_subset_Icc_self (by simpa [uIoc_of_le hab] using ht)))
    simpa [hba] using this
  have hyB : |(b - a) * q - (y b - y a)| ≤ ε * (b - a) := by
    have : (y b - y a) - (b - a) * q = ∫ t in a..b, (y' t - q) := by
      rw [intervalIntegral.integral_sub (hy'c.intervalIntegrable_of_Icc hab)
        intervalIntegrable_const, hB, intervalIntegral.integral_const, smul_eq_mul]
    rw [abs_sub_comm, this]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := a) (b := b) (C := ε)
      (f := fun t => y' t - q)
      (fun t ht => hεy t (Ioc_subset_Icc_self (by simpa [uIoc_of_le hab] using ht)))
    simpa [hba] using this
  have h2 := arcLen_sqrt_le ((b - a) * p) ((b - a) * q) (x b - x a) (y b - y a)
  have h3 : √(((b - a) * p) ^ 2 + ((b - a) * q) ^ 2) = (b - a) * √(p ^ 2 + q ^ 2) := by
    rw [show ((b - a) * p) ^ 2 + ((b - a) * q) ^ 2 = (b - a) ^ 2 * (p ^ 2 + q ^ 2) by ring,
      Real.sqrt_mul (by positivity), Real.sqrt_sq (by linarith)]
  rw [h3] at h2
  nlinarith

#print axioms arcLen_sqrt_le
#print axioms arcLen_dot_le
#print axioms arcLen_dist_eq
#print axioms arcLen_dist_le_integral
#print axioms arcLen_integral_le_dist

/-- **Length is the integral of speed.** A point moves in the plane, at position (x(t), y(t))
at clock time t, from t₀ to t₁. Its rates x'(t) and y'(t) have no jumps: x and y are
continuously differentiable on the closed stretch [t₀, t₁]. The length of its path is defined
by chords: the least upper bound, over every way of picking clock times
t₀ ≤ s₀ ≤ s₁ ≤ … ≤ sₙ ≤ t₁, of the total of the straight (Euclidean) distances between
successive positions; Mathlib calls this `eVariationOn`. Each pass is counted. That length equals
the integral of the speed √(x'(t)^2 + y'(t)^2) from t₀ to t₁ (and so it is finite). -/
theorem arc_length_eq_integral_of_speed {x y : ℝ → ℝ} {t₀ t₁ : ℝ}
    (hx : ContDiffOn ℝ 1 x (Icc t₀ t₁)) (hy : ContDiffOn ℝ 1 y (Icc t₀ t₁)) :
    eVariationOn (fun t => !₂[x t, y t]) (Icc t₀ t₁) =
      ENNReal.ofReal (∫ t in t₀..t₁, √(deriv x t ^ 2 + deriv y t ^ 2)) := by
  rcases le_or_gt t₁ t₀ with h | hlt
  · have hsub : (Icc t₀ t₁).Subsingleton := fun a ha b hb => by
      simp only [mem_Icc] at ha hb; linarith
    rw [eVariationOn.constant_on (hsub.image _), eq_comm, ENNReal.ofReal_eq_zero,
      intervalIntegral.integral_symm, neg_nonpos]
    exact intervalIntegral.integral_nonneg h fun _ _ => Real.sqrt_nonneg _
  set x' := derivWithin x (Icc t₀ t₁) with hx'def
  set y' := derivWithin y (Icc t₀ t₁) with hy'def
  have hU : UniqueDiffOn ℝ (Icc t₀ t₁) := uniqueDiffOn_Icc hlt
  have hx'c : ContinuousOn x' (Icc t₀ t₁) := hx.continuousOn_derivWithin hU le_rfl
  have hy'c : ContinuousOn y' (Icc t₀ t₁) := hy.continuousOn_derivWithin hU le_rfl
  have hxd : ∀ t ∈ Ioo t₀ t₁, HasDerivAt x (x' t) t := fun t ht => by
    have hmem : Icc t₀ t₁ ∈ nhds t := Icc_mem_nhds ht.1 ht.2
    have hd := ((hx.differentiableOn one_ne_zero) t (Ioo_subset_Icc_self ht)).differentiableAt hmem
    rw [hx'def, derivWithin_of_mem_nhds hmem]; exact hd.hasDerivAt
  have hyd : ∀ t ∈ Ioo t₀ t₁, HasDerivAt y (y' t) t := fun t ht => by
    have hmem : Icc t₀ t₁ ∈ nhds t := Icc_mem_nhds ht.1 ht.2
    have hd := ((hy.differentiableOn one_ne_zero) t (Ioo_subset_Icc_self ht)).differentiableAt hmem
    rw [hy'def, derivWithin_of_mem_nhds hmem]; exact hd.hasDerivAt
  have hint_eq : ∫ t in t₀..t₁, √(deriv x t ^ 2 + deriv y t ^ 2) =
      ∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2) := by
    apply intervalIntegral.integral_congr_Ioo_of_le hlt.le
    intro t ht
    simp only [(hxd t ht).deriv, (hyd t ht).deriv]
  have hvc : ContinuousOn (fun t => √(x' t ^ 2 + y' t ^ 2)) (Icc t₀ t₁) :=
    ((hx'c.pow 2).add (hy'c.pow 2)).sqrt
  have hsubI : ∀ {a b}, a ∈ Icc t₀ t₁ → b ∈ Icc t₀ t₁ → Icc a b ⊆ Icc t₀ t₁ :=
    fun ha hb => Icc_subset_Icc ha.1 hb.2
  have hsubO : ∀ {a b}, a ∈ Icc t₀ t₁ → b ∈ Icc t₀ t₁ → Ioo a b ⊆ Ioo t₀ t₁ :=
    fun ha hb => Ioo_subset_Ioo ha.1 hb.2
  have hII : ∀ {a b}, a ∈ Icc t₀ t₁ → b ∈ Icc t₀ t₁ →
      IntervalIntegrable (fun t => √(x' t ^ 2 + y' t ^ 2)) MeasureTheory.volume a b :=
    fun ha hb => (hvc.mono (uIcc_subset_Icc ha hb)).intervalIntegrable
  rw [hint_eq]
  apply le_antisymm
  · refine iSup_le fun P => ?_
    obtain ⟨n, u, hu, us⟩ := P
    dsimp only
    calc ∑ i ∈ Finset.range n, edist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])
        = ENNReal.ofReal (∑ i ∈ Finset.range n,
            dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])) := by
          rw [ENNReal.ofReal_sum_of_nonneg (fun _ _ => dist_nonneg)]
          simp only [edist_dist]
      _ ≤ ENNReal.ofReal (∑ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2)) := by
          apply ENNReal.ofReal_le_ofReal
          apply Finset.sum_le_sum
          intro i _
          have hle : u i ≤ u (i + 1) := hu (Nat.le_succ i)
          have hI := hsubI (us i) (us (i + 1))
          have hO := hsubO (us i) (us (i + 1))
          exact arcLen_dist_le_integral hle (hx.continuousOn.mono hI) (hy.continuousOn.mono hI)
            (fun t ht => hxd t (hO ht)) (fun t ht => hyd t (hO ht)) (hx'c.mono hI) (hy'c.mono hI)
      _ = ENNReal.ofReal (∫ t in u 0..u n, √(x' t ^ 2 + y' t ^ 2)) := by
          rw [intervalIntegral.sum_integral_adjacent_intervals]
          intro k _
          exact hII (us k) (us (k + 1))
      _ ≤ ENNReal.ofReal (∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2)) := by
          apply ENNReal.ofReal_le_ofReal
          have h0 : t₀ ∈ Icc t₀ t₁ := ⟨le_rfl, hlt.le⟩
          have h1 : t₁ ∈ Icc t₀ t₁ := ⟨hlt.le, le_rfl⟩
          rw [← intervalIntegral.integral_add_adjacent_intervals (hII h0 (us 0)) (hII (us 0) h1),
            ← intervalIntegral.integral_add_adjacent_intervals (hII (us 0) (us n)) (hII (us n) h1)]
          have e1 : 0 ≤ ∫ t in t₀..u 0, √(x' t ^ 2 + y' t ^ 2) :=
            intervalIntegral.integral_nonneg (us 0).1 fun _ _ => Real.sqrt_nonneg _
          have e2 : 0 ≤ ∫ t in u n..t₁, √(x' t ^ 2 + y' t ^ 2) :=
            intervalIntegral.integral_nonneg (us n).2 fun _ _ => Real.sqrt_nonneg _
          linarith
  · apply ENNReal.le_of_forall_pos_le_add
    intro η hη _
    have hL : 0 < t₁ - t₀ := sub_pos.2 hlt
    set ε : ℝ := (η : ℝ) / (4 * (t₁ - t₀)) with hεdef
    have hε : 0 < ε := by positivity
    have hεL : 4 * ε * (t₁ - t₀) = η := by rw [hεdef]; field_simp
    obtain ⟨δx, hδx, hx'u⟩ := Metric.uniformContinuousOn_iff.1
      (isCompact_Icc.uniformContinuousOn_of_continuous hx'c) ε hε
    obtain ⟨δy, hδy, hy'u⟩ := Metric.uniformContinuousOn_iff.1
      (isCompact_Icc.uniformContinuousOn_of_continuous hy'c) ε hε
    set δ := min δx δy
    have hδ : 0 < δ := lt_min hδx hδy
    obtain ⟨n, hn⟩ := exists_nat_gt ((t₁ - t₀) / δ)
    have hnpos : (0 : ℝ) < n := lt_trans (by positivity) hn
    set h := (t₁ - t₀) / n with hhdef
    have hh : 0 < h := by positivity
    have hhδ : h < δ := by
      rw [hhdef, div_lt_iff₀ hnpos]; rw [div_lt_iff₀ hδ] at hn; linarith
    have hnh : (n : ℝ) * h = t₁ - t₀ := by rw [hhdef]; field_simp
    set u : ℕ → ℝ := fun i => t₀ + i * h with hudef
    have hmono : MonotoneOn u (Iic n) := fun i _ j _ hij => by
      simp only [hudef]; gcongr
    have hus : ∀ i ≤ n, u i ∈ Icc t₀ t₁ := fun i hi => by
      have : (i : ℝ) ≤ n := by exact_mod_cast hi
      constructor
      · simp only [hudef]; nlinarith
      · simp only [hudef]; nlinarith
    have hsum := eVariationOn.sum_le_of_monotoneOn_Iic
      (f := fun t => !₂[x t, y t]) hmono hus
    have hkey : ∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2) ≤
        (∑ i ∈ Finset.range n, dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)]))
          + η := by
      have hu0 : u 0 = t₀ := by simp [hudef]
      have hun : u n = t₁ := by simp only [hudef]; linarith
      have hsplit : ∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2) =
          ∑ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2) := by
        rw [intervalIntegral.sum_integral_adjacent_intervals, hu0, hun]
        intro k hk
        exact hII (hus k hk.le) (hus (k + 1) hk)
      rw [hsplit, ← hεL, ← hnh]
      have : ∀ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2) ≤
          dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)]) + 4 * ε * h := by
        intro i hi
        rw [Finset.mem_range] at hi
        have hai := hus i hi.le
        have hbi := hus (i + 1) hi
        have hle : u i ≤ u (i + 1) := hmono (mem_Iic.2 hi.le) (mem_Iic.2 hi) (Nat.le_succ i)
        have hdiff : u (i + 1) - u i = h := by simp only [hudef]; push_cast; ring
        have hI := hsubI hai hbi
        have hO := hsubO hai hbi
        have := arcLen_integral_le_dist (ε := ε) hle (hx.continuousOn.mono hI)
          (hy.continuousOn.mono hI)
          (fun t ht => hxd t (hO ht)) (fun t ht => hyd t (hO ht)) (hx'c.mono hI) (hy'c.mono hI)
          (fun t ht => by
            have hd : dist t (u i) < δx := by
              rw [Real.dist_eq, abs_of_nonneg (by linarith [ht.1])]
              linarith [ht.2, min_le_left δx δy]
            have := hx'u t (hI ht) (u i) hai hd
            rw [Real.dist_eq] at this; exact this.le)
          (fun t ht => by
            have hd : dist t (u i) < δy := by
              rw [Real.dist_eq, abs_of_nonneg (by linarith [ht.1])]
              linarith [ht.2, min_le_right δx δy]
            have := hy'u t (hI ht) (u i) hai hd
            rw [Real.dist_eq] at this; exact this.le)
        rw [hdiff] at this; exact this
      calc ∑ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2)
          ≤ ∑ i ∈ Finset.range n,
            (dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)]) + 4 * ε * h) :=
            Finset.sum_le_sum this
        _ = _ := by rw [Finset.sum_add_distrib, Finset.sum_const, Finset.card_range, nsmul_eq_mul]; ring
    calc ENNReal.ofReal (∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2))
        ≤ ENNReal.ofReal ((∑ i ∈ Finset.range n,
            dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])) + η) :=
          ENNReal.ofReal_le_ofReal hkey
      _ = (∑ i ∈ Finset.range n,
            edist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])) + η := by
          rw [ENNReal.ofReal_add (Finset.sum_nonneg fun _ _ => dist_nonneg) (NNReal.coe_nonneg η),
            ENNReal.ofReal_sum_of_nonneg (fun _ _ => dist_nonneg), ENNReal.ofReal_coe_nnreal]
          simp only [edist_dist]
      _ ≤ _ := by gcongr

/-- **The graph formula.** If the height f(x) and its slope f'(x) have no jumps on the stretch
from a to b (f is continuously differentiable on [a, b]), then the length of the graph
x ↦ (x, f(x)) over [a, b], the least upper bound of its chord totals, is
∫ from a to b of √(1 + f'(x)^2). -/
theorem graph_length_eq_integral_sqrt_one_add_deriv_sq {f : ℝ → ℝ} {a b : ℝ}
    (hf : ContDiffOn ℝ 1 f (Icc a b)) :
    eVariationOn (fun x => !₂[x, f x]) (Icc a b) =
      ENNReal.ofReal (∫ x in a..b, √(1 + deriv f x ^ 2)) := by
  simpa using arc_length_eq_integral_of_speed (x := fun t => t) (y := f) contDiffOn_id hf

/-- **The cable.** The suspension cable hangs as y = x^2/1000 between towers at x = −200 and
x = 200 m (span 400 m, sag 40 m). Its length, the least upper bound of its chord totals, is
exactly 500 · (0.4 · √1.16 + asinh 0.4) metres, about 410.424 m. Here 0.4 = 2/5 and
1.16 = 29/25. -/
theorem cable_length_closed_form :
    eVariationOn (fun x : ℝ => !₂[x, x ^ 2 / 1000]) (Icc (-200) 200) =
      ENNReal.ofReal (500 * (2 / 5 * √(29 / 25) + arsinh (2 / 5))) := by
  rw [graph_length_eq_integral_sqrt_one_add_deriv_sq (f := fun x : ℝ => x ^ 2 / 1000)
    ((contDiff_id.pow 2).div_const _).contDiffOn]
  congr 1
  have hd : ∀ x : ℝ, deriv (fun x : ℝ => x ^ 2 / 1000) x = x / 500 := fun x => by
    rw [((hasDerivAt_pow 2 x).div_const 1000).deriv]; ring
  simp only [hd]
  have hF : ∀ x ∈ uIcc (-200 : ℝ) 200, HasDerivAt
      (fun x : ℝ => 250 * (x / 500 * √(1 + (x / 500) ^ 2) + arsinh (x / 500)))
      (√(1 + (x / 500) ^ 2)) x := by
    intro x _
    have hu : HasDerivAt (fun x : ℝ => x / 500) (1 / 500) x := (hasDerivAt_id x).div_const 500
    have hpos : 0 < 1 + (x / 500) ^ 2 := by positivity
    have hs : HasDerivAt (fun x : ℝ => √(1 + (x / 500) ^ 2))
        ((2 * (x / 500) * (1 / 500)) / (2 * √(1 + (x / 500) ^ 2))) x := by
      have h1 : HasDerivAt (fun x : ℝ => 1 + (x / 500) ^ 2) (2 * (x / 500) * (1 / 500)) x := by
        have := (hu.pow 2).const_add 1
        convert this using 1; push_cast; ring
      exact h1.sqrt hpos.ne'
    have := ((hu.mul hs).add hu.arsinh).const_mul 250
    convert this using 1
    have hsq := Real.sq_sqrt hpos.le
    have hspos := Real.sqrt_pos.2 hpos
    rw [smul_eq_mul]
    generalize √(1 + (x / 500) ^ 2) = s at hsq hspos ⊢
    field_simp
    nlinarith [hsq]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF
    (by apply Continuous.intervalIntegrable; fun_prop)]
  have e1 : (200 : ℝ) / 500 = 2 / 5 := by norm_num
  have e2 : (-200 : ℝ) / 500 = -(2 / 5) := by norm_num
  have e3 : 1 + ((2 : ℝ) / 5) ^ 2 = 29 / 25 := by norm_num
  simp only [e1, e2, neg_sq, e3, Real.arsinh_neg]
  ring

-- The sag: the cable's height at a tower is 200^2/1000 = 40 m.
example : (200 : ℚ) ^ 2 / 1000 = 40 := by norm_num
-- The slope x/500 at a tower is 200/500 = 0.4 = 2/5.
example : (200 : ℚ) / 500 = 2 / 5 := by norm_num
-- The stretch factor squared at a tower: 1 + 0.4^2 = 1.16 = 29/25.
example : 1 + ((2 : ℚ) / 5) ^ 2 = 29 / 25 := by norm_num
-- The slope x/500 is the derivative of x^2/1000: 2x/1000 = x/500.
example : ∀ x : ℚ, 2 * x / 1000 = x / 500 := by intro x; ring
-- The moving point x = 200t, y = 40t^2 traces the same parabola: 40t^2 = (200t)^2/1000.
example : ∀ t : ℚ, 40 * t ^ 2 = (200 * t) ^ 2 / 1000 := by intro t; ring
-- It starts and ends at the towers: x = ∓200, y = 40 at t = ∓1.
example : (200 : ℚ) * (-1) = -200 ∧ (40 : ℚ) * (-1) ^ 2 = 40 ∧ (200 : ℚ) * 1 = 200 := by norm_num
-- Its speed squared at t = 1 is 200^2 + 80^2 = 46400 = 40000 · 1.16, the graph's stretch factor
-- squared times the clock's 200 m per unit of time, squared.
example : (200 : ℚ) ^ 2 + (2 * 40 * 1) ^ 2 = 200 ^ 2 * (29 / 25) := by norm_num
-- Integrating the slope's size, forgetting the 1: vertical travel 40 m down plus 40 m up = 80 m.
example : (40 : ℚ) + 40 = 80 := by norm_num
-- Dropping the square root: 400 + (200^3 + 200^3)/(3 · 500^2) = 1264/3 m, about 421.333 m.
example : (400 : ℚ) + (200 ^ 3 + 200 ^ 3) / (3 * 500 ^ 2) = 1264 / 3 := by norm_num
-- The shallow-sag rule of thumb: 400 + 8 · 40^2/(3 · 400) = 1232/3 m, about 410.667 m.
example : (400 : ℚ) + 8 * 40 ^ 2 / (3 * 400) = 1232 / 3 := by norm_num
-- Figure points at 0.8 units per metre: the towers (−200, 40) and (200, 40) sit
-- 0.8 · 400 = 320 units apart (x = 20 and x = 340).
example : (340 : ℚ) - 20 = 4 / 5 * 400 := by norm_num

#print axioms arc_length_eq_integral_of_speed
#print axioms graph_length_eq_integral_sqrt_one_add_deriv_sq
#print axioms cable_length_closed_form
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'arcLen_sqrt_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'arcLen_dot_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'arcLen_dist_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'arcLen_dist_le_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'arcLen_integral_le_dist' depends on axioms: [propext, Classical.choice, Quot.sound]
'arc_length_eq_integral_of_speed' depends on axioms: [propext, Classical.choice, Quot.sound]
'graph_length_eq_integral_sqrt_one_add_deriv_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'cable_length_closed_form' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A deeper sag.** Set `D = 80.0` and guess the extra wire. About 439 m: double the sag, nearly four times the extra.
> - **Coarser Simpson.** Give the graph `4` strips, not `100`. It lands within 8 mm, and the first assert stops the run.
> - **Forget Pythagoras.** In `polygon`, drop the height term. Every chord total becomes 400 m, and the climbing assert fails.

---

## The usual mistake

> [!warning]
> **Treating the integral of the slope as the length.** The integral of $f'(x)$ is the change in height, 0 m tower to tower; the integral of its size is the vertical travel, 80 m. Length joins both directions by Pythagoras: hence the 1 and the square root.
>
> - **Dropping the square root.** 421.333 m against the true 410.424 m.
> - **Trusting a coarse chain.** Two chords give 407.92 m, 2.5027 m short.
> - **Mixing units.** Height in metres against x in kilometres puts the slope a thousand times off.

---

## Where you meet it in real life

- **Suspension bridges.** Main cables are spun to a computed length. A cable under its own weight hangs as a catenary (a cosh curve); the same integral measures it.
- **GPS tracks.** A GPS log is a chord chain between fixes; a sparse log reads short on a winding road.
- **Wires and surfaces.** Where a bent wire balances uses its length: [Centre of mass](05-centre-of-mass-and-pappus.md). Spinning a curve's length round an axis gives [Surface area](04-surface-area-of-revolution.md).

> **Say it back**
> Length is defined by chords: join points, add the straight pieces, refine; the length is the least upper bound of the totals. Each chord is its width times the square root of one plus the slope squared somewhere in its strip, so the total is a Riemann sum and the length an integral. For a moving point it is the integral of speed, whatever the clock. The 400 m cable with a 40 m sag is 410.424 m long.

---

## What this builds on

- [Parametric motion](01-parametric-motion.md): position as functions of a clock, and speed.
- [The integral](../04-Integrals/01-riemann-integral.md): strip sums closing in on the integral, as in Step 2.

## Where this goes next

- [Surface area](04-surface-area-of-revolution.md): spins each small length round an axis.
- [Line integrals of a function](../09-Vector%20Calculus/01-scalar-line-integrals.md): weights each small length by a density.
- Regular curve and arc length: length itself as the clock.

Arc length adds plain metres of curve; how to add something that varies along it, such as the cable's weight per metre, is what a line integral answers.

---

## Sources

Verified 2026-09-27: every link below resolves to the publisher's page.

- Strang, Gilbert, Edwin Herman et al. *Calculus Volume 2*, OpenStax. [Section 2.4, Arc Length of a Curve and Surface Area](https://openstax.org/books/calculus-volume-2/pages/2-4-arc-length-of-a-curve-and-surface-area). The graph formula from chords.
- Strang, Gilbert, Edwin Herman et al. *Calculus Volume 3*, OpenStax. [Section 3.3, Arc Length and Curvature](https://openstax.org/books/calculus-volume-3/pages/3-3-arc-length-and-curvature). Length as the integral of speed.
- "Catenary." MacTutor History of Mathematics, University of St Andrews. [Curve page](https://mathshistory.st-andrews.ac.uk/Curves/Catenary/). The hanging chain, and Jungius's 1669 disproof of Galileo's parabola.
