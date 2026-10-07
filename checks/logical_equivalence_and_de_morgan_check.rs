// Logical equivalence and De Morgan -- the same check as
// logical_equivalence_and_de_morgan_check.py, in Rust.  No crates.  Four dishes, one per
// way nuts and dairy can fall.  Each sentence is worked twice: with and/or/not, then with
// 1s and 0s (and = the smaller, or = the larger, not = 1 minus it).
const DISHES: [(i64, i64); 4] = [(1, 1), (1, 0), (0, 1), (0, 0)];   // (nuts, dairy); 1 means yes

fn word(v: bool) -> &'static str { if v { "yes" } else { "no" } }
fn same(x: &Vec<i64>, y: &Vec<i64>) -> usize { (0..x.len()).filter(|&i| x[i] == y[i]).count() }

fn main() {
    let mut note: Vec<i64> = Vec::new();
    let mut customer: Vec<i64> = Vec::new();
    let mut notboth: Vec<i64> = Vec::new();
    let mut either: Vec<i64> = Vec::new();
    println!("{:<6}{:<6}{:<7}{:<23}{:<22}{:<23}{}", "dish", "nuts", "dairy",
             "no nuts and no dairy", "not (nuts or dairy)", "not (nuts and dairy)", "(no nuts) or (no dairy)");
    for (i, (n, d)) in DISHES.iter().copied().enumerate() {
        let a = (n == 0) && (d == 0);                // the menu note, read straight
        let b = !(n == 1 || d == 1);                 // her reading -- law 1's other side
        let c = !(n == 1 && d == 1);                 // "not both nuts and dairy"
        let e = (n == 0) || (d == 0);                // law 2's other side
        assert!(a as i64 == (1 - n).min(1 - d) && b as i64 == 1 - n.max(d) && a == b);    // law 1
        assert!(c as i64 == 1 - n.min(d) && e as i64 == (1 - n).max(1 - d) && c == e);    // law 2
        note.push(a as i64); customer.push(b as i64); notboth.push(c as i64); either.push(e as i64);
        println!("{:<6}{:<6}{:<7}{:<23}{:<22}{:<23}{}", i + 1, word(n == 1), word(d == 1),
                 word(a), word(b), word(c), word(e));
    }
    let total = |v: &Vec<i64>| -> i64 { v.iter().sum() };
    println!("{:<44}{}", "rows checked", DISHES.len());
    println!("{:<44}{}", "rows where law 1 holds", same(&note, &customer));
    println!("{:<44}{}", "rows where law 2 holds", same(&notboth, &either));
    println!("{:<44}{}", "dishes the menu note lets through", total(&note));
    println!("{:<44}{}", "dishes not-both lets through", total(&notboth));
    println!("{:<44}{}", "rows where not-both and the note disagree", DISHES.len() - same(&note, &notboth));
    assert!(note == vec![0, 0, 0, 1] && customer == vec![0, 0, 0, 1]);
    assert!(notboth == vec![0, 1, 1, 1] && either == vec![0, 1, 1, 1]);
    assert!(same(&note, &customer) == 4 && same(&notboth, &either) == 4 && same(&note, &notboth) == 2);
    assert!(total(&note) == 1 && total(&notboth) == 3);
    println!("ALL CHECKS PASS");
}
