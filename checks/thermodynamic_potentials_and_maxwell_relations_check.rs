// Free energies and Maxwell relations -- the check behind the card.  std only.
// Water boiling at 1 atm, then a sealed heating loop at 1.5 bar gauge.
// Roads: closed forms; bisection on the Gibbs gap; Legendre's minimum found by
// golden-section search; finite differences on explicit state functions; and the
// IAPWS-IF97 saturation curve as a measured-water reference.

const R: f64 = 8.314462618; // molar gas constant, J/(mol K), NIST CODATA 2018 (exact)
const K0: f64 = 273.15; // kelvin = degrees Celsius + 273.15
const P0: f64 = 101325.0; // one atmosphere, Pa
const DH: f64 = 40650.0; // heat to boil one mole at 1 atm (enthalpy of boiling), J/mol
const DS: f64 = 108.9; // entropy of boiling, J/(mol K), as tabulated (four figures)
const TB: f64 = 373.15; // measured boiling point at 1 atm, K
const P_LOOP: f64 = P0 + 150000.0; // sealed loop: 1.5 bar on the gauge, absolute Pa
const CV: f64 = 3.0 * R; // steam as a rigid ideal gas: 3R per mole at fixed volume
const CP: f64 = CV + R; // ... and 4R at fixed pressure
const VL: f64 = 18.80e-6; // liquid water at 100 C, m^3/mol (958.4 kg/m^3)
const E: f64 = 2.718281828459045;

fn if97_psat(t: f64) -> f64 {
    // IAPWS-IF97 region 4: saturation pressure of real water, Pa
    let n = [0.11670521452767e4, -0.72421316703206e6, -0.17073846940092e2,
             0.12020824702470e5, -0.32325550322333e7, 0.14915108613530e2,
             -0.48232657361591e4, 0.40511340542057e6, -0.23855557567849, 0.65017534844798e3];
    let th = t + n[8] / (t - n[9]);
    let a = th * th + n[0] * th + n[1];
    let b = n[2] * th * th + n[3] * th + n[4];
    let c = n[5] * th * th + n[6] * th + n[7];
    (2.0 * c / (-b + (b * b - 4.0 * a * c).sqrt())).powf(4.0) * 1e6
}

fn bisect(f: &dyn Fn(f64) -> f64, lo0: f64, hi0: f64) -> f64 {
    let (mut lo, mut hi) = (lo0, hi0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(mid) > 0.0) == (f(lo) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn gap_ds(t: f64, p: f64, ds: f64) -> f64 { DH - t * ds + R * t * (p / P0).ln() }
fn gap(t: f64, p: f64) -> f64 { gap_ds(t, p, DH / TB) } // G(vapour) - G(liquid), J/mol

fn v0() -> f64 { R * TB / P0 }
fn helm(t: f64, v: f64) -> f64 { CV * t - t * (CV * (t / TB).ln() + R * (v / v0()).ln()) }
fn legendre_g(t: f64, p: f64) -> (f64, f64) {
    let (mut lo, mut hi, g) = (1e-4, 1.0, (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if helm(t, a) + p * a < helm(t, b) + p * b { hi = b } else { lo = a }
    }
    let v = 0.5 * (lo + hi);
    (helm(t, v) + p * v, v)
}

fn t_sv(s: f64, v: f64) -> f64 { TB * (v / v0()).powf(-R / CV) * E.powf(s / CV) }
fn t_sp(s: f64, p: f64) -> f64 { TB * (p / P0).powf(R / CP) * E.powf(s / CP) }
fn s_tv(t: f64, v: f64) -> f64 { CV * (t / TB).ln() + R * (v / v0()).ln() }
fn s_tp(t: f64, p: f64) -> f64 { CP * (t / TB).ln() - R * (p / P0).ln() }
fn d(f: &dyn Fn(f64) -> f64, x: f64, h: f64) -> f64 { (f(x + h) - f(x - h)) / (2.0 * h) }

fn sci(x: f64) -> String { sci_p(x, 6) }
fn sci4(x: f64) -> String { sci_p(x, 4) }
fn sci_p(x: f64, prec: usize) -> String {
    // Python's {:.Ne}: two-digit signed exponent
    let s = format!("{:.*e}", prec, x);
    let (m, e) = s.split_once('e').unwrap();
    let k: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs())
}

fn main() {
    // ---- 1. boiling at 1 atm: the lower Gibbs energy wins ----
    for tc in [90.0, 100.0, 110.0] {
        println!("gap at 1 atm, {:.0} C: {:+.1} J/mol", tc, DH - (tc + K0) * DS);
    }
    let t_cross = DH / DS;
    let t_cross_bis = bisect(&|t| gap_ds(t, P0, DS), 300.0, 450.0);
    println!("crossing with DS = 108.9: {:.2} K; entropy that puts it at 373.15 K: {:.3} J/(mol K)", t_cross, DH / TB);

    // ---- 2. Legendre: G(T, p) = min over V of F(T, V) + p V, one mole of steam ----
    let (g0, v_atm) = legendre_g(TB, P0);
    let (g1, v_loop) = legendre_g(TB, P_LOOP);
    println!("Legendre minimum: V at 1 atm = {:.3} L, at the loop = {:.3} L", v_atm * 1e3, v_loop * 1e3);
    println!("G(loop) - G(1 atm), vapour: search {:.2} J/mol, R T ln(p/p0) {:.2} J/mol", g1 - g0, R * TB * (P_LOOP / P0).ln());
    println!("G(loop) - G(1 atm), liquid: v dp = {:.2} J/mol", VL * (P_LOOP - P0));

    // ---- 3. the four Maxwell relations for the steam, by finite differences ----
    let (hs, hv, hp, ht) = (1e-4, 1e-8, 1e-2, 1e-4);
    let v0 = v0();
    let rel = [
        ("(dT/dV)_S = -(dp/dS)_V, K/m^3", d(&|v| t_sv(0.0, v), v0, hv),
         -d(&|s| R * t_sv(s, v0) / v0, 0.0, hs), -R * TB / (CV * v0)),
        ("(dT/dp)_S = (dV/dS)_p, K/Pa", d(&|p| t_sp(0.0, p), P0, hp),
         d(&|s| R * t_sp(s, P0) / P0, 0.0, hs), R * TB / (CP * P0)),
        ("(dS/dV)_T = (dp/dT)_V, Pa/K", d(&|v| s_tv(TB, v), v0, hv),
         d(&|t| R * t / v0, TB, ht), R / v0),
        ("-(dS/dp)_T = (dV/dT)_p, m^3/K", -d(&|p| s_tp(TB, p), P0, hp),
         d(&|t| R * t / P0, TB, ht), R / P0),
    ];
    for (name, left, right, exact) in rel {
        println!("{}: {} | {} | formula {}", name, sci(left), sci(right), sci(exact));
        assert!((left - exact).abs() < 1e-6 * exact.abs() && (right - exact).abs() < 1e-6 * exact.abs());
    }

    // ---- 4. Clapeyron slope at 1 atm, three ways ----
    let cc = DH * P0 / (R * TB * TB); // Clausius-Clapeyron
    let clap = (DH / TB) / (R * TB / P0 - VL); // Clapeyron, liquid volume kept
    let dp = 10.0; // slope of the gap = 0 curve
    let t_up = bisect(&|t| gap(t, P0 + dp), 300.0, 450.0);
    let t_dn = bisect(&|t| gap(t, P0 - dp), 300.0, 450.0);
    let curve = 2.0 * dp / (t_up - t_dn);
    let real = (if97_psat(TB + 0.01) - if97_psat(TB - 0.01)) / 0.02;
    println!("dp/dT: Clausius-Clapeyron {:.1} Pa/K, Clapeyron {:.1}, gap curve {:.1}, IF97 {:.1}", cc, clap, curve, real);
    println!("IF97 boiling point at 1 atm: {:.3} C; volume gained on boiling, from IF97 slope: {:.3} L/mol (ideal gas {:.3})",
             bisect(&|t| if97_psat(t) - P0, 360.0, 380.0) - K0, (DH / TB) / real * 1e3, v0 * 1e3);

    // ---- 5. the sealed loop at 1.5 bar gauge ----
    let t_closed = 1.0 / (1.0 / TB - R * (P_LOOP / P0).ln() / DH);
    let t_bis = bisect(&|t| gap(t, P_LOOP), 300.0, 450.0);
    let t_if97 = bisect(&|t| if97_psat(t) - P_LOOP, 373.0, 450.0);
    let t_lin = TB + (P_LOOP - P0) / cc;
    println!("loop boils at: formula {:.2} C, Gibbs bisection {:.2} C, IF97 {:.2} C", t_closed - K0, t_bis - K0, t_if97 - K0);
    println!("margin over 90 C flow: {:.1} K sealed, {:.1} K open at 1 atm", t_closed - K0 - 90.0, TB - K0 - 90.0);

    println!("hand: ln(p/p0) = {:.5}; R ln(p/p0)/DH = {} 1/K; 1/TB = {} 1/K; T = {:.2} K; DH p0 = {}; R TB^2 = {:.0}",
             (P_LOOP / P0).ln(), sci4(R * (P_LOOP / P0).ln() / DH), sci4(1.0 / TB), t_closed, sci4(DH * P0), R * TB * TB);

    // ---- 6. the integrated formula against real water, inside and outside the range ----
    let p_cc = |t: f64| P0 * E.powf(-DH / R * (1.0 / t - 1.0 / TB));
    let err = |tc: f64| 100.0 * (p_cc(tc + K0) / if97_psat(tc + K0) - 1.0); // pressure error, %
    let worst = (100..151).map(|c| c as f64).fold(100.0, |w, c| if err(c).abs() > err(w).abs() { c } else { w });
    println!("integrated formula, worst error from 100 to 150 C: {:+.2}% at {:.0} C", err(worst), worst);
    for tc in [150.0, 200.0, 300.0] {
        println!("p_sat at {:.0} C: formula {:.1} kPa, IF97 {:.1} kPa, error {:+.1}%",
                 tc, p_cc(tc + K0) / 1e3, if97_psat(tc + K0) / 1e3, err(tc));
    }

    // ---- 7. chart points: the Gibbs gap from 80 C to 140 C ----
    let temps: Vec<f64> = (0..7).map(|i| 80.0 + 10.0 * i as f64).collect();
    println!("chart, C       {}", temps.iter().map(|tc| format!("{:8.0}", tc)).collect::<String>());
    println!("chart, 1 atm   {}", temps.iter().map(|tc| format!("{:8.0}", gap(tc + K0, P0))).collect::<String>());
    println!("chart, loop    {}", temps.iter().map(|tc| format!("{:8.0}", gap(tc + K0, P_LOOP))).collect::<String>());

    // ---- 8. what breaks, and try changing ----
    let s_vp = d(&|v| s_tp(v * P0 / R, P0), v0, hv); // (dS/dV) holding p, not T
    println!("held fixed: (dS/dV)_T = {:.2} Pa/K, (dS/dV)_p = {:.2} Pa/K", R / v0, s_vp);
    let boil = |p: f64| (1.0 / (1.0 / TB - R * (p / P0).ln() / DH) - K0, bisect(&|t| if97_psat(t) - p, 300.0, 500.0) - K0);
    for (name, p) in [("loop at 3 bar gauge", P0 + 3e5), ("cooker at 1 bar gauge", P0 + 1e5), ("1600 m up, 84 kPa", 84000.0)] {
        let (a, b) = boil(p);
        println!("try, {}: formula {:.2} C, IF97 {:.2} C", name, a, b);
    }
    println!("try, IF97 vapour pressure rise per K at 15 C: {:.2}%",
             100.0 * (if97_psat(288.16) - if97_psat(288.14)) / 0.02 / if97_psat(288.15));
    let bad_c = DH * P0 / (R * 100.0 * 100.0);
    println!("break: Celsius in the slope {:.1} kPa/K; enthalpy alone at 140 C {:+.0} J/mol (Gibbs {:+.0}); straight-line loop {:.1} C",
             bad_c / 1e3, DH, gap(140.0 + K0, P0), t_lin - K0);
    println!("derived: ideal slope {:.1}% low; crossing {:.2} K off; loop {:.2} K above 1 atm, {:.2} K above IF97; Celsius slope x{:.1}; (dS/dV) ratio {:.2}; G rise ratio {:.0}",
             100.0 * (1.0 - cc / real), t_cross - TB, t_closed - TB, t_closed - t_if97, bad_c / cc, s_vp * v0 / R, (g1 - g0) / (VL * (P_LOOP - P0)));
    assert!((t_cross_bis - t_cross).abs() < 1e-9); // bisection = DH/DS
    assert!(((g1 - g0) - R * TB * (P_LOOP / P0).ln()).abs() < 1e-6); // Legendre search = closed form
    assert!((v_atm - v0).abs() < 1e-9 && (v_loop - R * TB / P_LOOP).abs() < 1e-9);
    assert!((curve - cc).abs() < 1e-3 * cc); // gap = 0 curve slope = formula
    assert!((t_bis - t_closed).abs() < 1e-9); // bisection = integrated formula
    assert!((if97_psat(300.0) / 1e6 - 0.353658941e-2).abs() < 1e-11); // IF97 published test values
    assert!((if97_psat(500.0) / 1e6 - 0.263889776e1).abs() < 1e-8);
    assert!((t_closed - t_if97).abs() < 0.5 && 0.01 < (real - cc) / real && (real - cc) / real < 0.03 && err(worst).abs() < 1.0);
    assert!(t_lin - t_if97 > 10.0); // the straight line overshoots
    assert!((s_vp - CP / v0).abs() < 1e-6 * s_vp); // at fixed p: c_p / V
    println!("ALL CHECKS PASS");
}
