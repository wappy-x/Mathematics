// CVA risk numbers and hedging -- the same check as cva_risk_numbers_and_hedging_check.py, in Rust.
// Standard library only, no crates.  Road 1: closed forms and their derivatives.
// Road 2: CVA as a double integral, every risk number by bump and revalue.
// Compile: rustc --edition 2021 -O cva_risk_numbers_and_hedging_check.rs -o /tmp/cva_check
use std::f64::consts::PI;

const K: f64 = 100.0; const R_: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0; const REC: f64 = 0.40;
const S0: f64 = 100.0; const VOL0: f64 = 0.20; const LAM: f64 = 0.02; const BP: f64 = 1e-4;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 {                          // 1/2 + phi(x) (x + x^3/3 + x^5/(3*5) + ...)
    if x > 10.0 { return 1.0; }
    if x < -10.0 { return 0.0; }
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() { n += 1.0; term *= x * x / (2.0 * n + 1.0); total += term; }
    0.5 + phi(x) * total
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn call(s: f64, vol: f64, t: f64) -> f64 {        // Black-Scholes call with t years left
    if t <= 0.0 { return (s - K).max(0.0); }
    let d1 = ((s / K).ln() + (R_ - Q + 0.5 * vol * vol) * t) / (vol * t.sqrt());
    s * (-Q * t).exp() * ncdf(d1) - K * (-R_ * t).exp() * ncdf(d1 - vol * t.sqrt())
}
// ---- road 1: closed forms ----
fn cva1(s: f64, vol: f64, sp: f64) -> f64 { (1.0 - REC) * call(s, vol, T) * (1.0 - (-sp / (1.0 - REC) * T).exp()) }
fn cds1(s_now: f64, s0: f64, m: f64, tenor: f64) -> f64 {
    let h = s_now / (1.0 - REC); let k = R_ + h;
    m * (1.0 - (-k * tenor).exp()) / k * (s_now - s0)
}
// ---- road 2: integrals, no closed form for CVA or the CDS legs ----
fn dee(s: f64, vol: f64, t: f64) -> f64 {         // discounted expected exposure at date t
    if t == 0.0 { return call(s, vol, T); }
    let g = |z: f64| phi(z) * call(s * ((R_ - Q - 0.5 * vol * vol) * t + vol * t.sqrt() * z).exp(), vol, T - t);
    let a = if t < T { -8.0 } else { ((K / s).ln() - (R_ - Q - 0.5 * vol * vol) * t) / (vol * t.sqrt()) }; // kink at expiry
    (-R_ * t).exp() * simpson(g, a, 8.0, 2000)
}
fn cva2(s: f64, vol: f64, sp: f64) -> f64 {
    let h = sp / (1.0 - REC);
    (1.0 - REC) * simpson(|t| dee(s, vol, t) * h * (-h * t).exp(), 0.0, T, 10)
}
fn cds2(s_now: f64, s0: f64, m: f64, tenor: f64) -> f64 {
    let h = s_now / (1.0 - REC);
    let ann = simpson(|t| (-(R_ + h) * t).exp(), 0.0, tenor, 200);
    let prot = (1.0 - REC) * simpson(|t| (-R_ * t).exp() * h * (-h * t).exp(), 0.0, tenor, 200);
    m * (prot - s0 * ann)
}

fn main() {
    let s0 = LAM * (1.0 - REC);
    let c = call(S0, VOL0, T);
    let pd = 1.0 - (-LAM * T).exp();
    let d1 = ((S0 / K).ln() + (R_ - Q + 0.5 * VOL0 * VOL0) * T) / (VOL0 * T.sqrt());
    let (c_delta, c_vega) = ((-Q * T).exp() * ncdf(d1), S0 * (-Q * T).exp() * phi(d1) * T.sqrt() / 100.0);
    let (cva, cva_2) = (cva1(S0, VOL0, s0), cva2(S0, VOL0, s0));
    let cs01_an = c * T * (-LAM * T).exp() * BP;     // dCVA/ds = C T e^{-hT}: the (1-R) cancels
    let cs01_bp = (cva2(S0, VOL0, s0 + BP) - cva2(S0, VOL0, s0 - BP)) / 2.0;
    let ann1 = (1.0 - (-(R_ + LAM) * T).exp()) / (R_ + LAM);
    let cds_cs01 = (cds2(s0 + BP, s0, 1.0, T) - cds2(s0 - BP, s0, 1.0, T)) / 2.0;
    let m_cs01 = cs01_bp / cds_cs01;
    let jtd = (1.0 - REC) * c - cva;                 // the risky price falls to recovery times C
    let m_jtd = jtd / (1.0 - REC);
    let (dl_an, vg_an) = ((1.0 - REC) * pd * c_delta, (1.0 - REC) * pd * c_vega);
    let dl_bp = (cva2(S0 + 0.5, VOL0, s0) - cva2(S0 - 0.5, VOL0, s0)) / 1.0;
    let vg_bp = (cva2(S0, VOL0 + 0.01, s0) - cva2(S0, VOL0 - 0.01, s0)) / 2.0;
    let m_5y = cs01_bp / ((1.0 - (-(R_ + LAM) * 5.0).exp()) / (R_ + LAM) * BP);

    let rows: Vec<(&str, f64)> = vec![("call C", c), ("Northwind spread s = h(1-R), bp", s0 / BP),
        ("default chance by T, 1-e^-hT", pd), ("survival to T, e^-hT", 1.0 - pd),
        ("1 CVA formula (1-R) C (1-e^-hT)", cva), ("2 CVA by double integral", cva_2),
        ("  DEE at t = 0.5, integral", dee(S0, VOL0, 0.5)), ("  DEE at t = 1, integral", dee(S0, VOL0, 1.0)),
        ("rule of thumb s C T", s0 * c * T), ("risky price C - CVA", c - cva),
        ("CS01 analytic C T e^-hT x 1bp", cs01_an), ("CS01 by bump, road 2", cs01_bp),
        ("CDS annuity A = (1-e^-(r+h)T)/(r+h)", ann1), ("CDS CS01 per $1 by bump, x 1e4", cds_cs01 * 1e4),
        ("hedge notional by CS01", m_cs01), ("jump-to-default loss (1-R)C - CVA", jtd),
        ("hedge notional by jump-to-default", m_jtd),
        ("CVA delta analytic", dl_an), ("CVA delta by bump, road 2", dl_bp), ("  call's own delta", c_delta),
        ("CVA vega per vol point, analytic", vg_an), ("CVA vega by bump, road 2", vg_bp), ("  call's own vega", c_vega),
        ("greek ratio (1-R)(1-e^-hT)", (1.0 - REC) * pd),
        ("wrong: CS01 per bp of hazard", cva1(S0, VOL0, s0 + (1.0 - REC) * BP) - cva),
        ("wrong: CVA on undiscounted exposure", (1.0 - REC) * LAM * c * (((R_ - LAM) * T).exp() - 1.0) / (R_ - LAM)),
        ("wrong: 5y CDS notional by CS01", m_5y),
        ("try: notional if spread 300bp", c * T * (-0.05 * T).exp() / ((1.0 - (-0.10_f64).exp()) / 0.10)),
        ("try: notional if Acme 110", call(110.0, VOL0, T) * T * (-LAM * T).exp() / ann1),
        ("try: CVA if recovery 0, same spread", c * (1.0 - (-s0 * T).exp()))];
    for (name, v) in &rows { println!("{:<38}{:>14.6}", name, v); }

    // desk is short CVA, long m of CDS and some shares
    let pnl = |ds_: f64, dsp: f64, m: f64, sh: f64| -(cva1(S0 + ds_, VOL0, s0 + dsp) - cva) + cds1(s0 + dsp, s0, m, T) + sh * ds_;
    println!("{:<28}{:>10}{:>12}{:>11}{:>11}", "scenario, $ per option", "unhedged", "CS01 hedge", "JTD hedge", "call delta");
    for (lab, ds_, dsp) in [("spread +10bp", 0.0, 10.0 * BP), ("spread +100bp", 0.0, 100.0 * BP), ("Acme +5", 5.0, 0.0),
                            ("Acme +5 and spread +100bp", 5.0, 100.0 * BP)] {
        println!("{:<28}{:>10.4}{:>12.4}{:>11.4}{:>11.4}", lab, pnl(ds_, dsp, 0.0, 0.0), pnl(ds_, dsp, m_cs01, dl_an),
                 pnl(ds_, dsp, m_jtd, dl_an), pnl(ds_, dsp, m_cs01, c_delta));
    }
    let dflt = |m: f64| -jtd + m * (1.0 - REC);      // default now: pay (1-R)C, release CVA, CDS pays M(1-R)
    println!("{:<28}{:>10.4}{:>12.4}{:>11.4}{:>11.4}", "Northwind defaults now", dflt(0.0), dflt(m_cs01), dflt(m_jtd), dflt(m_cs01));
    println!("{:<28}{:>10}{:>12.4}", "  5y CDS sized by CS01", "", dflt(m_5y));

    let row = |lab: &str, xs: &[i32], f: &dyn Fn(f64) -> f64| {
        let v: Vec<String> = xs.iter().map(|&x| format!("{:>7.2}", f(x as f64))).collect();
        println!("{}{}", lab, v.join(" "));
    };
    let grid = [0, 100, 200, 300, 400, 500, 600];
    println!("chart, spread bp       {}", grid.iter().map(|x| format!("{:>7}", x)).collect::<Vec<_>>().join(" "));
    row("chart, CVA cents       ", &grid, &|x| 100.0 * cva1(S0, VOL0, x * BP));
    row("chart, CS01 line cents ", &grid, &|x| 100.0 * (cva + cs01_an * (x - 120.0)));
    let moves = [0, 60, 120, 180, 240, 300, 360];
    println!("chart, spread after bp {}", moves.iter().map(|x| format!("{:>7}", x)).collect::<Vec<_>>().join(" "));
    row("chart, unhedged cents  ", &moves, &|x| 100.0 * pnl(0.0, (x - 120.0) * BP, 0.0, 0.0));
    row("chart, CS01 hedge cents", &moves, &|x| 100.0 * pnl(0.0, (x - 120.0) * BP, m_cs01, 0.0));
    row("chart, JTD hedge cents ", &moves, &|x| 100.0 * pnl(0.0, (x - 120.0) * BP, m_jtd, 0.0));

    assert!((cva_2 - cva).abs() < 1e-9, "double integral must land on the closed form");
    assert!([0.5, 1.0].iter().all(|&t| (dee(S0, VOL0, t) - c).abs() < 1e-9), "discounted exposure is flat at C");
    assert!((cs01_bp - cs01_an).abs() < 1e-10, "bumped CS01 vs C T e^-hT");
    assert!((cds_cs01 / BP - ann1).abs() < 1e-8, "CDS CS01 per bp vs the annuity");
    assert!((dl_bp - dl_an).abs() < 1e-6, "delta by bump vs (1-R) pd x call delta");
    assert!((vg_bp - vg_an).abs() < 1e-6, "vega by bump vs (1-R) pd x call vega");
    assert!(pnl(0.0, 10.0 * BP, m_cs01, dl_an).abs() < 0.01 * pnl(0.0, 10.0 * BP, 0.0, 0.0).abs(), "CS01 hedge kills 99% of a 10bp move");
    println!("ALL CHECKS PASS");
}
