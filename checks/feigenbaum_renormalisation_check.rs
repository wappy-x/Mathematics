// Feigenbaum renormalisation -- the same check as the Python, in Rust.  No crates.
// Road one: three one-hump maps, superstable dials found by Newton in the dial.
// Road two: the doubling operator T g(x) = -alpha g(g(-x/alpha)), its fixed point by Newton.
fn g(c: &[f64], x: f64) -> f64 {             // g(x) = 1 + c1 x^2 + c2 x^4 + ...
    1.0 + c.iter().enumerate().map(|(j, cj)| cj * x.powf((2 * j + 2) as f64)).sum::<f64>() }
fn t(c: &[f64], x: f64) -> f64 { let a = -1.0 / g(c, 1.0); -a * g(c, g(c, -x / a)) }   // the doubling operator
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> {   // Gaussian elimination with row swaps
    let n = b.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for k in 0..n {
        let p = (k..n).fold(k, |p, i| if m[i][k].abs() > m[p][k].abs() { i } else { p }); m.swap(k, p);
        for i in k + 1..n { let f = m[i][k] / m[k][k]; for j in 0..=n { m[i][j] -= f * m[k][j] } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - (i + 1..n).map(|j| m[i][j] * x[j]).sum::<f64>()) / m[i][i] }
    x
}
fn jac(f: &dyn Fn(&[f64]) -> Vec<f64>, c: &[f64], h: f64) -> (Vec<f64>, Vec<Vec<f64>>) {
    let f0 = f(c);                           // F at c, and its slopes by small nudges
    let cols: Vec<Vec<f64>> = (0..c.len()).map(|j| { let mut d = c.to_vec(); d[j] += h; f(&d) }).collect();
    let jm = (0..c.len()).map(|i| (0..c.len()).map(|j| (cols[j][i] - f0[i]) / h).collect()).collect();
    (f0, jm)
}
fn fixed_point(n: usize) -> (Vec<f64>, f64, f64) {   // Newton: g = T g at x = 1/N, ..., 1
    let xs: Vec<f64> = (0..n).map(|i| (i + 1) as f64 / n as f64).collect();
    let mut c: Vec<f64> = [-1.5, 0.1].iter().copied().chain(std::iter::repeat(0.0)).take(n).collect();
    for _ in 0..30 {
        let (f0, jm) = jac(&|c: &[f64]| xs.iter().map(|&x| g(c, x) - t(c, x)).collect(), &c, 1e-7);
        let step = solve(&jm, &f0.iter().map(|v| -v).collect::<Vec<f64>>());
        c = c.iter().zip(&step).map(|(u, v)| u + v).collect();
    }
    let vm: Vec<Vec<f64>> = xs.iter().map(|&x| (0..n).map(|j| x.powf((2 * j + 2) as f64)).collect()).collect();
    let (_, jm) = jac(&|c: &[f64]| solve(&vm, &xs.iter().map(|&x| t(c, x) - 1.0).collect::<Vec<f64>>()), &c, 1e-6);
    let big = |v: &[f64]| v.iter().copied().fold(0.0f64, |m, x| if x.abs() > m.abs() { x } else { m });
    let (mut v, mut lam) = (vec![1.0; n], 0.0);
    for _ in 0..200 {                        // power iteration: T's largest stretch near g
        let w: Vec<f64> = (0..n).map(|i| (0..n).map(|j| jm[i][j] * v[j]).sum()).collect();
        lam = big(&w) / big(&v); v = w.iter().map(|u| u / big(&w)).collect();
    }
    let a = -1.0 / g(&c, 1.0); (c, a, lam)
}
fn orbit(f: &dyn Fn(f64, f64) -> f64, r: f64, p: usize) -> f64 { (0..p).fold(0.5, |x, _| f(r, x)) }
fn superstable(f: &dyn Fn(f64, f64) -> f64, p: usize, mut r: f64) -> f64 {   // Newton in r
    let gg = |r: f64| orbit(f, r, p) - 0.5;
    for _ in 0..40 { let h = 1e-9 * r.abs().max(1.0); r -= gg(r) * 2.0 * h / (gg(r + h) - gg(r - h)) }
    r
}
fn fm(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let maps: [(&str, Box<dyn Fn(f64, f64) -> f64>, f64, f64); 3] = [
        ("logistic r x (1 - x)", Box::new(|r, x| r * x * (1.0 - x)), 2.0, 3.2),
        ("sine r sin(pi x)", Box::new(|r, x| r * (std::f64::consts::PI * x).sin()), 0.5, 0.78),
        ("flat top r (1 - (2x - 1)^4)", Box::new(|r, x| r * (1.0 - (2.0 * x - 1.0).powf(4.0))), 0.5, 0.915)];
    let mut out = Vec::new();
    for (name, f, a0, a1) in maps.iter() {
        let mut rr = vec![superstable(f.as_ref(), 1, *a0), superstable(f.as_ref(), 2, *a1)];
        for k in 2..9 {                      // guess: the last gap shrunk by the last ratio
            let n = rr.len();
            let ratio = if k == 2 { 6.0 } else { (rr[n - 2] - rr[n - 3]) / (rr[n - 1] - rr[n - 2]) };
            rr.push(superstable(f.as_ref(), 1 << k, rr[n - 1] + (rr[n - 1] - rr[n - 2]) / ratio));
        }
        let d: Vec<f64> = (1..9).map(|k| orbit(f.as_ref(), rr[k], 1 << (k - 1)) - 0.5).collect();
        let dr: Vec<f64> = (1..8).map(|i| (rr[i] - rr[i - 1]) / (rr[i + 1] - rr[i])).collect();
        let ar: Vec<f64> = (0..7).map(|i| d[i] / d[i + 1]).collect();
        println!("{}, superstable dials: {}\n  gap ratios: {}\n  window ratios: {}", name, fm(&rr, 6), fm(&dr, 4), fm(&ar, 4));
        out.push((rr, dr, ar, d));
    }
    let (rl, dl, al, d) = (&out[0].0, &out[0].1, &out[0].2, &out[0].3);
    println!("logistic by hand: 1 + sqrt(5) = {:.6}; gaps {}; windows {}", 1.0 + 5f64.sqrt(), fm(&(0..3).map(|i| rl[i + 1] - rl[i]).collect::<Vec<f64>>(), 6), fm(&d[..2], 6));
    let (mut alpha, mut delta) = (0.0, 0.0);
    for n in [1, 2, 4, 8] {
        let (c, a, l) = fixed_point(n); (alpha, delta) = (a, l); println!("fixed point of T, N = {}: alpha {:.6}, delta {:.6}, c = {}", n, a, l, fm(&c[..c.len().min(3)], 6));
    }
    assert!((rl[1] - (1.0 + 5f64.sqrt())).abs() < 1e-12);                       // Newton against the closed form
    assert!((alpha + al[6]).abs() < 1e-4 && (alpha + out[1].2[6]).abs() < 1e-4);    // operator against two maps
    assert!((delta - dl[6]).abs() < 1e-4 && (delta - out[1].1[6]).abs() < 1e-4);     // eigenvalue against two maps
    assert!(out[2].1[6] > 7.0 && out[2].2[6].abs() < 2.0);                                   // flat top: another family
    println!("ALL CHECKS PASS");
}
