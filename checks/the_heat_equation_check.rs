// The heat equation -- the same check as the Python, in Rust.  No crates.
// The rod: 1 m, ends held at 0 C, kappa = 1 in scaled time, starting at
// u = sin(pi x).  Road one is the formula e^(-kappa n^2 pi^2 t).  Road two
// is a grid where each point drifts toward its neighbours' average.
use std::f64::consts::PI;

fn step(u: &[f64], r: f64, heat: f64) -> Vec<f64> {      // one grid step, ends held at 0
    let n = u.len();
    let mut v = vec![0.0; n];
    for i in 1..n - 1 { v[i] = u[i] + r * (u[i - 1] - 2.0 * u[i] + u[i + 1]) + heat; }
    v
}

fn grid_half_life(n: usize, big_n: usize, r: f64) -> f64 { // step sin(n pi x) until its peak halves
    let dx = 1.0 / big_n as f64;
    let dt = r * dx * dx;
    let mut u: Vec<f64> = (0..=big_n).map(|i| (n as f64 * PI * i as f64 * dx).sin()).collect();
    let j = big_n / (2 * n);
    let (top, mut t) = (u[j], 0.0);
    loop {
        let v = step(&u, r, 0.0);
        t += dt;
        if v[j] <= top / 2.0 {                             // the last step, read as a pure exponential
            return t - dt + dt * (2.0 * u[j] / top).ln() / (u[j] / v[j]).ln();
        }
        u = v;
    }
}

fn big_u(x: f64, t: f64) -> f64 { (-PI * PI * t).exp() * (PI * x).sin() } // the formula, kappa = 1

fn main() {
    let (lam1, lam2) = (PI * PI, 4.0 * PI * PI);
    let (h1, h2) = (2f64.ln() / lam1, 2f64.ln() / lam2);
    println!("decay rate kappa n^2 pi^2: n=1 {:.6}, n=2 {:.6} per time unit", lam1, lam2);
    println!("half-life ln2/rate: n=1 {:.6}, n=2 {:.6}, ratio {:.3}", h1, h2, h1 / h2);
    let g: Vec<f64> = [10, 20, 40].iter().map(|&n| grid_half_life(1, n, 0.25)).collect();
    for (k, n) in [10, 20, 40].iter().enumerate() {
        println!("grid N={}: half-life {:.6}, error {:.7}", n, g[k], g[k] - h1);
    }
    println!("error shrinks per halving of the spacing h, dt = h^2/4: {:.3}, {:.3}", (g[0] - h1) / (g[1] - h1), (g[1] - h1) / (g[2] - h1));
    let g2 = grid_half_life(2, 40, 0.25);
    println!("grid N=40, n=2: half-life {:.6}; grid ratio {:.3}", g2, g[2] / g2);
    let (e, x, t) = (1e-4, 0.3, 0.05);
    let ut = (big_u(x, t + e) - big_u(x, t - e)) / (2.0 * e);
    let uxx = (big_u(x + e, t) - 2.0 * big_u(x, t) + big_u(x - e, t)) / (e * e);
    println!("formula at x=0.3, t=0.05, by differences: u_t {:.6}, u_xx {:.6}", ut, uxx);
    let mut u: Vec<f64> = (0..=40).map(|i| (i as f64 / 12.0).min((40 - i) as f64 / 28.0)).collect(); // tent
    let mut peaks = Vec::new();
    for _ in 0..400 { u = step(&u, 0.25, 0.0); peaks.push(u.iter().cloned().fold(f64::MIN, f64::max)); }
    let most = peaks.iter().cloned().fold(f64::MIN, f64::max);
    println!("tent start, peak 1 at x=0.3: largest later value {:.6}, at t=0.0625 {:.6}", most, peaks[399]);
    let mut w: Vec<f64> = (0..=20).map(|i| (PI * i as f64 / 20.0).sin()).collect(); // a heater: 20 C per time unit
    for _ in 0..1600 { w = step(&w, 0.25, 20.0 * 0.25 / 400.0); }
    println!("heater inside: middle at t=1 {:.6}; steady formula 20/8 = {:.6}", w[10], 20.0 / 8.0);
    println!("mistake, rate linear in n: n=2 half-life {:.6}, true {:.6}", 2f64.ln() / (2.0 * PI * PI), h2);
    let grow = 100.0 * PI * PI * 0.1;
    println!("mistake, sign flipped: ripple 0.001 at n=10 after t=0.1 grows by e^{:.3} = 10^{:.2}", grow, grow / 10f64.ln());
    let tu = 1.0 / 1.11e-4;                                // copper, 1 m: seconds per time unit
    println!("copper rod 1 m, kappa 1.11e-4 m^2/s: time unit {:.0} s, half-life {:.0} s = {:.1} min", tu, h1 * tu, h1 * tu / 60.0);
    let ts: Vec<f64> = (0..9).map(|k| 0.035 * k as f64).collect();
    let row = |lam: f64| ts.iter().map(|s| format!("{:.2}", (-lam * s).exp())).collect::<Vec<_>>().join(", ");
    println!("chart n=1: {}", row(lam1));
    println!("chart n=2: {}", row(lam2));
    println!("chart times: {}", ts.iter().map(|s| format!("{:.3}", s)).collect::<Vec<_>>().join(", "));
    let (a1, a2) = (big_u(0.5, h1), (-lam2 * h1).exp());   // heights after one half-life of n=1
    println!("figure, x 40+300x, y 120-90u; at t=0.070 heights n=1 {:.4}, n=2 {:.4}, y {:.1}, {:.1}", a1, a2, 120.0 - 90.0 * a1, 120.0 - 90.0 * a2);
    assert!((g[2] - h1).abs() < 2e-5 && (g2 - h2).abs() < 2e-5);        // the grid meets the formula
    assert!((ut - uxx).abs() < 1e-5 * uxx.abs());                       // the formula obeys u_t = u_xx
    assert!(most <= 1.0 && peaks.windows(2).all(|p| p[0] >= p[1]));    // no new hot spot
    assert!((w[10] - 2.5).abs() < 1e-3);                                // the heater breaks the bound
    println!("ALL CHECKS PASS");
}
