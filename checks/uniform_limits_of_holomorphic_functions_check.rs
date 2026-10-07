// Limits of holomorphic functions -- the same check as the Python, in Rust.  No crates.
// The tower: f(z) = sum of z^n/n^2 over n = 1, 2, 3, ... on the closed unit disc; floor n never
// exceeds M_n = 1/n^2.  Values on the rim: stacked floors against pi^2/6 and -pi^2/12.  Slope inside:
// floors differentiated one by one, against Cauchy's formula on a circle, against -log(1 - z)/z.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let m = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / m, (a.im * b.re - a.re * b.im) / m) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn log(w: C) -> C { c(md(w).ln(), w.im.atan2(w.re)) } // principal log from ln|w| and atan2
fn floors(z: C, n: usize, slope: bool) -> C { // the first n floors, or each floor differentiated
    let (mut p, mut s) = (c(1.0, 0.0), c(0.0, 0.0));
    for k in 1..=n {
        let kf = k as f64;
        if slope { s = add(s, c(p.re / kf, p.im / kf)); p = mul(p, z); } else { p = mul(p, z); s = add(s, c(p.re / (kf * kf), p.im / (kf * kf))); }
    }
    s
}
fn sr(x: f64, n: usize) -> f64 { floors(c(x, 0.0), n, false).re }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn main() {
    let n = 1000.0f64; // rim values: stack 1000 floors, add the tail's size
    let f1 = sr(1.0, 1000) + 1.0 / n - 1.0 / (2.0 * n * n) + 1.0 / (6.0 * n * n * n);
    let fm1 = (sr(-1.0, 100000) + sr(-1.0, 100001)) / 2.0; // alternating floors: average two neighbours
    println!("f(1): floors {:.6}, pi^2/6 {:.6}", f1, PI * PI / 6.0);
    println!("f(-1): floors {:.6}, -pi^2/12 {:.6}; mistake -f(1) = {:.6}", fm1, -PI * PI / 12.0, -f1);
    for k in [10usize, 100, 1000] { // worst gap on the closed disc sits at z = 1
        println!("N = {}: worst gap after N floors {:.6}, M-test bound 1/N {:.6}", k, PI * PI / 6.0 - sr(1.0, k), 1.0 / k as f64);
    }
    let (z0, rho) = (0.5f64, 0.4f64); // the slope at 1/2, Cauchy circle of radius 0.4 round it
    let termwise = floors(c(z0, 0.0), 80, true).re;
    let closed = -(1.0 - z0).ln() / z0;
    println!("f'(1/2): floors differentiated {:.6}, -log(1 - z)/z = 2 ln 2 = {:.6}", termwise, closed);
    let mut cauchy = c(0.0, 0.0);
    for m in [8usize, 32, 128] { // trapezoid sum of Cauchy's formula, m points on the circle
        cauchy = c(0.0, 0.0);
        for k in 0..m {
            let t = 2.0 * PI * k as f64 / m as f64;
            let p = c(rho * t.cos(), rho * t.sin());
            cauchy = add(cauchy, div(floors(add(c(z0, 0.0), p), 400, false), p));
        }
        cauchy = c(cauchy.re / m as f64, cauchy.im / m as f64);
        println!("Cauchy's formula, {} points: {}, error {:.9}", m, show(cauchy), md(sub(cauchy, c(closed, 0.0))));
    }
    let (err10, est10) = ((floors(c(z0, 0.0), 10, true).re - termwise).abs(), (1.0 / 10.0) / rho);
    println!("slope error after 10 floors {:.6}, Cauchy estimate (1/10)/0.4 = {:.6}", err10, est10);
    let w = c(0.0, 0.5);
    let (tw_i, cl_i) = (floors(w, 80, true), div(c(-log(sub(c(1.0, 0.0), w)).re, -log(sub(c(1.0, 0.0), w)).im), w));
    println!("f'(i/2): floors differentiated {}, -log(1 - z)/z {}", show(tw_i), show(cl_i));
    let h: Vec<String> = [10usize, 100, 1000].iter().map(|&k| format!("N = {}: {:.6}", k, floors(c(1.0, 0.0), k, true).re)).collect();
    println!("rim slope at z = 1, harmonic sums: {}", h.join(", "));
    for k in [16.0f64, 64.0] { // sin(nx)/n: tiny on the real line, huge at i/4
        let sh = ((k / 4.0).exp() - (-k / 4.0).exp()) / 2.0 / k;
        println!("sin(nz)/n, n = {}: real-line size <= {:.6}, slope at 0 = 1, size at i/4 = {:.6}", k as i32, 1.0 / k, sh);
    }
    let (sre, sim, l5) = (2.0f64, 3.0f64, 5.0f64.ln()); // the zeta link: |n^-s| = n^-(Re s)
    let t = c((-sre * l5).exp() * (-sim * l5).cos(), (-sre * l5).exp() * (-sim * l5).sin());
    println!("zeta link: 5^-(2+3i) = {}, size {:.6} = 1/5^2", show(t), md(t));
    println!("figure, centre (180, 120), 80 per unit: z = 1 at ({:.0}, 120), z = -1 at ({:.0}, 120), z0 at ({:.0}, 120), Cauchy radius {:.0}, i/2 at (180, {:.0})",
        180.0 + 80.0 * 1.0, 180.0 - 80.0 * 1.0, 180.0 + 80.0 * z0, 80.0 * rho, 120.0 - 80.0 * 0.5);
    assert!((f1 - PI * PI / 6.0).abs() < 1e-12 && (fm1 + PI * PI / 12.0).abs() < 1e-9); // floors meet pi
    assert!([10usize, 100, 1000].iter().all(|&k| PI * PI / 6.0 - sr(1.0, k) <= 1.0 / k as f64)); // M-test bound holds
    assert!((cauchy.re - termwise).abs() < 1e-10 && (termwise - closed).abs() < 1e-12 && err10 <= est10);
    assert!(md(sub(tw_i, cl_i)) < 1e-12 && floors(c(1.0, 0.0), 1000, true).re > 7.0); // i/2 case; rim slope runs off
    println!("ALL CHECKS PASS");
}
