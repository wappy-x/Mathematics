// Inclusion-exclusion -- the same check as inclusion_exclusion_check.py, in Rust.
// No crates.  A class of 30 students, by number: who plays football, who plays
// chess, who sings in the choir.  The formula the plain way, then the roster.
use std::collections::HashSet;
fn roster(parts: &[(i32, i32)]) -> HashSet<i32> { parts.iter().flat_map(|(a, b)| *a..*b).collect() }
fn only(a: &HashSet<i32>, b: &HashSet<i32>, d: &HashSet<i32>) -> usize { a.difference(b).filter(|x| !d.contains(x)).count() }
fn row(name: &str, values: &[usize]) {
    let mut line = format!("{:<34}", name);
    for v in values { line.push_str(&format!("{:>5}", v)); }
    println!("{}", line);
}
fn main() {
    let class: HashSet<i32> = (0..30).collect();       // the whole class, by number
    let f = roster(&[(0, 9), (18, 25), (26, 28)]);     // 18 play football
    let c = roster(&[(9, 13), (18, 23), (25, 28)]);    // 12 play chess
    let h = roster(&[(13, 18), (23, 28)]);             // 10 sing in the choir
    let (foot, chess, choir) = (f.len(), c.len(), h.len());
    let fc_set: HashSet<i32> = f.intersection(&c).cloned().collect();
    let (fc, fh, ch, all3) = (fc_set.len(), f.intersection(&h).count(), c.intersection(&h).count(), fc_set.intersection(&h).count());
    let two = foot + chess - fc;                              // the overlap comes off once
    let three = foot + chess + choir - fc - fh - ch + all3;   // pairs off, triple back on
    let slices = [only(&f, &c, &h), only(&c, &f, &h), only(&h, &f, &c), fc - all3, fh - all3, ch - all3, all3];
    let either: HashSet<i32> = f.union(&c).cloned().collect();
    let union3: HashSet<i32> = either.union(&h).cloned().collect();
    row("football, chess, choir", &[foot, chess, choir]);
    row("both: F&C, F&H, C&H", &[fc, fh, ch]);
    row("all three", &[all3]);
    row("at least one of the two, formula", &[two]);
    row("at least one of the two, roster", &[either.len()]);      // the second road
    row("neither of the two", &[class.len() - two]);
    row("at least one of three, formula", &[three]);
    row("at least one of three, roster", &[union3.len()]);
    row("none of the three", &[class.len() - three]);
    row("the seven slices of a class of 30", &slices);
    println!("the three mistakes come out at {}, {} and {}", foot + chess, three - all3, three - 2 * all3);
    assert!(class.len() == 30 && two == either.len() && two == 23 && class.len() - two == 7 && class.difference(&either).count() == 7);
    assert!(three == union3.len() && three == 28 && class.len() - three == 2 && class.difference(&union3).count() == 2);
    assert!(slices.iter().sum::<usize>() == three && (foot, chess, choir, fc, fh, ch, all3) == (18, 12, 10, 7, 4, 3, 2));
    println!("ALL CHECKS PASS");
}
