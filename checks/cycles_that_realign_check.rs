// When cycles meet again -- the same check as the Python twin, in Rust.  No crates.  A Chinese year name
// pairs a 10-year stem cycle with a 12-year branch cycle, counted from 1984, the Wood Rat.  Then the Maya
// 260-day and 365-day counts.  Road one divides the product by the biggest number going into both.
const ELEMENTS: [&str; 10] = ["Wood", "Wood", "Fire", "Fire", "Earth", "Earth", "Metal", "Metal", "Water", "Water"];
const ANIMALS: [&str; 12] = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"];
fn shared(a: i64, b: i64) -> i64 {       // the biggest number going into both
    let (mut a, mut b) = (a, b);
    while b != 0 { let t = a % b; a = b; b = t; }
    a
}
fn meet(a: i64, b: i64) -> i64 { a * b / shared(a, b) }        // road one
fn count_up(a: i64, b: i64) -> i64 {                           // road two
    let mut n = 1;
    while n % a != 0 || n % b != 0 { n += 1; }
    n
}
fn name(n: i64) -> String { format!("{} {}", ELEMENTS[(n % 10) as usize], ANIMALS[(n % 12) as usize]) }
fn main() {
    let year: i64 = 2026 - 1984;
    let mut pairs: Vec<(i64, i64)> = (0..120).map(|n| (n % 10, n % 12)).collect();
    pairs.sort();
    pairs.dedup();
    let bad: (i64, i64) = (3, 4);
    let bad_count = (0..120i64).filter(|n| (n % 10, n % 12) == bad).count();
    println!("2026 is year {} after 1984, the {}: stem {}, branch {} -- the {}", year, name(0), year % 10, year % 12, name(year));
    println!("road one: 10 x 12 = {}, shared factor {}, so they meet again after {} years", 10 * 12, shared(10, 12), meet(10, 12));
    println!("road two, counting up: both cycles come round together at year {}", count_up(10, 12));
    println!("pairs that ever happen: {} of the {} on paper -- both remainders even, or both odd", pairs.len(), 10 * 12);
    println!("stem 3 with branch 4: happens {} times in 120 years -- 3 is odd, 4 is even", bad_count);
    println!("Maya: 260 x 365 = {}, shared factor {}, so the counts realign after {} days", 260 * 365, shared(260, 365), meet(260, 365));
    println!("{} days is {} rounds of the 260-day count and {} of the 365-day count", meet(260, 365), meet(260, 365) / 260, meet(260, 365) / 365);
    println!("the three mistakes come out at {} years, {} days and {} years", 10 * 12, 260 * 365, 260 * 365 / 365);
    assert!(year == 42 && (year % 10, year % 12) == (2, 6) && name(year) == "Fire Horse");
    let want: Vec<(i64, i64)> = (0..10).flat_map(|s| (0..12).map(move |b| (s, b))).filter(|&(s, b)| s % 2 == b % 2).collect();
    assert!(pairs == want && pairs.len() == 60 && bad_count == 0);
    assert!(meet(10, 12) == 60 && count_up(10, 12) == 60 && meet(260, 365) == 18980 && 52 * 365 == 18980 && 73 * 260 == 18980 && 260 * 365 == 94900);
    println!("ALL CHECKS PASS");
}
