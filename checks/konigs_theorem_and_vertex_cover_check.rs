// Konig's theorem -- the same check as the Python, in Rust.  No crates.  The town plan: eight
// junctions, four on the west bank (W1-W4) and four on the east (E1-E4), joined by eight
// streets, each one a bridge.  A triangle of streets is the second case, where equality fails.
const NAMES: [&str; 8] = ["W1", "W2", "W3", "W4", "E1", "E2", "E3", "E4"];
const WESTM: u32 = 0b1111; const EASTM: u32 = 0b11110000;    // banks, one bit per junction
const ST: [(usize, usize); 8] = [(0, 4), (0, 5), (1, 4), (1, 5), (2, 5), (3, 5), (3, 6), (3, 7)];
const TRI: [(usize, usize); 3] = [(0, 1), (1, 2), (0, 2)];   // three junctions in a ring
fn show(m: u32) -> String { (0..8).filter(|i| m >> i & 1 == 1).map(|i| NAMES[i]).collect::<Vec<&str>>().join(", ") }
fn brute(n: usize, st: &[(usize, usize)]) -> (u32, u32, u32, u32, Vec<u32>) {
    let (mut nu, mut tau, mut alpha, mut rho) = (0u32, n as u32, 0u32, st.len() as u32 + 1);
    let mut mins: Vec<u32> = Vec::new();
    for m in 0..1u32 << n {                        // ROAD ONE, part one: every set of junctions
        let (k, cov) = (m.count_ones(), st.iter().all(|&(u, v)| m >> u & 1 == 1 || m >> v & 1 == 1));
        if cov && k < tau { tau = k; mins.clear() } if cov && k == tau { mins.push(m) }
        if st.iter().all(|&(u, v)| m >> u & 1 == 0 || m >> v & 1 == 0) && k > alpha { alpha = k }
    }
    for p in 0..1u32 << st.len() {                 // ROAD ONE, part two: every set of streets
        let (k, mut touch) = (p.count_ones(), 0u32);
        for (i, &(u, v)) in st.iter().enumerate() { if p >> i & 1 == 1 { touch |= 1 << u | 1 << v } }
        if touch.count_ones() == 2 * k && k > nu { nu = k } if touch.count_ones() == n as u32 && k < rho { rho = k }
    }
    (nu, tau, alpha, rho, mins)
}
fn grow(a: usize, mate: &mut [i32; 8], seen: &mut Vec<usize>, nbr: &[Vec<usize>]) -> bool {
    for &b in &nbr[a] {                            // one alternating walk out of a west junction
        if seen.contains(&b) { continue }
        seen.push(b);
        let w = mate[b];
        if w < 0 || grow(w as usize, mate, seen, nbr) { mate[b] = a as i32; return true }
    }
    false
}
fn built(st: &[(usize, usize)]) -> (Vec<(usize, usize)>, u32) {   // ROAD TWO: a matching, then guards
    let nbr: Vec<Vec<usize>> = (0..4).map(|a| st.iter().filter(|&&(u, _)| u == a).map(|&(_, b)| b).collect()).collect();
    let mut mate = [-1i32; 8];                     // mate: east junction -> west partner
    for a in 0..4 { grow(a, &mut mate, &mut Vec::new(), &nbr); }
    let mut pairs: Vec<(usize, usize)> = (4..8).filter(|&b| mate[b] >= 0).map(|b| (mate[b] as usize, b)).collect();
    pairs.sort();
    let mut stack: Vec<usize> = (0..4).filter(|&a| !pairs.iter().any(|&(w, _)| w == a)).collect();
    let mut z = stack.clone();                     // all an alternating walk reaches
    while let Some(a) = stack.pop() {
        for &b in &nbr[a] {
            if z.contains(&b) { continue }
            z.push(b);
            let w = mate[b] as usize;
            if mate[b] >= 0 && !z.contains(&w) { z.push(w); stack.push(w) }
        }
    }
    (pairs, (0..8).filter(|&x| if x < 4 { !z.contains(&x) } else { z.contains(&x) }).fold(0u32, |c, x| c | 1 << x))
}
fn hall(st: &[(usize, usize)]) -> (i32, u32, u32, u32) {   // ROAD THREE: Hall's worst set of west junctions
    let nbrs = |m: u32| st.iter().filter(|&&(u, _)| m >> u & 1 == 1).fold(0u32, |c, &(_, b)| c | 1 << b);
    let def = |m: u32| m.count_ones() as i32 - nbrs(m).count_ones() as i32;
    let mut bad = 0u32;                            // the west set with the biggest shortfall
    for m in 1..16u32 { if def(m) > def(bad) { bad = m } }
    (def(bad), bad, nbrs(bad), nbrs(bad) | (0..4).filter(|a| bad >> a & 1 == 0).fold(0, |c, a| c | 1 << a))
}
fn main() {
    let (nu, tau, alpha, rho, mins) = brute(8, &ST);
    let (pairs, cover) = built(&ST);
    let (gap, bad, side, hcover) = hall(&ST);
    let (t_nu, t_tau, ..) = brute(3, &TRI);
    let matched = pairs.iter().map(|&(a, b)| format!("{}-{}", NAMES[a], NAMES[b])).collect::<Vec<String>>().join("; ");
    println!("plan: {} junctions, west {} and east {}; {} streets, each a bridge", NAMES.len(), show(WESTM), show(EASTM), ST.len());
    println!("road one, all {} sets of junctions: fewest guards tau = {}, largest independent set alpha = {}", 1 << 8, tau, alpha);
    println!("road one, all {} sets of streets: largest matching nu = {}, smallest edge cover rho = {}", 1 << ST.len(), nu, rho);
    println!("road one, guard sets of size {}: {}, namely {}", tau, mins.len(), show(mins[0]));
    println!("road two, matching grown by alternating walks: {}", matched);
    println!("road two, guards read off that matching: {}", show(cover));
    println!("road three, worst west set for Hall's test: {} reaching only {}; shortfall {}; guards from it: {}", show(bad), show(side), gap, show(hcover));
    println!("Konig: largest matching {} = fewest guards {}", nu, tau);
    println!("Gallai: alpha + tau = {} + {} = {}, and nu + rho = {} + {} = {}", alpha, tau, alpha + tau, nu, rho, nu + rho);
    println!("mistakes: both ends of each matched street {} guards; one whole bank {} guards; an edge cover {} streets, not {}", 2 * nu, WESTM.count_ones(), rho, tau);
    println!("a triangle of streets: nu = {} but tau = {}, so Konig needs two banks", t_nu, t_tau);
    assert!(nu == tau && nu as usize == pairs.len() && nu == 3);   // Konig: brute force meets the walk
    assert!(cover == mins[0] && mins.len() == 1);        // the built guard set is the only smallest one
    assert!(hcover == cover && nu as i32 == 4 - gap);    // Hall's shortfall names the same guards
    assert!(alpha + tau == 8 && nu + rho == 8 && (t_nu, t_tau) == (1, 2));
    println!("ALL CHECKS PASS");
}
