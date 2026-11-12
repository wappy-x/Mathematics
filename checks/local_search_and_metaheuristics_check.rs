// Local search on an exam timetable: the same check as the Python, in Rust.  Standard library only,
// no crates, no rand: SplitMix64 is written out.  Every dataset is synthetic.
type Adj = Vec<Vec<usize>>;
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31)
    }
    fn below(&mut self, m: usize) -> usize { (self.next() % m as u64) as usize }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }   // in [0, 1)
}
fn sm(seed: u64) -> SplitMix64 { SplitMix64 { s: seed } }
fn build(rng: &mut SplitMix64, n: usize, slots: usize) -> Adj {   // 40 first-years, 80 others, 4 exams each
    let mut adj = vec![vec![false; n]; n];
    for who in 0..120 {
        let pool = if who < 40 { 12 } else { n };
        let mut pick: Vec<usize> = Vec::new();
        while pick.len() < 4 {
            let c = rng.below(pool);
            if pick.iter().all(|&p| p % slots != c % slots) { pick.push(c); }   // a clash-free timetable exists
        }
        for &a in &pick { for &b in &pick { if a != b { adj[a][b] = true; } } }
    }
    adj.iter().map(|r| (0..n).filter(|&b| r[b]).collect()).collect()
}
fn clashes(adj: &Adj, x: &[usize]) -> usize {
    (0..adj.len()).map(|a| adj[a].iter().filter(|&&b| a < b && x[a] == x[b]).count()).sum()
}
fn table(adj: &Adj, x: &[usize], slots: usize) -> Vec<Vec<i64>> {   // t[e][s]: e's clash partners in slot s
    let mut t = vec![vec![0i64; slots]; adj.len()];
    for a in 0..adj.len() { for &b in &adj[a] { t[a][x[b]] += 1; } } t
}
fn deltas(adj: &Adj, x: &[usize], slots: usize) -> Vec<i64> {    // the change in clashes of every move
    let (t, mut d) = (table(adj, x, slots), Vec::new());
    for e in 0..adj.len() { for s in 0..slots { if s != x[e] { d.push(t[e][s] - t[e][x[e]]); } } } d
}
fn mv(adj: &Adj, t: &mut Vec<Vec<i64>>, x: &mut Vec<usize>, e: usize, s: usize) {
    for &b in &adj[e] { t[b][x[e]] -= 1; t[b][s] += 1; }
    x[e] = s;
}
fn hill(adj: &Adj, x: &mut Vec<usize>, slots: usize, mut tr: Option<&mut Vec<i64>>) -> (i64, usize) {
    let (mut t, mut c, mut looks) = (table(adj, x, slots), clashes(adj, x) as i64, 0usize);
    loop {                                                        // steepest descent
        let (mut best, mut bm) = (0i64, None);
        for e in 0..adj.len() { for s in 0..slots {
            if s == x[e] { continue; }
            looks += 1;
            if looks % 1000 == 0 { if let Some(v) = tr.as_deref_mut() { v.push(c); } }
            if t[e][s] - t[e][x[e]] < best { best = t[e][s] - t[e][x[e]]; bm = Some((e, s)); }
        } }
        match bm { None => return (c, looks), Some((e, s)) => { mv(adj, &mut t, x, e, s); c += best; } }
    }
}
fn anneal(adj: &Adj, x: &mut Vec<usize>, slots: usize, rng: &mut SplitMix64, t0: f64, alpha: f64, steps: usize,
          stop: bool, mut tr: Option<&mut Vec<i64>>) -> (i64, usize, usize) {   // t0 = 0: never uphill
    let (mut t, mut c, mut temp, mut zero) = (table(adj, x, slots), clashes(adj, x) as i64, t0, 0usize);
    let mut best = c; for i in 1..=steps {
        let (e, mut s) = (rng.below(adj.len()), rng.below(slots - 1));
        if s >= x[e] { s += 1; }                                  // a different slot, every one equally likely
        let d = t[e][s] - t[e][x[e]];
        if d <= 0 || (temp > 0.0 && rng.unif() < (-(d as f64) / temp).exp()) { mv(adj, &mut t, x, e, s); c += d; }
        best = best.min(c); if c == 0 { zero += 1; } temp *= alpha;
        if i % 1000 == 0 { if let Some(v) = tr.as_deref_mut() { v.push(c); } }
        if stop && c == 0 { return (0, i, zero); }
    }
    (best, steps, zero)
}
fn genetic(adj: &Adj, slots: usize, rng: &mut SplitMix64, size: usize, children: usize) -> usize {
    let n = adj.len(); let mut pop: Vec<Vec<usize>> = (0..size).map(|_| (0..n).map(|_| rng.below(slots)).collect()).collect();
    let mut cost: Vec<usize> = pop.iter().map(|x| clashes(adj, x)).collect();
    for _ in 0..children {
        let mut pa = [0usize; 2];
        for j in 0..2 { let (a, b) = (rng.below(size), rng.below(size)); pa[j] = if (cost[a], a) <= (cost[b], b) { a } else { b }; }
        let mut child: Vec<usize> = (0..n).map(|e| pop[pa[rng.below(2)]][e]).collect();
        let (e, s) = (rng.below(n), rng.below(slots)); child[e] = s;            // mutation: one random move
        let (c, w) = (clashes(adj, &child), (0..size).max_by_key(|&k| (cost[k], k)).unwrap());
        if c <= cost[w] { pop[w] = child; cost[w] = c; }
        if c == 0 { return 0; }
    }
    *cost.iter().min().unwrap()
}
fn rx(rng: &mut SplitMix64, n: usize, slots: usize) -> Vec<usize> { (0..n).map(|_| rng.below(slots)).collect() }
fn wins<T>(rs: &[(i64, usize, T)]) -> usize { rs.iter().filter(|r| r.0 == 0).count() }
fn hruns(adj: &Adj, rng: &mut SplitMix64, k: usize, slots: usize) -> Vec<(i64, usize, ())> {
    (0..k).map(|_| { let mut x = rx(rng, adj.len(), slots); let r = hill(adj, &mut x, slots, None); (r.0, r.1, ()) }).collect()
}
fn mean<T>(rs: &[(i64, usize, T)]) -> f64 { rs.iter().map(|r| r.1 as f64).sum::<f64>() / rs.len() as f64 }
fn most<T>(rs: &[(i64, usize, T)]) -> usize { rs.iter().map(|r| r.1).max().unwrap() }
fn main() {
    let (n, sl) = (40usize, 12usize); let adj = build(&mut sm(20261111), n, sl);
    let pairs = adj.iter().map(|a| a.len()).sum::<usize>() / 2;
    let mut g = vec![usize::MAX; n];                                    // greedy colouring, listed order
    for e in 0..n { g[e] = (0..n).find(|&s| adj[e].iter().all(|&b| g[b] != s)).unwrap(); }
    let (core, gs) = ((0..12).all(|a| (0..12).all(|b| a == b || adj[a].contains(&b))), g.iter().max().unwrap() + 1);
    println!("clash pairs {}, busiest exam {}, core 12 all clash {}, greedy uses {} slots", pairs,
             adj.iter().map(|a| a.len()).max().unwrap(), if core { "True" } else { "False" }, gs);
    println!("timetables 12^40 = 10^{:.2}, moves per timetable {}, random start expects {:.2}",
             40.0 * 12f64.log10(), n * (sl - 1), pairs as f64 / sl as f64);
    let runs = hruns(&adj, &mut sm(1), 400, sl);
    let (w, looks, p) = (wins(&runs), mean(&runs), wins(&runs) as f64 / 400.0);
    let mut x1 = rx(&mut sm(1), n, sl); let c1 = clashes(&adj, &x1);
    let ends: Vec<usize> = (0..7).map(|c| runs.iter().filter(|r| r.0 == c).count()).collect();
    println!("hill: {} of 400 reach 0, p {:.4}, mean looks {:.1}, ends {:?}", w, p, looks, ends);
    let h1 = hill(&adj, &mut x1, sl, None); let (d1, t1) = (deltas(&adj, &x1, sl), table(&adj, &x1, sl));
    println!("run 1: start {}, stuck at {} after {} looks; moves improve {}, tie {}, worsen {}", c1, h1.0, h1.1,
             d1.iter().filter(|&&d| d < 0).count(), d1.iter().filter(|&&d| d == 0).count(), d1.iter().filter(|&&d| d > 0).count());
    let (e0, s0) = (0..n).flat_map(|e| (0..sl).map(move |s| (e, s))).find(|&(e, s)| s != x1[e] && t1[e][s] == t1[e][x1[e]] && t1[e][s] > 0).unwrap();
    println!("a tie move in run 1: exam {} from slot {} ({} partner there) to slot {} ({} there)", e0, x1[e0], t1[e0][x1[e0]], s0, t1[e0][s0]);
    let groups = (0..40).filter(|i| wins(&runs[i * 10..i * 10 + 10]) > 0).count();
    let (f10, pse) = (1.0 - (1.0 - p).powf(10.0), (p * (1.0 - p) / 400.0).sqrt()); let need = |q: f64| (0.05f64.ln() / (1.0 - q).ln()).ceil();
    println!("restarts: 10 runs win {:.4} by formula, {} of 40 blocks of 10; 95% needs {} runs ({} to {} with p +/- 1.96 se), expected looks {:.0}",
             f10, groups, need(p), need(p + 1.96 * pse), need(p - 1.96 * pse), looks / p);
    let mut rng = sm(2);
    let ann: Vec<_> = (0..50).map(|_| { let mut x = rx(&mut rng, n, sl); anneal(&adj, &mut x, sl, &mut rng, 2.0, 0.9995, 20000, true, None) }).collect();
    let tie: Vec<_> = (0..50).map(|_| { let mut x = rx(&mut rng, n, sl); anneal(&adj, &mut x, sl, &mut rng, 0.0, 1.0, 20000, true, None) }).collect();
    println!("anneal: {} of 50 reach 0, mean looks {:.1}, most {}", wins(&ann), mean(&ann), most(&ann));
    println!("ties only, T = 0: {} of 50 reach 0, mean looks {:.1}, most {}", wins(&tie), mean(&tie), most(&tie));
    let t5 = 2.0 * 0.9995f64.powf(5000.0);
    println!("accept a +1 move: T 2 {:.4}, T 1 {:.4}, after 5000 looks T {:.4} {:.6}", (-0.5f64).exp(), (-1f64).exp(), t5, (-1.0 / t5).exp());
    let mut xa = rx(&mut sm(3), n, sl); let ra = anneal(&adj, &mut xa, sl, &mut sm(4), 2.0, 0.9995, 20000, true, None);
    let used = (0..sl).filter(|s| xa.contains(s)).count();
    println!("one finished timetable: {} looks, full recount {} clashes, slots used {}", ra.1, clashes(&adj, &xa), used);
    let mut rng = sm(5); let hot: Vec<i64> = (0..20).map(|_| { let mut x = rx(&mut rng, n, sl); anneal(&adj, &mut x, sl, &mut rng, 2.0, 1.0, 20000, true, None).0 }).collect();
    let s11: Vec<i64> = (0..20).map(|_| { let mut x = rx(&mut rng, n, 11); anneal(&adj, &mut x, 11, &mut rng, 2.0, 0.9995, 20000, true, None).0 }).collect();
    let gen: Vec<usize> = (0..5).map(|_| genetic(&adj, sl, &mut rng, 30, 10000)).collect();
    println!("never cool, T 2: {} of 20 reach 0, mean best {:.2}; 11 slots: best {}, worst {}", hot.iter().filter(|&&b| b == 0).count(),
             hot.iter().sum::<i64>() as f64 / 20.0, s11.iter().min().unwrap(), s11.iter().max().unwrap());
    println!("genetic, 30 parents, 10000 children: bests {:?}", gen);
    // ---- the small timetable: 8 exams, 13 clashes, 3 slots, every timetable tried ----
    let e8 = [(0, 1), (0, 3), (0, 6), (1, 2), (1, 3), (1, 6), (1, 7), (2, 6), (2, 7), (4, 5), (4, 6), (5, 6), (5, 7)];
    let a8: Adj = (0..8).map(|v| e8.iter().filter(|e| e.0 == v).map(|e| e.1).chain(e8.iter().filter(|e| e.1 == v).map(|e| e.0)).collect()).collect();
    let xs: Vec<Vec<usize>> = (0..6561usize).map(|k| (0..8).map(|i| k / 3usize.pow(i) % 3).collect()).collect();
    let cs: Vec<usize> = xs.iter().map(|x| clashes(&a8, x)).collect();
    let mind = |x: &Vec<usize>| *deltas(&a8, x, 3).iter().min().unwrap();
    let traps: Vec<&Vec<usize>> = xs.iter().zip(&cs).filter(|(x, &c)| c > 0 && mind(x) > 0).map(|(x, _)| x).collect();
    let stuck = xs.iter().zip(&cs).filter(|(x, &c)| c > 0 && mind(x) >= 0).count();
    let p8 = xs.iter().filter(|x| hill(&a8, &mut (*x).clone(), 3, None).0 == 0).count() as f64 / 6561.0;
    let z0 = cs.iter().filter(|&&c| c == 0).count();
    let dt = deltas(&a8, traps[0], 3);
    println!("8 exams: timetables {}, clash-free {}, stuck {}, every move worse {} with clashes {:?}, trap {:?}, its {} moves add at least {}",
             xs.len(), z0, stuck, traps.len(), traps.iter().map(|t| clashes(&a8, t)).collect::<Vec<_>>(), traps[0], dt.len(), dt.iter().min().unwrap());
    let mut rng = sm(8); let sim3 = (0..4000).filter(|_| (0..3).any(|_| hill(&a8, &mut rx(&mut rng, 8, 3), 3, None).0 == 0)).count() as f64 / 4000.0;
    let f3 = 1.0 - (1.0 - p8).powf(3.0);
    println!("8 exams: hill wins from {:.4} of starts; 3 restarts win {:.4} by formula, {:.4} simulated", p8, f3, sim3);
    let esc: Vec<_> = (0..50).map(|_| anneal(&a8, &mut traps[0].clone(), 3, &mut rng, 1.0, 0.999, 5000, true, None)).collect();
    let st0: Vec<_> = (0..50).map(|_| anneal(&a8, &mut traps[0].clone(), 3, &mut rng, 0.0, 1.0, 5000, true, None)).collect();
    println!("from the trap: anneal T0 1 escapes {} of 50, mean looks {:.1}; T = 0 escapes {}", wins(&esc), mean(&esc), wins(&st0));
    let zz: f64 = cs.iter().map(|&c| (-(c as f64) / 0.5).exp()).sum(); let ch: Vec<f64> = (0..20).map(|_| anneal(&a8, &mut traps[0].clone(), 3, &mut rng, 0.5, 1.0, 50000, false, None).2 as f64 / 50000.0).collect();
    let fixed = ch.iter().sum::<f64>() / 20.0; let fse = (ch.iter().map(|v| (v - fixed) * (v - fixed)).sum::<f64>() / 19.0 / 20.0).sqrt();
    println!("T fixed 0.5, 20 runs: share of time clash-free {:.4} se {:.4}, exp(-C/T)/Z over all 6561 {:.4}", fixed, fse, z0 as f64 / zz);
    let (mut th, mut ta, mut tt) = (Vec::new(), Vec::new(), Vec::new()); hill(&adj, &mut rx(&mut sm(1), n, sl), sl, Some(&mut th));
    for (t0, al, tr) in [(2.0, 0.9995, &mut ta), (0.0, 1.0, &mut tt)] { anneal(&adj, &mut rx(&mut sm(1), n, sl), sl, &mut sm(9), t0, al, 10000, false, Some(tr)); }
    for (name, tr) in [("hill climb", &th), ("anneal", &ta), ("ties only", &tt)] {
        let mut v = vec![c1 as i64]; v.extend(tr.iter().chain(std::iter::repeat(&h1.0)).take(10));
        println!("chart, {:<10} {:?}", name, v);
    }
    assert!(core && gs == 13, "floor 12 by the clique of core exams; greedy in listed order needs 13");
    let mut full = Vec::new();
    for e in 0..n { for s in (0..sl).filter(|&s| s != x1[e]) { let mut y = x1.clone(); y[e] = s; full.push(clashes(&adj, &y) as i64 - h1.0); } }
    assert!(full == d1, "every move's change from the table equals a full recount");
    assert!(*d1.iter().min().unwrap() >= 0 && h1.0 > 0 && ra.0 == 0 && clashes(&adj, &xa) == 0, "run 1 is stuck; the annealed timetable recounts to 0");
    assert!((groups as f64 / 40.0 - f10).abs() < 4.0 * (0.25f64 / 40.0).sqrt(), "restart formula against blocks of runs");
    assert!((sim3 - f3).abs() < 4.0 * (0.25f64 / 4000.0).sqrt(), "restart formula against exhaustion");
    assert!(wins(&st0) == 0 && 0 < wins(&esc), "from a true trap only an uphill move escapes");
    assert!(*s11.iter().min().unwrap() >= 1, "11 slots can never reach 0: the 12 core exams need 12 slots");
    assert!((fixed - z0 as f64 / zz).abs() < 4.0 * fse, "fixed T visits timetables in proportion to exp(-C/T)");
    println!("ALL CHECKS PASS");
}
