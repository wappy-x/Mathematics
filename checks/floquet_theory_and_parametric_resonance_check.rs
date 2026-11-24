// Floquet theory -- the same check as the Python, in Rust.  No crates.
// Hill's equation x'' + (d + 0.1 cos t) x = 0, a swing pumped at twice its natural frequency.
// Two roads to the monodromy matrix M over one period 2 pi: RK4, and exact frozen-coefficient steps.
use std::f64::consts::PI;
type Mat = [[f64; 2]; 2];
const T: f64 = 2.0 * PI; const EPS: f64 = 0.1; const I: Mat = [[1.0, 0.0], [0.0, 1.0]];
fn add(y: &Mat, k: &Mat, c: f64) -> Mat { [[y[0][0] + c * k[0][0], y[0][1] + c * k[0][1]], [y[1][0] + c * k[1][0], y[1][1] + c * k[1][1]]] }
fn mul(x: &Mat, y: &Mat) -> Mat { let e = |i: usize, j: usize| x[i][0] * y[0][j] + x[i][1] * y[1][j]; [[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]] }
fn rk4(d: f64, t1: f64, n: usize, e: f64) -> Mat { // columns: starts (1, 0) and (0, 1); rows x and x'
    let (h, mut t, mut y) = (t1 / n as f64, 0.0, I);
    let f = |t: f64, y: &Mat| -> Mat { let q = d + e * t.cos(); [y[1], [-q * y[0][0], -q * y[0][1]]] };
    for _ in 0..n {
        let k1 = f(t, &y); let k2 = f(t + h / 2.0, &add(&y, &k1, h / 2.0));
        let k3 = f(t + h / 2.0, &add(&y, &k2, h / 2.0)); let k4 = f(t + h, &add(&y, &k3, h));
        y = add(&add(&add(&add(&y, &k1, h / 6.0), &k2, h / 3.0), &k3, h / 3.0), &k4, h / 6.0); t += h;
    }
    y
}
fn frozen(d: f64, n: usize) -> Mat {           // coefficient held at its mid-step value: exact cos/sin step
    let (h, mut m) = (T / n as f64, I);
    for k in 0..n {
        let q = d + EPS * ((k as f64 + 0.5) * h).cos();
        let w = q.abs().sqrt();
        let (c, s) = if q > 0.0 { ((w * h).cos(), (w * h).sin() / w) } else { ((w * h).cosh(), (w * h).sinh() / w) };
        m = mul(&[[c, s], [-q * s, c]], &m);
    }
    m
}
fn expm(b: &Mat, t: f64) -> Mat {              // I + Bt + (Bt)^2/2! + ...
    let (mut s, mut term) = (I, I);
    for k in 1..60 { term = add(&[[0.0; 2]; 2], &mul(&term, b), t / k as f64); s = add(&s, &term, 1.0); }
    s
}
fn tr(m: &Mat) -> f64 { m[0][0] + m[1][1] } fn det(m: &Mat) -> f64 { m[0][0] * m[1][1] - m[0][1] * m[1][0] }
fn fm(m: &Mat) -> String {
    let r = |v: f64| format!("{:.4}", (v * 1e4).round() / 1e4 + 0.0);
    format!("[[{}, {}], [{}, {}]]", r(m[0][0]), r(m[0][1]), r(m[1][0]), r(m[1][1]))
}
fn gap(x: &Mat, y: &Mat) -> f64 { (0..4).map(|k| (x[k / 2][k % 2] - y[k / 2][k % 2]).abs()).fold(0.0, f64::max) }
fn grows(d: f64, e: f64) -> bool { tr(&rk4(d, T, 1000, e)).abs() > 2.0 }
fn edge(mut lo: f64, mut hi: f64, e: f64) -> f64 { // bisection on |trace M| = 2
    for _ in 0..30 { let mid = (lo + hi) / 2.0; if grows(mid, e) == grows(lo, e) { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn main() {
    let (m1, m2, m3) = (rk4(0.25, T, 4000, EPS), rk4(0.5, T, 4000, EPS), rk4(1.0, T, 4000, EPS));
    for (d, m) in [(0.25, m1), (0.5, m2)] {
        println!("delta {}: M = {}, trace {:.4}, frozen-step trace {:.4}, det {:.6}", d, fm(&m), tr(&m), tr(&frozen(d, 20000)), det(&m));
    }
    let mu1 = (tr(&m1) - (tr(&m1).powi(2) - 4.0).sqrt()) / 2.0; let mu2 = 1.0 / mu1;
    let mu3 = (tr(&m3) + (tr(&m3).powi(2) - 4.0).sqrt()) / 2.0;
    println!("delta 0.25 multipliers {:.4} and {:.4}, sum {:.4}; growth exponent {:.4} per unit time", mu1, mu2, mu1 + mu2, (-mu1).ln() / T);
    let (mut ten, direct) = (I, rk4(0.25, 10.0 * T, 40000, EPS));
    for _ in 0..10 { ten = mul(&ten, &m1) }
    println!("x after 10 periods from x = 1 at rest: M^10 {:.3}, RK4 straight through {:.3}, (mu1^10 + mu2^10)/2 = {:.3}",
             ten[0][0], direct[0][0], (mu1.powi(10) + mu2.powi(10)) / 2.0);
    let th = (tr(&m2) / 2.0).acos(); let mut b = add(&m2, &I, -th.cos());
    b = add(&[[0.0; 2]; 2], &b, th / (th.sin() * T));                              // log M / T
    println!("delta 0.5 multipliers cos {:.4} +- i sin {:.4}, size 1; B = {}; e^(B 2pi) = {}", th, th, fm(&b), fm(&expm(&b, T)));
    let (pa, pb) = (mul(&rk4(0.5, 1.0, 1000, EPS), &expm(&b, -1.0)), mul(&rk4(0.5, 1.0 + T, 5000, EPS), &expm(&b, -1.0 - T)));
    println!("P(1) = {}, P(1 + 2pi) = {}", fm(&pa), fm(&pb));
    let tongue: Vec<(f64, f64, f64)> = [0.05, 0.1, 0.15, 0.2, 0.25, 0.3].iter().map(|&e| (e, edge(0.05, 0.25, e), edge(0.25, 0.45, e))).collect(); // stability chart
    println!("tongue edges, pump {}", tongue.iter().map(|(e, lo, hi)| format!("{:.2}: {:.4} to {:.4}", e, lo, hi)).collect::<Vec<_>>().join("; "));
    println!("first-order guess 1/4 -+ pump/2: {}", tongue.iter().map(|(e, _, _)| format!("{:.4} to {:.4}", 0.25 - e / 2.0, 0.25 + e / 2.0)).collect::<Vec<_>>().join("; "));
    let ds: Vec<f64> = (0..17).map(|k| 0.1 + 0.025 * k as f64).collect();
    println!("chart delta {}", ds.iter().map(|d| format!("{:.3}", d)).collect::<Vec<_>>().join(" "));
    println!("chart trace {}", ds.iter().map(|&d| format!("{:.2}", tr(&rk4(d, T, 1000, EPS)))).collect::<Vec<_>>().join(" "));
    let fr = (0..100).map(|k| { let q = -(0.25 + EPS * (k as f64 * T / 100.0).cos()); if q > 0.0 { q.sqrt() } else { 0.0 } }).fold(f64::MIN, f64::max);
    println!("mistake 1, e^(averaged A * 2pi): trace {:.4}; mistake 2, frozen stiffness {:.2} to {:.2}, largest frozen real part {:.4}", tr(&expm(&[[0.0, 1.0], [-0.25, 0.0]], T)), 0.25 - EPS, 0.25 + EPS, fr);
    println!("mistake 3, growth over 10 periods read as |trace|^10 = {:.1}, not |mu|^10 = {:.1}", tr(&m1).abs().powi(10), mu1.abs().powi(10));
    println!("pump at the natural frequency, delta 1: trace {:.6}, growth {:.4} per period, {:.2} over 10", tr(&m3), mu3, mu3.powi(10));
    assert!(gap(&m1, &frozen(0.25, 20000)) < 1e-6 && gap(&m2, &frozen(0.5, 20000)) < 1e-6 && (det(&m1) - 1.0).abs() < 1e-9 && (tr(&frozen(1.0, 20000)) - tr(&m3)).abs() < 1e-7);
    assert!((tr(&m1) + 2.0986).abs() < 1e-4 && (tr(&m2) + 0.5753).abs() < 1e-4 && tongue.iter().all(|&(e, lo, hi)| (lo - 0.25 + e / 2.0).abs() < e * e / 4.0 && (hi - 0.25 - e / 2.0).abs() < e * e / 4.0));
    assert!((ten[0][0] - direct[0][0]).abs() < 1e-6 * direct[0][0].abs() && ((mu1.powi(10) + mu2.powi(10)) / 2.0 - direct[0][0]).abs() < 1e-6 && mu1.abs() > 1.0);
    assert!(gap(&expm(&b, T), &m2) < 1e-9 && gap(&pa, &pb) < 1e-8);           // Floquet form P(t) e^(Bt)
    println!("ALL CHECKS PASS");
}
