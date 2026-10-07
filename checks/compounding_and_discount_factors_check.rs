// Compounding and discount factors -- the same check as the Python, in Rust.
// No crates, and no library exponential or logarithm: both are built here from
// their own series.  The money is a 1,000 bill due in five years at a 5 percent
// annual yield, and the shelf's 1,000 five-year bond paying a 6 percent coupon,
// priced at that same yield.
const FACE: f64 = 1000.0;
const COUPON: f64 = 60.0;
const YEARS: u32 = 5;
const R1: f64 = 0.05;

fn my_exp(mut x: f64) -> f64 {          // e^x: halve the argument, sum the series, square back
    let mut k = 0;
    while x.abs() > 0.5 { x /= 2.0; k += 1; }
    let (mut term, mut total, mut n) = (1.0_f64, 1.0_f64, 1.0_f64);
    while term.abs() > 1e-18 { term *= x / n; total += term; n += 1.0; }
    for _ in 0..k { total *= total; }
    total
}

fn ln_core(x: f64) -> f64 {             // ln x from the series in z = (x - 1) / (x + 1)
    let z = (x - 1.0) / (x + 1.0);
    let z2 = z * z;
    let (mut term, mut total, mut n) = (z, 0.0_f64, 1.0_f64);
    while term.abs() > 1e-18 { total += term / n; term *= z2; n += 2.0; }
    2.0 * total
}

fn my_ln(mut x: f64) -> f64 {           // halved into the range where the series is fast
    let (ln2, mut k) = (ln_core(2.0), 0.0_f64);
    while x > 1.5 { x /= 2.0; k += 1.0; }
    while x < 0.75 { x *= 2.0; k -= 1.0; }
    ln_core(x) + k * ln2
}

fn growth(factor: f64, periods: u32) -> f64 {   // one multiply per period; no power function used
    let mut out = 1.0;
    for _ in 0..periods { out *= factor; }
    out
}

fn row(name: &str, value: String) { println!("{:<46}{:>14}", name, value); }

fn main() {
    // ---- five roads to one discount factor for five years ----
    let d_annual = 1.0 / growth(1.0 + R1, YEARS);                        // 1: one multiply a year
    let (num, den) = (20i128.pow(YEARS), 21i128.pow(YEARS));             // 2: exact whole numbers
    let d_exact = ((num * 1_000_000_000_000i128 + den / 2) / den) as f64 / 1e12;
    let rc = my_ln(1.0 + R1);                                            // 3: the continuous quote
    let d_cont = my_exp(-rc * YEARS as f64);
    let r2 = 2.0 * (my_exp(rc / 2.0) - 1.0);                             // 4: twice a year
    let d_semi = 1.0 / growth(1.0 + r2 / 2.0, 2 * YEARS);
    let r12 = 12.0 * (my_exp(rc / 12.0) - 1.0);
    let r365 = 365.0 * (my_exp(rc / 365.0) - 1.0);                       // 5: every day
    let d_daily = 1.0 / growth(1.0 + r365 / 365.0, 365 * YEARS);
    let deposit = FACE * d_annual;
    let mut ledger = deposit;                                            // grown forward again
    for _ in 0..YEARS { ledger *= 1.0 + R1; }
    let rate_back = -my_ln(d_annual) / YEARS as f64;                     // the factor read back as a rate

    // ---- the shelf's bond, two ways ----
    let dfs: Vec<f64> = (1..=YEARS).map(|t| 1.0 / growth(1.0 + R1, t)).collect();
    let mut flows: Vec<f64> = vec![COUPON; (YEARS - 1) as usize];
    flows.push(COUPON + FACE);
    let mut price_sum = 0.0;
    for (c, d) in flows.iter().zip(dfs.iter()) { price_sum += c * d; }
    let annuity = (1.0 - dfs[dfs.len() - 1]) / R1;                       // coupons as one annuity factor
    let price_closed = COUPON * annuity + FACE * dfs[dfs.len() - 1];
    let pulls: Vec<f64> = (0..=YEARS).rev()
        .map(|n| COUPON * (1.0 - 1.0 / growth(1.0 + R1, n)) / R1 + FACE / growth(1.0 + R1, n))
        .collect();

    // ---- the two forces, and the curve ----
    let by_maturity: Vec<f64> = [1u32, 2, 5, 10, 30].iter().map(|&t| FACE / growth(1.0 + R1, t)).collect();
    let by_rate: Vec<f64> = [0.0, 0.02, 0.05, 0.08, 0.12].iter().map(|&r| FACE / growth(1.0 + r, YEARS)).collect();
    let curve5: Vec<f64> = (0..11).map(|t| FACE / growth(1.05, t)).collect();
    let curve8: Vec<f64> = (0..11).map(|t| FACE / growth(1.08, t)).collect();

    // ---- what breaks if the convention is read wrong ----
    let grow5 = growth(1.0 + R1, YEARS);
    let wrongs: Vec<(&str, f64)> = vec![
        ("5 percent read as a continuous rate", FACE * my_exp(-R1 * YEARS as f64)),
        ("nominal 5 percent, paid twice a year", FACE / growth(1.0 + R1 / 2.0, 2 * YEARS)),
        ("simple interest, 1 + 0.05 x 5", FACE / (1.0 + R1 * YEARS as f64)),
        ("time counted in months, not years", FACE / growth(1.0 + R1, 12 * YEARS)),
    ];

    println!("a 1,000 bill due in five years, quoted at 5 percent a year");
    for (name, r) in [("quoted once a year", R1), ("the same money, twice a year", r2),
                      ("the same money, monthly", r12), ("the same money, daily", r365),
                      ("the same money, continuously", rc)] {
        row(name, format!("{:.6} percent", 100.0 * r));
    }
    println!();
    println!("five roads to the discount factor D(5):");
    for (name, d) in [("1 annual, 1.05 multiplied in five times", d_annual),
                      ("2 whole numbers, 20^5 / 21^5", d_exact),
                      ("3 continuous, e to the minus 4.879016% x 5", d_cont),
                      ("4 semi-annual, ten half-years", d_semi),
                      ("5 daily, 1825 days", d_daily)] {
        row(name, format!("{:.10}", d));
    }
    row("deposit today for the 1,000 bill", format!("{:.2}", deposit));
    row("that deposit grown five years at 5 percent", format!("{:.2}", ledger));
    row("the factor read back as a rate, -ln(D) / 5", format!("{:.6} percent", 100.0 * rate_back));
    println!();
    println!("the shelf's bond: 1,000 face, 6 percent coupon, five years, yield 5 percent");
    println!("  year    cashflow    discount factor     present value");
    for (i, (c, d)) in flows.iter().zip(dfs.iter()).enumerate() {
        println!("  {:>4}  {:>10.2}       {:.10}      {:>11.2}", i + 1, c, d, c * d);
    }
    row("price, cashflow by cashflow", format!("{:.2}", price_sum));
    row("price, coupon annuity plus discounted face", format!("{:.2}", price_closed));
    println!();
    println!("pull to par, 5 years left down to 0: {}",
             pulls.iter().map(|p| format!("{:.2}", p)).collect::<Vec<_>>().join("  "));
    println!();
    println!("deposit funding 1,000 by maturity 1 2 5 10 30 years: {}",
             by_maturity.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" "));
    println!("deposit funding 1,000 by rate 0 2 5 8 12 percent:    {}",
             by_rate.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" "));
    println!();
    println!("chart, years from now       {}",
             (0..11).map(|t| format!("{:>7}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, deposit at 5 percent {}",
             curve5.iter().map(|v| format!("{:>7.2}", v)).collect::<Vec<_>>().join(" "));
    println!("chart, deposit at 8 percent {}",
             curve8.iter().map(|v| format!("{:>7.2}", v)).collect::<Vec<_>>().join(" "));
    println!();
    println!("what breaks, each deposit then grown at the true 5 percent:");
    for (name, v) in &wrongs {
        println!("  {:<40} deposit {:>8.2}   grows to {:>8.2}", name, v, v * grow5);
    }

    assert!((d_annual - d_exact).abs() < 1e-11, "floats against exact whole-number arithmetic");
    assert!((d_cont - d_annual).abs() < 1e-12, "the continuous road against the annual one");
    assert!((d_daily - d_annual).abs() < 1e-12, "1825 daily steps against five yearly ones");
    assert!((ledger - FACE).abs() < 1e-9, "the deposit grown forward must land on the bill");
    assert!((price_sum - price_closed).abs() < 1e-9, "cashflow by cashflow against the annuity form");
    assert!((rate_back - rc).abs() < 1e-14, "the rate read back out of the factor");
    assert!((my_ln(my_exp(0.37)) - 0.37).abs() < 1e-14, "the series exp and ln must undo each other");
    let d_neg = 1.0 / growth(1.0 - 0.02, YEARS);   // a shrinking account: the rate is minus 2 percent
    assert!(by_rate.windows(2).all(|w| w[0] > w[1]), "a higher rate must give a smaller factor");
    assert!(d_neg > 1.0, "a negative rate lifts the factor above one");
    println!("ALL CHECKS PASS");
}
