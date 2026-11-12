// Scheduling and the critical path -- the same check as the Python, in Rust.  No crates.
// Fitting out a new bakery: 9 jobs, durations p in working days, and arrows i -> j
// meaning "i must finish before j starts".  Then one oven, five batches, two rules.
const JOBS: [char; 9] = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
const NAME: [&str; 9] = ["strip out the old shop", "plumbing and drains", "three-phase electrics",
    "floor tiling", "fit the two ovens", "counter and shelving", "paint and signage", "test bakes",
    "hygiene inspection"];
const P: [i64; 9] = [3, 4, 5, 3, 6, 5, 3, 4, 2];
const ARCS: [(usize, usize); 10] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (4, 7), (6, 8), (7, 8)];
const N: usize = 9;

fn topo(arcs: &[(usize, usize)]) -> Vec<usize> {   // Kahn's peeling, lowest letter first
    let mut ins: Vec<usize> = (0..N).map(|j| arcs.iter().filter(|a| a.1 == j).count()).collect();
    let mut order: Vec<usize> = Vec::new();
    while order.len() < N {
        let j = (0..N).find(|x| !order.contains(x) && ins[*x] == 0).unwrap();
        order.push(j);
        for &(u, v) in arcs { if u == j { ins[v] -= 1 } }
    }
    order
}
// road one: forward pass, then backward pass
fn passes(p: &[i64], arcs: &[(usize, usize)]) -> (Vec<usize>, Vec<i64>, Vec<i64>, i64) {
    let order = topo(arcs);
    let (mut es, mut lf) = (vec![0i64; N], vec![0i64; N]);
    for &j in &order { es[j] = arcs.iter().filter(|a| a.1 == j).map(|a| es[a.0] + p[a.0]).max().unwrap_or(0) }
    let t = (0..N).map(|j| es[j] + p[j]).max().unwrap();
    for &j in order.iter().rev() { lf[j] = arcs.iter().filter(|a| a.0 == j).map(|a| lf[a.1] - p[a.1]).min().unwrap_or(t) }
    (order, es, lf, t)
}
fn finish(p: &[i64], arcs: &[(usize, usize)]) -> i64 { passes(p, arcs).3 }
fn walk(path: Vec<usize>, arcs: &[(usize, usize)], out: &mut Vec<Vec<usize>>) {   // road two: every chain
    let nxt: Vec<usize> = arcs.iter().filter(|a| a.0 == *path.last().unwrap()).map(|a| a.1).collect();
    if nxt.is_empty() { out.push(path.clone()) }
    for k in nxt { let mut q = path.clone(); q.push(k); walk(q, arcs, out) }
}
fn orders(items: &mut Vec<usize>, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {   // every order
    if items.is_empty() { out.push(cur.clone()) }
    for i in 0..items.len() {
        let x = items.remove(i); cur.push(x); orders(items, cur, out); cur.pop(); items.insert(i, x);
    }
}
// every job runs p + lo, p + lo + 1 or p + lo + 2 days, all 3^9 ways: (total, on time, path alone on time, worst, cases)
fn wobble(p: &[i64; N], lo: i64, order: &[usize], crit: &[usize], t: i64) -> (i64, i64, i64, i64, i64) {
    let (mut tot, mut hit, mut alone, mut worst, mut n) = (0i64, 0i64, 0i64, 0i64, 0i64);
    for w0 in 0..3i64.pow(N as u32) {
        let (mut w, mut q, mut e) = (w0, [0i64; N], [0i64; N]);
        for j in 0..N { q[j] = p[j] + w % 3 + lo; w /= 3 }
        for &j in order { e[j] = ARCS.iter().filter(|a| a.1 == j).map(|a| e[a.0] + q[a.0]).max().unwrap_or(0) }
        let tt = (0..N).map(|j| e[j] + q[j]).max().unwrap();
        tot += tt; hit += (tt <= t) as i64; worst = worst.max(tt); n += 1;
        alone += (crit.iter().map(|&j| q[j]).sum::<i64>() <= t) as i64;
    }
    (tot, hit, alone, worst, n)
}
fn letters(js: &[usize], sep: &str) -> String { js.iter().map(|&j| JOBS[j].to_string()).collect::<Vec<_>>().join(sep) }
fn sums(js: &[usize]) -> String { js.iter().map(|&j| P[j].to_string()).collect::<Vec<_>>().join(" + ") }
fn tagged(v: &[i64]) -> String { (0..N).map(|j| format!("{}{}", JOBS[j], v[j])).collect::<Vec<_>>().join(" ") }
const BN: [&str; 5] = ["croissants", "sourdough", "baguettes", "muffins", "birthday cake"];
const BP: [i64; 5] = [25, 50, 30, 15, 60];      // bake minutes
const BD: [i64; 5] = [60, 90, 105, 150, 180];   // van leaves, minutes after 5:00
fn score(seq: &[usize], bd: &[i64; 5]) -> (Vec<i64>, i64, i64, usize) {   // completions, total, worst lateness, late count
    let (mut c, mut now) = (Vec::new(), 0i64);
    for &b in seq { now += BP[b]; c.push(now) }
    let late: Vec<i64> = seq.iter().enumerate().map(|(i, &b)| c[i] - bd[b]).collect();
    let s = c.iter().sum();
    (c, s, *late.iter().max().unwrap(), late.iter().filter(|&&x| x > 0).count())
}
fn rule(key: &dyn Fn(usize) -> i64) -> Vec<usize> {   // repeatedly take the batch with the smallest key
    let (mut left, mut out): (Vec<usize>, Vec<usize>) = ((0..5).collect(), Vec::new());
    while !left.is_empty() {
        let mut bi = 0;
        for i in 1..left.len() { if key(left[i]) < key(left[bi]) { bi = i } }
        out.push(left.remove(bi));
    }
    out
}
fn main() {
    let (order, es, lf, t) = passes(&P, &ARCS);
    let ef: Vec<i64> = (0..N).map(|j| es[j] + P[j]).collect();
    let ls: Vec<i64> = (0..N).map(|j| lf[j] - P[j]).collect();
    let tf: Vec<i64> = (0..N).map(|j| ls[j] - es[j]).collect();
    let ff: Vec<i64> = (0..N).map(|j| ARCS.iter().filter(|a| a.0 == j).map(|a| es[a.1]).min().unwrap_or(t) - ef[j]).collect();
    let zero: Vec<usize> = order.iter().copied().filter(|&j| tf[j] == 0).collect();
    let total: i64 = P.iter().sum();
    println!("bakery fit-out: {} jobs, {} arrows, {} working days of work in all", N, ARCS.len(), total);
    println!("Kahn order for the passes: {}", letters(&order, " "));
    println!("job  name                     p  ES  EF  LS  LF  TF  FF");
    for j in 0..N {
        println!("{}    {:<24}{:>2}{:>4}{:>4}{:>4}{:>4}{:>4}{:>4}", JOBS[j], NAME[j], P[j], es[j], ef[j], ls[j], lf[j], tf[j], ff[j]);
    }
    let mut ch: Vec<Vec<usize>> = Vec::new();
    for j in 0..N { if ARCS.iter().all(|a| a.1 != j) { walk(vec![j], &ARCS, &mut ch) } }
    let len = |c: &Vec<usize>| -> i64 { c.iter().map(|&j| P[j]).sum() };
    let crit = ch.iter().find(|c| len(c) == t).unwrap().clone();
    let crit_len = len(&crit);
    println!("makespan T = {} working days; zero-float jobs {}", t, letters(&zero, " "));
    for c in &ch { println!("road two, chain {}: {} = {}", letters(c, " "), sums(c), len(c)) }
    let through: Vec<i64> = (0..N).map(|j| t - ch.iter().filter(|c| c.contains(&j)).map(|c| len(c)).max().unwrap()).collect();
    println!("road two, float = T - longest chain through the job: {}", tagged(&through));
    let slip: Vec<i64> = (0..N).map(|j| (0..10).filter(|&k| { let mut q = P; q[j] += k; finish(&q, &ARCS) == t }).max().unwrap()).collect();
    println!("road three, days each job can slip before T moves:   {}", tagged(&slip));
    let mut q2 = P; q2[5] += 2; let alone_f = finish(&q2, &ARCS); q2[6] += 2; let both = finish(&q2, &ARCS);
    let crew: Vec<i64> = [(1usize, 2usize), (2, 1)].iter().map(|&arc| { let mut a = ARCS.to_vec(); a.push(arc); finish(&P, &a) }).collect();
    println!("slip F by 2 alone: T = {}; slip F by 2 and G by 2: T = {}", alone_f, both);
    println!("mistake, every job end to end: {} days, not {}", total, t);
    println!("mistake, one crew for B and C: plumbing first T = {}, electrics first T = {}", crew[0], crew[1]);
    let (tot, hit, alone, worst, n) = wobble(&P, -1, &order, &crit, t);   // wobble -1, 0, +1
    println!("wobble, every job p-1, p or p+1 days, all {} cases: mean finish {:.2} days, on time (<= {}) in {:.1}%, worst {}",
             n, tot as f64 / n as f64, t, 100.0 * hit as f64 / n as f64, worst);
    println!("wobble, the critical path alone: mean {} days, on time in {:.1}%", crit_len, 100.0 * alone as f64 / n as f64);
    let spt = rule(&|b| BP[b]); let edd = rule(&|b| BD[b]); let gut = rule(&|b| -BP[b]);
    println!("one oven, 5 batches, {} minutes of baking in any order", BP.iter().sum::<i64>());
    println!("bake minutes / van leaves, minutes after 5:00: {}", (0..5).map(|b| format!("{} {}/{}", BN[b], BP[b], BD[b])).collect::<Vec<_>>().join(", "));
    for (lab, seq) in [("SPT, shortest bake first", &spt), ("EDD, earliest van first", &edd), ("gut, biggest batch first", &gut)] {
        let (c, s, lmax, nl) = score(seq, &BD);
        println!("{}: {}", lab, seq.iter().map(|&b| BN[b]).collect::<Vec<_>>().join(", "));
        println!("  done at {:?}; total {}, mean {:.0} min; worst lateness {} min; late batches {}", c, s, s as f64 / 5.0, lmax, nl);
    }
    let wt: i64 = spt.iter().enumerate().map(|(i, &b)| BP[b] * (5 - i as i64)).sum();   // bake x batches waiting
    println!("SPT total, each bake counted once per batch still waiting: {} = {}",
             spt.iter().enumerate().map(|(i, &b)| format!("{}x{}", BP[b], 5 - i)).collect::<Vec<_>>().join(" + "), wt);
    let mut allo: Vec<Vec<usize>> = Vec::new();
    orders(&mut (0..5).collect(), &mut Vec::new(), &mut allo);
    let sc: Vec<(Vec<i64>, i64, i64, usize)> = allo.iter().map(|s| score(s, &BD)).collect();
    let best_s = sc.iter().map(|a| a.1).min().unwrap();
    let best_l = sc.iter().map(|a| a.2).min().unwrap();
    println!("brute force, all {} orders: least total {}, orders reaching it {}; least worst lateness {}, orders reaching it {}",
             allo.len(), best_s, sc.iter().filter(|a| a.1 == best_s).count(), best_l, sc.iter().filter(|a| a.2 == best_l).count());
    let (mut p7, mut p3, mut bd120) = (P, P, BD); p7[2] = 7; p3[4] = 3; bd120[1] = 120;
    let (c7, ov) = (wobble(&p7, -1, &order, &crit, t), wobble(&P, 0, &order, &crit, t));
    println!("try, C = 7: T = {}, chains at T {}; wobble mean {:.2}, on time in {:.1}%", finish(&p7, &ARCS),
             ch.iter().filter(|c| c.iter().map(|&j| p7[j]).sum::<i64>() == t).count(), c7.0 as f64 / c7.4 as f64, 100.0 * c7.1 as f64 / c7.4 as f64);
    println!("try, E = 3: T = {}", finish(&p3, &ARCS));
    println!("try, jobs only overrun, p, p+1 or p+2 days: mean finish {:.2}, on time in {:.1}%", ov.0 as f64 / ov.4 as f64, 100.0 * ov.1 as f64 / ov.4 as f64);
    println!("try, sourdough van at 120: SPT worst lateness {} min; orders with every van on time {} of {}",
             score(&spt, &bd120).2, allo.iter().filter(|s| score(s, &bd120).2 <= 0).count(), allo.len());
    let x: Vec<i64> = (0..N).map(|j| 40 + 13 * es[j]).collect();
    println!("figure, x = 40 + 13 per day, row y = 34 + 20 per job; bar starts and ends: {}; float tails end C{} G{}; day {} at x {}",
             (0..N).map(|j| format!("{}{}-{}", JOBS[j], x[j], x[j] + 13 * P[j])).collect::<Vec<_>>().join(" "),
             40 + 13 * lf[2], 40 + 13 * lf[6], t, 40 + 13 * t);
    assert!(t == 22 && ch.iter().map(|c| len(c)).max().unwrap() == t);       // pass against chains
    assert!(tf == through && through == slip && zero == vec![0, 1, 3, 4, 7, 8]); // three roads to float
    assert!(ff[5] == 0 && tf[5] == 2 && both == 24 && crew == vec![24, 27]);
    assert!(score(&spt, &BD).1 == best_s && best_s == wt && score(&edd, &BD).2 == best_l && best_l == 0 && score(&spt, &BD).2 == 30);
    assert!(tot as f64 / n as f64 > t as f64 && hit < alone && alone < n);      // merging costs time
    println!("ALL CHECKS PASS");
}
