// Newton's method, the same check as the Python, in Rust.  No crates, no square root called.
// Solve x*x = 2 from the bracket [1, 2], stop on a residual, check two other ways, break it.
fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> (f64, usize) {
    let (mut k, mut k10) = (0, 0);                   // road two: signs only, no slopes
    while a < (a + b) / 2.0 && (a + b) / 2.0 < b {   // halve until the floats run out
        let c = (a + b) / 2.0;
        if (f(c) < 0.0) == (f(a) < 0.0) { a = c } else { b = c }
        k += 1;
        if k10 == 0 && b - a < 1e-10 { k10 = k }
    }
    ((a + b) / 2.0, k10)
}

fn newton(f: &dyn Fn(f64) -> f64, df: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64, mut x: f64)
    -> (Vec<f64>, String) {                          // a step leaving the bracket bisects
    let (mut path, mut kinds) = (vec![x], String::new());
    while f(x).abs() >= 1e-10 && path.len() < 60 {
        let t = if df(x) != 0.0 { x - f(x) / df(x) } else { a - 1.0 };
        let inside = a < t && t < b;
        kinds.push(if inside { 'N' } else { 'B' });
        x = if inside { t } else { (a + b) / 2.0 };
        if (f(x) < 0.0) == (f(a) < 0.0) { a = x } else { b = x }
        path.push(x);
    }
    (path, kinds)
}

fn decimals(x: f64, r: f64) -> i32 {                 // decimal places that agree
    let mut k = 0;
    while (x * 10f64.powi(k + 1)) as i64 == (r * 10f64.powi(k + 1)) as i64 { k += 1 }
    k
}

fn main() {
    let f = |x: f64| x * x - 2.0;
    let df = |x: f64| 2.0 * x;
    println!("bracket [1, 2]: f(1) = {:.1}, f(2) = {:.1}; the signs differ", f(1.0), f(2.0));
    let (r, k10) = bisect(&f, 1.0, 2.0);
    let (path, kinds) = newton(&f, &df, 1.0, 2.0, 1.0);
    let (mut p, mut q): (i64, i64) = (1, 1);         // road three: exact fractions p/q
    for (n, &x) in path.iter().enumerate() {
        println!("step {}  x = {:.15} = {}/{}  residual {:.1e}  error {:.1e}  decimals {}",
                 n, x, p, q, f(x), x - r, decimals(x, r));
        assert!((x - p as f64 / q as f64).abs() < 1e-15);
        (p, q) = (p * p + 2 * q * q, 2 * p * q);
    }
    let x4 = path[path.len() - 1];
    println!("stopped after {} Newton steps ({}): residual below 1e-10; bound |f|/2 = {:.1e}",
             path.len() - 1, kinds, f(x4).abs() / 2.0);
    println!("bisection, signs only: {:.15}; {} halvings to a bracket under 1e-10 wide", r, k10);
    let ratios: Vec<f64> = (0..3).map(|n| (path[n + 1] - r) / (path[n] - r).powi(2)).collect();
    let fmt = |v: Vec<f64>| v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ");
    println!("error ratio e(n+1)/e(n)^2: {} ; 1/(2 x_n): {} ; limit 1/(2r) = {:.4}", fmt(ratios.clone()),
             fmt((0..3).map(|n| 1.0 / (2.0 * path[n])).collect()), 1.0 / (2.0 * r));
    let (sx, sy) = (|x: f64| 40.0 + 200.0 * (x - 0.8), |y: f64| 150.0 - 50.0 * y);
    println!("figure, start ({:.1}, {:.1}), x1 ({:.1}, {:.1}), curve above x1 ({:.1}, {:.1}), x2 ({:.1}, {:.1})",
             sx(1.0), sy(-1.0), sx(1.5), sy(0.0), sx(1.5), sy(0.25), sx(path[2]), sy(0.0));
    println!("fail 1, start at 0: slope f'(0) = {:.1}, the tangent never meets the axis", df(0.0));
    let g = |x: f64| x.powi(3) - 2.0 * x + 2.0;
    let dg = |x: f64| 3.0 * x * x - 2.0;
    let mut cyc = vec![0.0f64];
    for _ in 0..4 { let c = cyc[cyc.len() - 1]; cyc.push(c - g(c) / dg(c)) }
    let cs: Vec<String> = cyc.iter().map(|v| format!("{:.0}", v)).collect();
    println!("fail 2, x^3 - 2x + 2 from 0, no bracket: {}", cs.join(" -> "));
    let (gpath, gk) = newton(&g, &dg, -2.0, 0.0, 0.0);
    let groot = bisect(&g, -2.0, 0.0).0;
    println!("same cubic guarded on [-2, 0]: {} steps ({}), x = {:.12}, bisection {:.12}",
             gpath.len() - 1, gk, gpath[gpath.len() - 1], groot);
    let (spath, _) = newton(&|x: f64| 1e-12 * f(x), &|x: f64| 2e-12 * x, 1.0, 2.0, 1.0);
    let s = spath[spath.len() - 1];
    println!("fail 3, f scaled by 1e-12: stops after {} steps at x = {:.3}, error {:.3}; bound |f|/m = {:.3}",
             spath.len() - 1, s, (s - r).abs(), 1e-12 * f(1.0).abs() / 2e-12);
    assert!((x4 - r).abs() <= f(x4).abs() / 2.0 && f(x4).abs() / 2.0 < 1e-10);
    assert!((0..3).all(|n| (ratios[n] - 1.0 / (2.0 * path[n])).abs() < 1e-6));
    assert!(cyc == vec![0.0, 1.0, 0.0, 1.0, 0.0] && (gpath[gpath.len() - 1] - groot).abs() < 1e-10);
    println!("ALL CHECKS PASS");
}
