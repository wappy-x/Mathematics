// Finite differences on a grid -- the same check as the Python, in Rust.  No crates.
// Steel bar 1 m long, ends held at 0 C, diffusivity alpha = 1.2e-5 m^2/s (illustrative),
// start u = 100 sin(pi x) C.  Road one: step the explicit scheme in a loop.  Road two:
// the exact solution 100 e^(-alpha pi^2 t) sin(pi x), and the scheme's own factor g per
// step for this one sine.  Road three: the Lax bound, error <= sum of dt * max |tau|.
use std::f64::consts::PI;

const ALPHA: f64 = 1.2e-5; // m^2/s
const U0: f64 = 100.0; // C
const T: f64 = 3600.0; // s
const HS: [f64; 4] = [0.04, 0.02, 0.01, 0.005]; // space steps, m

fn sci(v: f64, d: usize) -> String { format!("{:.*e}", d, v) }

fn exact(x: f64, t: f64) -> f64 { U0 * (-ALPHA * PI * PI * t).exp() * (PI * x).sin() }

fn run(h: f64, r: f64, steps: usize, w_set: Option<f64>) -> Vec<f64> {
    let n = (1.0 / h).round() as usize;
    let w = w_set.unwrap_or(r);
    let mut u: Vec<f64> = (0..=n).map(|j| U0 * (PI * j as f64 * h).sin()).collect();
    for _ in 0..steps {
        let mut v = vec![0.0; n + 1];
        for j in 1..n { v[j] = w * u[j - 1] + (1.0 - 2.0 * w) * u[j] + w * u[j + 1]; }
        u = v;
    }
    u
}

fn tau(x: f64, t: f64, h: f64, dt: f64) -> f64 {
    let d2 = (exact(x + h, t) - 2.0 * exact(x, t) + exact(x - h, t)) / (h * h);
    (exact(x, t + dt) - exact(x, t)) / dt - ALPHA * d2
}

fn max_abs(v: impl Iterator<Item = f64>) -> f64 { v.fold(0.0, |m: f64, x| m.max(x.abs())) }

fn error_and_bound(h: f64, r: f64, t_end: f64) -> (f64, f64, usize) {
    let (n, dt) = ((1.0 / h).round() as usize, r * h * h / ALPHA);
    let steps = (t_end / dt).round() as usize;
    let u = run(h, r, steps, None);
    let err = max_abs((0..=n).map(|j| u[j] - exact(j as f64 * h, steps as f64 * dt)));
    let mut bound = 0.0;
    for m in 0..steps { bound += dt * max_abs((1..n).map(|j| tau(j as f64 * h, m as f64 * dt, h, dt))); }
    (err, bound, steps)
}

fn norm_inf(r: f64, n: usize) -> f64 {
    let mut best: f64 = 0.0;
    for i in 1..n {
        let mut s = (1.0 - 2.0 * r).abs();
        if i > 1 { s += r.abs(); }
        if i < n - 1 { s += r.abs(); }
        best = best.max(s);
    }
    best
}

fn orders(es: &[f64]) -> String {
    (0..es.len() - 1).map(|i| format!("{:.2}", (es[i] / es[i + 1]).log2())).collect::<Vec<_>>().join(", ")
}

fn list(es: &[f64], f: &dyn Fn(f64) -> String) -> String { es.iter().map(|&e| f(e)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (h, dt) = (0.02, 10.0);
    let r = ALPHA * dt / (h * h);
    println!("bar 1 m, alpha = {} m^2/s, start 100 sin(pi x) C, T = {:.0} s", sci(ALPHA, 1), T);
    println!("grid h = {} m, 51 nodes, dt = {:.0} s, r = {:.4}, steps {}; r <= 1/2 needs dt <= {:.3} s",
             h, dt, r, (T / dt).round(), h * h / (2.0 * ALPHA));
    println!("weights: {:.4}, {:.4}, {:.4}", r, 1.0 - 2.0 * r, r);
    let u1 = run(h, r, 1, None)[25];
    println!("middle after one step: scheme {:.6} C, exact {:.6} C", u1, exact(0.5, dt));
    let ut = run(h, r, 360, None)[25];
    let g = 1.0 - 4.0 * r * (PI * h / 2.0).sin().powi(2);
    println!("middle at T: loop {:.6} C, closed form 100 g^360 {:.6} C (g = {:.8}), exact {:.6} C", ut, U0 * g.powi(360), g, exact(0.5, T));
    println!("one-hour target: centre error below 0.01 C; centre error {:.4} C", (ut - exact(0.5, T)).abs());
    let d2e: Vec<f64> = HS.iter().map(|&hh| ((2.0 * U0 * (PI * hh).cos() - 2.0 * U0) / (hh * hh) + U0 * PI * PI).abs()).collect();
    println!("second difference of 100 sin(pi x) at 0.5, error: {}; orders {}", list(&d2e, &|e| format!("{:.6}", e)), orders(&d2e));
    println!("  predicted h^2/12 * 100 pi^4 at h = 0.02: {:.6}; exact value -100 pi^2 = {:.4}", h * h / 12.0 * U0 * PI.powi(4), -U0 * PI * PI);
    for (rr, name) in [(0.3, "0.3"), (1.0 / 6.0, "1/6")] {
        let ts: Vec<f64> = HS.iter().map(|&hh| tau(0.5, 0.0, hh, rr * hh * hh / ALPHA).abs()).collect();
        let lead = ALPHA * PI.powi(4) * h * h * U0 * (rr / 2.0 - 1.0 / 12.0);
        println!("tau at the middle, t = 0, r = {}: {} C/s; orders {}", name, list(&ts, &|t| sci(t, 3)), orders(&ts));
        println!("  leading term alpha pi^4 h^2 100 (r/2 - 1/12) at h = 0.02: {} C/s", sci(lead, 3));
    }
    println!("norm of the step, max row sum: r = 0.3: {:.4}, r = 0.5: {:.4}, r = 0.51: {:.4}", norm_inf(0.3, 50), norm_inf(0.5, 50), norm_inf(0.51, 50));
    let gz = 1.0 - 4.0 * 0.51 * (49.0 * PI * h / 2.0).sin().powi(2);
    println!("r = 0.51, h = 0.02: dt = {:.0} s, weights 0.5100, {:.4}, 0.5100, zigzag factor g = {:.6}; 1.04^200 = {:.1}; |g|^200 = {:.1}", 0.51 * h * h / ALPHA, 1.0 - 2.0 * 0.51, gz, 1.04f64.powi(200), gz.abs().powi(200));
    let (mut e3, mut b3) = (vec![], vec![]);
    for &hh in HS.iter() {
        let (e, b, s) = error_and_bound(hh, 0.3, T);
        e3.push(e);
        b3.push(b);
        println!("r = 0.3, h = {}: {} steps, true error {} C, bound {} C, bound / true {:.3}", hh, s, sci(e, 3), sci(b, 3), b / e);
    }
    let ratios: Vec<f64> = (0..3).map(|i| e3[i] / e3[i + 1]).collect();
    println!("r = 0.3: error ratio per halving {}; orders {}", list(&ratios, &|x| format!("{:.3}", x)), orders(&e3));
    let work: Vec<usize> = HS.iter().map(|&hh| ((1.0 / hh).round() as usize - 1) * (T / (0.3 * hh * hh / ALPHA)).round() as usize).collect();
    let wr: Vec<f64> = (0..3).map(|i| work[i + 1] as f64 / work[i] as f64).collect();
    println!("work, node updates to 3600 s at r = 0.3: {}; ratios {}", work.iter().map(|w| w.to_string()).collect::<Vec<_>>().join(", "), list(&wr, &|x| format!("{:.2}", x)));
    let e6: Vec<f64> = HS.iter().map(|&hh| error_and_bound(hh, 1.0 / 6.0, T).0).collect();
    println!("r = 1/6: true error {} C; orders {}", list(&e6, &|e| sci(e, 3)), orders(&e6));
    let e51: Vec<f64> = HS.iter().map(|&hh| {
        let dd = 0.51 * hh * hh / ALPHA;
        let u = run(hh, 0.51, (3400.0 / dd).round() as usize, None);
        max_abs((0..u.len()).map(|j| u[j] - exact(j as f64 * hh, 3400.0)))
    }).collect();
    println!("r = 0.51 at 3400 s, h = 0.04, 0.02, 0.01, 0.005: error {} C", list(&e51, &|e| sci(e, 3)));
    println!("chart x, log10 h: {}", list(&HS, &|x| format!("{:.2}", x.log10())));
    println!("chart, log10 error r = 0.3: {}", list(&e3, &|x| format!("{:.2}", x.log10())));
    println!("chart, log10 bound r = 0.3: {}", list(&b3, &|x| format!("{:.2}", x.log10())));
    println!("chart, log10 error r = 1/6: {}", list(&e6, &|x| format!("{:.2}", x.log10())));
    let sq: Vec<f64> = HS.iter().map(|&hh| run(hh, 0.0, 360, Some(ALPHA * dt / hh))[(0.5 / hh).round() as usize]).collect();
    println!("mistake, r = alpha dt / h with dt = 10 s: middle at T {} C; true {:.4} C; weight at h = 0.02: {:.4}",
             list(&sq, &|v| format!("{:.4}", v)), exact(0.5, T), ALPHA * dt / h);
    let bad = max_abs(run(0.01, 1.2, 360, None).into_iter());
    println!("mistake, h = 0.01 with dt = 10 s (r = {:.1}): largest |u| at T {} C", ALPHA * 10.0 / 0.0001, sci(bad, 3));
    assert!((ut - U0 * g.powi(360)).abs() < 1e-9); // loop equals the closed form g^n
    assert!((ut - exact(0.5, T)).abs() < 0.01); // r = 0.3 tracks the bar
    assert!((0..3).all(|i| { let p = (e3[i] / e3[i + 1]).log2(); p > 1.98 && p < 2.02 })); // order 2
    assert!((0..3).all(|i| { let p = (e6[i] / e6[i + 1]).log2(); p > 3.9 && p < 4.1 })); // r = 1/6: order 4
    assert!((0..4).all(|i| b3[i] / e3[i] > 1.0 && b3[i] / e3[i] < 2.0)); // the Lax bound holds
    assert!(e51[3] > 1e6 * e51[1]); // consistent but unstable: no convergence
    assert!((sq[3] - exact(0.5, T)).abs() > (sq[0] - exact(0.5, T)).abs()); // stable, inconsistent: wrong
    assert!(bad > 1e100); // h halved, dt kept: r = 1.2 blows up
    println!("ALL CHECKS PASS");
}
