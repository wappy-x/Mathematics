// The round trip -- the same check as the Python, in Rust, no crates.  Test mass
// y'' + 2y' + 5y = f(t) from rest; case 1 is f = 10, case 2 is f = 10 cos t.  Road one:
// transform, partial fractions, table.  Road two: undetermined coefficients.  Road three: RK4.
use std::f64::consts::PI;

fn mul(p: &[f64], q: &[f64]) -> Vec<f64> {                  // polynomials, lowest power first
    let mut r = vec![0.0; p.len() + q.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in q.iter().enumerate() { r[i + j] += a * b } }
    r
}
fn solve(m: Vec<Vec<f64>>, v: &[f64]) -> Vec<f64> {         // Gaussian elimination, row swaps
    let n = v.len();
    let mut a: Vec<Vec<f64>> = m.iter().zip(v).map(|(row, x)| { let mut r = row.clone(); r.push(*x); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if a[r][c].abs() > a[p][c].abs() { p = r } }
        a.swap(c, p);
        for r in 0..n { if r != c { let k = a[r][c] / a[c][c]; let rc = a[c].clone(); for j in 0..=n { a[r][j] -= k * rc[j] } } }
    }
    (0..n).map(|i| a[i][n] / a[i][i]).collect()
}
fn unit(j: usize) -> Vec<f64> { let mut v = vec![0.0; j]; v.push(1.0); v }
fn transform_road(num: &[f64], p: &[f64]) -> (Vec<f64>, Vec<f64>) { // Y = num / (P (s^2 + 2s + 5))
    let (k, q) = (p.len() - 1, [5.0, 2.0, 1.0]);
    let mut cols: Vec<Vec<f64>> = (0..k).map(|j| mul(&unit(j), &q)).collect();
    for j in 0..2 { cols.push(mul(&unit(j), p)) }
    let at = |v: &Vec<f64>, i: usize| if i < v.len() { v[i] } else { 0.0 };
    let m = (0..k + 2).map(|i| cols.iter().map(|c| at(c, i)).collect()).collect();
    let x = solve(m, &(0..k + 2).map(|i| at(&num.to_vec(), i)).collect::<Vec<f64>>());
    let (d, c) = (x[k], x[k + 1]);                           // (Cs + D)/((s+1)^2 + 4)
    let mut out = if k == 1 { vec![x[0], 0.0, 0.0] } else { vec![0.0, x[1], x[0]] };
    out.extend([c, (d - c) / 2.0]);
    (x, out)
}
fn trial_road(f0: f64, fc: f64) -> Vec<f64> {              // constant K, then A cos t + B sin t
    let ab = solve(vec![vec![4.0, 2.0], vec![-2.0, 4.0]], &[fc, 0.0]);
    let c1 = -(f0 / 5.0 + ab[0]);                            // y(0) = 0
    vec![f0 / 5.0, ab[0], ab[1], c1, (c1 - ab[1]) / 2.0]     // y'(0) = B - c1 + 2 c2 = 0
}
fn y(c: &[f64], t: f64) -> f64 { c[0] + c[1] * t.cos() + c[2] * t.sin() + (-t).exp() * (c[3] * (2.0 * t).cos() + c[4] * (2.0 * t).sin()) }
fn rk4(f0: f64, fc: f64, h: f64, tt: f64) -> Vec<(f64, f64)> { // y'' = f - 2y' - 5y, from rest
    let g = |t: f64, y: f64, v: f64| [v, f0 + fc * t.cos() - 2.0 * v - 5.0 * y];
    let (mut u, mut path) = ([0.0, 0.0], vec![(0.0, 0.0)]);
    for n in 0..(tt / h).round() as usize {
        let t = n as f64 * h; let k1 = g(t, u[0], u[1]); let k2 = g(t + h / 2.0, u[0] + h / 2.0 * k1[0], u[1] + h / 2.0 * k1[1]);
        let k3 = g(t + h / 2.0, u[0] + h / 2.0 * k2[0], u[1] + h / 2.0 * k2[1]); let k4 = g(t + h, u[0] + h * k3[0], u[1] + h * k3[1]);
        for i in 0..2 { u[i] += h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) }; path.push((t + h, u[0]));
    }
    path
}
fn sci(x: f64) -> String {                                   // 3.8e-05, as Python prints it
    let s = format!("{:.1e}", x); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn main() {
    let fmt = |v: &[f64]| v.iter().map(|x| format!("{:.6}", x + 0.0)).collect::<Vec<_>>().join(", ");
    for (case, f0, fc, num, p) in [(1, 10.0, 0.0, vec![10.0], vec![0.0, 1.0]), (2, 0.0, 10.0, vec![0.0, 10.0], vec![1.0, 0.0, 1.0])] {
        let ((x, c), u) = (transform_road(&num, &p), trial_road(f0, fc));
        let part = if case == 1 { format!("{:.6}/s", x[0]) } else { format!("({:.6} s {:+.6})/(s^2 + 1)", x[1], x[0]) };
        println!("case {}: Y = {} + ({:.6} s {:+.6})/(s^2 + 2s + 5)", case, part, x[x.len() - 1], x[x.len() - 2]);
        println!("  transform road  [const, cos t, sin t, e^-t cos 2t, e^-t sin 2t] = {}", fmt(&c));
        println!("  trial road      [const, cos t, sin t, e^-t cos 2t, e^-t sin 2t] = {}", fmt(&u));
        assert!(c.iter().zip(&u).all(|(a, b)| (a - b).abs() < 1e-12));      // two roads, one answer
        let e: Vec<f64> = [0.1, 0.05].iter().map(|&h| rk4(f0, fc, h, 10.0).iter().map(|&(t, yy)| (yy - y(&c, t)).abs()).fold(0.0, f64::max)).collect();
        println!("  RK4 to t = 10: max error {} at h = 0.1, {} at h = 0.05, ratio {:.1}; y(1) = {:.2}", sci(e[0]), sci(e[1]), e[0] / e[1], y(&c, 1.0));
        assert!(e[1] < 1e-5 && 12.0 < e[0] / e[1] && e[0] / e[1] < 20.0);     // stepped motion = formula
    }
    let (x, c) = transform_road(&[10.0], &[0.0, 1.0]);
    let (mut tp, mut yp) = (0.0, f64::MIN);
    for (t, yy) in rk4(10.0, 0.0, 0.001, 3.0) { if yy > yp { tp = t; yp = yy } }
    println!("peak by RK4 scan: y = {:.6} m at t = {:.3} s; formula 2 + 2e^(-pi/2) = {:.6}, overshoot {:.1}%", yp, tp, 2.0 + 2.0 * (-PI / 2.0).exp(), 100.0 * (-PI / 2.0).exp());
    assert!((yp - (2.0 + 2.0 * (-PI / 2.0).exp())).abs() < 1e-6 && (tp - PI / 2.0).abs() < 1e-3);
    println!("figure, t {}", (0..13).map(|k| format!("{:4.1}", 0.5 * k as f64)).collect::<Vec<_>>().join(" "));
    println!("figure, y {}", (0..13).map(|k| format!("{:4.2}", y(&c, 0.5 * k as f64))).collect::<Vec<_>>().join(" "));
    println!("mistake 1, push taken as 10 not 10/s: y = 5e^(-t) sin 2t, y(0.5) = {:.3} m, settles at 0", 5.0 * (-0.5f64).exp() * 1.0f64.sin());
    println!("mistake 2, no 1/2 on the sine: starting velocity {:.1} m/s, not 0", -c[3] + 2.0 * (x[1] - x[2]));
    println!("mistake 3, (s - 1)^2 + 4 for (s + 1)^2 + 4: y(5) = {:.1} m", y(&[c[0], c[1], c[2], 0.0, 0.0], 5.0) + 5.0f64.exp() * (c[3] * 10.0f64.cos() + (x[1] + x[2]) / 2.0 * 10.0f64.sin()));
    println!("ALL CHECKS PASS");
}
