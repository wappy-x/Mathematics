// Two-timing and averaging -- the same check as the Python, in Rust, std only.  RK4 and cycle
// averages are written out.  Road one: the full equations.  Road two: the slow amplitude law.
use std::f64::consts::PI;
type P = [f64; 2];
const EPS: f64 = 0.1; const R0: f64 = 0.5; const GOAL: f64 = 1.9;
fn rk4(f: &dyn Fn(P) -> P, p: P, h: f64) -> P {
    let k1 = f(p); let k2 = f([p[0] + h / 2.0 * k1[0], p[1] + h / 2.0 * k1[1]]);
    let k3 = f([p[0] + h / 2.0 * k2[0], p[1] + h / 2.0 * k2[1]]); let k4 = f([p[0] + h * k3[0], p[1] + h * k3[1]]);
    [0, 1].map(|i| p[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]))
}
fn vdp(p: P) -> P { [p[1], -EPS * (p[0] * p[0] - 1.0) * p[1] - p[0]] }   // x'' + 0.1(x^2 - 1)x' + x = 0
fn duf(p: P) -> P { [p[1], -p[0] - EPS * p[0].powi(3)] }                // x'' + x + 0.1 x^3 = 0
fn avg(g: &dyn Fn(f64) -> f64) -> f64 { (0..360).map(|k| g(2.0 * PI * (k as f64 + 0.5) / 360.0)).sum::<f64>() / 360.0 }
fn h_vdp(r: f64, s: f64) -> f64 { (r * r * s.cos().powi(2) - 1.0) * (-r * s.sin()) }   // h(x, x') on x = r cos s
fn drift(r: f64) -> f64 { EPS * avg(&|s| h_vdp(r, s) * s.sin()) }                       // r' = eps <h sin s>
fn law(r: f64) -> f64 { EPS / 2.0 * r * (1.0 - r * r / 4.0) }
fn closed(t: f64) -> f64 { 2.0 / (1.0 + (4.0 / (R0 * R0) - 1.0) * (-EPS * t).exp()).sqrt() }
fn t_hit(e: f64) -> f64 { ((4.0 / (R0 * R0) - 1.0) / (4.0 / (GOAL * GOAL) - 1.0)).ln() / e }
fn root(f: &dyn Fn(f64) -> f64) -> f64 {           // bisection: where a drift falls to zero
    let (mut lo, mut hi) = (1.0, 3.0);
    for _ in 0..50 { let m = (lo + hi) / 2.0; if f(m) > 0.0 { lo = m } else { hi = m } }
    lo
}
fn peaks(f: &dyn Fn(P) -> P, mut p: P, t_end: f64, h: f64) -> Vec<(f64, f64)> {   // maxima of x
    let (mut out, mut k) = (vec![(0.0, p[0])], 0usize);
    while (k as f64) * h < t_end {
        let q = rk4(f, p, h); k += 1;
        if p[1] > 0.0 && q[1] <= 0.0 { out.push((((k - 1) as f64 + p[1] / (p[1] - q[1])) * h, p[0].max(q[0]))) }
        p = q;
    }
    out
}
fn cross(pk: &[(f64, f64)], i: usize, v: f64) -> f64 {   // where the line between peaks hits value v
    let j = (1..pk.len()).find(|&j| if i == 0 { pk[j].0 >= v } else { pk[j].1 >= v }).unwrap();
    let ((a, x), (b, y)) = (pk[j - 1], pk[j]);
    if i == 0 { x + (y - x) * (v - a) / (b - a) } else { a + (b - a) * (v - x) / (y - x) }
}
fn line(v: &[f64]) -> String { v.iter().map(|a| format!("{:.2}", a)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (mut r, mut t, h) = (R0, 0.0f64, 0.01);     // road two: step r' = drift(r) to 1.9
    while r < GOAL {
        let k1 = drift(r); let k2 = drift(r + h / 2.0 * k1); let k3 = drift(r + h / 2.0 * k2); let k4 = drift(r + h * k3);
        let r_new = r + h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
        t += if r_new < GOAL { h } else { h * (GOAL - r) / (r_new - r) }; r = r_new;
    }
    let pk = peaks(&vdp, [R0, 0.0], 110.0, 0.001);  // road one: the full van der Pol law
    let ts: Vec<f64> = (0..11).map(|k| 10.0 * k as f64).collect();
    let full: Vec<f64> = ts.iter().map(|&s| cross(&pk, 0, s)).collect();
    let t_full = cross(&pk, 1, GOAL);
    let ups: Vec<f64> = peaks(&duf, [1.0, 0.0], 62.0, 0.001).iter().map(|u| u.0).collect();
    let w_rk = 2.0 * PI * (ups.len() - 1) as f64 / (ups[ups.len() - 1] - ups[0]);
    let c4 = avg(&|s| s.cos().powi(4));              // r phi' = eps <h cos s>, h = r^3 cos^3 s
    let wrong = root(&|r| EPS * (-r) * (r * r / 4.0 - 0.5));   // <cos^2 sin^2> taken as 1/2 x 1/2
    let th = t_hit(EPS);
    println!("averaged drift at r = 0.5: by quadrature {:.7}, by 0.05 r(1 - r^2/4) {:.7}", drift(R0), law(R0));
    println!("drift is zero at r = {:.4}: every start settles at amplitude 2", root(&drift));
    println!("closed form: 4/0.5^2 - 1 = {:.0}, 4/1.9^2 - 1 = {:.5}; r = 1.9 at t = {:.2}", 4.0 / (R0 * R0) - 1.0, 4.0 / (GOAL * GOAL) - 1.0, th);
    println!("stepping the averaged law: r = 1.9 at t = {:.2}", t);
    println!("full law by RK4: peak height reaches 1.9 at t = {:.2}; peak at t = 100: {:.4}", t_full, full[10]);
    println!("t = {:.2} is {:.2} swings; at 1 kHz, {:.2} ms", th, th / (2.0 * PI), th / (2.0 * PI));
    println!("naive expansion: amplitude 0.5 + {:.7} t, at t = 100: {:.2}", law(R0), R0 + 100.0 * law(R0));
    println!("Duffing at amplitude 1: averaging 1 + 0.1 x {:.4} = {:.4}; RK4 {:.4}", c4, 1.0 + EPS * c4, w_rk);
    println!("chart t: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]");
    println!("chart full law: {}", line(&full));
    println!("chart averaged: {}", line(&ts.iter().map(|&s| closed(s)).collect::<Vec<_>>()));
    println!("chart naive: {}", line(&ts.iter().map(|&s| R0 + s * law(R0)).collect::<Vec<_>>()));
    println!("mistake 1, <cos^2 sin^2> taken as 1/2 x 1/2: settles at {:.2}, not 2", wrong);
    println!("mistake 2, dropping the 1/2 in r': r = 1.9 at t = {:.2}, not {:.2}", t_hit(2.0 * EPS), th);
    println!("mistake 3, Duffing shift 3/4 instead of 3/8: frequency {:.4}, not {:.4}", 1.0 + 2.0 * c4 * EPS, 1.0 + EPS * c4);
    assert!((drift(R0) - law(R0)).abs() < 1e-12 && (root(&drift) - 2.0).abs() < 1e-9);   // quadrature meets formula
    assert!((t - th).abs() < 0.01 && (th - 49.33).abs() < 0.005 && (closed(t) - GOAL).abs() < 1e-3);   // stepping meets closed form
    assert!((t_full - th).abs() < 0.5 && (full[10] - 2.0).abs() < 0.01);                  // full law follows slow law
    assert!((w_rk - (1.0 + EPS * c4)).abs() < 0.002 && (c4 - 0.375).abs() < 1e-12);       // Duffing: RK4 meets averaging
    println!("ALL CHECKS PASS");
}
