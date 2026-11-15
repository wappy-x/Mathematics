// Unbounded operators and domains -- the same check as the Python, in Rust.  No crates.
// Space: H = L2(0, 1), real signals on a 1 m bar, <f, g> = integral of f*g.
// Roads: closed forms against Simpson's rule, a Sturm-count eigenvalue search on
// the grid matrix, and an explicit matrix transpose against summation by parts.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for k in 1..m {
        s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    s * h / 3.0
}

fn l2(f: &dyn Fn(f64) -> f64) -> f64 {
    simpson(&|x| f(x).powi(2), 0.0, 1.0, 200000).sqrt()
}

fn close(a: f64, b: f64, tol: f64) {
    assert!((a - b).abs() <= tol * b.abs().max(1.0), "{} {}", a, b);
}

fn count_below(n: usize, x: f64) -> usize {
    let (mut c, mut d) = (0, 2.0 - x);
    for k in 0..n {
        if k > 0 {
            d = 2.0 - x - 1.0 / (if d != 0.0 { d } else { 1e-300 });
        }
        if d < 0.0 {
            c += 1;
        }
    }
    c
}

fn kth_eig(n: usize, k: usize) -> f64 {
    let (mut lo, mut hi) = (0.0f64, 4.0f64);
    for _ in 0..64 {
        let mid = (lo + hi) / 2.0;
        if count_below(n, mid) >= k { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}

fn tent_closed(e: f64) -> (f64, f64) {
    let (s, q) = (1.0 / (2.0 * e), (0.25 + e * e).sqrt());
    let c = q - 0.5;
    let iw = 0.5 * q + e * e * ((0.5 + q) / e).ln() - 0.25;
    let iw2 = 2.0 * e.powf(3.0) * (2.0 * s.powf(3.0) / 3.0 + s - (2.0 / 3.0) * (s * s + 1.0).powf(1.5) + 2.0 / 3.0);
    let d2 = 2.0 * e * (2.0 * s - s.atan() - 2.0 * (1.0 + s * s).sqrt() + 2.0);
    ((c * c - 2.0 * c * iw + iw2).sqrt(), d2.sqrt())
}

fn main() {
    // 1. Differentiation is unbounded: sin(n pi x) keeps size 1/sqrt2, its slope grows like n pi.
    println!("unbounded, n, size of sin(n pi x), size of its derivative, ratio, n pi");
    for n in [1.0f64, 10.0, 100.0, 1000.0] {
        let a = l2(&|x| (n * PI * x).sin());
        let b = l2(&|x| n * PI * (n * PI * x).cos());
        close(a, 1.0 / 2f64.sqrt(), 1e-9);
        close(b / a, n * PI, 1e-9);
        println!("unbounded, {}, {:.6}, {:.6}, {:.6}, {:.6}", n, a, b, b / a, n * PI);
    }
    let (u, du) = (l2(&|x| 10.0 * (PI * x).sin()), l2(&|x| 10.0 * PI * (PI * x).cos()));
    let (r, dr) = (l2(&|x| 0.01 * (1000.0 * PI * x).sin()), l2(&|x| 10.0 * PI * (1000.0 * PI * x).cos()));
    close(dr, du, 1e-9);
    println!("bar, profile 10 sin(pi x): size {:.6} K, gradient size {:.6} K/m", u, du);
    println!("bar, ripple 0.01 sin(1000 pi x): size {:.6} K, gradient size {:.6} K/m", r, dr);

    // 2. The finite rehearsal: forward differences on N cells, ends held at 0.
    //    D_N^T D_N = N^2 tridiag(-1, 2, -1); its eigenvalues found by Sturm counts.
    println!("grid, N, largest gain, closed form, largest/N, smallest gain, closed form");
    let (mut chart_top, mut chart_bot, mut gain10) = (vec![], vec![], 0.0);
    for nn in [10usize, 100, 1000, 10000] {
        let n = nn as f64;
        let top = n * kth_eig(nn - 1, nn - 1).sqrt();
        let bot = n * kth_eig(nn - 1, 1).sqrt();
        let (ct, cb) = (2.0 * n * (PI / (2.0 * n)).cos(), 2.0 * n * (PI / (2.0 * n)).sin());
        close(top, ct, 1e-10);
        close(bot, cb, 1e-8);
        chart_top.push(format!("{:.3}", top.log10()));
        chart_bot.push(format!("{:.3}", bot.log10()));
        println!("grid, {}, {:.6}, {:.6}, {:.6}, {:.6}, {:.6}", nn, top, ct, top / n, bot, cb);
        if nn == 10 {
            gain10 = top;
        }
    }
    println!("chart, log10 N, 1, 2, 3, 4");
    println!("chart, log10 largest gain, {}", chart_top.join(", "));
    println!("chart, log10 smallest gain, {}", chart_bot.join(", "));

    // 3. The grid adjoint: transpose the matrix entry by entry, compare with minus a backward difference.
    let (nn, h) = (10usize, 0.1f64);
    let mut d = vec![vec![0.0f64; nn - 1]; nn]; // row k: (f[k+1] - f[k]) / h, f[0] = f[N] = 0
    for k in 0..nn {
        if k >= 1 {
            d[k][k - 1] = -1.0 / h;
        }
        if k + 2 <= nn {
            d[k][k] = 1.0 / h;
        }
    }
    let f: Vec<f64> = (1..nn).map(|j| (PI * j as f64 * h).sin()).collect();
    let g: Vec<f64> = (0..nn).map(|k| (k as f64 * h + h / 2.0).powi(2)).collect();
    let df: Vec<f64> = (0..nn).map(|k| (0..nn - 1).map(|j| d[k][j] * f[j]).sum()).collect();
    let dtg: Vec<f64> = (0..nn - 1).map(|j| (0..nn).map(|k| d[k][j] * g[k]).sum()).collect();
    for j in 0..nn - 1 {
        close(dtg[j], -(g[j + 1] - g[j]) / h, 1e-12);
    }
    let left = h * df.iter().zip(&g).map(|(a, b)| a * b).sum::<f64>();
    let right = h * f.iter().zip(&dtg).map(|(a, b)| a * b).sum::<f64>();
    close(left, right, 1e-12);
    println!("grid adjoint, N = 10, <D f, g> = {:.6}, <f, D^T g> = {:.6}", left, right);

    // 4. The continuous adjoint, A = d/dx with f(0) = f(1) = 0:  <f', g> = <f, -g'> for any g.
    let lhs = simpson(&|x| PI * (PI * x).cos() * x * x, 0.0, 1.0, 2000);
    let rhs = simpson(&|x| -(PI * x).sin() * 2.0 * x, 0.0, 1.0, 2000);
    close(lhs, -2.0 / PI, 1e-10);
    close(rhs, -2.0 / PI, 1e-10);
    println!("adjoint, f = sin(pi x), g = x^2: <f', g> = {:.6}, <f, -g'> = {:.6}, -2/pi = {:.6}", lhs, rhs, -2.0 / PI);
    let (b1, b2) = (simpson(&|x| x * x, 0.0, 1.0, 2000), simpson(&|x| -x * 2.0 * x, 0.0, 1.0, 2000));
    close(b1 - b2, 1.0, 1e-10);
    println!("boundary, f = x, g = x^2: <f', g> = {:.6}, <f, -g'> = {:.6}, gap = {:.6}, f(1)g(1) - f(0)g(0) = 1", b1, b2, b1 - b2);

    // 5. Is g = 1 in the adjoint's domain when A has no end conditions?  Test f_n = x^n.
    println!("domain test, n, size of x^n, 1/sqrt(2n+1), <f_n', 1>, ratio");
    for n in [1.0f64, 10.0, 100.0, 1000.0] {
        let s = l2(&|x| x.powf(n));
        let p = simpson(&|x| n * x.powf(n - 1.0), 0.0, 1.0, 200000);
        let c = 1.0 / (2.0 * n + 1.0).sqrt();
        close(s, c, 1e-9);
        close(p, 1.0, 1e-9);
        println!("domain test, {}, {:.6}, {:.6}, {:.6}, {:.6}", n, s, c, p, p / s);
    }

    // 6. Closedness: smooth f_eps converge to the tent f(x) = 1/2 - |x - 1/2|, slopes to -sign(x - 1/2).
    println!("closed, eps (m), size of f_eps - f, closed form, size of f_eps' - f', closed form");
    let mut slope_err = 0.0;
    for e in [0.1f64, 0.01, 0.001] {
        let (a, b) = tent_closed(e);
        let q = (0.25 + e * e).sqrt();
        let sa = (2.0 * simpson(&|x| (q - ((x - 0.5f64).powi(2) + e * e).sqrt() - x).powi(2), 0.0, 0.5, 20000)).sqrt();
        let sb = (2.0 * simpson(&|x| ((0.5 - x) / ((x - 0.5f64).powi(2) + e * e).sqrt() - 1.0).powi(2), 0.0, 0.5, 20000)).sqrt();
        close(sa, a, 1e-6 * a);
        close(sb, b, 1e-6 * b);
        println!("closed, {}, {:.8}, {:.8}, {:.6}, {:.6}", e, sa, a, sb, b);
        if e == 0.001 {
            slope_err = b;
        }
    }

    // 7. What breaks.
    println!("breaks, bound from the N = 10 grid: ripple gradient at most {:.6} K/m, really {:.6} K/m", gain10 * r, dr);
    println!("breaks, drop the end conditions of A only: <f', g> = {:.6} but <f, -g'> = {:.6}", b1, b2);
    println!("breaks, forget the minus sign: <f, +g'> = {:.6}, true value {:.6}", -rhs, lhs);
    println!("breaks, stay in C1: slopes f_eps' within {:.6} of a limit that jumps from +1 to -1 at x = 0.5", slope_err);
    assert!(gain10 * r < dr / 100.0);
    println!("ALL CHECKS PASS");
}
