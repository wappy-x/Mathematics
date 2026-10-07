// Finite differences for a boundary problem -- the same check as the Python, in Rust.
// No crates.  The shelf: y'' = -1 on [0, 1] m, y(0) = y(1) = 0, exact sag x(1 - x)/2.
// Road one: the Thomas sweep.  Road two: closed forms.
use std::f64::consts::PI;

fn sweep(f: &dyn Fn(f64) -> f64, n: usize, h: f64) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let (mut p, mut r) = (vec![-2.0], vec![h * h * f(h)]);   // y[i-1] - 2 y[i] + y[i+1] = h^2 f(x_i)
    for i in 2..=n {                                          // forward: clear the 1 below each pivot
        let q = p[p.len() - 1];
        p.push(-2.0 - 1.0 / q);
        let last = r[r.len() - 1];
        r.push(h * h * f(i as f64 * h) - last / q);
    }
    let mut y = vec![0.0; n];
    y[n - 1] = r[n - 1] / p[n - 1];
    for i in (0..n - 1).rev() { y[i] = (r[i] - y[i + 1]) / p[i]; }   // back: last unknown first
    (p, r, y)
}
fn row(v: &[f64], d: usize) -> String { v.iter().map(|a| format!("{:.*}", d, a)).collect::<Vec<_>>().join(" ") }
fn maxgap(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max) }

fn main() {
    let uni = |_x: f64| -1.0;                                 // even load: w/T = 1 per metre
    let (n, h) = (9usize, 0.1);
    let (p, r, y) = sweep(&uni, n, h);
    let ex: Vec<f64> = (1..=n).map(|i| i as f64 * h * (1.0 - i as f64 * h) / 2.0).collect();
    println!("shelf: tension 200 N, load 200 N/m, y'' = -1.0 per m; N = {}, h = {:.1} m", n, h);
    println!("pivots p1..p9: {}", row(&p, 4));
    println!("right sides r1..r9: {}", row(&r, 4));
    println!("grid y1..y9: {}", row(&y, 6));
    println!("exact x(1-x)/2: {}", row(&ex, 6));
    let eu = maxgap(&y, &ex);
    println!("largest node error, even load: {:.10}; midpoint {:.6} m", eu, y[4]);
    let heap = |x: f64| -(PI / 2.0) * (PI * x).sin();         // same total load, heaped in the middle
    let m = PI.powi(3) / 2.0;                                 // largest size of y'''' for sin(pi x)/(2 pi)
    let (mut errs, mut gap) = (vec![], 0.0f64);
    for nn in [9usize, 19, 39] {
        let hh = 1.0 / (nn as f64 + 1.0);
        let (_, _, yh) = sweep(&heap, nn, hh);
        let eig: Vec<f64> = (1..=nn).map(|i| (PI / 2.0) * (PI * i as f64 * hh).sin() * hh * hh
            / (4.0 * (PI * hh / 2.0).sin().powi(2))).collect();
        gap = gap.max(maxgap(&yh, &eig));
        let (k, exm) = (nn / 2, 1.0 / (2.0 * PI));
        errs.push(yh[k] - exm);
        let (e, b) = (errs[errs.len() - 1], hh * hh * m / 96.0);
        println!("heaped N = {}, h = {:.4}: grid {:.6}, eigen formula {:.6}, exact {:.6}, error {:.8}, bound {:.8}",
                 nn, hh, yh[k], eig[k], exm, e, b);
        assert!(0.7 * b < e && e < b);                        // max-principle bound
    }
    let rat = [errs[0] / errs[1], errs[1] / errs[2]];
    println!("error ratios per halving: {:.2}, {:.2}; orders {:.2}, {:.2}", rat[0], rat[1], rat[0].log2(), rat[1].log2());
    println!("chart, heaped midpoint error x 10^4 at h = 0.025, 0.05, 0.1: {:.2}, {:.2}, {:.2}",
             errs[2] * 1e4, errs[1] * 1e4, errs[0] * 1e4);
    println!("mistake 1, h = 1/9 for nine points: midpoint {:.6} m", sweep(&uni, 9, 1.0 / 9.0).2[4]);
    println!("mistake 2, divide by h not h^2: midpoint {:.6} m", sweep(&|_x: f64| -1.0 / h, 9, h).2[4]);
    let ex19: Vec<f64> = (1..=19).map(|i| i as f64 / 20.0 * (1.0 - i as f64 / 20.0) / 2.0).collect();
    let e19 = maxgap(&sweep(&uni, 19, 0.05).2, &ex19);
    println!("mistake 3, order read off the even load: errors {:.10} (h = 0.1), {:.10} (h = 0.05)", eu, e19);
    let mut full = vec![0.0]; full.extend(&y); full.push(0.0);
    let pts: Vec<String> = full.iter().enumerate().map(|(i, v)| format!("({},{:.1})", 40 + 28 * i, 50.0 + 1120.0 * v)).collect();
    println!("figure, 280 px/m across, 1120 px/m down; nodes (px): {}", pts.join(" "));
    assert!(eu < 1e-12 && e19 < 1e-12);                       // even load: grid equals the parabola
    assert!(gap < 1e-12);                                     // heaped load: sweep equals eigenvector formula
    assert!(rat.iter().all(|q| 3.9 < *q && *q < 4.1));        // error falls with h^2
    println!("ALL CHECKS PASS");
}
