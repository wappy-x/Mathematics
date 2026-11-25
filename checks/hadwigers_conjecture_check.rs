// Hadwiger's conjecture -- the same check as the Python, in Rust.  No crates.
// A graph with no K(t) minor should need at most t - 1 colours.  For three small graphs the program
// finds the chromatic number chi and the largest complete minor h by search, and checks chi <= h.

fn graph(n: usize, lines: &[(usize, usize)]) -> Vec<u32> {  // each dot's neighbours as a bitmask
    let mut adj = vec![0u32; n];
    for &(a, b) in lines { adj[a] |= 1 << b; adj[b] |= 1 << a; }
    adj
}

fn colourings(adj: &[u32], k: usize) -> u64 {  // road 1 to chi: count proper k-colourings, dot by dot
    fn go(adj: &[u32], k: usize, col: &mut Vec<usize>) -> u64 {
        let v = col.len();
        if v == adj.len() { return 1; }
        let mut total = 0;
        for c in 0..k {
            if !(0..v).any(|u| adj[v] >> u & 1 == 1 && col[u] == c) {
                col.push(c);
                total += go(adj, k, col);
                col.pop();
            }
        }
        total
    }
    go(adj, k, &mut vec![])
}

fn chrom_poly(n: usize, lines: &[(usize, usize)], k: i64) -> i64 {  // road 2: sum over line sets of (-1)^|S| k^pieces
    let mut total = 0i64;
    for s in 0u32..1 << lines.len() {
        let mut parent: Vec<usize> = (0..n).collect();
        fn root(p: &Vec<usize>, mut x: usize) -> usize { while p[x] != x { x = p[x]; } x }
        for (i, &(a, b)) in lines.iter().enumerate() {
            if s >> i & 1 == 1 { let (ra, rb) = (root(&parent, a), root(&parent, b)); parent[ra] = rb; }
        }
        let pieces = (0..n).filter(|&v| root(&parent, v) == v).count() as u32;
        total += if s.count_ones() % 2 == 0 { 1 } else { -1 } * k.pow(pieces);
    }
    total
}

fn connected(adj: &[u32], m: u32) -> bool {
    let mut seen = m & m.wrapping_neg();
    loop {
        let mut grown = seen;
        for v in 0..adj.len() { if seen >> v & 1 == 1 { grown |= adj[v] & m; } }
        if grown == seen { return seen == m; }
        seen = grown;
    }
}

// K(t) minors: t disjoint joined-up branch sets, each pair touching
fn minor_models(adj: &[u32], t: usize, stop_at_first: bool) -> u64 {
    let n = adj.len();
    let mut sets = vec![];
    for m in 1u32..1 << n {
        if connected(adj, m) {
            let mut out = 0;
            for v in 0..n { if m >> v & 1 == 1 { out |= adj[v]; } }
            sets.push((m, out & !m, m.trailing_zeros() as usize));
        }
    }
    fn go(sets: &[(u32, u32, usize)], n: usize, t: usize, stop: bool, chosen: &mut Vec<u32>, used: u32, lo: usize, found: &mut u64) -> bool {
        if chosen.len() == t { *found += 1; return stop; }
        for &(m, out, low) in sets {  // sets taken in order of their lowest dot, so each model once
            if low >= lo && m & used == 0 && chosen.iter().all(|&c| out & c != 0)
                && n - (used | m).count_ones() as usize + 1 >= t - chosen.len() {
                chosen.push(m);
                let done = go(sets, n, t, stop, chosen, used | m, low + 1, found);
                chosen.pop();
                if done { return true; }
            }
        }
        false
    }
    let mut found = 0;
    go(&sets, n, t, stop_at_first, &mut vec![], 0, 0, &mut found);
    found
}

fn chi(adj: &[u32]) -> usize { (1..=adj.len()).find(|&k| colourings(adj, k) > 0).unwrap() }

fn hadwiger(adj: &[u32]) -> usize { (1..=adj.len() + 1).find(|&t| minor_models(adj, t, true) == 0).unwrap() - 1 }

fn main() {
    let mut petersen = vec![];
    for i in 0..5 { petersen.push((i, (i + 1) % 5)); }
    for i in 0..5 { petersen.push((5 + i, 5 + (i + 2) % 5)); }
    for i in 0..5 { petersen.push((i, i + 5)); }
    let spindle = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (0, 4), (0, 5), (4, 5), (4, 6), (5, 6), (3, 6)];
    let mut k22222 = vec![];
    for a in 0..10 { for b in a + 1..10 { if a / 2 != b / 2 { k22222.push((a, b)); } } }
    let (pet, spin, k5x2) = (graph(10, &petersen), graph(7, &spindle), graph(10, &k22222));
    let mut tri = 0;
    for a in 0..10 { for b in 0..a { for c in 0..b {
        if pet[a] >> b & 1 == 1 && pet[a] >> c & 1 == 1 && pet[b] >> c & 1 == 1 { tri += 1; }
    } } }
    println!("Petersen graph: {} dots, {} lines, {} triangles", pet.len(), petersen.len(), tri);
    let (p2, p3) = (colourings(&pet, 2), colourings(&pet, 3));
    let (q2, q3) = (chrom_poly(10, &petersen, 2), chrom_poly(10, &petersen, 3));
    println!("proper colourings, by search: 2 colours {}, 3 colours {}; by the chromatic polynomial: P(2) = {}, P(3) = {}", p2, p3, q2, q3);
    let spokes: Vec<u32> = (0..5).map(|i| (1 << i) | (1 << (i + 5))).collect();
    let mut touch = 0;
    for i in 0..5 { for j in 0..i {
        if (0..10).any(|v| spokes[i] >> v & 1 == 1 && pet[v] & spokes[j] != 0) { touch += 1; }
    } }
    println!("contract the 5 spokes: {} of 10 pairs of fused dots touch, so K(5) is a minor", touch);
    let (k5, k6) = (minor_models(&pet, 5, false), minor_models(&pet, 6, false));
    println!("search: K(5) minor models {}, K(6) minor models {}; a K(5) set needs 4 exits, one dot has 3, so each model uses 10 dots", k5, k6);
    let need = (1..10).find(|&s| 3 * s - 2 * (s - 1) >= 5).unwrap();
    println!("count: a K(6) branch set of s dots has at most s + 2 exits, needs 5, so s >= {}; 6 x {} = {} > 10 dots", need, need, 6 * need);
    let (hp, cp) = (hadwiger(&pet), chi(&pet));
    println!("Petersen: largest complete minor h = {}, chi = {}; no K({}) minor, so the proved case t = {} allows {} colours", hp, cp, hp + 1, hp + 1, hp);
    let (s3, s4) = (colourings(&spin, 3), colourings(&spin, 4));
    let (ps3, ps4) = (chrom_poly(7, &spindle, 3), chrom_poly(7, &spindle, 4));
    println!("Moser spindle: 3-colourings {} of {}, P(3) = {}; 4-colourings {}, P(4) = {}", s3, 3u32.pow(7), ps3, s4, ps4);
    let (hs, cs) = (hadwiger(&spin), chi(&spin));
    println!("Moser spindle: h = {}, chi = {}, equality", hs, cs);
    let (hk, ck) = (hadwiger(&k5x2), chi(&k5x2));
    let om = (0u32..1 << 10).filter(|&m| (0..10).all(|v| m >> v & 1 == 0 || (k5x2[v] | 1 << v | (!m & 1023)) == 1023))
        .map(|m| m.count_ones()).max().unwrap();
    let k8 = minor_models(&k5x2, 8, false);
    println!("K(2,2,2,2,2): 10 dots, {} lines; h = {}, chi = {}; the t <= 7 line formula at t = 8 gives 6 x 10 - 21 = {}", k22222.len(), hk, ck, 6 * 10 - 21);
    println!("K(2,2,2,2,2): K(8) minor models {}; count: 8 sets in 10 dots need >= {} single dots, all joined, but the largest all-joined group has {}", k8, 8 - 2, om);
    println!("  t  conjecture  edge-count road 2t-4  best proved");
    for t in 3..8 { println!("{:>3}{:>12}{:>22}{:>13}", t, t - 1, 2 * t - 4, if t <= 6 { t - 1 } else { 8 }); }
    let f = |x: f64| 1.0 - x + 2.0 * x * x.ln();
    let (mut lo, mut hi) = (0.1f64, 0.5f64);
    for _ in 0..100 {  // road 1 to Thomason's lambda: bisection
        let mid = (lo + hi) / 2.0;
        if f(mid) > 0.0 { lo = mid; } else { hi = mid; }
    }
    let mut x = 0.3f64;
    for _ in 0..50 { x -= f(x) / (1.0 + 2.0 * x.ln()); }  // road 2: Newton's method, f'(x) = 1 + 2 log x
    let alpha = (1.0 - lo) / (1.0 / lo).ln().sqrt();
    println!("Thomason: lambda = {:.6} by bisection, {:.6} by Newton; alpha = {:.5}", lo, x, alpha);
    println!("  t       extra factor sqrt(log t)  extra factor log log t");
    for e in [2, 6, 100] {
        let lt = e as f64 * 10f64.ln();
        println!("  10^{:<5}{:>24.2}{:>24.2}", e, lt.sqrt(), lt.ln());
    }
    println!("mistake 1, minor read as subgraph: no triangle in Petersen, so '2 colours'; true chi = {}", cp);
    println!("mistake 2, read backwards: K({}) minor, so '{} colours'; true chi = {}", hp, hp, cp);
    println!("mistake 3, t = 5 applied to Petersen: ceiling 4, but it has a K(5) minor; the case that applies is t = 6, ceiling 5");
    println!("mistake 4, Mader's count past t = 7: {} lines > {}, yet no K(8) minor", k22222.len(), 6 * 10 - 21);
    assert!(p2 == 0 && q2 == 0 && p3 as i64 == q3 && p3 > 0);  // two roads to chi(Petersen) = 3
    assert!(touch == 10 && k5 == 6 && k6 == 0 && hp == 5);
    assert!(s3 == 0 && ps3 == 0 && s4 as i64 == ps4 && s4 > 0);
    assert!((hs, cs) == (4, 4) && (hk, ck) == (7, 5) && k8 == 0 && om == 5 && om < 8 - 2 && k22222.len() > 6 * 10 - 21);
    assert!([(cp, hp), (cs, hs), (ck, hk)].iter().all(|&(c, h)| c <= h));  // the conjecture's instances, checked
    assert!((lo - x).abs() < 1e-12 && (alpha - 0.63817).abs() < 1e-5);  // two roads to lambda; alpha as Thomason states it
    println!("ALL CHECKS PASS");
}
