// Group actions -- the same check as the Python, in Rust.  No crates.  A square tile
// sits down eight ways; a move is the pair (sign, shift) sending the corner in position
// i to position sign*i + shift, wrapped at 4.  The four corners are painted black or
// white, giving 16 patterns; road one lists the orbits, road two averages (Burnside).
use std::collections::BTreeSet;
const TURNS: i64 = 4;
fn md(x: i64) -> usize { ((x % TURNS + TURNS) % TURNS) as usize }         // wrap at 4
fn moves() -> Vec<(i64, i64)> { (0..2 * TURNS).map(|n| (1 - 2 * (n / TURNS), n % TURNS)).collect() }
fn name(a: (i64, i64)) -> String { format!("r{}{}", a.1, if a.0 == -1 { "f" } else { "" }) }
fn homes(a: (i64, i64)) -> Vec<usize> { (0..TURNS).map(|i| md(a.0 * i + a.1)).collect() }
fn combine(a: (i64, i64), b: (i64, i64)) -> (i64, i64) { (a.0 * b.0, md(a.0 * b.1 + a.1) as i64) }
fn strs(v: &[usize]) -> Vec<String> { v.iter().map(|x| x.to_string()).collect() }
fn paint(p: &[usize]) -> String { p.iter().map(|&v| "BWG".as_bytes()[v] as char).collect() }
fn push(a: (i64, i64), p: &[usize]) -> Vec<usize> {   // the action: every corner
    let mut out = vec![0usize; TURNS as usize];       // carries its colour to the
    for (i, j) in homes(a).iter().enumerate() { out[*j] = p[i]; }   // position it lands on
    out
}
fn pull(a: (i64, i64), p: &[usize]) -> Vec<usize> {   // the action read backwards: every
    let back = homes((a.0, md(-a.0 * a.1) as i64));   // position asks the undo of a
    (0..TURNS as usize).map(|j| p[back[j]]).collect() // which corner it is handed
}
fn patterns(c: usize) -> Vec<Vec<usize>> {       // every way to paint corners 0, 1, 2, 3
    (0..c * c * c * c)
        .map(|n| vec![n / (c * c * c), n / (c * c) % c, n / c % c, n % c]).collect()
}
fn fixed(a: (i64, i64), c: usize) -> usize { patterns(c).iter().filter(|p| push(a, p) == **p).count() }
fn orbits(c: usize, group: &[(i64, i64)]) -> Vec<Vec<Vec<usize>>> {   // road one
    let mut seen: BTreeSet<BTreeSet<Vec<usize>>> = BTreeSet::new();
    for p in patterns(c) { seen.insert(group.iter().map(|&a| push(a, &p)).collect()); }
    let mut v: Vec<Vec<Vec<usize>>> = seen.into_iter().map(|o| o.into_iter().collect()).collect();
    v.sort_by(|x, y| y.len().cmp(&x.len()).then(x[0].cmp(&y[0])));
    v
}
fn row(t: &str, v: &[String]) {
    println!("{:<28}{}", t, v.iter().map(|s| format!("{:>6}", s)).collect::<String>());
}
fn main() {
    let mv = moves();
    let orbs = orbits(2, &mv);
    let reps: Vec<Vec<usize>> = orbs.iter().map(|o| o[0].clone()).collect();
    let stabs: Vec<usize> = reps.iter()
        .map(|r| mv.iter().filter(|&&a| push(a, r) == *r).count()).collect();
    let alone: Vec<usize> = mv.iter().map(|&a| fixed(a, 2)).collect();   // road two
    let sizes: Vec<usize> = orbs.iter().map(|o| o.len()).collect();
    let prod: Vec<usize> = sizes.iter().zip(&stabs).map(|(n, s)| n * s).collect();
    row("move", &mv.iter().map(|&a| name(a)).collect::<Vec<String>>());
    row("positions 0 1 2 3 go to",
        &mv.iter().map(|&a| strs(&homes(a)).concat()).collect::<Vec<String>>());
    row("patterns it leaves alone", &strs(&alone));
    row("one pattern per orbit", &reps.iter().map(|r| paint(r)).collect::<Vec<String>>());
    row("patterns in that orbit", &strs(&sizes));
    row("moves leaving it put", &strs(&stabs));
    row("orbit size x stabiliser", &strs(&prod));
    let (total, tot): (usize, usize) = (sizes.iter().sum(), alone.iter().sum());
    println!("road one, by listing: the {} patterns fall into {} orbits, their sizes \
              adding to {}", patterns(2).len(), orbs.len(), total);
    println!("road two, Burnside: {} = {}, and {} / {} = {}",
             strs(&alone).join(" + "), tot, tot, mv.len(), tot / mv.len());
    let seats: BTreeSet<usize> = mv.iter().map(|&a| homes(a)[0]).collect();   // corner 0's orbit
    let keep: Vec<String> = mv.iter().filter(|&&a| homes(a)[0] == 0).map(|&a| name(a)).collect();
    println!("the same moves on the four corners: corner 0 reaches {} positions, {} \
              leave it put, {} x {} = {}", seats.len(), keep.join(" and "),
             seats.len(), keep.len(), seats.len() * keep.len());
    let (o3, f3) = (orbits(3, &mv), mv.iter().map(|&a| fixed(a, 3)).sum::<usize>());
    println!("three colours: {} patterns, Burnside {} / {} = {}, by listing {}",
             patterns(3).len(), f3, mv.len(), f3 / mv.len(), o3.len());
    let t2: usize = mv[..4].iter().map(|&a| fixed(a, 2)).sum::<usize>() / 4;   // the four
    let t3: usize = mv[..4].iter().map(|&a| fixed(a, 3)).sum::<usize>() / 4;   // turns alone
    println!("turns only, flips forgotten: two colours still gives {}, three gives {}", t2, t3);
    println!("the four mistakes come out at {}, {}, {} and {}",
             patterns(2).len() / mv.len(), (tot - alone[0]) / mv.len(), stabs[2], t3);
    assert!(mv.iter().all(|&a| patterns(2).iter().all(|p| push(a, p) == pull(a, p))));
    assert!(mv.iter().all(|&a| mv.iter().all(|&b| patterns(2).iter()
        .all(|p| push(combine(a, b), p) == push(a, &push(b, p))))));
    assert!(sizes.iter().zip(&stabs).all(|(n, s)| n * s == mv.len()) && total == 16);
    assert!(tot == 48 && tot / 8 == orbs.len() && o3.len() == f3 / 8);
    println!("ALL CHECKS PASS");
}
