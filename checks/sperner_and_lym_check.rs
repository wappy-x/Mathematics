// Sperner and LYM -- the same check as the Python, in Rust.  No crates.  Managers
// 1 to 4; a group of them is a 4-bit mask.  Road one tries all 2^16 families of
// groups and keeps the antichains.  Road two walks the 24 arrival orders.  Road
// three splits the 16 groups into 6 chains.  The odd case n = 5 comes last.
fn size(s: u32) -> u64 { s.count_ones() as u64 }
fn fact(k: u64) -> u64 { if k < 2 { 1 } else { k * fact(k - 1) } }
fn show(fam: &[u32]) -> String {
    let one = |s: &u32| format!("'{{{}}}'", (0..4).filter(|i| s >> i & 1 == 1)
        .map(|i| (i + 1).to_string()).collect::<Vec<_>>().join(","));
    format!("[{}]", fam.iter().map(one).collect::<Vec<_>>().join(", "))
}
fn weight(fam: &[u32], n: u64) -> u64 { fam.iter().map(|&a| fact(size(a)) * fact(n - size(a))).sum() }
fn orders(rest: &[u32]) -> Vec<Vec<u32>> {          // every arrival order, built one place at a time
    if rest.is_empty() { return vec![vec![]] }
    let mut out = vec![];
    for &x in rest {
        for o in orders(&rest.iter().copied().filter(|&y| y != x).collect::<Vec<u32>>()) { let mut v = vec![x]; v.extend(o); out.push(v) }
    }
    out
}
fn hits(fam: &[u32], n: u32) -> (u64, u64) {        // orders whose growing group meets fam, and the most meetings
    let (mut met, mut most) = (0, 0);
    for o in orders(&(0..n).collect::<Vec<u32>>()) {
        let m = (0..=n as usize).filter(|&j| fam.contains(&o[..j].iter().map(|x| 1u32 << x).sum::<u32>())).count() as u64;
        if m > 0 { met += 1 }
        most = most.max(m);
    }
    (met, most)
}
fn antichain(fam: &[u32]) -> bool { fam.iter().all(|&a| fam.iter().all(|&b| a == b || a & b != a)) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn main() {
    let above: Vec<u32> = (0..16).map(|a: u32| (0..16).filter(|&b: &u32| a & b == a && a != b).map(|b| 1u32 << b).sum()).collect();
    let fams: Vec<Vec<u32>> = (0u32..1 << 16)
        .filter(|&f| (0..16).all(|a| f >> a & 1 == 0 || f & above[a as usize] == 0))
        .map(|f| (0..16).filter(|a| f >> a & 1 == 1).collect()).collect();
    let best = fams.iter().map(|f| f.len()).max().unwrap();
    let tops: Vec<&Vec<u32>> = fams.iter().filter(|f| f.len() == best).collect();
    let example = vec![0b0001u32, 0b0110, 0b1010, 0b1100];
    println!("groups of each size, 0 to 4: {:?}", (0..5).map(|k| (0..16).filter(|&a| size(a) == k).count()).collect::<Vec<_>>());
    println!("tidy rule books (antichains) of 4 managers: {}; largest has {} lines", fams.len(), best);
    println!("rule books with {} lines: {}: {}", best, tops.len(), show(tops[0]));
    let (h, most) = hits(&example, 4);
    let score: f64 = example.iter().map(|&a| 1.0 / (24 / fact(size(a)) / fact(4 - size(a))) as f64).sum();
    println!("example {}: 1/4 + 3/6 = {:.2}", show(&example), score);
    let room = (0..16u32).filter(|b| !example.contains(b) && antichain(&[example.clone(), vec![*b]].concat())).count();
    println!("  arrival orders meeting it: {} of 24 = {:.2}; most meetings in one order: {}; groups that still fit: {}", h, h as f64 / 24.0, most, room);
    println!("  orders through each line, k!(4-k)!: {:?}", example.iter().map(|&a| fact(size(a)) * fact(4 - size(a))).collect::<Vec<_>>());
    let road_two = fams.iter().all(|f| hits(f, 4) == (weight(f, 4), f.len().min(1) as u64));
    println!("every antichain: orders met = sum of k!(4-k)!, never twice: {}", yn(road_two));
    let top_score = fams.iter().map(|f| weight(f, 4)).max().unwrap();
    println!("largest LYM score over all antichains: {}/24", top_score);
    let chains: Vec<Vec<u32>> = vec![vec![0, 1, 3, 7, 15], vec![2, 6, 14], vec![4, 5, 13], vec![8, 9, 11], vec![10], vec![12]];
    let mut all: Vec<u32> = chains.iter().flatten().copied().collect();
    all.sort();
    let cover = all == (0..16).collect::<Vec<u32>>();
    let nested = chains.iter().all(|c| c.windows(2).all(|w| w[0] & w[1] == w[0]));
    println!("16 groups split into {} chains, sizes {:?}: {}", chains.len(), chains.iter().map(|c| c.len()).collect::<Vec<_>>(), yn(cover && nested));
    let pairs: Vec<u32> = (0..16).filter(|&a| size(a) == 2).collect();
    let plus1: Vec<u32> = pairs.iter().copied().chain([0b0001]).collect();
    let nest = plus1.iter().map(|&a| plus1.iter().filter(|&&b| a & b == a && a != b).count()).sum::<usize>();
    println!("mistake 1, six pairs plus {{1}}: {} lines, {} nested, score {}/24", plus1.len(), nest, weight(&plus1, 4));
    println!("mistake 2, one member per order, unweighted: at most {} lines, not {}", fact(4), best);
    let singles = vec![1u32, 2, 4, 8];
    println!("mistake 3, the four singles meet {} of 24 orders but have {} lines", hits(&singles, 4).0, singles.len());
    let mut layers_ok = true;
    for k in [2u64, 3] {
        let lay: Vec<u32> = (0..32).filter(|&a| size(a) == k).collect();
        println!("n = 5, all {}-groups: {} lines, antichain {}, orders met {} of 120", k, lay.len(), yn(antichain(&lay)), hits(&lay, 5).0);
        layers_ok &= lay.len() == 10 && antichain(&lay);
    }
    let caps: Vec<u64> = (1..=10u64).map(|n| fact(n) / fact(n / 2) / fact(n - n / 2)).collect();
    println!("largest tidy rule book, C(n, n//2), for n = 1 to 10: {:?}", caps);
    assert!(fams.len() == 168 && best == 6 && best as u64 == 24 / fact(2) / fact(2)); // Dedekind; C(4,2)
    assert!(tops.len() == 1 && *tops[0] == pairs);                                    // only the middle layer
    assert!(road_two && h == 18 && h == weight(&example, 4) && room == 0);                       // chains agree with weights
    assert!(top_score == 24 && cover && nested);                                      // LYM <= 1; 6 chains cover
    assert!(hits(&singles, 4).0 == 24 && layers_ok);
    println!("ALL CHECKS PASS");
}
