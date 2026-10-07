// Percentages -- the same check as percentages_check.py, in Rust.  No crates.
// Whole cents throughout: an $80 jacket, 25% off, then 8% sales tax at the
// till, and a 15% tip on a $46 dinner.  Two roads, then both undone.
fn part(amount: i64, percent: i64) -> i64 {   // 25 percent of 8000 cents -> 2000
    amount * percent / 100
}
fn row(name: &str, cents: i64) {
    println!("{:<34}{:>8.2}", name, cents as f64 / 100.0);
}
fn main() {
    let (tag, dinner) = (8000i64, 4600i64);
    let discount = part(tag, 25);
    let sale = tag - discount;
    let tax = part(sale, 8);
    let till = sale + tax;
    let till_2 = part(part(tag, 100 - 25), 100 + 8);    // second road: one multiply each way
    let back_to_sale = till * 100 / (100 + 8);          // undo the tax
    let back_to_tag = back_to_sale * 100 / (100 - 25);  // undo the cut
    let (tip15, tip18) = (part(dinner, 15), part(dinner, 18));
    let wrong_add = part(tag, 100 - 17);                // 25 off then 8 on is not 17 off
    let wrong_back = part(sale, 100 + 25);              // adding 25 back does not undo a cut
    let wrong_pts = (tip15 * 103 + 50) / 100;           // "three percent more", not three points
    for (name, cents) in [("jacket tag price", tag), ("25 percent off, the discount", discount),
                          ("sale price", sale), ("8 percent sales tax", tax),
                          ("total at the till", till), ("the one-multiply road agrees", till_2),
                          ("reversed from the till, the tag", back_to_tag), ("dinner bill", dinner),
                          ("tip at 15 percent", tip15), ("tip at 18 percent, three points", tip18)] {
        row(name, cents);
    }
    println!("mistakes: {:.2}, {:.2} and {:.2}", wrong_add as f64 / 100.0,
             wrong_back as f64 / 100.0, wrong_pts as f64 / 100.0);
    assert!(discount == 2000 && sale == 6000 && till == 6480);
    assert!(till_2 == till && back_to_sale == sale && back_to_tag == tag);
    assert!(tip15 == 690 && tip18 == 828 && wrong_add == 6640 && wrong_back == 7500 && wrong_pts == 711);
    println!("ALL CHECKS PASS");
}
