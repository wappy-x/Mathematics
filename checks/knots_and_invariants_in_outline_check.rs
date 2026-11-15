// Knots and invariants in outline -- the same check as the Python, in Rust.  No
// crates.  Road 1 builds the trefoil as a closed curve in space, looks down on
// it, and reads the diagram: its crossings, their order, over or under.  Road 2
// works with that reading alone, a Gauss code, and tests every choice of over
// and under two ways for a proof that the loop is the unknot.
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::PI;

const STEPS: usize = 720; // straight pieces per loop
type P3 = (f64, f64, f64);
type Word = Vec<(usize, bool)>; // (crossing name, over?) for each visit in turn
struct Cross { c1: usize, a: f64, c2: usize, b: f64, up: bool, xy: (f64, f64) }

fn trefoil(t: f64) -> P3 { (t.sin() + 2.0 * (2.0 * t).sin(), t.cos() - 2.0 * (2.0 * t).cos(), (3.0 * t).sin()) }
fn ring_a(t: f64) -> P3 { (t.cos(), t.sin(), 0.0) } // the Hopf link: two rings,
fn ring_b(t: f64) -> P3 { (1.0 + t.cos(), 0.3 * t.sin(), t.sin()) } // hooked once

fn crossings(loops: &[fn(f64) -> P3]) -> Vec<Cross> {
    let pts: Vec<Vec<P3>> = loops.iter()
        .map(|f| (0..STEPS).map(|k| f(2.0 * PI * k as f64 / STEPS as f64)).collect()).collect();
    let segs: Vec<(usize, usize)> = (0..loops.len()).flat_map(|c| (0..STEPS).map(move |k| (c, k))).collect();
    let mut found = Vec::new();
    for (i, &(c1, k1)) in segs.iter().enumerate() {
        let (p, q) = (pts[c1][k1], pts[c1][(k1 + 1) % STEPS]);
        for &(c2, k2) in &segs[i + 1..] {
            let gap = (k2 + STEPS - k1) % STEPS;
            if c1 == c2 && (gap == 1 || gap == STEPS - 1) { continue } // neighbours
            let (r, s) = (pts[c2][k2], pts[c2][(k2 + 1) % STEPS]);
            let d = (q.0 - p.0) * (s.1 - r.1) - (q.1 - p.1) * (s.0 - r.0);
            if d == 0.0 { continue }
            let u = ((r.0 - p.0) * (s.1 - r.1) - (r.1 - p.1) * (s.0 - r.0)) / d;
            let v = ((r.0 - p.0) * (q.1 - p.1) - (r.1 - p.1) * (q.0 - p.0)) / d;
            if (0.0..1.0).contains(&u) && (0.0..1.0).contains(&v) {
                let (z1, z2) = (p.2 + u * (q.2 - p.2), r.2 + v * (s.2 - r.2));
                let xy = (p.0 + u * (q.0 - p.0), p.1 + u * (q.1 - p.1));
                found.push(Cross { c1, a: k1 as f64 + u, c2, b: k2 as f64 + v, up: z1 > z2, xy });
            }
        }
    }
    found
}

fn gauss_code(found: &[Cross]) -> (Word, Vec<usize>) { // walk from t = 0, name by first visit
    let mut visits: Vec<(f64, bool, usize)> = Vec::new();
    for (n, f) in found.iter().enumerate() { visits.push((f.a, f.up, n)); visits.push((f.b, !f.up, n)); }
    visits.sort_by(|x, y| x.0.partial_cmp(&y.0).unwrap());
    let mut names = vec![0; found.len()];
    let mut next = 1;
    for v in &visits { if names[v.2] == 0 { names[v.2] = next; next += 1 } }
    (visits.iter().map(|v| (names[v.2], v.1)).collect(), names)
}

fn show(w: &Word) -> String {
    w.iter().map(|&(c, up)| format!("{}{}", if up { "O" } else { "U" }, c)).collect::<Vec<_>>().join(" ")
}

fn descending(w: &Word) -> bool { // road A: some start and direction meets every crossing first as over
    let n = w.len();
    if n == 0 { return true }
    for start in 0..n {
        for back in [false, true] {
            let (mut seen, mut ok) = (BTreeSet::new(), true);
            for j in 0..n {
                let (c, up) = w[if back { (start + n * n - j) % n } else { (start + j) % n }];
                if seen.insert(c) { ok = ok && up }
            }
            if ok { return true }
        }
    }
    false
}

fn untwists(w: &Word) -> bool { // road B: delete kinks until none is left
    let mut w = w.clone();
    while !w.is_empty() {
        let n = w.len();
        match (0..n).find(|&i| w[i].0 == w[(i + 1) % n].0) {
            None => return false,
            Some(i) => { let j = (i + 1) % n; w = w.iter().enumerate().filter(|(k, _)| *k != i && *k != j).map(|(_, x)| *x).collect() }
        }
    }
    true
}

fn gaps(w: &[usize]) -> Vec<usize> { // letters between a crossing's two visits
    let mut pos: BTreeMap<usize, Vec<usize>> = BTreeMap::new();
    for (i, &c) in w.iter().enumerate() { pos.entry(c).or_default().push(i) }
    pos.values().map(|p| p[1] - p[0] - 1).collect()
}

fn choose(shadow: &[usize], pick: usize) -> Word { // bit c-1 of pick set: first visit to c is over
    let mut seen = BTreeSet::new();
    shadow.iter().map(|&c| (c, ((pick >> (c - 1)) & 1 == 1) == seen.insert(c))).collect()
}

fn alternating(w: &Word) -> bool { (0..w.len()).all(|i| w[i].1 != w[(i + 1) % w.len()].1) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn shadow_of(w: &Word) -> Vec<usize> { w.iter().map(|x| x.0).collect() }

fn words(n: usize, prefix: &mut Vec<usize>, used: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if prefix.len() == 2 * n { out.push(prefix.clone()); return }
    for c in 1..=n {
        if used[c] < 2 { used[c] += 1; prefix.push(c); words(n, prefix, used, out); prefix.pop(); used[c] -= 1 }
    }
}

fn main() {
    let tre = crossings(&[trefoil]);
    let (code, names) = gauss_code(&tre);
    let hopf = crossings(&[ring_a, ring_b]);
    let between = hopf.iter().filter(|f| f.c1 != f.c2).count();
    println!("Road 1: the trefoil as a curve in space, seen from above");
    println!("crossings in the drawing: {}", tre.len());
    println!("walk from t = 0: {}", show(&code));
    println!("over and under alternate: {}", yn(alternating(&code)));
    let mut spots: Vec<(usize, (f64, f64))> = tre.iter().enumerate().map(|(n, f)| (names[n], f.xy)).collect();
    spots.sort_by_key(|s| s.0);
    let spot_text: Vec<String> = spots.iter().map(|(c, (x, y))| format!("crossing {} at ({:.3}, {:.3})", c, x, y)).collect();
    println!("figure, {}", spot_text.join(", "));
    println!("Hopf link: 2 loops, crossings between them {}, of a loop with itself {}", between, hopf.len() - between);
    println!("Road 2: the Gauss code alone");
    println!("letters between the two visits to crossings 1, 2, 3: {:?}", gaps(&shadow_of(&code)));
    println!("the trefoil as drawn: descending {}, untwists {}", yn(descending(&code)), yn(untwists(&code)));
    let diagrams: Vec<Word> = (0..8).rev().map(|p| choose(&shadow_of(&code), p)).collect();
    let down = diagrams.iter().filter(|d| descending(d)).count();
    let stuck: Vec<&Word> = diagrams.iter().filter(|d| !descending(d)).collect();
    let runs: BTreeSet<BTreeSet<usize>> = (0..6).map(|s| (0..3).map(|j| (s + j) % 6).collect()).collect();
    let in_a_row = diagrams.iter()
        .filter(|d| runs.contains(&d.iter().enumerate().filter(|x| x.1 .1).map(|x| x.0).collect())).count();
    println!("the 8 over/under choices on the trefoil's shadow: {} descending, {} not", down, stuck.len());
    println!("over at three passages in a row, counted directly: {}", in_a_row);
    println!("the two that are not: {} and {}; both alternate: {}", show(stuck[0]), show(stuck[1]),
             yn(stuck.iter().all(|d| alternating(d))));
    let flips: Vec<bool> = (1..=3).map(|x| descending(&code.iter().map(|&(c, up)| (c, up != (c == x))).collect())).collect();
    println!("change crossing 1, 2 or 3 alone, then descending: {}", flips.iter().map(|&f| yn(f)).collect::<Vec<_>>().join(", "));
    println!("every Gauss word, every over/under choice, for n = 1 to 3 crossings:");
    let mut census = Vec::new();
    for n in 1..=3usize {
        let mut all = Vec::new();
        words(n, &mut Vec::new(), &mut vec![0; n + 1], &mut all);
        let even: Vec<&Vec<usize>> = all.iter().filter(|w| gaps(w).iter().all(|g| g % 2 == 0)).collect();
        let ds: Vec<Word> = even.iter().flat_map(|w| (0..1usize << n).rev().map(move |p| choose(w, p))).collect();
        let dn = ds.iter().filter(|d| descending(d)).count();
        let kn = ds.iter().filter(|d| untwists(d)).count();
        let left: Vec<Word> = ds.iter().filter(|d| !descending(d) && !untwists(d)).cloned().collect();
        println!("n = {}: {} words, {} pass the even test, {} diagrams; descending {}, untwist by kinks {}, either {}",
                 n, all.len(), even.len(), ds.len(), dn, kn, ds.len() - left.len());
        census.push((ds.len(), dn, kn, left));
    }
    let left = &census[2].3;
    let abc = left.iter().all(|d| d[0].0 == d[3].0 && d[1].0 == d[4].0 && d[2].0 == d[5].0);
    println!("neither at 3 crossings: {}, all of shape abcabc: {}, all alternating: {}",
             left.len(), yn(abc), yn(left.iter().all(alternating)));
    let mut kinked = code.clone();
    kinked.extend([(4, true), (4, false)]);
    let mut granny = code.clone();
    granny.extend(code.iter().map(|&(c, up)| (c + 3, up)));
    println!("kinked trefoil {}: {} crossings, descending {}", show(&kinked), kinked.len() / 2, yn(descending(&kinked)));
    println!("granny knot, two trefoils joined: {} crossings, descending {}", granny.len() / 2, yn(descending(&granny)));
    println!("mistake 1, crossings in one drawing: unknot round {}, with one kink {}", crossings(&[ring_a]).len(), gaps(&[1, 1]).len());
    println!("mistake 2, loops counted: unknot 1, trefoil {}, Hopf link {}", [trefoil].len(), [ring_a, ring_b].len());
    println!("mistake 3, the shadow without over/under: {} of {} choices are the unknot", down, diagrams.len());
    assert!(tre.len() == 3 && show(&code) == "O1 U2 O3 U1 O2 U3"); // road 1 matches the hand reading
    assert!(alternating(&code) && !descending(&code) && gaps(&shadow_of(&code)) == vec![2, 2, 2]);
    assert!(down == 6 && in_a_row == 6); // descending = over three in a row
    assert!(flips.iter().all(|&f| f) && between == 2 && hopf.len() == 2);
    assert!(census[..2].iter().all(|c| c.0 == c.1 && c.1 == c.2)); // roads A and B agree
    assert!(left.len() == 12 && abc && left.iter().all(alternating));
    println!("ALL CHECKS PASS");
}
