// Degrees and the handshaking lemma -- the same check as the Python, in Rust.  No crates.
// The metro map is stations A to F, lines A-B B-C C-D D-E E-F F-A and the crossings B-E
// and C-F.  The degree total is reached twice: the ends tallied station by station, and
// the station-by-line table added down its columns.  A census of all 64 graphs on four
// named stations tests parity and lists their degree sequences; then Havel-Hakimi runs.
const NAMES: [char; 6] = ['A', 'B', 'C', 'D', 'E', 'F'];
const METRO: [(usize, usize); 8] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
fn degrees(n: usize, edges: &[(usize, usize)]) -> Vec<i64> {   // road one: ends per station
    let mut deg = vec![0i64; n];
    for &(u, v) in edges { deg[u] += 1; deg[v] += 1 }           // a loop has u == v: two ends
    deg
}
fn desc(deg: &[i64]) -> Vec<i64> { let mut s = deg.to_vec(); s.sort_by(|a, b| b.cmp(a)); s }
fn havel_hakimi(wish: &[i64]) -> Option<Vec<(usize, usize)>> {  // a graph, or give up
    let mut left: Vec<(i64, usize)> = wish.iter().enumerate().map(|(i, &d)| (d, i)).collect();
    let mut built: Vec<(usize, usize)> = Vec::new();
    loop {
        left.sort_by_key(|&(d, i)| (-d, i));
        if left[0].0 == 0 { return Some(built) }
        let (d, v) = (left[0].0 as usize, left[0].1);
        left[0].0 = 0;                                          // the greediest is now served
        if d >= left.len() || left[1..=d].iter().any(|p| p.0 == 0) { return None }
        for p in left[1..=d].iter_mut() { p.0 -= 1; built.push((v, p.1)) }
    }
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let wishes: Vec<Vec<i64>> = vec![vec![3, 3, 3, 3, 2, 2], vec![3, 3, 3, 1], vec![3, 3, 3], vec![4; 9]];
    let looped_e: Vec<(usize, usize)> = METRO.iter().copied().chain([(0, 0)]).collect();
    let doubled_e: Vec<(usize, usize)> = METRO.iter().copied().chain([(1, 2)]).collect();
    let deg = degrees(6, &METRO);
    let t: Vec<Vec<i64>> = (0..6).map(|s| METRO.iter()             // road two: the table
        .map(|&(u, v)| (u == s) as i64 + (v == s) as i64).collect()).collect();
    let rows: Vec<i64> = t.iter().map(|r| r.iter().sum()).collect();
    let cols: Vec<i64> = (0..METRO.len()).map(|j| t.iter().map(|r| r[j]).sum()).collect();
    let odd: Vec<String> = (0..6).filter(|&i| deg[i] % 2 == 1).map(|i| NAMES[i].to_string()).collect();
    let pairs4: Vec<(usize, usize)> = (0..4).flat_map(|a| (a + 1..4).map(move |b| (a, b))).collect();
    let (mut dist, mut census, mut seqs) = ([0usize; 5], true, Vec::<Vec<i64>>::new());
    for mask in 0..(1u32 << pairs4.len()) {   // every graph on four named stations, all 64 of them
        let es: Vec<(usize, usize)> = (0..pairs4.len()).filter(|i| mask >> i & 1 == 1).map(|i| pairs4[i]).collect();
        let dg = degrees(4, &es);
        census = census && dg.iter().sum::<i64>() == 2 * mask.count_ones() as i64;
        dist[dg.iter().filter(|d| *d % 2 == 1).count()] += 1; if !seqs.contains(&desc(&dg)) { seqs.push(desc(&dg)) }
    }
    let hh: Vec<Option<Vec<(usize, usize)>>> = wishes.iter().map(|w| havel_hakimi(w)).collect();
    let graphic: Vec<bool> = wishes.iter().zip(&hh)
        .map(|(w, b)| b.as_ref().map_or(false, |e| desc(&degrees(w.len(), e)) == *w)).collect();
    let (looped, doubled) = (degrees(6, &looped_e), degrees(6, &doubled_e));
    let total: i64 = deg.iter().sum();
    println!("the metro: 6 stations, {} lines\n  {}", METRO.len(),
             (0..6).map(|i| format!("{} deg {}", NAMES[i], deg[i])).collect::<Vec<_>>().join("   "));
    println!("degree sequence, largest first: {:?}", desc(&deg));
    println!("road 1, the ends tallied at each station and added: {}; average per station {} / 6 = {:.2}", total, total, total as f64 / 6.0);
    println!("road 2, the station-by-line table, a 1 where a line ends at a station: {}; columns add to {:?} = {}; rows add to the degrees: {}",
             (0..6).map(|s| format!("{} {}", NAMES[s], t[s].iter().map(|x| x.to_string()).collect::<String>())).collect::<Vec<_>>().join("  "),
             cols, cols.iter().sum::<i64>(), yn(rows == deg));
    println!("odd-degree stations: {}, {} of them; an even count: {}", odd.join(" "), odd.len(), yn(odd.len() % 2 == 0));
    println!("all {} graphs on four named stations: degree total = 2 x lines every time: {}; {} degree sequences appear, (3, 3, 2, 2) among them and (3, 3, 3, 1) not: {}", 1 << pairs4.len(), yn(census), seqs.len(), yn(seqs.contains(&vec![3, 3, 2, 2]) && !seqs.contains(&vec![3, 3, 3, 1])));
    println!("odd-station counts, and how many graphs each: {}; never 1 or 3: {}",
             (0..5).filter(|&k| dist[k] > 0).map(|k| format!("{} -> {}", k, dist[k])).collect::<Vec<_>>().join(", "),
             yn(dist[1] == 0 && dist[3] == 0));
    println!("party of 9 each shaking 3 hands: 9 x 3 = {}, odd, so no such party\nparty of 9 each shaking 4 hands: 9 x 4 = {} = 2 x {} handshakes, so possible", 9 * 3, 9 * 4, 9 * 4 / 2);
    println!("Havel-Hakimi on wished-for degree lists:");
    for ((w, b), &g) in wishes.iter().zip(&hh).zip(&graphic) {
        let built = if g { format!("  built {} lines", b.as_ref().unwrap().len()) } else { String::new() };
        println!("  {:?} sum {} even {}  graphic {}{}", w, w.iter().sum::<i64>(), yn(w.iter().sum::<i64>() % 2 == 0), yn(g), built);
    }
    println!("mistake 1, each line counted once, not at both ends: {}, not {}", METRO.len(), total);
    println!("mistake 2, a loop at A counted as one end: {} for {} lines, odd; the truth is {}\nmistake 3, the second B-C track merged away: {} for {} lines; the truth is {}",
             looped.iter().sum::<i64>() - 1, looped_e.len(), looped.iter().sum::<i64>(), total, doubled_e.len(), doubled.iter().sum::<i64>());
    assert!(rows == deg && cols == vec![2i64; METRO.len()] && cols.iter().sum::<i64>() == total);
    assert!(desc(&deg) == vec![3, 3, 3, 3, 2, 2] && odd == vec!["B", "C", "E", "F"]);
    assert!(census && dist == [8, 0, 48, 0, 8] && seqs.len() == 11 && seqs.contains(&vec![3, 3, 2, 2]) && !seqs.contains(&vec![3, 3, 3, 1]));
    assert!(graphic == vec![true, false, false, true]
            && looped.iter().sum::<i64>() == 2 * looped_e.len() as i64
            && doubled.iter().sum::<i64>() == 2 * doubled_e.len() as i64);
    println!("ALL CHECKS PASS");
}
