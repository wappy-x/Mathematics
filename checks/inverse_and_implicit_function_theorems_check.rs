// Inverse and implicit function theorems -- the same check as the Python, in
// Rust.  No crates.  One mole of gas: p in kPa, V in litres, T in kelvin, and
// F(p, V, T) = pV - nRT = 0.  Road 1 is the theorems' formula; road 2 solves
// F = 0 for V by halving and takes shrinking difference quotients.
const N: f64 = 1.0;
const R: f64 = 8.314;                      // kPa L per (mol K)
const P: f64 = 100.0;
const T: f64 = 300.0;                      // the known state
const A: f64 = 364.0;
const B: f64 = 0.04267;                    // van der Waals constants for carbon dioxide

fn ideal(p: f64, v: f64, t: f64) -> f64 { p * v - N * R * t }
fn vdw(p: f64, v: f64, t: f64) -> f64 { (p + A * N * N / (v * v)) * (v - N * B) - N * R * t }
fn solve(f: fn(f64, f64, f64) -> f64, p: f64, t: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {                      // F < 0 below the root, > 0 above it
        let mid = (lo + hi) / 2.0;
        if f(p, mid, t) < 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn gas(p: f64, t: f64) -> f64 { solve(ideal, p, t, 0.05, 500.0) }
fn co2(p: f64, t: f64) -> f64 { solve(vdw, p, t, 0.05, 500.0) }

fn main() {
    let v = gas(P, T);
    let (fp, fv, ft) = (v, P, -N * R);     // the three partials of pV - nRT
    let (dvdt, dvdp) = (-ft / fv, -fp / fv); // road 1: implicit function theorem
    let (s, c) = (-N * R * T / (v * v), N * R / v); // Jacobian of (V, T) -> (p, T)
    let inv_row = (1.0 / s, -c / s);       // top row of its inverse matrix
    println!("state: n = {:.0} mol, p = {:.0} kPa, T = {:.0} K; V by halving {:.6} L; |F| = {:.9}", N, P, T, v, ideal(P, v, T).abs());
    println!("partials: dF/dp = {:.6}, dF/dV = {:.6}, dF/dT = {:.6}", fp, fv, ft);
    println!("road 1, implicit: dV/dT = {:.6} L per K, dV/dp = {:.6} L per kPa", dvdt, dvdp);
    println!("inverse theorem: Jacobian [[{:.6}, {:.6}], [0, 1]], det {:.6}; inverse top row {:.6}, {:.6}", s, c, s, inv_row.0, inv_row.1);
    let mut errs = Vec::new();
    for k in [1.0_f64, 0.1, 0.01, 0.001] { // road 2: shrinking pressure steps
        let q = (gas(P + k, T) - v) / k;
        errs.push(q - dvdp);
        println!("road 2, pressure step {:?} kPa: quotient {:.6}, error {:.6}", k, q, q - dvdp);
    }
    let qt = (gas(P, T + 1e-3) - gas(P, T - 1e-3)) / 2e-3;
    println!("road 2, temperature: central quotient {:.6} L per K", qt);
    let (mut lo, mut hi) = (0.0_f64, 10.0_f64); // largest pressure step within 0.001
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (gas(P + mid, T) - v) / mid - dvdp < 0.001 { lo = mid } else { hi = mid }
    }
    println!("tolerance: every pressure step under {:.5} kPa lands within 0.001 of {:.6}", lo, dvdp);
    let (lin, exact) = (3.0 * dvdt + 2.0 * dvdp, gas(P + 2.0, T + 3.0) - v);
    println!("3 K warmer and 2 kPa more: predicted change {:.6} L, solved change {:.6} L", lin, exact);
    let ps = [80.0, 90.0, 100.0, 110.0, 120.0];
    let iso: Vec<String> = ps.iter().map(|&p| format!("{:.2}", gas(p, T))).collect();
    let tan: Vec<String> = ps.iter().map(|&p| format!("{:.2}", v + dvdp * (p - P))).collect();
    println!("chart, V on the 300 K isotherm: {}", iso.join(", "));
    println!("chart, tangent line at 100 kPa: {}", tan.join(", "));
    let w = co2(P, T);                     // second case: no tidy formula for V
    let wv = P - A * N * N / (w * w) + 2.0 * A * B * N.powi(3) / w.powi(3);
    let wq = (co2(P, T + 1e-3) - co2(P, T - 1e-3)) / 2e-3;
    println!("CO2 (a = {:.0}, b = {}) at the same state: V {:.6} L; dF/dV {:.6}; dV/dT implicit {:.6}, quotient {:.6}", A, B, w, wv, N * R / wv, wq);
    let (vc, tc, pc) = (3.0 * B, 8.0 * A / (27.0 * R * B), A / (27.0 * B * B));
    let fc = pc - A / vc.powi(2) + 2.0 * A * B / vc.powi(3);
    let vs = solve(vdw, pc, tc, 0.05, 1.0);
    let qc: Vec<f64> = [1.0, 0.001].iter().map(|&k| (solve(vdw, pc + k, tc, 0.05, 1.0) - vs) / k).collect();
    println!("CO2 critical point: V {:.5} L (halving: {:.5}), T {:.2} K, p {:.1} kPa; |dF/dV| {:.9}", vc, vs, tc, pc, fc.abs());
    println!("critical quotients for pressure steps 1 and 0.001 kPa: {:.6}, {:.6}", qc[0], qc[1]);
    println!("mistake 1, minus dropped: dV/dT = {:.6}; mistake 2, ratio upside down: {:.6}", ft / fv, -fv / ft);
    println!("mistake 3, p = 0 and T = 0: F at V = 1, 10, 100 is {:.0}, {:.0}, {:.0}; at T = 1 K it is {:.3} for every V",
             ideal(0.0, 1.0, 0.0), ideal(0.0, 10.0, 0.0), ideal(0.0, 100.0, 0.0), ideal(0.0, 1.0, 1.0));
    assert!(errs[3].abs() < 1e-5 && errs[1] / errs[2] > 9.0 && errs[1] / errs[2] < 11.0); // quotients close
    assert!((inv_row.1 - qt).abs() < 1e-8 && (dvdt - qt).abs() < 1e-8); // both theorems vs solver
    assert!((N * R / wv - wq).abs() < 1e-8);                       // CO2: formula vs solver
    assert!(qc[1] / qc[0] > 50.0);                                 // no finite rate at dF/dV = 0
    println!("ALL CHECKS PASS");
}
