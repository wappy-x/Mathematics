// Counting the complement -- the same check as the Python, in Rust.  No crates.  A
// 6-character password from 26 letters and 10 digits must carry at least one digit.
// The count is reached twice: the whole collection minus the letters-only passwords,
// and by adding the six "exactly k digits" terms.  A toy version is then listed string
// by string, and a 20-player squad subset by subset, against the same closed forms.
const LETTERS: i64 = 26;
const DIGITS: i64 = 10;
const LENGTH: u32 = 6;
const SQUAD: i64 = 20;
const PICK: u32 = 11;
const KEEPERS: i64 = 2;
const TL: i64 = 3;                          // toy size: 3 letters, 2 digits, length 4
const TD: i64 = 2;
const TN: u32 = 4;

fn comb(n: i64, k: i64) -> i64 {            // n choose k, multiplied out, no crates
    let mut out = 1;
    for i in 0..k {
        out = out * (n - i) / (i + 1);
    }
    out
}

fn main() {
    let total = (LETTERS + DIGITS).pow(LENGTH);                  // every password
    let letters_only = LETTERS.pow(LENGTH);                      // the complement: no digit
    let by_subtraction = total - letters_only;                   // road one
    let terms: Vec<i64> = (1..=LENGTH)
        .map(|k| comb(LENGTH as i64, k as i64) * DIGITS.pow(k) * LETTERS.pow(LENGTH - k))
        .collect();
    let by_terms: i64 = terms.iter().sum();                      // road two: exactly k digits
    let share = 100.0 * by_subtraction as f64 / total as f64;

    let (mut toy_all, mut toy_letters) = (0i64, 0i64);
    for code in 0..(TL + TD).pow(TN) {                           // every toy string, listed
        let (mut c, mut seen) = (code, false);
        for _ in 0..TN {
            seen = seen || c % (TL + TD) >= TL;
            c /= TL + TD;
        }
        toy_all += 1;
        toy_letters += if seen { 0 } else { 1 };
    }
    let toy_listed = (toy_all, toy_letters, toy_all - toy_letters);
    let toy_closed = ((TL + TD).pow(TN), TL.pow(TN), (TL + TD).pow(TN) - TL.pow(TN));

    let (mut elevens, mut keeperless) = (0i64, 0i64);
    for mask in 0..(1u32 << SQUAD) {                             // every subset of the squad, listed
        if mask.count_ones() == PICK {
            elevens += 1;
            keeperless += if mask & ((1u32 << KEEPERS) - 1) != 0 { 0 } else { 1 };
        }
    }
    let squad_listed = (elevens, keeperless, elevens - keeperless);
    let squad_closed = (comb(SQUAD, PICK as i64), comb(SQUAD - KEEPERS, PICK as i64),
                        comb(SQUAD, PICK as i64) - comb(SQUAD - KEEPERS, PICK as i64));
    let digit_first = LENGTH as i64 * DIGITS * (LETTERS + DIGITS).pow(LENGTH - 1);
    let keeper_first = KEEPERS * comb(SQUAD - 1, PICK as i64 - 1);

    println!("all 6-character passwords from 36 symbols: 36^6 = {}", total);
    println!("passwords with no digit at all, 26 letters only: 26^6 = {}", letters_only);
    println!("at least one digit, by subtraction: {} - {} = {}", total, letters_only, by_subtraction);
    println!("at least one digit, by adding the six exact-count terms: {}", by_terms);
    println!("exactly 1, 2, 3, 4, 5, 6 digits: {:?}", terms);
    println!("share of all passwords the rule allows: {:.2}%", share);
    println!("toy question, 3 letters and 2 digits in strings of 4, every string listed: {:?}", toy_listed);
    println!("the same toy counts from the closed forms: {:?}", toy_closed);
    println!("every starting eleven from 20 players: C(20,11) = {}", squad_closed.0);
    println!("elevens with no goalkeeper, 11 from the other 18: C(18,11) = {}", squad_closed.1);
    println!("at least one goalkeeper, by subtraction: {} - {} = {}", squad_closed.0, squad_closed.1, squad_closed.2);
    println!("the same three counts by listing all {} subsets: {:?}", 1i64 << SQUAD, squad_listed);
    println!("mistake 1, a digit placed first then the rest free: 6 x 10 x 36^5 = {}, over the {} that exist", digit_first, total);
    println!("mistake 2, complement read as exactly one digit: {} - {} = {}", total, terms[0], total - terms[0]);
    println!("mistake 3, a keeper placed first then ten from 19: 2 x C(19,10) = {}, over the {} that exist", keeper_first, squad_closed.0);
    assert!(by_subtraction == by_terms);              // subtraction against the six separate terms
    assert!(toy_listed == toy_closed);                // 625 strings listed against the closed forms
    assert!(squad_listed == squad_closed);            // 1,048,576 subsets listed against C(n, k)
    assert!(digit_first > total && keeper_first > squad_closed.0);  // both overcounts break their ceilings
    println!("ALL CHECKS PASS");
}
