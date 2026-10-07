// Returns: simple, log, and annualised -- the same check as the Python, in Rust.
// Standard library only, no crates.  One stock, $100, that moves up or down 10%
// a month.  Roads: logs by f64::ln and by their own series; a year's spread by
// the square-root rule, by listing all 4096 up/down paths, and by 200,000
// simulated years from a home-made random number generator; the chance of a
// loss by counting paths and by the binomial count.
// Compile: rustc --edition 2021 -O returns_simple_log_and_annualised_check.rs
const A: f64 = 0.10;
const P0: f64 = 100.0;
const MONTHS: usize = 12;

fn ln_series(x: f64) -> f64 {     // ln x = 2(y + y^3/3 + y^5/5 + ...), y = (x-1)/(x+1)
    let y = (x - 1.0) / (x + 1.0);
    let (mut term, mut total, mut k) = (y, 0.0, 1.0);
    while term.abs() > 1e-18 {
        total += term / k;
        term *= y * y;
        k += 2.0;
    }
    2.0 * total
}

fn sd(xs: &[f64]) -> f64 {        // spread: root of the average squared distance from the mean
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    (xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / xs.len() as f64).sqrt()
}

fn median(xs: &[f64]) -> f64 {    // the lists here always have an even length
    let mut s = xs.to_vec();
    s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    0.5 * (s[s.len() / 2 - 1] + s[s.len() / 2])
}

fn all_paths(n: usize, a: f64) -> Vec<f64> {   // year-end wealth factor of every up/down sequence
    (0..(1usize << n))
        .map(|mask| {
            let mut w = 1.0;
            for i in 0..n { w *= if (mask >> i) & 1 == 1 { 1.0 + a } else { 1.0 - a }; }
            w
        })
        .collect()
}

fn chance_below_start(n: usize, a: f64) -> f64 {   // binomial count: k ups out of n
    let (mut p, mut total) = (0.5f64.powi(n as i32), 0.0);
    for k in 0..=n {
        if k as f64 * (1.0 + a).ln() + (n - k) as f64 * (1.0 - a).ln() < 0.0 { total += p; }
        p = p * (n - k) as f64 / (k + 1) as f64;
    }
    total
}

fn simulate(years: usize, a: f64) -> (f64, f64) {   // home-made 64-bit LCG; its top bit is the coin
    let mut x: u64 = 2026;
    let (mut logs, mut simple) = (Vec::with_capacity(years), Vec::with_capacity(years));
    for _ in 0..years {
        let mut w = 1.0;
        for _ in 0..MONTHS {
            x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            w *= if x >> 63 == 1 { 1.0 + a } else { 1.0 - a };
        }
        logs.push(w.ln());
        simple.push(w - 1.0);
    }
    (sd(&logs), sd(&simple))
}

fn row(label: &str, vals: &[f64]) {
    let mut s = format!("{:<40}", label);
    for v in vals { s.push_str(&format!("{:>12.6}", v)); }
    println!("{}", s);
}

fn chart(label: &str, vals: &[f64]) {
    let v: Vec<String> = vals.iter().map(|x| format!("{:.2}", x)).collect();
    println!("{:<28}{}", label, v.join(" "));
}

fn main() {
    let (up, down) = (1.0 + A, 1.0 - A);
    let (r_up, r_dn) = (up.ln(), down.ln());
    let g = (r_up + r_dn) / 2.0;             // mean log return a month: the growth rate
    let sig_log = (r_up - r_dn) / 2.0;       // spread of the monthly log return
    let m = MONTHS as f64;
    row("up 10% then down 10%, dollars", &[P0 * up * down]);
    row("average of the two simple returns", &[(A + (-A)) / 2.0]);
    row("two-month simple return", &[up * down - 1.0]);
    row("log returns, up month and down month", &[r_up, r_dn]);
    row("sum of the two log returns", &[r_up + r_dn]);
    row("ln 0.99 by its own series", &[ln_series(0.99)]);
    row("exp(sum) - 1, back to simple", &[(r_up + r_dn).exp() - 1.0]);
    row("geometric mean a month, simple", &[(up * down).sqrt() - 1.0]);
    row("growth rate g a month, exact", &[g]);
    row("mu - sigma^2/2, approximate", &[0.0 - A * A / 2.0]);
    for r in [0.50f64, 0.10, 0.01, -0.01, -0.10, -0.50] {
        row(&format!("convert R = {:+.2}: log, R - R^2/2", r), &[(1.0 + r).ln(), r - r * r / 2.0]);
    }
    row("portfolio half each: value, dollars", &[50.0 * up + 50.0 * down]);
    row("wrong: average of the two log returns", &[(r_up + r_dn) / 2.0]);

    let paths = all_paths(MONTHS, A);
    let sd_log_enum = sd(&paths.iter().map(|w| w.ln()).collect::<Vec<_>>());
    let sd_simple_enum = sd(&paths.iter().map(|w| w - 1.0).collect::<Vec<_>>());
    let closed_simple = ((1.0 + A * A).powi(MONTHS as i32) - 1.0).sqrt();   // E[w^2] = (1 + a^2)^12
    let (mc_log, mc_simple) = simulate(200000, A);
    let mean_w = P0 * paths.iter().sum::<f64>() / paths.len() as f64;
    let med_w = P0 * median(&paths);
    let below_enum = paths.iter().filter(|&&w| w < 1.0).count() as f64 / paths.len() as f64;
    let below_binom = chance_below_start(MONTHS, A);
    let mut alt = vec![P0];
    for i in 0..MONTHS { let last = *alt.last().unwrap(); alt.push(last * if i % 2 == 0 { up } else { down }); }
    let alt_down_first = P0 * (down * up).powi(6);
    let alt_end = *alt.last().unwrap();
    row("monthly spread of the log return", &[sig_log]);
    row("rule: 0.10 x sqrt 12, simple", &[A * m.sqrt()]);
    row("rule: log spread x sqrt 12", &[sig_log * m.sqrt()]);
    row("all 4096 paths: spread, log", &[sd_log_enum]);
    row("all 4096 paths: spread, simple", &[sd_simple_enum]);
    row("closed form sqrt(1.01^12 - 1)", &[closed_simple]);
    row("200000 simulated years: log, simple", &[mc_log, mc_simple]);
    row("all paths: mean year-end, dollars", &[mean_w]);
    row("all paths: median year-end, dollars", &[med_w]);
    row("100 x 0.99^6, dollars", &[P0 * (up * down).powi(6)]);
    row("chance of ending below $100: paths", &[below_enum]);
    row("chance of ending below $100: binomial", &[below_binom]);
    row("alternating year: end, dollars", &[alt_end]);
    row("alternating years: spread of the end", &[sd(&[alt_end, alt_down_first])]);
    row("annual log drift, 12 x g", &[m * g]);
    row("median year; monthly geo mean ^ 12", &[med_w / P0 - 1.0, (up * down).sqrt().powi(MONTHS as i32) - 1.0]);
    row("wrong: spread scaled by 12, not sqrt 12", &[A * m]);

    for n in [12usize, 60, 120, 240] {
        let nf = n as f64;
        println!("horizon {:>3} months: median {:7.2}  below $100 {:.4}  drift {:+.4}  spread {:.4}",
                 n, P0 * (up * down).powf(nf / 2.0), chance_below_start(n, A), nf * g, sig_log * nf.sqrt());
    }
    let cross = (sig_log / g) * (sig_log / g);
    row("drift overtakes spread: months, years", &[cross, cross / 12.0]);

    let enum_by_n: Vec<f64> = (1..=MONTHS)
        .map(|n| sd(&all_paths(n, A).iter().map(|w| w.ln()).collect::<Vec<_>>()))
        .collect();
    chart("chart, alternating path", &alt);
    chart("chart, spread %, sqrt rule", &(1..=MONTHS).map(|n| 100.0 * sig_log * (n as f64).sqrt()).collect::<Vec<_>>());
    chart("chart, spread %, all paths", &enum_by_n.iter().map(|s| 100.0 * s).collect::<Vec<_>>());
    chart("chart, spread %, if linear", &(1..=MONTHS).map(|n| 100.0 * sig_log * n as f64).collect::<Vec<_>>());

    row("house fund: 8% - 0.15^2/2", &[0.08 - 0.15 * 0.15 / 2.0]);
    row("house fund: spread monthly, daily", &[0.15 / 12.0f64.sqrt(), 0.15 / 252.0f64.sqrt()]);
    let wk = (0..365).filter(|d| (3 + d) % 7 < 5).count() as f64;   // 1 Jan 2026 is a Thursday; Monday = 0
    row("2026: weekdays, less 10 NYSE holidays", &[wk, wk - 10.0]);
    row("try a = 0.20: two months, median year", &[P0 * 1.2 * 0.8, P0 * (1.2f64 * 0.8).powi(6)]);
    row("try a = 0.50: two months, dollars", &[P0 * 1.5 * 0.5]);
    row("try a = 0.50: g exact, approximate", &[(1.5f64.ln() + 0.5f64.ln()) / 2.0, -0.5 * 0.5 / 2.0]);
    row("try daily 1%: x sqrt 252", &[0.01 * 252.0f64.sqrt()]);

    assert!((ln_series(0.99) - (r_up + r_dn)).abs() < 1e-12, "series log of the product vs sum of logs");
    assert!((sd_log_enum - sig_log * m.sqrt()).abs() < 1e-12, "square-root rule vs every path, log");
    assert!((sd_simple_enum - closed_simple).abs() < 1e-12, "every path vs closed form, simple");
    assert!(sd_simple_enum - A * m.sqrt() > 0.005, "the rule is only approximate for simple returns");
    assert!((mc_log - sd_log_enum).abs() < 0.003, "simulation vs every path");
    assert!((med_w - alt_end).abs() < 1e-9, "median of all paths vs the alternating path");
    assert!((below_enum - below_binom).abs() < 1e-12, "counting paths vs the binomial count");
    assert!(((up * down).sqrt().powi(MONTHS as i32) - med_w / P0).abs() < 1e-12, "monthly geometric mean, compounded, vs median year");
    for (i, e) in enum_by_n.iter().enumerate() {
        assert!((e - sig_log * ((i + 1) as f64).sqrt()).abs() < 1e-12, "rule at every horizon");
    }
    println!("ALL CHECKS PASS");
}
