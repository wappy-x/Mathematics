// Ramsey numbers -- the same check as the Python, in Rust.  No crates.  Towns, every pair joined by one
// road, paved or gravel.  A county is a list of bitmasks: bit j of paved[i] is set when road i-j is paved.
// R(3,4) = 9 is reached twice: by the recursion with its parity step, and by searching every county.
const T: &str = "ABCDEFGHI";
const PAIRS: [(u64, u64); 6] = [(3, 3), (3, 4), (3, 5), (4, 4), (4, 5), (5, 5)];
fn cliques(adj: &[u32], m: u32, k: u32, lo: usize) -> u64 {  // k-sets inside m, every road among them in adj
    if k == 0 { return 1 }
    (lo..adj.len()).filter(|&v| m >> v & 1 == 1).map(|v| cliques(adj, adj[v] & m, k - 1, v + 1)).sum()
}
fn full(n: usize) -> u32 { ((1u64 << n) - 1) as u32 }
fn other(adj: &[u32]) -> Vec<u32> { adj.iter().enumerate().map(|(i, &a)| full(adj.len()) ^ a ^ (1 << i)).collect() }
fn dodges(adj: &[u32], s: u32, t: u32) -> bool { cliques(adj, full(adj.len()), s, 0) == 0 && cliques(&other(adj), full(adj.len()), t, 0) == 0 }
fn sweep(s: u32, t: u32, top: usize) -> Vec<usize> {  // road two: add one town at a time, keep every county that dodges
    let (mut level, mut counts): (Vec<Vec<u32>>, Vec<usize>) = (vec![vec![]], vec![0]);
    for _ in 1..=top {                          // sm: the towns the new town reaches by paved road
        level = level.iter().flat_map(|adj| (0..1u32 << adj.len())
            .filter(move |&sm| cliques(adj, sm, s - 1, 0) == 0 && cliques(&other(adj), full(adj.len()) & !sm, t - 1, 0) == 0)
            .map(move |sm| { let mut nx: Vec<u32> = adj.iter().enumerate().map(|(i, &a)| a | (sm >> i & 1) << adj.len()).collect(); nx.push(sm); nx }))
            .collect();
        counts.push(level.len());
    }
    counts
}
fn labelled(col: u32) -> Vec<u32> {           // six towns, road number b paved when bit b of col is set
    let (mut adj, mut b) = (vec![0u32; 6], 0);
    for i in 0..6 { for j in i + 1..6 { if col >> b & 1 == 1 { adj[i] |= 1 << j; adj[j] |= 1 << i } b += 1 } }
    adj
}
fn county(n: usize, gaps: &[usize]) -> Vec<u32> {
    (0..n).map(|i| (0..n).filter(|&j| gaps.contains(&((j + n - i) % n))).map(|j| 1u32 << j).sum()).collect()
}
fn binom(n: u64, k: u64) -> u64 {             // n choose k from factorials
    let fact = |x: u64| (1..=x).product::<u64>();
    fact(n) / (fact(k) * fact(n - k))
}
fn rec(s: u64, t: u64) -> u64 { if s == 2 { t } else if t == 2 { s } else { rec(s - 1, t) + rec(s, t - 1) } }
fn known(s: u64, t: u64) -> Option<u64> {
    if s == 2 { return Some(t) } if t == 2 { return Some(s) }
    match (s.min(t), s.max(t)) { (3, 3) => Some(6), (3, 4) => Some(9), (3, 5) => Some(14), (4, 4) => Some(18), (4, 5) => Some(25), _ => None }
}
fn row(label: &str, cells: Vec<String>) { println!("{}{}", label, cells.iter().map(|c| format!("{:>8}", c)).collect::<String>()) }
fn main() {
    let (e33, e24, e34) = (sweep(3, 3, 6), sweep(2, 4, 4), sweep(3, 4, 9));
    let first_zero = |e: &Vec<usize>| (1..e.len()).find(|&n| e[n] == 0).unwrap() as u64;
    let (r33, r24, r34) = (first_zero(&e33), first_zero(&e24), first_zero(&e34));
    let brute6 = (0..1u32 << 15).filter(|&col| dodges(&labelled(col), 3, 4)).count();   // road three
    let (paved, ends) = (8 - (r33 - 1), 9 * (8 - (r33 - 1)));   // at most R(3,3) - 1 gravel of 8; paved road-ends
    let (ring, paley, c13) = (county(8, &[1, 4, 7]), county(17, &(1..17).map(|x| x * x % 17).collect::<Vec<usize>>()), county(13, &[1, 5, 8, 12]));
    let tb = T.as_bytes();
    let roads: Vec<String> = (0..8).flat_map(|i| (i + 1..8).map(move |j| (i, j))).filter(|&(i, j)| ring[i] >> j & 1 == 1)
        .map(|(i, j)| format!("{}-{}", tb[i] as char, tb[j] as char)).collect();
    let chain: Vec<u64> = PAIRS.iter().map(|&(s, t)| known(s - 1, t).unwrap() + known(s, t - 1).unwrap()).collect();
    println!("nine towns {}: roads C(9,2) = {}, ways to surface them 2^36 = {}", T, binom(9, 2), 1u64 << 36);
    println!("search, no paved trio or gravel trio: 5 towns {}, 6 towns {}, so R(3,3) = {}", e33[5], e33[6], r33);
    println!("search, no paved road or gravel foursome: 3 towns {}, 4 towns {}, so R(2,4) = {}", e24[3], e24[4], r24);
    println!("recursion: R(3,4) <= R(2,4) + R(3,3) = {} + {} = {}", r24, r33, r24 + r33);
    println!("nine towns, 8 roads each: paved at most {}, gravel at most {}, so paved exactly {}", r24 - 1, r33 - 1, paved);
    println!("paved road-ends 9 x {} = {}, odd, but every road has 2 ends: no such county, R(3,4) <= 9", paved, ends);
    println!("search, no paved trio or gravel foursome: {}", (6..10).map(|n| format!("{} towns {}", n, e34[n])).collect::<Vec<_>>().join(", "));
    println!("six towns by brute force over all {} labellings: {} dodge", 1u32 << 15, brute6);
    println!("the 8-town escape, paved: {}", roads.join(", "));
    println!("  paved trios {} of {}, gravel foursomes {} of {}, paved roads per town {:?}, so R(3,4) = 9",
             cliques(&ring, 255, 3, 0), binom(8, 3), cliques(&other(&ring), 255, 4, 0), binom(8, 4), ring.iter().map(|a| a.count_ones()).collect::<Vec<u32>>());
    row("s,t            ", PAIRS.iter().map(|&(s, t)| format!("{},{}", s, t)).collect());
    row("known R(s,t)   ", PAIRS.iter().map(|&(s, t)| known(s, t).map_or("43..46".to_string(), |v| v.to_string())).collect());
    row("C(s+t-2, s-1)  ", PAIRS.iter().map(|&(s, t)| binom(s + t - 2, s - 1).to_string()).collect());
    row("by recursion   ", PAIRS.iter().map(|&(s, t)| rec(s, t).to_string()).collect());
    row("chained known  ", chain.iter().map(|c| c.to_string()).collect());
    println!("17 towns, paved when the gap is a square mod 17: one-colour foursomes {} + {} of {}, so R(4,4) > 17",
             cliques(&paley, full(17), 4, 0), cliques(&other(&paley), full(17), 4, 0), binom(17, 4));
    println!("13 towns, paved at gaps 1, 5, 8, 12: paved trios {}, gravel five-sets {} of {}, so R(3,5) > 13",
             cliques(&c13, full(13), 3, 0), cliques(&other(&c13), full(13), 5, 0), binom(13, 5));
    println!("mistake 1, parity step skipped: R(3,4) <= {}; mistake 2, ceiling read as the value: R(5,5) = {}; mistake 3, only paved trios counted: an all-gravel county of 9 has {}",
             r24 + r33, binom(8, 4), cliques(&[0u32; 9], 511, 3, 0));
    assert!(e34[9] == 0 && ends % 2 == 1);     // the search and the parity step agree: nine towns never dodge
    assert!(brute6 == e34[6]);                 // one-town-at-a-time search against labelling every road
    assert!(PAIRS.iter().all(|&(s, t)| binom(s + t - 2, s - 1) == rec(s, t)));
    assert!(dodges(&ring, 3, 4) && dodges(&paley, 4, 4) && dodges(&c13, 3, 5) && (ring.len() as u64 + 1, c13.len() as u64 + 1, paley.len() as u64 + 1) == (r34, rec(2, 5) + r34, r34 + r34));
    println!("ALL CHECKS PASS");
}
