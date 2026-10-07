// Money markets -- the same check as the Python, in Rust.  No crates, std only,
// and nothing here already holds an answer: each yield is found twice, once in
// closed form and once by a bisection root finder written out here, and the
// compounded overnight factor is built three separate ways.
// The bill: face 1,000,000 dollars, 91 days left, quoted at a 4.9 percent
// discount, actual/360.  The overnight path: 13 weeks of business-day blocks,
// invented but market-shaped -- 5.05 percent for six weeks, a quarter-point
// cut from day 42, and a 20 basis point quarter-end squeeze on day 87.
const F: f64 = 1_000_000.0;
const DAYS: f64 = 91.0;
const DQ: f64 = 0.049;
const N: f64 = 1_000_000.0;

fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {  // 200 halvings
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) <= 0.0 { hi = mid } else { lo = mid }
    }
    0.5 * (lo + hi)
}

fn blocks_of(cut_day: i32) -> Vec<(i32, f64, f64)> {   // start day, days, rate
    let mut out = Vec::new();
    for w in 0..13 {
        for k in 0..5 {
            let start = 7 * w + k;
            let days = if k == 4 { 3.0 } else { 1.0 };   // Friday carries 3 days
            let mut r = if start < cut_day { 0.0505 } else { 0.0480 };
            if start == 87 { r += 0.0020 }               // quarter-end squeeze
            out.push((start, days, r));
        }
    }
    out
}

fn grow(bl: &[(i32, f64, f64)]) -> f64 {       // road 1: multiply the block factors
    let mut g = 1.0;
    for &(_, days, r) in bl { g *= 1.0 + r * days / 360.0 }
    g
}

fn grow_by_logs(bl: &[(i32, f64, f64)]) -> f64 {   // road 2: add logs, then undo them
    let mut s = 0.0;
    for &(_, days, r) in bl { s += (1.0 + r * days / 360.0).ln() }
    s.exp()
}

fn grow_each_day(bl: &[(i32, f64, f64)]) -> f64 {  // the weekend mistake: compound Sat and Sun
    let mut g = 1.0;
    for &(_, days, r) in bl { g *= (1.0 + r / 360.0).powf(days) }
    g
}

fn rate_from(g: f64, days: f64) -> f64 { (g - 1.0) * 360.0 / days }   // simple, actual/360

fn money(name: &str, v: f64) { println!("{:<46}{:>16.2}", name, v) }
fn pct(name: &str, v: f64) { println!("{:<46}{:>15.4}%", name, 100.0 * v) }
fn fac(name: &str, v: f64) { println!("{:<46}{:>16.10}", name, v) }

fn main() {
    let p = F * (1.0 - DQ * DAYS / 360.0);                          // the quoting rule
    let i_mm = (F - p) / p * 360.0 / DAYS;                          // road 1
    let i_bs = bisect(|i| p * (1.0 + i * DAYS / 360.0) - F, -0.5, 0.5);   // road 2
    let y_bey = i_mm * 365.0 / 360.0;
    let ear = (F / p).powf(365.0 / DAYS) - 1.0;
    let ear_bs = bisect(|e: f64| (1.0 + e).powf(DAYS / 365.0) - F / p, -0.5, 0.5);

    let bl = blocks_of(42);
    let (g_all, g_log) = (grow(&bl), grow_by_logs(&bl));
    let mut s1 = 0.0;
    let mut s2 = 0.0;
    for &(_, d, r) in &bl { s1 += r * d / 360.0; s2 += (r * d / 360.0) * (r * d / 360.0) }
    let g_2nd = 1.0 + s1 + 0.5 * (s1 * s1 - s2);                    // road 3
    let r_c = rate_from(g_all, DAYS);
    let mut weighted = 0.0;
    for &(_, d, r) in &bl { weighted += r * d }
    let r_bar = weighted / DAYS;
    let j0 = 1.00000000;
    let (j42, j91) = (j0 * grow(&bl[..30]), j0 * g_all);

    println!("THE BILL: face 1,000,000 dollars, 91 days, quoted at a 4.9 percent discount");
    money("price paid, actual/360 discount rule", p);
    money("price times 36, a whole number by hand", p * 36.0);
    money("discount, face minus price", F - p);
    pct("1 money-market yield, closed form", i_mm);
    pct("2 money-market yield, by bisection", i_bs);
    pct("bond-equivalent yield, actual/365", y_bey);
    pct("3 effective annual rate, closed form", ear);
    pct("4 effective annual rate, by bisection", ear_bs);

    println!();
    println!("THE OVERNIGHT PATH: 13 weeks, 65 blocks, 91 calendar days");
    let ones = bl.iter().filter(|&&(_, d, _)| d == 1.0).count();
    let threes = bl.iter().filter(|&&(_, d, _)| d == 3.0).count();
    let total: f64 = bl.iter().map(|&(_, d, _)| d).sum();
    println!("{:<46}{:>6}{:>5}{:>5}", "blocks: one-day, three-day, calendar days", ones, threes, total as i64);
    fac("one-day block at 5.05 percent", 1.0 + 0.0505 / 360.0);
    fac("Friday block, three days at 5.05 percent", 1.0 + 0.0505 * 3.0 / 360.0);
    fac("1 compounded factor, block by block", g_all);
    fac("2 compounded factor, from logs", g_log);
    fac("3 compounded factor, two-term expansion", g_2nd);
    pct("compounded in arrears, actual/360", r_c);
    pct("weighted average of the daily rates", r_bar);
    money("interest on 1,000,000, compounded", N * (g_all - 1.0));
    money("interest on 1,000,000, at the average", N * s1);
    println!("{:<46}{:>16.8}{:>14.8}{:>14.8}", "index levels, day 0, day 42, day 91", j0, j42, j91);
    fac("factor from the two index levels", j91 / j0);

    println!();
    println!("WHAT THE MISTAKES COST, per 1,000,000 of the same 91 days");
    money("quote read as the return: interest short by", (F - p) - p * DQ * DAYS / 360.0);
    money("actual/365 in the price rule: overpaid by", F * (1.0 - DQ * DAYS / 365.0) - p);
    money("average instead of compounding: short by", N * (g_all - 1.0 - s1));
    money("weekends compounded, not one block: over by", N * (grow_each_day(&bl) - g_all));

    println!();
    println!("THE SAME 91 DAYS, FOUR WAYS OF QUOTING IT");
    pct("discount quote on the face", DQ);
    pct("compounded overnight, in arrears", r_c);
    pct("money-market yield on the cash", i_mm);
    pct("bond-equivalent yield", y_bey);

    println!();
    let weeks: Vec<usize> = (1..14).collect();
    let g_w: Vec<f64> = weeks.iter().map(|&w| grow(&bl[..5 * w])).collect();
    let mut head = format!("{:<24}", "week");
    let mut thu = format!("{:<24}", "overnight rate, Thursday");
    let mut cash = format!("{:<24}", "interest by week end");
    let mut run = format!("{:<24}", "running rate in arrears");
    for (idx, &w) in weeks.iter().enumerate() {
        head.push_str(&format!("{:>9}", w));
        thu.push_str(&format!("{:>9.2}", 100.0 * bl[5 * (w - 1) + 3].2));
        cash.push_str(&format!("{:>9.2}", N * (g_w[idx] - 1.0)));
        run.push_str(&format!("{:>9.2}", 100.0 * rate_from(g_w[idx], 7.0 * w as f64)));
    }
    for line in [head, thu, cash, run] { println!("{}", line) }

    println!();
    let mut quote = format!("{:<34}", "chart, discount quote, percent");
    let mut yield_line = format!("{:<34}", "chart, money-market yield, percent");
    for k in 0..11 {
        let d = 0.01 * k as f64;
        quote.push_str(&format!("{:>7.2}", 100.0 * d));
        yield_line.push_str(&format!("{:>7.2}", 100.0 * d / (1.0 - d * DAYS / 360.0)));
    }
    println!("{}", quote);
    println!("{}", yield_line);

    println!();
    println!("COMPOUNDING GAIN per 1,000,000, flat 5 percent compounded every day");
    for n in [30.0_f64, 91.0, 182.0, 365.0] {
        money(&format!("  over {} days", n as i64),
              N * ((1.0_f64 + 0.05 / 360.0).powf(n) - (1.0 + 0.05 * n / 360.0)));
    }

    assert!((p * 36.0 - 35554100.0).abs() < 1e-6);   // against the hand arithmetic
    assert!((i_bs - i_mm).abs() < 1e-12);            // root finder against closed form
    assert!((ear_bs - ear).abs() < 1e-10);           // root finder against the power
    assert!((g_log - g_all).abs() < 1e-12);          // logs against multiplication
    assert!((g_2nd - g_all).abs() < 5e-7);           // expansion against the product
    assert!(i_mm > DQ + 1e-4);                       // the return beats the quote
    assert!(r_c > r_bar + 1e-5);                     // compounding beats the average
    println!("ALL CHECKS PASS");
}
