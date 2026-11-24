// The Kuramoto model -- the same check as the Python, in Rust.  No crates.  2,000 oscillators,
// Lorentzian frequencies of half-width 0.5, so K_c = 1.  Three roads to r: the closed form, the
// self-consistency integral (Simpson, bisection) and RK4, starting phases from our own LCG.
use std::f64::consts::PI;
const G: f64 = 0.5; const N: usize = 2000;                // half-width, oscillators
const DT: f64 = 0.1; const T_END: f64 = 100.0; const T_AVG: f64 = 50.0;
fn g(w: f64) -> f64 { G / (PI * (w * w + G * G)) }      // the Lorentzian density
fn sum(v: &[f64]) -> f64 {                                // compensated sum, as Python's sum()
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for &x in v { let t = s + x; c += if s.abs() >= x.abs() { (s - t) + x } else { (x - t) + s }; s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn theory(k: f64, kc: f64) -> f64 { (1.0 - kc / k).max(0.0).sqrt() }
fn self_consistent(k: f64) -> f64 {                       // road two: solve the self-consistency
    let m = 400; let excess = |r: f64| {                               // locked-crowd integral / r - 1, Simpson
        let (h, x) = (PI / m as f64, |j: usize| -PI / 2.0 + j as f64 * PI / m as f64);
        let terms: Vec<f64> = (0..=m).map(|j| {
            let wt = if j == 0 || j == m { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
            wt * x(j).cos().powi(2) * g(k * r * x(j).sin())
        }).collect();
        k * sum(&terms) * h / 3.0 - 1.0
    };
    let (mut lo, mut hi) = (0.0, 1.0);                    // no positive root: hi falls to 0
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if excess(mid) > 0.0 { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn simulate(k: f64, om: &[f64], th0: &[f64]) -> (f64, Vec<f64>, Vec<f64>) {   // road three: RK4
    let f = |th: &[f64]| -> (Vec<f64>, f64) {             // theta' = omega + K r sin(psi - theta)
        let c: Vec<f64> = th.iter().map(|t| t.cos()).collect();
        let s: Vec<f64> = th.iter().map(|t| t.sin()).collect();
        let (cc, ss) = (sum(&c) / th.len() as f64, sum(&s) / th.len() as f64);
        ((0..th.len()).map(|i| om[i] + k * (ss * c[i] - cc * s[i])).collect(), cc.hypot(ss))
    };
    let step = |th: &[f64], kk: &[f64], a: f64| -> Vec<f64> { th.iter().zip(kk).map(|(t, q)| t + a * q).collect() };
    let (steps, avg) = ((T_END / DT).round() as usize, (T_AVG / DT).round() as usize);
    let (mut th, mut mid, mut rs) = (th0.to_vec(), th0.to_vec(), Vec::new());
    for n in 0..steps {
        let (k1, r) = f(&th);
        if n == steps - avg { mid = th.clone() }
        if n >= steps - avg { rs.push(r) }
        let (k2, _) = f(&step(&th, &k1, DT / 2.0));
        let (k3, _) = f(&step(&th, &k2, DT / 2.0));
        let (k4, _) = f(&step(&th, &k3, DT));
        th = (0..th.len()).map(|i| th[i] + DT / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    (sum(&rs) / rs.len() as f64, th, mid)
}
fn main() {
    let kc = 2.0 / (PI * g(0.0));                         // the critical coupling
    let om: Vec<f64> = (0..N).map(|i| G * (PI * ((i as f64 + 0.5) / N as f64 - 0.5)).tan()).collect();
    let mut seed: u64 = 2026;                             // 64-bit LCG, uniform in [0, 1)
    let th0: Vec<f64> = (0..N).map(|_| {
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        2.0 * PI * ((seed >> 11) as f64 / 9007199254740992.0)
    }).collect();
    println!("half-width {}, g(0) = {:.4}, K_c = 2/(pi g(0)) = {:.4}", G, g(0.0), kc);
    println!("K      closed form  integral   simulated, N = {}", N);
    let ks = [0.5, 0.8, 1.0, 1.2, 1.5, 2.0, 3.0, 4.0];
    let (mut sims, mut locked) = (Vec::new(), 0.0);
    for &k in &ks {
        let (r, th, mid) = simulate(k, &om, &th0);
        sims.push(r);
        println!("{:<6} {:<12.4} {:<10.4} {:.4}", format!("{:?}", k), theory(k, kc), self_consistent(k), r);
        if k == 2.0 { locked = (0..N).filter(|&i| ((th[i] - mid[i]) / T_AVG).abs() < 0.01).count() as f64 / N as f64 }
    }
    let a = 2.0 * theory(2.0, kc); let lock_th = 2.0 / PI * (a / G).atan();   // a = K r at K = 2
    println!("K = 2 by hand: K r = {:.4}; sqrt((K r)^2 + {}^2) = {:.4}; (that - {}) / (K r) = {:.4}",
             a, G, a.hypot(G), G, (a.hypot(G) - G) / a);
    println!("K = 0.8: simulated r = {:.4}; 1/sqrt(N) = {:.4}", sims[1], 1.0 / (N as f64).sqrt());
    println!("K = 2: share locked, simulated {:.4}; theory (2/pi) atan(K r / 0.5) = {:.4}", locked, lock_th);
    let (_, pair, _) = simulate(1.0, &[0.25, -0.25], &[0.0, 0.0]);
    println!("two oscillators, gap 0.5, K = 1: phase gap settles at {:.2} degrees", (pair[0] - pair[1]).to_degrees());
    println!("mistakes at K = 2: gamma = 1 gives K_c = {:.4} and r = {:.4}; no square root {:.4}; no 1/N {:.4}",
             2.0 * kc, theory(2.0, 2.0 * kc), 1.0 - kc / 2.0, theory(2.0 * N as f64, kc));
    assert!(ks.iter().all(|&k| (self_consistent(k) - theory(k, kc)).abs() < 1e-6));   // road 2 = road 1
    assert!((sims[5] - theory(2.0, kc)).abs() < 0.02 && (sims[7] - theory(4.0, kc)).abs() < 0.02);
    assert!(sims[1] < 5.0 / (N as f64).sqrt() && (locked - lock_th).abs() < 0.02);
    assert!(((pair[0] - pair[1]).to_degrees() - 30.0).abs() < 0.01);                 // the house pair
    println!("ALL CHECKS PASS");
}
