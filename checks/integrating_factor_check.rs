// The integrating factor -- the same check as the Python, in Rust.  No crates.
// A room at 10 C drifts toward an outdoor temperature that swings round 20 C:
// T' = -0.5 (T - (20 + 5 sin t)), T(0) = 10, t in hours.  Road one: the answer
// found with the weight e^(0.5t).  Road two: the weighted-input formula, its
// integral added up by Simpson's rule.  Road three: Euler steps on the law.
const K: f64 = 0.5;
const T0: f64 = 10.0;
const PI: f64 = std::f64::consts::PI;

fn outdoor(t: f64) -> f64 { 20.0 + 5.0 * t.sin() }
fn law(t: f64, temp: f64) -> f64 { -K * (temp - outdoor(t)) }       // the room's rate, C per hour
fn forced(t: f64) -> f64 { 20.0 + t.sin() - 2.0 * t.cos() }         // the part that stays
fn closed(t: f64) -> f64 { forced(t) - 8.0 * (-K * t).exp() }       // plus the transient

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let mut s = 0.0;                      // area under f from a to b, n even
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * (b - a) / n as f64) }
    (f(a) + f(b) + s) * (b - a) / (3.0 * n as f64)
}

fn via_weight(t: f64, p: f64, q: &dyn Fn(f64) -> f64, y0: f64) -> f64 { // (y0 + integral of mu q) / mu
    (y0 + simpson(&|s: f64| (p * s).exp() * q(s), 0.0, t, 2000)) / (p * t).exp()
}

fn euler(t_end: f64, h: f64) -> f64 {     // plain small steps along the slope
    let (mut t, mut temp) = (0.0, T0);
    for _ in 0..(t_end / h).round() as usize { temp += h * law(t, temp); t += h }
    temp
}

fn main() {
    let errs: Vec<f64> = [0.1, 0.05, 0.025].iter().map(|&h| (euler(10.0, h) - closed(10.0)).abs()).collect();
    let (mut t30, h) = (euler(30.0, 0.001), 0.001); // late in the day: the transient is gone
    let (mut top, mut t_top, mut bottom) = (f64::MIN, 0.0, f64::MAX);
    for i in 0..(2.0 * PI / h).round() as usize {    // one full outdoor swing, stepped
        let t = 30.0 + i as f64 * h;
        if t30 > top || (t30 == top && t > t_top) { top = t30; t_top = t }
        if t30 < bottom { bottom = t30 }
        t30 += h * law(t, t30);
    }
    let swing = (top - bottom) / 2.0;
    let lag = t_top - (PI / 2.0 + 10.0 * PI);        // outdoor peaks at t = pi/2 + 2 pi n
    let (mut lo, mut hi) = (0.0f64, 20.0f64);        // house coffee, by bisection
    for _ in 0..50 {
        let mid = (lo + hi) / 2.0;
        if via_weight(mid, 0.1, &|_s: f64| 2.0, 80.0) > 50.0 { lo = mid } else { hi = mid }
    }
    let fd = (closed(3.001) - closed(2.999)) / 0.002;
    let road2 = via_weight(10.0, K, &|s: f64| K * outdoor(s), T0);
    let unweighted = (-5.0f64).exp() * (T0 + simpson(&|s: f64| K * outdoor(s), 0.0, 10.0, 2000));
    let row = |f: &dyn Fn(f64) -> f64| (0..13).map(|t| format!("{:.2}", f(t as f64))).collect::<Vec<_>>().join(", ");
    let e: Vec<String> = errs.iter().map(|x| format!("{:.5}", x)).collect();
    println!("t (h)        {:?}", (0..13).collect::<Vec<i32>>());
    println!("outdoor (C)  {}", row(&outdoor));
    println!("room T (C)   {}", row(&closed));
    println!("forced (C)   {}", row(&forced));
    println!("T(10): weight answer {:.4}; Simpson on the weighted input {:.4}", closed(10.0), road2);
    println!("Euler error at t = 10, h = 0.1, 0.05, 0.025: {}", e.join(" "));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("rate at t = 3: finite difference {:.4}; law {:.4}", fd, law(3.0, closed(3.0)));
    println!("swing: formula 5 x {:.4} = {:.4}; Euler, one late cycle {:.4}", K / (K * K + 1.0).sqrt(), 5.0 * K / (K * K + 1.0).sqrt(), swing);
    println!("lag: formula atan(1/k) = {:.4} h of a {:.2} h swing; Euler peak after outdoor peak {:.3} h", (1.0 / K).atan(), 2.0 * PI, lag);
    println!("transient -8e^(-0.5t): at t = 10 {:.4}; under 0.1 C after {:.2} h", -8.0 * (-5f64).exp(), 2.0 * 80f64.ln());
    println!("coffee reaches 50 C: weight formula + bisection {:.4} min; 10 ln 2 = {:.4} min", lo, 10.0 * 2f64.ln());
    println!("mistake, weight e^(-0.5t) carried through: T(10) = {:.1}", via_weight(10.0, -K, &|s: f64| K * outdoor(s), T0));
    println!("mistake, constant dropped: T(0) = {:.2}, not 10", forced(0.0));
    println!("mistake, input not weighted: T(10) = {:.2}", unweighted);
    println!("mistake, room copies outdoor: swing 5.00, lag 0; truth {:.2} and {:.2} h", 5f64.sqrt(), 2f64.atan());
    assert!((road2 - closed(10.0)).abs() < 1e-9);                                  // road two
    assert!(errs[0] / errs[1] > 1.8 && errs[0] / errs[1] < 2.2 && errs[1] / errs[2] > 1.8 && errs[1] / errs[2] < 2.2);
    assert!((swing - 5f64.sqrt()).abs() < 0.005 && (lag - 2f64.atan()).abs() < 0.005); // road three
    assert!((fd - law(3.0, closed(3.0))).abs() < 1e-6 && (lo - 10.0 * 2f64.ln()).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
