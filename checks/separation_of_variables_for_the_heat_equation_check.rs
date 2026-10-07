// Separation of variables -- the same check as the Python, in Rust.  No crates.
// A 1 m rod, kappa = 1 (scaled time), started at 100 C with both ends held at 0 C:
// u = sum over odd n of (400/(n pi)) e^(-n^2 pi^2 t) sin(n pi x).  Road one: that
// mode sum, its coefficients also found by Simpson's rule.  Road two: a grid that
// steps u_t = u_xx directly and knows nothing of modes.  Second case: a 0-to-100 C
// ramp with insulated ends, a cosine series.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, m: usize) -> f64 { // integral of f from 0 to 1, m even
    (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 / m as f64)).sum::<f64>() / (3 * m) as f64
}
fn sine_sum(x: f64, t: f64, terms: usize) -> f64 { // cold ends, uniform 100 C start; terms counts odd n
    (0..terms).map(|k| { let n = (2 * k + 1) as f64; 400.0 / (n * PI) * (-(n * PI).powi(2) * t).exp() * (n * PI * x).sin() }).sum()
}
fn cos_sum(x: f64, t: f64, terms: usize) -> f64 { // insulated ends, ramp 100x start
    50.0 - (0..terms).map(|k| { let n = (2 * k + 1) as f64; 400.0 / (n * PI).powi(2) * (-(n * PI).powi(2) * t).exp() * (n * PI * x).cos() }).sum::<f64>()
}
fn grid(n: usize, t_end: f64, insulated: bool) -> Vec<f64> { // n cells, time step dx^2/4
    let mut u: Vec<f64> = (0..=n).map(|i| if insulated { 100.0 * i as f64 / n as f64 } else if i == 0 || i == n { 0.0 } else { 100.0 }).collect();
    for _ in 0..(t_end * 4.0 * (n * n) as f64).round() as usize {
        let mut e = vec![u[1]]; e.extend(&u); e.push(u[n - 1]); // insulated: mirror points make the end slope zero
        let mut new: Vec<f64> = (0..=n).map(|i| e[i + 1] + (e[i] - 2.0 * e[i + 1] + e[i + 2]) / 4.0).collect();
        if !insulated { new[0] = 0.0; new[n] = 0.0; }
        u = new;
    }
    u
}
fn f3(v: f64) -> String { let s = format!("{:.3}", v); if s == "-0.000" { "0.000".to_string() } else { s } }
fn join(v: &[f64], f: &dyn Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let b_f: Vec<f64> = (1..7).map(|n| if n % 2 == 1 { 400.0 / (n as f64 * PI) } else { 0.0 }).collect();
    let b_s: Vec<f64> = (1..7).map(|n| simpson(&|x| 200.0 * (n as f64 * PI * x).sin(), 2000)).collect();
    let a_f: Vec<f64> = (1..5).map(|n| if n % 2 == 1 { -400.0 / (n as f64 * PI).powi(2) } else { 0.0 }).collect();
    let a_s: Vec<f64> = (1..5).map(|n| simpson(&|x| 200.0 * x * (n as f64 * PI * x).cos(), 2000)).collect();
    let mid = sine_sum(0.5, 0.05, 10000);
    let modes: Vec<f64> = [1.0f64, 3.0, 5.0].iter().map(|&n| 400.0 / (n * PI) * (-(n * PI).powi(2) * 0.05).exp() * (n * PI / 2.0).sin()).collect();
    let ns = [10usize, 20, 40, 80];
    let gm: Vec<f64> = ns.iter().map(|&n| grid(n, 0.05, false)[n / 2]).collect();
    let errs: Vec<f64> = gm.iter().map(|g| (g - mid).abs()).collect();
    let (end_s, end_g) = (cos_sum(0.0, 0.05, 400), grid(80, 0.05, true));
    println!("sine coefficients b1..b6, formula: {}", join(&b_f, &f3));
    println!("sine coefficients b1..b6, Simpson: {}", join(&b_s, &f3));
    println!("middle at t = 0, first 1 2 3 10 100 odd modes: {}", [1, 2, 3, 10, 100].iter().map(|&k| format!("{:.2}", sine_sum(0.5, 0.0, k))).collect::<Vec<_>>().join(" "));
    println!("decay factors e^(-n^2 pi^2 0.05), n = 1 3 5: {}", [1.0f64, 3.0, 5.0].iter().map(|&n| format!("{:.4}", (-(n * PI).powi(2) * 0.05).exp())).collect::<Vec<_>>().join(" "));
    println!("middle at t = 0.05: modes 1 3 5 give {:.2} {:.2} {:.4}; full sum {:.2} C", modes[0], modes[1], modes[2], mid);
    println!("grid middle at t = 0.05, N = 10 20 40 80: {}", join(&gm, &|v| format!("{:.4}", v)));
    println!("grid error: {}  ratios {}", join(&errs, &|v| format!("{:.4}", v)), (0..3).map(|i| format!("{:.2}", errs[i] / errs[i + 1])).collect::<Vec<_>>().join(" "));
    println!("copper, kappa 1.11e-4 m^2/s: one time unit = {:.0} s; t = 0.05 is {:.0} s = {:.1} min", 1.0 / 1.11e-4, 0.05 / 1.11e-4, 0.05 / 1.11e-4 / 60.0);
    println!("figure, x (m):     {}", (0..11).map(|i| format!("{:.1}", i as f64 / 10.0)).collect::<Vec<_>>().join(" "));
    for t in [0.01, 0.05, 0.2] {
        println!("figure, t = {:.2}: {}", t, (0..11).map(|i| format!("{:.2}", sine_sum(i as f64 / 10.0, t, 200))).collect::<Vec<_>>().join(" "));
    }
    println!("cosine coefficients a1..a4, formula: {}  Simpson: {}", join(&a_f, &f3), join(&a_s, &f3));
    let mean = (end_g.iter().sum::<f64>() - (end_g[0] + end_g[80]) / 2.0) / 80.0;
    println!("insulated ramp, end x = 0 at t = 0.05: series {:.2} C, grid {:.2} C; grid mean {:.2} C", end_s, end_g[0], mean);
    println!("mistake, dropping the 2 in b_n: middle at t = 0.05 is {:.2} C, not {:.2}", mid / 2.0, mid);
    let wrong: f64 = (0..10000).map(|k| { let n = (2 * k + 1) as f64; 400.0 / (n * PI) * (-n * PI * PI * 0.05).exp() * (n * PI / 2.0).sin() }).sum();
    println!("mistake, e^(-n pi^2 t) for e^(-n^2 pi^2 t): middle {:.2} C, not {:.2}", wrong, mid);
    let cold_mean: f64 = (0..200).map(|k| { let n = (2 * k + 1) as f64; 200.0 / (n * PI) * (-(n * PI).powi(2) * 0.5).exp() * 2.0 / (n * PI) }).sum();
    println!("mistake, insulated ends treated as cold: ramp's mean at t = 0.5 is {:.2} C, not {:.2}", cold_mean, simpson(&|x| cos_sum(x, 0.5, 50), 200));
    let worst = b_f.iter().chain(&a_f).zip(b_s.iter().chain(&a_s)).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max);
    assert!(worst < 1e-6); // closed form against numerical integral
    assert!(errs[3] < 0.02); // grid, no modes, lands on the mode sum
    assert!((0..3).all(|i| errs[i] / errs[i + 1] > 3.5 && errs[i] / errs[i + 1] < 4.5)); // and closes in at order two
    assert!((end_s - end_g[0]).abs() < 0.02); // insulated case: cosines against the grid
    println!("ALL CHECKS PASS");
}
