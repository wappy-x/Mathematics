// Hamiltonian cycles -- the same check as hamiltonian_cycles_check.py, in Rust.  No crates.  Three
// networks: the 8 corners of a cube-shaped warehouse, that cube plus four gangways across the middle,
// and the Petersen network of 10 depots.  Every round is counted twice, by backtracking over routes
// and by a tally over sets of corners that builds no route at all.
fn deg(x: u64) -> u32 { x.count_ones() }             // a degree: the 1 bits of a neighbour set
fn low(w: u64) -> usize { w.trailing_zeros() as usize }   // the lowest corner in a bit set
fn fact(k: u64) -> u64 { if k < 2 { 1 } else { k * fact(k - 1) } }   // k! = 1 x 2 x ... x k
fn dash(r: &[usize]) -> String { r.iter().map(|v| v.to_string()).collect::<Vec<_>>().join("-") }
fn masks(n: usize, edges: &[(usize, usize)]) -> Vec<u64> {           // neighbours, as bits
    (0..n).map(|i| edges.iter().filter(|e| e.0 == i || e.1 == i).map(|e| 1u64 << if e.0 == i { e.1 } else { e.0 }).sum()).collect()
}
fn walk(m: &[u64], path: &mut Vec<usize>, left: u64, close: bool, out: &mut Vec<Vec<usize>>, opened: &mut u64) {
    *opened += 1; let end = path[path.len() - 1];   // one more partial route opened
    if left == 0 && (!close || (m[end] >> path[0] & 1 == 1 && path[1] < end)) {
        let mut r = path.clone(); if close { r.push(path[0]) } out.push(r);
    }
    let mut w = m[end] & left;
    while w != 0 {
        let b = w & w.wrapping_neg(); w -= b;
        path.push(low(b));
        walk(m, path, left - b, close, out, opened);
        path.pop();
    }
}
fn search(m: &[u64], close: bool) -> (Vec<Vec<usize>>, u64) {        // road one: backtracking
    let (mut out, mut opened) = (Vec::new(), 0u64);
    walk(m, &mut vec![0], (1u64 << m.len()) - 2, close, &mut out, &mut opened);
    (out, opened)
}
fn subsets(m: &[u64]) -> u64 {                      // road two: a tally over sets of corners
    let (n, full) = (m.len(), (1usize << m.len()) - 1);
    let mut cnt = vec![vec![0u64; n]; full + 1];
    cnt[1][0] = 1;                                  // one route: at 0, no step yet
    for s in (1..=full).step_by(2) {                // every set of corners that holds corner 0
        for v in 0..n {
            let (c, mut w) = (cnt[s][v], m[v] & !(s as u64));
            while c > 0 && w != 0 {
                let b = w & w.wrapping_neg(); w -= b;
                cnt[s | b as usize][low(b)] += c;   // the same routes, one corner longer
            }
        }
    }
    (0..n).filter(|&v| m[0] >> v & 1 == 1).map(|v| cnt[full][v]).sum::<u64>() / 2
}
fn main() {
    let cube: Vec<(usize, usize)> = (0..8).flat_map(|x| (x + 1..8).map(move |y| (x, y))).filter(|&(x, y)| deg((x ^ y) as u64) == 1).collect();
    let mut gang = cube.clone(); for x in 0..4 { gang.push((x, 7 - x)) }   // to opposite corners
    let pet: Vec<(usize, usize)> = (0..5).flat_map(|i| [(i, (i + 1) % 5), (i, i + 5), (i + 5, (i + 2) % 5 + 5)]).collect();
    let nets = [("cube warehouse", 8usize, &cube), ("cube + gangways", 8, &gang), ("Petersen depots", 10, &pet)];
    println!("{:<17}{:>3}{:>7}{:>9}{:>9}{:>5}{:>7}{:>10}{:>8}{:>9}", "network", "n", "links",
             "min deg", "odd deg", "n/2", "Dirac", "(n-1)!/2", "search", "subsets");
    let (mut mm, mut found, mut tally, mut opened) = (vec![], vec![], vec![], vec![]);
    for (name, n, edges) in nets {
        let m = masks(n, edges); let (rounds, op) = search(&m, true);
        let (t, d) = (subsets(&m), m.iter().map(|&x| deg(x)).min().unwrap());
        let (e, o) = (m.iter().map(|&x| deg(x)).sum::<u32>() / 2, m.iter().filter(|&&x| deg(x) % 2 == 1).count());
        println!("{:<17}{:>3}{:>7}{:>9}{:>9}{:>5}{:>7}{:>10}{:>8}{:>9}", name, n, e, d, o,
                 format!("{:.1}", n as f64 / 2.0), if d as f64 >= n as f64 / 2.0 { "yes" } else { "no" },
                 fact(n as u64 - 1) / 2, rounds.len(), t);
        mm.push(m); found.push(rounds.len() as u64); tally.push(t); opened.push(op);
    }
    println!("one round on the cube: {}", dash(&search(&mm[0], true).0[0]));
    println!("partial routes opened by the search: cube {}, Petersen {}", opened[0], opened[2]);
    println!("rounds on cube + gangways, from the K(4,4) count 4! x 3! / 2: {}", fact(4) * fact(3) / 2);
    println!("route over all 10 depots that will not close: {}", dash(&search(&mm[2], false).0[0]));
    let pairs: Vec<(usize, usize)> = (0..6).flat_map(|i| (i + 1..6).map(move |j| (i, j))).collect();
    let (mut dirac, mut ham, mut both) = (0u64, 0u64, 0u64);
    for bits in 0..1u32 << 15 {                     // every network on 6 labelled corners
        let m = masks(6, &(0..15).filter(|i| bits >> i & 1 == 1).map(|i| pairs[i]).collect::<Vec<_>>());
        let (d, h) = (m.iter().map(|&x| deg(x)).min().unwrap() >= 3, !search(&m, true).0.is_empty());
        dirac += d as u64; ham += h as u64; both += (d && h) as u64;
    }
    println!("of all {} networks on 6 corners, {} meet Dirac and all {} of those have a round", 1 << 15, dirac, both);
    println!("of the same {}, {} have a round, so {} have one with Dirac silent", 1 << 15, ham, ham - both);
    assert!(found == tally);                        // the two roads agree
    assert!(found[1] == fact(4) * fact(3) / 2 && found[1] == 72);      // search vs K(4,4) count
    assert!(found[0] == 6 && found[2] == 0);
    assert!(dirac == both && both < ham);           // Dirac is never wrong, and never necessary
    println!("ALL CHECKS PASS");
}
