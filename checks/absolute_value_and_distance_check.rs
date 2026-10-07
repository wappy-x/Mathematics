// Absolute value -- the same check as absolute_value_and_distance_check.py, in
// Rust.  No crates.  One street: the bus stop is house number 0, the bakery is
// 40, the chemist is 65, and the laundrette is -30, on the far side of the stop.
fn size(n: i64) -> i64 {              // |n|: how far n is from 0, sign dropped
    if n >= 0 { n } else { -n }
}

fn gap(x: i64, y: i64) -> i64 { size(x - y) }   // |x - y|: the distance from x to y

fn paced(x: i64, y: i64) -> i64 { (x.min(y)..x.max(y)).count() as i64 }  // counted house by house

fn row(name: &str, value: i64) { println!("{:<38}{:>5}", name, value); }

fn main() {
    let (stop, bakery, chemist, laundrette) = (0i64, 40i64, 65i64, -30i64);
    row("|40|   bus stop to the bakery", size(bakery));
    row("|65|   bus stop to the chemist", size(chemist));
    row("|-30|  bus stop to the laundrette", size(laundrette));
    row("|40 - 65|   bakery to chemist", gap(bakery, chemist));
    row("|65 - 40|   chemist to bakery", gap(chemist, bakery));
    row("|40 - (-30)|  bakery to laundrette", gap(bakery, laundrette));
    let counted = [paced(bakery, chemist), paced(chemist, bakery), paced(bakery, laundrette)];
    let mut c: Vec<String> = Vec::new();
    for v in counted { c.push(format!("{}", v)); }
    println!("the same three gaps, counted a step at a time  {}", c.join(" "));
    let mut d: Vec<String> = Vec::new();
    for n in [laundrette, stop, bakery, chemist] { d.push(format!("{}", size(n))); }
    println!("distance from the stop at -30, 0, 40, 65:   {}", d.join(" "));
    let (out, back, there) = (40i64, 25i64, -70i64);
    println!("one trip out: |40 + 25| = {} and |40| + |25| = {}", size(out + back), size(out) + size(back));
    println!("doubling back: |40 + (-70)| = {} but |40| + |-70| = {}", size(out + there), size(out) + size(there));
    println!("the three mistakes come out at {}, {} and {}", bakery - chemist, size(bakery - 30), size(out) + size(there));
    assert!(size(bakery) == 40 && size(laundrette) == 30 && size(stop) == 0);
    assert!(counted == [25, 25, 70] && gap(bakery, chemist) == 25 && gap(bakery, laundrette) == 70);
    assert!(size(out + there) == 30 && size(out) + size(there) == 110);
    println!("ALL CHECKS PASS");
}
