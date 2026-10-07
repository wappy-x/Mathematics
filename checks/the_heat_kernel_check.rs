// The heat kernel -- the same check as the Python, in Rust.  No crates.  Dye in
// a long tube, kappa = 0.01 cm^2/s.  Roads: the kernel formula; a halving walk
// stepped cell by cell; a grid stepped from a step start; Simpson integrals.
use std::f64::consts::PI;
const K: f64 = 0.01;

fn gk(x: f64, t: f64, k: f64) -> f64 { (-x * x / (4.0 * k * t)).exp() / (4.0 * PI * k * t).sqrt() }
fn g(x: f64, t: f64) -> f64 { gk(x, t, K) }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 4000;
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}
fn erf(z: f64) -> f64 {                          // Maclaurin series, fine for z <= 2
    let (mut s, mut term, mut n) = (0.0, z, 0.0);
    while term.abs() > 1e-17 { s += term / (2.0 * n + 1.0); n += 1.0; term *= -z * z / n; }
    2.0 / PI.sqrt() * s
}
fn step(mut u: Vec<f64>, r: f64, n: usize) -> Vec<f64> { // u_i += r (u_(i-1) - 2 u_i + u_(i+1))
    for _ in 0..n {
        let mut v = u.clone();
        for i in 1..u.len() - 1 { v[i] = u[i] + r * (u[i - 1] - 2.0 * u[i] + u[i + 1]); }
        u = v;
    }
    u
}

fn main() {
    let h = 1e-3;                                // 1. the kernel obeys u_t = kappa u_xx
    let gt = (g(1.0, 100.0 + h) - g(1.0, 100.0 - h)) / (2.0 * h);
    let gxx = K * (g(1.0 + h, 100.0) - 2.0 * g(1.0, 100.0) + g(1.0 - h, 100.0)) / (h * h);
    println!("at x = 1 cm, t = 100 s, in 1e-4 per s: u_t = {:.6}, kappa u_xx = {:.6}", gt * 1e4, gxx * 1e4);
    let fmt = |v: &[f64], p: usize, sep: &str| v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(sep);
    let areas: Vec<f64> = [100.0, 400.0].iter().map(|&t| simpson(&|x| g(x, t), -30.0, 30.0)).collect();
    println!("dye under the bell, t = 100 and 400 s: {}", fmt(&areas, 6, " "));
    let dx = 0.1;                                // 2. halving walk: r = 1/2, one tick = 0.5 s
    let mut walk = vec![0.0; 401]; walk[200] = 1.0;
    let (mut wid, mut dens) = (vec![], 0.0);
    for t in [100.0, 400.0] {
        let w = step(walk.clone(), 0.5, (t / 0.5) as usize);
        wid.push(w.iter().enumerate().map(|(i, m)| { let x = (i as f64 - 200.0) * dx; m * x * x }).sum::<f64>().sqrt());
        if t == 100.0 { dens = w[210] / (2.0 * dx); }
    }
    let formula: Vec<f64> = [100.0, 400.0].iter().map(|t| (2.0 * K * t).sqrt()).collect();
    println!("width sqrt(2 kappa t), t = 100 and 400 s: {} cm", fmt(&formula, 4, " "));
    println!("width of the halving walk, same times:    {} cm", fmt(&wid, 4, " "));
    println!("dye per cm at x = 1 cm, t = 100 s: bell {:.4}, walk {:.4}; peaks at 100 and 400 s: {:.4} {:.4}", g(1.0, 100.0), dens, g(0.0, 100.0), g(0.0, 400.0));
    for t in [100.0, 400.0] {
        let row: Vec<f64> = (-6..=6).map(|x| g(x as f64, t)).collect();
        println!("figure, bell t = {} s, x = -6..6 cm: {}", t, fmt(&row, 3, ", "));
    }
    let xq = [0.0, 1.0, 2.0];                    // 3. step start: 1 left of 0, clear water right
    let by_erf: Vec<f64> = xq.iter().map(|x| 0.5 * (1.0 - erf(x / (2.0 * (K * 100.0).sqrt())))).collect();
    let by_conv: Vec<f64> = xq.iter().map(|&x| simpson(&|s| g(s, 100.0), x, x + 20.0)).collect();
    println!("step start, t = 100 s, x = 0, 1, 2 cm: by erf   {}", fmt(&by_erf, 6, " "));
    println!("                           by kernel integral    {}", fmt(&by_conv, 6, " "));
    let mut errs = vec![];
    for d in [0.2f64, 0.1] {                        // cells d cm wide, r = 1/4, time step 25 d^2 s
        let n = (10.0 / d).round() as usize;
        let mut u = vec![1.0; n]; u.push(0.5); u.extend(vec![0.0; n]);
        let u = step(u, 0.25, (100.0 / (25.0 * d * d)).round() as usize);
        errs.push((u[n + (1.0 / d).round() as usize] - by_erf[1]).abs());
    }
    println!("grid error at x = 1 cm, cells 0.2 and 0.1 cm, in 1e-4: {:.2} {:.2}, ratio {:.2}", errs[0] * 1e4, errs[1] * 1e4, errs[0] / errs[1]);
    println!("step start at x = 10 cm, t = 100 s (by integral): {:.3e}", simpson(&|s| g(s, 100.0), 10.0, 30.0));
    let (s0, kx, r, q, sg, tt) = (100.0f64, 100.0f64, 0.05, 0.02, 0.2, 1.0); // 4. wing 12
    let m = s0.ln() + (r - q - sg * sg / 2.0) * tt;
    let call = (-r * tt).exp() * simpson(&|y: f64| (y.exp() - kx) * gk(y - m, tt, sg * sg / 2.0), kx.ln(), m + 12.0 * sg);
    println!("Black-Scholes call from the kernel: {:.9}", call);
    println!("mistake 1, width sqrt(kappa t) at 100 s: {:.4} cm", (K * 100.0).sqrt());
    println!("mistake 2, width taken to grow with t: {:.4} cm at 200 s; true {:.4} cm", 2.0 * (2.0 * K * 100.0).sqrt(), (2.0 * K * 200.0).sqrt());
    println!("mistake 3, bell without 1/sqrt(4 pi kappa t): dye total {:.4} at 100 s", simpson(&|x| (-x * x / 4.0).exp(), -30.0, 30.0));
    println!("mistake 4, run backwards 100 s: a ripple 1 cm long grows by e^{:.2}", K * (2.0 * PI).powi(2) * 100.0);
    assert!((gt - gxx).abs() < 1e-6 * gt.abs() && (gt - g(1.0, 100.0) * (1.0 / 400.0 - 1.0 / 200.0)).abs() < 1e-9);
    assert!(wid.iter().zip(&formula).all(|(a, b)| (a - b).abs() < 1e-9) && (dens - g(1.0, 100.0)).abs() < 0.01 * g(1.0, 100.0));
    assert!(by_erf.iter().zip(&by_conv).all(|(a, b)| (a - b).abs() < 1e-9) && errs[1] < 1e-3 && errs[0] / errs[1] > 3.5 && errs[0] / errs[1] < 4.5);
    assert!((call - 9.227005508154).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
