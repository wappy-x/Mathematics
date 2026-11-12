# Series solutions: assume the answer is a polynomial that never stops and match the coefficients

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Series Solutions and Boundary Problems](../README.md#s07) → Series solutions

---

## General Overview

A steel rod 2 mm thick and 865.9 mm long hangs from a clamp tilted 2 degrees off vertical. Its weight pulls it back toward vertical. How much tilt is left at the free tip?

The tension at each height is the weight of rod below, so the law for the tilt has a coefficient that grows along the rod, and the exponentials that solve a car's shock absorber no longer fit.

The way through: assume the answer is a polynomial that never stops, put it into the equation, and let the equation choose each coefficient: 1, 1/6, 1/180, 1/12960 and so on. Summed, the clamp's tilt is 1.1723 times the tip's, so the tip keeps 1.706 degrees.

**Where a linear equation's coefficients are power series, so are its solutions: substituting one turns the equation into a rule for each coefficient, and the series converges at least out to the nearest point, real or complex, where a coefficient fails.**

**What kind of fact this is:** a method; the promise about how far the series converges is a theorem, proved on this card in Why it works.

### The picture: the tilt up the rod, and the first two terms alone

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Tilt of a hanging rod, as a multiple of the tip's tilt"
    x-axis "Height above the free tip, in natural lengths (865.9 mm each)" [0, 0.5, 1, 1.5, 2, 2.5, 3]
    y-axis "Tilt / tip tilt (no unit)" 0 --> 12
    line [1.00, 1.02, 1.17, 1.63, 2.73, 5.29, 11.42]
    line [1.00, 1.02, 1.17, 1.56, 2.33, 3.60, 5.50]
```

Orange: the series summed to x^30. Teal: 1 + x^3/6 alone. They agree to two decimals up to one natural length, then part.

---

## The formula

Here the rates run up the rod, not through time. Height $x$ is measured up from the tip in **natural lengths** (865.9 mm here, derived below); $y$ is the tilt over the tip's tilt. The law is **Airy's equation**, met by George Airy in 1838 at a rainbow's edge:

$$y'' = x\,y, \qquad y(0) = 1, \qquad y'(0) = 0.$$

**Read it aloud:** the rate of the tilt's rate equals height times tilt; at the tip the tilt is 1 and not changing.

The method, for any equation $y'' + P(x)\,y' + Q(x)\,y = 0$ with the leading coefficient divided out:

$$y = \sum_{n=0}^{\infty} a_n\,(x - x_0)^n, \qquad a_0 = y(x_0), \quad a_1 = y'(x_0).$$

**Read it aloud:** the answer is a power series around the start; its first two coefficients are the starting value and rate, and the equation fixes the rest.

For Airy's equation, with $x_0 = 0$:

$$a_2 = 0, \qquad a_{n+3} = \frac{a_n}{(n+3)(n+2)} \quad (n \ge 0)$$

**Read it aloud:** each coefficient is the one three places back, divided by the two numbers just stepped past.

The point $x_0$ is **ordinary** when $P$ and $Q$ are power series around it. The reach:

$$R \;\ge\; \text{distance from } x_0 \text{ to the nearest complex point where } P \text{ or } Q \text{ fails}.$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$ | height above the tip, in natural lengths | 0 tip, 1 clamp | tilt grows faster |
| $y$, $y'$, $y''$ | tilt over tip tilt; its rate; that rate's rate | 1.1723 at the clamp | — |
| $\ell$ | natural length, (EI/w)^(1/3): E stiffness, I bending factor, w weight per metre | 865.9 mm | the tip keeps more of the clamp's tilt |
| $x_0$ | centre of the series | 0, the tip | — |
| $P$, $Q$ | coefficients of y' and y, y'' alone | P = 0, Q = −x | — |
| $a_n$, $n$ | coefficient of the n-th power; the power | a_3 = 1/6 | — |
| $S_N$ | partial sum, cut after power N | S_3 = 1.166667 | nearer 1.172300 |
| $R$ | radius of convergence: how far out the series adds up | unlimited; 1 for arctan | — |

### When it holds

- **An ordinary point.** In x^2 y'' + x y' + (x^2 − 1) y = 0, dividing by x^2 leaves 1/x and 1/x^2, which fail at 0; there [Frobenius](02-frobenius-and-regular-singular-points.md) repairs it.
- **A linear equation, for the radius promise.** y' = y^2, y(0) = 1, has no bad coefficient, yet its answer 1/(1 − x) blows up at x = 1.
- **A floor, not the exact radius.** Legendre's equation fails at ±1, yet some solutions are polynomials ([Legendre's equation](04-legendre-polynomials.md)).
- **Inside the radius only.** Past R the partial sums swing wildly, as the arctan case shows.

---

## Why it works

### Step 0: a power series can be differentiated term by term

Inside its radius a power series has as its rate the series of its terms' rates ([Power series](../../06-Calculus%20and%20analysis/06-Series/04-power-series.md)). Two power series are equal only when every coefficient matches, so one equation becomes one equation per power of x.

<details>
<summary>Where y'' = x y comes from, for the hanging rod</summary>

Height s in metres up from the tip; u(s) the sideways offset; θ = u' the tilt. The rod below s, hanging off line, bends it: EI u'' = ∫ from 0 to s of w (u(s) − u(σ)) dσ, σ running over the heights below s, EI being the bending stiffness. Differentiating: EI θ'' = w s θ. The tip carries no bending, so θ'(0) = 0. With s = ℓ x and ℓ^3 = EI / w, θ'' = x θ. A round rod has ℓ^3 = E d^2 / (16 ρ g); for steel (E = 200 GPa, ρ = 7850 kg/m^3), g = 9.81 m/s^2 and d = 2 mm, ℓ = 865.9 mm.

</details>

### Step 1: substitute and match the powers

With $y = \sum a_n x^n$, $y'' = \sum (n+2)(n+1)\,a_{n+2}\,x^n$ and $x\,y = \sum a_{n-1}\,x^n$ from n = 1. Match x^n. At n = 0, 2 a_2 = 0, since x y has no constant term. For n ≥ 1, (n + 2)(n + 1) a_{n+2} = a_{n−1}; renaming n − 1 as n gives the rule. It steps by three, so there are three chains, from a_0, a_1 and a_2; the last stays zero.

### Step 2: the two starting values fix the two free coefficients

At x = 0 the series reads a_0 and its rate a_1, so a_0 = 1 and a_1 = 0, silencing the second chain. The first gives y = 1 + x^3/6 + x^6/180 + x^9/12960 + …. Two free coefficients match the two conditions a second-order equation needs: a_0 = 0, a_1 = 1 gives the other basic solution, x + x^4/12 + …, and every solution mixes the two ([Superposition](../03-Oscillators%20-%20Second-Order%20Linear%20Equations/01-superposition-and-the-shape-of-linear-solutions.md)).

### Step 3: the series converges, so it is a real solution

Matching assumed a series existed. Successive terms have ratio x^3 / ((n + 3)(n + 2)), which shrinks to 0 for any x, so by the ratio test (a series converges when the size of each term over the last settles below 1) the series converges everywhere (a term outgrows the last only while x^3 > (n + 3)(n + 2): x > 10.2 at n = 30, 45.1 at n = 300). Step 0's term-by-term rates are then legitimate, the sum solves y'' = x y, and since only one solution starts at value 1 with rate 0 ([The Picard-Lindelof theorem](../02-Existence%2C%20Uniqueness%20and%20Sensitivity/02-lipschitz-and-the-picard-lindelof-theorem.md)), it is the rod's tilt.

### Step 4: the radius is set by the nearest bad point, even an invisible one

Airy's coefficient, x, is fine everywhere. A second case has a limit: (1 + x^2) y'' + 2x y' = 0, y(0) = 0, y'(0) = 1, is solved by arctan x, whose rate is 1/(1 + x^2). Here P = 2x / (1 + x^2), smooth on the whole real line. But 1 + x^2 is zero at ±i, the complex numbers whose square is −1, at distance 1 from 0.

A power series converges on a disc in the complex plane, never past a point where its function fails ([Power series in the plane](../../07-Complex%20analysis/02-Holomorphic%20Functions/02-complex-power-series.md)). Matching gives a_{n+2} = −n a_n / (n + 2): x − x^3/3 + x^5/5 − …, radius 1. It converges at x = 0.5 and flies apart at x = 2, where arctan is 1.107149.

<details>
<summary>Detailed proof: the series reaches at least as far as P and Q do</summary>

Let P = Σ p_k x^k and Q = Σ q_k x^k converge for |x| < ρ; fix r < ρ. Their terms at r are bounded, so |p_k|, |q_k| ≤ M r^(−k). Matching x^n gives
(n + 2)(n + 1) a_(n+2) = −Σ from k = 0 to n of [(k + 1) a_(k+1) p_(n−k) + a_k q_(n−k)].

Take positive b_0 ≥ |a_0|, b_1 ≥ |a_1| and define
(n + 2)(n + 1) b_(n+2) = M T_n, with T_n = Σ from k = 0 to n of [(k + 1) b_(k+1) + b_k] r^(k−n).
By induction and the triangle inequality, |a_n| ≤ b_n.

Since T_n = T_(n−1) / r + (n + 1) b_(n+1) + b_n and M T_(n−1) = (n + 1) n b_(n+1),
b_(n+2) / b_(n+1) = n / ((n + 2) r) + M / (n + 2) + M b_n / ((n + 2)(n + 1) b_(n+1)).
The first term keeps the ratio above 1/(3r), so the last shrinks to 0 and the ratio tends to 1/r. By the ratio test Σ b_n |x|^n, hence Σ a_n x^n, converges for |x| < r. As r < ρ was arbitrary, the radius is at least ρ.

</details>

A second road needs no series: step the equation up the rod with Runge-Kutta 4 ([Runge-Kutta four](../05-Numerical%20Evolution/04-runge-kutta-four.md)).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| a_0, a_1, a_2 | y(0), y'(0), the x^0 match | 1, 0, 0 |
| a_3, a_6 | 1 / (3 × 2), then ÷ (6 × 5) | 1/6, 1/180 |
| a_9, a_12 | ÷ (9 × 8), then ÷ (12 × 11) | 1/12960, 1/1710720 |
| sums at the clamp, x = 1 | 1 + 1/6, + 1/180, + 1/12960 | 1.166667, 1.172222, 1.172299 |
| series to x^30 | later terms add 0.000000003 | **1.1723** |
| tip tilt, 2-degree clamp | 2 / 1.1723 | **1.706 degrees** |

The 865.9 mm rod straightens under its own weight from 2 degrees at the clamp to 1.706 at the tip.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Stop at 1 + x^3/6 | 1.166667; at x = 3, 5.50 not 11.42 | dropped terms grow with x |
| Freeze x at 1, so y'' = y, y = cosh x | 1.543081, not 1.172300 | the clamp's tension, applied all the way down |
| Sum the arctan series at x = 2 | 44.3, −21580.2, −11157818536.0 after 5, 10, 20 terms, not 1.107149 | x = 2 is outside the radius 1 set by ±i |

---

## Code, from first principles, and it actually runs

Two roads to the clamp's tilt: the series summed to x^30, and Runge-Kutta 4 steps that never see a coefficient, whose error falls about 16-fold per halved step. For arctan, the code finds ±i, estimates the radius from the coefficients, and tests the series inside and outside it.

### Python

```python
# Power series at an ordinary point -- the check behind the card.  Standard library
# only.  A 2 mm steel rod hangs from a tilted clamp; its tilt y at height x above the
# free tip (x in natural lengths) obeys Airy's y'' = x y, y(0) = 1, y'(0) = 0.  Road one:
# the coefficient recurrence, summed.  Road two: Runge-Kutta 4.  Second case: arctan.
import math

def horner(a, x):                        # a[0] + a[1] x + a[2] x^2 + ...
    s = 0.0
    for c in reversed(a):
        s = s * x + c
    return s

def rk4(f, x, s, x1, n):                 # s = [y, y'], f returns [y', y'']
    h = (x1 - x) / n
    for _ in range(n):
        k1 = f(x, s)
        k2 = f(x + h / 2, [s[i] + h / 2 * k1[i] for i in (0, 1)])
        k3 = f(x + h / 2, [s[i] + h / 2 * k2[i] for i in (0, 1)])
        k4 = f(x + h, [s[i] + h * k3[i] for i in (0, 1)])
        s = [s[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in (0, 1)]
        x += h
    return s[0]

airy = lambda x, s: [s[1], x * s[0]]
atan_eq = lambda x, s: [s[1], -2 * x * s[1] / (1 + x * x)]
a = [1.0, 0.0, 0.0] + [0.0] * 30         # a_(n+3) = a_n / ((n + 3)(n + 2))
for n in range(30):
    a[n + 3] = a[n] / ((n + 3) * (n + 2))
b = [0.0, 1.0] + [0.0] * 400             # a_(n+2) = -n a_n / (n + 2)
for n in range(1, 400):
    b[n + 2] = -n * b[n] / (n + 2)
ell = (200e9 * 0.002 ** 2 / (16 * 7850 * 9.81)) ** (1 / 3)
print(f"natural length (E d^2 / (16 rho g))^(1/3), 2 mm steel: {ell * 1000:.1f} mm")
print("1/a3, 1/a6, 1/a9, 1/a12:", " ".join(f"{1 / a[k]:.0f}" for k in (3, 6, 9, 12)))
print("partial sums at x = 1, degree 3/6/9/12:", " ".join(f"{horner(a[:d + 1], 1.0):.9f}" for d in (3, 6, 9, 12)))
y1 = horner(a, 1.0)
print(f"series to degree 30 at x = 1: {y1:.12f}")
errs = [rk4(airy, 0.0, [1.0, 0.0], 1.0, n) - y1 for n in (5, 10, 20)]
print("RK4 errors x 1e9 at h = 0.2/0.1/0.05:", " ".join(f"{e * 1e9:.1f}" for e in errs))
print(f"error ratio when h halves: {errs[0] / errs[1]:.1f}, {errs[1] / errs[2]:.1f}")
print(f"clamp tilted 2.000 deg: tip tilt {2 / y1:.3f} deg")
print("Airy ratio ((n+3)(n+2))^(1/3) at n = 30, 300:", " ".join(f"{((n + 3) * (n + 2)) ** (1 / 3):.1f}" for n in (30, 300)))
dist = math.sqrt(4 * 1 * 1 - 0 * 0) / 2  # 1 + x^2 = 0: roots 0 +/- (sqrt(4ac - b^2) / 2a) i
print(f"second case: 1 + x^2 = 0 at 0 +/- {dist:.3f}i, distance {dist:.3f}")
est = math.sqrt(abs(b[399] / b[401]))
print(f"ratio estimate sqrt|a_399 / a_401|: {est:.5f}")
s05, r05 = horner(b[:41], 0.5), rk4(atan_eq, 0.0, [0.0, 1.0], 0.5, 40)
print(f"at x = 0.5: series 20 terms {s05:.9f}, RK4 {r05:.9f}")
r2 = rk4(atan_eq, 0.0, [0.0, 1.0], 2.0, 200)
print("at x = 2: series 5/10/20 terms", " ".join(f"{horner(b[:2 * k + 1], 2.0):.1f}" for k in (5, 10, 20)) + f"; RK4 {r2:.9f}")
print(f"mistake, x frozen at 1 (y'' = y, y = cosh x): y(1) = {(math.exp(1) + math.exp(-1)) / 2:.6f}")
xs = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
print("figure, x:          ", " ".join(f"{x:5.2f}" for x in xs))
print("figure, series y:   ", " ".join(f"{horner(a, x):5.2f}" for x in xs))
print("figure, 1 + x^3/6:  ", " ".join(f"{1 + x ** 3 / 6:5.2f}" for x in xs))
assert abs(rk4(airy, 0.0, [1.0, 0.0], 1.0, 80) - y1) < 1e-9          # two roads, one tilt
assert 14 < errs[0] / errs[1] < 18 and 14 < errs[1] / errs[2] < 18  # fourth order
assert abs(s05 - r05) < 1e-9 and abs(horner(b[:41], 2.0)) > 100 * r2  # inside vs outside radius
assert abs(est - dist) < 0.01                                        # radius = distance to +/- i
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
natural length (E d^2 / (16 rho g))^(1/3), 2 mm steel: 865.9 mm
1/a3, 1/a6, 1/a9, 1/a12: 6 180 12960 1710720
partial sums at x = 1, degree 3/6/9/12: 1.166666667 1.172222222 1.172299383 1.172299967
series to degree 30 at x = 1: 1.172299970058
RK4 errors x 1e9 at h = 0.2/0.1/0.05: -6272.6 -374.9 -22.9
error ratio when h halves: 16.7, 16.4
clamp tilted 2.000 deg: tip tilt 1.706 deg
Airy ratio ((n+3)(n+2))^(1/3) at n = 30, 300: 10.2 45.1
second case: 1 + x^2 = 0 at 0 +/- 1.000i, distance 1.000
ratio estimate sqrt|a_399 / a_401|: 1.00250
at x = 0.5: series 20 terms 0.463647609, RK4 0.463647609
at x = 2: series 5/10/20 terms 44.3 -21580.2 -11157818536.0; RK4 1.107148718
mistake, x frozen at 1 (y'' = y, y = cosh x): y(1) = 1.543081
figure, x:            0.00  0.50  1.00  1.50  2.00  2.50  3.00
figure, series y:     1.00  1.02  1.17  1.63  2.73  5.29 11.42
figure, 1 + x^3/6:    1.00  1.02  1.17  1.56  2.33  3.60  5.50
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Power series at an ordinary point -- the same check as the Python, in Rust.  No
// crates.  A 2 mm steel rod hangs from a tilted clamp; its tilt y at height x above the
// free tip (x in natural lengths) obeys Airy's y'' = x y, y(0) = 1, y'(0) = 0.  Road one:
// the coefficient recurrence, summed.  Road two: Runge-Kutta 4.  Second case: arctan.

fn horner(a: &[f64], x: f64) -> f64 {            // a[0] + a[1] x + a[2] x^2 + ...
    a.iter().rev().fold(0.0, |s, &c| s * x + c)
}

fn rk4(f: fn(f64, [f64; 2]) -> [f64; 2], mut x: f64, mut s: [f64; 2], x1: f64, n: usize) -> f64 {
    let h = (x1 - x) / n as f64;                 // s = [y, y'], f returns [y', y'']
    let add = |s: [f64; 2], k: [f64; 2], c: f64| [s[0] + c * k[0], s[1] + c * k[1]];
    for _ in 0..n {
        let k1 = f(x, s);
        let k2 = f(x + h / 2.0, add(s, k1, h / 2.0));
        let k3 = f(x + h / 2.0, add(s, k2, h / 2.0));
        let k4 = f(x + h, add(s, k3, h));
        s = [0, 1].map(|i| s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]));
        x += h;
    }
    s[0]
}

fn airy(x: f64, s: [f64; 2]) -> [f64; 2] { [s[1], x * s[0]] }
fn atan_eq(x: f64, s: [f64; 2]) -> [f64; 2] { [s[1], -2.0 * x * s[1] / (1.0 + x * x)] }
fn join(v: Vec<String>) -> String { v.join(" ") }

fn main() {
    let mut a = vec![0.0; 33];                   // a_(n+3) = a_n / ((n + 3)(n + 2))
    a[0] = 1.0;
    for n in 0..30 { a[n + 3] = a[n] / ((n + 3) * (n + 2)) as f64 }
    let mut b = vec![0.0; 402];                  // a_(n+2) = -n a_n / (n + 2)
    b[1] = 1.0;
    for n in 1..400 { b[n + 2] = -(n as f64) * b[n] / (n + 2) as f64 }
    let ell = (200e9 * 0.002f64.powi(2) / (16.0 * 7850.0 * 9.81)).powf(1.0 / 3.0);
    println!("natural length (E d^2 / (16 rho g))^(1/3), 2 mm steel: {:.1} mm", ell * 1000.0);
    println!("1/a3, 1/a6, 1/a9, 1/a12: {}", join([3, 6, 9, 12].iter().map(|&k| format!("{:.0}", 1.0 / a[k])).collect()));
    println!("partial sums at x = 1, degree 3/6/9/12: {}",
             join([3, 6, 9, 12].iter().map(|&d| format!("{:.9}", horner(&a[..d + 1], 1.0))).collect()));
    let y1 = horner(&a, 1.0);
    println!("series to degree 30 at x = 1: {:.12}", y1);
    let errs: Vec<f64> = [5, 10, 20].iter().map(|&n| rk4(airy, 0.0, [1.0, 0.0], 1.0, n) - y1).collect();
    println!("RK4 errors x 1e9 at h = 0.2/0.1/0.05: {}", join(errs.iter().map(|e| format!("{:.1}", e * 1e9)).collect()));
    println!("error ratio when h halves: {:.1}, {:.1}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("clamp tilted 2.000 deg: tip tilt {:.3} deg", 2.0 / y1);
    println!("Airy ratio ((n+3)(n+2))^(1/3) at n = 30, 300: {}",
             join([30.0f64, 300.0].iter().map(|n| format!("{:.1}", ((n + 3.0) * (n + 2.0)).powf(1.0 / 3.0))).collect()));
    let dist = (4.0f64 * 1.0 * 1.0 - 0.0 * 0.0).sqrt() / 2.0; // 1 + x^2 = 0: roots 0 +/- (sqrt(4ac - b^2) / 2a) i
    println!("second case: 1 + x^2 = 0 at 0 +/- {:.3}i, distance {:.3}", dist, dist);
    let est = (b[399] / b[401]).abs().sqrt();
    println!("ratio estimate sqrt|a_399 / a_401|: {:.5}", est);
    let (s05, r05) = (horner(&b[..41], 0.5), rk4(atan_eq, 0.0, [0.0, 1.0], 0.5, 40));
    println!("at x = 0.5: series 20 terms {:.9}, RK4 {:.9}", s05, r05);
    let r2 = rk4(atan_eq, 0.0, [0.0, 1.0], 2.0, 200);
    println!("at x = 2: series 5/10/20 terms {}; RK4 {:.9}",
             join([5, 10, 20].iter().map(|&k| format!("{:.1}", horner(&b[..2 * k + 1], 2.0))).collect()), r2);
    println!("mistake, x frozen at 1 (y'' = y, y = cosh x): y(1) = {:.6}", (1f64.exp() + (-1f64).exp()) / 2.0);
    let xs = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
    println!("figure, x:           {}", join(xs.iter().map(|x| format!("{:5.2}", x)).collect()));
    println!("figure, series y:    {}", join(xs.iter().map(|&x| format!("{:5.2}", horner(&a, x))).collect()));
    println!("figure, 1 + x^3/6:   {}", join(xs.iter().map(|x| format!("{:5.2}", 1.0 + x * x * x / 6.0)).collect()));
    assert!((rk4(airy, 0.0, [1.0, 0.0], 1.0, 80) - y1).abs() < 1e-9);          // two roads, one tilt
    assert!(14.0 < errs[0] / errs[1] && errs[0] / errs[1] < 18.0 && 14.0 < errs[1] / errs[2] && errs[1] / errs[2] < 18.0);
    assert!((s05 - r05).abs() < 1e-9 && horner(&b[..41], 2.0).abs() > 100.0 * r2); // inside vs outside radius
    assert!((est - dist).abs() < 0.01);                                        // radius = distance to +/- i
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
natural length (E d^2 / (16 rho g))^(1/3), 2 mm steel: 865.9 mm
1/a3, 1/a6, 1/a9, 1/a12: 6 180 12960 1710720
partial sums at x = 1, degree 3/6/9/12: 1.166666667 1.172222222 1.172299383 1.172299967
series to degree 30 at x = 1: 1.172299970058
RK4 errors x 1e9 at h = 0.2/0.1/0.05: -6272.6 -374.9 -22.9
error ratio when h halves: 16.7, 16.4
clamp tilted 2.000 deg: tip tilt 1.706 deg
Airy ratio ((n+3)(n+2))^(1/3) at n = 30, 300: 10.2 45.1
second case: 1 + x^2 = 0 at 0 +/- 1.000i, distance 1.000
ratio estimate sqrt|a_399 / a_401|: 1.00250
at x = 0.5: series 20 terms 0.463647609, RK4 0.463647609
at x = 2: series 5/10/20 terms 44.3 -21580.2 -11157818536.0; RK4 1.107148718
mistake, x frozen at 1 (y'' = y, y = cosh x): y(1) = 1.543081
figure, x:            0.00  0.50  1.00  1.50  2.00  2.50  3.00
figure, series y:     1.00  1.02  1.17  1.63  2.73  5.29 11.42
figure, 1 + x^3/6:    1.00  1.02  1.17  1.56  2.33  3.60  5.50
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the radius promise for every linear equation of this kind, and both cases on this card.

- When P and Q are power series, the matched coefficients give a series reaching at least as far as both, whatever a_0 and a_1 are.
- Airy's series, with a_0 = 1 and a_1 = 0, converges for every x, and its sum solves y'' = x y with y(0) = 1, y'(0) = 0.
- The arctan coefficients, from a_(n+2) = −n a_n / (n + 2), give a series of radius exactly 1.
- The worked numbers hold: a_3 = 1/6, a_6 = 1/180, a_9 = 1/12960, a_12 = 1/1710720, and arctan's −1/3 and 1/5.

Python and Rust check the rest: the rod's natural length, the sums at the clamp, the 1.706-degree tip, and the Runge-Kutta 4 match.

```lean
-- Series solutions: the coefficients that y'' + P y' + Q y = 0 forces on a power series converge at least as far as P and Q do, Airy's series solves the hanging rod's equation, and the arctan series has radius 1.
import Mathlib.Analysis.Analytic.OfScalars
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib

open Finset FormalMultilinearSeries

lemma series_solution_coeff_bound (p q a : ℕ → ℂ)
    (ha : ∀ n : ℕ, ((n : ℂ) + 2) * ((n : ℂ) + 1) * a (n + 2) =
      -∑ k ∈ range (n + 1), (((k : ℂ) + 1) * a (k + 1) * p (n - k) + a k * q (n - k)))
    (ρ r M : ℝ) (hρ : 0 < ρ) (hρr : ρ < r)
    (hp : ∀ n, ‖p n‖ * r ^ n ≤ M) (hq : ∀ n, ‖q n‖ * r ^ n ≤ M) :
    ∃ K, ∀ n, ‖a n‖ * ρ ^ n ≤ K := by
  have hr : 0 < r := hρ.trans hρr
  have hM : 0 ≤ M := le_trans (by positivity) (hp 0)
  set t : ℝ := ρ / r with ht
  have ht0 : 0 < t := by positivity
  have ht1 : t < 1 := by rw [ht, div_lt_one hr]; exact hρr
  set c : ℝ := M / (1 - t) with hc
  have hc0 : 0 ≤ c := div_nonneg hM (by linarith)
  obtain ⟨N, hN⟩ := exists_nat_ge (c * (ρ + ρ ^ 2))
  set K : ℝ := ∑ j ∈ range (N + 2), ‖a j‖ * ρ ^ j with hK
  have hK0 : 0 ≤ K := sum_nonneg (fun j _ => by positivity)
  refine ⟨K, fun n => ?_⟩
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    by_cases hn : n < N + 2
    · exact single_le_sum (f := fun j => ‖a j‖ * ρ ^ j) (fun j _ => by positivity)
        (mem_range.2 hn)
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
    have hm : N ≤ m := by omega
    have hmR : (N : ℝ) ≤ m := by exact_mod_cast hm
    -- termwise bound
    have hterm : ∀ k ∈ range (m + 1),
        ‖((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k)‖ * ρ ^ (m + 2) ≤
          K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * t ^ (m - k) := by
      intro k hk
      have hkm : k ≤ m := by rw [mem_range] at hk; omega
      obtain ⟨j, hj⟩ : ∃ j, m = k + j := ⟨m - k, by omega⟩
      have hmk : m - k = j := by omega
      rw [hmk]
      have hk1 : ‖(k : ℂ) + 1‖ = (k : ℝ) + 1 := by
        rw [show (k : ℂ) + 1 = ((k + 1 : ℕ) : ℂ) by push_cast; ring, Complex.norm_natCast]
        push_cast; ring
      have hA1 : ‖a (k + 1)‖ * ρ ^ (k + 1) ≤ K := ih (k + 1) (by omega)
      have hA0 : ‖a k‖ * ρ ^ k ≤ K := ih k (by omega)
      have hpj := hp j
      have hqj := hq j
      have hρj : ρ ^ j = t ^ j * r ^ j := by
        rw [ht, div_pow, div_mul_cancel₀ _ (by positivity)]
      have hkR : (k : ℝ) ≤ m := by exact_mod_cast hkm
      calc ‖((k : ℂ) + 1) * a (k + 1) * p j + a k * q j‖ * ρ ^ (m + 2)
          ≤ (((k : ℝ) + 1) * ‖a (k + 1)‖ * ‖p j‖ + ‖a k‖ * ‖q j‖) * ρ ^ (m + 2) := by
            gcongr
            refine (norm_add_le _ _).trans ?_
            rw [norm_mul, norm_mul, norm_mul, hk1]
        _ = ((k : ℝ) + 1) * (‖a (k + 1)‖ * ρ ^ (k + 1)) * (‖p j‖ * r ^ j) * ρ * t ^ j
            + (‖a k‖ * ρ ^ k) * (‖q j‖ * r ^ j) * ρ ^ 2 * t ^ j := by
            rw [hj, show ρ ^ (k + j + 2) = ρ ^ k * ρ ^ 2 * ρ ^ j by ring, hρj]
            ring
        _ ≤ ((k : ℝ) + 1) * K * M * ρ * t ^ j + K * M * ρ ^ 2 * t ^ j := by
            gcongr
        _ ≤ ((m : ℝ) + 1) * K * M * ρ * t ^ j + K * M * ρ ^ 2 * t ^ j := by
            gcongr
        _ = K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * t ^ j := by ring
    have hgeom : ∑ k ∈ range (m + 1), t ^ (m - k) ≤ 1 / (1 - t) := by
      have := sum_range_reflect (fun k => t ^ k) (m + 1)
      simp only [Nat.add_sub_cancel] at this
      rw [this, ← Nat.Ico_zero_eq_range]
      simpa using geom_sum_Ico_le_of_lt_one (m := 0) (n := m + 1) ht0.le ht1
    have hsum : ‖∑ k ∈ range (m + 1),
        (((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k))‖ * ρ ^ (m + 2) ≤
          K * (((m : ℝ) + 2) * ((m : ℝ) + 1)) := by
      calc _ ≤ (∑ k ∈ range (m + 1),
              ‖((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k)‖) * ρ ^ (m + 2) := by
            gcongr; exact norm_sum_le _ _
        _ = ∑ k ∈ range (m + 1),
              ‖((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k)‖ * ρ ^ (m + 2) := by
            rw [sum_mul]
        _ ≤ ∑ k ∈ range (m + 1), K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * t ^ (m - k) :=
            sum_le_sum hterm
        _ = K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * ∑ k ∈ range (m + 1), t ^ (m - k) := by
            rw [mul_sum]
        _ ≤ K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * (1 / (1 - t)) := by gcongr
        _ = K * (c * (((m : ℝ) + 1) * ρ + ρ ^ 2)) := by rw [hc]; ring
        _ ≤ K * (((m : ℝ) + 2) * ((m : ℝ) + 1)) := by
            apply mul_le_mul_of_nonneg_left _ hK0
            have h1 : c * (((m : ℝ) + 1) * ρ + ρ ^ 2) ≤ ((m : ℝ) + 1) * (c * (ρ + ρ ^ 2)) := by
              have : (0 : ℝ) ≤ m := by positivity
              have : 0 ≤ c * ρ ^ 2 := by positivity
              nlinarith
            have h2 : c * (ρ + ρ ^ 2) ≤ (m : ℝ) + 2 := by linarith
            have : (0 : ℝ) ≤ m := by positivity
            nlinarith
    have heq := congrArg (fun z : ℂ => ‖z‖) (ha m)
    simp only [norm_neg] at heq
    have hm2 : ‖((m : ℂ) + 2) * ((m : ℂ) + 1)‖ = ((m : ℝ) + 2) * ((m : ℝ) + 1) := by
      rw [show ((m : ℂ) + 2) * ((m : ℂ) + 1) = (((m + 2) * (m + 1) : ℕ) : ℂ) by push_cast; ring,
        Complex.norm_natCast]
      push_cast; ring
    rw [norm_mul, hm2] at heq
    have hpos : (0 : ℝ) < ((m : ℝ) + 2) * ((m : ℝ) + 1) := by positivity
    rw [← heq] at hsum
    have : ((m : ℝ) + 2) * ((m : ℝ) + 1) * (‖a (m + 2)‖ * ρ ^ (m + 2)) ≤
        ((m : ℝ) + 2) * ((m : ℝ) + 1) * K := by
      linarith
    exact le_of_mul_le_mul_left this hpos


lemma airy_coeff_bound (a : ℕ → ℝ)
    (hrec : ∀ n : ℕ, a (n + 3) = a n / (((n : ℝ) + 3) * ((n : ℝ) + 2))) :
    ∀ R : ℝ, 0 < R → ∃ C, ∀ n, |a n| * R ^ n ≤ C := by
  intro R hR
  obtain ⟨N, hN⟩ := exists_nat_ge (R ^ 3)
  refine ⟨∑ j ∈ range (N + 3), |a j| * R ^ j, ?_⟩
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    by_cases hn : n < N + 3
    · exact single_le_sum (f := fun j => |a j| * R ^ j) (fun j _ => by positivity)
        (mem_range.2 hn)
    · obtain ⟨m, rfl⟩ : ∃ m, n = m + 3 := ⟨n - 3, by omega⟩
      have hm : N ≤ m := by omega
      have hih := ih m (by omega)
      have hmN : (N : ℝ) ≤ m := by exact_mod_cast hm
      have hpos : (0 : ℝ) < ((m : ℝ) + 3) * ((m : ℝ) + 2) := by positivity
      have hR3 : R ^ 3 ≤ ((m : ℝ) + 3) * ((m : ℝ) + 2) := by
        have : (0 : ℝ) ≤ m := by positivity
        nlinarith
      rw [hrec, abs_div, abs_of_pos hpos, pow_add]
      calc |a m| / (((m : ℝ) + 3) * ((m : ℝ) + 2)) * (R ^ m * R ^ 3)
          = |a m| * R ^ m * (R ^ 3 / (((m : ℝ) + 3) * ((m : ℝ) + 2))) := by ring
        _ ≤ |a m| * R ^ m * 1 := by
          gcongr
          rw [div_le_one hpos]; exact hR3
        _ ≤ _ := by rw [mul_one]; exact hih

lemma deriv_coeff_bound (c : ℕ → ℝ) (hc : ∀ R : ℝ, 0 < R → ∃ C, ∀ n, |c n| * R ^ n ≤ C) :
    ∀ R : ℝ, 0 < R → ∃ C, ∀ n : ℕ, |((n : ℝ) + 1) * c (n + 1)| * R ^ n ≤ C := by
  intro R hR
  obtain ⟨C, hC⟩ := hc (2 * R) (by positivity)
  refine ⟨C / R, fun n => ?_⟩
  rw [le_div_iff₀ hR, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < (n : ℝ) + 1)]
  have h2 : ((n : ℝ) + 1) ≤ 2 ^ (n + 1) := by
    have := Nat.lt_two_pow_self (n := n + 1)
    exact_mod_cast this.le
  calc ((n : ℝ) + 1) * |c (n + 1)| * R ^ n * R
      = |c (n + 1)| * (((n : ℝ) + 1) * R ^ (n + 1)) := by ring
    _ ≤ |c (n + 1)| * (2 ^ (n + 1) * R ^ (n + 1)) := by gcongr
    _ = |c (n + 1)| * (2 * R) ^ (n + 1) := by ring
    _ ≤ C := hC (n + 1)

lemma series_summable_and_deriv (c : ℕ → ℝ)
    (hc : ∀ R : ℝ, 0 < R → ∃ C, ∀ n, |c n| * R ^ n ≤ C) (x : ℝ) :
    Summable (fun n => c n * x ^ n) ∧
      HasDerivAt (fun z => ∑' n, c n * z ^ n) (∑' n, c n * ((n : ℝ) * x ^ (n - 1))) x := by
  set S : ℝ := |x| + 1 with hS
  have hSpos : 0 < S := by positivity
  obtain ⟨C, hC⟩ := hc (2 * S) (by positivity)
  have hC0 : 0 ≤ C := le_trans (by positivity) (hC 0)
  have hsum : ∀ y : ℝ, |y| < S → Summable (fun n => c n * y ^ n) := by
    intro y hy
    refine Summable.of_norm_bounded (summable_geometric_two.mul_left C) (fun n => ?_)
    rw [Real.norm_eq_abs, abs_mul, abs_pow]
    have h1 : |c n| * |y| ^ n ≤ |c n| * S ^ n := by gcongr
    have h2 : |c n| * S ^ n = |c n| * (2 * S) ^ n * (1 / 2) ^ n := by
      rw [mul_assoc, ← mul_pow, show 2 * S * (1 / 2) = S by ring]
    have h3 : |c n| * (2 * S) ^ n * (1 / 2) ^ n ≤ C * (1 / 2) ^ n := by
      gcongr; exact hC n
    linarith
  refine ⟨hsum x (by rw [hS]; linarith), ?_⟩
  refine hasDerivAt_tsum_of_isPreconnected (t := Metric.ball 0 S) (y₀ := 0)
    (u := fun n : ℕ => C / S * ((n : ℝ) ^ 1 * (1 / 2) ^ n))
    ((summable_pow_mul_geometric_of_norm_lt_one 1 (by norm_num)).mul_left (C / S))
    Metric.isOpen_ball (convex_ball 0 S).isPreconnected
    (fun (n : ℕ) y _ => (hasDerivAt_pow n y).const_mul (c n)) ?_ (Metric.mem_ball_self hSpos)
    (hsum 0 (by simpa using hSpos)) (by rw [Metric.mem_ball, dist_zero_right, Real.norm_eq_abs, hS]; linarith)
  intro n y hy
  rw [Metric.mem_ball, dist_zero_right, Real.norm_eq_abs] at hy
  rw [Real.norm_eq_abs]
  rcases n with _ | n
  · simp
  · simp only [Nat.add_sub_cancel, pow_one]
    rw [abs_mul, abs_mul, abs_pow, abs_of_pos (by positivity : (0 : ℝ) < ((n + 1 : ℕ) : ℝ))]
    have h1 : |y| ^ n ≤ S ^ n := by gcongr
    have hcS := hC (n + 1)
    rw [div_mul_eq_mul_div, le_div_iff₀ hSpos]
    calc |c (n + 1)| * (((n + 1 : ℕ) : ℝ) * |y| ^ n) * S
        ≤ |c (n + 1)| * (((n + 1 : ℕ) : ℝ) * S ^ n) * S := by gcongr
      _ = (|c (n + 1)| * (2 * S) ^ (n + 1)) * (((n + 1 : ℕ) : ℝ) * (1 / 2) ^ (n + 1)) := by
        have key : (2 * S) ^ (n + 1) * (1 / 2) ^ (n + 1) = S ^ (n + 1) := by
          rw [← mul_pow]; ring_nf
        rw [show (|c (n + 1)| * (2 * S) ^ (n + 1)) * (((n + 1 : ℕ) : ℝ) * (1 / 2) ^ (n + 1))
            = |c (n + 1)| * ((n + 1 : ℕ) : ℝ) * ((2 * S) ^ (n + 1) * (1 / 2) ^ (n + 1)) by ring,
          key]
        ring
      _ ≤ C * (((n + 1 : ℕ) : ℝ) * (1 / 2) ^ (n + 1)) := by gcongr


lemma arctan_coeff_closed (b : ℕ → ℝ)
    (h0 : b 0 = 0) (h1 : b 1 = 1)
    (hrec : ∀ n : ℕ, b (n + 2) = -(n : ℝ) * b n / ((n : ℝ) + 2)) (k : ℕ) :
    b (2 * k) = 0 ∧ b (2 * k + 1) = (-1) ^ k / (2 * (k : ℝ) + 1) := by
  induction k with
  | zero => simp [h0, h1]
  | succ k ih =>
    obtain ⟨he, ho⟩ := ih
    constructor
    · rw [show 2 * (k + 1) = 2 * k + 2 by ring, hrec, he]; simp
    · rw [show 2 * (k + 1) + 1 = (2 * k + 1) + 2 by ring, hrec, ho]
      push_cast
      field_simp
      ring

#print axioms series_solution_coeff_bound
#print axioms airy_coeff_bound
#print axioms deriv_coeff_bound
#print axioms series_summable_and_deriv
#print axioms arctan_coeff_closed


/-- The radius promise at an ordinary point. Let P = Σ p_k x^k and Q = Σ q_k x^k be power series,
and let the coefficients a_n of y = Σ a_n x^n obey the rule that matching each power of x in
y'' + P y' + Q y = 0 gives:
(n + 2)(n + 1) a_(n+2) = −Σ_{k=0}^{n} [(k + 1) a_(k+1) p_(n−k) + a_k q_(n−k)].
Then the series for y converges at least as far out (in the complex plane) as both P and Q do,
whatever the starting value a_0 and rate a_1. -/
theorem series_solution_radius_ge_coefficient_radius (p q a : ℕ → ℂ)
    (ha : ∀ n : ℕ, ((n : ℂ) + 2) * ((n : ℂ) + 1) * a (n + 2) =
      -∑ k ∈ range (n + 1), (((k : ℂ) + 1) * a (k + 1) * p (n - k) + a k * q (n - k))) :
    min (ofScalars ℂ p).radius (ofScalars ℂ q).radius ≤ (ofScalars ℂ a).radius := by
  apply ENNReal.le_of_forall_nnreal_lt
  intro ρ hρ
  rcases eq_or_ne ρ 0 with h | h
  · simp [h]
  obtain ⟨r, hρr, hr⟩ := ENNReal.lt_iff_exists_nnreal_btwn.1 hρ
  obtain ⟨Cp, -, hCp⟩ := (ofScalars ℂ p).norm_mul_pow_le_of_lt_radius (hr.trans_le (min_le_left _ _))
  obtain ⟨Cq, -, hCq⟩ := (ofScalars ℂ q).norm_mul_pow_le_of_lt_radius (hr.trans_le (min_le_right _ _))
  simp only [ofScalars_norm] at hCp hCq
  have hρr' : (ρ : ℝ) < r := by exact_mod_cast hρr
  have hρ0 : (0 : ℝ) < ρ := by positivity
  obtain ⟨K, hK⟩ := series_solution_coeff_bound p q a ha ρ r (max Cp Cq) hρ0 hρr'
    (fun n => (hCp n).trans (le_max_left _ _)) (fun n => (hCq n).trans (le_max_right _ _))
  exact (ofScalars ℂ a).le_radius_of_bound K (fun n => by rw [ofScalars_norm]; exact hK n)

/-- Airy's equation for the hanging rod. With a_0 = 1, a_1 = 0, a_2 = 0 and
a_(n+3) = a_n / ((n + 3)(n + 2)), the series Σ a_n x^n converges for every real x, and its sum y
solves y'' = x y with y(0) = 1 and y'(0) = 0. -/
theorem airy_series_solves_airy_equation (a : ℕ → ℝ)
    (h0 : a 0 = 1) (h1 : a 1 = 0) (h2 : a 2 = 0)
    (hrec : ∀ n : ℕ, a (n + 3) = a n / (((n : ℝ) + 3) * ((n : ℝ) + 2))) :
    ∃ y y' : ℝ → ℝ, (∀ x : ℝ, HasSum (fun n => a n * x ^ n) (y x)) ∧
      (∀ x : ℝ, HasDerivAt y (y' x) x) ∧ (∀ x : ℝ, HasDerivAt y' (x * y x) x) ∧
      y 0 = 1 ∧ y' 0 = 0 := by
  have ha := airy_coeff_bound a hrec
  set a' : ℕ → ℝ := fun n => ((n : ℝ) + 1) * a (n + 1) with ha'def
  have ha' := deriv_coeff_bound a ha
  refine ⟨fun z => ∑' n, a n * z ^ n, fun z => ∑' n, a' n * z ^ n, ?_, ?_, ?_, ?_, ?_⟩
  · intro x; exact (series_summable_and_deriv a ha x).1.hasSum
  · intro x
    obtain ⟨-, hd⟩ := series_summable_and_deriv a ha x
    convert hd using 1
    symm
    apply HasSum.tsum_eq
    rw [← hasSum_nat_add_iff' 1]
    simp only [range_one, sum_singleton, Nat.cast_zero, zero_mul, mul_zero, sub_zero]
    convert (series_summable_and_deriv a' ha' x).1.hasSum using 1
    funext n
    simp only [ha'def, Nat.add_sub_cancel]
    push_cast; ring
  · intro x
    obtain ⟨-, hd⟩ := series_summable_and_deriv a' ha' x
    convert hd using 1
    symm
    apply HasSum.tsum_eq
    rw [← hasSum_nat_add_iff' 2]
    have hz : ∑ i ∈ range 2, a' i * ((i : ℝ) * x ^ (i - 1)) = 0 := by
      simp [sum_range_succ, ha'def, h2]
    rw [hz, sub_zero]
    have hs := ((series_summable_and_deriv a ha x).1.hasSum).mul_left x
    convert hs using 1
    funext n
    simp only [ha'def]
    rw [show n + 2 + 1 = n + 3 by ring, hrec n, show n + 2 - 1 = n + 1 by omega]
    have hpos : ((n : ℝ) + 3) * ((n : ℝ) + 2) ≠ 0 := by positivity
    push_cast
    field_simp
    ring
  · simp only
    rw [tsum_eq_single 0 (fun n hn => by simp [zero_pow hn])]
    simp [h0]
  · simp only
    rw [tsum_eq_single 0 (fun n hn => by simp [zero_pow hn])]
    simp [ha'def, h1]

/-- The arctan case: the coefficients from (1 + x^2) y'' + 2x y' = 0 with y(0) = 0, y'(0) = 1,
namely a_0 = 0, a_1 = 1 and a_(n+2) = −n a_n / (n + 2), give a power series of radius exactly 1,
the distance from 0 to the bad points ±i. -/
theorem arctan_series_radius_eq_one (b : ℕ → ℝ)
    (h0 : b 0 = 0) (h1 : b 1 = 1)
    (hrec : ∀ n : ℕ, b (n + 2) = -(n : ℝ) * b n / ((n : ℝ) + 2)) :
    (ofScalars ℝ b).radius = 1 := by
  have hc := arctan_coeff_closed b h0 h1 hrec
  have hle : ∀ n, |b n| ≤ 1 := by
    intro n
    obtain ⟨k, rfl | rfl⟩ := Nat.even_or_odd' n
    · rw [(hc k).1]; simp
    · rw [(hc k).2, abs_div, abs_pow, abs_neg, abs_one, one_pow]
      rw [abs_of_pos (by positivity)]
      rw [div_le_one (by positivity)]
      have : (0 : ℝ) ≤ k := by positivity
      linarith
  apply le_antisymm
  · by_contra hcon
    rw [not_le] at hcon
    obtain ⟨r, hr1, hr⟩ := ENNReal.lt_iff_exists_nnreal_btwn.1 hcon
    obtain ⟨C, hC, hb⟩ := (ofScalars ℝ b).norm_mul_pow_le_of_lt_radius hr
    have hr1' : (1 : ℝ) < r := by exact_mod_cast hr1
    have ht := tendsto_pow_const_div_const_pow_of_one_lt 1 hr1'
    have hev := (ht.eventually (gt_mem_nhds (show (0:ℝ) < 1 / (C + 1) by positivity)))
    obtain ⟨N, hN⟩ := Filter.eventually_atTop.1 hev
    have h1 := hN (2 * N + 1) (by omega)
    have h2 := hb (2 * N + 1)
    rw [ofScalars_norm, Real.norm_eq_abs, (hc N).2, abs_div, abs_pow, abs_neg, abs_one,
      one_pow, abs_of_pos (by positivity)] at h2
    have hx : (0 : ℝ) < (r : ℝ) ^ (2 * N + 1) := by positivity
    set x := (r : ℝ) ^ (2 * N + 1)
    have hy : (0 : ℝ) < 2 * (N : ℝ) + 1 := by positivity
    simp only [pow_one] at h1
    push_cast at h1
    rw [div_lt_div_iff₀ hx (by positivity)] at h1
    rw [div_mul_eq_mul_div, div_le_iff₀ hy] at h2
    nlinarith
  · have := (ofScalars ℝ b).le_radius_of_bound 1 (r := 1) (fun n => by
      rw [ofScalars_norm, Real.norm_eq_abs]; simpa using hle n)
    simpa using this

-- Worked numbers: a_3 = 1/6, a_6 = 1/180, a_9 = 1/12960, a_12 = 1/1710720.
example : (1 : ℚ) / (3 * 2) = 1 / 6 := by norm_num
example : ((1 : ℚ) / 6) / (6 * 5) = 1 / 180 := by norm_num
example : ((1 : ℚ) / 180) / (9 * 8) = 1 / 12960 := by norm_num
example : ((1 : ℚ) / 12960) / (12 * 11) = 1 / 1710720 := by norm_num
-- Arctan coefficients: a_3 = −1/3, a_5 = 1/5.
example : -(1 : ℚ) * 1 / (1 + 2) = -1 / 3 := by norm_num
example : -(3 : ℚ) * (-1 / 3) / (3 + 2) = 1 / 5 := by norm_num

#print axioms series_solution_radius_ge_coefficient_radius
#print axioms airy_series_solves_airy_equation
#print axioms arctan_series_radius_eq_one
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'series_solution_coeff_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'airy_coeff_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'deriv_coeff_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'series_summable_and_deriv' depends on axioms: [propext, Classical.choice, Quot.sound]
'arctan_coeff_closed' depends on axioms: [propext, Classical.choice, Quot.sound]
'series_solution_radius_ge_coefficient_radius' depends on axioms: [propext, Classical.choice, Quot.sound]
'airy_series_solves_airy_equation' depends on axioms: [propext, Classical.choice, Quot.sound]
'arctan_series_radius_eq_one' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A thicker rod.** Change `0.002` to `0.004`. The natural length grows by 2^(2/3), to 1374.6 mm (the label still says 2 mm).
> - **The index slip.** In the loop filling `a`, change `(n + 3) * (n + 2)` to `(n + 2) * (n + 1)`. The sum at x = 1 becomes 1.525451 and the first assert stops the run: Runge-Kutta 4 never saw the slip.
> - **The edge of the radius.** Change both `0.5`s on the `s05` line to `0.99`. The series gives 0.772019 against 0.780373 stepped, and the third assert stops the run.

---

## The usual mistake

> [!warning]
> **Reading the radius off the real line.** 2x / (1 + x^2) is smooth for every real x, yet the arctan series stops at radius 1, because 1 + x^2 vanishes at ±i.
>
> - **Dropping the x^0 match.** Without a_2 = 0 a false third chain appears.
> - **Shifting the index.** Dividing by (n + 2)(n + 1) instead: Try changing shows what it costs.
> - **A partial sum as the answer.** 1 + x^3/6 gives 1.166667, not 1.172300.

---

## Where you meet it in real life

- **Optics.** Airy's function sets the brightness at a rainbow's edge.
- **Standing columns.** With the sign flipped, it sets the tallest pole that stands under its own weight.
- **Quantum mechanics.** The quantum oscillator runs the same method on another equation.

> **Say it back**
> When a linear equation's coefficients are power series at a point, so are its solutions. Matching each power of x turns the equation into a rule for each coefficient; the starting value and rate fill the first two. For the hanging rod that gives 1 + x^3/6 + x^6/180 + …, a clamp tilt 1.1723 times the tip's. The series reaches at least the nearest complex point where a coefficient fails, which is why arctan's stops at 1.

---

## What this builds on

- [Superposition](../03-Oscillators%20-%20Second-Order%20Linear%20Equations/01-superposition-and-the-shape-of-linear-solutions.md): a_0 and a_1 pick the mix of two basic solutions.
- [Power series](../../06-Calculus%20and%20analysis/06-Series/04-power-series.md): the radius of convergence and term-by-term rates.
- [Taylor series](../../06-Calculus%20and%20analysis/06-Series/05-taylor-series.md): why a_0 and a_1 are the starting value and rate.
- [Power series in the plane](../../07-Complex%20analysis/02-Holomorphic%20Functions/02-complex-power-series.md): why a series stops at the nearest complex bad point.

## Where this goes next

- [Frobenius](02-frobenius-and-regular-singular-points.md): a series centred at a bad point, times a power of x.
- [Legendre's equation](04-legendre-polynomials.md): a recurrence that stops by itself.
- [The quantum oscillator](../../13-Engineering%20mathematics/09-Quantum%20Mechanics%20in%20Outline/04-quantum-harmonic-oscillator.md): a series forced to stop, so energy comes in steps.

The method needs P and Q to be power series at the centre; what to do at a point where one fails, as 1/x does at 0, is [Frobenius](02-frobenius-and-regular-singular-points.md).

---

## Sources

Verified 2026-11-12: every link below resolves to the publisher's page.

- Boyce, William E., Richard C. DiPrima and Douglas B. Meade. *Elementary Differential Equations and Boundary Value Problems*, 12th ed. Wiley. [Publisher page](https://www.wiley.com/en-us/Elementary+Differential+Equations+and+Boundary+Value+Problems%2C+12th+Edition-p-9781119777694). Series near an ordinary point; the radius theorem.
- Lebl, Jiří. *Notes on Diffy Qs*, §7.2. [Series solutions](https://www.jirka.org/diffyqs/html/seriessols_section.html). Works Airy's equation.
- Teschl, Gerald. *Ordinary Differential Equations and Dynamical Systems*. [Author's page and free text](https://www.mat.univie.ac.at/~gerald/ftp/book-ode/). Section 4.1: convergence for analytic coefficients.
- NIST Digital Library of Mathematical Functions. [§9.2 Differential Equation](https://dlmf.nist.gov/9.2). Airy's equation and its standard solutions.
