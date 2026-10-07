// The RLC circuit and the spring -- the same check as the Python, in Rust.  No
// crates.  A 10 V battery is switched onto L = 1 H, R = 2 ohm, C = 0.2 F in series,
// capacitor empty, no current.  Road one: the closed form from the roots of
// L r^2 + R r + 1/C = 0.  Road two: Euler steps on Kirchhoff's loop rule itself,
// q' = i and L i' = V - R i - q/C, which never solves anything.  Road three: the
// heat R i^2 summed step by step, against the energy the battery leaves unstored.
use std::f64::consts::PI;
const L: f64 = 1.0; // inductance, H
const R: f64 = 2.0; // resistance, ohm
const C: f64 = 0.2; // capacitance, F
const V: f64 = 10.0; // battery, volts

struct Run { q: f64, top: f64, t_top: f64, imax: f64, t_imax: f64, heat: f64, marks: Vec<f64> }

fn euler(res: f64, h: f64, t_end: f64) -> Run { // plain small steps along the slope
    let (mut q, mut i) = (0.0, 0.0);
    let (mut top, mut t_top, mut imax, mut t_imax, mut heat) = (-1.0, 0.0, -1.0, 0.0, 0.0);
    let mut marks = Vec::new();
    let every = (0.5 / h).round() as usize;
    for n in 0..=((t_end / h).round() as usize) {
        let t = n as f64 * h;
        if n % every == 0 { marks.push(q) }
        if q > top { top = q; t_top = t }
        if i > imax { imax = i; t_imax = t }
        heat += res * i * i * h;
        let (q2, i2) = (q + h * i, i + h * (V - res * i - q / C) / L);
        q = q2; i = i2;
    }
    Run { q, top, t_top, imax, t_imax, heat, marks }
}

fn main() {
    let a = -R / (2.0 * L);
    let b = (1.0 / (L * C) - (R / (2.0 * L)).powi(2)).sqrt(); // roots a +/- bi
    let (ca, cb) = (-C * V, -C * V * (-a) / b); // q(0) = 0 and i(0) = 0 fix the constants
    let q = |t: f64| C * V + (a * t).exp() * (ca * (b * t).cos() + cb * (b * t).sin());
    let house = |t: f64| (-t).exp() * ((2.0 * t).cos() + 0.5 * (2.0 * t).sin());
    let rc = 2.0 * (L / C).sqrt(); // critical resistance
    let errs: Vec<f64> = [0.001, 0.0005, 0.00025].iter().map(|&h| (euler(R, h, 5.0).q - q(5.0)).abs()).collect();
    let main_run = euler(R, 1e-4, 20.0);
    let (crit, over) = (euler(rc, 1e-4, 20.0), euler(6.0, 1e-4, 20.0));
    let (tp, ti) = (PI / b, b.atan2(-a) / b); // where i = 0, where i' = 0
    let i_at = |t: f64| (a * a + b * b) * C * V / b * (a * t).exp() * (b * t).sin();
    let gap = (0..51).map(|t| (q(t as f64 / 10.0) - C * V * (1.0 - house(t as f64 / 10.0))).abs()).fold(0.0, f64::max);
    let row = |xs: &[f64]| xs[..11].iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ");
    let qs: Vec<f64> = (0..11).map(|t| q(t as f64 / 2.0)).collect();
    let (stored, battery) = ((C * V).powi(2) / (2.0 * C), V * C * V);
    println!("roots: {:.4} +/- {:.4}i; natural rate 1/sqrt(LC) = {:.4} rad/s; damping ratio {:.4}", a, b, 1.0 / (L * C).sqrt(), R / 2.0 * (C / L).sqrt());
    println!("constants from q(0) = 0, i(0) = 0: A = {:.4}, B = {:.4}; final charge CV = {:.4} C", ca, cb, C * V);
    println!("t (s)          {}", (0..11).map(|t| format!("{:.1}", t as f64 / 2.0)).collect::<Vec<_>>().join(", "));
    println!("R = 2 ohm      {}", row(&qs));
    println!("R = {:.2} ohm   {}", rc, row(&crit.marks));
    println!("R = 6 ohm      {}", row(&over.marks));
    println!("closed form equals CV(1 - house y) every 0.1 s to 5 s, within 1e-12: {}", if gap < 1e-12 { "yes" } else { "no" });
    println!("peak, closed form: {:.4} C at {:.4} s; capacitor voltage {:.4} V", q(tp), tp, q(tp) / C);
    println!("peak, Euler h = 0.0001: {:.4} C at {:.4} s", main_run.top, main_run.t_top);
    println!("largest current: closed {:.4} A at {:.4} s; Euler {:.4} A at {:.4} s", i_at(ti), ti, main_run.imax, main_run.t_imax);
    println!("Euler error in q at t = 5, h = 0.001, 0.0005, 0.00025: {}", errs.iter().map(|e| format!("{:.6}", e)).collect::<Vec<_>>().join(" "));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("energy: battery V CV = {:.4} J; stored (CV)^2/2C = {:.4} J; heat summed by Euler {:.4} J", battery, stored, main_run.heat);
    println!("overshoot fraction e^(pi a/b) = {:.4}; critical R = 2 sqrt(L/C) = {:.4} ohm", (PI * a / b).exp(), rc);
    println!("highest charge at R = {:.4} and 6 ohm: {:.4}, {:.4} C", rc, crit.top, over.top);
    println!("mistake, q times C for q/C: steady charge V/C = {:.2} C, not {:.2}", V / C, C * V);
    println!("mistake, inductor dropped: q = CV(1 - e^(-t/RC)) at {:.2} s is {:.2} C, never above {:.2}", tp, C * V * (1.0 - (-tp / (R * C)).exp()), C * V);
    println!("mistake, all battery energy stored: {:.2} J claimed, {:.2} J in the capacitor", battery, stored);
    assert!(errs[0] / errs[1] > 1.9 && errs[0] / errs[1] < 2.1 && errs[1] / errs[2] > 1.9 && errs[1] / errs[2] < 2.1 && errs[2] < 0.01);
    assert!((main_run.top - q(tp)).abs() < 1e-3 && (main_run.t_top - tp).abs() < 1e-3 && (main_run.imax - i_at(ti)).abs() < 1e-3);
    assert!(gap < 1e-12); // the circuit is the shock absorber, scaled
    assert!((main_run.heat / (battery - stored) - 1.0).abs() < 1e-3 && crit.top < C * V + 1e-9);
    println!("ALL CHECKS PASS");
}
