// Fourier series of a square wave -- the same check as the Python, in Rust, std
// only.  Road one: the closed form b_n = 4/(n pi).  Road two: integrals over one
// period by a midpoint rule written here.  Road three: best single sine by search.
use std::f64::consts::PI;
const M: usize = 20000;                             // midpoint cells across one period

fn f(x: f64) -> f64 { if x.rem_euclid(2.0 * PI) < PI { 1.0 } else { -1.0 } }

fn integral(g: &dyn Fn(f64) -> f64) -> f64 {       // midpoint rule from -pi to pi
    let h = 2.0 * PI / M as f64;
    h * (0..M).map(|i| g(-PI + (i as f64 + 0.5) * h)).sum::<f64>()
}

fn closed_b(n: usize) -> f64 {                      // road one: 4/(n pi) for odd n, 0 for even
    if n % 2 == 1 { 4.0 / (n as f64 * PI) } else { 0.0 }
}

fn partial(x: f64, top: usize) -> f64 {             // S_N: the sine terms up to harmonic top
    (1..=top).map(|n| closed_b(n) * (n as f64 * x).sin()).sum()
}

fn err(g: &dyn Fn(f64) -> f64) -> f64 {             // mean-square miss: integral of (f - g)^2
    integral(&|x| (f(x) - g(x)).powi(2))
}

fn fmt(xs: &[f64], d: usize) -> String {
    xs.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let mut ss = [[0.0f64; 3]; 3];
    for m in 0..3 { for n in 0..3 {
        ss[m][n] = integral(&|x| ((m + 1) as f64 * x).sin() * ((n + 1) as f64 * x).sin());
    } }
    let mut sc = 0.0f64;
    for m in 1..=3 { for n in 0..4 {
        sc = sc.max(integral(&|x| (m as f64 * x).sin() * (n as f64 * x).cos()).abs());
    } }
    let cross = integral(&|x| x.sin() * (1.5 * x).sin());
    let cross_closed = (0.5 * PI).sin() / 0.5 - (2.5 * PI).sin() / 2.5;   // product-to-sum
    let a: Vec<f64> = (0..6).map(|n| integral(&|x| f(x) * (n as f64 * x).cos()) / PI).collect();
    let b: Vec<f64> = (1..6).map(|n| integral(&|x| f(x) * (n as f64 * x).sin()) / PI).collect();
    let (mut lo, mut hi, r) = (0.0f64, 3.0f64, (5.0f64.sqrt() - 1.0) / 2.0);   // road three
    for _ in 0..40 {
        let (p, q) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if err(&|x| p * x.sin()) < err(&|x| q * x.sin()) { hi = q } else { lo = p }
    }
    let best = (lo + hi) / 2.0;
    let xs: Vec<f64> = (0..16).map(|k| (k as f64 + 0.5) * PI / 8.0).collect();
    let mut off = 0.0f64;
    for m in 0..3 { for n in 0..3 { if m != n { off = off.max(ss[m][n].abs()) } } }
    let amax = a.iter().fold(0.0f64, |acc, v| acc.max(v.abs()));
    let misses: Vec<f64> = [1, 3, 5].iter().map(|&t| err(&|x| partial(x, t))).collect();
    println!("a 220 Hz tone: harmonics at {} Hz; one cycle lasts {:.2} ms", fmt(&[220.0, 660.0, 1100.0], 0), 1000.0 / 220.0);
    println!("integral of sin(nx)^2, n = 1..3: {}; pi = {:.6}", fmt(&[ss[0][0], ss[1][1], ss[2][2]], 6), PI);
    println!("largest |integral of sin(mx) sin(nx)|, m not n: {:.6}; of sin(mx) cos(nx): {:.6}", off, sc);
    println!("frequency 1.5, integral of sin(x) sin(1.5x): {:.6} by midpoint, {:.6} by identity", cross, cross_closed);
    println!("largest |a_n|, n = 0..5, by integral: {:.6}", amax);
    println!("b_1, b_3, b_5 by integral: {}; largest |b_2|, |b_4|: {:.6}", fmt(&[b[0], b[2], b[4]], 6), b[1].abs().max(b[3].abs()));
    println!("b_1, b_3, b_5 by 4/(n pi): {}", fmt(&[closed_b(1), closed_b(3), closed_b(5)], 6));
    println!("best single sine by search: b = {:.6}; 4/pi = {:.6}", best, 4.0 / PI);
    println!("mean-square miss with harmonics up to 1, 3, 5: {}", fmt(&misses, 6));
    println!("mistake, one sine at the wave's height, b = 1: mean-square miss {:.6}", err(&|x: f64| x.sin()));
    println!("S_5 at x = pi/2: {:.6}", partial(PI / 2.0, 5));
    println!("mistake, dividing by 2 pi instead of pi: b_1 = {:.6}", b[0] / 2.0);
    println!("chart, x in radians: {}", fmt(&xs, 2));
    println!("chart, S_1: {}", fmt(&xs.iter().map(|&x| partial(x, 1)).collect::<Vec<_>>(), 2));
    println!("chart, S_5: {}", fmt(&xs.iter().map(|&x| partial(x, 5)).collect::<Vec<_>>(), 2));
    assert!((0..3).all(|n| (ss[n][n] - PI).abs() < 1e-6) && off < 1e-9 && sc < 1e-9);
    assert!((1..6).all(|n| (b[n - 1] - closed_b(n)).abs() < 1e-6) && amax < 1e-9);
    assert!((best - 4.0 / PI).abs() < 1e-5);                  // search lands on the projection
    assert!((cross - cross_closed).abs() < 1e-6);             // the cross-talk number, two ways
    println!("ALL CHECKS PASS");
}
