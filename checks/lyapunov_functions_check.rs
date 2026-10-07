// Lyapunov functions -- the same check as the Python, in Rust, no crates.
// A ball settling in a bowl: x' = -x^3, x in cm from the bottom, t in s,
// V = x^2/2.  Road one: closed forms from separating variables.  Road two:
// Runge-Kutta 4 steps written out below.
type F = fn(&[f64]) -> Vec<f64>;

fn rk4(f: F, s0: &[f64], h: f64, n: usize) -> Vec<f64> {    // n classical RK4 steps
    let mut s = s0.to_vec();
    let add = |s: &[f64], k: &[f64], c: f64| -> Vec<f64> { s.iter().zip(k).map(|(a, b)| a + c * b).collect() };
    for _ in 0..n {
        let k1 = f(&s); let k2 = f(&add(&s, &k1, h / 2.0));
        let k3 = f(&add(&s, &k2, h / 2.0)); let k4 = f(&add(&s, &k3, h));
        s = (0..s.len()).map(|i| s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    s
}

fn first_time(f: F, x0: f64, h: f64, done: &dyn Fn(f64) -> bool) -> f64 {   // step until done(x)
    let (mut s, mut n) = (vec![x0], 0);
    while !done(s[0]) { s = rk4(f, &s, h, 1); n += 1; }
    n as f64 * h
}

fn settle(s: &[f64]) -> Vec<f64> { vec![-s[0].powi(3)] }
fn burst(s: &[f64]) -> Vec<f64> { vec![s[0].powi(3)] }
fn lin(s: &[f64]) -> Vec<f64> { vec![-s[0]] }                    // the linear bowl, for contrast
fn free(s: &[f64]) -> Vec<f64> { vec![s[1], -s[0].powi(3)] }     // no friction: x' = y, y' = -x^3
fn local(s: &[f64]) -> Vec<f64> { vec![-s[0] + s[0].powi(3)] }   // V' = -x^2 (1 - x^2)
fn closed(x0: f64, t: f64) -> f64 { x0 / (1.0 + 2.0 * x0 * x0 * t).sqrt() }   // 1/x^2 = 1/x0^2 + 2t
fn step(f: F, x0: f64, t: f64, h: f64) -> f64 { rk4(f, &[x0], h, (t / h).round() as usize)[0] }
fn v(x: f64) -> f64 { x * x / 2.0 }
fn en(s: &[f64]) -> f64 { s[1] * s[1] / 2.0 + s[0].powi(4) / 4.0 }   // energy, E' = 0

fn main() {
    println!("ball in a bowl: x' = -x^3, x in cm, t in s; V = x^2/2, V' = x x' = -x^4");
    let s0 = (settle(&[1e-4])[0] - settle(&[-1e-4])[0]) / 2e-4;
    println!("slope of the rate at x = 0, by differences: {:.6} -> linearisation silent", (s0 * 1e6).round() / 1e6 + 0.0);
    let rp: Vec<String> = [1.0f64, 0.5, 0.2].iter().map(|&x| format!("{:.3}", settle(&[x])[0])).collect();
    println!("rate x' = -x^3 at x = 1, 0.5, 0.2: {}", rp.join(" "));
    let vp: Vec<String> = [1.0f64, 0.5, 0.2].iter().map(|x| format!("{:.6}", -x.powi(4))).collect();
    println!("V' = -x^4 at x = 1, 0.5, 0.2: {}", vp.join(" "));
    let x4 = step(settle, 1.0, 4.0, 0.01);
    let dv = (v(rk4(settle, &[x4], 1e-3, 1)[0]) - v(rk4(settle, &[x4], -1e-3, 1)[0])) / 2e-3;
    println!("at t = 4 s: dV/dt by differences along the stepped path {:.6}, chain rule -x^4 {:.6}", dv, -x4.powi(4));
    let x12 = step(settle, 1.0, 12.0, 0.01);
    println!("x at t = 4, 12 s: closed {:.6} {:.6}; RK4 h = 0.01 {:.6} {:.6}", closed(1.0, 4.0), closed(1.0, 12.0), x4, x12);
    println!("V at t = 12 s: from the stepped x {:.6}; from 1/V = 1/V0 + 4t {:.6}", v(x12), 1.0 / (2.0 + 4.0 * 12.0));
    let err: Vec<f64> = [0.02, 0.01, 0.005].iter().map(|&h| step(settle, 1.0, 1.0, h) - closed(1.0, 1.0)).collect();
    println!("RK4 error at t = 1 s, h = 0.02, 0.01, 0.005: {:.3e} {:.3e} {:.3e} ratios {:.1} {:.1}",
             err[0], err[1], err[2], err[0] / err[1], err[1] / err[2]);
    println!("time to reach 0.1 cm: cubic closed {:.2} s, stepped {:.2} s; linear closed {:.2} s, stepped {:.2} s",
             (100.0 - 1.0) / 2.0, first_time(settle, 1.0, 0.01, &|x| x <= 0.1), 10f64.ln(), first_time(lin, 1.0, 0.01, &|x| x <= 0.1));
    for (name, f) in [("cubic", settle as F), ("linear", lin as F)] {
        let pts: Vec<String> = (0..13).map(|t| format!("{:.2}", step(f, 1.0, t as f64, 0.01))).collect();
        println!("chart, {} x at t = 0..12 s: {}", name, pts.join(" "));
    }
    let xb = step(burst, 1.0, 0.49, 0.001);
    println!("x' = +x^3 from 1 cm: V' = +x^4; x(0.49) closed {:.4}, RK4 {:.4}; blow-up at t = 0.5 s", 1.0 / (1.0 - 2.0 * 0.49f64).sqrt(), xb);
    let (mut s, mut top) = (rk4(free, &[1.0, 0.0], 0.01, 1000), 0.0f64);
    for _ in 0..1000 { s = rk4(free, &s, 0.01, 1); top = top.max(s[0].abs()); }
    println!("frictionless bowl from (1, 0): E at t = 0, 20 s {:.6} {:.6}; largest |x| on 10..20 s {:.4}", en(&[1.0, 0.0]), en(&s), top);
    let u0: f64 = 1.0 / 1.21;
    let t_esc = first_time(local, 1.1, 1e-4, &|x| x > 100.0);
    println!("x' = -x + x^3 from 1.1 cm: escape at t closed {:.3} s, stepped {:.3} s", 0.5 * (1.0 / (1.0 - u0)).ln(), t_esc);
    let x9 = 1.0 / (1.0 + (1.0 / 0.81 - 1.0) * 10f64.exp()).sqrt();
    println!("x' = -x + x^3 from 0.9 cm: x(5) closed {:.5}, stepped {:.5}", x9, step(local, 0.9, 5.0, 0.01));
    assert!((x12 - closed(1.0, 12.0)).abs() < 1e-8);            // the stepped path meets the closed form
    assert!(14.0 < err[1] / err[2] && err[1] / err[2] < 17.0);   // near 16-fold per halving: order 4
    assert!((dv + x4.powi(4)).abs() < 1e-7);                    // V' along the path equals grad V . f
    assert!((top - (4.0 * en(&[1.0, 0.0])).powf(0.25)).abs() < 1e-3 && (t_esc - 0.5 * (1.0 / (1.0 - u0)).ln()).abs() < 2e-3);
    println!("ALL CHECKS PASS");
}
