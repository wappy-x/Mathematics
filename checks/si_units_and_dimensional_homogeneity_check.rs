// Units and dimensions -- the same check as si_units_and_dimensional_homogeneity_check.py.  Std only.
// Road 1: exponent arithmetic.  Road 2: change the units and see whether the answer moves.
// Road 3: rebuild the pressure drop from a force balance on rings of water, step by step.
use std::f64::consts::PI;

type Dim = [i32; 7];
const BASE: [&str; 7] = ["M", "L", "T", "I", "Θ", "N", "J"];

fn dim(m: i32, l: i32, t: i32) -> Dim { [m, l, t, 0, 0, 0, 0] } // this card needs only the first three
fn mul(ds: &[Dim]) -> Dim {
    let mut o = [0; 7];
    for d in ds { for i in 0..7 { o[i] += d[i]; } }
    o
}
fn pw(d: Dim, p: i32) -> Dim { let mut o = d; for c in o.iter_mut() { *c *= p; } o }
fn show(d: Dim) -> String {
    let parts: Vec<String> = (0..7).filter(|&i| d[i] != 0)
        .map(|i| if d[i] == 1 { BASE[i].to_string() } else { format!("{}^{}", BASE[i], d[i]) }).collect();
    if parts.is_empty() { "1 (pure number)".to_string() } else { parts.join(" ") }
}
// SI size of one new unit of a quantity with dimension d, in a system of (metres, kilograms, seconds) per unit
fn in_units(d: Dim, s: (f64, f64, f64)) -> f64 { s.0.powi(d[1]) * s.1.powi(d[0]) * s.2.powi(d[2]) }

struct Formula { name: &'static str, coef: f64, pows: [i32; 4] } // powers of mu, l, Q, D
fn evaluate(f: &Formula, v: [f64; 4]) -> f64 {
    let mut out = f.coef;
    for k in 0..4 { out *= v[k].powi(f.pows[k]); }
    out
}

fn flow_for(dp_try: f64, mu: f64, ell: f64, d: f64, n: usize) -> (f64, Vec<f64>) {
    let h = d / 2.0 / n as f64;
    let mut u = vec![0.0; n + 1];
    for i in (1..=n).rev() { // trapezoid step from r_i to r_(i-1)
        let t1 = dp_try / ell * (i as f64 * h) / 2.0;
        let t0 = dp_try / ell * ((i - 1) as f64 * h) / 2.0;
        u[i - 1] = u[i] + h * (t1 + t0) / 2.0 / mu;
    }
    let g: Vec<f64> = (0..=n).map(|i| 2.0 * PI * (i as f64 * h) * u[i]).collect();
    let mut s = g[0] + g[n];
    for i in 1..n { s += if i % 2 == 1 { 4.0 * g[i] } else { 2.0 * g[i] }; }
    (h / 3.0 * s, u)
}

fn main() {
    let (mass, len, time) = (dim(1, 0, 0), dim(0, 1, 0), dim(0, 0, 1));
    let accel = mul(&[len, pw(time, -2)]);
    let force = mul(&[mass, accel]); // newton = kg m s^-2
    let pressure = mul(&[force, pw(len, -2)]); // pascal = newton per square metre
    let visc = mul(&[pressure, time]);
    let flow = mul(&[pw(len, 3), pw(time, -1)]);
    let speed = mul(&[len, pw(time, -1)]);
    let density = mul(&[mass, pw(len, -3)]);
    for (name, d) in [("force N", force), ("pressure Pa", pressure), ("viscosity Pa s", visc),
                      ("flow rate m^3/s", flow), ("density kg/m^3", density)] {
        println!("dims {:<22}{}", name, show(d));
    }

    // the drip tube: water at 20 C (NIST WebBook), 2 mm bore, 1 m long, 1 mL/s
    let (mu, rho, ell, q, d, gn) = (1.0016e-3, 998.21, 1.0, 1.0e-6, 2.0e-3, 9.80665);
    let (re_lam, bl_lo, bl_hi) = (2300.0, 4000.0, 1.0e5); // laminar limit; Blasius range (White)
    println!("inputs mu {:.4} mPa s, rho {:.2} kg/m^3, l {:.1} m, D {:.1} mm, Q {:.1} mL/s, g_n {:.5} m/s^2", 1000.0 * mu, rho, ell, 1000.0 * d, 1e6 * q, gn);
    println!("limits laminar below Re {:.0}; Blasius for Re {:.0} to {:.0}", re_lam, bl_lo, bl_hi);
    let ins = [visc, len, flow, len];
    let formulas = [
        Formula { name: "128 mu l Q / (pi D^4)", coef: 128.0 / PI, pows: [1, 1, 1, -4] },
        Formula { name: "32 mu l Q / D^2", coef: 32.0, pows: [1, 1, 1, -2] },
        Formula { name: "128 mu l Q / (pi D^3)", coef: 128.0 / PI, pows: [1, 1, 1, -3] },
    ];
    let systems = [("cm g s", (0.01, 0.001, 1.0)), ("ft lb min", (0.3048, 0.45359237, 60.0))]; // road 1's forecast
    // road 2: each input's own unit, its SI size written out by hand: [mu, l, Q, D, pressure]; no exponent list
    let (lb, ft, min) = (0.45359237, 0.3048, 60.0);
    let hand = [[0.1, 0.01, 1.0e-6, 0.01, 0.1], // poise, cm, cm^3/s, cm, barye
                [lb / (ft * min), ft, ft * ft * ft / min, ft, lb / (ft * min * min)]];
    let si_vals = [mu, ell, q, d];
    for (s, (a, b, c)) in systems.iter() { println!("system {:<10} one unit = {:.4} m, {:.8} kg, {:.0} s", s, a, b, c); }
    let mut verdicts = Vec::new();
    let mut ratios = Vec::new(); // (formula index, ratio, forecast)
    for (fi, f) in formulas.iter().enumerate() {
        let terms: Vec<Dim> = (0..4).map(|k| pw(ins[k], f.pows[k])).collect();
        let dd = mul(&terms);
        let p_si = evaluate(f, si_vals);
        let verdict = if dd == pressure { "PASS" } else { "REJECT" };
        verdicts.push(verdict);
        println!("check {:<23}{:<14}vs {}  {}", f.name, show(dd), show(pressure), verdict);
        println!("  SI answer read as Pa       {:14.6}", p_si);
        for (si, (s, sysf)) in systems.iter().enumerate() {
            let h = hand[si];
            let mut nv = [0.0; 4];
            for k in 0..4 { nv[k] = si_vals[k] / h[k]; }
            let back = evaluate(f, nv) * h[4]; // read as a pressure, convert to Pa
            let diff = mul(&[dd, pw(pressure, -1)]);
            let predicted = 1.0 / in_units(diff, *sysf); // road 1's forecast of the drift
            ratios.push((fi, back / p_si, predicted));
            println!("  in {:<10} back in Pa {:14.6}  ratio {:12.6}  forecast {:12.6}", s, back, back / p_si, predicted);
        }
    }

    let dp = evaluate(&formulas[0], si_vals);
    let area = PI * d * d / 4.0;
    let v = q / area;
    let re = rho * v * d / mu;
    println!("bore area mm^2               {:14.6}", 1e6 * area);
    println!("mean speed v = Q/area m/s    {:14.6}", v);
    println!("mu l Q / D^4 Pa              {:14.6}  times 128/pi = {:.6}", mu * ell * q / d.powi(4), 128.0 / PI);
    println!("Reynolds rho v D / mu        {:14.4}  dims {}", re, show(mul(&[density, speed, len, pw(visc, -1)])));
    println!("32 mu l v / D^2 Pa           {:14.6}", 32.0 * mu * ell * v / (d * d));
    println!("head dp/(rho g) cm           {:14.4}", 100.0 * dp / (rho * gn));
    println!("exit head 2 v^2/(2 g) cm     {:14.4}  entry length 0.06 Re D {:.4} cm", 100.0 * v * v / gn, 100.0 * 0.06 * re * d);

    // road 3: shear tau = (dp/l) r / 2 from a force balance; du/dr = -tau/mu from the wall; flow is linear in dp
    let (q1, _) = flow_for(1.0, mu, ell, d, 20000);
    let dp_road3 = q / q1;
    let (_, prof) = flow_for(dp_road3, mu, ell, d, 20000);
    println!("dp closed form Pa            {:14.6}", dp);
    println!("dp force balance Pa          {:14.6}", dp_road3);
    let rs: Vec<String> = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0].iter().map(|x: &f64| format!("{:6.2}", x)).collect();
    println!("chart, r (mm)          {}", rs.join(" "));
    let us: Vec<String> = [-4i32, -3, -2, -1, 0, 1, 2, 3, 4].iter()
        .map(|k| format!("{:6.0}", 1000.0 * prof[(k.unsigned_abs() as usize) * 5000])).collect();
    println!("chart, u (mm/s)        {}", us.join(" "));

    // what breaks: a mixed-unit version, and the laminar formula outside its range
    let k = evaluate(&formulas[0], [1e-3, 1.0, 1e-6, 1e-3]) / 1000.0;
    let mixed_ok = k * (1000.0 * mu) * ell * (1e6 * q) / (1000.0 * d).powi(4); // fed its own units
    let mixed_bad = k * mu * ell * q / d.powi(4);
    println!("mixed-unit constant K        {:14.6}  (kPa, with mPa s, m, mL/s, mm)", k);
    println!("mixed form, own units kPa   {:14.6}", mixed_ok);
    println!("mixed form, SI numbers kPa   {:14.6}", mixed_bad);
    println!("mixed form, SI over own      {:14.6}", mixed_bad / mixed_ok);
    let q10 = 1.0e-5;
    let v10 = q10 / area;
    let re10 = rho * v10 * d / mu;
    let lam10 = evaluate(&formulas[0], [mu, ell, q10, d]);
    let f_bl = 0.316 / re10.powf(0.25); // Blasius, smooth tube, 4000 < Re < 1e5 (White)
    let turb10 = f_bl * (ell / d) * rho * v10 * v10 / 2.0;
    println!("at 10 mL/s: Re               {:14.4}", re10);
    println!("at 10 mL/s: laminar Pa       {:14.4}", lam10);
    println!("at 10 mL/s: Blasius Pa       {:14.4}  friction factor {:.6}", turb10, f_bl);

    assert_eq!(verdicts, vec!["PASS", "REJECT", "REJECT"], "road 1: exponent check on the three quoted formulas");
    assert!(ratios.iter().filter(|r| r.0 == 0).all(|r| (r.1 - 1.0).abs() < 1e-12), "road 2: right formula ignores units");
    assert!(ratios.iter().all(|r| (r.1 / r.2 - 1.0).abs() < 1e-9), "road 2 drift equals road 1 forecast");
    assert!((dp_road3 / dp - 1.0).abs() < 1e-9, "road 3: force balance lands on the closed form");
    assert!((mixed_ok * 1000.0 / dp_road3 - 1.0).abs() < 1e-9, "mixed-unit form, fed its own units, meets the force balance");
    assert!(re < re_lam, "laminar at 1 mL/s");
    assert!(bl_lo < re10 && re10 < bl_hi, "turbulent, inside the Blasius range, at 10 mL/s");
    assert!(turb10 > 3.0 * lam10, "outside its range the laminar formula is off by more than 3x");
    println!("ALL CHECKS PASS");
}
