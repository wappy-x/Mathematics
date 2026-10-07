// The transport equation u_t + c u_x = 0 -- the same check in Rust, std only.
// A spill of 10 mg/L, width 1 km, rides a river at 2 km/h.  Road 1 is the
// formula; road 2 is a grid stepped with no formula (constant speed), or the
// characteristic ODE stepped by RK4 (speed 2 + x/2).
fn f(a: f64) -> f64 { 10.0 * (-a * a).exp() }            // the spill, mg/L, at label a km

fn upwind(h: f64, nu: f64) -> (f64, f64) {               // road 2: upwind grid, speed 2
    let (t, lo, hi, xq) = (3.0, -4.0, 10.0, 5.0);
    let k = nu * h / 2.0;
    let n = ((hi - lo) / h).round() as usize + 1;
    let mut u: Vec<f64> = (0..n).map(|i| f(lo + i as f64 * h)).collect();
    for _ in 0..(t / k).round() as usize {
        let old = u.clone();
        u[0] = 0.0;
        for i in 1..n { u[i] = old[i] - nu * (old[i] - old[i - 1]) }
    }
    (u[((xq - lo) / h).round() as usize], u.iter().fold(0.0f64, |m, v| m.max(v.abs())))
}

fn rk4(mut x: f64, t0: f64, t1: f64, n: usize) -> f64 {  // step X' = 2 + X/2 from t0 to t1
    let s = (t1 - t0) / n as f64;
    let c = |x: f64| 2.0 + x / 2.0;
    for _ in 0..n {
        let k1 = c(x); let k2 = c(x + s * k1 / 2.0); let k3 = c(x + s * k2 / 2.0); let k4 = c(x + s * k3);
        x += s * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
    }
    x
}

fn main() {
    let e = 1f64.exp();
    let exact = f(5.0 - 2.0 * 3.0);
    println!("constant speed 2 km/h, x = 5 km, t = 3 h: formula f(x - ct) = {:.4} mg/L", exact);
    let mut errs = vec![];
    for h in [0.05, 0.025, 0.0125] {
        let g = upwind(h, 0.8).0;
        errs.push(g - exact);
        println!("road 2, upwind grid h = {} km: {:.4} mg/L, grid minus formula {:+.4}", h, g, g - exact);
    }
    println!("error ratios as h halves: {:.2}, {:.2}", errs[0] / errs[1], errs[1] / errs[2]);
    let lab = 14.0 / e - 4.0;
    let v = f(lab);
    let back: Vec<f64> = [5, 10].iter().map(|&n| rk4(10.0, 2.0, 0.0, n)).collect();
    println!("speed 2 + x/2, x = 10 km, t = 2 h: label (x + 4)/e - 4 = {:.4} km, value {:.4} mg/L", lab, v);
    for (n, b) in [5, 10].iter().zip(&back) {
        println!("road 2, RK4 back to t = 0 in {} steps: label {:.6} km, error {:.7}", n, b, (b - lab).abs());
    }
    let w0 = 2.0 * 2f64.ln().sqrt();
    let w2 = rk4(w0 / 2.0, 0.0, 2.0, 20) - rk4(-w0 / 2.0, 0.0, 2.0, 20);
    println!("centre at t = 2 h: formula 4(e - 1) = {:.4} km, RK4 {:.4} km", 4.0 * (e - 1.0), rk4(0.0, 0.0, 2.0, 20));
    println!("half-height width: {:.4} km at t = 0; at t = 2 h, {:.4} km by formula, {:.4} by RK4", w0, w0 * e, w2);
    println!("mistake 1, f(x + ct) at x = 6 km, t = 3 h: {:.4} mg/L, not {:.4}", f(12.0), f(0.0));
    println!("mistake 2, speed 2 + x/2 taken as 2, at x = 10 km, t = 2 h: {:.4} mg/L, not {:.4}", f(6.0), v);
    let big = upwind(0.05, 1.5).1;
    println!("mistake 3, river moves 1.5 cells per time step, not 0.8: peak grows to 10^{:.1} mg/L", big.log10());
    let labels: Vec<f64> = (0..6001).map(|i| -3.0 + i as f64 / 1000.0).collect();   // u_t + u u_x = 0
    let sp: Vec<f64> = labels.iter().map(|a| 2.0 + (-a * a).exp()).collect();
    let cross = (0..6000).filter(|&i| sp[i + 1] < sp[i])
        .map(|i| -(labels[i + 1] - labels[i]) / (sp[i + 1] - sp[i])).fold(f64::INFINITY, f64::min);
    println!("nonlinear, speed 2 + e^(-a^2): lines first cross at {:.4} h by search, {:.4} h by formula", cross, (e / 2.0).sqrt());
    for t in [0.0, 1.5, 3.0] {
        let row: Vec<String> = (-2..9).map(|x| format!("{:.2}", f(x as f64 - 2.0 * t))).collect();
        println!("chart, t = {} h: {}", t, row.join(", "));
    }
    let a5 = [-2.0, -1.0, 0.0, 1.0, 2.0];
    let ends: Vec<String> = a5.iter().map(|a| format!("{:.2}", a + 4.0)).collect();
    println!("figure, x (km) at t = 2 h for a = -2 to 2, speed 2: {}; speed 2 + x/2, at t = 0.5, 1, 1.5, 2 h:", ends.join(" "));
    let curves: Vec<String> = a5.iter().map(|a| [0.5, 1.0, 1.5, 2.0].iter()
        .map(|t: &f64| format!("{:.2}", (a + 4.0) * (t / 2.0).exp() - 4.0)).collect::<Vec<_>>().join(" ")).collect();
    println!("figure, {}", curves.join("; "));
    assert!(errs[2] > 0.0 && errs[2] < 0.06 && errs[1] / errs[2] > 1.8 && errs[1] / errs[2] < 2.2);
    assert!((back[1] - lab).abs() < 1e-5 && (w2 - w0 * e).abs() < 1e-5);   // RK4 meets the closed-form label
    assert!((cross - (e / 2.0).sqrt()).abs() < 1e-4);                     // search meets breaking-time formula
    println!("ALL CHECKS PASS");
}
