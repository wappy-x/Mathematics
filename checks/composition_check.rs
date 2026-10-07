// Composing functions -- the same check as composition_check.py, in Rust.  No crates.  A $50 item and two offers: 20% off,
// and $5 off.  Each offer is a rule that takes a price in whole cents and hands back a price.  Every chain is walked step
// by step, then again as one collapsed rule, and the two roads must agree.
const PRICE: i64 = 5000;
const COUPON: i64 = 500;
const OTHER: i64 = 8000;
fn percent_off(c: i64) -> i64 { c * 4 / 5 }        // the 20% offer: keep four fifths; these prices are whole multiples of five cents, so it is exact
fn coupon_off(c: i64) -> i64 { c - COUPON }        // the $5 offer
fn nothing(c: i64) -> i64 { c }                    // the do-nothing rule
fn money(c: i64) -> String { format!("${}.{:02}", c / 100, c % 100) }
fn chain(rules: &[fn(i64) -> i64], c: i64) -> Vec<i64> {   // do the first rule, feed its answer to the next
    let mut steps = vec![c];
    for rule in rules { steps.push(rule(*steps.last().unwrap())); }
    steps
}
fn walk(rules: &[fn(i64) -> i64], c: i64) -> String {
    chain(rules, c).iter().map(|s| money(*s)).collect::<Vec<String>>().join(" -> ")
}
fn row(name: &str, value: &str) { println!("{:<38}{}", name, value); }
fn main() {
    let first: &[fn(i64) -> i64] = &[percent_off, coupon_off];
    let second: &[fn(i64) -> i64] = &[coupon_off, percent_off];
    let (pc, cp) = (*chain(first, PRICE).last().unwrap(), *chain(second, PRICE).last().unwrap());
    let (pc_rule, cp_rule) = (percent_off(PRICE) - COUPON, percent_off(PRICE) - percent_off(COUPON));   // each chain again, as one rule
    let (pc2, cp2) = (*chain(first, OTHER).last().unwrap(), *chain(second, OTHER).last().unwrap());
    let none_then_pc = *chain(&[nothing, percent_off], PRICE).last().unwrap();
    row("item price", &money(PRICE));
    row("20% off, then $5 off, step by step", &walk(first, PRICE));
    row("$5 off, then 20% off, step by step", &walk(second, PRICE));
    row("coupon after percent, as one rule", &format!("0.8 x price - {} = {}", money(COUPON), money(pc_rule)));
    row("percent after coupon, as one rule", &format!("0.8 x price - {} = {}", money(percent_off(COUPON)), money(cp_rule)));
    row("the two orders differ by", &format!("{}, which is 20% of the {} coupon", money(cp - pc), money(COUPON)));
    row(&format!("on an {} item, the two orders", money(OTHER)), &format!("{} and {}, still {} apart", money(pc2), money(cp2), money(cp2 - pc2)));
    row("do nothing, then 20% off", &format!("{} -- 20% off on its own", money(none_then_pc)));
    assert!(pc == 3500 && cp == 3600 && cp - pc == 100);
    assert!(pc == pc_rule && cp == cp_rule && percent_off(COUPON) == 400);
    assert!(pc2 == 5900 && cp2 == 6000 && none_then_pc == 4000);
    println!("ALL CHECKS PASS");
}
