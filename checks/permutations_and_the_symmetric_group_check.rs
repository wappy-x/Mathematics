// Permutations -- the same check as the Python, in Rust.  No crates.  A shuffle of n
// places is a list of destinations: entry i says where the card lying in place i goes.
// Composition does the right-hand shuffle first, so rt means t and then r.  Each answer
// is reached by two roads: the count by listing every shuffle and by multiplying n down
// to 1, the even-or-odd label by out-of-order pairs and by places minus cycles, the
// square's symmetries by the turn-and-flip rule and by keeping corner neighbours.
use std::collections::HashSet;
fn all_shuffles(n: usize) -> Vec<Vec<usize>> {     // road one: pick unused places
    fn grow(n: usize, used: Vec<usize>, out: &mut Vec<Vec<usize>>) {
        if used.len() == n { out.push(used); return; }
        for d in 1..=n {
            if !used.contains(&d) { let mut next = used.clone(); next.push(d); grow(n, next, out); }
        }
    }
    let (mut out, start) = (vec![], vec![]);
    grow(n, start, &mut out);
    out
}
fn multiply_down(n: usize) -> usize {              // road two: n x (n - 1) x ... x 1
    let mut total = 1;
    for k in 2..=n { total = total * k; }
    total
}
fn compose(a: &[usize], b: &[usize]) -> Vec<usize> { b.iter().map(|&j| a[j - 1]).collect() }
fn undo(a: &[usize]) -> Vec<usize> {               // the shuffle that puts cards back
    (1..=a.len()).map(|i| a.iter().position(|&j| j == i).unwrap() + 1).collect() }
fn cycles(a: &[usize]) -> Vec<Vec<usize>> {        // follow each place until it returns
    let (mut seen, mut out) = (vec![false; a.len() + 1], vec![]);
    for start in 1..=a.len() {
        if seen[start] { continue; }
        let (mut cyc, mut j) = (vec![], start);
        while !seen[j] { cyc.push(j); seen[j] = true; j = a[j - 1]; }
        out.push(cyc);
    }
    out
}
fn row(a: &[usize]) -> String {
    a.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ")
}
fn name(a: &[usize]) -> String {                   // cycle notation, single places out
    let text: String = cycles(a).iter().filter(|c| c.len() > 1)
        .map(|c| format!("({})", row(c))).collect::<Vec<_>>().join("");
    if text.is_empty() { "e".to_string() } else { text }
}
fn out_of_order(a: &[usize]) -> usize {            // pairs standing in the wrong order
    (0..a.len()).map(|i| (i + 1..a.len()).filter(|&j| a[i] > a[j]).count()).sum()
}
fn swaps(a: &[usize]) -> usize { a.len() - cycles(a).len() }    // places minus cycles
fn parity(a: &[usize]) -> &'static str { if swaps(a) % 2 == 1 { "odd" } else { "even" } }
fn main() {
    let (s3, s4) = (all_shuffles(3), all_shuffles(4));
    let (e, r, t, four) = (vec![1, 2, 3], vec![2, 3, 1], vec![2, 1, 3], vec![2, 3, 4, 1]);
    println!("the six shuffles of three cards: destinations, cycle name, even or odd");
    for p in &s3 { println!("  {}  {:<9}{}", row(p), name(p), parity(p)); }
    println!("swap then shift, rt: destinations {} = {}", row(&compose(&r, &t)), name(&compose(&r, &t)));
    println!("shift then swap, tr: destinations {} = {}", row(&compose(&t, &r)), name(&compose(&t, &r)));
    println!("the undo of r: destinations {} = {}", row(&undo(&r)), name(&undo(&r)));
    println!("r as swaps: 3 places minus {} cycle = {} swaps, {}", cycles(&r).len(), swaps(&r), parity(&r));
    println!("out-of-order pairs in {}: {}, so {}", row(&r), out_of_order(&r), parity(&r));
    let counts: Vec<usize> = (1..=5).map(|k| all_shuffles(k).len()).collect();
    println!("shuffles of 1, 2, 3, 4, 5 places: {}",
             counts.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "));
    println!("S_3 splits: even {}, odd {}", s3.iter().filter(|p| swaps(p) % 2 == 0).count(),
             s3.iter().filter(|p| swaps(p) % 2 == 1).count());
    println!("the four-cycle {}: {} swaps, {}", name(&four), swaps(&four), parity(&four));
    let mut tile: HashSet<Vec<usize>> = HashSet::new();
    for s in [1_i32, -1] { for k in 0..4 {
        tile.insert((0..4).map(|i| ((s * i + k).rem_euclid(4) + 1) as usize).collect());
    } }
    let rigid: HashSet<Vec<usize>> = s4.iter()
        .filter(|p| (0..4).all(|i| [1, 3].contains(&((p[(i + 1) % 4] + 4 - p[i]) % 4)))).cloned().collect();
    println!("corner shuffles of the square: {}; rigid symmetries among them: {}", s4.len(), tile.len());
    let distinct: HashSet<usize> = [2, 2, 1].into_iter().collect();
    println!("the list 2 2 1 is a shuffle: {}", if distinct.len() == 3 { "yes" } else { "no" });
    assert!(counts == (1..=5).map(multiply_down).collect::<Vec<usize>>());
    assert!(s4.iter().all(|p| out_of_order(p) % 2 == swaps(p) % 2));
    assert!(compose(&r, &t) == vec![3, 2, 1] && compose(&t, &r) == vec![1, 3, 2] && undo(&r) == vec![3, 1, 2]);
    assert!(s3.iter().all(|p| compose(p, &undo(p)) == e && s3.iter().all(|q| s3.contains(&compose(p, q)))) && tile == rigid);
    println!("ALL CHECKS PASS");
}
