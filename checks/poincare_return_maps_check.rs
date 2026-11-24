// Poincare maps -- the same check as the Python, in Rust.  No crates.
// The law is x'' + 0.2 x' + x = cos t: state z = (x, v), position and velocity.
// Watching it once every forcing period 2 pi turns the flow into a map P(z) = M z + c.
// Road one builds P by Runge-Kutta steps; road two builds M and the steady
// oscillation by hand formulas.  They must agree.
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;
const B: f64 = 0.2;                                   // damping
const N: usize = 4000;                                // steps per period

fn f(t: f64, z: [f64; 2]) -> [f64; 2] { [z[1], -B * z[1] - z[0] + t.cos()] }

fn flow(mut z: [f64; 2], t0: f64, span: f64, n: usize) -> [f64; 2] {   // Runge-Kutta 4 from time t0
    let (h, mut t) = (span / n as f64, t0);
    for _ in 0..n {
        let k1 = f(t, z);
        let k2 = f(t + h / 2.0, [z[0] + h / 2.0 * k1[0], z[1] + h / 2.0 * k1[1]]);
        let k3 = f(t + h / 2.0, [z[0] + h / 2.0 * k2[0], z[1] + h / 2.0 * k2[1]]);
        let k4 = f(t + h, [z[0] + h * k3[0], z[1] + h * k3[1]]);
        for i in 0..2 { z[i] += h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) }
        t += h;
    }
    z
}

fn p(z: [f64; 2]) -> [f64; 2] { flow(z, 0.0, TAU, N) }   // the once-per-period (stroboscopic) map
fn r4(v: f64) -> f64 { (v * 1e4).round() / 1e4 + 0.0 }  // no "-0.0000"
fn fmt(z: [f64; 2]) -> String { format!("({:.4}, {:.4})", r4(z[0]), r4(z[1])) }
fn dist(a: [f64; 2], b: [f64; 2]) -> f64 { ((a[0] - b[0]).powi(2) + (a[1] - b[1]).powi(2)).sqrt() }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let c = p([0.0, 0.0]);
    let (p1, p2) = (p([1.0, 0.0]), p([0.0, 1.0]));
    let m = [[p1[0] - c[0], p2[0] - c[0]], [p1[1] - c[1], p2[1] - c[1]]];   // columns: where each unit push goes
    let w = (1.0 - B * B / 4.0).sqrt();
    let (s, k) = ((TAU * w).sin() / w, (-B / 2.0 * TAU).exp());
    let mh = [[k * ((TAU * w).cos() + s * B / 2.0), k * s], [-k * s, k * ((TAU * w).cos() - s * B / 2.0)]];
    let d = (1.0 - m[0][0]) * (1.0 - m[1][1]) - m[0][1] * m[1][0];     // solve (I - M) z = c by Cramer
    let zs = [(c[0] * (1.0 - m[1][1]) + m[0][1] * c[1]) / d, ((1.0 - m[0][0]) * c[1] + m[1][0] * c[0]) / d];
    let amp = 1.0 / B;                                // steady x = a cos t + b sin t forces a = 0, b = 1/0.2
    let (tr, de) = (m[0][0] + m[1][1], m[0][0] * m[1][1] - m[0][1] * m[1][0]);
    let (size, ang) = (de.sqrt(), (de - tr * tr / 4.0).sqrt().atan2(tr / 2.0));
    let mut gaps = vec![];
    let mut z = [0.0, 0.0];
    for _ in 0..9 { gaps.push(dist(z, zs)); z = p(z) }
    let half = flow([0.0, amp], 0.0, TAU / 2.0, N / 2);
    let pred: Vec<f64> = (0..9).map(|n| amp * k.powi(n)).collect();
    let chart: Vec<f64> = (0..25).map(|j| flow([0.0, 0.0], 0.0, j as f64 * TAU / 4.0, j * N / 4 + 1)[0]).collect();
    println!("law x'' + {}x' + x = cos t; eigenvalues of A: {} +/- {:.6}i", B, -B / 2.0, w);
    println!("P(0, 0) = c = {}", fmt(c));
    println!("M by Runge-Kutta: [[{:.6}, {:.6}], [{:.6}, {:.6}]]", m[0][0], m[0][1], m[1][0], m[1][1]);
    println!("M by formula:     [[{:.6}, {:.6}], [{:.6}, {:.6}]]", mh[0][0], mh[0][1], mh[1][0], mh[1][1]);
    println!("fixed point of P: {}; steady oscillation (1/B) sin t at t = 0: (0.0000, {:.4})", fmt(zs), amp);
    println!("trace of M {:.6}, determinant {:.6} = exp(-2 pi B) {:.6}", tr, de, (-TAU * B).exp());
    println!("multipliers: size {:.4}, angle +/- {:.4} rad; exp(-pi B) = {:.4}, 2 pi (1 - w) = {:.4}", size, ang, k, TAU * (1.0 - w));
    println!("gap to fixed point after n periods from rest: {}", join(&gaps, 4));
    println!("prediction (1/B) exp(-pi B)^n:                {}", join(&pred, 4));
    println!("chart, x(t) every quarter period from rest: {}", join(&chart, 2));
    println!("mistake, forcing dropped: fixed point (0.0000, 0.0000), amplitude 0 not {:.0}", amp);
    println!("mistake, per-time factor exp(-0.1) = {:.4} as per-period: gap after 5 periods {:.4}, true {:.4}",
             (-B / 2.0).exp(), amp * (-B / 2.0).exp().powi(5), gaps[5]);
    println!("mistake, sampling every pi: steady state at t = pi is {}, so samples flip; not a 2-cycle", fmt(half));
    let worst = (0..2).flat_map(|i| (0..2).map(move |j| (i, j))).map(|(i, j)| (m[i][j] - mh[i][j]).abs()).fold(0.0, f64::max);
    assert!(worst < 1e-9);                                                  // numeric map = matrix exponential
    assert!(zs[0].abs() + (zs[1] - amp).abs() < 1e-9 && dist(p(zs), zs) < 1e-9);   // fixed point = steady oscillation
    assert!((size - (-B * PI).exp()).abs() < 1e-9 && (ang - TAU * (1.0 - w)).abs() < 1e-6); // Floquet multipliers
    assert!((gaps[8] / gaps[7] - k).abs() < 0.01 && (half[1] + amp).abs() < 1e-9); // gap ratio tends to exp(-pi B)
    println!("ALL CHECKS PASS");
}
