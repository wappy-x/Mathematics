// Perfect numbers and Mersenne primes -- the same check as
// perfect_numbers_and_mersenne_check.py, in Rust.  No crates.  28 the plain
// way, then Euclid's recipe, then the recipe on the first four.  The f64
// log10 only counts digits in the record prime.
fn divisors(n: i64) -> Vec<i64> {      // every d that goes into n, n itself last
    (1..=n).filter(|d| n % d == 0).collect()
}
fn proper_sum(n: i64) -> i64 {         // the same list, with n itself dropped
    divisors(n).iter().sum::<i64>() - n
}
fn digit_count(twos: f64) -> i64 {     // digits in that many 2s multiplied, minus 1
    (twos * 2f64.log10()).floor() as i64 + 1
}
fn row(name: &str, value: i64) { println!("{:<44}{:>8}", name, value); }

fn main() {
    let d28 = divisors(28);
    let parts: Vec<String> = d28[..d28.len() - 1].iter().map(|d| d.to_string()).collect();
    println!("28 = {}", parts.join(" + "));
    row("proper divisors of 28 add to", proper_sum(28));
    row("all divisors of 28 add to, that is 2 x 28", d28.iter().sum::<i64>());
    row("Euclid's way, (1 + 2 + 4) x (1 + 7) = 7 x 8", (1 + 2 + 4) * (1 + 7));
    let pairs = [(2i64, 3i64), (3, 7), (5, 31), (7, 127)];
    let recipe: Vec<String> = pairs.iter()
        .map(|&(p, m)| format!("{} x {} = {}", 1i64 << (p - 1), m, (1i64 << (p - 1)) * m)).collect();
    println!("the recipe: {}", recipe.join(", "));
    let sums: Vec<i64> = pairs.iter().map(|&(p, m)| proper_sum((1i64 << (p - 1)) * m)).collect();
    let shown: Vec<String> = sums.iter().map(|s| s.to_string()).collect();
    println!("added up by hand: {}", shown.join(", "));
    println!("2047 = 23 x 89, not prime, and 1024 x 2047 = {}", 1024 * 2047);
    row("proper divisors of 2096128 add to", proper_sum(2096128));
    row("digits in the record prime, 136279841 twos", digit_count(136279841.0));
    row("digits in its perfect number, 52nd known", digit_count(2.0 * 136279841.0 - 1.0));
    assert!(d28 == vec![1, 2, 4, 7, 14, 28] && proper_sum(28) == 28);
    assert!(d28.iter().sum::<i64>() == (1 + 2 + 4) * (1 + 7) && d28.iter().sum::<i64>() == 56);
    assert!(sums == vec![6, 28, 496, 8128]);
    assert!(proper_sum(2096128) == 2325392 && 23 * 89 == 2047);
    assert!(digit_count(136279841.0) == 41024320 && digit_count(2.0 * 136279841.0 - 1.0) == 82048640);
    println!("ALL CHECKS PASS");
}
