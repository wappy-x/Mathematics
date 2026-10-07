// Strings with repetition -- the same check as the Python, in Rust.  No crates.
// A 4-digit PIN, a licence plate of 3 letters then 3 digits, and the travelling
// parties from a 20-player squad.  Every count is reached twice: once by
// building every string and counting them, once by a road that lists nothing.
const DIGITS: &str = "0123456789";
const LETTERS: &str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

fn strings(options: &str, k: usize) -> Vec<String> {   // road one: build every string
    let mut out = vec![String::new()];
    for _ in 0..k {
        let mut next: Vec<String> = Vec::new();
        for s in &out { for ch in options.chars() { next.push(format!("{}{}", s, ch)) } }
        out = next;
    }
    out
}

fn product(factors: &[u64]) -> u64 { factors.iter().fold(1, |a, b| a * b) }   // nothing else

fn power(n: u64, k: usize) -> u64 { product(&vec![n; k]) }               // road two
fn falling(n: u64, k: u64) -> u64 { product(&(n - k + 1..=n).collect::<Vec<u64>>()) }

fn c(n: u64) -> String {                // separators, as the card quotes them
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') } out.push(ch) }
    out
}

fn triangle_row(n: usize) -> Vec<u64> { // road three: additions only, nothing multiplied
    let mut row = vec![1u64];
    for _ in 0..n {
        let mut next = vec![0u64; row.len() + 1];
        for (i, v) in row.iter().enumerate() { next[i] += v; next[i + 1] += v }
        row = next;
    }
    row
}

fn all_different(s: &str) -> bool {     // true when no symbol is used twice
    let mut seen: Vec<char> = Vec::new();
    for ch in s.chars() { if seen.contains(&ch) { return false } seen.push(ch) }
    true
}

fn main() {
    let small = strings("012", 2);
    let pins = strings(DIGITS, 4);
    let (plate_letters, plate_digits) = (strings(LETTERS, 3), strings(DIGITS, 3));
    let (plate, np) = ((plate_letters.len() * plate_digits.len()) as u64, pins.len() as u64);
    let stages: Vec<u64> = (0..5).map(|k| strings(DIGITS, k).len() as u64).collect();
    let parties = triangle_row(20); let total: u64 = parties.iter().sum();
    let alldiff = pins.iter().filter(|s| all_different(s)).count() as u64;
    println!("small case, 2 positions over the digits 0, 1, 2: 3 x 3 = {} strings", small.len());
    println!("the nine of them: {}", small.join(" "));
    println!("PIN stages, 0 to 4 positions built: {}", stages.iter().map(|&v| c(v)).collect::<Vec<String>>().join(", "));
    println!("PIN: 10 digits, 4 positions -> built {} strings, 10^4 = {}", c(np), c(power(10, 4)));
    println!("the first and the last PIN built: {} and {}", pins[0], pins[pins.len() - 1]);
    println!("plate letters: built {}, 26^3 = {}", c(plate_letters.len() as u64), c(power(26, 3)));
    println!("plate digits: built {}, 10^3 = {}", c(plate_digits.len() as u64), c(power(10, 3)));
    println!("whole plate: {} x {} = {}", c(plate_letters.len() as u64), c(plate_digits.len() as u64), c(plate));
    println!("squad of 20, each player in or out: 2^20 = {}", c(power(2, 20)));
    println!("the same total by adding only, row 20 of the sum triangle: {}", c(total));
    println!("parties by size, the first six entries of that row: {:?}", &parties[..6]);
    println!("12-player squad both ways: built {} strings, row 12 totals {}",
             c(strings("io", 12).len() as u64), c(triangle_row(12).iter().sum::<u64>()));
    println!("a byte, 8 positions over 2 options: 2^8 = {}", c(power(2, 8)));
    println!("mistake 1, adding the options: 10 + 10 + 10 + 10 = {}, not {}", 10 * 4, c(np));
    println!("mistake 2, no digit reused: 10 x 9 x 8 x 7 = {}, and the built PINs with four different digits number {}",
             c(falling(10, 4)), c(alldiff));
    println!("mistake 3, options and positions swapped: 4^10 = {}, not {}", c(power(4, 10)), c(power(10, 4)));
    println!("mistake 4, the plate read as one 36-symbol alphabet: 36^6 = {}, not {}", c(power(36, 6)), c(plate));
    assert!(np == power(10, 4) && np == 10000 && stages == (0..5).map(|k| power(10, k)).collect::<Vec<u64>>());
    assert!((plate_letters.len() * plate_digits.len()) as u64 == power(26, 3) * power(10, 3) && plate == 17_576_000);
    assert!(total == power(2, 20) && triangle_row(12).iter().sum::<u64>() == strings("io", 12).len() as u64);
    assert!(alldiff == falling(10, 4) && alldiff < np);
    println!("ALL CHECKS PASS");
}
