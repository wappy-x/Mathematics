// LaSalle and the damped swing -- the same check as the Python, in Rust.  No
// crates.  theta'' + c theta' + sin(theta) = 0, time in units of sqrt(l/g).
// Road one steps the swing by Runge-Kutta 4 and records where it ends.  Road
// two books the energy lost against c times the integral of v^2 (Simpson),
// and the late swings against the eigenvalues of the swing near the bottom.
use std::f64::consts::PI;
const C: f64 = 0.5;
const TH0: f64 = PI / 3.0;
const T: f64 = 40.0;
const DEG: f64 = 180.0 / PI;
fn f(th: f64, v: f64, c: f64) -> (f64, f64) { (v, -th.sin() - c * v) }
fn energy(p: (f64, f64)) -> f64 { 0.5 * p.1 * p.1 + 1.0 - p.0.cos() }
type Run = (Vec<(f64, f64)>, Vec<(f64, f64)>);
fn run(mut th: f64, mut v: f64, c: f64, h: f64) -> Run {  // RK4; a turnaround is where v flips sign
    let (mut out, mut turns) = (vec![(th, v)], Vec::new());
    for k in 0..(T / h).round() as usize {
        let (a1, b1) = f(th, v, c);
        let (a2, b2) = f(th + h / 2.0 * a1, v + h / 2.0 * b1, c);
        let (a3, b3) = f(th + h / 2.0 * a2, v + h / 2.0 * b2, c);
        let (a4, b4) = f(th + h * a3, v + h * b3, c);
        let t2 = th + h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4);
        let v2 = v + h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4);
        if v * v2 < 0.0 { turns.push((k as f64 * h + h * v / (v - v2), th + (t2 - th) * v / (v - v2))); }
        th = t2; v = v2; out.push((th, v));
    }
    (out, turns)
}
fn lost(out: &[(f64, f64)], c: f64, h: f64) -> f64 {     // c times the integral of v^2, Simpson
    let n = out.len() - 1;
    let s: f64 = out.iter().enumerate()
        .map(|(i, p)| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * p.1 * p.1).sum();
    c * h / 3.0 * s
}
fn widest(e: f64) -> f64 {                                 // bisection: 1 - cos(theta) = e
    let (mut lo, mut hi) = (0.0f64, PI);
    for _ in 0..60 { let m = (lo + hi) / 2.0; if 1.0 - m.cos() < e { lo = m } else { hi = m } }
    lo
}
fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }
fn main() {
    let (e0, unit) = (energy((TH0, 0.0)), (1.0f64 / 9.81).sqrt());
    println!("time unit {:.4} s; release: V0 = {:.3}, V' = {:.3}, v' = {:.3}", unit, e0, TH0.sin() * 0.0 + 0.0 * f(TH0, 0.0, C).1, f(TH0, 0.0, C).1);
    println!("trap: |theta| <= {:.2} deg, |v| <= {:.3}, top V(pi, 0) = {:.3}", widest(e0) * DEG, (2.0 * e0).sqrt(), energy((PI, 0.0)));
    let (w, s) = ((4.0 - C * C).sqrt() / 2.0, (C * C + 4.0).sqrt());  // bottom: det 1; top: det -1
    println!("eigenvalues: bottom {:.3} +- {:.4}i, top {:.3} and {:.3}", -C / 2.0, w, (-C + s) / 2.0, (-C - s) / 2.0);
    let (out, turns) = run(TH0, 0.0, C, 0.05);
    println!("turnarounds (t, deg): {}", join(turns[..5].iter().map(|(t, a)| format!("({:.2}, {:.2})", t, a * DEG)).collect(), ", "));
    let ratios: Vec<f64> = (0..turns.len() - 1).map(|i| (turns[i + 1].1 / turns[i].1).abs()).collect();
    let pred = (-C / 2.0 * PI / w).exp();                  // linear swing: shrink per half swing
    println!("half-swing ratio: first {:.4}, 6th {:.4}, from eigenvalues {:.4}", (turns[0].1 / TH0).abs(), ratios[5], pred);
    let first = turns.iter().find(|(_, a)| a.abs() * DEG < 1.0).unwrap().0;
    println!("turnarounds under 1 deg from t = {:.2}, which is {:.2} s", first, first * unit);
    let end = out[out.len() - 1];
    let widest_seen = out.iter().map(|p| p.0.abs()).fold(0.0, f64::max);
    println!("at t = 40: theta = {:.6}, v = {:.6}, widest ever {:.2} deg", end.0, end.1, widest_seen * DEG);
    let d: Vec<f64> = [0.1, 0.05].iter().map(|&h| { let o = run(TH0, 0.0, C, h).0; e0 - energy(o[o.len() - 1]) - lost(&o, C, h) }).collect();
    println!("V0 - V(40) = {:.6}; c * integral of v^2 = {:.6}", e0 - energy(end), lost(&out, C, 0.05));
    println!("bookkeeping gap in millionths: h = 0.1 {:.3}, h = 0.05 {:.3}, ratio {:.1}", d[0] * 1e6, d[1] * 1e6, d[0] / d[1]);
    println!("chart, V at t = 0, 0.5, ..., 12: {}", join(out[..241].iter().step_by(10).map(|&p| format!("{:.2}", energy(p))).collect(), ", "));
    let fg = out[..241].iter().step_by(5).map(|p| format!("{:.1},{:.1}", 180.0 + 45.0 * p.0, 120.0 - 45.0 * p.1)).collect();
    println!("figure, spiral x = 180 + 45 theta, y = 120 - 45 v: {}", join(fg, " "));
    let eye = (-8..=8).map(|k| format!("{:.2}", 2.0 * (k as f64 * PI / 16.0).cos())).collect();
    println!("figure, eye edge v = 2 cos(theta/2), theta = -pi..pi by pi/8: {}", join(eye, " "));
    let (free, free_turns) = run(TH0, 0.0, 0.0, 0.05);
    let fend = free[free.len() - 1];
    println!("c = 0: V(40) = {:.6}, last turnaround {:.2} deg", energy(fend), free_turns[free_turns.len() - 1].1.abs() * DEG);
    let ends: Vec<f64> = [3.0, 3.5].iter().map(|&v0| { let o = run(0.0, v0, C, 0.05).0; o[o.len() - 1].0 }).collect();
    let pl = [3.0f64, 3.5].iter().zip(&ends).map(|(v0, e)| format!("v0 = {:.1} (V0 = {:.3}) ends in well {}", v0, energy((0.0, *v0)), (e / (2.0 * PI)).round() as i64)).collect();
    println!("push from the bottom: {}", join(pl, ", "));
    assert!(d[1].abs() < 1e-6 && 12.0 < d[0] / d[1] && d[0] / d[1] < 20.0);   // book balances, RK4 order
    assert!((ratios[5] / pred - 1.0).abs() < 0.01);                          // late swings obey eigenvalues
    assert!(end.0.abs() < 1e-3 && end.1.abs() < 1e-3 && widest_seen <= widest(e0) + 1e-9);
    assert!((energy(fend) - e0).abs() < 1e-6 && (ends[1] - 2.0 * PI).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
