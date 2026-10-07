// Forward price by cash and carry -- the same check as
// forward_price_by_cash_and_carry_check.py, in Rust.  Standard library only,
// no crates, and nothing here already holds the answer: the random numbers and
// the integrator are written out below.  Acme trades at 100.00, the bank
// charges and pays 5 percent, the share yields 2 percent, delivery is one year
// out.  Four roads reach the same delivery price.
use std::f64::consts::PI;

const S: f64 = 100.0;                   // spot, bank rate, dividend yield, years
const R: f64 = 0.05;
const Q: f64 = 0.02;
const T: f64 = 1.0;
const SIGMA: f64 = 0.20;                // jumpiness and days, for the day-by-day road
const STEPS: usize = 365;
const DIV: f64 = 2.00;                  // a known cash dividend, paid at six months
const T_DIV: f64 = 0.5;
const HIGH: f64 = 105.00;               // two off-market delivery quotes
const LOW: f64 = 101.00;

fn forward(s: f64, r: f64, q: f64, t: f64) -> f64 {     // road 1: the formula
    s * ((r - q) * t).exp()
}

struct Rng { s: u64 }                   // a 64-bit linear congruential generator

impl Rng {
    fn unit(&mut self) -> f64 {         // a fresh number strictly inside (0, 1)
        self.s = self.s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.s >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {       // Box-Muller: two flat draws make one bell draw
        let (u1, u2) = (self.unit(), self.unit());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

/// Road 2: the funded purchase, run day by day down one random share path.
/// Trade A buys e^-qT shares and spends each dividend on more shares.  Trade B
/// buys one whole share and banks each dividend instead.  Both borrow what they
/// spend.  Returns where the share ended and the delivery price that leaves
/// each trade holding exactly nothing at the end.
fn funded_trade(seed: u64) -> (f64, f64, f64) {
    let (dt, mut rng, mut price) = (T / STEPS as f64, Rng { s: seed }, S);
    let (mut shares, mut loan_a) = ((-Q * T).exp(), (-Q * T).exp() * S);
    let (mut loan_b, mut bank) = (S, 0.0);
    for _ in 0..STEPS {
        price *= ((R - Q - 0.5 * SIGMA * SIGMA) * dt + SIGMA * dt.sqrt() * rng.normal()).exp();
        let paid = (Q * dt).exp() - 1.0;          // the day's dividend, per share held
        let cash = shares * price * paid;         // what trade A collects that day
        shares += cash / price;                   // spent on more shares at that day's price
        bank = bank * (R * dt).exp() + price * paid;  // trade B's dividend, left at the bank
        loan_a *= (R * dt).exp();
        loan_b *= (R * dt).exp();
    }
    (price, loan_a / shares, loan_b - bank)
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {   // the integrator
    let h = (b - a) / n as f64;
    let mut total = f(a) + f(b);
    for i in 1..n { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h) }
    total * h / 3.0
}

/// Road 3: the average share price on delivery day when the share is taken
/// to grow at the bank rate less its yield.  The bell curve is written out.
fn risk_neutral_average(sigma: f64) -> f64 {
    let drift = (R - Q - 0.5 * sigma * sigma) * T;
    let f = |z: f64| S * (drift + sigma * T.sqrt() * z).exp() * (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    simpson(f, -10.0, 10.0, 40000)
}

fn row(name: &str, value: f64) { println!("{:<44}{:>14.6}", name, value) }

fn cells(vals: &[f64], dp: usize) -> String {
    vals.iter().map(|v| format!("{:>9.*}", dp, v)).collect::<Vec<String>>().join("")
}

fn main() {
    let f = forward(S, R, Q, T);                                    // road 1
    let f_none = forward(S, R, 0.0, T);
    let prepaid = S * (-Q * T).exp();
    let repay = prepaid * (R * T).exp();
    let pv_div = DIV * (-R * T_DIV).exp();
    let f_cash = (S - pv_div) * (R * T).exp();                      // road 1, known cash income
    let f_cash_ledger = S * (R * T).exp() - DIV * (R * (T - T_DIV)).exp();   // road 4, dated ledger
    let seeds = [20260914u64, 7, 4242424242];
    let paths: Vec<(f64, f64, f64)> = seeds.iter().map(|&s| funded_trade(s)).collect();
    let finals: Vec<f64> = paths.iter().map(|p| p.0).collect();
    let reinvested: Vec<f64> = paths.iter().map(|p| p.1).collect();
    let banked: Vec<f64> = paths.iter().map(|p| p.2).collect();
    let vols = [0.10, 0.20, 0.50];
    let rn: Vec<f64> = vols.iter().map(|&v| risk_neutral_average(v)).collect();
    let (cc_t, rcc_t) = (HIGH - repay, repay - LOW);
    let (cc_now, rcc_now) = (cc_t * (-R * T).exp(), rcc_t * (-R * T).exp());
    let years = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
    let curve_q: Vec<f64> = years.iter().map(|&y| forward(S, R, Q, y)).collect();
    let curve_0: Vec<f64> = years.iter().map(|&y| forward(S, R, 0.0, y)).collect();
    let levels = [0.0, 0.02, 0.05, 0.08];
    let by_yield: Vec<f64> = levels.iter().map(|&y| forward(S, R, y, T)).collect();
    let by_rate: Vec<f64> = levels.iter().map(|&x| forward(S, x, Q, T)).collect();

    println!("Acme spot {:.2}, bank rate {:.0}%, dividend yield {:.0}%, delivery in {:.0} year",
             S, R * 100.0, Q * 100.0, T);
    row("1 formula   F = S e^((r-q)T)", f);
    for (i, seed) in seeds.iter().enumerate() {
        println!("2 funded trade, day by day, path {} (seed {})", i + 1, seed);
        row("    share ended at", finals[i]);
        row("    break-even delivery, dividends reinvested", reinvested[i]);
        row("    break-even delivery, dividends banked", banked[i]);
    }
    for (v, a) in vols.iter().zip(rn.iter()) {
        row(&format!("3 average share price at delivery, sigma {:.2}", v), *a);
    }
    row("prepaid forward   S e^-qT", prepaid);
    row("carried to delivery, S e^-qT e^rT", repay);
    row("no income at all, F = S e^rT", f_none);
    println!("known cash dividend of 2.00 at six months:");
    row("    present value of the dividend", pv_div);
    row("    1 formula   F = (S - I) e^rT", f_cash);
    row("    4 dated ledger, dividend lent to delivery", f_cash_ledger);
    println!("cash-and-carry against a quote of {:.2}:", HIGH);
    row("    shares bought today", prepaid / S);
    row("    borrowed today", prepaid);
    row("    repaid on delivery day", repay);
    row("    profit on delivery day", cc_t);
    row("    profit today", cc_now);
    println!("reverse cash-and-carry against a quote of {:.2}:", LOW);
    row("    profit on delivery day", rcc_t);
    row("    profit today", rcc_now);
    println!("what breaks if a piece goes missing:");
    row("    income forgotten", f_none);
    row("    income added, not subtracted", S * ((R + Q) * T).exp());
    row("    cash dividend taken at face value", (S - DIV) * (R * T).exp());
    row("    simple interest, not compounded", S * (1.0 + (R - Q) * T));
    row("    discounted back instead of grown", S * (-(R - Q) * T).exp());
    println!();
    println!("{:<38}{}", "chart, years to delivery", cells(&years, 0));
    println!("{:<38}{}", "chart, forward with the 2% yield", cells(&curve_q, 2));
    println!("{:<38}{}", "chart, forward with no income", cells(&curve_0, 2));
    println!("{:<38}{}", "bars, dividend yield 0/2/5/8 percent", cells(&by_yield, 2));
    println!("{:<38}{}", "bars, bank rate 0/2/5/8 percent", cells(&by_rate, 2));

    assert!((f - 103.045453395352).abs() < 1e-9, "the delivery price quoted on the card");
    assert!((f_none - 105.127109637602).abs() < 1e-9, "the same share with no income");
    assert!((f_cash - 103.076479396554).abs() < 1e-9, "the known cash dividend version");
    assert!((f_cash_ledger - f_cash).abs() < 1e-9, "dated ledger vs the cash-income formula");
    assert!(reinvested.iter().all(|b| (b - f).abs() < 1e-9), "the day-by-day road lands on the formula");
    let spread = |v: &Vec<f64>| v.iter().cloned().fold(f64::MIN, f64::max) - v.iter().cloned().fold(f64::MAX, f64::min);
    assert!(spread(&reinvested) < 1e-9, "and does not care which path the share took");
    assert!(spread(&finals) > 10.0, "though the three paths end far apart");
    assert!(spread(&banked) > 0.01, "banking the dividends does not hedge");
    assert!(rn.iter().all(|a| (a - f).abs() < 1e-6), "three volatilities, one average");
    assert!((cc_t - (HIGH - f)).abs() < 1e-9, "the trade nets exactly the mispricing");
    assert!((rcc_t - (f - LOW)).abs() < 1e-9, "and so does the trade run backwards");
    println!("ALL CHECKS PASS");
}
