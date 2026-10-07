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
