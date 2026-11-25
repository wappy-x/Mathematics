// Euclid's lemma -- the same check as the Python twin, in Rust.  No crates.
// On call one night in four: 21 calls on is 84 days, whole weeks, so 7 divides
// 4 x 21 and has to divide the 21.  Then 6, not a prime, dividing 4 x 9 = 36.
const P: i64 = 7;                 // the prime: days in a week
const A: i64 = 4;                 // days between calls
const B: i64 = 21;                // the number of calls
const C: i64 = 6;                 // the composite: a 6-day timetable
const U: i64 = 4;                 // and the pair it splits between
const V: i64 = 9;
fn listing_gcd(a: i64, b: i64) -> i64 {   // second road: list the divisors
    (1..=a.min(b)).filter(|d| a % d == 0 && b % d == 0).max().unwrap()
}
fn row(name: &str, value: i64) { println!("{:<40}{:>4}", name, value); }
fn main() {
    let total = A * B;
    let x = (1..P).find(|i| (A * i) % P == 1).unwrap();   // copies of 4 landing on 1
    let y = (1 - A * x) / P;
    row(&format!("{} calls {} days apart, days passed", B, A), total);
    println!("{} divided by {}: {} = {} x {} + {}", total, P, total, P, total / P, total % P);
    row(&format!("the {}-day gap divided by {}, remainder", A, P), A % P);
    row(&format!("shared factor of {} and {}, by listing", P, A), listing_gcd(P, A));
    println!("a mix landing on 1: {} x {} + {} x {} = {}", A, x, P, y, A * x + P * y);
    println!("times {}: {} x {} + {} x {} = {}", B, total, x, P * B, y, total * x + P * B * y);
    println!("{} x {} = {} x {}, {} = {} x {}, so {} = {} x {}",
             total, x, P, (total / P) * x, P * B, P, B, B, P, (total / P) * x + B * y);
    row(&format!("the {} calls divided by {}, remainder", B, P), B % P);
    row(&format!("{} x {} = {} divided by {}, remainder", U, V, U * V, C), (U * V) % C);
    println!("but {} into {} leaves {}, {} into {} leaves {}, gcd({}, {}) = {}",
             C, U, U % C, C, V, V % C, C, U, listing_gcd(C, U));
    let (week, days): (Vec<i64>, Vec<i64>) = ((0..P).map(|n| (A * n) % P).collect(), (0..C).map(|n| (U * n) % C).collect());
    let show = |v: &Vec<i64>| v.iter().map(|d| d.to_string()).collect::<Vec<String>>().join(" ");
    println!("call nights, days after Monday: {};  {}-day club days: {}", show(&week), C, show(&days));
    assert!(total == 84 && total % P == 0 && A % P == 4 && B % P == 0);
    assert!(A * x + P * y == 1 && total * x + P * B * y == B && (total / P) * x + B * y == B / P && B / P == 3);
    assert!((U * V) % C == 0 && U % C == 4 && V % C == 3 && listing_gcd(C, U) == 2);
    assert!(C % 2 == 0 && U % 2 == 0);   // both even, so every mix of them is even, never 1
    assert!((0..P).all(|d| week.contains(&d)) && (0..C).filter(|d| days.contains(d)).collect::<Vec<i64>>() == vec![0, 2, 4]);
    println!("ALL CHECKS PASS");
}
