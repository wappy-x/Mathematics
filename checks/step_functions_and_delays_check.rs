// Step functions and delays -- the same check as the Python, in Rust.  No
// crates.  A 20 C room, T' = -0.5(T - 20 - 10u(t - 2)), with the heater
// switched on at t = 2 h.  Road one is the transform answer, built from the two
// shifting rules.  Road two steps the equation with Runge-Kutta 4 and never
// uses a transform.  A midpoint sum checks each rule's integral directly.
const K: f64 = 0.5; const GAIN: f64 = 10.0; const ON: f64 = 2.0;

fn step(t: f64) -> f64 { if t >= 0.0 { 1.0 } else { 0.0 } }  // the unit step, 1 from t = 0 on

fn closed(t: f64, off: Option<f64>) -> f64 {               // road one: 10(1 - e^(-0.5(t - 2))) u(t - 2)
    let mut x = GAIN * (1.0 - (-K * (t - ON)).exp()) * step(t - ON);
    if let Some(o) = off { x -= GAIN * (1.0 - (-K * (t - o)).exp()) * step(t - o) }
    20.0 + x
}

fn rk4(t_end: f64, h: f64, off: Option<f64>) -> f64 {    // road two: heater fixed within each step
    let (mut temp, n) = (20.0, (t_end / h).round() as usize);
    for i in 0..n {
        let t0 = i as f64 * h;
        let heat = step(t0 - ON + 1e-9) - off.map_or(0.0, |o| step(t0 - o + 1e-9));
        let f = |x: f64| -K * (x - 20.0 - GAIN * heat);
        let k1 = f(temp); let k2 = f(temp + h / 2.0 * k1);
        let k3 = f(temp + h / 2.0 * k2); let k4 = f(temp + h * k3);
        temp += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
    }
    temp
}

fn transform(g: &dyn Fn(f64) -> f64, s: f64) -> f64 {    // midpoint sum of e^(-st) g(t), 0 to 40
    let (end, n) = (40.0, 40000);
    let dt = end / n as f64;
    (0..n).map(|k| { let t = (k as f64 + 0.5) * dt; (-s * t).exp() * g(t) }).sum::<f64>() * dt
}

fn sci(x: f64) -> String {                                // 2.0e-07, as Python prints it
    let t = format!("{:.1e}", x);
    let (m, e) = t.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn main() {
    let tgt: Vec<String> = (0..11).map(|t| format!("{:.0}", 20.0 + GAIN * step(t as f64 - ON))).collect();
    println!("target 20 + 10u(t - 2) at hours 0..10: {}", tgt.join(" "));
    let row: Vec<String> = (0..11).map(|t| format!("{:.2}", closed(t as f64, None))).collect();
    println!("T at hours 0..10: {}", row.join(" "));
    println!("T(3) = {:.4}, T(4) = {:.4}, T(6) = {:.4} C", closed(3.0, None), closed(4.0, None), closed(6.0, None));
    println!("reaches 25 C at t = 2 + 2 ln 2 = {:.3} h", ON + 2f64.ln() / K);
    let errs: Vec<f64> = [0.1, 0.05].iter().map(|&h| (rk4(4.0, h, None) - closed(4.0, None)).abs()).collect();
    println!("RK4 T(4) at h = 0.05: {:.6}; errors {}, {}; ratio {:.1}",
             rk4(4.0, 0.05, None), sci(errs[0]), sci(errs[1]), errs[0] / errs[1]);
    println!("on 2 h, off 6 h: T(8) = {:.4} closed, {:.4} RK4", closed(8.0, Some(6.0)), rk4(8.0, 0.05, Some(6.0)));
    let big_x = 5.0 * (-2.0f64).exp() / (1.0 * 1.5);           // delay rule at s = 1: 5e^(-2s)/(s(s+0.5))
    let xn = transform(&|t| closed(t, None) - 20.0, 1.0);
    println!("s = 1: delay rule X = {:.6}, midpoint sum of e^(-t)(T - 20) = {:.6}", big_x, xn);
    let sn = transform(&|t| 5.0 * step(t - ON), 1.0);
    println!("s = 1: forcing 5u(t-2) -> 5e^(-2)/1 = {:.6}, midpoint sum {:.6}", 5.0 * (-2.0f64).exp(), sn);
    let fnum = transform(&|t| (-K * t).exp() * t, 1.0);
    println!("s = 1: e^(-0.5t) t -> 1/(s+0.5)^2 = {:.6}, midpoint sum {:.6}", 1.0 / (1.5f64 * 1.5), fnum);
    println!("mistake 1, gate without restarting: T(2) = {:.4}, T(4) = {:.4}",
             20.0 + GAIN * (1.0 - (-K * 2.0).exp()), 20.0 + GAIN * (1.0 - (-K * 4.0).exp()));
    println!("mistake 2, e^(+2s) for the delay: T(4) = {:.4}", 20.0 + GAIN * (1.0 - (-K * 6.0).exp()));
    println!("mistake 3, 1/(s+0.5) read as e^(+0.5t): T(4) = {:.4}", 20.0 + GAIN * (1.0 - (K * 2.0).exp()));
    assert!((rk4(4.0, 0.05, None) - closed(4.0, None)).abs() < 1e-6);        // stepped room = transform answer
    assert!((rk4(8.0, 0.05, Some(6.0)) - closed(8.0, Some(6.0))).abs() < 1e-6); // second case: on, then off
    assert!((xn - big_x).abs() < 1e-6);                                        // delay rule vs direct integral
    assert!((fnum - 1.0 / (1.5f64 * 1.5)).abs() < 1e-6);                       // s-shift rule vs direct integral
    println!("ALL CHECKS PASS");
}
