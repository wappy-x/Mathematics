// Hadamard factorization -- the same check as the Python, in Rust.  No crates.
// sin(pi z) has order 1, so it is e^(az + b) pi z times the product of
// (1 - z^2/n^2); the code finds a = 0 and b = 0, checks the second-derivative
// identity the proof rests on, reads off Wallis, then does the same for xi.
use std::f64::consts::{E, PI};
const N: usize = 1000;

fn prod(z: f64, n: usize) -> f64 {           // pi z times the first n paired factors
    let mut p = PI * z;
    for k in 1..=n { p *= 1.0 - z * z / (k * k) as f64 }
    p * (-z * z / (n as f64 + 0.5)).exp()     // the tail's size, about z^2/(n + 1/2)
}

fn logmax(r: f64) -> f64 {                   // largest log|sin(pi z)| on |z| = r, by sampling
    let steps = 20000;
    let mut best: f64 = 0.0;
    for j in 0..=steps {
        let t = PI * j as f64 / steps as f64;
        let (x, y) = (r * t.cos(), r * t.sin());
        best = best.max(0.5 * ((PI * x).sin().powi(2) + (PI * y).sinh().powi(2)).ln());
    }
    best
}

fn zero_sum(z: f64) -> f64 {                 // minus the sum over every integer of 1/(z - n)^2
    let n = 100000;
    let s: f64 = (1..=n).map(|k| { let k = k as f64; 1.0 / (z - k).powi(2) + 1.0 / (z + k).powi(2) }).sum();
    -(1.0 / (z * z) + s + 2.0 / (n as f64 + 0.5))
}

fn lgam(x: f64) -> f64 {                     // log Gamma: shift up 8, then Stirling's series
    let s: f64 = -(0..8).map(|k| (x + k as f64).ln()).sum::<f64>();
    let y = x + 8.0;
    s + (y - 0.5) * y.ln() - y + 0.5 * (2.0 * PI).ln() + 1.0 / (12.0 * y) - 1.0 / (360.0 * y.powi(3)) + 1.0 / (1260.0 * y.powi(5))
}

fn log_xi(s: f64) -> f64 {                   // log xi(s), with (s - 1) zeta(s) by Euler-Maclaurin
    let n = 20.0_f64;
    let t: f64 = (1..20).map(|k| (k as f64).powf(-s)).sum::<f64>() + n.powf(-s) / 2.0 + s * n.powf(-s - 1.0) / 12.0
        - s * (s + 1.0) * (s + 2.0) * n.powf(-s - 3.0) / 720.0;
    (s / 2.0).ln() + ((s - 1.0) * t + n.powf(1.0 - s)).ln() - s / 2.0 * PI.ln() + lgam(s / 2.0)
}

fn main() {
    println!("log M(r)/r at r = 10, 100: {:.6}, {:.6}; closed form {:.6}, {:.6}", logmax(10.0) / 10.0, logmax(100.0) / 100.0,
             (10.0 * PI).sinh().ln() / 10.0, (100.0 * PI).sinh().ln() / 100.0);
    let jb = 10.0 * E * PI - 2f64.ln() - (10.0 * E * PI).ln();
    println!("zeros of sin(pi z)/(pi z) in |z| <= 10: 20; Jensen's bound {:.2}", jb);
    let h: f64 = (1..=N).map(|k| 1.0 / k as f64).sum();
    let q2: f64 = (1..=N).map(|k| 1.0 / (k * k) as f64).sum();
    println!("sum of 1/|n| over 0 < |n| <= {}: {:.4}; of 1/n^2: {:.6}", N, 2.0 * h, 2.0 * q2);
    for z in [0.5, 1.0 / 3.0] {
        println!("second log-derivative at z = {:.4}: -pi^2/sin^2 = {:.6}, zero sum = {:.6}", z, -(PI / (PI * z).sin()).powi(2), zero_sum(z));
    }
    let a = (((0.7 * PI).sin() / prod(0.7, N)).ln() - ((0.3 * PI).sin() / prod(0.3, N)).ln()) / 0.4;
    let b = ((0.3 * PI).sin() / prod(0.3, N)).ln() - 0.3 * a;
    println!("fitted from the product at z = 0.3 and 0.7: a = {:.6}, e^b = {:.6}", a.abs(), b.exp());
    let w: Vec<f64> = [10, 100, 1000].iter().map(|&n| prod(0.5, n) / (PI / 2.0) * (0.25 / (n as f64 + 0.5)).exp()).collect();
    println!("Wallis partial products, N = 10, 100, 1000: {:.6}, {:.6}, {:.6}", w[0], w[1], w[2]);
    println!("tail-corrected at N = 1000: {:.6}; 2/pi = {:.6}", prod(0.5, N) / (PI / 2.0), 2.0 / PI);
    let xi1 = log_xi(1.0).exp();
    let gam = (1..=10000).map(|k| 1.0 / k as f64).sum::<f64>() - 10000f64.ln() - 1.0 / 20000.0 + 1.0 / (12.0 * 1e8);
    let (b1, b2) = (-1.0 - gam / 2.0 + (4.0 * PI).ln() / 2.0, -(log_xi(1.001) - log_xi(0.999)) / 0.002);
    println!("xi(0) = xi(1) = {:.6}, so e^A = {:.6}", xi1, xi1);
    println!("Euler's constant from 1 + 1/2 + ... + 1/n - ln n: {:.6}", gam);
    println!("B = -1 - gamma/2 + ln(4 pi)/2 = {:.6}; B from the slope of ln xi at 1: {:.6}", b1, b2);
    let q = (1..=N).map(|k| (1.0 - 0.5 / k as f64).ln()).sum::<f64>().exp();
    println!("mistake 1, positive zeros only, no e^(z/n): product at 1/2 = {:.6} and falling", q);
    println!("mistake 2, e^z sin(pi z) has the same zeros: at 1/2 it reads {:.6}, not 1", 0.5f64.exp() * (PI / 2.0).sin());
    println!("mistake 3, dropping the pi: z times the product at 1/2 = {:.6}, not 1", 0.5 * 2.0 / PI);
    assert!((logmax(10.0) - (10.0 * PI).sinh().ln()).abs() < 1e-6 && (logmax(10.0 * E) - (10.0 * E * PI).ln() - jb).abs() < 1e-6);
    assert!((zero_sum(0.5) + PI * PI).abs() < 1e-9 && (zero_sum(1.0 / 3.0) + 4.0 * PI * PI / 3.0).abs() < 1e-9);
    assert!(a.abs() < 1e-6 && (b.exp() - 1.0).abs() < 1e-6 && (prod(0.5, N) / (PI / 2.0) - 2.0 / PI).abs() < 1e-7);
    assert!((xi1 - 0.5).abs() < 1e-9 && (b1 - b2).abs() < 1e-6 && b1 < 0.0);
    println!("ALL CHECKS PASS");
}
