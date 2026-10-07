// Convolution and the impulse response -- the same check as the Python, in
// Rust.  No crates.  The shock absorber: y'' + 2y' + 5y = f(t), starting at
// rest.  Road one blends the impulse response with the input by a midpoint
// sum; road two steps the equation itself with Runge-Kutta 4.

fn conv(a: impl Fn(f64) -> f64, b: impl Fn(f64) -> f64, t: f64, n: usize) -> f64 {
    let w = t / n as f64;                          // (a * b)(t): add a(tau) b(t - tau) over 0..t
    w * (0..n).map(|k| { let u = (k as f64 + 0.5) * w; a(u) * b(t - u) }).sum::<f64>()
}

fn rk4(push: f64, mut y: f64, mut v: f64, h: f64, t_end: f64) -> Vec<f64> {
    let acc = |y: f64, v: f64| push - 2.0 * v - 5.0 * y;   // y'' = push - 2y' - 5y
    let (mut out, every) = (Vec::new(), (0.5 / h).round() as usize);
    for n in 0..=(t_end / h).round() as usize {
        if n % every == 0 { out.push(y) }
        let k1 = (v, acc(y, v));
        let k2 = (v + h / 2.0 * k1.1, acc(y + h / 2.0 * k1.0, v + h / 2.0 * k1.1));
        let k3 = (v + h / 2.0 * k2.1, acc(y + h / 2.0 * k2.0, v + h / 2.0 * k2.1));
        let k4 = (v + h * k3.1, acc(y + h * k3.0, v + h * k3.1));
        y += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    out
}

fn sci(x: f64) -> String {                         // 2.6e-07, as Python prints it
    let s = format!("{:.1e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let g = |t: f64| 0.5 * (-t).exp() * (2.0 * t).sin();          // impulse response, from 1/(s^2+2s+5)
    let push = |_t: f64| 10.0;
    let trip = |t: f64| 2.0 - (-t).exp() * (2.0 * (2.0 * t).cos() + (2.0 * t).sin());  // round trip
    let c1 = conv(|t: f64| (-t).exp(), |t: f64| (-2.0 * t).exp(), 1.0, 4000);
    let exact = (-1.0_f64).exp() - (-2.0_f64).exp();
    println!("e^(-t) * e^(-2t) at t = 1: midpoint sum {:.6}, e^(-1) - e^(-2) = {:.6}", c1, exact);
    let lap: f64 = (0..40000).map(|k| { let u = (k as f64 + 0.5) * 0.001; 0.001 * (-u).exp() * ((-u).exp() - (-2.0 * u).exp()) }).sum();
    println!("transforms at s = 1: (1/2)(1/3) = {:.6}, weighted integral of e^(-t) - e^(-2t) = {:.6}", 1.0 / 6.0, lap);
    let kick: Vec<f64> = [0.05, 0.025].iter().map(|&h| rk4(0.0, 0.0, 1.0, h, 1.0)[2]).collect();
    let (e1, e2) = ((kick[0] - g(1.0)).abs(), (kick[1] - g(1.0)).abs());
    println!("impulse response at t = 1: RK4 from a unit kick {:.6}, 0.5 e^(-1) sin 2 = {:.6}", kick[1], g(1.0));
    println!("RK4 error at t = 1: h = 0.05 {}, h = 0.025 {}, ratio {:.1}, near 16 for order 4", sci(e1), sci(e2), e1 / e2);
    let ts: Vec<f64> = (0..13).map(|k| 0.5 * k as f64).collect();
    let ys: Vec<f64> = ts.iter().map(|&t| conv(g, push, t, 4000)).collect();
    let steps = rk4(10.0, 0.0, 0.0, 0.01, 6.0);
    let gap = ys.iter().zip(&steps).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let gap2 = ys.iter().zip(&ts).map(|(a, &t)| (a - trip(t)).abs()).fold(0.0, f64::max);
    println!("push of 10 at t = 1: convolution {:.6}, RK4 {:.6}, round trip {:.6}", ys[2], steps[2], trip(1.0));
    println!("largest gap over 0 to 6 s: convolution vs RK4 {}, convolution vs round trip {}", sci(gap), sci(gap2));
    println!("at t = 20: convolution {:.6}, steady value 10/5 = {:.6}", conv(g, push, 20.0, 40000), 10.0 / 5.0);
    println!("figure, t     {}", row(&ts));
    println!("figure, y     {}", row(&ys));
    println!("figure, 10g   {}", row(&ts.iter().map(|&t| 10.0 * g(t)).collect::<Vec<_>>()));
    println!("mistake 1, pointwise product at t = 1: e^(-3) = {:.6}, not {:.6}", (-3.0_f64).exp(), exact);
    let noflip = conv(|t: f64| (-t).exp(), |t: f64| (-2.0 * (1.0 - t)).exp(), 1.0, 4000);
    println!("mistake 2, no flip, e^(-2 tau) for e^(-2(t - tau)): {:.6}, not {:.6}", noflip, exact);
    println!("mistake 3, released from 1 cm and pushed: convolution alone {:.6}, RK4 {:.6}",
             ys[2], rk4(10.0, 1.0, 0.0, 0.01, 1.0)[2]);
    assert!((c1 - exact).abs() < 1e-6);                     // blended sum = closed form
    assert!((lap - 1.0 / 6.0).abs() < 1e-6);                // transform of the blend = product of transforms
    assert!((kick[1] - g(1.0)).abs() < 1e-6 && 12.0 < e1 / e2 && e1 / e2 < 20.0);  // a unit kick gives g
    assert!(gap < 1e-5);                                    // convolution = stepped equation
    println!("ALL CHECKS PASS");
}
