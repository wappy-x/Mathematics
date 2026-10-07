// Mixing tanks -- the same check as the Python, in Rust.  No crates.
// A 200 L brewing tank holds 4 kg of sugar.  Syrup at 0.05 kg/L flows in at
// 5 L/min and the stirred mix drains at 5 L/min, so S' = 0.25 - S/40.
// Road one: the integrating-factor answer.  Road two: Euler steps on the rate
// law itself.  Second case: a drug dripped into 40 L of body water.
const V: f64 = 200.0; // L
const Q: f64 = 5.0; // L/min
const C_IN: f64 = 0.05; // kg/L
const S0: f64 = 4.0; // kg
const TAU: f64 = V / Q; // 40 min
const S_INF: f64 = V * C_IN; // 10 kg

fn exact(t: f64) -> f64 { S_INF + (S0 - S_INF) * (-t / TAU).exp() } // S = 10 - 6 e^(-t/40)

fn euler(rate: &dyn Fn(f64, f64) -> f64, mut y: f64, t_end: f64, h: f64) -> f64 {
    let mut t = 0.0; // small steps along the slope
    for _ in 0..(t_end / h).round() as usize { y += h * rate(t, y); t += h }
    y
}

fn crossing(rate: &dyn Fn(f64, f64) -> f64, mut y: f64, level: f64, h: f64) -> f64 {
    let mut t = 0.0; // step until y reaches level
    while y < level { y += h * rate(t, y); t += h }
    t
}

fn main() {
    let tank = |_t: f64, s: f64| Q * C_IN - Q * s / V; // kg/min in minus kg/min out
    let drug = |_t: f64, a: f64| 20.0 - 5.0 * a / 40.0; // mg/h dripped in minus mg/h cleared
    let grow = |t: f64, s: f64| Q * C_IN - 4.0 * s / (V + t); // drain cut to 4 L/min: tank fills
    let errs: Vec<f64> = [1.0, 0.5, 0.25].iter().map(|&h| (euler(&tank, S0, 60.0, h) - exact(60.0)).abs()).collect();
    let drug_12 = 160.0 * (1.0 - (-12.0f64 / 8.0).exp()); // A = 160 (1 - e^(-t/8)) mg
    let grow_60 = 0.05 * 260.0 - 6.0 * (200.0f64 / 260.0).powi(4); // integrating factor (200 + t)^4
    let fixed_60 = 12.5 - 8.5 * (-60.0f64 / 50.0).exp(); // wrong: volume held at 200 L
    let ts: Vec<String> = (0..13).map(|i| format!("{}", 20 * i)).collect();
    let ss: Vec<String> = (0..13).map(|i| format!("{:.2}", exact(20.0 * i as f64))).collect();
    let es: Vec<String> = errs.iter().map(|e| format!("{:.4}", e)).collect();
    println!("in {:.2} kg/min; out S/{:.0} kg/min, {:.2} at t = 0 ({:.2} kg/L); net {:.2} kg/min", Q * C_IN, TAU, Q * S0 / V, S0 / V, tank(0.0, S0));
    println!("S = {:.0} - {:.0} e^(-t/{:.0}); settles at {:.2} kg = {} kg/L x {:.0} L", S_INF, S_INF - S0, TAU, S_INF, C_IN, V);
    println!("t (min) {}", ts.join(" "));
    println!("S (kg)  {}", ss.join(" "));
    println!("S(40) = {:.4} kg; S(60) = {:.4} kg, {:.4} kg/L", exact(40.0), exact(60.0), exact(60.0) / V);
    println!("Euler h = 0.01 to t = 60: {:.4} kg", euler(&tank, S0, 60.0, 0.01));
    println!("Euler error at t = 60, h = 1, 0.5, 0.25: {}", es.join(" "));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("S = 7 kg: formula 40 ln 2 = {:.2} min; Euler {:.2} min", TAU * 2f64.ln(), crossing(&tank, S0, 7.0, 0.001));
    println!("S = 9.70 kg: formula 40 ln 20 = {:.2} min; Euler {:.2} min", TAU * 20f64.ln(), crossing(&tank, S0, 9.7, 0.001));
    println!("drug: 20 mg/h into 40 L, cleared 5 L/h; settles at {:.0} mg = {:.2} mg/L; half-life 8 ln 2 = {:.2} h", 20.0 / (5.0 / 40.0), 20.0 / 5.0, 8.0 * 2f64.ln());
    println!("drug at 12 h: formula {:.2} mg; Euler {:.2} mg; {:.2} mg/L", drug_12, euler(&drug, 0.0, 12.0, 0.001), drug_12 / 40.0);
    println!("drug at 95% (152 mg): formula 8 ln 20 = {:.2} h; Euler {:.2} h", 8.0 * 20f64.ln(), crossing(&drug, 0.0, 152.0, 0.0001));
    println!("drain 4 L/min, S(60): formula {:.2} kg; Euler {:.2} kg; in {:.0} L", grow_60, euler(&grow, S0, 60.0, 0.001), V + 60.0);
    println!("mistake, volume held at 200 L with 4 L/min out: S(60) = {:.2} kg", fixed_60);
    println!("mistake, outflow 5S not 5S/200: settles at {:.2} kg", euler(&|_t, s| 0.25 - 5.0 * s, S0, 60.0, 0.01));
    println!("mistake, drain at the feed's 0.05 kg/L: S(60) = {:.2} kg", euler(&|_t, _s| 0.25 - 5.0 * 0.05, S0, 60.0, 0.01));
    println!("mistake, start from a clean tank: S(60) = {:.2} kg", S_INF * (1.0 - (-60.0 / TAU).exp()));
    assert!((euler(&tank, S0, 60.0, 0.01) - exact(60.0)).abs() < 1e-3); // road two meets road one
    assert!(errs[0] / errs[1] > 1.8 && errs[0] / errs[1] < 2.2 && errs[1] / errs[2] > 1.8 && errs[1] / errs[2] < 2.2);
    assert!((euler(&drug, 0.0, 12.0, 0.001) - drug_12).abs() < 1e-2); // the drug, both roads
    assert!((euler(&grow, S0, 60.0, 0.001) - grow_60).abs() < 1e-3); // unequal flows, both roads
    println!("ALL CHECKS PASS");
}
