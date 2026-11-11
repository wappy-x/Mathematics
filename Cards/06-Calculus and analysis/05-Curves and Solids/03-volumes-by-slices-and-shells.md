# Volumes: slicing a solid into discs, washers or shells

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Curves and Solids](../README.md#s05) → Volumes

---

## General Overview

A glassblower draws the inside wall of a wine glass's bowl as one curve, 10 cm deep. At 2 cm from the stem's centre line the wall stands 2 cm high; at 4 cm out, 8 cm. Height is half of distance squared, so the rim sits 4.472136 cm out. Spin the curve round the centre line and the bowl appears. How much wine does it hold?

No box formula fits a curved bowl, but a thin piece is nearly a known shape. Cut across, like a loaf, and each slice is almost a flat coin: a short cylinder. Cut round the centre line, like tree rings, and each piece is a tube. Add thinner and thinner pieces and an integral gives the total.

Both cuts give 100 pi cubic centimetres, 314.16 ml to the brim. The skill is picking the easier cut.

**Cut a solid of revolution (a solid made by spinning a flat shape round a line) into thin discs across the line or thin tubes round it; each piece's volume is a known shape's volume, and the integral adds them.**

**What kind of fact this is:** a method; that each cut gives the true volume is a theorem, proved in Why it works by a squeeze.

### The picture: one disc and one shell, cut from the same bowl

<p align="center"><img src="../figures/volumes-by-slices-and-shells.svg" alt="The wine glass bowl in cross-section twice, to scale: on the left one thin disc cut across it, on the right one thin shell cut round its centre line" width="420"></p>

Scale 1 cm = 16 units. Dashed: the axis the wall spins round. Left: the disc from 6 to 6.5 cm high, at its middle height's radius. Right: the shell from 2 to 2.5 cm out, cut through on both sides, from the rim down to the wall's height at its middle radius.

---

## The formula

Notation first. The **axis** is the line the solid spins round. Height up it is $y$, from $a$ to $b$; the cross-section there is a circle of radius $r(y)$. The integral sign adds thin pieces from $a$ to $b$; the closing dy names the variable they stack along ([Fundamental theorem of calculus](../04-Integrals/02-fundamental-theorem-of-calculus.md)).

**Discs**, slices across the axis:

$$V = \int_a^b \pi\, r(y)^2 \, dy$$

**Read it aloud:** add each circular slice's area up the axis.

**Washers**, discs with a hole of radius $r(y)$ inside an outer radius $R(y)$:

$$V = \int_a^b \pi\,\big(R(y)^2 - r(y)^2\big)\, dy$$

**Read it aloud:** each slice is a circle's area minus the hole's.

**Shells**, thin tubes round the axis. A tube's distance from the axis is $\rho$ (Greek rho), from 0 to $c$; its length along the axis is $\ell(\rho)$:

$$V = \int_0^c 2\pi\,\rho\,\ell(\rho)\, d\rho$$

**Read it aloud:** each tube, unrolled flat, is circumference times length times thickness.

For the bowl, the wall is $y = r^2/2$, so a disc at height $y$ has $r(y)^2 = 2y$. Wine at distance $\rho$ runs from the wall to the rim: $\ell(\rho) = 10 - \rho^2/2$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $V$ | volume, cm^3 (1 cm^3 = 1 ml) | 314.159265 | — |
| $y$, $a$, $b$ | height up the axis; its ends | 0 to 10 cm | more slices |
| $r$, $R$ | slice radius; outer radius round a hole | r(y)^2 = 2y | R: more; hole: less |
| $\rho$, $c$ | shell's distance from the axis; the largest | 0 to 4.472136 cm | far shells weigh more |
| $\ell$ | shell's length along the axis | 10 − ρ^2/2 cm | more, in step |
| $H$, $h$, $T$ | depth; fill height; outer wall's drop | 10; 6.909883; 0.3 cm | grows as h squared |
| $n$, $u$, $v$, $L_n$, $U_n$ | slice count; a slice's ends; inside and outside totals | 10, 100, 1000 | squeeze tightens |
| $\pi$ | circumference over diameter | 3.14 | fixed |

### When it holds

- **A known axis.** Every radius is a distance from it. Taking the wall height as the radius spins about the other axis: 280.992589, not 314.159265.
- **An unbroken profile.** A continuous radius or length lets the squeeze close; a profile with a few breaks is split at them.
- **Each part counted once.** Shells run over distances from 0 up; counting both sides of the axis doubles the wine to 628.318531.
- **Areas subtracted, not radii.** A washer is $\pi R^2 - \pi r^2$; squaring the gap gives the glass wall 0.905869 cm^3, not 19.132299.

---

## Why it works

### Step 0: a thin piece is nearly a shape whose volume is known

A cylinder of radius r and height h holds pi r^2 h ([Prisms and cylinders](../../05-Geometry%20and%20trig/02-Circles%20and%20Solids/04-prisms-and-cylinders.md)). A slice of the bowl has a sloping wall, but the bowl widens upward. The cylinder on the slice's bottom radius sits inside it, and the one on its top radius holds it.

### Step 1: discs, squeezed

Cut the depth into $n$ equal slices; the volume lies between the inside and outside cylinder totals. With 10 slices the totals are 282.743339 and 345.575192; with 100, 311.017673 and 317.300858; with 1000, 313.845106 and 314.473425. The gap, 62.831853, then 6.283185, then 0.628319, shrinks tenfold per tenfold more slices: neighbouring cylinders cancel, leaving the top slice's area times one slice's height.

Both totals are Riemann sums, the sums whose limit is the integral ([The integral](../04-Integrals/01-riemann-integral.md)), so the volume is the integral of the slice area, 2 pi y. An antiderivative (a function whose rate is the slice area) is pi y^2; at 10 cm it gives 100 pi = 314.159265 cm^3.

### Step 2: washers subtract a hole

The glass is hollow: its outer wall is the inner one lowered 0.3 cm, so at height y the outer radius squared is 2(y + 0.3) and the hole's is 2y. Each washer's area is pi times the difference, 2 pi times 0.3: 1.884956 cm^2 at every height. Below the bowl, the outer wall's 0.3 cm deep tip is solid glass: pi times 0.3 squared. Wall plus cap: 6.09 pi = 19.132299 cm^3 of glass.

### Step 3: shells, a tube unrolled

A tube with radii u and v and length ℓ is a cylinder minus a smaller one. Factor:

$$\pi\,(v^2 - u^2)\,\ell = 2\pi \cdot \tfrac{u+v}{2} \cdot (v-u) \cdot \ell$$

Middle circumference, times thickness, times length: the tube slit and laid flat, exactly.

The wine's tube at distance $\rho$ runs from the wall, $\rho^2/2$, to the rim. Using the length at each edge brackets every tube; with 1000 tubes the totals are 313.740386 and 314.578144, gap 0.837758, closing tenfold as before. The limit is the shell integral. An antiderivative of 2 pi rho (10 − rho^2/2) is 2 pi (5 rho^2 − rho^4/8); at $\rho^2 = 20$ it gives 2 pi (100 − 50) = 314.159265 cm^3.

<details>
<summary>Detailed proof: the squeeze for any widening bowl</summary>

Let $r(y)$ grow as $y$ rises from $a$ to $b$; cut $[a, b]$ into $n$ slices of height $(b-a)/n$. A slice from $u$ to $v$ holds the cylinder of radius $r(u)$ and lies inside the one of radius $r(v)$. Summing, $L_n \le V \le U_n$, with $L_n$ on bottom radii and $U_n$ on top radii.

Each inside cylinder but the lowest is the outside cylinder of the slice below, so $U_n - L_n = \pi\big(r(b)^2 - r(a)^2\big)(b-a)/n$: for the bowl, 628.318531 over n. Both totals are Riemann sums of the continuous $\pi r(y)^2$, so both tend to its integral, and $V$, trapped between them for every n, equals it.

For shells, let $\ell(\rho)$ shrink as $\rho$ grows, and cut $[0, c]$ into $n$ tubes of width $w = c/n$. The tube from $u$ to $v$ lies between exact tubes of lengths $\ell(v)$ and $\ell(u)$, each $2\pi\cdot\tfrac{u+v}{2}\,w$ times its length by Step 3's identity. Since $2\pi\rho\,\ell(\rho)$ lies between $2\pi\rho\,\ell(v)$ and $2\pi\rho\,\ell(u)$ on the tube, its integral there lies between the same two numbers. So $V$ and the shell integral share the bracket.

This gap does not telescope: neighbouring tubes do not cancel. But each middle radius is at most $c$, so $U_n - L_n \le 2\pi c\, w \sum (\ell(u) - \ell(v)) = 2\pi c^2 \big(\ell(0) - \ell(c)\big)/n$: for the bowl, 1256.637061 over n. The gap tends to 0, so $V$ equals the shell integral. A profile that rises and falls is split where it turns.

</details>

### Step 4: choose the cut whose piece has one formula

For the wine both are easy: discs turn $y = r^2/2$ round to $r^2 = 2y$; shells use it as drawn.

For the glass, washers win: one constant area plus the cap. Shells need two pieces: out to the rim, 4.472136 cm, each tube's glass is 0.3 cm long; from there to 4.538722 cm the rim cuts the tubes off, a second formula. Both give 19.132299 cm^3.

The rule: slice so each piece has one formula over the whole range and no curve needs turning inside out.

A third road, area times the distance the region's balance point travels, is Pappus's theorem: [Centre of mass](05-centre-of-mass-and-pappus.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| slice area at height y | pi r^2 with r^2 = 2y | 2 pi y |
| add the discs, 0 to 10 cm | antiderivative pi y^2 at 10 | **100 pi = 314.159265 cm^3** |
| add the shells | 2 pi (5 rho^2 − rho^4/8) at rho^2 = 20 | 2 pi (100 − 50) = **314.159265** |
| the can round the bowl | pi × 20 × 10 | 628.318531, half is 314.159265 |
| a 150 ml pour | h = sqrt(150/pi) | 6.909883 cm |
| the glass itself, washers | 2 pi × 0.3 × 10 + pi × 0.3^2 | **6.09 pi = 19.132299 cm^3** |

Brimful, the bowl holds 314.16 ml, half the can that encloses it; Archimedes proved that half for every paraboloid, the bowl's shape, in *On Conoids and Spheroids*. A 150 ml pour reaches 6.909883 cm, over two thirds of the way up.

### How the volume grows with the fill line

Discs up to a fill height h give pi h^2: volume grows as the square of the height.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Wine in the bowl against fill height"
    x-axis "fill height (cm)" [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    y-axis "volume (ml)" 0 --> 320
    line [0.00, 3.14, 12.57, 28.27, 50.27, 78.54, 113.10, 153.94, 201.06, 254.47, 314.16]
```

One line: the wine's volume in ml at each whole centimetre of fill height, from the disc integral pi h^2.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| washer as pi (R − r)^2 | 0.905869 cm^3 of glass, not 19.132299 | squared the gap, not the areas |
| wall height used as the radius | 280.992589, not 314.159265 | spins about the other axis |
| shells from −4.472136 to 4.472136 | 628.318531, double | each tube counted twice |
| half the depth read as half full | 78.539816, a fraction 0.25 | volume grows as depth squared |

The code prints all four.

---

## Code, from first principles, and it actually runs

Only square roots and pi are imported. Two roads sharing no step, disc cylinders and exact tubes, each squeeze 314.159265, and a midpoint sum checks the shell antiderivative. The glass wall is summed both ways; a bisection, which halves the search range until it pins the height, finds the 150 ml line without the square-root formula.

### Python

```python
# Volumes by discs, washers and shells -- the check behind the card.  Only
# math is imported, for sqrt and pi; every sum and root is written out here.
# The wine glass: its inside wall stands y = r^2/2 cm above the bowl's bottom
# at r cm from the stem's axis; the bowl is 10 cm deep, rim radius sqrt(20).
import math
PI, H, T = math.pi, 10.0, 0.3          # depth, and how far the outer wall sits below
C, TOP = math.sqrt(2 * H), math.sqrt(2 * (H + T))   # rim radius; where the outer wall meets the rim's level

def discs(n):                          # cylinders inside and outside each slice
    h = H / n                          # radius^2 is 2y: smallest at a slice's bottom
    return (sum(PI * 2 * (i * h) * h for i in range(n)),
            sum(PI * 2 * ((i + 1) * h) * h for i in range(n)))

def shells(n):                         # exact tubes, length taken at each edge
    w, lo, hi = C / n, 0.0, 0.0
    for i in range(n):
        u, v = i * w, (i + 1) * w
        lo += PI * (v * v - u * u) * (H - v * v / 2)
        hi += PI * (v * v - u * u) * (H - u * u / 2)
    return lo, hi

def midpoint(f, a, b, n):              # thin slices sampled at their middles
    return sum(f(a + (i + 0.5) * (b - a) / n) for i in range(n)) * (b - a) / n

disc_exact = PI * H * H                                    # antiderivative pi y^2 at 10
shell_exact = 2 * PI * (H / 2 * C**2 - C**4 / 8)           # 2 pi (5 p^2 - p^4/8) at sqrt(20)
print(f"bowl: wall y = r^2/2 cm, depth {H:.0f} cm, rim radius {C:.6f} cm")
print(f"discs: pi x {H:.0f}^2 = {disc_exact / PI:.0f} pi = {disc_exact:.6f}; shells: 2 pi ({H / 2 * C**2:.0f} - {C**4 / 8:.0f}) = {shell_exact:.6f}")
print(f"the can round the bowl: pi x {C * C:.0f} x 10 = {PI * C * C * H:.6f} cm^3, half of it {PI * C * C * H / 2:.6f}")
for n in (10, 100, 1000):
    (a, b), (c, d) = discs(n), shells(n)
    print(f"n = {n:>4}: discs [{a:.6f}, {b:.6f}] gap {b - a:.6f}; shells [{c:.6f}, {d:.6f}] gap {d - c:.6f}")
print("fill height cm: 0 1 2 3 4 5 6 7 8 9 10")
print("volume cm^3:", " ".join(f"{PI * h * h:.2f}" for h in range(11)))
lo, hi = 0.0, H                                            # bisection: fill height for 150 ml
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if midpoint(lambda y: 2 * PI * y, 0, mid, 8) < 150 else (lo, mid)
print(f"150 ml fills to {lo:.6f} cm by bisection; sqrt(150/pi) = {math.sqrt(150 / PI):.6f} cm")
wall_exact = PI * (2 * T * H + T * T)                      # washers: constant 2 pi T, plus the cap
washer = midpoint(lambda y: PI * (2 * (y + T) - 2 * max(y, 0)), -T, H, 103000)
shell_wall = midpoint(lambda p: 2 * PI * p * (min(p * p / 2, H) - (p * p / 2 - T)), 0, TOP, 200000)
print(f"glass in the bowl: washers exact {wall_exact / PI:.2f} pi = {wall_exact:.6f}, washer sum {washer:.6f}, shell sum {shell_wall:.6f} cm^3")
print(f"each washer 2 pi T = {2 * PI * T:.6f} cm^2; shells need two pieces: rim at r = {C:.6f}, outer wall ends at r = {TOP:.6f} cm")
bad_ring = midpoint(lambda y: PI * (math.sqrt(2 * (y + T)) - math.sqrt(2 * max(y, 0)))**2, -T, H, 103000)
wrong_axis = midpoint(lambda r: PI * (r * r / 2)**2, 0, C, 100000)
double = midpoint(lambda p: 2 * PI * abs(p) * (H - p * p / 2), -C, C, 100000)
print(f"mistake, (R - r)^2 for the glass: {bad_ring:.6f} cm^3")
print(f"mistake, wall height as the radius: {wrong_axis:.6f} cm^3")
print(f"mistake, shells from -sqrt(20) to sqrt(20): {double:.6f} cm^3")
print(f"mistake, half the depth: {PI * 25:.6f} cm^3, a fraction {PI * 25 / disc_exact:.2f} of the bowl")
k, m = 16 * C, 16 * math.sqrt(12.5); print(f"figure, bottom y 200, rim y {200 - 16 * H:.2f}, control y {200 + 16 * H:.2f}, stem to y 224; rim x {90 - k:.2f} {90 + k:.2f} "
      f"{270 - k:.2f} {270 + k:.2f}; disc x {90 - m:.2f} to {90 + m:.2f}, y {200 - 16 * 6.5:.2f} to {200 - 16 * 6:.2f}; "
      f"shells x 230-238, 302-310, y 40 to {200 - 16 * 2.25**2 / 2:.2f}")
assert abs(midpoint(lambda p: 2 * PI * p * (H - p * p / 2), 0, C, 1000) - shell_exact) < 1e-3   # shell sum vs antiderivative
a, b = discs(1000); c, d = shells(1000)
assert a <= disc_exact <= b and c <= disc_exact <= d and b - a < 0.9 and d - c < 0.9
assert abs(washer - wall_exact) < 1e-6 and abs(shell_wall - wall_exact) < 1e-6
assert abs(lo - math.sqrt(150 / PI)) < 1e-9                # bisection against the formula
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
bowl: wall y = r^2/2 cm, depth 10 cm, rim radius 4.472136 cm
discs: pi x 10^2 = 100 pi = 314.159265; shells: 2 pi (100 - 50) = 314.159265
the can round the bowl: pi x 20 x 10 = 628.318531 cm^3, half of it 314.159265
n =   10: discs [282.743339, 345.575192] gap 62.831853; shells [272.376083, 355.942448] gap 83.566365
n =  100: discs [311.017673, 317.300858] gap 6.283185; shells [309.970580, 318.347951] gap 8.377371
n = 1000: discs [313.845106, 314.473425] gap 0.628319; shells [313.740386, 314.578144] gap 0.837758
fill height cm: 0 1 2 3 4 5 6 7 8 9 10
volume cm^3: 0.00 3.14 12.57 28.27 50.27 78.54 113.10 153.94 201.06 254.47 314.16
150 ml fills to 6.909883 cm by bisection; sqrt(150/pi) = 6.909883 cm
glass in the bowl: washers exact 6.09 pi = 19.132299, washer sum 19.132299, shell sum 19.132299 cm^3
each washer 2 pi T = 1.884956 cm^2; shells need two pieces: rim at r = 4.472136, outer wall ends at r = 4.538722 cm
mistake, (R - r)^2 for the glass: 0.905869 cm^3
mistake, wall height as the radius: 280.992589 cm^3
mistake, shells from -sqrt(20) to sqrt(20): 628.318531 cm^3
mistake, half the depth: 78.539816 cm^3, a fraction 0.25 of the bowl
figure, bottom y 200, rim y 40.00, control y 360.00, stem to y 224; rim x 18.45 161.55 198.45 341.55; disc x 33.43 to 146.57, y 96.00 to 104.00; shells x 230-238, 302-310, y 40 to 159.50
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`. The two outputs agree line for line.

```rust
// Volumes by discs, washers and shells -- the same check as the Python, in
// Rust, std only.  Every sum and root is written out here.  The wine glass:
// its inside wall stands y = r^2/2 cm above the bowl's bottom at r cm from the
// stem's axis; the bowl is 10 cm deep, so the rim radius is sqrt(20).
use std::f64::consts::PI;
const H: f64 = 10.0; // depth
const T: f64 = 0.3; // how far the outer wall sits below the inner one

fn discs(n: usize) -> (f64, f64) { // cylinders inside and outside each slice
    let h = H / n as f64; // radius^2 is 2y: smallest at a slice's bottom
    let lo: f64 = (0..n).map(|i| PI * 2.0 * (i as f64 * h) * h).sum();
    let hi: f64 = (0..n).map(|i| PI * 2.0 * ((i + 1) as f64 * h) * h).sum();
    (lo, hi)
}

fn shells(n: usize, c: f64) -> (f64, f64) { // exact tubes, length at each edge
    let (w, mut lo, mut hi) = (c / n as f64, 0.0, 0.0);
    for i in 0..n {
        let (u, v) = (i as f64 * w, (i + 1) as f64 * w);
        lo += PI * (v * v - u * u) * (H - v * v / 2.0);
        hi += PI * (v * v - u * u) * (H - u * u / 2.0);
    }
    (lo, hi)
}

fn midpoint(f: impl Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // slices sampled at their middles
    (0..n).map(|i| f(a + (i as f64 + 0.5) * (b - a) / n as f64)).sum::<f64>() * (b - a) / n as f64
}

fn main() {
    let c = (2.0 * H).sqrt(); // rim radius
    let disc_exact = PI * H * H; // antiderivative pi y^2 at 10
    let shell_exact = 2.0 * PI * (H / 2.0 * c.powi(2) - c.powi(4) / 8.0); // 2 pi (5 p^2 - p^4/8) at sqrt(20)
    println!("bowl: wall y = r^2/2 cm, depth {:.0} cm, rim radius {:.6} cm", H, c);
    println!("discs: pi x {:.0}^2 = {:.0} pi = {:.6}; shells: 2 pi ({:.0} - {:.0}) = {:.6}",
             H, disc_exact / PI, disc_exact, H / 2.0 * c.powi(2), c.powi(4) / 8.0, shell_exact);
    println!("the can round the bowl: pi x {:.0} x 10 = {:.6} cm^3, half of it {:.6}", c * c, PI * c * c * H, PI * c * c * H / 2.0);
    for n in [10, 100, 1000] {
        let ((a, b), (s, d)) = (discs(n), shells(n, c));
        println!("n = {:>4}: discs [{:.6}, {:.6}] gap {:.6}; shells [{:.6}, {:.6}] gap {:.6}", n, a, b, b - a, s, d, d - s);
    }
    println!("fill height cm: 0 1 2 3 4 5 6 7 8 9 10");
    let vols: Vec<String> = (0..11).map(|h| format!("{:.2}", PI * (h * h) as f64)).collect();
    println!("volume cm^3: {}", vols.join(" "));
    let (mut lo, mut hi) = (0.0, H); // bisection: fill height for 150 ml
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if midpoint(|y| 2.0 * PI * y, 0.0, mid, 8) < 150.0 { lo = mid } else { hi = mid }
    }
    println!("150 ml fills to {:.6} cm by bisection; sqrt(150/pi) = {:.6} cm", lo, (150.0 / PI).sqrt());
    let wall_exact = PI * (2.0 * T * H + T * T); // washers: constant 2 pi T, plus the cap
    let washer = midpoint(|y| PI * (2.0 * (y + T) - 2.0 * y.max(0.0)), -T, H, 103000);
    let top = (2.0 * (H + T)).sqrt();
    let shell_wall = midpoint(|p| 2.0 * PI * p * ((p * p / 2.0).min(H) - (p * p / 2.0 - T)), 0.0, top, 200000);
    println!("glass in the bowl: washers exact {:.2} pi = {:.6}, washer sum {:.6}, shell sum {:.6} cm^3",
             wall_exact / PI, wall_exact, washer, shell_wall);
    println!("each washer 2 pi T = {:.6} cm^2; shells need two pieces: rim at r = {:.6}, outer wall ends at r = {:.6} cm",
             2.0 * PI * T, c, top);
    let bad_ring = midpoint(|y| PI * ((2.0 * (y + T)).sqrt() - (2.0 * y.max(0.0)).sqrt()).powi(2), -T, H, 103000);
    let wrong_axis = midpoint(|r| PI * (r * r / 2.0).powi(2), 0.0, c, 100000);
    let double = midpoint(|p| 2.0 * PI * p.abs() * (H - p * p / 2.0), -c, c, 100000);
    println!("mistake, (R - r)^2 for the glass: {:.6} cm^3", bad_ring);
    println!("mistake, wall height as the radius: {:.6} cm^3", wrong_axis);
    println!("mistake, shells from -sqrt(20) to sqrt(20): {:.6} cm^3", double);
    println!("mistake, half the depth: {:.6} cm^3, a fraction {:.2} of the bowl", PI * 25.0, PI * 25.0 / disc_exact);
    let (k, m) = (16.0 * c, 16.0 * 12.5f64.sqrt()); // figure: 16 units per cm, y runs down
    println!("figure, bottom y 200, rim y {:.2}, control y {:.2}, stem to y 224; rim x {:.2} {:.2} {:.2} {:.2}; disc x {:.2} to {:.2}, y {:.2} to {:.2}; shells x 230-238, 302-310, y 40 to {:.2}",
             200.0 - 16.0 * H, 200.0 + 16.0 * H, 90.0 - k, 90.0 + k, 270.0 - k, 270.0 + k, 90.0 - m, 90.0 + m,
             200.0 - 16.0 * 6.5, 200.0 - 16.0 * 6.0, 200.0 - 16.0 * 2.25 * 2.25 / 2.0);
    assert!((midpoint(|p| 2.0 * PI * p * (H - p * p / 2.0), 0.0, c, 1000) - shell_exact).abs() < 1e-3); // shell sum vs antiderivative
    let ((a, b), (s, d)) = (discs(1000), shells(1000, c));
    assert!(a <= disc_exact && disc_exact <= b && s <= disc_exact && disc_exact <= d && b - a < 0.9 && d - s < 0.9);
    assert!((washer - wall_exact).abs() < 1e-6 && (shell_wall - wall_exact).abs() < 1e-6);
    assert!((lo - (150.0 / PI).sqrt()).abs() < 1e-9); // bisection against the formula
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
bowl: wall y = r^2/2 cm, depth 10 cm, rim radius 4.472136 cm
discs: pi x 10^2 = 100 pi = 314.159265; shells: 2 pi (100 - 50) = 314.159265
the can round the bowl: pi x 20 x 10 = 628.318531 cm^3, half of it 314.159265
n =   10: discs [282.743339, 345.575192] gap 62.831853; shells [272.376083, 355.942448] gap 83.566365
n =  100: discs [311.017673, 317.300858] gap 6.283185; shells [309.970580, 318.347951] gap 8.377371
n = 1000: discs [313.845106, 314.473425] gap 0.628319; shells [313.740386, 314.578144] gap 0.837758
fill height cm: 0 1 2 3 4 5 6 7 8 9 10
volume cm^3: 0.00 3.14 12.57 28.27 50.27 78.54 113.10 153.94 201.06 254.47 314.16
150 ml fills to 6.909883 cm by bisection; sqrt(150/pi) = 6.909883 cm
glass in the bowl: washers exact 6.09 pi = 19.132299, washer sum 19.132299, shell sum 19.132299 cm^3
each washer 2 pi T = 1.884956 cm^2; shells need two pieces: rim at r = 4.472136, outer wall ends at r = 4.538722 cm
mistake, (R - r)^2 for the glass: 0.905869 cm^3
mistake, wall height as the radius: 280.992589 cm^3
mistake, shells from -sqrt(20) to sqrt(20): 628.318531 cm^3
mistake, half the depth: 78.539816 cm^3, a fraction 0.25 of the bowl
figure, bottom y 200, rim y 40.00, control y 360.00, stem to y 224; rim x 18.45 161.55 198.45 341.55; disc x 33.43 to 146.57, y 96.00 to 104.00; shells x 230-238, 302-310, y 40 to 159.50
ALL CHECKS PASS
```

### Lean

Lean proves the disc, washer and shell rules for every continuous radius or length, and checks the bowl's sums.

- Discs: spin the region under a radius r(y) ≥ 0, from height a to b. The solid's volume is the integral of pi r(y)^2.
- Washers: a hole of radius r(y) sits inside an outer radius R(y), with 0 ≤ r(y) ≤ R(y). The volume is the integral of pi (R(y)^2 − r(y)^2).
- Shells: the tube at distance ρ from the axis, for ρ from 0 to c, has length ℓ(ρ) ≥ 0. The volume is the integral of 2 pi ρ ℓ(ρ).
- Each tube may start at any height. Lean also does not need the radius to grow, as the squeeze above did.
- The bowl's wall: 2 cm out it stands 2 cm high, 4 cm out 8 cm, and the rim sits where r^2 = 20.
- The slice area 2 pi y adds to 100 pi from 0 to 10 cm. The tubes 2 pi ρ (10 − ρ^2/2) add to 100 pi from 0 to √20.
- The can holds pi × 20 × 10 = 200 pi, twice the bowl. The glass is 2 pi × 0.3 × 10 + pi × 0.3^2 = 6.09 pi.
- The disc gap is 200 pi over n, and the shell gap's bound is 400 pi over n.
- Filled to half the depth, the bowl holds pi × 5^2 = 25 pi, a quarter of 100 pi.

The decimals, the slice totals, the 150 ml search, the mistake values and the chart are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 266 lines</summary>

```lean
-- Volumes: a solid made by spinning a flat region round an axis has volume equal to the disc integral of pi r squared along the axis, the washer integral of pi (R squared minus r squared), and the shell integral of 2 pi rho times the tube length, and the wine glass bowl holds 100 pi.
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Constructions.HaarToSphere

open MeasureTheory Set
open scoped Real

/-! Space is modelled as `EuclideanSpace ℝ (Fin 2) × ℝ`: a point `q.1` of the flat plane square
on (at right angles) to the axis, and a height `q.2` up the axis. The axis is the line of points
whose plane part is `0`, so a point's distance from the axis is `‖q.1‖`. The `volume` of this
space is area on the plane times length up the axis: ordinary volume in three dimensions. -/

/-- Volume from slices: a solid whose slice at height `y` has area `f y` on `[a, b]`, and is
empty elsewhere, has volume the integral of `f`. -/
lemma volume_eq_of_slices (S : Set (EuclideanSpace ℝ (Fin 2) × ℝ)) (hS : MeasurableSet S)
    (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b) (hf : ContinuousOn f (Icc a b))
    (hf0 : ∀ y ∈ Icc a b, 0 ≤ f y)
    (hslice : ∀ y, volume ((fun x => (x, y)) ⁻¹' S) = (Icc a b).indicator (fun y => ENNReal.ofReal (f y)) y) :
    volume S = ENNReal.ofReal (∫ y in a..b, f y) := by
  rw [Measure.volume_eq_prod, Measure.prod_apply_symm hS]
  simp_rw [hslice]
  rw [lintegral_indicator measurableSet_Icc,
    ← ofReal_integral_eq_lintegral_ofReal (hf.integrableOn_compact isCompact_Icc)
      ((ae_restrict_iff' measurableSet_Icc).2 (Filter.Eventually.of_forall hf0)),
    intervalIntegral.integral_of_le hab, integral_Icc_eq_integral_Ioc]

/-- A function continuous on `[a, b]`, clamped, is continuous everywhere. -/
lemma continuous_clamp (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b) (hf : ContinuousOn f (Icc a b)) :
    Continuous (fun y => f (max a (min b y))) :=
  hf.comp_continuous (by fun_prop) (fun y => ⟨le_max_left _ _, max_le hab (min_le_left _ _)⟩)

/-- Clamping leaves points of `[a, b]` alone. -/
lemma clamp_eq (a b y : ℝ) (hy : y ∈ Icc a b) : max a (min b y) = y := by
  rw [min_eq_right hy.2, max_eq_right hy.1]

#print axioms volume_eq_of_slices
#print axioms continuous_clamp
#print axioms clamp_eq

/-- Discs. Spin round the axis the region under a radius `r(y)`, for heights y from a to b, where
every radius is a distance from the axis (never negative) and the radius is an unbroken
(continuous) function of height. The solid holds the integral from a to b of the slice area
pi r(y)², exactly. -/
theorem volume_solid_of_revolution_eq_disc_integral
    (r : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hr : ContinuousOn r (Icc a b)) (hr0 : ∀ y ∈ Icc a b, 0 ≤ r y) :
    volume {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r q.2}
      = ENNReal.ofReal (∫ y in a..b, π * r y ^ 2) := by
  have hc := continuous_clamp r a b hab hr
  set r' := fun y => r (max a (min b y))
  have hS : {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r q.2}
      = {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r' q.2} := by
    ext q
    simp only [mem_setOf_eq, r']
    constructor
    · rintro ⟨h1, h2⟩; exact ⟨h1, by rwa [clamp_eq a b _ h1]⟩
    · rintro ⟨h1, h2⟩; exact ⟨h1, by rwa [clamp_eq a b _ h1] at h2⟩
  rw [hS]
  apply volume_eq_of_slices _ _ (fun y => π * r y ^ 2) a b hab (by fun_prop)
  · intro y hy; have := hr0 y hy; positivity
  · intro y
    by_cases hy : y ∈ Icc a b
    · rw [indicator_of_mem hy]
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r' q.2}
          = Metric.closedBall 0 (r y) := by
        ext x; simp [r', hy.1, hy.2]
      rw [this, EuclideanSpace.volume_closedBall_fin_two, ← ENNReal.ofReal_pow (hr0 y hy),
        ← ENNReal.ofReal_mul (by positivity), mul_comm]
    · rw [indicator_of_notMem hy]
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r' q.2} = ∅ := by
        ext x
        simp only [mem_preimage, mem_setOf_eq, mem_empty_iff_false, iff_false]
        exact fun h => hy h.1
      rw [this, measure_empty]
  · exact (measurableSet_Icc.preimage measurable_snd).inter
      (measurableSet_le (by fun_prop) (hc.measurable.comp measurable_snd))

/-- Washers. A solid of revolution with a hole: at height y, from a to b, it fills the points
farther than the hole's radius r(y) from the axis and no farther than the outer radius R(y),
the hole lying inside the outer edge (0 ≤ r(y) ≤ R(y)), both radii unbroken (continuous).
Its volume is the integral of pi R(y)² minus pi r(y)²: areas subtracted, not radii. -/
theorem volume_washer_solid_eq_integral
    (r R : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hr : ContinuousOn r (Icc a b)) (hR : ContinuousOn R (Icc a b))
    (hrR : ∀ y ∈ Icc a b, 0 ≤ r y ∧ r y ≤ R y) :
    volume {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        q.2 ∈ Icc a b ∧ r q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R q.2}
      = ENNReal.ofReal (∫ y in a..b, π * (R y ^ 2 - r y ^ 2)) := by
  have hc := continuous_clamp r a b hab hr
  have hC := continuous_clamp R a b hab hR
  set r' := fun y => r (max a (min b y))
  set R' := fun y => R (max a (min b y))
  have hS : {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        q.2 ∈ Icc a b ∧ r q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R q.2}
      = {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        q.2 ∈ Icc a b ∧ r' q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R' q.2} := by
    ext q
    simp only [mem_setOf_eq, r', R']
    constructor
    · rintro ⟨h1, h2⟩; rw [clamp_eq a b _ h1]; exact ⟨h1, h2⟩
    · rintro ⟨h1, h2⟩; rw [clamp_eq a b _ h1] at h2; exact ⟨h1, h2⟩
  rw [hS]
  apply volume_eq_of_slices _ _ (fun y => π * (R y ^ 2 - r y ^ 2)) a b hab (by fun_prop)
  · intro y hy
    have h := hrR y hy
    have : r y ^ 2 ≤ R y ^ 2 := pow_le_pow_left₀ h.1 h.2 2
    have := Real.pi_pos
    nlinarith
  · intro y
    by_cases hy : y ∈ Icc a b
    · rw [indicator_of_mem hy]
      have h := hrR y hy
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ r' q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R' q.2}
          = Metric.closedBall 0 (R y) \ Metric.closedBall 0 (r y) := by
        ext x; simp [r', R', hy.1, hy.2, and_comm]
      rw [this, measure_sdiff (Metric.closedBall_subset_closedBall h.2)
          measurableSet_closedBall.nullMeasurableSet measure_closedBall_lt_top.ne,
        EuclideanSpace.volume_closedBall_fin_two, EuclideanSpace.volume_closedBall_fin_two,
        ← ENNReal.ofReal_pow h.1, ← ENNReal.ofReal_pow (h.1.trans h.2),
        ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity),
        ← ENNReal.ofReal_sub _ (by positivity)]
      congr 1; ring
    · rw [indicator_of_notMem hy]
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ r' q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R' q.2}
          = ∅ := by
        ext x
        simp only [mem_preimage, mem_setOf_eq, mem_empty_iff_false, iff_false]
        exact fun h => hy h.1
      rw [this, measure_empty]
  · exact (measurableSet_Icc.preimage measurable_snd).inter
      ((measurableSet_lt (hc.measurable.comp measurable_snd) (by fun_prop)).inter
      (measurableSet_le (by fun_prop) (hC.measurable.comp measurable_snd)))

/-- Shells. A solid of revolution cut into tubes round the axis: the tube at distance ρ from the
axis, for ρ from 0 to c, runs up the axis from height g(ρ) for a length ℓ(ρ) ≥ 0, with g and ℓ
unbroken (continuous). Counting each distance once, from 0 up, the solid holds the integral
from 0 to c of circumference times length, 2 pi ρ ℓ(ρ). -/
theorem volume_solid_of_revolution_eq_shell_integral
    (g ℓ : ℝ → ℝ) (c : ℝ) (hc : 0 ≤ c)
    (hg : ContinuousOn g (Icc 0 c)) (hℓ : ContinuousOn ℓ (Icc 0 c))
    (hℓ0 : ∀ ρ ∈ Icc 0 c, 0 ≤ ℓ ρ) :
    volume {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g ‖q.1‖ + ℓ ‖q.1‖}
      = ENNReal.ofReal (∫ ρ in (0 : ℝ)..c, 2 * π * ρ * ℓ ρ) := by
  have hgc := continuous_clamp g 0 c hc hg
  have hℓc := continuous_clamp ℓ 0 c hc hℓ
  set g' := fun y => g (max 0 (min c y))
  set ℓ' := fun y => ℓ (max 0 (min c y))
  have hℓ'0 : ∀ y, 0 ≤ ℓ' y := fun y =>
    hℓ0 _ ⟨le_max_left _ _, max_le hc (min_le_left _ _)⟩
  have hS : {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g ‖q.1‖ + ℓ ‖q.1‖}
      = {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖} := by
    ext q
    simp only [mem_setOf_eq, g', ℓ']
    constructor
    · rintro ⟨h1, h2⟩; rw [clamp_eq 0 c _ ⟨norm_nonneg _, h1⟩]; exact ⟨h1, h2⟩
    · rintro ⟨h1, h2⟩; rw [clamp_eq 0 c _ ⟨norm_nonneg _, h1⟩] at h2; exact ⟨h1, h2⟩
  have hmeas : MeasurableSet {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖} := by
    have h1 : Measurable fun q : EuclideanSpace ℝ (Fin 2) × ℝ => g' ‖q.1‖ :=
      hgc.measurable.comp (by fun_prop)
    have h2 : Measurable fun q : EuclideanSpace ℝ (Fin 2) × ℝ => ℓ' ‖q.1‖ :=
      hℓc.measurable.comp (by fun_prop)
    exact (measurableSet_le (measurable_norm.comp measurable_fst) measurable_const).inter
      ((measurableSet_le h1 measurable_snd).inter
      (measurableSet_le measurable_snd (h1.add h2)))
  rw [hS, Measure.volume_eq_prod, Measure.prod_apply hmeas]
  have hslice : ∀ x : EuclideanSpace ℝ (Fin 2),
      volume (Prod.mk x ⁻¹' {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖})
      = ENNReal.ofReal ((Metric.closedBall (0 : EuclideanSpace ℝ (Fin 2)) c).indicator
          (fun x => ℓ' ‖x‖) x) := by
    intro x
    by_cases hx : ‖x‖ ≤ c
    · have : Prod.mk x ⁻¹' {q : EuclideanSpace ℝ (Fin 2) × ℝ |
          ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖}
          = Icc (g' ‖x‖) (g' ‖x‖ + ℓ' ‖x‖) := by
        ext y; simp [hx]
      rw [this, Real.volume_Icc, indicator_of_mem (by simpa using hx)]
      congr 1; ring
    · have : Prod.mk x ⁻¹' {q : EuclideanSpace ℝ (Fin 2) × ℝ |
          ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖} = ∅ := by
        ext y; simp [hx]
      rw [this, measure_empty, indicator_of_notMem (by simpa using hx), ENNReal.ofReal_zero]
  simp_rw [hslice]
  have hint : Integrable ((Metric.closedBall (0 : EuclideanSpace ℝ (Fin 2)) c).indicator
          (fun x => ℓ' ‖x‖)) :=
    ((hℓc.comp continuous_norm).continuousOn.integrableOn_compact (isCompact_closedBall 0 c)).integrable_indicator
      measurableSet_closedBall
  rw [← ofReal_integral_eq_lintegral_ofReal hint
    (Filter.Eventually.of_forall fun x => indicator_nonneg (fun x _ => hℓ'0 _) x)]
  congr 1
  have hfun : (Metric.closedBall (0 : EuclideanSpace ℝ (Fin 2)) c).indicator (fun x => ℓ' ‖x‖)
      = fun x => (Iic c).indicator ℓ' ‖x‖ := by
    funext x
    by_cases hx : ‖x‖ ≤ c
    · rw [indicator_of_mem (by simpa using hx), indicator_of_mem (by simpa using hx)]
    · rw [indicator_of_notMem (by simpa using hx), indicator_of_notMem (by simpa using hx)]
  rw [hfun, integral_fun_norm_addHaar volume ((Iic c).indicator ℓ')]
  have hfun2 : (fun y : ℝ => y ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin 2)) - 1) •
      (Iic c).indicator ℓ' y) = (Iic c).indicator (fun y => y * ℓ' y) := by
    funext y
    by_cases hy : y ∈ Iic c <;> simp [hy]
  rw [hfun2, setIntegral_indicator measurableSet_Iic, Ioi_inter_Iic,
    intervalIntegral.integral_of_le hc]
  have hball : volume.real (Metric.ball (0 : EuclideanSpace ℝ (Fin 2)) 1) = π := by
    simp [Measure.real, Real.pi_pos.le]
  rw [hball, finrank_euclideanSpace_fin]
  simp_rw [mul_assoc]
  rw [integral_const_mul, integral_const_mul, nsmul_eq_mul, smul_eq_mul]
  have : ∫ y in Ioc 0 c, y * ℓ' y = ∫ y in Ioc 0 c, y * ℓ y := by
    refine setIntegral_congr_fun measurableSet_Ioc fun y hy => ?_
    simp only [ℓ', clamp_eq 0 c y ⟨hy.1.le, hy.2⟩]
  rw [this]; push_cast; ring

-- The bowl's wall is y = r²/2: 2 cm out it stands 2 cm high, 4 cm out 8 cm, and the 10 cm rim
-- sits where r² = 20.
example : (2 : ℚ) ^ 2 / 2 = 2 ∧ (4 : ℚ) ^ 2 / 2 = 8 ∧ (2 : ℚ) * 10 = 20 := by norm_num
-- Discs: the slice area is pi r² = 2 pi y, and adding them from 0 to 10 cm gives 100 pi.
example : ∫ y in (0 : ℝ)..10, π * (2 * y) = 100 * π := by
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul, integral_id]
  norm_num
  ring
-- Discs by the antiderivative: pi y² at 10 is 100 pi.
example : π * 10 ^ 2 = 100 * π := by ring
-- Shells: 2 pi (5 rho² - rho⁴/8) at rho² = 20 is 2 pi (100 - 50) = 100 pi.
example : 2 * π * (5 * 20 - 20 ^ 2 / 8) = 100 * π := by ring
-- Shells, as an integral: tubes 2 pi rho (10 - rho²/2) from 0 to the rim, sqrt 20, add to 100 pi.
example : ∫ ρ in (0 : ℝ)..√20, 2 * π * ρ * (10 - ρ ^ 2 / 2) = 100 * π := by
  have h : ∀ ρ : ℝ, 2 * π * ρ * (10 - ρ ^ 2 / 2) = 20 * π * ρ ^ 1 - π * ρ ^ 3 := fun ρ => by ring
  simp_rw [h]
  rw [intervalIntegral.integral_sub, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_const_mul, integral_pow, integral_pow]
  · have h2 : (√20 : ℝ) ^ 2 = 20 := Real.sq_sqrt (by norm_num)
    have h4 : (√20 : ℝ) ^ 4 = 400 := by rw [show (4 : ℕ) = 2 * 2 from rfl, pow_mul, h2]; norm_num
    norm_num [h2, h4]
    ring
  all_goals exact (Continuous.intervalIntegrable (by fun_prop) _ _)
-- The can round the bowl: pi × 20 × 10 = 200 pi, twice the bowl's 100 pi.
example : π * 20 * 10 = 2 * (100 * π) := by ring
-- The disc squeeze's gap: pi (r(b)² - r(a)²)(b - a) = pi (20 - 0) × 10 = 200 pi, over n slices.
example : π * (20 - 0) * 10 = 200 * π := by ring
-- The shell squeeze's bound: 2 pi c² (ℓ(0) - ℓ(c)) = 2 pi × 20 × (10 - 0) = 400 pi, over n tubes.
example : 2 * π * 20 * (10 - 0) = 400 * π := by ring
-- Washers for the glass: the outer radius² 2(y + 3/10) minus the hole's 2y is 3/5 at every
-- height, so each washer is 2 pi × 3/10.
example (y : ℝ) : π * (2 * (y + 3 / 10) - 2 * y) = 2 * π * (3 / 10) := by ring
-- The glass: 2 pi × 3/10 × 10 for the wall plus pi (3/10)² for the cap is 609/100 pi (6.09 pi).
example : 2 * π * (3 / 10) * 10 + π * (3 / 10) ^ 2 = 609 / 100 * π := by ring
-- The usual mistake: filled to half the depth, 5 cm, the bowl holds pi × 5² = 25 pi, a quarter
-- of 100 pi.
example : π * 5 ^ 2 * 4 = π * 10 ^ 2 := by ring

#print axioms volume_solid_of_revolution_eq_disc_integral
#print axioms volume_washer_solid_eq_integral
#print axioms volume_solid_of_revolution_eq_shell_integral
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'volume_eq_of_slices' depends on axioms: [propext, Classical.choice, Quot.sound]
'continuous_clamp' depends on axioms: [propext, Classical.choice, Quot.sound]
'clamp_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'volume_solid_of_revolution_eq_disc_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'volume_washer_solid_eq_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'volume_solid_of_revolution_eq_shell_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Set H to 5.** Guess first: what fraction of the wine? A quarter, 78.539816; the last assert fails, since 150 ml no longer fits.
> - **Set T to 0.** Guess first: no glass, and all three wall sums print 0.000000.
> - **Replace `max(y, 0)` by `y` in the washer sum.** Guess first: below the bowl the hole's radius squared turns negative, the tip counts as a full washer, the sum reads 19.415043 and the third assert fails.
> - **Add 10000 to the list (10, 100, 1000).** Guess first: both gaps shrink tenfold again.

---

## The usual mistake

> [!warning]
> **Picking a formula before drawing the solid.** No cut is right until the axis, the spinning region and the limits are drawn. Radii are distances from the chosen axis; shell lengths run parallel to it. The bowl's curve spun about the wrong line gives 280.992589: plausible, and a different solid.
>
> The other slips are in the table above.
>
> - **Dropping the cap.** Washers over the bowl's range alone miss the solid base.

---

## Where you meet it in real life

- **Glassware.** A pour line marks the fill height a volume integral of the profile gives, as 150 ml sits at 6.909883 cm here.
- **Medical imaging.** An organ's volume from a scan is slice areas times slice thickness: discs without the circles.
- **The same glass's skin and wall.** Its surface is [Surface area](04-surface-area-of-revolution.md); the wall curve's length is [Arc length](02-arc-length.md).

> **Say it back**
> A spun solid can be cut into thin discs across its axis or thin tubes round it. A disc is pi r^2 times its thickness; a tube is circumference times length times thickness. Squeezing each sum between pieces inside and outside the solid proves the integral is the volume. Both cuts give the wine glass 100 pi, 314.16 ml. Choose the cut whose piece has one formula across the range.

---

## What this builds on

- [Fundamental theorem of calculus](../04-Integrals/02-fundamental-theorem-of-calculus.md): turns each sum of slices into an antiderivative evaluated at the ends.
- [Prisms and cylinders](../../05-Geometry%20and%20trig/02-Circles%20and%20Solids/04-prisms-and-cylinders.md): the cylinder's pi r^2 h, the volume every disc and tube is built from.

## Where this goes next

- [Centre of mass](05-centre-of-mass-and-pappus.md): the same volumes from one area and the path of its balance point.

These slices work because each is a circle. A solid whose slices are any shape at all is added one small box at a time, by [Double integrals](../08-Multiple%20Integrals/01-double-integrals.md) and [Triple integrals](../08-Multiple%20Integrals/02-triple-integrals.md).

---

## Sources

Verified 2026-09-27: every link below resolves to the publisher's page.

- Strang, Gilbert, Edwin Herman et al. *Calculus Volume 1*, section 6.2, "Determining Volumes by Slicing." OpenStax. [Section page](https://openstax.org/books/calculus-volume-1/pages/6-2-determining-volumes-by-slicing). Discs, washers and the slicing principle.
- Strang, Gilbert, Edwin Herman et al. *Calculus Volume 1*, section 6.3, "Volumes of Revolution: Cylindrical Shells." OpenStax. [Section page](https://openstax.org/books/calculus-volume-1/pages/6-3-volumes-of-revolution-cylindrical-shells). Shells, and when to prefer them.
- O'Connor, J. J., and E. F. Robertson. "Archimedes of Syracuse." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Archimedes/). Names *On Conoids and Spheroids*, on paraboloids of revolution.
