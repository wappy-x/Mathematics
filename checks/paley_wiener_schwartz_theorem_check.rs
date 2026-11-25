// Paley-Wiener-Schwartz -- the check behind the card.  Rust std only.
// Units: time t in ms, frequency in kHz, so xi*t is a pure number.
// Convention: f-hat(zeta) = integral of f(t) e^(-2 pi i zeta t) dt, with a complex
// frequency zeta = xi + i*eta.  Every transform is computed here.  Roads: closed
// forms against Simpson's rule at two step counts, the slope rule against the
// transform of the second slope, and narrow bumps that settle on the spike's slope.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(a: C) -> C { let m = a.re.exp(); c(m * a.im.cos(), m * a.im.sin()) }
fn csin(a: C) -> C { c(a.re.sin() * a.im.cosh(), a.re.cos() * a.im.sinh()) }

fn simpson(f: &dyn Fn(f64) -> C, a: f64, b: f64, n: usize) -> C {
    let h = (b - a) / n as f64;
    let mut s = add(f(a), f(b));
    for k in 1..n {
        s = add(s, sc(f(a + k as f64 * h), if k % 2 == 1 { 4.0 } else { 2.0 }));
    }
    sc(s, h / 3.0)
}
fn ft(f: &dyn Fn(f64) -> f64, z: C, a: f64, b: f64, n: usize) -> C {
    simpson(&|t: f64| sc(cexp(sc(mul(c(0.0, -2.0 * PI), z), t)), f(t)), a, b, n)
}
fn bump(t: f64, k: u32) -> f64 {
    let u = 1.0 - 4.0 * t * t;
    if u <= 1e-9 { return 0.0; }
    let p = (1.0 - 1.0 / u).exp();
    match k {
        0 => p,
        1 => p * (-8.0 * t / u.powi(2)),
        _ => p * (64.0 * t * t / u.powi(4) - 8.0 / u.powi(2) - 128.0 * t * t / u.powi(3)),
    }
}
fn g_hat(z: C) -> C { div(csin(sc(z, PI)), sc(z, PI)) }
fn lnsinh(x: f64) -> f64 { x + ((1.0 - (-2.0 * x).exp()) / 2.0).ln() }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let g = |_t: f64| 1.0;
    let phi = |t: f64| bump(t, 0);
    // 1. both shutters obey the window bound
    let area = simpson(&|t| c(phi(t), 0.0), -0.5, 0.5, 4000).re;
    println!("smooth shutter area = {:.6} ms (hard shutter area = 1.000000 ms)", area);
    for (xi, eta) in [(0.25, 0.0), (0.25, 1.0), (2.0, 2.0), (0.5, 5.0)] {
        let z = c(xi, eta);
        let (exact, simp) = (abs(g_hat(z)), abs(ft(&g, z, -0.5, 0.5, 2000)));
        let sm = abs(ft(&phi, z, -0.5, 0.5, 4000));
        let sm2 = abs(ft(&phi, z, -0.5, 0.5, 8000));
        let bound = (PI * eta.abs()).exp();
        assert!((exact - simp).abs() < 1e-9 * exact.max(1.0) && (sm - sm2).abs() < 1e-9 * sm.max(1.0));
        assert!(exact <= bound && sm <= area * bound);
        println!("zeta = {:.2}+{:.2}i  hard {:.6} (Simpson {:.6})  bound {:.6}  ratio {:.6}  smooth {:.6}  ratio {:.6}",
                 xi, eta, exact, simp, bound, exact / bound, sm, sm / (area * bound));
        if (xi, eta) == (0.25, 1.0) {
            let sh = PI.sinh();
            println!("by hand: sinh(pi) = {:.6}  |sin(pi zeta)| = {:.6}  |pi zeta| = {:.6}", sh, (0.5 + sh * sh).sqrt(), abs(sc(z, PI)));
        }
    }
    // 2. read the window off the growth
    let etas: Vec<f64> = (1..11).map(|e| e as f64).collect();
    let hard: Vec<f64> = etas.iter().map(|&e| (lnsinh(PI * e) - (PI * e).ln()) / (2.0 * PI * e)).collect();
    let smooth: Vec<f64> = etas.iter().map(|&e| abs(ft(&phi, c(0.0, e), -0.5, 0.5, 4000)).ln() / (2.0 * PI * e)).collect();
    let spike: Vec<f64> = etas.iter().map(|&e| (2.0 * PI * e).ln() / (2.0 * PI * e)).collect();
    assert!((hard[0] - abs(ft(&g, c(0.0, 1.0), -0.5, 0.5, 2000)).ln() / (2.0 * PI)).abs() < 1e-9);
    assert!((smooth[9] - abs(ft(&phi, c(0.0, 10.0), -0.5, 0.5, 8000)).ln() / (20.0 * PI)).abs() < 1e-9);
    println!("by hand: ln sinh(10 pi) = {:.6}  ln(10 pi) = {:.6}", lnsinh(10.0 * PI), (10.0 * PI).ln());
    println!("chart eta (kHz): {}", (1..11).map(|e| e.to_string()).collect::<Vec<_>>().join(" "));
    for (name, row) in [("hard", &hard), ("smooth", &smooth), ("spike slope", &spike)] {
        println!("chart {}: {}", name, join(row, 3));
    }
    let far: Vec<f64> = [100.0, 1000.0, 10000.0].iter().map(|&e: &f64| (lnsinh(PI * e) - (PI * e).ln()) / (2.0 * PI * e)).collect();
    println!("hard shutter b at eta = 100, 1000, 10000 kHz: {}", join(&far, 6));
    assert!(hard[9] < far[0] && far[0] < far[1] && far[1] < far[2] && far[2] < 0.5 && 0.5 - far[2] < 1e-3);
    println!("type = 2 pi b = {:.6} ms; window width = 2b = 1.000000 ms", 2.0 * PI * 0.5);
    let (up, down) = (abs(ft(&g, c(0.0, 10.0), 0.0, 1.0, 2000)).ln() / (20.0 * PI), abs(ft(&g, c(0.0, -10.0), 0.0, 1.0, 2000)).ln() / (20.0 * PI));
    assert!((up - hard[9] - 0.5).abs() < 1e-9 && (down - hard[9] + 0.5).abs() < 1e-9); // shift by 0.5 ms
    println!("shutter open 0 to 1 ms, b up and down at eta = 1000 kHz: {:.6} {:.6}; width {:.6} ms, type over pi {:.6} ms",
             far[1] + 0.5, far[1] - 0.5, 2.0 * far[1], 2.0 * far[1] + 1.0);
    // 3. the real line measures smoothness, not width
    let ts = 48f64.powf(-0.25); // phi'' = 0 only at +-ts, where 384 t^4 = 8
    let l1 = 4.0 * bump(ts, 1).abs(); // so integral of |phi''| = 4 x steepest slope
    let l1s = 2.0 * simpson(&|t| c(bump(t, 2), 0.0), ts, 0.5, 4000).re - simpson(&|t| c(bump(t, 2), 0.0), -ts, ts, 4000).re;
    assert!(bump(ts, 2).abs() < 1e-9 && (l1 - l1s).abs() < 1e-9);
    println!("integral of |second slope| = 4 x steepest slope = {:.9}, at t = {:.6} ms (Simpson between the zeros {:.9})", l1, ts, l1s);
    for xi in [1.5, 2.5, 4.5, 8.5, 16.5] {
        let h = abs(g_hat(c(xi, 0.0)));
        let s = ft(&phi, c(xi, 0.0), -0.5, 0.5, 4000);
        let s2 = ft(&|t| bump(t, 2), c(xi, 0.0), -0.5, 0.5, 4000);
        assert!(abs(add(s2, sc(s, (2.0 * PI * xi).powi(2)))) < 1e-9);
        assert!((h - 1.0 / (PI * xi)).abs() < 1e-12);
        let bnd = l1 / (2.0 * PI * xi).powi(2);
        assert!(abs(s) <= bnd);
        println!("xi = {:4.1} kHz  hard {:.6}  smooth {:.9}  bound {:.9}  ratio {:.6}", xi, h, abs(s), bnd, abs(s) / bnd);
    }
    // 4. L2 converse: sinc^2 has type 2 pi; its inverse is silent past 1 ms
    let k = 200.0;
    let sinc2 = |x: f64| if x == 0.0 { 1.0 } else { ((PI * x).sin() / (PI * x)).powi(2) };
    println!("inverse of sinc^2, cut at {:.0} kHz, tail bound {:.6}:", k, 2.0 / (PI * PI * k));
    for t in [0.0, 0.5, 1.5] {
        let v = 2.0 * simpson(&|x| c(sinc2(x) * (2.0 * PI * x * t).cos(), 0.0), 0.0, k, 40000).re;
        let tri = (1.0 - t.abs()).max(0.0);
        assert!((v - tri).abs() < 2.0 / (PI * PI * k));
        println!("  t = {:.1} ms  inverse {:.6}  triangle {:.6}  gap {:.6}", t, v, tri, (v - tri).abs());
    }
    // 5. the spike's slope: narrow bumps of area 1 and width w
    let (mut a, mut b) = (c(0.0, 0.0), c(0.0, 0.0));
    for w in [1.0, 0.1, 0.01] {
        let d = |t: f64| bump(t / w, 1) / (w * w * area);
        a = ft(&d, c(1.0, 0.0), -w / 2.0, w / 2.0, 2000);
        b = ft(&d, c(0.0, 1.0), -w / 2.0, w / 2.0, 2000);
        println!("w = {:.3} ms  at 1 kHz {:.6}i  at 1i kHz {:.6}", w, a.im, b.re);
    }
    assert!((a.im - 2.0 * PI).abs() < 1e-3 && (b.re + 2.0 * PI).abs() < 1e-3);
    println!("limit 2 pi i zeta: {:.6}i and {:.6}", 2.0 * PI, -2.0 * PI);
    // 6. what breaks
    let gb: Vec<f64> = [1.0, 10.0, 100.0].iter().map(|&e: &f64| PI * e * e / (2.0 * PI * e)).collect();
    let (tail, mut bq) = ((-64.0 * PI).exp() / (8.0 * PI), Vec::new()); // bell's area beyond 8 ms of its peak
    for e in [1.0, 10.0] { // the defining integral at zeta = i eta, cut at eta -+ 8
        let v = simpson(&|t| c((-PI * t * t + 2.0 * PI * e * t).exp(), 0.0), e - 8.0, e + 8.0, 2000).re;
        assert!((v / (PI * e * e).exp() - 1.0).abs() < 1e-9);
        bq.push(v.ln() / (2.0 * PI * e));
    }
    println!("bell by Simpson on [eta - 8, eta + 8] ms, tail share below {:.1e}: b at eta = 1, 10: {:.6} {:.6}", tail, bq[0], bq[1]);
    println!("bell e^(-pi t^2): b at eta = 1, 10, 100: {}", join(&gb, 6));
    let (ex, im) = (abs(cexp(c(PI * 10.0, 0.0))).ln(), abs(cexp(c(0.0, PI * 10.0))));
    println!("e^(pi zeta): ln size at 10 kHz {:.6}; size at 10i kHz {:.6}, so b = 0", ex, im);
    println!("half-width misread as width: {:.6} ms instead of 1.000000 ms", PI / (2.0 * PI));
    println!("ALL CHECKS PASS");
}
