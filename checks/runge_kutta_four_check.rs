// Runge-Kutta four -- the same check as the Python, in Rust.  No crates; exp is
// the one primitive used.  Skydiver: v' = 9.8 - 0.2 v (m/s, s).
// School rumour: P' = 0.8 P (1 - P/1000), P(0) = 10 pupils, time in days.
fn rk4(f: &dyn Fn(f64, f64) -> f64, mut y: f64, h: f64, n: usize, w: [f64; 4], half: f64) -> f64 {
    let mut t = 0.0;
    for _ in 0..n {             // four slopes per step, then one weighted move
        let k1 = f(t, y); let k2 = f(t + half * h, y + half * h * k1);
        let k3 = f(t + half * h, y + half * h * k2); let k4 = f(t + h, y + h * k3);
        y += h * (w[0] * k1 + w[1] * k2 + w[2] * k3 + w[3] * k4) / w.iter().sum::<f64>(); t += h;
    }
    y
}
const W: [f64; 4] = [1.0, 2.0, 2.0, 1.0];
fn sky(_t: f64, v: f64) -> f64 { 9.8 - 0.2 * v }
fn exact(t: f64) -> f64 { 49.0 * (1.0 - (-0.2 * t).exp()) }           // road 1: the closed form
fn r(z: f64) -> f64 { 1.0 + z + z * z / 2.0 + z.powi(3) / 6.0 + z.powi(4) / 24.0 } // road 2
fn join(v: Vec<String>) -> String { v.join(" ") }
fn main() {
    let (k1, v2) = (sky(0.0, 0.0), rk4(&sky, 0.0, 2.0, 1, W, 0.5));
    let k2 = sky(1.0, k1); let k3 = sky(1.0, k2); let k4 = sky(2.0, 2.0 * k3);
    println!("one step, h = 2 s, from v = 0: k1 = {:.4}, k2 = {:.4}, k3 = {:.4}, k4 = {:.4}", k1, k2, k3, k4);
    println!("weighted slope {:.4}, v(2) = {:.4}, exact {:.4}, error {:.4}", (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0, v2, exact(2.0), exact(2.0) - v2);
    let x = |t: f64| 60.0 + 130.0 * t; let yy = |v: f64| 200.0 - 8.5 * v;   // figure scale
    let pts = [(0.0, 0.0), (1.0, k1), (1.0, k2), (2.0, 2.0 * k3), (2.0, v2)];
    println!("figure, start k2 k3 k4 end: {}", join(pts.iter().map(|&(t, v)| format!("{:.1},{:.1}", x(t), yy(v))).collect()));
    println!("figure, exact curve: {}", join((0..9).map(|i| { let t = i as f64 / 4.0; format!("{:.1},{:.1}", x(t), yy(exact(t))) }).collect()));
    println!("skydiver v(10), exact {:.6}", exact(10.0));
    let mut errs = vec![];
    for (h, lab) in [(2.0, "2"), (1.0, "1"), (0.5, "0.5"), (0.25, "0.25")] {
        let n = (10.0 / h) as usize; let v = rk4(&sky, 0.0, h, n, W, 0.5); errs.push(exact(10.0) - v);
        let road2 = 49.0 * (1.0 - r(-0.2 * h).powi(n as i32));
        println!("h = {:<5} RK4 {:.6}  error {:.7}  gap-factor road {:.6}", lab, v, errs[errs.len() - 1], road2);
        assert!((v - road2).abs() < 1e-9);                              // road 1 meets road 2
    }
    println!("error ratio per halving: {}", join((0..3).map(|i| format!("{:.2}", errs[i] / errs[i + 1])).collect()));
    let eul = |h: f64, n: i32| 49.0 * (1.0 - (1.0 - 0.2 * h).powi(n));
    let heun = |h: f64, n: i32| 49.0 * (1.0 - (1.0 - 0.2 * h + 0.02 * h * h).powi(n));
    println!("20 slope evaluations each: Euler h = 0.5 {:.4} error {:.4}; Heun h = 1 {:.4} error {:.4}; RK4 h = 2 error {:.4}",
        eul(0.5, 20), eul(0.5, 20) - exact(10.0), heun(1.0, 10), exact(10.0) - heun(1.0, 10), errs[0]);
    let ts: Vec<usize> = (0..=10).step_by(2).collect();
    println!("chart, t: {}", join(ts.iter().map(|t| t.to_string()).collect()));
    println!("chart, exact: {}", join(ts.iter().map(|&t| format!("{:.2}", exact(t as f64))).collect()));
    println!("chart, Euler h = 2: {}", join(ts.iter().map(|&t| format!("{:.2}", eul(2.0, (t / 2) as i32))).collect()));
    println!("chart, RK4 h = 2: {}", join(ts.iter().map(|&t| format!("{:.2}", rk4(&sky, 0.0, 2.0, t / 2, W, 0.5))).collect()));
    let rum = |_t: f64, p: f64| 0.8 * p * (1.0 - p / 1000.0);
    let p10 = 1000.0 / (1.0 + 99.0 * (-8.0f64).exp());
    let (a, b) = (rk4(&rum, 10.0, 0.5, 20, W, 0.5), rk4(&rum, 10.0, 0.25, 40, W, 0.5));
    println!("rumour day 10, exact {:.4}: h = 0.5 {:.4} error {:.4}; h = 0.25 {:.4} error {:.4}; ratio {:.2}", p10, a, p10 - a, b, p10 - b, (p10 - a) / (p10 - b));
    assert!((0..3).all(|i| 15.0 < errs[i] / errs[i + 1] && errs[i] / errs[i + 1] < 20.0) && 14.0 < (p10 - a) / (p10 - b) && (p10 - a) / (p10 - b) < 18.0);
    let (ww, nh) = (rk4(&sky, 0.0, 2.0, 5, [1.0; 4], 0.5), rk4(&sky, 0.0, 2.0, 5, W, 1.0));
    println!("mistakes at h = 2: equal weights {:.4}, halves dropped {:.4}", ww, nh);
    let (bw, c) = ([1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0], [0.0, 0.5, 0.5, 1.0]);
    let am = |u: [f64; 4]| [0.0, 0.5 * u[0], 0.5 * u[1], u[2]];        // the stage links, times u
    let dot = |u: [f64; 4]| (0..4).map(|i| bw[i] * u[i]).sum::<f64>();
    let (c2, c3, ac) = (c.map(|x| x * x), c.map(|x| x * x * x), am(c));
    let cac = [0, 1, 2, 3].map(|i| c[i] * ac[i]);
    let sums = [dot([1.0; 4]), dot(c), dot(c2), dot(c3), dot(ac), dot(cac), dot(am(c2)), dot(am(ac))];
    println!("order conditions, one over each sum: {}", join(sums.iter().map(|s| format!("{:.0}", 1.0 / s)).collect()));
    assert!(sums.iter().zip([1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0, 24.0]).all(|(s, t)| (s * t - 1.0).abs() < 1e-12));
    let (mut lo, mut hi) = (-3.0f64, -2.5f64);     // bisection for the stability edge R(z) = 1
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if r(mid) > 1.0 { lo = mid } else { hi = mid } }
    let big = rk4(&sky, 0.0, 15.0, 4, W, 0.5);
    println!("stability edge z = {:.4}, so h < {:.2} s; h = 15 gives v(60) = {:.2}, exact {:.2}", lo, -lo / 0.2, big, exact(60.0));
    assert!((big - exact(60.0)).abs() > 100.0 && (rk4(&sky, 0.0, 13.0, 20, W, 0.5) - exact(260.0)).abs() < 1.0);
    println!("ALL CHECKS PASS");
}
