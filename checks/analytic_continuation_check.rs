// Analytic continuation -- the same check as the Python, in Rust.  No crates.
// A perpetuity pays $1 a year for ever; z = 1/(1 + r) discounts a year at rate r.
// Road one adds the payments, or walks a chain of discs carrying one number, the
// value v; road two is the closed form 1/r.  The walk never uses 1/(1 - z).
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }

fn disc_series(cen: C, v: C, z: C) -> C { // the series at centre cen, coefficients v^(k+1)
    let (mut total, mut term) = (c(0.0, 0.0), v);
    for _ in 0..600 { total = add(total, term); term = mul(mul(term, v), sub(z, cen)); }
    total
}
fn paid(r: f64, n_years: i32) -> f64 { (1..=n_years).map(|n| (1.0 + r).powi(-n)).sum() } // road one
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn rival(r: f64) -> f64 { 1.0 / r + (PI / r).sin() } // agrees with 1/r at r = 1/n only

fn main() {
    println!("r = 5%: z = {:.6}; 3000 payments add to {:.6}; 1/r = {:.6}", 1.0 / 1.05, paid(0.05, 3000), 1.0 / 0.05);
    let r = -0.005;
    let z = 1.0 / (1.0 + r);
    println!("r = -0.5%: z = {:.6}, outside the unit disc; 1/r = {:.6}", z, 1.0 / r);
    for n in [100, 1000] {
        println!("  {} payments add to {:.6}; -200 + 200 z^{} = {:.6}", n, paid(r, n), n, -200.0 + 200.0 * z.powi(n));
    }
    let centres = [c(0.0, 0.0), c(0.5, 0.5), c(1.0, 0.4), c(1.2, 0.1), c(1.02, 0.0)];
    let mut v = c(1.0, 0.0);
    for w in centres.windows(2) {
        let new_v = disc_series(w[0], v, w[1]);
        println!("  disc at {}, radius 1/|v| = {:.6}, step ratio {:.6}, hands on v = {}",
            show(w[0]), 1.0 / modulus(v), modulus(mul(v, sub(w[1], w[0]))), show(new_v));
        v = new_v;
    }
    let f_t = disc_series(centres[4], v, c(z, 0.0));
    let last = sub(f_t, c(1.0, 0.0));
    println!("chain of discs: f(T) = {}, so P = f(T) - 1 = {}; last disc radius {:.6}, ratio {:.6}",
        show(f_t), show(last), 1.0 / modulus(v), modulus(mul(v, sub(c(z, 0.0), centres[4]))));
    println!("rival 1/r + sin(pi/r): at 5% {:.6}, at 50% {:.6}; at -0.75% {:.6} against 1/r = {:.6}",
        rival(0.05), rival(0.5), rival(-0.0075), 1.0 / -0.0075);
    println!("mistake, payment now counted too: 1/(1 - z) at 5% = {:.6}, not 20", 1.0 / (1.0 - 1.0 / 1.05));
    let t = 0.01;
    let smooth: f64 = (1..6000).map(|n| n as f64 * (-(n as f64) * t).exp()).sum();
    println!("1 + 2 + ... + 100 = {}; sum of n e^(-nt) at t = {}, minus 1/t^2 = {:.6}; -1/12 = {:.6}",
        (0..=100).sum::<i32>(), t, smooth - 1.0 / (t * t), -1.0 / 12.0);
    let figs: Vec<String> = centres.iter().map(|q| format!("({:.1},{:.1},r{:.1})",
        110.0 + 100.0 * q.re, 135.0 - 100.0 * q.im, 100.0 * modulus(sub(c(1.0, 0.0), *q)))).collect();
    println!("figure, discs {}; pole (210.0,135.0); T ({:.1},135.0)", figs.join(" "), 110.0 + 100.0 * z);
    assert!((paid(0.05, 3000) - 20.0).abs() < 1e-9 && (paid(r, 1000) / ((1.0 - z.powi(1000)) / r) - 1.0).abs() < 1e-12);
    assert!(modulus(sub(last, c(1.0 / r, 0.0))) < 1e-8); // the walk lands on 1/r
    assert!((smooth - 1.0 / (t * t) + 1.0 / 12.0).abs() < 1e-5); // the smoothed constant
    assert!((rival(0.05) - 20.0).abs() < 1e-9 && (rival(-0.0075) - 1.0 / -0.0075).abs() > 0.5);
    println!("ALL CHECKS PASS");
}
