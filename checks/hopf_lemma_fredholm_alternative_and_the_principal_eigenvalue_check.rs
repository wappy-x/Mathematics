// L u = -u'' + 2u' on (0, 1), u(0) = u(1) = 0 (scaled): the principal eigenvalue, Hopf's slopes, Fredholm.
// Roads: closed forms; shooting by RK4 with bisection; a finite-difference grid with inverse iteration;
// Simpson integrals; centred-difference residuals.  std only.
use std::f64::consts::{E, PI};

fn phi(x: f64) -> f64 { x.exp() * (PI * x).sin() } // L's first mode
fn phs(x: f64) -> f64 { (-x).exp() * (PI * x).sin() } // the adjoint's first mode

// -u''+2u'-lam u = f + point sources; u(0)=0, u'(0)=A; returns u(1), u'(1), inside min and max
fn shoot(lam: f64, a: f64, f: f64, kicks: &[(usize, f64)]) -> (f64, f64, f64, f64) {
    let n = 4000usize; let h = 1.0 / n as f64;
    let (mut u, mut p, mut lo, mut hi) = (0.0f64, a, f64::INFINITY, f64::NEG_INFINITY);
    let rhs = |u: f64, p: f64| (p, 2.0 * p - lam * u - f);
    for i in 0..n {
        for &(j, s) in kicks { if j == i { p -= s; } } // a source of size s makes the slope drop by s
        let k1 = rhs(u, p); let k2 = rhs(u + h / 2.0 * k1.0, p + h / 2.0 * k1.1);
        let k3 = rhs(u + h / 2.0 * k2.0, p + h / 2.0 * k2.1); let k4 = rhs(u + h * k3.0, p + h * k3.1);
        u += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        p += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        if i < n - 1 { lo = lo.min(u); hi = hi.max(u); } // inside points only
    }
    (u, p, lo, hi)
}

fn bisect(g: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 {
    for _ in 0..60 {
        let m = (a + b) / 2.0;
        if g(a) * g(m) <= 0.0 { b = m; } else { a = m; }
    }
    (a + b) / 2.0
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 2000; let h = (b - a) / n as f64; let mut s = 0.0;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}

fn thomas(lo: &[f64], di: &[f64], up: &[f64], r: &[f64]) -> Vec<f64> {
    let n = di.len(); let mut d = di.to_vec(); let mut r = r.to_vec();
    for i in 1..n { let m = lo[i] / d[i - 1]; d[i] -= m * up[i - 1]; r[i] -= m * r[i - 1]; }
    let mut x = vec![0.0; n]; x[n - 1] = r[n - 1] / d[n - 1];
    for i in (0..n - 1).rev() { x[i] = (r[i] - up[i] * x[i + 1]) / d[i]; }
    x
}

// centred differences for -u''+2u'-lam u on the N-1 inside points
fn grid(nn: usize, lam: f64) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let h = 1.0 / nn as f64;
    (vec![-1.0 / (h * h) - 1.0 / h; nn - 1], vec![2.0 / (h * h) - lam; nn - 1], vec![-1.0 / (h * h) + 1.0 / h; nn - 1])
}

fn maxabs(v: &[f64]) -> f64 { v.iter().fold(0.0f64, |m, t| m.max(t.abs())) }

fn grid_eig(nn: usize) -> (f64, Vec<f64>) { // inverse iteration: the eigenvalue of smallest size and its vector
    let (lo, di, up) = grid(nn, 0.0); let mut v = vec![1.0; nn - 1];
    for _ in 0..80 { let w = thomas(&lo, &di, &up, &v); let s = maxabs(&w); v = w.iter().map(|t| t / s).collect(); }
    let av: Vec<f64> = (0..nn - 1).map(|i| di[i] * v[i] + if i > 0 { lo[i] * v[i - 1] } else { 0.0 }
        + if i < nn - 2 { up[i] * v[i + 1] } else { 0.0 }).collect();
    let (mut num, mut den) = (0.0, 0.0);
    for i in 0..nn - 1 { num += v[i] * av[i]; }
    for i in 0..nn - 1 { den += v[i] * v[i]; }
    (num / den, v)
}

fn hres(g: fn(f64) -> f64, l: f64, s: f64, h: f64) -> f64 {
    let mut m = 0.0f64;
    for i in 1..10 {
        let x = 0.1 * i as f64;
        m = m.max((-(g(x + h) - 2.0 * g(x) + g(x - h)) / (h * h) + s * (g(x + h) - g(x - h)) / h - l * g(x)).abs());
    }
    m
}

fn row(v: &[f64], f: impl Fn(f64) -> String, sep: &str) -> String { v.iter().map(|&t| f(t)).collect::<Vec<_>>().join(sep) }

fn main() {
    let lam: Vec<f64> = [1.0, 2.0, 3.0].iter().map(|k: &f64| k * k * PI * PI + 1.0).collect();
    let sh: Vec<f64> = [(5.0, 15.0), (35.0, 45.0), (85.0, 95.0)].iter()
        .map(|&(a, b)| bisect(&|l| shoot(l, 1.0, 0.0, &[]).0, a, b)).collect();
    println!("eigenvalues k^2 pi^2 + 1:  {}", row(&lam, |t| format!("{:.6}", t), "  "));
    println!("by shooting (RK4, bisect): {}", row(&sh, |t| format!("{:.6}", t), "  "));
    for i in 0..3 { assert!((lam[i] - sh[i]).abs() < 1e-6); } // closed form against shooting
    let (l50, _) = grid_eig(50); let (l100, _) = grid_eig(100); let (l200, v200) = grid_eig(200);
    println!("grid lambda_1, N = 50/100/200: {:.6} {:.6} {:.6}; order {:.3}; Richardson {:.6}",
        l50, l100, l200, ((l50 - l100) / (l100 - l200)).log2(), (4.0 * l200 - l100) / 3.0);
    assert!(((4.0 * l200 - l100) / 3.0 - lam[0]).abs() < 1e-6 && v200.iter().all(|&t| t > 0.0)); // grid agrees; mode positive
    println!("grid mode at N = 200: smallest entry {:.6} > 0, sign changes 0", v200.iter().cloned().fold(f64::INFINITY, f64::min));
    println!("drift-free -u'': pi^2 = {:.6}; drift adds b^2/4 = {:.6}", PI * PI, lam[0] - PI * PI);
    println!("population: T = 100 days, threshold {:.5} per day, without drift {:.5} per day; the current adds {:.4}", lam[0] / 100.0, PI * PI / 100.0, (lam[0] - PI * PI) / 100.0);
    let (xp, xs) = (1.0 - PI.atan() / PI, PI.atan() / PI);
    let xpb = bisect(&|x: f64| (PI * x).sin() + PI * (PI * x).cos(), 0.3, 0.9);
    println!("peaks: mode at x = {:.4} (bisection {:.4}), height {:.4}; adjoint at x = {:.4}, height {:.4}", xp, xpb, phi(xp), xs, phs(xs));
    assert!((xp - xpb).abs() < 1e-9);
    println!("release at {:.4} km instead of 0.25 km: value {:.4} against {:.4}, ratio {:.4}", xs, phs(xs), phs(0.25), phs(xs) / phs(0.25));
    let (r1, r2, r3) = (hres(phi, lam[0], 1.0, 1e-2), hres(phi, lam[0], 1.0, 5e-3), hres(phs, lam[0], -1.0, 5e-3));
    println!("residual of L phi - lambda_1 phi: h = 0.01 {:.6}, h = 0.005 {:.6}, ratio {:.2}; of L* phi* - lambda_1 phi*: {:.6}", r1, r2, r1 / r2, r3);
    assert!(r1 / r2 > 3.9 && r3 < 1e-3);
    let pr = shoot(lam[0], PI, 0.0, &[]).1;
    println!("Hopf slopes: phi'(0) = pi = {:.4}; phi'(1) = -e pi = {:.4}, shooting {:.4}", PI, -E * PI, pr);
    println!("share of losses out the downstream end e/(1 + e) = {:.4}", E / (1.0 + E));
    let i1 = simpson(&phi, 0.0, 1.0);
    println!("births = losses: lambda_1 * int phi = {:.6}, phi'(0) - phi'(1) = pi (1 + e) = {:.6}", lam[0] * i1, PI * (1.0 + E));
    assert!((pr + E * PI).abs() < 1e-6 && (lam[0] * i1 - PI * (1.0 + E)).abs() < 1e-9);
    let j = simpson(&phs, 0.0, 1.0); let jc = PI * (1.0 + 1.0 / E) / (PI * PI + 1.0);
    println!("Fredholm test for f = 1: int f phi* = {:.6} (closed form {:.6}), not 0: no steady state", j, jc);
    let ends = [shoot(lam[0], 0.0, 1.0, &[]).0, shoot(lam[0], 5.0, 1.0, &[]).0];
    println!("shooting f = 1 at lambda_1: u(1) = {:.6} with u'(0) = 0, {:.6} with u'(0) = 5; formula -(e/pi) int phi* = {:.6}", ends[0], ends[1], -E / PI * jc);
    assert!((j - jc).abs() < 1e-12 && ends.iter().all(|t| (t + E / PI * jc).abs() < 1e-8));
    let big: Vec<f64> = [50usize, 100, 200].iter().map(|&nn| { let (lo, di, up) = grid(nn, lam[0]); maxabs(&thomas(&lo, &di, &up, &vec![1.0; nn - 1])) }).collect();
    println!("grid 'solution' of f = 1 at lambda_1, largest |u|, N = 50/100/200: {}", row(&big, |t| format!("{:.1}", t), " "));
    assert!(big[2] / big[1] > 3.5 && big[1] / big[0] > 3.5); // grows like 1/h^2: no limit
    let m = phs(0.25) / phs(0.75); // the amount to remove at x = 0.75
    println!("release 1 at x = 0.25, remove m at x = 0.75: phi*(0.25) = {:.4}, phi*(0.75) = {:.4}, m = {:.4} = e^0.5 {:.4}", phs(0.25), phs(0.75), m, 0.5f64.exp());
    let (kb, ku) = ([(1000usize, 1.0), (3000, -m)], [(1000usize, 1.0), (3000, -1.0)]); // a source +1 and a sink at x = 0.75
    let ub = [shoot(lam[0], 0.0, 0.0, &kb).0, shoot(lam[0], 1.0, 0.0, &kb).0]; let uu = shoot(lam[0], 0.0, 0.0, &ku).0;
    println!("shooting, balanced: |u(1)| = {:.12} and {:.12} for u'(0) = 0, 1; unbalanced m = 1: u(1) = {:.6}, formula {:.6}", ub[0].abs(), ub[1].abs(), uu, -E / PI * (phs(0.25) - phs(0.75)));
    assert!((m - 0.5f64.exp()).abs() < 1e-12 && maxabs(&ub) < 1e-9 && (uu + E / PI * (phs(0.25) - phs(0.75))).abs() < 1e-9);
    println!("wrong test with L's own mode: phi(0.25) - m phi(0.75) = {:.4}", phi(0.25) - m * phi(0.75));
    for &l in &[10.0f64, 10.8, 12.0] { // f = 1 below and above lambda_1: Fredholm says one solution each; only one is positive
        let (u0, u1) = (shoot(l, 0.0, 1.0, &[]).0, shoot(l, 1.0, 1.0, &[]).0); let a = -u0 / (u1 - u0);
        let (_, _, mn, mx) = shoot(l, a, 1.0, &[]);
        let w = (l - 1.0).sqrt(); let bb = ((-1.0f64).exp() / l - w.cos() / l) / w.sin();
        let uc = |x: f64| -1.0 / l + x.exp() * ((w * x).cos() / l + bb * (w * x).sin());
        let (mut cmn, mut cmx) = (f64::INFINITY, f64::NEG_INFINITY);
        for i in 1..4000 { let v = uc(i as f64 / 4000.0); cmn = cmn.min(v); cmx = cmx.max(v); }
        let (sign, ext, cext) = if mn > 0.0 { ("positive", mx, cmx) } else if mx < 0.0 { ("negative", mn, cmn) } else { ("mixed", mn, cmn) }; // the other extreme is the grid point next to an end
        println!("f = 1, r = {:.1}: slope u'(0) {:.4}; {} at every inside point, extreme {:.4}; closed form {:.4}", l, a, sign, ext, cext);
        assert!((mn - cmn).abs() < 1e-6 && (mx - cmx).abs() < 1e-6 && (mn > 0.0) == (l < lam[0]) && (mx < 0.0) == (l > lam[0]));
    }
    let q = |x: f64| x * x; let h = 1e-3;
    println!("degenerate -x^2 u'' + 2u on u = x^2: residual at 0.5 {:.6}, slope at 0 {:.4} -> 0",
        (-0.25 * (q(0.5 + h) - 2.0 * q(0.5) + q(0.5 - h)) / (h * h) + 2.0 * q(0.5)).abs(), (q(h) - q(0.0)) / h);
    let ray = simpson(&|x: f64| (PI * (PI * x).cos()).powi(2), 0.0, 1.0) / simpson(&|x: f64| (PI * x).sin().powi(2), 0.0, 1.0);
    println!("energy ratio of sin(pi x), the drift dropped: {:.6}, below lambda_1 = {:.6}", ray, lam[0]);
    assert!((ray - PI * PI).abs() < 1e-9);
    println!("try: drift b = 4: lambda_1 = pi^2 + 4 = {:.6}, best release point atan(pi/2)/pi = {:.4}", PI * PI + 4.0, (PI / 2.0).atan() / PI);
    let xs10: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    println!("chart, x       {}", row(&xs10, |t| format!("{:5.1}", t), " "));
    let sinp = |x: f64| (PI * x).sin();
    println!("chart, sin(pi x){}", row(&xs10, |t| format!("{:5.2}", sinp(t)), " "));
    println!("chart, phi      {}", row(&xs10, |t| format!("{:5.2}", phi(t)), " "));
    println!("chart, phi*     {}", row(&xs10, |t| format!("{:5.2}", phs(t)), " "));
    println!("ALL CHECKS PASS");
}
