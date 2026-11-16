// Fredholm alternative -- the same check as the Python, in Rust.  No crates.
// A 1 m layer of damp wood chips, both faces held at air temperature, heated
// by 25 W/m^3 plus 1.25 W/m^3 per kelvin of warming; k = 0.25 W/(m K).  All
// illustrative.  Scaled by k: u = f + lam K u, f = K q, q = 100 K/m^2,
// lam = 5 1/m^2, kernel K(x, y) = min(x, y) (1 - max(x, y)) on 0 <= x, y <= 1 m.
use std::f64::consts::PI;
const KC: f64 = 0.25;
const Q0: f64 = 25.0;
const BETA: f64 = 1.25;
const Q: f64 = Q0 / KC;
const L1: f64 = PI * PI; // lowest eigenvalue n^2 pi^2 of -u''

fn kern(x: f64, y: f64) -> f64 { x.min(y) * (1.0 - x.max(y)) }
fn total<I: Iterator<Item = f64>>(xs: I) -> f64 { let mut s = 0.0; for v in xs { s += v; } s }
fn closed(lv: f64, x: f64) -> f64 { // road 1: -u'' = q + lv u, u(0) = u(1) = 0
    if lv == 0.0 { return Q * x * (1.0 - x) / 2.0; }
    let s = lv.sqrt();
    Q * ((s * (x - 0.5)).cos() / (s / 2.0).cos() - 1.0) / lv
}
fn apply_k(p: &[f64]) -> Vec<f64> { // K on a polynomial: -w'' = p, w(0) = w(1) = 0
    let mut w = vec![0.0, 0.0];
    for k in 0..p.len() { w.push(-p[k] / (((k + 1) * (k + 2)) as f64)); }
    w[1] = -total(w.iter().cloned());
    w
}
fn peval(p: &[f64], x: f64) -> f64 { let mut v = 0.0; for c in p.iter().rev() { v = v * x + c; } v }
fn neumann(lv: f64, nmax: usize) -> Vec<f64> { // road 2: u = f + lv K f + lv^2 K^2 f + ...
    let mut t = apply_k(&[Q]);
    let mut terms = vec![];
    for _ in 0..=nmax {
        terms.push(peval(&t, 0.5));
        t = apply_k(&t).iter().map(|c| lv * c).collect();
    }
    terms
}
fn partial(terms: &[f64], n: usize) -> f64 { total(terms[..=n].iter().cloned()) }
fn modes(lv: f64, x: f64, nmax: usize) -> f64 { // road 3: sum <q, phi_n> phi_n(x) / (lam_n - lv)
    total((1..=nmax).step_by(2).map(|n| { let n = n as f64;
        4.0 * Q * (n * PI * x).sin() / (n * PI * (n * n * L1 - lv)) }))
}
fn nystrom(lv: f64, n: usize) -> f64 { // road 4: trapezoid grid, Gaussian elimination
    let h = 1.0 / n as f64;
    let xs: Vec<f64> = (1..n).map(|i| i as f64 * h).collect();
    let m = n - 1;
    let mut a: Vec<Vec<f64>> = (0..m).map(|i| {
        let mut row: Vec<f64> = (0..m).map(|j| (if i == j { 1.0 } else { 0.0 }) - lv * h * kern(xs[i], xs[j])).collect();
        row.push(closed(0.0, xs[i])); row }).collect();
    for c in 0..m {
        let mut p = c;
        for r in c..m { if a[r][c].abs() > a[p][c].abs() { p = r; } }
        a.swap(c, p);
        for r in c + 1..m {
            let f = a[r][c] / a[c][c];
            for k in c..=m { a[r][k] -= f * a[c][k]; }
        }
    }
    let mut u = vec![0.0; m];
    for r in (0..m).rev() { u[r] = (a[r][m] - total((r + 1..m).map(|k| a[r][k] * u[k]))) / a[r][r]; }
    u[n / 2 - 1] // the node x = 0.5 m
}
fn power(n: usize, iters: usize) -> f64 { // top eigenvalue of the grid's K, then 1/mu
    let h = 1.0 / n as f64;
    let xs: Vec<f64> = (1..n).map(|i| i as f64 * h).collect();
    let (mut v, mut mu) = (vec![1.0; xs.len()], 0.0);
    for _ in 0..iters {
        let w: Vec<f64> = xs.iter().map(|&xi| h * total(xs.iter().zip(v.iter()).map(|(&xj, &vj)| kern(xi, xj) * vj))).collect();
        mu = total(w.iter().map(|c| c * c)).sqrt() / total(v.iter().map(|c| c * c)).sqrt();
        v = w;
    }
    1.0 / mu
}
fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, panels: usize) -> f64 {
    let h = (hi - lo) / panels as f64;
    h / 3.0 * total((0..=panels).map(|i| (if i == 0 || i == panels { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h)))
}
fn kint<F: Fn(f64) -> f64>(g: &F, x: f64) -> f64 { // (K g)(x) by Simpson, split at the kink y = x
    simpson(|y| kern(x, y) * g(y), 0.0, x, 200) + simpson(|y| kern(x, y) * g(y), x, 1.0, 200)
}
fn sci(v: f64, d: usize) -> String { // Python-style e-notation: 8.10e-06
    let s = format!("{:.*e}", d, v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let lam = BETA / KC;
    let u5 = closed(lam, 0.5);
    println!("layer 1 m, k = {} W/(m K): q = {:.0} K/m^2, lam = {:.0} 1/m^2, critical lam_1 = pi^2 = {:.4} 1/m^2", KC, Q, lam, L1);
    println!("critical beta = k pi^2 = {:.4} W/(m^3 K); critical thickness at beta = {}: {:.3} m", KC * L1, BETA, PI * (KC / BETA).sqrt());
    println!("middle rise: no reaction {:.3} K; with reaction, closed form {:.3} K", closed(0.0, 0.5), u5);
    let terms = neumann(lam, 40);
    println!("Neumann generations r = 0 to 6 at the middle, K: {}", join(&terms[..7], 3));
    let ps: Vec<f64> = [0, 1, 2, 3, 5, 10, 20].iter().map(|&n| partial(&terms, n)).collect();
    println!("  partial sums r = 0, 1, 2, 3, 5, 10, 20: {}", join(&ps, 3));
    println!("  first omitted term after r = 20: {} K; ratio of terms 20 to 19: {:.4} = lam/{:.4}", sci(terms[21], 2), terms[20] / terms[19], lam * terms[19] / terms[20]);
    let m5: Vec<f64> = [1, 3, 11, 101].iter().map(|&n| modes(lam, 0.5, n)).collect();
    println!("mode sum at the middle, odd n up to 1, 3, 11, 101: {}; next term {} K", join(&m5, 4), sci(4.0 * Q / (103.0 * PI * (103.0 * 103.0 * L1 - lam)), 1));
    let ny = [nystrom(lam, 20), nystrom(lam, 40)];
    let (order, rich) = (((ny[0] - u5) / (ny[1] - u5)).log2(), (4.0 * ny[1] - ny[0]) / 3.0);
    println!("grid at h = 0.05, 0.025 m: {:.4}, {:.4} K; observed order {:.2}; Richardson {:.4} K", ny[0], ny[1], order, rich);
    let pw = [power(20, 60), power(40, 60)];
    println!("lam_1 from the grid's top eigenvalue at h = 0.05, 0.025 m: {:.4}, {:.4} 1/m^2", pw[0], pw[1]);
    println!("kernel in its own modes, K(x, y) = sum 2 sin(n pi x) sin(n pi y) / (n^2 pi^2):");
    let mut mer = vec![];
    for &(x, y) in &[(0.5, 0.5), (0.3, 0.7)] {
        let ps: Vec<f64> = [1usize, 9, 99].iter().map(|&nn| total((1..=nn).map(|n| { let n = n as f64;
            2.0 * (n * PI * x).sin() * (n * PI * y).sin() / (n * n * L1) }))).collect();
        mer.push((ps[2] - kern(x, y)).abs());
        println!("  K({}, {}) = {:.4}; N = 1, 9, 99: {}; tail < {:.5}", x, y, kern(x, y), join(&ps, 5), 2.0 / (L1 * 99.0));
    }
    let tr = simpson(|x| kern(x, x), 0.0, 1.0, 100);
    let h2 = total((0..400).flat_map(|i| (0..400).map(move |j| { let v = kern((i as f64 + 0.5) / 400.0, (j as f64 + 0.5) / 400.0); v * v }))) / 160000.0;
    let inv = |p: i32| total((1..=1000).map(|n| 1.0 / ((n * n) as f64 * L1).powi(p)));
    println!("  trace: int K(x,x) dx = {:.6}; sum 1/lam_n, n <= 1000: {:.6}, tail < {:.6}", tr, inv(1), 1.0 / (1000.0 * L1));
    println!("  Hilbert-Schmidt: int int K^2 = {:.6}; sum 1/lam_n^2, n <= 1000: {:.6}; 1/90 = {:.6}", h2, inv(2), 1.0 / 90.0);
    println!("at the critical lam = pi^2, uniform q = 100 K/m^2:");
    let s1 = simpson(|x| Q * (PI * x).sin(), 0.0, 1.0, 200);
    let s2 = simpson(|x| Q * (2.0 * PI * x).sin(), 0.0, 1.0, 200);
    println!("  int q sin(pi x) dx = {:.3} K/m (2q/pi = {:.3}); against sin(2 pi x): {:.3}", s1, 2.0 * Q / PI, s2.abs());
    let tc = neumann(L1, 40);
    println!("  partial sums r = 10, 20, 40: {} K; each term tends to 4q/pi^3 = {:.3} K",
        [10, 20, 40].iter().map(|&n| format!("{:.2}", partial(&tc, n))).collect::<Vec<_>>().join(", "), 4.0 * Q / PI.powf(3.0));
    let qc = |y: f64| Q * (PI * y).cos();
    println!("cosine source q = 100 cos(pi x): int q sin(pi x) dx = {:.3}", simpson(|x| qc(x) * (PI * x).sin(), 0.0, 1.0, 200).abs());
    let mut res = vec![];
    for &c in &[0.0, 5.0] {
        let uc = |y: f64| -(Q / (2.0 * PI)) * y * (PI * y).sin() + c * (PI * y).sin();
        res.push(uc(0.3) - L1 * kint(&uc, 0.3) - kint(&qc, 0.3));
        println!("  c = {:.0}: u(0.5) = {:.3} K, residual of u - pi^2 K u - K q at x = 0.3: {}", c, uc(0.5), sci(res[res.len() - 1].abs(), 1));
    }
    let e12 = closed(12.0, 0.5);
    let t12 = neumann(12.0, 20);
    println!("above critical, lam = 12: closed form {:.3} K, mode sum {:.3} K, Neumann r = 10, 20: {:.0}, {:.0}, ratio 12/pi^2 = {:.3}", e12, modes(12.0, 0.5, 101), partial(&t12, 10), partial(&t12, 20), 12.0 / L1);
    println!("chart x = 0, 0.1, ..., 1 m, rise in K:");
    for &lv in &[0.0, 5.0, 9.0] {
        let pts: Vec<f64> = (0..11).map(|i| closed(lv, i as f64 / 10.0)).collect();
        println!("  lam = {}: {}", lv, join(&pts, 2));
    }
    let need: Vec<usize> = [5.0, 9.0].iter().map(|&lv| { let t = neumann(lv, 200);
        (0..200).find(|&n| (partial(&t, n) - closed(lv, 0.5)).abs() < 0.01).unwrap_or(200) }).collect();
    println!("try: lam = 8 middle {:.2} K; within 0.01 K from round r = {} (lam = 5), {} (lam = 9); thickness at beta = 2.0: {:.3} m", closed(8.0, 0.5), need[0], need[1], PI * (KC / 2.0).sqrt());
    assert!((partial(&terms, 40) - u5).abs() < 1e-9 && (m5[3] - u5).abs() < 1e-5); // three roads meet
    assert!((rich - u5).abs() < 1e-3 && 1.9 < order && order < 2.1); // grid, second order
    assert!(pw.iter().all(|p| (p - L1).abs() < 0.03) && (lam * terms[19] / terms[20] - L1).abs() < 1e-3);
    assert!((tr - 1.0 / 6.0).abs() < 1e-9 && (h2 - 1.0 / 90.0).abs() < 1e-6); // trace and K^2 by quadrature
    assert!(mer.iter().all(|&d| d < 2.0 / (99.0 * L1)) && 0.0 < tr - inv(1) && tr - inv(1) < 1.0 / (1000.0 * L1) && (inv(2) - h2).abs() < 1e-6); // Mercer's mode sums
    assert!((s1 - 2.0 * Q / PI).abs() < 1e-6 && partial(&tc, 40) > 3.0 * partial(&tc, 10)); // no steady state
    let (tmin, tmax) = (tc.iter().cloned().fold(f64::MAX, f64::min), tc.iter().cloned().fold(f64::MIN, f64::max));
    assert!((tmin - closed(0.0, 0.5)).abs() < 1e-9 && tmax < 4.0 * Q / PI.powf(3.0) + 1e-9); // rounds lie in 12.500 to 12.901 K
    assert!(res.iter().all(|r| r.abs() < 1e-6) && (e12 - modes(12.0, 0.5, 2001)).abs() < 1e-4 && partial(&t12, 20).abs() > 1e3);
    println!("ALL CHECKS PASS");
}
