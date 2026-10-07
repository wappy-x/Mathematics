// Eigenvalue problems -- the same check as the Python, in Rust.  No crates.  A 1 m string,
// pinned at both ends, waves at 220 m/s: -y'' = lam y, y(0) = y(1) = 0.  Road one: the closed
// form n^2 pi^2.  Road two: RK4 shots bisected on lam.  Road three: finite differences.
use std::f64::consts::PI;
const C: f64 = 220.0;
fn shoot(lam: f64) -> (f64, f64, u32) { // y'' = -lam y, y(0) = 0, slope 0.1: (y(1) in cm, y'(1), nodes)
    let (n, mut nodes) = (1000u32, 0u32);
    let (h, mut y, mut p) = (1.0 / n as f64, 0.0f64, 0.1f64);
    let f = |y: f64, p: f64| (p, -lam * y);
    for i in 0..n {
        let a = f(y, p); let b = f(y + h / 2.0 * a.0, p + h / 2.0 * a.1);
        let c = f(y + h / 2.0 * b.0, p + h / 2.0 * b.1);
        let d = f(y + h * c.0, p + h * c.1);
        let yn = y + h / 6.0 * (a.0 + 2.0 * b.0 + 2.0 * c.0 + d.0);
        p += h / 6.0 * (a.1 + 2.0 * b.1 + 2.0 * c.1 + d.1);
        nodes += (i < n - 1 && yn * y < 0.0) as u32;
        y = yn;
    }
    (100.0 * y, p, nodes)
}
fn roots(g: &dyn Fn(f64) -> f64, count: usize) -> Vec<f64> { // scan lam upward from 0.5, bisect each sign change
    let (step, mut out, mut a, mut ga) = (0.5, vec![], 0.5, g(0.5));
    while out.len() < count {
        let (b, gb) = (a + step, g(a + step));
        if ga * gb < 0.0 {
            let (mut lo, mut hi, mut glo) = (a, b, ga);
            for _ in 0..50 {
                let (m, gm) = ((lo + hi) / 2.0, g((lo + hi) / 2.0));
                if glo * gm <= 0.0 { hi = m } else { lo = m; glo = gm }
            }
            out.push((lo + hi) / 2.0);
        }
        (a, ga) = (b, gb);
    }
    out
}
fn fd(n: usize, k: usize) -> f64 { // k-th eigenvalue of (1/h^2) tridiag(-1, 2, -1), n - 1 rows, by Sturm counts
    let q = (n * n) as f64; // 1/h^2
    let below = |x: f64| { // eigenvalues below x = negative pivots of A - x I
        let (mut d, mut cnt) = (2.0 * q - x, 0);
        for i in 0..n - 1 {
            if i > 0 { d = 2.0 * q - x - q * q / (if d == 0.0 { 1e-300 } else { d }) }
            if d < 0.0 { cnt += 1 }
        }
        cnt
    };
    let (mut lo, mut hi) = (0.0, 4.0 * q);
    for _ in 0..60 { let m = (lo + hi) / 2.0; if below(m) >= k { hi = m } else { lo = m } }
    (lo + hi) / 2.0
}
fn hz(l: f64) -> f64 { C * l.sqrt() / (2.0 * PI) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let lam = roots(&|l| shoot(l).0, 3);
    let exact: Vec<f64> = (1..4).map(|n| (n as f64 * PI).powi(2)).collect();
    let free = roots(&|l| shoot(l).1, 3); // far end free to slide: y'(1) = 0
    println!("not eigenvalues: lambda = -1, 0, 10 lands y(1) at {:.2}, {:.2}, {:.2} cm; sin(sqrt 10) = sin({:.4}) = {:.4}", shoot(-1.0).0, shoot(0.0).0, shoot(10.0).0, 10f64.sqrt(), 10f64.sqrt().sin());
    println!("chart lambda {}", (0..21).map(|i| (5 * i).to_string()).collect::<Vec<_>>().join(" "));
    println!("chart y(1) cm {}", join(&(0..21).map(|i| shoot(5.0 * i as f64).0).collect::<Vec<_>>(), 2));
    println!("shooting roots, both ends pinned: {}", join(&lam, 6));
    println!("closed form n^2 pi^2:             {}", join(&exact, 6));
    println!("frequencies c sqrt(lam)/(2 pi): {} Hz; ratios 1 : {:.3} : {:.3}", join(&lam.iter().map(|&l| hz(l)).collect::<Vec<_>>(), 2), hz(lam[1]) / hz(lam[0]), hz(lam[2]) / hz(lam[0]));
    println!("nodes inside the string for n = 1, 2, 3: {}", lam.iter().map(|&l| shoot(l).2.to_string()).collect::<Vec<_>>().join(" "));
    let mut errs = vec![];
    for n in [10, 20, 40] {
        let e: Vec<f64> = (1..4).map(|k| fd(n, k)).collect();
        errs.push(exact[0] - e[0]);
        println!("finite differences, {} inner points: {:.4} {:.4} {:.4}; error in lambda_1 {:.5}", n - 1, e[0], e[1], e[2], errs[errs.len() - 1]);
    }
    println!("error ratios as the grid halves: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("free far end: lambda {} -> {} Hz", join(&free, 4), join(&free.iter().map(|&l| hz(l)).collect::<Vec<_>>(), 2));
    println!("mistake, frequency in proportion to lambda: {} Hz", join(&lam.iter().map(|&l| 110.0 * l / lam[0]).collect::<Vec<_>>(), 2));
    println!("mistake, one pin only: lambda = 50 gives a shape at {:.2} Hz, y(1) = {:.2} cm", hz(50.0), shoot(50.0).0);
    println!("figure, x_px = 30 + 220 x; rows at y_px 45 110 175, 25 px per unit; nodes x = {:.3}, {:.3}, {:.3} m at x_px {:.1}, {:.1}, {:.1}", 0.5, 1.0 / 3.0, 2.0 / 3.0, 30.0 + 220.0 / 2.0, 30.0 + 220.0 / 3.0, 30.0 + 440.0 / 3.0);
    assert!(lam.iter().zip(&exact).all(|(a, b)| (a - b).abs() < 1e-6));
    assert!(free.iter().enumerate().all(|(i, a)| (a - ((i as f64 + 0.5) * PI).powi(2)).abs() < 1e-6));
    assert!(lam.iter().map(|&l| shoot(l).2).collect::<Vec<_>>() == vec![0, 1, 2]);
    assert!([errs[0] / errs[1], errs[1] / errs[2]].iter().all(|&r| 3.9 < r && r < 4.1)); // error falls 4x per halving: order two
    println!("ALL CHECKS PASS");
}
