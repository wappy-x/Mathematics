// Frobenius check for the wire 2x y'' + y' + y = 0, tip at x = 0.  Road 1: the
// series from the recurrence.  Road 2: s = sqrt(2x) makes it y'' + y = 0 in s,
// so cos s and sin s.  Road 3: Runge-Kutta 4 from x = 1 to x = 2.  No crates.
fn series(r: f64, x: f64) -> (f64, f64) {        // y and y' of the series with a0 = 1
    let (mut a, mut y, mut dy) = (1.0_f64, 0.0_f64, 0.0_f64);
    for n in 0..30 {
        let n = n as f64;
        if n > 0.0 { a = -a / ((n + r) * (2.0 * n + 2.0 * r - 1.0)); }
        y += a * x.powf(n + r);
        if n + r > 0.0 && x > 0.0 { dy += a * (n + r) * x.powf(n + r - 1.0); }
    }
    (y, dy)
}
fn exact(r2: u64) -> String {                    // a0..a4 as fractions; r2 is 2r
    let (mut d, mut out) = (1_u64, vec!["1".to_string()]);
    for n in 1..5_u64 {
        d *= (2 * n + r2) * (2 * n + r2 - 1) / 2;
        let sign = if n % 2 == 1 { "-" } else { "" };
        out.push(if d == 1 { format!("{}1", sign) } else { format!("{}1/{}", sign, d) });
    }
    out.join(", ")
}
fn f(x: f64, y: f64, v: f64) -> (f64, f64) { (v, -(v + y) / (2.0 * x)) }
fn rk4(mut y: f64, mut v: f64, mut x: f64, h: f64, steps: usize) -> f64 {
    for _ in 0..steps {                          // road 3: y'' = -(y' + y) / (2x)
        let k1 = f(x, y, v);
        let k2 = f(x + h / 2.0, y + h / 2.0 * k1.0, v + h / 2.0 * k1.1);
        let k3 = f(x + h / 2.0, y + h / 2.0 * k2.0, v + h / 2.0 * k2.1);
        let k4 = f(x + h, y + h * k3.0, v + h * k3.1);
        y += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        x += h;
    }
    y
}
fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(", ")
}
fn main() {
    let (p0, q0) = (0.5_f64, 0.0_f64);           // x p and x^2 q at the tip
    let (b, disc) = (p0 - 1.0, ((p0 - 1.0).powi(2) - 4.0 * q0).sqrt());
    println!("indicial r(r-1) + {:.1} r + {:.1} = 0: roots {:.1} and {:.1}", p0, q0, (-b - disc) / 2.0, (-b + disc) / 2.0);
    println!("r = 0 series: {}\nr = 1/2 series: {}", exact(0), exact(1));
    let (y1, y2) = (series(0.0, 1.0).0, series(0.5, 1.0).0);
    let (c1, c2) = (2.0_f64.sqrt().cos(), 2.0_f64.sqrt().sin() / 2.0_f64.sqrt());
    let five: f64 = [1.0, -1.0, 1.0 / 6.0, -1.0 / 90.0, 1.0 / 2520.0].iter().sum();
    println!("x = 1: r = 0 series {:.12} (five terms {:.12}), cos(sqrt(2x)) {:.12}", y1, five, c1);
    println!("x = 1: r = 1/2 series {:.12}, sin(sqrt(2x))/sqrt(2) {:.12}", y2, c2);
    let w: Vec<f64> = [0.5_f64, 1.0, 2.0].iter().map(|&x| {
        let ((u, du), (v, dv)) = (series(0.0, x), series(0.5, x));
        (u * dv - du * v) * x.sqrt()
    }).collect();
    println!("Wronskian times sqrt(x) at x = 0.5, 1, 2: {}", join(&w, 12));
    let (s0, d0) = series(0.0, 1.0);
    let e1 = (rk4(s0, d0, 1.0, 0.1, 10) - 2.0_f64.cos()).abs();
    let e2 = (rk4(s0, d0, 1.0, 0.05, 20) - 2.0_f64.cos()).abs();
    println!("RK4 from x = 1 to 2, error: h = 0.1 {:.12}, h = 0.05 {:.12}, ratio {:.1}", e1, e2, e1 / e2);
    let (f1, f2) = (1e-6_f64.sqrt() * series(0.0, 1e-6).1, 1e-6_f64.sqrt() * series(0.5, 1e-6).1);
    println!("tip heat flow sqrt(x) y' at x = 0.000001: r = 0 mode {:.3}, r = 1/2 mode {:.3}", f1, f2);
    for r in [0.0_f64, 0.5] {
        let pts: Vec<f64> = (0..11).map(|k| series(r, k as f64 / 2.0).0).collect();
        println!("chart r = {:.1}: {}", r, join(&pts, 2));
    }
    let (lhs, rhs) = (1 * (1 - 1) + 0 * 1 + 0, -(1 * 0 + -1) * 1);   // I(1) a1 = -(P1 r + Q1) a0
    let (g, h) = (|x: f64| 1.0 + x * x.ln(), 1e-4_f64);          // residual by finite differences
    let res = [0.25_f64, 0.5, 0.75].iter().map(|&x| (x * (1.0 - x) * (g(x + h) - 2.0 * g(x) + g(x - h)) / (h * h) + x * (g(x + h) - g(x - h)) / (2.0 * h) - g(x)).abs()).fold(0.0_f64, f64::max);
    println!("log case x(1-x)y'' + xy' - y = 0, roots 0 and 1: r = 0, n = 1 asks {} * a1 = {}", lhs, rhs);
    println!("log case: 1 + x ln x at x = 0.5 is {:.9}, largest residual at x = 0.25, 0.5, 0.75: {:.9}", g(0.5), res);
    println!("mistake, forgetting -r: roots 0 and -0.5; x^-0.5 leaves {:.1} x^-1.5", -0.5 * (2.0 * -0.5 - 1.0));
    let terms: Vec<f64> = (1..31).scan(1.0_f64, |p, n| { *p *= n as f64 * 0.1; Some(*p) }).skip(9).step_by(10).collect();
    println!("mistake, irregular x^2 y'' + (3x-1) y' + y = 0, n! 0.1^n at n = 10, 20, 30: {}", join(&terms, 6));
    let lg = 1.0_f64.ln();
    println!("mistake, a log forced on x^2 y'' - 2x y' + 2y = 0: x ln x leaves {:.3} at x = 1", 1.0 - 2.0 * (lg + 1.0) + 2.0 * lg);
    assert!((y1 - c1).abs() < 1e-12 && (y2 - c2).abs() < 1e-12);   // road 1 = road 2
    assert!(w.iter().all(|t| (t - 0.5).abs() < 1e-12));           // Abel: W = (1/2) x^(-1/2)
    assert!(e2 < 1e-8 && 14.0 < e1 / e2 && e1 / e2 < 18.0);        // road 3, fourth order
    assert!(res < 1e-6);                                           // the log partner solves it
    println!("ALL CHECKS PASS");
}
