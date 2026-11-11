# Green's theorem: circulation round a loop equals curl summed inside

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Vector Calculus](../README.md#s09) → Green's theorem

---

## General Overview

A field is fenced at five posts, in metres east and north of the south-west one: (0, 0), (6, 0), (6, 4), (3, 6), (0, 4). It is a house shape, a 6 m by 4 m rectangle under a roof 2 m high. The shoelace formula turns the five posts into 30 square metres, with no grid laid over the grass ([Shoelace formula](../../05-Geometry%20and%20trig/07-Points%2C%20Convexity%20and%20Fractals/01-polygon-area-and-orientation.md)).

Green's theorem explains why corners suffice. For a smooth field of arrows, such as wind, two totals agree: the work the wind does on one walk round the fence, and the wind's swirl added over every square metre inside, its **curl** ([Divergence and curl](03-divergence-and-curl.md)). For a field with curl 1 everywhere, the walk measures area; on straight fences it is the shoelace sum.

**Once round a closed fence, ground on the left, the work a smooth field does equals its curl added over the region inside; with curl 1, the walk measures area.**

**What kind of fact this is:** a theorem, proved on this card in Why it works for rectangles and for regions between two graphs, which covers the house; the general curved case is cited.

### The picture: the fenced field, to scale

<p align="center"><img src="../figures/greens-theorem.svg" alt="The house-shaped field with posts at (0,0), (6,0), (6,4), (3,6) and (0,4) metres, walked anticlockwise, with the shared line y = 4 dashed and the vortex centre (3,3) marked" width="420"></p>

To scale, 30 units per metre, north up. Chevrons show the anticlockwise walk; the dashed line splits the rectangle, 24 square metres, from the roof, 6. The dot at (3, 3) returns in What breaks.

---

## The formula

Notation first, in words. A field $F$ has east part $P$ and north part $Q$ at the point $x$ metres east, $y$ north. $P_y$, short for $\partial P/\partial y$, is how fast $P$ changes per metre north, a partial derivative ([Partial derivatives](../07-Several%20Variables/01-partial-derivatives.md)); $Q_x$ is how fast $Q$ changes per metre east. The region is $R$, its fence $C$. A circle on the integral sign marks a loop.

$$\oint_C P\,dx + Q\,dy \;=\; \iint_R \left(Q_x - P_y\right) dA$$

**Read it aloud:** the work round the fence, walked with the region on the left, equals the curl added over every small patch inside.

A line integral ([Line integrals of a field](02-line-integrals.md)) equals a double integral ([Double integrals](../08-Multiple%20Integrals/01-double-integrals.md)). The flux form counts flow across the fence, with $n$ the outward direction, length 1, and $ds$ a small length of fence:

$$\oint_C F\cdot n\,ds \;=\; \oint_C P\,dy - Q\,dx \;=\; \iint_R \left(P_x + Q_y\right) dA$$

**Read it aloud:** net flow out equals the divergence, the spreading-out per square metre, added inside.

With the field $(-y/2,\ x/2)$, curl 1, the first form measures area:

$$A \;=\; \tfrac12 \oint_C x\,dy - y\,dx \;=\; \tfrac12 \sum_{\text{fences}} \left(x_i\,y_{i+1} - x_{i+1}\,y_i\right)$$

**Read it aloud:** half the loop integral of x dy minus y dx is the area, one shoelace term per fence.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $F$, $P$, $Q$ | the field, its east and north parts, newtons | wind $(-y^2/20,\ x^2/20)$ | more work round the loop |
| $x$, $y$, $dA$ | metres east and north; a small patch of area | 0 to 6 each way | — |
| $R$, $C$ | the region; its fence, walked with the region on the left | the house; five fences | — |
| $P_y$, $Q_x$ | P's rate per metre north, Q's per metre east | $-y/10$, $x/10$ | — |
| $Q_x - P_y$ | curl: the swirl per square metre | $(x + y)/10$ | more work round the loop |
| $P_x + Q_y$ | divergence: spreading-out per square metre | 1 for $(x/2, y/2)$ | more flow out |
| $n$, $ds$ | outward direction, length 1; a small length of fence | $(1, 0)$ on the east fence | — |
| $A$, $x_i$, $y_i$ | the area; post i's position, in walking order, the first following the last | 30; post 3 is (6, 4) | — |

Curl is newtons per metre; times square metres, it gives joules, like the work on the left.

### When it holds

- **A closed fence that never crosses itself, in finitely many smooth pieces.** Corners are fine; a crossing fence counts some ground negatively.
- **Walked with the region on the left**, anticlockwise for an outer fence. Clockwise, the area is −30 square metres.
- **Continuous partial rates everywhere in the region, fence included.** One bad point breaks it: the vortex in What breaks gives 6.283185 J with curl 0 inside.
- **Every piece of the boundary included.** A region with a pond cut out has two fences: the outer anticlockwise, the pond's clockwise.

---

## Why it works

### Step 0: the fundamental theorem, twice

Adding a rate over an interval gives the change between its ends ([Fundamental theorem of calculus](../04-Integrals/02-fundamental-theorem-of-calculus.md)). On a rectangle, adding $P_y$ northward compares P on the top and bottom fences; adding $Q_x$ eastward compares Q on the right and left. Those four fences are the loop.

### Step 1: the proof on a rectangle

Take the rectangle from $x = a$ to $x = b$ and $y = c$ to $y = d$, walked anticlockwise. The P part sees only east-west motion: the bottom walked east, the top west.

$$\oint P\,dx = \int_a^b P(x, c)\,dx - \int_a^b P(x, d)\,dx = -\int_a^b \big(P(x, d) - P(x, c)\big)\,dx.$$

At each fixed $x$, the fundamental theorem turns the bracket into $P_y$ added from $y = c$ to $y = d$: the P part is minus the double integral of $P_y$. The Q part, right fence north and left fence south, becomes the double integral of $Q_x$ the same way. Adding gives the formula, nothing approximated.

On the 6 m by 4 m rectangle, with wind $P = -y^2/20$, $Q = x^2/20$ newtons, the bottom and left fences give 0 J. The right gives 36/20 N over 4 m, 7.2 J; the top, walked west against −0.8 N, 4.8 J. Inside, $-P_y = y/10$ adds to 4.8 and $Q_x = x/10$ to 7.2: 12 J both ways.

### Step 2: cut and glue

Set the roof triangle on the rectangle. The rectangle walks the dashed fence west for +4.8 J, the triangle east for −4.8 J. They cancel, leaving the outer fence: the rectangle's 12 J plus the triangle's 4.6 J is 16.6 J. A region glued from pieces that obey the theorem obeys it.

<details>
<summary>Detailed proof: a region between two graphs</summary>

Let the region be the points with $a \le x \le b$ and $g(x) \le y \le h(x)$: a continuous floor never above a continuous roof. Vertical sides have $dx = 0$. The floor, walked east, and the roof, walked west, give
$$\oint_C P\,dx = -\int_a^b \big(P(x, h(x)) - P(x, g(x))\big)\,dx = -\int_a^b \int_{g(x)}^{h(x)} P_y(x, y)\,dy\,dx = -\iint_R P_y\,dA,$$
by the fundamental theorem in $y$, which needs $P_y$ continuous. If the region is also the points between a left edge $x = k(y)$ and a right edge $x = m(y)$, the same argument, with the right edge walked north, gives $\oint_C Q\,dy = \iint_R Q_x\,dA$. The house is both kinds: above y = 4 it runs from $x = 3(y - 4)/2$ to $x = 6 - 3(y - 4)/2$.

Other regions are cut into pieces of both kinds; shared cuts cancel as in Step 2. An arbitrary smooth fence needs a limit argument with ε and δ, carried out in Apostol, Volume 2.

</details>

### Step 3: the flux form is the same theorem, turned a quarter

With the region on the left, outward is to the right. A small step $(dx, dy)$ turned a quarter right is $(dy, -dx)$, so the flow out through it is $P\,dy - Q\,dx$. That is the circulation of a turned field with east part −Q and north part P, whose curl is $P_x + Q_y$: the original divergence.

### Step 4: area, and the shoelace formula

The field $(-y/2,\ x/2)$ has $Q_x = 1/2$, $P_y = -1/2$: curl 1, so its loop integral is the area.

From post i to post i + 1, walk $x = x_i + t\,(x_{i+1} - x_i)$, $y = y_i + t\,(y_{i+1} - y_i)$ as a clock t runs from 0 to 1. In $x\,dy - y\,dx$ the terms carrying t cancel, leaving $x_i\,y_{i+1} - x_{i+1}\,y_i$: one fence, one shoelace term. Half of 0 + 24 + 24 + 12 + 0 is 30 square metres. The same integral is the outward flux of $(x/2,\ y/2)$, divergence 1.

A road with no calculus counts whole squares inside the fence: 26 of side 1 m, 29.6 square metres from 10 cm squares, 29.96 from 1 cm squares, within 0.05 of 30.

---

## Worked numbers, by hand

The wind's curl is $Q_x - P_y = x/10 + y/10$.

| Step | Arithmetic | Value |
| --- | --- | --- |
| shoelace terms | 0 − 0, 24 − 0, 36 − 12, 12 − 0, 0 − 0 | 0, 24, 24, 12, 0 |
| area, square metres | half of 60 | **30** |
| work, right fence | 36/20 N over 4 m | 7.2 J |
| work, roof (6, 4) to (3, 6) | step (−3, 2): (76 + 42)/20 | 5.9 J |
| work, roof (3, 6) to (0, 4) | step (−3, −2): (76 − 6)/20 | 3.5 J |
| work, bottom and left | P is 0, then Q is 0 | 0 J |
| work round the fence | 7.2 + 5.9 + 3.5 | **16.6 J** |
| x added inside | area 30 × balance point 3 | 90 |
| y added inside | 24 × 2 + 6 × 14/3 | 76 |
| curl added inside | (90 + 76)/10 | **16.6 J** |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Fence walked clockwise | area −30 square metres | region on the right; every term flips |
| Curl taken as $P_y - Q_x$ | −16.6 J | the east part's northward rate is the one subtracted |
| Vortex centred at (3, 3) | 6.283185 J round, curl 0 inside | undefined at (3, 3): smoothness fails |
| The half dropped | 60 square metres | the curl of $(-y,\ x)$ is 2, not 1 |

The vortex swirls round (3, 3):

$$V = \left(\frac{-(y - 3)}{(x - 3)^2 + (y - 3)^2},\ \frac{x - 3}{(x - 3)^2 + (y - 3)^2}\right).$$

Its curl is 0 wherever defined; difference quotients at 120 inside points confirm it. Yet a lap collects 6.283185 J, which is 2π: at (3, 3) the field has no value.

---

## Code, from first principles, and it actually runs

Both programs write their own Simpson's rule, which estimates an integral from evenly spaced samples. Three roads reach the area: shoelace sum, flux fence by fence, and whole squares counted in integers. Two reach the wind's work: fence by fence, and the hand-worked curl added inside. The vortex meets 2π built by Simpson.

### Python

```python
# Green's theorem -- the check behind the card.  Standard library only; pi is
# built here, not imported.  The plot is a house-shaped field fenced at five
# posts, in metres.  The wind is F = (P, Q) = (-y^2/20, x^2/20), in newtons.
HOUSE = [(0, 0), (6, 0), (6, 4), (3, 6), (0, 4)]
RECT, TRI = [(0, 0), (6, 0), (6, 4), (0, 4)], [(0, 4), (6, 4), (3, 6)]

def simpson(f, a, b, n=200):                  # Simpson's rule, n even
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def loop(field, posts, out=False):            # each fence: P dx + Q dy, or outward P dy - Q dx
    works = []
    for a, b in zip(posts, posts[1:] + posts[:1]):
        dx, dy = b[0] - a[0], b[1] - a[1]
        def push(t):
            p, q = field(a[0] + t * dx, a[1] + t * dy)
            return p * dy - q * dx if out else p * dx + q * dy
        works.append(simpson(push, 0, 1))
    return works

top = lambda x: 4 + 2 * x / 3 if x <= 3 else 4 + 2 * (6 - x) / 3   # the roof line over the house

def count(m):                                 # squares of side 1/m wholly inside, whole numbers only
    roof = lambda i: 12 * m + 2 * min(i, 6 * m - i)          # 3 m times the roof height at x = i/m
    return sum(1 for i in range(6 * m) for j in range(6 * m) if 3 * (j + 1) <= min(roof(i), roof(i + 1))) / m / m

wind = lambda x, y: (-y * y / 20, x * x / 20)
curl = lambda x, y: x / 10 + y / 10           # Q_x - P_y, worked by hand
vortex = lambda x, y: (-(y - 3) / ((x - 3) ** 2 + (y - 3) ** 2), (x - 3) / ((x - 3) ** 2 + (y - 3) ** 2))
terms = [xa * yb - xb * ya for (xa, ya), (xb, yb) in zip(HOUSE, HOUSE[1:] + HOUSE[:1])]
shoelace, flux_area = sum(terms) / 2, sum(loop(lambda x, y: (x / 2, y / 2), HOUSE, out=True))
grid = [(m, count(m)) for m in (1, 10, 100)]
rect, tri, house = loop(wind, RECT), loop(wind, TRI), loop(wind, HOUSE)
minus_py = simpson(lambda x: simpson(lambda y: y / 10, 0, 4, 2), 0, 6, 2)
q_x = simpson(lambda x: simpson(lambda y: x / 10, 0, 4, 2), 0, 6, 2)
over = lambda f: sum(simpson(lambda x: simpson(lambda y: f(x, y), 0, top(x), 2), a, b, 20) for a, b in ((0, 3), (3, 6)))
inside = over(curl)
spin, two_pi = sum(loop(vortex, HOUSE)), 8 * simpson(lambda x: 1 / (1 + x * x), 0, 1)
k, pts = 1e-5, [(0.25 + i / 2, 0.25 + j / 2) for i in range(12) for j in range(12) if 0.25 + j / 2 < top(0.25 + i / 2)]
dq = max(abs(vortex(x + k, y)[1] - vortex(x - k, y)[1] - vortex(x, y + k)[0] + vortex(x, y - k)[0]) / (2 * k) for x, y in pts)
fl = lambda v: ", ".join(f"{x:.6f}" for x in v)
print("figure, 30 units per metre, origin (90, 215): " + " ".join(f"({90 + 30 * x}, {215 - 30 * y})" for x, y in HOUSE) + f"; vortex centre ({90 + 30 * 3}, {215 - 30 * 3})")
print(f"shoelace terms: {terms}; sum {sum(terms)}; area {shoelace:.6f} m2")
print(f"area as outward flux of (x, y)/2, fence by fence: {flux_area:.6f}")
for m, a in grid:
    print(f"area from squares of side 1/{m} wholly inside: {a:.6f}, short by {shoelace - a:.6f}")
print(f"area walked clockwise: {sum(loop(lambda x, y: (x / 2, y / 2), HOUSE[::-1], out=True)):.6f}")
print(f"rectangle, wind work fence by fence: {fl(rect)}; total {sum(rect):.6f} J")
print(f"rectangle inside: -P_y summed {minus_py:.6f} (bottom + top), Q_x summed {q_x:.6f} (right + left)")
print(f"house, wind work fence by fence: {fl(house)}; total {sum(house):.6f} J")
print(f"house inside: x summed {over(lambda x, y: x):.6f}, y summed {over(lambda x, y: y):.6f}, curl (x + y)/10 summed {inside:.6f} J")
print(f"shared fence y = 4: rectangle {rect[2]:.6f}, triangle {tri[0]:.6f}; {sum(rect):.6f} + {sum(tri):.6f} = {sum(rect) + sum(tri):.6f}")
print(f"mistake, curl taken as P_y - Q_x: {-inside:.6f}; mistake, half dropped: {sum(terms):.6f}")
print(f"vortex round (3, 3): circulation {spin:.6f}; 2 pi built by Simpson {two_pi:.6f}")
print(f"vortex curl by difference quotient at {len(pts)} points: largest size {dq:.6f}")
assert abs(flux_area - shoelace) < 1e-9 and 0 < shoelace - grid[-1][1] < 0.05    # three roads to the area
assert abs(sum(house) - inside) < 1e-9                                           # the theorem, on the house
assert abs(rect[0] + rect[2] - minus_py) < 1e-9 and abs(rect[1] + rect[3] - q_x) < 1e-9
assert abs(spin - two_pi) < 1e-9 and dq < 1e-6                                    # the hole breaks it
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
figure, 30 units per metre, origin (90, 215): (90, 215) (270, 215) (270, 95) (180, 35) (90, 95); vortex centre (180, 125)
shoelace terms: [0, 24, 24, 12, 0]; sum 60; area 30.000000 m2
area as outward flux of (x, y)/2, fence by fence: 30.000000
area from squares of side 1/1 wholly inside: 26.000000, short by 4.000000
area from squares of side 1/10 wholly inside: 29.600000, short by 0.400000
area from squares of side 1/100 wholly inside: 29.960000, short by 0.040000
area walked clockwise: -30.000000
rectangle, wind work fence by fence: 0.000000, 7.200000, 4.800000, 0.000000; total 12.000000 J
rectangle inside: -P_y summed 4.800000 (bottom + top), Q_x summed 7.200000 (right + left)
house, wind work fence by fence: 0.000000, 7.200000, 5.900000, 3.500000, 0.000000; total 16.600000 J
house inside: x summed 90.000000, y summed 76.000000, curl (x + y)/10 summed 16.600000 J
shared fence y = 4: rectangle 4.800000, triangle -4.800000; 12.000000 + 4.600000 = 16.600000
mistake, curl taken as P_y - Q_x: -16.600000; mistake, half dropped: 60.000000
vortex round (3, 3): circulation 6.283185; 2 pi built by Simpson 6.283185
vortex curl by difference quotient at 120 points: largest size 0.000000
ALL CHECKS PASS
```

### Rust

Same rows, same labels, built with `rustc --edition 2021 -O`.

```rust
// Green's theorem -- the same check as the Python, in Rust.  No crates; pi is
// built here, not imported.  The plot is a house-shaped field fenced at five
// posts, in metres.  The wind is F = (P, Q) = (-y^2/20, x^2/20), in newtons.
type Field = fn(f64, f64) -> (f64, f64);
const HOUSE: [(i64, i64); 5] = [(0, 0), (6, 0), (6, 4), (3, 6), (0, 4)];

fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {    // Simpson's rule, n even
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}

fn lp(field: Field, posts: &[(f64, f64)], out: bool) -> Vec<f64> {      // P dx + Q dy, or outward P dy - Q dx
    (0..posts.len()).map(|k| {
        let (a, b) = (posts[k], posts[(k + 1) % posts.len()]);
        let (dx, dy) = (b.0 - a.0, b.1 - a.1);
        simpson(|t| { let (p, q) = field(a.0 + t * dx, a.1 + t * dy); if out { p * dy - q * dx } else { p * dx + q * dy } }, 0.0, 1.0, 200)
    }).collect()
}

fn top(x: f64) -> f64 { if x <= 3.0 { 4.0 + 2.0 * x / 3.0 } else { 4.0 + 2.0 * (6.0 - x) / 3.0 } }

fn count(m: i64) -> f64 {                     // squares of side 1/m wholly inside, whole numbers only
    let roof = |i: i64| 12 * m + 2 * i.min(6 * m - i);
    let mut c = 0;
    for i in 0..6 * m { for j in 0..6 * m { if 3 * (j + 1) <= roof(i).min(roof(i + 1)) { c += 1 } } }
    c as f64 / m as f64 / m as f64
}

fn wind(x: f64, y: f64) -> (f64, f64) { (-y * y / 20.0, x * x / 20.0) }
fn curl(x: f64, y: f64) -> f64 { x / 10.0 + y / 10.0 }                  // Q_x - P_y, worked by hand
fn half_pos(x: f64, y: f64) -> (f64, f64) { (x / 2.0, y / 2.0) }
fn vortex(x: f64, y: f64) -> (f64, f64) {
    let r2 = (x - 3.0).powi(2) + (y - 3.0).powi(2);
    (-(y - 3.0) / r2, (x - 3.0) / r2)
}
fn fl(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x + 0.0)).collect::<Vec<_>>().join(", ") }  // + 0.0 prints -0.0 as 0.0
fn sum(v: &[f64]) -> f64 { v.iter().sum() }

fn main() {
    let house: Vec<(f64, f64)> = HOUSE.iter().map(|&(x, y)| (x as f64, y as f64)).collect();
    let rect_p = [(0.0, 0.0), (6.0, 0.0), (6.0, 4.0), (0.0, 4.0)];
    let tri_p = [(0.0, 4.0), (6.0, 4.0), (3.0, 6.0)];
    let terms: Vec<i64> = (0..5).map(|k| { let (a, b) = (HOUSE[k], HOUSE[(k + 1) % 5]); a.0 * b.1 - b.0 * a.1 }).collect();
    let tsum: i64 = terms.iter().sum();
    let shoelace = tsum as f64 / 2.0;
    let flux_area = sum(&lp(half_pos, &house, true));
    let grid: Vec<(i64, f64)> = [1, 10, 100].iter().map(|&m| (m, count(m))).collect();
    let (rect, tri, hs) = (lp(wind, &rect_p, false), lp(wind, &tri_p, false), lp(wind, &house, false));
    let minus_py = simpson(|_x| simpson(|y| y / 10.0, 0.0, 4.0, 2), 0.0, 6.0, 2);
    let q_x = simpson(|x| simpson(|_y| x / 10.0, 0.0, 4.0, 2), 0.0, 6.0, 2);
    let over = |f: &dyn Fn(f64, f64) -> f64| -> f64 { [(0.0, 3.0), (3.0, 6.0)].iter().map(|&(a, b)| simpson(|x| simpson(|y| f(x, y), 0.0, top(x), 2), a, b, 20)).sum() };
    let inside = over(&curl);
    let spin = sum(&lp(vortex, &house, false));
    let two_pi = 8.0 * simpson(|x| 1.0 / (1.0 + x * x), 0.0, 1.0, 200);
    let k = 1e-5;
    let mut pts = Vec::new();
    for i in 0..12 { for j in 0..12 { let (x, y) = (0.25 + i as f64 / 2.0, 0.25 + j as f64 / 2.0); if y < top(x) { pts.push((x, y)) } } }
    let dq = pts.iter().map(|&(x, y)| ((vortex(x + k, y).1 - vortex(x - k, y).1 - vortex(x, y + k).0 + vortex(x, y - k).0) / (2.0 * k)).abs()).fold(0.0, f64::max);
    let fig: Vec<String> = HOUSE.iter().map(|&(x, y)| format!("({}, {})", 90 + 30 * x, 215 - 30 * y)).collect();
    println!("figure, 30 units per metre, origin (90, 215): {}; vortex centre ({}, {})", fig.join(" "), 90 + 30 * 3, 215 - 30 * 3);
    println!("shoelace terms: {:?}; sum {}; area {:.6} m2", terms, tsum, shoelace);
    println!("area as outward flux of (x, y)/2, fence by fence: {:.6}", flux_area);
    for &(m, a) in &grid { println!("area from squares of side 1/{} wholly inside: {:.6}, short by {:.6}", m, a, shoelace - a) }
    let rev: Vec<(f64, f64)> = house.iter().rev().copied().collect();
    println!("area walked clockwise: {:.6}", sum(&lp(half_pos, &rev, true)));
    println!("rectangle, wind work fence by fence: {}; total {:.6} J", fl(&rect), sum(&rect));
    println!("rectangle inside: -P_y summed {:.6} (bottom + top), Q_x summed {:.6} (right + left)", minus_py, q_x);
    println!("house, wind work fence by fence: {}; total {:.6} J", fl(&hs), sum(&hs));
    println!("house inside: x summed {:.6}, y summed {:.6}, curl (x + y)/10 summed {:.6} J", over(&|x, _y| x), over(&|_x, y| y), inside);
    println!("shared fence y = 4: rectangle {:.6}, triangle {:.6}; {:.6} + {:.6} = {:.6}", rect[2], tri[0], sum(&rect), sum(&tri), sum(&rect) + sum(&tri));
    println!("mistake, curl taken as P_y - Q_x: {:.6}; mistake, half dropped: {:.6}", -inside, tsum as f64);
    println!("vortex round (3, 3): circulation {:.6}; 2 pi built by Simpson {:.6}", spin, two_pi);
    println!("vortex curl by difference quotient at {} points: largest size {:.6}", pts.len(), dq);
    assert!((flux_area - shoelace).abs() < 1e-9 && shoelace - grid[2].1 > 0.0 && shoelace - grid[2].1 < 0.05);
    assert!((sum(&hs) - inside).abs() < 1e-9);                            // the theorem, on the house
    assert!((rect[0] + rect[2] - minus_py).abs() < 1e-9 && (rect[1] + rect[3] - q_x).abs() < 1e-9);
    assert!((spin - two_pi).abs() < 1e-9 && dq < 1e-6);                   // the hole breaks it
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
figure, 30 units per metre, origin (90, 215): (90, 215) (270, 215) (270, 95) (180, 35) (90, 95); vortex centre (180, 125)
shoelace terms: [0, 24, 24, 12, 0]; sum 60; area 30.000000 m2
area as outward flux of (x, y)/2, fence by fence: 30.000000
area from squares of side 1/1 wholly inside: 26.000000, short by 4.000000
area from squares of side 1/10 wholly inside: 29.600000, short by 0.400000
area from squares of side 1/100 wholly inside: 29.960000, short by 0.040000
area walked clockwise: -30.000000
rectangle, wind work fence by fence: 0.000000, 7.200000, 4.800000, 0.000000; total 12.000000 J
rectangle inside: -P_y summed 4.800000 (bottom + top), Q_x summed 7.200000 (right + left)
house, wind work fence by fence: 0.000000, 7.200000, 5.900000, 3.500000, 0.000000; total 16.600000 J
house inside: x summed 90.000000, y summed 76.000000, curl (x + y)/10 summed 16.600000 J
shared fence y = 4: rectangle 4.800000, triangle -4.800000; 12.000000 + 4.600000 = 16.600000
mistake, curl taken as P_y - Q_x: -16.600000; mistake, half dropped: 60.000000
vortex round (3, 3): circulation 6.283185; 2 pi built by Simpson 6.283185
vortex curl by difference quotient at 120 points: largest size 0.000000
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Green's theorem on every rectangle, the P part on every region between two graphs, and the shoelace term on every straight fence.

- Take any rectangle and any field whose partial rates are continuous everywhere in it, fence included. Walked once anticlockwise, the work round the fence equals the curl added over the rectangle.
- Take a region between a continuous floor and a roof never below it, with P and $P_y$ continuous there. P added along the floor, minus along the roof, equals minus $P_y$ added inside.
- Take a straight fence from one post to the next. Along it, the field $(-y/2,\ x/2)$ does work of exactly half the shoelace term $x_i\,y_{i+1} - x_{i+1}\,y_i$.
- The hand arithmetic holds exactly: shoelace terms 0, 24, 24, 12, 0, the 30 square metres, −30 clockwise, and 60 with the half dropped.
- The wind's arithmetic holds exactly: 12 J round the rectangle, 16.6 J round the house and inside, and the shared fence y = 4 cancelling.

The flux form, square counts, vortex and Simpson decimals are left to the Python and Rust checks; nothing checks curved fences in general.

<details>
<summary>The Lean proof, 239 lines</summary>

```lean
-- Green's theorem: the work a smooth field P dx + Q dy does once anticlockwise round a rectangle equals its curl Q_x − P_y added over the rectangle, the P part of that holds on any region between two graphs, and each straight fence adds one shoelace term to the area integral ½(x dy − y dx).
import Mathlib.MeasureTheory.Integral.CurveIntegral.Basic
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Tactic.NormNum

open Set MeasureTheory

/-- The 1-form `P dx + Q dy` on the plane: at the point `z`, a small step `v` collects
`P z · v.1 + Q z · v.2`. -/
noncomputable def workForm (P Q : ℝ × ℝ → ℝ) (z : ℝ × ℝ) : ℝ × ℝ →L[ℝ] ℝ :=
  P z • ContinuousLinearMap.fst ℝ ℝ ℝ + Q z • ContinuousLinearMap.snd ℝ ℝ ℝ

/-- The fence of the rectangle `[a, b] × [c, d]`, walked once anticlockwise (region on the
left): bottom east, right side north, top west, left side south, back to the start. -/
noncomputable def rectangleLoop (a b c d : ℝ) : Path ((a, c) : ℝ × ℝ) (a, c) :=
  (Path.segment (a, c) (b, c)).trans
    ((Path.segment (b, c) (b, d)).trans
      ((Path.segment (b, d) (a, d)).trans (Path.segment (a, d) (a, c))))

lemma workForm_seg_horiz (P Q : ℝ × ℝ → ℝ) (x0 x1 y t : ℝ) :
    workForm P Q (AffineMap.lineMap ((x0, y) : ℝ × ℝ) (x1, y) t) ((x1, y) - (x0, y)) =
      (x1 - x0) • P (x0 + (x1 - x0) * t, y) := by
  simp [workForm, AffineMap.lineMap_apply_module']
  have e : t * (x1 - x0) + x0 = x0 + (x1 - x0) * t := by ring
  rw [e, mul_comm]

lemma workForm_seg_vert (P Q : ℝ × ℝ → ℝ) (x y0 y1 t : ℝ) :
    workForm P Q (AffineMap.lineMap ((x, y0) : ℝ × ℝ) (x, y1) t) ((x, y1) - (x, y0)) =
      (y1 - y0) • Q (x, y0 + (y1 - y0) * t) := by
  simp [workForm, AffineMap.lineMap_apply_module']
  have e : t * (y1 - y0) + y0 = y0 + (y1 - y0) * t := by ring
  rw [e, mul_comm]

lemma curveIntegral_seg_horiz (P Q : ℝ × ℝ → ℝ) (x0 x1 y : ℝ) :
    (∫ᶜ z in Path.segment ((x0, y) : ℝ × ℝ) (x1, y), workForm P Q z) = ∫ x in x0..x1, P (x, y) := by
  rw [curveIntegral_segment]
  simp_rw [workForm_seg_horiz, intervalIntegral.integral_smul]
  rw [intervalIntegral.smul_integral_comp_add_mul (f := fun x => P (x, y))]
  simp

lemma curveIntegral_seg_vert (P Q : ℝ × ℝ → ℝ) (x y0 y1 : ℝ) :
    (∫ᶜ z in Path.segment ((x, y0) : ℝ × ℝ) (x, y1), workForm P Q z) = ∫ y in y0..y1, Q (x, y) := by
  rw [curveIntegral_segment]
  simp_rw [workForm_seg_vert, intervalIntegral.integral_smul]
  rw [intervalIntegral.smul_integral_comp_add_mul (f := fun y => Q (x, y))]
  simp

lemma mem_uIcc_affine (x0 x1 t : ℝ) (ht : t ∈ uIcc (0:ℝ) 1) : x0 + (x1 - x0) * t ∈ uIcc x0 x1 := by
  rw [uIcc_of_le zero_le_one] at ht
  obtain ⟨h0, h1⟩ := ht
  rcases le_total x0 x1 with h | h
  · rw [uIcc_of_le h]; constructor <;> nlinarith
  · rw [uIcc_of_ge h]; constructor <;> nlinarith

lemma curveIntegrable_seg_horiz {P Q : ℝ × ℝ → ℝ} {x0 x1 y : ℝ}
    (h : ContinuousOn (fun x => P (x, y)) (uIcc x0 x1)) :
    CurveIntegrable (workForm P Q) (Path.segment ((x0, y) : ℝ × ℝ) (x1, y)) := by
  rw [curveIntegrable_segment]
  simp_rw [workForm_seg_horiz]
  apply ContinuousOn.intervalIntegrable
  simp only [smul_eq_mul]
  exact continuousOn_const.mul (h.comp (by fun_prop : Continuous fun t : ℝ => x0 + (x1 - x0) * t).continuousOn
    (fun t ht => mem_uIcc_affine x0 x1 t ht))

lemma curveIntegrable_seg_vert {P Q : ℝ × ℝ → ℝ} {x y0 y1 : ℝ}
    (h : ContinuousOn (fun y => Q (x, y)) (uIcc y0 y1)) :
    CurveIntegrable (workForm P Q) (Path.segment ((x, y0) : ℝ × ℝ) (x, y1)) := by
  rw [curveIntegrable_segment]
  simp_rw [workForm_seg_vert]
  apply ContinuousOn.intervalIntegrable
  simp only [smul_eq_mul]
  exact continuousOn_const.mul (h.comp (by fun_prop : Continuous fun t : ℝ => y0 + (y1 - y0) * t).continuousOn
    (fun t ht => mem_uIcc_affine y0 y1 t ht))

#print axioms workForm_seg_horiz
#print axioms workForm_seg_vert
#print axioms curveIntegral_seg_horiz
#print axioms curveIntegral_seg_vert
#print axioms mem_uIcc_affine
#print axioms curveIntegrable_seg_horiz
#print axioms curveIntegrable_seg_vert

/-- **Green's theorem on a rectangle.** Take a field with east part `P` and north part `Q` on the
rectangle `R = [a, b] × [c, d]`, and suppose both have continuous rates of change everywhere in
the rectangle, fence included (`P'` and `Q'` are their derivatives, continuous on `R`). Walk the
fence once with the region on the left. The work the field does on the walk, `∮ P dx + Q dy`,
equals the curl `Q_x − P_y` added over the rectangle. Here `Q_x = Q' z (1, 0)` is Q's rate per
step east and `P_y = P' z (0, 1)` is P's rate per step north. -/
theorem circulation_round_rectangle_eq_curl_summed_inside
    {P Q : ℝ × ℝ → ℝ} {P' Q' : ℝ × ℝ → ℝ × ℝ →L[ℝ] ℝ} {a b c d : ℝ}
    (hab : a < b) (hcd : c < d)
    (hP : ∀ z ∈ Icc a b ×ˢ Icc c d, HasFDerivWithinAt P (P' z) (Icc a b ×ˢ Icc c d) z)
    (hQ : ∀ z ∈ Icc a b ×ˢ Icc c d, HasFDerivWithinAt Q (Q' z) (Icc a b ×ˢ Icc c d) z)
    (hP' : ContinuousOn P' (Icc a b ×ˢ Icc c d))
    (hQ' : ContinuousOn Q' (Icc a b ×ˢ Icc c d)) :
    (∫ᶜ z in rectangleLoop a b c d, workForm P Q z) =
      ∫ z in Icc a b ×ˢ Icc c d, (Q' z (1, 0) - P' z (0, 1)) := by
  set R := Icc a b ×ˢ Icc c d with hR
  have hPc : ContinuousOn P R := fun z hz => (hP z hz).continuousWithinAt
  have hQc : ContinuousOn Q R := fun z hz => (hQ z hz).continuousWithinAt
  have hrow : ∀ y ∈ Icc c d, ContinuousOn (fun x => P (x, y)) (uIcc a b) ∧
      ContinuousOn (fun x => P (x, y)) (uIcc b a) := by
    intro y hy
    have : ContinuousOn (fun x => P (x, y)) (Icc a b) :=
      hPc.comp (by fun_prop : Continuous fun x : ℝ => (x, y)).continuousOn
        (fun x hx => ⟨hx, hy⟩)
    exact ⟨by rwa [uIcc_of_le hab.le], by rwa [uIcc_of_ge hab.le]⟩
  have hcol : ∀ x ∈ Icc a b, ContinuousOn (fun y => Q (x, y)) (uIcc c d) ∧
      ContinuousOn (fun y => Q (x, y)) (uIcc d c) := by
    intro x hx
    have : ContinuousOn (fun y => Q (x, y)) (Icc c d) :=
      hQc.comp (by fun_prop : Continuous fun y : ℝ => (x, y)).continuousOn
        (fun y hy => ⟨hx, hy⟩)
    exact ⟨by rwa [uIcc_of_le hcd.le], by rwa [uIcc_of_ge hcd.le]⟩
  have ha : a ∈ Icc a b := left_mem_Icc.2 hab.le
  have hb : b ∈ Icc a b := right_mem_Icc.2 hab.le
  have hc : c ∈ Icc c d := left_mem_Icc.2 hcd.le
  have hd : d ∈ Icc c d := right_mem_Icc.2 hcd.le
  have i1 := curveIntegrable_seg_horiz (Q := Q) (hrow c hc).1
  have i2 := curveIntegrable_seg_vert (P := P) (hcol b hb).1
  have i3 := curveIntegrable_seg_horiz (Q := Q) (hrow d hd).2
  have i4 := curveIntegrable_seg_vert (P := P) (hcol a ha).2
  unfold rectangleLoop
  rw [curveIntegral_trans i1 (i2.trans (i3.trans i4)), curveIntegral_trans i2 (i3.trans i4),
    curveIntegral_trans i3 i4, curveIntegral_seg_horiz, curveIntegral_seg_vert,
    curveIntegral_seg_horiz, curveIntegral_seg_vert]
  have hle : ((a, c) : ℝ × ℝ) ≤ (b, d) := ⟨hab.le, hcd.le⟩
  have hIcc : Icc ((a, c) : ℝ × ℝ) (b, d) = R := by rw [Icc_prod_eq]
  have hnhds : ∀ x ∈ Ioo a b ×ˢ Ioo c d, R ∈ nhds x := fun x hx =>
    prod_mem_nhds (Icc_mem_nhds hx.1.1 hx.1.2) (Icc_mem_nhds hx.2.1 hx.2.2)
  have key := integral_divergence_prod_Icc_of_hasFDerivAt_of_le Q (fun z => -P z) Q'
    (fun z => -P' z) (a, c) (b, d) hle (by rwa [hIcc]) (by rw [hIcc]; exact hPc.neg)
    (fun x hx => (hQ x ⟨Ioo_subset_Icc_self hx.1, Ioo_subset_Icc_self hx.2⟩).hasFDerivAt
      (hnhds x hx))
    (fun x hx => ((hP x ⟨Ioo_subset_Icc_self hx.1, Ioo_subset_Icc_self hx.2⟩).hasFDerivAt
      (hnhds x hx)).neg)
    (by
      rw [hIcc]
      refine ContinuousOn.integrableOn_compact (isCompact_Icc.prod isCompact_Icc) ?_
      exact (hQ'.clm_apply continuousOn_const).add (hP'.neg.clm_apply continuousOn_const))
  simp only [hIcc, neg_apply, ← sub_eq_add_neg,
    intervalIntegral.integral_neg] at key
  rw [key, intervalIntegral.integral_symm a b, intervalIntegral.integral_symm c d]
  ring

/-- **The P part on a region between two graphs.** Let the region be the points `(x, y)` with
`a ≤ x ≤ b` and `g(x) ≤ y ≤ h(x)`, where the floor `g` and the roof `h` are continuous and the
floor is never above the roof. Suppose `P` is continuous on the region and has a continuous
northward rate `P_y` there, fence included. Walking the fence with the region on the left, the
vertical sides add nothing to `∮ P dx`; the floor, walked east, and the roof, walked west, give
`∫ P(x, g x) dx − ∫ P(x, h x) dx`. That equals minus `P_y` added over the region. -/
theorem p_part_between_two_graphs_eq_minus_py_summed
    {P Py : ℝ × ℝ → ℝ} {g h : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hg : ContinuousOn g (Icc a b)) (hh : ContinuousOn h (Icc a b))
    (hgh : ∀ x ∈ Icc a b, g x ≤ h x)
    (hP : ContinuousOn P {z | z.1 ∈ Icc a b ∧ z.2 ∈ Icc (g z.1) (h z.1)})
    (hPy : ∀ x ∈ Icc a b, ∀ y ∈ Icc (g x) (h x),
      HasDerivWithinAt (fun t => P (x, t)) (Py (x, y)) (Icc (g x) (h x)) y)
    (hPyc : ContinuousOn Py {z | z.1 ∈ Icc a b ∧ z.2 ∈ Icc (g z.1) (h z.1)}) :
    (∫ x in a..b, P (x, g x)) - (∫ x in a..b, P (x, h x)) =
      -∫ x in a..b, ∫ y in g x..h x, Py (x, y) := by
  have hin : ∀ x ∈ Icc a b, ∫ y in g x..h x, Py (x, y) = P (x, h x) - P (x, g x) := by
    intro x hx
    apply intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le (f := fun t => P (x, t))
      (f' := fun t => Py (x, t)) (hgh x hx)
    · exact hP.comp (by fun_prop : Continuous fun t : ℝ => (x, t)).continuousOn
        (fun t ht => ⟨hx, ht⟩)
    · intro y hy
      exact ((hPy x hx y (Ioo_subset_Icc_self hy)).hasDerivAt
        (Icc_mem_nhds hy.1 hy.2)).hasDerivWithinAt
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le (hgh x hx)]
      exact hPyc.comp (by fun_prop : Continuous fun t : ℝ => (x, t)).continuousOn
        (fun t ht => ⟨hx, ht⟩)
  have hcg : ContinuousOn (fun x => P (x, g x)) (Icc a b) :=
    hP.comp ((continuousOn_id).prodMk hg) (fun x hx => ⟨hx, le_rfl, hgh x hx⟩)
  have hch : ContinuousOn (fun x => P (x, h x)) (Icc a b) :=
    hP.comp ((continuousOn_id).prodMk hh) (fun x hx => ⟨hx, hgh x hx, le_rfl⟩)
  have e : (∫ x in a..b, ∫ y in g x..h x, Py (x, y)) = ∫ x in a..b, (P (x, h x) - P (x, g x)) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [uIcc_of_le hab] at hx
    exact hin x hx
  rw [e, intervalIntegral.integral_sub (hch.intervalIntegrable_of_Icc hab)
    (hcg.intervalIntegrable_of_Icc hab)]
  ring

/-- **One fence, one shoelace term.** The field `(−y/2, x/2)` has curl 1, so its work round a
loop measures area. Along one straight fence from post `p` to post `q`, its work
`½ ∫ x dy − y dx` is exactly `½ (x_p y_q − x_q y_p)`: the terms that carry the clock cancel. -/
theorem area_form_along_fence_eq_shoelace_term (p q : ℝ × ℝ) :
    (∫ᶜ z in Path.segment p q, workForm (fun w => -w.2 / 2) (fun w => w.1 / 2) z) =
      (p.1 * q.2 - q.1 * p.2) / 2 := by
  rw [curveIntegral_segment]
  have : ∀ t : ℝ, workForm (fun w => -w.2 / 2) (fun w => w.1 / 2) (AffineMap.lineMap p q t) (q - p)
      = (p.1 * q.2 - q.1 * p.2) / 2 := by
    intro t
    simp [workForm, AffineMap.lineMap_apply_module']
    ring
  simp_rw [this]
  simp

/-! ### The card's worked numbers -/

-- The house's posts (0,0), (6,0), (6,4), (3,6), (0,4): shoelace terms 0, 24, 24, 12, 0.
example : ((0:ℚ) * 0 - 6 * 0, (6:ℚ) * 4 - 6 * 0, (6:ℚ) * 6 - 3 * 4, (3:ℚ) * 4 - 0 * 6,
    (0:ℚ) * 0 - 0 * 4) = (0, 24, 24, 12, 0) := by norm_num

-- Half of 0 + 24 + 24 + 12 + 0 is 30 square metres.
example : ((0:ℚ) + 24 + 24 + 12 + 0) / 2 = 30 := by norm_num

-- The rectangle 24 square metres plus the roof triangle 6 square metres (base 6, height 2).
example : (6:ℚ) * 4 + 6 * 2 / 2 = 30 := by norm_num

-- Walked clockwise, every term flips: −30. With the half dropped: 60.
example : -(((0:ℚ) + 24 + 24 + 12 + 0) / 2) = -30 ∧ (0:ℚ) + 24 + 24 + 12 + 0 = 60 := by norm_num

-- Wind (−y²/20, x²/20) on the 6 m by 4 m rectangle: right fence 36/20 N over 4 m is 7.2 J,
-- top fence −0.8 N walked 6 m west is 4.8 J, total 12 J.
example : (36:ℚ) / 20 * 4 = 36 / 5 ∧ -(-(16:ℚ) / 20) * 6 = 24 / 5 ∧
    (36:ℚ) / 5 + 24 / 5 = 12 := by norm_num

-- Wind round the house: 7.2 + 5.9 + 3.5 = 16.6 J, with the roof terms (76 + 42)/20 and (76 − 6)/20.
example : (76 + 42 : ℚ) / 20 = 59 / 10 ∧ (76 - 6 : ℚ) / 20 = 7 / 2 ∧
    (36:ℚ) / 5 + 59 / 10 + 7 / 2 = 83 / 5 := by norm_num

-- Inside the house: x summed 30 × 3 = 90, y summed 24 × 2 + 6 × 14/3 = 76,
-- curl (x + y)/10 summed (90 + 76)/10 = 16.6 J, the same as the walk.
example : (30:ℚ) * 3 = 90 ∧ (24:ℚ) * 2 + 6 * (14 / 3) = 76 ∧ ((90:ℚ) + 76) / 10 = 83 / 5 := by
  norm_num

-- The shared fence y = 4 cancels: rectangle 12 J plus triangle 4.6 J is 16.6 J.
example : (12:ℚ) + 23 / 5 = 83 / 5 ∧ (24:ℚ) / 5 + -(24 / 5) = 0 := by norm_num

#print axioms circulation_round_rectangle_eq_curl_summed_inside
#print axioms p_part_between_two_graphs_eq_minus_py_summed
#print axioms area_form_along_fence_eq_shoelace_term
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'workForm_seg_horiz' depends on axioms: [propext, Classical.choice, Quot.sound]
'workForm_seg_vert' depends on axioms: [propext, Classical.choice, Quot.sound]
'curveIntegral_seg_horiz' depends on axioms: [propext, Classical.choice, Quot.sound]
'curveIntegral_seg_vert' depends on axioms: [propext, Classical.choice, Quot.sound]
'mem_uIcc_affine' depends on axioms: [propext, Classical.choice, Quot.sound]
'curveIntegrable_seg_horiz' depends on axioms: [propext, Classical.choice, Quot.sound]
'curveIntegrable_seg_vert' depends on axioms: [propext, Classical.choice, Quot.sound]
'circulation_round_rectangle_eq_curl_summed_inside' depends on axioms: [propext, Classical.choice, Quot.sound]
'p_part_between_two_graphs_eq_minus_py_summed' depends on axioms: [propext, Classical.choice, Quot.sound]
'area_form_along_fence_eq_shoelace_term' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Move the peak.** Set the fourth post to `(3, 8)`: shoelace and flux give 24 + 12 = 36 square metres, the square count keeps the old roof, and the first assert stops the run.
> - **A curl-free wind.** Make the wind `(y / 20, x / 20)`: curl 1/20 − 1/20 = 0, a lap gives 0 J, the hand-written curl disagrees, and the second assert stops the run.
> - **Move the vortex outside.** Replace every 3 in the vortex by 8: the fence no longer circles the centre, a lap gives 0, and the last assert stops the run.

---

## The usual mistake

> [!warning]
> **Checking the field only along the fence.** The theorem needs the field smooth inside too. The vortex is smooth on the fence, with zero curl wherever defined, yet does 2π J per lap: one bad point at (3, 3).
>
> - **Walking the wrong way.** Clockwise, the area comes out −30 square metres and the wind's work −16.6 J.
> - **Dropping the half.** The field $(-y,\ x)$ has curl 2, so its loop gives 60, twice the area.
> - **Forgetting a pond.** A hole's fence, walked clockwise, is part of the boundary too.

---

## Where you meet it in real life

- **Planimeters and mapping software.** A planimeter, a wheeled arm traced round a map outline, reads area by this theorem; mapping software runs the shoelace sum.
- **Testing for a potential.** Zero curl on a region without holes makes every loop integral zero, as on [Conservative fields](04-conservative-fields-and-potentials.md); the vortex shows why holes matter.

> **Say it back**
> Walk once round a closed fence, ground on the left, adding the field's push along each step. The total equals the curl added inside. On a rectangle this is the fundamental theorem twice; other shapes glue from pieces whose shared fences cancel. Turned a quarter, outflow equals divergence inside. With curl 1 the walk measures area: the shoelace formula.

---

## What this builds on

- [Line integrals of a field](02-line-integrals.md): the work of a field along a directed route, and its sign flip on reversal.
- [Double integrals](../08-Multiple%20Integrals/01-double-integrals.md): adding over a region one slice at a time.
- [Shoelace formula](../../05-Geometry%20and%20trig/07-Points%2C%20Convexity%20and%20Fractals/01-polygon-area-and-orientation.md): the shoelace formula and its sign, which this card derives.

## Where this goes next

- [Stokes' theorem](08-stokes-theorem.md): the same statement for a curved surface and its edge.
- [Cauchy's theorem](../../07-Complex%20analysis/03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/03-cauchys-theorem.md): loop integrals of complex-differentiable functions vanish; Green's theorem gives one proof.
- [Poincare-Bendixson](../../08-Differential%20equations%20and%20dynamics/06-Nonlinear%20Dynamics%20in%20the%20Plane/09-poincare-bendixson-and-bendixsons-criterion.md): the flux form rules out closed orbits where the divergence keeps one sign.
- [Divergence theorem](07-divergence-theorem.md): the flux form in three dimensions, flow out of a closed surface against divergence inside.
- Green, divergence and curl theorems: Green, Stokes and divergence as one theorem about boundaries.

Left open: this fence lies flat on the ground; what does the theorem say when the loop is the rim of a curved sheet, such as a bowl?

---

## Sources

Verified 27 Sep 2026: every link below resolves to the publisher's page.

- OpenStax. *Calculus Volume 3*, section 6.4, "Green's Theorem". [OpenStax](https://openstax.org/books/calculus-volume-3/pages/6-4-greens-theorem). Free; both forms, area, regions with holes.
- Apostol, Tom M. *Calculus, Volume 2*, 2nd ed. Wiley. [Publisher page](https://www.wiley.com/en-us/Calculus%2C+Volume+2%2C+2nd+Edition-p-9781119496762). The proof between two graphs, and the general case.
- O'Connor, J. J., and E. F. Robertson. "George Green." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Green/). A self-taught Nottingham miller; his 1828 essay gave the name.
