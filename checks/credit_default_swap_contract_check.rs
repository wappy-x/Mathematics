// The credit default swap contract -- the same check as credit_default_swap_contract_check.py.
// Standard library only, no crates.  Rust's std has no calendar, so day counts come from
// our own civil-date formula (days since 1 Jan 1970), not from a library.
// Compile: rustc --edition 2021 -O credit_default_swap_contract_check.rs -o /tmp/cds_check

fn days_from_civil(y: i64, m: i64, d: i64) -> i64 {           // Gregorian date to a day number
    let y = if m <= 2 { y - 1 } else { y };
    let era = y.div_euclid(400);
    let yoe = y - era * 400;
    let mp = (m + 9) % 12;                                       // March = 0 ... February = 11
    let doy = (153 * mp + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146097 + doe - 719468
}

fn main() {
    let (n, s, c) = (10_000_000.0_f64, 0.0120_f64, 0.0100_f64);
    let (lam, r, t) = (0.02_f64, 0.05_f64, 5.0_f64);

    // ---- road 1: the arithmetic of the contract ----
    let idealised = s * n / 4.0;
    let dates: Vec<i64> = (0..21)
        .map(|q: i64| days_from_civil(2026 + (3 * q + 11) / 12, (3 * q + 11) % 12 + 1, 20)).collect();
    let days: Vec<i64> = dates.windows(2).map(|w| w[1] - w[0]).collect();
    let coupons: Vec<f64> = days.iter().map(|&d| s * n * d as f64 / 360.0).collect();
    let event = days_from_civil(2029, 5, 19);
    let paid_n = dates[1..].iter().filter(|&&d| d <= event).count();
    let paid: f64 = coupons[..paid_n].iter().sum();
    let acc_days = event - dates[paid_n];
    let accrued = s * n * acc_days as f64 / 360.0;

    // ---- road 2: a ledger that walks the contract one day at a time ----
    let (mut ledger, mut owed, mut day) = (0.0_f64, 0.0_f64, dates[0]);
    while day < event {
        day += 1;
        owed += s * n / 360.0;
        if dates[1..].contains(&day) { ledger += owed; owed = 0.0; }
    }

    // ---- the auction, a toy version, and road 3: two ways to settle ----
    let quotes = [(40.0_f64, 42.0_f64), (40.5, 42.5), (41.0, 43.0), (39.5, 41.5), (40.0, 42.0)];
    let imm = quotes.iter().map(|(b, o)| (b + o) / 2.0).sum::<f64>() / quotes.len() as f64;
    let open_interest = 150e6;
    let mut bids = vec![(41.5_f64, 40e6_f64), (41.0, 50e6), (40.0, 80e6), (39.0, 100e6)];
    bids.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap());
    let (mut filled, mut fin) = (0.0_f64, f64::NAN);
    for (price, size) in &bids {
        filled += size;
        if filled >= open_interest { fin = *price; break; }
    }
    let rec = fin / 100.0;
    let cash_settle = n * (1.0 - rec);
    let physical = n - n * fin / 100.0;

    // ---- road 4: simulated default times against the closed form ----
    let q = (-(r + lam) / 4.0).exp();
    let a_closed = 0.25 * q * (1.0 - q.powi(20)) / (1.0 - q);
    let prot_closed = (1.0 - 0.40) * lam / (r + lam) * (1.0 - (-(r + lam) * t).exp());
    let (mut x, paths) = (20260928_u64, 200_000usize);
    let (mut sa, mut saa, mut sp, mut spp) = (0.0_f64, 0.0_f64, 0.0_f64, 0.0_f64);
    let disc: Vec<f64> = (1..=20).map(|i| 0.25 * (-r * i as f64 / 4.0).exp()).collect();
    for _ in 0..paths {
        x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        let tau = -((((x >> 11) as f64) + 0.5) / 9007199254740992.0).ln() / lam;
        let a: f64 = (0..20).filter(|&i| tau > (i + 1) as f64 / 4.0).map(|i| disc[i]).sum();
        let p = if tau <= t { (1.0 - 0.40) * (-r * tau).exp() } else { 0.0 };
        sa += a; saa += a * a; sp += p; spp += p * p;
    }
    let np = paths as f64;
    let (a_mc, prot_mc) = (sa / np, sp / np);
    let se_a = ((saa / np - a_mc * a_mc) / np).sqrt();
    let se_p = ((spp / np - prot_mc * prot_mc) / np).sqrt();
    let upfront = (s - c) * a_closed * n;
    let total_days: i64 = days.iter().sum();

    let rows: Vec<(&str, f64)> = vec![
        ("quarterly premium, 1/4 year", idealised), ("five years, 20 x 1/4", 20.0 * idealised),
        ("coupon 20 Dec 26-20 Mar 27, days", days[0] as f64), ("  premium", coupons[0]),
        ("coupon to 20 Jun 27, days", days[1] as f64), ("  premium", coupons[1]),
        ("coupon to 20 Sep 27, days", days[2] as f64), ("  premium", coupons[2]),
        ("coupon to 20 Dec 27, days", days[3] as f64), ("  premium", coupons[3]),
        ("first year, ACT/360", coupons[..4].iter().sum()), ("five years, days", total_days as f64),
        ("five years, ACT/360", coupons.iter().sum()),
        ("coupons paid before 19 May 29", paid_n as f64), ("  their total", paid),
        ("accrued, days", acc_days as f64), ("  accrued premium", accrued),
        ("ledger: premiums settled", ledger), ("ledger: accrued at event", owed),
        ("auction initial midpoint", imm), ("auction final price", fin),
        ("payout, cash settlement", cash_settle), ("payout, physical", physical),
        ("premium received, with accrued", paid + accrued),
        ("buyer's net gain over the trade", cash_settle - paid - accrued),
        ("Lehman 2008: payout at 8.625", n * (1.0 - 0.08625)),
        ("risky annuity, closed form", a_closed), ("risky annuity, simulated", a_mc),
        ("  standard error", se_a), ("protection leg, closed form", prot_closed),
        ("protection leg, simulated", prot_mc), ("  standard error", se_p),
        ("par spread, quarterly, bp", 1e4 * prot_closed / a_closed),
        ("upfront, 120 bp on 100 coupon", upfront),
        ("per 1 bp: premium per quarter", 1e-4 * n / 4.0), ("per 1 bp: upfront", 1e-4 * a_closed * n),
        ("per recovery point: payout", -0.01 * n),
        ("wrong: recovery as payout", n * rec), ("wrong: spread per quarter", s * n),
        ("wrong: 120 bp read as 12%", 0.12 * n / 4.0),
        ("try: 500 bp, per quarter", 0.05 * n / 4.0), ("try: 500 bp coupon, upfront", (s - 0.05) * a_closed * n),
    ];
    for (name, v) in &rows { println!("{:<36} {:>18.6}", name, v); }
    let rec_row: Vec<String> = (0..11).map(|k| format!("{:5}", 10 * k)).collect();
    println!("chart, recovery %    {}", rec_row.join(" "));
    let pay_row: Vec<String> = (0..11).map(|k| format!("{:5.0}", n * (1.0 - k as f64 / 10.0) / 1e6)).collect();
    println!("chart, payout $m     {}", pay_row.join(" "));

    let leaps = (2027..2032).filter(|y| y % 4 == 0).count() as i64;
    assert!((ledger - paid).abs() < 1e-6, "day-by-day ledger vs coupons from day counts");
    assert!((owed - accrued).abs() < 1e-6, "ledger's unpaid days vs the accrued formula");
    assert!(total_days == 5 * 365 + leaps, "calendar vs leap years");
    assert!((a_mc - a_closed).abs() < 4.0 * se_a, "simulated risky annuity vs closed form");
    assert!((prot_mc - prot_closed).abs() < 4.0 * se_p, "simulated protection leg vs closed form");
    assert!((a_closed - 4.1819).abs() < 5e-5, "house risky annuity");
    let clear = bids.iter().map(|b| b.0)
        .filter(|&p| bids.iter().filter(|b| b.0 >= p).map(|b| b.1).sum::<f64>() >= open_interest)
        .fold(f64::NEG_INFINITY, f64::max);
    assert!(fin == clear, "auction fill loop vs clearing-price rule");
    assert!((cash_settle - 6_000_000.0).abs() < 1e-6, "house payout at the auction's 40");
    let up_sum: f64 = (1..=20).map(|i| (s - c) * n * 0.25 * (-(r + lam) * i as f64 / 4.0).exp()).sum();
    assert!((upfront - up_sum).abs() < 1e-6, "upfront: geometric closed form vs quarter-by-quarter sum");
    assert!((prot_closed - 0.050625).abs() < 5e-7, "house protection leg");
    assert!((1e4 * prot_closed / a_closed - 121.06).abs() < 5e-3, "house par spread, quarterly");
    println!("ALL CHECKS PASS");
}
