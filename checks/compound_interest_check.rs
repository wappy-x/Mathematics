// Compound interest -- the same check as the Python, in Rust.  No crates.  $100
// in a savings account paying 5% a year, the interest left in.  Dollars are
// rounded to the cent for printing only; the running balance is kept in full.
const YEARS: usize = 10;
const START: f64 = 100.0;
const RATE: f64 = 0.05;
fn grid(name: &str, values: &[String]) {
    let mut line = format!("{:<32}", name);
    for v in values { line.push_str(&format!("{:>7}", v)); }
    println!("{}", line);
}
fn one(name: &str, value: String) { println!("{:<44}{:>10}", name, value); }
fn main() {
    let (mut comp, mut simp) = (vec![START], vec![START]);   // year 0: $100 each
    for _ in 0..YEARS {                                      // one road: a year at a time
        comp.push(comp[comp.len() - 1] * (1.0 + RATE));      // 5% of the balance, left in
        simp.push(simp[simp.len() - 1] + START * RATE);      // 5% of the first $100
    }
    let years: Vec<String> = (0..=YEARS).map(|y| y.to_string()).collect();
    let cs: Vec<String> = comp.iter().map(|v| format!("{:.2}", v)).collect();
    let ss: Vec<String> = simp.iter().map(|v| format!("{:.2}", v)).collect();
    grid("year", &years);
    grid("compound, interest left in", &cs);
    grid("simple, interest taken out", &ss);
    println!("interest earned in years 1, 2, 3 and 10: {:.2}, {:.2}, {:.2} and {:.2}",
             comp[1] - comp[0], comp[2] - comp[1], comp[3] - comp[2], comp[10] - comp[9]);
    one("after ten years, interest left in", format!("{:.2}", comp[10]));
    one("after ten years, interest taken out", format!("{:.2}", simp[10]));
    one("the gap", format!("{:.2}", comp[10] - simp[10]));
    let mut exact: i128 = 1;                      // second road: whole numbers only
    for _ in 0..YEARS { exact *= 105; }
    let cents = (exact + 5 * 10i128.pow(15)) / 10i128.pow(16);   // to the cent
    one("the same balance, from whole numbers", format!("{}.{:02}", cents / 100, cents % 100));
    println!("the three mistakes come out at {:.2}, {:.2} and {:.2}",
             simp[10], START * (1.0 + RATE), START * (1.0 + RATE) * 0.95);
    assert!(cents == 16289 && (comp[10] * 100.0).round() as i128 == cents && comp.len() == simp.len() && simp.len() == YEARS + 1);
    assert!((comp[5] * comp[5] / START - comp[10]).abs() < 1e-9);  // five years, squared
    assert!(simp[10] == 150.0 && ((comp[10] - simp[10]) * 100.0).round() as i64 == 1289);
    println!("ALL CHECKS PASS");
}
