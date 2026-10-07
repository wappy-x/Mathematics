// Similarity and model testing -- the same check as the Python, in Rust.  No
// crates.  A quarter-scale cycling helmet sits in a wind tunnel.  Which tunnel
// speed, or which tunnel pressure, makes its drag predict the full-size
// helmet's drag, and which dimensionless groups cannot be matched together?
use std::f64::consts::PI;

const R: f64 = 287.05;       // air: gas constant J/(kg K)
const GAMMA: f64 = 1.4;      // ratio of specific heats
const BETA: f64 = 1.458e-6;  // Sutherland's law: kg/(m s K^0.5)
const SUTH: f64 = 110.4;     // Sutherland's law: K
const T: f64 = 293.15;       // 20 C (US Std Atmosphere 1976 constants)
const P0: f64 = 101325.0;    // sea-level pressure, Pa
const DP: f64 = 0.22;        // helmet width, m
const UP: f64 = 12.5;        // rider speed, m/s
const LAM: f64 = 0.25;       // model scale
const DM: f64 = LAM * DP;

fn mu() -> f64 { BETA * T.powf(1.5) / (T + SUTH) }   // Pa s; does not depend on pressure
fn c() -> f64 { (GAMMA * R * T).sqrt() }             // m/s; does not depend on pressure
fn rho(p: f64) -> f64 { p / (R * T) }                // ideal-gas density, kg/m^3
fn reynolds(p: f64, u: f64, d: f64) -> f64 { rho(p) * u * d / mu() }

fn cd(re: f64) -> f64 {              // stand-in drag law: White's smooth-sphere fit, Re <= 2e5
    24.0 / re + 6.0 / (1.0 + re.sqrt()) + 0.4
}

fn drag(p: f64, u: f64, d: f64) -> f64 {   // newtons: dynamic pressure x frontal area x C_D
    0.5 * rho(p) * u * u * (PI * d * d / 4.0) * cd(reynolds(p, u, d))
}

fn predict(fm: f64, pm: f64, um: f64) -> f64 {   // similarity: equal C_D, so scale by rho U^2 D^2
    fm * (rho(P0) * UP.powi(2) * DP.powi(2)) / (rho(pm) * um.powi(2) * DM.powi(2))
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // f(lo) < 0 < f(hi)
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn pct(a: f64, b: f64) -> f64 { 100.0 * (a - b) / b }

fn main() {
    let (mu, c) = (mu(), c());
    let (re_p, ma_p, f_p) = (reynolds(P0, UP, DP), UP / c, drag(P0, UP, DP));
    println!("inputs: R {} J/(kg K), gamma {}, beta {:.3}e-6, S {} K, T {} K, p {:.0} Pa, U {} m/s = {:.1} km/h",
             R, GAMMA, BETA * 1e6, SUTH, T, P0, UP, UP * 3.6);
    println!("air at {:.0} C, 1 atm: rho {:.4} kg/m^3, mu {:.3} uPa s, nu {:.3} mm^2/s, c {:.2} m/s",
             T - 273.15, rho(P0), mu * 1e6, mu / rho(P0) * 1e6, c);
    println!("card 06's value for the same air, mu 1.82e-5 Pa s, is {:+.1} % from Sutherland's", pct(1.82e-5, mu));
    println!("full size: D {:.3} m, U {:.1} m/s, Re {:.0}, Ma {:.4}, C_D {:.4}, drag {:.4} N, power {:.2} W",
             DP, UP, re_p, ma_p, cd(re_p), f_p, f_p * UP);
    println!("by hand: sqrt(Re) {:.2}, 24/Re {:.5}, 6/(1 + sqrt(Re)) {:.5}, q {:.2} Pa, A {:.5} m^2",
             re_p.sqrt(), 24.0 / re_p, 6.0 / (1.0 + re_p.sqrt()), 0.5 * rho(P0) * UP.powi(2), PI * DP.powi(2) / 4.0);
    println!("model: D {:.3} m, scale 1/{:.0}", DM, 1.0 / LAM);
    // Case 1: atmospheric tunnel at the rider's own speed.
    let f1 = drag(P0, UP, DM);
    let pr1 = predict(f1, P0, UP);
    println!("case 1, 1 atm, {:.1} m/s: Re {:.0}, Ma {:.4}, model drag {:.4} N, predicts {:.4} N, error {:+.2} %, {:.2} W",
             UP, reynolds(P0, UP, DM), UP / c, f1, pr1, pct(pr1, f_p), (pr1 - f_p) * UP);
    // Case 2: atmospheric tunnel, speed chosen to match Re.  Two roads to that speed.
    let u2_formula = UP * DP / DM;
    let u2_root = bisect(&|u| reynolds(P0, u, DM) - re_p, 1.0, 200.0);
    let f2 = drag(P0, u2_formula, DM);
    let pr2 = predict(f2, P0, u2_formula);
    println!("case 2, 1 atm, Re matched: speed by formula {:.6} m/s, by root finder {:.6} m/s", u2_formula, u2_root);
    println!("case 2: Re {:.0}, Ma {:.4}, model drag {:.4} N, predicts {:.4} N, size of error {:.9} %",
             reynolds(P0, u2_formula, DM), u2_formula / c, f2, pr2, pct(pr2, f_p).abs());
    // Case 3: pressurised tunnel at the rider's speed, so Ma matches; pressure matches Re.
    let p3_formula = P0 * DP / DM;
    let p3_root = bisect(&|p| reynolds(p, UP, DM) - re_p, P0, 20.0 * P0);
    let f3 = drag(p3_formula, UP, DM);
    let pr3 = predict(f3, p3_formula, UP);
    println!("case 3, Ma matched at {:.1} m/s: pressure by formula {:.6} atm, by root finder {:.6} atm",
             UP, p3_formula / P0, p3_root / P0);
    println!("case 3: Re {:.0}, Ma {:.4}, model drag {:.4} N, predicts {:.4} N, size of error {:.9} %",
             reynolds(p3_formula, UP, DM), UP / c, f3, pr3, pct(pr3, f_p).abs());
    // The clash: in one fixed air, Re wants U_m = U_p / LAM, Ma wants U_m = U_p.
    println!("same air: Re needs {:.1} m/s, Ma needs {:.1} m/s; both only at scale 1", UP / LAM, UP);
    println!("density change, about Ma^2/2: full size {:.2} %, Re-matched model {:.2} %, at Ma 0.3 {:.2} %",
             ma_p * ma_p / 2.0 * 100.0, (u2_formula / c).powi(2) / 2.0 * 100.0, 0.3_f64 * 0.3 / 2.0 * 100.0);
    let lam_min_formula = UP / (0.3 * c);
    let lam_min_scan = (1..=10000).map(|k| k as f64 / 10000.0).find(|&l| UP / l / c <= 0.3).unwrap();
    println!("smallest scale keeping Ma <= 0.3 with Re matched at 1 atm: formula {:.4} (1/{:.2}), scan {:.4}",
             lam_min_formula, 1.0 / lam_min_formula, lam_min_scan);
    println!("outside the range: a 1/10 model needs {:.0} m/s, Ma {:.4}; a 20 m/s descent has Re {:.0}, past the fit's 200000",
             UP * 10.0, UP * 10.0 / c, reynolds(P0, 20.0, DP));
    println!("fit's edge: the model's Re reaches 200000 at {:.1} m/s", 200000.0 * mu / (rho(P0) * DM));
    // Unit-change road: feet, pounds, minutes.  The numbers move; Re, Ma and C_D do not.
    let (ft, lb, min) = (0.3048, 0.45359237, 60.0);
    let rho_i = rho(P0) / (lb / (ft * ft * ft));
    let (u_i, d_i, mu_i, c_i) = (UP / (ft / min), DP / ft, mu / (lb / (ft * min)), c / (ft / min));
    let f_i = f_p / (lb * ft / (min * min));
    let re_i = rho_i * u_i * d_i / mu_i;
    let cd_i = f_i / (0.5 * rho_i * u_i * u_i * PI * d_i * d_i / 4.0);
    println!("in ft, lb, min: U {:.1} ft/min, drag {:.1} lb ft/min^2, Re {:.0}, Ma {:.4}, C_D {:.4}",
             u_i, f_i, re_i, u_i / c_i, cd_i);
    // What breaks: three wrong recipes, each from the Re-matched or naive model.
    let area_only = f2 / (LAM * LAM);
    println!("mistake 1, force scaled by area alone: {:.4} N, error {:+.1} %", area_only, pct(area_only, f_p));
    let u_bad = UP * LAM;
    let pr_bad = predict(drag(P0, u_bad, DM), P0, u_bad);
    println!("mistake 2, speed scaled the wrong way, {:.3} m/s: Re {:.0}, predicts {:.4} N, error {:+.2} %",
             u_bad, reynolds(P0, u_bad, DM), pr_bad, pct(pr_bad, f_p));
    let re_both = reynolds(p3_formula, u2_formula, DM);
    println!("mistake 3, 4 atm and 50 m/s together: Re {:.0}, Re ratio {:.2}", re_both, re_both / re_p);
    // Figure points: the model's prediction against tunnel speed, and the two ratios.
    println!("figure, tunnel speed m/s -> predicted full-size drag N (truth {:.3})", f_p);
    let pts: Vec<String> = (10..65).step_by(5)
        .map(|u| format!("{}:{:.3}", u, predict(drag(P0, u as f64, DM), P0, u as f64))).collect();
    println!("  {}", pts.join(", "));
    println!("figure, tunnel speed m/s -> Re_m/Re_p and Ma_m/Ma_p at 1 atm");
    let rat: Vec<String> = (10..70).step_by(10)
        .map(|u| format!("{}:{:.2}/{:.2}", u, reynolds(P0, u as f64, DM) / re_p, u as f64 / c / ma_p)).collect();
    println!("  {}", rat.join(", "));
    assert!((u2_root - u2_formula).abs() < 1e-9 && (p3_root - p3_formula).abs() < 1e-6);   // two roads
    assert!((pr2 - f_p).abs() < 1e-12 * f_p);                                    // matched Re: model = truth
    assert!((pr3 - f_p).abs() < 1e-12 * f_p);                                    // complete similarity
    assert!((re_i - re_p).abs() < 1e-6 * re_p && (cd_i - cd(re_p)).abs() < 1e-9);   // unit-free
    assert!(pct(pr1, f_p) > 1.0);                                                // unmatched Re misleads
    assert!((lam_min_scan - lam_min_formula).abs() < 1e-4);                      // scan meets formula
    println!("ALL CHECKS PASS");
}
