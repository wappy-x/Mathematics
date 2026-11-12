# Sturm-Liouville: the standard form whose modes are real, perpendicular under a weight, and rich enough to expand functions in

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Series Solutions and Boundary Problems](../README.md#s07) → Sturm-Liouville

---

## General Overview

A string 1 m long is pinned at both ends. It vibrates in a mix of pure shapes called modes: one arch, two arches, three, each at its own pitch ([Eigenvalue problems](08-eigenvalues-and-eigenfunctions.md)). Multiply the one-arch shape by the two-arch shape, point by point, and integrate along the string. The answer is exactly 0.

A round drum skin of radius 1 m has ring-shaped modes built from Bessel's function ([Bessel's equation](03-bessels-equation-and-the-drum.md)). Multiply two and integrate along a radius: 0.196082, not 0. Count each point by its ring's circumference, which grows with the radius, and the answer is 0 again.

Both are one theorem about equations in the Sturm-Liouville form, and the cancellation is what splits any starting shape into modes, one pitch at a time.

**Put the equation in Sturm-Liouville form and, under shared end conditions, every eigenvalue is real and any two different modes integrate to zero against the form's weight.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; that every shape is a sum of modes is stated here and proved on Compact and symmetric.

### The picture: two string modes cancel

<p align="center"><img src="../figures/sturm-liouville-and-orthogonality.svg" alt="The string modes sin(pi x) and sin(2 pi x) on a 1 m string, and their product, whose two shaded lobes have equal and opposite area" width="420"></p>

To scale: 280 px per metre across, 100 px per unit up. Dashed: sin(πx). Dotted: sin(2πx). Shaded: their product, lobes of area +0.212207 and −0.212207, peak 0.7698 at x = 0.3041 m.

---

## The formula

Notation first: y' is the slope along the string, and (p y')' the rate of change of p times the slope. A **mode** is a nonzero shape y solving the equation below with the end conditions; its number λ is its **eigenvalue**. The Sturm-Liouville form:

$$-\big(p(x)\,y'\big)' + q(x)\,y = \lambda\, w(x)\, y, \qquad a < x < b .$$

**Read it aloud:** minus the rate of (stiffness times slope), plus the potential times the shape, equals the eigenvalue times the weight times the shape.

The left side is $L$ for short. Each end has one condition: y = 0, or p y' = 0, or a fixed real ratio of the two. The conclusion:

$$\int_a^b w(x)\,y_m(x)\,y_n(x)\,dx = 0 \quad (m \ne n), \qquad c_n = \frac{\int_a^b w\,f\,y_n\,dx}{\int_a^b w\,y_n^{2}\,dx}.$$

**Read it aloud:** two different modes, multiplied and weighted, integrate to zero; the amount of mode n in a shape f is their weighted overlap over the mode's weighted size.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$, $r$, $a$, $b$ | position: m along the string, drum radii from the centre; ends a and b | 0 to 1 on both | — |
| $y$, $y_n$, $u$, $v$ | a mode's shape; mode number n; two modes compared | sin(nπx); J0(j1 r) | — |
| $p$, $B$ | stiffness; B is the slope coefficient it is built from | p = 1 string, p = r drum | higher eigenvalues |
| $q$, $L$ | a potential, like springs under the string; L is the left side | q = 0 on both | eigenvalues shift up |
| $w$ | the weight: how much each point counts | w = 1 string, w = r drum | lower eigenvalues |
| $\lambda$, $\lambda_n$, $\mu$ | eigenvalues: the square of each mode's wave number | n^2 π^2 string; j1^2 drum | a faster mode |
| $f$, $c_n$, $N$ | a starting shape, in cm; amount of mode n; modes kept | x(1 − x); c1 = 0.258012 | closer to f |
| $J_0$, $J_1$, $j_1$, $j_2$ | Bessel's functions of order 0 and 1; J0's first two zeros | 2.404825558, 5.520078110 | — |

### When it holds

- **p and w positive inside the interval.** A sign-changing weight can give a mode size 0, and c_n cannot be divided out. p may reach 0 at an end, as the drum's does, if modes stay finite there.
- **p, q and w real.** An absorbing medium's complex coefficient gives complex eigenvalues.
- **The same end conditions for both modes.** The free-end constant 1 against the pinned sin(πx) integrates to 0.636620.
- **For the expansion, the integral of w f^2 finite.** The sum then reaches f on average, and pointwise inside the interval where f is smooth.

---

## Why it works

### Step 0: the operator behaves like a symmetric matrix

A symmetric matrix A, with u · Av equal to v · Au for all vectors u and v, has real eigenvalues and perpendicular eigenvectors. For functions the integral of a product is the dot product ([Gram-Schmidt](../../03-Algebra/06-Dot%20Products%20and%20Best%20Fits/03-gram-schmidt-and-orthonormal-bases.md)). The Sturm-Liouville form is the shape that makes the integral of u L v equal that of v L u.

### Step 1: put the equation in the form

Take y'' + B(x) y' + (a multiple of y) = −λ y. Multiply through by $p$ = e raised to the integral of B. Then p' = p B, so p y'' + p B y' is (p y')', the product rule backwards. Whatever now multiplies λ is the weight.

The drum's ring modes solve y'' + (1/r) y' + λ y = 0, with y(1) = 0 at the rim. B = 1/r integrates to ln r, so p = r: (r y')' + λ r y = 0, with weight r, the overview's circumference factor. The string already has p = w = 1.

### Step 2: the two-sided integration by parts

Take shapes u and v with the same end conditions. Integrate u (p v')' by parts twice ([Integration by parts](../../06-Calculus%20and%20analysis/04-Integrals/04-integration-by-parts.md)); each round moves a derivative from v to u and leaves an end term, and the middle pieces p u' v' cancel:

$$\int_a^b (u\,Lv - v\,Lu)\,dx = \Big[\,p\,(u'v - u\,v')\,\Big]_a^b .$$

This is **Lagrange's identity**; q u v appears on both sides and drops out. At a pinned end u = v = 0, so the bracket is 0; at the drum's centre p = r = 0 kills it.

### Step 3: different modes are perpendicular under the weight

Let u be a mode with eigenvalue λ and v one with eigenvalue μ. Then Lu = λ w u and Lv = μ w v. The identity's right side is 0, so

$$(\mu - \lambda)\int_a^b w\,u\,v\,dx = 0 .$$

If μ ≠ λ the weighted integral must vanish. On the drum, λ = j1^2 and μ = j2^2, and the integral of r J0(j1 r) J0(j2 r) is 0.

### Step 4: every eigenvalue is real

Suppose a mode y were complex, with eigenvalue λ. Since p, q and w are real, its complex conjugate is a mode with the conjugate eigenvalue. Step 3 then says (λ minus its conjugate) times the integral of w |y|^2 is 0. That integral is positive, so λ is real.

### Step 5: read off the amounts of each mode

If f = c1 y1 + c2 y2 + …, multiply by w y_n and integrate. By Step 3 every term dies but the one with y_n, leaving c_n times the integral of w y_n^2. Divide: that is the formula for $c_n$, the same move that finds a vector's components along perpendicular axes.

Whether the sum rebuilds f with nothing missing is a separate claim, **completeness**. It holds for regular problems (finite interval, p and w positive on all of it, ends included) and for the drum; the proof is on Compact and symmetric.

<details>
<summary>Detailed proof: Lagrange's identity and the reality of eigenvalues</summary>

With p, q real and u, v twice differentiable, u (p v')' − v (p u')' = p'(u v' − v u') + p(u v'' − v u''), the derivative of p(u v' − v u'). The q terms cancel, so ∫ (u L v − v L u) dx = [p(u' v − u v')] from a to b.

End terms. An end condition α y + β p y' = 0, with real α, β not both 0, makes (u, p u') and (v, p v') both perpendicular to (α, β), so parallel; (p u') v − u (p v') is their determinant, 0. Where p → 0 with bounded u, v and slopes, the term tends to 0.

Reality. If L y = λ w y with y ≠ 0 complex, conjugating gives L ȳ = λ̄ w ȳ under the same end conditions. With u = y, v = ȳ: (λ̄ − λ) ∫ w |y|^2 dx = 0, and the integral is positive, so λ̄ = λ.

</details>

A second road replaces the string by a row of beads and derivatives by differences ([Finite differences](07-finite-differences-for-boundary-problems.md)): the matrix is symmetric, so its eigenvectors are perpendicular, and they approach the modes as the beads multiply.

---

## Worked numbers, by hand

The string: −y'' = λ y on 0 ≤ x ≤ 1 m, pinned, so λ_n = n^2 π^2 and y_n = sin(nπx). The start is the arch f(x) = x(1 − x), in cm with x in m, 0.25 cm high in the middle, the shape a steady even push leaves.

| Step | Arithmetic | Value |
| --- | --- | --- |
| one arch times two | ½[cos(πx) − cos(3πx)] | integrates to **0** |
| each lobe | 2/(3π) | 0.212207, and −0.212207 |
| a mode's size | sin^2(πx) = ½[1 − cos(2πx)] | integrates to **0.5** |
| amount of mode n | 2 × integral of x(1 − x) sin(nπx), by parts twice: 4(1 − (−1)^n)/(nπ)^3 | c1 = 0.258012, c2 = 0, c3 = 0.009556 |
| rebuild the middle | c1 − c3 + c5 − c7 | 0.258012, 0.248456, 0.250520, **0.249768** |
| drum, weighted | integral of r J0(j1 r) J0(j2 r) | **0** |
| drum's mode size | integral of r J0(j1 r)^2 = J1(j1)^2/2 | 0.134757062 |

The arch holds 0.258012 cm of the lowest pitch and 0.009556 cm of the third; the symmetric arch has no even harmonics.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drum modes integrated without the weight r | 0.196082, not 0 | Perpendicular only under the weight |
| Coefficient not divided by the mode's size ½ | c1 = 0.129006, half the true 0.258012 | Modes are perpendicular, not unit size |
| A free-end mode, 1, set against a pinned one, sin(πx) | 0.636620, not 0 | Step 2's end terms need shared end conditions |

The code prints all three.

---

## Code, from first principles, and it actually runs

The check writes its own integrator (Simpson's rule), Bessel functions and root finder. Two roads per claim: Simpson against antiderivatives; J0's zeros from its series and from the integral J0(x) = (1/π) ∫ cos(x sin t) dt over 0 to π; the drum's size against J1; coefficients by Simpson and by parts. Four asserts.

### Python

```python
# Sturm-Liouville and orthogonality -- the check behind the card.  Standard library only;
# integrator, Bessel functions and root finder are written here.  Each claim is reached
# twice: Simpson against antiderivatives, J0 zeros by series and by integral, norm by J1.
from math import sin, cos, pi, acos, sqrt

def simpson(f, a, b, n=2000):                  # Simpson's rule, n even
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))) * h / 3

def z(v): return 0.0 if abs(v) < 5e-10 else v  # print a vanishing number as 0
def j_series(x, order=0):                      # J0 or J1 from its power series
    term, total, k = (x / 2) ** order, (x / 2) ** order, 0
    while abs(term) > 1e-18:
        k += 1
        term *= -(x / 2) ** 2 / (k * (k + order))
        total += term
    return total

def j0_integral(x):                            # J0(x) = (1/pi) * integral of cos(x sin t)
    return simpson(lambda t: cos(x * sin(t)), 0, pi, 200) / pi
def bisect(f, lo, hi):                         # root finder, 60 halvings
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

pairs = ((1, 1), (1, 2), (2, 2), (1, 3), (2, 3))
num = [simpson(lambda x: sin(m * pi * x) * sin(n * pi * x), 0, 1) for m, n in pairs]
anti = [0.5 if m == n else (sin((m - n) * pi) / (m - n) - sin((m + n) * pi) / (m + n)) / (2 * pi)
        for m, n in pairs]
print("string, Simpson:       " + " ".join(f"({m},{n}) {z(v):.6f}" for (m, n), v in zip(pairs, num)))
print("string, antiderivative:" + "".join(f" ({m},{n}) {z(v):.6f}" for (m, n), v in zip(pairs, anti)))
assert max(abs(a - b) for a, b in zip(num, anti)) < 1e-12
lobe = simpson(lambda x: sin(pi * x) * sin(2 * pi * x), 0, 0.5)
print(f"lobes of sin(pi x) sin(2 pi x): +{lobe:.6f} and -{lobe:.6f}; 2/(3 pi) = {2 / (3 * pi):.6f}")
j1, j2 = bisect(j_series, 2, 3), bisect(j_series, 5, 6)
i1, i2 = bisect(j0_integral, 2, 3), bisect(j0_integral, 5, 6)
print(f"drum J0 zeros, series road: {j1:.9f}, {j2:.9f}; integral road: {i1:.9f}, {i2:.9f}")
assert abs(j1 - i1) < 1e-9 and abs(j2 - i2) < 1e-9
wcross = simpson(lambda r: r * j_series(j1 * r) * j_series(j2 * r), 0, 1)
wnorm = simpson(lambda r: r * j_series(j1 * r) ** 2, 0, 1)
bare = simpson(lambda r: j_series(j1 * r) * j_series(j2 * r), 0, 1)
half_j1sq = j_series(j1, 1) ** 2 / 2
print(f"drum, weight r: cross {z(wcross):.9f}; norm {wnorm:.9f}, J1(j1)^2/2 = {half_j1sq:.9f}")
print(f"drum, weight dropped: cross {bare:.6f}, not 0")
assert abs(wcross) < 1e-10 and abs(wnorm - half_j1sq) < 1e-10
cs = [2 * simpson(lambda x: x * (1 - x) * sin(n * pi * x), 0, 1) for n in (1, 2, 3)]
cp = [4 * (1 - (-1) ** n) / (n * pi) ** 3 for n in range(1, 8)]
print("arch x(1 - x), c_1 c_2 c_3 by Simpson: " + " ".join(f"{z(c):.6f}" for c in cs))
print("arch x(1 - x), c_1 c_2 c_3 by parts:   " + " ".join(f"{c:.6f}" for c in cp[:3]))
assert max(abs(a - b) for a, b in zip(cs, cp)) < 1e-12
sums = [sum(cp[k] * sin((k + 1) * pi / 2) for k in range(n)) for n in (1, 3, 5, 7)]
print("partial sums at x = 0.5, target 0.25: " + ", ".join(f"N={2 * i + 1} {s:.6f}" for i, s in enumerate(sums)))
print(f"mistake, norm 1/2 left out: c_1 = {4 / pi ** 3:.6f}, half the true {cp[0]:.6f}")
print(f"mistake, slope-zero mode 1 against sin(pi x): {simpson(lambda x: sin(pi * x), 0, 1):.6f}, not 0")
xp = acos(1 / sqrt(3)) / pi
yp = sin(pi * xp) * sin(2 * pi * xp)
print(f"figure, peak x = {xp:.4f} value {yp:.4f} at ({40 + 280 * xp:.1f}, {120 - 100 * yp:.1f}), "
      f"trough at ({40 + 280 * (1 - xp):.1f}, {120 + 100 * yp:.1f})")
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
string, Simpson:       (1,1) 0.500000 (1,2) 0.000000 (2,2) 0.500000 (1,3) 0.000000 (2,3) 0.000000
string, antiderivative: (1,1) 0.500000 (1,2) 0.000000 (2,2) 0.500000 (1,3) 0.000000 (2,3) 0.000000
lobes of sin(pi x) sin(2 pi x): +0.212207 and -0.212207; 2/(3 pi) = 0.212207
drum J0 zeros, series road: 2.404825558, 5.520078110; integral road: 2.404825558, 5.520078110
drum, weight r: cross 0.000000000; norm 0.134757062, J1(j1)^2/2 = 0.134757062
drum, weight dropped: cross 0.196082, not 0
arch x(1 - x), c_1 c_2 c_3 by Simpson: 0.258012 0.000000 0.009556
arch x(1 - x), c_1 c_2 c_3 by parts:   0.258012 0.000000 0.009556
partial sums at x = 0.5, target 0.25: N=1 0.258012, N=3 0.248456, N=5 0.250520, N=7 0.249768
mistake, norm 1/2 left out: c_1 = 0.129006, half the true 0.258012
mistake, slope-zero mode 1 against sin(pi x): 0.636620, not 0
figure, peak x = 0.3041 value 0.7698 at (125.1, 43.0), trough at (234.9, 197.0)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Sturm-Liouville and orthogonality -- the same check as the Python, in Rust.  No crates;
// integrator, Bessel functions and root finder are written here.  Each claim is reached
// twice: Simpson against antiderivatives, J0 zeros by series and by integral, norm by J1.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // Simpson's rule, n even
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h)).sum();
    (f(a) + f(b) + inner) * h / 3.0
}

fn z(v: f64) -> f64 { if v.abs() < 5e-10 { 0.0 } else { v } } // print a vanishing number as 0

fn j_series(x: f64, order: i32) -> f64 {           // J0 or J1 from its power series
    let (mut term, mut k) = ((x / 2.0).powi(order), 0.0);
    let mut total = term;
    while term.abs() > 1e-18 {
        k += 1.0;
        term *= -(x / 2.0).powi(2) / (k * (k + order as f64));
        total += term;
    }
    total
}

fn j0_integral(x: f64) -> f64 {                    // J0(x) = (1/pi) * integral of cos(x sin t)
    simpson(&|t: f64| (x * t.sin()).cos(), 0.0, PI, 200) / PI
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // root finder, 60 halvings
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn main() {
    let pairs = [(1.0, 1.0), (1.0, 2.0), (2.0, 2.0), (1.0, 3.0), (2.0, 3.0)];
    let num: Vec<f64> = pairs.iter().map(|&(m, n)| simpson(&|x: f64| (m * PI * x).sin() * (n * PI * x).sin(), 0.0, 1.0, 2000)).collect();
    let anti: Vec<f64> = pairs.iter().map(|&(m, n)| if m == n { 0.5 } else {
        (((m - n) * PI).sin() / (m - n) - ((m + n) * PI).sin() / (m + n)) / (2.0 * PI) }).collect();
    let show = |v: &Vec<f64>| pairs.iter().zip(v).map(|(&(m, n), &x)| format!(" ({},{}) {:.6}", m, n, z(x))).collect::<String>();
    println!("string, Simpson:      {}", show(&num));
    println!("string, antiderivative:{}", show(&anti));
    assert!(num.iter().zip(&anti).all(|(a, b)| (a - b).abs() < 1e-12));
    let lobe = simpson(&|x: f64| (PI * x).sin() * (2.0 * PI * x).sin(), 0.0, 0.5, 2000);
    println!("lobes of sin(pi x) sin(2 pi x): +{:.6} and -{:.6}; 2/(3 pi) = {:.6}", lobe, lobe, 2.0 / (3.0 * PI));
    let j0 = |x: f64| j_series(x, 0);
    let (j1, j2) = (bisect(&j0, 2.0, 3.0), bisect(&j0, 5.0, 6.0));
    let (i1, i2) = (bisect(&j0_integral, 2.0, 3.0), bisect(&j0_integral, 5.0, 6.0));
    println!("drum J0 zeros, series road: {:.9}, {:.9}; integral road: {:.9}, {:.9}", j1, j2, i1, i2);
    assert!((j1 - i1).abs() < 1e-9 && (j2 - i2).abs() < 1e-9);
    let wcross = simpson(&|r: f64| r * j0(j1 * r) * j0(j2 * r), 0.0, 1.0, 2000);
    let wnorm = simpson(&|r: f64| r * j0(j1 * r).powi(2), 0.0, 1.0, 2000);
    let bare = simpson(&|r: f64| j0(j1 * r) * j0(j2 * r), 0.0, 1.0, 2000);
    let half_j1sq = j_series(j1, 1).powi(2) / 2.0;
    println!("drum, weight r: cross {:.9}; norm {:.9}, J1(j1)^2/2 = {:.9}", z(wcross), wnorm, half_j1sq);
    println!("drum, weight dropped: cross {:.6}, not 0", bare);
    assert!(wcross.abs() < 1e-10 && (wnorm - half_j1sq).abs() < 1e-10);
    let cs: Vec<f64> = (1..4).map(|n| 2.0 * simpson(&|x: f64| x * (1.0 - x) * (n as f64 * PI * x).sin(), 0.0, 1.0, 2000)).collect();
    let cp: Vec<f64> = (1..8).map(|n| 4.0 * (1.0 - (-1f64).powi(n)) / (n as f64 * PI).powi(3)).collect();
    println!("arch x(1 - x), c_1 c_2 c_3 by Simpson: {}", cs.iter().map(|c| format!("{:.6}", z(*c))).collect::<Vec<_>>().join(" "));
    println!("arch x(1 - x), c_1 c_2 c_3 by parts:   {}", cp[..3].iter().map(|c| format!("{:.6}", c)).collect::<Vec<_>>().join(" "));
    assert!(cs.iter().zip(&cp).all(|(a, b)| (a - b).abs() < 1e-12));
    let sums: Vec<String> = [1, 3, 5, 7].iter().map(|&n| {
        let s: f64 = (0..n).map(|k| cp[k] * ((k + 1) as f64 * PI / 2.0).sin()).sum();
        format!("N={} {:.6}", n, s) }).collect();
    println!("partial sums at x = 0.5, target 0.25: {}", sums.join(", "));
    println!("mistake, norm 1/2 left out: c_1 = {:.6}, half the true {:.6}", 4.0 / PI.powi(3), cp[0]);
    println!("mistake, slope-zero mode 1 against sin(pi x): {:.6}, not 0", simpson(&|x: f64| (PI * x).sin(), 0.0, 1.0, 2000));
    let xp = (1.0 / 3f64.sqrt()).acos() / PI;
    let yp = (PI * xp).sin() * (2.0 * PI * xp).sin();
    println!("figure, peak x = {:.4} value {:.4} at ({:.1}, {:.1}), trough at ({:.1}, {:.1})",
             xp, yp, 40.0 + 280.0 * xp, 120.0 - 100.0 * yp, 40.0 + 280.0 * (1.0 - xp), 120.0 + 100.0 * yp);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
string, Simpson:       (1,1) 0.500000 (1,2) 0.000000 (2,2) 0.500000 (1,3) 0.000000 (2,3) 0.000000
string, antiderivative: (1,1) 0.500000 (1,2) 0.000000 (2,2) 0.500000 (1,3) 0.000000 (2,3) 0.000000
lobes of sin(pi x) sin(2 pi x): +0.212207 and -0.212207; 2/(3 pi) = 0.212207
drum J0 zeros, series road: 2.404825558, 5.520078110; integral road: 2.404825558, 5.520078110
drum, weight r: cross 0.000000000; norm 0.134757062, J1(j1)^2/2 = 0.134757062
drum, weight dropped: cross 0.196082, not 0
arch x(1 - x), c_1 c_2 c_3 by Simpson: 0.258012 0.000000 0.009556
arch x(1 - x), c_1 c_2 c_3 by parts:   0.258012 0.000000 0.009556
partial sums at x = 0.5, target 0.25: N=1 0.258012, N=3 0.248456, N=5 0.250520, N=7 0.249768
mistake, norm 1/2 left out: c_1 = 0.129006, half the true 0.258012
mistake, slope-zero mode 1 against sin(pi x): 0.636620, not 0
figure, peak x = 0.3041 value 0.7698 at (125.1, 43.0), trough at (234.9, 197.0)
ALL CHECKS PASS
```

### Lean

Lean proves the card's three claims for every equation in Sturm-Liouville form on a finite interval a to b.

- Take p and w positive inside the interval, q and w without jumps, and one real end condition at each end.
- Then two modes with different eigenvalues, under the same end conditions, integrate to zero against the weight w.
- A mode allowed complex values has a real eigenvalue.
- If f is a finite sum of modes with different eigenvalues, c_n is the weighted overlap of f and y_n over y_n's weighted size.
- p may be 0 at an end, like the drum's centre, if the mode and its slope stay finite there.
- For the arch, c_2 = c_4 = 0, c_1 is 27 times c_3, and leaving out the size ½ halves c_1.

The decimals, the drum's Bessel modes and the partial sums that rebuild the arch are left to the Python and Rust checks.

```lean
-- Sturm-Liouville: for -(p y')' + q y = λ w y with p and w positive inside, real p, q, w and shared end conditions, two modes with different eigenvalues integrate to zero against the weight w, every eigenvalue is real, and the amount of each mode in a finite sum of modes is its weighted overlap over its weighted size.
import Mathlib.Analysis.RCLike.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Data.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Star

open Set

namespace SturmLiouville

theorem end_det_zero {𝕜 : Type*} [RCLike 𝕜] (α β : ℝ) (h : α ≠ 0 ∨ β ≠ 0) (U PU V PV : 𝕜)
    (hu : (α : 𝕜) * U + (β : 𝕜) * PU = 0) (hv : (α : 𝕜) * V + (β : 𝕜) * PV = 0) :
    PU * V - U * PV = 0 := by
  rcases h with h | h
  · have h' : (α : 𝕜) ≠ 0 := by exact_mod_cast h
    have : (α : 𝕜) * (PU * V - U * PV) = 0 := by linear_combination PU * hv - PV * hu
    exact (mul_eq_zero.mp this).resolve_left h'
  · have h' : (β : 𝕜) ≠ 0 := by exact_mod_cast h
    have : (β : 𝕜) * (PU * V - U * PV) = 0 := by linear_combination V * hu - U * hv
    exact (mul_eq_zero.mp this).resolve_left h'

theorem lagrange_identity_integral {𝕜 : Type*} [RCLike 𝕜] (p q w : ℝ → ℝ)
    (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a ≤ b) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (lam mu : 𝕜) (u u' v v' Pu Pv : ℝ → 𝕜)
    (hu : ∀ x ∈ Icc a b, HasDerivWithinAt u (u' x) (Icc a b) x)
    (hv : ∀ x ∈ Icc a b, HasDerivWithinAt v (v' x) (Icc a b) x)
    (hPu : ∀ x ∈ Icc a b, HasDerivWithinAt (fun t => (p t : 𝕜) * u' t) (Pu x) (Icc a b) x)
    (hPv : ∀ x ∈ Icc a b, HasDerivWithinAt (fun t => (p t : 𝕜) * v' t) (Pv x) (Icc a b) x)
    (eu : ∀ x ∈ Ioo a b, -Pu x + (q x : 𝕜) * u x = lam * (w x : 𝕜) * u x)
    (ev : ∀ x ∈ Ioo a b, -Pv x + (q x : 𝕜) * v x = mu * (w x : 𝕜) * v x)
    (bua : (α₁ : 𝕜) * u a + (β₁ : 𝕜) * ((p a : 𝕜) * u' a) = 0)
    (bva : (α₁ : 𝕜) * v a + (β₁ : 𝕜) * ((p a : 𝕜) * v' a) = 0)
    (bub : (α₂ : 𝕜) * u b + (β₂ : 𝕜) * ((p b : 𝕜) * u' b) = 0)
    (bvb : (α₂ : 𝕜) * v b + (β₂ : 𝕜) * ((p b : 𝕜) * v' b) = 0) :
    (mu - lam) * ∫ x in a..b, (w x : 𝕜) * u x * v x = 0 := by
  set W : ℝ → 𝕜 := fun t => ((p t : 𝕜) * u' t) * v t - u t * ((p t : 𝕜) * v' t) with hW
  have hWd : ∀ x ∈ Icc a b, HasDerivWithinAt W
      (Pu x * v x + ((p x : 𝕜) * u' x) * v' x - (u' x * ((p x : 𝕜) * v' x) + u x * Pv x))
      (Icc a b) x := fun x hx =>
    ((hPu x hx).mul (hv x hx)).sub ((hu x hx).mul (hPv x hx))
  have hwk : ContinuousOn (fun x => (w x : 𝕜)) (Icc a b) :=
    (RCLike.continuous_ofReal (K := 𝕜)).comp_continuousOn hwc
  have huc : ContinuousOn u (Icc a b) := fun x hx => (hu x hx).continuousWithinAt
  have hvc : ContinuousOn v (Icc a b) := fun x hx => (hv x hx).continuousWithinAt
  have hint : IntervalIntegrable (fun x => (mu - lam) * ((w x : 𝕜) * u x * v x)) MeasureTheory.volume a b := by
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le hab]
    exact continuousOn_const.mul ((hwk.mul huc).mul hvc)
  have hFTC := intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le hab
    (fun x hx => (hWd x hx).continuousWithinAt) (fun x hx => by
      have hx' : x ∈ Icc a b := Ioo_subset_Icc_self hx
      have hd := ((hWd x hx').hasDerivAt (Icc_mem_nhds hx.1 hx.2)).hasDerivWithinAt (s := Ioi x)
      convert hd using 1
      have h1 := eu x hx
      have h2 := ev x hx
      linear_combination v x * h1 - u x * h2) hint
  rw [intervalIntegral.integral_const_mul] at hFTC
  rw [hFTC]
  have ha := end_det_zero α₁ β₁ hend₁ (u a) ((p a : 𝕜) * u' a) (v a) ((p a : 𝕜) * v' a) bua bva
  have hb := end_det_zero α₂ β₂ hend₂ (u b) ((p b : 𝕜) * u' b) (v b) ((p b : 𝕜) * v' b) bub bvb
  simp only [hW, ha, hb, sub_zero]

theorem integral_pos_of_pos_at (a b : ℝ) (g : ℝ → ℝ) (hg : ContinuousOn g (Icc a b))
    (hg0 : ∀ x ∈ Ioo a b, 0 ≤ g x) (x₁ : ℝ) (hx₁ : x₁ ∈ Ioo a b) (hpos : 0 < g x₁) :
    0 < ∫ x in a..b, g x := by
  have hab : a ≤ b := (hx₁.1.trans hx₁.2).le
  have hca : ContinuousAt g x₁ := hg.continuousAt (Icc_mem_nhds hx₁.1 hx₁.2)
  have hev : {x | 0 < g x ∧ x ∈ Ioo a b} ∈ nhds x₁ :=
    (hca.eventually (lt_mem_nhds hpos)).and (Ioo_mem_nhds hx₁.1 hx₁.2)
  obtain ⟨l, r, hlr, hsub⟩ := mem_nhds_iff_exists_Ioo_subset.mp hev
  set c := (l + x₁) / 2
  set d := (x₁ + r) / 2
  have hc1 : l < c := by simp only [c]; linarith [hlr.1]
  have hc2 : c < x₁ := by simp only [c]; linarith [hlr.1]
  have hd1 : x₁ < d := by simp only [d]; linarith [hlr.2]
  have hd2 : d < r := by simp only [d]; linarith [hlr.2]
  have hcd_sub : Icc c d ⊆ Ioo l r := Icc_subset_Ioo hc1 hd2
  have hcin : c ∈ Ioo a b := (hsub (hcd_sub ⟨le_rfl, by linarith⟩)).2
  have hdin : d ∈ Ioo a b := (hsub (hcd_sub ⟨by linarith, le_rfl⟩)).2
  have hpos' : 0 < ∫ x in c..d, g x := by
    apply intervalIntegral.intervalIntegral_pos_of_pos_on
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le (by linarith)]
      exact hg.mono (Icc_subset_Icc hcin.1.le hdin.2.le)
    · intro x hx
      exact (hsub (hcd_sub (Ioo_subset_Icc_self hx))).1
    · linarith
  have hmono : (∫ x in c..d, g x) ≤ ∫ x in a..b, g x := by
    apply intervalIntegral.integral_mono_interval hcin.1.le (by linarith) hdin.2.le
    · rw [MeasureTheory.Measure.restrict_congr_set MeasureTheory.Ioo_ae_eq_Ioc.symm]
      exact (MeasureTheory.ae_restrict_iff' measurableSet_Ioo).mpr
        (Filter.Eventually.of_forall hg0)
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le hab]
      exact hg
  linarith

theorem exists_ne_zero_inside {𝕜 : Type*} [RCLike 𝕜] (a b : ℝ) (hab : a < b) (y : ℝ → 𝕜)
    (hy : ContinuousOn y (Icc a b)) (h : ∃ x ∈ Icc a b, y x ≠ 0) :
    ∃ x ∈ Ioo a b, y x ≠ 0 := by
  obtain ⟨x₀, hx₀, hne⟩ := h
  have hcl : x₀ ∈ closure (Ioo a b) := by rw [closure_Ioo hab.ne]; exact hx₀
  have := mem_closure_iff_nhdsWithin_neBot.mp hcl
  have hc : ContinuousWithinAt y (Ioo a b) x₀ := (hy x₀ hx₀).mono Ioo_subset_Icc_self
  have h1 : ∀ᶠ x in nhdsWithin x₀ (Ioo a b), y x ≠ 0 := hc.eventually_ne hne
  have h2 : ∀ᶠ x in nhdsWithin x₀ (Ioo a b), x ∈ Ioo a b := self_mem_nhdsWithin
  obtain ⟨x, hx1, hx2⟩ := (h2.and h1).exists
  exact ⟨x, hx1, hx2⟩

#print axioms end_det_zero
#print axioms lagrange_identity_integral
#print axioms integral_pos_of_pos_at
#print axioms exists_ne_zero_inside


/-- `y` is a mode of the Sturm-Liouville problem `-(p y')' + q y = lam w y` on `a < x < b`,
with eigenvalue `lam`, under the end conditions `α₁ y + β₁ p y' = 0` at `a` and
`α₂ y + β₂ p y' = 0` at `b`. Here `y` takes values in `𝕜` (the real or the complex numbers),
the coefficients `p, q, w` and the end-condition numbers are real, and `y'` is the slope of `y`.
The definition asks that:
* `y` has slope `y'` at every point of `a ≤ x ≤ b` (one-sided at the ends), so `y` stays finite
  on the closed interval;
* the stiffness times the slope, `p y'`, has a rate of change `P'` on `a ≤ x ≤ b`, and
  `-P' + q y = lam w y` at every point strictly inside;
* the two end conditions hold;
* `y` is not the zero shape on `a ≤ x ≤ b`.
The end conditions cover the card's three kinds: `y = 0` (`β = 0`), `p y' = 0` (`α = 0`), and
a fixed real ratio of the two. At an end where `p` is 0, like the drum's centre, the condition
`p y' = 0` holds automatically, so it asks only that the mode stay finite there. -/
def IsMode {𝕜 : Type*} [RCLike 𝕜] (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (lam : 𝕜)
    (y y' : ℝ → 𝕜) : Prop :=
  (∀ x ∈ Icc a b, HasDerivWithinAt y (y' x) (Icc a b) x) ∧
  (∃ P' : ℝ → 𝕜,
    (∀ x ∈ Icc a b, HasDerivWithinAt (fun t => (p t : 𝕜) * y' t) (P' x) (Icc a b) x) ∧
    ∀ x ∈ Ioo a b, -P' x + (q x : 𝕜) * y x = lam * (w x : 𝕜) * y x) ∧
  (α₁ : 𝕜) * y a + (β₁ : 𝕜) * ((p a : 𝕜) * y' a) = 0 ∧
  (α₂ : 𝕜) * y b + (β₂ : 𝕜) * ((p b : 𝕜) * y' b) = 0 ∧
  ∃ x ∈ Icc a b, y x ≠ 0

/-- The card's main claim, perpendicular modes. Put the equation in Sturm-Liouville form
`-(p y')' + q y = λ w y` on `a < x < b`, with `p, q, w` real, `p` and `w` positive inside the
interval, `q` and `w` continuous on `a ≤ x ≤ b`, and one end condition at each end
(`α y + β p y' = 0`, with `α, β` real and not both 0). If `u` is a mode with eigenvalue `λ`
and `v` is a mode with eigenvalue `μ`, under the same end conditions, and `λ ≠ μ`, then
`∫ₐᵇ w u v dx = 0`: two different modes, multiplied and weighted, integrate to zero. -/
theorem modes_with_different_eigenvalues_are_perpendicular_under_weight
    (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a < b)
    (hp : ∀ x ∈ Ioo a b, 0 < p x) (hw : ∀ x ∈ Ioo a b, 0 < w x)
    (hq : ContinuousOn q (Icc a b)) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (lam mu : ℝ) (u u' v v' : ℝ → ℝ)
    (hu : IsMode p q w a b α₁ β₁ α₂ β₂ lam u u')
    (hv : IsMode p q w a b α₁ β₁ α₂ β₂ mu v v')
    (hne : lam ≠ mu) :
    ∫ x in a..b, w x * u x * v x = 0 := by
  obtain ⟨hu1, ⟨Pu, hPu, eu⟩, bua, bub, -⟩ := hu
  obtain ⟨hv1, ⟨Pv, hPv, ev⟩, bva, bvb, -⟩ := hv
  have h := lagrange_identity_integral (𝕜 := ℝ) p q w a b α₁ β₁ α₂ β₂ hab.le hwc hend₁ hend₂
    lam mu u u' v v' Pu Pv hu1 hv1 hPu hPv eu ev bua bva bub bvb
  have hne' : mu - lam ≠ 0 := sub_ne_zero.mpr (Ne.symm hne)
  exact (mul_eq_zero.mp h).resolve_left hne'

/-- The card's second claim, real eigenvalues. Under the same conditions (`p, q, w` real,
`p` and `w` positive inside, `q` and `w` continuous on `a ≤ x ≤ b`, real end conditions with
`α, β` not both 0), let `y` be a mode that is allowed to take complex values, with a complex
eigenvalue `λ`. Then `λ` is real: its imaginary part is 0. -/
theorem every_eigenvalue_is_real
    (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a < b)
    (hp : ∀ x ∈ Ioo a b, 0 < p x) (hw : ∀ x ∈ Ioo a b, 0 < w x)
    (hq : ContinuousOn q (Icc a b)) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (lam : ℂ) (y y' : ℝ → ℂ)
    (hy : IsMode p q w a b α₁ β₁ α₂ β₂ lam y y') :
    lam.im = 0 := by
  obtain ⟨hy1, ⟨P', hP, ey⟩, ba, bb, hnz⟩ := hy
  have hstar_ofReal : ∀ r : ℝ, star (RCLike.ofReal r : ℂ) = (RCLike.ofReal r : ℂ) :=
    fun r => RCLike.conj_ofReal r
  have h := lagrange_identity_integral (𝕜 := ℂ) p q w a b α₁ β₁ α₂ β₂ hab.le hwc hend₁ hend₂
    lam (star lam) y y' (fun t => star (y t)) (fun t => star (y' t)) P' (fun t => star (P' t))
    hy1 (fun x hx => (hy1 x hx).star)
    hP (fun x hx => by
      have := (hP x hx).star
      convert this using 1
      funext t
      rw [star_mul', hstar_ofReal])
    ey (fun x hx => by
      have := congrArg star (ey x hx)
      simpa only [star_add, star_neg, star_mul', hstar_ofReal] using this)
    ba (by
      have := congrArg star ba
      simpa only [star_add, star_mul', hstar_ofReal, star_zero] using this)
    bb (by
      have := congrArg star bb
      simpa only [star_add, star_mul', hstar_ofReal, star_zero] using this)
  have hyc : ContinuousOn y (Icc a b) := fun x hx => (hy1 x hx).continuousWithinAt
  obtain ⟨x₁, hx₁, hy₁⟩ := exists_ne_zero_inside a b hab y hyc hnz
  have hpos : 0 < ∫ x in a..b, w x * Complex.normSq (y x) := by
    apply integral_pos_of_pos_at a b _ (hwc.mul (Complex.continuous_normSq.comp_continuousOn hyc))
      (fun x hx => mul_nonneg (hw x hx).le (Complex.normSq_nonneg _)) x₁ hx₁
    exact mul_pos (hw x₁ hx₁) (Complex.normSq_pos.mpr hy₁)
  have hI : (∫ x in a..b, (RCLike.ofReal (w x) : ℂ) * y x * star (y x))
      = ((∫ x in a..b, w x * Complex.normSq (y x) : ℝ) : ℂ) := by
    rw [← intervalIntegral.integral_ofReal]
    apply intervalIntegral.integral_congr
    intro x _
    change ((w x : ℝ) : ℂ) * y x * (starRingEnd ℂ) (y x) = (((w x * Complex.normSq (y x)) : ℝ) : ℂ)
    rw [mul_assoc, Complex.mul_conj]
    push_cast
    ring
  rw [hI] at h
  have hne : ((∫ x in a..b, w x * Complex.normSq (y x) : ℝ) : ℂ) ≠ 0 := by
    exact_mod_cast hpos.ne'
  have h0 : star lam - lam = 0 := (mul_eq_zero.mp h).resolve_right hne
  have : (starRingEnd ℂ) lam = lam := sub_eq_zero.mp h0
  exact Complex.conj_eq_iff_im.mp this

/-- The card's Step 5, the amount of each mode. Under the same conditions, take finitely many
modes `y_k` (one for each `k` in `s`) under the same end conditions, with eigenvalues `λ_k`
that are all different. If a shape `f` equals `∑ c_k y_k` on `a ≤ x ≤ b`, then for each `n` in
`s` the amount of mode `n` is its weighted overlap with `f` over its weighted size:
`c_n = (∫ₐᵇ w f y_n dx) / (∫ₐᵇ w y_n² dx)`. (That every shape is such a sum, possibly infinite,
is completeness, which the card states but proves elsewhere.) -/
theorem coefficient_is_weighted_overlap_over_size {ι : Type*}
    (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a < b)
    (hp : ∀ x ∈ Ioo a b, 0 < p x) (hw : ∀ x ∈ Ioo a b, 0 < w x)
    (hq : ContinuousOn q (Icc a b)) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (s : Finset ι) (lam : ι → ℝ) (y y' : ι → ℝ → ℝ)
    (hy : ∀ k ∈ s, IsMode p q w a b α₁ β₁ α₂ β₂ (lam k) (y k) (y' k))
    (hdistinct : ∀ j ∈ s, ∀ k ∈ s, j ≠ k → lam j ≠ lam k)
    (c : ι → ℝ) (f : ℝ → ℝ) (hf : ∀ x ∈ Icc a b, f x = ∑ k ∈ s, c k * y k x)
    (n : ι) (hn : n ∈ s) :
    c n = (∫ x in a..b, w x * f x * y n x) / (∫ x in a..b, w x * y n x ^ 2) := by
  have hcont : ∀ k ∈ s, ContinuousOn (y k) (Icc a b) := fun k hk x hx =>
    ((hy k hk).1 x hx).continuousWithinAt
  have hint : ∀ k ∈ s, IntervalIntegrable (fun x => c k * (w x * y k x * y n x))
      MeasureTheory.volume a b := by
    intro k hk
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le hab.le]
    exact continuousOn_const.mul ((hwc.mul (hcont k hk)).mul (hcont n hn))
  have h1 : (∫ x in a..b, w x * f x * y n x) = c n * ∫ x in a..b, w x * y n x ^ 2 := by
    calc (∫ x in a..b, w x * f x * y n x)
        = ∫ x in a..b, ∑ k ∈ s, c k * (w x * y k x * y n x) := by
          apply intervalIntegral.integral_congr
          intro x hx
          rw [uIcc_of_le hab.le] at hx
          simp only
          rw [hf x hx, Finset.mul_sum, Finset.sum_mul]
          apply Finset.sum_congr rfl
          intro k _
          ring
      _ = ∑ k ∈ s, ∫ x in a..b, c k * (w x * y k x * y n x) :=
          intervalIntegral.integral_finsetSum hint
      _ = ∑ k ∈ s, c k * ∫ x in a..b, w x * y k x * y n x := by
          apply Finset.sum_congr rfl
          intro k _
          exact intervalIntegral.integral_const_mul _ _
      _ = c n * ∫ x in a..b, w x * y n x * y n x := by
          apply Finset.sum_eq_single n
          · intro k hk hkn
            rw [modes_with_different_eigenvalues_are_perpendicular_under_weight p q w a b α₁ β₁ α₂
              β₂ hab hp hw hq hwc hend₁ hend₂ (lam k) (lam n) (y k) (y' k) (y n) (y' n) (hy k hk)
              (hy n hn) (hdistinct k hk n hn hkn), mul_zero]
          · intro h
            exact absurd hn h
      _ = c n * ∫ x in a..b, w x * y n x ^ 2 := by
          congr 1
          apply intervalIntegral.integral_congr
          intro x _
          simp only
          ring
  obtain ⟨x₁, hx₁, hy₁⟩ := exists_ne_zero_inside a b hab (y n) (hcont n hn) (hy n hn).2.2.2.2
  have hpos : 0 < ∫ x in a..b, w x * y n x ^ 2 := by
    apply integral_pos_of_pos_at a b _ (hwc.mul ((hcont n hn).pow 2))
      (fun x hx => mul_nonneg (hw x hx).le (sq_nonneg _)) x₁ hx₁
    exact mul_pos (hw x₁ hx₁) (sq_pos_of_ne_zero hy₁)
  rw [h1, mul_div_assoc, div_self hpos.ne', mul_one]

-- The arch x(1 - x) on the string: c_n = 4(1 - (-1)^n)/(nπ)^3. The even amounts vanish,
-- c_2 = 0 and c_4 = 0: the symmetric arch has no even harmonics.
example : (4 * (1 - (-1 : ℤ) ^ 2), 4 * (1 - (-1 : ℤ) ^ 4)) = (0, 0) := by norm_num
-- The odd numerators are 8, so c_1 / c_3 = 3^3 = 27: the third harmonic holds 1/27 of the first.
example : (4 * (1 - (-1 : ℚ) ^ 1) / 1 ^ 3) / (4 * (1 - (-1 : ℚ) ^ 3) / 3 ^ 3) = 27 := by norm_num
-- The usual mistake: c_1 = 8/π³, but leaving out the mode's size 1/2 gives 4/π³, half of it
-- of the true amount. The numerators: 4(1 - (-1)^1) = 8, and half of 8 is 4.
example : (4 * (1 - (-1 : ℤ) ^ 1), 4 * (1 - (-1 : ℤ) ^ 1) / 2) = (8, 4) := by norm_num

#print axioms modes_with_different_eigenvalues_are_perpendicular_under_weight
#print axioms every_eigenvalue_is_real
#print axioms coefficient_is_weighted_overlap_over_size

end SturmLiouville
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'SturmLiouville.end_det_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'SturmLiouville.lagrange_identity_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'SturmLiouville.integral_pos_of_pos_at' depends on axioms: [propext, Classical.choice, Quot.sound]
'SturmLiouville.exists_ne_zero_inside' depends on axioms: [propext, Classical.choice, Quot.sound]
'SturmLiouville.modes_with_different_eigenvalues_are_perpendicular_under_weight' depends on axioms: [propext, Classical.choice, Quot.sound]
'SturmLiouville.every_eigenvalue_is_real' depends on axioms: [propext, Classical.choice, Quot.sound]
'SturmLiouville.coefficient_is_weighted_overlap_over_size' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: change the pair `(2, 3)` to `(3, 3)`. Both roads print 0.500000; every string mode has size ½.
> - Guess first: delete `r *` from the `wnorm` line. The third assert fails: J1(j1)^2/2 is the weighted size only.
> - Guess first: change the by-parts factor 4 to 2. The fourth assert fails; Simpson's answer does not move.

---

## The usual mistake

> [!warning]
> **Testing perpendicularity with the plain integral when the problem has a weight.** The drum's first two ring modes give 0.196082; they are perpendicular only when each radius r counts r times. The weight is read off the equation, never chosen afterwards.
>
> - **Not dividing by the mode's size.** String modes have size ½, so c1 comes out 0.129006 instead of 0.258012.
> - **Mixing end conditions.** The free-end constant 1 against the pinned sin(πx) gives 0.636620.
> - **Taking perpendicular for complete.** Delete sin(πx) and the rest stay perpendicular, yet no sum of them rebuilds the arch: its 0.258012 cm of fundamental has nowhere to go.

---

## Where you meet it in real life

- **Strings and drums.** The c_n say how loud each harmonic is.
- **Heat in a rod.** Each mode cools at its own rate ([Fourier series](../09-Fourier%20Series/01-fourier-series-and-orthogonality.md)).
- **Legendre's polynomials.** Already in form, with p = 1 − x^2, so perpendicular on −1 to 1 ([Legendre's equation](04-legendre-polynomials.md)).
- **A forced string.** Expanding the force in modes solves one mode at a time; the closed form is [Green's function](10-greens-function-for-a-boundary-problem.md).

> **Say it back**
> Sturm-Liouville form: minus the rate of stiffness times slope, plus a potential, equals an eigenvalue times a weight times the shape. Integrating by parts twice shows the operator is symmetric under shared end conditions. Symmetry forces real eigenvalues and perpendicular modes under the weight. Each mode's amount in a shape is the weighted overlap over the mode's size. Drum modes need the weight r.

---

## What this builds on

- [Eigenvalue problems](08-eigenvalues-and-eigenfunctions.md): the string's modes.
- [Bessel's equation](03-bessels-equation-and-the-drum.md): J0 and the drum's modes.
- [Gram-Schmidt](../../03-Algebra/06-Dot%20Products%20and%20Best%20Fits/03-gram-schmidt-and-orthonormal-bases.md): components along perpendicular axes.
- [Integration by parts](../../06-Calculus%20and%20analysis/04-Integrals/04-integration-by-parts.md): Lagrange's identity.

## Where this goes next

- [Fourier series](../09-Fourier%20Series/01-fourier-series-and-orthogonality.md): the sine and cosine case, and convergence.
- [Schrodinger's equation](../../13-Engineering%20mathematics/09-Quantum%20Mechanics%20in%20Outline/03-schrodinger-equation-and-the-particle-in-a-box.md): the string equation as allowed energies.
- Compact and symmetric: the proof of completeness.
- Self-adjoint extensions: end conditions as a choice of operator.
- Helmholtz: the theorem in two and three dimensions.

This card leaves one question open: why do the modes leave nothing over, so that every shape is a sum of them?

---

## Sources

Verified 2026-11-12: every link below resolves to the publisher's page.

- Teschl, Gerald. *Ordinary Differential Equations and Dynamical Systems*. AMS, Graduate Studies in Mathematics 140. [Author's page, free text](https://www.mat.univie.ac.at/~gerald/ftp/book-ode/). Chapter 5: regular problems, Lagrange's identity, real eigenvalues, completeness.
- Lebl, Jiří. *Notes on Diffy Qs*, §5.1 "Sturm–Liouville problems". [Section page](https://www.jirka.org/diffyqs/html/slproblems_section.html). The form, weighted orthogonality, expansions.
- NIST Digital Library of Mathematical Functions, §10.9 "Integral Representations". [Section page](https://dlmf.nist.gov/10.9). The integral for J0, the check's second road.
- NIST Digital Library of Mathematical Functions, §10.22 "Integrals". [Section page](https://dlmf.nist.gov/10.22). J0 modes perpendicular with weight r; the size J1(j)^2/2.
