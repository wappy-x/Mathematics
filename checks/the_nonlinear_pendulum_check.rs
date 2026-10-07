// The nonlinear pendulum -- the same check as the Python, in Rust.  No crates.
// Time is counted in units of sqrt(l/g) and energy per m g l, so the swing obeys
// theta'' = -sin(theta).  Road one: the period integral by Simpson's rule.
// Road two: RK4 steps that know no formula.
use std::f64::consts::PI;
const G: f64 = 9.81; const L: f64 = 1.0; const TH0: f64 = PI / 3.0;   // 1 m rod, released at 60 degrees
fn energy(th: f64, w: f64) -> f64 { 0.5 * w * w + 1.0 - th.cos() }
fn quarter(k2: f64) -> f64 {                            // integral of 1/sqrt(1 - k2 sin^2) on [0, pi/2]
    let (n, h) = (400, PI / 800.0);
    let f = |p: f64| 1.0 / (1.0 - k2 * p.sin().powi(2)).sqrt();
    let mid: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h)).sum();
    h / 3.0 * (f(0.0) + f(PI / 2.0) + mid)
}
fn rk4(th: f64, w: f64, h: f64, c: f64) -> (f64, f64) { // one Runge-Kutta 4 step; c = friction
    let f = |a: f64, b: f64| (b, -a.sin() - c * b);
    let (a1, b1) = f(th, w);
    let (a2, b2) = f(th + h / 2.0 * a1, w + h / 2.0 * b1); let (a3, b3) = f(th + h / 2.0 * a2, w + h / 2.0 * b2);
    let (a4, b4) = f(th + h * a3, w + h * b3);
    (th + h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4), w + h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4))
}
fn time_to(mut th: f64, mut w: f64, target: f64, h: f64) -> f64 {   // step until theta passes target,
    let (mut t, s) = (0.0, th - target);                            // then bisect the last step
    while (rk4(th, w, h, 0.0).0 - target) * s > 0.0 { (th, w) = rk4(th, w, h, 0.0); t += h }
    let (mut lo, mut hi) = (0.0, h);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (rk4(th, w, mid, 0.0).0 - target) * s > 0.0 { lo = mid } else { hi = mid }
    }
    t + lo
}
fn run(mut th: f64, mut w: f64, t: f64, h: f64, step: &dyn Fn(f64, f64, f64) -> (f64, f64)) -> f64 {
    for _ in 0..(t / h).round() as i64 { (th, w) = step(th, w, h) }
    energy(th, w)
}
fn pts(cs: &[(f64, f64)]) -> String {                   // 45 units per rad, 30 per unit of speed
    cs.iter().map(|&(a, b)| format!("{:.1},{:.1}", 180.0 + 45.0 * a, 110.0 - 30.0 * b)).collect::<Vec<_>>().join(" ")
}
fn main() {
    let (u, rk) = ((L / G).sqrt(), |a: f64, b: f64, h: f64| rk4(a, b, h, 0.0));
    let euler = |a: f64, b: f64, h: f64| (a + h * b, b - h * a.sin());
    let (e0, top) = (energy(TH0, 0.0), energy(PI, 0.0));
    let t_simp = 4.0 * quarter(e0 / 2.0);
    let t_rk: Vec<f64> = [0.1, 0.05].iter().map(|&h| 4.0 * time_to(TH0, 0.0, 0.0, h)).collect();
    let err: Vec<f64> = t_rk.iter().map(|t| (t - t_simp).abs()).collect();
    let jac: Vec<f64> = [0.0, PI].iter().map(|&x| (-(x + 1e-5).sin() + (x - 1e-5).sin()) / 2e-5).collect();
    let sep = (2.0 * ((PI + 1e-5) / 2.0).cos() - 2.0 * ((PI - 1e-5) / 2.0).cos()) / 2e-5;
    let (er, e1) = (energy(0.0, 2.5), energy(0.0, 2f64.sqrt()));
    let k = (2.0 / er).sqrt();
    let (turn_s, turn_rk) = (2.0 * k * quarter(k * k), time_to(0.0, 2.5, 2.0 * PI, 0.05));
    let (e_rk, e_eu) = (run(TH0, 0.0, t_simp, 0.1, &rk), run(TH0, 0.0, 6.74, 0.1, &euler));
    println!("energy at release, 60 deg: {:.6}; standing on end at rest: {:.6}", e0, top);
    println!("bottom speed to reach the top: {:.4} units = {:.3} m/s", (2.0 * top).sqrt(), 2.0 * (G * L).sqrt());
    println!("lambda^2 = d(omega')/d(theta): at 0 {:.6} -> +-i, centre; at pi {:.6} -> +-1, saddle", jac[0], jac[1]);
    println!("separatrix omega = 2 cos(theta/2), slope at pi: {:.6}", sep);
    println!("period at 60 deg, Simpson: {:.6}; small-angle 2 pi: {:.6}; ratio {:.4}", t_simp, 2.0 * PI, t_simp / (2.0 * PI));
    println!("period at 60 deg, RK4 h = 0.1, 0.05: {:.6} {:.6}; errors {:.8} {:.8}, ratio {:.1}", t_rk[0], t_rk[1], err[0], err[1], err[0] / err[1]);
    println!("energy after one period, RK4 h = 0.1: {:.6}", e_rk);
    println!("1 m rod: one unit {:.4} s; period {:.3} s against small-angle {:.3} s", u, t_simp * u, 2.0 * PI * u);
    let ch: Vec<String> = [0.1, 0.5, 1.0, 1.5, 1.9, 1.99].iter().map(|&e| format!("{:.2}", 4.0 * quarter(e / 2.0))).collect();
    println!("chart, period at E = 0.1, 0.5, 1.0, 1.5, 1.9, 1.99: {}", ch.join(" "));
    println!("near the top, 2 ln(32/(2 - E)) at E = 1.9, 1.99: {:.2} {:.2}", 2.0 * (32.0f64 / 0.1).ln(), 2.0 * (32.0f64 / 0.01).ln());
    println!("push 2.5 ({:.3} m/s): energy {:.4}, speed at the top {:.4}, one turn Simpson {:.4}, RK4 {:.4}", 2.5 * (G * L).sqrt(), er, (2.0 * (er - 2.0)).sqrt(), turn_s, turn_rk);
    println!("mistake 1, bottom speed sqrt(2 g l) = {:.3} m/s: energy {:.4}, turns back at {:.1} deg", (2.0 * G * L).sqrt(), e1, (1.0 - e1).acos() * 180.0 / PI);
    println!("mistake 2, friction 0.5 (the house swing): energy after 6.74 units {:.4}", run(TH0, 0.0, 6.74, 0.01, &|a, b, h| rk4(a, b, h, 0.5)));
    println!("mistake 3, Euler's rule h = 0.1: energy after 6.74 units {:.4}", e_eu);
    let ks = (e0 / 2.0).sqrt();
    let lp: Vec<(f64, f64)> = (0..24).map(|i| { let p = i as f64 * PI / 12.0; (2.0 * (ks * p.sin()).asin(), 2.0 * ks * p.cos()) }).collect();
    println!("figure, swing loop: {}", pts(&lp));
    for sg in [1.0f64, -1.0] {
        let sp: Vec<(f64, f64)> = (-8..9).map(|i| (i as f64 * PI / 8.0, sg * 2.0 * (i as f64 * PI / 16.0).cos())).collect();
        let tp: Vec<(f64, f64)> = (-8..9).map(|i| { let a = i as f64 * PI / 8.0; (a, sg * (2.0 * (er - 1.0 + a.cos())).sqrt()) }).collect();
        println!("figure, separatrix {:+}: {}", sg as i32, pts(&sp));
        println!("figure, turning {:+}: {}", sg as i32, pts(&tp));
    }
    assert!((t_rk[1] - t_simp).abs() < 1e-6 && 12.0 < err[0] / err[1] && err[0] / err[1] < 20.0);   // two roads; order four
    assert!((jac[1].sqrt() - sep.abs()).abs() < 1e-6);            // saddle rate = separatrix slope
    assert!((turn_s - turn_rk).abs() < 1e-5);
    assert!((e_rk - e0).abs() < 1e-4 && 1e-4 < (e_eu - e0).abs());
    println!("ALL CHECKS PASS");
}
