// Fourier series of a square wave -- the same check as the Python, in Rust.  No crates.
// f(x) = +1 on (0, pi), -1 on (-pi, 0), repeating every 2 pi: a synthesiser's square tone.
// Road 1: the closed form c_n = 2/(i pi n) for odd n, 0 for even n.
// Road 2: each c_n as an average, (1/2 pi) times the integral of f(x) e^(-inx), by Simpson's rule.
// Parseval, the mean-square error and the Gibbs peak each get a second road as well.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn simpson(g: &dyn Fn(f64) -> C, a: f64, b: f64, m: usize) -> C { // m even panels
    let h = (b - a) / m as f64;
    let mut s = add(g(a), g(b));
    for k in 1..m { s = add(s, sc(g(a + k as f64 * h), if k % 2 == 1 { 4.0 } else { 2.0 })) }
    sc(s, h / 3.0)
}
fn spin(n: i64, x: f64) -> C { c((n as f64 * x).cos(), (n as f64 * x).sin()) } // e^(inx)
fn average(g: &dyn Fn(f64) -> C) -> C { sc(sub(simpson(g, 0.0, PI, 2000), simpson(g, -PI, 0.0, 2000)), 1.0 / (2.0 * PI)) } // of f(x) g(x)
fn closed(n: i64) -> C { if n % 2 != 0 { c(0.0, -2.0 / (PI * n as f64)) } else { c(0.0, 0.0) } }
fn partial(x: f64, n: i64) -> f64 { (-n..=n).map(|k| mul(closed(k), spin(k, x)).re).sum() } // S_N(x)
fn real(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { simpson(&|x| c(g(x), 0.0), a, b, 2000).re }
fn list(v: &[f64], d: usize) -> String { // d = 2 rounds first, as the Python does, so no -0.00
    v.iter().map(|&x| format!("{:.*}", d, if d == 2 { (x * 100.0).round() / 100.0 + 0.0 } else { x })).collect::<Vec<_>>().join(", ")
}
fn main() {
    let numeric: Vec<C> = (-7..=7).map(|n| average(&|x| spin(-n, x))).collect(); // index n + 7
    println!("c_n closed form, n = 1, 3, 5: {}", [1, 3, 5].map(|n| show(closed(n))).join(", "));
    println!("c_n by averaging, n = 1, 3, 5: {}", [1, 3, 5].map(|n| show(numeric[n as usize + 7])).join(", "));
    println!("c_n by averaging, n = 0, 2, -1: {}", [0i64, 2, -1].map(|n| show(numeric[(n + 7) as usize])).join(", "));
    let b_conv = [1, 3, 5].map(|n| mul(c(0.0, 1.0), sub(closed(n), closed(-n))).re);
    let b_real = [1, 3, 5].map(|n| average(&|x| c((n as f64 * x).sin(), 0.0)).re * 2.0);
    println!("b_n = i(c_n - c_-n), n = 1, 3, 5: {}; by (1/pi) int f sin nx: {}", list(&b_conv, 6), list(&b_real, 6));
    println!("a_n = c_n + c_-n, n = 1, 3: {:.6}, {:.6}; tone 220 Hz: harmonics at {}, {}, {} Hz", add(closed(1), closed(-1)).re, add(closed(3), closed(-3)).re, 220, 3 * 220, 5 * 220);
    let xs: Vec<f64> = (0..17).map(|k| k as f64 * PI / 8.0).collect();
    let sq: Vec<f64> = (0..17).map(|k| if k % 8 == 0 { 0.0 } else if k < 8 { 1.0 } else { -1.0 }).collect();
    println!("chart, square wave: {}", list(&sq, 2));
    for (n, name) in [(1, "first harmonic S_1"), (5, "three harmonics S_5")] {
        println!("chart, {}: {}", name, list(&xs.iter().map(|&x| partial(x, n)).collect::<Vec<_>>(), 2));
    }
    let (arrow, partner) = (mul(closed(1), spin(1, PI / 4.0)), mul(closed(-1), spin(-1, PI / 4.0)));
    let sum = add(arrow, partner);
    println!("arrows at x = pi/4: {} + {} = {}; |c_1| = {:.6}", show(arrow), show(partner), show(sum), modulus(closed(1)));
    println!("figure, 160 per unit, origin (120, 120), arrow ({:.2}, {:.2}), partner ({:.2}, {:.2}), sum ({:.2}, 120), radius {:.2}",
        120.0 + 160.0 * arrow.re, 120.0 - 160.0 * arrow.im, 120.0 + 160.0 * partner.re, 120.0 - 160.0 * partner.im, 120.0 + 160.0 * sum.re, 160.0 * modulus(closed(1)));
    let p5: f64 = (-5..=5).map(|n| modulus(closed(n)).powi(2)).sum();
    let odd: f64 = (1..2_000_000u64).step_by(2).map(|n| 1.0 / (n as f64 * n as f64)).sum::<f64>() + 1.0 / 4e6; // plus the tail
    println!("Parseval: 1 + 1/9 + 1/25 = {:.6}; odd n to 2e6 plus tail = {:.9}; pi^2/8 = {:.9}", 1.0 + 1.0 / 9.0 + 1.0 / 25.0, odd, PI * PI / 8.0);
    let msq = (real(&|x| (1.0 - partial(x, 5)).powi(2), 0.0, PI) + real(&|x| (-1.0 - partial(x, 5)).powi(2), -PI, 0.0)) / (2.0 * PI);
    println!("S_5: sum |c_n|^2 = {:.6}; mean-square error by Parseval {:.6}, by integrating (f - S_5)^2 {:.6}", p5, 1.0 - p5, msq);
    let peaks = [5i64, 21, 101].map(|n| (1..=2000).map(|k| partial(k as f64 * 4.0 * PI / ((n + 1) as f64 * 2000.0), n)).fold(f64::MIN, f64::max));
    let gibbs = 2.0 / PI * real(&|t| if t == 0.0 { 1.0 } else { t.sin() / t }, 0.0, PI);
    println!("Gibbs peak of S_N, N = 5, 21, 101: {}; limit (2/pi) Si(pi) = {:.6}", list(&peaks, 6), gibbs);
    println!("hypothesis dropped, at the jump x = 0: S_5 = {:.6}, S_101 = {:.6}; f is -1 just left, +1 just right", partial(0.0, 5) + 0.0, partial(0.0, 101) + 0.0);
    println!("mistake, 1/pi for 1/2 pi: c_1 = {}, S_5(pi/2) = {:.6}; true S_5(pi/2) = {:.6}", show(sc(closed(1), 2.0)), 2.0 * partial(PI / 2.0, 5), partial(PI / 2.0, 5));
    let flip: Vec<C> = (-5..=5).map(|n| average(&|x| spin(n, x))).collect(); // e^(+inx) in the average
    let rebuilt: f64 = (-5..=5).map(|n| mul(flip[(n + 5) as usize], spin(n, PI / 2.0)).re).sum();
    println!("mistake, e^(+inx) in the average: c_1 = {}, S_5(pi/2) = {:.6}", show(flip[6]), rebuilt);
    let half: f64 = (1..200001i64).step_by(2).map(|n| mul(closed(n), spin(n, PI / 2.0)).re).sum();
    println!("mistake, n > 0 only, n to 200000, at x = pi/2: {:.4} instead of 1", half);
    assert!((-7..=7).all(|n| modulus(sub(numeric[(n + 7) as usize], closed(n))) < 1e-9)); // average against formula
    assert!(b_conv.iter().zip(b_real.iter()).all(|(u, v)| (u - v).abs() < 1e-9)); // complex form against real form
    assert!((msq - (1.0 - p5)).abs() < 1e-9 && (odd - PI * PI / 8.0).abs() < 1e-9); // Parseval, two ways
    assert!(peaks[0] > peaks[1] && peaks[1] > peaks[2] && peaks[2] > gibbs && peaks[2] - gibbs < 1e-3); // Gibbs stays
    println!("ALL CHECKS PASS");
}
