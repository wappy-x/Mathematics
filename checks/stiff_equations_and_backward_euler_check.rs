// Stiff equations and backward Euler -- the same check as the Python, in Rust.
// No crates.  The fast intermediate: y' = -1000(y - cos t) - sin t, y(0) = 0,
// t in s.  Exact solution y = cos t - e^(-1000t).  Road 1: three stepping rules
// against that closed form.  Road 2: nudge the start and measure the factor each
// rule applies to the gap from the slow curve, against the algebra 1 + z,
// 1/(1 - z) and (1 + z/2)/(1 - z/2) with z = -1000h.
const K: f64 = 1000.0;
type Step = fn(f64, f64, f64) -> f64;
fn g(t: f64) -> f64 { K * t.cos() - t.sin() }                 // f(t, y) = -K y + g(t)
fn forward(t: f64, y: f64, h: f64) -> f64 { y + h * (-K * y + g(t)) }
fn backward(t: f64, y: f64, h: f64) -> f64 { (y + h * g(t + h)) / (1.0 + K * h) } // solved for the destination
fn trapezoid(t: f64, y: f64, h: f64) -> f64 {
    ((1.0 - K * h / 2.0) * y + h / 2.0 * (g(t) + g(t + h))) / (1.0 + K * h / 2.0)
}
fn exact(t: f64) -> f64 { t.cos() - (-K * t).exp() }
fn run(step: Step, h: f64, n: usize, y: f64) -> Vec<f64> {
    let mut ys = vec![y];
    for i in 0..n { let last = ys[i]; ys.push(step(i as f64 * h, last, h)); }
    ys
}
fn err(step: Step, h: f64, n: usize, y: f64) -> f64 {
    run(step, h, n, y)[n] - ((n as f64 * h).cos() - (1.0 - y) * (-K * n as f64 * h).exp())
}
fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let steps: [Step; 3] = [forward, backward, trapezoid];
    let names = ["forward", "backward", "trapezoid"];
    let h = 0.01; let z = -K * h;
    let one: Vec<String> = (0..3).map(|i| format!("{} {:.6}", names[i], steps[i](0.0, 0.0, h))).collect();
    println!("one step, h=0.01, from y=0: {}, exact {:.6}", one.join(", "), exact(h));
    let algebra = [1.0 + z, 1.0 / (1.0 - z), (1.0 + z / 2.0) / (1.0 - z / 2.0)];
    let nudged: Vec<f64> = steps.iter().map(|s| (s(0.0, 1e-3, h) - s(0.0, 0.0, h)) / 1e-3).collect();
    let al: Vec<String> = (0..3).map(|i| format!("{} {:.6}", names[i], algebra[i])).collect();
    let me: Vec<String> = (0..3).map(|i| format!("{} {:.6}", names[i], nudged[i])).collect();
    println!("gap factor, algebra: {}, exact e^z {:.6}", al.join(", "), z.exp());
    println!("gap factor, measured: {}", me.join(", "));
    assert!((0..3).all(|i| (algebra[i] - nudged[i]).abs() < 1e-9));
    println!("forward shrinks the gap only while |1 - 1000h| < 1, so h < 2/1000 = {:.3}", 2.0 / K);
    println!("figure, t: {}", join(&(0..11).map(|i| i as f64 * h).collect::<Vec<_>>(), 2));
    println!("figure, exact: {}", join(&(0..11).map(|i| exact(i as f64 * h)).collect::<Vec<_>>(), 2));
    println!("figure, backward: {}", join(&run(backward, h, 10, 0.0), 2));
    println!("figure, trapezoid: {}", join(&run(trapezoid, h, 10, 0.0), 2));
    println!("forward h=0.01: y at t=0.1 {}, at t=1 {}", sci(run(forward, h, 10, 0.0)[10]), sci(run(forward, h, 100, 0.0)[100]));
    println!("forward h=0.01 from y=1, already on the slow curve: error at t=0.1 {}", sci(err(forward, h, 10, 1.0)));
    for hh in [0.0019, 0.0021] {
        println!("forward h={}: factor {:.1}, 500 steps reach t={:.2}, error {}", hh, 1.0 - K * hh, 500.0 * hh, sci(err(forward, hh, 500, 0.0)));
    }
    let hs3 = [0.01, 0.005, 0.0025];
    let eb: Vec<f64> = hs3.iter().map(|&x| err(backward, x, (1.0 / x).round() as usize, 0.0)).collect();
    let et: Vec<f64> = hs3.iter().map(|&x| err(trapezoid, x, (1.0 / x).round() as usize, 0.0)).collect();
    for (n, e) in [("backward", &eb), ("trapezoid", &et)] {
        let s: Vec<String> = e.iter().map(|&x| sci(x)).collect();
        println!("error at t=1, h=0.01, 0.005, 0.0025: {} {}; ratios {:.2}, {:.2}", n, s.join(", "), e[0] / e[1], e[1] / e[2]);
    }
    assert!(1.9 < eb[0] / eb[1] && eb[0] / eb[1] < 2.1 && 3.9 < et[1] / et[2] && et[1] / et[2] < 4.1 // orders 1 and 2; errors within the proved bounds
        && eb.iter().zip(hs3.iter()).all(|(&e, &x)| e.abs() <= x / (2.0 * K) + (-K).exp() + (1.0 + K * x).powi(-((1.0 / x).round() as i32)))
        && err(forward, 0.0019, 500, 0.0).abs() <= 0.9_f64.powi(500) + 0.0019 * 0.0019 / 2.0 / 0.1);
    let hs = [0.001, 0.01, 0.1, 1.0, 10.0];
    let fac: Vec<f64> = hs.iter().map(|&x| (backward(0.0, 1e-3, x) - backward(0.0, 0.0, x)) / 1e-3).collect();
    println!("backward gap factor, h=0.001 to 10: {}", join(&fac, 6));
    assert!(fac.iter().zip(hs.iter()).all(|(&f, &x)| (f - 1.0 / (1.0 + K * x)).abs() < 1e-9 && 0.0 < f && f < 1.0));
    let tr: Vec<f64> = [1, 2, 3, 10].iter().map(|&n| err(trapezoid, 0.1, n, 0.0)).collect();
    println!("h=0.1, trapezoid error at t=0.1, 0.2, 0.3, 1: {}; backward at t=1 {}", join(&tr, 4), sci(err(backward, 0.1, 10, 0.0)));
    assert!((tr[3] + (-49.0_f64 / 51.0).powi(10)).abs() < 0.01);  // the start gap -1, times (-49/51) ten times
    let (mut v, mut its) = (0.0_f64, vec![]);
    for _ in 0..3 { v = 0.0 + h * (-K * v + g(h)); its.push(v); }   // plug-in iteration, not a solve
    println!("backward step by plug-in iteration: {}; solved {:.6}", join(&its, 3), backward(0.0, 0.0, h));
    println!("ALL CHECKS PASS");
}
