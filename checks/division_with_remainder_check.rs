// Division with a remainder -- the same check as division_with_remainder_check.py,
// in Rust.  No crates.  A 365-day year measured in 7-day weeks, then a 366-day
// leap year, then a 6 September birthday's weekday, 2026 to 2029.
const DAYS: [&str; 7] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

fn strip(total: i64, size: i64) -> (i64, i64) {   // the long way: take 7 away until under 7 is left
    let (mut t, mut q) = (total, 0);
    while t >= size { t -= size; q += 1; }
    (q, t)
}
fn row(name: &str, total: i64, q: i64, r: i64) {
    println!("{:<30}{:>7}{:>7}{:>11}", name, total, q, r);
}

fn main() {
    println!("{:<30}{:>7}{:>7}{:>11}", "what", "total", "weeks", "days over");
    row("ordinary year", 365, 365 / 7, 365 % 7);   // / whole weeks, % days over
    row("leap year", 366, 366 / 7, 366 % 7);
    let (q, r) = strip(365, 7);
    row("by taking 7 away over and over", 365, q, r);
    let mut pairs: Vec<(i64, i64)> = Vec::new();
    for k in 0..100 { if 365 - 7 * k >= 0 && 365 - 7 * k < 7 { pairs.push((k, 365 - 7 * k)); } }
    println!("quotient-and-leftover pairs with the leftover under 7: {}", pairs.len());
    let mut moved: Vec<usize> = vec![0];
    for length in [365usize, 366, 365] { moved.push((moved[moved.len() - 1] + length % 7) % 7); }
    let mut line = String::from("6 September: ");
    for (i, m) in moved.iter().enumerate() {
        if i > 0 { line.push_str(", "); }
        line.push_str(&format!("{} {}", 2026 + i, DAYS[*m]));
    }
    println!("{}", line);
    let steps: Vec<String> = moved.iter().map(|m| m.to_string()).collect();
    println!("weekdays moved since 2026: {}", steps.join(", then "));
    println!("the three mistakes come out at {} days, 51 weeks with {} days over, and {}",
             52 * 7, 365 - 51 * 7, DAYS[3]);
    assert!((365 / 7, 365 % 7) == (52, 1) && 52 * 7 + 1 == 365);
    assert!((366 / 7, 366 % 7) == (52, 2) && strip(365, 7) == (52, 1));
    assert!(pairs == vec![(52, 1)] && moved == vec![0, 1, 3, 4]);
    println!("ALL CHECKS PASS");
}
