// Fermat's little theorem -- the same check as the Python one, in Rust.  No crates.
// A 13-position lock dial, base 2: twelve doublings land on 1, the twelve doubled
// positions are the twelve positions shuffled, and 2 to the 1000 collapses to 3.
const DIAL: i64 = 13;
const BASE: i64 = 2;

fn turn(base: i64, times: i64, dial: i64) -> i64 {   // the reading after that many multiplications
    let mut out = 1;
    for _ in 0..times { out = (out * base) % dial; }
    out
}

fn row(name: &str, value: i64) { println!("{:<44}{:>14}", name, value); }

fn main() {
    let whole = BASE.pow(DIAL as u32 - 1);           // 4096, written out in full
    let left = 1000 % (DIAL - 1);                    // 1000 split by 12
    let doubles: Vec<i64> = (1..DIAL).map(|k| (BASE * k) % DIAL).collect();
    let (mut plain, mut shuffled) = (1i64, 1i64);    // 1 x 2 x ... x 12, and each doubled
    for k in 1..DIAL { plain *= k; shuffled *= BASE * k; }
    let marks: Vec<String> = doubles.iter().map(|d| d.to_string()).collect();
    row("2 doubled twelve times", whole);
    row(&format!("{} = {} x {} + 1, so the dial shows", whole, whole / DIAL, DIAL), whole % DIAL);
    row(&format!("2 to the {} = {}, so the dial shows", DIAL, BASE.pow(DIAL as u32)), turn(BASE, DIAL, DIAL));
    println!("1 to 12, each doubled: {}", marks.join(" "));
    row("1 to 12 multiplied", plain);
    row("the twelve doubles multiplied", shuffled);
    row("both of those, on the 13-dial", plain % DIAL);
    row(&format!("1000 = {} x {} + {}, leftover exponent", 1000 / (DIAL - 1), DIAL - 1, left), left);
    row(&format!("2 to the {} = {}, so the dial shows", left, BASE.pow(left as u32)), turn(BASE, left, DIAL));
    row("2 to the 1000 the long way, on the 13-dial", turn(BASE, 1000, DIAL));
    println!("gone wrong: cut by 13 -> {}, base 26 -> {}, 14 on a 15-dial ({}) -> {}",
             turn(BASE, 1000 % DIAL, DIAL), turn(2 * DIAL, DIAL - 1, DIAL), BASE.pow(14), turn(BASE, 14, 15));
    let mut sorted = doubles.clone(); sorted.sort();
    assert!(whole == 4096 && whole == 315 * DIAL + 1 && turn(BASE, DIAL - 1, DIAL) == 1);
    assert!(sorted == (1..DIAL).collect::<Vec<i64>>() && shuffled % DIAL == 12 && plain % DIAL == 12);
    assert!(turn(BASE, 1000, DIAL) == 16 % DIAL && turn(BASE, left, DIAL) == 3);
    println!("ALL CHECKS PASS");
}
