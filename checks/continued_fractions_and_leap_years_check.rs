// Continued fractions and the leap year -- the same check in Rust, no crates.
// A year is 365.2422 days; Euclid on the leftover 0.2422 = 1211/5000 gives the
// steps, stopping early gives the fractions, brute force is the second road.
const LEFT: f64 = 1211.0 / 5000.0;
fn euclid_steps(mut a: i64, mut b: i64) -> Vec<i64> {   // 1211/5000 -> 0, 4, 7, 1, 3, ...
    let mut out = Vec::new();
    while b != 0 { out.push(a / b); let r = a % b; a = b; b = r; }
    out
}
fn stops(steps: &[i64]) -> Vec<(i64, i64)> {            // the early stops, as top/bottom
    let (mut t, mut tb, mut b, mut bb) = (steps[0], 1i64, 1i64, 0i64);
    let mut out = vec![(t, b)];
    for &s in &steps[1..] { let (nt, nb) = (s * t + tb, s * b + bb); tb = t; bb = b; t = nt; b = nb; out.push((t, b)); }
    out
}
fn best_upto(cap: i64) -> (i64, i64) {                  // closest fraction, bottom <= cap
    let (mut bp, mut bq, mut be) = (0i64, 1i64, f64::INFINITY);
    for q in 1..=cap {
        let p = (q as f64 * LEFT).round() as i64;
        if (LEFT - p as f64 / q as f64).abs() < be { be = (LEFT - p as f64 / q as f64).abs(); bp = p; bq = q; }
    }
    (bp, bq)
}
fn main() {
    let steps = euclid_steps(1211, 5000); let four = stops(&steps)[1..5].to_vec();
    let leaps = (1..=400).filter(|y| y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)).count() as i64;
    println!("{:<40}365.2422", "a year, in days");
    println!("{:<40}0.2422 = 1211/5000", "the leftover after 365 whole days");
    println!("{:<40}{}", "the whole-number steps, from Euclid", steps.iter().map(|s| s.to_string()).collect::<Vec<_>>().join(", "));
    let mut rows: Vec<(String, i64, i64)> = four.iter().enumerate().map(|(i, &(p, q))| (format!("   stop after step {}", i + 1), p, q)).collect();
    rows.push(("   the Gregorian rule".to_string(), 97, 400));
    for (name, p, q) in &rows { let v = *p as f64 / *q as f64; println!("{:<22}{:>4}/{:<5}{:.6}{:>9.3} days adrift per 400 years", name, p, q, v, (v - LEFT) * 400.0); }
    println!("counting the real rule over 400 years: {} minus {} century skips is {} leap days", 400 / 4, 400 / 4 - leaps, leaps);
    println!("every stop beats every fraction with a bottom up to its own; best up to 400 is {}/{}, not 97/400", best_upto(400).0, best_upto(400).1);
    println!("pi as 3.14159265358979, same trick: {}", stops(&euclid_steps(314159265358979, 100000000000000))[..4].iter().map(|&(p, q)| format!("{}/{}", p, q)).collect::<Vec<_>>().join(", "));
    assert!(four == vec![(1, 4), (7, 29), (8, 33), (31, 128)] && leaps == 97);
    assert!(four.iter().all(|&(p, q)| best_upto(q) == (p, q)) && best_upto(400) == (31, 128));
    assert!((97.0 / 400.0 - LEFT).abs() > 20.0 * (31.0 / 128.0 - LEFT).abs());
    println!("ALL CHECKS PASS");
}
