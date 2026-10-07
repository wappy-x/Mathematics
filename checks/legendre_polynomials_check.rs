// Legendre polynomials -- the same check as the Python, in Rust.  No crates.
// Legendre's equation: (1 - x^2) y'' - 2x y' + n(n+1) y = 0.  Road one: the
// power series, which stops at x^n when n is whole.  Road two: Bonnet's rule,
// no series.  Orthogonality: exact from coefficients, and by Simpson's rule.
// The sphere: radius 10 cm, surface held at 30 cos^2(theta) volts.
fn series(n: f64, start: usize, terms: usize) -> Vec<f64> {   // a_(k+2) = (k - n)(k + n + 1) / ((k + 1)(k + 2)) a_k
    let (mut a, mut k) = ([vec![0.0; start], vec![1.0]].concat(), start);
    while k + 2 < terms {
        let kf = k as f64;
        let next = (kf - n) * (kf + n + 1.0) / ((kf + 1.0) * (kf + 2.0)) * a[k];
        a.push(0.0); a.push(next); k += 2;
    }
    a
}
fn p(n: usize) -> Vec<f64> {            // the series of n's parity, cut at x^n, scaled so P_n(1) = 1
    let a = series(n as f64, n % 2, n + 1);
    let s: f64 = a.iter().sum();
    a.iter().take(n + 1).map(|v| v / s + 0.0).collect()
}
fn bonnet(n: usize) -> Vec<f64> {       // (m + 1) P_(m+1) = (2m + 1) x P_m - m P_(m-1)
    let (mut p0, mut q) = (vec![1.0], vec![0.0, 1.0]);
    for m in 1..n {
        let mf = m as f64;
        let r: Vec<f64> = (0..m + 2).map(|i| ((2.0 * mf + 1.0) * (if i > 0 { q[i - 1] } else { 0.0 }) - mf * p0.get(i).copied().unwrap_or(0.0)) / (mf + 1.0)).collect();
        p0 = q; q = r;
    }
    if n == 0 { p0 } else { q }
}
fn ev(c: &[f64], x: f64) -> f64 { c.iter().enumerate().map(|(k, v)| v * x.powi(k as i32)).sum() }
fn mul(a: &[f64], b: &[f64]) -> Vec<f64> {
    let mut r = vec![0.0; a.len() + b.len() - 1];
    for i in 0..a.len() { for j in 0..b.len() { r[i + j] += a[i] * b[j]; } }
    r
}
fn exact(c: &[f64]) -> f64 { c.iter().enumerate().filter(|(k, _)| k % 2 == 0).map(|(k, v)| 2.0 * v / (k as f64 + 1.0)).sum() }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (m, h) = (2000, (b - a) / 2000.0);
    h / 3.0 * (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum::<f64>()
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let ps: Vec<Vec<f64>> = (0..5).map(p).collect();
    println!("before scaling, value at x = 1 for n = 2, 3, 4: {} ; n = 2 coefficients: {}", join(&[2usize, 3, 4].map(|n| series(n as f64, n % 2, n + 1).iter().sum()), 4), join(&series(2.0, 0, 3), 4));
    for n in 2..5 { println!("P{}, series, coefficients of x^0..x^{}: {}", n, n, join(&ps[n], 4)); }
    let gap = (0..5).flat_map(|n| ps[n].iter().zip(bonnet(n)).map(|(a, b)| (a - b).abs()).collect::<Vec<_>>()).fold(0.0, f64::max);
    println!("largest gap, series against Bonnet, P0..P4: {:.1e}", gap);
    let g = |m: usize, n: usize| exact(&mul(&ps[m], &ps[n]));
    let s = |m: usize, n: usize| simpson(&|x| ev(&ps[m], x) * ev(&ps[n], x), -1.0, 1.0);
    let diag: Vec<f64> = (0..5).map(|n| g(n, n)).collect();
    let norm: Vec<f64> = (0..5).map(|n| 2.0 / (2.0 * n as f64 + 1.0)).collect();
    println!("integral of P_n^2, exact: {} ; 2/(2n+1): {}", join(&diag, 4), join(&norm, 4));
    let off = (0..25).filter(|i| i / 5 != i % 5).map(|i| s(i / 5, i % 5).abs()).fold(0.0, f64::max);
    println!("integral of P1 P2: exact {:.6}, Simpson {:.6}; largest m != n, Simpson: {:.1e}", g(1, 2), s(1, 2) + 0.0, off);
    let mut errs = Vec::new();
    for big_n in [100usize, 200, 400] {  // Euler's rule on the equation, n = 2, from x = 0 to 0.5
        let (mut x, mut y, mut v, h) = (0.0f64, -0.5f64, 0.0f64, 0.5 / big_n as f64);
        for _ in 0..big_n { let v2 = v + h * (2.0 * x * v - 6.0 * y) / (1.0 - x * x); y += h * v; v = v2; x += h; }
        errs.push(y - ev(&ps[2], 0.5));
    }
    println!("Euler to x = 0.5, n = 2, 100/200/400 steps: errors {:+.5} {:+.5} {:+.5}; P2(0.5) = {:.4}", errs[0], errs[1], errs[2], ev(&ps[2], 0.5));
    let c: Vec<f64> = (0..5).map(|n| (2.0 * n as f64 + 1.0) / 2.0 * exact(&mul(&[0.0, 0.0, 30.0], &ps[n])) + 0.0).collect();
    let cs: Vec<f64> = (0..5).map(|n| (2.0 * n as f64 + 1.0) / 2.0 * simpson(&|x| 30.0 * x * x * ev(&ps[n], x), -1.0, 1.0)).collect();
    let cgap = c.iter().zip(&cs).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("sphere, c0..c4 in volts, exact: {} ; Simpson gap {:.1e}", join(&c, 4), cgap);
    let avg = simpson(&|t: f64| 30.0 * t.cos().powi(2) * t.sin() / 2.0, 0.0, std::f64::consts::PI);
    let pot = |r: f64, ct: f64| (0..5).map(|n| c[n] * (r / 0.1).powi(n as i32) * ev(&ps[n], ct)).sum::<f64>();
    println!("potential: centre {:.2} V, surface average {:.4} V; 5 cm, on the axis {:.2} V, at the equator {:.2} V", pot(0.0, 1.0), avg, pot(0.05, 1.0), pot(0.05, 0.0));
    let half: Vec<f64> = [11usize, 101, 1001].iter().map(|&t| series(0.5, 0, t).iter().sum()).collect();
    println!("mistake, n = 0.5, series at x = 1 up to x^10, x^100, x^1000: {}", join(&half, 4));
    println!("mistake, weight (1 - x^2): integral of P0 P2 = {:.4}; dropping (2n+1)/2: centre {:.2} V", exact(&mul(&[1.0, 0.0, -1.0], &ps[2])), 2.0 * c[0]);
    let xs: Vec<f64> = (0..11).map(|i| (i as f64 - 5.0) / 5.0).collect();
    let rows: [(&str, Box<dyn Fn(f64) -> f64>); 3] = [("P1", Box::new(|x| ev(&ps[1], x))), ("P2", Box::new(|x| ev(&ps[2], x))), ("P1 P2", Box::new(|x| ev(&ps[1], x) * ev(&ps[2], x)))];
    for (lab, f) in rows.iter() { println!("figure, {} at x = -1, -0.8, ..., 1: {}", lab, join(&xs.iter().map(|&x| f(x) + 0.0).collect::<Vec<_>>(), 2)); }
    assert!(gap < 1e-12 && (0..5).all(|n| (s(n, n) - norm[n]).abs() < 1e-9) && off < 1e-9);
    assert!(errs[2].abs() < 0.005 && 1.8 < errs[0] / errs[1] && errs[0] / errs[1] < 2.2 && 1.8 < errs[1] / errs[2] && errs[1] / errs[2] < 2.2);
    assert!((c[0] - avg).abs() < 1e-9 && cgap < 1e-8);
    assert!(half[1] - half[2] > 0.5 && half[0] - half[1] > 0.5);
    println!("ALL CHECKS PASS");
}
