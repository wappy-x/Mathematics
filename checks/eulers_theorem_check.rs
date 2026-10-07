// Euler's theorem -- the same check as eulers_theorem_check.py, in Rust.  No
// crates.  The last two digits of 3 to the 2026 on the 100-clock: phi(100) = 40
// and 2026 = 50 x 40 + 26.
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }   // the largest common divisor
fn product(xs: &[i64], n: i64) -> i64 {         // multiply a list together on the n-clock
    let mut p = 1i64;
    for x in xs { p = p * x % n; }
    p
}
fn power_mod(base: i64, e: i64, n: i64) -> i64 { product(&vec![base; e as usize], n) }
fn row(name: &str, value: i64) { println!("{:<36}{:>6}", name, value); }
fn main() {
    let (n, a, big) = (100i64, 3i64, 2026i64);
    let units: Vec<i64> = (1..n).filter(|u| gcd(*u, n) == 1).collect();   // the coprime residues
    let phi = units.len() as i64;
    let phi_factored = n / 2 * (2 - 1) / 5 * (5 - 1);                     // half of 100, then four fifths
    let mut shuffled: Vec<i64> = units.iter().map(|u| a * u % n).collect();
    shuffled.sort();
    let (q, rem) = (big / phi, big % phi);
    row("gcd(3, 100)", gcd(a, n));
    row("phi(100), counted one by one", phi);
    row("phi(100), from 100 = 2 x 2 x 5 x 5", phi_factored);
    row("3 to the 40 (mod 100)", power_mod(a, phi, n));
    println!("the same 40 come back, in a different order: {} of {} once sorted; multiplied, {} before and {} after",
             (0..units.len()).filter(|i| shuffled[*i] == units[*i]).count(), phi,
             product(&units, n), product(&shuffled, n));
    println!("{} = {} x {} + {}", big, q, phi, rem);
    row("3 to the 26 (mod 100), the shortcut", power_mod(a, rem, n));
    row("3 to the 2026 (mod 100), ground out", power_mod(a, big, n));
    println!("the mistakes: 10 to the {} gives {}, 2 to the {} gives {}, 3 to the {} gives {}, 3 to the {} gives {}",
             phi, power_mod(10, phi, n), phi, power_mod(2, phi, n), n - 1, power_mod(a, n - 1, n), q, power_mod(a, q, n));
    println!("the wrong cut hides here but shows on the 7-clock: 3 to the 10 is {} cut by 6, {} cut by 7",
             power_mod(a, 10 % 6, 7), power_mod(a, 10 % 7, 7));
    assert!(gcd(a, n) == 1 && phi == 40 && phi_factored == 40);
    assert!(shuffled == units && product(&units, n) == product(&shuffled, n) && power_mod(a, phi, n) == 1);
    assert!(power_mod(a, big, n) == 29 && power_mod(a, rem, n) == 29);
    assert!(power_mod(a, 10 % 6, 7) == power_mod(a, 10, 7) && power_mod(a, 10, 7) != power_mod(a, 10 % 7, 7));
    println!("ALL CHECKS PASS");
}
