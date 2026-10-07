// Powers on the clock -- the same check as modular_exponentiation_check.py, in Rust.  No
// crates.  A three-digit trip counter multiplies its reading by 7 each day and keeps only
// the last three digits.
fn by_squaring(mut days: i64, spare: bool) -> (i64, i64, Vec<i64>, Vec<i64>) {
    let mut rungs: Vec<i64> = Vec::new();          // halve the days down, then square back up
    while days > 0 { rungs.push(days); days /= 2; }
    rungs.reverse();
    let (mut reading, mut mults, mut trace) = (7i64, 0i64, vec![7i64]);
    for rung in &rungs[1..] {
        reading = reading * reading % 1000; mults += 1;        // square: doubles the days
        if spare && rung % 2 == 1 { reading = reading * 7 % 1000; mults += 1; }  // spare day
        trace.push(reading);
    }
    (reading, mults, rungs, trace)
}
fn slow(days: i64) -> i64 {             // the counter's own way, one multiplication a day
    let mut reading = 1i64;
    for _ in 0..days { reading = reading * 7 % 1000; }
    reading
}
fn line(name: &str, values: &[i64]) {
    let mut out = format!("{:<33}", name);
    for v in values { out.push_str(&format!("{:>7}", v)); }
    println!("{}", out);
}
fn main() {
    let (fast, mults, rungs, readings) = by_squaring(123, true);
    line("the days, from 1 up to 123", &rungs);
    line("what the counter reads on them", &readings);
    line("day 123 by squaring, mod 1000", &[fast]);
    line("day 123 the slow way, mod 1000", &[slow(123)]);
    line("multiplications, fast then slow", &[mults, 123]);
    line("day 7 with nothing thrown away", &[7 * 7 * 7 * 7 * 7 * 7 * 7]);
    line("biggest number written down", &[943 * 943]);
    line("skipping the spare 7s", &[by_squaring(123, false).0]);
    assert!(fast == 343 && slow(123) == 343 && fast == slow(123));
    assert!(rungs == vec![1, 3, 7, 15, 30, 61, 123] && readings == vec![7, 343, 543, 943, 249, 7, 343]);
    assert!(mults == 11 && 7i64.pow(7) % 1000 == readings[2] && by_squaring(123, false).0 == 401);
    println!("ALL CHECKS PASS");
}
