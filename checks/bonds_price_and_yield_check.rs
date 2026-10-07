// Bond price and yield -- the same check as the Python, in Rust.  No crates.
// The house bond: face 1000, a 6% coupon paid once a year, five years to run,
// priced when the market yield is 5%.  The price is built four ways that share
// no arithmetic, then tested a fifth way by spending it; the clean and dirty
// prices are built from the calendar, with the day count written out here.
const FACE: f64 = 1000.0;
const CR: f64 = 0.06;
const YEARS: usize = 5;
const Y: f64 = 0.05;

/// (period number, cash) for every payment; the last one carries the face.
fn flows(face: f64, cr: f64, years: usize, k: usize) -> Vec<(usize, f64)> {
    let n = years * k;
    let c = face * cr / k as f64;
    (1..=n).map(|t| (t, c + if t == n { face } else { 0.0 })).collect()
}

/// Road 1: discount every payment on its own, then add them up.
fn price(face: f64, cr: f64, y: f64, years: usize, k: usize) -> f64 {
    let mut s = 0.0;
    for (t, cf) in flows(face, cr, years, k) {
        s += cf / (1.0 + y / k as f64).powf(t as f64);
    }
    s
}

/// Value today of 1 at the end of each of n periods, i a period.
fn annuity(n: usize, i: f64) -> f64 {
    (1.0 - (1.0 + i).powf(-(n as f64))) / i
}

/// Road 2: the coupons as one annuity, plus the face discounted once.
fn price_closed(face: f64, cr: f64, y: f64, years: usize) -> f64 {
    face * cr * annuity(years, y) + face * (1.0 + y).powf(-(years as f64))
}

/// Road 3: start at maturity holding nothing, walk back a year at a time.
fn price_rollback(face: f64, cr: f64, y: f64, years: usize) -> f64 {
    let mut v = 0.0;
    for t in (1..=years).rev() {
        v = (v + face * cr + if t == years { face } else { 0.0 }) / (1.0 + y);
    }
    v
}

/// Road 4: the face, plus the slice of each coupon above the market's rate.
fn price_par_split(face: f64, cr: f64, y: f64, years: usize) -> f64 {
    face + (face * cr - y * face) * annuity(years, y)
}

/// Road 5: a savings account paying the coupons out; the balances it leaves.
fn account(start: f64, face: f64, cr: f64, y: f64, years: usize) -> Vec<f64> {
    let (mut bal, mut path) = (start, vec![start]);
    for _ in 0..years {
        bal = bal * (1.0 + y) - face * cr;
        path.push(bal);
    }
    path
}

/// Days from 1970-01-01 to a civil date, leap years and all.
fn day_number(y: i64, m: i64, d: i64) -> i64 {
    let y = y - if m <= 2 { 1 } else { 0 };
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = y - era * 400;
    let doy = (153 * (if m > 2 { m - 3 } else { m + 9 }) + 2) / 5 + d - 1;
    era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
}

fn row(label: &str, value: f64) { println!("{:<46}{:>15.6}", label, value); }

fn strip(label: &str, values: &[f64]) {
    let mut line = format!("{:<42}", label);
    for v in values { line.push_str(&format!("{:>10.2}", v)); }
    println!("{}", line);
}

fn main() {
    let p1 = price(FACE, CR, Y, YEARS, 1);
    let p2 = price_closed(FACE, CR, Y, YEARS);
    let p3 = price_rollback(FACE, CR, Y, YEARS);
    let p4 = price_par_split(FACE, CR, Y, YEARS);
    let path = account(p1, FACE, CR, Y, YEARS);
    let mut par_path: Vec<f64> = (1..=YEARS).rev().map(|n| price(FACE, CR, Y, n, 1)).collect();
    par_path.push(FACE);
    let pvs: Vec<f64> = flows(FACE, CR, YEARS, 1).iter()
        .map(|&(t, cf)| cf * (1.0 + Y).powf(-(t as f64))).collect();

    println!("the house bond: face {:.2}, coupon {:.2}% once a year, {} payments, market yield {:.2}%",
             FACE, CR * 100.0, YEARS, Y * 100.0);
    for (t, cf) in flows(FACE, CR, YEARS, 1) {
        let d = (1.0 + Y).powf(-(t as f64));
        println!("  year {}  cash {:>9.2}  discount factor D({}) {:.6}  present value {:>11.6}",
                 t, cf, t, d, cf * d);
    }
    strip("present values, to the cent", &pvs);
    row("road 1  the five present values added", p1);
    row("road 2  coupon annuity plus the face", p2);
    row("road 3  rolled back from maturity", p3);
    row("road 4  face plus the coupon above the yield", p4);
    row("road 5  savings account, balance at year 5", path[YEARS]);
    row("annuity factor for 5 years at 5%", annuity(YEARS, Y));
    row("the five coupons, 60 x the annuity factor", FACE * CR * annuity(YEARS, Y));
    row("the face, 1000 x D(5)", FACE * (1.0 + Y).powf(-(YEARS as f64)));
    row("coupon above the market's rate, 60 - 50", FACE * CR - Y * FACE);
    row("price above face, the premium paid", p1 - FACE);

    let ys = [0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09];
    let curve: Vec<f64> = ys.iter().map(|&yy| price(FACE, CR, yy, YEARS, 1)).collect();
    strip("price at yields 3% to 9%", &curve);
    strip("value just after each coupon, years 0-5", &par_path);
    strip("savings account balances, years 0-5", &path);

    let (first, settle, second) = (day_number(2026, 3, 15), day_number(2026, 9, 15), day_number(2027, 3, 15));
    let (elapsed, full) = (settle - first, second - first);
    let w = elapsed as f64 / full as f64;
    let accrued = FACE * CR * w;
    let mut daily = 0.0;
    for _ in 0..elapsed { daily += FACE * CR / full as f64; }
    let dirty_a = p1 * (1.0 + Y).powf(w);
    let mut dirty_b = 0.0;
    for (t, cf) in flows(FACE, CR, YEARS, 1) { dirty_b += cf / (1.0 + Y).powf(t as f64 - w); }
    let clean = dirty_a - accrued;
    println!("settling 2026-09-15: {} days of the {}-day coupon period have run", elapsed, full);
    row("fraction of the period elapsed", w);
    row("accrued interest, 60 x 184/365", accrued);
    row("the same, earned one day at a time", daily);
    row("dirty price, the 15 March price grown at 5%", dirty_a);
    row("dirty price, each payment from settlement", dirty_b);
    row("clean price, the quote: dirty minus accrued", clean);

    row("price when the yield equals the 6% coupon", price(FACE, CR, CR, YEARS, 1));
    let mut total = 0.0;
    for (_, cf) in flows(FACE, CR, YEARS, 1) { total += cf; }
    row("mistake: cash added with no discounting", total);
    row("mistake: yield typed as 5, not 0.05", price(FACE, CR, 5.0, YEARS, 1));
    row("try: coupon 0%, a zero-coupon bond", price(FACE, 0.0, Y, YEARS, 1));
    row("try: 30 years to run instead of 5", price(FACE, CR, Y, 30, 1));
    row("try: the same 6% paid twice a year", price(FACE, CR, Y, YEARS, 2));
    row("the half-yearly 5% quote as an annual rate", (1.0 + Y / 2.0) * (1.0 + Y / 2.0) - 1.0);

    assert!((p1 - p2).abs() < 1e-9, "term-by-term sum against the annuity closed form");
    assert!((p1 - p3).abs() < 1e-9, "term-by-term sum against the roll-back recursion");
    assert!((p1 - p4).abs() < 1e-9, "term-by-term sum against the face-plus-premium split");
    assert!((path[YEARS] - FACE).abs() < 1e-9, "spending the price leaves exactly the face");
    assert!(path.iter().zip(par_path.iter()).all(|(a, b)| (a - b).abs() < 1e-9),
            "balances are the prices");
    assert!((price(FACE, CR, CR, YEARS, 1) - FACE).abs() < 1e-9, "yield = coupon prices at face");
    assert!((0..ys.len() - 1).all(|i| curve[i] > curve[i + 1]),
            "the price falls at every step up in yield");
    assert!((dirty_a - dirty_b).abs() < 1e-9, "two roads to the dirty price");
    assert!((accrued - daily).abs() < 1e-9, "accrued interest: one day's worth, 184 times");
    assert!(par_path[1] < clean && clean < par_path[0], "the clean price sits inside the year's fall");
    assert!(elapsed == 184, "15 March to 15 September 2026 is 184 days");
    assert!(full == 365, "15 March 2026 to 15 March 2027 is 365 days");
    println!("ALL CHECKS PASS");
}
