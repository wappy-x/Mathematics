# Area: half base times height, and why cutting and rearranging never changes it

[Syllabus](../../../SYLLABUS.md) → [Geometry and trig](../README.md) → [Angles, Triangles and Congruence](../README.md#s01) → Area

---

## General Overview

A garden bed is a triangle with sides 7 m, 8 m and 9 m. Topsoil is sold by the square metre, so the question is how much ground lies inside the edges. Adding the edges gives 24 m of edging board, a different question.

The school rule is half the base times the height. Take the 9 m side as the base. The height is the distance from the far corner to that side, meeting it square on. Here it is about 5.96 m, so the bed holds about 26.83 square metres.

Heron of Alexandria, in the first century, gave a rule that needs only the three sides, and it gives the same answer. Parallelograms (opposite sides parallel) and trapezoids (one pair of sides parallel) follow from one idea: slice a shape, move the pieces without stretching them, and they cover as much ground as before.

**Area counts unit squares, and cutting and moving pieces never changes that count, so a parallelogram is a rectangle in disguise, a triangle is half a parallelogram, and Heron's rule is the same triangle with its height worked out from the sides.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, resting on two starting rules for area: shapes that match exactly have equal area, and pieces that do not overlap add.

### The picture: the bed, drawn to scale

<p align="center"><img src="../figures/area-of-triangles-and-polygons-1.svg" alt="The 7-8-9 m garden bed with its 9 m side as base and its height dropped square on to it" width="420"></p>

Scale 1 m = 30 units. Corner A sits at the origin, B 9 m along, and C above a point 5.33 m from A. The dashed line is the height; the small square marks its right angle with the base.

---

## The formula

Corners are A, B and C, and each side takes the small letter of the corner it faces: side a faces A. K is the area, c the side taken as base, and h the height to it. The sign √ asks which positive number times itself gives what is under it.

$$K = \tfrac12\, c\, h$$

**Read it aloud:** a triangle's area is half of one side times the height measured square on to that side.

A parallelogram with base $c$ and height $h$ has area $c\,h$. A trapezoid whose parallel sides are $u$ and $v$, a height $h$ apart, has area

$$K = \frac{u + v}{2}\, h$$

**Read it aloud:** average the two parallel sides, then multiply by the distance between them.

Heron's rule needs only the sides. First halve the perimeter:

$$s = \frac{a + b + c}{2}, \qquad K = \sqrt{s\,(s - a)(s - b)(s - c)}$$

**Read it aloud:** take half the perimeter, multiply it by what is left after taking away each side in turn, and take the square root.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $K$ | the area, in square metres | 26.832816 | — |
| $a$, $b$, $c$ | the three sides; $c$ is the one chosen as base | 7, 8, 9 m | rises until the angle it faces is square, then falls |
| $h$ | the height: square-on distance from the far corner to the base's line | 5.962848 m | grows in step: double it, double the area |
| $s$ | the semiperimeter: half the distance round | 12 m | — |
| $x$ | distance along the base from A to the foot of the height (where it meets the base) | 5.333333 m | slides the corner; area unchanged |
| $u$, $v$ | the two parallel sides of a trapezoid | 9 m and 4.5 m | grows by half the height per metre |

### When it holds

- **Flat ground.** On a curved surface, such as a large patch of the Earth, other rules apply.
- **Height means square on.** A sloping side is not a height: the 8 m side gives 36 square metres, not 26.83.
- **The sides can close.** Each side must be shorter than the other two together ([Triangles](02-triangle-angle-sum-and-inequality.md)). For 2, 3 and 6 m, Heron's product, s(s − a)(s − b)(s − c), comes out at −24.0625, which has no square root: there is no such triangle. At exact equality, as in 2, 3 and 5 m, the triangle lies flat and the area is 0.
- **Pieces cover once.** A polygon's area is the sum of its pieces only when they do not overlap and leave no gaps.
- **Measured sides carry error.** In a very thin triangle one of s − a, s − b, s − c is a small gap between large measured numbers, so a small tape error moves the answer a lot.

---

## Why it works

### Step 0: area is a count that cutting cannot change

A rectangle 3 m by 2 m holds six one-metre squares: width times height. For lengths that are not whole metres, finer squares count, and the rule stands.

Two rules carry the rest. Shapes that match exactly when one is laid on the other ([Congruent triangles](03-congruent-triangles.md)) have equal area. Pieces that do not overlap add. So cutting a shape up and sliding or turning the pieces keeps the total.

### Step 1: a parallelogram is a rectangle with one piece moved

Turn a copy of the bed half a turn and lay it against side BC, as drawn below. Together they make the parallelogram A, B, D, C: base 9 m, height h.

Cut down the dashed height from C. Slide the left piece 9 m right and it fills the gap under D exactly, because the two slanted ends are parallel and equally long.

The result is a rectangle 9 m wide and h tall. Nothing was stretched, so the parallelogram's area is $c\,h$: 53.665631 square metres.

### The picture: two beds make a parallelogram, one cut makes a rectangle

<p align="center"><img src="../figures/area-of-triangles-and-polygons-2.svg" alt="The bed and a half-turned copy form a parallelogram; cutting off its left end and moving it 9 m right gives a rectangle" width="420"></p>

Scale 1 m = 20 units. Shaded: the bed. The copy is the bed turned half a turn, sharing side BC. The dashed outline on the right is where the cut-off piece lands.

### Step 2: a triangle is half a parallelogram

The parallelogram's diagonal BC splits it into two triangles with the same three sides, so they match exactly and have equal area. Each is half: $K = \tfrac12\,c\,h$, or 26.832816 square metres.

Any side can be the base, with its own height: 7.666519 m to side a, 6.708204 m to b, 5.962848 m to c. Each product is 53.665631, twice the area.

### Step 3: a trapezoid is half a parallelogram too

Two copies of any trapezoid, one turned half a turn, make a parallelogram with base $u + v$ and height $h$. Halve it: $K = \tfrac12 (u + v)\,h$.

Run a hedge across the bed halfway up, parallel to the 9 m side; by [Similar triangles](04-similar-triangles-and-scale.md) it is 4.5 m long. The trapezoid below holds 20.124612 square metres, the triangle above 6.708204. Together, 26.832816: the whole bed, as Step 0 demands.

Any straight-edged plot splits the same way: draw lines between corners that stay inside it, cutting it into triangles, and add their areas.

### Step 4: the height, from the three sides

Lay side c along the ground with A at the start. Call the foot of the height $x$ metres from A. Two right-angled triangles stand either side of the height, and [Pythagoras](05-pythagoras-and-its-converse.md) gives one equation for each:

b^2 = x^2 + h^2 and a^2 = (c − x)^2 + h^2.

Subtract the second from the first. The h^2 cancels and leaves x = (b^2 + c^2 − a^2) / (2c). For the bed, (64 + 81 − 49) / 18 = 5.333333 m. Then h^2 = 64 − x^2, and h = 5.962848 m.

If the angle at A is wide, x comes out negative and the foot lies outside the triangle; the equations still hold.

### Step 5: put that height into half base times height

Square the area and multiply by 16: 16K^2 = 4c^2h^2. Replace h^2 from Step 4 and only sides remain. The result factors into four brackets, each twice one of s, s − a, s − b, s − c; the twos cancel the 16, and the square root is Heron's rule.

For the bed: the brackets are 24, 10, 8 and 6, whose product is 11520, which is 16 × 720. The area is √720, the 26.832816 of Step 2.

<details>
<summary>Detailed proof</summary>

From Step 4, 2cx = b^2 + c^2 − a^2 and h^2 = b^2 − x^2. So

16K^2 = 4c^2h^2 = 4b^2c^2 − (2cx)^2 = (2bc)^2 − (b^2 + c^2 − a^2)^2.

A difference of two squares, P^2 − Q^2, factors as (P − Q)(P + Q):

16K^2 = (2bc − b^2 − c^2 + a^2)(2bc + b^2 + c^2 − a^2) = (a^2 − (b − c)^2)((b + c)^2 − a^2).

Factor each bracket again:

16K^2 = (a − b + c)(a + b − c)(b + c − a)(b + c + a).

With 2s = a + b + c, the four brackets are 2(s − b), 2(s − c), 2(s − a) and 2s. Their product is 16 s(s − a)(s − b)(s − c). Divide by 16 and take the positive root. The triangle inequality makes all four brackets positive, so the root exists.

</details>

A second road needs no area formula. Slice the bed into thin upright strips, treat each as a rectangle, and add: 10 strips give 26.838914, 100 give 26.833563, 1000 give 26.832834, closing in on 26.832816.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Half the perimeter | (7 + 8 + 9) / 2 | s = 12 |
| What is left after each side | 12 − 7, 12 − 8, 12 − 9 | 5, 4, 3 |
| Heron's product | 12 × 5 × 4 × 3 | 720 |
| Heron's area | √720 | **26.832816** |
| Foot of the height | (64 + 81 − 49) / 18 | x = 5.333333 |
| Height | √(64 − x^2) | h = 5.962848 |
| Half base times height | 9 × 5.962848 / 2 | **26.832816** |

The bed needs about 26.83 square metres of topsoil.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| The 8 m side used as height | 9 × 8 / 2 = 36 | A sloping side is longer than the square-on height |
| The perimeter 24 used as s | 312.921715 | s is half the perimeter |
| Trapezoid: bases added, not averaged | 40.249224 for the 20.124612 strip | The two copies make a parallelogram; the half was dropped |
| Sides doubled, area doubled | Predict 53.67; truth 107.331263 | Base and height both double, so area multiplies by four |

The code prints all four.

---

## Code, from first principles, and it actually runs

Nothing is imported. The square root is Newton's rule (average a guess with the number divided by the guess, and repeat).

Road one is Heron. Road two puts the bed on a grid, finds the height by Pythagoras, and adds 1000 thin strips. A third check finds each side's height with the dot product (multiply matching grid coordinates and add). A second case, sides 4, 5 and 8 m, has its foot outside the triangle.

### Python

```python
# The 7-8-9 m bed. Road one: Heron. Road two: grid, Pythagoras, thin strips.

def root(v):                               # square root by Newton's rule
    r = max(v, 1.0)
    for _ in range(60):
        r = (r + v / r) / 2
    return r

def product(a, b, c):                      # Heron's product s(s-a)(s-b)(s-c)
    s = (a + b + c) / 2
    return s * (s - a) * (s - b) * (s - c)
def heron(a, b, c):
    return root(product(a, b, c))

def corner(a, b, c):                       # C above base AB, with A at (0, 0)
    x = (b * b + c * c - a * a) / (2 * c)  # from b^2 = x^2 + h^2, a^2 = (c - x)^2 + h^2
    return x, root(b * b - x * x)

def strips(c, x, h, n):                    # n strips, each read at its middle
    w, total = c / n, 0.0
    for i in range(n):
        t = (i + 0.5) * w
        total += w * (h * t / x if t < x else h * (c - t) / (c - x))
    return total

def height_to(p, q, r):                    # distance from p to the line through q, r
    dx, dy = r[0] - q[0], r[1] - q[1]
    k = ((p[0] - q[0]) * dx + (p[1] - q[1]) * dy) / (dx * dx + dy * dy)
    fx, fy = q[0] + k * dx, q[1] + k * dy  # the foot, found with the dot product
    return root((p[0] - fx) ** 2 + (p[1] - fy) ** 2)

a, b, c = 7, 8, 9
K, (x, h) = heron(a, b, c), corner(a, b, c)
A, B, C = (0.0, 0.0), (float(c), 0.0), (x, h)
ha, hb = height_to(A, B, C), height_to(B, C, A)
f16 = (a + b + c) * (-a + b + c) * (a - b + c) * (a + b - c)
g16 = 2 * (a * a * b * b + b * b * c * c + c * c * a * a) - (a ** 4 + b ** 4 + c ** 4)
trap, top, (x2, h2) = (c + c / 2) / 2 * (h / 2), (c / 2) * (h / 2) / 2, corner(8, 5, 4)
print(f"sides 7, 8, 9; s = {(a + b + c) / 2:.0f}; s(s-a)(s-b)(s-c) = {product(a, b, c):.0f}")
print(f"road one, Heron: area = {K:.6f}")
print(f"road two, grid: foot at x = {x:.6f}, height h = {h:.6f}, 9 x h / 2 = {c * h / 2:.6f}")
print("10, 100, 1000 strips: " + ", ".join(f"{strips(c, x, h, n):.6f}" for n in (10, 100, 1000)))
print(f"heights to a, b, c: {ha:.6f}, {hb:.6f}, {h:.6f}")
print(f"base x height, three ways: {a * ha:.6f}, {b * hb:.6f}, {c * h:.6f}")
print(f"16 x area^2: factored {f16}, expanded {g16}")
print(f"two beds, parallelogram: {c * h:.6f}")
print(f"cut halfway up: trapezoid {trap:.6f} + top {top:.6f} = {trap + top:.6f}")
print(f"second case 4, 5, 8: Heron {heron(4, 5, 8):.6f}; foot x = {x2:.6f}, h = {h2:.6f}, 4 x h / 2 = {4 * h2 / 2:.6f}")
print(f"mistake, slope as height: 9 x 8 / 2 = {c * b / 2:.6f}")
print(f"mistake, perimeter for s: {root(24 * 17 * 16 * 15):.6f}")
print(f"mistake, sum of bases for trapezoid: {(c + c / 2) * (h / 2):.6f}")
print(f"doubled sides 14, 16, 18: {heron(14, 16, 18):.6f}, {heron(14, 16, 18) / K:.6f} x the bed")
print(f"sides 2, 3, 6: s(s-a)(s-b)(s-c) = {product(2, 3, 6):.4f}, no triangle")
print(f"figure 1, 1 m = 30: A (45, 215), B (315, 215), C ({45 + 30 * x:.2f}, {215 - 30 * h:.2f})")
print(f"figure 2, 1 m = 20: A (40, 200), B (220, 200), D ({220 + 20 * x:.2f}, {200 - 20 * h:.2f}), C ({40 + 20 * x:.2f}, {200 - 20 * h:.2f})")
assert abs(strips(c, x, h, 1000) - K) < 1e-4             # strips against Heron
assert abs(16 * K * K - g16) < 1e-6                      # Heron against the expanded form
assert all(abs(v - 2 * K) < 1e-9 for v in (a * ha, b * hb, c * h))  # any base
assert abs(4 * h2 / 2 - heron(4, 5, 8)) < 1e-9           # obtuse case, two roads
print("ALL CHECKS PASS")
```

**Ran 2026-09-24 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
sides 7, 8, 9; s = 12; s(s-a)(s-b)(s-c) = 720
road one, Heron: area = 26.832816
road two, grid: foot at x = 5.333333, height h = 5.962848, 9 x h / 2 = 26.832816
10, 100, 1000 strips: 26.838914, 26.833563, 26.832834
heights to a, b, c: 7.666519, 6.708204, 5.962848
base x height, three ways: 53.665631, 53.665631, 53.665631
16 x area^2: factored 11520, expanded 11520
two beds, parallelogram: 53.665631
cut halfway up: trapezoid 20.124612 + top 6.708204 = 26.832816
second case 4, 5, 8: Heron 8.181534; foot x = -2.875000, h = 4.090767, 4 x h / 2 = 8.181534
mistake, slope as height: 9 x 8 / 2 = 36.000000
mistake, perimeter for s: 312.921715
mistake, sum of bases for trapezoid: 40.249224
doubled sides 14, 16, 18: 107.331263, 4.000000 x the bed
sides 2, 3, 6: s(s-a)(s-b)(s-c) = -24.0625, no triangle
figure 1, 1 m = 30: A (45, 215), B (315, 215), C (205.00, 36.11)
figure 2, 1 m = 20: A (40, 200), B (220, 200), D (326.67, 80.74), C (146.67, 80.74)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Area of the 7-8-9 m bed, std only.  Road one: Heron, from the sides.
// Road two: the bed on a grid, its height by Pythagoras, then thin strips.

fn root(v: f64) -> f64 {                   // square root by Newton's rule
    let mut r = v.max(1.0);
    for _ in 0..60 {
        r = (r + v / r) / 2.0;
    }
    r
}

fn product(a: f64, b: f64, c: f64) -> f64 { // Heron's product s(s-a)(s-b)(s-c)
    let s = (a + b + c) / 2.0;
    s * (s - a) * (s - b) * (s - c)
}

fn heron(a: f64, b: f64, c: f64) -> f64 {
    root(product(a, b, c))
}

fn corner(a: f64, b: f64, c: f64) -> (f64, f64) { // C above base AB, A at (0, 0)
    let x = (b * b + c * c - a * a) / (2.0 * c);
    (x, root(b * b - x * x))
}

fn strips(c: f64, x: f64, h: f64, n: usize) -> f64 { // n strips, read at the middle
    let w = c / n as f64;
    (0..n).map(|i| {
        let t = (i as f64 + 0.5) * w;
        w * if t < x { h * t / x } else { h * (c - t) / (c - x) }
    }).sum()
}

fn height_to(p: (f64, f64), q: (f64, f64), r: (f64, f64)) -> f64 {
    let (dx, dy) = (r.0 - q.0, r.1 - q.1);
    let k = ((p.0 - q.0) * dx + (p.1 - q.1) * dy) / (dx * dx + dy * dy);
    let (fx, fy) = (q.0 + k * dx, q.1 + k * dy); // the foot, by the dot product
    root((p.0 - fx).powi(2) + (p.1 - fy).powi(2))
}

fn main() {
    let (a, b, c) = (7.0_f64, 8.0_f64, 9.0_f64);
    let (k, (x, h)) = (heron(a, b, c), corner(a, b, c));
    let (pa, pb, pc) = ((0.0, 0.0), (c, 0.0), (x, h));
    let (ha, hb) = (height_to(pa, pb, pc), height_to(pb, pc, pa));
    let (ai, bi, ci) = (7i64, 8i64, 9i64);
    let f16 = (ai + bi + ci) * (-ai + bi + ci) * (ai - bi + ci) * (ai + bi - ci);
    let g16 = 2 * (ai * ai * bi * bi + bi * bi * ci * ci + ci * ci * ai * ai) - (ai.pow(4) + bi.pow(4) + ci.pow(4));
    let (trap, top) = ((c + c / 2.0) / 2.0 * (h / 2.0), (c / 2.0) * (h / 2.0) / 2.0);
    let (x2, h2) = corner(8.0, 5.0, 4.0);
    let st: Vec<String> = [10, 100, 1000].iter().map(|&n| format!("{:.6}", strips(c, x, h, n))).collect();
    println!("sides 7, 8, 9; s = {:.0}; s(s-a)(s-b)(s-c) = {:.0}", (a + b + c) / 2.0, product(a, b, c));
    println!("road one, Heron: area = {:.6}", k);
    println!("road two, grid: foot at x = {:.6}, height h = {:.6}, 9 x h / 2 = {:.6}", x, h, c * h / 2.0);
    println!("10, 100, 1000 strips: {}", st.join(", "));
    println!("heights to a, b, c: {:.6}, {:.6}, {:.6}", ha, hb, h);
    println!("base x height, three ways: {:.6}, {:.6}, {:.6}", a * ha, b * hb, c * h);
    println!("16 x area^2: factored {}, expanded {}", f16, g16);
    println!("two beds, parallelogram: {:.6}", c * h);
    println!("cut halfway up: trapezoid {:.6} + top {:.6} = {:.6}", trap, top, trap + top);
    println!("second case 4, 5, 8: Heron {:.6}; foot x = {:.6}, h = {:.6}, 4 x h / 2 = {:.6}", heron(4.0, 5.0, 8.0), x2, h2, 4.0 * h2 / 2.0);
    println!("mistake, slope as height: 9 x 8 / 2 = {:.6}", c * b / 2.0);
    println!("mistake, perimeter for s: {:.6}", root(24.0 * 17.0 * 16.0 * 15.0));
    println!("mistake, sum of bases for trapezoid: {:.6}", (c + c / 2.0) * (h / 2.0));
    println!("doubled sides 14, 16, 18: {:.6}, {:.6} x the bed", heron(14.0, 16.0, 18.0), heron(14.0, 16.0, 18.0) / k);
    println!("sides 2, 3, 6: s(s-a)(s-b)(s-c) = {:.4}, no triangle", product(2.0, 3.0, 6.0));
    println!("figure 1, 1 m = 30: A (45, 215), B (315, 215), C ({:.2}, {:.2})", 45.0 + 30.0 * x, 215.0 - 30.0 * h);
    println!("figure 2, 1 m = 20: A (40, 200), B (220, 200), D ({:.2}, {:.2}), C ({:.2}, {:.2})", 220.0 + 20.0 * x, 200.0 - 20.0 * h, 40.0 + 20.0 * x, 200.0 - 20.0 * h);
    assert!((strips(c, x, h, 1000) - k).abs() < 1e-4);          // strips against Heron
    assert!((16.0 * k * k - g16 as f64).abs() < 1e-6);          // Heron against the expanded form
    assert!([a * ha, b * hb, c * h].iter().all(|v| (v - 2.0 * k).abs() < 1e-9)); // any base
    assert!((4.0 * h2 / 2.0 - heron(4.0, 5.0, 8.0)).abs() < 1e-9); // obtuse case, two roads
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
sides 7, 8, 9; s = 12; s(s-a)(s-b)(s-c) = 720
road one, Heron: area = 26.832816
road two, grid: foot at x = 5.333333, height h = 5.962848, 9 x h / 2 = 26.832816
10, 100, 1000 strips: 26.838914, 26.833563, 26.832834
heights to a, b, c: 7.666519, 6.708204, 5.962848
base x height, three ways: 53.665631, 53.665631, 53.665631
16 x area^2: factored 11520, expanded 11520
two beds, parallelogram: 53.665631
cut halfway up: trapezoid 20.124612 + top 6.708204 = 26.832816
second case 4, 5, 8: Heron 8.181534; foot x = -2.875000, h = 4.090767, 4 x h / 2 = 8.181534
mistake, slope as height: 9 x 8 / 2 = 36.000000
mistake, perimeter for s: 312.921715
mistake, sum of bases for trapezoid: 40.249224
doubled sides 14, 16, 18: 107.331263, 4.000000 x the bed
sides 2, 3, 6: s(s-a)(s-b)(s-c) = -24.0625, no triangle
figure 1, 1 m = 30: A (45, 215), B (315, 215), C (205.00, 36.11)
figure 2, 1 m = 20: A (40, 200), B (220, 200), D (326.67, 80.74), C (146.67, 80.74)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the three area rules for every triangle and trapezoid on flat ground, not just the 7-8-9 m bed.

- A triangle's area is half of any side times the height measured square on to that side. If the corners lie on one line, both come out at 0.
- A trapezoid's area is the average of its two parallel sides times the distance between them. A parallelogram is the case where they are equal: base times height.
- Heron's rule gives the same triangle area from the three sides alone.
- The bed's numbers come out exactly: s = 12, Heron's product 720, the foot at 16/3 m, and the four brackets' product 11520.
- Sides 2, 3 and 6 m give Heron's product −24.0625, and sides 2, 3 and 5 m give 0.

The decimals, the thin strips, the 4-5-8 m case and the figure positions are left to the Python and Rust checks.

```lean
-- Area: in the flat plane a triangle's area is half a side times the square-on height to that side, a trapezoid's area is the average of its parallel sides times the distance between them, and Heron's rule gives the same triangle area from the three sides alone.
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Combination
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.LinearAlgebra.AffineSpace.AffineSubspace.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Integral

open MeasureTheory

lemma area_dist_sq (x y : EuclideanSpace ℝ (Fin 2)) :
    dist x y ^ 2 = (x 0 - y 0) ^ 2 + (x 1 - y 1) ^ 2 := by
  rw [EuclideanSpace.dist_sq_eq, Fin.sum_univ_two, Real.dist_eq, Real.dist_eq, sq_abs, sq_abs]

lemma area_infDist_mul_dist (P Q R : EuclideanSpace ℝ (Fin 2)) :
    Metric.infDist P (line[ℝ, Q, R] : Set _) * dist Q R =
      |(Q 0 - P 0) * (R 1 - P 1) - (Q 1 - P 1) * (R 0 - P 0)| := by
  by_cases hQR : Q = R
  · subst hQR; rw [mul_comm (Q 1 - P 1)]; simp
  have hd : 0 < dist Q R := dist_pos.2 hQR
  set c := (Q 0 - P 0) * (R 1 - P 1) - (Q 1 - P 1) * (R 0 - P 0) with hc
  have hd2 := area_dist_sq Q R
  have key : ∀ y ∈ (line[ℝ, Q, R] : Set (EuclideanSpace ℝ (Fin 2))),
      |c| ≤ dist P y * dist Q R := by
    intro y hy
    obtain ⟨r, rfl⟩ := (mem_affineSpan_pair_iff_exists_lineMap_eq).1 hy
    have h1 := area_dist_sq P (AffineMap.lineMap Q R r)
    have hpos : 0 ≤ dist P (AffineMap.lineMap Q R r) * dist Q R := by positivity
    rw [← abs_of_nonneg hpos]
    apply sq_le_sq.1
    rw [mul_pow, h1, hd2]
    simp only [AffineMap.lineMap_apply_module, PiLp.add_apply, PiLp.smul_apply, smul_eq_mul, hc]
    nlinarith [sq_nonneg ((P 0 - ((1 - r) * Q 0 + r * R 0)) * (R 0 - Q 0)
      + (P 1 - ((1 - r) * Q 1 + r * R 1)) * (R 1 - Q 1))]
  have hne : (line[ℝ, Q, R] : Set (EuclideanSpace ℝ (Fin 2))).Nonempty :=
    ⟨Q, left_mem_affineSpan_pair ℝ Q R⟩
  apply le_antisymm
  · have hw : (R 0 - Q 0) ^ 2 + (R 1 - Q 1) ^ 2 ≠ 0 := by
      have : 0 < dist Q R ^ 2 := by positivity
      rw [hd2] at this; nlinarith
    set r0 := ((P 0 - Q 0) * (R 0 - Q 0) + (P 1 - Q 1) * (R 1 - Q 1)) /
      ((R 0 - Q 0) ^ 2 + (R 1 - Q 1) ^ 2) with hr0
    have hF : AffineMap.lineMap Q R r0 ∈ (line[ℝ, Q, R] : Set (EuclideanSpace ℝ (Fin 2))) :=
      AffineMap.lineMap_mem_affineSpan_pair r0 Q R
    have hfoot : dist P (AffineMap.lineMap Q R r0) * dist Q R = |c| := by
      have h0 : 0 ≤ dist P (AffineMap.lineMap Q R r0) * dist Q R := by positivity
      rw [← abs_of_nonneg h0]
      apply (sq_eq_sq_iff_abs_eq_abs _ _).1
      rw [mul_pow, area_dist_sq P, hd2]
      simp only [AffineMap.lineMap_apply_module, PiLp.add_apply, PiLp.smul_apply, smul_eq_mul, hc]
      rw [hr0]
      field_simp
      ring
    calc Metric.infDist P _ * dist Q R ≤ dist P (AffineMap.lineMap Q R r0) * dist Q R :=
          mul_le_mul_of_nonneg_right (Metric.infDist_le_dist_of_mem hF) hd.le
      _ = |c| := hfoot
  · have : |c| / dist Q R ≤ Metric.infDist P (line[ℝ, Q, R] : Set _) :=
      (Metric.le_infDist hne).2 (fun y hy => by rw [div_le_iff₀ hd]; exact key y hy)
    rwa [div_le_iff₀ hd] at this

lemma area_region_volume (t : ℝ) (ht : 0 ≤ t) :
    volume {v : EuclideanSpace ℝ (Fin 2) |
      0 ≤ v 0 ∧ v 0 ≤ 1 ∧ 0 ≤ v 1 ∧ v 1 ≤ 1 + (t - 1) * v 0} = ENNReal.ofReal ((1 + t) / 2) := by
  have hmp : MeasurePreserving
      (fun v : EuclideanSpace ℝ (Fin 2) => MeasurableEquiv.finTwoArrow (WithLp.ofLp v))
      volume volume :=
    (volume_preserving_finTwoArrow ℝ).comp (PiLp.volume_preserving_ofLp (Fin 2))
  set S : Set (ℝ × ℝ) := {p | p.1 ∈ Set.Icc 0 1 ∧ p.2 ∈ Set.Icc 0 (1 + (t - 1) * p.1)} with hSdef
  have hS : MeasurableSet S :=
    measurableSet_region_between_cc (f := fun _ => (0 : ℝ)) (g := fun x => 1 + (t - 1) * x)
      (by fun_prop) (by fun_prop) measurableSet_Icc
  have hpre : {v : EuclideanSpace ℝ (Fin 2) |
      0 ≤ v 0 ∧ v 0 ≤ 1 ∧ 0 ≤ v 1 ∧ v 1 ≤ 1 + (t - 1) * v 0} =
      (fun v : EuclideanSpace ℝ (Fin 2) => MeasurableEquiv.finTwoArrow (WithLp.ofLp v)) ⁻¹' S := by
    ext v
    simp [hSdef, MeasurableEquiv.finTwoArrow, and_assoc]
  rw [hpre, hmp.measure_preimage hS.nullMeasurableSet, Measure.volume_eq_prod,
    Measure.prod_apply hS]
  have hslice : ∀ x : ℝ, volume (Prod.mk x ⁻¹' S) =
      Set.indicator (Set.Icc 0 1) (fun x => ENNReal.ofReal (1 + (t - 1) * x)) x := by
    intro x
    by_cases hx : x ∈ Set.Icc (0 : ℝ) 1
    · have : Prod.mk x ⁻¹' S = Set.Icc 0 (1 + (t - 1) * x) := by
        ext y; simp [hSdef, hx.1, hx.2]
      rw [this, Real.volume_Icc, Set.indicator_of_mem hx]
      simp
    · have : Prod.mk x ⁻¹' S = ∅ := by
        ext y
        simp only [Set.mem_preimage, hSdef, Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false,
          not_and]
        intro h; exact absurd h hx
      rw [this, Set.indicator_of_notMem hx]
      simp
  simp_rw [hslice]
  rw [lintegral_indicator measurableSet_Icc, ← ofReal_integral_eq_lintegral_ofReal]
  · congr 1
    rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le zero_le_one]
    rw [intervalIntegral.integral_add intervalIntegrable_const
      (Continuous.intervalIntegrable (by fun_prop) _ _), intervalIntegral.integral_const_mul]
    simp
    ring
  · exact (by fun_prop : Continuous fun x : ℝ => 1 + (t - 1) * x).integrableOn_Icc
  · refine (ae_restrict_iff' measurableSet_Icc).2 (Filter.Eventually.of_forall fun x hx => ?_)
    simp only [Pi.zero_apply]
    nlinarith [hx.1, hx.2]

lemma area_hull_region (t : ℝ) (ht : 0 ≤ t) :
    convexHull ℝ {(0 : EuclideanSpace ℝ (Fin 2)), EuclideanSpace.single 1 1,
      EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1, EuclideanSpace.single 0 1} =
      {v : EuclideanSpace ℝ (Fin 2) |
        0 ≤ v 0 ∧ v 0 ≤ 1 ∧ 0 ≤ v 1 ∧ v 1 ≤ 1 + (t - 1) * v 0} := by
  apply Set.Subset.antisymm
  · apply convexHull_min
    · intro v hv
      simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hv
      rcases hv with rfl | rfl | rfl | rfl <;> simp <;> linarith
    · intro x hx y hy a b ha hb hab
      obtain ⟨hx0, hx1, hx2, hx3⟩ := hx
      obtain ⟨hy0, hy1, hy2, hy3⟩ := hy
      simp only [Set.mem_ofPred_eq, PiLp.add_apply, PiLp.smul_apply, smul_eq_mul]
      refine ⟨by positivity, by nlinarith, by positivity, by nlinarith⟩
  · rintro v ⟨h0, h1, h2, h3⟩
    set x := v 0
    set y := v 1
    set L := 1 + (t - 1) * x with hL
    have hL0 : 0 ≤ L := by nlinarith
    set lam := y / L with hlam
    have hlamL : lam * L = y := by
      by_cases hL' : L = 0
      · have : y = 0 := by linarith
        rw [hlam, hL', this]; simp
      · rw [hlam]; field_simp
    have hlam0 : 0 ≤ lam := div_nonneg h2 hL0
    have hlam1 : lam ≤ 1 := by
      by_cases hL' : L = 0
      · rw [hlam, hL']; simp
      · rw [hlam, div_le_one (lt_of_le_of_ne hL0 (Ne.symm hL'))]; exact h3
    set s : Set (EuclideanSpace ℝ (Fin 2)) := {(0 : EuclideanSpace ℝ (Fin 2)),
      EuclideanSpace.single 1 1, EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1,
      EuclideanSpace.single 0 1} with hs
    have hP : (1 - x) • (0 : EuclideanSpace ℝ (Fin 2)) + x • EuclideanSpace.single 0 1 ∈
        convexHull ℝ s :=
      segment_subset_convexHull (by simp [hs]) (by simp [hs])
        ⟨1 - x, x, by linarith, h0, by ring, rfl⟩
    have hQ : (1 - x) • (EuclideanSpace.single 1 1 : EuclideanSpace ℝ (Fin 2)) +
        x • (EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1) ∈ convexHull ℝ s :=
      segment_subset_convexHull (by simp [hs]) (by simp [hs])
        ⟨1 - x, x, by linarith, h0, by ring, rfl⟩
    have hv := convex_convexHull ℝ s hP hQ (by linarith : 0 ≤ 1 - lam) hlam0 (by ring)
    convert hv using 1
    ext i
    fin_cases i
    · simp [x]; ring
    · simp
      change y = _
      rw [hL] at hlamL
      linear_combination -hlamL

open scoped Pointwise in
lemma area_affine_volume (A U W : EuclideanSpace ℝ (Fin 2)) (t : ℝ) (ht : 0 ≤ t) :
    volume (convexHull ℝ {A, A + W, A + U + t • W, A + U}) =
      ENNReal.ofReal (|U 0 * W 1 - U 1 * W 0| * ((1 + t) / 2)) := by
  let L : EuclideanSpace ℝ (Fin 2) →ₗ[ℝ] EuclideanSpace ℝ (Fin 2) :=
    { toFun := fun v => v 0 • U + v 1 • W
      map_add' := by
        intro x y
        simp only [PiLp.add_apply, add_smul]
        abel
      map_smul' := by
        intro c x
        simp only [PiLp.smul_apply, smul_eq_mul, mul_smul, smul_add, RingHom.id_apply] }
  have hdet : LinearMap.det L = U 0 * W 1 - U 1 * W 0 := by
    rw [← LinearMap.det_toMatrix (EuclideanSpace.basisFun (Fin 2) ℝ).toBasis, Matrix.det_fin_two]
    simp [LinearMap.toMatrix_apply, L]
    ring
  have himg : ({A, A + W, A + U + t • W, A + U} : Set (EuclideanSpace ℝ (Fin 2))) =
      A +ᵥ (L '' {(0 : EuclideanSpace ℝ (Fin 2)), EuclideanSpace.single 1 1,
        EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1, EuclideanSpace.single 0 1}) := by
    simp only [Set.image_insert_eq, Set.image_singleton, Set.vadd_set_insert,
      Set.vadd_set_singleton, vadd_eq_add]
    simp [L, add_assoc]
  rw [himg, convexHull_vadd, ← LinearMap.image_convexHull, area_hull_region t ht, measure_vadd,
    Measure.addHaar_image_linearMap, area_region_volume t ht, hdet,
    ← ENNReal.ofReal_mul (abs_nonneg _)]

#print axioms area_dist_sq
#print axioms area_infDist_mul_dist
#print axioms area_region_volume
#print axioms area_hull_region
#print axioms area_affine_volume

/-- Half base times height. In the flat plane, take any triangle with corners A, B and C, and
take side BC as the base. The height is the square-on distance from the far corner A to the
line through B and C. Then the area inside the triangle is half the base times the height.
No other condition is needed: if the corners lie on one line the triangle is flat and both
sides are 0. -/
theorem triangle_area_eq_half_base_times_height (A B C : EuclideanSpace ℝ (Fin 2)) :
    volume (convexHull ℝ {A, B, C}) =
      ENNReal.ofReal (1 / 2 * dist B C * Metric.infDist A (line[ℝ, B, C] : Set _)) := by
  have h := area_affine_volume A (C - A) (B - A) 0 le_rfl
  have hset : ({A, A + (B - A), A + (C - A) + (0 : ℝ) • (B - A), A + (C - A)} :
      Set (EuclideanSpace ℝ (Fin 2))) = {A, B, C} := by
    simp
  rw [hset] at h
  rw [h, mul_assoc, mul_comm (dist B C), area_infDist_mul_dist]
  congr 1
  simp only [PiLp.sub_apply]
  rw [show (C 0 - A 0) * (B 1 - A 1) - (C 1 - A 1) * (B 0 - A 0) =
    -((B 0 - A 0) * (C 1 - A 1) - (B 1 - A 1) * (C 0 - A 0)) by ring, abs_neg]
  ring

/-- Trapezoid rule. In the flat plane, let A, B, C, D be the corners of a trapezoid in order,
with the top side DC parallel to the base AB and pointing the same way (C − D is a
non-negative multiple of B − A). Its area is the average of the two parallel sides times the
height, the square-on distance between them. A parallelogram is the case DC = AB, giving base
times height. -/
theorem trapezoid_area_eq_average_of_parallel_sides_times_height
    (A B C D : EuclideanSpace ℝ (Fin 2)) (hpar : ∃ t : ℝ, 0 ≤ t ∧ C - D = t • (B - A)) :
    volume (convexHull ℝ {A, B, C, D}) =
      ENNReal.ofReal ((dist A B + dist D C) / 2 * Metric.infDist D (line[ℝ, A, B] : Set _)) := by
  obtain ⟨t, ht, hC⟩ := hpar
  have h := area_affine_volume A (D - A) (B - A) t ht
  have hset : ({A, A + (B - A), A + (D - A) + t • (B - A), A + (D - A)} :
      Set (EuclideanSpace ℝ (Fin 2))) = {A, B, C, D} := by
    have : A + (D - A) + t • (B - A) = C := by
      rw [← hC]; abel
    rw [this]; simp
  rw [hset] at h
  have hDC : dist D C = t * dist A B := by
    rw [dist_comm D C, dist_eq_norm, hC, norm_smul, Real.norm_of_nonneg ht, dist_comm,
      dist_eq_norm]
  rw [h, hDC]
  have key := area_infDist_mul_dist D A B
  congr 1
  calc |(D - A) 0 * (B - A) 1 - (D - A) 1 * (B - A) 0| * ((1 + t) / 2)
      = |(A 0 - D 0) * (B 1 - D 1) - (A 1 - D 1) * (B 0 - D 0)| * ((1 + t) / 2) := by
        simp only [PiLp.sub_apply]
        congr 1
        rw [← abs_neg]
        congr 1
        ring
    _ = Metric.infDist D (line[ℝ, A, B] : Set _) * dist A B * ((1 + t) / 2) := by rw [key]
    _ = (dist A B + t * dist A B) / 2 * Metric.infDist D (line[ℝ, A, B] : Set _) := by ring

/-- Heron's rule. In the flat plane, a triangle with sides a = BC, b = CA, c = AB and half
perimeter s = (a + b + c) / 2 has area √(s(s − a)(s − b)(s − c)). -/
theorem heron_triangle_area (A B C : EuclideanSpace ℝ (Fin 2)) :
    let a := dist B C
    let b := dist C A
    let c := dist A B
    let s := (a + b + c) / 2
    volume (convexHull ℝ {A, B, C}) =
      ENNReal.ofReal (Real.sqrt (s * (s - a) * (s - b) * (s - c))) := by
  intro a b c s
  have h := area_affine_volume A (C - A) (B - A) 0 le_rfl
  have hset : ({A, A + (B - A), A + (C - A) + (0 : ℝ) • (B - A), A + (C - A)} :
      Set (EuclideanSpace ℝ (Fin 2))) = {A, B, C} := by
    simp
  rw [hset] at h
  rw [h]
  congr 1
  set k := (C - A) 0 * (B - A) 1 - (C - A) 1 * (B - A) 0 with hk
  have ha := area_dist_sq B C
  have hb := area_dist_sq C A
  have hc := area_dist_sq A B
  have hprod : s * (s - a) * (s - b) * (s - c) =
      (2 * (a ^ 2) * (b ^ 2) + 2 * (b ^ 2) * (c ^ 2) + 2 * (c ^ 2) * (a ^ 2)
        - (a ^ 2) ^ 2 - (b ^ 2) ^ 2 - (c ^ 2) ^ 2) / 16 := by
    simp only [s]; ring
  have hk2 : s * (s - a) * (s - b) * (s - c) = (|k| * ((1 + 0) / 2)) ^ 2 := by
    rw [hprod, ha, hb, hc, mul_pow, sq_abs, hk]
    simp only [PiLp.sub_apply]
    ring
  rw [hk2, Real.sqrt_sq (by positivity)]

-- The 7-8-9 m bed: half the perimeter is 12, and Heron's product is 12 × 5 × 4 × 3 = 720.
example : ((7 + 8 + 9 : ℚ) / 2) = 12 := by norm_num
example : (12 : ℚ) * (12 - 7) * (12 - 8) * (12 - 9) = 720 := by norm_num

-- Step 4: the foot of the height lies (64 + 81 − 49) / 18 = 16/3 m from A, and h² = 64 − x².
example : ((8 : ℚ) ^ 2 + 9 ^ 2 - 7 ^ 2) / (2 * 9) = 16 / 3 := by norm_num
example : (8 : ℚ) ^ 2 - (16 / 3) ^ 2 = 320 / 9 := by norm_num
-- Half base times height squared matches Heron's product: (9/2)² × 320/9 = 720.
example : ((9 : ℚ) / 2) ^ 2 * (320 / 9) = 720 := by norm_num

-- Step 5: the four brackets are 24, 10, 8 and 6; their product is 11520 = 16 × 720,
-- and the expanded form gives the same number.
example : (7 + 8 + 9 : ℤ) * (-7 + 8 + 9) * (7 - 8 + 9) * (7 + 8 - 9) = 11520 := by norm_num
example : (11520 : ℤ) = 16 * 720 := by norm_num
example : (2 * (7 ^ 2 * 8 ^ 2 + 8 ^ 2 * 9 ^ 2 + 9 ^ 2 * 7 ^ 2) - (7 ^ 4 + 8 ^ 4 + 9 ^ 4) : ℤ)
    = 11520 := by norm_num

-- Sides 2, 3, 6 cannot close: Heron's product is −24.0625 = −385/16.
example : let s : ℚ := (2 + 3 + 6) / 2; s * (s - 2) * (s - 3) * (s - 6) = -385 / 16 := by
  norm_num
-- Sides 2, 3, 5 lie flat: Heron's product is 0.
example : let s : ℚ := (2 + 3 + 5) / 2; s * (s - 2) * (s - 3) * (s - 5) = 0 := by norm_num

-- The usual mistake: the 8 m sloping side used as the height gives 9 × 8 / 2 = 36.
example : (9 : ℚ) * 8 / 2 = 36 := by norm_num
-- A rectangle 3 m by 2 m holds six one-metre squares.
example : (3 : ℕ) * 2 = 6 := by decide

#print axioms triangle_area_eq_half_base_times_height
#print axioms trapezoid_area_eq_average_of_parallel_sides_times_height
#print axioms heron_triangle_area
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'area_dist_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'area_infDist_mul_dist' depends on axioms: [propext, Classical.choice, Quot.sound]
'area_region_volume' depends on axioms: [propext, Classical.choice, Quot.sound]
'area_hull_region' depends on axioms: [propext, Classical.choice, Quot.sound]
'area_affine_volume' depends on axioms: [propext, Classical.choice, Quot.sound]
'triangle_area_eq_half_base_times_height' depends on axioms: [propext, Classical.choice, Quot.sound]
'trapezoid_area_eq_average_of_parallel_sides_times_height' depends on axioms: [propext, Classical.choice, Quot.sound]
'heron_triangle_area' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Sides 14, 16, 18 m.** Guess first. Area 107.331263, four times the bed.
> - **Sides 4, 5, 8 m, on the 4 m base.** Guess where the foot lands. At x = −2.875, outside; height 4.090767, area 8.181534 both ways.
> - **Sides 2, 3, 6 m.** Guess first. Heron's product is −24.0625: no triangle.
> - **Only 10 strips.** Guess the error. 26.838914, a little high, all from the strip under corner C.

---

## The usual mistake

> [!warning]
> **Taking a sloping side as the height.** A slanted side is the longest side of a right-angled triangle whose upright is the true height, so it is always too long. For the bed, 9 × 8 / 2 gives 36 square metres against 26.832816.
>
> - **Forgetting the half:** 53.665631, two beds.

---

## Where you meet it in real life

- **Land survey.** A straight-edged plot is split into triangles, each measured along its sides only, as in Heron's book, the *Metrica*.
- **Materials by the square metre.** Turf, paint and tiles are priced by area, so an L-shaped room is cut into rectangles and a gable end into a rectangle and a triangle.
- **Computer graphics and engineering meshes.** Surfaces are stored as thousands of small triangles, and their areas weight shading, mass and stress.

> **Say it back**
> Area counts unit squares, and cutting and moving pieces never changes the count. A parallelogram is a rectangle with one end piece moved: base times height. Two copies of a triangle make a parallelogram, so a triangle is half base times height. Pythagoras finds the height from the sides, and that gives Heron's rule. The 7-8-9 m bed holds 26.83 square metres either way.

---

## What this builds on

- [Pythagoras](05-pythagoras-and-its-converse.md): the two right-angled triangles that give the height from the sides.

## Where this goes next

- [Small angles](../03-Trigonometry/08-small-angles-and-the-sine-bound.md): compares a triangle's area with a circular slice to pin down how a small angle behaves.
- [Shoelace formula](../07-Points%2C%20Convexity%20and%20Fractals/01-polygon-area-and-orientation.md): the area of any polygon straight from its corners' grid positions, the shoelace formula.

Left open: when only the corners' grid positions are known, is there a rule that needs no heights at all?

---

## Sources

Verified 2026-09-24: every link below resolves to the publisher's page.

- Euclid. *Elements*, Book I, Propositions 35 and 41, ed. D. E. Joyce, Clark University. [Proposition 35](https://mathcs.clarku.edu/~djoyce/java/elements/bookI/propI35.html) and [Proposition 41](https://mathcs.clarku.edu/~djoyce/java/elements/bookI/propI41.html). Parallelograms on one base between the same parallels are equal; a triangle is half such a parallelogram.
- O'Connor, J. J., and E. F. Robertson. "Heron of Alexandria." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Heron/). The Metrica and its areas of triangles and polygons.
- Abramson, Jay, et al. *Precalculus 2e*, section 8.2. OpenStax. [Section page](https://openstax.org/books/precalculus-2e/pages/8-2-non-right-triangles-law-of-cosines). Heron's formula with worked examples.
