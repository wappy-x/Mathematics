// Peano's three rules -- the same check as peano_and_one_plus_one_check.py, in
// Rust.  No crates.  A number is a rope: Zero is the rope before any knot, and
// Knot(r) is one more knot tied after r.  Addition is the two rules alone.
#[derive(Clone, PartialEq)]
enum Rope { Zero, Knot(Box<Rope>) }
fn nxt(r: Rope) -> Rope { Rope::Knot(Box::new(r)) }        // the next knot after the rope r
fn knots(r: &Rope) -> i64 { match r { Rope::Zero => 0, Rope::Knot(i) => knots(i) + 1 } }
fn add(m: Rope, n: &Rope) -> Rope {                        // m + 0 = m;  m + next(n) = next(m + n)
    match n { Rope::Zero => m, Rope::Knot(i) => nxt(add(m, i)) }
}
fn dropped_next(m: Rope, n: &Rope) -> Rope {               // a mistake: rule two without the next
    match n { Rope::Zero => m, Rope::Knot(i) => dropped_next(m, i) }
}
// second road: tie one knot at a time.  Then the same walk on a rope that breaks a rule.
fn tie(mut m: Rope, times: i64) -> Rope { for _ in 0..times { m = nxt(m); } m }
fn walk(mut k: i64, times: i64, nextf: fn(i64) -> i64) -> i64 { for _ in 0..times { k = nextf(k); } k }
fn row(name: &str, value: i64) { println!("{:<40}{:>4}", name, value); }
fn main() {
    let (zero, one) = (Rope::Zero, nxt(Rope::Zero));
    let two = nxt(one.clone());
    let three = nxt(two.clone());
    row("zero, the rope before any knot", knots(&zero));
    row("one, the knot after zero", knots(&one));
    row("two, the knot after one", knots(&two));
    row("1 + 1 by the two rules", knots(&add(one.clone(), &one)));
    row("2 + 3 by the two rules", knots(&add(two.clone(), &three)));
    row("2 + 3 by tying one knot at a time", knots(&tie(two.clone(), knots(&three))));
    println!("1 + 1 lands on two, knot for knot: {}",
             if add(one.clone(), &one) == two { "True" } else { "False" });
    println!("the three mistakes come out at {}, {} and {}", walk(2, 3, |k| (k + 1) % 4),
             walk(2, 3, |k| (k + 1).min(3)), knots(&dropped_next(two.clone(), &three)));
    assert!(knots(&add(one.clone(), &one)) == 2 && add(one.clone(), &one) == two);
    assert!(knots(&add(two.clone(), &three)) == 5
            && add(two.clone(), &three) == tie(two.clone(), knots(&three)));
    assert!(knots(&zero) == 0 && knots(&one) == 1 && knots(&nxt(three)) == 4);
    println!("ALL CHECKS PASS");
}
