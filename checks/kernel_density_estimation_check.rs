// Kernel density estimation -- the same check as kernel_density_estimation_check.py, in Rust.
// Standard library only, no crates.  As in the Python, the bell area Phi is built by Simpson slices.
use std::f64::consts::PI;
const A: [f64; 8] = [1.2, 1.9, 2.4, 2.8, 3.1, 3.5, 4.2, 5.0];
const B: [f64; 8] = [2.6, 3.3, 3.9, 4.4, 4.8, 5.5, 6.1, 7.0];

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let w = (b - a) / m as f64;
    let mut inner = 0.0;
    for i in 1..m { inner += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * w); }
    (f(a) + f(b) + inner) * w / 3.0
}
fn big_phi(z: f64) -> f64 { 0.5 + simpson(phi, 0.0, z, 4000) }      // area to the left of z
fn npdf(x: f64, sd: f64) -> f64 { phi(x / sd) / sd }
fn kde(x: f64, d: &[f64], h: f64) -> f64 { d.iter().map(|xi| phi((x - xi) / h)).sum::<f64>() / (d.len() as f64 * h) }
fn mean(d: &[f64]) -> f64 { d.iter().sum::<f64>() / d.len() as f64 }
fn sd(d: &[f64], div: f64) -> f64 { let m = mean(d); (d.iter().map(|v| (v - m) * (v - m)).sum::<f64>() / div).sqrt() }
fn hinges(d: &[f64]) -> (f64, f64) {
    let mut v = d.to_vec(); v.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let k = v.len() / 2;
    let med = |w: &[f64]| (w[(w.len() - 1) / 2] + w[w.len() / 2]) / 2.0;
    (med(&v[..k]), med(&v[v.len() - k..]))
}
fn silverman(d: &[f64], iqr_in: Option<f64>) -> f64 {
    let (q1, q3) = hinges(d);
    let iqr = iqr_in.unwrap_or(q3 - q1);
    0.9 * sd(d, d.len() as f64 - 1.0).min(iqr / 1.34) * (d.len() as f64).powf(-0.2)
}
fn without(d: &[f64], i: usize) -> Vec<f64> { d.iter().enumerate().filter(|(j, _)| *j != i).map(|(_, v)| *v).collect() }
fn cv_closed(d: &[f64], h: f64, leave_out: bool) -> f64 {
    let n = d.len() as f64;
    let mut i2 = 0.0;
    for a in d { for b in d { i2 += npdf(a - b, 2f64.sqrt() * h); } }
    i2 /= n * n;
    let mut fit = 0.0;
    for (i, a) in d.iter().enumerate() {
        if leave_out {
            let mut t = 0.0;
            for (j, b) in d.iter().enumerate() { if j != i { t += npdf(a - b, h); } }
            fit += t / (n - 1.0);
        } else { fit += kde(*a, d, h); }
    }
    i2 - 2.0 * fit / n
}
fn cv_simpson(d: &[f64], h: f64) -> f64 {
    let i2 = simpson(|x| kde(x, d, h).powi(2), -10.0, 16.0, 2000);
    let mut fit = 0.0;
    for (i, a) in d.iter().enumerate() { fit += kde(*a, &without(d, i), h); }
    i2 - 2.0 * fit / d.len() as f64
}

fn main() {
    let (n, x0) = (A.len() as f64, 3.0_f64);
    let (m, s) = (mean(&A), sd(&A, n - 1.0));
    let (q1, q3) = hinges(&A);
    let h = silverman(&A, None);
    let mn = s.min((q3 - q1) / 1.34);
    println!("mean {:.4}  s {:.4}  Q1 {:.2}  Q3 {:.2}  IQR {:.2}  IQR/1.34 {:.4}", m, s, q1, q3, q3 - q1, (q3 - q1) / 1.34);
    println!("min(s, IQR/1.34) {:.4}  8^(-1/5) {:.4}  h = 0.9 x {:.4} x {:.4} = {:.4}", mn, n.powf(-0.2), mn, n.powf(-0.2), h);
    let (mut lo, mut hi) = (0.0_f64, 2.0_f64);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if big_phi(mid) < 0.75 { lo = mid } else { hi = mid } }
    println!("standard bell: IQR {:.4}  R(K) = 1/(2 sqrt(pi)) {:.4}  (4/3)^(1/5) {:.4}", 2.0 * lo, 1.0 / (2.0 * PI.sqrt()), (4.0_f64 / 3.0).powf(0.2));
    println!("wait   z = (3 - wait)/h   bell height phi(z)");
    for xi in A { println!("{:4.1}   {:+8.4}            {:.4}", xi, (x0 - xi) / h, phi((x0 - xi) / h)); }
    let tot: f64 = A.iter().map(|xi| phi((x0 - xi) / h)).sum();
    let f1 = kde(x0, &A, h);
    let dd = 1e-4;
    let f2 = (A.iter().map(|xi| big_phi((x0 + dd - xi) / h) - big_phi((x0 - dd - xi) / h)).sum::<f64>() / n) / (2.0 * dd);
    let area = simpson(|x| kde(x, &A, h), -10.0, 16.0, 4000);
    let below0 = A.iter().map(|xi| big_phi(-xi / h)).sum::<f64>() / n;
    println!("sum of heights {:.4}   divide by n h = {:.4}", tot, n * h);
    println!("road 1  average of 8 bells   fhat(3) = {:.6}", f1);
    println!("road 2  slope of smooth CDF  fhat(3) = {:.6}", f2);
    println!("area under fhat {:.6}   area below 0 minutes {:.4}", area, below0);
    for a0 in [1.0_f64, 0.5] {
        let cnt: Vec<usize> = (0..6).map(|k| A.iter().filter(|&&v| a0 + k as f64 <= v && v < a0 + k as f64 + 1.0).count()).collect();
        println!("histogram, bins of 1 min from {:.1}: counts {:?}   density at 3 = {:.3}", a0, cnt, cnt[(x0 - a0).floor() as usize] as f64 / n);
    }
    let xs: Vec<f64> = (0..15).map(|k| 0.5 * k as f64).collect();
    println!("chart x      {}", xs.iter().map(|x| format!("{:5.1}", x)).collect::<Vec<_>>().join(" "));
    for hh in [0.25, h, 1.5] {
        println!("chart h={:.2} {}", hh, xs.iter().map(|x| format!("{:5.3}", kde(*x, &A, hh))).collect::<Vec<_>>().join(" "));
    }

    // ---- bias and variance at 3 minutes, if the waits were truly bell-shaped (centre m, spread s) ----
    let u = x0 - m;
    let f_true = npdf(u, s);
    let f2nd = npdf(u, s) * (u * u / s.powi(4) - 1.0 / (s * s));
    let exact = |hh: f64| -> (f64, f64) {
        let ef = npdf(u, (s * s + hh * hh).sqrt());
        let ek2 = npdf(u, (s * s + hh * hh / 2.0).sqrt()) / (2.0 * PI.sqrt() * hh);
        (ef - f_true, (ek2 - ef * ef) / n)
    };
    println!("true f(3) {:.4}   f''(3) {:.4}", f_true, f2nd);
    println!("h      bias exact  h^2 f''/2   var exact  f/(2 sqrt(pi) n h)  MSE");
    for hh in [0.25, 0.5, h, 1.0, 1.5] {
        let (b, v) = exact(hh);
        println!("{:.4} {:+.5}   {:+.5}    {:.5}    {:.5}          {:.5}", hh, b, hh * hh * f2nd / 2.0, v, f_true / (2.0 * PI.sqrt() * n * hh), b * b + v);
    }
    let mut state: u64 = 20261123;
    let mut unif = || { state ^= state << 13; state ^= state >> 7; state ^= state << 17; ((state >> 11) as f64 + 0.5) / 2f64.powi(53) };
    let (reps, mut acc, mut acc2) = (20000, 0.0_f64, 0.0_f64);
    for _ in 0..reps {
        let smp: Vec<f64> = (0..8).map(|_| { let a = unif(); let b = unif(); m + s * (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos() }).collect();
        let v = kde(x0, &smp, h); acc += v; acc2 += v * v;
    }
    let sim_mean = acc / reps as f64;
    let sim_var = acc2 / reps as f64 - sim_mean * sim_mean;
    let (b_ex, v_ex) = exact(h);
    println!("simulation, {} samples of 8: mean fhat(3) {:.5} (exact {:.5})  var {:.5} (exact {:.5})", reps, sim_mean, f_true + b_ex, sim_var, v_ex);
    let h_amise = (4.0_f64 / 3.0).powf(0.2) * s * n.powf(-0.2);
    let mise = |hh: f64| { let t = (s * s + hh * hh).sqrt();
        (1.0 / hh - 1.0 / t) / (2.0 * PI.sqrt() * n) + 1.0 / (2.0 * PI.sqrt() * t) - 2.0 * npdf(0.0, (t * t + s * s).sqrt()) + 1.0 / (2.0 * PI.sqrt() * s) };
    let mut h_mise = 0.1;
    for k in 100..=3000 { let hh = k as f64 / 1000.0; if mise(hh) < mise(h_mise) { h_mise = hh; } }
    println!("optimal-rate h = (4/3)^(1/5) s n^(-1/5) = {:.4}   exact MISE minimum at h = {:.3}", h_amise, h_mise);

    // ---- cross-validation ----
    let argmin = |lo_out: bool| { let mut best = 0.10;
        for k in 10..=300 { let hh = k as f64 / 100.0; if cv_closed(&A, hh, lo_out) < cv_closed(&A, best, lo_out) { best = hh; } } best };
    let h_cv = argmin(true);
    println!("CV score at h: 0.30 {:+.4}  0.73 {:+.4}  1.43 {:+.4}  2.00 {:+.4}", cv_closed(&A, 0.3, true), cv_closed(&A, h, true), cv_closed(&A, 1.43, true), cv_closed(&A, 2.0, true));
    println!("CV picks h = {:.2}   brute-force integral at 1.43: {:+.4}   fhat(3) there {:.4}", h_cv, cv_simpson(&A, 1.43), kde(x0, &A, h_cv));
    let h_nlo = argmin(false);
    println!("wrong: CV without leaving out picks h = {:.2} (the smallest allowed)", h_nlo);

    // ---- what breaks ----
    let (q1i, q3i) = (A[1] + 0.75 * (A[2] - A[1]), A[5] + 0.25 * (A[6] - A[5]));   // interpolated quartiles, R's default
    let (h_i, h_r, h_p) = (silverman(&A, Some(q3i - q1i)), 0.9 * s * n.powf(-0.5), 0.9 * sd(&A, n) * n.powf(-0.2));
    println!("wrong: forget 1/h            fhat(3) = {:.4}", tot / n);
    println!("other rule: interpolated IQR {:.2}  h = {:.4}  fhat(3) = {:.4}", q3i - q1i, h_i, kde(x0, &A, h_i));
    println!("wrong: n^(-1/2)              h = {:.4}  fhat(3) = {:.4}", h_r, kde(x0, &A, h_r));
    println!("wrong: s divided by n        h = {:.4}  fhat(3) = {:.4}", h_p, kde(x0, &A, h_p));
    let hb = silverman(&B, None);
    let mut a9 = A.to_vec(); a9.push(12.0);
    let (r1, r3) = hinges(&a9);
    println!("try: shop B h = {:.4}  fhatB(3) = {:.4}  fhatB(5) = {:.4}", hb, kde(x0, &B, hb), kde(5.0, &B, hb));
    println!("try: add a 12-min wait  s = {:.4}  IQR/1.34 = {:.4}  h = {:.4}", sd(&a9, 8.0), (r3 - r1) / 1.34, silverman(&a9, None));
    println!("try: 80 waits, same spread  h = {:.4}  MISE shrinks by 10^(-4/5) = {:.4}", 0.9 * s * 80f64.powf(-0.2), 10f64.powf(-0.8));

    assert!((h - 0.9 * 1.2275847 * 2f64.powf(-0.6)).abs() < 1e-6, "Silverman's h by hand");
    assert!((f1 - f2).abs() < 1e-6, "average of bells = slope of smoothed CDF");
    assert!((area - 1.0).abs() < 1e-9, "a kernel estimate is a density");
    assert!((sim_mean - (f_true + b_ex)).abs() < 4.0 * (sim_var / reps as f64).sqrt(), "simulated mean vs exact E fhat");
    assert!((sim_var - v_ex).abs() / v_ex < 0.05, "simulated variance vs exact");
    let (b05, _) = exact(0.05);
    assert!((b05 / (0.05 * 0.05 * f2nd / 2.0) - 1.0).abs() < 0.01, "bias is h^2 f''/2 for small h");
    assert!((cv_closed(&A, 1.43, true) - cv_simpson(&A, 1.43)).abs() < 1e-8, "CV integral: identity vs brute force");
    assert!(h_nlo == 0.10, "without leaving out, CV runs to the smallest h");
    assert!((2.0 * lo - 1.349).abs() < 1e-3, "IQR of the standard bell");
    println!("ALL CHECKS PASS");
}
