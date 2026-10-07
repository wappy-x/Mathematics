// Discounting -- the same check as the Python one, in Rust.  No crates.  A $100
// payment due later, priced today at 5%: divide by 1.05 once a year, then the
// continuous version, its factor from the series 1 + x + x times x / 2 + ...
const FACE: f64 = 100.0;  const RATE: f64 = 0.05;  const YEARS: usize = 10;
fn series(x: f64) -> f64 {                 // 1 + x + x times x / 2 + ... , 20 terms
    let (mut total, mut term) = (0.0, 1.0);
    for k in 1..21 { total += term; term = term * x / k as f64; }
    total
}
fn back(n: usize) -> f64 {                 // the payment divided by 1.05, n times over
    let mut value = FACE;
    for _ in 0..n { value = value / (1.0 + RATE); }
    value
}
fn row(name: &str, value: f64, p: usize) { println!("{:<38}{:>12.p$}", name, value, p = p); }
fn grid(name: &str, values: Vec<String>) {
    println!("{:<30}{}", name, values.iter().map(|v| format!("{:>7}", v)).collect::<Vec<_>>().join(""));
}
fn main() {
    grid("years until the payment", (0..=YEARS).map(|y| y.to_string()).collect());
    grid("the payment itself, always", (0..=YEARS).map(|_| format!("{:.2}", FACE)).collect());
    grid("what it is worth today", (0..=YEARS).map(|y| format!("{:.2}", back(y))).collect());
    let (one, ten, grow) = (back(1), back(YEARS), series(RATE));
    row("discount factor, one year", one / FACE, 6);
    row("$100 due in one year, worth today", one, 2);
    row("discount factor, ten years", ten / FACE, 6);
    row("$100 due in ten years, worth today", ten, 2);
    row("continuous growth factor, one year", grow, 6);
    row("continuous discount factor, one year", 1.0 / grow, 6);
    row("$100 due in one year, continuously", FACE / grow, 2);
    println!("the three mistakes come out at {:.2}, {:.2} and {:.2}",
             FACE * 0.95, one, FACE * 0.95f64.powi(YEARS as i32));
    let (mut num, mut den): (i128, i128) = (2 * 10000, 1);       // whole numbers only
    for _ in 0..YEARS { num *= 20; den *= 21; }
    let cents = (num + den) / (2 * den);
    assert!(cents == 6139 && (ten * 100.0).round() as i128 == cents && (one * 100.0).round() as i64 == 9524);
    assert!((ten * (1.0 + RATE).powi(YEARS as i32) - FACE).abs() < 1e-9);  // discounted, grown back
    assert!((1.0 / grow - series(-RATE)).abs() < 1e-12 && (FACE / grow * 100.0).round() as i64 == 9512);
    println!("ALL CHECKS PASS");
}
