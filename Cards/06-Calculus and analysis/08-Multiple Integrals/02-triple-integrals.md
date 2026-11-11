# Triple integrals: mass, moments and centres in three dimensions

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Multiple Integrals](../README.md#s08) → Triple integrals

---

## General Overview

A cheese wheel 20 cm in radius and 10 cm tall is cut into equal wedges, each spanning 60 degrees. The rind has dried and packed tight. So density (mass per cubic centimetre) rises steadily, from 1.0 g/cm^3 at the wedge's tip, the wheel's old centre, to 1.5 g/cm^3 at the rind.

How heavy is the wedge, and where does it balance? Volume times density fails: there is no single density. Instead, cut the wedge into tiny cubes, weigh each as density times volume, and add. As the cubes shrink the sum settles on one number: the **triple integral**, the name used from here on.

Weight each cube's mass by its position, divide by the total, and the result is the **centre of mass**. The wedge weighs 2792.53 g; its centre of mass lies on its middle line, 13.1303 cm from the tip. A uniform wedge's (one with the same density throughout) lies at 12.7324 cm.

**A triple integral adds density times volume over every tiny piece of a solid; weight each piece by its position, divide by the total, and the result is the point where the solid balances.**

**What kind of fact this is:** a method, resting on a definition (the limit of cube sums) and a theorem (adding one direction at a time gives the same limit), proved in Why it works.

### The picture: the wedge seen from above

<p align="center"><img src="../figures/triple-integrals.svg" alt="Top view of a 60-degree cheese wedge of radius 20 cm, with one cylindrical cell, a dashed arc halfway out, and the centre of mass just outside the uniform centroid" width="420"></p>

Scale 1 cm = 10 units; the 10 cm height points out of the page. Density is 1.25 g/cm^3 on the dashed arc 10 cm out. The outlined cell spans 14 to 16 cm out and 12 to 24 degrees. Filled dot: the centre of mass, 13.1303 cm out. Open dot: a uniform wedge's, 12.7324 cm.

---

## The formula

Notation first, in words. Two integral signs add over a flat region ([Double integrals](01-double-integrals.md)). Three in a row, with the solid's name at the foot, add over a solid: $\iiint_E \rho\,dV$ is read "the integral over E of rho dV", where $dV$ is one tiny piece's volume and $\rho$ (rho) is density.

$$M = \iiint_E \rho\,dV \qquad Q_x = \iiint_E x\,\rho\,dV \qquad \bar{x} = \frac{Q_x}{M}$$

**Read it aloud:** mass $M$ is density times volume added over the solid; the moment $Q_x$ is the same sum with each piece also times its $x$, its distance from the tip along the wedge's middle line; the balance point $\bar{x}$ (x bar) is moment over mass. With $\rho = 1$ the first sum is plain volume.

In cylindrical coordinates ([Cylindrical and spherical coordinates](../../05-Geometry%20and%20trig/04-Coordinates%20and%20Curves/07-cylindrical-and-spherical-coordinates.md)) $r$ is distance from the wheel's axis, $\theta$ (theta) the angle from the middle line in radians, and $z$ the height. The wedge, of radius $R$, height $H$ and angle $\alpha$ (alpha), is every point with $r$ from 0 to $R$, $\theta$ from $-\alpha/2$ to $\alpha/2$, and $z$ from 0 to $H$. Density is $1 + r/40$ g/cm^3. A tiny piece has volume $dV = r\,dr\,d\theta\,dz$, so

$$M = \int_{-\alpha/2}^{\alpha/2} \int_0^R \int_0^H \left(1 + \frac{r}{40}\right) r \, dz\, dr\, d\theta$$

**Read it aloud:** add up the height, then outward, then across the angle; each piece counts density times r times three small steps.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $E$, $V$ | the solid; its volume | the wedge; 2094.40 cm^3 | more mass |
| $\rho$ | density, mass per cubic centimetre | 1 + r/40 g/cm^3: 1.0 at the tip, 1.5 at the rind | centre moves toward the denser part |
| $x$, $y$, $z$ | position in cm: x from the tip along the middle line, y across, z up | x from 0 to 20 | — |
| $r$, $\theta$ | distance from the wheel's axis; angle from the middle line, in radians | r from 0 to 20 | — |
| $R$, $H$, $\alpha$ | wheel radius; height; wedge angle | 20 cm; 10 cm; 60 degrees = 1.047198 rad | wider angle pulls the centre inward |
| $dV$, $h$ | volume of one tiny piece; side of a test cube | r dr dθ dz; 1, 0.50, 0.25 cm | smaller h, smaller gap |
| $M$, $Q_x$, $m$ | mass; moment, mass times x added up; one piece's mass | 2792.53 g; 36666.67 g cm | — |
| $\bar{x}$, $\bar{y}$, $\bar{z}$ | the centre of mass, read "x bar" and so on | 13.1303 cm, 0, 5.0000 cm | — |

### When it holds

- **A bounded solid whose surface has no volume.** Cubes the surface cuts are neither in nor out, but their volume shrinks with the cubes: the cube sum falls short of the exact mass by 45.99 g with 1 cm cubes and by 2.42 g with 0.25 cm cubes.
- **Finite density.** Density growing like 1/r^2 toward the axis gives infinite mass: r times 1/r^2 has no finite integral down to 0.
- **Continuous density.** Then all six orders of adding x, y and z agree; an integrand that changes sign and blows up at a corner can give two answers.
- **Positive total mass.** The centre divides by M; with negative "density", such as charge, it can be undefined or outside the solid.

---

## Why it works

### Step 0: small enough, density is nearly constant

Inside a small cube density hardly changes, so its mass is density times volume almost exactly. The limit of the cube sums, as the cubes shrink, is the triple integral, by definition.

### Step 1: add one direction at a time

A sum over a grid of cubes can be added in any order: each vertical column first, then rows of columns. In the limit the column sums become an integral in $z$, leaving a double integral over the base. So a triple integral is three single integrals, innermost first.

<details>
<summary>Detailed proof: the cube limit exists and equals the one-at-a-time answer</summary>

A continuous density on a closed box is uniformly continuous: for any allowed error $\varepsilon > 0$ there is a cube side $h$ below which density varies by less than $\varepsilon$ inside every cube. The sum using each cube's smallest density (lower sum) and the one using its largest (upper sum) then differ by at most $\varepsilon$ times the box's volume, and every cube sum lies between them. So all cube sums close on one number.

Each column's integral lies, cube by cube, between the smallest and largest densities times the cube's height; integrating the column totals over the base stays between the same lower and upper sums. Two numbers trapped between squeezing bounds are equal. Relabelling axes gives the other orders.

For the wedge, set density to zero outside it. The jump sits on the surface. Cubes of side $h$ touching it number about a constant over $h^2$, so their volume is about a constant times $h$, which vanishes.

</details>

### Step 2: describe the solid

In x, y and z the wedge is awkward: y runs between the straight cuts until the rind's curve takes over, so the description splits in two. In cylindrical coordinates $r$, $\theta$ and $z$ each run over a fixed range: the wedge is a box.

### Step 3: a cylindrical cell's volume is r dr dθ dz

A cell between radii $r$ and $r + dr$, across angle $d\theta$, is a slice of a ring. Its top face has area $\tfrac{1}{2}d\theta\,\left((r+dr)^2 - r^2\right) = (r + \tfrac{1}{2}dr)\,dr\,d\theta$. Times its height, the volume is $r\,dr\,d\theta\,dz$ plus a term that vanishes faster than the cell. The factor $r$ is there because an angle step is longer far out: tip cells are slivers, rind cells are fat, as the outlined cell shows.

### Step 4: the centre of mass is where the moments cancel

Pieces of mass $m$ at positions $x$ on a rod balance where the sum of $(x - \bar{x})$ times $m$ is zero ([Centre of mass](../05-Curves%20and%20Solids/05-centre-of-mass-and-pappus.md)). Solving, $\bar{x}$ is the sum of $x$ times $m$ over the sum of $m$. With shrinking cubes as pieces, the top becomes $Q_x$ and the bottom $M$.

Every piece at $y$ has a mirror at $-y$ of equal density, so $\bar{y}$ is 0. Density ignores height, so $\bar{z}$ is half of $H$: 5.0000 cm.

### Step 5: the wedge, by hand

Density depends on $r$ only, so the integrals separate: the height gives $H$, the angle $\alpha$, the radius $\int_0^R (r + r^2/40)\,dr = R^2/2 + R^3/120$. So

$$M = \alpha H \left(\frac{R^2}{2} + \frac{R^3}{120}\right) = 10.4720 \times 266.6667 = 2792.53 \text{ g}$$

For the moment, $x = r\cos\theta$. Integrating $\cos\theta$ across the angle gives $2\sin(\alpha/2)$, which is 1 here. The radius integral gains an $r$: $R^3/3 + R^4/160$. So $Q_x = 2\sin(\alpha/2)\,H\,(R^3/3 + R^4/160)$, and dividing by $M$ gives $\bar{x}$.

With density 1, the same steps give the uniform centroid (the shape's own balance point), $4R\sin(\alpha/2)/(3\alpha)$. The denser rind pulls the balance point outward, from 12.7324 to 13.1303 cm.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| volume | half of α × R^2 × H | 2094.40 cm^3 |
| radius integral, mass | 200.0000 + 66.6667 | 266.6667 |
| angle × height | 1.047198 × 10 | 10.4720 |
| mass | 10.4720 × 266.6667 | **2792.53 g** |
| radius integral, moment | 2666.6667 + 1000.0000 | 3666.6667 |
| moment | 1 × 10 × 3666.6667 | 36666.67 g cm |
| centre of mass | 36666.67 / 2792.53 | **13.1303 cm** |
| average density | 2792.53 / 2094.40 | 1.3333 g/cm^3 |

The wedge weighs 2792.53 g and balances on its middle line at mid-height, 13.1303 cm from the tip. Its average density, 1.3333 g/cm^3, beats the 1.25 halfway out: most volume lies far out.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drop the r in r dr dθ dz | 261.80, in g/cm, not g | Every cell counted as if it sat 1 cm from the axis |
| Ignore density in the centre | 12.7324 cm, not 13.1303 | The shape's balance point, not the cheese's |
| Divide the moment by volume | 17.5070 cm | g cm over cm^3 is not a length |

The code prints all three.

---

## Code, from first principles, and it actually runs

Two roads that share no arithmetic. Road one evaluates Step 5's formulas.

Road two is the definition: fill the bounding box with cubes of side 1, 0.50 and 0.25 cm, keep those whose centre is inside the wedge, add density times volume, and position times that for the moments.

It works in x, y and z, never using the factor $r$, so agreement confirms Step 3; it also finds $\bar{y}$ and $\bar{z}$ without assuming symmetry. A second case runs road two with density 1 against the uniform-centroid formula.

### Python

```python
# Triple integrals -- the check behind the card.  Standard library only.
# A 60-degree wedge cut from a cheese wheel of radius 20 cm and height 10 cm.
# Density at distance r cm from the wheel's axis: 1 + r/40 g/cm^3.
# Road one: the antiderivatives worked by hand in cylindrical coordinates.
# Road two: the definition itself.  Cut the wedge's bounding box into cubes,
# keep each cube whose centre lies in the wedge, add density times volume.
# Road two never uses the r in r dr dtheta dz.
import math
R, H, A = 20.0, 10.0, math.pi / 3              # radius, height, wedge angle
S, T = math.sin(A / 2), math.tan(A / 2)

def rho(r): return 1 + r / 40                  # density, g/cm^3

def cubes(n, dens):                            # n cubes per cm along each edge
    h = 1 / n
    m = qx = qy = qz = 0.0
    for i in range(int(R * n)):
        x = (i + 0.5) * h
        for j in range(-int(R * S * n), int(R * S * n)):
            y = (j + 0.5) * h
            if abs(y) > x * T or x * x + y * y > R * R:
                continue                       # this cube's centre is outside
            for k in range(int(H * n)):
                z = (k + 0.5) * h
                dm = dens(math.sqrt(x * x + y * y)) * h ** 3
                m, qx, qy, qz = m + dm, qx + x * dm, qy + y * dm, qz + z * dm
    return m, qx / m, qy / m, qz / m

V = A / 2 * R ** 2 * H                                  # plain volume
M = A * H * (R ** 2 / 2 + R ** 3 / 120)                 # hand: mass
QX = 2 * S * H * (R ** 3 / 3 + R ** 4 / 160)            # hand: x-moment
XU = 4 * R * S / (3 * A)                                # hand: uniform centroid
print(f"wedge: radius {R:.0f} cm, height {H:.0f} cm, angle 60 degrees = {A:.6f} rad")
print(f"hand: volume {V:.2f} cm^3, mass {M:.2f} g, x-moment {QX:.2f} g cm")
print(f"hand: centre of mass x {QX / M:.4f} cm, y 0, z {H / 2:.4f} cm")
print(f"hand: r-integrals {R**2 / 2:.4f} + {R**3 / 120:.4f} = {M / (A * H):.4f} and "
      f"{R**3 / 3:.4f} + {R**4 / 160:.4f} = {QX / (2 * S * H):.4f}; angle x height {A * H:.4f}")
print(f"hand: density {rho(0):.4f} at the tip, {rho(10):.4f} at r = 10, {rho(R):.4f} at the rind; "
      f"average {M / V:.4f} g/cm^3")
print(f"hand: uniform centroid x {XU:.4f} cm")
errs = []
for n in (1, 2, 4):
    m, xb, yb, zb = cubes(n, rho)
    errs.append(abs(m - M))
    print(f"cubes of side {1 / n:.2f} cm: mass {m:.2f} g (gap {M - m:.2f}), "
          f"centre x {xb:.4f} y {abs(yb):.4f} z {zb:.4f}")
vu, xu, _, _ = cubes(4, lambda r: 1.0)
print(f"cubes of side 0.25 cm, density 1: volume {vu:.2f} cm^3, centroid x {xu:.4f} cm")
print(f"mistake 1, drop the r in r dr dtheta dz: 'mass' {A * H * (R + R * R / 80):.2f}")
print(f"mistake 2, ignore density: centre x {XU:.4f} cm, not {QX / M:.4f}")
print(f"mistake 3, divide the moment by volume: centre x {QX / V:.4f} cm")
F = 10                                                  # figure: 1 cm = 10 units
pt = lambda r, d: f"({40 + F * r * math.cos(math.radians(d)):.2f}, {120 - F * r * math.sin(math.radians(d)):.2f})"
print(f"figure, 1 cm = {F} units; tip {pt(0, 0)}; corners {pt(R, 30)} {pt(R, -30)}; rind {pt(R, 0)}; mid-arc ends {pt(10, 30)} {pt(10, -30)}")
print(f"figure, cell r 14 to 16 cm, 12 to 24 degrees {pt(14, 12)} {pt(16, 12)} {pt(16, 24)} {pt(14, 24)}; dots {pt(QX / M, 0)} {pt(XU, 0)}")
assert abs(m - M) / M < 0.002 and abs(xb - QX / M) < 0.01    # road two meets road one
assert abs(vu - V) / V < 0.002 and abs(xu - XU) < 0.01        # uniform case, own formula
assert errs[2] < errs[0] / 4                                  # the gap closes as cubes shrink
assert abs(zb - H / 2) < 1e-9 and abs(yb) < 1e-9              # symmetry, found not assumed
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
wedge: radius 20 cm, height 10 cm, angle 60 degrees = 1.047198 rad
hand: volume 2094.40 cm^3, mass 2792.53 g, x-moment 36666.67 g cm
hand: centre of mass x 13.1303 cm, y 0, z 5.0000 cm
hand: r-integrals 200.0000 + 66.6667 = 266.6667 and 2666.6667 + 1000.0000 = 3666.6667; angle x height 10.4720
hand: density 1.0000 at the tip, 1.2500 at r = 10, 1.5000 at the rind; average 1.3333 g/cm^3
hand: uniform centroid x 12.7324 cm
cubes of side 1.00 cm: mass 2746.54 g (gap 45.99), centre x 13.1431 y 0.0000 z 5.0000
cubes of side 0.50 cm: mass 2779.66 g (gap 12.87), centre x 13.1279 y 0.0000 z 5.0000
cubes of side 0.25 cm: mass 2790.11 g (gap 2.42), centre x 13.1327 y 0.0000 z 5.0000
cubes of side 0.25 cm, density 1: volume 2092.50 cm^3, centroid x 12.7357 cm
mistake 1, drop the r in r dr dtheta dz: 'mass' 261.80
mistake 2, ignore density: centre x 12.7324 cm, not 13.1303
mistake 3, divide the moment by volume: centre x 17.5070 cm
figure, 1 cm = 10 units; tip (40.00, 120.00); corners (213.21, 20.00) (213.21, 220.00); rind (240.00, 120.00); mid-arc ends (126.60, 70.00) (126.60, 170.00)
figure, cell r 14 to 16 cm, 12 to 24 degrees (176.94, 90.89) (196.50, 86.73) (186.17, 54.92) (167.90, 63.06); dots (171.30, 120.00) (167.32, 120.00)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Triple integrals -- the same check as the Python, in Rust.  No crates.
// A 60-degree wedge cut from a cheese wheel of radius 20 cm and height 10 cm.
// Density at distance r cm from the wheel's axis: 1 + r/40 g/cm^3.
// Road one: the antiderivatives worked by hand in cylindrical coordinates.
// Road two: the definition itself.  Cut the wedge's bounding box into cubes,
// keep each cube whose centre lies in the wedge, add density times volume.
// Road two never uses the r in r dr dtheta dz.
const R: f64 = 20.0;
const H: f64 = 10.0;

fn rho(r: f64) -> f64 { 1.0 + r / 40.0 }

fn cubes(n: i64, dens: &dyn Fn(f64) -> f64) -> (f64, f64, f64, f64) {
    let a = std::f64::consts::PI / 3.0;
    let (s, t, h) = ((a / 2.0).sin(), (a / 2.0).tan(), 1.0 / n as f64);
    let (mut m, mut qx, mut qy, mut qz) = (0.0, 0.0, 0.0, 0.0);
    let jmax = (R * s * n as f64) as i64;
    for i in 0..(R * n as f64) as i64 {
        let x = (i as f64 + 0.5) * h;
        for j in -jmax..jmax {
            let y = (j as f64 + 0.5) * h;
            if y.abs() > x * t || x * x + y * y > R * R { continue } // centre outside
            for k in 0..(H * n as f64) as i64 {
                let z = (k as f64 + 0.5) * h;
                let dm = dens((x * x + y * y).sqrt()) * h * h * h;
                m += dm; qx += x * dm; qy += y * dm; qz += z * dm;
            }
        }
    }
    (m, qx / m, qy / m, qz / m)
}

fn pt(r: f64, d: f64) -> String {                // figure: 1 cm = 10 units
    let t = d.to_radians();
    format!("({:.2}, {:.2})", 40.0 + 10.0 * r * t.cos(), 120.0 - 10.0 * r * t.sin())
}

fn main() {
    let a = std::f64::consts::PI / 3.0;
    let s = (a / 2.0).sin();
    let v = a / 2.0 * R * R * H;                                       // plain volume
    let m0 = a * H * (R * R / 2.0 + R * R * R / 120.0);                // hand: mass
    let qx0 = 2.0 * s * H * (R * R * R / 3.0 + R * R * R * R / 160.0); // hand: x-moment
    let xu0 = 4.0 * R * s / (3.0 * a);                                 // hand: uniform centroid
    println!("wedge: radius {:.0} cm, height {:.0} cm, angle 60 degrees = {:.6} rad", R, H, a);
    println!("hand: volume {:.2} cm^3, mass {:.2} g, x-moment {:.2} g cm", v, m0, qx0);
    println!("hand: centre of mass x {:.4} cm, y 0, z {:.4} cm", qx0 / m0, H / 2.0);
    println!("hand: r-integrals {:.4} + {:.4} = {:.4} and {:.4} + {:.4} = {:.4}; angle x height {:.4}",
             R * R / 2.0, R * R * R / 120.0, m0 / (a * H), R * R * R / 3.0, R.powi(4) / 160.0,
             qx0 / (2.0 * s * H), a * H);
    println!("hand: density {:.4} at the tip, {:.4} at r = 10, {:.4} at the rind; average {:.4} g/cm^3",
             rho(0.0), rho(10.0), rho(R), m0 / v);
    println!("hand: uniform centroid x {:.4} cm", xu0);
    let mut errs = Vec::new();
    let (mut m, mut xb, mut yb, mut zb) = (0.0, 0.0, 0.0, 0.0);
    for n in [1_i64, 2, 4] {
        (m, xb, yb, zb) = cubes(n, &rho);
        errs.push((m - m0).abs());
        println!("cubes of side {:.2} cm: mass {:.2} g (gap {:.2}), centre x {:.4} y {:.4} z {:.4}",
                 1.0 / n as f64, m, m0 - m, xb, yb.abs(), zb);
    }
    let (vu, xu, _, _) = cubes(4, &|_r| 1.0);
    println!("cubes of side 0.25 cm, density 1: volume {:.2} cm^3, centroid x {:.4} cm", vu, xu);
    println!("mistake 1, drop the r in r dr dtheta dz: 'mass' {:.2}", a * H * (R + R * R / 80.0));
    println!("mistake 2, ignore density: centre x {:.4} cm, not {:.4}", xu0, qx0 / m0);
    println!("mistake 3, divide the moment by volume: centre x {:.4} cm", qx0 / v);
    println!("figure, 1 cm = 10 units; tip {}; corners {} {}; rind {}; mid-arc ends {} {}",
             pt(0.0, 0.0), pt(R, 30.0), pt(R, -30.0), pt(R, 0.0), pt(10.0, 30.0), pt(10.0, -30.0));
    println!("figure, cell r 14 to 16 cm, 12 to 24 degrees {} {} {} {}; dots {} {}",
             pt(14.0, 12.0), pt(16.0, 12.0), pt(16.0, 24.0), pt(14.0, 24.0), pt(qx0 / m0, 0.0), pt(xu0, 0.0));
    assert!((m - m0).abs() / m0 < 0.002 && (xb - qx0 / m0).abs() < 0.01); // road two meets road one
    assert!((vu - v).abs() / v < 0.002 && (xu - xu0).abs() < 0.01);       // uniform case, own formula
    assert!(errs[2] < errs[0] / 4.0);                                     // the gap closes as cubes shrink
    assert!((zb - H / 2.0).abs() < 1e-9 && yb.abs() < 1e-9);              // symmetry, found not assumed
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
wedge: radius 20 cm, height 10 cm, angle 60 degrees = 1.047198 rad
hand: volume 2094.40 cm^3, mass 2792.53 g, x-moment 36666.67 g cm
hand: centre of mass x 13.1303 cm, y 0, z 5.0000 cm
hand: r-integrals 200.0000 + 66.6667 = 266.6667 and 2666.6667 + 1000.0000 = 3666.6667; angle x height 10.4720
hand: density 1.0000 at the tip, 1.2500 at r = 10, 1.5000 at the rind; average 1.3333 g/cm^3
hand: uniform centroid x 12.7324 cm
cubes of side 1.00 cm: mass 2746.54 g (gap 45.99), centre x 13.1431 y 0.0000 z 5.0000
cubes of side 0.50 cm: mass 2779.66 g (gap 12.87), centre x 13.1279 y 0.0000 z 5.0000
cubes of side 0.25 cm: mass 2790.11 g (gap 2.42), centre x 13.1327 y 0.0000 z 5.0000
cubes of side 0.25 cm, density 1: volume 2092.50 cm^3, centroid x 12.7357 cm
mistake 1, drop the r in r dr dtheta dz: 'mass' 261.80
mistake 2, ignore density: centre x 12.7324 cm, not 13.1303
mistake 3, divide the moment by volume: centre x 17.5070 cm
figure, 1 cm = 10 units; tip (40.00, 120.00); corners (213.21, 20.00) (213.21, 220.00); rind (240.00, 120.00); mid-arc ends (126.60, 70.00) (126.60, 170.00)
figure, cell r 14 to 16 cm, 12 to 24 degrees (176.94, 90.89) (196.50, 86.73) (186.17, 54.92) (167.90, 63.06); dots (171.30, 120.00) (167.32, 120.00)
ALL CHECKS PASS
```

### Lean

Lean proves two general facts for every density meeting the card's conditions, and the wedge's mass and moment for every radius, height and angle.

- On a box with continuous density, adding one direction at a time gives the triple integral, in all six orders of x, y and z.
- Take a bounded solid with continuous density and positive total mass M. Masses times offsets from a point add to zero exactly when that point is the moments over M.
- The wedge of radius R, height H and angle α up to a full turn, with density 1 + r/40, has mass $M = \alpha H (R^2/2 + R^3/120)$.
- Its moment along the middle line is $Q_x = 2\sin(\alpha/2)\,H\,(R^3/3 + R^4/160)$.
- For the card's wedge, density is 1, 1.25 and 1.5 at 0, 10 and 20 cm out, and 2 sin(α/2) is 1.
- The radius integrals are 800/3 for the mass and 11000/3 for the moment.
- Exactly, the volume is 2000π/3, the mass 8000π/9 and the moment 110000/3, so the centre sits 165/(4π) cm out.
- The uniform centroid is 40/π cm out, and the average density is 4/3.
- Dropping the r gives 250π/3; dividing the moment by volume gives 55/π.

The cube sums and their gaps, the decimals, the centre's y and z, and the figure are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 382 lines</summary>

```lean
-- Triple integrals: a continuous density on a closed box can be integrated one direction at a time in any of the six orders, the centre of mass of a bounded solid with positive mass is the one point about which the density-weighted positions cancel, and the card's wedge of radius R, height H and angle α with density 1 + r/40 has mass αH(R²/2 + R³/120) and x-moment 2 sin(α/2) H (R³/3 + R⁴/160).
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Set Real MeasureTheory

theorem swap2_aux {g : ℝ → ℝ → ℝ} {s t : Set ℝ}
    (hg : IntegrableOn (Function.uncurry g) (s ×ˢ t)) :
    ∫ x in s, ∫ y in t, g x y = ∫ y in t, ∫ x in s, g x y := by
  apply integral_integral_swap
  rw [Measure.prod_restrict, ← Measure.volume_eq_prod]
  exact hg

#print axioms swap2_aux

theorem fiber_aux {F : ℝ → ℝ → ℝ → ℝ} {s t u : Set ℝ}
    (hs : IsCompact s) (ht : IsCompact t) (hu : IsCompact u)
    (hF : ContinuousOn (fun q : (ℝ × ℝ) × ℝ => F q.1.1 q.1.2 q.2) ((s ×ˢ t) ×ˢ u)) :
    IntegrableOn (fun p : ℝ × ℝ => ∫ z in u, F p.1 p.2 z) (s ×ˢ t) := by
  have h1 : IntegrableOn (fun q : (ℝ × ℝ) × ℝ => F q.1.1 q.1.2 q.2) ((s ×ˢ t) ×ˢ u) :=
    hF.integrableOn_compact ((hs.prod ht).prod hu)
  have h2 : Integrable (fun q : (ℝ × ℝ) × ℝ => F q.1.1 q.1.2 q.2)
      ((volume.restrict (s ×ˢ t)).prod (volume.restrict u)) := by
    rw [Measure.prod_restrict, ← Measure.volume_eq_prod]
    exact h1
  exact h2.integral_prod_left

#print axioms fiber_aux

theorem triple_aux {ρ : ℝ × ℝ × ℝ → ℝ} {s t u : Set ℝ}
    (hs : IsCompact s) (ht : IsCompact t) (hu : IsCompact u)
    (hms : MeasurableSet s)
    (hρ : ContinuousOn ρ (s ×ˢ t ×ˢ u)) :
    ∫ p in s ×ˢ t ×ˢ u, ρ p = ∫ x in s, ∫ y in t, ∫ z in u, ρ (x, y, z) := by
  rw [Measure.volume_eq_prod, setIntegral_prod _ (hρ.integrableOn_compact (hs.prod (ht.prod hu)))]
  refine setIntegral_congr_fun hms fun x hx => ?_
  rw [Measure.volume_eq_prod, setIntegral_prod]
  refine ContinuousOn.integrableOn_compact (ht.prod hu) ?_
  refine hρ.comp (by fun_prop) ?_
  intro q hq
  exact ⟨hx, hq⟩

#print axioms triple_aux

/-- **Adding one direction at a time.** Let ρ be a density on the closed box
[a₁, b₁] × [a₂, b₂] × [a₃, b₃] in space, with no jumps there (continuous on the box). Then the
triple integral of ρ over the box (Mathlib's integral for the volume on ℝ × ℝ × ℝ) equals the
three single integrals done one after another, and all six orders of adding x, y and z give the
same number. The first order is the card's: each vertical column in z first, then y, then x. -/
theorem triple_integral_eq_iterated {ρ : ℝ × ℝ × ℝ → ℝ} {a₁ b₁ a₂ b₂ a₃ b₃ : ℝ}
    (hρ : ContinuousOn ρ (Icc a₁ b₁ ×ˢ Icc a₂ b₂ ×ˢ Icc a₃ b₃)) :
    let M := ∫ p in Icc a₁ b₁ ×ˢ Icc a₂ b₂ ×ˢ Icc a₃ b₃, ρ p
    (M = ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ρ (x, y, z)) ∧
    (M = ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ρ (x, y, z)) ∧
    (M = ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ρ (x, y, z)) ∧
    (M = ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ρ (x, y, z)) ∧
    (M = ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ρ (x, y, z)) ∧
    (M = ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ρ (x, y, z)) := by
  intro M
  have c1 := isCompact_Icc (a := a₁) (b := b₁)
  have c2 := isCompact_Icc (a := a₂) (b := b₂)
  have c3 := isCompact_Icc (a := a₃) (b := b₃)
  have h1 : M = ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ρ (x, y, z) :=
    triple_aux c1 c2 c3 measurableSet_Icc hρ
  have h2 : M = ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ρ (x, y, z) := by
    rw [h1]
    refine setIntegral_congr_fun measurableSet_Icc fun x hx => ?_
    refine swap2_aux (g := fun y z => ρ (x, y, z)) ?_
    refine ContinuousOn.integrableOn_compact (c2.prod c3) ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hx, hq⟩
  have h3 : M = ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ρ (x, y, z) := by
    rw [h1]
    refine swap2_aux (g := fun x y => ∫ z in Icc a₃ b₃, ρ (x, y, z)) ?_
    refine fiber_aux (F := fun x y z => ρ (x, y, z)) c1 c2 c3 ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.1.1, hq.1.2, hq.2⟩
  have h4 : M = ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ρ (x, y, z) := by
    rw [h3]
    refine setIntegral_congr_fun measurableSet_Icc fun y hy => ?_
    refine swap2_aux (g := fun x z => ρ (x, y, z)) ?_
    refine ContinuousOn.integrableOn_compact (c1.prod c3) ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.1, hy, hq.2⟩
  have h5 : M = ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ρ (x, y, z) := by
    rw [h2]
    refine swap2_aux (g := fun x z => ∫ y in Icc a₂ b₂, ρ (x, y, z)) ?_
    refine fiber_aux (F := fun x z y => ρ (x, y, z)) c1 c3 c2 ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.1.1, hq.2, hq.1.2⟩
  have h6 : M = ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ρ (x, y, z) := by
    rw [h4]
    refine swap2_aux (g := fun y z => ∫ x in Icc a₁ b₁, ρ (x, y, z)) ?_
    refine fiber_aux (F := fun y z x => ρ (x, y, z)) c2 c3 c1 ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.2, hq.1.1, hq.1.2⟩
  exact ⟨h1, h2, h3, h4, h5, h6⟩

/-- **The centre of mass is where the moments cancel.** Take a bounded solid E in space (a
bounded measurable set) and a density ρ with no jumps (continuous). Suppose the total mass
M = ∫_E ρ dV is positive. Then a point c is a balance point, meaning the pieces' masses times
their offsets from c add to zero (∫_E ρ(p) (p − c) dV = 0), exactly when c is the moment
∫_E ρ(p) p dV divided by the mass M. In coordinates: x̄ = Q_x / M, and the same for y and z. -/
theorem centre_of_mass_balances {E : Set (ℝ × ℝ × ℝ)} {ρ : ℝ × ℝ × ℝ → ℝ}
    (hE : MeasurableSet E) (hEb : Bornology.IsBounded E) (hρ : Continuous ρ)
    (hM : 0 < ∫ p in E, ρ p) (c : ℝ × ℝ × ℝ) :
    (∫ p in E, ρ p • (p - c)) = 0 ↔ c = (∫ p in E, ρ p) ⁻¹ • ∫ p in E, ρ p • p := by
  have hK := hEb.isCompact_closure
  have i1 : IntegrableOn ρ E := (hρ.continuousOn.integrableOn_compact hK).mono_set subset_closure
  have i2 : IntegrableOn (fun p => ρ p • p) E :=
    ((hρ.smul continuous_id).continuousOn.integrableOn_compact hK).mono_set subset_closure
  have i3 : IntegrableOn (fun p => ρ p • c) E := i1.smul_const c
  simp_rw [smul_sub]
  rw [integral_sub i2 i3, integral_smul_const, sub_eq_zero, eq_inv_smul_iff₀ hM.ne', eq_comm]

/-- Two angles in `(-π, π]` with the same cosine and sine are equal. -/
theorem angle_eq_aux {θ θ' : ℝ} (h : θ ∈ Ioc (-π) π) (h' : θ' ∈ Ioc (-π) π)
    (hc : cos θ' = cos θ) (hs : sin θ' = sin θ) : θ' = θ := by
  have e1 := Complex.arg_cos_add_sin_mul_I h
  have e2 := Complex.arg_cos_add_sin_mul_I h'
  rw [← Complex.ofReal_cos, ← Complex.ofReal_sin] at e1 e2
  rw [hc, hs] at e2
  rw [← e2, e1]

#print axioms angle_eq_aux

/-- A point of the open polar strip that lands in the wedge comes from the wedge's own box. -/
theorem wedge_polar_aux {R α r θ : ℝ} (hα : α ≤ 2 * π) (hr : 0 < r) (hθ1 : -π < θ)
    (hθ2 : θ < π)
    (h : ∃ r' θ' : ℝ, 0 ≤ r' ∧ r' ≤ R ∧ -(α / 2) ≤ θ' ∧ θ' ≤ α / 2 ∧
      r * cos θ = r' * cos θ' ∧ r * sin θ = r' * sin θ') :
    r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 := by
  obtain ⟨r', θ', hr0, hrR, ht1, ht2, hx, hy⟩ := h
  have hsq : r' ^ 2 = r ^ 2 := by
    have e : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = (r' * cos θ') ^ 2 + (r' * sin θ') ^ 2 := by
      rw [hx, hy]
    have a := cos_sq_add_sin_sq θ
    have b := cos_sq_add_sin_sq θ'
    linear_combination (-1 : ℝ) * e + r ^ 2 * a - r' ^ 2 * b
  have hrr : r' = r := (sq_eq_sq₀ hr0 hr.le).1 hsq
  subst hrr
  have hc : cos θ' = cos θ := (mul_left_cancel₀ hr.ne' hx).symm
  have hs : sin θ' = sin θ := (mul_left_cancel₀ hr.ne' hy).symm
  have hθ : θ ∈ Ioc (-π) π := ⟨hθ1, hθ2.le⟩
  rcases eq_or_lt_of_le (show -π ≤ θ' by linarith) with h0 | h0
  · exfalso
    rw [← h0, sin_neg, sin_pi] at hs
    rw [← h0, cos_neg, cos_pi] at hc
    have e1 := Complex.arg_cos_add_sin_mul_I hθ
    rw [← Complex.ofReal_cos, ← Complex.ofReal_sin, ← hc, ← hs] at e1
    simp at e1
    linarith
  · have := angle_eq_aux hθ ⟨h0, by linarith⟩ hc hs
    subst this
    exact ⟨hrR, ht1, ht2⟩

#print axioms wedge_polar_aux

/-- The flat wedge (the cross-section of the solid wedge). -/
def wedgeD (R α : ℝ) : Set (ℝ × ℝ) :=
  {q | ∃ r θ : ℝ, 0 ≤ r ∧ r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 ∧ q.1 = r * cos θ ∧ q.2 = r * sin θ}

#print axioms wedgeD

theorem wedgeD_eq (R α : ℝ) : wedgeD R α =
    (fun p : ℝ × ℝ => (p.1 * cos p.2, p.1 * sin p.2)) '' (Icc 0 R ×ˢ Icc (-(α / 2)) (α / 2)) := by
  ext ⟨x, y⟩
  simp only [wedgeD, mem_ofPred_eq, mem_image, mem_prod, mem_Icc, Prod.exists, Prod.mk.injEq]
  constructor
  · rintro ⟨r, θ, h1, h2, h3, h4, h5, h6⟩
    exact ⟨r, θ, ⟨⟨h1, h2⟩, h3, h4⟩, h5.symm, h6.symm⟩
  · rintro ⟨r, θ, ⟨⟨h1, h2⟩, h3, h4⟩, h5, h6⟩
    exact ⟨r, θ, h1, h2, h3, h4, h5.symm, h6.symm⟩

#print axioms wedgeD_eq

theorem wedgeD_compact (R α : ℝ) : IsCompact (wedgeD R α) := by
  rw [wedgeD_eq]
  exact (isCompact_Icc.prod isCompact_Icc).image (by fun_prop)

#print axioms wedgeD_compact

/-- Integrating along the height of the solid wedge. -/
theorem wedge_height_aux {R H α : ℝ} (hH : 0 ≤ H) (F : ℝ × ℝ → ℝ) :
    let E : Set (ℝ × ℝ × ℝ) := {p | ∃ r θ : ℝ, 0 ≤ r ∧ r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 ∧
      p.1 = r * cos θ ∧ p.2.1 = r * sin θ ∧ 0 ≤ p.2.2 ∧ p.2.2 ≤ H}
    (∫ p in E, F (p.1, p.2.1)) = (∫ q in wedgeD R α, F q) * H := by
  intro E
  have hpre : (MeasurableEquiv.prodAssoc : (ℝ × ℝ) × ℝ ≃ᵐ ℝ × ℝ × ℝ) ⁻¹' E =
      wedgeD R α ×ˢ Icc 0 H := by
    ext ⟨⟨x, y⟩, z⟩
    simp only [E, wedgeD, mem_preimage, MeasurableEquiv.prodAssoc, MeasurableEquiv.coe_mk,
      Equiv.prodAssoc_apply, mem_ofPred_eq, mem_prod, mem_Icc]
    constructor
    · rintro ⟨r, θ, h1, h2, h3, h4, h5, h6, h7, h8⟩
      exact ⟨⟨r, θ, h1, h2, h3, h4, h5, h6⟩, h7, h8⟩
    · rintro ⟨⟨r, θ, h1, h2, h3, h4, h5, h6⟩, h7, h8⟩
      exact ⟨r, θ, h1, h2, h3, h4, h5, h6, h7, h8⟩
  rw [← volume_preserving_prodAssoc.setIntegral_preimage_emb
    MeasurableEquiv.prodAssoc.measurableEmbedding, hpre]
  have : ∀ q : (ℝ × ℝ) × ℝ,
      F ((MeasurableEquiv.prodAssoc q).1, (MeasurableEquiv.prodAssoc q).2.1) = F q.1 * 1 := by
    rintro ⟨⟨x, y⟩, z⟩; simp [MeasurableEquiv.prodAssoc]
  simp_rw [this]
  rw [Measure.volume_eq_prod, setIntegral_prod_mul F (fun _ : ℝ => (1 : ℝ))]
  simp [hH]

#print axioms wedge_height_aux

/-- Polar coordinates on the flat wedge. -/
theorem wedge_polar_change {R α : ℝ} (hα : α ≤ 2 * π) (F : ℝ × ℝ → ℝ) :
    (∫ q in wedgeD R α, F q) =
      ∫ p in Icc 0 R ×ˢ Icc (-(α / 2)) (α / 2), p.1 * F (p.1 * cos p.2, p.1 * sin p.2) := by
  set K : Set (ℝ × ℝ) := Icc 0 R ×ˢ Icc (-(α / 2)) (α / 2) with hKdef
  have hK : MeasurableSet K := measurableSet_Icc.prod measurableSet_Icc
  have hT : MeasurableSet polarCoord.target := by
    rw [polarCoord_target]; exact measurableSet_Ioi.prod measurableSet_Ioo
  rw [← integral_indicator (wedgeD_compact R α).isClosed.measurableSet,
    ← integral_comp_polarCoord_symm]
  have step : ∫ p in polarCoord.target, p.1 • (wedgeD R α).indicator F (polarCoord.symm p) =
      ∫ p in polarCoord.target,
        K.indicator (fun p => p.1 * F (p.1 * cos p.2, p.1 * sin p.2)) p := by
    refine setIntegral_congr_fun hT fun p hp => ?_
    obtain ⟨r, θ⟩ := p
    rw [polarCoord_target] at hp
    simp only [mem_prod, mem_Ioi, mem_Ioo] at hp
    obtain ⟨hr, hθ1, hθ2⟩ := hp
    simp only [polarCoord_symm_apply, smul_eq_mul]
    by_cases hp : (r, θ) ∈ K
    · rw [indicator_of_mem hp, indicator_of_mem]
      simp only [hKdef, mem_prod, mem_Icc] at hp
      exact ⟨r, θ, hp.1.1, hp.1.2, hp.2.1, hp.2.2, rfl, rfl⟩
    · rw [indicator_of_notMem hp, indicator_of_notMem, mul_zero]
      intro hm
      apply hp
      obtain ⟨r', θ', h1, h2, h3, h4, h5, h6⟩ := hm
      have := wedge_polar_aux hα hr hθ1 hθ2 ⟨r', θ', h1, h2, h3, h4, h5, h6⟩
      simp only [hKdef, mem_prod, mem_Icc]
      exact ⟨⟨hr.le, this.1⟩, this.2⟩
  rw [step, setIntegral_indicator hK]
  refine setIntegral_congr_set ?_
  rw [ae_eq_set]
  constructor
  · rw [sdiff_eq_empty.2 inter_subset_right, measure_empty]
  · have hsub : K \ (polarCoord.target ∩ K) ⊆ ({0} ×ˢ univ) ∪ (univ ×ˢ {-π, π}) := by
      rintro ⟨r, θ⟩ ⟨hpK, hpT⟩
      simp only [hKdef, mem_prod, mem_Icc] at hpK
      rw [polarCoord_target] at hpT
      simp only [mem_inter_iff, mem_prod, mem_Ioi, mem_Ioo, not_and_or, not_lt] at hpT
      simp only [mem_union, mem_prod, mem_singleton_iff, mem_univ, and_true, true_and,
        mem_insert_iff]
      rcases hpT with (h | h | h) | h
      · left; linarith
      · right; left; linarith
      · right; right; linarith
      · exact absurd hpK h
    refine measure_mono_null hsub (measure_union_null ?_ ?_)
    · rw [Measure.volume_eq_prod, Measure.prod_prod]; simp
    · rw [Measure.volume_eq_prod, Measure.prod_prod]
      rw [(Set.toFinite ({-π, π} : Set ℝ)).measure_zero, mul_zero]

#print axioms wedge_polar_change

theorem sqrt_polar_aux {r θ : ℝ} (hr : 0 ≤ r) :
    √((r * cos θ) ^ 2 + (r * sin θ) ^ 2) = r := by
  rw [show (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 by
    linear_combination r ^ 2 * cos_sq_add_sin_sq θ]
  exact sqrt_sq hr

#print axioms sqrt_polar_aux

theorem Icc_integral_aux {a b : ℝ} (hab : a ≤ b) (f : ℝ → ℝ) :
    ∫ x in Icc a b, f x = ∫ x in a..b, f x := by
  rw [integral_Icc_eq_integral_Ioc, intervalIntegral.integral_of_le hab]

#print axioms Icc_integral_aux

theorem radial_mass_aux (R : ℝ) :
    ∫ r in (0 : ℝ)..R, r * (1 + r / 40) = R ^ 2 / 2 + R ^ 3 / 120 := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun r : ℝ => r ^ 2 / 2 + r ^ 3 / 120) (fun x _ => ?_)
    ((by fun_prop : Continuous fun r : ℝ => r * (1 + r / 40)).intervalIntegrable _ _)]
  · ring
  · have := ((hasDerivAt_pow 2 x).div_const 2).add ((hasDerivAt_pow 3 x).div_const 120)
    convert this using 1
    push_cast; ring

#print axioms radial_mass_aux

theorem radial_moment_aux (R : ℝ) :
    ∫ r in (0 : ℝ)..R, r * r * (1 + r / 40) = R ^ 3 / 3 + R ^ 4 / 160 := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun r : ℝ => r ^ 3 / 3 + r ^ 4 / 160) (fun x _ => ?_)
    ((by fun_prop : Continuous fun r : ℝ => r * r * (1 + r / 40)).intervalIntegrable _ _)]
  · ring
  · have := ((hasDerivAt_pow 3 x).div_const 3).add ((hasDerivAt_pow 4 x).div_const 160)
    convert this using 1
    push_cast; ring

#print axioms radial_moment_aux

/-- **The cheese wedge, by hand.** The wedge of radius R, height H and angle α (in radians, at
most a full turn 2π) is every point (r cos θ, r sin θ, z) with r from 0 to R, θ from −α/2 to
α/2 and z from 0 to H. Its density at distance r = √(x² + y²) from the wheel's axis is
1 + r/40. Then its mass is M = αH(R²/2 + R³/120), and its moment along the middle line,
Q_x = ∫ x ρ dV, is 2 sin(α/2) H (R³/3 + R⁴/160). -/
theorem wedge_mass_and_moment {R H α : ℝ} (hR : 0 ≤ R) (hH : 0 ≤ H) (hα₀ : 0 ≤ α)
    (hα : α ≤ 2 * π) :
    let E : Set (ℝ × ℝ × ℝ) := {p | ∃ r θ : ℝ, 0 ≤ r ∧ r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 ∧
      p.1 = r * cos θ ∧ p.2.1 = r * sin θ ∧ 0 ≤ p.2.2 ∧ p.2.2 ≤ H}
    (∫ p in E, (1 + √(p.1 ^ 2 + p.2.1 ^ 2) / 40)) = α * H * (R ^ 2 / 2 + R ^ 3 / 120) ∧
    (∫ p in E, p.1 * (1 + √(p.1 ^ 2 + p.2.1 ^ 2) / 40)) =
      2 * sin (α / 2) * H * (R ^ 3 / 3 + R ^ 4 / 160) := by
  intro E
  have hα2 : -(α / 2) ≤ α / 2 := by linarith
  constructor
  · refine (wedge_height_aux (R := R) (α := α) hH
      (fun q => 1 + √(q.1 ^ 2 + q.2 ^ 2) / 40)).trans ?_
    rw [wedge_polar_change hα]
    rw [setIntegral_congr_fun (measurableSet_Icc.prod measurableSet_Icc)
      (g := fun z : ℝ × ℝ => (z.1 * (1 + z.1 / 40)) * (fun _ : ℝ => (1 : ℝ)) z.2) ?_]
    · rw [Measure.volume_eq_prod, setIntegral_prod_mul (fun r : ℝ => r * (1 + r / 40))
        (fun _ : ℝ => (1 : ℝ)), Icc_integral_aux hR, radial_mass_aux]
      simp only [integral_const, MeasurableSet.univ, measureReal_restrict_apply, univ_inter,
        Real.volume_real_Icc_of_le hα2, smul_eq_mul, mul_one]
      ring
    · rintro ⟨r, θ⟩ hp
      simp only [mem_prod, mem_Icc] at hp
      simp only [sqrt_polar_aux hp.1.1, mul_one]
  · refine (wedge_height_aux (R := R) (α := α) hH
      (fun q => q.1 * (1 + √(q.1 ^ 2 + q.2 ^ 2) / 40))).trans ?_
    rw [wedge_polar_change hα]
    rw [setIntegral_congr_fun (measurableSet_Icc.prod measurableSet_Icc)
      (g := fun z : ℝ × ℝ => (z.1 * z.1 * (1 + z.1 / 40)) * cos z.2) ?_]
    · rw [Measure.volume_eq_prod, setIntegral_prod_mul (fun r : ℝ => r * r * (1 + r / 40))
        cos, Icc_integral_aux hR, radial_moment_aux, Icc_integral_aux hα2, integral_cos,
        sin_neg]
      ring
    · rintro ⟨r, θ⟩ hp
      simp only [mem_prod, mem_Icc] at hp
      simp only [sqrt_polar_aux hp.1.1]
      ring

-- The card's wedge: R = 20 cm, H = 10 cm, α = 60 degrees = π/3 radians.
-- Density 1 + r/40: 1 at the tip, 5/4 (1.25) halfway out at r = 10, 3/2 (1.5) at the rind.
example : (1 : ℚ) + 0 / 40 = 1 ∧ (1 : ℚ) + 10 / 40 = 5 / 4 ∧ (1 : ℚ) + 20 / 40 = 3 / 2 := by
  norm_num
-- The radius integral for the mass: 200 + 66.6667 = 800/3 (266.6667).
example : (20 : ℚ) ^ 2 / 2 + 20 ^ 3 / 120 = 800 / 3 := by norm_num
-- The radius integral for the moment: 2666.6667 + 1000 = 11000/3 (3666.6667).
example : (20 : ℚ) ^ 3 / 3 + 20 ^ 4 / 160 = 11000 / 3 := by norm_num
-- The angle factor 2 sin(α/2) is 2 sin(π/6) = 1.
example : 2 * sin (π / 3 / 2) = 1 := by
  rw [show π / 3 / 2 = π / 6 by ring, sin_pi_div_six]; norm_num
-- Volume: α/2 × R² × H = 2000π/3 cm³ (2094.40).
example : π / 3 / 2 * 20 ^ 2 * 10 = 2000 * π / 3 := by ring
-- Mass: α H (R²/2 + R³/120) = 8000π/9 g (2792.53).
example : π / 3 * 10 * (20 ^ 2 / 2 + 20 ^ 3 / 120) = 8000 * π / 9 := by ring
-- Moment: 1 × 10 × 11000/3 = 110000/3 g cm (36666.67).
example : (1 : ℚ) * 10 * (11000 / 3) = 110000 / 3 := by norm_num
-- Centre of mass: (110000/3) / (8000π/9) = 165/(4π) cm (13.1303).
example : (110000 / 3) / (8000 * π / 9) = 165 / (4 * π) := by
  field_simp [pi_ne_zero]; ring
-- Uniform centroid: 4R sin(α/2)/(3α) = 40/π cm (12.7324).
example : 4 * 20 * sin (π / 3 / 2) / (3 * (π / 3)) = 40 / π := by
  rw [show π / 3 / 2 = π / 6 by ring, sin_pi_div_six]; field_simp [pi_ne_zero]; ring
-- Average density: mass over volume, (8000π/9) / (2000π/3) = 4/3 g/cm³ (1.3333).
example : (8000 * π / 9) / (2000 * π / 3) = 4 / 3 := by
  field_simp [pi_ne_zero]; ring
-- Mistake 1, drop the r: α H (R + R²/80) = 250π/3 (261.80).
example : π / 3 * 10 * (20 + 20 ^ 2 / 80) = 250 * π / 3 := by ring
-- Mistake 3, divide the moment by volume: (110000/3) / (2000π/3) = 55/π (17.5070).
example : (110000 / 3) / (2000 * π / 3) = 55 / π := by
  field_simp [pi_ne_zero]; ring

#print axioms triple_integral_eq_iterated
#print axioms centre_of_mass_balances
#print axioms wedge_mass_and_moment
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'swap2_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'fiber_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'triple_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'angle_eq_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedge_polar_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedgeD' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedgeD_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedgeD_compact' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedge_height_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedge_polar_change' depends on axioms: [propext, Classical.choice, Quot.sound]
'sqrt_polar_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'Icc_integral_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'radial_mass_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'radial_moment_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'triple_integral_eq_iterated' depends on axioms: [propext, Classical.choice, Quot.sound]
'centre_of_mass_balances' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedge_mass_and_moment' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Density 1 everywhere.** Guess first: the centre moves toward the tip, to the uniform centroid, 12.7324 cm.
> - **A taller wheel, H = 20.** Guess first: mass doubles, the balance point along x stays put, and the centre's height doubles.
> - **Delete the inside test in the cube loop.** Guess first: the sum weighs the whole bounding box and the first assert fails.

---

## The usual mistake

> [!warning]
> **Dropping the r in r dr dθ dz.** The wedge is a box in $r$, $\theta$ and $z$, yet its cells are not equal: an angle step is longer far out. Without the $r$ the "mass" is 261.80, in grams per centimetre: a length went missing.
>
> - **The density halfway out as the average.** 1.25 g/cm^3 against a true average of 1.3333: too little mass.
> - **The angle in degrees.** $\alpha$ must be in radians: 1.047198, not 60.
> - **Box bounds for a non-box.** Running y over a fixed range weighs a rectangle of cheese that was never there.

---

## Where you meet it in real life

- **Medical scanners.** A CT scan reports density in small cubes (voxels); summing density times voxel volume, as road two does, weighs an organ.
- **Loading ships and aircraft.** Fuel in a curved tank shifts the centre of mass, which sets whether the craft sits level.
- **The Earth's interior.** Density rises toward the core; a triple integral in spherical coordinates turns a density model into a mass that must match what orbits reveal.
- **Spinning things.** Weight each piece by squared distance from an axis and the same integral says how hard a body is to spin up: [Rotation](../../13-Engineering%20mathematics/07-Mechanics%20and%20Structures/02-rigid-body-rotation-and-moment-of-inertia.md).

> **Say it back**
> A triple integral cuts a solid into tiny pieces, multiplies each volume by the density there, and adds, in the limit. It is computed one direction at a time, once the solid is described as ranges of coordinates. In cylindrical coordinates a piece's volume is r dr dθ dz, since an angle step is longer far out. Weighting by position and dividing by mass gives the centre of mass. The wedge weighs 2792.53 g and balances 13.1303 cm from its tip, beyond a uniform wedge's 12.7324 cm.

---

## What this builds on

- [Double integrals](01-double-integrals.md): adding over a region one direction at a time, here with a third layer.
- [Cylindrical and spherical coordinates](../../05-Geometry%20and%20trig/04-Coordinates%20and%20Curves/07-cylindrical-and-spherical-coordinates.md): the coordinates that make the wedge a box.

## Where this goes next

- [Change of variables](03-change-of-variables-and-jacobians.md): the stretch factor for any coordinates, of which r is one case.
- [Divergence theorem](../09-Vector%20Calculus/07-divergence-theorem.md): outflow from each piece, added over a solid, equals the flow through its surface.
- [Rotation](../../13-Engineering%20mathematics/07-Mechanics%20and%20Structures/02-rigid-body-rotation-and-moment-of-inertia.md): squared distance times mass, for spinning bodies.
- Ricci and scalar curvature: volumes of small balls in curved space, integrated the same way.

This card leaves one question open: in coordinates other than cylindrical ones, what replaces the factor r in a cell's volume?

---

## Sources

Verified 2026-09-27: every link below resolves to the publisher's page.

- OpenStax. *Calculus Volume 3*, section 5.4, "Triple Integrals". [OpenStax page](https://openstax.org/books/calculus-volume-3/pages/5-4-triple-integrals). Box sums, adding one direction at a time, and solids described by bounds.
- OpenStax. *Calculus Volume 3*, section 5.5, "Triple Integrals in Cylindrical and Spherical Coordinates". [OpenStax page](https://openstax.org/books/calculus-volume-3/pages/5-5-triple-integrals-in-cylindrical-and-spherical-coordinates). The cylindrical cell and its r dr dθ dz.
- OpenStax. *Calculus Volume 3*, section 5.6, "Calculating Centers of Mass and Moments of Inertia". [OpenStax page](https://openstax.org/books/calculus-volume-3/pages/5-6-calculating-centers-of-mass-and-moments-of-inertia). Mass, first moments and the centre of mass of a solid.
