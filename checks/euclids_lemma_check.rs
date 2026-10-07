// Euclid's lemma -- the same check as the Python twin, in Rust.  No crates.
// $84 raised as 4 gifts of $21: 7 divides the total, and so has to divide a
// gift.  Then 6, not a prime, dividing 4 x 9 = 36 but neither the 4 nor the 9.
const P: i64 = 7;                 // the prime
const A: i64 = 4;                 // the number of gifts
const B: i64 = 21;                // one gift
const C: i64 = 6;                 // the composite
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
    row(&format!("{} gifts of ${}, the money raised", A, B), total);
    println!("{} shared by {}: {} = {} x {} + {}", total, P, total, P, total / P, total % P);
    row(&format!("the {} gifts shared by {}, remainder", A, P), A % P);
    row(&format!("shared factor of {} and {}, by listing", P, A), listing_gcd(P, A));
    println!("a mix landing on 1: {} x {} + {} x {} = {}", A, x, P, y, A * x + P * y);
    println!("times {}: {} x {} + {} x {} = {}", B, total, x, P * B, y, total * x + P * B * y);
    println!("{} x {} = {} x {}, {} = {} x {}, so {} = {} x {}",
             total, x, P, (total / P) * x, P * B, P, B, B, P, (total / P) * x + B * y);
    row(&format!("the ${} gift shared by {}, remainder", B, P), B % P);
    row(&format!("{} x {} = {} shared by {}, remainder", U, V, U * V, C), (U * V) % C);
    println!("but {} into {} leaves {}, {} into {} leaves {}, gcd({}, {}) = {}",
             C, U, U % C, C, V, V % C, C, U, listing_gcd(C, U));
    assert!(total == 84 && total % P == 0 && A % P == 4 && B % P == 0);
    assert!(A * x + P * y == 1 && total * x + P * B * y == B && (total / P) * x + B * y == B / P && B / P == 3);
    assert!((U * V) % C == 0 && U % C == 4 && V % C == 3 && listing_gcd(C, U) == 2);
    assert!(C % 2 == 0 && U % 2 == 0);   // both even, so every mix of them is even, never 1
    println!("ALL CHECKS PASS");
}
