# Picard iteration: turn the equation into an integral, then keep feeding the guess back in

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Existence, Uniqueness and Sensitivity](../README.md#s02) → Picard iteration

---

## General Overview

A yeast culture weighs 1 gram at noon. While food is plentiful it grows, in grams per hour, at a rate equal to its mass: at 1 g it gains 1 g per hour, at 2 g it gains 2. What does it weigh at 1 pm?

Suppose no formula is known. Guess that the mass stays at 1 g. That guess gives a rate, 1 g per hour, and adding up that rate gives a better guess: 1 + t grams after t hours. Feed that back into the rule and add up again: 1 + t + t^2/2. After five passes the guess reads 2.7167 g at 1 pm; the true mass is e = 2.7183 g.

This loop is **Picard iteration**, after Émile Picard, who used it late in the nineteenth century to prove that solutions exist. It swaps "find a curve whose slope obeys the rule" for "find a curve that reproduces itself when its rate is added up", and repetition answers the second.

**Rewrite the equation as "the solution is its starting value plus its accumulated rate", start from a constant guess and keep substituting; when the rate cannot change faster than a fixed multiple of the unknown, the guesses converge to the solution.**

**What kind of fact this is:** a method; that its guesses converge is a theorem, proved in Why it works, and completed into existence and uniqueness on [The Picard-Lindelof theorem](02-lipschitz-and-the-picard-lindelof-theorem.md).

### The picture: each guess hugs the true curve a little longer

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653, #e9c46a"}}}}%%
xychart-beta
    title "Picard guesses for y' = y, y(0) = 1"
    x-axis "Time after noon (h)" [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
    y-axis "Yeast mass (g)" 0.8 --> 2.8
    line [1.00, 1.20, 1.40, 1.60, 1.80, 2.00]
    line [1.00, 1.22, 1.48, 1.78, 2.12, 2.50]
    line [1.00, 1.22, 1.49, 1.82, 2.21, 2.67]
    line [1.00, 1.22, 1.49, 1.82, 2.23, 2.72]
```

From the bottom: guess 1, the line 1 + t (orange); guess 2 (green); guess 3 (dark blue); the true mass e^t (yellow). The flat starting guess is left off. Each pass stays on the true curve further from noon.

---

## The formula

Notation first, in words. The unknown is $y$, the mass in grams, and the rule is $f$: $y' = f(t, y)$, "the rate of y at time t is f of t and y", from $y(0) = y_0$. The guess made by the n-th pass is the whole curve $\phi_n$, read "phi n". Inside an integral the running time is $s$, leaving $t$ as the end point.

The equation and its starting value together are one integral equation:

$$y(t) = y_0 + \int_0^t f\bigl(s, y(s)\bigr)\,ds$$

**Read it aloud:** the value at time t is the starting value plus all the rate collected since time 0.

Picard iteration turns that into a recipe:

$$\phi_0(t) = y_0, \qquad \phi_{n+1}(t) = y_0 + \int_0^t f\bigl(s, \phi_n(s)\bigr)\,ds$$

**Read it aloud:** start with the constant curve; for each next guess, put the current guess into the rule, integrate from 0 to t, and add the starting value.

For the yeast, $f(t, y) = y$ and $y_0 = 1$, and the guesses are partial sums of the exponential series:

$$\phi_n(t) = 1 + t + \frac{t^2}{2!} + \dots + \frac{t^n}{n!}$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $t$, $s$ | hours after noon; $s$ runs from 0 to t inside the integral | t = 1 | more passes needed |
| $y$, $y'$ | mass (g) and its rate (g per hour) | 1 g, 1 g/h at noon | — |
| $f$ | the rate rule | rate equals mass | a faster rule needs more passes |
| $y_0$ | the starting value | 1 g | every guess scales with it |
| $\phi_n$, $n$ | the n-th guess, a whole curve; the pass number | guess 5: 2.7167 at t = 1 | closer to the solution |
| $L$ | Lipschitz constant: most change in rate per unit change in the unknown | 1 per hour | slower convergence |
| $M$ | largest rate the starting guess produces | 1 g/h | larger error bound |
| $e$ | 2.71828…, the true mass at 1 pm | 2.718282 g | — |

### When it holds

- **The rule is continuous.** Then every integral exists. If the rule jumps, the limit need not have a slope everywhere.
- **The rule has a Lipschitz constant $L$:** the rate changes by at most L times any change in the unknown. Without it the guesses may find one solution among several: y' = √y from 0 gives the zero curve and misses t^2/4.
- **The guesses stay where the constant holds.** For y' = y, everywhere. For y' = y^2 the constant grows with y, and convergence stops at the blow-up time: [Blow-up](03-blow-up-and-the-life-span-of-a-solution.md).
- **The integrals are exact.** On a computer each carries a quadrature error, the error of adding up areas on a grid, and the guesses converge to the grid version's solution.

---

## Why it works

### Step 0: integrating smooths, differentiating roughens

A guess with a small wiggle can have a wildly wrong slope but a nearly right integral: a small error added up over a short time stays small. So the equation moves from slopes to areas.

### Step 1: the integral equation says the same thing

If $y$ solves the equation, integrate both sides from 0 to t: by the fundamental theorem of calculus, $y(t) - y_0$ is the integral of $f$ along the curve. Conversely, if a continuous curve satisfies the integral equation, its integrand is continuous, so the fundamental theorem differentiates the right side into $y' = f(t, y)$. Setting t = 0 gives $y(0) = y_0$. One integral equation carries both statements.

### Step 2: for the yeast, each pass adds one term

The rule returns the guess itself, so $\phi_1(t) = 1 + \int_0^t 1\,ds = 1 + t$. Integrating $s^k/k!$ from 0 to t gives $t^{k+1}/(k+1)!$, so each pass lifts every term one power and puts a fresh 1 in front. By induction $\phi_n$ is the degree-n Taylor polynomial of $e^t$ ([Taylor series](../../06-Calculus%20and%20analysis/06-Series/05-taylor-series.md)). The method rebuilt the exponential without using it.

### Step 3: the gaps between guesses shrink like a factorial

Two consecutive passes differ only through the rule, which changes by at most L times the change in the unknown. So each new gap is at most L times the integral of the previous one. The first gap is at most M t, and integrating repeatedly turns t into t^2/2, t^3/6, and so on:

$$|\phi_{n+1}(t) - \phi_n(t)| \le \frac{M L^n t^{n+1}}{(n+1)!}$$

The factorial beats any power, so the gaps add up to a finite total, $(M/L)(e^{Lt} - 1)$, wherever the constant holds, and the guesses settle. For the yeast, M = L = 1 and the gap is exactly $t^{n+1}/(n+1)!$. Over the first hour the gaps after guess n add to at most 2/(n+1)!: 0.002778 for guess 5, against a true gap of 0.001615.

### Step 4: the limit solves the equation

The gaps shrink at the same rate at every time, so the limit curve is continuous. Guesses within d of the limit give integrals within L d t of its integral, so the limit satisfies the integral equation, and by Step 1 it solves the problem.

<details>
<summary>Detailed proof: the guesses converge to a solution</summary>

Let $f$ be continuous for $0 \le t \le T$ and all y, with $|f(t, a) - f(t, b)| \le L|a - b|$, and let M be the largest value of $|f(t, y_0)|$ there.

Claim: $|\phi_{n+1}(t) - \phi_n(t)| \le M L^n t^{n+1}/(n+1)!$ on [0, T]. For n = 0 the integrand is at most M, so the gap is at most M t. If the claim holds for n − 1, the rule's bound gives $|\phi_{n+1}(t) - \phi_n(t)| \le L \int_0^t M L^{n-1} s^n/n!\,ds = M L^n t^{n+1}/(n+1)!$.

These bounds sum to $(M/L)(e^{LT} - 1)$, so for every ε > 0 there is an N with $|\phi_m(t) - \phi_n(t)| < ε$ for all m > n ≥ N and every t in [0, T]. The guesses converge uniformly to a continuous y. The integrals of the rule along $\phi_n$ and along y differ by at most L T times the largest gap, which tends to 0. So y satisfies the integral equation, and by the fundamental theorem of calculus it solves the problem. That y is the only solution is proved on the Picard-Lindelöf card.

</details>

### Step 5: no series needed

The method does not need polynomials. A bucket holds water h = 25 cm deep and drains as h' = −0.2 √h cm per minute. The first pass uses the starting rate, 1 cm per minute: 15 cm at 10 minutes. The second integrates −0.2 √(25 − s) and reads 16.0793 cm. Four more, by trapezoids on a grid, settle at 16.0000 cm, which the exact solution (5 − 0.1t)^2 confirms; the bucket empties at 50 minutes.

A second road to the yeast is Euler's rule: from each point, step a short time along the slope the rule gives. It has its own card, [Euler's method](../05-Numerical%20Evolution/01-eulers-method.md). Steps of 0.01 h reach 2.704814 g; steps of 0.001 h reach 2.716924 g. Stepping marches through time; Picard improves the whole curve at once.

---

## Worked numbers, by hand

The yeast at 1 pm, t = 1 hour.

| Step | Arithmetic | Value |
| --- | --- | --- |
| guess 0 | the starting mass | 1 g |
| guess 1 | 1 + 1 | 2 g |
| guess 2 | 2 + 1/2 | 2.5 g |
| guess 3 | 2.5 + 1/6 | 2.666667 g |
| guess 4 | 2.666667 + 1/24 | 2.708333 g |
| guess 5 | 2.708333 + 1/120 | **2.716667 g** |
| gap to the solution | e − 2.716667 | 0.001615 g |
| guaranteed gap | 2/6! = 2/720 | 0.002778 g |

After five passes the predicted mass at 1 pm is 1.6 milligrams light, inside the 2.8 milligrams Step 3 guarantees without knowing e.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Stop at guess 2 | 2.5 g, 0.218282 g short | a partial sum, not the solution |
| Integrate but never add $y_0$ | guess 5 reads 0.008333 g | only the term t^5/5! survives |
| No Lipschitz constant: y' = √y, y(0) = 0 | guesses read 0.0000 at t = 2; t^2/4 also solves it, reading 1.0000 | iteration finds a solution, not the only one |

The code prints all three.

---

## Code, from first principles, and it actually runs

Two roads sharing no arithmetic. Road one stores each guess as polynomial coefficients and integrates exactly. Road two stores each guess as values at 1,000 grid times and adds up trapezoids, so it works for any rule. They must agree on every guess, and the gaps to e must sit inside Step 3's bound. The code also steps Euler's rule, runs the bucket, and prints the three failures.

### Python

```python
# Picard iteration -- the check behind the card.  Standard library only.
# Road one feeds polynomial coefficients back in, exactly.  Road two feeds a
# curve sampled on a grid back in, adding up trapezoids; it never learns the
# curves are polynomials.  exp and sqrt are primitives; the iteration is ours.
from fractions import Fraction
from math import exp, factorial, sqrt

def coeffs(n, lead=1):                # y' = y, y(0) = 1: integrate, then add lead
    c = [Fraction(1)]
    for _ in range(n):
        c = [Fraction(lead)] + [a / (k + 1) for k, a in enumerate(c)]
    return c

def value(c, t):
    return float(sum(a * Fraction(t) ** k for k, a in enumerate(c)))

def picard_grid(f, y0, T, sweeps, guess, N=1000):   # end value of each iterate
    dt = T / N
    ts = [i * dt for i in range(N + 1)]
    ys = [guess(t) for t in ts]
    ends = [ys[-1]]
    for _ in range(sweeps):
        rate = [f(t, y) for t, y in zip(ts, ys)]
        ys = [y0]
        for i in range(N):
            ys.append(ys[-1] + dt * (rate[i] + rate[i + 1]) / 2)
        ends.append(ys[-1])
    return ends

def euler(h):                         # small steps along the slope, to t = 1
    y = 1.0
    for _ in range(round(1 / h)):
        y += h * y
    return y

e = exp(1)
grid = picard_grid(lambda t, y: y, 1.0, 1.0, 5, lambda t: 1.0)
for n in range(6):
    v, bound = value(coeffs(n), 1), 2 / factorial(n + 1)
    print(f"iterate {n} at t=1: coefficients {v:.6f}, grid {grid[n]:.6f}, gap to e {e - v:.6f}, bound {bound:.6f}")
ts = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
print("figure, t (h): " + " ".join(f"{t:.1f}" for t in ts))
for n in (1, 2, 3):
    print(f"figure, iterate {n}: " + " ".join(f"{value(coeffs(n), Fraction(t).limit_denominator(10)):.2f}" for t in ts))
print("figure, e^t: " + " ".join(f"{exp(t):.2f}" for t in ts))
e1, e2 = euler(0.01), euler(0.001)
print(f"euler's rule to t=1: step 0.01 gives {e1:.6f} (gap {e - e1:.6f}), step 0.001 gives {e2:.6f} (gap {e - e2:.6f})")
bucket = picard_grid(lambda t, h: -0.2 * sqrt(h), 25.0, 10.0, 6, lambda t: 25.0)
exact = (5 - 0.1 * 10) ** 2
print("bucket at t=10 min, iterates 0-6: " + " ".join(f"{b:.4f}" for b in bucket) + f"; exact {exact:.4f}")
root = lambda t, y: sqrt(max(y, 0.0))
zero = picard_grid(root, 0.0, 2.0, 5, lambda t: 0.0)
other = picard_grid(root, 0.0, 2.0, 1, lambda t: t * t / 4)
print(f"y' = sqrt(y), y(0) = 0, at t=2: iterates from 0 give {zero[-1]:.4f}; t^2/4 fed in returns {other[-1]:.4f}")
print(f"mistake, y0 not added after integrating: iterate 5 at t=1 is {value(coeffs(5, 0), 1):.6f}")
assert abs(grid[5] - value(coeffs(5), 1)) < 1e-5               # two roads, one iterate
assert all(0 < e - value(coeffs(n), 1) <= 2 / factorial(n + 1) for n in range(6))
assert abs(bucket[-1] - exact) < 1e-4                          # the bucket converges
assert 9 < (e - e1) / (e - e2) < 11 and abs(e - e2) < 2e-3     # stepping closes in
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
iterate 0 at t=1: coefficients 1.000000, grid 1.000000, gap to e 1.718282, bound 2.000000
iterate 1 at t=1: coefficients 2.000000, grid 2.000000, gap to e 0.718282, bound 1.000000
iterate 2 at t=1: coefficients 2.500000, grid 2.500000, gap to e 0.218282, bound 0.333333
iterate 3 at t=1: coefficients 2.666667, grid 2.666667, gap to e 0.051615, bound 0.083333
iterate 4 at t=1: coefficients 2.708333, grid 2.708333, gap to e 0.009948, bound 0.016667
iterate 5 at t=1: coefficients 2.716667, grid 2.716667, gap to e 0.001615, bound 0.002778
figure, t (h): 0.0 0.2 0.4 0.6 0.8 1.0
figure, iterate 1: 1.00 1.20 1.40 1.60 1.80 2.00
figure, iterate 2: 1.00 1.22 1.48 1.78 2.12 2.50
figure, iterate 3: 1.00 1.22 1.49 1.82 2.21 2.67
figure, e^t: 1.00 1.22 1.49 1.82 2.23 2.72
euler's rule to t=1: step 0.01 gives 2.704814 (gap 0.013468), step 0.001 gives 2.716924 (gap 0.001358)
bucket at t=10 min, iterates 0-6: 25.0000 15.0000 16.0793 15.9954 16.0002 16.0000 16.0000; exact 16.0000
y' = sqrt(y), y(0) = 0, at t=2: iterates from 0 give 0.0000; t^2/4 fed in returns 1.0000
mistake, y0 not added after integrating: iterate 5 at t=1 is 0.008333
ALL CHECKS PASS
```

### Rust

Same labels, built with `rustc --edition 2021 -O`; road one keeps the coefficients as floating-point numbers, not fractions.

```rust
// Picard iteration -- the same check as the Python, in Rust.  No crates.
// Road one feeds polynomial coefficients back in.  Road two feeds a curve
// sampled on a grid back in, adding up trapezoids; it never learns the curves
// are polynomials.  exp and sqrt are primitives; the iteration is ours.
fn coeffs(n: usize, lead: f64) -> Vec<f64> { // y' = y, y(0) = 1: integrate, then add lead
    let mut c = vec![1.0];
    for _ in 0..n {
        let mut next = vec![lead];
        next.extend(c.iter().enumerate().map(|(k, a)| a / (k + 1) as f64));
        c = next;
    }
    c
}

fn value(c: &[f64], t: f64) -> f64 { c.iter().enumerate().map(|(k, a)| a * t.powi(k as i32)).sum() }

fn picard_grid(f: &dyn Fn(f64, f64) -> f64, y0: f64, big_t: f64, sweeps: usize, guess: &dyn Fn(f64) -> f64) -> Vec<f64> {
    let n = 1000;                        // end value of each iterate
    let dt = big_t / n as f64;
    let ts: Vec<f64> = (0..=n).map(|i| i as f64 * dt).collect();
    let mut ys: Vec<f64> = ts.iter().map(|&t| guess(t)).collect();
    let mut ends = vec![ys[n]];
    for _ in 0..sweeps {
        let rate: Vec<f64> = ts.iter().zip(&ys).map(|(&t, &y)| f(t, y)).collect();
        ys = vec![y0];
        for i in 0..n { let last = ys[i]; ys.push(last + dt * (rate[i] + rate[i + 1]) / 2.0) }
        ends.push(ys[n]);
    }
    ends
}

fn euler(h: f64) -> f64 {                // small steps along the slope, to t = 1
    let mut y = 1.0;
    for _ in 0..(1.0 / h).round() as usize { y += h * y }
    y
}

fn fact(n: usize) -> f64 { (1..=n).map(|k| k as f64).product() }

fn row(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let e = 1f64.exp();
    let grid = picard_grid(&|_t, y| y, 1.0, 1.0, 5, &|_t| 1.0);
    for n in 0..6 {
        let (v, bound) = (value(&coeffs(n, 1.0), 1.0), 2.0 / fact(n + 1));
        println!("iterate {} at t=1: coefficients {:.6}, grid {:.6}, gap to e {:.6}, bound {:.6}", n, v, grid[n], e - v, bound);
    }
    let ts = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];
    println!("figure, t (h): {}", row(&ts, 1));
    for n in 1..4 {
        let vals: Vec<f64> = ts.iter().map(|&t| value(&coeffs(n, 1.0), t)).collect();
        println!("figure, iterate {}: {}", n, row(&vals, 2));
    }
    println!("figure, e^t: {}", row(&ts.iter().map(|t| t.exp()).collect::<Vec<_>>(), 2));
    let (e1, e2) = (euler(0.01), euler(0.001));
    println!("euler's rule to t=1: step 0.01 gives {:.6} (gap {:.6}), step 0.001 gives {:.6} (gap {:.6})", e1, e - e1, e2, e - e2);
    let bucket = picard_grid(&|_t, h: f64| -0.2 * h.sqrt(), 25.0, 10.0, 6, &|_t| 25.0);
    let exact = (5.0 - 0.1 * 10.0f64).powi(2);
    println!("bucket at t=10 min, iterates 0-6: {}; exact {:.4}", row(&bucket, 4), exact);
    let root = |_t: f64, y: f64| y.max(0.0).sqrt();
    let zero = picard_grid(&root, 0.0, 2.0, 5, &|_t| 0.0);
    let other = picard_grid(&root, 0.0, 2.0, 1, &|t| t * t / 4.0);
    println!("y' = sqrt(y), y(0) = 0, at t=2: iterates from 0 give {:.4}; t^2/4 fed in returns {:.4}", zero[5], other[1]);
    println!("mistake, y0 not added after integrating: iterate 5 at t=1 is {:.6}", value(&coeffs(5, 0.0), 1.0));
    assert!((grid[5] - value(&coeffs(5, 1.0), 1.0)).abs() < 1e-5);             // two roads, one iterate
    assert!((0..6).all(|n| { let g = e - value(&coeffs(n, 1.0), 1.0); 0.0 < g && g <= 2.0 / fact(n + 1) }));
    assert!((bucket[6] - exact).abs() < 1e-4);                            // the bucket converges
    assert!(9.0 < (e - e1) / (e - e2) && (e - e1) / (e - e2) < 11.0 && (e - e2).abs() < 2e-3);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
iterate 0 at t=1: coefficients 1.000000, grid 1.000000, gap to e 1.718282, bound 2.000000
iterate 1 at t=1: coefficients 2.000000, grid 2.000000, gap to e 0.718282, bound 1.000000
iterate 2 at t=1: coefficients 2.500000, grid 2.500000, gap to e 0.218282, bound 0.333333
iterate 3 at t=1: coefficients 2.666667, grid 2.666667, gap to e 0.051615, bound 0.083333
iterate 4 at t=1: coefficients 2.708333, grid 2.708333, gap to e 0.009948, bound 0.016667
iterate 5 at t=1: coefficients 2.716667, grid 2.716667, gap to e 0.001615, bound 0.002778
figure, t (h): 0.0 0.2 0.4 0.6 0.8 1.0
figure, iterate 1: 1.00 1.20 1.40 1.60 1.80 2.00
figure, iterate 2: 1.00 1.22 1.48 1.78 2.12 2.50
figure, iterate 3: 1.00 1.22 1.49 1.82 2.21 2.67
figure, e^t: 1.00 1.22 1.49 1.82 2.23 2.72
euler's rule to t=1: step 0.01 gives 2.704814 (gap 0.013468), step 0.001 gives 2.716924 (gap 0.001358)
bucket at t=10 min, iterates 0-6: 25.0000 15.0000 16.0793 15.9954 16.0002 16.0000 16.0000; exact 16.0000
y' = sqrt(y), y(0) = 0, at t=2: iterates from 0 give 0.0000; t^2/4 fed in returns 1.0000
mistake, y0 not added after integrating: iterate 5 at t=1 is 0.008333
ALL CHECKS PASS
```

The two outputs match line for line. A tenfold smaller Euler step cuts its gap tenfold, 0.013468 to 0.001358: first order.

### Lean

Lean proves that the guesses converge for every continuous rule with a Lipschitz constant, and finds the yeast's guesses for every pass.

- Let the rule be continuous for times 0 to T and every value, with a Lipschitz constant L there. Then the guesses converge at the same rate at every time from 0 to T.
- The limit is a continuous curve that satisfies the integral equation and starts at $y_0$. Its slope is the one the rule gives, from 0 to T.
- Let M bound the rate the starting guess produces. At time t, guesses n and n + 1 differ by at most $M L^n t^{n+1}/(n+1)!$.
- For y' = y from 1, guess n is $1 + t + t^2/2! + \dots + t^n/n!$ at every time t.
- At 1 pm, guesses 0 to 5 read 1, 2, 5/2, 8/3, 65/24 and 163/60 g.
- The arithmetic: 2/6! is 1/360 g, 1/5! is 1/120 g, and t^2/4 reads 1 at t = 2.

The decimals, the gaps to e, the grid road, Euler's rule, the bucket and y' = √y are left to the Python and Rust checks.

```lean
-- Picard iteration: for a rate rule that is continuous and has a Lipschitz constant L on the times 0 to T, the Picard guesses converge uniformly to a solution of y' = f(t, y), y(0) = y0, the gap between guesses n and n + 1 is at most M L^n t^(n+1)/(n+1)!, and for y' = y from 1 the guesses are the partial sums of the exponential series.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Normed.Group.FunctionSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Topology.UniformSpace.UniformApproximation

open Set Filter Finset

/-- Helper: each Picard guess is continuous on the times `0` to `T`. -/
lemma picard_iterate_continuousOn (f : ℝ → ℝ → ℝ) (y₀ T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∀ n, ContinuousOn (φ n) (Icc 0 T) := by
  intro n
  induction n with
  | zero => exact (continuousOn_const (c := y₀)).congr (fun t ht => h0 t ht)
  | succ n ih =>
    rcases lt_or_ge T 0 with hT | hT
    · rw [Icc_eq_empty (not_le.mpr hT)]; exact continuousOn_empty _
    have hg : ContinuousOn (fun s => f s (φ n s)) (Icc 0 T) :=
      hcont.comp (continuousOn_id.prodMk ih) (fun s hs => ⟨hs, mem_univ _⟩)
    have hprim := intervalIntegral.continuousOn_primitive_interval' (μ := MeasureTheory.volume) (a := 0)
      (hg.intervalIntegrable_of_Icc hT) (by rw [uIcc_of_le hT]; exact ⟨le_rfl, hT⟩)
    rw [uIcc_of_le hT] at hprim
    exact (continuousOn_const.add hprim).congr (fun t ht => hstep n t ht)

/-- Helper: the gap bound `|φ (n + 1) t - φ n t| ≤ M L^n t^(n+1) / (n+1)!`. -/
lemma picard_gap_bound_aux (f : ℝ → ℝ → ℝ) (y₀ L M T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (hlip : ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L * |a - b|)
    (hM : ∀ t ∈ Icc 0 T, |f t y₀| ≤ M)
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∀ n : ℕ, ∀ t ∈ Icc 0 T,
      |φ (n + 1) t - φ n t| ≤ M * L ^ n * t ^ (n + 1) / ((n + 1).factorial : ℝ) := by
  have hφc := picard_iterate_continuousOn f y₀ T hcont φ h0 hstep
  have hcomp : ∀ h : ℝ → ℝ, ContinuousOn h (Icc 0 T) →
      ContinuousOn (fun s => f s (h s)) (Icc 0 T) := fun h hh =>
    hcont.comp (continuousOn_id.prodMk hh) (fun s hs => ⟨hs, mem_univ _⟩)
  intro n
  induction n with
  | zero =>
    intro t ht
    have hsub : uIoc (0 : ℝ) t ⊆ Icc 0 T := by
      rw [uIoc_of_le ht.1]; exact fun s hs => ⟨hs.1.le, hs.2.trans ht.2⟩
    rw [hstep 0 t ht, h0 t ht, add_sub_cancel_left]
    have hcongr : ∫ s in (0)..t, f s (φ 0 s) = ∫ s in (0)..t, f s y₀ := by
      refine intervalIntegral.integral_congr (fun s hs => ?_)
      rw [uIcc_of_le ht.1] at hs
      simp only [h0 s ⟨hs.1, hs.2.trans ht.2⟩]
    rw [hcongr]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := t) (C := M)
      (f := fun s => f s y₀) (fun s hs => by rw [Real.norm_eq_abs]; exact hM s (hsub hs))
    rw [Real.norm_eq_abs, sub_zero, abs_of_nonneg ht.1] at this
    simpa using this
  | succ n ih =>
    intro t ht
    have hL : 0 ≤ L := by
      have := hlip t ht 1 0
      norm_num at this
      exact (abs_nonneg _).trans this
    have hsub : uIcc (0 : ℝ) t ⊆ Icc 0 T := by
      rw [uIcc_of_le ht.1]; exact Icc_subset_Icc le_rfl ht.2
    have int1 : IntervalIntegrable (fun s => f s (φ (n + 1) s)) MeasureTheory.volume 0 t :=
      ((hcomp _ (hφc (n + 1))).mono hsub).intervalIntegrable
    have int2 : IntervalIntegrable (fun s => f s (φ n s)) MeasureTheory.volume 0 t :=
      ((hcomp _ (hφc n)).mono hsub).intervalIntegrable
    have int3 : IntervalIntegrable (fun s => |f s (φ (n + 1) s) - f s (φ n s)|)
        MeasureTheory.volume 0 t :=
      ((((hcomp _ (hφc (n + 1))).sub (hcomp _ (hφc n))).abs).mono hsub).intervalIntegrable
    have int4 : IntervalIntegrable
        (fun s : ℝ => L * (M * L ^ n * s ^ (n + 1) / ((n + 1).factorial : ℝ)))
        MeasureTheory.volume 0 t := by
      apply Continuous.intervalIntegrable; fun_prop
    rw [hstep (n + 1) t ht, hstep n t ht, add_sub_add_left_eq_sub,
      ← intervalIntegral.integral_sub int1 int2]
    calc |∫ s in (0)..t, (f s (φ (n + 1) s) - f s (φ n s))|
        ≤ ∫ s in (0)..t, |f s (φ (n + 1) s) - f s (φ n s)| :=
          intervalIntegral.abs_integral_le_integral_abs ht.1
      _ ≤ ∫ s in (0)..t, L * (M * L ^ n * s ^ (n + 1) / ((n + 1).factorial : ℝ)) := by
          refine intervalIntegral.integral_mono_on ht.1 int3 int4 (fun s hs => ?_)
          have hs' : s ∈ Icc 0 T := ⟨hs.1, hs.2.trans ht.2⟩
          exact (hlip s hs' _ _).trans (mul_le_mul_of_nonneg_left (ih s hs') hL)
      _ = M * L ^ (n + 1) * t ^ (n + 1 + 1) / ((n + 1 + 1).factorial : ℝ) := by
          have hfun : (fun s : ℝ => L * (M * L ^ n * s ^ (n + 1) / ((n + 1).factorial : ℝ))) =
              fun s => (L * M * L ^ n / ((n + 1).factorial : ℝ)) * s ^ (n + 1) := by
            ext s; ring
          rw [hfun, intervalIntegral.integral_const_mul, integral_pow, Nat.factorial_succ (n + 1)]
          push_cast
          field_simp
          ring

/-- Picard iteration converges to a solution. Let the rule `f` be continuous for times
`0 ≤ t ≤ T` and every value `y`, and let it have a Lipschitz constant `L` there:
`|f t a - f t b| ≤ L * |a - b|`. Start from the constant guess `φ 0 t = y₀` and make each next
guess by `φ (n + 1) t = y₀ + ∫₀ᵗ f(s, φ n s) ds`. Then the guesses converge, at the same rate
at every time from `0` to `T`, to a continuous curve `y` that satisfies the integral equation
`y t = y₀ + ∫₀ᵗ f(s, y s) ds` and solves the problem `y' = f(t, y)`, `y(0) = y₀`. -/
theorem picard_iterates_converge_to_solution (f : ℝ → ℝ → ℝ) (y₀ L T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (hlip : ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L * |a - b|)
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∃ y : ℝ → ℝ, TendstoUniformlyOn φ y atTop (Icc 0 T) ∧ ContinuousOn y (Icc 0 T) ∧
      (∀ t ∈ Icc 0 T, y t = y₀ + ∫ s in (0)..t, f s (y s)) ∧
      y 0 = y₀ ∧ ∀ t ∈ Icc 0 T, HasDerivWithinAt y (f t (y t)) (Icc 0 T) t := by
  rcases lt_or_ge T 0 with hT | hT
  · have hE : Icc 0 T = ∅ := Icc_eq_empty (not_le.mpr hT)
    refine ⟨fun _ => y₀, ?_, ?_, ?_, rfl, ?_⟩
    · rw [hE]; exact tendstoUniformlyOn_empty
    · rw [hE]; exact continuousOn_empty _
    · intro t ht; rw [hE] at ht; simp at ht
    · intro t ht; rw [hE] at ht; simp at ht
  -- a nonnegative Lipschitz constant
  obtain ⟨L', hL', hlip'⟩ : ∃ L' : ℝ, 0 < L' ∧
      ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L' * |a - b| :=
    ⟨max L 0 + 1, by positivity, fun t ht a b =>
      (hlip t ht a b).trans (mul_le_mul_of_nonneg_right
        (by linarith [le_max_left L 0]) (abs_nonneg _))⟩
  have hcomp : ∀ h : ℝ → ℝ, ContinuousOn h (Icc 0 T) →
      ContinuousOn (fun s => f s (h s)) (Icc 0 T) := fun h hh =>
    hcont.comp (continuousOn_id.prodMk hh) (fun s hs => ⟨hs, mem_univ _⟩)
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn
    (hcomp (fun _ => y₀) continuousOn_const)
  have hM' : ∀ t ∈ Icc 0 T, |f t y₀| ≤ M := fun t ht => by
    simpa [Real.norm_eq_abs] using hM t ht
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM' 0 ⟨le_rfl, hT⟩)
  have hgap := picard_gap_bound_aux f y₀ L' M T hcont hlip' hM' φ h0 hstep
  have hφc := picard_iterate_continuousOn f y₀ T hcont φ h0 hstep
  -- the series of gaps
  obtain ⟨d, hd⟩ : ∃ d : ℕ → ℝ → ℝ, d = fun n t => φ (n + 1) t - φ n t := ⟨_, rfl⟩
  obtain ⟨u, hu⟩ : ∃ u : ℕ → ℝ, u = fun n => M * L' ^ n * T ^ (n + 1) / ((n + 1).factorial : ℝ) :=
    ⟨_, rfl⟩
  have hus : Summable u := by
    have h1 : Summable (fun n : ℕ => (L' * T) ^ (n + 1) / ((n + 1).factorial : ℝ)) :=
      (summable_nat_add_iff 1).mpr (Real.summable_pow_div_factorial (L' * T))
    have h2 := h1.mul_left (M / L')
    convert h2 using 1
    ext n
    rw [hu, mul_pow, pow_succ L']
    field_simp
  have hbound : ∀ n t, t ∈ Icc 0 T → ‖d n t‖ ≤ u n := by
    intro n t ht
    rw [hd, hu, Real.norm_eq_abs]
    dsimp only
    refine (hgap n t ht).trans ?_
    have : t ^ (n + 1) ≤ T ^ (n + 1) := pow_le_pow_left₀ ht.1 ht.2 _
    gcongr
  have hTU := tendstoUniformlyOn_tsum_nat hus hbound
  obtain ⟨y, hy⟩ : ∃ y : ℝ → ℝ, y = fun t => y₀ + ∑' n, d n t := ⟨_, rfl⟩
  have hφsum : ∀ N, ∀ t ∈ Icc 0 T, φ N t = y₀ + ∑ n ∈ range N, d n t := by
    intro N t ht
    rw [hd]
    simp only
    rw [Finset.sum_range_sub (fun n => φ n t), h0 t ht]
    ring
  have hconv : TendstoUniformlyOn φ y atTop (Icc 0 T) := by
    rw [Metric.tendstoUniformlyOn_iff] at hTU ⊢
    intro ε hε
    filter_upwards [hTU ε hε] with N hN t ht
    rw [hφsum N t ht, hy]
    simp only
    rw [dist_add_left]
    exact hN t ht
  have hyc : ContinuousOn y (Icc 0 T) :=
    hconv.continuousOn (Eventually.of_forall hφc).frequently
  have hgc := hcomp y hyc
  have hint : ∀ t ∈ Icc 0 T, y t = y₀ + ∫ s in (0)..t, f s (y s) := by
    intro t ht
    have hsub : uIcc (0 : ℝ) t ⊆ Icc 0 T := by
      rw [uIcc_of_le ht.1]; exact Icc_subset_Icc le_rfl ht.2
    have h1 : Tendsto (fun n => φ (n + 1) t) atTop (nhds (y t)) :=
      (hconv.tendsto_at ht).comp (tendsto_add_atTop_nat 1)
    have h2 : Tendsto (fun n => φ (n + 1) t) atTop
        (nhds (y₀ + ∫ s in (0)..t, f s (y s))) := by
      rw [Metric.tendsto_atTop]
      intro ε hε
      have hpos : 0 < L' * T + 1 := by positivity
      obtain ⟨N, hN⟩ := eventually_atTop.mp
        (Metric.tendstoUniformlyOn_iff.mp hconv (ε / (L' * T + 1)) (by positivity))
      refine ⟨N, fun n hn => ?_⟩
      have int1 : IntervalIntegrable (fun s => f s (φ n s)) MeasureTheory.volume 0 t :=
        ((hcomp _ (hφc n)).mono hsub).intervalIntegrable
      have int2 : IntervalIntegrable (fun s => f s (y s)) MeasureTheory.volume 0 t :=
        (hgc.mono hsub).intervalIntegrable
      rw [hstep n t ht, dist_add_left, dist_eq_norm,
        ← intervalIntegral.integral_sub int1 int2]
      calc ‖∫ s in (0)..t, (f s (φ n s) - f s (y s))‖
          ≤ (L' * (ε / (L' * T + 1))) * |t - 0| := by
            refine intervalIntegral.norm_integral_le_of_norm_le_const (fun s hs => ?_)
            have hs' : s ∈ Icc 0 T := hsub (uIoc_subset_uIcc hs)
            rw [Real.norm_eq_abs]
            refine (hlip' s hs' _ _).trans (mul_le_mul_of_nonneg_left ?_ hL'.le)
            have := hN n hn s hs'
            rw [Real.dist_eq, abs_sub_comm] at this
            exact this.le
        _ ≤ (L' * (ε / (L' * T + 1))) * T := by
            rw [sub_zero, abs_of_nonneg ht.1]
            gcongr
            exact ht.2
        _ = ε * (L' * T) / (L' * T + 1) := by field_simp
        _ < ε := by
            rw [div_lt_iff₀ hpos]
            nlinarith
    exact tendsto_nhds_unique h1 h2
  refine ⟨y, hconv, hyc, hint, ?_, ?_⟩
  · rw [hint 0 ⟨le_rfl, hT⟩, intervalIntegral.integral_same, add_zero]
  · intro t ht
    obtain ⟨g, hg⟩ : ∃ g : ℝ → ℝ, g = fun s => f (projIcc 0 T hT s) (y (projIcc 0 T hT s)) :=
      ⟨_, rfl⟩
    have hgcont : Continuous g := by
      rw [hg]
      exact hgc.comp_continuous (continuous_subtype_val.comp continuous_projIcc)
        (fun s => (projIcc 0 T hT s).2)
    have hgeq : ∀ s ∈ Icc 0 T, g s = f s (y s) := by
      intro s hs
      rw [hg]
      simp only [projIcc_of_mem hT hs]
    have hderiv : HasDerivAt (fun u => y₀ + ∫ s in (0)..u, g s) (g t) t :=
      ((hgcont.integral_hasStrictDerivAt 0 t).hasDerivAt).const_add y₀
    rw [← hgeq t ht]
    refine hderiv.hasDerivWithinAt.congr_of_mem (fun u hu => ?_) ht
    rw [hint u hu]
    congr 1
    refine intervalIntegral.integral_congr (fun s hs => ?_)
    rw [uIcc_of_le hu.1] at hs
    exact (hgeq s ⟨hs.1, hs.2.trans hu.2⟩).symm

/-- The gaps between guesses shrink like a factorial. With the same rule, Lipschitz constant
`L` and guesses as above, let `M` bound the rate the starting guess produces:
`|f t y₀| ≤ M` for `0 ≤ t ≤ T`. Then at every time `t` from `0` to `T` and for every pass `n`,
`|φ (n + 1) t - φ n t| ≤ M * L ^ n * t ^ (n + 1) / (n + 1)!`. -/
theorem picard_gap_le_factorial_bound (f : ℝ → ℝ → ℝ) (y₀ L M T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (hlip : ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L * |a - b|)
    (hM : ∀ t ∈ Icc 0 T, |f t y₀| ≤ M)
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∀ n : ℕ, ∀ t ∈ Icc 0 T,
      |φ (n + 1) t - φ n t| ≤ M * L ^ n * t ^ (n + 1) / ((n + 1).factorial : ℝ) := by
  exact picard_gap_bound_aux f y₀ L M T hcont hlip hM φ h0 hstep

/-- The yeast: for `y' = y` from `y(0) = 1`, the Picard guesses are the partial sums of the
exponential series, `φ n t = 1 + t + t²/2! + ... + tⁿ/n!`, at every time `t`. -/
theorem yeast_picard_iterates_are_exp_partial_sums (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t, φ 0 t = 1)
    (hstep : ∀ n t, φ (n + 1) t = 1 + ∫ s in (0)..t, φ n s) :
    ∀ n : ℕ, ∀ t : ℝ, φ n t = ∑ k ∈ range (n + 1), t ^ k / (k.factorial : ℝ) := by
  intro n
  induction n with
  | zero => intro t; simp [h0]
  | succ n ih =>
    intro t
    have hfun : φ n = fun s => ∑ k ∈ range (n + 1), s ^ k / (k.factorial : ℝ) := funext ih
    rw [hstep, hfun, intervalIntegral.integral_finsetSum
      (fun k _ => by apply Continuous.intervalIntegrable; fun_prop)]
    rw [Finset.sum_range_succ' _ (n + 1)]
    simp only [intervalIntegral.integral_div, integral_pow, pow_zero, Nat.factorial_zero,
      Nat.cast_one, div_one]
    rw [add_comm]
    congr 1
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [Nat.factorial_succ]
    push_cast
    field_simp
    ring

-- The yeast at 1 pm, guesses 0 to 5: 1, 2, 5/2, 8/3, 65/24 and 163/60 grams (163/60 = 2.716667).
example : ∑ k ∈ range 1, (1 : ℚ) / k.factorial = 1 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 2, (1 : ℚ) / k.factorial = 2 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 3, (1 : ℚ) / k.factorial = 5 / 2 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 4, (1 : ℚ) / k.factorial = 8 / 3 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 5, (1 : ℚ) / k.factorial = 65 / 24 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 6, (1 : ℚ) / k.factorial = 163 / 60 := by norm_num [Finset.sum_range_succ, Nat.factorial]
-- The guaranteed gap after guess 5: 2/6! = 2/720 = 1/360 g.
example : (2 : ℚ) / (Nat.factorial 6) = 1 / 360 := by norm_num [Nat.factorial]
-- Forgetting to add y₀: guess 5 keeps only t^5/5!, which at t = 1 is 1/120 g.
example : (1 : ℚ) / (Nat.factorial 5) = 1 / 120 := by norm_num [Nat.factorial]
-- y' = √y from 0: the other solution t²/4 reads 1 at t = 2.
example : (2 : ℚ) ^ 2 / 4 = 1 := by norm_num

#print axioms picard_iterate_continuousOn
#print axioms picard_gap_bound_aux
#print axioms picard_iterates_converge_to_solution
#print axioms picard_gap_le_factorial_bound
#print axioms yeast_picard_iterates_are_exp_partial_sums
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'picard_iterate_continuousOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'picard_gap_bound_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'picard_iterates_converge_to_solution' depends on axioms: [propext, Classical.choice, Quot.sound]
'picard_gap_le_factorial_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'yeast_picard_iterates_are_exp_partial_sums' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **More passes.** Change `range(6)` to `range(9)` and the grid call's `5` to `8`. Guess 8 reads 2.718279 g, about 3 millionths short of e.
> - **Two hours.** Evaluate the coefficients at t = 2. Guess 5 reads 7.266667 against e^2 = 7.389056: five passes are worse further out.
> - **Drop the trapezoid.** Replace `(rate[i] + rate[i + 1]) / 2` with `rate[i]`. The grid road lags by about 0.0013 at guess 5, and the first assert stops the run.

---

## The usual mistake

> [!warning]
> **Treating the pass number as time.** Each guess is a whole curve, not a value at a later moment. Guess 5 covers noon to 1 pm and beyond; it is good near noon and worse far away, and more passes push the good region outward.
>
> - **Reporting a guess as exact.** Guess 2 is 0.218282 g short at 1 pm.
> - **Reading convergence as uniqueness.** y' = √y from 0 iterates to 0, while t^2/4 also solves it; uniqueness needs the Lipschitz constant.

---

## Where you meet it in real life

- **Existence proofs.** Most textbook proofs that an initial value problem has a solution build it this way.
- **Series solutions.** For a polynomial rule, a few passes by hand give a solution's first power-series terms.
- **Sensitivity to the start.** The same gap estimate, applied to two solutions from different starts, bounds how far they drift apart: [Gronwall's inequality](04-gronwall-and-continuous-dependence.md).

> **Say it back**
> A differential equation with a starting value is one integral equation: the value is the start plus the accumulated rate. Picard iteration starts from the constant curve and keeps putting the latest guess into the rule and integrating. With a Lipschitz constant the gaps between guesses shrink like a factorial, and the limit solves the equation. For y' = y from 1 the guesses are the partial sums of e^t; the fifth reads 2.7167 at t = 1 against 2.7183.

---

## What this builds on

- [A differential equation](../01-Rate%20Equations/01-what-a-differential-equation-says.md): rate rule, starting value, solution.
- [Fixed points](../../06-Calculus%20and%20analysis/03-What%20Derivatives%20Tell%20You/07-fixed-point-iteration-and-the-contraction-principle.md): pressing a rule until its output stops moving; Picard does the same to whole curves.
- [Fundamental theorem of calculus](../../06-Calculus%20and%20analysis/04-Integrals/02-fundamental-theorem-of-calculus.md): the bridge between the equation and its integral form.
- [Taylor series](../../06-Calculus%20and%20analysis/06-Series/05-taylor-series.md): the polynomials the yeast's guesses become.

## Where this goes next

- [The Picard-Lindelof theorem](02-lipschitz-and-the-picard-lindelof-theorem.md): the limit exists, and it is the only solution.
- Banach's fixed point theorem: any map that shrinks distances has one fixed point, Picard's recipe being one.
- Schauder: a fixed point without shrinking, giving solutions when the rule has no Lipschitz constant.

The guesses settle on a solution, but this card leaves open whether the Lipschitz constant rules out every other solution from the same start.

---

## Sources

Verified 28 Sep 2026: every link below resolves to the author's or archive's page.

- Lebl, Jiří. *Basic Analysis*, §7.6. [Author's page](https://www.jirka.org/ra/html/sec_metpicard.html). The iteration as a contraction on continuous functions.
- Lebl, Jiří. *Notes on Diffy Qs*, §1.2. [Author's page](https://www.jirka.org/diffyqs/html/slopefields_section.html). Picard's theorem for a first course; y' = 2√|y| from 0 has two solutions.
- Teschl, Gerald. *Ordinary Differential Equations and Dynamical Systems*, AMS Graduate Studies in Mathematics 140. [Author's page](https://www.mat.univie.ac.at/~gerald/ftp/book-ode/). Chapter 2 builds solutions by Picard iteration.
- O'Connor, J. J., and E. F. Robertson. "Charles Émile Picard." MacTutor, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Picard_Emile/). His successive approximations for existence.
