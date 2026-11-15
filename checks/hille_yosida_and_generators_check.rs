// Hille-Yosida and generators -- the check behind the card.  Rust std only.
// Bar: 1 m, ends held at 0 K rise, H = L2(0, 1).  A = kappa d^2/dx^2 on H^2 with zero ends.
// Roads: closed forms on sine modes, a Green's-function integral by Simpson's rule,
// tridiagonal solves on an N-cell grid, power iteration for norms, Yosida's series.
use std::f64::consts::PI;

const KAPPA: f64 = 1.11e-4; // m^2/s, copper's thermal diffusivity (illustrative)
const T: f64 = 600.0; // s
const LAM: f64 = 0.01; // 1/s

// (lam I - A_N) u = f on the N - 1 inside points; Thomas algorithm.
fn solve(lam: f64, f: &[f64], n_cells: usize) -> Vec<f64> {
    let h2 = (1.0 / n_cells as f64).powi(2);
    let (a, b) = (-KAPPA / h2, lam + 2.0 * KAPPA / h2);
    let n = f.len();
    let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);
    for i in 0..n {
        let m = b - if i > 0 { a * c[i - 1] } else { 0.0 };
        c[i] = a / m;
        d[i] = (f[i] - if i > 0 { a * d[i - 1] } else { 0.0 }) / m;
    }
    for i in (0..n - 1).rev() { d[i] -= c[i] * d[i + 1]; }
    d
}

fn dot(v: &[f64], w: &[f64]) -> f64 { v.iter().zip(w).map(|(x, y)| x * y).sum() }

// Largest eigenvalue of the symmetric resolvent matrix = its operator norm.
fn power_norm(lam: f64, n: usize, its: usize) -> f64 {
    let mut v = vec![1.0; n - 1];
    let mut r = 0.0;
    for _ in 0..its {
        let w = solve(lam, &v, n);
        r = dot(&v, &w) / dot(&v, &v);
        let s = dot(&w, &w).sqrt();
        v = w.iter().map(|x| x / s).collect();
    }
    r
}

// Largest eigenvalue of -A_N by Sturm bisection: the LDL^T pivots of -A_N - x I
// that are negative count the eigenvalues below x.  No eigenvalue formula used.
fn top_eig(nb: usize) -> f64 {
    let (d, e2) = (2.0 * KAPPA * (nb * nb) as f64, (KAPPA * (nb * nb) as f64).powi(2));
    let below = |x: f64| {
        let (mut c, mut q) = (0, 1.0);
        for i in 0..nb - 1 { q = d - x - if i > 0 { e2 / q } else { 0.0 }; if q == 0.0 { q = 1e-300; } if q < 0.0 { c += 1; } }
        c
    };
    let (mut lo, mut hi) = (0.0, 2.0 * d);
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if below(mid) == nb - 1 { hi = mid; } else { lo = mid; } }
    (lo + hi) / 2.0
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (m, h) = (2000, (b - a) / 2000.0);
    let s: f64 = (1..m).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h)).sum();
    (f(a) + f(b) + s) * h / 3.0
}

fn check(ok: &mut Vec<bool>, name: &str, got: f64, want: f64, tol: f64) {
    ok.push((got - want).abs() <= tol);
    assert!(*ok.last().unwrap(), "{} {} {}", name, got, want);
}

fn main() {
    let mu1 = KAPPA * PI.powi(2); // decay rate of the arch sin(pi x), 1/s
    let mut ok: Vec<bool> = Vec::new();
    println!("setup, kappa = 1.11e-4 m^2/s, arch decay rate kappa pi^2 = {:.8} 1/s, lambda = 0.01 1/s", mu1);
    // 1. The resolvent test on the grid, at several N.
    println!("test, N, ||R(lambda, A_N)|| by power iteration (s), closed form (s), bar limit 1/(lambda + kappa pi^2) (s), bound 1/lambda (s)");
    let mut cf = 0.0;
    for &n in &[10usize, 100, 1000] {
        let pw = power_norm(LAM, n, 400);
        let nf = n as f64;
        cf = 1.0 / (LAM + 4.0 * KAPPA * nf * nf * (PI / (2.0 * nf)).sin().powi(2));
        println!("test, {}, {:.4}, {:.4}, {:.4}, {:.4}", n, pw, cf, 1.0 / (LAM + mu1), 1.0 / LAM);
        check(&mut ok, "power", pw, cf, 1e-6);
        assert!(pw <= 1.0 / LAM);
    }
    check(&mut ok, "bar limit", cf, 1.0 / (LAM + mu1), 1e-3);
    // 2. The true resolvent through its Green's function, against modes and grid.
    let m = (LAM / KAPPA).sqrt();
    println!("green, m = sqrt(lambda / kappa) = {:.6} 1/m", m);
    let g = |x: f64, s: f64| {
        let (lo, hi) = (x.min(s), x.max(s));
        (m * lo).sinh() * (m * (1.0 - hi)).sinh() / (KAPPA * m * m.sinh())
    };
    let arch = |s: f64| 10.0 * (PI * s).sin();
    let green = LAM * (simpson(&|s| g(0.5, s) * arch(s), 0.0, 0.5) + simpson(&|s| g(0.5, s) * arch(s), 0.5, 1.0));
    let mode = 10.0 * LAM / (LAM + mu1);
    let n = 1000usize;
    let xs: Vec<f64> = (1..n).map(|j| j as f64 / n as f64).collect();
    let a0: Vec<f64> = xs.iter().map(|&x| arch(x)).collect();
    let grid = LAM * solve(LAM, &a0, n)[n / 2 - 1];
    println!("discounted arch, midpoint of lambda R u0: Green {:.6} K, mode {:.6} K, grid N=1000 {:.6} K", green, mode, grid);
    check(&mut ok, "green", green, mode, 1e-8);
    check(&mut ok, "grid", grid, mode, 1e-5);
    let u: Vec<f64> = solve(LAM, &vec![1.0; n - 1], n).iter().map(|y| LAM * y).collect();
    let flat = |x: f64| 1.0 - (m * (x - 0.5)).cosh() / (m / 2.0).cosh();
    let flat_norm = simpson(&|x| flat(x).powi(2), 0.0, 1.0).sqrt();
    println!("discounted flat 1 K source: ||lambda R f|| closed form {:.6} K, grid {:.6} K, ||f|| = 1 K", flat_norm, (dot(&u, &u) / n as f64).sqrt());
    check(&mut ok, "flat", (dot(&u, &u) / n as f64).sqrt(), flat_norm, 1e-3);
    assert!(flat_norm <= 1.0);
    let energy = |x: f64| (m * (x - 0.5)).sinh() * m / (m / 2.0).cosh();
    let lhs = flat_norm.powi(2) + KAPPA * simpson(&|x| energy(x).powi(2), 0.0, 1.0) / LAM;
    let fu = simpson(&flat, 0.0, 1.0);
    println!("energy identity, w = lambda R f: ||w||^2 + (kappa/lambda) ||w'||^2 = {:.6}, <f, w> = {:.6}", lhs, fu);
    check(&mut ok, "energy", lhs, fu, 1e-9);
    // 3. Recover the semigroup: implicit Euler (n steps) and Yosida's approximation.
    let exact = 10.0 * (-mu1 * T).exp();
    println!("hand, pi^2 = {:.6}, lambda + kappa pi^2 = {:.8} 1/s, a = kappa pi^2 t = {:.6}, one step factor at n = 10: {:.6}, e^(-a) = {:.7}", PI * PI, LAM + mu1, mu1 * T, 1.0 / (1.0 + mu1 * T / 10.0), (-mu1 * T).exp());
    println!("exact, midpoint after {:.0} s: 10 exp(-kappa pi^2 t) = {:.6} K", T, exact);
    println!("euler, n, mode formula (K), grid N=1000 (K), error (K), n * error");
    let mut errs = Vec::new();
    for &steps in &[1usize, 10, 100, 1000] {
        let sf = steps as f64;
        let mf = 10.0 * (1.0 + mu1 * T / sf).powf(-sf);
        let mut v = a0.clone();
        for _ in 0..steps {
            v = solve(sf / T, &v, n).iter().map(|y| (sf / T) * y).collect();
        }
        errs.push(mf - exact);
        println!("euler, {}, {:.6}, {:.6}, {:.6}, {:.6}", steps, mf, v[n / 2 - 1], mf - exact, sf * (mf - exact));
        check(&mut ok, "euler grid", v[n / 2 - 1], mf, 1e-3);
    }
    let lim = 10.0 * (-mu1 * T).exp() * (mu1 * T).powi(2) / 2.0;
    println!("euler, limit of n * error = 10 e^(-a) a^2 / 2 with a = kappa pi^2 t: {:.6}", lim);
    check(&mut ok, "rate", 1000.0 * errs[3], lim, 2e-3);
    println!("chart, log10 n, 0, 1, 2, 3");
    let ch: Vec<String> = errs.iter().map(|e| format!("{:.3}", e.log10())).collect();
    println!("chart, log10 error, {}", ch.join(", "));
    println!("yosida, lambda (1/s), mode formula (K), grid N=200 series (K), error (K)");
    let n2 = 200usize;
    let a2: Vec<f64> = (1..n2).map(|j| arch(j as f64 / n2 as f64)).collect();
    for &lam in &[0.01f64, 0.1, 1.0] {
        let mf = 10.0 * (-T * lam * mu1 / (lam + mu1)).exp();
        let mut v = a2.clone();
        let mut acc = vec![0.0; v.len()];
        let mut w = (-lam * T).exp();
        let terms = (lam * T + 12.0 * (lam * T).sqrt() + 20.0) as usize;
        for k in 0..terms {
            for (p, q) in acc.iter_mut().zip(&v) {
                *p += w * q;
            }
            v = solve(lam, &v, n2).iter().map(|y| lam * y).collect();
            w *= lam * T / (k as f64 + 1.0);
        }
        println!("yosida, {:.2}, {:.6}, {:.6}, {:.6}", lam, mf, acc[n2 / 2 - 1], mf - exact);
        check(&mut ok, "yosida", acc[n2 / 2 - 1], mf, 5e-4);
    }
    // 4. What breaks.
    println!("backward, N, top growth rate of -A_N by Sturm bisection (1/s), closed form 4 kappa N^2 sin^2((N-1) pi/(2N)) (1/s), row-sum bound 4 kappa N^2 (1/s)");
    for &nb in &[10usize, 100, 1000] {
        let nf = nb as f64;
        let (st, w) = (top_eig(nb), 4.0 * KAPPA * nf * nf * ((nf - 1.0) * PI / (2.0 * nf)).sin().powi(2));
        println!("backward, {}, {:.4}, {:.4}, {:.4}", nb, st, w, 4.0 * KAPPA * nf * nf);
        check(&mut ok, "sturm", st, w, 1e-6);
    }
    let bk = (1..50).map(|k| 1.0 / (LAM - mu1 * k as f64 * k as f64).abs()).fold(0.0, f64::max);
    println!("breaks, backward heat at lambda = 0.01: ||R(lambda, -A)|| = {:.1} s against the bound 1/lambda = 100 s (mode n = 3, kappa pi^2 9 = {:.8} 1/s)", bk, 9.0 * mu1);
    assert!(bk > 1.0 / LAM);
    let dt = T / 10.0;
    let wn = 4.0 * KAPPA * 100.0 * 100.0 * (99.0 * PI / 200.0).sin().powi(2);
    println!("breaks, explicit Euler, N=100, 10 steps of {:.0} s: worst mode factor per step {:.4}, after 10 steps 10^{:.2}, stable only for steps up to h^2/(2 kappa) = {:.4} s", dt, 1.0 - dt * wn, 10.0 * (1.0 - dt * wn).abs().log10(), 0.0001 / (2.0 * KAPPA));
    println!("breaks, one implicit step: {:.6} K against {:.6} K", 10.0 / (1.0 + mu1 * T), exact);
    println!("breaks, Yosida with lambda = 0.01: {:.6} K against {:.6} K", 10.0 * (-T * 0.01 * mu1 / (0.01 + mu1)).exp(), exact);
    println!("ALL CHECKS PASS");
}
