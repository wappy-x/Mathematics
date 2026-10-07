// Timing and in-arrears adjustments -- the check behind the card.  Rust std only.
// Nothing imported knows the answer: the normal CDF, the integrator and the
// random numbers are written out below.
use std::f64::consts::PI;

const F: f64 = 0.06;
const DL: f64 = 0.25;
const T: f64 = 5.0;
const VOL: f64 = 0.20;
const BP: f64 = 1e4;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn n_cdf(x: f64) -> f64 {                                             // bell-curve area left of x, by its series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {   // area under f, thin slices
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

// the lognormal fixing: L_T = F exp(-vol^2 T / 2 + vol sqrt(T) z) under the U-bond odds
fn l_of(z: f64, t: f64) -> f64 { F * (-0.5 * VOL * VOL * t + VOL * t.sqrt() * z).exp() }
fn adj_closed(f: f64, vol: f64, t: f64) -> f64 {                      // road 1: closed form
    DL * f * f * ((vol * vol * t).exp() - 1.0) / (1.0 + DL * f)
}
fn weighted<W: Fn(f64) -> f64>(w: &W, t: f64) -> f64 {               // road 2: E[L W] / E[W] - F by Simpson
    let num = simpson(|z| l_of(z, t) * w(l_of(z, t)) * phi(z), -10.0, 10.0, 4000);
    let den = simpson(|z| w(l_of(z, t)) * phi(z), -10.0, 10.0, 4000);
    num / den - F
}
fn caplet(k: f64) -> f64 {                                            // undiscounted Black caplet on L_T
    if k <= 0.0 { return F; }
    let s = VOL * T.sqrt();
    let d1 = ((F / k).ln() + 0.5 * s * s) / s;
    F * n_cdf(d1) - k * n_cdf(d1 - s)
}
fn mc<W: Fn(f64) -> f64>(draws: &[f64], w: &W) -> f64 {              // in-arrears average minus plain average, same paths
    let (mut slw, mut sw, mut sl) = (0.0, 0.0, 0.0);
    for &l in draws { let x = w(l); slw += l * x; sw += x; sl += l; }
    slw / sw - sl / draws.len() as f64
}
fn moments(y: f64) -> f64 {                                           // E[L W]/E[W] - F for W = 1/(1 + y L), no integral:
    let mom = |k: i32| F.powi(k) * (0.5 * (k * (k - 1)) as f64 * VOL * VOL * T).exp(); // E[L^k]
    let num: f64 = (0..20).map(|k| (-y).powi(k) * mom(k + 1)).sum();
    let den: f64 = (0..20).map(|k| (-y).powi(k) * mom(k)).sum();
    num / den - F
}
fn bp(v: f64) -> f64 { if v.abs() < 5e-13 { 0.0 } else { BP * v } }  // basis points, with no "-0.0000"

fn main() {
    let (r, notional) = (0.05, 10_000_000.0);
    let p0t = (-r * T).exp();                 // today's price of $1 paid at the fixing date T
    let p0u = p0t / (1.0 + DL * F);           // today's price of $1 paid at U = T + 0.25

    // the three-state stand-in: 2%, 6% or 10% with odds 1/4, 1/2, 1/4 (U-bond odds)
    let ls = [0.02, 0.06, 0.10];
    let ps = [0.25, 0.5, 0.25];
    let mean3: f64 = (0..3).map(|i| ps[i] * ls[i]).sum();
    let var3: f64 = (0..3).map(|i| ps[i] * (ls[i] - mean3).powi(2)).sum();
    let adj3_var = DL * var3 / (1.0 + DL * mean3);                        // road 1: the variance formula
    let w3: Vec<f64> = (0..3).map(|i| ps[i] * (1.0 + DL * ls[i])).collect(); // road 2: re-weight by 1 + dl L
    let w3sum: f64 = w3.iter().sum();
    let q3: Vec<f64> = w3.iter().map(|w| w / w3sum).collect();
    let adj3_rw = (0..3).map(|i| q3[i] * ls[i]).sum::<f64>() - mean3;

    let arrears = |l: f64| 1.0 + DL * l;
    let adj = adj_closed(F, VOL, T);
    let adj_simp = weighted(&arrears, T);
    let el2 = 2.0 * simpson(caplet, 0.0, 1.2, 6000);                      // road 3: L^2 = 2 x (all caplets)
    let adj_cap = DL * (el2 - F * F) / (1.0 + DL * F);

    let mut state: u64 = 20260928;                                        // road 4: Monte Carlo, home-made numbers
    let mut unif = || {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((state >> 11) as f64 + 0.5) / 2f64.powi(53)
    };
    let mut draws = Vec::with_capacity(200_000);
    for _ in 0..100_000 {
        let (u1, u2) = (unif(), unif());
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        draws.push(l_of(z, T)); draws.push(l_of(-z, T));                  // each draw with its mirror image
    }
    let adj_mc = mc(&draws, &arrears);

    // money: $10m notional, one quarter
    let pv_via_adj = notional * DL * p0t * adj;                           // extra fixed rate, paid at T
    let var_ln = F * F * ((VOL * VOL * T).exp() - 1.0);
    let pv_rolled = notional * p0u * DL * DL * var_ln;                    // the extra dl^2 L^2 at U, valued with U bonds

    // what breaks
    let hull = DL * F * F * VOL * VOL * T / (1.0 + DL * F);               // e^x - 1 replaced by x
    let no_denominator = DL * var_ln;                                     // forgot 1 / (1 + dl F)
    let wrong_t = adj_closed(F, VOL, T + DL);                             // used the payment date U

    let rows: Vec<(&str, f64)> = vec![
        ("three-state mean fixing, %", 100.0 * mean3), ("three-state variance", var3),
        ("three-state T-odds for 2%, 6%, 10%", q3[0]), ("  6%", q3[1]), ("  10%", q3[2]),
        ("three-state adj, variance formula, bp", BP * adj3_var), ("three-state adj, re-weighted odds, bp", BP * adj3_rw),
        ("1 + dl F", 1.0 + DL * F), ("vol^2 T", VOL * VOL * T), ("lognormal variance of L_T", var_ln), ("e^(vol^2 T) - 1", (VOL * VOL * T).exp() - 1.0),
        ("1 adj, closed form, bp", BP * adj), ("2 adj, Simpson integral, bp", BP * adj_simp),
        ("3 adj, strip of caplets, bp", BP * adj_cap), ("4 adj, Monte Carlo 200,000, bp", BP * adj_mc),
        ("in-arrears fair rate, %", 100.0 * (F + adj)),
        ("P(0,T)", p0t), ("P(0,U)", p0u),
        ("extra PV via the adjustment, $", pv_via_adj), ("extra PV by rolling to U, $", pv_rolled),
        ("wrong: no adjustment, bp", 0.0), ("wrong: vol^2 T for e^(vol^2 T) - 1, bp", BP * hull),
        ("wrong: forgot 1/(1 + dl F), bp", BP * no_denominator), ("wrong: T = 5.25 in the variance, bp", BP * wrong_t),
        ("greek: vol 21% instead of 20%, bp", BP * adj_closed(F, 0.21, T)), ("greek: F 6.01% instead of 6%, bp", BP * adj_closed(0.0601, VOL, T)),
        ("try: vol 40%, bp", BP * adj_closed(F, 0.40, T)), ("try: F 3%, bp", BP * adj_closed(0.03, VOL, T)),
    ];
    for (name, v) in &rows { println!("{:<40} {:>16.6}", name, v); }

    let pay: Vec<String> = [0.02, 0.04, 0.06, 0.08, 0.10].iter().map(|l| format!("{:.2}", notional * DL * DL * l * l)).collect();
    println!("payoff chart, extra $ at U for fixings 2..10%: {}", pay.join(", "));

    println!("\nyears to fixing: adjustment bp, closed form | Simpson");
    for tl in [5.0, 4.0, 3.0, 2.0, 1.0, 0.25] {
        println!("  {:>4.2}   {:.4} | {:.4}", tl, bp(adj_closed(F, VOL, tl)), bp(weighted(&arrears, tl)));
    }

    println!("\npayment delay after T, months: adjustment bp, Simpson | Monte Carlo");
    let (mut sweep, mut sweep_mc) = (Vec::new(), Vec::new());
    for m in 0..7 {
        let x = DL - m as f64 / 12.0;                                     // years from the payment date D on to U
        let w = move |l: f64| if x >= 0.0 { 1.0 + x * l } else { 1.0 / (1.0 - x * l) };
        let a = weighted(&w, T);                                          // early: roll forward; late: discount back
        if x >= 0.0 { assert!((a - x * var_ln / (1.0 + x * F)).abs() < 1e-12); } // closed form x Var / (1 + x F)
        else { assert!((a - moments(-x)).abs() < 1e-12); }               // late: series in lognormal moments
        sweep.push(bp(a)); sweep_mc.push(bp(mc(&draws, &w)));
        println!("  {}   {:.4} | {:.4}", m, sweep[m], sweep_mc[m]);
    }
    let chart: Vec<String> = sweep.iter().map(|v| format!("{:.2}", v)).collect();
    println!("chart: {}", chart.join(", "));

    assert!((adj3_var - adj3_rw).abs() < 1e-15);                          // variance formula = re-weighted odds
    assert!((adj - adj_simp).abs() < 1e-12);                              // closed form = integral
    assert!((adj - adj_cap).abs() < 1e-9);                                // closed form = strip of caplets
    assert!((adj - adj_mc).abs() < 0.05 / BP);                            // closed form = simulation, within noise
    assert!((pv_via_adj - pv_rolled).abs() < 1e-6);                       // two money routes agree
    assert!((sweep[6] - sweep_mc[6]).abs() < 0.05);                       // late payment: integral = simulation
    println!("all checks passed");
}
