// Valid arguments -- the same check as valid_arguments_check.py, in Rust.  No
// crates.  The landlord's rule: "if the rent is late, a $50 fee applies."
// Four tenants argue from it.  1 for yes, 0 for no, over every (late, fee).
const CASES: [(i64, i64); 4] = [(0, 0), (0, 1), (1, 0), (1, 1)];
type Rule = fn(i64, i64) -> i64;
type Arg = (&'static str, fn(Rule, i64, i64) -> [i64; 2], fn(i64, i64) -> i64);
fn rule(late: i64, fee: i64) -> i64 {      // the rule, broken only by a late rent and no fee
    if late == 1 && fee == 0 { 0 } else { 1 }
}
fn or_rule(late: i64, fee: i64) -> i64 {   // the second route: the same rule as "not late, or a fee"
    if late == 0 || fee == 1 { 1 } else { 0 }
}
fn holds(arg: &Arg, r: Rule, l: i64, f: i64) -> bool { (arg.1)(r, l, f).iter().all(|&p| p == 1) }
fn bad_rows(arg: &Arg, r: Rule) -> Vec<(i64, i64)> {   // premises all hold, conclusion fails
    CASES.iter().cloned().filter(|&(l, f)| holds(arg, r, l, f) && (arg.2)(l, f) == 0).collect()
}
fn main() {
    let args: [Arg; 4] = [("Rosa  (ponens)", |r, l, f| [r(l, f), l], |_l, f| f),
        ("Sam   (tollens)", |r, l, f| [r(l, f), 1 - f], |l, _f| 1 - l),
        ("Tess  (consequent)", |r, l, f| [r(l, f), f], |l, _f| l),
        ("Vic   (antecedent)", |r, l, f| [r(l, f), 1 - l], |_l, f| 1 - f)];
    println!("{:<19}{:>14}{:>16}{:>9}{:>14}", "argument", "premises hold", "counterexamples", "verdict", "second route");
    let (mut fits, mut bad, mut second) = (Vec::new(), Vec::new(), Vec::new());
    for arg in &args {
        fits.push(CASES.iter().filter(|&&(l, f)| holds(arg, rule, l, f)).count());
        bad.push(bad_rows(arg, rule).len());
        second.push(bad_rows(arg, or_rule).len());
        let verdict = if bad[bad.len() - 1] == 0 { "VALID" } else { "INVALID" };
        println!("{:<19}{:>14}{:>16}{:>9}{:>14}", arg.0, fits[fits.len() - 1], bad[bad.len() - 1], verdict, second[second.len() - 1]);
    }
    let rule_false = CASES.iter().filter(|&&(l, f)| rule(l, f) == 0).count();
    println!("cases checked {}", CASES.len());
    println!("the rule by itself is false on cases {}", rule_false);
    let killer = bad_rows(&args[2], rule)[0];
    println!("both look-alikes fail on the same case: late {}, fee {}", killer.0, killer.1);
    assert!(fits == vec![1, 1, 2, 2] && bad == second);
    assert!(bad == vec![0, 0, 1, 1] && rule_false == 1);
    assert!(bad_rows(&args[2], rule) == vec![(0, 1)] && bad_rows(&args[3], rule) == vec![(0, 1)]);
    println!("ALL CHECKS PASS");
}
