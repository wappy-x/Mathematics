// Separable equations -- the same check as the Python, in Rust.  No crates.
// A snowball melts at a rate proportional to its surface: V' = -k V^(2/3),
// V(0) = 1000 cm^3, k = 0.3 cm/min.  Road one: the separated answer.  Road
// two: Euler steps on the law.  Road three: the law turned round, minutes per
// cm^3 of snow added up by Simpson's rule.
const K: f64 = 0.3;
const V0: f64 = 1000.0;

fn rate(v: f64) -> f64 {                  // the law; no snow, no melting
    if v > 0.0 { -K * v.powf(2.0 / 3.0) } else { 0.0 }
}

fn separated(t: f64) -> f64 {             // 3 V^(1/3) = 30 - k t, cubed; then V = 0
    (10.0 - 0.1 * t).max(0.0).powi(3)
}

fn euler(t_end: f64, h: f64) -> f64 {     // plain small steps along the slope
    let mut v = V0;
    for _ in 0..(t_end / h).round() as usize { v += h * rate(v) }
    v
}

fn euler_melt(h: f64) -> f64 {            // step until the snow runs out
    let (mut v, mut n) = (V0, 0u32);
    while v > 0.0 { v += h * rate(v); n += 1 }
    n as f64 * h
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let mut s = 0.0;                      // area under f from a to b, n even
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * (b - a) / n as f64) }
    (f(a) + f(b) + s) * (b - a) / (3.0 * n as f64)
}

fn main() {
    let minutes_per_cm3 = |v: f64| -1.0 / rate(v);
    let t_half = 10.0 * (10.0 - 500f64.powf(1.0 / 3.0)); // separated: V = 500
    let t_half_simpson = simpson(&minutes_per_cm3, 500.0, V0, 2000);
    let t_melt = 3.0 * V0.powf(1.0 / 3.0) / K;           // 3 V^(1/3) = 30 - k t reaches 0
    let errs: Vec<f64> = [1.0, 0.5, 0.25].iter().map(|&h| (euler(50.0, h) - separated(50.0)).abs()).collect();
    let slope = (separated(37.001) - separated(36.999)) / 0.002; // the answer's own rate
    let coffee = simpson(&|t: f64| 1.0 / (0.1 * (t - 20.0)), 50.0, 80.0, 2000);
    let ts: Vec<i64> = (0..13).map(|i| 10 * i).collect();
    let vs: Vec<i64> = ts.iter().map(|&t| separated(t as f64).round() as i64).collect();
    let raw: Vec<i64> = ts.iter().map(|&t| (10.0 - 0.1 * t as f64).powi(3).round() as i64).collect();
    let e: Vec<String> = errs.iter().map(|x| format!("{:.4}", x)).collect();
    let ln2 = 10.0 * 2f64.ln();
    println!("t (min)     {:?}", ts);
    println!("V (cm^3)    {:?}", vs);
    println!("formula     {:?}", raw);
    println!("V(50) separated {:.4}; Euler h = 0.01 gives {:.4}", separated(50.0), euler(50.0, 0.01));
    println!("Euler error at t = 50, h = 1, 0.5, 0.25: {}", e.join(" "));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("melted at: separated {:.2} min; Euler h = 0.01 steps out at {:.2} min", t_melt, euler_melt(0.01));
    println!("half gone (500 cm^3): separated {:.4} min; Simpson {:.4} min", t_half, t_half_simpson);
    println!("rate at t = 37: finite difference {:.4}; law -k V^(2/3) {:.4}; at t = 0 {:.1}", slope, rate(separated(37.0)), rate(V0));
    println!("lost constant solution: k V^(2/3) at V = 0 is {:.1}, so V = 0 for all time obeys the law", K * 0f64.powf(2.0 / 3.0));
    println!("a puddle at t = 120 fits both histories: V(50) = {:.0} or V(50) = 0", separated(50.0));
    println!("radius {:.4} cm, shrinking {:.4} cm/min", (3.0 * V0 / (4.0 * std::f64::consts::PI)).powf(1.0 / 3.0),
             K / (36.0 * std::f64::consts::PI).powf(1.0 / 3.0));
    println!("coffee reaches 50 C: Simpson {:.4} min; separated 10 ln 2 = {:.4} min", coffee, ln2);
    println!("mistake, formula past 100 min: V(120) = {:.0} cm^3", (10.0 - 0.1 * 120.0f64).powi(3));
    println!("mistake, dropped the 3: V^(1/3) = 10 - 0.3t, gone at {:.2} min", 10.0 / 0.3);
    println!("mistake, constant added after cubing: V = 1000 - (0.1t)^3, V(50) = {:.0}", 1000.0 - 5f64.powi(3));
    assert!((euler(50.0, 0.01) - separated(50.0)).abs() < 0.1);        // road two meets road one
    assert!((t_half_simpson - t_half).abs() < 1e-6 && (coffee - ln2).abs() < 1e-6);
    assert!(errs[0] / errs[1] > 1.8 && errs[0] / errs[1] < 2.2 && errs[1] / errs[2] > 1.8 && errs[1] / errs[2] < 2.2);
    assert!((slope - rate(separated(37.0))).abs() < 1e-4);              // the answer obeys the law
    println!("ALL CHECKS PASS");
}
