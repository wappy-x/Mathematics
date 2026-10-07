// Day of the week -- the same check as day_of_the_week_check.py, in Rust.  No crates.  The rule is
// run for 20 July 1969, then checked the long way, by counting every day since 1 January 1900.
const DAYS: [&str; 7] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
const OFFSET: [i64; 12] = [0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5];              // January to December
const LENGTH: [i64; 12] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
fn leap(year: i64) -> bool {       // every fourth year, but a century year needs 400
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}
fn weekday(day: i64, month: i64, year: i64) -> i64 {   // 0 is Sunday; good from 1900 to 2099
    let t = day + OFFSET[(month - 1) as usize] + (year - 1900) + (year - 1900) / 4;
    (t - if leap(year) && month <= 2 { 1 } else { 0 }) % 7
}
fn by_counting(day: i64, month: i64, year: i64) -> i64 {  // the long road: every day since 1900
    let mut n = day - 1;
    for y in 1900..year { n += 365 + if leap(y) { 1 } else { 0 }; }
    for m in 1..month { n += LENGTH[(m - 1) as usize] + if m == 2 && leap(year) { 1 } else { 0 }; }
    n
}
fn main() {
    for (name, value) in [("the day of the month", 20), ("July's offset", OFFSET[6]), ("years since 1900", 1969 - 1900), ("leap days since 1900", 69 / 4)] {
        println!("{:<30}{:>5}", name, value);
    }
    let sums = [20, 20 + OFFSET[6], 20 + OFFSET[6] + 69, 20 + OFFSET[6] + 69 + 17];
    let parts: Vec<String> = sums.iter().map(|s| s.to_string()).collect();
    println!("running sum, piece by piece:  {}", parts.join(", "));
    println!("{} = {} x 7 + {}, so 20 July 1969 was a {}", sums[3], sums[3] / 7, sums[3] % 7,
             DAYS[weekday(20, 7, 1969) as usize]);
    let n = by_counting(20, 7, 1969);
    println!("the long road: {} days on from Monday, {} = {} x 7 + {}, a {}", n, n, n / 7, n % 7,
             DAYS[((1 + n) % 7) as usize]);
    println!("1 January 1900 {}, 1 January 1904 {}, 6 September 2026 {}",
             DAYS[weekday(1, 1, 1900) as usize], DAYS[weekday(1, 1, 1904) as usize],
             DAYS[weekday(6, 9, 2026) as usize]);
    println!("the three mistakes come out at {}, {} and {}", DAYS[((sums[3] - 17) % 7) as usize],
             DAYS[((sums[3] - OFFSET[6]) % 7) as usize], DAYS[((1 + 0 + 4 + 1) % 7) as usize]);
    assert!(weekday(20, 7, 1969) == (1 + n) % 7 && (1 + n) % 7 == 0 && sums[3] == 112);
    for y in [1900, 1904, 1943, 2000, 2026, 2099] { for m in 1..=12 { for d in [1, 28] { assert!(weekday(d, m, y) == (1 + by_counting(d, m, y)) % 7); } } }
    assert!(n == 25402 && !leap(1900) && leap(2000));
    println!("ALL CHECKS PASS");
}
