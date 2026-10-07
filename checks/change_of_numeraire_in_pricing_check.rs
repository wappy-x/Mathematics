// Change of numeraire -- the same check as the Python, in Rust.  No crates.  Rust
// has no erf, so the bell-curve area N(x) is built the honest way: add up thin
// slices under the curve.  One Acme call is priced five ways in three units, the
// exercise chance is reached three ways, and a two-outcome toy plus a two-state
// rate curve carry the bond unit and the annuity unit.
// Compile: rustc --edition 2021 -O change_of_numeraire_in_pricing_check.rs -o /tmp/chk
use std::f64::consts::PI;
const S: f64 = 100.0; const K: f64 = 100.0;                // the house market
const R: f64 = 0.05; const QY: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;
const STEPS: usize = 801;                                  // odd, so no node lands on the strike
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height at x
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 { // the only integrator here
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                  // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}
fn vt() -> f64 { SIG * T.sqrt() }                          // one wiggle unit, sigma root T
fn acme(z: f64, odds: f64) -> f64 { S * ((R - QY + odds * 0.5 * SIG * SIG) * T + vt() * z).exp() }
fn payoff(x: f64) -> f64 { (x - K).max(0.0) }
fn tilt(x: f64) -> f64 { (-(R - QY) * T).exp() * x / S }    // share unit measured against the bank
fn bond(t: f64) -> f64 { (-R * t).exp() }                  // a flat 5 percent curve
fn terminal(p: f64, steps: usize) -> Vec<f64> {            // weights on the steps+1 end nodes
    let mut w = vec![1.0];
    for _ in 0..steps {
        let mut nxt = vec![0.0; w.len() + 1];
        for (j, x) in w.iter().enumerate() { nxt[j] += x * (1.0 - p); nxt[j + 1] += x * p; }
        w = nxt;
    }
    w
}
fn bill(u0: f64, odds: &[f64], pay: &[f64], ut: &[f64]) -> f64 {
    u0 * (0..odds.len()).map(|i| odds[i] * pay[i] / ut[i]).sum::<f64>()
}
fn h(s: &str) -> (String, Vec<f64>) { (s.to_string(), vec![]) }
fn d<A: Into<String>>(s: A, v: f64) -> (String, Vec<f64>) { (s.into(), vec![v]) }
fn dm<A: Into<String>>(s: A, v: Vec<f64>) -> (String, Vec<f64>) { (s.into(), v) }
fn main() {
    let d1 = ((S / K).ln() + (R - QY + 0.5 * SIG * SIG) * T) / vt();
    let d2 = d1 - vt();
    let call = S * (-QY * T).exp() * n_cdf(d1) - K * (-R * T).exp() * n_cdf(d2);
    let f_fwd = S * ((R - QY) * T).exp();                  // the forward price
    // unit 1, a dollar in the bank; unit 2, one share with dividends reinvested; unit 3, the bond
    let c_bank = (-R * T).exp() * simpson(|z| payoff(acme(z, -1.0)) * phi(z), -10.0, 10.0, 40000);
    let c_share = S * simpson(|z| payoff(acme(z, 1.0)) / ((QY * T).exp() * acme(z, 1.0)) * phi(z),
                              -10.0, 10.0, 40000);
    let c_bond = (-R * T).exp() * (f_fwd * n_cdf(d1) - K * n_cdf(d2));
    let mean_fwd = simpson(|z| acme(z, -1.0) * phi(z), -10.0, 10.0, 40000);
    // the tilt averages one, and reweighting the exercise region gives the share-odds chance
    let tilt_mean = simpson(|z| tilt(acme(z, -1.0)) * phi(z), -10.0, 10.0, 40000);
    let zb = ((K / S).ln() - (R - QY - 0.5 * SIG * SIG) * T) / vt();   // Acme lands on the strike
    let p_bank = simpson(phi, zb, 10.0, 4000);
    let p_share = simpson(|z| tilt(acme(z, -1.0)) * phi(z), zb, 10.0, 4000);
    let dt = T / STEPS as f64; let up = (SIG * dt.sqrt()).exp(); let dw = 1.0 / up;
    let p_up = (((R - QY) * dt).exp() - dw) / (up - dw);              // bank odds on one step
    let p_share_step = p_up * up * (-(R - QY) * dt).exp();            // the same step, tilted
    let ends: Vec<f64> = (0..=STEPS)
        .map(|j| S * up.powi(j as i32) * dw.powi((STEPS - j) as i32)).collect();
    let (wb, ws) = (terminal(p_up, STEPS), terminal(p_share_step, STEPS));
    let t_bank = (-R * T).exp() * (0..=STEPS).map(|j| wb[j] * payoff(ends[j])).sum::<f64>();
    let t_share = S * (0..=STEPS).map(|j| ws[j] * payoff(ends[j]) / ((QY * T).exp() * ends[j]))
        .sum::<f64>();
    let t_pb: f64 = (0..=STEPS).filter(|&j| ends[j] > K).map(|j| wb[j]).sum();
    let t_ps: f64 = (0..=STEPS).filter(|&j| ends[j] > K).map(|j| ws[j]).sum();
    // a two-outcome toy: bank unit 2 -> 2, asset unit 3 -> 2 or 4, contract pays 0 or 12
    let (bq, n_t, pay) = ([0.5, 0.5], [2.0, 4.0], [0.0, 12.0]);
    let lt: Vec<f64> = n_t.iter().map(|n| (n / 3.0) / (2.0 / 2.0)).collect();  // asset beat the bank
    let aq: Vec<f64> = bq.iter().zip(&lt).map(|(w, l)| w * l).collect();       // the asset's odds
    let (toy_bank, toy_asset) = (bill(2.0, &bq, &pay, &[2.0, 2.0]), bill(3.0, &aq, &pay, &n_t));
    let (toy_wrong, toy_hedge) = (bill(3.0, &bq, &pay, &n_t), 6.0 * 3.0 - 6.0 * 2.0);
    let (a0, fl_two) = (bond(2.0) + bond(3.0), 100.0 * (bond(1.0) - bond(3.0)));
    let fl_each = 100.0 * [(1.0_f64, 2.0_f64), (2.0, 3.0)].iter().map(|&(a, b)| (bond(a) / bond(b) - 1.0) * bond(b)).sum::<f64>();
    let swap = (bond(1.0) - bond(3.0)) / a0;
    let hi = [bond(2.0) * R.exp() - 0.02, bond(3.0) * R.exp() - 0.04];    // year-1 bonds, rates up
    let lo = [bond(2.0) * R.exp() + 0.02, bond(3.0) * R.exp() + 0.04];    // year-1 bonds, rates down
    let a1 = [hi[0] + hi[1], lo[0] + lo[1]];
    let w_t: Vec<f64> = [hi[1], lo[1]].iter().map(|b| 0.5 * b / (bond(3.0) * R.exp())).collect();
    let s1 = [(1.0 - hi[1]) / a1[0], (1.0 - lo[1]) / a1[1]];   // next year's forward swap rate
    let w_a: Vec<f64> = a1.iter().map(|a| 0.5 * a / (a0 * R.exp())).collect();    // annuity odds
    let mart = w_a[0] * s1[0] + w_a[1] * s1[1];                // the annuity-odds average
    let w_keep = S * simpson(|z| payoff(acme(z, -1.0)) / ((QY * T).exp() * acme(z, -1.0)) * phi(z),
                             -10.0, 10.0, 40000);           // the new unit, the old odds
    let w_nd1 = S * (-QY * T).exp() * n_cdf(d1) - K * (-R * T).exp() * n_cdf(d1);
    let w_loose = c_share * ((R - QY) * T).exp();           // weights left adding to e^{(r-q)T}
    let w_twice = c_share * (-R * T).exp();                 // the unit already carries the discount
    let mut rows: Vec<(String, Vec<f64>)> = vec![
        h("Acme: S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year"),
        h("one call, three units of account"),
        d("  formula  S e^-qT N(d1) - K e^-rT N(d2)", call), d("  unit a dollar in the bank", c_bank),
        d("  unit one share, dividends reinvested", c_share),
        d("  unit the 1-year bond, e^-rT (F N1 - K N2)", c_bond),
        d("  an 801-step tree, bank weights", t_bank), d("  the same tree, share weights", t_share),
        d("  the call counted in share units", call / S),
        d("  the call counted in one-year bonds", call / (-R * T).exp()),
        h("chance Acme finishes above the strike"),
        d("  bank odds, integrated from the strike draw", p_bank), d("  N(d2)", n_cdf(d2)),
        d("  share odds, every outcome reweighted", p_share), d("  N(d1)", n_cdf(d1)),
        d("  bank odds on the 801-step tree", t_pb), d("  share odds on the same tree", t_ps),
        h("the pieces"), dm("  d1 and d2", vec![d1, d2]),
        dm("  e^-rT, e^-qT and e^qT", vec![(-R * T).exp(), (-QY * T).exp(), (QY * T).exp()]),
        dm("  forward F, then Acme's average under bond odds", vec![f_fwd, mean_fwd]),
        d("  average tilt, must be 1", tilt_mean),
        h("the tilt outcome by outcome: the share unit's weight multiplier"),
    ];
    for x in [60.0_f64, 80.0, 100.0, 120.0, 140.0] {
        rows.push(d(format!("  Acme at {:.0}", x), tilt(x)));
    }
    rows.extend(vec![
        h("two outcomes: bank unit 2 -> 2, asset unit 3 -> 2 or 4, contract pays 0 or 12"),
        dm("  bank odds, the bill and the hedge's cost", vec![toy_bank, toy_hedge]),
        dm("  the two tilts, 2/3 and 4/3", vec![lt[0], lt[1]]),
        d(format!("  asset odds {:.6} and {:.6}, bill", aq[0], aq[1]), toy_asset),
        d("  asset units with the old odds kept", toy_wrong),
        h("flat 5% curve, two-year swap starting in one year, notional 100"),
        d("  annuity A(0) = P(0,2) + P(0,3)", a0), d("  floating leg from two bonds", fl_two),
        d("  floating leg from its forward rates", fl_each),
        d("  forward swap rate from the bond ratio", swap), d("  e^r - 1", R.exp() - 1.0),
        h("a two-state curve at year 1: the three sets of odds stop agreeing"),
        d("  bank odds on the rates-up state", 0.5), d("  three-year bond odds on that state", w_t[0]),
        d("  annuity odds on that state", w_a[0]), d("  forward swap rate now", swap),
        d("  annuity-odds average of next year's rate", mart), h("what breaks"),
        d("  unit changed, old odds kept", w_keep), d("  N(d1) used for both halves", w_nd1),
        d("  tilt left unnormalised", w_loose),
        d("  share-unit answer discounted a second time", w_twice)]);
    for (name, vals) in &rows {
        if vals.is_empty() { println!("{}", name); continue; }
        let mut line = format!("{:<44}", name);
        for v in vals { line.push_str(&format!("{:>14.6}", v)); }
        println!("{}", line);
    }
    let spots: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let mut line = format!("{:<36}", "chart, Acme now");
    for s in &spots { line.push_str(&format!("{:>7.2}", s)); }
    println!("{}", line);
    for (lab, o) in [("chart, exercise chance, bank odds %", -1.0_f64),
                     ("chart, exercise chance, share odds %", 1.0)] {
        let mut line = format!("{:<36}", lab);
        for s in &spots {
            let v = 100.0 * n_cdf(((s / K).ln() + (R - QY + o * 0.5 * SIG * SIG) * T) / vt());
            line.push_str(&format!("{:>7.2}", v));
        }
        println!("{}", line);
    }

    assert!((call - 9.227005508154).abs() < 1e-9, "formula vs the number the shelf quotes");
    assert!((c_bank - call).abs() < 1e-7, "bank unit, brute force, vs the formula");
    assert!((c_share - call).abs() < 1e-7, "share unit, brute force, vs the formula");
    assert!((c_bond - call).abs() < 1e-9, "bond unit, forward form, vs the formula");
    assert!((mean_fwd - f_fwd).abs() < 1e-7, "bond odds average Acme to the forward");
    assert!((tilt_mean - 1.0).abs() < 1e-9, "the tilt must average one");
    assert!((p_bank - n_cdf(d2)).abs() < 1e-9 && (p_share - n_cdf(d1)).abs() < 1e-9, "by integral");
    assert!((t_pb - n_cdf(d2)).abs() < 0.001 && (t_ps - n_cdf(d1)).abs() < 0.001, "on the tree");
    assert!((t_share - t_bank).abs() < 1e-9, "one tree, two units, one price");
    assert!((t_bank - call).abs() < 0.005, "the tree road lands near the formula");
    assert!(n_cdf(d1) > n_cdf(d2), "the share unit tilts the odds upward");
    assert!((toy_asset - toy_bank).abs() < 1e-12 && (toy_hedge - toy_bank).abs() < 1e-12, "one bill");
    assert!((toy_wrong - 4.5).abs() < 1e-12, "keeping the old odds misprices the toy");
    assert!((fl_each - fl_two).abs() < 1e-12, "forward rates paid and discounted vs two bonds");
    assert!((swap - (R.exp() - 1.0)).abs() < 1e-12, "flat curve: the par rate is e^r - 1");
    assert!((mart - swap).abs() < 1e-12, "annuity odds make the par rate a fair bet");
    assert!((w_a[0] + w_a[1] - 1.0).abs() < 1e-12, "the annuity odds are a probability");
    assert!((w_t[0] - 0.5).abs() > 0.02, "with moving rates the bond odds are not the bank's");
    println!("ALL CHECKS PASS");
}
