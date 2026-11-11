// Thermodynamic laws and entropy -- the same check as thermodynamic_laws_and_entropy_check.py.
// Standard library only, no crates.  A bicycle pump: 300 cm^3 of air at 20 C and 1 atm,
// outlet shut, squeezed to 75 cm^3.  Roads: closed forms; an RK4 walk along the stroke;
// Simpson for the slow stroke; a step-by-step entropy sum; the lost-work identity.
use std::f64::consts::PI;

const R: f64 = 8.314462618; // gas constant, J/(mol K), CODATA 2018 (exact)
const CV: f64 = 2.5 * R; // air as a diatomic ideal gas, J/(mol K)
const P1: f64 = 101325.0; // start pressure, Pa
const T1: f64 = 293.15; // start temperature, K
const T0: f64 = 293.15; // room, K
const V1: f64 = 300e-6; // m^3
const V2: f64 = 75e-6; // m^3
const BORE: f64 = 0.030; // m

fn out(label: &str, v: f64, d: usize, unit: &str) {
    println!("{:<42}{:>12.*} {}", label, d, v, unit);
}

fn stroke_rk4(cv: f64, n: f64, steps: usize) -> (f64, f64) {
    // road 2: dT/dV = -R T/(cv V), dW/dV = -n R T/V, walked in V
    let h = (V2 - V1) / steps as f64;
    let f = |v: f64, t: f64| (-R * t / (cv * v), -n * R * t / v);
    let (mut v, mut t, mut w) = (V1, T1, 0.0);
    for _ in 0..steps {
        let k1 = f(v, t);
        let k2 = f(v + h / 2.0, t + h / 2.0 * k1.0);
        let k3 = f(v + h / 2.0, t + h / 2.0 * k2.0);
        let k4 = f(v + h, t + h * k3.0);
        t += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        w += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        v += h;
    }
    (t, w)
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = 0.0;
    for i in 1..m {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    h / 3.0 * (f(a) + f(b) + s)
}

fn fast(cv: f64, ratio: f64) -> (f64, f64) {
    // closed form: T V^(gamma-1) stays fixed, W = n cv (T2 - T1)
    let n = P1 * V1 / (R * T1);
    let t2 = T1 * ratio.powf(R / cv);
    (t2, n * cv * (t2 - T1))
}

fn main() {
    let area = PI * BORE.powi(2) / 4.0;
    let n = P1 * V1 / (R * T1);
    let r = V1 / V2;
    let (t2, w_fast) = fast(CV, r);
    let p2 = n * R * t2 / V2;
    let (t2_rk, w_rk) = stroke_rk4(CV, n, 2000);
    let w_slow = n * R * T0 * r.ln();
    let w_slow_simp = simpson(|v| n * R * T0 / v, V2, V1, 2000);
    let q_cool = n * CV * (t2 - T0);
    let ds_air = n * CV * (T0 / t2).ln();
    let m = 100000; // road 2 for the entropy: add dQ/T over 100,000 small cooling steps
    let mut ds_air_sum = 0.0;
    for i in 0..m {
        let tm = t2 - (i as f64 + 0.5) * (t2 - T0) / m as f64;
        ds_air_sum += n * CV * (-(t2 - T0) / m as f64) / tm;
    }
    let ds_room = q_cool / T0;
    let s_gen = ds_air + ds_room;
    let p3 = n * R * T0 / V2;

    out("air in the barrel", n * 1000.0, 4, "mmol");
    out("barrel length for 300 cm^3, 30 mm bore", V1 / area * 100.0, 2, "cm");
    out("barrel area", area * 1e6, 2, "mm^2");
    out("tyre valve opens above, 7 bar gauge", (P1 + 7e5) / 1000.0, 1, "kPa");
    out("cv, air, per mole", CV, 3, "J/(mol K)");
    out("n cv, heat capacity of the air", n * CV * 1000.0, 2, "mJ/K");
    out("4 to the power 0.4", r.powf(0.4), 4, "");
    out("fast stroke: end temperature", t2, 2, "K");
    out("fast stroke: end temperature, RK4", t2_rk, 2, "K");
    out("fast stroke: end temperature, Celsius", t2 - 273.15, 2, "C");
    out("fast stroke: end pressure", p2 / 1000.0, 1, "kPa");
    out("fast stroke: work on the air", w_fast, 2, "J");
    out("fast stroke: work on the air, RK4", w_rk, 2, "J");
    out("handle force at the end, fast", (p2 - P1) * area, 1, "N");
    out("of the work, pushed by the outside air", P1 * (V1 - V2), 2, "J");
    out("cool-down at 75 cm^3: heat to the room", q_cool, 2, "J");
    out("cool-down: end pressure", p3 / 1000.0, 1, "kPa");
    out("cool-down: air entropy change", ds_air * 1000.0, 2, "mJ/K");
    out("cool-down: air entropy, summed dQ/T", ds_air_sum * 1000.0, 2, "mJ/K");
    out("cool-down: room entropy change", ds_room * 1000.0, 2, "mJ/K");
    out("cool-down: entropy generated", s_gen * 1000.0, 2, "mJ/K");
    out("slow stroke: work = heat to the room", w_slow, 2, "J");
    out("slow stroke: work, Simpson", w_slow_simp, 2, "J");
    out("slow stroke: air entropy change", -n * R * r.ln() * 1000.0, 2, "mJ/K");
    out("lost work, W_fast - W_slow", w_fast - w_slow, 2, "J");
    out("lost work, T0 x S_gen", T0 * s_gen, 2, "J");
    println!("cool-down, step by step (mJ/K): air, room, total");
    let mut bars = Vec::new();
    for t in [t2, 450.0, 400.0, 350.0, 300.0, T0] {
        let a = n * CV * (t / t2).ln() * 1000.0;
        let b = n * CV * (t2 - t) / T0 * 1000.0;
        println!("  air at {:6.2} K {:>9.2} {:>9.2} {:>9.2}", t, a, b, a + b);
        bars.push((36.0 * (a + b) / (s_gen * 1000.0) + 0.5).floor() as i64); // bar length, 36 blocks = the total
    }
    println!("cool-down bars, blocks, 36 for the total:{}", bars.iter().map(|k| format!("{:4}", k)).collect::<String>());
    let claim_a = n * CV * (450.0 / T1).ln() - n * R * r.ln();
    let claim_b = -n * R * r.ln() + 35.0 / T0;
    out("claim: insulated, ends at 450 K, total dS", claim_a * 1000.0, 2, "mJ/K");
    out("claim: 35 J and back to 20 C, total dS", claim_b * 1000.0, 2, "mJ/K");
    out("wrong: Celsius in T V^0.4 rule", (T1 - 273.15) * r.powf(0.4), 2, "C");
    out("wrong: Boyle for the fast stroke", P1 * r / 1000.0, 1, "kPa");
    out("wrong: Boyle handle force", (P1 * r - P1) * area, 1, "N");
    out("wrong: air's dS as -Q/T0, total", (-q_cool / T0 + ds_room) * 1000.0, 2, "mJ/K");
    out("wrong: sign of W flipped, end temperature", T1 - w_fast / (n * CV), 2, "K");
    out("two stages of 2:1, cooled between", 2.0 * fast(CV, 2.0).1, 2, "J");
    out("diesel 18:1 from 20 C", fast(CV, 18.0).0, 1, "K");
    out("try: squeeze to 37.5 cm^3, end temperature", fast(CV, 8.0).0, 1, "K");
    out("try: helium, end temperature", fast(1.5 * R, r).0, 1, "K");
    out("try: helium, end pressure", n * R * fast(1.5 * R, r).0 / V2 / 1000.0, 1, "kPa");
    out("try: claim of 45 J, total dS", (-n * R * r.ln() + 45.0 / T0) * 1000.0, 2, "mJ/K");
    let vols = [300.0_f64, 250.0, 200.0, 150.0, 100.0, 75.0];
    let row = |g: &dyn Fn(f64) -> String| vols.iter().map(|&v| g(v)).collect::<Vec<_>>().join(" ");
    println!("chart, volume cm^3      {}", row(&|v| format!("{:6}", v as i64)));
    println!("chart, fast stroke kPa  {}", row(&|v| format!("{:6.1}", P1 * (V1 / (v * 1e-6)).powf(1.4) / 1000.0)));
    println!("chart, slow stroke kPa  {}", row(&|v| format!("{:6.1}", P1 * V1 / (v * 1e-6) / 1000.0)));

    assert!((t2_rk - t2).abs() < 1e-6 && (w_rk - w_fast).abs() < 1e-6, "RK4 walk must land on the closed form");
    assert!((w_slow_simp - w_slow).abs() < 1e-6, "Simpson must land on n R T ln r");
    assert!((ds_air_sum - ds_air).abs() < 1e-8, "summed dQ/T must land on n cv ln(T0/T2)");
    assert!(((w_fast - w_slow) - T0 * s_gen).abs() < 1e-9, "lost work equals T0 times entropy generated");
    assert!((p2 - P1 * r.powf(1.4)).abs() < 1e-6, "ideal gas law and p V^gamma give the same end pressure");
    assert!(s_gen > 0.0 && claim_a < 0.0 && claim_b < 0.0, "cooling allowed; both claims ruled out");
    println!("ALL CHECKS PASS");
}
