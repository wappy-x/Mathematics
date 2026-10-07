// Two-point boundary value problems -- the same check as the Python, in Rust.
// No crates.  The strut y'' + y = 0 (x in m, y in cm) has every solution
// A cos x + B sin x.  Road one fits A and B to both ends with sin and cos.
// Road two never calls them: RK4 steps v, the solution with v(0) = 0 and
// v'(0) = 1, to the far end, and fits B from its value and slope there.
// u, with u(0) = 1 and u'(0) = 0, is stepped for the Neumann case.
use std::f64::consts::PI;

fn rk4(l: f64, n: usize, mut y: f64, mut p: f64) -> (f64, f64) { // step (y, y') across [0, L]
    let h = l / n as f64;
    for _ in 0..n {
        let k1 = (p, -y);
        let k2 = (p + h / 2.0 * k1.1, -(y + h / 2.0 * k1.0));
        let k3 = (p + h / 2.0 * k2.1, -(y + h / 2.0 * k2.0));
        let k4 = (p + h * k3.1, -(y + h * k3.0));
        y += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        p += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    (y, p)
}

fn pts(f: &dyn Fn(f64) -> f64, xs: &[f64]) -> String {
    xs.iter().map(|&x| format!("{:.1},{:.1}", 40.0 + 300.0 / PI * x, 190.0 - 120.0 * f(x))).collect::<Vec<_>>().join(" ")
}

fn main() {
    let (s1, c1) = (1f64.sin(), 1f64.cos());
    let (v1, dv1) = rk4(1.0, 100, 0.0, 1.0);     // road two at x = 1 m, h = 0.01
    let (vpi, dvpi) = rk4(PI, 314, 0.0, 1.0);    // road two at x = pi m
    let (_upi, dupi) = rk4(PI, 314, 1.0, 0.0);   // u at x = pi m
    let (b, bn, br) = (1.0 / s1, 1.0 / c1, 1.0 / (s1 + c1));
    let errs: Vec<f64> = [10, 20, 40].iter().map(|&n| (1.0 / rk4(1.0, n, 0.0, 1.0).0 - b).abs()).collect();
    let fam: Vec<f64> = [0.5, 1.0, 2.0].iter().map(|&c| rk4(PI, 314, 0.0, c).0).collect();
    let half: Vec<f64> = (0..13).map(|k| PI * k as f64 / 12.0).collect();
    let unit: Vec<f64> = (0..5).map(|k| k as f64 / 4.0).collect();
    println!("strut y'' + y = 0, every solution y = A cos x + B sin x; x in m, y in cm");
    println!("[0, 1], ends 0 and 1: D = sin 1 = {:.6}; A = 0, B = 1/sin 1 = {:.6}", s1, b);
    println!("  road two, stepped v(1) = {:.6}, B = {:.6}; midpoint y(0.5) = {:.6} cm", v1, 1.0 / v1, 0.5f64.sin() * b);
    println!("  RK4 error in B at h = 0.1 0.05 0.025: {:.2e} {:.2e} {:.2e}; ratios {:.1} {:.1}", errs[0], errs[1], errs[2], errs[0] / errs[1], errs[1] / errs[2]);
    println!("[0, pi], ends 0 and 0: D = sin pi = 0 exactly (floating sin(pi) = {:.2e}, stepped v(pi) = {:.2e})", PI.sin(), vpi);
    println!("  C sin x for C = 0.5 1 2, stepped y(pi): {:.1e} {:.1e} {:.1e}: every C fits, infinitely many", fam[0], fam[1], fam[2]);
    println!("[0, pi], ends 0 and 1: y(pi) = -A = 1 but A = 0: none; naive B = 1/sin(pi) = {:.2e}, 1/v(pi) = {:.2e}", 1.0 / PI.sin(), 1.0 / vpi);
    println!("house form -y'' = lambda y on [0, 1]: L = pi is lambda = pi^2 = {:.6}, the first eigenvalue", PI * PI);
    println!("Neumann [0, pi], y'(0) = y'(pi) = 0: B = 0 and -B = 0, A free: y = C cos x; stepped u'(pi) = {:.1e}", dupi);
    println!("Dirichlet-Neumann [0, 1], y(0) = 0, y'(1) = 1: B = 1/cos 1 = {:.6}; stepped 1/v'(1) = {:.6}", bn, 1.0 / dv1);
    println!("Robin [0, 1], y(0) = 0, y(1) + y'(1) = 1: B = 1/(sin 1 + cos 1) = {:.6}; stepped {:.6}", br, 1.0 / (v1 + dv1));
    println!("mistake, Robin sign flipped, y(1) - y'(1) = 1: B = {:.4}, not {:.4}", 1.0 / (s1 - c1), br);
    println!("hypothesis dropped, condition squared y(1)^2 = 1: B = +{:.6} or -{:.6}, exactly two; stepped y(1)^2 = {:.6}", b, b, (b * v1).powi(2));
    println!("figure, scale 95.49 px per m across, 120 px per cm up, origin (40, 190)");
    println!("figure, sin x on [0, pi]: {}", pts(&|x: f64| x.sin(), &half));
    println!("figure, 0.5 sin x: {}", pts(&|x: f64| 0.5 * x.sin(), &half));
    println!("figure, sin x / sin 1 on [0, 1]: {}; target (pi, 1) at {}", pts(&|x: f64| x.sin() * b, &unit), pts(&|_x: f64| 1.0, &[PI]));
    assert!((1.0 / v1 - b).abs() < 1e-8 && (1.0 / dv1 - bn).abs() < 1e-8);          // stepping meets the sine fit
    assert!(errs[0] / errs[1] > 12.0 && errs[0] / errs[1] < 20.0 && (1.0 / (v1 + dv1) - br).abs() < 1e-8); // order 4; Robin
    assert!(fam.iter().all(|f| f.abs() < 1e-8) && (dvpi + 1.0).abs() < 1e-8 && dupi.abs() < 1e-8); // at pi: v = 0, v' = -1, u' = 0
    println!("ALL CHECKS PASS");
}
