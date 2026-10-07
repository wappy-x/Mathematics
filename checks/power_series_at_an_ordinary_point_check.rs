// Power series at an ordinary point -- the same check as the Python, in Rust.  No
// crates.  A 2 mm steel rod hangs from a tilted clamp; its tilt y at height x above the
// free tip (x in natural lengths) obeys Airy's y'' = x y, y(0) = 1, y'(0) = 0.  Road one:
// the coefficient recurrence, summed.  Road two: Runge-Kutta 4.  Second case: arctan.

fn horner(a: &[f64], x: f64) -> f64 {            // a[0] + a[1] x + a[2] x^2 + ...
    a.iter().rev().fold(0.0, |s, &c| s * x + c)
}

fn rk4(f: fn(f64, [f64; 2]) -> [f64; 2], mut x: f64, mut s: [f64; 2], x1: f64, n: usize) -> f64 {
    let h = (x1 - x) / n as f64;                 // s = [y, y'], f returns [y', y'']
    let add = |s: [f64; 2], k: [f64; 2], c: f64| [s[0] + c * k[0], s[1] + c * k[1]];
    for _ in 0..n {
        let k1 = f(x, s);
        let k2 = f(x + h / 2.0, add(s, k1, h / 2.0));
        let k3 = f(x + h / 2.0, add(s, k2, h / 2.0));
        let k4 = f(x + h, add(s, k3, h));
        s = [0, 1].map(|i| s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]));
        x += h;
    }
    s[0]
}

fn airy(x: f64, s: [f64; 2]) -> [f64; 2] { [s[1], x * s[0]] }
fn atan_eq(x: f64, s: [f64; 2]) -> [f64; 2] { [s[1], -2.0 * x * s[1] / (1.0 + x * x)] }
fn join(v: Vec<String>) -> String { v.join(" ") }

fn main() {
    let mut a = vec![0.0; 33];                   // a_(n+3) = a_n / ((n + 3)(n + 2))
    a[0] = 1.0;
    for n in 0..30 { a[n + 3] = a[n] / ((n + 3) * (n + 2)) as f64 }
    let mut b = vec![0.0; 402];                  // a_(n+2) = -n a_n / (n + 2)
    b[1] = 1.0;
    for n in 1..400 { b[n + 2] = -(n as f64) * b[n] / (n + 2) as f64 }
    let ell = (200e9 * 0.002f64.powi(2) / (16.0 * 7850.0 * 9.81)).powf(1.0 / 3.0);
    println!("natural length (E d^2 / (16 rho g))^(1/3), 2 mm steel: {:.1} mm", ell * 1000.0);
    println!("1/a3, 1/a6, 1/a9, 1/a12: {}", join([3, 6, 9, 12].iter().map(|&k| format!("{:.0}", 1.0 / a[k])).collect()));
    println!("partial sums at x = 1, degree 3/6/9/12: {}",
             join([3, 6, 9, 12].iter().map(|&d| format!("{:.9}", horner(&a[..d + 1], 1.0))).collect()));
    let y1 = horner(&a, 1.0);
    println!("series to degree 30 at x = 1: {:.12}", y1);
    let errs: Vec<f64> = [5, 10, 20].iter().map(|&n| rk4(airy, 0.0, [1.0, 0.0], 1.0, n) - y1).collect();
    println!("RK4 errors x 1e9 at h = 0.2/0.1/0.05: {}", join(errs.iter().map(|e| format!("{:.1}", e * 1e9)).collect()));
    println!("error ratio when h halves: {:.1}, {:.1}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("clamp tilted 2.000 deg: tip tilt {:.3} deg", 2.0 / y1);
    println!("Airy ratio ((n+3)(n+2))^(1/3) at n = 30, 300: {}",
             join([30.0f64, 300.0].iter().map(|n| format!("{:.1}", ((n + 3.0) * (n + 2.0)).powf(1.0 / 3.0))).collect()));
    let dist = (4.0f64 * 1.0 * 1.0 - 0.0 * 0.0).sqrt() / 2.0; // 1 + x^2 = 0: roots 0 +/- (sqrt(4ac - b^2) / 2a) i
    println!("second case: 1 + x^2 = 0 at 0 +/- {:.3}i, distance {:.3}", dist, dist);
    let est = (b[399] / b[401]).abs().sqrt();
    println!("ratio estimate sqrt|a_399 / a_401|: {:.5}", est);
    let (s05, r05) = (horner(&b[..41], 0.5), rk4(atan_eq, 0.0, [0.0, 1.0], 0.5, 40));
    println!("at x = 0.5: series 20 terms {:.9}, RK4 {:.9}", s05, r05);
    let r2 = rk4(atan_eq, 0.0, [0.0, 1.0], 2.0, 200);
    println!("at x = 2: series 5/10/20 terms {}; RK4 {:.9}",
             join([5, 10, 20].iter().map(|&k| format!("{:.1}", horner(&b[..2 * k + 1], 2.0))).collect()), r2);
    println!("mistake, x frozen at 1 (y'' = y, y = cosh x): y(1) = {:.6}", (1f64.exp() + (-1f64).exp()) / 2.0);
    let xs = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
    println!("figure, x:           {}", join(xs.iter().map(|x| format!("{:5.2}", x)).collect()));
    println!("figure, series y:    {}", join(xs.iter().map(|&x| format!("{:5.2}", horner(&a, x))).collect()));
    println!("figure, 1 + x^3/6:   {}", join(xs.iter().map(|x| format!("{:5.2}", 1.0 + x * x * x / 6.0)).collect()));
    assert!((rk4(airy, 0.0, [1.0, 0.0], 1.0, 80) - y1).abs() < 1e-9);          // two roads, one tilt
    assert!(14.0 < errs[0] / errs[1] && errs[0] / errs[1] < 18.0 && 14.0 < errs[1] / errs[2] && errs[1] / errs[2] < 18.0);
    assert!((s05 - r05).abs() < 1e-9 && horner(&b[..41], 2.0).abs() > 100.0 * r2); // inside vs outside radius
    assert!((est - dist).abs() < 0.01);                                        // radius = distance to +/- i
    println!("ALL CHECKS PASS");
}
