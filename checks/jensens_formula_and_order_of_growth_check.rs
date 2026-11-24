// Jensen's formula and order of growth -- the same check as the Python, in Rust.
// No crates.  Road one: the circle average of ln|f|, summed at N points.  Road
// two: ln|f(0)| plus ln(R/|a|) for each known zero a, their number checked by the
// argument principle.  Then the order of sin z and e^(z^2), and the zero bound.
use std::f64::consts::PI;
const N: usize = 4096;
fn circ(r: f64, n: usize, k: usize) -> (f64, f64) { let t = 2.0 * PI * k as f64 / n as f64; (r * t.cos(), r * t.sin()) }
fn avg(lnf: &dyn Fn(f64, f64) -> f64, r: f64, n: usize) -> f64 {
    (0..n).map(|k| { let (x, y) = circ(r, n, k); lnf(x, y) }).sum::<f64>() / n as f64
}
fn lnsin(x: f64, y: f64) -> f64 {  // ln|sin z| = ln sqrt(sin^2 x + sinh^2 y), written so e^|y| cannot overflow
    let e = (-2.0 * y.abs()).exp(); y.abs() + 0.5 * (x.sin().powi(2) * e + ((1.0 - e) / 2.0).powi(2)).ln()
}
fn lnsinc(x: f64, y: f64) -> f64 { lnsin(x, y) - 0.5 * (x * x + y * y).ln() }   // ln|sin z / z|
fn lnlin(x: f64, y: f64) -> f64 { 0.5 * ((x - 0.5).powi(2) + y * y).ln() }      // ln|z - 1/2|
fn winding(r: f64, n: usize) -> i64 {  // turns of sin z round |z| = r: arg = atan2(cos x tanh y, sin x)
    let (mut tot, mut prev) = (0.0, None::<f64>);
    for k in 0..=n {
        let (x, y) = circ(r, n, k);
        let a = (x.cos() * y.tanh()).atan2(x.sin());
        if let Some(p) = prev { tot += (a - p + PI).rem_euclid(2.0 * PI) - PI; }
        prev = Some(a);
    }
    (tot / (2.0 * PI)).round() as i64
}
fn zeros(r: f64) -> i64 { winding(r, 64 * r as usize + 256) - 1 }   // zeros of sin z / z: drop the one at 0
fn lnm(r: f64, g: &dyn Fn(f64, f64) -> f64) -> f64 {               // ln of max |g| on |z| = r
    (0..3600).map(|k| { let (x, y) = circ(r, 3600, k); g(x, y) }).fold(f64::MIN, f64::max)
}
fn f6(v: f64) -> String { format!("{:.6}", if v.abs() < 5e-7 { 0.0 } else { v }) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let chart: Vec<f64> = (0..13).map(|k| { let (x, y) = circ(1.0, 12, k); lnlin(x, y) }).collect();
    println!("chart, ln|e^(it) - 1/2| at t = 0, 30, ..., 360 degrees: {}", join(&chart, 3));
    let (a1, ln2) = (avg(&lnlin, 1.0, N), 2f64.ln());
    println!("z - 1/2 on |z| = 1: circle average {}; ln|f(0)| = {}; correction ln 2 = {}", f6(a1), f6(0.5f64.ln()), f6(ln2));
    let (r10, n10) = (10.0, zeros(10.0));
    let terms: Vec<f64> = (1..4).map(|k| (r10 / (k as f64 * PI)).ln()).collect();
    let (a10, j10) = (avg(&lnsinc, r10, N), 0.0 + 2.0 * terms.iter().sum::<f64>());   // ln|f(0)| = ln 1 = 0
    println!("sin z / z on |z| = 10: zeros inside by the argument principle {}, at +-pi, +-2pi, +-3pi", n10);
    println!("  ln(10/pi), ln(10/2pi), ln(10/3pi) = {}", terms.iter().map(|&v| f6(v)).collect::<Vec<_>>().join(", "));
    println!("  circle average {}; Jensen: 0 + 2 x their sum = {}", f6(a10), f6(j10));
    let rs = [10.0f64, 100.0, 1000.0];
    let osin: Vec<f64> = rs.iter().map(|&r| lnm(r, &lnsin).ln() / r.ln()).collect();
    let oexp: Vec<f64> = rs.iter().map(|&r| lnm(r, &|x, y| x * x - y * y).ln() / r.ln()).collect();   // ln|e^(z^2)| = x^2 - y^2
    println!("order estimate ln ln M(r) / ln r at r = 10, 100, 1000: sin z {}; e^(z^2) {}", join(&osin, 4), join(&oexp, 4));
    println!("  ln M(10) by sampling {}; ln sinh 10 = {}", f6(lnm(10.0, &lnsin)), f6(10f64.sinh().ln()));
    let big = [zeros(100.0) + 1, zeros(1000.0) + 1];
    println!("zeros of sin z in |z| < 100 and 1000: {} and {}; 2r/pi = {:.2} and {:.2}", big[0], big[1], 200.0 / PI, 2000.0 / PI);
    let radii = [10.0f64, 20.0, 30.0, 40.0, 50.0];
    let cnt: Vec<i64> = radii.iter().map(|&r| zeros(r)).collect();
    let bnd: Vec<f64> = radii.iter().map(|&r| (lnm(2.0 * r, &lnsin) - (2.0 * r).ln()) / ln2).collect();   // f(0) = 1
    println!("chart, zeros of sin z / z in |z| < r, r = 10..50: {}", cnt.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, Jensen bound (ln M(2r) - ln|f(0)|) / ln 2: {}", join(&bnd, 1));
    let (sq, inv) = (avg(&|x, y| 2.0 * lnlin(x, y), 1.0, N), avg(&|x, y| -lnlin(x, y), 1.0, N));
    println!("mistake 1, no correction: Jensen would give ln|f(0)| = {}, the circle gives {}", f6(-ln2), f6(a1));
    println!("mistake 2, (z - 1/2)^2 counted once: {}; circle {}; counted twice {}", f6(2.0 * -ln2 + ln2), f6(sq), f6(2.0 * -ln2 + 2.0 * ln2));
    println!("mistake 3, pole of 1/(z - 1/2) added like a zero: {}; circle {}; subtracted {}", f6(ln2 + ln2), f6(inv), f6(ln2 - ln2));
    let real = (-10000..=10000).map(|x| (x as f64 / 100.0).sin().abs()).fold(0.0, f64::max);
    println!("mistake 4, size on the real line only: largest |sin x| for -100 <= x <= 100 is {:.6}, yet {} zeros in |z| < 100", real, big[0]);
    assert!((a1 - (lnlin(0.0, 0.0) + (1.0f64 / 0.5).ln())).abs() < 1e-9 && (a10 - j10).abs() < 1e-9);   // two roads agree
    assert!(n10 == 6 && cnt.iter().zip(radii.iter()).all(|(&c, &r)| c == 2 * (r / PI) as i64) && big == [63, 637]);
    assert!(cnt.iter().zip(bnd.iter()).zip(radii.iter())
        .all(|((&c, &b), &r)| (c as f64) <= b && (b - ((2.0 * r).sinh() / (2.0 * r)).ln() / ln2).abs() < 1e-9));
    assert!((lnm(10.0, &lnsin) - 10f64.sinh().ln()).abs() < 1e-9);
    assert!((osin[2] - 1.0).abs() < 0.001 && (oexp[0] - 2.0).abs() < 1e-9 && sq.abs() < 1e-9 && inv.abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
