# Normal families: bounded holomorphic functions always have a convergent subsequence, and limits keep their zero count

[Syllabus](../../../SYLLABUS.md) → [Complex analysis](../README.md) → [Taylor Series, Zeros and Rigidity](../README.md#s04) → Normal families

---

## General Overview

Take the powers z, z², z³, … on the unit disc, the points less than 1 from 0. Each stays below 1 in size there. On the closed disc of radius 0.9 their worst sizes fall fast: 0.9, then 0.590490 at the fifth power, 0.014781 at the fortieth. They settle on the zero function.

Any endless list of holomorphic functions (with a complex derivative at every point) sharing one bound has a sub-list that settles. A size bound caps every slope, and capped slopes force settling.

Each z − 1/n has one zero, at 1/n. For n ≥ 3 it lies inside the circle of radius 1/2, and so does the one zero of the limit z. Zero counts survive the limit.

Together they give the key step of the Riemann mapping theorem, met later: a map that stretches the most exists and is one-to-one.

**Holomorphic functions sharing one bound always contain a sub-list converging evenly on every closed disc inside the region (Montel), and the limit keeps the zero count inside each circle (Hurwitz), so a limit of one-to-one maps is one-to-one or constant.**

**What kind of fact this is:** two theorems, proved on this card in Why it works.

### The picture: one bound, falling worst sizes

```
worst |z^n| on |z| <= 0.9          worst |z^n| on |z| < 1
n =  1  ####################################  0.900000    1
n =  5  ########################              0.590490    1
n = 10  ##############                        0.348678    1
n = 20  #####                                 0.121577    1
n = 40  #                                     0.014781    1
```

On a closed disc inside, the bars shrink to nothing; on the open disc the worst size stays 1.

---

## The formula

Notation first. A **region** $`U`$ is an open set in one piece. A **compact** set $`K`$ is closed and bounded, such as a closed disc inside $`U`$. A list $`f_1, f_2, \ldots`$ converges **locally uniformly** when it converges uniformly (one error bound for all points at once) on every compact K in U. A family is **normal** when every list from it has a locally uniformly convergent sub-list.

**Montel's theorem.** A family of holomorphic functions on $`U`$ that all obey $`\lvert f\rvert \le M`$ is normal. The engine is a slope cap from Cauchy's estimate, at each point $`\xi`$ of a closed disc K at least $`\delta`$ inside U:

```math
\lvert f'(\xi)\rvert \le \frac{M}{\delta} \quad\Longrightarrow\quad \lvert f(z) - f(w)\rvert \le \frac{M}{\delta}\,\lvert z - w\rvert \quad \text{for } z, w \text{ in a closed disc } K
```

**Read it aloud:** every slope on K is at most M over delta, so values at two points differ by at most that cap times their distance.

**Hurwitz's theorem.** Let $`f_n \to f`$ locally uniformly on $`U`$, with $`f`$ not zero everywhere. Let $`C`$ be a circle that, with its inside, lies in $`U`$, with no zero of $`f`$ on it. Then for all large $`n`$:

```math
N(f_n, C) = \frac{1}{2\pi i}\oint_C \frac{f_n'(z)}{f_n(z)}\,dz \;=\; \frac{1}{2\pi i}\oint_C \frac{f'(z)}{f(z)}\,dz = N(f, C)
```

**Read it aloud:** the number of zeros inside C, each counted as often as its multiplicity (a double zero, like the 0 of $`z^2`$, counts twice), is the same for the late functions in the list as for the limit.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`U`$, $`K`$ | the region; a closed disc (or other compact set) inside it | the unit disc; $`\lvert z\rvert \le 0.9`$ | a bigger K needs a smaller δ |
| $`f_n`$, $`f`$, $`n`$, $`j`$ | the n-th function; its limit; list positions | $`z^n`$, limit 0 | — |
| $`M`$ | one bound on the size of every function | 1 | the slope cap grows with it |
| $`\delta`$, $`\rho`$ | how far K sits inside U; a circle's radius in Cauchy's estimate | 0.1; just under 0.1 | a smaller slope cap |
| $`z`$, $`w`$, $`\xi`$, $`a`$, $`b`$, $`q`$ | points of K; ξ where a slope is read; a, b tested for equal values; q a checkpoint | $`\lvert \xi\rvert \le 0.9`$; a = −0.3, b = −0.7 | — |
| $`C`$, $`N(f, C)`$, $`m`$, $`k`$, $`h`$ | a circle; zeros of f inside it, with multiplicity; a floor under $`\lvert f\rvert`$ on C; a zero's order; the zero-free leftover | $`\lvert z\rvert = 1/2`$; 1 for $`z - 1/n`$ | — |
| $`g_n`$, $`z_0`$, $`D`$, $`F`$, $`s`$ | a one-to-one map of a region D into the unit disc; the point sent to 0; the limit; the largest stretch $`\lvert g'(z_0)\rvert`$ | $`(z + z^2/n)/(1 + 1/n)`$; 0; z; 1 | — |
| $`\varepsilon`$, $`\eta`$ | an allowed error; a distance keeping every function within ε/3 | η = ε/30 here | a smaller ε needs a smaller η |

### When it holds

- **Holomorphic, not just smooth.** Real $`\sin(nx)`$ is bounded with no settling sub-list.
- **One bound for the whole family on each compact set.** Without it, $`nz`$ runs off: at z = 1/2 its values are n/2.
- **No zero of the limit on C.** For n ≥ 2, each $`z - 1/2 + 1/n`$ has one zero inside $`\lvert z\rvert = 1/2`$; the limit's zero 0.5 sits on the circle.
- **A limit that is not zero everywhere.** Each $`e^z/n`$ has no zeros; their limit is zero at every point.

---

## Why it works

### Step 0: in the plane, a size bound is a slope bound

Cauchy's estimate ([Derivatives from the boundary](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/06-derivatives-from-the-boundary.md)): if $`\lvert f\rvert \le M`$ on a circle of radius ρ, the slope at its centre is at most M/ρ. So one bound caps every slope in the family.

### Step 1: the shared slope cap

Each ξ with $`\lvert \xi\rvert \le 0.9`$ has a circle of radius just under 0.1 inside the unit disc, so every f bounded by 1 has $`\lvert f'(\xi)\rvert \le 10`$ there. For $`z^n`$ the largest slope is 3.874205. Integrating $`f'`$ along a segment gives the formula's bound.

### Step 2: equicontinuity, then Arzela-Ascoli

The cap makes the family **equicontinuous** (one closeness rule serves every function): points closer than ε/10 have values closer than ε. Bounded plus equicontinuous gives a sub-list converging uniformly on the closed disc: the Arzela-Ascoli theorem, proved for this case in the fold.

<details>
<summary>Detailed proof: bounded and equicontinuous gives a uniformly convergent sub-list</summary>

Take points $`q_1, q_2, \ldots`$ coming arbitrarily close to every point of K, such as those with rational coordinates. The values at $`q_1`$ are bounded, so a sub-list converges there; from it take one converging at $`q_2`$, and so on. The j-th function of the j-th sub-list converges at every $`q_i`$.

Fix ε, and pick η so that points closer than η have values closer than ε/3, for every function. K is compact, so finitely many $`q_i`$ lie within η of every point of K. Late in the diagonal list, any two functions $`f_j, f_k`$ differ by less than ε/3 at those points. For z in K, take such a q within η:

$`\displaystyle \lvert f_j(z) - f_k(z)\rvert \le \lvert f_j(z) - f_j(q)\rvert + \lvert f_j(q) - f_k(q)\rvert + \lvert f_k(q) - f_k(z)\rvert < \varepsilon.`$

This holds for every z at once, so the list converges uniformly on K.

</details>

### Step 3: one sub-list for every compact set

Take closed discs of radius 1 − 1/(j + 1), j = 1, 2, …, which fill the unit disc. Pick a sub-list converging on the first, a sub-list of that converging on the second, and so on. The j-th function of the j-th sub-list converges on all of them. The limit is holomorphic by [Limits of holomorphic functions](02-uniform-limits-of-holomorphic-functions.md). Any region U works the same way, with compact sets filling U.

### Step 4: Hurwitz, by counting zeros with an integral

Each zero a of f inside C factors out as $`(z - a)^k`$, k its order ([Zeros and the identity theorem](03-zeros-and-the-identity-theorem.md)); the leftover h has no zeros inside C. So $`f'/f`$ is a sum of terms $`k/(z - a)`$ plus $`h'/h`$. Round C each $`1/(z - a)`$ integrates to $`2\pi i`$ ([Cauchy's integral formula](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/05-cauchys-integral-formula.md)) and $`h'/h`$ to 0 (Cauchy's theorem), so the formula's integral is the zero count: the argument principle, met in full later.

On C, $`\lvert f\rvert`$ stays above some m > 0, so $`\lvert f_n\rvert > m/2`$ there for large n. Derivatives converge too (the limits card), so $`f_n'/f_n \to f'/f`$ uniformly on C. The integrals converge, and converging whole numbers are eventually equal.

### Step 5: limits of one-to-one maps

Let each $`f_n`$ be one-to-one, with a non-constant limit f. If $`f(a) = f(b)`$ with a ≠ b, a small circle round b, avoiding a, holds a zero of $`f - f(a)`$ and none on it (zeros are isolated). Hurwitz, applied to $`f_n - f_n(a) \to f - f(a)`$, gives a zero there too for large n: a second point with value $`f_n(a)`$, impossible. So **the limit of one-to-one maps is one-to-one or constant**.

The example: the gap of $`f_n(z) = z + z^2/n`$ factors as $`f_n(a) - f_n(b) = (a - b)(1 + (a + b)/n)`$. Inside the disc $`\lvert a + b\rvert < 2`$, so for n ≥ 2 the second factor is never 0, and the limit z is one-to-one too. For n = 1 it fails: $`f_1(-0.3) = f_1(-0.7) = -0.21`$. The constant case is real: z/n tends to 0.

### Step 6: the existence step of the Riemann mapping theorem

```mermaid
flowchart LR
    A["Family: one-to-one maps<br/>of D into the disc, z0 to 0"] -->|"Cauchy: stretch at z0 is capped"| B["s = largest stretch, finite"]
    B -->|"Montel: bounded by 1"| C["sub-list converges to F<br/>with stretch s > 0"]
    C -->|"not constant (s > 0), so Hurwitz: one-to-one"| D["F one-to-one, in the family"]
    D -->|"later card"| E["F fills the disc"]
```

The family: one-to-one holomorphic maps g of the region D into the unit disc with $`g(z_0) = 0`$, assumed not empty (the later card shows it). All are bounded by 1, so Cauchy's estimate caps the stretch $`\lvert g'(z_0)\rvert`$; let s be the least upper bound.

Take maps with stretches climbing to s. Montel gives a sub-list converging to some F with $`\lvert F'(z_0)\rvert = s > 0`$ (a one-to-one map has $`g'(z_0) \ne 0`$: [Local normal form](06-open-mapping-theorem-and-local-normal-form.md)), so F is not constant and, by Step 5, one-to-one. By [The maximum modulus principle](05-maximum-modulus-principle.md), F stays below size 1 inside D. So F is in the family, with the largest stretch.

On the unit disc with $`z_0 = 0`$, the maps $`g_n = (z + z^2/n)/(1 + 1/n)`$ have stretches 0.666667, 0.75, 0.909091, 0.990099 for n = 2, 3, 10, 100, and converge to z, of stretch 1.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Worst size of $`z^{40}`$ on $`\lvert z\rvert \le 0.9`$ | 0.9 to the 40th | 0.014781 |
| Slope cap there | M/δ = 1/0.1 | 10 |
| Largest real slope of any $`z^n`$ there | $`9 \times 0.9^8`$ | 3.874205 |
| Zeros of $`z^2 + 1/5`$ inside $`\lvert z\rvert = 1/2`$ | roots $`\pm i/\sqrt 5`$, size 0.447214 | 2 |
| Zeros of the limit $`z^2`$ there | one zero, multiplicity 2 | 2 |
| Stretch of $`g_{10}`$ at 0 | 10/11 | 0.909091 |
| Worst gap $`\lvert g_{10} - z\rvert`$ on the rim | 2/11, at z = −1 | **0.181818** |

The zero count 2 carries over although the two zeros merge.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Counting the limit's distinct zeros | 1 for $`z^2`$, against 2 for each $`z^2 + 1/n`$, n ≥ 5 | Hurwitz counts with multiplicity |
| Circle through the limit's zero | $`z - 1/2 + 1/n`$: 1 zero inside; the limit: 0 | the limit's zero sits on C |
| Dropping "or constant" | z/n is one-to-one, worst size 0.01 at n = 100, limit 0 | a constant limit is allowed |
| Expecting uniform convergence on the open disc | $`z^{40}`$ at 0.9999 is 0.996008 | Montel promises closed discs inside |

The code prints all four.

---

## Code, from first principles, and it actually runs

Every claim takes two roads. Worst sizes: a polar grid against $`0.9^n`$. Zero counts: the turns of f round a circle against roots found by algebra. One-to-one: counts of solutions of $`f(z) = f(a)`$ against the factor $`1 + (a + b)/n`$. Stretches $`g_n'(0)`$: Cauchy's formula on a circle against n/(n + 1).

### Python

```python
# Normal families: Montel and Hurwitz -- the check behind the card.  Standard library only.
# Montel: z^n stays below 1 on the unit disc; on |z| <= 0.9 its worst size falls and its slopes obey
# one Cauchy bound.  Hurwitz: zeros counted by the argument principle (the turns of f round a circle)
# against roots found by algebra.  Riemann mapping: g_n = (z + z^2/n)/(1 + 1/n) climbs to z.
import cmath, math

def ring(r, m=2000):                           # m even steps round the circle |z| = r
    return [r * cmath.exp(2j * math.pi * k / m) for k in range(m)]
def turns(f, r, m=2000):                       # argument principle: angle steps of f summed, over 2 pi
    v = [f(z) for z in ring(r, m)]
    return round(sum(cmath.phase(v[k] / v[k - 1]) for k in range(m)) / (2 * math.pi))
def yn(claim):
    return "yes" if claim else "no"
disc = [k / 50 * cmath.exp(1j * t / 10) for k in range(46) for t in range(63)]   # grid on |z| <= 0.9
ns = (1, 5, 10, 20, 40)
grid = [max(abs(z ** n) for z in disc) for n in ns]
print("Montel: worst |z^n| on |z| <= 0.9 by grid, n = 1, 5, 10, 20, 40: " + ", ".join(f"{w:.6f}" for w in grid))
print("the same by 0.9^n: " + ", ".join(f"{0.9 ** n:.6f}" for n in ns))
print(f"on the open disc |z| < 1: z^40 at z = 0.9999 is {0.9999 ** 40:.6f}, so the worst size stays 1")
slope = max(abs(n * z ** (n - 1)) for z in disc for n in range(1, 120))
print(f"largest slope |n z^(n-1)| on |z| <= 0.9, any n: {slope:.6f}; Cauchy bound 1/(1 - 0.9) = {1 / (1 - 0.9):.6f}")
lin = [turns(lambda z, n=n: z - 1 / n, 0.5) for n in (3, 10, 100)]
print(f"Hurwitz: z - 1/n, turns on |z| = 1/2 for n = 3, 10, 100: {lin}; limit z: {turns(lambda z: z, 0.5)}")
sq = [turns(lambda z, n=n: z * z + 1 / n, 0.5) for n in (5, 100)]
print(f"z^2 + 1/n, n = 5, 100: turns {sq}, roots of size {1 / math.sqrt(5):.6f}, {1 / math.sqrt(100):.6f}; "
      f"limit z^2: turns {turns(lambda z: z * z, 0.5)}, distinct zeros 1")
edge = [turns(lambda z, n=n: z - 0.5 + 1 / n, 0.5) for n in (10, 100)]
print(f"z - 1/2 + 1/n, n = 10, 100: turns on |z| = 1/2 {edge}; the limit's zero 0.5 sits on the circle: 0 inside")
f = lambda z, n: z + z * z / n
print(f"one-to-one test, n = 1: f(-0.3) = {f(-0.3, 1):.6f}, f(-0.7) = {f(-0.7, 1):.6f}")
pre = [turns(lambda z, n=n: f(z, n) - f(-0.3, n), 0.999) for n in (1, 2, 10)]
print(f"solutions of f(z) = f(-0.3) in |z| < 0.999, n = 1, 2, 10: {pre}")
every = all(turns(lambda z, n=n, a=a: f(z, n) - f(a, n), 0.95, 400) == 1 for n in (2, 10) for a in disc[::7])
print(f"every grid point a hit once, n = 2 and 10: {yn(every)}; factor |1 + (a + b)/n| above 1 - 2/n: "
      + ", ".join(f"{1 - 2 / n:.6f}" for n in (2, 3, 10)))
print(f"z/n: one-to-one, worst size on the disc 1/n = {1 / 100:.6f} at n = 100; the limit 0 is constant")
g = lambda z, n: (z + z * z / n) / (1 + 1 / n)
cau = [sum(g(z, n) / z for z in ring(0.5)).real / 2000 for n in (2, 3, 10, 100)]
print("Riemann mapping: g_n'(0) by Cauchy's formula, n = 2, 3, 10, 100: " + ", ".join(f"{c:.6f}" for c in cau))
print("the same by n/(n + 1): " + ", ".join(f"{n / (n + 1):.6f}" for n in (2, 3, 10, 100)))
rim = ring(1.0, 720)
gap = [max(abs(g(z, n) - z) for z in rim) for n in (2, 10, 100)]
big = max(abs(g(z, n)) for z in rim for n in (2, 10, 100))
print(f"worst gap |g_n - z| on the rim, n = 2, 10, 100: {', '.join(f'{x:.6f}' for x in gap)}; largest |g_n| {big:.6f}")
assert all(abs(w - 0.9 ** n) < 1e-12 for w, n in zip(grid, ns))          # grid against formula
assert slope <= 1 / (1 - 0.9) and abs(slope - 9 * 0.9 ** 8) < 1e-9          # Cauchy bound holds
assert lin == [1, 1, 1] and sq == [2, 2] and edge == [1, 1] and pre == [2, 1, 1] and every
assert abs(f(-0.3, 1) - f(-0.7, 1)) < 1e-12                                 # n = 1 is two-to-one
assert all(abs(c - n / (n + 1)) < 1e-12 for c, n in zip(cau, (2, 3, 10, 100)))
assert all(abs(x - 2 / (n + 1)) < 1e-9 for x, n in zip(gap, (2, 10, 100))) and abs(big - 1) < 1e-12
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
Montel: worst |z^n| on |z| <= 0.9 by grid, n = 1, 5, 10, 20, 40: 0.900000, 0.590490, 0.348678, 0.121577, 0.014781
the same by 0.9^n: 0.900000, 0.590490, 0.348678, 0.121577, 0.014781
on the open disc |z| < 1: z^40 at z = 0.9999 is 0.996008, so the worst size stays 1
largest slope |n z^(n-1)| on |z| <= 0.9, any n: 3.874205; Cauchy bound 1/(1 - 0.9) = 10.000000
Hurwitz: z - 1/n, turns on |z| = 1/2 for n = 3, 10, 100: [1, 1, 1]; limit z: 1
z^2 + 1/n, n = 5, 100: turns [2, 2], roots of size 0.447214, 0.100000; limit z^2: turns 2, distinct zeros 1
z - 1/2 + 1/n, n = 10, 100: turns on |z| = 1/2 [1, 1]; the limit's zero 0.5 sits on the circle: 0 inside
one-to-one test, n = 1: f(-0.3) = -0.210000, f(-0.7) = -0.210000
solutions of f(z) = f(-0.3) in |z| < 0.999, n = 1, 2, 10: [2, 1, 1]
every grid point a hit once, n = 2 and 10: yes; factor |1 + (a + b)/n| above 1 - 2/n: 0.000000, 0.333333, 0.800000
z/n: one-to-one, worst size on the disc 1/n = 0.010000 at n = 100; the limit 0 is constant
Riemann mapping: g_n'(0) by Cauchy's formula, n = 2, 3, 10, 100: 0.666667, 0.750000, 0.909091, 0.990099
the same by n/(n + 1): 0.666667, 0.750000, 0.909091, 0.990099
worst gap |g_n - z| on the rim, n = 2, 10, 100: 0.666667, 0.181818, 0.019802; largest |g_n| 1.000000
ALL CHECKS PASS
```

### Rust

Same numbers, same labels.

```rust
// Normal families: Montel and Hurwitz -- the same check as the Python, in Rust.  No crates.
// Montel: z^n stays below 1 on the unit disc; on |z| <= 0.9 its worst size falls and its slopes obey
// one Cauchy bound.  Hurwitz: zeros counted by the argument principle (the turns of f round a circle)
// against roots found by algebra.  Riemann mapping: g_n = (z + z^2/n)/(1 + 1/n) climbs to z.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let m = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / m, (a.im * b.re - a.re * b.im) / m) }
fn sc(a: C, s: f64) -> C { c(a.re * s, a.im * s) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn cis(t: f64) -> C { c(t.cos(), t.sin()) }
fn pw(z: C, n: i32) -> C { (0..n).fold(c(1.0, 0.0), |p, _| mul(p, z)) }
fn ring(r: f64, m: usize) -> Vec<C> { (0..m).map(|k| sc(cis(2.0 * PI * k as f64 / m as f64), r)).collect() }
fn turns(f: &dyn Fn(C) -> C, r: f64, m: usize) -> i64 { // argument principle: angle steps of f summed, over 2 pi
    let v: Vec<C> = ring(r, m).into_iter().map(|z| f(z)).collect();
    let s: f64 = (0..m).map(|k| { let q = div(v[k], v[(k + m - 1) % m]); q.im.atan2(q.re) }).sum();
    (s / (2.0 * PI)).round() as i64
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn f(z: C, n: f64) -> C { add(z, sc(mul(z, z), 1.0 / n)) }
fn g(z: C, n: f64) -> C { sc(f(z, n), 1.0 / (1.0 + 1.0 / n)) }
fn j(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let disc: Vec<C> = (0..46).flat_map(|k| (0..63).map(move |t| sc(cis(t as f64 / 10.0), k as f64 / 50.0))).collect();
    let ns = [1, 5, 10, 20, 40];
    let grid: Vec<f64> = ns.iter().map(|&n| disc.iter().map(|&z| md(pw(z, n))).fold(0.0, f64::max)).collect();
    println!("Montel: worst |z^n| on |z| <= 0.9 by grid, n = 1, 5, 10, 20, 40: {}", j(&grid));
    println!("the same by 0.9^n: {}", j(&ns.iter().map(|&n| 0.9f64.powi(n)).collect::<Vec<_>>()));
    println!("on the open disc |z| < 1: z^40 at z = 0.9999 is {:.6}, so the worst size stays 1", 0.9999f64.powi(40));
    let mut slope = 0.0f64;
    for &z in &disc { for n in 1..120 { slope = slope.max(n as f64 * md(pw(z, n - 1))) } }
    println!("largest slope |n z^(n-1)| on |z| <= 0.9, any n: {:.6}; Cauchy bound 1/(1 - 0.9) = {:.6}", slope, 1.0 / (1.0 - 0.9));
    let lin: Vec<i64> = [3.0, 10.0, 100.0].iter().map(|&n| turns(&|z| sub(z, c(1.0 / n, 0.0)), 0.5, 2000)).collect();
    println!("Hurwitz: z - 1/n, turns on |z| = 1/2 for n = 3, 10, 100: {:?}; limit z: {}", lin, turns(&|z| z, 0.5, 2000));
    let sq: Vec<i64> = [5.0, 100.0].iter().map(|&n| turns(&|z| add(mul(z, z), c(1.0 / n, 0.0)), 0.5, 2000)).collect();
    println!("z^2 + 1/n, n = 5, 100: turns {:?}, roots of size {:.6}, {:.6}; limit z^2: turns {}, distinct zeros 1",
        sq, 1.0 / 5f64.sqrt(), 1.0 / 100f64.sqrt(), turns(&|z| mul(z, z), 0.5, 2000));
    let edge: Vec<i64> = [10.0, 100.0].iter().map(|&n| turns(&|z| sub(z, c(0.5 - 1.0 / n, 0.0)), 0.5, 2000)).collect();
    println!("z - 1/2 + 1/n, n = 10, 100: turns on |z| = 1/2 {:?}; the limit's zero 0.5 sits on the circle: 0 inside", edge);
    let (p3, p7) = (f(c(-0.3, 0.0), 1.0), f(c(-0.7, 0.0), 1.0));
    println!("one-to-one test, n = 1: f(-0.3) = {:.6}, f(-0.7) = {:.6}", p3.re, p7.re);
    let pre: Vec<i64> = [1.0, 2.0, 10.0].iter().map(|&n| turns(&|z| sub(f(z, n), f(c(-0.3, 0.0), n)), 0.999, 2000)).collect();
    println!("solutions of f(z) = f(-0.3) in |z| < 0.999, n = 1, 2, 10: {:?}", pre);
    let every = [2.0, 10.0].iter().all(|&n| disc.iter().step_by(7).all(|&a| turns(&|z| sub(f(z, n), f(a, n)), 0.95, 400) == 1));
    println!("every grid point a hit once, n = 2 and 10: {}; factor |1 + (a + b)/n| above 1 - 2/n: {}",
        yn(every), j(&[2.0, 3.0, 10.0].map(|n: f64| 1.0 - 2.0 / n)));
    println!("z/n: one-to-one, worst size on the disc 1/n = {:.6} at n = 100; the limit 0 is constant", 1.0 / 100.0);
    let nn = [2.0, 3.0, 10.0, 100.0];
    let cau: Vec<f64> = nn.iter().map(|&n| ring(0.5, 2000).iter().map(|&z| div(g(z, n), z).re).sum::<f64>() / 2000.0).collect();
    println!("Riemann mapping: g_n'(0) by Cauchy's formula, n = 2, 3, 10, 100: {}", j(&cau));
    println!("the same by n/(n + 1): {}", j(&nn.map(|n| n / (n + 1.0))));
    let rim = ring(1.0, 720);
    let gap: Vec<f64> = [2.0, 10.0, 100.0].iter().map(|&n| rim.iter().map(|&z| md(sub(g(z, n), z))).fold(0.0, f64::max)).collect();
    let big = [2.0, 10.0, 100.0].iter().flat_map(|&n| rim.iter().map(move |&z| md(g(z, n)))).fold(0.0, f64::max);
    println!("worst gap |g_n - z| on the rim, n = 2, 10, 100: {}; largest |g_n| {:.6}", j(&gap), big);
    assert!(grid.iter().zip(ns).all(|(w, n)| (w - 0.9f64.powi(n)).abs() < 1e-12)); // grid against formula
    assert!(slope <= 1.0 / (1.0 - 0.9) && (slope - 9.0 * 0.9f64.powi(8)).abs() < 1e-9); // Cauchy bound holds
    assert!(lin == vec![1, 1, 1] && sq == vec![2, 2] && edge == vec![1, 1] && pre == vec![2, 1, 1] && every);
    assert!(md(sub(p3, p7)) < 1e-12); // n = 1 is two-to-one
    assert!(cau.iter().zip(nn).all(|(c, n)| (c - n / (n + 1.0)).abs() < 1e-12));
    assert!(gap.iter().zip([2.0, 10.0, 100.0]).all(|(x, n)| (x - 2.0 / (n + 1.0)).abs() < 1e-9) && (big - 1.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
Montel: worst |z^n| on |z| <= 0.9 by grid, n = 1, 5, 10, 20, 40: 0.900000, 0.590490, 0.348678, 0.121577, 0.014781
the same by 0.9^n: 0.900000, 0.590490, 0.348678, 0.121577, 0.014781
on the open disc |z| < 1: z^40 at z = 0.9999 is 0.996008, so the worst size stays 1
largest slope |n z^(n-1)| on |z| <= 0.9, any n: 3.874205; Cauchy bound 1/(1 - 0.9) = 10.000000
Hurwitz: z - 1/n, turns on |z| = 1/2 for n = 3, 10, 100: [1, 1, 1]; limit z: 1
z^2 + 1/n, n = 5, 100: turns [2, 2], roots of size 0.447214, 0.100000; limit z^2: turns 2, distinct zeros 1
z - 1/2 + 1/n, n = 10, 100: turns on |z| = 1/2 [1, 1]; the limit's zero 0.5 sits on the circle: 0 inside
one-to-one test, n = 1: f(-0.3) = -0.210000, f(-0.7) = -0.210000
solutions of f(z) = f(-0.3) in |z| < 0.999, n = 1, 2, 10: [2, 1, 1]
every grid point a hit once, n = 2 and 10: yes; factor |1 + (a + b)/n| above 1 - 2/n: 0.000000, 0.333333, 0.800000
z/n: one-to-one, worst size on the disc 1/n = 0.010000 at n = 100; the limit 0 is constant
Riemann mapping: g_n'(0) by Cauchy's formula, n = 2, 3, 10, 100: 0.666667, 0.750000, 0.909091, 0.990099
the same by n/(n + 1): 0.666667, 0.750000, 0.909091, 0.990099
worst gap |g_n - z| on the rim, n = 2, 10, 100: 0.666667, 0.181818, 0.019802; largest |g_n| 1.000000
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Montel, Hurwitz and the limit of one-to-one maps for every list of functions, and checks the worked numbers exactly.

- Take holomorphic functions on an open set, sharing one bound on each compact set inside it. Then some sub-list converges locally uniformly to a holomorphic limit.
- Suppose holomorphic functions converge locally uniformly to a limit with no zero on a circle C. Suppose C and its inside lie in the open set. Then late functions have as many zeros inside C as the limit, counted with multiplicity.
- On a region, a locally uniform limit of one-to-one holomorphic functions is one-to-one or constant.
- Take $`f_n(z) = z + z^2/n`$ with $`n \ne 0`$. Then $`f_n(a) - f_n(b) = (a - b)(1 + (a + b)/n)`$.
- For n = 1 it fails: $`f_1(-0.3)`$ and $`f_1(-0.7)`$ both equal −0.21.
- The slope cap is 1/0.1 = 10, and the zero 1/3 of z − 1/3 lies inside the circle of radius 1/2.
- The roots $`\pm i/\sqrt 5`$ lie inside $`\lvert z\rvert = 1/2`$, since 1/5 is below $`(1/2)^2`$.
- The stretch of $`g_{10}`$ at 0 is 10/11, and its gap from z at z = −1 is 2/11.

The worst sizes on the grid, the turn counts round circles and the stretches by Cauchy's formula are left to the Python and Rust checks.

```lean
-- Normal families: a locally bounded list of holomorphic functions has a locally uniformly convergent sub-list (Montel), late functions keep the limit's zero count inside a circle (Hurwitz), and a limit of one-to-one maps is one-to-one or constant.
import Mathlib.Analysis.Complex.LocallyUniformLimit
import Mathlib.Analysis.Analytic.Order
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Analysis.Complex.Liouville
import Mathlib.Analysis.Complex.RemovableSingularity
import Mathlib.Analysis.Calculus.LogDeriv
import Mathlib.Analysis.Meromorphic.Divisor
import Mathlib.Analysis.Normed.Module.Ball.Pointwise
import Mathlib.Topology.UniformSpace.Ascoli

open Filter Metric Set

lemma nf_finsum_ne_zero {φ : ℂ → ℕ} {s : Set ℂ} (hfin : (s ∩ Function.support φ).Finite)
    {a : ℂ} (ha : a ∈ s) (hφ : φ a ≠ 0) : ∑ᶠ z ∈ s, φ z ≠ 0 := by
  rw [← finsum_mem_inter_support, finsum_mem_eq_finite_toFinset_sum _ hfin]
  intro h0
  rw [Finset.sum_eq_zero_iff] at h0
  exact hφ (h0 a (by simp [ha, hφ]))

#print axioms nf_finsum_ne_zero

lemma nf_eq_zero_of_order_ne_zero {h : ℂ → ℂ} {z : ℂ} (hz : analyticOrderNatAt h z ≠ 0) :
    h z = 0 := by
  by_contra hne
  by_cases ha : AnalyticAt ℂ h z
  · apply hz; simp [analyticOrderNatAt, (ha.analyticOrderAt_eq_zero).2 hne]
  · apply hz; simp [analyticOrderNatAt, analyticOrderAt_of_not_analyticAt ha]

#print axioms nf_eq_zero_of_order_ne_zero

lemma nf_zeros_finite {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V) (hh : DifferentiableOn ℂ h V)
    {c : ℂ} {r : ℝ} (hC : closedBall c r ⊆ V) :
    (ball c r ∩ Function.support (analyticOrderNatAt h)).Finite := by
  have hm : MeromorphicOn h (closedBall c r) := fun z hz =>
    (hh.analyticAt (hV.mem_nhds (hC hz))).meromorphicAt
  refine ((MeromorphicOn.divisor h (closedBall c r)).finiteSupport
    (isCompact_closedBall c r)).subset ?_
  rintro z ⟨hz, hne⟩
  have hzC : z ∈ closedBall c r := ball_subset_closedBall hz
  have ha := hh.analyticAt (hV.mem_nhds (hC hzC))
  rw [Function.mem_support] at hne
  rw [Function.mem_support, hm.divisor_apply hzC, ha.meromorphicOrderAt_eq]
  unfold analyticOrderNatAt at hne
  cases hk : analyticOrderAt h z with
  | top => simp [hk] at hne
  | coe n => simp_all

#print axioms nf_zeros_finite

lemma nf_logDeriv_differentiableAt {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V)
    (hh : DifferentiableOn ℂ h V) {z : ℂ} (hz : z ∈ V) (hne : h z ≠ 0) :
    DifferentiableAt ℂ (logDeriv h) z := by
  have ha := hh.analyticAt (hV.mem_nhds hz)
  exact ha.deriv.differentiableAt.div ha.differentiableAt hne

#print axioms nf_logDeriv_differentiableAt

lemma nf_circle_logDeriv_zero {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V)
    (hh : DifferentiableOn ℂ h V) {c : ℂ} {r : ℝ} (hr : 0 ≤ r) (hC : closedBall c r ⊆ V)
    (hne : ∀ z ∈ closedBall c r, h z ≠ 0) : (∮ z in C(c, r), logDeriv h z) = 0 := by
  have hd : ∀ z ∈ closedBall c r, DifferentiableAt ℂ (logDeriv h) z := fun z hz =>
    nf_logDeriv_differentiableAt hV hh (hC hz) (hne z hz)
  exact Complex.circleIntegral_eq_zero_of_differentiable_on_off_countable hr countable_empty
    (fun z hz => (hd z hz).continuousAt.continuousWithinAt)
    (fun z hz => hd z (ball_subset_closedBall hz.1))

#print axioms nf_circle_logDeriv_zero

lemma nf_logDeriv_continuousOn {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V)
    (hh : DifferentiableOn ℂ h V) {S : Set ℂ} (hS : S ⊆ V) (hne : ∀ z ∈ S, h z ≠ 0) :
    ContinuousOn (logDeriv h) S := fun z hz =>
  (nf_logDeriv_differentiableAt hV hh (hS hz) (hne z hz)).continuousAt.continuousWithinAt

#print axioms nf_logDeriv_continuousOn

lemma nf_order_sub (a z : ℂ) :
    analyticOrderAt (fun w : ℂ => w - a) z = if z = a then 1 else 0 := by
  have han : AnalyticAt ℂ (fun w : ℂ => w - a) z := analyticAt_id.sub analyticAt_const
  split_ifs with hza
  · subst hza
    simp
  · exact han.analyticOrderAt_eq_zero.2 (sub_ne_zero.2 hza)

#print axioms nf_order_sub

lemma nf_arg_principle_aux {c : ℂ} {r : ℝ} (hr : 0 < r) {V : Set ℂ} (hV : IsOpen V)
    (hC : closedBall c r ⊆ V) (n : ℕ) : ∀ h : ℂ → ℂ, DifferentiableOn ℂ h V →
    (∀ z ∈ sphere c r, h z ≠ 0) → (∀ z ∈ closedBall c r, analyticOrderAt h z ≠ ⊤) →
    ∑ᶠ z ∈ ball c r, analyticOrderNatAt h z = n →
    (∮ z in C(c, r), logDeriv h z) = 2 * Real.pi * Complex.I * n := by
  induction n with
  | zero =>
    intro h hh hs htop hsum
    have hfin := nf_zeros_finite hV hh hC
    have hne : ∀ z ∈ closedBall c r, h z ≠ 0 := by
      intro z hz
      rcases (mem_closedBall.1 hz).lt_or_eq with hlt | heq
      · have hzb : z ∈ ball c r := mem_ball.2 hlt
        have h0 : analyticOrderNatAt h z = 0 := by
          by_contra hne
          exact nf_finsum_ne_zero hfin hzb hne hsum
        have ha := hh.analyticAt (hV.mem_nhds (hC hz))
        rw [← ha.analyticOrderAt_eq_zero, ← ENat.natCast_toNat (htop z hz)]
        simp [analyticOrderNatAt] at h0 ⊢
        exact h0
      · exact hs z (mem_sphere.2 heq)
    rw [nf_circle_logDeriv_zero hV hh hr.le hC hne]
    simp
  | succ n ih =>
    intro h hh hs htop hsum
    have hfin := nf_zeros_finite hV hh hC
    obtain ⟨a, ha, hane⟩ : ∃ a ∈ ball c r, analyticOrderNatAt h a ≠ 0 :=
      exists_ne_zero_of_finsum_mem_ne_zero (by rw [hsum]; exact Nat.succ_ne_zero n)
    have ha0 : h a = 0 := nf_eq_zero_of_order_ne_zero hane
    have haV : a ∈ V := hC (ball_subset_closedBall ha)
    set k := dslope h a with hkdef
    have hk : DifferentiableOn ℂ k V := (Complex.differentiableOn_dslope (hV.mem_nhds haV)).2 hh
    have hhk : h = (fun z => z - a) * k := by
      funext z
      have := sub_smul_dslope h a z
      rw [ha0, sub_zero, smul_eq_mul] at this
      exact this.symm
    have hks : ∀ z ∈ sphere c r, k z ≠ 0 := by
      intro z hz hk0
      apply hs z hz
      rw [hhk]
      simp [hk0]
    have hord : ∀ z ∈ closedBall c r, analyticOrderAt h z =
        (if z = a then 1 else 0) + analyticOrderAt k z := by
      intro z hz
      rw [← nf_order_sub a z, hhk]
      exact analyticOrderAt_mul (analyticAt_id.sub analyticAt_const)
        (hk.analyticAt (hV.mem_nhds (hC hz)))
    have htopk : ∀ z ∈ closedBall c r, analyticOrderAt k z ≠ ⊤ := by
      intro z hz htk
      apply htop z hz
      rw [hord z hz, htk, add_top]
    have hnat : ∀ z ∈ ball c r, analyticOrderNatAt h z =
        (if z = a then 1 else 0) + analyticOrderNatAt k z := by
      intro z hz
      have hz' := ball_subset_closedBall hz
      unfold analyticOrderNatAt
      rw [hord z hz', ENat.toNat_add (by split_ifs <;> simp) (htopk z hz')]
      split_ifs <;> simp
    have hfink : (ball c r ∩ Function.support (analyticOrderNatAt k)).Finite :=
      nf_zeros_finite hV hk hC
    have hsumk : ∑ᶠ z ∈ ball c r, analyticOrderNatAt k z = n := by
      have h1 : ∑ᶠ z ∈ ball c r, analyticOrderNatAt h z =
          ∑ᶠ z ∈ ball c r, (if z = a then 1 else 0) +
            ∑ᶠ z ∈ ball c r, analyticOrderNatAt k z := by
        rw [← finsum_mem_add_distrib' _ hfink]
        · exact finsum_mem_congr rfl hnat
        · exact (finite_singleton a).subset (fun z hz => by
            simp only [mem_inter_iff, Function.mem_support, ne_eq, ite_eq_right_iff,
              one_ne_zero, imp_false, not_not] at hz
            exact hz.2)
      have h2 : ∑ᶠ z ∈ ball c r, (if z = a then 1 else 0) = 1 := by
        rw [finsum_mem_eq_sum_of_inter_support_eq _ (t := {a})]
        · simp
        · ext z
          by_cases hz : z = a <;> simp [hz, ha]
      rw [hsum, h2] at h1
      omega
    have hIk := ih k hk hks htopk hsumk
    have hcongr : EqOn (logDeriv h) (fun z => (z - a)⁻¹ + logDeriv k z) (sphere c r) := by
      intro z hz
      have hza : z ≠ a := by
        rintro rfl
        rw [mem_sphere] at hz
        rw [mem_ball] at ha
        linarith
      rw [hhk, logDeriv_mul (f := fun w : ℂ => w - a) (g := k) z (sub_ne_zero.2 hza) (hks z hz) (differentiableAt_id.sub_const a)
        (hk.differentiableAt (hV.mem_nhds (hC (sphere_subset_closedBall hz))))]
      simp [logDeriv_apply]
    rw [circleIntegral.integral_congr hr.le hcongr, circleIntegral.integral_add, hIk,
      circleIntegral.integral_sub_inv_of_mem_ball ha]
    · push_cast; ring
    · refine ContinuousOn.circleIntegrable hr.le ?_
      refine (continuousOn_id.sub continuousOn_const).inv₀ ?_
      intro z hz h0
      have h0' : z = a := sub_eq_zero.1 h0
      subst h0'
      rw [mem_sphere] at hz
      rw [mem_ball] at ha
      linarith
    · exact ContinuousOn.circleIntegrable hr.le (nf_logDeriv_continuousOn hV hk
        (sphere_subset_closedBall.trans hC) hks)

#print axioms nf_arg_principle_aux

lemma nf_arg_principle {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V) (hh : DifferentiableOn ℂ h V)
    {c : ℂ} {r : ℝ} (hr : 0 < r) (hC : closedBall c r ⊆ V) (hs : ∀ z ∈ sphere c r, h z ≠ 0) :
    (∮ z in C(c, r), logDeriv h z) = 2 * Real.pi * Complex.I * (∑ᶠ z ∈ ball c r, analyticOrderNatAt h z : ℕ) := by
  obtain ⟨δ, hδ, hsub⟩ := (isCompact_closedBall c r).exists_thickening_subset_open hV hC
  rw [thickening_closedBall hδ hr.le] at hsub
  have htop : ∀ z ∈ closedBall c r, analyticOrderAt h z ≠ ⊤ := by
    intro z hz htz
    rw [analyticOrderAt_eq_top] at htz
    have hAn : AnalyticOnNhd ℂ h (ball c (δ + r)) := fun w hw => hh.analyticAt (hV.mem_nhds (hsub hw))
    have hzb : z ∈ ball c (δ + r) := by
      rw [mem_ball]; rw [mem_closedBall] at hz; linarith
    have hEq := hAn.eqOn_zero_of_preconnected_of_eventuallyEq_zero
      (convex_ball c (δ + r)).isPreconnected hzb htz
    obtain ⟨p, hp⟩ := (NormedSpace.sphere_nonempty (x := c)).2 hr.le
    apply hs p hp
    apply hEq
    rw [mem_ball]; rw [mem_sphere] at hp; linarith
  exact nf_arg_principle_aux hr hV hC _ h hh hs htop rfl

#print axioms nf_arg_principle

lemma nf_div_estimate {u v U' V' : ℂ} {m B δ : ℝ} (hm : 0 < m) (hv : m ≤ ‖v‖) (hu : ‖u‖ ≤ B)
    (hU : ‖U' - u‖ ≤ δ) (hV : ‖V' - v‖ ≤ δ) (hδ : δ ≤ m / 2) :
    ‖U' / V' - u / v‖ ≤ 2 * δ * (m + B) / m ^ 2 := by
  have hv0 : v ≠ 0 := by
    intro h0; rw [h0, norm_zero] at hv; linarith
  have hV' : m / 2 ≤ ‖V'‖ := by
    have := norm_sub_norm_le v V'
    rw [norm_sub_rev] at this
    linarith
  have hV0 : V' ≠ 0 := by
    intro h0; rw [h0, norm_zero] at hV'; linarith
  have hδ0 : 0 ≤ δ := (norm_nonneg _).trans hU
  have hB0 : 0 ≤ B := (norm_nonneg _).trans hu
  have heq : U' / V' - u / v = ((U' - u) * v - u * (V' - v)) / (V' * v) := by
    field_simp
    ring
  rw [heq, norm_div, norm_mul]
  have hnum : ‖(U' - u) * v - u * (V' - v)‖ ≤ δ * ‖v‖ + B * δ := by
    calc ‖(U' - u) * v - u * (V' - v)‖ ≤ ‖(U' - u) * v‖ + ‖u * (V' - v)‖ := norm_sub_le _ _
      _ = ‖U' - u‖ * ‖v‖ + ‖u‖ * ‖V' - v‖ := by rw [norm_mul, norm_mul]
      _ ≤ δ * ‖v‖ + B * δ := by gcongr
  have hpos : 0 < ‖V'‖ * ‖v‖ := by positivity
  rw [div_le_div_iff₀ hpos (by positivity)]
  calc ‖(U' - u) * v - u * (V' - v)‖ * m ^ 2 ≤ (δ * ‖v‖ + B * δ) * m ^ 2 := by gcongr
    _ ≤ 2 * δ * (m + B) * (‖V'‖ * ‖v‖) := by
      have h1 : m ≤ 2 * ‖V'‖ := by linarith
      have h2 : (δ * ‖v‖ + B * δ) * m ^ 2 ≤ δ * (m + B) * m * ‖v‖ := by
        have : B * δ * m ^ 2 ≤ B * δ * m * ‖v‖ := by
          have := mul_le_mul_of_nonneg_left hv (mul_nonneg (mul_nonneg hB0 hδ0) hm.le)
          nlinarith
        nlinarith
      have h3 : δ * (m + B) * m * ‖v‖ ≤ δ * (m + B) * (2 * ‖V'‖) * ‖v‖ := by
        gcongr
      nlinarith

#print axioms nf_div_estimate

lemma nf_isolated_zero_ball {h : ℂ → ℂ} {U : Set ℂ} (hU : IsOpen U) (hUc : IsPreconnected U)
    (hh : DifferentiableOn ℂ h U) (hnz : ∃ z ∈ U, h z ≠ 0) {a : ℂ} (ha : a ∈ U) (ha0 : h a = 0)
    {ρ₀ : ℝ} (hρ₀ : 0 < ρ₀) :
    ∃ ρ, 0 < ρ ∧ ρ ≤ ρ₀ ∧ closedBall a ρ ⊆ U ∧ (∀ z ∈ sphere a ρ, h z ≠ 0) ∧
      ∑ᶠ z ∈ ball a ρ, analyticOrderNatAt h z ≠ 0 := by
  have hAn : AnalyticOnNhd ℂ h U := fun z hz => hh.analyticAt (hU.mem_nhds hz)
  rcases (hAn a ha).eventually_eq_zero_or_eventually_ne_zero with hev | hev
  · exfalso
    obtain ⟨z, hz, hz0⟩ := hnz
    exact hz0 (hAn.eqOn_zero_of_preconnected_of_eventuallyEq_zero hUc ha hev hz)
  obtain ⟨ε, hε, hεU⟩ := Metric.isOpen_iff.1 hU a ha
  obtain ⟨η, hη, hηne⟩ := Metric.mem_nhdsWithin_iff.1 hev
  set ρ := min ρ₀ (min (ε / 2) (η / 2)) with hρ_def
  have hρ : 0 < ρ := lt_min hρ₀ (lt_min (by linarith) (by linarith))
  have hρε : ρ ≤ ε / 2 := (min_le_right _ _).trans (min_le_left _ _)
  have hρη : ρ ≤ η / 2 := (min_le_right _ _).trans (min_le_right _ _)
  have hCU : closedBall a ρ ⊆ U := (closedBall_subset_ball (by linarith)).trans hεU
  have hsph : ∀ z ∈ sphere a ρ, h z ≠ 0 := by
    intro z hz
    apply hηne
    refine ⟨?_, ?_⟩
    · rw [mem_ball, mem_sphere.1 hz]; linarith
    · rw [mem_compl_iff, mem_singleton_iff]
      rintro rfl
      rw [mem_sphere, dist_self] at hz
      linarith
  refine ⟨ρ, hρ, min_le_left _ _, hCU, hsph, ?_⟩
  apply nf_finsum_ne_zero (nf_zeros_finite hU hh hCU) (mem_ball_self hρ)
  have hne_top : analyticOrderAt h a ≠ ⊤ := by
    rw [Ne, analyticOrderAt_eq_top]
    intro hev'
    obtain ⟨w, hw⟩ := (hev'.filter_mono nhdsWithin_le_nhds).and hev |>.exists
    exact hw.2 hw.1
  have hne_zero : analyticOrderAt h a ≠ 0 := by
    rw [Ne, (hAn a ha).analyticOrderAt_eq_zero, not_not]
    exact ha0
  unfold analyticOrderNatAt
  intro h0
  rw [ENat.toNat_eq_zero] at h0
  rcases h0 with h0 | h0
  · exact hne_zero h0
  · exact hne_top h0

#print axioms nf_isolated_zero_ball

lemma nf_equicontinuous {U : Set ℂ} (hU : IsOpen U)
    {f : ℕ → ℂ → ℂ} (hf : ∀ n, DifferentiableOn ℂ (f n) U)
    (hbd : ∀ K ⊆ U, IsCompact K → ∃ M : ℝ, ∀ n, ∀ z ∈ K, ‖f n z‖ ≤ M) {x₀ : ℂ} (hx₀ : x₀ ∈ U)
    {ε : ℝ} (hε : 0 < ε) : ∀ᶠ y in nhds x₀, ∀ n, dist (f n x₀) (f n y) < ε := by
  obtain ⟨R0, hR0, hball⟩ := Metric.isOpen_iff.1 hU x₀ hx₀
  set R := R0 / 3 with hR_def
  have hR : 0 < R := by positivity
  have hKU : closedBall x₀ (2 * R) ⊆ U := (closedBall_subset_ball (by linarith)).trans hball
  obtain ⟨M, hM⟩ := hbd _ hKU (isCompact_closedBall _ _)
  have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM 0 x₀ (mem_closedBall_self (by linarith)))
  have hderiv : ∀ n, ∀ y ∈ ball x₀ R, ‖deriv (f n) y‖ ≤ M / R := by
    intro n y hy
    rw [mem_ball] at hy
    have hsub : closedBall y R ⊆ closedBall x₀ (2 * R) := by
      intro z hz
      rw [mem_closedBall] at hz ⊢
      linarith [dist_triangle z y x₀]
    apply Complex.norm_deriv_le_of_forall_mem_sphere_norm_le hR
    · apply DifferentiableOn.diffContOnCl
      rw [closure_ball y hR.ne']
      exact (hf n).mono (hsub.trans hKU)
    · intro z hz
      exact hM n z (hsub (sphere_subset_closedBall hz))
  have hmv : ∀ n, ∀ y ∈ ball x₀ R, ‖f n y - f n x₀‖ ≤ M / R * ‖y - x₀‖ := by
    intro n y hy
    refine Convex.norm_image_sub_le_of_norm_deriv_le (fun z hz => ?_) (hderiv n)
      (convex_ball x₀ R) (mem_ball_self hR) hy
    exact (hf n).differentiableAt (hU.mem_nhds (hKU (ball_subset_closedBall.trans
      (closedBall_subset_closedBall (by linarith)) hz)))
  have hL : 0 < M / R + 1 := by positivity
  have hρ : 0 < min R (ε / (M / R + 1)) := lt_min hR (by positivity)
  filter_upwards [ball_mem_nhds x₀ hρ] with y hy n
  rw [mem_ball] at hy
  have hy1 : dist y x₀ < R := hy.trans_le (min_le_left _ _)
  have hy2 : dist y x₀ < ε / (M / R + 1) := hy.trans_le (min_le_right _ _)
  rw [dist_comm, dist_eq_norm]
  have h1 := hmv n y (mem_ball.2 hy1)
  rw [← dist_eq_norm y x₀] at h1
  rw [lt_div_iff₀ hL] at hy2
  have h2 : M / R * dist y x₀ ≤ (M / R + 1) * dist y x₀ := by
    have := dist_nonneg (x := y) (y := x₀)
    nlinarith
  linarith

#print axioms nf_equicontinuous

/-- Montel's theorem: holomorphic functions on an open set `U` that share one bound on each
compact set inside `U` contain a sub-list converging uniformly on every compact set inside `U`,
and the limit is holomorphic. -/
theorem montel_locally_bounded_has_locally_uniform_subsequence {U : Set ℂ} (hU : IsOpen U)
    {f : ℕ → ℂ → ℂ} (hf : ∀ n, DifferentiableOn ℂ (f n) U)
    (hbd : ∀ K ⊆ U, IsCompact K → ∃ M : ℝ, ∀ n, ∀ z ∈ K, ‖f n z‖ ≤ M) :
    ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ g : ℂ → ℂ, DifferentiableOn ℂ g U ∧
      TendstoLocallyUniformlyOn (fun k => f (φ k)) g atTop U := by
  set 𝔖 : Set (Set ℂ) := {K | K ⊆ U ∧ IsCompact K} with h𝔖
  set t : ℕ → Set ℂ := fun n => closedBall 0 n ∩ (thickening (1 / ((n : ℝ) + 1)) Uᶜ)ᶜ with ht_def
  have ht : ∀ n, t n ∈ 𝔖 := by
    intro n
    refine ⟨?_, (isCompact_closedBall 0 (n : ℝ)).inter_right isOpen_thickening.isClosed_compl⟩
    rintro z ⟨-, hz⟩
    by_contra hzU
    exact hz (self_subset_thickening (by positivity) _ hzU)
  have hmono : Monotone t := by
    intro n m hnm
    have hnm' : (n : ℝ) ≤ m := by exact_mod_cast hnm
    refine inter_subset_inter (closedBall_subset_closedBall hnm') (compl_subset_compl.2 ?_)
    apply thickening_mono
    apply one_div_le_one_div_of_le (by positivity)
    linarith
  have hex : ∀ K ∈ 𝔖, ∃ n, K ⊆ t n := by
    rintro K ⟨hKU, hK⟩
    obtain ⟨δ, hδ, hδU⟩ := hK.exists_thickening_subset_open hU hKU
    obtain ⟨R, hR⟩ := hK.isBounded.subset_closedBall 0
    obtain ⟨n, hn⟩ := exists_nat_gt (max R (1 / δ))
    refine ⟨n, fun z hz => ⟨?_, ?_⟩⟩
    · have := hR hz
      rw [mem_closedBall] at this ⊢
      linarith [le_max_left R (1 / δ)]
    · intro hzt
      rw [mem_thickening_iff] at hzt
      obtain ⟨w, hw, hzw⟩ := hzt
      apply hw
      apply hδU
      rw [mem_thickening_iff]
      refine ⟨z, hz, ?_⟩
      rw [dist_comm]
      refine hzw.trans ?_
      have h1 : 1 / δ < (n : ℝ) + 1 := by linarith [le_max_right R (1 / δ)]
      rw [div_lt_iff₀ (by positivity)]
      rw [div_lt_iff₀ hδ] at h1
      linarith
  have := UniformOnFun.isCountablyGenerated_uniformity (β := ℂ) 𝔖 ht hmono hex
  set u : ℕ → UniformOnFun ℂ ℂ 𝔖 := fun n => UniformOnFun.ofFun 𝔖 (f n) with hu_def
  have hcomp : IsCompact (closure (range u)) := by
    refine ArzelaAscoli.isCompact_closure_of_isClosedEmbedding (F := UniformOnFun.toFun 𝔖) (𝔖 := 𝔖)
      (fun K hK => hK.2) Topology.IsClosedEmbedding.id ?_ ?_
    · intro K hK x hx
      apply EquicontinuousAt.equicontinuousWithinAt
      rw [Metric.equicontinuousAt_iff_right]
      intro ε hε
      filter_upwards [nf_equicontinuous hU hf hbd (hK.1 hx) hε] with y hy
      rintro ⟨i, n, rfl⟩
      exact hy n
    · intro K hK x hx
      obtain ⟨M, hM⟩ := hbd K hK.1 hK.2
      refine ⟨closedBall 0 M, isCompact_closedBall _ _, ?_⟩
      rintro i ⟨n, rfl⟩
      rw [mem_closedBall, dist_zero_right]
      exact hM n x hx
  obtain ⟨a, -, φ, hφ, hlim⟩ := hcomp.tendsto_subseq (x := u)
    (fun n => subset_closure (mem_range_self n))
  have hT : TendstoLocallyUniformlyOn (fun k => f (φ k)) (UniformOnFun.toFun 𝔖 a) atTop U := by
    rw [tendstoLocallyUniformlyOn_iff_forall_isCompact hU]
    intro K hKU hK
    exact UniformOnFun.tendsto_iff_tendstoUniformlyOn.1 hlim K ⟨hKU, hK⟩
  exact ⟨φ, hφ, UniformOnFun.toFun 𝔖 a,
    hT.differentiableOn (Eventually.of_forall fun k => hf (φ k)) hU, hT⟩

/-- Hurwitz's theorem: if holomorphic `f n` converge locally uniformly on `U` to `g`, `g` is not
zero everywhere, and the circle of centre `c` and radius `r` lies with its inside in `U` and carries
no zero of `g`, then for all large `n` the number of zeros of `f n` inside the circle, each counted
with its multiplicity, equals that of `g`. -/
theorem hurwitz_zero_count_eventually_eq {U : Set ℂ} (hU : IsOpen U)
    {f : ℕ → ℂ → ℂ} {g : ℂ → ℂ} (hf : ∀ n, DifferentiableOn ℂ (f n) U)
    (hlim : TendstoLocallyUniformlyOn f g atTop U) (hg : ∃ z ∈ U, g z ≠ 0)
    {c : ℂ} {r : ℝ} (hr : 0 < r) (hC : closedBall c r ⊆ U)
    (hgC : ∀ z ∈ sphere c r, g z ≠ 0) :
    ∀ᶠ n in atTop, (∑ᶠ z ∈ ball c r, analyticOrderNatAt (f n) z) =
      ∑ᶠ z ∈ ball c r, analyticOrderNatAt g z := by
  have _ := hg
  have hgd : DifferentiableOn ℂ g U := hlim.differentiableOn (Eventually.of_forall hf) hU
  have hS : sphere c r ⊆ U := sphere_subset_closedBall.trans hC
  have hSc : IsCompact (sphere c r) := isCompact_sphere c r
  have hSne : (sphere c r).Nonempty := (NormedSpace.sphere_nonempty (x := c)).2 hr.le
  have hu : TendstoUniformlyOn f g atTop (sphere c r) :=
    (tendstoLocallyUniformlyOn_iff_forall_isCompact hU).1 hlim _ hS hSc
  have hu' : TendstoUniformlyOn (deriv ∘ f) (deriv g) atTop (sphere c r) :=
    (tendstoLocallyUniformlyOn_iff_forall_isCompact hU).1
      (hlim.deriv (Eventually.of_forall hf) hU) _ hS hSc
  obtain ⟨x₀, hx₀, hmin⟩ := hSc.exists_isMinOn hSne (hgd.continuousOn.mono hS).norm
  set m := ‖g x₀‖ with hm_def
  have hm : 0 < m := norm_pos_iff.2 (hgC x₀ hx₀)
  have hmle : ∀ z ∈ sphere c r, m ≤ ‖g z‖ := fun z hz => hmin hz
  obtain ⟨B, hB⟩ := hSc.exists_bound_of_continuousOn ((hgd.deriv hU).continuousOn.mono hS)
  have hB0 : 0 ≤ B := (norm_nonneg _).trans (hB x₀ hx₀)
  -- choose the closeness `δ` so that the log-derivatives differ by at most `1 / (2 r)`
  set δ := min (m / 2) (m ^ 2 / (4 * r * (m + B))) with hδ_def
  have hδ : 0 < δ := lt_min (by linarith) (by positivity)
  have hδm : δ ≤ m / 2 := min_le_left _ _
  have hδ2 : 2 * δ * (m + B) / m ^ 2 ≤ 1 / (2 * r) := by
    have h1 : δ ≤ m ^ 2 / (4 * r * (m + B)) := min_le_right _ _
    rw [div_le_div_iff₀ (by positivity) (by positivity)]
    rw [le_div_iff₀ (by positivity)] at h1
    nlinarith
  filter_upwards [Metric.tendstoUniformlyOn_iff.1 hu δ hδ,
    Metric.tendstoUniformlyOn_iff.1 hu' δ hδ] with n hn hn'
  have hfn0 : ∀ z ∈ sphere c r, f n z ≠ 0 := by
    intro z hz h0
    have h1 := hn z hz
    rw [dist_eq_norm, h0, sub_zero] at h1
    have := hmle z hz
    linarith
  have hlog : ∀ z ∈ sphere c r, ‖logDeriv (f n) z - logDeriv g z‖ ≤ 1 / (2 * r) := by
    intro z hz
    rw [logDeriv_apply, logDeriv_apply]
    refine le_trans (nf_div_estimate hm (hmle z hz) (hB z hz) ?_ ?_ hδm) hδ2
    · have := hn' z hz
      rw [dist_comm, dist_eq_norm] at this
      exact this.le
    · have := hn z hz
      rw [dist_comm, dist_eq_norm] at this
      exact this.le
  have hIn := nf_arg_principle hU (hf n) hr hC hfn0
  have hIg := nf_arg_principle hU hgd hr hC hgC
  have hdiff : (∮ z in C(c, r), (logDeriv (f n) z - logDeriv g z)) =
      2 * Real.pi * Complex.I * ((∑ᶠ z ∈ ball c r, analyticOrderNatAt (f n) z : ℕ) -
        (∑ᶠ z ∈ ball c r, analyticOrderNatAt g z : ℕ) : ℂ) := by
    rw [circleIntegral.integral_sub, hIn, hIg, mul_sub]
    · exact ContinuousOn.circleIntegrable hr.le (nf_logDeriv_continuousOn hU (hf n) hS hfn0)
    · exact ContinuousOn.circleIntegrable hr.le (nf_logDeriv_continuousOn hU hgd hS hgC)
  have hbound := circleIntegral.norm_integral_le_of_norm_le_const hr.le hlog
  rw [hdiff] at hbound
  set N₁ := ∑ᶠ z ∈ ball c r, analyticOrderNatAt (f n) z
  set N₂ := ∑ᶠ z ∈ ball c r, analyticOrderNatAt g z
  have hnorm : ‖2 * (Real.pi : ℂ) * Complex.I * ((N₁ : ℂ) - N₂)‖ =
      2 * Real.pi * |(N₁ : ℝ) - N₂| := by
    have : ((N₁ : ℂ) - N₂) = (((N₁ : ℝ) - N₂ : ℝ) : ℂ) := by push_cast; ring
    rw [this, norm_mul, norm_mul, norm_mul, Complex.norm_real, Complex.norm_I, Complex.norm_real]
    simp [Real.norm_eq_abs, abs_of_pos Real.pi_pos]
  rw [hnorm] at hbound
  have hr' : 2 * Real.pi * r * (1 / (2 * r)) = Real.pi := by field_simp
  rw [hr'] at hbound
  have habs : |(N₁ : ℝ) - N₂| < 1 := by
    have := Real.pi_pos
    nlinarith [abs_nonneg ((N₁ : ℝ) - N₂)]
  rw [abs_sub_lt_iff] at habs
  have h1 : (N₁ : ℝ) < N₂ + 1 := by linarith
  have h2 : (N₂ : ℝ) < N₁ + 1 := by linarith
  have h1' : N₁ < N₂ + 1 := by exact_mod_cast h1
  have h2' : N₂ < N₁ + 1 := by exact_mod_cast h2
  omega

/-- Limits of one-to-one maps: on a region (an open set in one piece), a locally uniform limit of
one-to-one holomorphic functions is one-to-one or constant. -/
theorem injOn_or_const_of_tendstoLocallyUniformlyOn {U : Set ℂ} (hU : IsOpen U)
    (hUc : IsPreconnected U) {f : ℕ → ℂ → ℂ} {g : ℂ → ℂ}
    (hf : ∀ n, DifferentiableOn ℂ (f n) U) (hinj : ∀ n, InjOn (f n) U)
    (hlim : TendstoLocallyUniformlyOn f g atTop U) :
    InjOn g U ∨ ∃ w : ℂ, ∀ z ∈ U, g z = w := by
  by_contra hcon
  push Not at hcon
  obtain ⟨hni, hnc⟩ := hcon
  obtain ⟨a, ha, b, hb, hab, hne⟩ : ∃ a ∈ U, ∃ b ∈ U, g a = g b ∧ a ≠ b := by
    simp only [InjOn, not_forall] at hni
    obtain ⟨a, ha, b, hb, hab, hne⟩ := hni
    exact ⟨a, ha, b, hb, hab, hne⟩
  set w := g a with hw
  have hgd : DifferentiableOn ℂ g U := hlim.differentiableOn (Eventually.of_forall hf) hU
  set h : ℂ → ℂ := fun z => g z - w with hh_def
  set F : ℕ → ℂ → ℂ := fun n z => f n z - w with hF_def
  have hhd : DifferentiableOn ℂ h U := hgd.sub_const w
  have hFd : ∀ n, DifferentiableOn ℂ (F n) U := fun n => (hf n).sub_const w
  have hFlim : TendstoLocallyUniformlyOn F h atTop U := by
    rw [Metric.tendstoLocallyUniformlyOn_iff] at hlim ⊢
    intro ε hε x hx
    obtain ⟨t, ht, hev⟩ := hlim ε hε x hx
    refine ⟨t, ht, hev.mono fun n hn y hy => ?_⟩
    simpa [h, F, dist_sub_right] using hn y hy
  have hnz : ∃ z ∈ U, h z ≠ 0 := by
    obtain ⟨z, hz, hz'⟩ := hnc w
    exact ⟨z, hz, sub_ne_zero.2 hz'⟩
  have hd : 0 < dist a b := dist_pos.2 hne
  obtain ⟨ρa, hρa, hρa', hCa, hsa, hNa⟩ :=
    nf_isolated_zero_ball hU hUc hhd hnz ha (by simp [h, w]) (ρ₀ := dist a b / 2) (by linarith)
  obtain ⟨ρb, hρb, hρb', hCb, hsb, hNb⟩ :=
    nf_isolated_zero_ball hU hUc hhd hnz hb (by simp [h, w, hab]) (ρ₀ := dist a b / 2)
      (by linarith)
  have hEa := hurwitz_zero_count_eventually_eq hU hFd hFlim hnz hρa hCa hsa
  have hEb := hurwitz_zero_count_eventually_eq hU hFd hFlim hnz hρb hCb hsb
  obtain ⟨n, hna, hnb⟩ := (hEa.and hEb).exists
  rw [← hna] at hNa
  rw [← hnb] at hNb
  obtain ⟨x, hx, hx0⟩ := exists_ne_zero_of_finsum_mem_ne_zero hNa
  obtain ⟨y, hy, hy0⟩ := exists_ne_zero_of_finsum_mem_ne_zero hNb
  have hFx := nf_eq_zero_of_order_ne_zero hx0
  have hFy := nf_eq_zero_of_order_ne_zero hy0
  have hxU : x ∈ U := hCa (ball_subset_closedBall hx)
  have hyU : y ∈ U := hCb (ball_subset_closedBall hy)
  have hxy : x ≠ y := by
    rintro rfl
    rw [mem_ball] at hx hy
    have := dist_triangle_left a b x
    linarith
  apply hxy
  apply hinj n hxU hyU
  simp only [F, sub_eq_zero] at hFx hFy
  rw [hFx, hFy]

-- The gap of z + z²/n factors as (a - b)(1 + (a + b)/n).
example (a b n : ℂ) (hn : n ≠ 0) :
    (a + a ^ 2 / n) - (b + b ^ 2 / n) = (a - b) * (1 + (a + b) / n) := by
  field_simp
  ring
-- For n = 1 it fails: f₁(-3/10) = f₁(-7/10) = -21/100.
example : ((-3 / 10 : ℚ) + (-3 / 10) ^ 2) = -21 / 100 := by norm_num
example : ((-7 / 10 : ℚ) + (-7 / 10) ^ 2) = -21 / 100 := by norm_num
-- Slope cap M/δ = 1/(1/10) = 10.
example : (1 : ℚ) / (1 / 10) = 10 := by norm_num
-- The zero 1/3 of z - 1/3 lies inside |z| = 1/2.
example : (1 : ℚ) / 3 < 1 / 2 := by norm_num
-- The roots ±i/√5 of z² + 1/5 have size squared 1/5 < (1/2)², so both lie inside |z| = 1/2.
example : (1 : ℚ) / 5 < (1 / 2) ^ 2 := by norm_num
-- Stretch of g₁₀ = (z + z²/10)/(1 + 1/10) at 0 is 10/11.
example : (1 + 1 / 10 : ℚ)⁻¹ = 10 / 11 := by norm_num
-- Worst gap |g₁₀ - z| on the rim, at z = -1: 2/11.
example : ((-1 + (-1) ^ 2 / 10) / (1 + 1 / 10) : ℚ) - (-1) = 2 / 11 := by norm_num

#print axioms montel_locally_bounded_has_locally_uniform_subsequence
#print axioms hurwitz_zero_count_eventually_eq
#print axioms injOn_or_const_of_tendstoLocallyUniformlyOn
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'nf_finsum_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_eq_zero_of_order_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_zeros_finite' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_logDeriv_differentiableAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_circle_logDeriv_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_logDeriv_continuousOn' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_order_sub' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_arg_principle_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_arg_principle' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_div_estimate' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_isolated_zero_ball' depends on axioms: [propext, Classical.choice, Quot.sound]
'nf_equicontinuous' depends on axioms: [propext, Classical.choice, Quot.sound]
'montel_locally_bounded_has_locally_uniform_subsequence' depends on axioms: [propext, Classical.choice, Quot.sound]
'hurwitz_zero_count_eventually_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'injOn_or_const_of_tendstoLocallyUniformlyOn' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A smaller circle.** In the `edge` line, change radius `0.5` to `0.45`. The zero 0.4 (n = 10) is inside, 0.49 (n = 100) is not: `[1, 0]`; the third assert fails.
> - **Let n = 1 in.** In the `every` line, change `(2, 10)` to `(1, 10)`. Points such as −0.3 gain a second solution, `every` prints no; the third assert fails.
> - **Drop the scaling.** In `g`, change `(1 + 1 / n)` to `1`. $`g_2`$ reaches 1.5 on the rim, every stretch is 1; the fifth assert fails.

---

## The usual mistake

> [!warning]
> **Trusting "bounded" off the complex plane.** The proof needs Cauchy's estimate, which only holomorphic functions obey. On $`0 \le x \le \pi`$, $`\sin(nx)`$ stays below 1 but has slope n at 0, and no sub-list converges uniformly.
>
> - **Counting distinct zeros.** $`z^2`$ has one zero point, counted twice, matching $`z^2 + 1/n`$ for n ≥ 5.
> - **Drawing C through the limit's zero.** For n ≥ 2, each $`z - 1/2 + 1/n`$ has 1 zero inside $`\lvert z\rvert = 1/2`$; the limit has 0.
> - **Forgetting the constant case.** One-to-one maps z/n converge to 0.
> - **Expecting even convergence on the open disc.** $`z^{40}`$ is still 0.996008 at 0.9999.

---

## Where you meet it in real life

- **Conformal maps in engineering.** Flow and heat problems on awkward shapes are solved by mapping them onto a disc; this card is why the map exists.
- **Roots under rounding.** A polynomial with slightly wrong coefficients keeps its root count inside any circle that avoids the exact roots.
- **Fractals of iteration.** Where the repeats of a map form a normal family is the calm Fatou set; the rest is the Julia set.

> **Say it back**
> A size bound on holomorphic functions caps their slopes (Cauchy's estimate), so a diagonal choice finds a sub-list converging on every closed disc inside: Montel. The zero count, an integral of f′/f, is a converging whole number, so it stays fixed: Hurwitz. So a limit of one-to-one maps is one-to-one or constant. Together they build the Riemann map.

---

## What this builds on

- [Limits of holomorphic functions](02-uniform-limits-of-holomorphic-functions.md): the limit is holomorphic, and derivatives converge too.
- [Derivatives from the boundary](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/06-derivatives-from-the-boundary.md): Cauchy's estimate, turning a size bound into a slope bound.

## Where this goes next

- [The argument principle](../06-Real%20Integrals%20and%20Counting%20Zeros/06-the-argument-principle.md): the zero count of Step 4, extended to poles and read as turns of the image.
- [The Riemann mapping theorem](../07-Conformal%20Maps%20and%20Harmonic%20Functions/08-riemann-mapping-theorem-and-schwarz-christoffel.md): uses Step 6 to show every region without holes, short of the plane, is a disc in disguise.
- [Picard's theorems](../05-Laurent%20Series%2C%20Singularities%20and%20Residues/06-picards-theorems.md): a non-constant function on the whole plane misses at most one value.
- [Runge's theorem](11-runges-theorem.md): holomorphic functions as uniform limits of rational functions, and of polynomials on sets with no holes.
- [Arzela-Ascoli](../../17-Topology/01-Metric%20Spaces/09-arzela-ascoli.md): the Step 2 argument on any compact metric space.

Montel needs a shared bound; whether missing two values is enough is left to Picard's theorems.

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Stein, Elias M., and Rami Shakarchi. *Complex Analysis*. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113852/complex-analysis). Chapter 8, section 3: Montel, one-to-one limits, and the Riemann mapping proof.
- Conway, John B. *Functions of One Complex Variable I*, 2nd ed. Springer, Graduate Texts in Mathematics 11, 1978. [doi:10.1007/978-1-4612-6313-5](https://doi.org/10.1007/978-1-4612-6313-5). Chapter VII: normal families, Hurwitz and the Riemann mapping theorem.
- Montel, Paul. "Sur les suites infinies de fonctions." *Annales scientifiques de l'École normale supérieure* 24 (1907): 233–334. [doi:10.24033/asens.580](https://doi.org/10.24033/asens.580). The original paper on bounded families.
- Hurwitz, A. "Ueber die Nullstellen der Bessel'schen Function." *Mathematische Annalen* 33 (1888): 246–266. [doi:10.1007/BF01443855](https://doi.org/10.1007/BF01443855). Bessel zeros counted through a limit: the source of Hurwitz's theorem.
