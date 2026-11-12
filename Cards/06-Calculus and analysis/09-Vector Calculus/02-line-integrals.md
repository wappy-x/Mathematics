# Line integrals of a field: work done along a path

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Vector Calculus](../README.md#s09) → Line integrals of a field

---

## General Overview

A cart crosses a field 40 m wide and 30 m deep, from corner A in the south-west to corner B in the north-east. Wind blows over the field. A hedge shelters the south edge, so the wind's eastward push grows by 0.1 N for every metre north: nothing at the hedge, 3 N along the north edge. A steady 1 N drift pushes south everywhere.

On each short stretch, only the part of the push along the cart's motion helps; a push across it does nothing, a push against it takes energy away. The help is **work**, in joules: newtons along the motion times metres moved.

Straight across, the wind gives 30 J. Along a curve bowing south, 10 J. East along the hedge, then north: −30 J. North, then east along the windy top: 90 J. Same ends, four answers. A **line integral of a field** adds these pieces up, and keeps track of the direction of travel.

<p align="center"><img src="../figures/line-integrals.svg" alt="The field 40 m by 30 m to scale, with the four routes from A to B and six wind arrows that lengthen northward" width="420"></p>

To scale, 6 units per metre; wind arrows run from their dots, 1 m per newton. Solid edges: east, then north. Dashed edges: north, then east. Diagonal: straight. Dotted: the curve.

**A line integral of a field adds, along a directed route, the field's part along the motion times each small step; reversing the route flips the sign, and another route may give another answer.**

**What kind of fact this is:** a definition. Three facts about it are theorems, proved in Why it works: it is the limit of force-times-step sums, it ignores the pace, and it flips sign on reversal.

---

## The formula

Notation first, in words. A **field** $F$ puts a vector at every point: the wind's push, with east part $P$ and north part $Q$. The route $C$ is traced by a position $r(t)$ as a clock $t$ runs from $a$ to $b$; $r'(t)$ is the velocity.

$$W = \int_C F \cdot dr = \int_a^b F(r(t)) \cdot r'(t)\, dt$$

**Read it aloud:** at each clock reading, take the wind where the cart is, dot it with the cart's velocity, and add over the clock.

In parts, the same integral is $\int_C P\,dx + Q\,dy$: east push times eastward steps, plus north push times northward steps. With $T$ the direction of travel (length 1) and $ds$ a small length, $F \cdot dr = (F \cdot T)\, ds$: push along the motion times distance.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $F$, $P$, $Q$ | the field, and its east and north parts, newtons | $(y/10, -1)$ N | more help where it points along the route |
| $C$ | the route, including its direction | A to B | reversing it flips the sign |
| $r(t)$, $x$, $y$ | the cart's position at clock reading t: metres east and north of A | straight: $(40t, 30t)$ | — |
| $t$, $a$, $b$; $s$, $\varphi$ | the clock and its start and end; a second clock and the rule turning it into the first | 0 to 1; $t = s^2$ | a new clock leaves the answer alone |
| $r'(t)$ | velocity: metres per unit of clock | straight: $(40, 30)$ | — |
| $dr$ | a small step along the route, velocity times a small clock step | — | — |
| $\cdot$ | the dot product: east parts multiplied, plus north parts multiplied | straight, at clock t: $3t \times 40 + (-1) \times 30$ | — |
| $T$, $ds$ | direction of travel, length 1; a small length along the route | straight: $(0.8, 0.6)$, 50 m in all | — |
| $W$ | the work done by the wind, joules | straight: 30 J | — |

Newtons times metres are joules. With the clock in seconds, $F(r(t)) \cdot r'(t)$ is power in watts.

### When it holds

A definition holds wherever it makes sense; the bullets say where.

- **Smooth pieces.** Corners are fine: split there and add. Each L-shaped route is two straight pieces.
- **A field with at most a few jumps along the route.** A field jumping at every scale leaves the sums with no limit.
- **A forward clock.** Any forward pace gives the same work; a backward clock reverses the route and the sign.
- **A finite route.** One spiralling in forever can have sums that never settle.

---

## Why it works

### Step 0: a steady push on a straight step

For a steady push on a straight step, work is the dot product of push and step: the push's part along the step, times the step's length. The rest is adding short steps, over which the wind barely changes.

### Step 1: short steps give a sum, the sum closes in on the integral

Cut the route into short pieces. Dot the wind at each piece's middle with its chord, the straight step from start to end, and add. No derivative appears.

On the curve, 4 pieces give 9.375000 J, short by 0.625000 J; 16 pieces, short by 0.039062 J. To land within 0.01 J, 32 pieces suffice: short by 0.009766 J. With 64, 0.002441 J.

Over a short clock step the chord is almost $r'(t)$ times the step, so the sum is almost a sum of $F(r(t)) \cdot r'(t)$ times clock steps. That is a Riemann sum ([The integral](../04-Integrals/01-riemann-integral.md)), and it closes in on the integral.

<details>
<summary>Detailed proof: every fine force-times-chord sum tends to the integral</summary>

Let $r$ have a continuous velocity, and $F$ be continuous along the route. Cut the clock at $a = t_0 < t_1 < \dots < t_n = b$, widest step h, and pick any reading τ_i in each step. The sum is $S = \sum F(r(\tau_i)) \cdot (r(t_i) - r(t_{i-1}))$.

By the fundamental theorem of calculus, applied to each coordinate, $r(t_i) - r(t_{i-1}) = \int_{t_{i-1}}^{t_i} r'(t)\,dt$. So
$$S - W = \sum \int_{t_{i-1}}^{t_i} \big(F(r(\tau_i)) - F(r(t))\big) \cdot r'(t)\,dt.$$
$F(r(t))$ is continuous on a closed interval, so uniformly continuous: for every ε > 0 some δ > 0 keeps readings less than δ apart within ε in field. Take h < δ. A dot product is at most the product of lengths, so
$$|S - W| \le \varepsilon \int_a^b \lVert r'(t) \rVert\, dt = \varepsilon L,$$
with L the route's length. As ε shrinks, S tends to W, whatever readings are picked. Corners are handled piece by piece.

</details>

### Step 2: the pace does not matter, the direction does

Push straight from A to B, starting slowly: position $(40s^2, 30s^2)$ as a new clock s runs from 0 to 1. The chain rule multiplies the velocity by $2s$, the rate of $t = s^2$; the substitution rule ([Substitution](../04-Integrals/03-substitution.md)) removes exactly that factor, so the work is 30 J again.

In general, a forward clock change $t = \varphi(s)$ leaves the integral unchanged. A backward one, B to A, swaps the limits, which flips the sign: −30 J. Reversing the route reverses every chord, so the Step 1 sums flip sign too. On [Line integrals of a function](01-scalar-line-integrals.md) each small length counts positive either way; here each step carries a direction.

### Step 3: the curve, by hand

**The curve.** Position $(40t, 30t^2)$, velocity $(40, 60t)$, wind $(3t^2, -1)$. The dot product is $120t^2 - 60t$; its antiderivative $40t^3 - 30t^2$ gives 40 − 30 = **10 J** from 0 to 1.

**The other three.** The straight route and both L-shaped routes are worked in the table below: 30 J, −30 J and 90 J. On the L-shaped routes each leg is a steady push on a straight step, so Step 0 alone does it.

### Step 4: why routes differ, and a closed loop

Every route covers 40 m east and 30 m north, but one doing its eastward travel further north collects more help. The 1 N drift costs every route the same −30 J.

Go out north-then-east (90 J) and back along the hedge route reversed (+30 J). The cart ends where it began, yet the wind did 120 J: 0.1 N per metre times the area, 40 m × 30 m.

No accident: the wind's shear, how fast its eastward push changes going north, sets its **curl** ([Divergence and curl](03-divergence-and-curl.md)), here −0.1 N per metre. [Green's theorem](06-greens-theorem.md) proves that the work round an anticlockwise loop is the curl added over the enclosed area. This loop runs clockwise, so its work is the negative: +120 J.

A gradient field is made of one function's rates of change, east and north ([Gradient](../07-Several%20Variables/03-gradient-and-directional-derivatives.md)). For such a field, each step's dot product is that function's rate along the step. So the work is its change from A to B, and every loop gets 0 J. This wind is no gradient; [Conservative fields](04-conservative-fields-and-potentials.md) takes that road.

---

## Worked numbers, by hand

The wind at $(x, y)$ is $(y/10, -1)$ N; the cart goes from A $(0, 0)$ to B $(40, 30)$, in metres.

| Step | Arithmetic | Value |
| --- | --- | --- |
| straight route | length sqrt(40^2 + 30^2), direction 40/50 and 30/50 | 50 m, $(0.8, 0.6)$ |
| wind on it at clock t | $(30t/10, -1)$ | $(3t, -1)$ N |
| push along motion per unit of clock | $3t \times 40 + (-1) \times 30$ | 120t − 30 |
| add over the clock, 0 to 1 | 120/2 − 30 | **30 J** |
| north leg, either edge | −1 N × 30 m | −30 J |
| east leg along the top | 3 N × 40 m | 120 J |
| north, then east | −30 + 120 | **90 J** |
| east, then north | 0 + (−30) | **−30 J** |

Straight across, the wind supplies 30 J the pusher would otherwise provide; along the hedge it takes 30 J away.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Go B to A but keep the A-to-B velocity | 30 J, not −30 J | The direction lives in the velocity; reversing the route reverses it |
| Use the direction $(0.8, 0.6)$ instead of the velocity $(40, 30)$ | 0.600 J, not 30 J | The clock step is not a metre: 1 unit of clock covers 50 m |
| Add the wind's strength times length | 94.211, not 30 J | Strength ignores direction: the drift works against the cart |
| Same ends, so same work | 30 J for north-then-east, truly 90 J | This wind is no gradient field |

---

## Code, from first principles, and it actually runs

Two roads for all four routes, each checked against the hand values. Road one, the formula: Simpson's rule (a strip sum fitting a parabola over each pair of strips) on $F(r(t)) \cdot r'(t)$. Road two, the definition: mid-piece wind dotted with each chord, 1,024 pieces, no derivative. A second case checks a new clock, the reversal, and the loop against 0.1 N/m times the area.

### Python

```python
# Line integrals of a field -- the check behind the card.  Standard library
# only; math gives sqrt as a primitive, and every sum is written out here.
# Wind pushes a cart with force F(x, y) = (y/10, -1) newtons at the point
# x m east and y m north of corner A.  The cart goes from A to B by four routes.
from math import sqrt

def F(x, y): return (y / 10, -1.0)
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def line(p, q):                    # a straight piece from p to q, clock t from 0 to 1
    return (lambda t: (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t),
            lambda t: (q[0] - p[0], q[1] - p[1]))
A, B, NW, SE = (0, 0), (40, 30), (0, 30), (40, 0)
curve = (lambda t: (40 * t, 30 * t * t), lambda t: (40.0, 60 * t))
routes = {"straight": [line(A, B)], "curve": [curve],
          "east, then north": [line(A, SE), line(SE, B)],
          "north, then east": [line(A, NW), line(NW, B)]}
by_hand = {"straight": 120 / 2 - 30, "curve": 120 / 3 - 60 / 2,
           "east, then north": 0 - 30, "north, then east": -30 + 3 * 40}

def simpson(g, n=100):             # road one: integral of F(r(t)).r'(t) dt, Simpson's rule
    h = 1 / n
    return h / 3 * (g(0) + g(1) + sum((4 if i % 2 else 2) * g(i * h) for i in range(1, n)))
def formula(route): return sum(simpson(lambda t: dot(F(*r(t)), v(t))) for r, v in route)
def chords(route, n):              # road two, the definition: mid-piece force . each chord
    total = 0.0
    for r, _ in route:
        for i in range(n):
            p, q, m = r(i / n), r((i + 1) / n), r((i + 0.5) / n)
            total += dot(F(*m), (q[0] - p[0], q[1] - p[1]))
    return total

print("wind force (y/10, -1) N at (x, y) m; cart from A (0, 0) to B (40, 30)")
print(f"by hand: straight length {sqrt(40 ** 2 + 30 ** 2):.0f} m, direction ({40 / 50:.1f}, {30 / 50:.1f}); "
      f"north leg {-1 * 30:.0f} J; east leg at y = 30: {F(0, 30)[0]:.0f} N x 40 m = {F(0, 30)[0] * 40:.0f} J")
for name, route in routes.items():
    print(f"{name}: formula {formula(route):.6f} J, by hand {by_hand[name]:.6f} J, "
          f"1024 chords {chords(routes[name], 1024):.6f} J")
for n in (4, 16, 32, 64):
    print(f"curve, {n:2d} chords: {chords([curve], n):.6f} J, short by {10 - chords([curve], n):.6f} J")
pace = formula([(lambda s: (40 * s * s, 30 * s * s), lambda s: (80 * s, 60 * s))])
back = formula([line(B, A)])
loop = formula(routes["north, then east"]) + formula([line(B, SE), line(SE, A)])
print(f"straight, slow start (40s^2, 30s^2): {pace:.6f} J; straight, B to A: {back:.6f} J")
print(f"loop, north-then-east out, hedge route back: {loop:.6f} J; 0.1 N/m x 40 m x 30 m = {0.1 * 40 * 30:.6f}")
print(f"mistake 1, B to A with the A-to-B velocity: {simpson(lambda t: dot(F(*line(B, A)[0](t)), (40, 30))):.3f} J, not -30")
print(f"mistake 2, speed factor dropped: {simpson(lambda t: dot(F(40 * t, 30 * t), (0.8, 0.6))):.3f} J, not 30")
print(f"mistake 3, strength |F| times length: {simpson(lambda t: 50 * sqrt((3 * t) ** 2 + 1)):.3f} N m, not 30 J")
print(f"mistake 4, same ends so same work: straight 30 J copied to north-then-east, truly {by_hand['north, then east']:.0f} J")
X, Y = (lambda x: 50 + 6 * x), (lambda y: 210 - 6 * y)
print("figure, 6 units per m, curve:", " ".join(f"({X(40 * t / 8):.1f},{Y(30 * (t / 8) ** 2):.1f})" for t in range(9)))
print("figure, arrows 6 units per N, tail->head:", " ".join(
    f"({X(x):.0f},{Y(y):.0f})->({X(x + y / 10):.1f},{Y(y - 1):.0f})" for x, y in ((6, 12), (6, 24), (16, 26), (26, 26), (34, 4), (34, 12))))
for name in routes:
    assert abs(formula(routes[name]) - by_hand[name]) < 1e-9     # road one against the hand
    assert abs(chords(routes[name], 1024) - by_hand[name]) < 1e-4  # road two, the definition
assert abs(pace - 30) < 1e-9 and abs(back + 30) < 1e-9 and abs(chords([line(B, A)], 1024) + 30) < 1e-9  # new clock: same; reversed: negated, both roads
assert abs(loop - 0.1 * 40 * 30) < 1e-9                         # the loop against wind gain x area
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
wind force (y/10, -1) N at (x, y) m; cart from A (0, 0) to B (40, 30)
by hand: straight length 50 m, direction (0.8, 0.6); north leg -30 J; east leg at y = 30: 3 N x 40 m = 120 J
straight: formula 30.000000 J, by hand 30.000000 J, 1024 chords 30.000000 J
curve: formula 10.000000 J, by hand 10.000000 J, 1024 chords 9.999990 J
east, then north: formula -30.000000 J, by hand -30.000000 J, 1024 chords -30.000000 J
north, then east: formula 90.000000 J, by hand 90.000000 J, 1024 chords 90.000000 J
curve,  4 chords: 9.375000 J, short by 0.625000 J
curve, 16 chords: 9.960938 J, short by 0.039062 J
curve, 32 chords: 9.990234 J, short by 0.009766 J
curve, 64 chords: 9.997559 J, short by 0.002441 J
straight, slow start (40s^2, 30s^2): 30.000000 J; straight, B to A: -30.000000 J
loop, north-then-east out, hedge route back: 120.000000 J; 0.1 N/m x 40 m x 30 m = 120.000000
mistake 1, B to A with the A-to-B velocity: 30.000 J, not -30
mistake 2, speed factor dropped: 0.600 J, not 30
mistake 3, strength |F| times length: 94.211 N m, not 30 J
mistake 4, same ends so same work: straight 30 J copied to north-then-east, truly 90 J
figure, 6 units per m, curve: (50.0,210.0) (80.0,207.2) (110.0,198.8) (140.0,184.7) (170.0,165.0) (200.0,139.7) (230.0,108.8) (260.0,72.2) (290.0,30.0)
figure, arrows 6 units per N, tail->head: (86,138)->(93.2,144) (86,66)->(100.4,72) (146,54)->(161.6,60) (206,54)->(221.6,60) (254,186)->(256.4,192) (254,138)->(261.2,144)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Line integrals of a field -- the same check as the Python, in Rust.  No
// crates; sqrt is a primitive, and every sum is written out here.  Wind pushes
// a cart with force F(x, y) = (y/10, -1) newtons at the point x m east and
// y m north of corner A.  The cart goes from A to B by four routes.
type P = (f64, f64);
type Piece = (Box<dyn Fn(f64) -> P>, Box<dyn Fn(f64) -> P>); // position, velocity

fn f(p: P) -> P { (p.1 / 10.0, -1.0) }
fn dot(u: P, v: P) -> f64 { u.0 * v.0 + u.1 * v.1 }
fn line(p: P, q: P) -> Piece { // a straight piece from p to q, clock t from 0 to 1
    (Box::new(move |t| (p.0 + (q.0 - p.0) * t, p.1 + (q.1 - p.1) * t)), Box::new(move |_| (q.0 - p.0, q.1 - p.1)))
}
fn curve() -> Piece { (Box::new(|t| (40.0 * t, 30.0 * t * t)), Box::new(|t| (40.0, 60.0 * t))) }
fn simpson(g: &dyn Fn(f64) -> f64) -> f64 { // road one: integral of F(r(t)).r'(t) dt
    let n = 100;
    let h = 1.0 / n as f64;
    let mut s = g(0.0) + g(1.0);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(i as f64 * h) }
    s * h / 3.0
}
fn formula(route: &[Piece]) -> f64 { route.iter().map(|(r, v)| simpson(&|t| dot(f(r(t)), v(t)))).sum() }
fn chords(route: &[Piece], n: usize) -> f64 { // road two, the definition: mid-piece force . each chord
    let mut total = 0.0;
    for (r, _) in route {
        for i in 0..n {
            let (p, q) = (r(i as f64 / n as f64), r((i + 1) as f64 / n as f64));
            total += dot(f(r((i as f64 + 0.5) / n as f64)), (q.0 - p.0, q.1 - p.1));
        }
    }
    total
}

fn main() {
    let (a, b, nw, se) = ((0.0, 0.0), (40.0, 30.0), (0.0, 30.0), (40.0, 0.0));
    let routes: Vec<(&str, Vec<Piece>, f64)> = vec![
        ("straight", vec![line(a, b)], 120.0 / 2.0 - 30.0),
        ("curve", vec![curve()], 120.0 / 3.0 - 60.0 / 2.0),
        ("east, then north", vec![line(a, se), line(se, b)], 0.0 - 30.0),
        ("north, then east", vec![line(a, nw), line(nw, b)], -30.0 + 3.0 * 40.0)];
    println!("wind force (y/10, -1) N at (x, y) m; cart from A (0, 0) to B (40, 30)");
    println!("by hand: straight length {:.0} m, direction ({:.1}, {:.1}); north leg {:.0} J; east leg at y = 30: {:.0} N x 40 m = {:.0} J",
             (40.0f64.powi(2) + 30.0f64.powi(2)).sqrt(), 40.0 / 50.0, 30.0 / 50.0, -1.0 * 30.0, f((0.0, 30.0)).0, f((0.0, 30.0)).0 * 40.0);
    for (name, route, hand) in &routes {
        println!("{}: formula {:.6} J, by hand {:.6} J, 1024 chords {:.6} J", name, formula(route), hand, chords(route, 1024));
    }
    for n in [4, 16, 32, 64] {
        let c = chords(&[curve()], n);
        println!("curve, {:2} chords: {:.6} J, short by {:.6} J", n, c, 10.0 - c);
    }
    let pace = formula(&[(Box::new(|s: f64| (40.0 * s * s, 30.0 * s * s)), Box::new(|s: f64| (80.0 * s, 60.0 * s)))]);
    let back = formula(&[line(b, a)]);
    let lp = formula(&routes[3].1) + formula(&[line(b, se), line(se, a)]);
    println!("straight, slow start (40s^2, 30s^2): {:.6} J; straight, B to A: {:.6} J", pace, back);
    println!("loop, north-then-east out, hedge route back: {:.6} J; 0.1 N/m x 40 m x 30 m = {:.6}", lp, 0.1 * 40.0 * 30.0);
    let rb = line(b, a).0;
    println!("mistake 1, B to A with the A-to-B velocity: {:.3} J, not -30", simpson(&|t| dot(f(rb(t)), (40.0, 30.0))));
    println!("mistake 2, speed factor dropped: {:.3} J, not 30", simpson(&|t| dot(f((40.0 * t, 30.0 * t)), (0.8, 0.6))));
    println!("mistake 3, strength |F| times length: {:.3} N m, not 30 J", simpson(&|t| 50.0 * ((3.0 * t).powi(2) + 1.0).sqrt()));
    println!("mistake 4, same ends so same work: straight 30 J copied to north-then-east, truly {:.0} J", routes[3].2);
    let (sx, sy) = (|x: f64| 50.0 + 6.0 * x, |y: f64| 210.0 - 6.0 * y);
    let pts: Vec<String> = (0..9).map(|t| t as f64 / 8.0)
        .map(|t| format!("({:.1},{:.1})", sx(40.0 * t), sy(30.0 * t * t))).collect();
    println!("figure, 6 units per m, curve: {}", pts.join(" "));
    let arr: Vec<String> = [(6.0, 12.0), (6.0, 24.0), (16.0, 26.0), (26.0, 26.0), (34.0, 4.0), (34.0, 12.0)].iter()
        .map(|&(x, y): &(f64, f64)| format!("({:.0},{:.0})->({:.1},{:.0})", sx(x), sy(y), sx(x + y / 10.0), sy(y - 1.0))).collect();
    println!("figure, arrows 6 units per N, tail->head: {}", arr.join(" "));
    for (_, route, hand) in &routes {
        assert!((formula(route) - hand).abs() < 1e-9); // road one against the hand
        assert!((chords(route, 1024) - hand).abs() < 1e-4); // road two, the definition
    }
    assert!((pace - 30.0).abs() < 1e-9 && (back + 30.0).abs() < 1e-9 && (chords(&[line(b, a)], 1024) + 30.0).abs() < 1e-9); // new clock: same; reversed: negated, both roads
    assert!((lp - 0.1 * 40.0 * 30.0).abs() < 1e-9); // the loop against wind gain x area
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
wind force (y/10, -1) N at (x, y) m; cart from A (0, 0) to B (40, 30)
by hand: straight length 50 m, direction (0.8, 0.6); north leg -30 J; east leg at y = 30: 3 N x 40 m = 120 J
straight: formula 30.000000 J, by hand 30.000000 J, 1024 chords 30.000000 J
curve: formula 10.000000 J, by hand 10.000000 J, 1024 chords 9.999990 J
east, then north: formula -30.000000 J, by hand -30.000000 J, 1024 chords -30.000000 J
north, then east: formula 90.000000 J, by hand 90.000000 J, 1024 chords 90.000000 J
curve,  4 chords: 9.375000 J, short by 0.625000 J
curve, 16 chords: 9.960938 J, short by 0.039062 J
curve, 32 chords: 9.990234 J, short by 0.009766 J
curve, 64 chords: 9.997559 J, short by 0.002441 J
straight, slow start (40s^2, 30s^2): 30.000000 J; straight, B to A: -30.000000 J
loop, north-then-east out, hedge route back: 120.000000 J; 0.1 N/m x 40 m x 30 m = 120.000000
mistake 1, B to A with the A-to-B velocity: 30.000 J, not -30
mistake 2, speed factor dropped: 0.600 J, not 30
mistake 3, strength |F| times length: 94.211 N m, not 30 J
mistake 4, same ends so same work: straight 30 J copied to north-then-east, truly 90 J
figure, 6 units per m, curve: (50.0,210.0) (80.0,207.2) (110.0,198.8) (140.0,184.7) (170.0,165.0) (200.0,139.7) (230.0,108.8) (260.0,72.2) (290.0,30.0)
figure, arrows 6 units per N, tail->head: (86,138)->(93.2,144) (86,66)->(100.4,72) (146,54)->(161.6,60) (206,54)->(221.6,60) (254,186)->(256.4,192) (254,138)->(261.2,144)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the three facts of Why it works for any route with a continuous velocity, and any field continuous along it.

- Run a route backwards, from B to A, and its work is the negative of the forward work.
- Change to a forward clock that starts and ends where the old one does, and the work stays the same.
- Force-times-chord sums close in on the work. Make every clock step short enough, and every sum lands as close as you like, whatever readings are picked.
- The hand values hold exactly: 30 J straight, 10 J on the curve, 30 J at a slow start, and −30 J from B to A.
- The table's legs hold too: −30 J north, 120 J east along the top, then 90 J and −30 J for the L-shaped routes.
- The loop gets 90 + 30 = 120 J, which is 0.1 N per metre times 40 m × 30 m.
- On the curve, 4 pieces give 9.375 J, short by 0.625 J.

The 1,024-chord sums, the 16-, 32- and 64-piece sums, the four mistakes and the figure are left to the Python and Rust checks.

```lean
-- Line integrals of a field: for a route with a continuous velocity and a field continuous along it, reversing the route flips the sign of the work, a forward change of clock leaves it unchanged, force-times-chord sums close in on it, and the card's wind gives 30, 10, −30 and 90 J on its four routes and 120 J round the loop.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Topology.Order.ProjIcc
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Tactic

open Set RealInnerProductSpace

/-- Telescoping over `Fin`: the steps of a list of numbers add up to last minus first. -/
theorem fin_sum_succ_sub_castSucc : ∀ (m : ℕ) (u : Fin (m + 1) → ℝ),
    ∑ i : Fin m, (u i.succ - u i.castSucc) = u (Fin.last m) - u 0 := by
  intro m
  induction m with
  | zero => intro u; simp
  | succ m ih =>
    intro u
    rw [Fin.sum_univ_castSucc]
    have h := ih (fun i => u i.castSucc)
    simp only [Fin.succ_castSucc] at h ⊢
    rw [h, Fin.succ_last, Fin.castSucc_zero]
    ring

/-- **Reversing the route flips the sign.** A route r(t), for clock t from a to b, has a
continuous velocity r'(t) (r is continuously differentiable: a smooth piece), and the field F is
continuous along the route. The work is ∫ from a to b of F(r(t)) · r'(t) dt. Run the same route
backwards, from B to A, by the clock s ↦ r(a + b − s). Its work is the negative of the forward work. -/
theorem line_integral_reverse_eq_neg {n : ℕ} (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (r : ℝ → EuclideanSpace ℝ (Fin n)) {a b : ℝ} (hab : a ≤ b)
    (hr : ContDiff ℝ 1 r) (hF : ContinuousOn F (r '' Icc a b)) :
    (∫ s in a..b, ⟪F (r (a + b - s)), deriv (fun s => r (a + b - s)) s⟫) =
      -∫ t in a..b, ⟪F (r t), deriv r t⟫ := by
  have hdiff : Differentiable ℝ r := hr.differentiable one_ne_zero
  have hd : ∀ s, deriv (fun s => r (a + b - s)) s = -deriv r (a + b - s) := by
    intro s
    have h1 : HasDerivAt r (deriv r (a + b - s)) (a + b - s) := (hdiff _).hasDerivAt
    have h2 : HasDerivAt (fun s : ℝ => a + b - s) (-1) s := by
      simpa using (hasDerivAt_id s).const_sub (a + b)
    have h3 := h1.scomp s h2
    have h4 : (r ∘ fun s : ℝ => a + b - s) = fun s => r (a + b - s) := rfl
    rw [h4] at h3
    rw [h3.deriv]
    simp
  simp_rw [hd, inner_neg_right]
  rw [intervalIntegral.integral_neg,
    intervalIntegral.integral_comp_sub_left (fun x => ⟪F (r x), deriv r x⟫) (a + b)]
  congr 2 <;> ring

/-- **The pace does not matter.** A route r(t), clock t from a to b, has a continuous velocity,
and the field F is continuous along it. A new clock s runs from c to d, and t = φ(s) turns it into
the old one: φ has a continuous rate of change, runs forward (never goes back), and starts at a
and ends at b. Then the work along the new-clock route r(φ(s)), ∫ from c to d of
F(r(φ(s))) · (r ∘ φ)'(s) ds, equals the work ∫ from a to b of F(r(t)) · r'(t) dt. -/
theorem line_integral_reparam_eq {n : ℕ} (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (r : ℝ → EuclideanSpace ℝ (Fin n)) (φ : ℝ → ℝ) {a b c d : ℝ} (hcd : c ≤ d)
    (hr : ContDiff ℝ 1 r) (hF : ContinuousOn F (r '' Icc a b))
    (hφ : ContDiff ℝ 1 φ) (hmono : MonotoneOn φ (Icc c d)) (hφc : φ c = a) (hφd : φ d = b) :
    (∫ s in c..d, ⟪F (r (φ s)), deriv (r ∘ φ) s⟫) = ∫ t in a..b, ⟪F (r t), deriv r t⟫ := by
  have hdiff : Differentiable ℝ r := hr.differentiable one_ne_zero
  have hφdiff : Differentiable ℝ φ := hφ.differentiable one_ne_zero
  set g : ℝ → ℝ := fun t => ⟪F (r t), deriv r t⟫ with hg
  have hd : ∀ s, deriv (r ∘ φ) s = deriv φ s • deriv r (φ s) := by
    intro s
    exact ((hdiff (φ s)).hasDerivAt.scomp s (hφdiff s).hasDerivAt).deriv
  have hint : ∀ s, ⟪F (r (φ s)), deriv (r ∘ φ) s⟫ = (g ∘ φ) s * deriv φ s := by
    intro s
    rw [hd, inner_smul_right]
    simp only [hg, Function.comp]
    ring
  simp_rw [hint]
  have hgc : ContinuousOn g (Icc a b) :=
    (hF.comp hr.continuous.continuousOn (mapsTo_image r _)).inner
      (hr.continuous_deriv le_rfl).continuousOn
  rw [intervalIntegral.integral_comp_mul_deriv' (f := φ) (f' := deriv φ) (g := g)
    (fun x _ => (hφdiff x).hasDerivAt) (hφ.continuous_deriv le_rfl).continuousOn, hφc, hφd]
  apply hgc.mono
  rintro _ ⟨x, hx, rfl⟩
  rw [uIcc_of_le hcd] at hx
  refine ⟨?_, ?_⟩
  · rw [← hφc]; exact hmono ⟨le_rfl, hcd⟩ hx hx.1
  · rw [← hφd]; exact hmono hx ⟨hcd, le_rfl⟩ hx.2

/-- **Force-times-chord sums close in on the work.** A route r(t), clock t from a to b, has a
continuous velocity, and the field F is continuous along it. Cut the clock at
a = t₀ ≤ t₁ ≤ … ≤ tₙ = b with every step shorter than δ, pick any reading τᵢ in each step, and
add F(r(τᵢ)) · (r(tᵢ) − r(tᵢ₋₁)): the wind at that reading dotted with the step's chord.
For every ε > 0 there is a δ > 0 that keeps every such sum within ε of the work
∫ from a to b of F(r(t)) · r'(t) dt, whatever readings are picked. -/
theorem chord_sums_tend_to_line_integral {n : ℕ}
    (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (r : ℝ → EuclideanSpace ℝ (Fin n)) {a b : ℝ} (hab : a ≤ b)
    (hr : ContDiff ℝ 1 r) (hF : ContinuousOn F (r '' Icc a b)) :
    ∀ ε > 0, ∃ δ > 0, ∀ (m : ℕ) (t : Fin (m + 1) → ℝ) (τ : Fin m → ℝ),
      t 0 = a → t (Fin.last m) = b →
      (∀ i : Fin m, t i.castSucc ≤ τ i ∧ τ i ≤ t i.succ) →
      (∀ i : Fin m, t i.succ - t i.castSucc < δ) →
      |(∑ i : Fin m, ⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫) -
          ∫ s in a..b, ⟪F (r s), deriv r s⟫| < ε := by
  intro ε hε
  have hdiff : Differentiable ℝ r := hr.differentiable one_ne_zero
  set p : ℝ → ℝ := fun x => (projIcc a b hab x : ℝ) with hp
  have hpc : Continuous p := continuous_subtype_val.comp continuous_projIcc
  have hpI : ∀ x ∈ Icc a b, p x = x := fun x hx => by simp [hp, projIcc_of_mem hab hx]
  have hpm : ∀ x, p x ∈ Icc a b := fun x => (projIcc a b hab x).2
  have hr' : Continuous (deriv r) := hr.continuous_deriv le_rfl
  have hrc : Continuous r := hr.continuous
  set G : ℝ → EuclideanSpace ℝ (Fin n) := fun x => F (r (p x)) with hG
  have hGc : Continuous G :=
    hF.comp_continuous (hrc.comp hpc) (fun x => mem_image_of_mem r (hpm x))
  set g : ℝ → ℝ := fun x => ⟪G x, deriv r x⟫ with hg
  have hgc : Continuous g := hGc.inner hr'
  set H : ℝ → ℝ := fun x => ∫ s in a..x, g s with hH
  have hHd : ∀ x, HasDerivAt H (g x) x := fun x =>
    (hgc.integral_hasStrictDerivAt a x).hasDerivAt
  obtain ⟨M, hM⟩ : ∃ M, ∀ x ∈ Icc a b, ‖deriv r x‖ ≤ M :=
    isCompact_Icc.exists_bound_of_continuousOn hr'.continuousOn
  have hM0 : 0 ≤ M := le_trans (norm_nonneg _) (hM a ⟨le_rfl, hab⟩)
  have hba : 0 ≤ b - a := sub_nonneg.2 hab
  set η : ℝ := ε / (2 * (M + 1) * (b - a + 1)) with hη
  have hden : 0 < 2 * (M + 1) * (b - a + 1) := by positivity
  have hη0 : 0 < η := div_pos hε hden
  have hηeq : η * (2 * (M + 1) * (b - a + 1)) = ε := by
    rw [hη]; field_simp
  have huc := (isCompact_Icc (a := a) (b := b)).uniformContinuousOn_of_continuous hGc.continuousOn
  rw [Metric.uniformContinuousOn_iff] at huc
  obtain ⟨δ, hδ, hδG⟩ := huc η hη0
  refine ⟨δ, hδ, ?_⟩
  intro m t τ h0 hlast hτ hstep
  have hmono : Monotone t := Fin.monotone_iff_le_succ.2 (fun i => (hτ i).1.trans (hτ i).2)
  have htI : ∀ j, t j ∈ Icc a b := fun j =>
    ⟨h0 ▸ hmono (Fin.zero_le j), hlast ▸ hmono (Fin.le_last j)⟩
  have hint : ∫ s in a..b, ⟪F (r s), deriv r s⟫ = H b - H a := by
    have h1 : ∫ s in a..b, ⟪F (r s), deriv r s⟫ = ∫ s in a..b, g s := by
      apply intervalIntegral.integral_congr
      intro x hx
      rw [uIcc_of_le hab] at hx
      simp [hg, hG, hpI x hx]
    rw [h1, hH]
    simp
  have htel : H b - H a = ∑ i : Fin m, (H (t i.succ) - H (t i.castSucc)) := by
    rw [← h0, ← hlast]
    exact (fin_sum_succ_sub_castSucc m (fun j => H (t j))).symm
  rw [hint, htel, ← Finset.sum_sub_distrib]
  have hterm : ∀ i : Fin m,
      |⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫ - (H (t i.succ) - H (t i.castSucc))| ≤
        η * M * (t i.succ - t i.castSucc) := by
    intro i
    have hxy : t i.castSucc ≤ t i.succ := (hτ i).1.trans (hτ i).2
    have hτI : τ i ∈ Icc a b :=
      ⟨(htI _).1.trans (hτ i).1, (hτ i).2.trans (htI _).2⟩
    have hGτ : G (τ i) = F (r (τ i)) := by simp [hG, hpI _ hτI]
    let K : ℝ → ℝ := fun s => ⟪F (r (τ i)), r s⟫ - H s
    have hK : ∀ s, HasDerivAt K (⟪F (r (τ i)), deriv r s⟫ - g s) s := by
      intro s
      have h1 := (hasDerivAt_const s (F (r (τ i)))).inner ℝ (hdiff s).hasDerivAt
      have h2 : HasDerivAt K (⟪F (r (τ i)), deriv r s⟫ + ⟪(0 : EuclideanSpace ℝ (Fin n)), r s⟫ - g s) s :=
        h1.sub (hHd s)
      convert h2 using 1
      simp
    have hb : ∀ s ∈ Ico (t i.castSucc) (t i.succ),
        ‖⟪F (r (τ i)), deriv r s⟫ - g s‖ ≤ η * M := by
      intro s hs
      have hsI : s ∈ Icc a b :=
        ⟨(htI _).1.trans hs.1, hs.2.le.trans (htI _).2⟩
      have hGs : G s = F (r s) := by simp [hG, hpI s hsI]
      have hdist : dist (G (τ i)) (G s) < η := by
        apply hδG _ hτI _ hsI
        rw [Real.dist_eq, abs_lt]
        have := hstep i
        constructor <;> linarith [(hτ i).1, (hτ i).2, hs.1, hs.2]
      rw [Real.norm_eq_abs, hg]
      simp only
      rw [← inner_sub_left]
      calc |⟪F (r (τ i)) - G s, deriv r s⟫| ≤ ‖F (r (τ i)) - G s‖ * ‖deriv r s‖ :=
            abs_real_inner_le_norm _ _
        _ ≤ η * M := by
            apply mul_le_mul _ (hM s hsI) (norm_nonneg _) hη0.le
            rw [← dist_eq_norm, ← hGτ]
            exact hdist.le
    have hmv := norm_image_sub_le_of_norm_deriv_le_segment' (f := K)
      (fun s _ => (hK s).hasDerivWithinAt) hb (t i.succ) ⟨hxy, le_rfl⟩
    rw [Real.norm_eq_abs] at hmv
    convert hmv using 2
    simp only [K, inner_sub_right]
    ring
  calc |∑ i : Fin m, (⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫ -
          (H (t i.succ) - H (t i.castSucc)))|
      ≤ ∑ i : Fin m, |⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫ -
          (H (t i.succ) - H (t i.castSucc))| := Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ i : Fin m, η * M * (t i.succ - t i.castSucc) := Finset.sum_le_sum (fun i _ => hterm i)
    _ = η * M * (b - a) := by
        rw [← Finset.mul_sum, fin_sum_succ_sub_castSucc m t, h0, hlast]
    _ < ε := by
        have h1 : η * M * (b - a) ≤ η * ((M + 1) * (b - a + 1)) := by
          apply le_trans (le_of_eq (mul_assoc _ _ _))
          apply mul_le_mul_of_nonneg_left _ hη0.le
          nlinarith
        nlinarith

-- The card's wind is (y/10, −1) N at (x, y) m; the cart goes from A (0, 0) to B (40, 30).
-- Straight route (40t, 30t): wind (3t, −1), velocity (40, 30); the work is 120/2 − 30 = 30 J.
example : (∫ t in (0 : ℝ)..1, ((30 * t / 10) * 40 + (-1) * 30)) = 30 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 60 * t ^ 2 - 30 * t ^ 1)
      ((30 * x / 10) * 40 + (-1) * 30) x := by
    intro x _
    have := ((hasDerivAt_pow 2 x).const_mul 60).sub ((hasDerivAt_pow 1 x).const_mul 30)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- The curve (40t, 30t^2): wind (3t^2, −1), velocity (40, 60t); the work is 40 − 30 = 10 J.
example : (∫ t in (0 : ℝ)..1, ((30 * t ^ 2 / 10) * 40 + (-1) * (60 * t))) = 10 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 40 * t ^ 3 - 30 * t ^ 2)
      ((30 * x ^ 2 / 10) * 40 + (-1) * (60 * x)) x := by
    intro x _
    have := ((hasDerivAt_pow 3 x).const_mul 40).sub ((hasDerivAt_pow 2 x).const_mul 30)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- Its dot product is 120t^2 − 60t, with antiderivative 40t^3 − 30t^2.
example : ∀ t : ℚ, (30 * t ^ 2 / 10) * 40 + (-1) * (60 * t) = 120 * t ^ 2 - 60 * t := by
  intro t; ring
example : (40 : ℚ) * 1 ^ 3 - 30 * 1 ^ 2 - (40 * 0 ^ 3 - 30 * 0 ^ 2) = 10 := by norm_num
-- The straight route at a slow start, (40s^2, 30s^2): velocity (80s, 60s), work 30 J again.
example : (∫ s in (0 : ℝ)..1, ((30 * s ^ 2 / 10) * (80 * s) + (-1) * (60 * s))) = 30 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 60 * t ^ 4 - 30 * t ^ 2)
      ((30 * x ^ 2 / 10) * (80 * x) + (-1) * (60 * x)) x := by
    intro x _
    have := ((hasDerivAt_pow 4 x).const_mul 60).sub ((hasDerivAt_pow 2 x).const_mul 30)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- The straight route from B to A, (40 − 40s, 30 − 30s): velocity (−40, −30), work −30 J.
example : (∫ s in (0 : ℝ)..1, ((30 * (1 - s) / 10) * (-40) + (-1) * (-30))) = -30 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 60 * t ^ 2 - 90 * t ^ 1)
      ((30 * (1 - x) / 10) * (-40) + (-1) * (-30)) x := by
    intro x _
    have := ((hasDerivAt_pow 2 x).const_mul 60).sub ((hasDerivAt_pow 1 x).const_mul 90)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- Straight route: length √(40^2 + 30^2) = 50 m, direction (40/50, 30/50) = (0.8, 0.6).
example : (40 : ℚ) ^ 2 + 30 ^ 2 = 50 ^ 2 ∧ (40 : ℚ) / 50 = 4 / 5 ∧ (30 : ℚ) / 50 = 3 / 5 := by
  norm_num
-- North leg on either edge: −1 N × 30 m = −30 J. East leg along the top: 3 N × 40 m = 120 J.
example : (-1 : ℚ) * 30 = -30 ∧ (30 : ℚ) / 10 * 40 = 120 := by norm_num
-- North, then east: −30 + 120 = 90 J. East, then north: 0 + (−30) = −30 J.
example : (-30 : ℚ) + 120 = 90 ∧ (0 : ℚ) + (-30) = -30 := by norm_num
-- The loop, out north-then-east and back along the hedge route reversed: 90 + 30 = 120 J,
-- which is 0.1 N per metre times the area 40 m × 30 m.
example : (90 : ℚ) + 30 = 120 ∧ (1 : ℚ) / 10 * (40 * 30) = 120 := by norm_num
-- On the curve, 4 force-times-chord pieces give 9.375 J = 75/8 J, short by 0.625 J = 5/8 J.
-- Piece i runs over clock [i/4, (i+1)/4]: wind at its middle (3((2i+1)/8)^2, −1), chord
-- (10, 30((i+1)^2 − i^2)/16).
example : (∑ i ∈ Finset.range 4,
    (3 * ((2 * (i : ℚ) + 1) / 8) ^ 2 * 10 + (-1) * (30 * ((i + 1) ^ 2 - i ^ 2) / 16))) = 75 / 8 := by
  norm_num [Finset.sum_range_succ]
example : (10 : ℚ) - 75 / 8 = 5 / 8 := by norm_num

#print axioms fin_sum_succ_sub_castSucc
#print axioms line_integral_reverse_eq_neg
#print axioms line_integral_reparam_eq
#print axioms chord_sums_tend_to_line_integral
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'fin_sum_succ_sub_castSucc' depends on axioms: [propext, Classical.choice, Quot.sound]
'line_integral_reverse_eq_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
'line_integral_reparam_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'chord_sums_tend_to_line_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Kill the drift.** In `F`, change `-1.0` to `0.0`. Each route gains 30 J: 60, 40, 0 and 120 J. The first assert stops the run.
> - **Sample at each piece's start.** In `chords`, use `p` for `m`. The straight sum falls about 0.06 J short; the second assert stops it.
> - **Turn the wind round.** Make the east push `-y / 10`. The loop becomes −120 J: it follows the shear's sign.

---

## The usual mistake

> [!warning]
> **Treating work as fixed by the ends.** Straight across gives 30 J; north, then east gives 90 J. Equal ends force equal work only for a gradient field, and this shearing wind is not one.
>
> - **Dropping the direction.** B to A with the A-to-B velocity gives +30 J, not −30 J.
> - **Unit direction for velocity.** 0.600 J, not 30 J: one unit of clock covers 50 m.
> - **Strength for work.** Strength times length gives 94.211, blind to direction.
> - **Whose work.** The 30 J is the wind's. At steady pace with no friction, the pusher does −30 J, holding back.

---

## Where you meet it in real life

- **Mechanics.** Work by a force along a path is this integral: [Newton's laws](../../13-Engineering%20mathematics/07-Mechanics%20and%20Structures/01-newtons-laws-work-and-energy.md).
- **Electricity.** The voltage driven round a wire loop is the electric field's line integral round it: [Magnetic fields](../../13-Engineering%20mathematics/06-Circuits%20and%20Electromagnetism/05-magnetism-and-faradays-law.md).
- **Heat engines.** A gas's work depends on its route through pressure and volume, so an engine cycle can deliver net work: [The thermodynamic laws](../../13-Engineering%20mathematics/08-Fluids%20and%20Heat/07-thermodynamic-laws-and-entropy.md).

> **Say it back**
> A line integral of a field adds the field's part along the motion times each small step. With a clock, it is the field dotted with the velocity, added over the clock. Pace does not change it; reversal flips its sign. Across the windy field, routes from A to B get 30, 10, −30 and 90 J, and a loop gets 120 J, because the wind shears.

---

## What this builds on

- [Line integrals of a function](01-scalar-line-integrals.md): adding along a route by small lengths, unsigned.
- [Gradient](../07-Several%20Variables/03-gradient-and-directional-derivatives.md): the dot product with a direction, and gradient fields.

## Where this goes next

- [Conservative fields](04-conservative-fields-and-potentials.md): fields whose work depends only on the ends.
- [Green's theorem](06-greens-theorem.md): work round a loop as the curl over the area inside.
- [Contour integrals](../../07-Complex%20analysis/03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/01-contour-integrals.md): the same sum in the complex plane.
- [Magnetic fields](../../13-Engineering%20mathematics/06-Circuits%20and%20Electromagnetism/05-magnetism-and-faradays-law.md): the voltage round a loop.
- [Newton's laws](../../13-Engineering%20mathematics/07-Mechanics%20and%20Structures/01-newtons-laws-work-and-energy.md): work and the energy it changes.
- [Continuity and Bernoulli](../../13-Engineering%20mathematics/08-Fluids%20and%20Heat/01-continuity-and-bernoulli.md): a flow added along a streamline.
- [The thermodynamic laws](../../13-Engineering%20mathematics/08-Fluids%20and%20Heat/07-thermodynamic-laws-and-entropy.md): work and heat that depend on the route.

Four routes gave four answers; which fields give one answer on every route, and how to tell without trying routes, is [Conservative fields](04-conservative-fields-and-potentials.md).

---

## Sources

Verified 2026-09-27: every link below resolves to the publisher's page.

- Strang, Gilbert, Edwin Herman et al. *Calculus Volume 3*, OpenStax. [Section 6.2, Line Integrals](https://openstax.org/books/calculus-volume-3/pages/6-2-line-integrals). The definition, the parameter formula, orientation and piecewise routes.
- Strang, Gilbert, Edwin Herman et al. *Calculus Volume 3*, OpenStax. [Section 6.3, Conservative Vector Fields](https://openstax.org/books/calculus-volume-3/pages/6-3-conservative-vector-fields). When the route stops mattering.
- Auroux, Denis, et al. *18.02SC Multivariable Calculus*, MIT OpenCourseWare, 2010. [Course page](https://ocw.mit.edu/courses/18-02sc-multivariable-calculus-fall-2010/). Work along curves, with worked problems and lecture videos.
