// Quantifiers -- the same check as the Python one, in Rust.  No crates.  An
// office of six people and the three keys they carry.  Each claim is scanned
// twice: once across the people, once down the keys.
const KEYS: [&str; 3] = ["front", "store", "server"];
const OFFICE: [&str; 6] = ["Ana", "Ben", "Cara", "Dev", "Eve", "Finn"];
const CARRIES: [(&str, &[&str]); 6] = [("Ana", &["front", "store"]), ("Ben", &["front"]),
    ("Cara", &["front", "server"]), ("Dev", &["front"]), ("Eve", &["front", "server"]),
    ("Finn", &["store"])];
// held(person) is the keys on that person's ring; the rest counts them two ways.
fn held(p0: &str) -> &'static [&'static str] { CARRIES.iter().find(|(p, _)| *p == p0).unwrap().1 }
fn keys_of(person: &str) -> usize { held(person).len() }
fn holders_of(key: &str, people: &[&str]) -> usize { people.iter().filter(|p| held(p).contains(&key)).count() }
fn least(people: &[&str]) -> usize { people.iter().map(|p| keys_of(p)).min().unwrap() }
fn reach(people: &[&str]) -> usize { KEYS.iter().map(|k| holders_of(k, people)).max().unwrap() }
fn row(name: &str, value: &str) { println!("{:<46}{:>5}", name, value); }
fn yes(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn verdicts(people: &[&str], pad: &str) -> (bool, bool, usize) {   // the two claims, any room
    let (has_key, r) = (least(people) >= 1, reach(people));
    row(&format!("{}everyone has a key", pad), yes(has_key));
    row(&format!("{}there is one key everyone has", pad), yes(r == people.len()));
    row(&format!("{}largest reach of any one key", pad), &r.to_string());
    (has_key, r == people.len(), r)
}

fn main() {
    let across: usize = OFFICE.iter().map(|p| keys_of(p)).sum();          // across the people
    let down: usize = KEYS.iter().map(|k| holders_of(k, &OFFICE)).sum();  // down the keys
    row(&format!("people {}, keys {}, carryings added across", OFFICE.len(), KEYS.len()), &across.to_string());
    let per_person: Vec<String> = OFFICE.iter().map(|p| format!("{} {}", p, keys_of(p))).collect();
    let per_key: Vec<String> = KEYS.iter().map(|k| format!("{} {}", k, holders_of(k, &OFFICE))).collect();
    println!("keys carried, person by person   {}", per_person.join("  "));
    println!("people reached, key by key       {}", per_key.join("  "));
    row("the same carryings added down the keys", &down.to_string());
    let full = verdicts(&OFFICE, "");
    println!("shrink the office to the five who carry front");
    let small = verdicts(&OFFICE[..5], "  ");
    assert!(across == 9 && down == across);
    assert!(full == (true, false, 5) && small == (true, true, 5));
    println!("ALL CHECKS PASS");
}
