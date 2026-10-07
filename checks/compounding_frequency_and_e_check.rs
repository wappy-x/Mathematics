// Compounding more often, and the number e -- the same check as the Python one,
// in Rust.  No crates.  $1 at 100% for a year, the rate split n ways and
// multiplied in n times, then the ceiling by the series 1 + 1 + 1/2 + 1/6 + ...
fn ladder(rate: f64, n: u64) -> f64 {      // (1 + rate/n) multiplied in, n times over
    let mut total = 1.0;
    for _ in 0..n { total = total * (1.0 + rate / n as f64); }
    total
}
fn series(rate: f64) -> f64 {              // 1 + rate + rate x rate / 2 + ... , 20 terms
    let (mut total, mut term) = (0.0, 1.0);
    for k in 1..21 { total += term; term = term * rate / k as f64; }
    total
}
fn row(name: &str, value: f64, places: usize) {
    println!("{:<33}{:>13.p$}", name, value, p = places);
}
fn main() {
    let steps: [(&str, u64); 5] = [("paid once a year", 1), ("paid twice a year", 2),
        ("paid monthly, 12 times", 12), ("paid daily, 365 times", 365),
        ("paid a million times", 1000000)];
    for (name, n) in steps { row(name, ladder(1.0, n), 6); }
    row("the ceiling, e by the series", series(1.0), 6);
    row("e, to nine decimals", series(1.0), 9);
    let yearly = 100.0 * ladder(0.05, 1);
    let cont = 100.0 * series(0.05);
    row("$100 at 5%, paid once a year", yearly, 2);
    row("$100 at 5%, paid continuously", cont, 6);
    row("$100 continuous, to the cent", (cont * 100.0).round() / 100.0, 2);
    assert!((ladder(1.0, 2) - 2.25).abs() < 1e-12);
    assert!((series(1.0) - ladder(1.0, 1000000)).abs() < 1e-5);
    assert!(((yearly * 100.0).round() / 100.0 - 105.00).abs() < 1e-9
        && ((cont * 100.0).round() / 100.0 - 105.13).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
