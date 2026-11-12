# Surface area: why a slanted strip needs the slant length

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Curves and Solids](../README.md#s05) → Surface area

---

## General Overview

A glassworks silver-plates the outside of a wine glass's bowl. The bowl is the lower 6 cm of a ball of radius 4 cm, with a rim 3.464102 cm from the centre line. The plating is 0.002 cm thick; silver weighs 10.49 g per cm^3. How much silver does one glass take?

Thickness times area gives the silver's volume, so the question is the bowl's area. The bowl is a curve spun round an axis: its side profile turned a full circle about the centre line.

Cut it into thin rings, like a barrel's hoops. Each ring's area is its circumference times its width. The catch is which width: measured up the glass, a ring is thinner than measured along the curved wall, and silver covers the wall.

The answer is 150.796447 cm^2 of bowl, 0.301593 cm^3 of silver, 3.1637 g per glass. The same method gives a whole ball's area, 4 pi R^2 for radius R, which Archimedes found by other means.

**Spin a curve round an axis and its surface area is the sum of thin rings, each one circumference times its slant length, and the slant length is the arc-length element, not the step along the axis.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, for surfaces measured by thin cone-shaped bands; the sphere's area is a worked case of it.

### The picture: the bowl and one band

<p align="center"><img src="../figures/surface-area-of-revolution.svg" alt="Side view of the glass&#x27;s bowl, drawn to scale: the lower 6 cm of a ball of radius 4 cm, with one shaded band between heights 1 cm and 2 cm whose slanted edge is 1.29 cm long" width="420"></p>

Drawn to scale, 1 cm = 25 units. Dotted: the axis. Dashed arc: the ball above the rim. Shaded: one band seen edge-on, whose slanted edges are the width the silver covers.

---

## The formula

Let $x$ be the height above the bowl's bottom, in cm, and $f(x)$ the profile's radius there. The slope $f'(x)$ is the rate of radius per unit of height, as on [Arc length](02-arc-length.md). Spin the profile from height $a$ to height $b$ once round the axis. The area swept is

$$S = \int_a^b 2\pi f(x)\sqrt{1 + f'(x)^2}\,dx$$

**Read it aloud:** add up, along the axis, each height's circumference times the wall's slant length there.

The factor $\sqrt{1 + f'(x)^2}\,dx$ is the arc-length element: the length of wall over an axial step $dx$. For the bowl, $f(x) = \sqrt{8x - x^2}$, the circle of radius 4 cm with its lowest point at height 0.

For a ball of radius $R$ cut to a height $h$, it comes out as

$$S = 2\pi R h, \qquad \text{and for the whole ball, } h = 2R: \quad S = 4\pi R^2.$$

**Read it aloud:** a slice of a ball has the area of a straight tube of the ball's radius and the slice's height.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$, $dx$ | height above the bowl's bottom, and a small step in it | 0 to 6 cm | — |
| $f$ | the radius of the profile at height $x$ | $\sqrt{8x - x^2}$ cm; 3.872983 cm at $x = 3$ | wider rings, more area |
| $f'$ | slope: cm of radius per cm of height | 0.258199 at $x = 3$ | a longer slant, more area |
| $a$, $b$ | heights where the spun piece starts and stops | 0 and 6 cm | a taller piece, more area |
| $S$ | area of the spun surface, cm^2 | 150.796447 cm^2 | more silver |
| $R$, $h$ | the ball's radius, and the height of the slice | 4 cm, 6 cm | area grows in step with each |
| $r_1$, $r_2$, $\ell$, $L$ | a band's edge radii and slant width; $L$ a full cone's slant | 2.6458, 3.4641, 1.2922 cm | a bigger band |
| $n$, $i$, $c_i$, $w$, $K$ | band count, one band, a point in it, widest band, steepest slope | 6 to 6000 bands | a closer total |

### When it holds

- **The radius is never negative.** A profile below the axis must use its distance, or that part cancels real area: What breaks shows 79.97 cm^2 counted as 0.
- **The slope is continuous.** A sharp corner: split there and add the pieces.
- **The slope stays finite at the ends,** or the integral is taken as a limit. The bowl's wall lies flat at its bottom, so its radius changes infinitely fast per unit of height there; Step 5 takes that limit.
- **One full turn about a straight axis the profile does not cross.** Half a turn gives half the area; a crossing profile sweeps some wall twice.

---

## Why it works

### Step 0: the silver covers the wall, and the wall is slanted

A thin ring of the bowl is nearly a strip of a cone. Its width is the wall it spans, longer than the height step whenever the wall leans.

### Step 1: one straight segment, spun, sweeps a band of area pi (r1 + r2) times slant

Join two points of the profile with a straight chord. Spun, it sweeps a **frustum**: a cone with its tip cut off, a lampshade. With edge radii $r_1$ and $r_2$ and slant width $\ell$, its area is

$$\pi\,(r_1 + r_2)\,\ell,$$

the average edge circumference times the slant.

<details>
<summary>The algebra behind this, if you want it</summary>

A cone of base radius $r_2$ and slant $L$ unrolls to a sector of radius $L$ and arc $2\pi r_2$, area $\pi r_2 L$. Extend the frustum to such a cone; the removed tip has slant $L - \ell$. Similar triangles give $r_1 / (L - \ell) = r_2 / L$ (taking $r_2 > r_1$), so $r_2 (L - \ell) = r_1 L$. The frustum's area is $\pi r_2 L - \pi r_1 (L - \ell) = \pi (r_2 - r_1) L + \pi r_1 \ell$, and $(r_2 - r_1) L = r_2 \ell$ from the similar triangles, which gives $\pi (r_1 + r_2)\ell$. Equal radii give a cylinder, $2\pi r_1 \ell$: the same formula.

</details>

### Step 2: the slant is the height step times the arc-length factor

The chord rises $\Delta x$ along the axis while the radius changes by $r_2 - r_1$. Pythagoras gives

$$\ell = \sqrt{\Delta x^2 + (r_2 - r_1)^2} = \Delta x\,\sqrt{1 + \left(\frac{r_2 - r_1}{\Delta x}\right)^2}.$$

The ratio inside is the chord's slope. The bowl's band from $x = 1$ to $x = 2$ has radii 2.6458 and 3.4641 cm and slant 1.2922 cm, not 1 cm; its area is 24.8027 cm^2. That centimetre of bowl truly has 25.1327 cm^2 (Step 4): the chord cuts inside the curve.

### Step 3: many thin bands, and the limit is the integral

Cut the profile into equal height steps and add the bands. Six bands fall short of 150.796447 cm^2 by 2.814318; 6000 bands by 0.000006.

As the steps thin, the chord's slope equals the profile's slope $f'(x)$ at some height inside the step (the mean value theorem: a point where the curve's slope equals the chord's), and the average radius approaches $f(x)$ at that height.

So each band tends to $2\pi f(x)\sqrt{1 + f'(x)^2}\,\Delta x$, and the sum of those is a Riemann sum whose limit is the integral. A Riemann sum is a total of function values times step widths: [The integral](../04-Integrals/01-riemann-integral.md).

<details>
<summary>Detailed proof</summary>

Let $f \ge 0$ with $f'$ continuous on $[a, b]$, split into steps of width at most $w$. On step $i$ the mean value theorem gives $c_i$ with chord slope $f'(c_i)$, so the band's slant is $\sqrt{1 + f'(c_i)^2}\,\Delta x_i$. On a closed interval, $|f'| \le K$ for some $K$, and $f$ is uniformly continuous: for every $\varepsilon > 0$ some $\delta > 0$ makes $w < \delta$ put both edge radii within $\varepsilon$ of $f(c_i)$. The band sum then differs from $\sum_i 2\pi f(c_i)\sqrt{1 + f'(c_i)^2}\,\Delta x_i$ by at most $2\pi\varepsilon\sqrt{1 + K^2}\,(b - a)$, and that sum is a Riemann sum of a continuous function, tending to the integral as $w \to 0$.

</details>

### Step 4: on a ball, radius times slant factor is the ball's radius

For the bowl, $f(x) = \sqrt{8x - x^2}$ and the slope is $f'(x) = (4 - x)/f(x)$. Multiply the radius by the slant factor:

$$f\sqrt{1 + f'^2} = \sqrt{f^2 + (4 - x)^2} = \sqrt{8x - x^2 + 16 - 8x + x^2} = 4.$$

The product is 4, the ball's radius, at every height. Low down the ring is small but the wall nearly flat, so a height step spans a long stretch of wall; higher up the ring is wide and the wall nearly upright. The two cancel exactly, so

$$S = \int_0^6 2\pi \cdot 4\,dx = 2\pi \cdot 4 \cdot 6 = 48\pi = 150.796447 \text{ cm}^2.$$

For any radius $R$ the product is $R$. A slice of height $h$ has area $2\pi R h$; the whole ball, $h = 2R$, has $4\pi R^2$, 201.061930 cm^2 here. This is Archimedes' result: a ball has the area of the tube that fits round it, ends excluded.

### Step 5: the steep bottom is a limit, played with numbers

At $x = 0$ the slope is infinite, so the hypothesis fails at that end. Start a little way up and slide the start down. Starting 0.01 cm up loses 0.251327 cm^2. To lose less than 0.01 cm^2, start below 0.000398 cm. Any tolerance can be met this way, so the limit is 150.796447 cm^2.

A second road measures tiny patches of the surface, located by height and angle round the axis: [Surface integrals](../09-Vector%20Calculus/05-surface-integrals-and-flux.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| radius at $x = 3$ | $\sqrt{8 \cdot 3 - 3^2} = \sqrt{15}$ | 3.872983 cm |
| slope at $x = 3$ | $(4 - 3) / 3.872983$ | 0.258199 |
| slant factor | $\sqrt{1 + 0.258199^2} = \sqrt{16/15}$ | 1.032796 |
| radius times slant factor | $3.872983 \times 1.032796$ | 4.000000 cm |
| area per cm of height | $2\pi \times 4$ | 25.1327 cm^2 |
| bowl, 6 cm tall | $25.1327 \times 6 = 48\pi$ | **150.796447 cm^2** |
| silver, 0.002 cm thick | $150.796447 \times 0.002$ | 0.301593 cm^3 |
| its weight | $0.301593 \times 10.49$ | **3.1637 g** |

Each glass takes just over 3 g of silver on its bowl, stem and foot aside.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Height step as the band's width | 127.04 cm^2 | Slant factor dropped |
| Disc formula, pi times radius squared | 226.19, in cm^3 | Sums volume, not skin |
| The whole ball's 4 pi R^2 | 201.061930 cm^2 | Counts the ball above the rim |
| Profile crinkled by 0.01 cm | 172.94 cm^2 | Close radii, far slopes |
| Signed radius $x - 3$ from 0 to 6, crossing the axis | 0.00, not 79.97 cm^2 | Negative radius cancels real area |

The crinkled profile is $f(x) + 0.01\sin(100x)$: never more than 0.01 cm from the bowl, yet its steep ripples add area. The line $x - 3$ drops the hypothesis that the radius is never negative: its two cones cancel instead of adding. The code prints all five.

---

## Code, from first principles, and it actually runs

Pi is built from a polygon. Road one: a difference quotient confirms radius times slant factor is 4, then $2\pi R h$. Road two uses no slope: chord bands, 6 to 6000, with the shortfall closing. A second case runs the whole ball.

### Python

```python
# Surface area of revolution -- the check behind the card.  Standard library
# only; math.sqrt and math.sin are the only primitives used.  The glass's bowl
# is the lower 6 cm of a ball of radius 4 cm: at height x above the bottom its
# radius is f(x) = sqrt(8x - x^2).  Road one: the formula, S = 2 pi R h.
# Road two: bands swept by chords, with no derivative anywhere.
import math

sides, s = 6, 1.0                           # Archimedes: a hexagon in a unit circle,
for _ in range(26):                         # its side count doubled 26 times
    s, sides = s / math.sqrt(2 + math.sqrt(4 - s * s)), sides * 2
PI = sides * s / 2                          # half the polygon's perimeter
R, H = 4.0, 6.0                             # ball radius and bowl height, cm

def f(x):
    return math.sqrt(max(8 * x - x * x, 0.0))

def bands(g, a, b, n, slant=True):          # n frustums, each pi (r1 + r2) times its width
    total, w = 0.0, (b - a) / n
    for k in range(n):
        x0, x1 = a + k * w, a + (k + 1) * w
        run = math.sqrt(w * w + (g(x1) - g(x0)) ** 2) if slant else w
        total += PI * (g(x0) + g(x1)) * run
    return total

def dq(g, x, h=1e-5):                       # a shrinking difference quotient for g'
    return (g(x + h) - g(x - h)) / (2 * h)

exact, ball = 2 * PI * R * H, 2 * PI * R * (2 * R)
print(f"pi, from a {sides}-sided polygon: {PI:.12f}")
print(f"bowl: R = {R:g} cm, h = {H:g} cm, rim radius {f(H):.6f} cm")
factors = []
for x in (1, 3, 5):
    k = math.sqrt(1 + dq(f, x) ** 2)
    factors.append(f(x) * k)
    print(f"x = {x}: radius {f(x):.6f}, slope {dq(f, x):.6f}, slant factor {k:.6f}, product {factors[-1]:.6f}")
print(f"road one, 2 pi R h: bowl {exact:.6f}, whole ball {ball:.6f}")
errs = []
for n in (6, 60, 600, 6000):
    errs.append(exact - bands(f, 0, H, n))
    print(f"road two, {n:4d} bands: {exact - errs[-1]:.6f}, short by {errs[-1]:.6f}")
ball2 = bands(f, 0, 2 * R, 6000)
print(f"road two, whole ball, 6000 bands: {ball2:.6f}")
print(f"one band, x 1 to 2: radii {f(1):.4f} and {f(2):.4f}, slant {math.sqrt(1 + (f(2) - f(1)) ** 2):.4f}, "
      f"area {bands(f, 1, 2, 1):.4f}, exact {2 * PI * R:.4f}")
print(f"pole: start 0.01 cm up, lose {2 * PI * R * 0.01:.6f}; to lose under 0.01, start below {0.01 / (2 * PI * R):.6f}")
print(f"silver 0.002 cm thick at 10.49 g per cm^3: {exact * 0.002:.6f} cm^3, {exact * 0.002 * 10.49:.4f} g")
print(f"figure, 25 per cm: centre (150, 120), band ({150 + 25 * f(1):.2f}, 195) to "
      f"({150 + 25 * f(2):.2f}, 170), rim ({150 - 25 * f(H):.2f} to {150 + 25 * f(H):.2f}, 70)")
w = H / 6000
disc = sum(PI * f((k + 0.5) * w) ** 2 * w for k in range(6000))
print(f"mistake, width not slant: {bands(f, 0, H, 60000, slant=False):.2f}")
print(f"mistake, disc formula pi f^2 (a volume, cm^3): {disc:.2f}")
print(f"mistake, crinkled within 0.01 cm: {bands(lambda x: f(x) + 0.01 * math.sin(100 * x), 0, H, 60000):.2f}")
print(f"mistake, signed radius x - 3 on 0 to 6: {round(bands(lambda x: x - 3, 0, 6, 6), 2) + 0.0:.2f}, true {bands(lambda x: abs(x - 3), 0, 6, 6):.2f}")
assert abs(exact - bands(f, 0, H, 6000)) < 1e-3               # road two meets road one
assert all(a > b > 0 for a, b in zip(errs, errs[1:]))          # and closes in from below
assert abs(ball2 - 4 * PI * R * R) < 1e-3                       # the sphere, 4 pi R^2
assert all(abs(p - R) < 1e-6 for p in factors)                  # radius x slant factor = R
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
pi, from a 402653184-sided polygon: 3.141592653590
bowl: R = 4 cm, h = 6 cm, rim radius 3.464102 cm
x = 1: radius 2.645751, slope 1.133893, slant factor 1.511858, product 4.000000
x = 3: radius 3.872983, slope 0.258199, slant factor 1.032796, product 4.000000
x = 5: radius 3.872983, slope -0.258199, slant factor 1.032796, product 4.000000
road one, 2 pi R h: bowl 150.796447, whole ball 201.061930
road two,    6 bands: 147.982130, short by 2.814318
road two,   60 bands: 150.759254, short by 0.037193
road two,  600 bands: 150.795985, short by 0.000462
road two, 6000 bands: 150.796442, short by 0.000006
road two, whole ball, 6000 bands: 201.061912
one band, x 1 to 2: radii 2.6458 and 3.4641, slant 1.2922, area 24.8027, exact 25.1327
pole: start 0.01 cm up, lose 0.251327; to lose under 0.01, start below 0.000398
silver 0.002 cm thick at 10.49 g per cm^3: 0.301593 cm^3, 3.1637 g
figure, 25 per cm: centre (150, 120), band (216.14, 195) to (236.60, 170), rim (63.40 to 236.60, 70)
mistake, width not slant: 127.04
mistake, disc formula pi f^2 (a volume, cm^3): 226.19
mistake, crinkled within 0.01 cm: 172.94
mistake, signed radius x - 3 on 0 to 6: 0.00, true 79.97
ALL CHECKS PASS
```

### Rust

```rust
// Surface area of revolution -- the same check as the Python, in Rust, std only.
// The glass's bowl is the lower 6 cm of a ball of radius 4 cm: at height x above
// the bottom its radius is f(x) = sqrt(8x - x^2).  Road one: S = 2 pi R h.
// Road two: bands swept by chords, with no derivative anywhere.

fn f(x: f64) -> f64 {
    (8.0 * x - x * x).max(0.0).sqrt()
}

// n frustums, each pi (r1 + r2) times its width (slant, or axial if slant is false)
fn bands(pi: f64, g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize, slant: bool) -> f64 {
    let w = (b - a) / n as f64;
    let mut total = 0.0;
    for k in 0..n {
        let (x0, x1) = (a + k as f64 * w, a + (k + 1) as f64 * w);
        let run = if slant { (w * w + (g(x1) - g(x0)).powi(2)).sqrt() } else { w };
        total += pi * (g(x0) + g(x1)) * run;
    }
    total
}

// a shrinking difference quotient for g'
fn dq(g: &dyn Fn(f64) -> f64, x: f64) -> f64 {
    let h = 1e-5;
    (g(x + h) - g(x - h)) / (2.0 * h)
}

fn main() {
    let (mut sides, mut s) = (6u64, 1.0f64); // Archimedes: a hexagon in a unit circle
    for _ in 0..26 {
        s = s / (2.0 + (4.0 - s * s).sqrt()).sqrt();
        sides *= 2;
    }
    let pi = sides as f64 * s / 2.0; // half the polygon's perimeter
    let (r, h) = (4.0f64, 6.0f64); // ball radius and bowl height, cm
    let exact = 2.0 * pi * r * h;
    let ball = 2.0 * pi * r * (2.0 * r);
    println!("pi, from a {}-sided polygon: {:.12}", sides, pi);
    println!("bowl: R = {} cm, h = {} cm, rim radius {:.6} cm", r, h, f(h));
    let mut factors = Vec::new();
    for x in [1.0, 3.0, 5.0] {
        let k = (1.0 + dq(&f, x).powi(2)).sqrt();
        factors.push(f(x) * k);
        println!("x = {}: radius {:.6}, slope {:.6}, slant factor {:.6}, product {:.6}", x, f(x), dq(&f, x), k, f(x) * k);
    }
    println!("road one, 2 pi R h: bowl {:.6}, whole ball {:.6}", exact, ball);
    let mut errs = Vec::new();
    for n in [6usize, 60, 600, 6000] {
        errs.push(exact - bands(pi, &f, 0.0, h, n, true));
        let e = errs[errs.len() - 1];
        println!("road two, {:4} bands: {:.6}, short by {:.6}", n, exact - e, e);
    }
    let ball2 = bands(pi, &f, 0.0, 2.0 * r, 6000, true);
    println!("road two, whole ball, 6000 bands: {:.6}", ball2);
    println!("one band, x 1 to 2: radii {:.4} and {:.4}, slant {:.4}, area {:.4}, exact {:.4}",
        f(1.0), f(2.0), (1.0 + (f(2.0) - f(1.0)).powi(2)).sqrt(), bands(pi, &f, 1.0, 2.0, 1, true), 2.0 * pi * r);
    println!("pole: start 0.01 cm up, lose {:.6}; to lose under 0.01, start below {:.6}",
        2.0 * pi * r * 0.01, 0.01 / (2.0 * pi * r));
    println!("silver 0.002 cm thick at 10.49 g per cm^3: {:.6} cm^3, {:.4} g", exact * 0.002, exact * 0.002 * 10.49);
    println!("figure, 25 per cm: centre (150, 120), band ({:.2}, 195) to ({:.2}, 170), rim ({:.2} to {:.2}, 70)",
        150.0 + 25.0 * f(1.0), 150.0 + 25.0 * f(2.0), 150.0 - 25.0 * f(h), 150.0 + 25.0 * f(h));
    let w = h / 6000.0;
    let disc: f64 = (0..6000).map(|k| pi * f((k as f64 + 0.5) * w).powi(2) * w).sum();
    let crinkle = |x: f64| f(x) + 0.01 * (100.0 * x).sin();
    println!("mistake, width not slant: {:.2}", bands(pi, &f, 0.0, h, 60000, false));
    println!("mistake, disc formula pi f^2 (a volume, cm^3): {:.2}", disc);
    println!("mistake, crinkled within 0.01 cm: {:.2}", bands(pi, &crinkle, 0.0, h, 60000, true));
    let signed = bands(pi, &|x: f64| x - 3.0, 0.0, 6.0, 6, true);
    println!("mistake, signed radius x - 3 on 0 to 6: {:.2}, true {:.2}",
        (signed * 100.0).round() / 100.0 + 0.0, bands(pi, &|x: f64| (x - 3.0).abs(), 0.0, 6.0, 6, true));
    assert!((exact - bands(pi, &f, 0.0, h, 6000, true)).abs() < 1e-3); // road two meets road one
    assert!(errs.windows(2).all(|p| p[0] > p[1] && p[1] > 0.0)); // and closes in from below
    assert!((ball2 - 4.0 * pi * r * r).abs() < 1e-3); // the sphere, 4 pi R^2
    assert!(factors.iter().all(|p| (p - r).abs() < 1e-6)); // radius x slant factor = R
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
pi, from a 402653184-sided polygon: 3.141592653590
bowl: R = 4 cm, h = 6 cm, rim radius 3.464102 cm
x = 1: radius 2.645751, slope 1.133893, slant factor 1.511858, product 4.000000
x = 3: radius 3.872983, slope 0.258199, slant factor 1.032796, product 4.000000
x = 5: radius 3.872983, slope -0.258199, slant factor 1.032796, product 4.000000
road one, 2 pi R h: bowl 150.796447, whole ball 201.061930
road two,    6 bands: 147.982130, short by 2.814318
road two,   60 bands: 150.759254, short by 0.037193
road two,  600 bands: 150.795985, short by 0.000462
road two, 6000 bands: 150.796442, short by 0.000006
road two, whole ball, 6000 bands: 201.061912
one band, x 1 to 2: radii 2.6458 and 3.4641, slant 1.2922, area 24.8027, exact 25.1327
pole: start 0.01 cm up, lose 0.251327; to lose under 0.01, start below 0.000398
silver 0.002 cm thick at 10.49 g per cm^3: 0.301593 cm^3, 3.1637 g
figure, 25 per cm: centre (150, 120), band (216.14, 195) to (236.60, 170), rim (63.40 to 236.60, 70)
mistake, width not slant: 127.04
mistake, disc formula pi f^2 (a volume, cm^3): 226.19
mistake, crinkled within 0.01 cm: 172.94
mistake, signed radius x - 3 on 0 to 6: 0.00, true 79.97
ALL CHECKS PASS
```

The two outputs are identical.

### Lean

Lean proves the band limit for every profile that meets When it holds, and the slice area for a ball of every radius.

- Take a radius that is never negative, with a slope that is continuous and finite at the ends. Cut $[a, b]$ into $n$ equal height steps and add the chord bands. As $n$ grows, the total tends to $\int_a^b 2\pi f(x)\sqrt{1 + f'(x)^2}\,dx$.
- On a ball of any radius $R$, at every height strictly between bottom and top, the radius times the slant factor is exactly $R$.
- A slice of the ball from height $a$ to height $b$ has area $2\pi R(b - a)$. The whole ball has $4\pi R^2$.
- The hand arithmetic holds exactly: the radius and slope at $x = 3$, the bowl's $48\pi$, the band's radii, the frustum algebra, the signed radius and the silver.

The band totals from 6 to 6000, Step 5's numbers, the mistakes table and the figure are left to the Python and Rust checks.

```lean
-- Surface area: the frustum bands swept by chords of a non-negative profile with a continuous slope add up, as the bands thin, to the integral of 2π f(x) √(1 + f'(x)^2), and a slice of a ball of radius R and height h has area 2πRh, so the whole ball has 4πR^2.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow

open Set Filter Topology Real

/-- The slant width moves by at most the change in rise: √(h² + A²) ≤ √(h² + B²) + |A − B|. -/
lemma sa_sqrt_le (h A B : ℝ) : √(h ^ 2 + A ^ 2) ≤ √(h ^ 2 + B ^ 2) + |A - B| := by
  have hB : |B| ≤ √(h ^ 2 + B ^ 2) := Real.abs_le_sqrt (by nlinarith)
  have hs := Real.sq_sqrt (show 0 ≤ h ^ 2 + B ^ 2 by positivity)
  have key : h ^ 2 + A ^ 2 ≤ (√(h ^ 2 + B ^ 2) + |A - B|) ^ 2 := by
    have h1 : B * (A - B) ≤ |B| * |A - B| := by rw [← abs_mul]; exact le_abs_self _
    have h2 : |B| * |A - B| ≤ √(h ^ 2 + B ^ 2) * |A - B| :=
      mul_le_mul_of_nonneg_right hB (abs_nonneg _)
    have h3 : |A - B| ^ 2 = (A - B) ^ 2 := sq_abs _
    nlinarith
  calc √(h ^ 2 + A ^ 2) ≤ √((√(h ^ 2 + B ^ 2) + |A - B|) ^ 2) := Real.sqrt_le_sqrt key
    _ = √(h ^ 2 + B ^ 2) + |A - B| := Real.sqrt_sq (by positivity)

/-- One band against its strip of the integral, for short enough steps. -/
lemma sa_band_close (f f' : ℝ → ℝ) (a b : ℝ)
    (hf_deriv : ∀ x ∈ Icc a b, HasDerivWithinAt f (f' x) (Icc a b) x)
    (hf'_cont : ContinuousOn f' (Icc a b)) (ε : ℝ) (hε : 0 < ε) :
    ∃ δ > 0, ∀ u v, u ∈ Icc a b → v ∈ Icc a b → u ≤ v → v - u < δ →
      |π * (f u + f v) * √((v - u) ^ 2 + (f v - f u) ^ 2) -
        ∫ x in u..v, 2 * π * f x * √(1 + f' x ^ 2)| ≤ ε * (v - u) := by
  have hfc : ContinuousOn f (Icc a b) := fun x hx => (hf_deriv x hx).continuousWithinAt
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hfc
  obtain ⟨M', hM'⟩ := isCompact_Icc.exists_bound_of_continuousOn hf'_cont
  have hM0 : ∀ x ∈ Icc a b, |f x| ≤ |M| := fun x hx => (hM x hx).trans (le_abs_self _)
  have hM'0 : ∀ x ∈ Icc a b, |f' x| ≤ |M'| := fun x hx => (hM' x hx).trans (le_abs_self _)
  have hgc : ContinuousOn (fun x => 2 * π * f x * √(1 + f' x ^ 2)) (Icc a b) :=
    (continuousOn_const.mul hfc).mul ((continuousOn_const.add (hf'_cont.pow 2)).sqrt)
  set ρ := ε / (4 * π * (1 + |M'|)) with hρdef
  set η := ε / (4 * π * (|M| + 1)) with hηdef
  have hρ : 0 < ρ := by positivity
  have hη : 0 < η := by positivity
  obtain ⟨δ1, hδ1, hu1⟩ := Metric.uniformContinuousOn_iff.mp
    (isCompact_Icc.uniformContinuousOn_of_continuous hfc) ρ hρ
  obtain ⟨δ2, hδ2, hu2⟩ := Metric.uniformContinuousOn_iff.mp
    (isCompact_Icc.uniformContinuousOn_of_continuous hf'_cont) η hη
  refine ⟨min δ1 δ2, lt_min hδ1 hδ2, ?_⟩
  intro u v hu hv huv hδ
  have hsub : Icc u v ⊆ Icc a b := Icc_subset_Icc hu.1 hv.2
  have hclose : ∀ y ∈ Icc u v, ∀ z ∈ Icc u v, dist z y < min δ1 δ2 := by
    intro y hy z hz
    rw [Real.dist_eq, abs_lt]
    constructor <;> linarith [hy.1, hy.2, hz.1, hz.2]
  have huI : u ∈ Icc u v := ⟨le_rfl, huv⟩
  have hvI : v ∈ Icc u v := ⟨huv, le_rfl⟩
  -- the rise over the step is at most |M'| times the step
  have hrise : |f v - f u| ≤ |M'| * (v - u) := by
    have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := f) (f' := f') (s := Icc u v)
      (C := |M'|) (fun x hx => (hf_deriv x (hsub hx)).mono hsub)
      (fun x hx => hM'0 x (hsub hx)) (convex_Icc u v) huI hvI
    rwa [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 huv)] at this
  have hD : √((v - u) ^ 2 + (f v - f u) ^ 2) ≤ (1 + |M'|) * (v - u) := by
    have := sa_sqrt_le (v - u) (f v - f u) 0
    rw [show (0 : ℝ) ^ 2 = 0 by norm_num, add_zero, Real.sqrt_sq (sub_nonneg.2 huv),
      sub_zero] at this
    linarith
  -- pointwise comparison
  have hpt : ∀ y ∈ Icc u v,
      |π * (f u + f v) * √((v - u) ^ 2 + (f v - f u) ^ 2) -
        (v - u) * (2 * π * f y * √(1 + f' y ^ 2))| ≤ ε * (v - u) := by
    intro y hy
    have hyab := hsub hy
    -- the rise is close to the slope at y times the step
    have hlin : |f v - f u - (v - u) * f' y| ≤ η * (v - u) := by
      have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
        (f := fun z => f z - f' y * z) (f' := fun z => f' z - f' y) (s := Icc u v)
        (C := η) (fun x hx => ((hf_deriv x (hsub hx)).mono hsub).sub
          ((hasDerivWithinAt_id x _).const_mul (f' y) |>.congr_deriv (by simp)))
        (fun z hz => by
          rw [Real.norm_eq_abs, ← Real.dist_eq]
          exact (hu2 z (hsub hz) y hyab (lt_of_lt_of_le (hclose y hy z hz) (min_le_right _ _))).le)
        (convex_Icc u v) huI hvI
      rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 huv)] at this
      convert this using 2; ring
    set D := √((v - u) ^ 2 + (f v - f u) ^ 2) with hDdef
    have hE : √((v - u) ^ 2 + ((v - u) * f' y) ^ 2) = (v - u) * √(1 + f' y ^ 2) := by
      rw [show (v - u) ^ 2 + ((v - u) * f' y) ^ 2 = (v - u) ^ 2 * (1 + f' y ^ 2) by ring,
        Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq (sub_nonneg.2 huv)]
    set E := (v - u) * √(1 + f' y ^ 2) with hEdef
    have hDE : |D - E| ≤ η * (v - u) := by
      rw [abs_sub_le_iff]
      constructor
      · have := sa_sqrt_le (v - u) (f v - f u) ((v - u) * f' y)
        rw [hE] at this; linarith
      · have := sa_sqrt_le (v - u) ((v - u) * f' y) (f v - f u)
        rw [hE, abs_sub_comm] at this; linarith
    have hfu : |f u - f y| ≤ ρ := by
      rw [← Real.dist_eq]
      exact (hu1 u hu y hyab (lt_of_lt_of_le (hclose y hy u huI) (min_le_left _ _))).le
    have hfv : |f v - f y| ≤ ρ := by
      rw [← Real.dist_eq]
      exact (hu1 v hv y hyab (lt_of_lt_of_le (hclose y hy v hvI) (min_le_left _ _))).le
    have hfy : |f y| ≤ |M| := hM0 y hyab
    have hD0 : 0 ≤ D := Real.sqrt_nonneg _
    have hexp : π * (f u + f v) * D - (v - u) * (2 * π * f y * √(1 + f' y ^ 2)) =
        π * ((f u - f y + (f v - f y)) * D + 2 * f y * (D - E)) := by
      rw [hEdef]; ring
    rw [hexp, abs_mul, abs_of_pos Real.pi_pos]
    have hA : |(f u - f y + (f v - f y)) * D| ≤ 2 * ρ * ((1 + |M'|) * (v - u)) := by
      rw [abs_mul, abs_of_nonneg hD0]
      have : |f u - f y + (f v - f y)| ≤ 2 * ρ := (abs_add_le _ _).trans (by linarith)
      exact mul_le_mul this hD hD0 (by positivity)
    have hB : |2 * f y * (D - E)| ≤ 2 * |M| * (η * (v - u)) := by
      rw [abs_mul, abs_mul, abs_two]
      exact mul_le_mul (by linarith) hDE (abs_nonneg _) (by positivity)
    have hsum := (abs_add_le _ _).trans (add_le_add hA hB)
    have hh : 0 ≤ v - u := sub_nonneg.2 huv
    have e1 : π * (2 * ρ * ((1 + |M'|) * (v - u))) = ε / 2 * (v - u) := by
      rw [hρdef]; field_simp; ring
    have e2 : π * (2 * |M| * (η * (v - u))) ≤ ε / 2 * (v - u) := by
      rw [hηdef]
      have : π * (2 * |M| * (ε / (4 * π * (|M| + 1)) * (v - u))) =
          ε / 2 * (v - u) * (|M| / (|M| + 1)) := by field_simp; ring
      rw [this]
      have : |M| / (|M| + 1) ≤ 1 := by
        rw [div_le_one (by positivity)]; linarith
      have : 0 ≤ ε / 2 * (v - u) := by positivity
      nlinarith
    calc π * |(f u - f y + (f v - f y)) * D + 2 * f y * (D - E)|
        ≤ π * (2 * ρ * ((1 + |M'|) * (v - u)) + 2 * |M| * (η * (v - u))) :=
          mul_le_mul_of_nonneg_left hsum Real.pi_pos.le
      _ ≤ ε * (v - u) := by rw [mul_add]; linarith
  -- integrate the pointwise comparison
  rcases eq_or_lt_of_le huv with heq | hlt
  · subst heq; simp
  have hpos : 0 < v - u := sub_pos.2 hlt
  set T := π * (f u + f v) * √((v - u) ^ 2 + (f v - f u) ^ 2) with hT
  have hgi : IntervalIntegrable (fun x => 2 * π * f x * √(1 + f' x ^ 2)) MeasureTheory.volume u v :=
    (hgc.mono hsub).intervalIntegrable_of_Icc huv
  have : T - ∫ x in u..v, 2 * π * f x * √(1 + f' x ^ 2) =
      ∫ x in u..v, (T / (v - u) - 2 * π * f x * √(1 + f' x ^ 2)) := by
    rw [intervalIntegral.integral_sub intervalIntegrable_const hgi, intervalIntegral.integral_const,
      smul_eq_mul]
    field_simp
  rw [this]
  have hb := intervalIntegral.norm_integral_le_of_norm_le_const (a := u) (b := v) (C := ε)
    (f := fun x => T / (v - u) - 2 * π * f x * √(1 + f' x ^ 2)) (fun x hx => by
      rw [uIoc_of_le huv] at hx
      have := hpt x (Ioc_subset_Icc_self hx)
      rw [Real.norm_eq_abs]
      rw [show T / (v - u) - 2 * π * f x * √(1 + f' x ^ 2) =
        (T - (v - u) * (2 * π * f x * √(1 + f' x ^ 2))) / (v - u) by field_simp]
      rw [abs_div, abs_of_pos hpos, div_le_iff₀ hpos]
      exact this)
  rw [Real.norm_eq_abs, abs_of_pos hpos] at hb
  exact hb

/-- **Surface area of revolution.** Spin the profile x ↦ f(x), from height a to height b
(a ≤ b), once round the axis. The radius f(x) is never negative there, and the slope f'(x)
exists at every height of [a, b] (one-sided at the ends, so it is finite there) and has no
jumps. Cut [a, b] into n equal height steps and join the profile's points with chords; each
chord, spun, sweeps a frustum band of area π (r₁ + r₂) ℓ, where r₁, r₂ are its edge radii and
ℓ = √(Δx^2 + (r₂ − r₁)^2) is its slant width. As n grows, the total of the n bands tends to
∫ from a to b of 2π f(x) √(1 + f'(x)^2) dx: each ring is circumference times slant length,
and the slant length is the arc-length element, not the step along the axis. -/
theorem frustum_band_sums_tend_to_surface_area_integral (f f' : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hf_nonneg : ∀ x ∈ Icc a b, 0 ≤ f x)
    (hf_deriv : ∀ x ∈ Icc a b, HasDerivWithinAt f (f' x) (Icc a b) x)
    (hf'_cont : ContinuousOn f' (Icc a b)) :
    Tendsto (fun n : ℕ => ∑ i ∈ Finset.range n,
        π * (f (a + i * (b - a) / n) + f (a + (i + 1) * (b - a) / n)) *
          √(((b - a) / n) ^ 2 + (f (a + (i + 1) * (b - a) / n) - f (a + i * (b - a) / n)) ^ 2))
      atTop (𝓝 (∫ x in a..b, 2 * π * f x * √(1 + f' x ^ 2))) := by
  have hfc : ContinuousOn f (Icc a b) := fun x hx => (hf_deriv x hx).continuousWithinAt
  have hgc : ContinuousOn (fun x => 2 * π * f x * √(1 + f' x ^ 2)) (Icc a b) :=
    (continuousOn_const.mul hfc).mul ((continuousOn_const.add (hf'_cont.pow 2)).sqrt)
  rw [Metric.tendsto_atTop]
  intro ε hε
  have hba : 0 ≤ b - a := sub_nonneg.2 hab
  obtain ⟨δ, hδ, hloc⟩ := sa_band_close f f' a b hf_deriv hf'_cont (ε / (b - a + 1))
    (by positivity)
  obtain ⟨N, hN⟩ := exists_nat_gt ((b - a) / δ)
  refine ⟨N + 1, fun n hn => ?_⟩
  have hnpos : (0 : ℝ) < n := by exact_mod_cast (show 0 < n by omega)
  have hNn : (N : ℝ) < n := by exact_mod_cast (show N < n by omega)
  have hstep : (b - a) / n < δ := by
    rw [div_lt_iff₀ hnpos]
    rw [div_lt_iff₀ hδ] at hN
    nlinarith
  set x : ℕ → ℝ := fun k => a + k * (b - a) / n with hxdef
  have hx_mem : ∀ k ≤ n, x k ∈ Icc a b := by
    intro k hk
    have hk' : (k : ℝ) ≤ n := by exact_mod_cast hk
    have h0 : 0 ≤ (k : ℝ) * (b - a) / n := by positivity
    have h1 : (k : ℝ) * (b - a) / n ≤ b - a := by
      rw [div_le_iff₀ hnpos]; nlinarith
    exact ⟨by simp only [hxdef]; linarith, by simp only [hxdef]; linarith⟩
  have hx0 : x 0 = a := by simp [hxdef]
  have hxn : x n = b := by simp only [hxdef]; field_simp; ring
  have hxs : ∀ k : ℕ, x (k + 1) = a + ((k : ℝ) + 1) * (b - a) / n := by
    intro k; simp only [hxdef]; push_cast; ring
  have hint : (∫ x in a..b, 2 * π * f x * √(1 + f' x ^ 2)) =
      ∑ k ∈ Finset.range n, ∫ y in x k..x (k + 1), 2 * π * f y * √(1 + f' y ^ 2) := by
    rw [intervalIntegral.sum_integral_adjacent_intervals, hx0, hxn]
    intro k hk
    have hmono : x k ≤ x (k + 1) := by
      rw [hxs]; simp only [hxdef]
      have : (0 : ℝ) ≤ (b - a) / n := by positivity
      have e : ((k : ℝ) + 1) * (b - a) / n = (k : ℝ) * (b - a) / n + (b - a) / n := by ring
      rw [e]; linarith
    exact (hgc.mono (Icc_subset_Icc (hx_mem k hk.le).1 (hx_mem (k + 1) hk).2)).intervalIntegrable_of_Icc
      hmono
  rw [Real.dist_eq, hint, ← Finset.sum_sub_distrib]
  have hterm : ∀ k ∈ Finset.range n,
      |π * (f (a + k * (b - a) / n) + f (a + (k + 1) * (b - a) / n)) *
          √(((b - a) / n) ^ 2 + (f (a + (k + 1) * (b - a) / n) - f (a + k * (b - a) / n)) ^ 2) -
        ∫ y in x k..x (k + 1), 2 * π * f y * √(1 + f' y ^ 2)| ≤ ε / (b - a + 1) * ((b - a) / n) := by
    intro k hk
    rw [Finset.mem_range] at hk
    have hu := hx_mem k hk.le
    have hv := hx_mem (k + 1) hk
    rw [hxs] at hv ⊢
    have hvu : a + ((k : ℝ) + 1) * (b - a) / n - (a + k * (b - a) / n) = (b - a) / n := by
      field_simp; ring
    have := hloc _ _ hu hv (by linarith [hvu, show (0 : ℝ) ≤ (b - a) / n by positivity])
      (by rw [hvu]; exact hstep)
    rw [hvu] at this
    exact this
  calc |∑ k ∈ Finset.range n, _| ≤ ∑ k ∈ Finset.range n, |_| := Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ k ∈ Finset.range n, ε / (b - a + 1) * ((b - a) / n) := Finset.sum_le_sum hterm
    _ = ε / (b - a + 1) * (b - a) := by
      rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]; field_simp
    _ < ε := by
      rw [div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]; nlinarith

/-- **On a ball, radius times slant factor is the ball's radius.** Stand a ball of radius R > 0
on its lowest point; at height x its profile has radius f(x) = √(2Rx − x^2) (for the card's
bowl, R = 4 and f(x) = √(8x − x^2)). At every height strictly between the bottom and the top,
the radius times the slant factor √(1 + f'(x)^2) equals R. -/
theorem ball_radius_times_slant_factor_eq_radius (R x : ℝ) (hR : 0 < R)
    (hx : x ∈ Ioo 0 (2 * R)) :
    √(2 * R * x - x ^ 2) * √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2) = R := by
  obtain ⟨hx0, hx1⟩ := hx
  have hq : 0 < 2 * R * x - x ^ 2 := by nlinarith
  have h1 : HasDerivAt (fun t => 2 * R * t - t ^ 2) (2 * R - 2 * x) x := by
    have := ((hasDerivAt_id' x).const_mul (2 * R)).sub (hasDerivAt_pow 2 x)
    convert this using 1
    norm_num
  rw [(h1.sqrt hq.ne').deriv]
  have hs : 0 < √(2 * R * x - x ^ 2) := Real.sqrt_pos.mpr hq
  have hss : √(2 * R * x - x ^ 2) ^ 2 = 2 * R * x - x ^ 2 := Real.sq_sqrt hq.le
  rw [← Real.sqrt_mul hq.le, div_pow, mul_pow, hss,
    show (2 * R * x - x ^ 2) * (1 + (2 * R - 2 * x) ^ 2 / (2 ^ 2 * (2 * R * x - x ^ 2))) = R ^ 2 by
      field_simp; ring]
  exact Real.sqrt_sq hR.le

/-- **Archimedes: a slice of a ball has the area of the tube round it.** For a ball of radius
R > 0 with profile f(x) = √(2Rx − x^2), the spun area between heights a and b, with
0 ≤ a ≤ b ≤ 2R, is ∫ from a to b of 2π f(x) √(1 + f'(x)^2) dx = 2πR(b − a): the slice's height
times the circumference 2πR. The steep ends cost nothing, so the whole ball, a = 0 and b = 2R,
has area 4πR^2. -/
theorem ball_slice_area_eq_two_pi_R_h (R a b : ℝ) (hR : 0 < R) (ha : 0 ≤ a) (hab : a ≤ b)
    (hb : b ≤ 2 * R) :
    (∫ x in a..b, 2 * π * √(2 * R * x - x ^ 2) *
        √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2)) = 2 * π * R * (b - a) ∧
      (∫ x in (0 : ℝ)..2 * R, 2 * π * √(2 * R * x - x ^ 2) *
        √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2)) = 4 * π * R ^ 2 := by
  have key : ∀ a b : ℝ, a ≤ b → 0 ≤ a → b ≤ 2 * R →
      (∫ x in a..b, 2 * π * √(2 * R * x - x ^ 2) *
        √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2)) = 2 * π * R * (b - a) := by
    intro a b hab ha hb
    rw [intervalIntegral.integral_congr_Ioo_of_le hab (g := fun _ => 2 * π * R)]
    · simp [intervalIntegral.integral_const]; ring
    · intro x hx
      simp only
      rw [mul_assoc, ball_radius_times_slant_factor_eq_radius R x hR
        ⟨by linarith [hx.1], by linarith [hx.2]⟩]
  refine ⟨key a b hab ha hb, ?_⟩
  rw [key 0 (2 * R) (by linarith) le_rfl le_rfl]; ring

/-! The card's exact worked numbers. -/

-- The bowl's radius squared at x = 3: 8 · 3 − 3^2 = 15, so the radius is √15 ≈ 3.872983 cm.
example : 8 * 3 - 3 ^ 2 = 15 := by decide
-- The slope there is (4 − 3)/√15, so the slant factor squared is 1 + 1/15 = 16/15.
example : 1 + (4 - 3 : ℚ) ^ 2 / 15 = 16 / 15 := by norm_num
-- Radius times slant factor, squared: 15 · 16/15 = 16 = 4^2, so the product is 4 cm.
example : (15 : ℚ) * (16 / 15) = 4 ^ 2 := by norm_num
-- Step 4's algebra: f^2 + (4 − x)^2 = 8x − x^2 + 16 − 8x + x^2 = 16 at every height.
example : ∀ x : ℝ, (8 * x - x ^ 2) + (4 - x) ^ 2 = 16 := by intro x; ring
-- The bowl: 2π · 4 · 6 = 48π cm^2 (about 150.796447).
example : 2 * π * 4 * 6 = 48 * π := by ring
-- The whole ball, h = 2R = 8: 2π · 4 · 8 = 64π = 4π · 4^2 cm^2 (about 201.061930).
example : 2 * π * 4 * 8 = 4 * π * 4 ^ 2 := by ring
-- The band from x = 1 to x = 2: radii squared 8 − 1 = 7 and 16 − 4 = 12 (radii 2.6458 and
-- 3.4641 cm); the rim at x = 6 has radius squared 48 − 36 = 12 too (3.464102 cm).
example : 8 * 1 - 1 ^ 2 = 7 ∧ 8 * 2 - 2 ^ 2 = 12 ∧ 8 * 6 - 6 ^ 2 = 12 := by decide
-- That centimetre of bowl truly has 2π · 4 · 1 = 8π cm^2 (about 25.1327).
example : 2 * π * 4 * (2 - 1) = 8 * π := by ring
-- Step 1's algebra: if similar triangles give r₂(L − ℓ) = r₁L, the frustum's area
-- πr₂L − πr₁(L − ℓ) (big cone minus tip) equals π(r₁ + r₂)ℓ.
example : ∀ r₁ r₂ L ℓ : ℝ, r₂ * (L - ℓ) = r₁ * L →
    π * r₂ * L - π * r₁ * (L - ℓ) = π * (r₁ + r₂) * ℓ := by
  intro r₁ r₂ L ℓ h; linear_combination π * h
-- The signed radius x − 3 on [0, 6]: its antiderivative x^2/2 − 3x gives 18 − 18 = 0, so the
-- two cones cancel; each cone's slant squared is 3^2 + 3^2 = 18.
example : ((6 : ℚ) ^ 2 / 2 - 3 * 6) - (0 ^ 2 / 2 - 3 * 0) = 0 ∧ (3 : ℚ) ^ 2 + 3 ^ 2 = 18 := by
  norm_num
-- Silver: 48π cm^2 times 0.002 = 1/500 cm is 12π/125 cm^3 (about 0.301593).
example : 48 * π * (1 / 500) = 12 * π / 125 := by ring

#print axioms sa_sqrt_le
#print axioms sa_band_close
#print axioms frustum_band_sums_tend_to_surface_area_integral
#print axioms ball_radius_times_slant_factor_eq_radius
#print axioms ball_slice_area_eq_two_pi_R_h
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'sa_sqrt_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'sa_band_close' depends on axioms: [propext, Classical.choice, Quot.sound]
'frustum_band_sums_tend_to_surface_area_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'ball_radius_times_slant_factor_eq_radius' depends on axioms: [propext, Classical.choice, Quot.sound]
'ball_slice_area_eq_two_pi_R_h' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Guess first:** raise the bowl height `H` from 6 to 8, the whole ball. The area becomes 201.061930 cm^2, since $2\pi R h$ grows in step with $h$.
> - **Guess first:** change 6000 to 6 in the first assert. The chords sit inside the curve, so the total is 147.982130 cm^2, short by 2.81, and the assert fails.
> - **Guess first:** add `slant=False` to the band call in the first assert. It then meets 127.04 cm^2 and fails.

---

## The usual mistake

> [!warning]
> **Multiplying circumference by the height step.** The volume formula does that with a disc, so it feels natural. But a disc's thickness lies along the axis; a wall's width lies along the wall. On the bowl this gives 127.04 cm^2, well short, and the error grows with the slope.
>
> - **Squaring the radius out of habit.** $\pi f(x)^2$ sums slices of volume: 226.19 cm^3 for this bowl, a quantity in different units.
> - **Adding lids.** The formula measures the spun wall only; a closed container adds its end discs separately.

---

## Where you meet it in real life

- **Plating and paint.** A turned object's coating is its spun area times a thickness: 3.1637 g of silver for this bowl.
- **Heat loss.** A flask loses heat through its skin, so its area sets the rate; its capacity is [Volumes](03-volumes-by-slices-and-shells.md).
- **Pappus's rule.** A spun area equals the profile's length times the distance its centre of mass travels: [Centre of mass](05-centre-of-mass-and-pappus.md).

> **Say it back**
> A spun curve's area is a stack of thin rings, each circumference times width along the wall, and that width is the height step times the arc-length factor. On a ball, radius times slant factor is the ball's radius, so a slice has area 2 pi R h.

---

## What this builds on

- [Arc length](02-arc-length.md): the slant factor $\sqrt{1 + f'(x)^2}$ and the chord-to-limit argument used here for the wall's width.

## Where this goes next

- [Surface integrals](../09-Vector%20Calculus/05-surface-integrals-and-flux.md): measures any curved sheet patch by patch, with the spin angle as one grid number.
- Surface area, a planned card on the Differential geometry wing: area for any curved surface, not only one spun round an axis.

A spun surface is round about its axis; how to measure a curved sheet with no axis at all, such as a car's bonnet, is what adding small flat patches answers.

---

## Sources

Verified 2026-09-27: every link below resolves to the publisher's page.

- Strang, Gilbert, Edwin Herman, et al. *Calculus Volume 2*, OpenStax, 2016. [Section 2.4, Arc Length of a Curve and Surface Area](https://openstax.org/books/calculus-volume-2/pages/2-4-arc-length-of-a-curve-and-surface-area). The frustum derivation and the integral.
- O'Connor, J. J., and E. F. Robertson. "Archimedes." MacTutor History of Mathematics, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Archimedes/). *On the Sphere and Cylinder*, and the result he wanted on his tomb.
