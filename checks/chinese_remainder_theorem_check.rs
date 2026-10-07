// The Chinese remainder theorem -- the same check as the Python twin, in Rust.  No
// crates.  Three rotas from a shared reset: day 2 of a 3-day cycle, day 3 of a 5-day
// cycle, day 2 of the 7-day week.  Road one folds two cycles at a time; road two scans.
const CYCLES: [i64; 3] = [3, 5, 7];
const DAYS: [i64; 3] = [2, 3, 2];
fn inverse(a: i64, n: i64) -> i64 { (0..n).find(|t| (a * t) % n == 1).unwrap() }   // undoes multiplying by a
fn show(v: &[i64]) -> String {      // "[23, 128]", the way Python prints a list
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))
}
fn fold(day1: i64, cycle1: i64, day2: i64, cycle2: i64) -> i64 {   // road one: two into one
    let inv = inverse(cycle1 % cycle2, cycle2);
    let steps = ((day2 - day1) * inv).rem_euclid(cycle2);
    println!("on the {}-cycle: {} leaves {}, undone by {}; steps: {}", cycle2, cycle1, cycle1 % cycle2, inv, steps);
    (day1 + cycle1 * steps).rem_euclid(cycle1 * cycle2)
}
fn fits(cycles: &[i64], days: &[i64], span: i64) -> Vec<i64> {     // road two: try every day
    (0..span).filter(|&d| (0..cycles.len()).all(|i| d % cycles[i] == days[i])).collect()
}
fn main() {
    let (mut x, mut m) = (DAYS[0], CYCLES[0]);
    for i in 1..3 {
        x = fold(x, m, DAYS[i], CYCLES[i]);
        m *= CYCLES[i];
        println!("combined so far: day {} of the {}-day cycle", x, m);
    }
    let hand: Vec<String> = CYCLES.iter().map(|c| format!("{} = {} x {} + {}", x, x / c, c, x % c)).collect();
    println!("by hand: {}", hand.join(";  "));
    println!("{:<32}{:>10}", "by scanning all 105 days", show(&fits(&CYCLES, &DAYS, 105)));
    println!("{:<32}{:>10}", "the next one, two cycles out", show(&fits(&CYCLES, &DAYS, 210)));
    let counts: Vec<i64> = (0..30i64).map(|d| (0..3).filter(|&i| d % CYCLES[i] == DAYS[i]).count() as i64).collect();
    println!("rotas matched, days 0 to 29: {}", counts.iter().map(|n| n.to_string()).collect::<Vec<String>>().join(" "));
    let sum: i64 = DAYS.iter().sum();
    println!("adding the day numbers: {} = {}, which is day {} of the 3-day cycle", DAYS.iter().map(|d| d.to_string()).collect::<Vec<String>>().join(" + "), sum, sum % 3);
    let (agree, clash) = (fits(&[3, 5, 6], &[2, 3, 2], 30), fits(&[3, 5, 6], &[2, 3, 1], 30));
    println!("a 6-day cycle in place of the 7: readings agreeing fit {} in 30; readings clashing, {}", show(&agree), show(&clash));
    assert!(x == 23 && m == 105 && fits(&CYCLES, &DAYS, 105) == vec![23]);
    assert!(23 % 3 == 2 && 23 % 5 == 3 && 23 % 7 == 2 && 23 + 105 == 128);
    assert!(counts[23] == 3 && counts[..23].iter().max() == Some(&2) && agree == vec![8] && clash.is_empty());
    println!("ALL CHECKS PASS");
}
