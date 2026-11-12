# Triangle centres: centroid, circumcentre and incentre, and the different questions they answer

[Syllabus](../../../SYLLABUS.md) → [Geometry and trig](../README.md) → [Coordinates and Curves](../README.md#s04) → Triangle centres

---

## General Overview

Three farms share one new well. On a map grid in kilometres, farm A sits at (0, 0), B at (8, 0) and C at (2, 6); straight roads join them. Each pays an equal share, so each wants the same length of pipe. Where does the well go?

"The middle of the triangle" is at least three places. Equal pipes need the well at (4.00, 2.00), the **circumcentre**, every pipe 4.47 km. The average of the farm positions, (3.33, 2.00), is the **centroid**, where equal weights on the farms would balance; as a well it gives pipes of 3.89, 5.08 and 4.22 km. The inside point whose nearest road is furthest away, (2.92, 2.10), is the **incentre**, centre of the largest round pond that fits between them, radius 2.10 km.

**The centroid averages the corners, the circumcentre is where the perpendicular bisectors cross (lines through each side's midpoint, square to it), and the incentre is where the angle bisectors cross (lines halving each corner angle); each time two lines fix the point and the third passes through it for free.**

**What kind of fact this is:** a theorem, three times over (each kind of line meets at one point), proved on this card in Why it works; the names are definitions.

### The picture: the farms, the pipe circle and the pond

<p align="center"><img src="../figures/triangle-centres.svg" alt="Three farms at A, B and C joined by roads; the dashed circle through all three is centred at O, the solid circle inside touching all three roads is centred at I, and G is the average of the corners" width="420"></p>

Drawn at 1 km = 22 units. Dashed: the circle through the farms, centre O. Solid: the largest pond, centre I.

---

## The formula

Notation first, in words. Adding points, or multiplying one by a number, acts on each coordinate separately, as with vectors. Bars, as in $\lvert O - A\rvert$, mean the straight-line distance between two points ([Distance and midpoint](01-distance-and-midpoint.md)). Each road takes the small letter of the farm it faces: road $a$ runs from B to C.

$$G = \frac{A + B + C}{3}$$

**Read it aloud:** the centroid is the plain average of the three corners.

$$\lvert O - A\rvert = \lvert O - B\rvert = \lvert O - C\rvert = R$$

**Read it aloud:** the circumcentre is the one point equally far from all three corners, the circumradius away.

$$I = \frac{aA + bB + cC}{a + b + c}, \qquad r = \frac{K}{s}$$

**Read it aloud:** the incentre averages the corners, each counted by the road facing it; its distance to every road, the inradius, is the area over half the perimeter.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $A$, $B$, $C$; $x_A$, $y_A$ | the farms as grid points; A's two coordinates | (0, 0), (8, 0), (2, 6) km | every centre moves |
| $a$, $b$, $c$ | each road's length, named for the farm it faces | 8.49, 6.32, 8.00 km | pulls I towards the farm it faces |
| $G$ | centroid: the average of the corners | (3.33, 2.00) | — |
| $O$ | circumcentre: equally far from the corners | (4.00, 2.00) | — |
| $R$ | the circumradius: the common pipe length | 4.47 km | longer pipes |
| $I$ | incentre: equally far from the roads | (2.92, 2.10) | — |
| $r$ | the inradius: the pond's radius | 2.1044 km | a bigger pond |
| $K$, $s$ | the area, and half the perimeter | 24.00 km^2 and 11.4049 km | K up: bigger pond; s up: smaller |

### When it holds

- **Farms not in a row.** In a row, the perpendicular bisectors are parallel and O does not exist; the code divides by zero.
- **Straight pipes on flat ground.** Pipes along roads or over hills move the fair point.
- **Equal weights, for balance.** Unequal weights need a weighted average.
- **No corner angle over 90°, for O inside.** At exactly 90°, O is the longest road's midpoint. Farms at (0, 0), (8, 0) and (2, 2) make an obtuse triangle (angle C is over 90°) and put O at (4.00, −2.00), outside the triangle.

---

## Why it works

### Step 0: two lines fix the point, and the third comes free

The circumcentre is equally far from three farms, the incentre from three roads. Equal from the first two is one straight line (for roads, the one running inside the triangle); from the first and third, another. Two non-parallel lines cross at exactly one point ([Lines](02-lines-slopes-and-intersections.md)). There the second and third are equal too, both being equal to the first, so the third line passes through the same point.

### Step 1: the centroid sits two-thirds along every median

A **median** runs from a corner to the midpoint of the opposite side. From farm A it reaches (5, 3); two-thirds of the way is (3.33, 2.00). In general A + (2/3)((B + C)/2 − A) works out to (A + B + C)/3, the same from every corner, so G lies on all three medians.

Equal weights at the corners balance at their average position. An evenly thick sheet, cut into strips parallel to road $a$, balances strip by strip on the median from A, so on every median: at G. G also has the least total of squared distances to the corners: 58.67, against 60.00 at O.

<details>
<summary>The algebra behind this, if you want it</summary>

Write each corner's gap from a point P as (P − G) + (G − V), for V in A, B, C, square with the dot product, and add:

$$\lvert P - A\rvert^2 + \lvert P - B\rvert^2 + \lvert P - C\rvert^2 = 3\lvert P - G\rvert^2 + \bigl(\text{the same total at } G\bigr),$$

because the cross terms carry 2(P − G) · ((G − A) + (G − B) + (G − C)), and that sum is 3G − (A + B + C) = 0. The total is smallest at P = G.

</details>

### Step 2: equal distance from two farms is a straight line

A well at (x, y) is equally far from A and B when the squared distances match. Both contain x^2 + y^2, which cancels, leaving

$$2(x_B - x_A)\,x + 2(y_B - y_A)\,y = x_B^2 + y_B^2 - x_A^2 - y_A^2,$$

with $x_A$ and $y_A$ farm A's coordinates, likewise for B. That is a straight line, through the midpoint of road AB at right angles to it: the **perpendicular bisector**.

For the farms, A and B give 16x = 64, so x = 4; A and C give 4x + 12y = 40, so y = 2. The lines cross at O = (4.00, 2.00), where the third bisector passes too. The circle of radius 4.47 km about O, through all three farms, is the **circumcircle**. Nothing keeps O inside the triangle.

### Step 3: equal distance from two roads is an angle bisector

Distance to a road means the shortest distance, at right angles to it. From a point inside the triangle, equally far from the two roads at farm A, drop those two shortest lines. The two right triangles share their hypotenuse and have another side equal, so they are congruent by RHS (right angle, hypotenuse, side; [Congruent triangles](../01-Angles%2C%20Triangles%20and%20Congruence/03-congruent-triangles.md)): the point lies on the **angle bisector**, halving angle A. Run backwards, the same congruence shows every point of that bisector is equally far from both roads. Two bisectors cross at I, the third passes too, and every road is 2.10 km away.

The weights come from the point D where the bisector from A meets road $a$: it splits that road in the ratio c to b.

<details>
<summary>Detailed proof</summary>

**The split.** Triangles ABD and ACD share the height from A to road $a$, so their areas are as BD to DC. D, on the bisector, is equally far from roads $c$ and $b$, so the same areas are as c to b. Hence BD : DC = c : b, D = (bB + cC)/(b + c), and BD = ac/(b + c).

**Where I sits on AD.** The bisector from B crosses AD at I, so by the same fact in triangle ABD, AI : ID = c : ac/(b + c) = (b + c) : a.

**Together.** That point is (aA + (b + c)D)/(a + b + c) = (aA + bB + cC)/(a + b + c).

</details>

### Step 4: the largest pond has radius area over half-perimeter

Join any inside point P to the three farms. Each of the three pieces has area half its road times P's distance to that road ([Area](../01-Angles%2C%20Triangles%20and%20Congruence/06-area-of-triangles-and-polygons.md)). A pond centred at P fits only if every distance is at least its radius, so K is at least radius times s, and no radius exceeds K over s. At I all three distances equal r, so the pond there reaches that ceiling: 2.1044 km.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| road lengths | distance formula | a = 8.49, b = 6.32, c = 8.00 km |
| centroid | ((0 + 8 + 2)/3, (0 + 0 + 6)/3) | **G = (3.33, 2.00)** |
| bisector of A and B | 16x = 64 | x = 4 |
| bisector of A and C | 4x + 12y = 40, with x = 4 | y = 2 |
| equal pipes | distance from (4, 2) to each farm | **R = 4.47 km** |
| area and half-perimeter | 8 × 6 / 2; (8.49 + 6.32 + 8.00)/2 | 24.00 km^2; 11.4049 km |
| incentre | (8.49 × A + 6.32 × B + 8.00 × C) / (a + b + c) | **I = (2.92, 2.10)** |
| largest pond | 24.00 / 11.4049 | **r = 2.1044 km** |

The well goes at (4.00, 2.00), with 4.47 km of pipe to each farm.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Well at the centroid | pipes 3.89, 5.08, 4.22 km | averaging does not equalise distances |
| Pond at the centroid | clearances 2.00, 1.89, 2.53 km | averaging ignores the roads |
| Equal pipes, obtuse farms | O at (4.00, −2.00), 2.00 km outside road AB | O may leave the triangle |
| O as least total | 60.00 at O, 58.67 at G | that is the centroid's job |


---

## Code, from first principles, and it actually runs

Nothing is imported. Each centre is found twice. Route one is the card's formulas, with Cramer's rule (a ratio of cross-multiplied coefficients) solving the bisector equations. Route two is a blind zoom search: score a grid of trial points on the centre's defining property, keep the best, shrink the grid round it, repeat. For the incentre it seeks the point whose nearest road is furthest away, testing the largest-pond claim directly.

### Python

```python
# Triangle centres -- the check behind the card.  Nothing is imported.  Farms in km:
# A = (0, 0), B = (8, 0), C = (2, 6).  Each centre is found twice: by its formula, and by
# a blind zoom search for the point with the centre's defining property.  Then an obtuse case.
def dist(p, q): return ((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2) ** 0.5
def side(p, u, v):                        # distance from p to the road u-v,
    cr = (v[0] - u[0]) * (p[1] - u[1]) - (v[1] - u[1]) * (p[0] - u[0])
    return cr / dist(u, v)                # signed: positive on the triangle's side
def zoom(f, x=0.0, y=0.0, w=40.0):        # route two: best point of a 21 x 21 grid,
    for _ in range(70):                   # then a smaller grid round it, repeated
        pts = [(x + w * i / 10, y + w * j / 10) for i in range(-10, 11) for j in range(-10, 11)]
        x, y = min(pts, key=f)
        w *= 0.7
    return (x, y)
def centres(A, B, C):                     # route one: the formulas on the card
    a, b, c = dist(B, C), dist(C, A), dist(A, B)
    G = ((A[0] + B[0] + C[0]) / 3, (A[1] + B[1] + C[1]) / 3)
    (p1, q1, k1), (p2, q2, k2) = [(2 * (Q[0] - A[0]), 2 * (Q[1] - A[1]),  # perpendicular
             Q[0] ** 2 + Q[1] ** 2 - A[0] ** 2 - A[1] ** 2) for Q in (B, C)]  # bisectors
    det = p1 * q2 - q1 * p2                               # Cramer's rule
    O = ((k1 * q2 - q1 * k2) / det, (p1 * k2 - k1 * p2) / det)
    n = a + b + c
    I = ((a * A[0] + b * B[0] + c * C[0]) / n, (a * A[1] + b * B[1] + c * C[1]) / n)
    return (a, b, c), G, O, I

def pt(p): return f"({p[0]:.2f}, {p[1]:.2f})"
def three(xs): return ", ".join(f"{x:.2f}" for x in xs)

A, B, C = (0.0, 0.0), (8.0, 0.0), (2.0, 6.0)
(a, b, c), G, O, I = centres(A, B, C)
K, s = c * (C[1] - A[1]) / 2, (a + b + c) / 2            # AB is level: height is C's rise
roads = lambda p: [side(p, A, B), side(p, B, C), side(p, C, A)]
sq = lambda p: sum(dist(p, F) ** 2 for F in (A, B, C))
G2 = zoom(sq)                                             # least total squared distance
O2 = zoom(lambda p: (dist(p, A) ** 2 - dist(p, B) ** 2) ** 2 + (dist(p, A) ** 2 - dist(p, C) ** 2) ** 2)
I2 = zoom(lambda p: -min(roads(p)))                       # furthest from the nearest road
print(f"farms A {pt(A)}, B {pt(B)}, C {pt(C)} km; sides a = {a:.2f}, b = {b:.2f}, c = {c:.2f} km")
print(f"area K = {K:.2f} km^2; half-perimeter s = {s:.4f} km; r = K / s = {K / s:.4f} km")
print(f"centroid G: by averaging {pt(G)}; by least total squared distance {pt(G2)}")
print(f"circumcentre O: by two bisectors {pt(O)}; by equal-distance search {pt(O2)}")
print(f"incentre I: by side weights {pt(I)}; by furthest-from-roads search {pt(I2)}")
print(f"O to farms A, B, C: {three(dist(O, F) for F in (A, B, C))} km")
print(f"I to roads AB, BC, CA: {three(roads(I))} km; largest pond found: radius {min(roads(I2)):.4f} km")
print(f"G to farms A, B, C: {three(dist(G, F) for F in (A, B, C))} km")
print(f"G to roads AB, BC, CA: {three(roads(G))} km")
print(f"total squared distance to the farms: at G {sq(G):.2f}, at O {sq(O):.2f}, at I {sq(I):.2f}")
A3, B3, C3 = (0.0, 0.0), (8.0, 0.0), (2.0, 2.0)          # second case: an obtuse layout
_, _, O3, _ = centres(A3, B3, C3)
O4 = zoom(lambda p: (dist(p, A3) ** 2 - dist(p, B3) ** 2) ** 2 + (dist(p, A3) ** 2 - dist(p, C3) ** 2) ** 2)
M3 = ((A3[0] + B3[0]) / 2, (A3[1] + B3[1]) / 2)
print(f"obtuse farms {pt(A3)}, {pt(B3)}, {pt(C3)}: O by bisectors {pt(O3)}, by search {pt(O4)}")
print(f"obtuse: O to farms {three(dist(O3, F) for F in (A3, B3, C3))} km; O to road AB {side(O3, A3, B3):.2f} km")
print(f"obtuse: midpoint of AB {pt(M3)} to farms {three(dist(M3, F) for F in (A3, B3, C3))} km")
svg = lambda p: f"({80 + 22 * p[0]:.2f}, {178 - 22 * p[1]:.2f})"
print(f"figure, 1 km = 22 units: A {svg(A)}, B {svg(B)}, C {svg(C)}, G {svg(G)}, O {svg(O)}, I {svg(I)}, "
      f"R {22 * dist(O, A):.2f}, r {22 * K / s:.2f}")
assert dist(G, G2) < 1e-6 and dist(O, O2) < 1e-6 and dist(I, I2) < 1e-6   # two routes each
assert abs(min(roads(I2)) - K / s) < 1e-6                 # largest pond = area / half-perimeter
assert max(dist(O3, F) for F in (A3, B3, C3)) - min(dist(O3, F) for F in (A3, B3, C3)) < 1e-9
assert dist(O3, O4) < 1e-6 and side(O3, A3, B3) < 0      # obtuse: the well leaves the triangle
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
farms A (0.00, 0.00), B (8.00, 0.00), C (2.00, 6.00) km; sides a = 8.49, b = 6.32, c = 8.00 km
area K = 24.00 km^2; half-perimeter s = 11.4049 km; r = K / s = 2.1044 km
centroid G: by averaging (3.33, 2.00); by least total squared distance (3.33, 2.00)
circumcentre O: by two bisectors (4.00, 2.00); by equal-distance search (4.00, 2.00)
incentre I: by side weights (2.92, 2.10); by furthest-from-roads search (2.92, 2.10)
O to farms A, B, C: 4.47, 4.47, 4.47 km
I to roads AB, BC, CA: 2.10, 2.10, 2.10 km; largest pond found: radius 2.1044 km
G to farms A, B, C: 3.89, 5.08, 4.22 km
G to roads AB, BC, CA: 2.00, 1.89, 2.53 km
total squared distance to the farms: at G 58.67, at O 60.00, at I 59.21
obtuse farms (0.00, 0.00), (8.00, 0.00), (2.00, 2.00): O by bisectors (4.00, -2.00), by search (4.00, -2.00)
obtuse: O to farms 4.47, 4.47, 4.47 km; O to road AB -2.00 km
obtuse: midpoint of AB (4.00, 0.00) to farms 4.00, 4.00, 2.83 km
figure, 1 km = 22 units: A (80.00, 178.00), B (256.00, 178.00), C (124.00, 46.00), G (153.33, 134.00), O (168.00, 134.00), I (144.23, 131.70), R 98.39, r 46.30
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Triangle centres -- the same check as the Python, in Rust.  No crates.  Farms in km:
// A = (0, 0), B = (8, 0), C = (2, 6).  Each centre is found twice: by its formula, and by
// a blind zoom search for the point with the centre's defining property.  Then an obtuse case.
type P = (f64, f64);
fn dist(p: P, q: P) -> f64 { ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt() }
fn side(p: P, u: P, v: P) -> f64 { // distance from p to the road u-v, signed:
    ((v.0 - u.0) * (p.1 - u.1) - (v.1 - u.1) * (p.0 - u.0)) / dist(u, v) // + on the triangle's side
}
fn zoom(f: &dyn Fn(P) -> f64) -> P { // route two: best point of a 21 x 21 grid, then a
    let (mut x, mut y, mut w) = (0.0, 0.0, 40.0); // smaller grid round it, repeated
    for _ in 0..70 {
        let (mut best, mut fb) = ((x, y), f64::INFINITY);
        for i in -10..=10 { for j in -10..=10 {
            let q = (x + w * i as f64 / 10.0, y + w * j as f64 / 10.0);
            let v = f(q);
            if v < fb { best = q; fb = v }
        } }
        (x, y) = best;
        w *= 0.7;
    }
    (x, y)
}
fn centres(a_: P, b_: P, c_: P) -> ((f64, f64, f64), P, P, P) { // route one: the formulas
    let (a, b, c) = (dist(b_, c_), dist(c_, a_), dist(a_, b_));
    let g = ((a_.0 + b_.0 + c_.0) / 3.0, (a_.1 + b_.1 + c_.1) / 3.0);
    let row = |q: P| (2.0 * (q.0 - a_.0), 2.0 * (q.1 - a_.1), q.0 * q.0 + q.1 * q.1 - a_.0 * a_.0 - a_.1 * a_.1);
    let ((p1, q1, k1), (p2, q2, k2)) = (row(b_), row(c_)); // perpendicular bisectors
    let det = p1 * q2 - q1 * p2; // Cramer's rule
    let o = ((k1 * q2 - q1 * k2) / det, (p1 * k2 - k1 * p2) / det);
    let n = a + b + c;
    let i = ((a * a_.0 + b * b_.0 + c * c_.0) / n, (a * a_.1 + b * b_.1 + c * c_.1) / n);
    ((a, b, c), g, o, i)
}
fn pt(p: P) -> String { format!("({:.2}, {:.2})", p.0, p.1) }
fn three(x: [f64; 3]) -> String { format!("{:.2}, {:.2}, {:.2}", x[0], x[1], x[2]) }
fn equal(a_: P, b_: P, c_: P) -> impl Fn(P) -> f64 {
    move |p| (dist(p, a_).powi(2) - dist(p, b_).powi(2)).powi(2) + (dist(p, a_).powi(2) - dist(p, c_).powi(2)).powi(2)
}
fn main() {
    let (fa, fb, fc) = ((0.0, 0.0), (8.0, 0.0), (2.0, 6.0));
    let ((a, b, c), g, o, i) = centres(fa, fb, fc);
    let (k, s) = (c * (fc.1 - fa.1) / 2.0, (a + b + c) / 2.0); // AB is level: height is C's rise
    let roads = |p: P| [side(p, fa, fb), side(p, fb, fc), side(p, fc, fa)];
    let farms = |p: P| [dist(p, fa), dist(p, fb), dist(p, fc)];
    let sq = |p: P| farms(p).iter().map(|d| d * d).sum::<f64>();
    let g2 = zoom(&sq); // least total squared distance
    let o2 = zoom(&equal(fa, fb, fc));
    let i2 = zoom(&|p: P| -roads(p).iter().cloned().fold(f64::INFINITY, f64::min)); // furthest from nearest road
    let r2 = roads(i2).iter().cloned().fold(f64::INFINITY, f64::min);
    println!("farms A {}, B {}, C {} km; sides a = {:.2}, b = {:.2}, c = {:.2} km", pt(fa), pt(fb), pt(fc), a, b, c);
    println!("area K = {:.2} km^2; half-perimeter s = {:.4} km; r = K / s = {:.4} km", k, s, k / s);
    println!("centroid G: by averaging {}; by least total squared distance {}", pt(g), pt(g2));
    println!("circumcentre O: by two bisectors {}; by equal-distance search {}", pt(o), pt(o2));
    println!("incentre I: by side weights {}; by furthest-from-roads search {}", pt(i), pt(i2));
    println!("O to farms A, B, C: {} km", three(farms(o)));
    println!("I to roads AB, BC, CA: {} km; largest pond found: radius {:.4} km", three(roads(i)), r2);
    println!("G to farms A, B, C: {} km", three(farms(g)));
    println!("G to roads AB, BC, CA: {} km", three(roads(g)));
    println!("total squared distance to the farms: at G {:.2}, at O {:.2}, at I {:.2}", sq(g), sq(o), sq(i));
    let (a3, b3, c3) = ((0.0, 0.0), (8.0, 0.0), (2.0, 2.0)); // second case: an obtuse layout
    let (_, _, o3, _) = centres(a3, b3, c3);
    let o4 = zoom(&equal(a3, b3, c3));
    let m3 = ((a3.0 + b3.0) / 2.0, (a3.1 + b3.1) / 2.0);
    let f3 = |p: P| [dist(p, a3), dist(p, b3), dist(p, c3)];
    println!("obtuse farms {}, {}, {}: O by bisectors {}, by search {}", pt(a3), pt(b3), pt(c3), pt(o3), pt(o4));
    println!("obtuse: O to farms {} km; O to road AB {:.2} km", three(f3(o3)), side(o3, a3, b3));
    println!("obtuse: midpoint of AB {} to farms {} km", pt(m3), three(f3(m3)));
    let svg = |p: P| format!("({:.2}, {:.2})", 80.0 + 22.0 * p.0, 178.0 - 22.0 * p.1);
    println!("figure, 1 km = 22 units: A {}, B {}, C {}, G {}, O {}, I {}, R {:.2}, r {:.2}",
             svg(fa), svg(fb), svg(fc), svg(g), svg(o), svg(i), 22.0 * dist(o, fa), 22.0 * k / s);
    assert!(dist(g, g2) < 1e-6 && dist(o, o2) < 1e-6 && dist(i, i2) < 1e-6); // two routes each
    assert!((r2 - k / s).abs() < 1e-6); // largest pond = area / half-perimeter
    let d3 = f3(o3);
    assert!(d3.iter().cloned().fold(f64::MIN, f64::max) - d3.iter().cloned().fold(f64::INFINITY, f64::min) < 1e-9);
    assert!(dist(o3, o4) < 1e-6 && side(o3, a3, b3) < 0.0); // obtuse: the well leaves the triangle
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
farms A (0.00, 0.00), B (8.00, 0.00), C (2.00, 6.00) km; sides a = 8.49, b = 6.32, c = 8.00 km
area K = 24.00 km^2; half-perimeter s = 11.4049 km; r = K / s = 2.1044 km
centroid G: by averaging (3.33, 2.00); by least total squared distance (3.33, 2.00)
circumcentre O: by two bisectors (4.00, 2.00); by equal-distance search (4.00, 2.00)
incentre I: by side weights (2.92, 2.10); by furthest-from-roads search (2.92, 2.10)
O to farms A, B, C: 4.47, 4.47, 4.47 km
I to roads AB, BC, CA: 2.10, 2.10, 2.10 km; largest pond found: radius 2.1044 km
G to farms A, B, C: 3.89, 5.08, 4.22 km
G to roads AB, BC, CA: 2.00, 1.89, 2.53 km
total squared distance to the farms: at G 58.67, at O 60.00, at I 59.21
obtuse farms (0.00, 0.00), (8.00, 0.00), (2.00, 2.00): O by bisectors (4.00, -2.00), by search (4.00, -2.00)
obtuse: O to farms 4.47, 4.47, 4.47 km; O to road AB -2.00 km
obtuse: midpoint of AB (4.00, 0.00) to farms 4.00, 4.00, 2.83 km
figure, 1 km = 22 units: A (80.00, 178.00), B (256.00, 178.00), C (124.00, 46.00), G (153.33, 134.00), O (168.00, 134.00), I (144.23, 131.70), R 98.39, r 46.30
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves each centre's main facts for any farms not in a row, not just the three on the map.

- The three perpendicular bisectors meet at exactly one point: the one point equally far from all three farms.
- The incentre, $I = (aA + bB + cC)/(a + b + c)$, lies inside the triangle and on all three angle bisectors.
- I is K/s from every road, and no point of the triangle is more than K/s from its nearest road. So the largest pond has radius K over s.
- For any three corners, even in a row, G is two-thirds of the way along every median.
- For every point P, the total of squared distances to the corners is $3\lvert P - G\rvert^2$ plus the same total at G. So that total is least at G.
- The farms' numbers come out exactly: G = (10/3, 2), O = (4, 2) with squared distance 20 to each farm, and area 24 km^2. The totals of squared distances are 176/3 at G and 60 at O.
- For the obtuse farms, O = (4, −2) is equally far from all three. A well at the midpoint of road AB needs at most 4 km.

The decimals, the zoom searches, the figure and O falling outside the obtuse triangle are left to the Python and Rust checks.

```lean
-- Triangle centres: for three points not in a row, the perpendicular bisectors meet at exactly one point, the angle bisectors meet at the weighted average of the corners, at distance area over half-perimeter from every side, and the centroid sits two-thirds along every median and has the least total of squared distances.
import Mathlib.Geometry.Euclidean.PerpBisector
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Affine
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Combination
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Geometry.Euclidean.Circumcenter

open EuclideanGeometry AffineSubspace

/-- The plane, with ordinary straight-line distance. -/
local notation "Plane" => EuclideanSpace ℝ (Fin 2)

/-- Twice the signed area of the triangle X Y P. -/
noncomputable def tcCross (X Y P : Plane) : ℝ :=
  (Y 0 - X 0) * (P 1 - X 1) - (Y 1 - X 1) * (P 0 - X 0)

#print axioms tcCross

lemma tc_dist_eq (P Q : Plane) : dist P Q = √((P 0 - Q 0) ^ 2 + (P 1 - Q 1) ^ 2) := by
  rw [EuclideanSpace.dist_eq, Fin.sum_univ_two, Real.dist_eq, Real.dist_eq, sq_abs, sq_abs]

#print axioms tc_dist_eq

lemma tc_dist_sq (P Q : Plane) : dist P Q ^ 2 = (P 0 - Q 0) ^ 2 + (P 1 - Q 1) ^ 2 := by
  rw [tc_dist_eq, Real.sq_sqrt (by positivity)]

#print axioms tc_dist_sq

lemma tc_ext (P Q : Plane) (h0 : P 0 = Q 0) (h1 : P 1 = Q 1) : P = Q := by
  ext i; fin_cases i <;> simp [h0, h1]

#print axioms tc_ext

lemma tc_collinear (A B C : Plane) (h : tcCross A B C = 0) :
    Collinear ℝ ({A, B, C} : Set Plane) := by
  by_cases hBC : B = C
  · subst hBC
    simp [collinear_pair]
  · apply collinear_insert_of_mem_affineSpan_pair
    have hn : 0 < (B 0 - C 0) ^ 2 + (B 1 - C 1) ^ 2 := by
      rw [← tc_dist_sq]; exact pow_pos (dist_pos.2 hBC) 2
    rw [mem_affineSpan_pair_iff_exists_lineMap_eq]
    refine ⟨((A 0 - B 0) * (C 0 - B 0) + (A 1 - B 1) * (C 1 - B 1)) /
      ((B 0 - C 0) ^ 2 + (B 1 - C 1) ^ 2), ?_⟩
    unfold tcCross at h
    apply tc_ext <;> simp [AffineMap.lineMap_apply_module] <;> field_simp
    · linear_combination (C 1 - B 1) * h
    · linear_combination (B 0 - C 0) * h

#print axioms tc_collinear

lemma tc_infDist_line (X Y P : Plane) (hXY : X ≠ Y) :
    Metric.infDist P (line[ℝ, X, Y] : Set Plane) = |tcCross X Y P| / dist X Y := by
  have hn : 0 < (X 0 - Y 0) ^ 2 + (X 1 - Y 1) ^ 2 := by
    rw [← tc_dist_sq]; exact pow_pos (dist_pos.2 hXY) 2
  have hd : |tcCross X Y P| / dist X Y =
      √(tcCross X Y P ^ 2 / ((X 0 - Y 0) ^ 2 + (X 1 - Y 1) ^ 2)) := by
    rw [Real.sqrt_div' _ hn.le, Real.sqrt_sq_eq_abs, tc_dist_eq]
  rw [hd]
  apply le_antisymm
  · set t := ((Y 0 - X 0) * (P 0 - X 0) + (Y 1 - X 1) * (P 1 - X 1)) /
      ((X 0 - Y 0) ^ 2 + (X 1 - Y 1) ^ 2)
    refine (Metric.infDist_le_dist_of_mem (AffineMap.lineMap_mem_affineSpan_pair t X Y)).trans
      (le_of_eq ?_)
    rw [tc_dist_eq]
    congr 1
    simp only [AffineMap.lineMap_apply_module, t, tcCross]
    simp
    field_simp
    ring
  · rw [Metric.le_infDist ⟨X, left_mem_affineSpan_pair ℝ X Y⟩]
    intro Q hQ
    rw [SetLike.mem_coe, mem_affineSpan_pair_iff_exists_lineMap_eq] at hQ
    obtain ⟨r, rfl⟩ := hQ
    rw [tc_dist_eq]
    apply Real.sqrt_le_sqrt
    rw [div_le_iff₀ hn]
    simp [AffineMap.lineMap_apply_module, tcCross]
    nlinarith [sq_nonneg ((Y 0 - X 0) * (P 0 - ((1 - r) * X 0 + r * Y 0)) +
      (Y 1 - X 1) * (P 1 - ((1 - r) * X 1 + r * Y 1)))]

#print axioms tc_infDist_line

lemma tc_angle_bisect {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (u v : V) (p q k : ℝ) (hu : ‖u‖ = q) (hv : ‖v‖ = p) (hq : q ≠ 0) (hp : p ≠ 0) :
    InnerProductGeometry.angle u (k • (p • u + q • v)) =
      InnerProductGeometry.angle (k • (p • u + q • v)) v := by
  unfold InnerProductGeometry.angle
  congr 1
  set w := k • (p • u + q • v)
  have h1 : inner ℝ u w = k * q * (p * q + inner ℝ u v) := by
    simp only [w, inner_smul_right, inner_add_right, real_inner_self_eq_norm_sq, hu]; ring
  have h2 : inner ℝ w v = k * p * (p * q + inner ℝ u v) := by
    simp only [w, inner_smul_left, inner_add_left, real_inner_self_eq_norm_sq, hv,
      RCLike.conj_to_real]; ring
  rw [h1, h2, hu, hv]
  by_cases hw : ‖w‖ = 0
  · simp [hw]
  · field_simp

#print axioms tc_angle_bisect

lemma tc_mem_hull (A B C P : Plane) (α β γ : ℝ) (ha : 0 ≤ α) (hb : 0 ≤ β) (hc : 0 ≤ γ)
    (hs : α + β + γ = 1) (hP : P = α • A + β • B + γ • C) :
    P ∈ convexHull ℝ ({A, B, C} : Set Plane) := by
  have := (convex_convexHull ℝ ({A, B, C} : Set Plane)).sum_mem (t := Finset.univ)
    (w := ![α, β, γ]) (z := ![A, B, C]) (by intro i _; fin_cases i <;> simpa)
    (by simpa [Fin.sum_univ_three] using hs)
    (by intro i _; fin_cases i <;> exact subset_convexHull ℝ _ (by simp))
  simpa [Fin.sum_univ_three, hP] using this

#print axioms tc_mem_hull

lemma tc_cross_comb (X Y x y : Plane) (a b : ℝ) (hab : a + b = 1) :
    tcCross X Y (a • x + b • y) = a * tcCross X Y x + b * tcCross X Y y := by
  obtain rfl : b = 1 - a := by linarith
  simp [tcCross]; ring

#print axioms tc_cross_comb

lemma tc_hull_sign (A B C : Plane) :
    convexHull ℝ ({A, B, C} : Set Plane) ⊆
      {P | 0 ≤ tcCross B C P * tcCross A B C ∧ 0 ≤ tcCross C A P * tcCross A B C ∧
        0 ≤ tcCross A B P * tcCross A B C} := by
  apply convexHull_min
  · intro P hP
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hP
    rcases hP with h | h | h <;> rw [h] <;> simp only [Set.mem_ofPred_eq, tcCross] <;>
      refine ⟨?_, ?_, ?_⟩ <;>
      nlinarith [sq_nonneg ((B 0 - A 0) * (C 1 - A 1) - (B 1 - A 1) * (C 0 - A 0))]
  · intro x hx y hy a b ha hb hab
    simp only [Set.mem_ofPred_eq, tc_cross_comb _ _ _ _ _ _ hab] at hx hy ⊢
    refine ⟨?_, ?_, ?_⟩ <;> nlinarith [mul_nonneg ha hx.1, mul_nonneg hb hy.1,
      mul_nonneg ha hx.2.1, mul_nonneg hb hy.2.1, mul_nonneg ha hx.2.2, mul_nonneg hb hy.2.2]

#print axioms tc_hull_sign

/-- The circumcentre. For three farms A, B and C on flat ground that are not in a row, the three
perpendicular bisectors (the points equally far from two of the farms) meet at exactly one point:
the one point equally far from all three farms. -/
theorem perpendicular_bisectors_meet_at_one_point (A B C : Plane)
    (h : ¬ Collinear ℝ ({A, B, C} : Set Plane)) :
    ∃! O : Plane, O ∈ perpBisector A B ∧ O ∈ perpBisector B C ∧ O ∈ perpBisector C A := by
  have hD : tcCross A B C ≠ 0 := fun h0 => h (tc_collinear A B C h0)
  have hind : AffineIndependent ℝ ![A, B, C] := affineIndependent_iff_not_collinear_set.2 h
  let T : Affine.Simplex ℝ Plane 2 := ⟨![A, B, C], hind⟩
  have hA : dist T.circumcenter A = T.circumradius := by
    rw [dist_comm]; exact T.dist_circumcenter_eq_circumradius 0
  have hB : dist T.circumcenter B = T.circumradius := by
    rw [dist_comm]; exact T.dist_circumcenter_eq_circumradius 1
  have hC : dist T.circumcenter C = T.circumradius := by
    rw [dist_comm]; exact T.dist_circumcenter_eq_circumradius 2
  refine ⟨T.circumcenter, ?_, ?_⟩
  · simp only [mem_perpBisector_iff_dist_eq]
    exact ⟨by rw [hA, hB], by rw [hB, hC], by rw [hC, hA]⟩
  · rintro O' ⟨e1, e2, -⟩
    rw [mem_perpBisector_iff_dist_eq] at e1 e2
    set O := T.circumcenter
    have f1 : dist O' A ^ 2 = dist O' B ^ 2 := by rw [e1]
    have f2 : dist O' B ^ 2 = dist O' C ^ 2 := by rw [e2]
    have g1 : dist O A ^ 2 = dist O B ^ 2 := by rw [hA, hB]
    have g2 : dist O B ^ 2 = dist O C ^ 2 := by rw [hB, hC]
    rw [tc_dist_sq, tc_dist_sq] at f1 f2 g1 g2
    have E1 : (O' 0 - O 0) * (B 0 - A 0) + (O' 1 - O 1) * (B 1 - A 1) = 0 := by
      linear_combination (f1 - g1) / 2
    have E2 : (O' 0 - O 0) * (C 0 - B 0) + (O' 1 - O 1) * (C 1 - B 1) = 0 := by
      linear_combination (f2 - g2) / 2
    have hx : (O' 0 - O 0) * tcCross A B C = 0 := by
      unfold tcCross; linear_combination (C 1 - B 1) * E1 - (B 1 - A 1) * E2
    have hy : (O' 1 - O 1) * tcCross A B C = 0 := by
      unfold tcCross; linear_combination (B 0 - A 0) * E2 - (C 0 - B 0) * E1
    apply tc_ext
    · exact sub_eq_zero.1 ((mul_eq_zero.1 hx).resolve_right hD)
    · exact sub_eq_zero.1 ((mul_eq_zero.1 hy).resolve_right hD)

/-- The incentre. For three farms not in a row, name each road by the farm it faces:
a = |BC|, b = |CA|, c = |AB|. Let K be the area (half base times height, base AB) and
s = (a + b + c) / 2 half the perimeter. The point I = (aA + bB + cC) / (a + b + c) lies inside
the triangle, on all three angle bisectors, at distance K / s from every road, and no point of
the triangle is more than K / s from its nearest road, so the largest pond has radius K / s. -/
theorem angle_bisectors_meet_at_incentre (A B C : Plane)
    (h : ¬ Collinear ℝ ({A, B, C} : Set Plane)) :
    let a := dist B C
    let b := dist C A
    let c := dist A B
    let s := (a + b + c) / 2
    let K := c * Metric.infDist C (line[ℝ, A, B] : Set Plane) / 2
    let I : Plane := (a + b + c)⁻¹ • (a • A + b • B + c • C)
    I ∈ interior (convexHull ℝ ({A, B, C} : Set Plane)) ∧
    (∠ B A I = ∠ I A C ∧ ∠ C B I = ∠ I B A ∧ ∠ A C I = ∠ I C B) ∧
    (Metric.infDist I (line[ℝ, B, C] : Set Plane) = K / s ∧
      Metric.infDist I (line[ℝ, C, A] : Set Plane) = K / s ∧
      Metric.infDist I (line[ℝ, A, B] : Set Plane) = K / s) ∧
    ∀ P ∈ convexHull ℝ ({A, B, C} : Set Plane),
      min (Metric.infDist P (line[ℝ, B, C] : Set Plane))
        (min (Metric.infDist P (line[ℝ, C, A] : Set Plane))
          (Metric.infDist P (line[ℝ, A, B] : Set Plane))) ≤ K / s := by
  intro a b c s K I
  have hD : tcCross A B C ≠ 0 := fun h0 => h (tc_collinear A B C h0)
  have hAB : A ≠ B := by rintro rfl; exact hD (by unfold tcCross; ring)
  have hBC : B ≠ C := by rintro rfl; exact hD (by unfold tcCross; ring)
  have hCA : C ≠ A := by rintro rfl; exact hD (by unfold tcCross; ring)
  have ha : 0 < a := dist_pos.2 hBC
  have hb : 0 < b := dist_pos.2 hCA
  have hc : 0 < c := dist_pos.2 hAB
  have hS : 0 < a + b + c := by positivity
  have hI0 : I 0 = (a + b + c)⁻¹ * (a * A 0 + b * B 0 + c * C 0) := by simp [I]; ring
  have hI1 : I 1 = (a + b + c)⁻¹ * (a * A 1 + b * B 1 + c * C 1) := by simp [I]; ring
  have hIa : tcCross B C I = a * tcCross A B C / (a + b + c) := by
    unfold tcCross; rw [hI0, hI1]; field_simp; ring
  have hIb : tcCross C A I = b * tcCross A B C / (a + b + c) := by
    unfold tcCross; rw [hI0, hI1]; field_simp; ring
  have hIc : tcCross A B I = c * tcCross A B C / (a + b + c) := by
    unfold tcCross; rw [hI0, hI1]; field_simp; ring
  have hKs : K / s = |tcCross A B C| / (a + b + c) := by
    simp only [K, s]
    rw [tc_infDist_line A B C hAB, show dist A B = c from rfl]
    field_simp
  refine ⟨?_, ?_, ?_, ?_⟩
  · -- I is inside the triangle
    have hU : IsOpen {P : Plane | 0 < tcCross B C P * tcCross A B C ∧
        0 < tcCross C A P * tcCross A B C ∧ 0 < tcCross A B P * tcCross A B C} := by
      simp only [Set.ofPred_and]
      unfold tcCross
      refine IsOpen.inter (isOpen_lt continuous_const (by fun_prop))
        (IsOpen.inter (isOpen_lt continuous_const (by fun_prop))
          (isOpen_lt continuous_const (by fun_prop)))
    have hsub : {P : Plane | 0 < tcCross B C P * tcCross A B C ∧
        0 < tcCross C A P * tcCross A B C ∧ 0 < tcCross A B P * tcCross A B C} ⊆
        convexHull ℝ ({A, B, C} : Set Plane) := by
      rintro P ⟨p1, p2, p3⟩
      have nn : ∀ x : ℝ, 0 < x * tcCross A B C → 0 ≤ x / tcCross A B C := by
        intro x hx
        rw [← mul_div_mul_right x _ hD]
        exact div_nonneg hx.le (mul_self_nonneg _)
      have k0 : tcCross B C P * A 0 + tcCross C A P * B 0 + tcCross A B P * C 0 =
          tcCross A B C * P 0 := by unfold tcCross; ring
      have k1 : tcCross B C P * A 1 + tcCross C A P * B 1 + tcCross A B P * C 1 =
          tcCross A B C * P 1 := by unfold tcCross; ring
      have ks : tcCross B C P + tcCross C A P + tcCross A B P = tcCross A B C := by
        unfold tcCross; ring
      apply tc_mem_hull A B C P _ _ _ (nn _ p1) (nn _ p2) (nn _ p3)
      · field_simp; linear_combination ks
      · apply tc_ext
        · simp; field_simp; linear_combination -k0
        · simp; field_simp; linear_combination -k1
    apply interior_maximal hsub hU
    have hDD : 0 < tcCross A B C * tcCross A B C := mul_self_pos.2 hD
    refine ⟨?_, ?_, ?_⟩
    · rw [hIa, div_mul_eq_mul_div, mul_assoc]; positivity
    · rw [hIb, div_mul_eq_mul_div, mul_assoc]; positivity
    · rw [hIc, div_mul_eq_mul_div, mul_assoc]; positivity
  · -- I lies on the three angle bisectors
    have hS0 : a + b + c ≠ 0 := hS.ne'
    have vA : I -ᵥ A = (a + b + c)⁻¹ • (b • (B -ᵥ A) + c • (C -ᵥ A)) := by
      apply tc_ext <;> simp [I] <;> field_simp <;> ring
    have vB : I -ᵥ B = (a + b + c)⁻¹ • (c • (C -ᵥ B) + a • (A -ᵥ B)) := by
      apply tc_ext <;> simp [I] <;> field_simp <;> ring
    have vC : I -ᵥ C = (a + b + c)⁻¹ • (a • (A -ᵥ C) + b • (B -ᵥ C)) := by
      apply tc_ext <;> simp [I] <;> field_simp <;> ring
    refine ⟨?_, ?_, ?_⟩
    · unfold EuclideanGeometry.angle
      rw [vA]
      exact tc_angle_bisect _ _ _ _ _ ((dist_eq_norm_vsub _ B A).symm.trans (dist_comm B A))
        (dist_eq_norm_vsub _ C A).symm hc.ne' hb.ne'
    · unfold EuclideanGeometry.angle
      rw [vB]
      exact tc_angle_bisect _ _ _ _ _ ((dist_eq_norm_vsub _ C B).symm.trans (dist_comm C B))
        (dist_eq_norm_vsub _ A B).symm ha.ne' hc.ne'
    · unfold EuclideanGeometry.angle
      rw [vC]
      exact tc_angle_bisect _ _ _ _ _ ((dist_eq_norm_vsub _ A C).symm.trans (dist_comm A C))
        (dist_eq_norm_vsub _ B C).symm hb.ne' ha.ne'
  · -- I is at distance K / s from each road
    rw [hKs, tc_infDist_line B C I hBC, tc_infDist_line C A I hCA, tc_infDist_line A B I hAB,
      show dist B C = a from rfl, show dist C A = b from rfl, show dist A B = c from rfl,
      hIa, hIb, hIc]
    refine ⟨?_, ?_, ?_⟩ <;>
      rw [abs_div, abs_mul, abs_of_pos hS] <;> first
        | rw [abs_of_pos ha]; field_simp
        | rw [abs_of_pos hb]; field_simp
        | rw [abs_of_pos hc]; field_simp
  · -- no point of the triangle is farther than K / s from its nearest road
    intro P hP
    obtain ⟨p1, p2, p3⟩ := tc_hull_sign A B C hP
    rw [tc_infDist_line B C P hBC, tc_infDist_line C A P hCA, tc_infDist_line A B P hAB, hKs]
    by_contra hcon
    rw [not_le] at hcon
    simp only [lt_min_iff] at hcon
    obtain ⟨q1, q2, q3⟩ := hcon
    rw [div_lt_div_iff₀ hS ha] at q1
    rw [div_lt_div_iff₀ hS hb] at q2
    rw [div_lt_div_iff₀ hS hc] at q3
    have hDpos : 0 < |tcCross A B C| := abs_pos.2 hD
    have m1 := mul_lt_mul_of_pos_right q1 hDpos
    have m2 := mul_lt_mul_of_pos_right q2 hDpos
    have m3 := mul_lt_mul_of_pos_right q3 hDpos
    have r1 : |tcCross B C P| * |tcCross A B C| = tcCross B C P * tcCross A B C := by
      rw [← abs_mul, abs_of_nonneg p1]
    have r2 : |tcCross C A P| * |tcCross A B C| = tcCross C A P * tcCross A B C := by
      rw [← abs_mul, abs_of_nonneg p2]
    have r3 : |tcCross A B P| * |tcCross A B C| = tcCross A B P * tcCross A B C := by
      rw [← abs_mul, abs_of_nonneg p3]
    have ks : tcCross B C P + tcCross C A P + tcCross A B P = tcCross A B C := by
      unfold tcCross; ring
    have hD2 : |tcCross A B C| * |tcCross A B C| = tcCross A B C * tcCross A B C :=
      abs_mul_abs_self _
    have t1 : |tcCross B C P| * (a + b + c) * |tcCross A B C| =
        (a + b + c) * (tcCross B C P * tcCross A B C) := by linear_combination (a + b + c) * r1
    have t2 : |tcCross C A P| * (a + b + c) * |tcCross A B C| =
        (a + b + c) * (tcCross C A P * tcCross A B C) := by linear_combination (a + b + c) * r2
    have t3 : |tcCross A B P| * (a + b + c) * |tcCross A B C| =
        (a + b + c) * (tcCross A B P * tcCross A B C) := by linear_combination (a + b + c) * r3
    have hs2 : (a + b + c) * (tcCross B C P * tcCross A B C) +
        (a + b + c) * (tcCross C A P * tcCross A B C) +
        (a + b + c) * (tcCross A B P * tcCross A B C) =
        (a + b + c) * (tcCross A B C * tcCross A B C) := by
      linear_combination (a + b + c) * tcCross A B C * ks
    have e : |tcCross A B C| * a * |tcCross A B C| + |tcCross A B C| * b * |tcCross A B C| +
        |tcCross A B C| * c * |tcCross A B C| = (a + b + c) * (tcCross A B C * tcCross A B C) := by
      linear_combination (a + b + c) * hD2
    linarith [m1, m2, m3, t1, t2, t3, hs2, e]

/-- The centroid. For any three corners, the average G = (A + B + C) / 3 is two-thirds of the
way from each corner to the midpoint of the opposite side, so it lies on all three medians; and
for every point P, the total of squared distances from P to the corners is 3|P − G|² plus the
same total at G, so that total is smallest at G. -/
theorem centroid_on_medians_and_least_squares (A B C : Plane) :
    let G : Plane := (1 / 3 : ℝ) • (A + B + C)
    (A + (2 / 3 : ℝ) • (midpoint ℝ B C - A) = G ∧
      B + (2 / 3 : ℝ) • (midpoint ℝ C A - B) = G ∧
      C + (2 / 3 : ℝ) • (midpoint ℝ A B - C) = G) ∧
    ∀ P : Plane, dist P A ^ 2 + dist P B ^ 2 + dist P C ^ 2 =
      3 * dist P G ^ 2 + (dist G A ^ 2 + dist G B ^ 2 + dist G C ^ 2) := by
  intro G
  refine ⟨⟨?_, ?_, ?_⟩, ?_⟩
  · apply tc_ext <;> simp [G, midpoint_eq_smul_add] <;> ring
  · apply tc_ext <;> simp [G, midpoint_eq_smul_add] <;> ring
  · apply tc_ext <;> simp [G, midpoint_eq_smul_add] <;> ring
  · intro P
    simp only [tc_dist_sq]
    simp [G]
    ring

-- Farms A (0, 0), B (8, 0), C (2, 6). The centroid averages the corners: (10/3, 2).
example : ((0 : ℚ) + 8 + 2) / 3 = 10 / 3 ∧ ((0 : ℚ) + 0 + 6) / 3 = 2 := by norm_num
-- From farm A, the median reaches the midpoint (5, 3); two-thirds of the way is (10/3, 2).
example : (0 : ℚ) + 2 / 3 * (5 - 0) = 10 / 3 ∧ (0 : ℚ) + 2 / 3 * (3 - 0) = 2 := by norm_num
-- Bisector of A and B: 16x = 64, so x = 4. Bisector of A and C: 4x + 12y = 40, so y = 2.
example : (16 : ℤ) * 4 = 64 ∧ (4 : ℤ) * 4 + 12 * 2 = 40 := by decide
-- O = (4, 2) is equally far from all three farms: squared distance 20 to each.
example : dist (!₂[4, 2] : Plane) !₂[0, 0] = dist (!₂[4, 2] : Plane) !₂[8, 0] ∧
    dist (!₂[4, 2] : Plane) !₂[8, 0] = dist (!₂[4, 2] : Plane) !₂[2, 6] := by
  simp [EuclideanSpace.dist_eq, Real.dist_eq]; norm_num
example : ((4 : ℤ) - 0) ^ 2 + (2 - 0) ^ 2 = 20 ∧ ((4 : ℤ) - 8) ^ 2 + (2 - 0) ^ 2 = 20 ∧
    ((4 : ℤ) - 2) ^ 2 + (2 - 6) ^ 2 = 20 := by decide
-- The area is 8 × 6 / 2 = 24 square km.
example : (8 : ℕ) * 6 / 2 = 24 := by decide
-- Total of squared distances: 176/3 (58.67) at G, against 60 at O.
example : ((10 / 3 : ℚ) ^ 2 + 2 ^ 2) + ((10 / 3 - 8) ^ 2 + 2 ^ 2) + ((10 / 3 - 2) ^ 2 + (2 - 6) ^ 2)
    = 176 / 3 := by norm_num
example : ((4 : ℤ) ^ 2 + 2 ^ 2) + ((4 - 8) ^ 2 + 2 ^ 2) + ((4 - 2) ^ 2 + (2 - 6) ^ 2) = 60 := by
  decide
-- Obtuse farms (0, 0), (8, 0), (2, 2): O = (4, −2), squared distance 20 to each, outside road AB.
example : dist (!₂[4, -2] : Plane) !₂[0, 0] = dist (!₂[4, -2] : Plane) !₂[8, 0] ∧
    dist (!₂[4, -2] : Plane) !₂[8, 0] = dist (!₂[4, -2] : Plane) !₂[2, 2] := by
  simp [EuclideanSpace.dist_eq, Real.dist_eq]; norm_num
-- There a well at the midpoint (4, 0) of road AB needs at most 4 km: 4² = 16 < 20.
example : ((4 : ℤ) - 0) ^ 2 + 0 ^ 2 = 16 ∧ ((4 : ℤ) - 8) ^ 2 + 0 ^ 2 = 16 ∧
    ((4 : ℤ) - 2) ^ 2 + (0 - 2) ^ 2 = 8 ∧ (16 : ℤ) < 20 := by decide

#print axioms perpendicular_bisectors_meet_at_one_point
#print axioms angle_bisectors_meet_at_incentre
#print axioms centroid_on_medians_and_least_squares
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'tcCross' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_dist_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_dist_sq' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_ext' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_collinear' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_infDist_line' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_angle_bisect' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_mem_hull' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_cross_comb' depends on axioms: [propext, Classical.choice, Quot.sound]
'tc_hull_sign' depends on axioms: [propext, Classical.choice, Quot.sound]
'perpendicular_bisectors_meet_at_one_point' depends on axioms: [propext, Classical.choice, Quot.sound]
'angle_bisectors_meet_at_incentre' depends on axioms: [propext, Classical.choice, Quot.sound]
'centroid_on_medians_and_least_squares' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Line the farms up.** Set `C` (in Rust, `fc`) to `(4.0, 0.0)`. Python stops on a division by zero; in Rust the first assert stops it. No equal-pipe point exists.
> - **Wrong weights.** In the incentre, swap the weights `a` and `c`. The point leaves the search's (2.92, 2.10) and the first assert stops it.
> - **Average over two.** Divide the centroid by 2. The search still finds (3.33, 2.00), and the first assert stops it.

---

## The usual mistake

> [!warning]
> **Calling one point "the centre" before naming the question.** The average of the farms is the natural guess for a fair well, and gives pipes of 3.89, 5.08 and 4.22 km. Balance, equal distance to the corners and equal distance to the sides are different demands, met by one point only when all three sides are equal.
>
> - **Equal pipes read as short pipes.** For the obtuse farms, O's pipes are all 4.47 km, but a well at the midpoint of road AB, (4.00, 0.00), needs at most 4.00 km.
> - **Averaging the corners for the pond.** The centroid clears road $a$ by 1.89 km, less than the 2.1044 km pond at I.

---

## Where you meet it in real life

- **Nearest-site maps.** Maps giving each spot to its nearest mast have borders along perpendicular bisectors, meeting in threes at circumcentres.
- **Round things from three marks.** Three points on a broken plate's rim fix the circle through them, centred at their circumcentre ([Circles and parabolas](04-circles-and-parabolas.md)).
- **Plates and offcuts.** An evenly thick triangular plate hangs level from its centroid; the largest disc cut from a triangular offcut is centred at its incentre.

> **Say it back**
> A triangle has several centres, each answering its own question. The centroid averages the corners, and equal weights there balance. The circumcentre, where perpendicular bisectors cross, is equally far from the corners and can lie outside. The incentre, where angle bisectors cross, is equally far from the sides and centres the largest circle inside. Two equalities force the third, so the third line always joins the crossing.

---

## What this builds on

- [Lines](02-lines-slopes-and-intersections.md): two non-parallel lines cross at exactly one point, found by solving two equations.
- [Distance and midpoint](01-distance-and-midpoint.md): the distance formula behind every pipe length, road length and midpoint.
- [Congruent triangles](../01-Angles%2C%20Triangles%20and%20Congruence/03-congruent-triangles.md): the RHS test that puts I on each angle bisector.
- [Area](../01-Angles%2C%20Triangles%20and%20Congruence/06-area-of-triangles-and-polygons.md): half base times height, which gives the pond's radius as K over s.

## Where this goes next

The sibling [Circles and parabolas](04-circles-and-parabolas.md) writes the circumcircle as an equation.

Every corner of a nearest-site map is a circumcentre; [Nearest-neighbour maps](../07-Points%2C%20Convexity%20and%20Fractals/04-voronoi-and-delaunay.md) builds the whole map from perpendicular bisectors.

Every answer here assumed flat ground; asked of three towns on the curved Earth, "equally far" has different answers, which is where [Triangles on a sphere](../06-Beyond%20Euclid/01-triangles-on-a-sphere.md) takes geometry off the plane.

---

## Sources

Verified 2026-09-24: every link below resolves to the publisher's page.

- Euclid, *Elements*, Book IV, [Proposition 4](https://mathcs.clarku.edu/~djoyce/elements/bookIV/propIV4.html) and [Proposition 5](https://mathcs.clarku.edu/~djoyce/elements/bookIV/propIV5.html), D. E. Joyce's edition, Clark University. The incircle and the circumcircle, constructed and proved.
- Euclid, *Elements*, Book VI, [Proposition 3](https://mathcs.clarku.edu/~djoyce/elements/bookVI/propVI3.html), same edition. The angle-bisector split used in Step 3.
- Coxeter, H. S. M., and S. L. Greitzer. *Geometry Revisited*. MAA, 1967. [Publisher page](https://bookstore.ams.org/nml-19). Chapter 1: medians, circumcircle and incircle.
- Kimberling, Clark. [*Encyclopedia of Triangle Centers*](https://faculty.evansville.edu/ck6/encyclopedia/ETC.html), University of Evansville. Lists the incentre, centroid and circumcentre first, among tens of thousands of centres.
