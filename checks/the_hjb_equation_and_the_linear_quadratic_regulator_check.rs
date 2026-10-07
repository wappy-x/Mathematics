// The HJB equation and the linear-quadratic regulator -- the same check as the Python.
// Cruise control: speed error x (m/s), push u (m/s^2), x' = u, cost the integral of
// x^2 + u^2.  Claim: value V(x) = x^2, best push u = -x.  Roads: the formula; a search
// over u; RK4 stepping of the car; a backward Bellman recursion; RK4 on the Riccati.
const X0: f64 = 2.0;

fn run(k: f64, h: f64, t_end: f64) -> (f64, f64, Vec<f64>) { // RK4: x' = -k x, cost rate (1 + k^2) x^2
    let f = |x: f64| (-k * x, (1.0 + k * k) * x * x);
    let (mut x, mut c, mut t, mut half, mut path) = (X0, 0.0, 0.0, f64::NAN, vec![X0]);
    for _ in 0..(t_end / h).round() as usize {
        let a = f(x); let b = f(x + h / 2.0 * a.0); let d = f(x + h / 2.0 * b.0); let e = f(x + h * d.0);
        let xn = x + h / 6.0 * (a.0 + 2.0 * b.0 + 2.0 * d.0 + e.0);
        c += h / 6.0 * (a.1 + 2.0 * b.1 + 2.0 * d.1 + e.1);
        if half.is_nan() && xn <= X0 / 2.0 { half = t + h * (x - X0 / 2.0) / (x - xn) } // straight line
        x = xn; t += h; path.push(x);
    }
    (c, half, path)
}
fn ternary(g: impl Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // lowest point of a bowl
    for _ in 0..200 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if g(m1) < g(m2) { hi = m2 } else { lo = m1 }
    }
    (lo + hi) / 2.0
}
fn bellman(h: f64) -> f64 {                // V = P x^2 on steps of h, back from P = 0
    let mut p = 0.0;
    for _ in 0..(40.0 / h).round() as usize { p = h + p / (1.0 + h * p) }
    p
}
fn riccati(s_end: f64, h: f64) -> f64 {    // RK4 on P' = 1 - P^2 in time to go, P(0) = 0
    let (g, mut p) = (|p: f64| 1.0 - p * p, 0.0);
    for _ in 0..(s_end / h).round() as usize {
        let a = g(p); let b = g(p + h / 2.0 * a); let d = g(p + h / 2.0 * b);
        p += h / 6.0 * (a + 2.0 * b + 2.0 * d + g(p + h * d));
    }
    p
}
fn tanh(s: f64) -> f64 { ((2.0 * s).exp() - 1.0) / ((2.0 * s).exp() + 1.0) }
fn sci(v: f64) -> String {                 // 1.4e-06, the way Python prints it
    let s = format!("{:.1e}", v);
    let (m, e) = s.split_once('e').unwrap(); let n: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let u_best = ternary(|u| X0 * X0 + u * u + 2.0 * X0 * u, -10.0, 10.0);
    let (c1, half, path) = run(1.0, 0.01, 60.0);
    let gains = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0]; let costs: Vec<f64> = gains.iter().map(|&k| run(k, 0.01, 60.0).0).collect();
    let scan = (25..301).map(|k| (run(k as f64 / 100.0, 0.02, 60.0).0, k as f64 / 100.0))
        .fold((f64::INFINITY, 0.0), |b, c| if c.0 < b.0 { c } else { b });
    println!("HJB at x = 2, V' = 4: search finds u = {:.4}, min of x^2 + u^2 + V'u = {:.6}", u_best, X0 * X0 + u_best * u_best + 2.0 * X0 * u_best);
    println!("cost of u = -x from x0 = 2, RK4 stepped: {:.6}; value V(2) = x0^2 = {:.6}", c1, X0 * X0);
    println!("error halves after {:.3} s, stepped; ln 2 = {:.3} s", half, 2f64.ln());
    let pts: Vec<f64> = (0..301).step_by(50).map(|i| path[i]).collect();
    println!("chart, error x(t) at t = 0 0.5 1 1.5 2 2.5 3: {}", join(&pts, 2));
    println!("chart, cost of gain k = {}: {}", gains.iter().map(|k| format!("{:?}", k)).collect::<Vec<_>>().join(" "), join(&costs, 2));
    println!("best gain on a scan 0.25 to 3 in steps of 0.01: k = {:.2}, cost {:.4}", scan.1, scan.0);
    for h in [0.1, 0.01, 0.001] {
        let p = bellman(h);
        println!("Bellman on steps of {}: P = {:.6}, gain {:.6}, P - 1 = {:.6}", h, p, p / (1.0 + h * p), p - 1.0);
    }
    for h in [0.1, 0.05] {
        let ps: Vec<f64> = [1.0, 2.0, 3.0].iter().map(|&s| riccati(s, h)).collect();
        let worst = ps.iter().zip([1.0, 2.0, 3.0]).map(|(p, s)| (p - tanh(s)).abs()).fold(0.0, f64::max);
        println!("Riccati RK4 h = {}: P at 1, 2, 3 s to go = {}; worst error vs tanh {}", h, join(&ps, 6), sci(worst));
    }
    println!("tanh(1) = {:.6}; 1 s trip from x0 = 2 costs {:.4}, not {:.4}", tanh(1.0), X0 * X0 * tanh(1.0), X0 * X0);
    let (c20, (c05, h05, _)) = (run(20.0, 0.001, 60.0).0, run(0.5, 0.01, 60.0));
    println!("mistake, no push cost: gain 20 gives speed cost {:.4}, true cost {:.4}", c20 / 401.0, c20);
    println!("mistake, V' = x not 2x: gain 0.5, cost {:.4}, halving time {:.3} s", c05, h05);
    println!("mistake, root P = -1: u = +x, error after 3 s = {:.4} m/s", run(-1.0, 0.01, 3.0).2.last().unwrap());
    assert!((c1 - X0 * X0).abs() < 1e-6 && (half - 2f64.ln()).abs() < 1e-3); // stepping vs formula
    assert!((scan.1 - 1.0f64).abs() < 1e-9 && costs.iter().zip(gains).all(|(c, k)| (c - X0 * X0 * (1.0 + k * k) / (2.0 * k)).abs() < 1e-6));
    let r = (bellman(0.01) - 1.0) / (bellman(0.001) - 1.0);
    assert!((bellman(0.001) - 1.0).abs() < 1e-3 && 9.0 < r && r < 11.0);
    assert!((u_best + X0).abs() < 1e-6 && [1.0, 2.0, 3.0].iter().all(|&s| (riccati(s, 0.05) - tanh(s)).abs() < 1e-6));
    println!("ALL CHECKS PASS");
}
