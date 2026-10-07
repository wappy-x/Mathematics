// Bessel's equation and the drum -- the same check as the Python, in Rust.  No crates.  A timpani
// head, radius 0.3 m, wave speed 100 m/s.  A pure note's shape y(x), x = k r, obeys x^2 y'' + x y' + x^2 y = 0.
// Road one: the Frobenius series J0, zeros by bisection.  Road two: Runge-Kutta 4 out from the centre.
use std::f64::consts::PI;
const R: f64 = 0.3; const C: f64 = 100.0;              // drum radius (m), wave speed on the head (m/s)

fn terms(x: f64, n: usize, wrong: bool) -> Vec<f64> {  // a_n = -a_(n-2) / n^2; wrong: n(n - 1), y'/x dropped
    let mut out = vec![1.0];
    for k in 1..n { let d = if wrong { (2 * k * (2 * k - 1)) as f64 } else { (4 * k * k) as f64 }; out.push(out[k - 1] * -x * x / d); }
    out
}
fn series(x: f64) -> f64 { terms(x, 40, false).iter().sum() }
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..80 { let mid = (lo + hi) / 2.0; if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn zeros(f: &dyn Fn(f64) -> f64) -> Vec<f64> {         // every sign change of f below 10, refined
    (0..100).map(|i| i as f64 * 0.1).filter(|&a| f(a) * f(a + 0.1) < 0.0).map(|a| bisect(f, a, a + 0.1)).collect()
}
fn rk4(x: f64, y: f64, v: f64, h: f64) -> (f64, f64) { // one step of y'' = -y'/x - y; at x = 0, y'' = -y/2
    let f = |x: f64, y: f64, v: f64| (v, if x == 0.0 { -y / 2.0 } else { -v / x - y });
    let k1 = f(x, y, v); let k2 = f(x + h / 2.0, y + h / 2.0 * k1.0, v + h / 2.0 * k1.1);
    let k3 = f(x + h / 2.0, y + h / 2.0 * k2.0, v + h / 2.0 * k2.1); let k4 = f(x + h, y + h * k3.0, v + h * k3.1);
    (y + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0), v + h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1))
}
fn rk4_zeros(h: f64) -> Vec<f64> {                     // step out from y(0) = 1, y'(0) = 0; refine each crossing
    let (mut x, mut y, mut v, mut found) = (0.0, 1.0, 0.0, Vec::new());
    while x < 10.0 - h / 2.0 {
        let (y2, v2) = rk4(x, y, v, h);
        if y * y2 < 0.0 { found.push(x + bisect(&|s| rk4(x, y, v, s).0, 0.0, h)); }
        x += h; y = y2; v = v2;
    }
    found
}
fn fx(v: f64, p: usize, w: usize) -> String {          // fixed decimals, no "-0.00"
    let s = format!("{:w$.p$}", v, w = w, p = p);
    if s.trim_start_matches(|c: char| c == ' ' || c == '-').chars().all(|c| c == '0' || c == '.') { format!("{:w$.p$}", 0.0, w = w, p = p) } else { s }
}
fn row(vals: &[f64], p: usize) -> String { vals.iter().map(|&v| fx(v, p, 0)).collect::<Vec<_>>().join(" ") }
fn resid(g: &dyn Fn(f64) -> f64, x: f64) -> f64 {
    let h = 1e-3;
    x * x * (g(x + h) - 2.0 * g(x) + g(x - h)) / (h * h) + x * (g(x + h) - g(x - h)) / (2.0 * h) + x * x * g(x)
}

fn main() {
    println!("indicial s^2 = 0: double root s = 0; a1 = 0; a2, a4, a6, a8 = -1/4, 1/64, -1/2304, 1/147456");
    println!("J0 put into the equation at x = 1.5, rates by differences: residual below 1e-5: {}", if resid(&series, 1.5).abs() < 1e-5 { "yes" } else { "no" });
    println!("hand check, terms at x = 2.4: {} ; J0(2.4) = {:.6}, J0(2.41) = {:.6}", row(&terms(2.4, 7, false), 6), series(2.4), series(2.41));
    let js = zeros(&series);
    println!("zeros, series and bisection: {}", row(&js, 6));
    let mut errs: Vec<f64> = Vec::new();
    for h in [0.2, 0.1, 0.05] {
        let rz = rk4_zeros(h);
        errs.push(rz.iter().zip(&js).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max));
        println!("zeros, RK4 from the centre, h = {:.2}: {} ; worst error {:.2} millionths", h, row(&rz, 6), errs[errs.len() - 1] * 1e6);
    }
    println!("error ratio when h halves: {:.1}, {:.1}", errs[0] / errs[1], errs[1] / errs[2]);
    let beta: Vec<f64> = (1..=3).map(|n| (n as f64 - 0.25) * PI).collect();
    let ratios: Vec<f64> = js[1..].iter().map(|j| j / js[0]).collect();
    let bratios: Vec<f64> = beta[1..].iter().map(|b| b / beta[0]).collect();
    let mcm: Vec<f64> = beta.iter().map(|b| b + 1.0 / (8.0 * b)).collect();
    println!("overtone ratios j2/j1, j3/j1: {} ; large-x estimate (n - 1/4) pi: {} ; its ratios {} ; with 1/(8 beta) added: {}", row(&ratios, 3), row(&beta, 3), row(&bratios, 3), row(&mcm, 4));
    let fs: Vec<f64> = js.iter().map(|j| C * j / (2.0 * PI * R)).collect();
    println!("timpani R = {} m, c = {:.0} m/s: notes {} Hz", R, C, row(&fs, 1));
    println!("figure, r (cm): {}", (0..11).map(|i| format!("{:5}", 3 * i)).collect::<Vec<_>>().join(" "));
    for n in 0..3 { println!("figure, mode {}:  {}", n + 1, (0..11).map(|i| fx(series(js[n] * i as f64 / 10.0), 2, 5)).collect::<Vec<_>>().join(" ")); }
    println!("mistake, harmonic overtones: {:.1} and {:.1} Hz, not {:.1} and {:.1}", 2.0 * fs[0], 3.0 * fs[0], fs[1], fs[2]);
    let cz = zeros(&|x| terms(x, 40, true).iter().sum());
    let cr: Vec<f64> = cz[1..].iter().map(|z| z / cz[0]).collect();
    println!("mistake, y'/x dropped (cos x): zeros {} ; ratios {} ; fundamental {:.1} Hz; cos x in J0's equation at 1.5: {:.3}", row(&cz, 3), row(&cr, 3), C * cz[0] / (2.0 * PI * R), resid(&|x: f64| x.cos(), 1.5));
    let tz = zeros(&|x| terms(x, 4, false).iter().sum());
    println!("mistake, 4 terms of the series: {} zero below 10, at {:.3}", tz.len(), tz[0]);
    assert!(errs[errs.len() - 1] < 5e-7);                                            // two roads, one set of zeros
    assert!(10.0 < errs[0] / errs[1] && errs[0] / errs[1] < 22.0 && 10.0 < errs[1] / errs[2] && errs[1] / errs[2] < 22.0);
    assert!(resid(&series, 1.5).abs() < 1e-5 && resid(&|x: f64| x.cos(), 1.5).abs() > 1.0);   // J0 solves it, cos x does not
    assert!(js.iter().zip(&beta).all(|(j, b)| (j - b - 1.0 / (8.0 * b)).abs() < 0.005));     // large-x estimate agrees
    println!("ALL CHECKS PASS");
}
