// Basel capital -- the same check as basel_capital_and_risk_weighted_assets_check.py, in Rust.
// Standard library only, no crates.  Three roads to the CET1 ratio, two to the payout
// limit, two to each breaking point, two to the CET1 a bank needs.
// Money in millions of dollars; ratios as decimals inside, percent when printed.

const LOANS: [(f64, f64); 3] = [(400.0, 0.30), (400.0, 1.00), (200.0, 0.75)]; // mortgages, corporates, retail
const K_M: f64 = 12.0;                       // market-risk capital charge on the 100m trading book
const MIN_C: f64 = 0.045;
const MIN_T1: f64 = 0.06;
const MIN_TOT: f64 = 0.08;
const CCB: f64 = 0.025;
const TABLE: [(f64, f64); 4] = [(0.05125, 1.00), (0.0575, 0.80), (0.06375, 0.60), (0.07, 0.40)];

fn rwa(km: f64, ko: f64) -> f64 {           // road 1: weight each loan, turn charges into RWA
    LOANS.iter().map(|(e, w)| e * w).sum::<f64>() + 12.5 * (km + ko)
}

fn ratio_by_charges(c: f64, km: f64, ko: f64) -> f64 {   // road 2: add the 8% charges, then compare
    let charge = LOANS.iter().map(|(e, w)| MIN_TOT * e * w).sum::<f64>() + km + ko;
    MIN_TOT * c / charge
}

fn exact_bp(c_k: i64, loans_k: &[(i64, i64)], charges_k: i64) -> (i64, i64, i64) {   // road 3: integers
    let r_k = loans_k.iter().map(|(e, w)| e * w).sum::<i64>() / 100 + charges_k * 25 / 2;
    (c_k * 10000 / r_k, c_k * 10000 % r_k, r_k)
}

fn cet1_for_minima(r: f64, a1: f64, t2: f64) -> f64 {   // CET1 fills whatever the other tiers leave empty
    (MIN_C * r).max(MIN_T1 * r - a1).max(MIN_TOT * r - a1 - t2)
}

fn cet1_for_minima_scan(r_k: i64, a1_k: i64, t2_k: i64) -> i64 {   // count up a thousand dollars at a time
    let mut c = 0;
    while !(1000 * c >= 45 * r_k && 1000 * (c + a1_k) >= 60 * r_k && 1000 * (c + a1_k + t2_k) >= 80 * r_k) {
        c += 1;
    }
    c
}

fn keep_by_table(c: f64, r: f64) -> Option<f64> {   // payout rule, road A: the Basel table on CET1 ratios
    let q = MIN_C + (c - cet1_for_minima(r, 0.0, 0.0)) / r;
    if q < MIN_C - 1e-12 { return None; }
    for (top, keep) in TABLE.iter() {
        if q <= top + 1e-12 { return Some(*keep); }
    }
    Some(0.0)
}

fn keep_by_dollars(c_k: i64, r_k: i64) -> Option<f64> {   // road B: which quarter of the buffer is still full
    let (excess, buf) = (c_k - 80 * r_k / 1000, 25 * r_k / 1000);
    if excess < 0 { return None; }
    for (j, keep) in [(1, 1.00), (2, 0.80), (3, 0.60), (4, 0.40)] {
        if 4 * excess <= j * buf { return Some(keep); }
    }
    Some(0.0)
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {   // root finder: f(lo) < 0 <= f(hi)
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    hi
}

fn main() {
    let (cet1, at1, t2) = (120.0_f64, 0.0_f64, 0.0_f64);
    let k_o = 0.12 * 120.0;                  // operational-risk charge: 12% of a 120m business indicator
    let r = rwa(K_M, k_o);
    let credit: f64 = LOANS.iter().map(|(e, w)| e * w).sum();
    let ratio1 = cet1 / r;
    let ratio2 = ratio_by_charges(cet1, K_M, k_o);
    let (bp, rem, r_k) = exact_bp(120000, &[(400000, 30), (400000, 100), (200000, 75)], 12000 + 14400);
    let need = (cet1_for_minima(r, at1, t2) + CCB * r) / r;
    let loss_formula = cet1 - need * r;
    let (mut lo, mut hi) = (0_i64, 120000_i64);   // smallest whole-thousand loss at which earnings must be kept
    while lo < hi {
        let mid = (lo + hi) / 2;
        if keep_by_dollars(120000 - mid, r_k) == Some(0.0) { lo = mid + 1; } else { hi = mid; }
    }
    let loss_bisect = lo as f64 / 1000.0;
    let grow_formula = cet1 / (need * r) - 1.0;
    let grow_bisect = bisect(|g| keep_by_table(cet1, r * (1.0 + g)).unwrap() - 0.2, 0.0, 0.4);
    let mixed_need = (cet1_for_minima(r, 15.0, 20.0) + CCB * r) / r;
    let mixed_scan = (cet1_for_minima_scan(r_k, 15000, 20000) + 25 * r_k / 1000) as f64 / r_k as f64;

    assert!(rem == 0 && (100.0 * ratio1 - bp as f64 / 100.0).abs() < 1e-12, "road 1 against the exact integer road");
    assert!((ratio2 - ratio1).abs() < 1e-12, "charges road against the weights road");
    assert!((mixed_need - mixed_scan).abs() < 1e-12, "CET1 need, mixed bank: max formula against the scan");
    let only_scan = (cet1_for_minima_scan(r_k, 0, 0) + 25 * r_k / 1000) as f64 / r_k as f64;
    assert!((need - only_scan).abs() < 1e-12, "CET1 need, CET1-only bank");
    assert!((loss_formula - loss_bisect).abs() < 1e-9, "breach loss: formula against bisection on the dollar rule");
    assert!((grow_formula - grow_bisect).abs() < 1e-9, "RWA growth: formula against bisection on the table rule");
    for tenth in 0..401_i64 {                // the two payout roads agree on every loss, 0 to 40m by 0.1m
        assert!(keep_by_table(cet1 - tenth as f64 / 10.0, r) == keep_by_dollars(120000 - 100 * tenth, r_k), "{}", tenth);
    }

    let rows: Vec<(&str, f64)> = vec![
        ("credit RWA, sum of E w", credit), ("market RWA, 12.5 K_M", 12.5 * K_M),
        ("operational charge K_O", k_o), ("operational RWA, 12.5 K_O", 12.5 * k_o),
        ("CET1, C", cet1), ("Tier 1 floor, 6% of RWA", MIN_T1 * r), ("total RWA R, weights", r), ("credit charge, 8% of credit RWA", MIN_TOT * credit),
        ("  8% charges added up", MIN_TOT * r),
        ("CET1 ratio %, road 1 weights", 100.0 * ratio1), ("CET1 ratio %, road 2 charges", 100.0 * ratio2),
        ("CET1 ratio %, road 3 exact bp", bp as f64 / 100.0 + rem as f64 / r_k as f64 / 100.0),
        ("stack: CET1 minimum 4.5%", MIN_C * r), ("stack: fills AT1 slot 1.5%", (MIN_T1 - MIN_C) * r),
        ("stack: fills Tier 2 slot 2.0%", (MIN_TOT - MIN_T1) * r), ("stack: conservation buffer", CCB * r),
        ("buffer quarter", CCB * r / 4.0),
        ("stack: cushion above need", cet1 - need * r),
        ("CET1 need %, CET1-only bank", 100.0 * need), ("CET1 need %, mixed bank, formula", 100.0 * mixed_need),
        ("CET1 need %, mixed bank, scan", 100.0 * mixed_scan),
        ("buffer-breach loss, formula", loss_formula), ("buffer-breach loss, bisection", loss_bisect),
        ("minimum-breach loss", cet1 - MIN_TOT * r),
        ("RWA growth to breach %, formula", 100.0 * grow_formula), ("RWA growth to breach %, bisection", 100.0 * grow_bisect),
        ("payout at 20m loss, of 10m earnings", 10.0 * (1.0 - keep_by_table(cet1 - 20.0, r).unwrap())),
        ("wrong: divide by loans + book %", 100.0 * cet1 / 1100.0), ("wrong: credit RWA only %", 100.0 * cet1 / credit),
        ("wrong: charges not times 12.5 %", 100.0 * cet1 / (credit + K_M + k_o)),
        ("wrong: 7% read as need, cushion", cet1 - (MIN_C + CCB) * r),
        ("try: CCyB 1%, need %", 100.0 * (need + 0.01)), ("try: CCyB 1%, cushion", cet1 - (need + 0.01) * r),
        ("try: loss 10 and RWA +5%, ratio %", 100.0 * (cet1 - 10.0) / (1.05 * r)),
        ("try: corporates at 75%, ratio %", 100.0 * cet1 / (r - 100.0)),
    ];
    for (name, v) in &rows { println!("{:<38} {:>12.4}", name, v); }

    println!();
    println!("  loss   CET1   ratio%  table%  keep%  payout%");
    for loss in (0..45).step_by(5) {
        let c = cet1 - loss as f64;
        let q = MIN_C + (c - cet1_for_minima(r, at1, t2)) / r;
        let kept = match keep_by_table(c, r) {
            None => "below min".to_string(),
            Some(k) => format!("{:5.0}  {:7.0}", 100.0 * k, 100.0 * (1.0 - k)),
        };
        println!("{:6} {:6.0} {:8.2} {:7.3}  {}", loss, c, 100.0 * c / r, 100.0 * q, kept);
    }
    let xs: Vec<String> = (0..17).map(|i| format!("{}", 2.5 * i as f64)).collect();
    let ys: Vec<String> = (0..17)
        .map(|i| format!("{:.0}", 100.0 * (1.0 - keep_by_table(cet1 - 2.5 * i as f64, r).unwrap())))
        .collect();
    println!("chart, loss 0..40 by 2.5  {}", xs.join(" "));
    println!("chart, payout % of earnings {}", ys.join(" "));

    println!("ALL CHECKS PASS");
}
