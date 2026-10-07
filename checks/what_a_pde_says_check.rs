// A partial differential equation -- the same check as the Python, in Rust.  No
// crates.  Road one sorts seven equations by B^2 - 4AC and solves the rod, string
// and plate in closed form.  Road two sorts them by scanning directions, and steps
// the rod, string and plate on finite-difference grids that never see the answers.
use std::f64::consts::PI;

fn by_discriminant(a: i64, b: i64, c: i64) -> (i64, &'static str) {   // road one: the sign of B^2 - 4AC
    let d = b * b - 4 * a * c;
    (d, if d > 0 { "hyperbolic" } else if d == 0 { "parabolic" } else { "elliptic" })
}
fn by_scan(a: f64, b: f64, c: f64) -> &'static str {   // road two: signs of A p^2 + B p q + C q^2 round a half circle
    let (mut lo, mut hi) = (f64::INFINITY, f64::NEG_INFINITY);
    for j in 0..3600 {
        let t = PI * j as f64 / 3600.0;
        let q = a * t.cos().powi(2) + b * t.cos() * t.sin() + c * t.sin().powi(2);
        lo = lo.min(q); hi = hi.max(q);
    }
    if lo < -1e-9 && hi > 1e-9 { "hyperbolic" } else if lo > 1e-9 || hi < -1e-9 { "elliptic" } else { "parabolic" }
}
fn lap(u: &[f64], j: usize, h: f64) -> f64 { (u[j - 1] - 2.0 * u[j] + u[j + 1]) / (h * h) }
fn heat(n: usize, t_end: f64) -> f64 {                  // rod: each point moves toward its neighbours' mean
    let (h, mut u): (f64, Vec<f64>) = (1.0 / n as f64, (0..=n).map(|j| (PI * j as f64 / n as f64).sin()).collect());
    let dt = 0.25 * h * h;
    for _ in 0..(t_end / dt).round() as usize {
        let mut v = vec![0.0; n + 1];
        for j in 1..n { v[j] = u[j] + dt * lap(&u, j, h) }
        u = v;
    }
    u[n / 2]
}
fn wave(v0: f64, n: usize, t_end: f64) -> f64 {         // string: the bend sets the acceleration, leapfrog steps
    let h = 1.0 / n as f64; let dt = h / 2.0;
    let mut old: Vec<f64> = (0..=n).map(|j| (PI * j as f64 * h).sin()).collect();
    let mut now = vec![0.0; n + 1];
    for j in 1..n { now[j] = old[j] + dt * v0 * old[j] + dt * dt / 2.0 * lap(&old, j, h) }
    for _ in 0..(t_end / dt).round() as usize - 1 {
        let mut next = vec![0.0; n + 1];
        for j in 1..n { next[j] = 2.0 * now[j] - old[j] + dt * dt * lap(&now, j, h) }
        old = now; now = next;
    }
    now[n / 2]
}
fn plate(n: usize, sweeps: usize) -> f64 {              // plate: each inside point becomes its neighbours' mean
    let mut u = vec![vec![0.0; n + 1]; n + 1];
    for i in 0..=n { u[n][i] = (PI * i as f64 / n as f64).sin() }
    for _ in 0..sweeps { for j in 1..n { for i in 1..n {
        u[j][i] = (u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4.0;
    } } }
    u[n / 2][n / 2]
}
fn main() {
    let cases = [("heat u_t = u_xx", 1, 0, 0), ("wave u_tt = u_xx", 1, 0, -1), ("Laplace u_xx + u_yy = 0", 1, 0, 1),
        ("Tricomi y u_xx + u_yy at y = 1", 1, 0, 1), ("Tricomi y u_xx + u_yy at y = -1", -1, 0, 1), ("trap u_xx + 3u_xy + u_yy", 1, 3, 1),
        ("tilted u_xx + 2u_xy + u_yy", 1, 2, 1)];
    let mut agree = true;
    for (name, a, b, c) in cases {
        let (d, k1) = by_discriminant(a, b, c); let k2 = by_scan(a as f64, b as f64, c as f64);
        agree &= k1 == k2;
        println!("{}: A {}, B {}, C {}, B^2 - 4AC {} -> {}; direction scan -> {}", name, a, b, c, d, k1, k2);
    }
    let rod = (-PI * PI * 0.1).exp(); let (e1, e2) = ((heat(10, 0.1) - rod).abs(), (heat(20, 0.1) - rod).abs());
    println!("rod middle at t = 0.1: closed {:.4}; grid error {:.6} at h = 0.1, {:.6} at h = 0.05; halves at t = {:.4}", rod, e1, e2, 2f64.ln() / (PI * PI));
    let (pl, st) = (wave(0.0, 40, 0.5), wave(1.0, 40, 0.5));
    println!("string middle at t = 0.5: plucked closed {:.4}, grid {:.4}; struck closed {:.4}, grid {:.4}", (PI / 2.0).cos(), pl, 1.0 / PI, st);
    let (pc, pg) = ((PI / 2.0).sinh() / PI.sinh(), plate(20, 2000));
    println!("plate centre: closed {:.4}, grid {:.4} at h = 0.05", pc, pg);
    let ts: Vec<f64> = (0..21).map(|k| k as f64 / 10.0).collect();
    println!("chart rod middle: {}", ts.iter().map(|t| format!("{:.2}", (-PI * PI * t).exp())).collect::<Vec<_>>().join(", "));
    println!("chart string middle: {}", ts.iter().map(|t| format!("{:.2}", (PI * t).cos())).collect::<Vec<_>>().join(", "));
    println!("figure, panels left x {}, width 90 (1 m), bottom y 190, top y 100 (t = 1 or y = 1 m)", (0..3).map(|p| (20 + 115 * p).to_string()).collect::<Vec<_>>().join(", "));
    println!("mistake 1, string given its shape only: middle at t = 0.5 is {:.4} or {:.4}, both fit", (PI / 2.0).cos(), 1.0 / PI);
    println!("mistake 2, plate given value and slope on one edge: slope data sin(10x)/10, at y = 1 m u reaches {:.2}; data sin(20x)/20 gives {:.0}", 10f64.sinh() / 100.0, 20f64.sinh() / 400.0);
    println!("mistake 3, rod run backwards 0.01: noise 0.001 sin(10 pi x) grows to {:.2}, the true profile only x{:.4}", 0.001 * (100.0 * PI * PI * 0.01).exp(), (PI * PI * 0.01).exp());
    assert!(agree);                                         // two roads, one sorting
    assert!(e1 / e2 > 3.5 && e1 / e2 < 4.5 && e2 < 1e-3);   // the rod's grid closes on e^(-pi^2 t) at second order
    assert!(pl.abs() < 1e-3 && (st - 1.0 / PI).abs() < 1e-3);   // the string's grid matches both closed forms
    assert!((pg - pc).abs() < 2e-3);                        // the plate's averaging matches the closed form
    println!("ALL CHECKS PASS");
}
