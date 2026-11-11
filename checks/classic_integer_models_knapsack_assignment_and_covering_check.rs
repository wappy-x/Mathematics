// Four classic integer models -- the same check as the Python, in Rust.  No crates.
// A festival books acts (knapsack), slots headliners (assignment), places first-aid
// posts (covering) and routes its van (routing); every answer is reached two ways.
fn splitmix(s: u64) -> (u64, u64) {       // SplitMix64, a small fixed random-number generator
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn make_acts(seed: u64) -> Vec<(i64, i64)> { // 60 acts: fee in units of 500 pounds, draw in tickets
    let (mut acts, mut s) = (Vec::new(), seed);
    for _ in 0..60 {
        let (s1, a) = splitmix(s); let (s2, b) = splitmix(s1);
        let fee = 1 + (a % 12) as i64;
        (s, acts) = (s2, [acts, vec![(fee, 40 * fee + (b % 300) as i64)]].concat());
    }
    acts
}
fn table(acts: &[(i64, i64)], w_max: usize) -> (i64, Vec<usize>) { // road 1: the table
    let mut k = vec![vec![0i64; w_max + 1]];
    for &(fee, draw) in acts {
        let prev = k.last().unwrap().clone();
        k.push((0..=w_max).map(|w| if fee as usize <= w { prev[w].max(prev[w - fee as usize] + draw) } else { prev[w] }).collect());
    }
    let (mut pick, mut w) = (Vec::new(), w_max);
    for i in (1..=acts.len()).rev() {      // walk back up the table to read off the acts
        if k[i][w] != k[i - 1][w] { pick.insert(0, i); w -= acts[i - 1].0 as usize; }
    }
    (k[acts.len()][w_max], pick)
}
// take acts in order while they fit; returns total, the act that does not fit, room left
fn fill(acts: &[(i64, i64)], order: &[usize], k: usize, mut room: i64, skip: bool) -> (i64, Option<usize>, i64) {
    let mut total = 0;
    for &i in &order[k..] {
        if acts[i].0 <= room { room -= acts[i].0; total += acts[i].1; }
        else if !skip { return (total, Some(i), room); }
    }
    (total, None, room)
}
fn visit(acts: &[(i64, i64)], order: &[usize], k: usize, room: i64, value: i64, best: &mut i64, nodes: &mut u64) {
    *nodes += 1;
    let (base, cut, left) = fill(acts, order, k, room, false);
    let Some(c) = cut else { *best = (*best).max(value + base); return; }; // everything left fits
    if (value + base) * acts[c].0 + acts[c].1 * left <= *best * acts[c].0 { return; } // bound cannot win
    *best = (*best).max(value);
    let (fee, draw) = acts[order[k]];
    if fee <= room { visit(acts, order, k + 1, room - fee, value + draw, best, nodes); }
    visit(acts, order, k + 1, room, value, best, nodes);
}
fn perms(items: &[usize]) -> Vec<Vec<usize>> { // every ordering, written out
    if items.len() <= 1 { return vec![items.to_vec()]; }
    (0..items.len()).flat_map(|k| { let rest = [&items[..k], &items[k + 1..]].concat();
        perms(&rest).into_iter().map(move |p| [vec![items[k]], p].concat()) }).collect()
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn frac(n: i64, d: i64) -> String { let g = gcd(n, d); if d / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) } }
const STOPS: [char; 6] = ['G', 'M', 'F', 'T', 'N', 'S'];
fn routing(edge: &[(&str, i64)], show: bool) -> (String, i64, Vec<i64>, usize) {
    let d: Vec<Vec<i64>> = STOPS.iter().map(|&a| STOPS.iter().map(|&b| edge.iter().filter(|e| e.0 == format!("{}{}", a, b)
        || e.0 == format!("{}{}", b, a)).map(|e| e.1).sum()).collect()).collect(); // a stop to itself: 0
    let tours: Vec<Vec<usize>> = perms(&[1, 2, 3, 4, 5]).into_iter().map(|p| [vec![0], p].concat()).collect();
    let length = |t: &Vec<usize>| -> i64 { (0..6).map(|k| d[t[k]][t[(k + 1) % 6]]).sum() };
    let tour = tours.iter().fold(&tours[0], |b, t| if length(t) < length(b) { t } else { b }); // road 1: 120 tours
    let moves: Vec<Vec<usize>> = perms(&[0, 1, 2, 3, 4, 5]).into_iter().filter(|p| (0..6).all(|i| p[i] != i)).collect();
    let (mut cuts, mut rounds): (Vec<Vec<usize>>, Vec<i64>) = (Vec::new(), Vec::new()); // road 2: assignment, then cut loops
    loop {
        let ok: Vec<&Vec<usize>> = moves.iter().filter(|p| cuts.iter().all(|s| s.iter().filter(|&&i| s.contains(&p[i])).count() <= s.len() - 1)).collect();
        let cost = |p: &Vec<usize>| -> i64 { (0..6).map(|i| d[i][p[i]]).sum() };
        let nxt = ok.iter().fold(ok[0], |b, &p| if cost(p) < cost(b) { p } else { b });
        let (mut found, mut seen): (Vec<Vec<usize>>, Vec<bool>) = (Vec::new(), vec![false; 6]);
        for i0 in 0..6 {                    // split the next-stop list into loops
            let (mut lp, mut i) = (Vec::new(), i0);
            while !seen[i] { seen[i] = true; lp.push(i); i = nxt[i]; }
            if !lp.is_empty() { found.push(lp); }
        }
        rounds.push(cost(nxt));
        let name = |l: &Vec<usize>| -> String { l.iter().map(|&k| STOPS[k]).collect() };
        if show { println!("routing round {}: {} allowed, best {} m, loops {}", rounds.len(), ok.len(), rounds.last().unwrap(),
                           found.iter().map(|l| name(l)).collect::<Vec<_>>().join(" ")); }
        if found.len() == 1 { return (name(tour) + "G", length(tour), rounds, tours.len()); }
        cuts.extend(found);
    }
}
fn main() {
    let (acts, w) = (make_acts(7), 80usize);
    let (best, pick) = table(&acts, w);
    let mut order: Vec<usize> = (0..60).collect(); // best tickets per pound first, ties by number
    order.sort_by(|&i, &j| (acts[j].1 * acts[i].0).cmp(&(acts[i].1 * acts[j].0)).then(i.cmp(&j)));
    let (mut bb, mut nodes) = (0i64, 0u64);       // road 2: branch and bound
    visit(&acts, &order, 0, w as i64, 0, &mut bb, &mut nodes);
    let (base, cut, left) = fill(&acts, &order, 0, w as i64, false);
    let c = cut.unwrap(); let k = order.iter().position(|&i| i == c).unwrap(); // the act the fractional bound cuts, and its rank
    let (lp_num, lp_den) = (base * acts[c].0 + acts[c].1 * left, acts[c].0);
    let greedy = fill(&acts, &order, 0, w as i64, true).0;
    let mut by_draw: Vec<usize> = (0..60).collect(); by_draw.sort_by(|&i, &j| acts[j].1.cmp(&acts[i].1).then(i.cmp(&j)));
    let big = fill(&acts, &by_draw, 0, w as i64, true).0;
    println!("knapsack: 60 acts, budget 40000 pounds = {} units of 500; maximise tickets; a full list has {} subsets", w, 1u64 << 60);
    println!("road 1, table of {} cells: {} tickets, {} acts, fees {} pounds", 60 * (w + 1), best, pick.len(), 500 * pick.iter().map(|&i| acts[i - 1].0).sum::<i64>());
    let ids = |v: &[usize]| [&v[..8], &v[8..]].iter().map(|row| row.iter().map(|&i| format!("{}:{}:{}", i, 500 * acts[i - 1].0, acts[i - 1].1))
        .collect::<Vec<_>>().join(" ")).collect::<Vec<_>>().join("\n");
    println!("acts booked (number:fee in pounds:tickets):\n{}", ids(&pick));
    println!("road 2, branch and bound: {} tickets, {} nodes visited", bb, nodes);
    println!("fractional bound: best {} acts by tickets per pound = {} tickets, {} units, in rank order:\n{}", k, base, w as i64 - left,
             ids(&order[..k].iter().map(|&i| i + 1).collect::<Vec<_>>()));
    println!("  then act {} (fee {}, {} tickets) fits {}, worth {}: bound {}", c + 1, 500 * acts[c].0, acts[c].1, frac(left, acts[c].0),
             frac(acts[c].1 * left, lp_den), frac(lp_num, lp_den));
    let gap = lp_num - best * lp_den;
    println!("gap between bound and best: {} tickets, {:.2} percent", frac(gap, lp_den), (gap * 100) as f64 / (lp_den * best) as f64);
    println!("greedy by tickets per pound, skipping misfits: {}; stopping at the first misfit: {}; by biggest draw: {}", greedy, base, big);
    assert!(best == bb && best * lp_den <= lp_num && lp_num < (best + 30) * lp_den); // table, tree and bound agree
    assert!(big < base && base < greedy && greedy < best);                       // every shortcut falls short
    // assignment: four headliners, four Saturday slots, crowd in hundreds; maximise
    let (names, slots) = (["Kestrel", "Lumen", "Marrow", "Nettle"], ["Main 21:00", "Main 19:00", "Tent 21:00", "Tent 19:00"]);
    let crowd = [[92, 70, 55, 40], [88, 60, 64, 45], [75, 66, 50, 48], [70, 52, 58, 30]];
    let total = |p: &Vec<usize>| -> i64 { (0..4).map(|i| crowd[i][p[i]]).sum() };
    let plans = perms(&[0, 1, 2, 3]);
    let plan = plans.iter().fold(&plans[0], |b, p| if total(p) > total(b) { p } else { b }); // road 1: 24 pairings
    let on = |m: u32, i: usize, j: usize| -> i64 { ((m >> (4 * i + j)) & 1) as i64 };
    let grids: Vec<u32> = (0..1u32 << 16).filter(|&m| (0..4).all(|i| (0..4).map(|j| on(m, i, j)).sum::<i64>() == 1)
        && (0..4).all(|j| (0..4).map(|i| on(m, i, j)).sum::<i64>() == 1)).collect(); // road 2: all 0-1 grids
    let grid_best = grids.iter().map(|&m| (0..16).map(|c| crowd[c / 4][c % 4] * on(m, c / 4, c % 4)).sum::<i64>()).max().unwrap();
    let (mut free, mut grab) = (vec![0usize, 1, 2, 3], 0i64);
    for i in 0..4 {                         // each act grabs its best free slot
        let j = free.iter().fold(free[0], |j, &f| if crowd[i][f] > crowd[i][j] { f } else { j });
        free.retain(|&f| f != j); grab += crowd[i][j];
    }
    println!("assignment, crowd in hundreds: {}", (0..4).map(|i| format!("{} {:?}", names[i], crowd[i])).collect::<Vec<_>>().join("; "));
    println!("  best: {}", (0..4).map(|i| format!("{} -> {}", names[i], slots[plan[i]])).collect::<Vec<_>>().join(", "));
    println!("  crowd {} hundred; 0-1 grids obeying the rules {} of {}, best {}; worst plan {}; grab {}", total(plan), grids.len(), 1 << 16,
             grid_best, plans.iter().map(|p| total(p)).min().unwrap(), grab);
    assert!(grids.len() == 24 && plans.len() == 24 && grid_best == total(plan) && grab < total(plan));
    // covering: eight zones, six possible first-aid posts; every zone covered; minimise cost
    let posts: [(&[usize], i64); 6] = [(&[3, 4, 5], 3000), (&[1, 2, 3, 8], 4500), (&[1, 6, 8], 3200),
                                       (&[2, 5, 7], 3200), (&[1, 2, 3, 4, 6, 7], 5700), (&[8], 1500)];
    println!("covering, zones and pounds: {}", (0..6).map(|k| format!("P{} {:?} {}", k + 1, posts[k].0, posts[k].1)).collect::<Vec<_>>().join("; "));
    let count = |m: usize, z: usize| (0..6).filter(|&k| m >> k & 1 == 1 && posts[k].0.contains(&z)).count();
    let cost = |m: usize| -> i64 { (0..6).filter(|&k| m >> k & 1 == 1).map(|k| posts[k].1).sum() };
    let covers: Vec<usize> = (0..64).filter(|&m| (1..=8).all(|z| count(m, z) >= 1)).collect();
    let exact = (0..64).filter(|&m| (1..=8).all(|z| count(m, z) == 1)).count();
    let cover = covers.iter().fold(covers[0], |b, &m| if cost(m) < cost(b) { m } else { b }); // road 1: 64 choices
    let mut dp: Vec<i64> = (0..256).map(|s| if s == 0 { 0 } else { 1_000_000_000 }).collect(); // road 2: cost per zone set
    for p in &posts {
        let mask: usize = p.0.iter().map(|z| 1 << (z - 1)).sum();
        for s in (0..256).rev() { dp[s | mask] = dp[s | mask].min(dp[s] + p.1); }
    }
    let (mut left, mut gcost, mut gpicks): (Vec<usize>, i64, Vec<String>) = ((1..=8).collect(), 0, Vec::new());
    while !left.is_empty() {                // greedy: cheapest per new zone
        let new = |k: usize| posts[k].0.iter().filter(|z| left.contains(z)).count() as i64;
        let pk = (0..6).filter(|&k| new(k) > 0).fold(usize::MAX, |pk, k|
            if pk == usize::MAX || posts[k].1 * new(pk) < posts[pk].1 * new(k) { k } else { pk });
        left.retain(|z| !posts[pk].0.contains(z));
        (gcost, gpicks) = (gcost + posts[pk].1, [gpicks, vec![format!("P{}", pk + 1)]].concat());
    }
    let label = |m: usize| (0..6).filter(|&k| m >> k & 1 == 1).map(|k| format!("P{}", k + 1)).collect::<Vec<_>>().join("+");
    println!("  best {} = {} pounds; zone-set table {}; {} of 64 choices cover", label(cover), cost(cover), dp[255], covers.len());
    println!("  greedy {} = {} pounds; 'exactly once' plans: {}", gpicks.join("+"), gcost, exact);
    assert!(cost(cover) == dp[255] && dp[255] == 9400 && gcost > cost(cover) && exact == 0);
    // routing: van from the gate G round five stops and back; metres; minimise
    let mut edge = [("GM", 300), ("GF", 200), ("MF", 250), ("TN", 300), ("TS", 350), ("NS", 400), ("GT", 900), ("GN", 1100),
                    ("GS", 800), ("MT", 600), ("MN", 800), ("MS", 900), ("FT", 700), ("FN", 1000), ("FS", 650)];
    println!("routing, metres: {}", edge.iter().map(|e| format!("{}={}", e.0, e.1)).collect::<Vec<_>>().join(" "));
    let (tour, tlen, rounds, ntours) = routing(&edge, true);
    println!("routing: all {} directed tours, best {} = {} m", ntours, tour, tlen);
    assert!(rounds.windows(2).all(|p| p[0] <= p[1]) && *rounds.last().unwrap() == tlen && rounds[0] < tlen); // cut loop meets brute force
    println!("try: budget 30000 -> {} tickets; budget 50000 -> {}", table(&acts, 60).0, table(&acts, 100).0);
    edge[6].1 = 500;                        // the track from G to T
    let (t2, _, r2, _) = routing(&edge, false);
    println!("try: track G-T cut to 500 m -> {} = {} m after {} rounds", t2, r2.last().unwrap(), r2.len());
    println!("ALL CHECKS PASS");
}
