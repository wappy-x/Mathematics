// Q-learning and temporal differences -- the same check as the Python, in Rust.
// No crates.  A reservoir holds 0-4 units (1 unit = 10 million m3); each month it
// releases 0, 1 or 2 units, rain adds 0, 1 or 2.  Maximise discounted money, in
// GBP thousands.  Roads: (1) value iteration on the known model; (2) every one of
// the 54 rules, each solved exactly by elimination; (3) Q-learning from 20000
// simulated months that never sees the model; (4) TD(0) against (2).
const CAP: usize = 4; const G: f64 = 0.9; const REV: [i64; 3] = [0, 80, 120];
const SPILL: i64 = 100; const EMPTY: i64 = 120;
const RAIN: [(usize, f64); 3] = [(0, 0.3), (1, 0.4), (2, 0.3)]; // inflow units, chances
type Tab = [[f64; 3]; 5];
struct SplitMix64 { x: u64 }                     // the card's random numbers, seeded
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.x ^ (self.x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
fn na(s: usize) -> usize { s.min(2) + 1 }        // cannot release water not held
fn step(s: usize, a: usize, w: usize) -> (i64, usize) {   // release, rain, spill
    let (x, s2) = (s - a + w, (s - a + w).min(CAP));
    let spill = if x > CAP { (x - CAP) as i64 } else { 0 };
    (REV[a] - SPILL * spill - if s2 == 0 { EMPTY } else { 0 }, s2)
}
fn best(q: &Tab, s: usize) -> usize {            // greedy action, ties to less water
    (0..na(s)).fold(0, |b, a| if q[s][a] > q[s][b] { a } else { b })
}
fn backup(q: &Tab, s: usize, a: usize, g: f64) -> f64 {   // sum of r + g max Q(s')
    let mut tot = 0.0;
    for &(w, p) in RAIN.iter() {
        let (r, s2) = step(s, a, w);
        tot += p * (r as f64 + g * q[s2][best(q, s2)]);
    }
    tot
}
fn value_iteration(g: f64) -> (Tab, usize) {
    let (mut q, mut k) = ([[0.0; 3]; 5], 0);
    loop {
        let (mut n, mut d) = ([[0.0; 3]; 5], 0.0f64);
        for s in 0..5 { for a in 0..na(s) {
            n[s][a] = backup(&q, s, a, g);
            d = d.max((n[s][a] - q[s][a]).abs());
        } }
        k += 1; q = n;
        if d < 1e-9 { return (q, k); }
    }
}
fn evaluate(pol: &[usize]) -> Vec<f64> {         // solve (I - g P) V = r by elimination
    let mut m = [[0.0f64; 6]; 5];
    for s in 0..5 {
        m[s][s] += 1.0; for &(w, p) in RAIN.iter() {
            let (r, s2) = step(s, pol[s], w);
            m[s][s2] -= G * p; m[s][5] += p * r as f64;
        } }
    for c in 0..5 {
        let piv = (c..5).fold(c, |b, i| if m[i][c].abs() > m[b][c].abs() { i } else { b });
        m.swap(c, piv);
        for i in c + 1..5 {
            let f = m[i][c] / m[c][c];
            for j in 0..6 { m[i][j] = m[i][j] - f * m[c][j]; }
        }
    }
    let mut v = vec![0.0; 5];
    for i in (0..5).rev() {
        let sum = ((i + 1)..5).fold(0.0, |t, j| t + m[i][j] * v[j]);
        v[i] = (m[i][5] - sum) / m[i][i];
    }
    v
}
fn rain(u: u64) -> usize { if u < 3 { 0 } else if u < 7 { 1 } else { 2 } }
fn err(q: &Tab, qs: &Tab) -> f64 {
    (0..5).flat_map(|s| (0..na(s)).map(move |a| (s, a))).fold(0.0f64, |e, (s, a)| e.max((q[s][a] - qs[s][a]).abs()))
}
fn learn(eps: u64, seed: u64, months: usize, c: usize, myopic: bool, trace: usize, marks: &[usize],
         qs: &Tab, pi: &[usize]) -> (Tab, [[usize; 3]; 5], f64, Vec<(usize, f64, f64)>) {
    let (mut rng, mut s, mut earned) = (SplitMix64 { x: seed }, 2usize, 0.0);
    let (mut q, mut n, mut errs) = ([[0.0f64; 3]; 5], [[0usize; 3]; 5], vec![]);
    for t in 1..=months {
        let a = if rng.next() % 100 < eps { (rng.next() % na(s) as u64) as usize }  // explore
                else { best(&q, s) };                                               // exploit
        let w = rain(rng.next() % 10);
        let (r, s2) = step(s, a, w);
        earned += r as f64;
        n[s][a] += 1;
        let alpha = if c > 0 { c as f64 / (c - 1 + n[s][a]) as f64 } else { 1.0 / n[s][a] as f64 };
        let target = r as f64 + if myopic { 0.0 } else { G * q[s2][best(&q, s2)] };
        let old = q[s][a]; q[s][a] += alpha * (target - q[s][a]);
        if t <= trace { println!("trace,{},{},{},{},{},{},{:.2},{:.2},{:.3},{:.2}", t, s, a, w, r, s2, old, target, alpha, q[s][a]); }
        if marks.contains(&t) {
            let e2 = (0..5).fold(0.0f64, |m, x| m.max((q[x][pi[x]] - qs[x][pi[x]]).abs()));
            errs.push((t, err(&q, qs), e2));
        }
        s = s2;
    }
    (q, n, earned / months as f64, errs)
}
fn yes(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn row(q: &Tab, s: usize) -> String { (0..na(s)).map(|a| format!("{:.2}", q[s][a])).collect::<Vec<_>>().join(",") }
fn main() {
    let (qs, sweeps) = value_iteration(G);
    let pi: Vec<usize> = (0..5).map(|s| best(&qs, s)).collect();
    for s in 0..5 { println!("Q*,s={},{},best={}", s, row(&qs, s), pi[s]); }
    let mut res: f64 = 0.0;
    for s in 0..5 { for a in 0..na(s) { res = res.max((backup(&qs, s, a, G) - qs[s][a]).abs()); } }
    println!("value iteration: {} sweeps from Q=0 to change < 1e-9; Bellman residual < 1e-6: {}", sweeps, yes(res < 1e-6));
    for &(w, p) in RAIN.iter() {                 // by hand: targets at Q*, level 2, release 1
        let (r, s2) = step(2, 1, w); let tg = r as f64 + G * qs[s2][pi[s2]];
        println!("hand,rain {},chance {},next level {},target {:.2},TD error {:.2},weighted {:.2}", w, p, s2, tg, tg - qs[2][1], p * tg);
    }
    let mut rules = vec![];
    for a1 in 0..2 { for a2 in 0..3 { for a3 in 0..3 { for a4 in 0..3 { rules.push(vec![0, a1, a2, a3, a4]); } } } }
    let vals: Vec<Vec<f64>> = rules.iter().map(|p| evaluate(p)).collect();
    let tot = |i: usize| vals[i].iter().fold(0.0, |t, v| t + v);
    let mut top = 0;
    for i in 0..rules.len() { if tot(i) > tot(top) { top = i; } }
    let dom = (0..rules.len()).all(|i| (0..5).all(|s| vals[top][s] >= vals[i][s] - 1e-9));
    let gapv = (0..5).fold(0.0f64, |m, s| m.max((vals[top][s] - qs[s][pi[s]]).abs()));
    println!("enumeration: {} rules, best {:?}, best in every state {}, matches value iteration {}",
             rules.len(), rules[top], yes(dom), yes(gapv < 1e-6));
    let mut d = [0.2f64; 5];                     // long-run share of months per level
    for _ in 0..2000 {
        let mut nd = [0.0; 5];
        for s in 0..5 { for &(w, p) in RAIN.iter() { nd[step(s, pi[s], w).1] += d[s] * p; } } d = nd;
    }
    let mut avg = 0.0; for s in 0..5 { for &(w, p) in RAIN.iter() { avg += d[s] * p * step(s, pi[s], w).0 as f64; } }
    println!("best rule earns on average {:.2} per month in the long run", avg);
    let marks = [500, 1000, 2000, 5000, 10000, 20000];
    let (q, n, earned, errs) = learn(10, 1, 20000, 10, false, 6, &marks, &qs, &pi);
    for s in 0..5 { println!("learned,s={},{},best={}", s, row(&q, s), best(&q, s)); }
    let mut vis = vec![];
    for s in 0..5 { for a in 0..na(s) { vis.push(format!("{}{}:{}", s, a, n[s][a])); } }
    println!("visits,{}", vis.join(","));
    for &(t, e1, e2) in errs.iter() { println!("error after {} months: all pairs {:.2}, chosen pairs {:.2}", t, e1, e2); }
    let lp: Vec<usize> = (0..5).map(|s| best(&q, s)).collect();
    println!("learned rule {:?}, true rule {:?}, earned {:.2} per month while learning", lp, pi, earned);
    for &eps in [0u64, 10, 30, 100].iter() {
        let (q2, _, e, _) = learn(eps, 1, 20000, 10, false, 0, &[], &qs, &pi);
        let right = (0..5).filter(|&s| best(&q2, s) == pi[s]).count();
        println!("explore {}%: earned {:.2}/month, short of best {:.2}, max error {:.2}, levels right {}/5, rule {:?}",
                 eps, e, avg - e, err(&q2, &qs), right, (0..5).map(|s| best(&q2, s)).collect::<Vec<_>>());
    }
    let q1 = learn(10, 1, 20000, 0, false, 0, &[], &qs, &pi).0;
    let qm = learn(10, 1, 20000, 10, true, 0, &[], &qs, &pi).0;
    let pm: Vec<usize> = (0..5).map(|s| best(&qm, s)).collect();
    println!("break, step 1/n: max error {:.2}; drop the future: rule {:?}, worth {:.2} from level 2 against {:.2}",
             err(&q1, &qs), pm, evaluate(&pm)[2], qs[2][pi[2]]);
    let sd: Vec<String> = [2u64, 3].iter().map(|&k| format!("{:.2}", err(&learn(10, k, 20000, 10, false, 0, &[], &qs, &pi).0, &qs))).collect();
    println!("seeds 2 and 3: max error {}", sd.join(", "));
    for &g in [0.5, 0.99].iter() {
        let qg = value_iteration(g).0;
        println!("gamma {}: best rule {:?}", g, (0..5).map(|s| best(&qg, s)).collect::<Vec<_>>());
    }
    let hold1: Vec<usize> = (0..5).map(|s: usize| s.min(1)).collect();   // TD(0): 'release 1 if you can'
    let (ve, mut v, mut nv, mut rng, mut s) = (evaluate(&hold1), [0.0f64; 5], [0usize; 5], SplitMix64 { x: 7 }, 2usize);
    for _ in 0..20000 {
        let (r, s2) = step(s, hold1[s], rain(rng.next() % 10));
        nv[s] += 1; v[s] += 10.0 / (9 + nv[s]) as f64 * (r as f64 + G * v[s2] - v[s]);
        s = s2; }
    let j = |x: &[f64]| x.iter().map(|y| format!("{:.2}", y)).collect::<Vec<_>>().join(",");
    println!("TD(0) release-1 rule: exact {}; TD {}", j(&ve), j(&v));
    let tde = (0..5).fold(0.0f64, |m, s| m.max((v[s] - ve[s]).abs()));
    println!("TD(0) max error {:.2}", tde);
    let minve = ve.iter().fold(f64::INFINITY, |m, &y| m.min(y));
    assert!(res < 1e-6 && dom && gapv < 1e-6 && rules[top] == pi);          // road 1 = road 2
    assert!(lp == pi && errs[errs.len() - 1].2 < 0.05 * qs[2][pi[2]]);       // road 3 agrees
    assert!(err(&learn(0, 1, 20000, 10, false, 0, &[], &qs, &pi).0, &qs) > 100.0 && pm != pi); // breaks bite
    assert!(tde < 0.05 * minve);                                             // road 4 agrees
    println!("ALL CHECKS PASS");
}
