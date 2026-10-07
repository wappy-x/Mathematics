// Poincare-Bendixson and Bendixson's criterion -- the same check as the Python, in
// Rust, std only.  Oscillator r' = r(1 - r^2), angle' = 1, in x, y (volts, ms);
// shock absorber p' = v, v' = -5p - 2v (cm, s).  Two roads each time, see the card.
use std::f64::consts::PI;
type P = (f64, f64);
fn ring(p: P) -> P { let (x, y) = p; let s = x * x + y * y; (x - y - x * s, x + y - y * s) }
fn shock(p: P) -> P { let (x, v) = p; (v, -5.0 * x - 2.0 * v) }
fn add(p: P, k: P, c: f64) -> P { (p.0 + c * k.0, p.1 + c * k.1) }
fn rk4(f: fn(P) -> P, mut p: P, h: f64, n: usize) -> P {     // Runge-Kutta 4, written out
    for _ in 0..n {
        let k1 = f(p); let k2 = f(add(p, k1, h / 2.0)); let k3 = f(add(p, k2, h / 2.0)); let k4 = f(add(p, k3, h));
        p = (p.0 + h * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0) / 6.0, p.1 + h * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1) / 6.0);
    }
    p
}
fn closed(r0: f64, t: f64) -> f64 { 1.0 / (1.0 + (1.0 / (r0 * r0) - 1.0) * (-2.0 * t).exp()).sqrt() }
fn div(f: fn(P) -> P, p: P) -> f64 {                          // f_x + g_y by central differences
    let e = 1e-5;
    (f((p.0 + e, p.1)).0 - f((p.0 - e, p.1)).0 + f((p.0, p.1 + e)).1 - f((p.0, p.1 - e)).1) / (2.0 * e)
}
fn flux(f: fn(P) -> P, a: f64, b: f64) -> f64 {              // line integral of f dy - g dx round an ellipse
    let n = 4000;
    (0..n).map(|i| { let s = 2.0 * PI * (i as f64 + 0.5) / n as f64; let q = f((a * s.cos(), b * s.sin()));
        (q.0 * b * s.cos() + q.1 * a * s.sin()) * 2.0 * PI / n as f64 }).sum()
}
fn disk(f: fn(P) -> P, big_r: f64) -> f64 {                  // double integral of the divergence over a disk
    let (n, m) = (1000, 32); let mut tot = 0.0;
    for i in 0..n { let r = (i as f64 + 0.5) * big_r / n as f64;
        for j in 0..m { let s = 2.0 * PI * (j as f64 + 0.5) / m as f64;
            tot += div(f, (r * s.cos(), r * s.sin())) * r * (big_r / n as f64) * (2.0 * PI / m as f64); } }
    tot
}
fn rad(r: f64, a: f64) -> P { let (x, y) = (r * a.cos(), r * a.sin()); let (f, g) = ring((x, y)); ((x * f + y * g) / r, (x * g - y * f) / (r * r)) }
fn area(q: &[P]) -> f64 { ((q[1].0 - q[0].0) * (q[2].1 - q[0].1) - (q[2].0 - q[0].0) * (q[1].1 - q[0].1)).abs() / 2.0 }
fn f6(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn norm(p: P) -> f64 { (p.0 * p.0 + p.1 * p.1).sqrt() }
fn main() {
    println!("oscillator r' = r(1 - r^2), angle' = 1; shock absorber p'' + 2p' + 5p = 0");
    let rims: Vec<Vec<P>> = [0.5, 2.0].iter().map(|&r| (0..360).map(|j| rad(r, 2.0 * PI * j as f64 / 360.0)).collect()).collect();
    let lo = |w: &Vec<P>| w.iter().map(|q| q.0).fold(f64::INFINITY, f64::min);
    let hi = |w: &Vec<P>| w.iter().map(|q| q.0).fold(f64::NEG_INFINITY, f64::max);
    let amin = rims.iter().flatten().map(|q| q.1).fold(f64::INFINITY, f64::min);
    println!("rims r = 0.5, 2: radial rate {:.6}..{:.6} {:.6}..{:.6}; angular rate min {:.6}", lo(&rims[0]), hi(&rims[0]), lo(&rims[1]), hi(&rims[1]), amin);
    let ts = [2.0, 4.0, 8.0]; let mut worst: f64 = 0.0;
    for r0 in [0.5, 2.0] {
        let c: Vec<f64> = ts.iter().map(|&t| closed(r0, t)).collect();
        let k: Vec<f64> = ts.iter().map(|&t| norm(rk4(ring, (r0, 0.0), 0.01, (100.0 * t) as usize))).collect();
        for i in 0..3 { worst = worst.max((k[i] - c[i]).abs()) }
        println!("from r = {:.1}, r at t = 2, 4, 8 ms: closed {}", r0, f6(&c));
        println!("from r = {:.1}, r at t = 2, 4, 8 ms: RK4    {}", r0, f6(&k));
    }
    let err: Vec<f64> = [0.2, 0.1].iter().map(|&h: &f64| (norm(rk4(ring, (0.5, 0.0), h, (2.0 / h).round() as usize)) - closed(0.5, 2.0)).abs()).collect();
    println!("RK4 error at t = 2 ms, h = 0.2, 0.1, in millionths: {:.3} {:.3}; ratio {:.2}", err[0] * 1e6, err[1] * 1e6, err[0] / err[1]);
    let back = rk4(ring, (1.0, 0.0), 2.0 * PI / 6283.0, 6283);
    println!("start on the cycle at (1, 0): after {:.6} ms the gap is {:.6}", 2.0 * PI, norm((back.0 - 1.0, back.1)));
    let dr: Vec<f64> = [0.0, 0.5, 1.0, 2.0].iter().map(|&r| div(ring, (r, 0.0))).collect();
    println!("oscillator divergence at r = 0, 0.5, 1, 2: {}", f6(&dr));
    let (g1, g2) = ((flux(ring, 0.5, 0.5), disk(ring, 0.5)), (flux(ring, 1.0, 1.0), disk(ring, 1.0)));
    println!("Green, circle r = 0.5: line {:.5} area {:.5}; cycle r = 1: line {:.5} area {:.5}", g1.0, g1.1, g2.0, g2.1);
    let dv: Vec<f64> = [(0.0, 0.0), (3.0, -4.0), (-10.0, 7.0)].iter().map(|&p| div(shock, p)).collect();
    let t0 = [(1.0, 0.0), (1.01, 0.0), (1.0, 0.01)];
    let t1: Vec<P> = t0.iter().map(|&p| rk4(shock, p, 0.001, 1000)).collect();
    let ratio = area(&t1) / area(&t0);
    println!("shock divergence at (0,0), (3,-4), (-10,7): {}; patch area after 1 s x {:.6}, e^(-2) = {:.6}", f6(&dv), ratio, (-2.0f64).exp());
    let ell = (flux(shock, 5f64.sqrt(), 5.0), -2.0 * PI * 5f64.sqrt() * 5.0);
    println!("ellipse 5p^2 + v^2 = 25: line integral {:.6}; -2 x area {:.6}", ell.0, ell.1);
    let e: Vec<f64> = [0, 2, 4].iter().map(|&t| { let p = rk4(shock, (5f64.sqrt(), 0.0), 0.001, 1000 * t); 5.0 * p.0 * p.0 + p.1 * p.1 }).collect();
    println!("mistake 1, rest inside: energy 5p^2 + v^2 at t = 0, 2, 4 s: {}", f6(&e));
    let gap = (1..1001).map(|k| { let z = k as f64 * 2f64.sqrt(); (z - z.round()).abs() * 2.0 * PI }).fold(f64::INFINITY, f64::min);
    println!("mistake 2, doughnut angles' = 1, sqrt 2: closest return in 1000 laps {:.6} rad, not 0", gap);
    for r0 in [0.5, 2.0] {
        let pts: Vec<String> = (0..17).map(|k| { let p = rk4(ring, (r0, 0.0), 0.01, 25 * k); format!("{:.1},{:.1}", 180.0 + 50.0 * p.0, 120.0 - 50.0 * p.1) }).collect();
        println!("figure, from r = {:.1}, t = 0 to 4 ms every 0.25: {}", r0, pts.join(" "));
    }
    assert!(worst < 1e-8 && lo(&rims[0]) > 0.0 && hi(&rims[1]) < 0.0);   // RK4 meets the closed form; both rims point in
    assert!(err[0] / err[1] > 14.0 && err[0] / err[1] < 18.0);  // error falls 16-fold as h halves: order 4
    assert!((ratio - (dv[1] * 1.0).exp()).abs() < 1e-6);         // Liouville: area shrinks at the divergence
    assert!((g1.0 - g1.1).abs() < 1e-5 && (ell.0 - ell.1).abs() < 1e-6);   // Green's two sides agree
    println!("ALL CHECKS PASS");
}
