// Two equations, two unknowns -- the same check as the Python, in Rust.  No
// crates.  Friday: 2 adults and 3 children pay $41.  Saturday: 1 adult and 2
// children pay $24.  x is the adult price, y the child price, held in cents.
const FRI: (i64, i64, i64) = (2, 3, 4100);   // adults, children, total in cents
const SAT: (i64, i64, i64) = (1, 2, 2400);
const SUN: (i64, i64, i64) = (4, 6, 7000);   // a third receipt that cannot be right
const GUESS: (i64, i64) = (1300, 500);       // a pair that fits Friday and nothing else

fn m(cents: i64) -> String { format!("{:.2}", cents as f64 / 100.0) }
fn one(name: String, value: String) { println!("{:<58}{:>8}", name, value); }
fn row(name: &str, cents: &[i64]) {
    let mut line = format!("{:<26}", name);
    for v in cents { line.push_str(&format!("{:>7}", m(*v))); }
    println!("{}", line);
}
fn at(r: (i64, i64, i64), y: i64) -> i64 { (r.2 - r.1 * 100 * y) / r.0 }

fn main() {
    let (a, b, p) = FRI;
    let (c, d, q) = SAT;
    // road one: elimination.  Double Saturday so both receipts carry two adults.
    let dbl = (2 * c, 2 * d, 2 * q);
    let y1 = (dbl.2 - p) / (dbl.1 - b);          // the one child left over
    let x1 = (q - d * y1) / c;                   // that price back into Saturday
    // road two: substitution.  Saturday says x = (q - d*y)/c; put that into Friday.
    let y2 = (p * c - a * q) / (b * c - a * d);
    let x2 = (q - d * y2) / c;
    // road three: the crossing number, then the cross-multiplied pair
    let cross = a * d - b * c;
    let (x3, y3) = ((p * d - b * q) / cross, (a * q - c * p) / cross);
    let wy = q - p;                              // mistake: only the tickets doubled
    let wx = q - d * wy;

    one("Friday, 2 adults and 3 children".to_string(), m(p));
    one("Saturday, 1 adult and 2 children".to_string(), m(q));
    one("elimination -- Saturday doubled, 2 adults and 4 children".to_string(), m(dbl.2));
    one("minus Friday, leaving one child".to_string(), m(y1));
    one("that price back into Saturday, one adult".to_string(), m(x1));
    one(format!("substitution -- child {}, adult", m(y2)), m(x2));
    one(format!("crossing number {} -- cross-multiplied child {}, adult", cross, m(y3)), m(x3));
    one(format!("Friday checks, {} + {}", m(a * x1), m(b * y1)), m(a * x1 + b * y1));
    one(format!("Saturday checks, {} + {}", m(c * x1), m(d * y1)), m(c * x1 + d * y1));
    one("Sunday claims 4 adults and 6 children cost".to_string(), m(SUN.2));
    one(format!("Friday doubled says they cost, crossing number {}", a * SUN.1 - b * SUN.0), m(2 * p));
    one(format!("had Sunday read {}, ({}, {}) fits and so does", m(2 * p), m(x1), m(y1)),
        format!("({}, {})", m(GUESS.0), m(GUESS.1)));

    let ys: Vec<i64> = (0..11).map(|y| 100 * y).collect();
    row("child price, dollars", &ys);
    row("adults on Friday's line", &(0..11).map(|y| at(FRI, y)).collect::<Vec<i64>>());
    row("adults on Saturday's line", &(0..11).map(|y| at(SAT, y)).collect::<Vec<i64>>());
    row("adults on Sunday's line", &(0..11).map(|y| at(SUN, y)).collect::<Vec<i64>>());

    one(format!("mistake -- only the tickets doubled: child {}, adult", m(wy)), m(wx));
    one("mistake -- the rearranged adult back into Saturday".to_string(),
        format!("{} = {}", m(q), m(q)));
    one(format!("mistake -- Friday alone at {} and {}, Saturday", m(GUESS.0), m(GUESS.1)),
        m(c * GUESS.0 + d * GUESS.1));

    assert!((x1, y1) == (x2, y2) && (x2, y2) == (x3, y3));   // three roads, one pair
    assert!(a * 1000 + b * 700 == p && c * 1000 + d * 700 == q && (x1, y1) == (1000, 700));
    assert!(a * GUESS.0 + b * GUESS.1 == p && c * GUESS.0 + d * GUESS.1 == 2300);
    assert!(a * SUN.1 - b * SUN.0 == 0 && 2 * p == 8200 && SUN.2 != 8200);
    println!("ALL CHECKS PASS");
}
