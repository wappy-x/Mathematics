// Graphs -- the same check as the Python, in Rust.  No crates.  Map 1 is the metro
// ring: stations A to F, lines A-B B-C C-D D-E E-F F-A and the crossings B-E and
// C-F.  Map 2 is the tourist map, stations 1 to 6.  Map 3 is a decoy carrying the
// same station count, line count and station-by-station tally as map 1.
const NAMES: [char; 6] = ['A', 'B', 'C', 'D', 'E', 'F'];
const RING: [(usize, usize); 8] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
const TOURIST: [(usize, usize); 8] = [(0, 2), (0, 4), (0, 5), (1, 4), (1, 5), (2, 3), (3, 4), (3, 5)];
const DECOY: [(usize, usize); 8] = [(0, 1), (0, 2), (1, 2), (1, 4), (2, 5), (3, 4), (3, 5), (4, 5)];
fn lines(pairs: &[(usize, usize)]) -> Vec<(usize, usize)> {   // each line once, low end first
    let mut out: Vec<(usize, usize)> = pairs.iter().map(|&(a, b)| if a < b { (a, b) } else { (b, a) }).collect();
    out.sort(); out.dedup(); out
}
fn perms(items: &[usize]) -> Vec<Vec<usize>> {                // every renaming, generated here
    if items.is_empty() { return vec![Vec::new()] }
    let mut out: Vec<Vec<usize>> = Vec::new();
    for (i, &x) in items.iter().enumerate() {
        let mut rest = items.to_vec(); rest.remove(i);
        for mut p in perms(&rest) { p.insert(0, x); out.push(p) }
    }
    out
}
fn fingerprint(pairs: &[(usize, usize)], n: usize) -> (usize, Vec<usize>, usize) {
    let e = lines(pairs);                        // road two: counts no renaming can change
    let mut tally: Vec<usize> = (0..n).map(|v| e.iter().filter(|&&(a, b)| a == v || b == v).count()).collect();
    tally.sort();
    let mut tri = 0;
    for a in 0..n { for b in a + 1..n { for c in b + 1..n {
        if e.contains(&(a, b)) && e.contains(&(a, c)) && e.contains(&(b, c)) { tri += 1 }
    }}}
    (e.len(), tally, tri)
}
fn renamings(src: &[(usize, usize)], dst: &[(usize, usize)], n: usize) -> usize {
    let (target, e) = (lines(dst), lines(src));  // road one: try all n! renamings
    perms(&(0..n).collect::<Vec<usize>>()).iter()
        .filter(|p| lines(&e.iter().map(|&(a, b)| (p[a], p[b])).collect::<Vec<_>>()) == target)
        .count()
}
fn main() {
    let pairs6: Vec<(usize, usize)> = (0..6).flat_map(|a| (a + 1..6).map(move |b| (a, b))).collect();
    let k33 = lines(&[0usize, 2, 4].iter()                    // A C E against B D F
        .flat_map(|&a| [1usize, 3, 5].iter().map(move |&b| (a, b))).collect::<Vec<_>>());
    let cube: Vec<(usize, usize)> = (0..8usize).flat_map(|u| (u + 1..8).map(move |v| (u, v)))
        .filter(|&(u, v)| (u ^ v).count_ones() == 1).collect();
    let per_dir: Vec<usize> = (0..3).map(|b| cube.iter().filter(|&&(u, v)| u ^ v == 1 << b).count()).collect();
    let (ring, inner) = (lines(&RING), [1usize, 2, 4, 5]);
    let cycle6 = lines(&(0..6).map(|i| (i, (i + 1) % 6)).collect::<Vec<_>>());
    let path6 = lines(&(0..5).map(|i| (i, i + 1)).collect::<Vec<_>>());
    let ring_only: Vec<(usize, usize)> = ring.iter().copied().filter(|&e| e != (1, 4) && e != (2, 5)).collect();
    let induced: Vec<(usize, usize)> = ring.iter().copied().filter(|&(a, b)| inner.contains(&a) && inner.contains(&b)).collect();
    let gap = *k33.iter().find(|e| !ring.contains(e)).unwrap();
    let orders = perms(&(0..6).collect::<Vec<usize>>()).len();
    let (f1, f2, f3) = (fingerprint(&RING, 6), fingerprint(&TOURIST, 6), fingerprint(&DECOY, 6));
    println!("map 1, the ring: 6 stations, {} lines; the adjacency list", ring.len());
    for v in 0..6 {
        let nb: Vec<String> = ring.iter().filter(|&&(a, b)| a == v || b == v)
            .map(|&(a, b)| NAMES[if a == v { b } else { a }].to_string()).collect();
        println!("  {}: {}", NAMES[v], nb.join(" "));
    }
    println!("all pairs of 6 stations, listed: {}; by formula 6 x 5 / 2 = {}; map 1 runs {}, so {} pairs have no line",
             pairs6.len(), 6 * 5 / 2, ring.len(), pairs6.len() - ring.len());
    println!("named families on 6 stations: K(6) {} lines, C(6) {}, P(6) {}, K(3,3) {}",
             pairs6.len(), cycle6.len(), path6.len(), k33.len());
    println!("map 1 is K(3,3) less one line: {} - 1 = {}; the missing pair is {}-{}",
             k33.len(), ring.len(), NAMES[gap.0], NAMES[gap.1]);
    println!("the 3-cube Q(3): 8 corners, {} lines by flipping one coordinate; by formula 8 x 3 / 2 = {}; {:?} in the three directions", cube.len(), 8 * 3 / 2, per_dir);
    println!("drop the crossings B-E and C-F: {} lines left, the ring C(6)", ring_only.len());
    println!("keep B C E F and every line between them: {} lines, the 4-cycle B-C-F-E-B", induced.len());
    println!("map 2 onto map 1: {} of the {} renamings work", renamings(&TOURIST, &RING, 6), orders);
    println!("map 3 onto map 1: {} of the {} renamings work", renamings(&DECOY, &RING, 6), orders);
    println!("lines and tally: map 1 {} {:?}, map 2 {} {:?}, map 3 {} {:?}",
             f1.0, f1.1, f2.0, f2.1, f3.0, f3.1);
    println!("triangles: map 1 {}, map 2 {}, map 3 {}", f1.2, f2.2, f3.2);
    assert!(pairs6.len() == 6 * 5 / 2 && cube.len() == 8 * 3 / 2 && per_dir == vec![4, 4, 4]);
    assert!(ring == k33.iter().copied().filter(|&e| e != (0, 3)).collect::<Vec<_>>() && ring_only == cycle6);
    assert!(induced == vec![(1, 2), (1, 4), (2, 5), (4, 5)] && renamings(&TOURIST, &RING, 6) == 8);
    assert!(f2 == f1 && f3 != f1 && renamings(&DECOY, &RING, 6) == 0);
    println!("ALL CHECKS PASS");
}
