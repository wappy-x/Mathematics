// There are infinitely many primes -- the same check, in Rust.  No crates.
// Six primes multiplied, plus one, is 30031.  Two roads to a new prime:
// factor it, and divide it by every prime on the list.
const LISTED: [i64; 6] = [2, 3, 5, 7, 11, 13];

fn factor(n: i64) -> i64 {       // trial division: the smallest prime factor of n
    let mut d: i64 = 2;
    while d * d <= n {
        if n % d == 0 { return d; }
        d += 1;
    }
    n
}

fn main() {
    let mut product: i64 = 1;
    for p in LISTED { product *= p; }
    let euclid = product + 1;                     // the Euclid number
    let small = factor(euclid);                   // road one: factor it
    let big = euclid / small;
    let mut rem = String::new();                  // road two: the remainders
    for p in LISTED {
        if !rem.is_empty() { rem.push(' '); }
        rem.push_str(&(euclid % p).to_string());
    }
    let seen = LISTED.iter().filter(|&&q| q == small || q == big).count();
    let rows: [(&str, String); 11] = [
        ("2 x 3 x 5 x 7 x 11 x 13", product.to_string()), ("that product plus one", euclid.to_string()),
        ("remainder of 30031 by each listed prime", rem.clone()), ("smallest prime factor of 30031", small.to_string()),
        ("30031 divided by 59", big.to_string()), ("59 x 509, multiplied back", (small * big).to_string()),
        ("smallest prime factor of 509", factor(big).to_string()), ("drop the plus one, factor 30030", factor(product).to_string()),
        ("either factor already listed, 0 is no", seen.to_string()),
        ("add one to 13 alone", (13 + 1).to_string()), ("factor that 14 instead", factor(14).to_string())];
    for (name, value) in rows { println!("{:<41}{:>6}", name, value); }
    assert!(product == 30030 && euclid == 30031 && small * big == euclid);
    assert!(small == 59 && big == 509 && factor(big) == 509);
    assert!(rem == "1 1 1 1 1 1" && factor(product) == 2 && factor(14) == 2);
    println!("ALL CHECKS PASS");
}
