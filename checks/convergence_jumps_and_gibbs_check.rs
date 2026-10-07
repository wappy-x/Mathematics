// Convergence, jumps and Gibbs -- the same check as the Python, in Rust.  No crates.
// Square wave: -1 on (-pi, 0), +1 on (0, pi), period 2 pi.
// S(N, x) = (4/pi)(sin x + sin 3x/3 + ... + sin((2N-1)x)/(2N-1)), N odd harmonics.
use std::f64::consts::PI;

fn s(n: usize, x: f64) -> f64 {                   // road one: add the terms
    4.0 / PI * (1..=n).map(|k| ((2 * k - 1) as f64 * x).sin() / (2 * k - 1) as f64).sum::<f64>()
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // our own integrator
    let n = 4000;
    let h = (b - a) / n as f64;
    let w = |i: usize| if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=n).map(|i| g(a + i as f64 * h) * w(i)).sum::<f64>()
}

fn s_kernel(n: usize, x: f64) -> f64 {            // road two: S' = (2/pi) sin(2Nt)/sin t, from S(0) = 0
    let m = 2.0 * n as f64;
    2.0 / PI * simpson(&|t: f64| if t == 0.0 { m } else { (m * t).sin() / t.sin() }, 0.0, x)
}

fn tri_err(n: usize) -> f64 {                     // |x| minus its N-harmonic series, at x = 0
    (PI / 2.0 - 4.0 / PI * (1..=n).map(|k| 1.0 / ((2 * k - 1) as f64).powi(2)).sum::<f64>()).abs()
}

fn join(v: Vec<String>) -> String { v.join(", ") }

fn main() {
    let ns = [10usize, 50, 250];
    println!("square wave: -1 on (-pi, 0), +1 on (0, pi); N = number of odd harmonics");
    println!("at the jump x = 0: {}; midpoint of -1 and 1 = 0", join(ns.iter().map(|&n| format!("S_{} = {:.6}", n, s(n, 0.0))).collect()));
    println!("at x = pi/2 by hand: {}", join([1usize, 2, 3].iter().map(|&n| format!("S_{} = {:.4}", n, s(n, PI / 2.0))).collect()));
    println!("at x = pi/2, error S_N - 1: {}", join(ns.iter().map(|&n| format!("N = {}: {:+.6}", n, s(n, PI / 2.0) - 1.0)).collect()));
    let part: Vec<f64> = [50usize, 51].iter()
        .map(|&m| (1..=m).map(|k| if k % 2 == 1 { 1.0 } else { -1.0 } / (2 * k - 1) as f64).sum()).collect();
    let pi_int = simpson(&|t: f64| 4.0 / (1.0 + t * t), 0.0, 1.0);
    println!("Leibniz: 4 x (1 - 1/3 + ... 50 terms) = {:.6}; 4 x mean of 50 and 51 terms = {:.6}; pi as area under 4/(1+t^2) = {:.6}",
             4.0 * part[0], 2.0 * (part[0] + part[1]), pi_int);
    let mut peaks = Vec::new();
    for &n in &ns {
        let x = PI / (2 * n) as f64;              // first place S' is zero: sin(2Nx) = 0
        let (a, b) = (s(n, x), s_kernel(n, x));
        println!("peak N = {}: at x = pi/{} = {:.5}; by the terms {:.6}; by the kernel {:.6}", n, 2 * n, x, a, b);
        peaks.push((a, b));
    }
    let si_int = simpson(&|u: f64| if u == 0.0 { 1.0 } else { u.sin() / u }, 0.0, PI);
    let (mut si_ser, mut term) = (0.0, PI);       // Si(pi) = sum (-1)^n pi^(2n+1) / ((2n+1)(2n+1)!)
    for n in 0..30 {
        si_ser += term / (2 * n + 1) as f64;
        term *= -PI * PI / ((2 * n + 2) * (2 * n + 3)) as f64;
    }
    let lim = 2.0 / PI * si_ser;
    println!("limit (2/pi) Si(pi): by Simpson {:.6}; by power series {:.6}", 2.0 / PI * si_int, lim);
    println!("overshoot {:.6} above 1 = {:.2}% of the jump 2; read as % of the height 1: peak {:.2}, wrong",
             lim - 1.0, 100.0 * (lim - 1.0) / 2.0, 1.0 + (lim - 1.0) / 2.0);
    println!("square-wave overshoot, N = 10, 50, 250: {}", join(peaks.iter().map(|p| format!("{:.4}", p.0 - 1.0)).collect()));
    println!("triangle |x| worst error, N = 10, 50, 250: {}; times pi N: {}",
             join(ns.iter().map(|&n| format!("{:.6}", tri_err(n))).collect()),
             join(ns.iter().map(|&n| format!("{:.4}", tri_err(n) * PI * n as f64)).collect()));
    let xs: Vec<f64> = (0..21).map(|i| i as f64 / 100.0).collect();
    println!("figure, x: {}", join(xs.iter().map(|x| format!("{:.2}", x)).collect()));
    println!("figure, S_10: {}", join(xs.iter().map(|&x| format!("{:.2}", s(10, x))).collect()));
    println!("figure, S_50: {}", join(xs.iter().map(|&x| format!("{:.2}", s(50, x))).collect()));
    println!("mistake, value at the jump taken as f(0) = 1: series gives {:.2}, off by 1", s(50, 0.0));
    assert!(peaks.iter().all(|p| (p.0 - p.1).abs() < 1e-9));                  // two roads to each peak
    assert!((si_int - si_ser).abs() < 1e-9 && (peaks[2].0 - lim).abs() < 1e-4); // peak -> (2/pi) Si(pi)
    let avg_err = (2.0 * (part[0] + part[1]) - pi_int).abs();
    assert!(avg_err < 5e-4 && 5e-4 < (4.0 * part[0] - pi_int).abs());         // Leibniz, and averaging helps
    assert!((tri_err(250) * PI * 250.0 - 1.0).abs() < 0.01);                  // no jump: error dies like 1/(pi N)
    assert!(peaks.iter().map(|p| p.0).fold(f64::MAX, f64::min) - 1.0 > 0.178); // a jump: the overshoot stays
    println!("ALL CHECKS PASS");
}
