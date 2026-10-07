// Adaptive steps on the skydiver v' = 9.8 - 0.2v, v(0) = 0, exact v = 49(1 - e^(-0.2t)).
// Road A: the Dormand-Prince 5(4) pair, stage by stage, with the step controller.
// Road B: closed forms. On this equation every step multiplies the gap 49 - v by a
// polynomial in z = -0.2h, and the exact answer multiplies it by e^z.
const A: [&[f64]; 7] = [&[], &[1.0 / 5.0], &[3.0 / 40.0, 9.0 / 40.0],
    &[44.0 / 45.0, -56.0 / 15.0, 32.0 / 9.0],
    &[19372.0 / 6561.0, -25360.0 / 2187.0, 64448.0 / 6561.0, -212.0 / 729.0],
    &[9017.0 / 3168.0, -355.0 / 33.0, 46732.0 / 5247.0, 49.0 / 176.0, -5103.0 / 18656.0],
    &[35.0 / 384.0, 0.0, 500.0 / 1113.0, 125.0 / 192.0, -2187.0 / 6784.0, 11.0 / 84.0]];
const B4: [f64; 7] = [5179.0 / 57600.0, 0.0, 7571.0 / 16695.0, 393.0 / 640.0,
    -92097.0 / 339200.0, 187.0 / 2100.0, 1.0 / 40.0];
fn f(v: f64) -> f64 { 9.8 - 0.2 * v }
fn comb(v: f64, h: f64, w: &[f64], k: &[f64]) -> f64 {
    v + h * w.iter().zip(k).map(|(a, q)| a * q).sum::<f64>()
}
fn pair(v: f64, h: f64) -> (f64, f64) { // one Dormand-Prince step: fifth, fourth
    let mut k: Vec<f64> = Vec::new();
    for row in A.iter() { let s = comb(v, h, row, &k); k.push(f(s)); }
    (comb(v, h, A[6], &k), comb(v, h, &B4, &k))
}
fn allowed(v: f64, w: f64) -> f64 { 1e-6 * (1.0 + v.abs().max(w.abs())) }
fn solve(tend: f64, mut h: f64, safety: f64) -> (f64, Vec<f64>, Vec<f64>, u32) {
    let (mut t, mut v, mut ends, mut lens, mut rejected) = (0.0, 0.0, vec![], vec![], 0);
    while t < tend - 1e-12 {
        h = h.min(tend - t);
        let (v5, v4) = pair(v, h);
        let (est, tol) = ((v5 - v4).abs(), allowed(v, v5));
        if est <= tol { t += h; v = v5; ends.push(t); lens.push(h); } else { rejected += 1; }
        h *= (safety * (tol / est).powf(0.2)).max(0.2).min(5.0);
    }
    (v, ends, lens, rejected)
}
fn exact(t: f64) -> f64 { 49.0 * (1.0 - (-0.2 * t).exp()) }
fn poly(z: f64, c: &[f64]) -> f64 { c.iter().rev().fold(0.0, |acc, ci| acc * z + ci) }
fn join(x: &[f64]) -> String { x.iter().map(|e| format!("{:.2}", e)).collect::<Vec<_>>().join(", ") }
fn main() {
    let r5 = [1.0, 1.0, 0.5, 1.0 / 6.0, 1.0 / 24.0, 1.0 / 120.0, 1.0 / 600.0];
    let d = [0.0, 0.0, 0.0, 0.0, 0.0, -97.0 / 120000.0, 39.0 / 120000.0, -5.0 / 120000.0];
    let (v5, v4) = pair(0.0, 1.0);
    let est = (v5 - v4).abs();
    println!("try h=1.000: fifth {:.9}, fourth {:.9}, estimate {:.4e}, allowed {:.4e}", v5, v4, v4 - v5, allowed(0.0, v5));
    assert!((v5 - 49.0 * (1.0 - poly(-0.2, &r5))).abs() < 1e-12 && (v4 - v5 - 49.0 * poly(-0.2, &d)).abs() < 1e-12);
    println!("by hand: R5(-0.2) = {:.9}, D(-0.2) = {:.4e}", poly(-0.2, &r5), poly(-0.2, &d));
    println!("road B, estimate 49 D(-0.2) = {:.4e}", 49.0 * poly(-0.2, &d));
    println!("true error, computed minus exact: fourth {:.4e}, fifth {:.4e}", v4 - exact(1.0), v5 - exact(1.0));
    assert!(((v4 - v5) / (v4 - exact(1.0)) - 1.0).abs() < 0.1);
    let h1 = 0.9 * (allowed(0.0, v5) / est).powf(0.2);
    let (w5, w4) = pair(0.0, h1);
    let ok = if (w5 - w4).abs() <= allowed(0.0, w5) { "accepted" } else { "rejected" };
    println!("retry h={:.3}: estimate {:.4e}, allowed {:.4e}, {}", h1, (w5 - w4).abs(), allowed(0.0, w5), ok);
    let (x5, x4) = pair(0.0, 0.5);
    println!("halve h=1: estimate shrinks by {:.2} (2^5 = 32)", est / (x5 - x4).abs());
    let rk4 = |v: f64, h: f64| 49.0 - (49.0 - v) * poly(-0.2 * h, &r5[..5]);
    let (yc, yf) = (rk4(0.0, 1.0), rk4(rk4(0.0, 0.5), 0.5));
    println!("step doubling, RK4 h=1: estimate {:.4e}, true fine error {:.4e}", (yc - yf) / 15.0, yf - exact(1.0));
    assert!(((yc - yf) / 15.0 / (yf - exact(1.0)) - 1.0).abs() < 0.1);
    let (v, ends, lens, rej) = solve(25.0, 1.0, 0.9);
    let early = ends.iter().filter(|&&e| e <= 5.0).count();
    println!("accepted {}, rejected {}; first 5 s: {}, after: {}", ends.len(), rej, early, ends.len() - early);
    println!("figure, step ends t: {}", join(&ends));
    println!("figure, step lengths h: {}", join(&lens));
    println!("v(25): adaptive {:.9}, exact {:.9}, global error {:.3e}", v, exact(25.0), v - exact(25.0));
    assert!((v - exact(25.0)).abs() < 1e-5);
    let hmin = lens[..lens.len() - 1].iter().cloned().fold(f64::MAX, f64::min);
    println!("breaks: no safety factor rejects {}; uniform at smallest h needs {} steps", solve(25.0, 1.0, 1.0).3, (25.0 / hmin) as u32 + 1);
    println!("breaks: step doubling divided by 31, not 15: {:.4e}", (yc - yf) / 31.0);
    println!("PASS");
}
