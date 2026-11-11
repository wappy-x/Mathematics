# Power series: polynomials that never stop, and the radius inside which they behave

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Series](../README.md#s06) → Power series

---

## General Overview

A calculator chip can add and multiply, but has no circuit for the natural log of 1.5. It runs a recipe of adds and multiplies instead: 0.500000 − 0.125000 + 0.041667 − 0.015625 + … Twenty terms give 0.405465093. The true value is 0.405465108.

The recipe is a polynomial that never stops. At 0.5 its terms shrink fast; at 1.1 the x^100 term alone is −137.81. So it comes with a fence: inside it works, outside it fails, and each fence post must be checked by hand.

Two recipes run through this card: 1 + x + x^2 + …, which adds up to 1/(1 − x), and x − x^2/2 + x^3/3 − …, which adds up to ln(1 + x) and comes from the first by integrating term by term. From here on a recipe is a **power series**, the fence's half-width its **radius of convergence**, and the two posts its **endpoints**.

**A power series converges at every input nearer its centre than a distance R, fails farther away, must be tested separately at the two inputs exactly R away, and inside can be differentiated and integrated term by term.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; the power series itself is a definition.

### The picture: the log and two of its partial sums

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "ln(1 + x) against its series cut off after x^4 and after x^10"
    x-axis "Input x (a pure number)" [-0.9, -0.6, -0.3, 0, 0.3, 0.6, 0.9, 1.2, 1.5]
    y-axis "Output (a pure number)" -2.5 --> 1.5
    line [-2.30, -0.92, -0.36, 0.00, 0.26, 0.47, 0.64, 0.79, 0.92]
    line [-1.71, -0.88, -0.36, 0.00, 0.26, 0.46, 0.57, 0.54, 0.23]
    line [-2.12, -0.92, -0.36, 0.00, 0.26, 0.47, 0.63, 0.47, -2.40]
```

Orange is ln(1 + x), computed as an area; teal, the series cut after x^4; dark blue, after x^10. From −0.3 to 0.3 all agree to two decimals. Past the fence, at 1.5, extra terms hurt: −2.40 against 0.92.

---

## The formula

A power series has a centre c, fixed numbers $a_n$ called coefficients, and an input x. The bars in $|x - c|$ mean the distance from x to c. A sigma sign running to infinity means the limit of partial sums ([Infinite series](01-series-convergence.md)).

$$f(x) = \sum_{n=0}^{\infty} a_n (x-c)^n = a_0 + a_1 (x-c) + a_2 (x-c)^2 + \cdots$$

**Read it aloud:** f of x is where the sums of more and more terms head, each term a fixed number times a power of the distance from the centre.

$$R = \frac{1}{L}, \qquad L = \lim_{n\to\infty} \left| \frac{a_{n+1}}{a_n} \right|$$

**Read it aloud:** the radius is one over the limit of neighbouring coefficient ratios; L = 0 means no fence, and L infinite means only the centre works.

$$f'(x) = \sum_{n=1}^{\infty} n\, a_n (x-c)^{n-1}, \qquad \int_c^x f(t)\,dt = \sum_{n=0}^{\infty} \frac{a_n}{n+1} (x-c)^{n+1}, \qquad |x - c| < R$$

**Read it aloud:** strictly inside the radius, differentiate or integrate each term; both new series have radius R.

The card's two series, centred at c = 0:

$$\frac{1}{1-x} = \sum_{n=0}^{\infty} x^n, \qquad \ln(1+x) = \sum_{n=1}^{\infty} \frac{(-1)^{n+1}}{n}\, x^n$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$, $t$ | the input; t is a stand-in input inside an integral | x = 0.5; endpoints −1 and 1 | nearer an endpoint, slower convergence |
| $n$, $N$ | n counts terms; N is the last power kept | N = 20 | larger N, smaller gap inside |
| $a_n$ | the coefficient of the n-th power | 1; and (−1)^(n+1)/n for the log | faster growth, smaller radius |
| $c$ | the centre | 0 | slides the fence |
| $f$ | the function the series adds up to | 1/(1 − x), ln(1 + x) | — |
| $S_N$ | partial sum: terms through the N-th power | S_20(0.5) = 0.405465093, log | heads for f(x) inside |
| $R$, $L$ | radius; limit of coefficient ratios, R = 1/L | L = 1, R = 1 | larger L, smaller R |
| $d$, $M$ | in the proof: a working distance, and a ceiling on the terms there | d below 1 | — |

### When it holds

- **Strictly inside.** At distance exactly R the theorem is silent: the two series here behave differently at their endpoints.
- **The ratio formula needs a limit.** If ratios never settle, or coefficients vanish, R still exists (Step 1) but the root test finds it ([Convergence tests](02-comparison-ratio-and-root-tests.md)).
- **Term by term only inside.** At x = 1 the log series converges; its differentiated series 1 − 1 + 1 − … does not.

---

## Why it works

### Step 0: at a fixed input, a power series is a plain series

At x = 0.5, 1 + x + x^2 + … is 1 + 0.5 + 0.25 + …, the shelf's house example, adding up to 2. Each fixed input gives an ordinary series, decided by comparing with a geometric one.

### Step 1: working at one distance forces working at every smaller distance

Say the series converges at distance d from the centre. Its terms shrink to zero, so none exceeds some ceiling M. At a nearer input the n-th term is at most M times (|x − c|/d)^n, a geometric series with ratio below 1, so it converges, even with every term made positive.

So the working inputs fill a stretch around c with no holes. Let R be the least upper bound (sup) of the working distances. Anything nearer than R lies below some working distance, so works; anything farther cannot work, or R would not be an upper bound.

### Step 2: the ratio test measures the fence

Neighbouring terms have ratio $|a_{n+1}/a_n|$ times |x − c|, heading for L times |x − c|. Below 1 converges, above 1 diverges, so R = 1/L. For the log the ratio n/(n + 1) is 0.999001 at n = 1,000, heading for 1; for 1/(1 − x) it is 1. Both radii are 1.

### Step 3: the endpoints are separate questions

At distance R the ratio heads for exactly 1 and the test is silent.

- **1/(1 − x) at 1:** 1 + 1 + 1 + …; through x^99 the sum is 100. Diverges.
- **1/(1 − x) at −1:** sums run 1, 0, 1, 0. Diverges.
- **Log at −1:** minus the harmonic series 1 + 1/2 + 1/3 + …, −7.485471 after 1,000 terms. Diverges.
- **Log at 1:** 1 − 1/2 + 1/3 − …, which converges ([Alternating series](03-alternating-and-conditional-convergence.md)); Step 5 proves it equals ln 2.

So 1/(1 − x) works for −1 < x < 1; the log for −1 < x ≤ 1.

### Step 4: inside, differentiate and integrate term by term

Fix x inside and a distance d between |x − c| and R. The differentiated terms are at most n times a geometric series with ratio below 1, and n grows slower than the geometric factor shrinks, so they converge. That this sum is the slope of f takes a bound on the gap, folded below.

For integration, the tail beyond N terms is small at every point from c to x at once, so its integral is small.

<details>
<summary>Detailed proof</summary>

Take c = 0, and a distance r between |x| and d: |x| < r < d < R. Convergence at d gives $|a_n| d^n \le M$.

**Slope.** For a small step h with |x + h| ≤ r, the mean value theorem applied twice to $y^n$ gives $|((x+h)^n - x^n)/h - n x^{n-1}| \le |h|\, n(n-1)\, r^{n-2}$. Summed, the gap between f's difference quotient and $\sum n a_n x^{n-1}$ is at most $|h| (M/r^2) \sum n(n-1)(r/d)^n$. That sum converges by the ratio test, so the gap is a constant times |h|; for any tolerance ε, |h| below ε over the constant works.

**Same radius.** Convergence of the differentiated series at a point y with |y| > R would, by Step 1, give absolute convergence at some z with R < |z| < |y|; since $|a_n z^n| \le |z| \cdot n |a_n| |z|^{n-1}$, the original would converge beyond R. The integrated series has the original as its derivative series, so its radius is R too.

**Integral.** For |t| ≤ |x| the tail beyond N terms is at most $\sum_{n>N} M (|x|/d)^n$, a number independent of t that heads for 0; its integral is at most |x| times that.

</details>

### Step 5: the log series and its error, from the geometric series

Replace x by −t: 1/(1 + t) = 1 − t + t^2 − … for |t| < 1. Integrate each term from 0 to x. The antiderivative of 1/(1 + t) is ln(1 + t), so ln(1 + x) = x − x^2/2 + x^3/3 − …

A finite version gives the error. The finite geometric sum says 1/(1 + t) is 1 − t + … ± t^(N−1) plus a remainder ±t^N/(1 + t). Integrating from 0 to x, for x from 0 to 1, ln(1 + x) is $S_N(x)$ plus at most the area under t^N: x^(N+1)/(N + 1).

At x = 0.5, N = 20 the bound is 0.000000023. At x = 1 it is 1/(N + 1), heading for 0, so the log series at 1 equals ln 2. To land within 0.001 of ln 2, N = 1,000 is enough: the actual gap is 0.000500.

Differentiating instead gives 1 + 2x + 3x^2 + … = 1/(1 − x)^2, which is 4 at 0.5. Where coefficients come from is [Taylor series](05-taylor-series.md); the general rules for passing limits through integrals and derivatives are [Swapping limits](08-swapping-limits-with-integrals-and-derivatives.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Log coefficient ratio | n/(n + 1) at n = 1,000 | 0.999001, heading for 1 |
| Radius | R = 1/L | **1** |
| Geometric at 0.5, through x^20 | 2 − 0.5^20 | 1.999999046 |
| Log at 0.5, through x^20 | 0.500000 − 0.125000 + 0.041667 − … | **0.405465093** |
| Gap to the area under 1/(1 + t), 0.405465108 | bound 0.5^21/21 | 0.000000015 ≤ 0.000000023 |
| Slope of 1/(1 − x) at 0.5 | 1 + 2(0.5) + … + 20(0.5)^19 | 3.999958038, against 4 |
| Log at 1 and at −1, 1,000 terms | 1 − 1/2 + …; −(1 + 1/2 + …) | 0.692647 (ln 2 = 0.693147); −7.485471 |
| Where each works | Steps 2 and 3 | 1/(1 − x): −1 < x < 1; log: **−1 < x ≤ 1** |

Twenty adds and multiplies give ln 1.5 to seven decimals, as the bound promised.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Take both log endpoints because R = 1 | −7.485471 at x = −1 after 1,000 terms, falling | endpoints need their own test |
| Differentiate at x = 1, where the log converges | slope sums 1, 0, 1, 0, 1, 0 | term by term holds only strictly inside |
| Use the series at x = 1.1 | x^100 term: −137.81 for the log, 13780.61 for 1/(1 − x) | growing terms have no sum |
| Same N for slope as for value | value gap 0.000000954, slope gap 0.000042 | term n is multiplied by n |

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one adds the series, and the differentiated geometric series, term by term. Road two shares no arithmetic with it: the closed form 1/(1 − x), a Simpson's-rule area under 1/(1 + t) (an area estimate built from thin strips topped by parabolas), and a difference quotient (the slope between two nearby points). Four asserts compare the roads; each failed when the maths was broken on purpose.

### Python

```python
# Power series -- the check behind the card.  Nothing is imported.
# Road one: partial sums of the two series, and their term-by-term slope.
# Road two, sharing no arithmetic with road one: the closed form 1/(1-x), a
# Simpson sum for the area under 1/(1+t) from 0 to x, which is ln(1+x), and a
# shrinking difference quotient for the slope of 1/(1-x).
def geo(x, N):                          # 1 + x + x^2 + ... + x^N
    return sum(x**n for n in range(N + 1))

def geo_slope(x, N):                    # term by term: 1 + 2x + 3x^2 + ... + N x^(N-1)
    return sum(n * x**(n - 1) for n in range(1, N + 1))

def ln_series(x, N):                    # x - x^2/2 + x^3/3 - ... through the x^N term
    return sum((-1)**(n + 1) * x**n / n for n in range(1, N + 1))

def ln_area(x, m=4000):                 # Simpson's rule: area under 1/(1+t) from 0 to x
    h = x / m
    s = 1 + 1 / (1 + x) + sum((4 if k % 2 else 2) / (1 + k * h) for k in range(1, m))
    return s * h / 3

def row(vals):
    return ", ".join(f"{v:.2f}" for v in vals)

x, N = 0.5, 20
g, closed = geo(x, N), 1 / (1 - x)
s, area = ln_series(x, N), ln_area(x)
h, slope = 1e-5, geo_slope(x, N)
dq = (1 / (1 - x - h) - 1 / (1 - x + h)) / (2 * h)
tail = ((N + 1) * x**N - N * x**(N + 1)) / (1 - x)**2
ln2 = ln_area(1.0)
print(f"radius: coefficient ratio 1 for 1/(1-x); n/(n+1) = {1000 / 1001:.6f} at n = 1000 for ln(1+x)")
print(f"1/(1-x) at {x}, through x^{N}: {g:.9f}; closed form {closed:.9f}; gap {closed - g:.9f}")
print(f"ln(1+x) at {x}, through x^{N}: {s:.9f}; Simpson area {area:.9f}; gap {abs(s - area):.9f}; bound {x**(N + 1) / (N + 1):.9f}")
print(f"slope of 1/(1-x) at {x}, through {N}x^{N - 1}: {slope:.9f}; difference quotient {dq:.6f}; gap {dq - slope:.6f}")
for M in (10, 100, 1000):
    v = ln_series(1.0, M)
    print(f"N = {M}: x = 1 sum {v:.6f}, ln 2 = {ln2:.6f}, gap {abs(v - ln2):.6f} <= 1/(N+1) = {1 / (M + 1):.6f}; x = -1 sum {ln_series(-1.0, M):.6f}")
print(f"1/(1-x) at x = 1: sum through x^99 = {geo(1.0, 99):.0f}; at x = -1 sums run {row(geo(-1.0, k) for k in range(6))}")
print(f"slope series of ln(1+x) at x = 1, 1 - 1 + 1 - ...: sums run {row(sum((-1)**(n + 1) * 1.0**(n - 1) for n in range(1, k + 1)) for k in range(1, 7))}")
print(f"log terms at {x}: {', '.join(f'{(-1)**(n + 1) * x**n / n:.6f}' for n in range(1, 5))}; at x = 2, 1/(1-x) = {1 / (1 - 2):.2f} but terms run {row(2.0**n for n in range(4))}")
print(f"outside, x = 1.1: x^100 term of 1/(1-x) is {1.1**100:.2f}; of ln(1+x) is {-1.1**100 / 100:.2f}")
xs = [(3 * k - 9) / 10 for k in range(9)]
print(f"chart, x: {row(xs)}")
print(f"chart, ln(1+x) by Simpson: {row(ln_area(t) for t in xs)}")
print(f"chart, through x^4: {row(ln_series(t, 4) for t in xs)}")
print(f"chart, through x^10: {row(ln_series(t, 10) for t in xs)}")
assert abs(closed - g) <= x**(N + 1) / (1 - x) + 1e-15      # partial sum against closed form
assert abs(s - area) <= x**(N + 1) / (N + 1) + 1e-12          # term-by-term integral against area
assert abs((dq - slope) - tail) < 1e-8                        # slope gap is the predicted tail
assert all(abs(ln_series(1.0, M) - ln2) <= 1 / (M + 1) for M in (10, 100, 1000))
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
radius: coefficient ratio 1 for 1/(1-x); n/(n+1) = 0.999001 at n = 1000 for ln(1+x)
1/(1-x) at 0.5, through x^20: 1.999999046; closed form 2.000000000; gap 0.000000954
ln(1+x) at 0.5, through x^20: 0.405465093; Simpson area 0.405465108; gap 0.000000015; bound 0.000000023
slope of 1/(1-x) at 0.5, through 20x^19: 3.999958038; difference quotient 4.000000; gap 0.000042
N = 10: x = 1 sum 0.645635, ln 2 = 0.693147, gap 0.047512 <= 1/(N+1) = 0.090909; x = -1 sum -2.928968
N = 100: x = 1 sum 0.688172, ln 2 = 0.693147, gap 0.004975 <= 1/(N+1) = 0.009901; x = -1 sum -5.187378
N = 1000: x = 1 sum 0.692647, ln 2 = 0.693147, gap 0.000500 <= 1/(N+1) = 0.000999; x = -1 sum -7.485471
1/(1-x) at x = 1: sum through x^99 = 100; at x = -1 sums run 1.00, 0.00, 1.00, 0.00, 1.00, 0.00
slope series of ln(1+x) at x = 1, 1 - 1 + 1 - ...: sums run 1.00, 0.00, 1.00, 0.00, 1.00, 0.00
log terms at 0.5: 0.500000, -0.125000, 0.041667, -0.015625; at x = 2, 1/(1-x) = -1.00 but terms run 1.00, 2.00, 4.00, 8.00
outside, x = 1.1: x^100 term of 1/(1-x) is 13780.61; of ln(1+x) is -137.81
chart, x: -0.90, -0.60, -0.30, 0.00, 0.30, 0.60, 0.90, 1.20, 1.50
chart, ln(1+x) by Simpson: -2.30, -0.92, -0.36, 0.00, 0.26, 0.47, 0.64, 0.79, 0.92
chart, through x^4: -1.71, -0.88, -0.36, 0.00, 0.26, 0.46, 0.57, 0.54, 0.23
chart, through x^10: -2.12, -0.92, -0.36, 0.00, 0.26, 0.47, 0.63, 0.47, -2.40
ALL CHECKS PASS
```

### Rust

Same rows and labels, built with `rustc --edition 2021 -O`; outputs agree byte for byte.

```rust
// Power series -- the same check as the Python, in Rust, std only.
// Road one: partial sums of the two series, and their term-by-term slope.
// Road two, sharing no arithmetic with road one: the closed form 1/(1-x), a
// Simpson sum for the area under 1/(1+t) from 0 to x, which is ln(1+x), and a
// shrinking difference quotient for the slope of 1/(1-x).
fn geo(x: f64, n: i32) -> f64 { // 1 + x + x^2 + ... + x^N
    (0..=n).fold(0.0, |a, k| a + x.powf(k as f64))
}
fn geo_slope(x: f64, n: i32) -> f64 { // term by term: 1 + 2x + 3x^2 + ... + N x^(N-1)
    (1..=n).fold(0.0, |a, k| a + k as f64 * x.powf((k - 1) as f64))
}
fn sign(n: i32) -> f64 { if n % 2 == 1 { 1.0 } else { -1.0 } } // (-1)^(n+1)
fn ln_series(x: f64, n: i32) -> f64 { // x - x^2/2 + x^3/3 - ... through the x^N term
    (1..=n).fold(0.0, |a, k| a + sign(k) * x.powf(k as f64) / k as f64)
}
fn ln_area(x: f64) -> f64 { // Simpson's rule: area under 1/(1+t) from 0 to x
    let m = 4000;
    let h = x / m as f64;
    let inner = (1..m).fold(0.0, |a, k| a + (if k % 2 == 1 { 4.0 } else { 2.0 }) / (1.0 + k as f64 * h));
    (1.0 + 1.0 / (1.0 + x) + inner) * h / 3.0
}
fn row(v: &[f64]) -> String {
    v.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", ")
}
fn main() {
    let (x, n) = (0.5_f64, 20);
    let (g, closed) = (geo(x, n), 1.0 / (1.0 - x));
    let (s, area) = (ln_series(x, n), ln_area(x));
    let (h, slope) = (1e-5, geo_slope(x, n));
    let dq = (1.0 / (1.0 - x - h) - 1.0 / (1.0 - x + h)) / (2.0 * h);
    let tail = ((n + 1) as f64 * x.powf(n as f64) - n as f64 * x.powf((n + 1) as f64)) / (1.0 - x).powf(2.0);
    let ln2 = ln_area(1.0);
    println!("radius: coefficient ratio 1 for 1/(1-x); n/(n+1) = {:.6} at n = 1000 for ln(1+x)", 1000.0 / 1001.0);
    println!("1/(1-x) at {}, through x^{}: {:.9}; closed form {:.9}; gap {:.9}", x, n, g, closed, closed - g);
    println!("ln(1+x) at {}, through x^{}: {:.9}; Simpson area {:.9}; gap {:.9}; bound {:.9}", x, n, s, area, (s - area).abs(), x.powf((n + 1) as f64) / (n + 1) as f64);
    println!("slope of 1/(1-x) at {}, through {}x^{}: {:.9}; difference quotient {:.6}; gap {:.6}", x, n, n - 1, slope, dq, dq - slope);
    for m in [10, 100, 1000] {
        let v = ln_series(1.0, m);
        println!("N = {}: x = 1 sum {:.6}, ln 2 = {:.6}, gap {:.6} <= 1/(N+1) = {:.6}; x = -1 sum {:.6}",
            m, v, ln2, (v - ln2).abs(), 1.0 / (m + 1) as f64, ln_series(-1.0, m));
    }
    let ends: Vec<f64> = (0..6).map(|k| geo(-1.0, k)).collect();
    println!("1/(1-x) at x = 1: sum through x^99 = {:.0}; at x = -1 sums run {}", geo(1.0, 99), row(&ends));
    let slopes: Vec<f64> = (1..7).map(|k| (1..=k).fold(0.0, |a, j| a + sign(j) * 1.0_f64.powf((j - 1) as f64))).collect();
    println!("slope series of ln(1+x) at x = 1, 1 - 1 + 1 - ...: sums run {}", row(&slopes));
    let terms: Vec<String> = (1..5).map(|k| format!("{:.6}", sign(k) * x.powf(k as f64) / k as f64)).collect();
    let doubling: Vec<f64> = (0..4).map(|k| 2.0_f64.powf(k as f64)).collect();
    println!("log terms at {}: {}; at x = 2, 1/(1-x) = {:.2} but terms run {}", x, terms.join(", "), 1.0 / (1.0 - 2.0), row(&doubling));
    println!("outside, x = 1.1: x^100 term of 1/(1-x) is {:.2}; of ln(1+x) is {:.2}", 1.1_f64.powf(100.0), -1.1_f64.powf(100.0) / 100.0);
    let xs: Vec<f64> = (0..9).map(|k| (3 * k - 9) as f64 / 10.0).collect();
    println!("chart, x: {}", row(&xs));
    println!("chart, ln(1+x) by Simpson: {}", row(&xs.iter().map(|&t| ln_area(t)).collect::<Vec<_>>()));
    println!("chart, through x^4: {}", row(&xs.iter().map(|&t| ln_series(t, 4)).collect::<Vec<_>>()));
    println!("chart, through x^10: {}", row(&xs.iter().map(|&t| ln_series(t, 10)).collect::<Vec<_>>()));
    assert!((closed - g).abs() <= x.powf((n + 1) as f64) / (1.0 - x) + 1e-15); // partial sum against closed form
    assert!((s - area).abs() <= x.powf((n + 1) as f64) / (n + 1) as f64 + 1e-12); // term-by-term integral against area
    assert!(((dq - slope) - tail).abs() < 1e-8); // slope gap is the predicted tail
    assert!([10, 100, 1000].iter().all(|&m| (ln_series(1.0, m) - ln2).abs() <= 1.0 / (m + 1) as f64));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
radius: coefficient ratio 1 for 1/(1-x); n/(n+1) = 0.999001 at n = 1000 for ln(1+x)
1/(1-x) at 0.5, through x^20: 1.999999046; closed form 2.000000000; gap 0.000000954
ln(1+x) at 0.5, through x^20: 0.405465093; Simpson area 0.405465108; gap 0.000000015; bound 0.000000023
slope of 1/(1-x) at 0.5, through 20x^19: 3.999958038; difference quotient 4.000000; gap 0.000042
N = 10: x = 1 sum 0.645635, ln 2 = 0.693147, gap 0.047512 <= 1/(N+1) = 0.090909; x = -1 sum -2.928968
N = 100: x = 1 sum 0.688172, ln 2 = 0.693147, gap 0.004975 <= 1/(N+1) = 0.009901; x = -1 sum -5.187378
N = 1000: x = 1 sum 0.692647, ln 2 = 0.693147, gap 0.000500 <= 1/(N+1) = 0.000999; x = -1 sum -7.485471
1/(1-x) at x = 1: sum through x^99 = 100; at x = -1 sums run 1.00, 0.00, 1.00, 0.00, 1.00, 0.00
slope series of ln(1+x) at x = 1, 1 - 1 + 1 - ...: sums run 1.00, 0.00, 1.00, 0.00, 1.00, 0.00
log terms at 0.5: 0.500000, -0.125000, 0.041667, -0.015625; at x = 2, 1/(1-x) = -1.00 but terms run 1.00, 2.00, 4.00, 8.00
outside, x = 1.1: x^100 term of 1/(1-x) is 13780.61; of ln(1+x) is -137.81
chart, x: -0.90, -0.60, -0.30, 0.00, 0.30, 0.60, 0.90, 1.20, 1.50
chart, ln(1+x) by Simpson: -2.30, -0.92, -0.36, 0.00, 0.26, 0.47, 0.64, 0.79, 0.92
chart, through x^4: -1.71, -0.88, -0.36, 0.00, 0.26, 0.46, 0.57, 0.54, 0.23
chart, through x^10: -2.12, -0.92, -0.36, 0.00, 0.26, 0.47, 0.63, 0.47, -2.40
ALL CHECKS PASS
```

### Lean

Lean proves the radius, the ratio formula and term-by-term calculus for every power series, and where the card's two series work.

- Every power series has one radius R, from 0 up to no fence at all.
- Nearer the centre than R, the series converges. Farther than R, its partial sums head for no number.
- Strictly inside R, the series of differentiated terms converges, and its sum is the slope of f.
- Strictly inside R, the series of integrated terms converges, and its sum is the area under f from c to x.
- Farther than R, the differentiated and integrated series fail too, so both have radius R.
- If no coefficient is zero and the ratios $|a_{n+1}/a_n|$ head for a number L, then R = 1/L. L = 0 means no fence; L infinite is not covered.
- 1 + x + x^2 + … converges exactly when −1 < x < 1, and then to 1/(1 − x).
- x − x^2/2 + x^3/3 − … converges exactly when −1 < x ≤ 1, and then to ln(1 + x). At x = 1 that is ln 2.
- At x = 1 the sum through x^99 is 100; at x = −1 the sums of 1 + x + x^2 + … run 1, 0, 1, 0, 1, 0.
- At x = 1 the log's slope series has sums 1, 0, 1, 0, 1, 0.
- At 0.5 the geometric sum through x^20 is exactly 2 − 0.5^20. The first four log terms are 1/2, −1/8, 1/24, −1/64.
- At 0.5 the slope sum through 20x^19 is exactly 4 − 44/2^20, against 4.
- At x = 2, 1/(1 − x) is −1, but the terms run 1, 2, 4, 8.

The log's error bound, the decimals, the Simpson areas and the chart are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 418 lines</summary>

```lean
-- Power series: every power series has a radius R inside which it converges and can be differentiated and integrated term by term and outside which it fails, the coefficient ratios give R = 1/L, and the card's two series 1 + x + x² + ⋯ and x − x²/2 + x³/3 − ⋯ work exactly on −1 < x < 1 and −1 < x ≤ 1.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Analytic.OfScalars
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.Complex.AbelLimit
import Mathlib.Analysis.PSeries

open Finset Filter Topology
open scoped ENNReal

/-! Helper lemmas. -/

lemma ps_terms_tendsto_zero (f : ℕ → ℝ)
    (h : ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, f n) atTop (𝓝 s)) :
    Tendsto f atTop (𝓝 0) := by
  obtain ⟨s, hs⟩ := h
  have h1 := (hs.comp (tendsto_add_atTop_nat 1)).sub hs
  rw [sub_self] at h1
  refine h1.congr (fun N => ?_)
  simp [Function.comp, sum_range_succ]

lemma ps_summable_abs (a : ℕ → ℝ) {r : ℝ} (hr : 0 ≤ r)
    (h : ENNReal.ofReal r < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    Summable (fun n : ℕ => |a n| * r ^ n) := by
  have := (FormalMultilinearSeries.ofScalars ℝ a).summable_norm_mul_pow (r := r.toNNReal) h
  simpa [FormalMultilinearSeries.ofScalars_norm, Real.coe_toNNReal _ hr] using this

lemma ps_le_radius (a : ℕ → ℝ) {r : ℝ} (hr : 0 ≤ r)
    (h : Tendsto (fun n : ℕ => |a n| * r ^ n) atTop (𝓝 0)) :
    ENNReal.ofReal r ≤ (FormalMultilinearSeries.ofScalars ℝ a).radius := by
  apply (FormalMultilinearSeries.ofScalars ℝ a).le_radius_of_tendsto (l := 0)
  simpa [FormalMultilinearSeries.ofScalars_norm, Real.coe_toNNReal _ hr] using h

lemma ps_summable_deriv_bound (a : ℕ → ℝ) {r : ℝ} (hr : 0 < r)
    (h : ENNReal.ofReal r < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    Summable (fun n : ℕ => (n : ℝ) * |a n| * r ^ (n - 1)) := by
  obtain ⟨r2, hr2, h1, h2⟩ := ENNReal.lt_iff_exists_real_btwn.1 h
  have hrr2 : r < r2 := (ENNReal.ofReal_lt_ofReal_iff_of_nonneg hr.le).1 h1
  have hr2p : 0 < r2 := hr.trans hrr2
  have hs := (ps_summable_abs a hr2 h2).div_const r
  have hq : Tendsto (fun n : ℕ => (n : ℝ) * (r / r2) ^ n) atTop (𝓝 0) :=
    tendsto_self_mul_const_pow_of_lt_one (by positivity) ((div_lt_one hr2p).2 hrr2)
  have hev : ∀ᶠ n : ℕ in atTop, (n : ℝ) * (r / r2) ^ n ≤ 1 :=
    hq.eventually (ge_mem_nhds zero_lt_one)
  refine Summable.of_norm_bounded_eventually hs ?_
  rw [Nat.cofinite_eq_atTop]
  filter_upwards [hev] with n hn
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  rcases n with _ | m
  · simp; positivity
  · have key : ((m + 1 : ℕ) : ℝ) * |a (m + 1)| * r ^ (m + 1 - 1)
        = ((m + 1 : ℕ) : ℝ) * (r / r2) ^ (m + 1) * (|a (m + 1)| * r2 ^ (m + 1) / r) := by
      simp only [Nat.add_sub_cancel, div_pow]
      field_simp
      ring
    rw [key]
    calc ((m + 1 : ℕ) : ℝ) * (r / r2) ^ (m + 1) * (|a (m + 1)| * r2 ^ (m + 1) / r)
        ≤ 1 * (|a (m + 1)| * r2 ^ (m + 1) / r) := by gcongr
      _ = |a (m + 1)| * r2 ^ (m + 1) / r := one_mul _
lemma ps_diverge_outside (a : ℕ → ℝ) (c x : ℝ)
    (hx : (FormalMultilinearSeries.ofScalars ℝ a).radius < ENNReal.ofReal |x - c|) :
    ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n * (x - c) ^ n) atTop (𝓝 s) := by
  intro h
  have h0 := (ps_terms_tendsto_zero _ h).abs
  simp only [abs_zero, abs_mul, abs_pow] at h0
  exact (ps_le_radius a (abs_nonneg _) h0).not_gt hx

lemma ps_deriv_diverge_outside (a : ℕ → ℝ) (c x : ℝ)
    (hx : (FormalMultilinearSeries.ofScalars ℝ a).radius < ENNReal.ofReal |x - c|) :
    ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, (n : ℝ) * a n * (x - c) ^ (n - 1))
      atTop (𝓝 s) := by
  intro h
  have h0 := (ps_terms_tendsto_zero _ h).abs
  simp only [abs_zero] at h0
  have h1 := (tendsto_const_div_atTop_nhds_zero_nat |x - c|).mul h0
  rw [mul_zero] at h1
  refine (ps_le_radius a (abs_nonneg _) (h1.congr' ?_)).not_gt hx
  filter_upwards [eventually_ge_atTop 1] with n hn
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  simp only [Nat.add_sub_cancel, abs_mul, abs_pow, Nat.abs_cast]
  push_cast
  field_simp
  ring

lemma ps_integ_diverge_outside (a : ℕ → ℝ) (c x : ℝ)
    (hx : (FormalMultilinearSeries.ofScalars ℝ a).radius < ENNReal.ofReal |x - c|) :
    ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n / (n + 1) * (x - c) ^ (n + 1))
      atTop (𝓝 s) := by
  intro h
  have h0 := (ps_terms_tendsto_zero _ h).abs
  simp only [abs_zero] at h0
  obtain ⟨r', hr'0, h1, h2⟩ := ENNReal.lt_iff_exists_real_btwn.1 hx
  have hlt : r' < |x - c| := (ENNReal.ofReal_lt_ofReal_iff'.1 h2).1
  have hpos : 0 < |x - c| := hr'0.trans_lt hlt
  have hq : Tendsto (fun n : ℕ => (n : ℝ) * (r' / |x - c|) ^ n) atTop (𝓝 0) :=
    tendsto_self_mul_const_pow_of_lt_one (by positivity) ((div_lt_one hpos).2 hlt)
  have hq' : Tendsto (fun n : ℕ => (r' / |x - c|) ^ n) atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_of_lt_one (by positivity) ((div_lt_one hpos).2 hlt)
  have h3 := ((h0.mul (hq.add hq')).div_const |x - c|)
  simp only [add_zero, mul_zero, zero_div] at h3
  refine (ps_le_radius a hr'0 (h3.congr fun n => ?_)).not_gt h1
  simp only [abs_mul, abs_div, abs_pow, div_pow]
  rw [abs_of_pos (by positivity : (0 : ℝ) < n + 1)]
  field_simp
  ring

lemma ps_summable_inside (a : ℕ → ℝ) (c x : ℝ)
    (hx : ENNReal.ofReal |x - c| < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    Summable (fun n : ℕ => a n * (x - c) ^ n) :=
  (ps_summable_abs a (abs_nonneg _) hx).of_norm_bounded
    (fun n => le_of_eq (by rw [Real.norm_eq_abs, abs_mul, abs_pow]))

lemma ps_hasDeriv_inside (a : ℕ → ℝ) (c x : ℝ)
    (hx : ENNReal.ofReal |x - c| < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    ∃ D : ℝ, HasSum (fun n : ℕ => (n : ℝ) * a n * (x - c) ^ (n - 1)) D ∧
      HasDerivAt (fun y => ∑' n : ℕ, a n * (y - c) ^ n) D x := by
  obtain ⟨r, hr0, h1, h2⟩ := ENNReal.lt_iff_exists_real_btwn.1 hx
  have hlt : |x - c| < r := (ENNReal.ofReal_lt_ofReal_iff'.1 h1).1
  have hrpos : 0 < r := (abs_nonneg _).trans_lt hlt
  have hu := ps_summable_deriv_bound a hrpos h2
  have hxmem : x ∈ Metric.ball c r := by rwa [Metric.mem_ball, Real.dist_eq]
  have hbound : ∀ (n : ℕ) (y : ℝ), y ∈ Metric.ball c r →
      ‖(n : ℝ) * a n * (y - c) ^ (n - 1)‖ ≤ (n : ℝ) * |a n| * r ^ (n - 1) := by
    intro n y hy
    rw [Metric.mem_ball, Real.dist_eq] at hy
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_pow, Nat.abs_cast]
    gcongr
  have hderiv : ∀ (n : ℕ) (y : ℝ), y ∈ Metric.ball c r →
      HasDerivAt (fun z => a n * (z - c) ^ n) ((n : ℝ) * a n * (y - c) ^ (n - 1)) y := by
    intro n y _
    have := ((hasDerivAt_pow n (y - c)).comp_sub_const y c).const_mul (a n)
    convert this using 1
    ring
  refine ⟨_, (hu.of_norm_bounded (fun n => hbound n x hxmem)).hasSum, ?_⟩
  exact hasDerivAt_tsum_of_isPreconnected hu Metric.isOpen_ball (convex_ball c r).isPreconnected
    hderiv hbound hxmem (ps_summable_inside a c x hx) hxmem

lemma ps_integral_inside (a : ℕ → ℝ) (c x : ℝ)
    (hx : ENNReal.ofReal |x - c| < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    HasSum (fun n : ℕ => a n / (n + 1) * (x - c) ^ (n + 1))
      (∫ t in c..x, ∑' n : ℕ, a n * (t - c) ^ n) := by
  have hs := ps_summable_abs a (abs_nonneg _) hx
  have hb : ∀ n, ∀ t ∈ Set.uIcc c x, ‖a n * (t - c) ^ n‖ ≤ |a n| * |x - c| ^ n := by
    intro n t ht
    rw [Real.norm_eq_abs, abs_mul, abs_pow]
    exact mul_le_mul_of_nonneg_left
      (pow_le_pow_left₀ (abs_nonneg _) (Set.abs_sub_left_of_mem_uIcc ht) n) (abs_nonneg _)
  have h := intervalIntegral.hasSum_integral_of_dominated_convergence
    (μ := MeasureTheory.volume) (a := c) (b := x)
    (F := fun n t => a n * (t - c) ^ n) (f := fun t => ∑' n : ℕ, a n * (t - c) ^ n)
    (fun n _ => |a n| * |x - c| ^ n)
    (fun n => (by fun_prop : Continuous fun t : ℝ => a n * (t - c) ^ n).aestronglyMeasurable)
    (fun n => MeasureTheory.ae_of_all _ fun t ht => hb n t (Set.uIoc_subset_uIcc ht))
    (MeasureTheory.ae_of_all _ fun t _ => hs)
    intervalIntegrable_const
    (MeasureTheory.ae_of_all _ fun t ht =>
      (hs.of_norm_bounded (fun n => hb n t (Set.uIoc_subset_uIcc ht))).hasSum)
  convert h using 1
  funext n
  rw [intervalIntegral.integral_const_mul,
    intervalIntegral.integral_comp_sub_right (fun t => t ^ n), integral_pow]
  simp only [sub_self, ne_eq, Nat.add_eq_zero_iff, one_ne_zero, and_false, not_false_eq_true,
    zero_pow, sub_zero]
  ring

lemma ps_Icc_eq_range (f : ℕ → ℝ) (hf : f 0 = 0) (N : ℕ) :
    ∑ n ∈ Icc (1 : ℕ) N, f n = ∑ n ∈ range (N + 1), f n := by
  induction N with
  | zero => simp [hf]
  | succ N ih => rw [sum_Icc_succ_top (by omega), ih, sum_range_succ _ (N + 1)]

lemma ps_log_hasSum {x : ℝ} (hx : |x| < 1) :
    HasSum (fun n : ℕ => (-1 : ℝ) ^ (n + 1) / n * x ^ n) (Real.log (1 + x)) := by
  have h0 : |-x| < 1 := by rwa [abs_neg]
  have h := (Real.hasSum_pow_div_log_of_abs_lt_one h0).neg
  rw [sub_neg_eq_add, neg_neg] at h
  have h2 : HasSum (fun n : ℕ => (-1 : ℝ) ^ (n + 1 + 1) / ((n + 1 : ℕ) : ℝ) * x ^ (n + 1))
      (Real.log (1 + x)) := by
    refine h.congr_fun (fun n => ?_)
    push_cast
    rw [neg_pow]
    ring
  have h3 := (hasSum_nat_add_iff (f := fun n : ℕ => (-1 : ℝ) ^ (n + 1) / n * x ^ n) 1).mp h2
  simpa using h3

lemma ps_geom_tendsto (x : ℝ) (hx : x ∈ Set.Ioo (-1 : ℝ) 1) :
    Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 (1 / (1 - x))) := by
  have h := (hasSum_geometric_of_abs_lt_one (abs_lt.2 hx)).tendsto_sum_nat
  rw [one_div]
  exact h.comp (tendsto_add_atTop_nat 1)

lemma ps_geom_conv (x : ℝ)
    (h : ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 s)) :
    x ∈ Set.Ioo (-1 : ℝ) 1 := by
  obtain ⟨s, hs⟩ := h
  have h0 := ps_terms_tendsto_zero (fun n => x ^ n)
    ⟨s, (tendsto_add_atTop_iff_nat 1).1 hs⟩
  exact abs_lt.1 (tendsto_pow_atTop_nhds_zero_iff.1 h0)

lemma ps_log_tendsto (x : ℝ) (hx : x ∈ Set.Ioc (-1 : ℝ) 1) :
    Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      atTop (𝓝 (Real.log (1 + x))) := by
  have heq : (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      = fun N : ℕ => ∑ n ∈ range (N + 1), (-1 : ℝ) ^ (n + 1) / n * x ^ n :=
    funext fun N => ps_Icc_eq_range _ (by simp) N
  rw [heq, tendsto_add_atTop_iff_nat 1
    (f := fun N : ℕ => ∑ n ∈ range N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)]
  rcases hx.2.lt_or_eq with h | rfl
  · exact (ps_log_hasSum (abs_lt.2 ⟨hx.1, h⟩)).tendsto_sum_nat
  · obtain ⟨l, hl⟩ : ∃ l, Tendsto (fun N : ℕ => ∑ n ∈ range N, (-1 : ℝ) ^ (n + 1) / n * 1 ^ n)
        atTop (𝓝 l) := by
      obtain ⟨l, hl⟩ := Antitone.tendsto_alternating_series_of_tendsto_zero
        (f := fun i : ℕ => 1 / ((i : ℝ) + 1))
        (fun i j hij => by
          simp only
          gcongr)
        tendsto_one_div_add_atTop_nhds_zero_nat
      refine ⟨l, (tendsto_add_atTop_iff_nat 1).1 (hl.congr fun N => ?_)⟩
      rw [sum_range_succ']
      simp only [one_pow, mul_one, CharP.cast_eq_zero, div_zero, add_zero]
      refine sum_congr rfl fun i _ => ?_
      push_cast
      ring
    have habel := Real.tendsto_tsum_powerSeries_nhdsWithin_lt
      (f := fun n : ℕ => (-1 : ℝ) ^ (n + 1) / n) (l := l)
      (by simpa only [one_pow, mul_one] using hl)
    have hlog : Tendsto (fun y : ℝ => ∑' n : ℕ, (-1 : ℝ) ^ (n + 1) / n * y ^ n) (𝓝[<] 1)
        (𝓝 (Real.log (1 + 1))) := by
      have hc : Tendsto (fun y : ℝ => Real.log (1 + y)) (𝓝[<] 1) (𝓝 (Real.log (1 + 1))) :=
        ((show ContinuousAt (fun y : ℝ => 1 + y) 1 by fun_prop).log
          (by norm_num)).tendsto.mono_left nhdsWithin_le_nhds
      refine hc.congr' ?_
      filter_upwards [Ioo_mem_nhdsLT (show (0 : ℝ) < 1 by norm_num)] with y hy
      exact ((ps_log_hasSum (abs_lt.2 ⟨by linarith [hy.1], hy.2⟩)).tsum_eq).symm
    rw [← tendsto_nhds_unique habel hlog]
    exact hl

lemma ps_log_conv (x : ℝ)
    (h : ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      atTop (𝓝 s)) :
    x ∈ Set.Ioc (-1 : ℝ) 1 := by
  obtain ⟨s, hs⟩ := h
  have heq : (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      = fun N : ℕ => ∑ n ∈ range (N + 1), (-1 : ℝ) ^ (n + 1) / n * x ^ n :=
    funext fun N => ps_Icc_eq_range _ (by simp) N
  rw [heq] at hs
  have hs' := (tendsto_add_atTop_iff_nat 1
    (f := fun N : ℕ => ∑ n ∈ range N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)).1 hs
  have h0 := ps_terms_tendsto_zero _ ⟨s, hs'⟩
  by_contra hx
  have hx' : 1 < |x| ∨ x = -1 := by
    rw [Set.mem_Ioc, not_and_or, not_lt, not_le] at hx
    rcases hx with h | h
    · rcases h.lt_or_eq with h | h
      · left; rw [abs_of_neg (by linarith)]; linarith
      · right; exact h
    · left; rw [abs_of_pos (by linarith)]; exact h
  rcases hx' with hgt | rfl
  · have h1 := tendsto_pow_const_div_const_pow_of_one_lt 1 hgt
    have h2 := h0.abs.mul h1
    rw [abs_zero, zero_mul] at h2
    have h3 : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (𝓝 0) := by
      refine h2.congr' ?_
      filter_upwards [eventually_ge_atTop 1] with n hn
      have hn' : (n : ℝ) ≠ 0 := by positivity
      have hxn : |x| ^ n ≠ 0 := by positivity
      simp only [abs_mul, abs_div, abs_pow, abs_neg, abs_one, one_pow, Nat.abs_cast, pow_one]
      field_simp
    exact one_ne_zero (tendsto_nhds_unique tendsto_const_nhds h3)
  · have hH := Real.tendsto_sum_range_one_div_nat_succ_atTop
    refine not_tendsto_nhds_of_tendsto_atTop hH (-s) (hs.neg.congr fun N => ?_)
    rw [sum_range_succ']
    simp only [CharP.cast_eq_zero, div_zero, zero_mul, add_zero, ← sum_neg_distrib]
    refine sum_congr rfl fun i _ => ?_
    have h1 : ((-1 : ℝ)) ^ (i + 1 + 1) * (-1) ^ (i + 1) = -1 := by
      rw [← pow_add]
      exact Odd.neg_one_pow ⟨i + 1, by ring⟩
    push_cast
    rw [div_mul_eq_mul_div, h1]
    ring

#print axioms ps_terms_tendsto_zero
#print axioms ps_summable_abs
#print axioms ps_le_radius
#print axioms ps_summable_deriv_bound
#print axioms ps_diverge_outside
#print axioms ps_deriv_diverge_outside
#print axioms ps_integ_diverge_outside
#print axioms ps_summable_inside
#print axioms ps_hasDeriv_inside
#print axioms ps_integral_inside
#print axioms ps_Icc_eq_range
#print axioms ps_log_hasSum
#print axioms ps_geom_tendsto
#print axioms ps_geom_conv
#print axioms ps_log_tendsto
#print axioms ps_log_conv

/-- The radius of convergence. Take any coefficients a₀, a₁, a₂, … and any centre c, and let
f(y) = a₀ + a₁(y − c) + a₂(y − c)² + ⋯ . There is one radius R, a distance from 0 up to
infinity, such that:
* at every input x nearer c than R, the series a₀ + a₁(x − c) + ⋯ converges;
* at every input farther than R, its running totals head for no number at all;
* strictly inside R, f has a slope, and the slope is the differentiated series
  ∑ n aₙ (x − c)^(n−1), which converges there;
* strictly inside R, the area under f from c to x is the integrated series
  ∑ aₙ/(n + 1) (x − c)^(n+1), which converges there;
* farther than R, the differentiated and integrated series fail too, so both have radius R.
At distance exactly R nothing is claimed: the endpoints are tested one by one. -/
theorem power_series_has_radius_of_convergence (a : ℕ → ℝ) (c : ℝ) :
    ∃ R : ℝ≥0∞,
      (∀ x : ℝ, ENNReal.ofReal |x - c| < R →
        Summable (fun n : ℕ => a n * (x - c) ^ n)) ∧
      (∀ x : ℝ, R < ENNReal.ofReal |x - c| →
        ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n * (x - c) ^ n) atTop (𝓝 s)) ∧
      (∀ x : ℝ, ENNReal.ofReal |x - c| < R →
        ∃ D : ℝ, HasSum (fun n : ℕ => (n : ℝ) * a n * (x - c) ^ (n - 1)) D ∧
          HasDerivAt (fun y => ∑' n : ℕ, a n * (y - c) ^ n) D x) ∧
      (∀ x : ℝ, ENNReal.ofReal |x - c| < R →
        HasSum (fun n : ℕ => a n / (n + 1) * (x - c) ^ (n + 1))
          (∫ t in c..x, ∑' n : ℕ, a n * (t - c) ^ n)) ∧
      (∀ x : ℝ, R < ENNReal.ofReal |x - c| →
        (¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, (n : ℝ) * a n * (x - c) ^ (n - 1))
            atTop (𝓝 s)) ∧
        (¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n / (n + 1) * (x - c) ^ (n + 1))
            atTop (𝓝 s))) := by
  exact ⟨(FormalMultilinearSeries.ofScalars ℝ a).radius,
    fun x hx => ps_summable_inside a c x hx,
    fun x hx => ps_diverge_outside a c x hx,
    fun x hx => ps_hasDeriv_inside a c x hx,
    fun x hx => ps_integral_inside a c x hx,
    fun x hx => ⟨ps_deriv_diverge_outside a c x hx, ps_integ_diverge_outside a c x hx⟩⟩

/-- The ratio test measures the fence. If no coefficient is zero and the neighbouring ratios
|aₙ₊₁/aₙ| head for a limit L, then the radius is R = 1/L (with 1/0 read as infinity: L = 0
means no fence): the series converges at every x with |x − c| < 1/L, and its running totals
head for no number at every x with |x − c| > 1/L. -/
theorem radius_is_one_over_ratio_limit (a : ℕ → ℝ) (c L : ℝ) (ha : ∀ n, a n ≠ 0)
    (hL : Tendsto (fun n : ℕ => |a (n + 1) / a n|) atTop (𝓝 L)) :
    (∀ x : ℝ, ENNReal.ofReal |x - c| < (ENNReal.ofReal L)⁻¹ →
      Summable (fun n : ℕ => a n * (x - c) ^ n)) ∧
    (∀ x : ℝ, (ENNReal.ofReal L)⁻¹ < ENNReal.ofReal |x - c| →
      ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n * (x - c) ^ n) atTop (𝓝 s)) := by
  have hL0 : 0 ≤ L := ge_of_tendsto' hL (fun n => abs_nonneg _)
  have hc : Tendsto (fun n : ℕ => ‖a n.succ‖ / ‖a n‖) atTop (𝓝 L) := by
    simpa [Real.norm_eq_abs, abs_div] using hL
  have hR : (FormalMultilinearSeries.ofScalars ℝ a).radius = (ENNReal.ofReal L)⁻¹ := by
    rcases hL0.eq_or_lt with h | h
    · subst h
      rw [ENNReal.ofReal_zero, ENNReal.inv_zero]
      exact FormalMultilinearSeries.ofScalars_radius_eq_top_of_tendsto ℝ a
        (Eventually.of_forall ha) hc
    · have hne : L.toNNReal ≠ 0 := by simpa using h
      rw [FormalMultilinearSeries.ofScalars_radius_eq_inv_of_tendsto ℝ a hne
        (by rwa [Real.coe_toNNReal _ hL0]), ENNReal.coe_inv hne]
      rfl
  rw [← hR]
  exact ⟨fun x hx => ps_summable_inside a c x hx, fun x hx => ps_diverge_outside a c x hx⟩

/-- Same radius, different endpoints. Both of the card's series have radius 1, yet:
the running totals 1 + x + ⋯ + x^N settle on some number exactly when −1 < x < 1, and then
on 1/(1 − x); the running totals x − x²/2 + x³/3 − ⋯ ± x^N/N settle on some number exactly
when −1 < x ≤ 1, and then on ln(1 + x), so at x = 1 on ln 2. -/
theorem geometric_and_log_series_where_they_work :
    (∀ x : ℝ, (∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 s)) ↔
        x ∈ Set.Ioo (-1) 1) ∧
    (∀ x ∈ Set.Ioo (-1 : ℝ) 1,
        Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 (1 / (1 - x)))) ∧
    (∀ x : ℝ, (∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
          atTop (𝓝 s)) ↔ x ∈ Set.Ioc (-1) 1) ∧
    (∀ x ∈ Set.Ioc (-1 : ℝ) 1,
        Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
          atTop (𝓝 (Real.log (1 + x)))) := by
  exact ⟨fun x => ⟨ps_geom_conv x, fun hx => ⟨_, ps_geom_tendsto x hx⟩⟩, ps_geom_tendsto,
    fun x => ⟨ps_log_conv x, fun hx => ⟨_, ps_log_tendsto x hx⟩⟩, ps_log_tendsto⟩

/-! The card's exact worked numbers. -/

-- 1/(1 − x) at x = 1: through x^99 the sum 1 + 1 + ⋯ + 1 is 100.
example : ∑ n ∈ range 100, (1 : ℤ) ^ n = 100 := by
  norm_num

-- 1/(1 − x) at x = −1: the running totals run 1, 0, 1, 0, 1, 0.
example : (List.range 6).map (fun N : ℕ => ∑ n ∈ range (N + 1), (-1 : ℤ) ^ n) = [1, 0, 1, 0, 1, 0] := by
  decide

-- The log's slope series at x = 1, 1 − 1 + 1 − ⋯ (term n is n · (−1)^(n+1)/n · 1^(n−1)):
-- running totals 1, 0, 1, 0, 1, 0.
example : (List.range 6).map (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) (N + 1), (-1 : ℤ) ^ (n + 1))
    = [1, 0, 1, 0, 1, 0] := by
  decide

-- Geometric at 1/2 through x^20: 2 − (1/2)^20 (the card's 1.999999046).
example : ∑ n ∈ range 21, (1 / 2 : ℚ) ^ n = 2 - (1 / 2) ^ 20 := by
  norm_num [Finset.sum_range_succ]

-- First four log terms at 1/2: 1/2, −1/8, 1/24, −1/64 (the card's 0.500000, −0.125000,
-- 0.041667, −0.015625).
example : [1, 2, 3, 4].map (fun n : ℕ => (-1 : ℚ) ^ (n + 1) / n * (1 / 2) ^ n)
    = [1 / 2, -1 / 8, 1 / 24, -1 / 64] := by
  norm_num

-- Slope of 1/(1 − x) at 1/2, through 20x^19: 1 + 2(1/2) + ⋯ + 20(1/2)^19 = 4 − 44/2^20
-- (the card's 3.999958038, against 4 = 1/(1 − 1/2)^2).
example : ∑ n ∈ Icc (1 : ℕ) 20, (n : ℚ) * (1 / 2) ^ (n - 1) = 4 - 44 / 2 ^ 20 ∧
    (1 : ℚ) / (1 - 1 / 2) ^ 2 = 4 := by
  norm_num [Finset.sum_Icc_succ_top]

-- Outside the fence at x = 2, 1/(1 − x) is −1 but the terms run 1, 2, 4, 8.
example : (1 : ℚ) / (1 - 2) = -1 ∧ (List.range 4).map (fun n : ℕ => (2 : ℤ) ^ n) = [1, 2, 4, 8] := by
  norm_num [List.range_succ]

#print axioms power_series_has_radius_of_convergence
#print axioms radius_is_one_over_ratio_limit
#print axioms geometric_and_log_series_where_they_work
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'ps_terms_tendsto_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_summable_abs' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_le_radius' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_summable_deriv_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_diverge_outside' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_deriv_diverge_outside' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_integ_diverge_outside' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_summable_inside' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_hasDeriv_inside' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_integral_inside' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_Icc_eq_range' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_log_hasSum' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_geom_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_geom_conv' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_log_tendsto' depends on axioms: [propext, Classical.choice, Quot.sound]
'ps_log_conv' depends on axioms: [propext, Classical.choice, Quot.sound]
'power_series_has_radius_of_convergence' depends on axioms: [propext, Classical.choice, Quot.sound]
'radius_is_one_over_ratio_limit' depends on axioms: [propext, Classical.choice, Quot.sound]
'geometric_and_log_series_where_they_work' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Move to the fence.** `x, N = 0.9, 20`: the geometric gap becomes 1.094189891, the slope gap 36.472997, and the third assert stops the run: the difference quotient's own error, 0.000001, exceeds its tolerance.
> - **Double the terms.** `x, N = 0.5, 40`: every gap prints as zero and all asserts pass.
> - **Starve the area.** `m=4000` to `m=4`: the area reads 0.405471380, a gap of 0.000006288 against a bound of 0.000000023, and the second assert stops it.

---

## The usual mistake

> [!warning]
> **Reading the endpoints off the radius.** Both series have R = 1, yet 1/(1 − x) fails at both endpoints while the log fails at −1 and converges at 1.
>
> - **Trusting the closed form past the fence.** 1/(1 − x) at x = 2 is −1.00; the series 1 + 2 + 4 + 8 + … has no sum.
> - **Differentiating at an endpoint.** The log converges at 1; its derivative series has sums 1, 0, 1, 0.

---

## Where you meet it in real life

- **Calculators.** Logs come from polynomials, on inputs first shrunk towards the centre so few terms are needed.
- **Finance.** The geometric series prices a perpetual bond (a fixed payment every year, forever), the shelf's house example; x times its derivative, x + 2x^2 + 3x^3 + …, weights each payment by its date; divided by the price, it gives the bond's duration, the average wait for the money.
- **Differential equations.** Solutions are sought as power series, and the radius says how far to trust them: [Series solutions](../../08-Differential%20equations%20and%20dynamics/07-Series%20Solutions%20and%20Boundary%20Problems/01-power-series-at-an-ordinary-point.md).

> **Say it back**
> A power series is a polynomial that never stops, read as the limit of its partial sums. Working at one distance forces working at every smaller one, so one radius R splits inside from outside. Coefficient ratios find R; the two points exactly R away are tested one by one. Inside, term-by-term calculus holds, and integrating 1 − t + t^2 − … gives the log series with its error bound.

---

## What this builds on

- [Convergence tests](02-comparison-ratio-and-root-tests.md): geometric comparison and the ratio test, which find the radius.
- [Infinite series](01-series-convergence.md): a sum as the limit of its partial sums, and the geometric series done exactly.
- [Alternating series](03-alternating-and-conditional-convergence.md): the test that settles the log series at its endpoint x = 1.

## Where this goes next

- [Taylor series](05-taylor-series.md): the coefficients a function's own derivatives force.
- [Power series in the plane](../../07-Complex%20analysis/02-Holomorphic%20Functions/02-complex-power-series.md): the fence becomes a circle, explaining the radius.
- [Series solutions](../../08-Differential%20equations%20and%20dynamics/07-Series%20Solutions%20and%20Boundary%20Problems/01-power-series-at-an-ordinary-point.md): solving for a function by solving for its coefficients.
- Weierstrass and the minimax fit: polynomials good over a whole interval.

Both series here were found by hand; which coefficients a given function forces, and whether the series then equals that function, is [Taylor series](05-taylor-series.md).

---

## Sources

Verified 2026-09-27: every link below resolves to the publisher's page.

- Lebl, Jiří. *Basic Analysis I & II*. [Section 2.6, More on series](https://www.jirka.org/ra/html/sec_moreonseries.html): the radius and endpoints. [Section 6.2, Interchange of limits](https://www.jirka.org/ra/html/sec_liminter.html): term-by-term calculus.
- Abbott, Stephen. *Understanding Analysis*, 2nd ed. Springer, 2015. [DOI 10.1007/978-1-4939-2712-8](https://doi.org/10.1007/978-1-4939-2712-8). Proves the radius from bounded terms, as Step 1 does.
- OpenStax. *Calculus Volume 2*, Rice University. [6.2 Properties of Power Series](https://openstax.org/books/calculus-volume-2/pages/6-2-properties-of-power-series): the log series by term-by-term integration.
