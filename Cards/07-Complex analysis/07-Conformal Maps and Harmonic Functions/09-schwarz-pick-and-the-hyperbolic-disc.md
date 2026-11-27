# Schwarz-Pick: a holomorphic map of the disc into itself never stretches hyperbolic distance

[Syllabus](../../../SYLLABUS.md) → [Complex analysis](../README.md) → [Conformal Maps and Harmonic Functions](../README.md#s07) → Schwarz-Pick

---

## General Overview

M. C. Escher's woodcut *Circle Limit III* draws fish inside a circle, small near the rim, yet all the same size in their own world. The circle with that way of measuring is the **Poincaré disc**: the unit disc (the points less than 1 from 0) with a ruler that counts a short drawn piece at distance r from 0 as 2/(1 − r^2) times its drawn length ([Three geometries](../../05-Geometry%20and%20trig/06-Beyond%20Euclid/02-spherical-and-hyperbolic-geometry.md)).

The squaring map f(z) = z^2 keeps the disc inside itself. The point 0.5 goes to 0.25, and 0 stays put. On paper the gap from 0 halves, from 0.5 to 0.25. With the disc's own ruler the gap falls from ln 3 = 1.098612 to ln(5/3) = 0.510826.

Every holomorphic map (one with a complex derivative at each point) that sends the disc into itself does the same: it never stretches the disc's distance. The maps that keep distance exactly are the disc's Möbius maps, the fisheye lenses of [Mobius transformations](02-mobius-transformations-and-the-point-at-infinity.md).

**A holomorphic map of the unit disc into itself never increases the disc's hyperbolic distance between two points, and the maps that keep one nonzero distance unchanged keep them all: they are the disc's Möbius maps, its rigid motions without a mirror.**

**What kind of fact this is:** a theorem, proved on this card in Why it works from the Schwarz lemma; the hyperbolic ruler and distance are definitions.

### The picture: one gap on paper and in the disc's world

```
hyperbolic, 0 to 0.5     ██████████████████████ 1.098612
hyperbolic, 0 to 0.25    ██████████ 0.510826
drawn, 0 to 0.5          ██████████ 0.500000
drawn, 0 to 0.25         █████ 0.250000
```

Squaring halves the drawn gap but more than halves the true one.

---

## The formula

Notation first, in words. $`\mathbb{D}`$ is the open unit disc. For a point c inside it, $`\varphi_c(z) = (z - c)/(1 - \bar c z)`$ is the Möbius map, or **Blaschke factor**, that sends c to 0 and keeps the disc; $`\bar c`$ is c mirrored in the real axis. The **pseudo-distance** $`\delta(z, w) = \lvert\varphi_w(z)\rvert`$ is how far z lands from 0 once w is moved to 0.

The **hyperbolic distance** d uses $`\mathrm{artanh}\, x = \tfrac12 \ln\frac{1 + x}{1 - x}`$, the inverse hyperbolic tangent:

```math
d(z, w) = 2\,\mathrm{artanh}\,\delta(z, w) = \ln\frac{1 + \delta}{1 - \delta}, \qquad \delta(z, w) = \left\lvert \frac{z - w}{1 - \bar w z} \right\rvert
```

**Read it aloud:** move w to 0, see how far z lands from 0, and turn that drawn distance into a true one with twice the inverse hyperbolic tangent.

The theorem has a distance form and a stretch form:

```math
d\big(f(z), f(w)\big) \le d(z, w), \qquad \frac{\lvert f'(z)\rvert\,(1 - \lvert z\rvert^2)}{1 - \lvert f(z)\rvert^2} \le 1
```

**Read it aloud:** f never moves two points farther apart in the disc's world, and at each point it stretches the disc's ruler by a factor of at most 1.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`f`$, $`\mathbb{D}`$ | a holomorphic map; the open unit disc it maps into itself | z^2 | — |
| $`z`$, $`w`$, $`a`$; r, t | points of the disc; drawn distances from 0 | 0.5, −0.5, a = 0.5; r = 0.5 | nearer the rim, larger distances |
| $`f'(z)`$ | the complex derivative: drawn stretch and turn | 2z, size 1 at 0.5 | a larger factor, still at most 1 |
| $`\varphi_c`$, $`m`$, $`p`$ | the disc map sending c to 0; $`m = \varphi_{0.5}`$, $`p = \varphi_{-0.5}`$ | m(0.5) = 0, m(0) = −0.5 | — |
| $`g`$, $`s`$, $`u`$ | proof only: f moved to fix 0; any disc map fixing 0; a point near 0 | $`g = \varphi_{0.25} \circ f \circ p`$ | — |
| $`\delta(z, w)`$ | pseudo-distance, below 1 | δ(0, 0.5) = 0.5 | d grows without limit as δ nears 1 |
| $`d(z, w)`$ | hyperbolic distance | d(0, 0.5) = ln 3 = 1.098612 | — |
| $`\mathrm{artanh}`$, $`\cosh`$ | inverse hyperbolic tangent; hyperbolic cosine $`(e^x + e^{-x})/2`$ | artanh 0.5 = 0.549306 | — |

### When it holds

- **f maps the disc into the disc.** 2z^2 sends 0.8 to 1.28, outside, and its stretch at 0.5 is 2.
- **f holomorphic.** Square-rooting each point's distance from 0, direction kept, sends 0.25 to 0.5: the distance from 0 grows from 0.510826 to 1.098612. The mirror $`\bar z`$ keeps distances but reverses angles.
- **The disc's ruler, not the drawn one.** The Möbius map p stretches drawn lengths at −0.5 by 1.333333, yet keeps hyperbolic lengths exactly.

---

## Why it works

### Step 0: move both points to the centre, then use the Schwarz lemma

The Schwarz lemma handles one case: a holomorphic map of the disc into itself fixing 0 satisfies $`\lvert s(z)\rvert \le \lvert z\rvert`$ and $`\lvert s'(0)\rvert \le 1`$ ([The maximum modulus principle](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/05-maximum-modulus-principle.md), in a fold). Möbius maps can move a to 0 before f acts and f(a) to 0 after it, turning that case into the general one.

### Step 1: the Möbius maps keep the disc's ruler

The map $`\varphi_c`$ sends the disc onto itself, and its reverse is $`\varphi_{-c}`$. Expanding $`\lvert 1 - \bar c z\rvert^2 - \lvert z - c\rvert^2`$ gives the key identity:

```math
1 - \lvert\varphi_c(z)\rvert^2 = \frac{(1 - \lvert c\rvert^2)(1 - \lvert z\rvert^2)}{\lvert 1 - \bar c z\rvert^2}, \qquad \varphi_c'(z) = \frac{1 - \lvert c\rvert^2}{(1 - \bar c z)^2}
```

Divide one by the other: $`\lvert\varphi_c'(z)\rvert / (1 - \lvert\varphi_c(z)\rvert^2) = 1/(1 - \lvert z\rvert^2)`$. So $`\varphi_c`$ stretches the disc's ruler by exactly 1 everywhere.

For m at 0.5: the drawn stretch is 0.75/0.75^2 = 1.333333, the weights are 0.75 and 1, and the hyperbolic stretch is 1.000000.

### Step 2: the distance formula

Distances survive $`\varphi_w`$, so d(z, w) equals the distance from 0 to $`\varphi_w(z)`$. Turn that point onto the positive real axis; turning keeps the ruler too. From 0 to a real r the shortest route is the radius, since sideways steps add length. Summing the ruler 2/(1 − t^2) from 0 to r gives ln((1 + r)/(1 − r)) = 2 artanh r. With r = δ(z, w), that is the formula.

Simpson's rule on the ruler agrees: ln 3 = 1.098612 and ln(5/3) = 0.510826.

<details>
<summary>A second formula for d, with no Möbius map in it</summary>

Put c = w and the identity of Step 1 gives $`1 - \delta^2 = (1 - \lvert z\rvert^2)(1 - \lvert w\rvert^2)/\lvert 1 - \bar w z\rvert^2`$. Since $`\cosh(2\,\mathrm{artanh}\,\delta) = (1 + \delta^2)/(1 - \delta^2) = 1 + 2\delta^2/(1 - \delta^2)`$,

$`\displaystyle \cosh d(z, w) = 1 + \frac{2\lvert z - w\rvert^2}{(1 - \lvert z\rvert^2)(1 - \lvert w\rvert^2)}.`$

From 0.5 to −0.5 both formulas give 2.197225; from 0.25 to 0.5i both give 1.250290.

</details>

### Step 3: Schwarz-Pick

Fix a point a and set $`g = \varphi_{f(a)} \circ f \circ \varphi_{-a}`$. Here $`\varphi_{-a}`$ sends 0 to a, f sends a to f(a), and $`\varphi_{f(a)}`$ sends f(a) back to 0. So g maps the disc into itself and fixes 0, and the Schwarz lemma applies.

- **Distance form.** Put $`u = \varphi_a(z)`$. Then $`g(u) = \varphi_{f(a)}(f(z))`$, and $`\lvert g(u)\rvert \le \lvert u\rvert`$ reads $`\delta(f(z), f(a)) \le \delta(z, a)`$. Twice artanh is increasing, so $`d(f(z), f(a)) \le d(z, a)`$.
- **Stretch form.** The chain rule gives $`g'(0) = \varphi_{f(a)}'(f(a))\, f'(a)\, \varphi_{-a}'(0) = f'(a)(1 - \lvert a\rvert^2)/(1 - \lvert f(a)\rvert^2)`$, and $`\lvert g'(0)\rvert \le 1`$.

For z^2 at a = 0.5 the weights give 0.8; a difference quotient on g itself gives 0.800000.

### Step 4: the holomorphic rigid motions are exactly the Möbius maps

Step 1 shows each $`\varphi_c`$ keeps every distance, and so does each turn about 0. Conversely, suppose a holomorphic self-map f keeps the distance between a and one other point z. Then $`\lvert g(u)\rvert = \lvert u\rvert`$ at one u other than 0, the Schwarz lemma's equality case. So g is a turn, and $`f = \varphi_{-f(a)} \circ (\text{turn}) \circ \varphi_a`$ is a Möbius map of the disc. A rigid motion without a mirror is holomorphic anyway, since it keeps angles and orientation ([The complex derivative](../02-Holomorphic%20Functions/01-complex-derivative-and-cauchy-riemann.md)).

[The Riemann mapping theorem](08-riemann-mapping-theorem-and-schwarz-christoffel.md) proves that Blaschke factors followed by turns are all the disc's one-to-one maps onto itself; this card shows they are its rigid motions. Over 5778 grid pairs, m keeps every distance (ratios 1.000000 to 1.000000); z^2 never exceeds 0.987281.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| image of 0.5 | 0.5 × 0.5 | 0.25 |
| drawn stretch | \|f'(0.5)\| = 2 × 0.5 | 1 |
| weights | 1 − 0.5^2 and 1 − 0.25^2 | 0.75 and 0.9375 |
| stretch of the ruler | 1 × 0.75 / 0.9375 | **0.8**, at most 1 |
| distance 0 to 0.5 | ln((1 + 0.5)/(1 − 0.5)) = ln 3 | 1.098612 |
| distance 0 to 0.25 | ln(1.25/0.75) = ln(5/3) | **0.510826**, shrunk |
| distance 0.5 to −0.5 | ln 3 + ln 3, along the diameter | 2.197225 |
| after squaring | both land on 0.25 | **0** |

At 0.5, z^2 keeps drawn lengths but shrinks the disc's by a fifth; it folds 0.5 and −0.5 together, collapsing a gap of 2.197225 to 0.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Expecting \|f'\| ≤ 1 for p at −0.5 | 1.333333 | The bound is on the disc's ruler, which gives 1.000000 |
| Ruler 1/(1 − t^2), no factor 2 | 0.549306 from 0 to 0.5, not 1.098612 | A different, half-size ruler |
| Schwarz lemma on p without moving 0 back | \|p(0)\| = 0.5 > \|0\| | The lemma needs f(0) = 0 |
| 2z^2, which leaves the disc | stretch 2 at 0.5; 2z^2 at 0.8 is 1.28 | The map must land inside the disc |

---

## Code, from first principles, and it actually runs

Distances take three roads: twice artanh of the pseudo-distance, the cosh formula, and the ruler summed by Simpson's rule. The stretch takes two: the Schwarz-Pick weights, and a difference quotient on the moved map g. A grid of 108 points (9 radii, 12 angles) tests every pair for stretching.

### Python

```python
# Schwarz-Pick and the hyperbolic disc -- the check behind the card.  Standard library
# only.  f(z) = z^2 on the unit disc, the Mobius map m(z) = (z - 0.5)/(1 - 0.5z).
# Road one: closed forms (2 artanh, the cosh formula, Schwarz-Pick's weights).
# Road two: the ruler 2/(1 - t^2) summed by Simpson's rule, a difference quotient,
# and a search over 108 grid points for the largest stretch of distance.
import math
def mob(c, z): return (z - c) / (1 - c.conjugate() * z)   # sends c to 0, keeps the disc
def dist(z, w): return 2 * math.atanh(abs(mob(w, z)))      # hyperbolic distance
def dist_cosh(z, w):                                       # the same, by the cosh formula
    return math.acosh(1 + 2 * abs(z - w) ** 2 / ((1 - abs(z) ** 2) * (1 - abs(w) ** 2)))
def ruler(r, n=1000):                    # Simpson's rule on 2/(1 - t^2) from 0 to r
    h = r / n
    s = sum((1 if k in (0, n) else 4 if k % 2 else 2) * 2 / (1 - (k * h) ** 2) for k in range(n + 1))
    return s * h / 3
def sp(f, df, z): return abs(df(z)) * (1 - abs(z) ** 2) / (1 - abs(f(z)) ** 2)
f, df = (lambda z: z * z), (lambda z: 2 * z)
m, dm = (lambda z: mob(0.5 + 0j, z)), (lambda z: 0.75 / (1 - 0.5 * z) ** 2)
p, dp = (lambda z: mob(-0.5 + 0j, z)), (lambda z: 0.75 / (1 + 0.5 * z) ** 2)
a, h = 0.5 + 0j, 1e-5
g = lambda w: mob(f(a), f(p(w)))         # move 0 to a, apply f, move f(a) to 0
dq = abs(g(h) - g(-h)) / (2 * h)
ratio = sp(f, df, a)
grid = [r / 10 * complex(math.cos(k * math.pi / 6), math.sin(k * math.pi / 6)) for r in range(1, 10) for k in range(12)]
pairs = [(z, w) for i, z in enumerate(grid) for w in grid[i + 1:]]
fr = [dist(f(z), f(w)) / dist(z, w) for z, w in pairs]
mr = [dist(m(z), m(w)) / dist(z, w) for z, w in pairs]
z0, d1, d2 = 0j, dist(0j, a), dist(0j, f(a))
print(f"f(z) = z^2 at 0.5: f = {f(a).real:.6f}, |f'| = {abs(df(a)):.6f}, 1 - |z|^2 = {1 - abs(a) ** 2:.6f}, 1 - |f|^2 = {1 - abs(f(a)) ** 2:.6f}")
print(f"Schwarz-Pick ratio {ratio:.6f}; |g'(0)| by difference quotient {dq:.6f}")
print(f"0 to 0.5: 2 artanh 0.5 = {d1:.6f}; ln 3 = {math.log(3):.6f}; ruler summed = {ruler(0.5):.6f}")
print(f"0 to 0.25: 2 artanh 0.25 = {d2:.6f}; ln(5/3) = {math.log(5 / 3):.6f}; ruler summed = {ruler(0.25):.6f}")
print(f"0.5 to -0.5: artanh form {dist(a, -a):.6f}; cosh form {dist_cosh(a, -a):.6f}; after z^2 {dist(f(a), f(-a)):.6f}")
print(f"0.25 to 0.5i: artanh form {dist(f(a), 0.5j):.6f}; cosh form {dist_cosh(f(a), 0.5j):.6f}")
print(f"z^2 on {len(pairs)} grid pairs: largest distance ratio {max(fr):.6f}")
print(f"m(z) = (z - 0.5)/(1 - 0.5z): m(0.5) = {abs(m(a)):.6f}, m(0) = {m(z0).real:.6f}, distance after {dist(m(a), m(z0)):.6f}")
print(f"m on the grid pairs: distance ratios from {min(mr):.6f} to {max(mr):.6f}")
print(f"m at 0.5: |m'| = {abs(dm(a)):.6f}, hyperbolic stretch {sp(m, dm, a):.6f}")
print(f"mistake 1, drawn stretch of (z + 0.5)/(1 + 0.5z) at -0.5: |p'| = {abs(dp(-a)):.6f}; hyperbolic {sp(p, dp, -a):.6f}")
print(f"mistake 2, ruler 1/(1 - t^2): artanh 0.5 = {math.atanh(0.5):.6f}, not {d1:.6f}")
print(f"mistake 3, Schwarz lemma on p, which moves 0: |p(0)| = {abs(p(z0)):.6f} > |0|")
print(f"mistake 4, 2z^2 leaves the disc: ratio at 0.5 = {sp(lambda z: 2 * z * z, lambda z: 4 * z, a):.6f}; 2(0.8)^2 = {2 * 0.8 ** 2:.6f}")
assert abs(ratio - 0.8) < 1e-12 and abs(dq - ratio) < 1e-8            # weights vs difference quotient
assert abs(d1 - math.log(3)) < 1e-12 and abs(ruler(0.5) - d1) < 1e-9    # formula vs summed ruler
assert abs(d2 - ruler(0.25)) < 1e-9 and d2 < d1                         # and z^2 shrinks it
assert abs(dist(a, -a) - dist_cosh(a, -a)) < 1e-12 and abs(dist(f(a), 0.5j) - dist_cosh(f(a), 0.5j)) < 1e-12
assert max(fr) < 1 and all(abs(r - 1) < 1e-9 for r in mr)              # contraction; isometry
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
f(z) = z^2 at 0.5: f = 0.250000, |f'| = 1.000000, 1 - |z|^2 = 0.750000, 1 - |f|^2 = 0.937500
Schwarz-Pick ratio 0.800000; |g'(0)| by difference quotient 0.800000
0 to 0.5: 2 artanh 0.5 = 1.098612; ln 3 = 1.098612; ruler summed = 1.098612
0 to 0.25: 2 artanh 0.25 = 0.510826; ln(5/3) = 0.510826; ruler summed = 0.510826
0.5 to -0.5: artanh form 2.197225; cosh form 2.197225; after z^2 0.000000
0.25 to 0.5i: artanh form 1.250290; cosh form 1.250290
z^2 on 5778 grid pairs: largest distance ratio 0.987281
m(z) = (z - 0.5)/(1 - 0.5z): m(0.5) = 0.000000, m(0) = -0.500000, distance after 1.098612
m on the grid pairs: distance ratios from 1.000000 to 1.000000
m at 0.5: |m'| = 1.333333, hyperbolic stretch 1.000000
mistake 1, drawn stretch of (z + 0.5)/(1 + 0.5z) at -0.5: |p'| = 1.333333; hyperbolic 1.000000
mistake 2, ruler 1/(1 - t^2): artanh 0.5 = 0.549306, not 1.098612
mistake 3, Schwarz lemma on p, which moves 0: |p(0)| = 0.500000 > |0|
mistake 4, 2z^2 leaves the disc: ratio at 0.5 = 2.000000; 2(0.8)^2 = 1.280000
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Schwarz-Pick and the hyperbolic disc -- the same check as the Python, in Rust.  No
// crates.  f(z) = z^2 on the unit disc, the Mobius map m(z) = (z - 0.5)/(1 - 0.5z).
// Road one: closed forms (2 artanh, the cosh formula, Schwarz-Pick's weights).
// Road two: the ruler 2/(1 - t^2) summed by Simpson's rule, a difference quotient,
// and a search over 108 grid points for the largest stretch of distance.
#[derive(Clone, Copy)]
struct C(f64, f64);
impl std::ops::Add for C { type Output = C; fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) } }
impl std::ops::Sub for C { type Output = C; fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) } }
impl std::ops::Mul for C { type Output = C; fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
impl std::ops::Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.0 * o.0 + o.1 * o.1;
    C((self.0 * o.0 + self.1 * o.1) / d, (self.1 * o.0 - self.0 * o.1) / d) } }
fn r(x: f64) -> C { C(x, 0.0) }
fn ab(z: C) -> f64 { z.0.hypot(z.1) }
fn mob(c: C, z: C) -> C { (z - c) / (r(1.0) - C(c.0, -c.1) * z) }   // sends c to 0, keeps the disc
fn dist(z: C, w: C) -> f64 { 2.0 * ab(mob(w, z)).atanh() }            // hyperbolic distance
fn dist_cosh(z: C, w: C) -> f64 {                                    // the same, by the cosh formula
    (1.0 + 2.0 * ab(z - w).powi(2) / ((1.0 - ab(z).powi(2)) * (1.0 - ab(w).powi(2)))).acosh() }
fn ruler(x: f64) -> f64 {                // Simpson's rule on 2/(1 - t^2) from 0 to x
    let (n, h) = (1000, x / 1000.0);
    let s: f64 = (0..=n).map(|k| { let wt = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        let t = k as f64 * h; wt * 2.0 / (1.0 - t * t) }).sum();
    s * h / 3.0 }
fn sp(f: &dyn Fn(C) -> C, df: &dyn Fn(C) -> C, z: C) -> f64 { ab(df(z)) * (1.0 - ab(z).powi(2)) / (1.0 - ab(f(z)).powi(2)) }
fn main() {
    let f = |z: C| z * z; let df = |z: C| r(2.0) * z;
    let m = |z: C| mob(r(0.5), z); let dm = |z: C| r(0.75) / ((r(1.0) - r(0.5) * z) * (r(1.0) - r(0.5) * z));
    let p = |z: C| mob(r(-0.5), z); let dp = |z: C| r(0.75) / ((r(1.0) + r(0.5) * z) * (r(1.0) + r(0.5) * z));
    let (a, h, z0, i5) = (r(0.5), 1e-5, r(0.0), C(0.0, 0.5));
    let g = |w: C| mob(f(a), f(p(w)));   // move 0 to a, apply f, move f(a) to 0
    let dq = ab(g(r(h)) - g(r(-h))) / (2.0 * h);
    let ratio = sp(&f, &df, a);
    let mut grid = Vec::new();
    for k in 1..10 { for j in 0..12 { let t = j as f64 * std::f64::consts::PI / 6.0;
        grid.push(r(k as f64 / 10.0) * C(t.cos(), t.sin())); } }
    let (mut fr, mut mr, mut np) = (Vec::new(), Vec::new(), 0);
    for i in 0..grid.len() { for j in i + 1..grid.len() { let (z, w) = (grid[i], grid[j]); np += 1;
        fr.push(dist(f(z), f(w)) / dist(z, w)); mr.push(dist(m(z), m(w)) / dist(z, w)); } }
    let mx = |v: &Vec<f64>| v.iter().cloned().fold(f64::MIN, f64::max);
    let mn = |v: &Vec<f64>| v.iter().cloned().fold(f64::MAX, f64::min);
    let (d1, d2) = (dist(z0, a), dist(z0, f(a)));
    println!("f(z) = z^2 at 0.5: f = {:.6}, |f'| = {:.6}, 1 - |z|^2 = {:.6}, 1 - |f|^2 = {:.6}", f(a).0, ab(df(a)), 1.0 - ab(a).powi(2), 1.0 - ab(f(a)).powi(2));
    println!("Schwarz-Pick ratio {:.6}; |g'(0)| by difference quotient {:.6}", ratio, dq);
    println!("0 to 0.5: 2 artanh 0.5 = {:.6}; ln 3 = {:.6}; ruler summed = {:.6}", d1, 3f64.ln(), ruler(0.5));
    println!("0 to 0.25: 2 artanh 0.25 = {:.6}; ln(5/3) = {:.6}; ruler summed = {:.6}", d2, (5.0f64 / 3.0).ln(), ruler(0.25));
    println!("0.5 to -0.5: artanh form {:.6}; cosh form {:.6}; after z^2 {:.6}", dist(a, r(-0.5)), dist_cosh(a, r(-0.5)), dist(f(a), f(r(-0.5))));
    println!("0.25 to 0.5i: artanh form {:.6}; cosh form {:.6}", dist(f(a), i5), dist_cosh(f(a), i5));
    println!("z^2 on {} grid pairs: largest distance ratio {:.6}", np, mx(&fr));
    println!("m(z) = (z - 0.5)/(1 - 0.5z): m(0.5) = {:.6}, m(0) = {:.6}, distance after {:.6}", ab(m(a)), m(z0).0, dist(m(a), m(z0)));
    println!("m on the grid pairs: distance ratios from {:.6} to {:.6}", mn(&mr), mx(&mr));
    println!("m at 0.5: |m'| = {:.6}, hyperbolic stretch {:.6}", ab(dm(a)), sp(&m, &dm, a));
    println!("mistake 1, drawn stretch of (z + 0.5)/(1 + 0.5z) at -0.5: |p'| = {:.6}; hyperbolic {:.6}", ab(dp(r(-0.5))), sp(&p, &dp, r(-0.5)));
    println!("mistake 2, ruler 1/(1 - t^2): artanh 0.5 = {:.6}, not {:.6}", 0.5f64.atanh(), d1);
    println!("mistake 3, Schwarz lemma on p, which moves 0: |p(0)| = {:.6} > |0|", ab(p(z0)));
    println!("mistake 4, 2z^2 leaves the disc: ratio at 0.5 = {:.6}; 2(0.8)^2 = {:.6}", sp(&|z: C| r(2.0) * z * z, &|z: C| r(4.0) * z, a), 2.0 * 0.8f64.powi(2));
    assert!((ratio - 0.8).abs() < 1e-12 && (dq - ratio).abs() < 1e-8);           // weights vs difference quotient
    assert!((d1 - 3f64.ln()).abs() < 1e-12 && (ruler(0.5) - d1).abs() < 1e-9);    // formula vs summed ruler
    assert!((d2 - ruler(0.25)).abs() < 1e-9 && d2 < d1);                         // and z^2 shrinks it
    assert!((dist(a, r(-0.5)) - dist_cosh(a, r(-0.5))).abs() < 1e-12 && (dist(f(a), i5) - dist_cosh(f(a), i5)).abs() < 1e-12);
    assert!(mx(&fr) < 1.0 && mr.iter().all(|x| (x - 1.0).abs() < 1e-9));        // contraction; isometry
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
f(z) = z^2 at 0.5: f = 0.250000, |f'| = 1.000000, 1 - |z|^2 = 0.750000, 1 - |f|^2 = 0.937500
Schwarz-Pick ratio 0.800000; |g'(0)| by difference quotient 0.800000
0 to 0.5: 2 artanh 0.5 = 1.098612; ln 3 = 1.098612; ruler summed = 1.098612
0 to 0.25: 2 artanh 0.25 = 0.510826; ln(5/3) = 0.510826; ruler summed = 0.510826
0.5 to -0.5: artanh form 2.197225; cosh form 2.197225; after z^2 0.000000
0.25 to 0.5i: artanh form 1.250290; cosh form 1.250290
z^2 on 5778 grid pairs: largest distance ratio 0.987281
m(z) = (z - 0.5)/(1 - 0.5z): m(0.5) = 0.000000, m(0) = -0.500000, distance after 1.098612
m on the grid pairs: distance ratios from 1.000000 to 1.000000
m at 0.5: |m'| = 1.333333, hyperbolic stretch 1.000000
mistake 1, drawn stretch of (z + 0.5)/(1 + 0.5z) at -0.5: |p'| = 1.333333; hyperbolic 1.000000
mistake 2, ruler 1/(1 - t^2): artanh 0.5 = 0.549306, not 1.098612
mistake 3, Schwarz lemma on p, which moves 0: |p(0)| = 0.500000 > |0|
mistake 4, 2z^2 leaves the disc: ratio at 0.5 = 2.000000; 2(0.8)^2 = 1.280000
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves both forms of Schwarz-Pick and the rigid-motion fact, for every holomorphic map f of the disc into itself.

- Take two points z and w of the disc. Then the hyperbolic distance from f(z) to f(w) is at most the distance from z to w.
- Take a point z of the disc. Then f stretches the disc's ruler at z by a factor of at most 1.
- Suppose f keeps the hyperbolic distance between two different points of the disc. Then f keeps every hyperbolic distance in the disc.
- In that case f is a Blaschke factor $`\varphi_c`$, with c in the disc, followed by a turn about 0.
- The hand arithmetic holds exactly: f(0.5) = 0.25, a stretch of 0.8, and distances ln 3 and ln(5/3) from 0.
- From 0.5 to −0.5 the distance is 2 ln 3, and squaring collapses it to 0.
- The map m sends 0.5 to 0 and 0 to −0.5, and 2(0.8)^2 = 1.28 lies outside the disc.

The Simpson sums, the cosh formula, the difference quotient and the 5778 grid pairs are left to the Python and Rust checks.

```lean
-- Schwarz-Pick: a holomorphic map of the unit disc into itself never increases the disc's hyperbolic distance, never stretches its ruler at a point, and keeps one distance only when it is a Mobius map of the disc.
import Mathlib.Analysis.Complex.Schwarz
import Mathlib.Analysis.SpecialFunctions.Artanh
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum

open Complex Metric ComplexConjugate

noncomputable section

/-- The card's pseudo-distance δ(z, w) = |(z − w)/(1 − w̄ z)|: how far z lands from 0 once the
disc map φ_w(z) = (z − w)/(1 − w̄ z) has moved w to 0. -/
def pseudoDist (z w : ℂ) : ℝ := ‖(z - w) / (1 - conj w * z)‖

/-- The card's hyperbolic (Poincare) distance on the unit disc, d(z, w) = 2 artanh δ(z, w). -/
def hypDist (z w : ℂ) : ℝ := 2 * Real.artanh (pseudoDist z w)

-- Helper lemmas for the proofs below.

lemma sp_norm_identity (w z : ℂ) :
    ‖1 - conj w * z‖ ^ 2 - ‖z - w‖ ^ 2 = (1 - ‖w‖ ^ 2) * (1 - ‖z‖ ^ 2) := by
  simp only [Complex.sq_norm, normSq_apply, sub_re, sub_im, mul_re, mul_im, conj_re, conj_im,
    one_re, one_im]
  ring

lemma sp_den_ne_zero {w z : ℂ} (hw : ‖w‖ < 1) (hz : ‖z‖ < 1) : 1 - conj w * z ≠ 0 := by
  intro h
  have h1 : conj w * z = 1 := by linear_combination -h
  have h2 : ‖conj w * z‖ < 1 := by
    rw [norm_mul, Complex.norm_conj]
    nlinarith [norm_nonneg w, norm_nonneg z]
  rw [h1] at h2
  simp at h2

lemma sp_mob_norm_lt {w z : ℂ} (hw : ‖w‖ < 1) (hz : ‖z‖ < 1) :
    ‖(z - w) / (1 - conj w * z)‖ < 1 := by
  have hd := sp_den_ne_zero hw hz
  have hpos : 0 < ‖1 - conj w * z‖ := norm_pos_iff.mpr hd
  rw [norm_div, div_lt_one hpos]
  have h := sp_norm_identity w z
  have : 0 < (1 - ‖w‖ ^ 2) * (1 - ‖z‖ ^ 2) := by
    apply mul_pos <;> nlinarith [norm_nonneg w, norm_nonneg z]
  nlinarith [norm_nonneg (z - w), norm_nonneg (1 - conj w * z)]

lemma sp_mob_mapsTo {a : ℂ} (ha : ‖a‖ < 1) :
    Set.MapsTo (fun ζ : ℂ => (ζ - a) / (1 - conj a * ζ)) (ball 0 1) (ball 0 1) := by
  intro ζ hζ
  rw [mem_ball_zero_iff] at hζ ⊢
  exact sp_mob_norm_lt ha hζ

lemma sp_mob_hasDerivAt {a ζ : ℂ} (hd : 1 - conj a * ζ ≠ 0) :
    HasDerivAt (fun ζ : ℂ => (ζ - a) / (1 - conj a * ζ))
      ((1 - conj a * a) / (1 - conj a * ζ) ^ 2) ζ := by
  have h1 : HasDerivAt (fun ζ : ℂ => ζ - a) 1 ζ := (hasDerivAt_id ζ).sub_const a
  have h2 : HasDerivAt (fun ζ : ℂ => 1 - conj a * ζ) (-conj a) ζ := by
    simpa using ((hasDerivAt_id ζ).const_mul (conj a)).const_sub 1
  convert h1.div h2 hd using 1
  field_simp
  ring

lemma sp_mob_diffOn {a : ℂ} (ha : ‖a‖ < 1) :
    DifferentiableOn ℂ (fun ζ : ℂ => (ζ - a) / (1 - conj a * ζ)) (ball 0 1) := by
  intro ζ hζ
  rw [mem_ball_zero_iff] at hζ
  exact (sp_mob_hasDerivAt (sp_den_ne_zero ha hζ)).differentiableAt.differentiableWithinAt

lemma sp_mob_inv {a z : ℂ} (ha : ‖a‖ < 1) (hz : ‖z‖ < 1) :
    ((z - a) / (1 - conj a * z) - -a) / (1 - conj (-a) * ((z - a) / (1 - conj a * z))) = z := by
  have h1 := sp_den_ne_zero ha hz
  have h2 := sp_den_ne_zero ha ha
  rw [map_neg]
  have h3 : 1 - -conj a * ((z - a) / (1 - conj a * z)) = (1 - conj a * a) / (1 - conj a * z) := by
    rw [eq_div_iff h1, sub_mul, neg_mul, neg_mul, mul_assoc, div_mul_cancel₀ _ h1]
    ring
  have h4 : (z - a) / (1 - conj a * z) - -a = z * (1 - conj a * a) / (1 - conj a * z) := by
    rw [eq_div_iff h1, sub_mul, div_mul_cancel₀ _ h1]
    ring
  rw [h3, h4, div_div_div_cancel_right₀ h1]
  field_simp

lemma sp_one_sub_conj_mul_self_ne_zero {w : ℂ} (hw : ‖w‖ < 1) : 1 - conj w * w ≠ 0 :=
  sp_den_ne_zero hw hw

lemma sp_aux {f : ℂ → ℂ} (hf : DifferentiableOn ℂ f (ball 0 1))
    (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1)) {w : ℂ} (hw : w ∈ ball (0 : ℂ) 1) :
    ∃ g : ℂ → ℂ, DifferentiableOn ℂ g (ball 0 1) ∧ Set.MapsTo g (ball 0 1) (ball 0 1) ∧
      g 0 = 0 ∧
      (∀ z ∈ ball (0 : ℂ) 1,
        g ((z - w) / (1 - conj w * z)) = (f z - f w) / (1 - conj (f w) * f z)) ∧
      HasDerivAt g (deriv f w * (1 - conj w * w) / (1 - conj (f w) * f w)) 0 := by
  have hw1 : ‖w‖ < 1 := mem_ball_zero_iff.mp hw
  have hnw : ‖-w‖ < 1 := by rwa [norm_neg]
  have hbw : f w ∈ ball (0 : ℂ) 1 := hmaps hw
  have hb1 : ‖f w‖ < 1 := mem_ball_zero_iff.mp hbw
  set b := f w with hb
  refine ⟨fun ζ => (f ((ζ - -w) / (1 - conj (-w) * ζ)) - b) /
      (1 - conj b * f ((ζ - -w) / (1 - conj (-w) * ζ))), ?_, ?_, ?_, ?_, ?_⟩
  · exact (sp_mob_diffOn hb1).comp (hf.comp (sp_mob_diffOn hnw) (sp_mob_mapsTo hnw))
      (hmaps.comp (sp_mob_mapsTo hnw))
  · exact (sp_mob_mapsTo hb1).comp (hmaps.comp (sp_mob_mapsTo hnw))
  · simp [hb]
  · intro z hz
    have hz1 : ‖z‖ < 1 := mem_ball_zero_iff.mp hz
    simp only
    rw [sp_mob_inv hw1 hz1]
  · have e0 : (0 - -w) / (1 - conj (-w) * 0) = w := by simp
    have hM := sp_mob_hasDerivAt (a := -w) (ζ := 0) (by simp)
    have hF : HasDerivAt f (deriv f w) ((0 - -w) / (1 - conj (-w) * 0)) := by
      rw [e0]
      exact (hf.differentiableAt (isOpen_ball.mem_nhds hw)).hasDerivAt
    have hFM := hF.comp 0 hM
    have hB : HasDerivAt (fun ζ : ℂ => (ζ - b) / (1 - conj b * ζ))
        ((1 - conj b * b) / (1 - conj b * b) ^ 2)
        ((f ∘ fun ζ : ℂ => (ζ - -w) / (1 - conj (-w) * ζ)) 0) := by
      simp only [Function.comp_apply, e0]
      exact sp_mob_hasDerivAt (sp_den_ne_zero hb1 hb1)
    refine (hB.comp 0 hFM).congr_deriv ?_
    have h1 := sp_den_ne_zero hb1 hb1
    simp only [map_neg, mul_zero, sub_zero, one_pow, div_one, neg_mul_neg]
    field_simp

lemma sp_pd_rot {lam x y : ℂ} (hl : ‖lam‖ = 1) :
    pseudoDist (lam * x) (lam * y) = pseudoDist x y := by
  unfold pseudoDist
  have h : conj lam * lam = 1 := by rw [conj_mul', hl]; simp
  rw [show lam * x - lam * y = lam * (x - y) by ring, map_mul,
    show 1 - conj lam * conj y * (lam * x) = 1 - (conj lam * lam) * conj y * x by ring, h,
    one_mul, mul_div_assoc, norm_mul, hl, one_mul]

lemma sp_pd_mob {c u v : ℂ} (hc : ‖c‖ < 1) (hu : ‖u‖ < 1) (hv : ‖v‖ < 1) :
    pseudoDist ((u - c) / (1 - conj c * u)) ((v - c) / (1 - conj c * v)) = pseudoDist u v := by
  unfold pseudoDist
  have h1 := sp_den_ne_zero hc hu
  have h2 := sp_den_ne_zero hc hv
  have h3 : 1 - c * conj v ≠ 0 := by
    intro h
    apply h2
    have := congrArg conj h
    simpa [map_sub, map_mul, mul_comm] using this
  have h1' : 1 - u * conj c ≠ 0 := by rwa [mul_comm]
  have h2' : 1 - v * conj c ≠ 0 := by rwa [mul_comm]
  have h3' : 1 - conj v * c ≠ 0 := by rwa [mul_comm]
  have A : (u - c) / (1 - conj c * u) - (v - c) / (1 - conj c * v) =
      (1 - conj c * c) * (u - v) / ((1 - conj c * u) * (1 - conj c * v)) := by
    field_simp
    ring
  have B : 1 - conj ((v - c) / (1 - conj c * v)) * ((u - c) / (1 - conj c * u)) =
      (1 - conj c * c) * (1 - conj v * u) / ((1 - c * conj v) * (1 - conj c * u)) := by
    simp only [map_div₀, map_sub, map_mul, map_one, Complex.conj_conj]
    field_simp
    ring
  have hn : ‖1 - c * conj v‖ = ‖1 - conj c * v‖ := by
    rw [← Complex.norm_conj]
    simp [map_sub, map_mul, mul_comm]
  have hcc := sp_den_ne_zero hc hc
  rw [A, B, norm_div, norm_div, norm_div, norm_div, norm_mul, norm_mul, norm_mul, norm_mul, hn]
  have p1 : 0 < ‖1 - conj c * c‖ := norm_pos_iff.mpr hcc
  have p2 : 0 < ‖1 - conj c * u‖ := norm_pos_iff.mpr h1
  have p3 : 0 < ‖1 - conj c * v‖ := norm_pos_iff.mpr h2
  field_simp

lemma sp_alg {a a' b b' C κ c c' φ u : ℂ} (hκ : C * κ = 1) (hφ : φ * (1 - a' * u) = u - a)
    (hc : c * (C - a' * b) = a * C - b) (hc' : c' * (κ - a * b') = a' * κ - b')
    (h1 : 1 - a' * u ≠ 0) (h2 : 1 - -b' * (C * φ) ≠ 0) (h3 : C - a' * b ≠ 0)
    (h4 : 1 - b' * C * a ≠ 0) :
    (C * φ - -b) / (1 - -b' * (C * φ)) =
      (C - b * a') / (1 - b' * C * a) * ((u - c) / (1 - c' * u)) := by
  have eN : (C - b * a') * u + (b - C * a) = (C * φ - -b) * (1 - a' * u) := by
    linear_combination (-C) * hφ
  have eD : (1 - b' * C * a) + (b' * C - a') * u = (1 - -b' * (C * φ)) * (1 - a' * u) := by
    linear_combination (-b' * C) * hφ
  have hD : (1 - b' * C * a) + (b' * C - a') * u ≠ 0 := by
    rw [eD]; exact mul_ne_zero h2 h1
  have L : (C * φ - -b) / (1 - -b' * (C * φ)) =
      ((C - b * a') * u + (b - C * a)) / ((1 - b' * C * a) + (b' * C - a') * u) := by
    rw [eN, eD, mul_div_mul_right _ _ h1]
  have e1 : u - c = ((C - b * a') * u + (b - C * a)) / (C - a' * b) := by
    rw [eq_div_iff h3]; linear_combination (-1 : ℂ) * hc
  have e2 : 1 - c' * u = ((1 - b' * C * a) + (b' * C - a') * u) / (1 - b' * C * a) := by
    rw [eq_div_iff h4]; linear_combination (c' * u - u * a') * hκ - C * u * hc'
  rw [L, e1, e2, show C - b * a' = C - a' * b by ring]
  have h4' : 1 - C * a * b' ≠ 0 := by
    intro h; apply h4; linear_combination h
  field_simp

#print axioms sp_norm_identity
#print axioms sp_den_ne_zero
#print axioms sp_mob_norm_lt
#print axioms sp_mob_mapsTo
#print axioms sp_mob_hasDerivAt
#print axioms sp_mob_diffOn
#print axioms sp_mob_inv
#print axioms sp_one_sub_conj_mul_self_ne_zero
#print axioms sp_aux
#print axioms sp_pd_rot
#print axioms sp_pd_mob
#print axioms sp_alg

/-- **Schwarz-Pick, distance form.** Let f be holomorphic on the open unit disc and map the disc
into the disc. Then for any two points z and w of the disc, the hyperbolic distance between
f(z) and f(w) is at most the hyperbolic distance between z and w: f never stretches the disc's
distance. -/
theorem hypDist_map_le_of_holomorphic_self_map_of_disc {f : ℂ → ℂ}
    (hf : DifferentiableOn ℂ f (ball 0 1)) (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1))
    {z w : ℂ} (hz : z ∈ ball (0 : ℂ) 1) (hw : w ∈ ball (0 : ℂ) 1) :
    hypDist (f z) (f w) ≤ hypDist z w := by
  obtain ⟨g, hgd, hgm, hg0, hgeq, -⟩ := sp_aux hf hmaps hw
  have hz1 := mem_ball_zero_iff.mp hz
  have hw1 := mem_ball_zero_iff.mp hw
  have hle : pseudoDist (f z) (f w) ≤ pseudoDist z w := by
    unfold pseudoDist
    rw [← hgeq z hz]
    exact Complex.norm_le_norm_of_mapsTo_ball hgd (hgm.mono_right ball_subset_closedBall) hg0
      (sp_mob_norm_lt hw1 hz1)
  have := Real.artanh_le_artanh (neg_one_lt_zero.trans_le (norm_nonneg _))
    (sp_mob_norm_lt hw1 hz1) hle
  unfold hypDist pseudoDist
  linarith

/-- **Schwarz-Pick, stretch form.** With the same f, holomorphic on the open unit disc and mapping
it into itself, at every point z of the disc the stretch of the disc's ruler,
|f'(z)| (1 − |z|²)/(1 − |f(z)|²), is at most 1. -/
theorem hyperbolic_stretch_le_one_of_holomorphic_self_map_of_disc {f : ℂ → ℂ}
    (hf : DifferentiableOn ℂ f (ball 0 1)) (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1))
    {z : ℂ} (hz : z ∈ ball (0 : ℂ) 1) :
    ‖deriv f z‖ * (1 - ‖z‖ ^ 2) / (1 - ‖f z‖ ^ 2) ≤ 1 := by
  obtain ⟨g, hgd, hgm, hg0, -, hgder⟩ := sp_aux hf hmaps hz
  have h := Complex.norm_deriv_le_one_of_mapsTo_ball hgd
    (by rw [hg0]; exact hgm.mono_right ball_subset_closedBall) one_pos
  rw [hgder.deriv] at h
  have hz1 := mem_ball_zero_iff.mp hz
  have hfz1 := mem_ball_zero_iff.mp (hmaps hz)
  rw [conj_mul', conj_mul'] at h
  have e1 : (1 - (‖z‖ : ℂ) ^ 2) = ((1 - ‖z‖ ^ 2 : ℝ) : ℂ) := by push_cast; ring
  have e2 : (1 - (‖f z‖ : ℂ) ^ 2) = ((1 - ‖f z‖ ^ 2 : ℝ) : ℂ) := by push_cast; ring
  have p1 : 0 ≤ 1 - ‖z‖ ^ 2 := by nlinarith [norm_nonneg z]
  have p2 : 0 ≤ 1 - ‖f z‖ ^ 2 := by nlinarith [norm_nonneg (f z)]
  rw [e1, e2, norm_div, norm_mul, Complex.norm_real, Complex.norm_real, Real.norm_of_nonneg p1,
    Real.norm_of_nonneg p2] at h
  exact h

/-- **Keeping one distance forces a rigid motion.** With the same f, holomorphic on the open
unit disc and mapping it into itself, suppose f keeps the hyperbolic distance between one pair of
different points a and z of the disc. Then f keeps every hyperbolic distance in the disc, and f
is a Mobius map of the disc: a turn λ (|λ| = 1) after a Blaschke factor φ_c with c in the disc,
f(w) = λ (w − c)/(1 − c̄ w). -/
theorem isometry_and_mobius_of_hypDist_eq {f : ℂ → ℂ}
    (hf : DifferentiableOn ℂ f (ball 0 1)) (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1))
    {a z : ℂ} (ha : a ∈ ball (0 : ℂ) 1) (hz : z ∈ ball (0 : ℂ) 1) (hne : z ≠ a)
    (heq : hypDist (f z) (f a) = hypDist z a) :
    (∀ u ∈ ball (0 : ℂ) 1, ∀ v ∈ ball (0 : ℂ) 1, hypDist (f u) (f v) = hypDist u v) ∧
      ∃ c ∈ ball (0 : ℂ) 1, ∃ lam : ℂ, ‖lam‖ = 1 ∧
        ∀ u ∈ ball (0 : ℂ) 1, f u = lam * ((u - c) / (1 - conj c * u)) := by
  obtain ⟨g, hgd, hgm, hg0, hgeq, -⟩ := sp_aux hf hmaps ha
  have ha1 := mem_ball_zero_iff.mp ha
  have hz1 := mem_ball_zero_iff.mp hz
  have hfz1 := mem_ball_zero_iff.mp (hmaps hz)
  have hb1 := mem_ball_zero_iff.mp (hmaps ha)
  set b := f a with hb
  -- equal distance gives equal pseudo-distance
  have hpd : pseudoDist (f z) b = pseudoDist z a := by
    unfold hypDist at heq
    have h' : Real.artanh (pseudoDist (f z) b) = Real.artanh (pseudoDist z a) := by linarith
    exact Real.artanh_injOn ⟨neg_one_lt_zero.trans_le (norm_nonneg _), sp_mob_norm_lt hb1 hfz1⟩
      ⟨neg_one_lt_zero.trans_le (norm_nonneg _), sp_mob_norm_lt ha1 hz1⟩ h'
  set ζ := (z - a) / (1 - conj a * z) with hζdef
  have hζ : ζ ∈ ball (0 : ℂ) 1 := sp_mob_mapsTo ha1 hz
  have hζne : ζ ≠ 0 := div_ne_zero (sub_ne_zero.mpr hne) (sp_den_ne_zero ha1 hz1)
  have hgζ : ‖g ζ‖ = ‖ζ‖ := by
    rw [hgeq z hz]
    exact hpd
  have hds : ‖dslope g 0 ζ‖ = 1 / 1 := by
    rw [dslope_of_ne _ hζne, slope_def_module, hg0, sub_zero, sub_zero, norm_smul, norm_inv, hgζ,
      inv_mul_cancel₀ (norm_ne_zero_iff.mpr hζne)]
    norm_num
  have haff := Complex.affine_of_mapsTo_ball_of_norm_dslope_eq_div hgd
    (by rw [hg0]; exact hgm.mono_right ball_subset_closedBall) hζ hds
  set C := dslope g 0 ζ with hCdef
  have hC : ‖C‖ = 1 := by simpa using hds
  have hgform : ∀ u ∈ ball (0 : ℂ) 1, g u = C * u := fun u hu => by
    rw [haff hu]; simp [hg0, smul_eq_mul, mul_comm]
  have hfu : ∀ u ∈ ball (0 : ℂ) 1, f u = (C * ((u - a) / (1 - conj a * u)) - -b) /
      (1 - conj (-b) * (C * ((u - a) / (1 - conj a * u)))) := by
    intro u hu
    have hfu1 := mem_ball_zero_iff.mp (hmaps hu)
    have := hgeq u hu
    rw [hgform _ (sp_mob_mapsTo ha1 hu)] at this
    rw [this, sp_mob_inv hb1 hfu1]
  -- the Mobius form
  have hCC : conj C * C = 1 := by rw [conj_mul', hC]; simp
  have hκ : C * conj C = 1 := by rw [mul_comm]; exact hCC
  have hC0 : C ≠ 0 := by intro h; rw [h] at hC; simp at hC
  have hCa : ‖C * a‖ < 1 := by rw [norm_mul, hC, one_mul]; exact ha1
  have h4 : 1 - conj b * C * a ≠ 0 := by
    rw [mul_assoc]; exact sp_den_ne_zero hb1 hCa
  have hconj : conj (C - conj a * b) = conj C * (1 - conj b * C * a) := by
    simp only [map_sub, map_mul, Complex.conj_conj]
    linear_combination (a * conj b) * hCC
  have hnorm : ‖C - conj a * b‖ = ‖1 - conj b * C * a‖ := by
    rw [← Complex.norm_conj, hconj, norm_mul, Complex.norm_conj, hC, one_mul]
  have h3 : C - conj a * b ≠ 0 := by
    rw [← norm_ne_zero_iff, hnorm, norm_ne_zero_iff]; exact h4
  set c := (a * C - b) / (C - conj a * b) with hcdef
  have hc : c * (C - conj a * b) = a * C - b := div_mul_cancel₀ _ h3
  have hc3 : conj (C - conj a * b) ≠ 0 := by
    rwa [map_ne_zero]
  have hc' : conj c * (conj C - a * conj b) = conj a * conj C - conj b := by
    have := div_mul_cancel₀ (conj (a * C - b)) hc3
    simp only [map_sub, map_mul, Complex.conj_conj] at this
    rw [hcdef, map_div₀]
    simpa only [map_sub, map_mul, Complex.conj_conj] using this
  have hc1 : ‖c‖ < 1 := by
    have hid := sp_norm_identity b (a * C)
    have hpos : 0 < (1 - ‖b‖ ^ 2) * (1 - ‖a * C‖ ^ 2) := by
      rw [norm_mul, hC, mul_one]
      apply mul_pos <;> nlinarith [norm_nonneg a, norm_nonneg b]
    have hp : 0 < ‖C - conj a * b‖ := norm_pos_iff.mpr h3
    rw [hcdef, norm_div, div_lt_one hp, hnorm]
    rw [show conj b * (a * C) = conj b * C * a by ring] at hid
    nlinarith [norm_nonneg (a * C - b), norm_nonneg (1 - conj b * C * a)]
  have hcball : c ∈ ball (0 : ℂ) 1 := mem_ball_zero_iff.mpr hc1
  set lam := (C - b * conj a) / (1 - conj b * C * a) with hlamdef
  have hlam : ‖lam‖ = 1 := by
    rw [hlamdef, norm_div, ← hnorm, show C - b * conj a = C - conj a * b by ring]
    exact div_self (norm_ne_zero_iff.mpr h3)
  have hform : ∀ u ∈ ball (0 : ℂ) 1, f u = lam * ((u - c) / (1 - conj c * u)) := by
    intro u hu
    have hu1 := mem_ball_zero_iff.mp hu
    have hφ1 : ‖C * ((u - a) / (1 - conj a * u))‖ < 1 := by
      rw [norm_mul, hC, one_mul]; exact sp_mob_norm_lt ha1 hu1
    have hnb : ‖-b‖ < 1 := by rwa [norm_neg]
    have h2 := sp_den_ne_zero hnb hφ1
    rw [hfu u hu]
    rw [map_neg] at h2 ⊢
    exact sp_alg hκ (div_mul_cancel₀ _ (sp_den_ne_zero ha1 hu1)) hc hc'
      (sp_den_ne_zero ha1 hu1) h2 h3 h4
  refine ⟨fun u hu v hv => ?_, c, hcball, lam, hlam, hform⟩
  have hu1 := mem_ball_zero_iff.mp hu
  have hv1 := mem_ball_zero_iff.mp hv
  unfold hypDist
  rw [hform u hu, hform v hv, sp_pd_rot hlam, sp_pd_mob hc1 hu1 hv1]

-- The card's worked numbers for f(z) = z^2 at z = 1/2, all exact fractions.
-- f(1/2) = 1/4.
example : ((1 / 2 : ℂ)) ^ 2 = 1 / 4 := by norm_num
-- The stretch of the ruler: |f'(1/2)| (1 − 1/4)/(1 − 1/16) = 1 × (3/4)/(15/16) = 4/5, at most 1.
example : ‖deriv (fun z : ℂ => z ^ 2) (1 / 2)‖ * (1 - ‖(1 / 2 : ℂ)‖ ^ 2)
    / (1 - ‖(1 / 2 : ℂ) ^ 2‖ ^ 2) = 4 / 5 := by
  have h : deriv (fun z : ℂ => z ^ 2) (1 / 2) = 1 := by
    rw [(hasDerivAt_pow 2 (1 / 2 : ℂ)).deriv]; norm_num
  rw [h]
  simp
  norm_num
-- Hyperbolic distance from 0 to 1/2 is ln 3, and from 0 to f(1/2) = 1/4 it is ln(5/3): shrunk.
example : hypDist 0 (1 / 2) = Real.log 3 := by
  have h : pseudoDist 0 (1 / 2) = 1 / 2 := by
    unfold pseudoDist; simp
  unfold hypDist
  rw [h, Real.artanh_eq_half_log (by constructor <;> norm_num)]
  norm_num
  ring
example : hypDist 0 (1 / 4) = Real.log (5 / 3) := by
  have h : pseudoDist 0 (1 / 4) = 1 / 4 := by
    unfold pseudoDist; simp
  unfold hypDist
  rw [h, Real.artanh_eq_half_log (by constructor <;> norm_num)]
  norm_num
  ring
-- From 1/2 to −1/2 the distance is ln 3 + ln 3; squaring sends both to 1/4, distance 0.
example : hypDist (1 / 2) (-1 / 2) = 2 * Real.log 3 := by
  have h : pseudoDist (1 / 2) (-1 / 2) = 4 / 5 := by
    unfold pseudoDist
    have e : ((1 / 2 : ℂ) - -1 / 2) / (1 - conj (-1 / 2 : ℂ) * (1 / 2)) = ((4 / 5 : ℝ) : ℂ) := by
      have c2 : conj (2 : ℂ) = 2 := map_ofNat _ 2
      simp [map_div₀, c2]
      norm_num
    rw [e, Complex.norm_real, Real.norm_of_nonneg (by norm_num)]
  unfold hypDist
  rw [h, Real.artanh_eq_half_log (by constructor <;> norm_num)]
  rw [show (1 + 4 / 5 : ℝ) / (1 - 4 / 5) = 3 ^ 2 by norm_num, Real.log_pow]
  ring
example : hypDist ((1 / 2 : ℂ) ^ 2) ((-1 / 2 : ℂ) ^ 2) = 0 := by
  unfold hypDist pseudoDist
  norm_num
-- The Mobius map m = φ_{1/2} sends 1/2 to 0 and 0 to −1/2.
example : (1 / 2 - 1 / 2 : ℂ) / (1 - conj (1 / 2 : ℂ) * (1 / 2)) = 0 := by simp
example : (0 - 1 / 2 : ℂ) / (1 - conj (1 / 2 : ℂ) * 0) = -1 / 2 := by
  simp
  ring
-- The mistake 2z^2: it sends 4/5 to 32/25, outside the disc.
example : (2 : ℝ) * (4 / 5) ^ 2 = 32 / 25 ∧ (1 : ℝ) < 32 / 25 := by
  constructor <;> norm_num

#print axioms hypDist_map_le_of_holomorphic_self_map_of_disc
#print axioms hyperbolic_stretch_le_one_of_holomorphic_self_map_of_disc
#print axioms isometry_and_mobius_of_hypDist_eq
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'sp_norm_identity' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_den_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_mob_norm_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_mob_mapsTo' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_mob_hasDerivAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_mob_diffOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_mob_inv' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_one_sub_conj_mul_self_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_pd_rot' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_pd_mob' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_alg' depends on axioms: [propext, Classical.choice, Quot.sound]
'hypDist_map_le_of_holomorphic_self_map_of_disc' depends on axioms: [propext, Classical.choice, Quot.sound]
'hyperbolic_stretch_le_one_of_holomorphic_self_map_of_disc' depends on axioms: [propext, Classical.choice, Quot.sound]
'isometry_and_mobius_of_hypDist_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Cube instead of square.** Set `f, df = (lambda z: z ** 3), (lambda z: 3 * z ** 2)`. Guess: does the stretch at 0.5 rise or fall? It falls to 0.571429 on both roads; the first assert, pinned to 0.8, stops the run.
> - **Move the Möbius centre.** In `m`, replace `0.5 + 0j` by `0.9 + 0j`. Guess: do the grid ratios still read 1? They do, from 1.000000 to 1.000000: every $`\varphi_c`$ is a rigid motion. The m(z) line keeps its old label over new values; the line for m at 0.5 reads 2.122807, because `dm` still holds the old derivative.
> - **Break the ruler.** Change the 2 in `dist` to 1. Guess which assert fails: the second, against ln 3 and the summed ruler.

---

## The usual mistake

> [!warning]
> **Reading the theorem as a bound on the drawn derivative.** Schwarz-Pick does not say $`\lvert f'(z)\rvert \le 1`$. The Möbius map p = (z + 0.5)/(1 + 0.5z) maps the disc onto itself, yet its drawn stretch at −0.5 is 1.333333. The bound is on the disc's ruler: the weights 0.75 and 1 bring that factor to exactly 1.
>
> - **Dropping the factor 2.** The ruler 1/(1 − t^2) puts 0.5 at 0.549306 from 0, not 1.098612.
> - **Using the Schwarz lemma without moving 0 back.** For p, $`\lvert p(0)\rvert = 0.5`$, more than $`\lvert 0\rvert`$; move the points with $`\varphi_c`$ first.
> - **Forgetting the map must stay inside.** 2z^2 sends 0.8 to 1.28, outside the disc, and its stretch at 0.5 is 2.

---

## Where you meet it in real life

- **Repeated maps and fractals.** A self-map of the disc that fixes a point inside and is not a rigid motion pulls every point towards it: squaring sends 0.5 to 0.25 and on towards 0. Complex dynamics, the study of repeated maps such as z^2 + c, leans on this.
- **Control engineering.** Pick's 1915 question, which values a bounded holomorphic function can take at given points, became Nevanlinna-Pick interpolation: a robust-control test of whether a controller can meet given gains at given frequencies.
- **Escher's prints.** The rigid motions of Step 4 carry one fish of a Circle Limit print onto another.

> **Say it back**
> The Poincaré disc measures a short piece at drawn distance r from 0 as 2/(1 − r^2) times its drawn length. The disc's Möbius maps keep that ruler, so they can move any point to 0 without changing distances. Moving a and f(a) to 0 turns any holomorphic self-map into one that fixes 0, where the Schwarz lemma bounds it. So no such map stretches hyperbolic distance: z^2 shrinks the gap from 0 to 0.5, ln 3, to ln(5/3). Keeping one nonzero distance forces a Möbius map.

---

## What this builds on

- [The maximum modulus principle](../04-Taylor%20Series%2C%20Zeros%20and%20Rigidity/05-maximum-modulus-principle.md): the Schwarz lemma and its equality case, in a fold.
- [Mobius transformations](02-mobius-transformations-and-the-point-at-infinity.md): the maps $`\varphi_c`$, their reverses, and how they compose.
- [Conformal maps](01-conformal-maps.md): f'(z) as one turn and one stretch, which makes a single stretch factor meaningful.
- [Three geometries](../../05-Geometry%20and%20trig/06-Beyond%20Euclid/02-spherical-and-hyperbolic-geometry.md): the disc's ruler and the distance ln((1 + r)/(1 − r)) from the centre.

## Where this goes next

- [Univalent maps](10-koebe-quarter-theorem-and-boundary-behaviour.md): one-to-one maps of the disc, and how far their images must reach (the Koebe quarter theorem).

Left open: which holomorphic maps of the disc into itself pass through given values at given points, the question Pick's criterion answers; and, on the next card ([Univalent maps](10-koebe-quarter-theorem-and-boundary-behaviour.md)), how much of the plane a one-to-one map of the disc must cover.

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Stein, Elias M., and Rami Shakarchi. *Complex Analysis*. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113852/complex-analysis). Chapter 8: the Schwarz lemma and the disc's Möbius maps.
- Ahlfors, Lars V. *Conformal Invariants: Topics in Geometric Function Theory*. AMS Chelsea reprint, 2010 (first published by McGraw-Hill, 1973). [DOI](https://doi.org/10.1090/chel/371). Chapter 1: the Schwarz-Pick lemma and the hyperbolic metric.
- Pick, Georg. "Über eine Eigenschaft der konformen Abbildung kreisförmiger Bereiche." *Mathematische Annalen* 77 (1915), 1–6. [DOI](https://doi.org/10.1007/BF01456816). The invariant form of the Schwarz lemma.
- Pick, Georg. "Über die Beschränkungen analytischer Funktionen, welche durch vorgegebene Funktionswerte bewirkt werden." *Mathematische Annalen* 77 (1915), 7–23. [DOI](https://doi.org/10.1007/BF01456817). The interpolation question.
