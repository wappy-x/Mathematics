// Sets and membership -- the same check as sets_and_membership_check.py, in
// Rust.  No crates.  The office is five people with ages.  The guest list is
// everyone under 30, written out by name and built again from the rule.
const OFFICE: [(&str, i64); 5] = [("Ana", 24), ("Ben", 31), ("Cleo", 28), ("Dev", 41), ("Eli", 29)];

fn under_30(age: i64) -> bool { age < 30 }   // the party rule, strict: a 30-year-old is out
fn as_set(names: &[&str]) -> Vec<String> {   // a set: repeats dropped, order thrown away
    let mut out: Vec<String> = Vec::new();
    for n in names { if !out.contains(&n.to_string()) { out.push(n.to_string()); } }
    out.sort();
    out
}
fn by_rule(test: fn(i64) -> bool) -> Vec<String> {   // keep the office people it says yes to
    as_set(&OFFICE.iter().filter(|(_, age)| test(*age)).map(|(n, _)| *n).collect::<Vec<&str>>())
}
fn row(name: &str, value: String) { println!("{:<30}{:>6}", name, value); }
fn yes_no(b: bool) -> String { String::from(if b { "True" } else { "False" }) }
fn has(set: &[String], name: &str) -> bool { set.contains(&name.to_string()) }

fn main() {
    let names = ["Eli", "Ana", "Cleo", "Ana"];             // scrambled, one name twice
    let written = as_set(&["Ana", "Cleo", "Eli"]);         // the list, written out
    let guests = by_rule(under_30);                        // the same list, from the rule
    row("people in the office", OFFICE.len().to_string());
    row("guests, by the rule", guests.len().to_string());
    row("guests, written out", written.len().to_string());
    row("same guests either way", yes_no(guests == written));
    row("Ana is on the list", yes_no(has(&guests, "Ana")));
    row("Ben is on the list", yes_no(has(&guests, "Ben")));
    row("scrambled spelling, guests", as_set(&names).len().to_string());
    row("nobody in the office under 20", by_rule(|age| age < 20).len().to_string());
    row("nobody in the office over 60", by_rule(|age| age > 60).len().to_string());
    row("the two empty lists agree", yes_no(by_rule(|age| age < 20) == by_rule(|age| age > 60)));
    println!("count the repeat: {} guests; count the orders: {} spellings; drop the rule: {} guests", names.len(), 3 * 2 * 1, OFFICE.len());
    assert!(guests == written && as_set(&names) == written);   // order and repeats do not count
    assert!(OFFICE.iter().all(|(n, age)| under_30(*age) == has(&written, n)));   // person by person
    assert!(guests.len() == 3 && OFFICE.len() == 5 && by_rule(|age| age > 60).len() == 0 && !under_30(30));
    println!("ALL CHECKS PASS");
}
