// Symplectic steps -- the same check as the Python, in Rust, no crates.  Road one steps each
// method in its own loop; road two is a closed form: rotation formula, (1 + h^2)^n, the circle.
use std::f64::consts::PI;

fn leap(q: f64, v: f64, h: f64) -> (f64, f64) {     // half kick, drift, half kick
    let v = v - h / 2.0 * q;
    let q = q + h * v;
    (q, v - h / 2.0 * q)
}
fn euler(q: f64, v: f64, h: f64) -> (f64, f64) { (q + h * v, v - h * q) }
fn energy(q: f64, v: f64) -> f64 { (q * q + v * v) / 2.0 }
fn sci(x: f64, d: usize) -> String {                  // Python-style exponent: e+170, e-03
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let k: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs())
}
fn orbit_error(step: fn(f64, f64, f64) -> (f64, f64), m: usize) -> f64 {
    let (mut q, mut v) = (1.0, 0.0);
    for _ in 0..m { (q, v) = step(q, v, 2.0 * PI / m as f64) }
    (q - 1.0).hypot(v)
}
fn planet(per_year: usize, is_euler: bool) -> (f64, f64, Vec<String>, f64) {
    let (h, gm) = (1.0 / per_year as f64, 4.0 * PI * PI);
    let (mut x, mut y, mut vx, mut vy, mut hi, mut r1) = (1.0f64, 0.0f64, 0.0, 2.0 * PI, 0.0f64, 0.0);
    let mut track = vec![];
    for n in 1..=per_year * 1000 {
        let r3 = x.hypot(y).powi(3);
        if is_euler {
            (x, y, vx, vy) = (x + h * vx, y + h * vy, vx - h * gm * x / r3, vy - h * gm * y / r3);
        } else {
            vx -= h / 2.0 * gm * x / r3; vy -= h / 2.0 * gm * y / r3; x += h * vx; y += h * vy;
            let r3 = x.hypot(y).powi(3); vx -= h / 2.0 * gm * x / r3; vy -= h / 2.0 * gm * y / r3;
        }
        hi = hi.max((x.hypot(y) - 1.0).abs());
        if n <= per_year && n % 5 == 0 { track.push(format!("{:.0},{:.0}", 180.0 + 60.0 * x, 120.0 - 60.0 * y)) }
        if n == per_year { r1 = x.hypot(y) }
    }
    (hi, r1, track, (vx * vx + vy * vy) / 2.0 - gm / x.hypot(y))
}
fn main() {
    let h = 2.0 * PI / 100.0;
    let (a, b, theta) = (1.0 - h * h / 2.0, 1.0 - h * h / 4.0, 2.0 * (h / 2.0).asin());
    println!("h = 2 pi/100 = {:.7}; a = {:.9}; b = {:.9}", h, a, b);
    println!("area factor per step: leapfrog a^2 + h^2 b = {:.12}; Euler 1 + h^2 = {:.9}", a * a + h * h * b, 1.0 + h * h);
    let (mut q, mut v, mut eq, mut ev, mut lo, mut hi, mut gap) = (1.0f64, 0.0f64, 1.0, 0.0, 0.5f64, 0.5f64, 0.0f64);
    for n in 1..=100000 {
        (q, v) = leap(q, v, h); lo = lo.min(energy(q, v)); hi = hi.max(energy(q, v));
        let t = n as f64 * theta;
        gap = gap.max((q - t.cos()).abs()).max((v + b.sqrt() * t.sin()).abs());
        (eq, ev) = euler(eq, ev, h);
        if n == 100 { println!("one orbit: Euler energy {:.6}, formula 0.5(1 + h^2)^100 = {:.6}", energy(eq, ev), 0.5 * (1.0 + h * h).powi(100)) }
    }
    println!("1000 orbits: leapfrog energy min {:.6}, max {:.6}; band [b/2, 1/2] = [{:.6}, 0.5], width {:.3}%", lo, hi, b / 2.0, 25.0 * h * h);
    println!("1000 orbits: Euler energy {}, formula {}", sci(energy(eq, ev), 4), sci(0.5 * (1.0 + h * h).powi(100000), 4));
    println!("leapfrog loop vs rotation formula, largest gap in 100000 steps: {}", sci(gap, 1));
    let lead = 100000.0 * (theta - h);
    println!("angle per step {:.9} vs h {:.9}; lead after 1000 orbits {:.4} rad", theta, h, lead);
    println!("position after 1000 orbits: leapfrog q = {:.4}, exact 1; cos(lead) = {:.4}", q, lead.cos());
    let errs: Vec<(f64, f64)> = [50, 100, 200].iter().map(|&m| (orbit_error(leap, m), orbit_error(euler, m))).collect();
    for (m, (el, ee)) in [50, 100, 200].iter().zip(&errs) {
        println!("one orbit in {} steps: leapfrog error {}, Euler error {}", m, sci(*el, 3), sci(*ee, 3));
    }
    let (hi1, _, _, en1) = planet(100, false);
    let (hi2, _, _, _) = planet(200, false);
    let (ehi, er1, etrack, een) = planet(100, true);
    println!("planet, leapfrog, 100/yr, 1000 yr: largest radius error {:.5} AU ({:.3}%); energy {:.4}, exact {:.4}", hi1, 100.0 * hi1, en1, -2.0 * PI * PI);
    println!("planet, leapfrog, 200/yr, 1000 yr: largest radius error {:.5} AU; ratio {:.2}", hi2, hi1 / hi2);
    println!("planet, Euler, 100/yr: radius after 1 yr {:.4} AU ({:.0}% out), largest error in 1000 yr {:.2} AU; energy {:.4}", er1, 100.0 * (er1 - 1.0), ehi, een);
    let (mut q, mut v) = (1.0, -0.75);
    let a5: f64 = 1.0 - 2.5 * 2.5 / 2.0; for _ in 0..6 { (q, v) = leap(q, v, 2.5) }
    println!("h = 2.5: a = {:?}, growth root {:?}; from (1, -0.75), 6 steps: q = {:.0}, v = {:.0}", a5, a5 - (a5 * a5 - 1.0).sqrt(), q, v);
    println!("figure, Euler first year every 5 steps (px): 240,120 {}", etrack.join(" "));
    assert!(gap < 1e-9);                                                            // loop = rotation formula
    assert!((energy(eq, ev) / (0.5 * (1.0 + h * h).powi(100000)) - 1.0).abs() < 1e-8); // Euler's growth law
    let (r2, r1e) = (errs[1].0 / errs[2].0, errs[1].1 / errs[2].1);
    assert!(3.8 < r2 && r2 < 4.2 && 1.8 < r1e && r1e < 2.4);                         // orders 2 and 1
    assert!(3.95 < hi1 / hi2 && hi1 / hi2 < 4.05 && hi1 < 0.0025 && er1 > 1.5); // band ~ h^2; Euler out
    println!("ALL CHECKS PASS");
}
