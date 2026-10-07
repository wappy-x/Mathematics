// Natural log and doubling time -- the same check as the Python one, in Rust.
// No crates.  ln is the series 2 * (y + y*y*y/3 + ...), y = (x - 1)/(x + 1).
// Road one is ln 2 / ln 1.08; road two multiplies 1.08 by itself 9 and 10
// times, and the doubling has to land between the two.
fn ln(x: f64) -> f64 {                       // natural log, built here from the series
    let y = (x - 1.0) / (x + 1.0);
    let (mut term, mut total, mut k) = (y, 0.0f64, 1i64);
    while term.abs() > 1e-18 { total += term / k as f64; term *= y * y; k += 2; }
    2.0 * total
}
fn grown(factor: f64, years: i64) -> f64 {   // the factor multiplied by itself
    let mut out = 1.0f64;
    for _ in 0..years { out *= factor; }
    out
}
fn row(name: &str, value: String) { println!("{:<40}{:>12}", name, value); }
fn main() {
    let ln2 = ln(2.0);
    let (eight, five) = (ln2 / ln(1.08), ln2 / ln(1.05));
    row("ln 2", format!("{:.6}", ln2));
    row("ln 1.08 and ln 1.05", format!("{:.6} and {:.6}", ln(1.08), ln(1.05)));
    row("100 x ln 2, the honest rule number", format!("{:.4}", 100.0 * ln2));
    for (rate, factor) in [(8.0f64, 1.08f64), (5.0, 1.05)] {
        row(&format!("years to double at {}%, ln 2 / ln {}", rate, factor), format!("{:.3}", ln2 / ln(factor)));
        row(&format!("the rule of 72 at {}%, 72 / {}", rate, rate), format!("{:.3}", 72.0 / rate));
    }
    row("1.08 multiplied by itself 9 times", format!("{:.6}", grown(1.08, 9)));
    row("1.08 multiplied by itself 10 times", format!("{:.6}", grown(1.08, 10)));
    row("$100 at 5% after 14 years, then 15", format!("${:.2} ${:.2}", 100.0 * grown(1.05, 14), 100.0 * grown(1.05, 15)));
    println!("the three mistakes come out at {}, {:.3} and {:.6}", 100.0 / 8.0, ln2 / 0.08, grown(1.08, 9));
    assert!((ln(1.25) + ln(1.6) - ln2).abs() < 1e-14 && (ln(0.5) / ln(0.9) - 6.579).abs() < 5e-4);
    assert!(grown(1.08, 9) < 2.0 && 2.0 < grown(1.08, 10) && format!("{:.2} {:.2}", 100.0 * grown(1.05, 14), 100.0 * grown(1.05, 15)) == "197.99 207.89");
    assert!(9.0 < eight && eight < 10.0 && 14.0 < five && five < 15.0 && 72.0 / 8.0 < eight && five < 72.0 / 5.0);
    println!("ALL CHECKS PASS");
}
