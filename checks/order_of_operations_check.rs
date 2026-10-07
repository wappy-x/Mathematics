// Order of operations -- the same check as the Python above, in Rust.
// Standard library only, no crates.  Everything is counted in whole cents.
fn main() {
    let (cash, apples, price, friends) = (1000, 12, 75, 4);

    let bill = apples * price;       // the multiply happens before the subtract
    let change = cash - bill;        // what comes back over the counter
    let each = change / friends;     // the brackets close, then the divide

    let cost_each = bill / friends;  // second route: split the bill, split the note
    let note_each = cash / friends;
    let no_brackets = cash - apples * price / friends;   // the keystrokes, as typed

    for (label, value) in [("twelve apples", bill),
                           ("change from the note", change),
                           ("each friend's change", each),
                           ("each friend's cost", cost_each),
                           ("cost each plus change each", cost_each + each),
                           ("the note split four ways", note_each),
                           ("brackets dropped", no_brackets),
                           ("8 / 2 * 4 by the rungs", 8 / 2 * 4),
                           ("8 / 2 * 4 multiply first", 8 / (2 * 4)),
                           ("five friends, not four", (cash - apples * price) / 5),
                           ("apples at 80 cents", (cash - apples * 80) / friends)] {
        println!("{:<28}{:>6}", label, value);
    }

    assert!(each == 25, "twelve apples from a 1000-cent note, four ways, is 25 cents each");
    assert!(cost_each + each == note_each, "cost each plus change each is the note split four ways");
    assert!(no_brackets == 775, "without the brackets the divide grabs the apples");
    println!("ALL CHECKS PASS");
}
