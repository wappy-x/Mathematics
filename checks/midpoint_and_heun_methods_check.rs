// Midpoint and Heun -- the same check as the Python, in Rust, std only.
// The skydiver: v' = 9.8 - 0.2 v, v(0) = 0, exact v = 49 (1 - e^(-0.2 t)).
// Road one: step the rule and compare with the exact curve.  Road two: for this
// straight-line rule a two-stage step multiplies the gap to 49 m/s by
// q = 1 - x + x^2/2 with x = 0.2 h, so v_n = 49 (1 - q^n), no stepping at all.
type Rule = fn(f64, f64) -> f64;
type Step = fn(Rule, f64, f64, f64) -> f64;

fn f(_t: f64, v: f64) -> f64 { 9.8 - 0.2 * v } // the rate rule, m/s per s
fn drag(_t: f64, v: f64) -> f64 { 9.8 - 9.8 * (v / 49.0).powi(2) } // drag grows as v^2
fn euler(f: Rule, t: f64, v: f64, h: f64) -> f64 { v + h * f(t, v) }
fn midpoint(f: Rule, t: f64, v: f64, h: f64) -> f64 { v + h * f(t + h / 2.0, v + h / 2.0 * f(t, v)) }
fn heun(f: Rule, t: f64, v: f64, h: f64) -> f64 { v + h / 2.0 * (f(t, v) + f(t + h, v + h * f(t, v))) }
fn heun_no_half(f: Rule, t: f64, v: f64, h: f64) -> f64 { v + h * (f(t, v) + f(t + h, v + h * f(t, v))) }
fn slope_at_end(f: Rule, t: f64, v: f64, h: f64) -> f64 { v + h * f(t + h, v + h * f(t, v)) }

fn run(step: Step, rule: Rule, h: f64) -> Vec<f64> {
    let mut path = vec![0.0];
    let mut v = 0.0;
    for n in 0..(10.0 / h).round() as usize { v = step(rule, n as f64 * h, v, h); path.push(v); }
    path
}
fn last(step: Step, rule: Rule, h: f64) -> f64 { *run(step, rule, h).last().unwrap() }
fn exact(t: f64) -> f64 { 49.0 * (1.0 - (-0.2 * t).exp()) }
fn exact_drag(t: f64) -> f64 { 49.0 * (1.0 - (-0.4 * t).exp()) / (1.0 + (-0.4 * t).exp()) }
fn join(p: &[f64]) -> String { p.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (k1, k2, km) = (f(0.0, 0.0), f(2.0, 2.0 * f(0.0, 0.0)), f(1.0, f(0.0, 0.0)));
    println!("first step, h = 2: k1 = {:.2}; Heun predicts {:.2}, slope there {:.2}, average {:.2}; midpoint half-step {:.2}, slope there {:.2}",
        k1, 2.0 * k1, k2, (k1 + k2) / 2.0, k1, km);
    println!("first step lands at {:.2} (Heun) and {:.2} (midpoint); exact {:.4}; Euler {:.2}",
        heun(f, 0.0, 0.0, 2.0), midpoint(f, 0.0, 0.0, 2.0), exact(2.0), euler(f, 0.0, 0.0, 2.0));
    let ex: Vec<f64> = (0..6).map(|i| exact(2.0 * i as f64)).collect();
    println!("chart, exact: {}", join(&ex));
    println!("chart, euler h = 2: {}", join(&run(euler, f, 2.0)));
    println!("chart, heun h = 2: {}", join(&run(heun, f, 2.0)));
    let x = 0.2 * 2.0;
    let q: f64 = 1.0 - x + x * x / 2.0;
    println!("shortcut, h = 2: q = {:.4} against e^(-0.4) = {:.4}; 49 (1 - q^5) = {:.4}; q passes 1 at h = {:.0}", q, (-x).exp(), 49.0 * (1.0 - q.powi(5)), 2.0 / 0.2);
    let hs = [2.0, 1.0, 0.5, 0.25];
    let steps: [Step; 3] = [euler, midpoint, heun];
    let err: Vec<Vec<f64>> = hs.iter().map(|&h| steps.iter().map(|&s| (last(s, f, h) - exact(10.0)).abs()).collect()).collect();
    for (i, &h) in hs.iter().enumerate() {
        println!("h = {}: v(10) Euler {:.4} error {:.4}; Heun {:.4} error {:.4}; midpoint error {:.4}",
            h, last(euler, f, h), err[i][0], last(heun, f, h), err[i][2], err[i][1]);
    }
    println!("error ratio when h halves, 0.5 to 0.25: Euler {:.2}, Heun {:.2}", err[2][0] / err[3][0], err[2][2] / err[3][2]);
    let (dm, dh) = (last(midpoint, drag, 2.0), last(heun, drag, 2.0));
    println!("drag v^2, h = 2: midpoint {:.4}, Heun {:.4}, exact {:.4}", dm, dh, exact_drag(10.0));
    let de: Vec<Vec<f64>> = [0.5, 0.25].iter().map(|&h| [midpoint as Step, heun].iter().map(|&s| (last(s, drag, h) - exact_drag(10.0)).abs()).collect()).collect();
    println!("drag v^2, error at h = 0.5 and 0.25: midpoint {:.5} {:.5} ratio {:.2}; Heun {:.5} {:.5} ratio {:.2}",
        de[0][0], de[1][0], de[0][0] / de[1][0], de[0][1], de[1][1], de[0][1] / de[1][1]);
    let wrong: [(&str, Step); 3] = [("slope at start only (Euler)", euler), ("sum not averaged", heun_no_half), ("end slope alone", slope_at_end)];
    for (name, s) in wrong {
        println!("mistake, {}: v(10) = {:.2}, error {:.2}", name, last(s, f, 2.0), (last(s, f, 2.0) - exact(10.0)).abs());
    }
    let (px, py) = (|t: f64| 45.0 + 100.0 * t, |v: f64| 200.0 - 9.0 * v);
    let pts: Vec<String> = [0.0, 0.5, 1.0, 1.5, 2.0].iter().map(|&t| format!("({:.1}, {:.1})", px(t), py(exact(t)))).collect();
    println!("figure, exact curve (x, y): {}; end x {:.1}: Euler y {:.1}, Heun y {:.1}; half-step ({:.1}, {:.1})",
        pts.join(", "), px(2.0), py(2.0 * k1), py(heun(f, 0.0, 0.0, 2.0)), px(1.0), py(k1));
    let (h, x) = (0.1, 0.02);
    assert!(run(heun, f, 2.0).iter().enumerate().all(|(n, v)| (v - 49.0 * (1.0 - q.powi(n as i32))).abs() < 1e-9)); // two roads agree
    assert!((exact(h) - heun(f, 0.0, 0.0, h) - 49.0 * x * x * x / 6.0).abs() < 49.0 * x.powi(4) / 24.0); // local error ~ h^3
    assert!(err[2][2] / err[3][2] > 3.8 && err[2][2] / err[3][2] < 4.2 && err[2][0] / err[3][0] > 1.8 && err[2][0] / err[3][0] < 2.2);
    assert!(dm != dh && de[0][0] / de[1][0] > 3.6 && de[0][0] / de[1][0] < 4.4 && de[0][1] / de[1][1] > 3.6 && de[0][1] / de[1][1] < 4.4);
    println!("ALL CHECKS PASS");
}
