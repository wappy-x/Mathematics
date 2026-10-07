// Decimals -- the same check as decimals_check.py, in Rust.  No crates.
// Petrol at $1.85 a litre into a 42.5-litre tank, and a receipt that has to
// land on a whole cent.  Three roads to the same total, all in whole numbers.
fn row(name: &str, value: &str) { println!("{:<36}{:>9}", name, value); }
fn point(thousandths: i64) -> String {    // 78625 -> "78.625", the point put back
    format!("{}.{:03}", thousandths / 1000, thousandths % 1000)
}
fn money(cents: i64) -> String { format!("{}.{:02}", cents / 100, cents % 100) }
fn main() {
    let (price, litres) = (185i64, 425i64);   // $1.85 as hundredths, 42.5 as tenths
    let total = price * litres;               // thousandths of a dollar
    row("$1.85 is 185 over 100", &price.to_string());
    row("42.5 litres is 425 over 10", &litres.to_string());
    row("185 x 425, both whole numbers", &total.to_string());
    row("78625 over 1000, the point back", &point(total));
    let (top, bottom) = (37i64 * 85, 20i64 * 2);   // the fraction road, 3145 over 40
    row("37/20 x 85/2 = 3145/40, reduced", &format!("{}/{}", top / 5, bottom / 5));
    row("629 divided by 8", &point(top * 1000 / bottom));
    let (whole, half) = (price * 420, price * 5);  // 42 litres, then the half litre
    row(&format!("42 litres {}, half litre {}", point(whole), point(half)),
        &point(whole + half));
    let cents = (total + 5) / 10;             // to the nearest cent, a half goes up
    row("the receipt, rounded to the cent", &money(cents));
    row("columns right of the point", "0.1 0.01 0.001");
    println!("mistakes: {}, {}, and 43 litres gives {}",
             money(total / 10), money(total), money(price * 430 / 10));
    assert!(total == 78625 && top * 1000 / bottom == total);   // two roads, one answer
    assert!(whole + half == total && top / 5 == 629 && bottom / 5 == 8);
    assert!(cents == 7863 && 629 * 125 == total);  // 629/8 is 78.625, and 1/8 is 0.125
    assert!(point(total) == "78.625" && money(cents) == "78.63");  // the printed strings
    println!("ALL CHECKS PASS");
}
