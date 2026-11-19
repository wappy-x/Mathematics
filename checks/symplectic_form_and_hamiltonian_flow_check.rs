// Symplectic form and Hamiltonian flow -- the check behind the card.  std only.
// A 20 kg swing on 2 m rods, released from rest at -60 degrees.  State: angle q (rad), momentum
// p (kg m^2/s).  H = p^2/160 - 392.4 cos q.  The symplectic form is omega = dq ^ dp.
// Roads: the period by the AGM formula and by RK4; a patch of states carried by RK4, by
// leapfrog and by Euler, its area by the shoelace rule at two boundary resolutions; the
// form equation iota_X omega = dH against finite differences of H; two coupled swings,
// where the two shadow areas trade places but their sum, the integral of omega, stays.
use std::f64::consts::PI;
const I: f64 = 80.0; // m l^2
const K: f64 = 392.4; // m g l
const C: f64 = 40.0; // spring between the seats, J/rad^2
const DEG: f64 = PI / 180.0;

fn f6(x: f64) -> String { format!("{:.6}", x) }
fn sci(x: f64) -> String { // Python's .1e: two-digit exponent with its sign
    let s = format!("{:.1e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let n: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn rates(z: &[f64], c: f64) -> Vec<f64> { // Hamilton's equations for 1 or 2 swings
    let n = z.len() / 2;
    let mut f: Vec<f64> = (0..n).map(|i| -K * z[i].sin()).collect();
    if n == 2 { f[0] -= c * (z[0] - z[1]); f[1] -= c * (z[1] - z[0]); }
    let mut out: Vec<f64> = (0..n).map(|i| z[n + i] / I).collect();
    out.extend(f);
    out
}
fn axpy(z: &[f64], h: f64, k: &[f64]) -> Vec<f64> { z.iter().zip(k).map(|(a, b)| a + h * b).collect() }
fn rk4(z: &[f64], h: f64, c: f64) -> Vec<f64> {
    let k1 = rates(z, c);
    let k2 = rates(&axpy(z, h / 2.0, &k1), c);
    let k3 = rates(&axpy(z, h / 2.0, &k2), c);
    let k4 = rates(&axpy(z, h, &k3), c);
    (0..z.len()).map(|i| z[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect()
}
fn euler(z: &[f64], h: f64) -> Vec<f64> { vec![z[0] + h * z[1] / I, z[1] - h * K * z[0].sin()] }
fn leap(z: &[f64], h: f64) -> Vec<f64> { // half kick, drift, half kick
    let p = z[1] - h / 2.0 * K * z[0].sin();
    let q = z[0] + h * p / I;
    vec![q, p - h / 2.0 * K * q.sin()]
}
fn ham(q: f64, p: f64) -> f64 { p * p / (2.0 * I) - K * q.cos() }
fn det(m: &[Vec<f64>]) -> f64 { // determinant by Laplace expansion along the first row
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| (if j % 2 == 0 { 1.0 } else { -1.0 }) * m[0][j] * det(&m[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect::<Vec<_>>())).sum()
}
fn solve_x(om: &dyn Fn((f64, f64), (f64, f64)) -> f64, g: (f64, f64)) -> (f64, f64) { // the X with iota_X om = g on (dq, dp), by Cramer's rule
    let (a, b) = ((om((1.0, 0.0), (1.0, 0.0)), om((1.0, 0.0), (0.0, 1.0))), (om((0.0, 1.0), (1.0, 0.0)), om((0.0, 1.0), (0.0, 1.0))));
    let d = a.0 * b.1 - b.0 * a.1;
    ((g.0 * b.1 - b.0 * g.1) / d + 0.0, (a.0 * g.1 - g.0 * a.1) / d + 0.0)
}
fn agm_period(q0: f64) -> f64 { // T = 2 pi sqrt(l/g) / AGM(1, cos(q0/2))
    let (mut a, mut b) = (1.0f64, (q0 / 2.0).cos());
    for _ in 0..30 { let a2 = (a + b) / 2.0; b = (a * b).sqrt(); a = a2; }
    2.0 * PI * (2.0f64 / 9.81).sqrt() / a
}
fn square(n: usize, q0: f64) -> Vec<(f64, f64)> { // boundary of q0-2..q0+2 deg by 0..8, anticlockwise
    let (lo, hi, d, nf) = (q0 - 2.0 * DEG, q0 + 2.0 * DEG, 4.0 * DEG / n as f64, n as f64);
    let mut v = Vec::new();
    for k in 0..n { v.push((lo + d * k as f64, 0.0)); }
    for k in 0..n { v.push((hi, 8.0 * k as f64 / nf)); }
    for k in 0..n { v.push((hi - d * k as f64, 8.0)); }
    for k in 0..n { v.push((lo, 8.0 - 8.0 * k as f64 / nf)); }
    v
}
fn shoelace(p: &[(f64, f64)]) -> f64 {
    let n = p.len();
    (0..n).fold(0.0, |s, i| s + (p[i].0 * p[(i + 1) % n].1 - p[(i + 1) % n].0 * p[i].1)) / 2.0
}
fn carry(pts: &[(f64, f64)], step: &dyn Fn(&[f64], f64) -> Vec<f64>, h: f64, steps: usize) -> Vec<(f64, f64)> {
    pts.iter().map(|&(q, p)| {
        let mut z = vec![q, p];
        for _ in 0..steps { z = step(&z, h); }
        (z[0], z[1])
    }).collect()
}
fn main() {
    let q0 = -PI / 3.0;
    let rk = |z: &[f64], h: f64| rk4(z, h, 0.0);
    println!("swing: m l^2 = 80 kg m^2, m g l = 392.4 J, release -60 deg, H = {} J", f6(ham(q0, 0.0)));
    let t_p = agm_period(q0);
    let (mut z, mut t, h) = (vec![q0, 0.0], 0.0f64, 0.001); // road two: RK4 until the seat passes the bottom
    let z2 = loop {
        assert!(t < 10.0, "the seat never reached the bottom in 10 s");
        let z2 = rk4(&z, h, 0.0);
        if z2[0] >= 0.0 { break z2; }
        z = z2; t += h;
    };
    let tq = t + h * (-z[0]) / (z2[0] - z[0]);
    println!("period: AGM {:.9} s, RK4 quarter swing x 4 {:.9} s", t_p, 4.0 * tq);
    assert!((4.0 * tq - t_p).abs() < 1e-6);
    let a0 = 4.0 * DEG * 8.0;
    println!("patch at release, 4 deg = {} rad, x 8 kg m^2/s: {} J s; shoelace {}", f6(4.0 * DEG), f6(a0), f6(shoelace(&square(100, q0))));
    let mut ex = [0.0; 2];
    for (j, n) in [25usize, 100].iter().enumerate() {
        ex[j] = shoelace(&carry(&square(*n, q0), &rk, t_p / 600.0, 600));
        println!("one swing, exact flow (RK4, 600 steps), {} points a side: {} error {}", n, f6(ex[j]), sci((ex[j] - a0).abs()));
    }
    assert!((ex[1] - a0).abs() < 1e-6 && (ex[1] - a0).abs() < (ex[0] - a0).abs());
    let h = t_p / 60.0;
    println!("Euler's step stretches area by 1 + h^2 (K/I) cos q, h^2 = {} s^2, K/I = {:.3} 1/s^2", f6(h * h), K / I);
    let lf = shoelace(&carry(&square(100, q0), &leap, h, 60));
    let eu = shoelace(&carry(&square(100, q0), &euler, h, 60));
    println!("one swing, 60 steps of {} s: leapfrog {} Euler {} ratio {}", f6(h), f6(lf), f6(eu), f6(eu / a0));
    assert!((lf - a0).abs() < 1e-6 && eu > 1.5 * a0);
    let jac = |step: &dyn Fn(&[f64], f64) -> Vec<f64>, z: &[f64]| { // one-step Jacobian by central differences
        let e = 1e-6;
        let (u1, u2) = (step(&[z[0] + e, z[1]], h), step(&[z[0] - e, z[1]], h));
        let (v1, v2) = (step(&[z[0], z[1] + e], h), step(&[z[0], z[1] - e], h));
        let a = [(u1[0] - u2[0]) / (2.0 * e), (u1[1] - u2[1]) / (2.0 * e)];
        let b = [(v1[0] - v2[0]) / (2.0 * e), (v1[1] - v2[1]) / (2.0 * e)];
        a[0] * b[1] - a[1] * b[0]
    };
    let pb = (2.0 * I * (ham(q0, 0.0) + K)).sqrt();
    for (name, z) in [("release", [q0, 0.0]), ("the bottom", [0.0, pb])] {
        let (de, dl, rule) = (jac(&euler, &z), jac(&leap, &z), 1.0 + h * h * (K / I) * z[0].cos());
        println!("area factor per step at {}: Euler {:.6} (rule {:.6}), leapfrog {:.6}", name, de, rule, dl);
        assert!((de - rule).abs() < 1e-6 && (dl - 1.0).abs() < 1e-8);
    }
    for (name, (q, p)) in [("release", (q0, 0.0)), ("the bottom", (0.0, pb))] {
        let x: Vec<f64> = rates(&[q, p], 0.0).iter().map(|v| v + 0.0).collect(); // iota_X omega = X_q dp - X_p dq
        let iw = (-x[1] + 0.0, x[0]);
        let dh = ((ham(q + 1e-6, p) - ham(q - 1e-6, p)) / 2e-6, (ham(q, p + 1e-6) - ham(q, p - 1e-6)) / 2e-6);
        println!("at {}: X = ({:.4}, {:.4}), iota_X omega = ({:.4} dq, {:.4} dp), dH = ({:.4} dq, {:.4} dp)",
                 name, x[0], x[1], iw.0, iw.1, dh.0, dh.1);
        assert!((iw.0 - dh.0).abs() < 1e-5 && (iw.1 - dh.1).abs() < 1e-5);
    }
    let g0 = ((ham(q0 + 1e-6, 0.0) - ham(q0 - 1e-6, 0.0)) / 2e-6, (ham(q0, 1e-6) - ham(q0, -1e-6)) / 2e-6); // dH at release
    let (xw, xr) = (solve_x(&|u: (f64, f64), v: (f64, f64)| u.0 * v.1 - u.1 * v.0, g0), solve_x(&|u: (f64, f64), v: (f64, f64)| u.1 * v.0 - u.0 * v.1, g0));
    println!("solve iota_X omega = dH at release: omega = dq^dp, X = ({:.4}, {:.4}); omega = dp^dq, X = ({:.4}, {:.4})", xw.0, xw.1, xr.0, xr.1);
    assert!((xw.1 - rates(&[q0, 0.0], 0.0)[1]).abs() < 1e-5 && (xr.1 + rates(&[q0, 0.0], 0.0)[1]).abs() < 1e-5);
    println!("two swings, spring 40 J/rad^2: t (s), shadow q1p1, shadow q2p2, sum (J s)");
    let mut chart: [Vec<String>; 3] = [vec![], vec![], vec![]];
    let mut s = std::collections::HashMap::new();
    for n in [25usize, 50] {
        let mut pts: Vec<Vec<f64>> = square(n, q0).iter().map(|&(q, p)| vec![q, 0.0, p, 0.0]).collect();
        for k in 0..2001 {
            if k % 100 == 0 {
                let a1 = shoelace(&pts.iter().map(|w| (w[0], w[2])).collect::<Vec<_>>());
                let a2 = shoelace(&pts.iter().map(|w| (w[1], w[3])).collect::<Vec<_>>());
                s.insert((n, k / 100), (a1, a2));
                if n == 50 {
                    for (row, v) in chart.iter_mut().zip([a1, a2, a1 + a2]) { row.push(format!("{:.4}", v)); }
                    if k % 500 == 0 { println!("t = {:2}: {} {} {}", k / 100, f6(a1), f6(a2), f6(a1 + a2)); }
                }
            }
            if k < 2000 { pts = pts.iter().map(|w| rk4(w, 0.01, C)).collect(); }
        }
    }
    let sum = |n: usize, t: usize| { let (a, b) = s[&(n, t)]; a + b };
    for n in [25usize, 50] {
        println!("t = 20, {} points a side: sum {}, error {}", n, f6(sum(n, 20)), sci((sum(n, 20) - a0).abs()));
    }
    assert!((sum(50, 20) - a0).abs() < 1e-5 && s[&(50, 15)].0.abs() < 0.01 && s[&(50, 15)].1 > 0.5);
    for (name, row) in ["chart, shadow q1p1", "chart, shadow q2p2", "chart, sum"].iter().zip(chart.iter()) { println!("{} [{}]", name, row.join(", ")); }
    let stretch = |w: &[f64]| vec![2.0 * w[0], w[1], w[2] / 2.0, w[3]]; // state (q1, p1, q2, p2): q1 doubled, q2 halved
    let js: Vec<Vec<f64>> = (0..4).map(|i| (0..4).map(|j| stretch(&(0..4).map(|k| if k == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>())[i]).collect()).collect();
    let sq: Vec<(f64, f64)> = square(50, q0).iter().map(|&(q, p)| { let w = stretch(&[q, p, 0.0, 0.0]); (w[0], w[1]) }).collect(); // the patch, stretched
    println!("stretch q1 x2, q2 x1/2: volume factor {} omega on the patch {}", f6(det(&js)), f6(shoelace(&sq)));
    assert!((shoelace(&sq) - 2.0 * a0).abs() < 1e-9 && (det(&js) - 1.0).abs() < 1e-12);
    println!("try: Euler 600 steps {} | leapfrog 15 steps {}",
             f6(shoelace(&carry(&square(100, q0), &euler, t_p / 600.0, 600))),
             f6(shoelace(&carry(&square(100, q0), &leap, t_p / 15.0, 15))));
    let t90 = agm_period(-PI / 2.0);
    println!("try: release -90 deg, period {:.6} s, area after one swing {}", t90,
             f6(shoelace(&carry(&square(100, -PI / 2.0), &rk, t90 / 600.0, 600))));
    println!("ALL CHECKS PASS");
}
