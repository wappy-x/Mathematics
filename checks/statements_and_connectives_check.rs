// Statements and connectives -- the same check as statements_and_connectives_check.py,
// in Rust.  No crates.  The club door after 9 pm: show ID and be over 21.  Two
// facts per person, so four rows.  Every row is worked twice: straight from the
// words, then by counting how many of the two facts came out true.
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn count(col: &[bool]) -> usize { col.iter().filter(|b| **b).count() }

fn main() {
    let door = [("Nia", true, true), ("Sam", true, false),
                ("Ray", false, true), ("Jo", false, false)];
    let (mut ands, mut ors, mut nots, mut ones) = (vec![], vec![], vec![], vec![]);
    let mut agree = 0;

    println!("the door after 9 pm: show ID and be over 21");
    println!("{:<6}{:>11}{:>9}{:>13}{:>16}{:>15}",
             "name", "showed ID", "over 21", "not over 21", "ID and over 21", "ID or over 21");
    for (name, shown, older) in door {
        let both = shown && older;                       // straight from the words
        let either = shown || older;
        let trues = count(&[shown, older]);              // the second road: count the trues
        if both == (trues == 2) && either == (trues >= 1) { agree += 1; }
        ands.push(both); ors.push(either); nots.push(!older); ones.push(trues == 1);
        println!("{:<6}{:>11}{:>9}{:>13}{:>16}{:>15}",
                 name, yn(shown), yn(older), yn(!older), yn(both), yn(either));
    }
    println!("and lets in {} of 4, or lets in {} of 4, not over 21 is true for {} of 4",
             count(&ands), count(&ors), count(&nots));
    println!("the counting road agrees on {} of 4 rows", agree);
    println!("the three mistakes let in {}, {} and {} of 4",
             count(&ors), count(&ones), door.iter().filter(|d| d.1).count());

    assert!(ands == vec![true, false, false, false]);
    assert!(ors == vec![true, true, true, false] && nots == vec![false, true, false, true]);
    assert!(count(&ands) == 1 && count(&ors) == 3 && agree == 4);
    assert!(count(&ones) == 2 && door.iter().filter(|d| d.1).count() == 2);
    println!("ALL CHECKS PASS");
}
