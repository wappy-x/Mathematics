# The argument principle: walk the boundary and watch the output spin; the turns count zeros minus poles inside

[Syllabus](../../../SYLLABUS.md) → [Complex analysis](../README.md) → [Real Integrals and Counting Zeros](../README.md#s06) → The argument principle

---

## General Overview

Take f(z) = z(z − 0.4). It is zero at 0 and at 0.4, both inside the circle of radius 1 centred at 0. Walk that circle once anticlockwise. At each step, draw the value f(z) as an arrow from 0: a compass needle.

When the walk returns to its start, the needle has turned exactly twice round. Two turns, two zeros inside. On the circle of radius 0.2 only the zero at 0 is inside, and the needle turns once.

Poles push the other way. A **pole** is a point where the function blows up, like 1/(z − 2)^3 at 2; the power 3 is the pole's **order**. For g(z) = (z − 0.5)/(z − 2)^3 the needle turns once on the unit circle: one zero inside, no pole. On the circle of radius 3 the pole is inside too, counted three times, and the needle turns 1 − 3 = −2 times.

From here on the needle's net number of turns is the **winding number** of the output curve round 0 ([Deforming a loop](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/04-deforming-contours-and-winding-numbers.md)). The count never locates a zero.

**Walk a loop and follow the value of f: the number of times it winds round 0 equals the number of zeros inside minus the number of poles inside, each counted as often as its multiplicity or order.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, with the full argument in a folded Detailed proof.

### The picture: the walk, and the needle's tip

<p align="center"><img src="../figures/the-argument-principle.svg" alt="Left: the unit circle walked anticlockwise, with the zeros of z(z - 0.4) at 0 and 0.4 inside. Right: the values f(z) along the walk, a curve that winds twice round 0" width="420"></p>

To scale. Left: 55 units per 1, 0 at (75, 120), the zeros at (75, 120) and (97, 120). Right: 65 units per 1, 0 at (240, 120), f(z) at 72 even steps of the walk, every point printed by both checks. The tip starts at (279, 120) and circles 0 twice.

---

## The formula

Reminder: a loop integral adds f(z) times each small step dz round a closed path ([Contour integrals](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/01-contour-integrals.md)); arg w is the angle of the arrow w, measured anticlockwise from the positive real axis. The quotient f′/f, the derivative divided by the function, is the **logarithmic derivative**: the rate of change of ln f.

$$N - P = \frac{1}{2\pi i}\oint_C \frac{f'(z)}{f(z)}\,dz = \frac{\Delta_C \arg f}{2\pi} = n\big(f(C),\,0\big)$$

**Read it aloud:** zeros minus poles inside the loop equals the loop integral of f′ over f, divided by two pi i, which is the total turn of f's angle along the loop, in whole turns: the winding number of the output curve round 0.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $f$, $z$ | the function, and the point walking the loop | z(z − 0.4); z on \|z\| = 1 | — |
| $C$ | the loop, walked once anticlockwise | \|z\| = 1 | may enclose more zeros or poles |
| $f'$ | the complex derivative of f | 2z − 0.4 | — |
| $N$ | zeros inside, each counted by its multiplicity | 2 | one more turn per zero |
| $P$ | poles inside, each counted by its order | 0; for g on \|z\| = 3, 3 | one turn fewer per pole |
| $a$, $m$, $p$ | a zero or pole; a zero's multiplicity; a pole's order | 0.4, m = 1; 2, p = 3 | — |
| $\Delta_C \arg f$ | total change in the angle of f round C, kept continuous | 4π, two full turns | — |
| $n(f(C), 0)$ | winding number of the output curve round 0 | 2 | — |

A zero of **multiplicity** m at a: f is (z − a)^m times a function nonzero at a ([Zeros and the identity theorem](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/03-zeros-and-the-identity-theorem.md)).

### When it holds

- **f is holomorphic (has a complex derivative) inside and on C, except at poles.** Drop this and the count fails: z-bar, the conjugate, has one zero inside the unit circle, but its needle turns −1 times.
- **No zero or pole on C.** On |z| = 0.4 the walk hits the zero at 0.4, where the needle has no direction and f′/f is infinite.
- **f not identically zero.** Then its zeros are isolated, so a loop holds finitely many.

---

## Why it works

### Step 0: f′/f measures change in ln f, and round a loop only the angle changes

Write f in polar form, |f| times e^(i arg f). Then ln f = ln|f| + i arg f, and f′/f is its rate of change. Round a closed loop, |f| returns to its start, so ln|f| gains nothing. The angle can come back 2π, 4π or −2π higher. So the integral is i times the total change in angle, and dividing by 2πi gives whole turns.

### Step 1: each zero of multiplicity m contributes a residue m

Near a zero a of multiplicity m, f(z) = (z − a)^m h(z), with h nonzero at a. The product rule gives

f′/f = m/(z − a) + h′/h.

The second term has no pole at a, so the **residue** of f′/f at a, its coefficient of 1/(z − a) ([Residues](../05-Laurent%20Series%2C%20Singularities%20and%20Residues/04-residues.md)), is m. For z(z − 0.4), f′/f = (2z − 0.4)/(z(z − 0.4)) = 1/z + 1/(z − 0.4): residue 1 at each zero.

### Step 2: each pole of order p contributes a residue −p

Near a pole a of order p, f(z) = (z − a)^(−p) h(z), and the same product rule gives −p/(z − a) + h′/h. For g, g′/g = 1/(z − 0.5) − 3/(z − 2): residue 1 at the zero, −3 at the pole.

### Step 3: add the residues

f′/f is holomorphic everywhere else inside C, so by [The residue theorem](../05-Laurent%20Series%2C%20Singularities%20and%20Residues/05-the-residue-theorem.md) its loop integral is 2πi times the sum of the residues inside: 2πi(N − P). For g round |z| = 3 that is 2πi(1 − 3), and the needle turns −2 times.

The needle turns unevenly. For z(z − 0.4) on the unit circle, it has turned 0.31 of a turn after the first eighth of the walk, 1.00 halfway, and 2.00 at the end:

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The needle's total turn along the walk, f(z) = z(z - 0.4) on |z| = 1"
    x-axis "Fraction of the walk done" ["0", "1/8", "2/8", "3/8", "4/8", "5/8", "6/8", "7/8", "1"]
    y-axis "Turns of f(z) round 0" 0 --> 2
    line [0.00, 0.31, 0.56, 0.78, 1.00, 1.22, 1.44, 1.69, 2.00]
```

The line is the needle's accumulated turn. It climbs fastest at the start and end of the walk, near z = 1, the point closest to the zero at 0.4.

<details>
<summary>Detailed proof</summary>

Let f be holomorphic on an open set containing C and its inside, except at poles, with no zero or pole on C and f not identically zero. Its zeros are isolated ([Zeros and the identity theorem](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/03-zeros-and-the-identity-theorem.md)); poles are isolated by definition, and the closed inside of C is closed and bounded, so it holds finitely many of each.

**Residues.** In Step 1, h is holomorphic and nonzero on a small disc round a, so h′/h is holomorphic there and the residue of f′/f at a is exactly m; likewise −p at a pole. Away from zeros and poles, f′/f is holomorphic. The residue theorem gives the loop integral of f′/f as 2πi(N − P).

**Turns, without a global logarithm.** Step 0 used ln f, which is only defined piece by piece. Instead, parametrise C by z(t), t from 0 to 1, and let w(t) = f(z(t)), a closed path avoiding 0. The chain rule gives w′/w = (f′(z)/f(z)) z′(t), so the loop integral of f′/f dz equals the loop integral of dw/w round f(C), which is 2πi times n(f(C), 0) by the definition of the winding number.

</details>

A second road avoids residues: Step 0 alone. Follow the angle of f continuously along the walk and read off its total change, as the checks' compass does.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Zeros of z(z − 0.4) | z = 0 or z − 0.4 = 0 | 0 and 0.4 |
| Inside \|z\| = 1 | both closer than 1 to 0 | N = 2, P = 0 |
| Inside \|z\| = 0.2 | 0 only | **N − P = 1** |
| f′/f round \|z\| = 1 | 1/z + 1/(z − 0.4): residues 1 + 1 | **N − P = 2** |
| g = (z − 0.5)/(z − 2)^3 | zero 0.5, pole 2 of order 3 | — |
| Round \|z\| = 1 | 0.5 inside, 2 outside | **1 − 0 = 1** |
| Round \|z\| = 3 | both inside | **1 − 3 = −2** |

Two turns on |z| = 1: the quadratic z(z − 0.4) has both its zeros in the unit disc.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Compass read at only 3 or 4 points of the walk | −1 or 0 turns, not 2 | a step turned more than half a turn and was read the short way |
| Pole of order 3 counted once, \|z\| = 3 | 1 − 1 = 0, not −2 | order counts |
| z-bar round \|z\| = 1 | −1 turns, with one zero inside | z-bar is not holomorphic |

The code prints all three. At 5 points the compass reads 2.

---

## Code, from first principles, and it actually runs

Three roads; the first two share nothing but f. Road one: (1/2πi) times a trapezoid sum of f′/f dz at 256 points, the derivative written out by hand; its error for z(z − 0.4) on |z| = 1 falls from 6.6e-4 at 8 points to 4.3e-7 at 16 and 1.8e-13 at 32. Road two: the compass, with no derivative; it adds the small turn from each value of f to the next, read off atan2 (the angle of a point from its two coordinates). Road three: the located zeros and poles. The asserts pin all four cases, the shrinking error, the missed turns and the z-bar break.

### Python

```python
# The argument principle -- the check behind the card.  Walk a circle and count
# the turns of f(z) round 0 by two roads that share nothing but f.  Road one:
# (1/2 pi i) times a trapezoid sum of f'/f dz.  Road two: a compass needle,
# adding the small turn between neighbouring values of f, read off atan2.
import math

def f(z): return z * (z - 0.4), 2 * z - 0.4                      # value, derivative
def g(z): return (z - 0.5) / (z - 2) ** 3, ((z - 2) - 3 * (z - 0.5)) / (z - 2) ** 4

def walk(r, n):                          # n + 1 points round |z| = r, anticlockwise
    return [r * complex(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)) for k in range(n + 1)]

def integral(fn, r, n=256):              # road one: (1/2 pi i) x sum of f'/f dz
    total = 0
    for z in walk(r, n)[:-1]:
        v, d = fn(z)
        total += d / v * 1j * z * (2 * math.pi / n)
    return total / (2j * math.pi)

def compass(fn, r, n=256, marks=None):   # road two: add up the needle's small turns
    pts, turn, seen = walk(r, n), 0.0, [0.0]
    for k in range(n):
        q = fn(pts[k + 1])[0] / fn(pts[k])[0]
        turn += math.atan2(q.imag, q.real)
        if marks and (k + 1) % (n // marks) == 0: seen.append(turn / (2 * math.pi))
    return (turn / (2 * math.pi), seen) if marks else turn / (2 * math.pi)

def show(z):
    re, im = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def sci(x): e = math.floor(math.log10(x)); return f"{x / 10 ** e:.1f}e{e}"

def count(zeros, poles, r):              # road three: located zeros and poles, with multiplicity
    return sum(m for a, m in zeros if abs(a) < r) - sum(m for a, m in poles if abs(a) < r)

cases = [("z(z - 0.4)", f, [(0, 1), (0.4, 1)], [], 1), ("z(z - 0.4)", f, [(0, 1), (0.4, 1)], [], 0.2),
         ("(z - 0.5)/(z - 2)^3", g, [(0.5, 1)], [(2, 3)], 1), ("(z - 0.5)/(z - 2)^3", g, [(0.5, 1)], [(2, 3)], 3)]
gaps = []
for name, fn, zs, ps, r in cases:
    truth, i1, c2 = count(zs, ps, r), integral(fn, r), compass(fn, r)
    gaps += [abs(i1 - truth), abs(c2 - truth)]
    print(f"{name} round |z| = {r}: N - P = {truth}; integral = {show(i1)}; compass = {c2:.6f}")
errs = [abs(integral(f, 1, n) - 2) for n in (8, 16, 32)]
print("z(z - 0.4), |z| = 1, integral error at 8, 16, 32 points: " + ", ".join(sci(e) for e in errs))
turns, marks = compass(f, 1, 256, 8)
print("needle turns at 0, 1/8, ..., 8/8 of the walk: " + ", ".join(f"{t:.2f}" for t in marks))
few = [compass(f, 1, n) for n in (3, 4, 5)]
print("compass sampled at only 3, 4, 5 points: " + ", ".join(str(int(math.floor(c + 0.5))) for c in few))
cz = compass(lambda z: (z.conjugate(), None), 1)     # z-bar: no derivative exists
print(f"break, z-bar round |z| = 1 (one zero inside, not holomorphic): compass = {cz:.6f}")
print(f"mistake, pole of order 3 counted once, |z| = 3: 1 - 1 = 0, not {count([(0.5, 1)], [(2, 3)], 3)}")
print("figure, left 55 units per 1, 0 at (75, 120), zeros at (75, 120) and (97, 120); right 65 units per 1, 0 at (240, 120)")
img = [f(z)[0] for z in walk(1, 72)]
print("figure, image points: " + " ".join(f"{math.floor(240 + 65 * w.real + 0.5)},{math.floor(120 - 65 * w.imag + 0.5)}" for w in img))
assert max(gaps) < 1e-9                                 # both roads land on N - P in all four cases
assert errs[2] < errs[1] < errs[0] and errs[2] < 1e-9   # the trapezoid error shrinks
assert abs(few[2] - integral(f, 1)) < 1e-9 and abs(few[0] - 2) > 2.5   # 5 points suffice, 3 miss turns
assert abs(cz + count([(0, 1)], [], 1)) < 1e-9          # z-bar turns the other way: -1, not +1
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
z(z - 0.4) round |z| = 1: N - P = 2; integral = 2.000000 + 0.000000i; compass = 2.000000
z(z - 0.4) round |z| = 0.2: N - P = 1; integral = 1.000000 + 0.000000i; compass = 1.000000
(z - 0.5)/(z - 2)^3 round |z| = 1: N - P = 1; integral = 1.000000 + 0.000000i; compass = 1.000000
(z - 0.5)/(z - 2)^3 round |z| = 3: N - P = -2; integral = -2.000000 + 0.000000i; compass = -2.000000
z(z - 0.4), |z| = 1, integral error at 8, 16, 32 points: 6.6e-4, 4.3e-7, 1.8e-13
needle turns at 0, 1/8, ..., 8/8 of the walk: 0.00, 0.31, 0.56, 0.78, 1.00, 1.22, 1.44, 1.69, 2.00
compass sampled at only 3, 4, 5 points: -1, 0, 2
break, z-bar round |z| = 1 (one zero inside, not holomorphic): compass = -1.000000
mistake, pole of order 3 counted once, |z| = 3: 1 - 1 = 0, not -2
figure, left 55 units per 1, 0 at (75, 120), zeros at (75, 120) and (97, 120); right 65 units per 1, 0 at (240, 120)
figure, image points: 279,120 278,111 275,102 271,94 265,87 258,81 250,77 241,74 231,73 222,73 212,76 203,80 195,86 187,94 181,103 177,113 174,123 174,135 175,146 178,157 183,168 190,178 199,186 209,193 220,199 233,202 245,204 258,203 271,201 284,196 295,189 305,181 314,171 321,159 327,147 330,134 331,120 330,106 327,93 321,81 314,69 305,59 295,51 284,44 271,39 258,37 245,36 233,38 221,41 209,47 199,54 190,62 183,72 178,83 175,94 174,105 174,117 177,127 181,137 187,146 194,154 203,160 212,164 222,167 231,167 241,166 250,163 258,159 265,153 271,146 275,138 278,129 279,120
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`. Complex arithmetic is a small struct written out at the top.

```rust
// The argument principle -- the same check as the Python, in Rust.  No crates.
// Walk a circle and count the turns of f(z) round 0 by two roads that share
// nothing but f.  Road one: (1/2 pi i) times a trapezoid sum of f'/f dz.  Road
// two: a compass needle, adding the small turn between neighbouring values.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C {
    C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn abs(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
type F = fn(C) -> (C, C);                                  // value, derivative
fn f(z: C) -> (C, C) { (z * (z - c(0.4, 0.0)), c(2.0, 0.0) * z - c(0.4, 0.0)) }
fn g(z: C) -> (C, C) {
    let (a, b) = (z - c(0.5, 0.0), z - c(2.0, 0.0));
    (a / (b * b * b), (b - c(3.0, 0.0) * a) / (b * b * b * b))
}
fn zbar(z: C) -> (C, C) { (c(z.re, -z.im), c(f64::NAN, 0.0)) }  // no derivative exists

fn walk(r: f64, n: usize) -> Vec<C> {                      // n + 1 points round |z| = r
    (0..=n).map(|k| { let t = 2.0 * PI * k as f64 / n as f64; c(r * t.cos(), r * t.sin()) }).collect()
}
fn integral(h: F, r: f64, n: usize) -> C {                 // road one: (1/2 pi i) x sum of f'/f dz
    let mut total = c(0.0, 0.0);
    for &z in &walk(r, n)[..n] { let (v, d) = h(z); total = total + d / v * c(0.0, 1.0) * z * c(2.0 * PI / n as f64, 0.0); }
    total / c(0.0, 2.0 * PI)
}
fn compass(h: F, r: f64, n: usize, marks: usize) -> (f64, Vec<f64>) {  // road two: the needle's turns
    let (pts, mut turn, mut seen) = (walk(r, n), 0.0, vec![0.0]);
    for k in 0..n {
        let q = h(pts[k + 1]).0 / h(pts[k]).0;
        turn += q.im.atan2(q.re);
        if marks > 0 && (k + 1) % (n / marks) == 0 { seen.push(turn / (2.0 * PI)); }
    }
    (turn / (2.0 * PI), seen)
}
fn show(z: C) -> String {
    let (re, im) = ((z.re * 1e6).round() / 1e6 + 0.0, (z.im * 1e6).round() / 1e6 + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn sci(x: f64) -> String { let e = x.log10().floor(); format!("{:.1}e{}", x / 10f64.powf(e), e as i32) }
fn count(zeros: &[(f64, i32)], poles: &[(f64, i32)], r: f64) -> i32 {  // road three: located, with multiplicity
    zeros.iter().filter(|p| p.0.abs() < r).map(|p| p.1).sum::<i32>() - poles.iter().filter(|p| p.0.abs() < r).map(|p| p.1).sum::<i32>()
}

fn main() {
    let (fz, gz, gp): (&[(f64, i32)], &[(f64, i32)], &[(f64, i32)]) = (&[(0.0, 1), (0.4, 1)], &[(0.5, 1)], &[(2.0, 3)]);
    let cases: [(&str, F, &[(f64, i32)], &[(f64, i32)], f64); 4] = [("z(z - 0.4)", f, fz, &[], 1.0), ("z(z - 0.4)", f, fz, &[], 0.2),
        ("(z - 0.5)/(z - 2)^3", g, gz, gp, 1.0), ("(z - 0.5)/(z - 2)^3", g, gz, gp, 3.0)];
    let mut gap: f64 = 0.0;
    for (name, h, zs, ps, r) in cases {
        let (truth, i1, c2) = (count(zs, ps, r), integral(h, r, 256), compass(h, r, 256, 0).0);
        gap = gap.max(abs(i1 - c(truth as f64, 0.0))).max((c2 - truth as f64).abs());
        println!("{} round |z| = {}: N - P = {}; integral = {}; compass = {:.6}", name, r, truth, show(i1), c2);
    }
    let errs: Vec<f64> = [8, 16, 32].iter().map(|&n| abs(integral(f, 1.0, n) - c(2.0, 0.0))).collect();
    println!("z(z - 0.4), |z| = 1, integral error at 8, 16, 32 points: {}", errs.iter().map(|&e| sci(e)).collect::<Vec<_>>().join(", "));
    let marks = compass(f, 1.0, 256, 8).1;
    println!("needle turns at 0, 1/8, ..., 8/8 of the walk: {}", marks.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", "));
    let few: Vec<f64> = [3, 4, 5].iter().map(|&n| compass(f, 1.0, n, 0).0).collect();
    println!("compass sampled at only 3, 4, 5 points: {}", few.iter().map(|x| format!("{}", (x + 0.5).floor() as i32)).collect::<Vec<_>>().join(", "));
    let cz = compass(zbar, 1.0, 256, 0).0;
    println!("break, z-bar round |z| = 1 (one zero inside, not holomorphic): compass = {:.6}", cz);
    println!("mistake, pole of order 3 counted once, |z| = 3: 1 - 1 = 0, not {}", count(gz, gp, 3.0));
    println!("figure, left 55 units per 1, 0 at (75, 120), zeros at (75, 120) and (97, 120); right 65 units per 1, 0 at (240, 120)");
    let img: Vec<String> = walk(1.0, 72).iter().map(|&z| { let w = f(z).0;
        format!("{},{}", (240.0 + 65.0 * w.re + 0.5).floor(), (120.0 - 65.0 * w.im + 0.5).floor()) }).collect();
    println!("figure, image points: {}", img.join(" "));
    assert!(gap < 1e-9);                                   // both roads land on N - P in all four cases
    assert!(errs[2] < errs[1] && errs[1] < errs[0] && errs[2] < 1e-9);  // the trapezoid error shrinks
    assert!((few[2] - integral(f, 1.0, 256).re).abs() < 1e-9 && (few[0] - 2.0).abs() > 2.5);  // 5 suffice, 3 miss
    assert!((cz + count(&[(0.0, 1)], &[], 1.0) as f64).abs() < 1e-9);  // z-bar turns the other way: -1
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
z(z - 0.4) round |z| = 1: N - P = 2; integral = 2.000000 + 0.000000i; compass = 2.000000
z(z - 0.4) round |z| = 0.2: N - P = 1; integral = 1.000000 + 0.000000i; compass = 1.000000
(z - 0.5)/(z - 2)^3 round |z| = 1: N - P = 1; integral = 1.000000 + 0.000000i; compass = 1.000000
(z - 0.5)/(z - 2)^3 round |z| = 3: N - P = -2; integral = -2.000000 + 0.000000i; compass = -2.000000
z(z - 0.4), |z| = 1, integral error at 8, 16, 32 points: 6.6e-4, 4.3e-7, 1.8e-13
needle turns at 0, 1/8, ..., 8/8 of the walk: 0.00, 0.31, 0.56, 0.78, 1.00, 1.22, 1.44, 1.69, 2.00
compass sampled at only 3, 4, 5 points: -1, 0, 2
break, z-bar round |z| = 1 (one zero inside, not holomorphic): compass = -1.000000
mistake, pole of order 3 counted once, |z| = 3: 1 - 1 = 0, not -2
figure, left 55 units per 1, 0 at (75, 120), zeros at (75, 120) and (97, 120); right 65 units per 1, 0 at (240, 120)
figure, image points: 279,120 278,111 275,102 271,94 265,87 258,81 250,77 241,74 231,73 222,73 212,76 203,80 195,86 187,94 181,103 177,113 174,123 174,135 175,146 178,157 183,168 190,178 199,186 209,193 220,199 233,202 245,204 258,203 271,201 284,196 295,189 305,181 314,171 321,159 327,147 330,134 331,120 330,106 327,93 321,81 314,69 305,59 295,51 284,44 271,39 258,37 245,36 233,38 221,41 209,47 199,54 190,62 183,72 178,83 175,94 174,105 174,117 177,127 181,137 187,146 194,154 203,160 212,164 222,167 231,167 241,166 250,163 258,159 265,153 271,146 275,138 278,129 279,120
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the argument principle for every circle, both as a loop integral and as needle turns, and the residue at each zero and pole.

- For f and any circle C meeting the three conditions in When it holds, the loop integral of f′/f round C, divided by 2πi, is N − P.
- Under the same conditions, the needle's angle can be kept continuous along the walk. Every such angle gains exactly 2π(N − P): N − P turns.
- Near a zero a of multiplicity m, f′/f = m/(z − a) + h′/h. So round a small circle at a, the integral over 2πi is m. A pole of order p gives −p.
- The hand arithmetic holds exactly: both f′/f splits, which points lie inside which circle, the four counts, and the pole counted once giving 0.

The z-bar break, the trapezoid error, the coarse compass readings, every decimal and the figure are left to the Python and Rust checks.

```lean
-- The argument principle: for a function holomorphic on and inside a circle except at poles, with no zero or pole on the circle and not identically zero, the loop integral of f′/f divided by 2πi, and the needle's total turn along the walk counted in whole turns, both equal the zeros inside minus the poles inside, each counted by its multiplicity or order.
import Mathlib.Analysis.Meromorphic.Divisor
import Mathlib.Analysis.Calculus.LogDeriv
import Mathlib.Analysis.SpecialFunctions.Complex.CircleMap
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Meromorphic.FactorizedRational
import Mathlib.Analysis.Normed.Module.Ball.Pointwise
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.MetricSpace.Thickening

/-! The plane is `ℂ`; `I` is i. The loop C is the circle `|z - c| = R`, walked once
anticlockwise: `circleMap c R t = c + R e^(it)` for `0 ≤ t ≤ 2π`, and `∮ z in C(c, R), F z` is the
loop integral of `F` round it. `logDeriv f z = deriv f z / f z` is the logarithmic derivative
f′/f. `MeromorphicOn f (closedBall c R)` says f is holomorphic on and inside the circle except at
isolated poles. `MeromorphicOn.divisor f (closedBall c R) a` is the whole number m at a zero of
multiplicity m, −p at a pole of order p, and 0 elsewhere; its positive part `⁺` counts zeros and
its negative part `⁻` counts poles. `ball c R` is the inside of the circle. -/

namespace TheArgumentPrinciple

open Complex Metric Set

theorem circleIntegral_logDeriv_eq_zero_aux {g : ℂ → ℂ} {c : ℂ} {r : ℝ} (hr : 0 ≤ r)
    (hg : ∀ z ∈ closedBall c r, AnalyticAt ℂ g z ∧ g z ≠ 0) :
    (∮ z in C(c, r), logDeriv g z) = 0 := by
  have hd : ∀ z ∈ closedBall c r, DifferentiableAt ℂ (logDeriv g) z := fun z hz => by
    obtain ⟨ha, hne⟩ := hg z hz
    exact ha.deriv.differentiableAt.div ha.differentiableAt hne
  exact circleIntegral_eq_zero_of_differentiable_on_off_countable hr Set.countable_empty
    (fun z hz => (hd z hz).continuousAt.continuousWithinAt)
    (fun z hz => hd z (ball_subset_closedBall hz.1))

open Classical in
theorem circleIntegral_sub_inv_aux {c u : ℂ} {r : ℝ} (hr : 0 < r) (hu : u ∉ sphere c r) :
    (∮ z in C(c, r), (z - u)⁻¹) = if u ∈ ball c r then 2 * Real.pi * I else 0 := by
  split_ifs with h
  · exact circleIntegral.integral_sub_inv_of_mem_ball h
  · have hu' : u ∉ closedBall c r := by
      intro h'
      rcases (mem_closedBall.1 h').lt_or_eq with h1 | h1
      · exact h (mem_ball.2 h1)
      · exact hu (mem_sphere.2 h1)
    have hd : ∀ z ∈ closedBall c r, DifferentiableAt ℂ (fun z => (z - u)⁻¹) z := fun z hz =>
      (differentiableAt_id.sub_const u).inv (sub_ne_zero.2 fun h => hu' (h ▸ hz))
    exact circleIntegral_eq_zero_of_differentiable_on_off_countable hr.le Set.countable_empty
      (fun z hz => (hd z hz).continuousAt.continuousWithinAt)
      (fun z hz => hd z (ball_subset_closedBall hz.1))

open Classical in
theorem circleIntegral_formula_aux {F g : ℂ → ℂ} {c : ℂ} {r : ℝ} (hr : 0 < r) (s : Finset ℂ)
    (D : ℂ → ℤ) (hs : ∀ u ∈ s, u ∉ sphere c r)
    (hg : ∀ z ∈ closedBall c r, AnalyticAt ℂ g z ∧ g z ≠ 0)
    (hF : ∀ z ∈ sphere c r, F z = ∑ u ∈ s, (D u : ℂ) * (z - u)⁻¹ + logDeriv g z) :
    (2 * Real.pi * I)⁻¹ * (∮ z in C(c, r), F z)
      = ∑ u ∈ s, if u ∈ ball c r then (D u : ℂ) else 0 := by
  have hc : ∀ u ∈ s, ContinuousOn (fun z : ℂ => (D u : ℂ) * (z - u)⁻¹) (sphere c r) :=
    fun u hu => continuousOn_const.mul ((continuousOn_id.sub continuousOn_const).inv₀
      fun z hz h => hs u hu (by have : z = u := sub_eq_zero.1 h; exact this ▸ hz))
  have hgc : ContinuousOn (logDeriv g) (sphere c r) := fun z hz => by
    obtain ⟨ha, hne⟩ := hg z (sphere_subset_closedBall hz)
    exact (ha.deriv.continuousAt.div ha.continuousAt hne).continuousWithinAt
  rw [circleIntegral.integral_congr hr.le hF, circleIntegral.integral_add
    (ContinuousOn.circleIntegrable hr.le (continuousOn_finsetSum _ hc))
    (hgc.circleIntegrable hr.le),
    circleIntegral.integral_fun_sum (fun u hu => (hc u hu).circleIntegrable hr.le),
    circleIntegral_logDeriv_eq_zero_aux hr.le hg, add_zero, Finset.mul_sum]
  refine Finset.sum_congr rfl fun u hu => ?_
  rw [circleIntegral.integral_const_mul, circleIntegral_sub_inv_aux hr (hs u hu)]
  have h2 : (2 * (Real.pi : ℂ) * I) ≠ 0 := by simp [Real.pi_ne_zero, I_ne_zero]
  split_ifs
  · field_simp
  · simp


open Classical in
theorem finsum_divisor_aux {f : ℂ → ℂ} {c : ℂ} {R : ℝ} {K : Set ℂ} (s : Finset ℂ)
    (hmero : MeromorphicOn f (closedBall c R)) (hmK : MeromorphicOn f K)
    (hBK : ball c R ⊆ K) (hs : ∀ a, MeromorphicOn.divisor f K a ≠ 0 → a ∈ s) :
    ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) : ℂ)
        - ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) : ℂ)
      = ∑ u ∈ s, if u ∈ ball c R then (MeromorphicOn.divisor f K u : ℂ) else 0 := by
  have hDD : ∀ a ∈ ball c R,
      MeromorphicOn.divisor f (closedBall c R) a = MeromorphicOn.divisor f K a := fun a ha => by
    rw [hmero.divisor_apply (ball_subset_closedBall ha), hmK.divisor_apply (hBK ha)]
  have key : ∀ F : ℤ → ℤ, F 0 = 0 →
      (∑ᶠ a ∈ ball c R, F (MeromorphicOn.divisor f (closedBall c R) a))
        = ∑ u ∈ s, if u ∈ ball c R then F (MeromorphicOn.divisor f K u) else 0 := by
    intro F hF0
    rw [finsum_mem_def, finsum_eq_sum_of_support_subset _ (s := s)]
    · refine Finset.sum_congr rfl fun u _ => ?_
      rw [Set.indicator_apply]
      split_ifs with h
      · rw [hDD u h]
      · rfl
    · intro a ha
      rw [Function.mem_support, Set.indicator_apply] at ha
      split_ifs at ha with hb
      · apply hs
        intro h0
        rw [hDD a hb, h0, hF0] at ha
        exact ha rfl
      · exact absurd rfl ha
  rw [key (fun x => x⁺) (by simp), key (fun x => x⁻) (by simp)]
  push_cast
  rw [← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun u _ => ?_
  split_ifs
  · rw [← Int.cast_sub, posPart_sub_negPart]
  · simp

#print axioms finsum_divisor_aux

theorem int_ne_add_half_aux (m n : ℤ) : (m : ℝ) ≠ n + 1 / 2 := by
  intro h
  have h' : ((2 * m : ℤ) : ℝ) = ((2 * n + 1 : ℤ) : ℝ) := by push_cast; linarith
  have := Int.cast_injective h'
  omega

#print axioms int_ne_add_half_aux

#print axioms circleIntegral_logDeriv_eq_zero_aux
#print axioms circleIntegral_sub_inv_aux
#print axioms circleIntegral_formula_aux

/-- **The argument principle, as a loop integral.** Let C be the circle `|z - c| = R`, walked once
anticlockwise. Let f be holomorphic (have a complex derivative) inside and on C except at poles,
with no zero or pole on C (f is holomorphic and nonzero at every point of C), and f not
identically zero. Let N be the number of zeros inside C, each counted by its multiplicity, and P
the number of poles inside C, each counted by its order. Then
`(1/2πi) ∮_C f′(z)/f(z) dz = N − P`. -/
theorem loop_integral_of_log_deriv_eq_zeros_sub_poles
    (f : ℂ → ℂ) (c : ℂ) (R : ℝ) (hR : 0 < R)
    (hmero : MeromorphicOn f (closedBall c R))
    (hC : ∀ z ∈ sphere c R, AnalyticAt ℂ f z ∧ f z ≠ 0)
    (hne : ∃ z ∈ closedBall c R, f z ≠ 0) :
    (2 * Real.pi * I)⁻¹ * (∮ z in C(c, R), logDeriv f z)
      = ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) : ℂ)
        - ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) : ℂ) := by
  -- enlarge the closed disc to a slightly bigger one on which f is still meromorphic
  set V := ball c R ∪ {z | AnalyticAt ℂ f z} with hV
  have hVo : IsOpen V := isOpen_ball.union (isOpen_analyticAt ℂ f)
  have hKV : closedBall c R ⊆ V := by
    intro z hz
    rcases (mem_closedBall.1 hz).lt_or_eq with h | h
    · exact Or.inl (mem_ball.2 h)
    · exact Or.inr (hC z (mem_sphere.2 h)).1
  obtain ⟨δ, hδ, hδV⟩ := (isCompact_closedBall c R).exists_thickening_subset_open hVo hKV
  rw [thickening_closedBall hδ hR.le] at hδV
  have hRR' : R < R + δ / 2 := by linarith
  have hK'V : closedBall c (R + δ / 2) ⊆ V :=
    (closedBall_subset_ball (by linarith : R + δ / 2 < δ + R)).trans hδV
  set K := closedBall c (R + δ / 2) with hK
  have hmK : MeromorphicOn f K := fun z hz => by
    rcases hK'V hz with h | h
    · exact hmero z (ball_subset_closedBall h)
    · exact (show AnalyticAt ℂ f z from h).meromorphicAt
  have hord0 : ∀ z ∈ sphere c R, meromorphicOrderAt f z = 0 := fun z hz =>
    (hC z hz).1.meromorphicNFAt.meromorphicOrderAt_eq_zero_iff.2 (hC z hz).2
  obtain ⟨z0, hz0⟩ : (sphere c R).Nonempty := NormedSpace.sphere_nonempty.2 hR.le
  have hsphK : sphere c R ⊆ K :=
    sphere_subset_closedBall.trans (closedBall_subset_closedBall hRR'.le)
  have hBK : ball c R ⊆ K := ball_subset_closedBall.trans (closedBall_subset_closedBall hRR'.le)
  have hntop : ∀ u : K, meromorphicOrderAt f u ≠ ⊤ := fun u =>
    hmK.meromorphicOrderAt_ne_top_of_isPreconnected (convex_closedBall c _).isPreconnected
      (hsphK hz0) u.2 (by rw [hord0 z0 hz0]; exact WithTop.zero_ne_top)
  have hfin : (MeromorphicOn.divisor f K).support.Finite :=
    (MeromorphicOn.divisor f K).finiteSupport (isCompact_closedBall c _)
  obtain ⟨g, hg_an, hg_ne, hfg⟩ := hmK.extract_zeros_poles hntop hfin
  set D := MeromorphicOn.divisor f K with hD
  have hD0 : ∀ z ∈ sphere c R, D z = 0 := fun z hz => by
    rw [hD, hmK.divisor_apply (hsphK hz), hord0 z hz]; rfl
  set s := hfin.toFinset with hs
  have hsph : ∀ u ∈ s, u ∉ sphere c R := fun u hu hu' => by
    rw [hs, Set.Finite.mem_toFinset] at hu; exact hu (hD0 u hu')
  have hP : (∏ᶠ u, (· - u) ^ D u) = fun z => ∏ u ∈ s, (z - u) ^ D u := by
    rw [finprod_eq_prod_of_mulSupport_subset _ (s := s)
      (by rw [Function.FactorizedRational.mulSupport]; simp [s])]
    ext z; simp [Finset.prod_apply]
  have hkey : ∀ z ∈ sphere c R,
      logDeriv f z = ∑ u ∈ s, (D u : ℂ) * (z - u)⁻¹ + logDeriv g z := by
    intro z hz
    have hzK := hsphK hz
    have hzs : ∀ u ∈ s, z - u ≠ 0 := fun u hu h => hsph u hu (by
      have : z = u := sub_eq_zero.1 h
      exact this ▸ hz)
    set P : ℂ → ℂ := fun w => ∏ u ∈ s, (w - u) ^ D u with hPdef
    have hPd : DifferentiableAt ℂ P z :=
      DifferentiableAt.fun_finsetProd (f := fun u w => (w - u) ^ D u) fun u hu =>
        (differentiableAt_id.sub_const u).zpow (Or.inl (hzs u hu))
    have hPne : P z ≠ 0 := Finset.prod_ne_zero_iff.2 fun u hu => zpow_ne_zero _ (hzs u hu)
    have hzint : K ∈ nhds z := closedBall_mem_nhds_of_mem (mem_ball.2 (by
      have := mem_sphere.1 hz; linarith))
    have h1 : Filter.EventuallyEq (nhdsWithin z {z}ᶜ) f (fun w => P w * g w) := by
      filter_upwards [mem_codiscreteWithin_iff_forall_mem_nhdsNE.1 hfg z hzK,
        nhdsWithin_le_nhds hzint] with w hw hwK
      have := hw.resolve_right (not_not_intro hwK)
      simpa [hP, P] using this
    have hfe : Filter.EventuallyEq (nhds z) f (fun w => P w * g w) :=
      (ContinuousAt.eventuallyEq_nhds_iff_eventuallyEq_nhdsNE (hC z hz).1.continuousAt
        (hPd.continuousAt.mul (hg_an z hzK).continuousAt)).1 h1
    rw [(logDeriv_congr_nhds hfe).eq_of_nhds, logDeriv_fun_mul z hPne (hg_ne ⟨z, hzK⟩) hPd
      (hg_an z hzK).differentiableAt]
    congr 1
    rw [show P = ∏ u ∈ s, (fun w => (w - u) ^ D u) by ext w; simp [P, Finset.prod_apply],
      logDeriv_prod (f := fun u w => (w - u) ^ D u) (fun u hu => zpow_ne_zero _ (hzs u hu))
        (fun u hu => (differentiableAt_id.sub_const u).zpow (Or.inl (hzs u hu)))]
    refine Finset.sum_congr rfl fun u _ => ?_
    rw [logDeriv_fun_zpow (f := fun w => w - u) (differentiableAt_id.sub_const u)]
    simp [logDeriv_apply, div_eq_mul_inv]
  have hgK : ∀ z ∈ closedBall c R, AnalyticAt ℂ g z ∧ g z ≠ 0 := fun z hz =>
    have hz' : z ∈ K := closedBall_subset_closedBall hRR'.le hz
    ⟨hg_an z hz', hg_ne ⟨z, hz'⟩⟩
  rw [circleIntegral_formula_aux hR s D hsph hgK hkey,
    finsum_divisor_aux s hmero hmK hBK (fun a ha => by simpa [s] using ha)]

/-- **Walk the boundary and watch the needle spin.** Same hypotheses as above. Follow the value
f(z) as an arrow from 0 while z walks the circle once anticlockwise, and keep its angle φ
continuous: f(c + R e^(it)) = |f(c + R e^(it))| e^(iφ(t)) for `0 ≤ t ≤ 2π`. Such a continuous angle
exists, and every such angle has total change `φ(2π) − φ(0) = 2π (N − P)`: the needle turns
exactly N − P times round 0. -/
theorem needle_turns_eq_zeros_sub_poles
    (f : ℂ → ℂ) (c : ℂ) (R : ℝ) (hR : 0 < R)
    (hmero : MeromorphicOn f (closedBall c R))
    (hC : ∀ z ∈ sphere c R, AnalyticAt ℂ f z ∧ f z ≠ 0)
    (hne : ∃ z ∈ closedBall c R, f z ≠ 0) :
    (∃ φ : ℝ → ℝ, ContinuousOn φ (Icc 0 (2 * Real.pi)) ∧
      ∀ t ∈ Icc 0 (2 * Real.pi),
        f (circleMap c R t) = ‖f (circleMap c R t)‖ * exp (φ t * I)) ∧
    ∀ φ : ℝ → ℝ, ContinuousOn φ (Icc 0 (2 * Real.pi)) →
      (∀ t ∈ Icc 0 (2 * Real.pi),
        f (circleMap c R t) = ‖f (circleMap c R t)‖ * exp (φ t * I)) →
      φ (2 * Real.pi) - φ 0
        = 2 * Real.pi *
          (((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) : ℝ)
            - ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) : ℝ)) := by
  have h1 := loop_integral_of_log_deriv_eq_zeros_sub_poles f c R hR hmero hC hne
  set N := (∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) with hN
  set Q := (∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) with hQ
  have h2π : (2 * (Real.pi : ℂ) * I) ≠ 0 := by simp [Real.pi_ne_zero, I_ne_zero]
  have hI : (∮ z in C(c, R), logDeriv f z) = 2 * Real.pi * I * ((N : ℂ) - (Q : ℂ)) := by
    rw [← h1, ← mul_assoc, mul_inv_cancel₀ h2π, one_mul]
  have hγs : ∀ t, circleMap c R t ∈ sphere c R := fun t => circleMap_mem_sphere c hR.le t
  have hcont_ld : ∀ w ∈ sphere c R, ContinuousAt (logDeriv f) w := fun w hw => by
    obtain ⟨ha, hne⟩ := hC w hw
    exact ha.deriv.continuousAt.div ha.continuousAt hne
  set F : ℝ → ℂ := fun t => (circleMap 0 R t * I) * logDeriv f (circleMap c R t) with hFdef
  have hFc : Continuous F :=
    ((continuous_circleMap 0 R).mul continuous_const).mul
      (continuous_iff_continuousAt.2 fun t =>
        ContinuousAt.comp (g := logDeriv f) (hcont_ld _ (hγs t))
          (continuous_circleMap c R).continuousAt)
  set L : ℝ → ℂ := fun t => ∫ s in (0 : ℝ)..t, F s with hLdef
  have hL : ∀ t, HasDerivAt L (F t) t := fun t => (hFc.integral_hasStrictDerivAt 0 t).hasDerivAt
  have hLc : Continuous L := continuous_iff_continuousAt.2 fun t => (hL t).continuousAt
  have hfγ : ∀ t, HasDerivAt (fun t => f (circleMap c R t))
      (deriv f (circleMap c R t) * (circleMap 0 R t * I)) t := fun t =>
    ((hC _ (hγs t)).1.differentiableAt.hasDerivAt).comp t (hasDerivAt_circleMap c R t)
  set H : ℝ → ℂ := fun t => f (circleMap c R t) * exp (-L t) with hHdef
  have hH : ∀ t, HasDerivAt H 0 t := by
    intro t
    have := (hfγ t).mul ((hL t).neg.cexp)
    convert this using 1
    have hf0 := (hC _ (hγs t)).2
    simp only [hFdef, logDeriv_apply]
    field_simp
    ring
  have hHc : ∀ t, H t = H 0 := fun t =>
    is_const_of_deriv_eq_zero (fun t => (hH t).differentiableAt) (fun t => (hH t).deriv) t 0
  have hL0 : L 0 = 0 := intervalIntegral.integral_same
  have hrep : ∀ t, f (circleMap c R t) = f (circleMap c R 0) * exp (L t) := by
    intro t
    have := hHc t
    simp only [hHdef, hL0, neg_zero, exp_zero, mul_one] at this
    rw [← this, mul_assoc, ← exp_add, neg_add_cancel, exp_zero, mul_one]
  have hL2π : L (2 * Real.pi) = 2 * Real.pi * I * ((N : ℂ) - (Q : ℂ)) := by
    rw [← hI]
    simp only [hLdef, hFdef, circleIntegral, deriv_circleMap, smul_eq_mul]
  set φ0 : ℝ → ℝ := fun t => arg (f (circleMap c R 0)) + (L t).im with hφ0def
  have hφ0c : Continuous φ0 := continuous_const.add (continuous_im.comp hLc)
  have hφ0 : ∀ t, f (circleMap c R t) = ‖f (circleMap c R t)‖ * exp (φ0 t * I) := by
    intro t
    rw [hrep t, norm_mul, Complex.norm_exp]
    conv_lhs => rw [← Complex.norm_mul_exp_arg_mul_I (f (circleMap c R 0)), ← Complex.re_add_im (L t)]
    simp only [hφ0def]
    push_cast
    simp only [add_mul, exp_add]
    ring
  refine ⟨⟨φ0, hφ0c.continuousOn, fun t _ => hφ0 t⟩, fun ψ hψc hψ => ?_⟩
  have key : ∀ t ∈ Icc 0 (2 * Real.pi), ∃ n : ℤ, ψ t - φ0 t = n * (2 * Real.pi) := by
    intro t ht
    have h := (hψ t ht).symm.trans (hφ0 t)
    have hn0 : ((‖f (circleMap c R t)‖ : ℝ) : ℂ) ≠ 0 := by
      simpa using (hC _ (hγs t)).2
    obtain ⟨n, hn⟩ := Complex.exp_eq_exp_iff_exists_int.1 (mul_left_cancel₀ hn0 h)
    refine ⟨n, ?_⟩
    have := congrArg Complex.im hn
    simp at this
    linarith
  have hpi : 0 < 2 * Real.pi := by positivity
  obtain ⟨n0, hn0⟩ := key 0 ⟨le_rfl, hpi.le⟩
  obtain ⟨n1, hn1⟩ := key (2 * Real.pi) ⟨hpi.le, le_rfl⟩
  have hcd : ContinuousOn (fun t => ψ t - φ0 t) (Icc 0 (2 * Real.pi)) :=
    hψc.sub hφ0c.continuousOn
  have hn01 : n0 = n1 := by
    by_contra hneq
    rcases lt_or_gt_of_ne hneq with hlt | hlt
    · have hle : ((n0 : ℝ) + 1 / 2) ≤ n1 := by
        have : (n0 : ℝ) + 1 ≤ n1 := by exact_mod_cast hlt
        linarith
      have hmem : ((n0 : ℝ) + 1 / 2) * (2 * Real.pi) ∈
          Icc (ψ 0 - φ0 0) (ψ (2 * Real.pi) - φ0 (2 * Real.pi)) := by
        rw [hn0, hn1]
        constructor <;> nlinarith
      obtain ⟨t, ht, hteq⟩ := intermediate_value_Icc hpi.le hcd hmem
      obtain ⟨m, hm⟩ := key t ht
      have : (m : ℝ) = n0 + 1 / 2 := by
        have := hm.symm.trans hteq
        exact mul_right_cancel₀ hpi.ne' this
      exact int_ne_add_half_aux m n0 this
    · have hle : ((n1 : ℝ) + 1 / 2) ≤ n0 := by
        have : (n1 : ℝ) + 1 ≤ n0 := by exact_mod_cast hlt
        linarith
      have hmem : ((n1 : ℝ) + 1 / 2) * (2 * Real.pi) ∈
          Icc (ψ (2 * Real.pi) - φ0 (2 * Real.pi)) (ψ 0 - φ0 0) := by
        rw [hn0, hn1]
        constructor <;> nlinarith
      obtain ⟨t, ht, hteq⟩ := intermediate_value_Icc' hpi.le hcd hmem
      obtain ⟨m, hm⟩ := key t ht
      have : (m : ℝ) = n1 + 1 / 2 := by
        have := hm.symm.trans hteq
        exact mul_right_cancel₀ hpi.ne' this
      exact int_ne_add_half_aux m n1 this
  have hdiff : ψ (2 * Real.pi) - ψ 0 = φ0 (2 * Real.pi) - φ0 0 := by
    rw [hn01] at hn0
    linarith
  rw [hdiff]
  simp only [hφ0def, hL2π, hL0]
  simp [Complex.mul_im]

/-- **Each zero of multiplicity m contributes m; each pole of order p contributes −p.** Near a,
let f(z) = (z − a)^n h(z) on the punctured disc `0 < |z − a| < R`, with h holomorphic and nonzero
on the whole disc `|z − a| < R`; n = m > 0 is a zero of multiplicity m, n = −p < 0 a pole of order
p. Then f′/f = n/(z − a) + h′/h on the punctured disc, so the residue of f′/f at a is n: every
small circle `|z − a| = r` with `0 < r < R` gives `(1/2πi) ∮ f′/f dz = n`. -/
theorem log_deriv_residue_eq_order
    (f h : ℂ → ℂ) (a : ℂ) (R : ℝ) (n : ℤ)
    (hh : DifferentiableOn ℂ h (ball a R)) (hh0 : ∀ z ∈ ball a R, h z ≠ 0)
    (hf : ∀ z ∈ ball a R \ {a}, f z = (z - a) ^ n * h z) :
    (∀ z ∈ ball a R \ {a}, logDeriv f z = n / (z - a) + logDeriv h z) ∧
    ∀ r : ℝ, 0 < r → r < R →
      (2 * Real.pi * I)⁻¹ * (∮ z in C(a, r), logDeriv f z) = n := by
  have h1 : ∀ z ∈ ball a R \ {a}, logDeriv f z = n / (z - a) + logDeriv h z := by
    intro z hz
    have hopen : IsOpen (ball a R \ {a}) := isOpen_ball.sdiff isClosed_singleton
    have heq : Filter.EventuallyEq (nhds z) f (fun w => (w - a) ^ n * h w) :=
      Filter.eventually_of_mem (hopen.mem_nhds hz) hf
    have hza : z - a ≠ 0 := sub_ne_zero.2 hz.2
    have hdh : DifferentiableAt ℂ h z := hh.differentiableAt (isOpen_ball.mem_nhds hz.1)
    rw [(logDeriv_congr_nhds heq).eq_of_nhds, logDeriv_fun_mul (f := fun w => (w - a) ^ n) z (zpow_ne_zero n hza) (hh0 z hz.1)
      ((differentiableAt_id.sub_const a).zpow (Or.inl hza)) hdh,
      logDeriv_fun_zpow (f := fun w => w - a) (differentiableAt_id.sub_const a) n]
    simp [logDeriv_apply, div_eq_mul_inv]
  refine ⟨h1, fun r hr0 hrR => ?_⟩
  have hsub : closedBall a r ⊆ ball a R := closedBall_subset_ball hrR
  have := circleIntegral_formula_aux (F := logDeriv f) (g := h) hr0 {a} (fun _ => n)
    (by simp [hr0.ne]) (fun z hz => ⟨hh.analyticAt (isOpen_ball.mem_nhds (hsub hz)),
      hh0 z (hsub hz)⟩)
    (fun z hz => by
      have hz' : z ∈ ball a R \ {a} := ⟨hsub (sphere_subset_closedBall hz), by
        rintro rfl; simp [hr0.ne] at hz⟩
      rw [h1 z hz']; simp [div_eq_mul_inv])
  rw [this]; simp [hr0]

/-! ### The card's worked numbers, checked exactly (0.4 is written 2/5, 0.5 is 1/2, 0.2 is 1/5) -/

-- f(z) = z(z − 2/5), f′(z) = 2z − 2/5: f′/f = 1/z + 1/(z − 2/5), residue 1 at each zero.
example (z : ℂ) (h0 : z ≠ 0) (h1 : z - 2 / 5 ≠ 0) :
    (2 * z - 2 / 5) / (z * (z - 2 / 5)) = 1 / z + 1 / (z - 2 / 5) := by
  rw [div_add_div _ _ h0 h1, div_eq_div_iff (mul_ne_zero h0 h1) (mul_ne_zero h0 h1)]
  ring

-- g(z) = (z − 1/2)/(z − 2)^3, g′(z) = ((z − 2) − 3(z − 1/2))/(z − 2)^4:
-- g′/g = 1/(z − 1/2) − 3/(z − 2), residue 1 at the zero and −3 at the pole.
example (z : ℂ) (h1 : z - 1 / 2 ≠ 0) (h2 : z - 2 ≠ 0) :
    (((z - 2) - 3 * (z - 1 / 2)) / (z - 2) ^ 4) / ((z - 1 / 2) / (z - 2) ^ 3)
      = 1 / (z - 1 / 2) - 3 / (z - 2) := by
  rw [div_sub_div _ _ h1 h2, div_div_div_eq,
    div_eq_div_iff (mul_ne_zero (pow_ne_zero 4 h2) h1) (mul_ne_zero h1 h2)]
  ring

-- Which points lie inside which circle: 0 and 2/5 inside |z| = 1; only 0 inside |z| = 1/5;
-- 1/2 inside |z| = 1 but 2 outside; both 1/2 and 2 inside |z| = 3.
example : ‖(0 : ℂ)‖ < 1 ∧ ‖(2 / 5 : ℂ)‖ < 1 ∧ ‖(0 : ℂ)‖ < 1 / 5 ∧ ¬ ‖(2 / 5 : ℂ)‖ < 1 / 5 := by
  norm_num [Complex.norm_real]
example : ‖(1 / 2 : ℂ)‖ < 1 ∧ ¬ ‖(2 : ℂ)‖ < 1 ∧ ‖(1 / 2 : ℂ)‖ < 3 ∧ ‖(2 : ℂ)‖ < 3 := by
  norm_num [Complex.norm_real]

-- The counts N − P: 1 + 1 = 2 on |z| = 1; 1 on |z| = 1/5; 1 − 0 = 1 and 1 − 3 = −2 for g.
example : (1 + 1 : ℤ) - 0 = 2 ∧ (1 : ℤ) - 0 = 1 ∧ (1 : ℤ) - 0 = 1 ∧ (1 : ℤ) - 3 = -2 := by decide

-- The mistake: counting the pole of order 3 once gives 1 − 1 = 0, not −2.
example : (1 : ℤ) - 1 = 0 ∧ (1 : ℤ) - 1 ≠ 1 - 3 := by decide

#print axioms loop_integral_of_log_deriv_eq_zeros_sub_poles
#print axioms needle_turns_eq_zeros_sub_poles
#print axioms log_deriv_residue_eq_order

end TheArgumentPrinciple
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'TheArgumentPrinciple.finsum_divisor_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'TheArgumentPrinciple.int_ne_add_half_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'TheArgumentPrinciple.circleIntegral_logDeriv_eq_zero_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'TheArgumentPrinciple.circleIntegral_sub_inv_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'TheArgumentPrinciple.circleIntegral_formula_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'TheArgumentPrinciple.loop_integral_of_log_deriv_eq_zeros_sub_poles' depends on axioms: [propext, Classical.choice, Quot.sound]
'TheArgumentPrinciple.needle_turns_eq_zeros_sub_poles' depends on axioms: [propext, Classical.choice, Quot.sound]
'TheArgumentPrinciple.log_deriv_residue_eq_order' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Widen the small circle.** Change the radius `0.2` to `0.5`. Now 0.4 is inside: all three roads say 2, and every assert passes.
> - **Fewer compass points.** Change `(3, 4, 5)` to `(3, 4, 4)`. The last reading is now 0, not 2, and the third assert stops the run.
> - **Claim a double zero.** In the first case, write the zero at 0.4 as `(0.4, 2)`. Road three says 3, both measuring roads say 2, and the first assert stops the run.

---

## The usual mistake

> [!warning]
> **Trusting a coarse picture of the image curve.** From 3 points the needle for z(z − 0.4) seems to turn −1 times; from 4, 0. A sampled step is read the short way round, so a step that really turns more than half a turn is miscounted. The count is a theorem; a sampled picture is a check, fine enough only when no step turns half a turn.
>
> - **Forgetting the poles, or their order.** For g on |z| = 3 the needle turns −2 times: 1 zero minus 3 for the pole. Counting the pole once gives 0.
> - **A zero on the path.** On |z| = 0.4 the walk hits the zero at 0.4 and the integral does not exist.
> - **Dropping holomorphy.** z-bar has one zero inside |z| = 1, but its needle turns −1 times.

---

## Where you meet it in real life

- **Counting a polynomial's roots in a region.** Walk the circle and count turns; no root is located. [Rouche's theorem](07-rouches-theorem.md) makes it easier still.
- **Stability of feedback control.** A feedback loop is stable when 1 + L(s) has no zeros in the right half-plane; L, the loop's transfer function, is a function of a complex variable s. The **Nyquist criterion** walks up the imaginary axis and round a large half circle, and counts how often the plot of L circles −1: [Nyquist and margins](../../13-Engineering%20mathematics/03-Feedback%20Control/06-nyquist-criterion-and-stability-margins.md).
- **Zeros of the zeta function.** Their count up to a given height is the argument principle round a rectangle: Counting the zeros.
- **Topology.** The winding number is the degree of a circle-to-circle map, generalised to spheres: Homology of spheres, and degree.

> **Say it back**
> Walk a loop and watch f as a needle from 0. Each zero inside adds turns, one per unit of multiplicity; each pole takes turns away, one per unit of order. The reason: f′/f has residue m at a zero of multiplicity m and −p at a pole of order p, and its loop integral is i times the needle's total turn. For z(z − 0.4) on the unit circle the needle turns twice; for (z − 0.5)/(z − 2)^3 once, and −2 times on the circle of radius 3.

---

## What this builds on

- [The residue theorem](../05-Laurent%20Series%2C%20Singularities%20and%20Residues/05-the-residue-theorem.md): the loop integral as 2πi times the residues inside.
- [Zeros and the identity theorem](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/03-zeros-and-the-identity-theorem.md): zeros are isolated and each has a multiplicity.

## Where this goes next

- [Rouche's theorem](07-rouches-theorem.md): two functions close on the loop have the same count.
- [Zeta's zeros and the primes](../09-Special%20Functions%20and%20the%20Zeta%20Function/09-zeros-of-zeta-and-the-primes.md): where zeta's zeros sit, and why primes care.
- [Nyquist and margins](../../13-Engineering%20mathematics/03-Feedback%20Control/06-nyquist-criterion-and-stability-margins.md): the count as a stability test.
- Homology of spheres, and degree: winding number as degree.
- The prime number theorem: no zeta zeros on the line Re s = 1.
- Counting the zeros: the zero count up to height T.

Left open: when f is hard to walk, can a simpler function that stays close to f on the loop give the same count?

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's or author's page.

- Stein, Elias M., and Rami Shakarchi. *Complex Analysis*. Princeton Lectures in Analysis II. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113852/complex-analysis). Chapter 3: the argument principle and Rouché's theorem.
- Orloff, Jeremy. "Topic 11: Argument Principle." 18.04 Complex Variables with Applications, MIT OpenCourseWare, Spring 2018. [Course notes](https://ocw.mit.edu/courses/18-04-complex-variables-with-applications-spring-2018/resources/mit18_04s18_topic11/). Free; the theorem, the winding picture, and the Nyquist criterion.
- Åström, Karl J., and Richard M. Murray. *Feedback Systems: An Introduction for Scientists and Engineers*, 2nd ed. Princeton University Press. [Book site with full text](https://fbswiki.org/wiki/index.php/Feedback_Systems:_An_Introduction_for_Scientists_and_Engineers). The Nyquist criterion, as control engineers use it.
