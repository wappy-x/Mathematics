// Index lag and seasonality -- the check behind the card.  Rust std only, no crates.
// Reference CPI on 15 Apr 2027 from January 300.0 and February 301.2 (invented levels).
// Curve: 1-year zero-coupon swap rate 2.50%, plus twelve monthly seasonal factors that sum to zero.
const SEAS: [f64; 12] = [0.30, 0.20, 0.15, 0.10, 0.03, 0.02, -0.08, -0.05, -0.02, -0.10, -0.25, -0.30];
const K1: f64 = 0.025;
const DAY: i64 = 15;
const N: f64 = 10_000_000.0;

fn days_in(n: i64) -> i64 {
    // month n counts from Jan 2027 = 1
    let (y, m) = (2027 + (n - 1).div_euclid(12), (n - 1).rem_euclid(12) + 1);
    if m == 2 {
        return if y % 4 == 0 && (y % 100 != 0 || y % 400 == 0) { 29 } else { 28 };
    }
    if [4, 6, 9, 11].contains(&m) { 30 } else { 31 }
}

fn ref_cpi(m0: i64, m1: i64, day: i64, days: i64) -> i64 {
    // CPI in thousandths -> reference CPI in units of 0.00001
    let formula = m0 * days + (day - 1) * (m1 - m0); // road 1: the Treasury formula
    let mut walk = m0 * days;
    for _ in 1..day {
        walk += m1 - m0; // road 2: one day at a time
    }
    assert_eq!(walk, formula);
    (formula * 1000 / days + 5) / 10 // truncate to six decimals, round to five
}

fn s(n: i64, table: &[f64; 12]) -> f64 {
    // seasonal factor of month n, as a log change
    table[(n - 1).rem_euclid(12) as usize] / 100.0
}

fn window_a(n: i64, h: i64, lag: i64, table: &[f64; 12]) -> f64 {
    // road A: the weights formula, 15th of month n to 15th of n+h
    let w0 = (DAY - 1) as f64 / days_in(n) as f64;
    let w1 = (DAY - 1) as f64 / days_in(n + h) as f64;
    let inner: f64 = (n - lag + 2..n + h - lag + 1).map(|j| s(j, table)).sum();
    (1.0 - w0) * s(n - lag + 1, table) + inner + w1 * s(n + h - lag + 1, table)
}

fn window_b(n: i64, h: i64) -> f64 {
    // road B: whole CPI months, read through the Treasury rule
    let q = (1.0 + K1).powf(1.0 / 12.0);
    let mut sig = vec![0.0f64; 64]; // sig[j + 24] is the seasonal level of month j
    for j in -23..40i64 {
        sig[(j + 24) as usize] = sig[(j + 23) as usize] + s(j, &SEAS);
    }
    let lev = |j: i64, with_season: bool| {
        q.powf(j as f64) * if with_season { sig[(j + 24) as usize].exp() } else { 1.0 }
    };
    let reference = |n_: i64, with_season: bool| {
        let w = (DAY - 1) as f64 / days_in(n_) as f64;
        lev(n_ - 3, with_season) + w * (lev(n_ - 2, with_season) - lev(n_ - 3, with_season))
    };
    let seasonal = reference(n + h, true) / reference(n, true);
    let trend = reference(n + h, false) / reference(n, false);
    (seasonal / trend).ln()
}

fn rate(s_: f64, t: f64) -> f64 {
    // zero-coupon rate for a term of T years
    (1.0 + K1) * (s_ / t).exp() - 1.0
}

fn row(label: &str, v: f64, d: usize) {
    println!("{:<46} {:.*}", label, d, v);
}

fn main() {
    // ---- the reference index on 15 April 2027 ----
    let r0 = ref_cpi(300000, 301200, 15, 30) as f64 / 1e5;
    let r0_flat = ref_cpi(300000, 301200, 1, 30) as f64 / 1e5; // no interpolation: January alone
    let r0_15 = ref_cpi(300000, 301200, 16, 30) as f64 / 1e5; // 15 days counted, not 14
    assert!((r0 - (300.0 + 14.0 / 30.0 * 1.2)).abs() < 1e-9);

    // ---- the seasonal factors ----
    let total: f64 = SEAS.iter().sum();
    assert!(total.abs() < 1e-12);
    let (s_a, s_b) = (window_a(4, 3, 3, &SEAS), window_b(4, 3));
    let (k3, k3_b) = (rate(s_a, 0.25), rate(s_b, 0.25));
    assert!((k3 - k3_b).abs() < 1e-5); // two roads agree within 0.1 bp
    let parts = [(1.0 - 14.0 / 30.0) * s(2, &SEAS), s(3, &SEAS), s(4, &SEAS), 14.0 / 31.0 * s(5, &SEAS)];
    assert!((parts.iter().sum::<f64>() - s_a).abs() < 1e-12); // hand weights match the general formula
    let k1_a = rate(window_a(4, 12, 3, &SEAS), 1.0);
    assert!((k1_a - K1).abs() < 1e-12); // 1-year point untouched, road A
    let shifts: Vec<f64> = (4..16).map(|n| rate(window_b(n, 12), 1.0) - K1).collect();
    assert!(shifts.iter().enumerate().all(|(i, x)| i == 10 || x.abs() < 1e-12)); // every start but Feb 2028
    let leap = (1.0 + K1) * (s(12, &SEAS) * (14.0 / 28.0 - 14.0 / 29.0)).exp() - 1.0 - K1;
    assert!((shifts[10] - leap).abs() < 1e-8); // leap day: Dec at 14/29, 14/28
    let r_jul = r0 * (1.0 + K1).powf(0.25) * s_a.exp();
    assert!(((r_jul / r0).powf(4.0) - 1.0 - k3).abs() < 1e-12);

    // ---- money on a 10,000,000 dollar 3-month swap, paid 15 July ----
    let infl_leg = N * (r_jul / r0 - 1.0);
    let fixed_naive = N * ((1.0 + K1).powf(0.25) - 1.0);
    let fixed_fair = N * ((1.0 + k3).powf(0.25) - 1.0);
    assert!((infl_leg - fixed_fair).abs() < 1e-6);

    // ---- what breaks ----
    let k3_nolag = rate(window_a(4, 3, 0, &SEAS), 0.25);
    let mut bad = SEAS;
    bad[11] = 0.0; // December dropped: factors sum to +0.30%
    let k1_bad = rate(window_a(4, 12, 3, &bad), 1.0);
    assert!((k1_bad - ((1.0 + K1) * 0.003f64.exp() - 1.0)).abs() < 1e-12);

    row("reference CPI 15 Apr 2027", r0, 5);
    row("  wrong: January alone, no interpolation", r0_flat, 5);
    row("  wrong: 15/30 of the way, not 14/30", r0_15, 5);
    let seas: Vec<String> = SEAS.iter().map(|x| format!("{:+.2}", x)).collect();
    println!("seasonal factors Jan..Dec (%) {}", seas.join(" "));
    row("sum of the twelve factors (%)", total * 100.0 + 0.0, 2);
    row("weight 16/30 x Feb factor (%)", parts[0] * 100.0, 4);
    row("Mar factor (%)", parts[1] * 100.0, 4);
    row("Apr factor (%)", parts[2] * 100.0, 4);
    row("weight 14/31 x May factor (%)", parts[3] * 100.0, 4);
    row("S, road A: weights formula (%)", s_a * 100.0, 6);
    row("S, road B: whole CPI months (%)", s_b * 100.0, 6);
    row("trend factor 1.025^0.25", (1.0 + K1).powf(0.25), 6);
    row("seasonal factor exp(S)", s_a.exp(), 6);
    row("projected reference CPI 15 Jul 2027", r_jul, 4);
    row("3-month breakeven, no seasonality (%)", K1 * 100.0, 2);
    row("3-month breakeven, road A (%)", k3 * 100.0, 4);
    row("3-month breakeven, road B (%)", k3_b * 100.0, 4);
    row("  road A minus road B (bp)", (k3 - k3_b) * 1e4, 2);
    row("S / T over 3 months (%)", s_a / 0.25 * 100.0, 2);
    row("same S spread over one year, rate (%)", rate(s_a, 1.0) * 100.0, 2);
    row("  gap from seasonality (bp)", (k3 - K1) * 1e4, 1);
    row("1-year breakeven with seasonality (%)", k1_a * 100.0, 4);
    let largest = shifts.iter().enumerate().filter(|(i, _)| *i != 10).map(|(_, x)| x.abs()).fold(0.0, f64::max);
    row("largest 1-year shift, 11 start months (bp)", largest * 1e4, 1);
    row("1-year shift, 15 Feb 2028 start (bp)", shifts[10] * 1e4, 2);
    row("inflation leg, 10m notional ($)", infl_leg, 2);
    row("fixed leg struck at 2.50% ($)", fixed_naive, 2);
    row("fixed leg struck at the fair rate ($)", fixed_fair, 2);
    row("  loss from ignoring seasonality ($)", infl_leg - fixed_naive, 2);
    row("wrong: no lag, factors May..Aug (%)", k3_nolag * 100.0, 4);
    row("wrong: December dropped, 1-year rate (%)", k1_bad * 100.0, 4);
    println!("chart: 3-month breakeven (%) starting the 15th of Apr 2027 .. Mar 2028");
    let chart: Vec<String> = (4..16).map(|n| format!("{:.2}", rate(window_a(n, 3, 3, &SEAS), 0.25) * 100.0)).collect();
    println!("{}", chart.join(" "));
    println!("ALL CHECKS PASS");
}
