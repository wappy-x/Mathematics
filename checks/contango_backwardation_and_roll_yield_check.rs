// Contango, backwardation and roll yield -- the same check as the Python, in
// Rust.  No crates.  Every number quoted on the card is printed here.  The
// random numbers come from a generator written below, the straight-line fit is
// written out, the ledgers are loops.
const R: f64 = 0.05;                  // bank rate, per year
const U: f64 = 0.02;                  // crude storage, per year
const S_OIL: f64 = 80.0;              // crude spot, $/barrel
const F12_OIL: f64 = 84.0;            // crude 12-month future
const S_CU: f64 = 9000.0;             // copper spot, $/tonne
const F12_CU: f64 = 8700.0;           // copper 12-month future
const DAYS: usize = 30;               // daily marks in each month of a ledger

fn carry(s: f64, f12: f64) -> f64 { (f12 / s).ln() }     // c = r + u - y

fn strip(s: f64, c: f64) -> Vec<f64> {                    // future for delivery k months out
    (0..13).map(|k| s * (c * k as f64 / 12.0).exp()).collect()
}

fn roll_formula(c: f64, months: f64) -> f64 { (-c * months / 12.0).exp() - 1.0 }   // road 1

// Road 2: hold the front contract, mark it every day from the curve, and at
// its delivery buy the new front.  spot[i] is the spot price on day i.
fn ledger(c: f64, spot: &[f64], months: usize, per_roll: usize) -> f64 {
    let (mut value, mut day) = (1.0, 0);
    let n = per_roll * DAYS;
    for _ in 0..months / per_roll {
        for d in 0..n {
            let left0 = (n - d) as f64 / (12 * DAYS) as f64;    // years to delivery today
            let left1 = left0 - 1.0 / (12 * DAYS) as f64;       // and tomorrow
            value *= spot[day + 1] * (c * left1).exp() / (spot[day] * (c * left0).exp());
            day += 1;
        }
    }
    value - 1.0
}

struct Lcg { state: u64 }             // a 64-bit linear congruential generator
impl Lcg {
    fn uniform(&mut self) -> f64 {
        self.state = self.state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.state >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 {      // Box-Muller: two uniforms make one bell-curve draw
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn fit_slope(prices: &[f64]) -> f64 {  // road 4: least-squares slope of ln F against years
    let n = prices.len() as f64;
    let xs: Vec<f64> = (0..prices.len()).map(|k| k as f64 / 12.0).collect();
    let ys: Vec<f64> = prices.iter().map(|p| p.ln()).collect();
    let (mx, my) = (xs.iter().sum::<f64>() / n, ys.iter().sum::<f64>() / n);
    let sxy: f64 = xs.iter().zip(&ys).map(|(x, y)| (x - mx) * (y - my)).sum();
    sxy / xs.iter().map(|x| (x - mx) * (x - mx)).sum::<f64>()
}

fn pct(x: f64) -> String { format!("{:+.4}%", if x.abs() < 1e-12 { 0.0 } else { 100.0 * x }) }
fn show(label: &str, text: String) { println!("{:<44} {}", label, text) }
fn join(v: &[f64]) -> String { v.iter().map(|p| format!("{:.2}", p)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (c_oil, c_cu) = (carry(S_OIL, F12_OIL), carry(S_CU, F12_CU));
    let flat_oil = vec![S_OIL; 12 * DAYS + 1];
    let flat_cu = vec![S_CU; 12 * DAYS + 1];
    let (oil_strip, cu_strip) = (strip(S_OIL, c_oil), strip(S_CU, c_cu));

    let (sigma, dt) = (0.30, 1.0 / (12 * DAYS) as f64);   // road 3: a random spot path
    let mut rng = Lcg { state: 20260927 };
    let mut path = vec![S_OIL];
    for _ in 0..12 * DAYS {
        let last = *path.last().unwrap();
        path.push(last * (-0.5 * sigma * sigma * dt + sigma * dt.sqrt() * rng.gauss()).exp());
    }
    let fut_log = (1.0 + ledger(c_oil, &path, 12, 1)).ln();
    let spot_log = (path[12 * DAYS] / path[0]).ln();
    let quoted: Vec<f64> = oil_strip.iter().map(|p| (p * 100.0).round() / 100.0).collect();

    show("crude carry c = r + u - y, per year", format!("{:.6}", c_oil));
    let y_oil = R + U - c_oil;                                // what the market forward implies
    show("crude implied convenience yield y", format!("{:.6}", y_oil));
    println!("crude strip, months 0..12: {}", join(&oil_strip));
    show("front minus spot, $; growth factor e^c", format!("{:.2}  {:.6}", oil_strip[1] - S_OIL, c_oil.exp()));
    show("full-carry ceiling r + u; 12-month cap", format!("{:.6}  {:.2}", R + U, S_OIL * (R + U).exp()));
    show("copper carry c, per year", format!("{:.6}", c_cu));
    let cu5: Vec<f64> = [0, 3, 6, 9, 12].iter().map(|&k| cu_strip[k]).collect();
    println!("copper strip, months 0,3,6,9,12: {}", join(&cu5));
    show("1 formula, crude, one month", pct(roll_formula(c_oil, 1.0)));
    show("2 daily ledger, crude, one month", pct(ledger(c_oil, &flat_oil, 1, 1)));
    show("  roll-date spread (F0 - F1) / F1", pct((oil_strip[0] - oil_strip[1]) / oil_strip[1]));
    show("  one month, in logs, -c/12", format!("{:.6}", -c_oil / 12.0));
    show("1 formula, crude, twelve months", pct(roll_formula(c_oil, 12.0)));
    show("2 daily ledger, crude, twelve months", pct(ledger(c_oil, &flat_oil, 12, 1)));
    show("  spot / 12-month future - 1", pct(S_OIL / F12_OIL - 1.0));
    show("3 random path: spot ends at", format!("{:.2}", path[12 * DAYS]));
    show("  futures log return", format!("{:.6}", fut_log));
    show("  spot log return", format!("{:.6}", spot_log));
    show("  futures minus spot, the roll", format!("{:.6}", fut_log - spot_log));
    show("4 straight-line fit to the quoted strip, c", format!("{:.6}", fit_slope(&quoted)));
    show("copper: formula, one month", pct(roll_formula(c_cu, 1.0)));
    show("copper: daily ledger, one month", pct(ledger(c_cu, &flat_cu, 1, 1)));
    show("copper: formula, twelve months", pct(roll_formula(c_cu, 12.0)));
    show("copper: daily ledger, twelve months", pct(ledger(c_cu, &flat_cu, 12, 1)));
    show("crude roller + cash interest, a year", pct((R - c_oil).exp() - 1.0));
    show("crude barrel in a tank, y - u, a year", pct((y_oil - U).exp() - 1.0));
    for end in [76.0_f64, 80.0, 84.0, 88.0] {
        let walk: Vec<f64> = (0..=12 * DAYS).map(|i| S_OIL * (end / S_OIL).powf(i as f64 / (12 * DAYS) as f64)).collect();
        show(&format!("crude roller, spot drifts to {:.0}", end),
             format!("spot {}  roller {}", pct(end / S_OIL - 1.0), pct(ledger(c_oil, &walk, 12, 1))));
    }
    show("wrong: strip read as a forecast, a year", pct(F12_OIL / S_OIL - 1.0));
    show("wrong: 5% spread / 12, one month", pct(-(F12_OIL / S_OIL - 1.0) / 12.0));
    show("try: strip 80 -> 88, one month", pct(roll_formula(carry(80.0, 88.0), 1.0)));
    show("try: y = 7%, carry and one month", format!("{:.6}  {}", R + U - 0.07, pct(roll_formula(R + U - 0.07, 1.0))));
    show("try: roll quarterly, crude, a year", pct(ledger(c_oil, &flat_oil, 12, 3)));
    let idx = |c: f64| -> Vec<f64> { (0..13).map(|m| 100.0 * (1.0 + roll_formula(c, m as f64))).collect() };
    println!("chart, crude roller index: {}", join(&idx(c_oil)));
    println!("chart, copper roller index: {}", join(&idx(c_cu)));
    println!("chart, spot index: {}", join(&(0..13).map(|m| 100.0 * flat_oil[m * DAYS] / S_OIL).collect::<Vec<_>>()));

    assert!((ledger(c_oil, &flat_oil, 12, 1) - (S_OIL / F12_OIL - 1.0)).abs() < 1e-12, "ledger vs the two ends of the strip");
    assert!((roll_formula(c_oil, 1.0) - ledger(c_oil, &flat_oil, 1, 1)).abs() < 1e-12, "formula vs daily ledger, crude month");
    assert!((roll_formula(c_cu, 12.0) - ledger(c_cu, &flat_cu, 12, 1)).abs() < 1e-12, "formula vs daily ledger, copper year");
    assert!((ledger(c_oil, &flat_oil, 1, 1) - (oil_strip[0] - oil_strip[1]) / oil_strip[1]).abs() < 1e-12, "ledger vs roll-date spread");
    assert!(((fut_log - spot_log) + c_oil).abs() < 1e-9, "random path: futures minus spot is -c");
    assert!((fit_slope(&quoted) - c_oil).abs() < 2e-4, "slope of the quoted strip recovers c");
    assert!(ledger(c_cu, &flat_cu, 12, 1) > 0.0 && 0.0 > ledger(c_oil, &flat_oil, 12, 1), "backwardation pays, contango bleeds");
    println!("ALL CHECKS PASS");
}
