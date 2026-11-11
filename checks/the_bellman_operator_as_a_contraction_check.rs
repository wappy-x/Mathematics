// The Bellman operator contracts -- the same check as the Python, in Rust, no
// crates.  A reservoir holds 0 to 4 units of water (1 unit = 10 million m^3);
// each month it releases a units for r(a) thousand pounds, then rain adds 0, 1
// or 2.  The best values are reached twice: by value iteration (pressing T) and
// by evaluating all 120 fixed release rules exactly, by elimination.
const GAMMA: f64 = 0.95;
const R: [f64; 5] = [0.0, 60.0, 100.0, 120.0, 130.0]; // r(a): revenue, thousand pounds
const RAIN: [(usize, f64); 3] = [(0, 0.3), (1, 0.5), (2, 0.2)]; // inflow in units, probability
type V5 = [f64; 5];

fn p_next(s: usize, a: usize) -> V5 {               // p(s' | s, a); water above 4 units spills
    let mut d = [0.0; 5];
    for &(w, pw) in RAIN.iter() { d[(s - a + w).min(4)] += pw }
    d
}
fn q(v: &V5, s: usize, a: usize, g: f64) -> f64 {   // revenue now plus discounted expected value next month
    let p = p_next(s, a);
    let mut e = 0.0;
    for t in 0..5 { e += p[t] * v[t] }
    R[a] + g * e
}
fn t_op(v: &V5, g: f64) -> V5 {                      // the Bellman operator: best action in every state
    let mut out = [0.0; 5];
    for s in 0..5 { out[s] = (0..=s).map(|a| q(v, s, a, g)).fold(f64::NEG_INFINITY, f64::max) }
    out
}
fn greedy(v: &V5) -> [usize; 5] {
    let mut pol = [0; 5];
    for s in 0..5 { for a in 1..=s { if q(v, s, a, GAMMA) > q(v, s, pol[s], GAMMA) { pol[s] = a } } }
    pol
}
fn sup(u: &V5, w: &V5) -> f64 { (0..5).map(|i| (u[i] - w[i]).abs()).fold(0.0, f64::max) }
fn sumn(u: &V5, w: &V5) -> f64 { (0..5).map(|i| (u[i] - w[i]).abs()).sum() }
fn evaluate(pol: &[usize; 5]) -> V5 {                // solve (I - gamma P) V = r by Gaussian elimination
    let mut m = [[0.0f64; 6]; 5];
    for s in 0..5 {
        let p = p_next(s, pol[s]);
        for t in 0..5 { m[s][t] = (if s == t { 1.0 } else { 0.0 }) - GAMMA * p[t] }
        m[s][5] = R[pol[s]];
    }
    for c in 0..5 {
        let mut piv = c;
        for i in c + 1..5 { if m[i][c].abs() > m[piv][c].abs() { piv = i } }
        m.swap(c, piv);
        for i in c + 1..5 {
            let f = m[i][c] / m[c][c];
            for j in 0..6 { m[i][j] -= f * m[c][j] }
        }
    }
    let mut v = [0.0; 5];
    for i in (0..5).rev() {
        let mut acc = 0.0;
        for j in i + 1..5 { acc += m[i][j] * v[j] }
        v[i] = (m[i][5] - acc) / m[i][i];
    }
    v
}
fn fmt(v: &V5) -> String { format!("[{}]", v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ")) }
fn fpol(p: &[usize; 5]) -> String { format!("[{}]", p.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let mut pols = vec![];
    for a1 in 0..2 { for a2 in 0..3 { for a3 in 0..4 { for a4 in 0..5 { pols.push([0, a1, a2, a3, a4]) } } } }
    let vals: Vec<V5> = pols.iter().map(evaluate).collect();
    let mut vstar = [0.0; 5];                         // road 2: best of all 120 rules, state by state
    for s in 0..5 { vstar[s] = vals.iter().map(|v| v[s]).fold(f64::NEG_INFINITY, f64::max) }
    let mut best = 0;
    for i in 1..pols.len() { if vals[i].iter().sum::<f64>() > vals[best].iter().sum::<f64>() { best = i } }
    println!("road 2, all {} release rules by elimination: V* = {}", pols.len(), fmt(&vstar));
    println!("best rule releases {}; its largest shortfall from V*: {:.9}", fpol(&pols[best]), sup(&vals[best], &vstar));
    let mut vs: Vec<V5> = vec![[0.0; 5]];             // road 1: value iteration from V_0 = 0
    for _ in 0..1000 { let n = t_op(vs.last().unwrap(), GAMMA); vs.push(n) }
    println!("road 1, value iteration, 1000 sweeps from 0: V = {}", fmt(&vs[1000]));
    println!("gap between roads {:.9}; Bellman residual ||T V* - V*|| = {:.9}", sup(&vs[1000], &vstar), sup(&t_op(&vstar, GAMMA), &vstar));
    assert!(sup(&vs[1000], &vstar) < 1e-9);                   // two roads, one answer

    let mut rng = SplitMix(0x2026);                   // SplitMix64, seed 0x2026, for random value functions
    let mut worst = 0.0f64;
    for _ in 0..20000 {
        let mut u = [0.0; 5];
        let mut w = [0.0; 5];
        for i in 0..5 { u[i] = 2000.0 * rng.next() - 1000.0 }
        for i in 0..5 { w[i] = 2000.0 * rng.next() - 1000.0 }
        worst = worst.max(sup(&t_op(&u, GAMMA), &t_op(&w, GAMMA)) / sup(&u, &w));
    }
    let mut up = vstar;
    for s in 0..5 { up[s] += 100.0 }
    let shift = sup(&t_op(&up, GAMMA), &t_op(&vstar, GAMMA)) / 100.0;
    println!("20000 random pairs: largest ||TU - TW|| / ||U - W|| = {:.6}; V* + 100 against V*: {:.6}", worst, shift);

    let err: Vec<f64> = vs.iter().map(|v| sup(v, &vstar)).collect();
    let d1 = sup(&vs[1], &vs[0]);
    let first = |n: usize| GAMMA.powi(n as i32) / (1.0 - GAMMA) * d1;          // first-step bound
    let last = |n: usize| GAMMA / (1.0 - GAMMA) * sup(&vs[n], &vs[n - 1]);    // last-step bound
    let q4: Vec<f64> = (0..5).map(|a| q(&vs[1], 4, a, GAMMA)).collect();
    println!("sweep 2, full reservoir, release 0 to 4: {}", join(&q4, 4));
    println!("gamma / (1 - gamma) = {:.4}; ||V_1 - V_0|| = {:.4}; over (1 - gamma): {:.4}; gamma^198, gamma^199 times that: {:.4}, {:.4}",
             GAMMA / (1.0 - GAMMA), d1, d1 / (1.0 - GAMMA), first(198), first(199));
    println!("k, V_k(full), error ||V_k - V*||, ratio to previous, gamma^k e_0, last-step bound, first-step bound");
    for k in [1usize, 2, 3, 10, 50, 100, 200] {
        println!("{}, {:.4}, {:.4}, {:.6}, {:.4}, {:.4}, {:.4}", k, vs[k][4], err[k], err[k] / err[k - 1],
                 GAMMA.powi(k as i32) * err[0], last(k), first(k));
    }
    let ratios: Vec<f64> = (1..301).map(|k| err[k] / err[k - 1]).collect();
    println!("error ratios over sweeps 1 to 300: smallest {:.6}, largest {:.6}",
             ratios.iter().cloned().fold(f64::INFINITY, f64::min), ratios.iter().cloned().fold(0.0, f64::max));
    let fnd = |ok: &dyn Fn(usize) -> bool| (1..=1000).find(|&n| ok(n)).unwrap();
    let (nf, nl, nt) = (fnd(&|n| first(n) <= 0.1), fnd(&|n| last(n) <= 0.1), fnd(&|n| err[n] <= 0.1));
    println!("within 0.1 (100 pounds): first-step bound promises n = {}, last-step bound stops at n = {}, true at n = {}", nf, nl, nt);
    for k in [1usize, 2] {
        let pk = greedy(&vs[k]);
        println!("greedy rule after sweep {}: {}, loss {:.4}, bound 2 gamma e_k / (1 - gamma) = {:.4}",
                 k, fpol(&pk), sup(&evaluate(&pk), &vstar), 2.0 * GAMMA * err[k] / (1.0 - GAMMA));
    }
    let settle = 1 + (0..301).filter(|&k| greedy(&vs[k]) != pols[best]).max().unwrap();
    println!("greedy rule equals the best rule from sweep {} on; error then {:.4}", settle, err[settle]);
    let (mut w1, p1) = ([0.0; 5], greedy(&vs[1]));   // sweep 1's rule valued again: 2000 fixed-rule sweeps, no elimination
    for _ in 0..2000 {
        let mut n = [0.0; 5];
        for s in 0..5 { n[s] = q(&w1, s, p1[s], GAMMA) }
        w1 = n;
    }
    println!("greedy rule after sweep 1, valued by 2000 fixed-rule sweeps instead: loss {:.4}", sup(&w1, &vstar));

    let mut v1: Vec<V5> = vec![[0.0; 5]];             // break 1: gamma = 1, nothing discounts the future
    for _ in 0..1000 { let n = t_op(v1.last().unwrap(), 1.0); v1.push(n) }
    let steps1: Vec<f64> = [10usize, 100, 1000].iter().map(|&k| sup(&v1[k], &v1[k - 1])).collect();
    println!("gamma = 1: step ||V_k - V_k-1|| at k = 10, 100, 1000: {:.4}, {:.4}, {:.4}; V_1000(full) = {:.4}",
             steps1[0], steps1[1], steps1[2], v1[1000][4]);
    let naive = fnd(&|n| sup(&vs[n], &vs[n - 1]) <= 0.1); // break 2: stop when the step is small
    println!("stop when step <= 0.1: sweep {}, step {:.4}, true error {:.4}", naive, sup(&vs[naive], &vs[naive - 1]), err[naive]);
    let mut u = vstar;                                // break 3: the total gap, not the largest
    u[2] += 100.0;
    let (tu, tv) = (t_op(&u, GAMMA), t_op(&vstar, GAMMA));
    let ch: Vec<f64> = (0..5).map(|i| tu[i] - tv[i]).collect();
    println!("one sweep, change in each state: {}", join(&ch, 4));
    println!("total-gap norm, V* + 100 at half full against V*: before {:.4}, after one sweep {:.4}, ratio {:.6}",
             sumn(&u, &vstar), sumn(&tu, &tv), sumn(&tu, &tv) / sumn(&u, &vstar));
    let ks: Vec<usize> = (0..=200).step_by(20).collect();
    println!("chart, sweep: {}", ks.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, log10 error: {}", join(&ks.iter().map(|&k| err[k].log10()).collect::<Vec<_>>(), 3));
    println!("chart, log10 gamma^k e_0: {}", join(&ks.iter().map(|&k| (GAMMA.powi(k as i32) * err[0]).log10()).collect::<Vec<_>>(), 3));

    assert!(worst <= GAMMA + 1e-12 && (shift - GAMMA).abs() < 1e-9);          // T contracts, by exactly gamma at worst
    assert!((1..301).all(|k| err[k] <= GAMMA * err[k - 1] + 1e-9));
    assert!((1..301).all(|n| err[n] <= last(n) + 1e-9 && last(n) <= first(n) + 1e-9));
    assert!((1..301).all(|k| (0..5).all(|s| (q(&vs[k], s, greedy(&vs[k])[s], GAMMA) - t_op(&vs[k], GAMMA)[s]).abs() < 1e-9))); // greedy wins the max
    assert!(greedy(&vs[1000]) == pols[best]);                                  // road 1's final rule is road 2's best rule
    assert!((sup(&w1, &vstar) - sup(&evaluate(&p1), &vstar)).abs() < 1e-9 && sup(&w1, &vstar) <= 2.0 * GAMMA * err[1] / (1.0 - GAMMA));
    assert!(steps1[2] > 1.0 && err[naive] > 0.1 && sumn(&tu, &tv) > sumn(&u, &vstar));      // the breaks really break
    println!("ALL CHECKS PASS");
}
