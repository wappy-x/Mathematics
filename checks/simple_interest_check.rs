// Simple interest -- the same check as simple_interest_check.py, in Rust.  No
// crates.  $500 lent to a cousin at 4% a year, simple interest, five years.
// Two roads: the one-line formula, and adding the same $20.00 on five times.
fn row(name: &str, value: f64) {
    println!("{:<38}{:>10}", name, format!("${:.2}", value));
}

fn main() {
    let (principal, rate, years) = (500.00f64, 0.04f64, 5);
    let per_year = principal * rate;                 // the same $20.00 every year
    let mut balance = principal;
    let mut steps = vec![principal];
    for _ in 0..years {                              // road 1: add it on, year by year
        balance = balance + per_year;
        steps.push(balance);
    }
    let by_formula = principal * rate * years as f64;   // road 2: straight to the total
    let wrong_rate = principal + principal * 4.0 * years as f64;
    let mut compound = principal;
    for _ in 0..years {
        compound = compound * (1.0 + rate);          // the mistake: interest on interest
    }
    row("principal lent to the cousin", principal);
    row("interest each year, 500.00 x 0.04", per_year);
    let cells: Vec<String> = steps.iter().map(|b| format!("${:.2}", b)).collect();
    println!("{:<38}{}", "balance, years 0 to 5", cells.join(" "));
    row("interest after five years, added up", balance - principal);
    row("the same by principal x rate x years", by_formula);
    row("step from each year to the next", steps[1] - steps[0]);
    row("to repay after five years", balance);
    row("if the interest earned interest", compound);
    row("if 4% were read as 4", wrong_rate);
    assert!((per_year - 20.00).abs() < 1e-9 && (balance - 600.00).abs() < 1e-9);
    assert!((by_formula - 100.00).abs() < 1e-9 && (balance - principal - by_formula).abs() < 1e-9);
    for (i, b) in steps.iter().enumerate() {
        assert!((b - (500.00 + 20.00 * i as f64)).abs() < 1e-9);
    }
    println!("ALL CHECKS PASS");
}
