// The Euler-Lagrange equation -- the same check as the Python, in Rust.  No crates.
// A cable runs from pylon A = (0, 0) to pylon B = (400, 300), in metres.  Rocky
// ground past x = 200 m doubles the price, from 80 to 160 pounds a metre.
use std::f64::consts::PI;
const X: f64 = 400.0;
const Y: f64 = 300.0;
const M: f64 = 0.75;
const H: f64 = 1e-4;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // Simpson's rule, 2000 panels
    let (n, w) = (2000, (b - a) / 2000.0);
    let inner: f64 = (1..n).map(|k| if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * w)).sum();
    w / 3.0 * (f(a) + f(b) + inner)
}
fn length(dy: &dyn Fn(f64) -> f64) -> f64 { simpson(&|x| (1.0 + dy(x).powi(2)).sqrt(), 0.0, X) }
fn first_variation(dy: &dyn Fn(f64) -> f64, de: &dyn Fn(f64) -> f64) -> f64 {  // F_p = y'/sqrt(1+y'^2)
    simpson(&|x| dy(x) / (1.0 + dy(x).powi(2)).sqrt() * de(x), 0.0, X)
}
fn quotient(dy: &dyn Fn(f64) -> f64, de: &dyn Fn(f64) -> f64) -> f64 {  // nudging both ways
    (length(&|x| dy(x) + H * de(x)) - length(&|x| dy(x) - H * de(x))) / (2.0 * H)
}
fn descend(price: &dyn Fn(f64) -> f64) -> (Vec<f64>, f64) {   // direct method, nodes every 40 m
    let (n, dx) = (10usize, X / 10.0);
    let mut y: Vec<f64> = (0..=n).map(|k| Y * k as f64 / 10.0 + 50.0 * (PI * k as f64 / 10.0).sin()).collect();
    for _ in 0..2000 {
        for i in 1..n {
            let (ca, cb) = (price((i as f64 - 0.5) * dx), price((i as f64 + 0.5) * dx));
            let (a, b) = (y[i - 1], y[i + 1]);
            let (mut lo, mut hi) = (a.min(b), a.max(b));
            for _ in 0..60 {                                  // bisection on the local slope
                let m = (lo + hi) / 2.0;
                let up = ca * (m - a) / (dx * dx + (m - a).powi(2)).sqrt() < cb * (b - m) / (dx * dx + (b - m).powi(2)).sqrt();
                if up { lo = m } else { hi = m }
            }
            y[i] = (lo + hi) / 2.0;
        }
    }
    let c = (0..n).map(|i| price((i as f64 + 0.5) * dx) * (dx * dx + (y[i + 1] - y[i]).powi(2)).sqrt()).sum();
    (y, c)
}
fn main() {
    let line = |_x: f64| M;
    let de = |x: f64| 40.0 * PI / X * (PI * x / X).cos();          // bulge eta = 40 sin(pi x / 400)
    let bow = |x: f64| M + 60.0 * PI / X * (PI * x / X).cos();     // y = 0.75x + 60 sin(pi x / 400)
    println!("straight line y = 0.75x: length {:.6} m", length(&line));
    let ls: Vec<String> = [-1.0, -0.5, 0.0, 0.5, 1.0].iter().map(|&e| format!("{:.2}", length(&|x| M + e * de(x)))).collect();
    println!("line plus e x bulge, e = -1, -0.5, 0, 0.5, 1: lengths {} m", ls.join(", "));
    println!("second-order term, by hand: {:.6} m times e^2", simpson(&|x| de(x).powi(2), 0.0, X) / (2.0 * 1.25f64.powi(3)));
    let (fl, fb, qb) = (first_variation(&line, &de).abs(), first_variation(&bow, &de), quotient(&bow, &de));
    println!("first variation at the line: formula {:.6} m, quotient {:.6} m", fl, quotient(&line, &de).abs());
    println!("first variation at the bowed route: formula {:.6} m, quotient {:.6} m", fb, qb);
    println!("moving pylon B 10 m north: first variation {:.6} m", first_variation(&line, &|_x| 10.0 / X));
    let (yf, lf) = descend(&|_x| 1.0);
    let dev = (0..11).map(|k| (yf[k] - M * 40.0 * k as f64).abs()).fold(0.0, f64::max);
    println!("direct method, flat ground: length {:.6} m, largest gap from y = 0.75x {:.6} m", lf, dev);
    let g = |s: f64| 80.0 * s / (200.0f64.powi(2) + s * s).sqrt() - 160.0 * (Y - s) / (200.0f64.powi(2) + (Y - s).powi(2)).sqrt();
    let (mut lo, mut hi) = (0.0, Y);
    for _ in 0..100 { let m = (lo + hi) / 2.0; if g(m) < 0.0 { lo = m } else { hi = m } }   // 80 sin = 160 sin
    let s = (lo + hi) / 2.0;
    let cost = 80.0 * (200.0f64.powi(2) + s * s).sqrt() + 160.0 * (200.0f64.powi(2) + (Y - s).powi(2)).sqrt();
    println!("rocky, Euler-Lagrange road: cross x = 200 at y = {:.4} m, cost {:.2} pounds", s, cost);
    let (yr, cr) = descend(&|x| if x < 200.0 { 80.0 } else { 160.0 });
    let sine = |j: usize| (yr[j + 1] - yr[j]) / (1600.0 + (yr[j + 1] - yr[j]).powi(2)).sqrt();
    let (sg, sr) = (sine(0), sine(9));
    println!("rocky, direct road: cross at y = {:.4} m, cost {:.2} pounds", yr[5], cr);
    println!("rocky, sines {:.4} and {:.4}; 80 x {:.4} = {:.4}, 160 x {:.4} = {:.4}", sg, sr, sg, 80.0 * sg, sr, 160.0 * sr);
    println!("mistake, straight line on rocky ground: {:.2} pounds, {:.2} too much", 80.0 * 250.0 + 160.0 * 250.0, 60000.0 - cost);
    println!("mistake, least rock (straight across it): {:.2} pounds", 80.0 * (200.0f64.powi(2) + Y * Y).sqrt() + 160.0 * 200.0);
    println!("figure, px = 50 + 0.6x, py = 210 - 0.6y: A (50, 210), B (290, 30), crossings (170, 120.0), (170, {:.1})", 210.0 - 0.6 * s);
    assert!((lf - 500.0).abs() < 1e-6 && dev < 1e-6);              // direct method finds the Euler-Lagrange line
    assert!((fb - qb).abs() < 1e-5 && fb.abs() > 1.0 && fl < 1e-9); // formula = derivative; zero only at the line
    assert!((cr - cost).abs() < 1e-4 && (yr[5] - s).abs() < 1e-4); // two roads, one bent route
    assert!((sg / sr - 2.0).abs() < 1e-6);                         // 80 sin on grass = 160 sin on rock
    println!("ALL CHECKS PASS");
}
