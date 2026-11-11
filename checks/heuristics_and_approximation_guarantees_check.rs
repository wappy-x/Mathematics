// Heuristics with a promise -- the same check as the Python, in Rust.  No crates.  Fees in £ thousand, distances in metres.
// Part 1: greedy covering of ten genres, each genre's price, the dual-fitting bound, against every lineup and a dual certificate.
// Part 2: the nearest-neighbour buggy round, improved by two-opt, checked against every one of the 2,520 rounds.
use std::collections::HashSet;
use std::sync::Mutex;
type Act = (String, f64, Vec<usize>);
struct Step { name: String, fee: f64, new: Vec<usize>, open: Vec<usize> }
fn h(k: usize) -> f64 { (1..=k).map(|j| 1.0 / j as f64).sum() }          // the harmonic sum
fn greedy(acts: &[Act], n: usize, by_fee: bool) -> (Vec<Step>, Vec<f64>) {
    let (mut left, mut steps, mut price) = (vec![true; n], Vec::new(), vec![0.0; n]);
    while left.iter().any(|&l| l) {
        let mut best: Option<(f64, usize, Vec<usize>)> = None;
        for (i, (_, fee, gs)) in acts.iter().enumerate() {
            let new: Vec<usize> = gs.iter().copied().filter(|&g| left[g]).collect();
            if new.is_empty() { continue }
            let key = if by_fee { fee / new.len() as f64 } else { -(new.len() as f64) };
            if best.as_ref().map_or(true, |b| key < b.0) { best = Some((key, i, new)) }
        }
        let (_, i, new) = best.unwrap();
        let open = acts.iter().map(|a| a.2.iter().filter(|&&g| left[g]).count()).collect();
        for &g in &new { price[g] = acts[i].1 / new.len() as f64; left[g] = false }
        steps.push(Step { name: acts[i].0.clone(), fee: acts[i].1, new, open });
    }
    (steps, price)
}
fn bill(acts: &[Act], by_fee: bool) -> (String, f64) {                    // greedy's picks and its bill
    let st = greedy(acts, 10, by_fee).0;
    (st.iter().map(|s| s.name.as_str()).collect::<Vec<_>>().join(" "), st.iter().map(|s| s.fee).sum())
}

fn cheapest(acts: &[Act], n: usize) -> (f64, String) {                   // every lineup tried
    let mut best = (f64::INFINITY, String::new());
    for mask in 0..(1usize << acts.len()) {
        let chosen: Vec<&Act> = acts.iter().enumerate().filter(|(i, _)| mask >> i & 1 == 1).map(|(_, a)| a).collect();
        if chosen.iter().flat_map(|a| a.2.iter().copied()).collect::<HashSet<usize>>().len() != n { continue }
        let c = (chosen.iter().map(|a| a.1).sum::<f64>(), chosen.iter().map(|a| a.0.as_str()).collect::<Vec<_>>().join(" "));
        if c.0 < best.0 || (c.0 == best.0 && c.1 < best.1) { best = c }
    }
    best
}

static SITE: Mutex<[(&str, i64, i64); 8]> = Mutex::new([("O", 30, 20), ("A", 50, 110), ("M", 100, 230), ("D", 190, 80),
    ("J", 380, 60), ("B", 380, 10), ("S", 370, 210), ("C", 100, 130)]);          // a "try" line moves C
fn site() -> [(&'static str, i64, i64); 8] { *SITE.lock().unwrap() }
fn dist(i: usize, j: usize) -> f64 { let w = site(); let (dx, dy) = ((w[i].1 - w[j].1) as f64, (w[i].2 - w[j].2) as f64); (dx * dx + dy * dy).sqrt() }
fn length(t: &[usize]) -> f64 { (0..t.len()).map(|i| dist(t[i], t[(i + 1) % t.len()])).sum() }
fn word(t: &[usize]) -> String { let w = site(); t.iter().chain([t[0]].iter()).map(|&i| w[i].0).collect::<Vec<_>>().join("-") }

fn two_opt(t0: &[usize], log_moves: bool) -> (Vec<usize>, usize, usize) {   // best improving swap, until none
    let (mut t, n, mut moves, mut looks) = (t0.to_vec(), t0.len(), 0, 0);
    loop {
        let (mut best, mut at) = (-1e-9, None);
        for i in 0..n - 1 {
            for j in i + 2..(if i > 0 { n } else { n - 1 }) {
                let (a, b, c, e) = (t[i], t[i + 1], t[j], t[(j + 1) % n]);
                looks += 1; let delta = dist(a, c) + dist(b, e) - dist(a, b) - dist(c, e);
                if delta < best { best = delta; at = Some((i, j)) }
            }
        }
        let Some((i, j)) = at else { return (t, moves, looks) };
        let mut new = t.clone(); new[i + 1..j + 1].reverse();
        if log_moves {
            println!("two-opt move {}: drop {} and {}, change {:.1}, recount {:.1}", moves + 1,
                     &word(&[t[i], t[i + 1]])[..3], &word(&[t[j], t[(j + 1) % n]])[..3], best, length(&new) - length(&t));
        }
        t = new; moves += 1;
    }
}

fn crossings(t: &[usize]) -> usize {                     // pairs of legs that cross, by orientation signs
    let w = site(); let o = |p: usize, q: usize, r: usize| (w[q].1 - w[p].1) * (w[r].2 - w[p].2) - (w[q].2 - w[p].2) * (w[r].1 - w[p].1);
    let (n, mut count) = (t.len(), 0);
    for x in 0..n { for z in x + 2..(if x > 0 { n } else { n - 1 }) {
        let (p, q, r, s) = (t[x], t[(x + 1) % n], t[z], t[(z + 1) % n]);
        if o(p, q, r) * o(p, q, s) < 0 && o(r, s, p) * o(r, s, q) < 0 { count += 1 } } }
    count
}
fn nearest() -> Vec<usize> {                             // from the office, always to the nearest stage not yet visited
    let (mut t, mut left) = (vec![0usize], (1..8).collect::<Vec<usize>>());
    while let Some(&k) = left.iter().min_by(|&&a, &&b| { let l = *t.last().unwrap(); dist(l, a).partial_cmp(&dist(l, b)).unwrap().then(a.cmp(&b)) }) {
        t.push(k); left.retain(|&v| v != k);
    }
    t
}

fn next_perm(p: &mut [usize]) -> bool {                  // lexicographic order, as the Python lists them
    let Some(i) = (0..p.len() - 1).rev().find(|&i| p[i] < p[i + 1]) else { return false };
    let j = (i + 1..p.len()).rev().find(|&j| p[j] > p[i]).unwrap();
    p.swap(i, j); p[i + 1..].reverse(); true
}

fn main() {
    let act = |n: &str, f: f64, g: &[usize]| (n.to_string(), f, g.to_vec());
    let acts: Vec<Act> = vec![act("P", 50.0, &[0, 1, 2, 3, 4]), act("Q", 50.0, &[5, 6, 7, 8, 9]),
        act("R", 54.0, &[0, 1, 2, 5, 6, 7]), act("S", 30.0, &[3, 4]), act("T", 36.0, &[8, 9]),
        act("U", 40.0, &[2, 3, 8]), act("V", 28.0, &[1, 9])];
    const GENRES: [&str; 10] = ["rock", "pop", "folk", "jazz", "soul", "indie", "techno", "hip-hop", "reggae", "metal"];
    for a in &acts { println!("act {}, fee {}: {}", a.0, a.1, a.2.iter().map(|&k| GENRES[k]).collect::<Vec<_>>().join(" ")) }
    let (steps, price) = greedy(&acts, 10, true);
    let g: f64 = steps.iter().map(|s| s.fee).sum();
    for (k, s) in steps.iter().enumerate() { println!("greedy step {}: act {}, fee {}, {} new genres at {:.2} each", k + 1, s.name, s.fee, s.new.len(), s.fee / s.new.len() as f64) }
    let (opt, opt_names) = cheapest(&acts, 10);
    println!("greedy lineup costs {}; cheapest of all 128 lineups: {} at {}; ratio {:.2}", g, opt_names, opt, g / opt);
    let y = [9.0, 9.0, 9.0, 11.5, 11.5, 9.0, 9.0, 9.0, 11.5, 11.5]; let ysum: f64 = y.iter().sum(); // dual prices, one per genre
    let dual_ok = acts.iter().all(|a| a.2.iter().map(|&k| y[k]).sum::<f64>() <= a.1);
    println!("dual prices {} sum to {:.2}; every act's genres within its fee: {}", y.map(|v| v.to_string()).join(" "), ysum, if dual_ok { "yes" } else { "no" });
    let d = acts.iter().map(|a| a.2.len()).max().unwrap();
    println!("promise: H({}) = {:.3}, H(10) = {:.3}, 1 + ln 10 = {:.3}", d, h(d), h(10), 1.0 + 10f64.ln());
    let ratios: Vec<f64> = acts.iter().map(|a| a.2.iter().map(|&k| price[k]).sum::<f64>() / a.1).collect(); let rmax = ratios.iter().cloned().fold(0.0, f64::max);
    println!("greedy prices on each act / its fee: {}", acts.iter().zip(&ratios).map(|(a, r)| format!("{} {:.3}", a.0, r)).collect::<Vec<_>>().join(" "));
    println!("fitted floor {} / H({}) = {:.2}; shrinking by {:.3} instead gives {:.2}", g, d, g / h(d), rmax, g / rmax);
    let (mut checks, mut held) = (0, 0);
    for s in &steps { for (a, &k) in acts.iter().zip(&s.open) {
        if k > 0 { checks += 1; if s.fee / s.new.len() as f64 <= a.1 / k as f64 { held += 1 } } } }
    let p_lines: Vec<String> = steps.iter().filter(|s| s.open[0] > 0)
        .map(|s| format!("{:.2} <= 50/{} = {:.2}", s.fee / s.new.len() as f64, s.open[0], 50.0 / s.open[0] as f64)).collect();
    println!("act P's allowances: {}; all {} of {} step checks hold", p_lines.join(", "), held, checks);
    let mut tight: Vec<Act> = (1..=10).map(|i| (format!("solo{}", i), 60.0 / i as f64, vec![i - 1])).collect();
    tight.push(act("big", 61.0, &(0..10).collect::<Vec<_>>()));
    let (tg, topt) = (bill(&tight, true).1, cheapest(&tight, 10).0);
    println!("near-tight case, solo act i at 60/i and big act at 61: greedy {:.2}, best {}, ratio {:.3} against H(10) {:.3}", tg, topt, tg / topt, h(10));
    let ((mnames, mg), praw) = (bill(&acts, false), acts[0].2.iter().map(|&k| price[k]).sum::<f64>()); // ties go to the act listed first
    println!("mistakes: raw prices as a floor {:.2} > {}; act P's raw prices {:.2} > 50; most-genres greedy {} costs {}", price.iter().sum::<f64>(), opt, praw, mnames, mg);
    let mut bad: Vec<Act> = (1..=10).map(|i| (format!("solo{}", i), 10.0, vec![i - 1])).collect();
    bad.push(act("big", 1000.0, &(0..10).collect::<Vec<_>>()));
    let ((bnames, bg), bopt) = (bill(&bad, false), cheapest(&bad, 10).0);
    println!("most-genres case, ten solo acts at 10 and a big act at 1000: most-genres greedy {} {}, best {}, ratio {:.3} > H(10) {:.3}", bnames, bg, bopt, bg / bopt, h(10));

    let nn = nearest();
    println!("nearest-neighbour round {}: {:.1} m, {} crossing pair(s)", word(&nn), length(&nn), crossings(&nn));
    let (best_t, moves, looks) = two_opt(&nn, true);
    println!("two-opt round {}: {:.1} m after {} moves and {} looks, {} crossings", word(&best_t), length(&best_t), moves, looks, crossings(&best_t));
    let (mut rounds, mut p) = (Vec::new(), vec![1usize, 2, 3, 4, 5, 6, 7]);
    loop { if p[0] < p[6] { rounds.push([vec![0], p.clone()].concat()) } if !next_perm(&mut p) { break } }
    let l = rounds.iter().map(|t| length(t)).fold(f64::INFINITY, f64::min);
    let (mut in_tree, mut tree) = (vec![0usize], 0.0);      // Prim's cheapest connecting tree, the floor
    while in_tree.len() < 8 { let mut b = (f64::INFINITY, 0);
        for &u in &in_tree { for v in 0..8 { if !in_tree.contains(&v) && (dist(u, v), v) < b { b = (dist(u, v), v) } } }
        tree += b.0; in_tree.push(b.1) }
    println!("shortest of all {} rounds: {:.1} m; cheapest tree floor {:.1} m; nearest-neighbour {:.1}% above", rounds.len(), l, tree, 100.0 * (length(&nn) / l - 1.0));
    let ends: Vec<f64> = rounds.iter().map(|t| length(&two_opt(t, false).0)).collect();
    let hit = ends.iter().filter(|e| (*e - l).abs() < 1e-6).count();
    let (distinct, mut worst): (HashSet<String>, usize) = (ends.iter().map(|e| format!("{:.6}", e)).collect(), 0); for k in 0..ends.len() { if ends[k] > ends[worst] { worst = k } }
    println!("two-opt from every round: {} of {} end at the shortest, {} above; distinct stopping lengths {}", hit, rounds.len(), rounds.len() - hit, distinct.len());
    let wt = two_opt(&rounds[worst], false).0;
    println!("worst stop {}: {:.1} m, {:.1}% above, {} crossings", word(&wt), ends[worst], 100.0 * (ends[worst] / l - 1.0), crossings(&wt));
    println!("figure, scale 0.75 per m, {}", site().iter().map(|p| format!("{}({},{})", p.0, p.1, p.2)).collect::<Vec<_>>().join(" "));

    assert!(opt == 100.0 && (ysum - opt).abs() < 1e-9 && dual_ok);          // certificate meets enumeration
    assert!(g <= h(d) * opt && rmax <= h(d) && held == checks);              // the theorem, act by act
    assert!((price.iter().sum::<f64>() - g).abs() < 1e-9);                   // every pound charged once
    assert!(topt == 61.0 && tg / topt <= h(10) && tg / topt > 2.8);          // nearly tight, never over
    assert!((length(&best_t) - l).abs() < 1e-6 && tree <= l);                // two-opt against enumeration
    assert!(crossings(&best_t) == 0 && crossings(&nn) == 2 && ends.iter().all(|&e| e >= l - 1e-6));
    assert!(bg / bopt > h(10) && bopt == 100.0);                            // most genres first: no promise
    let r60: Vec<Act> = acts.iter().map(|a| (a.0.clone(), if a.0 == "R" { 60.0 } else { a.1 }, a.2.clone())).collect();
    let ((rn, rg), fits) = (bill(&r60, true), r60.iter().all(|a| a.2.iter().map(|&k| y[k]).sum::<f64>() <= a.1));
    println!("try R at 60: greedy {} costs {}, cheapest {}; dual certificate fits: {}", rn, rg, cheapest(&r60, 10).0, if fits { "yes" } else { "no" });
    let mut t59 = tight.clone(); t59[10].1 = 59.0;
    let ((n59, g59), b59) = (bill(&t59, true), cheapest(&t59, 10).0);
    println!("try big act at 59: greedy {} {:.2}, best {}, ratio {:.3}", n59, g59, b59, g59 / b59);
    let mut y10 = y; y10[2] = 10.0;                                         // folk's price raised to 10
    println!("try folk at 10: prices sum to {:.2}; overpriced acts: {}", y10.iter().sum::<f64>(),
             acts.iter().filter(|a| a.2.iter().map(|&k| y10[k]).sum::<f64>() > a.1).map(|a| a.0.as_str()).collect::<Vec<_>>().join(" "));
    SITE.lock().unwrap()[7] = ("C", 150, 130);                               // move the comedy tent
    let (nn2, l2) = (nearest(), rounds.iter().map(|t| length(t)).fold(f64::INFINITY, f64::min)); let (t2, m2, _) = two_opt(&nn2, false);
    println!("try C at (150, 130): nearest-neighbour {} {:.1} m, {} crossings, {:.1}% above the shortest {:.1} m; two-opt reaches {:.1} m in {} moves",
             word(&nn2), length(&nn2), crossings(&nn2), 100.0 * (length(&nn2) / l2 - 1.0), l2, length(&t2), m2);
    println!("ALL CHECKS PASS");
}
