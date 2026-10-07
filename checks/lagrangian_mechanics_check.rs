// Lagrangian mechanics -- the same check as the Python, in Rust.  No crates.
// Road one knows only L = T - V and gets each acceleration from the Euler-Lagrange
// equation by numerical slopes of L.  Road two steps the equations derived by hand.
use std::f64::consts::PI;
const G: f64 = 9.81; const M: f64 = 30.0; const LEN: f64 = 2.0; const TH0: f64 = PI / 6.0;   // swing
const MB: f64 = 0.5; const R: f64 = 0.5; const I: f64 = 0.25; const W0: f64 = 6.0;            // bead on a free hoop
type Lag = dyn Fn(&[f64], &[f64]) -> f64; type Acc = dyn Fn(&[f64], &[f64]) -> Vec<f64>;
fn l_swing(q: &[f64], v: &[f64]) -> f64 { 0.5 * M * LEN * LEN * v[0] * v[0] + M * G * LEN * q[0].cos() }
fn l_wrong(q: &[f64], v: &[f64]) -> f64 { 0.5 * M * LEN * LEN * v[0] * v[0] - M * G * LEN * q[0].cos() } // T + V
fn l_hoop(q: &[f64], v: &[f64]) -> f64 {
    0.5 * I * v[1] * v[1] + 0.5 * MB * R * R * (v[0] * v[0] + q[0].sin().powi(2) * v[1] * v[1]) + MB * G * R * q[0].cos() }
fn slope(f: &dyn Fn(&[f64]) -> f64, x: &[f64], i: usize) -> f64 {   // central difference in input i
    let (mut xp, mut xm) = (x.to_vec(), x.to_vec()); xp[i] += 1e-4; xm[i] -= 1e-4; (f(&xp) - f(&xm)) / 2e-4 }
fn acc_from_l(lag: &Lag, q: &[f64], v: &[f64]) -> Vec<f64> {        // sum_j L_vi,vj a_j = L_qi - sum_j L_vi,qj v_j
    let n = q.len(); let s: Vec<f64> = q.iter().chain(v.iter()).cloned().collect();
    let f = |x: &[f64]| lag(&x[..n], &x[n..]);
    let p = |i: usize| move |x: &[f64]| slope(&f, x, n + i);              // momentum dL/dv_i
    let a: Vec<Vec<f64>> = (0..n).map(|i| (0..n).map(|j| slope(&p(i), &s, n + j)).collect()).collect();
    let b: Vec<f64> = (0..n).map(|i| slope(&f, &s, i) - (0..n).map(|j| slope(&p(i), &s, j) * v[j]).sum::<f64>()).collect();
    if n == 1 { return vec![b[0] / a[0][0]]; }
    let det = a[0][0] * a[1][1] - a[0][1] * a[1][0]; vec![(b[0] * a[1][1] - a[0][1] * b[1]) / det, (a[0][0] * b[1] - b[0] * a[1][0]) / det]
}
fn acc_swing(q: &[f64], _v: &[f64]) -> Vec<f64> { vec![-(G / LEN) * q[0].sin()] }
fn acc_hoop(q: &[f64], v: &[f64]) -> Vec<f64> {                     // q = (theta, phi), v = (theta', phi')
    let (c, s) = (q[0].cos(), q[0].sin());
    vec![s * c * v[1] * v[1] - (G / R) * s, -2.0 * MB * R * R * s * c * v[0] * v[1] / (I + MB * R * R * s * s)] }
fn run(acc: &Acc, s0: Vec<f64>, h: f64, steps: usize) -> Vec<Vec<f64>> {   // Runge-Kutta 4 on q' = v, v' = acc
    let (n, mut out) = (s0.len() / 2, vec![s0.clone()]);
    let f = |s: &[f64]| { let mut d = s[n..].to_vec(); d.extend(acc(&s[..n], &s[n..])); d };
    let ad = |s: &[f64], k: &[f64], c: f64| s.iter().zip(k).map(|(x, y)| x + c * y).collect::<Vec<f64>>();
    for _ in 0..steps {
        let s = out.last().unwrap().clone();
        let k1 = f(&s); let k2 = f(&ad(&s, &k1, h / 2.0)); let k3 = f(&ad(&s, &k2, h / 2.0)); let k4 = f(&ad(&s, &k3, h));
        out.push((0..s.len()).map(|i| s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect());
    }
    out
}
fn action(path: &[Vec<f64>], eps: f64) -> f64 {                    // trapezoid sum of L along path + eps * sin(pi t)
    let vals: Vec<f64> = path.iter().enumerate().map(|(k, s)| { let t = k as f64 * 0.001;
        l_swing(&[s[0] + eps * (PI * t).sin()], &[s[1] + eps * PI * (PI * t).cos()]) }).collect();
    0.001 * (vals.iter().sum::<f64>() - 0.5 * (vals[0] + vals[vals.len() - 1]))
}
fn first(p: &[Vec<f64>]) -> f64 { (action(p, 0.01) - action(p, -0.01)) / 0.02 }                 // nudge 0.01 rad each way
fn second(p: &[Vec<f64>]) -> f64 { (action(p, 0.01) + action(p, -0.01) - 2.0 * action(p, 0.0)) / 2e-4 }
fn range(xs: impl Iterator<Item = f64> + Clone) -> (f64, f64) { (xs.clone().fold(f64::MAX, f64::min), xs.fold(f64::MIN, f64::max)) }
fn main() {
    let (a1, a2) = (acc_from_l(&l_swing, &[TH0], &[0.0])[0], acc_swing(&[TH0], &[0.0])[0]);
    let (sw1, sw2) = (run(&|q: &[f64], v: &[f64]| acc_from_l(&l_swing, q, v), vec![TH0, 0.0], 0.01, 100), run(&acc_swing, vec![TH0, 0.0], 0.01, 100));
    println!("swing: m l^2 = {:.1} kg m^2, m g l = {:.1} J; at 30 deg, angular acceleration from L alone {:.6}, from -(g/l) sin {:.6} rad/s^2",
             M * LEN * LEN, M * G * LEN, a1, a2);
    println!("swing angle at 1 s: road one {:.6}, road two {:.6} rad; speed {:.6} rad/s", sw1[100][0], sw2[100][0], sw2[100][1]);
    let fine = run(&acc_swing, vec![TH0, 0.0], 0.001, 1000); let end = fine[1000][0];   // true path, 0 to 1 s; a straight line
    let line: Vec<Vec<f64>> = (0..=1000).map(|k| vec![TH0 + (end - TH0) * k as f64 / 1000.0, end - TH0]).collect();
    let q2 = 0.0005 * fine.iter().enumerate().map(|(k, s)| { let t = PI * k as f64 / 1000.0;
        (if k > 0 && k < 1000 { 1.0 } else { 0.5 }) * (M * LEN * LEN * (PI * t.cos()).powi(2) - M * G * LEN * s[0].cos() * t.sin().powi(2)) }).sum::<f64>();
    for (name, pth) in [("true path", &fine), ("straight line", &line)] {
        println!("{}: action {:.6} J s; first-order change {:.6}, second-order {:.4}", name, action(pth, 0.0), first(pth), second(pth));
    }
    println!("second variation, 0.5 x integral of (m l^2 eta'^2 - m g l cos(theta) eta^2): {:.4}", q2);
    let (h1, h2) = (run(&|q: &[f64], v: &[f64]| acc_from_l(&l_hoop, q, v), vec![0.3, 0.0, 0.0, W0], 0.01, 300), run(&acc_hoop, vec![0.3, 0.0, 0.0, W0], 0.01, 300));
    let p1: Vec<f64> = h1.iter().map(|s| slope(&|v: &[f64]| l_hoop(&s[..2], v), &s[2..], 1)).collect();  // road one
    let mom: Vec<f64> = h2.iter().map(|s| (I + MB * R * R * s[0].sin().powi(2)) * s[3]).collect();       // road two
    let ((b0, b1), (w0, w1), (m0, m1), (p0, pp)) = (range(h2.iter().map(|s| s[0])), range(h2.iter().map(|s| s[3])), range(mom.iter().cloned()), range(p1.iter().cloned()));
    println!("hoop at 3 s: bead angle road one {:.6}, road two {:.6} rad; over 0 to 3 s the bead swings {:.4} to {:.4} rad, the hoop spins {:.4} to {:.4} rad/s",
             h1[300][0], h2[300][0], b0, b1, w0, w1);
    println!("momentum (I + m R^2 sin^2 theta) phi', m R^2 = {:.3}, at the start {:.6} x {}; road two: min {:.6}, max {:.6}; slope of L in phi', road one: min {:.6}, max {:.6} kg m^2/s",
             MB * R * R, mom[0] / W0, W0, m0, m1, p0, pp);
    let ch: Vec<String> = (0..=300).step_by(25).map(|k| format!("{:.2}", h2[k][3])).collect(); println!("chart, t = 0, 0.25 ... 3 s, hoop spin: {}", ch.join(" "));
    let dr = run(&|q: &[f64], v: &[f64]| vec![acc_hoop(q, &[v[0], W0])[0]], vec![0.3, 0.0], 0.01, 300);   // mistake 3: motor holds phi'
    let ((d0, d1), pd) = (range(dr.iter().map(|s| s[0])), |x: f64| (I + MB * R * R * x.sin().powi(2)) * W0);
    println!("mistake 1, L = T + V: acceleration at 30 deg {:.6} rad/s^2; mistake 2, hoop spin alone I phi': {:.4} to {:.4} kg m^2/s\nmistake 3, motor-held spin: bead to {:.4} rad, momentum {:.6} to {:.6} kg m^2/s",
             acc_from_l(&l_wrong, &[TH0], &[0.0])[0], I * w0, I * w1, d1, pd(d0), pd(d1));
    println!("figure, 60 units per metre: pivot 180.0,30.0; seat at 30 deg {:.1},{:.1}; seat at rest {:.1},{:.1}; drop {:.3} m; angle arc 40 units, ends 180.0,70.0 and {:.1},{:.1}",
             180.0 + 60.0 * LEN * TH0.sin(), 30.0 + 60.0 * LEN * TH0.cos(), 180.0, 30.0 + 60.0 * LEN, LEN * (1.0 - TH0.cos()), 180.0 + 40.0 * TH0.sin(), 30.0 + 40.0 * TH0.cos());
    assert!((a1 - a2).abs() < 1e-6 && (sw1[100][0] - sw2[100][0]).abs() < 1e-6);   // road one = road two, swing
    assert!((h1[300][0] - h2[300][0]).abs() < 1e-5 && pp - p0 < 1e-6);             // road one = road two, hoop
    assert!(first(&fine).abs() < 0.01 && 0.01 < first(&line).abs());               // stationary only on the true path
    assert!((second(&fine) - q2).abs() < 1e-3 * q2);                               // nudge cost = second variation
    println!("ALL CHECKS PASS");
}
