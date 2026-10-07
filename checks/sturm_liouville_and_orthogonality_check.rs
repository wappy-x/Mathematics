// Sturm-Liouville and orthogonality -- the same check as the Python, in Rust.  No crates;
// integrator, Bessel functions and root finder are written here.  Each claim is reached
// twice: Simpson against antiderivatives, J0 zeros by series and by integral, norm by J1.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // Simpson's rule, n even
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h)).sum();
    (f(a) + f(b) + inner) * h / 3.0
}

fn z(v: f64) -> f64 { if v.abs() < 5e-10 { 0.0 } else { v } } // print a vanishing number as 0

fn j_series(x: f64, order: i32) -> f64 {           // J0 or J1 from its power series
    let (mut term, mut k) = ((x / 2.0).powi(order), 0.0);
    let mut total = term;
    while term.abs() > 1e-18 {
        k += 1.0;
        term *= -(x / 2.0).powi(2) / (k * (k + order as f64));
        total += term;
    }
    total
}

fn j0_integral(x: f64) -> f64 {                    // J0(x) = (1/pi) * integral of cos(x sin t)
    simpson(&|t: f64| (x * t.sin()).cos(), 0.0, PI, 200) / PI
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // root finder, 60 halvings
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn main() {
    let pairs = [(1.0, 1.0), (1.0, 2.0), (2.0, 2.0), (1.0, 3.0), (2.0, 3.0)];
    let num: Vec<f64> = pairs.iter().map(|&(m, n)| simpson(&|x: f64| (m * PI * x).sin() * (n * PI * x).sin(), 0.0, 1.0, 2000)).collect();
    let anti: Vec<f64> = pairs.iter().map(|&(m, n)| if m == n { 0.5 } else {
        (((m - n) * PI).sin() / (m - n) - ((m + n) * PI).sin() / (m + n)) / (2.0 * PI) }).collect();
    let show = |v: &Vec<f64>| pairs.iter().zip(v).map(|(&(m, n), &x)| format!(" ({},{}) {:.6}", m, n, z(x))).collect::<String>();
    println!("string, Simpson:      {}", show(&num));
    println!("string, antiderivative:{}", show(&anti));
    assert!(num.iter().zip(&anti).all(|(a, b)| (a - b).abs() < 1e-12));
    let lobe = simpson(&|x: f64| (PI * x).sin() * (2.0 * PI * x).sin(), 0.0, 0.5, 2000);
    println!("lobes of sin(pi x) sin(2 pi x): +{:.6} and -{:.6}; 2/(3 pi) = {:.6}", lobe, lobe, 2.0 / (3.0 * PI));
    let j0 = |x: f64| j_series(x, 0);
    let (j1, j2) = (bisect(&j0, 2.0, 3.0), bisect(&j0, 5.0, 6.0));
    let (i1, i2) = (bisect(&j0_integral, 2.0, 3.0), bisect(&j0_integral, 5.0, 6.0));
    println!("drum J0 zeros, series road: {:.9}, {:.9}; integral road: {:.9}, {:.9}", j1, j2, i1, i2);
    assert!((j1 - i1).abs() < 1e-9 && (j2 - i2).abs() < 1e-9);
    let wcross = simpson(&|r: f64| r * j0(j1 * r) * j0(j2 * r), 0.0, 1.0, 2000);
    let wnorm = simpson(&|r: f64| r * j0(j1 * r).powi(2), 0.0, 1.0, 2000);
    let bare = simpson(&|r: f64| j0(j1 * r) * j0(j2 * r), 0.0, 1.0, 2000);
    let half_j1sq = j_series(j1, 1).powi(2) / 2.0;
    println!("drum, weight r: cross {:.9}; norm {:.9}, J1(j1)^2/2 = {:.9}", z(wcross), wnorm, half_j1sq);
    println!("drum, weight dropped: cross {:.6}, not 0", bare);
    assert!(wcross.abs() < 1e-10 && (wnorm - half_j1sq).abs() < 1e-10);
    let cs: Vec<f64> = (1..4).map(|n| 2.0 * simpson(&|x: f64| x * (1.0 - x) * (n as f64 * PI * x).sin(), 0.0, 1.0, 2000)).collect();
    let cp: Vec<f64> = (1..8).map(|n| 4.0 * (1.0 - (-1f64).powi(n)) / (n as f64 * PI).powi(3)).collect();
    println!("arch x(1 - x), c_1 c_2 c_3 by Simpson: {}", cs.iter().map(|c| format!("{:.6}", z(*c))).collect::<Vec<_>>().join(" "));
    println!("arch x(1 - x), c_1 c_2 c_3 by parts:   {}", cp[..3].iter().map(|c| format!("{:.6}", c)).collect::<Vec<_>>().join(" "));
    assert!(cs.iter().zip(&cp).all(|(a, b)| (a - b).abs() < 1e-12));
    let sums: Vec<String> = [1, 3, 5, 7].iter().map(|&n| {
        let s: f64 = (0..n).map(|k| cp[k] * ((k + 1) as f64 * PI / 2.0).sin()).sum();
        format!("N={} {:.6}", n, s) }).collect();
    println!("partial sums at x = 0.5, target 0.25: {}", sums.join(", "));
    println!("mistake, norm 1/2 left out: c_1 = {:.6}, half the true {:.6}", 4.0 / PI.powi(3), cp[0]);
    println!("mistake, slope-zero mode 1 against sin(pi x): {:.6}, not 0", simpson(&|x: f64| (PI * x).sin(), 0.0, 1.0, 2000));
    let xp = (1.0 / 3f64.sqrt()).acos() / PI;
    let yp = (PI * xp).sin() * (2.0 * PI * xp).sin();
    println!("figure, peak x = {:.4} value {:.4} at ({:.1}, {:.1}), trough at ({:.1}, {:.1})",
             xp, yp, 40.0 + 280.0 * xp, 120.0 - 100.0 * yp, 40.0 + 280.0 * (1.0 - xp), 120.0 + 100.0 * yp);
    println!("ALL CHECKS PASS");
}
