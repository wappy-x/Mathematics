// Day counts -- the same check as the Python, in Rust.  No crates.  A note for
// $3,600.00 pays 10 percent a year, simple, so a whole year of accrual pays
// $360.00 and the Actual/360 coupon in dollars equals the day count.  Every
// answer is reached twice: day counts by an ordinal formula and by visiting
// every calendar date, the Actual/Actual fraction in closed form and one day
// at a time, weekdays from the ordinal and by Zeller's congruence.  Money is
// held in whole cents by integer arithmetic, so no rounding can drift.
type D = (i64, i64, i64);
const PAY: i64 = 360;          // the notional $3,600.00 times the rate 0.10
const DEN: i64 = 365 * 366;    // 133590, one denominator holding both 1/365 and 1/366
const MONTHS: [i64; 12] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const NAMES: [&str; 7] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

fn leap(y: i64) -> bool { y % 4 == 0 && (y % 100 != 0 || y % 400 == 0) }  // 2000 leap, 1900 not
fn year_len(y: i64) -> i64 { if leap(y) { 366 } else { 365 } }
fn month_len(y: i64, m: i64) -> i64 { if m == 2 && leap(y) { 29 } else { MONTHS[(m - 1) as usize] } }
fn days(s: D, e: D) -> i64 { ordinal(e) - ordinal(s) }                    // road one, by ordinals
// 30E/360 numerator, ISDA 2006 4.16(g)
fn thirty_e(s: D, e: D) -> i64 { 360 * (e.0 - s.0) + 30 * (e.1 - s.1) + e.2.min(30) - s.2.min(30) }
// Actual/Actual ISDA, counted over DEN
fn act_act(s: D, e: D) -> i64 { pieces(s, e).iter().map(|&(_, k, l)| k * (DEN / l)).sum() }
fn cents(num: i64, den: i64) -> i64 { (200 * PAY * num + den) / (2 * den) }  // to the cent
fn dollars(c: i64) -> String { format!("${}.{:02}", c / 100, c % 100) }
fn show(dt: D) -> String { format!("{:04}-{:02}-{:02}", dt.0, dt.1, dt.2) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn weekday(dt: D) -> usize { (ordinal(dt) % 7) as usize }   // 1 January of year 1 was a Monday
fn business(dt: D, hols: &[D]) -> bool { weekday(dt) < 5 && !hols.contains(&dt) }

fn ordinal(dt: D) -> i64 {                    // days since 1 January of year 1, zero based
    let (y, m, d) = dt;
    let z = y - 1;
    365 * z + z / 4 - z / 100 + z / 400 + (1..m).map(|k| month_len(y, k)).sum::<i64>() + d - 1
}

fn visited(s: D, e: D) -> i64 {               // road two: visit every date on the calendar
    (s.0..=e.0).map(|y| (1..=12).map(|m| (1..=month_len(y, m))
        .filter(|&d| s <= (y, m, d) && (y, m, d) < e).count() as i64).sum::<i64>()).sum()
}

fn next_day(dt: D) -> D {
    let (y, m, d) = dt;
    if d < month_len(y, m) { (y, m, d + 1) } else if m < 12 { (y, m + 1, 1) } else { (y + 1, 1, 1) }
}

fn prev_day(dt: D) -> D {
    let (y, m, d) = dt;
    if d > 1 { (y, m, d - 1) } else if m > 1 { (y, m - 1, month_len(y, m - 1)) } else { (y - 1, 12, 31) }
}

fn pieces(s: D, e: D) -> Vec<D> {             // Actual/Actual ISDA: days in each calendar year
    let mut out = Vec::new();
    for y in s.0..=e.0 {
        let (lo, hi) = (s.max((y, 1, 1)), e.min((y + 1, 1, 1)));
        if lo < hi { out.push((y, days(lo, hi), year_len(y))) }
    }
    out
}

fn one_at_a_time(s: D, e: D) -> i64 {         // road two: add one day's share at a time
    let (mut total, mut cur) = (0, s);
    while cur < e { total += DEN / year_len(cur.0); cur = next_day(cur) }
    total
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn zeller(dt: D) -> usize {                   // road two to the weekday, Monday as 0
    let (mut y, mut m, d) = dt;
    if m < 3 { y -= 1; m += 12 }
    (((d + 13 * (m + 1) / 5 + y + y / 4 - y / 100 + y / 400) % 7 + 5) % 7) as usize
}

fn modified_following(dt: D, hols: &[D]) -> D {   // forward, but back if the month changes
    if business(dt, hols) { return dt }
    let mut f = next_day(dt);
    while !business(f, hols) { f = next_day(f) }
    if f.1 == dt.1 { return f }
    let mut b = prev_day(dt);
    while !business(b, hols) { b = prev_day(b) }
    b
}

fn report(label: &str, s: D, e: D) -> D {
    let (n, h, aa) = (days(s, e), thirty_e(s, e), act_act(s, e));
    let split: Vec<String> = pieces(s, e).iter()
        .map(|&(y, k, l)| format!("{} in {} over {}", k, y, l)).collect();
    println!("{}: {} to {}", label, show(s), show(e));
    println!("  actual days {} by ordinals, {} by visiting every date; \
              30E/360 numerator {}; Act/Act days {}", n, visited(s, e), h, split.join(" + "));
    for (name, num, den) in [("30E/360     ", h, 360), ("Actual/360  ", n, 360), ("Act/Act ISDA", aa, DEN)] {
        println!("  {}  year fraction {:.6}  coupon {}",
                 name, num as f64 / den as f64, dollars(cents(num, den)));
    }
    (n, h, aa)
}

fn main() {
    let (s1, e1, mid) = ((2007, 1, 15), (2007, 3, 1), (2007, 2, 1));
    let (s2, e2) = ((2007, 9, 1), (2008, 3, 1));
    let (s3, e3) = (e2, (2008, 5, 31));
    let pays: [D; 4] = [(2007, 3, 1), (2007, 9, 1), (2008, 3, 1), (2008, 5, 31)];
    let offsets = [0, 15, 30, 45, 60, 75, 90];
    println!("A note for $3,600.00 at 10 percent a year, simple: a whole year accrues $360.00");
    let (n1, h1, a1) = report("first period, the 45-day stub", s1, e1);
    let g = gcd(PAY * a1, DEN);
    println!("  Act/Act coupon exactly {}/{} dollars = {:.6}; one day at a time agrees: {}",
             PAY * a1 / g, DEN / g, (PAY * a1) as f64 / DEN as f64, yn(one_at_a_time(s1, e1) == a1));
    println!("  widest gap, 30E/360 less Act/Act: {}", dollars(cents(h1, 360) - cents(a1, DEN)));
    let (n2, _, a2) = report("second period, across the leap year", s2, e2);
    println!("  one flat 365 instead of the year split: {:.6}, coupon {}",
             n2 as f64 / 365.0, dollars(cents(n2, 365)));
    let (n3, _, _) = report("final stub, due at the month end", s3, e3);
    println!("additivity at {}: Actual/360 {} + {} = {}; 30E/360 {} + {} = {}", show(mid),
             days(s1, mid), days(mid, e1), days(s1, e1),
             thirty_e(s1, mid), thirty_e(mid, e1), thirty_e(s1, e1));
    let (mut ends, mut cur, mut k): (Vec<D>, D, i64) = (Vec::new(), s1, 0);
    for off in offsets { while k < off { cur = next_day(cur); k += 1 } ends.push(cur) }
    println!("accrued from 2007-01-15, in dollars, against days of elapsed calendar time");
    let mut head = String::from("  elapsed days  ");
    for o in offsets { head.push_str(&format!("{:>7}", o)) }
    println!("{}", head);
    for (name, road) in [("  30E/360       ", 0), ("  Actual/360    ", 1), ("  Act/Act ISDA  ", 2)] {
        let mut line = name.to_string();
        for &x in &ends {
            let c = match road { 0 => cents(thirty_e(s1, x), 360), 1 => cents(days(s1, x), 360),
                                 _ => cents(act_act(s1, x), DEN) };
            line.push_str(&format!("{:>7}", dollars(c)));
        }
        println!("{}", line);
    }
    println!("payment dates: weekday by two roads, then modified following, weekends closed");
    for &p in &pays {
        let r = modified_following(p, &[]);
        let moved = if r == p { "stays put".to_string() }
                    else { format!("moves to {}, a {}", show(r), NAMES[weekday(r)]) };
        println!("  {}  {:<9} by ordinal, {:<9} by Zeller; {}",
                 show(p), NAMES[weekday(p)], NAMES[zeller(p)], moved);
    }
    println!("  with 2008-03-03 a stated holiday, 2008-03-01 moves forward to {}",
             show(modified_following((2008, 3, 1), &[(2008, 3, 3)])));
    println!("  with 2008-05-30 a stated holiday, 2008-05-31 moves back to {}",
             show(modified_following((2008, 5, 31), &[(2008, 5, 30)])));
    let (u, v, jan): (D, D, (D, D)) = ((2007, 2, 28), (2007, 3, 31), ((2007, 1, 30), (2007, 1, 31)));  // 30E/360 reads jan as 0
    let unclipped = 360 * (v.0 - u.0) + 30 * (v.1 - u.1) + v.2 - u.2;
    let rolled = days(s3, (2008, 5, 30));
    println!("what breaks");
    println!("  counting both endpoints: {} days, Actual/360 coupon {}, not {}",
             n1 + 1, dollars(cents(n1 + 1, 360)), dollars(cents(n1, 360)));
    println!("  leaving the 31st unclipped, {} to {}: {} days, not {}",
             show(u), show(v), unclipped, thirty_e(u, v));
    println!("  one flat 365 across the leap year: coupon {}, not {}",
             dollars(cents(n2, 365)), dollars(cents(a2, DEN)));
    println!("  accruing to the rolled date, {} to 2008-05-30: {} days, Actual/360 coupon {}, \
              not {}", show(s3), rolled, dollars(cents(rolled, 360)), dollars(cents(n3, 360)));
    assert!(days(s1, e1) == visited(s1, e1) && visited(s1, e1) == 45);
    assert!(days(s2, e2) == visited(s2, e2) && visited(s2, e2) == 182);
    assert!(act_act(s1, e1) == one_at_a_time(s1, e1) && act_act(s2, e2) == one_at_a_time(s2, e2));
    assert!(act_act(s2, e2) == 122 * 366 + 60 * 365 && thirty_e(s2, e2) == 180);
    assert!(days(s1, mid) + days(mid, e1) == 45 && thirty_e(s1, mid) + thirty_e(mid, e1) == 46);
    assert!(pays.iter().all(|&p| weekday(p) == zeller(p)));
    assert!(pays.iter().map(|&p| modified_following(p, &[])).collect::<Vec<D>>()
            == vec![e1, (2007, 9, 3), (2008, 3, 3), (2008, 5, 30)]);
    assert!((cents(h1, 360), cents(n1, 360), cents(a1, DEN), thirty_e(u, v), rolled, thirty_e(jan.0, jan.1), days(jan.0, jan.1)) == (4600, 4500, 4438, 32, 90, 0, 1));
    println!("ALL CHECKS PASS");
}
